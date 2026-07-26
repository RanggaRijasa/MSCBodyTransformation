import SwiftUI

private struct AdaptiveDemoSurfaceModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.adaptiveGlassSurface()
    }
}

extension View {
    func adaptiveDemoSurface() -> some View {
        modifier(AdaptiveDemoSurfaceModifier())
    }
}
