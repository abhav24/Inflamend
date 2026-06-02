import Foundation

enum RedFlagKind: String, CaseIterable, Equatable {
    case severeAbdominalPain
    case heavyBleeding
    case blackTarryStool
    case highFever
    case fainting
    case severeDehydration
    case unableToKeepFluidsDown
    case chestPain
    case shortnessOfBreath
    case rapidWeightLoss
    case rapidWorsening
    case selfHarm

    var userMessage: String {
        switch self {
        case .severeAbdominalPain: return "Severe abdominal pain can be serious."
        case .heavyBleeding: return "Heavy bleeding needs prompt medical guidance."
        case .blackTarryStool: return "Black or tarry stool can be a serious warning sign."
        case .highFever: return "High fever with IBD symptoms can be serious."
        case .fainting: return "Fainting or feeling like you may pass out needs urgent attention."
        case .severeDehydration: return "Severe dehydration can become urgent quickly."
        case .unableToKeepFluidsDown: return "Being unable to keep fluids down can be serious."
        case .chestPain: return "Chest pain needs urgent medical attention."
        case .shortnessOfBreath: return "Shortness of breath needs urgent medical attention."
        case .rapidWeightLoss: return "Rapid weight loss should be discussed with a clinician."
        case .rapidWorsening: return "Rapidly worsening symptoms should be reviewed promptly."
        case .selfHarm: return "If you may hurt yourself, seek immediate support now."
        }
    }
}

struct RedFlagAssessment: Equatable {
    let flags: [RedFlagKind]

    var hasRedFlags: Bool { !flags.isEmpty }

    var safetyCopy: String {
        guard hasRedFlags else {
            return "No urgent red flags were detected from this entry. Keep tracking changes and contact your clinician if you are concerned."
        }

        return "Some symptoms you logged can be serious. Inflamend is not a doctor and cannot diagnose or triage emergencies. If symptoms feel severe, rapidly worsening, or unsafe, contact urgent medical care, emergency services, or your clinician now."
    }
}

enum RedFlagDetector {
    static func assess(text: String = "", bowelLog: BowelLogInput? = nil, symptomLog: SymptomLogInput? = nil) -> RedFlagAssessment {
        var found = Set<RedFlagKind>()
        let normalized = text.lowercased()

        let textRules: [(RedFlagKind, [String])] = [
            (.severeAbdominalPain, ["severe abdominal pain", "worst stomach pain", "pain 10", "pain is 10"]),
            (.heavyBleeding, ["heavy bleeding", "lots of blood", "significant blood", "large amount of blood"]),
            (.blackTarryStool, ["black stool", "tarry stool", "black and tarry"]),
            (.highFever, ["high fever", "104 fever", "103 fever"]),
            (.fainting, ["fainting", "passed out", "passing out", "fainted"]),
            (.severeDehydration, ["severe dehydration", "very dehydrated", "dizzy and dehydrated"]),
            (.unableToKeepFluidsDown, ["can't keep fluids down", "cannot keep fluids down", "unable to keep fluids down"]),
            (.chestPain, ["chest pain"]),
            (.shortnessOfBreath, ["shortness of breath", "can't breathe", "cannot breathe"]),
            (.rapidWeightLoss, ["rapid weight loss", "lost weight quickly"]),
            (.rapidWorsening, ["rapidly worse", "rapid worsening", "getting worse fast"]),
            (.selfHarm, ["suicidal", "self harm", "kill myself"])
        ]

        for (kind, phrases) in textRules where phrases.contains(where: normalized.contains) {
            found.insert(kind)
        }

        if let bowelLog {
            if bowelLog.blood == .significant { found.insert(.heavyBleeding) }
            if bowelLog.blood == .visible, bowelLog.urgencyScore >= 8 { found.insert(.heavyBleeding) }
            if bowelLog.painScore >= 8 { found.insert(.severeAbdominalPain) }
            if bowelLog.nighttime && bowelLog.urgencyScore >= 8 { found.insert(.rapidWorsening) }
        }

        if let symptomLog {
            if symptomLog.painScore >= 8 { found.insert(.severeAbdominalPain) }
            if symptomLog.fever { found.insert(.highFever) }
            if symptomLog.dehydrationScore >= 8 { found.insert(.severeDehydration) }
            if symptomLog.rapidWorsening { found.insert(.rapidWorsening) }
        }

        let ordered = RedFlagKind.allCases.filter(found.contains)
        return RedFlagAssessment(flags: ordered)
    }
}

