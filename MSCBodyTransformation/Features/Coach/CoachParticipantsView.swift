import SwiftUI

@MainActor
struct CoachParticipantsView: View {
    let state: CoachParticipantsState
    let router: ShellTabRouter
    let destination: CoachParticipantsDestination

    @State private var presentedFilter: CoachParticipantFilterDraft?
    @State private var attentionSort: CoachAttentionSort = .priority

    init(
        state: CoachParticipantsState,
        router: ShellTabRouter,
        destination: CoachParticipantsDestination = .all
    ) {
        self.state = state
        self.router = router
        self.destination = destination
    }

    var body: some View {
        @Bindable var state = state

        VStack(spacing: 0) {
            controls(query: $state.query)
                .padding(.horizontal, AppSpacing.medium)
                .padding(.bottom, AppSpacing.medium)

            Divider()

            participantContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.large)
        .task(id: destination) {
            state.prepare(for: destination)
            if state.state == .idle {
                await state.load()
            }
        }
        .sheet(item: $presentedFilter) { draft in
            CoachParticipantFilterSheet(
                draft: draft,
                programs: state.availablePrograms
            ) { selection in
                state.selectedProgramID = selection.programID
                state.completionFilter = selection.completion
                state.reviewFilter = .all
                state.sort = selection.sort
            }
        }
        .accessibilityIdentifier("coach.participants")
    }

    private var navigationTitle: LocalizedStringKey {
        switch destination {
        case .all:
            "coach.participants.navigation.all"
        case .needsAttention:
            "coach.participants.navigation.attention"
        case .program:
            "coach.participants.navigation.program"
        }
    }

    @ViewBuilder
    private func controls(query: Binding<String>) -> some View {
        switch destination {
        case .needsAttention:
            attentionControls
        case .all, .program:
            directoryControls(query: query)
        }
    }

