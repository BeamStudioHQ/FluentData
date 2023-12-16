import SwiftUI

public struct ErrorView: View {
    let error: Error
    let retryAction: (() -> Void)?

    public init(error: Error, retryAction: (() -> Void)? = nil) {
        self.error = error
        self.retryAction = retryAction
    }

    public var body: some View {
        VStack {
            Image(systemName: "exclamationmark.octagon.fill")
                .resizable()
                .opacity(0.5)
                .frame(width: 56, height: 56)
                .padding(3)
                .foregroundColor(.red)

            Text(verbatim: "An error occured")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.red)
                .padding(.vertical, 8)

            Text(error.localizedDescription)
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if let retryAction {
                Button(action: retryAction) {
                    Text(verbatim: "Try again")
                        .bold()
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}
