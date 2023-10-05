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

    public init(form: TaskModel.CreateFormData) throws {
        let errors = form.validationErrors
        guard errors.isEmpty else { throw FormError.invalidData(errors) }

        self.$project.id = try form.project!.requireID()

        self.name = form.name
        self.description = form.description
        self.done = false
    }
}

extension TaskModel {
    public struct CreateFormData: Validatable {
        public init() {
            self.description = ""
            self.name = ""
            self.project = nil
        }

        public var description: String
        public var name: String
        public var project: ProjectModel?

        public var validationErrors: [Error] {
            var errors: [Error] = []

            if description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errors.append(ValidationError.field(name: "description", reason: "You need to provide a description"))
            }

            if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errors.append(ValidationError.field(name: "name", reason: "You need to provide a name"))
            }

            if project?._$idExists != true {
                errors.append(ValidationError.field(name: "project", reason: "A task must be part of a project"))
            }

            return errors
        }
    }
}

extension TaskModel {
    public struct EditFormData {
        public init(from project: ProjectModel) { }
    }
}

extension TaskModel {
    public enum Filter {
        case done(Bool)
        case project(ProjectModel)
    }
}

extension TaskModel {
    public enum SortCriteria: Equatable {
        case createdAt
        case done
        case name
        case updatedAt
    }
}
