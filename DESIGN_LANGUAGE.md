# Design Language Guide — PocketSmart Style

Use this document to apply the PocketSmart design language to a new SwiftUI app. Adapt all content/labels/icons to the actual app domain — the design patterns are what carries over, not the budgeting-specific terminology.

---

## Core Philosophy

- **Instagram-inspired social polish**: Clean cards, generous whitespace, readable typography, smooth spring animations.
- **SF Symbols only** — never use emoji in UI. Every icon is a system image.
- **Indigo-to-violet brand gradient** as the primary accent. Everything else uses semantic system colors.
- **Adaptive backgrounds**: Use `Color(.secondarySystemBackground)` for cards — respects dark/light mode automatically.
- **No emoji in code output**, no placeholder comments, no extra abstraction layers.

---

## 1. Design System File

Create `DesignSystem.swift` in the main target. This file holds everything below.

### 1.1 Brand Colors

```swift
extension Color {
    static let brandPrimary   = Color(red: 0.388, green: 0.400, blue: 0.945) // #6366F1 Indigo-500
    static let brandSecondary = Color(red: 0.545, green: 0.361, blue: 0.965) // #8B5CF6 Violet-500
    static let brandSuccess   = Color(red: 0.063, green: 0.725, blue: 0.506) // #10B981 Emerald-500
    static let brandWarning   = Color(red: 0.961, green: 0.620, blue: 0.043) // #F59E0B Amber-500
    static let brandDanger    = Color(red: 0.937, green: 0.267, blue: 0.267) // #EF4444 Red-500
}

// Required for foregroundStyle(.brandPrimary) syntax
extension ShapeStyle where Self == Color {
    static var brandPrimary:   Color { .init(red: 0.388, green: 0.400, blue: 0.945) }
    static var brandSecondary: Color { .init(red: 0.545, green: 0.361, blue: 0.965) }
    static var brandSuccess:   Color { .init(red: 0.063, green: 0.725, blue: 0.506) }
    static var brandWarning:   Color { .init(red: 0.961, green: 0.620, blue: 0.043) }
    static var brandDanger:    Color { .init(red: 0.937, green: 0.267, blue: 0.267) }
}
```

### 1.2 Gradients

```swift
struct AppGradient {
    static var brand: LinearGradient {
        LinearGradient(colors: [.brandPrimary, .brandSecondary],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var success: LinearGradient {
        LinearGradient(colors: [.brandSuccess, Color(red: 0.020, green: 0.588, blue: 0.400)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var sunset: LinearGradient {
        LinearGradient(colors: [Color(red: 0.988, green: 0.565, blue: 0.243),
                                Color(red: 0.937, green: 0.267, blue: 0.267)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var ocean: LinearGradient {
        LinearGradient(colors: [Color(red: 0.235, green: 0.741, blue: 0.980),
                                Color(red: 0.388, green: 0.400, blue: 0.945)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var mint: LinearGradient {
        LinearGradient(colors: [Color(red: 0.200, green: 0.850, blue: 0.706),
                                Color(red: 0.063, green: 0.725, blue: 0.506)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
```

---

## 2. Core Components

### 2.1 Card Style

Every content card uses `cardStyle()`. Apply it to the outermost container of a card.

```swift
struct CardStyle: ViewModifier {
    var cornerRadius: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

extension View {
    func cardStyle(cornerRadius: CGFloat = 16) -> some View {
        modifier(CardStyle(cornerRadius: cornerRadius))
    }
}
```

**Usage pattern:**
```swift
VStack(spacing: 12) {
    // content
}
.padding(16)
.cardStyle()
.padding(.horizontal, 20)
```

### 2.2 Primary Button

Full-width gradient CTA. Used for all primary actions in sheets and auth flows.

```swift
struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var isLoading: Bool = false
    var gradient: LinearGradient = AppGradient.brand
    let action: () -> Void

    init(_ title: String, icon: String? = nil, isLoading: Bool = false,
         gradient: LinearGradient = AppGradient.brand, action: @escaping () -> Void) {
        self.title = title; self.icon = icon
        self.isLoading = isLoading; self.gradient = gradient; self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaleEffect(0.85)
                } else {
                    if let icon { Image(systemName: icon).font(.system(size: 15, weight: .semibold)) }
                    Text(title).fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity).frame(height: 54)
            .foregroundStyle(.white)
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(isLoading)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}
```

