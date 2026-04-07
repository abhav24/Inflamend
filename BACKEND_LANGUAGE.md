# Backend Architecture Guide

This document defines how the backend layer of this app is structured. Follow these patterns exactly when building new features, adding collections, or writing ViewModels. All examples use Firebase (Auth + Firestore).

---

## 1. Stack

- **Auth**: Firebase Auth (email + password)
- **Database**: Cloud Firestore (NoSQL, real-time)
- **Client**: accessed via `Auth.auth()` and `Firestore.firestore()` throughout the app

### Setup

Add `GoogleService-Info.plist` to the main target. Initialize in the App entry point:

```swift
// YourApp.swift
import SwiftUI
import FirebaseCore

@main
struct YourApp: App {
    init() { FirebaseApp.configure() }
    // ...
}
```

Podfile (or Package.swift) dependencies:
```ruby
pod 'Firebase/Auth'
pod 'Firebase/Firestore'
```

---

## 2. Firestore Data Model

### Design rules
- Every document has a `createdAt: Timestamp` field
- Every user-owned document has a `userId: String` field
- Optional group membership uses a `familyId: String?` field (rename to match your domain)
- Amounts use `Double` with validation enforced in app code and Firestore rules
- Text fields are length-capped in both app code and security rules
- All collections are secured — no collection is world-readable

### Collections

#### `users/{uid}`
```
name:      String        // 2–50 chars
email:     String
role:      String        // e.g. "member", "admin" — define enum in Swift
familyId:  String?       // optional group membership
currency:  String        // "USD" default
joinedAt:  Timestamp
```

#### `families/{familyId}` (group / team / org — rename for your domain)
```
name:        String      // 1–50 chars
parentIds:   [String]    // admin user IDs
childIds:    [String]    // member user IDs
inviteCode:  String      // 6-char uppercase alphanumeric, unique
createdAt:   Timestamp
```

#### Content collection — adapt for your domain
```
userId:      String      // required — owner
familyId:    String?     // optional group link
title:       String      // 1–80 chars
amount:      Double      // 0 < x ≤ 999,999.99
description: String      // ≤ 200 chars
type:        String      // enum rawValue
date:        Timestamp
createdAt:   Timestamp
```

---

## 3. Firestore Security Rules

Deploy `firestore.rules` to the project. These rules enforce ownership and group membership server-side.

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isSignedIn() {
      return request.auth != null;
    }
    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }
    function isGroupAdmin(groupId) {
      return isSignedIn() &&
        request.auth.uid in get(/databases/$(database)/documents/families/$(groupId)).data.parentIds;
    }
    function isGroupMember(groupId) {
      return isSignedIn() && (
        request.auth.uid in get(/databases/$(database)/documents/families/$(groupId)).data.parentIds ||
        request.auth.uid in get(/databases/$(database)/documents/families/$(groupId)).data.childIds
      );
    }

    // Users
    match /users/{userId} {
      allow read:  if isOwner(userId) ||
        (isSignedIn() && isGroupAdmin(resource.data.familyId));
      allow write: if isOwner(userId);
    }

    // Groups / families
    match /families/{familyId} {
      allow read:   if isGroupMember(familyId);
      allow create: if isSignedIn() && request.auth.uid in request.resource.data.parentIds;
      allow update: if isGroupAdmin(familyId);
      allow delete: if isGroupAdmin(familyId);
    }

    // Content (rename 'items' to your collection name)
    match /items/{itemId} {
      allow read: if isOwner(resource.data.userId) ||
        (resource.data.familyId != null && isGroupAdmin(resource.data.familyId));
      allow create: if isSignedIn() &&
        isOwner(request.resource.data.userId) &&
        request.resource.data.amount is number &&
        request.resource.data.amount > 0 &&
        request.resource.data.amount <= 999999.99 &&
        request.resource.data.description.size() <= 200;
      allow update: if isOwner(resource.data.userId);
      allow delete: if isOwner(resource.data.userId) ||
        (resource.data.familyId != null && isGroupAdmin(resource.data.familyId));
    }
  }
}
```

Deploy with:
```
firebase deploy --only firestore:rules
```

---

## 4. Model Layer

Every model has three things:
1. A local `init` for creating new instances in Swift
2. A Firestore `init(id:data:)` that decodes `[String: Any]` from a snapshot
3. A `firestoreData: [String: Any]` computed property for writes

```swift
import FirebaseFirestore

