import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var editingName = false
    @State private var displayName = ""
    @State private var savingName = false
    @State private var tracksMenstrual = false
    @State private var medReminders = false
    @State private var dailyReminder = false
    @State private var showSignOutAlert = false
    @State private var exportLoading = false
    @State private var showExportSheet = false
    @State private var exportText = ""

    private let db = AppDatabase.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    profileHeader
                        .padding(.bottom, 24)

                    VStack(spacing: 24) {
                        accountSection
                        trackingSection
                        notificationsSection
                        dataSection
                        accountSettingsSection

                        Button(role: .destructive) {
                            showSignOutAlert = true
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                .font(.subheadline).fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .foregroundStyle(.white)
                                .background(Color.brandDanger)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)

                        Text("Inflamend v1.0.0")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.bottom, 8)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear { syncState() }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                Task { await auth.signOut() }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .sheet(isPresented: $showExportSheet) {
            ActivityView(text: exportText)
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        ZStack(alignment: .bottom) {
            AppGradient.brand
                .frame(height: 160)
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 10) {
                if let name = auth.profile?.display_name, !name.isEmpty {
                    UserAvatarView(name: name, size: 80)
                        .overlay(Circle().strokeBorder(.white, lineWidth: 3))
                } else {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.2)).frame(width: 80, height: 80)
                        Image(systemName: "person.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.white)
                    }
                }
                VStack(spacing: 4) {
                    Text(auth.profile?.display_name ?? "Add your name")
                        .font(.title3).fontWeight(.bold)
                        .foregroundStyle(.white)
                    if let diagnosis = auth.profile?.diagnosis_type {
                        Text(diagnosis.label)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            }
            .padding(.bottom, 20)
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        sectionBlock("Account") {
            if editingName {
                HStack(spacing: 8) {
                    TextField("Your name", text: $displayName)
                        .padding(10)
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Button("Save") { Task { await saveName() } }
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(AppGradient.brand)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .disabled(savingName)

                    Button("Cancel") {
                        displayName = auth.profile?.display_name ?? ""
                        editingName = false
                    }
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            } else {
                SettingsRow(icon: "person.fill", label: "Display Name",
                            subtitle: auth.profile?.display_name ?? "Not set",
                            color: .brandPrimary) {
                    editingName = true
                }
            }

            if let dx = auth.profile?.diagnosis_type {
                Divider().padding(.leading, 58)
                SettingsRow(icon: "cross.case.fill", label: "Diagnosis",
                            subtitle: dx.label, color: .brandSecondary)
            }
        }
    }

    // MARK: - Tracking Preferences

    private var trackingSection: some View {
        sectionBlock("Tracking") {
            HStack {
                IconBadge(systemName: "figure.stand", color: .brandSecondary, size: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Menstrual Cycle").font(.subheadline)
                    Text("Track cycle alongside IBD").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: $tracksMenstrual)
                    .tint(.brandPrimary)
                    .onChange(of: tracksMenstrual) { _, v in Task { await saveTracksMenstrual(v) } }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
        }
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        sectionBlock("Notifications") {
            HStack {
                IconBadge(systemName: "pills.fill", color: .brandWarning, size: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Medication Reminders").font(.subheadline)
                    Text("Get reminded to take medications").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: $medReminders)
                    .tint(.brandPrimary)
                    .onChange(of: medReminders) { _, v in UserDefaults.standard.set(v, forKey: "notif_med") }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)

            Divider().padding(.leading, 58)

            HStack {
                IconBadge(systemName: "bell.fill", color: .brandPrimary, size: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Log Reminder").font(.subheadline)
                    Text("Reminder to log your symptoms daily").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Toggle("", isOn: $dailyReminder)
                    .tint(.brandPrimary)
                    .onChange(of: dailyReminder) { _, v in UserDefaults.standard.set(v, forKey: "notif_daily") }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
        }
    }

    // MARK: - Data Section

    private var dataSection: some View {
        sectionBlock("Data") {
            Button {
                Task { await exportReport() }
            } label: {
                HStack(spacing: 14) {
                    IconBadge(systemName: "doc.richtext.fill", color: .brandSuccess, size: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Export Report").font(.subheadline)
                        Text("30-day summary for your doctor").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if exportLoading {
                        ProgressView().scaleEffect(0.8)
                    } else {
                        Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.quaternary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
            }
            .buttonStyle(.plain)
            .disabled(exportLoading)
        }
    }

    // MARK: - Account Settings

    private var accountSettingsSection: some View {
        sectionBlock("Account Settings") {
            SettingsRow(icon: "lock.fill", label: "Change Password",
                        subtitle: "Use the forgot password flow", color: .brandWarning)
            Divider().padding(.leading, 58)
            SettingsRow(icon: "hand.raised.fill", label: "Privacy Policy", color: Color(.systemGray))
            Divider().padding(.leading, 58)
            SettingsRow(icon: "doc.text.fill", label: "Terms of Service", color: Color(.systemGray))
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func sectionBlock(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption).fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                content()
            }
            .cardStyle(cornerRadius: 14)
            .padding(.horizontal, 20)
        }
    }

    private func syncState() {
        displayName = auth.profile?.display_name ?? ""
        tracksMenstrual = auth.profile?.tracks_menstrual_cycle ?? false
        medReminders = UserDefaults.standard.bool(forKey: "notif_med")
        dailyReminder = UserDefaults.standard.bool(forKey: "notif_daily")
    }

    private func saveName() async {
        guard let uid = db.userId else { return }
        savingName = true
        struct Payload: Encodable { let display_name: String; let updated_at: String }
        if (try? await db.update("profiles", filter: "id=eq.\(uid)",
                                  data: Payload(display_name: displayName.trimmingCharacters(in: .whitespaces),
                                                updated_at: ISO8601DateFormatter().string(from: Date())))) != nil {
            if var p = auth.profile {
                p.display_name = displayName.trimmingCharacters(in: .whitespaces)
                auth.updateProfile(p)
            }
        }
        savingName = false
        editingName = false
    }

    private func saveTracksMenstrual(_ value: Bool) async {
        guard let uid = db.userId else { return }
        struct Payload: Encodable { let tracks_menstrual_cycle: Bool; let updated_at: String }
        _ = try? await db.update("profiles", filter: "id=eq.\(uid)",
                                  data: Payload(tracks_menstrual_cycle: value,
                                                updated_at: ISO8601DateFormatter().string(from: Date())))
        if var p = auth.profile { p.tracks_menstrual_cycle = value; auth.updateProfile(p) }
    }

    private func exportReport() async {
        guard let uid = db.userId, let profile = auth.profile else { return }
        exportLoading = true

        let fmt = ISO8601DateFormatter()
        let to = Date()
        let from = Calendar.current.date(byAdding: .day, value: -29, to: to)!
        let fromStr = fmt.string(from: from)
        let toStr = fmt.string(from: to)

        async let symptomsRes: [SymptomLog] = (try? db.select("symptom_logs",
            filter: "user_id=eq.\(uid)&logged_at=gte.\(fromStr)&logged_at=lte.\(toStr)")) ?? []
        async let bowelsRes: [BowelLog] = (try? db.select("bowel_logs",
            filter: "user_id=eq.\(uid)&logged_at=gte.\(fromStr)&logged_at=lte.\(toStr)")) ?? []
        async let foodsRes: [FoodLog] = (try? db.select("food_logs",
            filter: "user_id=eq.\(uid)&logged_at=gte.\(fromStr)&logged_at=lte.\(toStr)")) ?? []
        async let medsRes: [MedicationLog] = (try? db.select("medication_logs",
            filter: "user_id=eq.\(uid)&created_at=gte.\(fromStr)&created_at=lte.\(toStr)")) ?? []

        let (symptoms, bowels, foods, meds) = await (symptomsRes, bowelsRes, foodsRes, medsRes)

        let df = DateFormatter(); df.dateStyle = .medium
        let avgPain = symptoms.isEmpty ? "N/A" : String(format: "%.1f",
            Double(symptoms.reduce(0) { $0 + $1.pain_level }) / Double(symptoms.count))
        let flareDays = symptoms.filter { $0.is_flare }.count
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
Entries: \(symptoms.count)
Average Pain: \(avgPain)/10
Flare Days: \(flareDays)

BOWEL HEALTH
Total Movements: \(bowels.count)
With Blood: \(bowels.filter { $0.blood_present }.count)

NUTRITION
Food Entries: \(foods.count)
Trigger Foods: \(foods.filter { $0.is_trigger_food }.count)

MEDICATIONS
Doses Logged: \(meds.count)
Doses Taken: \(medsTaken)
Adherence: \(adherence)%

---
Generated by Inflamend. Not a substitute for medical advice.
"""
        exportLoading = false
        showExportSheet = true
    }
}

// MARK: - Activity View (Share Sheet)

struct ActivityView: UIViewControllerRepresentable {
    let text: String
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
