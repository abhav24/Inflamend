import SwiftUI

enum InsightsRange: String, CaseIterable {
    case week = "7 Days"
    case month = "30 Days"
    var days: Int { self == .week ? 7 : 30 }
}

struct DayPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}

struct InsightsView: View {
    @State private var range: InsightsRange = .week
    @State private var loading = false
    @State private var painPoints: [DayPoint] = []
    @State private var bowelPoints: [DayPoint] = []
    @State private var topTriggers: [(name: String, count: Int)] = []
    @State private var heatmapData: [(date: Date, pain: Double?)] = []

    private let db = SupabaseClient.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Range Picker
                    Picker("Range", selection: $range) {
                        ForEach(InsightsRange.allCases, id: \.self) { r in
                            Text(r.rawValue).tag(r)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    if loading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else {
                        VStack(spacing: 20) {
                            painTrendCard
                            bowelFrequencyCard
                            triggerFoodsCard
                            heatmapCard
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
        }
        .task { await loadData() }
        .onChange(of: range) { _, _ in Task { await loadData() } }
    }

    // MARK: - Cards

    private var painTrendCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            cardHeader(title: "Symptom Trends", subtitle: "Average pain level per day (0–10)",
                       icon: "waveform.path.ecg", color: .brandDanger)
            if painPoints.allSatisfy({ $0.value == 0 }) {
                emptyChart(icon: "chart.line.downtrend.xyaxis", text: "No symptom data for this period")
            } else {
                BarChart(points: painPoints, maxY: 10, color: .brandDanger)
            }
        }
        .padding(16)
        .cardStyle()
    }

