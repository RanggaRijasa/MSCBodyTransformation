import SwiftUI

@MainActor
struct AdminTabRootView: View {
    let tab: AdminTab
    let features: AdminFeatureContainer
    let router: ShellTabRouter
    let showsOfflineBanner: Bool

    var body: some View {
        Group {
            switch tab {
            case .overview:
                AdminOverviewView(features: features, router: router)
            case .programs:
                AdminProgramsView(features: features, router: router)
            case .people:
                AdminPeopleView(features: features)
            case .content:
                AdminContentView(features: features, router: router)
            case .settings:
                AdminSettingsView(features: features, router: router)
            }
        }
        .safeAreaInset(edge: .top) {
            if showsOfflineBanner {
                OfflineBanner()
                    .padding(.horizontal, AppSpacing.medium)
            }
        }
    }
}

private struct AdminOverviewView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let features: AdminFeatureContainer
    let router: ShellTabRouter

    var body: some View {
        ScrollView {
            AsyncContentView(
                state: features.dashboardState,
                retryAction: { Task { await features.load() } }
            ) { snapshot in
                LazyVStack(alignment: .leading, spacing: AppSpacing.large) {
                    SectionHeader(
                        title: "Ringkasan operasional",
                        subtitle: "Semua angka berasal dari data demo lokal."
                    )

                    LazyVGrid(
                        columns: metricColumns,
                        spacing: AppSpacing.small
                    ) {
                        ForEach(ProgramStatus.allCases, id: \.self) { status in
                            MetricCard(
                                title: LocalizedStringKey(status.adminTitle),
                                value: (snapshot.programCounts[status] ?? 0)
                                    .formatted(
                                        .number.locale(
                                            Locale(identifier: "id-ID")
                                        )
                                    ),
                                systemImage: status == .archived
                                    ? "archivebox"
                                    : "square.stack.3d.up"
                            )
                        }
                        MetricCard(
                            title: "Peserta aktif",
                            value: snapshot.activeParticipantCount.formatted(
                                .number.locale(Locale(identifier: "id-ID"))
                            ),
                            systemImage: "person.3"
                        )
                        MetricCard(
                            title: "Persetujuan Coach",
                            value: snapshot.pendingCoachApprovals.formatted(
                                .number.locale(Locale(identifier: "id-ID"))
                            ),
                            systemImage: "person.badge.clock",
                            accentColor: .brandAccent
                        )
                        MetricCard(
                            title: "Pemeriksaan tertunda",
                            value: snapshot.pendingReviews.formatted(
                                .number.locale(Locale(identifier: "id-ID"))
                            ),
                            systemImage: "checklist",
                            accentColor: .brandAccent
                        )
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Text("Status perhitungan skor")
                            .font(AppTypography.sectionTitle)
                        Label(
                            "Pratinjau dihitung lokal. Layanan pusat menjadi "
                                + "sumber resmi pada fase integrasi.",
                            systemImage: "info.circle"
                        )
                        .font(AppTypography.secondary)
                        .foregroundStyle(Color.appSecondaryText)
                    }

                    HStack {
                        Button("Kelola program") {
                            router.navigate(
                                to: .admin(.programEditor(nil)),
                                in: .admin(.overview)
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.brandPrimary)

                        Button("Kelola pemenang") {
                            if let activeID = activeProgramID {
                                router.navigate(
                                    to: .admin(
                                        .winnerManagement(activeID)
                                    ),
                                    in: .admin(.overview)
                                )
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(activeProgramID == nil)
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Text("Audit lokal terbaru")
                            .font(AppTypography.sectionTitle)
                        if snapshot.auditEvents.isEmpty {
                            Text("Belum ada aktivitas istimewa.")
                                .foregroundStyle(Color.appSecondaryText)
                        } else {
                            ForEach(snapshot.auditEvents) { event in
                                AdminAuditRow(event: event)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: 760)
            .padding(AppSpacing.medium)
            .frame(maxWidth: .infinity)
        }
        .background(Color.appBackground)
        .accessibilityIdentifier("admin.overview")
    }

    private var activeProgramID: UUID? {
        guard case .loaded(let programs) = features.programsState else {
            return nil
        }
        return programs.first(where: { $0.status == .active })?.id
    }

    private var metricColumns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.flexible())]
        }
        return [
            GridItem(.adaptive(minimum: 150), spacing: AppSpacing.small)
        ]
    }
}

private struct AdminAuditRow: View {
    let event: AuditEvent

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.small) {
            Image(systemName: "checkmark.shield")
                .foregroundStyle(Color.brandPrimary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                Text(event.kind.adminTitle)
                    .font(AppTypography.cardTitle)
                Text(event.summary)
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
                Text(
                    event.createdAt,
                    format: .dateTime
                        .locale(Locale(identifier: "id-ID"))
                        .day()
                        .month(.wide)
                        .year()
                        .hour()
                        .minute()
                )
                .font(AppTypography.label)
                .foregroundStyle(Color.appSecondaryText)
            }
            Spacer()
        }
        .padding(AppSpacing.small)
        .background(
            Color.appSurface,
            in: RoundedRectangle(
                cornerRadius: AppRadius.medium,
                style: .continuous
            )
        )
    }
}

