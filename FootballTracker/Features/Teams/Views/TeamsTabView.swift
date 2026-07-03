import SwiftUI
import Observation

@Observable @MainActor
final class TeamsTabViewModel {
    var searchQuery: String = ""
    var searchResults: [FootballTeam] = []
    var isSearching: Bool = false
    
    var leagues: [LeagueInfo] = []
    var leagueTeams: [String: [FootballTeam]] = [:]
    var isLoadingTeamsForLeague: Set<String> = []
    
    private let teamRepo: any TeamRepository
    private let leagueRepo: any LeagueRepository
    private var searchTask: Task<Void, Never>?
    
    init(teamRepo: any TeamRepository, leagueRepo: any LeagueRepository) {
        self.teamRepo = teamRepo
        self.leagueRepo = leagueRepo
        Task { await loadLeagues() }
    }
    
    func loadLeagues() async {
        do {
            leagues = try await leagueRepo.listLeagues(country: nil)
        } catch {
            print("Error loading leagues: \(error)")
        }
    }
    
    func loadTeams(for leagueId: String) async {
        guard leagueTeams[leagueId] == nil && !isLoadingTeamsForLeague.contains(leagueId) else { return }
        
        isLoadingTeamsForLeague.insert(leagueId)
        do {
            let teams = try await teamRepo.listTeams(leagueId: leagueId, season: .s2023)
            leagueTeams[leagueId] = teams
        } catch {
            print("Error loading teams for league \(leagueId): \(error)")
        }
        isLoadingTeamsForLeague.remove(leagueId)
    }
    
    func onSearchQueryChanged() {
        searchTask?.cancel()
        guard searchQuery.count >= 2 else { searchResults = []; return }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            isSearching = true
            do {
                let results = try await teamRepo.searchTeams(query: searchQuery)
                guard !Task.isCancelled else { return }
                searchResults = results.filter { team in
                    let name = team.name.lowercased()
                    return !name.contains(" u19") && 
                           !name.contains(" u20") && 
                           !name.contains(" u21") && 
                           !name.contains(" u23") && 
                           !name.hasSuffix(" ii") &&
                           !name.hasSuffix(" b") &&
                           !name.hasSuffix(" w") &&
                           !name.contains("women") 
                }
            } catch {
                guard !Task.isCancelled else { return }
                print("Search error: \(error)")
            }
            isSearching = false
        }
    }
}

struct TeamsTabView: View {
    @State private var vm: TeamsTabViewModel
    @Environment(AppState.self) private var appState
    @State private var expandedLeagues: Set<String> = []
    
    init() {
        _vm = State(wrappedValue: TeamsTabViewModel(teamRepo: DIContainer().teamRepository, leagueRepo: DIContainer().leagueRepository))
    }
    
    var body: some View {
        ZStack {
            AppBackground(imageName: "img_bg_3.jpg")
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 14) {
                    ZStack {
                        Text("Teams")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    
                    // Search bar
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.white.opacity(0.45))
                        TextField("Search for a team...", text: Binding(get: { vm.searchQuery }, set: { vm.searchQuery = $0; vm.onSearchQueryChanged() }))
                            .foregroundStyle(.white)
                            .tint(.white)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        if vm.isSearching { ProgressView().tint(.white).scaleEffect(0.75) }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 52)
                    .background {
                        Capsule(style: .continuous)
                            .fill(Theme.glassFill)
                            .background(.ultraThinMaterial, in: Capsule(style: .continuous))
                    }
                    .overlay(Capsule(style: .continuous).stroke(Theme.glassStroke, lineWidth: 1))
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 14)
                
                Divider().background(Color.white.opacity(0.08))
                
                if !vm.searchQuery.isEmpty {
                    if vm.searchResults.isEmpty && !vm.isSearching {
                        EmptyStateView(message: "No teams found.")
                    } else {
                        List(vm.searchResults) { team in
                            GlassListRow {
                                TeamRowContainer(team: team)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                } else {
                    if vm.leagues.isEmpty {
                        ProgressView().tint(.white).scaleEffect(1.2)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List(vm.leagues) { league in
                            LeagueSectionView(league: league, vm: vm, expandedLeagues: $expandedLeagues)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
    }
}

struct TeamRowContainer: View {
    let team: FootballTeam
    @Environment(AppState.self) private var appState
    
    var body: some View {
        let isFavorite = appState.isFavorite(team)
        HStack {
            NavigationLink(value: Route.teamDetail(team)) {
                TeamRow(team: team)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Button {
                if isFavorite {
                    withAnimation { appState.removeFavoriteTeam(team) }
                } else {
                    withAnimation { appState.addFavoriteTeam(team) }
                }
            } label: {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.system(size: 20))
                    .foregroundStyle(isFavorite ? Color.yellow : Color.white.opacity(0.3))
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
    }
}

struct LeagueSectionView: View {
    let league: LeagueInfo
    let vm: TeamsTabViewModel
    @Binding var expandedLeagues: Set<String>
    
    var body: some View {
        let isExpanded = Binding(
            get: { expandedLeagues.contains(league.id) },
            set: { isExpanding in
                if isExpanding {
                    expandedLeagues.insert(league.id)
                    Task { await vm.loadTeams(for: league.id) }
                } else {
                    expandedLeagues.remove(league.id)
                }
            }
        )
        
        DisclosureGroup(isExpanded: isExpanded) {
            if vm.isLoadingTeamsForLeague.contains(league.id) {
                HStack {
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                }
                .padding(.vertical, 16)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else if let teams = vm.leagueTeams[league.id] {
                ForEach(teams) { team in
                    TeamRowContainer(team: team)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 8)
                    
                    if team.id != teams.last?.id {
                        Divider().background(Color.white.opacity(0.1))
                    }
                }
            }
        } label: {
            HStack(spacing: 12) {
                CachedAsyncImage(url: URL(string: league.icon ?? "")) { img in
                    img.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Circle().fill(Color.white.opacity(0.1))
                }
                .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(league.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(league.country)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(.vertical, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.45))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.glassStroke, lineWidth: 1)
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .tint(.white)
    }
}
