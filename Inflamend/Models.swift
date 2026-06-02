import Foundation
import SwiftUI

// MARK: - Local Snapshot Store

struct AppSnapshot: Codable, Equatable {
    var schemaVersion: Int
    var authSession: AuthSession?
    var onboardingProfile: OnboardingProfile?
    var riskScore: Int
    var mood: MoodOption?
    var medsTaken: Int
    var medsTotal: Int
    var latestSafetyMessage: String?
    var aiMemoryEnabled: Bool
    var voiceTranscriptStorageEnabled: Bool
    var lastSyncStatus: String
    var pendingSyncMutations: [PendingSyncMutation]
    var logs: [LogEntry]
    var chatMessages: [ChatMessage]

    init(
        schemaVersion: Int = 1,
        authSession: AuthSession?,
        onboardingProfile: OnboardingProfile?,
        riskScore: Int,
        mood: MoodOption?,
        medsTaken: Int,
        medsTotal: Int,
        latestSafetyMessage: String?,
        aiMemoryEnabled: Bool,
        voiceTranscriptStorageEnabled: Bool,
        lastSyncStatus: String,
        pendingSyncMutations: [PendingSyncMutation] = [],
        logs: [LogEntry],
        chatMessages: [ChatMessage]
    ) {
        self.schemaVersion = schemaVersion
        self.authSession = authSession
        self.onboardingProfile = onboardingProfile
        self.riskScore = riskScore
        self.mood = mood
        self.medsTaken = medsTaken
        self.medsTotal = medsTotal
        self.latestSafetyMessage = latestSafetyMessage
        self.aiMemoryEnabled = aiMemoryEnabled
        self.voiceTranscriptStorageEnabled = voiceTranscriptStorageEnabled
        self.lastSyncStatus = lastSyncStatus
        self.pendingSyncMutations = pendingSyncMutations
        self.logs = logs
        self.chatMessages = chatMessages
    }

    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case authSession
        case onboardingProfile
        case riskScore
        case mood
        case medsTaken
        case medsTotal
        case latestSafetyMessage
        case aiMemoryEnabled
        case voiceTranscriptStorageEnabled
        case lastSyncStatus
        case pendingSyncMutations
        case logs
        case chatMessages
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        authSession = try container.decodeIfPresent(AuthSession.self, forKey: .authSession)
        onboardingProfile = try container.decodeIfPresent(OnboardingProfile.self, forKey: .onboardingProfile)
        riskScore = try container.decodeIfPresent(Int.self, forKey: .riskScore) ?? 42
        mood = try container.decodeIfPresent(MoodOption.self, forKey: .mood)
        medsTaken = try container.decodeIfPresent(Int.self, forKey: .medsTaken) ?? 0
        medsTotal = max(1, try container.decodeIfPresent(Int.self, forKey: .medsTotal) ?? 4)
        latestSafetyMessage = try container.decodeIfPresent(String.self, forKey: .latestSafetyMessage)
        aiMemoryEnabled = try container.decodeIfPresent(Bool.self, forKey: .aiMemoryEnabled) ?? false
        voiceTranscriptStorageEnabled = try container.decodeIfPresent(Bool.self, forKey: .voiceTranscriptStorageEnabled) ?? false
        lastSyncStatus = try container.decodeIfPresent(String.self, forKey: .lastSyncStatus) ?? "Saved on this device"
        pendingSyncMutations = try container.decodeIfPresent([PendingSyncMutation].self, forKey: .pendingSyncMutations) ?? []
        logs = try container.decodeIfPresent([LogEntry].self, forKey: .logs) ?? []
        chatMessages = try container.decodeIfPresent([ChatMessage].self, forKey: .chatMessages) ?? [
            ChatMessage(role: .assistant, content: AppDefaults.initialAssistantMessage)
        ]
    }
}

enum SyncMutationKind: String, Codable, Equatable {
    case authSession
    case onboardingProfile
    case healthLog
    case healthLogUpdate
    case healthLogDeletion
    case chatMessage
    case privacyPreference
    case safetyNotice
    case reportExport
    case accountDeletion
}

enum SyncMutationStatus: String, Codable, Equatable {
    case pending
    case blockedNoBackend
    case syncing
    case synced
    case failedRetryable
    case failedNeedsUser
}

struct HealthLogReplayPayload: Codable, Equatable {
    var localId: String
    var type: LogType
    var title: String
    var details: String
    var displayTime: String
    var loggedAt: Date
    var typedPayload: HealthLogPayload?

    init(log: LogEntry) {
        localId = log.id.uuidString
        type = log.type
        title = log.title
        details = log.sub
        displayTime = log.time
        loggedAt = log.loggedAt
        typedPayload = log.payload
    }
}

struct SyncMutationPayload: Codable, Equatable {
    enum PayloadKind: String, Codable {
        case healthLog
    }

    var kind: PayloadKind
    var healthLog: HealthLogReplayPayload?

    static func healthLogSnapshot(for log: LogEntry) -> SyncMutationPayload {
        SyncMutationPayload(kind: .healthLog, healthLog: HealthLogReplayPayload(log: log))
    }
}

struct PendingSyncMutation: Identifiable, Codable, Equatable {
    var id = UUID()
    var kind: SyncMutationKind
    var localRecordId: String
    var summary: String
    var payload: SyncMutationPayload?
    var createdAt = Date()
    var idempotencyKey: String
    var serverRecordId: String? = nil
    var receiptId: String? = nil
    var receiptRecordedAt: Date? = nil
    var attemptCount = 0
    var status: SyncMutationStatus = .pending
    var lastAttemptedAt: Date? = nil
    var nextRetryAt: Date? = nil
    var lastError: String? = nil

