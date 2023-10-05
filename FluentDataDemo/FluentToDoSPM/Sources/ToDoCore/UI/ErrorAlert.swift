import SwiftUI

private struct ErrorAlert: ViewModifier {
    @Binding var error: Error?

    func body(content: Content) -> some View {
        let isPresented = Binding(get: {
            error != nil
        }, set: { newValue in
            if false == newValue {
                error = nil
            }
        })

        content
            .alert(isPresented: isPresented) {
                if let error = error {
                    Alert(
                        title: Text(verbatim: "Oops!"),
                        message: Text(verbatim: "An error occured...\n\n\(error)")
                    )
                } else {
                    Alert(
                        title: Text(verbatim: "Oops!"),
                        message: Text(verbatim: "An unknown error occurred...")
                    )
                }
            }
    }
}

public extension View {
    func errorAlert(error: Binding<Error?>) -> some View {
        modifier(ErrorAlert(error: error))
    }
}
