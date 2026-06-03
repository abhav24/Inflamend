# Inflamend

A native iOS health tracking and AI companion app for people living with Inflammatory Bowel Disease (IBD), specifically Ulcerative Colitis. Inflamend helps patients log daily health data, monitor flare risk, identify food and lifestyle patterns, and get AI-powered insights — all in a dark, minimal, medically-informed UI.

---

## What It Does

- **Flare Risk Score** — AI-driven 0–100 risk indicator updated from logged data, shown as an animated ring on the home screen
- **Daily Logging** — 7-category logging system: food, bowel movements (Bristol scale), symptoms, medications, sleep, weight, and rapid check-ins
- **Timeline Management** — Edit, delete, and undo any log entry with full structured payload preservation
- **Insights & Charts** — Date-windowed trend summaries, pain heatmap, bowel chart, food frequency list, and accessibility summaries
- **AI Chat** — In-app assistant ("Ask Inflamend") with local deterministic safety responses and Claude API scaffolding
- **Medication Tracking** — Daily schedule with check-off, streak tracking, reminder settings, and persisted dose status
- **Doctor Report Export** — Shareable local report with structured health data
- **Privacy & Sync** — Full local-first data layer with sync queue, snapshot recovery, and user data export/delete controls

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Language | Swift 5.9+ |
| Framework | SwiftUI 6 (`@Observable` macro) |
| Min iOS | 17.0 |
| State | Centralized `AppState` with `@Observable` / `@MainActor` |
| Persistence | `AppSnapshotStore` — JSON to Application Support with iOS file protection |
| Sync | Local mutation queue with typed payloads, replay planner, backoff, network-awareness |
| Charts | Pure SwiftUI (`Path`, `GeometryReader`) — no external library |
| Navigation | Custom floating tab bar (no `NavigationStack`) |
| Backend | Supabase schema, RLS policies, and Edge Functions (AI chat, risk score, voice parse, export) |
| Dependencies | None (no Swift packages, no CocoaPods) |
| Tests | `InflamendTests` (health logic unit tests), `InflamendUITests` (15+ UI smoke tests) |

Dark mode only. No external dependencies.

---

## Branch Overview

| Branch | Description |
|--------|-------------|
| `main` | Baseline — navigation, design system, core screens |
| `v2` | Local-first MVP — full offline data layer, timeline editing, sync queue, UI tests |

---

## Architecture

```
Inflamend/
├── InflamendApp.swift        # @main entry, forces dark color scheme
├── ContentView.swift         # Root: tab switcher + custom tab bar + sheets + auth flow
├── Models.swift              # AppState, LogEntry, typed payloads, sync models, enums
├── DesignSystem.swift        # Color tokens, typography, reusable components
├── Core/
│   └── HealthLogic.swift     # Risk scoring, red-flag detection, report generation
└── Views/
    ├── HomeView.swift        # Dashboard: risk ring, mood check-in, timeline
    ├── LogView.swift         # 7-tab logging interface
    ├── InsightsView.swift    # Local-log summaries, charts, heatmap, empty states
    ├── ChatView.swift        # AI assistant chat UI
    └── ProfileView.swift     # Account, stats, sync status, settings, privacy controls
```

### State Management

All UI state flows through a single `AppState` class (`@Observable`, `@MainActor`). It owns auth, onboarding, privacy preferences, logs, chat, risk state, snapshot restore, and the pending sync mutation queue.

`AppSnapshotStore` writes JSON to Application Support with iOS file protection. The Supabase sync worker is scaffolded but externally blocked — all data stays local until a sync connection is established.

