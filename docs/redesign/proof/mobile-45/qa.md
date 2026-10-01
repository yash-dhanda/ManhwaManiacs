# mobile/45 Glass QA and polish

Lane M45, branch `redesign/M45`. Nothing was pushed (the integrator pushes), so section O (CI) is not run here. Where the prompt and `glass/DESIGN.md` disagree the contract won; the places are named under "Contract notes".

Floor and result: see "Totals" at the end. `flutter analyze`: No issues found. `node design/build.mjs --check`: exit 0 (347 contrast cases, glass 281 pass / 0 fail). `git status --short mobile/docs/screenshots` prints nothing.

## Checks

| Section | Check | Method | Result | Fix commit(s) |
|---|---|---|---|---|
| A1 | Glass `PENDING` map and the pending stand-in | `PENDING` was already empty; the symbol, `pending_routes.dart`, `pending_screen.dart` and its test are deleted | done | e525e983 |
| A2 | Strict completeness | `test/skins/completeness_test.dart`: every route named, no `pending.` name, no `PENDING` on disk in either skin, `readerLanding` redirects | pass | e525e983 |
| A3 | Import boundary | see below | failure line recorded, edit reverted | none |
| B1 | One entry per `ScreenId`, sheets in both presentations | `qa/glass_qa_screens.dart` (throws at load on a missing id), sheets in the harness group `screens` | 35 entries | 3f5ff2b3 |
| B2/I1/I4 | Audit rules G1 to G10 | `qa/glass_qa_test.dart` | 105 pass, 0 open violations, no accepted exceptions; JSON in `audit/` | see fixes |
| C1 | Physics values | `glass_physics_test.dart` already asserted all of them; the 0.55 constant is now spelled out | pass | 3f5ff2b3 |
| C2 | Contrast gate | `node design/build.mjs --check` | 347 cases, glass 281 pass, 0 fail, 0 expect warnings | none |
| C3 | Three worst cases | `qa/glass_worst_cases_test.dart` | pass; see contract notes | none |
| D | Calibration | harness `mobile-45 calibration` | capture and 4x crops exist; no refraction in flutter_tester, so not countable | none |
| E | Screenshots | harness groups | see inventory | none |
| F | Screen readers | `qa/glass_screen_reader_test.dart` plus the tests named in its header | pass | the announcement and speed dial commits |
| G1 | Reduced motion at rest | `qa/glass_motion_test.dart`, OS flag and in-app switch, 32 screens x 2 | pass; allowed tickers: text caret on auth and profile forms, Wrapped's story clock | none |
| G2 | Reduce Motion column (116 rows) | `qa/glass_motion_test.dart` parses 4.10 | every row with a numeric fade, jump, none or frozen cell is asserted; the rest are walked on the device | wave fix |
| G3 | Planned settle times | same file, table-driven from `glass/DESIGN.md` | pass for every row that has a number | none |
| G4 | 116 motion names | `motion_names_test.dart` | pass | none |
| H | Signatures | `typed_headline_test.dart`, `letter_reveal_test.dart` (extended), `qa/glass_signature_test.dart` | pass | none |
| I2 | Colour and contrast rules | audit G5 to G8 | pass (G8 cover backings are asserted by the poster and tile tests, not generically) | none |
| I3 | Keyboard and focus on tablets | `qa/glass_focus_test.dart` | pass; accepted classes listed below | focus ring commit |
| I5 | Text scale 1.0, 1.3, 2.0 | `qa/glass_textscale_test.dart` | pass after 8 overflow fixes | see fixes |
| I6 | Gesture alternatives | `qa/glass_gestures_qa_test.dart` plus the existing tests per row; table below | partial, see below | none |
| I7 | Haptics and sound | `qa/glass_haptics_qa_test.dart`, `glass_haptics_test.dart`, `skin_haptics_test.dart`, `skin_audio_test.dart`, `settings/settings_sections_test.dart` | pass | skin.switch commit |
| I8 | Flashing | see below | all under 3 per second | none |
| J | Gate-close checklist, both scenarios | `qa/glass_gate_test.dart` | pass; share cards by `share/share_render_test.dart` | none |
| K | Budget | `qa/glass_budget_test.dart` | pass | none |
| L | Float parity | harness `mobile-45 float` | 4 of 5 frames | none |
| M | Cross-skin switch | `qa/glass_switch_test.dart` | pass, with the gap below | none |
| N | Device checklist | `device-checklist.md` | awaiting owner, rows 1 to 14 | none |
| O | CI | not run (no push in this lane) | n/a | none |

