# Inflamend

**Your Gut's Best Friend** — A mobile app for people living with Inflammatory Bowel Disease (IBD) to track their health, identify patterns, and manage flares before they happen.

---

## What It Does

Inflamend is a React Native app that lets IBD patients log food, bowel movements, symptoms, medications, sleep, menstrual cycle, and weight — all in one place. The app analyzes that data to calculate a daily flare risk score and includes an AI-powered chat assistant for IBD questions and emotional support.

**Key features:**
- Log 7 types of health data with purpose-built forms
- Daily flare risk indicator (Low / Medium / High) based on the last 7 days of logs
- AI chat assistant trained on IBD knowledge
- Insights screen with symptom trend charts, bowel frequency charts, and a pain heatmap
- Offline-first — logs save locally and sync to the cloud when connected
- Medication reminders via push notifications
- PDF export of a 30-day health report to share with your doctor
- Menstrual cycle tracking with IBD symptom correlation

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile framework | React Native + Expo (SDK 54) |
| Navigation | Expo Router (file-based) |
| Backend | Supabase (PostgreSQL + Auth + Edge Functions) |
| AI chat | Anthropic API via Supabase Edge Function |
| State management | Zustand |
| Offline storage | AsyncStorage + sync queue |
| Charts | Custom bar/line charts (React Native Views) |
| Notifications | expo-notifications |
| PDF export | expo-print + expo-sharing |

---

## Project Structure

```
Inflamend/
├── app/
│   ├── _layout.tsx              # Root layout — auth listener, route protection, sync
│   ├── (auth)/
│   │   ├── login.tsx            # Email/password login
│   │   ├── signup.tsx           # Account creation
│   │   ├── forgot-password.tsx  # Password reset
│   │   └── onboarding.tsx       # 4-step onboarding (diagnosis, cycle, notifications)
│   └── (tabs)/
│       ├── home.tsx             # Dashboard — risk gauge, daily stats, timeline
│       ├── log.tsx              # Log screen — 7 form types in a tab switcher
│       ├── insights.tsx         # Charts, trigger analysis, pain heatmap
│       ├── chat.tsx             # AI chat assistant
│       └── profile.tsx          # Settings, export, logout
├── components/
│   └── ui/
│       ├── SliderInput.tsx      # Custom 0–10 slider with PanResponder
│       ├── DateTimePicker.tsx   # Native date/time picker (iOS modal + Android dialog)
│       └── TagSelector.tsx      # Multi-select pill tag component
├── constants/
│   ├── bristol.ts               # Bristol Stool Scale definitions (1–7)
│   ├── colors.ts                # App color palette
│   └── index.ts                 # Pain locations, moods, meal types, etc.
├── hooks/
│   ├── useAuth.ts               # Auth helpers (signIn, signUp, signOut, updateProfile)
│   ├── useLogs.ts               # CRUD hooks for all 7 log types
│   ├── useSyncQueue.ts          # Offline queue — enqueue, flush, pending count
│   └── useRiskIndicator.ts      # Flare risk score calculator (0–100)
├── lib/
│   ├── supabase.ts              # Supabase client (AsyncStorage session persistence)
│   └── notifications.ts        # Push notification scheduling for medications
├── store/
│   ├── authStore.ts             # Zustand store — session, user, profile
│   └── syncStore.ts             # Zustand store — sync status, pending count
├── supabase/
│   ├── migrations/
│   │   └── 001_initial_schema.sql   # All 11 database tables with RLS + indexes
│   └── functions/
│       └── chat/
│           └── index.ts         # Deno edge function — AI chat proxy
└── types/
    └── index.ts                 # TypeScript types for every database table
```

---

## Database Schema

11 tables in Supabase PostgreSQL, all with Row Level Security (users can only see their own data):

| Table | Purpose |
|---|---|
| `profiles` | Extends Supabase auth — name, diagnosis type, cycle tracking toggle |
| `food_logs` | Meals with nutrition, hydration, trigger/safe food flags |
| `bowel_logs` | Bristol scale, urgency, blood, mucus, pain |
| `symptom_logs` | Pain, fatigue, nausea, bloating, stress, mood, flare status |
| `medications` | User's medication list (name, dosage, schedule) |
| `medication_logs` | Daily medication tracking — taken/missed, side effects |
| `sleep_logs` | Bedtime, wake time, quality, night wakings, bathroom trips |
| `menstrual_logs` | Cycle day, flow level, associated symptoms |
| `weight_logs` | Weight in kg |
| `chat_messages` | Full conversation history with the AI assistant |
| `flare_events` | Recorded flare periods with severity and identified triggers |

