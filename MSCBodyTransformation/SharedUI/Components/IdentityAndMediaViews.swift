import SwiftUI
import UIKit

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

struct MediaThumbnail: View {
    let title: LocalizedStringKey
    let systemImage: String
    let kindLabel: LocalizedStringKey

    var body: some View {
        ZStack {
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
        .accessibilityValue(Text(kindLabel))
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
