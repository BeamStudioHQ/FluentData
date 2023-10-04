/// Errors occuring while working with read-only databases
public enum ReadOnlyDatabaseError: Error {
    /// Thrown when trying to alter a read-only database
    case invalidOperation
}
