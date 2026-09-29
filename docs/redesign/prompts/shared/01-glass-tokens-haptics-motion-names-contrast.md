# Shared 01: Glass tokens, haptic patterns, motion names and the contrast gate

## Goal

Add the Glass ("Meniscus") skin to the single design source that `shared/00` created, and finish the generator's three companions. You will write `design/tokens/glass.json` with every Glass token (colour including the mood and paper sets and the avatar glyph colours, space and layout lengths, radius, blur, borders, the light angle, layers, the five glass tiers and the clear, tinted, solid and material finishes, the legibility dim and the `edgeSoft` values, the tier snap, the caustic, twenty physical springs, the timed curves, physics constants, thresholds, eighteen type roles, haptics, AHAP patterns and sounds); extend `design/build.mjs` so Glass gets its CSS, TypeScript (physical Motion springs) and Dart (`GlassTokens`) outputs and its share of the shared Tailwind theme; write `design/build-haptics.mjs`, which turns both skins' AHAP patterns into `mobile/assets/haptics/{cinematic,glass}/*.ahap.json` and both skins' motion tables into generated name unions; and write `design/check-contrast.mjs`, the CI gate that composites every declared text/ground pair of both skins and fails below WCAG thresholds. After this step `node design/build.mjs --check` regenerates everything, lints both skins' utilities and runs the contrast gate. Nothing in this step renders UI or is imported by app code yet.

## Read first

