import SwiftUI

struct ProfileView: View {
    var appState: AppState
    @State private var preparedExport: ProfilePreparedExport?
    @State private var pendingConfirmation: ProfileConfirmation?
    @State private var showingProfileEdit = false
    @State private var showingSyncDetails = false
    @State private var showingMedicationReminders = false
    @State private var showingPreferences = false
    @State private var showingFlareHistory = false
    @State private var showingCarePlan = false
    @State private var showingEducationLibrary = false

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
                            .accessibilityIdentifier("profile-display-name")
                        Text(appState.diagnosisLabel)
                            .font(DS.sans(13))
                            .foregroundColor(.fgDim)
                            .accessibilityIdentifier("profile-diagnosis-label")
                    }
                    Spacer()
                    Button { showingProfileEdit = true } label: {
                        Text("Edit")
                            .font(DS.sans(13, weight: .medium))
                            .foregroundColor(.fgPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.bgInset)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PressableButtonStyle())
                    .accessibilityIdentifier("profile-edit-button")
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
                    ProfileRow(icon: "download", label: "Export doctor report", sub: "Shareable text file", accessibilityID: "profile-export-report-row") {
                        do {
                            preparedExport = .doctorReport(try appState.prepareDoctorReportExport())
                        } catch {
                            appState.showToast("Report export failed")
                        }
                    }
                    ProfileRow(
                        icon: "bell",
                        label: "Medication reminders",
                        sub: appState.medicationReminderSummary,
                        accessibilityID: "profile-medication-reminders-row"
                    ) {
                        showingMedicationReminders = true
                    }
                    ProfileRow(
                        icon: "calendar",
                        label: "Flare history",
                        sub: appState.flareHistorySummary.profileSummary,
                        accessibilityID: "profile-flare-history-row"
                    ) {
                        showingFlareHistory = true
                    }
                    ProfileRow(
                        icon: "heart",
                        label: "Care plan",
                        sub: appState.carePlanSummary.profileSummary,
                        isLast: true,
                        accessibilityID: "profile-care-plan-row"
                    ) {
                        showingCarePlan = true
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
                    ProfileRow(
                        icon: "settings",
                        label: "Preferences",
                        sub: appState.preferencesSummary,
                        accessibilityID: "profile-preferences-row"
                    ) {
                        showingPreferences = true
                    }
                    ProfileRow(
                        icon: "book",
                        label: "IBD library",
                        sub: appState.ibdEducationLibrary.profileSummary,
                        accessibilityID: "profile-ibd-library-row"
                    ) {
                        showingEducationLibrary = true
                    }
                    ProfileRow(icon: "logout", label: "Sign out", isDanger: true, isLast: true, accessibilityID: "profile-sign-out-row") {
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
                    ProfileRow(icon: "cloud", label: "Sync status", sub: appState.syncSummary, accessibilityID: "profile-sync-status-row") {
                        showingSyncDetails = true
                    }
                    ProfileRow(
                        icon: "sparkle",
                        label: "AI memory",
                        sub: appState.aiMemoryEnabled ? "On · saved only with consent" : "Off",
                        accessibilityID: "profile-ai-memory-toggle"
                    ) {
                        appState.setAIMemoryEnabled(!appState.aiMemoryEnabled)
                    }
                    ProfileRow(
                        icon: "mic",
                        label: "Voice transcript storage",
                        sub: appState.voiceTranscriptStorageEnabled ? "On · transcripts may be stored" : "Off · drafts only",
                        accessibilityID: "profile-voice-transcript-storage-toggle"
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
        .sheet(isPresented: $showingProfileEdit) {
            ProfileEditSheet(appState: appState)
        }
        .sheet(isPresented: $showingSyncDetails) {
            SyncStatusDetailSheet(appState: appState)
        }
        .sheet(isPresented: $showingMedicationReminders) {
            MedicationReminderSettingsSheet(appState: appState)
        }
        .sheet(isPresented: $showingPreferences) {
            ProfilePreferencesSheet(appState: appState)
        }
        .sheet(isPresented: $showingFlareHistory) {
            FlareHistorySheet(summary: appState.flareHistorySummary)
        }
        .sheet(isPresented: $showingCarePlan) {
            CarePlanSheet(summary: appState.carePlanSummary)
        }
        .sheet(isPresented: $showingEducationLibrary) {
            IBDEducationLibrarySheet(library: appState.ibdEducationLibrary)
        }
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

private struct ProfileEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    var appState: AppState
    @State private var displayName: String
    @State private var diagnosis: String
    @State private var primaryGoal: String
    @State private var baselineStoolCount: Int
    @State private var hasFlarePlan: Bool
    @FocusState private var focusedField: Field?

    private enum Field {
        case displayName
    }

    private let diagnoses = ["Ulcerative colitis", "Crohn's disease", "IBD unclassified", "Prefer not to say"]
    private let goals = ["Track flare risk", "Prepare doctor reports", "Remember meds", "Find possible patterns"]

    init(appState: AppState) {
        self.appState = appState
        let profile = appState.onboardingProfile
        _displayName = State(initialValue: appState.displayName == "there" ? "" : appState.displayName)
        _diagnosis = State(initialValue: profile?.diagnosis ?? "Prefer not to say")
        _primaryGoal = State(initialValue: profile?.primaryGoal ?? "Track symptoms")
        _baselineStoolCount = State(initialValue: profile?.baselineStoolCount ?? 2)
        _hasFlarePlan = State(initialValue: profile?.hasFlarePlan ?? false)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    IconBadge(name: "user", color: .sage)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Edit profile")
                            .font(DS.sans(18, weight: .semibold))
                            .foregroundColor(.fgPrimary)
                            .accessibilityIdentifier("profile-edit-title")
                        Text("Saved locally; backend profile sync waits for Supabase.")
                            .font(DS.sans(12))
                            .foregroundColor(.fgFaint)
                    }
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        AppIcon(name: "close", size: 15, color: .fgDim)
                            .frame(width: 36, height: 36)
                            .background(Color.bgInset)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PressableButtonStyle(scale: 0.94))
                    .accessibilityLabel("Close profile editor")
                    .accessibilityIdentifier("profile-edit-close-button")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Display name")
                        .font(DS.sans(13, weight: .semibold))
                        .foregroundColor(.fgPrimary)
                    TextField("Name", text: $displayName)
                        .font(DS.sans(15))
                        .foregroundColor(.fgPrimary)
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .focused($focusedField, equals: .displayName)
                        .padding(12)
                        .background(Color.bgInset)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityIdentifier("profile-edit-display-name-field")
                }
                .padding(14)
                .background(Color.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                ProfileEditChoiceGroup(
                    title: "Diagnosis",
                    options: diagnoses,
                    selected: diagnosis,
                    color: .sage,
                    identifierPrefix: "profile-edit-diagnosis"
                ) { diagnosis = $0 }

                ProfileEditChoiceGroup(
                    title: "Primary goal",
                    options: goals,
                    selected: primaryGoal,
                    color: .amber,
                    identifierPrefix: "profile-edit-goal"
                ) { primaryGoal = $0 }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Usual stool count")
                        .font(DS.sans(13, weight: .semibold))
                        .foregroundColor(.fgPrimary)
                    HStack(spacing: 12) {
                        ProfileEditStepperButton(
                            icon: "minus",
                            isEnabled: baselineStoolCount > 0,
                            identifier: "profile-edit-baseline-decrement-button"
                        ) {
                            baselineStoolCount = max(0, baselineStoolCount - 1)
                        }

                        VStack(spacing: 2) {
                            Text("\(baselineStoolCount)")
                                .font(DS.serif(30))
                                .foregroundColor(.fgPrimary)
                            Text("on a typical day")
                                .font(DS.sans(12))
                                .foregroundColor(.fgDim)
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(baselineStoolCount) stools on a typical day")
                        .accessibilityIdentifier("profile-edit-baseline-status")

                        ProfileEditStepperButton(
                            icon: "plus",
                            isEnabled: baselineStoolCount < 20,
                            identifier: "profile-edit-baseline-increment-button"
                        ) {
                            baselineStoolCount = min(20, baselineStoolCount + 1)
                        }
                    }
                }
                .padding(14)
                .background(Color.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Button {
                    hasFlarePlan.toggle()
                } label: {
                    HStack(spacing: 10) {
                        AppIcon(name: hasFlarePlan ? "check" : "note", size: 15, color: hasFlarePlan ? .darkText : .fgDim)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Clinician flare plan")
                                .font(DS.sans(14, weight: .semibold))
                                .foregroundColor(hasFlarePlan ? .darkText : .fgPrimary)
                            Text(hasFlarePlan ? "Saved in local profile" : "Not saved yet")
                                .font(DS.sans(12))
                                .foregroundColor(hasFlarePlan ? .darkText.opacity(0.72) : .fgDim)
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(hasFlarePlan ? Color.sage : Color.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(PressableButtonStyle(scale: 0.97))
                .accessibilityIdentifier("profile-edit-flare-plan-toggle")
                .accessibilityValue(hasFlarePlan ? "Saved" : "Not saved")

                HStack(alignment: .top, spacing: 10) {
                    AppIcon(name: "shield", size: 15, color: .fgDim)
                    Text("Profile edits update this device and queue future backend sync. They do not change medical care instructions.")
                        .font(DS.sans(12))
                        .foregroundColor(.fgDim)
                        .lineSpacing(3)
                        .accessibilityIdentifier("profile-edit-safety-note")
                }
                .padding(14)
                .background(Color.bgInset)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                PrimaryButton(title: "Save profile") {
                    if appState.updateProfile(
                        displayName: displayName,
                        diagnosis: diagnosis,
                        primaryGoal: primaryGoal,
                        baselineStoolCount: baselineStoolCount,
                        hasFlarePlan: hasFlarePlan
                    ) {
                        dismiss()
                    }
                }
                .accessibilityIdentifier("profile-edit-save-button")
            }
            .padding(20)
        }
        .background(Color.bgPrimary)
        .presentationDetents([.large])
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
                .accessibilityIdentifier("profile-edit-keyboard-done-button")
            }
        }
    }
}

