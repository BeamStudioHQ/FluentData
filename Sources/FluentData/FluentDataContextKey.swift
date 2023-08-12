/// Supported storage mediums for a context
///
/// ``memory`` won't persist data across two launches of your app. This can be quite useful during the development process.
///
/// ``file(_:)`` on the other hand, will persist data on disk using the SQLite format.
/// The file will be located in the "Application Support" folder of the currently running application.
public enum FluentDataPersistence {
    case memory
    case file(_ name: String)
}

/// An unique identifier for a database context
public protocol FluentDataContextKey {
    /// The list of migrations to apply
    ///
    /// Migrations allows your data model to evolve with your app. Migrations are automatically applied in order when the database context is created.
    ///
    /// Fluent keeps track of migrations that have already been applied.
    ///
    /// For more information about the migration system of Fluent, see [Fluent's migration documentation](https://docs.vapor.codes/fluent/migration/)
    static var migrations: [Migration] { get }
    
    /// Specify how the data must be persisted for this context
    static var persistence: FluentDataPersistence { get }
}
