import SwiftUI

@MainActor
struct ParticipantHomeView: View {
    let store: ParticipantJourneyStore
    let router: ShellTabRouter

    var body: some View {
        if store.entryStage != .complete {
            ParticipantEntryFlowView(store: store)
        } else if let snapshot = store.snapshot {
            ScrollView {
                LazyVStack(spacing: AppSpacing.xLarge) {
                    profileCard(snapshot)
                    programSection(snapshot)
                    focusSection(snapshot)
                    leaderboardSection(snapshot)
                }
                .frame(maxWidth: 760)
                .padding(.vertical, AppSpacing.small)
                .frame(maxWidth: .infinity)
            }
            .background(Color.appBackground)
            .accessibilityIdentifier("participant.home")
        } else {
            EmptyStateView(
                title: "participant.today.empty.title",
                message: "participant.today.empty.message",
                systemImage: "house"
            )
        }
    }

    private func profileCard(
        _ snapshot: ParticipantJourneySnapshot
    ) -> some View {
        Button {
            router.navigate(
                to: .participant(.profile),
                in: .participant(.today)
            )
        } label: {
            HStack(spacing: AppSpacing.medium) {
                UserAvatar(
                    displayName: snapshot.profile.displayName,
                    size: 64
                )

                VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                    Text("participant.home.greeting")
                        .font(AppTypography.secondary)
                        .foregroundStyle(Color.appSecondaryText)

                    Text(snapshot.profile.displayName)
                        .font(AppTypography.sectionTitle)
                        .foregroundStyle(Color.appPrimaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(roleTitle(snapshot.user.role))
                        .font(AppTypography.label)
                        .foregroundStyle(Color.brandPrimary)
                        .padding(.horizontal, AppSpacing.xSmall)
                        .padding(.vertical, AppSpacing.xxSmall)
                        .background(
                            Color.brandPrimary.opacity(0.1),
                            in: Capsule()
                        )
                }

                Spacer(minLength: AppSpacing.xSmall)

                Image(systemName: "chevron.right")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.brandPrimary)
                    .frame(width: 44, height: 44)
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
        .padding(.horizontal, AppSpacing.medium)
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("participant.home.profile.hint"))
        .accessibilityIdentifier("participant.home.profile")
    }

