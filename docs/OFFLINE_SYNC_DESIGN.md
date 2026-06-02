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

Not implemented in iOS yet. Supabase schema supports server-side storage; local persistence and queue services are next app-layer work.
