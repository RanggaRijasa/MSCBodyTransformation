import SwiftUI

@MainActor
struct ShellRouteDestinationView: View {
    let route: ShellRoute
    let router: ShellTabRouter
    let participantStore: ParticipantJourneyStore?
    let coachFeatures: CoachFeatureContainer?

    var body: some View {
        switch route {
        case .participant(.localInvite(let code)):
            LocalInvitePlaceholderView(code: code)
        case .participant(.programDetail):
            participantDestination {
                ParticipantProgramView(
                    store: $0,
                    router: router
                )
            }
        case .participant(.stepDetail(let stepID)):
            participantDestination {
                ParticipantStepDetailView(
                    store: $0,
                    stepID: stepID
                )
            }
        case .participant(.weighIn(let type)):
            participantDestination {
                ParticipantWeighInView(
                    store: $0,
                    type: type,
                    presentation: .pushed
                )
            }
        case .participant(.leaderboard):
            participantDestination {
                ParticipantLeaderboardView(store: $0)
            }
        case .participant(.coach(let coachID)):
            participantDestination {
                ParticipantCoachDetailView(
                    store: $0,
                    coachID: coachID
                )
            }
        case .participant(.profile):
            participantDestination {
                ParticipantProfileView(
                    store: $0,
                    router: router
                )
            }
        case .coach(.participantDetail(let participantID)):
            coachDestination {
                CoachParticipantDetailDestinationView(
                    participantID: participantID,
                    features: $0
                )
            }
        case .coach(.reviewQueue):
            coachDestination {
                CoachReviewQueueView(features: $0)
            }
        case .coach(.invite):
            coachDestination {
                CoachInviteView(
                    state: $0.invites,
                    router: router
                )
            }
        case .coach(.storePreview):
            coachDestination {
                CoachStorePreviewView(state: $0.storePreview)
            }
        case .coach(.leaderboard):
            coachDestination {
                CoachLeaderboardView(state: $0.leaderboard)
            }
        case .coach(.profile):
            coachDestination {
                CoachProfileView(
                    state: $0.profile,
                    router: router
                )
            }
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

    @ViewBuilder
    private func participantDestination<Content: View>(
        @ViewBuilder content: (ParticipantJourneyStore) -> Content
    ) -> some View {
        if let participantStore {
            content(participantStore)
        } else {
            LoadingStateView()
                .padding(AppSpacing.medium)
        }
    }

    @ViewBuilder
    private func coachDestination<Content: View>(
        @ViewBuilder content: (CoachFeatureContainer) -> Content
    ) -> some View {
        if let coachFeatures {
            content(coachFeatures)
        } else {
            LoadingStateView()
                .padding(AppSpacing.medium)
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
