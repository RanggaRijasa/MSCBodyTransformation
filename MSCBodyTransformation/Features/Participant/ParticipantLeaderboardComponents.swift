import SwiftUI

nonisolated struct ParticipantLeaderboardDisplayEntry:
    Equatable,
    Identifiable,
    Sendable
{
    let id: UUID
    let participantID: UUID
    let displayName: String
    let rank: Int
    let totalPoints: Int
    let progressPercentage: Int?
    let isCurrentUser: Bool
    let hasTie: Bool
}

struct ParticipantLeaderboardProgramSelector: View {
    let program: Program?
    let showsSelectionControl: Bool

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            Image(systemName: "trophy.fill")
                .font(.title2)
                .foregroundStyle(Color.brandAccent)
                .frame(width: 44, height: 44)
                .background(
                    Color.brandAccent.opacity(0.14),
                    in: RoundedRectangle(
                        cornerRadius: AppRadius.medium,
                        style: .continuous
                    )
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                Text("Program")
                    .font(AppTypography.label)
                    .foregroundStyle(Color.appSecondaryText)

                Text(program?.title ?? "Pilih program")
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(Color.appPrimaryText)
                    .multilineTextAlignment(.leading)

                if let program {
                    Text(ParticipantLeaderboardFormatting.range(program))
                        .font(AppTypography.label.monospacedDigit())
                        .foregroundStyle(Color.appSecondaryText)
                }
            }

            Spacer(minLength: AppSpacing.xSmall)

            if showsSelectionControl {
                HStack(spacing: AppSpacing.xxSmall) {
                    Text("Ganti")
                        .font(AppTypography.label.weight(.semibold))

                    Image(systemName: "chevron.right")
                        .font(AppTypography.label.weight(.semibold))
                        .accessibilityHidden(true)
                }
                .foregroundStyle(Color.brandPrimary)
            }
        }
        .padding(AppSpacing.medium)
        .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
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
        .accessibilityElement(children: .combine)
    }
}

struct ParticipantLeaderboardPodium: View {
    let entries: [ParticipantLeaderboardDisplayEntry]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: AppSpacing.small) {
                    ForEach(entries) { entry in
                        ParticipantLeaderboardRankRow(
                            entry: entry,
                            showsProgress: false
                        )
                    }
                }
            } else {
                HStack(alignment: .bottom, spacing: AppSpacing.xSmall) {
                    ForEach(visualOrder) { entry in
                        ParticipantLeaderboardPodiumPlace(entry: entry)
                    }
                }
            }
        }
        .accessibilityIdentifier("participant.leaderboard.podium")
    }

    private var visualOrder: [ParticipantLeaderboardDisplayEntry] {
        switch entries.count {
        case 3...:
            [entries[1], entries[0], entries[2]]
        case 2:
            [entries[1], entries[0]]
        default:
            entries
        }
    }
}

private struct ParticipantLeaderboardPodiumPlace: View {
    let entry: ParticipantLeaderboardDisplayEntry
    @ScaledMetric(relativeTo: .title2) private var firstAvatarSize = 86
    @ScaledMetric(relativeTo: .title3) private var otherAvatarSize = 70

