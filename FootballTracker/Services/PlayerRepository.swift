import Foundation

protocol PlayerRepository: Sendable {
    func searchPlayers(query: String, season: Season) async throws -> [Player]
    func playerDetail(id: String, season: Season) async throws -> Player
}

struct RemotePlayerRepository: PlayerRepository {
    let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func searchPlayers(query: String, season: Season) async throws -> [Player] {
        return try await client.get("/players", query: [
            "search": query,
            "season": String(season.year)
        ])
    }

    func playerDetail(id: String, season: Season) async throws -> Player {
        return try await client.get("/players/\(id)", query: ["season": String(season.year)])
    }
}
