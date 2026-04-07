import SwiftUI

struct HomeView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var risk: RiskIndicator?
    @State private var foodCount = 0
    @State private var bowelCount = 0
    @State private var symptomLogged = false
    @State private var medsTaken = 0
    @State private var medsTotal = 0
    @State private var timeline: [TimelineEntry] = []
    @State private var loading = true
    @State private var selectedLogTab: LogTab = .food
    @State private var showLog = false

    private let db = AppDatabase.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    headerSection
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 24)

                    if loading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else {
                        VStack(spacing: 24) {
                            if let risk {
                                riskCard(risk)
                                    .padding(.horizontal, 20)
                            }

                            statGrid
                                .padding(.horizontal, 20)

                            quickLogSection

                            if !timeline.isEmpty {
                                timelineSection
                                    .padding(.horizontal, 20)
                            } else {
                                emptyState
                                    .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Inflamend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { Task { await loadData() } } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .refreshable { await loadData() }
        }
        .task { await loadData() }
        .sheet(isPresented: $showLog) {
            LogView(initialTab: selectedLogTab)
                .onDisappear { Task { await loadData() } }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDate())
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("\(greeting()), \(auth.profile?.display_name?.components(separatedBy: " ").first ?? "there")")
                    .font(.title2).fontWeight(.bold)
            }
            Spacer()
            if let name = auth.profile?.display_name {
                UserAvatarView(name: name, size: 44)
            }
        }
    }

    private func riskCard(_ risk: RiskIndicator) -> some View {
        VStack(spacing: 12) {
            HStack {
                Label("Flare Risk", systemImage: "waveform.path.ecg")
                    .font(.subheadline).fontWeight(.semibold)
                Spacer()
                Text("\(risk.level.rawValue.uppercased()) · \(risk.score)%")
                    .font(.subheadline).fontWeight(.bold)
                    .foregroundStyle(riskColor(risk.level))
            }
            BrandProgressBar(value: Double(risk.score) / 100.0, color: riskColor(risk.level))
            if !risk.factors.isEmpty {
                Text(risk.factors.prefix(2).joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(riskColor(risk.level).opacity(0.4), lineWidth: 2)
        )
    }

    private var statGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(icon: "fork.knife", label: "Meals", value: "\(foodCount)", gradient: AppGradient.ocean)
            StatCard(icon: "arrow.triangle.2.circlepath", label: "BMs", value: "\(bowelCount)", gradient: AppGradient.mint)
            StatCard(icon: "stethoscope", label: "Symptoms",
                     value: symptomLogged ? "Logged" : "None",
                     gradient: symptomLogged ? AppGradient.brand : nil)
            StatCard(icon: "pills.fill", label: "Meds",
                     value: medsTotal > 0 ? "\(medsTaken)/\(medsTotal)" : "None",
                     gradient: medsTotal > 0 ? AppGradient.success : nil)
        }
    }

    private var quickLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Quick Log")
                .padding(.horizontal, 0)

            HStack(spacing: 10) {
                QuickLogButton(icon: "fork.knife", label: "Food", gradient: AppGradient.ocean) {
                    selectedLogTab = .food; showLog = true
                }
                QuickLogButton(icon: "arrow.triangle.2.circlepath", label: "Bowel", gradient: AppGradient.mint) {
                    selectedLogTab = .bowel; showLog = true
                }
                QuickLogButton(icon: "stethoscope", label: "Symptoms", gradient: AppGradient.brand) {
                    selectedLogTab = .symptoms; showLog = true
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private var timelineSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Today's Timeline", count: timeline.count)
                .padding(.horizontal, 0)

            ForEach(timeline) { entry in
                TimelineRow(entry: entry)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clipboard")
                .font(.system(size: 44))
                .foregroundStyle(.brandPrimary.opacity(0.4))
            Text("Nothing logged today yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Tap Quick Log above to get started.")
                .font(.subheadline)
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Data Loading

    private func loadData() async {
        guard let uid = db.userId else { return }
        loading = true
        let today = ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: Date()))
        let tomorrow = ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!)

        async let foodRes: [FoodLog] = (try? db.select("food_logs", filter: "user_id=eq.\(uid)&logged_at=gte.\(today)&logged_at=lt.\(tomorrow)")) ?? []
        async let bowelRes: [BowelLog] = (try? db.select("bowel_logs", filter: "user_id=eq.\(uid)&logged_at=gte.\(today)&logged_at=lt.\(tomorrow)")) ?? []
        async let symptomRes: [SymptomLog] = (try? db.select("symptom_logs", filter: "user_id=eq.\(uid)&logged_at=gte.\(today)&logged_at=lt.\(tomorrow)")) ?? []
        async let medRes: [MedicationLog] = (try? db.select("medication_logs", filter: "user_id=eq.\(uid)&created_at=gte.\(today)&created_at=lt.\(tomorrow)")) ?? []

        let (foods, bowels, symptoms, meds) = await (foodRes, bowelRes, symptomRes, medRes)

        foodCount = foods.count
        bowelCount = bowels.count
        symptomLogged = !symptoms.isEmpty
        medsTaken = meds.filter { $0.was_taken }.count
        medsTotal = meds.count

        var entries: [TimelineEntry] = []
        entries += foods.map { TimelineEntry(id: $0.id, type: .food, date: parseDate($0.logged_at)) }
        entries += bowels.map { TimelineEntry(id: $0.id, type: .bowel, date: parseDate($0.logged_at)) }
        entries += symptoms.map { TimelineEntry(id: $0.id, type: .symptom, date: parseDate($0.logged_at)) }
        entries += meds.map { TimelineEntry(id: $0.id, type: .medication, date: parseDate($0.created_at), wasTaken: $0.was_taken) }
        timeline = entries.sorted { $0.date > $1.date }

        risk = await calculateRisk(uid: uid)
        loading = false
    }

    private func calculateRisk(uid: String) async -> RiskIndicator {
        let sevenDaysAgo = ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .day, value: -7, to: Date())!)

        async let bowelRes: [BowelLog] = (try? db.select("bowel_logs", filter: "user_id=eq.\(uid)&logged_at=gte.\(sevenDaysAgo)")) ?? []
        async let symptomRes: [SymptomLog] = (try? db.select("symptom_logs", filter: "user_id=eq.\(uid)&logged_at=gte.\(sevenDaysAgo)")) ?? []
        async let medRes: [MedicationLog] = (try? db.select("medication_logs", filter: "user_id=eq.\(uid)&created_at=gte.\(sevenDaysAgo)")) ?? []
        async let foodRes: [FoodLog] = (try? db.select("food_logs", filter: "user_id=eq.\(uid)&logged_at=gte.\(sevenDaysAgo)")) ?? []

        let (bowels, symptoms, meds, foods) = await (bowelRes, symptomRes, medRes, foodRes)

        var score = 0
        var factors: [String] = []

        if !bowels.isEmpty {
            let abnormal = bowels.filter { $0.bristol_scale < 3 || $0.bristol_scale > 5 }.count
            let pct = Double(abnormal) / Double(bowels.count)
            if pct > 0.5 { score += 20; factors.append("Irregular bowel movements") }
            else if pct > 0.3 { score += 10; factors.append("Some irregular movements") }
            if bowels.contains(where: { $0.blood_present }) { score += 10; factors.append("Blood in stool") }
        }

        if !symptoms.isEmpty {
            let avgPain = Double(symptoms.reduce(0) { $0 + $1.pain_level }) / Double(symptoms.count)
            let inFlare = symptoms.contains { $0.is_flare }
            if avgPain >= 6 { score += 15; factors.append("High pain levels") }
            else if avgPain >= 4 { score += 8; factors.append("Moderate pain") }
            if inFlare { score += 15; factors.append("Currently in a flare") }
        }

        if !meds.isEmpty {
            let missed = meds.filter { !$0.was_taken }.count
            if Double(missed) / Double(meds.count) > 0.3 { score += 10; factors.append("Missed medications") }
        }

        if !foods.isEmpty {
            let triggers = foods.filter { $0.is_trigger_food }.count
            if triggers >= 3 { score += 10; factors.append("Multiple trigger foods") }
            else if triggers >= 1 { score += 5; factors.append("Trigger foods consumed") }
        }

        let capped = min(score, 100)
        let level: RiskLevel = capped >= 60 ? .high : capped >= 30 ? .medium : .low
        return RiskIndicator(score: capped, level: level, factors: factors)
    }

    // MARK: - Helpers

    private func greeting() -> String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Good morning" }
        if h < 18 { return "Good afternoon" }
        return "Good evening"
    }

    private func formattedDate() -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: Date())
    }

    private func parseDate(_ str: String) -> Date {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.date(from: str) ?? ISO8601DateFormatter().date(from: str) ?? Date()
    }

    private func riskColor(_ level: RiskLevel) -> Color {
        switch level {
        case .high: return .brandDanger
        case .medium: return .brandWarning
        case .low: return .brandSuccess
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    var gradient: LinearGradient? = nil

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(gradient.map { AnyShapeStyle($0) } ?? AnyShapeStyle(Color.brandPrimary.opacity(0.1)))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(gradient == nil ? .brandPrimary : .white)
            }
            Text(value)
                .font(.title3).fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .cardStyle()
    }
}