    init(
        id: UUID = UUID(),
        kind: SyncMutationKind,
        localRecordId: String,
        summary: String,
        payload: SyncMutationPayload? = nil,
        createdAt: Date = Date(),
        idempotencyKey: String? = nil,
        serverRecordId: String? = nil,
        receiptId: String? = nil,
        receiptRecordedAt: Date? = nil,
        attemptCount: Int = 0,
        status: SyncMutationStatus = .pending,
        lastAttemptedAt: Date? = nil,
        nextRetryAt: Date? = nil,
        lastError: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.localRecordId = localRecordId
        self.summary = summary
        self.payload = payload
        self.createdAt = createdAt
        self.idempotencyKey = idempotencyKey ?? Self.makeIdempotencyKey(kind: kind, localRecordId: localRecordId, mutationId: id)
        self.serverRecordId = serverRecordId
        self.receiptId = receiptId
        self.receiptRecordedAt = receiptRecordedAt
        self.attemptCount = attemptCount
        self.status = status
        self.lastAttemptedAt = lastAttemptedAt
        self.nextRetryAt = nextRetryAt
        self.lastError = lastError
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case kind
        case localRecordId
        case summary
        case payload
        case createdAt
        case idempotencyKey
        case serverRecordId
        case receiptId
        case receiptRecordedAt
        case attemptCount
        case status
        case lastAttemptedAt
        case nextRetryAt
        case lastError
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        kind = try container.decode(SyncMutationKind.self, forKey: .kind)
        localRecordId = try container.decode(String.self, forKey: .localRecordId)
        summary = try container.decode(String.self, forKey: .summary)
        payload = try container.decodeIfPresent(SyncMutationPayload.self, forKey: .payload)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        idempotencyKey = try container.decodeIfPresent(String.self, forKey: .idempotencyKey)
            ?? Self.makeIdempotencyKey(kind: kind, localRecordId: localRecordId, mutationId: id)
        serverRecordId = try container.decodeIfPresent(String.self, forKey: .serverRecordId)
        receiptId = try container.decodeIfPresent(String.self, forKey: .receiptId)
        receiptRecordedAt = try container.decodeIfPresent(Date.self, forKey: .receiptRecordedAt)
        attemptCount = try container.decodeIfPresent(Int.self, forKey: .attemptCount) ?? 0
        status = try container.decodeIfPresent(SyncMutationStatus.self, forKey: .status) ?? .pending
        lastAttemptedAt = try container.decodeIfPresent(Date.self, forKey: .lastAttemptedAt)
        nextRetryAt = try container.decodeIfPresent(Date.self, forKey: .nextRetryAt)
        lastError = try container.decodeIfPresent(String.self, forKey: .lastError)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(kind, forKey: .kind)
        try container.encode(localRecordId, forKey: .localRecordId)
        try container.encode(summary, forKey: .summary)
        try container.encodeIfPresent(payload, forKey: .payload)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(idempotencyKey, forKey: .idempotencyKey)
        try container.encodeIfPresent(serverRecordId, forKey: .serverRecordId)
        try container.encodeIfPresent(receiptId, forKey: .receiptId)
        try container.encodeIfPresent(receiptRecordedAt, forKey: .receiptRecordedAt)
        try container.encode(attemptCount, forKey: .attemptCount)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(lastAttemptedAt, forKey: .lastAttemptedAt)
        try container.encodeIfPresent(nextRetryAt, forKey: .nextRetryAt)
        try container.encodeIfPresent(lastError, forKey: .lastError)
    }

    private static func makeIdempotencyKey(kind: SyncMutationKind, localRecordId: String, mutationId: UUID) -> String {
        "inflamend.\(kind.rawValue).\(localRecordId).\(mutationId.uuidString)"
    }
}

enum SyncReplayAction: String, Codable, Equatable {
    case authenticate
    case upsert
    case insert
    case update
    case softDelete
    case invokeFunction
}

struct SyncReplayPlanItem: Identifiable, Codable, Equatable {
    var mutationId: UUID
    var kind: SyncMutationKind
    var localRecordId: String
    var idempotencyKey: String
    var serverRecordId: String?
    var action: SyncReplayAction
    var target: String
    var summary: String
    var payload: SyncMutationPayload?
    var requiresReceipt: Bool
    var receiptId: String?

    var id: UUID { mutationId }
}

struct SyncReplayResult: Equatable {
    var pendingMutations: [PendingSyncMutation]
    var replayPlan: [SyncReplayPlanItem]
    var statusMessage: String
    var toastMessage: String
}

struct LocalSyncReplayWorker: Equatable {
    var supabaseConfigured = false
    static let retryDelays: [TimeInterval] = [60, 300, 900, 3600, 21600]

    func plan(for mutations: [PendingSyncMutation]) -> [SyncReplayPlanItem] {
        mutations
            .filter { $0.status != .synced }
            .map(Self.planItem)
    }

    func retry(_ mutations: [PendingSyncMutation], attemptedAt: Date = Date()) -> SyncReplayResult {
        let replayPlan = plan(for: mutations)
        guard !replayPlan.isEmpty else {
            return SyncReplayResult(
                pendingMutations: mutations,
                replayPlan: [],
                statusMessage: "Nothing pending",
                toastMessage: "Nothing pending"
            )
        }

        guard supabaseConfigured else {
            let planByMutation = Dictionary(uniqueKeysWithValues: replayPlan.map { ($0.mutationId, $0) })
            let updatedMutations = mutations.map { mutation in
                guard mutation.status != .synced else { return mutation }
                var copy = mutation
                let planItem = planByMutation[mutation.id] ?? Self.planItem(for: mutation)
                copy.attemptCount += 1
                copy.status = .blockedNoBackend
                copy.lastAttemptedAt = attemptedAt
                copy.nextRetryAt = Self.nextRetryDate(afterAttemptCount: copy.attemptCount, attemptedAt: attemptedAt)
                copy.lastError = "Supabase not configured for \(planItem.action.rawValue) \(planItem.target)"
                return copy
            }
            return SyncReplayResult(
                pendingMutations: updatedMutations,
                replayPlan: replayPlan,
                statusMessage: "Sync blocked: Supabase not configured",
                toastMessage: "Backend setup required"
            )
        }

        let updatedMutations = mutations.map { mutation in
            guard mutation.status != .synced else { return mutation }
            var copy = mutation
            let planItem = replayPlan.first { $0.mutationId == mutation.id } ?? Self.planItem(for: mutation)
            copy.attemptCount += 1
            copy.status = .failedRetryable
            copy.lastAttemptedAt = attemptedAt
            copy.nextRetryAt = Self.nextRetryDate(afterAttemptCount: copy.attemptCount, attemptedAt: attemptedAt)
            copy.lastError = "Replay client not implemented for \(planItem.action.rawValue) \(planItem.target)"
            return copy
        }
        return SyncReplayResult(
            pendingMutations: updatedMutations,
            replayPlan: replayPlan,
            statusMessage: "Sync worker scaffolded; network client pending",
            toastMessage: "Sync worker scaffolded"
        )
    }

    static func nextRetryDate(afterAttemptCount attemptCount: Int, attemptedAt: Date) -> Date {
        let index = max(0, min(attemptCount - 1, retryDelays.count - 1))
        return attemptedAt.addingTimeInterval(retryDelays[index])
    }

    private static func planItem(for mutation: PendingSyncMutation) -> SyncReplayPlanItem {
        let route = route(for: mutation.kind)
        return SyncReplayPlanItem(
            mutationId: mutation.id,
            kind: mutation.kind,
            localRecordId: mutation.localRecordId,
            idempotencyKey: mutation.idempotencyKey,
            serverRecordId: mutation.serverRecordId,
            action: route.action,
            target: route.target,
            summary: mutation.summary,
            payload: mutation.payload,
            requiresReceipt: route.requiresReceipt,
            receiptId: mutation.receiptId
        )
    }

