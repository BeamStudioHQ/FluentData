import Combine
import FluentData

public protocol ProjectsRepository {
    // MARK: Queries
    func projects(queryBuilder: @escaping (QueryBuilder<ProjectModel>) -> QueryBuilder<ProjectModel>) -> AnyPublisher<[ProjectModel], Error>

    // MARK: Side effects
    func create(project: ProjectModel.CreateFormData) async throws
}

public struct ConcreteProjectsRepository: ProjectsRepository {
    let fluentContext: FluentDataContext

    public init(fluentContext: FluentDataContext) {
        self.fluentContext = fluentContext
    }

    public func create(project form: ProjectModel.CreateFormData) async throws {
        try await ProjectModel(form: form).save(on: fluentContext.database)
    }

    public func projects(queryBuilder: @escaping (FluentKit.QueryBuilder<ProjectModel>) -> FluentKit.QueryBuilder<ProjectModel>) -> AnyPublisher<[ProjectModel], Error> {
        FluentQuery(context: fluentContext, queryBuilder: queryBuilder).publisher
    }
}
