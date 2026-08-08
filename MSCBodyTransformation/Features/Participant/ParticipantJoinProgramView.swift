import SwiftUI

@MainActor
struct ParticipantJoinProgramView: View {
    let store: ParticipantJourneyStore
    let programID: UUID?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedCoach: CoachProfile?
    @State private var stage = JoinProgramStage.scanCoach
    @State private var fieldError: String?
    @State private var showsScanner = false

    init(
        store: ParticipantJourneyStore,
        programID: UUID?
    ) {
        self.store = store
        self.programID = programID
    }

    var body: some View {
        Group {
            if let program {
                content(program)
            } else {
                ContentUnavailableView {
                    Label(
                        "participant.join.program_required.title",
                        systemImage: "rectangle.stack.badge.plus"
                    )
                } description: {
                    Text("participant.join.program_required.message")
                } actions: {
                    Button("action.close") {
                        dismiss()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .navigationTitle(Text("participant.join.flow.title"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showsScanner) {
            LocalQRScannerSheet { identifier in
                Task { await loadCoachPreview(identifier: identifier) }
            }
        }
        .accessibilityIdentifier("participant.join.flow")
    }

    @ViewBuilder
    private func content(_ program: Program) -> some View {
        if stage != .completed,
           store.registrationAvailability(for: program) == .closed {
            ContentUnavailableView {
                Label(
                    "participant.program.registration.closed",
                    systemImage: "clock.badge.xmark"
                )
            } description: {
                Text(
                    "participant.join.registration_closed.message"
                )
            } actions: {
                Button("action.close") {
                    dismiss()
                }
            }
        } else {
            switch stage {
            case .scanCoach:
                scannerStep(program)
            case .confirmCoach:
                coachConfirmationStep(program)
            case .payment:
                paymentStep(program)
            case .completed:
                completionStep(program)
            }
        }
    }

    private func scannerStep(_ program: Program) -> some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text(program.title)
                        .font(AppTypography.cardTitle)
                    Text(
                        ParticipantFormatting.currency(program.price ?? 0)
                    )
                    .font(AppTypography.metric.monospacedDigit())
                }
            } header: {
                Text("participant.join.selected_program")
            }

            Section {
                Button {
                    showsScanner = true
                } label: {
                    Label(
                        "participant.join.scan_coach",
                        systemImage: "qrcode.viewfinder"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .accessibilityIdentifier("participant.join.scan")
            } header: {
                Text("participant.join.scan_step.title")
            } footer: {
                Text("participant.join.scan_step.message")
            }

            if let fieldError {
                Section {
                    Label(
                        fieldError,
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appDestructive)
                    .accessibilityIdentifier(
                        "participant.join.validation"
                    )
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    private func coachConfirmationStep(_ program: Program) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                SectionHeader(
                    title: "participant.join.confirm_coach.title",
                    subtitle: "participant.join.confirm_coach.message"
                )

                if let selectedCoach {
                    HStack(spacing: AppSpacing.medium) {
                        UserAvatar(
                            displayName: selectedCoach.displayName,
                            size: 64
                        )
                        VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                            Text(selectedCoach.displayName)
                                .font(AppTypography.sectionTitle)
                            Text(selectedCoach.city)
                                .font(AppTypography.secondary)
                                .foregroundStyle(Color.appSecondaryText)
                            Label(
                                "participant.join.coach.verified",
                                systemImage: "checkmark.seal.fill"
                            )
                            .font(AppTypography.label)
                            .foregroundStyle(Color.appSuccess)
                        }
                    }
                    .padding(AppSpacing.medium)
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
                }

                LabeledContent(
                    "participant.join.program_label",
                    value: program.title
                )
                LabeledContent(
                    "participant.program.offer.price",
                    value: ParticipantFormatting.currency(program.price ?? 0)
                )

                Button {
                    stage = .payment
                } label: {
                    Text("participant.join.confirm_coach.action")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .disabled(selectedCoach == nil)
                .accessibilityIdentifier("participant.join.confirm-coach")

                Button("participant.join.scan_again") {
                    selectedCoach = nil
                    fieldError = nil
                    stage = .scanCoach
                }
                .frame(maxWidth: .infinity, minHeight: 44)
            }
            .frame(maxWidth: 560, alignment: .leading)
            .padding(AppSpacing.large)
            .frame(maxWidth: .infinity)
        }
    }

    private func paymentStep(_ program: Program) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                Image(systemName: "apple.logo")
                    .font(.largeTitle)
                    .foregroundStyle(Color.appPrimaryText)
                    .accessibilityHidden(true)

                SectionHeader(
                    title: "participant.payment.title",
                    subtitle: "participant.payment.message"
                )

                VStack(spacing: AppSpacing.medium) {
                    LabeledContent(
                        "participant.join.program_label",
                        value: program.title
                    )
                    if let selectedCoach {
                        LabeledContent(
                            "participant.join.coach_label",
                            value: selectedCoach.displayName
                        )
                    }
                    Divider()
                    LabeledContent(
                        "participant.payment.total",
                        value: ParticipantFormatting.currency(
                            program.price ?? 0
                        )
                    )
                    .font(AppTypography.cardTitle.monospacedDigit())
                }
                .padding(AppSpacing.medium)
                .background(
                    Color.appSurface,
                    in: RoundedRectangle(
                        cornerRadius: AppRadius.large,
                        style: .continuous
                    )
                )

                Label(
                    "participant.payment.placeholder_notice",
                    systemImage: "info.circle.fill"
                )
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appInfo)

                if let fieldError {
                    Text(fieldError)
                        .font(AppTypography.secondary)
                        .foregroundStyle(Color.appDestructive)
                }

                Button {
                    Task {
                        await completeLocalPaymentPlaceholder()
                    }
                } label: {
                    if store.isPerformingAction {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("participant.payment.demo_action")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .disabled(
                    selectedCoach == nil || store.isPerformingAction
                )
                .accessibilityIdentifier("participant.payment.demo")
            }
            .frame(maxWidth: 560, alignment: .leading)
            .padding(AppSpacing.large)
            .frame(maxWidth: .infinity)
        }
    }

    private func completionStep(_ program: Program) -> some View {
        ScrollView {
            VStack(spacing: AppSpacing.large) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Color.appSuccess)
                    .accessibilityHidden(true)
                SectionHeader(
                    title: "participant.join.completed.title",
                    subtitle: "participant.join.completed.message"
                )
                Text(program.title)
                    .font(AppTypography.sectionTitle)
                    .multilineTextAlignment(.center)
                Button("participant.join.completed.action") {
                    dismiss()
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .accessibilityIdentifier("participant.join.completed")
            }
            .frame(maxWidth: 560)
            .padding(AppSpacing.large)
            .frame(maxWidth: .infinity)
        }
    }

    private var program: Program? {
        guard let programID else { return nil }
        return store.snapshot?.programs.first { $0.id == programID }
    }

    private func loadCoachPreview(identifier: String) async {
        do {
            selectedCoach = try await store.coach(
                matchingEnrollmentIdentifier: identifier
            )
            fieldError = nil
            stage = .confirmCoach
        } catch let error as DomainError {
            selectedCoach = nil
            fieldError = ParticipantFormatting.fieldReason(error)
        } catch {
            selectedCoach = nil
            fieldError = String(
                localized: "participant.error.generic",
                defaultValue: "Terjadi kendala. Coba lagi."
            )
        }
    }

    private func completeLocalPaymentPlaceholder() async {
        guard let programID, let selectedCoach else { return }
        do {
            try await store.joinProgram(
                programID: programID,
                with: selectedCoach
            )
            fieldError = nil
            stage = .completed
        } catch let error as DomainError {
            fieldError = ParticipantFormatting.fieldReason(error)
        } catch {
            fieldError = String(
                localized: "participant.error.generic",
                defaultValue: "Terjadi kendala. Coba lagi."
            )
        }
    }
}

private enum JoinProgramStage: Sendable {
    case scanCoach
    case confirmCoach
    case payment
    case completed
}
