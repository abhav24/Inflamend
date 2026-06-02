import SwiftUI

enum Tab: String, CaseIterable {
    case home     = "home"
    case log      = "log"
    case insights = "insights"
    case chat     = "chat"
    case profile  = "profile"

    var label: String {
        switch self {
        case .home:     return "Home"
        case .log:      return "Log"
        case .insights: return "Insights"
        case .chat:     return "Care"
        case .profile:  return "You"
        }
    }
    var icon: String {
        switch self {
        case .home:     return "home"
        case .log:      return "plus"
        case .insights: return "chart"
        case .chat:     return "shield"
        case .profile:  return "user"
        }
    }
}

struct ContentView: View {
    @State private var appState = AppState()
    @State private var selectedTab: Tab = .home
    @State private var showFoodSheet = false
    @State private var showBristolSheet = false
    @State private var showCheckInSheet = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.bgPrimary.ignoresSafeArea()

            if !appState.isAuthenticated {
                AuthGateView(appState: appState)
                    .transition(.pageFade)
            } else if !appState.hasCompletedOnboarding {
                OnboardingGateView(appState: appState)
                    .transition(.pageFade)
            } else {
                mainAppShell
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .overlay(alignment: .top) {
            if let msg = appState.toast {
                ToastView(message: msg, actionTitle: appState.toastActionTitle) {
                    appState.performToastAction()
                }
                    .padding(.top, 60)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .animation(.spring(duration: 0.3), value: appState.toast)
                    .zIndex(999)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: appState.toast)
        // Food sheet
        .sheet(isPresented: $showFoodSheet) {
            QuickFoodSheet(appState: appState, isPresented: $showFoodSheet)
                .presentationDetents([.medium])
                .presentationBackground(Color.bgElevated)
                .presentationCornerRadius(32)
        }
        // Bristol sheet
        .sheet(isPresented: $showBristolSheet) {
            QuickBristolSheet(appState: appState, isPresented: $showBristolSheet)
                .presentationDetents([.medium])
                .presentationBackground(Color.bgElevated)
                .presentationCornerRadius(32)
        }
        .sheet(isPresented: $showCheckInSheet) {
            CheckInSheet(appState: appState, isPresented: $showCheckInSheet)
                .presentationDetents([.large])
                .presentationBackground(Color.bgElevated)
                .presentationCornerRadius(32)
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var mainAppShell: some View {
        Group {
            switch selectedTab {
            case .home:
                HomeView(
                    appState: appState,
                    selectedTab: $selectedTab,
                    showFoodSheet: $showFoodSheet,
                    showBristolSheet: $showBristolSheet,
                    showCheckInSheet: $showCheckInSheet
                )
            case .log:
                LogView(appState: appState)
            case .insights:
                InsightsView(appState: appState)
            case .chat:
                ChatView(appState: appState)
            case .profile:
                ProfileView(appState: appState)
            }
        }
        .id(selectedTab)
        .transition(.pageFade)
        .animation(.spring(response: 0.38, dampingFraction: 0.88), value: selectedTab)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 96)

        CustomTabBar(selectedTab: $selectedTab)
    }
}

// MARK: - Auth Gate

enum AuthMode {
    case signIn
    case signUp
}

struct AuthGateView: View {
    var appState: AppState
    @State private var mode: AuthMode = .signUp
    @State private var email = ""
    @State private var displayName = ""
    @State private var password = ""
    @FocusState private var focusedField: AuthField?

    private enum AuthField: Hashable {
        case displayName
        case email
        case password
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                Spacer(minLength: 36)

                VStack(alignment: .leading, spacing: 6) {
                    Text("INFLAMEND").dsLabel()
                    Text("Your IBD day, organized.")
                        .font(DS.serif(38))
                        .foregroundColor(.fgPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Track symptoms, meds, meals, notes, and reports with privacy-first local scaffolding while Supabase auth is configured.")
                        .font(DS.sans(14))
                        .foregroundColor(.fgDim)
                        .lineSpacing(3)
                }

                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        authModeButton("Sign up", mode: .signUp)
                        authModeButton("Sign in", mode: .signIn)
                    }

                    if mode == .signUp {
                        authTextField("Name", text: $displayName, contentType: .name)
                            .accessibilityIdentifier("auth-name-field")
                            .focused($focusedField, equals: .displayName)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .email
                            }
                    }
                    authTextField("Email", text: $email, contentType: .emailAddress)
                        .accessibilityIdentifier("auth-email-field")
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .password
                        }
                    SecureField("Password scaffold", text: $password)
                        .textContentType(mode == .signUp ? .newPassword : .password)
                        .font(DS.sans(15))
                        .foregroundColor(.fgPrimary)
                        .padding(14)
                        .background(Color.bgInset)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .accessibilityIdentifier("auth-password-field")
                        .focused($focusedField, equals: .password)
                        .submitLabel(.done)
                        .onSubmit(submitAuth)

                    Text("Password is accepted for flow testing only and is not stored in this local scaffold.")
                        .font(DS.sans(12))
                        .foregroundColor(.fgFaint)
                        .lineSpacing(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(16)
                .background(Color.bgCard)
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.strokeDefault, lineWidth: 0.5))
                .clipShape(RoundedRectangle(cornerRadius: 22))

