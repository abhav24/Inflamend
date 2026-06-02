# Inflamend

A native iOS health tracking and AI companion app for people living with Inflammatory Bowel Disease (IBD), specifically Ulcerative Colitis. Inflamend helps patients log daily health data, monitor flare risk, summarize food and lifestyle patterns, and review careful local insights — all in a dark, minimal, medically-informed UI.

---

## What It Does

- **Flare Risk Score** — AI-driven 0–100 risk indicator updated from logged data, shown as an animated ring on the home screen
- **Daily Logging** — 7-category logging system: food, bowel movements (Bristol scale), symptoms, medications, sleep, weight, and rapid check-ins
- **Food Pattern Summaries** — Summarizes local meal logs by frequency without making trigger or causation claims
- **Insights & Charts** — Local-log trend summaries, empty states, pain heatmap, bowel-log chart, and food frequency list
- **AI Chat** — In-app assistant ("Ask Inflamend") for medication questions, dietary advice, and symptom explanation
- **Medication Tracking** — Daily schedule with check-off, streak tracking, and reminder support
- **Profile & Export** — Saved-log stats, medication status, and a shareable local doctor report

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Language | Swift 5.9+ |
| Framework | SwiftUI 6 (`@Observable` macro) |
| Min iOS | 17.0 |
| State | Centralized `AppState` with `@Observable` / `@MainActor` |
| Charts | Pure SwiftUI (`Path`, `GeometryReader`) — no external library |
| Navigation | Custom floating tab bar (no `NavigationStack`) |
| Assets | SF Symbols only — no custom images |
| Backend | Supabase schema/RLS/Edge Function scaffolds; iOS app still uses mock/local state |
| Dependencies | None (no Swift packages, no CocoaPods) |
| Tests | Xcode unit test target `InflamendTests` |

Dark mode only. No external dependencies.

---

## Current Local Commands

This repository currently builds and tests on the available `iPhone 17` iOS 26.0 simulator. The originally requested `iPhone 16` simulator is not installed on this machine.

```bash
xcodebuild -list
xcodebuild clean build -scheme Inflamend -destination 'platform=iOS Simulator,name=iPhone 17'
xcodebuild test -scheme Inflamend -destination 'platform=iOS Simulator,name=iPhone 17'
```

Current test coverage is focused on deterministic health logic:

- Red-flag detection.
- Risk scoring.
- Voice transcript parsing.
- Medication schedule calculations.
- Local doctor report export content.
- Report summary wording.
- Local Care safety responses.
- Validation helpers.

Supabase backend files are scaffolded under `supabase/`, but local migration/function verification requires installing the Supabase CLI and Deno.

---

## Architecture

```
Inflamend/
├── InflamendApp.swift        # @main entry, forces dark color scheme
├── ContentView.swift         # Root: tab switcher + custom tab bar + sheets
├── Models.swift              # AppState, LogEntry, ChatMessage, enums
├── DesignSystem.swift        # Color tokens, typography, reusable components
└── Views/
    ├── HomeView.swift        # Dashboard: risk ring, mood check-in, timeline
    ├── LogView.swift         # 7-tab logging interface
    ├── InsightsView.swift    # Local-log summaries, charts, heatmap, and empty states
    ├── ChatView.swift        # AI assistant chat UI
    └── ProfileView.swift     # Account, stats, settings
```

### State Management

All UI state is coordinated through a single `AppState` class (no Combine, no Redux). It's declared with `@Observable` and annotated `@MainActor`. Views create it at the root and pass it down via `@State` / `@Binding`.

`AppState` now also owns local scaffolds for auth, onboarding, privacy preferences, logs, chat messages, risk state, snapshot restore, and a pending sync mutation queue. `AppSnapshotStore` writes JSON to Application Support with iOS file protection while the Supabase worker remains externally blocked.

```swift
@Observable @MainActor
class AppState {
    var authSession: AuthSession?
    var onboardingProfile: OnboardingProfile?
    var riskScore: Int = 42
    var mood: MoodOption?
    var medsTaken: Int = 2
    var medsTotal: Int = 4
    var pendingSyncMutations: [PendingSyncMutation] = []
    var logs: [LogEntry] = []
    var chatMessages: [ChatMessage] = [...]
    var toast: String?

    func signUp(email: String, displayName: String)
    func completeOnboarding(...)
    func addLog(type: LogType, title: String, sub: String)
    func retryPendingSyncScaffold()
}
```

