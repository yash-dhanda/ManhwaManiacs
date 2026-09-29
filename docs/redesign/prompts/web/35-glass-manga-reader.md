# Web Glass manga reader

Track: web · Order 88 · Depends on: `docs/redesign/prompts/web/34-reader-engine-glass-commands.md` · Runs in parallel with: `docs/redesign/prompts/mobile/35-glass-manga-reader.md` · Proof folder: `docs/redesign/proof/web-35/`

## Goal

Build the Glass manga reader on the web client (`frontend/`), glass §8.14, as chrome over the shared reader engine (`useReaderEngine()` and its `renderChrome(state)` slot in `frontend/src/features/reader/engine/`): the black canvas with brightness, warmth and colour layers; floating `glassRegular` capsules tinted by the current page with the adaptive legibility dim; the scrub rail with its magnifier lens and the go-to-page popover; auto-hide and the minimised pill, cinema and locked modes; the gestures (pinch, anchored double tap, tap bands, the pull past the chapter end that arms at 48 and commits at 72 with momentum, the opt-in sideways chapter swipe, Ctrl/⌘ + wheel, middle-click autoscroll); chapter seams and the seam chip; paged single and double with Slide, Fade and None; read-all; the reader settings sheet with the migrated values of §8.25.3; every state and key; the in-reader chapter list; the dialogue overlay and the 1.12 × hit lens; the reader landing; the desktop page-lit gutters and material side panels; tablet, mobile-web and landscape deltas; and the manga-reader row of the live-surface budget. The skin never moves the page layer itself: every page movement is an engine command. When you finish, the ScreenIds `reader`, `readAll` and `readerLanding` leave the Glass `PENDING` set, and both entry points (the followed-series page and the source series page) are proven. Glass stays behind the debug row; Cinematic must not change by a single pixel.

## Read first

Read these completely before planning. Where this file and `glass/DESIGN.md` disagree, `glass/DESIGN.md` wins; say so in the report.

