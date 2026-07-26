import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

nonisolated struct LocalInvitePayload: Equatable, Sendable {
    let opaqueToken: String
}

nonisolated struct LocalInvitePayloadParser: Sendable {
    static let approvedScheme = "msc-demo"
    static let approvedHost = "join"

    func payload(from url: URL) throws -> LocalInvitePayload {
        guard url.scheme?.lowercased() == Self.approvedScheme,
              url.host?.lowercased() == Self.approvedHost else {
            throw DomainError.validation(
                field: "qrPayload",
                reason: "QR bukan undangan lokal MSC."
            )
        }
        let components = url.pathComponents.filter { $0 != "/" }
        guard components.count == 1 else {
            throw DomainError.validation(
                field: "qrPayload",
                reason: "Format undangan lokal tidak valid."
            )
        }
        let token = components[0].uppercased()
        let allowed = CharacterSet.alphanumerics.union(
            CharacterSet(charactersIn: "-_")
        )
        guard (4...128).contains(token.count),
              token.unicodeScalars.allSatisfy({
                  allowed.contains($0)
              }) else {
            throw DomainError.validation(
                field: "qrPayload",
                reason: "Token undangan lokal tidak valid."
            )
        }
        return LocalInvitePayload(opaqueToken: token)
    }

    func payload(from string: String) throws -> LocalInvitePayload {
        guard let url = URL(string: string) else {
            throw DomainError.validation(
                field: "qrPayload",
                reason: "QR tidak berisi URL yang valid."
            )
        }
        return try payload(from: url)
    }

    func url(forOpaqueToken token: String) throws -> URL {
        let normalized = token
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        guard let url = URL(
            string: "\(Self.approvedScheme)://"
                + "\(Self.approvedHost)/\(normalized)"
        ) else {
            throw DomainError.validation(
                field: "qrPayload",
                reason: "Token undangan lokal tidak valid."
            )
        }
        _ = try payload(from: url)
        return url
    }
}

nonisolated struct LocalQRCodeGenerator: Sendable {
    func image(
        payload: String,
        scale: CGFloat = 12,
        paddingModules: CGFloat = 3
    ) -> CGImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else {
            return nil
        }

        let scaled = output.transformed(
            by: CGAffineTransform(scaleX: scale, y: scale)
        )
        let padding = paddingModules * scale
        let extent = scaled.extent.insetBy(dx: -padding, dy: -padding)
        let background = CIImage(
            color: CIColor(red: 1, green: 1, blue: 1)
        ).cropped(to: extent)
        let padded = scaled.composited(over: background)
        return CIContext(options: [.useSoftwareRenderer: false])
            .createCGImage(padded, from: extent)
    }
}
