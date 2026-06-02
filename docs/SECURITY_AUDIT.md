# Security Audit

## Current Positive Controls

- No hardcoded live API keys were found in source during baseline scan.
- `.gitignore` excludes local `.xcconfig` files and `.env` files.
- Config examples use placeholders only.
- Supabase schema enables RLS for every user-owned table.
- Edge Functions verify JWT and derive user identity from Supabase Auth.
- AI provider key is server-side only by design.

## High-Priority Risks

| Risk | Status | Fix |
|---|---|---|
| No iOS auth/session implementation | Open | Add AuthService and auth screens |
| No local encryption/keychain session handling | Open | Store session tokens safely via Supabase SDK/Keychain strategy |
| No hosted RLS verification | Blocked | Requires Supabase local/hosted setup |
| No rate limiting on Edge Functions | Open | Add gateway or backend rate limits |
| No PHI logging policy enforcement | Open | Add logging wrapper and review |
| Generated Info.plist lacks permission descriptions for voice | Open | Add when Speech/mic features are implemented |
| `.claude/settings.local.json` exists locally | External/user file | Do not add to git |

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