    private static func route(for kind: SyncMutationKind) -> (action: SyncReplayAction, target: String, requiresReceipt: Bool) {
        switch kind {
        case .authSession:
            return (.authenticate, "supabase.auth.session", false)
        case .onboardingProfile:
            return (.upsert, "public.onboarding_responses", false)
        case .healthLog:
            return (.upsert, "public.log_notes", false)
        case .healthLogUpdate:
            return (.update, "public.log_notes", false)
        case .healthLogDeletion:
            return (.softDelete, "public.log_notes.deleted_at", true)
        case .chatMessage:
            return (.insert, "public.chat_messages", false)
        case .privacyPreference:
            return (.upsert, "public.user_settings", false)
        case .safetyNotice:
            return (.insert, "public.audit_events", false)
        case .reportExport:
            return (.invokeFunction, "functions/export-report", true)
        case .accountDeletion:
            return (.invokeFunction, "functions/account-delete", true)
        }
    }
}

private enum AppDefaults {
    static let initialAssistantMessage = "How is your gut today? I can help make sense of logs, prepare questions, or flag symptoms that may need clinician attention."
}

struct AuthSession: Codable, Equatable {
    var userId: UUID
    var email: String
    var displayName: String
    var signedInAt: Date
    var isLocalScaffold: Bool

    static func local(email: String, displayName: String) -> AuthSession {
        AuthSession(
            userId: UUID(),
            email: email,
            displayName: displayName.isEmpty ? AppState.defaultDisplayName(for: email) : displayName,
            signedInAt: Date(),
            isLocalScaffold: true
        )
    }
}

struct OnboardingProfile: Codable, Equatable {
    var diagnosis: String
    var primaryGoal: String
    var baselineStoolCount: Int
    var hasFlarePlan: Bool
    var skippedSensitiveQuestions: Bool
    var completedAt: Date
}

struct AppSnapshotStore {
    var fileURL: URL

    static var live: AppSnapshotStore {
        AppSnapshotStore(fileURL: defaultFileURL())
    }

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    var fileExists: Bool {
        FileManager.default.fileExists(atPath: fileURL.path)
    }

    func load() -> AppSnapshot? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder.inflamend.decode(AppSnapshot.self, from: data)
    }

    func save(_ snapshot: AppSnapshot) throws {
        let data = try JSONEncoder.inflamend.encode(snapshot)
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: fileURL, options: [.atomic])
        try? FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: fileURL.path
        )
    }

    func delete() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    private static func defaultFileURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base
            .appendingPathComponent("Inflamend", isDirectory: true)
            .appendingPathComponent("app-snapshot-v1.json")
    }
}

private extension JSONEncoder {
    static var inflamend: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }
}

private extension JSONDecoder {
    static var inflamend: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

// MARK: - App State

@MainActor
@Observable
class AppState {
    @ObservationIgnored private let store: AppSnapshotStore
    @ObservationIgnored private let syncReplayWorker: LocalSyncReplayWorker

    var authSession: AuthSession? = nil
    var onboardingProfile: OnboardingProfile? = nil
    var riskScore: Int = 42
    var mood: MoodOption? = nil
    var medsTaken: Int = 2
    var medsTotal: Int = 4
    var latestSafetyMessage: String? = nil
    var aiMemoryEnabled: Bool = false
    var voiceTranscriptStorageEnabled: Bool = false
    var lastSyncStatus: String = "Saved on this device"
    var pendingSyncMutations: [PendingSyncMutation] = []
    var logs: [LogEntry] = []
    var chatMessages: [ChatMessage] = [
        ChatMessage(role: .assistant, content: AppDefaults.initialAssistantMessage)
    ]
    var toast: String? = nil
    var toastActionTitle: String? = nil
    @ObservationIgnored private var toastActionHandler: (() -> Void)? = nil
    @ObservationIgnored private var toastGeneration = 0
    private var toastTask: Task<Void, Never>? = nil

    init(store: AppSnapshotStore = .live, syncReplayWorker: LocalSyncReplayWorker = LocalSyncReplayWorker()) {
        self.store = store
        self.syncReplayWorker = syncReplayWorker
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--inflamend-reset-state") {
            store.delete()
        }
        if ProcessInfo.processInfo.arguments.contains("--inflamend-seed-complete-state") {
            seedCompleteState()
            persist()
            return
        }
        #endif
        if let snapshot = store.load() {
            apply(snapshot)
        } else if store.fileExists {
            lastSyncStatus = "Local snapshot unreadable; using clean state"
        }
    }

    var isAuthenticated: Bool {
        authSession != nil
    }

    var hasCompletedOnboarding: Bool {
        onboardingProfile != nil
    }

    var displayName: String {
        authSession?.displayName ?? "there"
    }

    var firstName: String {
        displayName.split(separator: " ").first.map(String.init) ?? displayName
    }

    var diagnosisLabel: String {
        onboardingProfile?.diagnosis ?? "IBD profile not completed"
    }

    var pendingSyncCount: Int {
        pendingSyncMutations.filter { $0.status != .synced }.count
    }

    var syncSummary: String {
        if pendingSyncCount == 0 {
            return lastSyncStatus
        }
        var statusPieces = ["\(pendingSyncCount) pending"]
        let blockedCount = pendingSyncMutations.filter { $0.status == .blockedNoBackend }.count
        if blockedCount > 0 {
            statusPieces.append("\(blockedCount) blocked")
        }
        let failedCount = pendingSyncMutations.filter {
            $0.status == .failedRetryable || $0.status == .failedNeedsUser
        }.count
        if failedCount > 0 {
            statusPieces.append("\(failedCount) failed")
        }
        return "\(statusPieces.joined(separator: " · ")) · \(lastSyncStatus)"
    }

    var pendingSyncReplayPlan: [SyncReplayPlanItem] {
        syncReplayWorker.plan(for: pendingSyncMutations)
    }

    func showToast(_ message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        toastTask?.cancel()
        toastGeneration += 1
        let generation = toastGeneration
        toastActionTitle = actionTitle
        toastActionHandler = action
        toast = message
        let duration: Duration = actionTitle == nil ? .seconds(2.2) : .seconds(5.5)
        toastTask = Task {
            do {
                try await Task.sleep(for: duration)
            } catch {
                return
            }
            guard self.toastGeneration == generation else { return }
            self.clearToast()
        }
    }

    func clearToast() {
        toastGeneration += 1
        toast = nil
        toastActionTitle = nil
        toastActionHandler = nil
    }

    func performToastAction() {
        toastActionHandler?()
    }

    func addLog(type: LogType, title: String, sub: String = "", date: Date = Date(), payload: HealthLogPayload? = nil) {
        let entry = LogEntry(type: type, title: title, sub: sub, loggedAt: date, payload: payload)
        logs.insert(entry, at: 0)
        enqueueSync(
            kind: .healthLog,
            localRecordId: entry.id.uuidString,
            summary: "\(type.rawValue): \(title)",
            payload: .healthLogSnapshot(for: entry)
        )
        persist()
    }

