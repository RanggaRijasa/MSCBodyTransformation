import Foundation

nonisolated struct AppConfiguration: Equatable, Sendable {
    enum Mode: String, Equatable, Sendable {
        case localDemo = "local_demo"
    }

    enum Build: String, Equatable, Sendable {
        case debug
        case release

        static var current: Self {
#if DEBUG
            .debug
#else
            .release
#endif
        }
    }

    static let indonesianLocaleIdentifier = "id-ID"

    let mode: Mode
    let build: Build
    let localeIdentifier: String

    static var localDemo: Self {
        Self(
            mode: .localDemo,
            build: .current,
            localeIdentifier: indonesianLocaleIdentifier
        )
    }

    var locale: Locale {
        Locale(identifier: localeIdentifier)
    }
}