### 2.3 Progress Bar

Animated, capsule-shaped progress bar with spring animation.

```swift
struct ProgressBar: View {
    var value: Double       // 0.0 … 1.0
    var color: Color = .brandPrimary
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(color.opacity(0.12))
                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * min(value, 1))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: value)
            }
        }
        .frame(height: height)
    }
}
```

- Use `height: 8` for primary progress bars (budget, main progress)
- Use `height: 6` for card-level progress bars
- Use `height: 5` for compact/mini progress bars
- Use `height: 4` for dense list rows

### 2.4 Icon Badge (Rounded Square)

Rounded square with tinted background and SF Symbol. Used for categories, settings rows, and any icon-with-label pattern.

```swift
// General-purpose badge
ZStack {
    RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
        .fill(color.opacity(0.12))
    Image(systemName: iconName)
        .font(.system(size: size * 0.42, weight: .medium))
        .foregroundStyle(color)
}
.frame(width: size, height: size)
```

- `size: 30` — settings rows
- `size: 44` — standard list rows
- `size: 52` — goal/item cards
- `size: 28` — compact inline usage

### 2.5 User Avatar

Initials-based circular avatar with deterministic color assignment. No photo uploads needed.

```swift
struct UserAvatarView: View {
    let name: String
    var size: CGFloat = 44

    private var initials: String {
        let parts = name.split(separator: " ").filter { !$0.isEmpty }
        if parts.count >= 2 {
            return (String(parts[0].prefix(1)) + String(parts[1].prefix(1))).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private var bgColor: Color {
        let palette: [Color] = [
            .init(red: 0.388, green: 0.400, blue: 0.945),
            .init(red: 0.545, green: 0.361, blue: 0.965),
            .init(red: 0.063, green: 0.725, blue: 0.506),
            .init(red: 0.235, green: 0.510, blue: 0.960),
            .init(red: 0.960, green: 0.380, blue: 0.600),
            .init(red: 0.988, green: 0.480, blue: 0.243),
            .init(red: 0.200, green: 0.780, blue: 0.720),
        ]
        let hash = name.unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) }
        return palette[abs(hash) % palette.count]
    }

    var body: some View {
        ZStack {
            Circle().fill(bgColor)
            Text(initials)
                .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}
```

- `size: 88` — profile header
- `size: 46` — card-level
- `size: 44` — standard list row
- `size: 34` — nav bar trailing item

### 2.6 Section Header

Consistent section label used before groups of cards.

```swift
struct SectionHeader: View {
    let title: String
    var count: Int? = nil
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center) {
            Text(title).font(.title3).fontWeight(.bold)
            if let count {
                Text("\(count)")
                    .font(.caption).fontWeight(.semibold)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Color.brandPrimary.opacity(0.1))
                    .foregroundStyle(.brandPrimary)
                    .clipShape(Capsule())
            }
            Spacer()
            if let label = actionLabel, let action {
                Button(action: action) {
                    Text(label).font(.subheadline).foregroundStyle(.brandPrimary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
}
```

### 2.7 Settings Row

Apple Settings-style tappable row with colored icon badge, label, and chevron.

```swift
struct SettingsRow: View {
    let icon: String
    let label: String
    var subtitle: String? = nil
    let color: Color
    var action: (() -> Void)? = nil

    var body: some View {
        Button { action?() } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                VStack(alignment: .leading, spacing: 1) {
                    Text(label).font(.subheadline)
                    if let sub = subtitle {
                        Text(sub).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2).foregroundStyle(.quaternary)
            }
            .padding(.horizontal, 16).padding(.vertical, 13)
        }
        .buttonStyle(.plain)
    }
}
```

