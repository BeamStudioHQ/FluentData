import SwiftUI

public struct NotRequestedView: View {
    public var perform: () -> Void

    public init(perform: @escaping () -> Void) {
        self.perform = perform
    }

    public var body: some View {
        Color.clear
            .onAppear(perform: perform)
    }
}
