
## web/27

No unresolved items.

## Step mobile/05

No unresolved items reported.

## web/05

No unresolved items reported by the verifier.

## mobile/26

None reported by the verifier.

## mobile/06 (cinematic shell, navigation, transitions)
- Resolved in 4.0.1 cleanup (redesign/P3): match cut (CineHero's tween runs on CineCurves.turn), palette announces 'Searching…' then the count, reader.enter fires when the last blade lands.

## web/06 cinematic shell, navigation, transitions (lane L02)

- Playwright e2e/cinematic/shell.spec.ts:272 'signed-out /login fires no session requests (bare frame does no app-only work)' (item 16, e2e)
- Playwright e2e/cinematic/shell.spec.ts:303 'scrim under the running head over art, wipe blade timings, hit targets' (item 16, Column wipe e2e)
- Motion-timings overlay (scope 14; acceptance 'development only, production bundles never contain it'): a second overlay from web/11 still ships in production
- Reader prefetch (scope 6): first two pages do not go through web/03's sources limiter
- Minor deviations from scope 3, 4 and 9 (not blocking alone)

## mobile/27

None reported by the verifier.

## mobile/07
- Resolved in 4.0.1 cleanup (redesign/P3): flutter analyze is clean.

## mobile/16 (cinematic discover/search/sources/dialogue, lane L09)
- Resolved in 4.0.1 cleanup (redesign/P3): flutter analyze clean; Discover uses the shared primitives (CineButton, CineNotice, TypedText, CineSlugLines, CinePlate, CineLeaderDial, CineIndeterminateRule).
- Left: F.3 scan widgets in the primitives gallery. The gallery lost its in-app entry with the legacy Diagnostics screen; the widgets are covered by `scan_widgets_test.dart`.
- Left: the Discover masthead kicker and the idle section heads still use the local Kicker/SectionHead, not SetHeading (a per-screen motion change, over 30 min).
- Left: 'Dip into the reader' proof needs a device capture (the other states are in proof/mobile-16).

## mobile/08 (cinematic tonight, lane L06)
- Left: the six keys are wired (`tonight_shortcuts.dart`); the widget test asserts only R and P. V, down/up, Enter, rail keys and the keyboard-only focus ring still need test coverage (about 30 min).

## mobile/09

No unresolved items.

## mobile/17 (L09, cinematic downloads/index/status)
- Resolved in 4.0.1 cleanup (redesign/P3): tap-target guidelines pass on Status, Index, Downloads and the What's new sheet (iOS check added).
- Left: Save to Files CI proof (APK build and iOS dry run) needs CI runs.

## mobile/18 (L09, cinematic settings and edition restart)
- Resolved in 4.0.1 cleanup (redesign/P3): full flutter test passes; C3 guided auto-advance is a 2-10 s stepper in 0.5 s steps.

## mobile/11

None reported by the verifier.

## mobile/19
- Resolved in 4.0.1 cleanup (redesign/P3): B4 Try again cancels the running ask with a CancelToken (the From-your-sources ask still only drops a late answer); C5 a rejected tag fades over 160 ms; B1/G stale badge (already built, tested in picks_screen_test).
- Left: B9/B6 the world card lives at primitives/cards/cine_world_card.dart and has no poster form; Because-you-read rails use CinePoster (over 30 min).

## mobile/20 (cinematic onboarding, merged from redesign/M20)
- Resolved in 4.0.1 cleanup (redesign/P3): E2.2 the wall hides a poster while its flight copy is in the air.
- Left: keyboard: shortcuts, roving groups and the ? sheet's Onboarding group are wired; only right/left have a widget test.
- Left: E2.6 Tonight holds only its headline until `landed`, not the kicker, rack and deck (over 30 min across three files).

## mobile/12 (cinematic manga reader strip, merged from redesign/L01)
- Resolved in 4.0.1 cleanup (redesign/P3): A10 fetchChapterText has repository tests (texts and boxes; null on 404).

## mobile/21 (cinematic numbers, streak, annual)
- Resolved in 4.0.1 cleanup (redesign/P3): A2 (a separate NumbersRepository by design, tested in numbers_data_test); B6 the 30/90-day date labels no longer collide with the last day.
- Left: CI APK/iOS run links and the web-twin comparison (web postponed).

## mobile/13

None reported by the verifier.

## Step mobile/14 (cinematic novel reader)
- Obsolete: 'Edition LEGACY legacy reader still reads and writes K25 and K26': the legacy reader is deleted. Both skins read and write K25; K26 is a read-only fallback.
- Left (implemented, widget tests missing; each 30 min or more): the remaining keys of K (h, k, Space, Home, End, =, +, -, 0, comma, o, m, g); over-scroll 140 px and the live-region announcement; chrome auto-hide thresholds, guards and fade timings; hit targets in the Type and Contents sheets and the Margins panel; reduced-motion timings; Slide/Fade turns and re-paginate on a Type change; speaker/drop-cap semantics, name popover, end matter, rating card, stale toast, 38% line, Contents marks, half detent.
- Left: proof web-twin comparison (web postponed) and the device checklist (owner).

## mobile/22 (cinematic circle)
- Left: the 18+ and isolation widget test for the Circle screens (about 40 min).
- Left: hit-target coverage for the Settings Circle and privacy section and the 8 px spacing outside stamps.

## Step mobile/15 (cinematic listen mode)
- Resolved in 4.0.1 cleanup (redesign/P3): E the speed ruler sheet has the single detent [0.5].
- Obsolete: 'the extraction first as its own no-pixel commit' (history).
- Accepted: A1 the handler forwards commands and each chapter session owns one player; two never play at once.
- Left: proof gaps (web-15, device checklist, screenshot map).

## mobile/23

None reported by the verifier. (flutter analyze: 18 info-level avoid_dynamic_calls lints in new tests, no errors.)

## mobile/28

None reported by the verifier.

## mobile/29

None reported by the verifier.

## mobile/24

None reported by the verifier.

## mobile/30

No unresolved items reported by the verifier.
## mobile/24b (cinematic reconcile)
- Resolved in 4.0.1 cleanup (redesign/P3): cine_kit's stand-ins are replaced by the shared primitives and deleted; DialogueLandingHost (unused) is deleted, the manga reader lands dialogue jumps itself.
- Not attempted (need a device, art or owner): all "fix attempted, not re-checked" acceptance items above that name CI runs, proof screenshots, or hardware checks.

## mobile/24b

No unresolved items reported by the verifier.

## mobile/31

None reported by the verifier.

## mobile/v1 leftovers (Cinematic)
- Resolved in 4.0.1 cleanup (redesign/P3): cine_kit.dart's local stand-ins are gone.

## mobile/38

None reported.

## mobile/42

None reported by the verifier.

## mobile/35

None reported by the verifier.

## mobile/33

None reported by the verifier.

## mobile/37

None reported by the verifier.

## mobile/43

None reported by the verifier.

## mobile/44

(none reported)

## release/00 + release/01 (mobile-only 3.6.0, lane R1)

- Cinematic onboarding step 1 (Edition, cinematic 8.7: `YOUR EDITION`, the two live previews, the deferred restart after `Print my first issue`) is not built. The flow stays at four steps with Glass on (`onboarding_screen.dart` `_glass => false`); Glass is chosen in Settings -> Appearance or on the profile form. Over 45 min.
- Tablet bands (mobile-45 open issue 4), still accepted in `qa/glass_focus_test.dart`: on the 834 x 1194 frame the Settings, You, Statistics and onboarding panes reach the screen's bottom edge inside the 24 px bottom band, and the series header buttons sit at y 8-52 inside the 76 px top band. No chrome floats in either band on the wide frame and `GlassFocusTraversalPolicy` scrolls a focused control clear where the scroll extent allows. A real fix is per-screen layout (series header top inset, pane bottom padding); over 45 min.
- The tablet page panel's focus ring clip (mobile-45 open issue 3, second half): grouped cards now host their rows' rings outside the clip; the page panel does not.
- Search `?scope=ask` still parses to `all`: Search has no ask-results pane. The idle "Describe what you want to read" row now shows when AI is available and hands the words to Picks.
- Release/01 items not done in this mobile-only release: the cross-skin Flutter suite `cross_skin_release_test.dart` (F3, 60-90 min), web A-C/E/F/G (web postponed), the install-page Glass strip (G, needs the web float frames). D2 resolved in 4.0.1 cleanup: Cinematic's arrival Undo now calls `AppIconSwitcher` like Glass's.
- Device checks: the alternate icon (iOS `AppIcon-Glass` via Xcode 26 actool, Android `.CinematicIcon`/`.GlassIcon` aliases) has only CI build proof; switch it on a phone once.

## 4.0.1 cleanup (redesign/P3)

- Done: the legacy skin and everything only it used are deleted (a stored or profile `legacy` boots Cinematic); boot awaits in `main.dart` are bounded with fallbacks; the session-token keychain read retries on a timeout and keeps the session unknown (never signs out).
- Left: `SharedPreferences.getInstance()` stays unbounded at boot: every provider needs it and there is no fallback.
- Left: release/00 `?scope=ask` on Glass Search is an owner decision (redirect to Picks or build an ask pane); tablet bands and the page-panel ring clip are per-screen layout work (over 30 min).