struct QuickLogButton: View {
    let icon: String
    let label: String
    let gradient: LinearGradient
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle().fill(gradient).frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Text(label)
                    .font(.caption).fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}

struct TimelineEntry: Identifiable {
    enum EntryType { case food, bowel, symptom, medication }
    let id: String
    let type: EntryType
    let date: Date
    var wasTaken: Bool? = nil

    var icon: String {
        switch type {
        case .food: return "fork.knife"
        case .bowel: return "arrow.triangle.2.circlepath"
        case .symptom: return "stethoscope"
        case .medication: return "pills.fill"
        }
    }

    var label: String {
        switch type {
        case .food: return "Meal logged"
        case .bowel: return "Bowel movement"
        case .symptom: return "Symptoms logged"
        case .medication: return (wasTaken == true) ? "Medication taken" : "Medication missed"
        }
    }

    var iconColor: Color {
        switch type {
        case .food: return .brandPrimary
        case .bowel: return .brandSuccess
        case .symptom: return .brandWarning
        case .medication: return (wasTaken == true) ? .brandSuccess : .brandDanger
        }
    }
}

struct TimelineRow: View {
    let entry: TimelineEntry

    var body: some View {
        HStack(spacing: 14) {
            IconBadge(systemName: entry.icon, color: entry.iconColor, size: 40)
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.label)
                    .font(.subheadline).fontWeight(.semibold)
                Text(formatTime(entry.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .cardStyle()
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }
}
