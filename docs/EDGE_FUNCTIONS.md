# Edge Functions

## Functions

| Function | Purpose | Current Behavior |
|---|---|---|
| `ai-chat` | Safe server-side AI proxy | Verifies JWT, detects red flags, blocks medication-change advice, returns scaffolded response until provider key is set |
| `voice-parse` | Parse transcript into structured draft | Verifies JWT, parses common log intents, always requires confirmation, stores no audio |
| `export-report` | Generate doctor report | Verifies JWT, validates report type/format, returns plain scaffolded report content |
| `risk-score` | Deterministic risk score | Verifies JWT, computes score and cautious factors from supplied inputs |

## Security Rules

- Functions verify JWT by calling Supabase Auth with the bearer token.
- Functions never trust a client-provided `user_id`.
- Provider keys are read only from Edge Function environment variables.
- Functions return safe error codes and avoid PHI in logs.
- `config.toml` sets `verify_jwt = false` because each scaffold performs explicit verification internally.

## Rate Limiting

Rate limiting is not implemented yet. Production options:

- Supabase gateway/rate limit controls if available.
- Upstash/Redis keyed by `user_id` and function name.
- Postgres-backed rolling window table with service role only.

## Required Environment Variables

```text
SUPABASE_URL
SUPABASE_ANON_KEY
AI_PROVIDER_API_KEY      # ai-chat only, server-side
REPORT_STORAGE_BUCKET    # future PDF/report storage
```

## Production Gaps

- Add provider-specific AI call with a locked server-side medical safety system prompt.
- Persist chat messages only when privacy settings allow.
- Persist voice drafts/transcripts through service role after verifying JWT.
- Generate real CSV/PDF exports.
- Add structured logs that exclude PHI.
- Add integration tests for unauthenticated, cross-user, invalid payload, and red-flag requests.
