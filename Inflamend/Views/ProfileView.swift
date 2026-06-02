import SwiftUI

struct ProfileView: View {
    var appState: AppState
    @State private var preparedExport: ProfilePreparedExport?
    @State private var pendingConfirmation: ProfileConfirmation?

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
                    ProfileRow(icon: "download", label: "Export doctor report", sub: "Shareable text file") {
                        do {
                            preparedExport = .doctorReport(try appState.prepareDoctorReportExport())
                        } catch {
                            appState.showToast("Report export failed")
                        }
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
                    ProfileRow(icon: "download", label: "Export my data", sub: "Local JSON file", accessibilityID: "profile-export-data-row") {
                        do {
                            preparedExport = .userData(try appState.prepareUserDataExport())
                        } catch {
                            appState.showToast("Data export failed")
                        }
                    }
                    ProfileRow(
                        icon: "close",
                        label: "Delete AI history",
                        sub: "\(appState.chatMessages.count) messages",
                        isDanger: true,
                        accessibilityID: "profile-delete-ai-history-row"
                    ) {
                        pendingConfirmation = .clearAIHistory
                    }
                    ProfileRow(
                        icon: "close",
                        label: "Delete data/account",
                        sub: "Requires signed-in backend account",
                        isDanger: true,
                        isLast: true,
                        accessibilityID: "profile-delete-data-account-row"
                    ) {
                        pendingConfirmation = .deleteDataAccount
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
        .sheet(item: $preparedExport) { export in
            switch export {
            case .doctorReport(let report):
                DoctorReportExportSheet(export: report)
            case .userData(let userData):
                UserDataExportSheet(export: userData)
            }
        }
        .confirmationDialog(
            pendingConfirmation?.title ?? "",
            isPresented: Binding(
                get: { pendingConfirmation != nil },
                set: { if !$0 { pendingConfirmation = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let pendingConfirmation {
                Button(pendingConfirmation.confirmationTitle, role: .destructive) {
                    perform(pendingConfirmation)
                    self.pendingConfirmation = nil
                }
                .accessibilityIdentifier(pendingConfirmation.confirmationAccessibilityID)
            }
            Button("Cancel", role: .cancel) {
                pendingConfirmation = nil
            }
        } message: {
            Text(pendingConfirmation?.message ?? "")
        }
    }

    private func perform(_ confirmation: ProfileConfirmation) {
        switch confirmation {
        case .clearAIHistory:
            appState.clearAIHistory()
        case .deleteDataAccount:
            appState.requestAccountDeletionScaffold()
        }
    }
}

private enum ProfilePreparedExport: Identifiable {
    case doctorReport(DoctorReportExport)
    case userData(UserDataExport)

    var id: UUID {
        switch self {
        case .doctorReport(let export):
            return export.id
        case .userData(let export):
            return export.id
        }
    }
}

private enum ProfileConfirmation {
    case clearAIHistory
    case deleteDataAccount

    var title: String {
        switch self {
        case .clearAIHistory:
            return "Delete AI history?"
        case .deleteDataAccount:
            return "Request data/account deletion?"
        }
    }

    var message: String {
        switch self {
        case .clearAIHistory:
            return "This clears saved Care messages on this device. Cloud deletion still requires backend setup."
        case .deleteDataAccount:
            return "This records a deletion request locally. Final account and cloud data deletion requires production backend credentials."
        }
    }

    var confirmationTitle: String {
        switch self {
        case .clearAIHistory:
            return "Delete AI history"
        case .deleteDataAccount:
            return "Request deletion"
        }
    }

    var confirmationAccessibilityID: String {
        switch self {
        case .clearAIHistory:
            return "profile-confirm-delete-ai-history-button"
        case .deleteDataAccount:
            return "profile-confirm-delete-data-account-button"
        }
    }
}

struct DoctorReportExportSheet: View {
    let export: DoctorReportExport

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                IconBadge(name: "note", color: .sage)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Report ready")
                        .font(DS.sans(18, weight: .semibold))
                        .foregroundColor(.fgPrimary)
                    Text(export.fileName)
                        .font(DS.mono(11))
                        .foregroundColor(.fgFaint)
                }
                Spacer()
            }

            Text("Review the generated text before sharing it with a clinician. It is based only on local logs and is not a diagnosis.")
                .font(DS.sans(13))
                .foregroundColor(.fgDim)
                .lineSpacing(3)

            ScrollView {
                Text(export.content)
                    .font(DS.mono(12))
                    .foregroundColor(.fgDim)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(maxHeight: 240)
            .padding(12)
            .background(Color.bgInset)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            ShareLink(item: export.fileURL) {
                HStack(spacing: 8) {
                    AppIcon(name: "share", size: 16, color: .darkText)
                    Text("Share report")
                        .font(DS.sans(15, weight: .medium))
                        .tracking(-0.1)
                }
                .foregroundColor(.darkText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.sage)
                .clipShape(Capsule())
            }
            .buttonStyle(PressableButtonStyle(scale: 0.97))
        }
        .padding(20)
        .background(Color.bgPrimary)
        .presentationDetents([.medium, .large])
    }
}

struct UserDataExportSheet: View {
    let export: UserDataExport

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                IconBadge(name: "download", color: .ink)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Data export ready")
                        .font(DS.sans(18, weight: .semibold))
                        .foregroundColor(.fgPrimary)
                        .accessibilityIdentifier("user-data-export-title")
                    Text(export.fileName)
                        .font(DS.mono(11))
                        .foregroundColor(.fgFaint)
                }
                Spacer()
            }

            Text("This JSON file contains local data saved on this device, including logs, onboarding profile, privacy preferences, pending sync records, and saved Care messages. Review before sharing.")
                .font(DS.sans(13))
                .foregroundColor(.fgDim)
                .lineSpacing(3)

            ScrollView {
                Text(export.content)
                    .font(DS.mono(11))
                    .foregroundColor(.fgDim)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(maxHeight: 240)
            .padding(12)
            .background(Color.bgInset)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            ShareLink(item: export.fileURL) {
                HStack(spacing: 8) {
                    AppIcon(name: "share", size: 16, color: .darkText)
                    Text("Share data export")
                        .font(DS.sans(15, weight: .medium))
                        .tracking(-0.1)
                }
                .foregroundColor(.darkText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.ink)
                .clipShape(Capsule())
            }
            .buttonStyle(PressableButtonStyle(scale: 0.97))
            .accessibilityIdentifier("user-data-export-share-button")
        }
        .padding(20)
        .background(Color.bgPrimary)
        .presentationDetents([.medium, .large])
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
    var accessibilityID: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        if let action {
            Button(action: action) {
                rowContent
            }
            .buttonStyle(PressableButtonStyle(scale: 0.97))
            .accessibilityIdentifier(accessibilityID ?? label)
        } else {
            rowContent
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier(accessibilityID ?? label)
        }
    }

    private var rowContent: some View {
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
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(Color.strokeDefault).frame(height: 0.5).padding(.leading, 60)
            }
        }
    }
}

#Preview {
    ProfileView(appState: AppState())
        .background(Color.bgPrimary)
        .preferredColorScheme(.dark)
}
