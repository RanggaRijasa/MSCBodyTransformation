import SwiftUI

@MainActor
struct AdminTabRootView: View {
    let tab: AdminTab
    let features: AdminFeatureContainer
    let router: ShellTabRouter
    let showsOfflineBanner: Bool
    let onSelectAdminTab: (AdminTab) -> Void

    var body: some View {
        Group {
            switch tab {
            case .overview:
                AdminDashboardView(
                    features: features,
                    router: router,
                    onSelectAdminTab: onSelectAdminTab
                )
            case .programs:
                AdminProgramsView(features: features, router: router)
            case .people:
                AdminPeopleView(features: features)
            case .content:
                AdminContentView(features: features)
            case .settings:
                AdminSettingsView()
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

private struct AdminProgramsView: View {
    let features: AdminFeatureContainer
    let router: ShellTabRouter
    @State private var actionError: DomainError?

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                searchField

                Button {
                    Task { await createDraft() }
                } label: {
                    Label("Buat program baru", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .accessibilityIdentifier("admin.program.create")

                if let message = features.lastMessage {
                    Label(message, systemImage: "checkmark.circle.fill")
                        .font(AppTypography.secondary)
                        .foregroundStyle(Color.appSuccess)
                        .padding(.horizontal, AppSpacing.xSmall)
                }
            }
            .padding(.horizontal, AppSpacing.medium)
            .padding(.top, AppSpacing.small)
            .padding(.bottom, AppSpacing.medium)
            .background(Color.appBackground)

            Divider()

            ScrollView {
                LazyVStack(
                    alignment: .leading,
                    spacing: AppSpacing.medium
                ) {
                    programContent
                }
                .padding(AppSpacing.medium)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Color.appBackground)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
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
    }

    private var searchField: some View {
        HStack(spacing: AppSpacing.small) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.appSecondaryText)
                .accessibilityHidden(true)

            TextField(
                "Cari program",
                text: Bindable(features).programQuery
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.search)
            .accessibilityIdentifier("admin.program.search")

            if !features.programQuery.isEmpty {
                Button {
                    features.programQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.appSecondaryText)
                }
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel("Hapus pencarian")
            }
        }
        .padding(.leading, AppSpacing.medium)
        .padding(.trailing, AppSpacing.xSmall)
        .frame(minHeight: 44)
        .background(
            Color.appSecondaryBackground,
            in: RoundedRectangle(
                cornerRadius: AppRadius.medium,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: AppRadius.medium,
                style: .continuous
            )
            .stroke(Color.appBorder, lineWidth: 1)
        }
    }

    @ViewBuilder
    private var programContent: some View {
        switch features.programsState {
        case .idle, .loading:
            LoadingStateView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.xxLarge)
        case .failed(let error):
            ErrorStateView(error: error) {
                Task { await features.load() }
            }
            .padding(.vertical, AppSpacing.large)
        case .empty:
            emptyProgramsView(
                title: "Belum ada program",
                message: "Buat program pertama dari tombol di atas."
            )
        case .offline(let programs):
            Label(
                "Menampilkan data lokal terakhir.",
                systemImage: "wifi.slash"
            )
            .font(AppTypography.secondary)
            .foregroundStyle(Color.appSecondaryText)
            if let programs {
                programCards(filter(programs))
            } else {
                emptyProgramsView(
                    title: "Program tidak tersedia",
                    message: "Coba lagi setelah data lokal siap."
                )
            }
        case .loaded:
            if features.filteredPrograms.isEmpty {
                emptyProgramsView(
                    title: features.programQuery.isEmpty
                        && features.programStatusFilter == nil
                        ? "Belum ada program"
                        : "Program tidak ditemukan",
                    message: features.programQuery.isEmpty
                        && features.programStatusFilter == nil
                        ? "Buat program pertama dari tombol di atas."
                        : "Ubah pencarian atau filter status."
                )
            } else {
                programCards(features.filteredPrograms)
            }
        }
    }

    @ViewBuilder
    private func programCards(
        _ programs: [AdminProgramDraft]
    ) -> some View {
        ForEach(programs) { program in
            programCard(program)
        }
    }

