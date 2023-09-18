import Combine
import FluentKit
import FluentSQLiteDriver
import NIOTransportServices
import OSLog

/// An isolated database context
public class FluentDataContext {
    /// Access the Fluent's Database object
    ///
    /// Use Fluent's Database object to execute CUD operations such as `Model.create(on:)`, `Model.update(on:)` or `Model.delete(on:)`
    ///
    /// ```swift
    /// Planet(name: "Earth").create(on: context.database)
    /// ```
    public var database: any Database {
        databases.database(.sqlite, logger: logger, on: eventLoopGroup.next())!
    }
    
    private let databases: Databases
    private let eventLoopGroup: EventLoopGroup
    private let logger: Logger
    private var registeredQueries: [UUID: AnyQueryRegistration] = [:]
    private let threadPool: NIOThreadPool
    
    /// Create and register a new database context
    /// - Parameters:
    ///   - contextKey: the key which uniquely identify this context
    ///   - makeDefault: if `true`, register this context as the default one. If `nil`, registers this context as the default one only if there is no default context yet
    public init<K: FluentDataContextKey>(contextKey: K.Type, makeDefault: Bool? = nil) {
        let eventLoopGroup = NIOTSEventLoopGroup(loopCount: 1, defaultQoS: .userInitiated)
        let threadPool = NIOThreadPool(numberOfThreads: 1)
        threadPool.start()

        let logger = Logger(label: DatabaseID.sqlite.string, factory: {
            OSLogLogHandler(os.Logger(subsystem: "FluentData", category: $0), logLevel: contextKey.logQueries ? .debug : .info)
        })

        databases = Self.initDatabases(contextKey: contextKey, eventLoopGroup: eventLoopGroup, threadPool: threadPool, logger: logger)

        self.logger = logger
        self.eventLoopGroup = eventLoopGroup
        self.threadPool = threadPool

        databases.middleware.use(QueryChangesTrackingMiddleware(tracker: self), on: .sqlite)
        
        // Register the context
        FluentDataContexts[contextKey, makeDefault] = self
    }

    private static func initDatabases<K: FluentDataContextKey>(contextKey: K.Type, eventLoopGroup: EventLoopGroup, threadPool: NIOThreadPool, logger: Logger) -> Databases {
        guard contextKey.shouldMigrate else {
            let databases = Databases(threadPool: threadPool, on: eventLoopGroup)
            databases.use(K.databaseConfigurationFactory, as: .sqlite, isDefault: true)
            return databases
        }

        do {
            return try createAndMigrateDatabases()
        } catch let migrationError {
            return tryRecoverMigrationError(migrationError)
        }

        func createAndMigrateDatabases() throws -> Databases {
            let databases = Databases(threadPool: threadPool, on: eventLoopGroup)
            databases.use(K.databaseConfigurationFactory, as: .sqlite, isDefault: true)

            do {
                try migrate(migrations: contextKey.migrations, filePath: contextKey.removableFilePath, databases: databases, eventLoopGroup: eventLoopGroup, logger: logger)
            } catch {
                databases.shutdown()
                throw error
            }

            return databases
        }

        func migrate(migrations migrationList: [Migration], filePath: URL?, databases: Databases, eventLoopGroup: EventLoopGroup, logger: Logger) throws {
            let migrations = Migrations()
            migrationList.forEach { migrations.add($0) }

            let migrator = Migrator(databases: databases, migrations: migrations, logger: logger, on: eventLoopGroup.next())
            try migrator.setupIfNeeded().wait()
            try migrator.prepareBatch().wait()
        }

        func removeFile(migrationError: Error) {
            guard let filePath = contextKey.removableFilePath else {
                fatalError("Failure policy is incompatible with specified persistance.\nMigrations failed with error: \(migrationError)")
            }

            do {
                try FileManager.default.removeItem(at: filePath)
            } catch let fileManagerError {
                fatalError("Unable to start fresh: \(fileManagerError)\nMigrations failed with error: \(migrationError)")
            }
        }

        func tryRecoverMigrationError(_ migrationError: Error) -> Databases {
            switch contextKey.migrationFailurePolicy {
            case .startFresh:
                removeFile(migrationError: migrationError)
                do {
                    logger.notice("Unable to migrate, trying to start fresh")
                    return try createAndMigrateDatabases()
                } catch let error {
                    fatalError("Migrations failed with error (will start fresh and retry): \(migrationError)\nMigrations failed again with error (aborting): \(error)")
                }

            case .abort:
                fatalError("Migrations failed with error: \(migrationError)")

            case .backupAndStartFresh(let backupHandler):
                guard let filePath = contextKey.removableFilePath else {
                    fatalError("Failure policy is incompatible with specified persistance.\nMigrations failed with error: \(migrationError)")
                }
                logger.notice("Unable to migrate, running backup handler and trying to start fresh")
                backupHandler(filePath)

                removeFile(migrationError: migrationError)
                do {
                    return try createAndMigrateDatabases()
                } catch let error {
                    fatalError("Migrations failed with error (will backup and retry): \(migrationError)\nMigrations failed again with error (aborting): \(error)")
                }
            }
        }
    }

