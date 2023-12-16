import Dispatch
import SwiftUI
import ToDoCore

struct ProjectCreationSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(DIContainer<AppState>.self) private var container
    @Environment(\.dismiss) private var dismiss

    @State private var error: Error?
    @State private var formData = ProjectModel.CreateFormData()
    private let placeholder = Placeholders.all.randomElement()!

    var body: some View {
        NavigationStack {
            List {
                if let error {
                    ErrorView(error: error)
                }

                nameSection
                descriptionSection

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
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var descriptionSection: some View {
        Section {
            TextField(placeholder.description, text: $formData.description)
        } header: {
            Text(verbatim: "Description")
            + Text(" *")
                .foregroundStyle(.red)
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
}

// MARK: - Side effects

extension ProjectCreationSheet {
    private func save() {
        Task {
            do {
                try await container.interactors.projects.create(project: formData)
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

extension ProjectCreationSheet {
    enum Placeholders {
        static let all: [ProjectModel.CreateFormData] = [groceries, housekeeping]

        static let groceries: ProjectModel.CreateFormData = {
            var form = ProjectModel.CreateFormData()
            form.name = "Groceries"
            form.description = "For the love of food"
            return form
        }()

        static let housekeeping: ProjectModel.CreateFormData = {
            var form = ProjectModel.CreateFormData()
            form.name = "Housekeeping"
            form.description = "Another one fights the dust"
            return form
        }()
    }
}
