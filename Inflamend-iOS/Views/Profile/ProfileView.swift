import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var showEditProfile = false
    @State private var tracksMenstrual = false
    @State private var medReminders = false
    @State private var dailyReminder = false
    @State private var showSignOutAlert = false
    @State private var exportLoading = false
    @State private var showExportSheet = false
    @State private var exportText = ""
    @State private var animateCards = false

    // Stats
    @State private var totalLogs = 0
    @State private var flareDays = 0
    @State private var medAdherence = "—"

    private let db = AppDatabase.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    profileHeader.padding(.bottom, 24)

                    VStack(spacing: 0) {
                        statsStrip.padding(.horizontal, 20).padding(.bottom, 28)
                    }
                    .opacity(animateCards ? 1 : 0)
                    .offset(y: animateCards ? 0 : 16)

                    VStack(spacing: 24) {
                        accountSection
                        trackingSection
                        notificationsSection
                        dataSection
                        accountSettingsSection

                        Button(role: .destructive) { showSignOutAlert = true } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                .font(.subheadline).fontWeight(.semibold)
                                .frame(maxWidth: .infinity).padding(.vertical, 16)
                                .foregroundStyle(.white).background(Color.brandDanger)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)

                        Text("Inflamend v1.0.0")
                            .font(.caption2).foregroundStyle(.quaternary)
                            .padding(.bottom, 8)
                    }
                    .opacity(animateCards ? 1 : 0)
                    .offset(y: animateCards ? 0 : 16)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            syncState()
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.05)) { animateCards = true }
            Task { await loadStats() }
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) { Task { await auth.signOut() } }
        } message: { Text("Are you sure you want to sign out?") }
        .sheet(isPresented: $showEditProfile) { EditProfileSheet().environmentObject(auth) }
        .sheet(isPresented: $showExportSheet) { ActivityView(text: exportText) }
    }

    // MARK: - Profile Header (§3.6)

    private var profileHeader: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                if let name = auth.profile?.display_name, !name.isEmpty {
                    UserAvatarView(name: name, size: 88)
                } else {
                    ZStack {
                        Circle().fill(Color.brandPrimary.opacity(0.15)).frame(width: 88, height: 88)
                        Image(systemName: "person.fill")
                            .font(.system(size: 40)).foregroundStyle(.brandPrimary)
                    }
                }
                Button { showEditProfile = true } label: {
                    ZStack {
                        Circle().fill(Color(.systemBackground)).frame(width: 28, height: 28)
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 26)).foregroundStyle(.brandPrimary)
                    }
                }
                .offset(x: 2, y: 2)
            }

            VStack(spacing: 6) {
                Text(auth.profile?.display_name ?? "Add your name")
                    .font(.title3).fontWeight(.bold)
                if let dx = auth.profile?.diagnosis_type {
                    Text(dx.label)
                        .font(.caption2).fontWeight(.semibold)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color.brandPrimary.opacity(0.1))
                        .foregroundStyle(.brandPrimary)
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Stats Strip (§3.2)

    private var statsStrip: some View {
        HStack(spacing: 0) {
            StatCell(label: "Logs (30d)", value: "\(totalLogs)")
            Divider().frame(height: 36)
            StatCell(label: "Flare Days", value: "\(flareDays)")
            Divider().frame(height: 36)
            StatCell(label: "Med Adherence", value: medAdherence)
        }
        .padding(.vertical, 14)
        .cardStyle()
    }

    // MARK: - Settings Sections

    private var accountSection: some View {
        sectionBlock("Account") {
            SettingsRow(icon: "person.fill", label: "Edit Profile",
                        subtitle: auth.profile?.display_name ?? "Not set",
                        color: .brandPrimary) { showEditProfile = true }
            if let dx = auth.profile?.diagnosis_type {
                Divider().padding(.leading, 58)
                SettingsRow(icon: "cross.case.fill", label: "Diagnosis",
                            subtitle: dx.label, color: .brandSecondary)
            }
        }
    }

    private var trackingSection: some View {
        sectionBlock("Tracking") {
            HStack {
                IconBadge(systemName: "figure.stand", color: .brandSecondary, size: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Menstrual Cycle").font(.subheadline)
                    Text("Track cycle alongside IBD").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: $tracksMenstrual).tint(.brandPrimary)
                    .onChange(of: tracksMenstrual) { _, v in Task { await saveTracksMenstrual(v) } }
            }
            .padding(.horizontal, 16).padding(.vertical, 13)
        }
    }

    private var notificationsSection: some View {
        sectionBlock("Notifications") {
            HStack {
                IconBadge(systemName: "pills.fill", color: .brandWarning, size: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Medication Reminders").font(.subheadline)
                    Text("Get reminded to take medications").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: $medReminders).tint(.brandPrimary)
                    .onChange(of: medReminders) { _, v in UserDefaults.standard.set(v, forKey: "notif_med") }
            }
            .padding(.horizontal, 16).padding(.vertical, 13)

            Divider().padding(.leading, 58)

            HStack {
                IconBadge(systemName: "bell.fill", color: .brandPrimary, size: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Log Reminder").font(.subheadline)
                    Text("Reminder to log each day").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: $dailyReminder).tint(.brandPrimary)
                    .onChange(of: dailyReminder) { _, v in UserDefaults.standard.set(v, forKey: "notif_daily") }
            }
            .padding(.horizontal, 16).padding(.vertical, 13)
        }
    }

    private var dataSection: some View {
        sectionBlock("Data") {
            Button { Task { await exportReport() } } label: {
                HStack(spacing: 14) {
                    IconBadge(systemName: "doc.richtext.fill", color: .brandSuccess, size: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Export Report").font(.subheadline)
                        Text("30-day summary for your doctor").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if exportLoading { ProgressView().scaleEffect(0.8) }
                    else { Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.quaternary) }
                }
                .padding(.horizontal, 16).padding(.vertical, 13)
            }
            .buttonStyle(.plain).disabled(exportLoading)
        }
    }

    private var accountSettingsSection: some View {
        sectionBlock("Account Settings") {
            SettingsRow(icon: "lock.fill",     label: "Change Password", subtitle: "Use the forgot password flow", color: .brandWarning)
            Divider().padding(.leading, 58)
            SettingsRow(icon: "hand.raised.fill", label: "Privacy Policy", color: Color(.systemGray))
            Divider().padding(.leading, 58)
            SettingsRow(icon: "doc.text.fill",    label: "Terms of Service", color: Color(.systemGray))
        }
    }

    @ViewBuilder
    private func sectionBlock(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption).fontWeight(.semibold)
                .foregroundStyle(.secondary).textCase(.uppercase).tracking(0.5)
                .padding(.horizontal, 20)
            VStack(spacing: 0) { content() }
                .cardStyle(cornerRadius: 14).padding(.horizontal, 20)
        }
    }

    // MARK: - Data / Actions

    private func syncState() {
        tracksMenstrual = auth.profile?.tracks_menstrual_cycle ?? false
        medReminders = UserDefaults.standard.bool(forKey: "notif_med")
        dailyReminder = UserDefaults.standard.bool(forKey: "notif_daily")
    }

    private func loadStats() async {
        guard let uid = db.userId else { return }
        let fmt = ISO8601DateFormatter()
        let from = fmt.string(from: Calendar.current.date(byAdding: .day, value: -29, to: Date())!)
        async let symptoms: [SymptomLog]    = (try? db.select("symptom_logs",    filter: "user_id=eq.\(uid)&logged_at=gte.\(from)")) ?? []
        async let bowels: [BowelLog]        = (try? db.select("bowel_logs",      filter: "user_id=eq.\(uid)&logged_at=gte.\(from)")) ?? []
        async let foods: [FoodLog]          = (try? db.select("food_logs",       filter: "user_id=eq.\(uid)&logged_at=gte.\(from)")) ?? []
        async let meds: [MedicationLog]     = (try? db.select("medication_logs", filter: "user_id=eq.\(uid)&created_at=gte.\(from)")) ?? []
        let (s, b, f, m) = await (symptoms, bowels, foods, meds)
        totalLogs = s.count + b.count + f.count + m.count
        flareDays = s.filter { $0.is_flare }.count
        if !m.isEmpty {
            let pct = Int(Double(m.filter { $0.was_taken }.count) / Double(m.count) * 100)
            medAdherence = "\(pct)%"
        }
    }

    private func saveTracksMenstrual(_ value: Bool) async {
        guard let uid = db.userId else { return }
        struct Payload: Encodable { let tracks_menstrual_cycle: Bool; let updated_at: String }
        _ = try? await db.update("profiles", filter: "id=eq.\(uid)",
            data: Payload(tracks_menstrual_cycle: value, updated_at: ISO8601DateFormatter().string(from: Date())))
        if var p = auth.profile { p.tracks_menstrual_cycle = value; auth.updateProfile(p) }
    }

    private func exportReport() async {
        guard let uid = db.userId, let profile = auth.profile else { return }
        exportLoading = true
        let fmt = ISO8601DateFormatter(); let df = DateFormatter(); df.dateStyle = .medium
        let to = Date(); let from = Calendar.current.date(byAdding: .day, value: -29, to: to)!
        let fromStr = fmt.string(from: from); let toStr = fmt.string(from: to)
        async let s: [SymptomLog]    = (try? db.select("symptom_logs",    filter: "user_id=eq.\(uid)&logged_at=gte.\(fromStr)&logged_at=lte.\(toStr)")) ?? []
        async let b: [BowelLog]      = (try? db.select("bowel_logs",      filter: "user_id=eq.\(uid)&logged_at=gte.\(fromStr)&logged_at=lte.\(toStr)")) ?? []
        async let f: [FoodLog]       = (try? db.select("food_logs",       filter: "user_id=eq.\(uid)&logged_at=gte.\(fromStr)&logged_at=lte.\(toStr)")) ?? []
        async let m: [MedicationLog] = (try? db.select("medication_logs", filter: "user_id=eq.\(uid)&created_at=gte.\(fromStr)&created_at=lte.\(toStr)")) ?? []
        let (symptoms, bowels, foods, meds) = await (s, b, f, m)
        let avgPain = symptoms.isEmpty ? "N/A" : String(format: "%.1f", Double(symptoms.reduce(0) { $0 + $1.pain_level }) / Double(symptoms.count))
        let medsTaken = meds.filter { $0.was_taken }.count
        let adherence = meds.isEmpty ? 0 : Int(Double(medsTaken) / Double(meds.count) * 100)
        exportText = """
INFLAMEND HEALTH REPORT
Generated: \(df.string(from: Date()))
Period: \(df.string(from: from)) – \(df.string(from: to))

PATIENT
Name: \(profile.display_name ?? "Not set")
Diagnosis: \(profile.diagnosis_type?.label ?? "Not set")

SYMPTOMS (Last 30 Days)
Entries: \(symptoms.count) | Average Pain: \(avgPain)/10 | Flare Days: \(symptoms.filter { $0.is_flare }.count)

BOWEL HEALTH
Total Movements: \(bowels.count) | With Blood: \(bowels.filter { $0.blood_present }.count)

NUTRITION
Food Entries: \(foods.count) | Trigger Foods: \(foods.filter { $0.is_trigger_food }.count)

MEDICATIONS
Doses Logged: \(meds.count) | Taken: \(medsTaken) | Adherence: \(adherence)%

---
Generated by Inflamend. Not a substitute for medical advice.
"""
        exportLoading = false; showExportSheet = true
    }
}

