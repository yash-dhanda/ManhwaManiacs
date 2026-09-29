# Mobile Glass QA and polish

Track: mobile · Order 109 · Depends on: `docs/redesign/prompts/mobile/44-glass-ambient-reader-extras.md` · Web twin: `docs/redesign/prompts/web/45-glass-qa-polish.md` (runs in parallel) · Proof folder: `docs/redesign/proof/mobile-45/`

## Goal

Every Glass screen now exists in the Flutter app (steps `mobile/25` to `mobile/44`). This step proves the whole Glass skin on iOS and Android against every check in `glass/DESIGN.md` §15.8, and fixes everything that fails, so that `release/01` can make Glass available. It runs the same checklist as `web/45` on Flutter:

- the strict completeness and boundary tests, with the Glass `PENDING` set empty;
- the physics test and the contrast gate, plus the three worst glass cases checked in widgets;
- the calibration capture and the comparison with the web;
- harness screenshots of every `ScreenId` at phone, large-phone, tablet and desktop-frame sizes, plus Reduce Motion, Solid glass, Increase Contrast, Bold Text, Legible text, text scale 1.0, 1.3 and 2.0, and every state, with Cinematic beside Glass;
- the screen-reader behaviours, including the VoiceOver and TalkBack custom actions;
- reduced motion against §4.10 and §4.11, all 116 motion names, and the planned settle times;
- the two signature animations;
- the accessibility pass of §14 with the gate-close checklist of §14.11;
- the §15.7 budget: at most 6 `LiquidGlassLayer`s and 8 glass shapes (the eight `BackdropGroup` members) per frame;
- the "Float" parity captures;
- a cross-skin switch in both directions through the debug row.

On top of that, it covers what only phones have: the owner's device pass at 120 Hz on the iPhone and the Android flagship (the dock, sheets, poster zoom, stack overview, the reader with the hit lens, cruise, rain, Wrapped), and a green CI APK build and iOS dry run. Fix every defect in its own commit, and write `docs/redesign/proof/mobile-45/qa.md`. You add no features. When a check needs something the contract does not define, the contract wins and the gap goes into `qa.md` as an open issue.

## Read first

Read these completely before planning. Where this file and `glass/DESIGN.md` disagree, `glass/DESIGN.md` wins; say so in the report.

1. `docs/redesign/inventory/00-decisions.md`, all of it. The two signature animations are binding; the base is dark AMOLED `#000000`; the target is flagship-only maximum effects; "Still honor OS reduced-motion for accessibility"; the haptics must be rich on iOS and Android.
2. `docs/redesign/stack-decision.md`: §2.3 (the completeness test, the import-boundary test, the reader engine), §2.4 and §2.5 (the skin mirror `mm.skin.active`, the return route `mm.skin.return`, `AppRestart`, the 1.5 s budget, downloads re-queued), §3 "Release model", and §4 risks 3, 4, 5, 9 and 11.
3. `docs/redesign/glass/DESIGN.md`:
   - **Colour, material and type.** §2.1.2 (text on glass is `onGlass` or `onTint`; the backing disc; `label1` to `label4`, `g500` and `g600`; the T4/T5 mapping). §2.1.7 (the dims, the legibility floor, the three worst cases). §2.1.8 (the field table with its per-screen opacity; the "Text over the brighter fields" rule). §2.4.1 (the three glass rules, the Flutter budget of 6 layers and 8 shapes, focus rings never clipped). §2.4.3 (the thickness scale, the Flutter `LiquidGlassSettings` mapping, the calibration knobs). §2.6 (the two-tone ring; Flutter `FocusRingSpec` as a `foregroundPainter` outside `ClipRSuperellipse`). §3.2 (the smallest role is 11 px), §3.3 (all of it: the factor `f`, rules 1 to 5), §3.5 (`GRAD`, Bold Text) and §3.6 (Legible text).
   - **Motion, haptics and sound.** §4.2 (the spring table with its settle times), §4.10 (the 116-row motion table, every last column; **Stack fan** and **Address drain** exist only on Flutter) and §4.11 (all of it: sources of each setting, `glassMotionPrefsProvider`, `glassAssistiveProvider`, the Reduce Motion table, Reduce Transparency and Solid glass, Increase Contrast). §5 (all of it: rate limits, the Android rule, `haptics.systemEnabled`, depth-scaled `nav.push`, the event table, the AHAP files, "Feel it"). §6 (sounds off by default; suppression; the audio-session owner `skin_audio.dart`).
   - **Components.** §7.12 (toasts; the Dismiss action), §7.15 (the dock: minimise, the four tabs kept in semantics), §7.24 (states), §7.25 (the 18+ gate alert and hold), §7.34 and §7.35 (swipe and reorder custom actions), §7.37 (the stack overview, its semantics, the "All levels" action).
   - **Shell and settings.** §8.0.1 (frames and the orientation rule). §8.0.3 (the `ScreenId` and route table, the `?sheet=` ids). §8.0.5 (back per platform, the Android back order, exclusion rects). §8.0.7. §8.0.8 in full: the availability flag, the 18+ purge steps 1 to 6, focus on navigation, the Flutter status screens. §8.0.9. §8.1 (Setup and the **Address drain**). §8.2 (splash). §8.25.1, §8.25.2 (the switch flow, the melt, the icon rule). §8.25.12 (Diagnostics: "Glass layers on screen", "Preview Glass skin", "Glass calibration", "Show motion timings", the FPS, Jank and Worst frame rows). §8.28.
   - **Signature and accessibility rules.** §10.1 and §10.2 in full, including the Flutter implementation paragraphs (`letter_reveal.dart`, `typed_headline.dart`, `revealedHeadingsProvider`, `revealWhenVisible`). §11 (the last column: the alternative for every gesture). §12.2 (the icon rule, gated by the flag), §12.4 (Droplet reveal timings), §12.5 (the "Float" set) and §12.7 (demo art: no real names or covers). §13 (the 28 signature moments and their Reduce Motion versions). §14.1 to §14.11 (every rule, and the gate-close checklist with its share-card check).
   - **Implementation.** §15.3 (the Flutter file map, packages, sheets, the accessibility scope, native `mm/platform` methods, shader prewarm), §15.7 (all of it, and the Flutter column of the live-surface table row by row), §15.8 (every bullet), §15.9, and §15.10 rows G5, G7, G10, G13, G15 and G16.
