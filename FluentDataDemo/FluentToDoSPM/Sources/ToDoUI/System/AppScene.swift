import ToDoCore
import SwiftUI

public struct AppScene: Scene {
    @State private var container: DIContainer<AppState>?

    public var body: some Scene {
        WindowGroup {
            if let container {
                ContentView()
                    .environment(container)
                    .environment(container.appState)
            } else {
                ProgressView()
                    .task {
                        let appEnvironment = try! await AppEnvironment.bootstrap()
                        self.container = appEnvironment.container
                    }
            }
        }
    }

    public init() {}
}
