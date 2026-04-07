import Foundation

// MARK: - Auth & Profile

enum DiagnosisType: String, Codable, CaseIterable {
    case crohns = "crohns"
    case ulcerativeColitis = "ulcerative_colitis"
    case ibdUnspecified = "ibd_unspecified"
    case other = "other"

    var label: String {
        switch self {
        case .crohns: return "Crohn's Disease"
        case .ulcerativeColitis: return "Ulcerative Colitis"
        case .ibdUnspecified: return "IBD (Unspecified)"
        case .other: return "Other"
        }
    }
}

struct UserProfile: Codable, Identifiable {
    let id: String
    var display_name: String?
    var date_of_birth: String?
    var diagnosis_type: DiagnosisType?
    var diagnosis_date: String?
    var tracks_menstrual_cycle: Bool
    let created_at: String
    let updated_at: String
}

// MARK: - Food Log

enum MealType: String, Codable, CaseIterable {
    case breakfast, lunch, dinner, snack, drink
    var label: String { rawValue.capitalized }
}

struct FoodLog: Codable, Identifiable {
    let id: String
    let user_id: String
    var logged_at: String
    var meal_type: MealType
    var description: String
    var photo_url: String?
    var calories: Int?
    var protein_g: Double?
    var carbs_g: Double?
    var fat_g: Double?
    var fiber_g: Double?
    var water_ml: Double?
    var is_trigger_food: Bool
    var is_safe_food: Bool
    var notes: String?
    let created_at: String
}

struct FoodLogInput: Encodable {
    let logged_at: String
    let meal_type: String
    let description: String
    let is_trigger_food: Bool
    let is_safe_food: Bool
    let notes: String?
}

// MARK: - Bowel Log

enum BloodAmount: String, Codable, CaseIterable {
    case none, trace, moderate, significant
    var label: String { rawValue.capitalized }
}

struct BowelLog: Codable, Identifiable {
    let id: String
    let user_id: String
    var logged_at: String
    var bristol_scale: Int
    var urgency: Int
    var blood_present: Bool
    var blood_amount: BloodAmount
    var mucus_present: Bool
    var pain_during: Int
    var notes: String?
    let created_at: String
}

struct BowelLogInput: Encodable {
    let logged_at: String
    let bristol_scale: Int
    let urgency: Int
    let blood_present: Bool
    let blood_amount: String
    let mucus_present: Bool
    let pain_during: Int
    let notes: String?
}

// MARK: - Symptom Log

enum Mood: String, Codable, CaseIterable {
    case great, good, okay, bad, terrible
    var label: String { rawValue.capitalized }
    var icon: String {
        switch self {
        case .great: return "face.smiling"
        case .good: return "face.smiling"
        case .okay: return "face.dashed"
        case .bad: return "faceid"
        case .terrible: return "xmark.circle"
        }
    }
}

struct SymptomLog: Codable, Identifiable {
    let id: String
    let user_id: String
    var logged_at: String
    var pain_level: Int
    var pain_location: [String]
    var fatigue_level: Int
    var nausea_level: Int
    var bloating_level: Int
    var stress_level: Int
    var mood: Mood?
    var is_flare: Bool
    var notes: String?
    let created_at: String
}

struct SymptomLogInput: Encodable {
    let logged_at: String
    let pain_level: Int
    let pain_location: [String]
    let fatigue_level: Int
    let nausea_level: Int
    let bloating_level: Int
    let stress_level: Int
    let mood: String?
    let is_flare: Bool
    let notes: String?
}

// MARK: - Medication

struct Medication: Codable, Identifiable {
    let id: String
    let user_id: String
    var name: String
    var dosage: String?
    var dosage_unit: String?
    var frequency: String?
    var time_of_day: [String]
    var is_active: Bool
    var start_date: String?
    var end_date: String?
    let created_at: String
}

struct MedicationLog: Codable, Identifiable {
    let id: String
    let user_id: String
    var medication_name: String
    var dosage: String?
    var dosage_unit: String?
    var scheduled_time: String?
    var taken_at: String?
    var was_taken: Bool
    var side_effects: [String]
    var notes: String?
    let created_at: String
}

struct MedicationLogInput: Encodable {
    let medication_name: String
    let dosage: String?
    let dosage_unit: String?
    let was_taken: Bool
    let side_effects: [String]
    let notes: String?
}

// MARK: - Sleep Log

