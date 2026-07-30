import SwiftUI

@MainActor
struct ParticipantEntryFlowView: View {
    let store: ParticipantJourneyStore

    var body: some View {
        VStack(spacing: 0) {
            if store.entryStage != .complete {
                ParticipantEntryProgressView(stage: store.entryStage)
            }
            stageContent
        }
        .background(Color.appBackground)
        .navigationTitle(
            Text(
                LocalizedStringKey(
                    ParticipantEntryStagePresentation(
                        stage: store.entryStage
                    ).titleKey
                )
            )
        )
    }

    @ViewBuilder
    private var stageContent: some View {
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

private struct ParticipantEntryProgressView: View {
    let stage: ParticipantEntryStage

    private var presentation: ParticipantEntryStagePresentation {
        ParticipantEntryStagePresentation(stage: stage)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            HStack(alignment: .firstTextBaseline) {
                Text(LocalizedStringKey(presentation.titleKey))
                    .font(AppTypography.cardTitle)

                Spacer(minLength: AppSpacing.small)

                progressText
                    .font(AppTypography.label.monospacedDigit())
                    .foregroundStyle(Color.appSecondaryText)
            }

            ProgressView(
                value: Double(presentation.currentStep),
                total: Double(presentation.totalSteps)
            )
            .tint(Color.brandPrimary)
        }
        .padding(.horizontal, AppSpacing.large)
        .padding(.vertical, AppSpacing.small)
        .background(Color.appBackground)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            Text(LocalizedStringKey(presentation.titleKey))
        )
        .accessibilityValue(progressText)
        .accessibilityIdentifier("participant.entry.progress")
    }

    private var progressText: Text {
        Text(
            "\(Text("participant.entry.progress.step")) \(presentation.currentStep, format: .number) \(Text("participant.entry.progress.of")) \(presentation.totalSteps, format: .number)"
        )
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
                VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                    Text("participant.profile.field.name")
                        .font(AppTypography.label)
                        .foregroundStyle(Color.appSecondaryText)
                    TextField(
                        "participant.profile.field.name",
                        text: $displayName
                    )
                    .textContentType(.name)
                    .focused($focusedField, equals: .displayName)
                    .onSubmit { focusedField = .city }
                    .accessibilityIdentifier("participant.profile.name")
                }

                VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                    Text("participant.profile.field.city")
                        .font(AppTypography.label)
                        .foregroundStyle(Color.appSecondaryText)
                    TextField(
                        "participant.profile.field.city",
                        text: $city
                    )
                    .textContentType(.addressCity)
                    .focused($focusedField, equals: .city)
                    .accessibilityIdentifier("participant.profile.city")
                }

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
