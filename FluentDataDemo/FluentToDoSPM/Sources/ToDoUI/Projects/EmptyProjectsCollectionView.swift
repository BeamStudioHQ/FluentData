import FluentData
import ToDoCore
import SwiftUI

struct EmptyProjectsCollectionView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ContentUnavailableView(label: {
            Label("No projects found", systemImage: "tray.fill")
        }, description: {
            Text(
                verbatim: "Start by creating your first project and add some tasks to it. Grouping tasks in different projects helps you staying organized."
            )
            .padding(8)
        }, actions: {
            Button("Create a project") {
                appState.routing.projects.showCreationSheet = true
            }
            .buttonStyle(CapsuleButtonStyle(background: .blue))
        })
    }
}

