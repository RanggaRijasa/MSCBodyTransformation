import Foundation

nonisolated struct FixedClock: AppClock {
    let fixedDate: Date

    init(now fixedDate: Date) {
        self.fixedDate = fixedDate
    }

    func now() -> Date {
        fixedDate
    }
}
