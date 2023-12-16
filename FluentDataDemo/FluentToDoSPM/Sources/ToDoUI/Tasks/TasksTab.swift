import SwiftUI

struct TasksTab: View {
    var body: some View {
        NavigationStack {
            TasksView()
                .navigationTitle("Tasks")
        }
        .tabItem {
            Label("Tasks", systemImage: "rectangle.stack.fill")
        }
    }
}