```swift
@Observable @MainActor
class AppState {
    var authSession: AuthSession?
    var onboardingProfile: OnboardingProfile?
    var riskScore: Int
    var logs: [LogEntry] = []
    var pendingSyncMutations: [PendingSyncMutation] = []
    var syncRetryMetadata: SyncRetryMetadata?
    var privacyPreferences: PrivacyPreferences

    func addLog(type: LogType, payload: LogPayload)
    func editLog(id: UUID, payload: LogPayload)
    func deleteLog(id: UUID)
    func undoLastDelete()
    func retryPendingSyncScaffold()
    func exportUserData() -> ExportBundle
    func deleteAllData()
}
```

### Local-First Data Layer

- **Typed payloads** — each log type has a structured payload (e.g. `BowelPayload`, `FoodPayload`) preserved through edits
- **Sync queue** — mutations enqueue as `PendingSyncMutation` with serialized typed payloads
- **Snapshot recovery** — `AppSnapshotStore` persists and restores full app state on launch
- **Replay planner** — queued mutations replay in order when connectivity returns
- **Retry backoff** — exponential backoff metadata tracked per mutation; sync pauses when network is unavailable

### Navigation

No `NavigationStack`. A custom `Tab` enum drives a `ZStack` switch inside `ContentView`. The floating tab bar is a capsule with `.ultraThinMaterial` glassmorphism, 20px shadow, and spring scale animation on the active tab.

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

---

## Screens

### Home (`HomeView.swift`)

- Greeting with time-of-day prefix and user name
- **Flare Risk Card**: `RiskRing` at 164pt, risk label, data source caption
- **Today Summary**: 4 mini-stat rows (symptoms, meds, water, sleep)
- **Mood Check-in**: 4 options (great/ok/rough/flare), color-coded, persists in AppState
- **Rapid Log Row**: Water, meal, meds, BM quick-log buttons → trigger sheets
- **Timeline**: Chronological `LogEntry` list with edit and delete (with undo) per entry
- **AI Insight Card**: Pattern nudge with gradient background, links to ChatView

### Log (`LogView.swift`)

7-tab picker at the top. Each tab is a `FormCard` stack:

| Tab | Fields |
|-----|--------|
| **Rapid** | 6 quick-action buttons (feeling well, flare, water, meds, BM, meal) |
| **Food** | Meal time picker, free text, known triggers (6 tags), gut-friendly foods (4 tags) |
| **Bowel** | Bristol scale 1–7, urgency slider 0–10, blood/mucus/pain toggles |
| **Symptoms** | Pain, fatigue, mood sliders 0–10; body map placeholder |
| **Meds** | Today's schedule, checkbox toggle with persisted dose status, toast on change |
| **Sleep** | Bedtime/wake inputs, calculated duration, quality slider, bathroom wake pills |
| **Weight** | Large serif input (kg/lbs unit preference), trend indicator |

All log submissions produce typed payloads stored in `AppState.logs` and enqueued in the sync mutation queue.

### Insights (`InsightsView.swift`)

- **Date range selector**: Recent / 30d / 90d / All toggle with spring animation
- **Stat tiles**: Avg pain, bowel log count, flare mention count
- **Line chart**: Local pain and fatigue scores, area fill, dot markers
- **Bar chart**: Recent bowel/check-in entries from local logs
- **Pain Heatmap**: 5-week calendar grid, color intensity by saved pain severity
- **Food patterns list**: Meal log frequency summaries with no trigger or causation claim
- **Accessibility summaries** on all charts
- **Honest empty states** when saved logs do not yet support a chart

All charts implemented in pure SwiftUI using `Path` and `GeometryReader`.

### Chat (`ChatView.swift`)

- Circular gradient avatar (sage → amber)
- User messages: right-aligned, sage background
- AI messages: left-aligned, card background with outline
- Typing indicator: 3 animated dots with staggered opacity
- Suggestion chips appear when < 3 messages
- Local deterministic safety responses (red-flag detection, medication change warnings)
- Ready for Claude API integration

### Profile (`ProfileView.swift`)