    public func use(middleware: AnyModelMiddleware) {
        databases.middleware.use(middleware, on: .sqlite)
    }

    internal func deregister<Model: FluentKit.Model>(_ fluentQuery: FluentQuery<Model>) {
        registeredQueries.removeValue(forKey: fluentQuery.queryId)
    }

    internal func register<Model: FluentKit.Model>(_ fluentQuery: FluentQuery<Model>) {
        let queryBuilder = fluentQuery.queryBuilder(Model.query(on: database))
        
        let registration = QueryRegistration<Model>(queryBuilder: queryBuilder, subject: fluentQuery.subject)
        registeredQueries.updateValue(registration, forKey: fluentQuery.queryId)
        Task(priority: .background) {
            await registration.update()
        }
    }
}

extension FluentDataContext: DatabaseStateTracker {
    private func refreshAllQueriesFor(schema: String, space: String?) async {
        for registration in registeredQueries.values {
            if registration.shouldUpdateFor(schema: schema, space: space) {
                await registration.update()
            }
        }
    }
    
    func onCreate(_ model: FluentKit.AnyModel, on db: FluentKit.Database) async {
        let modelType = type(of: model)
        await refreshAllQueriesFor(schema: modelType.schema, space: modelType.space)
    }
    
    func onDelete(_ model: FluentKit.AnyModel, force: Bool, on db: FluentKit.Database) async {
        let modelType = type(of: model)
        await refreshAllQueriesFor(schema: modelType.schema, space: modelType.space)
    }
    
    func onSoftDelete(_ model: FluentKit.AnyModel, on db: FluentKit.Database) async {
        let modelType = type(of: model)
        await refreshAllQueriesFor(schema: modelType.schema, space: modelType.space)
    }
    
    func onRestore(_ model: FluentKit.AnyModel, on db: FluentKit.Database) async {
        let modelType = type(of: model)
        await refreshAllQueriesFor(schema: modelType.schema, space: modelType.space)
    }
    
    func onUpdate(_ model: FluentKit.AnyModel, on db: FluentKit.Database) async {
        let modelType = type(of: model)
        await refreshAllQueriesFor(schema: modelType.schema, space: modelType.space)
    }
}

fileprivate protocol AnyQueryRegistration {
    func shouldUpdateFor(schema: String, space: String?) -> Bool
    func update() async
}

fileprivate protocol DatabaseStateTracker: AnyObject {
    func onCreate(_ model: AnyModel, on db: Database) async
    func onDelete(_ model: AnyModel, force: Bool, on db: Database) async
    func onSoftDelete(_ model: AnyModel, on db: Database) async
    func onRestore(_ model: AnyModel, on db: Database) async
    func onUpdate(_ model: AnyModel, on db: Database) async
}