### A3 boundary proof

A throwaway `import 'package:manhwamaniacs/skins/cinematic/cinematic_skin.dart';` in `lib/skins/glass/screens/home/home_screen.dart` made `test/skins/import_boundary_test.dart` fail with:

`lib/skins/glass/screens/home/home_screen.dart imports package:manhwamaniacs/skins/cinematic/cinematic_skin.dart (other skin)`

Reverted with `git checkout -- <file>` before any commit.

### Fixes (one commit each; run `git log --oneline` for the SHAs)

| Defect found | Section |
|---|---|
| Onboarding built its merge `AnimationController` lazily inside `dispose()` (a framework assertion) | 14.1 |
| A non-interactive `GlassSlab` exposed an unlabelled button (G3) | 14.5 |
| The series cover's `GestureDetector` added an unlabelled twin of the labelled tap node (G3) | 14.5 |
| Two level-1 headings per screen: the large title and the series title wrapped a header around `LetterReveal`'s own; the compact title capsule echoed the title; the search page had none (G2) | 14.5 |
| Section and empty-state headings had no level (now level 2) | 14.5 |
| Wrapped's Pause and Close were 3.7 px apart on Android (G4) | 14.6 |
| Series chapters header sat 6 px from the Download button on tablets (G4) | 14.6 |
| The reader's title capsule overflowed in Read all (G1) | 3.3 |
| `wave` reduced to an instant swap; 4.10 says a 150 ms fade | 4.10 |
| The 18+ debug row's exit did not fire `skin.switch` | 5.2 |
| A Glass root left a static motion probe that threw "ref after the widget was disposed" in the next move | 4.10 |
| The manga reader announced no chapter change | 14.5 |
| The speed dial's slider value carried the wpm text; the contract's Flutter value is "1.25 times" | 8.15.5 |
| The focus ring of a control inside clipped glass was clipped away: `GlassFocusRingHost` now paints it outside the clip | 2.6, 14.4 |
| Nothing moved focus to the title on navigation: the large title now takes it | 8.0.8 |
| Text-scale overflows: Settings search well, idle search rows, rail skeleton, You card error form, Shelf toolbar height, friend sheet rail height, login server row | 3.3 |

## Audit summary

105 audits (35 screens x 390 iOS, 390 Android, 834 iOS): **0 open violations**, 0 accepted. Reader, Read all and novel are audited through their own rigs (demo pages). Before the fixes the audit found 81 heading violations, 4 gap violations and 1 unlabelled node across the 105 runs; the overflow findings came from the text-scale pass.

Rule implementation notes: G5 and G6 skip icon glyphs (private-use code points are non-text, 14.2); G5 skips text wells (`InputDecorator`); G7 skips text on a `GlassSlab`; G2 counts level-1 or unlevelled headers (section heads are level 2); G4 spacing treats sibling shapes of one glass group as abutting.

## Contrast gate and the three worst cases

`check-contrast.mjs`: 347 cases (cinematic 66, glass 281), all pass, 0 expect warnings. The widget cases: the reader top group over white settles at dim 0.64 and GRAD 40; Increase Contrast moves the floor to 0.40 and keeps 0.64 at Lb 1.0 (the formula, see contract notes); the dock sits under the 0.72 plateau with the dim inside 0.22 to 0.64 (plateau by `primitives/scroll_edge_test.dart`); the tinted action keeps `onTint #FFFFFF`.

## Calibration

