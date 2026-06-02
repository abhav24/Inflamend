import SwiftUI

struct InsightsView: View {
    var appState: AppState
    @State private var range = "Recent"

    private var summary: InsightSummary {
        InsightSummaryBuilder.build(logs: appState.logs, limit: range == "Recent" ? 7 : nil)
    }

    private var chartSeries: [(data: [Double], color: Color)] {
        [
            (data: summary.painValues, color: .clay),
            (data: summary.fatigueValues, color: .amber)
        ]
    }

    private var bowelLabels: [String] {
        summary.bowelValues.indices.map { "\($0 + 1)" }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PATTERNS · TRENDS").dsLabel()
                        HStack(spacing: 0) {
                            Text("Your ")
                                .font(DS.serif(36))
                                .foregroundColor(.fgPrimary)
                            Text("insights")
                                .font(DS.serif(36, italic: true))
                                .foregroundColor(.fgPrimary)
                        }
                        Text(summary.confidenceLabel)
                            .font(DS.sans(12))
                            .foregroundColor(.fgDim)
                    }
                    Spacer()
                    HStack(spacing: 2) {
                        ForEach(["Recent","All"], id: \.self) { r in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { range = r }
                            } label: {
                                Text(r)
                                    .font(DS.mono(12))
                                    .foregroundColor(range == r ? .bgPrimary : .fgDim)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(range == r ? Color.fgPrimary : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .animation(.spring(response: 0.28, dampingFraction: 0.75), value: range)
                            }
                            .buttonStyle(PressableButtonStyle())
                        }
                    }
                    .padding(2)
                    .background(Color.bgInset)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 14)
                .appearAnimation(delay: 0)

                HStack(spacing: 8) {
                    StatTile(value: formatted(summary.averagePain), unit: summary.averagePain == nil ? "" : "/10", label: "Avg pain", trend: nil)
                    StatTile(value: "\(summary.bowelLogCount)", unit: "", label: "BM logs", trend: nil)
                    StatTile(value: "\(summary.flareMentionCount)", unit: "", label: "Flare marks", trend: nil)
                }
                .padding(.horizontal, 20)
                .appearAnimation(delay: 0.07)

                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .lastTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Symptom trend")
                                .font(DS.sans(16, weight: .medium))
                                .foregroundColor(.fgPrimary)
                                .tracking(-0.1)
                            Text("Pain · Fatigue")
                                .font(DS.sans(12))
                                .foregroundColor(.fgDim)
                        }
                        Spacer()
                        HStack(spacing: 10) {
                            LegendDot(color: .clay,  label: "PAIN")
                            LegendDot(color: .amber, label: "FATIGUE")
                        }
                    }
                    .padding(.bottom, 16)
                    if summary.hasTrendData {
                        LineChartView(series: chartSeries)
                    } else {
                        InsightEmptyState(
                            title: "Trend needs more logs",
                            message: "Save at least two check-ins or symptom logs with pain or fatigue scores."
                        )
                    }
                }
                .card()
                .padding(.horizontal, 20)
                .appearAnimation(delay: 0.14)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Bowel logs")
                        .font(DS.sans(16, weight: .medium))
                        .foregroundColor(.fgPrimary)
                        .tracking(-0.1)
                    Text("Recent local entries")
                        .font(DS.sans(12))
                        .foregroundColor(.fgDim)
                        .padding(.bottom, 12)
                    if summary.hasBowelData {
                        BarChartView(data: summary.bowelValues, labels: bowelLabels)
                    } else {
                        InsightEmptyState(
                            title: "No bowel pattern yet",
                            message: "Log bowel movements or check-ins to populate this chart."
                        )
                    }
                }
                .card()
                .padding(.horizontal, 20)
                .appearAnimation(delay: 0.21)

                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .lastTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pain heatmap")
                                .font(DS.sans(16, weight: .medium))
                                .foregroundColor(.fgPrimary)
                                .tracking(-0.1)
                            Text("Saved pain scores")
                                .font(DS.sans(12))
                                .foregroundColor(.fgDim)
                        }
                        Spacer()
                        HStack(spacing: 3) {
                            Text("LOW")
                                .font(DS.mono(10))
                                .foregroundColor(.fgFaint)
                            ForEach(1...5, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color(red: 0.85, green: 0.45, blue: 0.32).opacity(Double(i) / 5.0))
                                    .frame(width: 10, height: 10)
                                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.strokeDefault, lineWidth: 0.5))
                            }
                            Text("HIGH")
                                .font(DS.mono(10))
                                .foregroundColor(.fgFaint)
                        }
                    }
                    .padding(.bottom, 16)
                    if summary.painHeatmapValues.isEmpty {
                        InsightEmptyState(
                            title: "No pain scores yet",
                            message: "Pain scores from check-ins and symptom logs will appear here."
                        )
                    } else {
                        HeatmapView(values: summary.painHeatmapValues)
                    }
                }
                .card()
                .padding(.horizontal, 20)
                .appearAnimation(delay: 0.28)

                VStack(alignment: .leading, spacing: 0) {
                    Text("Food patterns")
                        .font(DS.sans(16, weight: .medium))
                        .foregroundColor(.fgPrimary)
                        .tracking(-0.1)
                        .padding(.bottom, 4)
                    Text("Frequency only · not a trigger claim")
                        .font(DS.sans(12))
                        .foregroundColor(.fgDim)
                        .padding(.bottom, 14)

                    if summary.hasFoodPatterns {
                        ForEach(Array(summary.foodPatterns.enumerated()), id: \.offset) { idx, pattern in
                            PatternRow(pattern: pattern, isLast: idx == summary.foodPatterns.count - 1)
                        }
                    } else {
                        InsightEmptyState(
                            title: "No food patterns yet",
                            message: "Meal logs will be summarized by frequency after you save them."
                        )
                    }
                }
                .card()
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .appearAnimation(delay: 0.35)
            }
        }
        .background(Color.bgPrimary)
    }

    private func formatted(_ value: Double?) -> String {
        guard let value else { return "--" }
        return String(format: "%.1f", value)
    }
}

