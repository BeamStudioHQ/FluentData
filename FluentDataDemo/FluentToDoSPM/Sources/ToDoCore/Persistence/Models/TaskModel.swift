import FluentData

public final class TaskModel: Model {
    public static let schema: String = "tasks"
    public static let space: String? = nil

    enum FieldKeys {
        static let createdAt: FieldKey = "created_at"
        static let description: FieldKey = "description"
        static let done: FieldKey = "done"
        static let name: FieldKey = "name"
        static let project: FieldKey = "project_id"
        static let updatedAt: FieldKey = "updated_at"
    }

    @ID
    public var id: UUID?

    @Field(key: FieldKeys.name)
    public var name: String

    @Field(key: FieldKeys.description)
    public var description: String

    @Parent(key: FieldKeys.project)
    public var project: ProjectModel

    @Field(key: FieldKeys.done)
    public var done: Bool

    @Timestamp(key: FieldKeys.createdAt, on: .create)
    var createdAt: Date?

    @Timestamp(key: FieldKeys.updatedAt, on: .update)
    var updatedAt: Date?

    public init() { }

    public init(project: ProjectModel, name: String, description: String) throws {
        self.$project.id = try project.requireID()

        self.name = name
        self.description = description
    }
}
