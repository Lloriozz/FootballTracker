import Foundation
import Observation
import SwiftUI

/// Global app state shared through SwiftUI's environment.
@Observable @MainActor
final class AppState {
    /// Currently authenticated user. nil = not logged in.
    var currentUser: User? {
        didSet {
            if let userId = currentUser?.id {
                hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "onboardingDone_\(userId)")
                if let data = UserDefaults.standard.data(forKey: "favoriteTeams_\(userId)"),
                   let teams = try? JSONDecoder().decode([FootballTeam].self, from: data) {
                    favoriteTeams = teams
                } else {
                    favoriteTeams = []
                }
            } else {
                hasCompletedOnboarding = false
                favoriteTeams = []
            }
        }
    }

    /// True once the user has completed first-run onboarding (picked a favourite team).
    var hasCompletedOnboarding: Bool = false {
        didSet {
            guard let userId = currentUser?.id else { return }
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "onboardingDone_\(userId)")
        }
    }
    
    /// True if the user has seen the welcome screen.
    var hasSeenWelcome: Bool = UserDefaults.standard.bool(forKey: "hasSeenWelcome") {
        didSet {
            UserDefaults.standard.set(hasSeenWelcome, forKey: "hasSeenWelcome")
        }
    }
    
    /// The user's globally selected favorite teams.
    var favoriteTeams: [FootballTeam] = [] {
        didSet {
            guard let userId = currentUser?.id else { return }
            if let data = try? JSONEncoder().encode(favoriteTeams) {
                UserDefaults.standard.set(data, forKey: "favoriteTeams_\(userId)")
            } else {
                UserDefaults.standard.removeObject(forKey: "favoriteTeams_\(userId)")
            }
        }
    }
    
    func addFavoriteTeam(_ team: FootballTeam) {
        var teams = favoriteTeams
        if !teams.contains(where: { $0.id == team.id }) {
            teams.append(team)
            favoriteTeams = teams
        }
    }
    
    func removeFavoriteTeam(_ team: FootballTeam) {
        var teams = favoriteTeams
        teams.removeAll(where: { $0.id == team.id })
        favoriteTeams = teams
    }
    
    func isFavorite(_ team: FootballTeam) -> Bool {
        return favoriteTeams.contains(where: { $0.id == team.id })
    }

    /// Central dependency container.
    let container = DIContainer()

    // MARK: - Auth helpers

    func login(session: UserSession, isNewAccount: Bool = false) {
        currentUser = session.user
        if !isNewAccount {
            hasCompletedOnboarding = true
        }
    }

    func logout() async {
        await container.authService.logout()
        currentUser = nil
    }
}

// MARK: - Route enum

/// Screens that can be pushed inside a tab's NavigationStack.
enum Route: Hashable {
    /// Match detail for a given match id.
    case matchDetail(String)
    /// Player detail for a given player id and season.
    case playerDetail(String, String)
    /// All fixtures for a given team id and season.
    case teamFixtures(String, String)
    /// All fixtures for a given league id and season.
    case leagueFixtures(String, String)
    /// Team detail
    case teamDetail(FootballTeam)
}
