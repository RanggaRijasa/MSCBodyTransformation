import SwiftUI

struct ParticipantProgramOfferView: View {
    let program: Program
    let join: () -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppSpacing.xLarge) {
                ParticipantProgramPoster(
                    program: program,
                    participationStatus: .notEnrolled
                )

                programIdentity
                aboutSection
                priceSection
            }
            .frame(maxWidth: 680, alignment: .leading)
            .padding(.horizontal, AppSpacing.medium)
            .padding(.bottom, AppSpacing.xxLarge)
            .frame(maxWidth: .infinity)
        }
        .background(Color.appBackground)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            joinBar
        }
        .navigationTitle(program.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var programIdentity: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(periodText)
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appSecondaryText)

            Text(program.title)
                .font(.title.weight(.bold))
                .foregroundStyle(Color.appPrimaryText)
                .fixedSize(horizontal: false, vertical: true)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: AppSpacing.medium) {
                    durationLabel
                    stepCountLabel
                }
                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    durationLabel
                    stepCountLabel
                }
            }
        }
        .padding(AppSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
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
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("participant.program.offer.identity")
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("participant.program.offer.about")
                .font(AppTypography.sectionTitle)
                .foregroundStyle(Color.appPrimaryText)

            Text(program.summary)
                .font(AppTypography.body)
                .foregroundStyle(Color.appPrimaryText)
                .fixedSize(horizontal: false, vertical: true)

            Label(
                "participant.program.offer.wellness_note",
                systemImage: "heart.text.square"
            )
            .font(AppTypography.secondary)
            .foregroundStyle(Color.appSecondaryText)
        }
    }

    private var priceSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Divider()
            Text("participant.program.offer.price")
                .font(AppTypography.sectionTitle)
            Text(
                ParticipantFormatting.currency(program.price ?? 0)
            )
            .font(.title2.weight(.bold).monospacedDigit())
            .foregroundStyle(Color.appPrimaryText)
        }
    }

    private var joinBar: some View {
        VStack(spacing: 0) {
            Divider()
            Button(action: join) {
                Text("participant.program.offer.join")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.small)
            .accessibilityIdentifier("participant.program.offer.join")
        }
        .background(Color.appBackground)
    }

    private var durationLabel: some View {
        Label {
            Text(
                "\(program.durationInDays, format: .number.locale(ParticipantFormatting.locale)) \(Text("participant.program.days_suffix"))"
            )
        } icon: {
            Image(systemName: "calendar")
                .foregroundStyle(Color.brandPrimary)
        }
        .font(AppTypography.secondary)
    }

    private var stepCountLabel: some View {
        let stepCount = program.days.flatMap(\.steps).count
        return Label {
            Text(
                "\(stepCount, format: .number.locale(ParticipantFormatting.locale)) \(Text("participant.program.offer.steps_suffix"))"
            )
        } icon: {
            Image(systemName: "checklist")
                .foregroundStyle(Color.brandPrimary)
        }
        .font(AppTypography.secondary)
    }

    private var periodText: String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone =
            TimeZone(identifier: program.timeZoneIdentifier) ?? .gmt
        let displayEndDate = program.days.map(\.scheduledDate).max()
            ?? calendar.date(
                byAdding: .day,
                value: max(program.durationInDays - 1, 0),
                to: program.startDate
            )
            ?? program.endDate
        let start = ParticipantFormatting.date(
            program.startDate,
            timeZoneIdentifier: program.timeZoneIdentifier
        )
        let end = ParticipantFormatting.date(
            displayEndDate,
            timeZoneIdentifier: program.timeZoneIdentifier
        )
        return "\(start) – \(end)"
    }
}