enum BloodAmount: String, Equatable {
    case none
    case trace
    case visible
    case significant
}

struct BowelLogInput: Equatable {
    var bristolType: Int
    var urgencyScore: Int
    var blood: BloodAmount
    var painScore: Int
    var nighttime: Bool
}

struct SymptomLogInput: Equatable {
    var painScore: Int
    var fatigueScore: Int
    var urgencyScore: Int
    var fever: Bool
    var dehydrationScore: Int
    var rapidWorsening: Bool
}

struct RiskScoreInput: Equatable {
    var stoolCountToday: Int
    var baselineStoolCount: Int
    var blood: BloodAmount
    var urgencyScore: Int
    var painScore: Int
    var sleepHours: Double
    var missedMedication: Bool
    var userMarkedFlare: Bool
    var rapidWorsening: Bool
}

struct RiskFactor: Equatable {
    enum Severity: String {
        case low
        case medium
        case high
    }

    let label: String
    let severity: Severity
}

struct RiskScoreResult: Equatable {
    let score: Int
    let tier: String
    let factors: [RiskFactor]
    let disclaimer: String
}

enum RiskScoreService {
    static func calculate(_ input: RiskScoreInput) -> RiskScoreResult {
        var score = 12
        var factors: [RiskFactor] = []

        if input.stoolCountToday > max(3, input.baselineStoolCount + 2) {
            score += 15
            factors.append(RiskFactor(label: "Bowel frequency is above your logged baseline.", severity: .medium))
        }

        switch input.blood {
        case .none:
            break
        case .trace:
            score += 10
            factors.append(RiskFactor(label: "Trace blood was logged.", severity: .medium))
        case .visible:
            score += 20
            factors.append(RiskFactor(label: "Visible blood was logged.", severity: .high))
        case .significant:
            score += 28
            factors.append(RiskFactor(label: "Significant blood was logged.", severity: .high))
        }

        if input.urgencyScore >= 7 {
            score += 14
            factors.append(RiskFactor(label: "Urgency is high.", severity: .medium))
        }

        if input.painScore >= 7 {
            score += 14
            factors.append(RiskFactor(label: "Pain is high.", severity: .medium))
        }

        if input.sleepHours > 0 && input.sleepHours < 5 {
            score += 8
            factors.append(RiskFactor(label: "Sleep was short.", severity: .low))
        }

        if input.missedMedication {
            score += 12
            factors.append(RiskFactor(label: "A medication dose was missed or skipped.", severity: .medium))
        }

        if input.userMarkedFlare {
            score += 18
            factors.append(RiskFactor(label: "You marked today as a flare day.", severity: .high))
        }

        if input.rapidWorsening {
            score += 18
            factors.append(RiskFactor(label: "Symptoms may be worsening quickly.", severity: .high))
        }

        let finalScore = min(100, max(0, score))
        return RiskScoreResult(
            score: finalScore,
            tier: finalScore < 30 ? "low" : finalScore < 60 ? "medium" : "high",
            factors: factors,
            disclaimer: "This score is a tracking aid based on self-reported data. It is not medically validated and is not a diagnosis."
        )
    }
}

enum VoiceLogType: String, Equatable {
    case bowel
    case meal
    case medication
    case symptom
    case sleep
    case weight
    case note
}

struct VoiceLogDraft: Equatable {
    enum Confidence: String {
        case high
        case medium
        case ambiguous
    }

    let type: VoiceLogType
    let confidence: Confidence
    let fields: [String: String]
    let safetyFlags: [RedFlagKind]

