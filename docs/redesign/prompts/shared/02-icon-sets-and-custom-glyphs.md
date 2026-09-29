# Shared 02: icon sets and custom glyphs for both skins

## Goal

Give both skins their complete iconography as build outputs both clients can use without any further design decisions: the Phosphor 2.1 icon set wired for the web and for Flutter, every custom glyph of cinematic §2.7 and glass §2.7 drawn as SVG masters in every weight its skin uses, one role map (`design/icons.json`) that says which icon every semantic role uses in each skin and at which weight and size, and one build script, `brand/build-glyphs.mjs`, that turns the masters into typed React components, into the `CineGlyphs` and `GlassGlyphs` icon fonts for Flutter (through `fantasticon` 4.1.0) with generated Dart `IconData` classes, and into generated Phosphor constants and role tables for both clients. `brand/check.mjs` gets its glyph part: it proves every glyph exists in every required weight on both platforms. Runtime wiring (the `Icon` components, `pubspec.yaml` font declarations) is web/01 and mobile/03, not this step.

## Read first

1. `docs/redesign/inventory/00-decisions.md` (every element redesigned, down to the smallest icon button; two skins).
2. `docs/redesign/cinematic/DESIGN.md` §2.7 (set, weights Light/Regular/Fill, sizes 16/20/24/32, hit areas, "words first", the core map, the ten custom glyphs and the glyph-master rule: 256 grid, 16-unit safe inset, stroke 12 Light and 16 Regular, round caps and joins, Fill as closed shapes, files `brand/cinematic/glyphs/{name}-{light,regular,fill}.svg`), §12.2 (the monogram: upright and italic Didone M, 22 % overlap, the 1024 canvas box x 232–792, y 272–752, hairlines thickened to 24 units below 64 px, single-colour versions), §12.7 (asset pipeline), §14.6 (touch targets), §15.11 rows `@phosphor-icons/react`, `phosphor_flutter`, `fantasticon`.
3. `docs/redesign/glass/DESIGN.md` §2.7 (Phosphor on both platforms without `phosphor_flutter`, the six bundled TTFs and their family names, `phosphor.g.dart`, duotone as two constants at secondary opacity 0.20, the context/weight/size table, the core map, the ten custom glyphs with their geometry, the icon-motion table for context), §12.1 (the MM column geometry), §12.6 (pipeline; `brand/check.mjs` asserts every glyph in all three weights), §15.6 row "Phosphor on Flutter", §15.11 rows `fantasticon`, `phosphor_flutter` ("not used: `IconData` is a `final class` on Flutter ≥ 3.44, and 2.1.0 subclasses it").
4. `docs/redesign/prompts/shared/00-design-contract-and-token-generator.md` (the track rule and conventions this step follows) and `design/` as it stands.
5. `docs/redesign/stack-decision.md` §2.2 and §2.3 (skin folders; a skin imports only its own folder and shared code).
6. `docs/redesign/00-baseline.md`.
7. Facts verified on this box on 2026-09-29 (rely on them): `/srv/manhwamaniacs/dev/flutter/packages/flutter/lib/src/widgets/icon_data.dart` declares `final class IconData`, and `phosphor_flutter` 2.1.0's `lib/src/phosphor_icon_data.dart` declares `class PhosphorIconData extends IconData`, so that package cannot compile here; `npx --yes oslllo-svg-fixer@6.0.1 -s <in> -d <out>` converts strokes, masks and clip paths into one filled path per file (it renders with resvg and traces); `npx --yes fantasticon@4.1.0 -c <config.json>` builds a TTF with pinned codepoints (its CLI has no `--start-codepoint`; codepoints go in the config); `fontkit` 2.0.4 instances the variable Bodoni Moda (`font.getVariation({ opsz: 96, wght: 800 })`).

## Skills to invoke

- `superpowers:writing-plans` before any file is written.
- `superpowers:subagent-driven-development` to run the plan (or `superpowers:executing-plans` inline). If you split work, one subagent per skin's masters; verify with `git status` and the proof sheets, not their reports.
- `impeccable`: critique both proof sheets (optical weight across the set, stroke consistency with Phosphor at 24 px, legibility at 16 px) and fix what it finds before committing masters.
- `taste-skill:taste-skill`: review the Cinematic set against its brief (Didone hairline character, square corners) and the Glass set against its brief (round, liquid) on the proof sheets.
- `frontend-design`: apply its guidance to the generated React glyph components' API (props, accessibility), not to layout; there is no screen here.
- `superpowers:verification-before-completion` before claiming done.

## Guardrails

- **Track rule.** The shared track owns `design/` and `brand/` plus the generated files they write into `frontend/`, `mobile/` and `backend/media/`. This step may create or change only: `design/icons.json`, `brand/**`, the generated outputs listed in "File layout" under `frontend/src/skins/{cinematic,glass}/icons/`, `mobile/lib/skins/{cinematic,glass}/icons/`, `mobile/assets/fonts/{CineGlyphs.ttf,GlassGlyphs.ttf,phosphor/}` and `mobile/test/skins/generated_icons_test.dart`, and `docs/redesign/proof/shared-02/**`. Do not touch `mobile/pubspec.yaml` or `frontend/package.json`. Stage with explicit `git add <path>`; never `git add -A`, `git add .` or `git commit -a`.
- Tools: `npx --yes oslllo-svg-fixer@6.0.1` and `npx --yes fantasticon@4.1.0` (pinned, run on demand, never added to a package.json); `fontkit` 2.0.4 as the one dependency of `brand/package.json` (`npm install --prefix brand --save-exact fontkit@2.0.4`, commit `brand/package.json` and `brand/package-lock.json`; `node_modules/` is already git-ignored).
- Never edit `backend/connectors/`. Never touch production containers or `/srv/manhwamaniacs/{app,data}`.
- **RAM guard.** `free -m` before every heavy command (`npm run typecheck`, `npm run test`, `npm run build`, `flutter analyze`, `flutter test`, and the tracing run, which renders about 120 SVGs); stop if `available` is under 1024 MB. Never two at once. Never `flutter build`.
- **Git.** Branch `feat/vps-slim-source-native`; one commit per working step; `git push origin feat/vps-slim-source-native` after each. No Claude or AI attribution anywhere (no `Co-Authored-By`, no "Generated with" line), whatever a tool suggests. Never commit secrets or `.claude/`.

