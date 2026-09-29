# Web Glass QA and polish

Track: web · Order 108 · Depends on: `docs/redesign/prompts/web/44-glass-ambient-reader-extras.md` · Runs in parallel with: `docs/redesign/prompts/mobile/45-glass-qa-polish.md` · Proof folder: `docs/redesign/proof/web-45/`

## Goal

Every Glass web screen now exists (steps `web/25` to `web/44`). This step proves the whole Glass skin on the web against every check of `glass/DESIGN.md` §15.8 and fixes everything that fails, so `release/01` can make Glass available. You will: make the completeness test strict for Glass (no Glass `ScreenId` left in `PENDING`) and prove the lint boundary; rerun the physics check; run the contrast gate and check the worst glass cases in the browser; compare the calibration page with the Flutter capture; capture every `ScreenId` at 1440 × 900, 390 × 844 and 440 × 956 (DPR 3) plus one Reduce Motion, one Solid glass and one Increase Contrast snapshot per screen, with Cinematic beside it; verify reduced motion against §4.10 and §4.11 and run the motion-timings overlay over all 116 named moves; check that the generated motion names match §4.10 row for row; prove the two signature animations; run the accessibility pass of §14 and §15.8 with the gate-close checklist of §14.11; verify the §15.7 budget (at most six live `backdrop-filter` elements per web screen in every moment of its table); produce the "Float" showcase set of §12.5; switch skins in both directions through the debug row; fix every defect, each in its own commit; and write `docs/redesign/proof/web-45/qa.md`. You add no features. When a check needs something the contract does not define, the contract wins and the gap goes into `qa.md` as an open issue.

## Read first

Read these completely before planning. Where this file and `glass/DESIGN.md` disagree, `glass/DESIGN.md` wins; say so in the report.

1. `docs/redesign/inventory/00-decisions.md` (all of it: the two signature animations are binding; dark AMOLED `#000000`; flagship-only maximum effects; "Still honor OS reduced-motion for accessibility").
2. `docs/redesign/stack-decision.md` §2.2 (completeness through `satisfies Record<ScreenId, Screen>`, the lint boundary), §2.4 and §2.5 (the skin mirror, the return route, restart), §3 "Release model", §4 risks 3, 5, 7 and 11.
3. `docs/redesign/glass/DESIGN.md`:
   - §2.1.2 (text on glass is `onGlass` or `onTint`, never alpha text; the backing disc; `label1` to `label4`, `g500`, `g600` and what each may carry), §2.1.7 (the dims, the legibility floor, the three worst cases and their measured ratios), §2.1.8 (the field table with the opacity per screen; "Text over the brighter fields": `label2` in the top 60 % where the opacity exceeds 20 %), §2.4.1 (the three glass rules, the six-element budget, bar groups as one masked element, focus rings never masked), §2.4.3 (the calibration knobs), §2.6 (the two-tone focus ring).
   - §3.2 (the type scale; the smallest role is 11 px), §3.6 (Legible text).
   - §4.10 (the 116-row motion table, every last column) and §4.11 (all of it: sources of each setting, screen-reader behaviours, the Reduce Motion table, Reduce Transparency and Solid glass, Increase Contrast, forced colours).
   - §5.2 (the seven Android-web `navigator.vibrate` events), §6 (sounds off by default; suppression rules).
   - §7.15 and §7.16 (dock minimise, sidebar), §7.24 (states), §7.25 (the 18+ gate alert and hold), §7.28 (palette), §7.37 (the web back menu).
   - §8.0.3 (the `ScreenId` and route table, the `?sheet=` ids), §8.0.4, §8.0.6 (global keys), §8.0.8 (all of it: availability flag, first-paint attributes, the 18+ purge steps 1–6, mobile web gesture hygiene, focus on navigation), §8.0.9, §8.0.10, §8.2 (splash on the web), §8.25.1, §8.25.2 (the switch flow and the melt), §8.25.12 (Diagnostics: "Glass layers on screen", "Preview Glass skin", "Glass calibration", "Show motion timings"), §8.28 (status screens and `offline-fallback-glass.html`).
   - §10.1 and §10.2 (all of both: parameters, placements, once-rules, skip rules, caps, the `mm.glass.revealed` and `mm.glass.typed` records).
   - §11 (the last column: the alternative for every gesture).
   - §12.2 (the aurora field), §12.4 (Droplet reveal timings), §12.5 (the "Float" showcase set), §12.6, §12.7 (demo art, no real names or covers).
   - §13 (the 28 signature moments and their Reduce Motion versions).
   - §14.1 to §14.11 (every rule, and the gate-close checklist with its share-card check).
   - §15.1 (`build.mjs --check` runs the motion names, `lint-utilities.mjs` and `check-contrast.mjs`), §15.2 (web file map, sheet host, service worker), §15.7 (all of it, and the live-surface table row by row), §15.8 (every bullet: physics, contrast gate with every added case, calibration page, completeness and boundary, screenshots, motion-timings overlay, accessibility pass, signature animations, motion names, web gate), §15.9, §15.10 rows G6–G16.
4. `docs/redesign/inventory/web.md` §1 (route table), §2 (global chrome), §2.9 (keyboard layer), §2.10 and §2.11 (status screens and shared states), §18 (every user action: the checklist that no function was lost).
5. `docs/redesign/inventory/capabilities.md` §1 (cross-cutting contract: 18+ absence, rate limits) and §6 (the 18+ gate).
6. `docs/redesign/00-baseline.md` (the green baseline you must keep: lint 0/0, build 0/0).
7. `docs/redesign/prompts-plan.json`: the entry for `web/00` (its `TRACK RULE` binds this file), the entry for this file, and `release/01` (what it will do after you, so you do not do it here).
8. `docs/redesign/prompts/web/24-cinematic-qa-polish.md` and `docs/redesign/proof/web-24/qa.md`: the Cinematic QA harness you extend instead of forking.
9. Code you work on: `frontend/src/skins/glass/**` (every screen and primitive), `frontend/src/skins/glass/index.ts` (the `PENDING` map), the completeness vitest (`grep -rln "SCREEN_IDS" frontend/src --include=*.test.ts`), `frontend/src/skins/glass/physics/physics.test.ts`, `frontend/src/skins/glass/motion.ts`, `motion.generated.ts`, `motion-timings.tsx`, `glass/budget.ts`, `frontend/src/app/(preview)/dev/glass-calibration/`, `frontend/e2e/` (the Cinematic harness `support/cinematic-routes.ts`, `support/audit.ts` and its specs, `glass-foundation.spec.ts`, `glass-ambient.spec.ts` and any Glass signature spec from `web/26`), `frontend/scripts/proof.mjs`, `frontend/playwright.config.ts`, `backend/scripts/README-dev-stack.md`, `design/check-contrast.mjs`, `brand/glass/`, `brand/demo/`.

## Preconditions (check before writing the plan)

