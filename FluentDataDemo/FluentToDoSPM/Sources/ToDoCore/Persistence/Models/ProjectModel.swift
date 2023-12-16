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

extension ProjectModel: Hashable {
    public static func == (lhs: ProjectModel, rhs: ProjectModel) -> Bool {
        if lhs._$idExists, rhs._$idExists, lhs.id == rhs.id {
            return true
        }

        return lhs.name == rhs.name &&
            lhs.description == rhs.description
    }

    public var hashValue: Int {
        var hasher = Hasher()
        self.hash(into: &hasher)
        return hasher.finalize()
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(description)
    }
}

extension ProjectModel {
    public struct CreateFormData: Validatable {
        public init() {
            self.description = ""
            self.name = ""
        }

        public var description: String
        public var name: String

        public var validationErrors: [Error] {
            var errors: [Error] = []

            if description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errors.append(ValidationError.field(name: "description", reason: "You need to provide a description"))
            }

            if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errors.append(ValidationError.field(name: "name", reason: "You need to provide a name"))
            }

            return errors
        }
    }
}

extension ProjectModel {
    public struct EditFormData {
        public init(from project: ProjectModel) { }
    }
}

extension ProjectModel {
    public enum SortCriteria: Equatable {
        case createdAt
        case name
    }
}
