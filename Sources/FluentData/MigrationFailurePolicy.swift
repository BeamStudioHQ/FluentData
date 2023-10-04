import Foundation

/// Recovery policy FluentData should adopt when a migration fails to execute
///
/// When using ``startFresh`` or ``backupAndStartFresh(backupHandler:)``, the process will crash if a new database cannot be created (similar to ``abort``)
public enum MigrationFailurePolicy {
    /// ``abort`` the process will crash voluntarily. Reasons why the migration failed to execute will be available in the logs.
    case abort

    /// ``backupAndStartFresh(backupHandler:)`` will call the speccified closure with the URL to a copy of the database file which failed to migrate.
    /// After the backup handler returns, the behaviour will be equivalent to ``startFresh``.
    case backupAndStartFresh(backupHandler: (URL) -> Void)

    /// ``startFresh`` will wipe the database content and recreate a new database. This is not recommended in production as it brings data losses
    case startFresh
}
