import Foundation

protocol AuthServiceProtocol: Sendable {
    func login(email: String, password: String) async throws -> UserSession
    func signup(email: String, password: String, displayName: String) async throws -> UserSession
    func me() async throws -> User
    func logout() async
}