1. `docs/redesign/inventory/00-decisions.md` (the reader references: Webtoon app vertical scroll, auto-hide chrome, next-chapter card) and `docs/redesign/00-baseline.md`.
2. `docs/redesign/stack-decision.md` §2.2 and §4 risk 5 (glass on chrome only, never inside the strip).
3. `docs/redesign/glass/DESIGN.md`:
   - §8.14 in full: §8.14.1 canvas, §8.14.2 chrome, §8.14.3 gestures and input, §8.14.4 chapter boundaries, §8.14.5 reader settings sheet, §8.14.6 states, §8.14.7 keys, §8.14.8 chapter list, §8.14.9 dialogue overlay and hit lens, §8.14.10 reader landing, §8.14.11 platform deltas.
   - §9.4.4 page-tinted chrome (all of it: this step builds it for the manga reader), §9.4.1 "Entry" and "Persistence" only (the cruise button and `cruiseSpeed`), §8.25.3 (the migration table rows Brightness, Warmth, Cruise speed, Page transition, Direction/fit/zoom, Reader background).
   - §2.1.7 (`dimLegibility = clamp(0.22 + 0.42 × Lb, 0.22, 0.64)`, the reader rows of the `Lb` table, `dimShift`, `Lb = 1.0` until a sample lands), §2.1.8 step 3 (`PageSample`) and the reader rows of the field table, §3.5 (the label `GRAD` follows `Lb`), §2.4.1 (the reader strip never holds glass; content twins; `twinDense`; bar groups are one masked element), §2.4.2 rules 1, 7 and 8, §2.5.
   - Components: §7.2, §7.10 (sheets; the desktop panel), §7.12 (toasts inside readers: top-centre at 60 px), §7.19 (hairline progress, liquid ring), §7.21 (scrub rail, fill slider, slider), §7.22 (switch), the Stepper row of §7.3, §7.23 (menus, the page menu), §7.24 (object lens), §7.29 (download control), §7.30 (status capsules), §7.37 (the back button, the depth indicator, the back menu).
   - Motion and feedback: §4.2, §4.3, §4.4 (Reader scrub rail row), §4.5 (zoom ±0.18, chapter end), §4.6 (double tap 280 ms and 24 px; chrome auto-hide; chapter-end pull), §4.9, §4.10 rows Materialise, Dematerialise, Minimise, Scrub lens, Chapter card rise, Seam chip, Hit lens, Page slide, Tap light, Zoom, Dive, Surface, Bloom, Sheet present, Letter reveal, Liquid spinner, Dim shift, Light follows the story; §4.11; §5.2 reader events (`reader.enter`, `chapter.arm`, `chapter.next`, `chapter.seam`, `scrub.tick`, `scrub.boundary`, `zoom.snap`, `zoom.limit`, `page.turn`, `ocr.hit`, `reader.unlock`, `bookmark.add`, `autoscroll.toggle`, `download.start`, `download.done`, `download.fail`) and "Never haptic" (chrome show and hide, scrolling).
   - §8.0.3 (rows `reader`, `readAll`, `readerLanding`; sheet ids `chapters`, `settings`, `note`), §8.0.4 (Dive, Reader → back), §8.0.5, §8.0.6 (the `g` chords are off inside readers), §8.0.8 (18+, unavailable content, mobile web gesture hygiene: the strip keeps `touch-action: pan-y`), §8.0.10.
   - §11 every reader row; §13 (the reader's signature moments); §14.1–§14.10 (§14.5: chrome never hides while a screen reader is on; page images take the OCR text as their description); §15.4; §15.7 (the "Manga reader" row: at most 6 live web elements).
4. `docs/redesign/cinematic/DESIGN.md`, for the behaviour both skins share (never for its look): §15.4 (the base engine fields and duties: page tint, panels, completion events, the next-chapter auto-queue) and §8.14.11 ("Saving the next chapter", the engine duty Glass §8.14.4 reuses).
5. `docs/redesign/inventory/web.md` §9 (RD1–RD42, the escape order, local position memory), §18.6 (A65–A73), §18.8 (A89), §19 (K31–K39, the reader keys you read).
6. `docs/redesign/prompts-plan.json`: the `web/00` entry (TRACK RULE) and this file's entry.
7. Reports: `docs/redesign/proof/web-12/report.md` and `web-13/report.md` (engine API: `pinchZoom`, `zoomAt`, `setLayout`, `dragTurn`, `releaseTurn`, `furtherElsewhere`, read-all boundaries, the render slots, `reader-prefs.ts`), `web-23/report.md` (`pageToViewport`, the page-tint worker), `web-34/report.md` (the Glass engine API you call: `currentPageSample`, `engine.live`, `onSeam`, `onNeighbour`, `armNeighbour`, `commitNeighbour`, `continueFling`, `swipeNeighbour`, `releaseSwipeNeighbour`, `pageLayerTransform`, `autoScroll.start(pxPerSecond)`), `web-27/report.md` (`ScrubRail`, `Sheet`, `FillSlider`, `Stepper`), `web-28/report.md` (download control, depth glyph, lens states), `web-29/report.md` (back menu, Dive, `html[data-reader]`), `web-33/report.md`.
8. Code: `frontend/src/features/reader/` (engine, `zoom.ts`, `page-turn.ts`, `read-all.ts`, `reader-prefs.ts`, `wheel-zoom-arming.ts`, `keymap.ts`, `scroll-storage.ts`, `hooks.ts`), `frontend/src/features/ocr/{hooks,boxes}.ts`, `frontend/src/features/bookmarks/{hooks,note}.ts`, `frontend/src/features/offline/{use-chapter-download,download-mark}.ts`, `frontend/src/features/novels/toc-window.ts` (from `web/33`), `frontend/src/lib/keyboard/`, `frontend/src/skins/glass/` (`Shell.tsx`, `motion.ts`, `glass/{GlassSurface,liquid-map,budget,useLb}.ts|tsx`, `primitives/*`, `haptics.ts`, `screens/series/`), `frontend/scripts/proof.mjs`. The Cinematic reader in `frontend/src/skins/cinematic/screens/reader/` is for reference only (never import it).

## Preconditions (stop and report if any fails)

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs
git branch --show-current                                         # feat/vps-slim-source-native
test -f docs/redesign/proof/web-34/report.md && echo web-34 done
grep -rn "currentPageSample\|pageLayerTransform\|commitNeighbour" frontend/src/features/reader/engine/types.ts | head -5
grep -n "feature" frontend/src/skins/glass/index.ts | head -3     # feature is no longer PENDING (web/33)
grep -n "^S1 \|^S11 \|^G6 \|^G14 " docs/redesign/signoffs.md
node design/build.mjs --check
cd frontend && free -m && npm run test 2>&1 | tail -5             # record the vitest file and case counts: your floor
```

## Skills to invoke

1. `superpowers:writing-plans` before any code. Save the plan at `docs/redesign/proof/web-35/plan.md`.
2. `superpowers:test-driven-development` for every pure helper (section A and the `*.ts` helpers in the file layout): vitest first.
3. `superpowers:subagent-driven-development` to run the plan (or `superpowers:executing-plans` inline). At most 6 implementer subagents (frame, light layers and tint; chrome, rail, popover and modes; strip, seams, boundaries and paged; gestures and keys; settings sheet, chapter list and side panels; dialogue overlay, hit lens, landing and states). Start every subagent prompt with a scope lock, pass `model: "opus"` explicitly, run builds, tests and browsers one at a time, and verify each subagent's work against `git status` and `git diff`, never against its report alone.
4. `frontend-design:frontend-design`, `impeccable:impeccable` and `taste-skill:taste-skill` for the chrome, the tint, the lens and the panels (the art is the hero; glass only floats over it; one lit object at a time).
5. `superpowers:verification-before-completion` before you claim anything is done.

## Scope: deliver every item below

Sizes are CSS px. Every named move goes through `play()`; every glass surface is a `GlassSurface` counted by the budget; nothing inside the strip is glass (seams, seam cards, broken-page lenses and the dialogue boxes are content twins). `html[data-reader]` is set while the reader is mounted. `document.title` is `{series} · Ch {n} · ManhwaManiacs`; route focus goes to a visually hidden `h1` ("Solo Leveling, chapter 143") with `preventScroll: true`. Web "hit 44" means the element's own box is at least 44 × 44 at 390 × 844.

### A. Reader values and migration (skin-neutral; `frontend/src/features/reader/glass-reader-values.ts` + test)

Read-time values with the §8.25.3 migration: the new key when present, otherwise derived from the stored legacy key; writes go only to the new keys; old keys are never rewritten; unknown fields (Cinematic's) survive every Glass write. Scopes follow §8.14.5.

| Value | Where (scoped storage) | Glass values | When the new key is absent |
|---|---|---|---|
| layout, direction, fit, zoom | per series `mm.reader-preferences[{source}:{series}]`, the shared `layout`, `direction`, `fitMode`, `zoom` | `STRIP` · `SINGLE` · `DOUBLE`; `ltr` · `rtl`; `width` · `height` · `original`; 0.5–3.0 | as stored (a stored `GUIDED` reads as `STRIP` until `web/44`) |
| `cruiseSpeed` | per series, new key | 0.25–4 multiplier of 60 px/s | legacy `autoScrollSpeed` level `v`: `(20 + (v − 1) × 22.2) / 60` rounded to 0.05 (1 → 0.35, 5 → 1.80, 10 → 3.65); nothing stored → 1.0 |
| `glass.brightness` | per profile `mm.reader-settings`, nested object `glass` | 0.2–1.0 | legacy `dimmer` 0–0.92: `1 − dimmer / 0.92 × 0.8` (0 → 1.0, 0.46 → 0.6, 0.92 → 0.2); nothing → 1.0 |
| `glass.warmth` | same | 0–1 | legacy `warmth` 0–0.7: `warmth / 0.7`; nothing → 0 |
| `glass.pageTransition` | same | `SLIDE` · `FADE` · `NONE` | legacy `pageTransition` true → `FADE`, false → `NONE`; nothing → `NONE` |
| `glass.background` | same | `BLACK` · `GRAPHITE` | `BLACK` |
| `glass.chapters` | same | `CONTINUOUS` · `SINGLE` | `CONTINUOUS` |
| `glass.tapToScroll`, `glass.swipeChapter`, `glass.lockControls`, `glass.hideCinemaProgress` | same | booleans | `false` |
| `glass.pageTinted` | same | boolean | `true` |
| `colour`, `pageGap`, `cinema`, `tapZones`, `autoNextChapter` | same, shared fields (same meaning in both skins) | `NORMAL` · `SEPIA` · `GREY`; boolean; boolean; the three bands; boolean | as stored; `autoNextChapter` default `true` |

Test every formula at both ends and one middle value, unknown-field preservation through a Glass write, and per-profile isolation through `scoped-storage.ts`. `web/39` builds Settings → Reader defaults on this module and adds the remaining migration rows; do not build that page here.

If `features/reader/zoom.ts` has no cap on the displayed rubber band, add the option `rubberBandMax` (the displayed overshoot never exceeds it; Glass passes 0.18 scale, §4.5) with a test; Cinematic's calls stay unchanged.

### B. Screens and frame (§8.14.1)

1. `ReaderScreen` (`reader`, `/reader/:sourceId/:seriesKey/:chapterKey?page&at&all&q`) and `ReadAllScreen` (`readAll`, `/read-all/:sourceId/:seriesKey?from&page&at`) render `MangaReader` with `useReaderEngine({ kind, … }, { autoQueueNext: true, chapterMode, coverPalette, overscrollReturn: { type: "spring", stiffness: 322.3, damping: 35.9 } })`; `ReaderLandingScreen` is §L.
2. **Canvas:** `#000000`, or Graphite `#0B0B0F` from `glass.background`. **Light layers** (pointer-transparent, above the pages, below the chrome): a black overlay at alpha `(1 − brightness) × 0.9` (0.72 at 20 %) and a `readerWarmth` `#FF8A00` layer at `warmth × 0.36` alpha with `mix-blend-mode: multiply`. **Colour** Normal · Sepia · Grey through the engine's `pageFilter` prop (page layer only).
3. **Strip:** full width on phones at 1×; `clamp(480px, 50vw, 900px)` centred on desktop; page gap 0 or 8 px (`pageGap`); page boxes sized from the manifest before images load with a `#0B0B0F` placeholder and no spinner (the engine's `pagePlaceholder` slot). Page images carry the OCR text of the page as their accessible description when it exists, otherwise "Page 18 of 40".
4. **Entry:** the Dive from a chapter row, Continue, a history orb, a bookmark or a dialogue result lands here (`reader.enter`); the first page fades in over the last 40 % of the Dive.

### C. Chrome (§8.14.2, through `renderChrome`)

1. **Material:** every chrome surface is `glassRegular` (T3) with `dimLegibility` and the page tint of §D, over `ScrollEdge` soft edges that fade in and out with the chrome. The two top groups are **one** masked backdrop element (both shapes in one `liquidMap`), so they count once.
2. **Top-left group:** back (44) showing the depth indicator (`strata` glyph, 1–4 lit bars; accessible name "Back to {previous title}, {n} levels deep"; long-press 500 ms on touch, right-click or `mod+\` opens the `web/29` back menu; `aria-keyshortcuts="Control+Backslash"`, `Meta+Backslash` on macOS) + the title capsule "Solo Leveling · Ch 143" (click → the series sheet route; long-press or `t` on phones → the chapter list). Read-all adds `mono` "143 of 412".
3. **Top-right group:** the compact download control (§7.29 through `use-chapter-download.ts`: Download → "18/40 · 45 %" with a cancel × → Saved check → a click shows "Remove download?" inline, reverting after 4 s; warn states "Save again" and "Resume 18/40"; every coloured glyph on the backing disc), bookmark (toggle; saved = Fill `iris400` on the backing disc; `b`), settings (`sliders` glyph; `,`).
4. **Bottom capsule** (56 tall, max 520 wide, centred on the strip column, bottom `calc(env(safe-area-inset-bottom, 0px) + 16px)`): previous chapter (disabled at 30 % when none), the page readout `mono` "18 / 40" as a button ("Page 18 of 40, go to page"), the cruise button (`flywheel` glyph; §C9), next chapter (tooltip with the next chapter's label); a 2 px progress hairline inside its bottom edge (`iris500` at 80 %, following on `track`).
5. **Go to page popover** (anchored picker, no URL state; `g` opens it): the readout blooms (`morph`, k 273.4, c 24.80) a `glassThick` popover above the capsule, 280 wide: a number well (96 wide, `mono` 15, `inputmode="numeric"`, the current page as placeholder, "/ 40" after it; Enter jumps, Esc closes), a page slider 1 to N with `detent.tick` per page and the target page's thumbnail (image proxy at `w=240`) in a 64 × 96 box beside the value while dragging, and "Go" (the tinted twin). Jumps of up to 5 pages glide on `page` (`jumpToPage(n, { glide: true })`); longer jumps cut with a 120 ms cross-fade.
6. **Scrub rail** (`web/27` `ScrubRail`, trailing edge between the two groups, 44 px hit strip): the 3 px `rgba(255,255,255,0.50)` track with a 1 px `rgba(0,0,0,0.60)` outline, the `iris500` fill, a 12 px `#FFFFFF` thumb with a 1.5 px `#000000` ring; on touch the track widens to 6 px and the `glassThick` magnifier lens (120 × 164, radius 20) grows out of the thumb on `lens` (k 223.8, c 20.94) and follows on `track` (k 1754.6, c 72.05), showing the page thumbnail at `w=240` and `monoLarge` "18"; `scrub.tick` per page, `scrub.boundary` at the first and last page and at chapter boundaries in read-all (the rail segmented by chapter with 2 px gaps from the engine's read-all boundaries); bookmarks as 4 px droplets; release glides up to 5 pages, cuts beyond; `role="slider"` with `aria-valuetext="Page 18 of 40"`; no rail when `pageCount == 1`; on desktop hovering the rail shows the magnifier at the pointer.
7. **Auto-hide and minimise** (the engine's thresholds): 24 px of cumulative downward scroll dematerialises the top groups (lensing out, blur 8, scale 0.92) and morphs the bottom capsule on `minimize` (k 246.7, c 31.42) into a 32 px pill showing only "18 / 40"; 56 px of upward scroll, a centre tap, the chapter end or pointer movement into the top or bottom 72 px (desktop) restores them. Idle hide after 3,000 ms only when a tap opened the chrome. Never hide in the first 800 ms after a chapter opens, while a sheet, menu, popover or scrub is active, while a screen reader is on (`html[data-sr="on"]`), or within 30 s of a `keydown` or Tab. Hidden chrome is `inert`; a key that is not a reader binding, a Tab, or pointer movement into the chrome's region restores it first and puts focus on its first control. Chrome show and hide never fire a haptic.
8. **Cinema mode** (`c`, or the settings sheet): the pill hides too after 3 s idle; a 2 px micro-progress line stays at the very bottom edge unless "Hide progress" (`glass.hideCinemaProgress`) is on.
9. **Cruise button:** toggles cruise through `autoScroll.start(cruiseSpeed × 60)` / stop, `p` toggles, `<` / `>` step 0.25× within 0.25–4 (written to `cruiseSpeed`), `autoscroll.toggle`; a tap or a manual scroll pauses it; it never starts on its own under reduced motion. The flywheel pill, its drag, the HUD, the 400 ms ramp and flick-to-cruise are `web/44`.
10. **Locked mode** (`glass.lockControls`): taps only scroll; five taps in the centre region within 2 s unlock (a small lock glyph pulses at each tap; toast "Reader unlocked"; `reader.unlock`); a visually hidden "Unlock controls" button that appears on focus, and `u`, unlock at once.
11. **Nothing beneath:** when the reader has no parent level in the Glass stack recorder (`sessionStorage['mm.glass.stack']` holds no earlier level for this tab: a hard load, a deep link, the skin-switch return route), back goes to `feature` `/sources/:sourceId/series/:seriesKey` as a full page with a 200 ms cross-fade.
12. **Tap light:** a 120 px radial light at 10 % white blooms at the tap point and fades over 300 ms (opacity only, also under reduced motion).
13. **Zoom chip:** a `glassThin` capsule top-centre showing "200 %" for 1,200 ms after a pinch or a Ctrl/⌘ + wheel zoom.

### D. Page-tinted chrome and the legibility dim (§9.4.4, §2.1.7; `screens/reader/page-tint.ts` + test)

1. **Source:** `engine.state.currentPageSample` (manifest tint first, then the decoded sample; the engine already holds updates above 3,000 px/s and applies the greyscale rules).
2. **Tint:** the sample's `tint` clamped in OKLCH to L 0.35–0.50 and C ≤ 0.12; applied as a tint layer inside every reader glass surface at 18 %, to the rims at 22 % (the rim tint at L 0.86, C ≤ 0.08), to the soft edges at 30 %, to the minimised pill's inner glow at 30 %, and to the micro-progress line. Changes cross-fade over `tintShift` (900 ms `cubic-bezier(0.2, 0, 0, 1)`) through registered custom properties (`@property --reader-tint { syntax: "<color>"; inherits: true; initial-value: #000000 }` and `--reader-rim-tint`) and apply only when the new tint differs from the current by ΔE (OKLab) > 0.04. Pure helpers: `clampTint(hex)`, `rimTint(hex)`, `deltaE(a, b)`; tests for a saturated red, a near-grey and the 0.04 gate.
3. **Legibility:** `Lb` per surface: the top groups use `pTop`; the bottom capsule, the pill and the micro-progress use `pBottom`; every other reader surface (popover, page menu, next-chapter card, seam chip, zoom chip, loading capsule, match capsule, the settings sheet) uses the maximum of `pTop`, `pMid` and `pBottom` over the viewport bands its rect overlaps (top quarter, middle half, bottom quarter). Pass `Lb` to `GlassSurface`, which sets `dim = clamp(0.22 + 0.42 × Lb, 0.22, 0.64)` and the label `GRAD` over `dimShift` (400 ms); with no sample yet `Lb = 1.0` (dim 0.64). Test the band selection.
4. **Switch** (Ambient → Page-tinted chrome, default on). Off: neutral glass; the dim still adapts. Reduce Transparency: the tint stays on the solid chrome's rim only.
5. **Desktop:** the side panels' rims take the same tint; the page-lit gutters are §J2.

### E. Strip, seams, boundaries and paged (§8.14.1, §8.14.4)

1. **Continuous (default):** the engine stitches neighbours with seams. The seam (96 px, the `chapterDivider` slot, a content twin): a hairline, "CHAPTER 144" `caption1` +0.2 em with the letter reveal when the seam enters (`seamProgress` turns non-null), the chapter title `footnote` `label2`, a hairline. On `onSeam({ kind: "top" })` a `glassThin` chip "Chapter 144" sticks under the top group for 1,200 ms (Seam chip: `materialize`, hold, `dematerialize`); on `onSeam({ kind: "reading-line" })` fire `chapter.seam`.
2. **Missing chapters:** when chapter numbers jump (143 → 145), the seam shows a `warning` row "Chapter 144 is missing from this source".
3. **Neighbour still loading:** the tail seam shows a 16 px liquid ring spinner and "Chapter 144 is on its way" (`footnote` `label2`); the head seam the same for the previous chapter. **Failed neighbour:** the seam card "Chapter 144 didn't load" + "Try again" + "Open it on its own", retrying with back-off 2, 4, 8, 16, 30 s (cap 30 s).
4. **Read-all:** the strip streams the whole series in order (chapter 1 or `?from=` first); seams are slim (48 px) with no card and no pause.
5. **One at a time** (`glass.chapters = SINGLE`, engine `chapterMode: "single"`): past the last page the strip rubber-bands (the engine's `overscrollExtent`); on `onNeighbour({ phase: "armed" })` (48 displayed px) call `armNeighbour("next")` and raise the `glassThick` **next-chapter card** from the bottom like a partial sheet, its position driven every frame by `engine.live` `overscrollExtent`: the next chapter's first page as a thumbnail tilted 8° in depth (`perspective: 900px; rotateX(8deg)`, following the pointer ±4° on desktop), "Chapter 144", "42 pages · about 6 min", and a tinted "Read next" twin; `chapter.arm`. At 72 px (`"locked"`) the card locks with `chapter.next`; releasing zooms the card to full screen on `zoom` (k 125.9, c 21.09) carrying the release velocity, then `commitNeighbour({ direction: "next", velocity })` and `continueFling(velocity)`. Pulling down past the first page does the same with the previous chapter's card from the top. A `"locked"` event with `via: "wheel"` (210 px of wheel past the end) commits at once with `velocity: 0`. "Read next" and `l` commit without a pull. Reduced motion: the card appears at the lock and the switch is a 200 ms cross-fade with no carried momentum.
6. **Auto next** (`autoNextChapter`, default on): in one-at-a-time mode, reaching the end with the chrome hidden commits the next chapter after 900 ms unless the reader scrolls back.
7. **Caught up** (the last published chapter): the end card "You're caught up" / "The source hasn't published chapter 145 yet." and, when the series is not in the library, "Add to library to hear about new chapters" with an "Add to library" button (`POST /library/follow`, `follow.add`).
8. **Sideways chapter swipe** (opt-in `glass.swipeChapter`, strip only): `lockAxis` decides; while locked on x, `swipeNeighbour(dx)` drives a content-twin title card of the neighbour chapter sliding in from the side by `displayed`; release calls `releaseSwipeNeighbour(vx)`; a commit fires `chapter.next`.
9. **Paged** (`SINGLE` or `DOUBLE`; when a series with no stored layout is switched to paged at 768 px or wider, Double is selected; below 768 px, Single): fit width, height or original; right-to-left mirrors spreads; 8 px spread gap; page turns per `glass.pageTransition`: **Slide** (finger-tracked through the engine's `dragTurn` / `releaseTurn`, projection decides, settling on `page` k 146.0, c 24.17, the incoming page sliding over with an 8 px soft shadow `0 0 8px rgba(0,0,0,0.5)` on its moving edge), **Fade** (160 ms), **None**; `page.turn` on every committed turn. Tap bands 30 / 40 / 30: left previous, centre chrome, right next, mirrored for right-to-left until the reader sets their own (`tapZones`). The wheel turns one page per gesture with a 200 ms idle reset.
10. **Broken page** (the `brokenPage` slot, inside the page box): a 72 px lens drawn as a content twin with the `image-broken` glyph, "This page didn't load", and a "Retry" button in the same content style that remounts only that image.

### F. Gestures and input (§8.14.3, §11; `screens/reader/reader-gestures.ts` + test, `middle-autoscroll.ts` + test)

1. **Vertical scroll:** native momentum, never scroll-jacked; the strip keeps `touch-action: pan-y`.
2. **Tap (strip):** toggles the chrome anywhere (default). With "Tap to scroll": the top third and the left-middle scroll back 75 % of the viewport, the bottom third and the right-middle forward, the centre toggles; the scroll glides on `settle`. **Tap (paged):** the 30 / 40 / 30 bands.
3. **Double tap** (a second tap within 280 ms and 24 px; single taps are never delayed): `zoomAt(point, 2 or 1, { type: "spring", stiffness: 195.0, damping: 25.13 })` (`camera`) anchored at the tap point, `zoom.snap`. In paged mode and with Tap to scroll on, a double tap is recognised only in the centre band and a side-band tap acts at once without a double-tap window. In the centre band the chrome toggle made by the first tap is reverted instantly (no fade) before the zoom runs, so a double tap never changes chrome visibility. Tests: the 280 ms and 24 px limits, the band rules, the revert.
4. **Pinch** (`@use-gesture/react` 10.3.1 `usePinch` on the strip): `pinchZoom(focal, scale, velocity, { min: 1, max: 3, snapStep: null, rubberBand: true, rubberBandMax: 0.18 })` in the strip and `max: 4` in paged; release springs with the scale velocity; `zoom.limit` when the pinch reaches 1× or the maximum. Zoomed: horizontal pan enabled.
5. **Long-press a page** (450 ms on touch; right-click on desktop; `shift+F10` while the strip has focus opens it for the page on the reading line): the page menu (`Menu` blooming at the point): Save page image (downloads the page through the image proxy), Bookmark this spot, Show dialogue (§I), Report broken page (remounts the image with a fresh fetch). Guided view, React to this chapter and Recommend to… join later (see Out of scope).
6. **Mouse wheel:** scrolls; Ctrl/⌘ + wheel zooms around the pointer (keep `wheel-zoom-arming.ts`; the zoom chip shows); in one-at-a-time mode the engine turns wheel delta past an end into the arm (140 px) and commit (210 px) phases.
7. **Middle-click** (desktop): an autoscroll anchor at the press point (a 24 px content-twin circle with up and down carets): speed `sign(dy) × min(max(|dy| − 12, 0) × 10, 4000)` px/s through `autoScroll.start` / `setSpeed` (signed); any click, key or Esc stops it; while it is active the reader sets `data-cursor="all-scroll"`. Test the 12 px dead zone, 10 px/s per px and the 4,000 px/s cap.
8. **Installed iOS PWA back swipe:** the `web/29` leading-edge handler applies in the reader only from the leading 20 px and only in the strip at 1× (the Surface move: the reader slides right over the recessed series page).
9. **Cursors** (§7.40, the `web/26` item T contract): over the strip the pointer hides (`data-cursor="none"`) after 3,000 ms without pointer movement while the chrome is hidden, and returns on the next move; the scrub rail keeps `ns-resize` from `web/27`; every chrome control shows `pointer`.

### G. Reader settings sheet (§8.14.5)

Phones: `?sheet=settings` at `medium` (the page stays visible above, changes apply live), draggable to `large`; T4 glass, so body text is `onGlass` and wells, tracks and steppers use `wellOnGlass`. Tablets: the same sheet. Desktop: inline in the right panel's Settings tab (§J). Every row shows its scope in `caption1` `onGlass`: "This series" or "All series" (§A).

| Section | Controls |
|---|---|
| Layout | Segmented Strip · Single · Double (hidden in read-all); Direction Left to right · Right to left; Fit Width · Height · Original (Height and Original disabled in the strip with the reason "Strip pages always fit the width"); Zoom `Stepper` 50–300 % in 10 % steps with a reset; Chapters Continuous · One at a time; Page gap switch (strip) |
| Motion | Page transition Slide · Fade · None (paged); Auto next switch; Swipe sideways to change chapter switch |
| Taps | A phone-silhouette diagram with three bands; tapping a band cycles Previous · Menu · Next; "Tap to scroll" switch (strip); "Reset to automatic" plain button; the first-run overlay of three glass panes labelled Back · Menu · Next shows for 1.5 s and fades over 1,000 ms whenever the layout changes |
| Light | Brightness and Warmth as two `FillSlider`s side by side (72 × 160, `fill2` twins; brightness 20–100 %, warmth 0–100 %); Colour Normal · Sepia · Grey; Background Black · Graphite |
| Ambient | Page-tinted chrome switch; Cruise speed (a `Slider` 0.25×–4× in 0.05 steps with a magnet at 1.0×, value in `mono` "1.25×", "This series") |
| Screen | Cinema mode switch, with "Hide progress" under it while cinema is on; Lock reader controls switch; Fullscreen button (Fullscreen API when supported, else hidden) |
| Help | Keyboard shortcuts (opens `?sheet=shortcuts`); Reset reader settings (`HoldToConfirm`; toast "Reader settings reset") |

Keep screen awake, Refresh rate and Volume keys are phone-app rows and are absent on the web.

### H. In-reader chapter list (§8.14.8)

Phones `?sheet=chapters` at `large`; tablets the same sheet; desktop the left panel (§J). The current chapter centred and marked by a 2 px `iris500` bar; download marks; a go-to field at the top (`/`); the Newest/Oldest control; tapping a chapter switches chapters in place (the route stays the reader: `router.replace`, the pages cross-fade); in read-all, tapping a row scrolls the strip to that chapter's seam on `camera`. Long lists: the `toc-window.ts` window of 400 rows around the current chapter with "Show earlier chapters (212)" and "Show more chapters (400)", and `FastScroll` with a chapter-number bubble above 200 rows. States: loading (8 row skeletons under the live header), error ("Couldn't load the chapter list" + Try again), unavailable ("Chapters didn't come through" + Try again), offline (downloaded chapters at full strength, every other row at 40 % with "Needs a connection" and not activatable; the header "Offline · 24 downloaded"), rate limited (the `warning` capsule with its countdown).

### I. Dialogue overlay and the hit lens (§8.14.9)

1. **Overlay** (`o`, or the page menu): the page dims to 50 % and every recognised speech region (`GET /ocr/chapter` boxes through `useOcrChapter`) appears as a box (radius 6) holding its text in `callout` `label1`, drawn in **one** absolutely positioned layer over the reader viewport, positioned with the engine's `pageToViewport(page, x, y)` and re-laid out on every scroll frame; each box is a content twin on `twinDense` `rgba(19,19,23,0.82)` with a 0.5 px `rgba(255,255,255,0.22)` rim and no backdrop read. Clicking or tapping a box copies its text (toast "Copied"). Pages without OCR show "No dialogue has been extracted for this chapter" (the web has no Extract text).
2. **Hit lens:** when the reader was opened with `?q=` (from dialogue search), fetch the chapter's OCR pages, open at the first page whose text contains the query (case-insensitive), outline every matched box on that page 2 px `iris400`, and place a **T1 hit lens** (`glassFilm`, radius 6, a 2 px specular rim; the one glass surface of the overlay layer) over the current match, magnifying the matched line 1.12 × through `pageLayerTransform({ scale: 1.12, originX, originY }, clipRect)`. A `glassRegular` capsule at the bottom reads "Match 1 of 3" with previous and next buttons (each change announced through a polite `role="status"` region); `n` / `shift+n`, the buttons or a horizontal swipe on the capsule step between matches; each step slides the lens on `camera` (k 195.0, c 25.13), gliding the strip on `camera` when the next match is off screen, and re-magnifies 1.0 → 1.12 on `lens`; `ocr.hit`. No match: open at page 1 with the toast "Opened at the chapter start: the match moved." Esc or the capsule's × removes the lens and the outlines. Reduced motion: the lens appears at the new bubble with a 120 ms fade and magnifies without growth.

### J. Platform deltas (§8.14.11, web)

1. **Desktop (≥ 1024 px):** the strip at `clamp(480px, 50vw, 900px)`; two side panels, content-layer `materialThick` (`rgba(19,19,23,0.84)`, blur 36), radius 26, inset 12, never Liquid Glass, their rims taking the page tint:
   - **Left, 300 wide** (`t`): the chapter list with a 48 × 72 first-page thumbnail per row (image proxy `w=96`), the number in `mono`, title, date, the download control, the current chapter marked and centred; "Read all" and Newest/Oldest at the top; the go-to field (`/`).
   - **Right, 360 wide**: tabs **Settings · Dialogue** (`,` and `shift+o` open them; `o` toggles the overlay and, while this panel is open, switches it to Dialogue): the settings of §G inline (changes apply live) and the overlay's text list for the current page. The Circle tab joins in `web/43`.
   - Opening or closing a panel re-centres the strip: its centre travels to the middle of the remaining width on `sheet` (k 171.3, c 24.09) while the panel slides in from its edge on `sheet`; panels push the strip, never cover it; both hide with the chrome in cinema mode and return with it.
   - **Fit** (`panel-fit.ts` + test): with panels open the strip is `min(clamp(480px, 50vw, 900px), viewport − Σ(open panel width + 24) − 24)`; if that would fall below 480 px, opening a second panel closes the first on the same spring with the `caption1` toast "One panel at a time at this window size" (both fit from 1,212 px).
   - **Semantics and focus:** non-modal `<aside role="complementary">` landmarks labelled "Chapters" and "Reader settings"; opening by key moves focus to the current row or first control, opening by pointer leaves it; `F6` / `shift+F6` cycle strip → left panel → right panel; Esc inside a panel closes it and returns focus to the strip.
2. **Page-lit gutters** (desktop, both panels closed): the gutters beside the strip are `g25` `#060608` wells in which the sample's `top` colour glows in the top half and its `bottom` colour in the bottom half of each gutter, at 10 % opacity, blurred 120 px (radial gradients, no live filter), cross-fading over `tintShift` as pages change, never touching the art. Page-tinted chrome off or Reduce Transparency: plain `#000000`.
3. The bottom capsule floats at the bottom of the strip column.
4. **Tablet web (768–1023 px):** Double page by default in paged mode (the §E9 rule); the panels open as sheets (the chapter list at `large`, settings at `medium`) from the title capsule and the settings button.
5. **Mobile web:** as phones; pinch through `usePinch`; no haptics on iOS Safari (`haptics.ts` maps only the seven `navigator.vibrate` events on Android Chrome).
6. **Landscape phone** (a coarse-pointer viewport under 500 px tall): top-left back + title capsule (the title at most 40 % of the width); top-right the page capsule (`mono` "18 / 40", the go-to button) + a glass group of bookmark, settings and ⋯ (Download with the §7.29 states, Cruise, Previous chapter, Next chapter); the scrub rail runs along the bottom edge (44 px hit strip, 3 px track, 12 px thumb, the 120 × 164 magnifier above the thumb; segmented in read-all); edges at `max(env(safe-area-inset-left), 16px)` and `max(env(safe-area-inset-right), 16px)`; sheets `min(560px, 100vw − 16px)` wide, centred, at the viewport height − safe-top − 10.

### K. States (§8.14.6)

- **Loading chapter:** three page-shaped skeletons (2:3, max 420 wide) with the sheen and a `glassThin` capsule "Loading chapter 143"; after 3 s it adds "This source can be slow".
- **Error:** the object lens (`danger` `warning-circle`) "Couldn't open this chapter" + the server message + "Try again" + "Go to series".
- **No pages:** lens "This chapter has no pages" + "Go to series".
- **Offline:** a downloaded chapter opens from the device with an "Offline" capsule in the top group; neighbours that are not downloaded show "Chapter 144 needs a connection" as the end card, with "Download next 10 when online" as a plain action that queues them.
- **Stale anchor:** toast "This chapter changed. Opened at page 17 instead of 19."
- **Rate limited:** a `warning` capsule "The source is rate-limiting; pages will keep loading" while prefetch paces itself.
- **Bookmark notices:** toast "Saved this spot · Add note" (`bookmark.add`; "Add note" opens `?sheet=note`, a one-line note sheet saving through the bookmark upsert in `features/bookmarks/note.ts`), "Couldn't save that spot" (error).
- **Further ahead elsewhere:** when a save returns `advanced: false` (the engine's `furtherElsewhere`), the toast "You're further ahead on another device: Ch 146, p. 12" with "Jump there".
- **Gate closed on a mature series:** the lens "This isn't available on this profile" + "Back home", no title or cover. **Unavailable content:** the §8.0.8 lens and its lines.

### L. Reader landing (`/reader`, §8.14.10)

A bare page: the object lens with `strip-scroll`, "Pick something to read", "Open a series from your library or a source to start reading.", primary "Go to library".

### M. Keys (§8.14.7, web) and the escape order (`screens/reader/reader-keys.ts` + test)

`→`/`d` and `←`/`a` page by direction · `j`/`k` next/previous page · Space / Shift+Space one screen · Home/End first/last page · `h`/`l` previous/next chapter · Ctrl+Shift+←/→ chapter aliases · `g` go to page (the global `g` chords are off inside the reader) · `u` unlock · `f` fullscreen · `c` cinema · `m` show/hide chrome · `p` cruise play/pause · `<` / `>` cruise slower/faster · `b` bookmark · `t` chapter list · `,` reader settings · `s` series page · `=`/`+`/`-`/`0` zoom · `w` strip, `v` single, `r` right-to-left paged · `o` dialogue overlay (and the Dialogue tab when the right panel is open) · `shift+o` right panel on its Dialogue tab (desktop) · `?` shortcuts · `n` / `shift+n` next/previous match · `mod+\` back menu. Esc order: menu or popover → dialogue overlay and hit lens → side panel (desktop) → fullscreen → cinema → leave the reader. The Single-key switch off skips every printable binding. Test the escape reducer and the binding table.

### N. Checks

- Vitest: `glass-reader-values.test.ts`, the `zoom.ts` addition, `page-tint.test.ts`, `reader-gestures.test.ts`, `middle-autoscroll.test.ts`, `panel-fit.test.ts`, `reader-keys.test.ts`.
- `frontend/e2e/glass/web-35-reader.spec.ts` (Playwright against `next dev`, the Glass skin; the `web/34` long-strip fixture and route fixtures under `frontend/e2e/fixtures/reader/`): both entry points (the followed series page and the source series page) open the reader; scrolling down 24 px hides the chrome and 56 px up restores it; hidden chrome is `inert` and Tab restores it with focus on its first control; the minimised pill reads "18 / 40"; `g` opens the go-to popover, Enter jumps, Esc closes; the rail answers arrows with `aria-valuetext`; `b` saves a bookmark (network log); `,` opens `?sheet=settings` and browser back closes it; switching Layout to Single turns pages with `→`; Chapters → One at a time plus ten 21 px wheel events past the end commits the next chapter; `o` shows the dialogue boxes from a `GET /ocr/chapter` fixture and Esc removes them; `?q=` opens at the matching page with the lens and "Match 1 of 3", `n` moves to match 2; at 1440 × 900 `t` and `,` open both panels and the strip re-centres, and at 1,100 px wide opening the second closes the first with the toast; `F6` cycles focus; the Esc order holds step by step; a mocked `advanced: false` save shows the further-ahead toast; `/reader` shows the landing; every interactive element at 390 × 844 is at least 44 × 44; the live glass count in the "scrubbing with the hit lens and a pill" case is at most 6.

## Out of scope here (owned by later steps; do not build)

- `web/36`: the novel reader. `web/41`: the "Previously · 20 s" pill and the More like this rail on the caught-up card. `web/43`: the Circle tab, reactions on the caught-up card, React to this chapter and Recommend to… in the page menu, `shift+c`. `web/44`: the cruise flywheel pill, its drag, HUD, 400 ms ramp, flick to cruise and the right-edge speed swipe; the soundscape row, `shift+s` and Rain on glass; guided view, its page-menu item, the `panel-focus` button and `shift+p`.
- Phone-app-only rows (Flutter, `mobile/35`): the left-edge brightness band, Keep screen awake, Refresh rate, Volume keys, `immersiveSticky` system UI, the iOS 20 px edge swipe outside the PWA, Android predictive back.

## File layout

Follow the naming the earlier Glass screens used (`ls frontend/src/skins/glass/screens/`); if it differs from below, follow it and list the mapping in the report.

```
frontend/src/features/reader/glass-reader-values.ts (+ .test.ts)          A
frontend/src/features/reader/zoom.ts (+ test)                              A (rubberBandMax, only if missing)
frontend/src/skins/glass/screens/reader/
  ReaderScreen.tsx  ReadAllScreen.tsx  ReaderLandingScreen.tsx  MangaReader.tsx
  ReaderChrome.tsx  TopGroups.tsx  BottomCapsule.tsx  GoToPagePopover.tsx  ReaderScrubRail.tsx
  LightLayers.tsx  TapLight.tsx  ZoomChip.tsx  LockedMode.tsx  MiddleAutoscroll.tsx
  ChapterSeam.tsx  SeamChip.tsx  NeighbourCard.tsx  SwipeNeighbourCard.tsx  EndCards.tsx  BrokenPage.tsx
  PagedStage.tsx  PageMenu.tsx  ReaderSettings.tsx  TapZonesDiagram.tsx
  ChapterList.tsx  SidePanels.tsx  PageLitGutters.tsx  DialogueOverlay.tsx  HitLens.tsx  MatchCapsule.tsx
  ReaderStates.tsx
  page-tint.ts (+ test)  reader-gestures.ts (+ test)  middle-autoscroll.ts (+ test)  panel-fit.ts (+ test)  reader-keys.ts (+ test)
frontend/src/skins/glass/index.ts          remove reader, readAll and readerLanding from PENDING
frontend/e2e/glass/web-35-reader.spec.ts
docs/redesign/proof/web-35/                plan.md, routes.txt, screenshots, report.md
```

The route files under `frontend/src/app/(app)/reader/` and `read-all/` stay thin. No CSS modules; the registered properties live in `skins/glass/glass.css`.

## Acceptance criteria

- [ ] `reader`, `readAll` and `readerLanding` render in Glass and are gone from Glass `PENDING`; the completeness and boundary tests pass; nothing under `frontend/src/skins/cinematic/` changed and the Cinematic reader specs pass.
- [ ] The skin never moves the page layer: every jump, zoom, turn, neighbour switch, fling and lens goes through an engine command (review the diff: no `scrollTop` writes or transforms on the page layer in `skins/glass/screens/reader/`).
- [ ] Every inventory row RD1–RD42 has a Glass counterpart or a recorded reason (list them in the report); A65–A73 and A89 still send their calls (network log).
- [ ] Chrome: `glassRegular` groups (the two top groups one masked element), the bottom capsule, the pill, the go-to popover, the scrub rail with the lens growing on `lens` and following on `track`, bookmarks as droplets, read-all segments; auto-hide at 24 / 56 px with the 800 ms, 3,000 ms and 30 s rules; hidden chrome `inert`; cinema, locked mode and its `u` / hidden-button unlock; nothing-beneath back.
- [ ] Page tint: clamped L 0.35–0.50, C ≤ 0.12 at 18 % / 22 % / 30 %, cross-fading over 900 ms only past ΔE 0.04, held during fast flings; the dim follows `pTop` / `pBottom` / the band maximum over 400 ms, 0.64 before the first sample; off and Reduce Transparency behave per §9.4.4; the gutters glow on desktop.
- [ ] Boundaries: 96 px seams with the letter reveal, the seam chip for 1,200 ms, `chapter.seam`; missing, loading and failed-neighbour seams with the back-off; one-at-a-time arms at 48, locks at 72, zooms into the next chapter with momentum; the wheel path at 140 / 210 px; auto next after 900 ms; the caught-up card; the opt-in sideways swipe with `c` 0.35 and the 96 px commit.
- [ ] Paged: Single and Double, RTL spreads, Slide (finger-tracked, `page` spring, 8 px shadow), Fade 160 ms and None, the 30 / 40 / 30 bands, one page per wheel gesture.
- [ ] Gestures: double tap within 280 ms and 24 px zooms at the point on `camera` and never changes chrome visibility; pinch 1–3× (paged 1–4×) with ±0.18 rubber band and `zoom.limit`; the page menu by long-press, right-click and `shift+F10`; Ctrl/⌘ + wheel zoom with the chip; middle-click autoscroll with the dead zone, cap and `all-scroll` cursor; the pointer hides over the strip after 3,000 ms still with the chrome hidden and returns on move.
- [ ] Settings sheet: every row of §G with its scope caption, applying live, persisting through §A; the migration formulas hold on a profile seeded with legacy `dimmer`, `warmth`, `pageTransition` and `autoScrollSpeed` values (and those keys are unchanged afterwards).
- [ ] Chapter list, dialogue overlay and hit lens behave per §H and §I with every state.
- [ ] Desktop panels: 300 and 360 wide, `materialThick`, pushing the strip on `sheet`, the fit rule and toast, landmarks, F6 cycling, Esc returning focus. Tablet, mobile-web and landscape deltas as in §J.
- [ ] Every state of §K and the landing render and are screenshotted.
- [ ] Keyboard: every binding of §M, the Esc order, the Single-key switch; the chrome never hides while `data-sr="on"`.
- [ ] Hit targets: at 390 × 844 every interactive element is at least 44 × 44 with 8 px between hit boxes.
- [ ] Reduced motion: dematerialise and minimise swap instantly or fade 150 ms; the scrub lens fades in place and follows 1:1; the seam chip fades; the next-chapter switch is a 200 ms cross-fade without momentum; Slide becomes a 160 ms cross-fade; the hit lens fades 120 ms; the tint changes stay (colour is not motion); finger tracking stays 1:1; cruise never starts on its own.
- [ ] Solid glass and Increase Contrast render the solid chrome (tint on the rim only) and the contrast modifiers (screenshots).
- [ ] Budget: the §15.7 manga-reader case (top chrome, bottom capsule, scrub lens, seam chip, hit lens, reader sheet) stays at 6 or fewer live `backdrop-filter` elements (budget counter readout in the report); no glass inside the strip.
- [ ] `npm run typecheck`, `npm run lint` (0 errors, 0 warnings), `npm run test` (at or above the floor plus the new tests), `npm run build` (0 errors, 0 warnings), `npm run verify:reader` (exit 0) and `node design/build.mjs --check` are green; `web-35-reader.spec.ts`, `web-34-engine.spec.ts` and every earlier Glass spec pass.

## Verification

**RAM guard (production shares this box).** Before every heavy command (a build, the vitest suite, `next dev`, a Playwright run) run `free -m` and read the `available` column of the `Mem:` row. If it is under 1024 MB, stop and report instead of running it. Never run two builds at once, and never run `next build` while `next dev` or a Playwright browser is running.

From `frontend/`:

```bash
free -m && npm run typecheck
free -m && npm run lint
free -m && npm run test
free -m && npm run build
npm run verify:reader
cd .. && node design/build.mjs --check && cd frontend
```

Dev stack as `backend/scripts/README-dev-stack.md` says (uvicorn 127.0.0.1:8010, the dev SQLite, never production data); export `MM_PROOF_USER` and `MM_PROOF_PASSWORD` from its demo account; then:

```bash
free -m && NEXT_PUBLIC_API_URL=/api BACKEND_INTERNAL_URL=http://127.0.0.1:8010 npm run dev -- --port 3010
# second shell
free -m && E2E_BASE_URL=http://127.0.0.1:3010 E2E_USERNAME=$MM_PROOF_USER E2E_PASSWORD=$MM_PROOF_PASSWORD npx playwright test e2e/glass/web-35-reader.spec.ts --workers=1
free -m && E2E_BASE_URL=http://127.0.0.1:3010 E2E_USERNAME=$MM_PROOF_USER E2E_PASSWORD=$MM_PROOF_PASSWORD npx playwright test e2e/glass e2e/engine --workers=1
free -m && E2E_BASE_URL=http://127.0.0.1:3010 E2E_USERNAME=$MM_PROOF_USER E2E_PASSWORD=$MM_PROOF_PASSWORD npx playwright test e2e/cinematic --grep -i reader --workers=1
```

**Visual proof** with `frontend/scripts/proof.mjs` (run `node scripts/proof.mjs --help` first), headless Chromium, named session `web-35`, at 1440 × 900 and 390 × 844 (and `--dpr3` for 440 × 956 on the chrome-shown shot):

```bash
free -m && node scripts/proof.mjs --step web-35 --skin glass --session web-35 --viewport-only --routes docs/redesign/proof/web-35/routes.txt
free -m && node scripts/proof.mjs --step web-35/reduced --skin glass --session web-35 --viewport-only --reduced --routes <reader URL>
free -m && node scripts/proof.mjs --step web-35/dpr3 --skin glass --session web-35 --viewport-only --dpr3 --routes <reader URL>
free -m && node scripts/proof.mjs --step web-35/cinematic --skin cinematic --session web-35 --viewport-only --routes <reader URL>,<read-all URL>
```

`routes.txt` holds a chapter reader URL reached from a followed series, the same chapter from the source series page, a read-all URL, `?sheet=settings`, `?sheet=chapters`, a `?q=` dialogue URL (with an OCR fixture), a chapter on a white-page series and one on a dark series (to show the tint and the dim), an unknown chapter key, and `/reader`. Interaction states go into a scratch Playwright script under your scratchpad that imports `signIn` from `scripts/proof.mjs`, saving into `docs/redesign/proof/web-35/states/`: `chrome-shown-{desktop,phone}.png`, `chrome-hidden-pill-{desktop,phone}.png`, `cinema-{desktop,phone}.png`, `locked-phone.png`, `goto-popover-phone.png`, `scrub-lens-phone.png`, `rail-hover-desktop.png`, `seam-{desktop,phone}.png`, `seam-chip-phone.png`, `seam-loading-desktop.png`, `seam-failed-desktop.png`, `seam-missing-desktop.png`, `next-card-armed-phone.png`, `next-card-locked-phone.png`, `caught-up-phone.png`, `swipe-neighbour-phone.png`, `paged-single-desktop.png`, `paged-double-desktop.png`, `paged-slide-mid-phone.png`, `page-menu-phone.png`, `settings-sheet-{medium,large}-phone.png`, `taps-overlay-phone.png`, `chapter-list-phone.png`, `chapter-list-offline-phone.png`, `panels-both-desktop.png`, `panel-left-desktop.png`, `panels-narrow-1100.png` (with the toast), `gutters-desktop.png`, `tint-white-page-phone.png`, `tint-dark-page-phone.png`, `dialogue-overlay-phone.png`, `hit-lens-{desktop,phone}.png`, `landscape-phone-844x390.png`, `tablet-768.png`, `middle-autoscroll-desktop.png`, `zoom-chip-phone.png`, every state of §K (`<state>-{desktop,phone}.png`), and `chrome-solid-phone.png` and `chrome-contrast-phone.png` (init script setting `document.documentElement.dataset.solid = "on"` or `dataset.contrast = "more"` on `DOMContentLoaded`). If you use `playwright-cli`, pass `-s=web-35`. Write `docs/redesign/proof/web-35/report.md` mapping each screenshot to the acceptance item it proves. Stop `next dev` when done.

`00-baseline.md` records lint and build at 0 errors and 0 warnings; keep them there. This step changes nothing in `mobile/` or `backend/`: check each of your commits with `git show --stat --format= <hash>` (the parallel `mobile/NN` session and the backend and shared sessions commit `mobile/` and `backend/` on the same branch, so never judge by the branch diff). If one of your commits touched them, revert that part and prove the baseline with `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze` (No issues found), `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter test` (all 2012 tests pass, or the current higher count) and `cd backend && .venv/bin/python -m pytest -q --no-header`, one at a time after the RAM guard.

## Git

- Branch `feat/vps-slim-source-native`. Commit small and often: the plan; §A with its tests; the frame and light layers; the chrome; the tint and dim; strip, seams and boundaries; paged; gestures; the settings sheet; the chapter list and side panels; the dialogue overlay and hit lens; states and landing; keys; the e2e spec; the proof. Example: `feat(web-glass): manga reader chrome with page tint and the legibility dim`.
- Stage explicit paths only, never `git add -A` or `git add .`: the mobile, backend and shared sessions commit in the same checkout.
- No Claude or AI attribution anywhere: no `Co-Authored-By` line, no "Generated with" line, no AI author. Never commit real credentials or secrets (the dev-stack demo password is committed only in `backend/scripts/README-dev-stack.md` by `backend/00`; never copy it into a spec, script or proof file), `.env*` or `.claude/`.
- Run `npm run build` (after `free -m`, with `next dev` stopped) before every push, then `git push origin feat/vps-slim-source-native` after each working step.
- Never edit `backend/connectors/`. Never touch production containers or `/srv/manhwamaniacs/{app,data}`. Do not deploy: Glass stays behind the debug row until `release/01`.

## Report back

Reply with:

1. Done items by section (A, B1–B4, C1–C13, D1–D5, E1–E10, F1–F9, G, H, I1–I2, J1–J6, K, L, M, N), each with its commit hash; anything not done with the reason and its `glass/DESIGN.md` section.
2. The RD1–RD42 map (each row → the Glass element, or "absent on the web" with the reason).
3. Any engine or shared-module change you made (`zoom.ts` `rubberBandMax`, `glass-reader-values.ts`) with its test names.
4. The screenshot folder `docs/redesign/proof/web-35/` and its file list.
5. Test counts: vitest files and cases before and after; each Playwright spec's result (Glass, engine and Cinematic reader); lint, build, `verify:reader` and `build.mjs --check` results; the lowest `free -m` available figure.
6. The live glass count measured in the manga-reader case, and the motion-timings figures for Minimise, Scrub lens, Seam chip, Chapter card rise, Page slide, Hit lens, Dive and the panel re-centre (any raster-only cost listed for the owner's hardware check).
7. Open issues, each with its `glass/DESIGN.md` section.

Next prompt file: `docs/redesign/prompts/web/36-glass-novel-reader.md` (`docs/redesign/prompts/mobile/35-glass-manga-reader.md` runs in parallel).