private struct ProfileEditChoiceGroup: View {
    let title: String
    let options: [String]
    let selected: String
    let color: Color
    let identifierPrefix: String
    let action: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(DS.sans(13, weight: .semibold))
                .foregroundColor(.fgPrimary)
            FlowLayout(spacing: 6) {
                ForEach(options, id: \.self) { option in
                    ProfileEditChoiceButton(
                        label: option,
                        isSelected: selected == option,
                        color: color,
                        identifier: "\(identifierPrefix)-\(option.profileEditIdentifierSlug)-button"
                    ) {
                        action(option)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct ProfileEditChoiceButton: View {
    let label: String
    let isSelected: Bool
    let color: Color
    let identifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(DS.sans(13, weight: .medium))
                .foregroundColor(isSelected ? color : .fgDim)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? color.opacity(0.15) : Color.bgInset)
                .overlay(Capsule().stroke(isSelected ? color : Color.clear, lineWidth: 1))
                .clipShape(Capsule())
        }
        .buttonStyle(PressableButtonStyle(scale: 0.97))
        .accessibilityIdentifier(identifier)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}

private struct ProfileEditStepperButton: View {
    let icon: String
    let isEnabled: Bool
    let identifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            AppIcon(name: icon, size: 16, color: isEnabled ? .fgPrimary : .fgFaint)
                .frame(width: 40, height: 40)
                .background(Color.bgInset)
                .clipShape(Circle())
        }
        .buttonStyle(PressableButtonStyle(scale: isEnabled ? 0.94 : 1))
        .disabled(!isEnabled)
        .accessibilityIdentifier(identifier)
    }
}

