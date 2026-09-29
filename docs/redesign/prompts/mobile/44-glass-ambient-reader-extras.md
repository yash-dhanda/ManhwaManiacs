# Mobile Glass ambient reader extras (new feature 4)

Track: mobile · Order 107 · Depends on: `docs/redesign/prompts/mobile/43-glass-circle.md` · Web twin: `docs/redesign/prompts/web/44-glass-ambient-reader-extras.md` (runs in parallel) · Proof folder: `docs/redesign/proof/mobile-44/`

## Goal

Build new feature 4 of `00-decisions.md` ("Ambient reader extras") in the Glass skin of the Flutter app (iOS and Android), in the manga reader, the novel reader and the listen player. You deliver four things. **Cruise**: auto-scroll as a flywheel pill, with vertical drag at 8 px per 0.05×, a magnet at 1.0×, engaging from a decaying fling through the engine's `engageFromVelocity`, the 400 ms ramp, and `cruiseSpeed` saved per series. **The soundscape**: six scenes of three live layers each. `mobile/lib/skins/glass/soundscape/generator.dart` renders the procedural 30 s loops to WAV bytes in an isolate for `SoLoud.loadMem`. `mobile/lib/skins/glass/soundscape/mixer.dart` runs three layers per scene, the 2 s recorded-layer cross-fade, ducking under narration and music detection through `audio_session` on iOS and `mm/platform` `audio.isMusicActive` on Android. The recorded `.ogg` layers come from `/app/soundscapes/glass-{scene}-{layer}.ogg`. There is also the Bed · Detail · Tone mixer and `mm.soundscape.defaults`. `mobile/lib/skins/glass/shaders/rain_on_glass.frag` runs only while the Rain scene plays with reader chrome visible. **Guided view**: the panel camera on the `camera` spring, the T2 lens with its refracted sliver, the panel counter and the pinch-out overview. **Page-tinted chrome**: make it exact against glass §9.4.4 in both readers and the listen player, with the tint from the engine's `currentPageSample` and the legibility dim and label grade set per chrome group. Everything reads the shared reader engine. `mobile/23` built the page-tint and panel isolate, `setCamera` and `pageToViewport`. `mobile/34` built `currentPageSample`, `scrollVelocity`, `panelBoxes`, `pageLayerTransform` and `engageFromVelocity`. The skin never moves the page layer itself. This step adds no `ScreenId`. Glass stays reachable only through the Diagnostics debug row. Cinematic must not change by a single pixel.

## Read first

Read these completely before planning. Where this file and `glass/DESIGN.md` disagree, `glass/DESIGN.md` wins; say so in the report.

1. `docs/redesign/inventory/00-decisions.md`, all of it. It covers new feature 4 ("auto-scroll with speed control, ambient soundscape while reading, panel-by-panel guided view for manhwa, reader chrome tinted by dynamic color from the current page"), rich haptics on iOS and Android, UI sound off by default, flagship-only maximum effects, and honouring the OS reduced-motion setting.
2. `docs/redesign/stack-decision.md` §2.3: the mobile folder layout, `test/skins/import_boundary_test.dart`, the completeness test, the rule that the reader engine is extracted first, and the rule that logic living in a widget moves first. Also §2.6 item 2 (per-page palettes and panel boxes both run on the client, per sign-offs G6 and G14), §3 "Dependency changes" (`flutter_soloud` 4.1.7) and §4 risks 5, 6, 9 and 11.
3. `docs/redesign/glass/DESIGN.md`:
   - **§9.4 in full.** This is the contract for this step:
     - §9.4.1 Cruise.
     - §9.4.2 Soundscape, including the scene table, the recorded-layer paragraph ("the iOS and Android apps always fetch" `.ogg`), Starting, Picker, Match the story, Remember for this series, Your own music, Mixing rules, Rain on glass (the Flutter shader paragraph with its uniform order), Playback engines ("Phones: `flutter_soloud` 4.1.7 …") and States.
     - §9.4.3 Guided view.
     - §9.4.4 Page-tinted chrome.
   - §2.1.2 (text on glass is `onGlass`, the backing disc, and the mapping that turns `label2` on a T4 sheet body into `onGlass`).
   - §2.1.7: the `dimLegibility` formula `clamp(0.22 + 0.42 × Lb, 0.22, 0.64)` and the `Lb` source rows for the manga reader top chrome `pTop`, the bottom capsule and minimised pill `pBottom`, "every other surface over a reader page", and the novel reader's paper.
   - §2.1.8 steps 3 and 5 (the `PageSample` shape, the greyscale rule, manifest `pages[].tint` first paint) and §2.1.9 (one light per meaning).
   - §2.4.1: the layer stack, the three glass rules (the guided-view lens and the hit lens live in the one overlay layer, never inside the strip), and the Flutter budget of 6 layers and 8 shapes. §2.4.2 rule 7 (content twins, `fill2`). §2.4.3 (T2 Pane for the guided-view lens; the Flutter `LiquidGlassSettings` mapping).
   - §2.8.5: `springCamera` `SpringToken(ms: 450, bounce: 0.1)` (k 195.0, c 25.13, settle 392 ms), `curveTintShift` 900 ms `Cubic(0.2, 0, 0, 1)`, `curveDimShift` 400 ms, `physicsRubberBandChapterC` 0.35, `physicsValueMagnetSpeed` 0.08, `thresholdChapterArm` 48, `thresholdChapterCommit` 72, `thresholdDragSlopTouch` 10, `thresholdDoubleTapWindow` 280 / `thresholdDoubleTapSlop` 24. §3.2 (`mono` 13/18, `monoLarge` 22/26, `subhead`, `footnote`, `caption1`). §3.3 rule 4: reader chrome text is clamped at 1.3×, and at `f > 1.3` the cruise button leaves the bottom capsule. §3.5 (`GRAD = round(40 × Lb)` animates with the dim).
   - §4.3 to §4.6: velocity hand-off, projection `pos + 0.499 × v`, the rubber band, and the value-magnet row ("cruise: within ±0.08× of 1.0×; ±12.8 px at 8 px per 0.05× on the cruise pill").
   - §4.10 rows **Cruise ramp**, **Cruise disc spin**, **Panel camera**, **Rain on glass**, **Scene glyph loops**, **Level bars**, **Dim shift**, **Light follows the story**, **Materialise**, **Dematerialise** and **Rubber band**. §4.11 in full: the sources of each setting, the Reduce Motion table including its Cruise row, and the Reduce Transparency and Increase Contrast rules.
   - §5 intro (rate limits: ticks 40 ms, impacts 120 ms; the Haptics switch). §5.1: the Android rule and `haptics.systemEnabled`. §5.2 rows `autoscroll.start` (`ahap:cruise`), `autoscroll.toggle`, `autoscroll.step`, `autoscroll.end`, `detent.tick`, `detent.magnet`, `detent.limit`, `panel.step`, `zoom.limit`, `chapter.arm`, `chapter.next`, `select`, `toggle.on` and `toggle.off`. §5.3 row `cruise`.
   - §6: UI sounds are suppressed while a soundscape plays; the one audio-session owner `mobile/lib/skins/skin_audio.dart`; the states `idle`, `soundscape` and `narration` with their iOS categories and Android focus; the transitions; and the "In the background" rules.
   - §8.0.1 (orientation: phones widen to all four orientations inside readers). §8.0.3 (`?sheet=soundscape`; the Settings slugs `ambient` and `feedback`). §8.0.5 (Android back order row 7 "Guided view", `gestures.setExclusionRects` for the scrub rail). §8.0.8 (the 18+ purge, step 1: "narration, cruise and the soundscape stop"). §8.0.9 (sign-out, profile loss and profile switch stop cruise and the soundscape).
   - §8.14.2 (chrome groups, the bottom capsule with the cruise button, scrub rail, auto-hide and minimise, cinema mode, locked mode). §8.14.3 (the double-tap rule, the trailing-edge drag, the long-press page menu with "Guided view"). §8.14.4 (the next-chapter card). §8.14.5: the Ambient section, the text-scale move, and **Keep screen awake**, the one rule for both readers. §8.14.7 (hardware keys `p`, `<`, `>`, `shift+p`, `shift+s`; Esc order). §8.14.9 (the single overlay layer). §8.14.11 in full: the Reader system UI positions, the landscape phone layout ("A running cruise shows its pill above the rail's trailing end"; the ⋯ menu holds Cruise and Guided view; the novel ⋯ holds Soundscape) and the tablet-landscape desktop panels.
   - §8.15.1 (the seven papers and their ink). §8.15.3 (the Aa button's 6 px `iris400` dot badge and its accessible name while a soundscape plays; the novel bottom capsule's cruise button in scroll mode). §8.15.4 (cruise pace in novels: 1.0× is the profile's reading pace, default 250 wpm). §8.15.5 (the Ambient group of the Aa sheet). §8.15.8 (keys `a`, `<`, `>`, `shift+s`). §8.16.2 (the player's header ⋯ holds **Soundscape**; the speaking orb's narrator hue). §8.16.6 (the sleep timer's 8 s fade).
   - §8.25.3: the **Ambient** group of Reader defaults, and the migration row "Cruise speed" ("mobile: nothing stored, default 1.0"). §8.25.5 (Soundscape defaults).
   - §11 rows: "Vertical drag on the cruise pill", "Flick while cruising", "Touch the strip while cruising", "Drag the trailing edge", "Tap bands | Guided view", "Double tap", "Pinch out | Guided view", "Swipe horizontally | Guided view", "Swipe down".
   - §13 rows 15 to 18. §14.1, §14.4, §14.5, §14.6 (44 × 44 pt on iOS, **48 × 48 dp on Android**), §14.8, §14.9 and §14.10 ("Cruise never starts on its own under Reduce Motion; the camera in guided view cuts").
   - §15.3 in full: the file map (`shaders/rain_on_glass.frag`, `soundscape/generator.dart`, `soundscape/mixer.dart`), the Packages bullet, the Native bullet (`mm/platform` methods) and the Accessibility scope. §15.4 (the five state fields and the command table). §15.5: the keys table (`mm.reader-prefs.u{user}p{profile}` map `"source:series" → {…, cruiseSpeed, soundscape: {scene, mix}}`, `mm.soundscape.defaults`) and row 11 (the recorded-layer route). §15.7: the Flutter column of the live-surface table, "the rain shader … counts as one extra Flutter layer", page samples in a `compute()` isolate, and the sensors rule. §15.11 row `flutter_soloud`.
