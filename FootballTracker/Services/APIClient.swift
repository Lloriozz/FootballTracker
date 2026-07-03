import Foundation

/// Thin `URLSession` wrapper for the Football Tracker backend.
/// Every response is expected in the shape `{ "data": T }`.
actor APIClient {
    static let shared = APIClient(baseURL: URL(string: "http://localhost:3000/api/v1")!)

    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL) {
        self.baseURL = baseURL
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        self.session = URLSession(configuration: config)
    }

    /// Performs a GET request and decodes the `data` field of the response envelope.
    func get<T: Decodable>(_ path: String, query: [String: String] = [:]) async throws -> T {
        let request = try buildRequest(method: "GET", path: path, query: query, body: nil as String?)
        return try await perform(request)
    }

    /// Performs a POST request with a JSON-encodable body.
    func post<Body: Encodable, T: Decodable>(_ path: String, body: Body) async throws -> T {
        let request = try buildRequest(method: "POST", path: path, query: [:], body: body)
        return try await perform(request)
    }

    // MARK: - Private helpers

    private func buildRequest<Body: Encodable>(
        method: String,
        path: String,
        query: [String: String],
        body: Body?
    ) throws -> URLRequest {
        var components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: true)!
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Attach stored access token if available.
        if let token = TokenStore.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }
        return request
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            // Try to parse backend error body.
            if let apiError = try? JSONDecoder().decode(BackendError.self, from: data) {
                throw APIError.serverError(apiError.error.message)
            }
            throw APIError.httpError(http.statusCode)
        }
        let envelope = try JSONDecoder().decode(DataEnvelope<T>.self, from: data)
        return envelope.data
    }
}

// MARK: - Supporting types

private struct DataEnvelope<T: Decodable>: Decodable {
    let data: T
}

private struct BackendError: Decodable {
    struct Inner: Decodable { let code: String; let message: String }
    let error: Inner
}

enum APIError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "Could not reach the server."
        case .httpError(let code): "Server returned error \(code)."
        case .serverError(let msg): msg
        }
    }
}

/// Simple token store backed by UserDefaults (use Keychain in production).
final class TokenStore: @unchecked Sendable {
    static let shared = TokenStore()
    private let defaults = UserDefaults.standard

    var accessToken: String? {
        get { defaults.string(forKey: "accessToken") }
        set { defaults.set(newValue, forKey: "accessToken") }
    }

    var refreshToken: String? {
        get { defaults.string(forKey: "refreshToken") }
        set { defaults.set(newValue, forKey: "refreshToken") }
    }

    func clear() {
        accessToken = nil
        refreshToken = nil
    }
}
