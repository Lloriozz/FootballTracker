import SwiftUI

struct LoginView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: LoginViewModel

    init(authService: AuthServiceProtocol) {
        _viewModel = State(wrappedValue: LoginViewModel(authService: authService))
    }

    var body: some View {
        ZStack {
            AppBackground(imageName: "img_bg_9.jpg")

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        // Removed icon per request
                        
                        VStack(spacing: 6) {
                            Text("FootballTracker")
                                .font(.system(size: 36, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                            
                            Text("Real-time scores & stats")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .padding(.top, 72)
                    .padding(.bottom, 48)

                    // Card
                    VStack(spacing: 0) {
                        // Mode toggle
                        HStack(spacing: 12) {
                            modeTab("Sign In", mode: .login)
                            modeTab("Sign Up", mode: .signup)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 28)

                        // Form
                        VStack(spacing: 16) {
                            if viewModel.mode == .signup {
                                GlassTextField(placeholder: "Your Name", text: bindingFor(\.displayName), icon: "person")
                            }
                            GlassTextField(placeholder: "Email", text: bindingFor(\.email), icon: "envelope", keyboardType: .emailAddress)
                            GlassTextField(placeholder: "Password", text: bindingFor(\.password), icon: "lock", isSecure: true)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                        // Error message
                        if let error = viewModel.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(error)
                                    .font(.caption)
                            }
                            .foregroundStyle(Color(hex: "#FF5252"))
                            .padding(.horizontal, 24)
                            .padding(.top, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Submit button
                        Button {
                            Task { @MainActor in
                                if let session = await viewModel.submit() {
                                    appState.login(session: session, isNewAccount: viewModel.mode == .signup)
                                }
                            }
                        } label: {
                            ZStack {
                                if viewModel.isLoading {
                                    ProgressView().tint(.black)
                                } else {
                                    Text(viewModel.mode == .login ? "Sign In" : "Create Account")
                                        .font(.system(size: 17, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.black)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(hex: "#D4F851"))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: Color(hex: "#D4F851").opacity(0.3), radius: 15, x: 0, y: 8)
                        }
                        .disabled(viewModel.isLoading)
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
                        .padding(.bottom, 36)
                    }
                    .background(Color.black.opacity(0.05))
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 30, x: 0, y: 15)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func modeTab(_ title: String, mode: LoginViewModel.Mode) -> some View {
        let isSelected = viewModel.mode == mode
        Button {
            withAnimation(.spring(response: 0.3)) {
                viewModel.mode = mode
                viewModel.errorMessage = nil
            }
        } label: {
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? Color(hex: "#D4F851") : .white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? Color(hex: "#D4F851") : Color.clear, lineWidth: 2)
                )
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(isSelected ? 0.05 : 0.08))
                )
        }
        .animation(.spring(response: 0.3), value: viewModel.mode)
    }



    /// Keypath → Binding helper to avoid capturing self in closures.
    private func bindingFor<V>(_ keyPath: ReferenceWritableKeyPath<LoginViewModel, V>) -> Binding<V> {
        Binding(get: { viewModel[keyPath: keyPath] }, set: { viewModel[keyPath: keyPath] = $0 })
    }
}
