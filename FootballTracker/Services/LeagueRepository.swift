import Foundation

protocol LeagueRepository: Sendable {
    func listLeagues(country: String?) async throws -> [LeagueInfo]
    func fixtures(leagueId: String, season: Season) async throws -> [Match]
}

struct RemoteLeagueRepository: LeagueRepository {
    let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func listLeagues(country: String?) async throws -> [LeagueInfo] {
        var query: [String: String] = [:]
        if let country { query["country"] = country }
        return try await client.get("/leagues", query: query)
    }

    func fixtures(leagueId: String, season: Season) async throws -> [Match] {
        return try await client.get("/leagues/\(leagueId)/fixtures", query: ["season": String(season.year)])
    }
}