4. `docs/redesign/inventory/mobile.md`: §1 (route table), §3 (global chrome G1 to G14), §4 (every user action: the checklist that no function was lost) and §5 (every settings key that must survive).
5. `docs/redesign/inventory/capabilities.md` §1 (the cross-cutting contract: 18+ absence, rate limits) and §6 (the 18+ gate).
6. `docs/redesign/00-baseline.md`: the green baseline you must keep (`flutter analyze` clean, 2012 tests passing).
7. `docs/redesign/prompts-plan.json`: the entry for `mobile/00` (its `TRACK RULE` binds this file), the entry for this file, `mobile/24` (the Cinematic QA you extend instead of forking) and `release/01` (what it will do after you, so you do not do it here).
8. The web twin `docs/redesign/prompts/web/45-glass-qa-polish.md` and, when it exists, `docs/redesign/proof/web-45/qa.md`. Its calibration counts, Float frames and open issues are inputs to D and L.
9. `docs/redesign/proof/mobile-24/qa.md` (the Cinematic QA harness and its conventions) and, when present, `docs/redesign/proof/mobile-{03,25,29,44}/report.md` (the glass-gate decision, `SkinGlass`'s registry, the shell, the ambient extras).
10. Code you work on:
    - `mobile/lib/skins/glass/**`, every screen and primitive. The Glass `PENDING` map: `grep -rn "PENDING" mobile/lib/skins/glass`.
    - `mobile/test/skins/completeness_test.dart`, `mobile/test/skins/import_boundary_test.dart` and `mobile/test/skins/glass/glass_physics_test.dart`.
    - `mobile/lib/skins/glass/motion.dart` (`GlassMotion.play` and the motion-timings overlay), `motion_names.g.dart`, `skin_glass.dart` (the layer and shape registry, `GlassQuality`), `haptics.dart`, `mobile/lib/skins/skin_haptics.dart`, `mobile/lib/skins/skin_audio.dart`.
    - The Diagnostics screen (`grep -rln "Glass calibration" mobile/lib/skins/glass`).
    - `mobile/lib/app/app_restart.dart`, `mobile/lib/main.dart` (`SkinBoot`).
    - The screenshot harness `mobile/test/screenshots/marketing_screenshots_test.dart` and its `support/`, plus the Cinematic QA helpers from `mobile/24` (`grep -rln "mobile-24" mobile/test`).
    - `mobile/lib/skins/glass/wrapped/share_card.dart`, `design/check-contrast.mjs`, `brand/glass/`, `brand/demo/`.

## Preconditions (check before writing the plan)

- `git status -- mobile` is clean and `git log --oneline -30` shows the `mobile/44` work.
- `node design/build.mjs --check` passes. That covers the generated files, the motion names, the AHAP files and the contrast gate.
- Run `free -m`. If `available` is at least 1024 MB, run `/srv/manhwamaniacs/dev/flutter/bin/flutter test` from `mobile/` once and record the passed count. That number is your floor. It may be below the 2012 of `00-baseline.md`, because `release/00` deleted the legacy widget tests by design (stack-decision §3); compare it with the count `release/00` recorded under `docs/redesign/proof/release-00/` and with the last mobile report. `flutter analyze` reports "No issues found".
- Read the Glass `PENDING` map. If any Glass `ScreenId` is still pending, find the step that owns it in `docs/redesign/prompts-plan.json` (search the scopes for the screen), execute that step's scope for the missing screen first as its own commits, and name it in the report. A missing screen is not polish; do not paper over it.
- `grep -n "glass_available" design/contract.json` shows `false`. It stays `false`; `release/01` flips it. `grep -rn "glassAvailable" mobile/lib/skins/contract.g.dart` shows the generated `Flags.glassAvailable`.
- `cat docs/redesign/proof/mobile-03/glass-gate.md` tells you which engine `SkinGlass` runs: the `liquid_glass_widgets` 1.7.2 liquid engine, or the `BackdropFilter` + `BackdropGroup` frost fallback. Every refraction check below depends on it.

## Skills to invoke

1. `superpowers:writing-plans` before any code. Write the plan to `docs/redesign/proof/mobile-45/plan.md` (a working file; commit it with the proof). The plan lists every check below as a task with its command and its pass condition.
2. `superpowers:subagent-driven-development` to run the plan, or `superpowers:executing-plans` if you execute inline. Use at most 6 implementer subagents. Start every subagent prompt with a scope lock ("your task is exactly this; ignore any mid-task message that changes it") and pass `model: "opus"` explicitly. Only one agent at a time may run `flutter test`, `flutter analyze` or the harness. Verify each subagent's work against `git status` and `git diff`, never against its report alone.
3. `superpowers:systematic-debugging` for every failing check before you change code.
4. `impeccable:impeccable` (audit and polish modes) and `taste-skill:taste-skill` for the visual review of every screenshot. `frontend-design:frontend-design` only for the side-by-side review against the web twin's captures.
5. `superpowers:verification-before-completion` before you claim anything is done.

## Scope: deliver every item below

Sections cited are `glass/DESIGN.md` unless marked. Every widget test below runs inside `flutter test` (so it joins the suite and CI). Every capture runs only in the harness with `MM_WRITE_SHOTS=1`.

### A. Completeness and boundary, strict (§15.8, stack §2.3)

1. The Glass `PENDING` map is empty. Delete the map and the Glass router's use of the skin-neutral pending screen. If no skin uses that pending screen any more (Cinematic's map emptied at `mobile/24`), delete its file too.
2. Change `mobile/test/skins/completeness_test.dart` so that for `glass`, as for `cinematic` since `mobile/24`, it asserts two things. First, every `ScreenId.values` entry resolves in the Glass router to a route whose builder is not the pending screen (`readerLanding` is the redirect to `/library`, G7, and counts). Second, the skin exposes no `PENDING` symbol.
3. The boundary holds. `test/skins/import_boundary_test.dart` fails if a file under `lib/skins/glass/**` imports `/screens/`, `/widgets/`, `app/theme/` or `skins/cinematic/`. Prove it once:
   1. Add a throwaway `import '../../cinematic/cinematic_skin.dart';` (or the matching relative path) to one Glass screen.
   2. Run `flutter test test/skins/import_boundary_test.dart`.
   3. Copy the failure line into `qa.md`.
   4. Revert with `git checkout -- <that file>` before anything is committed.

### B. The QA harness (extend the Cinematic one; do not fork it)

1. **Routes and presentations.** Extend `mobile/24`'s route list helper with a `skin: SkinId` parameter (default `cinematic`, so its tests keep working unchanged). For Glass, the helper builds the Glass app over the fake repositories and returns, for each sheet route (`feature`, `featureByFollow`, `recap`, `circleMember`, `profileNew`, `profileEdit`), both presentations:
   - the deep-link full page (no parent route);
   - the sheet over its base, opened by tapping the real trigger: a poster, a recap offer, a friend orb, the picker's add and edit buttons.

   `setup` is a real screen on Flutter (§8.1). The helper throws if any `ScreenId` is missing. The fixtures live in `mobile/test/fixtures/glass_qa/`, copied for shape from the dev-stack payloads of `backend/scripts/README-dev-stack.md` and given invented titles from §12.7 ("The Ninth Regression", "Salt and Iron", "Moonlit Bakery") and the demo covers and pages of `brand/demo/`.
2. **The Glass audit**, `mobile/test/skins/glass/qa/glass_audit.dart`. `audit(tester, {required TargetPlatform platform})` returns every violation with the widget's key or type path, the rule and the measured value.
   - **G1 Errors:** no `FlutterError` (a `RenderFlex` overflow included) and no uncaught exception while the screen pumps and settles (`tester.takeException()` is null; `FlutterError.onError` is captured).
   - **G2 Headings:** exactly one `Semantics(header: true)` node outside `ExcludeSemantics` and offstage subtrees. After a pushed navigation, primary focus is on that header's `Focus` node (for a sheet route, the sheet title's), and after a pop focus returns to the element that pushed.
   - **G3 Names:** every semantics node with a tap, long-press, increase or decrease action, or with the button, slider, text-field or toggled flag, has a non-empty label. `expect(tester, meetsGuideline(labeledTapTargetGuideline))` passes.
   - **G4 Hit targets (§14.6):** `meetsGuideline(iOSTapTargetGuideline)` (44 × 44) under `TargetPlatform.iOS`, and `meetsGuideline(androidTapTargetGuideline)` (48 × 48) under `TargetPlatform.android`. Between two hit rects there are at least 8 px unless both are sibling shapes of one `SkinGlass` group.
   - **G5 No alpha text on glass (§2.1.2, §14.2):** every `RichText` under a live `SkinGlass` (not a content twin, not a `wellOnGlass` well, not a solid surface) resolves to a colour with alpha 1 that equals `onGlass` `Color(0xFFF2F2F7)` or `onTint` `Color(0xFFFFFFFF)`. Twins, wells and solid surfaces are exempt and listed.
   - **G6 Non-informational greys:** `label4` `rgba(235,235,245,0.24)` and `g500` `#56565F` colour text only inside a disabled control. `g600` `#76767F` never colours text.
   - **G7 Brighter fields (§2.1.8):** some screens have a field opacity above 20 %: Home, the hero enlargement, the image viewer, series detail, book page, the recap deck, the profile picker, Statistics and Wrapped, plus Settings, You and admin under a mood whose own opacity exceeds 20 % (Horror 26 %, Fantasy 22 %, Default 30 %). On those screens, no text in the top 60 % of the viewport that sits directly on the field resolves to `label3` `rgba(235,235,245,0.52)`.
   - **G8 Cover overlays (§7.8, §7.20):** everything drawn over a cover inside a poster or tile (tags, droplet, progress, star, follow bell, play orb) has its own backing with alpha ≥ 0.72.
   - **G9 Text size (§3.2):** no visible text renders below 11 logical px after the text scaler.
   - **G10 Images:** every `Image` has a `semanticLabel`, or has `excludeFromSemantics: true` inside a labelled container.
