import SwiftUI

enum LogTab: String, CaseIterable {
    case rapid   = "Rapid"
    case food    = "Food"
    case bowel   = "Bowel"
    case symptom = "Symptoms"
    case meds    = "Meds"
    case sleep   = "Sleep"
    case weight  = "Weight"
    case note    = "Note"
    case voice   = "Voice"
}

struct LogView: View {
    var appState: AppState
    @State private var activeTab: LogTab = .rapid

    var body: some View {
        VStack(spacing: 0) {
            // Header
            ScreenHeader(subtitle: "NEW ENTRY", title: "Log your ", titleItalicSuffix: "day")

            // Tab pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(LogTab.allCases, id: \.self) { t in
                        LogPill(title: t.rawValue, isActive: activeTab == t) {
                            withAnimation(.easeInOut(duration: 0.15)) { activeTab = t }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 14)

            // Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    switch activeTab {
                    case .rapid:   LogRapidForm(appState: appState)
                    case .food:    LogFoodForm(appState: appState)
                    case .bowel:   LogBowelForm(appState: appState)
                    case .symptom: LogSymptomForm(appState: appState)
                    case .meds:    LogMedsForm(appState: appState)
                    case .sleep:   LogSleepForm(appState: appState)
                    case .weight:  LogWeightForm(appState: appState)
                    case .note:    LogNoteForm(appState: appState)
                    case .voice:   LogVoiceForm(appState: appState)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .animation(.easeInOut(duration: 0.15), value: activeTab)
            }
        }
        .background(Color.bgPrimary)
    }
}

// MARK: - Form Card wrapper

struct FormCard<Content: View>: View {
    let title: String
    var label: String? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .lastTextBaseline) {
                Text(title)
                    .font(DS.sans(15, weight: .medium))
                    .foregroundColor(.fgPrimary)
                    .tracking(-0.1)
                Spacer()
                if let lbl = label {
                    Text(lbl).dsLabel()
                }
            }
            content()
        }
        .card()
    }
}

// MARK: - Pill toggle

struct PillToggle: View {
    let label: String
    let isActive: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(DS.sans(13))
                .foregroundColor(isActive ? color : .fgDim)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isActive ? color.opacity(0.15) : Color.bgInset)
                .overlay(
                    Capsule().stroke(isActive ? color : Color.clear, lineWidth: 1)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isActive)
    }
}

// MARK: - Rapid form

struct LogRapidForm: View {
    var appState: AppState
    let items: [(k: String, label: String, icon: String, color: Color, msg: String)] = [
        ("well",  "Feeling well",    "check",    .sage,  "Feeling well"),
        ("flare", "In a flare",      "flame",    .clay,  "Flare marker"),
        ("water", "Water · 250ml",   "droplet",  .ink,   "Water · 250ml"),
        ("meds",  "Meds taken",      "pill",     .amber, "Medication taken"),
        ("bm",    "Bowel movement",  "activity", .clay,  "Bowel movement"),
        ("meal",  "Safe meal",       "fork",     .sage,  "Safe meal"),
    ]

    var body: some View {
        let cols = [GridItem(.flexible()), GridItem(.flexible())]
        LazyVGrid(columns: cols, spacing: 10) {
            ForEach(items, id: \.k) { item in
                Button {
                    switch item.k {
                    case "well":
                        appState.recordCheckIn(status: .great, pain: 0, fatigue: 1, urgency: 0, stoolCount: 1, bloodPresent: false, medicationTaken: true, notes: "")
                    case "flare":
                        appState.recordCheckIn(status: .flare, pain: 7, fatigue: 8, urgency: 7, stoolCount: 5, bloodPresent: false, medicationTaken: true, notes: "Rapid flare marker")
                    case "water":
                        appState.addLog(type: .water, title: "Water · 250ml", sub: "Saved on this device")
                        appState.showToast("Water logged")
                    case "meds":
                        appState.recordMedicationTaken()
                    case "bm":
                        appState.recordBowel(bristol: 4, urgency: 3, blood: .none, mucus: false, pain: 0, nighttime: false)
                    case "meal":
                        appState.addLog(type: .food, title: "Safe meal", sub: "Food pattern tracking")
                        appState.showToast("Meal logged")
                    default:
                        appState.showToast(item.msg)
                    }
                } label: {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle().fill(item.color.opacity(0.13)).frame(width: 44, height: 44)
                            AppIcon(name: item.icon, size: 22, color: item.color)
                        }
                        Text(item.label)
                            .font(DS.sans(14))
                            .foregroundColor(.fgPrimary)
                            .tracking(-0.1)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1.3, contentMode: .fit)
                    .padding(18)
                    .background(Color.bgCard)
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.strokeDefault, lineWidth: 0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                }
                .buttonStyle(.plain)
            }
        }

        HStack(spacing: 12) {
            IconBadge(name: "sparkle", size: 36, iconSize: 17, color: .sage)
            Text("Need more detail? Switch tabs above for guided forms.")
                .font(DS.sans(13))
                .foregroundColor(.fgDim)
                .lineSpacing(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .card()
    }
}