private extension String {
    var profileEditIdentifierSlug: String {
        lowercased()
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "/", with: "-")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }
}

private struct FlareHistorySheet: View {
    let summary: FlareHistorySummary

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    IconBadge(name: "flame", color: .clay)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Flare history")
                            .font(DS.sans(18, weight: .semibold))
                            .foregroundColor(.fgPrimary)
                            .accessibilityIdentifier("flare-history-title")
                        Text(summary.detailSummary)
                            .font(DS.sans(13))
                            .foregroundColor(.fgFaint)
                            .accessibilityIdentifier("flare-history-summary")
                    }
                    Spacer()
                }

                if summary.events.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No local flare marks yet")
                            .font(DS.sans(15, weight: .medium))
                            .foregroundColor(.fgPrimary)
                        Text("Flare-marked check-ins and logs will appear here after they are saved on this device.")
                            .font(DS.sans(12))
                            .foregroundColor(.fgDim)
                            .lineSpacing(3)
                    }
                    .padding(14)
                    .background(Color.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("flare-history-empty-state")
                } else {
                    VStack(spacing: 10) {
                        ForEach(Array(summary.events.enumerated()), id: \.element.id) { index, event in
                            FlareHistoryEventRow(event: event, index: index)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Color.bgPrimary)
        .presentationDetents([.medium, .large])
    }
}

