import Foundation
import Supabase

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var isLoading = true
    @Published var isAuthenticated = false

    private let db = AppDatabase.shared

    init() {
        Task { await checkSession() }
    }

    func checkSession() async {
        guard let uid = await db.currentUserId() else {
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
        let uid = try await db.signIn(email: email, password: password)
        let p: UserProfile = try await db.selectOne("profiles", filter: "id=eq.\(uid)")
        profile = p
        isAuthenticated = true
    }

    func signOut() async {
        try? await db.signOut()
        profile = nil
        isAuthenticated = false
    }

    func updateProfile(_ updated: UserProfile) {
        profile = updated
    }
}