Flutter harness capture: `calibration-flutter-harness.png`, crops in `calibration/`. The shaders did not render in `flutter_tester`: the capture shows the frost path and no refraction, so it cannot be counted. Counts per rim: not measurable. Device captures requested (checklist row 12). Web counts: `docs/redesign/proof/web-45/qa.md` does not exist yet, so **D3 is blocked**; `release/01` must not start until the device captures and the web counts exist, and no side-by-side was composed.

## Motion summary

116 rows in 4.10 and the same 116 names in `MotionName`. Duration column: every row with a "settle N ms" or leading "N ms" is played and logged within one frame; a cell such as "40 ms spacing, settle 431 ms each" plans the settle. The Reduce Motion column is asserted where the cell names a fade of N ms, a jump, none or frozen; the remaining rows are walked on the device. **Stack fan** (200 ms fade) and **Address drain** (200 ms fade to Login) are asserted. Device walk: awaiting owner.

## Budget (layers / shapes measured; limit)

| Moment | Measured | Limit |
|---|---|---|
| Library + Filters sheet + toast | 3 / 4 | 4 / 8 |
| Search open + toast | 1 / 1 | 3 / 3 |
| Desktop frame Library, toast, window | 2 / 2 | 6 / 6 |
| Profile picker | 1 / 2 | 2 / 2 |
| Onboarding | 2 / 2 | 2 / 2 |
| Wrapped | 1 / 1 | 2 / 2 |
| Home | 2 / 5 | 6 / 8 |
| Series detail page | 5 / 6 | 6 / 8 |

