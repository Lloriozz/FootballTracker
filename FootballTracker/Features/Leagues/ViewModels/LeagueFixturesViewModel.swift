import SwiftUI
import Observation

@Observable
@MainActor
final class LeagueFixturesViewModel {
    enum State { case idle, loading, loaded([Match]), error(String) }
    var state: State = .idle
    var selectedSeason: Season = .s2023

    private let leagueRepo: any LeagueRepository
    let league: LeagueInfo

    init(league: LeagueInfo, leagueRepo: any LeagueRepository) {
        self.league = league
        self.leagueRepo = leagueRepo
    }

    func load() async {
        state = .loading
        do {
            let matches = try await leagueRepo.fixtures(leagueId: league.id, season: selectedSeason)
            state = matches.isEmpty ? .loaded([]) : .loaded(matches)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