4. `docs/redesign/cinematic/DESIGN.md` §9.4.3. Its **Detection**, **Rule**, **Parity** and **Cache** paragraphs are the panel contract for both skins. Also read §15.4 (the shared engine seam).
5. `docs/redesign/inventory/mobile.md`: S15 and S19 items 31 and 32 (today's auto-scroll switch and its 30 / 60 / 120 px/s slider) and the gestures line, S26 and N1 (the novel reader and type panel), §5a K05 (keep screen awake) and K08, §6a (auto-scroll "frame-delta based, clamps long frames to 1/60 s", keep-awake wakelock) and §6b (the novel reading line; 250 wpm). `docs/redesign/inventory/capabilities.md` §13 (manifest `pages[].tint` and `pages[].panels`, progress) and §25 (reader-flow capabilities).
6. `docs/redesign/00-baseline.md` (the green baseline you must keep: `flutter analyze` clean, 2012 tests passing).
7. `docs/redesign/prompts-plan.json`: the entry for `mobile/00` (its `TRACK RULE` binds this file), the entry for this file, and the entries for `mobile/02`, `mobile/23`, `mobile/25`, `mobile/29`, `mobile/34`, `mobile/35`, `mobile/36`, `mobile/37` and `mobile/39`, which say what they already built.
8. The web twin `docs/redesign/prompts/web/44-glass-ambient-reader-extras.md` (the same feature on the web; the values in its sections B to G must match yours, see "Parity with the web twin" below) and, when it exists, `docs/redesign/proof/web-44/report.md`.
9. Earlier mobile reports, when present: `docs/redesign/proof/mobile-{23,25,29,34,35,36,37,39}/report.md`. They give the engine API names, the `SkinGlass` parameters, the audio-session state machine, the reader overlay layer, the novel pagination and the settings keys.
10. Code you build on. Read all of it before planning:
    - `mobile/lib/features/reader/engine/`. Find the engine with `grep -rn "chromeBuilder" mobile/lib/features/reader/engine`, then read it and its tests in full: auto-scroll, `currentPageSample`, `scrollVelocity`, `panelBoxes`, `setCamera`, `pageToViewport`, `pageLayerTransform`, `engageFromVelocity`, `overscrollExtent`, `page_tint.dart` and the panel detector with `test/features/reader/engine/panels_test.dart`.
    - `mobile/lib/features/reader/models/reader_prefs.dart` and `providers/reader_prefs_provider.dart` (the per-series and per-profile records from `mobile/12`), `mobile/lib/features/reader/utils/reader_wakelock.dart` and `reader_display_mode.dart`.
    - `mobile/lib/features/novels/utils/novel_book.dart` (`kWordsPerMinute = 250`), the reading-pace source behind "6 min left" (`grep -rn "minLeft\|readingPace\|wordsPerMinute" mobile/lib/features/novels`), `narration_playback.dart`, `novel_audio_session.dart`, `providers/novel_audio_provider.dart`, and the sleep-timer provider from `mobile/37` (`grep -rln "sleep" mobile/lib/features/novels mobile/lib/skins/glass`).
    - `mobile/lib/skins/skin_audio.dart` (the audio-session owner and `SoLoud` init from `mobile/02`), `mobile/lib/skins/skin_haptics.dart`, and the `mm/platform` channel wrapper (`grep -rln "mm/platform" mobile/lib`).
    - `mobile/lib/skins/glass/`: `skin_glass.dart` (tiers, the tint and `lb` parameters, the layer and shape registry, `GlassTextAxes`), `physics/glass_physics.dart` (`project`, `rubberband`, `Magnet`, `dimFor`), `motion.dart` (`GlassMotion.play`), `motion_names.g.dart`, `haptics.dart`, `tokens.g.dart`, `routes/glass_sheet_route.dart`, the reader, novel, listen and settings screens (`ls mobile/lib/skins/glass/screens`), the primitives (`ls mobile/lib/skins/glass/primitives`: Slider, Switch, Segmented, IconButton, Menu, Toast), `icons/phosphor.g.dart`, `icons/glass_glyphs.g.dart` (the `flywheel` and `panel-focus` glyphs), and `copy/genres.dart`.
    - The OKLCH helpers the ambient field and page tint already use (`grep -rln "oklch\|OkLch\|Oklab" mobile/lib`).
    - How Cinematic's `mobile/23` fetched and cached `/app/soundscapes` files (`grep -rn "soundscapes" mobile/lib`). Reuse the shared downloader if it lives in `features/`. Never import from `skins/cinematic/`.
    - `backend/media/soundscapes/SOURCES.md` and `backend/media/soundscapes/glass/SOURCES.md` (read only), and `brand/demo/pages/` with `brand/demo/demo.json` (the §12.7 demo art and its panel boxes).

## Preconditions (check before writing the plan)

- `git log --oneline -30` shows the `mobile/43` commits. `git status -- mobile` is clean.
- `node design/build.mjs --check` passes. `grep -in "cruise.\?ramp\|panel.\?camera\|rain.\?on.\?glass\|scene.\?glyph\|level.\?bars\|cruise.\?disc" mobile/lib/skins/glass/motion_names.g.dart` finds all six names (**Cruise ramp**, **Panel camera**, **Rain on glass**, **Scene glyph loops**, **Level bars**, **Cruise disc spin**); use the enum's exact spelling in code. `ls mobile/assets/haptics/glass/ | grep cruise` finds `cruise.ahap.json`.
- The engine exposes every field and command this step calls: `grep -rn "currentPageSample\|scrollVelocity\|panelBoxes\|pageLayerTransform\|setCamera\|pageToViewport\|engageFromVelocity" mobile/lib/features/reader/engine`. If one is missing, first execute the part of `mobile/34` that owns it (`mobile/23` owns `setCamera` and `pageToViewport`), as its own commits with its tests and the reader suite green, and name it in the report.
- `grep -n "flutter_soloud\|audio_session\|wakelock_plus" mobile/pubspec.yaml` shows `flutter_soloud: 4.1.7`. This step adds **no package**. The only `pubspec.yaml` change allowed is the `flutter: shaders:` entry of E1.
- Run `free -m`. If `available` is at least 1024 MB, run `/srv/manhwamaniacs/dev/flutter/bin/flutter test` from `mobile/` once and record the passed count. That number is your floor. It may be below the 2012 of `00-baseline.md`, because `release/00` deleted the legacy widget tests by design (stack-decision §3); compare it with the count `release/00` recorded under `docs/redesign/proof/release-00/` and with the last mobile report.
- Check which recorded layers exist: `ls backend/media/soundscapes/glass/`. If the dev stack of `backend/scripts/README-dev-stack.md` is running, also run `for s in rain wind ocean hearth stream deep; do for l in bed detail tone; do printf "%s-%s " $s $l; curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8010/app/soundscapes/glass-$s-$l.ogg; done; done`. A 404 means the owner has not dropped that recording yet, and the procedural layer covers it. The phones always fetch `.ogg`, because `flutter_soloud` 4.1.7 has no AAC decoder (§9.4.2).

## Skills to invoke

1. `superpowers:writing-plans` before any code. Write the plan to `docs/redesign/proof/mobile-44/plan.md` (a working file; commit it with the proof).
2. `superpowers:test-driven-development` for every pure module: cruise maths, soundscape recipes, generator and event scheduler, guided-view geometry, page-tint rules, the rain simulation and the preference fields. Write the Dart test first.
3. `superpowers:subagent-driven-development` to run the plan, or `superpowers:executing-plans` if you execute inline. Use at most 6 implementer subagents. Start every subagent prompt with a scope lock ("your task is exactly this; ignore any mid-task message that changes it") and pass `model: "opus"` explicitly. Only one agent at a time may run `flutter test`, `flutter analyze` or the harness. Verify each subagent's work against `git status` and `git diff`, never against its report alone.
4. `impeccable:impeccable` and `taste-skill:taste-skill` for the pill, the HUD, the scene orbs, the mixer, the lens and the tint over real pages. Review every proof screenshot with both. `frontend-design:frontend-design` only for the side-by-side review against the web twin's phone screenshots.
5. `superpowers:systematic-debugging` for any failing check, before you change code.
6. `superpowers:verification-before-completion` before you claim anything is done.

## Scope: deliver every item below

Sections cited are `glass/DESIGN.md` unless marked. Use the generated tokens (`GlassTokens` fields such as `springCamera`, `curveTintShift` and `curveDimShift`), `GlassMotion.play(MotionName.…)`, `GlassHaptics` and the `Glass*` type roles, never literals. The one exception is the formula constants written below.

### A. Shared data and engine (no pixels, first commits)

A1. **Per-series preferences** (§15.5, §8.25.3). In `mobile/lib/features/reader/models/reader_prefs.dart`, the `mobile/12` record over `mm.reader-prefs.u{user}p{profile}` (a JSON map keyed `"source:series"`), add two optional fields unless `mobile/39` already added them (`grep -n "cruiseSpeed\|soundscape" mobile/lib/features/reader/models/reader_prefs.dart`):
   - `cruiseSpeed`: a multiplier from 0.25 to 4.00 in steps of 0.05. When absent, it falls back to the profile default (A2). Mobile migration (§8.25.3): nothing was stored before (today's 30 / 60 / 120 px/s choice was session-only, mobile.md S15 item 32), so there is nothing to read and the default is 1.0. Never write or reinterpret a Cinematic key.
   - `soundscape`: `{scene: "rain" | "wind" | "ocean" | "hearth" | "stream" | "deep", mix: {bed, detail, tone}}`, each mix value 0 to 1. It is written only while "Remember for this series" is on and removed when that switch is turned off.
   - Unknown fields are preserved (the `mobile/12` normaliser rule). Tests in `mobile/test/features/reader/models/reader_prefs_test.dart`:
     - a missing `cruiseSpeed` reads the profile default;
     - 4.3 clamps to 4.00 and 0.1 to 0.25;
     - 1.26 snaps to 1.25;
     - a `soundscape` record round-trips;
     - an unknown field survives a write;
     - the two profile scopes `u1p1` and `u1p2` never see each other's values.
A2. **Profile defaults** (§8.25.3 Ambient, §8.25.5, §15.5). Read the names `mobile/35` and `mobile/39` created; never add a second key for any of them (`grep -rn "cruiseDefault\|pageTinted\|guidedDefault\|keepAwake\|mm.soundscape.defaults" mobile/lib`):
   - In the `glass` object of the profile-scoped `mm.reader-settings.u{user}p{profile}` record, through `mobile/35`'s `glass_reader_values.dart`: `glass.cruiseDefault` (1.00; `mobile/39` A8), `glass.pageTinted` (`true`; `mobile/35`), `glass.guidedDefault` (`false`; `mobile/39` A8) and `glass.keepAwake` (seeded once from K05 by `mobile/35`). Only a field that is missing is added here, with exactly that name and default.
   - `mm.soundscape.defaults.u{user}p{profile}` = `{scene: "off" | <scene>, matchStory: true, mix: {bed: 0.8, detail: 0.5, tone: 0.3}, volumeDb: -12, lowerUnderNarration: true}` through `mobile/39`'s `soundscapeDefaultsProvider` in `mobile/lib/features/reader/providers/soundscape_defaults_provider.dart`. If its test lacks them, add the clamping cases (`volumeDb` −30 to 0, each mix value 0 to 1) and the profile scoping; create the provider at that path only if `mobile/39` did not.
A3. **The engine ramp.** Cruise ramps linearly from 0 to the target over 400 ms (§4.10 Cruise ramp). If the engine's auto-scroll start has no ramp, add an optional `rampMs` parameter (default 0, so Cinematic is unchanged) in `features/reader/engine/`. Keep the existing frame-delta rule that clamps long frames to 1/60 s. Test it with a fake clock: the linear ramp `v(t) = 60 × t / 0.4` px/s covers 3 px ± 0.5 in the first 200 ms and 12 px ± 0.5 over the whole 400 ms ramp. The reader suites (`test/features/reader`) must stay green.
A4. **Novel auto-scroll.** Check whether `features/novels` already exposes an auto-scroll command for the scroll-mode column (`grep -rn "autoScroll\|AutoScroll" mobile/lib/features/novels`). If it does not, add `mobile/lib/features/novels/utils/novel_auto_scroll.dart`. It is a skin-neutral controller that takes the column's `ScrollPosition` and moves it by `v × dt` per frame from a `Ticker`, with the same `rampMs`, the same 1/60 s long-frame clamp, `setSpeed`, `pause`, `resume` and a stop at the end of the chapter. Cover it with `novel_auto_scroll_test.dart`, which checks the same ramp numbers as A3 and the stop at `maxScrollExtent`.
A5. **Recorded-layer files** (§9.4.2, §15.5 row 11). If `mobile/23` put a skin-neutral soundscape file cache under `features/`, extend it. Otherwise create `mobile/lib/features/reader/services/soundscape_files.dart`:
   - URL: `{apiBase}/app/soundscapes/glass-{scene}-{layer}.ogg`, built with the same base-URL helper `mobile/23` used for `/app/soundscapes` (the id spelling of glass §9.4.2 and §15.5, the same URL `web/44` requests; `backend/07` maps it onto `backend/media/soundscapes/glass/` and also answers the plan's older `/app/soundscapes/glass/{scene}-{layer}.ogg` alias, which no client uses).
   - Storage: `getApplicationSupportDirectory()/soundscapes/glass/{scene}-{layer}.ogg`. Download to `{name}.part` and rename it into place on a 200 with a non-empty body.
   - `Future<File?> ensure(scene, layer)` returns the cached file, or downloads it once, or returns `null` on a 404, a network error or offline (`connectivity_plus`). A failed name is remembered for the session, so it is not retried on every play.
   - Test with a fake Dio adapter: 200 writes the file and a second call makes no request; 404 returns null and makes no retry in the same session; a `.part` file never counts as cached.

### B. Cruise (§9.4.1, §8.14.2, §8.15.3, §8.15.4, §11)

Put the pure maths in `mobile/lib/skins/glass/ambient/cruise.dart` (with `mobile/test/skins/glass/ambient/cruise_test.dart`), the state in `ambient/cruise_controller.dart` (a Riverpod `Notifier` scoped to the open reader) and the UI in `ambient/cruise_pill.dart`.

B1. **Speed model.**
   - Manga: `pxPerSecond(m) = 60 × m`, with `m` clamped to 0.25–4.00, which gives 15 to 240 px/s. The range spans ÷4 to ×4 around 1.0×, which is what the contract's "logarithmic" range means.
   - Novel scroll mode (§8.15.4): `pxPerSecond(m) = m × (wpm / 60) / wordsPerLine × lineHeightPx`.
     - `wpm` is the profile's measured pace from the source behind "6 min left", or `kWordsPerMinute` (250) until two minutes of samples exist.
     - `lineHeightPx` is `fontSize × lineHeight` of the rendered column.
     - `wordsPerLine` is the chapter's word count divided by `columnContentHeight / lineHeightPx`.
   - Tests: `pxPerSecond(1) = 60`, `pxPerSecond(4) = 240`, `pxPerSecond(0.1) = 15`, and the novel formula at 250 wpm, 12 words per line and 30 px lines gives 10.42 px/s.
B2. **Entry points.**
   - The cruise button is the `flywheel` glyph from `GlassGlyphs`, a 44 pt icon button (48 dp hit on Android). It sits in the manga reader's bottom capsule and in the novel reader's bottom capsule (scroll mode only).
   - In manga Single and Double layouts the button is not rendered and `p` does nothing, because cruise scrolls a strip.
   - Landscape phone (§8.14.11): the manga top-right ⋯ menu holds "Cruise".
   - Text scale (§3.3 rule 4): at `f > 1.3`, where `f = MediaQuery.textScalerOf(context).scale(17) / 17`, the cruise button leaves the bottom capsule and becomes the first row "Cruise" of the reader settings sheet (manga) or of the Aa sheet's Ambient group (novel).
   - Hardware keys go through the reader's `Shortcuts`/`Actions` registry from `mobile/35`: `p` (manga, including read-all), `a` (novel scroll mode), and `<` / `>` (`CharacterActivator('<')` and `CharacterActivator('>')`), which step by 0.25×. In the novel reader `<` and `>` change cruise speed only while narration is not playing (§8.15.8). All of these obey the Settings → Shortcuts "Single-key shortcuts" switch.
   - The reader-settings Ambient row "Cruise speed" is a Glass Slider from 0.25 to 4.00 in steps of 0.05, with the 1.0× magnet. It writes `cruiseSpeed` for this series and is the non-drag alternative for the pill (§14.8).
B3. **Start.**
   - A tap calls the engine's auto-scroll start with `pxPerSecond(m)` and `rampMs: 400` (§4.10 Cruise ramp), fires the `autoscroll.start` haptic (`ahap:cruise`: C@0.000 dur 0.180 I0.25 S0.30; T@0.180 I0.40 S0.60), and morphs the button on `springSnappy` into the **flywheel pill**.
   - The pill is a 44 pt tall capsule inside the bottom capsule's `SkinGlass` group. It is a sibling shape of that one layer, never its own `LiquidGlassLayer`. It has 16 px horizontal padding, a 20 px disc glyph, a 6 px gap, and `m` in `mono` 13/18 `onGlass`. The value is always shown with one decimal ("1.0×"), and with two when the second decimal is not zero ("1.25×").
   - The disc turns at `2π × m` radians per second (one turn per second at 1.0×, §4.10 Cruise disc spin). Drive it from the one `Ticker` of the controller, and hold it still while cruise is paused.
   - Semantics: `Semantics(button: true, label: "Cruise", value: "1.0 times, playing" (or "paused"), increasedValue:, decreasedValue:, onIncrease:, onDecrease: stepping 0.25, onTap: stop)`. VoiceOver's swipe up and down and TalkBack's volume keys therefore adjust the speed without a drag.
B4. **Speed by drag** (§11 "Vertical drag on the cruise pill", §4.6 value magnet).
   - A vertical drag on the pill (`onVerticalDragStart/Update/End`, slop `thresholdDragSlopTouch` 10) changes `m` by 0.05 per 8 px. Up is faster. The value is clamped to 0.25–4.00.
   - `autoscroll.step` (`selection`) fires each time `m` crosses a multiple of 0.25.
   - **The magnet:** while the raw value is within ±0.08 of 1.00 (`physicsValueMagnetSpeed`, ±12.8 px of drag), the value shows and applies as exactly 1.00. `detent.magnet` (`rigid(0.4)`) fires once on entering that band.
   - Past either end the value stops and `detent.limit` (`soft(0.5)`) fires once.
   - While dragging, a **HUD** floats 12 px above the pill. It is a `SkinGlass(tier: T2)` capsule (`glassThin`), 44 pt tall with 16 px padding, showing the value in `monoLarge` 22/26 `onGlass` ("1.5×"). It enters and leaves through `GlassMotion.play` with the **Materialise** and **Dematerialise** moves (use the generated enum spelling). The HUD takes the scrub-lens shape slot of the bottom capsule's layer (the two never show together).
   - On release the value persists to `cruiseSpeed` for this series, and the engine's speed follows through `setSpeed()` with no ramp.
B5. **Trailing-edge drag while cruising** (§9.4.1, §11 "Drag the trailing edge"). While cruise runs, a vertical drag on the scrub rail's hit strip (44 pt; 48 dp on Android) changes speed by the same 8 px per 0.05× rule and shows the same HUD, instead of scrubbing. When cruise is paused or off, the rail scrubs as `mobile/35` built it. The Android exclusion rect from `mobile/35` (a 200 dp band centred on the thumb, through `gestures.setExclusionRects`) stays in place in both modes.
B6. **Flick to cruise** (§9.4.1, §13 row 17). While cruise is on, a touch on the strip pauses the engine under the finger (the catch). On release:
   - If the release velocity is downward, meaning content moving up and reading forward, above 240 px/s: let the strip's ballistic simulation coast. Watch the engine's `scrollVelocity` each frame, and on the first frame where it is at or below 240 px/s call `engageFromVelocity(v)`. The pill takes `m = round(v / 60, 0.05)` with `autoscroll.step`, and the new `m` persists as this series' `cruiseSpeed`. There is no 800 ms wait and no ramp, because the scroll is already moving at that speed.
   - Any other release (a hold, a slow drag, an upward flick): resume after 800 ms with the 400 ms ramp at the saved speed, counting from the moment the momentum falls below 15 px/s.
B7. **Pause, resume and stop.**
   - Tapping the pill stops cruise (`autoscroll.toggle`, `soft(0.4)`) and the pill morphs back into the button on `springSnappy`.
   - Any chrome interaction pauses cruise: a sheet, a menu, the scrub rail when not cruising, or the go-to popover. Closing it resumes after 800 ms with the ramp.
   - Reaching the end of available pages stops cruise with `autoscroll.end` (`medium`). In continuous mode cruise carries across chapter seams. In one-at-a-time mode it stops at the chapter end, and the next-chapter card behaves as §8.14.4.
   - Android volume keys (K08) page as before and pause cruise for 800 ms.
B8. **Keep awake** (§8.14.5, the one rule, through `features/reader/utils/reader_wakelock.dart`). While cruise runs or guided view is open, `WakelockPlus.enable()` holds whatever the Keep screen awake switch says. With the switch off, release it 2 s after cruise stops and guided view closes. Always release it on leaving the reader and on `AppLifecycleState.paused`. Narration does not hold the wakelock.
B9. **Landscape phones** (§8.14.11). With the bottom scrub rail, a running cruise shows its pill above the rail's trailing end, 8 px above the rail's hit strip, at the Reader system UI's `max(inset.right, 16)` edge.
B10. **Reduce Motion** (§4.11 Cruise row, §14.1, §14.10), using `glassMotionPrefsProvider.reduced` (the OS setting or the in-app switch):
   - Cruise starts only from the button, `p` / `a`, the settings slider or the semantics action, and with no ramp (`rampMs: 0`).
   - After a touch it does **not** resume on its own. The pill shows the paused disc, and a tap on the pill or `p` resumes at speed.
   - Flick to cruise never engages.
   - The disc is static.
   - Cruise never starts on chapter open or from any default under Reduce Motion.
B11. **Stops from outside.** Register a stop with the Glass shell's `purgeMatureLocal(ref)` step 1 for when the open series is mature, and with the sign-out, profile-gone and profile-switch flows of §8.0.9. Leaving the reader stops cruise, and so does `AppRestart` (a skin switch): the controller's `ref.onDispose` stops the engine's auto-scroll.

### C. The soundscape engine (§9.4.2, §6, §15.3)

The files are:
- `mobile/lib/skins/glass/soundscape/recipes.dart`: the pure scene table, `matchScene` and levels.
- `soundscape/generator.dart`: the DSP, the WAV writer, and the isolate entry.
- `soundscape/mixer.dart`: layers, fades, ducking, the event scheduler, music detection, and the audio port.
- `soundscape/soundscape_controller.dart`: a Riverpod `Notifier` holding the states and commands.

Tests go in `mobile/test/skins/glass/soundscape/`.

C1. **Audio port.** In `mixer.dart`, declare `abstract interface class SoundscapeAudio` with exactly the calls the mixer needs:
   - `loadMem(name, bytes)`, `loadFile(path)`;
   - `play(source, {volume, pan, looping})`, `setVolume(handle, v)`, `fadeVolume(handle, to, duration)`, `setPause(handle, paused)`, `stop(handle)`;
   - `disposeSource(source)`, `getPosition(handle)`.

   The production class `SoLoudSoundscapeAudio` forwards each call to `SoLoud.instance` (`flutter_soloud` 4.1.7, already initialised by `skin_audio.dart`). §15.11 confirms `loadMem`, `loadFile`, `setVolume` and `fadeVolume` in 4.1.7; check the other calls against the 4.1.7 sources (`ls ${PUB_CACHE:-$HOME/.pub-cache}/hosted/pub.dev/flutter_soloud-4.1.7/lib`) before relying on them, and use the 4.1.7 names. A `FakeSoundscapeAudio` in the tests records the calls, because the FFI engine cannot run in `flutter test`.
C2. **The generator** (§9.4.2 Playback engines, "Phones").
   - Every procedural loop layer is rendered in a background isolate (`Isolate.run`) as **30 s, mono, 32 kHz** PCM: 960,000 samples, written as a 16-bit little-endian WAV (header `RIFF`/`WAVE`, `fmt ` PCM 1 channel 32000 Hz, `data` 1,920,000 bytes).
   - Seamless loop: render 32 s. For `i` in the first 64,000 samples (2 s), `out[i] = sig[i] × sin(π/2 × i/64000) + sig[960000 + i] × cos(π/2 × i/64000)` (an equal-power cross-fade of the last 2 s into the first 2 s). After that, `out[i] = sig[i]`.
   - Noise sources: white noise from `Random(seed)`. Pink noise by Paul Kellet's refined filter over white. Brown noise by the leaky integrator `b = (b + 0.02 × white) / 1.02`, then × 3.5.
   - Filters are RBJ-cookbook biquads (low-pass, high-pass, and band-pass with constant 0 dB peak gain). Time-varying filters recompute their coefficients every 32 samples.
   - LFO gain rule: `g(t) = 1 − depth × (0.5 + 0.5 × sin(2π f t))`, so the gain moves between `1 − depth` and 1.
   - Levels: every layer is normalised to **−24 dBFS RMS**, except the Hearth bed at **−18 dBFS RMS**. The Deep bed is its two sines at equal amplitude plus the pink noise 18 dB below the sines' combined RMS, with the whole layer normalised to −24 dBFS.
   - The output also includes an **RMS envelope** at 30 Hz (900 `Float32` values, 0 to 1) that drives the level bars.
C3. **The recipes, exactly.** This is §9.4.2's procedural-fallback column ("always available, no files"), made exact per layer:

   | Scene | Bed (loop) | Detail | Tone (loop) |
   |---|---|---|---|
   | Rain | pink noise → high-pass 400 Hz → low-pass 6 kHz | **events**: droplet ticks, a sine at 2–4 kHz (uniform), 4 ms long with a 1 ms attack and exponential decay. The rate wanders between 8 and 20 per second on a 0.1 Hz random walk, and each tick is panned uniformly between −0.8 and 0.8 | brown noise → low-pass 200 Hz, at −24 dBFS |
   | Wind | brown noise → band-pass 300 Hz, Q 0.7, its centre modulated ±150 Hz by a 0.08 Hz sine LFO; a 0.05 Hz gain LFO with depth 0.4 | **events**: filtered noise bursts, white noise → band-pass 1.2 kHz, Q 1, 40–120 ms long, Poisson rate 0.5 per second | silent in the built-in version |
   | Ocean | brown noise → low-pass 900 Hz; a 0.1 Hz gain LFO with depth 0.7 | **loop**: white noise → high-pass 2 kHz, whose gain follows the same 0.1 Hz swell delayed by 1.5 s (a second LFO at phase −54°) | silent in the built-in version |
   | Hearth | brown noise → low-pass 1.2 kHz, at −18 dBFS | **events**: crackles, white-noise bursts 3–8 ms long → band-pass 3 kHz, Q 2, Poisson rate 6 per second | silent in the built-in version |
   | Stream | pink noise → band-pass 1.8 kHz, Q 1.2; a 7 Hz gain LFO with depth 0.15 | silent in the built-in version | silent in the built-in version |
   | Deep | sines at 55 Hz and 82.41 Hz (A1 + E2), each detuned by a 0.03 Hz LFO of ±4 cents (`f(t) = f0 × 2^((4/1200) sin(2π 0.03 t))`, phase integrated), plus pink noise → low-pass 300 Hz at −18 dB relative to the sines | silent in the built-in version | silent in the built-in version |

   - A silent layer still has its mixer slider, which controls its recorded layer once that arrives.
   - **Event banks** replace per-event synthesis: 12 droplet ticks at 2000 + 2000 × k/11 Hz; 6 wind bursts of 40, 56, 72, 88, 104 and 120 ms; 12 crackles of 3 to 8 ms. Each is rendered once by the generator into a short WAV and loaded with `loadMem`.
   - The event scheduler in `mixer.dart` is a `Timer.periodic(20 ms)`. It draws Poisson arrivals from a seeded `Random`, plays every event due at or before now with `play(source, volume: layerGain × (0.6 + 0.4 × r), pan: p)`, picks the bank entry at random, and never plays an event before the window start. Event timing is quantised to 20 ms, which is inaudible for random textures.
   - Parity: if `frontend/src/skins/glass/soundscape-recipes.ts` from the web twin exists when you start (`git log --oneline -- frontend/src/skins/glass/soundscape-recipes.ts`), read its levels and LFO rule. If they differ from the above, match the web and record it in the report.
C4. **Tests** (`recipes_test.dart`, `generator_test.dart`, `scheduler_test.dart`):
   - the table covers 6 scenes × 3 layers, with each cell `loop`, `events` or `silent` as above;
   - one rendered layer has 960,000 samples and a correct 44-byte WAV header;
   - the loop seam: `|out[0] − out[959999]|` is at most the 99th percentile of `|out[i+1] − out[i]|` over the buffer;
   - the RMS of every loop is −24 ± 0.5 dBFS (Hearth bed −18 ± 0.5);
   - the envelope has 900 values;
   - the scheduler at rate 6 per second over 10 s of virtual time (a fake clock) yields 45 to 75 events and never one before the window start, and the same seed gives the same events;
   - `dbToGain(-12) ≈ 0.2512` and `dbToGain(-30) ≈ 0.0316`.
C5. **Caching the rendered bytes.** The first render of a loop writes its WAV bytes to `getApplicationSupportDirectory()/soundscapes/glass/procedural/{scene}-{layer}-v1.wav`. Later starts read the bytes and `loadMem` them; the render runs only when the file is missing. Eight loops exist (Rain bed and tone, Wind bed, Ocean bed and detail, Hearth bed, Stream bed, Deep bed), about 15.4 MB in total.
   - **Prewarm:** when a reader opens with a scene due to play (remembered, matched or default), start rendering or reading that scene's loops in the background right away, so they are ready when the scene starts. The reader's own first frame never waits for this.
   - When the soundscape sheet opens, render the remaining scenes one at a time in the background isolate.
C6. **Mixer graph** (§9.4.2 Mixing rules). Each playing layer handle's volume is `mix[layer] × master × duck × mute`, where:
   - `master = 10^(volumeDb/20)` (−12 dB → 0.251);
   - `duck` is 1, or 0.251 while ducked;
   - `mute` is 0 while muted for music, otherwise 1.

   All changes go through `fadeVolume`:
   - fade in 3 s (the master from 0);
   - fade out 1.5 s;
   - duck and unduck over 400 ms;
   - the recorded cross-fade over 2 s.

   There is one `SoundscapeAudio` voice per loop layer (`looping: true`) plus the event scheduler per event layer.
C7. **Recorded layers** (primary when available). On a scene's first play, call `soundscape_files.ensure(scene, layer)` for its three layers.
   - When a file arrives, `loadFile` it, start it at volume 0, and `fadeVolume` it up over 2 s while its procedural counterpart fades down over the same 2 s. Then stop and dispose that procedural voice, or stop its event scheduler.
   - A 404, a network error or a load error keeps the procedural layer playing.
   - The level bars' envelope for a recorded layer comes from `SoLoud.instance.readSamplesFromFile` when `grep -rn "readSamplesFromFile" ${PUB_CACHE:-$HOME/.pub-cache}/hosted/pub.dev/flutter_soloud-4.1.7/lib` finds it: 2,700 averaged samples over a 90 s loop, read once on load. Otherwise it reuses the procedural layer's envelope. Record which one you used.
C8. **Starting** (§9.4.2 Starting).
   - The procedural version starts on the tap, from memory or the cached bytes, and the master fades in over 3 s. The scene's recorded layers replace their procedural layers as they arrive.
   - Offline with nothing cached, or with any recorded layer failing, the scene keeps its procedural layers. After the first 2 s (while files may still arrive), the scene orb shows the `cloud-slash` badge, and its semantics hint reads "Playing the built-in version".
   - Time from the tap to first audio is logged in the Diagnostics motion log as `soundscape.start` with its milliseconds. Record the figure from the owner's device pass.
C9. **Audio session** (§6). The controller requests states from `skin_audio.dart`'s state machine and never calls `AudioSession.instance.configure` itself:
   - `idle → soundscape` on start: iOS `.playback` + `.mixWithOthers`, Android `AUDIOFOCUS_NONE`.
   - `soundscape → narration` when narration starts, and `narration → soundscape` when it stops with a scene still on.
   - Back to `idle` 1.5 s after the last fade-out.
   - UI sounds (`skin_audio.dart` cues) stay silent in `soundscape` and `narration`.
   - Narration state comes from the one signal `mobile/37`'s player uses. If that signal lives only inside a Glass widget, lift it into `skin_audio.dart`'s state machine, not into a second provider.
C10. **Narration, sleep and lifecycle.**
   - While narration plays, duck by 12 dB over 400 ms and back over 400 ms when it stops. With "Lower under narration" off, pause instead (fade out 1.5 s, then `setPause`), and resume with the 3 s fade when narration stops.
   - Follow the sleep timer's 8 s fade (`mobile/37`) and stop with it.
   - Leaving the reader: fade out 1.5 s and pause. Returning to a reader in the same app session resumes the same scene with the 3 s fade.
   - `AppLifecycleState.paused`: fade out 1.5 s and pause, unless narration is playing. In that case the soundscape keeps playing in the background, ducked, as §6 "In the background" says. On `resumed`, resume.
   - A system interruption (a call) pauses the soundscape and returns the session to `idle`. The interruption ending resumes nothing on its own; a toast offers "Resume".
   - Every voice and source is stopped and disposed in `ref.onDispose`, so an `AppRestart` (a skin switch), a profile switch or a sign-out leaves no voice playing.
C11. **Your own music** (§9.4.2). When a scene starts, check for other audio:
   - iOS: `AVAudioSession.secondaryAudioShouldBeSilencedHint` through `audio_session` (confirm the getter with `grep -rn "secondaryAudioShouldBeSilencedHint" ${PUB_CACHE:-$HOME/.pub-cache}/hosted/pub.dev/audio_session-*/lib`). If `audio_session` lacks it, add `audio.isOtherAudioPlaying` to the iOS side of `mm/platform` in `AppDelegate.swift`, reading `AVAudioSession.sharedInstance().secondaryAudioShouldBeSilencedHint`, in its own commit, and check the CI iOS dry run.
   - Android: `mm/platform` `audio.isMusicActive` (`AudioManager.isMusicActive`, added by `mobile/25`).

   If music is playing, the scene **starts muted** (state `muted`), and the toast "Your music is playing. Tap to mix the soundscape in." carries an action that unmutes over 1 s. The session is the `soundscape` state, so the user's music is never interrupted or ducked.
C12. **Match the story** (§9.4.2). `matchScene(genres)` walks the series' genre list in order, lowercased, and returns the first hit:
   - horror, thriller, mystery, psychological → Rain;
   - romance, slice of life, comedy, drama, historical → Hearth;
   - fantasy, isekai, school, supernatural → Stream;
   - adventure, sports → Ocean;
   - action, martial arts, murim, military → Wind;
   - sci-fi, mecha, cyberpunk, space → Deep;
   - nothing → Rain.

   When the reader opens, a scene is chosen in this order: a remembered per-series `soundscape`, then Match the story (when on), then the default scene. Tests cover every genre word above and the fallback.
C13. **States** (§9.4.2 States):
   - `off`;
   - `starting` (procedural, the first 2 s);
   - `playingRecorded` (every non-silent layer recorded);
   - `playingBuiltin` (at least one layer on its procedural fallback after 2 s);
   - `paused`;
   - `muted` (music playing);
   - `ducked`;
   - `unavailable`: `SoLoud` is not initialised or a `play` throws. Show the toast "Couldn't start the soundscape" and return the state to `off`.

   The controller exposes `{state, scene, matchedScene, levels (8 bar values), mix, volumeDb}` and the commands `start(scene)`, `stop()`, `setMix(layer, v)`, `setVolume(db)`, `unmute()`.
C14. **18+ purge.** Register a stop with the Glass shell's `purgeMatureLocal(ref)` step 1 for when the open series is mature.

### D. The soundscape sheet and its entry points (§9.4.2 Picker, §8.0.3)

D1. **The sheet.** `mobile/lib/skins/glass/soundscape/soundscape_sheet.dart` is registered as the `?sheet=soundscape` `GlassSheetPage` of the reader and novel routes, and of the listen player's host route.
   - Phone frame: the Glass sheet at `medium` (0.52 × viewport height), draggable to `large`.
   - Landscape phone: `min(560, width − 16)` wide and centred, at screen height − safe-top − 10 (§8.14.11).
   - Tablet-landscape desktop frame (§8.0.1: shorter side ≥ 600, width ≥ 1024), inside a reader: the section "Soundscape" at the top of the right panel's Settings tab. The panel opens on that tab and scrolls to the section.
   - Elsewhere on that frame: the 440 px right panel of §7.10.
   - The sheet body is T4 glass at `medium`, so its text is `onGlass` (§2.1.2 mapping).
D2. **Scene orbs** (`soundscape/scene_orb.dart`).
   - Six 64 px circles drawn as `fill2` twins (§2.4.2 rule 7; no backdrop read), each with its scene name under it in `footnote` `onGlass`.
   - The phone frame (§8.0.1: shorter side under 600) lays them out as a 3 × 2 grid; the tablet and desktop frames as one row.
   - **Off** is a 44 pt capsule radio above the grid on phones, and the first 64 px orb (the `speakerSimpleSlash` Phosphor glyph) in the row on wider frames.
   - All seven are wrapped in one `Semantics(container: true, label: "Soundscape", explicitChildNodes: true)`. Each orb is `Semantics(inMutuallyExclusiveGroup: true, checked: selected, button: true, label: "Rain")`, with ", matched to this series" appended to the label when Match the story chose it.
   - Under the matched orb, "Matched: Hearth" in `caption1` `onGlass`.
   - Hardware arrow keys move between orbs and Space or Enter selects (a `FocusTraversalGroup` with `ReadingOrderTraversalPolicy`).
   - Each hit area is at least 44 pt (48 dp on Android) with 8 px spacing.
D3. **Glyph patterns** inside each orb. One `CustomPainter` per orb draws on a 64 × 64 canvas clipped to the circle, in `label2` `Color(0xA3EBEBF5)`, with all orbs driven by **one** shared `Ticker`. Speeds are given per 60 Hz frame and scaled by the real frame delta:
   - Rain: 12 streaks, 1 × 8 px, falling 0.6 px/frame at 10° from vertical.
   - Wind: 6 leaves, 3 × 2 px, drifting left to right 0.4 px/frame on a ±4 px sine.
   - Ocean: 3 wave lines, 2 px thick, scrolling 0.3 px/frame.
   - Hearth: 8 embers of 2 px rising 0.5 px/frame with a 30 % flicker.
   - Stream: 4 ripple rings of 1 px expanding from 2 to 20 px radius in 2 s.
   - Deep: 14 stars of 2 px drifting 0.3 px/frame with a 5 s twinkle.

   The ticker stops while the sheet is closed or the orbs are scrolled out of view (`TickerMode` plus a visibility check against the sheet's scroll position). Under Reduce Motion each orb shows one still frame (§4.10 Scene glyph loops). The patterns are `ExcludeSemantics`.
D4. **Level bars** on the playing orb: 8 bars, 3 px wide and 2 px apart, centred in the orb, wrapped in `ExcludeSemantics`, and updated at 30 fps from the controller's `levels`.
   - Bars 1–3 show the Bed level, 4–6 Detail, and 7–8 Tone.
   - Each bar is `clamp(level × (0.7 + 0.3 × j_i), 0, 1)`, where `level` is that layer's envelope value at the voice's `getPosition` (event layers: an accumulator that adds each event's volume and decays by `exp(−dt / 80 ms)`) times its mix, and `j_i` is a per-bar value redrawn each frame from the seeded `Random` and smoothed with α = 0.3.
   - Under Reduce Motion the bars are static at the mix values (§4.10 Level bars).
D5. **Mixer** under the orbs, built from the `mobile/27` primitives, each at least 44 pt tall (48 dp on Android):
   - Sliders **Bed · Detail · Tone**, 0–100 % (defaults 80 / 50 / 30), with `detent.tick` every 10 % and step magnetism at 30 % of a step.
   - The master volume, −30 to 0 dB (default −12 dB), its value shown in `mono` "−12 dB".
   - Switches **Match the story** (default on), **Remember for this series** (default off; shown inside a reader only) and **Lower under narration** (default on).
   - Scope captions in `caption1` `onGlass`: "This series" beside the mix while Remember is on, otherwise "All series · Saved on this device" (§15.10 owner call).
D6. **Entry points.** Each opens the sheet:
   - the reader settings Ambient row "Soundscape" (manga) and the Aa sheet's Ambient row (novel), both showing the current state ("Off", "Rain", "Rain · built-in", "Rain · muted");
   - `shift+s` on a hardware keyboard in either reader;
   - the listen full player's header ⋯ item **Soundscape** (`mobile/37` built the ⋯; wire the item if it is a stub);
   - the landscape novel ⋯ item "Soundscape" (§8.14.11);
   - Settings → Sound & haptics → Soundscape defaults (`/settings/feedback`, from `mobile/39`). Make its rows read and write `mm.soundscape.defaults` if they do not already.
D7. **Novel Aa badge** (§8.15.3). While a scene plays, the Aa button carries a 6 px `iris400` dot on the backing disc rule of §2.1.2 (top-right of the glyph, inside the 44 pt hit), and its semantics label becomes "Type and page, soundscape playing".

### E. Rain on glass (§9.4.2 Rain on glass, §4.10, §13 row 16)

E1. **The shader.** `mobile/lib/skins/glass/shaders/rain_on_glass.frag` starts with `#include <flutter/runtime_effect.glsl>` and declares, in this order: `uniform vec2 uSize;` (first, set by the engine), `uniform float uTime;`, `uniform vec3 uDrops[10];` (x, y, radius in the filter input's pixel space; a radius of 0 means no drop), then `uniform sampler2D uBackdrop;` (the first sampler, which receives the filter input).
   - `uv = FlutterFragCoord().xy / uSize`, with `uv.y = 1.0 − uv.y` under `#ifdef IMPELLER_TARGET_OPENGLES`.
   - Per drop: a hemispherical lens profile. The displacement is at most 3 px at the centre and falls to 0 at the rim. A 1 px `rgba(255,255,255,0.35)` specular dot sits at the live light angle, passed as one more float, `uniform float uLight;` (radians), declared after `uDrops` and before the sampler. Name this addition to §9.4.2's uniform list in the report.
   - Add exactly one line block to `mobile/pubspec.yaml` under `flutter:`: `shaders:` → `- lib/skins/glass/shaders/rain_on_glass.frag`. `flutter test` compiles the shader bundle, so a compile error fails the suite.
E2. **The simulation**, in `mobile/lib/skins/glass/ambient/rain_on_glass.dart` (pure `RainSim` plus the widget), tested by `rain_on_glass_test.dart`:
   - 6 to 10 droplets, radius 3–6 px;
   - each run lasts 4 s along a gravity path with a 15 % lateral wobble, starting at a random position;
   - a new droplet every 0.6 s, up to the cap.

   Tests: never more than 10 alive; a spawn every 600 ms ± 1 frame; each run 4 s; radii inside 3–6; lateral offset ≤ 15 % of the travelled height.
E3. **The widget.** While the Rain scene is in `starting`, `playing*` or `ducked`, and a reader's glass chrome is on screen, `RainOnGlass` wraps these surfaces: the manga reader's top groups, bottom capsule and minimised pill, and the novel reader's top groups and bottom capsule. Each gets `ClipRSuperellipse` (the capsule's own radius) → `BackdropFilter(filter: ImageFilter.shader(shader))`. The uniforms are updated from one `Ticker`.
   - It is drawn only when `ImageFilter.isShaderFilterSupported` is true (Impeller, the owner's devices). Check that flag before loading the `FragmentProgram` or constructing the filter: in the pinned SDK, `ImageFilter.shader` throws `UnsupportedError` without Impeller, which is the case in `flutter test`.
   - It counts as **one extra layer** in `SkinGlass`'s registry while it runs (§15.7); register it through the registry's API so Diagnostics' "Glass layers on screen" shows it.
   - Read the `ImageFilter.shader` documentation in the pinned SDK (`grep -n "ImageFilter.shader\|isShaderFilterSupported" -A 30 /srv/manhwamaniacs/dev/flutter/bin/cache/pkg/sky_engine/lib/ui/painting.dart`), write the coordinate space of `FlutterFragCoord` and `uDrops` in a code comment, and confirm it with the one-drop row of the device checklist.
E4. It is off under Reduce Motion, Reduce Transparency (`mm/platform` `a11y.reduceTransparency`), Solid glass, and cinema mode with the chrome hidden. It stops when all reader glass is hidden and restarts when the chrome returns. It is off in the background. Other scenes add nothing to the glass.

### F. Guided view (§9.4.3, §11, §13 row 18)

Put the pure geometry in `mobile/lib/skins/glass/ambient/guided.dart` (with `guided_test.dart`). The view is `ambient/guided_view.dart`, rendered in the reader's single `Overlay` entry: the one `mobile/35` built for the dialogue boxes and the hit lens.

F1. **Data.**
   - The engine's `panelBoxes` for the current page: `{x, y, w, h}` page fractions in reading order, or `null`.
   - The manifest's `pages[].panels` are used first.
   - Detection runs in the shared `compute()` isolate one page ahead (built in `mobile/23`).
   - The engine posts `POST /reader/panels` on chapter exit. That is already its duty; do not add a second post.
   - Downloaded chapters use their stored panels or analyse local blobs.
F2. **Entry.** Any of these opens guided view:
   - the page menu (long-press a page, 450 ms) item "Guided view";
   - reader settings → Ambient → Guided view;
   - `shift+p` on a hardware keyboard;
   - the landscape ⋯ item "Guided view";
   - the `panel-focus` icon button (44 pt; 48 dp on Android), which joins the top-right glass group as one more sibling shape whenever `panelBoxes` is non-null for the current page and is absent otherwise.

   With the profile's "Guided view on by default for chapters with panels" on, a chapter whose first page has panels opens in guided view.
F3. **Camera.** `frameRect(panel, viewport, padding: 24, maxScale: 3)` fits the panel to the viewport minus 24 px on every side (width or height, whichever binds) and never scales above 3×.
   - The engine's `setCamera(rect, springCamera, velocity)` moves the page layer (`SpringDescription` k 195.0, c 25.13, settle 392 ms), carries the swipe's velocity (§4.3: `controller.animateWith(SpringSimulation(…, velocityInUnits))`) and crosses page boundaries continuously.
   - Everything outside the panel frame is dimmed to `#000000` at 85 % by one `CustomPaint`: a full-viewport path with the lens rect cut out (`PathFillType.evenOdd`), under the lens.
F4. **The lens.**
   - One `SkinGlass(tier: T2)` (a fixed-size lens keeps T2, §2.4.3), radius 14, with a 2 px specular rim, at the framed panel's viewport rect.
   - It is the one glass surface of the overlay layer, taking the "overlay lens" slot of §15.7.
   - Its rect animates with the camera on the same spring. `Lb` for the lens is the maximum of `pTop`, `pMid` and `pBottom` over the bands it overlaps.
   - **The refracted sliver** (§9.4.3): on the liquid engine the lens's own bezel refraction samples the dimmed art beyond its rim, so the next panel shows as a refracted sliver of colour before the camera arrives. If the `mobile/03` gate record chose the `BackdropFilter` frost fallback, there is no sliver; say so in the report.
   - Check the sliver on a real chapter in the device checklist and in the proof.
F5. **Moving.**
   - A horizontal drag, direction-locked when `abs(dx) > 2 × abs(dy)` after the 10 px slop, commits at ≥ 50 px or ≥ 500 px/s. It is mirrored for right-to-left series.
   - A tap on the right 30 % band moves to the next panel and on the left 30 % band to the previous one, mirrored for RTL. Side taps act at once and never open a double-tap window.
   - Hardware keys: `→` / `←` (following the visual direction), `j` / Space (next), `k` / Shift+Space (previous).
   - `panel.step` (`soft(0.3)`) fires per panel.
   - Panels taller than the viewport minus padding are walked in steps of 80 % of the viewport height before moving on (`walkSteps`).
   - The centre 40 % band has no single-tap action and never toggles chrome.
   - Gesture plumbing: one `RawGestureDetector` with a `ScaleGestureRecognizer`. A one-pointer update is the pan, with the direction lock above; a two-pointer update is the pinch. Taps go through the engine's tap classifier with `thresholdDoubleTapWindow` 280 ms and `thresholdDoubleTapSlop` 24 px, so single taps are never delayed.
F6. **Past the last panel** of the chapter: a further next rubber-bands the camera (`rubberband(x, d, 0.35)`, `physicsRubberBandChapterC`). At 48 displayed px, `chapter.arm` (`soft(0.5)`) fires and the §8.14.4 next-chapter card rises. At 72 displayed px, or on a second next press, or on the card's "Read next", `chapter.next` (`rigid(0.8)`) commits and the next chapter opens on its first panel. Before the first panel, the same rule offers the previous chapter.
F7. **Counter pill.**
   - A `SkinGlass(tier: T3)` (`glassRegular`) at the bottom capsule's position, `max(inset.bottom, MediaQuery.systemGestureInsetsOf(context).bottom) + 16` from the bottom (§8.14.11). The bottom capsule dematerialises while guided view is open, and the pill takes its layer slot.
   - Text in `subhead` `onGlass`: "Panel 4 of 38 · Page 7" when every page of the chapter has a panel result, otherwise "Panel 4 · Page 7".
   - An overview button: the Phosphor `squaresFour` glyph at 20, a 44 pt hit, `Semantics(button: true, label: "Show the whole page")`.
   - A close ×, 44 pt hit, labelled "Close guided view".
   - Each step is announced politely: `SemanticsService.sendAnnouncement(View.of(context), "Panel 4 of 38, page 7", TextDirection.ltr, assertiveness: Assertiveness.polite)`.
   - While the current page is being analysed the pill reads "Finding panels…" and the page is framed whole.
   - With no panels it reads "Page 7 · whole page", the page is framed whole, and next moves to the next page.
F8. **Double tap** in the centre band only: the whole page for 1.5 s (a zoom out on `springCamera`), then back to the panel.
F9. **Overview.**
   - Opened by a pinch out below 1× or the overview button.
   - The whole page fits the viewport. Every panel is outlined 2 px `iris400` at radius 6 and numbered in a `fill2` twin chip (`caption1` 600 `label1`, 24 px tall, 44 pt hit) at its top-left. The chips are twins because the overlay carries one glass surface only (§2.4.1).
   - A tap on a panel or its chip, or Enter on a focused chip, flies the camera to that panel on `springCamera`.
   - A pinch in, the overview button or Esc returns to the current panel.
   - A pinch in above 1× in panel mode rubber-bands ±0.18 and fires `zoom.limit` (`soft(0.4)`).
F10. **Exit.** Each of these returns to the strip (or the paged layout) with the current panel's top at the top content inset (`inset.top + 60` on phones):
   - a downward drag whose projection `project(dy, vy)` passes 120 px;
   - the pill's ×;
   - Esc on a hardware keyboard (inner-first order: overview → guided view → the reader's own chain);
   - Android back (the back-order row 7: a `PopScope(canPop: false)` bound to guided view, so no predictive preview shows);
   - `shift+p`;
   - the `panel-focus` button.
F11. **Chrome in guided view.** The top groups stay as they are and follow the reader's own chrome rules. The centre band never toggles them.
F12. **Reduce Motion** (§4.10 Panel camera, §14.10). Every camera move is a cut with a 120 ms cross-fade of the page layer. There is no glide, so no sliver. The whole-page glance and the overview also cut.
F13. **Offline:** guided view works from the saved copy (stored panels, or local blobs analysed on the device).
F14. **Semantics.** The overlay is one `Semantics(container: true, label: "Guided view")`. The counter's live text is `Semantics(liveRegion: true)`. The side bands expose `onIncrease` and `onDecrease` custom semantics ("Next panel", "Previous panel") so VoiceOver and TalkBack users step without gestures.
F15. **Tests** in `guided_test.dart`:
   - `frameRect` for a wide panel (width-bound), a tall panel (height-bound) and a tiny panel (clamped at 3×);
   - `walkSteps(H, V)` returns `[0]` when `H ≤ V`; otherwise the stops `k × 0.8 V` for every integer `k ≥ 0` with `k × 0.8 V < H − V`, then `H − V` (bottom-aligned). A panel 2.5 viewports tall gives `[0, 0.8, 1.5]` viewports and a panel 0.9 viewports tall gives `[0]`;
   - `nextPanel` crosses from the last panel of page 3 to the first of page 4, and mirrors for RTL;
   - `swipeCommits(49, 100)` is false, while `swipeCommits(50, 0)` and `swipeCommits(10, 500)` are true;
   - `exitByProjection(60, 150)` is true (60 + 0.499 × 150 = 134.9 > 120).

   Widget tests in `guided_view_test.dart` use a fake engine whose `panelBoxes` are the `brand/demo/demo.json` boxes of one demo page:
   - `shift+p` frames panel 1;
   - `→` steps to panel 2 and an announcement containing "Panel 2" is sent (capture `SystemChannels.accessibility` with a mock message handler);
   - a 60 px horizontal drag steps;
   - a centre tap does nothing;
   - a centre double tap shows the whole page and returns after 1.5 s;
   - the overview shows the numbered chips;
   - Esc leaves;
   - a page with `panelBoxes: null` reads "Page 2 · whole page";
   - with `disableAnimations: true` a step completes within 150 ms of fake time.

### G. Page-tinted chrome, exact in both readers (§9.4.4, §2.1.7, §3.5, §8.14.11)

`mobile/35` wired a first version into the manga chrome. This step makes every bullet of §9.4.4 exact:
- in the manga reader (strip, paged, read-all, guided view);
- in the novel reader;
- in the listen full player.

Put the pure rules in `mobile/lib/skins/glass/ambient/page_tint.dart` (with `page_tint_test.dart`). They are applied by `ambient/page_tint_controller.dart`, which provides one `ReaderTint` (tint, rim, top, bottom, per-group `Lb`) to the chrome through an `InheritedWidget` or a provider. Reuse what `mobile/35` built instead of adding a second path (`grep -rn "pageTint\|ReaderTint\|currentPageSample" mobile/lib/skins/glass`).

G1. **Source.** The engine's `currentPageSample`: the page under the reading line, 38 % down in the strip; the visible page in paged modes; the current page in guided view. It updates at most every 600 ms and is cached per page URL by the engine. Before the first sample, use the manifest's `pages[].tint` for that page (the engine's base `pageTint` field).
G2. **Clamp** in OKLCH, reusing the existing OKLCH helpers:
   - `clampTint(color)` → lightness 0.35–0.50, chroma ≤ 0.12, hue kept.
   - `rimTint(color)` → L 0.86, C ≤ 0.08.
G3. **Where the tint goes**, exactly:
   - Inside every reader `SkinGlass`, a tint layer of the clamped tint at **18 %** alpha, between the `dimLegibility` layer and the tier fill. Add a `tint` parameter to `SkinGlass` unless `mobile/35` already did.
   - The specular rim's first stop mixes the rim tint at **22 %**, in place of the ambient rim's 18 %.
   - The reader's `edgeSoft` scrims take the clamped tint mixed at **30 %** into `#000000` as their colour at the plateau's alpha.
   - The minimised pill's inner glow is a 12 px blurred inset glow of the tint at **30 %**.
   - The 2 px micro-progress line of cinema mode fills with the rim tint.
   - In the tablet-landscape desktop frame, the side panels' 0.5 px rims mix the rim tint at 22 %.
   - Every colour change runs through one `TweenAnimationBuilder<Color?>` per value (`ColorTween`) over `curveTintShift` (900 ms `Cubic(0.2, 0, 0, 1)`).
G4. **When it changes.**
   - A new tint is applied only when its OKLab distance to the current one exceeds 0.04 (`deltaE`).
   - It never changes while `abs(scrollVelocity) > 3000` px/s; it is applied when the fling settles.
   - A greyscale sample (`tint == null`) keeps the previous tint. After 6 greyscale pages in a row, the tint becomes the series cover palette's `a[0]` through the same clamp.
G5. **Legibility, per chrome group.**
   - The top groups use `pTop`. The bottom capsule and the minimised pill use `pBottom`.
   - Every other surface over a page uses the maximum over the bands its rect overlaps. That covers the page menu, the go-to popover, the next-chapter card, the cruise HUD, the "Previously" pill, the "Match" capsule, the seam chip, the zoom chip, the loading capsule, the reader settings sheet, the guided-view lens and the counter.
   - `dim = dimFor(Lb)`, which is `clamp(0.22 + 0.42 × Lb, 0.22, 0.64)`; under Increase Contrast the floor is 0.40 and the ceiling 0.72. `GRAD = round(40 × Lb)` goes through `GlassTextAxes`. Both animate over `curveDimShift` (400 ms), and both are held during flings above 3000 px/s.
   - So a capsule over a white panel darkens and thickens its labels while the other group stays clear.
G6. **Desktop-frame page-lit gutters** (§8.14.11). In the tablet-landscape desktop frame with both side panels closed, the gutters are `#060608` wells with two pools: the sample's `top` colour in the top half and its `bottom` colour in the bottom half, at 10 % opacity, as two `RadialGradient`s in one `CustomPaint` per gutter, each centred in its half with a radius of the gutter width + 120 px, fading from the colour at 10 % to transparent (no live blur). They cross-fade over `curveTintShift` and never touch the art. With Page-tinted chrome off, Reduce Transparency or Solid glass, the gutters are plain `#000000`.
G7. **Novel reader.** The chrome's tint is the paper's ink at 12 % (the tint layer; the rim tint is `rimTint(ink)`), and `Lb` is the paper's fixed luminance (§8.15.1). The **listen full player** takes the narrating voice's hue (the hue `mobile/37` uses for the speaking orb) through `clampTint` at 18 %, changing over `curveTintShift` when the narrator changes.
G8. **The switch.** Reader settings → Ambient → Page-tinted chrome (manga) and the Aa sheet's Ambient group (novel): the one per-profile value `glass.pageTinted` (`mobile/35`), default on.
   - Off: neutral glass (the tint layers are transparent), but the dim still adapts.
   - Reduce Transparency and Solid glass: the tint stays only on the solid chrome's 1 px rim, mixed at 22 %.
G9. **Reduce Motion:** tint and gutter changes cross-fade over 200 ms linear (§4.11 colour transitions), and the dim changes instantly.
G10. **Tests** in `page_tint_test.dart`:
   - `clampTint(Color(0xFFFF0000))` has L within 0.35–0.50 and C ≤ 0.12;
   - `rimTint` gives L 0.86 ± 0.005;
   - `deltaE` of identical colours is 0, and of `#123456` against `#123457` is below 0.04;
   - `shouldApply` is false at 3500 px/s and true at 1000 px/s when ΔE > 0.04;
   - five greyscale samples keep the previous tint, and the sixth returns the cover's `a[0]` (clamped);
   - `dimFor(1.0) == 0.64` and `dimFor(0) == 0.22`, and under Increase Contrast `0.72` and `0.40`;
   - the novel tint for Void ink `#D9D6D0` is the ink at 12 %.

   In widget tests with a fake engine state:
   - over a sample with `pTop = 1.0` the top group's dim settles at 0.64 and its `GlassTextAxes.grad` at 40;
   - over `pTop = 0.1` they settle at 0.262 and 4;
   - a sample during a fake 4000 px/s fling changes nothing until the velocity drops.

### H. Settings wiring (§8.25.3 Ambient, §8.25.5)

Confirm that the Reader defaults Ambient group (`/settings/ambient`, from `mobile/39`) reads and writes the keys of A2:
- "Page-tinted chrome";
- "Cruise default speed" (Slider 0.25–4.00, step 0.05, magnet 1.0×);
- "Guided view on by default for chapters with panels";
- the row "Soundscape defaults" leading to Sound and haptics.

Also confirm that the Sound & haptics page (`/settings/feedback`) writes `mm.soundscape.defaults` from its scene radio group, Match the story, the Bed · Detail · Tone mix, the volume and Lower under narration. Fix whatever is a stub. Every caption says "Saved on this device."

### I. Flutter checks (`mobile/test/skins/glass/ambient/`, `mobile/test/skins/glass/soundscape/`)

Beyond the unit tests above, write these widget tests over the Glass reader screens, with fake engine, repositories and `FakeSoundscapeAudio`:

1. **Cruise:**
   - a tap starts the engine with `rampMs: 400`;
   - dragging the pill up 80 px raises the value by 0.50×;
   - a drag ending at a raw 1.07 shows and applies 1.0 (magnet), while one ending at 1.09 shows 1.1;
   - `>` then `<` returns to the start value;
   - a touch then release resumes 800 ms after the momentum falls below 15 px/s;
   - a fake fling decaying through 240 px/s calls `engageFromVelocity` once;
   - with `disableAnimations: true`, the start has `rampMs: 0`, a touch does not resume on its own, and a fling never engages;
   - `cruiseSpeed` is in the per-series map after the drag ends;
   - in Single layout the button is absent;
   - at `TextScaler.linear(1.4)` the button is absent from the capsule and present as the first row of the settings sheet.
2. **Soundscape:**
   - `shift+s` opens `?sheet=soundscape`;
   - choosing Rain moves the controller to `starting` and the fake records `loadMem` plus looping `play` calls;
   - with every file fetch failing, the state is `playingBuiltin` after 2 s and the orb carries `cloud-slash`;
   - with a fake file for each layer, the state reaches `playingRecorded` after the 2 s cross-fade (`fadeVolume` to the layer value on the recorded voice and to 0 on the procedural one);
   - narration starting ducks every voice to its value × 0.251 over 400 ms, and with Lower under narration off the voices are paused instead;
   - the music check returning true starts in `muted` with the toast;
   - `AppLifecycleState.paused` fades and pauses, and `resumed` resumes;
   - disposing the provider container stops and disposes every voice;
   - the Aa badge label changes in the novel reader;
   - the orbs are one mutually exclusive semantics group.
3. **Rain:** the Rain scene with visible chrome registers one extra layer (read through `SkinGlass`'s registry). No rain is registered with `disableAnimations: true`, with Solid glass, with a non-Rain scene, or with the chrome hidden. In the test environment `ImageFilter.isShaderFilterSupported` may be false; then assert only the registry and the simulation, and leave the pixels to the device checklist.
4. **Guided view:** the `guided_view_test.dart` cases of F15.
5. **Page tint:** the widget cases of G10.
6. **Budget** (§15.7, `SkinGlass` registry). In the manga reader with the reader settings sheet open, guided view on, the seam chip showing and Rain playing, the registry reports ≤ 6 layers and ≤ 8 shapes, and never more than two stacked layers over one point. In the novel reader with the listen row, a speaker chip, the Aa sheet and Rain: ≤ 5 layers (the table's 4 plus rain) and ≤ 6 shapes. No glass sits inside the strip or the novel column.
7. **18+:** with a mature series open, cruise running and Rain playing, running `purgeMatureLocal` stops both before the next pump.
8. **Keyboard:** with a hardware keyboard simulated (`tester.sendKeyEvent`), every new control is reachable by Tab with the Glass focus ring (`FocusRingSpec`) painted outside its clip. With "Single-key shortcuts" off, `p`, `a`, `<`, `>`, `shift+s` and `shift+p` do nothing, while arrows, Space and Esc still work in guided view.
9. **Targets:** `expect(tester, meetsGuideline(iOSTapTargetGuideline))` with `TargetPlatform.iOS`, and `androidTapTargetGuideline` with `TargetPlatform.android`, on the reader with the pill, the sheet, the guided-view counter and the overview. Also `meetsGuideline(labeledTapTargetGuideline)`.

## Out of scope here (do not build)

- The web side (`web/44`), any backend change, new recordings (the owner drops them; `shared/03`'s `design/sounds/trim-loop.mjs` prepares them), and the Cinematic skin. Its auto-scroll chip, loops, dolly and tint are `mobile/23`'s and must not change.
- The QA sweep of the whole skin (`mobile/45`).
- Any new package. Gradle or Xcode on this box.

## File layout

```
mobile/pubspec.yaml                                               E1: the flutter: shaders: entry only
mobile/lib/features/reader/models/reader_prefs.dart (+ test)      A1 cruiseSpeed and soundscape (only if missing)
mobile/lib/features/reader/engine/<auto-scroll file> (+ test)     A3 rampMs (only if missing)
mobile/lib/features/novels/utils/novel_auto_scroll.dart (+ test)  A4 (only if features/novels has none)
mobile/lib/features/reader/services/soundscape_files.dart (+ test) A5 (unless mobile/23 made a shared one)
mobile/lib/skins/glass/
├── skin_glass.dart                                               G3 tint parameter (only if missing)
├── shaders/rain_on_glass.frag                                    E1
├── ambient/
│   ├── cruise.dart, cruise_controller.dart, cruise_pill.dart     B
│   ├── rain_on_glass.dart                                        E2, E3
│   ├── guided.dart, guided_view.dart                             F
│   └── page_tint.dart, page_tint_controller.dart                 G (the gutters paint lives in page_tint_controller.dart)
├── soundscape/
│   ├── recipes.dart, generator.dart, mixer.dart                  C
│   ├── soundscape_controller.dart                                C (A2 reads mobile/39's soundscape_defaults_provider.dart)
│   ├── soundscape_sheet.dart, scene_orb.dart                     D
└── screens/<reader, novel, listen, settings folders>             wiring: capsules, top-right group, page menu, keys, ⋯ menus,
                                                                  right panel, Aa Ambient group and badge, player ⋯, settings rows
mobile/test/skins/glass/ambient/*_test.dart                       B, E, F, G, I
mobile/test/skins/glass/soundscape/*_test.dart                    A2, C, D, I
mobile/test/screenshots/marketing_screenshots_test.dart           the mobile-44 group (proof)
docs/redesign/proof/mobile-44/                                    plan.md, screenshots, device-checklist.md, report.md
```

Skin files import only `features/*/{models,providers,repositories,services,store,queue,utils,controllers,engine}`, `core/`, `shared/` and their own `skins/glass/**`. `test/skins/import_boundary_test.dart` fails on anything else, including any `skins/cinematic/` import.

## Parity with the web twin

These values must be identical on both clients; list any difference in the report:
- the speed model (60 px/s × m, 0.25–4.00, 8 px per 0.05×, ticks every 0.25×, the 400 ms linear ramp, the 800 ms resume, the 240 px/s engage);
- the six recipes, `matchScene`, the fades (3 s in, 1.5 s out, 2 s recorded, 400 ms duck by 12 dB);
- `frameRect`, `walkSteps`, the swipe commit (50 px or 500 px/s) and the exit projection (120 px);
- `clampTint`, `rimTint`, the ΔE 0.04 and 3000 px/s rules, and the 18 / 22 / 30 % mixes.

This file follows `glass/DESIGN.md` on two points where the web twin's prompt reads differently. If `web/44` built them otherwise, name both in the report as open parity issues:
1. The cruise magnet is ±0.08× (§4.6, §2.8.5 `physicsValueMagnetSpeed`) with no extra hysteresis.
2. Scene names and "Matched: …" on the T4 sheet body are `onGlass` (§2.1.2 mapping), while the orb glyph patterns stay `label2` (§9.4.2).

## Acceptance criteria

- [ ] `cruise_test.dart`, `recipes_test.dart`, `generator_test.dart`, `scheduler_test.dart`, `guided_test.dart`, `page_tint_test.dart`, `rain_on_glass_test.dart`, the soundscape-defaults clamping cases (A2) and the `reader_prefs` and ramp cases pass with every value listed in A1, A3, B1, C4, E2, F15 and G10.
- [ ] Cruise:
  - a tap ramps from 0 to speed over 400 ms;
  - the pill is 44 pt tall inside the bottom capsule's layer, with a disc turning `m` times per second and `m` in `mono`;
  - a vertical drag changes speed at 8 px per 0.05×, ticks every 0.25×, snaps to 1.0× within ±0.08×, and shows the T2 HUD;
  - the trailing-edge drag changes speed while cruising;
  - a forward fling engages at the coasting speed and saves it;
  - a touch pauses and resumes after 800 ms;
  - `p` / `a`, `<`, `>` and the semantics increase and decrease actions work;
  - `cruiseSpeed` persists per series per profile;
  - the button is absent in Single and Double layouts and moves into the settings sheet at text scale > 1.3;
  - the landscape pill sits above the rail's trailing end.
- [ ] Keep awake follows §8.14.5 exactly: held while cruise runs or guided view is open, released 2 s after both stop when the switch is off, and on leaving the reader and on `paused`.
- [ ] Reduce Motion (the OS setting and the in-app switch):
  - cruise has no ramp, never resumes or engages on its own, and the disc is static;
  - scene glyphs and level bars are still;
  - rain is off;
  - guided view cuts with a 120 ms cross-fade and has no sliver;
  - tint changes cross-fade over 200 ms and the dim changes instantly.
- [ ] Soundscape:
  - a scene starts at once from the generator's WAV bytes (`loadMem`), which are cached on disk after the first render;
  - recorded `.ogg` layers from `/app/soundscapes/glass-{scene}-{layer}.ogg` cross-fade in over 2 s when fetched or cached in the app support directory;
  - the built-in state shows `cloud-slash`;
  - fades are 3 s in and 1.5 s out;
  - narration ducks it by 12 dB over 400 ms, or pauses it with Lower under narration off;
  - it follows the sleep timer, pauses when the reader is left or the app is backgrounded without narration, keeps playing ducked in the background with narration, and resumes on return;
  - another app's music starts it muted with the toast and its unmute action;
  - UI sounds stay silent while it plays;
  - `mm.soundscape.defaults` and the per-series `soundscape` record behave as §9.4.2 says (remembered beats Match the story, which beats the default);
  - the failure toast reads "Couldn't start the soundscape";
  - no voice survives a skin switch, a profile switch or a sign-out;
  - the audio session changes only through `skin_audio.dart`.
- [ ] The sheet:
  - is `?sheet=soundscape`: phone `medium`, landscape centred, the desktop frame's reader right panel Settings tab, the 440 px panel elsewhere;
  - has seven orbs in one mutually exclusive semantics group operable by hardware arrows, "Matched: …" under the matched orb, the mixer with 10 % ticks, and the three switches;
  - opens from every entry point (`shift+s`, both readers' Ambient rows, the player ⋯, the landscape novel ⋯, Settings);
  - the novel Aa badge and its label change while a scene plays.
- [ ] Rain on glass runs only with the Rain scene and visible reader glass, through `BackdropFilter(ImageFilter.shader)` clipped to each capsule, on Impeller only. It counts as one extra layer, and is off under Reduce Motion, Reduce Transparency, Solid glass and in the background.
- [ ] Guided view:
  - every entry point works;
  - the camera frames each panel with 24 px padding up to 3× on `springCamera`, carrying the swipe velocity and crossing pages;
  - the dim is `#000` at 85 %;
  - the T2 lens (radius 14, 2 px rim) is the overlay's one glass surface and shows the refracted sliver on the liquid engine;
  - tall panels walk in 80 % steps;
  - the counter pill reads as specified in every state and announces each step politely;
  - a centre double tap shows the page for 1.5 s;
  - pinch-out and the overview button show numbered outlines;
  - exit by swipe-down projection past 120 px, ×, Esc, Android back, `shift+p` or the glyph returns to the panel's position;
  - past the last panel the chapter card arms at 48 and commits at 72.
- [ ] Page-tinted chrome:
  - follows `currentPageSample` (manifest tint first), clamped to L 0.35–0.50 and C ≤ 0.12;
  - appears at 18 % inside every reader glass surface, 22 % in rims, and 30 % in soft edges and the pill glow, plus on the micro-progress line and the desktop-frame panel rims;
  - changes only above ΔE 0.04 and never during flings above 3000 px/s;
  - greyscale pages keep the tint, falling back to the cover's `a[0]` after 6 pages;
  - each chrome group's dim and `GRAD` follow its own band;
  - the desktop-frame gutters glow at 10 %;
  - the novel chrome takes the paper ink at 12 % and the listen player the narrator's hue;
  - the switch and Reduce Transparency behave as G8.
- [ ] Budget: never more than 6 layers and 8 shapes in the moments of I6 (rain included), never more than two stacked layers, and no glass in the strip or the novel column.
- [ ] Keyboard and targets: every new control is reachable by Tab with the unclipped Glass focus ring and operable by Enter or Space (orbs also by arrows). Every hit area is at least 44 × 44 pt on iOS and 48 × 48 dp on Android, with 8 px between hit areas unless they are cells of one glass group. Single-key shortcuts obey the Shortcuts switch.
- [ ] 18+ and session: closing the gate with a mature series open stops cruise and the soundscape before the next frame, and so do sign-out, profile loss and a profile switch.
- [ ] Per-skin difference: `git diff --stat` over this step's commits shows nothing under `mobile/lib/skins/cinematic/`. The Cinematic reader's auto-scroll chip and soundscape behave as before (its tests are green, and the before and after harness captures match).
- [ ] Glass `PENDING` is unchanged (no `ScreenId` added), and the completeness and import-boundary tests pass.
- [ ] `flutter analyze` reports "No issues found". `flutter test` passes at or above the floor plus the new tests. `node design/build.mjs --check` passes. After the push, the CI Flutter job (analyze, test, the release APK build) and the iOS dry run are green, which proves the shader compiles for both platforms.

## Verification

**RAM guard (production shares this box, and `web/44` runs in parallel).** Before every heavy command (`flutter analyze`, `flutter test`, the harness, `npm run build`), run `free -m` and read the `available` column of the `Mem:` row. If it is under 1024 MB, stop and report instead of running it. Run one heavy command at a time. If `pgrep -fa "next build|flutter_tester"` shows another heavy command running, wait until it exits (check again every minute) before starting yours. Never run Gradle or Xcode on this box; CI builds the APK and runs the iOS dry run.

From `mobile/`:

```bash
free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze
free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter test test/skins/glass test/features/reader test/features/novels test/skins/import_boundary_test.dart test/skins/completeness_test.dart
free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter test
cd .. && node design/build.mjs --check && cd mobile
```

`flutter analyze` must report "No issues found", and the full suite must pass at or above the floor plus the new tests. This step changes nothing in `frontend/` or `backend/` (check each of your own commits with `git show --stat --format= <hash>`: none lists a path under `frontend/` or `backend/`; a branch or range diff would also show the commits of the web twin and the other sessions working on this branch). So `npm run lint` and `npm run build` (in `frontend/`) and the backend pytest (`backend/.venv/bin/python -m pytest -q --no-header` from `backend/`) are not rerun, except under the push rule in Git. Every test that passed in the baseline must still pass, apart from the legacy widget tests `release/00` deleted by design.

**Visual proof.** In the screenshot harness (`mobile/test/screenshots/marketing_screenshots_test.dart`), add a `mobile-44` group over the demo pages `brand/demo/pages/*.webp` with the panel boxes of `brand/demo/demo.json`, captured through the `mobile/03` harness API (`support/skin_shots.dart`: `captureSkinWidget` for the reader states and open sheets, with the fakes of `support/shot_harness.dart`). Use fake engine states for the page samples: one dark page, one white page, one colourful page and one greyscale page. Run from `mobile/` `free -m && MM_PROOF_DIR=../docs/redesign/proof/mobile-44 /srv/manhwamaniacs/dev/flutter/bin/flutter test test/screenshots/marketing_screenshots_test.dart --plain-name "mobile-44"` at phone 390 × 844 (`kSkinShotSizes.first`, DPR 3), `kSkinShotLandscape` (844 × 390) and `kSkinShotTabletWide` (1024 × 1366: width ≥ 1024, so §8.0.1's desktop frame with the reader's side panels and gutters), writing into `docs/redesign/proof/mobile-44/`. The harness appends the size to each name (`-phone`, `-landscape`, `-tablet-wide`); a name below ending in `-desktop` is written as `-tablet-wide`. Never set `MM_WRITE_SHOTS` (it overwrites the install page's public screenshots in `mobile/docs/screenshots/`); `git status --short mobile/docs/screenshots` must print nothing afterwards:

- `cruise-pill-phone.png` (running at 1.0×), `cruise-hud-phone.png` (dragging at 1.5×), `cruise-landscape.png` (pill above the rail), `cruise-textscale-1.4-phone.png` (the Cruise row in the sheet);
- `soundscape-sheet-phone.png` (Rain playing, level bars, mixer), `soundscape-sheet-landscape.png`, `soundscape-panel-desktop.png`, `soundscape-builtin-phone.png` (`cloud-slash`), `novel-aa-badge-phone.png`;
- `rain-phone.png` (the rain widget in place; say in the report whether the shader rendered in the harness);
- `guided-phone.png`, `guided-sliver-phone.png` (mid-glide), `guided-finding-phone.png`, `guided-whole-page-phone.png`, `guided-overview-phone.png`;
- `tint-{dark,white,colour,grey}-page-phone.png`, `tint-off-phone.png`, `tint-solid-phone.png`, `gutters-desktop.png`, `novel-tint-{void,night-paper}-phone.png`, `listen-player-tint-phone.png`;
- `cinematic-reader-{before,after}-phone.png`, from the Cinematic group at the start and the end of this step.

Use only the demo art, never real series art. Compare the phone captures with `docs/redesign/proof/web-44/*-phone.png` when they exist, and list the differences in the report.

**Device checklist.** Write `docs/redesign/proof/mobile-44/device-checklist.md` for the owner. Glass is reachable only through Settings → Diagnostics → the debug row (`Edition (debug)` CINEMATIC | GLASS). The iPhone installs the CI IPA through SideStore, and the Android flagship installs the CI APK. Each row gives exact steps and a pass condition, read from Diagnostics → Rendering performance and "Show motion timings":
- cruise at 120 Hz on a 120-page, 2,880 px demo webtoon: mean FPS ≥ 114, jank < 5 %, no `danger` row for **Cruise ramp**;
- flick to cruise engaging at a gentle and a hard flick;
- the pill drag and its magnet click;
- each of the six scenes sounding as named, with the time to first audio recorded;
- a recorded layer cross-fading in (once the owner has dropped files);
- narration ducking the scene, and Lower under narration off pausing it;
- Spotify or Apple Music playing before a scene starts gives the muted toast;
- background with and without narration, and the lock screen;
- a phone call interrupting;
- Rain on glass on both phones (droplets refracting a white page; Diagnostics' layer row goes up by one);
- guided view's sliver at 120 Hz with no `danger` row for **Panel camera**;
- page tint over the white demo panels;
- landscape on both phones;
- the Android exclusion rect: the rail drag while cruising never triggers system back.

Write `docs/redesign/proof/mobile-44/report.md` mapping each screenshot and each test to the acceptance item it proves.

## Git

- Branch `feat/vps-slim-source-native`. Commit small and often, one working step per commit:
  1. the preference fields;
  2. the engine ramp (if needed);
  3. novel auto-scroll (if needed);
  4. the soundscape file cache;
  5. cruise maths with its test;
  6. the pill, HUD and wiring;
  7. the recipes and generator with their tests;
  8. the mixer and controller;
  9. the sheet and orbs;
  10. entry points and settings wiring;
  11. the rain shader and simulation (the `pubspec.yaml` shaders entry in this commit, alone with the shader);
  12. guided-view geometry with its test;
  13. the guided view;
  14. page-tint rules with their test;
  15. the tint wiring in each reader;
  16. the proof.
- Stage your paths explicitly (`git add mobile/lib/skins/glass/ambient …`), never `git add -A` or `git add .`, because the web, backend and shared sessions commit in the same checkout.
- Use conventional messages (`feat(mobile-glass): flywheel cruise pill with flick-to-cruise`). No Claude or AI attribution anywhere: no `Co-Authored-By` line, no "Generated with" line, no AI author. Never commit secrets or `.claude/`.
- Before every push: `git fetch origin` and `git diff --stat origin/feat/vps-slim-source-native...HEAD -- frontend`. If it lists files, run `free -m && npm run build` in `frontend/` first (never while `flutter test` runs) and push only if it passes. Then run `git push origin feat/vps-slim-source-native` after each working step.
- After pushing the shader commit, confirm that CI's Flutter job (including the release APK build) and the iOS dry run are green for that SHA. Use `gh run list --branch feat/vps-slim-source-native --limit 5` if `gh` exists. Otherwise make at most one anonymous `curl -s "https://api.github.com/repos/yash-dhanda/ManhwaManiacs/actions/runs?branch=feat/vps-slim-source-native&per_page=5" | jq '.workflow_runs[] | {name, head_sha, status, conclusion}'` every 5 minutes, never in a tight loop.
- Never edit `backend/connectors/`. Never touch production containers or `/srv/manhwamaniacs/{app,data}`. Do not deploy anything: Glass stays behind the debug row until `release/01`.

## Report back

Reply with:

1. Done items by section (A to I), and anything not done with the reason.
2. Engine or data-layer work you had to add (A3, A4, A5, or a missing `mobile/34` field), with its commits and the reader-suite result.
3. Which of the 18 recorded layers exist (the precondition list), whether `readSamplesFromFile` exists in 4.1.7 (C7), and how the music check was wired on iOS (C11).
4. The proof folder `docs/redesign/proof/mobile-44/` and its file list, whether the rain shader rendered in the harness, and the differences from the web twin's phone captures.
5. Test counts (`flutter test` passed before and after), the `flutter analyze` result, `build.mjs --check`, the CI run URLs or conclusions for the shader commit, and the `free -m` available figure before each heavy command.
6. Parity differences from `web/44` (the "Parity with the web twin" list), and any deviation from `glass/DESIGN.md` with its section.
7. The device checklist path and the rows that need the owner.
8. Open issues, each with its section.

Next prompt file: `docs/redesign/prompts/mobile/45-glass-qa-polish.md` (`docs/redesign/prompts/web/45-glass-qa-polish.md` runs in parallel).
