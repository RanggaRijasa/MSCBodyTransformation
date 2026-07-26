import SwiftUI

struct StatusBadge: View {
    let title: LocalizedStringKey
    let kind: AppStatusKind

    var body: some View {
        let style = AppStatusStyle.style(for: kind)

        Label(title, systemImage: style.systemImage)
            .font(AppTypography.label)
            .foregroundStyle(style.foregroundColor)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, AppSpacing.small)
            .padding(.vertical, AppSpacing.xSmall)
            .background(style.backgroundColor, in: Capsule())
            .accessibilityElement(children: .combine)
    }
}

struct ProgressRing: View {
    @Environment(\.accessibilityReduceMotion) private var shouldReduceMotion
    @ScaledMetric(relativeTo: .body) private var ringSize: CGFloat = 76
    @ScaledMetric(relativeTo: .body) private var strokeWidth: CGFloat = 8

    let progress: Double
    let label: LocalizedStringKey

    private var boundedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.appBorder, lineWidth: strokeWidth)

            Circle()
                .trim(from: 0, to: boundedProgress)
                .stroke(
                    Color.brandPrimary,
                    style: StrokeStyle(
                        lineWidth: strokeWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(
                    AppMotion.standard(reduceMotion: shouldReduceMotion),
                    value: boundedProgress
                )

            Text(
                boundedProgress,
                format: .percent.precision(.fractionLength(0))
            )
            .font(AppTypography.label.monospacedDigit())
            .foregroundStyle(Color.appPrimaryText)
        }
        .frame(width: ringSize, height: ringSize)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(label))
        .accessibilityValue(
            Text(
                boundedProgress,
                format: .percent.precision(.fractionLength(0))
            )
        )
    }
}

struct MetricCard: View {
    let title: LocalizedStringKey
    let value: String
    let systemImage: String
    let accentColor: Color

    init(
        title: LocalizedStringKey,
        value: String,
        systemImage: String,
        accentColor: Color = .brandPrimary
    ) {
        self.title = title
        self.value = value
        self.systemImage = systemImage
        self.accentColor = accentColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Label(title, systemImage: systemImage)
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appSecondaryText)

            Text(value)
                .font(AppTypography.metric)
                .foregroundStyle(Color.appPrimaryText)
                .fixedSize(horizontal: false, vertical: true)

            Rectangle()
                .fill(accentColor)
                .frame(height: 3)
                .accessibilityHidden(true)
        }
        .padding(AppSpacing.medium)
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
    }
}

struct RankBadge: View {
    let rank: Int

    var body: some View {
        Label {
            Text(rank, format: .number)
                .monospacedDigit()
        } icon: {
            Image(systemName: rank <= 3 ? "trophy.fill" : "number")
        }
        .font(AppTypography.cardTitle)
        .foregroundStyle(rank == 1 ? Color.black : Color.appPrimaryText)
        .padding(.horizontal, AppSpacing.medium)
        .frame(minHeight: 44)
        .background(rank == 1 ? Color.brandAccent : Color.clear, in: Capsule())
        .adaptiveGlassSurface(
            cornerRadius: AppRadius.prominent,
            tint: rank == 1 ? .brandAccent : nil
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("accessibility.rank"))
        .accessibilityValue(Text(rank, format: .number))
    }
}

#Preview("Status badges") {
    VStack(alignment: .leading, spacing: AppSpacing.small) {
        StatusBadge(title: "status.approved", kind: .success)
        StatusBadge(title: "status.pending", kind: .pending)
        StatusBadge(title: "status.rejected", kind: .error)
        StatusBadge(title: "status.locked", kind: .locked)
    }
    .padding()
}

#Preview("Metrics") {
    HStack {
        MetricCard(
            title: "metric.points",
            value: 1_250.formatted(
                .number.locale(Locale(identifier: "id-ID"))
            ),
            systemImage: "star.fill",
            accentColor: .brandAccent
        )
        ProgressRing(progress: 0.7, label: "metric.progress")
    }
    .padding()
}

#Preview("Rank") {
    HStack {
        RankBadge(rank: 1)
        RankBadge(rank: 4)
    }
    .padding()
}
