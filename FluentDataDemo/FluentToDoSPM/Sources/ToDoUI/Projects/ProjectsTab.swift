import SwiftUI

struct ProjectsTab: View {
    var body: some View {
        NavigationStack {
            ProjectsView()
                .navigationTitle("Projects")
        }
        .tabItem { Label("Projects", systemImage: "rectangle.3.group.fill") }
    }
}
