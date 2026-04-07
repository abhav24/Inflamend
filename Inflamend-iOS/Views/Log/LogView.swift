import SwiftUI

enum LogTab: String, CaseIterable {
    case food, bowel, symptoms, meds, sleep, cycle, weight
    var label: String {
        switch self {
        case .food: return "Food"
        case .bowel: return "Bowel"
        case .symptoms: return "Symptoms"
        case .meds: return "Meds"
        case .sleep: return "Sleep"
        case .cycle: return "Cycle"
        case .weight: return "Weight"
        }
    }
    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .bowel: return "arrow.triangle.2.circlepath"
        case .symptoms: return "stethoscope"
        case .meds: return "pills.fill"
        case .sleep: return "moon.zzz.fill"
        case .cycle: return "calendar.circle.fill"
        case .weight: return "scalemass.fill"
        }
    }
}

struct LogView: View {
    var initialTab: LogTab = .food
    @State private var selectedTab: LogTab = .food
    @Environment(\.dismiss) private var dismiss

    init(initialTab: LogTab = .food) {
        self.initialTab = initialTab
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(LogTab.allCases, id: \.self) { tab in
                            FilterChip(label: tab.label, selected: selectedTab == tab) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedTab = tab
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .background(Color(.systemBackground))
                .overlay(alignment: .bottom) {
                    Divider()
                }

                // Tab Content
                ScrollView {
                    VStack(spacing: 20) {
                        switch selectedTab {
                        case .food:     FoodLogForm()
                        case .bowel:    BowelLogForm()
                        case .symptoms: SymptomLogForm()
                        case .meds:     MedLogForm()
                        case .sleep:    SleepLogForm()
                        case .cycle:    CycleLogForm()
                        case .weight:   WeightLogForm()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .padding(.bottom, 40)
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Food Log Form

struct FoodLogForm: View {
    @State private var mealType: MealType = .breakfast
    @State private var description = ""
    @State private var notes = ""
    @State private var isTrigger = false
    @State private var isSafe = false
    @State private var loading = false
    @State private var success = false

    var body: some View {
        VStack(spacing: 16) {
            if success { SuccessBanner() }

            VStack(alignment: .leading, spacing: 12) {
                FieldLabel(text: "Meal Type")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(MealType.allCases, id: \.self) { type in
                            FilterChip(label: type.label, selected: mealType == type) {
                                mealType = type
                            }
                        }
                    }
                }
            }
            .padding(16)
            .cardStyle()

            VStack(alignment: .leading, spacing: 12) {
                FieldLabel(text: "What did you eat?")
                TextField("e.g. Grilled chicken, rice, salad", text: $description, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                FieldLabel(text: "Notes (optional)")
                TextField("Any reactions, portion size, etc.", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
                    .padding(12)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .padding(16)
            .cardStyle()

            VStack(spacing: 0) {
                Toggle(isOn: $isTrigger) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Trigger Food")
                            .font(.subheadline).fontWeight(.medium)
                        Text("Mark this as a known trigger")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .tint(.brandWarning)
                .padding(16)

                Divider().padding(.leading, 16)

                Toggle(isOn: $isSafe) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Safe Food")
                            .font(.subheadline).fontWeight(.medium)
                        Text("This food is well tolerated")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .tint(.brandSuccess)
                .padding(16)
            }
            .cardStyle()

            PrimaryButton("Save Food Log", icon: "checkmark", isLoading: loading) {
                Task { await save() }
            }
        }
    }

    private func save() async {
        guard !description.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        guard let uid = SupabaseClient.shared.userId else { return }
        loading = true
        let input = FoodLogInput(
            logged_at: ISO8601DateFormatter().string(from: Date()),
            meal_type: mealType.rawValue,
            description: description.trimmingCharacters(in: .whitespaces),
            is_trigger_food: isTrigger,
            is_safe_food: isSafe,
            notes: notes.isEmpty ? nil : notes
        )
        struct WithUser: Encodable {
            let user_id: String
            let logged_at: String
            let meal_type: String
            let description: String
            let is_trigger_food: Bool
            let is_safe_food: Bool
            let notes: String?
        }
        let payload = WithUser(user_id: uid, logged_at: input.logged_at, meal_type: input.meal_type,
                               description: input.description, is_trigger_food: input.is_trigger_food,
                               is_safe_food: input.is_safe_food, notes: input.notes)
        do {
            try await SupabaseClient.shared.insert("food_logs", data: payload)
            description = ""; notes = ""; isTrigger = false; isSafe = false
            success = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { success = false }
        } catch {}
        loading = false
    }
}

// MARK: - Bowel Log Form

struct BowelLogForm: View {
    @State private var bristolScale = 4
    @State private var urgency = 1.0
    @State private var bloodPresent = false
    @State private var bloodAmount: BloodAmount = .none
    @State private var mucusPresent = false
    @State private var painDuring = 0.0
    @State private var notes = ""
    @State private var loading = false
    @State private var success = false

    var body: some View {
        VStack(spacing: 16) {
            if success { SuccessBanner() }

            // Bristol Scale
            VStack(alignment: .leading, spacing: 12) {
                FieldLabel(text: "Bristol Stool Scale")
                ForEach(bristolTypes, id: \.scale) { type in
                    Button {
                        withAnimation(.spring(response: 0.3)) { bristolScale = type.scale }
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(bristolScale == type.scale ? AppGradient.brand : AnyShapeStyle(Color(.tertiarySystemBackground)))
                                    .frame(width: 36, height: 36)
                                Text("\(type.scale)")
                                    .font(.system(.subheadline, design: .rounded)).fontWeight(.bold)
                                    .foregroundStyle(bristolScale == type.scale ? .white : .primary)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(type.name).font(.subheadline).fontWeight(.medium)
                                    .foregroundStyle(.primary)
                                Text(type.description).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if type.scale == 4 {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(.brandSuccess)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    if type.scale < 7 { Divider() }
                }
            }
            .padding(16)
            .cardStyle()

            // Urgency & Pain
            VStack(spacing: 16) {
                SliderRow(label: "Urgency", value: $urgency, range: 1...5, color: .brandWarning)
                Divider()
                SliderRow(label: "Pain During", value: $painDuring, range: 0...10, color: .brandDanger)
            }
            .padding(16)
            .cardStyle()

            // Blood & Mucus
            VStack(spacing: 0) {
                Toggle(isOn: $bloodPresent) {
                    Label("Blood Present", systemImage: "drop.fill")
                        .font(.subheadline).fontWeight(.medium)
                }
                .tint(.brandDanger)
                .padding(16)

                if bloodPresent {
                    Divider().padding(.leading, 16)
                    VStack(alignment: .leading, spacing: 8) {
                        FieldLabel(text: "Blood Amount")
                        Picker("", selection: $bloodAmount) {
                            ForEach(BloodAmount.allCases, id: \.self) { a in
                                Text(a.label).tag(a)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }

                Divider().padding(.leading, 16)

                Toggle(isOn: $mucusPresent) {
                    Label("Mucus Present", systemImage: "humidity.fill")
                        .font(.subheadline).fontWeight(.medium)
                }
                .tint(.brandWarning)
                .padding(16)
            }
            .cardStyle()

            VStack(alignment: .leading, spacing: 8) {
                FieldLabel(text: "Notes (optional)")
                TextField("Any additional details", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
                    .padding(12)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .padding(16)
            .cardStyle()

            PrimaryButton("Save Bowel Log", icon: "checkmark", isLoading: loading) {
                Task { await save() }
            }
        }
    }

    private func save() async {
        guard let uid = SupabaseClient.shared.userId else { return }
        loading = true
        struct Payload: Encodable {
            let user_id: String; let logged_at: String; let bristol_scale: Int
            let urgency: Int; let blood_present: Bool; let blood_amount: String
            let mucus_present: Bool; let pain_during: Int; let notes: String?
        }
        let p = Payload(user_id: uid, logged_at: ISO8601DateFormatter().string(from: Date()),
                        bristol_scale: bristolScale, urgency: Int(urgency),
                        blood_present: bloodPresent, blood_amount: bloodAmount.rawValue,
                        mucus_present: mucusPresent, pain_during: Int(painDuring),
                        notes: notes.isEmpty ? nil : notes)
        do {
            try await SupabaseClient.shared.insert("bowel_logs", data: p)
            bristolScale = 4; urgency = 1; bloodPresent = false; mucusPresent = false; painDuring = 0; notes = ""
            success = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { success = false }
        } catch {}
        loading = false
    }
}

// MARK: - Symptom Log Form

struct SymptomLogForm: View {
    @State private var painLevel = 0.0
    @State private var fatigueLevel = 0.0
    @State private var nauseaLevel = 0.0
    @State private var bloatingLevel = 0.0
    @State private var stressLevel = 0.0
    @State private var selectedLocations: Set<String> = []
    @State private var mood: Mood? = nil
    @State private var isFlare = false
    @State private var notes = ""
    @State private var loading = false
    @State private var success = false

    var body: some View {
        VStack(spacing: 16) {
            if success { SuccessBanner() }

            VStack(spacing: 16) {
                SliderRow(label: "Pain Level", value: $painLevel, range: 0...10, color: .brandDanger)
                Divider()
                SliderRow(label: "Fatigue", value: $fatigueLevel, range: 0...10, color: .brandWarning)
                Divider()
                SliderRow(label: "Nausea", value: $nauseaLevel, range: 0...10, color: .brandSecondary)
                Divider()
                SliderRow(label: "Bloating", value: $bloatingLevel, range: 0...10, color: Color(red: 0.2, green: 0.6, blue: 0.9))
                Divider()
                SliderRow(label: "Stress", value: $stressLevel, range: 0...10, color: .brandWarning)
            }
            .padding(16)
            .cardStyle()

            // Pain Locations
            VStack(alignment: .leading, spacing: 10) {
                FieldLabel(text: "Pain Location")
                FlowLayout(spacing: 8) {
                    ForEach(painLocations, id: \.id) { loc in
                        FilterChip(label: loc.label, selected: selectedLocations.contains(loc.id)) {
                            if selectedLocations.contains(loc.id) {
                                selectedLocations.remove(loc.id)
                            } else {
                                selectedLocations.insert(loc.id)
                            }
                        }
                    }
                }
            }
            .padding(16)
            .cardStyle()

            // Mood
            VStack(alignment: .leading, spacing: 10) {
                FieldLabel(text: "Mood")
                HStack(spacing: 8) {
                    ForEach(Mood.allCases, id: \.self) { m in
                        Button {
                            mood = (mood == m) ? nil : m
                        } label: {
                            Text(m.label)
                                .font(.caption).fontWeight(.semibold)
                                .padding(.horizontal, 12).padding(.vertical, 7)
                                .foregroundStyle(mood == m ? .white : .primary)
                                .background(mood == m ? AppGradient.brand : AnyShapeStyle(Color(.tertiarySystemBackground)))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
            .cardStyle()

            VStack(spacing: 0) {
                Toggle(isOn: $isFlare) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mark as Flare Day")
                            .font(.subheadline).fontWeight(.medium)
                        Text("Indicates an active flare episode")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .tint(.brandDanger)
                .padding(16)
            }
            .cardStyle()

            VStack(alignment: .leading, spacing: 8) {
                FieldLabel(text: "Notes (optional)")
                TextField("Describe your symptoms further", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
                    .padding(12)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .padding(16)
            .cardStyle()

            PrimaryButton("Save Symptom Log", icon: "checkmark", isLoading: loading) {
                Task { await save() }
            }
        }
    }

    private func save() async {
        guard let uid = SupabaseClient.shared.userId else { return }
        loading = true
        struct Payload: Encodable {
            let user_id: String; let logged_at: String; let pain_level: Int
            let pain_location: [String]; let fatigue_level: Int; let nausea_level: Int
            let bloating_level: Int; let stress_level: Int; let mood: String?
            let is_flare: Bool; let notes: String?
        }
        let p = Payload(user_id: uid, logged_at: ISO8601DateFormatter().string(from: Date()),
                        pain_level: Int(painLevel), pain_location: Array(selectedLocations),
                        fatigue_level: Int(fatigueLevel), nausea_level: Int(nauseaLevel),
                        bloating_level: Int(bloatingLevel), stress_level: Int(stressLevel),
                        mood: mood?.rawValue, is_flare: isFlare, notes: notes.isEmpty ? nil : notes)
        do {
            try await SupabaseClient.shared.insert("symptom_logs", data: p)
            painLevel = 0; fatigueLevel = 0; nauseaLevel = 0; bloatingLevel = 0; stressLevel = 0
            selectedLocations = []; mood = nil; isFlare = false; notes = ""
            success = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { success = false }
        } catch {}
        loading = false
    }
}

// MARK: - Medication Log Form

struct MedLogForm: View {
    @State private var medicationName = ""
    @State private var dosage = ""
    @State private var wasTaken = true
    @State private var selectedSideEffects: Set<String> = []
    @State private var notes = ""
    @State private var loading = false
    @State private var success = false

    var body: some View {
        VStack(spacing: 16) {
            if success { SuccessBanner() }

            VStack(alignment: .leading, spacing: 12) {
                FieldLabel(text: "Medication Name")
                TextField("e.g. Mesalamine, Humira", text: $medicationName)
                    .padding(12)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                FieldLabel(text: "Dosage (optional)")
                TextField("e.g. 400mg", text: $dosage)
                    .padding(12)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .padding(16)
            .cardStyle()

            Toggle(isOn: $wasTaken) {
                Label(wasTaken ? "Medication Taken" : "Medication Missed", systemImage: wasTaken ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.subheadline).fontWeight(.medium)
                    .foregroundStyle(wasTaken ? .brandSuccess : .brandDanger)
            }
            .tint(.brandSuccess)
            .padding(16)
            .cardStyle()

            VStack(alignment: .leading, spacing: 10) {
                FieldLabel(text: "Side Effects (optional)")
                FlowLayout(spacing: 8) {
                    ForEach(sideEffectOptions, id: \.id) { opt in
                        FilterChip(label: opt.label, selected: selectedSideEffects.contains(opt.id)) {
                            if selectedSideEffects.contains(opt.id) {
                                selectedSideEffects.remove(opt.id)
                            } else {
                                selectedSideEffects.insert(opt.id)
                            }
                        }
                    }
                }
            }
            .padding(16)
            .cardStyle()

            VStack(alignment: .leading, spacing: 8) {
                FieldLabel(text: "Notes (optional)")
                TextField("Any additional notes", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
                    .padding(12)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .padding(16)
            .cardStyle()

            PrimaryButton("Save Medication Log", icon: "checkmark", isLoading: loading) {
                Task { await save() }
            }
        }
    }

    private func save() async {
        guard !medicationName.trimmingCharacters(in: .whitespaces).isEmpty,
              let uid = SupabaseClient.shared.userId else { return }
        loading = true
        struct Payload: Encodable {
            let user_id: String; let medication_name: String; let dosage: String?
            let was_taken: Bool; let side_effects: [String]; let notes: String?
        }
        let p = Payload(user_id: uid, medication_name: medicationName.trimmingCharacters(in: .whitespaces),
                        dosage: dosage.isEmpty ? nil : dosage,
                        was_taken: wasTaken, side_effects: Array(selectedSideEffects),
                        notes: notes.isEmpty ? nil : notes)
        do {
            try await SupabaseClient.shared.insert("medication_logs", data: p)
            medicationName = ""; dosage = ""; wasTaken = true; selectedSideEffects = []; notes = ""
            success = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { success = false }
        } catch {}
        loading = false
    }
}

// MARK: - Sleep Log Form

struct SleepLogForm: View {
    @State private var bedtime = Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var wakeTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var quality = 3.0
    @State private var nightWakings = 0.0
    @State private var bathroomWakings = 0.0
    @State private var notes = ""
    @State private var loading = false
    @State private var success = false

    var body: some View {
        VStack(spacing: 16) {
            if success { SuccessBanner() }

            VStack(spacing: 0) {
                HStack {
                    Label("Bedtime", systemImage: "moon.fill")
                        .font(.subheadline).fontWeight(.medium)
                    Spacer()
                    DatePicker("", selection: $bedtime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
                .padding(16)
                Divider().padding(.leading, 16)
                HStack {
                    Label("Wake Time", systemImage: "sun.max.fill")
                        .font(.subheadline).fontWeight(.medium)
                    Spacer()
                    DatePicker("", selection: $wakeTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
                .padding(16)
            }
            .cardStyle()

            VStack(spacing: 16) {
                SliderRow(label: "Sleep Quality", value: $quality, range: 1...5, color: .brandPrimary)
                Divider()
                SliderRow(label: "Night Wakings", value: $nightWakings, range: 0...10, color: .brandWarning)
                Divider()
                SliderRow(label: "Bathroom Trips", value: $bathroomWakings, range: 0...10, color: .brandSecondary)
            }
            .padding(16)
            .cardStyle()

            VStack(alignment: .leading, spacing: 8) {
                FieldLabel(text: "Notes (optional)")
                TextField("How did you sleep?", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
                    .padding(12)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .padding(16)
            .cardStyle()

            PrimaryButton("Save Sleep Log", icon: "checkmark", isLoading: loading) {
                Task { await save() }
            }
        }
    }

    private func save() async {
        guard let uid = SupabaseClient.shared.userId else { return }
        loading = true
        let fmt = ISO8601DateFormatter()
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        struct Payload: Encodable {
            let user_id: String; let date: String; let bedtime: String; let wake_time: String
            let quality: Int; let night_wakings: Int; let bathroom_wakings: Int; let notes: String?
        }
        let p = Payload(user_id: uid, date: df.string(from: Date()),
                        bedtime: fmt.string(from: bedtime), wake_time: fmt.string(from: wakeTime),
                        quality: Int(quality), night_wakings: Int(nightWakings),
                        bathroom_wakings: Int(bathroomWakings), notes: notes.isEmpty ? nil : notes)
        do {
            try await SupabaseClient.shared.insert("sleep_logs", data: p)
            quality = 3; nightWakings = 0; bathroomWakings = 0; notes = ""
            success = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { success = false }
        } catch {}
        loading = false
    }
}

// MARK: - Cycle Log Form

struct CycleLogForm: View {
    @State private var flow: FlowLevel = .light
    @State private var selectedSymptoms: Set<String> = []
    @State private var notes = ""
    @State private var loading = false
    @State private var success = false

    var body: some View {
        VStack(spacing: 16) {
            if success { SuccessBanner() }

            VStack(alignment: .leading, spacing: 10) {
                FieldLabel(text: "Flow Level")
                Picker("", selection: $flow) {
                    ForEach(FlowLevel.allCases, id: \.self) { f in
                        Text(f.label).tag(f)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(16)
            .cardStyle()

            VStack(alignment: .leading, spacing: 10) {
                FieldLabel(text: "Symptoms")
                FlowLayout(spacing: 8) {
                    ForEach(menstrualSymptoms, id: \.id) { sym in
                        FilterChip(label: sym.label, selected: selectedSymptoms.contains(sym.id)) {
                            if selectedSymptoms.contains(sym.id) { selectedSymptoms.remove(sym.id) }
                            else { selectedSymptoms.insert(sym.id) }
                        }
                    }
                }
            }
            .padding(16)
            .cardStyle()

            VStack(alignment: .leading, spacing: 8) {
                FieldLabel(text: "Notes (optional)")
                TextField("Additional notes", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
                    .padding(12)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .padding(16)
            .cardStyle()

            PrimaryButton("Save Cycle Log", icon: "checkmark", isLoading: loading) {
                Task { await save() }
            }
        }
    }

    private func save() async {
        guard let uid = SupabaseClient.shared.userId else { return }
        loading = true
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        struct Payload: Encodable {
            let user_id: String; let date: String; let flow: String
            let symptoms: [String]; let notes: String?
        }
        let p = Payload(user_id: uid, date: df.string(from: Date()), flow: flow.rawValue,
                        symptoms: Array(selectedSymptoms), notes: notes.isEmpty ? nil : notes)
        do {
            try await SupabaseClient.shared.insert("menstrual_logs", data: p)
            flow = .light; selectedSymptoms = []; notes = ""
            success = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { success = false }
        } catch {}
        loading = false
    }
}

// MARK: - Weight Log Form

struct WeightLogForm: View {
    @State private var weightKg = ""
    @State private var notes = ""
    @State private var loading = false
    @State private var success = false

    var body: some View {
        VStack(spacing: 16) {
            if success { SuccessBanner() }

            VStack(alignment: .leading, spacing: 12) {
                FieldLabel(text: "Weight (kg)")
                HStack(spacing: 12) {
                    Image(systemName: "scalemass.fill")
                        .foregroundStyle(.brandPrimary)
                    TextField("e.g. 68.5", text: $weightKg)
                        .keyboardType(.decimalPad)
                    Text("kg")
                        .foregroundStyle(.secondary)
                        .fontWeight(.medium)
                }
                .padding(14)
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                FieldLabel(text: "Notes (optional)")
                TextField("Morning weight, after meal, etc.", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
                    .padding(12)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .padding(16)
            .cardStyle()

            PrimaryButton("Save Weight", icon: "checkmark", isLoading: loading) {
                Task { await save() }
            }
        }
    }

    private func save() async {
        guard let kg = Double(weightKg), let uid = SupabaseClient.shared.userId else { return }
        loading = true
        struct Payload: Encodable {
            let user_id: String; let logged_at: String; let weight_kg: Double; let notes: String?
        }
        let p = Payload(user_id: uid, logged_at: ISO8601DateFormatter().string(from: Date()),
                        weight_kg: kg, notes: notes.isEmpty ? nil : notes)
        do {
            try await SupabaseClient.shared.insert("weight_logs", data: p)
            weightKg = ""; notes = ""
            success = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { success = false }
        } catch {}
        loading = false
    }
}

// MARK: - Shared UI

struct SuccessBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.brandSuccess)
            Text("Logged successfully!")
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(.brandSuccess)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(Color.brandSuccess.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { row in row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0 }
            .reduce(0) { $0 + $1 + spacing } - spacing
        return CGSize(width: proposal.width ?? 0, height: max(height, 0))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: ProposedViewSize(width: bounds.width, height: nil), subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            for view in row {
                let size = view.sizeThatFits(.unspecified)
                view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubviews.Element]] {
        var rows: [[LayoutSubviews.Element]] = [[]]
        var rowWidth: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity
        for view in subviews {
            let w = view.sizeThatFits(.unspecified).width
            if rowWidth + w + (rows.last!.isEmpty ? 0 : spacing) > maxWidth && !rows.last!.isEmpty {
                rows.append([view])
                rowWidth = w
            } else {
                rows[rows.count - 1].append(view)
                rowWidth += (rows.last!.count > 1 ? spacing : 0) + w
            }
        }
        return rows
    }
}
