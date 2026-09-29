# Web foundation 01: Motion 13, dependencies, fonts and icons for both skins

## Goal

Give the web client (`frontend/`) the runtime pieces every later Cinematic and Glass step builds on. This step does four things:

- It moves the legacy UI from `framer-motion` 12 to `motion` 13.4.4 with no change in behaviour.
- It installs the pinned packages of the stack decision and both dependency ledgers, and proves they resolve cleanly and build.
- It proves, with a Vitest parity test, that `design/build.mjs`'s stdlib port of Motion's spring gives exactly the curves the installed `motion` gives.
- It adds each skin's fonts through `next/font/google` and each skin's `Icon` component, which reads `design/icons.json` and the glyph components that shared/02 generated.

Only the active skin's font faces may load: a Cinematic page never fetches a Glass face, and the reverse. The legacy look does not change.

## Read first

1. `docs/redesign/stack-decision.md` §3 ("Dependency changes", web line) and §4 risk 11 (dev-box memory).
2. `docs/redesign/cinematic/DESIGN.md`:
   - §2.7 (iconography: Phosphor 2.1.10; weights Light at 24, Regular at 20 and below, Fill for active; never Bold or Duotone; sizes 16 / 20 / 24 / 32; the core map; the 10 custom glyphs),
   - §2.8.4 ("Springs on each client" and "Test": the parity rule),
   - §3.1 (the four families and the exact `next/font/google` calls, CJK fallbacks), §3.4 (the three reading faces and the Hyperlegible option),
   - §15.2 rows `fonts.ts` and the "Packages" paragraph, §15.10 S9 and S13,
   - §15.11 (the ledger rows for `motion`, `@base-ui/react`, `embla-carousel-react`, `sonner`, `lenis`, `@use-gesture/react`, `@phosphor-icons/react`, each with its fallback).
3. `docs/redesign/glass/DESIGN.md`:
   - §2.7 (Regular at 22 default, Duotone for active at rest, Fill on press, Light for ornamental 48–64, Bold for dense 14–16; core map; custom glyphs),
   - §3.1 (Google Sans Flex with `ROND`, `GRAD`, `opsz`; Google Sans Code; Literata `preload: false`; Atkinson Hyperlegible Next never preloaded; Noto Sans CJK), §3.6 (Legible text),
   - §15.2 (the `fonts.ts` line and the Dependencies bullet), §15.10 G1 (physical springs), §15.11 (the resolution gate: `npm ci`, `npm ls --all`, `next build`; a failing package is replaced by its fallback, never forced).
4. `docs/redesign/inventory/00-decisions.md`, and `docs/redesign/inventory/web.md` §20 (MO1–MO22, the legacy motion that must keep working).
5. `docs/redesign/00-baseline.md`.
6. Upstream outputs (read, do not rewrite): `frontend/src/skins/{types,index,server}.ts`, `frontend/src/skins/cinematic/index.ts`, `frontend/src/skins/glass/index.ts`, `frontend/src/skins/pending.tsx` (web/00); `frontend/src/skins/{cinematic,glass}/tokens.generated.{css,ts}` (shared/00, shared/01); `design/icons.json`; `brand/{cinematic,glass}/glyphs/*.svg`; the generated glyph components in `frontend/src/skins/cinematic/icons/` and `frontend/src/skins/glass/icons/` (shared/02).

