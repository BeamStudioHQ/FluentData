public protocol Validatable {
    var validationErrors: [Error] { get }
}

public enum ValidationError: Error {
    case field(name: String, reason: String)
}
