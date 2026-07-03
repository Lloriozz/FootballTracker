import SwiftUI
import Observation

@Observable @MainActor
final class TeamDetailViewModel {
    enum State { case idle, loading, loaded([Match]), error(String) }
    
    let team: FootballTeam
    var selectedSeason: Season = .s2023
    var fixturesState: State = .idle
    private let teamRepo: any TeamRepository
    
    init(team: FootballTeam, teamRepo: any TeamRepository) {
        self.team = team
        self.teamRepo = teamRepo
    }
    
    func loadFixtures() async {
        fixturesState = .loading
        do {
            let matches = try await teamRepo.fixtures(teamId: team.id, season: selectedSeason)
            fixturesState = matches.isEmpty ? .loaded([]) : .loaded(matches)
        } catch {
            fixturesState = .error(error.localizedDescription)
        }
    }
}

struct TeamDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let team: FootballTeam
    @State private var vm: TeamDetailViewModel
    
    init(team: FootballTeam) {
        self.team = team
        _vm = State(wrappedValue: TeamDetailViewModel(team: team, teamRepo: DIContainer().teamRepository))
    }
    
    var isFavorite: Bool {
        appState.isFavorite(team)
    }
    
    var body: some View {
        ZStack {
            AppBackground(imageName: "img_bg_1.jpg")
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        CachedAsyncImage(url: URL(string: team.logo ?? "")) { img in
                            img.resizable().aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Circle().fill(Color.white.opacity(0.1))
                        }
                        .frame(width: 80, height: 80)
                        
                        Text(team.name)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text(team.country ?? "")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                    
                    // Matches
                    HStack {
                        Text("Fixtures")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                    
                    switch vm.fixturesState {
                    case .idle: Color.clear.frame(height: 0)
                    case .loading:
                        ProgressView().tint(Color(hex: "#00C853"))
                            .frame(maxWidth: .infinity, minHeight: 200)
                    case .error(let msg):
                        ErrorStateView(message: msg) { Task { await vm.loadFixtures() } }
                    case .loaded(let matches):
                        if matches.isEmpty {
                            EmptyStateView(message: "No fixtures found for \(vm.selectedSeason.label).")
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(matches) { match in
                                    MatchCard(match: match)
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(team.shortName ?? team.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").fontWeight(.bold)
                        Text("Back")
                    }
                    .foregroundStyle(.white)
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation {
                        if isFavorite {
                            appState.removeFavoriteTeam(team)
                        } else {
                            appState.addFavoriteTeam(team)
                        }
                    }
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundStyle(isFavorite ? Color.yellow : Color.white)
                }
            }
        }
        .task { await vm.loadFixtures() }
    }
}
