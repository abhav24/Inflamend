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
    case food, bowel, symptom, meds, water, sleep, weight

    var iconName: String {
        switch self {
        case .food:    return "fork"
        case .bowel:   return "activity"
        case .symptom: return "heart"
        case .meds:    return "pill"
        case .water:   return "droplet"
        case .sleep:   return "moon"
        case .weight:  return "chart"
        }
    }
    var color: Color {
        switch self {
        case .food:    return .sage
        case .bowel:   return .clay
        case .symptom: return .amber
        case .meds:    return .ink
        case .water:   return .ink
        case .sleep:   return .amber
        case .weight:  return .ink
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