    @ViewBuilder
    private func programSection(
        _ snapshot: ParticipantJourneySnapshot
    ) -> some View {
        let programs = availablePrograms(snapshot)

        VStack(alignment: .leading, spacing: AppSpacing.small) {
            ParticipantHomeSectionHeader(title: "participant.home.program.title")
                .padding(.horizontal, AppSpacing.medium)

            if programs.isEmpty {
                ContentUnavailableView {
                    Label(
                        "participant.home.program.empty.title",
                        systemImage: "rectangle.stack"
                    )
                } description: {
                    Text("participant.home.program.empty.message")
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, AppSpacing.medium)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: AppSpacing.medium) {
                        ForEach(programs) { program in
                            Button {
                                openProgram(program)
                            } label: {
                                ParticipantProgramPoster(program: program)
                            }
                            .buttonStyle(.plain)
                            .containerRelativeFrame(.horizontal) {
                                availableWidth,
                                _ in
                                carouselCardWidth(
                                    availableWidth: availableWidth,
                                    itemCount: programs.count
                                )
                            }
                            .accessibilityIdentifier(
                                "participant.home.program.\(program.id)"
                            )
                        }
                    }
                    .scrollTargetLayout()
                }
                .contentMargins(
                    .horizontal,
                    AppSpacing.medium,
                    for: .scrollContent
                )
                .scrollTargetBehavior(.viewAligned)
            }
        }
    }

    @ViewBuilder
    private func focusSection(
        _ snapshot: ParticipantJourneySnapshot
    ) -> some View {
        let programs = focusPrograms(snapshot)

        VStack(alignment: .leading, spacing: AppSpacing.small) {
            ParticipantHomeSectionHeader(title: "participant.home.focus.title")
                .padding(.horizontal, AppSpacing.medium)

            if programs.isEmpty {
                ContentUnavailableView {
                    Label(
                        "participant.home.focus.empty.title",
                        systemImage: "checklist"
                    )
                } description: {
                    Text("participant.home.focus.empty.message")
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, AppSpacing.medium)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: AppSpacing.medium) {
                        ForEach(programs) { program in
                            focusCard(program, snapshot: snapshot)
                                .containerRelativeFrame(.horizontal) {
                                    availableWidth,
                                    _ in
                                    carouselCardWidth(
                                        availableWidth: availableWidth,
                                        itemCount: programs.count
                                    )
                                }
                        }
                    }
                    .scrollTargetLayout()
                }
                .contentMargins(
                    .horizontal,
                    AppSpacing.medium,
                    for: .scrollContent
                )
                .scrollTargetBehavior(.viewAligned)
            }
        }
    }

    private func focusCard(
        _ program: Program,
        snapshot: ParticipantJourneySnapshot
    ) -> some View {
        let day = focusDay(for: program)
        let completedStepCount = completedStepCount(
            for: day,
            program: program,
            snapshot: snapshot
        )
        let totalStepCount = day?.steps.count ?? 0
        let action = focusAction(
            for: program,
            day: day,
            snapshot: snapshot
        )

        return ParticipantHomeFocusCard(
            programTitle: program.title,
            dayTitle: day?.title,
            completedStepCount: completedStepCount,
            totalStepCount: totalStepCount,
            actionTitle: action.title,
            actionSystemImage: action.systemImage,
            actionAccessibilityIdentifier:
                action.accessibilityIdentifier
        ) {
            perform(action)
        }
    }

    @ViewBuilder
    private func leaderboardSection(
        _ snapshot: ParticipantJourneySnapshot
    ) -> some View {
        if store.currentEnrollment != nil {
            let entries = Array(
                snapshot.leaderboard
                    .sorted {
                        if $0.rank == $1.rank {
                            return $0.participantDisplayName
                                < $1.participantDisplayName
                        }
                        return $0.rank < $1.rank
                    }
                    .prefix(5)
            )

            if !entries.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    ParticipantHomeSectionHeader(
                        title: "participant.home.leaderboard.title",
                        actionTitle: "participant.home.view_all"
                    ) {
                        router.navigate(
                            to: .participant(.leaderboard),
                            in: .participant(.today)
                        )
                    }
                    .padding(.horizontal, AppSpacing.medium)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(
                            alignment: .top,
                            spacing: AppSpacing.medium
                        ) {
                            ForEach(entries) { entry in
                                ParticipantHomeLeaderboardItem(entry: entry)
                            }
                        }
                    }
                    .contentMargins(
                        .horizontal,
                        AppSpacing.medium,
                        for: .scrollContent
                    )
                }
            }
        }
    }

    private func carouselCardWidth(
        availableWidth: CGFloat,
        itemCount: Int
    ) -> CGFloat {
        guard itemCount > 1 else {
            return max(availableWidth, 1)
        }
        return min(
            max(availableWidth - AppSpacing.xLarge, 1),
            560
        )
    }

    private func roleTitle(_ role: UserRole) -> LocalizedStringKey {
        switch role {
        case .participant:
            "participant.home.role.participant"
        case .coach:
            "participant.home.role.coach"
        case .admin:
            "participant.home.role.admin"
        }
    }

    private func availablePrograms(
        _ snapshot: ParticipantJourneySnapshot
    ) -> [Program] {
        snapshot.programs
            .filter { program in
                program.status == .active || program.status == .scheduled
            }
            .sorted { lhs, rhs in
                if lhs.status == rhs.status {
                    return lhs.startDate < rhs.startDate
                }
                return lhs.status == .active
            }
    }

    private func focusPrograms(
        _ snapshot: ParticipantJourneySnapshot
    ) -> [Program] {
        guard store.currentEnrollment != nil else {
            return []
        }
        let activeProgramIDs = Set(
            snapshot.enrollments
                .filter { $0.status == .active }
                .map(\.programID)
        )
        return snapshot.programs
            .filter {
                $0.status == .active && activeProgramIDs.contains($0.id)
            }
            .sorted { $0.startDate < $1.startDate }
    }

    private func focusDay(for program: Program) -> ProgramDay? {
        if program.id == store.currentProgram?.id {
            return store.todayDay
        }
        return ProgramDayResolver().activeDay(
            in: program,
            at: store.effectiveDate
        )
    }

    private func completedStepCount(
        for day: ProgramDay?,
        program: Program,
        snapshot: ParticipantJourneySnapshot
    ) -> Int {
        guard program.id == store.currentProgram?.id,
              let day else {
            return 0
        }
        let submittedStepIDs = Set(
            snapshot.submissions
                .filter { $0.status != .rejected }
                .map(\.stepID)
        )
        return day.steps.filter {
            submittedStepIDs.contains($0.id)
        }.count
    }

    private func focusAction(
        for program: Program,
        day: ProgramDay?,
        snapshot: ParticipantJourneySnapshot
    ) -> ParticipantHomeFocusAction {
        guard program.id == store.currentProgram?.id else {
            return .program(program.id)
        }
        if store.initialWeighIn == nil {
            return .weighIn(.initial)
        }
        if isLastProgramDay(day, in: program), store.finalWeighIn == nil {
            return .weighIn(.final)
        }
        guard let day,
              store.access(for: day) == .available else {
            return .program(program.id)
        }

        let submittedStepIDs = Set(
            snapshot.submissions
                .filter { $0.status != .rejected }
                .map(\.stepID)
        )
        if let step = day.steps
            .sorted(by: { $0.order < $1.order })
            .first(where: { !submittedStepIDs.contains($0.id) }) {
            return .step(step)
        }
        return .program(program.id)
    }

    private func isLastProgramDay(
        _ day: ProgramDay?,
        in program: Program
    ) -> Bool {
        guard let day,
              let lastDayNumber = program.days.map(\.dayNumber).max() else {
            return false
        }
        return day.dayNumber == lastDayNumber
    }

    private func openProgram(_ program: Program) {
        router.navigate(
            to: .participant(.programDetail(program.id, .today)),
            in: .participant(.today)
        )
    }

    private func perform(_ action: ParticipantHomeFocusAction) {
        switch action {
        case .step(let step):
            router.navigate(
                to: .participant(.stepDetail(step.id)),
                in: .participant(.today)
            )
        case .weighIn(let type):
            router.navigate(
                to: .participant(.weighIn(type)),
                in: .participant(.today)
            )
        case .program(let programID):
            router.navigate(
                to: .participant(.programDetail(programID, .today)),
                in: .participant(.today)
            )
        }
    }
}