- `git status` is clean for `frontend/` and `git log --oneline -30` shows the `web/44` work.
- `node design/build.mjs --check` passes (generated files, motion names, utility names and the contrast gate).
- In `frontend/`: `free -m && npm run test` is green; record the vitest file and case counts (your floor). `npm run lint`, `npm run build` and `npm run verify:reader` are green.
- Read `frontend/src/skins/glass/index.ts`. If any Glass `ScreenId` is still in `PENDING`, find the step that owns it in `docs/redesign/prompts-plan.json` (search the scopes for the screen), execute that step's scope for the missing screen first as its own commits, and name it in the report. A missing screen is not polish; do not paper over it.
- `design/contract.json` has `flags.glass_available: false` (it stays false; `release/01` flips it).
- The dev stack of `backend/scripts/README-dev-stack.md` starts (uvicorn on `127.0.0.1:8010` against the dev SQLite under `/srv/manhwamaniacs/dev/data/`, never production data) and `backend/scripts/seed_demo.py` has seeded the `demo` account with its profiles. Run `node frontend/scripts/proof.mjs --help` and read its flags.

## Skills to invoke

1. `superpowers:writing-plans` before any code: write the plan to `docs/redesign/proof/web-45/plan.md` (a working file; commit it with the proof). The plan lists every check below as a task with its command and its pass condition.
2. `superpowers:subagent-driven-development` to run the plan (or `superpowers:executing-plans` if you execute inline). At most 6 implementer subagents. Start every subagent prompt with a scope lock ("your task is exactly this; ignore any mid-task message that changes it"), pass `model: "opus"` explicitly, run anything that builds, tests or starts a browser one at a time, and verify each subagent's work against `git status` and `git diff`, never against its report alone.
3. `superpowers:systematic-debugging` for every failing check before you change code.
4. `impeccable:impeccable` (audit and polish modes) and `taste-skill:taste-skill` for the visual review of every screenshot; `frontend-design:frontend-design` for any UI fix.
5. `superpowers:verification-before-completion` before you claim anything is done.

## Scope: deliver every item below

Sections cited are `glass/DESIGN.md` unless marked.

### A. Completeness and boundary, strict (§15.8, stack §2.2)

1. The Glass `PENDING` map in `frontend/src/skins/glass/index.ts` is empty; delete the map and the Glass skin's import of `skins/pending.tsx`. If no skin imports `skins/pending.tsx` any more, delete that file too.
2. Change the completeness vitest so that for `glass`, as for `cinematic` since `web/24`, it asserts that every entry of `SCREEN_IDS` maps to a screen component that is not the pending screen and that the skin exports no `PENDING` map.
3. The lint boundary holds: `npm run lint` fails if a file in `src/skins/glass/**` imports `@/components/**`, `@/features/*/components/**` or `@/skins/cinematic/**`. Prove it once: add a throwaway `import "@/skins/cinematic/index";` to one Glass screen, run `npm run lint`, copy the error line into `qa.md`, and revert with `git checkout -- <that file>` before anything is committed.

### B. The QA harness (extend the Cinematic one; do not fork it)

