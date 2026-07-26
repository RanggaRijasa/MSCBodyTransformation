import Foundation

nonisolated struct LoadCurrentSessionUseCase: Sendable {
    let repository: any SessionRepository

    func callAsFunction() async throws -> AppSession {
        try await repository.loadCurrentSession()
    }
}

nonisolated struct SwitchDebugRoleUseCase: Sendable {
    let repository: any SessionRepository

    func callAsFunction(role: UserRole) async throws -> AppSession {
        try await repository.switchDebugRole(to: role)
    }
}
