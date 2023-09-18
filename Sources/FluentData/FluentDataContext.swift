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
        
        if case .bundle = contextKey.persistence {
            databases.middleware.use(ReadOnlyMiddleware(), on: .sqlite)
        } else {
            databases.middleware.use(QueryChangesTrackingMiddleware(tracker: self), on: .sqlite)
        }
        
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
        refreshAllQueries()
    }
}

extension FluentDataContext: DatabaseStateTracker {
    private func refreshAllQueries() {
        registeredQueries.values.forEach { registration in
            registration.update()
        }
    }
    
    func onCreate(_ model: FluentKit.AnyModel, on db: FluentKit.Database) {
        refreshAllQueries()
    }
    
    func onDelete(_ model: FluentKit.AnyModel, force: Bool, on db: FluentKit.Database) {
        refreshAllQueries()
    }
    
    func onSoftDelete(_ model: FluentKit.AnyModel, on db: FluentKit.Database) {
        refreshAllQueries()
    }
    
    func onRestore(_ model: FluentKit.AnyModel, on db: FluentKit.Database) {
        refreshAllQueries()
    }
    
    func onUpdate(_ model: FluentKit.AnyModel, on db: FluentKit.Database) {
        refreshAllQueries()
    }
}

fileprivate protocol AnyQueryRegistration {
    func update()
}

fileprivate protocol DatabaseStateTracker: AnyObject {
    func onCreate(_ model: AnyModel, on db: Database)
    func onDelete(_ model: AnyModel, force: Bool, on db: Database)
    func onSoftDelete(_ model: AnyModel, on db: Database)
    func onRestore(_ model: AnyModel, on db: Database)
    func onUpdate(_ model: AnyModel, on db: Database)
}

public enum ReadOnlyDatabaseError: Error {
    case invalidOperation
}

fileprivate struct ReadOnlyMiddleware: AnyModelMiddleware {
    func handle(_ event: FluentKit.ModelEvent, _ model: FluentKit.AnyModel, on db: FluentKit.Database, chainingTo next: FluentKit.AnyModelResponder) -> NIOCore.EventLoopFuture<Void> {
        return db.eventLoop.makeFailedFuture(ReadOnlyDatabaseError.invalidOperation)
    }
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
            .map {
                switch event {
                case .create:
                    tracker.onCreate(model, on: db)
                case .delete(let force):
                    tracker.onDelete(model, force: force, on: db)
                case .restore:
                    tracker.onRestore(model, on: db)
                case .softDelete:
                    tracker.onSoftDelete(model, on: db)
                case .update:
                    tracker.onUpdate(model, on: db)
                }
                
                return $0
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
    
    func update() {
        queryBuilder.all().whenComplete { result in
            switch result {
            case .success(let model):
                subject.send(model)
            case .failure(let error):
                subject.send(completion: .failure(error))
            }
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
