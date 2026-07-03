import Foundation
import Observation

@Observable
@MainActor
final class LoginViewModel {
    enum Mode { case login, signup }

    var mode: Mode = .login
    var email: String = ""
    var password: String = ""
    var displayName: String = ""
    var isLoading: Bool = false
    var errorMessage: String?

    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    var isFormValid: Bool {
        let baseValid = !email.trimmingCharacters(in: .whitespaces).isEmpty
            && password.count >= 6
        if mode == .signup {
            return baseValid && !displayName.trimmingCharacters(in: .whitespaces).isEmpty
        }
        return baseValid
    }

    func submit() async -> UserSession? {
        guard isFormValid else {
            errorMessage = mode == .signup
                ? "Please fill in your name, email, and a password of at least 6 characters."
                : "Please enter your email and password."
            return nil
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            switch mode {
            case .login:
                return try await authService.login(email: email.lowercased().trimmingCharacters(in: .whitespaces), password: password)
            case .signup:
                return try await authService.signup(
                    email: email.lowercased().trimmingCharacters(in: .whitespaces),
                    password: password,
                    displayName: displayName.trimmingCharacters(in: .whitespaces)
                )
            }
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
