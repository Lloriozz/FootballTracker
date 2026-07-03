import Foundation

struct RealAuthService: AuthServiceProtocol {
    let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func login(email: String, password: String) async throws -> UserSession {
        let body = ["email": email, "password": password]
        let response: UserSession = try await client.post("/auth/login", body: body)
        TokenStore.shared.accessToken = response.accessToken
        TokenStore.shared.refreshToken = response.refreshToken
        return response
    }

    func signup(email: String, password: String, displayName: String) async throws -> UserSession {
        let body = ["email": email, "password": password, "displayName": displayName]
        let response: UserSession = try await client.post("/auth/signup", body: body)
        TokenStore.shared.accessToken = response.accessToken
        TokenStore.shared.refreshToken = response.refreshToken
        return response
    }

    func me() async throws -> User {
        return try await client.get("/auth/me")
    }

    func logout() async {
        TokenStore.shared.clear()
    }
}
