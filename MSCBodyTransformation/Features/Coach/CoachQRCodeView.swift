import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

struct CoachQRCodeView: View {
    let payload: String

    var body: some View {
        Group {
            if let image = makeImage() {
                Image(decorative: image, scale: 1)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            } else {
                ContentUnavailableView(
                    "coach.invite.qr.error.title",
                    systemImage: "qrcode",
                    description: Text("coach.invite.qr.error.message")
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
        .accessibilityLabel(Text("coach.invite.qr.accessibility"))
    }

    private func makeImage() -> CGImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "M"
        guard let outputImage = filter.outputImage else {
            return nil
        }
        let scaledImage = outputImage.transformed(
            by: CGAffineTransform(scaleX: 12, y: 12)
        )
        return CIContext(options: [.useSoftwareRenderer: false])
            .createCGImage(scaledImage, from: scaledImage.extent)
    }
}