// MARK: - Food form

struct LogFoodForm: View {
    var appState: AppState
    @State private var meal = "lunch"
    @State private var name = ""
    @State private var tags: Set<String> = []
    let mealTimes = ["breakfast", "lunch", "dinner", "snack"]
    let triggerTags = ["Dairy", "Spicy", "Gluten", "Raw veg", "Caffeine", "Alcohol"]
    let safeTags    = ["Bone broth", "Bananas", "Rice", "Oatmeal"]

    var body: some View {
        FormCard(title: "When", label: "MEAL") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(mealTimes, id: \.self) { m in
                        LogPill(title: m.capitalized, isActive: meal == m) { meal = m }
                    }
                }
            }
        }

        FormCard(title: "What did you eat?", label: "DESCRIPTION") {
            TextField("e.g. Grilled chicken, white rice, steamed carrots", text: $name)
                .font(DS.sans(15))
                .foregroundColor(.fgPrimary)
                .padding(12)
                .background(Color.bgInset)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }

        FormCard(title: "Known triggers", label: "TAG IF PRESENT") {
            FlowLayout(spacing: 6) {
                ForEach(triggerTags, id: \.self) { t in
                    PillToggle(label: t, isActive: tags.contains(t), color: .clay) {
                        if tags.contains(t) { tags.remove(t) } else { tags.insert(t) }
                    }
                }
            }
        }

        FormCard(title: "Gut-friendly foods", label: "TAG IF PRESENT") {
            FlowLayout(spacing: 6) {
                ForEach(safeTags, id: \.self) { t in
                    PillToggle(label: t, isActive: tags.contains(t), color: .sage) {
                        if tags.contains(t) { tags.remove(t) } else { tags.insert(t) }
                    }
                }
            }
        }

        PrimaryButton(title: "Save entry") {
            let title = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Meal · \(meal)" : name
            let sub = tags.isEmpty ? "Food pattern tracking" : tags.sorted().joined(separator: " · ")
            appState.addLog(type: .food, title: title, sub: sub)
            appState.showToast("Meal logged")
            name = ""; tags = []
        }
    }
}

// MARK: - Bowel form

struct LogBowelForm: View {
    var appState: AppState
    @State private var bristol = 4
    @State private var urgency = 3.0
    @State private var blood: BloodAmount = .none
    @State private var mucus = false
    @State private var pain  = 2.0
    @State private var nighttime = false
    let bristolLabels = ["Hard lumps", "Lumpy sausage", "Cracked sausage", "Smooth sausage", "Soft blobs", "Mushy", "Watery"]

