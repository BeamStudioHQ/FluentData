import SwiftUI

public struct CapsuleButtonStyle<BackgroundStyle: ShapeStyle>: ButtonStyle {
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
            .clipShape(Capsule())
    }
}