    private func directoryControls(query: Binding<String>) -> some View {
        VStack(spacing: AppSpacing.medium) {
            participantSummary

            HStack(spacing: AppSpacing.small) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.appSecondaryText)
                    .accessibilityHidden(true)

                TextField(
                    String(
                        localized: "coach.participants.search",
                        defaultValue: "Cari nama atau kota"
                    ),
                    text: query
                )
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()

                if !query.wrappedValue.isEmpty {
                    Button {
                        query.wrappedValue = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.appSecondaryText)
                    }
                    .accessibilityLabel(Text("action.clear"))
                }
            }
            .padding(.horizontal, AppSpacing.medium)
            .frame(minHeight: 50)
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
            .accessibilityIdentifier("coach.participants.search")

            Button {
                presentedFilter = CoachParticipantFilterDraft(
                    programID: state.selectedProgramID,
                    completion: state.completionFilter,
                    sort: state.sort
                )
            } label: {
                HStack(spacing: AppSpacing.medium) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title3)
                        .foregroundStyle(Color.appPrimaryText)
                        .frame(width: 32)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                        Text("coach.participants.filter.action")
                            .font(AppTypography.cardTitle)
                            .foregroundStyle(Color.appPrimaryText)

                        Text(filterSummary)
                            .font(AppTypography.secondary)
                            .foregroundStyle(Color.appSecondaryText)
                            .lineLimit(2)
                    }

                    Spacer(minLength: AppSpacing.small)

                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appSecondaryText)
                        .accessibilityHidden(true)
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
                .contentShape(
                    RoundedRectangle(
                        cornerRadius: AppRadius.large,
                        style: .continuous
                    )
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("coach.participants.filter")
        }
    }

    private var participantSummary: some View {
        HStack(spacing: 0) {
            CoachParticipantSummaryMetric(
                value: scopedParticipants.count,
                title: "coach.participants.summary.total",
                systemImage: "person.2.fill",
                color: .appPrimaryText
            )

            Divider()
                .padding(.vertical, AppSpacing.small)

            Button {
                guard destination != .needsAttention else {
                    return
                }
                router.navigate(
                    to: .coach(.participants(.needsAttention)),
                    in: .coach(.dashboard)
                )
            } label: {
                CoachParticipantSummaryMetric(
                    value: scopedParticipants.filter(\.isFallingBehind).count,
                    title: "coach.participants.summary.attention",
                    systemImage: "exclamationmark.circle.fill",
                    color: .brandPrimary
                )
            }
            .buttonStyle(.plain)
            .accessibilityHint(
                Text("coach.participants.summary.attention.hint")
            )
        }
        .padding(.vertical, AppSpacing.xSmall)
        .fixedSize(horizontal: false, vertical: true)
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

    private var scopedParticipants: [CoachParticipantSummary] {
        switch destination {
        case .all, .needsAttention:
            state.participants
        case .program(let programID):
            state.participants.filter { $0.program?.id == programID }
        }
    }

    private var filterSummary: String {
        let program = state.availablePrograms.first {
            $0.id == state.selectedProgramID
        }?.title ?? String(
            localized: "coach.filter.all_programs",
            defaultValue: "Semua program"
        )
        let completion = completionFilterTitle
        let sort = participantSortTitle

        if state.completionFilter == .all {
            return "\(program) · \(sort)"
        }
        return "\(program) · \(completion) · \(sort)"
    }

    private var completionFilterTitle: String {
        switch state.completionFilter {
        case .all:
            String(
                localized: "coach.filter.completion.all",
                defaultValue: "Semua status"
            )
        case .inProgress:
            String(
                localized: "coach.filter.completion.in_progress",
                defaultValue: "Sedang berjalan"
            )
        case .complete:
            String(
                localized: "coach.filter.completion.complete",
                defaultValue: "Selesai"
            )
        case .fallingBehind:
            String(
                localized: "coach.filter.completion.falling_behind",
                defaultValue: "Perlu perhatian"
            )
        }
    }

    private var participantSortTitle: String {
        switch state.sort {
        case .progress:
            String(
                localized: "coach.sort.progress",
                defaultValue: "Kemajuan"
            )
        case .points:
            String(
                localized: "coach.sort.points",
                defaultValue: "Poin"
            )
        case .lastActivity:
            String(
                localized: "coach.sort.last_activity",
                defaultValue: "Aktivitas terakhir"
            )
        }
    }

    private var attentionControls: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(
                String(
                    format: String(
                        localized:
                            "coach.participants.attention.count_format",
                        defaultValue:
                            "%@ peserta perlu ditindaklanjuti"
                    ),
                    CoachFormatting.number(
                        state.filteredParticipants.count
                    )
                )
            )
            .font(AppTypography.secondary)
            .foregroundStyle(Color.appSecondaryText)

            Label {
                Text("coach.participants.attention.explanation")
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appPrimaryText)
            } icon: {
                Image(systemName: "info.circle")
                    .font(.title3)
                    .foregroundStyle(Color.brandPrimary)
            }
            .padding(AppSpacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color.brandPrimary.opacity(0.06),
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
                .stroke(Color.brandPrimary.opacity(0.18), lineWidth: 1)
            }

            Menu {
                ForEach(CoachAttentionSort.allCases) { sort in
                    Button {
                        attentionSort = sort
                    } label: {
                        if attentionSort == sort {
                            Label(
                                sort.title,
                                systemImage: "checkmark"
                            )
                        } else {
                            Text(sort.title)
                        }
                    }
                }
            } label: {
                HStack(spacing: AppSpacing.medium) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.title3)
                        .foregroundStyle(Color.appSecondaryText)
                        .frame(width: 32)
                        .accessibilityHidden(true)

                    Text("coach.participants.attention.sort")
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(Color.appPrimaryText)

                    Spacer()

                    Text(attentionSort.title)
                        .font(AppTypography.secondary)
                        .foregroundStyle(Color.appSecondaryText)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.brandPrimary)
                        .accessibilityHidden(true)
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
                .contentShape(
                    RoundedRectangle(
                        cornerRadius: AppRadius.large,
                        style: .continuous
                    )
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                Text("coach.participants.navigation.attention")
            )
            .accessibilityValue(Text(attentionSort.title))
            .accessibilityIdentifier(
                "coach.participants.filter.completion"
            )
        }
    }

    @ViewBuilder
    private var participantContent: some View {
        switch state.state {
        case .idle, .loading:
            ScrollView {
                LazyVStack(spacing: AppSpacing.medium) {
                    ForEach(0..<3, id: \.self) { _ in
                        CoachParticipantPlaceholderCard()
                    }
                }
                .padding(AppSpacing.medium)
            }
            .redacted(reason: .placeholder)
        case .failed(let error):
            ScrollView {
                ErrorStateView(error: error) {
                    Task {
                        await state.load()
                    }
                }
                .padding(AppSpacing.medium)
            }
        case .loaded:
            if displayedParticipants.isEmpty {
                ContentUnavailableView(
                    "coach.participants.filtered_empty.title",
                    systemImage: destination == .needsAttention
                        ? "checkmark.circle"
                        : "person.2.slash",
                    description: Text(emptyMessageKey)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(AppSpacing.large)
            } else {
                ScrollView {
                    LazyVStack(spacing: AppSpacing.medium) {
                        ForEach(displayedParticipants) { participant in
                            participantCard(participant)
                        }

                        if destination == .needsAttention {
                            Text(
                                "coach.participants.attention.footer"
                            )
                            .font(AppTypography.label)
                            .foregroundStyle(Color.appSecondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, AppSpacing.small)
                        }
                    }
                    .padding(AppSpacing.medium)
                    .padding(.bottom, AppSpacing.large)
                }
                .refreshable {
                    await state.load()
                }
            }
        }
    }

    private var emptyMessageKey: LocalizedStringKey {
        destination == .needsAttention
            ? "coach.participants.attention.empty"
            : "coach.participants.filtered_empty.message"
    }

    private var displayedParticipants: [CoachParticipantSummary] {
        guard destination == .needsAttention else {
            return state.filteredParticipants
        }

        switch attentionSort {
        case .priority:
            return state.filteredParticipants.sorted {
                if $0.progressPercentage == $1.progressPercentage {
                    return $0.lastActivityAt < $1.lastActivityAt
                }
                return $0.progressPercentage < $1.progressPercentage
            }
        case .lastActivity:
            return state.filteredParticipants.sorted {
                $0.lastActivityAt < $1.lastActivityAt
            }
        case .name:
            return state.filteredParticipants.sorted {
                $0.profile.displayName.localizedStandardCompare(
                    $1.profile.displayName
                ) == .orderedAscending
            }
        }
    }

    @ViewBuilder
    private func participantCard(
        _ participant: CoachParticipantSummary
    ) -> some View {
        Button {
            router.navigate(
                to: .coach(.participantDetail(participant.id)),
                in: .coach(.dashboard)
            )
        } label: {
            if destination == .needsAttention {
                CoachAttentionParticipantCard(summary: participant)
            } else {
                CoachDirectoryParticipantCard(summary: participant)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(
            "coach.participant.open.\(participant.id)"
        )
    }
}

private struct CoachParticipantSummaryMetric: View {
    let value: Int
    let title: LocalizedStringKey
    let systemImage: String
    let color: Color

    var body: some View {
        HStack(spacing: AppSpacing.xSmall) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.08), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                Text(
                    value,
                    format: .number.locale(CoachFormatting.locale)
                )
                .font(AppTypography.sectionTitle.monospacedDigit())
                .foregroundStyle(Color.appPrimaryText)

                Text(title)
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppSpacing.small)
        .accessibilityElement(children: .combine)
    }
}

