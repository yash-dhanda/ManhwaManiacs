# Review: shared track, files 00 to 05

Reviewed on 2026-09-29 against `docs/redesign/prompts-plan.json` (the shared track has exactly these six entries, orders 1, 3, 6, 9, 15, 16, group 8), `cinematic/DESIGN.md`, `glass/DESIGN.md`, `inventory/00-decisions.md`, `stack-decision.md` and `00-baseline.md`. All six files existed; none had to be created. Every fix below was applied in place. Nothing outside `docs/redesign/` was touched, and no state-changing git command was run.

## How values were checked

Numbers were recomputed on this box, not trusted:

- **Springs.** The Cinematic port rules were run against the installed `frontend/node_modules/motion-dom` 12.42.2 (`spring(visualDuration, bounce).toString()`). The Glass physical springs were recomputed: all 20 k, c and settle values match glass §4.2, and the `page` sample vector matches.
- **Contrast.** 14 of the shared/01 compositing vectors were recomputed with the stated model (the three worst cases, T2 and T4, the disc, the negatives, `ink.45` on `paper.2`, `scrim.head`), along with all 12 Cinematic avatar fields and all 6 mood grades. All match to ±0.02.
- **Route encoding.** Checked in Node and in Dart 3 from `/srv/manhwamaniacs/dev/flutter/bin/dart`.
- **Phosphor.** The Phosphor archive SHA-256 matched. The codepoint regex finds 1,512 icons in each of the six files. All Phosphor names in the 67-role table exist. The `@phosphor-icons/react` 2.1.10 export names were read from `dist/ssr/ArrowLeft.d.ts`.
- **Pinned versions exist.** npm: `oslllo-svg-fixer` 6.0.1, `fantasticon` 4.1.0, `@resvg/resvg-js` 2.6.2, `sharp` 0.34.5, `fontkit` 2.0.4, `ffmpeg-static` 5.3.0. pub.dev: `flutter_launcher_icons` 0.14.4, `flutter_native_splash` 2.4.8, `flutter_dynamic_icon_plus` 1.4.1, `gaimon` 1.5.0. apt candidates: `sox` 14.7.0.9 and `ffmpeg` 8.0.1.
- **Font commit.** The pinned google/fonts commit `23e54b5…` answers HTTP 200 for Bodoni Moda, IBM Plex Mono SemiBold and Google Sans Flex.
- **Legacy CSS.** `frontend/src/app/globals.css` was read for the legacy `@theme` and `:root` definitions.
- **Counts against DESIGN.** Screens 35, sheet ids 29, settings slugs 20, haptic events 47 + 43, sound events 31 + 21, Cinematic colours 81, durations 65, type roles 23 and 18, motion names 38 and 116, Glass layout 23, curves 17, thresholds 33, Glass cue lengths 5,682 ms and Cinematic cue lengths 3,740 ms. All were checked. The Glass colour and physics counts were wrong (see shared/01).

## Rule compliance (all six files, after fixes)

| Rule | 00 | 01 | 02 | 03 | 04 | 05 |
|---|---|---|---|---|---|---|
| Goal, Read first with exact paths, item-by-item scope | yes | yes | yes | yes | yes | yes |
| Skills: writing-plans, subagent-driven or executing-plans, impeccable, taste-skill, frontend-design, verification-before-completion | yes | yes | yes | yes | yes | yes |
| File layout per stack-decision §2.1–2.3 | yes | yes | yes | yes | yes | yes |
| Acceptance checklist: reduced motion, keyboard, 44 pt hit targets, per-skin difference | yes | yes | yes | yes (N/A stated) | yes | yes |
| Exact verification commands (lint, build, analyze, test with the Flutter path; backend pytest) | yes (fixed) | yes (fixed) | yes (fixed) | yes (fixed) | yes | yes |
| Visual proof at 1440 × 900 and 390 × 844 under `docs/redesign/proof/<step>/` | added | added | added | added | yes | yes |
| RAM guard, one build at a time | yes | yes | yes | yes | yes | yes |
| Git: small commits, push, no AI attribution, no secrets or `.claude/`, explicit `git add` | yes | yes | yes | yes | yes | yes |
| No `backend/connectors/`, no production | yes | yes | yes | yes | yes | yes |
| Dependencies stated with a stop-and-report precondition | none needed | added | added | added | added | yes |
| Report back plus next prompt file (checked against plan order) | yes | yes | yes | yes | yes | yes |
| No TBD, "etc." or "as appropriate" | fixed ("and so on") | yes | yes | yes | yes | yes |