    var requiresConfirmation: Bool { true }
}

enum VoiceLogParser {
    static func parse(_ transcript: String) -> VoiceLogDraft {
        let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = text.lowercased()
        let numericText = normalizeNumberWords(in: normalized)
        let flags = RedFlagDetector.assess(text: text).flags

        if containsAny(normalized, ["bowel", "movement", "bristol", "stool", "poop"]) {
            var fields: [String: String] = [:]
            fields["bristol_type"] = firstMatch(in: numericText, pattern: #"bristol\s*(\d)|type\s*(\d)"#)
            fields["stool_count"] = firstMatch(in: numericText, pattern: #"(\d+)\s+(bowel|movement|movements|stools)"#)
            fields["blood"] = normalized.contains("no blood") ? "none" : normalized.contains("blood") ? "visible" : nil
            fields["urgency_score"] = firstMatch(in: numericText, pattern: #"urgency\s*(?:is\s*)?(\d+)"#)
            return VoiceLogDraft(type: .bowel, confidence: fields.isEmpty ? .ambiguous : .medium, fields: fields, safetyFlags: flags)
        }

        if containsAny(normalized, ["took", "taken", "med", "medicine", "mesalamine", "dose", "pill"]) {
            var fields: [String: String] = ["status": containsAny(normalized, ["skip", "miss"]) ? "skipped" : "taken"]
            fields["medication_name"] = firstMedicationName(in: normalized)
            return VoiceLogDraft(type: .medication, confidence: .medium, fields: fields, safetyFlags: flags)
        }

        if containsAny(normalized, ["ate", "meal", "breakfast", "lunch", "dinner", "snack", "food"]) {
            var fields: [String: String] = ["description": text]
            fields["meal_type"] = ["breakfast", "lunch", "dinner", "snack"].first(where: normalized.contains)
            return VoiceLogDraft(type: .meal, confidence: .medium, fields: fields, safetyFlags: flags)
        }

        if containsAny(normalized, ["slept", "sleep", "woke", "bathroom"]) {
            var fields: [String: String] = [:]
            fields["duration_hours"] = firstMatch(in: numericText, pattern: #"(\d+(?:\.\d+)?)\s*(hours|hour|hrs|hr)"#)
            fields["bathroom_wakes"] = firstMatch(in: numericText, pattern: #"woke(?: up)?\s*(\d+)"#)
            return VoiceLogDraft(type: .sleep, confidence: fields.isEmpty ? .ambiguous : .medium, fields: fields, safetyFlags: flags)
        }

        if containsAny(normalized, ["weight", "pounds", "lbs", "kg"]) {
            var fields: [String: String] = [:]
            fields["weight_value"] = firstMatch(in: numericText, pattern: #"(\d+(?:\.\d+)?)"#)
            fields["unit"] = containsAny(normalized, ["kg", "kilogram"]) ? "kg" : "lb"
            return VoiceLogDraft(type: .weight, confidence: fields["weight_value"] == nil ? .ambiguous : .medium, fields: fields, safetyFlags: flags)
        }

        if containsAny(normalized, ["pain", "fatigue", "urgency", "rough", "flare", "feel"]) {
            var fields: [String: String] = ["note": text]
            fields["pain_score"] = firstMatch(in: numericText, pattern: #"pain\s*(?:is\s*)?(\d+)"#)
            fields["fatigue_score"] = firstMatch(in: numericText, pattern: #"fatigue\s*(?:is\s*)?(\d+)"#)
            return VoiceLogDraft(type: .symptom, confidence: .medium, fields: fields, safetyFlags: flags)
        }

        return VoiceLogDraft(type: .note, confidence: .ambiguous, fields: ["note": text], safetyFlags: flags)
    }

    private static func containsAny(_ text: String, _ needles: [String]) -> Bool {
        needles.contains(where: text.contains)
    }

    private static func normalizeNumberWords(in text: String) -> String {
        let replacements = [
            "zero": "0",
            "one": "1",
            "two": "2",
            "three": "3",
            "four": "4",
            "five": "5",
            "six": "6",
            "seven": "7",
            "eight": "8",
            "nine": "9",
            "ten": "10"
        ]

        return replacements.reduce(text) { partial, pair in
            partial.replacingOccurrences(of: "\\b\(pair.key)\\b", with: pair.value, options: .regularExpression)
        }
    }

    private static func firstMedicationName(in text: String) -> String? {
        ["mesalamine", "azathioprine", "prednisone", "vitamin d"].first(where: text.contains)
    }

    private static func firstMatch(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else {
            return nil
        }

        for index in 1..<match.numberOfRanges {
            let range = match.range(at: index)
            if range.location != NSNotFound, let swiftRange = Range(range, in: text) {
                return String(text[swiftRange])
            }
        }

        return nil
    }
}

struct MedicationSchedule: Equatable {
    enum Frequency: Equatable {
        case daily
        case twiceDaily
        case weekly(weekday: Int)
    }

    var medicationName: String
    var dose: String
    var frequency: Frequency
    var times: [DateComponents]
}

struct ScheduledDose: Equatable {
    var medicationName: String
    var dose: String
    var scheduledAt: Date
}

enum MedicationScheduleCalculator {
    static func doses(for schedule: MedicationSchedule, on day: Date, calendar: Calendar = .current) -> [ScheduledDose] {
        let weekday = calendar.component(.weekday, from: day)

        if case let .weekly(targetWeekday) = schedule.frequency, targetWeekday != weekday {
            return []
        }

        let times: [DateComponents]
        switch schedule.frequency {
        case .daily, .weekly:
            times = schedule.times.prefix(1).map { $0 }
        case .twiceDaily:
            times = schedule.times.prefix(2).map { $0 }
        }

        return times.compactMap { time in
            var components = calendar.dateComponents([.year, .month, .day], from: day)
            components.hour = time.hour
            components.minute = time.minute
            return calendar.date(from: components).map {
                ScheduledDose(medicationName: schedule.medicationName, dose: schedule.dose, scheduledAt: $0)
            }
        }
    }
}

struct ReportSummaryInput: Equatable {
    var daysLogged: Int
    var bowelMovementCount: Int
    var bloodEventCount: Int
    var medicationDosesTaken: Int
    var medicationDosesScheduled: Int
    var possiblePatterns: [String]
    var notes: [String]
}

enum ReportSummaryGenerator {
    static func plainText(_ input: ReportSummaryInput) -> String {
        let adherence = input.medicationDosesScheduled == 0
            ? "No scheduled medication doses in this range."
            : "\(Int((Double(input.medicationDosesTaken) / Double(input.medicationDosesScheduled) * 100).rounded()))% medication adherence based on logged doses."

        return [
            "Inflamend Doctor Report",
            "Self-reported tracking summary. Not a diagnosis.",
            "",
            "Days logged: \(input.daysLogged)",
            "Bowel movements logged: \(input.bowelMovementCount)",
            "Blood flags: \(input.bloodEventCount)",
            adherence,
            "",
            "Possible patterns:",
            input.possiblePatterns.isEmpty ? "Keep logging to improve confidence." : input.possiblePatterns.map { "- Possible pattern: \($0)" }.joined(separator: "\n"),
            "",
            "Notes:",
            input.notes.isEmpty ? "No notes in this range." : input.notes.map { "- \($0)" }.joined(separator: "\n"),
            "",
            "Questions to ask your clinician:",
            "- Are these symptom changes expected for my condition?",
            "- Should any medication questions be reviewed by my GI team or pharmacist?"
        ].joined(separator: "\n")
    }
}

enum HealthLogValidator {
    static func isValidBristolType(_ value: Int) -> Bool { (1...7).contains(value) }
    static func isValidScale(_ value: Int) -> Bool { (0...10).contains(value) }
    static func isValidWeight(_ value: Double) -> Bool { value > 0 && value < 1000 }
    static func isValidWaterAmountMl(_ value: Int) -> Bool { value > 0 && value <= 5000 }
}
