import SwiftUI

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
            if let imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(initials)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.brandPrimary)
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

    private var initials: String {
        displayName
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
            .uppercased()
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