**Settings section pattern:**
```swift
VStack(alignment: .leading, spacing: 8) {
    Text("Section Title")
        .font(.caption).fontWeight(.semibold)
        .foregroundStyle(.secondary)
        .textCase(.uppercase)
        .tracking(0.5)
        .padding(.horizontal, 20)

    VStack(spacing: 0) {
        SettingsRow(icon: "...", label: "...", color: .brandPrimary) { }
        Divider().padding(.leading, 58)
        SettingsRow(icon: "...", label: "...", color: .blue) { }
    }
    .cardStyle()
    .padding(.horizontal, 20)
}
```

### 2.8 Filter Chip

Horizontal-scrolling pill filter for lists.

```swift
struct FilterChip: View {
    let label: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline).fontWeight(.semibold)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .foregroundStyle(selected ? .white : .primary)
                .background(selected ? Color.brandPrimary : Color(.tertiarySystemFill))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// Usage:
ScrollView(.horizontal, showsIndicators: false) {
    HStack(spacing: 10) {
        FilterChip(label: "All",    selected: filter == nil)     { filter = nil }
        FilterChip(label: "Type A", selected: filter == .typeA)  { filter = .typeA }
        FilterChip(label: "Type B", selected: filter == .typeB)  { filter = .typeB }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 10)
}
```

---

## 3. Screen Patterns

### 3.1 Hero/Highlight Card

The most important metric goes in a full-bleed gradient card at the top of the main screen. Secondary stats sit below a divider inside the same card.

```swift
ZStack(alignment: .topLeading) {
    AppGradient.brand
    // Decorative circle
    Circle()
        .fill(.white.opacity(0.06))
        .frame(width: 200)
        .offset(x: 160, y: -60)

    VStack(alignment: .leading, spacing: 0) {
        Text("Primary metric label")
            .font(.caption)
            .foregroundStyle(.white.opacity(0.7))
            .padding(.bottom, 6)

        Text(primaryValue)
            .font(.system(size: 40, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.bottom, 20)

        Divider()
            .overlay(.white.opacity(0.2))
            .padding(.bottom, 16)

        HStack(spacing: 0) {
            StatItem(label: "Stat A", value: valueA)
            Spacer()
            StatItem(label: "Stat B", value: valueB, alignment: .trailing)
        }
    }
    .padding(24)
}
.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
.padding(.horizontal, 20)
```

