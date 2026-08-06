import Foundation
import Security

nonisolated protocol SessionSecureStoring: Sendable {
    func loadSession() async throws -> AuthSessionMaterial?
    func saveSession(_ session: AuthSessionMaterial) async throws
    func deleteSession() async throws
    func loadPendingEnrollmentIntent() async throws -> PendingEnrollmentIntent?
    func savePendingEnrollmentIntent(
        _ intent: PendingEnrollmentIntent
    ) async throws
    func deletePendingEnrollmentIntent() async throws
    func loadOAuthAttempt() async throws -> OAuthAuthorizationAttempt?
    func saveOAuthAttempt(_ attempt: OAuthAuthorizationAttempt) async throws
    func deleteOAuthAttempt() async throws
    func loadPendingRegistrationDraft() async throws -> PendingRegistrationDraft?
    func savePendingRegistrationDraft(_ draft: PendingRegistrationDraft) async throws
    func deletePendingRegistrationDraft() async throws
    func deleteAll() async throws
}

actor KeychainSessionSecureStore: SessionSecureStoring {
    private enum Account: String {
        case session
        case pendingEnrollment = "pending_enrollment"
        case oauthAttempt = "oauth_attempt"
        case pendingRegistration = "pending_registration"
    }

    private let service: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(service: String = "id.msc.body-transformation.auth") {
        self.service = service
    }

    func loadSession() throws -> AuthSessionMaterial? {
        try load(AuthSessionMaterial.self, account: .session)
    }

    func saveSession(_ session: AuthSessionMaterial) throws {
        try save(session, account: .session)
    }

    func deleteSession() throws {
        try delete(account: .session)
    }

    func loadPendingEnrollmentIntent() throws -> PendingEnrollmentIntent? {
        try load(PendingEnrollmentIntent.self, account: .pendingEnrollment)
    }

    func savePendingEnrollmentIntent(
        _ intent: PendingEnrollmentIntent
    ) throws {
        try save(intent, account: .pendingEnrollment)
    }

    func deletePendingEnrollmentIntent() throws {
        try delete(account: .pendingEnrollment)
    }

    func loadOAuthAttempt() throws -> OAuthAuthorizationAttempt? {
        try load(OAuthAuthorizationAttempt.self, account: .oauthAttempt)
    }

    func saveOAuthAttempt(_ attempt: OAuthAuthorizationAttempt) throws {
        try save(attempt, account: .oauthAttempt)
    }

    func deleteOAuthAttempt() throws {
        try delete(account: .oauthAttempt)
    }

    func loadPendingRegistrationDraft() throws -> PendingRegistrationDraft? {
        try load(PendingRegistrationDraft.self, account: .pendingRegistration)
    }

    func savePendingRegistrationDraft(_ draft: PendingRegistrationDraft) throws {
        try save(draft, account: .pendingRegistration)
    }

    func deletePendingRegistrationDraft() throws {
        try delete(account: .pendingRegistration)
    }

    func deleteAll() throws {
        for account in [
            Account.session,
            .pendingEnrollment,
            .oauthAttempt,
            .pendingRegistration
        ] {
            try delete(account: account)
        }
    }

    private func load<Value: Decodable>(
        _ type: Value.Type,
        account: Account
    ) throws -> Value? {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess, let data = result as? Data else {
            throw AuthenticationError.unknown
        }
        do {
            return try decoder.decode(type, from: data)
        } catch {
            try? delete(account: account)
            throw AuthenticationError.sessionExpired
        }
    }

    private func save<Value: Encodable>(
        _ value: Value,
        account: Account
    ) throws {
        let data = try encoder.encode(value)
        let query = baseQuery(account: account)
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String:
                kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecAttrSynchronizable as String: false
        ]
        let updateStatus = SecItemUpdate(
            query as CFDictionary,
            attributes as CFDictionary
        )
        if updateStatus == errSecSuccess {
            return
        }
        guard updateStatus == errSecItemNotFound else {
            throw AuthenticationError.unknown
        }
        var insertion = query
        attributes.forEach { insertion[$0.key] = $0.value }
        guard SecItemAdd(insertion as CFDictionary, nil) == errSecSuccess else {
            throw AuthenticationError.unknown
        }
    }

    private func delete(account: Account) throws {
        let status = SecItemDelete(baseQuery(account: account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AuthenticationError.unknown
        }
    }

    private func baseQuery(account: Account) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account.rawValue,
            kSecAttrSynchronizable as String: false
        ]
    }
}

actor InMemorySessionSecureStore: SessionSecureStoring {
    private var session: AuthSessionMaterial?
    private var pendingEnrollmentIntent: PendingEnrollmentIntent?
    private var oauthAttempt: OAuthAuthorizationAttempt?
    private var pendingRegistrationDraft: PendingRegistrationDraft?

    func loadSession() -> AuthSessionMaterial? { session }
    func saveSession(_ session: AuthSessionMaterial) { self.session = session }
    func deleteSession() { session = nil }

    func loadPendingEnrollmentIntent() -> PendingEnrollmentIntent? {
        pendingEnrollmentIntent
    }

    func savePendingEnrollmentIntent(_ intent: PendingEnrollmentIntent) {
        pendingEnrollmentIntent = intent
    }

    func deletePendingEnrollmentIntent() {
        pendingEnrollmentIntent = nil
    }

    func loadOAuthAttempt() -> OAuthAuthorizationAttempt? { oauthAttempt }
    func saveOAuthAttempt(_ attempt: OAuthAuthorizationAttempt) {
        oauthAttempt = attempt
    }
    func deleteOAuthAttempt() { oauthAttempt = nil }

    func loadPendingRegistrationDraft() -> PendingRegistrationDraft? {
        pendingRegistrationDraft
    }
    func savePendingRegistrationDraft(_ draft: PendingRegistrationDraft) {
        pendingRegistrationDraft = draft
    }
    func deletePendingRegistrationDraft() {
        pendingRegistrationDraft = nil
    }

    func deleteAll() {
        session = nil
        pendingEnrollmentIntent = nil
        oauthAttempt = nil
        pendingRegistrationDraft = nil
    }
}