## Findings and fixes per file

### shared/00: contract, Cinematic tokens, generator

1. **Critical: the spring port did not reproduce Motion.** The file specified a "5 ms backward difference" velocity and printed x(T) for every sample. The installed `motion-dom` uses the analytic velocity, and it returns exactly `1` for any sample where rest already holds. As a result, every string differed from Motion in its tail (`…0.9993, 0.9995)` against `…1, 1)`), and web/01's full-string parity test would have failed. The underdamped vector was also wrong: `{400, 0.3}` is T 650, n 22, `linear(0, 0.0676, 0.2212, …`, not T 700, n 23. **Fix:**
   - Velocity is now the analytic derivative, and done samples print `1`.
   - The file adds a `motionSpring()` export.
   - All five vectors are corrected, with both head and tail.
   - A scratch parity command against the installed `motion-dom` was added, plus an acceptance box.
   - The corrected rules were verified byte-identical for 126 `{ms, bounce}` pairs.
2. **Query encoding differed between clients.** Dart's `Uri(queryParameters:)` keeps `~` and encodes `*`, while `URLSearchParams` does the opposite: `a~b*c` became `a~b%2Ac` against `a%7Eb*c`, verified with Dart. **Fix:** the Dart builder now uses a 12-line WHATWG form encoder. A seventh vector, `discover({ q: "a~b*c é" })` → `/search?q=a%7Eb*c+%C3%A9`, was added to the node and Dart tests.
3. **The legacy collisions conflicted with web/00 and would have broken legacy colours.**
   - shared/00 told web/00 to delete ten keys from the legacy `@theme` block. web/00 instead imports the generated theme first, keeps the legacy block, and bridges per skin in `legacy-bridge.css`.
   - The literal fallbacks `#F85149`, `#3FB950` and `#D29922` would also have frozen colours that legacy re-points per theme through `:root { --color-danger: var(--mm-danger) }`, where `--mm-danger` is `#ef4444` or `#B91C1C` in other themes.

   **Fix:** the three fallbacks are now `var(--mm-color-danger, var(--mm-danger, #F85149))` and the same pattern for success and warning. The deletion instruction and its hand-off are replaced by web/00's bridge strategy, and the acceptance and report were updated.
4. **The `type-dropcap` optical size was wrong.** The file fixed it at `"opsz" 96`, while cinematic §3.5 says `opsz = min(size, 96)`. **Fix:** `font-optical-sizing: auto; font-variation-settings: "wght" 800`. The axis clamps at 96, so this is exact.
5. **"Nine generated files" was wrong.** The layout lists eight. The acceptance and commit plan are fixed.
6. **"Dart value `about`, and so on" was vague.** It now reads: one value per slug, camelCase, with examples.
7. **Proof, backend and verification.** The proof SVG is now captured with headless Chromium at 1440 × 900 and 390 × 844, with the Chromium install fallback from shared/04. A backend pytest line was added for when `backend/.venv` exists.

### shared/01: Glass tokens, haptics, motion names, contrast

1. **The tier snap contradicted DESIGN.** The file said `[36, 57, 97, 401]`, copied from the plan. Glass §2.4.3, §2.8.4 and §15.1 all say `[36, 57, 97]`: T5 is never reached by size, and §15.8 checks `tierFor(401) == T4`. DESIGN wins. **Fix:** Read first, item 1 and the generated Dart test were updated, with the reason stated.
2. **The Glass colour list was incomplete.** It said 131 rows and omitted `backingDisc` (0.60), `coverBacking` (0.86) and `coverDisc` (0.72), which §2.8.1 defines and §15.8 reads from `glass.json`. **Fix:** the three keys were added, the count is now 134 plus 12 glyph colours (146 keys), and the contrast cases use these token keys. The state-colour rule accepts `color.backingDisc`.
3. **Physics was said to have 19 keys; §2.8.5 has 21.** `magnetPull`, `projectionCap`, `impactMinInterval` and `rubberBandChapterC` were missing from the count. **Fix:** the count is 21, and there is now a rule to store each row's Web CSS column number, never the prose. For example `doubleTapWindow` 280 and `doubleTapSlop` 24, `imageDismiss` 180 and `imageDismissVelocity` 800, `streakAtRiskHour` 20.
4. A precondition block for shared/00 was added, along with the proof PNGs, the backend line, and cross-slice hand-offs for web/25 and web/01 (below).

