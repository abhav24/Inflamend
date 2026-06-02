# CI Setup

## Recommended GitHub Actions Workflow

Add after the test target exists:

```yaml
name: iOS

on:
  pull_request:
  push:
    branches: [main]

jobs:
  build-test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode.app
      - name: Build
        run: xcodebuild clean build -scheme Inflamend -destination 'platform=iOS Simulator,name=iPhone 17'
      - name: Test
        run: xcodebuild test -scheme Inflamend -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Current Blocker

`xcodebuild test` fails because no test target/action exists. Add tests before enabling CI as required.

## Supabase CI

Future backend CI should run:

```bash
supabase db start
supabase db reset
supabase functions serve ai-chat --no-verify-jwt
```

Then run RLS and Edge Function smoke tests.
