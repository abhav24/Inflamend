import SwiftUI

struct HomeView: View {
    var appState: AppState
    @Binding var selectedTab: Tab
    @Binding var showFoodSheet: Bool
    @Binding var showBristolSheet: Bool
    @Binding var showCheckInSheet: Bool
    @State private var editingEntry: LogEntry?

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
                        + Text(appState.firstName)
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
                        SummaryRow(icon: "pill",    label: "Meds",     value: "\(appState.medsTaken)", total: "of \(appState.medsTotal)", color: .sage, accessibilityID: "home-meds-summary-row")
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
                    .accessibilityIdentifier("home-start-checkin-button")
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
                        RapidButton(icon: "droplet", label: "Water",  color: .ink)   {
                            appState.addLog(type: .water, title: "Water · 250ml", sub: "Saved locally")
                            appState.showToast("Water logged")
                        }
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
                        if appState.logs.isEmpty {
                            EmptyTimelineRow {
                                selectedTab = .log
                            }
                        } else {
                            ForEach(Array(appState.logs.enumerated()), id: \.element.id) { idx, entry in
                                TimelineRow(entry: entry, isLast: idx == appState.logs.count - 1) {
                                    editingEntry = entry
                                } onDelete: {
                                    appState.deleteLog(id: entry.id)
                                }
                            }
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
        .sheet(item: $editingEntry) { entry in
            TimelineEditSheet(entry: entry) { title, sub, payload in
                appState.updateLog(id: entry.id, title: title, sub: sub, preservePayload: true, payload: payload)
            }
        }
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
        .accessibilityIdentifier("home-safety-card")
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
    var accessibilityID: String? = nil

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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) \(value) \(total)")
        .accessibilityIdentifier(accessibilityID ?? "home-summary-\(label.lowercased())-row")
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

struct EmptyTimelineRow: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                IconBadge(name: "plus", size: 38, iconSize: 16, color: .sage)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Start today's log")
                        .font(DS.sans(15, weight: .medium))
                        .foregroundColor(.fgPrimary)
                    Text("Add a check-in, BM, meal, medication, note, or voice transcript.")
                        .font(DS.sans(12))
                        .foregroundColor(.fgDim)
                        .lineSpacing(2)
                }
                Spacer()
                AppIcon(name: "chevron", size: 14, color: .fgFaint)
            }
            .padding(16)
        }
        .buttonStyle(PressableButtonStyle(scale: 0.98))
        .accessibilityLabel("Start today's log")
        .accessibilityIdentifier("timeline-empty-start-log-button")
    }
}

struct TimelineRow: View {
    let entry: LogEntry
    var isLast: Bool = false
    var onEdit: () -> Void
    var onDelete: () -> Void
    @State private var showDeleteConfirmation = false

    var body: some View {
        HStack(spacing: 12) {
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(entry.title). \(entry.sub). \(entry.time)")
            .accessibilityIdentifier("timeline-entry-\(entry.type.rawValue)")

            HStack(spacing: 2) {
                Button(action: onEdit) {
                    AppIcon(name: "edit", size: 17, color: .fgFaint)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit \(entry.title)")
                .accessibilityIdentifier("timeline-edit-\(entry.type.rawValue)")

                Button {
                    showDeleteConfirmation = true
                } label: {
                    AppIcon(name: "trash", size: 18, color: .fgFaint)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete \(entry.title)")
                .accessibilityIdentifier("timeline-delete-\(entry.type.rawValue)")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(Color.strokeDefault).frame(height: 0.5).padding(.leading, 64)
            }
        }
        .confirmationDialog(
            "Delete log entry?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete entry", role: .destructive) {
                onDelete()
                showDeleteConfirmation = false
            }
            .accessibilityIdentifier("timeline-confirm-delete-\(entry.type.rawValue)-button")

            Button("Cancel", role: .cancel) {
                showDeleteConfirmation = false
            }
        } message: {
            Text("Remove \(entry.title) from local logs on this device.")
        }
    }
}

private struct TimelineEditSheet: View {
    let entry: LogEntry
    let onSave: (String, String, HealthLogPayload?) -> Bool

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    @State private var title: String
    @State private var detail: String
    @State private var payload: HealthLogPayload?

    private enum Field {
        case title
        case detail
    }

