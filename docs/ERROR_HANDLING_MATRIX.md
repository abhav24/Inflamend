# Error Handling Matrix

| Area | Failure | User-Facing Behavior | Implementation Status |
|---|---|---|---|
| Auth | Invalid email/password | Human-readable error, no raw backend code | Pending |
| Auth | Session expired | Return to sign in, preserve local unsynced logs | Pending |
| Supabase | Network offline | Save locally and queue mutation | Local queue implemented; network replay pending |
| Supabase | RLS denied | Safe generic error, log non-PHI diagnostic | Pending |
| Logging | Invalid fields | Inline validation | Pending |
| Voice | Permission denied | Manual fallback | Pending |
| Voice | Empty transcript | Retry/manual fallback | Edge parser handles empty payload |
| Voice | Ambiguous parse | Confirmation screen with editable fields | Parser scaffold returns `ambiguous` |
| AI | Missing auth | Ask user to sign in | Edge function returns 401 |
| AI | Provider unavailable | Safe fallback, no infinite spinner | Edge function scaffold returns provider status |
| AI | Red flag | Urgent-care guidance | Edge function scaffold implemented |
| AI | Medication-change prompt | Advises clinician/pharmacist, no prescription change | Implemented locally and in Edge scaffold |
| Reports | Export fails | Retry or plain text fallback | Pending in iOS |
| Notifications | Permission denied | Reminders disabled with explanation | Pending |
| HealthKit | Permission denied | App remains fully usable | Pending |
| StoreKit | Product unavailable | Hide premium gates or show setup error | Not applicable |

## Rule

No button should silently do nothing. Every unavailable production path must either be hidden or explain what setup/action is required.
