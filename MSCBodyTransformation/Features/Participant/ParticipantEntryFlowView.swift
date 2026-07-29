import SwiftUI

@MainActor
struct ParticipantEntryFlowView: View {
    let store: ParticipantJourneyStore

    var body: some View {
        switch store.entryStage {
        case .login:
            LocalDemoLoginView(store: store)
        case .profile:
            ParticipantProfileCompletionView(store: store)
        case .disclaimer:
            ParticipantDisclaimerView(store: store)
        case .initialWeighIn:
            ParticipantWeighInView(
                store: store,
                type: .initial,
                presentation: .entry
            )
        case .complete:
            EmptyStateView(
                title: "participant.entry.complete.title",
                message: "participant.entry.complete.message",
                systemImage: "checkmark.circle"
            )
        }
    }
}

private struct LocalDemoLoginView: View {
    let store: ParticipantJourneyStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                Image(systemName: "figure.run.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Color.brandPrimary)
                    .accessibilityHidden(true)

                SectionHeader(
                    title: "participant.login.title",
                    subtitle: "participant.login.message"
                )

                LabeledContent(
                    "participant.login.account",
                    value: "peserta@demo.local"
                )
                .padding(AppSpacing.medium)
                .background(
                    Color.appSurface,
                    in: RoundedRectangle(
                        cornerRadius: AppRadius.large,
                        style: .continuous
                    )
                )

                Text("participant.local_only_notice")
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)

                Button {
                    Task {
                        await store.localLogin()
                    }
                } label: {
                    Label(
                        "participant.login.action",
                        systemImage: "arrow.right.circle.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .disabled(store.isPerformingAction)
                .accessibilityIdentifier("participant.login")
            }
            .frame(maxWidth: 560, alignment: .leading)
            .padding(AppSpacing.large)
            .frame(maxWidth: .infinity)
        }
        .background(Color.appBackground)
    }
}

private struct ParticipantProfileCompletionView: View {
    let store: ParticipantJourneyStore

    @State private var displayName = ""
    @State private var city = ""
    @State private var fieldError: String?
    @FocusState private var focusedField: Field?

    private enum Field {
        case displayName
        case city
    }

    var body: some View {
        Form {
            Section {
                TextField(
                    "participant.profile.field.name",
                    text: $displayName
                )
                .textContentType(.name)
                .focused($focusedField, equals: .displayName)
                .onSubmit { focusedField = .city }
                .accessibilityIdentifier("participant.profile.name")

                TextField(
                    "participant.profile.field.city",
                    text: $city
                )
                .textContentType(.addressCity)
                .focused($focusedField, equals: .city)
                .accessibilityIdentifier("participant.profile.city")

                if let fieldError {
                    Text(fieldError)
                        .font(AppTypography.secondary)
                        .foregroundStyle(Color.appDestructive)
                        .accessibilityIdentifier(
                            "participant.profile.validation"
                        )
                }
            } header: {
                Text("participant.profile.completion.title")
            } footer: {
                Text("participant.profile.completion.message")
            }

            Section {
                Button("action.continue") {
                    Task {
                        await save()
                    }
                }
                .disabled(store.isPerformingAction)
                .accessibilityIdentifier("participant.profile.continue")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .onAppear {
            displayName = store.snapshot?.profile.displayName ?? ""
            city = store.snapshot?.profile.city ?? ""
            focusedField = .displayName
        }
    }

    private func save() async {
        do {
            try await store.saveProfile(
                displayName: displayName,
                city: city
            )
            fieldError = nil
        } catch let error as DomainError {
            fieldError = ParticipantFormatting.fieldReason(error)
        } catch {
            fieldError = String(localized: "participant.error.generic")
        }
    }
}

private struct ParticipantDisclaimerView: View {
    let store: ParticipantJourneyStore
    @State private var hasAcknowledged = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                SectionHeader(
                    title: "participant.disclaimer.title",
                    subtitle: "participant.disclaimer.message"
                )

                Label {
                    Text(
                        store.wellnessDisclaimer?.body
                            ?? String(
                                localized: "participant.disclaimer.fallback"
                            )
                    )
                } icon: {
                    Image(systemName: "heart.text.square")
                        .foregroundStyle(Color.appInfo)
                }
                .padding(AppSpacing.medium)
                .background(
                    Color.appSurface,
                    in: RoundedRectangle(
                        cornerRadius: AppRadius.large,
                        style: .continuous
                    )
                )

                Toggle(
                    "participant.disclaimer.acknowledgement",
                    isOn: $hasAcknowledged
                )
                .accessibilityIdentifier(
                    "participant.disclaimer.acknowledgement"
                )

                Button("action.continue") {
                    store.acceptDisclaimer()
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .disabled(!hasAcknowledged)
                .accessibilityIdentifier(
                    "participant.disclaimer.continue"
                )
            }
            .frame(maxWidth: 560, alignment: .leading)
            .padding(AppSpacing.large)
            .frame(maxWidth: .infinity)
        }
        .background(Color.appBackground)
    }
}

#Preview("Entry — login") {
    ParticipantEntryFlowPreview(stage: .login)
}

#Preview("Entry — profil") {
    ParticipantEntryFlowPreview(stage: .profile)
}

@MainActor
private struct ParticipantEntryFlowPreview: View {
    let stage: ParticipantEntryStage
    @State private var store = ParticipantJourneyStore(
        environment: .preview,
        startsWithoutEnrollment: true
    )

    var body: some View {
        ParticipantEntryFlowView(store: store)
            .task {
                await store.load()
                store.entryStage = stage
            }
    }
}