    init(entry: LogEntry, onSave: @escaping (String, String, HealthLogPayload?) -> Bool) {
        self.entry = entry
        self.onSave = onSave
        _title = State(initialValue: entry.title)
        _detail = State(initialValue: entry.sub)
        _payload = State(initialValue: entry.payload)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                SheetHandle()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)

                HStack(alignment: .center, spacing: 12) {
                    IconBadge(name: entry.type.iconName, size: 42, iconSize: 18, color: entry.type.color)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("EDIT LOG")
                            .dsLabel()
                        Text(entry.type.rawValue.capitalized)
                            .font(DS.serif(28))
                            .foregroundColor(.fgPrimary)
                            .accessibilityIdentifier("timeline-edit-sheet-title")
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .dsLabel()
                    TextField("Log title", text: $title)
                        .font(DS.sans(15))
                        .foregroundColor(.fgPrimary)
                        .padding(14)
                        .background(Color.bgInset)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .focused($focusedField, equals: .title)
                        .submitLabel(.done)
                        .accessibilityIdentifier("timeline-edit-title-field")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Details")
                        .dsLabel()
                    TextField("Optional detail", text: $detail, axis: .vertical)
                        .font(DS.sans(15))
                        .foregroundColor(.fgPrimary)
                        .lineLimit(3...5)
                        .padding(14)
                        .background(Color.bgInset)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .focused($focusedField, equals: .detail)
                        .accessibilityIdentifier("timeline-edit-detail-field")
                }

                if let foodPayloadBinding {
                    TimelineFoodPayloadFields(payload: foodPayloadBinding)
                }

                if let bowelPayloadBinding {
                    TimelineBowelPayloadFields(payload: bowelPayloadBinding)
                }

                PrimaryButton(title: "Save changes") {
                    if onSave(titleForSave, detailForSave, payload) {
                        dismiss()
                    }
                }
                .accessibilityIdentifier("timeline-save-edit-button")

                GhostButton(title: "Cancel") {
                    dismiss()
                }
                .accessibilityIdentifier("timeline-cancel-edit-button")
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
        }
        .background(Color.bgPrimary.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
                .accessibilityIdentifier("timeline-edit-keyboard-done-button")
            }
        }
    }

    private var foodPayloadBinding: Binding<HealthLogPayload>? {
        guard payload?.kind == .food else { return nil }
        return Binding(
            get: { payload ?? entry.payload ?? HealthLogPayload.food(mealTime: "lunch", description: entry.title, tags: []) },
            set: { payload = $0 }
        )
    }

    private var bowelPayloadBinding: Binding<HealthLogPayload>? {
        guard payload?.kind == .bowel else { return nil }
        return Binding(
            get: {
                payload ?? entry.payload ?? HealthLogPayload.bowel(
                    bristol: 4,
                    urgency: 0,
                    blood: .none,
                    mucus: false,
                    pain: 0,
                    nighttime: false
                )
            },
            set: { payload = $0 }
        )
    }

    private var titleForSave: String {
        guard payload?.kind == .bowel else { return title }
        return payload?.bowelDisplayTitle ?? title
    }

    private var detailForSave: String {
        switch payload?.kind {
        case .food:
            let tags = payload?.foodTags ?? []
            return tags.isEmpty ? "Food pattern tracking" : tags.sorted().joined(separator: " · ")
        case .bowel:
            return payload?.bowelDisplayDetails ?? detail
        default:
            return detail
        }
    }
}

private struct TimelineFoodPayloadFields: View {
    @Binding var payload: HealthLogPayload

