public protocol SomeOptional {
    associatedtype Wrapped
    func unwrap() throws -> Wrapped
}

public struct ValueIsMissingError: Error { }

extension Optional: SomeOptional {
    public func unwrap() throws -> Wrapped {
        switch self {
        case let .some(value): return value
        case .none: throw ValueIsMissingError()
        }
    }
}
