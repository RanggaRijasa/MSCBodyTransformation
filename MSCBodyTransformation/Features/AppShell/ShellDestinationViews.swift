import SwiftUI

@MainActor
struct ShellRouteDestinationView: View {
    let route: ShellRoute
    let router: ShellTabRouter

    var body: some View {
        switch route {
        case .participant(.localInvite(let code)):
            LocalInvitePlaceholderView(code: code)
        case .admin(.programEditor):
            LocalDraftEditorPlaceholderView()
        default:
            ContentUnavailableView {
                Label(
                    "shell.destination.title",
                    systemImage: "hammer.fill"
                )
            } description: {
                Text("shell.destination.message")
            }
            .navigationTitle(Text("shell.destination.navigation_title"))
        }
    }
}

private struct LocalInvitePlaceholderView: View {
    let code: String

    var body: some View {
        VStack(spacing: AppSpacing.large) {
            Image(systemName: "ticket.fill")
                .font(.largeTitle)
                .foregroundStyle(Color.brandPrimary)
                .accessibilityHidden(true)

            SectionHeader(
                title: "shell.invite.title",
                subtitle: "shell.invite.message"
            )

            Text(code)
                .font(AppTypography.metric)
                .foregroundStyle(Color.appPrimaryText)
                .padding(AppSpacing.medium)
                .adaptiveGlassSurface()
                .accessibilityLabel(Text("shell.invite.code"))
        }
        .frame(maxWidth: 520)
        .padding(AppSpacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .navigationTitle(Text("shell.invite.navigation_title"))
    }
}

private struct LocalDraftEditorPlaceholderView: View {
    @State private var title = "Program kebiasaan baru"
    @State private var summary = ""

    var body: some View {
        Form {
            Section("shell.draft.section.identity") {
                TextField("shell.draft.field.title", text: $title)
                TextField(
                    "shell.draft.field.summary",
                    text: $summary,
                    axis: .vertical
                )
                .lineLimit(3...6)
            }

            Section {
                StatusBadge(title: "status.draft", kind: .warning)
            }
        }
        .navigationTitle(Text("shell.draft.navigation_title"))
    }
}

@MainActor
struct ShellSheetView: View {
    let sheet: ShellSheet

    var body: some View {
        switch sheet {
        case .confirmation:
            ConfirmationSheet(
                title: "sheet.confirmation.demo.title",
                message: "sheet.confirmation.demo.message",
                confirmTitle: "action.confirm",
                isDestructive: false,
                confirmAction: {}
            )
        case .inviteCode(let code):
            InviteCodeSheet(code: code)
        case .scenarioInformation(let scenario):
            ScenarioInformationSheet(scenario: scenario)
        }
    }
}

private struct InviteCodeSheet: View {
    @Environment(\.dismiss) private var dismiss
    let code: String

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.large) {
                Image(systemName: "qrcode")
                    .font(.largeTitle)
                    .foregroundStyle(Color.brandPrimary)
                    .accessibilityHidden(true)

                Text("sheet.invite.title")
                    .font(AppTypography.sectionTitle)

                Text(code)
                    .font(AppTypography.metric)
                    .padding(AppSpacing.large)
                    .adaptiveGlassSurface()
                    .accessibilityLabel(Text("shell.invite.code"))

                Text("sheet.invite.demo_notice")
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(AppSpacing.large)
            .navigationTitle(Text("sheet.invite.navigation_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("action.close") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct ScenarioInformationSheet: View {
    @Environment(\.dismiss) private var dismiss
    let scenario: String

    var body: some View {
        NavigationStack {
            Form {
                LabeledContent("sheet.scenario.active") {
                    Text(
                        LocalizedStringKey(
                            "scenario.\(scenario)"
                        )
                    )
                }
                Text("sheet.scenario.debug_notice")
                    .foregroundStyle(Color.appSecondaryText)
            }
            .navigationTitle(Text("sheet.scenario.title"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("action.close") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