    func deleteLog(id: LogEntry.ID) {
        guard let index = logs.firstIndex(where: { $0.id == id }) else { return }
        let entry = logs[index]

        logs.remove(at: index)

        let localRecordId = entry.id.uuidString
        let hasUnreplayedCreate = pendingSyncMutations.contains {
            $0.kind == .healthLog && $0.localRecordId == localRecordId && $0.status != .synced
        }

        var removedMutations: [PendingSyncMutation] = []
        if hasUnreplayedCreate {
            removedMutations = pendingSyncMutations.filter {
                $0.kind == .healthLog && $0.localRecordId == localRecordId && $0.status != .synced
            }
            pendingSyncMutations.removeAll {
                $0.kind == .healthLog && $0.localRecordId == localRecordId && $0.status != .synced
            }
        } else {
            removedMutations = pendingSyncMutations.filter {
                $0.kind == .healthLogUpdate && $0.localRecordId == localRecordId && $0.status != .synced
            }
            pendingSyncMutations.removeAll {
                $0.kind == .healthLogUpdate && $0.localRecordId == localRecordId && $0.status != .synced
            }
            enqueueSync(
                kind: .healthLogDeletion,
                localRecordId: localRecordId,
                summary: "Deleted \(entry.type.rawValue): \(entry.title)"
            )
        }

        persist()
        showToast("Log removed", actionTitle: "Undo") { [weak self] in
            self?.restoreDeletedLog(entry, originalIndex: index, removedMutations: removedMutations)
        }
    }

    private func restoreDeletedLog(_ entry: LogEntry, originalIndex: Int, removedMutations: [PendingSyncMutation]) {
        toastTask?.cancel()
        clearToast()

        guard !logs.contains(where: { $0.id == entry.id }) else { return }
        let insertIndex = min(max(0, originalIndex), logs.count)
        logs.insert(entry, at: insertIndex)

        let localRecordId = entry.id.uuidString
        pendingSyncMutations.removeAll {
            $0.kind == .healthLogDeletion && $0.localRecordId == localRecordId && $0.status != .synced
        }
        for mutation in removedMutations.reversed() where !pendingSyncMutations.contains(where: { $0.id == mutation.id }) {
            pendingSyncMutations.insert(mutation, at: 0)
        }

        persist()
        showToast("Log restored")
    }

    @discardableResult
    func updateLog(
        id: LogEntry.ID,
        title: String,
        sub: String,
        preservePayload: Bool = false,
        payload editedPayload: HealthLogPayload? = nil
    ) -> Bool {
        guard let index = logs.firstIndex(where: { $0.id == id }) else { return false }

        let cleanedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedSub = sub.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedTitle.isEmpty else {
            showToast("Log title is required")
            return false
        }

        let previousPayload = logs[index].payload
        let payload: HealthLogPayload?
        if let editedPayload {
            payload = editedPayload.preservingDisplayEdits(title: cleanedTitle)
        } else {
            payload = preservePayload ? logs[index].payload?.preservingDisplayEdits(title: cleanedTitle) : nil
        }
        logs[index].title = cleanedTitle
        logs[index].sub = cleanedSub
        logs[index].payload = payload
        if editedPayload?.kind == .medication {
            reconcileMedicationAdherence(from: previousPayload, to: payload)
        } else if editedPayload?.kind == .checkIn {
            reconcileCheckInDerivedState(from: previousPayload, to: payload)
        }

        let entry = logs[index]
        let localRecordId = entry.id.uuidString
        if let pendingCreateIndex = pendingSyncMutations.firstIndex(where: {
            $0.kind == .healthLog && $0.localRecordId == localRecordId && $0.status != .synced
        }) {
            pendingSyncMutations[pendingCreateIndex].summary = "\(entry.type.rawValue): \(cleanedTitle)"
            pendingSyncMutations[pendingCreateIndex].payload = .healthLogSnapshot(for: entry)
            pendingSyncMutations[pendingCreateIndex].status = .pending
            pendingSyncMutations[pendingCreateIndex].attemptCount = 0
            pendingSyncMutations[pendingCreateIndex].lastAttemptedAt = nil
            pendingSyncMutations[pendingCreateIndex].nextRetryAt = nil
            pendingSyncMutations[pendingCreateIndex].lastError = nil
        } else if let pendingUpdateIndex = pendingSyncMutations.firstIndex(where: {
            $0.kind == .healthLogUpdate && $0.localRecordId == localRecordId && $0.status != .synced
        }) {
            pendingSyncMutations[pendingUpdateIndex].summary = "Updated \(entry.type.rawValue): \(cleanedTitle)"
            pendingSyncMutations[pendingUpdateIndex].payload = .healthLogSnapshot(for: entry)
            pendingSyncMutations[pendingUpdateIndex].status = .pending
            pendingSyncMutations[pendingUpdateIndex].attemptCount = 0
            pendingSyncMutations[pendingUpdateIndex].lastAttemptedAt = nil
            pendingSyncMutations[pendingUpdateIndex].nextRetryAt = nil
            pendingSyncMutations[pendingUpdateIndex].lastError = nil
        } else {
            enqueueSync(
                kind: .healthLogUpdate,
                localRecordId: localRecordId,
                summary: "Updated \(entry.type.rawValue): \(cleanedTitle)",
                payload: .healthLogSnapshot(for: entry)
            )
        }

        let safetyText = "\(cleanedTitle) \(cleanedSub)"
        if let bowelInput = payload?.bowelSafetyInput {
            publishSafety(RedFlagDetector.assess(text: safetyText, bowelLog: bowelInput))
        } else if let symptomInput = payload?.symptomSafetyInput {
            publishSafety(RedFlagDetector.assess(text: safetyText, symptomLog: symptomInput))
        } else if let checkInInput = payload?.checkInSafetyInput {
            publishSafety(RedFlagDetector.assess(text: safetyText, symptomLog: checkInInput))
        }

        persist()
        showToast("Log updated")
        return true
    }

    func recordCheckIn(status: MoodOption?, pain: Int, fatigue: Int, urgency: Int, stoolCount: Int, bloodPresent: Bool, medicationTaken: Bool, notes: String) {
        mood = status
        if medicationTaken, medsTaken < medsTotal {
            medsTaken += 1
        }

        let risk = RiskScoreService.calculate(
            RiskScoreInput(
                stoolCountToday: stoolCount,
                baselineStoolCount: 2,
                blood: bloodPresent ? .visible : BloodAmount.none,
                urgencyScore: urgency,
                painScore: pain,
                sleepHours: 7,
                missedMedication: !medicationTaken,
                userMarkedFlare: status == .flare,
                rapidWorsening: false
            )
        )
        riskScore = risk.score

        let symptomLog = SymptomLogInput(
            painScore: pain,
            fatigueScore: fatigue,
            urgencyScore: urgency,
            fever: false,
            dehydrationScore: 0,
            rapidWorsening: status == .flare
        )
        publishSafety(RedFlagDetector.assess(text: notes, symptomLog: symptomLog))

        let payload = HealthLogPayload.checkIn(
            status: status,
            pain: pain,
            fatigue: fatigue,
            urgency: urgency,
            stoolCount: stoolCount,
            bloodPresent: bloodPresent,
            medicationTaken: medicationTaken
        )
        addLog(
            type: .checkin,
            title: payload.checkInDisplayTitle ?? "\(status?.label ?? "Skipped status") check-in · pain \(pain)/10",
            sub: payload.checkInDisplayDetails ?? "Fatigue \(fatigue)/10 · urgency \(urgency)/10 · stool \(stoolCount)",
            payload: payload
        )
        showToast("Check-in saved")
    }