### Navigation

No `NavigationStack`. A custom `Tab` enum drives a `ZStack` switch inside `ContentView`. The floating tab bar is a capsule with `.ultraThinMaterial` glassmorphism, 20px shadow, spring scale animation on active tab.

---

## Design System (`DesignSystem.swift`)

### Color Palette (Warm Dark Theme)

| Token | Hex | Usage |
|-------|-----|-------|
| `bgPrimary` | `#141210` | App background |
| `bgElevated` | — | Cards, sheets |
| `bgCard` | — | Inner card surfaces |
| `fgPrimary` | `#F6F1E4` | Headings, primary text |
| `fgDim` | 62% opacity | Secondary text |
| `fgFaint` | 38% opacity | Labels, hints |
| `fgGhost` | 18% opacity | Dividers, placeholders |
| `sage` | `#A8B89A` | Safe / positive / buttons |
| `amber` | `#E3A963` | Caution / medium risk |
| `clay` | `#D98466` | Alerts / rust accent |
| `ink` | `#8A94A2` | Medication / neutral |
| `riskHigh` | `#D96A52` | High flare risk |
| `darkText` | `#1A1612` | Text on light backgrounds |

### Typography

- **Serif (Georgia)** — headings, risk score number
- **Mono (Courier New)** — labels, data values, tab names
- **Sans (System)** — body text, form inputs

### Reusable Components

| Component | Description |
|-----------|-------------|
| `RiskRing` | Animated circular progress (0–100), color-coded by severity |
| `MiniRing` | Small ring for medication adherence |
| `PrimaryButton` | Sage green pill button with press spring animation |
| `GhostButton` | Transparent variant |
| `LogPill` | Toggle pill (selected = colored background) |
| `DSChip` / `DSTag` | Micro-label components |
| `AppIcon` | Maps custom names to SF Symbols |
| `IconBadge` | SF Symbol in colored circle |
| `ToastView` | Slide-in notification, 2.2s auto-dismiss |
| `ScreenHeader` | Consistent title + subtitle pattern |
| `FlowLayout` | Custom `Layout` for wrapping pill tags |

### ViewModifiers

```swift
.card()              // rounded card with stroke + elevated background
.dsLabel()           // mono, uppercase, faint foreground
.appearAnimation(delay: 0.2)  // opacity + Y-offset fade-in
```

---

## Screens

### Home (`HomeView.swift`)

- Greeting with time-of-day prefix and user name
- **Flare Risk Card**: `RiskRing` at 164pt, risk label, data source caption
- **Today Summary**: 4 mini-stat rows (symptoms, meds, water, sleep)
- **Mood Check-in**: 4 options (great/ok/rough/flare), color-coded, persists in AppState
- **Rapid Log Row**: Water, meal, meds, BM quick-log buttons → trigger sheets
- **Timeline**: Chronological `LogEntry` list with icon badges
- **AI Insight Card**: Pattern nudge with gradient background, links to ChatView

Staggered appear animations with 0–0.35s delays.

### Log (`LogView.swift`)

7-tab picker at the top. Each tab is a `FormCard` stack:

| Tab | Fields |
|-----|--------|
| **Rapid** | 6 quick-action buttons (feeling well, flare, water, meds, BM, meal) |
| **Food** | Meal time picker, free text, known triggers (6 tags), gut-friendly foods (4 tags) |
| **Bowel** | Bristol scale 1–7, urgency slider 0–10, blood/mucus/pain toggles |
| **Symptoms** | Pain, fatigue, mood sliders 0–10; body map placeholder |
| **Meds** | Today's schedule (4 meds), checkbox toggle, toast on change |
| **Sleep** | Bedtime/wake inputs, calculated duration, quality slider, bathroom wake pills |
| **Weight** | Large serif input (kg), trend indicator |

### Insights (`InsightsView.swift`)

- **Recent / All toggle** with spring animation
- **Stat tiles**: Avg pain, bowel log count, flare mention count
- **Line chart**: Local pain and fatigue scores, area fill, dot markers
- **Bar chart**: Recent bowel/check-in entries from local logs
- **Pain Heatmap**: 5-week calendar grid, color intensity by saved pain severity
- **Food patterns list**: Meal log frequency summaries with no trigger or causation claim
- **Honest empty states** when saved logs do not yet support a chart