    var body: some View {
        FormCard(title: "Bristol Stool Scale", label: "TYPE 1–7") {
            VStack(spacing: 6) {
                ForEach(0..<7) { i in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(bristol == i+1 ? Color.sage : Color.bgPrimary)
                                .frame(width: 32, height: 32)
                            Text("\(i+1)")
                                .font(DS.mono(13, weight: .semibold))
                                .foregroundColor(bristol == i+1 ? .darkText : .fgPrimary)
                        }
                        Text(bristolLabels[i])
                            .font(DS.sans(14))
                            .foregroundColor(.fgPrimary)
                            .tracking(-0.1)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(bristol == i+1 ? Color.sageDim : Color.bgInset)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(bristol == i+1 ? Color.sage : Color.clear, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .onTapGesture { bristol = i+1 }
                    .animation(.easeInOut(duration: 0.15), value: bristol)
                }
            }
        }

        FormCard(title: "Urgency", label: "LEVEL \(Int(urgency))/10") {
            Slider(value: $urgency, in: 0...10, step: 1)
                .tint(.amber)
        }

        FormCard(title: "Blood", label: blood.rawValue.uppercased()) {
            FlowLayout(spacing: 6) {
                ForEach([BloodAmount.none, .trace, .visible, .significant], id: \.rawValue) { option in
                    PillToggle(label: option.rawValue.capitalized, isActive: blood == option, color: option == .none ? .sage : .clay) {
                        blood = option
                    }
                }
            }
        }

        FormCard(title: "Pain", label: "LEVEL \(Int(pain))/10") {
            Slider(value: $pain, in: 0...10, step: 1)
                .tint(.clay)
        }

        FormCard(title: "Other", label: "TAG IF PRESENT") {
            FlowLayout(spacing: 6) {
                PillToggle(label: "Mucus", isActive: mucus, color: .amber) { mucus.toggle() }
                PillToggle(label: "Nighttime", isActive: nighttime, color: .clay) { nighttime.toggle() }
            }
        }

        PrimaryButton(title: "Save entry") {
            appState.recordBowel(
                bristol: bristol,
                urgency: Int(urgency),
                blood: blood,
                mucus: mucus,
                pain: Int(pain),
                nighttime: nighttime
            )
        }
    }
}

// MARK: - Symptom form

struct LogSymptomForm: View {
    var appState: AppState
    @State private var painVal    = 4.0
    @State private var fatigueVal = 6.0
    @State private var moodVal    = 5.0

    var body: some View {
        FormCard(title: "Pain", label: "\(Int(painVal))/10") {
            Slider(value: $painVal, in: 0...10, step: 1).tint(.clay)
        }
        FormCard(title: "Fatigue", label: "\(Int(fatigueVal))/10") {
            Slider(value: $fatigueVal, in: 0...10, step: 1).tint(.amber)
        }
        FormCard(title: "Mood", label: "\(Int(moodVal))/10") {
            Slider(value: $moodVal, in: 0...10, step: 1).tint(.sage)
        }
        FormCard(title: "Pain location", label: "TAP ON BODY") {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.bgInset)
                    .frame(height: 160)
                Text("BODY MAP · PLACEHOLDER")
                    .font(DS.mono(11))
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundColor(.fgFaint)
            }
        }
        PrimaryButton(title: "Save entry") {
            appState.addLog(type: .symptom, title: "Pain \(Int(painVal))/10 · fatigue \(Int(fatigueVal))/10", sub: "Mood \(Int(moodVal))/10")
            appState.showToast("Symptoms saved")
        }
    }
}

// MARK: - Meds form

struct LogMedsForm: View {
    var appState: AppState
    @State private var meds: [MedEntry] = [
        MedEntry(name: "Mesalamine",   dose: "800mg",   time: "8:00am",  taken: true),
        MedEntry(name: "Azathioprine", dose: "50mg",    time: "8:00am",  taken: true),
        MedEntry(name: "Vitamin D",    dose: "1000 IU", time: "8:00am",  taken: false),
        MedEntry(name: "Mesalamine",   dose: "800mg",   time: "8:00pm",  taken: false),
    ]

