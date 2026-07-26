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
                configuration.isPressed
                    ? Color.brandPrimaryPressed
                    : Color.brandPrimary,
                in: RoundedRectangle(
                    cornerRadius: AppRadius.medium,
                    style: .continuous
                )
            )
            .opacity(isEnabled ? 1 : 0.45)
    }
}
