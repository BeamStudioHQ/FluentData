import Foundation

public extension Array {
    func pick(at indexSet: IndexSet) -> Self {
        indexSet.compactMap { self[safe: $0] }
    }

    subscript(safe index: Index) -> Element? {
        let isValidIndex = index >= 0 && index < count
        return isValidIndex ? self[index] : nil
    }
}
