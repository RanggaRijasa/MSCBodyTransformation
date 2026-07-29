import SwiftUI

struct ParticipantLeaderboardRankStyle {
    let accentColor: Color
    let surfaceColor: Color
    let rankForegroundColor: Color

    init(rank: Int) {
        switch rank {
        case 1:
            accentColor = .brandAccent
            surfaceColor = Color.brandAccent.opacity(0.18)
            rankForegroundColor = .black
        case 2:
            accentColor = .appSecondaryText
            surfaceColor = Color.appSecondaryText.opacity(0.1)
            rankForegroundColor = .appBackground
        case 3:
            accentColor = .podiumBronze
            surfaceColor = Color.podiumBronze.opacity(0.12)
            rankForegroundColor = .black
        default:
            accentColor = .appBorder
            surfaceColor = .appSurface
            rankForegroundColor = .appPrimaryText
        }
    }
}
