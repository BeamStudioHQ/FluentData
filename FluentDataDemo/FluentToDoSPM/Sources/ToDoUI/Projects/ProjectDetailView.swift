import FluentData
import SwiftUI
import ToDoCore

struct ProjectDetailView: View {
    let project: ProjectModel

    var body: some View {
        List {
            Section {
                Text(verbatim: project.description)
            } header: {
                Text(verbatim: "Description")
            }

            TasksSection(project: project)
        }
        .navigationTitle(project.name)
    }
}

extension ProjectDetailView {
    struct TasksSection: View {
        @Environment(AppState.self) private var appState
        @Environment(DIContainer<AppState>.self) private var container

        private var cancelBag = CancelBag()
        @State private var error: Error?
        @State private(set) var loadable: Loadable<[TaskModel]>
        @State var project: ProjectModel
        @State private var sortCriteria: TaskModel.SortCriteria = .name
        @State private var sortDirection: SortDirection = .ascending

        var body: some View {
            Section {
                self.content
            } header: {
                HStack {
                    Text(verbatim: "Tasks")

                    Spacer()

                    Button {
                        appState.routing.tasks.showCreationSheet = true
                    } label: {
                        Label("Create task", systemImage: "plus")
                            .labelStyle(.iconOnly)
                    }

                    TasksSortingMenu(sortCriteria: $sortCriteria, sortDirection: $sortDirection)
                }
            }
            .onChange(of: project, initial: false) { reload() }
            .onChange(of: sortCriteria, initial: false) { reload() }
            .onChange(of: sortDirection, initial: false) { reload() }
        }

        @ViewBuilder
        private var content: some View {
            switch loadable {
            case .notRequested:
                NotRequestedView(perform: reload)

            case let .isLoading(lastLoad, _):
                loadingView(lastLoad)

            case let .loaded(loaded):
                loadedView(loaded, showLoading: false)

            case let .failed(error):
                failedView(error)
            }
        }

        init(loadable: Loadable<[TaskModel]> = .notRequested, project: ProjectModel) {
            self._loadable = .init(initialValue: loadable)
            self._project = .init(initialValue: project)
        }
    }
}

// MARK: - Side Effects

extension ProjectDetailView.TasksSection {
    func delete(tasks: [TaskModel]) {
        Task {
            do {
                try await container.interactors.tasks.delete(tasks: tasks)
            } catch {
                DispatchQueue.main.async {
                    self.error = error
                }
            }
        }
    }

    func reload() {
        container.interactors.tasks
            .load(
                tasks: $loadable,
                filters: [
                    .project(project)
                ],
                sort: sortCriteria,
                direction: sortDirection,
                cancelBag
            )
    }
}

// MARK: - Loading Content

extension ProjectDetailView.TasksSection {
    @ViewBuilder
    func loadingView(_ previouslyLoaded: [TaskModel]?) -> some View {
        if let previouslyLoaded {
            loadedView(previouslyLoaded, showLoading: true)
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    func failedView(_ error: Error) -> some View {
        ErrorView(error: error) {
            self.reload()
        }
    }
}

// MARK: - Displaying Content

extension ProjectDetailView.TasksSection {
    @ViewBuilder
    func loadedView(_ loaded: [TaskModel], showLoading: Bool) -> some View {
        if showLoading {
            ProgressView().padding()
        }

        if loaded.isEmpty {
            EmptyTasksCollectionView()
        } else {
            ForEach(loaded, id: \.id) { item in
                TaskListCell(item: item, showProject: false)
            }
            .onDelete { indexSet in delete(tasks: loaded.pick(at: indexSet)) }
        }
    }
}