private struct CoachDirectoryParticipantCard: View {
    let summary: CoachParticipantSummary

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.medium) {
            UserAvatar(
                displayName: summary.profile.displayName,
                imageName: summary.profile.localPhotoReference,
                size: 64
            )

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                HStack(alignment: .firstTextBaseline) {
                    Text(summary.profile.displayName)
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(Color.appPrimaryText)

                    Spacer(minLength: AppSpacing.small)

                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appSecondaryText)
                        .accessibilityHidden(true)
                }

                Text(
                    summary.program?.title
                        ?? String(
                            localized: "coach.program.none",
                            defaultValue: "Belum ada program"
                        )
                )
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appSecondaryText)

                HStack(spacing: AppSpacing.small) {
                    ProgressView(
                        value: Double(summary.progressPercentage),
                        total: 100
                    )
                    .tint(Color.brandPrimary)

                    Text(
                        CoachFormatting.percentage(
                            summary.progressPercentage
                        )
                    )
                    .font(AppTypography.label.monospacedDigit())
                    .foregroundStyle(Color.appPrimaryText)
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AppSpacing.small) {
                        activityLabel
                        if summary.isFallingBehind {
                            attentionBadge
                        }
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                        activityLabel
                        if summary.isFallingBehind {
                            attentionBadge
                        }
                    }
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
        .contentShape(
            RoundedRectangle(
                cornerRadius: AppRadius.large,
                style: .continuous
            )
        )
        .accessibilityElement(children: .combine)
    }

    private var activityLabel: some View {
        Label {
            Text(CoachFormatting.relativeActivity(summary.lastActivityAt))
        } icon: {
            Image(systemName: "circle.fill")
                .font(.system(size: 7))
                .foregroundStyle(activityColor)
        }
        .font(AppTypography.secondary)
        .foregroundStyle(Color.appSecondaryText)
    }

    private var activityColor: Color {
        summary.progressPercentage == 0 ? .appSecondaryText : .appSuccess
    }

    private var attentionBadge: some View {
        Label(
            "coach.status.falling_behind",
            systemImage: "exclamationmark.circle.fill"
        )
        .font(AppTypography.label)
        .foregroundStyle(Color.appDestructive)
        .padding(.horizontal, AppSpacing.xSmall)
        .padding(.vertical, AppSpacing.xxSmall)
        .background(
            Color.appDestructive.opacity(0.1),
            in: RoundedRectangle(
                cornerRadius: AppRadius.small,
                style: .continuous
            )
        )
    }
}

