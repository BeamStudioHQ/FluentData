import FluentData
import ToDoCore

struct AppEnvironment {
    let container: DIContainer<AppState>
}

extension AppEnvironment {
    static func bootstrap() async throws -> AppEnvironment {
        let appState = AppState()

        let fluentContext = FluentDataContext(
            contextKey: ToDoPersistenceContextKey.self,
            makeDefault: false
        )

        let interactors = DIContainer<AppState>.Interactors(
            projects: ConcreteProjectsInteractor(repository: ConcreteProjectsRepository(fluentContext: fluentContext)),
            tasks: ConcreteTasksInteractor(repository: ConcreteTasksRepository(fluentContext: fluentContext))
        )

        let container = DIContainer(appState: appState, interactors: interactors)

        return AppEnvironment(container: container)
    }
}
