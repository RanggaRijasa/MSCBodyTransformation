import Foundation
import SwiftUI

nonisolated struct AppEnvironment: Sendable {
    let configuration: AppConfiguration
    let clock: any AppClock
    let identifierGenerator: any IdentifierGenerating
    let repositories: AppRepositories?
    let bootstrapError: DomainError?

    static var live: Self {
        makeLocalDemoEnvironment(
            clock: SystemClock(),
            identifierGenerator: UUIDIdentifierGenerator()
        )
    }

    static var preview: Self {
        makeLocalDemoEnvironment(
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
        clock: any AppClock,
        identifierGenerator: any IdentifierGenerating
    ) -> Self {
        do {
            let repository = InMemoryAppRepository(
                seed: try MockSeedData.load()
            )
            return Self(
                configuration: .localDemo,
                clock: clock,
                identifierGenerator: identifierGenerator,
                repositories: AppRepositories(repository: repository),
                bootstrapError: nil
            )
        } catch let error as DomainError {
            return Self(
                configuration: .localDemo,
                clock: clock,
                identifierGenerator: identifierGenerator,
                repositories: nil,
                bootstrapError: error
            )
        } catch {
            return Self(
                configuration: .localDemo,
                clock: clock,
                identifierGenerator: identifierGenerator,
                repositories: nil,
                bootstrapError: .unknown
            )
        }
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
