import Combine

public extension Publisher {
    func asNeverFailing() -> AnyPublisher<Output, Never> {
        self.map { $0 as Output? }.replaceError(with: nil).compactMap { $0 }.eraseToAnyPublisher()
    }
}
