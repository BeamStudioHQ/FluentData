import SwiftUI

public protocol TasksInteractor {
    // MARK: - Queries
    func load(tasks: LoadableSubject<[TaskModel]>, filters: [TaskModel.Filter], sort: TaskModel.SortCriteria, direction: SortDirection, _ cancelBag: CancelBag?)

    // MARK: - Side effects
    func create(task: TaskModel.CreateFormData) async throws
    func delete(tasks: [TaskModel]) async throws
    func toggleDone(of task: TaskModel) async throws
    func update(task: TaskModel.EditFormData) async throws
}

extension TasksInteractor {
    func load(tasks: LoadableSubject<[TaskModel]>, filters: [TaskModel.Filter]? = nil, sort: TaskModel.SortCriteria? = nil, direction: SortDirection? = nil, _ cancelBag: CancelBag?) {
        self.load(tasks: tasks, filters: filters ?? [], sort: sort ?? .name, direction: direction ?? .ascending, cancelBag)
    }
}

public struct ConcreteTasksInteractor: TasksInteractor {
    let repository: any TasksRepository

    public init(repository: any TasksRepository) {
        self.repository = repository
    }

    public func create(task form: TaskModel.CreateFormData) async throws {
        try await repository.create(task: form)
    }

    public func delete(tasks: [TaskModel]) async throws {
        try await repository.delete(tasks: tasks)
    }

    public func load(tasks loadable: LoadableSubject<[TaskModel]>, filters: [TaskModel.Filter], sort: TaskModel.SortCriteria, direction: SortDirection, _ cancelBag: CancelBag?) {
        let cancelBag = cancelBag ?? CancelBag()

        loadable.wrappedValue.setIsLoading(cancelBag: cancelBag)

        repository.tasks {
            var qb = $0
                .with(\.$project)

            filters.forEach { filter in
                switch filter {
                case .done(let value):
                    qb = qb.filter(\.$done, .equal, value)

                case .project(let project):
                    guard let projectId = project.id else { return }
                    qb = qb.filter(\.$project.$id, .equal, projectId)
                }
            }

            switch sort {
            case .createdAt:
                qb = qb.sort(\.$createdAt, direction.asFluentSortDirection)

            case .done:
                qb = qb.sort(\.$done, direction.asFluentSortDirection)

            case .name:
                qb = qb.sort(\.$name, direction.asFluentSortDirection)

            case .updatedAt:
                qb = qb.sort(\.$updatedAt, direction.asFluentSortDirection)
            }

            return qb
        }
        .sinkToLoadable { entries in
            withAnimation {
                loadable.wrappedValue = entries
            }
        }
            .store(in: cancelBag)
    }


    public func toggleDone(of task: TaskModel) async throws
    {
        try await repository.toggleDone(of: task)
    }

    public func update(task: TaskModel.EditFormData) async throws {
        try await repository.update(task: task)
    }
}
