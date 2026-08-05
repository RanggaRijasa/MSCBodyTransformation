import SwiftUI

@MainActor
struct ParticipantProgramCatalogView: View {
    let store: ParticipantJourneyStore
    let router: ShellTabRouter
    var navigationContext: ProgramParticipationNavigationContext =
        .participant(.program)

    @State private var selectedFilter =
        ParticipantProgramCatalogFilter.enrolled

    var body: some View {
        if store.snapshot != nil || store.guestSnapshot != nil {
            VStack(spacing: 0) {
                catalogHeader

                Picker(
                    "participant.program.catalog.filter.label",
                    selection: $selectedFilter
                ) {
                    ForEach(ParticipantProgramCatalogFilter.allCases) {
                        filter in
                        Text(filter.title)
                            .font(.subheadline.weight(.medium))
                            .frame(minHeight: AppSpacing.xLarge)
                            .tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .controlSize(.large)
                .frame(minHeight: 44)
                .padding(.horizontal, AppSpacing.medium)
                .padding(.top, AppSpacing.small)
                .padding(.bottom, AppSpacing.medium)
                .accessibilityIdentifier(
                    "participant.program.catalog.filter"
                )

                programList
                    .frame(maxHeight: .infinity)
            }
            .background(Color.appBackground)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if store.isGuest {
                    selectedFilter = .available
                }
            }
        } else {
            EmptyStateView(
                title: "participant.program.empty.title",
                message: "participant.program.empty.message",
                systemImage: "rectangle.stack"
            )
        }
    }

    private var catalogHeader: some View {
        HStack(alignment: .center, spacing: AppSpacing.medium) {
            Text("tab.participant.program")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Color.appPrimaryText)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("participant.program.catalog")

            Spacer(minLength: AppSpacing.small)
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.top, AppSpacing.small)
        .padding(.bottom, AppSpacing.xSmall)
    }

    private var programList: some View {
        let programs = filteredPrograms

        return ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.large) {
                if programs.isEmpty {
                    ContentUnavailableView {
                        Label(
                            selectedFilter.emptyTitle,
                            systemImage: selectedFilter.emptySystemImage
                        )
                    } description: {
                        Text(
                            store.isGuest
                                && selectedFilter != .available
                                ? "guest.program.account_required"
                                : selectedFilter.emptyMessage
                        )
                    }
                    .frame(maxWidth: .infinity, minHeight: 280)
                } else {
                    ForEach(programs) { program in
                        Button {
                            openProgram(program)
                        } label: {
                            ParticipantProgramPoster(
                                program: program,
                                participationStatus: participationStatus(
                                    for: program
                                )
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(
                            "participant.program.select.\(program.id)"
                        )
                    }
                }
            }
            .frame(maxWidth: 760)
            .padding(.horizontal, AppSpacing.medium)
            .padding(.bottom, AppSpacing.large)
            .frame(maxWidth: .infinity)
        }
    }

    private var filteredPrograms: [Program] {
        store.programs
            .filter { program in
                if store.isGuest, selectedFilter != .available {
                    return false
                }
                return selectedFilter.includes(
                    program,
                    enrollment: store.visibleEnrollments.first {
                        $0.programID == program.id
                    }
                )
            }
            .sorted(by: selectedFilter.precedes)
    }

    private func openProgram(_ program: Program) {
        router.navigate(
            to: navigationContext.programDetailRoute(
                programID: program.id
            ),
            in: navigationContext.tab
        )
    }

    private func participationStatus(
        for program: Program
    ) -> ParticipantProgramParticipationStatus {
        guard let snapshot = store.snapshot else {
            return store.registrationAvailability(for: program) == .closed
                ? .registrationClosed
                : .notEnrolled
        }
        let status = ParticipantProgramParticipationStatus.make(
            programID: program.id,
            enrollments: snapshot.enrollments
        )
        if status == .notEnrolled,
           store.registrationAvailability(for: program) == .closed {
            return .registrationClosed
        }
        return status
    }
}

private enum ParticipantProgramCatalogFilter:
    String,
    CaseIterable,
    Identifiable
{
    case enrolled
    case available
    case history

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .enrolled:
            "participant.program.catalog.filter.enrolled"
        case .available:
            "participant.program.catalog.filter.available"
        case .history:
            "participant.program.catalog.filter.history"
        }
    }

    var emptyTitle: LocalizedStringKey {
        switch self {
        case .enrolled:
            "participant.program.catalog.enrolled.empty.title"
        case .available:
            "participant.program.catalog.available.empty.title"
        case .history:
            "participant.program.catalog.history.empty.title"
        }
    }

    var emptyMessage: LocalizedStringKey {
        switch self {
        case .enrolled:
            "participant.program.catalog.enrolled.empty.message"
        case .available:
            "participant.program.catalog.available.empty.message"
        case .history:
            "participant.program.catalog.history.empty.message"
        }
    }

    var emptySystemImage: String {
        switch self {
        case .enrolled:
            "checkmark.circle"
        case .available:
            "rectangle.stack"
        case .history:
            "clock.arrow.circlepath"
        }
    }

    func includes(
        _ program: Program,
        enrollment: ProgramEnrollment?
    ) -> Bool {
        switch self {
        case .enrolled:
            guard let enrollment else {
                return false
            }
            return enrollment.status == .active
                && (program.status == .active
                    || program.status == .scheduled)
        case .available:
            let canEnroll = enrollment == nil
                || enrollment?.status == .cancelled
            return canEnroll
                && (program.status == .active
                    || program.status == .scheduled)
        case .history:
            guard let enrollment,
                  enrollment.status != .cancelled else {
                return false
            }
            return enrollment.status == .completed
                || program.status == .completed
                || program.status == .archived
        }
    }

    func precedes(_ lhs: Program, _ rhs: Program) -> Bool {
        switch self {
        case .enrolled, .available:
            if lhs.status == rhs.status {
                return lhs.startDate < rhs.startDate
            }
            return lhs.status == .active
        case .history:
            return lhs.endDate > rhs.endDate
        }
    }
}
