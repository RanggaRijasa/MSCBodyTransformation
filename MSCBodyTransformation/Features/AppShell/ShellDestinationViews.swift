import SwiftUI

@MainActor
struct ShellRouteDestinationView: View {
    let route: ShellRoute
    let router: ShellTabRouter
    let participantStore: ParticipantJourneyStore?
    let coachFeatures: CoachFeatureContainer?
    let adminFeatures: AdminFeatureContainer?

    var body: some View {
        switch route {
        case .participant(.joinProgram(let programID)):
            participantDestination {
                ParticipantJoinProgramView(
                    store: $0,
                    programID: programID
                )
            }
        case .participant(.programDetail(let programID, let sourceTab)):
            participantDestination {
                ParticipantProgramView(
                    store: $0,
                    router: router,
                    programID: programID,
                    navigationTab: sourceTab
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
        case .admin(.programEditor(let programID)):
            adminDestination { features in
                if let programID {
                    AdminProgramEditorView(
                        programID: programID,
                        features: features
                    )
                } else {
                    AdminNewProgramDestinationView(features: features)
                }
            }
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

    @ViewBuilder
    private func adminDestination<Content: View>(
        @ViewBuilder content: (AdminFeatureContainer) -> Content
    ) -> some View {
        if let adminFeatures {
            content(adminFeatures)
        } else {
            LoadingStateView()
                .padding(AppSpacing.medium)
        }
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
        case .scenarioInformation(let scenario):
            ScenarioInformationSheet(scenario: scenario)
        }
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