                PrimaryButton(title: mode == .signUp ? "Create local account" : "Sign in", action: submitAuth)
                .accessibilityIdentifier("auth-primary-button")

                VStack(alignment: .leading, spacing: 8) {
                    AuthValueRow(icon: "shield", title: "Safety-first", detail: "Red flags show cautious guidance, never diagnosis.")
                    AuthValueRow(icon: "download", title: "Doctor-ready", detail: "Logs feed export and report scaffolds.")
                    AuthValueRow(icon: "lock", title: "Local restore", detail: "Session and logs restore from a protected local snapshot.")
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 110)
        }
        .background(Color.bgPrimary)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
                .accessibilityIdentifier("auth-keyboard-done-button")
            }
        }
    }

    private func submitAuth() {
        focusedField = nil

        switch mode {
        case .signUp:
            appState.signUp(email: email, displayName: displayName)
        case .signIn:
            appState.signIn(email: email)
        }
    }

    private func authModeButton(_ title: String, mode target: AuthMode) -> some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                mode = target
                focusedField = nil
            }
        } label: {
            Text(title)
                .font(DS.sans(13, weight: .medium))
                .foregroundColor(mode == target ? .darkText : .fgDim)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(mode == target ? Color.sage : Color.bgInset)
                .clipShape(Capsule())
        }
        .buttonStyle(PressableButtonStyle(scale: 0.96))
        .accessibilityIdentifier(target == .signUp ? "auth-mode-sign-up-button" : "auth-mode-sign-in-button")
    }

    private func authTextField(_ placeholder: String, text: Binding<String>, contentType: UITextContentType) -> some View {
        TextField(placeholder, text: text)
            .textContentType(contentType)
            .keyboardType(contentType == .emailAddress ? .emailAddress : .default)
            .textInputAutocapitalization(contentType == .emailAddress ? .never : .words)
            .autocorrectionDisabled(contentType == .emailAddress)
            .font(DS.sans(15))
            .foregroundColor(.fgPrimary)
            .padding(14)
            .background(Color.bgInset)
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct AuthValueRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            IconBadge(name: icon, size: 34, iconSize: 15, color: .sage)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DS.sans(14, weight: .medium))
                    .foregroundColor(.fgPrimary)
                Text(detail)
                    .font(DS.sans(12))
                    .foregroundColor(.fgDim)
                    .lineSpacing(2)
            }
        }
    }
}

// MARK: - Onboarding Gate

struct OnboardingGateView: View {
    var appState: AppState
    @State private var diagnosis = "Ulcerative colitis"
    @State private var primaryGoal = "Track flare risk"
    @State private var baselineStoolCount = 2
    @State private var hasFlarePlan = false

