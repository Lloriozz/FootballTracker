import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var showingLogoutAlert = false

    var body: some View {
        ZStack {
            AppBackground(imageName: "img_bg_4.jpg")

            ScrollView {
                VStack(spacing: 28) {
                    // Avatar
                    VStack(spacing: 14) {
                        ZStack {
                            Text("Profile")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color(hex: "#00C853").opacity(0.3), Color(hex: "#1565C0").opacity(0.3)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ))
                                .frame(width: 88, height: 88)
                            Text(initials)
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }

                        if let user = appState.currentUser {
                            Text(user.displayName ?? user.email)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    .padding(.top, 50)

                    Divider().background(Color.white.opacity(0.08)).padding(.horizontal, 24)

                    // Info cards
                    VStack(spacing: 12) {
                        infoCard(icon: "star.fill", title: "Favourite seasons", value: "2022/23 · 2023/24")
                        infoCard(icon: "server.rack", title: "Data source", value: "API-Football (Free)")
                        infoCard(icon: "lock.shield.fill", title: "Account", value: "Secured")
                    }
                    .padding(.horizontal, 20)

                    // Logout
                    Button(role: .destructive) {
                        showingLogoutAlert = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(Color(hex: "#FF5252"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(hex: "#FF5252").opacity(0.15))
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "#FF5252").opacity(0.4), lineWidth: 1))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .alert("Sign Out?", isPresented: $showingLogoutAlert) {
            Button("Sign Out", role: .destructive) {
                Task { await appState.logout() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll need to sign in again to access your content.")
        }
    }

    private var initials: String {
        guard let user = appState.currentUser else { return "?" }
        let name = user.displayName ?? user.email
        return String(name.prefix(1)).uppercased()
    }

    private func infoCard(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color(hex: "#00C853"))
                .frame(width: 36, height: 36)
                .background(Color(hex: "#00C853").opacity(0.10), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.5))
                Text(value)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            Spacer()
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.glassFill)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.glassStroke, lineWidth: 1))
    }
}
