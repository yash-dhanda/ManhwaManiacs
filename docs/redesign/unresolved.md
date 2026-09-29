
## web/27

No unresolved items.

## Step mobile/05

No unresolved items reported.

## web/05

No unresolved items reported by the verifier.

## mobile/26

None reported by the verifier.

## mobile/06 (cinematic shell, navigation, transitions)
- Scope 4.4 Match cut: cover Hero with createRectTween RectTween(begin,end) and route animation curved with CineCurves.turn; CineHero wraps this for callers.
- Scope item 9, command palette: SemanticsService.announce 'Searching...' then 'N results'.
- Scope 4.8 / acceptance: reader.enter fires when the last blade lands (end of the close).

## web/06 cinematic shell, navigation, transitions (lane L02)

- Playwright e2e/cinematic/shell.spec.ts:272 'signed-out /login fires no session requests (bare frame does no app-only work)' (item 16, e2e)
- Playwright e2e/cinematic/shell.spec.ts:303 'scrim under the running head over art, wipe blade timings, hit targets' (item 16, Column wipe e2e)
- Motion-timings overlay (scope 14; acceptance 'development only, production bundles never contain it'): a second overlay from web/11 still ships in production
- Reader prefetch (scope 6): first two pages do not go through web/03's sources limiter
- Minor deviations from scope 3, 4 and 9 (not blocking alone)