Verified correct and unchanged: the 20 springs, the curve forms, the 15 AHAP patterns (including the `rise1–4` and `swell` arithmetic), the 90-event haptic map, the 7 web vibrations, the 28 cues and the 52-event sound map against glass §5.2 and §6, the four accessibility override blocks against §4.11, and the focus ring.

### shared/02: icon sets and custom glyphs

1. **Two font sources for one mark.** shared/02 downloaded Bodoni Moda from google/fonts `main`, while shared/04 downloaded it again from the pinned commit into `.cache`. **Fix:** shared/02 now downloads from the pinned commit `23e54b5…` and commits `OFL-BodoniModa.txt` and `OFL-IBMPlexMono.txt`, and shared/04 reads the committed files.
2. **Deprecated Phosphor React export names.** `component: "ArrowLeft"` is `@deprecated Use ArrowLeftIcon` in 2.1.10. **Fix:** names now carry the `Icon` suffix and are imported from `@phosphor-icons/react/ssr`.
3. **The Glass `mm-mark` glyph did not match the brand geometry.** Its vertex heights were 98 and 186, where shared/05's 1024 centrelines divided by 4 give 96.5 and 184.5. **Fix:** the glyph uses the exact ÷ 4 geometry, and shared/05 gains a 2 % render comparison.
4. **Role extension had no owner.** The rule "a screen adds a role here" had later tracks editing a shared-track file with no procedure. **Fix:** this is now one sanctioned edit, with explicit `git add` paths and `brand/check.mjs`.
5. The hand-off to web/01 now states the duplicate-generator conflict (below). A precondition, proof PNGs and the backend line were added.

### shared/03: UI sounds and soundscape audio

1. **An unfulfilled claim.** The file said "web/44 and mobile/44 run `trim-loop.mjs --strict` before they ship", but neither does. They ship on procedural layers, and `--strict` would block them until the owner delivers the recordings. **Fix:** the file now states that nothing calls `--strict` and that the missing list is the owner's to-do.
2. A precondition was added that checks the cue counts (13 and 28) in the token files, along with the proof PNGs, an acceptance box and the backend line.

Verified correct and unchanged: all 13 Cinematic and 28 Glass cue lengths and peaks against the §6 tables, the 384 KB budget arithmetic, the 545,472-byte Glass total behind the 320 KB conflict, the eight loop ids, the 18 layer names, the sox and ffmpeg candidates, and free disk (13 GB).

### shared/04: Cinematic brand, platform icons, demo art

1. **Two monogram constructions.** `mark.mjs` recomputed what shared/02's `monogram.mjs` had already written to `monogram.json`. **Fix:** `mark.mjs` reads `monogram.json`. `brand/lib/fonts.mjs` returns the committed Bodoni Moda files, and `.cache` holds only Archivo. The Dart paths are generated from `monogram.json`'s commands.
2. **The SideStore screenshot names disagreed with backend/07's `_SHOWCASE`.** **Fix:** `front-03-novels-read-aloud.png` and `front-04-year-in-chapters.png`.
3. **Line ranges were off.** Cinematic §12 is lines 4156–4210 (the file said 4154–4207).
4. A precondition for shared/02 and shared/00 was added, along with an exact hand-off to web/06 (below) and an owner-facing open issue: the new icon, the `Maniacs` label, the native frame, the favicon, the PWA icons and the manifest reach legacy users on the next deploy and iOS build, before the flip. The plan places them here, and release/00 only re-checks the manifest.

### shared/05: Glass brand, alternate icon, art intake

1. **Line ranges were off.** Glass §12 is lines 3904–3975 (the file said 3889–3960).
2. **New Decision 11: `ic_stat_mm` stays Cinematic's.** Glass §12.6 calls it both "the column silhouette" and "shared with Cinematic". An acceptance check now proves that no Glass `ic_stat` file exists.
3. **New Decision 12: rights per skin.** Cinematic §8.7 accepts only drawn art (own work or commission), while glass §12.7 also accepts generated drafts. `intake.mjs` now writes Cinematic outputs only from drawn masters, `--check` names each exception, and the scratch intake proof tests both paths.
4. An acceptance check was added that the Glass `mm-mark` glyph from shared/02 matches `mark.json` ÷ 4. The hand-off to mobile/39 was corrected (below). The report now lists twelve decisions.

