import SwiftUI

nonisolated enum AdminDashboardQuickAction:
    String,
    CaseIterable,
    Equatable,
    Identifiable,
    Sendable
{
    case createProgram
    case addWinnerPoster

    var id: String { rawValue }

    var title: String {
        switch self {
        case .createProgram:
            "Buat program"
        case .addWinnerPoster:
            "Tambah poster"
        }
    }

    var systemImage: String {
        switch self {
        case .createProgram:
            "plus.square.fill"
        case .addWinnerPoster:
            "photo.stack.fill"
        }
    }

    var accessibilityIdentifier: String {
        "admin.dashboard.action.\(rawValue)"
    }
}

@MainActor
struct AdminDashboardView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let features: AdminFeatureContainer
    let router: ShellTabRouter
    let onSelectAdminTab: (AdminTab) -> Void

    @State private var actionError: DomainError?
    @State private var isCreatingProgram = false

    private let locale = Locale(
        identifier: AppConfiguration.indonesianLocaleIdentifier
    )

    var body: some View {
        ScrollView {
            AsyncContentView(
                state: features.dashboardState,
                retryAction: { Task { await features.load() } }
            ) { snapshot in
                LazyVStack(
                    alignment: .leading,
                    spacing: AppSpacing.large
                ) {
                    SectionHeader(
                        title: "Kendali operasional hari ini",
                        subtitle: "Data demo lokal."
                    )

                    attentionSection(snapshot)
                    quickActionsSection
                    dailyOverviewSection(snapshot)
                    recentActivitySection(snapshot.auditEvents)
                }
            }
            .frame(maxWidth: 760, alignment: .leading)
            .padding(AppSpacing.medium)
            .frame(maxWidth: .infinity)
        }
        .background(Color.appBackground)
        .refreshable {
            await features.load()
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
        .accessibilityIdentifier("admin.dashboard")
    }

    private func attentionSection(
        _ snapshot: AdminDashboardSnapshot
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            SectionHeader(title: "Perlu tindakan")

            if snapshot.pendingReviews == 0,
               snapshot.pendingCoachApprovals == 0 {
                AdminDashboardQuietState()
            } else {
                VStack(spacing: 0) {
                    if snapshot.pendingReviews > 0 {
                        AdminDashboardAttentionRow(
                            count: snapshot.pendingReviews,
                            title: "Pemeriksaan tertunda",
                            subtitle:
                                "Bukti peserta menunggu keputusan Coach.",
                            systemImage: "clock.badge.exclamationmark",
                            accessibilityIdentifier:
                                "admin.dashboard.attention.reviews"
                        )
                    }

                    if snapshot.pendingReviews > 0,
                       snapshot.pendingCoachApprovals > 0 {
                        Divider()
                            .padding(.leading, 68)
                    }

                    if snapshot.pendingCoachApprovals > 0 {
                        AdminDashboardAttentionRow(
                            count: snapshot.pendingCoachApprovals,
                            title: "Persetujuan Coach",
                            subtitle: "Akun baru perlu ditinjau.",
                            systemImage: "person.badge.clock",
                            accessibilityIdentifier:
                                "admin.dashboard.attention.coachApprovals"
                        ) {
                            features.peopleScope = .pendingCoachApprovals
                            onSelectAdminTab(.people)
                        }
                    }
                }
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
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            SectionHeader(title: "Akses cepat")

            LazyVGrid(
                columns: quickActionColumns,
                spacing: AppSpacing.small
            ) {
                ForEach(AdminDashboardQuickAction.allCases) { action in
                    AdminDashboardQuickActionCard(
                        action: action,
                        isLoading:
                            action == .createProgram && isCreatingProgram
                    ) {
                        perform(action)
                    }
                    .disabled(isCreatingProgram)
                }
            }
            .accessibilityIdentifier("admin.dashboard.quickActions")
        }
    }

    private func dailyOverviewSection(
        _ snapshot: AdminDashboardSnapshot
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            SectionHeader(title: "Gambaran hari ini")

            VStack(spacing: AppSpacing.medium) {
                Group {
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(spacing: AppSpacing.medium) {
                            dailyMetrics(snapshot)
                        }
                    } else {
                        HStack(spacing: AppSpacing.medium) {
                            dailyMetrics(snapshot)
                        }
                    }
                }

                Divider()

                Label {
                    VStack(
                        alignment: .leading,
                        spacing: AppSpacing.xxSmall
                    ) {
                        Text("Pratinjau skor dihitung lokal.")
                            .font(AppTypography.cardTitle)
                            .foregroundStyle(Color.appPrimaryText)
                        Text(
                            "Layanan pusat menjadi sumber resmi pada fase integrasi."
                        )
                        .font(AppTypography.secondary)
                        .foregroundStyle(Color.appSecondaryText)
                    }
                } icon: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(Color.appInfo)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
            .accessibilityIdentifier("admin.dashboard.overview")
        }
    }

    @ViewBuilder
    private func dailyMetrics(
        _ snapshot: AdminDashboardSnapshot
    ) -> some View {
        AdminDashboardMetric(
            value: snapshot.programCounts[.active] ?? 0,
            title: "Program aktif",
            systemImage: "chart.bar.fill",
            locale: locale
        )

        metricDivider

        AdminDashboardMetric(
            value: snapshot.activeParticipantCount,
            title: "Peserta aktif",
            systemImage: "person.2.fill",
            locale: locale
        )

        metricDivider

        AdminDashboardMetric(
            value: snapshot.programCounts[.scheduled] ?? 0,
            title: "Terjadwal",
            systemImage: "calendar",
            locale: locale
        )
    }

    @ViewBuilder
    private var metricDivider: some View {
        if dynamicTypeSize.isAccessibilitySize {
            Divider()
        } else {
            Divider()
                .frame(height: 72)
        }
    }

    private func recentActivitySection(
        _ auditEvents: [AuditEvent]
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            SectionHeader(title: "Aktivitas terbaru")

            if auditEvents.isEmpty {
                Label(
                    "Belum ada aktivitas istimewa.",
                    systemImage: "clock"
                )
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appSecondaryText)
                .padding(AppSpacing.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    Color.appSurface,
                    in: RoundedRectangle(
                        cornerRadius: AppRadius.large,
                        style: .continuous
                    )
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(
                        Array(auditEvents.prefix(3).enumerated()),
                        id: \.element.id
                    ) { index, event in
                        AdminDashboardAuditRow(event: event, locale: locale)

                        if index < min(auditEvents.count, 3) - 1 {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
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
        }
        .accessibilityIdentifier("admin.dashboard.activity")
    }

    private var quickActionColumns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return [GridItem(.flexible())]
        }
        return [
            GridItem(.flexible(), spacing: AppSpacing.small),
            GridItem(.flexible(), spacing: AppSpacing.small)
        ]
    }

    private func perform(_ action: AdminDashboardQuickAction) {
        switch action {
        case .createProgram:
            Task { await createProgram() }
        case .addWinnerPoster:
            onSelectAdminTab(.content)
        }
    }

    private func createProgram() async {
        guard !isCreatingProgram else {
            return
        }
        isCreatingProgram = true
        defer { isCreatingProgram = false }

        do {
            let draft = try await features.createDraft()
            router.navigate(
                to: .admin(.programEditor(draft.id)),
                in: .admin(.overview)
            )
        } catch let error as DomainError {
            actionError = error
        } catch {
            actionError = .unknown
        }
    }
}

