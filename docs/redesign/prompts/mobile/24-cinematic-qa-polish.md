# Mobile Cinematic QA and polish before the flip

Track: mobile · Order 66 · Depends on: `docs/redesign/prompts/mobile/23-cinematic-ambient-reader-extras.md` · Web twin: `docs/redesign/prompts/web/24-cinematic-qa-polish.md` · Proof folder: `docs/redesign/proof/mobile-24/`

## Goal

Every Cinematic screen of the Flutter app now exists (steps `mobile/04` to `mobile/23`). This step proves the whole skin on iOS and Android against its contract and fixes everything that fails, so `release/00` can make Cinematic the default. You will: make the completeness test strict (no Cinematic `ScreenId` left in `PENDING`, the pending map deleted from the Cinematic skin); prove the import boundary; build a Flutter QA harness that pumps every `ScreenId` with fake providers at phone and tablet sizes on both target platforms and audits it (tap targets 44 pt on iOS and 48 dp on Android, labels, headings, contrast, `ink.45` only on `paper.0`, text floor, no overflow); run the accessibility rules of `cinematic/DESIGN.md` §14 and every check of §15.7; verify reduced motion against the §4.8 table; verify the §15.6 performance guards as they apply to Flutter; check text scale 1.0, 1.3 and 2.0, OS Bold Text, Increase Contrast, Hyperlegible text and the screen-reader timer rules; prove both signature animations with widget tests; capture every `ScreenId` through the screenshot harness at phone and tablet sizes with and without the layout grid; confirm the CI APK build and the iOS dry run are green; add the one diagnostic row the iPhone audio-session check needs; write the owner's device-pass checklist of §15.8 (Column wipe, Iris, trailer scrub, Cut to home, Lightbox, the reader at 120 Hz with page tint, the Listen highlighter, the `AVAudioSession` category after SoLoud init and after Hear, text scale, Bold Text, Increase Contrast, TalkBack and VoiceOver); fix every defect found, one commit per fix; and write `docs/redesign/proof/mobile-24/qa.md`. You add no features. When a check needs something the contract does not define, the contract wins and the gap goes into `qa.md` as an open issue.

## Read first

Read these completely before planning. Where this file and `docs/redesign/cinematic/DESIGN.md` disagree, `cinematic/DESIGN.md` wins; say so in the report.

1. `docs/redesign/inventory/00-decisions.md` (all of it; the two signature animations are binding; "Flagship-only, maximum effects… Still honor OS reduced-motion for accessibility").
2. `docs/redesign/stack-decision.md` §2.3 (completeness and import-boundary tests), §2.5 (restart budget under 1.5 s), §3 "Release model", §4 risks 6, 9 and 11.
3. `docs/redesign/cinematic/DESIGN.md`:
   - §2.1.1 (the neutral ramp: `ink.45` `#7A7770` only on `paper.0` `#000000`; the raised-stock scope), §2.1.4 (scrims and the over-art table: minimum black alpha at the text line `ink.100` 0.60, `ink.80` 0.68, `spot` 0.66, `set` 0.70, `ink.60` 0.82, `proof` 0.84), §2.2.2 (the grid and the Diagnostics "Show the layout grid" overlay), §2.4 (focus ring, z layers).
   - §3.3 (mobile text scale, the per-role caps, heights as minimums), §3.4 (Hyperlegible text).
   - §4.5 (every named move and its planned duration), §4.7, §4.8 (the reduced-motion table, authoritative).
   - §5 (haptics per event, the Feedback toggle), §6 (UI sounds off by default; the iOS audio-session State A: `.ambient` with `mixWithOthers`).
   - §7 intro (hit areas: "44 hit" means 44, and 48 on Android), §7.1 (button loading segment), §7.10 (dialogs: the 1000 ms destructive arm, `dur.arm`), §7.11 (toasts: holds, screen-reader rule, `Alt+T`), §7.18 (leader dial, indeterminate rule), §7.29 (`folioLabel()`), §7.30 (Lightbox).
   - §8.0.3 (the `ScreenId` and route table, the shell branches), §8.0.5 (platform rules, back order inside modal states), §8.0.7 (the debug row before the flip), §8.0.9 (tablet and landscape layouts), §8.14.2 (Column wipe), §8.16 (Listen, the highlighter), §8.30.3 (restart mechanics), §8.30.7 (Diagnostics).
   - §10.1 (all of it, including §10.1.6 Flutter), §10.2 (all of it, including §10.2.4 Flutter).
   - §11 (the last column: the alternative for every gesture).
   - §14.1 to §14.11 (every rule), §15.3 (Flutter file map), §15.6 (performance guards), §15.7 (accessibility checks per cluster), §15.8 (verification and the device pass), §15.9 (the motion-timings overlay and `SKIN RESTART`), §15.11 (dependency ledger).
