import SwiftUI
import Observation

// MARK: - View

struct PlayerSearchView: View {
    @State private var vm: PlayerSearchViewModel
    @State private var selectedPlayer: Player?

    init() {
        _vm = State(wrappedValue: PlayerSearchViewModel(playerRepo: DIContainer().playerRepository))
    }

    var body: some View {
        ZStack {
            AppBackground(imageName: "img_bg_6.jpg")

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 14) {
                    ZStack {
                        Text("Players")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    
                    seasonPicker

                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass").foregroundStyle(.white.opacity(0.45))
                        TextField("Search footballer…", text: Binding(
                            get: { vm.searchQuery },
                            set: { vm.searchQuery = $0; vm.onQueryChanged() }
                        ))
                        .foregroundStyle(.white).tint(Color(hex: "#00C853"))
                        .autocorrectionDisabled().textInputAutocapitalization(.never)

                        if case .loading = vm.state { ProgressView().tint(.white).scaleEffect(0.75) }
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
                .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 14)

                Divider().background(Color.white.opacity(0.08))

                // Content
                contentView
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .navigationDestination(for: Player.self) { player in
            PlayerDetailView(initialPlayer: player, season: vm.selectedSeason)
        }
    }

    private var seasonPicker: some View {
        HStack(spacing: 0) {
            ForEach(Season.allCases, id: \.self) { season in
                Button {
                    vm.selectedSeason = season
                    if !vm.searchQuery.isEmpty { vm.onQueryChanged() }
                } label: {
                    Text(season.label)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(vm.selectedSeason == season ? .white : .white.opacity(0.45))
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

    @ViewBuilder
    private var contentView: some View {
        switch vm.state {
        case .idle:
            VStack(spacing: 16) {
                Image(systemName: "person.2.circle")
                    .font(.system(size: 52))
                    .foregroundStyle(Color(hex: "#00C853").opacity(0.5))
                Text("Search for any footballer")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                Text("Type at least 3 characters")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .loading:
            ProgressView().tint(Color(hex: "#00C853"))
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .empty:
            EmptyStateView(message: "No players found. Try a different name or season.")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .error(let msg):
            ErrorStateView(message: msg) { vm.onQueryChanged() }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .loaded(let players):
            List(players) { player in
                GlassListRow {
                    PlayerRow(player: player)
                }
                .overlay {
                    NavigationLink(value: player) { EmptyView() }.opacity(0)
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

struct PlayerRow: View {
    let player: Player
    var body: some View {
        HStack(spacing: 14) {
            CachedAsyncImage(url: URL(string: player.photo ?? "")) { img in
                img.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle().fill(Color.white.opacity(0.08))
            }
            .frame(width: 44, height: 44).clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(player.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                HStack(spacing: 8) {
                    if let stat = player.statistics?.first {
                        Text(stat.position.isEmpty ? "–" : stat.position)
                            .font(.caption).foregroundStyle(.white.opacity(0.5))
                        Text("·").foregroundStyle(.white.opacity(0.2))
                        Text(stat.teamName)
                            .font(.caption).foregroundStyle(.white.opacity(0.5))
                    }
                    if let nat = player.nationality, !nat.isEmpty {
                        Text("· \(nat)")
                            .font(.caption).foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.25))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Player Detail View

struct PlayerDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let initialPlayer: Player
    let season: Season

    @State private var detailedPlayer: Player?
    @State private var isLoading = false

    var player: Player {
        detailedPlayer ?? initialPlayer
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            AppBackground(imageName: "img_bg_6.jpg")

            ScrollView {
                VStack(spacing: 0) {
                    // Hero card
                    GlassCard(cornerRadius: 24, padding: 28) {
                        VStack(spacing: 16) {
                            CachedAsyncImage(url: URL(string: player.photo ?? "")) { img in
                                img.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle().fill(Color.white.opacity(0.08))
                            }
                            .frame(width: 100, height: 100).clipShape(Circle())
                            .overlay(Circle().stroke(Color(hex: "#00C853").opacity(0.5), lineWidth: 2))

                            VStack(spacing: 6) {
                                Text(player.name)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)

                                HStack(spacing: 12) {
                                    if let nat = player.nationality, !nat.isEmpty {
                                        pill(nat, icon: "flag")
                                    }
                                    if let age = player.age {
                                        pill("Age \(age)", icon: "person")
                                    }
                                    if player.injured == true {
                                        pill("Injured", icon: "bandage")
                                            .foregroundStyle(Color(hex: "#FF5252"))
                                    }
                                }
                            }

                            // Quick stats from first season record
                            if let stat = player.statistics?.first {
                                HStack(spacing: 20) {
                                    statBubble("\(stat.goals)", label: "Goals")
                                    statBubble("\(stat.assists)", label: "Assists")
                                    statBubble("\(stat.appearances)", label: "Apps")
                                    if let rating = stat.rating {
                                        statBubble(String(format: "%.1f", rating), label: "Rating")
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    Divider().background(Color.white.opacity(0.08))

                    // Career history
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Career")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)

                        ForEach(player.statistics ?? [], id: \.self) { stat in
                            careerRow(stat: stat)
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
            
            if isLoading {
                ProgressView().tint(Color(hex: "#00C853"))
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.4))
            }

            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.3), in: Circle())
            }
            .padding(.leading, 16)
        }
        .task {
            isLoading = true
            do {
                detailedPlayer = try await DIContainer().playerRepository.playerDetail(id: initialPlayer.id, season: season)
            } catch {
                print("Failed to fetch player details: \(error)")
            }
            isLoading = false
        }
        .navigationTitle("")
        .navigationBarHidden(true)
    }

    private func pill(_ text: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 10))
            Text(text).font(.system(size: 12, weight: .medium, design: .rounded))
        }
        .foregroundStyle(.white.opacity(0.65))
        .padding(.horizontal, 10).padding(.vertical, 4)
        .background(Color.white.opacity(0.08), in: Capsule())
    }

    private func statBubble(_ value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "#00C853"))
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(minWidth: 60)
    }

    private func careerRow(stat: PlayerStat) -> some View {
        GlassCard(cornerRadius: 12, padding: 0) {
            HStack(spacing: 14) {
                CachedAsyncImage(url: URL(string: stat.teamLogo)) { img in
                    img.resizable().aspectRatio(contentMode: .fit)
                } placeholder: { Circle().fill(Color.white.opacity(0.05)) }
                .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 2) {
                    Text(stat.teamName)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    HStack(spacing: 6) {
                        Text(stat.leagueName)
                            .font(.caption).foregroundStyle(.white.opacity(0.5))
                        if let season = stat.season {
                            Text("· \(season)/\(String(season + 1).dropFirst(2))")
                                .font(.caption).foregroundStyle(.white.opacity(0.35))
                        }
                    }
                }

                Spacer()

                HStack(spacing: 12) {
                    miniStat("⚽", "\(stat.goals)")
                    miniStat("🅰️", "\(stat.assists)")
                    miniStat("📅", "\(stat.appearances)")
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .padding(.horizontal, 16)
    }

    private func miniStat(_ icon: String, _ value: String) -> some View {
        VStack(spacing: 1) {
            Text(icon).font(.system(size: 11))
            Text(value).font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(.white.opacity(0.8))
        }
    }
}