private struct AdminDashboardAttentionRow: View {
    let count: Int
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let systemImage: String
    let accessibilityIdentifier: String
    let action: (() -> Void)?

    init(
        count: Int,
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        systemImage: String,
        accessibilityIdentifier: String,
        action: (() -> Void)? = nil
    ) {
        self.count = count
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.accessibilityIdentifier = accessibilityIdentifier
        self.action = action
    }

    @ViewBuilder
    var body: some View {
        if let action {
            Button(action: action) {
                rowContent(showsChevron: true)
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text("Buka daftar yang perlu ditinjau."))
            .accessibilityIdentifier(accessibilityIdentifier)
        } else {
            rowContent(showsChevron: false)
                .accessibilityIdentifier(accessibilityIdentifier)
        }
    }

    private func rowContent(showsChevron: Bool) -> some View {
        HStack(spacing: AppSpacing.small) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.appWarning)
                .frame(width: 44, height: 44)
                .background(
                    Color.brandAccent.opacity(0.18),
                    in: RoundedRectangle(
                        cornerRadius: AppRadius.medium,
                        style: .continuous
                    )
                )
                .accessibilityHidden(true)

            Text(
                count,
                format: .number.locale(
                    Locale(
                        identifier:
                            AppConfiguration.indonesianLocaleIdentifier
                    )
                )
            )
            .font(AppTypography.cardTitle.monospacedDigit())
            .foregroundStyle(Color.black)
            .frame(minWidth: 32, minHeight: 32)
            .background(Color.brandAccent, in: RoundedRectangle(
                cornerRadius: AppRadius.small,
                style: .continuous
            ))

            VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                Text(title)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(Color.appPrimaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: AppSpacing.xSmall)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.appSecondaryText)
                    .accessibilityHidden(true)
            }
        }
        .padding(AppSpacing.medium)
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

private struct AdminDashboardQuietState: View {
    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                Text("Tidak ada tindakan mendesak")
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(Color.appPrimaryText)
                Text("Semua antrean operasional sudah tertangani.")
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
            }
        } icon: {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(Color.appSuccess)
        }
        .padding(AppSpacing.medium)
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
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
        .accessibilityIdentifier("admin.dashboard.attention.clear")
    }
}

private struct AdminDashboardQuickActionCard: View {
    let action: AdminDashboardQuickAction
    let isLoading: Bool
    let perform: () -> Void

    var body: some View {
        Button(action: perform) {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                HStack {
                    Group {
                        if isLoading {
                            ProgressView()
                                .tint(Color.brandPrimary)
                        } else {
                            Image(systemName: action.systemImage)
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(
                                    action == .createProgram
                                        ? Color.brandPrimary
                                        : Color.appPrimaryText
                                )
                        }
                    }
                    .frame(width: 44, height: 44)
                    .background(
                        action == .createProgram
                            ? Color.brandPrimary.opacity(0.12)
                            : Color.appSecondaryBackground,
                        in: RoundedRectangle(
                            cornerRadius: AppRadius.medium,
                            style: .continuous
                        )
                    )
                    .accessibilityHidden(true)

                    Spacer(minLength: AppSpacing.xSmall)

                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color.appSecondaryText)
                        .accessibilityHidden(true)
                }

                Text(LocalizedStringKey(action.title))
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(Color.appPrimaryText)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(AppSpacing.medium)
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
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
            .contentShape(
                RoundedRectangle(
                    cornerRadius: AppRadius.large,
                    style: .continuous
                )
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(action.accessibilityIdentifier)
    }
}

private struct AdminDashboardMetric: View {
    let value: Int
    let title: LocalizedStringKey
    let systemImage: String
    let locale: Locale

    var body: some View {
        VStack(spacing: AppSpacing.xSmall) {
            Image(systemName: systemImage)
                .foregroundStyle(Color.brandPrimary)
                .accessibilityHidden(true)

            Text(value, format: .number.locale(locale))
                .font(AppTypography.metric)
                .foregroundStyle(Color.appPrimaryText)

            Text(title)
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appSecondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

private struct AdminDashboardAuditRow: View {
    let event: AuditEvent
    let locale: Locale

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.small) {
            Image(systemName: "checkmark.shield")
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 44, height: 44)
                .background(
                    Color.appSecondaryBackground,
                    in: RoundedRectangle(
                        cornerRadius: AppRadius.medium,
                        style: .continuous
                    )
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                Text(event.kind.adminTitle)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(Color.appPrimaryText)
                Text(event.summary)
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
                Text(
                    event.createdAt,
                    format: .dateTime
                        .locale(locale)
                        .day()
                        .month(.wide)
                        .year()
                        .hour()
                        .minute()
                )
                .font(AppTypography.label)
                .foregroundStyle(Color.appSecondaryText)
            }

            Spacer(minLength: AppSpacing.xSmall)
        }
        .padding(AppSpacing.small)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Dashboard Admin — normal") {
    NavigationStack {
        AdminDashboardPreview()
            .navigationTitle("Dashboard")
    }
    .environment(\.locale, Locale(identifier: "id-ID"))
}

#Preview("Dashboard Admin — teks terbesar dan gelap") {
    NavigationStack {
        AdminDashboardPreview()
            .navigationTitle("Dashboard")
    }
    .environment(\.locale, Locale(identifier: "id-ID"))
    .dynamicTypeSize(.accessibility5)
    .preferredColorScheme(.dark)
}

@MainActor
private struct AdminDashboardPreview: View {
    @State private var features = AdminFeatureContainer(
        environment: .preview
    )
    @State private var router = ShellTabRouter()

    var body: some View {
        AdminDashboardView(
            features: features,
            router: router,
            onSelectAdminTab: { _ in }
        )
        .task {
            await features.load()
        }
    }
}