private struct CoachAttentionParticipantCard: View {
    let summary: CoachParticipantSummary

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack(alignment: .top, spacing: AppSpacing.medium) {
                UserAvatar(
                    displayName: summary.profile.displayName,
                    imageName: summary.profile.localPhotoReference,
                    size: 64
                )

                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    Text(summary.profile.displayName)
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(Color.appPrimaryText)

                    Text(
                        summary.program?.title
                            ?? String(
                                localized: "coach.program.none",
                                defaultValue: "Belum ada program"
                            )
                    )
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)

                    attentionStatus
                }

                Spacer(minLength: AppSpacing.small)

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appSecondaryText)
                    .accessibilityHidden(true)
            }

            Divider()

            Label {
                VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                    Text(attentionTitle)
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(Color.appPrimaryText)

                    Text(attentionMessage)
                        .font(AppTypography.secondary)
                        .foregroundStyle(Color.appSecondaryText)
                }
            } icon: {
                Image(systemName: attentionSystemImage)
                    .font(.title3)
                    .foregroundStyle(attentionColor)
            }

            Text("coach.participants.attention.open")
                .font(AppTypography.button)
                .foregroundStyle(Color.brandPrimary)
                .padding(.horizontal, AppSpacing.medium)
                .frame(minHeight: 44)
                .overlay {
                    RoundedRectangle(
                        cornerRadius: AppRadius.medium,
                        style: .continuous
                    )
                    .stroke(Color.brandPrimary, lineWidth: 1)
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
        .contentShape(
            RoundedRectangle(
                cornerRadius: AppRadius.large,
                style: .continuous
            )
        )
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var attentionStatus: some View {
        if summary.progressPercentage == 0 {
            Text("coach.participants.attention.not_started")
                .font(AppTypography.label)
                .foregroundStyle(Color.appDestructive)
                .padding(.horizontal, AppSpacing.xSmall)
                .padding(.vertical, AppSpacing.xxSmall)
                .background(
                    Color.appDestructive.opacity(0.1),
                    in: RoundedRectangle(
                        cornerRadius: AppRadius.small,
                        style: .continuous
                    )
                )
        } else {
            Text("coach.participants.attention.behind")
                .font(AppTypography.label)
                .foregroundStyle(Color.appWarning)
                .padding(.horizontal, AppSpacing.xSmall)
                .padding(.vertical, AppSpacing.xxSmall)
                .background(
                    Color.brandAccent.opacity(0.18),
                    in: RoundedRectangle(
                        cornerRadius: AppRadius.small,
                        style: .continuous
                    )
                )
        }
    }

    private var attentionTitle: String {
        if summary.progressPercentage == 0 {
            return String(
                localized:
                    "coach.participants.attention.not_started.title",
                defaultValue: "Belum ada progres"
            )
        }
        return String(
            format: String(
                localized:
                    "coach.participants.attention.missing_steps_format",
                defaultValue: "%@ langkah belum selesai"
            ),
            CoachFormatting.number(summary.missingStepCount)
        )
    }

    private var attentionMessage: String {
        if summary.progressPercentage == 0 {
            return String(
                localized:
                    "coach.participants.attention.not_started.message",
                defaultValue:
                    "Belum ada langkah yang diselesaikan."
            )
        }
        return String(
            format: String(
                localized:
                    "coach.participants.attention.last_activity_format",
                defaultValue: "Aktivitas terakhir %@"
            ),
            CoachFormatting.relativeDate(summary.lastActivityAt)
        )
    }

    private var attentionSystemImage: String {
        summary.progressPercentage == 0
            ? "clock.badge.exclamationmark"
            : "exclamationmark.triangle"
    }

    private var attentionColor: Color {
        summary.progressPercentage == 0
            ? .appDestructive
            : .appWarning
    }
}

