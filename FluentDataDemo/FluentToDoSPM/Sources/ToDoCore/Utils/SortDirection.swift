import FluentData

public enum SortDirection: Equatable {
    case ascending
    case descending
}

extension SortDirection {
    var asFluentSortDirection: DatabaseQuery.Sort.Direction {
        switch self {
        case .ascending: return .ascending
        case .descending: return .descending
        }
    }
}
