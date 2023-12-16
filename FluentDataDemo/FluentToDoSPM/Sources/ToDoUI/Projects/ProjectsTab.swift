import SwiftUI
import ToDoCore

struct ProjectsTab: View {
    var body: some View {
        NavigationStack {
            ProjectsView()
                .navigationTitle("Projects")
                .navigationDestination(for: ProjectModel.self) { project in ProjectDetailView(project: project) }
        }
        .tabItem {
            Label("Projects", systemImage: "rectangle.3.group.fill")
        }
    }
}