The reader, guided view and Rain moments (4/7 and 6/8), the novel reader and the "third layer is solid1" rule are asserted by `reader/glass_reader_budget_test.dart`, `ambient/ambient_reader_test.dart`, `novel/novel_reader_test.dart` and `skin_glass_test.dart`. The ambient field is one `CustomPaint` with one radial gradient per anchor in a loop of three and no blur filter; snapshots are captured at pixelRatio 0.5. `grep` for `precacheImage|instantiateImageCodec|decodeImageFromList|ResizeImage` finds `glass/palette.dart` (the 64 px cover palette decode), `onboarding/skin_preview_loop.dart` (the skin's own preview assets) and `wrapped/share_card.dart` (the share render): all contract-assigned.

## Gate-close checklist (both scenarios: the gate closes; a switch to a gate-closed profile)

Items 1 to 9 pass through the real `purgeMatureLocal` over the real shell. 3: a mature level is popped, 4: the mature snapshot is dropped, 5: gate-open recent searches are gone, 6: the image cache is cleared, 7: held payloads run, 8 and 9: the downloaded blob is byte-identical after the purge. 10: no command palette on Flutter ("n/a on Flutter (7.28: desktop web; phones get Search)"). Deep link: the lens "This isn't available on this profile" with "Back home" and no title or cover. Share cards: `share/share_render_test.dart` (a mostly mature year draws no mature title, source, genre or cover and nothing from the Circle). The 18+ hold: `profiles/gate_end_to_end_test.dart` and `primitives/hold_test.dart`.

## Gesture alternatives (I6)

Tested: reorder (four semantics actions and Alt+arrows, new test), toast Dismiss, "All levels" on every back button, the speed dial, cruise pill steps, swipe and reorder semantics (`primitives/lists_states_a11y_test.dart`), charts "Show as table", the 18+ hold's visible button, back and tab alternatives in the shell tests. Implemented but with no widget test of their own: "Not interested" row actions, "Hide for this session" on the accessory, "Unlock controls" in locked mode. Gesture-only rows (pinch, tilt, throw, shake, brightness band, volume keys) are on the device checklist.

## Flashing (I8)

Caret blink 530 ms phases (0.94 Hz); bead dip a single 120 ms; flame tip noise 5 Hz at 2 % of the flame; skeleton sheen 1,400 ms. Nothing flashes more than three times in a second. Tilt is within +-6 deg (cards) and +-25 deg (light) and is pinned under reduced motion or with "Light follows the device" off (`reduced` tests in `qa/glass_motion_test.dart`, `tilt_test.dart`).

## Screenshot inventory

`du -sh docs/redesign/proof/mobile-45`: 192 MB (limit 200). `screens/` 205 files (35 screens x 5 sizes: 390 x 844 @3, 440 x 956 @3, 834 x 1194 @2, 1024 x 1366 @2, 1366 x 1024 @2, plus the six sheet routes as sheets), `screens-a11y/` 175 files (reduced, solid, contrast, bold, legible, plus `inapp/`), `textscale/` 105, `states/` 48, `pairs/` 32, `float-compare/` 4, `calibration/` 2 and the top-level harness capture, `audit/` 105 JSON. The in-app switch equals the OS-path capture pixel for pixel on every screen; three differences in the first run (profiles solid and contrast, tonight reduced) were not stable on a repeat capture, so they are animation timing, not a difference.

Reviewed: grey frost where the shaders do not run is expected in `flutter_tester` (no refraction); the Home hero card at 440 x 956 puts the "Start Ch 143" and "Details" buttons over the second line of a two-line title (open issue).

## Device checklist

`device-checklist.md`: rows 1 to 14, all "awaiting owner".

## Contract notes (where DESIGN.md won)

- C3: the prompt expects 0.72 under Increase Contrast. 2.1.7's formula `clamp(0.22 + 0.42 x Lb, floor, ceiling)` gives 0.64 at Lb 1.0 in both modes; Increase Contrast raises the floor to 0.40 and the ceiling to 0.72, and the ceiling is never reached by the formula.
- G3: a Duration cell with a spacing before the settle plans the settle.
- M: see open issue 1.

## Open issues

1. **Glass is unreachable before the flag flips (stack 8.0.7, mobile 18/40).** `SkinBoot.resolveSkin` maps a debug `glass` to Cinematic while `Flags.glassAvailable` is false (asserted by `test/app/skin_boot_test.dart`), and Cinematic's Diagnostics row offers LEGACY and CINEMATIC only. M1 was therefore tested up to the restart (`mm.skin.debug`, no `PATCH`, return route, `prepare()`), with the restart tree built as the release will build it. The shared track must decide which of the two is wrong before `release/01`.
2. **Calibration (2.4.3) is blocked**: no refraction in `flutter_tester` and no web counts yet.
3. **Rings inside grouped cards and the page panel** (14.4): a row that spans a clipped card or the tablet page panel paints its ring inside that clip. Free-standing controls are fixed.
4. **Tablet Settings, You, Statistics and onboarding panes** end 8 to 16 px inside the wide frame's 24 px bottom band, and header buttons on the series page sit inside the 76 px top band (14.4).
5. **Home hero overlap** at 440 x 956 (8.8).
6. **Float frame 3** (novel plus listen) was not captured: it needs mobile/37's narration fakes. Web frames do not exist yet, so no pair was composed (12.5).
7. **Reader chapter announcement**: now `SemanticsService.sendAnnouncement("Chapter N")`; confirm the wording on a device.
8. **Wrapped's story clock and text carets** keep a ticker under Reduce Motion (14.1 allows progress indicators; confirm the caret).
9. **Contrast gate warnings** about the Glass WAV set size and the missing soundscape intake files are the shared track's.

## Totals

`flutter test` (whole suite, after merging `feat/vps-slim-source-native` a second time): **9,546 passed, 1 skipped, 0 failed**. The floor recorded by mobile/24 was 7,083 passed; the rest is other lanes' work merged since. New test files of this step: `qa/glass_qa_test.dart` (105), `glass_motion_test.dart` (about 230 cases), `glass_focus_test.dart` (32), `glass_textscale_test.dart` (105), `glass_budget_test.dart` (12), `glass_gate_test.dart` (3), `glass_switch_test.dart` (3), `glass_screen_reader_test.dart` (5), `glass_signature_test.dart` (6), `glass_worst_cases_test.dart` (4), `glass_gestures_qa_test.dart` (2), `glass_haptics_qa_test.dart` (2), `motion_names_test.dart` (2), plus 7 cases added to the typed-headline and letter-reveal tests. `flutter analyze`: No issues found.
