import Foundation

nonisolated struct AppConfiguration: Equatable, Sendable {
    enum Mode: String, Equatable, Sendable {
        case localDemo = "local_demo"
        case debugLocalSupabase = "debug_local_supabase"
        case hostedProduction = "hosted_production"
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
    static let modeEnvironmentKey = "MSC_APP_MODE"
    static let privacyPolicyURLEnvironmentKey = "MSC_PRIVACY_POLICY_URL"
    static let termsOfUseURLEnvironmentKey = "MSC_TERMS_OF_USE_URL"
    static let callbackURL = URL(
        string: "mscbodytransformation://auth/callback"
    )!

    let mode: Mode
    let build: Build
    let localeIdentifier: String
    let isEmailPasswordAuthenticationVisible: Bool
    let supabaseURL: URL?
    let supabasePublishableKey: String?

    static var localDemo: Self {
        Self(
            mode: .localDemo,
            build: .current,
            localeIdentifier: indonesianLocaleIdentifier,
            isEmailPasswordAuthenticationVisible: false,
            supabaseURL: nil,
            supabasePublishableKey: nil
        )
    }

    static func unavailable(build: Build) -> Self {
        Self(
            mode: build == .debug ? .debugLocalSupabase : .hostedProduction,
            build: build,
            localeIdentifier: indonesianLocaleIdentifier,
            isEmailPasswordAuthenticationVisible: false,
            supabaseURL: nil,
            supabasePublishableKey: nil
        )
    }

    static func load(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        bundledConfiguration: [String: String]? = nil,
        build: Build = .current
    ) throws -> Self {
        let configurationValues = build == .release
            ? (bundledConfiguration ?? releaseConfigurationFromMainBundle())
            : environment
        let defaultMode: Mode = build == .debug
            ? .localDemo
            : .hostedProduction
        let mode: Mode
        if let rawMode = configurationValues[modeEnvironmentKey] {
            guard let parsedMode = Mode(rawValue: rawMode) else {
                throw AuthenticationError.validation
            }
            mode = parsedMode
        } else {
            mode = defaultMode
        }

        if mode == .localDemo {
            guard build == .debug else {
                throw AuthenticationError.validation
            }
            return Self(
                mode: mode,
                build: build,
                localeIdentifier: indonesianLocaleIdentifier,
                isEmailPasswordAuthenticationVisible: false,
                supabaseURL: nil,
                supabasePublishableKey: nil
            )
        }

        guard let rawURL = configurationValues[
            SupabaseRuntimeConfiguration.urlEnvironmentKey
        ], let url = URL(string: rawURL),
              let scheme = url.scheme?.lowercased(),
              let host = url.host?.lowercased(),
              let publishableKey = configurationValues[
                SupabaseRuntimeConfiguration.publishableKeyEnvironmentKey
              ], !publishableKey.trimmingCharacters(
                in: .whitespacesAndNewlines
              ).isEmpty else {
            throw AuthenticationError.validation
        }

        switch mode {
        case .localDemo:
            throw AuthenticationError.validation
        case .debugLocalSupabase:
            guard build == .debug,
                  scheme == "http" || scheme == "https",
                  isLocalDevelopmentHost(host) else {
                throw AuthenticationError.validation
            }
        case .hostedProduction:
            guard scheme == "https", !isLocalDevelopmentHost(host) else {
                throw AuthenticationError.validation
            }
        }

        return Self(
            mode: mode,
            build: build,
            localeIdentifier: indonesianLocaleIdentifier,
            isEmailPasswordAuthenticationVisible: false,
            supabaseURL: url,
            supabasePublishableKey: publishableKey
        )
    }

    var locale: Locale {
        Locale(identifier: localeIdentifier)
    }

    var environmentIdentifier: String {
        mode.rawValue
    }

    private static func isLocalDevelopmentHost(_ host: String) -> Bool {
        host == "localhost"
            || host == "127.0.0.1"
            || host == "::1"
            || host.hasSuffix(".local")
            || host.hasPrefix("10.")
            || host.hasPrefix("192.168.")
            || (host.hasPrefix("172.") && isPrivate172Host(host))
    }

    private static func isPrivate172Host(_ host: String) -> Bool {
        let components = host.split(separator: ".")
        guard components.count == 4,
              let second = Int(components[1]) else {
            return false
        }
        return (16...31).contains(second)
    }

    private static func releaseConfigurationFromMainBundle() -> [String: String] {
        let keys = [
            modeEnvironmentKey,
            SupabaseRuntimeConfiguration.urlEnvironmentKey,
            SupabaseRuntimeConfiguration.publishableKeyEnvironmentKey,
            privacyPolicyURLEnvironmentKey,
            termsOfUseURLEnvironmentKey
        ]

        return keys.reduce(into: [:]) { result, key in
            if let value = Bundle.main.object(
                forInfoDictionaryKey: key
            ) as? String {
                result[key] = value
            }
        }
    }
}
