import Observation

@Observable
public class DIContainer<AppState> {
    public let appState: AppState
    public let interactors: Interactors

    public init(appState: AppState, interactors: Interactors) {
        self.appState = appState
        self.interactors = interactors
    }
}

public extension DIContainer {
    struct Interactors {
        public let projects: ProjectsInteractor
        public let tasks: TasksInteractor

        public init(projects: ProjectsInteractor, tasks: TasksInteractor) {
            self.projects = projects
            self.tasks = tasks
        }
    }
}
