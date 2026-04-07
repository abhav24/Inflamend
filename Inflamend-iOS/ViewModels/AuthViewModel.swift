import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var isLoading = true
    @Published var isAuthenticated = false

    private let db = SupabaseClient.shared

    var userId: String? { db.userId }

    init() {
        Task { await checkSession() }
    }

    func checkSession() async {
        guard let uid = db.userId, db.accessToken != nil else {
            isLoading = false
            isAuthenticated = false
            return
        }
        do {
            let p: UserProfile = try await db.selectOne("profiles", filter: "id=eq.\(uid)")
            profile = p
            isAuthenticated = true
        } catch {
            isAuthenticated = false
        }
        isLoading = false
    }

    func signIn(email: String, password: String) async throws {
        let (_, uid) = try await db.signIn(email: email, password: password)
        let p: UserProfile = try await db.selectOne("profiles", filter: "id=eq.\(uid)")
        profile = p
        isAuthenticated = true
    }

    func signOut() async {
        await db.signOut()
        profile = nil
        isAuthenticated = false
    }

    func updateProfile(_ updated: UserProfile) {
        profile = updated
    }
}
