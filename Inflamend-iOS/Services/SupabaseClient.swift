import Foundation

// MARK: - Supabase Client

final class SupabaseClient {
    static let shared = SupabaseClient()

    private let baseURL: String
    private let anonKey: String
    private let session = URLSession.shared
    private let tokenKey = "sb_access_token"
    private let userIdKey = "sb_user_id"

    private init() {
        baseURL = Config.supabaseURL
        anonKey = Config.supabaseAnonKey
    }

    // MARK: - Token Management

    var accessToken: String? {
        get { UserDefaults.standard.string(forKey: tokenKey) }
        set { UserDefaults.standard.set(newValue, forKey: tokenKey) }
    }

    var userId: String? {
        get { UserDefaults.standard.string(forKey: userIdKey) }
        set { UserDefaults.standard.set(newValue, forKey: userIdKey) }
    }

    func clearSession() {
        accessToken = nil
        userId = nil
    }

    // MARK: - Auth

    func signIn(email: String, password: String) async throws -> (token: String, userId: String) {
        let url = URL(string: "\(baseURL)/auth/v1/token?grant_type=password")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["email": email, "password": password])

        let (data, response) = try await session.data(for: req)
        try checkHTTP(response, data: data)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let token = json?["access_token"] as? String,
              let user = json?["user"] as? [String: Any],
              let uid = user["id"] as? String else {
            throw SupabaseError.invalidResponse
        }
        accessToken = token
        userId = uid
        return (token, uid)
    }

    func signUp(email: String, password: String) async throws {
        let url = URL(string: "\(baseURL)/auth/v1/signup")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["email": email, "password": password])

        let (data, response) = try await session.data(for: req)
        try checkHTTP(response, data: data)
    }

    func signOut() async {
        guard let token = accessToken else { clearSession(); return }
        let url = URL(string: "\(baseURL)/auth/v1/logout")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        addAuthHeaders(&req, token: token)
        _ = try? await session.data(for: req)
        clearSession()
    }

    func resetPassword(email: String) async throws {
        let url = URL(string: "\(baseURL)/auth/v1/recover")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.httpBody = try JSONSerialization.data(withJSONObject: ["email": email])
        let (data, response) = try await session.data(for: req)
        try checkHTTP(response, data: data)
    }

    // MARK: - REST API

    func select<T: Decodable>(_ table: String, query: [String] = [], filter: String? = nil) async throws -> [T] {
        var components = URLComponents(string: "\(baseURL)/rest/v1/\(table)")!
        var items: [URLQueryItem] = []
        if !query.isEmpty { items.append(URLQueryItem(name: "select", value: query.joined(separator: ","))) }
        if let filter { items.append(contentsOf: parseFilter(filter)) }
        components.queryItems = items.isEmpty ? nil : items

        var req = URLRequest(url: components.url!)
        req.httpMethod = "GET"
        addAuthHeaders(&req)
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: req)
        try checkHTTP(response, data: data)
        return try decoder.decode([T].self, from: data)
    }

    func selectOne<T: Decodable>(_ table: String, filter: String? = nil) async throws -> T {
        let results: [T] = try await select(table, filter: filter)
        guard let first = results.first else { throw SupabaseError.notFound }
        return first
    }

    func insert<T: Encodable>(_ table: String, data: T) async throws {
        let url = URL(string: "\(baseURL)/rest/v1/\(table)")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        addAuthHeaders(&req)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        req.httpBody = try encoder.encode(data)

        let (body, response) = try await session.data(for: req)
        try checkHTTP(response, data: body)
    }

    func update<T: Encodable>(_ table: String, filter: String, data: T) async throws {
        var components = URLComponents(string: "\(baseURL)/rest/v1/\(table)")!
        components.queryItems = parseFilter(filter)
        var req = URLRequest(url: components.url!)
        req.httpMethod = "PATCH"
        addAuthHeaders(&req)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        req.httpBody = try encoder.encode(data)

        let (body, response) = try await session.data(for: req)
        try checkHTTP(response, data: body)
    }

    func invokeFunction(_ name: String, body: [String: Any]) async throws -> Data {
        guard let token = accessToken else { throw SupabaseError.unauthorized }
        let url = URL(string: "\(baseURL)/functions/v1/\(name)")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: req)
        try checkHTTP(response, data: data)
        return data
    }

    // MARK: - Helpers

    private func addAuthHeaders(_ req: inout URLRequest, token: String? = nil) {
        let t = token ?? accessToken ?? anonKey
        req.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
    }

    private func parseFilter(_ filter: String) -> [URLQueryItem] {
        filter.components(separatedBy: "&").compactMap { part in
            let kv = part.components(separatedBy: "=")
            guard kv.count == 2 else { return nil }
            return URLQueryItem(name: kv[0], value: kv[1])
        }
    }

    private func checkHTTP(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        if http.statusCode == 401 { throw SupabaseError.unauthorized }
        if http.statusCode >= 400 {
            let msg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["message"] as? String
            throw SupabaseError.httpError(http.statusCode, msg ?? "Unknown error")
        }
    }

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .useDefaultKeys
        return d
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        return e
    }()
}

// MARK: - Errors

enum SupabaseError: LocalizedError {
    case invalidResponse
    case unauthorized
    case notFound
    case httpError(Int, String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid server response"
        case .unauthorized: return "Please sign in again"
        case .notFound: return "Record not found"
        case .httpError(_, let msg): return msg
        }
    }
}
