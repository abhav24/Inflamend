import SwiftUI

struct HomeView: View {
    var appState: AppState
    @Binding var selectedTab: Tab
    @Binding var showFoodSheet: Bool
    @Binding var showBristolSheet: Bool
    @Binding var showCheckInSheet: Bool

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 5  { return "Rest up" }
        if h < 12 { return "Good morning" }
        if h < 18 { return "Good afternoon" }
        return "Good evening"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(alignment: .bottom) {

                    VStack(alignment: .leading, spacing: 4) {
                        Text(todayLabel)
                            .dsLabel()
                        (Text("\(greeting), ")
                            .font(DS.serif(36))
                            .foregroundColor(.fgPrimary)
                        + Text("Priya")
                            .font(DS.serif(36, italic: true))
                            .foregroundColor(.fgPrimary))
                    }
                    Spacer()
                    // Bell button
                    Button {
                        appState.showToast("3 reminders snoozed")
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            AppIcon(name: "bell", size: 20, color: .fgPrimary)
                                .frame(width: 44, height: 44)
                                .background(Color.bgInset)
                                .clipShape(Circle())
                            Circle()
                                .fill(Color.clay)
                                .frame(width: 8, height: 8)
                                .overlay(Circle().stroke(Color.bgCard, lineWidth: 2))
                                .offset(x: 2, y: -2)
                        }
                    }
                    .buttonStyle(PressableButtonStyle(scale: 0.92))
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 18)
                .appearAnimation(delay: 0)

                // Risk card + Today summary side by side
                HStack(alignment: .top, spacing: 10) {
                    // Risk card (wider)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("FLARE RISK")
                            .dsLabel()
                            .padding(.bottom, 8)
                        RiskRing(score: appState.riskScore, size: 164, strokeWidth: 10)
                            .frame(maxWidth: .infinity)
                        Text("Based on ")
                            .font(DS.sans(12))
                            .foregroundColor(.fgDim) +
                        Text("7 days")
                            .font(DS.sans(12, weight: .medium))
                            .foregroundColor(.fgPrimary) +
                        Text(" of logs")
                            .font(DS.sans(12))
                            .foregroundColor(.fgDim)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(Color.bgCard)
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.strokeDefault, lineWidth: 0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 24))

                    // Today summary (narrower)
                    VStack(spacing: 0) {
                        Text("TODAY")
                            .dsLabel()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 10)
                        SummaryRow(icon: "flame",   label: "Symptoms", value: "\(appState.logs.filter { $0.type == .symptom }.count)", total: "logged", color: .clay)
                        SummaryRow(icon: "pill",    label: "Meds",     value: "\(appState.medsTaken)", total: "of \(appState.medsTotal)", color: .sage)
                        SummaryRow(icon: "droplet", label: "Water",    value: "6",   total: "cups",  color: .ink)
                        SummaryRow(icon: "moon",    label: "Sleep",    value: "7.2", total: "hrs",   color: .amber, isLast: true)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(Color.bgCard)
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.strokeDefault, lineWidth: 0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
                .appearAnimation(delay: 0.07)

                if let safety = appState.latestSafetyMessage {
                    SafetyCard(message: safety) {
                        appState.clearSafetyMessage()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 14)
                    .appearAnimation(delay: 0.10)
                }

                // Check-in card
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .lastTextBaseline) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("CHECK-IN").dsLabel()
                            Text("How are you feeling?")
                                .font(DS.sans(18, weight: .medium))
                                .foregroundColor(.fgPrimary)
                                .tracking(-0.15)
                        }
                        Spacer()
                        if appState.mood != nil {
                            DSChip(text: "LOGGED · \(timeNow())")
                        }
                    }
                    .padding(.bottom, 14)

                    PrimaryButton(title: "Start check-in") {
                        showCheckInSheet = true
                    }
                    .padding(.bottom, 12)

                    HStack(spacing: 8) {
                        ForEach(MoodOption.allCases, id: \.self) { option in
                            Button {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                                    appState.mood = option
                                }
                                appState.showToast("Logged: feeling \(option.label.lowercased())")
                            } label: {
                                VStack(spacing: 6) {
                                    Text(option.icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(option.color)
                                    Text(option.label)
                                        .font(DS.sans(13, weight: .medium))
                                        .foregroundColor(appState.mood == option ? option.color : .fgPrimary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(appState.mood == option ? option.color.opacity(0.15) : Color.bgInset)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(appState.mood == option ? option.color : Color.clear, lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: appState.mood)
                            }
                            .buttonStyle(PressableButtonStyle())
                        }
                    }
                }
                .card()
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
                .appearAnimation(delay: 0.14)

                // Rapid log row
                VStack(spacing: 10) {
                    HStack {
                        Text("RAPID LOG · ONE TAP").dsLabel()
                        Spacer()
                        Button { selectedTab = .log } label: {
                            Text("MORE →")
                                .font(DS.mono(12))
                                .tracking(0.8)
                                .foregroundColor(.sage)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                    .padding(.horizontal, 4)

                    HStack(spacing: 8) {
                        RapidButton(icon: "droplet", label: "Water",  color: .ink)   { appState.showToast("Logged water · 250ml") }
                        RapidButton(icon: "fork",    label: "Meal",   color: .sage)  { showFoodSheet = true }
                        RapidButton(icon: "pill",    label: "Meds",   color: .amber) { appState.recordMedicationTaken(name: "Mesalamine") }
                        RapidButton(icon: "activity",label: "BM",     color: .clay)  { showBristolSheet = true }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
                .appearAnimation(delay: 0.21)

                // Timeline
                VStack(spacing: 10) {
                    HStack {
                        Text("TIMELINE · TODAY").dsLabel().padding(.horizontal, 4)
                        Spacer()
                        Text("\(appState.logs.count) entries")
                            .font(DS.mono(11))
                            .foregroundColor(.fgFaint)
                    }
                    .padding(.horizontal, 4)

                    VStack(spacing: 0) {
                        ForEach(Array(appState.logs.enumerated()), id: \.element.id) { idx, entry in
                            TimelineRow(entry: entry, isLast: idx == appState.logs.count - 1)
                        }
                    }
                    .background(Color.bgCard)
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.strokeDefault, lineWidth: 0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
                .appearAnimation(delay: 0.28)

                // AI nudge card
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.sageDim)
                            .frame(width: 36, height: 36)
                        AppIcon(name: "sparkle", size: 18, color: .sage)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("PATTERN SPOTTED")
                            .font(DS.mono(10, weight: .medium))
                            .tracking(1.4)
                            .textCase(.uppercase)
                            .foregroundColor(.sage)

                        Group {
                            Text("Your urgency spikes ")
                            + Text("2–3 days")
                                .font(DS.serif(17, italic: true))
                            + Text(" after dairy-heavy meals. Consider a 48-hour pause.")
                        }
                        .font(DS.sans(15))
                        .foregroundColor(.fgPrimary)
                        .lineSpacing(3)

                        Button { selectedTab = .chat } label: {
                            Text("DISCUSS WITH AI →")
                                .font(DS.mono(12))
                                .tracking(0.8)
                                .foregroundColor(.sage)
                        }
                        .buttonStyle(PressableButtonStyle())
                        .padding(.top, 6)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(18)
                .background(
                    LinearGradient(
                        colors: [Color.sage.opacity(0.14), Color.amber.opacity(0.10)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.sage.opacity(0.5), lineWidth: 0.5))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
                .appearAnimation(delay: 0.35)
            }
        }
        .background(Color.bgPrimary)
    }

    private func timeNow() -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: Date()).lowercased()
    }

    private var todayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE · MMM d"
        return formatter.string(from: Date()).uppercased()
    }
}

