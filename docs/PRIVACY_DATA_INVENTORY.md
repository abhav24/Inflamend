# Privacy Data Inventory

| Data type | Collected? | Stored locally? | Sent to Supabase? | Sent to AI provider? | Linked to user? | Used for tracking? | Retention | Delete path |
|---|---:|---:|---:|---:|---:|---:|---|---|
| Account email/auth identity | Planned | Session only | Yes | No | Yes | No | Account lifetime | Delete account |
| Health symptoms | UI scaffolded | Protected local snapshot | Yes when backend configured | Only with explicit AI context consent | Yes when signed in | No | Until deleted/export retention policy | Delete logs/account |
| Timeline log timestamps | Implemented locally | Protected local snapshot | Yes when backend configured | Only with explicit AI context consent if included in context | Yes when signed in | No | Until logs/account deleted | Delete logs/account |
| Bowel movement data | UI scaffolded | Protected local snapshot | Yes when backend configured | Only with explicit AI context consent | Yes when signed in | No | Until deleted/export retention policy | Delete logs/account |
| Medication records | UI scaffolded | Protected local snapshot | Yes when backend configured | Only with explicit AI context consent | Yes when signed in | No | Until deleted/export retention policy | Delete logs/account |
| Food and trigger logs | UI scaffolded | Protected local snapshot | Yes when backend configured | Only with explicit AI context consent | Yes when signed in | No | Until deleted/export retention policy | Delete logs/account |
| Sleep and weight data | UI scaffolded | Protected local snapshot | Yes when backend configured | Only with explicit AI context consent | Yes when signed in | No | Until deleted/export retention policy | Delete logs/account |
| AI chat messages | UI scaffolded | Protected local snapshot | Optional when backend configured | Yes for assistant requests | Yes if persisted | No | User-controlled if memory enabled | Delete AI history |
| Voice transcripts | UI scaffolded | Optional local draft/snapshot if enabled | Optional when backend configured and opted in | No by default | Yes if stored | No | User-controlled opt-in | Delete transcripts |
| Parsed voice drafts | UI scaffolded | Protected local snapshot after confirmation | Yes when backend configured | No | Yes when signed in | No | Until confirmed/discarded/deleted | Delete drafts/logs |
| Sync replay metadata | Implemented locally | Protected local snapshot | Yes when backend configured | No | Yes when signed in | No | Until mutation syncs or account/data is deleted | Delete logs/account |
| Device push token | Future | Yes | Yes if notifications enabled | No | Yes | No | While reminders enabled | Disable notifications/delete account |
| Crash diagnostics | Future | Platform controlled | Optional service | No | Maybe | No | Vendor policy | Vendor controls |
| Analytics events | Not added | No | No | No | No | No | N/A | N/A |
| Purchase/subscription status | Future if StoreKit added | Yes | Optional | No | Yes | No | Subscription lifetime | Restore/manage subscription |
| User data export file | Implemented locally | Temporary protected JSON file | Backend export job planned | No | Yes | No | Until user shares/deletes temporary file | Export my data / delete local file |

## Rules

- No ad tracking.
- No cross-app tracking.
- No sale/share of health data.
- Do not send sensitive health logs to AI without explicit consent and clear disclosure.
- Do not log PHI to console in production.
- Do not commit secrets.
- AI memory defaults off in the current UI.
- Voice transcript storage defaults off in the current UI.
- Local auth scaffold stores an email/display name session but never stores the password field.
- The local snapshot is a production scaffold, not a substitute for final encrypted storage and Keychain-backed live auth tokens.
- Timeline logs include a structured `loggedAt` event timestamp plus a display `time`; both are included in local snapshots and local user-data exports.
- Local Insights and doctor reports use `loggedAt` for 7-day and 30-day health-log windows, so event dates must be treated as health metadata in exports, backend sync, and AI-context review.
- Sync idempotency keys are generated from mutation type and local IDs, not health text; queued mutation summaries still need sanitization before any production diagnostics or telemetry.
- Profile can create a local user-data JSON export from the current protected snapshot. Cloud export receipts and backend export jobs still require production Supabase credentials.
