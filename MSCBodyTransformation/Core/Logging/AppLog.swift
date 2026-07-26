import Foundation
import OSLog

enum AppLog {
    private static let subsystem =
        Bundle.main.bundleIdentifier ?? "MSCBodyTransformation"

    static let lifecycle = Logger(
        subsystem: subsystem,
        category: "lifecycle"
    )

    static let navigation = Logger(
        subsystem: subsystem,
        category: "navigation"
    )

    static let localDemo = Logger(
        subsystem: subsystem,
        category: "local-demo"
    )
}
