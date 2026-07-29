import SwiftUI

struct ParticipantHomeCoachAvatar: View {
    let coach: CoachProfile
    let isAssigned: Bool
    let imageName: String?

    init(
        coach: CoachProfile,
        isAssigned: Bool,
        imageName: String? = nil
    ) {
        self.coach = coach
        self.isAssigned = isAssigned
        self.imageName = imageName
    }

    var body: some View {
        VStack(spacing: AppSpacing.xSmall) {
            UserAvatar(
                displayName: coach.displayName,
                imageName: imageName,
                size: 96
            )
            .overlay {
                Circle()
                    .stroke(
                        isAssigned ? Color.brandAccent : Color.brandPrimary,
                        lineWidth: isAssigned ? 4 : 3
                    )
                    .padding(-5)
            }
            .padding(AppSpacing.xSmall)
            .overlay(alignment: .bottom) {
                if isAssigned {
                    Label(
                        "participant.home.coaches.assigned",
                        systemImage: "star.fill"
                    )
                    .font(AppTypography.label.weight(.semibold))
                    .foregroundStyle(Color.brandSecondary)
                    .padding(.horizontal, AppSpacing.xSmall)
                    .padding(.vertical, AppSpacing.xxSmall)
                    .background(Color.brandAccent, in: Capsule())
                }
            }

            Text(coach.displayName)
                .font(AppTypography.secondary.weight(.semibold))
                .foregroundStyle(Color.appPrimaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text(coach.city)
                .font(AppTypography.label)
                .foregroundStyle(Color.appSecondaryText)
        }
        .frame(width: 128)
        .padding(.vertical, AppSpacing.xSmall)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("participant.home.coaches.open_hint"))
    }
}
