import Foundation
@testable import FootballTracker

final class MockLeagueRepository: LeagueRepository, @unchecked Sendable {
    var listLeaguesResult: Result<[LeagueInfo], Error> = .success([])
    var fixturesResult: Result<[Match], Error> = .success([])

    func listLeagues(country: String?) async throws -> [LeagueInfo] {
        switch listLeaguesResult {
        case .success(let leagues): return leagues
        case .failure(let error): throw error
        }
    }
    
    func fixtures(leagueId: String, season: Season) async throws -> [Match] {
        switch fixturesResult {
        case .success(let matches): return matches
        case .failure(let error): throw error
        }
    }
}