4. `docs/redesign/inventory/mobile.md` §1 (routes and screens), §3 (global chrome G1–G14), §4 (every user action → API or local storage: the checklist that no function was lost), §5 (every settings key), §6 (reader internals, §6c download states).
5. `docs/redesign/inventory/capabilities.md` §1 (cross-cutting contract: 18+ absence, rate limits), §6 (the 18+ gate), §24 (offline downloads).
6. `docs/redesign/00-baseline.md` (the green baseline: `flutter analyze` "No issues found"; `flutter test` 2012 passed, 0 failed, 0 skipped at the time; the counts have grown since, and the floor is what you record below).
7. `docs/redesign/prompts-plan.json`: the entry for `mobile/00` (its `TRACK RULE` binds this file) and the entry for this file.
8. Code you work on: `mobile/lib/skins/cinematic/**` (every screen and primitive), the Cinematic `PENDING` map (`grep -rn "PENDING" mobile/lib/skins/cinematic`), `mobile/lib/skins/skin.dart`, `mobile/test/skins/completeness_test.dart`, `mobile/test/skins/import_boundary_test.dart`, `mobile/test/skins/cinematic/tint_test.dart` (over-art table, surface × ink loop), `mobile/test/skins/cinematic/set_heading_test.dart` and the `TypedHeadline` test from `mobile/04` (`grep -rln "TypedHeadline" mobile/test`), `mobile/lib/skins/cinematic/motion.dart` and `motion_timings.dart`, the screenshot harness (`mobile/test/screenshots/marketing_screenshots_test.dart` and `mobile/test/screenshots/support/`, as `mobile/03` extended it), `mobile/lib/features/reader/engine/` (incl. `page_tint.dart`), `mobile/lib/features/downloads/utils/mature_filter.dart`, the sources request limiter in `mobile/lib/core/network/`, `mobile/lib/skins/skin_audio.dart`, `mobile/RELEASE.md`, `.github/workflows/tests.yml` (the flutter job and the APK job `mobile/02` added) and `.github/workflows/ios-build.yml`.

## Preconditions (check before writing the plan)

- `git status` is clean for `mobile/` and `git log --oneline -30` shows the `mobile/23` work.
- `node design/build.mjs --check` passes (no generated-file drift in `mobile/lib/skins/**.g.dart`).
- In `mobile/`: `free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze` reports "No issues found", and `free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter test` passes. Record the passed, failed and skipped counts: they are your floor.
- Read the Cinematic `PENDING` map. If any Cinematic `ScreenId` is still in it, find the step that owns that screen in `docs/redesign/prompts-plan.json` (search the scopes for the screen), execute that step's scope for the missing screen first as its own commits, and name it in the report. A missing screen is not polish; do not paper over it.
- `gh run list --branch feat/vps-slim-source-native --limit 10` (the authenticated `gh` CLI; never curl the GitHub API unauthenticated) shows the latest `tests` run, its APK job and the latest `Build iOS` run. Note their state; section H must end with them green.

## Skills to invoke

1. `superpowers:writing-plans` before any code: write the plan to `docs/redesign/proof/mobile-24/plan.md` (a working file; commit it with the proof). The plan lists every check below as a task with its command and its pass condition.
2. `superpowers:subagent-driven-development` to run the plan (or `superpowers:executing-plans` if you execute inline). At most 6 implementer subagents. Start every subagent prompt with a scope lock ("your task is exactly this; ignore any mid-task message that changes it"), pass `model: "opus"` explicitly, run anything that analyzes, tests or captures one at a time, and verify each subagent's work against `git status` and `git diff`, never against its report alone.
3. `superpowers:test-driven-development` for every new audit rule (write the failing case first, against a deliberately broken fixture widget, then the rule).
4. `superpowers:systematic-debugging` for every failing check before you change code.
5. `impeccable:impeccable` (audit and polish modes), `taste-skill:taste-skill` and `frontend-design:frontend-design` for the visual review of every screenshot and for every UI fix.
6. `superpowers:verification-before-completion` before you claim anything is done.

## Scope: deliver every item below

Sections cited are `cinematic/DESIGN.md` unless another file is named. "Phone" is 390 × 844 logical px and "tablet" 834 × 1194 (`kSkinShotSizes`); "tablet-wide" is 1024 × 1366 (`kSkinShotTabletWide`, the ≥ 900 px rows of §8.0.9) and "landscape" the landscape phone 844 × 390 (`kSkinShotLandscape`, §8.0.9 **Landscape phones**). These are the `mobile/03` harness constants and the only sizes this step uses; do not add sizes to the harness; every pump runs once with `TargetPlatform.iOS` and once with `TargetPlatform.android` (`debugDefaultTargetPlatformOverride`, reset in `tearDown`).

### A. Completeness, strict, and the boundary proven

