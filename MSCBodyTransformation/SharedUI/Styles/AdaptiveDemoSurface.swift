import SwiftUI

private struct AdaptiveDemoSurfaceModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency)
    private var shouldReduceTransparency

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *), !shouldReduceTransparency {
            content
                .glassEffect(
                    .regular,
                    in: .rect(cornerRadius: AppRadius.large)
                )
        } else {
            content
                .background(
                    Color.appSurface,
                    in: RoundedRectangle(
                        cornerRadius: AppRadius.large,
                        style: .continuous
                    )
                )
                .overlay {
                    RoundedRectangle(
                        cornerRadius: AppRadius.large,
                        style: .continuous
                    )
                    .stroke(Color.appBorder, lineWidth: 1)
                }
        }
    }
}

extension View {
    func adaptiveDemoSurface() -> some View {
        modifier(AdaptiveDemoSurfaceModifier())
    }
}