    var body: some View {
        FormCard(title: "Today's schedule", label: "\(meds.count) DOSES") {
            VStack(spacing: 0) {
                ForEach(Array(meds.enumerated()), id: \.element.id) { idx, med in
                    HStack(spacing: 12) {
                        Button {
                            meds[idx].taken.toggle()
                            let verb = meds[idx].taken ? "taken" : "marked missed"
                            if meds[idx].taken {
                                appState.recordMedicationTaken(name: med.name)
                            }
                            appState.showToast("\(med.name) · \(verb)")
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(meds[idx].taken ? Color.sage : Color.clear)
                                    .frame(width: 26, height: 26)
                                    .overlay(
                                        Circle().stroke(meds[idx].taken ? Color.clear : Color.fgFaint, lineWidth: 1.5)
                                    )
                                if meds[idx].taken {
                                    AppIcon(name: "check", size: 13, color: .darkText)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .animation(.easeInOut(duration: 0.15), value: meds[idx].taken)

                        HStack(spacing: 0) {
                            Text(med.name)
                                .font(DS.sans(14))
                                .foregroundColor(meds[idx].taken ? .fgDim : .fgPrimary)
                                .tracking(-0.1)
                            Text(" · \(med.dose)")
                                .font(DS.sans(12))
                                .foregroundColor(.fgFaint)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text(med.time)
                            .font(DS.mono(11))
                            .foregroundColor(.fgFaint)
                    }
                    .padding(.vertical, 12)
                    .overlay(alignment: .bottom) {
                        if idx < meds.count - 1 {
                            Rectangle().fill(Color.strokeDefault).frame(height: 0.5)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Sleep form

struct LogSleepForm: View {
    var appState: AppState
    @State private var quality = 7.0
    @State private var wake = 1

    var body: some View {
        FormCard(title: "Bedtime → Wake", label: "LAST NIGHT") {
            HStack(spacing: 10) {
                TimeInputBox(label: "Bed",  value: "11:20p")
                TimeInputBox(label: "Wake", value: "6:40a")
            }
            HStack(spacing: 8) {
                AppIcon(name: "moon", size: 15, color: .amber)
                Text("7h 20m")
                    .font(DS.mono(14))
                    .foregroundColor(.fgPrimary)
                Spacer()
                Text("in bed")
                    .font(DS.sans(12))
                    .foregroundColor(.fgDim)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.bgInset)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }

        FormCard(title: "Sleep quality", label: "\(Int(quality))/10") {
            Slider(value: $quality, in: 0...10, step: 1).tint(.amber)
        }

        FormCard(title: "Bathroom trips", label: "\(wake) NIGHTTIME WAKES") {
            HStack(spacing: 6) {
                ForEach([0,1,2,3], id: \.self) { n in
                    LogPill(title: "\(n)", isActive: wake == n) { wake = n }
                        .frame(maxWidth: .infinity)
                }
                LogPill(title: "4+", isActive: wake == 4) { wake = 4 }
                    .frame(maxWidth: .infinity)
            }
        }

        PrimaryButton(title: "Save entry") {
            appState.addLog(type: .sleep, title: "Sleep quality \(Int(quality))/10", sub: "\(wake) bathroom wakes")
            appState.showToast("Sleep logged")
        }
    }
}

// MARK: - Weight form

struct LogWeightForm: View {
    var appState: AppState
    @State private var weight = "62.4"

    var body: some View {
        FormCard(title: "Current weight", label: "KG") {
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                TextField("0.0", text: $weight)
                    .font(DS.serif(64))
                    .foregroundColor(.fgPrimary)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.decimalPad)
                    .frame(maxWidth: .infinity)
                Text("kg")
                    .font(DS.mono(18))
                    .foregroundColor(.fgFaint)
            }
            .padding(.vertical, 18)

            HStack(spacing: 4) {
                Text("↑ 0.4 kg")
                    .font(DS.sans(13))
                    .foregroundColor(.sage)
                Text("since last week")
                    .font(DS.sans(13))
                    .foregroundColor(.fgDim)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 2)

            PrimaryButton(title: "Save entry") {
                appState.addLog(type: .weight, title: "Weight · \(weight) kg", sub: "Manual entry")
                appState.showToast("Weight · \(weight) kg")
            }
            .padding(.top, 14)
        }
    }
}

// MARK: - Note form

struct LogNoteForm: View {
    var appState: AppState
    @State private var note = ""

    var body: some View {
        FormCard(title: "Note", label: "PRIVATE") {
            TextField("What changed or what should your doctor know?", text: $note, axis: .vertical)
                .lineLimit(5...8)
                .font(DS.sans(15))
                .foregroundColor(.fgPrimary)
                .padding(12)
                .background(Color.bgInset)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Text("Notes stay in your log. Do not use notes for urgent care needs.")
                .font(DS.sans(12))
                .foregroundColor(.fgDim)
        }

        PrimaryButton(title: "Save note") {
            let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                appState.showToast("Add a note first")
                return
            }
            appState.addLog(type: .note, title: trimmed, sub: "Manual note")
            appState.showToast("Note saved")
            note = ""
        }
    }
}

// MARK: - Voice form

struct LogVoiceForm: View {
    var appState: AppState
    @State private var transcript = ""
    @State private var draft: VoiceLogDraft? = nil

    var body: some View {
        FormCard(title: "Voice transcript", label: "SCAFFOLD") {
            Text("Microphone and Speech permissions still need Apple setup. Paste or type a transcript here to test parsing.")
                .font(DS.sans(12))
                .foregroundColor(.fgDim)
                .lineSpacing(2)

            TextField("Example: I had three bowel movements, Bristol six, no blood.", text: $transcript, axis: .vertical)
                .lineLimit(4...8)
                .font(DS.sans(15))
                .foregroundColor(.fgPrimary)
                .padding(12)
                .background(Color.bgInset)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            GhostButton(title: "Parse transcript") {
                let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    appState.showToast("Add a transcript first")
                    return
                }
                draft = VoiceLogParser.parse(trimmed)
            }
        }

        if let draft {
            VoiceDraftConfirmation(draft: draft) {
                appState.recordVoiceDraft(draft)
                transcript = ""
                self.draft = nil
            } discard: {
                self.draft = nil
            }
        }
    }
}

struct VoiceDraftConfirmation: View {
    let draft: VoiceLogDraft
    let save: () -> Void
    let discard: () -> Void

    var body: some View {
        FormCard(title: "Confirm before saving", label: draft.confidence.rawValue.uppercased()) {
            HStack(spacing: 10) {
                IconBadge(name: "mic", size: 34, iconSize: 15, color: .sage)
                VStack(alignment: .leading, spacing: 2) {
                    Text(draft.type.rawValue.capitalized)
                        .font(DS.sans(15, weight: .medium))
                        .foregroundColor(.fgPrimary)
                    Text("Voice-derived health data is never auto-saved.")
                        .font(DS.sans(12))
                        .foregroundColor(.fgDim)
                }
            }

            if !draft.fields.isEmpty {
                VStack(spacing: 0) {
                    ForEach(draft.fields.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        HStack {
                            Text(key.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(DS.sans(13))
                                .foregroundColor(.fgDim)
                            Spacer()
                            Text(value)
                                .font(DS.mono(12))
                                .foregroundColor(.fgPrimary)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 12)
                .background(Color.bgInset)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if !draft.safetyFlags.isEmpty {
                Text("Safety flags detected. Review this entry and seek medical help if symptoms feel serious or rapidly worsening.")
                    .font(DS.sans(12))
                    .foregroundColor(.clay)
                    .lineSpacing(2)
            }

            PrimaryButton(title: "Save confirmed log", action: save)
            GhostButton(title: "Discard draft", action: discard)
        }
    }
}

// MARK: - Helpers

struct TimeInputBox: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).dsLabel()
            Text(value)
                .font(DS.mono(18))
                .foregroundColor(.fgPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.bgInset)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// Simple flow layout for wrapping pills
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, place) in result.placements.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + place.x, y: bounds.minY + place.y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var placements: [(x: CGFloat, y: CGFloat)] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            var totalHeight: CGFloat = 0
            var maxX: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth && x > 0 {
                    y += rowHeight + spacing
                    x = 0
                    rowHeight = 0
                }
                placements.append((x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                maxX = max(maxX, x)
            }
            totalHeight = y + rowHeight
            self.size = CGSize(width: maxX, height: totalHeight)
        }
    }
}

#Preview {
    LogView(appState: AppState())
        .background(Color.bgPrimary)
        .preferredColorScheme(.dark)
}