3. **Test files**, each a normal widget-test file in `mobile/test/skins/glass/qa/`: `glass_qa_test.dart` (C3, F, I1, I2, I4 to I8), `glass_focus_test.dart` (I3), `glass_textscale_test.dart` (I5), `glass_motion_test.dart` (G), `glass_gate_test.dart` (J), `glass_budget_test.dart` (K) and `glass_switch_test.dart` (M). The signature tests extend `mobile/26`'s `typed_headline_test.dart` and `letter_reveal_test.dart` (H).

### C. Physics and the contrast gate (§15.8, first two bullets; §2.1.7)

1. `flutter test test/skins/glass/glass_physics_test.dart` passes and asserts every §15.8 value. Add any value the test does not yet assert:
   - `project(0, 1000) ≈ 499`;
   - `rubberband(100, 800, 0.55) ≈ 51.5`;
   - `{ms: 520, bounce: 0}` → k 146.0, c 24.17, and `{ms: 150, bounce: 0.14}` → k 1754.6, c 72.05;
   - the rail snap of offset 310 at 900 px/s with stride 136 lands on 816;
   - `tierFor(44) == T2`, `tierFor(240) == T4`, and `tierFor(401) == T4` (T5 is never reached by size, §2.4.3);
   - `dimFor(1.0) == 0.64`, `dimFor(0) == 0.22`, and 0.64 for a dark cover with one white patch (mean `l` 0.2, `lMax` 1.0);
   - the depth intensity at depth 3 is 0.54.

   (`web/45`'s prompt writes `tierFor(401) == T5`; the contract says T4. Name this in the report as a web parity issue if `web/45` asserted T5.)
2. `node design/build.mjs --check` passes, and its `check-contrast.mjs` output lists every added case of §15.8: clear glass, other tiers over white, backing discs, wells on sheets, T4/T5 bodies, cover overlays, the ambient field, avatar glyphs, and both negative cases. Copy the output table into `qa.md`. A missing case is an open issue for the shared track; you do not edit `design/`.
3. **The three worst cases in widgets** (`glass_qa_test.dart`, fake engine and fake repositories):
   - The manga reader's top group over a page sample with `pTop = 1.0` settles at dim 0.64 and `GlassTextAxes.grad` 40, and at 0.72 under Increase Contrast (`MediaQueryData(highContrast: true)` on iOS, and separately the in-app switch).
   - The dock's bar group over a Library list whose covers carry `palette.lMax = 1.0` sits over the `edgeSoft` plateau `Color(0xB8000000)` (0.72) up to safe-bottom + 85, with a dim between 0.22 and 0.64.
   - The tinted action over a white page keeps its label at `onTint` `#FFFFFF`.

   Capture each case in the harness into `worst-cases/` and review it.

### D. The calibration comparison with the web (§15.8, §2.4.3)

1. In the harness, capture Settings → Diagnostics → "Glass calibration" (the 16 px checkerboard with the T2 44 px button, the T3 dock and the T4 240 px menu) at 390 × 844, DPR 3. Save it as `docs/redesign/proof/mobile-45/calibration-flutter-harness.png`. It is a top-level file on purpose, because `web/45` finds the newest Flutter capture with `ls -t docs/redesign/proof/mobile-45/*calib*`. Put crops of the T2 button and the T4 menu at 4× nearest-neighbour zoom in `calibration/`, made by the harness compose helper (E6).
2. Say in `qa.md` whether the liquid shaders rendered in `flutter_tester`. If they did not (the capture shows the frost path or flat glass), the harness capture cannot be counted. Add to the device checklist (N) the owner's screenshots of the same page on the iPhone and the Android flagship, to be dropped as `docs/redesign/proof/mobile-45/calibration-flutter-premium-ios.png` and `…-android.png`.
3. Count how many 16 px checker squares each rim bends, at the T2 button and at the T4 menu, on every capture that renders refraction. Take the web counts from `docs/redesign/proof/web-45/qa.md` (or count `docs/redesign/proof/web-45/calibration/web-liquid.png` yourself). Compose the web and Flutter captures side by side into `calibration/side-by-side.png`. A difference of more than one square is an open issue for the shared track, naming the §2.4.3 knob to change in `design/tokens/glass.json` (Flutter `refractiveIndex` 1.2 and `thickness`, web `n` 1.5); you do not edit it.
4. If neither a refracting Flutter capture nor the web counts exist yet, record the item as blocked in `qa.md` with whatever counts exist, and name it in the report. `release/01` must not start until both counts exist.

### E. Screenshots of every `ScreenId` (§15.8 Screenshots)

Add a `mobile-45` group family to `mobile/test/screenshots/marketing_screenshots_test.dart`, with one `--plain-name` per sub-group so each run stays small. Use every route of B1, the demo art only, and invented titles only.

1. **Main sets** (`mobile-45 screens`). Capture at 390 × 844 DPR 3 and at 440 × 956 DPR 3 (the phone frame), at 820 × 1180 DPR 1 (the tablet frame) and at 1180 × 820 DPR 1 (the desktop frame, §8.0.1). Write them to `docs/redesign/proof/mobile-45/screens/<screenId>-<w>x<h>.png`. Sheet routes are also captured as `<screenId>-sheet-<w>x<h>.png`.
2. **Accessibility variants** (`mobile-45 a11y`), one per screen at 390 × 844 DPR 1, into `screens-a11y/<screenId>-{reduced,solid,contrast,bold,legible}.png`:
   - Reduce Motion: `MediaQueryData(disableAnimations: true)`.
   - Solid glass: the `mm/platform` `a11y.reduceTransparency` fake returning true.
   - Increase Contrast: `highContrast: true`.
   - Bold Text: `boldText: true`.
   - Legible text: the in-app switch.

   Also capture each screen once through the in-app switches alone (Settings → Appearance: Reduce motion in this app, Solid glass, Increase contrast), and assert that each result matches its OS-path capture pixel for pixel: the raw RGBA bytes of both captures (`image.toByteData(format: ui.ImageByteFormat.rawRgba)`) are equal.
3. **Text scale** (`mobile-45 textscale`): every screen at `TextScaler.linear(1.0)`, `1.3` and `2.0` at 390 × 844 DPR 1, into `textscale/<screenId>-{1.0,1.3,2.0}.png`.
4. **States** (`mobile-45 states`): each screen's loading, empty, error and offline states that the contract defines (fake repositories delay, fail or report offline), at 390 × 844 and 820 × 1180, both DPR 1, into `states/`.
5. **Both skins side by side** (`mobile-45 pairs`): every route with `skin: cinematic` and with `skin: glass` at 390 × 844 DPR 1, composed into `pairs/<screenId>.png` (Cinematic left, Glass right), so the owner sees that the two skins are different apps on one data layer.
6. **Compose helper.** A small function in the harness's `support/` decodes PNGs with `ui.instantiateImageCodec` inside `tester.runAsync`, paints them onto a `PictureRecorder` canvas (side by side, or cropped and scaled 4× with `FilterQuality.none`) and writes the PNG with `toByteData(format: ui.ImageByteFormat.png)`. No new package.
7. Review every image with `impeccable` and `taste-skill` against the contract, and fix what is wrong: grey frosted cards where glass should refract, alpha text on glass, a bar label without its `edgeSoft` plateau, a clipped focus ring, glass inside a list or the strip, a field that glares, a lower screen that is not true black, a title that wraps at 2.0 where the cap says it clamps.
8. Record `du -sh docs/redesign/proof/mobile-45` in `qa.md`. The folder must stay under 200 MB. If it grows past that, re-capture the variant sets (2 to 5) at DPR 0.75 rather than dropping any screen.

### F. Screen readers (§4.11, §14.5)

In `glass_qa_test.dart`, with `MediaQueryData(accessibleNavigation: true)` (what `glassAssistiveProvider` reads):
- toasts stay until dismissed and carry a close button and the "Dismiss" custom action;
- reader chrome never auto-hides (pump 10 s of fake time: the chrome is still shown);
- Wrapped does not auto-advance;
- voice previews do not auto-play in the orbit;
- the dock never minimises, and when minimised by scroll without a screen reader its four tabs stay in the semantics tree as a tab list.

Independently of the flag, check the semantics tree (`tester.getSemantics`, `SemanticsHandle`):
- headings expose their full text from the first frame, while the reveals still run;
- announcements go through `SemanticsService.sendAnnouncement` (capture `SystemChannels.accessibility` with a mock decoded-message handler): the manga reader announces "Chapter 144" on a chapter change and nothing on page changes, and the guided-view counter and the "Match 1 of 3" capsule announce politely;
- the scrub rail is a slider whose value is "Page 18 of 40";
- a manga page with OCR text has the label "Page 18. Dialogue: …", and one without has "Page 18 of 40";
- hidden reader chrome sits under `ExcludeSemantics` and `ExcludeFocus`;
- locked mode offers the "Unlock controls" custom action;
- swipe rows (§7.34), reorderable rows (§7.35) and the reaction strip expose their actions as `customSemanticsActions`;
- every back button carries the "All levels" custom action, which opens the stack overview (the flat back menu under Reduce Motion or with a screen reader on);
- the stack overview reads "Back to {title}, level {n} of {total}";
- a voice introducing itself shows its transcript caption;
- Wrapped exposes previous, pause and next and each card as a region;
- the recap deck reads as one list with four headings;
- the speed dial is a slider with value "1.25 times" and increase and decrease actions that step 0.05;
- the cruise pill is adjustable, stepping 0.25.

### G. Reduced motion, motion timings and motion names (§4.10, §4.11, §14.1, §15.8)

1. `glass_motion_test.dart` pumps every screen twice with reduced motion: once from the OS alone (`disableAnimations: true`), and once with the OS flag off and the in-app switch on. On each screen, after `pumpAndSettle` plus `pump(const Duration(seconds: 2))`:
   - no ticker remains active except the allowed ones (§14.1): progress indicators as static opacity pulses, the Liquid spinner's and the thinking orbit's 1.2 s pulses, and a user-started cruise. Each allowed one animates opacity only;
   - `LetterReveal` and `TypedHeadline` show their full text with no caret and no glint;
   - the ambient field's anchors do not move over 15 s of fake time;
   - the light angle stays at 135° after fake accelerometer events;
   - programmatic scrolls jump.
2. **Walk the tables.** Walk every row of the §4.11 Reduce Motion table and the last column of all 116 rows of §4.10, by widget test where a test can see it and by the device checklist otherwise, and tick each in `qa.md`. For example:
   - Push and Pop are a 200 ms cross-fade, with the back swipe still tracking 1:1.
   - Sheet present is a fade plus a 16 px translate over 150 ms, with no recession.
   - The tab droplet cross-fades over 150 ms.
   - Minimise is an instant swap.
   - Rubber band is a hard stop.
   - Stack fan becomes a flat list with a 200 ms fade.
   - Address drain becomes a 200 ms cross-fade to Login.
   - Skin melt becomes a 200 ms fade to black.
   - Droplet reveal becomes a 200 ms cross-fade with `logo.reduced`.
   - Cruise ramp is none.
   - Panel camera is a cut with a 120 ms cross-fade.
   - Rain on glass is off.
   - Hold fill runs in 4 visible steps.
   - Error shake is none, with the error text kept.
   - Celebrations become their end states with a 150 ms fade.

   **Stack fan** and **Address drain** are Flutter-only (the web marks them n/a) and must be ticked here.
3. **Planned settle times.** `GlassMotion.play` logs each move's name and planned duration (§15.8 motion-timings overlay). A table-driven test reads the Duration column of §4.10 from `../docs/redesign/glass/DESIGN.md` (resolved from the `mobile/` working directory). It takes the leading number of cells of the form "settle N ms" or "N ms", skips "continuous" and "while stretched" cells, plays each such move in a test host, and asserts that the logged planned duration equals the table's value within one frame (8.3 ms). Examples: **Sheet present** 447 ms, **Push** 615 ms, **Panel camera** 392 ms, **Zoom** 558 ms, **Materialise** 250 ms.
4. **Motion names** (§15.8). `node design/build.mjs --check` passes. The new `mobile/test/skins/glass/motion_names_test.dart` extracts the 116 bold names of the §4.10 table from the same file, normalises both sides (lowercase, letters only), and asserts that `MotionName.values` has exactly those names. The enum makes an unknown name a compile error. If `GlassMotion` also accepts a string label anywhere, assert that an unknown label throws an `AssertionError` in debug.
5. **The real-frame pass** is a device item (N). On the owner's phones, with Settings → Diagnostics → "Show motion timings" on, every move of §4.10 is triggered at least once, screen by screen from the list in the device checklist. Pass: no row turns `danger` (dropped frames, or an overrun of more than one frame past the planned settle).

### H. Signature animations actually play (§10.1, §10.2, §15.8 Flutter bullet)

Extend `mobile/26`'s `typed_headline_test.dart` and `letter_reveal_test.dart`:

1. **Typing reveal on Home.**
   - Pump Home and request focus on the greeting's header `Focus` node right away, as route focus does (§8.0.8).
   - 200 ms later the 10th grapheme's span is transparent (`Color(0x00000000)`): focus did not skip the typing. The string is laid out in full from frame 0.
   - The caret is present: 2 px wide, 0.72 em tall, `iris400`.
   - After `n × 50 + 40 + 200` ms (`n` graphemes, spaces included) every grapheme is opaque.
   - After `n × 50 + 3 × 1060 + 350 + 200` ms the caret is gone.
   - The heading's `Semantics(label:)` carries the full string from the first frame, and the typed spans sit under `ExcludeSemantics`.
2. **Skip rules.** A tap down on the headline completes it at once, and so does a key event while the headline has focus. Focus arriving does not. Navigating away completes it silently. After a skip, the count never advances again.
3. **Once per session per profile per placement.** `revealedHeadingsProvider` holds `"{profileId}:{placement}"` from the moment typing starts. A second visit in the same `ProviderScope` shows the greeting at rest. A fresh `ProviderScope` (a new app session, or an `AppRestart`) types again.
4. **The other placements** type once each: Login "Welcome back"; onboarding step 1 "Hi, {name}." (assert the 5th grapheme when the string is shorter than 10); the Wrapped cover "Your {year} in chapters"; the recap deck heading "Previously on {title}". A headline longer than 48 graphemes types the first 48 and fades the tail in as one span over 200 ms.
5. **Letter reveal.**
   - A Home rail header (H3, `title2`) below the fold keeps its letters in the waiting state until `revealWhenVisible` sees it 25 % in view.
   - After scrolling it in, within `24 × (g − 1) + 345 + 100` ms (`g` graphemes; spaces take no time) every letter is at opacity 1, translate 0, blur 0 and scale 1.
   - 120 ms after the last letter settles, the glint (`ShaderMask`, 40 % of the width, white at 18 %) crosses once over 500 ms.
   - The placement is recorded, and a second visit shows it at rest.
   - Three headers scrolled in at once animate at most two at a time.
   - A heading over 60 graphemes reveals per word at 40 ms per word.
   - The §10.1 check still passes: a 40-grapheme title at 200 px width never splits a word across lines, and changing to a longer title throws no `RangeError`.
6. **Reduced motion:** both show their full text immediately, with no caret and no glint.

### I. Accessibility pass (§14.2 to §14.10, §15.8 "Accessibility pass per cluster")

1. **Audit.** `glass_qa_test.dart` runs `audit()` on every route of B1 at 390 × 844 under `TargetPlatform.iOS` and under `TargetPlatform.android`, and at 820 × 1180 under iOS. It writes `docs/redesign/proof/mobile-45/audit/<screenId>-<frame>-<platform>.json` only when `MM_WRITE_SHOTS=1`; otherwise it just asserts zero violations.
2. **Contrast and colour (§14.2, §14.3):** C3, plus the following.
   - Every overlay on a cover sits on an opaque black backing.
   - Read, inactive, offline and "not for me" states dim by role, never by opacity. Only disabled controls dim to 40 %.
   - Status pills carry their word, download states a glyph and a semantics label, unread items a dot and a bar, and the 18+ badge "18+". Speaker tints use an underline style, and reactions are named.
   - The machine light always comes with the sparkle glyph and "suggested by AI" in the semantics label. The people light always comes with an orb or a name.
   - Charts carry a summary sentence and "Show as table".
3. **Keyboard and focus on tablets** (§14.4, `glass_focus_test.dart`, the 820 × 1180 and 1180 × 820 frames with a simulated hardware keyboard).
   - Tab 60 times on each screen, recording the focused rect.
   - Every focused element shows the two-tone ring painted by `FocusRingSpec` as a `foregroundPainter` outside `ClipRSuperellipse`: no ancestor clip of the focused widget cuts the ring rect inflated by 4 px (6 px glow; 3 px ring under Increase Contrast).
   - After Glass's `FocusTraversalPolicy` scrolls, no focused rect intersects the floating chrome bands: top safe + 60; bottom safe + 85, or + 56 more with the accessory; the tablet sidebar.
   - Rails and grids take one tab stop each (arrow keys inside). A route change puts focus on the header, and a pop returns it to the pusher. Sheets, menus and alerts trap focus and return it on close.
   - Settings → Shortcuts "Single-key shortcuts" off: every printable-character binding stops (letters with or without Shift, digits, punctuation). Arrows, Home, End, Page Up/Down, Space, Enter, Esc, Tab, Delete, Backspace, F-keys and every `mod+` or `alt+` combination keep working. No shortcut fires while typing in a field except the `allowInInput` ones (`mod+k`, `mod+b` and Esc, wherever the Flutter key map binds them; §8.0.6, §14.4).
4. **Touch targets (§14.6):** audit rule G4 on every screen on both platforms.
5. **Text size (§14.7, §3.3)**, in `glass_textscale_test.dart`, on every screen at 1.0, 1.3 and 2.0:
   - no overflow error;
   - reader chrome text clamps at 1.3, and at `f > 1.3` the cruise and download controls leave the reader capsules and become the first rows of the reader settings sheet ("Download", "Cruise");
   - capsule controls (chips, segmented, title and status capsules, tags, badges, `tabLabel`) clamp at 1.5;
   - at `f ≥ 1.6` dock labels hide (semantics keep the names, and each tab's long-press menu gains the non-interactive header row with the tab name) and list rows stack;
   - at `f ≥ 1.9` grids drop to 2 columns and rails show 1.6 posters;
   - at `f ≥ 1.3` Wrapped cards become the reflowing column, with `wrappedNumeral` unscaled;
   - `footnote` never renders below 11 px;
   - `boldText: true` adds `wght + 100`, and `GRAD + 20` on glass;
   - Legible text swaps every UI role to Atkinson Hyperlegible Next (§3.6) with nothing clipped.
6. **Every gesture has an alternative (§14.8, §11).** For every row of §11 whose iOS or Android column is not "n/a", perform the alternative in its last column (the button, menu item, semantics action or hardware key) in a widget test and confirm it does the same thing. Examples: the stack overview's "All levels" action; the sleep menu for shake-to-extend; tap bands for volume keys; the ⋯ menu for long-press. List each row with pass or the fix commit.
7. **Haptics and sound (§14.9, §5, §6).** A fake `SkinHaptics` records every call.
   - A scripted tour per cluster asserts the §5.2 pattern for each event fired: for example `detent.magnet` → `rigid(0.4)`, `autoscroll.start` → `ahap:cruise`, and `nav.push` at depths 1 to 4 → intensities 0.38, 0.46, 0.54 and 0.62.
   - Rate limits hold: ticks at least 40 ms apart, impacts at least 120 ms apart, and a burst keeps the strongest. Nothing fires on plain navigation taps inside a screen, on scrolling, on focus or on a toast appearing.
   - The Haptics switch off stops everything. On Android, `haptics.systemEnabled` returning 0 skips the vibrator-path patterns.
   - "Feel it" plays `selection`, `soft(0.5)`, `rigid(0.6)`, `ahap:droplet` and `success` 400 ms apart, and is disabled with "Turn haptics on to feel them." when the switch is off.
   - UI sounds are off for a new device, silent while narration or a soundscape plays, and never play for the typing or letter reveals.
   - Voice previews never auto-play with a screen reader on, and every clip longer than 3 s has a visible stop control.
8. **Flashing (§14.10).** Record in `qa.md`: the caret blink (530 ms phases, 0.94 Hz); the source-health bead's single 120 ms dip; the streak flame's 5 Hz tip noise at 2 % of the flame height; the skeleton sheen (1,400 ms). Nothing flashes more than three times in one second. Tilt stays within ±6° (cards) and ±25° (light), and stops under reduced motion or with "Light follows the device" off. The `sensors_plus` stream is subscribed only while a screen that uses tilt is visible, at `samplingPeriod` 33 ms.

### J. Content safety and the gate-close checklist (§14.11, §8.0.8)

`glass_gate_test.dart` builds the Glass app over fake repositories and stores seeded from `mobile/test/fixtures/glass_qa/gate/`. The seed is a gate-open profile with:
- one followed mature series, with one downloaded chapter whose blob files sit in a temp directory (record their sha256);
- a bookmark, two history rows, and a recent search `{q, gateOpen: true}` of its title;
- the series open in the Library tab's stack, with a stack-overview snapshot flagged mature, and the Home tab active;
- cruise and the Rain soundscape running in its reader (fake engine, `FakeSoundscapeAudio`);
- narration playing (a fake player);
- an in-flight recap for it with a pending "Recap ready" toast.

1. **Close the gate** through Settings → Content and check every item of §14.11, each ticked in `qa.md`:
   1. Narration, cruise and the soundscape stop, and the accessory leaves.
   2. The "Recap ready" toast never appears.
   3. Every tab whose top route was mature is at its root.
   4. The stack overview shows no mature level (the snapshot was disposed).
   5. Recent searches typed with the gate open are gone.
   6. No mature cover appears anywhere. `PaintingBinding.instance.imageCache.clear()` and `clearLiveImages()` were called (spy), and the ambient field no longer uses the mature palette.
   7. Home, Statistics, Wrapped, the recap and the Circle, opened offline (the connectivity fake), show their offline states, not old copies. Their cached payloads were deleted.
   8. Downloads, its counts and the storage meter show none of it and say nothing about it.
   9. Reopening the gate brings the download back untouched: the same sha256 for every blob.
   10. An offline Library, Sources directory, Collections, History, Bookmarks and the recap skip list show none of it. For the palette half of item 10: if the Flutter build has a command palette (`grep -rln "CommandPalette\|command_palette" mobile/lib/skins/glass`), check its recent items like the recent searches. Otherwise mark it "n/a on Flutter (§7.28: desktop web; phones get Search)".
2. **Separately, switch to a gate-closed profile** and repeat checks 3 to 10.
3. **A deep link to mature content** on a gated profile (the reader route, the series route, a bookmark row, a notification tap) opens the object lens "This isn't available on this profile" with "Back home", and no title or cover.
4. **Share cards.** For a gate-open profile whose year is mostly mature (three chapters of the mature series and one of a non-mature one), render every share side through `wrapped/share_card.dart`: the Statistics stat cards and every Wrapped card that has one (card 11 has none). Collect every string (the text of every `RichText`) and every image provider URL in each card's tree. Assert that no mature series title, mature source name, mature genre word or mature cover URL appears, and that nothing from the Circle is drawn.
5. **The 18+ gate itself (§7.25).** Turning it on needs the 1,200 ms hold (the fill starts at 200 ms, with the `hold.ramp` swell) or the explicit confirm button, which is visible for everyone. A double tap never confirms. A release before 200 ms within 8 px is a click that opens the confirm alert.

### K. Performance budget (§15.7, §2.4.1)

`glass_budget_test.dart` reads `SkinGlass`'s registry of mounted `LiquidGlassLayer`s and shapes in each moment below. On the frost fallback, it counts `BackdropGroup` members as shapes and groups as layers. Pass: never above the number, and never more than two stacked glass layers over one point.

| Moment (§15.7 Flutter column) | Frame | Layers / shapes at most |
|---|---|---|
| Library tab root with the Filters sheet open and an Undo toast; then a row menu instead of the toast | 390 × 844 | 4 / 8 |
| Search open (the orb expanded) with a toast | 390 × 844 | 3 / 3 |
| Manga reader scrubbing (the rail held) with the magnifier, the seam chip, the hit lens (opened from a dialogue search result) and the reader settings sheet | 390 × 844 | 4 / 7 |
| The same with guided view and Rain on (the rain shader counts as one extra layer, §9.4.2) | 390 × 844 | 6 / 8 |
| Novel reader with the listen row, a speaker chip and the Aa sheet | 390 × 844 | 4 / 6 |
| Desktop frame Library with the sidebar, the toolbar group, a toast, the bulk-selection toolbar, a window (series detail) and a menu | 1180 × 820 | 6 / 6 |
| Profile picker; onboarding; Wrapped | 390 × 844 | 2 / 2 each |

Also test and record the following:
- A third stacked glass layer forces the lowest one to `solid1` while the stack lasts.
- The Diagnostics row "Glass layers on screen" shows the live count and turns `warning` above 6 layers or 8 shapes.
- `GlassQuality.premium` is on chrome, and `standard` appears only on at most two page-level controls per scrolling screen and on transient glass (a dragged thumb or knob). Count the `SkinGlass` instances by quality per screen.
- The ambient field is one `CustomPaint` with three `RadialGradient`s and no `ImageFilter.blur`.
- Per-letter reveals stay within 60 graphemes and two at once.
- Each skeleton's sheen is one gradient.
- The genre field stays within 24 bodies and the Wrapped page pile within 200 bodies, and both stop their `Ticker` at rest.
- Rain runs only while the Rain scene plays and reader glass is visible.
- Page samples reach the isolate at most every 600 ms: at most 17 `compute` calls in a 10 s fake scroll. Panel detection shares that isolate.
- Stack-overview snapshots are captured at `pixelRatio: 0.5` and released on `tester.binding.handleMemoryPressure()`.
- Sensors run only while visible, at 30 Hz.
- No file under `lib/skins/glass/` decodes or prefetches reader pages itself. `grep -rn "precacheImage\|instantiateImageCodec\|decodeImageFromList\|ResizeImage" mobile/lib/skins/glass` may show only uses the contract assigns to the skin (for example the share card's own render); justify each hit in `qa.md` or move it into the data layer.

### L. The "Float" parity captures (§12.5)

The five 1320 × 2868 Float frames are web captures by definition (§12.5: a 440 × 956 viewport at DPR 3 through Playwright), and `web/45` produces them. On Flutter, capture the same five UIs in the harness group `mobile-45 float` at 440 × 956 DPR 3, into `docs/redesign/proof/mobile-45/float-compare/`:
- Home, fed by the demo covers;
- the manhwa reader mid-chapter with the chrome shown, over the demo pages;
- novel plus listen: the listen full player over an invented two-paragraph chapter with an invented cast;
- the Wrapped cover card;
- the Circle, with the second demo profile's activity.

There is no 18+ content, and titles are invented from §12.7. When `docs/redesign/proof/web-45/float/*.png` exist, compose each web frame beside its Flutter capture into `float-compare/pair-{1..5}.png`, and list the differences in `qa.md`.

### M. Cross-skin switch in both directions through the debug row (§8.25.2, §8.2, stack §2.5)

`glass_switch_test.dart`, with the fake repositories and a fake `SharedPreferences`:

1. **Cinematic → Glass.** Start in Cinematic on `/library/collections` (a non-root route) with a download queued, then use Settings → Diagnostics → the debug row (`Edition (debug)` CINEMATIC | GLASS, which glass §8.25.12 calls "Preview Glass skin") and choose GLASS. Pass:
   - `mm.skin.active` is `glass`, and `mm.skin.return` was written and then cleared after being read;
   - `PATCH /profiles/{id} {skin: "glass"}` went through the offline outbox (the fake API);
   - `AppRestart` swapped its key, and afterwards no Cinematic widget is in the tree (`find.byWidgetPredicate((w) => w.runtimeType.toString().startsWith('Cine'))` finds nothing);
   - Glass's `prepare()` awaited `LiquidGlassWidgets.initialize()` (a spy) before the Glass splash's first frame;
   - the Droplet reveal plays once (cold 1,200 ms) and lands on `/library/collections`;
   - the queued download was re-queued at startup;
   - the toast "Switched to Glass" shows its Undo with the 10 s draining rim.
2. **Glass → Cinematic.** From Glass's debug row choose CINEMATIC. Pass:
   - **Skin melt** is in the motion log with its planned 615 ms (under reduced motion, a 200 ms fade to black), and the `skin.switch` haptic (`heavy`) fired;
   - the return route is restored;
   - no Glass widget remains;
   - the soundscape voices, cruise and narration were stopped by disposal (the fakes record it);
   - Cinematic's splash plays.
3. **Budget.** In the fake-clock run, nothing between the confirm and the restart waits longer than the melt plus one frame. The real "under 1,500 ms to the new splash" figure is a device item (N), read from the `mm.skin.t0` timestamp in Diagnostics.
4. **Profile hand-off.** A profile switch into a profile whose skin differs runs the restart inside the hand-off, with no alert and no Undo. A boot-time mismatch (the remembered profile's skin differs from the mirror) plays the Droplet to the lens and restarts with no confirm (§8.2).
5. **Nothing leaks across, and the flag holds.** `Flags.glassAvailable` is still `false`. So the Appearance skin cards, onboarding step 2's Glass option and the profile form's skin row still hide Glass (§8.0.8), and "App icon follows the skin" is not offered: a spy on the `flutter_dynamic_icon_plus` wrapper records zero calls. The icon behaviour of §12.2 is verified in `release/01`.

### N. The owner's device pass at 120 Hz

Write `docs/redesign/proof/mobile-45/device-checklist.md` for the owner. It covers the iPhone (the CI IPA from `ios-build.yml` for this step's final SHA, installed through SideStore) and the Android flagship (the release APK from the `tests.yml` build job for the same SHA). Glass is reached through Settings → Diagnostics → the debug row.

Each row gives exact steps, a pass condition and an empty result column. The measurement for every 120 Hz row: turn on Settings → Diagnostics → "Show motion timings", and read Diagnostics → Rendering performance after the gesture. Pass: mean FPS ≥ 114 (within 5 % of 120), Jank % in the `success` colour (< 5 %), at most 2 dropped frames per second, and no motion row turning `danger`.

1. **The dock:** drag across the four tabs (the droplet follows and ticks), minimise and restore by scrolling, merge with the search orb, long-press a tab.
2. **Sheets:** present series detail, drag between `medium` and `large`, catch it mid-flight, fling it closed at 1,500 px/s or more, and on Android use a predictive back gesture on it.
3. **Poster zoom:** open series detail from a poster (`heroine`), then catch and drag the zoom back before 80 %.
4. **Stack overview:** push four levels in the Library tab, long-press Back for 450 ms (the fan), pick a level, and swipe a card away.
5. **The reader with the hit lens:** open a dialogue search result. The T1 lens hops from bubble to bubble across a page boundary with `n` and the capsule.
6. **Cruise:** tap (the ramp), drag the pill (the magnet click at 1.0×), gently flick to cruise, touch to pause, run the whole 120-page, 2,880 px demo webtoon.
7. **Rain:** start the Rain scene over a white demo page. Droplets refract the page on the capsules and the minimised pill, and Diagnostics' "Glass layers on screen" goes up by one.
8. **Wrapped:** cards advance, the page pile falls, and the flip to share works.
9. **VoiceOver** (iPhone) and **TalkBack** (Android). Each of these custom actions is reachable from the rotor or the actions menu: a swipe row's actions, the reaction strip, the back button's "All levels", a toast's "Dismiss", locked mode's "Unlock controls", the cruise pill's adjust, and the guided-view next and previous panel.
10. **Text size** on both phones: iOS Larger Text at the default, at xxL (factor 1.24) and at AX2 (1.94); Android font scale 1.0, 1.3 and 2.0. Nothing clips on Home, the Library, series detail, the manga reader, the novel reader, Settings and Wrapped.
11. **iOS Reduce Transparency** swaps glass to solid live, and back. **Increase Contrast** (iOS; Android 14 contrast ≥ 0.5) adds the 1 px `hcBorder` and raises the dims. **Reduce Motion** (iOS) and **Remove animations** (Android) match §4.11.
12. **Calibration:** screenshot Settings → Diagnostics → Glass calibration on both phones, and drop the files as `docs/redesign/proof/mobile-45/calibration-flutter-premium-{ios,android}.png`.
13. **Skin switch timing:** switch both ways through the debug row. The `SKIN RESTART` figure in Diagnostics is under 1,500 ms, and the return route is restored.
14. **Motion-timings walk:** for each cluster, trigger every move of §4.10 listed for that cluster's screens (write the move list per screen into the checklist from the "Where used" column). Rows that turn `danger` are reported with the screen and the move.

You cannot run these rows yourself. `qa.md` marks each one "awaiting owner", and the report names them.

### O. CI: the release APK build and the iOS dry run

After the final push, both workflows must be green for the final `git rev-parse HEAD`: `.github/workflows/tests.yml` (the Flutter job: `flutter analyze`, `flutter test` and the `flutter build apk --release` job `mobile/02` added) and `.github/workflows/ios-build.yml` (the unsigned iOS build, the dry run). Read runs with `gh run list --branch feat/vps-slim-source-native --limit 10` when `gh` exists. Otherwise make at most one anonymous request every 5 minutes, never in a tight loop (the limit is 60 per hour): `curl -s "https://api.github.com/repos/yash-dhanda/ManhwaManiacs/actions/runs?branch=feat/vps-slim-source-native&per_page=10" | jq '.workflow_runs[] | {name, head_sha, status, conclusion, html_url}'`.

For a red job, read the failing step through `…/actions/runs/<run_id>/jobs` and its message through the anonymous `…/check-runs/<job_id>/annotations`. Failures such as `ENOTFOUND` or `Request timeout` on the runner's cache or artifact steps are GitHub's, not the code's: push again. Anything else is a defect: fix it, push, and check again. Record the run ids and conclusions in `qa.md`.

### P. Fix everything, then `qa.md`

Every failure found in A to O is fixed in the Glass skin, or in the shared data layer when that is where the fault is. Each fix is its own commit, and the check is re-run after the fix. Then write `docs/redesign/proof/mobile-45/qa.md` with:

- a table with one row per check: section and item, command or method, result, and the commit SHA of the fix when there was one;
- the audit summary per screen and platform (0 violations is the target; list any accepted exception with its reason and the contract section that allows it);
- the contrast-gate table and the three worst cases in widgets;
- the calibration counts (Flutter harness, Flutter devices, web) or the blocked note;
- the motion summary: rows checked out of 116, the two Flutter-only rows, the planned-settle test result, and the device walk marked "awaiting owner";
- the budget table with the measured counts;
- the gate-close checklist ticks for both scenarios, and the share-card result;
- the screenshot inventory with `du -sh`;
- the CI run ids and conclusions;
- the device checklist status;
- open issues, each with the contract section it concerns, including parity issues with `web/45`.

## Out of scope here (do not build)

- `release/01`: flipping `flags.glass_available`, turning on the surfaces it gates (the Appearance skin cards, onboarding's Glass option, the profile form's skin row, alternate-icon registration), deleting the debug row and the `mm.skin.debug` key, the version bump and the ship.
- Any new feature or package. Any change in `frontend/`, `backend/` or `design/`: report token, contrast or calibration gaps for the shared track. Any change to the Cinematic skin except a shared-layer fix that a Glass check exposed; then rerun `mobile/24`'s tests for the touched screens.
- The web QA (`web/45`). Gradle or Xcode on this box.

## File layout

```
mobile/lib/skins/glass/<router or skin file holding PENDING>        PENDING map removed (A1)
mobile/lib/skins/<skin-neutral pending screen>                      deleted when no skin uses it (A1)
mobile/test/skins/completeness_test.dart                            strict for glass (A2)
mobile/test/skins/glass/glass_physics_test.dart                     missing §15.8 values only (C1)
mobile/test/skins/glass/motion_names_test.dart                      G4
mobile/test/skins/glass/primitives/typed_headline_test.dart         H (extended)
mobile/test/skins/glass/primitives/letter_reveal_test.dart          H (extended)
mobile/test/skins/glass/qa/glass_audit.dart                         B2
mobile/test/skins/glass/qa/glass_qa_test.dart                       C3, F, I1, I2, I4, I6, I7, I8
mobile/test/skins/glass/qa/glass_focus_test.dart                    I3
mobile/test/skins/glass/qa/glass_textscale_test.dart                I5
mobile/test/skins/glass/qa/glass_motion_test.dart                   G1–G3
mobile/test/skins/glass/qa/glass_gate_test.dart                     J
mobile/test/skins/glass/qa/glass_budget_test.dart                   K
mobile/test/skins/glass/qa/glass_switch_test.dart                   M
mobile/test/fixtures/glass_qa/                                      fake payloads (invented titles, demo art only), gate seed
mobile/test/screenshots/marketing_screenshots_test.dart             mobile-45 groups (C3, D, E, L)
mobile/test/screenshots/support/<compose helper>.dart               E6
mobile/lib/skins/glass/**                                           fixes (P)
docs/redesign/proof/mobile-45/                                      plan.md, qa.md, device-checklist.md, calibration-flutter-harness.png,
                                                                    audit/, screens/, screens-a11y/, textscale/, states/, pairs/,
                                                                    worst-cases/, calibration/, float-compare/
```

Skin files import only `features/*/{models,providers,repositories,services,store,queue,utils,controllers,engine}`, `core/`, `shared/` and their own `skins/glass/**`. `test/skins/import_boundary_test.dart` fails on anything else.

## Acceptance criteria

- [ ] The Glass `PENDING` map is gone. The completeness test asserts a real screen for every `ScreenId` in both skins. The import-boundary proof line is in `qa.md`.
- [ ] `glass_physics_test.dart` asserts every §15.8 value (`tierFor(401) == T4`). `node design/build.mjs --check` passes with every §15.8 contrast case listed. The three worst cases hold in widgets: dim 0.64 and `GRAD` 40 over white, 0.72 under Increase Contrast, and the 0.72 plateau under the dock.
- [ ] The Flutter calibration capture exists as `calibration-flutter-harness.png`, with either both square counts within one square of the web's or the item recorded as blocked, and the device captures requested in the checklist.
- [ ] Harness screenshots exist for every `ScreenId`:
  - at 390 × 844 @3, 440 × 956 @3, 820 × 1180 and 1180 × 820, with sheet routes in both presentations;
  - Reduce Motion, Solid glass, Increase Contrast, Bold Text and Legible text per screen, with the in-app switch captures identical to the OS-path ones;
  - text scale 1.0, 1.3 and 2.0 per screen;
  - the states;
  - a Cinematic/Glass pair per screen.

  The folder is under 200 MB.
- [ ] The audit reports 0 violations on every screen on iOS and Android at the phone frame and on iOS at the tablet frame, or each remaining violation is listed in `qa.md` with the contract section that allows it.
- [ ] Hardware keyboards on tablets:
  - every focused element shows the unclipped two-tone ring (3 px under Increase Contrast) and is never under a floating bar;
  - rails and grids are one tab stop;
  - route changes focus the header, pops return focus, and overlays trap and return it;
  - the Single-key shortcuts switch behaves as §14.4.
- [ ] Every hit target is at least 44 × 44 pt on iOS and 48 × 48 dp on Android, with 8 px spacing or shared glass-group cells.
- [ ] Text scale 1.0, 1.3 and 2.0 and Bold Text follow §3.3 rules 1 to 5 on every screen with no overflow. `footnote` never renders below 11 px.
- [ ] Reduced motion (the OS flag, and the in-app switch alone) matches the §4.11 table and every last column of §4.10, **Stack fan** and **Address drain** included. Only progress pulses and a user-started cruise keep running, reveals show their full text, and the field, the light and tilt are frozen. The planned-settle test matches §4.10. The motion-names test matches all 116 names.
- [ ] The signature tests pass:
  - the Home greeting is still typing 200 ms after navigation despite route focus;
  - typing skips on a tap or key but not on focus, and types once per session per profile per placement;
  - the other four placements type;
  - a rail header waits for 25 % visibility and settles within `24 × (g − 1) + 445` ms with one glint;
  - at most two reveals run at once;
  - reduced motion shows both at once.
- [ ] The screen-reader behaviours and semantics of F hold, including every custom action: swipe rows, reorderable rows, the reaction strip, "All levels", "Dismiss", "Unlock controls", the cruise pill and guided view.
- [ ] Haptics follow §5.2 with the rate limits, the Haptics switch and Android's system setting. UI sounds are off by default and silent during narration and a soundscape.
- [ ] The gate-close checklist passes all ten items (the palette half of item 10 only where a Flutter palette exists) for a gate closing and for a switch to a gate-closed profile. The deep-link lens shows no title or cover. Share sides draw no mature title, source, genre or cover and nothing from the Circle. The gate needs the hold or the explicit button.
- [ ] The budget holds in every moment of the K table: at most 4/8, 3/3, 4/7, 6/8, 4/6, 6/6 and 2/2 layers and shapes, never more than two stacked layers, the third forced to `solid1`. Every other §15.7 rule has evidence in `qa.md`.
- [ ] The Float parity captures exist at 440 × 956 @3 from demo art and invented titles only, paired with the web frames when those exist.
- [ ] Cross-skin switches in both directions through the debug row restore the return route, play the arriving skin's splash once, re-queue the queued download, leave nothing of the other skin in the tree, and stop cruise, the soundscape and narration. `Flags.glassAvailable` is still `false`, and no icon change is attempted.
- [ ] `device-checklist.md` lists rows 1 to 14 with steps and pass conditions, and `qa.md` marks them "awaiting owner".
- [ ] Cinematic is unchanged except for listed shared-layer fixes; `mobile/24`'s tests still pass for every screen a fix touched.
- [ ] `flutter analyze` reports "No issues found". `flutter test` passes at or above the floor plus the new tests. `node design/build.mjs --check` passes. The CI Flutter job (analyze, test, release APK) and the iOS dry run are green for the final SHA, with the run ids in `qa.md`.
- [ ] `docs/redesign/proof/mobile-45/qa.md` exists with every part listed in P.

## Verification

**RAM guard (production shares this box, and `web/45` runs in parallel).** Before every heavy command (`flutter analyze`, `flutter test`, each harness run, `npm run build`), run `free -m` and read the `available` column of the `Mem:` row. If it is under 1024 MB, stop and report instead of running it. Run one heavy command at a time. If `pgrep -fa "next build|flutter_tester|playwright"` shows another heavy command running, wait until it exits (check again every minute) before starting yours. Never run Gradle or Xcode on this box.

From `mobile/`:

```bash
free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze
free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter test test/skins
free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter test
cd .. && node design/build.mjs --check && cd mobile
```

Harness runs, one at a time:

```bash
free -m && MM_WRITE_SHOTS=1 /srv/manhwamaniacs/dev/flutter/bin/flutter test test/screenshots/marketing_screenshots_test.dart --plain-name "mobile-45 screens"
free -m && MM_WRITE_SHOTS=1 /srv/manhwamaniacs/dev/flutter/bin/flutter test test/screenshots/marketing_screenshots_test.dart --plain-name "mobile-45 a11y"
free -m && MM_WRITE_SHOTS=1 /srv/manhwamaniacs/dev/flutter/bin/flutter test test/screenshots/marketing_screenshots_test.dart --plain-name "mobile-45 textscale"
free -m && MM_WRITE_SHOTS=1 /srv/manhwamaniacs/dev/flutter/bin/flutter test test/screenshots/marketing_screenshots_test.dart --plain-name "mobile-45 states"
free -m && MM_WRITE_SHOTS=1 /srv/manhwamaniacs/dev/flutter/bin/flutter test test/screenshots/marketing_screenshots_test.dart --plain-name "mobile-45 pairs"
free -m && MM_WRITE_SHOTS=1 /srv/manhwamaniacs/dev/flutter/bin/flutter test test/screenshots/marketing_screenshots_test.dart --plain-name "mobile-45 calibration"
free -m && MM_WRITE_SHOTS=1 /srv/manhwamaniacs/dev/flutter/bin/flutter test test/screenshots/marketing_screenshots_test.dart --plain-name "mobile-45 float"
free -m && MM_WRITE_SHOTS=1 /srv/manhwamaniacs/dev/flutter/bin/flutter test test/skins/glass/qa/glass_qa_test.dart
```

`flutter analyze` must report "No issues found", and the full suite must pass at or above the floor plus the new tests. `00-baseline.md` records 2012 passing tests. Every test that passed in the baseline must still pass, except legacy widget tests that `release/00` deleted by design (name them if the count dropped for that reason). This step changes nothing in `frontend/` or `backend/` (`git diff --stat origin/feat/vps-slim-source-native -- frontend backend` over your commits is empty). So `npm run lint` and `npm run build` (in `frontend/`) and the backend pytest (`backend/.venv/bin/python -m pytest -q --no-header` from `backend/`) are not rerun, except under the push rule in Git.

**Visual proof.** Everything in C3, D, E and L lands under `docs/redesign/proof/mobile-45/` at the exact sizes above. Review every image with `impeccable` and `taste-skill` before you write `qa.md`.

## Git

- Branch `feat/vps-slim-source-native`. Commit small and often:
  1. the strict completeness change;
  2. the audit helper and the harness extensions;
  3. the motion-names and planned-settle tests;
  4. the gate, budget, switch, focus and text-scale tests;
  5. one commit per fix (`fix(mobile-glass): label3 over the Home field in the rail meta`);
  6. the proof and `qa.md`.
- Stage your paths explicitly (`git add mobile/test/skins/glass/qa …`, `git add docs/redesign/proof/mobile-45`), never `git add -A` or `git add .`, because the web, backend and shared sessions commit in the same checkout.
- No Claude or AI attribution anywhere: no `Co-Authored-By` line, no "Generated with" line, no AI author. Never commit secrets (fixtures carry no real tokens or passwords) or `.claude/`.
- Before every push: `git fetch origin` and `git diff --stat origin/feat/vps-slim-source-native...HEAD -- frontend`. If it lists files, run `free -m && npm run build` in `frontend/` first (never while `flutter test` runs) and push only if it passes. Then run `git push origin feat/vps-slim-source-native` after each working step, and check CI as in O after the last one.
- Never edit `backend/connectors/`. Never touch production containers or `/srv/manhwamaniacs/{app,data}`. Do not deploy: Glass ships in `release/01`.

## Report back

Reply with:

1. Done items by section (A to P), and anything not done with the reason.
2. Any `ScreenId` that was still pending at the start, and which step's scope you executed for it.
3. Paths: `docs/redesign/proof/mobile-45/qa.md`, `device-checklist.md`, the screenshot folders with `du -sh`, `calibration-flutter-harness.png` and the side-by-side (or the blocked note), and the Float comparison pairs.
4. Test counts: `flutter test` passed before and after, the new test files with their case counts, the `flutter analyze` result, `build.mjs --check`, and the `free -m` available figure before each heavy command.
5. Audit totals (violations found, fixed, and accepted with reason) and the number of fix commits.
6. The motion summary (116 rows walked, the two Flutter-only rows, the planned-settle result) and the device rows awaiting the owner.
7. The budget counts per moment, and the gate-close checklist result for both scenarios.
8. The CI run ids and conclusions for the final SHA (Flutter job, release APK, iOS dry run).
9. Open issues, each with its `glass/DESIGN.md` section, including gaps for the shared track (tokens, contrast cases, calibration knobs) and parity issues with `web/45`.

Next prompt file: `docs/redesign/prompts/release/01-glass-final-release.md` (it also waits for `docs/redesign/prompts/web/45-glass-qa-polish.md`).