private struct CoachParticipantPlaceholderCard: View {
    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            UserAvatar(displayName: "Peserta", size: 64)
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text("Nama peserta")
                Text("Program aktif")
                ProgressView(value: 0.2)
            }
            Spacer()
        }
        .padding(AppSpacing.medium)
        .background(
            Color.appSurface,
            in: RoundedRectangle(
                cornerRadius: AppRadius.large,
                style: .continuous
            )
        )
    }
}

private struct CoachParticipantFilterDraft: Identifiable {
    let id = UUID()
    var programID: UUID?
    var completion: CoachCompletionFilter
    var sort: CoachParticipantSort
}

private struct CoachParticipantFilterSheet: View {
    @Environment(\.dismiss) private var dismiss

    let programs: [Program]
    let onApply: (CoachParticipantFilterDraft) -> Void

    @State private var draft: CoachParticipantFilterDraft

    init(
        draft: CoachParticipantFilterDraft,
        programs: [Program],
        onApply: @escaping (CoachParticipantFilterDraft) -> Void
    ) {
        self.programs = programs
        self.onApply = onApply
        _draft = State(initialValue: draft)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("coach.filter.program") {
                    Picker(
                        "coach.filter.program",
                        selection: $draft.programID
                    ) {
                        Text("coach.filter.all_programs")
                            .tag(UUID?.none)
                        ForEach(programs) { program in
                            Text(program.title)
                                .tag(Optional(program.id))
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("coach.filter.completion") {
                    Picker(
                        "coach.filter.completion",
                        selection: $draft.completion
                    ) {
                        ForEach(CoachCompletionFilter.allCases) { filter in
                            Text(LocalizedStringKey(filter.titleKey))
                                .tag(filter)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("coach.sort.label") {
                    Picker(
                        "coach.sort.label",
                        selection: $draft.sort
                    ) {
                        ForEach(CoachParticipantSort.allCases) { sort in
                            Text(LocalizedStringKey(sort.titleKey))
                                .tag(sort)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle(
                Text("coach.participants.filter.navigation_title")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.close") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: AppSpacing.small) {
                    Button {
                        draft.programID = nil
                        draft.completion = .all
                        draft.sort = .progress
                    } label: {
                        Text("coach.participants.filter.reset")
                            .font(AppTypography.button)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .foregroundStyle(Color.brandPrimary)
                            .overlay {
                                RoundedRectangle(
                                    cornerRadius: AppRadius.medium,
                                    style: .continuous
                                )
                                .stroke(Color.brandPrimary, lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)

                    Button {
                        onApply(draft)
                        dismiss()
                    } label: {
                        Text("coach.participants.filter.apply")
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                }
                .padding(AppSpacing.medium)
                .background(.bar)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier("coach.participants.filter.sheet")
    }
}

private enum CoachAttentionSort:
    String,
    CaseIterable,
    Identifiable
{
    case priority
    case lastActivity = "last_activity"
    case name

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .priority:
            "coach.participants.attention.sort.priority"
        case .lastActivity:
            "coach.participants.attention.sort.last_activity"
        case .name:
            "coach.participants.attention.sort.name"
        }
    }
}

#Preview("Peserta Coach — normal") {
    NavigationStack {
        CoachParticipantsPreview(destination: .all)
    }
    .environment(\.locale, Locale(identifier: "id-ID"))
}

#Preview("Peserta Coach — perlu perhatian") {
    NavigationStack {
        CoachParticipantsPreview(destination: .needsAttention)
    }
    .environment(\.locale, Locale(identifier: "id-ID"))
}

@MainActor
private struct CoachParticipantsPreview: View {
    let destination: CoachParticipantsDestination

    @State private var state = CoachParticipantsState(environment: .preview)
    @State private var router = ShellTabRouter()

    var body: some View {
        CoachParticipantsView(
            state: state,
            router: router,
            destination: destination
        )
    }
}