    private var bowelFrequencyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            cardHeader(title: "Bowel Frequency", subtitle: "Count per day",
                       icon: "arrow.triangle.2.circlepath", color: .brandPrimary)
            if bowelPoints.allSatisfy({ $0.value == 0 }) {
                emptyChart(icon: "calendar.badge.exclamationmark", text: "No bowel data for this period")
            } else {
                BarChart(points: bowelPoints, maxY: Double(bowelPoints.map(\.value).max() ?? 1), color: .brandPrimary)
            }
        }
        .padding(16)
        .cardStyle()
    }

    private var triggerFoodsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardHeader(title: "Potential Triggers", subtitle: "Foods you marked as triggers",
                       icon: "exclamationmark.triangle.fill", color: .brandWarning)

            if topTriggers.isEmpty {
                emptyChart(icon: "checkmark.seal.fill", text: "No trigger foods logged yet")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(topTriggers.enumerated()), id: \.offset) { index, item in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.caption).fontWeight(.bold)
                                .foregroundStyle(.secondary)
                                .frame(width: 20)
                            Text(item.name.prefix(1).uppercased() + item.name.dropFirst())
                                .font(.subheadline).fontWeight(.medium)
                            Spacer()
                            Text("\(item.count)x")
                                .font(.subheadline).fontWeight(.bold)
                                .foregroundStyle(.brandWarning)
                                .monospacedDigit()
                        }
                        .padding(.vertical, 10)
                        if index < topTriggers.count - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(16)
        .cardStyle()
    }

    private var heatmapCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardHeader(title: "Pain Heatmap", subtitle: "Last 30 days",
                       icon: "calendar.circle.fill", color: .brandSecondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(heatmapData, id: \.date) { item in
                    let color = heatmapColor(item.pain)
                    VStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(color)
                            .frame(height: 32)
                            .overlay(
                                Text(dayLabel(item.date))
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(.white)
                            )
                    }
                }
            }

            HStack(spacing: 16) {
                legendItem(color: .brandSuccess, label: "Low (0–3)")
                legendItem(color: .brandWarning, label: "Moderate (4–6)")
                legendItem(color: .brandDanger, label: "High (7–10)")
                legendItem(color: Color(.systemFill), label: "No data")
            }
            .font(.caption)
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: - Helpers

    @ViewBuilder
    private func cardHeader(title: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            IconBadge(systemName: icon, color: color, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline).fontWeight(.bold)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func emptyChart(icon: String, text: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(.secondary.opacity(0.5))
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).foregroundStyle(.secondary)
        }
    }

    private func heatmapColor(_ pain: Double?) -> Color {
        guard let pain else { return Color(.systemFill) }
        if pain <= 3 { return .brandSuccess }
        if pain <= 6 { return .brandWarning }
        return .brandDanger
    }

    private func dayLabel(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "d"
        return f.string(from: date)
    }

    // MARK: - Data Loading

    private func loadData() async {
        guard let uid = db.userId else { return }
        loading = true

        let fmt = ISO8601DateFormatter()
        let to = Date()
        let from = Calendar.current.date(byAdding: .day, value: -(range.days - 1), to: to)!
        let fromStr = fmt.string(from: Calendar.current.startOfDay(for: from))
        let toStr = fmt.string(from: Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: to))!)

        async let symptomsRes: [SymptomLog] = (try? db.select("symptom_logs",
            filter: "user_id=eq.\(uid)&logged_at=gte.\(fromStr)&logged_at=lt.\(toStr)")) ?? []
        async let bowelsRes: [BowelLog] = (try? db.select("bowel_logs",
            filter: "user_id=eq.\(uid)&logged_at=gte.\(fromStr)&logged_at=lt.\(toStr)")) ?? []
        async let foodsRes: [FoodLog] = (try? db.select("food_logs",
            filter: "user_id=eq.\(uid)&logged_at=gte.\(fromStr)&logged_at=lt.\(toStr)")) ?? []

        let (symptoms, bowels, foods) = await (symptomsRes, bowelsRes, foodsRes)

        // Build day arrays
        let days = (0..<range.days).map { i in
            Calendar.current.date(byAdding: .day, value: i, to: from)!
        }

        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let labelFmt = DateFormatter(); labelFmt.dateFormat = "M/d"

        // Pain points
        var painMap: [String: [Int]] = [:]
        for d in days { painMap[df.string(from: d)] = [] }
        for log in symptoms {
            let key = String(log.logged_at.prefix(10))
            if painMap[key] != nil { painMap[key]!.append(log.pain_level) }
        }
        painPoints = days.map { day in
            let key = df.string(from: day)
            let vals = painMap[key] ?? []
            let avg = vals.isEmpty ? 0.0 : Double(vals.reduce(0, +)) / Double(vals.count)
            return DayPoint(label: labelFmt.string(from: day), value: avg)
        }

        // Bowel points
        var bowelMap: [String: Int] = [:]
        for d in days { bowelMap[df.string(from: d)] = 0 }
        for log in bowels {
            let key = String(log.logged_at.prefix(10))
            if bowelMap[key] != nil { bowelMap[key]! += 1 }
        }
        bowelPoints = days.map { day in
            DayPoint(label: labelFmt.string(from: day), value: Double(bowelMap[df.string(from: day)] ?? 0))
        }

        // Triggers
        var triggerCounts: [String: Int] = [:]
        for food in foods where food.is_trigger_food {
            let key = food.description.trimmingCharacters(in: .whitespaces).lowercased()
            triggerCounts[key, default: 0] += 1
        }
        topTriggers = triggerCounts.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, $0.value) }

        // Heatmap (always 30 days)
        let heatFrom = Calendar.current.date(byAdding: .day, value: -29, to: to)!
        let heatDays = (0..<30).map { i in Calendar.current.date(byAdding: .day, value: i, to: heatFrom)! }
        let heatFromStr = fmt.string(from: Calendar.current.startOfDay(for: heatFrom))
        let heatSymptoms: [SymptomLog] = (try? await db.select("symptom_logs",
            filter: "user_id=eq.\(uid)&logged_at=gte.\(heatFromStr)")) ?? []
        var heatMap: [String: [Int]] = [:]
        for d in heatDays { heatMap[df.string(from: d)] = [] }
        for log in heatSymptoms {
            let key = String(log.logged_at.prefix(10))
            if heatMap[key] != nil { heatMap[key]!.append(log.pain_level) }
        }
        heatmapData = heatDays.map { day in
            let vals = heatMap[df.string(from: day)] ?? []
            let avg: Double? = vals.isEmpty ? nil : Double(vals.reduce(0, +)) / Double(vals.count)
            return (date: day, pain: avg)
        }

        loading = false
    }
}

// MARK: - Bar Chart

struct BarChart: View {
    let points: [DayPoint]
    let maxY: Double
    let color: Color
    var height: CGFloat = 120

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(points) { point in
                    let frac = maxY > 0 ? point.value / maxY : 0
                    let barH = max(CGFloat(frac) * height, point.value > 0 ? 4 : 2)
                    VStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(point.value > 0 ? color : Color(.systemFill))
                            .frame(height: barH)
                            .animation(.spring(response: 0.5), value: barH)
                    }
                    .frame(height: height)
                }
            }
            HStack(spacing: 3) {
                ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                    let show = index == 0 || index == points.count - 1 || index == points.count / 2
                    Text(show ? point.label : "")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.top, 8)
    }
}
