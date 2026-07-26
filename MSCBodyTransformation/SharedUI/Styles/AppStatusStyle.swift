import SwiftUI

enum AppStatusKind: String, CaseIterable, Identifiable, Sendable {
    case neutral
    case information
    case success
    case warning
    case error
    case pending
    case locked

    var id: String { rawValue }
}

struct AppStatusStyle {
    let foregroundColor: Color
    let backgroundColor: Color
    let systemImage: String

    static func style(for kind: AppStatusKind) -> Self {
        switch kind {
        case .neutral:
            Self(
                foregroundColor: .appSecondaryText,
                backgroundColor: .appBorder.opacity(0.32),
                systemImage: "circle"
            )
        case .information:
            Self(
                foregroundColor: .appInfo,
                backgroundColor: .appInfo.opacity(0.14),
                systemImage: "info.circle.fill"
            )
        case .success:
            Self(
                foregroundColor: .appSuccess,
                backgroundColor: .appSuccess.opacity(0.14),
                systemImage: "checkmark.circle.fill"
            )
        case .warning:
            Self(
                foregroundColor: .appWarning,
                backgroundColor: .brandAccent.opacity(0.24),
                systemImage: "exclamationmark.triangle.fill"
            )
        case .error:
            Self(
                foregroundColor: .appDestructive,
                backgroundColor: .appDestructive.opacity(0.14),
                systemImage: "xmark.circle.fill"
            )
        case .pending:
            Self(
                foregroundColor: .appWarning,
                backgroundColor: .brandAccent.opacity(0.24),
                systemImage: "clock.fill"
            )
        case .locked:
            Self(
                foregroundColor: .appSecondaryText,
                backgroundColor: .appBorder.opacity(0.32),
                systemImage: "lock.fill"
            )
        }
    }
}
