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

        public init(projects: ProjectsInteractor) {
            self.projects = projects
        }
    }
}
