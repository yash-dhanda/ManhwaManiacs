# mobile/20 plan

Tasks in the order of the scope letters. Each has its test beside it.

1. A data layer (`features/onboarding/`): models (taste, catalog), repository over the app's Dio, providers (catalog keyed by profile, gate and answers; similar seeds through mobile/19's AI client), pure helpers (steps, genre paragraph, art styles, print run), the per-profile draft and the pending `done`. Unit tests in `test/features/onboarding/`.
2. B route, frame, chrome: `/welcome` out of `PENDING`, Dip entry (Cut from the picker's iris), top bar with folio and four rules, `PageView` over the visited steps only, one step-back action, `PopScope(canPop: false)`, iOS `canSwipe = false`, the "Onboarding" shortcut group.
3. C the four steps: formats (three-strip duotone plates), genre paragraph (justified `Text.rich` of word widgets), art style plates, seed wall with similar inserts and counter.
4. D save and resume: draft first, background `PUT`, resume through `resumeStep`, restore through `GET /profiles/{id}/taste`, pending `done` flushed at the next pick, picker hand-off.
5. E Print and Cut to home: follows 4 at a time, `step: done` save, `/home` refetch, flight layer above the Navigator, Tonight's `first_picks` slots and the held headline, fail-safe, reduced-motion cross-fade.
6. F states and G accessibility: galleys, unreachable and offline notices, hit targets, text scale, tablet and landscape.
7. Proof: screenshots, device checklist, report.
