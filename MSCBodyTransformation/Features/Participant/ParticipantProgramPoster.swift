import SwiftUI

nonisolated enum ParticipantProgramParticipationStatus:
    Equatable,
    Sendable
{
    case enrolled
    case notEnrolled

    static func make(
        programID: UUID,
        enrollments: [ProgramEnrollment]
    ) -> Self {
        enrollments.contains {
            $0.programID == programID && $0.status != .cancelled
        } ? .enrolled : .notEnrolled
    }
}

struct ParticipantProgramPoster: View {
    let program: Program
    let participationStatus: ParticipantProgramParticipationStatus?

    init(
        program: Program,
        participationStatus: ParticipantProgramParticipationStatus? = nil
    ) {
        self.program = program
        self.participationStatus = participationStatus
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topTrailing) {
                if hasCoverImage {
                    ProgramCoverImage(
                        reference: program.coverLocalReference,
                        alternativeText:
                            program.coverAlternativeText
                            ?? String(
                                localized:
                                    "program.cover.default_alternative",
                                defaultValue: "Cover program"
                            )
                    )
                    .frame(
                        width: proxy.size.width,
                        height: proxy.size.height
                    )
                    .clipped()
                } else {
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }

                LinearGradient(
                    colors: coverOverlayColors,
                    startPoint: .top,
                    endPoint: .bottom
                )

                if !hasCoverImage {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 220, height: 220)
                        .offset(x: 130, y: -75)
                        .accessibilityHidden(true)

                    Image(systemName: posterSymbol)
                        .font(.system(size: 92, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.16))
                        .offset(x: 95, y: 45)
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                    Label(
                        topLabelTitle,
                        systemImage: topLabelSystemImage
                    )
                        .font(AppTypography.label)
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, AppSpacing.xSmall)
                        .padding(.vertical, AppSpacing.xxSmall)
                        .background(Color.black.opacity(0.32), in: Capsule())

                    Spacer()

                    Text(program.title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.white)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    let dayCount = Text(
                        program.durationInDays,
                        format: .number.locale(ParticipantFormatting.locale)
                    )
                    Text(
                        "\(dayCount) \(Text("participant.home.program.days"))"
                    )
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.white.opacity(0.88))
                }
                .padding(AppSpacing.medium)
                .frame(
                    width: proxy.size.width,
                    height: proxy.size.height,
                    alignment: .leading
                )

                Image(systemName: "arrow.up.right")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.18), in: Circle())
                    .padding(AppSpacing.small)
                    .accessibilityHidden(true)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .aspectRatio(16 / 9, contentMode: .fit)
        .clipShape(
            RoundedRectangle(
                cornerRadius: AppRadius.prominent,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: AppRadius.prominent,
                style: .continuous
            )
            .stroke(Color.white.opacity(0.16), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.12), radius: 12, y: 6)
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("participant.home.program.open_hint"))
    }

    private var hasCoverImage: Bool {
        LocalMediaImageResolver.image(
            reference: program.coverLocalReference
        ) != nil
    }

    private var coverOverlayColors: [Color] {
        if hasCoverImage {
            return [
                Color.black.opacity(0.12),
                Color.black.opacity(0.72)
            ]
        }
        return [
            Color.black.opacity(0.02),
            Color.black.opacity(0.28)
        ]
    }

    private var gradientColors: [Color] {
        switch program.status {
        case .scheduled:
            [Color.programPosterInfo, Color.programPosterBase]
        case .completed:
            [Color.programPosterBase, Color.programPosterAccent]
        case .draft, .preparingCommerce, .active, .archived:
            [Color.programPosterBase, Color.programPosterPrimary]
        }
    }

    private var posterSymbol: String {
        switch program.status {
        case .scheduled:
            "calendar.badge.clock"
        case .completed:
            "trophy.fill"
        case .draft, .preparingCommerce, .active, .archived:
            "figure.highintensity.intervaltraining"
        }
    }

    private var statusTitle: LocalizedStringKey {
        switch program.status {
        case .scheduled:
            "participant.home.program.status.scheduled"
        case .completed:
            "participant.home.program.status.completed"
        case .draft:
            "status.draft"
        case .preparingCommerce:
            "status.preparing_commerce"
        case .active:
            "status.active"
        case .archived:
            "status.archived"
        }
    }

    private var topLabelTitle: LocalizedStringKey {
        switch participationStatus {
        case .enrolled:
            "participant.program.participation.enrolled"
        case .notEnrolled:
            "participant.program.participation.not_enrolled"
        case nil:
            statusTitle
        }
    }

    private var topLabelSystemImage: String {
        switch participationStatus {
        case .enrolled:
            "checkmark.circle.fill"
        case .notEnrolled:
            "plus.circle"
        case nil:
            "calendar"
        }
    }
}
