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
        eventLoopGroup = NIOTSEventLoopGroup(loopCount: 1, defaultQoS: .userInitiated)
        threadPool = NIOThreadPool(numberOfThreads: 1)
        threadPool.start()
        
        databases = Databases(threadPool: threadPool, on: eventLoopGroup)
        databases.use(K.databaseConfigurationFactory, as: .sqlite, isDefault: true)
        logger = Logger(label: DatabaseID.sqlite.string, factory: {
            OSLogLogHandler(os.Logger(subsystem: "FluentData", category: $0))
        })
        
        let migrations = Migrations()
        contextKey.migrations.forEach { migrations.add($0) }
        let migrator = Migrator(databases: databases, migrations: migrations, logger: logger, on: eventLoopGroup.next())
        try! migrator.setupIfNeeded().wait()
        try! migrator.prepareBatch().wait()
        
        databases.middleware.use(QueryChangesTrackingMiddleware(tracker: self), on: .sqlite)
        
        // Register the context
        FluentDataContexts[contextKey, makeDefault] = self
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
    let subject: CurrentValueSubject<[Model], Never>
    
    init(
        queryBuilder: QueryBuilder<Model>,
        subject: CurrentValueSubject<[Model], Never>
    ) {
        self.queryBuilder = queryBuilder
        self.subject = subject
    }
    
    func update() {
        queryBuilder.all()
            .whenSuccess {
                subject.send($0)
            }
    }
}

fileprivate extension FluentDataContextKey {
    static var databaseConfigurationFactory: DatabaseConfigurationFactory {
        switch Self.persistence {
        case .memory:
            return .sqlite(.memory)
        case .file(let name):
            let folder = try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let urlSafePersistenceName = name.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed.subtracting(CharacterSet.symbols).subtracting(CharacterSet.newlines))!
            let filePath = folder.appendingPathComponent("\(urlSafePersistenceName).sqlite")
            return .sqlite(.file(filePath.absoluteString))
        }
    }
}