// MARK: - Safety Card

struct SafetyCard: View {
    let message: String
    let dismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            IconBadge(name: "shield", size: 38, iconSize: 18, color: .clay)

            VStack(alignment: .leading, spacing: 6) {
                Text("SAFETY CHECK")
                    .font(DS.mono(10, weight: .medium))
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundColor(.clay)
                Text(message)
                    .font(DS.sans(14))
                    .foregroundColor(.fgPrimary)
                    .lineSpacing(3)
                Button("DISMISS", action: dismiss)
                    .font(DS.mono(11))
                    .foregroundColor(.fgDim)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color.clayDim)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.clay.opacity(0.45), lineWidth: 0.5))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Safety check. \(message)")
    }
}

// MARK: - Summary Row

struct SummaryRow: View {
    let icon: String
    let label: String
    let value: String
    let total: String
    let color: Color
    var isLast: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.13))
                    .frame(width: 26, height: 26)
                AppIcon(name: icon, size: 13, color: color)
            }
            Text(label)
                .font(DS.sans(13))
                .foregroundColor(.fgDim)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(DS.mono(13))
                    .foregroundColor(.fgPrimary)
                Text(total)
                    .font(DS.mono(11))
                    .foregroundColor(.fgFaint)
            }
        }
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(Color.strokeDefault).frame(height: 0.5)
            }
        }
    }
}

// MARK: - Rapid Button

struct RapidButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.13))
                        .frame(width: 40, height: 40)
                    AppIcon(name: icon, size: 19, color: color)
                }
                Text(label)
                    .font(DS.sans(12))
                    .foregroundColor(.fgDim)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(Color.bgCard)
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.strokeDefault, lineWidth: 0.5))
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
        .buttonStyle(PressableButtonStyle())
    }
}

// MARK: - Timeline Row

struct TimelineRow: View {
    let entry: LogEntry
    var isLast: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            IconBadge(name: entry.type.iconName, size: 36, iconSize: 15, color: entry.type.color)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(DS.sans(14))
                    .foregroundColor(.fgPrimary)
                    .tracking(-0.1)
                if !entry.sub.isEmpty {
                    Text(entry.sub)
                        .font(DS.sans(12))
                        .foregroundColor(.fgDim)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(entry.time)
                .font(DS.mono(11))
                .tracking(0.4)
                .foregroundColor(.fgFaint)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(Color.strokeDefault).frame(height: 0.5).padding(.leading, 64)
            }
        }
    }
}

#Preview {
    HomeView(
        appState: AppState(),
        selectedTab: .constant(.home),
        showFoodSheet: .constant(false),
        showBristolSheet: .constant(false),
        showCheckInSheet: .constant(false)
    )
    .background(Color.bgPrimary)
    .preferredColorScheme(.dark)
}
