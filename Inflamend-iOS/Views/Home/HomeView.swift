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
    @State private var animateCards = false
    @State private var selectedLogTab: LogTab = .food
    @State private var showLog = false

    private let db = AppDatabase.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if loading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                    } else {
                        VStack(spacing: 24) {
                            heroCard
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                                .opacity(animateCards ? 1 : 0)
                                .offset(y: animateCards ? 0 : 16)

                            statsStrip
                                .opacity(animateCards ? 1 : 0)
                                .offset(y: animateCards ? 0 : 16)

                            quickLogSection
                                .opacity(animateCards ? 1 : 0)
                                .offset(y: animateCards ? 0 : 16)

                            if !timeline.isEmpty {
                                timelineSection
                                    .opacity(animateCards ? 1 : 0)
                                    .offset(y: animateCards ? 0 : 16)
                            } else {
                                emptyState
                                    .opacity(animateCards ? 1 : 0)
                                    .offset(y: animateCards ? 0 : 16)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 80) }
            .overlay(alignment: .bottomTrailing) { fab }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(Date().greeting)
                            .font(.caption).foregroundStyle(.secondary)
                        Text(auth.profile?.display_name?.components(separatedBy: " ").first ?? "there")
                            .font(.headline).fontWeight(.bold)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if let name = auth.profile?.display_name {
                        UserAvatarView(name: name, size: 34)
                    }
                }
            }
        }
        .task { await loadData() }
        .refreshable { await loadData() }
        .sheet(isPresented: $showLog) {
            LogView(initialTab: selectedLogTab)
                .onDisappear { Task { await loadData() } }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.05)) {
                animateCards = true
            }
        }
    }

    // MARK: - Hero Card (§3.1)

    private var heroCard: some View {
        ZStack(alignment: .topLeading) {
            AppGradient.brand
            Circle()
                .fill(.white.opacity(0.06))
                .frame(width: 200)
                .offset(x: 160, y: -60)

            VStack(alignment: .leading, spacing: 0) {
                Text("Flare Risk Score")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.bottom, 6)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(risk?.score ?? 0)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("%")
                        .font(.title2).fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.bottom, 8)

                if let risk, !risk.factors.isEmpty {
                    Text(risk.factors.prefix(2).joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                        .padding(.bottom, 16)
                } else {
                    Spacer().frame(height: 20)
                }

                Divider().overlay(.white.opacity(0.2)).padding(.bottom, 16)

                HStack(spacing: 0) {
                    miniStat(label: "Meals Today",   value: "\(foodCount)")
                    Spacer()
                    miniStat(label: "Bowel Today",   value: "\(bowelCount)",    alignment: .center)
                    Spacer()
                    miniStat(label: "Risk Level",    value: risk?.level.rawValue.capitalized ?? "Low", alignment: .trailing)
                }
            }
            .padding(24)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func miniStat(label: String, value: String, alignment: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(value)
                .font(.subheadline).fontWeight(.bold)
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    // MARK: - Stats Strip (§3.2)

    private var statsStrip: some View {
        HStack(spacing: 0) {
            StatCell(label: "Meals",    value: "\(foodCount)")
            Divider().frame(height: 36)
            StatCell(label: "BMs",      value: "\(bowelCount)")
            Divider().frame(height: 36)
            StatCell(label: "Meds",     value: medsTotal > 0 ? "\(medsTaken)/\(medsTotal)" : "None")
        }
        .padding(.vertical, 14)
        .cardStyle()
        .padding(.horizontal, 20)
    }

    // MARK: - Quick Log Section

    private var quickLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Quick Log")

            HStack(spacing: 10) {
                QuickLogButton(icon: "fork.knife",                label: "Food",     gradient: AppGradient.ocean)    { selectedLogTab = .food;     showLog = true }
                QuickLogButton(icon: "arrow.triangle.2.circlepath", label: "Bowel",  gradient: AppGradient.mint)     { selectedLogTab = .bowel;    showLog = true }
                QuickLogButton(icon: "stethoscope",               label: "Symptoms", gradient: AppGradient.brand)    { selectedLogTab = .symptoms; showLog = true }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Timeline Section

    private var timelineSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Today's Timeline", count: timeline.count)
                .padding(.horizontal, 0)
            ForEach(timeline) { entry in
                TimelineRow(entry: entry)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Empty State (§3.8)

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 40)
            ZStack {
                Circle()
                    .fill(Color.brandPrimary.opacity(0.08))
                    .frame(width: 96, height: 96)
                Image(systemName: "clipboard")
                    .font(.system(size: 40))
                    .foregroundStyle(.brandPrimary.opacity(0.6))
            }
            VStack(spacing: 8) {
                Text("Nothing logged yet")
                    .font(.title2).fontWeight(.bold)
                Text("Tap Quick Log above or use the + button to get started.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - FAB (§3.3)

    private var fab: some View {
        Button { selectedLogTab = .food; showLog = true } label: {
            Image(systemName: "plus")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(AppGradient.brand)
                .clipShape(Circle())
                .shadow(color: .brandPrimary.opacity(0.35), radius: 10, y: 4)
        }
        .padding(.trailing, 24).padding(.bottom, 24)
    }

    // MARK: - Data Loading

    private func loadData() async {
        guard let uid = db.userId else { return }
        loading = true
        animateCards = false

        let fmt = ISO8601DateFormatter()
        let today = fmt.string(from: Calendar.current.startOfDay(for: Date()))
        let tomorrow = fmt.string(from: Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!)

        async let foodRes: [FoodLog]     = (try? db.select("food_logs",     filter: "user_id=eq.\(uid)&logged_at=gte.\(today)&logged_at=lt.\(tomorrow)")) ?? []
        async let bowelRes: [BowelLog]   = (try? db.select("bowel_logs",   filter: "user_id=eq.\(uid)&logged_at=gte.\(today)&logged_at=lt.\(tomorrow)")) ?? []
        async let symptomRes: [SymptomLog] = (try? db.select("symptom_logs", filter: "user_id=eq.\(uid)&logged_at=gte.\(today)&logged_at=lt.\(tomorrow)")) ?? []
        async let medRes: [MedicationLog]  = (try? db.select("medication_logs", filter: "user_id=eq.\(uid)&created_at=gte.\(today)&created_at=lt.\(tomorrow)")) ?? []

        let (foods, bowels, symptoms, meds) = await (foodRes, bowelRes, symptomRes, medRes)

        foodCount = foods.count
        bowelCount = bowels.count
        symptomLogged = !symptoms.isEmpty
        medsTaken = meds.filter { $0.was_taken }.count
        medsTotal = meds.count

        var entries: [TimelineEntry] = []
        entries += foods.map    { TimelineEntry(id: $0.id, type: .food,       date: parseDate($0.logged_at)) }
        entries += bowels.map   { TimelineEntry(id: $0.id, type: .bowel,      date: parseDate($0.logged_at)) }
        entries += symptoms.map { TimelineEntry(id: $0.id, type: .symptom,    date: parseDate($0.logged_at)) }
        entries += meds.map     { TimelineEntry(id: $0.id, type: .medication, date: parseDate($0.created_at), wasTaken: $0.was_taken) }
        timeline = entries.sorted { $0.date > $1.date }

        risk = await calculateRisk(uid: uid)
        loading = false

        withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.05)) {
            animateCards = true
        }
    }

    private func calculateRisk(uid: String) async -> RiskIndicator {
        let sevenDaysAgo = ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .day, value: -7, to: Date())!)
        async let bowelRes: [BowelLog]       = (try? db.select("bowel_logs",      filter: "user_id=eq.\(uid)&logged_at=gte.\(sevenDaysAgo)")) ?? []
        async let symptomRes: [SymptomLog]   = (try? db.select("symptom_logs",   filter: "user_id=eq.\(uid)&logged_at=gte.\(sevenDaysAgo)")) ?? []
        async let medRes: [MedicationLog]    = (try? db.select("medication_logs", filter: "user_id=eq.\(uid)&created_at=gte.\(sevenDaysAgo)")) ?? []
        async let foodRes: [FoodLog]         = (try? db.select("food_logs",       filter: "user_id=eq.\(uid)&logged_at=gte.\(sevenDaysAgo)")) ?? []
        let (bowels, symptoms, meds, foods) = await (bowelRes, symptomRes, medRes, foodRes)

        var score = 0; var factors: [String] = []
        if !bowels.isEmpty {
            let abnormal = bowels.filter { $0.bristol_scale < 3 || $0.bristol_scale > 5 }.count
            let pct = Double(abnormal) / Double(bowels.count)
            if pct > 0.5 { score += 20; factors.append("Irregular bowel movements") }
            else if pct > 0.3 { score += 10; factors.append("Some irregular movements") }
            if bowels.contains(where: { $0.blood_present }) { score += 10; factors.append("Blood in stool") }
        }
        if !symptoms.isEmpty {
            let avgPain = Double(symptoms.reduce(0) { $0 + $1.pain_level }) / Double(symptoms.count)
            if avgPain >= 6 { score += 15; factors.append("High pain levels") }
            else if avgPain >= 4 { score += 8; factors.append("Moderate pain") }
            if symptoms.contains(where: { $0.is_flare }) { score += 15; factors.append("Currently in a flare") }
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

    private func parseDate(_ str: String) -> Date {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.date(from: str) ?? ISO8601DateFormatter().date(from: str) ?? Date()
    }
}

// MARK: - Supporting Views

struct QuickLogButton: View {
    let icon: String; let label: String; let gradient: LinearGradient; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle().fill(gradient).frame(width: 44, height: 44)
                    Image(systemName: icon).font(.system(size: 18, weight: .semibold)).foregroundStyle(.white)
                }
                Text(label).font(.caption).fontWeight(.semibold).foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 16).cardStyle()
        }
        .buttonStyle(.plain)
    }
}

struct TimelineEntry: Identifiable {
    enum EntryType { case food, bowel, symptom, medication }
    let id: String; let type: EntryType; let date: Date; var wasTaken: Bool? = nil
    var icon: String {
        switch type { case .food: return "fork.knife"; case .bowel: return "arrow.triangle.2.circlepath"
        case .symptom: return "stethoscope"; case .medication: return "pills.fill" }
    }
    var label: String {
        switch type { case .food: return "Meal logged"; case .bowel: return "Bowel movement"
        case .symptom: return "Symptoms logged"
        case .medication: return (wasTaken == true) ? "Medication taken" : "Medication missed" }
    }
    var iconColor: Color {
        switch type { case .food: return .brandPrimary; case .bowel: return .brandSuccess
        case .symptom: return .brandWarning
        case .medication: return (wasTaken == true) ? .brandSuccess : .brandDanger }
    }
}

struct TimelineRow: View {
    let entry: TimelineEntry
    var body: some View {
        HStack(spacing: 14) {
            IconBadge(systemName: entry.icon, color: entry.iconColor, size: 40)
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.label).font(.subheadline).fontWeight(.semibold)
                Text(entry.date.dateString("h:mm a")).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14).cardStyle()
    }
}
