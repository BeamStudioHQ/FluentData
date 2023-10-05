import SwiftUI
import ToDoCore

struct TaskListCell: View {
    @Environment(DIContainer<AppState>.self) private var container

    @State var error: Error? = nil
    var item: TaskModel
    var showProject: Bool = true

    var body: some View {
        HStack(alignment: .center) {
            Button {
                Task {
                    do {
                        try await container.interactors.tasks.toggleDone(of: item)
                    } catch {
                        self.error = error
                    }
                }
            } label: {
                Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.done ? .green : .secondary)
            }

            VStack(alignment: .leading) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    if showProject {
                        Text(verbatim: item.project.name)
                            .fontWeight(.semibold)
                            .foregroundStyle(.tertiary)
                    }

                    Text(verbatim: item.name)
                        .fontWeight(.bold)
                }

                Text(verbatim: item.description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .errorAlert(error: $error)
    }
}