## Preconditions (stop and report if any fails)

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs
git branch --show-current                                   # feat/vps-slim-source-native
ls frontend/src/skins/server.ts frontend/src/skins/completeness.test.ts   # web/00
ls design/icons.json frontend/src/skins/{cinematic,glass}/icons/{roles.generated.ts,glyphs.generated.tsx}   # shared/02
ls frontend/src/skins/glass/tokens.generated.ts             # shared/01
grep -rln "framer-motion" frontend/src | wc -l             # 4 files today
```

## Skills to invoke

- `superpowers:writing-plans` first. Save the plan at `docs/redesign/proof/web-01/plan.md` and commit it with the first code commit.
- `superpowers:subagent-driven-development` to run it (or `superpowers:executing-plans` inline). Give subagents this file's path and their exact section. Check their work against `git diff`, never against their reports.
- `frontend-design`, `impeccable` and `taste-skill:taste-skill` for the specimen page (item 16) and the icon weight rules.
- `superpowers:verification-before-completion` before you claim anything is done.

## Scope, item by item

### A. Motion 13 and the pinned packages

1. Check `free -m` first; stop under 1024 MB available. Then, in `frontend/`:

   ```bash
   npm uninstall framer-motion
   npm install --save-exact motion@13.4.4 @base-ui/react@1.8.0 embla-carousel-react@8.6.0 sonner@2.0.8 lenis@1.3.26 @use-gesture/react@10.3.1 @phosphor-icons/react@2.1.10 fast-average-color@9.6.0
   ```

   `package.json` must list all eight with exact versions (no `^`, no `~`). Never use `--force`, `--legacy-peer-deps` or `overrides`. If a package fails to resolve against React 19.2.4, drop it and apply the fallback from its ledger row: `lenis` → native scrolling; `@use-gesture/react` → pointer-event pinch in `features/reader` (about 120 lines, written later by the step that needs it); `@phosphor-icons/react` → the Phosphor SVGs copied into `skins/{skin}/icons/`; `fast-average-color` → the mean of a 32 × 32 canvas decode (about 20 lines, later); `sonner` → a 40-line queue in the Glass `Toast`. Report any fallback you take. `motion` and `@base-ui/react` have no fallback: if either fails, stop and report.
2. Replace every `from "framer-motion"` with `from "motion/react"` (4 files, 7 import lines today; `grep -rn "framer-motion" src`). The API is the same (`motion`, `AnimatePresence`, `useReducedMotion`, `LazyMotion`, `m`, `MotionConfig`); change nothing else. Afterwards `grep -rn "framer-motion" src package.json` returns nothing.
3. Clean reinstall and tree check:

   ```bash
   free -m && rm -rf node_modules && npm ci
   npm ls --all > /tmp/npm-ls.txt; echo "exit $?"   # must be 0; grep -c "invalid\|missing\|UNMET" /tmp/npm-ls.txt must print 0
   ```
4. `frontend/next.config.ts`: add `optimizePackageImports: ["@phosphor-icons/react"]` inside `experimental`, next to `proxyTimeout` and `viewTransition`. Keep everything web/00 put there.

### B. Spring parity (cinematic §2.8.4, §15.10 S13; glass §15.10 G1)

5. `frontend/src/skins/cinematic/tokens.test.ts` (Vitest, node):
   - Read `src/skins/cinematic/tokens.generated.css` as text. For each spring token (today `release`, `sheet` and `scrub`), extract `--mm-spring-<name>: linear(…)` and `--mm-spring-<name>-ms: <T>ms`.
   - Take `{ visualDuration, bounce }` for the same name from `tokens.generated.ts` (read the file for the export's exact name).
   - Assert that `` `${T}ms ${curve}` `` equals `spring(visualDuration, bounce).toString()`, with `spring` imported from `"motion"`.
   - Also assert the settle times the contract states: release 800 ms, sheet 850 ms, scrub 500 ms, and that `spring(0.42, 0).toString()` starts with `"800ms linear(0, 0.0572, 0.1795"`.
6. `frontend/src/skins/glass/tokens.test.ts`: the same for every Glass spring. Glass's TS tokens are physical `{ stiffness, damping, mass }` (G1), so compare with `spring({ keyframes: [0, 1], stiffness, damping, mass }).toString()`. If the installed `motion` signature differs, read `node_modules/motion-dom` for the spring generator and adapt the call, not the expectation.
7. If a parity case fails, the generator in `design/` is wrong, and that is the shared track's file. Do not edit `design/` or any generated file. Stop, and report the failing keys with both strings.

### C. Fonts (only the active skin's faces load)

8. `frontend/src/skins/cinematic/fonts.ts`, exactly as cinematic §3.1 and §15.2 give them:

   ```ts
   export const bodoni = Bodoni_Moda({ subsets: ["latin", "latin-ext"], axes: ["opsz"], style: ["normal", "italic"], display: "block", preload: true, variable: "--mm-font-display" });
   export const archivo = Archivo({ subsets: ["latin", "latin-ext"], axes: ["wdth"], display: "swap", variable: "--mm-font-grotesk" });
   export const newsreader = Newsreader({ subsets: ["latin", "latin-ext"], axes: ["opsz"], style: ["normal", "italic"], display: "swap", variable: "--mm-font-newsreader" });
   export const plexMono = IBM_Plex_Mono({ subsets: ["latin", "latin-ext"], weight: ["400", "500", "600"], display: "swap", variable: "--mm-font-folio" });
   ```

   Add the CJK fallbacks, each with `display: "swap", preload: false` and variables `--mm-font-noto-serif-kr`, `--mm-font-noto-serif-jp`, `--mm-font-noto-serif-sc`, `--mm-font-noto-sans-kr`, `--mm-font-noto-sans-jp`, `--mm-font-noto-sans-sc` (`Noto_Serif_KR`, `Noto_Serif_JP`, `Noto_Serif_SC`, `Noto_Sans_KR`, `Noto_Sans_JP`, `Noto_Sans_SC`). Export two family strings for the alternate-title rule (§3.1: CJK display titles drop italic and tracking, `wght` 700, one size down):
   - `cjkDisplayFamily = "var(--mm-font-display), var(--mm-font-noto-serif-kr), var(--mm-font-noto-serif-jp), var(--mm-font-noto-serif-sc), serif"`
   - `cjkUiFamily = "var(--mm-font-grotesk), var(--mm-font-noto-sans-kr), var(--mm-font-noto-sans-jp), var(--mm-font-noto-sans-sc), sans-serif"`

   `next/font` gives each face a hashed family name, so the stacks must reference the variables, never the literal "Noto Serif KR".
9. `frontend/src/skins/cinematic/reading-fonts.ts`, exactly as §3.4:
   - `Literata({ axes: ["opsz"], style: ["normal", "italic"], display: "swap", preload: false, variable: "--mm-font-literata" })`
   - `Source_Serif_4({ axes: ["opsz"], style: ["normal", "italic"], display: "swap", preload: false, variable: "--mm-font-source-serif" })`
   - `Atkinson_Hyperlegible_Next({ style: ["normal", "italic"], display: "swap", preload: false, variable: "--mm-font-atkinson" })`

   Their variables go on `<html>` together with the core faces. The reason: Hyperlegible text swaps `--mm-font-text` to `var(--mm-font-atkinson)` on every screen (the generated `html[data-legible="on"][data-skin="cinematic"]` rule), so that variable must exist on every page. A `preload: false` face is fetched only when rendered text uses it, so no Literata, Source Serif or Atkinson request happens outside the novel reader unless Hyperlegible text is on. That meets §15.2's "loaded only by the novel reader's layout" in the way that matters (no download), and the network check under "Verification" proves it.
10. `frontend/src/skins/glass/fonts.ts`, exactly as glass §3.1:
    - `Google_Sans_Flex({ subsets: ["latin"], axes: ["ROND", "GRAD", "opsz"], display: "swap", preload: true, variable: "--mm-font-sans" })`
    - `Google_Sans_Code({ subsets: ["latin"], display: "swap", preload: false, variable: "--mm-font-mono" })` (glass §3.1 gives no `preload`; use `false`, because with `true` it would be a second preload on every page)
    - `Literata({ axes: ["opsz"], style: ["normal", "italic"], display: "swap", preload: false, variable: "--mm-font-serif" })`
    - `Atkinson_Hyperlegible_Next({ subsets: ["latin"], style: ["normal", "italic"], display: "swap", preload: false, variable: "--mm-font-legible" })`. Never preloaded: the server cannot know the profile's setting. It is fetched as soon as web/02's boot script stamps `data-legible="on"` and the generated `[data-skin="glass"][data-legible="on"]` rule points `--mm-font-sans` at it.
    - `Noto_Sans_KR`, `Noto_Sans_JP`, `Noto_Sans_SC` with `display: "swap", preload: false`, variables `--mm-font-noto-sans-kr`, `-jp`, `-sc`; export `cjkFamily = "var(--mm-font-sans), var(--mm-font-noto-sans-kr), var(--mm-font-noto-sans-jp), var(--mm-font-noto-sans-sc), system-ui, sans-serif"`.

    All of these families and axes exist in next 16.2.9's `font-data.json` (Google Sans Flex has `GRAD`, `ROND`, `opsz`, `slnt`, `wdth`, `wght`; `slnt` and `wdth` stay at their defaults, 0 and 100).
11. Wiring:
    - `skins/cinematic/index.ts` sets `fontClassName` to the space-joined `.variable` of every face in `fonts.ts` and `reading-fonts.ts`; `skins/glass/index.ts` does the same with `glass/fonts.ts`.
    - Both root layouts already apply `skins[id].fontClassName` (web/00).
    - `next/font/google` is an empty module outside the Next compiler, so Vitest cannot run it, and the completeness test imports the skin index files. Add `frontend/src/test/next-font-google.stub.ts`: every loader used in the repo (`Bodoni_Moda`, `Archivo`, `Newsreader`, `IBM_Plex_Mono`, `Literata`, `Source_Serif_4`, `Atkinson_Hyperlegible_Next`, the six `Noto_*`, `Google_Sans_Flex`, `Google_Sans_Code`, `Syne`, `DM_Sans`) as a named export returning `{ className: "", variable: "", style: { fontFamily: "" } }`. Alias it in `vitest.config.ts` (`resolve.alias["next/font/google"]`).

### D. Icons

12. Icon roles come from shared/02; this step writes no generator. shared/02 (`brand/build-glyphs.mjs`) already generated, per skin, `frontend/src/skins/{cinematic,glass}/icons/roles.generated.ts` (`ICON_ROLES`: role → `{ kind: "phosphor", name, component }` or `{ kind: "glyph", name }`; `type IconRole`; `ICON_RULES`: the skin's weight rules, sizes and hit sizes from `design/icons.json`) and `icons/glyphs.generated.tsx` (one component per custom glyph, `GLYPHS`, `type GlyphName`; Glass `Strata` takes `level`). Read both files before coding. Do not add a second role generator and never edit the generated files (a wrong role is shared/02's to fix; report it).
    - `frontend/src/skins/{cinematic,glass}/icons/phosphor.ts` (hand-written, one per skin): static named imports from `@phosphor-icons/react/ssr` of exactly the components that skin's `ICON_ROLES` names (the `component` field; confirm each export in `node_modules/@phosphor-icons/react/dist/ssr/index.d.ts`), exported as `PHOSPHOR: Record<string, Icon>` keyed by that `component` string. Never `import * as` the package or index it by a computed name: that defeats `optimizePackageImports` and ships all 1,512 icons. The SSR build has no context, so it works in server and client components alike.
    - `icon.test.ts` (per skin) asserts that every `kind: "phosphor"` entry of `ICON_ROLES` has its `component` in `PHOSPHOR` and every `kind: "glyph"` entry has its `name` in `GLYPHS`, so a role that shared/02 adds later fails the test until its import is added here.
13. `frontend/src/skins/cinematic/Icon.tsx`: `export function Icon({ name, size = 24, filled = false, label, className }: { name: IconRole; size?: 16 | 20 | 24 | 32; filled?: boolean; label?: string; className?: string })`, with `IconRole` from `./icons/roles.generated`.
    - Weight rule (§2.7): `filled` → `fill`; otherwise `size <= 20` → `regular`; otherwise `light`. A role whose `ICON_RULES` entry fixes a weight (the streak flame is Fill) uses that weight unless the rule gives `fill`. Glyph roles render the `GLYPHS` component with that `weight`.
    - The prop type makes `bold` and `duotone` unrepresentable.
    - Colour is `currentColor`.
    - With `label`: `role="img"` and `aria-label={label}`. Without: `aria-hidden="true"` and `focusable="false"`.
14. `frontend/src/skins/glass/Icon.tsx`: `export function Icon({ name, size = 22, state = "rest", tier = "default", level, label, className }: { name: IconRole; size?: number; state?: "rest" | "active" | "pressed"; tier?: "default" | "ornamental" | "dense"; level?: 1 | 2 | 3 | 4; label?: string; className?: string })`, with `IconRole` from `./icons/roles.generated` (`level` is passed to the `Strata` glyph for the `back-depth` role).
    - Weight rule (glass §2.7): `pressed` → `fill`; `active` → `duotone` (Phosphor draws the secondary layer at opacity 0.2); `tier: "ornamental"` → `light` (use sizes 48–64); `tier: "dense"` → `bold` (sizes 14–16); otherwise `regular`. Glyph roles have only `regular`, `duotone` and `fill` masters: `light` and `bold` map through `ICON_RULES`' `glyphFallback` (light → regular, bold → fill).
    - Same colour and accessibility rules as Cinematic. The Duotone → Fill cross-fade on press (120 ms) belongs to the IconButton primitive in web/26, not here.
15. Both Icon components are pure (no hooks), so server components can render them. The lint boundary from web/00 applies: each imports only its own skin's files and `@phosphor-icons/react/ssr`.

### E. Proof page (development only)

16. `frontend/src/app/(preview)/skin-preview/[skin]/specimen/page.tsx`. It calls `notFound()` when `process.env.NODE_ENV === "production"`, and renders on `#000000`:
    - **Cinematic.** Bodoni Moda Italic at 72 px with `font-variation-settings: "opsz" 72, "wght" 600` ("ManhwaManiacs"); the Archivo kicker `NOW SHOWING` (13 px, `"wdth" 62, "wght" 700`, uppercase, letter-spacing 0.16em); Newsreader 18 / 28 body ("The page turns and the city holds its breath."); Plex Mono 500 `CH 143 · P. 18 / 64`; a CJK line "나 혼자만 레벨업 · 俺だけレベルアップな件 · 我独自升级" in `cjkDisplayFamily` at `wght` 700; one line each in Literata, Source Serif 4 and Atkinson Hyperlegible Next; then every role in `ICON_ROLES` at 16, 20, 24 and 32, plus a filled row, in `#F3F0E8` (`ink.100`), each with its role name in 11 px Plex Mono beneath.
    - **Glass.** Google Sans Flex "Read the next chapter" at `wght` 300 / 500 / 800 and `ROND` 0 / 100; Google Sans Code `12:04 · 3.5×`; Literata and Atkinson lines; the same CJK line in `cjkFamily`; every role at 22 in the rest, active and pressed states, at 56 ornamental and at 16 dense, in `#F2F2F7` (`label1`).
    - The page is a proof surface only: no navigation from the app links to it.

