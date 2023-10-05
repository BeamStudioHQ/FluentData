import Dispatch
import SwiftUI
import ToDoCore

struct ProjectCreationSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(DIContainer<AppState>.self) private var container
    @Environment(\.dismiss) private var dismiss

    @State private var error: Error?
    @State private var formData = ProjectModel.CreateFormData()

    var body: some View {
        NavigationStack {
            List {
                nameSection
                descriptionSection

                Button("Create") { // WIP capsule button style
                    save()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .clipShape(Capsule())
                .disabled(!formData.validationErrors.isEmpty)
                .safeAreaPadding()
            }
            .navigationTitle("Project creation")
            .navigationBarTitleDisplayMode(.inline)
            // .errorAlert(error: $error) // WIP
        }
    }

    private var descriptionSection: some View {
        Section {
            TextField("exemple: List of chores to keep the house perfectly clean and safe", text: $formData.description)
                .lineLimit(4, reservesSpace: true)
        } header: {
            Text(verbatim: "Description")
        }
    }

    private var nameSection: some View {
        Section {
            TextField("exemple: Housekeeping", text: $formData.name)
        } header: {
            Text(verbatim: "Name")
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