private struct FlareHistoryEventRow: View {
    let event: FlareHistoryEvent
    let index: Int

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            IconBadge(name: "flame", size: 34, iconSize: 15, color: .clay)
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(DS.sans(14, weight: .medium))
                    .foregroundColor(.fgPrimary)
                Text(event.detail)
                    .font(DS.sans(12))
                    .foregroundColor(.fgDim)
                    .lineLimit(2)
                Text(event.loggedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(DS.mono(11))
                    .foregroundColor(.fgFaint)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("flare-history-event-\(index)")
    }
}

private struct CarePlanSheet: View {
    let summary: CarePlanSummary

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    IconBadge(name: "heart", color: .sage)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Care plan questions")
                            .font(DS.sans(18, weight: .semibold))
                            .foregroundColor(.fgPrimary)
                            .accessibilityIdentifier("care-plan-title")
                        Text(summary.profileSummary)
                            .font(DS.sans(13))
                            .foregroundColor(.fgFaint)
                            .accessibilityIdentifier("care-plan-summary")
                    }
                    Spacer()
                }

                VStack(spacing: 10) {
                    ForEach(Array(summary.questions.enumerated()), id: \.element.id) { index, question in
                        CarePlanQuestionRow(question: question, index: index)
                    }
                }

                HStack(alignment: .top, spacing: 10) {
                    AppIcon(name: "shield", size: 15, color: .fgDim)
                    Text(summary.safetyNote)
                        .font(DS.sans(12))
                        .foregroundColor(.fgDim)
                        .lineSpacing(3)
                        .accessibilityIdentifier("care-plan-safety-note")
                }
                .padding(14)
                .background(Color.bgInset)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(20)
        }
        .background(Color.bgPrimary)
        .presentationDetents([.medium, .large])
    }
}

private struct CarePlanQuestionRow: View {
    let question: CarePlanQuestion
    let index: Int

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            IconBadge(name: "note", size: 34, iconSize: 15, color: .sage)
            VStack(alignment: .leading, spacing: 4) {
                Text(question.context)
                    .font(DS.mono(10, weight: .semibold))
                    .foregroundColor(.fgFaint)
                    .textCase(.uppercase)
                Text(question.text)
                    .font(DS.sans(14, weight: .medium))
                    .foregroundColor(.fgPrimary)
                    .lineSpacing(2)
            }
            Spacer()
        }
        .padding(14)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("care-plan-question-\(index)")
    }
}

private struct IBDEducationLibrarySheet: View {
    let library: PatientEducationLibrary

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    IconBadge(name: "book", color: .ink)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("IBD library")
                            .font(DS.sans(18, weight: .semibold))
                            .foregroundColor(.fgPrimary)
                            .accessibilityIdentifier("ibd-library-title")
                        Text(library.profileSummary)
                            .font(DS.sans(13))
                            .foregroundColor(.fgFaint)
                            .accessibilityIdentifier("ibd-library-summary")
                    }
                    Spacer()
                }

                VStack(spacing: 10) {
                    ForEach(Array(library.articles.enumerated()), id: \.element.id) { index, article in
                        IBDEducationArticleRow(article: article, index: index)
                    }
                }

                HStack(alignment: .top, spacing: 10) {
                    AppIcon(name: "shield", size: 15, color: .fgDim)
                    Text(library.safetyNote)
                        .font(DS.sans(12))
                        .foregroundColor(.fgDim)
                        .lineSpacing(3)
                        .accessibilityIdentifier("ibd-library-safety-note")
                }
                .padding(14)
                .background(Color.bgInset)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(20)
        }
        .background(Color.bgPrimary)
        .presentationDetents([.medium, .large])
    }
}

