import SwiftUI
import ToDoCore

struct ProjectsView: View {
    @Environment(AppState.self) private var appState
    @Environment(DIContainer<AppState>.self) private var container

    @State var cancelBag = CancelBag()
    @State private var error: Error?
    @State private(set) var loadable: Loadable<[ProjectModel]>

    var body: some View {
        self.content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        appState.routing.projects.showCreationSheet = true
                    } label: {
                        Label("Add project", systemImage: "plus")
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

                case let .isLoading(last, _):
                    loadingView(last)

                case let .loaded(previousLoad):
                    loadedView(previousLoad, showLoading: false)

                case let .failed(error):
                    failedView(error)
                }
            }
        }
    }

    init(loadable: Loadable<[ProjectModel]> = .notRequested) {
        self._loadable = .init(initialValue: loadable)
    }
}

// MARK: - Side Effects

extension ProjectsView {
//    func delete(wallets: [WalletModel]) {
//        Task {
//            do {
//                try await container.interactors.walletsInteractor.delete(wallets: wallets)
//            } catch {
//                DispatchQueue.main.async {
//                    self.error = error
//                }
//            }
//        }
//    } // WIP

    func reload() {
        container.interactors.projects
            .load(projects: $loadable, cancelBag)
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
            //.onDelete { indexSet in delete(wallets: wallets.pick(at: indexSet)) } // WIP
        }
    }
}
