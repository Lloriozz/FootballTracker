import SwiftUI

/// Root tab bar shown after authentication.
struct MainTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        TabView {
            // Home — favourite team fixtures
            NavigationStack {
                TeamHomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)

            // Leagues — browse + fixtures
            NavigationStack {
                LeagueListView()
            }
            .tabItem {
                Label("Leagues", systemImage: "trophy.fill")
            }
            .tag(1)
            
            // Teams — search + info
            NavigationStack {
                TeamsTabView()
                    .navigationDestination(for: Route.self) { route in
                        switch route {
                        case .teamDetail(let team):
                            TeamDetailView(team: team)
                        default:
                            EmptyView()
                        }
                    }
            }
            .tabItem {
                Label("Teams", systemImage: "shield.fill")
            }
            .tag(2)

            // Players — search + detail
            NavigationStack {
                PlayerSearchView()
            }
            .tabItem {
                Label("Players", systemImage: "person.2.fill")
            }
            .tag(3)

            // Profile
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.circle.fill")
            }
            .tag(4)
        }
        .tint(Color(hex: "#00C853"))
    }
}
