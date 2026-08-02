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

struct SecondaryActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    var foregroundColor: Color = .brandPrimary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTypography.button)
            .frame(maxWidth: .infinity, minHeight: 50)
            .padding(.horizontal, AppSpacing.medium)
            .foregroundStyle(foregroundColor)
            .background(
                configuration.isPressed
                    ? foregroundColor.opacity(0.08)
                    : Color.appSurface,
                in: RoundedRectangle(
                    cornerRadius: AppRadius.medium,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: AppRadius.medium,
                    style: .continuous
                )
                .stroke(foregroundColor, lineWidth: 1)
            }
            .opacity(isEnabled ? 1 : 0.45)
    }
}
