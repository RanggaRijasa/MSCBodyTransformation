import SwiftUI

@MainActor
struct AdminPersonDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    let person: AdminPersonSummary
    let features: AdminFeatureContainer

    @State private var selectedProgramID: UUID?
    @State private var selectedCoachID: UUID?
    @State private var enrollmentReason = ""
    @State private var coachTransferReason = ""
    @State private var rejectionReason = ""
    @State private var error: DomainError?
    @State private var isSaving = false
    @State private var showsApprovalConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                identitySection
                profileDataSection

                if let application = person.coachApplication {
                    coachApplicationSection(application)
                    coachApplicationActions(application)
                }

                if let participant = person.participantProfile {
                    participantCoachSection(participant)
                    coachTransferSection(participant)
                    manualEnrollmentSection(participant)
                }

                if let coach = person.coachProfile {
                    coachStatusSection(coach)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .id(person.id)
            .navigationTitle(Text(navigationTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Tutup") { dismiss() }
                }
            }
            .alert(
                "Data belum lengkap",
                isPresented: Binding(
                    get: { error != nil },
                    set: { if !$0 { error = nil } }
                )
            ) {
                Button("Tutup", role: .cancel) {}
            } message: {
                Text(error?.localizedAdminMessage ?? "")
            }
            .confirmationDialog(
                "admin.coach_application.approve.confirm.title",
                isPresented: $showsApprovalConfirmation,
                titleVisibility: .visible
            ) {
                Button("admin.coach_application.approve.action") {
                    Task { await approveCoachApplication() }
                }
                .accessibilityIdentifier(
                    "admin.coach-application.confirm-approve"
                )
                Button("action.cancel", role: .cancel) {}
            } message: {
                Text("admin.coach_application.approve.confirm.message")
            }
            .task {
                if selectedProgramID == nil {
                    selectedProgramID = availablePrograms.first?.id
                }
                if selectedCoachID == nil {
                    selectedCoachID = person.participantProfile?.coachID
                        ?? availableCoaches.first?.id
                }
            }
        }
    }

    private func coachApplicationSection(
        _ application: CoachApplication
    ) -> some View {
        Section {
            LabeledContent(
                "auth.profile.field.member_level",
                value: application.memberLevel.displayName
            )
            LabeledContent("coach.eligibility.requirement.level") {
                requirementStatus(
                    application.eligibility.isLevelEligible
                )
            }
            LabeledContent("coach.eligibility.requirement.hom_sts") {
                requirementStatus(application.hasCompletedHOMSTS)
            }
            LabeledContent("coach.eligibility.requirement.ict") {
                requirementStatus(application.hasCompletedICT)
            }
            if let payment = application.payment {
                LabeledContent(
                    "coach.payment.price",
                    value: Decimal(
                        payment.amountMinorUnits
                    ).formatted(
                        .currency(code: "IDR")
                            .precision(.fractionLength(0))
                            .locale(ParticipantFormatting.locale)
                    )
                )
                LabeledContent("coach.pending.payment") {
                    requirementStatus(payment.state == .verified)
                }
                if let start = payment.accessStartsAt,
                   let end = payment.accessEndsAt {
                    LabeledContent("coach.payment.access_period") {
                        VStack(alignment: .trailing) {
                            Text(
                                start,
                                format: .dateTime
                                    .day()
                                    .month(.wide)
                                    .year()
                                    .locale(ParticipantFormatting.locale)
                            )
                            Text(
                                end,
                                format: .dateTime
                                    .day()
                                    .month(.wide)
                                    .year()
                                    .locale(ParticipantFormatting.locale)
                            )
                            .foregroundStyle(Color.appSecondaryText)
                        }
                    }
                }
            }
            if let submittedAt = application.submittedAt {
                LabeledContent("coach.application.submitted_at") {
                    Text(
                        submittedAt,
                        format: .dateTime
                            .day()
                            .month(.wide)
                            .year()
                            .locale(ParticipantFormatting.locale)
                    )
                }
            }
            LabeledContent("coach.application.status.title") {
                StatusBadge(
                    title: applicationStatusTitle(application.status),
                    kind: applicationStatusKind(application.status)
                )
            }
        } header: {
            Text("admin.coach_application.section")
        } footer: {
            Text("admin.coach_application.read_only_notice")
        }
        .accessibilityIdentifier("admin.coach-application.detail")
    }

    @ViewBuilder
    private func coachApplicationActions(
        _ application: CoachApplication
    ) -> some View {
        if application.status == .submitted
            || application.status == .pendingAdminApproval {
            Section {
                Button("admin.coach_application.approve.action") {
                    showsApprovalConfirmation = true
                }
                .disabled(!application.isReadyForAdminApproval || isSaving)
                .accessibilityIdentifier(
                    "admin.coach-application.approve"
                )

                TextField(
                    "admin.coach_application.reject.reason",
                    text: $rejectionReason,
                    axis: .vertical
                )
                .accessibilityIdentifier(
                    "admin.coach-application.reject-reason"
                )

                Button(
                    "admin.coach_application.reject.action",
                    role: .destructive
                ) {
                    Task { await rejectCoachApplication() }
                }
                .disabled(
                    rejectionReason.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty || isSaving
                )
                .accessibilityIdentifier(
                    "admin.coach-application.reject"
                )
            } header: {
                Text("admin.coach_application.decision.section")
            } footer: {
                if !application.isReadyForAdminApproval {
                    Text("admin.coach_application.approval_blocked")
                } else {
                    Text("admin.coach_application.decision.audit_notice")
                }
            }
        }
    }

    private func requirementStatus(_ isSatisfied: Bool) -> some View {
        Label(
            isSatisfied
                ? "coach.eligibility.satisfied"
                : "coach.eligibility.not_satisfied",
            systemImage:
                isSatisfied
                ? "checkmark.circle.fill"
                : "xmark.circle.fill"
        )
        .foregroundStyle(
            isSatisfied ? Color.appSuccess : Color.appDestructive
        )
    }

    private func coachTransferSection(
        _ participant: ParticipantProfile
    ) -> some View {
        Section {
            Picker("Coach baru", selection: $selectedCoachID) {
                ForEach(availableCoaches) { coach in
                    Text(coach.displayName)
                        .tag(Optional(coach.id))
                }
            }
            TextField(
                "Alasan perubahan Coach",
                text: $coachTransferReason,
                axis: .vertical
            )
            Button(isSaving ? "Menyimpan…" : "Ubah Coach") {
                Task { await transferCoach(for: participant) }
            }
            .disabled(
                isSaving
                    || selectedCoachID == nil
                    || selectedCoachID == participant.coachID
            )
        } header: {
            Text("Perubahan Coach")
        } footer: {
            Text(
                "Enrollment aktif dan terjadwal ikut dipindahkan. Enrollment "
                    + "selesai tetap menyimpan Coach lamanya untuk audit."
            )
        }
    }

    private var identitySection: some View {
        Section {
            VStack(spacing: AppSpacing.medium) {
                UserAvatar(
                    displayName: profileDisplayName,
                    imageName: profileImageName,
                    size: 96
                )
                .accessibilityIdentifier("admin.people.detail.photo")

                VStack(spacing: AppSpacing.xxSmall) {
                    Text(profileDisplayName)
                        .font(AppTypography.sectionTitle)
                        .multilineTextAlignment(.center)

                    Text(person.user.email)
                        .font(AppTypography.secondary)
                        .foregroundStyle(Color.appSecondaryText)

                    if let profileCity {
                        Text(profileCity)
                            .font(AppTypography.secondary)
                            .foregroundStyle(Color.appSecondaryText)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.small)
        } header: {
            Text(identitySectionTitle)
        }
    }

    @ViewBuilder
    private var profileDataSection: some View {
        Section("participant.profile.data") {
            LabeledContent(
                "participant.profile.field.name",
                value: profileDisplayName
            )
            .accessibilityIdentifier("admin.people.detail.name")

            switch person.user.role {
            case .participant:
                if let participant = person.participantProfile {
                    LabeledContent(
                        "participant.profile.field.phone",
                        value: participant.phoneNumber
                            ?? String(
                                localized:
                                    "participant.profile.phone.empty",
                                defaultValue: "Belum ditambahkan"
                            )
                    )
                    .accessibilityIdentifier("admin.people.detail.phone")

                    LabeledContent(
                        "participant.profile.field.email",
                        value: person.user.email
                    )
                    .accessibilityIdentifier("admin.people.detail.email")
                }

            case .coach:
                if let coach = person.coachProfile {
                    LabeledContent(
                        "participant.profile.field.email",
                        value: person.user.email
                    )
                    .accessibilityIdentifier("admin.people.detail.email")

                    LabeledContent(
                        "participant.profile.field.city",
                        value: coach.city
                    )
                    .accessibilityIdentifier("admin.people.detail.city")

                    VStack(
                        alignment: .leading,
                        spacing: AppSpacing.xSmall
                    ) {
                        Text("coach.profile.biography")
                            .font(AppTypography.label)
                            .foregroundStyle(Color.appSecondaryText)
                        Text(coach.biography)
                            .font(AppTypography.body)
                            .foregroundStyle(Color.appPrimaryText)
                    }
                    .padding(.vertical, AppSpacing.xSmall)
                    .accessibilityIdentifier(
                        "admin.people.detail.biography"
                    )
                }

            case .admin:
                LabeledContent(
                    "participant.profile.field.email",
                    value: person.user.email
                )
                .accessibilityIdentifier("admin.people.detail.email")
            }
        }
    }

    private func participantCoachSection(
        _ participant: ParticipantProfile
    ) -> some View {
        Section {
            if let coach = assignedCoach(for: participant) {
                HStack(spacing: AppSpacing.medium) {
                    UserAvatar(
                        displayName: coach.displayName,
                        imageName: coach.localPhotoReference,
                        size: 56
                    )

                    VStack(
                        alignment: .leading,
                        spacing: AppSpacing.xxSmall
                    ) {
                        Text(coach.displayName)
                            .font(AppTypography.cardTitle)
                        Text(coach.city)
                            .font(AppTypography.secondary)
                            .foregroundStyle(Color.appSecondaryText)
                    }

                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier(
                    "admin.people.detail.participant-coach"
                )
            } else {
                Label(
                    "participant.profile.coach.empty",
                    systemImage: "person.crop.circle.badge.questionmark"
                )
                .foregroundStyle(Color.appSecondaryText)
            }
        } header: {
            Text("participant.profile.coach.section")
        }
    }

    private func coachStatusSection(
        _ coach: CoachProfile
    ) -> some View {
        Section("coach.profile.coach_settings") {
            LabeledContent("coach.profile.approval.status") {
                StatusBadge(
                    title: coach.isApproved
                        ? "status.approved"
                        : "status.awaiting_approval",
                    kind: coach.isApproved ? .success : .pending
                )
            }

            LabeledContent("coach.profile.visibility.title") {
                StatusBadge(
                    title: coach.isPublic
                        ? "coach.profile.visibility.public"
                        : "coach.profile.visibility.private",
                    kind: coach.isPublic ? .success : .neutral
                )
            }
        }
        .accessibilityIdentifier("admin.people.detail.coach-status")
    }

    private func manualEnrollmentSection(
        _ participant: ParticipantProfile
    ) -> some View {
        Section {
            Picker(
                "Program",
                selection: $selectedProgramID
            ) {
                ForEach(availablePrograms) { program in
                    Text(program.title)
                        .tag(Optional(program.id))
                }
            }

            if let selectedProgram {
                if let deadline = selectedProgram.registrationClosesAt {
                    LabeledContent(
                        "admin.people.manual_enrollment.deadline",
                        value: ParticipantFormatting.dateAndTime(
                            deadline,
                            timeZoneIdentifier:
                                selectedProgram.timeZoneIdentifier
                        )
                    )
                } else {
                    LabeledContent(
                        "admin.people.manual_enrollment.deadline",
                        value: String(
                            localized:
                                "admin.people.manual_enrollment.no_deadline",
                            defaultValue: "Tidak dibatasi"
                        )
                    )
                }
            }

            TextField(
                "Alasan enrollment",
                text: $enrollmentReason,
                axis: .vertical
            )
            .accessibilityIdentifier("admin.people.enroll-reason")

            Button(isSaving ? "Menyimpan…" : "Daftarkan peserta") {
                Task { await enroll(participant: participant) }
            }
            .disabled(isSaving || availablePrograms.isEmpty)
            .accessibilityIdentifier("admin.people.enroll")
        } header: {
            Text("Pendaftaran manual")
        } footer: {
            Text(
                "admin.people.manual_enrollment.deadline_help"
            )
        }
    }

    private var navigationTitle: LocalizedStringKey {
        switch person.user.role {
        case .participant:
            "Profil peserta"
        case .coach:
            "Profil Coach"
        case .admin:
            "Profil Admin"
        }
    }

    private var identitySectionTitle: LocalizedStringKey {
        switch person.user.role {
        case .participant:
            "participant.profile.identity"
        case .coach:
            "coach.profile.identity.title"
        case .admin:
            "Informasi Admin"
        }
    }

    private var profileDisplayName: String {
        person.participantProfile?.displayName
            ?? person.coachProfile?.displayName
            ?? person.user.displayName
    }

    private var profileImageName: String? {
        person.participantProfile?.localPhotoReference
            ?? person.coachProfile?.localPhotoReference
    }

    private var profileCity: String? {
        person.participantProfile?.city
            ?? person.coachProfile?.city
    }

    private var availablePrograms: [AdminProgramDraft] {
        guard case .loaded(let programs) = features.programsState else {
            return []
        }
        return programs.filter {
            $0.status == .scheduled || $0.status == .active
        }
    }

    private var selectedProgram: AdminProgramDraft? {
        guard let selectedProgramID else {
            return nil
        }
        return availablePrograms.first { $0.id == selectedProgramID }
    }

    private var availableCoaches: [CoachProfile] {
        guard case .loaded(let people) = features.peopleState else {
            return []
        }
        return people.compactMap(\.coachProfile)
            .filter(\.isApproved)
            .sorted {
                $0.displayName.localizedStandardCompare($1.displayName)
                    == .orderedAscending
            }
    }

    private func assignedCoach(
        for participant: ParticipantProfile
    ) -> CoachProfile? {
        guard
            let coachID = participant.coachID,
            case .loaded(let people) = features.peopleState
        else {
            return nil
        }

        return people.compactMap(\.coachProfile).first {
            $0.id == coachID
        }
    }

    private func enroll(participant: ParticipantProfile) async {
        guard let programID = selectedProgramID else {
            error = .validation(
                field: "program",
                reason: "Pilih program terlebih dahulu."
            )
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            try await features.manualEnroll(
                participant: participant,
                programID: programID,
                reason: enrollmentReason
            )
            dismiss()
        } catch let domainError as DomainError {
            error = domainError
        } catch {
            self.error = .unknown
        }
    }

    private func transferCoach(for participant: ParticipantProfile) async {
        guard let coachID = selectedCoachID,
              let coach = availableCoaches.first(where: {
                  $0.id == coachID
              }) else {
            error = .validation(
                field: "coach",
                reason: "Pilih Coach baru terlebih dahulu."
            )
            return
        }
        isSaving = true
        defer { isSaving = false }
        do {
            try await features.transferCoach(
                participant: participant,
                to: coach,
                reason: coachTransferReason
            )
            dismiss()
        } catch let domainError as DomainError {
            error = domainError
        } catch {
            self.error = .unknown
        }
    }

    private func approveCoachApplication() async {
        guard let application = person.coachApplication else {
            return
        }
        isSaving = true
        defer { isSaving = false }
        do {
            try await features.approveCoach(
                applicationID: application.id
            )
            dismiss()
        } catch let domainError as DomainError {
            error = domainError
        } catch {
            self.error = .unknown
        }
    }

    private func rejectCoachApplication() async {
        guard let application = person.coachApplication else {
            return
        }
        isSaving = true
        defer { isSaving = false }
        do {
            try await features.rejectCoach(
                applicationID: application.id,
                reason: rejectionReason
            )
            dismiss()
        } catch let domainError as DomainError {
            error = domainError
        } catch {
            self.error = .unknown
        }
    }

    private func applicationStatusTitle(
        _ status: CoachApplicationStatus
    ) -> LocalizedStringKey {
        switch status {
        case .draft:
            "coach.application.status.draft"
        case .ineligible:
            "coach.application.status.ineligible"
        case .readyForPayment:
            "coach.application.status.ready_for_payment"
        case .paymentProcessing:
            "coach.application.status.payment_processing"
        case .paymentVerified:
            "coach.application.status.payment_verified"
        case .pendingAdminApproval, .submitted:
            "coach.application.status.pending_admin_approval"
        case .acceptedPendingPayment:
            "coach.application.status.accepted_payment"
        case .active:
            "coach.application.status.active"
        case .approved:
            "coach.application.status.approved"
        case .rejected:
            "coach.application.status.rejected"
        case .expired:
            "coach.application.status.expired"
        }
    }

    private func applicationStatusKind(
        _ status: CoachApplicationStatus
    ) -> AppStatusKind {
        switch status {
        case .approved, .active:
            .success
        case .rejected, .ineligible, .expired:
            .error
        case .pendingAdminApproval, .submitted, .paymentProcessing,
             .acceptedPendingPayment:
            .pending
        case .paymentVerified:
            .information
        case .draft, .readyForPayment:
            .neutral
        }
    }
}
