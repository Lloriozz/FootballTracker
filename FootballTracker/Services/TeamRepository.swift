import Foundation

protocol TeamRepository: Sendable {
    func searchTeams(query: String) async throws -> [FootballTeam]
    func listTeams(leagueId: String, season: Season) async throws -> [FootballTeam]
    func fixtures(teamId: String, season: Season) async throws -> [Match]
}

struct RemoteTeamRepository: TeamRepository {
    let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func searchTeams(query: String) async throws -> [FootballTeam] {
        return try await client.get("/teams", query: ["search": query])
    }
    
    func listTeams(leagueId: String, season: Season) async throws -> [FootballTeam] {
        return try await client.get("/teams", query: ["league": leagueId, "season": String(season.year)])
    }

    func fixtures(teamId: String, season: Season) async throws -> [Match] {
        return try await client.get("/teams/\(teamId)/fixtures", query: ["season": String(season.year)])
    }
}