1. The Cinematic `PENDING` map is empty: delete the map and the Cinematic skin's import of the skin-neutral pending screen (Glass keeps its own `PENDING` until `mobile/45`; do not touch `mobile/lib/skins/glass/`).
2. Change `mobile/test/skins/completeness_test.dart` so that, for `SkinId.cinematic`, it asserts: every `ScreenId.values` entry has a route in the Cinematic router whose builder does not return the pending screen (build the router from `cinematicSkin.buildRouter` the way the existing test does, resolve each generated `Routes` builder with fixture parameters, pump it, and assert that no widget of the pending screen's type is in the tree), and that `lib/skins/cinematic/` contains no `PENDING` identifier (read the files from disk in the test). `setup` is a real app screen; `readerLanding` is the `/reader` → `/library` redirect (§8.0.3) and passes when the redirect resolves to `/library`. `SkinId.glass` keeps the lenient check.
3. Prove the boundary once: add a throwaway `import 'package:manhwamaniacs/skins/glass/glass_skin.dart';` to one Cinematic screen, run `free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter test test/skins/import_boundary_test.dart`, copy the failure line into `qa.md`, and revert the edit with `git checkout -- <that file>` before anything is committed.

### B. The QA harness (flutter_test, fake providers, no network)

Write these under `mobile/test/skins/cinematic/qa/`. They run in the normal `flutter test` suite, except the text-scale matrix of C6, which registers its tests only when `MM_QA_MATRIX=1` is set (so the normal run stays at 0 skipped).

1. `qa_screens.dart`: one entry per `ScreenId.values` value, each a function that pumps the Cinematic app at that route (the real `cinematicSkin.buildRouter`, `initialLocation` from the generated `Routes` builders) inside a `ProviderScope` whose overrides come from the harness fixtures (`test/screenshots/support/shot_fixtures.dart`, `shot_covers.dart`, `shot_network.dart`; add fixtures that are missing, never real series, sources or art: the install page is public and the app carries mature sources). Parameters: the first fixture follow (`featureByFollow`, `feature`, `reader`, `readAll`, `recap`), a series key that contains `/`, a space and `%` (so the encoded route builders of §8.0.3 are exercised), the first fixture source (`source`), a novel series and chapter with `novels_enabled` true (`novel`), the first fixture collection (`collection`), the current year (`annual`), the second fixture profile (`circleMember`, `profileEdit`). The file throws at load time when a `ScreenId` has no entry.
2. `qa_audit.dart`: `Future<List<QaViolation>> auditScreen(WidgetTester tester, {required TargetPlatform platform})`, each violation carrying a finder description, the rule and the measured value:
   1. **Exceptions:** `tester.takeException()` is null after the pump (no overflow, no assertion, no layout error).
   2. **Tap targets (§14.6):** `meetsGuideline(iOSTapTargetGuideline)` (44 × 44) under iOS and `meetsGuideline(androidTapTargetGuideline)` (48 × 48) under Android; plus a spacing rule over the semantics tree (`tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode`, every node with `SemanticsAction.tap`): at least 8 px between the rects of adjacent tappable nodes that are not ancestors of each other. Inline text spans inside running text are exempt and listed.
   3. **Labels:** `meetsGuideline(labeledTapTargetGuideline)`; every icon-only control carries `Semantics(label:)` or a `tooltip`.
   4. **Headings (§14.4, §14.5):** exactly one semantics node with `isHeader` and `headingLevel == 1` per screen (the masthead; Discover and Dialogue have a visually hidden one); section heads are level 2.
   5. **Contrast:** `meetsGuideline(textContrastGuideline)`. Where it flags text over art that sits on a ground from the §2.1.4 over-art table, the violation is accepted only if the matching row exists in `tint_test.dart`; record it with that row.
   6. **`ink.45` on the wrong ground (§2.1.1, §14.2):** every `RenderParagraph` whose text colour equals `CineTokens.colorInk45` must have `paper.0` `#000000` as the first opaque background found walking up its ancestors (`ColoredBox`, `DecoratedBox` with a colour, `Material`, `Container.color`); an ancestor painting an image or a gradient counts as "over art" and fails unless the text has its own solid ground.
   7. **Text floor (§3.3, §14.7):** no visible `RenderParagraph` renders below 11 logical px at text scale 1.0.
   8. **Images:** every cover and page image has a semantics label (the series title, "Page 18 of 40") or is excluded from semantics as decorative.
3. `cinematic_qa_test.dart`: for every entry of `qa_screens.dart`, at phone, tablet, tablet-wide and landscape, on iOS and on Android: pump, settle (bounded: `pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10))`, with the loading fixtures resolved), run `auditScreen`, and fail on any violation that is not in the accepted list `qa_accepted.dart` (each accepted entry names its contract section). With `MM_WRITE_QA=1` it also writes each screen's violations to `docs/redesign/proof/mobile-24/audit/<screenId>-<width>x<height>-<ios|android>.json`.
4. `cinematic_focus_test.dart` (tablet-wide 1024 × 1366, hardware keyboard through `tester.sendKeyEvent`): on every screen, a route change moves focus to the masthead's `FocusNode` (§14.4); `Tab` 60 times, recording each focused rect: every focused widget paints `CineFocusRing` (the bone stroke over the `#000000` band out to 6 px, §2.8.2), the ring is not clipped (the focused rect inflated by 6 px lies inside the nearest clip), rails take one tab stop, and the order follows the grid's reading order (a jump backwards in y of more than 8 px outside a landmark change is recorded and fixed); opening a sheet (`CineSheetRoute`), a dialog, the command palette where the tablet has it, and the Lightbox traps focus and returns it to the trigger on close.

### C. Accessibility rules of §14 and every §15.7 check, on every screen

Work through each bullet of §15.7 and each subsection of §14, and record a pass or a fix in `qa.md`:

1. **Contrast (§14.2, §15.7 first two bullets):** `tint_test.dart` passes, including the surface × ink loop and the over-art table composited over `#FFFFFF` and `#F5F547` (≥ 4.5:1; ≥ 3:1 for large text and icons). Walk every screenshot of section E and every place where text or an icon sits over a cover, a page, a duotone field or a blurred copy, and make sure each (component, ink, ground alpha) has a row, including the 44 pt iOS and 48 dp Android running head at text scale 1.0 and at the largest scale and the page-tinted chrome at the most saturated `page.tint` (S 0.35, L 0.06). Add the missing rows.
2. **Colour is never the only signal (§14.3):** health states carry a label and a square mark, cautions the `NOTE` kicker, errors the `CORRECTION` kicker and the `‸` margin mark, download states distinct shapes (§7.18, inventory `mobile.md` §6c), reactions a glyph and a name, charts a text summary and a label on every mark. Check each screen that shows them.
3. **Keyboard and focus (§14.4):** the results of B4; single-key shortcuts turn off in Settings → Keyboard and stop firing on a hardware keyboard (widget test: with the setting off, a `j` key event on the reader does nothing, `Esc` still closes the top layer).
4. **Increase Contrast (§14.4, §14.7):** with `tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(highContrast: true)`, the skin root applies `CineTokens.copyWith(colorInk45: colorInk80, colorRule1: colorRule2)`: a widget test finds no `RenderParagraph` coloured `ink.45` and no rule painted `rule.1` on three representative screens (Tonight, Library, Settings).
5. **Screen readers (§14.5):** `cinematic_screen_reader_test.dart` with `FakeAccessibilityFeatures(accessibleNavigation: true)`: a toast with an action never times out; the reader chrome never auto-hides; the recap countdown never starts; The Annual does not auto-advance; guided view does not auto-advance; the Listen post-play countdown waits. Without the flag: timers pause while any `FocusNode` inside the timed element has focus (toast holds, the chrome idle hide, the mini-player linger). The reader's live region (`Semantics(liveRegion: true)`) carries exactly "Chapter 143, The Return · Solo Leveling" (or "Chapter 143 · Solo Leveling" without a chapter title) on entry and on a chapter change, and does not change on a page change; the ruler exposes the value "Page 18 of 40"; folios read in full through `folioLabel()`; the Lightbox is labelled "Cover of {title}"; `SetHeading` and `TypedHeadline` expose their full text from the first frame (read the semantics tree 100 ms after navigation, while the animation still runs).
6. **Text size (§3.3, §14.7), the matrix:** `cinematic_text_scale_test.dart`, registered only with `MM_QA_MATRIX=1`: every screen at phone and tablet, at `textScaleFactorTestValue` 1.0, 1.3 and 2.0, each once plain, once with `FakeAccessibilityFeatures(boldText: true)`, once with Hyperlegible text on (Settings → Appearance, the per-profile key from `mobile/18`): no exception (no overflow), and every `RenderParagraph` with `didExceedMaxLines` true is one the contract truncates (list each in `qa_accepted.dart` with its §7 or §8 rule); Bold Text adds 120 to every role's `wght` (read the `FontVariation('wght')` of three roles). Also "Transmigration" in `type.cover` at 2.0 in a 358 px column falls back to the plain string with no overflow (§10.1.1).
7. **Every gesture has an alternative (§14.8):** for every row of §11 whose platform includes iOS or Android, operate the alternative named in its last column (button, menu item or key) in a widget test and confirm it does the same thing; long-press menus are mirrored by a visible `dots-three` button, the Lightbox by `View cover`, swipe actions by row menus, edge swipes by setup-sheet controls. Rows that cannot be exercised in a widget test go to the device pass (section I).
8. **Haptics and sound (§14.9):** with the per-profile haptics toggle off, the fake `mm/platform` channel and the fake `haptic_feedback` and `gaimon` handlers receive no calls while a scripted session taps through Tonight, Library, a sheet and a destructive confirm; UI sounds are off for a new profile (`skin_audio.dart` plays nothing) and stay silent while narration or a soundscape plays.
9. **Flashing (§14.10):** record the caret blink (530 ms halves, 0.94 Hz), the skeleton flicker (0.36 Hz) and the sparks (once a second) from their controllers' durations in `qa.md`; nothing exceeds three flashes a second.
10. **Content safety (§14.11) and the 18+ on-device checklist (§15.7):** `cinematic_mature_absence_test.dart` over `sqflite_common_ffi`: seed a mature series with one downloaded chapter, a bookmark in the offline bookmark store, an offline follow and a queued progress outbox entry; close the gate: the Downloads list, its counts and the storage meter, Library offline, Tonight's offline edition, Bookmarks, History and Discover search show none of it and say nothing about it, and a queued download of that series pauses silently; reopen the gate: all of it returns untouched. A World card shows the 16 px certificate when `is_adult` is true or any `available[]` source is mature, and is absent with the gate closed. Share cards draw only the `shareable` block (render one to PNG with `RepaintBoundary.toImage` and assert no fixture mature title appears in its text spans). The same checklist runs on both devices in section I.
11. **Destructive confirms (§7.10, §15.7):** a widget test for every destructive confirm in the app: two taps 150 ms apart on its trigger and confirm button do not confirm (the 1000 ms `dur.arm` holds), a tap after 1000 ms does; with reduced motion the rule appears full at 1000 ms with no fill. List each confirm tested in `qa.md`.
12. **Spoiler guard (§15.7):** reactions checked on an unread, a half-read and a finished chapter fixture.

### D. Reduced motion (§4.8, §14.1)

1. `cinematic_reduced_motion_test.dart`, with `FakeAccessibilityFeatures(disableAnimations: true)`, and again with the OS flag off and the in-app switch Settings → Appearance → "Reduce motion in the app" on (both must make `CineMotion.reduced(context)` true): on every screen in its ready state, `pumpAndSettle` completes within 2 s of fake time (nothing loops); a separate case pumps the three allowed loaders (the leader dial, the indeterminate rule, the button loading segment of §7.1 and §7.18) and asserts they still animate; every `CineMotion.play` call recorded by the motion-timings recorder during a scripted walk (push, pop, sheet, dialog, tab change, toast, Lightbox open and close) has a planned duration of 200 ms or less; no `SetHeading` builds a per-letter `Transform` or `ImageFiltered` (the whole string fades over 200 ms); every `TypedHeadline` shows its full text at once with no caret; Drift shows a still frame at scale 1.03; programmatic scrolls jump (after one pump the `ScrollPosition.pixels` equals the target).
2. Walk every row of the §4.8 table and tick it in `qa.md`, naming the test or the device-pass row that proves it: Column wipe, Iris, match cut and Stop the press become a 200 ms cross-fade; Page, Dip, Rise and Insert a 150 ms fade; skeletons static at 0.8; rules present at rest; Folio flip instant; auto-scroll never auto-starts; guided view cuts; streak loops static; the trailer scrub scrolls away normally and the now-showing strip fades in over 150 ms; Cut to home cross-fades; the Lightbox fades and still drags to dismiss; the arm rule appears full at 1000 ms; the recap and Listen countdowns update a label once per second; the voice pulse is a static band; the colophon is a still page; page-tint and ambient swaps are instant and page tint changes at most once every 2 s; gestures still track the finger and finish with a 150 ms fade.

### E. Screenshots of every `ScreenId`

Extend the harness with a new file `mobile/test/screenshots/cinematic_qa_shots_test.dart` built on `support/skin_shots.dart` (`captureSkinScreen` for each route with the parameters of `qa_screens.dart`, `captureSkinWidget` for fixture states), with three groups that the verification runs one at a time, each with its own `MM_PROOF_DIR` (see **Proof output location** under Verification):

- group `mobile-24 screens` → `docs/redesign/proof/mobile-24/screens/`: every `ScreenId` at `phone`, `tablet`, `tablet-wide` and `landscape`, each once with the layout-grid overlay off (`cinematic-<screenId>-<w>x<h>.png`, the name `captureSkinScreen` writes) and once on (`captureSkinWidget` named `<screenId>-grid`, so `<screenId>-grid-phone.png` and so on; the Diagnostics "Show the layout grid" overlay of §2.2.2, turned on through its provider);
- group `mobile-24 states` → `docs/redesign/proof/mobile-24/states/`: `<screenId>-<state>-phone.png` and `-tablet.png` for each loading, empty, error and offline state the contract defines for that screen (fixtures that delay, fail or report offline);
- group `mobile-24 a11y` → `docs/redesign/proof/mobile-24/a11y/`: `<screenId>-scale2-phone.png` (`textScale: 2.0`), `<screenId>-bold-phone.png`, `<screenId>-contrast-phone.png` and `<screenId>-legible-phone.png`.

Review every image with `impeccable` and `taste-skill` against the contract and fix what is wrong (off the 4-column phone grid or 8-column tablet grid, text off the baseline, `ink.45` on a raised stock, a clipped focus ring, a scrim that does not reach the text). The harness renders with the test renderer; motion and 120 Hz are proven in section I, not here.

### F. Signature animations actually play

Extend the `mobile/04` tests (keep their file names):

1. **Typing reveal on Tonight (§10.2):** pump Tonight with the cover-story fixture; request focus on the headline at 100 ms; at 200 ms the 10th grapheme is still transparent (read the `TextSpan` colours) and the caret is present: focus did not skip it. After `n × 50 ms + 3,180 ms + 160 ms + 200 ms` (`n` = the headline's grapheme count, spaces included) every grapheme is revealed and the caret is gone. A tap on the headline completes it at once, and so do `Enter` and `Space` while it is focused; the count never advances again afterwards. Pump Tonight again for the same profile on the same day: the headline shows at rest immediately (once per day per profile).
2. **Letter set (§10.1):** an H3 `SetHeading` with `trigger: inView` below the fold keeps its letters at opacity 0 until it is 50 % visible; scroll it in; within 1,420 ms (the 120 ms rule lead, at most 560 ms of stagger and the 640 ms letter move, plus 100 ms of slack) every letter is at opacity 1, offset 0 and blur 0. A second pump in the same session shows it at rest. A masthead (`trigger: mount`) plays once per session; a `signal` title (a feature page title) plays on every visit, starting when the route animation completes.
3. **Reduced motion:** both render their full text immediately; the Letter set is one 200 ms fade and the typed headline has no caret.

### G. Performance guards (§15.6), as they apply to Flutter

Check each and record the evidence (a test name or a code reference) in `qa.md`:

1. Grain and Drift run only on the one visible hero or spread art and pause off screen (`TickerMode` false when scrolled away: assert the hero's `AnimationController.isAnimating` is false after scrolling it out).
2. At most one animated blur layer per screen outside letter reveals and Rack focus; Rack focus runs on at most 12 images at once (pump a Discover results fixture of 40 items and a tablet Library wall; count running `ImageFiltered` animations).
3. Duotone `ColorFilter.matrix` instances are cached per colour (`duotone.dart` returns the identical instance for the same `ambient.duo`); spreads request covers at `w=720` (the fake image client records URLs) and never upscale sharp art.
4. The reader runs no grain, blur, drift or backdrop effect over pages: in a reader fixture, `find.descendant(of: <the strip>, matching: find.byType(BackdropFilter))`, `ImageFiltered` and the grain `CustomPaint` all find nothing.
5. Page-tint sampling runs at most every 600 ms in `compute()` on a 16 × 16 decode: during a scripted 10 s fling over the demo pages the sampler is called at most 17 times; panel detection shares the isolate at 360 px wide, one page ahead.
6. The trailer scrub relayouts one pinned sliver header (a test counts `RenderSliverPersistentHeader` layouts per frame: one).
7. The edition preview PNG loop mounts only on Settings → Appearance and onboarding step 1, and unmounts on leave.
8. The Lightbox decodes the full cover only on open; Cut to home flies at most 12 posters.
9. The sources request limiter: its test in `mobile/test/core/network/` is green; a scripted 3-minute fake-clock browse never starts more than 50 requests to `/sources/*`, covers and page images in any 60 s window; P3 prefetch pauses below 20 free slots; a fake 429 with `Retry-After: 5` pauses P2 and P3 for 5 s.
10. Rails build lazily beyond 30 items (`ListView.builder`); walls use `SliverGrid`.

### H. CI: the APK build and the iOS dry run

After the last fix is pushed, `gh run list --branch feat/vps-slim-source-native --limit 5` shows, for that commit, the `tests` workflow green (backend, web and flutter jobs, and the `flutter build apk --release` job `mobile/02` added) and the `Build iOS (unsigned, for sideload)` workflow green (`gh run watch <run-id> --exit-status`). A red run is a defect of this step: read its log (`gh run view <run-id> --log-failed`), fix, push, and watch again. Record both run URLs in `qa.md`. Pushing this branch publishes the IPA to the owner's SideStore source (the `ios-build.yml` release step); that IPA is the one the owner uses for section I.

### I. The owner's device pass (§15.8)

1. **Audio-session probe.** If `grep -rn "AVAudioSession()" mobile/lib` finds no existing probe, add one: in `mobile/lib/skins/skin_audio.dart`, right after `SoLoud.instance.init()` and when a Hear sample ends, read `await AVAudioSession().category` (`package:audio_session/audio_session.dart`, 0.1.25, iOS only; skipped elsewhere) and store it in `audioSessionProbeProvider` (`afterInit`, `afterHear`, each a category name and a time). Show it in Cinematic Settings → Diagnostics under the two developer switches as one row "Audio session (iOS)" reading `After sound init: ambient · After a sample: ambient` (`mono` values, `set` when both are `ambient`, `proof` otherwise), and `debugPrint` both values. If the value after init is not `ambient`, `skin_audio.dart` re-applies State A right after init (§6) in the same commit.
2. Write `docs/redesign/proof/mobile-24/device-pass.md` for the owner: one line per check, each with an empty result box and a "notes" cell, split by device (iPhone with the IPA from section H through SideStore; the Android flagship with a signed release APK built where the signing key lives, per `mobile/RELEASE.md`, never Gradle on this box, so it installs over the existing app and keeps its downloads). Every row names the motion-timings overlay reading to expect (Settings → Diagnostics → "Show motion timings": no `proof` row, no dropped frame, no overrun of more than one frame):
   - the Edition (debug) row switching LEGACY → CINEMATIC and back (`SKIN RESTART` under 1,500 ms);
   - the Column wipe into both readers, the Dip out, the Iris (picker → shell), the trailer scrub on Tonight, Cut to home at the end of onboarding, the Lightbox open, drag-to-dismiss and close, the match cut from a poster and its reverse (iOS edge swipe reverses it with the finger; Android predictive back fades through);
   - the reader at 120 Hz with page tint on: a 120-page, 2,880 px webtoon scrolled end to end with 0 dropped frames; Android `flutter_displaymode` reports the high refresh rate in Diagnostics;
   - the Rack focus cap at first load (§15.8, §15.6): a Library wall of at least 40 followed series and a Discover results page of 40 items, each opened cold: at most 12 covers rack-focus at once, 0 dropped frames;
   - the Listen highlighter following the narration, the lock-screen controls (`audio_service`), shake to extend the sleep timer;
   - iPhone only: the "Audio session (iOS)" row reads `ambient` after sound init and after a Hear sample;
   - text scale 1.0, 1.3 and 2.0 (iOS Larger Text; Android font size), Bold Text on, Increase Contrast on (iOS) and high-contrast text (Android), Hyperlegible text on: Tonight, Library, a feature page, the reader chrome, Listen, Settings; nothing clips;
   - VoiceOver (iPhone) and TalkBack (Android): the masthead is announced on every route change, the reader announces the chapter and not pages, toasts with an action stay, the reader chrome stays, every row's swipe action is reachable as a custom action or through its row menu;
   - Reduce Motion (iOS) and Remove animations (Android): three rows of §4.8 by eye (Column wipe cross-fade, Lightbox fade, trailer scrub scrolls normally);
   - haptics on the listed §5 events with the Feedback toggle on, none with it off; UI sounds off by default, on after opting in, silent under narration;
   - the 18+ checklist of C10 on the device (with a real mature fixture series the owner picks on a working 18+ source), the seed restored afterwards;
   - every destructive confirm resists a double tap.
3. The session does not wait for the owner: `qa.md` lists the device pass as "awaiting owner" with the file path, and `release/00` checks it before shipping.

### J. Fix everything, then `qa.md`

Every failure found in A to I is fixed in the Cinematic skin (or in the shared data layer when that is where the fault is), one commit per fix, with the check re-run after the fix. Then write `docs/redesign/proof/mobile-24/qa.md`:

- a table with one row per check (section and item, command or test name, result, the commit SHA of the fix when there was one);
- the audit summary per screen (0 violations is the target; every accepted exception is listed with its reason and the contract section that allows it);
- the §4.8 table with each row's proof;
- the screenshot inventory;
- the CI run URLs (APK build, iOS dry run);
- the device pass status ("awaiting owner", with the checklist path);
- open issues, each with the contract section it concerns.

## Out of scope here (do not build)

- The flip itself (`release/00`): the default skin, deleting `legacy`, the version bump and the ship.
- Any Glass work; any new feature; any change in `frontend/` or `backend/`.
- The "Front pages" set and `og.png` (`web/24` owns them).

## File layout

```
mobile/lib/skins/cinematic/**                              PENDING removed (A1); fixes (J)
mobile/lib/skins/skin_audio.dart                           audio-session probe and State A re-apply if needed (I1)
mobile/lib/skins/cinematic/screens/settings/…              the "Audio session (iOS)" Diagnostics row (I1; find the Diagnostics screen file with grep "Show motion timings")
mobile/test/skins/completeness_test.dart                   strict for cinematic (A2)
mobile/test/skins/cinematic/qa/qa_screens.dart             B1
mobile/test/skins/cinematic/qa/qa_audit.dart               B2
mobile/test/skins/cinematic/qa/qa_accepted.dart            accepted exceptions with their sections
mobile/test/skins/cinematic/qa/cinematic_qa_test.dart      B3
mobile/test/skins/cinematic/qa/cinematic_focus_test.dart   B4
mobile/test/skins/cinematic/qa/cinematic_screen_reader_test.dart   C5
mobile/test/skins/cinematic/qa/cinematic_text_scale_test.dart      C6 (MM_QA_MATRIX=1 only)
mobile/test/skins/cinematic/qa/cinematic_mature_absence_test.dart  C10
mobile/test/skins/cinematic/qa/cinematic_confirm_arm_test.dart     C11
mobile/test/skins/cinematic/qa/cinematic_reduced_motion_test.dart  D1
mobile/test/skins/cinematic/qa/cinematic_perf_guards_test.dart     G
mobile/test/skins/cinematic/tint_test.dart                 new over-art rows (C1)
mobile/test/skins/cinematic/set_heading_test.dart and the TypedHeadline test   F (extended)
mobile/test/screenshots/cinematic_qa_shots_test.dart       E
mobile/test/screenshots/support/*                          missing fixtures only
docs/redesign/proof/mobile-24/                             plan.md, qa.md, device-pass.md, audit/, screens/, states/, a11y/
```

Skin files import only `features/*/{models,providers,repositories,services,store,queue,utils,controllers,engine}`, `core/`, `shared/` and their own `skins/cinematic/**`; the boundary test enforces it.

## Acceptance criteria

- [ ] The Cinematic skin has no `PENDING` map, and `completeness_test.dart` fails if any `ScreenId` resolves to the pending screen in the Cinematic router.
- [ ] The boundary proof is recorded in `qa.md` (the failure line) and the throwaway import is not in any commit.
- [ ] `cinematic_qa_test.dart` passes for every `ScreenId` at 390 × 844, 834 × 1194, 1024 × 1366 and 844 × 390 on iOS and Android: no exception, 44 × 44 targets under iOS and 48 × 48 under Android with ≥ 8 px spacing, labelled targets, one level-1 heading, contrast, `ink.45` only on `paper.0`, no text below 11 px, labelled images; every accepted exception is listed with its section.
- [ ] Hardware-keyboard focus: route changes focus the masthead, every focused widget shows the unclipped `CineFocusRing`, rails are one tab stop, the order follows the reading order, sheets, dialogs and the Lightbox trap and return focus.
- [ ] The `tint` tests pass with the over-art table complete for every text or icon run over art in the screenshots.
- [ ] Increase Contrast remaps `ink.45` → `ink.80` and `rule.1` → `rule.2`; Bold Text adds 120 `wght`; the text-scale matrix (`MM_QA_MATRIX=1`) passes at 1.0, 1.3 and 2.0 plain, bold and Hyperlegible, with every truncation allowed by a named rule; "Transmigration" falls back at 2.0 in 358 px.
- [ ] Screen-reader rules: toasts with actions stay, chrome never auto-hides, the recap countdown, The Annual, guided view and the Listen countdown wait; timers pause while focus is inside; the reader live region announces the §14.4 string on entry and chapter change only; reveals expose their full text from the first frame.
- [ ] Reduced motion (the OS flag, and the in-app switch alone) matches every row of §4.8: only the leader dial, the indeterminate rule and the button loading segment keep running; every recorded move is 200 ms or less.
- [ ] Both signature-animation tests pass: the Tonight headline still types 200 ms after navigation despite focus, skips on tap, `Enter` and `Space` and stays skipped, types once per day per profile; an H3 below the fold waits for 50 % visibility; reduced motion shows both at once.
- [ ] The 18+ absence test passes (every local store filtered, counts silent, a queued download paused, everything back when the gate reopens); share cards draw only the `shareable` block.
- [ ] Every destructive confirm resists two taps 150 ms apart (the 1000 ms arm), each listed; the spoiler guard holds on the three fixtures.
- [ ] Every §15.6 guard has evidence in `qa.md`, including the limiter never exceeding 50 starts per 60 s.
- [ ] Screenshots of every `ScreenId` at the four harness sizes, with and without the grid, plus the state and a11y captures, are in `docs/redesign/proof/mobile-24/{screens,states,a11y}/`, and `git status --short mobile/docs/screenshots` prints nothing.
- [ ] The `tests` workflow (with the APK job) and the `Build iOS` workflow are green for the final pushed commit; their URLs are in `qa.md`.
- [ ] `device-pass.md` covers every §15.8 device item listed in section I, and Diagnostics shows the "Audio session (iOS)" row.
- [ ] Legacy users see no change (the flip is `release/00`): with the debug row on LEGACY, Library and a reader render as before (a harness capture of each, before and after).
- [ ] `flutter analyze` reports "No issues found"; `flutter test` passes with the passed count at or above the floor plus the new tests (never below the 2012 passed of `00-baseline.md`: every test that passed there must still pass) and 0 failed; `node design/build.mjs --check` passes.
- [ ] `docs/redesign/proof/mobile-24/qa.md` exists with every part of section J.

## Verification

**RAM guard (production shares this box).** Before every heavy command run `free -m` and read the `available` column of the `Mem:` row. If it is under 1024 MB, stop and report instead of running it. Never run two heavy commands at once, never run `flutter test` while a `next build` runs (`pgrep -fa "next build"` prints nothing first), and no Gradle or Xcode on this box (CI builds the APK and the iOS dry run).

From `mobile/`:

```bash
free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze
free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter test test/skins
free -m && MM_QA_MATRIX=1 /srv/manhwamaniacs/dev/flutter/bin/flutter test test/skins/cinematic/qa/cinematic_text_scale_test.dart
free -m && MM_WRITE_QA=1 /srv/manhwamaniacs/dev/flutter/bin/flutter test test/skins/cinematic/qa/cinematic_qa_test.dart
free -m && MM_PROOF_DIR=../docs/redesign/proof/mobile-24/screens /srv/manhwamaniacs/dev/flutter/bin/flutter test test/screenshots/cinematic_qa_shots_test.dart --plain-name "mobile-24 screens"
free -m && MM_PROOF_DIR=../docs/redesign/proof/mobile-24/states /srv/manhwamaniacs/dev/flutter/bin/flutter test test/screenshots/cinematic_qa_shots_test.dart --plain-name "mobile-24 states"
free -m && MM_PROOF_DIR=../docs/redesign/proof/mobile-24/a11y /srv/manhwamaniacs/dev/flutter/bin/flutter test test/screenshots/cinematic_qa_shots_test.dart --plain-name "mobile-24 a11y"
free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter test
cd .. && node design/build.mjs --check
```

**Proof output location.** The `mobile/03` harness (`mobile/test/screenshots/support/skin_shots.dart`) writes a capture only when `MM_PROOF_DIR` is set, so every capture command above sets it (to the `screens`, `states` or `a11y` folder of `docs/redesign/proof/mobile-24/`, relative to `mobile/`) and never `MM_WRITE_SHOTS`, which makes the legacy marketing tests overwrite `mobile/docs/screenshots/`, the install page's public screenshots. The sizes are the four harness constants named at the top of the Scope. After the runs, `git status --short mobile/docs/screenshots` must print nothing.

`flutter analyze` must report "No issues found" and the full `flutter test` run must pass with no failures, at or above the floor (never below the 2012 passed of `00-baseline.md`: every test that passed there must still pass). This step changes nothing in `frontend/` or `backend/` (`git show --name-only --format= <hash> -- frontend backend` for each of your own commits (never a branch or range diff: parallel sessions commit on the same branch) is empty), so `npm run lint` and `npm run build` (in `frontend/`) and the backend pytest (`backend/.venv/bin/python -m pytest -q --no-header` from `backend/`) are not rerun, except the push rule under Git. CI (section H) runs every suite on the pushed commit.

**Visual proof.** Everything in section E lands under `docs/redesign/proof/mobile-24/` from the harness at the exact sizes above. Compare each phone capture (`screens/cinematic-<screenId>-390x844.png`) with the web twin's `docs/redesign/proof/web-24/screens/<screenId>-390x844.jpg` when present and list the differences that the contract does not explain (stack-decision risk 1).

## Git

- Branch `feat/vps-slim-source-native`. Commit small and often: the strict completeness change, the QA harness, then one commit per fix (`fix(mobile-cinematic): ink.45 on paper.2 in the filters sheet`), the audio-session probe, then the proof and `qa.md`. Stage your paths explicitly (`git add mobile/test/skins/cinematic/qa/cinematic_qa_test.dart …`, `git add docs/redesign/proof/mobile-24`), never `git add -A` or `git add .`, because the web, backend and shared sessions commit in the same checkout.
- Conventional messages. No Claude or AI attribution anywhere: no `Co-Authored-By` line, no "Generated with" line, no AI author. Never commit secrets (the signing key and `android/key.properties` stay off this box and out of git) or `.claude/`.
- Before every push: `git fetch origin` and `git diff --stat origin/feat/vps-slim-source-native...HEAD -- frontend`. If it lists files (another session's commits), run `free -m && npm run build` in `frontend/` first (never while `flutter test` runs) and push only if it passes; then `git push origin feat/vps-slim-source-native` after each working step.
- Never edit `backend/connectors/`. Never touch production containers or `/srv/manhwamaniacs/{app,data}`. Do not deploy: the flip is `release/00`.

## Report back

Reply with:

1. Done items by section (A to J), and anything not done with the reason.
2. Any `ScreenId` that was still pending at the start and which step's scope you executed for it.
3. Paths: `docs/redesign/proof/mobile-24/qa.md`, `device-pass.md` and the screenshot folders.
4. Test counts: `flutter test` passed, failed and skipped before and after; the matrix run's count; `flutter analyze` result; the `free -m` available figure before each heavy command.
5. Audit totals (violations found, fixed, accepted with reason); the number of fix commits.
6. The CI run URLs (tests with the APK job, Build iOS) and their state.
7. Open issues, each with its contract section, and the device pass status.

Next prompt file: `docs/redesign/prompts/release/00-cinematic-flip-release.md` (it also waits for `docs/redesign/prompts/web/24-cinematic-qa-polish.md` and for the owner's device pass). After the flip, the mobile track continues with `docs/redesign/prompts/mobile/25-glass-foundation-material-physics.md`.
