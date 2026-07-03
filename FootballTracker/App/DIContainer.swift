import Foundation

/// Dependency container wiring all services and repositories.
@MainActor
struct DIContainer {
    /// Real auth service calling the backend.
    let authService: AuthServiceProtocol

    /// Team search + fixtures backed by backend + API-Football cache.
    let teamRepository: any TeamRepository

    /// League listing + fixtures backed by backend + API-Football cache.
    let leagueRepository: any LeagueRepository

    /// Player search + detail backed by backend + API-Football cache.
    let playerRepository: any PlayerRepository

    /// Builds the production dependency graph.
    init() {
        authService = RealAuthService()
        teamRepository = RemoteTeamRepository()
        leagueRepository = RemoteLeagueRepository()
        playerRepository = RemotePlayerRepository()
    }
}
