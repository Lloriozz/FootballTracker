import SwiftUI
import Observation
import Foundation

struct NewsArticle: Identifiable {
    let id = UUID()
    let title: String
    let source: String
    let timeAgo: String
    let imageURL: String?
}

@Observable
@MainActor
final class TeamHomeViewModel {
    enum State { case idle, loading, loaded([String: Match?]), error(String) }

    var selectedSeason: Season = .s2023
    var fixturesState: State = .idle
    
    let mockNews: [NewsArticle] = [
        NewsArticle(title: "Real Madrid secure thrilling 3-2 victory in El Clasico", source: "Global Sports", timeAgo: "2h ago", imageURL: "https://images.unsplash.com/photo-1518605368461-1ee7c532066d?auto=format&fit=crop&q=80&w=800"),
        NewsArticle(title: "Premier League: Title race heats up as top teams clash", source: "Football Daily", timeAgo: "4h ago", imageURL: "https://images.unsplash.com/photo-1522778119026-d647f0596c20?auto=format&fit=crop&q=80&w=800"),
        NewsArticle(title: "Champions League Quarter-Final draw announced", source: "EuroSport", timeAgo: "5h ago", imageURL: "https://images.unsplash.com/photo-1579952363873-27f3bade9f55?auto=format&fit=crop&q=80&w=800")
    ]

    private let teamRepo: any TeamRepository

    init(teamRepo: any TeamRepository) {
        self.teamRepo = teamRepo
    }

    func loadFeaturedMatches(for teams: [FootballTeam]) async {
        guard !teams.isEmpty else {
            fixturesState = .idle
            return
        }
        
        fixturesState = .loading
        do {
            var results: [String: Match?] = [:]
            for team in teams {
                let matches = try await teamRepo.fixtures(teamId: team.id, season: selectedSeason)
                let featured = matches.min(by: { a, b in
                    let d1 = a.kickoffDate ?? Date.distantPast
                    let d2 = b.kickoffDate ?? Date.distantPast
                    return abs(d1.timeIntervalSinceNow) < abs(d2.timeIntervalSinceNow)
                })
                results[team.id] = featured
            }
            fixturesState = .loaded(results)
        } catch {
            fixturesState = .error(error.localizedDescription)
        }
    }
}
