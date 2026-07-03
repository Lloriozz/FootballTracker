import SwiftUI
import Observation

@Observable @MainActor
final class OnboardingTeamSelectionViewModel {
    var searchQuery: String = ""
    var searchResults: [FootballTeam] = []
    var isSearching: Bool = false
    
    private let teamRepo: any TeamRepository
    private var searchTask: Task<Void, Never>?
    
    init(teamRepo: any TeamRepository) {
        self.teamRepo = teamRepo
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
                // Filter out youth/women/B teams
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
                print("Search error: \(error)")
            }
            isSearching = false
        }
    }
}

struct OnboardingTeamSelectionView: View {
    @Environment(AppState.self) private var appState
    @State private var vm: OnboardingTeamSelectionViewModel
    
    init() {
        _vm = State(wrappedValue: OnboardingTeamSelectionViewModel(teamRepo: DIContainer().teamRepository))
    }
    
    var body: some View {
        ZStack {
            AppBackground(imageName: "img_bg_5.jpg")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pick your team")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Select your favourite team to personalize your home tab.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 40)
                .padding(.bottom, 24)
                
                // Search bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.white.opacity(0.45))
                    TextField("Search teams...", text: Binding(get: { vm.searchQuery }, set: { vm.searchQuery = $0; vm.onSearchQueryChanged() }))
                        .foregroundStyle(.white)
                        .tint(Theme.primaryLight)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    if vm.isSearching { ProgressView().tint(.white).scaleEffect(0.75) }
                }
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background {
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.08))
                }
                .overlay(Capsule(style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 1))
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                
                // Results
                if vm.searchResults.isEmpty && !vm.searchQuery.isEmpty && !vm.isSearching {
                    VStack {
                        Spacer()
                        Text("No teams found")
                            .foregroundStyle(.white.opacity(0.5))
                        Spacer()
                    }
                } else {
                    List(vm.searchResults) { team in
                        Button {
                            withAnimation {
                                if appState.isFavorite(team) {
                                    appState.removeFavoriteTeam(team)
                                } else {
                                    appState.addFavoriteTeam(team)
                                }
                            }
                        } label: {
                            HStack(spacing: 14) {
                                CachedAsyncImage(url: URL(string: team.logo ?? "")) { img in
                                    img.resizable().aspectRatio(contentMode: .fit)
                                } placeholder: {
                                    Circle().fill(Color.white.opacity(0.1))
                                }
                                .frame(width: 40, height: 40)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(team.name)
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.white)
                                    Text(team.country ?? "")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                                Spacer()
                                if appState.isFavorite(team) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                        .font(.system(size: 20))
                                } else {
                                    Circle()
                                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                                        .frame(width: 20, height: 20)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .contentShape(Rectangle())
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(appState.isFavorite(team) ? Color.green.opacity(0.15) : Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(appState.isFavorite(team) ? Color.green.opacity(0.5) : Color.clear, lineWidth: 1.5)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 24, bottom: 6, trailing: 24))
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
                
                if !appState.favoriteTeams.isEmpty {
                    Button {
                        withAnimation {
                            appState.hasCompletedOnboarding = true
                        }
                    } label: {
                        Text("Continue (\(appState.favoriteTeams.count))")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(Theme.bgSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.primaryLight, in: Capsule())
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                } else {
                    // Skip Button
                    Button {
                        withAnimation {
                            appState.hasCompletedOnboarding = true
                        }
                    } label: {
                        Text("Skip for now")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.vertical, 16)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }
                
            }
            // Ensure bottom buttons clear the home indicator
            .padding(.bottom, 16)
        }
    }
}
