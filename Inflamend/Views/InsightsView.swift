import SwiftUI

struct InsightsView: View {
    @State private var range = "7d"

    let painData:    [Double] = [3,4,2,3,5,4,3,2,3,4,5,6,5,4,3,3,4,5,7,6,5,4,3,4,5,4,3,4,3,2]
    let fatigueData: [Double] = [5,6,4,5,6,7,6,5,4,5,6,7,7,6,5,5,6,7,8,7,6,5,4,5,6,5,4,5,4,3]

    var painSlice:    [Double] { range == "7d" ? Array(painData.suffix(7))    : painData }
    var fatigueSlice: [Double] { range == "7d" ? Array(fatigueData.suffix(7)) : fatigueData }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                // Header
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PATTERNS · TRENDS").dsLabel()
                        HStack(spacing: 0) {
                            Text("Your ").font(DS.serif(36)).foregroundColor(.fgPrimary)
                            Text("insights").font(DS.serif(36, italic: true)).foregroundColor(.fgPrimary)
                        }
                    }
                    Spacer()
                    // 7d / 30d toggle
                    HStack(spacing: 2) {
                        ForEach(["7d","30d"], id: \.self) { r in
                            Button { withAnimation { range = r } } label: {
                                Text(r)
                                    .font(DS.mono(12))
                                    .foregroundColor(range == r ? .bgPrimary : .fgDim)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(range == r ? Color.fgPrimary : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(2)
                    .background(Color.bgInset)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 4)

                // Stat tiles
                HStack(spacing: 8) {
                    StatTile(value: "4.2", unit: "/10",  label: "Avg pain",    trend: -0.8)
                    StatTile(value: "2.1", unit: "/day", label: "BM avg",      trend: 0.1)
                    StatTile(value: "18",  unit: "d",    label: "Since flare", trend: nil)
                }
                .padding(.horizontal, 20)

                // Trend chart card
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
                    LineChartView(
                        series: [
                            (data: painSlice,    color: .clay),
                            (data: fatigueSlice, color: .amber),
                        ]
                    )
                }
                .card()
                .padding(.horizontal, 20)

                // Bowel frequency
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bowel frequency")
                        .font(DS.sans(16, weight: .medium))
                        .foregroundColor(.fgPrimary)
                        .tracking(-0.1)
                    Text("Movements per day")
                        .font(DS.sans(12))
                        .foregroundColor(.fgDim)
                        .padding(.bottom, 12)
                    BarChartView(
                        data:   [2,3,2,4,3,2,3],
                        labels: ["Fri","Sat","Sun","Mon","Tue","Wed","Thu"]
                    )
                }
                .card()
                .padding(.horizontal, 20)

                // Heatmap
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .lastTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pain heatmap")
                                .font(DS.sans(16, weight: .medium))
                                .foregroundColor(.fgPrimary)
                                .tracking(-0.1)
                            Text("Last 30 days")
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
                    HeatmapView()
                }
                .card()
                .padding(.horizontal, 20)

                // Top triggers
                VStack(alignment: .leading, spacing: 0) {
                    Text("Top triggers")
                        .font(DS.sans(16, weight: .medium))
                        .foregroundColor(.fgPrimary)
                        .tracking(-0.1)
                        .padding(.bottom, 4)
                    Text("Foods correlated with symptom spikes within 48h")
                        .font(DS.sans(12))
                        .foregroundColor(.fgDim)
                        .padding(.bottom, 14)

                    let triggers: [(food: String, count: Int, severity: Double)] = [
                        ("Dairy (milk, cheese)", 5, 0.9),
                        ("Spicy food",           3, 0.7),
                        ("Raw vegetables",       3, 0.5),
                        ("Coffee",               2, 0.4),
                    ]
                    ForEach(Array(triggers.enumerated()), id: \.offset) { idx, t in
                        TriggerRow(food: t.food, count: t.count, severity: t.severity, isLast: idx == triggers.count - 1)
                    }
                }
                .card()
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(Color.bgPrimary)
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
            let len = series[0].data.count
            let xStep = (w - pad * 2) / max(1, Double(len - 1))

            ZStack {
                // Grid lines
                ForEach([0.0, 0.5, 1.0], id: \.self) { t in
                    Path { p in
                        let y = pad + t * (h - pad * 2)
                        p.move(to: CGPoint(x: pad, y: y))
                        p.addLine(to: CGPoint(x: w - pad, y: y))
                    }
                    .stroke(Color.strokeDefault, style: StrokeStyle(lineWidth: 0.5, dash: [2, 4]))
                }

                // Series
                ForEach(0..<series.count, id: \.self) { si in
                    let s = series[si]
                    let pts = s.data.enumerated().map { (i, v) in
                        CGPoint(
                            x: pad + Double(i) * xStep,
                            y: pad + (1 - v / maxVal) * (h - pad * 2)
                        )
                    }

                    // Fill
                    Path { p in
                        guard !pts.isEmpty else { return }
                        p.move(to: CGPoint(x: pad, y: h - pad))
                        for pt in pts { p.addLine(to: pt) }
                        p.addLine(to: CGPoint(x: pts.last!.x, y: h - pad))
                        p.closeSubpath()
                    }
                    .fill(s.color.opacity(0.08))

                    // Line
                    Path { p in
                        guard !pts.isEmpty else { return }
                        p.move(to: pts[0])
                        for pt in pts.dropFirst() { p.addLine(to: pt) }
                    }
                    .stroke(s.color, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))

                    // Dots
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
    let seed: [Int] = [0,1,2,3,1,0,2, 1,3,4,3,2,1,0, 1,2,3,5,4,3,2, 1,1,2,3,2,1,0, 1,2,3,4]
    let days = ["M","T","W","T","F","S","S"]

    var body: some View {
        let cols = [GridItem(.fixed(20))] + Array(repeating: GridItem(.flexible()), count: 7)

        LazyVGrid(columns: cols, spacing: 4) {
            // Header row
            Color.clear.frame(width: 20, height: 14)
            ForEach(days, id: \.self) { d in
                Text(d)
                    .font(DS.mono(10))
                    .foregroundColor(.fgFaint)
                    .frame(maxWidth: .infinity)
            }

            // Weeks
            ForEach(0..<5) { w in
                Text("W\(w+1)")
                    .font(DS.mono(10))
                    .foregroundColor(.fgFaint)
                    .frame(width: 20)
                ForEach(0..<7) { d in
                    let v = seed[(w * 7 + d) % seed.count]
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

// MARK: - Trigger Row

struct TriggerRow: View {
    let food: String
    let count: Int
    let severity: Double
    var isLast: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(food)
                    .font(DS.sans(14))
                    .foregroundColor(.fgPrimary)
                    .tracking(-0.1)
                Text("\(count) events · 48h window")
                    .font(DS.mono(11))
                    .tracking(0.4)
                    .foregroundColor(.fgFaint)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ZStack(alignment: .leading) {
                Capsule().fill(Color.bgInset).frame(width: 100, height: 6)
                Capsule().fill(Color.clay).frame(width: 100 * severity, height: 6)
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

#Preview {
    InsightsView()
        .background(Color.bgPrimary)
        .preferredColorScheme(.dark)
}