---

## AI Risk Indicator

The flare risk score (0–100) is calculated client-side by `hooks/useRiskIndicator.ts` using the last 7 days of data:

| Factor | Max Points |
|---|---|
| Abnormal Bristol scale readings (< 3 or > 5) | 20 |
| Blood in stool | 10 |
| High urgency | 5 |
| High pain levels | 15 |
| Currently in a flare | 15 |
| High fatigue | 8 |
| High stress | 7 |
| Poor sleep quality | 10 |
| Frequent nighttime bathroom trips | 10 |
| Missed medications | 10 |
| Trigger foods consumed | 10 |

Score < 30 = **Low** (green), 30–59 = **Medium** (yellow), 60+ = **High** (red).

---

## How to Run

### Prerequisites

- Node.js v18+ (installed via nvm — see below)
- Xcode (for iOS simulator) or Android Studio (for Android emulator)
- A Supabase project ([supabase.com](https://supabase.com))
- An Anthropic API key for the AI chat feature

### 1. Install Node.js (if needed)

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.zshrc
nvm install --lts
```

### 2. Clone and install dependencies

```bash
git clone git@github.com:abhav24/Inflamend.git
cd Inflamend
npm install --legacy-peer-deps
```

### 3. Set up environment variables

```bash
cp .env.example .env
```

Edit `.env` with your actual values:

```
EXPO_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
```

### 4. Set up the database

In your Supabase project, go to **SQL Editor** and run the contents of:

```
supabase/migrations/001_initial_schema.sql
```

This creates all 11 tables, RLS policies, indexes, and the trigger that auto-creates a profile on signup.

### 5. Deploy the AI chat edge function

Install the Supabase CLI, then:

```bash
supabase login
supabase link --project-ref your-project-ref
supabase secrets set AI_API_KEY=your-anthropic-api-key
supabase functions deploy chat
```

### 6. Run the app

**iOS Simulator** (requires Xcode):
```bash
npm run ios
```

**Android Emulator** (requires Android Studio):
```bash
npm run android
```

**Physical device** (install Expo Go from the App Store / Play Store):
```bash
npm start
# Scan the QR code with your camera (iOS) or Expo Go app (Android)
```

---

## App Flow

1. **Sign up** → enter email and password
2. **Onboarding** → select diagnosis type (Crohn's, UC, IBD unspecified, Other), toggle menstrual cycle tracking, allow notifications
3. **Home tab** → see today's flare risk score, daily stats, timeline of logs, and quick log buttons
4. **Log tab** → tap a tab at the top (Food / Bowel / Symptoms / Meds / Sleep / Cycle / Weight) and fill in the form — saves offline immediately and syncs when connected
5. **Insights tab** → view 7-day or 30-day symptom trends, bowel frequency chart, top trigger foods, and pain heatmap calendar
6. **Chat tab** → ask the AI assistant questions about IBD, medications, or your symptoms
7. **Profile tab** → edit your name, toggle settings, export a PDF report for your doctor, or log out

---

## Offline Sync

All log forms write to AsyncStorage immediately on submit — so the app works with no internet connection. A sync queue (`hooks/useSyncQueue.ts`) tracks unsynced entries. Whenever the device comes back online (detected via `@react-native-community/netinfo`), the queue is flushed to Supabase automatically in the background. A sync badge on the Home screen shows pending count or "Syncing..." status.

---

## Medication Reminders

When a user adds a medication with a scheduled time (e.g. "08:00"), the app schedules a daily local push notification via `expo-notifications`. Notifications are rescheduled whenever the medication list changes. Tapping a notification opens the app to the Meds log form.

---

## Environment Variables

| Variable | Description |
|---|---|
| `EXPO_PUBLIC_SUPABASE_URL` | Your Supabase project URL |
| `EXPO_PUBLIC_SUPABASE_ANON_KEY` | Your Supabase anon/public key |

The AI API key is stored as a Supabase secret (`AI_API_KEY`) and never exposed to the client — all AI requests go through the edge function.

---

## Notes

- All features are available to all users — no premium gating is implemented yet
- The `.env` file is gitignored — never commit your real keys
- The `supabase/functions/` directory uses Deno (not Node) and has its own `tsconfig.json`