    func recordBowel(bristol: Int, urgency: Int, blood: BloodAmount, mucus: Bool, pain: Int, nighttime: Bool, notes: String = "") {
        let input = BowelLogInput(
            bristolType: bristol,
            urgencyScore: urgency,
            blood: blood,
            painScore: pain,
            nighttime: nighttime
        )
        publishSafety(RedFlagDetector.assess(text: notes, bowelLog: input))

        let risk = RiskScoreService.calculate(
            RiskScoreInput(
                stoolCountToday: max(3, logs.filter { $0.type == .bowel }.count + 1),
                baselineStoolCount: 2,
                blood: blood,
                urgencyScore: urgency,
                painScore: pain,
                sleepHours: 7,
                missedMedication: false,
                userMarkedFlare: false,
                rapidWorsening: nighttime && urgency >= 8
            )
        )
        riskScore = risk.score

        let payload = HealthLogPayload.bowel(
            bristol: bristol,
            urgency: urgency,
            blood: blood,
            mucus: mucus,
            pain: pain,
            nighttime: nighttime
        )
        addLog(
            type: .bowel,
            title: payload.bowelDisplayTitle ?? "Bowel movement",
            sub: payload.bowelDisplayDetails ?? "",
            payload: payload
        )
        showToast("Bowel movement saved")
    }

    func recordSymptoms(pain: Int, fatigue: Int, mood: Int) {
        let payload = HealthLogPayload.symptom(pain: pain, fatigue: fatigue, mood: mood)
        if let symptomInput = payload.symptomSafetyInput {
            publishSafety(RedFlagDetector.assess(symptomLog: symptomInput))
        }
        addLog(
            type: .symptom,
            title: payload.symptomDisplayTitle ?? "Symptoms logged",
            sub: payload.symptomDisplayDetails ?? "",
            payload: payload
        )
        showToast("Symptoms saved")
    }

    func recordSleep(quality: Int, bathroomWakeCount: Int) {
        let payload = HealthLogPayload.sleep(quality: quality, bathroomWakeCount: bathroomWakeCount)
        addLog(
            type: .sleep,
            title: payload.sleepDisplayTitle ?? "Sleep logged",
            sub: payload.sleepDisplayDetails ?? "",
            payload: payload
        )
        showToast("Sleep logged")
    }

    func recordWeight(value: Double, unit: String = "kg") {
        guard HealthLogValidator.isValidWeight(value) else {
            showToast("Enter a valid weight")
            return
        }

        let payload = HealthLogPayload.weight(value: value, unit: unit)
        addLog(
            type: .weight,
            title: payload.weightDisplayTitle ?? "Weight logged",
            sub: payload.weightDisplayDetails ?? "",
            payload: payload
        )
        showToast(payload.weightDisplayTitle ?? "Weight saved")
    }

    func recordVoiceDraft(_ draft: VoiceLogDraft) {
        let fieldSummary = draft.fields
            .sorted { $0.key < $1.key }
            .map { "\($0.key.replacingOccurrences(of: "_", with: " ")): \($0.value)" }
            .joined(separator: " · ")
        addLog(type: .voice, title: "Voice \(draft.type.rawValue) confirmed", sub: fieldSummary, payload: .voice(draft))
        publishSafety(RedFlagAssessment(flags: draft.safetyFlags))
        showToast("Voice log saved")
    }

    func recordMedicationTaken(name: String = "Medication") {
        if medsTaken < medsTotal {
            medsTaken += 1
        }
        let payload = HealthLogPayload.medication(name: name, status: "taken")
        addLog(
            type: .meds,
            title: payload.medicationDisplayTitle ?? "\(name) · taken",
            sub: payload.medicationDisplayDetails ?? "Logged manually",
            payload: payload
        )
        showToast("\(name) marked taken")
    }

    func clearSafetyMessage() {
        latestSafetyMessage = nil
        persist()
    }

    func signUp(email: String, displayName: String) {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.isValidEmail(trimmedEmail) else {
            showToast("Enter a valid email")
            return
        }
        authSession = .local(email: trimmedEmail, displayName: trimmedName)
        enqueueSync(kind: .authSession, localRecordId: authSession?.userId.uuidString ?? trimmedEmail, summary: "Local account scaffold")
        persist()
        showToast("Account scaffold created")
    }

    func signIn(email: String) {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard Self.isValidEmail(trimmedEmail) else {
            showToast("Enter a valid email")
            return
        }
        let existingName = authSession?.displayName ?? Self.defaultDisplayName(for: trimmedEmail)
        authSession = .local(email: trimmedEmail, displayName: existingName)
        enqueueSync(kind: .authSession, localRecordId: authSession?.userId.uuidString ?? trimmedEmail, summary: "Local sign in")
        persist()
        showToast("Signed in locally")
    }

    func signOut() {
        authSession = nil
        persist()
        showToast("Signed out")
    }

    func completeOnboarding(diagnosis: String, primaryGoal: String, baselineStoolCount: Int, hasFlarePlan: Bool, skippedSensitiveQuestions: Bool = false) {
        onboardingProfile = OnboardingProfile(
            diagnosis: diagnosis,
            primaryGoal: primaryGoal,
            baselineStoolCount: max(0, min(20, baselineStoolCount)),
            hasFlarePlan: hasFlarePlan,
            skippedSensitiveQuestions: skippedSensitiveQuestions,
            completedAt: Date()
        )
        enqueueSync(kind: .onboardingProfile, localRecordId: authSession?.userId.uuidString ?? "local-onboarding", summary: diagnosis)
        persist()
        showToast("Onboarding saved")
    }

    func skipOnboarding() {
        completeOnboarding(
            diagnosis: "Prefer not to say",
            primaryGoal: "Track symptoms",
            baselineStoolCount: 2,
            hasFlarePlan: false,
            skippedSensitiveQuestions: true
        )
    }

    func setAIMemoryEnabled(_ enabled: Bool) {
        aiMemoryEnabled = enabled
        enqueueSync(kind: .privacyPreference, localRecordId: "ai-memory", summary: enabled ? "AI memory on" : "AI memory off")
        persist()
        showToast("AI memory \(enabled ? "on" : "off")")
    }

    func setVoiceTranscriptStorageEnabled(_ enabled: Bool) {
        voiceTranscriptStorageEnabled = enabled
        enqueueSync(kind: .privacyPreference, localRecordId: "voice-transcripts", summary: enabled ? "Voice transcript storage on" : "Voice transcript storage off")
        persist()
        showToast("Transcript storage \(enabled ? "on" : "off")")
    }

    func addChatMessage(role: ChatRole, content: String) {
        let message = ChatMessage(role: role, content: content)
        chatMessages.append(message)
        if aiMemoryEnabled {
            enqueueSync(kind: .chatMessage, localRecordId: message.id.uuidString, summary: "\(role.rawValue) chat message")
        }
        persist()
    }

