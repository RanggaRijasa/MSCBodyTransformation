import Foundation

nonisolated protocol AppClock: Sendable {
    func now() -> Date
}
