import SwiftUI

@MainActor
private struct SinglePressNavigationBackButtonModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .frame(
                                minWidth: AppControlMetrics.minimumTouchTarget,
                                minHeight: AppControlMetrics.minimumTouchTarget
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("action.back"))
                    .accessibilityIdentifier("navigation.back")
                }
            }
    }
}

extension View {
    @MainActor
    func singlePressNavigationBackButton() -> some View {
        modifier(SinglePressNavigationBackButtonModifier())
    }
}
