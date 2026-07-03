import SwiftUI

@main
struct FootballTrackerApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @Environment(AppState.self) private var appState
    @State private var isRestoring = TokenStore.shared.accessToken != nil

    var body: some View {
        Group {
            if isRestoring {
                ZStack {
                    Theme.bgPrimary.ignoresSafeArea()
                    ProgressView().tint(Theme.primaryLight)
                }
                .task {
                    do {
                        let user = try await appState.container.authService.me()
                        appState.currentUser = user
                    } catch {
                        TokenStore.shared.clear()
                    }
                    withAnimation {
                        isRestoring = false
                    }
                }
            } else if !appState.hasSeenWelcome {
                WelcomeView()
                    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            } else if appState.currentUser == nil {
                LoginView(authService: appState.container.authService)
                    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            } else if !appState.hasCompletedOnboarding {
                OnboardingTeamSelectionView()
                    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            } else {
                MainTabView()
                    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isRestoring)
        .animation(.easeInOut(duration: 0.3), value: appState.hasSeenWelcome)
        .animation(.easeInOut(duration: 0.3), value: appState.currentUser == nil)
        .animation(.easeInOut(duration: 0.3), value: appState.hasCompletedOnboarding)
    }
}
