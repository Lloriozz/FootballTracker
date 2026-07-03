import Foundation
@testable import FootballTracker

final class MockPlayerRepository: PlayerRepository, @unchecked Sendable {
    var searchPlayersResult: Result<[Player], Error> = .success([])
    var playerDetailResult: Result<Player, Error>?

    func searchPlayers(query: String, season: Season) async throws -> [Player] {
        switch searchPlayersResult {
        case .success(let players): return players
        case .failure(let error): throw error
        }
    }
    
    func playerDetail(id: String, season: Season) async throws -> Player {
        guard let result = playerDetailResult else {
            throw URLError(.badServerResponse)
        }
        switch result {
        case .success(let player): return player
        case .failure(let error): throw error
        }
    }
}
