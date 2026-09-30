
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

## mobile/27

None reported by the verifier.

## mobile/07

None reported by verifier. flutter analyze NOT run at merge (flutter not installed on this host); final audit must run it.

## mobile/16 (cinematic discover/search/sources/dialogue, lane L09)

Verifier items (fix attempted, not re-checked):
- Acceptance: `flutter analyze` reports no issues (post-merge analyze was clean)
- Section E.3 / acceptance: opening a hit lands on the matched page and pulses the 2 px spot frame twice, or shows the chapter-start toast
- Section F.3: scan widgets added to the mobile/04 Diagnostics primitives gallery with fixture states
- Ground rules / scope: use the mobile/04, mobile/05 and mobile/06 primitives and the real SetHeading
- Screenshots of the states 'Discover searching, group jump, scan block in each phase, reader bubble pulse' and 'Dip into the reader' (E.3)

## mobile/08 (cinematic tonight, lane L06)

- (fix attempted, not re-checked) Acceptance: hardware keyboard `R`, `↓`/`↑`, `C`, `P`, `V`, `Enter` and rail keys work in a widget test with `tester.sendKeyEvent`, and the CineFocusRing double ring shows on keyboard focus only

## mobile/09

No unresolved items.

## mobile/17 (L09, cinematic downloads/index/status)

- (fix attempted, not re-checked) Acceptance: iOSTapTargetGuideline, androidTapTargetGuideline and labeledTapTargetGuideline pass on the three screens AND the What's new sheet
- (fix attempted, not re-checked) Acceptance: Save to Files 'CI's APK build and iOS dry run are green for the native commit'
- (fix attempted, not re-checked) Dependency stand-ins (informational, not code defects): StreakFlame (mobile/08) and NarratingIndicator plus activeNarrationJobsProvider (mobile/15)

## mobile/18 (L09, cinematic settings and edition restart)

- (fix attempted, not re-checked) Acceptance: every baseline-passing test still passes; flutter test 0 failed
- (fix attempted, not re-checked) C3 Ambient row: guided auto-advance 'fixed-hold stepper 2-10 s step 0.5'
- mobile/22 MUST add its Circle providers to the mature-gate invalidators and delete 'circle_service' from noClientCache in mobile/test/features/settings/mature_invalidators_test.dart

## mobile/11

None reported by the verifier.

## mobile/19

- (fix attempted, not re-checked) E5 readers' first-page chip (manga and novel chrome)
- (fix attempted, not re-checked) C2 chapter-end credits rails (caught-up More like this, the-end Up next)
- (fix attempted, not re-checked) B4 / acceptance: Try again cancels the running request with a CancelToken
- (fix attempted, not re-checked) B9 World card widget at mobile/lib/skins/cinematic/primitives/world_card.dart, and B6 rails using it
- (fix attempted, not re-checked) C5 suggested tags: reject token fades over 160 ms
- (fix attempted, not re-checked) B1 / G stale badge from world recommendations

## mobile/20 (cinematic onboarding, merged from redesign/M20)

- (fix attempted, not re-checked) B7: backward swipe release settles with CinePagePhysics / CineSprings.release (504 ms)
- (fix attempted, not re-checked) Acceptance: hardware keyboard, arrows move focus inside roving groups, and the 'Onboarding' group is listed in the ? sheet
- (fix attempted, not re-checked) E2.2: the wall hides the flying posters in the same frame the flight layer paints copies (Visibility maintainSize/State/Animation)
- (fix attempted, not re-checked) E2.6: Tonight holds its whole Front page moment (kicker, cover rack, headline, deck) until `landed`

## mobile/12 (cinematic manga reader strip, merged from redesign/L01)

- A10: fetchChapterText must return the page texts and boxes, with a repository test on a fake Dio adapter (null on 404)

## mobile/21 (cinematic numbers, streak, annual)

- D3: the Annual PageView must use mobile/13's CinePagePhysics (finger-tracked, releasing on CineSprings.release) (fix attempted, not re-checked)
- A2: extend LibraryRepository and library_repository_impl.dart with statistics({days}), annual(year) and markMilestoneSeen(days) (fix attempted, not re-checked)
- Last acceptance item: CI APK build and iOS dry run green, with run links in the report (fix attempted, not re-checked)
- B6: chapters-per-day date labels must not collide (nothing clips) (fix attempted, not re-checked)
- Proof: comparison against the web twin's phone captures (fix attempted, not re-checked)

## mobile/13

None reported by the verifier.

## Step mobile/14 (cinematic novel reader)

Each item: fix attempted, not re-checked.

- Acceptance: hardware keyboard, every key of K works in a widget test, and the escape order is exact
- Acceptance: seamless next, auto next 900 ms, over-scroll 140 px, live-region announcement
- Acceptance: chrome auto-hide 24/56 px, focus and screen-reader guards, no slide, 240/160 ms fade
- Acceptance: hit targets in bars, sheets AND panels
- Acceptance: reduced motion (page turns 150 ms fades, Letter set 200 ms fade, panels fade in place, in-page head scrolls away without fading)
- Acceptance: per-skin difference, Edition LEGACY legacy reader still reads and writes K25 and K26
- Acceptance: paged mode (Cut, Slide finger-tracked, Fade turns, three tap-zone presets, re-paginate on Type change keeping the paragraph); the 'p. 7 of 22' folio
- Acceptance: speaker semantics prefix, drop cap semantics, long-press name popover, end matter Letter set, rating card, stale-anchor toast copy, progress saved at the 38% line, Contents narrated and saved marks, Type sheet half detent
- Proof deliverables
