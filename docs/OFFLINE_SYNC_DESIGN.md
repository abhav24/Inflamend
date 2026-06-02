# Offline and Sync Design

## Goal

Users must be able to log important health data even with poor connectivity, without silent failure or data loss.

## Proposed Architecture

- Local persistence layer stores logs immediately.
- Pending sync queue records mutations with stable IDs and stable idempotency keys.
- Sync service retries with backoff when network returns.
- Server assigns/accepts client IDs to avoid duplicates.
- Server receipt IDs are retained for actions that need proof of completion, such as exports and deletion requests.
- Conflict handling prefers user-visible merge for edited records and last-write-wins only for low-risk settings.
- Last sync timestamp is visible in Profile/Privacy or sync status.

## Queue States

| State | Meaning |
|---|---|
| `pending` | Saved locally, not sent |
| `syncing` | In flight |
| `synced` | Confirmed by backend |
| `blockedNoBackend` | Retry attempted but Supabase is not configured |
| `failedRetryable` | Network/server temporary failure |
| `failedNeedsUser` | Validation/auth/conflict needs action |

## UI States

- Offline banner when network is unavailable.
- "Saved on this device" confirmation for offline logs.
- Retry button for failed user-actionable sync.
- No infinite spinners.

## Current Status

Partially implemented in iOS.

Implemented:

- `AppSnapshotStore` writes a local JSON snapshot in Application Support.
- iOS file protection is applied to the snapshot file.
- Session scaffold, onboarding profile, logs, chat, privacy preferences, risk, meds, mood, and safety state restore across app launches.
- Log actions save locally before any backend exists.
- `PendingSyncMutation` records local mutations with kind, local record ID, summary, optional typed payload snapshot, idempotency key, optional server record ID, optional receipt ID/timestamp, attempt count, status, last attempted timestamp, and last error.
- `SyncReplayPlanItem` and `LocalSyncReplayWorker` turn pending mutations into deterministic future actions against Supabase Auth, public tables, soft-delete fields, or Edge Functions while carrying idempotency/server/receipt metadata and typed health-log payload snapshots into the plan.
- Profile exposes pending sync count and lets users retry, which currently marks queued records as blocked with per-record errors because Supabase is not configured.
- Local health-log edits coalesce into unreplayed creates when possible, existing-record edits reuse one pending update mutation, Home timeline edits preserve existing typed payloads for display-only changes, food timeline edits can replace meal/tag payloads, bowel timeline edits can replace Bristol/blood/pain payloads and safety state, symptom timeline edits can replace pain/fatigue/mood payloads and safety state, sleep timeline edits can replace quality/wake payloads, generic model edits can clear stale payloads, edit payload snapshots update with the latest local row, and edit-then-delete removes redundant pending updates.
- Chat messages are only queued for backend replay when AI memory is explicitly enabled.
- Snapshot decode tolerates older snapshot files that do not contain the queue, and legacy queued mutations decode with generated idempotency keys.
- Corrupt snapshots fall back to a clean state with a visible local status string.

Not implemented:

- Live Supabase network replay client that serializes typed health-log payload snapshots into backend columns or JSONB.
- Network reachability state.
- Conflict handling.
- User-visible per-record sync detail screens.
- Supabase Auth token refresh.

Next app-layer work is to connect the replay worker to a real Supabase client, store returned server IDs and receipts, then implement backoff, reachability, and conflict handling once credentials are available.
