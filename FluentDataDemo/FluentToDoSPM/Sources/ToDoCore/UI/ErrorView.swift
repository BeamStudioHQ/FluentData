import SwiftUI

public struct ErrorView: View {
    let error: Error
    let retryAction: () -> Void

    public init(error: Error, retryAction: @escaping () -> Void) {
        self.error = error
        self.retryAction = retryAction
    }

    public var body: some View {
        // WIP: Improve ErrorView rendering
        VStack {
            Text(verbatim: "An error occured")
                .font(.title)

            Text(error.localizedDescription)
                .font(.callout)
                .multilineTextAlignment(.center)
                .padding(.bottom, 40)
                .padding()

            Button(action: retryAction) {
                Text(verbatim: "Try again")
                    .bold()
            }
        }
    }
}
