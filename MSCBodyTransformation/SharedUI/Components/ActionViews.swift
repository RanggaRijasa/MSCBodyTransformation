import SwiftUI

struct PrimaryActionBar: View {
    @Environment(\.accessibilityReduceTransparency)
    private var shouldReduceTransparency
    @Environment(\.colorSchemeContrast)
    private var colorSchemeContrast

    let title: LocalizedStringKey
    let systemImage: String
    let action: () -> Void

    var body: some View {
        VStack {
            if #available(iOS 26.0, *),
               !shouldReduceTransparency,
               colorSchemeContrast != .increased {
                Button(action: action) {
                    Label(title, systemImage: systemImage)
                        .font(AppTypography.button)
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.glassProminent)
                .tint(.brandPrimary)
            } else {
                Button(action: action) {
                    Label(title, systemImage: systemImage)
                }
                .buttonStyle(PrimaryActionButtonStyle())
            }
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.vertical, AppSpacing.small)
        .background(.bar)
    }
}

struct ConfirmationSheet: View {
    @Environment(\.dismiss) private var dismiss

    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let confirmTitle: LocalizedStringKey
    let isDestructive: Bool
    let confirmAction: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                Label(
                    title,
                    systemImage: isDestructive
                        ? "exclamationmark.triangle"
                        : "checkmark.circle"
                )
                .font(AppTypography.sectionTitle)
                .foregroundStyle(
                    isDestructive
                        ? Color.appDestructive
                        : Color.appPrimaryText
                )

                Text(message)
                    .font(AppTypography.body)
                    .foregroundStyle(Color.appSecondaryText)

                Spacer()

                Button(role: isDestructive ? .destructive : nil) {
                    confirmAction()
                    dismiss()
                } label: {
                    Text(confirmTitle)
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
                .tint(isDestructive ? .appDestructive : .brandPrimary)
            }
            .padding(AppSpacing.large)
            .navigationTitle(Text("sheet.confirmation.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview("Primary action") {
    PrimaryActionBar(
        title: "action.continue",
        systemImage: "arrow.right",
        action: {}
    )
}

#Preview("Confirmation") {
    ConfirmationSheet(
        title: "preview.confirmation.title",
        message: "preview.confirmation.message",
        confirmTitle: "action.continue",
        isDestructive: false,
        confirmAction: {}
    )
}