**Rule**: Show the most user-meaningful outcome as the big number (e.g., what they've saved or earned), not raw input data.

### 3.2 Stats Strip

Three equal-width stats in a horizontal card. Used on profile/summary screens.

```swift
HStack(spacing: 0) {
    StatCell(label: "Label A", value: "Value A")
    Divider().frame(height: 36)
    StatCell(label: "Label B", value: "Value B")
    Divider().frame(height: 36)
    StatCell(label: "Label C", value: "Value C")
}
.padding(.vertical, 14)
.cardStyle()
.padding(.horizontal, 20)

private struct StatCell: View {
    let label: String
    let value: String
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.subheadline).fontWeight(.bold)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
```

### 3.3 Dashboard / Main List Screen

Standard layout for a scrollable list screen with a FAB (floating action button):

```swift
NavigationStack {
    ScrollView {
        VStack(spacing: 0) {
            // Hero card
            heroCard
                .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 24)
                .opacity(animateCards ? 1 : 0).offset(y: animateCards ? 0 : 16)

            // Sections
            SectionHeader(title: "Section")
            // section content
                .opacity(animateCards ? 1 : 0).offset(y: animateCards ? 0 : 16)
        }
    }
    .navigationBarTitleDisplayMode(.inline)
    .toolbar { /* leading: greeting/title, trailing: avatar */ }
    .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 80) } // clears FAB
    .overlay(alignment: .bottomTrailing) {
        Button { showAdd = true } label: {
            Image(systemName: "plus")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(AppGradient.brand)
                .clipShape(Circle())
                .shadow(color: .brandPrimary.opacity(0.35), radius: 10, y: 4)
        }
        .padding(.trailing, 24).padding(.bottom, 24)
    }
    .sheet(isPresented: $showAdd) { AddItemView() }
}
.onAppear {
    withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.05)) {
        animateCards = true
    }
}
```

**Always add `.safeAreaInset(edge: .bottom) { Color.clear.frame(height: 80) }` when there is a FAB** — this prevents the last list item from being hidden behind it.

### 3.4 Navigation Bar with Greeting

The home tab's nav bar uses a two-line greeting on the leading side and an avatar on the trailing side:

```swift
.toolbar {
    ToolbarItem(placement: .topBarLeading) {
        VStack(alignment: .leading, spacing: 1) {
            Text(Date().greeting)         // "Good morning"
                .font(.caption).foregroundStyle(.secondary)
            Text(user.firstName ?? "there")
                .font(.headline).fontWeight(.bold)
        }
    }
    ToolbarItem(placement: .topBarTrailing) {
        UserAvatarView(name: user.name, size: 34)
    }
}
```

```swift
// Add to DesignSystem.swift
extension Date {
    var greeting: String {
        switch Calendar.current.component(.hour, from: self) {
        case 0..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }
}
```

### 3.5 Tab Bar

Five tabs, uniform for all users. `.tint(.brandPrimary)` gives selected tabs the brand color.

```swift
struct MainTabView: View {
    @State private var selectedTab = 0
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home",        systemImage: "house.fill") }.tag(0)
            SecondView()
                .tabItem { Label("Second",      systemImage: "...") }.tag(1)
            ThirdView()
                .tabItem { Label("Third",       systemImage: "...") }.tag(2)
            FourthView()
                .tabItem { Label("Fourth",      systemImage: "...") }.tag(3)
            ProfileView()
                .tabItem { Label("Profile",     systemImage: "person.crop.circle.fill") }.tag(4)
        }
        .tint(.brandPrimary)
    }
}
```

**Profile is always the rightmost tab.** Secondary screens (settings, sub-features) live as navigation destinations inside ProfileView, not as separate tabs.

### 3.6 Profile Screen

Instagram-style profile: large avatar + name/badge at top, stats strip, then settings sections.

```swift
NavigationStack {
    ScrollView {
        VStack(spacing: 0) {
            profileHeader.padding(.bottom, 24)
            statsStrip.padding(.horizontal, 20).padding(.bottom, 28)
            settingsSection(title: "Account") { /* rows */ }.padding(.bottom, 16)
            settingsSection(title: "About")   { /* rows */ }.padding(.bottom, 24)
            // Sign out button
            // Version string: Text("AppName v1.0").font(.caption2).foregroundStyle(.quaternary)
        }
        .padding(.top, 8)
    }
    .navigationTitle("Profile")
    .navigationDestination(isPresented: $showSubScreen) { SubScreenView() }
    .sheet(isPresented: $showEdit) { EditProfileView() }
}
```

Profile header structure:
```swift
VStack(spacing: 16) {
    ZStack(alignment: .bottomTrailing) {
        UserAvatarView(name: user.name, size: 88)
        // Edit pencil badge at bottom-right of avatar
        Button { showEdit = true } label: {
            ZStack {
                Circle().fill(Color(.systemBackground)).frame(width: 28, height: 28)
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 26)).foregroundStyle(.brandPrimary)
            }
        }
        .offset(x: 2, y: 2)
    }
    VStack(spacing: 6) {
        Text(user.name).font(.title3).fontWeight(.bold)
        Text(user.email).font(.caption).foregroundStyle(.secondary)
        // Role/type badge:
        Text(user.roleName)
            .font(.caption2).fontWeight(.semibold)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(Color.brandPrimary.opacity(0.1))
            .foregroundStyle(.brandPrimary)
            .clipShape(Capsule())
    }
}
.frame(maxWidth: .infinity)
.padding(.vertical, 24)
```

### 3.7 Welcome / Onboarding Screen

Full-screen gradient background with decorative circles, animated entrance.

```swift
ZStack {
    AppGradient.brand.ignoresSafeArea()

    // Decorative blobs
    GeometryReader { geo in
        Circle().fill(.white.opacity(0.07)).frame(width: 320)
            .offset(x: geo.size.width * 0.55, y: -60)
        Circle().fill(.white.opacity(0.05)).frame(width: 240)
            .offset(x: -60, y: geo.size.height * 0.6)
    }

    VStack(spacing: 0) {
        Spacer()
        // App icon
        ZStack {
            Circle().fill(.white.opacity(0.18)).frame(width: 96, height: 96)
            Image(systemName: "YOUR_APP_ICON_SYMBOL")
                .font(.system(size: 44)).foregroundStyle(.white)
        }
        .scaleEffect(animateIn ? 1 : 0.6).opacity(animateIn ? 1 : 0)

        // Tagline
        VStack(spacing: 10) {
            Text("AppName")
                .font(.system(size: 38, weight: .bold, design: .rounded)).foregroundStyle(.white)
            Text("Your short tagline\nhere.")
                .font(.title3).multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.85))
        }
        .offset(y: animateIn ? 0 : 20).opacity(animateIn ? 1 : 0)

        Spacer()

        // Feature pills
        HStack(spacing: 12) {
            FeaturePill(icon: "...", label: "Feature A")
            FeaturePill(icon: "...", label: "Feature B")
            FeaturePill(icon: "...", label: "Feature C")
        }
        .offset(y: animateIn ? 0 : 30).opacity(animateIn ? 1 : 0)

        Spacer().frame(height: 48)

        // CTAs
        VStack(spacing: 14) {
            Button { showSignUp = true } label: {
                Text("Get Started")
                    .fontWeight(.bold).frame(maxWidth: .infinity).frame(height: 56)
                    .foregroundStyle(.brandPrimary).background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            Button { showSignIn = true } label: {
                Text("I already have an account")
                    .fontWeight(.semibold).frame(maxWidth: .infinity).frame(height: 52)
                    .foregroundStyle(.white)
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.5), lineWidth: 1.5))
            }
        }
        .padding(.horizontal, 28)
        .offset(y: animateIn ? 0 : 40).opacity(animateIn ? 1 : 0)
        Spacer().frame(height: 48)
    }
}
.onAppear {
    withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1)) { animateIn = true }
}
.fullScreenCover(isPresented: $showSignUp) { SignUpView() }
.fullScreenCover(isPresented: $showSignIn) { SignInView() }

// FeaturePill component:
struct FeaturePill: View {
    let icon: String; let label: String
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption)
            Text(label).font(.caption).fontWeight(.semibold)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .foregroundStyle(.white).background(.white.opacity(0.18)).clipShape(Capsule())
    }
}
```

### 3.8 Empty State

Consistent empty state pattern for lists with no data:

```swift
VStack(spacing: 20) {
    Spacer().frame(height: 40)
    ZStack {
        Circle().fill(Color.brandPrimary.opacity(0.08)).frame(width: 96, height: 96)
        Image(systemName: "YOUR_SYMBOL")
            .font(.system(size: 40)).foregroundStyle(.brandPrimary.opacity(0.6))
    }
    VStack(spacing: 8) {
        Text("Nothing here yet").font(.title2).fontWeight(.bold)
        Text("Describe what the user should do to get started.")
            .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
    }
    PrimaryButton("Primary Action", icon: "plus") { showCreate = true }
        .padding(.horizontal, 40)
}
```

### 3.9 Grouped List with Search

For full-screen list views with search, grouping, and swipe-to-delete:

```swift
NavigationStack {
    VStack(spacing: 0) {
        // Filter chips (optional)
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) { /* FilterChip instances */ }
            .padding(.horizontal, 20).padding(.vertical, 10)
        }

        List {
            ForEach(groupedItems, id: \.key) { section in
                Section(header:
                    Text(section.key)
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(.secondary).textCase(nil)
                ) {
                    ForEach(section.value) { item in
                        ItemRow(item: item)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(
                                Color(.secondarySystemBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            )
                    }
                    .onDelete { offsets in deleteItems(in: section.value, at: offsets) }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
    .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search ...")
    .navigationTitle("Title")
    .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
            Button { showAdd = true } label: {
                Image(systemName: "plus.circle.fill").font(.title3).foregroundStyle(.brandPrimary)
            }
        }
    }
}
```

### 3.10 Standard List Row

```swift
HStack(spacing: 12) {
    // Icon badge (44pt)
    ZStack {
        RoundedRectangle(cornerRadius: 12, style: .continuous).fill(color.opacity(0.12))
        Image(systemName: iconName).font(.system(size: 18, weight: .medium)).foregroundStyle(color)
    }
    .frame(width: 44, height: 44)

    VStack(alignment: .leading, spacing: 2) {
        Text(primaryLabel).font(.subheadline).fontWeight(.medium).lineLimit(1)
        Text(secondaryLabel).font(.caption).foregroundStyle(.secondary)
    }
    Spacer()
    Text(trailingValue).font(.subheadline).fontWeight(.semibold)
}
.padding(.horizontal, 14).padding(.vertical, 12)
```

### 3.11 Sheet / Form Pattern

Sheets for creation/editing follow a consistent structure:

```swift
NavigationStack {
    ScrollView {    // or VStack(spacing: 24) if short
        VStack(spacing: 24) {
            // Section header (optional)
            VStack(spacing: 8) {
                Text("Sheet Title").font(.title3).fontWeight(.bold)
                Text("Subtitle or instruction.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)

            // Form field
            VStack(alignment: .leading, spacing: 8) {
                Text("Field Label").font(.subheadline).fontWeight(.semibold)
                TextField("Placeholder", text: $value)
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            // Inline error
            if let err = localError {
                Text(err).font(.footnote).foregroundStyle(.brandDanger)
            }

            PrimaryButton("Save", isLoading: vm.isLoading) { save() }
            Spacer()
        }
        .padding(24)
    }
    .navigationTitle("Sheet Name")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
        ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
    }
    .scrollDismissesKeyboard(.interactively)   // important for forms
    .onChange(of: vm.savedItem) { _, item in   // auto-dismiss on success
        if item != nil { dismiss() }
    }
}
```

---

## 4. Typography Rules

| Context | Font |
|---|---|
| Screen hero number | `.system(size: 40, weight: .bold, design: .rounded)` |
| Navigation/card title | `.title3` + `.fontWeight(.bold)` |
| Section header | `.title3` + `.fontWeight(.bold)` |
| Card label | `.subheadline` + `.fontWeight(.semibold)` |
| Body text | `.subheadline` |
| Secondary text | `.caption` + `.foregroundStyle(.secondary)` |
| Tertiary / hint text | `.caption2` + `.foregroundStyle(.tertiary)` |
| Settings section label | `.caption` + `.fontWeight(.semibold)` + `.textCase(.uppercase)` + `.tracking(0.5)` |
| Monospaced input (codes) | `.system(size: 32, weight: .bold, design: .monospaced)` |
| Version string | `.caption2` + `.foregroundStyle(.quaternary)` |

---

## 5. Spacing & Layout Constants

| Use | Value |
|---|---|
| Screen horizontal padding | `20pt` |
| Card internal padding | `16pt` (compact: `14pt`) |
| Sheet/form padding | `24pt` |
| Between major sections | `24pt` |
| Between cards in a section | `12pt` |
| Nav bar content below top | `8pt` (`.padding(.top, 8)` on scroll VStack) |
| FAB safe area clearance | `80pt` (.safeAreaInset height) |
| FAB bottom/trailing padding | `24pt` each |
| FAB circle size | `56pt` |
| Form field height (PrimaryButton) | `54pt` |
| Welcome screen CTA height | `56pt` (primary) / `52pt` (secondary) |

---

## 6. Animation Patterns

### Card entrance animation
```swift
@State private var animateCards = false

// Apply to each card:
.opacity(animateCards ? 1 : 0)
.offset(y: animateCards ? 0 : 16)

// Trigger in .onAppear:
withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.05)) {
    animateCards = true
}
```

### Welcome screen entrance
```swift
withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1)) {
    animateIn = true
}
```

### Toggle expand/collapse
```swift
withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
    showSection.toggle()
}
```

### Circular progress ring on cards
```swift
Circle()
    .trim(from: 0, to: goal.progress)
    .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
    .rotationEffect(.degrees(-90))
    .animation(.spring(response: 0.6), value: goal.progress)
```

---

## 7. Color Usage Rules

| Semantic use | Color |
|---|---|
| Primary actions, selected state, tint | `.brandPrimary` |
| Secondary accent, badges | `.brandSecondary` |
| Success, positive values, completion | `.brandSuccess` |
| Warnings, attention | `.brandWarning` |
| Errors, destructive actions, danger | `.brandDanger` |
| Card backgrounds | `Color(.secondarySystemBackground)` |
| Input field backgrounds | `Color(.secondarySystemBackground)` |
| Dividers inside cards | `Divider().padding(.leading, 58)` |
| Subtle tinted fill | `color.opacity(0.1)` or `0.12` |
| Hero gradient background | `AppGradient.brand` |

**Positive values** (gains, completions) → `.brandSuccess` with `"+"` prefix  
**Negative values** (losses, expenses) → `Color.primary` (not red, to avoid alarming users) or `.brandDanger` only when explicitly negative/over-budget

---

## 8. Navigation Patterns

### Pushing a sub-screen from Profile
```swift
// In ProfileView — do NOT use NavigationLink directly, use state + destination:
@State private var showSubScreen = false

SettingsRow(icon: "...", label: "Sub Screen", color: .brandPrimary) { showSubScreen = true }

.navigationDestination(isPresented: $showSubScreen) { SubScreenView() }
```

### Sub-screen pushed inside a NavigationStack
When a view is always pushed (never presented as a root), use `Group` instead of `NavigationStack` as the body wrapper. Keep `.navigationTitle`, `.toolbar`, and `.sheet` modifiers — they work correctly inside a parent stack:

```swift
var body: some View {
    Group {
        if isLoading { ProgressView() }
        else if items.isEmpty { emptyState }
        else { contentList }
    }
    .navigationTitle("Sub Screen")
    .toolbar { /* ... */ }
    .sheet(isPresented: $showSheet) { /* ... */ }
}
```

### Sheets
- Use `@Environment(\.dismiss)` to dismiss from within the sheet
- Auto-dismiss when async work completes via `.onChange`:
```swift
.onChange(of: vm.createdItem) { _, item in
    if item != nil { dismiss() }
}
```
- Never call `dismiss()` synchronously in a button action that triggers async work

---

## 9. Helper Extensions

Add to DesignSystem.swift:

```swift
extension Double {
    func currencyString() -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency; f.currencyCode = "USD"; f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: self)) ?? "$\(self)"
    }
    func percentString() -> String { "\(Int((self * 100).rounded()))%" }
}

extension Date {
    func dateString(_ format: String) -> String {
        let f = DateFormatter(); f.dateFormat = format; return f.string(from: self)
    }
    var relativeLabel: String {
        if Calendar.current.isDateInToday(self)     { return "Today" }
        if Calendar.current.isDateInYesterday(self) { return "Yesterday" }
        return dateString("MMM d")
    }
    var greeting: String {
        switch Calendar.current.component(.hour, from: self) {
        case 0..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }
}
```

---

## 10. Input Validation Pattern

All user-facing text fields sanitize input before use:

```swift
struct InputValidator {
    static func sanitize(_ input: String, maxLength: Int) -> String {
        String(input.trimmingCharacters(in: .whitespacesAndNewlines).prefix(maxLength))
    }
    static func isValidName(_ value: String) -> Bool {
        value.count >= 2 && value.count <= 50
    }
    static func isValidInviteCode(_ value: String) -> Bool {
        value.count == 6 && value.allSatisfy { $0.isLetter || $0.isNumber }
    }
}

// Enforce max length in TextField onChange:
.onChange(of: name) { _, v in if v.count > 50 { name = String(v.prefix(50)) } }
```

---

## 11. What NOT to Do

- Do not use emoji anywhere in the UI
- Do not use `NavigationLink` label wrappers on buttons — use `navigationDestination(isPresented:)` with state
- Do not nest `NavigationStack` inside a view that is already pushed by a parent `NavigationStack`
- Do not call `dismiss()` synchronously in a button action that starts an async operation — wait for success via `.onChange`
- Do not use `.listRowSeparator(.visible)` — always hide separators and use card backgrounds instead
- Do not use `.tint` per-button — set it once on the `TabView`
- Do not add `.safeAreaInset` unless there is a FAB or persistent overlay that would obscure content
- Do not use `UIColor` directly — always use `Color(.systemBackground)` etc.