private struct IBDEducationArticleRow: View {
    let article: PatientEducationArticle
    let index: Int

    private var sourceNames: String {
        article.sources.map(\.name).joined(separator: ", ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                IconBadge(name: "book", size: 34, iconSize: 15, color: .ink)
                VStack(alignment: .leading, spacing: 4) {
                    Text(article.title)
                        .font(DS.sans(15, weight: .semibold))
                        .foregroundColor(.fgPrimary)
                    Text(article.summary)
                        .font(DS.sans(12))
                        .foregroundColor(.fgDim)
                        .lineSpacing(3)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(article.keyPoints, id: \.self) { keyPoint in
                    HStack(alignment: .top, spacing: 7) {
                        Text("-")
                            .font(DS.sans(12, weight: .semibold))
                            .foregroundColor(.fgFaint)
                        Text(keyPoint)
                            .font(DS.sans(12))
                            .foregroundColor(.fgDim)
                            .lineSpacing(2)
                    }
                }
            }

            Text("Ask: \(article.clinicianPrompt)")
                .font(DS.sans(12, weight: .medium))
                .foregroundColor(.fgPrimary)
                .lineSpacing(2)

            Text("Source: \(sourceNames)")
                .font(DS.mono(10, weight: .semibold))
                .foregroundColor(.fgFaint)
                .textCase(.uppercase)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .accessibilityIdentifier("ibd-library-article-source-\(index)")
        }
        .padding(14)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("ibd-library-article-\(index)")
    }
}

private struct MedicationReminderSettingsSheet: View {
    var appState: AppState

    private var settings: MedicationReminderSettings {
        appState.medicationReminderSettings
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    IconBadge(name: "bell", color: .amber)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Medication reminders")
                            .font(DS.sans(18, weight: .semibold))
                            .foregroundColor(.fgPrimary)
                            .accessibilityIdentifier("medication-reminders-title")
                        Text(settings.summary)
                            .font(DS.sans(13))
                            .foregroundColor(.fgFaint)
                            .accessibilityIdentifier("medication-reminders-status")
                    }
                    Spacer()
                }

                Toggle(
                    isOn: Binding(
                        get: { settings.isEnabled },
                        set: { appState.setMedicationRemindersEnabled($0) }
                    )
                ) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reminder preference")
                            .font(DS.sans(15, weight: .medium))
                            .foregroundColor(.fgPrimary)
                        Text(settings.detail)
                            .font(DS.sans(12))
                            .foregroundColor(.fgDim)
                    }
                }
                .toggleStyle(.switch)
                .padding(14)
                .background(Color.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .accessibilityIdentifier("medication-reminders-enabled-toggle")

                VStack(alignment: .leading, spacing: 10) {
                    Text("Lead time")
                        .font(DS.sans(13, weight: .semibold))
                        .foregroundColor(.fgPrimary)

                    HStack(spacing: 8) {
                        ForEach(MedicationReminderSettings.allowedAdvanceNoticeMinutes, id: \.self) { minutes in
                            ReminderLeadTimeButton(
                                minutes: minutes,
                                isSelected: settings.advanceNoticeMinutes == minutes
                            ) {
                                appState.setMedicationReminderAdvanceNotice(minutes: minutes)
                            }
                        }
                    }
                }
                .padding(14)
                .background(Color.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 10) {
                    Text("Scheduled doses")
                        .font(DS.sans(13, weight: .semibold))
                        .foregroundColor(.fgPrimary)

                    ForEach(appState.medicationDoses) { dose in
                        HStack(spacing: 10) {
                            AppIcon(name: "pill", size: 14, color: .fgDim)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(dose.name)
                                    .font(DS.sans(13, weight: .medium))
                                    .foregroundColor(.fgPrimary)
                                Text("\(dose.dose) · \(dose.time)")
                                    .font(DS.sans(12))
                                    .foregroundColor(.fgFaint)
                            }
                            Spacer()
                            Text(dose.status.label)
                                .font(DS.sans(12, weight: .medium))
                                .foregroundColor(dose.status.color)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(14)
                .background(Color.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                HStack(alignment: .top, spacing: 10) {
                    AppIcon(name: "shield", size: 15, color: .fgDim)
                    Text("Notification setup required before iOS alerts are scheduled. Your preference is saved locally and included in data export.")
                        .font(DS.sans(12))
                        .foregroundColor(.fgDim)
                        .lineSpacing(3)
                        .accessibilityIdentifier("medication-reminders-setup-status")
                }
                .padding(14)
                .background(Color.bgInset)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(20)
        }
        .background(Color.bgPrimary)
        .presentationDetents([.medium, .large])
    }
}

private struct ReminderLeadTimeButton: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void

    private var label: String {
        switch minutes {
        case 0:
            return "At time"
        case 60:
            return "1 hr"
        default:
            return "\(minutes)m"
        }
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(DS.sans(13, weight: .medium))
                .foregroundColor(isSelected ? .darkText : .fgDim)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(isSelected ? Color.sage : Color.bgInset)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PressableButtonStyle(scale: 0.97))
        .accessibilityIdentifier("medication-reminder-lead-\(minutes)-button")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}

