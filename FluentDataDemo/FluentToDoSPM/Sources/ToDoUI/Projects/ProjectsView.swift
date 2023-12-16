import SwiftUI
import ToDoCore

struct ProjectsView: View {
    @Environment(AppState.self) private var appState
    @Environment(DIContainer<AppState>.self) private var container

    private var cancelBag = CancelBag()
    @State private var error: Error?
    @State private(set) var loadable: Loadable<[ProjectModel]>
    @State private var sortCriteria: ProjectModel.SortCriteria = .name
    @State private var sortDirection: SortDirection = .ascending

    private var hasProjects: Bool {
        switch loadable {
        case .isLoading(let last, _) where last?.isEmpty == false:
            return true

        case .loaded(let projects) where projects.isEmpty == false:
            return true

        default:
            return false
        }
    }

    var body: some View {
        self.content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if hasProjects {
                        Menu {
                            Button {
                                appState.routing.projects.showCreationSheet = true
                            } label: {
                                Label("Project", systemImage: "rectangle.portrait.badge.plus")
                            }

                            Button {
                                appState.routing.tasks.showCreationSheet = .default
                            } label: {
                                Label("Task", systemImage: "rectangle.stack.badge.plus")
                            }
                        } label: {
                            Label("Create", systemImage: "plus")
                                .labelStyle(.iconOnly)
                        }
                    } else {
                        Button {
                            appState.routing.projects.showCreationSheet = true
                        } label: {
                            Label("Create", systemImage: "plus")
                                .labelStyle(.iconOnly)
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker(selection: $sortCriteria) {
                            Text(verbatim: "Name")
                                .tag(ProjectModel.SortCriteria.name)

                            Text(verbatim: "Creation date")
                                .tag(ProjectModel.SortCriteria.createdAt)
                        } label: {
                            Text(verbatim: "Sort by")
                        }

                        Picker(selection: $sortDirection) {
                            Text(verbatim: "Ascending")
                                .tag(SortDirection.ascending)

                            Text(verbatim: "Descending")
                                .tag(SortDirection.descending)
                        } label: {
                            Text(verbatim: "Sort by")
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down.square")
                            .labelStyle(.iconOnly)
                    }
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        List {
            Section {
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
        }
        .onChange(of: sortCriteria, initial: false) { reload() }
        .onChange(of: sortDirection, initial: false) { reload() }
    }

    init(loadable: Loadable<[ProjectModel]> = .notRequested) {
        self._loadable = .init(initialValue: loadable)
    }
}

// MARK: - Side Effects

extension ProjectsView {
    func delete(projects: [ProjectModel]) {
        Task {
            do {
                try await container.interactors.projects.delete(projects: projects)
            } catch {
                DispatchQueue.main.async {
                    self.error = error
                }
            }
        }
    }

    func reload() {
        container.interactors.projects
            .load(projects: $loadable, sort: sortCriteria, direction: sortDirection, cancelBag)
    }
}

// MARK: - Loading Content

extension ProjectsView {
    @ViewBuilder
    func loadingView(_ previouslyLoaded: [ProjectModel]?) -> some View {
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

extension ProjectsView {
    @ViewBuilder
    func loadedView(_ loaded: [ProjectModel], showLoading: Bool) -> some View {
        if showLoading {
            ProgressView().padding()
        }

        if loaded.isEmpty {
            EmptyProjectsCollectionView()
        } else {
            ForEach(loaded, id: \.id) { item in
                ProjectListCell(item: item)
            }
            .onDelete { indexSet in delete(projects: loaded.pick(at: indexSet)) }
        }
    }
}
