import Combine
import Foundation
import FluentData

public protocol ProjectsRepository {
    // MARK: Queries
    func projects(queryBuilder: @escaping (QueryBuilder<ProjectModel>) -> QueryBuilder<ProjectModel>) -> AnyPublisher<[ProjectModel], Error>

    // MARK: Side effects
    func create(project: ProjectModel.CreateFormData) async throws
    func delete(projects: [ProjectModel]) async throws
    func update(project: ProjectModel.EditFormData) async throws
}

public struct ConcreteProjectsRepository: ProjectsRepository {
    let fluentContext: FluentDataContext

    public init(fluentContext: FluentDataContext) {
        self.fluentContext = fluentContext
    }

    public func create(project form: ProjectModel.CreateFormData) async throws {
        try await fluentContext.database.transaction { transaction in
            let project = try ProjectModel(form: form)
            try await project.save(on: transaction)

            var taskForm = TaskModel.CreateFormData()
            taskForm.name = "Task 1"
            taskForm.description = "Something to do"
            taskForm.project = project
            try await TaskModel(form: taskForm).save(on: transaction)

            taskForm.name = "Task 2"
            taskForm.description = "Something else to do"
            try await TaskModel(form: taskForm).save(on: transaction)
        }
    }

    public func delete(projects: [ProjectModel]) async throws {
        try await fluentContext.database.transaction { transaction in
            for project in projects {
                try await project.delete(on: transaction)
            }
        }
    }

    public func projects(queryBuilder: @escaping (FluentKit.QueryBuilder<ProjectModel>) -> FluentKit.QueryBuilder<ProjectModel>) -> AnyPublisher<[ProjectModel], Error> {
        FluentQuery(context: fluentContext, queryBuilder: queryBuilder).publisher
    }

    public func update(project: ProjectModel.EditFormData) async throws {
        fatalError("Not implemented")
    }
}
