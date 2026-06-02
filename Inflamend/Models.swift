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
    case failedNeedsUser
}

struct PendingSyncMutation: Identifiable, Codable, Equatable {
    var id = UUID()
    var kind: SyncMutationKind
    var localRecordId: String
    var summary: String
    var createdAt = Date()
    var attemptCount = 0
    var status: SyncMutationStatus = .pending
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
    private var toastTask: Task<Void, Never>? = nil

    init(store: AppSnapshotStore = .live) {
        self.store = store
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
        return "\(pendingSyncCount) pending · \(lastSyncStatus)"
    }

    func showToast(_ message: String) {
        toast = message
        toastTask?.cancel()
        toastTask = Task {
            try? await Task.sleep(for: .seconds(2.2))
            self.toast = nil
        }
    }

    func addLog(type: LogType, title: String, sub: String = "", date: Date = Date()) {
        let entry = LogEntry(type: type, title: title, sub: sub, time: Self.timeString(from: date))
        logs.insert(entry, at: 0)
        enqueueSync(kind: .healthLog, localRecordId: entry.id.uuidString, summary: "\(type.rawValue): \(title)")
        persist()
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
                blood: bloodPresent ? .visible : .none,
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

        let statusLabel = status?.label ?? "Skipped status"
        addLog(
            type: .checkin,
            title: "\(statusLabel) check-in · pain \(pain)/10",
            sub: "Fatigue \(fatigue)/10 · urgency \(urgency)/10 · stool \(stoolCount)"
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

        let bloodLabel = blood == .none ? "no blood" : "\(blood.rawValue) blood"
        let details = [bloodLabel, mucus ? "mucus" : nil, nighttime ? "nighttime" : nil]
            .compactMap { $0 }
            .joined(separator: " · ")
        addLog(type: .bowel, title: "Bristol \(bristol) · urgency \(urgency)/10", sub: details)
        showToast("Bowel movement saved")
    }

    func recordVoiceDraft(_ draft: VoiceLogDraft) {
        let fieldSummary = draft.fields
            .sorted { $0.key < $1.key }
            .map { "\($0.key.replacingOccurrences(of: "_", with: " ")): \($0.value)" }
            .joined(separator: " · ")
        addLog(type: .voice, title: "Voice \(draft.type.rawValue) confirmed", sub: fieldSummary)
        publishSafety(RedFlagAssessment(flags: draft.safetyFlags))
        showToast("Voice log saved")
    }

    func recordMedicationTaken(name: String = "Medication") {
        if medsTaken < medsTotal {
            medsTaken += 1
        }
        addLog(type: .meds, title: "\(name) · taken", sub: "Logged manually")
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
        addLog(type: .note, title: "User data exported", sub: export.fileName)
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
        addLog(type: .note, title: "Doctor report exported", sub: export.fileName)
        enqueueSync(kind: .reportExport, localRecordId: export.id.uuidString, summary: "Doctor report exported")
        persist()
        showToast("Report ready to share")
        return export
    }

    func requestAccountDeletionScaffold() {
        enqueueSync(kind: .accountDeletion, localRecordId: "account-deletion-\(UUID().uuidString)", summary: "Account deletion requested")
        addLog(type: .note, title: "Account deletion requested", sub: "Requires signed-in backend account")
        showToast("Account deletion scaffolded")
    }

    func retryPendingSyncScaffold() {
        guard !pendingSyncMutations.isEmpty else {
            lastSyncStatus = "Nothing pending"
            persist(updateSyncTimestamp: false)
            showToast("Nothing pending")
            return
        }
        pendingSyncMutations = pendingSyncMutations.map { mutation in
            var copy = mutation
            copy.attemptCount += 1
            copy.status = .blockedNoBackend
            return copy
        }
        lastSyncStatus = "Sync blocked: Supabase not configured"
        persist(updateSyncTimestamp: false)
        showToast("Backend setup required")
    }

    private func publishSafety(_ assessment: RedFlagAssessment) {
        latestSafetyMessage = assessment.hasRedFlags ? assessment.safetyCopy : nil
        if assessment.hasRedFlags {
            enqueueSync(kind: .safetyNotice, localRecordId: "latest-safety", summary: "Safety notice shown")
        }
        persist()
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

    private func enqueueSync(kind: SyncMutationKind, localRecordId: String, summary: String) {
        guard authSession != nil else { return }
        pendingSyncMutations.insert(
            PendingSyncMutation(kind: kind, localRecordId: localRecordId, summary: summary),
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

struct LogEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var type: LogType
    var title: String
    var sub: String
    var time: String
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
