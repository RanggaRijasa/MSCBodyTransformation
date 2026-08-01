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

struct FilterSummaryButton: View {
    let title: LocalizedStringKey
    let summary: Text
    let identifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.medium) {
                Image(systemName: "slider.horizontal.3")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(Color.appPrimaryText)
                    .frame(
                        width: AppControlMetrics.minimumTouchTarget,
                        height: AppControlMetrics.minimumTouchTarget
                    )
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                    Text(title)
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(Color.appPrimaryText)

                    summary
                        .font(AppTypography.secondary)
                        .foregroundStyle(Color.appSecondaryText)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: AppSpacing.xSmall)

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appSecondaryText)
                    .accessibilityHidden(true)
            }
            .padding(AppSpacing.medium)
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
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
            .contentShape(
                RoundedRectangle(
                    cornerRadius: AppRadius.large,
                    style: .continuous
                )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
        .accessibilityValue(summary)
        .accessibilityIdentifier(identifier)
    }
}

struct FilterSheetActionBar: View {
    let resetTitle: LocalizedStringKey
    let applyTitle: LocalizedStringKey
    let resetIdentifier: String
    let applyIdentifier: String
    let onReset: () -> Void
    let onApply: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Button(resetTitle, action: onReset)
                .buttonStyle(SecondaryActionButtonStyle())
                .accessibilityIdentifier(resetIdentifier)

            Button(applyTitle, action: onApply)
                .buttonStyle(PrimaryActionButtonStyle())
                .accessibilityIdentifier(applyIdentifier)
        }
        .padding(AppSpacing.medium)
        .background(.bar)
        .overlay(alignment: .top) {
            Divider()
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("app.filter.action-bar")
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