// MARK: - Edit Profile Sheet

struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var auth: AuthViewModel
    @State private var name = ""
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let name = auth.profile?.display_name, !name.isEmpty {
                        UserAvatarView(name: name, size: 72).padding(.top, 24)
                    }

                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            FieldLabel(text: "Display Name")
                            TextField("Your name", text: $name)
                                .padding(14)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .onChange(of: name) { _, v in if v.count > 50 { name = String(v.prefix(50)) } }
                        }
                        if let error { Text(error).font(.footnote).foregroundStyle(.brandDanger) }
                        PrimaryButton("Save Changes", isLoading: loading) { Task { await save() } }
                    }
                }
                .padding(.horizontal, 24)
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
        .onAppear { name = auth.profile?.display_name ?? "" }
    }

    private func save() async {
        let trimmed = InputValidator.sanitize(name, maxLength: 50)
        guard InputValidator.isValidName(trimmed) else { error = "Name must be 2–50 characters"; return }
        guard let uid = AppDatabase.shared.userId else { return }
        loading = true; error = nil
        struct Payload: Encodable { let display_name: String; let updated_at: String }
        do {
            try await AppDatabase.shared.update("profiles", filter: "id=eq.\(uid)",
                data: Payload(display_name: trimmed, updated_at: ISO8601DateFormatter().string(from: Date())))
            if var p = auth.profile { p.display_name = trimmed; auth.updateProfile(p) }
            dismiss()
        } catch { self.error = error.localizedDescription }
        loading = false
    }
}

// MARK: - Activity View

struct ActivityView: UIViewControllerRepresentable {
    let text: String
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
