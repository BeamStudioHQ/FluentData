import Combine
import Dispatch
import FluentKit

/// A query object, auto-updating with Combine
public class FluentQuery<Model: FluentKit.Model> {
    private let context: FluentDataContext
    internal let queryBuilder: (QueryBuilder<Model>) -> QueryBuilder<Model>
    internal let queryId: UUID
    internal let subject = CurrentValueSubject<[Model], Error>([])
    public var publisher: AnyPublisher<[Model], Error> { subject.receive(on: DispatchQueue.main).eraseToAnyPublisher() }

    public init(
        context: FluentDataContext,
        queryBuilder: @escaping (QueryBuilder<Model>) -> QueryBuilder<Model> = { $0 }
    ) {
        self.context = context
        self.queryBuilder = queryBuilder
        self.queryId = UUID()
        self.context.register(self)
    }
    
    /// Create a query object to fetch entries from the specified database context
    /// - Parameters:
    ///   - contextKey: the key which uniquely identify this context
    ///   - queryBuilder: optional, can be specified to customize the query, such as the sort order
    public convenience init<TContextKey: FluentDataContextKey>(
        contextKey: TContextKey.Type,
        queryBuilder: @escaping (QueryBuilder<Model>) -> QueryBuilder<Model> = { $0 }
    ) {
        self.init(context: FluentDataContexts[contextKey], queryBuilder: queryBuilder)
    }
    
    /// Create a query object to fetch entries from the default database context
    /// - Parameters:
    ///   - queryBuilder: optional, can be specified to customize the query, such as the sort order
    public convenience init(
        queryBuilder: @escaping (QueryBuilder<Model>) -> QueryBuilder<Model> = { $0 }
    ) {
        guard let context = FluentDataContexts.default else {
            fatalError("FluentData has no default context")
        }
        self.init(context: context, queryBuilder: queryBuilder)
    }
    
    deinit {
        self.context.deregister(self)
    }
}