    private let mealTimes = ["breakfast", "lunch", "dinner", "snack"]
    private let triggerTags = ["Dairy", "Spicy", "Gluten", "Raw veg", "Caffeine", "Alcohol"]
    private let safeTags = ["Bone broth", "Bananas", "Rice", "Oatmeal"]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Meal")
                    .dsLabel()
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(mealTimes, id: \.self) { meal in
                            LogPill(title: meal.capitalized, isActive: payload.mealTime == meal) {
                                payload.mealTime = meal
                            }
                            .accessibilityIdentifier("timeline-edit-food-meal-\(meal)")
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Known triggers")
                    .dsLabel()
                FlowLayout(spacing: 6) {
                    ForEach(triggerTags, id: \.self) { tag in
                        PillToggle(label: tag, isActive: tagIsActive(tag), color: .clay) {
                            toggleTag(tag)
                        }
                        .accessibilityIdentifier("timeline-edit-food-tag-\(slug(for: tag))")
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Gut-friendly foods")
                    .dsLabel()
                FlowLayout(spacing: 6) {
                    ForEach(safeTags, id: \.self) { tag in
                        PillToggle(label: tag, isActive: tagIsActive(tag), color: .sage) {
                            toggleTag(tag)
                        }
                        .accessibilityIdentifier("timeline-edit-food-tag-\(slug(for: tag))")
                    }
                }
            }
        }
        .padding(14)
        .background(Color.bgInset)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func tagIsActive(_ tag: String) -> Bool {
        Set(payload.foodTags ?? []).contains(tag)
    }

    private func toggleTag(_ tag: String) {
        var tags = Set(payload.foodTags ?? [])
        if tags.contains(tag) {
            tags.remove(tag)
        } else {
            tags.insert(tag)
        }
        payload.foodTags = tags.sorted()
    }

    private func slug(for text: String) -> String {
        text
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }
}

private struct TimelineBowelPayloadFields: View {
    @Binding var payload: HealthLogPayload

    private let bristolLabels = [
        "Hard lumps",
        "Lumpy sausage",
        "Cracked sausage",
        "Smooth sausage",
        "Soft blobs",
        "Mushy",
        "Watery"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Bristol Stool Scale")
                    .dsLabel()
                VStack(spacing: 6) {
                    ForEach(1...7, id: \.self) { value in
                        Button {
                            payload.bristolType = value
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(payload.bristolType == value ? Color.sage : Color.bgPrimary)
                                        .frame(width: 32, height: 32)
                                    Text("\(value)")
                                        .font(DS.mono(13, weight: .semibold))
                                        .foregroundColor(payload.bristolType == value ? .darkText : .fgPrimary)
                                }
                                Text(bristolLabels[value - 1])
                                    .font(DS.sans(14))
                                    .foregroundColor(.fgPrimary)
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(payload.bristolType == value ? Color.sageDim : Color.bgPrimary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(payload.bristolType == value ? Color.sage : Color.clear, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("timeline-edit-bowel-bristol-\(value)")
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Urgency \(payload.urgencyScore ?? 0)/10")
                    .dsLabel()
                Slider(
                    value: Binding(
                        get: { Double(payload.urgencyScore ?? 0) },
                        set: { payload.urgencyScore = Int($0) }
                    ),
                    in: 0...10,
                    step: 1
                )
                .tint(.amber)
                .accessibilityIdentifier("timeline-edit-bowel-urgency-slider")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Blood")
                    .dsLabel()
                FlowLayout(spacing: 6) {
                    ForEach([BloodAmount.none, .trace, .visible, .significant], id: \.rawValue) { option in
                        PillToggle(
                            label: option.rawValue.capitalized,
                            isActive: payload.blood == option,
                            color: option == .none ? .sage : .clay
                        ) {
                            payload.blood = option
                        }
                        .accessibilityIdentifier("timeline-edit-bowel-blood-\(option.rawValue)")
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Pain \(payload.painScore ?? 0)/10")
                    .dsLabel()
                Slider(
                    value: Binding(
                        get: { Double(payload.painScore ?? 0) },
                        set: { payload.painScore = Int($0) }
                    ),
                    in: 0...10,
                    step: 1
                )
                .tint(.clay)
                .accessibilityIdentifier("timeline-edit-bowel-pain-slider")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Other")
                    .dsLabel()
                FlowLayout(spacing: 6) {
                    PillToggle(label: "Mucus", isActive: payload.mucus == true, color: .amber) {
                        payload.mucus = !(payload.mucus ?? false)
                    }
                    .accessibilityIdentifier("timeline-edit-bowel-mucus")

                    PillToggle(label: "Nighttime", isActive: payload.nighttime == true, color: .clay) {
                        payload.nighttime = !(payload.nighttime ?? false)
                    }
                    .accessibilityIdentifier("timeline-edit-bowel-nighttime")
                }
            }
        }
        .padding(14)
        .background(Color.bgInset)
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