    var body: some View {
        VStack(spacing: AppSpacing.xSmall) {
            avatar

            VStack(spacing: AppSpacing.xSmall) {
                Text(entry.displayName)
                    .font(AppTypography.secondary.weight(.semibold))
                    .foregroundStyle(Color.appPrimaryText)
                    .multilineTextAlignment(.center)

                Text(
                    ParticipantLeaderboardFormatting.points(
                        entry.totalPoints
                    )
                )
                .font(.title2.monospacedDigit().weight(.bold))
                .foregroundStyle(Color.appPrimaryText)
                .fixedSize(horizontal: true, vertical: false)

                Text("poin")
                    .font(AppTypography.label)
                    .foregroundStyle(Color.appSecondaryText)

                if entry.isCurrentUser {
                    Text("Kamu")
                        .font(AppTypography.label.weight(.semibold))
                        .foregroundStyle(Color.brandPrimary)
                        .padding(.horizontal, AppSpacing.xSmall)
                        .padding(.vertical, AppSpacing.xxSmall)
                        .background(
                            Color.brandPrimary.opacity(0.1),
                            in: Capsule()
                        )
                }
            }
            .padding(.horizontal, AppSpacing.xSmall)
            .padding(.vertical, AppSpacing.small)
            .frame(
                maxWidth: .infinity,
                minHeight: entry.rank == 1 ? 150 : 124,
                alignment: .top
            )
            .background(
                style.surfaceColor,
                in: UnevenRoundedRectangle(
                    topLeadingRadius: AppRadius.large,
                    bottomLeadingRadius: AppRadius.medium,
                    bottomTrailingRadius: AppRadius.medium,
                    topTrailingRadius: AppRadius.large,
                    style: .continuous
                )
            )
            .overlay {
                UnevenRoundedRectangle(
                    topLeadingRadius: AppRadius.large,
                    bottomLeadingRadius: AppRadius.medium,
                    bottomTrailingRadius: AppRadius.medium,
                    topTrailingRadius: AppRadius.large,
                    style: .continuous
                )
                .stroke(style.accentColor.opacity(0.6), lineWidth: 1)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            Text("Peringkat \(entry.rank), \(entry.displayName)")
        )
        .accessibilityValue(
            Text("\(entry.totalPoints) poin")
        )
    }

    private var avatar: some View {
        UserAvatar(
            displayName: entry.displayName,
            size: entry.rank == 1 ? firstAvatarSize : otherAvatarSize
        )
        .overlay {
            Circle()
                .stroke(style.accentColor, lineWidth: entry.rank == 1 ? 4 : 3)
                .padding(-4)
        }
        .overlay(alignment: .bottom) {
            Text(
                entry.rank,
                format: .number.locale(
                    ParticipantLeaderboardFormatting.locale
                )
            )
            .font(AppTypography.cardTitle.monospacedDigit())
            .foregroundStyle(style.rankForegroundColor)
            .frame(width: 38, height: 38)
            .background(style.accentColor, in: Circle())
            .overlay {
                Circle()
                    .stroke(Color.appSurface, lineWidth: 3)
            }
            .offset(y: AppSpacing.medium)
        }
        .overlay(alignment: .top) {
            if entry.rank == 1 {
                Image(systemName: "crown.fill")
                    .font(.title3)
                    .foregroundStyle(Color.brandAccent)
                    .offset(y: -AppSpacing.large)
                    .accessibilityHidden(true)
            }
        }
        .padding(.top, entry.rank == 1 ? AppSpacing.large : 0)
        .padding(.bottom, AppSpacing.small)
    }

    private var style: ParticipantLeaderboardRankStyle {
        ParticipantLeaderboardRankStyle(rank: entry.rank)
    }
}

struct ParticipantLeaderboardCurrentRankCard: View {
    let entry: ParticipantLeaderboardDisplayEntry

    var body: some View {
        ParticipantLeaderboardRankRow(
            entry: entry,
            showsProgress: true,
            isCurrentUserCard: true
        )
        .accessibilityIdentifier("participant.leaderboard.current-user")
    }
}

struct ParticipantLeaderboardRankRow: View {
    let entry: ParticipantLeaderboardDisplayEntry
    var showsProgress = true
    var isCurrentUserCard = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    HStack(alignment: .top, spacing: AppSpacing.medium) {
                        rankBadge
                        UserAvatar(displayName: entry.displayName, size: 52)
                        participantDetails
                    }

