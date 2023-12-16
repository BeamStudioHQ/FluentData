import Observation

@Observable
public class AppState {
    var routing = ViewRouting()
}

public extension AppState {
    struct ViewRouting {
        var selectedTab: ContentView.SelectedTab = .projects

        var projects = ProjectsRouting()
        var tasks = TasksRouting()
    }
}