    private func emptyProgramsView(
        title: String,
        message: String
    ) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: "square.stack.3d.up.slash")
        } description: {
            Text(message)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xxLarge)
    }

    private func filter(
        _ programs: [AdminProgramDraft]
    ) -> [AdminProgramDraft] {
        let query = features.programQuery.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        return programs.filter { program in
            (query.isEmpty
                || program.title.localizedCaseInsensitiveContains(query))
                && (features.programStatusFilter == nil
                    || program.status == features.programStatusFilter)
        }
    }

    private func programCard(_ program: AdminProgramDraft) -> some View {
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
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                HStack(alignment: .top, spacing: AppSpacing.small) {
                    VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                        Text(program.title)
                            .font(AppTypography.cardTitle)
                            .foregroundStyle(Color.appPrimaryText)
                            .multilineTextAlignment(.leading)
                        Text(
                            program.summary.isEmpty
                                ? "Belum ada deskripsi."
                                : program.summary
                        )
                        .font(AppTypography.secondary)
                        .foregroundStyle(Color.appSecondaryText)
                        .multilineTextAlignment(.leading)
                    }
                    Spacer(minLength: AppSpacing.small)
                    VStack(alignment: .trailing, spacing: AppSpacing.small) {
                        StatusBadge(
                            title: LocalizedStringKey(
                                program.status.adminTitle
                            ),
                            kind: statusKind(for: program.status)
                        )
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.appSecondaryText)
                            .accessibilityHidden(true)
                    }
                }

                Text("\(duration) hari • \(dayCount) hari disusun")
                    .font(AppTypography.label.monospacedDigit())
                    .foregroundStyle(Color.appSecondaryText)

                if program.status == .draft {
                    let progress = AdminProgramFlowProgress(
                        issues: AdminProgramDraftValidator().validate(program)
                    )
                    VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                        ProgressView(
                            value: Double(progress.completedStageCount),
                            total: 3
                        )
                        .tint(.brandPrimary)
                        Text(
                            "\(progress.completedStageCount.formatted(.number.locale(locale))) dari 3 tahap selesai"
                        )
                        .font(AppTypography.label.monospacedDigit())
                        .foregroundStyle(Color.appSecondaryText)
                    }
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
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("admin.program.open.\(program.id)")
    }

    private func statusKind(for status: ProgramStatus) -> AppStatusKind {
        switch status {
        case .draft:
            .warning
        case .preparingCommerce:
            .pending
        case .scheduled, .active:
            .success
        case .completed, .archived:
            .neutral
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
    @State private var selectedRole = UserRole.participant
    @State private var selectedPerson: AdminPersonSummary?
    @State private var actionError: DomainError?

    var body: some View {
        VStack(spacing: 0) {
            peopleHeader
            rolePicker
            peopleList
                .frame(maxHeight: .infinity)
        }
        .background(Color.appBackground)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: features.peopleScope, initial: true) { _, scope in
            if scope == .pendingCoachApprovals {
                selectedRole = .coach
            }
        }
        .onChange(of: selectedRole) { _, role in
            if role != .coach,
               features.peopleScope == .pendingCoachApprovals {
                features.peopleScope = .all
            }
        }
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
    }

    private var peopleHeader: some View {
        HStack(alignment: .center, spacing: AppSpacing.medium) {
            Text("tab.admin.people")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Color.appPrimaryText)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("admin.people")

            Spacer(minLength: AppSpacing.small)
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.top, AppSpacing.xSmall)
        .padding(.bottom, AppSpacing.xSmall)
    }

    private var rolePicker: some View {
        Picker("Peran", selection: $selectedRole) {
            ForEach(UserRole.allCases, id: \.self) { role in
                Text(role.adminTitle)
                    .font(.subheadline.weight(.medium))
                    .frame(minHeight: AppSpacing.xLarge)
                    .tag(role)
            }
        }
        .pickerStyle(.segmented)
        .controlSize(.large)
        .frame(minHeight: AppControlMetrics.minimumTouchTarget)
        .padding(.horizontal, AppSpacing.medium)
        .padding(.top, AppSpacing.small)
        .padding(.bottom, AppSpacing.medium)
        .accessibilityIdentifier("admin.people.role-filter")
    }

    private var peopleList: some View {
        List {
            if features.peopleScope == .pendingCoachApprovals {
                Section {
                    Label(
                        "Menampilkan persetujuan Coach tertunda.",
                        systemImage: "line.3.horizontal.decrease.circle.fill"
                    )
                    .foregroundStyle(Color.appSecondaryText)

                    Button("Tampilkan semua Coach") {
                        features.peopleScope = .all
                    }
                }
            }

            if case .loaded = features.peopleState {
                if visiblePeople.isEmpty {
                    ContentUnavailableView(
                        emptyStateTitle,
                        systemImage: emptyStateSystemImage,
                        description: Text(emptyStateMessage)
                    )
                } else {
                    ForEach(visiblePeople) { person in
                        personRow(person)
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
        .contentMargins(.top, 0, for: .scrollContent)
        .scrollContentBackground(.hidden)
    }

    private var visiblePeople: [AdminPersonSummary] {
        features.filteredPeople.filter {
            $0.user.role == selectedRole
        }
    }

    private var emptyStateTitle: LocalizedStringKey {
        if features.peopleScope == .pendingCoachApprovals {
            return "Tidak ada persetujuan Coach tertunda"
        }
        switch selectedRole {
        case .participant:
            return "Belum ada peserta"
        case .coach:
            return "Belum ada Coach"
        case .admin:
            return "Belum ada Admin"
        }
    }

    private var emptyStateMessage: LocalizedStringKey {
        if features.peopleScope == .pendingCoachApprovals {
            return "Semua akun Coach sudah ditinjau."
        }
        switch selectedRole {
        case .participant:
            return "Akun peserta akan muncul di sini."
        case .coach:
            return "Akun Coach akan muncul di sini."
        case .admin:
            return "Akun Admin akan muncul di sini."
        }
    }

    private var emptyStateSystemImage: String {
        if features.peopleScope == .pendingCoachApprovals {
            return "person.badge.checkmark"
        }
        switch selectedRole {
        case .participant:
            return "person.2"
        case .coach:
            return "person.badge.checkmark"
        case .admin:
            return "person.crop.circle"
        }
    }

    private func personRow(_ person: AdminPersonSummary) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Button {
                selectedPerson = person
            } label: {
                HStack(spacing: AppSpacing.small) {
                    UserAvatar(displayName: person.user.displayName)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                        Text(person.user.displayName)
                            .font(AppTypography.cardTitle)
                            .foregroundStyle(Color.appPrimaryText)
                        Text(personSubtitle(person))
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

    private func personSubtitle(_ person: AdminPersonSummary) -> String {
        if let participant = person.participantProfile {
            return participant.city
        }
        if let coach = person.coachProfile {
            return coach.city
        }
        return person.user.email
    }
}

private struct AdminSettingsView: View {
    @State private var notificationsEnabled = true

    var body: some View {
        Form {
            Section("Konfigurasi lokal") {
                Toggle("Notifikasi demo", isOn: $notificationsEnabled)
                LabeledContent("Zona waktu default", value: "Asia/Makassar")
                LabeledContent("Mode data", value: "Fixture lokal")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
        .accessibilityIdentifier("admin.settings")
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
