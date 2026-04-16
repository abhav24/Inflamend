# Apple Health / HealthKit Setup

This project now includes:
- `lib/healthSync.ts` incremental metric sync (steps, heart rate, sleep, active energy)
- cursor/state persistence in `health_sync_state`
- dedupe-safe upserts into `health_samples`
- profile actions in `app/(tabs)/profile.tsx`
- Supabase tables from `supabase/migrations/002_health_sync.sql`

To run end-to-end on iOS, complete the native setup below.

## 1) Install the native bridge

Use a HealthKit bridge library compatible with your Expo workflow (currently scaffold assumes `react-native-health`).

## 2) Enable iOS capability

In your iOS app target:
- Open **Signing & Capabilities**
- Add **HealthKit** capability
- Keep existing notification/camera/photo permissions

`app.json` already includes:
- `NSHealthShareUsageDescription`
- `NSHealthUpdateUsageDescription`

## 3) Ensure native build path supports the bridge

Because HealthKit is native-only, you need a native iOS build path (Expo dev client / prebuild or bare workflow) where the bridge module is linked.

## 4) Health sync behavior (already implemented)

The sync flow currently:
1. Reads `health_sync_state.last_cursor` per metric (falls back to lookback window)
2. Fetches HealthKit samples incrementally
3. Normalizes samples to:
	- `steps` (`count`)
	- `heart_rate` (`bpm`)
	- `sleep_hours` (`hours` derived from start/end)
	- `active_energy_kcal` (`kcal`)
4. Upserts dedupe-safe rows into `health_samples` via `(user_id, metric, observed_at, source)`
5. Updates `health_sync_state` with status, cursor, and errors per metric

## 5) Conflict and dedupe strategy

When app logs and Health samples overlap:
- Keep raw health import in `health_samples`
- Keep user-entered logs unchanged in existing log tables
- Resolve at query/presentation layer (prefer user logs for explicit entries)

## 6) Validation checklist

- Permission prompt appears on iOS and can be re-requested from Profile
- "Connect Apple Health" sets `app_settings.health_sync_enabled = true`
- Manual "Sync Health Data Now" imports non-placeholder data
- `health_sync_state` transitions: `syncing -> success` or `error`
- Offline failures persist retries and surface clear error state in Profile

## 7) Current known gap

- On non-iOS platforms, or when HealthKit bridge methods are unavailable, metrics are skipped with explicit state errors.
- Bridge method naming can vary by library version; `lib/healthSync.ts` includes fallback method resolution for active energy samples.