                    HStack {
                        Spacer()
                        pointsBadge
                    }
                }
            } else {
                HStack(spacing: AppSpacing.medium) {
                    rankBadge
                    UserAvatar(displayName: entry.displayName, size: 52)
                    participantDetails
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                    pointsBadge
                }
            }
        }
        .padding(AppSpacing.medium)
        .background(
            isCurrentUserCard
                ? Color.brandPrimary.opacity(0.08)
                : Color.appSurface,
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
            .stroke(
                isCurrentUserCard ? Color.brandPrimary : Color.appBorder,
                lineWidth: isCurrentUserCard ? 2 : 1
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(
            "participant.leaderboard.rank.\(entry.rank).\(entry.id)"
        )
    }

    private var rankBadge: some View {
        Text(
            entry.rank,
            format: .number.locale(
                ParticipantLeaderboardFormatting.locale
            )
        )
        .font(AppTypography.cardTitle.monospacedDigit())
        .foregroundStyle(
            entry.rank <= 3
                ? ParticipantLeaderboardRankStyle(
                    rank: entry.rank
                ).rankForegroundColor
                : Color.appPrimaryText
        )
        .frame(width: 42, height: 42)
        .background(
            entry.rank <= 3
                ? ParticipantLeaderboardRankStyle(
                    rank: entry.rank
                ).accentColor
                : Color.appSecondaryBackground,
            in: Circle()
        )
    }

    private var participantDetails: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
            Text(entry.displayName)
                .font(AppTypography.cardTitle)
                .foregroundStyle(Color.appPrimaryText)

            if showsProgress,
               let progressPercentage = entry.progressPercentage {
                Text(
                    ParticipantFormatting.percentage(progressPercentage)
                )
                .font(AppTypography.secondary.monospacedDigit())
                .foregroundStyle(Color.appSecondaryText)
            }

            if entry.hasTie {
                Label("Poin sama", systemImage: "equal.circle")
                    .font(AppTypography.label)
                    .foregroundStyle(Color.appInfo)
            }
        }
    }

    private var pointsBadge: some View {
        VStack(alignment: .trailing, spacing: AppSpacing.xxSmall) {
            Text(
                ParticipantLeaderboardFormatting.points(
                    entry.totalPoints
                )
            )
            .font(.title3.monospacedDigit().weight(.bold))
            .foregroundStyle(Color.appPrimaryText)
            .fixedSize(horizontal: true, vertical: false)

            Text("poin")
                .font(AppTypography.label)
                .foregroundStyle(Color.appSecondaryText)
        }
        .padding(.horizontal, AppSpacing.small)
        .padding(.vertical, AppSpacing.xSmall)
        .background(Color.appSecondaryBackground, in: Capsule())
        .fixedSize(horizontal: true, vertical: false)
    }
}

struct ParticipantLeaderboardArchiveRow: View {
    let program: Program
    let isSelected: Bool

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            Image(systemName: "trophy.circle.fill")
                .font(.title2)
                .foregroundStyle(Color.brandAccent)

            VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                Text(program.title)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(Color.appPrimaryText)
                Text(ParticipantLeaderboardFormatting.range(program))
                    .font(AppTypography.secondary.monospacedDigit())
                    .foregroundStyle(Color.appSecondaryText)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.brandPrimary)
                    .accessibilityLabel(Text("Dipilih"))
            } else {
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.appSecondaryText)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, AppSpacing.xSmall)
    }
}

nonisolated enum ParticipantLeaderboardFormatting {
    static let locale = Locale(identifier: "id-ID")

    static func points(_ value: Int) -> String {
        value.formatted(.number.locale(locale))
    }

    static func range(_ program: Program) -> String {
        var format = Date.FormatStyle()
            .day()
            .month(.abbreviated)
            .year()
            .locale(locale)
        let timeZone =
            TimeZone(identifier: program.timeZoneIdentifier) ?? .gmt
        format.timeZone = timeZone

        let startDate = program.days.first?.scheduledDate ?? program.startDate
        let endDate = program.days.last?.scheduledDate
            ?? scheduledEndDate(
                startDate: startDate,
                durationInDays: program.durationInDays,
                timeZone: timeZone
            )
        return "\(startDate.formatted(format)) – "
            + endDate.formatted(format)
    }

    private static func scheduledEndDate(
        startDate: Date,
        durationInDays: Int,
        timeZone: TimeZone
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(
            byAdding: .day,
            value: max(durationInDays - 1, 0),
            to: startDate
        ) ?? startDate
    }
}

#Preview("Peringkat dengan poin lima digit") {
    let entries = [
        ParticipantLeaderboardDisplayEntry(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            participantID:
                UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
            displayName: "Farhan Rizki",
            rank: 1,
            totalPoints: 18_750,
            progressPercentage: 100,
            isCurrentUser: false,
            hasTie: false
        ),
        ParticipantLeaderboardDisplayEntry(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            participantID:
                UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
            displayName: "Citra Dewi",
            rank: 2,
            totalPoints: 15_420,
            progressPercentage: 96,
            isCurrentUser: false,
            hasTie: false
        ),
        ParticipantLeaderboardDisplayEntry(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            participantID:
                UUID(uuidString: "10000000-0000-0000-0000-000000000003")!,
            displayName: "Eka Sari",
            rank: 3,
            totalPoints: 12_350,
            progressPercentage: 92,
            isCurrentUser: true,
            hasTie: false
        )
    ]

    ScrollView {
        VStack(spacing: AppSpacing.large) {
            ParticipantLeaderboardPodium(entries: entries)
            ParticipantLeaderboardCurrentRankCard(entry: entries[2])
        }
        .padding(AppSpacing.medium)
    }
    .background(Color.appBackground)
    .environment(\.locale, Locale(identifier: "id-ID"))
}
