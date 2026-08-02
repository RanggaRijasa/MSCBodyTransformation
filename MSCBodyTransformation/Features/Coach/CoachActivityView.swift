import SwiftUI

@MainActor
struct CoachActivityView: View {
    let state: CoachActivityState
    let router: ShellTabRouter

    @State private var presentedFilter: CoachActivityFilterDraft?

    var body: some View {
        Group {
            switch state.state {
            case .idle, .loading:
                LoadingStateView()
            case .failed(let error):
                ErrorStateView(error: error) {
                    Task {
                        await state.load()
                    }
                }
                .padding(AppSpacing.medium)
            case .loaded:
                loadedContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .navigationTitle(Text("coach.activity.navigation_title"))
        .navigationBarTitleDisplayMode(.large)
        .task {
            if state.state == .idle {
                await state.load()
            }
        }
        .sheet(item: $presentedFilter) { draft in
            CoachActivityFilterSheet(
                draft: draft,
                programs: state.availablePrograms,
                referenceDate: state.referenceDate
            ) { selection in
                state.selectedProgramID = selection.programID
                state.kindFilter = selection.kind
                state.timeRange = selection.timeRange
            }
        }
        .accessibilityIdentifier("coach.activity")
    }

    private var loadedContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.large) {
                FilterSummaryButton(
                    title: "coach.activity.filter.action",
                    summary: Text(verbatim: filterSummary),
                    identifier: "coach.activity.filter"
                ) {
                    presentedFilter = CoachActivityFilterDraft(
                        programID: state.selectedProgramID,
                        kind: state.kindFilter,
                        timeRange: state.timeRange
                    )
                }

                if state.sections.isEmpty {
                    emptyContent
                } else {
                    ForEach(state.sections) { section in
                        activitySection(section)
                    }

                    if state.timeRange == .today,
                       state.hasOlderMatchingActivity {
                        previousActivityButton
                    }
                }
            }
            .frame(maxWidth: 760, alignment: .leading)
            .padding(AppSpacing.medium)
            .frame(maxWidth: .infinity)
        }
        .refreshable {
            await state.load()
        }
    }

    private var emptyContent: some View {
        ContentUnavailableView {
            Label(
                emptyTitle,
                systemImage: state.timeRange == .today
                    ? "clock"
                    : "line.3.horizontal.decrease.circle"
            )
        } description: {
            Text(emptyMessage)
        } actions: {
            if state.timeRange == .today,
               state.hasOlderMatchingActivity {
                Button {
                    state.showPreviousActivity()
                } label: {
                    Label(
                        "coach.activity.previous",
                        systemImage: "clock.arrow.circlepath"
                    )
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("coach.activity.previous")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xxLarge)
    }

    private var emptyTitle: LocalizedStringKey {
        state.timeRange == .today
            ? "coach.activity.empty.today.title"
            : "coach.activity.empty.filtered.title"
    }

    private var emptyMessage: LocalizedStringKey {
        state.timeRange == .today
            ? "coach.activity.empty.today.message"
            : "coach.activity.empty.filtered.message"
    }

    private func activitySection(
        _ section: CoachActivitySection
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(sectionTitle(for: section.day))
                .font(AppTypography.sectionTitle)
                .foregroundStyle(Color.appPrimaryText)

            VStack(spacing: 0) {
                ForEach(Array(section.items.enumerated()), id: \.element.id) {
                    index,
                    item in
                    CoachActivityRow(item: item) {
                        open(item)
                    }

                    if index < section.items.count - 1 {
                        Divider()
                            .padding(.leading, 80)
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

    private var previousActivityButton: some View {
        Button {
            state.showPreviousActivity()
        } label: {
            Label(
                "coach.activity.previous",
                systemImage: "clock.arrow.circlepath"
            )
            .frame(maxWidth: .infinity, minHeight: 50)
        }
        .buttonStyle(SecondaryActionButtonStyle())
        .accessibilityIdentifier("coach.activity.previous")
    }

    private var filterSummary: String {
        [
            selectedProgramTitle,
            kindFilterTitle(state.kindFilter),
            timeRangeTitle(state.timeRange)
        ]
        .joined(separator: " · ")
    }

    private var selectedProgramTitle: String {
        state.availablePrograms.first {
            $0.id == state.selectedProgramID
        }?.title ?? String(
            localized: "coach.filter.all_programs",
            defaultValue: "Semua program"
        )
    }

    private func sectionTitle(for day: Date) -> String {
        if state.calendar.isDate(day, inSameDayAs: state.referenceDate) {
            return String(
                localized: "coach.activity.section.today",
                defaultValue: "Hari ini"
            )
        }
        if let yesterday = state.calendar.date(
            byAdding: .day,
            value: -1,
            to: state.referenceDate
        ),
           state.calendar.isDate(day, inSameDayAs: yesterday) {
            return String(
                localized: "coach.activity.section.yesterday",
                defaultValue: "Kemarin"
            )
        }
        return day.formatted(
            Date.FormatStyle(
                date: .complete,
                time: .omitted,
                locale: CoachFormatting.locale,
                timeZone: state.calendar.timeZone
            )
        )
    }

    private func open(_ item: CoachActivityItem) {
        if item.requiresReview {
            router.navigate(
                to: .coach(.reviewQueue),
                in: .coach(.dashboard)
            )
        } else {
            router.navigate(
                to: .coach(.participantDetail(item.participantID)),
                in: .coach(.dashboard)
            )
        }
    }
}

private struct CoachActivityRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let item: CoachActivityItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    accessibilityLayout
                } else {
                    standardLayout
                }
            }
            .padding(AppSpacing.medium)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("coach.activity.row.hint"))
        .accessibilityIdentifier("coach.activity.item.\(item.id)")
    }

    private var standardLayout: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack(alignment: .top, spacing: AppSpacing.medium) {
                UserAvatar(
                    displayName: item.participantName,
                    imageName: item.participantPhotoReference,
                    size: 56
                )
                .accessibilityHidden(true)

                activityDetails

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appSecondaryText)
                    .frame(minHeight: AppControlMetrics.minimumTouchTarget)
                    .accessibilityHidden(true)
            }

            HStack(spacing: AppSpacing.xSmall) {
                Spacer()
                    .frame(width: 72)
                trailingStatus
            }
        }
    }

    private var accessibilityLayout: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack(alignment: .top, spacing: AppSpacing.medium) {
                UserAvatar(
                    displayName: item.participantName,
                    imageName: item.participantPhotoReference,
                    size: 56
                )
                .accessibilityHidden(true)
                activityDetails
            }

            HStack {
                trailingStatus
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.appSecondaryText)
                    .accessibilityHidden(true)
            }
        }
    }

    private var activityDetails: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
            Text(item.participantName)
                .font(AppTypography.cardTitle)
                .foregroundStyle(Color.appPrimaryText)

            Text(activityDescription)
                .font(AppTypography.body)
                .foregroundStyle(Color.appPrimaryText)
                .fixedSize(horizontal: false, vertical: true)

            Text(activityTime)
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var trailingStatus: some View {
        HStack(spacing: AppSpacing.xSmall) {
            Image(systemName: activityIcon)
                .font(.title3.weight(.medium))
                .foregroundStyle(activityColor)
                .accessibilityHidden(true)

            badge
        }
    }

    @ViewBuilder
    private var badge: some View {
        if item.requiresReview {
            activityBadge(
                String(
                    localized: "coach.activity.badge.review",
                    defaultValue: "Perlu pemeriksaan"
                ),
                kind: .warning
            )
        } else if item.evidenceStatus == .rejected {
            activityBadge(
                String(
                    localized: "status.rejected",
                    defaultValue: "Ditolak"
                ),
                kind: .error
            )
        } else if let points = item.points {
            activityBadge(
                String(
                    format: String(
                        localized: "coach.activity.badge.points_format",
                        defaultValue: "%@ poin"
                    ),
                    CoachFormatting.number(points)
                ),
                kind: .warning
            )
        }
    }

    private func activityBadge(
        _ title: String,
        kind: AppStatusKind
    ) -> some View {
        let style = AppStatusStyle.style(for: kind)
        return Text(title)
            .font(AppTypography.label.monospacedDigit())
            .foregroundStyle(style.foregroundColor)
            .padding(.horizontal, AppSpacing.small)
            .padding(.vertical, AppSpacing.xSmall)
            .background(style.backgroundColor, in: Capsule())
            .fixedSize(horizontal: false, vertical: true)
    }

    private var activityDescription: String {
        switch item.kind {
        case .evidenceSubmitted:
            return String(
                format: String(
                    localized: "coach.activity.message.evidence_format",
                    defaultValue: "Mengirim bukti untuk %@"
                ),
                item.stepTitle ?? item.programTitle
            )
        case .stepCompleted:
            return String(
                format: String(
                    localized: "coach.activity.message.step_format",
                    defaultValue: "Menyelesaikan langkah %@"
                ),
                item.stepTitle ?? item.programTitle
            )
        case .participantJoined:
            return String(
                format: String(
                    localized: "coach.activity.message.joined_format",
                    defaultValue: "Bergabung ke program %@"
                ),
                item.programTitle
            )
        case .programCompleted:
            return String(
                format: String(
                    localized: "coach.activity.message.completed_format",
                    defaultValue: "Menyelesaikan program %@"
                ),
                item.programTitle
            )
        }
    }

    private var activityTime: String {
        item.occurredAt.formatted(
            .relative(
                presentation: .numeric,
                unitsStyle: .wide
            )
            .locale(CoachFormatting.locale)
        )
    }

    private var activityIcon: String {
        switch item.kind {
        case .evidenceSubmitted:
            "doc.text"
        case .stepCompleted:
            "figure.run"
        case .participantJoined:
            "person.badge.plus"
        case .programCompleted:
            "checkmark.seal"
        }
    }

    private var activityColor: Color {
        switch item.kind {
        case .evidenceSubmitted:
            item.requiresReview ? .appWarning : .appDestructive
        case .stepCompleted, .participantJoined:
            .appSuccess
        case .programCompleted:
            .appSuccess
        }
    }
}