## File layout

```
frontend/package.json, package-lock.json                      change (deps)
frontend/next.config.ts                                       change (optimizePackageImports)
frontend/vitest.config.ts                                     change (next/font/google alias)
frontend/src/**/<4 files importing framer-motion>             change (import path only)
frontend/src/test/next-font-google.stub.ts                    new
frontend/src/skins/cinematic/{fonts.ts,reading-fonts.ts,Icon.tsx,icons/phosphor.ts,tokens.test.ts,icon.test.ts}   new
frontend/src/skins/glass/{fonts.ts,Icon.tsx,icons/phosphor.ts,tokens.test.ts,icon.test.ts}                        new
(the shared/02 files icons/roles.generated.ts and icons/glyphs.generated.tsx are read, never edited)
frontend/src/skins/cinematic/index.ts, glass/index.ts         change (fontClassName only)
frontend/src/app/(preview)/skin-preview/[skin]/specimen/page.tsx                                                         new
docs/redesign/proof/web-01/plan.md                                 new
docs/redesign/proof/web-01/*.png, fonts-network.txt           new
```

## Acceptance criteria

- [ ] `package.json` pins `motion` 13.4.4, `@base-ui/react` 1.8.0, `embla-carousel-react` 8.6.0, `sonner` 2.0.8, `lenis` 1.3.26, `@use-gesture/react` 10.3.1, `@phosphor-icons/react` 2.1.10 and `fast-average-color` 9.6.0 exactly, and `framer-motion` is gone from `package.json` and `src/`.
- [ ] `npm ci` succeeds, and `npm ls --all` exits 0 with no invalid, missing or unmet peer lines.
- [ ] `npm run typecheck`, `lint`, `test` and `build` pass. Vitest counts are at least what you recorded before your first change, and no test that passed before fails.
- [ ] Both spring parity tests pass. Cinematic's settle times are 800, 850 and 500 ms.
- [ ] Legacy motion is unchanged. With no skin cookie, the legacy screens that animate (route cross-fade `route-in`, the command palette and profile switcher entrances, the reader chrome slide, MO1–MO22 in inventory §20) animate as before, and under `prefers-reduced-motion: reduce` they behave as before. You check this by viewing the before and after screenshots of `/library`, `/settings` and the open command palette (`mod+k`).
- [ ] Font isolation, from the network log described under "Verification":
  - on `/login` with `mm-skin-debug=cinematic`, the only skin faces fetched are Bodoni Moda (preloaded), with no Google Sans, Syne, DM Sans, Literata, Source Serif, Atkinson or Noto request;
  - with `mm-skin-debug=glass`, only Google Sans Flex, with no Bodoni, Archivo, Newsreader, Plex, Syne or DM Sans request;
  - on the specimen pages the faces each skin uses do load;
  - `curl` of a Cinematic page shows `<link rel="preload" … as="font">` only for Bodoni Moda's files, and of a Glass page only for Google Sans Flex's.
  If the other skin's preloaded face shows up (Next preloads every `preload: true` face imported anywhere in a layout's module graph), set `preload: false` on both Bodoni Moda and Google Sans Flex, rebuild, re-check, and report it. Bodoni's `display: "block"` still keeps a swap out of the letter reveal.
