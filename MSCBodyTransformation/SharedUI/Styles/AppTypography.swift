import SwiftUI

enum AppTypography {
    static let screenTitle = Font.largeTitle.weight(.bold)
    static let sectionTitle = Font.title2.weight(.semibold)
    static let cardTitle = Font.headline.weight(.semibold)
    static let body = Font.body
    static let secondary = Font.subheadline
    static let label = Font.caption.weight(.medium)
    static let metric = Font.title.monospacedDigit().weight(.bold)
    static let button = Font.headline.weight(.semibold)
}

enum AppMotion {
    static let quickDuration = 0.18
    static let standardDuration = 0.28

    static func quick(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .easeOut(duration: quickDuration)
    }

    static func standard(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .snappy(duration: standardDuration)
    }
}
