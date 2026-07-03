import Foundation
@testable import FootballTracker

final class MockTeamRepository: TeamRepository, @unchecked Sendable {
    var searchTeamsResult: Result<[FootballTeam], Error> = .success([])
    var listTeamsResult: Result<[FootballTeam], Error> = .success([])
    var fixturesResult: Result<[Match], Error> = .success([])

    var searchTeamsCalls: [(query: String, Void)] = []
    
    func searchTeams(query: String) async throws -> [FootballTeam] {
        searchTeamsCalls.append((query: query, ()))
        switch searchTeamsResult {
        case .success(let teams): return teams
        case .failure(let error): throw error
        }
    }
    
    func listTeams(leagueId: String, season: Season) async throws -> [FootballTeam] {
        switch listTeamsResult {
        case .success(let teams): return teams
        case .failure(let error): throw error
        }
    }
    
    func fixtures(teamId: String, season: Season) async throws -> [Match] {
        switch fixturesResult {
        case .success(let matches): return matches
        case .failure(let error): throw error
        }
    }
}
