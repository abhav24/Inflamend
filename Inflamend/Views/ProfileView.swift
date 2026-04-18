import SwiftUI

struct ProfileView: View {
    var appState: AppState

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Header
                ScreenHeader(subtitle: "YOUR ACCOUNT", title: "Hello, ", titleItalicSuffix: "Priya")

                // Profile card
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.sage, .amber], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 60, height: 60)
                        Text("P")
                            .font(DS.serif(28))
                            .foregroundColor(.darkText)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Priya Raman")
                            .font(DS.sans(18))
                            .foregroundColor(.fgPrimary)
                            .tracking(-0.15)
                        Text("Diagnosed with UC · 2022")
                            .font(DS.sans(13))
                            .foregroundColor(.fgDim)
                    }
                    Spacer()
                    Button { } label: {
                        Text("Edit")
                            .font(DS.sans(13, weight: .medium))
                            .foregroundColor(.fgPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.bgInset)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .card()
                .padding(.horizontal, 20)
                .padding(.bottom, 14)

                // Stats row
                HStack {
                    ProfileStat(value: "147", label: "Days logged")
                    Rectangle().fill(Color.strokeDefault).frame(width: 0.5).padding(.vertical, 4)
                    ProfileStat(value: "18",  label: "Since flare")
                    Rectangle().fill(Color.strokeDefault).frame(width: 0.5).padding(.vertical, 4)
                    ProfileStat(value: "92%", label: "Med streak")
                }
                .padding(18)
                .background(Color.bgCard)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.strokeDefault, lineWidth: 0.5))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 20)
                .padding(.bottom, 14)

                // Health section
                SectionLabel("HEALTH")
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)

                VStack(spacing: 0) {
                    ProfileRow(icon: "download", label: "Export 30-day PDF report", sub: "Share with your GI")     { appState.showToast("Preparing report…") }
                    ProfileRow(icon: "bell",     label: "Medication reminders",     sub: "4 active")
                    ProfileRow(icon: "calendar", label: "Menstrual tracking",       sub: "On")
                    ProfileRow(icon: "heart",    label: "Flare history",            sub: "2 flares recorded", isLast: true)
                }
                .background(Color.bgCard)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.strokeDefault, lineWidth: 0.5))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 20)
                .padding(.bottom, 14)

                // App section
                SectionLabel("APP")
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)

                VStack(spacing: 0) {
                    ProfileRow(icon: "sparkle",  label: "AI memory",    sub: "Your chat context")
                    ProfileRow(icon: "settings", label: "Preferences")
                    ProfileRow(icon: "book",     label: "IBD library",  sub: "Guided articles")
                    ProfileRow(icon: "logout",   label: "Sign out",     isDanger: true, isLast: true) {
                        appState.showToast("Signed out")
                    }
                }
                .background(Color.bgCard)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.strokeDefault, lineWidth: 0.5))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 20)
                .padding(.bottom, 24)

                Text("INFLAMEND v2.4.0 · BUILD 184")
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
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

#Preview {
    ProfileView(appState: AppState())
        .background(Color.bgPrimary)
        .preferredColorScheme(.dark)
}
