import SwiftUI
import Observation

@Observable
@MainActor
final class PlayerSearchViewModel {
    enum State { case idle, loading, loaded([Player]), empty, error(String) }

    var state: State = .idle
    var searchQuery: String = ""
    var selectedSeason: Season = .s2023

    private let playerRepo: any PlayerRepository
    private var searchTask: Task<Void, Never>?

    init(playerRepo: any PlayerRepository) {
        self.playerRepo = playerRepo
        Task { await search() }
    }

    func onQueryChanged() {
        searchTask?.cancel()
        guard searchQuery.isEmpty || searchQuery.count >= 3 else {
            return
        }
        searchTask = Task {
            if !searchQuery.isEmpty {
                try? await Task.sleep(for: .milliseconds(600))
            }
            guard !Task.isCancelled else { return }
            await search()
        }
    }

    private func search() async {
        guard !Task.isCancelled else { return }
        state = .loading
        do {
            let results = try await playerRepo.searchPlayers(query: searchQuery, season: selectedSeason)
            guard !Task.isCancelled else { return }
            state = results.isEmpty ? .empty : .loaded(results)
        } catch {
            guard !Task.isCancelled else { return }
            state = .error(error.localizedDescription)
        }
    }
}
