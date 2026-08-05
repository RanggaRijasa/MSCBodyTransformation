import Foundation
import Observation

@MainActor
@Observable
final class CoachLeaderboardState {
    private let environment: AppEnvironment
    private let service: CoachDataService

    var state: CoachFeatureLoadState<CoachLeaderboardSnapshot> = .idle
    var selectedProgramID: UUID?

    init(environment: AppEnvironment) {
        self.environment = environment
        service = CoachDataService(environment: environment)
    }

    func load() async {
        state = .loading
        do {
            let identity = try await service.identity()
            guard let repositories = environment.repositories else {
                throw environment.bootstrapError ?? DomainError.unknown
            }
            let referenceDate = environment.clock.now()
            let programs = try await repositories.programs.programs()
                .filter {
                    let status = $0.lifecycleStatus(at: referenceDate)
                    return status == .active
                        || status == .completed
                        || status == .archived
                }
                .sorted { $0.endDate > $1.endDate }
            guard let selectedProgram = programs.first(where: {
                $0.id == selectedProgramID
            }) ?? programs.first(where: {
                $0.lifecycleStatus(at: referenceDate) == .active
            }) ?? programs.first else {
                throw DomainError.notFound(resource: "program")
            }
            selectedProgramID = selectedProgram.id
            let entries = try await repositories.leaderboard.leaderboard(
                programID: selectedProgram.id
            )
            let winners = try await repositories.leaderboard.winners(
                programID: selectedProgram.id
            )
            let participantIDs = Set(
                try await repositories.coachParticipants
                    .assignedParticipants(coachID: identity.profile.id)
                    .map(\.id)
            )
            guard !Task.isCancelled else {
                return
            }
            state = .loaded(
                CoachLeaderboardSnapshot(
                    programs: programs,
                    selectedProgram: selectedProgram,
                    entries: entries,
                    winners: winners,
                    assignedParticipantIDs: participantIDs,
                    referenceDate: referenceDate
                )
            )
        } catch is CancellationError {
            return
        } catch let error as DomainError {
            state = .failed(error)
        } catch {
            state = .failed(.unknown)
        }
    }

    func selectProgram(_ id: UUID) async {
        selectedProgramID = id
        await load()
    }
}

@MainActor
@Observable
final class CoachProfileState {
    private let environment: AppEnvironment
    private let service: CoachDataService

    var isLocalDemo: Bool {
        environment.configuration.mode == .localDemo
    }

    var state: CoachFeatureLoadState<CoachProfileSnapshot> = .idle
    var displayName = ""
    var biography = ""
    var city = ""
    var localPhotoReference: String?
    var isPublic = true
    var notificationsEnabled = true
    var isSaving = false
    var saveConfirmationVisible = false
    var isLoggedOut = false

    init(environment: AppEnvironment) {
        self.environment = environment
        service = CoachDataService(environment: environment)
    }

    func load() async {
        state = .loading
        do {
            let identity = try await service.identity()
            displayName = identity.profile.displayName
            biography = identity.profile.biography
            city = identity.profile.city
            localPhotoReference = identity.profile.localPhotoReference
            isPublic = identity.profile.isPublic
            guard !Task.isCancelled else {
                return
            }
            state = .loaded(
                CoachProfileSnapshot(
                    user: identity.user,
                    profile: identity.profile
                )
            )
        } catch is CancellationError {
            return
        } catch let error as DomainError {
            state = .failed(error)
        } catch {
            state = .failed(.unknown)
        }
    }

    func save(
        displayName: String,
        biography: String,
        city: String,
        localPhotoReference: String?
    ) async throws {
        guard let repositories = environment.repositories,
              case .loaded(let snapshot) = state else {
            throw DomainError.unknown
        }
        let normalizedName = displayName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let normalizedBiography = biography.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let normalizedCity = city.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !normalizedName.isEmpty else {
            throw DomainError.validation(
                field: "displayName",
                reason: "Nama publik wajib diisi."
            )
        }
        guard !normalizedBiography.isEmpty else {
            throw DomainError.validation(
                field: "biography",
                reason: "Bio wajib diisi."
            )
        }
        guard !normalizedCity.isEmpty else {
            throw DomainError.validation(
                field: "city",
                reason: "Kota wajib diisi."
            )
        }

        isSaving = true
        defer { isSaving = false }
        var profile = snapshot.profile
        profile.displayName = normalizedName
        profile.biography = normalizedBiography
        profile.city = normalizedCity
        profile.localPhotoReference = localPhotoReference
        profile.isPublic = isPublic
        _ = try await repositories.profiles.save(coachProfile: profile)
        saveConfirmationVisible = true
        await load()
    }

    func saveSettings() async throws {
        try await save(
            displayName: displayName,
            biography: biography,
            city: city,
            localPhotoReference: localPhotoReference
        )
    }

    func logoutLocalDemo() async {
        if isLocalDemo {
            await environment.repositories?.session
                .setDebugScenario(.loggedOut)
        } else {
            try? await environment.repositories?.session.signOut()
        }
        isLoggedOut = true
    }

    func resumeLocalDemo() async {
        guard let session = environment.repositories?.session else {
            return
        }
        _ = try? await session.switchDebugRole(to: .coach)
        isLoggedOut = false
        await load()
    }
}
