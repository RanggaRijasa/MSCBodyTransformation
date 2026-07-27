import SwiftUI

@MainActor
struct ParticipantProgramView: View {
    let store: ParticipantJourneyStore
    let router: ShellTabRouter

    var body: some View {
        if store.currentEnrollment != nil,
           let program = store.currentProgram {
            List {
                overviewSection(program)
                scoringSection(program)
                timelineSection(program)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .accessibilityIdentifier("participant.program")
        } else {
            EmptyStateView(
                title: "participant.program.empty.title",
                message: "participant.program.empty.message",
                systemImage: "list.bullet.rectangle"
            )
        }
    }

    private func overviewSection(_ program: Program) -> some View {
        Section {
            ProgramCard(
                title: LocalizedStringKey(program.title),
                summary: program.summary,
                statusTitle: "status.active",
                statusKind: .success,
                progress: Double(store.overallProgress) / 100
            )

            LabeledContent(
                "participant.program.period",
                value: "\(ParticipantFormatting.date(program.days.map(\.scheduledDate).min() ?? program.startDate, timeZoneIdentifier: program.timeZoneIdentifier)) – \(ParticipantFormatting.date(program.days.map(\.scheduledDate).max() ?? program.endDate, timeZoneIdentifier: program.timeZoneIdentifier))"
            )
            LabeledContent("participant.program.duration") {
                let dayCount = Text(
                    program.days.count,
                    format: .number.locale(ParticipantFormatting.locale)
                )
                Text("\(dayCount) \(Text("participant.program.days_suffix"))")
            }

            if let coachID = store.currentEnrollment?.coachID,
               let coach = store.coach(id: coachID) {
                Button {
                    router.navigate(
                        to: .participant(.coach(coach.id)),
                        in: .participant(.program)
                    )
                } label: {
                    HStack(spacing: AppSpacing.medium) {
                        UserAvatar(displayName: coach.displayName)
                        VStack(alignment: .leading) {
                            Text("participant.program.assigned_coach")
                                .font(AppTypography.label)
                                .foregroundStyle(Color.appSecondaryText)
                            Text(coach.displayName)
                                .font(AppTypography.cardTitle)
                                .foregroundStyle(Color.appPrimaryText)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("participant.program.overview")
        }
    }

    private func scoringSection(_ program: Program) -> some View {
        Section {
            Label(
                "participant.program.rule.step_points",
                systemImage: "checkmark.seal"
            )
            Label(
                "participant.program.rule.review",
                systemImage: "person.crop.circle.badge.checkmark"
            )
            LabeledContent("participant.program.weight_points_rate") {
                let pointsPerKilogram = Text(
                    NSDecimalNumber(
                        decimal: program.weightPointsPerKilogram
                    ).intValue,
                    format: .number.locale(ParticipantFormatting.locale)
                )
                Text(
                    "\(pointsPerKilogram) \(Text("participant.program.points_per_kg_suffix"))"
                )
            }
            Text("participant.local_score_notice")
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appSecondaryText)
        } header: {
            Text("participant.program.rules")
        }
    }

    private func timelineSection(_ program: Program) -> some View {
        Section {
            ForEach(program.days.sorted(by: {
                $0.dayNumber < $1.dayNumber
            })) { day in
                timelineRow(day)
            }
        } header: {
            Text("participant.program.timeline")
        } footer: {
            Text("participant.program.timeline.footer")
        }
    }

    @ViewBuilder
    private func timelineRow(_ day: ProgramDay) -> some View {
        let access = store.access(for: day)
        let isHidden = access == .hidden

        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack(alignment: .top, spacing: AppSpacing.medium) {
                Image(systemName: daySymbol(access))
                    .foregroundStyle(dayColor(access))
                    .frame(width: 44, height: 44)
                    .background(dayColor(access).opacity(0.12), in: Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                    let dayNumber = Text(
                        day.dayNumber,
                        format: .number.locale(
                            ParticipantFormatting.locale
                        )
                    )
                    Text("\(Text("participant.day.label")) \(dayNumber)")
                    .font(AppTypography.cardTitle)

                    Text(
                        isHidden
                            ? String(
                                localized: "participant.program.hidden_day"
                            )
                            : day.title
                    )
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)

                    if !isHidden {
                        Text(
                            ParticipantFormatting.date(
                                day.scheduledDate,
                                timeZoneIdentifier: store.currentProgram?
                                    .timeZoneIdentifier
                            )
                        )
                        .font(AppTypography.label)
                        .foregroundStyle(Color.appSecondaryText)
                    }
                }
                Spacer()
                StatusBadge(
                    title: LocalizedStringKey(dayStatusKey(access)),
                    kind: dayStatusKind(access)
                )
            }

            if !isHidden && access != .locked {
                ForEach(day.steps.sorted(by: { $0.order < $1.order })) {
                    step in
                    Button {
                        router.navigate(
                            to: .participant(.stepDetail(step.id)),
                            in: .participant(.program)
                        )
                    } label: {
                        Label(step.title, systemImage: "chevron.right")
                            .labelStyle(.titleAndIcon)
                            .foregroundStyle(Color.appPrimaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 60)
                }
            }
        }
        .padding(.vertical, AppSpacing.xSmall)
        .accessibilityElement(children: .contain)
    }

    private func dayStatusKey(_ access: ProgramDayAccess) -> String {
        switch access {
        case .available:
            "participant.day.current"
        case .readOnly:
            "participant.day.past"
        case .locked:
            "status.locked"
        case .hidden:
            "participant.day.hidden"
        }
    }

    private func dayStatusKind(_ access: ProgramDayAccess) -> AppStatusKind {
        switch access {
        case .available:
            .information
        case .readOnly:
            .success
        case .locked:
            .locked
        case .hidden:
            .neutral
        }
    }

    private func daySymbol(_ access: ProgramDayAccess) -> String {
        switch access {
        case .available:
            "sun.max.fill"
        case .readOnly:
            "checkmark.circle.fill"
        case .locked:
            "lock.fill"
        case .hidden:
            "eye.slash.fill"
        }
    }

    private func dayColor(_ access: ProgramDayAccess) -> Color {
        AppStatusStyle.style(for: dayStatusKind(access)).foregroundColor
    }
}

#Preview("Timeline dengan hari tersembunyi") {
    ParticipantProgramPreview()
}

@MainActor
private struct ParticipantProgramPreview: View {
    @State private var store = ParticipantJourneyStore(
        environment: .preview
    )
    @State private var router = ShellTabRouter()

    var body: some View {
        NavigationStack {
            ParticipantProgramView(store: store, router: router)
                .task {
                    await store.load()
                    store.selectDay(3)
                }
        }
    }
}