private struct AdminProgramsView: View {
    let features: AdminFeatureContainer
    let router: ShellTabRouter
    @State private var actionError: DomainError?

    var body: some View {
        List {
            if let message = features.lastMessage {
                Section {
                    Label(message, systemImage: "checkmark.circle")
                        .foregroundStyle(Color.appSuccess)
                }
            }

            if case .loaded = features.programsState {
                if features.filteredPrograms.isEmpty {
                    ContentUnavailableView(
                        "Tidak ada program",
                        systemImage: "square.stack.3d.up.slash",
                        description: Text(
                            "Ubah pencarian atau filter status."
                        )
                    )
                } else {
                    ForEach(ProgramStatus.allCases, id: \.self) { status in
                        let programs = features.filteredPrograms.filter {
                            $0.status == status
                        }
                        if !programs.isEmpty {
                            Section(status.adminTitle) {
                                ForEach(programs) { program in
                                    programRow(program)
                                }
                            }
                        }
                    }
                }
            } else {
                Section {
                    AsyncContentView(
                        state: features.programsState,
                        retryAction: { Task { await features.load() } }
                    ) { _ in EmptyView() }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .searchable(text: Bindable(features).programQuery)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Button("Semua status") {
                        features.programStatusFilter = nil
                    }
                    ForEach(ProgramStatus.allCases, id: \.self) { status in
                        Button(status.adminTitle) {
                            features.programStatusFilter = status
                        }
                    }
                } label: {
                    Label("Filter status", systemImage: "line.3.horizontal.decrease.circle")
                }
                Button {
                    Task { await createDraft() }
                } label: {
                    Label("Buat draft", systemImage: "plus")
                }
                .accessibilityIdentifier("admin.program.create")
            }
        }
        .alert(
            "Tindakan tidak dapat diselesaikan",
            isPresented: Binding(
                get: { actionError != nil },
                set: { if !$0 { actionError = nil } }
            )
        ) {
            Button("Tutup", role: .cancel) {}
        } message: {
            Text(actionError?.localizedAdminMessage ?? "")
        }
        .accessibilityIdentifier("admin.programs")
    }

    private func programRow(_ program: AdminProgramDraft) -> some View {
        let locale = Locale(identifier: "id-ID")
        let duration = program.durationInDays.formatted(
            .number.locale(locale)
        )
        let dayCount = program.days.count.formatted(
            .number.locale(locale)
        )
        return Button {
            router.navigate(
                to: .admin(.programEditor(program.id)),
                in: .admin(.programs)
            )
        } label: {
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                HStack {
                    Text(program.title)
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(Color.appPrimaryText)
                    Spacer()
                    Text(program.status.adminTitle)
                        .font(AppTypography.label)
                        .foregroundStyle(Color.appSecondaryText)
                }
                Text(program.summary.isEmpty
                    ? "Belum ada deskripsi."
                    : program.summary)
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
                Text("\(duration) hari • \(dayCount) hari disusun")
                .font(AppTypography.label.monospacedDigit())
                .foregroundStyle(Color.appSecondaryText)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("admin.program.open.\(program.id)")
        .swipeActions(edge: .trailing) {
            if program.status != .archived {
                Button("Arsipkan", role: .destructive) {
                    Task {
                        do {
                            try await features.archive(program)
                        } catch let error as DomainError {
                            actionError = error
                        } catch {
                            actionError = .unknown
                        }
                    }
                }
            }
            Button("Duplikasi") {
                Task {
                    do {
                        try await features.duplicate(program)
                    } catch let error as DomainError {
                        actionError = error
                    } catch {
                        actionError = .unknown
                    }
                }
            }
            .tint(.brandPrimary)
        }
    }

    private func createDraft() async {
        do {
            let draft = try await features.createDraft()
            router.navigate(
                to: .admin(.programEditor(draft.id)),
                in: .admin(.programs)
            )
        } catch let error as DomainError {
            actionError = error
        } catch {
            actionError = .unknown
        }
    }
}

private struct AdminPeopleView: View {
    let features: AdminFeatureContainer
    @State private var selectedPerson: AdminPersonSummary?
    @State private var actionError: DomainError?

