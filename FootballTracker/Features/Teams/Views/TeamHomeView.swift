import SwiftUI
import Observation

// MARK: - View


struct TeamHomeView: View {
    @Environment(AppState.self) private var appState
    @State private var vm: TeamHomeViewModel

    init() {
        _vm = State(wrappedValue: TeamHomeViewModel(teamRepo: DIContainer().teamRepository))
    }

    var body: some View {
        ZStack {
            AppBackground(imageName: "img_bg_1.jpg")

            VStack(spacing: 0) {
                header
                Divider().background(Color.white.opacity(0.08))
                mainContent
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .task {
            await vm.loadFeaturedMatches(for: appState.favoriteTeams)
        }
        .onChange(of: appState.favoriteTeams) { oldValue, newValue in
            Task { await vm.loadFeaturedMatches(for: newValue) }
        }
        .navigationDestination(for: Route.self) { route in
            switch route {
            case .teamDetail(let team):
                TeamDetailView(team: team)
            default:
                EmptyView()
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 14) {
            ZStack {
                Text("My Teams")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            
            if !appState.favoriteTeams.isEmpty {
                seasonPicker
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 14)
    }

    private var seasonPicker: some View {
        HStack(spacing: 0) {
            ForEach(Season.allCases, id: \.self) { season in
                Button {
                    vm.selectedSeason = season
                    Task { await vm.loadFeaturedMatches(for: appState.favoriteTeams) }
                } label: {
                    Text(season.label)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(vm.selectedSeason == season ? .white : .white.opacity(0.45))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(vm.selectedSeason == season ? Color(hex: "#00C853").opacity(0.25) : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: Main content

    @ViewBuilder
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                newsSection
                
                if appState.favoriteTeams.isEmpty {
                    emptyTeamPrompt
                        .padding(.top, 40)
                } else {
                    teamsSection
                }
            }
            .padding(.bottom, 32)
        }
    }
    
    private var newsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Latest News")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(vm.mockNews) { article in
                        NewsCard(article: article)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.top, 16)
    }

    private var teamsSection: some View {
        VStack(spacing: 24) {
            switch vm.fixturesState {
            case .idle: Color.clear.frame(height: 0)
            case .loading:
                ProgressView().tint(Color(hex: "#00C853"))
                    .frame(maxWidth: .infinity, minHeight: 200)
            case .error(let msg):
                ErrorStateView(message: msg) { Task { await vm.loadFeaturedMatches(for: appState.favoriteTeams) } }
            case .loaded(let results):
                ForEach(appState.favoriteTeams) { team in
                    FavoriteTeamSection(team: team, match: results[team.id] ?? nil)
                }
            }
        }
    }

    private var emptyTeamPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "sportscourt")
                .font(.system(size: 52))
                .foregroundStyle(Color(hex: "#00C853").opacity(0.6))
            Text("No Favourite Teams")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
            Text("Go to the Teams tab to find and favorite a team.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.45))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
}

// MARK: - Shared subviews

struct TeamRow: View {
    let team: FootballTeam
    var body: some View {
        HStack(spacing: 14) {
            CachedAsyncImage(url: URL(string: team.logo ?? "")) { img in
                img.resizable().aspectRatio(contentMode: .fit)
            } placeholder: {
                Circle().fill(Color.white.opacity(0.05))
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text(team.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(team.country ?? "")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }
}

struct FavoriteTeamSection: View {
    let team: FootballTeam
    let match: Match?
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Team header
            HStack(spacing: 14) {
                CachedAsyncImage(url: URL(string: team.logo ?? "")) { img in
                    img.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Circle().fill(Color.white.opacity(0.05))
                }
                .frame(width: 46, height: 46)

                VStack(alignment: .leading, spacing: 2) {
                    Text(team.name)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(team.country ?? "")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
                Spacer()
                Button { 
                    withAnimation { appState.removeFavoriteTeam(team) } 
                } label: {
                    Image(systemName: "star.fill")
                        .foregroundStyle(Color.yellow)
                }
            }
            .padding(.horizontal, 20)
            
            if let match = match {
                MatchCard(match: match)
                    .padding(.horizontal, 16)
            } else {
                Text("No featured match available")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 20)
            }
        }
    }
}

struct MatchCard: View {
    let match: Match

    var body: some View {
        GlassCard(cornerRadius: 16, padding: 0) {
            VStack(spacing: 0) {
                // Competition bar
                HStack(spacing: 8) {
                    CachedAsyncImage(url: URL(string: match.competitionLogo)) { img in
                        img.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: { Color.white.opacity(0.05) }
                    .frame(width: 18, height: 18)

                    Text(match.competition)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))

                    Spacer()

                    statusBadge
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)

                Divider().background(Color.white.opacity(0.05))

                // Teams + score
                HStack(spacing: 0) {
                    teamColumn(team: match.homeTeam, score: match.homeScore, isHome: true)
                    scoreColumn
                    teamColumn(team: match.awayTeam, score: match.awayScore, isHome: false)
                }
                .padding(.vertical, 14)
            }
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        let color: Color = match.status == .live ? Color(hex: "#FF3D00") :
                           match.status == .finished ? Color.white.opacity(0.4) :
                           Color(hex: "#00C853").opacity(0.7)
        let label = match.status == .live ? (match.elapsed.map { "\($0)'" } ?? "Live") :
                    match.status == .finished ? "FT" :
                    kickoffLabel

        Text(label)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12), in: Capsule())
    }

    private var kickoffLabel: String {
        guard let d = match.kickoffDate else { return "TBD" }
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: d)
    }

    private func teamColumn(team: Team, score: Int?, isHome: Bool) -> some View {
        let footballTeam = FootballTeam(id: team.id, name: team.name, country: nil, logo: team.emblem, shortName: team.shortName, emblem: team.emblem)
        return NavigationLink(value: Route.teamDetail(footballTeam)) {
            VStack(spacing: 8) {
                CachedAsyncImage(url: URL(string: team.emblem)) { img in
                    img.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Circle().fill(Color.white.opacity(0.1))
                }
                .frame(width: 48, height: 48)

                Text(team.shortName)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var scoreColumn: some View {
        VStack(spacing: 4) {
            if let home = match.homeScore, let away = match.awayScore {
                Text("\(home) – \(away)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            } else {
                Text("vs")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))
                if let date = match.kickoffDate {
                    Text(date, format: .dateTime.hour().minute())
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.35))
                }
            }
        }
        .frame(width: 80)
    }
}

struct ErrorStateView: View {
    let message: String
    let retry: () -> Void
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 36))
                .foregroundStyle(.white.opacity(0.35))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
            Button("Retry") { retry() }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(hex: "#00C853"))
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }
}

struct EmptyStateView: View {
    let message: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 36))
                .foregroundStyle(.white.opacity(0.3))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }
}

struct NewsCard: View {
    let article: NewsArticle
    
    var body: some View {
        GlassCard(cornerRadius: 16, padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                if let urlString = article.imageURL, let url = URL(string: urlString) {
                    CachedAsyncImage(url: url) { img in
                        img.resizable()
                           .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle().fill(Color.white.opacity(0.1))
                    }
                    .frame(height: 120)
                    .clipped()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(article.title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        
                    HStack {
                        Text(article.source)
                        Spacer()
                        Text(article.timeAgo)
                    }
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                }
                .padding(12)
            }
        }
        .frame(width: 260)
    }
}
