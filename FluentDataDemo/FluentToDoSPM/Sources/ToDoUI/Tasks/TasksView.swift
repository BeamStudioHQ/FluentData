import SwiftUI
import ToDoCore

struct TasksView: View {
    @Environment(AppState.self) private var appState
    @Environment(DIContainer<AppState>.self) private var container

    private var cancelBag = CancelBag()
    @State private var error: Error?
    @State private(set) var loadable: Loadable<[TaskModel]>
    @State private var sortCriteria: TaskModel.SortCriteria = .name
    @State private var sortDirection: SortDirection = .ascending

    var body: some View {
        self.content
            .onChange(of: sortCriteria, initial: false) { reload() }
            .onChange(of: sortDirection, initial: false) { reload() }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { TasksSortingMenu(sortCriteria: $sortCriteria, sortDirection: $sortDirection) }
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
    }

    init(loadable: Loadable<[TaskModel]> = .notRequested) {
        self._loadable = .init(initialValue: loadable)
    }
}

// MARK: - Side Effects

extension TasksView {
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
            .load(tasks: $loadable, filters: [], sort: sortCriteria, direction: sortDirection, cancelBag)
    }
}

// MARK: - Loading Content

extension TasksView {
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

extension TasksView {
    @ViewBuilder
    func loadedView(_ loaded: [TaskModel], showLoading: Bool) -> some View {
        if showLoading {
            ProgressView().padding()
        }

        if loaded.isEmpty {
            EmptyTasksCollectionView()
        } else {
            ForEach(loaded, id: \.id) { item in
                TaskListCell(item: item)
            }
            .onDelete { indexSet in delete(tasks: loaded.pick(at: indexSet)) }
        }
    }
}