// MARK: - Stat Tile

struct StatTile: View {
    let value: String
    let unit: String
    let label: String
    let trend: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).dsLabel()
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(DS.serif(32))
                    .foregroundColor(.fgPrimary)
                Text(unit)
                    .font(DS.mono(12))
                    .foregroundColor(.fgFaint)
            }
            if let t = trend {
                Text("\(t < 0 ? "↓" : "↑") \(String(format: "%.1f", abs(t))) vs prev")
                    .font(DS.mono(11))
                    .foregroundColor(t < 0 ? .sage : .clay)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(padding: 14)
    }
}

// MARK: - Legend dot

struct LegendDot: View {
    let color: Color
    let label: String
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
                .font(DS.mono(11))
                .tracking(0.4)
                .foregroundColor(.fgDim)
        }
    }
}

// MARK: - Line Chart

struct LineChartView: View {
    let series: [(data: [Double], color: Color)]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h: CGFloat = 140
            let pad: CGFloat = 8
            let maxVal: Double = 10
            let nonEmptySeries = series.filter { !$0.data.isEmpty }

            ZStack {
                ForEach([0.0, 0.5, 1.0], id: \.self) { t in
                    Path { p in
                        let y = pad + t * (h - pad * 2)
                        p.move(to: CGPoint(x: pad, y: y))
                        p.addLine(to: CGPoint(x: w - pad, y: y))
                    }
                    .stroke(Color.strokeDefault, style: StrokeStyle(lineWidth: 0.5, dash: [2, 4]))
                }

                ForEach(0..<nonEmptySeries.count, id: \.self) { si in
                    let s = nonEmptySeries[si]
                    let xStep = (w - pad * 2) / max(1, Double(s.data.count - 1))
                    let pts = s.data.enumerated().map { (i, v) in
                        CGPoint(
                            x: pad + Double(i) * xStep,
                            y: pad + (1 - v / maxVal) * (h - pad * 2)
                        )
                    }

                    Path { p in
                        guard !pts.isEmpty else { return }
                        p.move(to: CGPoint(x: pad, y: h - pad))
                        for pt in pts { p.addLine(to: pt) }
                        p.addLine(to: CGPoint(x: pts.last!.x, y: h - pad))
                        p.closeSubpath()
                    }
                    .fill(s.color.opacity(0.08))

                    Path { p in
                        guard !pts.isEmpty else { return }
                        p.move(to: pts[0])
                        for pt in pts.dropFirst() { p.addLine(to: pt) }
                    }
                    .stroke(s.color, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))

                    ForEach(0..<pts.count, id: \.self) { i in
                        Circle()
                            .fill(s.color)
                            .frame(width: 4, height: 4)
                            .position(pts[i])
                    }
                }
            }
            .frame(height: h)
        }
        .frame(height: 140)
    }
}

