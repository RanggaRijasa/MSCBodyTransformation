import SwiftUI

@MainActor
struct ParticipantJoinProgramView: View {
    let store: ParticipantJourneyStore
    private let initialCode: String

    @Environment(\.dismiss) private var dismiss
    @State private var inviteCode: String
    @State private var preview: ProgramInvitePreview?
    @State private var fieldError: String?
    @State private var showsScanner = false
    @FocusState private var isCodeFocused: Bool

    init(
        store: ParticipantJourneyStore,
        initialCode: String = ""
    ) {
        self.store = store
        self.initialCode = initialCode
        _inviteCode = State(initialValue: initialCode)
    }

    var body: some View {
        Form {
            scannerSection
            manualCodeSection

            if let preview {
                previewSection(preview)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .navigationTitle(Text("participant.invite.title"))
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if preview != nil {
                VStack(spacing: 0) {
                    Divider()
                    confirmButton
                        .padding(.horizontal, AppSpacing.medium)
                        .padding(.vertical, AppSpacing.small)
                }
                .background(Color.appBackground)
            }
        }
        .sheet(isPresented: $showsScanner) {
            LocalQRScannerSheet { token in
                inviteCode = token
                fieldError = nil
                Task {
                    await loadPreview()
                }
            }
        }
        .onChange(of: inviteCode) {
            preview = nil
            fieldError = nil
        }
        .task(id: initialCode) {
            guard !initialCode.isEmpty else { return }
            await loadPreview()
        }
    }

    private var scannerSection: some View {
        Section {
            Button {
                isCodeFocused = false
                showsScanner = true
            } label: {
                Label(
                    "participant.invite.scan_action",
                    systemImage: "qrcode.viewfinder"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .accessibilityIdentifier("participant.join.scan")
        } footer: {
            Text("participant.invite.scan_message")
        }
    }

    private var manualCodeSection: some View {
        Section {
            TextField(
                "participant.invite.field",
                text: $inviteCode
            )
            .textInputAutocapitalization(.characters)
            .autocorrectionDisabled()
            .textContentType(.oneTimeCode)
            .submitLabel(.continue)
            .focused($isCodeFocused)
            .onSubmit {
                Task {
                    await loadPreview()
                }
            }
            .accessibilityIdentifier("participant.join.code")

            if let fieldError {
                Text(fieldError)
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appDestructive)
                    .accessibilityIdentifier(
                        "participant.join.validation"
                    )
            }

            Button {
                Task {
                    await loadPreview()
                }
            } label: {
                if store.isPerformingAction {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("participant.invite.preview_action")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.bordered)
            .disabled(
                inviteCode.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ).isEmpty || store.isPerformingAction
            )
            .accessibilityIdentifier("participant.join.preview")
        } header: {
            Text("participant.invite.manual_title")
        } footer: {
            Text("participant.invite.manual_message")
        }
    }

    private func previewSection(
        _ preview: ProgramInvitePreview
    ) -> some View {
        Section {
            ProgramCard(
                title: LocalizedStringKey(preview.program.title),
                summary: preview.program.summary,
                statusTitle: programStatusTitle(preview.program.status),
                statusKind: programStatusKind(preview.program.status),
                progress: nil
            )
            .accessibilityIdentifier("participant.join.preview.result")

            LabeledContent(
                "participant.invite.code_label",
                value: preview.invite.code
            )

            if let coach = store.coach(id: preview.invite.coachID) {
                LabeledContent(
                    "participant.program.assigned_coach",
                    value: coach.displayName
                )
            }

            LabeledContent(
                "participant.program.period",
                value: periodText(for: preview.program)
            )

        } header: {
            Text("participant.invite.preview.title")
        } footer: {
            Text("participant.invite.preview.message")
        }
    }

    private var confirmButton: some View {
        Button {
            Task {
                await joinProgram()
            }
        } label: {
            Text("participant.join.confirm_action")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryActionButtonStyle())
        .disabled(store.isPerformingAction)
        .accessibilityIdentifier("participant.join.confirm")
    }

    private func loadPreview() async {
        isCodeFocused = false
        do {
            preview = try await store.loadInvitePreview(code: inviteCode)
            fieldError = nil
        } catch let error as DomainError {
            preview = nil
            fieldError = ParticipantFormatting.fieldReason(error)
        } catch {
            preview = nil
            fieldError = String(localized: "participant.error.generic")
        }
    }

    private func joinProgram() async {
        do {
            try await store.joinPendingInvite()
            fieldError = nil
            dismiss()
        } catch let error as DomainError {
            fieldError = ParticipantFormatting.fieldReason(error)
        } catch {
            fieldError = String(localized: "participant.error.generic")
        }
    }

    private func periodText(for program: Program) -> String {
        let startDate =
            program.days.map(\.scheduledDate).min() ?? program.startDate
        let endDate: Date
        if let lastScheduledDate = program.days.map(\.scheduledDate).max() {
            endDate = lastScheduledDate
        } else {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone =
                TimeZone(identifier: program.timeZoneIdentifier) ?? .gmt
            endDate = calendar.date(
                byAdding: .day,
                value: max(program.durationInDays - 1, 0),
                to: startDate
            ) ?? program.endDate
        }
        let start = ParticipantFormatting.date(
            startDate,
            timeZoneIdentifier: program.timeZoneIdentifier
        )
        let end = ParticipantFormatting.date(
            endDate,
            timeZoneIdentifier: program.timeZoneIdentifier
        )
        return "\(start) – \(end)"
    }

    private func programStatusTitle(
        _ status: ProgramStatus
    ) -> LocalizedStringKey {
        switch status {
        case .draft:
            "status.draft"
        case .scheduled:
            "participant.home.program.status.scheduled"
        case .active:
            "status.active"
        case .completed:
            "participant.home.program.status.completed"
        case .archived:
            "status.archived"
        }
    }

    private func programStatusKind(_ status: ProgramStatus) -> AppStatusKind {
        switch status {
        case .active:
            .success
        case .scheduled:
            .information
        case .completed, .archived:
            .neutral
        case .draft:
            .warning
        }
    }
}