private struct ParticipantHomeSectionHeader: View {
    let title: LocalizedStringKey
    let actionTitle: LocalizedStringKey?
    let action: (() -> Void)?

    init(
        title: LocalizedStringKey,
        actionTitle: LocalizedStringKey? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.small) {
            Text(title)
                .font(AppTypography.sectionTitle)
                .foregroundStyle(Color.appPrimaryText)
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: AppSpacing.small)

            if let actionTitle, let action {
                Button(action: action) {
                    HStack(spacing: AppSpacing.xxSmall) {
                        Text(actionTitle)
                        Image(systemName: "chevron.right")
                            .accessibilityHidden(true)
                    }
                    .font(AppTypography.secondary.weight(.semibold))
                    .foregroundStyle(Color.brandPrimary)
                    .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct ParticipantHomeFocusCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let programTitle: String
    let dayTitle: String?
    let completedStepCount: Int
    let totalStepCount: Int
    let actionTitle: LocalizedStringKey
    let actionSystemImage: String
    let actionAccessibilityIdentifier: String?
    let action: () -> Void

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    programDescription
                    progress
                    actionButton
                }
            } else {
                HStack(spacing: AppSpacing.large) {
                    progress
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        programDescription
                        actionButton
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
    }

    private var programDescription: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
            Text(programTitle)
                .font(AppTypography.cardTitle)
                .foregroundStyle(Color.appPrimaryText)
                .fixedSize(horizontal: false, vertical: true)

            if let dayTitle {
                Text(dayTitle)
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var progress: some View {
        ParticipantHomeProgressRing(
            completed: completedStepCount,
            total: totalStepCount
        )
    }

    private var actionButton: some View {
        Button(action: action) {
            Label(actionTitle, systemImage: actionSystemImage)
                .font(AppTypography.button)
                .frame(maxWidth: .infinity, minHeight: 50)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: AppRadius.medium))
        .tint(.brandPrimary)
        .accessibilityIdentifier(
            actionAccessibilityIdentifier
                ?? "participant.home.focus.action"
        )
    }
}

private struct ParticipantHomeProgressRing: View {
    let completed: Int
    let total: Int

    private var progress: Double {
        guard total > 0 else {
            return 0
        }
        return min(max(Double(completed) / Double(total), 0), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.appBorder, lineWidth: 10)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.brandPrimary,
                    style: StrokeStyle(
                        lineWidth: 10,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: AppSpacing.xxSmall) {
                Text("\(completed)/\(total)")
                    .font(AppTypography.metric)
                    .foregroundStyle(Color.appPrimaryText)
                    .monospacedDigit()

                Text("participant.home.focus.steps_completed")
                    .font(AppTypography.label)
                    .foregroundStyle(Color.appSecondaryText)
            }
        }
        .frame(width: 116, height: 116)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("participant.home.focus.progress"))
        .accessibilityValue(
            Text(
                "\(completed) \(Text("participant.home.focus.of")) \(total)"
            )
        )
    }
}

private struct ParticipantHomeLeaderboardItem: View {
    let entry: LeaderboardEntry

