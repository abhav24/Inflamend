import Foundation
import SwiftUI

// MARK: - App State

@MainActor
@Observable
class AppState {
    var riskScore: Int = 42
    var mood: MoodOption? = nil
    var medsTaken: Int = 2
    var medsTotal: Int = 4
    var latestSafetyMessage: String? = nil
    var aiMemoryEnabled: Bool = false
    var voiceTranscriptStorageEnabled: Bool = false
    var lastSyncStatus: String = "Saved on this device"
    var logs: [LogEntry] = [
        LogEntry(type: .sleep,   title: "Slept 7h 20m · quality 7/10", sub: "1 bathroom wake",    time: "6:40a"),
        LogEntry(type: .meds,    title: "Mesalamine · 800mg",           sub: "Azathioprine · 50mg", time: "8:00a"),
        LogEntry(type: .food,    title: "Oatmeal, banana, almond milk", sub: "Safe · breakfast",   time: "8:30a"),
        LogEntry(type: .water,   title: "Water · 500ml",                sub: "",                   time: "10:15a"),
        LogEntry(type: .symptom, title: "Mild pain · urgency 3/10",     sub: "Lower abdomen",      time: "11:20a"),
    ]
    var chatMessages: [ChatMessage] = [
        ChatMessage(role: .assistant, content: "Hi Priya — how's your gut today? I can help make sense of your logs, talk through meals, or just listen.")
    ]
    var toast: String? = nil
    private var toastTask: Task<Void, Never>? = nil

    func showToast(_ message: String) {
        toast = message
        toastTask?.cancel()
        toastTask = Task {
            try? await Task.sleep(for: .seconds(2.2))
            self.toast = nil
        }
    }

    func addLog(type: LogType, title: String, sub: String = "", date: Date = Date()) {
        logs.insert(LogEntry(type: type, title: title, sub: sub, time: Self.timeString(from: date)), at: 0)
        lastSyncStatus = "Saved on this device"
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
    }

    private func publishSafety(_ assessment: RedFlagAssessment) {
        latestSafetyMessage = assessment.hasRedFlags ? assessment.safetyCopy : nil
    }

    private static func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        return formatter.string(from: date).lowercased()
    }
}

// MARK: - Log Entry

struct LogEntry: Identifiable {
    let id = UUID()
    var type: LogType
    var title: String
    var sub: String
    var time: String
}

enum LogType {
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

enum MoodOption: String, CaseIterable {
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

struct ChatMessage: Identifiable {
    let id = UUID()
    var role: ChatRole
    var content: String
}

enum ChatRole { case user, assistant }

// MARK: - Meds

struct MedEntry: Identifiable {
    let id = UUID()
    var name: String
    var dose: String
    var time: String
    var taken: Bool
}
