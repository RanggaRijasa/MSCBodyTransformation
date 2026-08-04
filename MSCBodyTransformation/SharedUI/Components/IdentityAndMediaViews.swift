import SwiftUI
import UIKit

enum LocalMediaImageResolver {
    static func image(reference: String?) -> UIImage? {
        guard let reference, !reference.isEmpty else {
            return nil
        }
        if FileManager.default.fileExists(atPath: reference) {
            return UIImage(contentsOfFile: reference)
        }
        if let image = UIImage(named: reference) {
            return image
        }
        if isBundledEvidenceFixture(reference) {
            return UIImage(named: "EvidenceDemoFixture")
        }
        return nil
    }

    static func isBundledEvidenceFixture(_ reference: String?) -> Bool {
        guard let reference else {
            return false
        }
        return reference.hasPrefix("fixtures/evidence/")
            || reference.hasPrefix("local-demo://debug/evidence")
    }
}

struct ProgramCoverImage: View {
    let reference: String?
    let alternativeText: String

    var body: some View {
        Group {
            if let image = LocalMediaImageResolver.image(
                reference: reference
            ) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [
                            Color.programPosterBase,
                            Color.programPosterPrimary
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "photo")
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.72))
                }
            }
        }
        .aspectRatio(16.0 / 9.0, contentMode: .fit)
        .clipped()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            Text(
                alternativeText.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ).isEmpty
                    ? String(
                        localized: "program.cover.default_alternative",
                        defaultValue: "Cover program"
                    )
                    : alternativeText
            )
        )
        .accessibilityAddTraits(.isImage)
    }
}

struct UserAvatar: View {
    let displayName: String
    let imageName: String?
    let size: CGFloat

    init(
        displayName: String,
        imageName: String? = nil,
        size: CGFloat = 52
    ) {
        self.displayName = displayName
        self.imageName = imageName
        self.size = size
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.appSecondaryText)
                    .padding(size * 0.12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.appSecondaryBackground)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            Circle().stroke(Color.appBorder, lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(displayName))
    }

    private var image: UIImage? {
        guard let imageName, !imageName.isEmpty else {
            return nil
        }
        if FileManager.default.fileExists(atPath: imageName) {
            return UIImage(contentsOfFile: imageName)
        }
        return UIImage(named: imageName)
    }

}

struct HomeProfileCard: View {
    let displayName: String
    let imageName: String?
    let badgeTitle: LocalizedStringKey
    let accessibilityHint: LocalizedStringKey
    let accessibilityIdentifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.medium) {
                UserAvatar(
                    displayName: displayName,
                    imageName: imageName,
                    size: 64
                )

                VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                    Text("participant.home.greeting")
                        .font(AppTypography.secondary)
                        .foregroundStyle(Color.appSecondaryText)

                    Text(displayName)
                        .font(AppTypography.sectionTitle)
                        .foregroundStyle(Color.appPrimaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(badgeTitle)
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
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text(accessibilityHint))
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

struct MediaThumbnail: View {
    let title: LocalizedStringKey
    let systemImage: String
    let kindLabel: LocalizedStringKey
    var imageReference: String? = nil
    var showsDemoBadge = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            Group {
                if let image = LocalMediaImageResolver.image(
                    reference: imageReference
                ) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.appSecondaryBackground

                    VStack(spacing: AppSpacing.xSmall) {
                        Image(systemName: systemImage)
                            .font(.title2)
                            .foregroundStyle(Color.brandPrimary)
                            .accessibilityHidden(true)

                        Text(kindLabel)
                            .font(AppTypography.label)
                            .foregroundStyle(Color.appSecondaryText)
                    }
                }
            }

            if showsDemoBadge {
                Text("coach.evidence.demo_badge")
                    .font(AppTypography.label)
                    .foregroundStyle(Color.appPrimaryText)
                    .padding(.horizontal, AppSpacing.xSmall)
                    .padding(.vertical, AppSpacing.xxSmall)
                    .background(.regularMaterial, in: Capsule())
                    .padding(AppSpacing.xSmall)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 112)
        .clipShape(
            RoundedRectangle(
                cornerRadius: AppRadius.medium,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: AppRadius.medium,
                style: .continuous
            )
            .stroke(Color.appBorder, lineWidth: 1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
        .accessibilityValue(
            Text(
                showsDemoBadge
                    ? "coach.evidence.demo_badge"
                    : kindLabel
            )
        )
    }
}

struct WinnerPosterImage: View {
    let reference: String?
    let alternativeText: String

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ContentUnavailableView(
                    "Poster belum tersedia",
                    systemImage: "photo",
                    description: Text(
                        "Admin perlu memilih gambar poster pemenang."
                    )
                )
                .background(Color.appSecondaryBackground)
            }
        }
        .aspectRatio(9.0 / 16.0, contentMode: .fit)
        .clipShape(
            RoundedRectangle(
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(alternativeText))
        .accessibilityAddTraits(.isImage)
    }

    private var image: UIImage? {
        guard let reference, !reference.isEmpty else { return nil }
        if FileManager.default.fileExists(atPath: reference),
           let localImage = UIImage(contentsOfFile: reference) {
            return localImage
        }
        return UIImage(named: reference)
    }
}

#Preview("Avatar") {
    HStack {
        UserAvatar(displayName: "Ayu Lestari")
        UserAvatar(displayName: "Coach Raka", size: 72)
    }
    .padding()
}

#Preview("Media") {
    MediaThumbnail(
        title: "preview.media.title",
        systemImage: "play.rectangle.fill",
        kindLabel: "preview.media.video"
    )
    .padding()
}
