import Combine
import FluentKit
import FluentSQLiteDriver
import NIOTransportServices
import OSLog

private protocol AnyQueryRegistration {
    func shouldUpdateFor(schema: String, space: String?) -> Bool
    func update() async
}

private protocol DatabaseStateTracker: AnyObject {
    func onCreate(_ model: AnyModel, on db: Database) async
    func onDelete(_ model: AnyModel, force: Bool, on db: Database) async
    func onSoftDelete(_ model: AnyModel, on db: Database) async
    func onRestore(_ model: AnyModel, on db: Database) async
    func onUpdate(_ model: AnyModel, on db: Database) async
}

private struct ReadOnlyMiddleware: AnyModelMiddleware {
    func handle(
        _ event: FluentKit.ModelEvent,
        _ model: FluentKit.AnyModel,
        on db: FluentKit.Database,
        chainingTo next: FluentKit.AnyModelResponder
    ) -> NIOCore.EventLoopFuture<Void> {
        return db.eventLoop.makeFailedFuture(ReadOnlyDatabaseError.invalidOperation)
    }
}

private struct QueryChangesTrackingMiddleware: AnyModelMiddleware {
    private weak var tracker: (any DatabaseStateTracker)?

    init(tracker: any DatabaseStateTracker) {
        self.tracker = tracker
    }

