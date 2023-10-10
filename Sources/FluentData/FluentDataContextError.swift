public enum FluentDataContextError: Error {
    case bundledDatabaseNotFound
    case invalidDatabaseName
    case unableToOpenDatabase
    case unknownPathToDatabaseFile
}
