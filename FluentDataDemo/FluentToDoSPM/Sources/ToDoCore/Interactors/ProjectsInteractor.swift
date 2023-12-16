import SwiftUI

public protocol ProjectsInteractor {
    // MARK: - Queries
    func load(projects: LoadableSubject<[ProjectModel]>, sort: ProjectModel.SortCriteria, direction: SortDirection, _ cancelBag: CancelBag?)

    // MARK: - Side effects
    func create(project: ProjectModel.CreateFormData) async throws
    func delete(projects: [ProjectModel]) async throws
    func update(project: ProjectModel.EditFormData) async throws
}

extension ProjectsInteractor {
    func load(projects: LoadableSubject<[ProjectModel]>, sort: ProjectModel.SortCriteria? = nil, direction: SortDirection? = nil, _ cancelBag: CancelBag?) {
        self.load(projects: projects, sort: sort ?? .name, direction: direction ?? .ascending, cancelBag)
    }
}

public struct ConcreteProjectsInteractor: ProjectsInteractor {
    let repository: any ProjectsRepository

    public init(repository: any ProjectsRepository) {
        self.repository = repository
    }

    public func create(project form: ProjectModel.CreateFormData) async throws {
        try await repository.create(project: form)
    }

    public func delete(projects: [ProjectModel]) async throws {
        try await repository.delete(projects: projects)
    }

    public func load(projects loadable: LoadableSubject<[ProjectModel]>, sort: ProjectModel.SortCriteria, direction: SortDirection, _ cancelBag: CancelBag?) {
        let cancelBag = cancelBag ?? CancelBag()

        loadable.wrappedValue.setIsLoading(cancelBag: cancelBag)

        repository.projects {
            var qb = $0

            switch sort {
            case .createdAt:
                qb = qb.sort(\.$createdAt, direction.asFluentSortDirection)

            case .name:
                qb = qb.sort(\.$name, direction.asFluentSortDirection)
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

    public func update(project: ProjectModel.EditFormData) async throws {
        try await repository.update(project: project)
    }
}
