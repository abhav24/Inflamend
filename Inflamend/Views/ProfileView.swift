import SwiftUI

struct ProfileView: View {
    var appState: AppState

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Header
                ScreenHeader(subtitle: "YOUR ACCOUNT", title: "Hello, ", titleItalicSuffix: appState.firstName)
                    .appearAnimation(delay: 0)

                // Profile card
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.sage, .amber], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 60, height: 60)
                        Text(String(appState.firstName.prefix(1)).uppercased())
                            .font(DS.serif(28))
                            .foregroundColor(.darkText)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(appState.displayName)
                            .font(DS.sans(18))
                            .foregroundColor(.fgPrimary)
                            .tracking(-0.15)
                        Text(appState.diagnosisLabel)
                            .font(DS.sans(13))
                            .foregroundColor(.fgDim)
                    }
                    Spacer()
                    Button { appState.showToast("Profile editing scaffolded") } label: {
                        Text("Edit")
                            .font(DS.sans(13, weight: .medium))
                            .foregroundColor(.fgPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.bgInset)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PressableButtonStyle())
                }
                .card()
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
                .appearAnimation(delay: 0.07)

                // Stats row
                HStack {
                    ProfileStat(value: "\(appState.logs.count)", label: "Logs saved")
                    Rectangle().fill(Color.strokeDefault).frame(width: 0.5).padding(.vertical, 4)
                    ProfileStat(value: "\(appState.riskScore)",  label: "Risk score")
                    Rectangle().fill(Color.strokeDefault).frame(width: 0.5).padding(.vertical, 4)
                    ProfileStat(value: "\(appState.medsTaken)/\(appState.medsTotal)", label: "Meds")
                }
                .padding(18)
                .background(Color.bgCard)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.strokeDefault, lineWidth: 0.5))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
                .appearAnimation(delay: 0.14)

                // Health section
                SectionLabel("HEALTH")
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)

                VStack(spacing: 0) {
                    ProfileRow(icon: "download", label: "Export 30-day report", sub: "Plain text scaffold") {
                        let report = ReportSummaryGenerator.plainText(
                            ReportSummaryInput(
                                daysLogged: 7,
                                bowelMovementCount: appState.logs.filter { $0.type == .bowel }.count,
                                bloodEventCount: 0,
                                medicationDosesTaken: appState.medsTaken,
                                medicationDosesScheduled: appState.medsTotal,
                                possiblePatterns: ["Keep logging to improve confidence"],
                                notes: ["Export requested from Profile"]
                            )
                        )
                        appState.addLog(type: .note, title: "Doctor report prepared", sub: "\(report.count) characters")
                        appState.showToast("Report scaffold prepared")
                    }
                    ProfileRow(icon: "bell", label: "Medication reminders", sub: "Requires notification setup") {
                        appState.showToast("Notification setup required")
                    }
                    ProfileRow(icon: "calendar", label: "Flare history", sub: "Scaffolded") {
                        appState.showToast("Flare history scaffolded")
                    }
                    ProfileRow(icon: "heart", label: "Care plan", sub: "Questions for your GI", isLast: true) {
                        appState.showToast("Care plan scaffolded")
                    }
                }
                .background(Color.bgCard)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.strokeDefault, lineWidth: 0.5))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
                .appearAnimation(delay: 0.21)

                // App section
                SectionLabel("APP")
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)

                VStack(spacing: 0) {
                    ProfileRow(icon: "settings", label: "Preferences", sub: "Units, timezone, reminders") {
                        appState.showToast("Preferences scaffolded")
                    }
                    ProfileRow(icon: "book", label: "IBD library", sub: "Guided articles") {
                        appState.showToast("Education library scaffolded")
                    }
                    ProfileRow(icon: "logout",   label: "Sign out",     isDanger: true, isLast: true) {
                        appState.signOut()
                    }
                }
                .background(Color.bgCard)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.strokeDefault, lineWidth: 0.5))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .appearAnimation(delay: 0.28)

                SectionLabel("PRIVACY")
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)

                VStack(spacing: 0) {
                    ProfileRow(icon: "cloud", label: "Sync status", sub: appState.syncSummary) {
                        appState.retryPendingSyncScaffold()
                    }
                    ProfileRow(
                        icon: "sparkle",
                        label: "AI memory",
                        sub: appState.aiMemoryEnabled ? "On · saved only with consent" : "Off"
                    ) {
                        appState.setAIMemoryEnabled(!appState.aiMemoryEnabled)
                    }
                    ProfileRow(
                        icon: "mic",
                        label: "Voice transcript storage",
                        sub: appState.voiceTranscriptStorageEnabled ? "On · transcripts may be stored" : "Off · drafts only"
                    ) {
                        appState.setVoiceTranscriptStorageEnabled(!appState.voiceTranscriptStorageEnabled)
                    }
                    ProfileRow(icon: "download", label: "Export my data", sub: "Requires backend credentials") {
                        appState.requestDataExportScaffold()
                    }
                    ProfileRow(icon: "close", label: "Delete AI history", sub: "\(appState.chatMessages.count) messages", isDanger: true) {
                        appState.clearAIHistory()
                    }
                    ProfileRow(icon: "close", label: "Delete data/account", sub: "Requires signed-in backend account", isDanger: true, isLast: true) {
                        appState.requestAccountDeletionScaffold()
                    }
                }
                .background(Color.bgCard)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.strokeDefault, lineWidth: 0.5))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .appearAnimation(delay: 0.35)

                Text("INFLAMEND v1.0 · BUILD 1")
                    .font(DS.mono(11))
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundColor(.fgFaint)
                    .padding(.bottom, 20)
            }
        }
        .background(Color.bgPrimary)
    }
}

// MARK: - Profile Stat

struct ProfileStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(DS.serif(30))
                .foregroundColor(.fgPrimary)
            Text(label).dsLabel()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Section Label

struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text).dsLabel().padding(.horizontal, 4)
    }
}

// MARK: - Profile Row

struct ProfileRow: View {
    let icon: String
    let label: String
    var sub: String? = nil
    var isDanger: Bool = false
    var isLast: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isDanger ? Color.clayDim : Color.bgInset)
                        .frame(width: 32, height: 32)
                    AppIcon(name: icon, size: 15, color: isDanger ? .clay : .fgDim)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(DS.sans(14))
                        .foregroundColor(isDanger ? .clay : .fgPrimary)
                        .tracking(-0.1)
                    if let s = sub {
                        Text(s)
                            .font(DS.sans(12))
                            .foregroundColor(.fgFaint)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !isDanger {
                    AppIcon(name: "chevron", size: 14, color: .fgFaint)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .overlay(alignment: .bottom) {
                if !isLast {
                    Rectangle().fill(Color.strokeDefault).frame(height: 0.5).padding(.leading, 60)
                }
            }
        }
        .buttonStyle(PressableButtonStyle(scale: 0.97))
        .disabled(action == nil)
    }
}

#Preview {
    ProfileView(appState: AppState())
        .background(Color.bgPrimary)
        .preferredColorScheme(.dark)
}
