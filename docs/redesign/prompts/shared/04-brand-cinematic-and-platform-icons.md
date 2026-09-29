# Shared 04: Cinematic brand masters, the shared platform icons, the native frame and the demo art

## Goal

Draw the Cinematic brand ("Programme": a film-magazine masthead) as reproducible code and ship every platform asset that depends on it. You will build the SVG masters in `brand/cinematic/` (the one-line masthead wordmark cut from Bodoni Moda outlines with its Oxford rule, the stacked lockup, the `mm-mark` monogram with its Subtitle Yellow intersection on the 1024 canvas, the single-colour versions, the simplified favicon pair and the notification icon `ic_stat_mm`), one export script that renders every PNG the three platforms need (iOS 1024 opaque, iOS 18 dark and tinted, Android adaptive foreground, background and monochrome, `ic_stat_mm` in five densities, the web favicon set, PWA icons, four black iOS startup images and the 1200 × 630 Open Graph image), the `flutter_launcher_icons` 0.14.4 and `flutter_native_splash` 2.4.8 configuration for the plain black native frame that both skins share, the home-screen label `Maniacs`, the web app manifest, the self-hosted Bodoni Moda and Archivo subsets for the public install page, and a procedural demo art set (24 covers and 40 webtoon pages made only from shapes and type) that the previews, screenshots and the edition preview fixture use instead of anyone's real art. A check script proves sizes, alpha and safe-circle fit. The splash choreography itself is not part of this step (it is code in web/06 and mobile/06); Glass's brand is shared/05.

## Read first

Read these before planning. Where a value is copied below the section is cited; the DESIGN files win if anything here disagrees, except where "Decisions this step makes" says otherwise and why.

1. `docs/redesign/prompts-plan.json`, the entry whose `path` is `docs/redesign/prompts/shared/04-brand-cinematic-and-platform-icons.md` (the binding scope) and the TRACK RULE in the `shared/00` entry.
2. `docs/redesign/inventory/00-decisions.md` (all: dark only, `#000000`, the name stays, every brand asset is new, flagship-only, honour reduced motion).
3. `docs/redesign/stack-decision.md` §2.1 (`design/` is the single source; generated-file header convention), §2.2 and §2.3 (where web and Flutter files live), §3 ("Release model": nothing ships to users until the flip; the legacy skin still runs), §4 risk 11 (RAM).
4. `docs/redesign/cinematic/DESIGN.md`:
   - §12.1 to §12.7 (lines 4156 to 4210): the masthead idea, wordmark and monogram geometry, single-colour versions, `ic_stat_mm`, minimum sizes, the app icon, display name, web icons and manifest, SideStore fields, the splash table (read it so the masters fit the choreography), voice, the "Front pages" and OG layout, the asset pipeline;
   - §2.1.1 and §2.1.2 (`color.paper.0` `#000000`, `color.ink.100` bone `#F3F0E8`, `color.spot` `#F4D03F`, `color.spot.glow` `rgba(244,208,63,0.35)`), §2.1.4 (the 13 eased scrim stops and `scrim.gutter`), §2.1.5 (the duotone matrix and the fallback duo `#B8B2A4`), §2.6 (`rule.oxford` 3 + 2 + 1 px), §2.7 (the `mm-mark` glyph box x 58 to 198, y 68 to 188 on the 256 grid), §3.1 (Bodoni Moda axes `opsz` 6 to 96 and `wght` 500 to 900 used; Archivo `wdth` 62 to 125, `wght` 100 to 900);
   - §8.2 (the native layer: a plain `#000000` frame with no mark, owned by neither skin), §8.30.3 (the edition preview fixture paragraphs "Fixture" and "Build context": `design/previews/covers/01.webp` to `06.webp`), §8.34 (the install page and its four cover lines), §15.2 (the "Web app manifest" paragraph), §15.3 (packages line), §15.5 (the `GET /app/fonts/{file}.woff2` row), §15.10 ("Owner calls": the home-screen label), §15.11 (ledger rows `flutter_launcher_icons`, `flutter_native_splash`, `@resvg/resvg-js`).
5. `docs/redesign/glass/DESIGN.md` §12.3 (the shared native frame: `android_12` with `brand/splash/transparent-288.png`), §12.6 (the OG image and install page are shared and skin-neutral), §12.7 (the demo covers and demo pages brief: counts, sizes, palette spread, white-dominant covers, speech bubbles, white panels, near-black splash pages), §15.6 rows "Native splash", "App icon", "PWA manifest, startup images, OG image, install page".
6. `docs/redesign/inventory/capabilities.md` §23 (app distribution: `/app/source.json`, the install page, `/app/media/{name}`), `docs/redesign/inventory/web.md` §2.10 row S4 (the offline fallback shows `/icons/icon-192.png` at 72 px, so the new icon must keep that path), `docs/redesign/inventory/mobile.md` row S02 (splash).
7. `docs/redesign/00-baseline.md` (green baseline: frontend lint and build 0 errors 0 warnings; `flutter analyze` clean; `flutter test` 2012 passed).
8. Code to read, not rewrite: `frontend/src/app/manifest.ts`, `frontend/src/app/layout.tsx` (or `frontend/src/app/(app)/layout.tsx` if web/00 has moved it; it references `/icons/icon-192.png` and `/icons/apple-touch-icon.png`), `frontend/public/sw.js` lines 45 to 55 (precaches `/icons/icon-192.png` and `/icons/icon-512.png`), `mobile/pubspec.yaml`, `mobile/android/app/src/main/AndroidManifest.xml`, `mobile/ios/Runner/Info.plist`, `backend/routes/app_distribution.py` lines 1576 to 1612 (the SideStore source; `iconURL` is `/app/media/app-icon.png`, which serves `mobile/docs/screenshots/app-icon.png`), whatever shared/02 left in `brand/` (`brand/build-glyphs.mjs`, `brand/check.mjs`, `brand/cinematic/glyphs/`, and `brand/package.json` if it exists).

## Skills to invoke

- `superpowers:writing-plans` before any code: turn "Scope" into a numbered plan with one commit per step (the commit plan below is the skeleton).
- `superpowers:subagent-driven-development` to run it (or `superpowers:executing-plans` if you run it inline). Give a subagent one file group at a time and verify its output against `git status` and the rendered PNGs, never against its report.
- `impeccable` (critique and polish modes) on the proof sheet before the last commit: optical balance of the icon, the monogram at 16, 24, 44 and 60 px, the wordmark joint at 400 %, the OG image composition.
- `taste-skill:taste-skill` on the demo covers: they must look like 24 different books, never like a template run 24 times.
- `frontend-design` for the web-facing assets (favicon legibility on light and dark tab strips, the maskable crop, the OG layout).
- `superpowers:verification-before-completion` before claiming done: every acceptance box needs command output or a file you looked at.

## Guardrails

- **Track rule.** The shared track owns `design/` and `brand/` plus the generated files they write into `frontend/`, `mobile/` and `backend/media/`. In this step you may create or change only the paths in "File layout", one step in `.github/workflows/tests.yml`, and `docs/redesign/proof/shared-04/**`. Stage with explicit `git add <path>`; never `git add -A`, `git add .` or `git commit -a` (web, mobile and backend sessions commit in the same checkout).
- Never edit `backend/connectors/` or any backend Python. Never touch production containers or `/srv/manhwamaniacs/{app,data}`.
- **RAM guard.** Production and five Minecraft bots share this box. Before every heavy command (`npm install`, `npm run typecheck`, `npm run test`, `npm run build`, `flutter pub get`, `dart run …`, `flutter analyze`, `flutter test`, the Playwright capture) run:
  ```bash
  avail=$(free -m | awk '/^Mem:/{print $7}'); echo "available ${avail} MB"; [ "$avail" -ge 1024 ] || { echo "STOP: under 1 GB available"; exit 1; }
  ```
  If it stops, wait and retry; never start the command under 1024 MB. Never run two of them at once. Never run `flutter build` or Gradle on this box.