struct SleepLog: Codable, Identifiable {
    let id: String
    let user_id: String
    var date: String
    var bedtime: String
    var wake_time: String
    var duration_minutes: Int?
    var quality: Int
    var night_wakings: Int
    var bathroom_wakings: Int
    var notes: String?
    let created_at: String
}

struct SleepLogInput: Encodable {
    let date: String
    let bedtime: String
    let wake_time: String
    let quality: Int
    let night_wakings: Int
    let bathroom_wakings: Int
    let notes: String?
}

// MARK: - Menstrual Log

enum FlowLevel: String, Codable, CaseIterable {
    case none, spotting, light, medium, heavy
    var label: String { rawValue.capitalized }
}

struct MenstrualLog: Codable, Identifiable {
    let id: String
    let user_id: String
    var date: String
    var cycle_day: Int?
    var flow: FlowLevel
    var symptoms: [String]
    var notes: String?
    let created_at: String
}

struct MenstrualLogInput: Encodable {
    let date: String
    let flow: String
    let symptoms: [String]
    let notes: String?
}

// MARK: - Weight Log

struct WeightLog: Codable, Identifiable {
    let id: String
    let user_id: String
    var logged_at: String
    var weight_kg: Double
    var notes: String?
    let created_at: String
}

struct WeightLogInput: Encodable {
    let logged_at: String
    let weight_kg: Double
    let notes: String?
}

// MARK: - Chat

enum ChatRole: String, Codable {
    case user, assistant
}

struct ChatMessage: Codable, Identifiable {
    let id: String
    let user_id: String
    let role: ChatRole
    let content: String
    let created_at: String
}

// MARK: - Risk Indicator

enum RiskLevel: String {
    case low, medium, high
}

struct RiskIndicator {
    let score: Int
    let level: RiskLevel
    let factors: [String]
}

// MARK: - Bristol Scale

struct BristolType {
    let scale: Int
    let name: String
    let description: String
    let systemIcon: String
}

let bristolTypes: [BristolType] = [
    BristolType(scale: 1, name: "Separate hard lumps",  description: "Hard to pass, like nuts",             systemIcon: "circle.fill"),
    BristolType(scale: 2, name: "Lumpy sausage",        description: "Sausage-shaped but lumpy",            systemIcon: "oval.fill"),
    BristolType(scale: 3, name: "Cracked sausage",      description: "Sausage with surface cracks",         systemIcon: "oval"),
    BristolType(scale: 4, name: "Smooth sausage",       description: "Smooth, soft — ideal",                systemIcon: "checkmark.circle.fill"),
    BristolType(scale: 5, name: "Soft blobs",           description: "Soft blobs with clear edges",         systemIcon: "drop.fill"),
    BristolType(scale: 6, name: "Fluffy pieces",        description: "Fluffy with ragged edges, mushy",     systemIcon: "cloud.fill"),
    BristolType(scale: 7, name: "Watery",               description: "Entirely liquid, no solid pieces",    systemIcon: "drop"),
]

// MARK: - Constants

let painLocations: [(id: String, label: String)] = [
    ("abdomen_upper", "Upper Abdomen"),
    ("abdomen_lower", "Lower Abdomen"),
    ("rectum",        "Rectum"),
    ("joints",        "Joints"),
    ("back",          "Back"),
    ("other",         "Other"),
]

let menstrualSymptoms: [(id: String, label: String)] = [
    ("cramps",             "Cramps"),
    ("headache",           "Headache"),
    ("mood_changes",       "Mood Changes"),
    ("bloating",           "Bloating"),
    ("fatigue",            "Fatigue"),
    ("back_pain",          "Back Pain"),
    ("breast_tenderness",  "Breast Tenderness"),
]

let sideEffectOptions: [(id: String, label: String)] = [
    ("nausea",         "Nausea"),
    ("headache",       "Headache"),
    ("fatigue",        "Fatigue"),
    ("stomach_pain",   "Stomach Pain"),
    ("dizziness",      "Dizziness"),
    ("rash",           "Rash"),
    ("insomnia",       "Insomnia"),
    ("appetite_loss",  "Appetite Loss"),
]

let starterQuestions = [
    "What foods should I avoid during a flare?",
    "Explain what my medication does",
    "I'm feeling discouraged today",
    "What is the Bristol Stool Scale?",
    "How can I track my symptoms better?",
    "When should I contact my doctor?",
]