All charts implemented in pure SwiftUI using `Path` and `GeometryReader`.

### Chat (`ChatView.swift`)

- Circular gradient avatar (sage → amber)
- User messages: right-aligned, sage background
- AI messages: left-aligned, card background with outline
- Typing indicator: 3 animated dots with staggered opacity
- Suggestion chips appear when < 3 messages
- 1.2s simulated response delay (ready for Claude API)
- `ScrollViewReader` auto-scrolls to latest message

Local deterministic safety responses:
- Red-flag prompts bypass general advice
- Medication-change prompts advise clinician/pharmacist review
- Food/stress guidance stays cautious and non-causal

### Profile (`ProfileView.swift`)

- Circular gradient avatar with initial
- Stats row: saved logs, risk score, medication status
- **HEALTH section**: Local doctor report export, medication reminders, flare history, care plan
- **APP section**: Preferences, IBD library, sign out
- **PRIVACY section**: Sync status, AI memory, voice transcript storage, data export/delete controls
- Version footer: `INFLAMEND v1.0 · BUILD 1`

---

## Data Models (`Models.swift`)

```swift
enum LogType { case food, bowel, symptom, meds, water, sleep, weight }

struct LogEntry: Identifiable {
    let type: LogType
    let title: String    // e.g. "Mesalamine · 800mg"
    let sub: String      // e.g. "taken on schedule"
    let time: String     // e.g. "8:00a"
    // iconName and color computed from LogType
}

enum MoodOption: String { case great, ok, rough, flare }
// Each has: icon (◎ ○ ◐ ●), color (sage/fgDim/amber/clay)

struct ChatMessage: Identifiable {
    let role: ChatRole   // .user | .assistant
    let content: String
}

struct MedEntry {
    let name: String
    let dose: String
    let time: String
    var taken: Bool
}
```

---

## How to Recreate

### Requirements

- macOS 14+ (Sonoma or later)
- Xcode 16+
- iOS 17+ simulator or device

### Steps

**1. Create Xcode project**
```
Xcode → File → New → Project → iOS App
Interface: SwiftUI
Language: Swift
Minimum deployment: iOS 17.0
Bundle ID: com.yourname.inflamend
```

**2. Delete boilerplate**

Remove `ContentView.swift` and start fresh with the file structure above.

**3. Set dark mode only**

In `InflamendApp.swift`:
```swift
@main
struct InflamendApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
```

**4. Build files in this order**

1. `Models.swift` — enums and data models first, no UI dependencies
2. `DesignSystem.swift` — color extensions, typography constants, all reusable components
3. `ContentView.swift` — root navigation, custom tab bar, sheet modals
4. `Views/HomeView.swift`
5. `Views/LogView.swift`
6. `Views/InsightsView.swift`
7. `Views/ChatView.swift`
8. `Views/ProfileView.swift`

**5. Color tokens**

Add colors as `Color` extensions in `DesignSystem.swift`:
```swift
extension Color {
    static let bgPrimary   = Color(hex: "141210")
    static let fgPrimary   = Color(hex: "F6F1E4")
    static let sage        = Color(hex: "A8B89A")
    static let amber       = Color(hex: "E3A963")
    static let clay        = Color(hex: "D98466")
    static let ink         = Color(hex: "8A94A2")
    // ... etc
}
```

**6. No external packages needed**

No Swift Package Manager dependencies. All charts use SwiftUI `Path`. All icons use SF Symbols.

**7. Build and run**
```bash
xcodebuild -scheme Inflamend -destination 'platform=iOS Simulator,name=iPhone 17'
```

---

## Planned Integrations (Not Yet Built)

| Feature | Planned Tech |
|---------|-------------|
| AI chat responses | Anthropic Claude API |
| Production user authentication | Supabase Auth |
| Server data persistence | Supabase Postgres |
| Offline sync queue | Local repository + Supabase sync worker |
| Push notifications | APNs + Supabase Edge Functions |
| PDF export | PDFKit |
| Medication reminders | `UNUserNotificationCenter` |

---

## Business Model

- **Free tier**: Core logging, basic insights
- **Premium ($4.99/month)**: AI Risk Indicator, AI Chat, advanced food pattern summaries
- Premium gating not implemented in current MVP — all features available to all users