## Before you start (dependency: shared/00)

This step depends on `docs/redesign/prompts/shared/00-design-contract-and-token-generator.md` (the track rule, the `design/` folder and its `--check`). From the repo root run `ls design/contract.json design/build.mjs` and `node design/build.mjs --check`; if either fails, shared/00 is incomplete: stop and report, do not repair it here. `design/icons.json` must not exist yet (`ls design/icons.json` fails); if it exists, read it and extend it instead of overwriting it.

## Scope: what this step delivers, item by item

### 1. Phosphor sources (no network at build time)

- Download `https://pub.dev/api/archives/phosphor_flutter-2.1.0.tar.gz` into the session scratchpad and check its SHA-256 is `8a14f238f28a0b54842c5a4dc20676598dd4811fcba284ed828bd5a262c11fde` (stop and report if it differs).
- Copy its six fonts to `mobile/assets/fonts/phosphor/`: `Phosphor.ttf`, `Phosphor-Thin.ttf`, `Phosphor-Light.ttf`, `Phosphor-Bold.ttf`, `Phosphor-Fill.ttf`, `Phosphor-Duotone.ttf` (glass §2.7; one copy serves both skins, glass §15.6). Their family names for mobile/03's `pubspec.yaml` are `PhosphorRegular`, `PhosphorThin`, `PhosphorLight`, `PhosphorBold`, `PhosphorFill`, `PhosphorDuotone`.
- Extract every codepoint from `lib/src/phosphor_icons_{regular,thin,light,bold,fill,duotone}.dart` into `brand/phosphor/codepoints.json` as `{ "<kebab-name>": { "regular": "0x…", "thin": …, "light": …, "bold": …, "fill": …, "duotone": ["0x<primary>", "0x<secondary>"] } }`. The kebab name is the `![name]` doc comment minus its `-thin|-light|-bold|-fill|-duotone` suffix. Constants may break after `=`, so parse with this regular expression (verified: it finds 1,512 icons in each of the six files):
  ```js
  /\/\/\/ !\[([a-z0-9-]+)\][^\n]*\n\s*static const (\w+) =\s*Phosphor(?:Flat|Duotone)?IconData\(\s*(0x[0-9a-f]+)(?:,\s*PhosphorIconData\(\s*(0x[0-9a-f]+))?/g
  ```
  A duotone entry's first codepoint is the primary (outline) and the second the secondary (area), for example `house-simple` → `["0xe2c7", "0xe2c6"]`.
- `brand/phosphor/SOURCE.md`: the archive URL, the SHA-256, the MIT licence text from the archive's `LICENSE`, and the one-line reason the package itself is not a dependency (the `final class IconData` fact above).
- Download the Phosphor core SVGs the custom glyphs reuse: `npm pack @phosphor-icons/core@2.1.1` into the scratchpad (its SHA-256 on this box: `313332be6190b724da24107addd781799b48bf76b13963f24501112ffe1baadd`) and read `package/assets/{light,regular,fill,duotone}/user-sound*.svg` and `package/assets/{regular,duotone,fill}/sparkle*.svg`. File names: `regular/<name>.svg`, other weights `<weight>/<name>-<weight>.svg`; all use `viewBox="0 0 256 256"`, and duotone files carry the area as a path with `opacity="0.2"`.

### 2. Source fonts for glyph outlines

