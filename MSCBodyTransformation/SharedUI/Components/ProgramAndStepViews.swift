import SwiftUI

struct ProgramCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let title: LocalizedStringKey
    let summary: String
    let statusTitle: LocalizedStringKey
    let statusKind: AppStatusKind
    let progress: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            adaptiveHeader

            if let progress {
                ProgressView(value: min(max(progress, 0), 1))
                    .tint(.brandPrimary)
                    .accessibilityLabel(Text("metric.progress"))
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

    @ViewBuilder
    private var adaptiveHeader: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                titleAndSummary
                StatusBadge(title: statusTitle, kind: statusKind)
            }
        } else {
            HStack(alignment: .top, spacing: AppSpacing.medium) {
                titleAndSummary
                Spacer(minLength: AppSpacing.small)
                StatusBadge(title: statusTitle, kind: statusKind)
            }
        }
    }

    private var titleAndSummary: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text(title)
                .font(AppTypography.cardTitle)
                .foregroundStyle(Color.appPrimaryText)
                .fixedSize(horizontal: false, vertical: true)

            Text(LocalizedStringKey(summary))
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appSecondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct StepRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let title: LocalizedStringKey
    let detail: String
    let points: Int
    let statusTitle: LocalizedStringKey
    let statusKind: AppStatusKind

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    statusIcon
                    stepDescription
                    HStack(alignment: .top, spacing: AppSpacing.small) {
                        StatusBadge(title: statusTitle, kind: statusKind)
                        Spacer(minLength: AppSpacing.xSmall)
                        pointsLabel
                    }
                }
            } else {
                HStack(alignment: .top, spacing: AppSpacing.medium) {
                    statusIcon
                    stepDescription
                    Spacer(minLength: AppSpacing.xSmall)
                    pointsLabel
                }
            }
        }
        .padding(.vertical, AppSpacing.xSmall)
        .accessibilityElement(children: .combine)
    }

    private var statusIcon: some View {
        Image(systemName: AppStatusStyle.style(for: statusKind).systemImage)
            .foregroundStyle(
                AppStatusStyle.style(for: statusKind).foregroundColor
            )
            .frame(width: 44, height: 44)
            .background(
                AppStatusStyle.style(for: statusKind).backgroundColor,
                in: Circle()
            )
            .accessibilityHidden(true)
    }

    private var stepDescription: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text(title)
                .font(AppTypography.cardTitle)
                .foregroundStyle(Color.appPrimaryText)
                .fixedSize(horizontal: false, vertical: true)

            Text(LocalizedStringKey(detail))
                .font(AppTypography.secondary)
                .foregroundStyle(Color.appSecondaryText)
                .fixedSize(horizontal: false, vertical: true)

            if !dynamicTypeSize.isAccessibilitySize {
                StatusBadge(title: statusTitle, kind: statusKind)
            }
        }
    }

    private var pointsLabel: some View {
        Text(points, format: .number)
            .font(AppTypography.label.monospacedDigit())
            .foregroundStyle(Color.appPrimaryText)
            .accessibilityLabel(Text("metric.points"))
    }
}

struct SectionHeader: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey?

    init(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
            Text(title)
                .font(AppTypography.sectionTitle)
                .foregroundStyle(Color.appPrimaryText)

            if let subtitle {
                Text(subtitle)
                    .font(AppTypography.secondary)
                    .foregroundStyle(Color.appSecondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

struct LockedContentView: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey

    var body: some View {
        EmptyStateView(
            title: title,
            message: message,
            systemImage: "lock.fill"
        )
    }
}

struct EvidenceStatusView: View {
    let status: SubmissionStatus?

    var body: some View {
        switch status {
        case .approved:
            StatusBadge(title: "status.approved", kind: .success)
        case .pending:
            StatusBadge(title: "status.pending", kind: .pending)
        case .rejected:
            StatusBadge(title: "status.rejected", kind: .error)
        case nil:
            StatusBadge(title: "status.missing", kind: .neutral)
        }
    }
}

#Preview("Program card") {
    ProgramCard(
        title: "Transformasi 7 hari",
        summary: "Program demo untuk membangun kebiasaan aktif.",
        statusTitle: "status.active",
        statusKind: .success,
        progress: 0.4
    )
    .padding()
}

#Preview("Step row") {
    StepRow(
        title: "Gerak pagi",
        detail: "Lakukan aktivitas ringan sesuai kemampuan.",
        points: 10,
        statusTitle: "status.pending",
        statusKind: .pending
    )
    .padding()
}

#Preview("Evidence states") {
    VStack {
        EvidenceStatusView(status: .approved)
        EvidenceStatusView(status: .pending)
        EvidenceStatusView(status: .rejected)
        EvidenceStatusView(status: nil)
    }
    .padding()
}