    var body: some View {
        List {
            if case .loaded(let people) = features.peopleState {
                ForEach(UserRole.allCases, id: \.self) { role in
                    let matches = people.filter { $0.user.role == role }
                    if !matches.isEmpty {
                        Section(role.adminTitle) {
                            ForEach(matches) { person in
                                personRow(person)
                            }
                        }
                    }
                }
            } else {
                AsyncContentView(
                    state: features.peopleState,
                    retryAction: { Task { await features.load() } }
                ) { _ in EmptyView() }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .sheet(item: $selectedPerson) { person in
            AdminPersonDetailSheet(
                person: person,
                features: features
            )
        }
        .alert(
            "Tindakan tidak dapat diselesaikan",
            isPresented: Binding(
                get: { actionError != nil },
                set: { if !$0 { actionError = nil } }
            )
        ) {
            Button("Tutup", role: .cancel) {}
        } message: {
            Text(actionError?.localizedAdminMessage ?? "")
        }
        .accessibilityIdentifier("admin.people")
    }

    private func personRow(_ person: AdminPersonSummary) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Button {
                selectedPerson = person
            } label: {
                HStack(spacing: AppSpacing.small) {
                    UserAvatar(displayName: person.user.displayName)
                    VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                        Text(person.user.displayName)
                            .font(AppTypography.cardTitle)
                            .foregroundStyle(Color.appPrimaryText)
                        Text(person.user.role.adminTitle)
                            .font(AppTypography.label)
                            .foregroundStyle(Color.appSecondaryText)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color.appSecondaryText)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(
                "admin.people.open.\(person.user.id)"
            )

            if person.user.isCoachApprovalPending {
                Button("Setujui Coach") {
                    Task {
                        do {
                            try await features.approveCoach(
                                userID: person.user.id
                            )
                        } catch let error as DomainError {
                            actionError = error
                        } catch {
                            actionError = .unknown
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.brandPrimary)
                .accessibilityIdentifier(
                    "admin.people.approve.\(person.user.id)"
                )
            }

            if let coach = person.coachProfile, coach.isApproved {
                Toggle(
                    "Tampilkan di direktori publik",
                    isOn: Binding(
                        get: { coach.isPublic },
                        set: { value in
                            Task {
                                do {
                                    try await features.setCoachPublic(
                                        coach,
                                        isPublic: value
                                    )
                                } catch let error as DomainError {
                                    actionError = error
                                } catch {
                                    actionError = .unknown
                                }
                            }
                        }
                    )
                )
            }
        }
        .padding(.vertical, AppSpacing.xSmall)
    }
}

private struct AdminPersonDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let person: AdminPersonSummary
    let features: AdminFeatureContainer

    @State private var selectedProgramID: UUID?
    @State private var reason = ""
    @State private var error: DomainError?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Ringkasan") {
                    LabeledContent("Nama", value: person.user.displayName)
                    LabeledContent("Peran", value: person.user.role.adminTitle)
                    if let participant = person.participantProfile {
                        LabeledContent("Kota", value: participant.city)
                        LabeledContent(
                            "Jumlah enrollment",
                            value: person.enrollments.count.formatted(
                                .number.locale(Locale(identifier: "id-ID"))
                            )
                        )
                    }
                }

                if let participant = person.participantProfile {
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
                            text: $reason,
                            axis: .vertical
                        )
                        .accessibilityIdentifier(
                            "admin.people.enroll-reason"
                        )
                        Button(isSaving ? "Menyimpan…" : "Daftarkan peserta") {
                            Task { await enroll(participant: participant) }
                        }
                        .disabled(isSaving || availablePrograms.isEmpty)
                        .accessibilityIdentifier("admin.people.enroll")
                    } header: {
                        Text("Pendaftaran manual")
                    } footer: {
                        Text(
                            "Alasan wajib diisi dan dicatat pada audit lokal."
                        )
                    }
                }
            }
            .navigationTitle("Detail orang")
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
            }
        }
    }

    private var availablePrograms: [AdminProgramDraft] {
        guard case .loaded(let programs) = features.programsState else {
            return []
        }
        return programs.filter { $0.status != .archived }
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
                reason: reason
            )
            dismiss()
        } catch let domainError as DomainError {
            error = domainError
        } catch {
            self.error = .unknown
        }
    }
}

private struct AdminSettingsView: View {
    let features: AdminFeatureContainer
    let router: ShellTabRouter
    @State private var notificationsEnabled = true

    var body: some View {
        Form {
            Section("Konfigurasi lokal") {
                Toggle("Notifikasi demo", isOn: $notificationsEnabled)
                LabeledContent("Zona waktu default", value: "Asia/Makassar")
                LabeledContent("Mode data", value: "Fixture lokal")
            }
            Section {
                if let program = activeProgram {
                    Button("Kelola pemenang \(program.title)") {
                        router.navigate(
                            to: .admin(.winnerManagement(program.id)),
                            in: .admin(.settings)
                        )
                    }
                } else {
                    Text("Belum ada program aktif.")
                        .foregroundStyle(Color.appSecondaryText)
                }
            } header: {
                Text("Pemenang")
            } footer: {
                Text(
                    "Tidak ada data yang dikirim ke server pada fase ini."
                )
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .accessibilityIdentifier("admin.settings")
    }

    private var activeProgram: AdminProgramDraft? {
        guard case .loaded(let programs) = features.programsState else {
            return nil
        }
        return programs.first { $0.status == .active }
    }
}

extension DomainError {
    var localizedAdminMessage: String {
        switch self {
        case .validation(_, let reason), .conflict(let reason):
            reason
        case .notFound:
            "Data yang dicari tidak tersedia."
        case .permissionDenied:
            "Akun ini tidak memiliki izin untuk tindakan tersebut."
        case .offline:
            "Data lokal sedang tidak tersedia."
        case .timeout:
            "Proses memerlukan waktu terlalu lama."
        case .sessionExpired:
            "Sesi demo berakhir."
        case .invalidFixture, .unknown:
            "Coba lagi."
        }
    }
}