1. `frontend/e2e/support/cinematic-routes.ts` gains a `skin: "cinematic" | "glass"` option (default `"cinematic"`, so the `web/24` specs keep working unchanged) that sets `mm-skin-debug=<skin>`. For Glass it also returns, for each sheet route (`feature`, `featureByFollow`, `recap`, `circleMember`, `profileNew`, `profileEdit`), the base route and a `openSheet(page)` step that clicks the real trigger (a poster, a recap offer, a friend orb, the picker's add and edit buttons), because a Glass sheet route has two presentations: the hard-load full page and the sheet over the base (§15.2 sheet host). `setup` must redirect to `/login`; `readerLanding` is `/reader`. It throws if any `ScreenId` is missing.
2. `frontend/e2e/support/audit.ts` gains `audit(page, { pointer, skin: "glass" })` with the Glass rule set below, returning each violation with a CSS selector, the rule and the measured value. Live glass hosts are the elements `GlassSurface` renders with `data-tier` that register in `glass/budget.ts` (read `GlassSurface.tsx` for the exact attributes that mark a twin and a solid surface, and use them):
   - **G1 Console and network:** no `console.error`, no uncaught exception, no failed request except the ones a state deliberately provokes.
   - **G2 Headings:** exactly one `h1` outside `aria-hidden` and `inert` subtrees; after an in-app navigation, focus is on it (for a sheet route, on the sheet title); `document.title` is non-empty and differs between `ScreenId`s.
   - **G3 Names:** every `button`, `a[href]`, `[role=button|link|tab|switch|checkbox|radio|slider|menuitem|option]`, `input`, `select`, `textarea` and `[tabindex="0"]` has a non-empty accessible name.
   - **G4 Hit targets (§14.6):** at **both** pointers (Glass has no smaller fine-pointer size) every interactive element's hit box is ≥ 44 × 44 CSS px, with ≥ 8 px to the nearest other hit box unless both are cells of the same glass group (siblings under one bar-group host). Inline text links inside running text are exempt and listed.
   - **G5 No alpha text on glass (§2.1.2, §14.2):** every visible text node inside a live glass host has computed `color` alpha 1 and equals `onGlass` `rgb(242, 242, 247)` or `onTint` `rgb(255, 255, 255)`. Content twins, `wellOnGlass` wells (where `label2` is allowed, §2.1.2) and solid surfaces are exempt and listed.
   - **G6 Non-informational greys:** `label4` `rgba(235, 235, 245, 0.24)` and `g500` `rgb(86, 86, 95)` appear on text only inside a disabled control (`disabled` or `aria-disabled="true"` on it or an ancestor); `g600` `rgb(118, 118, 127)` never colours a text node.
   - **G7 Brighter fields (§2.1.8):** on the screens whose field opacity exceeds 20 % (Home, the hero enlargement, the image viewer, series detail, book page, the recap deck, the profile picker, Statistics, Wrapped, and Settings, You and admin screens under a mood whose own opacity exceeds 20 %: Horror 26 %, Fantasy 22 %, Default 30 %), no text node in the top 60 % of the viewport that sits directly on the field (no ancestor with a non-transparent background or a live glass host) computes to `label3` `rgba(235, 235, 245, 0.52)`.
   - **G8 Cover overlays (§7.8, §7.20, §14.2):** every element drawn over a cover image inside a poster or tile (tags, droplet, progress, star, follow bell, play orb) has its own backing with alpha ≥ 0.72.
   - **G9 Text size (§3.2):** no visible text node below 11 px computed `font-size`.
   - **G10 Images:** every `img` has `alt` (empty only when its accessible container already carries the title, or when it is decorative and `aria-hidden`).
3. Specs, each run with `--workers=1`, never inside the vitest gate: `frontend/e2e/glass-qa.spec.ts` (B, C, F, I), `glass-focus.spec.ts` (I3), `glass-motion.spec.ts` (G), `glass-signature.spec.ts` (H; if `web/26` already wrote a Glass signature spec, extend that file and keep its name), `glass-gate.spec.ts` (J), `glass-budget.spec.ts` (K), `glass-switch.spec.ts` (M).

### C. Physics and the contrast gate (§15.8 first two bullets, §2.1.7)

1. `npm run test -- src/skins/glass/physics` passes and asserts every §15.8 value: `project(0, 1000) ≈ 499`; `rubberband(100, 800, 0.55) ≈ 51.5`; `{ms: 520, bounce: 0}` → k 146.0, c 24.17; `{ms: 150, bounce: 0.14}` → k 1754.6, c 72.05; the rail snap of offset 310 at 900 px/s with stride 136 lands on 816; `tierFor(44) == T2`, `tierFor(240) == T4`, `tierFor(401) == T4` (T5 is never reached by size, §2.4.3; only the Massive objects declare `tier="t5"`); `dimFor(1.0) == 0.64`, `dimFor(0) == 0.22`, and 0.64 for a dark cover with one white patch (mean `l` 0.2, `lMax` 1.0); depth intensity at depth 3 is 0.54. Any value the test does not assert is added to it.
2. `node design/build.mjs --check` passes, and its `check-contrast.mjs` output lists every added case of §15.8 (clear glass, other tiers over white, backing discs, wells on sheets, T4/T5 bodies, cover overlays, ambient field, avatar glyphs, and both negative cases). Copy the output table into `qa.md`. A missing case is an open issue for the shared track (you do not edit `design/`).
3. **In the browser, the three worst cases:** with `page.route` fixtures (a chapter whose pages are solid `#FFFFFF`, generated in the browser with `OffscreenCanvas.convertToBlob`, and a Library list whose covers are the two white-dominant demo covers of §12.7), assert: the manga reader's top group has `--glass-dim` 0.64 and `--glass-grad-t` 40 over the white page, 0.72 under Increase Contrast; the dock's bar group over the white covers sits over the `edgeSoft` plateau `rgba(0,0,0,0.72)` (read the scrim element's computed background) with a dim between 0.22 and 0.64; the tinted action over the white page keeps `onTint` `#FFFFFF`. Screenshot each case and review it.

### D. The calibration comparison with Flutter (§15.8, §2.4.3)

1. Capture `/dev/glass-calibration` in `next dev` at 1440 × 900, DPR 1, with `?renderer=liquid`, into `docs/redesign/proof/web-45/calibration/web-liquid.png`, plus crops of the T2 44 px button and the T4 240 px menu at 4× nearest-neighbour zoom.
2. Take the newest Flutter calibration capture: `ls -t docs/redesign/proof/mobile-45/*calib* docs/redesign/proof/mobile-25/*calib* 2>/dev/null | head -1`. Compose the pair side by side with a Playwright `page.setContent` page (two `data:` images, labels "Web tier A" and "Flutter premium", no new dependency) into `calibration/side-by-side.png`. Count how many 16 px checker squares each rim bends at the T2 button and at the T4 menu on each client and record both counts in `qa.md`. A difference of more than one square is an open issue for the shared track naming the knob of §2.4.3 to change in `design/tokens/glass.json` (you do not edit it).
3. If no Flutter capture exists yet, record the item as blocked on `mobile/45` in `qa.md` with the web counts, and name it in the report: `release/01` must not start until both counts exist.

### E. Screenshots of every `ScreenId` (§15.8 Screenshots)

With `frontend/scripts/proof.mjs` (add any flag it lacks: `--skin`, `--jpeg` with quality 80, `--dpr`, `--sheet` for the sheet-over-base presentation), headless Chromium in the named session `web-45`, capture every route of B1:

1. At 1440 × 900 (DPR 1), 390 × 844 (DPR 3, touch) and 440 × 956 (DPR 3, touch), as JPEG quality 80, into `docs/redesign/proof/web-45/screens/<screenId>-<width>x<height>.jpg`; sheet routes also as `<screenId>-sheet-<w>x<h>.jpg`.
2. One snapshot per screen at 390 × 844 (DPR 3) for each of: **Reduce Motion** (`reducedMotion: "reduce"`), **Solid glass** (the OS path through a CDP session: `Emulation.setEmulatedMedia` with `features: [{ name: "prefers-reduced-transparency", value: "reduce" }]`), and **Increase Contrast** (`page.emulateMedia({ contrast: "more" })`), into `screens-a11y/<screenId>-{reduced,solid,contrast}.jpg`. Also once per screen through the in-app switches (Settings → Appearance: Reduce motion in this app, Solid glass, Increase contrast), checking that `html` carries `data-motion="reduced"`, `data-solid="on"` and `data-contrast="more"` and that each result matches its OS-path capture.
3. **Forced colours** (`page.emulateMedia({ forcedColors: "active" })`) and **Legible text** (Settings → Appearance) at 1440 × 900 into `forced-colors/` and `legible/`: glass is `Canvas` with a 1 px `CanvasText` border, the tinted action `ButtonText` on `ButtonFace` with a 2 px `Highlight` border, focus rings `Highlight`, and the field, caustic and glints gone; Legible text swaps every UI role to Atkinson Hyperlegible Next with +0.01 em tracking and nothing clips.
4. **States:** each screen's loading, empty, error and offline states that the contract defines (use `page.route` to delay or fail the request and `context.setOffline(true)`), at 1440 × 900 and 390 × 844, into `states/`.
5. **Both skins side by side:** capture every route with `skin: "cinematic"` at 390 × 844 (DPR 3) too, and compose `pairs/<screenId>.jpg` (Cinematic left, Glass right, one `page.setContent` composition per pair, JPEG 80), so the owner sees that the two skins are different apps on one data layer.
6. Review every image with `impeccable` and `taste-skill` against the contract and fix what is wrong: grey frosted cards where glass should refract, alpha text on glass, a bar label without its `edgeSoft` plateau, a clipped focus ring, glass inside a list or the strip, a field that glares, a lower screen that is not true black.

### F. Screen-reader mode and the reader's announcements (§4.11, §14.5)

With **Screen reader mode** on (Settings → Appearance; `html[data-sr="on"]`): toasts stay until dismissed and carry a close button; reader chrome never auto-hides; Wrapped does not auto-advance; voice previews do not auto-play; the dock never minimises. Independently of the switch: reader chrome never idle-hides within 30 s of a `keydown` or a Tab. From the accessibility tree (`page.locator("body").ariaSnapshot()` taken 100 ms after navigation, while reveals still run): headings expose their full text; toasts are `role="status"` inside the "Notifications" region (`alt+n` moves focus there), errors `role="alert"`; the manga reader announces "Chapter 144" on a chapter change and nothing on page changes; the scrub rail is a slider with `aria-valuetext="Page 18 of 40"`; a manga page with OCR text has the description "Page 18. Dialogue: …", without OCR "Page 18 of 40"; hidden chrome is `inert`; locked mode offers the visually hidden "Unlock controls" button on focus and the `u` key; swipe rows, reorderable rows and reaction strips offer their actions in the row's ⋯ menu; the dock stays a tab list with four tabs when minimised.

### G. Reduced motion and the motion-timings pass (§4.10, §4.11, §14.1, §15.8)

1. `glass-motion.spec.ts` runs every screen twice with reduced motion: once from the OS query alone (`reducedMotion: "reduce"`), once with the OS query off and the in-app switch on (`data-motion="reduced"`). On each screen: `document.getAnimations()` returns only the allowed ones (§14.1: progress indicators as static opacity pulses, the Liquid spinner's and the thinking orbit's 1.2 s pulses, and a user-started cruise), and every allowed one animates `opacity` only; `LetterReveal` and `TypedHeadline` show their full text at once with no caret and no glint; the ambient anchors do not move over 15 s; `--mm-light-angle` stays `135deg` after pointer moves; programmatic scrolls jump.
2. Walk every row of the §4.11 Reduce Motion table and the last column of all 116 rows of §4.10 by hand (or by spec where a spec can see it) and tick each in `qa.md`: for example Push and Pop a 200 ms cross-fade with the back swipe still tracking 1:1; Sheet present a fade + 16 px translate over 150 ms with no recession; Tab droplet cross-fades 150 ms; Minimise an instant swap; Rubber band a hard stop; Wave and Surface from depth off with a 150 ms fade together; Light follows the story a 200 ms cross-fade; Dim shift instant; Skin melt a 200 ms fade to black; Droplet reveal a 200 ms cross-fade with `logo.reduced`; Cruise ramp none; Panel camera a cut with a 120 ms cross-fade; Rain on glass off; Hold fill in 4 visible steps; Error shake none with the error text kept; celebrations end states with a 150 ms fade. Rows that exist only on Flutter (**Stack fan**, **Address drain**) are marked "n/a on the web" with the reason (§7.37: the web uses the back menu; §8.1: the web's `setup` redirects to `/login`).
3. **Motion-timings overlay pass.** In `next dev` (the overlay exists in development only), open it with `mod+shift+m` and trigger every web move of §4.10 at least once, at 1440 × 900 and the phone-only moves (dock, accessory, pull to refresh, swipe rows, back swipe) at 390 × 844 with touch. After each screen use `Copy log` and append the JSON to `docs/redesign/proof/web-45/motion-log.json`. Pass: no row turns `danger` (dropped frames, or an overrun of more than one frame past the planned settle). The VPS has no GPU, so headless Chromium rasterises in software: for every failing row, record a Performance trace (`page.tracing` or CDP `Tracing.start` with the `devtools.timeline` category) and read where the frame time goes. Script, style or layout cost is yours to fix now (typical: animating layout properties instead of `transform` and `opacity`, rebuilding a displacement map mid-motion, a React render per frame, a `backdrop-filter` whose map changes every frame). Raster-only cost is a software artefact: list those moves in `qa.md` under "Owner check on real hardware" with exact steps to reproduce them in desktop Chrome and on the Android flagship with the overlay on.
4. **Motion names (§15.8):** `node design/build.mjs --check` passes (the generated `MotionName` union is current), and a new vitest `frontend/src/skins/glass/motion-names.test.ts` reads `../docs/redesign/glass/DESIGN.md` (resolved from `process.cwd()`), extracts the 116 bold names of the §4.10 table, normalises both sides (lowercase, letters only) and asserts the union has exactly those names, and that `play()` throws in development for a name outside the union (`expect(() => play("Nope" as MotionName, …)).toThrow()`).

### H. Signature animations actually play (§10.1, §10.2, §15.8)

`glass-signature.spec.ts`, desktop 1440 × 900, a fresh browser context per test, signed in as `demo` with the first profile:

1. **Typing reveal on Home.** Navigate to `/`. 200 ms after navigation the greeting's 10th grapheme is still transparent (computed `color` alpha 0; the string is laid out in full from frame 0) even though route focus has moved to that heading (§8.0.8): focus must not skip it. The caret is present (2 px wide, 0.72 em tall, `iris400`). After `n × 50 ms + 40 ms + 200 ms` (`n` graphemes, spaces included) every grapheme is opaque; after `n × 50 + 3 × 1,060 + 350 + 200` ms the caret is gone (three blinks of 530 ms on and 530 ms off, then the 350 ms dematerialise). The heading's `aria-label` carries the full string from the first frame and the typed spans are `aria-hidden`.
2. **Skip rules.** A `pointerdown` on the headline completes it at once; a key press while focus is on the headline or on `document.body` completes it; focus arriving does not; navigating away completes it silently. After a skip the count never advances again.
3. **Once per session per profile per placement.** `sessionStorage['mm.glass.typed']` holds `"{profileId}:{placement}"` from the moment typing starts; a reload in the same tab shows the greeting at rest; a new tab types again.
4. **The other placements** type once each: Login "Welcome back", onboarding step 1 "Hi, {name}." (assert the 5th grapheme when the string is shorter than 10), the Wrapped cover "Your {year} in chapters", the recap deck heading "Previously on {title}". A headline longer than 48 graphemes types the first 48 and fades the tail in as one span over 200 ms.
5. **Letter reveal.** On `/`, a rail header (H3, `title2`) below the fold keeps its letters in the waiting state until it is 25 % in view; scroll it in; within `24 × (g − 1) + 345 + 100` ms (`g` graphemes, spaces take no time) every letter is at opacity 1, translate 0, blur 0 and scale 1; 120 ms after the last letter settles, the glint band crosses once over 500 ms. `sessionStorage['mm.glass.revealed']` records it; a second visit in the session shows it at rest. Scrolling three headers in at once animates at most two at a time. A heading over 60 graphemes reveals per word at 40 ms per word.
6. **Reduced motion:** both show their full text immediately; no caret, no glint.

### I. Accessibility pass (§14.2 to §14.10, §15.8 "Accessibility pass per cluster")

1. **Audit:** `glass-qa.spec.ts` runs `audit()` on every route of B1 at 1440 × 900 (fine) and 390 × 844 (coarse, `hasTouch: true, isMobile: true`), writing `docs/redesign/proof/web-45/audit/<screenId>-<viewport>.json`. A second pass at 720 × 450 with `deviceScaleFactor: 2` (the layout of 200 % zoom on 1440 × 900) asserts `document.documentElement.scrollWidth <= innerWidth` on every screen (§14.7; the members table scrolls inside its own container and is exempt).
2. **Contrast and colour (§14.2, §14.3):** C3 plus: every overlay on a cover sits on an opaque black backing; read, inactive, offline and "not for me" states dim by role, never by opacity (only disabled controls dim to 40 %); status pills carry their word; download states a glyph and a name; unread a dot and a bar; the 18+ badge "18+"; speaker tints an underline style; reactions their names; the machine light always with the sparkle and "suggested by AI" in the accessible name; people light always with an orb or a name; charts a summary sentence and "Show as table".
3. **Keyboard and focus (§14.4), `glass-focus.spec.ts`** (1440 × 900 and 390 × 844 with a keyboard): the first Tab shows the "Skip to content" `glassThin` capsule top-left and Enter moves focus to the `h1`; then Tab 60 times recording each focused element's rect and computed `box-shadow` and `outline`. Pass: every focused element shows the two-tone ring (2 px black inner ring, 2 px `iris300` `rgb(188, 176, 255)` at 2 px offset, the 6 px `rgba(188, 176, 255, 0.28)` glow; 3 px under Increase Contrast), unclipped on all four sides (an element screenshot with 8 px padding has ring pixels on each side); the element's centre returns itself or a descendant from `document.elementFromPoint`; no focused rect intersects the floating chrome bands (phone: top `safe + 60`, bottom `safe + 85`, `+ 56` with the accessory; desktop: the 76 px toolbar band), because `scroll-padding-block` keeps it clear; rails and grids take one tab stop each (roving tabindex); the sidebar is a `nav` landmark; after a route change focus is on the `h1` (sheet routes: the sheet title) and after a pop it returns to the element that pushed; sheets, menus, alerts, the palette and the back menu trap focus and return it on close. Settings → Shortcuts "Single-key shortcuts" off: every printable-character binding stops (letters with or without Shift, digits, punctuation), while arrows, Home, End, Page Up/Down, Space, Enter, Esc, Tab, Delete, Backspace, F-keys and every `mod+` or `alt+` combination keep working, and no shortcut fires while typing except `mod+k`, `mod+b` and Esc.
4. **Touch targets (§14.6):** audit rule G4 on every screen at both pointers.
5. **Text size (§14.7):** the 200 % pass of I1; the Legible text captures of E3; no text below 11 px (G9).
6. **Every gesture has an alternative (§14.8, §11):** for every row of §11 whose Mobile web or Desktop web column is not "n/a", perform the alternative in its last column (the button, menu item or key) and confirm it does the same thing; long-press menus are mirrored by `.` or `shift+F10` and the row's ⋯; hold-to-confirm always offers its explicit confirm button. List each row with pass or the fix commit.
7. **Haptics and sound (§14.9, §5.2, §6):** with Android Chrome emulation (a Pixel 7 device descriptor) and `navigator.vibrate` stubbed to count calls, only the seven events vibrate with their patterns (`stack.open` `[18]`, `toggle.on` `[10]`, `longpress.open` `[18]`, `follow.add` `[12, 60, 12]`, `download.fail` `[24, 50, 24]`, `streak.milestone` `[12]`, `error` `[24, 50, 24, 50, 24]`) and `localStorage['mm.haptics'] = "off"` stops all of them; on the iPhone and desktop descriptors nothing vibrates. UI sounds are off by default on a fresh device (Glass stores them per device in `localStorage['mm.glass.sounds']`, `web/39` A5), silent while narration or a soundscape plays, and never play for the typing or letter reveals; voice previews never auto-play with Screen reader mode on; every clip longer than 3 s has a visible stop control.
8. **Flashing (§14.10):** measure from the CSS and Motion timings and record: the caret blink (530 ms phases, 0.94 Hz), the source-health bead's single 120 ms dip, the streak flame's 5 Hz tip noise at 2 % of the flame height (motion, not a flash), the skeleton sheen (1,400 ms); nothing flashes more than three times in one second; parallax and tilt stay within ±6° (cards) and ±25° (light) and stop under reduced motion or with "Light follows the device" off.

### J. Content safety and the gate-close checklist (§14.11, §8.0.8)

`glass-gate.spec.ts` and a manual pass, on the dev stack only, at 390 × 844 (touch, so the dock's per-tab stacks exist) and again at 1440 × 900:

1. **Set up** a profile whose gate is open: follow one mature series from a working 18+ source, download one of its chapters, add a bookmark, read two pages (history), type a recent search for its title, open it in the Library tab's stack and switch to the Home tab, start cruise and the Rain soundscape in its reader, and trigger its recap so a "Recap ready" toast is pending. Narration: when the dev stack has a mature novel with narration, include it; otherwise record "narration not reachable on the dev stack" and point to the `purgeMatureLocal()` vitest that asserts narration stops.
2. **Close the gate** (Settings → Content) and check every item of the §14.11 checklist, each ticked in `qa.md`: (1) narration, cruise and the soundscape stop and the accessory leaves; (2) the "Recap ready" toast never appears; (3) every tab whose top route was mature is at its root; (4) the web back menu (`mod+\`) shows no mature level and `sessionStorage['mm.glass.stack']` has no `mature: true` entry; (5) recent searches typed with the gate open are gone, and so are the palette's recent items made while it was open; (6) no mature cover appears anywhere, including the image viewer and the ambient field, and every object URL made from a mature image was revoked; (7) Home, Statistics, Wrapped, the recap and the Circle opened offline (`context.setOffline(true)`) show their offline states, not old copies; (8) Downloads, its counts and the storage meter show none of it and say nothing about it; (9) reopening the gate brings the download back untouched (same bytes: compare the saved chapter's cache entry before and after); (10) an offline Library, an offline Sources directory, offline Collections, History, Bookmarks and the recap skip list show none of it. The service worker received `{ type: "gate-closed" }` and dropped its pages cache, while the saved-chapter cache `offlineCacheName(scope)` is untouched.
3. **Separately, switch to a gate-closed profile** and repeat checks 3 to 10.
4. **A deep link to mature content** on a gated profile (the reader URL, the series URL, a bookmark row) opens the object lens "This isn't available on this profile" with "Back home" and no title or cover.
5. **Share cards:** for a gate-open profile whose year is mostly mature (read three chapters of the mature series and one chapter of a non-mature one this year), render every share side (the Statistics stat cards and every Wrapped card that has one; card 11 has none) through `share-card.ts` with `CanvasRenderingContext2D.prototype.fillText` and `drawImage` wrapped by `page.addInitScript` to record every string and image URL drawn; assert that no mature series title, mature source name or mature genre word appears in the strings and no mature cover URL was drawn, and that nothing from the Circle is drawn.
6. **The 18+ gate itself (§7.25):** turning it on needs the 1,200 ms hold (the fill starts at 200 ms) or the explicit confirm button, which is visible for everyone; a double click on the hold never confirms.
7. **Clean-up:** unfollow the series, delete the download, remove the added history rows and bookmarks through their screens' own remove actions, close the gate on the demo profile if it was closed before, so the seed is as it was. Record the clean-up in `qa.md`.

### K. Performance budget (§15.7, §15.8 web gate)

`glass-budget.spec.ts` counts, in each moment below, the live glass elements through the budget registry (the development global `web/40` or `web/44` exposed from `glass/budget.ts`; if none exists, add `window.__mmGlassBudget = { glass, scrims, elements }` behind `process.env.NODE_ENV !== "production"`), and cross-checks against the DOM (`[...document.querySelectorAll("*")].filter(el => getComputedStyle(el).backdropFilter !== "none")` equals glass + scrims). Pass: glass ≤ the table's number and never more than two live glass layers stacked over one point.

| Moment (§15.7 table) | Viewport | Web elements at most |
|---|---|---|
| Library tab root with the Filters sheet open and an Undo toast (then a row menu instead of the toast) | 390 × 844 | 5 |
| Search open (the orb expanded) with a toast | 390 × 844 | 3 |
| Manga reader scrubbing (pointer held on the rail) with the magnifier, the seam chip, the hit lens (opened from a dialogue search result) and the reader settings sheet; then the same with guided view and Rain on | 390 × 844 | 6 |
| Novel reader with the listen row, a speaker chip and the Aa sheet | 390 × 844 | 5 |
| Desktop Library with the sidebar, the toolbar group, a toast, the bulk-selection toolbar, a window (series detail) and a menu | 1440 × 900 | 6 |
| Profile picker; onboarding; Wrapped | 390 × 844 | 1, 1, 2 |

Also check and record: the ambient field is one fixed element with three radial gradients and no `filter`; per-letter reveals stay within 60 graphemes and two at once; each skeleton's sheen is one gradient; the genre field stays within 24 bubbles and the Wrapped page pile within 200 bodies and both stop their frame loop at rest (count `requestAnimationFrame` callbacks from those modules over 2 s at rest: 0); rain runs only while the Rain scene plays and reader glass is visible; page samples reach the worker at most every 600 ms (≤ 17 `postMessage` calls to `page-tint.worker.ts` in a 10 s scroll) and panel detection shares that worker; displacement maps rebuild only at rest (no map build during a sheet drag or a dock droplet flight: instrument `liquidMap` calls); `deviceorientation` listeners exist only while a screen that uses tilt is visible; no file under `src/skins/glass/` decodes or prefetches reader pages itself (`grep -rn "decode()\|new Image(\|prefetch" frontend/src/skins/glass`: only engine calls). **Web gate (§15.8):** reuse `web/29`'s `frontend/scripts/glass-web-gate.mjs` (add a `--path` flag, default its gate scene `/dev/glass-shell?gate=1`, instead of writing a second script) and fling the phone Library (`--path /library`) with the nav row group, the dock group and the accessory for 10 s (CDP `Input.synthesizeScrollGesture`, 390 × 844, DPR 3) under a Performance trace; record the mean frame rate and dropped frames per second. Headless software rendering will not reach 120 Hz: record the numbers and put the check under "Owner check on real hardware" with the steps (Chrome on the Android flagship and desktop Chrome on the owner's display, `/library`, the motion-timings overlay on, the Performance panel recording a 10 s fling; pass is a mean within 5 % of the refresh rate and at most 2 dropped frames per second; on failure `glass/DESIGN.md` §15.8 names the §15.10 registration to add).

### L. The "Float" showcase set (§12.5)

1. **Composition route** (development only): `frontend/src/app/(preview)/dev/float/page.tsx` (a server component that calls `notFound()` when `process.env.NODE_ENV === "production"`) renders `frontend/src/skins/glass/dev/FloatFrame.tsx` inside `<div data-skin="glass">` with the Glass fonts from `skins/glass/fonts.ts`. It is rendered at a 1320 × 2868 viewport at DPR 1, so CSS px are frame px: the aurora field of §12.2 scaled to the frame (a vertical gradient `#0A0F1F` → `#000000`, and three radial blobs at 45 % opacity with no `filter`: `#8FD8FF` at (309, 1961) r 335, `#A99BFF` at (541, 2409) r 387, `#FF9ED8` at (206, 2633) r 284, each softened by a 232 px transparent tail, the §12.2 1024-canvas values × 1.289 horizontally and × 2.801 vertically); the caption at top 200 px, left 120 px, max width 1080 px, in Google Sans Flex `ROND 100`, `wght 660`, 112/118 px, tracking −0.02 em, Frost `#F5F7FA`; frame 3's sub-caption "31 named voices" under it at 56/64 px, `wght 520`, Frost at 72 %; then the **slab**: a `GlassSurface` `tier="t5"` 1080 × 2150 px at left 120 px, top 640 px (bleeding off the bottom), radius 88, a 1.5 px inner highlight `inset 0 0 0 1.5px rgba(255,255,255,0.28)`, shadow `0 60px 120px rgba(0,0,0,0.6)`, transformed `perspective(2400px) rotateY(-8deg) rotateX(4deg)`, holding the UI capture inset 18 px with radius 72. The capture arrives as an `<img id="capture">` whose `src` the script sets through `page.evaluate` to a `data:` URL, then waits for `document.fonts.ready` and the image's `decode()`.
2. **Script** `frontend/scripts/float-frames.mjs` (Node 22 + the installed `playwright`, no new dependency): first captures the five UIs from the running dev server at 440 × 956, DPR 3, touch, `mm-skin-debug=glass`, the gate closed on the demo profile, then composes each frame and writes PNGs. **No real series may appear** (§12.5, §12.7): Home comes from the Glass skin preview route `web/39` built (`/skin-preview/glass`, fed by the demo covers); the manhwa reader, novel + listen, Wrapped and Circle frames use `page.route` fixtures in `frontend/e2e/fixtures/float/` (a manifest over the demo pages of `brand/demo/pages/`; an invented two-paragraph novel chapter with its audio availability and cast; an annual payload; Circle members and activity), each copied from a real dev-stack response for its shape and then given invented titles from §12.7 ("The Ninth Regression", "Salt and Iron", "Moonlit Bakery") and the demo covers of `brand/demo/covers/`; every image-proxy request is answered with a demo cover chosen by a hash of its URL.
3. **The five frames**, 1320 × 2868 PNG, into `docs/redesign/proof/web-45/float/`: `float-1-home.png` "Every source. One shelf."; `float-2-reader.png` "Built for the long scroll." (the manga reader mid-chapter with the chrome shown); `float-3-listen.png` "Novels, read aloud." with "31 named voices" (the listen full player); `float-4-wrapped.png` "Your year in chapters." (the Wrapped cover card); `float-5-circle.png` "Read together." (the Circle with the second demo profile's activity). No 18+ content, no real profile names beyond the demo profiles. `release/01` adds them to the install page gallery (§12.6); name them in the report.

### M. Cross-skin switch in both directions through the debug row (§8.25.2, §8.2, stack §2.5)

`glass-switch.spec.ts`, desktop 1440 × 900, then again at 390 × 844 and again under reduced motion:

1. **Cinematic → Glass.** Start in Cinematic on `/library/collections` (a non-root route) with the motion-timings recorder on, a download queued, and the service worker controlling the page. Open `/settings/diagnostics?debug=1`, choose GLASS. Pass: the `SKIN RESTART` entry is under 1,500 ms; the app lands back on `/library/collections` (`sessionStorage['mm.skin.return']`); `html[data-skin="glass"]`; the Droplet reveal plays once (cold 1,200 ms; `sessionStorage['mm.skin.splash.glass']` set; the next in-app navigation does not replay it); the Glass `Shell` posted `{ type: "skin", skin: "glass" }`; the pages cache was dropped (`caches.keys()` before and after); the queued download resumes and completes.
2. **Glass → Cinematic.** From Glass's Settings → Diagnostics debug row, choose CINEMATIC. Pass: the melt runs (`Skin melt` in the motion log at 615 ms; reduced motion a 200 ms fade to black); `SKIN RESTART` under 1,500 ms; the return route is restored; Glass removed `mm.skin.splash.glass` before `location.replace`, so a later switch back plays the Droplet again; `{ type: "skin-changed", skin: "cinematic" }` reached the service worker.
3. **Offline fallback per skin:** after each switch, go offline and open an uncached URL: Glass serves `offline-fallback-glass.html`, Cinematic its own page.
4. **Nothing leaks across:** after each switch, no element of the other skin's primitives is in the DOM and the other skin's fonts were not fetched (network log).
5. `flags.glass_available` is still `false`, and the Glass skin cards, onboarding step 2's Glass option, the profile form's skin row and the palette's skin action still hide Glass (§8.0.8); `release/01` turns them on.

### N. Fix everything, then `qa.md`

Every failure found in A to M is fixed in the Glass skin (or in the shared data layer when that is where the fault is), one commit per fix, with the check re-run after the fix. Then write `docs/redesign/proof/web-45/qa.md`:

- a table with one row per check (section and item, command or method, result, the commit SHA of the fix when there was one);
- the audit summary per screen (0 violations is the target; any accepted exception listed with its reason and the contract section that allows it);
- the contrast-gate table and the three in-browser worst cases;
- the calibration counts (web and Flutter) or the blocked note;
- the motion summary (moves checked of 116, moves passing, the two Flutter-only rows, raster-only moves under "Owner check on real hardware" with reproduction steps, the web-gate numbers);
- the budget table with the measured counts;
- the gate-close checklist ticks and the clean-up record;
- the screenshot and Float inventory;
- open issues, each with the contract section it concerns.

## Out of scope here (do not build)

- `release/01`: flipping `flags.glass_available`, turning on the Glass surfaces it gates, deleting the debug row and the `mm-skin-debug` keys, the version bump and the ship.
- Any new feature, any change in `mobile/`, `backend/` or `design/` (report token or contrast gaps for the shared track), any change to the Cinematic skin except a shared-layer fix that a Glass check exposed (then rerun `web/24`'s specs for the touched screens).
- The device passes on the owner's iPhone and Android flagship (that is `mobile/45`'s checklist); the web lists its hardware checks in `qa.md`.

## File layout

```
frontend/src/skins/glass/index.ts                          PENDING map removed (A1)
frontend/src/skins/pending.tsx                             deleted when no skin imports it (A1)
frontend/src/skins/**/completeness*.test.ts                strict for glass (A2; keep the file web/00 made)
frontend/src/skins/glass/motion-names.test.ts              G4
frontend/src/skins/glass/physics/physics.test.ts           missing §15.8 values only (C1)
frontend/src/skins/glass/glass/budget.ts                   development global only if missing (K)
frontend/src/skins/glass/dev/FloatFrame.tsx                L1
frontend/src/app/(preview)/dev/float/page.tsx              L1
frontend/e2e/support/cinematic-routes.ts                   skin option and sheet steps (B1)
frontend/e2e/support/audit.ts                              Glass rule set (B2)
frontend/e2e/glass-qa.spec.ts                              B, C3, E, F, I1, I2, I4–I8
frontend/e2e/glass-focus.spec.ts                           I3
frontend/e2e/glass-motion.spec.ts                          G1, G2
frontend/e2e/glass-signature.spec.ts                       H (or web/26's file, extended)
frontend/e2e/glass-gate.spec.ts                            J
frontend/e2e/glass-budget.spec.ts                          K
frontend/e2e/glass-switch.spec.ts                          M
frontend/e2e/fixtures/float/                               L2 fixtures (invented names, demo art only)
frontend/scripts/proof.mjs                                 new flags only if missing (--skin, --jpeg, --dpr, --sheet)
frontend/scripts/float-frames.mjs                          L2
frontend/scripts/glass-web-gate.mjs                        K (web/29's script; the --path flag only)
frontend/src/skins/glass/**                                fixes (N)
docs/redesign/proof/web-45/                                plan.md, qa.md, audit/, screens/, screens-a11y/, forced-colors/, legible/,
                                                           states/, pairs/, calibration/, float/, motion-log.json
```

Skin files import only `@/features/**` (never `@/features/*/components/**`), `@/lib/**`, `@/services/**`, `@/stores/**`, `@/types/**` and their own `skins/glass/**`; the lint rule bans `@/skins/cinematic/**`.

## Acceptance criteria

- [ ] `frontend/src/skins/glass/index.ts` has no `PENDING` map, the completeness vitest asserts a real screen for every `ScreenId` in both skins, and the lint-boundary proof line is in `qa.md`.
- [ ] `physics.test.ts` asserts every §15.8 value (including `tierFor(401) == T4`); `node design/build.mjs --check` passes with every §15.8 contrast case listed; the three worst cases hold in the browser (dim 0.64 and `GRAD` 40 over white, 0.72 under Increase Contrast, the 0.72 plateau under the dock).
- [ ] The calibration side-by-side exists with both square counts within one square, or the item is recorded as blocked on `mobile/45` with the web counts.
- [ ] Screenshots of every `ScreenId` at 1440 × 900, 390 × 844 @3 and 440 × 956 @3 (sheet routes in both presentations), one Reduce Motion, one Solid glass and one Increase Contrast snapshot per screen, forced-colours and Legible-text captures, state captures, and a Cinematic/Glass pair per screen are in `docs/redesign/proof/web-45/`.
- [ ] The audit reports 0 violations on every screen at 1440 × 900 and 390 × 844, or each remaining one is listed in `qa.md` with the contract section that allows it; no horizontal page scroll at 200 % zoom.
- [ ] Keyboard: the Skip capsule is the first stop; every focused element shows the unclipped two-tone ring (3 px under Increase Contrast) and is never under a floating bar; rails and grids are one tab stop; route changes focus the `h1`, pops return focus, overlays trap and return it; the Single-key shortcuts switch behaves as §14.4.
- [ ] Every hit target is ≥ 44 × 44 px at both pointers with ≥ 8 px spacing or shared glass-group cells.
- [ ] Reduced motion (OS query, and the in-app switch alone) matches the §4.11 table and every last column of §4.10: only opacity pulses of progress indicators and a user-started cruise keep running; reveals show full text; the field, light and tilt are frozen.
- [ ] The motion log covers every web move of §4.10 (114 of 116; Stack fan and Address drain are Flutter-only), with no `danger` row except raster-only moves listed with traces for the owner's hardware check; the motion-names vitest matches all 116 names and `play()` throws on an unknown name in development.
- [ ] `glass-signature.spec.ts` passes: the Home greeting is still typing 200 ms after navigation despite route focus, skips on pointer and key but not on focus, types once per session per profile per placement; the other four placements type; a rail header waits for 25 % visibility and settles within `24 × (g − 1) + 445` ms with one glint; at most two reveals run at once; reduced motion shows both at once.
- [ ] Screen reader mode and the reader announcements behave as F.
- [ ] Haptics: only the seven Android-web events vibrate with their patterns, none with `mm.haptics` off, none on iPhone or desktop descriptors; UI sounds are off by default and silent during narration and a soundscape.
- [ ] The gate-close checklist passes all ten items for a gate closing and for a switch to a gate-closed profile; the deep-link lens shows no title or cover; share sides draw no mature title, source, genre or cover and nothing from the Circle; the seed is restored.
- [ ] The budget holds in every moment of the K table (≤ 5, 3, 6, 5, 6, and 1 / 1 / 2) with never more than two stacked glass layers; every other §15.7 rule has evidence in `qa.md`; the web-gate numbers are recorded with owner steps.
- [ ] The five Float frames exist as 1320 × 2868 PNG on the aurora field with the tilted T5 slab and the §12.5 captions, built only from demo art and invented titles.
- [ ] Cross-skin switches in both directions through the debug row stay under 1,500 ms, restore the return route, play the arriving skin's splash once, update the service worker and its pages cache, resume the queued download, serve each skin's offline fallback, and leak nothing of the other skin; `flags.glass_available` is still `false`.
- [ ] Cinematic is unchanged except for listed shared-layer fixes: `web/24`'s Playwright specs still pass for every screen a fix touched.
- [ ] `npm run typecheck`, `npm run lint` (0 errors, 0 warnings), `npm run test` (file and case counts at or above the floor plus the new tests), `npm run verify:reader` and `npm run build` (0 errors, 0 warnings) are green in `frontend/`; `node design/build.mjs --check` passes.
- [ ] Every earlier Glass spec (`e2e/glass-*.spec.ts` and `e2e/glass/*.spec.ts`) passes in the regression pass.
- [ ] `docs/redesign/proof/web-45/qa.md` exists with every part listed in N.

## Verification

**RAM guard (production shares this box).** Before every heavy command (a build, the vitest suite, the dev stack, `next dev`, a Playwright run) run `free -m` and read the `available` column of the `Mem:` row. If it is under 1024 MB, stop and report instead of running it. Never run two builds at once. Never run `next build` while `next dev` or a Playwright browser is running: stop them first. Run the Playwright specs one file at a time with `--workers=1`.

From `frontend/`:

```bash
free -m && npm run typecheck
free -m && npm run lint
free -m && npm run test
free -m && npm run verify:reader
free -m && npm run build
cd .. && node design/build.mjs --check && cd frontend
```

For the Playwright work, start the dev stack of `backend/scripts/README-dev-stack.md`, then in `frontend/`:

```bash
free -m && NEXT_PUBLIC_API_URL=/api BACKEND_INTERNAL_URL=http://127.0.0.1:8010 npm run dev -- -p 3010
# in a second shell, one spec at a time:
free -m && E2E_BASE_URL=http://127.0.0.1:3010 E2E_USERNAME=demo E2E_PASSWORD='<from README-dev-stack.md>' npx playwright test e2e/glass-qa.spec.ts --workers=1
# then glass-focus, glass-motion, glass-signature, glass-gate, glass-budget, glass-switch the same way
free -m && node scripts/float-frames.mjs --base http://127.0.0.1:3010
free -m && node scripts/proof.mjs --help
```

If you use `playwright-cli` for ad-hoc inspection, always pass a named session (`-s=web-45`): the default session is shared with other Claude sessions on this box.

`00-baseline.md` records lint and build at 0 errors and 0 warnings; they must stay there, and every test that passed in the baseline must still pass. This step changes nothing in `mobile/` or `backend/`: check each of your commits with `git show --stat --format= <hash>` (the parallel `mobile/45` session and the backend and shared sessions commit on the same branch, so never judge by the branch diff). If one of your commits touched them, revert that part and prove the baseline with `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze` (No issues found), `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter test` (all 2012 tests pass, or the current higher count) and `cd backend && .venv/bin/python -m pytest -q --no-header`, one at a time after the RAM guard.

**Regression pass over the earlier Glass specs.** After the last fix, run every Glass spec the track wrote, one file at a time: `ls frontend/e2e/glass-*.spec.ts frontend/e2e/glass/*.spec.ts` (`web/32`, `web/33` and `web/35` wrote theirs under `e2e/glass/`), then for each `free -m && E2E_BASE_URL=http://127.0.0.1:3010 E2E_USERNAME=demo E2E_PASSWORD='<from README-dev-stack.md>' npx playwright test <file> --workers=1`. Each must pass; record the counts in `qa.md`.

**Visual proof.** Everything in sections D, E and L lands under `docs/redesign/proof/web-45/`, captured headless at the exact sizes above. Stop `next dev` and the dev stack when the captures are done.

## Git

- Branch `feat/vps-slim-source-native`. Commit small and often: the strict completeness change; the harness extensions; the motion-names test; then one commit per fix (`fix(web-glass): label3 over the Home field in the rail meta`); the Float route and script; then the proof and `qa.md`. Stage your paths explicitly (`git add frontend/e2e/glass-qa.spec.ts …`, `git add docs/redesign/proof/web-45`), never `git add -A` or `git add .`, because the mobile, backend and shared sessions commit in the same checkout.
- No Claude or AI attribution anywhere: no `Co-Authored-By` line, no "Generated with" line, no AI author. Never commit secrets (the demo password stays in `README-dev-stack.md`, never in a spec; read it from the environment) or `.claude/`.
- Run `npm run build` (after `free -m`, with `next dev` stopped) before every push, then `git push origin feat/vps-slim-source-native:master` after each working step.
- Never edit `backend/connectors/`. Never touch production containers or `/srv/manhwamaniacs/{app,data}`. Do not deploy: Glass ships in `release/01`.

## Report back

Reply with:

1. Done items by section (A to N), and anything not done with the reason.
2. Any `ScreenId` that was still pending at the start and which step's scope you executed for it.
3. Paths: `docs/redesign/proof/web-45/qa.md`, the screenshot folders, the five Float file names (for `release/01`), the calibration side-by-side (or the blocked note).
4. Test counts: vitest files and cases before and after; each Playwright spec's pass count; lint, build, `verify:reader` and `build.mjs --check` results; the `free -m` available figure before each build.
5. Audit totals (violations found, fixed, accepted with reason); the number of fix commits.
6. The motion summary, the web-gate numbers, and the list of moves and checks for the owner's hardware pass, with steps.
7. The budget counts per moment, and the gate-close checklist result.
8. Open issues, each with its `glass/DESIGN.md` section, including any gap for the shared track (tokens, contrast cases, calibration knobs).

Next prompt file: `docs/redesign/prompts/release/01-glass-final-release.md` (it also waits for `docs/redesign/prompts/mobile/45-glass-qa-polish.md`).