- [ ] Icons: `icon.test.ts` renders every role of both skins with `renderToStaticMarkup` and finds one `<svg`. The Cinematic rule gives `light` at 24 and 32, `regular` at 16 and 20, `fill` when filled. The Glass rule gives `regular`, `duotone`, `fill`, `light` and `bold` for rest, active, pressed, ornamental and dense. An unlabelled icon has `aria-hidden="true"`; a labelled one has `role="img"` and its `aria-label`. Every `ICON_ROLES` entry of both skins resolves through `PHOSPHOR` or `GLYPHS`, and no second role table or role generator exists (`ls frontend/src/skins/*/icon-roles.generated.ts frontend/scripts/icon-roles.mjs` finds nothing).
- [ ] Keyboard and hit targets: this step adds no interactive element (IconButton and its 44 px target arrive in web/04 and web/26). The specimen page has no focusable controls.
- [ ] Reduced motion: `Icon` and the fonts add no animation.
- [ ] Per-skin differences: Cinematic `Icon` defaults to 24 px Light and can never render Bold or Duotone. Glass `Icon` defaults to 22 px Regular with Duotone for active. Each skin's `<html>` carries only its own font variables.
- [ ] The completeness test from web/00 still passes (the font stub works).

## Verification

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs/frontend
free -m                                  # stop under 1024 MB available
npm run test 2>&1 | tail -5              # BEFORE changes: record Vitest files/cases
# … implement …
free -m && npm run typecheck
free -m && npm run lint                  # baseline: 0 errors, 0 warnings
free -m && npm run test
free -m && npm run build                 # never alongside next dev or another build
```

Mobile and backend: this step changes neither. Judge that by your own commits, never by the branch diff (mobile, backend and shared sessions commit on the same branch): `git show --stat --format= <hash>` for each of your commits must list no `mobile/` or `backend/` path. Only if one does, revert that part and prove the baseline still holds with its own commands, one at a time after the RAM guard: `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze` (baseline: No issues found), `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter test` (baseline: all 2012 tests passed) and `cd backend && .venv/bin/python -m pytest -q --no-header`.

**Network log and screenshots.** `frontend/scripts/proof.mjs` arrives in web/03, so use a one-off `/tmp/mm-fonts.mjs` (not committed). It loads a URL in headless Chromium through `createRequire("/srv/manhwamaniacs/dev/ManhwaManiacs/frontend/package.json")("playwright")`, sets the `mm-skin-debug` cookie from its first argument, and collects every response whose `request().resourceType() === "font"`. It then maps each font URL to its family by reading the `CSSFontFaceRule`s in `document.styleSheets` inside the page (`src` URL → `font-family`; next/font family names contain the face name, for example `Bodoni_Moda`), and prints `skin route family url` lines. Run it for `cinematic`, `glass` and `none` on `/login`, `/skin-preview/cinematic/specimen` and `/skin-preview/glass/specimen`, and save the output as `docs/redesign/proof/web-01/fonts-network.txt`.

Screenshots: start the dev stack of `backend/scripts/README-dev-stack.md` (uvicorn 127.0.0.1:8010, dev SQLite under `/srv/manhwamaniacs/dev/data/`), then `free -m && BACKEND_INTERNAL_URL=http://127.0.0.1:8010 npm run dev -- --port 3010`. Capture headless Chromium screenshots at 1440 × 900 and 390 × 844 of `/skin-preview/cinematic/specimen` and `/skin-preview/glass/specimen` (full page), plus legacy `/library`, `/settings` and `/library` with the command palette open, before and after the change. Save them in `docs/redesign/proof/web-01/`. Stop `next dev` before any `npm run build`. If Chromium is missing, run `npx playwright install chromium` once.