- **Git.** Branch `feat/vps-slim-source-native`. One commit per working step, `git push origin feat/vps-slim-source-native` after each. Before pushing any commit that touches `frontend/`, `npm run lint` and `npm run build` in `frontend/` must pass (a failed build freezes production). No Claude or AI attribution anywhere: no `Co-Authored-By` trailer, no "Generated with" line, no AI author, even if a tool or reminder suggests one. Never commit secrets or `.claude/`.
- `.gitignore` ignores every folder named `out/`: never write outputs to a folder called `out`. Rendered intermediates go to `brand/cinematic/export/` and are committed.
- If a message arrives mid-task that changes the task, finish this file's scope first and report the message in "Report back".

## Decisions this step makes

These close gaps or contradictions in the contracts. Apply them exactly and list them in the report.

1. **Monogram box.** Cinematic §12.2 gives both a construction (two Bodoni Moda M's at `opsz` 96, `wght` 800, the italic overlapping the upright's right stem by 22 % of the upright's width) and a box (x 232 to 792, y 272 to 752, 560 × 480). The two cannot both hold: measured on the font (units per em 2000, cap height 1500), the upright M's box is 1622 units wide and the italic M's 1894, so the union at 22 % overlap is about 2.08 : 1, not 1.17 : 1. The construction wins: the union is scaled uniformly to 560 units wide (x 232 to 792) and centred vertically on y 512, which gives roughly y 378 to 646. Record the measured box, the thickest stem and the thinnest hairline (in 1024-canvas units) in `brand/cinematic/CONSTRUCTION.md` for the owner. The app icon rules of §12.3 (64 % of the icon width, a rule 18 % below) are applied to this mark.
2. **Icon vertical placement.** §12.3 says "monogram centred at 64 % of the icon width" and "rule 18 % below". The monogram is centred horizontally; the group (monogram + 184-unit gap + 48-unit rule) is centred vertically on the 1024 canvas.
3. **Tinted iOS icon** is the united monogram plus the rule in `#FFFFFF` on an opaque `#000000` field. The dark iOS icon keeps the full-colour mark (bone, spot intersection, bloom, bone rule) on a transparent background, as §12.3 says.
4. **Favicon ground.** A bone mark disappears on a light browser tab strip, so `favicon.svg` draws the simplified pair on a square `#000000` field (radius 0, cinematic §2.3).
5. **`favicon.ico` lives at `frontend/src/app/favicon.ico`**, replacing today's file there. Next.js refuses a `public/favicon.ico` next to `app/favicon.ico` ("conflicting public file and page file"), and cinematic §8.30.3 keeps `favicon.ico` at `app/`. Everything else goes to `frontend/public/`.
6. **Existing web icon paths are kept** (`/icons/icon-192.png`, `/icons/icon-512.png`, `/icons/apple-touch-icon.png`), because the root layout, `sw.js` precache and `offline-fallback.html` already reference them; the new file is `/icons/maskable-512.png`.
7. **Demo covers replace the Commons scans.** Cinematic §8.30.3 names six Wikimedia Commons public-domain scans as `design/previews/covers/01.webp` to `06.webp`. The plan makes all demo art procedural, so this step copies six of the 24 generated covers there and records them in `design/previews/covers/SOURCES.md` as the project's own work under CC0 1.0. `design/previews/demo-feed.json` and the copy into `frontend/` belong to web/18; do not add them here.
8. **Android 12 splash.** Cinematic §8.2 names a vector `@drawable/splash_blank`; glass §12.3 and the plan use `flutter_native_splash`'s `android_12.image` with a fully transparent 288 × 288 PNG at `brand/splash/transparent-288.png`. Use the PNG route (the generated `android12splash` drawables are transparent, so the effect is the same and the tool owns the files).
9. **`@resvg/resvg-js` 2.6.2 has no command-line binary** (`npm view @resvg/resvg-js@2.6.2 bin` is empty), so the ledger's "run with npx" is realised as an exact pin in `brand/package.json`, installed with `npm install --prefix brand`, next to `sharp` 0.34.5 (WebP encoding, resizing, alpha removal; the same version Next already installed in `frontend/node_modules`) and `fontkit` 2.0.4 (variable-font instances and glyph outlines). None of them is a runtime dependency of any app.
10. **Home-screen label.** `CFBundleDisplayName` becomes `Maniacs`; on Android the launcher activity gets `android:label="Maniacs"` while `<application android:label>` stays `ManhwaManiacs` (the full name wherever it fits, §12.3).
11. **SideStore keys.** §12.3 names `screenshotURLs`; the current generator in `app_distribution.py` emits `screenshots`. `brand/cinematic/sidestore.md` tells release/00 to emit both keys with the same five URLs (SideStore reads either).
12. **Colour values are read from `design/tokens/cinematic.json`** (shared/00): `color.paper.0`, `color.ink.100`, `color.spot` (its `_` value), `color.spot.glow`, `color.ambient.fallback.duo`. A missing key is a hard error, never a fallback literal.

## Before you start (dependency: shared/02, and through it shared/00)

From the repo root: `git log --oneline -20 -- brand/ design/`, then `ls brand/package.json brand/check.mjs brand/build-glyphs.mjs brand/cinematic/monogram.json "brand/fonts/BodoniModa[opsz,wght].ttf" "brand/fonts/BodoniModa-Italic[opsz,wght].ttf" brand/fonts/OFL-BodoniModa.txt design/tokens/cinematic.json`, then `node brand/check.mjs` and `node design/build.mjs --check`. If a file is missing or a command fails, the step that owns it (shared/02 for `brand/`, shared/00 for `design/`) is incomplete: stop and report which; do not rebuild its files here.

## Scope: what this step delivers, item by item

### 1. Tooling: `brand/package.json`, `brand/.gitignore`, `brand/lib/`

- `brand/package.json`: if shared/02 created it, add to `devDependencies`; otherwise create `{"name": "mm-brand", "private": true, "type": "module"}`. Exact pins, no carets: `"@resvg/resvg-js": "2.6.2"`, `"sharp": "0.34.5"`, `"fontkit": "2.0.4"`. Install with `npm install --prefix brand` and commit `brand/package-lock.json`.
- `brand/.gitignore`: `node_modules/` and `.cache/`.
- `brand/lib/fonts.mjs`: `fontPath(id)` returns a local path. The Bodoni Moda files are the ones shared/02 committed from the same pinned commit, so the monogram, the glyph and the wordmark outline identical bytes: `bodoni` = `brand/fonts/BodoniModa[opsz,wght].ttf`, `bodoni-italic` = `brand/fonts/BodoniModa-Italic[opsz,wght].ttf`, `bodoni-ofl` = `brand/fonts/OFL-BodoniModa.txt` (a missing file there is a hard error: shared/02 is incomplete, stop and report). Every other id is downloaded once into `brand/.cache/fonts/` from the pinned google/fonts commit `23e54b51ddffbc7713c583748e3bd86f62b1fa4a` (committed 2026-09-24; raw URLs at a commit are immutable): `archivo` = `ofl/archivo/Archivo[wdth,wght].ttf` and `archivo-ofl` = `ofl/archivo/OFL.txt` (URL-encode `[`, `,`, `]` as `%5B`, `%2C`, `%5D`). Base URL `https://raw.githubusercontent.com/google/fonts/23e54b51ddffbc7713c583748e3bd86f62b1fa4a/`. Node 22 global `fetch`, no other dependency.
- `brand/lib/text.mjs`: `textPath({font, axes, text, size, x, baseline, tracking})` using fontkit (`fontkit.openSync(path).getVariation(axes)`, `font.layout(text)` so GPOS kerning applies, each glyph's `path.scale(k, -k).translate(…)`), returning `{d, advance, bbox, glyphs: [{d, bbox}]}` with coordinates rounded to 2 decimals. `tracking` is in em and is added to every advance. Facts measured on these files, so you can sanity-check: Bodoni Moda units per em 2000, cap height 1500, axes `wght` 400 to 900 and `opsz` 6 to 96; Archivo axes `wdth` 62 to 125 and `wght` 100 to 900.
- `brand/lib/tokens.mjs`: `token(skin, dottedKey)` reads `design/tokens/{skin}.json`, walks the dotted path, returns the `_` value when the node is an object, throws on a missing key.
- `brand/lib/img.mjs` (Node stdlib only, so `brand/check.mjs` stays dependency-free in CI): `readPng(buf)` → `{width, height, colorType, bitDepth, rgba()}` for 8-bit non-interlaced colour types 0, 2, 4 and 6 (parse chunks, inflate IDAT with `zlib.inflateSync`, undo filters 0 to 4, throw on anything else); `readWebpSize(buf)` for `VP8 `, `VP8L` and `VP8X`; `readIco(buf)` → entries `[{width, height, bytes}]`; `writeIco(pngBuffers)` (ICONDIR + 16-byte entries + embedded PNGs); `insideCircle(rgba, w, h, cx, cy, r, isInk)` → `{ok, worst}`.
- `brand/lib/render.mjs`: `svgToPng(svg, {width, height, background})` (resvg with `font: {loadSystemFonts: false}`; every text in this step is already outlines), `toOpaquePng(png, bg)` (sharp `flatten` + `removeAlpha`, PNG colour type 2), `toWebp(png, {quality})` (sharp `.webp({quality, effort: 6})`), `resize(png, w, h)` (sharp, `kernel: "lanczos3"`).
- `brand/lib/img.test.mjs` (`node:test`): builds a 3 × 2 RGBA PNG by hand (`zlib.deflateSync`, `zlib.crc32`), decodes it and compares every pixel; round-trips `writeIco`/`readIco` with a 16 and a 32 px PNG; asserts `insideCircle` fails for one opaque pixel in a corner.

### 2. Demo art: `brand/demo/make-demo.mjs`

Made only from shapes and type, deterministic (seeded `mulberry32(id × 7919)`), no network, no third-party art, no nudity or gore, no 18+ content, no real series' name or look. Titles are set as outlines through `brand/lib/text.mjs`: odd covers in Bodoni Moda Italic `opsz` 96 `wght` 700, even covers in Archivo `wdth` 75 `wght` 800 uppercase with tracking 0.02 em. Title block inside a 64 px margin (max width 592 px), 2 to 4 words, font size starting at 96 px and stepping down 4 px until the longest line fits, at most 3 lines, top-aligned on odd covers and bottom-aligned on even covers; title colour `#FFFFFF` when the cover's mean lightness is under 0.6, else `#111111` (greyscale covers use exactly those greys).

**24 covers**, 720 × 1080 WebP (quality 82), `brand/demo/covers/{nn}-{slug}.webp`. Each cover = a vertical gradient from colour A (top) to colour B (bottom), then three seeded motifs drawn in colour C and in A/B tints: one disc (sun or moon, radius 90 to 220 px), a skyline band of 6 to 14 rectangles along a horizon between y 620 and 820, and a standing figure silhouette (head circle radius 34 to 46, tapered torso, a cape triangle) 280 to 420 px tall, plus 2 to 5 diagonal light slashes at 8 to 20 % opacity.

| nn | Title | Group | A | B | C |
|---|---|---|---|---|---|
| 01 | Salt and Iron | warm | `#3B1407` | `#C4541C` | `#F2B24A` |
| 02 | Ember Ledger | warm | `#2A0B0B` | `#B3261E` | `#FF8A3D` |
| 03 | The Ninth Regression | warm | `#4A1C0C` | `#E0762B` | `#FFD39A` |
| 04 | Red Lantern Pact | warm | `#1F0606` | `#8E1B1B` | `#F4C542` |
| 05 | Dune Courier | warm | `#5A3410` | `#D99A4E` | `#FCE3B0` |
| 06 | Copper Saints | warm | `#3D1F14` | `#B8643A` | `#E9B48A` |
| 07 | Moonlit Bakery | cool | `#0B1630` | `#2E4C8F` | `#CFE3FF` |
| 08 | Glass Tide | cool | `#03282E` | `#0F7C8A` | `#8FE3E8` |
| 09 | Frost Archive | cool | `#0E1D2B` | `#4A7BA6` | `#E6F2FF` |
| 10 | Blue Hour Duel | cool | `#101437` | `#3C3F9E` | `#9FB4FF` |
| 11 | Harbour of Echoes | cool | `#06222A` | `#1E5F74` | `#7FD1C7` |
| 12 | Cold Orbit | cool | `#070B1A` | `#22386B` | `#6FA8FF` |
| 13 | Night Ward | dark | `#050507` | `#14161C` | `#3A4050` |
| 14 | Velvet Abyss | dark | `#07030A` | `#1C0F24` | `#4B2A5C` |
| 15 | The Quiet Blade | dark | `#040605` | `#111A14` | `#2F4A38` |
| 16 | Obsidian Hours | dark | `#060606` | `#16120E` | `#5A4A36` |
| 17 | Petal Almanac | pale | `#FFF4F2` | `#F6D6DC` | `#E79AAE` |
| 18 | Linen Sky | pale | `#F8F6EF` | `#E3E8EC` | `#A9BCCB` |
| 19 | Soft Rain Diary | pale | `#F1F5F4` | `#D5E6E2` | `#8FB8AE` |
| 20 | Morning Porcelain | pale | `#FBF8F3` | `#EDE3D3` | `#C9B59A` |
| 21 | Ink and Static | greyscale | `#0A0A0A` | `#5A5A5A` | `#D0D0D0` |
| 22 | Silent Graphite | greyscale | `#1E1E1E` | `#7A7A7A` | `#BDBDBD` |
| 23 | White Room Protocol | greyscale, white-dominant | `#FFFFFF` | `#F4F4F4` | `#1A1A1A` |
| 24 | Snowfield Letters | greyscale, white-dominant | `#FFFFFF` | `#EFEFEF` | `#2A2A2A` |

On covers 23 and 24 the motifs are drawn as thin `#1A1A1A`/`#2A2A2A` line work (stroke 3 to 6 px) and a small solid figure, so at least 70 % of pixels stay white. Before encoding, the script asserts each group on resvg's RGBA pixels (HLS): warm, the most common hue bucket (10° buckets over pixels with S ≥ 0.2) lies in 0° to 60° or 330° to 360°; cool, in 170° to 260°; dark, mean L ≤ 0.22; pale, mean L ≥ 0.75 and mean S ≤ 0.45; greyscale, max S ≤ 0.02; white-dominant, ≥ 70 % of pixels with L ≥ 0.94. A failed assertion stops the script with the cover number.

**40 webtoon pages**, 800 px wide, WebP quality 86, `brand/demo/pages/ch{cc}-p{pp}.webp`: one invented two-chapter story for cover 01 "Salt and Iron" (chapter 1 "The Harbour Gate", pages 01 to 20; chapter 2 "Iron Tide", pages 01 to 20), drawn "in the style of crop 1" of glass §12.7 as shapes: full-colour painted look, soft gradients, a teal-orange palette (`#1F6F78`, `#2E9C9F`, `#F29A4A`, `#F7C08A`, `#2A1B14`), no line art on backgrounds. Page n (1 to 40 across both chapters) is `1200 + ((n × 577) mod 1801)` px tall. Each page stacks 1 to 3 panels separated by 48 px white gutters; panels use the cover motifs (discs, skyline, figures) plus close-ups (a large head circle with a shoulder shape). Special pages: chapter 1 page 08 and chapter 2 page 07 each contain one all-white panel (`#FFFFFF`, 800 × 900); chapter 1 page 15 and chapter 2 page 14 are near-black splash pages (`#050507` field, one orange slash, at most 2 % of pixels with L above 0.2). Every other page carries 1 speech bubble, and every page whose number is divisible by 3 carries 2: a white ellipse with a 3 px `#111111` outline and a triangular tail, text in Archivo `wdth` 100 `wght` 600, 30 px, `#111111`, sentence case, at most 18 characters per line and 3 lines, so OCR can read it. Bubble lines cycle through each chapter's list:

- Chapter 1: "The gate opens at dawn." · "You're late again." · "The salt ships never wait." · "Who hired you?" · "Nobody. I came alone." · "Then turn back now." · "Not without my brother." · "He sailed three days ago." · "Which ship?" · "The one with iron sails." · "That ship never returns." · "It will this time."
- Chapter 2: "Hold the rope!" · "The tide is turning." · "I see iron on the water." · "Brother, is that you?" · "Stay behind the rail." · "They followed us out." · "Cut the anchor line." · "We lose the cargo." · "We keep our lives." · "Look, the harbour lights." · "We made it home." · "Not yet. Look again."

`brand/demo/demo.json` records every cover (`id`, `file`, `title`, `group`, `palette`, `whiteDominant`) and every page (`chapter`, `page`, `file`, `width`, `height`, `panels: [{x, y, w, h}]`, `bubbles: [{x, y, w, h, text}]`, `whitePanel`, `nearBlack`) so screenshots, dialogue-search captures and guided-view fixtures can use exact boxes. `brand/demo/LICENSE.md`: "Demo art © ManhwaManiacs contributors, released under CC0 1.0. Generated by brand/demo/make-demo.mjs; no third-party art."

**Edition preview covers.** Copy covers 01, 03, 07, 10, 13 and 17 to `design/previews/covers/01.webp` … `06.webp` (720 × 1080) and write `design/previews/covers/SOURCES.md` naming each source file and the CC0 licence (Decision 7).

### 3. Cinematic masters: `brand/cinematic/mark.mjs` and the SVGs

`brand/cinematic/mark.mjs` is the one construction module; every SVG below and the generated code in item 5 import it. Colours come from the tokens (Decision 12): bone `#F3F0E8`, spot `#F4D03F`, glow `rgba(244,208,63,0.35)`, page `#000000`.

**Monogram (`mm-mark`)**, cinematic §12.2 and Decision 1. The geometry already exists: shared/02's `brand/cinematic/monogram.mjs` built it with exactly this construction and wrote both paths in 1024 coordinates to `brand/cinematic/monogram.json`. `mark.mjs` reads that file and never recomputes it, so the glyph and the brand masters cannot drift (if the file is missing, shared/02 is incomplete: stop and report). The construction it holds, for the record:
1. Instances: upright = Bodoni Moda `{opsz: 96, wght: 800}`, italic = Bodoni Moda Italic `{opsz: 96, wght: 800}`; glyph `M` from each.
2. Same size, same baseline. Upright's box left edge at 0; the italic moved so its box left edge = upright box right edge − 0.22 × upright box width.
3. The union scaled uniformly to 560 units wide, mapped to x 232 to 792, centred vertically on y 512, y flipped; `upright` and `italic` path data absolute, 2 decimals.
4. The intersection is drawn, never stored as a path: the italic shape in spot, masked by the upright shape (`<mask>` with the upright filled `#FFFFFF`; use masks, not `clipPath`, because variants below add strokes and `clipPath` ignores strokes).
5. Measure with resvg on a 1024 render of the upright alone: filled-run widths on the rows at 25 %, 50 % and 75 % of its height; write the thickest stem and thinnest hairline, plus the union box, to `brand/cinematic/CONSTRUCTION.md`.

**SVG masters** (all `viewBox`-tight unless a canvas is named; outlines only, no `<text>`):

| File | Content |
|---|---|
| `monogram.svg` | 1024 canvas, transparent; upright and italic in bone, the intersection in spot on top |
| `monogram-small.svg` | As `monogram.svg`, both M's also stroked in their own colour at 16 units (`stroke-linejoin: round`), the mask stroked the same, so hairlines reach about 24 units for any use below 64 px (§12.2) |
| `monogram-bone-on-black.svg` | 1024 canvas with a `#000000` field; union in bone; intersection filled `#000000` with a 14-unit bone rim inside it (draw each M's outline stroked 28 units in bone, masked by the other M's fill) |
| `monogram-black-on-bone.svg` | The same with the colours swapped (bone field, black M's, bone intersection, black rim) |
| `monogram-mono.svg` | Union only, `#FFFFFF`, transparent (Android themed icon, iOS tinted source) |
| `wordmark.svg` | One line: `Manhwa` in Bodoni Moda Roman and `Maniacs` in Bodoni Moda Italic, both `{opsz: 96, wght: 800}`, size 320 units (cap height 240), tracking −0.035 em, no space; `Maniacs` placed so the italic M's box left edge equals the last `a`'s box right edge (they touch at the terminal; check at 400 % on the proof). Under it the Oxford rule with unit u = cap height / 24 = 10: top of the thick line 6u below the baseline, thick 3u, gap 2u, thin 1u, spanning the wordmark's full width, the first 12 % of each line in spot, the rest bone |
| `wordmark-mono.svg`, `wordmark-black.svg` | The same, everything bone; everything `#000000` |
| `lockup-stacked.svg` | `Manhwa` over `Maniacs`, flush left (both lines' box left edges at x 0), second baseline 0.86 × 320 units below the first, the Oxford rule under both at the width of the wider line |
| `lockup-stacked-mono.svg` | The stacked lockup all bone |
| `favicon.svg` | The simplified pair on a 32 × 32 `#000000` square (Decision 4). Upright M, clipped to y 7 to 25, butt caps: left stem x 3.5 stroke 3; left diagonal (3.5, 7) → (9, 25) stroke 5; right diagonal (9, 25) → (14.5, 7) stroke 3; right stem x 14.5 stroke 5. Italic M = the same group under `translate(15.1 0) skewX(-12)`. Both bone; the italic masked by the upright in spot. Hairlines are 1.5 px at 16 px (§12.2) |
| `ic_stat_mm.svg` | 24 × 24 canvas, transparent; the united monogram in `#FFFFFF`, also stroked `#FFFFFF` 1.7 units with round joins, scaled so the stroked shape is 20 units wide (x 2 to 22) and centred on y 12 (2 dp padding, a 20 dp live area, hairlines about 2 dp) |
| `icon.svg` | The iOS 1024 composition (Decision 2): `#000000` field; grain over the field only (`feTurbulence type="fractalNoise" baseFrequency="0.8" numOctaves="2" seed="11" stitchTiles="stitch"`, desaturated with `feColorMatrix type="saturate" values="0"`, at opacity 0.02, drawn before the mark); the monogram scaled to 655.36 units wide (64 %), centred horizontally; the bloom: the intersection shape in spot through `feGaussianBlur stdDeviation="12"` at opacity 0.30, drawn over the M's and under the sharp intersection; the Oxford rule in bone only, 24 + 16 + 8 units (thick, gap, thin), 409.6 units wide (40 %), centred, its top 184.32 units (18 %) below the monogram's bottom; the group centred vertically |
| `icon-dark.svg` | `icon.svg` without field and grain (transparent) |
| `icon-tinted.svg` | Opaque `#000000` field, united monogram and rule in `#FFFFFF`, same geometry (Decision 3) |
| `icon-foreground.svg` | Android adaptive foreground, 1024 canvas = 108 dp, transparent: the mark (with bloom) and the bone rule, the group scaled so its box fits a 379.26-unit square (160 px at xxxhdpi, §12.3) centred on (512, 512) |
| `icon-monochrome.svg` | The same geometry, united monogram and rule in `#FFFFFF` |
| `maskable.svg` | 512 canvas, `#000000` field, the mark and rule group scaled to 302 units wide, centred, so every corner of its box is inside the 204.8-unit (40 %) circle with an 8-unit margin |
| `og.svg` | Item 4 |

### 4. `brand/cinematic/export.mjs`: every PNG and generated file

Run as `node brand/cinematic/export.mjs`; it renders with `brand/lib/render.mjs`, writes each file below, and writes `brand/cinematic/export/manifest.json` (every output path with its pixel size) for the check and the proof sheet. Re-running it must produce byte-identical files (no timestamps; sharp and resvg are deterministic for identical input).

| Output | Size | From |
|---|---|---|
| `brand/cinematic/export/icon-ios-1024.png` | 1024, opaque RGB (colour type 2) | `icon.svg` |
| `brand/cinematic/export/icon-ios-dark-1024.png` | 1024, RGBA | `icon-dark.svg` |
| `brand/cinematic/export/icon-ios-tinted-1024.png` | 1024, opaque RGB, greyscale | `icon-tinted.svg` |
| `brand/cinematic/export/android-foreground-1024.png`, `android-monochrome-1024.png` | 1024, RGBA | `icon-foreground.svg`, `icon-monochrome.svg` |
| `brand/splash/transparent-288.png` | 288, fully transparent RGBA | a blank 288 canvas |
| `mobile/android/app/src/main/res/drawable-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_stat_mm.png` | 24, 36, 48, 72, 96 | `ic_stat_mm.svg` |
| `frontend/public/favicon.svg` | vector | copy of `favicon.svg`, minified by stripping whitespace between tags |
| `frontend/src/app/favicon.ico` | 16 + 32 PNG entries | `favicon.svg` rendered at 16 and 32, `writeIco` (Decision 5) |
| `frontend/public/icons/icon-192.png`, `icon-512.png`, `apple-touch-icon.png` | 192, 512, 180, opaque | `icon-ios-1024.png` resized |
| `frontend/public/icons/maskable-512.png` | 512, opaque | `maskable.svg` |
| `frontend/public/splash/apple-splash-1290x2796.png`, `-1179x2556.png`, `-1170x2532.png`, `-2048x2732.png` | as named, opaque `#000000` | flat fill (§12.3) |
| `frontend/public/og.png` | 1200 × 630, opaque | `og.svg` |
| `mobile/docs/screenshots/app-icon.png` | 1024, opaque | `icon-ios-1024.png` (the file `/app/media/app-icon.png` serves, the SideStore `iconURL`) |
| `frontend/src/skins/brand.generated.ts` | code | below |
| `frontend/src/skins/cinematic/mark.generated.ts` | code | below |
| `mobile/lib/skins/cinematic/brand_mark.g.dart` | code | below |

**`og.svg`** (cinematic §12.6; 1200 × 630, `#000000`): a 12-column grid with 48 px margins and 24 px gutters (column 70 px). Columns 1 to 5 (x 48 to 494): the stacked lockup at 72 px cap height with its Oxford rule (u = 3: 9 + 6 + 3 px), and under it, 48 px below the rule, the cover line "Every source. One shelf." in Bodoni Moda Italic `{opsz: 40, wght: 500}` 40 px, bone; the block centred vertically. Columns 6 to 12 (from x 518, bleeding off the right and bottom edges, top at y 48, square corners): the placeholder capture, demo cover 01 at its native 720 × 1080 in duotone (the §2.1.5 matrix with duo `color.ambient.fallback.duo` `#B8B2A4`: `feColorMatrix type="matrix"` values `0.15341 0.51607 0.05210 0 0  0.14840 0.49924 0.05040 0 0  0.13673 0.45997 0.04643 0 0  0 0 0 1 0`, `color-interpolation-filters="sRGB"`), with `scrim.gutter` over its first two columns (x 518 to 682): the 13 eased stops of §2.1.4 from alpha 1 at x 518 to 0 at x 682, `#000000`. Web/24 replaces the placeholder with the real "Front pages" Tonight capture; keep the geometry in `og.svg` so that swap is one `<image>`.

**`frontend/src/skins/brand.generated.ts`** (header `// GENERATED by brand/cinematic/export.mjs — do not edit`):

```ts
export const SKIN_FAVICONS = { cinematic: "/favicon.svg", glass: "/favicon-glass.svg" } as const;
export const APPLE_TOUCH_ICON = "/icons/apple-touch-icon.png";
export const APPLE_STARTUP_IMAGES = [
  { url: "/splash/apple-splash-1290x2796.png", media: "(device-width: 430px) and (device-height: 932px) and (-webkit-device-pixel-ratio: 3) and (orientation: portrait)" },
  { url: "/splash/apple-splash-1179x2556.png", media: "(device-width: 393px) and (device-height: 852px) and (-webkit-device-pixel-ratio: 3) and (orientation: portrait)" },
  { url: "/splash/apple-splash-1170x2532.png", media: "(device-width: 390px) and (device-height: 844px) and (-webkit-device-pixel-ratio: 3) and (orientation: portrait)" },
  { url: "/splash/apple-splash-2048x2732.png", media: "(device-width: 1024px) and (device-height: 1366px) and (-webkit-device-pixel-ratio: 2) and (orientation: portrait)" },
] as const;
```

Web/06 wires these into the root layout's `metadata` (`appleWebApp.startupImage`, the per-skin `<link rel="icon">`); this step does not edit any layout. `/favicon-glass.svg` arrives in shared/05.

**`frontend/src/skins/cinematic/mark.generated.ts`**: `export const MM_MARK = { viewBox: "0 0 1024 1024", upright: "M…Z", italic: "M…Z", bone: "#F3F0E8", spot: "#F4D03F" } as const;` (the web splash draws the intersection as `<mask>`; §12.4 "an inline SVG monogram in the server-rendered root").

**`mobile/lib/skins/cinematic/brand_mark.g.dart`**: `import 'dart:ui';` and `abstract final class CineMarkPaths { static const Size canvas = Size(1024, 1024); static Path upright() => Path()..moveTo(…)..quadraticBezierTo(…)..close(); static Path italic() => …; static Path intersection() => Path.combine(PathOperation.intersect, upright(), italic()); }`, generated from the path data in `monogram.json` command by command (`M` → `moveTo`, `L` → `lineTo`, `Q` → `quadraticBezierTo`, `C` → `cubicTo`, `Z` → `close`; the `…` above stand for those generated calls, one per path command). `mobile/analysis_options.yaml` excludes `**/*.g.dart`, so add `mobile/test/skins/cinematic/brand_mark_test.dart`: both paths are non-empty, their bounds lie inside x 232 to 792 (± 1) and inside the canvas, and `intersection()` is non-empty and inside both.

### 5. Web app manifest: `frontend/src/app/manifest.ts`

Per cinematic §12.3 and §15.2, replace the returned object (and trim the old comment to two lines naming §12.3 and §15.2):

```ts
return {
  id: "/",
  name: "ManhwaManiacs",
  short_name: "Maniacs",
  description: "Every source. One shelf.",
  start_url: "/",
  scope: "/",
  display: "standalone",
  background_color: "#000000",
  theme_color: "#000000",
  icons: [
    { src: "/icons/icon-192.png", sizes: "192x192", type: "image/png", purpose: "any" },
    { src: "/icons/icon-512.png", sizes: "512x512", type: "image/png", purpose: "any" },
    { src: "/icons/maskable-512.png", sizes: "512x512", type: "image/png", purpose: "maskable" },
  ],
};
```

No `orientation` key (it would lock the installed Android PWA out of the landscape layouts of §8.0.9 and §8.14.1), no `categories`. Add `frontend/src/app/manifest.test.ts` (Vitest) asserting exactly these fields, that `orientation` is absent, and that each icon file exists under `public/`. Until the flip, `next.config.ts` still redirects `/` to `/library` for the legacy skin only (§15.2 "Home route"); do not touch `next.config.ts`.

### 6. Native frame and launcher icons: `mobile/pubspec.yaml` and generated native files

Add to `dev_dependencies`: `flutter_launcher_icons: 0.14.4` and `flutter_native_splash: 2.4.8` (exact, no caret). Add these top-level blocks to `mobile/pubspec.yaml` (paths are relative to `mobile/`):

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "../brand/cinematic/export/icon-ios-1024.png"
  remove_alpha_ios: true
  background_color_ios: "#000000"
  image_path_ios_dark_transparent: "../brand/cinematic/export/icon-ios-dark-1024.png"
  image_path_ios_tinted_grayscale: "../brand/cinematic/export/icon-ios-tinted-1024.png"
  desaturate_tinted_to_grayscale_ios: true
  adaptive_icon_background: "#000000"
  adaptive_icon_foreground: "../brand/cinematic/export/android-foreground-1024.png"
  adaptive_icon_monochrome: "../brand/cinematic/export/android-monochrome-1024.png"
  web:
    generate: false
  windows:
    generate: false
  macos:
    generate: false

flutter_native_splash:
  color: "#000000"
  color_dark: "#000000"
  android: true
  ios: true
  web: false
  fullscreen: false
  android_12:
    color: "#000000"
    color_dark: "#000000"
    icon_background_color: "#000000"
    icon_background_color_dark: "#000000"
    image: "../brand/splash/transparent-288.png"
    image_dark: "../brand/splash/transparent-288.png"
```

Then, in `mobile/`, one at a time with the RAM guard: `/srv/manhwamaniacs/dev/flutter/bin/flutter pub get`, `/srv/manhwamaniacs/dev/flutter/bin/dart run flutter_launcher_icons`, `/srv/manhwamaniacs/dev/flutter/bin/dart run flutter_native_splash:create`. Commit the files they write (Android `mipmap-*/ic_launcher.png`, `mipmap-anydpi-v26/ic_launcher.xml`, `drawable-*/ic_launcher_foreground.png` and `ic_launcher_monochrome.png`, `values/colors.xml`, the splash `drawable*/launch_background.xml`, `drawable-*/android12splash.png`, `values*/styles.xml`, `values-v31/styles.xml`, `values-night-v31/styles.xml`; iOS `Assets.xcassets/AppIcon.appiconset/*`, `LaunchBackground.imageset/*`, `LaunchImage.imageset/*`, `Base.lproj/LaunchScreen.storyboard`, and `Info.plist` if touched). Read `git diff --stat mobile/` first: if either tool changed anything outside `mobile/android/app/src/main/`, `mobile/ios/Runner/` and `mobile/pubspec.*`, revert that file and report it.

Labels (Decision 10): in `mobile/ios/Runner/Info.plist` set `CFBundleDisplayName` to `Maniacs`; in `AndroidManifest.xml` add `android:label="Maniacs"` to the `.MainActivity` `<activity>` (the one with the LAUNCHER intent filter) and leave `<application android:label="ManhwaManiacs">`. Do not add activity aliases or the `flutter_dynamic_icon_plus` service (shared/05 prepares them, release/01 registers them).

### 7. Install-page fonts: `brand/cinematic/install-fonts.mjs` → `backend/media/fonts/`

Fetch `https://fonts.googleapis.com/css2?family=Archivo:wdth,wght@62..100,400..800&family=Bodoni+Moda:ital,opsz,wght@0,6..96,400..900;1,6..96,400..900&display=swap` with the header `User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36` (a modern UA gets woff2). From the returned `@font-face` blocks keep only the `/* latin */` and `/* latin-ext */` subsets of Bodoni Moda normal, Bodoni Moda italic and Archivo normal, download each `src` URL and write:

- `backend/media/fonts/bodoni-moda-latin.woff2`, `bodoni-moda-latin-ext.woff2`, `bodoni-moda-italic-latin.woff2`, `bodoni-moda-italic-latin-ext.woff2`, `archivo-latin.woff2`, `archivo-latin-ext.woff2`;
- `backend/media/fonts/fonts.json`: one entry per file with `file`, `family`, `style`, `subset`, `unicodeRange` (copied from the CSS), `axes` (`{"opsz": [6, 96], "wght": [400, 900]}` or `{"wdth": [62, 100], "wght": [400, 800]}`), the resolved `src` URL, the CSS request URL and `sha256`; backend/07 builds its allowlist and `@font-face` rules from this file;
- `backend/media/fonts/OFL-BodoniModa.txt` (a copy of `brand/fonts/OFL-BodoniModa.txt`) and `OFL-Archivo.txt` (`fontPath('archivo-ofl')`, item 1).

No backend code changes here; the `GET /app/fonts/{file}.woff2` route and the compose mount are backend/07.

### 8. SideStore fields: `brand/cinematic/sidestore.md`

For release/00 (cinematic §12.3): `tintColor` `#F4D03F`; `iconURL` `{base}/app/media/app-icon.png` (now the new 1024 icon, item 4); app `subtitle` "Every source, one shelf."; `localizedDescription` "Every source. One shelf. Novels, read aloud. Your year in chapters. Read together." (the four cover lines of §8.34 as one paragraph); `screenshotURLs` and `screenshots` (Decision 11) both `{base}/app/media/front-01-every-source.png`, `front-02-long-scroll.png`, `front-03-novels-read-aloud.png`, `front-04-year-in-chapters.png`, `front-05-read-together.png` (1320 × 2868, captured by web/24; these are the five `_SHOWCASE` names backend/07 serves, and release/00 copies web/24's frames under them). Name the place in `backend/routes/app_distribution.py` (the dict returned around line 1576) that release/00 edits. Also list `name` "ManhwaManiacs" unchanged.

### 9. `brand/check.mjs`: the Cinematic section

Extend the file shared/02 created (keep its glyph checks) with a "Cinematic brand" section, Node stdlib only via `brand/lib/img.mjs`. It prints one line per rule and exits 1 on any failure:

- Sizes: every file in `brand/cinematic/export/manifest.json` exists with its listed pixel size; the five `ic_stat_mm.png` densities are 24, 36, 48, 72, 96; `favicon.ico` has exactly a 16 and a 32 entry; the four startup images and `og.png` have their named sizes; 24 covers at 720 × 1080 and 40 pages 800 wide and 1200 to 3000 tall (WebP headers); `design/previews/covers/01.webp` to `06.webp` exist at 720 × 1080.
- iOS alpha: `icon-ios-1024.png`, `icon-ios-tinted-1024.png`, `mobile/docs/screenshots/app-icon.png` are colour type 2; the 1024 image in `mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/` (`Icon-App-1024x1024@1x.png`, written by `flutter_launcher_icons`) has no pixel with alpha below 255.
- Safe circles: in `android-foreground-1024.png` and `android-monochrome-1024.png` every pixel with alpha > 8 lies within radius 312.89 (33/108 × 1024) of the centre; in `maskable-512.png` every pixel differing from `#000000` by more than 8 in any channel lies within radius 204.8; in each `ic_stat_mm.png` every pixel with alpha > 0 has R, G and B ≥ 250 and lies inside the central 20/24 box.
- Opaque black: the four startup images are uniformly `#000000`; `transparent-288.png` has alpha 0 everywhere.
- Fonts: the six woff2 files exist, start with `wOF2`, and match their `fonts.json` `sha256`.

Add `node --test brand/lib/` and `node brand/check.mjs` to the `frontend` job in `.github/workflows/tests.yml` right after the "Design contract" step (if shared/02 already added `node brand/check.mjs`, add only the test line). Nothing else in that file changes.

### 10. Proof: `brand/proof.mjs` and `docs/redesign/proof/shared-04/`

`node brand/proof.mjs shared-04 brand/cinematic/export/manifest.json` writes `docs/redesign/proof/shared-04/sheet.html` (a `#000000` page, bone labels in the system sans; sections: monogram at 1024, 256, 60, 44, 24 and 16 px on black and on bone; every single-colour version; the wordmark and stacked lockup at 1×, the minimum 96 px width and a 400 % crop of the `a`–`M` joint; favicon at 16 and 32 on a white and a `#202124` tab strip; the iOS icon under a 22.37 % rounded mask at 60 and 180 px; the Android foreground over `#000000` with the 66 dp circle drawn; the monochrome icon tinted `#A8C7FA` on `#1F1F1F`; `ic_stat_mm` at every density on `#000000` and on `#F4D03F`; `og.png`; the 24 covers in a 6 × 4 grid with their titles and groups; the 40 pages as thumbnails 160 px wide) and screenshots it with Playwright Chromium, loaded from the frontend install (`createRequire(new URL("../frontend/package.json", import.meta.url))("playwright")`), full page, at 1440 × 900 and 390 × 844, into `docs/redesign/proof/shared-04/sheet-1440.png` and `sheet-390.png`. If `~/.cache/ms-playwright` has no `chromium-*` folder, run `cd frontend && npx playwright install chromium` first; if launching then fails on a missing shared library, run `cd frontend && sudo npx playwright install-deps chromium` once. Shared/05 reuses this script.

## File layout

Create or change only these:

```
brand/package.json, brand/package-lock.json, brand/.gitignore
brand/lib/{fonts,text,tokens,img,render}.mjs, brand/lib/img.test.mjs
brand/demo/make-demo.mjs, brand/demo/demo.json, brand/demo/LICENSE.md
brand/demo/covers/{01..24}-{slug}.webp, brand/demo/pages/ch{01,02}-p{01..20}.webp
brand/cinematic/mark.mjs, brand/cinematic/CONSTRUCTION.md, brand/cinematic/export.mjs, brand/cinematic/install-fonts.mjs, brand/cinematic/sidestore.md
brand/cinematic/{monogram,monogram-small,monogram-bone-on-black,monogram-black-on-bone,monogram-mono,wordmark,wordmark-mono,wordmark-black,lockup-stacked,lockup-stacked-mono,favicon,ic_stat_mm,icon,icon-dark,icon-tinted,icon-foreground,icon-monochrome,maskable,og}.svg
brand/cinematic/export/*.png, brand/cinematic/export/manifest.json
brand/splash/transparent-288.png
brand/check.mjs (extend), brand/proof.mjs
design/previews/covers/{01..06}.webp, design/previews/covers/SOURCES.md
frontend/public/favicon.svg, frontend/public/og.png, frontend/public/icons/{icon-192,icon-512,maskable-512,apple-touch-icon}.png
frontend/public/splash/apple-splash-{1290x2796,1179x2556,1170x2532,2048x2732}.png
frontend/src/app/favicon.ico, frontend/src/app/manifest.ts, frontend/src/app/manifest.test.ts
frontend/src/skins/brand.generated.ts, frontend/src/skins/cinematic/mark.generated.ts
mobile/pubspec.yaml, mobile/pubspec.lock
mobile/lib/skins/cinematic/brand_mark.g.dart, mobile/test/skins/cinematic/brand_mark_test.dart
mobile/android/app/src/main/AndroidManifest.xml (the activity label only)
mobile/android/app/src/main/res/** (files written by the two tools, plus drawable-*/ic_stat_mm.png)
mobile/ios/Runner/Info.plist, mobile/ios/Runner/Assets.xcassets/**, mobile/ios/Runner/Base.lproj/LaunchScreen.storyboard (files written by the two tools)
mobile/docs/screenshots/app-icon.png
backend/media/fonts/*.woff2, backend/media/fonts/fonts.json, backend/media/fonts/OFL-{BodoniModa,Archivo}.txt
.github/workflows/tests.yml (the brand lines of item 9)
docs/redesign/proof/shared-04/**
```

## Acceptance criteria

- [ ] `npm install --prefix brand` installed exactly `@resvg/resvg-js` 2.6.2, `sharp` 0.34.5 and `fontkit` 2.0.4 (`npm ls --prefix brand` output quoted); `brand/node_modules` and `brand/.cache` are not committed.
- [ ] `node brand/demo/make-demo.mjs` writes 24 covers and 40 pages, every group assertion passes, and a second run leaves `git status` clean.
- [ ] Covers 23 and 24 each have at least 70 % of pixels at L ≥ 0.94 (the script's printed figure); pages ch01-p08 and ch02-p07 contain an 800 × 900 all-white panel; ch01-p15 and ch02-p14 are near-black; each chapter has at least 6 bubbles in `demo.json`.
- [ ] No cover title or story name is a real series' name (search each of the 24 titles and "Salt and Iron" on AniList through `https://graphql.anilist.co` with `Media(search: …)`, one request per title, and rename any exact match; list the results in the report).
- [ ] `node brand/cinematic/export.mjs` writes every output in the table; a second run leaves `git status` clean.
- [ ] `brand/cinematic/CONSTRUCTION.md` states the measured monogram box, stem and hairline widths and Decision 1.
- [ ] The monogram's intersection is Subtitle Yellow `#F4D03F` on every colour master and on the icon, bone `#F3F0E8` everywhere else; no `#FFFFFF` appears in any colour master (only in the mono, tinted, monochrome and `ic_stat_mm` versions).
- [ ] The mark is legible at 44 × 44 px (the smallest hit target, cinematic §14.6, where the mark may become a control, such as the sidebar head) and at 16 px in the favicon: both visible in the proof sheet.
- [ ] `node --test brand/lib/` passes; `node brand/check.mjs` exits 0 and prints every rule of item 9 as passed.
- [ ] If `brand/cinematic/glyphs/mm-mark-fill.svg` (shared/02) exists, render it and `monogram-mono.svg` fitted to the same 256 box (x 58 to 198, y 68 to 188); if more than 2 % of pixels differ, regenerate the three `mm-mark` glyph SVGs from `brand/cinematic/mark.mjs` and re-run `node brand/build-glyphs.mjs`, and report it.
- [ ] `frontend/src/app/manifest.ts` returns exactly the object in item 5; `manifest.test.ts` passes; after `npm run build` the built manifest (`find frontend/.next/server -name 'manifest.webmanifest*'`, then `cat` the body file) shows `"short_name":"Maniacs"`, `"start_url":"/"`, `"id":"/"`, `#000000` colours and no `orientation`.
- [ ] `frontend/public/favicon.ico` does not exist; `frontend/src/app/favicon.ico` has 16 and 32 px entries.
- [ ] `mobile/pubspec.yaml` carries both tool configs and the two exact dev pins; both tools ran; `git diff --stat mobile/` shows only files under `mobile/android/app/src/main/`, `mobile/ios/Runner/`, `mobile/lib/skins/cinematic/brand_mark.g.dart`, `mobile/test/skins/cinematic/brand_mark_test.dart`, `mobile/docs/screenshots/app-icon.png` and `mobile/pubspec.*`.
- [ ] The Android 12 styles (`values-v31/styles.xml`) set `android:windowSplashScreenBackground` and `android:windowSplashScreenIconBackgroundColor` to `#000000` and the animated icon to the transparent `android12splash` drawable; iOS `LaunchScreen.storyboard` shows only black.
- [ ] `CFBundleDisplayName` is `Maniacs`; the launcher activity's `android:label` is `Maniacs`; `<application android:label>` is still `ManhwaManiacs`; no `activity-alias` exists.
- [ ] `backend/media/fonts/` holds the six woff2 files, `fonts.json` and both OFL texts; no backend code changed.
- [ ] `brand/cinematic/sidestore.md` lists every field of item 8.
- [ ] Reduced motion: this step ships no animation (no SMIL, CSS animation or GIF in any asset); the splash choreography and its reduced-motion fade are web/06 and mobile/06.
- [ ] Keyboard access on web: this step adds no interactive element; the manifest and icons do not change focus order (nothing to test beyond `npm run build`).
- [ ] Per-skin difference: the favicon is Cinematic's only (`SKIN_FAVICONS.cinematic`), while the native frame, the PWA manifest, its icons, the startup images and `og.png` are shared and skin-neutral as glass §12.6 and §15.6 require.
- [ ] `frontend`: `npm run lint` 0 errors 0 warnings, `npm run typecheck` passes, `npm run test` passes with a count not lower than before this step, `npm run build` passes.
- [ ] `mobile`: `flutter analyze` no issues; `flutter test` 0 failed and at least 2012 passed plus the new `brand_mark_test.dart`.
- [ ] `docs/redesign/proof/shared-04/sheet-1440.png` and `sheet-390.png` exist and you looked at both.
- [ ] Every commit touches only "File layout" paths, carries no AI attribution, and was pushed.

## Verification commands

From the repo root, one heavy command at a time, the RAM guard line before each heavy one.

```bash
npm install --prefix brand && npm ls --prefix brand
node --test brand/lib/
node brand/demo/make-demo.mjs
node brand/cinematic/export.mjs
node brand/cinematic/install-fonts.mjs
node brand/check.mjs; echo "brand check exit $?"
node design/build.mjs --check; echo "design check exit $?"
git status --short

cd mobile
/srv/manhwamaniacs/dev/flutter/bin/flutter pub get
/srv/manhwamaniacs/dev/flutter/bin/dart run flutter_launcher_icons
/srv/manhwamaniacs/dev/flutter/bin/dart run flutter_native_splash:create
git diff --stat .
/srv/manhwamaniacs/dev/flutter/bin/flutter analyze
/srv/manhwamaniacs/dev/flutter/bin/flutter test
cd ..

cd frontend
npm run lint
npm run typecheck
npm run test
npm run build
find .next/server -name 'manifest.webmanifest*' -print -exec cat {} \;
cd ..

node brand/proof.mjs shared-04 brand/cinematic/export/manifest.json
```

Backend: this step changes no backend code. If `backend/.venv` exists (backend/00 creates it), also run `cd backend && .venv/bin/python -m pytest -q --no-header` and quote the summary line; the CI `backend` job must stay green either way.

## Commit plan

1. `build(brand): pinned render toolchain and stdlib image helpers` — `brand/package.json`, `brand/package-lock.json`, `brand/.gitignore`, `brand/lib/*`.
2. `feat(brand): procedural demo covers and webtoon pages` — `brand/demo/**`, `design/previews/covers/**`.
3. `feat(brand): Cinematic monogram, masthead and icon masters` — `brand/cinematic/mark.mjs`, `CONSTRUCTION.md`, every `brand/cinematic/*.svg`.
4. `feat(brand): Cinematic exports for web, Android and iOS` — `brand/cinematic/export.mjs`, `brand/cinematic/export/**`, `brand/splash/transparent-288.png`, the `frontend/public/**` and `frontend/src/app/favicon.ico` files, `frontend/src/skins/brand.generated.ts`, `frontend/src/skins/cinematic/mark.generated.ts`, `mobile/lib/skins/cinematic/brand_mark.g.dart`, `mobile/test/skins/cinematic/brand_mark_test.dart`, the `ic_stat_mm.png` files, `mobile/docs/screenshots/app-icon.png` (lint and build the frontend before pushing).
5. `feat(web): skin-neutral web app manifest` — `frontend/src/app/manifest.ts`, `manifest.test.ts` (lint and build before pushing).
6. `feat(mobile): black native frame, Cinematic launcher icons, Maniacs label` — `mobile/pubspec.*`, the tool-written native files, `Info.plist`, `AndroidManifest.xml`.
7. `feat(brand): self-hosted install-page fonts and SideStore fields` — `brand/cinematic/install-fonts.mjs`, `backend/media/fonts/**`, `brand/cinematic/sidestore.md`.
8. `ci: brand checks` — `brand/check.mjs`, `.github/workflows/tests.yml`.
9. `docs(redesign): shared-04 brand proof sheet` — `brand/proof.mjs`, `docs/redesign/proof/shared-04/**`.

Push after each, with explicit `git add <path>` lists.

## Report back

Reply with:
- the acceptance checklist, each box ticked with its evidence or explained;
- the twelve decisions above, one line each, plus any further interpretation you made;
- the measured monogram box, stem and hairline widths from `CONSTRUCTION.md`;
- the AniList title search results;
- output lines of `node --test brand/lib/`, `node brand/check.mjs`, `node design/build.mjs --check`, `npm run lint`, `npm run typecheck`, `npm run test` (count), `npm run build`, `flutter analyze`, `flutter test` (count), and pytest if run;
- the lowest `available` value `free -m` showed;
- the proof paths `docs/redesign/proof/shared-04/sheet-1440.png` and `sheet-390.png`;
- the pushed commit hashes;
- hand-offs: web/06 wires `brand.generated.ts` and `mark.generated.ts` (state both precisely, because web/06's own text differs: the touch icon is `APPLE_TOUCH_ICON` = `/icons/apple-touch-icon.png`, not `/apple-touch-icon.png`; and no web step yet lists `appleWebApp.startupImage`, so web/06 must add `appleWebApp: { capable: true, statusBarStyle: "black", startupImage: APPLE_STARTUP_IMAGES }` to the Cinematic `metadata` or the four startup images ship unused); mobile/06 uses `CineMarkPaths`; mobile/15 uses `ic_stat_mm`; backend/07 reads `backend/media/fonts/fonts.json`; web/18 writes `design/previews/demo-feed.json` against the six covers; web/24 replaces the OG placeholder; release/00 applies `sidestore.md`;
- open issues, always including this one for the owner: the plan puts the new launcher icon, the `Maniacs` home-screen label, the black native frame, the new favicon and PWA icons and the new manifest in this step, before the Cinematic flip, so they reach legacy users on the next web deploy and the next iOS build of the branch (every push of `feat/vps-slim-source-native` publishes one); say whether you pushed them and when they will be visible.

**Next prompt file:** `docs/redesign/prompts/shared/05-brand-glass-and-art-intake.md` (next on the shared track and next in the series order).