    private let diagnoses = ["Ulcerative colitis", "Crohn's disease", "IBD unclassified", "Prefer not to say"]
    private let goals = ["Track flare risk", "Prepare doctor reports", "Remember meds", "Find possible patterns"]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("SETUP").dsLabel()
                    Text("Make Inflamend fit your day")
                        .font(DS.serif(34))
                        .foregroundColor(.fgPrimary)
                    Text("Answer only what helps. You can skip sensitive questions and still use every core logging flow.")
                        .font(DS.sans(14))
                        .foregroundColor(.fgDim)
                        .lineSpacing(3)
                }
                .padding(.top, 42)

                FormCard(title: "Diagnosis", label: "OPTIONAL") {
                    FlowLayout(spacing: 6) {
                        ForEach(diagnoses, id: \.self) { option in
                            PillToggle(label: option, isActive: diagnosis == option, color: .sage) {
                                diagnosis = option
                            }
                        }
                    }
                }

                FormCard(title: "Primary goal", label: primaryGoal.uppercased()) {
                    FlowLayout(spacing: 6) {
                        ForEach(goals, id: \.self) { option in
                            PillToggle(label: option, isActive: primaryGoal == option, color: .amber) {
                                primaryGoal = option
                            }
                        }
                    }
                }

                FormCard(title: "Usual stool count", label: "\(baselineStoolCount)/DAY") {
                    Stepper(value: $baselineStoolCount, in: 0...20) {
                        Text("\(baselineStoolCount) on a typical day")
                            .font(DS.sans(15))
                            .foregroundColor(.fgPrimary)
                    }
                    .tint(.sage)
                }

                FormCard(title: "Care plan", label: hasFlarePlan ? "SAVED" : "NOT YET") {
                    PillToggle(label: "I have a clinician flare plan", isActive: hasFlarePlan, color: .sage) {
                        hasFlarePlan.toggle()
                    }
                    Text("Inflamend can help remember context, but care decisions should come from your GI clinician.")
                        .font(DS.sans(12))
                        .foregroundColor(.fgDim)
                        .lineSpacing(2)
                }

                PrimaryButton(title: "Finish setup") {
                    appState.completeOnboarding(
                        diagnosis: diagnosis,
                        primaryGoal: primaryGoal,
                        baselineStoolCount: baselineStoolCount,
                        hasFlarePlan: hasFlarePlan
                    )
                }
                .accessibilityIdentifier("onboarding-finish-button")

                GhostButton(title: "Skip sensitive questions") {
                    appState.skipOnboarding()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 110)
        }
        .background(Color.bgPrimary)
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    private let leadingTabs: [Tab] = [.home, .insights]
    private let trailingTabs: [Tab] = [.chat, .profile]

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            HStack(spacing: 0) {
                ForEach(leadingTabs, id: \.self) { tab in
                    tabButton(tab)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 68)

            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.7)) {
                    selectedTab = .log
                }
            } label: {
                AppIcon(name: "plus", size: 34, color: .darkText)
                    .frame(width: 72, height: 72)
                    .background(Color.sage)
                    .clipShape(Circle())
                    .shadow(color: Color.sage.opacity(0.24), radius: 16, x: 0, y: 8)
                    .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 10)
            }
            .buttonStyle(PressableButtonStyle(scale: 0.9))
            .accessibilityLabel("Log")
            .accessibilityIdentifier("tab-log")
            .zIndex(2)

            HStack(spacing: 0) {
                ForEach(trailingTabs, id: \.self) { tab in
                    tabButton(tab)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 68)
        }
        .frame(maxWidth: .infinity, minHeight: 68)
        .padding(.horizontal, 10)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule().stroke(Color.strokeStrong, lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 8)
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 14)
    }

    private func tabButton(_ tab: Tab) -> some View {
        Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 3) {
                AppIcon(
                    name: tab.icon,
                    size: 22,
                    color: selectedTab == tab ? .fgPrimary : .fgFaint
                )
                .scaleEffect(selectedTab == tab ? 1.14 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.58), value: selectedTab)
                Text(tab.label)
                    .font(DS.mono(10))
                    .tracking(0.4)
                    .textCase(.uppercase)
                    .foregroundColor(selectedTab == tab ? .fgPrimary : .fgFaint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .animation(.easeInOut(duration: 0.18), value: selectedTab)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PressableButtonStyle(scale: 0.88))
        .accessibilityLabel(tab.label)
        .accessibilityIdentifier("tab-\(tab.rawValue)")
    }
}

// MARK: - Quick Food Sheet

struct QuickFoodSheet: View {
    var appState: AppState
    @Binding var isPresented: Bool
    @State private var mealName = ""
    @State private var selectedTag: String? = nil
    let tags = ["Safe", "Trigger: dairy", "Trigger: spicy", "Unsure"]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHandle().frame(maxWidth: .infinity).padding(.vertical, 12)

