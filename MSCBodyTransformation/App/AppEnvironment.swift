import Foundation
import SwiftUI

nonisolated struct AppEnvironment: Sendable {
    let configuration: AppConfiguration
    let clock: any AppClock
    let identifierGenerator: any IdentifierGenerating
    let repositories: AppRepositories?
    let commerce: CommerceCoordinator?
    let bootstrapError: DomainError?

    init(
        configuration: AppConfiguration,
        clock: any AppClock,
        identifierGenerator: any IdentifierGenerating,
        repositories: AppRepositories?,
        commerce: CommerceCoordinator? = nil,
        bootstrapError: DomainError?
    ) {
        self.configuration = configuration
        self.clock = clock
        self.identifierGenerator = identifierGenerator
        self.repositories = repositories
        self.commerce = commerce
        self.bootstrapError = bootstrapError
    }

    @MainActor static var live: Self {
        let clock = SystemClock()
        let identifiers = UUIDIdentifierGenerator()
        do {
            let configuration = try AppConfiguration.load()
            switch configuration.mode {
            case .localDemo:
                return makeLocalDemoEnvironment(
                    configuration: configuration,
                    clock: clock,
                    identifierGenerator: identifiers
                )
            case .debugLocalSupabase, .hostedProduction:
                return try makeSupabaseEnvironment(
                    configuration: configuration,
                    clock: clock,
                    identifierGenerator: identifiers
                )
            }
        } catch {
            return Self(
                configuration: .unavailable(build: .current),
                clock: clock,
                identifierGenerator: identifiers,
                repositories: nil,
                commerce: nil,
                bootstrapError: .validation(
                    field: "appConfiguration",
                    reason: "Konfigurasi aplikasi belum lengkap."
                )
            )
        }
    }

    static var preview: Self {
        makeLocalDemoEnvironment(
            configuration: .localDemo,
            clock: FixedClock(
                now: Date(timeIntervalSince1970: 1_785_028_400)
            ),
            identifierGenerator: DeterministicIdentifierGenerator(
                identifier: UUID(
                    uuid: (
                        0, 0, 0, 0,
                        0, 0,
                        0, 0,
                        0, 0,
                        0, 0, 0, 0, 0, 1
                    )
                )
            )
        )
    }

    private static func makeLocalDemoEnvironment(
        configuration: AppConfiguration,
        clock: any AppClock,
        identifierGenerator: any IdentifierGenerating
    ) -> Self {
        do {
            let repository = InMemoryAppRepository(seed: try MockSeedData.load())
            return Self(
                configuration: configuration,
                clock: clock,
                identifierGenerator: identifierGenerator,
                repositories: AppRepositories(repository: repository),
                commerce: nil,
                bootstrapError: nil
            )
        } catch let error as DomainError {
            return Self(
                configuration: configuration,
                clock: clock,
                identifierGenerator: identifierGenerator,
                repositories: nil,
                commerce: nil,
                bootstrapError: error
            )
        } catch {
            return Self(
                configuration: configuration,
                clock: clock,
                identifierGenerator: identifierGenerator,
                repositories: nil,
                commerce: nil,
                bootstrapError: .unknown
            )
        }
    }

    @MainActor private static func makeSupabaseEnvironment(
        configuration: AppConfiguration,
        clock: any AppClock,
        identifierGenerator: any IdentifierGenerating
    ) throws -> Self {
        guard let projectURL = configuration.supabaseURL,
              let publishableKey = configuration.supabasePublishableKey else {
            throw AuthenticationError.validation
        }
        let runtimeConfiguration = try SupabaseRuntimeConfiguration(
            projectURL: projectURL,
            publishableKey: publishableKey
        )
        let secureStore = KeychainSessionSecureStore()
        let authClient = URLSessionSupabaseAuthClient(
            configuration: runtimeConfiguration
        )
        let profileClient = URLSessionSupabaseProfileClient(
            configuration: runtimeConfiguration
        )
        let accountDeletionClient = URLSessionSupabaseAccountDeletionClient(
            configuration: runtimeConfiguration
        )
        let sessionRepository = SupabaseSessionRepository(
            authClient: authClient,
            profileClient: profileClient,
            secureStore: secureStore,
            clock: clock,
            environmentIdentifier: configuration.environmentIdentifier
        )
        let externalAuthentication = NativeProviderAuthenticationCoordinator(
            authClient: authClient,
            profileClient: profileClient,
            secureStore: secureStore,
            configuration: configuration,
            clock: clock
        )
        let authenticationRepository = SupabaseAuthenticationRepository(
            sessionRepository: sessionRepository,
            profileClient: profileClient,
            accountDeletionClient: accountDeletionClient,
            externalAuthentication: externalAuthentication,
            secureStore: secureStore,
            clock: clock,
            environmentIdentifier: configuration.environmentIdentifier
        )
        let publicClient = URLSessionSupabaseClient(
            configuration: runtimeConfiguration,
            authorization: .publicAnon
        )
        let authenticatedClient = URLSessionSupabaseClient(
            configuration: runtimeConfiguration,
            accessTokenProvider: SessionSupabaseAccessTokenProvider(
                sessionRepository: sessionRepository
            )
        )
        let phase11Repository = SupabasePhase11Repository(
            client: authenticatedClient,
            sessionRepository: sessionRepository,
            profileClient: profileClient
        )
        let commerceRepository = SupabaseCommerceRepository(
            client: authenticatedClient
        )
        let commerce = CommerceCoordinator(
            service: StoreKitProgramPurchaseService(
                server: commerceRepository
            ),
            sessionRepository: sessionRepository
        )
        return Self(
            configuration: configuration,
            clock: clock,
            identifierGenerator: identifierGenerator,
            repositories: AppRepositories(
                session: sessionRepository,
                authentication: authenticationRepository,
                profiles: phase11Repository,
                authenticatedParticipantReads:
                    SupabaseAuthenticatedParticipantReadRepository(
                        client: authenticatedClient
                    ),
                publicCoachDirectory:
                    SupabasePublicCoachDirectoryRepository(
                        client: publicClient
                    ),
                publicPrograms: SupabasePublicProgramRepository(
                    client: publicClient
                ),
                publicLeaderboard: SupabasePublicLeaderboardRepository(
                    client: publicClient
                ),
                publicManagedContent:
                    SupabasePublicManagedContentRepository(
                        client: publicClient
                ),
                phase11Repository: phase11Repository
            ),
            commerce: commerce,
            bootstrapError: nil
        )
    }
}

private struct AppEnvironmentKey: EnvironmentKey {
    static let defaultValue = AppEnvironment.live
}

extension EnvironmentValues {
    var appEnvironment: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}