- Circular gradient avatar with initial
- Stats row: saved logs, risk score, medication status
- **HEALTH**: Doctor report export, medication reminders, flare history, care plan questions
- **APP**: Weight unit preferences, IBD education library, sign out
- **PRIVACY**: Sync status with retry detail, AI memory toggle, voice transcript storage toggle, data export and delete controls
- Version footer

---

## Data Models (`Models.swift`)

Core types:

```swift
enum LogType { case food, bowel, symptom, meds, water, sleep, weight, checkIn }

struct LogEntry: Identifiable {
    let id: UUID
    let type: LogType
    let title: String
    let sub: String
    let timestamp: Date
    var payload: LogPayload   // typed, preserved through edits
}

// Typed payloads (one per log type)
struct FoodPayload: Codable { var mealTime, notes: String; var triggers, friendly: [String] }
struct BowelPayload: Codable { var bristolType: Int; var urgency: Double; var blood, mucus, pain: Bool }
struct SymptomsPayload: Codable { var pain, fatigue, mood: Double }
// ... MedsPayload, SleepPayload, WeightPayload, CheckInPayload

struct PendingSyncMutation: Codable, Identifiable {
    let id: UUID
    let logType: LogType
    let operation: SyncOperation   // .create | .update | .delete
    let payload: LogPayload
    var retryCount: Int
    var lastAttempt: Date?
}
```

---

## Tests

### Unit Tests (`InflamendTests/HealthLogicTests.swift`)

Covers deterministic health logic:
- Red-flag symptom detection
- Risk score calculation
- Voice transcript parsing
- Medication schedule calculations
- Doctor report content and wording
- Local Care safety response routing
- Validation helpers

### UI Smoke Tests (`InflamendUITests/InflamendUITests.swift`)

15+ scenarios covering:
- Auth onboarding flow
- Today check-in
- Bowel red-flag warning
- Care red-flag response
- Medication dose toggle
- Food log submission
- Doctor report export
- Insights empty state and populated state
- Privacy toggle controls
- Voice confirmation flow
- Profile sign-out
- Destructive action confirmation
- Local sign-in

---

## Build & Run

```bash
# Build
xcodebuild -project Inflamend.xcodeproj -scheme Inflamend \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug build

# Unit tests
xcodebuild test -project Inflamend.xcodeproj -scheme Inflamend \
  -destination 'platform=iOS Simulator,name=iPhone 17'

# UI tests
xcodebuild test -project Inflamend.xcodeproj -scheme InflamendUITests \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

Requires macOS 14+, Xcode 16+, iOS 17+ simulator. No external dependencies.

Supabase backend files are scaffolded under `supabase/` (schema, RLS policies, edge functions). Local migration and function verification requires the Supabase CLI and Deno.

---

## Supabase Backend (Scaffolded)

```
supabase/
├── migrations/
│   ├── 0001_init.sql                      # Core schema
│   ├── 0002_rls_policies.sql              # Row-level security
│   ├── 0003_seed_dev_data.sql
│   ├── 0004_medication_reminder_settings.sql
│   └── 0005_app_preferences.sql
└── functions/
    ├── ai-chat/          # Claude API proxy
    ├── risk-score/       # Server-side risk scoring
    ├── voice-parse/      # Voice transcript → structured log
    └── export-report/    # PDF report generation
```

---

## Planned Integrations

| Feature | Status |
|---------|--------|
| Claude API chat responses | Scaffolded — local safety responses live; API call wired |
| Supabase Auth | Schema + RLS ready; iOS client not yet connected |
| Server data sync | Sync queue built locally; Supabase worker blocked externally |
| Push notifications | `UNUserNotificationCenter` reminder settings built; APNs not yet registered |
| PDF export | Structured report data ready; PDFKit render not yet implemented |
| Apple Health import | Not started |

---

## Business Model

- **Free tier**: Core logging, basic insights
- **Premium ($4.99/month)**: AI Risk Indicator, AI Chat, advanced food pattern summaries
- Premium gating not implemented — all features available to all users in current build