private struct CoachActivityFilterDraft: Identifiable {
    let id = UUID()
    var programID: UUID?
    var kind: CoachActivityKindFilter
    var timeRange: CoachActivityTimeRange
}

private struct CoachActivityFilterSheet: View {
    @Environment(\.dismiss) private var dismiss

    let programs: [Program]
    let referenceDate: Date
    let onApply: (CoachActivityFilterDraft) -> Void

    @State private var draft: CoachActivityFilterDraft

    init(
        draft: CoachActivityFilterDraft,
        programs: [Program],
        referenceDate: Date,
        onApply: @escaping (CoachActivityFilterDraft) -> Void
    ) {
        self.programs = programs
        self.referenceDate = referenceDate
        self.onApply = onApply
        _draft = State(initialValue: draft)
    }

    var body: some View {
        NavigationStack {
            Form {
                ProgramFilterSection(
                    programs: programs,
                    referenceDate: referenceDate,
                    sectionTitle: "coach.filter.program",
                    allProgramsTitle: "coach.filter.all_programs",
                    optionIdentifierPrefix:
                        "coach.activity.filter.option.program",
                    selection: $draft.programID
                )

                Section("coach.activity.filter.kind") {
                    Picker(
                        "coach.activity.filter.kind",
                        selection: $draft.kind
                    ) {
                        ForEach(CoachActivityKindFilter.allCases) { kind in
                            Text(verbatim: kindFilterTitle(kind))
                                .tag(kind)
                                .accessibilityIdentifier(
                                    "coach.activity.filter.option.kind.\(kind.rawValue)"
                                )
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("coach.activity.filter.time") {
                    Picker(
                        "coach.activity.filter.time",
                        selection: $draft.timeRange
                    ) {
                        ForEach(CoachActivityTimeRange.allCases) { range in
                            Text(verbatim: timeRangeTitle(range))
                                .tag(range)
                                .accessibilityIdentifier(
                                    "coach.activity.filter.option.time.\(range.rawValue)"
                                )
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle(Text("coach.activity.filter.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.close") {
                        dismiss()
                    }
                    .foregroundStyle(Color.brandPrimary)
                    .accessibilityIdentifier("coach.activity.filter.close")
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                FilterSheetActionBar(
                    resetTitle: "coach.activity.filter.reset",
                    applyTitle: "coach.activity.filter.apply",
                    resetIdentifier: "coach.activity.filter.reset",
                    applyIdentifier: "coach.activity.filter.apply"
                ) {
                    draft.programID = nil
                    draft.kind = .all
                    draft.timeRange = .today
                } onApply: {
                    onApply(draft)
                    dismiss()
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier("coach.activity.filter.sheet")
    }
}

private func kindFilterTitle(_ kind: CoachActivityKindFilter) -> String {
    switch kind {
    case .all:
        String(
            localized: "coach.activity.filter.kind.all",
            defaultValue: "Semua aktivitas"
        )
    case .evidenceSubmitted:
        String(
            localized: "coach.activity.filter.kind.evidence",
            defaultValue: "Bukti dikirim"
        )
    case .stepCompleted:
        String(
            localized: "coach.activity.filter.kind.step",
            defaultValue: "Langkah selesai"
        )
    case .participantJoined:
        String(
            localized: "coach.activity.filter.kind.joined",
            defaultValue: "Peserta bergabung"
        )
    case .programCompleted:
        String(
            localized: "coach.activity.filter.kind.completed",
            defaultValue: "Program selesai"
        )
    }
}

private func timeRangeTitle(_ range: CoachActivityTimeRange) -> String {
    switch range {
    case .today:
        String(
            localized: "coach.activity.filter.time.today",
            defaultValue: "Hari ini"
        )
    case .lastSevenDays:
        String(
            localized: "coach.activity.filter.time.seven_days",
            defaultValue: "7 hari terakhir"
        )
    case .lastThirtyDays:
        String(
            localized: "coach.activity.filter.time.thirty_days",
            defaultValue: "30 hari terakhir"
        )
    }
}

#Preview("Aktivitas Coach — hari ini") {
    @Previewable @State var state = CoachActivityState(
        environment: .preview
    )
    @Previewable @State var router = ShellTabRouter()

    NavigationStack {
        CoachActivityView(state: state, router: router)
    }
    .environment(\.locale, Locale(identifier: "id-ID"))
    .preferredColorScheme(.dark)
}
