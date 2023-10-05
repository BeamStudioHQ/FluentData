import FluentData

public final class ProjectModel: Model {
    public static let schema: String = "projects"
    public static let space: String? = nil

    enum FieldKeys {
        static let createdAt: FieldKey = "created_at"
        static let description: FieldKey = "description"
        static let name: FieldKey = "name"
        static let updatedAt: FieldKey = "updated_at"
    }

    @ID
    public var id: UUID?

    @Field(key: FieldKeys.name)
    public var name: String
    
    @Field(key: FieldKeys.description)
    public var description: String

    @Children(for: \.$project)
    public var tasks: [TaskModel]

    @Timestamp(key: FieldKeys.createdAt, on: .create)
    var createdAt: Date?

    @Timestamp(key: FieldKeys.updatedAt, on: .update)
    var updatedAt: Date?

    public init() {}

    public init(form: CreateFormData) throws {
        let errors = form.validationErrors
        guard errors.isEmpty else { throw FormError.invalidData(errors) }

        self.name = form.name
        self.description = form.description
    }
}

extension ProjectModel {
    public struct CreateFormData { // WIP Validable protocol
        public init() {
            self.description = ""
            self.name = ""
        }

        public var description: String
        public var name: String

        public var validationErrors: [Error] {
            // WIP
            return []
        }
    }
}

extension ProjectModel {
    public struct EditFormData {
        public init(from project: ProjectModel) { }
    }
}

enum FormError: Error {
    case invalidData([Error])
}
