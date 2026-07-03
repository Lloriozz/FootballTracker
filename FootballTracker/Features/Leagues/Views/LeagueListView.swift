import SwiftUI
import Observation

// MARK: - View

struct LeagueListView: View {
    @State private var vm: LeagueListViewModel
    @State private var path = NavigationPath()

    init() {
        _vm = State(wrappedValue: LeagueListViewModel(leagueRepo: DIContainer().leagueRepository))
    }

    var body: some View {
        ZStack {
            AppBackground(imageName: "img_bg_7.jpg")

            VStack(spacing: 0) {
                // Title + search
                VStack(spacing: 14) {
                    ZStack {
                        Text("Leagues")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    // Search bar
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass").foregroundStyle(.white.opacity(0.45))
                        TextField("Search leagues…", text: Binding(get: { vm.searchQuery }, set: { vm.searchQuery = $0 }))
                            .foregroundStyle(.white).tint(Color(hex: "#00C853"))
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 52)
                    .background {
                        Capsule(style: .continuous)
                            .fill(Theme.glassFill)
                            .background(.ultraThinMaterial, in: Capsule(style: .continuous))
                    }
                    .overlay(Capsule(style: .continuous).stroke(Theme.glassStroke, lineWidth: 1))

                    // Country chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            countryChip("All", nil)
                            ForEach(vm.countries, id: \.self) { country in
                                countryChip(country, country)
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 14)

                Divider().background(Color.white.opacity(0.08))

                // Content
                switch vm.state {
                case .idle, .loading:
                    ProgressView().tint(Color(hex: "#00C853"))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .error(let msg):
                    ErrorStateView(message: msg) { Task { await vm.load() } }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .loaded(let leagues):
                    let filtered = vm.filtered(leagues)
                    if filtered.isEmpty {
                        EmptyStateView(message: "No leagues found.")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List(filtered) { league in
                            GlassListRow {
                                LeagueRow(league: league)
                            }
                            .overlay {
                                NavigationLink(value: league) { EmptyView() }.opacity(0)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .navigationDestination(for: LeagueInfo.self) { league in
            LeagueFixturesView(league: league)
        }
        .navigationDestination(for: Route.self) { route in
            switch route {
            case .teamDetail(let team):
                TeamDetailView(team: team)
            default:
                EmptyView()
            }
        }
        .task { await vm.load() }
    }

    @ViewBuilder
    private func countryChip(_ label: String, _ country: String?) -> some View {
        let isSelected = vm.selectedCountry == country
        Button {
            vm.selectCountry(country)
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? Theme.bgPrimary : Theme.textPrimary.opacity(0.55))
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(isSelected ? Color(hex: "#00C853").opacity(0.25) : Color.white.opacity(0.07),
                            in: Capsule())
                .overlay(Capsule().stroke(isSelected ? Color(hex: "#00C853").opacity(0.5) : Color.clear, lineWidth: 1))
        }
    }
}

struct LeagueRow: View {
    let league: LeagueInfo
    var body: some View {
        HStack(spacing: 14) {
            CachedAsyncImage(url: URL(string: league.icon ?? "")) { img in
                img.resizable().aspectRatio(contentMode: .fit)
            } placeholder: { RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.05)) }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text(league.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                HStack(spacing: 6) {
                    CachedAsyncImage(url: URL(string: league.flag ?? "")) { img in
                        img.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: { Color.clear }
                    .frame(width: 16, height: 12).clipShape(RoundedRectangle(cornerRadius: 2))

                    Text(league.country)
                        .font(.caption).foregroundStyle(.white.opacity(0.5))
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.25))
        }
        .padding(.vertical, 6)
    }
}

// MARK: - League Fixtures View

struct LeagueFixturesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm: LeagueFixturesViewModel

    init(league: LeagueInfo) {
        _vm = State(wrappedValue: LeagueFixturesViewModel(league: league, leagueRepo: DIContainer().leagueRepository))
    }

    var body: some View {
        ZStack {
            AppBackground(imageName: "img_bg_8.jpg")

            VStack(spacing: 0) {
                // Header
                HStack(spacing: 14) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.trailing, 4)
                    }

                    CachedAsyncImage(url: URL(string: vm.league.icon ?? "")) { img in
                        img.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: { Color.white.opacity(0.05) }
                    .frame(width: 44, height: 44)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(vm.league.name)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(vm.league.country)
                            .font(.caption).foregroundStyle(.white.opacity(0.5))
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

                seasonPicker
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                Divider().background(Color.white.opacity(0.08))

                switch vm.state {
                case .idle, .loading:
                    ProgressView().tint(Color(hex: "#00C853"))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .error(let msg):
                    ErrorStateView(message: msg) { Task { await vm.load() } }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .loaded(let matches):
                    if matches.isEmpty {
                        EmptyStateView(message: "No fixtures for \(vm.selectedSeason.label).")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(matches) { match in
                                    MatchCard(match: match).padding(.horizontal, 16)
                                }
                            }
                            .padding(.vertical, 16)
                        }
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .task { await vm.load() }
    }

    private var seasonPicker: some View {
        HStack(spacing: 0) {
            ForEach(Season.allCases, id: \.self) { season in
                Button {
                    vm.selectedSeason = season
                    Task { await vm.load() }
                } label: {
                    Text(season.label)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(vm.selectedSeason == season ? Theme.bgPrimary : Theme.textPrimary.opacity(0.45))
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(vm.selectedSeason == season ? Color(hex: "#00C853").opacity(0.25) : Theme.glassFill,
                                    in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Theme.glassFill)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Theme.glassStroke, lineWidth: 1))
    }
}