Decision 1 (iOS name `AppIcon-Glass` instead of the plan's `GlassIcon`) stands: glass §12.2 names `AppIcon-Glass` and the asset-catalog method.

## Slice against its neighbours

**Coverage.** Every item in the six plan scopes is assigned to exactly one file and section. The TRACK RULE, the contract, the tokens, the generator, `--check` and CI, the lint, the self-checks, the Glass tokens, the AHAP assets, the motion unions, the contrast gate, the icons, the glyph fonts, the role tables, the cues, the loops, the Glass intake, the Cinematic and Glass masters, the platform icons, the native frame, the manifest, the install fonts, the demo art, the SideStore fields, the alternate-icon assets and the art intake are all covered. The consumers also match: mobile/02 declares the AHAP and sound assets, mobile/03 declares the eight icon font families and bans `phosphor_flutter`, web/02 checks for the `.ogg` and `.m4a` files, backend/07 serves the soundscapes, fonts and both Glass path shapes, mobile/06 uses `CineMarkPaths`, web/29 uses `GLASS_MARK` and `SKIN_FAVICONS`, web/44 uses `droplets.webp`, and release/01 applies `icon-registration.md`.

**Resolved inside this slice** (conflicting or duplicated instructions):
- shared/00 against web/00: the legacy `@theme` strategy (fix 00-3).
- shared/02 against shared/04: the Bodoni Moda source and the monogram construction (fixes 02-1 and 04-1).
- shared/02 against shared/05: the Glass `mm-mark` geometry (fix 02-3, check 05-4).
- shared/04 against backend/07 and release/00: the Front pages file names (fix 04-2).
- shared/03 against web/44 and mobile/44: `--strict` (fix 03-1).

**For the reviewers of the other files** (not edited here, because those files belong to other slices):

| File | Problem | Suggested fix |
|---|---|---|
| web/01 §B item 6 | The Glass parity test compares CSS `--mm-spring-*` strings with Motion's `spring({stiffness, damping, mass}).toString()`. Glass CSS is glass §15.1's own curve: 60 samples over a 0.01 ms settle time (`page` gives `615ms`). Motion prints `800ms linear(0, 0.0541, …` with 27 samples, so the test fails by design. | Assert stiffness and damping against `(2π/d)²` and `4π(1 − b)/d`, and compare each CSS sample with `spring({keyframes: [0, 1], stiffness, damping, mass: 1}).next(t).value` at the same `t`, within ±0.0005 (checked: the worst gap over all 20 springs is 0.00035). This is written into shared/01's hand-off. |
| web/01 §D item 12 | A second generator (`frontend/scripts/icon-roles.mjs`, `icon-roles.generated.ts`) duplicates shared/02's `icons/roles.generated.ts` and its `IconRole` type. It also says the glyphs live in `./icons/index.ts`, but they are in `icons/glyphs.generated.tsx`. | Generate only the static imports keyed by shared/02's `component` names (the `…Icon` names), and import `IconRole` from shared/02's file. Written into shared/02's hand-off. |
| web/06 §13 favicon | It uses `apple: "/apple-touch-icon.png"`, but the file is at `/icons/apple-touch-icon.png` (shared/04 Decision 6, `APPLE_TOUCH_ICON`). No web step wires `APPLE_STARTUP_IMAGES`. | Use the `brand.generated.ts` constants and add `appleWebApp: { capable: true, statusBarStyle: "black", startupImage: APPLE_STARTUP_IMAGES }`. Written into shared/04's hand-off. |
| web/25 `tierFor` | Uses `97–400 → t4`, `> 400 → t5` with `[36, 57, 97, 401]`. This contradicts glass §2.4.3 and the §15.8 check `tierFor(401) == T4`; mobile/25 is already correct. | Use `≥ 97 → t4` and the generated `glass.snap` `[36, 57, 97]`. |
| mobile/39 preconditions | Greps `AndroidManifest.xml` and `project.pbxproj` for the Glass aliases and names "from shared/05". shared/05 deliberately registers nothing; release/01 does. | Read the names from `brand/glass/icon-registration.md`, and expect the greps to print nothing. Written into shared/05's hand-off. |
| backend/07 `@font-face` | Declares Archivo `font-weight: 100 900`. shared/04 fetches the `wdth 62..100, wght 400..800` subset. | Declare `400 800` (Bodoni Moda `400 900` is correct). Minor. |

**Owner call to surface:** the brand assets that change before the flip (see shared/04, point 4).