## Git

- Branch `feat/vps-slim-source-native`. Suggested commits: plan; the `motion` swap and pins (`package.json`, lock, 4 import changes); `optimizePackageImports`; the parity tests; Cinematic fonts; Glass fonts; the font stub; the two `PHOSPHOR` import maps; the two `Icon` components; the specimen page; proof. Push after each working step: `git push origin feat/vps-slim-source-native`.
- Stage explicit paths only (`git add frontend/package.json frontend/package-lock.json frontend/src/skins … docs/redesign/proof/web-01`), never `git add -A`: other sessions commit in this checkout.
- No Claude or AI attribution in any commit (no `Co-Authored-By`, no "Generated with" line). Never commit secrets, `.env*` or `.claude/`.
- `npm run build` must pass before every push.

## Guardrails

- Work in `frontend/` (plus `docs/redesign/proof/`). Do not edit `design/`, `brand/` or any generated file by hand. Never edit `backend/connectors/` or `mobile/`.
- Never touch production containers or `/srv/manhwamaniacs/{app,data}`.
- RAM guard: `free -m` before `npm ci`, every build, test run and dev server start. Stop under 1024 MB available. One heavy command at a time.

## Report back

1. Done items A–E, each with its commit hash.
2. Installed versions (`npm ls motion @base-ui/react embla-carousel-react sonner lenis @use-gesture/react @phosphor-icons/react fast-average-color`), and any ledger fallback taken.
3. Spring parity results (every key, pass or fail).
4. The font network summary per skin, and whether the preload fallback was needed.
5. Screenshot folder `docs/redesign/proof/web-01/`.
6. Test counts before and after, lint and build results, and the lowest `free -m` available figure.
7. Open issues.

Next prompt in the web track: `docs/redesign/prompts/web/02-foundation-restart-haptics-sound.md` (it also needs `shared/01` and `shared/03` done). Next in the global order: `docs/redesign/prompts/mobile/01-foundation-skin-engine-and-restart.md`.
