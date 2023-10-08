import Combine
import FluentData
import SwiftUI
import ToDoCore

struct ProjectPicker: View {
    @Binding private var project: ProjectModel?

    @State private var projects: [ProjectModel] = []
    private let projectsQuery = FluentQuery<ProjectModel>(contextKey: ToDoPersistenceContextKey.self) { $0.sort(\.$name) }

    public init(project: Binding<ProjectModel?>) {
        self._project = project
    }

    @ViewBuilder
    var body: some View {
        Picker(selection: $project) {
            if projects.count > 5 {
                Text(verbatim: "")
                    .tag(ProjectModel?.none)
            }

            ForEach(projects, id: \.self) { item in
                Text(verbatim: item.name)
                    .tag(ProjectModel?.some(item))
            }
        } label: {
            EmptyView()
        }
        .if(projects.count <= 5) { view in
            view.pickerStyle(.inline)
        }
        .if(projects.count > 5) { view in
            view.pickerStyle(.wheel)
        }
        .onReceive(projectsQuery.publisher.asNeverFailing()) {
            projects = $0
        }
    }
}
