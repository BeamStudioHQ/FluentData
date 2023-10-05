public protocol ProjectsInteractor {
    // MARK: - Queries
    func load(projects: LoadableSubject<[ProjectModel]>, _ cancelBag: CancelBag?)

    // MARK: - Side effects
    func create(project: ProjectModel.CreateFormData) async throws
//    func delete(projects: [ProjectModel]) async throws // WIP
//    func update(project: ProjectModel.EditFormData) async throws // WIP
}

public struct ConcreteProjectsInteractor: ProjectsInteractor {
    let repository: any ProjectsRepository

    public init(repository: any ProjectsRepository) {
        self.repository = repository
    }

    public func create(project form: ProjectModel.CreateFormData) async throws {
        try await repository.create(project: form)
    }

    public func load(projects loadable: LoadableSubject<[ProjectModel]>, _ cancelBag: CancelBag?) {
        let cancelBag = cancelBag ?? CancelBag()

        loadable.wrappedValue.setIsLoading(cancelBag: cancelBag)

        repository.projects { $0.sort(\.$name) }
            .sinkToLoadable { loadable.wrappedValue = $0 }
            .store(in: cancelBag)
    }
}