    var body: some View {
        VStack(spacing: AppSpacing.xSmall) {
            UserAvatar(
                displayName: entry.participantDisplayName,
                size: 60
            )
            .overlay {
                Circle()
                    .stroke(rankColor, lineWidth: entry.rank <= 3 ? 3 : 2)
                    .padding(-4)
            }
            .overlay {
                if entry.rank == 1 {
                    Circle()
                        .stroke(
                            Color.brandAccent.opacity(0.5),
                            lineWidth: 2
                        )
                        .padding(-8)
                }
            }
            .shadow(
                color: entry.rank == 1
                    ? Color.brandAccent.opacity(0.45)
                    : Color.clear,
                radius: 8
            )
            .padding(AppSpacing.xSmall)
            .frame(width: 76, height: 90, alignment: .bottom)
            .overlay(alignment: .top) {
                if entry.rank == 1 {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(Color.brandAccent)
                        .accessibilityHidden(true)
                }
            }

            Text(
                entry.rank,
                format: .number.locale(ParticipantFormatting.locale)
            )
            .font(AppTypography.label.monospacedDigit())
            .foregroundStyle(rankNumberColor)
            .frame(width: 28, height: 28)
            .background(rankColor, in: Circle())

            Text(firstName)
                .font(AppTypography.secondary.weight(.semibold))
                .foregroundStyle(Color.appPrimaryText)

            if entry.isCurrentUser {
                Text("participant.home.leaderboard.current_user")
                    .font(AppTypography.label)
                    .foregroundStyle(Color.brandPrimary)
                    .padding(.horizontal, AppSpacing.xSmall)
                    .padding(.vertical, AppSpacing.xxSmall)
                    .background(
                        Color.brandPrimary.opacity(0.1),
                        in: Capsule()
                    )
            }
        }
        .frame(minWidth: 64)
        .padding(.vertical, AppSpacing.xSmall)
        .accessibilityElement(children: .combine)
    }

    private var firstName: String {
        entry.participantDisplayName
            .split(separator: " ")
            .first
            .map(String.init)
            ?? entry.participantDisplayName
    }

    private var rankColor: Color {
        switch entry.rank {
        case 1:
            Color.brandAccent
        case 2:
            Color.gray
        case 3:
            Color.brown
        default:
            Color.appBorder
        }
    }

    private var rankNumberColor: Color {
        entry.rank <= 3 ? Color.black : Color.appPrimaryText
    }
}

private enum ParticipantHomeFocusAction {
    case step(ProgramStep)
    case weighIn(WeighInType)
    case program(UUID)

    var title: LocalizedStringKey {
        switch self {
        case .step:
            "participant.home.focus.continue"
        case .weighIn(.initial):
            "participant.weigh.initial.action"
        case .weighIn(.final):
            "participant.weigh.final.action"
        case .program:
            "action.view_program"
        }
    }

    var systemImage: String {
        switch self {
        case .step:
            "arrow.right"
        case .weighIn(.initial):
            "scalemass"
        case .weighIn(.final):
            "flag.checkered"
        case .program:
            "list.bullet.rectangle"
        }
    }

    var accessibilityIdentifier: String? {
        switch self {
        case .step(let step):
            "participant.step.open.\(step.order)"
        case .weighIn(.initial):
            "participant.weigh.initial.open"
        case .weighIn(.final):
            "participant.weigh.final.open"
        case .program:
            nil
        }
    }
}

#Preview("Home — aktif") {
    ParticipantHomePreview(day: 3)
}

#Preview("Home — gelap") {
    ParticipantHomePreview(day: 3)
        .preferredColorScheme(.dark)
}

#Preview("Home — Dynamic Type terbesar") {
    ParticipantHomePreview(day: 3)
        .dynamicTypeSize(.accessibility5)
}

#Preview("Home — tanpa program aktif") {
    ParticipantHomeEmptyPreview()
}

@MainActor
private struct ParticipantHomePreview: View {
    let day: Int
    @State private var store = ParticipantJourneyStore(
        environment: .preview
    )
    @State private var router = ShellTabRouter()

    var body: some View {
        NavigationStack {
            ParticipantHomeView(store: store, router: router)
                .navigationTitle(Text("tab.participant.today"))
                .task {
                    await store.load()
                    store.selectDay(day)
                }
        }
    }
}

@MainActor
private struct ParticipantHomeEmptyPreview: View {
    @State private var store = ParticipantJourneyStore(
        environment: .preview
    )
    @State private var router = ShellTabRouter()

    var body: some View {
        NavigationStack {
            ParticipantHomeView(store: store, router: router)
                .navigationTitle(Text("tab.participant.today"))
                .task {
                    await store.load()
                    store.hidesActiveProgramForDemo = true
                }
        }
    }
}
