import Foundation

/// Authentication response stored after login/signup.
struct UserSession: Codable, Hashable {
    /// Short-lived JWT used for API requests.
    let accessToken: String

    /// Long-lived token used to rotate access tokens.
    let refreshToken: String

    /// The authenticated user profile.
    let user: User
}

/// Minimal user profile returned by the backend.
struct User: Codable, Hashable, Identifiable {
    let id: String
    let email: String
    let displayName: String?
}
