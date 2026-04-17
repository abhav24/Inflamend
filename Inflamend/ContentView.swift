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
        case .chat:     return "Ask"
        case .profile:  return "You"
        }
    }
    var icon: String {
        switch self {
        case .home:     return "home"
        case .log:      return "plus"
        case .insights: return "chart"
        case .chat:     return "chat"
        case .profile:  return "user"
        }
    }
}

struct ContentView: View {
    @State private var appState = AppState()
    @State private var selectedTab: Tab = .home
    @State private var showFoodSheet = false
    @State private var showBristolSheet = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.bgPrimary.ignoresSafeArea()

            // Screen content
            Group {
                switch selectedTab {
                case .home:
                    HomeView(
                        appState: appState,
                        selectedTab: $selectedTab,
                        showFoodSheet: $showFoodSheet,
                        showBristolSheet: $showBristolSheet
                    )
                case .log:
                    LogView(appState: appState)
                case .insights:
                    InsightsView()
                case .chat:
                    ChatView(appState: appState)
                case .profile:
                    ProfileView(appState: appState)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Leave space for tab bar
            .padding(.bottom, 88)

            // Custom tab bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .overlay(alignment: .top) {
            if let msg = appState.toast {
                ToastView(message: msg)
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
        .preferredColorScheme(.dark)
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: Tab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 3) {
                        AppIcon(
                            name: tab.icon,
                            size: 22,
                            color: selectedTab == tab ? .fgPrimary : .fgFaint
                        )
                        Text(tab.label)
                            .font(DS.mono(10))
                            .tracking(0.8)
                            .textCase(.uppercase)
                            .foregroundColor(selectedTab == tab ? .fgPrimary : .fgFaint)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 68)
        .padding(.horizontal, 10)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule().stroke(Color.strokeStrong, lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 8)
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 18)
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
                            .font(DS.mono(18, weight: .semibold))
                            .foregroundColor(selected == i ? .darkText : .fgPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
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
                appState.showToast("Bristol type \(selected) · saved")
                isPresented = false
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(Color.bgElevated)
    }
}

#Preview {
    ContentView()
}