            VStack(alignment: .leading, spacing: 4) {
                Text("QUICK MEAL")
                    .dsLabel()
                Text("What did you eat?")
                    .font(DS.serif(22))
                    .foregroundColor(.fgPrimary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            TextField("e.g. Turkey sandwich on sourdough", text: $mealName)
                .font(DS.sans(15))
                .foregroundColor(.fgPrimary)
                .padding(14)
                .background(Color.bgInset)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(tags, id: \.self) { t in
                        LogPill(title: t, isActive: selectedTag == t) {
                            selectedTag = selectedTag == t ? nil : t
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 16)

            PrimaryButton(title: "Save meal") {
                let title = mealName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Meal logged" : mealName
                appState.addLog(type: .food, title: title, sub: selectedTag ?? "Food pattern tracking")
                appState.showToast("Meal logged")
                isPresented = false
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(Color.bgElevated)
    }
}

// MARK: - Quick Bristol Sheet

struct QuickBristolSheet: View {
    var appState: AppState
    @Binding var isPresented: Bool
    @State private var selected = 4
    let labels = ["Hard lumps", "Lumpy", "Cracked", "Smooth", "Soft", "Mushy", "Watery"]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetHandle().frame(maxWidth: .infinity).padding(.vertical, 12)

            VStack(alignment: .leading, spacing: 4) {
                Text("BOWEL MOVEMENT")
                    .dsLabel()
                Text("Pick a Bristol type")
                    .font(DS.serif(22))
                    .foregroundColor(.fgPrimary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            HStack(spacing: 6) {
                ForEach(1...7, id: \.self) { i in
                    Button {
                        selected = i
                    } label: {
                        Text("\(i)")
                            .font(DS.mono(16, weight: .semibold))
                            .foregroundColor(selected == i ? .darkText : .fgPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(selected == i ? Color.sage : Color.bgInset)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)

            Text(labels[selected - 1])
                .font(DS.sans(13))
                .foregroundColor(.fgDim)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 16)

            PrimaryButton(title: "Save") {
                appState.recordBowel(bristol: selected, urgency: 3, blood: .none, mucus: false, pain: 0, nighttime: false)
                isPresented = false
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(Color.bgElevated)
    }
}

// MARK: - Check-In Sheet

struct CheckInSheet: View {
    var appState: AppState
    @Binding var isPresented: Bool
    @State private var status: MoodOption? = .ok
    @State private var pain = 3.0
    @State private var fatigue = 5.0
    @State private var urgency = 3.0
    @State private var stoolCount = 2.0
    @State private var bloodPresent = false
    @State private var medicationTaken = true
    @State private var notes = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                SheetHandle()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)

                VStack(alignment: .leading, spacing: 4) {
                    Text("TODAY CHECK-IN").dsLabel()
                    Text("Thirty-second gut check")
                        .font(DS.serif(24))
                        .foregroundColor(.fgPrimary)
                        .accessibilityIdentifier("checkin-sheet-title")
                    Text("Skip anything you do not want to answer.")
                        .font(DS.sans(13))
                        .foregroundColor(.fgDim)
                }

                FormCard(title: "Overall", label: status?.label.uppercased()) {
                    HStack(spacing: 8) {
                        ForEach(MoodOption.allCases, id: \.self) { option in
                            LogPill(title: option.label, isActive: status == option) {
                                status = status == option ? nil : option
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }

                sliderCard("Pain", value: $pain, color: .clay)
                sliderCard("Fatigue", value: $fatigue, color: .amber)
                sliderCard("Urgency", value: $urgency, color: .sage)
                sliderCard("Stool count today", value: $stoolCount, range: 0...20, color: .ink)

                FormCard(title: "Flags", label: "OPTIONAL") {
                    FlowLayout(spacing: 6) {
                        PillToggle(label: "Blood present", isActive: bloodPresent, color: .clay) { bloodPresent.toggle() }
                        PillToggle(label: "Medication taken", isActive: medicationTaken, color: .sage) { medicationTaken.toggle() }
                    }
                }

                FormCard(title: "Note", label: "OPTIONAL") {
                    TextField("Anything your doctor should know?", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                        .font(DS.sans(15))
                        .foregroundColor(.fgPrimary)
                        .padding(12)
                        .background(Color.bgInset)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                PrimaryButton(title: "Save check-in") {
                    appState.recordCheckIn(
                        status: status,
                        pain: Int(pain),
                        fatigue: Int(fatigue),
                        urgency: Int(urgency),
                        stoolCount: Int(stoolCount),
                        bloodPresent: bloodPresent,
                        medicationTaken: medicationTaken,
                        notes: notes
                    )
                    isPresented = false
                }
                .accessibilityIdentifier("checkin-save-button")

                GhostButton(title: "Skip for now") {
                    isPresented = false
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Color.bgElevated)
    }

    private func sliderCard(_ title: String, value: Binding<Double>, range: ClosedRange<Double> = 0...10, color: Color) -> some View {
        FormCard(title: title, label: "\(Int(value.wrappedValue))") {
            Slider(value: value, in: range, step: 1).tint(color)
        }
    }
}

#Preview {
    ContentView()
}
