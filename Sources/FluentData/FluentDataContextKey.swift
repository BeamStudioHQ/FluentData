import Foundation

/// An unique identifier for a database context
public protocol FluentDataContextKey {
    /// If set, SQL queries will be logged. Defaults to `true` in DEBUG configuration, false otherwise.
    static var logQueries: Bool { get }

    /// Specify FluentData's behaviour if one of the migrations fail. Defaults to ``MigrationFailurePolicy/abort``.
    static var migrationFailurePolicy: MigrationFailurePolicy { get }

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

public extension FluentDataContextKey {
    static var logQueries: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    static var migrationFailurePolicy: MigrationFailurePolicy {
        return .abort
    }

    static var migrations: [Migration] {
        return []
    }
}
