import SwiftUI
import Observation

@Observable
@MainActor
final class LeagueListViewModel {
    enum State { case idle, loading, loaded([LeagueInfo]), error(String) }

    var state: State = .idle
    var selectedCountry: String? = nil
    var searchQuery: String = ""

    private let leagueRepo: any LeagueRepository

    private let popularCountries = ["England", "Spain", "Germany", "Italy", "France", "Portugal", "Netherlands"]

    init(leagueRepo: any LeagueRepository) {
        self.leagueRepo = leagueRepo
    }

    var countries: [String] { popularCountries }

    func load() async {
        state = .loading
        do {
            let leagues = try await leagueRepo.listLeagues(country: selectedCountry)
            state = leagues.isEmpty ? .loaded([]) : .loaded(leagues)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func selectCountry(_ country: String?) {
        selectedCountry = country
        Task { await load() }
    }

    func filtered(_ leagues: [LeagueInfo]) -> [LeagueInfo] {
        guard !searchQuery.isEmpty else { return leagues }
        return leagues.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
    }
}
