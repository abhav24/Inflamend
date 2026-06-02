# Offline and Sync Design

## Goal

Users must be able to log important health data even with poor connectivity, without silent failure or data loss.

## Proposed Architecture

- Local persistence layer stores logs immediately.
- Pending sync queue records mutations with stable IDs.
- Sync service retries with backoff when network returns.
- Server assigns/accepts client IDs to avoid duplicates.
- Conflict handling prefers user-visible merge for edited records and last-write-wins only for low-risk settings.
- Last sync timestamp is visible in Profile/Privacy or sync status.

## Queue States

| State | Meaning |
|---|---|
| `pending` | Saved locally, not sent |
| `syncing` | In flight |
| `synced` | Confirmed by backend |
| `blockedNoBackend` | Retry attempted but Supabase is not configured |
| `failed_retryable` | Network/server temporary failure |
| `failed_needs_user` | Validation/auth/conflict needs action |

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
- `PendingSyncMutation` records local mutations with kind, local record ID, summary, attempt count, and status.
- Profile exposes pending sync count and lets users retry, which currently marks queued records as blocked because Supabase is not configured.
- Chat messages are only queued for backend replay when AI memory is explicitly enabled.
- Snapshot decode tolerates older snapshot files that do not contain the queue.
- Corrupt snapshots fall back to a clean state with a visible local status string.

Not implemented:

- Backend sync worker.
- Network reachability state.
- Conflict handling.
- Per-record sync status.
- Supabase Auth token refresh.

Next app-layer work is to move the queue behind a repository/sync-worker protocol and implement real Supabase replay once credentials are available.