struct Item: Identifiable, Equatable {
    let id: String
    var userId: String
    var familyId: String?
    var title: String
    var amount: Double
    var description: String
    var type: ItemType
    var date: Date
    var createdAt: Date

    // Local init (creating new)
    init(id: String = UUID().uuidString, userId: String, familyId: String? = nil,
         title: String, amount: Double, description: String,
         type: ItemType, date: Date = Date()) {
        self.id = id; self.userId = userId; self.familyId = familyId
        self.title = title; self.amount = amount; self.description = description
        self.type = type; self.date = date; self.createdAt = Date()
    }

    // Firestore init — returns nil if required fields are missing/invalid
    init?(id: String, data: [String: Any]) {
        guard let userId = data["userId"] as? String,
              let title  = data["title"]  as? String,
              let amount = data["amount"] as? Double,
              amount > 0 else { return nil }
        self.id          = id
        self.userId      = userId
        self.familyId    = data["familyId"]    as? String
        self.title       = title
        self.amount      = amount
        self.description = data["description"] as? String ?? ""
        self.type        = ItemType(rawValue: data["type"] as? String ?? "") ?? .defaultCase
        self.date        = (data["date"] as? Timestamp)?.dateValue() ?? Date()
        self.createdAt   = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
    }

    // For writes
    var firestoreData: [String: Any] {
        var d: [String: Any] = [
            "userId":      userId,
            "title":       title,
            "amount":      amount,
            "description": description,
            "type":        type.rawValue,
            "date":        Timestamp(date: date),
            "createdAt":   Timestamp(date: createdAt)
        ]
        if let fid = familyId { d["familyId"] = fid }
        return d
    }
}
```

---

## 5. ViewModel Pattern

Every ViewModel follows this exact structure. Do not deviate.

```
@MainActor final class XViewModel: ObservableObject
  @Published var items: [X] = []
  @Published var isLoading = false
  @Published var errorMessage: String?

  private var userId: String = ""
  private var listener: ListenerRegistration?   // Firestore real-time listener

  func setup(userId:)      — stores userId, calls startListening()
  func teardown()          — removes listener, resets all state
  private startListening() — attaches addSnapshotListener
  // MARK: - Computed      — aggregates over @Published arrays
  // MARK: - CRUD          — addX(), updateX(), deleteX()
```

### Full example

```swift
import FirebaseFirestore

