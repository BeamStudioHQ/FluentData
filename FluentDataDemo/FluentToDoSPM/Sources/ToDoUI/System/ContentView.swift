import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        @Bindable var bindableAppState = appState

        TabView(selection: $bindableAppState.routing.selectedTab) {
            ProjectsTab()
                .tag(SelectedTab.projects)

            TasksTab()
                .tag(SelectedTab.tasks)
        }
        .sheet(isPresented: $bindableAppState.routing.projects.showCreationSheet) { ProjectCreationSheet() }
        .sheet(item: $bindableAppState.routing.tasks.showCreationSheet) { TaskCreationSheet($0) }
    }
}

extension ContentView {
    enum SelectedTab: Hashable {
        case projects
        case tasks
    }
}
