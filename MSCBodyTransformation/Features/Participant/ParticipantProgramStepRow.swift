import SwiftUI

struct ParticipantProgramStepRow: View {
    let step: ProgramStep
    let dayNumber: Int
    let submission: StepSubmission?
    let canOpen: Bool
    let onOpen: () -> Void

    var body: some View {
        Group {
            if canOpen {
                Button(action: onOpen) {
                    rowContent(showsChevron: true)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(
                    "participant.program.step.\(dayNumber).\(step.order)"
                )
            } else {
                rowContent(showsChevron: false)
            }
        }
    }

    private func rowContent(showsChevron: Bool) -> some View {
        HStack(spacing: AppSpacing.medium) {
            Image(systemName: presentation.systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(presentation.color)
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                Text(step.title)
                    .font(AppTypography.body)
                    .foregroundStyle(Color.appPrimaryText)
                    .multilineTextAlignment(.leading)

                Text(LocalizedStringKey(presentation.statusKey))
                    .font(AppTypography.label)
                    .foregroundStyle(presentation.color)
            }

            Spacer(minLength: AppSpacing.small)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appSecondaryText)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.vertical, AppSpacing.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private var presentation: ParticipantProgramStepRowPresentation {
        ParticipantProgramStepRowPresentation(submission: submission)
    }
}

private struct ParticipantProgramStepRowPresentation {
    let statusKey: String
    let systemImage: String
    let color: Color

    init(submission: StepSubmission?) {
        guard let submission else {
            statusKey = "participant.status.not_started"
            systemImage = "circle"
            color = .appSecondaryText
            return
        }

        switch submission.status {
        case .pending:
            statusKey = "status.pending"
            systemImage = "clock.fill"
            color = .appWarning
        case .approved:
            statusKey = "status.approved"
            systemImage = "checkmark.circle.fill"
            color = .appSuccess
        case .rejected:
            statusKey = "status.rejected"
            systemImage = "exclamationmark.triangle.fill"
            color = .appDestructive
        }
    }
}