@MainActor
final class ItemViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var userId: String = ""
    private var listener: ListenerRegistration?

    // MARK: - Lifecycle

    func setup(userId: String) {
        guard userId != self.userId else { return }
        self.userId = userId
        startListening()
    }

    func teardown() {
        listener?.remove(); listener = nil
        userId = ""; items = []
    }

    // MARK: - Real-time listener

    private func startListening() {
        listener?.remove()
        isLoading = true
        listener = Firestore.firestore()
            .collection("items")
            .whereField("userId", isEqualTo: userId)
            .order(by: "date", descending: true)
            .limit(to: 200)
            .addSnapshotListener { [weak self] snap, err in
                Task { @MainActor in
                    self?.isLoading = false
                    if let err { self?.errorMessage = err.localizedDescription; return }
                    self?.items = snap?.documents.compactMap {
                        Item(id: $0.documentID, data: $0.data())
                    } ?? []
                }
            }
    }

    // MARK: - Computed

    var recentItems: [Item] { Array(items.prefix(10)) }

    // MARK: - CRUD

    func addItem(title: String, amount: Double, description: String, type: ItemType) {
        guard amount > 0, amount <= 999_999.99 else { errorMessage = "Invalid amount."; return }
        let cleanTitle = InputValidator.sanitize(title, maxLength: 80)
        let cleanDesc  = InputValidator.sanitize(description, maxLength: 200)
        guard InputValidator.isValidTitle(cleanTitle) else {
            errorMessage = "Title must be 1–80 characters."; return
        }
        let item = Item(userId: userId, title: cleanTitle, amount: amount,
                        description: cleanDesc, type: type)
        Firestore.firestore()
            .collection("items").document(item.id)
            .setData(item.firestoreData) { [weak self] err in
                if let err { Task { @MainActor in self?.errorMessage = err.localizedDescription } }
            }
    }

    func deleteItem(_ item: Item) {
        guard item.userId == userId else { return }   // ownership check — always required
        Firestore.firestore().collection("items").document(item.id).delete()
    }

    func updateItem(_ item: Item) {
        guard item.userId == userId else { return }
        Firestore.firestore().collection("items").document(item.id)
            .setData(item.firestoreData) { [weak self] err in
                if let err { Task { @MainActor in self?.errorMessage = err.localizedDescription } }
            }
    }
}
```

---

## 6. Auth ViewModel

```swift
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var currentUser: AppUser?
    @Published var isLoading = true
    @Published var errorMessage: String?

    private var authHandle: AuthStateDidChangeListenerHandle?
    private var userListener: ListenerRegistration?

    init() { listenToAuthState() }

    deinit {
        if let h = authHandle { Auth.auth().removeStateDidChangeListener(h) }
        userListener?.remove()
    }

    private func listenToAuthState() {
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task { @MainActor in
                if let firebaseUser { self?.fetchUser(uid: firebaseUser.uid) }
                else { self?.currentUser = nil; self?.isLoading = false }
            }
        }
    }

    private func fetchUser(uid: String) {
        userListener?.remove()
        userListener = Firestore.firestore()
            .collection("users").document(uid)
            .addSnapshotListener { [weak self] snap, _ in
                Task { @MainActor in
                    guard let data = snap?.data() else { self?.isLoading = false; return }
                    self?.currentUser = AppUser(id: uid, data: data)
                    self?.isLoading = false
                }
            }
    }

    func signIn(email: String, password: String) {
        errorMessage = nil
        guard AuthRateLimiter.canAttempt() else {
            errorMessage = "Too many attempts. Try again in \(AuthRateLimiter.lockoutCountdown() ?? "a few minutes")."; return
        }
        let cleanEmail = InputValidator.sanitize(email.lowercased(), maxLength: 254)
        guard InputValidator.isValidEmail(cleanEmail) else { errorMessage = "Invalid email."; return }
        guard !password.isEmpty else { errorMessage = "Password cannot be empty."; return }

        isLoading = true
        Auth.auth().signIn(withEmail: cleanEmail, password: password) { [weak self] _, err in
            Task { @MainActor in
                self?.isLoading = false
                if let err {
                    AuthRateLimiter.recordFailure()
                    let r = AuthRateLimiter.remainingAttempts()
                    self?.errorMessage = r == 0
                        ? "Account temporarily locked. Try again in \(AuthRateLimiter.lockoutCountdown() ?? "15 minutes")."
                        : "\(err.localizedDescription) (\(r) attempt\(r == 1 ? "" : "s") left)"
                } else { AuthRateLimiter.reset() }
            }
        }
    }

    func signUp(email: String, password: String, name: String, role: UserRole,
                completion: @escaping (String?) -> Void) {
        errorMessage = nil
        let cleanEmail = InputValidator.sanitize(email.lowercased(), maxLength: 254)
        let cleanName  = InputValidator.sanitize(name, maxLength: 50)
        guard InputValidator.isValidEmail(cleanEmail) else { errorMessage = "Invalid email."; return }
        let pw = InputValidator.validatePassword(password)
        guard pw.isValid else { errorMessage = pw.message; return }
        guard InputValidator.isValidName(cleanName) else { errorMessage = "Name must be 2–50 characters."; return }

        isLoading = true
        Auth.auth().createUser(withEmail: cleanEmail, password: password) { [weak self] result, err in
            Task { @MainActor in
                self?.isLoading = false
                if let err { self?.errorMessage = err.localizedDescription; completion(nil); return }
                guard let uid = result?.user.uid else { completion(nil); return }
                let data: [String: Any] = [
                    "name":     cleanName,
                    "email":    cleanEmail,
                    "role":     role.rawValue,
                    "currency": "USD",
                    "joinedAt": Timestamp(date: Date())
                ]
                try? await Firestore.firestore().collection("users").document(uid).setData(data)
                completion(uid)
            }
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
        AuthRateLimiter.reset()
    }

    func updateProfile(name: String) {
        guard let uid = currentUser?.id else { return }
        let cleanName = InputValidator.sanitize(name, maxLength: 50)
        guard InputValidator.isValidName(cleanName) else { errorMessage = "Name must be 2–50 characters."; return }
        Firestore.firestore().collection("users").document(uid).updateData(["name": cleanName])
    }
}
```

---

## 7. Group / Team ViewModel (invite code pattern)

```swift
func createGroup(name: String) {
    let cleanName = InputValidator.sanitize(name, maxLength: 50)
    guard !cleanName.isEmpty else { errorMessage = "Name is required."; return }
    let code    = generateInviteCode()
    let groupId = UUID().uuidString
    let group   = Family(id: groupId, name: cleanName, parentIds: [userId], inviteCode: code)
    let db = Firestore.firestore()
    isLoading = true
    db.collection("families").document(groupId).setData(group.firestoreData) { [weak self] err in
        if let err { Task { @MainActor in self?.isLoading = false; self?.errorMessage = err.localizedDescription }; return }
        db.collection("users").document(self?.userId ?? "").updateData(["familyId": groupId]) { [weak self] _ in
            Task { @MainActor in
                self?.isLoading = false
                self?.successMessage = "Group created!"
                self?.listenToGroup(groupId)
            }
        }
    }
}