    func setSafetyMessage(_ message: String?) {
        latestSafetyMessage = message
        if let message, !message.isEmpty {
            enqueueSync(kind: .safetyNotice, localRecordId: "latest-safety", summary: "Safety notice shown")
        }
        persist()
    }

    func clearAIHistory() {
        chatMessages = [
            ChatMessage(role: .assistant, content: "AI history cleared on this device. Cloud deletion requires backend setup.")
        ]
        persist()
        showToast("AI history cleared locally")
    }

    func prepareUserDataExport() throws -> UserDataExport {
        let export = try UserDataExporter.writeJSONExport(snapshot: snapshot())
        addLog(type: .note, title: "User data exported", sub: export.fileName, payload: .note("User data exported: \(export.fileName)"))
        enqueueSync(kind: .reportExport, localRecordId: export.id.uuidString, summary: "User data JSON exported")
        persist()
        showToast("Data export ready to share")
        return export
    }

    func prepareDoctorReportExport() throws -> DoctorReportExport {
        let export = try DoctorReportExporter.writePlainTextReport(
            logs: logs,
            medsTaken: medsTaken,
            medsTotal: medsTotal,
            displayName: displayName
        )
        addLog(type: .note, title: "Doctor report exported", sub: export.fileName, payload: .note("Doctor report exported: \(export.fileName)"))
        enqueueSync(kind: .reportExport, localRecordId: export.id.uuidString, summary: "Doctor report exported")
        persist()
        showToast("Report ready to share")
        return export
    }

    func requestAccountDeletionScaffold() {
        enqueueSync(kind: .accountDeletion, localRecordId: "account-deletion-\(UUID().uuidString)", summary: "Account deletion requested")
        addLog(
            type: .note,
            title: "Account deletion requested",
            sub: "Requires signed-in backend account",
            payload: .note("Account deletion requested; requires signed-in backend account")
        )
        showToast("Account deletion scaffolded")
    }

    func retryPendingSyncScaffold() {
        guard !pendingSyncMutations.isEmpty else {
            lastSyncStatus = "Nothing pending"
            persist(updateSyncTimestamp: false)
            showToast("Nothing pending")
            return
        }
        let result = syncReplayWorker.retry(pendingSyncMutations)
        pendingSyncMutations = result.pendingMutations
        lastSyncStatus = result.statusMessage
        persist(updateSyncTimestamp: false)
        showToast(result.toastMessage)
    }

    private func publishSafety(_ assessment: RedFlagAssessment) {
        latestSafetyMessage = assessment.hasRedFlags ? assessment.safetyCopy : nil
        if assessment.hasRedFlags {
            enqueueSync(kind: .safetyNotice, localRecordId: "latest-safety", summary: "Safety notice shown")
        }
        persist()
    }

    private func reconcileMedicationAdherence(from previousPayload: HealthLogPayload?, to currentPayload: HealthLogPayload?) {
        guard previousPayload?.kind == .medication || currentPayload?.kind == .medication else { return }

        let wasTaken = Self.isTakenMedicationStatus(previousPayload?.medicationStatus)
        let isTaken = Self.isTakenMedicationStatus(currentPayload?.medicationStatus)

        if wasTaken && !isTaken {
            medsTaken = max(0, medsTaken - 1)
        } else if !wasTaken && isTaken {
            medsTaken = min(medsTotal, medsTaken + 1)
        }
    }

    private nonisolated static func isTakenMedicationStatus(_ status: String?) -> Bool {
        status?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "taken"
    }

    private func reconcileCheckInDerivedState(from previousPayload: HealthLogPayload?, to currentPayload: HealthLogPayload?) {
        guard previousPayload?.kind == .checkIn || currentPayload?.kind == .checkIn else { return }

        if previousPayload?.kind == .checkIn {
            let wasTaken = previousPayload?.medicationTaken == true
            let isTaken = currentPayload?.medicationTaken == true

            if wasTaken && !isTaken {
                medsTaken = max(0, medsTaken - 1)
            } else if !wasTaken && isTaken {
                medsTaken = min(medsTotal, medsTaken + 1)
            }
        }

        guard let currentPayload, currentPayload.kind == .checkIn else { return }
        mood = currentPayload.status
        if let riskInput = currentPayload.checkInRiskInput(baselineStoolCount: 2) {
            riskScore = RiskScoreService.calculate(riskInput).score
        }
    }

    private func snapshot() -> AppSnapshot {
        AppSnapshot(
            schemaVersion: 1,
            authSession: authSession,
            onboardingProfile: onboardingProfile,
            riskScore: riskScore,
            mood: mood,
            medsTaken: medsTaken,
            medsTotal: medsTotal,
            latestSafetyMessage: latestSafetyMessage,
            aiMemoryEnabled: aiMemoryEnabled,
            voiceTranscriptStorageEnabled: voiceTranscriptStorageEnabled,
            lastSyncStatus: lastSyncStatus,
            pendingSyncMutations: pendingSyncMutations,
            logs: logs,
            chatMessages: chatMessages
        )
    }

    private func apply(_ snapshot: AppSnapshot) {
        authSession = snapshot.authSession
        onboardingProfile = snapshot.onboardingProfile
        riskScore = snapshot.riskScore
        mood = snapshot.mood
        medsTaken = snapshot.medsTaken
        medsTotal = snapshot.medsTotal
        latestSafetyMessage = snapshot.latestSafetyMessage
        aiMemoryEnabled = snapshot.aiMemoryEnabled
        voiceTranscriptStorageEnabled = snapshot.voiceTranscriptStorageEnabled
        lastSyncStatus = snapshot.lastSyncStatus
        pendingSyncMutations = snapshot.pendingSyncMutations
        logs = snapshot.logs
        chatMessages = snapshot.chatMessages
    }

    private func enqueueSync(
        kind: SyncMutationKind,
        localRecordId: String,
        summary: String,
        payload: SyncMutationPayload? = nil
    ) {
        guard authSession != nil else { return }
        pendingSyncMutations.insert(
            PendingSyncMutation(kind: kind, localRecordId: localRecordId, summary: summary, payload: payload),
            at: 0
        )
    }

    private func persist(updateSyncTimestamp: Bool = true) {
        if updateSyncTimestamp {
            let localStatus = "Saved locally at \(Self.timeString(from: Date()))"
            lastSyncStatus = pendingSyncCount > 0 ? "\(localStatus) · backend pending" : localStatus
        }
        do {
            try store.save(snapshot())
        } catch {
            lastSyncStatus = "Local save failed"
        }
    }

