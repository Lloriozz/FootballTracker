import Foundation
import SwiftUI

// MARK: - Match list models (used by Team + League fixtures)

struct Match: Identifiable, Codable, Hashable {
    let id: String
    let competition: String
    let competitionId: String
    let competitionLogo: String
    let round: String
    let status: MatchStatus
    let elapsed: Int?
    let kickoff: String          // ISO-8601 string, parsed on display
    let homeTeam: Team
    let awayTeam: Team
    let homeScore: Int?
    let awayScore: Int?
    let isFavorite: Bool

    var kickoffDate: Date? {
        ISO8601DateFormatter().date(from: kickoff)
    }
}

enum MatchStatus: String, Codable, Hashable {
    case scheduled
    case live
    case finished

    var displayName: String {
        switch self {
        case .scheduled: "Scheduled"
        case .live: "Live"
        case .finished: "Final"
        }
    }
}

struct Team: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let shortName: String
    /// URL string to the team logo image from API-Football CDN.
    let emblem: String
    let primaryColorHex: String
    let secondaryColorHex: String

    var primaryColor: Color { Color(hex: primaryColorHex) }
    var secondaryColor: Color { Color(hex: secondaryColorHex) }
}

// MARK: - Competition (for League browsing)

struct Competition: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let icon: String
    let status: String
    let hasTeams: Bool
}

// MARK: - Team stat (for match detail)

struct TeamStat: Codable, Hashable, Identifiable {
    var id: String { label }
    let label: String
    let home: Int
    let away: Int
}

// MARK: - New Models added for restructure

enum Season: Int, Codable, Hashable, CaseIterable {
    case s2022 = 2022
    case s2023 = 2023
    case s2024 = 2024
    
    var year: Int { rawValue }
    var label: String { "\(rawValue)-\(rawValue + 1)" }
}

struct FootballTeam: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let country: String?
    let logo: String?
    let shortName: String?
    let emblem: String?
}

struct LeagueInfo: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let country: String
    let icon: String?
    let flag: String?
}

struct Player: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let photo: String?
    let nationality: String?
    let age: Int?
    let injured: Bool?
    let statistics: [PlayerStat]?
}

struct PlayerStat: Identifiable, Codable, Hashable {
    var id: String { teamName }
    let teamName: String
    let teamLogo: String
    let leagueName: String
    let season: Int?
    let position: String
    let appearances: Int
    let goals: Int
    let assists: Int
    let rating: Double?
}
