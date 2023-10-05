import FluentData
import SwiftUI

struct EmptyTasksCollectionView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ContentUnavailableView(label: {
            Label("All done!", systemImage: "checkmark.seal.fill")
                .foregroundStyle(.green)
        }, description: {
            Text(
                verbatim: "Take a break, read a book, go for a walk... you made it!"
            )
            .padding(8)
        })
    }
}

