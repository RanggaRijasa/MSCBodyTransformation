import Foundation

nonisolated struct UsersFixture: Codable, Sendable {
    let users: [AppUser]
    let participantProfiles: [ParticipantProfile]
}

nonisolated struct CoachesFixture: Codable, Sendable {
    let coachProfiles: [CoachProfile]
}

nonisolated struct ProgramsFixture: Codable, Sendable {
    let programs: [Program]
}

nonisolated struct EnrollmentsFixture: Codable, Sendable {
    let enrollments: [ProgramEnrollment]
    let weighIns: [WeighIn]
}

nonisolated struct SubmissionsFixture: Codable, Sendable {
    let submissions: [StepSubmission]
}

nonisolated struct LeaderboardFixture: Codable, Sendable {
    let entries: [LeaderboardEntry]
    let winners: [ProgramWinner]
}

nonisolated struct ManagedContentFixture: Codable, Sendable {
    let content: [ManagedContent]
    let auditEvents: [AuditEvent]
}

nonisolated struct FixtureDecoder: Sendable {
    private let decoder: JSONDecoder

    init() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func decode<Value: Decodable & Sendable>(
        _ type: Value.Type,
        from data: Data,
        fileName: String
    ) throws -> Value {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw DomainError.invalidFixture(
                file: fileName,
                reason: String(describing: error)
            )
        }
    }
}

nonisolated final class FixtureBundleAnchor: NSObject {}

nonisolated struct LocalFixtureLoader: Sendable {
    private let bundle: Bundle
    private let decoder: FixtureDecoder

    init(
        bundle: Bundle = Bundle(for: FixtureBundleAnchor.self),
        decoder: FixtureDecoder = FixtureDecoder()
    ) {
        self.bundle = bundle
        self.decoder = decoder
    }

    func load<Value: Decodable & Sendable>(
        _ type: Value.Type,
        fileName: String
    ) throws -> Value {
        guard let url = bundle.url(
            forResource: fileName,
            withExtension: "json",
            subdirectory: "Fixtures"
        ) ?? bundle.url(forResource: fileName, withExtension: "json") else {
            throw DomainError.invalidFixture(
                file: "\(fileName).json",
                reason: "File fixture tidak ditemukan di app bundle."
            )
        }

        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(
                type,
                from: data,
                fileName: "\(fileName).json"
            )
        } catch let error as DomainError {
            throw error
        } catch {
            throw DomainError.invalidFixture(
                file: "\(fileName).json",
                reason: String(describing: error)
            )
        }
    }
}
