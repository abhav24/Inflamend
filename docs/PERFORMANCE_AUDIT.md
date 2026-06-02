# Performance Audit

## Baseline

No runtime profiling has been completed. The app builds successfully on `iPhone 17` simulator, but performance under real data volumes is unknown.

## Risks

- Static arrays and small mock data hide long-list performance issues.
- Global `AppState` may redraw unrelated screens.
- Custom charts need testing with 30, 90, 180, and 365 days of logs.
- Animations should respect Reduce Motion.
- Future sync/network work needs timeouts and retry limits.

## Required Measurements

- Cold launch time.
- Memory usage after 1,000 logs.
- Scroll smoothness on timeline and insights.
- Chart render time for long date windows.
- Edge Function timeout behavior.
- Slow network and offline mutation behavior.

## Current Status

No performance regressions detected by build. Profiling pending after real data layer is implemented.