    func handle(
        _ event: FluentKit.ModelEvent,
        _ model: FluentKit.AnyModel,
        on db: FluentKit.Database,
        chainingTo next: FluentKit.AnyModelResponder
    ) -> NIOCore.EventLoopFuture<Void> {
        let nextFuture = next.handle(event, model, on: db)

        if let tracker {
            nextFuture
                .whenSuccess { _ in
                    Task {
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
                }
        }

        return nextFuture
    }
}

private struct QueryRegistration<Model: FluentKit.Model>: AnyQueryRegistration {
    private let queryBuilder: QueryBuilder<Model>
    private let subject: CurrentValueSubject<[Model], Error>

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
        guard queryBuilder.eagerLoaders.isEmpty else {
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
            let value = try await queryBuilder.all()
            subject.send(value)
        } catch {
            subject.send(completion: .failure(error))
        }
    }
}

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
        guard let db = databases.database(.sqlite, logger: logger, on: eventLoopGroup.next()) else {
            fatalError("Unable to fetch database object")
        }
        return db
    }

    private let databases: Databases
    private let eventLoopGroup: EventLoopGroup
    private let logger: Logger
    private var registeredQueries: [UUID: AnyQueryRegistration] = [:]
    private let threadPool: NIOThreadPool

    /// Create and register a new database context
    /// - Parameters:
    ///   - contextKey: the key which uniquely identify this context
    ///   - makeDefault: if `true`, register this context as the default one. If `nil`, registers this context as the default one only if there is no default
    ///     context yet
    public init<K: FluentDataContextKey>(contextKey: K.Type, middlewares: [AnyModelMiddleware] = [], makeDefault: Bool? = nil) {
        let eventLoopGroup = NIOTSEventLoopGroup(loopCount: 1, defaultQoS: .userInitiated)
        let threadPool = NIOThreadPool(numberOfThreads: 1)
        threadPool.start()

        let logger = Logger(label: DatabaseID.sqlite.string) { category in
            OSLogHandler(os.Logger(subsystem: "FluentData", category: category), logLevel: contextKey.logQueries ? .debug : .info)
        }

        databases = Self.initDatabases(contextKey: contextKey, eventLoopGroup: eventLoopGroup, threadPool: threadPool, logger: logger)

        self.logger = logger
        self.eventLoopGroup = eventLoopGroup
        self.threadPool = threadPool

        if case .bundle = contextKey.persistence {
            databases.middleware.use(ReadOnlyMiddleware(), on: .sqlite)
            middlewares.forEach { databases.middleware.use($0, on: .sqlite) }
        } else {
            middlewares.forEach { databases.middleware.use($0, on: .sqlite) }
            databases.middleware.use(QueryChangesTrackingMiddleware(tracker: self), on: .sqlite)
        }

        // Register the context
        FluentDataContexts[contextKey, makeDefault] = self
    }

    private static func initDatabases<K: FluentDataContextKey>(
        contextKey: K.Type,
        eventLoopGroup: EventLoopGroup,
        threadPool: NIOThreadPool,
        logger: Logger
    ) -> Databases {
        guard contextKey.shouldMigrate else {
            let databases = Databases(threadPool: threadPool, on: eventLoopGroup)
            databases.use(K.databaseConfigurationFactory, as: .sqlite, isDefault: true)
            return databases
        }

        do {
            return try createAndMigrateDatabases()
        } catch {
            return tryRecoverMigrationError(error)
        }

        func createAndMigrateDatabases() throws -> Databases {
            let databases = Databases(threadPool: threadPool, on: eventLoopGroup)
            databases.use(K.databaseConfigurationFactory, as: .sqlite, isDefault: true)

            do {
                try migrate(
                    migrations: contextKey.migrations,
                    filePath: contextKey.removableFilePath,
                    databases: databases,
                    eventLoopGroup: eventLoopGroup,
                    logger: logger
                )
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
            } catch {
                fatalError("Unable to start fresh: \(error)\nMigrations failed with error: \(migrationError)")
            }
        }

        func tryRecoverMigrationError(_ migrationError: Error) -> Databases {
            switch contextKey.migrationFailurePolicy {
            case .startFresh:
                removeFile(migrationError: migrationError)
                do {
                    logger.notice("Unable to migrate, trying to start fresh")
                    return try createAndMigrateDatabases()
                } catch {
                    fatalError(
                        "Migrations failed with error (will start fresh and retry): \(migrationError)\nMigrations failed again with error (aborting): \(error)"
                    )
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
                } catch {
                    fatalError(
                        "Migrations failed with error (will backup and retry): \(migrationError)\nMigrations failed again with error (aborting): \(error)"
                    )
                }
            }
        }
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
        for registration in registeredQueries.values where registration.shouldUpdateFor(schema: schema, space: space) {
            await registration.update()
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

fileprivate extension FluentDataContextKey {
    static var databaseConfigurationFactory: DatabaseConfigurationFactory {
        switch Self.persistence {
        case .bundle:
            // swiftlint:disable force_unwrapping
            let filePath = Self.filePath!
            // swiftlint:enable force_unwrapping
            let folder = FileManager.default.temporaryDirectory
            let tempPath = folder.appendingPathComponent("\(UUID().uuidString).sqlite")
            do {
                try FileManager.default.copyItem(at: filePath, to: tempPath)
                return .sqlite(.file(tempPath.absoluteString))
            } catch {
                fatalError("Unable to copy bundled database \(tempPath) from bundle \(filePath) to temporary directory.")
            }

        case .file:
            // swiftlint:disable force_unwrapping
            let filePath = Self.filePath!
            // swiftlint:enable force_unwrapping
            return .sqlite(.file(filePath.absoluteString))

        case .memory:
            return .sqlite(.memory)
        }
    }

    static var filePath: URL? {
        switch Self.persistence {
        case .bundle(let bundle, let name):
            if let path = bundle.url(forResource: name, withExtension: "sqlite") {
                return path
            } else {
                fatalError("Database \(name).sqlite not found in \(bundle.bundlePath).")
            }

        case .file(let name):
            guard let folder = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
                fatalError("Unknown to store database `\(name)` (1)")
            }

            guard let urlSafePersistenceName = name.addingPercentEncoding(
                withAllowedCharacters: CharacterSet.urlPathAllowed.subtracting(CharacterSet.symbols).subtracting(CharacterSet.newlines)
            ) else {
                fatalError("Unknown to store database `\(name)` (2)")
            }

            let filePath = folder.appendingPathComponent("\(urlSafePersistenceName).sqlite")
            return filePath

        case .memory:
            return nil
        }
    }

    static var removableFilePath: URL? {
        switch Self.persistence {
        case .bundle, .memory:
            return nil

        case .file:
            return filePath
        }
    }

    static var shouldMigrate: Bool {
        switch Self.persistence {
        case .bundle:
            return false

        case .file, .memory:
            return true
        }
    }
}
