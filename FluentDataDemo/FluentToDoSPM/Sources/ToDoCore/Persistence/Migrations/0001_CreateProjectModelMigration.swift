import FluentData

struct CreateProjectModelMigration: AsyncMigration {
    func prepare(on database: FluentKit.Database) async throws {
        typealias Model = ProjectModel
        typealias ModelKeys = Model.FieldKeys

        try await database.schema(Model.schema, space: Model.space)
            .id()
            .field(ModelKeys.name, .string, .required)
            .field(ModelKeys.description, .string, .required)
            .field(ModelKeys.createdAt, .datetime, .required)
            .field(ModelKeys.updatedAt, .datetime, .required)
            .create()
    }
    
    func revert(on database: FluentKit.Database) async throws {
        fatalError("Migration doesn't support revert")
    }
}