    #if DEBUG
    private func seedCompleteState() {
        authSession = .local(email: "ui-test@example.com", displayName: "UI Test")
        onboardingProfile = OnboardingProfile(
            diagnosis: "Ulcerative colitis",
            primaryGoal: "Prepare doctor reports",
            baselineStoolCount: 2,
            hasFlarePlan: false,
            skippedSensitiveQuestions: false,
            completedAt: Date()
        )
        riskScore = 24
        medsTaken = 1
        medsTotal = 2
        logs = [
            LogEntry(type: .note, title: "UI test export note", sub: "Seeded local log", time: Self.timeString(from: Date()))
        ]
        chatMessages = [
            ChatMessage(role: .assistant, content: AppDefaults.initialAssistantMessage),
            ChatMessage(role: .user, content: "UI test saved Care note")
        ]
        pendingSyncMutations = []
        lastSyncStatus = "Seeded for UI testing"
    }
    #endif

    nonisolated static func defaultDisplayName(for email: String) -> String {
        let localPart = email.split(separator: "@").first.map(String.init) ?? "there"
        let cleaned = localPart
            .replacingOccurrences(of: ".", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
        return cleaned.split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }

    private nonisolated static func isValidEmail(_ email: String) -> Bool {
        let parts = email.split(separator: "@")
        guard parts.count == 2 else { return false }
        return parts[1].contains(".")
    }

    private static func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        return formatter.string(from: date).lowercased()
    }
}

// MARK: - Log Entry

struct HealthLogPayload: Codable, Equatable {
    enum Kind: String, Codable {
        case checkIn
        case bowel
        case food
        case symptom
        case medication
        case sleep
        case weight
        case note
        case voice
    }

    var kind: Kind
    var status: MoodOption?
    var painScore: Int?
    var fatigueScore: Int?
    var urgencyScore: Int?
    var moodScore: Int?
    var stoolCount: Int?
    var blood: BloodAmount?
    var medicationTaken: Bool?
    var bristolType: Int?
    var mucus: Bool?
    var nighttime: Bool?
    var mealTime: String?
    var foodDescription: String?
    var foodTags: [String]?
    var medicationName: String?
    var medicationStatus: String?
    var sleepQuality: Int?
    var bathroomWakeCount: Int?
    var weightValue: Double?
    var weightUnit: String?
    var note: String?
    var voiceType: VoiceLogType?
    var voiceFields: [String: String]?
    var safetyFlags: [RedFlagKind]?

    init(
        kind: Kind,
        status: MoodOption? = nil,
        painScore: Int? = nil,
        fatigueScore: Int? = nil,
        urgencyScore: Int? = nil,
        moodScore: Int? = nil,
        stoolCount: Int? = nil,
        blood: BloodAmount? = nil,
        medicationTaken: Bool? = nil,
        bristolType: Int? = nil,
        mucus: Bool? = nil,
        nighttime: Bool? = nil,
        mealTime: String? = nil,
        foodDescription: String? = nil,
        foodTags: [String]? = nil,
        medicationName: String? = nil,
        medicationStatus: String? = nil,
        sleepQuality: Int? = nil,
        bathroomWakeCount: Int? = nil,
        weightValue: Double? = nil,
        weightUnit: String? = nil,
        note: String? = nil,
        voiceType: VoiceLogType? = nil,
        voiceFields: [String: String]? = nil,
        safetyFlags: [RedFlagKind]? = nil
    ) {
        self.kind = kind
        self.status = status
        self.painScore = painScore
        self.fatigueScore = fatigueScore
        self.urgencyScore = urgencyScore
        self.moodScore = moodScore
        self.stoolCount = stoolCount
        self.blood = blood
        self.medicationTaken = medicationTaken
        self.bristolType = bristolType
        self.mucus = mucus
        self.nighttime = nighttime
        self.mealTime = mealTime
        self.foodDescription = foodDescription
        self.foodTags = foodTags
        self.medicationName = medicationName
        self.medicationStatus = medicationStatus
        self.sleepQuality = sleepQuality
        self.bathroomWakeCount = bathroomWakeCount
        self.weightValue = weightValue
        self.weightUnit = weightUnit
        self.note = note
        self.voiceType = voiceType
        self.voiceFields = voiceFields
        self.safetyFlags = safetyFlags
    }

    static func checkIn(
        status: MoodOption?,
        pain: Int,
        fatigue: Int,
        urgency: Int,
        stoolCount: Int,
        bloodPresent: Bool,
        medicationTaken: Bool
    ) -> HealthLogPayload {
        HealthLogPayload(
            kind: .checkIn,
            status: status,
            painScore: pain,
            fatigueScore: fatigue,
            urgencyScore: urgency,
            stoolCount: stoolCount,
            blood: bloodPresent ? .visible : BloodAmount.none,
            medicationTaken: medicationTaken
        )
    }

    static func bowel(
        bristol: Int,
        urgency: Int,
        blood: BloodAmount,
        mucus: Bool,
        pain: Int,
        nighttime: Bool
    ) -> HealthLogPayload {
        HealthLogPayload(
            kind: .bowel,
            painScore: pain,
            urgencyScore: urgency,
            blood: blood,
            bristolType: bristol,
            mucus: mucus,
            nighttime: nighttime
        )
    }

    static func food(mealTime: String, description: String, tags: [String]) -> HealthLogPayload {
        HealthLogPayload(
            kind: .food,
            mealTime: mealTime,
            foodDescription: description,
            foodTags: tags
        )
    }

    static func symptom(pain: Int, fatigue: Int, mood: Int) -> HealthLogPayload {
        HealthLogPayload(
            kind: .symptom,
            painScore: pain,
            fatigueScore: fatigue,
            moodScore: mood
        )
    }

    static func medication(name: String, status: String) -> HealthLogPayload {
        HealthLogPayload(kind: .medication, medicationName: name, medicationStatus: status)
    }

    static func sleep(quality: Int, bathroomWakeCount: Int) -> HealthLogPayload {
        HealthLogPayload(kind: .sleep, sleepQuality: quality, bathroomWakeCount: bathroomWakeCount)
    }

    static func weight(value: Double?, unit: String) -> HealthLogPayload {
        HealthLogPayload(kind: .weight, weightValue: value, weightUnit: unit)
    }

    static func note(_ note: String) -> HealthLogPayload {
        HealthLogPayload(kind: .note, note: note)
    }

    static func voice(_ draft: VoiceLogDraft) -> HealthLogPayload {
        HealthLogPayload(
            kind: .voice,
            voiceType: draft.type,
            voiceFields: draft.fields,
            safetyFlags: draft.safetyFlags
        )
    }

    func preservingDisplayEdits(title: String) -> HealthLogPayload {
        var updated = self
        switch kind {
        case .food:
            updated.foodDescription = title
        case .note:
            updated.note = title
        case .checkIn, .bowel, .symptom, .medication, .sleep, .weight, .voice:
            break
        }
        return updated
    }

    var checkInDisplayTitle: String? {
        guard kind == .checkIn else { return nil }
        return "\(status?.label ?? "Skipped status") check-in · pain \(painScore ?? 0)/10"
    }

    var checkInDisplayDetails: String? {
        guard kind == .checkIn else { return nil }
        var parts = [
            "Fatigue \(fatigueScore ?? 0)/10",
            "urgency \(urgencyScore ?? 0)/10",
            "stool \(stoolCount ?? 0)"
        ]
        if let bloodAmount = blood, bloodAmount != BloodAmount.none {
            parts.append("blood present")
        }
        if medicationTaken == false {
            parts.append("medication not taken")
        }
        return parts.joined(separator: " · ")
    }