func joinGroup(code: String) {
    let cleanCode = InputValidator.sanitize(code.uppercased(), maxLength: 6)
    guard InputValidator.isValidInviteCode(cleanCode) else {
        errorMessage = "Invalid code."; return
    }
    isLoading = true
    Firestore.firestore().collection("families")
        .whereField("inviteCode", isEqualTo: cleanCode)
        .limit(to: 1)
        .getDocuments { [weak self] snap, err in
            Task { @MainActor in
                self?.isLoading = false
                if let err { self?.errorMessage = err.localizedDescription; return }
                guard let doc = snap?.documents.first else {
                    self?.errorMessage = "No group found with that code."; return
                }
                let groupId = doc.documentID
                let db = Firestore.firestore()
                let uid = self?.userId ?? ""
                try? await db.collection("families").document(groupId)
                    .updateData(["childIds": FieldValue.arrayUnion([uid])])
                try? await db.collection("users").document(uid)
                    .updateData(["familyId": groupId])
                self?.successMessage = "Joined!"
                self?.listenToGroup(groupId)
            }
        }
}

// 6-char invite code — no ambiguous characters (0/O, 1/I/L)
static func generateInviteCode() -> String {
    let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    return String((0..<6).compactMap { _ in chars.randomElement() })
}
```

**Auto-dismiss pattern for sheets** — never call `dismiss()` in the button action; wait for the state change:
```swift
PrimaryButton("Create") { groupVM.createGroup(name: name) }

.onChange(of: groupVM.group) { _, grp in
    if grp != nil { dismiss() }
}
```

---

## 8. App Entry Point

ViewModels are `@StateObject` at the app root, injected as `@EnvironmentObject`. Started/stopped by watching `authVM.currentUser`.

```swift
@main
struct YourApp: App {
    @StateObject private var authVM  = AuthViewModel()
    @StateObject private var itemVM  = ItemViewModel()
    @StateObject private var groupVM = GroupViewModel()

