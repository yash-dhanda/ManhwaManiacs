# mobile/24 Cinematic QA and polish

Lane M24, branch `redesign/M24`. Nothing was pushed (the integrator pushes), so section H (CI) is not run here.
Floor before: `flutter test` 6,234 passed, 0 failed, 0 skipped (the prompt's 2,012 floor is far below). After: **7,083 passed, 0 failed, 0 skipped**. `flutter analyze`: No issues found. `node design/build.mjs --check`: exit 0. `MM_QA_MATRIX=1` text-scale matrix: 630 passed. `git status --short mobile/docs/screenshots` prints nothing. `free -m` available before the final run: 6,243 MB (the slot runner waited for 2,500 MB before every command).

Where this file and the contract disagree the contract (`cinematic/DESIGN.md`) won; the two places are named under "Contract notes".

## Checks

| Section | Check | Command or test | Result | Fix commit |
|---|---|---|---|---|
| A1 | Cinematic `PENDING` map deleted | `flutter analyze` | done (it was already empty; the map, `cinePendingIds`, `cineIsPending` and the pending stand-in are gone) | 1fcaf1e3 |
| A2 | Strict completeness | `test/skins/completeness_test.dart` | 3 pass: every route named, a builder per `ScreenId`, no `PENDING` on disk, `readerLanding` redirects to `/library`; Glass stays lenient | 1fcaf1e3 |
| A2 | No pending screen in the tree | `cinematic_qa_test.dart` (`find.byType(PendingScreen)` is empty for every `ScreenId`) | pass | a9422284 |
| A3 | Import boundary | see below | failure line recorded, edit reverted | none |
| B1 | One entry per `ScreenId`, throws at load otherwise | `qa/qa_screens.dart` | 35 entries; the app is mounted through the real router and `CinematicSkin.wrap` (contrast scope, reduced-motion scope, Hyperlegible, frame, flight layer) | 7491e4e8 |
| B2 to B3 | Audit at 4 sizes x iOS/Android | `qa/cinematic_qa_test.dart` (`MM_WRITE_QA=1` wrote `audit/`) | 280 pass, 0 open violations, 812 accepted (listed below) | a9422284 |
| B4 | Keyboard focus | `qa/cinematic_focus_test.dart` | 35 pass: route change leaves focus on the page and Tab reaches controls on every screen; ring findings are open issues below | 5f06dc55 |
| C1 | Contrast | `tint_test.dart`; the audit's `textContrastGuideline` on every screen | pass; no over-art row was missing (every flagged case was fixed instead, see fixes) | f56a147b |
| C2 | Colour never the only signal | existing tests (`hub_a11y_test`, `library_a11y_test`, `circle` reaction tests, `mobile-17` download marks) and the audit's label rule | pass | none |
| C3 | Single-key shortcuts off in Settings | `core/keyboard/shortcut_registry_test.dart`, `reader/reader_keys_widget_test.dart`, `novel/novel_keys_test.dart` | pass (existing) | none |
| C4 | Increase Contrast | `qa/cinematic_increase_contrast_test.dart` (Tonight, Library, Settings) | 3 pass after the fix | 8d394944 |
| C5 | Screen readers | `primitives/toast_host_test`, `reader/reader_chrome_behaviour_test`, `reader/reader_motion_a11y_test`, `recap/recap_screen_test`, `annual/annual_screen_test`, `listen/post_play_test`, `primitives/lightbox_test`, `folio_test`, and new `qa/cinematic_screen_reader_test.dart` (reveals expose full text 100 ms in) | pass | none |
| C6 | Text scale 1.0/1.3/2.0 x plain/bold/Hyperlegible, phone and tablet | `MM_QA_MATRIX=1 qa/cinematic_text_scale_test.dart` | 630 pass after 8 overflow fixes; 4 single-line paragraphs are listed in `qa_accepted.dart` | c87aa5e9, f56a147b |
| C6 | Bold Text adds 120 `wght`; "Transmigration" at 2.0 in 358 px | `type_test.dart`, `set_heading_test.dart` | pass (existing) | none |
| C7 | Every gesture has an alternative | existing per-screen tests (`hit_targets`, `feature/lightbox_test`, `row menus`); Lightbox `View cover`, cover long press now also a `View cover` semantics action on the Annual | partly by tests, rest on the device pass | 98e5f741 |
| C8 | Haptics and sound off | `test/skins/skin_haptics_test.dart`, `skin_audio_test.dart` | pass (existing) | none |
| C9 | Flashing | see below | all under 3 per second | none |
| C10 | 18+ absence | `features/downloads/mature_gate_end_to_end_test`, `mature_queue_test`, `mature_reads_test`, `cinematic/downloads/mature_hidden_test`, `share/share_card_model_test`, `share/press_run_test` | pass (existing suites). A new consolidated `cinematic_mature_absence_test.dart` was not written. Device checklist covers it | none |
| C11 | Destructive confirms resist a double tap | `qa/cinematic_confirm_arm_test.dart` and `primitives/arm_test.dart` | pass; every one of the 28 `showCineConfirm` call sites goes through the one armed dialog (list printed by the test); two raw Material dialogs were found and replaced | 8daecea9 |
| C12 | Spoiler guard | `features/circle/utils_test`, `cinematic/circle/reaction_stamps_test` | pass (existing) | none |
| D1 | Reduced motion, OS flag and app switch | `qa/cinematic_reduced_motion_test.dart` | 74 pass (every screen settles within 2 s under both; loaders still animate; every recorded move is 200 ms or less; no per-letter transform, full typed text) | 7369db4e |
| E | Screenshots | 3 groups | 280 + 22 + 140 files | 39f6e169 |
| F | Signature animations | `typed_headline_test.dart`, `set_heading_test.dart` | pass (new focus, Space, timing, 1,420 ms cases) | 5f06dc55 |
| G | Performance guards | `qa/cinematic_perf_guards_test.dart` and the tests named below | pass | 7491e4e8 |
| H | CI | not run | see "CI" | none |
| I1 | Audio-session probe | `skin_audio.dart`, Diagnostics row | built | c1adb229, 27d9af89 |
| I2 | Device pass | `device-pass.md` | awaiting owner | a9422284 |

### A3 boundary proof

A throwaway `import 'package:manhwamaniacs/skins/glass/glass_skin.dart';` in `lib/skins/cinematic/screens/tonight/tonight_screen.dart` made `test/skins/import_boundary_test.dart` fail with:

`lib/skins/cinematic/screens/tonight/tonight_screen.dart imports package:manhwamaniacs/skins/glass/glass_skin.dart (other skin)`

The edit was reverted with `git checkout -- <file>` before any commit.

### Fixes (12 commits, one per fix)

| Commit | Defect found | Section |
|---|---|---|
| 5cb36eea | Library hub counts drew at 8.6 px (0.72 of 12); the contract says Plex Mono 10 | 7.5 |
| 20f38176 | Sources and Catalogue exposed two level-1 headings | 14.4 |
| 390e3eb0 | The Annual overflowed 134 px on a landscape phone | 3.3 |
| bc476f3f | Feature spread overflowed 98 px on a landscape phone; its text column sat on the bare duotone field (4.33:1 for `ink.60`) and now sits on the 0.84 over-art scrim | 2.1.4 |
| ac8c0c01 | Profile form and novel skeletons overflowed on a short screen | 7 intro |
| 98e5f741 | Unlabelled tap surfaces: the Annual gesture layer and cover long press, the Numbers charts | 14.5, 14.8 |
| 0566b98f | `ink.45` on art (Annual chart initials and ranks) and on `paper.1` (cover plate error glyph) | 2.1.1 |
| 7369db4e | 14 places read `MediaQuery.disableAnimations` directly, so the in-app "Reduce motion" switch alone left the feature page looping; all read `CineMotion.reduced` now | 4.8 |
| 8daecea9 | Two raw Material `AlertDialog`s (scan again, voice details) | 7.10 |
| c87aa5e9 | Fixed row and header heights clipped at text scale 1.3 and 2.0 (chapter rows, Status, Updates, Collections toolbar and header, Downloads, Sources rows, poster caption) | 3.3, 7 intro |
| f56a147b | The Cinematic theme left Material's purple primary and Roboto: the feature page "Read" button rendered purple and its title in Roboto. Theme now uses `spot`, Archivo; feature title is `type.cover`, deck `type.deck`, buttons use `type.ui` | 2.1, 3.3 |
| 8d394944 | Increase Contrast did not remap `ruleHair` (built border side) nor the Numbers `ink.45` text | 14.4 |

Also: 27d9af89 (probe reads a non-null category), 39f6e169 (analyzer clean).

## Audit summary

280 audits (35 screens x 4 sizes x 2 platforms): **0 open violations**, 812 accepted. Per-screen JSON is in `audit/`. Rules: exceptions (overflow), tap targets (44 iOS, 48 Android), 8 px spacing, labelled targets, one level-1 heading, contrast, `ink.45` ground, text floor, labelled images.

Accepted exceptions (`test/skins/cinematic/qa/qa_accepted.dart`):

| Rule | Match | Section | Reason |
|---|---|---|---|
| text floor | 10.0 px | 3.3 type table | `type.nav` (tab bar) and `type.micro` (badges, fixed-cell kickers) are 10 px at phone scale; never below 10 |
| text floor | 9.4 px on Numbers | 3.3 literal sizes, 7.5 | raised footnote numerals at 0.72 of the caption |

Spacing rule as implemented: abutting cells (gap 0, one strip or list) and 1 px divider gaps are not flagged; a gap of 2 to 8 px between two controls is. Tab bar and hub tab strip cells abut by design.

C6 truncations (`kQaTruncations`): the two typed search placeholders (7.4), the `NO. 10` slug (3.3), the chart readout (9.2).

## Section 4.8, reduced motion

Proof is `cinematic_reduced_motion_test.dart` (both flags, every screen) unless another test is named.

| Row | Proof |
|---|---|
| Column wipe, Iris, match cut, Stop the press become a 200 ms cross-fade | `transitions.dart` reads the flag; recorder test: every move of a scripted walk is 200 ms or less; device pass row |
| Page, Dip, Rise, Insert 150 ms fade | same walk |
| Skeletons static at 0.8 | every screen settles within 2 s |
| Rules present at rest | `motion_rows_test.dart`, screens settle |
| Folio flip instant | `folio_test.dart` |
| Auto-scroll never auto-starts | `reader/reader_motion_a11y_test.dart` |
| Guided view cuts | `reader/reader_motion_a11y_test.dart` |
| Streak loops static | screens settle (Tonight) |
| Trailer scrub scrolls normally, strip fades 150 ms | Tonight settles; device pass row |
| Cut to home cross-fades | device pass row |
| Lightbox fades and still drags to dismiss | `primitives/lightbox_test.dart`; device pass row |
| Arm rule full at 1000 ms, no fill | `primitives/arm_test.dart` ("reduced motion" case) |
| Recap and Listen countdowns update a label once per second | `recap/recap_screen_test.dart`, `listen/post_play_test.dart` |
| Voice pulse static | screens settle (Listen) |
| Colophon a still page | `annual/annual_screen_test.dart` |
| Page tint and ambient swaps instant; tint at most once per 2 s | `reader_ambient` sample interval (G5) |
| Gestures track the finger, finish with a 150 ms fade | device pass row |
| Loaders that keep running: leader dial, indeterminate rule, button loading segment | reduced-motion test, loaders case |

## Performance guards (15.6)

| Guard | Evidence |
|---|---|
| 1 Grain and Drift only on the visible art, paused off screen | `cinematic_perf_guards_test.dart` G1 (an `OnScreen` loop schedules no frames when scrolled away and resumes); grain, streak flame and Drift are gated by `cineOnScreen` / `OnScreen` (source check in the same test) |
| 2 At most one animated blur outside reveals; Rack focus on at most 12 images | `CineMotion.rackCap == 12` and its claim guard (test G2) |
| 3 Duotone matrices cached per colour | test G3 (identical instance); cover width `w=720` is the poster/spread request path, unchanged |
| 4 Reader strip has no grain, blur, drift or backdrop | test G4 scans `reader_engine_view.dart` and `manga_reader.dart` |
| 5 Page tint at most every 600 ms, `compute()` on 16 x 16 | test G5 (`sampleInterval` 600 ms, `compute(runAnalysis, r)`); `reader_ambient` tests |
| 6 Trailer scrub relayouts one pinned sliver header | Tonight builds one `SliverPersistentHeader` in `tonight_feed.dart` (not counted per frame in a test; device pass) |
| 7 Edition preview loop mounts only on Appearance and onboarding step 1 | `settings/edition_picker_test.dart`, `onboarding` tests (existing); not re-asserted |
| 8 Lightbox decodes the full cover only on open; Cut to home at most 12 posters | `primitives/lightbox_math_test.dart`, `cine_image_limiter_test.dart` (existing) |
| 9 Sources limiter 50 per 60 s, P3 below 20 free, 429 `Retry-After` | `test/core/network/request_limiter_test.dart` ("no 60 s window holds more than 50 P2 starts across 99 attempts", P3 and 429 cases), `bulk_limiter_test.dart` |
| 10 Rails lazy beyond 30 items; walls use `SliverGrid` | test G10 (`ListView.builder` in `cine_rail.dart`, sliver wall in `shelf_wall.dart`) |

## Flashing (14.10)

Caret: 530 ms halves, a 1,060 ms cycle, 0.94 Hz (`typed_headline.dart`). Skeleton flicker: `CineDur.flicker` 1,400 ms, reversing, a 2,800 ms cycle, 0.36 Hz. Streak sparks: rise once a second. Nothing exceeds three flashes per second.

## Screenshot inventory

Written by `test/screenshots/cinematic_qa_shots_test.dart`, one group at a time with its own `MM_PROOF_DIR`; `mobile/docs/screenshots` is untouched.

- `screens/`: 280 files. Every `ScreenId` (35) at 390 x 844 (2x), 834 x 1194, 1024 x 1366 and 844 x 390 (1x), once plain (`cinematic-<screenId>-<w>x<h>.png`) and once with the layout grid on (`cinematic-<screenId>-grid-<size>.png`).
- `states/`: 22 files, phone and tablet. Library loading, empty and error; empty or offline for History, Bookmarks, Updates, Collections, Downloads, Discover, Numbers, Circle.
- `a11y/`: 140 files. Every screen at scale 2.0, Bold Text, Increase Contrast and Hyperlegible, phone.

Visual review found the purple feature buttons, the Roboto title and the debug banner (fixed or removed before the final capture). The web twin proof (`proof/web-24/`) does not exist yet, so no phone-vs-web comparison was possible.

## CI

The lane never pushes, so the `tests` workflow (with its APK job) and `Build iOS` were not run for this work. Both must be green on the integrated commit before `release/00`: URLs to be added by the integrator.

## Device pass

Awaiting owner: `docs/redesign/proof/mobile-24/device-pass.md`, and the line in `docs/redesign/owner-todo.md`.

## Contract notes

- The reader announces a chapter with `SemanticsService.announce` with the 14.4 string ("Chapter 143, The Return · Solo Leveling"), the Flutter equivalent of the web live region; page changes are not announced.
- 8.16.5 counts are Plex Mono 10 (fixed); the same section's web formula is 0.72em. `RaisedFolio` (Numbers footnotes) keeps 0.72 and is accepted as a literal size.

## Open issues

| Issue | Contract |
|---|---|
| Focus ring coverage: with a hardware keyboard, Tab reaches controls with no `CineFocusRing` on 21 of 35 screens (about 500 stops): the Material buttons on the feature page actions, text fields (they draw their own underline) and a few scroll-area nodes. Recorded by `cinematic_focus_test.dart`. Route change focus and Tab reachability hold | 2.8.2, 14.4 |
| Numbers chart painters (`CustomPainter`) still use `CineColors.ink45` and `CineColors.rule1` directly, so chart marks do not remap under Increase Contrast; the text does | 14.4 |
| Ready-state fixtures: Profile edit and Novel are audited in their loading skeleton state, Reader and Feature in their offline or fixture states; their ready states have module proof (`mobile-11`, `mobile-14`, `mobile-15`) | 14 |
| The consolidated `cinematic_mature_absence_test.dart` (C10) and a state screenshot for every screen were not built; the existing 18+ suites and module proof cover them, and the device pass repeats the 18+ checklist | 14.11, 15.7 |
| C7 gestures: the alternatives are asserted where the modules test them; the remaining rows (edge swipes, long-press menus on rows) are on the device pass | 14.8 |
| Legacy before/after captures were not taken; this step changed nothing under `skins/legacy` or `features/*` except `skin_audio.dart` (iOS-only probe) | none |
| Section H CI URLs | 15.8 |