private extension MedicationDoseStatus {
    var color: Color {
        switch self {
        case .pending:
            return .fgFaint
        case .taken:
            return .sage
        case .skipped:
            return .amber
        case .missed:
            return .clay
        }
    }
}

private struct ProfilePreferencesSheet: View {
    @Environment(\.dismiss) private var dismiss
    var appState: AppState

    private var preferences: AppPreferences {
        appState.appPreferences
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    IconBadge(name: "settings", color: .ink)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Preferences")
                            .font(DS.sans(18, weight: .semibold))
                            .foregroundColor(.fgPrimary)
                            .accessibilityIdentifier("profile-preferences-title")
                        Text(preferences.summary)
                            .font(DS.sans(13))
                            .foregroundColor(.fgFaint)
                            .accessibilityIdentifier("profile-preferences-status")
                    }
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        AppIcon(name: "close", size: 15, color: .fgDim)
                            .frame(width: 36, height: 36)
                            .background(Color.bgInset)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PressableButtonStyle(scale: 0.94))
                    .accessibilityLabel("Close preferences")
                    .accessibilityIdentifier("profile-preferences-close-button")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Weight unit")
                        .font(DS.sans(13, weight: .semibold))
                        .foregroundColor(.fgPrimary)

                    HStack(spacing: 8) {
                        ForEach(WeightUnit.allCases) { unit in
                            PreferenceSegmentButton(
                                label: unit.label,
                                isSelected: preferences.weightUnit == unit,
                                identifier: "profile-preference-weight-\(unit.rawValue)-button"
                            ) {
                                appState.setPreferredWeightUnit(unit)
                            }
                        }
                    }
                }
                .padding(14)
                .background(Color.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Toggle(
                    isOn: Binding(
                        get: { preferences.useDeviceTimeZone },
                        set: { appState.setUseDeviceTimeZone($0) }
                    )
                ) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Use device timezone")
                            .font(DS.sans(15, weight: .medium))
                            .foregroundColor(.fgPrimary)
                        Text(preferences.timeZoneSummary)
                            .font(DS.sans(12))
                            .foregroundColor(.fgDim)
                            .accessibilityIdentifier("profile-preferences-timezone-status")
                    }
                }
                .toggleStyle(.switch)
                .padding(14)
                .background(Color.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .accessibilityIdentifier("profile-preferences-device-timezone-toggle")

                HStack(alignment: .top, spacing: 10) {
                    AppIcon(name: "shield", size: 15, color: .fgDim)
                    Text("Preferences are saved locally and included in data export. Backend settings sync waits for Supabase configuration.")
                        .font(DS.sans(12))
                        .foregroundColor(.fgDim)
                        .lineSpacing(3)
                        .accessibilityIdentifier("profile-preferences-setup-status")
                }
                .padding(14)
                .background(Color.bgInset)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(20)
        }
        .background(Color.bgPrimary)
        .presentationDetents([.medium, .large])
    }
}

private struct PreferenceSegmentButton: View {
    let label: String
    let isSelected: Bool
    let identifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(DS.sans(13, weight: .medium))
                .foregroundColor(isSelected ? .darkText : .fgDim)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(isSelected ? Color.ink : Color.bgInset)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PressableButtonStyle(scale: 0.97))
        .accessibilityIdentifier(identifier)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}

