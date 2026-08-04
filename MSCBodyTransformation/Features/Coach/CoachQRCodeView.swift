import SwiftUI

struct CoachQRCodeView: View {
    let payload: String
    let coachName: String

    var body: some View {
        Group {
            if let image = LocalQRCodeGenerator().image(
                payload: payload
            ) {
                Image(decorative: image, scale: 1)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            } else {
                ContentUnavailableView(
                    "coach.identifier.qr.error.title",
                    systemImage: "qrcode",
                    description: Text("coach.identifier.qr.error.message")
                )
            }
        }
        .frame(maxWidth: 260, minHeight: 220, maxHeight: 260)
        .padding(AppSpacing.medium)
        .background(
            Color.white,
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "QR pendaftaran milik \(coachName)"
        )
    }
}