fileprivate struct QueryChangesTrackingMiddleware: AnyModelMiddleware {
    private weak var tracker: (any DatabaseStateTracker)?
    
    init(tracker: any DatabaseStateTracker) {
        self.tracker = tracker
    }
    
    func handle(_ event: FluentKit.ModelEvent, _ model: FluentKit.AnyModel, on db: FluentKit.Database, chainingTo next: FluentKit.AnyModelResponder) -> NIOCore.EventLoopFuture<Void> {
        guard let tracker else {
            return next.handle(event, model, on: db)
        }
        
        return next.handle(event, model, on: db)
            .flatMap { result in
                let promise = db.eventLoop.makePromise(of: Void.self)
                
                promise.completeWithTask {
                    switch event {
                    case .create:
                        await tracker.onCreate(model, on: db)
                    case .delete(let force):
                        await tracker.onDelete(model, force: force, on: db)
                    case .restore:
                        await tracker.onRestore(model, on: db)
                    case .softDelete:
                        await tracker.onSoftDelete(model, on: db)
                    case .update:
                        await tracker.onUpdate(model, on: db)
                    }
                }
                
                return promise.futureResult.map { result }
            }
    }
}

fileprivate struct QueryRegistration<Model: FluentKit.Model>: AnyQueryRegistration {
    let queryBuilder: QueryBuilder<Model>
    let subject: CurrentValueSubject<[Model], Error>

    init(
        queryBuilder: QueryBuilder<Model>,
        subject: CurrentValueSubject<[Model], Error>
    ) {
        self.queryBuilder = queryBuilder
        self.subject = subject
    }
    
    func shouldUpdateFor(schema: String, space: String?) -> Bool {
        // If the queried table matches the given schema and space, an update is required
        if queryBuilder.query.schema == schema, queryBuilder.query.space == space {
            return true
        }
        
        // We also need to check if there is any eager loaders for a matching model
        if queryBuilder.eagerLoaders.isEmpty == false {
            // TODO(FD-8): Improve detection of eager loaded models
            // As of now, we don't have access to the EagerLoader concrete classes of the Fluent module.
            // Because of that, we don't know which model is eager loaded, thus limiting the way we can optimize this
            return true
        }
        
        // If not, we check here if there is a join on a table matching the given schema and space
        for join in queryBuilder.query.joins {
            switch join {
            case .join(let joinedSchema, _, _, _, _):
                if joinedSchema == schema, self.queryBuilder.query.space == space {
                    return true
                }
                
            case .extendedJoin(let joinedSchema, let joinedSpace, _, _, _, _):
                if joinedSchema == schema, joinedSpace == space {
                    return true
                }
                
            case .advancedJoin(let joinedSchema, let joinedSpace, _, _, _):
                if joinedSchema == schema, joinedSpace == space {
                    return true
                }
                
            case .custom:
                return false
            }
        }
        
        // If we don't find a match, it means the query doesn't need to be updated
        return false
    }
    
    func update() async {
        do {
            subject.send(try await queryBuilder.all())
        } catch {
            subject.send(completion: .failure(error))
        }
    }
}

fileprivate extension FluentDataContextKey {
    static var databaseConfigurationFactory: DatabaseConfigurationFactory {
        switch Self.persistence {
        case .memory:
            return .sqlite(.memory)
        case .file:
            let filePath = Self.filePath!
            return .sqlite(.file(filePath.absoluteString))
        case .bundle:
            let filePath = Self.filePath!
            let folder = FileManager.default.temporaryDirectory
            let tempPath = folder.appendingPathComponent("\(UUID().uuidString).sqlite")
            do {
                try FileManager.default.copyItem(at: filePath, to: tempPath)
                return .sqlite(.file(tempPath.absoluteString))
            } catch {
                fatalError("Unable to copy bundled database \(tempPath) from bundle \(filePath) to temporary directory.")
            }
        }
    }

    static var filePath: URL? {
        switch Self.persistence {
        case .memory:
            return nil
        case .file(let name):
            let folder = try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let urlSafePersistenceName = name.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed.subtracting(CharacterSet.symbols).subtracting(CharacterSet.newlines))!
            let filePath = folder.appendingPathComponent("\(urlSafePersistenceName).sqlite")
            return filePath
        case .bundle(let bundle, let name):
            if let path = bundle.url(forResource: name, withExtension: "sqlite") {
                return path
            } else {
                fatalError("Database \(name).sqlite not found in \(bundle.bundlePath).")
            }
        }
    }

    static var removableFilePath: URL? {
        switch Self.persistence {
        case .file:
            return filePath
        case .memory, .bundle:
            return nil
        }
    }

    static var shouldMigrate: Bool {
        switch Self.persistence {
        case .memory, .file:
            return true
        case .bundle:
            return false
        }
    }
}
