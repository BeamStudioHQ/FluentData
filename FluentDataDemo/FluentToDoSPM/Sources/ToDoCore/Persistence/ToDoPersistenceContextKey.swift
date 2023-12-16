import FluentData

public struct ToDoPersistenceContextKey: FluentDataContextKey {
    public static let migrations: [Migration] = [
        CreateProjectModelMigration(),
        CreateTaskModelMigration(),
    ]

    public static let persistence: FluentData.FluentDataPersistence = .file("todos")
}