1. `docs/redesign/inventory/00-decisions.md` (all).
2. `docs/redesign/stack-decision.md` §2.1 (token format, outputs, CI check) and §2.3 (`skin_haptics.dart`, the Dart layout).
3. `docs/redesign/glass/DESIGN.md`:
   - the "Conventions used everywhere below" section (units, the `{ms, bounce}` spring format with `k = (2π / d)²`, `c = 4π(1 − bounce) / d`, breakpoints `frame` 768 / `desktop` 1024 / `wide` 1440, token naming, contrast);
   - §2.1 all of it (§2.1.2 text roles and the backing-disc rule and its exceptions, §2.1.3 Iris, §2.1.4 semantic, §2.1.5 speakers, §2.1.6 moods, §2.1.7 scrims, dims, the legibility floor and the worked 8.8:1 case, §2.1.8 the ambient field and its per-screen opacity table, §2.1.9 lights);
   - §2.3, §2.4 (layers, variants, §2.4.3 the thickness scale and the free-size snap `[36, 57, 97]`: `< 36` T1, `36–56` T2, `57–96` T3, `≥ 97` T4, T5 never reached by size), §2.5, §2.6;
   - §2.8 complete (§2.8.1 to §2.8.5: every key with its CSS, Tailwind and Flutter column, and the runtime-value paragraph at its end);
   - §3.1, §3.2, §3.3 (caps and the footnote floor), §3.5 (`ROND` and `GRAD` on glass; why `--glass-rond` and `--glass-grad` stay unregistered), §3.6 (Legible text), §3.7 (the type-role map);
   - §4.2 (springs with k, c, ζ, settle, overshoot), §4.3 (why the web uses physical springs), §4.6, §4.7, §4.8, §4.10 (the motion table: the 116 names), §4.11 (Reduce Motion, Reduce Transparency and Solid glass, Increase Contrast, forced colours);
   - §5 all (§5.1 primitives, §5.2 every event, §5.3 the AHAP signatures);
   - §6 (cues, levels, the event map);
   - §7.26 (the avatar presets and their glyph colours);
   - §15.1 (token source shape and generator outputs), §15.6 (cross-skin alignment), §15.8 (the contrast gate's full case list and the physics check values), §15.10 G1, G2, G8.
4. `docs/redesign/cinematic/DESIGN.md`: §2.1.1 (the `ink.45` rule and the raised and wash scopes), §2.1.4 (the over-art table), §2.1.6 (moods, stocks), §4.5 (the 38 motion names), §5 (the six AHAP patterns), §7.25 (avatar fields must carry `ink.100` at ≥ 4.5:1), §14.2 (contrast rules), §15.10 S2.
5. `docs/redesign/prompts/shared/00-design-contract-and-token-generator.md` and everything it produced: `design/contract.json`, `design/tokens/cinematic.json`, `design/build.mjs`, `design/lib/*.mjs`, `design/lint-utilities.mjs`, `design/test/*.test.mjs`, and the generated files under `frontend/src/skins/` and `mobile/lib/skins/`. Extend them; do not fork them.
6. `docs/redesign/00-baseline.md` (frontend lint and build green; `flutter analyze` clean; `flutter test` 2012 passed).
7. Inventory context only: `docs/redesign/inventory/mobile.md` "G12 Haptics vocabulary (current)" (what the app does today).

## Skills to invoke

- `superpowers:writing-plans` before coding.
- `superpowers:subagent-driven-development` to run the plan (or `superpowers:executing-plans` inline). Subagents each get one file group; verify against `git status`, not their report.
- `superpowers:test-driven-development` for the physical spring sampler, the compositing and contrast function, the AHAP writer and the motion-name converter: write the node:test vectors below first.
- `impeccable`: audit `frontend/src/skins/glass/tokens.generated.css` and the grown `theme.generated.css` against glass §2.8 and §3.7 before the generated-files commit.
- `taste-skill:taste-skill`: review the proof sheet `docs/redesign/proof/shared-01/glass-tokens.svg` only.
- `frontend-design`: not needed; no web UI in this step.
- `superpowers:verification-before-completion` before claiming done.

## Guardrails

- **Track rule.** The shared track owns `design/` and `brand/` plus the generated files they write into `frontend/`, `mobile/` and `backend/media/`. In this step you may create or change only `design/**`, the generated files listed in "File layout", and `docs/redesign/proof/shared-01/**`. Stage with explicit `git add <path>`; never `git add -A`, `git add .` or `git commit -a` (other sessions commit in the same checkout).
- Everything under `design/` stays Node 22 stdlib only. No `npm install`.
- Never edit `backend/connectors/`. Never touch production containers or `/srv/manhwamaniacs/{app,data}`.
- **RAM guard.** Run `free -m` before every heavy command (`npm run typecheck`, `npm run test`, `npm run build`, `flutter analyze`, `flutter test`); if `available` is under 1024 MB, stop and wait. Never run two at once. Never `flutter build`.
- **Git.** Branch `feat/vps-slim-source-native`; one commit per working step; `git push origin feat/vps-slim-source-native` after each. No Claude or AI attribution anywhere (no `Co-Authored-By`, no "Generated with" line), whatever a tool suggests. Never commit secrets or `.claude/`.

## Before you start (dependency: shared/00)

This step depends on `docs/redesign/prompts/shared/00-design-contract-and-token-generator.md`. From the repo root run `git log --oneline -15 -- design/` and `ls design/contract.json design/tokens/cinematic.json design/build.mjs design/lib/spring.mjs design/lint-utilities.mjs frontend/src/skins/theme.generated.css mobile/lib/skins/token_types.g.dart`, then `node design/build.mjs --check && node --test design/test/`. If a file is missing or either command fails, shared/00 is incomplete: stop and report which, do not repair it here.

## Scope: what this step delivers, item by item

### 1. `design/tokens/glass.json`

One schema: every key of glass §2.8 is a path in this file (glass §15.1). Dotted keys nest; `"_"` holds a parent's own value where needed. Copy values exactly from §2.8; the counts below come from its tables and are checked by `design/test/glass-tokens.test.mjs`.

- `"spring": { "format": "physical", … }` (glass §15.10 G1). The `format` key is generator configuration and emits no name.
- `color` (§2.8.1, 134 rows plus 12 glyph colours, 146 keys): the Graphite ramp `g0` to `g1000` (15), `surface1..3`, `label1..4`, `onGlass`, `onTint`, `fill1..4`, `twinDense`, `wellOnGlass`, `backingDisc` `rgba(0,0,0,0.60)`, `coverBacking` `rgba(0,0,0,0.86)`, `coverDisc` `rgba(0,0,0,0.72)` (the three backings §15.8 reads from this file), `separator`, `separatorOpaque`, `iris100..900`, `success`, `warning`, `danger`, `info`, `mature`, `streak`, `streakCore`, `bloom`, `bloomWash`, `bloomRim`, `machine`, `machineWash`, `machineRim`, `readerWarmth`, `brandFrost`, `spk1..10`, `mood.{romantic,action,comedy,horror,sliceOfLife,fantasy,default}`, `aurora1..3`, `heat0..4`, `dimSheet`, `dimModal`, `dimContext`, `dimClear`, `edgeHard`, `paper.{void,ink,nightPaper,dusk,moss,rosewood,glass}.{page,ink,muted}`, `avatar.<preset>.{from,to}` for the 12 presets (`violetSpark`, `cyanRocket`, `roseHeart`, `amberCoffee`, `emeraldCat`, `emberFlame`, `steelBlade`, `phantom`, `arcaneWand`, `lunarMoon`, `starlight`, `bookworm`) and `avatar.<preset>.glyph` from §7.26: `rgba(0,0,0,0.85)` for `starlight`, `amberCoffee`, `emberFlame`, `cyanRocket`, `emeraldCat`, `bookworm`, `steelBlade`; `#FFFFFF` for `violetSpark`, `roseHeart`, `phantom`, `arcaneWand`, `lunarMoon`.
- `font`: `sans` Google Sans Flex (axes `wght` 300–800, `opsz` 6–144, `ROND` 0–100, `GRAD` 0–100; CSS `--mm-font-sans`, Flutter `GoogleSansFlexMM`), `mono` Google Sans Code (`wght` 300–800; `--mm-font-mono`, `GoogleSansCodeMM`), `serif` Literata (`--mm-font-serif`, `LiterataMM`), `legible` Atkinson Hyperlegible Next (`--mm-font-legible`, `AtkinsonHyperlegibleNext`) (glass §3.1, §3.7).
- `space` (`s0` 0 to `s14` 96, 15 values incl. `s13` 85), `layout` (23 keys from `touchMin` 44 with `touchMinAndroid` 48 to `palette` 640; `readerStripMax` stores `{ "min": 480, "fraction": 0.5, "max": 900 }` and emits `clamp(480px, 50vw, 900px)` for CSS and three Dart fields; `measureMax` stores `{ "value": 88, "unit": "ch" }`), `bp` (`frame 768`, `desktop 1024`, `wide 1440`; the shared breakpoint variants already exist, so Glass defines no `--breakpoint-*`).
- `radius` (9: `capsule 9999`, `xs 6`, `sm 10`, `md 14`, `lg 20`, `xl 26`, `xxl 32`, `sheet 36`, `iconTile 12`), `blur` (12: `film 2`, `edge 6`, `thin 8`, `regular 10`, `context 12`, `thick 22`, `monolith 32`, `recede 8`, `switch 40`, `fieldPhone 120`, `fieldDesktop 180`, `reveal 12`), `border` (6: `hairline`, `slab`, `focusRing`, `selectedRing`, `errorRing`, `hc`, each with the §2.8.3 value), `light` (`angle 135`, `range 25`), `z` (10: `canvas 0`, `field 1`, `content 2`, `edge 3`, `controls 10`, `overlays 20`, `interruptions 30`, `hud 40`, `takeover 50`, `debug 90`).
- `glass` (§2.8.4): `t1` to `t5` each with `thickness`, `bezel`, `displacement`, `blur`, `saturate`, `fill`, `rim`, `specular`, `shadow`, `dispersion`, `rond` (for example `t3`: 24, 12, 12, 10, 1.8, `rgba(255,255,255,0.06)`, `rgba(255,255,255,0.20)`, 0.40, `0 8px 24px rgba(0,0,0,0.50)`, 0, 60); `clear`, `tinted` (with `fillPressed` and `specular` `rgba(228,223,255,0.60)`), `solid1` `#1C1C22`, `solid2` `#26262E`, `materialThin`, `materialRegular`, `materialThick` (`{fill, blur}`), `snap` `[36, 57, 97]` (glass §2.4.3, §2.8.4 and §15.1 all give three thresholds; the plan entry's `[36, 57, 97, 401]` is a slip for the §15.8 physics check `tierFor(401) == T4`, which proves there is no fourth threshold: T5 is declared for the Massive objects only and never reached by size).
- `dim` (`legibility {min 0.22, slope 0.42, max 0.64, minHc 0.40, maxHc 0.72}`, `grad {slope 40}`, `edgePlateau 0.72`, `edgeFade 24`), `caustic` (`alpha 0.14`, `alphaPressed 0.22`, `blur 18`, `offset 8`).
- `spring` (§2.8.5, 20): `track {150, 0.14}`, `press {220, 0.2}`, `tick {260, 0.3}`, `snappy {400, 0.15}`, `morph {380, 0.25}`, `tab {450, 0.22}`, `lens {420, 0.3}`, `sheet {480, 0.08}`, `sheetSnap {420, 0.12}`, `page {520, 0}`, `zoom {560, 0.06}`, `settle {350, 0}`, `minimize {400, 0}`, `dismiss {320, 0}`, `camera {450, 0.1}`, `celebrate {600, 0.35}`, `drift {900, 0}`, `letter {424, 0.12}`, `smooth {500, 0.1}`, `splashLens {468, 0.18}`.
- `curve` (§2.8.5, 17), in four forms the generator accepts: `{ms, bezier}` (`fadeIn 180 [0.2,0,0,1]`, `fadeOut 120 [0.4,0,1,1]`, `colorShift 240`, `tintShift 900`, `dimShift 400`, `materialize 250`, `dematerialize 350`, `sweep 520`, `followRing 700`, all `[0.2,0,0,1]` except `fadeOut`); `{ms, "curve": "linear"}` (`glowIn 150`, `glowOut 60`, `shimmer 1400`, `reducedCrossfade 150`, `reducedRoute 200`); `{ms, "curve": "step"}` (`caretBlink 530`, Dart `Threshold(0.5)`); `{ms}` (`typeStep 50`, `letterStagger 24`, Dart `Duration`).
- `physics` (21, from `decelerationRate 0.998` to `genreCentreK 4`, including `magnetPull` 0.35, `projectionCap` 1.0, `impactMinInterval` 120 and `rubberBandChapterC` 0.35) and `threshold` (33, from `dragSlopTouch 10` to `topCapsule 400`), all plain numbers: store the number of each row's Web CSS column, never the prose of its Value column (`threshold.doubleTapWindow` 280, its distance half is `threshold.doubleTapSlop` 24; `threshold.imageDismiss` 180, its velocity half is `threshold.imageDismissVelocity` 800; `threshold.streakAtRiskHour` 20; `threshold.dragSlopTouch` 10 and `threshold.dragSlopTouchScroll` 18; `threshold.pullTrigger` 100 and `threshold.pullRest` 60; `physics.valueMagnetSpeed` 0.08).
- `type` (§3.7, 18 roles): `display`, `largeTitle`, `title1`, `title2`, `title3`, `headline`, `body`, `callout`, `subhead`, `footnote`, `caption1`, `caption2`, `tabLabel`, `sidebarItem`, `mono`, `monoLarge`, `numeral`, `wrappedNumeral`. Each: `font` (`sans`, or `mono` for `mono` and `monoLarge`), `phone`, `tablet`, `desktop`, `wide` as `[size, line]` or `null` (`tabLabel` desktop and wide, `sidebarItem` phone), `wght`, `rond` (or `null` for the two mono roles), `tracking` (em), `capAt` (px or `null`: `display` 56, `largeTitle` 48, `title1` 40, `title2` 34). `footnote` also carries `"floor": 11` (§3.3: never below 11 px).
- `ahap` (§5.3, 15 patterns, the `T`/`C` event objects of `shared/00`): `droplet` T@0 I0.55 S0.85, T@0.070 I0.25 S0.95; `splash` T@0 I0.70 S0.80, C@0.020 dur 0.100 I0.25 S0.95; `magnet` T@0 I0.40 S0.90, T@0.050 I0.70 S0.80; `unlock` C@0 dur 0.120 I0.40 S0.85, T@0.120 I0.70 S0.90; `shimmer` T@0.00 I0.25, T@0.04 I0.30, T@0.08 I0.35, T@0.12 I0.40, T@0.16 I0.45, all S0.90; `pop` T@0 I0.50 S1.00, T@0.050 I0.25 S1.00; `ignite` C@0 dur 0.280 I0.35 S0.50, T@0.280 I0.90 S0.70; `swell` seven transients at t = 0, 0.15, 0.30, 0.45, 0.60, 0.75, 0.90 with I 0.20, 0.30 … 0.80 and S 0.60, 0.65 … 0.90; `cruise` C@0 dur 0.180 I0.25 S0.30, T@0.180 I0.40 S0.60; `rise1` to `rise4` with `I_d = 0.30 + 0.08 × d` written out (C@0 dur 0.120 I = 0.19 / 0.23 / 0.27 / 0.31, S0.70; T@0.120 I = 0.38 / 0.46 / 0.54 / 0.62, S0.85); `fan` T@0.00 I0.30 S0.90, T@0.05 I0.38 S0.90, T@0.10 I0.46 S0.90, T@0.15 I0.54 S0.85; `dive` C@0 dur 0.300 I0.35 S0.30, T@0.300 I0.55 S0.60.
- `haptics` (§5.2): all 90 contract events in the grammar of `design/lib/haptics.mjs`: `nav.change` selection; `nav.scrub` selection; `nav.reselect` soft:0.4; `nav.push` `ahap:rise{depth}`; `nav.pop` soft:0.5; `nav.root` `{ "repeat": "selection", "every": 40, "max": 4 }`; `stack.open` ahap:fan; `stack.pick` medium; `reader.enter` ahap:dive; `tap.primary` soft:0.6; `tap.secondary` none; `select` selection; `toggle.on` toggleOn; `toggle.off` toggleOff; `detent.tick` selection; `detent.magnet` rigid:0.4; `detent.limit` soft:0.5; `press.lift` soft:0.4; `longpress.open` medium; `throw.commit` rigid:velocity; `motion.catch` soft:velocity<=0.5; `magnet.capture` selection; `magnet.drop` ahap:magnet; `reorder.lift` dragStart; `reorder.pass` selection; `reorder.drop` soft:0.5; `sheet.pass` selection; `sheet.detent` soft:0.5; `sheet.dismiss` none; `threshold.cross` rigid:0.6; `threshold.back` rigidBack; `refresh.arm` medium; `refresh.fire` none; `refresh.done` selection; `undo` light; `delete.confirm` warning; `hold.ramp` ahap:swell; `hold.done` success; `chapter.arm` soft:0.5; `chapter.next` rigid:0.8; `chapter.seam` medium; `chapter.complete` none; `scrub.tick` selection; `scrub.boundary` rigid:0.6; `zoom.snap` light; `zoom.limit` soft:0.4; `page.turn` selection; `panel.step` soft:0.3; `ocr.hit` selection; `reader.unlock` medium; `autoscroll.start` ahap:cruise; `autoscroll.toggle` soft:0.4; `autoscroll.step` selection; `autoscroll.end` medium; `follow.add` success; `follow.remove` light; `favorite` light; `bookmark.add` success; `download.start` selection; `download.done` success; `download.fail` error; `listen.toggle` soft:0.6; `voice.center` selection; `voice.assign` success; `sleep.fade` soft:0.3; `recap.ready` success; `recap.countdown.end` none; `streak.extend` ahap:ignite; `streak.milestone` `["ahap:shimmer", {"after": 180, "then": "ahap:shimmer"}]`; `goal.met` `["success", {"after": 180, "then": "ahap:shimmer"}]`; `annual.page` selection; `annual.podium` success; `annual.summary` none; `share.lift` medium; `share.flip` rigid:0.5; `share.export` success; `reaction.bloom` medium; `reaction.cross` selection; `reaction.send` ahap:pop; `recommend.send` success; `profile.select` ahap:droplet; `gate.confirm` ahap:unlock; `skin.switch` heavy; `logo.land` ahap:droplet; `logo.settle` ahap:splash; `logo.reduced` light; `splash.impress` none (Cinematic-only); `success` success; `warning` warning; `error` error.
- `hapticsWeb` (§5.2, the seven Android-Chrome events): `stack.open [18]`, `toggle.on [10]`, `longpress.open [18]`, `follow.add [12, 60, 12]`, `download.fail [24, 50, 24]`, `streak.milestone [12]`, `error [24, 50, 24, 50, 24]`.
- `sounds` (§6, cue to file stem under `sounds/glass/`, 28 cues): `tap`, `tick`, `toggle-on`, `toggle-off`, `sheet-up`, `sheet-down`, `push-1`, `push-2`, `push-3`, `push-4`, `back`, `root`, `fan`, `dive`, `droplet`, `throw`, `catch`, `add`, `download-done`, `error`, `unlock`, `shimmer`, `pop`, `chapter`, `flip`, `send`, `melt`, `logo`. This normalises the §15.1 excerpt (event to file) into the same cue/event split Cinematic uses.
- `soundEvents` (§6): all 52 contract sound events. `tap.primary` tap; `select`, `detent.tick`, `sheet.pass`, `scrub.tick`, `nav.scrub`, `annual.page`, `page.turn` tick; `toggle.on` toggle-on; `toggle.off` toggle-off; `sheet.open` sheet-up; `sheet.close` sheet-down; `nav.push` `["push-1", "push-2", "push-3", "push-4"]` (indexed by depth 1 to 4); `nav.pop` back; `nav.root` root; `stack.open` fan; `reader.enter` dive; `refresh.arm`, `logo.land` droplet; `throw.commit` throw; `motion.catch`, `magnet.capture` catch; `follow.add`, `bookmark.add`, `voice.assign`, `recap.ready`, `magnet.drop`, `annual.podium` add; `download.done`, `share.export`, `hold.done` download-done; `error`, `download.fail` error; `gate.confirm`, `reader.unlock` unlock; `streak.extend`, `streak.milestone`, `goal.met`, `annual.summary` shimmer; `reaction.send` pop; `chapter.next` chapter; `share.flip` flip; `recommend.send` send; `skin.switch` melt; `logo.settle` logo; and `null` for `nav.change`, `favorite`, `undo`, `scrub.boundary`, `chapter.complete`, `autoscroll.toggle`, `splash.reveal`.
- `motionNames` (§4.10): the 116 names of the table's Name column, in table order, exactly as written (`"Materialise"`, `"Dematerialise"`, `"Press swell"` … `"Lens hop"`, `"Card drop"`).
- `contrast`: the declared pairs for the gate (item 4).

Add to `design/tokens/cinematic.json`: `motionNames` (§4.5, the 38 names in table order: `Cut`, `Set`, `Folio flip`, `Page`, `Match cut`, `Dip`, `Column wipe`, `Iris`, `Insert`, `Rise`, `Dissolve`, `Rack focus`, `Develop`, `Drift`, `Flicker`, `Rule draw`, `Letter set`, `Type`, `Trailer scrub`, `Cut to home`, `Lightbox`, `Arm`, `Countdown`, `Voice pulse`, `Ignite`, `Flame`, `Dolly`, `Unseal`, `Credits roll`, `Rule slide`, `Panel`, `Slate`, `Paddle page`, `Unfold`, `Leader draw`, `Highlight sweep`, `Stop the press`, `Credits`) and its `contrast` pairs.

### 2. Generator additions (`design/build.mjs`, `design/lib/*.mjs`)

`build.mjs` picks up `glass.json` automatically (it reads every `design/tokens/*.json`); keep the entry near 150 lines by putting new logic in helpers.

**Physical springs** (`design/lib/spring.mjs`, glass §4.2, §4.3, §15.10 G1). When a token file sets `spring.format` to `"physical"`:
- k = (2π / d)² and c = 4π(1 − bounce) / d with d = ms / 1000, mass 1. TS: `{ type: "spring", stiffness: k.toFixed(1), damping: c.toFixed(2), mass: 1 }` as numbers. Dart: `SpringToken(ms: ms, bounce: bounce, flutterScale: 1.0)`, so `description` is `withDurationAndBounce(duration: Duration(milliseconds: ms), bounce: bounce)` (Flutter derives exactly this k and c).
- Settle time: the last instant at which `|1 − x(t)| > 0.005`, x from rest at 0 to target 1 (critically damped `1 − (1 + ωt)e^(−ωt)`, underdamped as in `shared/00`, ω = √k, ζ = c / (2ω)), searched at 0.01 ms resolution up to 3,000 ms, then `Math.round` to whole ms. Verified values (they equal the §4.2 table): track 149, press 253, tick 289, snappy 431, morph 434, tab 518, lens 467, sheet 447, sheetSnap 342, page 615, zoom 558, settle 414, minimize 473, dismiss 378, camera 392, celebrate 643, drift 1064, letter 345, smooth 436, splashLens 532.
- CSS: `--mm-spring-<name>: linear(…)` with 60 samples x(i · T / 59), i = 0 … 59, each `Math.round(x × 10000) / 10000`, the first forced to 0 and the last to 1; `--mm-spring-<name>-ms: <T>ms`. Vector: `page` → T 615, samples 2 and 3 are `0.0073` and `0.0269`, the string ends `, 1)`.
- Computed k and c must match the §4.2 table within ±0.3 and ±0.03 for all 20 springs (`splashLens` computes to 180.2 and 22.02; the table rounds it to 180.0 and 22.0).
- Without `format` the Cinematic path of `shared/00` is unchanged (its node:test vectors must still pass).

**Glass CSS** (`frontend/src/skins/glass/tokens.generated.css`, glass §15.1 CSS bullet):
- `[data-skin="glass"] { … }` with every §2.8 property under its §2.8 name (camelCase keys to kebab: `color.onGlass` → `--mm-color-on-glass`, `layout.touchMin` → `--mm-layout-touch-min`, `radius.iconTile` → `--mm-radius-icon-tile`), the tier properties exactly as §2.8.4 writes them (`--mm-glass-t1-thickness: 12; --mm-glass-t1-bezel: 6px; --mm-glass-t1-displacement: 6; --mm-glass-t1-blur: 2px; … --mm-glass-t1-rond: 20`), `--mm-border-*`, `--mm-focus-offset: 2px`, `--mm-focus-glow: 0 0 0 2px #000, 0 0 0 6px rgba(188,176,255,0.28)`, `--mm-light-angle: 135deg`, `--mm-dim-*`, `--mm-dim-edge-plateau`, `--mm-dim-edge-fade: 24px`, `--mm-grad-slope: 40`, `--mm-caustic-*`, every `--mm-spring-*` and `-ms`, every `--mm-ease-*` and `--mm-dur-*` from `curve`, and `--mm-physics-*` and `--mm-threshold-*` as unitless numbers (§2.8.5 lists them as TypeScript constants; they are emitted in CSS too so a CSS-only component can read them).
- Type-role variables per role, redefined inside `@media (min-width: 768px)`, `(min-width: 1024px)` and `(min-width: 1440px)` (glass §3.7): `--mm-type-<role>-size` (rem), `-lh` (rem), `-wght`, `-rond` (omitted for the mono roles), `-track` (em, with its unit) and, for the shared utility of `shared/00`, `-tracking` (the same em value) and `-family` (`var(--mm-font-sans)` or `var(--mm-font-mono)`). Glass defines no `-fvs`, `-style` or `-transform`, so the shared `type-<role>` utility falls back to Glass's `wght` + `ROND` + `GRAD` settings resolved on the element. A role that is `null` at a breakpoint keeps the previous breakpoint's values (for `sidebarItem`, the phone block uses the tablet values).
- Overrides (glass §3.6, §4.11), each written for both its media query and its first-paint attribute:
  - Legible: `html[data-skin="glass"][data-legible="on"] { --mm-font-sans: var(--mm-font-legible); --mm-tracking-legible: 0.01em; }`.
  - Solid glass and Reduce Transparency: `@media (prefers-reduced-transparency: reduce) { [data-skin="glass"] { … } }` and `html[data-skin="glass"][data-solid="on"] { … }` with the same body, computed from the tokens: `t1` to `t3` fill `#1C1C22` (`solid1`), `t4` and `t5` fill `#26262E` (`solid2`), every tier and `clear` `-blur: 0px; -saturate: 1; -displacement: 0; -dispersion: 0px; -rim: rgba(255,255,255,0.10)` and `-specular` = the tier's specular × 0.5; `clear` fill `#1C1C22`; tinted `--mm-glass-tinted-fill: #5B4AD1; --mm-glass-tinted-fill-pressed: #4A3CB0; --mm-glass-tinted-blur: 0px; --mm-glass-tinted-rim: rgba(255,255,255,0.10)`; `--mm-caustic-alpha: 0; --mm-caustic-alpha-pressed: 0`.
  - Increase Contrast: `@media (prefers-contrast: more)` and `html[data-skin="glass"][data-contrast="more"]`: `--mm-color-label2: #F2F2F7; --mm-color-label3: rgba(235,235,245,0.64); --mm-color-iris400: #BCB0FF; --mm-dim-min: 0.40; --mm-dim-max: 0.72; --mm-border-focus-ring: 3px solid var(--mm-color-iris300);`.
  - Reduce Motion: `@media (prefers-reduced-motion: reduce)` and `html[data-skin="glass"][data-motion="reduced"]`: every `--mm-spring-<name>: linear` and `--mm-spring-<name>-ms: 150ms` (`curve.reducedCrossfade`), so any CSS-only spring transition becomes the 150 ms cross-fade of §4.11. Component-level replacements stay in the components.
- `@property` registrations go into the shared `theme.generated.css` (the dedup rule of `shared/00`): `--mm-light-angle` (`<angle>`, inherits true, 135deg), `--glass-dim` (`<number>`, inherits false, 0.64, the `Lb = 1.0` start of §2.1.7), `--glass-grad-t` and `--glass-rond-t` (`<number>`, inherits false, 0), `--amb-a1`, `--amb-a2`, `--amb-a3`, `--amb-rim` (`<color>`, inherits true, `#4336A3`, the Default mood), `--page-top` and `--page-bottom` (`<color>`, inherits true, `#000000`); `--page-tint` reuses Cinematic's registration unchanged. `--glass-rond` and `--glass-grad` stay unregistered (§3.5).

**Shared theme additions** (`frontend/src/skins/theme.generated.css`): the union of both skins' `@theme inline` entries, each name once: Glass colours `--color-<kebab>`, radius `--radius-<name>` (the five colliding names keep the `shared/00` legacy fallbacks), blur `--blur-<kebab>`, layout `--spacing-<kebab>: var(--mm-layout-<kebab>)`, springs `--ease-spring-<kebab>`, bezier curves `--ease-<kebab>`, fonts `--font-sans`, `--font-mono`, `--font-serif` (already emitted with fallbacks), type roles `--text-<role>` (names shared with Cinematic, `body`, `headline`, `subhead`, `numeral`, are emitted once; both skins' variables have the same names), and the runtime colours `--color-amb-a1`, `--color-amb-a2`, `--color-amb-a3`, `--color-amb-rim`, `--color-page-top`, `--color-page-bottom`. One `@utility type-<role>` per distinct role name, the var-only shape of `shared/00`.

**Glass TypeScript** (`frontend/src/skins/glass/tokens.generated.ts`): `as const` objects `color`, `space`, `layout`, `radius`, `blur`, `border`, `light`, `z`, `glass` (tiers, finishes, `snap`), `dim`, `caustic`, `spring` (physical Motion transitions), `springCss` (`{ ms, easing }`), `curve` (`{ ms, bezier }` or `{ ms, curve }`), `physics`, `threshold`, `type`, `haptics`, `hapticsWeb`, `ahap`, `sounds`, `soundEvents`, typed against `HapticEvent` and `SoundEvent` from `../contract.generated`.

**Glass Dart** (`mobile/lib/skins/glass/tokens.g.dart`, glass §2.8 Flutter column):
- `class GlassTokens extends ThemeExtension<GlassTokens>` with every field named as §2.8 writes it (`colorIris600`, `spaceS5`, `layoutTouchMin`, `layoutTouchMinAndroid`, `layoutReaderStripMin`, `layoutReaderStripFraction`, `layoutReaderStripMax`, `layoutMeasureMaxCh`, `radiusIconTile`, `blurFieldPhone`, `borderHairline`, `borderFocusRing` (a `FocusRingSpec`), `lightAngle`, `lightRange`, `zHud`, `glassT1` … `glassT5` (`GlassTier`), `glassClear`, `glassTinted` (`GlassFinish`), `glassSolid1`, `glassSolid2`, `glassMaterialThin` … (`MaterialSpec`), `dimMin`, `dimSlope`, `dimMax`, `dimMinHc`, `dimMaxHc`, `gradSlope`, `dimEdgePlateau`, `dimEdgeFade`, `glassSnap`, `causticAlpha`, `causticAlphaPressed`, `causticBlur`, `causticOffset`, `springTrack` … `springSplashLens`, `curveFadeIn` … (`CurveToken`, or `Duration` for `curveTypeStep` and `curveLetterStagger`), `physics*`, `threshold*`, `typeDisplay` … `typeWrappedNumeral` (`GlassTypeRole`), and `legible` (`bool`, default false)), a `const` constructor, complete `copyWith` and `lerp`.
- `const glassTokens = GlassTokens(…)`; `extension GlassTokensContext on BuildContext { GlassTokens get glass => Theme.of(this).extension<GlassTokens>()!; }`.
- `abstract final class` holders `GlassColors`, `GlassSpace`, `GlassRadius`, `GlassSprings`, `GlassCurves`, `GlassPhysics`, `GlassThresholds`.
- `GlassTier`, `GlassFinish`, `MaterialSpec`, `GlassTypeRole` (records `(size, line)?` per breakpoint, `wght`, `rond`, `trackingEm`, `capAt`, `floor`) defined in this file; `SpringToken`, `CurveToken`, `FocusRingSpec`, `HapticStep`, `AhapEvent` come from `mobile/lib/skins/token_types.g.dart` (add `CurveToken(ms, curve)` there if `shared/00` did not).
- `class GlassType` with `static TextStyle style(BuildContext context, GlassTypeRole role, {bool legible = false, double? rond, double grad = 0})`: frame by glass conventions (width ≥ 1440 wide; width ≥ 1024 and shortest side ≥ 600 desktop; width ≥ 768 tablet; else phone), family `GoogleSansFlexMM` (or `GoogleSansCodeMM`; `AtkinsonHyperlegibleNext` with `legible`, adding 0.01 em tracking), `fontSize`, `height = line / size`, `letterSpacing = trackingEm × size`, `fontVariations` `wght` (+100 when `MediaQuery.boldTextOf(context)`, clamped to 800; the caller adds 20 to `grad` on glass), `opsz` = size, `ROND` = `rond ?? role.rond`, `GRAD` = grad (none of the three for the mono roles, `wght` only); `static double maxScaleFor(BuildContext context, GlassTypeRole role)` = `capAt == null ? double.infinity : capAt / baseSize`; `static TextScaler scaler(BuildContext context, GlassTypeRole role)` = the context scaler clamped by `maxScaleFor`; `static double scaledSize(BuildContext context, GlassTypeRole role)` honouring the `footnote` floor of 11 px.
- `const Map<HapticEvent, List<HapticStep>> glassHaptics` (every event; `nav.root`'s repeat becomes one step with `repeatEveryMs: 40, maxRepeats: 4`), `const Map<String, List<AhapEvent>> glassAhap`, `const Map<String, String> glassSoundCues` (`assets/sounds/glass/<stem>.wav`), `const Map<SoundEvent, List<String>> glassSoundEvents` (`nav.push` has four entries, depth order).

### 3. `design/build-haptics.mjs` (glass §5.3, §15.1 "Generator ownership", G2)

Called by `build.mjs` (and by `--check`, in memory). Stdlib only. It writes:

**AHAP assets** for both skins, one file per pattern: `mobile/assets/haptics/cinematic/{impress,stamp,wipe,ignite,pressrun,pass}.ahap.json` (6) and `mobile/assets/haptics/glass/{droplet,splash,magnet,unlock,shimmer,pop,ignite,swell,cruise,rise1,rise2,rise3,rise4,fan,dive}.ahap.json` (15). Format (Apple AHAP, which `gaimon` 1.5.0 `Gaimon.patternFromData` reads), two-space indented, keys in this order, no timestamp:

```json
{
  "Version": 1.0,
  "Metadata": { "Project": "ManhwaManiacs", "Description": "glass rise3" },
  "Pattern": [
    { "Event": { "Time": 0.0, "EventType": "HapticContinuous", "EventDuration": 0.12,
      "EventParameters": [ { "ParameterID": "HapticIntensity", "ParameterValue": 0.27 },
                           { "ParameterID": "HapticSharpness", "ParameterValue": 0.7 } ] } },
    { "Event": { "Time": 0.12, "EventType": "HapticTransient",
      "EventParameters": [ { "ParameterID": "HapticIntensity", "ParameterValue": 0.54 },
                           { "ParameterID": "HapticSharpness", "ParameterValue": 0.85 } ] } }
  ]
}
```
Transients (`T`) become `HapticTransient` without `EventDuration`; continuous (`C`) become `HapticContinuous` with it. Only these two event types (gaimon's Android conversion ignores attack and decay, glass §5.3).

**Motion-name unions** for both skins, from each token file's `motionNames`: `frontend/src/skins/cinematic/motion.generated.ts`, `frontend/src/skins/glass/motion.generated.ts`, `mobile/lib/skins/cinematic/motion_names.g.dart`, `mobile/lib/skins/glass/motion_names.g.dart`.
- Id: the name lower-cased, split on anything that is not a letter or digit, camelCased (`Column wipe` → `columnWipe`, `Count-up` → `countUp`, `Deck lift-off` → `deckLiftOff`, `Reaction bloom and arc` → `reactionBloomAndArc`). Label: the name upper-cased (`COLUMN WIPE`), the string the motion-timings overlay prints (cinematic §15.9, glass §15.8).
- TS: `export const MOTION_NAMES = [...] as const; export type MotionName = (typeof MOTION_NAMES)[number]; export const MOTION_LABELS: Record<MotionName, string> = {…};`.
- Dart: `enum MotionName { columnWipe('COLUMN WIPE'), …; const MotionName(this.label); final String label; }`. A Dart reserved word or an `Enum` member name gets the suffix `Move`: `throw` → `throwMove`, `catch` → `catchMove`; the full list to escape is the Dart reserved words (`assert break case catch class const continue default do else enum extends false final finally for if in is new null rethrow return super switch this throw true try var void while with`) plus `index`, `values`, `name`, `hashCode`, `runtimeType`. The label keeps the original name.
- Fail the build on duplicate ids within a skin.

### 4. `design/check-contrast.mjs` (glass §15.8 "Contrast gate", cinematic §2.1.1, §2.1.4, §14.2)

Stdlib, called by `build.mjs --check` after the lint. It reads the `contrast` arrays of every token file and evaluates each case.

**Model.** WCAG 2.x: channel c in 0..1, linear = c ≤ 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055)^2.4; L = 0.2126 R + 0.7152 G + 0.0722 B; ratio = (L_hi + 0.05) / (L_lo + 0.05). Compositing is plain alpha-over in sRGB with floats (no 8-bit rounding): `out = a × src + (1 − a) × dst`, applied bottom to top.

**Case schema** (one object per case):
```json
{ "id": "glass.onGlass.t3.white.dimMax", "fg": "color.onGlass",
  "over": ["#FFFFFF", { "black": 0.64 }, "glass.t3.fill"],
  "kind": "text", "expect": 5.14, "ref": "§2.1.7" }
```
`over` lists the ground bottom to top; its first entry must be opaque. Entries are a colour literal, a token key of the same file (an `rgba()` value composites with its alpha), `{ "black": a }`, `{ "white": a }`, or `{ "color": "<literal or key>", "alpha": a }`. `fg` is a colour literal or key; an `rgba()` foreground is composited over the final ground before measuring. `kind` is `text` (min 4.5), `large` (min 3: ≥ 24 px, or ≥ 18.66 px at `wght` ≥ 700) or `nontext` (min 3: icons, focus rings, UI marks). `expect` is the figure the DESIGN file prints; the gate prints a warning, not a failure, when the computed ratio differs from it by more than 0.1, and you report every such warning. Glass §15.8 reads the backings from `glass.json`, so write them as token keys: the backing disc as `"color.backingDisc"` (`rgba(0,0,0,0.60)`), the cover tag capsule and play orb as `"color.coverBacking"` (0.86) and the cover discs as `"color.coverDisc"` (0.72); `{ "black": a }` stays for dims and scrims (0.64, 0.22, 0.72 plateau, 0.88 `scrim.head`).

**Output.** One line per case (`id  ratio  min  expect  PASS|FAIL`), then a summary; exit 1 on any failure or any forbidden declaration.

**Forbidden declarations** (rule checks on the declared cases, so a bad pair cannot be added quietly):
- Cinematic: a case whose `fg` is `color.ink.45` and whose `over` is anything other than a single opaque `color.paper.0` or `#000000` (a badge's `#000000` fill counts) fails, citing cinematic §2.1.1.
- Glass: a case whose `fg` is a state colour (`iris*`, `success`, `warning`, `danger`, `info`, `mature`, `streak`, `streakCore`, `bloom`, `machine`) with a T2 to T5 tier fill in `over` and no `"color.backingDisc"` (or `{ "black": 0.60 }`) above that fill fails, unless the case carries `"exception"` naming one of the §2.1.2 exceptions.
- Glass: a case whose `fg` is `label2` or `label3` with a T4 or T5 fill in `over` and no `color.wellOnGlass` above it fails, unless its id starts with `glass.wrapped.` (the Wrapped frame, §2.1.2).

**Cases to declare.**

Cinematic (`cinematic.json` `contrast`): `ink.100`, `ink.80`, `ink.60` on each of `paper.0` to `paper.4` (`ink.60` expects 7.20, 6.75, 6.42, 5.97, 5.45); `ink.45` on `paper.0` (4.70); `#000000` on `spot` (13.9) and on `proof` (6.9); `spot`, `proof`, `set`, `info` on `paper.0` (13.9, 6.9, 11.4, 12.1); `ink.60` on each of the six mood grades (lowest 6.35, comedy); `ink.80` on `spot.wash` over `paper.0` (9.41) and over `paper.3` (6.98); each stock's ink on its page (≥ 13.4, lowest sepia night 13.42) and muted on its page (≥ 5.8); the over-art rows of §2.1.4 over `#FFFFFF` (`ink.100` at 0.60, `ink.80` 0.68, `spot` 0.66, `set` 0.70, `ink.60` 0.82, `proof` 0.84: every one ≥ 4.5); `scrim.head` flat part over `#FFFFFF` (`{ "black": 0.88 }`: `ink.60` 5.65, `spot` 10.94, `ink.100` 14.47); `on-art` controls (`ink.100` on `{ "black": 0.64 }` over `#FFFFFF` 5.89 and over `#F5F547` 6.51); `ink.100` on each of the twelve `avatar.*` fields (§7.25, every one ≥ 4.5; lowest amber 4.53); the focus ring `ink.100` on `#000000` as `nontext`.

Glass (`glass.json` `contrast`): the label table of §2.1.2 (`label1`, `label2`, `label3` on `g0`, `surface1`, `surface3`: 18.82 / 16.61 / 14.16, 7.15 / 6.88 / 6.32, 4.92 / 4.92 / 4.67), `iris300` to `iris600` on `g0` (§2.1.3), the semantic colours on `g0` and `surface1` and black text on each (§2.1.4), each speaker `spk1..10` on each of the seven papers, each paper's ink and muted on its page, and every §15.8 case:
- the three worst cases of §2.1.7: `onGlass` on T3 over `#FFFFFF` at dim 0.64 (expect 5.14); `onGlass` on T3 over `#FFFFFF` under the 0.72 `edgeSoft` plateau at dim 0.22 (8.8); `onTint` on `glassTinted` over `#FFFFFF` at dim 0.64 (4.66);
- clear glass over `#FFFFFF` at dim 0.64 (5.72) and over the uniform backdrop `#BCBCBC` (Lb 0.5) at dim 0.43 (4.56); T2 over `#FFFFFF` at dim 0.64 (5.05); T4 over `#FFFFFF` at dim 0.22 (4.55);
- the backing disc: `iris400`, `iris500`, `danger`, `warning`, `success`, `streakCore`, `bloom`, `mature` on `{ "black": 0.60 }` inside T2, T3, T4 and clear over `#FFFFFF` at dim 0.64 (`nontext`, lowest `iris500` on T2 4.55) and inside T4 at dim 0.22 (lowest `iris500` 4.38); `onGlass` on the Selected wash inside T3 over `#FFFFFF` at 0.64 (4.95; read the wash colour in §7.1); `iris400` on the dock's plateau (T3 over the 0.72 plateau at 0.22, 4.11); the other §2.1.2 exceptions at dim 0.22 marked with `"exception"` (`iris400`, `bloom`, `streak` at 80 % inside T2 and T3 over the plateau and `streak` at 80 % on the bare plateau, lowest 3.07; `iris400`, `danger`, `warning`, `bloom`, `streak` at 80 % inside T2 and T3 over a 0.475-luminance blob at 36 % field opacity, lowest 3.31; `bloom` inside T2 under `dimContext`, 3.09; `bloom` and `iris300` rings inside T4 under `dimSheet`, lowest 3.92; the wordmark's `iris400` M's over the capped field, 4.38; `mature` on the 40 px disc inside T4 under `dimModal`, 5.98);
- the overlay sidebar: `onGlass` on T3 under `dimSheet` over `#FFFFFF` at 0.64 (7.52) and its `bloom` and `warning` dots and `streak` ring at 80 % on the disc inside T3 under `dimSheet` at 0.22 (lowest 3.57);
- glyph mapping: the Audiobook panel's `danger` and `success` on the disc inside T4 at 0.22 (4.61 and 7.82);
- wells: `label2` on `wellOnGlass` inside T4 over `#FFFFFF` under `dimSheet` at 0.22 (5.20);
- T4 and T5 bodies: `onGlass` on T4 under `dimModal` at 0.22 (9.23) and on T5 under `dimSheet` at 0.22 (8.36);
- cover overlays over `#FFFFFF`: tag text on `{ "black": 0.86 }` (`iris400` 6.54, `success` 8.73, `warning` 8.87, `info` 7.37, `mature` 5.35); `success` droplet on `{ "black": 0.72 }` (5.17, `nontext`); `iris500` progress on `{ "black": 0.86 }` (4.89, `nontext`); the favourite star (`streakCore`) and `age-gate` glyph (`mature`) on `{ "black": 0.72 }` (`nontext`); the desktop hover bell (`iris400` 6.54) and star (`streakCore` 10.81) on `{ "black": 0.86 }`; `label1` on the play orb `{ "black": 0.86 }` (13.96);
- the ambient field: `label2` and `label3` over a `#B7B7B7` blob at each screen's opacity from the §2.1.8 table (`label3` only where that opacity is ≤ 20 %, `label2` everywhere; `label2` at 36 % expects 4.57);
- avatar glyphs (§7.26): each preset's gradient sampled at 30, 50 and 70 % of its diagonal (linear interpolation from `from` to `to` in sRGB) against its glyph colour, `nontext` (lowest 3.58 for Steel Blade dark and Rose Heart white);
- the focus ring: `iris300` on `#000000` and `#000000` (the inner ring) on `#FFFFFF`, both `nontext`.
- Negative self-checks go in `design/test/contrast.test.mjs`, not in the JSON: bare `danger` inside T4 over `#FFFFFF` at 0.22 must measure 1.68 (±0.02) and be rejected by the state-colour rule; `label3` on T4 under `dimModal` at 0.22 must measure 3.64 and be rejected by the label rule; `label2` on T5 under `dimSheet` at 0.22 must measure 4.32 and be rejected; `ink.45` on `paper.2` must measure 4.20 and be rejected by the Cinematic rule.

Compositing vectors verified on this box with exactly this model (use them in `design/test/contrast.test.mjs`, ±0.02): T3 over white at dim 0.64 → 5.18; plateau case → 8.78; tinted → 4.67; clear 0.64 → 5.72; T2 0.64 → 5.05; T4 0.22 → 4.55; `iris500` disc in T2 → 4.55; `label2` well → 5.20; T4 `dimModal` → 9.23; T5 `dimSheet` → 8.36; `iris500` disc in T4 0.22 → 4.38; clear over `#BCBCBC` at 0.43 → 4.56; Cinematic `scrim.head` 0.88 over white: `ink.60` 5.68, `spot` 10.99, `ink.100` 14.54; `ink.80` on `spot.wash` over black 9.38. (The DESIGN figures differ from these by at most 0.07; that is rounding in the documents, which is why the gate warns rather than fails on `expect`.)

### 5. `design/lint-utilities.mjs` extended

Scan `frontend/src/skins/glass/**/*.{ts,tsx,css}` (except `*.generated.*`) against Glass's own names (the `@theme` entries this generator emits for Glass, plus the `animate-*` names in an `@theme` block of `frontend/src/skins/glass/motion.css` when it exists), with the same structural allowlist and arbitrary-value rules as Cinematic, except: `backdrop-blur-<glass blur name>` is allowed for Glass (Glass is built on backdrop filters), and `rounded-<glass radius>` replaces `rounded-0|round`. A Cinematic-only name in a Glass file fails, and a Glass-only name in a Cinematic file fails.

### 6. Self-checks (`node --test design/test/`)

New files: `glass-spring.test.mjs` (all 20 springs: k ±0.3 and c ±0.03 against §4.2, settle exact; the two §15.8 values `{520, 0}` → k 146.0, c 24.17 and `{150, 0.14}` → k 1754.6, c 72.05; the `page` sample vector), `contrast.test.mjs` (the compositing vectors and the four negative cases), `haptics.test.mjs` (the `rise3` file byte for byte as above; `swell` has 7 events whose last is at 0.9 s with I 0.8 and S 0.9; every event of `contract.json` present in both skins' `haptics`), `motion-names.test.mjs` (38 Cinematic and 116 Glass ids, unique; `Throw` → `throwMove`, `Catch` → `catchMove`, `Count-up` → `countUp`), `glass-tokens.test.mjs` (the counts of item 1). The `shared/00` tests must still pass.

The generated Dart test gains `mobile/test/skins/generated_glass_test.dart` (generated): `GlassColors.iris600 == Color(0xFF7563F2)`; `glassTokens.colorLabel2 == Color(0xA3EBEBF5)`; `GlassSprings.page.description.stiffness` 146.0 ± 0.05 and `.damping` 24.17 ± 0.01; `GlassSprings.track.description.stiffness` 1754.6 ± 0.1; `glassTokens.glassSnap` equals `[36, 57, 97]`; the Glass `MotionName.values.length == 116` and `MotionName.throwMove.label == 'THROW'`; the Cinematic `MotionName.values.length == 38`; every `HapticEvent` in `glassHaptics`; every `SoundEvent` in `glassSoundEvents`; `glassSoundEvents[SoundEvent.navPush]!.length == 4`.

### 7. Proof

Extend `design/proof-sheet.mjs` to also write `docs/redesign/proof/shared-01/glass-tokens.svg`: every Glass colour swatch with its contrast on `#000000`, the five tiers as panels over a black-and-white checkerboard strip showing fill and rim, the 20 spring curves from their `linear()` samples with settle times, and the contrast gate's results table (case id, ratio, threshold, pass). Also write `docs/redesign/proof/shared-01/contrast-report.txt` with the gate's full output.

## File layout

Create:
```
design/tokens/glass.json
design/build-haptics.mjs
design/check-contrast.mjs
design/lib/composite.mjs                 WCAG luminance, ratio, alpha-over
design/test/glass-spring.test.mjs
design/test/contrast.test.mjs
design/test/haptics.test.mjs
design/test/motion-names.test.mjs
design/test/glass-tokens.test.mjs
frontend/src/skins/glass/tokens.generated.css
frontend/src/skins/glass/tokens.generated.ts
frontend/src/skins/cinematic/motion.generated.ts
frontend/src/skins/glass/motion.generated.ts
mobile/lib/skins/glass/tokens.g.dart
mobile/lib/skins/cinematic/motion_names.g.dart
mobile/lib/skins/glass/motion_names.g.dart
mobile/assets/haptics/cinematic/{impress,stamp,wipe,ignite,pressrun,pass}.ahap.json
mobile/assets/haptics/glass/{droplet,splash,magnet,unlock,shimmer,pop,ignite,swell,cruise,rise1,rise2,rise3,rise4,fan,dive}.ahap.json
mobile/test/skins/generated_glass_test.dart
docs/redesign/proof/shared-01/glass-tokens.svg
docs/redesign/proof/shared-01/contrast-report.txt
docs/redesign/proof/shared-01/glass-tokens-1440.png, glass-tokens-390.png
```
Change: `design/tokens/cinematic.json` (add `motionNames`, `contrast`), `design/build.mjs`, `design/lib/spring.mjs`, `design/lib/naming.mjs`, `design/lib/emit-*.mjs`, `design/lint-utilities.mjs`, `design/proof-sheet.mjs`, and the regenerated `frontend/src/skins/theme.generated.css`, `frontend/src/skins/cinematic/tokens.generated.*`, `mobile/lib/skins/token_types.g.dart`, `mobile/lib/skins/cinematic/tokens.g.dart`, `mobile/test/skins/generated_contract_test.dart` (only if the generator's output for them changes). Do not declare the AHAP assets in `mobile/pubspec.yaml`; mobile/02 does that.

## Acceptance criteria

- [ ] `design/tokens/glass.json` holds every key of glass §2.8.1 to §2.8.5 and §3.7 with identical values (spot-check: `color.twinDense`, `color.paper.glass.muted` `#8F8F99`, `color.avatar.steelBlade.glyph`, `layout.readerStripMax`, `radius.iconTile`, `blur.fieldDesktop`, `border.focusRing`, `glass.t4.dispersion` 0.6, `glass.tinted.fillPressed`, `glass.snap`, `dim.legibility.maxHc` 0.72, `spring.splashLens`, `curve.caretBlink`, `physics.gravitySplash` 9000, `physics.magnetPull` 0.35, `color.backingDisc`, `threshold.topCapsule` 400, `type.wrappedNumeral`), plus `spring.format: "physical"`, 15 AHAP patterns, all 90 haptic events, all 52 sound events, 28 cues and 116 motion names.
- [ ] `node design/build.mjs` writes every file in "File layout"; running it twice leaves the tree unchanged.
- [ ] `node design/build.mjs --check` exits 0 and runs, in order, the output comparison, `design/lint-utilities.mjs` (both skins) and `design/check-contrast.mjs`; changing one byte of `mobile/assets/haptics/glass/rise3.ahap.json` or `frontend/src/skins/glass/motion.generated.ts` makes it exit 1 naming that file; regenerating restores exit 0.
- [ ] `node design/check-contrast.mjs` passes every declared case of both skins and prints no warning larger than 0.1 without it being listed in your report; the four negative self-checks are rejected in `design/test/contrast.test.mjs`.
- [ ] `node --test design/test/` passes (all `shared/00` tests plus the five new files).
- [ ] Glass TS springs are physical: `spring.page` is `{ type: "spring", stiffness: 146, damping: 24.17, mass: 1 }` and no Glass spring carries `visualDuration`; Cinematic's springs are unchanged (`visualDuration`).
- [ ] `frontend/src/skins/glass/tokens.generated.css` contains the four override blocks (legible, solid/reduced-transparency, increase-contrast, reduced-motion), each under both its media query and its `html[data-skin="glass"][data-…]` attribute selector, and the type variables per `frame`/`desktop`/`wide` breakpoint.
- [ ] `theme.generated.css` has each `@theme inline` name and each `type-*` utility exactly once (a duplicate-name check in `design/test/glass-tokens.test.mjs` proves it), the Glass runtime `@property` registrations, and `--page-tint` registered once.
- [ ] Reduced motion: the Glass reduced-motion override maps every spring to `linear` over 150 ms; the Cinematic tokens are untouched; `curve.reducedCrossfade` (150) and `curve.reducedRoute` (200) exist in TS and Dart for the components.
- [ ] Hit targets: `--mm-layout-touch-min: 44px`, `GlassTokens.layoutTouchMin == 44` and `layoutTouchMinAndroid == 48` (glass §14.6); `--mm-layout-nav-button: 44px`.
- [ ] Keyboard focus: `--mm-border-focus-ring`, `--mm-focus-offset`, `--mm-focus-glow` and `GlassTokens.borderFocusRing` match §2.8.3; Increase Contrast widens the ring to 3 px.
- [ ] Per-skin differences hold: `design/lint-utilities.mjs` rejects `rounded-md` in a Cinematic probe file and `rounded-0` and `ease-settle` in a Glass probe file, and accepts `backdrop-blur-thin` only in Glass (make both probes, run the lint, delete the probes, and show `git status` without them).
- [ ] `frontend`: `npm run lint` 0 errors 0 warnings, `npm run typecheck` passes, `npm run test` passes with a count no lower than before this step, `npm run build` passes.
- [ ] `mobile`: `flutter analyze` no issues; `flutter test` passes with 2012 plus the generated tests' cases, 0 failed.
- [ ] Proof files exist under `docs/redesign/proof/shared-01/`: `glass-tokens.svg`, `contrast-report.txt`, `glass-tokens-1440.png` and `glass-tokens-390.png`, and you looked at both PNGs.
- [ ] Every commit touches only this step's paths, carries no AI attribution, and was pushed.

## Verification commands

From the repo root, one heavy command at a time, `free -m` first (stop under 1024 MB available).

```bash
node design/build.mjs
node design/build.mjs --check; echo "check exit $?"
node --test design/test/
node design/check-contrast.mjs | tee docs/redesign/proof/shared-01/contrast-report.txt | tail -5
node design/lint-utilities.mjs; echo "lint exit $?"

# Tailwind 4 compile check (scratch): both skins' CSS in one stylesheet
cd frontend && node --input-type=module -e "
import {compile} from '@tailwindcss/node';
import fs from 'node:fs';
const css = '@import \"tailwindcss\";\n' + ['src/skins/theme.generated.css','src/skins/cinematic/tokens.generated.css','src/skins/glass/tokens.generated.css'].map(f => fs.readFileSync(f,'utf8')).join('\n');
const c = await compile(css, { base: process.cwd(), onDependency() {} });
const out = c.build(['bg-iris600','text-label2','type-large-title','type-body','rounded-capsule','rounded-md','backdrop-blur-thin','ease-spring-page','h-dock-height','bg-amb-a1']);
const expect = ['.bg-iris600 {','.text-label2 {','.type-large-title {','.type-body {','.rounded-capsule {','var(--mm-radius-md, 0.5rem)','.backdrop-blur-thin {','.ease-spring-page {','.h-dock-height {','.bg-amb-a1 {'];
const missing = expect.filter(e => !out.includes(e));
if (missing.length) { console.error('missing', missing); process.exit(1); } console.log('tailwind ok');
"; cd ..

free -m
cd frontend && npm run lint && cd ..
free -m
cd frontend && npm run typecheck && cd ..
free -m
cd frontend && npm run test && cd ..
free -m
cd frontend && npm run build && cd ..
free -m
cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze && cd ..
free -m
cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter test && cd ..
node design/proof-sheet.mjs
git status --short
```

Backend: no backend code changes here. If `backend/.venv` exists (backend/00 creates it), also run `cd backend && free -m && timeout 1800 .venv/bin/python -m pytest -q --no-header 2>&1 | tail -3` and quote the summary line; the CI `backend` job (`cd backend && pytest -q --no-header`) must stay green on your pushed commits either way.

**Visual proof.** No web screen changes in this step. The proof is `docs/redesign/proof/shared-01/glass-tokens.svg` and `contrast-report.txt`; capture the SVG in headless Chromium at 1440 × 900 and 390 × 844 (full page) into `docs/redesign/proof/shared-01/glass-tokens-1440.png` and `glass-tokens-390.png` with the command block of shared/00 "Visual proof" (same script, with `shared-01/glass-tokens.svg` as the page and `shared-01/glass-tokens-` as the output prefix; install Chromium first exactly as that block says if `~/.cache/ms-playwright` has no `chromium-*` folder), and look at both.

## Commit plan

1. `feat(design): Glass token source` — `design/tokens/glass.json`, `design/test/glass-tokens.test.mjs`.
2. `feat(design): physical springs for Glass` — `design/lib/spring.mjs`, `design/test/glass-spring.test.mjs`.
3. `feat(design): Glass CSS, TS and Dart emitters` — `design/build.mjs`, `design/lib/naming.mjs`, `design/lib/emit-*.mjs`.
4. `feat(design): AHAP assets and motion-name unions` — `design/build-haptics.mjs`, `design/test/haptics.test.mjs`, `design/test/motion-names.test.mjs`, `motionNames` in both token files.
5. `feat(design): contrast gate for both skins` — `design/check-contrast.mjs`, `design/lib/composite.mjs`, `design/test/contrast.test.mjs`, the `contrast` arrays.
6. `feat(design): lint Glass utilities` — `design/lint-utilities.mjs`.
7. `feat(design): generated Glass tokens, haptics and motion names` — every generated file.
8. `docs(redesign): Glass token proof and contrast report` — `design/proof-sheet.mjs`, `docs/redesign/proof/shared-01/**`.

Push after each; `git add <explicit paths>` every time.

## Report back

- The checklist with every box ticked or explained.
- Counts: Glass colour keys, layout keys, springs, curves, physics, thresholds, type roles, AHAP files per skin, motion names per skin, contrast cases per skin (pass/fail), warnings above 0.1 with their ids and both figures.
- The 20 Glass settle times as generated.
- The outputs of `--check`, `node --test design/test/` (pass count), the contrast gate summary line, both lint runs, `npm run lint`, `npm run typecheck`, `npm run test` (count), `npm run build`, `flutter analyze`, `flutter test` (count), and the lowest `free -m` available figure.
- Proof paths: `docs/redesign/proof/shared-01/glass-tokens.svg`, `contrast-report.txt`, `glass-tokens-1440.png`, `glass-tokens-390.png`.
- Pushed commit hashes.
- Open issues: any DESIGN value you had to interpret (for example where a §15.8 case needed a colour from another section), and the hand-offs: mobile/02 declares `assets/haptics/` in `pubspec.yaml`; web/02 and mobile/02 read `haptics`, `hapticsWeb`, `sounds` and `soundEvents` from the generated files; web/04 and mobile/04 start every named move through `play(name)` typed by `MotionName`. Also state for web/25 that `glass.snap` is `[36, 57, 97]` (T5 is never reached by size; `tierFor(401)` is T4 per glass §15.8), and for web/01 that the Glass CSS springs are glass §15.1's own 60-sample curves over the 0.01 ms settle time, so they are not equal to Motion's `spring({stiffness, damping, mass}).toString()` (that prints `800ms linear(0, 0.0541, …` for `page`, 27 samples at 30 ms): the Glass parity test must compare the physical `stiffness` and `damping` against `(2π / d)²` and `4π(1 − bounce) / d`, and each CSS sample against Motion's generator value `spring({ keyframes: [0, 1], stiffness, damping, mass: 1 }).next(t).value` at the same `t` (±0.0005, because the TS tokens round k to one decimal and c to two; checked on this box against `motion-dom` 12.42.2 for all 20 springs, worst difference 0.00035; the last sample is 1), not the two strings.

**Next prompt file:** in the series order the next file is `docs/redesign/prompts/web/00-foundation-skin-engine-and-routes.md`; the next file on the shared track is `docs/redesign/prompts/shared/02-icon-sets-and-custom-glyphs.md`.