// MARK: - Bar Chart

struct BarChartView: View {
    let data: [Double]
    let labels: [String]

    var body: some View {
        let maxVal = data.max() ?? 1
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(0..<data.count, id: \.self) { i in
                VStack(spacing: 6) {
                    Text(data[i] == data[i].rounded() ? "\(Int(data[i]))" : "")
                        .font(DS.mono(10))
                        .foregroundColor(.fgDim)
                    GeometryReader { geo in
                        let h = geo.size.height * (data[i] / maxVal)
                        VStack(spacing: 0) {
                            Spacer()
                            RoundedRectangle(cornerRadius: 6)
                                .fill(i == data.count - 1 ? Color.sage : Color.sageDim)
                                .frame(height: max(4, h))
                        }
                    }
                    Text(labels[i])
                        .font(DS.mono(10))
                        .tracking(0.4)
                        .foregroundColor(.fgFaint)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 120)
    }
}

// MARK: - Heatmap

struct HeatmapView: View {
    let values: [Int]
    let days = ["M","T","W","T","F","S","S"]

    var body: some View {
        let cols = [GridItem(.fixed(20))] + Array(repeating: GridItem(.flexible()), count: 7)
        let trimmedValues = Array(values.suffix(35))
        let paddedValues = Array(repeating: 0, count: max(0, 35 - trimmedValues.count)) + trimmedValues

        LazyVGrid(columns: cols, spacing: 4) {
            Color.clear.frame(width: 20, height: 14)
            ForEach(days, id: \.self) { d in
                Text(d)
                    .font(DS.mono(10))
                    .foregroundColor(.fgFaint)
                    .frame(maxWidth: .infinity)
            }

            ForEach(0..<5) { w in
                Text("W\(w+1)")
                    .font(DS.mono(10))
                    .foregroundColor(.fgFaint)
                    .frame(width: 20)
                ForEach(0..<7) { d in
                    let v = paddedValues[w * 7 + d]
                    let hasValue = v > 0
                    RoundedRectangle(cornerRadius: 5)
                        .fill(hasValue
                            ? Color(red: 0.85, green: 0.42, blue: 0.32).opacity(Double(v) / 5.0)
                            : Color.bgInset)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.strokeDefault, lineWidth: 0.5))
                        .aspectRatio(1, contentMode: .fit)
                }
            }
        }
    }
}

// MARK: - Pattern Row

struct PatternRow: View {
    let pattern: InsightFoodPattern
    var isLast: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(pattern.label)
                    .font(DS.sans(14))
                    .foregroundColor(.fgPrimary)
                    .tracking(-0.1)
                Text("\(pattern.count) food logs")
                    .font(DS.mono(11))
                    .tracking(0.4)
                    .foregroundColor(.fgFaint)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ZStack(alignment: .leading) {
                Capsule().fill(Color.bgInset).frame(width: 100, height: 6)
                Capsule().fill(Color.clay).frame(width: 100 * pattern.severity, height: 6)
            }
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(Color.strokeDefault).frame(height: 0.5)
            }
        }
    }
}

struct InsightEmptyState: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(DS.sans(14, weight: .medium))
                .foregroundColor(.fgPrimary)
            Text(message)
                .font(DS.sans(12))
                .foregroundColor(.fgFaint)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        .padding(14)
        .background(Color.bgInset)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    InsightsView(appState: AppState())
        .background(Color.bgPrimary)
        .preferredColorScheme(.dark)
}
