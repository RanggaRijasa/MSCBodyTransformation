import Foundation

nonisolated struct UUIDIdentifierGenerator: IdentifierGenerating {
    func makeIdentifier() -> UUID {
        UUID()
    }
}