    init() { FirebaseApp.configure() }

    var body: some Scene {
        WindowGroup {
            Group {
                if authVM.isLoading {
                    SplashView()
                } else if authVM.currentUser != nil {
                    MainTabView()
                        .onChange(of: authVM.currentUser) { _, user in
                            if let user {
                                itemVM.setup(userId: user.id)
                                groupVM.setup(userId: user.id, groupId: user.groupId, role: user.role)
                            } else {
                                itemVM.teardown()
                                groupVM.teardown()
                            }
                        }
                } else {
                    WelcomeView()
                }
            }
            .environmentObject(authVM)
            .environmentObject(itemVM)
            .environmentObject(groupVM)
        }
    }
}
```

---

## 9. Firebase Console Setup (required before first run)

1. Create a project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add an iOS app — bundle ID must match Xcode target
3. Download `GoogleService-Info.plist` and add it to the main target
4. In **Firestore Database**, click "Create database" — choose production mode
5. Go to [Google Cloud Console](https://console.developers.google.com) → APIs → enable **Cloud Firestore API** for the project
6. Deploy `firestore.rules` via Firebase CLI: `firebase deploy --only firestore:rules`

Without step 4–5, every read and write will fail with "Cloud Firestore API has not been used in project."

---

## 10. Security Utilities

These two files are required in every project. Copy them over unchanged — they have no Firebase dependency.

### `InputValidator`
All user-supplied strings pass through this before touching Firestore.

- `sanitize(_ raw: String, maxLength: Int)` — trim + cap
- `isSafeSize(_ text: String, maxBytes: Int = 10_000)` — UTF-8 byte cap
- `isValidEmail(_ email: String) -> Bool`
- `validatePassword(_ password: String) -> PasswordResult` — min 8 chars, 1 letter + 1 digit
- `isValidName(_ name: String) -> Bool` — 2–50 chars
- `isValidTitle(_ title: String) -> Bool` — 1–80 chars
- `parseAmount(_ raw: String) -> Double?` — 0 < x ≤ 999,999.99, rounded to 2dp
- `isValidInviteCode(_ code: String) -> Bool` — 6 uppercase alphanumeric

### `AuthRateLimiter`
5 sign-in attempts per 15-minute sliding window, stored in `UserDefaults`. Firebase is the server-side gate — this is a UX guard only.

- `canAttempt() -> Bool`
- `recordFailure()`
- `reset()`
- `remainingAttempts() -> Int`
- `lockoutCountdown() -> String?`

---

## 11. Aggregates

Compute all aggregates over in-memory `@Published` arrays in the ViewModel. Never add extra Firestore queries for numbers you can derive locally.

```swift
var totalThisMonth: Double {
    let (start, end) = currentMonthBounds()
    return items.filter { $0.date >= start && $0.date < end }.map(\.amount).reduce(0, +)
}

private func currentMonthBounds() -> (start: Date, end: Date) {
    let cal = Calendar.current; let now = Date()
    let start = cal.date(from: cal.dateComponents([.year, .month], from: now))!
    let end   = cal.date(byAdding: .month, value: 1, to: start)!
    return (start, end)
}
```

---

## 12. Rules

- Call `setup()` from `.onChange(of: authVM.currentUser)` at the app root — never from a View's `.onAppear`
- Always call `teardown()` on sign-out — Firestore listeners keep firing for stale users if not removed
- Always include `guard item.userId == userId` before any delete/update — security rules are the server gate, this prevents accidental UI bugs
- Always cap list queries: `.limit(to: 200)` for personal lists, `.limit(to: 50)` for member/child views
- Never call `dismiss()` in a button action that starts async Firestore work — use `.onChange(of: vm.createdItem)`
- Validate + sanitize in the ViewModel before every write, even if the UI already enforces it
