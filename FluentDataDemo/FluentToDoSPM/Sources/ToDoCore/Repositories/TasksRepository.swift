import Combine
import FluentData

public protocol TasksRepository {
    // MARK: Queries
    func tasks(queryBuilder: @escaping (QueryBuilder<TaskModel>) -> QueryBuilder<TaskModel>) -> AnyPublisher<[TaskModel], Error>

    // MARK: Side effects
    func create(task: TaskModel.CreateFormData) async throws
    func delete(tasks: [TaskModel]) async throws
    func toggleDone(of task: TaskModel) async throws
    func update(task: TaskModel.EditFormData) async throws
}

public struct ConcreteTasksRepository: TasksRepository {
    let fluentContext: FluentDataContext

    public init(fluentContext: FluentDataContext) {
        self.fluentContext = fluentContext
    }

    public func create(task form: TaskModel.CreateFormData) async throws {
        try await TaskModel(form: form).save(on: fluentContext.database)
    }

    public func delete(tasks: [TaskModel]) async throws {
        try await fluentContext.database.transaction { transaction in
            for task in tasks {
                try await task.delete(on: transaction)
            }
        }
    }

    public func tasks(queryBuilder: @escaping (FluentKit.QueryBuilder<TaskModel>) -> FluentKit.QueryBuilder<TaskModel>) -> AnyPublisher<[TaskModel], Error> {
        FluentQuery(context: fluentContext, queryBuilder: queryBuilder).publisher
    }


    public func toggleDone(of task: TaskModel) async throws {
        task.done.toggle()
        try await task.save(on: fluentContext.database)
    }

    public func update(task: TaskModel.EditFormData) async throws {
        fatalError("Not implemented")
    }
}
