import Dispatch
import SwiftUI
import ToDoCore

struct TaskCreationSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(DIContainer<AppState>.self) private var container
    @Environment(\.dismiss) private var dismiss

    @State private var error: Error?
    @State private var formData: TaskModel.CreateFormData
    private let placeholder = Placeholders.all.randomElement()!

    public init(_ routingArgs: TasksRouting.CreationSheet) {
        var formData = TaskModel.CreateFormData()
        if case .withProject(let project) = routingArgs {
            formData.project = project
        }
        _formData = .init(initialValue: formData)
    }

    var body: some View {
        NavigationStack {
            List {
                if let error {
                    ErrorView(error: error)
                }

                nameSection
                descriptionSection
                projectSection

                Button {
                    save()
                } label: {
                    Text("Create")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CapsuleButtonStyle(background: .blue))
                .disabled(!formData.validationErrors.isEmpty)
                .listRowInsets(.none)
                .listRowBackground(Color.clear)
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var descriptionSection: some View {
        Section {
            TextField(placeholder.description, text: $formData.description)
        } header: {
            Text(verbatim: "Description")
        }
    }

    private var nameSection: some View {
        Section {
            TextField(placeholder.name, text: $formData.name)
        } header: {
            Text(verbatim: "Name")
            + Text(" *")
                .foregroundStyle(.red)
        }
    }

    private var projectSection: some View {
        Section {
            ProjectPicker(project: $formData.project)
        } header: {
            Text(verbatim: "Project")
            + Text(" *")
                .foregroundStyle(.red)
        }
    }
}

// MARK: - Side effects

extension TaskCreationSheet {
    private func save() {
        Task {
            do {
                try await container.interactors.tasks.create(task: formData)
                DispatchQueue.main.async {
                    dismiss()
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error
                }
            }
        }
    }
}

// MARK: - Placeholders

extension TaskCreationSheet {
    enum Placeholders {
        static let all: [TaskModel.CreateFormData] = [changeTheLightBulb, fixTheRoof]

        static let changeTheLightBulb: TaskModel.CreateFormData = {
            var form = TaskModel.CreateFormData()
            form.name = "Change the light bulb"
            form.description = "The one in the basement is not working anymore"
            return form
        }()

        static let fixTheRoof: TaskModel.CreateFormData = {
            var form = TaskModel.CreateFormData()
            form.name = "Fix the roof"
            form.description = "Before the rain season starts..."
            return form
        }()
    }
}