private struct SyncStatusDetailSheet: View {
    var appState: AppState

    private var activeMutations: [PendingSyncMutation] {
        appState.pendingSyncMutations.filter { $0.status != .synced }
    }

    private var replayPlanByMutation: [UUID: SyncReplayPlanItem] {
        Dictionary(uniqueKeysWithValues: appState.pendingSyncReplayPlan.map { ($0.mutationId, $0) })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    IconBadge(name: "cloud", color: .ink)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Sync details")
                            .font(DS.sans(18, weight: .semibold))
                            .foregroundColor(.fgPrimary)
                            .accessibilityIdentifier("profile-sync-detail-title")
                        Text(appState.syncSummary)
                            .font(DS.sans(12))
                            .foregroundColor(.fgFaint)
                            .accessibilityIdentifier("profile-sync-detail-summary")
                    }
                    Spacer()
                }

                Text("Inflamend is saving changes on this device. Cloud replay is blocked until Supabase credentials are configured.")
                    .font(DS.sans(13))
                    .foregroundColor(.fgDim)
                    .lineSpacing(3)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Network: \(appState.syncNetworkStatus.label)")
                        .font(DS.sans(13, weight: .semibold))
                        .foregroundColor(.fgPrimary)
                        .accessibilityIdentifier("profile-sync-network-status")
                    Text(appState.syncNetworkStatus.detail)
                        .font(DS.sans(12))
                        .foregroundColor(.fgFaint)
                        .accessibilityIdentifier("profile-sync-network-detail")
                    Text(appState.automaticSyncRetrySummary)
                        .font(DS.sans(12))
                        .foregroundColor(.fgFaint)
                        .accessibilityIdentifier("profile-sync-automatic-retry-detail")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.bgInset)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Button {
                    appState.retryPendingSyncScaffold()
                } label: {
                    HStack(spacing: 8) {
                        AppIcon(name: "refresh", size: 16, color: activeMutations.isEmpty ? .fgFaint : .darkText)
                        Text(activeMutations.isEmpty ? "Nothing pending" : "Retry sync")
                            .font(DS.sans(15, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundColor(activeMutations.isEmpty ? .fgFaint : .darkText)
                    .background(activeMutations.isEmpty ? Color.bgInset : Color.ink)
                    .clipShape(Capsule())
                }
                .buttonStyle(PressableButtonStyle(scale: activeMutations.isEmpty ? 1 : 0.97))
                .disabled(activeMutations.isEmpty)
                .accessibilityIdentifier("profile-sync-detail-retry-button")

                if activeMutations.isEmpty {
                    Text("No local records are waiting for backend replay.")
                        .font(DS.sans(13))
                        .foregroundColor(.fgDim)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(Color.bgInset)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .accessibilityIdentifier("profile-sync-detail-empty")
                } else {
                    VStack(spacing: 10) {
                        ForEach(Array(activeMutations.enumerated()), id: \.element.id) { index, mutation in
                            SyncMutationDetailRow(
                                index: index,
                                mutation: mutation,
                                plan: replayPlanByMutation[mutation.id]
                            )
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Color.bgPrimary)
        .presentationDetents([.medium, .large])
    }
}

private struct SyncMutationDetailRow: View {
    let index: Int
    let mutation: PendingSyncMutation
    let plan: SyncReplayPlanItem?

    private var accessibilitySummary: String {
        var pieces = [
            mutation.summary,
            mutation.kind.syncLabel,
            mutation.status.syncLabel
        ]
        if let plan {
            pieces.append("\(plan.action.syncLabel) \(plan.target)")
        }
        if let nextRetryAt = mutation.nextRetryAt {
            pieces.append("Next retry after \(nextRetryAt.formatted(date: .abbreviated, time: .shortened))")
        }
        if let lastError = mutation.lastError, !lastError.isEmpty {
            pieces.append(lastError)
        }
        pieces.append("Attempts \(mutation.attemptCount)")
        return pieces.joined(separator: ", ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                AppIcon(name: mutation.status.syncIconName, size: 16, color: mutation.status.syncColor)
                    .frame(width: 28, height: 28)
                    .background(mutation.status.syncColor.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(mutation.summary)
                        .font(DS.sans(14, weight: .semibold))
                        .foregroundColor(.fgPrimary)
                    Text(mutation.kind.syncLabel)
                        .font(DS.sans(12))
                        .foregroundColor(.fgFaint)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 8) {
                SyncDetailChip(
                    text: mutation.status.syncLabel,
                    color: mutation.status.syncColor,
                    identifier: "profile-sync-detail-status-\(index)"
                )

                if let plan {
                    SyncDetailChip(
                        text: "\(plan.action.syncLabel) \(plan.target)",
                        color: .fgDim,
                        identifier: "profile-sync-detail-target-\(index)"
                    )
                }
            }

            if let lastError = mutation.lastError, !lastError.isEmpty {
                Text(lastError)
                    .font(DS.sans(12))
                    .foregroundColor(.fgDim)
                    .lineLimit(3)
                    .accessibilityIdentifier("profile-sync-detail-error-\(index)")
            }

            Text("Attempts \(mutation.attemptCount) · \(mutation.createdAt.formatted(date: .abbreviated, time: .shortened))")
                .font(DS.mono(11))
                .foregroundColor(.fgFaint)
                .accessibilityIdentifier("profile-sync-detail-attempts-\(index)")

            if let nextRetryAt = mutation.nextRetryAt {
                Text("Next retry after \(nextRetryAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(DS.mono(11))
                    .foregroundColor(.fgFaint)
                    .accessibilityIdentifier("profile-sync-detail-next-retry-\(index)")
            }
        }
        .padding(14)
        .background(Color.bgInset)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityIdentifier("profile-sync-detail-row-\(index)")
    }
}

private struct SyncDetailChip: View {
    let text: String
    let color: Color
    let identifier: String

    var body: some View {
        Text(text)
            .font(DS.mono(10, weight: .semibold))
            .foregroundColor(color)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
            .accessibilityLabel(text)
            .accessibilityIdentifier(identifier)
    }
}

private extension SyncMutationKind {
    var syncLabel: String {
        switch self {
        case .authSession:
            return "Auth session"
        case .onboardingProfile:
            return "Onboarding profile"
        case .healthLog:
            return "Health log create"
        case .healthLogUpdate:
            return "Health log update"
        case .healthLogDeletion:
            return "Health log deletion"
        case .chatMessage:
            return "Care message"
        case .privacyPreference:
            return "Privacy preference"
        case .safetyNotice:
            return "Safety notice"
        case .reportExport:
            return "Report export"
        case .accountDeletion:
            return "Account deletion"
        }
    }
}

private extension SyncMutationStatus {
    var syncLabel: String {
        switch self {
        case .pending:
            return "Pending"
        case .blockedNoBackend:
            return "Blocked - backend setup needed"
        case .syncing:
            return "Syncing"
        case .synced:
            return "Synced"
        case .failedRetryable:
            return "Retryable failure"
        case .failedNeedsUser:
            return "Needs attention"
        }
    }

    var syncColor: Color {
        switch self {
        case .pending, .syncing:
            return .amber
        case .blockedNoBackend, .failedRetryable, .failedNeedsUser:
            return .clay
        case .synced:
            return .sage
        }
    }

    var syncIconName: String {
        switch self {
        case .pending, .syncing:
            return "clock"
        case .blockedNoBackend, .failedRetryable, .failedNeedsUser:
            return "alert"
        case .synced:
            return "check"
        }
    }
}

private extension SyncReplayAction {
    var syncLabel: String {
        switch self {
        case .authenticate:
            return "Auth"
        case .upsert:
            return "Upsert"
        case .insert:
            return "Insert"
        case .update:
            return "Update"
        case .softDelete:
            return "Delete"
        case .invokeFunction:
            return "Function"
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
                        .accessibilityIdentifier("doctor-report-export-title")
                    Text(export.fileName)
                        .font(DS.mono(11))
                        .foregroundColor(.fgFaint)
                        .accessibilityIdentifier("doctor-report-export-filename")
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
            .accessibilityIdentifier("doctor-report-export-share-button")
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
