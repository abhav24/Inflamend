import Foundation
import Supabase

// MARK: - Supabase singleton

let supabase = SupabaseClient(
    supabaseURL: URL(string: Config.supabaseURL)!,
    supabaseKey: Config.supabaseAnonKey
)

// MARK: - AppDatabase

/// Thin service wrapper around the official supabase-swift SDK.
/// All view-layer code calls this rather than the SDK directly.
final class AppDatabase {
    static let shared = AppDatabase()
    private init() {}

    private var client: SupabaseClient { supabase }

    // MARK: - Cached User ID (synchronous, populated after auth)

    private(set) var userId: String? {
        get { UserDefaults.standard.string(forKey: "app_user_id") }
        set { UserDefaults.standard.set(newValue, forKey: "app_user_id") }
    }

    // MARK: - Auth

    func signIn(email: String, password: String) async throws -> String {
        let session = try await client.auth.signIn(email: email, password: password)
        let uid = session.user.id.uuidString
        userId = uid
        return uid
    }

    func signUp(email: String, password: String) async throws {
        try await client.auth.signUp(email: email, password: password)
    }

    func signOut() async throws {
        try await client.auth.signOut()
        userId = nil
    }

    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }

    func currentUserId() async -> String? {
        if let cached = userId { return cached }
        let uid = try? await client.auth.session.user.id.uuidString
        userId = uid
        return uid
    }

    // MARK: - Database

    func select<T: Decodable & Sendable>(
        _ table: String,
        filter: String? = nil
    ) async throws -> [T] {
        var query = client.from(table).select()
        if let filter {
            query = applyFilter(query, filter: filter)
        }
        return try await query.execute().value
    }

    func selectOne<T: Decodable & Sendable>(
        _ table: String,
        filter: String? = nil
    ) async throws -> T {
        var query = client.from(table).select()
        if let filter {
            query = applyFilter(query, filter: filter)
        }
        return try await query.single().execute().value
    }

    func insert<T: Encodable & Sendable>(_ table: String, data: T) async throws {
        try await client.from(table).insert(data).execute()
    }

    func update<T: Encodable & Sendable>(_ table: String, filter: String, data: T) async throws {
        var query = client.from(table).update(data)
        query = applyUpdateFilter(query, filter: filter)
        try await query.execute()
    }

    // MARK: - Edge Functions

    func invokeFunction(_ name: String, body: some Encodable & Sendable) async throws -> Data {
        let response = try await client.functions.invoke(name, options: .init(body: body))
        return response
    }

    // MARK: - Filter Helper

    /// Parses simple `key=op.value` filter strings into SDK query methods.
    private func applyFilter(
        _ query: PostgrestFilterBuilder,
        filter: String
    ) -> PostgrestFilterBuilder {
        var q = query
        for part in filter.components(separatedBy: "&") {
            guard let eqRange = part.range(of: "=") else { continue }
            let key = String(part[part.startIndex..<eqRange.lowerBound])
            let remainder = String(part[eqRange.upperBound...])
            guard let opRange = remainder.range(of: ".") else { continue }
            let op = String(remainder[remainder.startIndex..<opRange.lowerBound])
            let value = String(remainder[opRange.upperBound...])
            switch op {
            case "eq":  q = q.eq(key, value: value)
            case "neq": q = q.neq(key, value: value)
            case "gte": q = q.gte(key, value: value)
            case "lte": q = q.lte(key, value: value)
            case "gt":  q = q.gt(key, value: value)
            case "lt":  q = q.lt(key, value: value)
            default: break
            }
        }
        return q
    }

    private func applyUpdateFilter(
        _ query: PostgrestFilterBuilder,
        filter: String
    ) -> PostgrestFilterBuilder {
        applyFilter(query, filter: filter)
    }
}
