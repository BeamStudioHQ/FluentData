import SwiftUI

public struct CapsuleButtonStyle<BackgroundStyle: ShapeStyle>: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled: Bool

    private let background: BackgroundStyle
    private let verticalPadding: CGFloat

    public init(background: BackgroundStyle, verticalPadding: CGFloat = 12) {
        self.background = background
        self.verticalPadding = verticalPadding
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .fontWeight(.semibold)
            .padding(.horizontal)
            .padding(.vertical, verticalPadding)
            .background(background)
            .brightness(configuration.isPressed ? -0.2 : 0)
            .clipShape(Capsule())
            .opacity(isEnabled ? 1 : 0.5)
            .animation(.easeInOut(duration: 0.25), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.125), value: isEnabled)
    }
}
