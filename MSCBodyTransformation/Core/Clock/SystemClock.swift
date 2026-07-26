import Foundation

nonisolated struct SystemClock: AppClock {
    func now() -> Date {
        Date.now
    }
}