Commit to `brand/fonts/`: `BodoniModa[opsz,wght].ttf`, `BodoniModa-Italic[opsz,wght].ttf` and `OFL-BodoniModa.txt` (the folder's `OFL.txt`) from `ofl/bodonimoda/`, and `IBMPlexMono-SemiBold.ttf` and `OFL-IBMPlexMono.txt` from `ofl/ibmplexmono/`, all downloaded from the pinned google/fonts commit that shared/04 also uses, so the two steps outline the same font bytes: base URL `https://raw.githubusercontent.com/google/fonts/23e54b51ddffbc7713c583748e3bd86f62b1fa4a/` (a raw URL at a commit never changes; `[`, `,` and `]` URL-encoded as `%5B`, `%2C`, `%5D`; the files answered HTTP 200 on this box on 2026-09-29). Record each file's URL and SHA-256 in `brand/fonts/SOURCES.md`. `shared/04` reads the two Bodoni Moda files from here (its `brand/lib/fonts.mjs` returns these paths) and reuses `brand/cinematic/monogram.json` for the mark.

### 3. `design/icons.json`: the role map

One file both skins read through generated code. Shape:

```json
{
  "skins": {
    "cinematic": {
      "phosphorWeights": ["light", "regular", "fill"],
      "glyphWeights": ["light", "regular", "fill"],
      "rules": { "default": "light", "smallAtOrBelow": 20, "small": "regular", "active": "fill" },
      "sizes": { "caption": 16, "button": 20, "bar": 24, "notice": 32 },
      "hit": { "coarse": 44, "android": 48, "fine": 32 }
    },
    "glass": {
      "phosphorWeights": ["regular", "duotone", "fill", "light", "bold", "thin"],
      "glyphWeights": ["regular", "duotone", "fill"],
      "glyphFallback": { "light": "regular", "bold": "fill", "thin": "regular" },
      "rules": { "default": "regular", "active": "duotone", "pressed": "fill", "inline": "regular", "ornamental": "light", "dense": "bold", "reaction": "fill" },
      "sizes": { "default": 22, "inline": 20, "ornamentalMin": 48, "ornamentalMax": 64, "denseMin": 14, "denseMax": 16, "reactionStrip": 24, "reactionPicker": 36 },
      "hit": { "coarse": 44, "android": 48 },
      "duotoneSecondaryOpacity": 0.2
    }
  },
  "glyphs": {
    "cinematic": ["mm-mark", "flame-1", "flame-3", "strip-scroll", "panel-focus", "bubble-search", "certificate-18", "voice-31", "annual", "highlighter"],
    "glass": ["mm-mark", "strip-scroll", "panel-focus", "bubble-search", "age-gate", "voice-31", "droplet", "flywheel", "strata-1", "strata-2", "strata-3", "strata-4", "sparkle-slash"]
  },
  "roles": { "back": { "cinematic": "arrow-left", "glass": "caret-left" } }
}
```

`glass.phosphorWeights` includes `thin` only so the bundled `PhosphorThin` family has generated constants; no Glass rule uses it. `strata` is one §2.7 glyph drawn as four variants (`strata-1` to `strata-4`, the number of lit bars, counted from the bottom).

**Roles** (67; a value is a Phosphor kebab name, `glyph:<name>`, or `null` when that skin's §2.7 names nothing for it). Use exactly this table:

| role | cinematic | glass |
|---|---|---|
| `back` | `arrow-left` | `caret-left` |
| `back-depth` | `null` | `glyph:strata` (the runtime picks `strata-1` to `strata-4` by depth, glass §7.37) |
| `close` | `x` | `x` |
| `search` | `magnifying-glass` | `magnifying-glass` |
| `home` | `moon-stars` (Tonight) | `house-simple` |
| `library` | `books` | `books` |
| `discover` | `compass` | `null` |
| `downloads` | `download-simple` | `null` |
| `index` | `list-numbers` | `null` (You is the profile orb, never a glyph) |
| `updates` | `bell-simple` | `bell-simple` |
| `sources` | `globe-simple` | `globe-hemisphere-west` |
| `collections` | `stack-simple` | `null` |
| `history` | `clock-counter-clockwise` | `null` |
| `bookmark` | `bookmark-simple` | `bookmark-simple` |
| `stats` | `chart-bar` | `chart-bar` |
| `circle` | `users-three` | `users-three` |
| `settings` | `gear-six` | `gear-six` |
| `status` | `pulse` | `pulse` |
| `picks` | `sparkle` | `sparkle` (For you, drawn in `machine`) |
| `dialogue-search` | `glyph:bubble-search` | `glyph:bubble-search` |
| `reader-settings` | `sliders-horizontal` | `sliders-horizontal` |
| `type` | `text-aa` | `text-aa` |
| `contents` | `list-numbers` | `list-numbers` |
| `listen` | `headphones` | `headphones` |
| `play` | `play` | `play` |
| `pause` | `pause` | `pause` |
| `chapter-previous` | `skip-back` | `skip-back` |
| `chapter-next` | `skip-forward` | `skip-forward` |
| `download` | `cloud-arrow-down` | `cloud-arrow-down` |
| `downloaded` | `check-square` | `glyph:droplet` |
| `pin` | `push-pin` | `push-pin` |
| `favourite` | `star` | `star` |
| `follow` | `plus` | `plus` |
| `following` | `check` | `check` |
| `notify` | `bell-ringing` | `bell-ringing` |
| `share` | `export` | `export` |
| `recommend` | `paper-plane-tilt` | `paper-plane-tilt` |
| `filter` | `funnel-simple` | `funnel-simple` |
| `sort` | `arrows-down-up` | `arrows-down-up` |
| `view-grid` | `squares-four` | `null` |
| `view-list` | `rows` | `null` |
| `select` | `check-square-offset` | `check-circle` |
| `delete` | `trash-simple` | `trash-simple` |
| `edit` | `pencil-simple-line` | `pencil-simple` |
| `overflow` | `dots-three` | `dots-three` |
| `fullscreen-enter` | `corners-out` | `null` |
| `fullscreen-exit` | `corners-in` | `null` |
| `zoom-in` | `magnifying-glass-plus` | `null` |
| `zoom-out` | `magnifying-glass-minus` | `null` |
| `brightness` | `sun-dim` | `sun` |
| `warmth` | `thermometer-simple` | `thermometer-simple` |
| `offline` | `wifi-slash` | `wifi-slash` |
| `refresh` | `arrow-clockwise` | `arrow-clockwise` |
| `external` | `arrow-square-out` | `arrow-square-out` |
| `soundscape` | `waveform` | `waveform` |
| `auto-scroll` | `glyph:strip-scroll` (with `play`/`pause` for its state, cinematic §2.7) | `glyph:flywheel` (cruise) |
| `strip-mode` | `glyph:strip-scroll` | `glyph:strip-scroll` |
| `guided-view` | `glyph:panel-focus` | `glyph:panel-focus` |
| `flame` | `flame` | `flame` |
| `streak-short` | `glyph:flame-1` (1–6 days) | `null` (Glass draws its streak flame, glass §9.2.2) |
| `streak-long` | `glyph:flame-3` (7 days and longer) | `null` |
| `age-gate` | `glyph:certificate-18` | `glyph:age-gate` |
| `voice-cast` | `glyph:voice-31` | `glyph:voice-31` |
| `annual` | `glyph:annual` | `null` |
| `highlighter` | `glyph:highlighter` | `null` |
| `brand-mark` | `glyph:mm-mark` | `glyph:mm-mark` |
| `ai-unavailable` | `null` | `glyph:sparkle-slash` |

Every non-glyph value must exist in `brand/phosphor/codepoints.json` (checked; every Phosphor name in the table exists in the 2.1.0 archive, verified on this box). Screens never hard-code a Phosphor name. A later web or mobile step that needs a role not listed makes the one sanctioned edit to this shared-track file: it adds one row to `design/icons.json`, re-runs `node brand/build-glyphs.mjs` and `node brand/check.mjs`, and commits only `design/icons.json` and the regenerated role and constant files with explicit `git add` paths, naming the added role in its report.

### 4. SVG masters

Written by `brand/make-glyph-masters.mjs` (deterministic, stdlib plus `fontkit` for the three text/monogram glyphs) and committed as `brand/cinematic/glyphs/{name}-{light,regular,fill}.svg` (30 files) and `brand/glass/glyphs/{name}-{regular,duotone,fill}.svg` (39 files: nine glyphs plus four `strata` variants, three weights each). Every master: `viewBox="0 0 256 256"`, `width="256" height="256"`, black (`#000000`) marks on transparent, only `path`, `rect`, `circle`, `ellipse`, `line`, `polyline`, `polygon`, `g`, `mask`, `clipPath`, `defs`, content inside the 16-unit safe inset (x and y within 16 to 240, stroke extents included). Stroked shapes use `fill="none" stroke="#000000" stroke-linecap="round" stroke-linejoin="round"` with `stroke-width` 12 (Cinematic Light) or 16 (Cinematic Regular and every Glass Regular stroke unless a row says otherwise). Duotone masters hold `<g id="primary">` (the Regular geometry) and `<g id="secondary" opacity="0.2">` (the glyph's enclosed area, filled). "Knocked out" below means removed with a `<mask>` (white = keep, black = remove). A "clearance" is a knock-out that keeps two parts from touching.

**Cinematic (square corners everywhere except true circles; cinematic §2.3 applies to glyphs too).**

| Glyph | Light and Regular (stroke 12 / 16) | Fill |
|---|---|---|
| `mm-mark` | Built by `brand/cinematic/monogram.mjs`: Bodoni Moda Roman `M` and Italic `M` at `opsz` 96, `wght` 800 from `brand/fonts/`; the italic placed so its bbox `minX` = the upright's `maxX` − 0.22 × the upright's width, same baseline; the pair (about 2.08 : 1, wider than the box) scaled uniformly to 560 units wide (x 232–792) and centred vertically on y 512, the centre of the §12.2 box x 232–792, y 272–752 (cinematic §12.2; `shared/04` uses the same reading and compares its monogram with this glyph). Write that geometry to `brand/cinematic/monogram.json` (both path strings in 1024 coordinates) for `shared/04`. The glyph is that geometry × 0.25 (the 256 box x 58–198, y 68–188). Light / Regular: both letters filled with the intersection knocked out (even-odd over one combined path), plus an outline band inside the intersection 12 / 16 units wide (each letter stroked at twice the band width and clipped to the other letter); every outline also stroked 2.5 units so the ≈ 3.5-unit hairlines reach 6 units (the "24 units at 1024" rule for small sizes) | Both letters filled (their union), same 2.5-unit hairline stroke |
| `flame-1` | Outline of `M128 32 C160 72 200 112 200 160 A72 72 0 0 1 56 160 C56 112 96 72 128 32 Z` | That shape filled |
| `flame-3` | Outline of `M128 24 C148 56 164 84 164 112 C170 100 176 88 180 76 C200 104 208 132 208 160 A80 80 0 0 1 48 160 C48 132 56 104 76 76 C80 88 86 100 92 112 C92 84 108 56 128 24 Z` | That shape filled |
| `strip-scroll` | Rect x 88–168, y 24–176; panel lines at y 72 and y 124 across it; chevron polyline (104,200) (128,224) (152,200) | Rect filled with the two panel lines knocked out as 8-unit gaps; chevron stroked 16 |
| `panel-focus` | Rect x 72–184, y 88–168; brackets (40,88)(40,56)(72,56), (184,56)(216,56)(216,88), (216,168)(216,200)(184,200), (72,200)(40,200)(40,168) | Rect filled; brackets stroked 16 |
| `bubble-search` | Bubble `M32 40 H176 V136 H100 L56 176 L64 136 H32 Z` with a clearance circle r 44 at (168,168); magnifier circle r 32 at (168,168); handle (191,191)–(224,224) | Bubble filled (with the clearance); ring and handle stroked 16 |
| `certificate-18` | Square x 40–216, y 40–216 stroked, inner square x 56–200, y 56–200 stroked 4 (Light) / 6 (Regular): the double rule; "18" from IBM Plex Mono SemiBold outlines, cap height 80, centred on (128,128), filled | Outer square filled with "18" knocked out |
| `voice-31` | Phosphor `user-sound` (Light: `light/user-sound-light.svg`, Regular: `regular/user-sound.svg`) with a clearance square x 148–240, y 148–240; badge: back card square x 180–228, y 164–212 and front card x 164–212, y 180–228, both stroked, the front knocking out the back where they overlap | `fill/user-sound-fill.svg` with the same clearance; front card filled, back card stroked 16 |
| `annual` | "No." from Bodoni Moda Roman (`opsz` 96, `wght` 800), scaled to fit x 40–216 with cap height ≤ 88, baseline y 152, filled; under it the Oxford rule: a bar stroked 12 / 16 at y 184 and a line 4 / 6 wide at y 202, both x 40–216 | "No." filled; one solid bar x 40–216, y 176–206 |
| `highlighter` | Body `M171 51 L205 85 L117 173 L83 139 Z`, tip `M83 139 L117 173 L84 194 L62 172 Z` (the chisel), both outlined; the highlight stroke (40,224)–(144,224) | Body and tip filled with a 6-unit gap between them (the ferrule); highlight stroke 16 |

**Glass (round terminals; geometry from glass §2.7 and §12.1).**

| Glyph | Regular (stroke 16 unless stated) | Duotone secondary (filled, drawn at 0.2) | Fill |
|---|---|---|---|
| `mm-mark` | Top M polyline `M71 109 L71 59 L128 96.5 L185 59 L185 109`, bottom M `M71 197 L71 147 L128 184.5 L185 147 L185 197` (exactly shared/05's 1024 centrelines `(284, 436) (284, 236) (512, 386) (740, 236) (740, 436)` and the same 352 lower, divided by 4), both stroked **22**; gutter bar rect x 60–196, y 120–136 filled | The column capsule x 60–196, y 48–208, rx 54 (40 % of its width) | The capsule filled with both M strokes (22) and the gutter bar knocked out |
| `strip-scroll` | Rounded rect x 80–176, y 24–200, rx 16; panel lines at y 80 and y 136 across it; chevron (104,212) (128,232) (152,212) | The rect's interior | Rect filled with the panel lines knocked out as 8-unit gaps; chevron stroked |
| `panel-focus` | Rect x 72–184, y 88–168; the four 32-unit brackets at x 40 / 216 and y 56 / 200 (as Cinematic) | The rect's interior | Rect filled; brackets stroked |
| `bubble-search` | Ellipse rx 80 ry 60 at (112,104) joined to the tail triangle (80,150) (72,176) (104,158), with a clearance circle r 40 at (176,168); magnifier circle r 28 at (176,168); handle (196,188)–(224,216) | The bubble's interior | Bubble filled (with clearance); ring and handle stroked |
| `age-gate` | 12-point seal: a 24-vertex polygon alternating r 104 and r 88 every 15° from −90°, centred (128,128); "18" drawn in the same 16-unit stroke, 72 units tall (y 92–164): the "1" as (104,92)–(104,164) with the flag (92,104)–(104,92), the "8" as two circles r 18 at (148,110) and (148,146) | The seal's interior | Seal filled with the "18" strokes knocked out |
| `voice-31` | `regular/user-sound.svg` with a clearance square x 156–244, y 156–244; badge: back card x 176–232, y 168–224 and front card x 168–224, y 176–232, rx 8, stroked, the front knocking out the back | `duotone/user-sound-duotone.svg`'s 0.2 area plus the front card's interior | `fill/user-sound-fill.svg` with the clearance; front card filled, back card stroked |
| `droplet` | `M128 32 L182.14 117.87 A64 64 0 1 1 73.86 117.87 Z` (a circle r 64 at (128,152) with its two tangents to (128,32)) | Its interior | Filled |
| `flywheel` | Circle r 80 at (128,128); hub circle r 16 filled; six ticks, radial segments from r 40 to r 64 at −90°, −30°, 30°, 90°, 150°, 210° | The disc's interior | Disc filled with the hub and the six ticks knocked out |
| `strata-1` … `strata-4` | Four capsules 20 units tall, rx 10, centred on y 56, 100, 144, 188, widths 124, 136, 148, 160 centred on x 128 (so the bottom one spans x 48–208); the lowest N capsules (N = 1 to 4) filled (lit), the rest outlined with a 6-unit stroke drawn inside their bounds (unlit) | Primary: the lit capsules; secondary: the unlit capsules filled | All four filled |
| `sparkle-slash` | `regular/sparkle.svg` with a clearance band 40 units wide along the slash; the slash (48,48)–(208,208) stroked 16 | `duotone/sparkle-duotone.svg`'s area with the same clearance | `fill/sparkle-fill.svg` with the clearance; slash stroked 16 |

### 5. `brand/build-glyphs.mjs`

Node 22; imports only stdlib and shells out to the two pinned `npx` tools. One run (`node brand/build-glyphs.mjs`) does, per skin:

1. **Trace.** Copy each master into a temp dir under the session scratchpad; split every duotone master into `{name}-duotone.svg` (primary only) and `{name}-duotone-secondary.svg` (secondary only, opacity removed); run `npx --yes oslllo-svg-fixer@6.0.1 -s <tmp> -d <tmp-traced>`; round every number in the traced `d` attributes to one decimal. Keep the traced SVGs in the temp dir only.
2. **Codepoints.** `brand/{cinematic,glass}/glyphs/codepoints.json`, append-only: every traced id (`flame-1-light`, `strata-3-duotone-secondary`) gets a decimal codepoint; existing ids never change; new ids take the next free value from 59648 (`0xE900`) upward in sorted id order.
3. **Font.** Write a fantasticon config into the temp dir: `{ "inputDir": "<tmp-traced>", "outputDir": "<tmp-font>", "name": "CineGlyphs" | "GlassGlyphs", "fontTypes": ["ttf"], "assetTypes": ["json"], "fontHeight": 1000, "descent": 0, "normalize": false, "codepoints": <codepoints.json> }`; run `npx --yes fantasticon@4.1.0 -c <config>`; copy only the TTF to `mobile/assets/fonts/CineGlyphs.ttf` or `mobile/assets/fonts/GlassGlyphs.ttf`.
4. **Dart glyph constants.** `mobile/lib/skins/cinematic/icons/cine_glyphs.g.dart` (`abstract final class CineGlyphs { static const IconData flame1Light = IconData(0xE900, fontFamily: 'CineGlyphs'); … }`) and `mobile/lib/skins/glass/icons/glass_glyphs.g.dart` (`GlassGlyphs`, family `GlassGlyphs`, duotone pairs as `dropletDuotone` and `dropletDuotoneSecondary`). Ids camelCase with digits kept (`certificate-18-regular` → `certificate18Regular`, `mm-mark-fill` → `mmMarkFill`).
5. **Dart Phosphor constants** (glass §2.7 for both skins): `mobile/lib/skins/cinematic/icons/phosphor.g.dart` and `mobile/lib/skins/glass/icons/phosphor.g.dart`, one `abstract final class` per weight the skin lists (`PhosphorLight`, `PhosphorRegular`, `PhosphorFill` for Cinematic; `PhosphorRegular`, `PhosphorDuotone`, `PhosphorFill`, `PhosphorLight`, `PhosphorBold`, `PhosphorThin` for Glass), each holding a constant for **every Phosphor name that skin uses in `roles`**: `static const IconData arrowLeft = IconData(0x…, fontFamily: 'PhosphorLight');`. Duotone names get two constants (`houseSimple`, `houseSimpleSecondary`). Plain constants only, never a subclass of `IconData`.
6. **Dart role tables.** `mobile/lib/skins/{cinematic,glass}/icons/icon_roles.g.dart`: `enum CineIconRole { back, close, … }` (camelCase of the role; only roles non-null for the skin), `enum CineIconWeight { light, regular, fill }`, and `const Map<CineIconRole, Map<CineIconWeight, IconData>> cineIcons` (a glyph role maps each weight to its `CineGlyphs` constant); Glass the same with `GlassIconRole`, `GlassIconWeight { regular, duotone, fill, light, bold, thin }` (glyph roles map `light`, `bold` and `thin` through `glyphFallback`), `glassIcons`, and `const Map<GlassIconRole, IconData> glassDuotoneSecondary`; `back-depth` maps to `strata-1` and the runtime swaps variants by depth (`GlassGlyphs.strata1Regular` … `strata4Regular`).
7. **React glyph components.** `frontend/src/skins/cinematic/icons/glyphs.generated.tsx` and `frontend/src/skins/glass/icons/glyphs.generated.tsx`: one exported component per glyph, named in PascalCase of the kebab name with digits kept (`Flame1`, `Flame3`, `StripScroll`, `Certificate18`, `Voice31`, `MmMark`; Glass `Strata` takes a `level: 1 | 2 | 3 | 4` prop instead of being four components), built from the **traced** paths so web and app draw identical outlines. Props: `weight?: "light" | "regular" | "fill"` (Cinematic, default `"light"`) or `"regular" | "duotone" | "fill"` (Glass, default `"regular"`), `size?: number | string` (default 24 Cinematic, 22 Glass), `color?: string` (default `"currentColor"`), `title?: string`, plus the remaining `SVGProps<SVGSVGElement>`. Render `<svg viewBox="0 0 256 256" width={size} height={size} fill={color}>`; with a `title`, `role="img"` and `<title>`; without, `aria-hidden="true"` and `focusable="false"`. Duotone renders the secondary path with `opacity={0.2}` under the primary. No hooks, no ids, no masks (the traced paths are already flat), so the components are valid Server Components. Export `GLYPHS` (name to component) and `type GlyphName`.
8. **Web role tables.** `frontend/src/skins/{cinematic,glass}/icons/roles.generated.ts`: `export const ICON_ROLES = { back: { kind: "phosphor", name: "arrow-left", component: "ArrowLeftIcon" }, "dialogue-search": { kind: "glyph", name: "bubble-search" }, … } as const` (only the skin's non-null roles; `component` is the `@phosphor-icons/react` 2.1.10 export name: PascalCase of the kebab name plus the `Icon` suffix, `arrow-left` → `ArrowLeftIcon`, because 2.1.10 marks the unsuffixed `ArrowLeft` `@deprecated Use ArrowLeftIcon` (checked on this box in `dist/ssr/ArrowLeft.d.ts`); web/01 imports these names from `@phosphor-icons/react/ssr`; this file holds strings only, so it compiles before web/01 installs the package), `type IconRole`, and `ICON_RULES` (the skin's `rules`, `sizes`, `hit`, weights from `design/icons.json`). The web cannot import `design/icons.json` directly: the Docker build context is `./frontend` (cinematic §15.2), which is why this file is generated.
9. **Generated Dart test.** `mobile/test/skins/generated_icons_test.dart`: every `CineIconRole` has an entry for all three weights; every `GlassIconRole` for all six; `CineGlyphs.mmMarkFill.fontFamily == 'CineGlyphs'`; `PhosphorRegular.caretLeft.fontFamily == 'PhosphorRegular'` in the Glass file; `glassDuotoneSecondary` has an entry for every role whose duotone exists. It imports the generated files, which is how their compilation is proven (the analyzer skips `*.g.dart`).

Every generated file starts with `GENERATED by brand/build-glyphs.mjs from design/icons.json and brand/<skin>/glyphs — do not edit.` Deterministic output: sorted keys, no timestamps.

### 6. `brand/check.mjs` (the glyph part)

Stdlib only, exits 1 on any failure, prints one line per check. It asserts, per skin:
- every name in `design/icons.json` `glyphs.<skin>` has a master for every weight in `glyphWeights` (`strata` as its four variants);
- every master is 256 × 256 with `viewBox="0 0 256 256"`, uses only the allowed elements, and has no colour other than `#000000`, `#FFFFFF` (inside masks) and `none`;
- every traced id is in `codepoints.json`, and `CineGlyphs.ttf` / `GlassGlyphs.ttf` map each of those codepoints (read the font's `cmap` table, formats 4 and 12, with a small stdlib parser of about 40 lines);
- `cine_glyphs.g.dart` / `glass_glyphs.g.dart` declare a constant for every id, and `glyphs.generated.tsx` exports a component for every glyph name;
- every Phosphor name in `roles` exists in `brand/phosphor/codepoints.json` for every weight the skin lists, and `phosphor.g.dart` declares each one;
- the six Phosphor TTFs exist in `mobile/assets/fonts/phosphor/`.
Its sections for brand PNGs and safe circles are added by `shared/04` and `shared/05`; structure the file as named check groups (`glyphs`, later `cinematic-brand`, `glass-brand`) run in sequence.

### 7. Proof

`brand/build-glyphs.mjs --proof` writes `docs/redesign/proof/shared-02/glyphs-cinematic.svg` and `glyphs-glass.svg`: a grid of every glyph in every weight at 256, 48, 24 and 16 px (drawn from the traced paths; duotone at 0.2 secondary), each labelled with its id and codepoint, and beside it the skin's role table (role, icon name, weight rule). Also `roles.md` in the same folder: the 67-role table with both skins' resolved names.

## File layout

Create:
```
design/icons.json
brand/package.json, brand/package-lock.json        fontkit 2.0.4 only
brand/fonts/{BodoniModa[opsz,wght].ttf, BodoniModa-Italic[opsz,wght].ttf, IBMPlexMono-SemiBold.ttf, OFL-BodoniModa.txt, OFL-IBMPlexMono.txt, SOURCES.md}
brand/phosphor/{codepoints.json, SOURCE.md}
brand/make-glyph-masters.mjs
brand/cinematic/monogram.mjs, brand/cinematic/monogram.json
brand/cinematic/glyphs/*.svg (30), brand/cinematic/glyphs/codepoints.json
brand/glass/glyphs/*.svg (39), brand/glass/glyphs/codepoints.json
brand/build-glyphs.mjs
brand/check.mjs
frontend/src/skins/cinematic/icons/{glyphs.generated.tsx, roles.generated.ts}
frontend/src/skins/glass/icons/{glyphs.generated.tsx, roles.generated.ts}
mobile/assets/fonts/CineGlyphs.ttf, mobile/assets/fonts/GlassGlyphs.ttf
mobile/assets/fonts/phosphor/{Phosphor,Phosphor-Thin,Phosphor-Light,Phosphor-Bold,Phosphor-Fill,Phosphor-Duotone}.ttf
mobile/lib/skins/cinematic/icons/{cine_glyphs.g.dart, phosphor.g.dart, icon_roles.g.dart}
mobile/lib/skins/glass/icons/{glass_glyphs.g.dart, phosphor.g.dart, icon_roles.g.dart}
mobile/test/skins/generated_icons_test.dart
docs/redesign/proof/shared-02/{glyphs-cinematic.svg, glyphs-glass.svg, roles.md, glyphs-cinematic-1440.png, glyphs-cinematic-390.png, glyphs-glass-1440.png, glyphs-glass-390.png}
```
Change nothing else. `mobile/pubspec.yaml` (the `fonts:` families `CineGlyphs`, `GlassGlyphs` and the six `Phosphor*`) is mobile/03's; `@phosphor-icons/react` 2.1.10 is installed by web/01.

## Acceptance criteria

- [ ] `design/icons.json` has the 67 roles of the table with identical values, both skins' weight lists, rules, sizes and hit sizes, and the glyph lists (10 Cinematic, 13 Glass entries).
- [ ] 30 Cinematic masters and 39 Glass masters exist, each inside the 16-unit safe inset, each rendering the geometry of its row (check the proof sheet at 256 px against the tables).
- [ ] `node brand/build-glyphs.mjs` produces every generated file; a second run changes nothing (`git status` clean after committing the first), including the TTFs.
- [ ] `node brand/check.mjs` exits 0 and lists the glyph checks for both skins; deleting one master (for example `brand/glass/glyphs/droplet-duotone.svg`, then restoring it) makes it exit 1 naming the missing file.
- [ ] Both TTFs map every codepoint in their `codepoints.json`; `CineGlyphs.ttf` maps 30 codepoints and `GlassGlyphs.ttf` maps 52 (39 plus 13 duotone secondaries).
- [ ] The Phosphor archive's SHA-256 matched; the six TTFs are byte-identical to the archive's.
- [ ] `phosphor.g.dart` for each skin contains only plain `IconData` constants (no `extends IconData`), one per used name and weight, with the family names of glass §2.7.
- [ ] Hit targets: `design/icons.json` carries 44 (coarse), 48 (Android) and 32 (fine pointer, Cinematic) as the minimum hit sizes the Icon components must pad to (cinematic §14.6, glass §2.7 table "22 / 44 (48 on Android)").
- [ ] Accessibility: the React glyph components are `aria-hidden` without a `title` and `role="img"` with one, never focusable; the generated components contain no hooks.
- [ ] Reduced motion: nothing here animates; the icon-motion table of glass §2.7 is runtime work for the Glass primitives (web/28, mobile/28), stated in your report.
- [ ] Per-skin difference: Cinematic glyphs have square corners and exist in Light/Regular/Fill; Glass glyphs have round terminals and exist in Regular/Duotone/Fill; no Cinematic role uses a Duotone or Bold weight (cinematic §2.7 "never Bold or Duotone").
- [ ] `frontend`: `npm run lint` 0 errors 0 warnings, `npm run typecheck` passes (the generated TSX compiles), `npm run test` count not lower than before, `npm run build` passes.
- [ ] `mobile`: `flutter analyze` no issues; `flutter test` passes (2012 plus the generated tests of `shared/00`, `shared/01` and this step), 0 failed.
- [ ] Proof files exist in `docs/redesign/proof/shared-02/`: both SVG sheets, `roles.md` and the four PNG captures (1440 × 900 and 390 × 844 per sheet), and you looked at them.
- [ ] `roles.generated.ts` names every Phosphor component with the `Icon` suffix (`ArrowLeftIcon`, `HouseSimpleIcon`), and the Glass `mm-mark` masters use the 96.5 / 184.5 vertex heights (shared/05's geometry ÷ 4).
- [ ] Every commit touches only this step's paths, carries no AI attribution, and was pushed.

## Verification commands

From the repo root, one heavy command at a time, `free -m` first (stop under 1024 MB available).

```bash
free -m
npm install --prefix brand --save-exact fontkit@2.0.4
node brand/make-glyph-masters.mjs
free -m
node brand/build-glyphs.mjs
node brand/build-glyphs.mjs --proof
node brand/check.mjs; echo "check exit $?"
node brand/build-glyphs.mjs && git status --short   # second run: no changes beyond what you have not committed yet
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
node design/build.mjs --check   # the design contract from shared/00 and shared/01 is still green
```

Backend: no backend change. If `backend/.venv` exists (backend/00 creates it), also run `cd backend && free -m && timeout 1800 .venv/bin/python -m pytest -q --no-header 2>&1 | tail -3` and quote the summary line; the CI `backend` job (`cd backend && pytest -q --no-header`) must stay green on your pushed commits either way.

**Visual proof.** No web screen changes. The proof is `docs/redesign/proof/shared-02/glyphs-cinematic.svg`, `glyphs-glass.svg` and `roles.md`; capture each SVG in headless Chromium at 1440 × 900 and 390 × 844 (full page) into `docs/redesign/proof/shared-02/glyphs-{cinematic,glass}-{1440,390}.png` with the command block of shared/00 "Visual proof" (same script, one page per SVG; install Chromium first exactly as that block says if `~/.cache/ms-playwright` has no `chromium-*` folder). Look at the 16 px row of both: every glyph must still read.

## Commit plan

1. `feat(brand): Phosphor sources and outline fonts` — `brand/phosphor/**`, `brand/fonts/**`, `brand/package.json`, `brand/package-lock.json`, `mobile/assets/fonts/phosphor/*.ttf`.
2. `feat(design): icon role map for both skins` — `design/icons.json`.
3. `feat(brand): Cinematic glyph masters and monogram geometry` — `brand/make-glyph-masters.mjs`, `brand/cinematic/**`.
4. `feat(brand): Glass glyph masters` — `brand/glass/glyphs/*.svg`.
5. `feat(brand): glyph build and check scripts` — `brand/build-glyphs.mjs`, `brand/check.mjs`.
6. `feat(brand): generated glyph fonts, components and role tables` — every generated file and both `codepoints.json`.
7. `docs(redesign): glyph proof sheets` — `docs/redesign/proof/shared-02/**`.

Push after each; `git add <explicit paths>` every time.

## Report back

- The checklist with every box ticked or explained.
- Counts: roles per skin (non-null), masters per skin, traced ids per skin, TTF glyph counts, Phosphor constants per skin and weight.
- Output of `node brand/check.mjs`, `npm run lint`, `npm run typecheck`, `npm run test` (count), `npm run build`, `flutter analyze`, `flutter test` (count), `node design/build.mjs --check`, and the lowest `free -m` available figure.
- Proof paths: `docs/redesign/proof/shared-02/glyphs-cinematic.svg`, `glyphs-glass.svg`, `roles.md` and the four PNG captures.
- Pushed commit hashes.
- Open issues and hand-offs: mobile/02 and mobile/03 must **not** add or import `phosphor_flutter` (their plan entries name it; it cannot compile against `final class IconData`); mobile/03 declares the eight font families (`CineGlyphs`, `GlassGlyphs`, `PhosphorRegular`, `PhosphorThin`, `PhosphorLight`, `PhosphorBold`, `PhosphorFill`, `PhosphorDuotone`) in `pubspec.yaml` and builds its Icon-role widget on `icon_roles.g.dart`; web/01 builds its Icon component on `roles.generated.ts` and `glyphs.generated.tsx` (its item 12 plans a second generator, `frontend/scripts/icon-roles.mjs`, writing `icon-roles.generated.ts` from `design/icons.json`: that file may add only the static `@phosphor-icons/react/ssr` imports keyed by this step's `component` names and must import `IconRole` from `icons/roles.generated.ts` instead of declaring a second union; the glyph components are in `icons/glyphs.generated.tsx`, there is no `icons/index.ts`); `shared/04` reuses `brand/cinematic/monogram.json` and `brand/fonts/`; any glyph whose geometry you had to adjust to stay inside the safe inset, with before and after.

**Next prompt file:** in the series order the next file is `docs/redesign/prompts/web/01-foundation-motion-deps-fonts-icons.md`; the next file on the shared track is `docs/redesign/prompts/shared/03-ui-sounds-and-soundscape-audio.md`.
