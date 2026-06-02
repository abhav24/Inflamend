# Security Audit

## Current Positive Controls

- No hardcoded live API keys were found in source during baseline scan.
- `.gitignore` excludes local `.xcconfig` files and `.env` files.
- Config examples use placeholders only.
- Supabase schema enables RLS for every user-owned table.
- Edge Functions verify JWT and derive user identity from Supabase Auth.
- AI provider key is server-side only by design.
- Local snapshot persistence writes to Application Support and applies iOS file protection.
- Password entered in the local auth scaffold is not stored.
- Pending sync queue is local-only, uses non-PHI idempotency keys, and does not send data without backend setup.
- Corrupt local snapshots fall back to clean state instead of crashing.

## High-Priority Risks

| Risk | Status | Fix |
|---|---|---|
| No production iOS auth/session implementation | Partially mitigated | Local auth/session scaffold exists; replace with Supabase Auth |
| No local encryption/keychain session handling | Open | Move live tokens to Keychain; consider encrypted local health store |
| No hosted RLS verification | Blocked | Requires Supabase local/hosted setup |
| No rate limiting on Edge Functions | Open | Add gateway or backend rate limits |
| No PHI logging policy enforcement | Open | Add logging wrapper and review |
| Pending mutation summaries may contain user-entered text | Open | Sanitize or exclude summaries from production diagnostics before live sync telemetry |
| Generated Info.plist lacks permission descriptions for voice | Open | Add when Speech/mic features are implemented |
| `.claude/settings.local.json` exists locally | External/user file | Do not add to git |
| Local snapshot corruption handling | Partially mitigated | Unit-tested clean fallback exists; add recovery UI |

## Secrets Policy

Committed files may include:

- `.xcconfig.example`
- Documentation placeholders
- Local demo credentials clearly scoped to Supabase local seed

Committed files must not include:

- Supabase service role key.
- Supabase anon key for a real hosted project.
- AI provider key.
- Apple certificates/profiles.
- Real user data or PHI.
