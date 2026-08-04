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
    @State private var error: DomainError?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                identitySection
                profileDataSection

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
            Text("Alasan wajib diisi dan dicatat pada audit lokal.")
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
        return programs.filter { $0.status != .archived }
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
}