    var checkInSafetyInput: SymptomLogInput? {
        guard kind == .checkIn else { return nil }
        return SymptomLogInput(
            painScore: painScore ?? 0,
            fatigueScore: fatigueScore ?? 0,
            urgencyScore: urgencyScore ?? 0,
            fever: false,
            dehydrationScore: 0,
            rapidWorsening: status == .flare
        )
    }

    func checkInRiskInput(baselineStoolCount: Int) -> RiskScoreInput? {
        guard kind == .checkIn else { return nil }
        return RiskScoreInput(
            stoolCountToday: stoolCount ?? 0,
            baselineStoolCount: baselineStoolCount,
            blood: blood ?? BloodAmount.none,
            urgencyScore: urgencyScore ?? 0,
            painScore: painScore ?? 0,
            sleepHours: 7,
            missedMedication: medicationTaken == false,
            userMarkedFlare: status == .flare,
            rapidWorsening: false
        )
    }

    var bowelDisplayTitle: String? {
        guard kind == .bowel else { return nil }
        let bristol = bristolType ?? 4
        let urgency = urgencyScore ?? 0
        return "Bristol \(bristol) · urgency \(urgency)/10"
    }

    var bowelDisplayDetails: String? {
        guard kind == .bowel else { return nil }
        let bloodAmount = blood ?? .none
        let bloodLabel = bloodAmount == .none ? "no blood" : "\(bloodAmount.rawValue) blood"
        return [bloodLabel, mucus == true ? "mucus" : nil, nighttime == true ? "nighttime" : nil]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    var bowelSafetyInput: BowelLogInput? {
        guard kind == .bowel else { return nil }
        return BowelLogInput(
            bristolType: bristolType ?? 4,
            urgencyScore: urgencyScore ?? 0,
            blood: blood ?? .none,
            painScore: painScore ?? 0,
            nighttime: nighttime ?? false
        )
    }

    var symptomDisplayTitle: String? {
        guard kind == .symptom else { return nil }
        return "Pain \(painScore ?? 0)/10 · fatigue \(fatigueScore ?? 0)/10"
    }

    var symptomDisplayDetails: String? {
        guard kind == .symptom else { return nil }
        return "Mood \(moodScore ?? 0)/10"
    }

    var symptomSafetyInput: SymptomLogInput? {
        guard kind == .symptom else { return nil }
        return SymptomLogInput(
            painScore: painScore ?? 0,
            fatigueScore: fatigueScore ?? 0,
            urgencyScore: urgencyScore ?? 0,
            fever: false,
            dehydrationScore: 0,
            rapidWorsening: false
        )
    }

    var medicationDisplayTitle: String? {
        guard kind == .medication else { return nil }
        return "\(medicationName ?? "Medication") · \(medicationStatus ?? "taken")"
    }

    var medicationDisplayDetails: String? {
        guard kind == .medication else { return nil }
        return "Logged manually"
    }

    var sleepDisplayTitle: String? {
        guard kind == .sleep else { return nil }
        return "Sleep quality \(sleepQuality ?? 0)/10"
    }

    var sleepDisplayDetails: String? {
        guard kind == .sleep else { return nil }
        let count = bathroomWakeCount ?? 0
        return "\(count) bathroom \(count == 1 ? "wake" : "wakes")"
    }

    var weightDisplayTitle: String? {
        guard kind == .weight, let weightValue else { return nil }
        return "Weight · \(Self.formattedWeight(weightValue)) \(weightUnit ?? "kg")"
    }

    var weightDisplayDetails: String? {
        guard kind == .weight else { return nil }
        return "Manual entry"
    }

    static func formattedWeight(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}

struct LogEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var type: LogType
    var title: String
    var sub: String
    var time: String
    var loggedAt: Date
    var payload: HealthLogPayload?

    init(
        id: UUID = UUID(),
        type: LogType,
        title: String,
        sub: String,
        time: String? = nil,
        loggedAt: Date = Date(),
        payload: HealthLogPayload? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.sub = sub
        self.loggedAt = loggedAt
        self.time = time ?? Self.displayTime(from: loggedAt)
        self.payload = payload
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case sub
        case time
        case loggedAt
        case payload
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        type = try container.decode(LogType.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        sub = try container.decodeIfPresent(String.self, forKey: .sub) ?? ""
        loggedAt = try container.decodeIfPresent(Date.self, forKey: .loggedAt) ?? Date()
        time = try container.decodeIfPresent(String.self, forKey: .time) ?? Self.displayTime(from: loggedAt)
        payload = try container.decodeIfPresent(HealthLogPayload.self, forKey: .payload)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(title, forKey: .title)
        try container.encode(sub, forKey: .sub)
        try container.encode(time, forKey: .time)
        try container.encode(loggedAt, forKey: .loggedAt)
        try container.encodeIfPresent(payload, forKey: .payload)
    }

    private static func displayTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        return formatter.string(from: date).lowercased()
    }
}

enum LogType: String, Codable, Equatable {
    case checkin, food, bowel, symptom, meds, water, sleep, weight, note, voice

    var iconName: String {
        switch self {
        case .checkin: return "check"
        case .food:    return "fork"
        case .bowel:   return "activity"
        case .symptom: return "heart"
        case .meds:    return "pill"
        case .water:   return "droplet"
        case .sleep:   return "moon"
        case .weight:  return "chart"
        case .note:    return "note"
        case .voice:   return "mic"
        }
    }
    var color: Color {
        switch self {
        case .checkin: return .sage
        case .food:    return .sage
        case .bowel:   return .clay
        case .symptom: return .amber
        case .meds:    return .ink
        case .water:   return .ink
        case .sleep:   return .amber
        case .weight:  return .ink
        case .note:    return .fgDim
        case .voice:   return .sage
        }
    }
}

// MARK: - Mood

enum MoodOption: String, CaseIterable, Codable {
    case great = "great"
    case ok    = "ok"
    case rough = "rough"
    case flare = "flare"

    var label: String {
        switch self {
        case .great: return "Great"
        case .ok:    return "Okay"
        case .rough: return "Rough"
        case .flare: return "Flare"
        }
    }
    var icon: String {
        switch self {
        case .great: return "◎"
        case .ok:    return "○"
        case .rough: return "◐"
        case .flare: return "●"
        }
    }
    var color: Color {
        switch self {
        case .great: return .sage
        case .ok:    return .fgDim
        case .rough: return .amber
        case .flare: return .clay
        }
    }
}

// MARK: - Chat

struct ChatMessage: Identifiable, Codable, Equatable {
    var id = UUID()
    var role: ChatRole
    var content: String
}

enum ChatRole: String, Codable, Equatable { case user, assistant }

// MARK: - Meds

struct MedEntry: Identifiable {
    let id = UUID()
    var name: String
    var dose: String
    var time: String
    var taken: Bool
}
