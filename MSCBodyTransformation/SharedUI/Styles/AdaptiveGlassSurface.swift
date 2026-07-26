import SwiftUI

private struct AdaptiveGlassSurfaceModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency)
    private var shouldReduceTransparency
    @Environment(\.colorSchemeContrast)
    private var colorSchemeContrast

    let cornerRadius: CGFloat
    let isInteractive: Bool
    let tint: Color?

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *),
           !shouldReduceTransparency,
           colorSchemeContrast != .increased {
            content
                .glassEffect(
                    .regular
                        .tint(tint)
                        .interactive(isInteractive),
                    in: .rect(cornerRadius: cornerRadius)
                )
        } else {
            content
                .background(
                    Color.appElevatedSurface,
                    in: RoundedRectangle(
                        cornerRadius: cornerRadius,
                        style: .continuous
                    )
                )
                .overlay {
                    RoundedRectangle(
                        cornerRadius: cornerRadius,
                        style: .continuous
                    )
                    .stroke(Color.appBorder, lineWidth: 1)
                }
        }
    }
}

extension View {
    func adaptiveGlassSurface(
        cornerRadius: CGFloat = AppRadius.large,
        isInteractive: Bool = false,
        tint: Color? = nil
    ) -> some View {
        modifier(
            AdaptiveGlassSurfaceModifier(
                cornerRadius: cornerRadius,
                isInteractive: isInteractive,
                tint: tint
            )
        )
    }
}

struct AdaptiveGlassControlGroup<Content: View>: View {
    @Environment(\.accessibilityReduceTransparency)
    private var shouldReduceTransparency
    @Environment(\.colorSchemeContrast)
    private var colorSchemeContrast

    let spacing: CGFloat
    @ViewBuilder let content: () -> Content

    init(
        spacing: CGFloat = AppSpacing.small,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.spacing = spacing
        self.content = content
    }

    @ViewBuilder
    var body: some View {
        if #available(iOS 26.0, *),
           !shouldReduceTransparency,
           colorSchemeContrast != .increased {
            GlassEffectContainer(spacing: spacing) {
                content()
            }
        } else {
            content()
        }
    }
}
