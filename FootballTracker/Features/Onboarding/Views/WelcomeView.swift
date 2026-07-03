import SwiftUI

struct WelcomeView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            AppBackground(imageName: "img_bg_2.jpg")
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                
                Text("Which football\nteam are you?")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineSpacing(-2)
                    .padding(.bottom, 16)
                
                Text("Follow your favourite team. Get real-time scores, stats, and personalized news.")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.primaryLight)
                    .padding(.bottom, 32)
                
                HStack(spacing: 12) {
                    pill("48 teams")
                    pill("Live scores")
                    pill("Real-time stats")
                }
                .padding(.bottom, 48)
                
                Button {
                    withAnimation {
                        appState.hasSeenWelcome = true
                    }
                } label: {
                    Text("Let's start")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Theme.bgSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Theme.primaryLight, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 32)
        }
    }
    
    private func pill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(Theme.bgSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Theme.primaryLight.opacity(0.9), in: Capsule())
    }
}
