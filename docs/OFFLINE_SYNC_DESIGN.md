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
- Profile exposes last local save status through the app state, ready for UI surfacing.

Not implemented:

- Pending mutation queue.
- Backend sync worker.
- Network reachability state.
- Conflict handling.
- Per-record sync status.
- Supabase Auth token refresh.

Next app-layer work is to split snapshot persistence into a repository plus queue so local saves can be replayed to Supabase without UI code owning sync behavior.
