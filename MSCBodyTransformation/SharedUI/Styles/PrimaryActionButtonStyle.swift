import SwiftUI

struct PrimaryActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 50)
            .padding(.horizontal, AppSpacing.medium)
            .foregroundStyle(.white)
            .background(
                Color.brandPrimary.opacity(configuration.isPressed ? 0.82 : 1),
                in: RoundedRectangle(
                    cornerRadius: AppRadius.medium,
                    style: .continuous
                )
            )
            .opacity(isEnabled ? 1 : 0.45)
    }
}
