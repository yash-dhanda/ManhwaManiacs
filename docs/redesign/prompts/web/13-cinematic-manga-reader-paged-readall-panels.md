# Web Cinematic manga reader 2: paged, read-all, setup sheet, side panels

Track: web · Order 43 · Depends on: `docs/redesign/prompts/web/12-cinematic-manga-reader-strip.md` · Proof folder: `docs/redesign/proof/web-13/`

## Goal

Finish the Cinematic manga reader on the web client on top of what `web/12` built (the strip, chrome, ruler, credits, Contents panel and the engine commands `pinchZoom` and `zoomAt`). This step delivers the paged layouts (single and double, RTL spreads, the Cut / Slide / Fade page turns with a finger-driven Slide), the read-all route `/read-all/:sourceId/:seriesKey` as one continuous strip across the whole series, the "Reading setup" sheet with every control that works on the web today, the right "Margins" side panel (NOTES, DIALOGUE, CIRCLE) with the narrow-desktop and tablet rules, the page actions on long-press and right-click, and the reader rows of the gesture matrix, with every state. The ScreenId `readAll` leaves the Cinematic `PENDING` set, and both the chapter reader and read-all are proven from both entry points (the followed-series page and the source series page).

## Read first

Read these completely before planning. Where this file and `cinematic/DESIGN.md` disagree, `cinematic/DESIGN.md` wins; say so in the report.

1. `docs/redesign/inventory/00-decisions.md` (all of it).
2. `docs/redesign/stack-decision.md` §2.2 (web folder layout, the lint boundary), §2.6, §4 risks 6 and 11.
3. `docs/redesign/cinematic/DESIGN.md`:
   - §2.1.1 (raised-stock scope), §2.1.4 (the folio-flag ground and the over-art rule), §2.1.6 (manga reader grounds), §2.4 (z layers), §2.7 (icons).
   - §4.2–§4.8 (durations; `spring.release` and `spring.sheet`; the motion rows Rise, Panel, Rule slide, Folio flip, Lightbox, Unseal, Arm; reduced motion).
   - §5 (`page.turn`, `scrub.boundary`, `longpress.open` (the web vibrates `[12]` for it on Android Chrome), `select`, `toggle.on`/`toggle.off`, `sheet.detent`, `bookmark.add`, `delete.confirm`) and §6 (cues `turn`, `tick`, `sheet`, `set`).
   - §7 intro, §7.5 (slug lines and the segmented control), §7.9 (sheets, the `[0.5, 0.92]` live-preview detents, column panels on desktop), §7.10 (dialogs and the 1000 ms arm), §7.12 (contents tabs), §7.16, §7.18, §7.20 (sliders), §7.21 (switches, steppers), §7.22 (menus and context menus), §7.23, §7.30 (Lightbox).
   - §8.14 intro, §8.14.3 (the running-head trailing buttons, auto-hide keys `,` and `]`), §8.14.4 (read-all ruler), §8.14.5 (the read-all divider), §8.14.6 (credits), §8.14.7, §8.14.8, §8.14.9, §8.14.10, §8.14.11, §8.14.12, §8.14.13.
   - §9.3.3 (the spoiler guard wording, needed by the CIRCLE tab) and §9.4.5 (the tooltips "Auto-scroll needs the strip.").
   - §11 (every reader row: tap zones, double tap, pinch, horizontal swipe in paged modes, long-press on a reader page, wheel), §14.4, §14.5, §14.6, §15.4, §15.6 (limiter; the bulk bucket), §15.7, §15.9.
4. `docs/redesign/glass/DESIGN.md` §15.4 (the `setLayout` row: "finger-driven Slide is new" on the web, and `jumpToPage`; the commit order).
5. `docs/redesign/inventory/web.md` §1 (R19, R20), §2.9 (reader bindings), §9 (RD1–RD42, especially RD10, RD11, RD29–RD42), §18.6 (A65–A73), §19.3 (K29–K39).
6. `docs/redesign/inventory/capabilities.md` §1 (rate limits: the bulk bucket is 6/min for `POST /reader/chapters/manifest`), §13 (batch manifests, partial failure), §15 (bookmark notes), §20 (`GET /ocr/chapter` and its boxes), §25 (read-all "streaming chapter 1 immediately").
7. `docs/redesign/00-baseline.md`.
8. `docs/redesign/proof/web-12/report.md` (the engine API names `web/12` added and its open issues).
9. Code: `frontend/src/features/reader/` (the engine hook, `spread.ts`, `read-all.ts`, `fit.ts`, `keymap.ts`, `reader-prefs.ts` from `web/12`, `zoom.ts`), `frontend/src/skins/cinematic/screens/reader/` (everything `web/12` built), `frontend/src/skins/cinematic/primitives/` (Sheet, Dialog, Menu, ContextMenu, Slider, Switch, Stepper, Segmented, Tabs, Lightbox), `frontend/src/features/ocr/hooks.ts` (`useOcrChapter`), `frontend/src/features/bookmarks/`, `frontend/src/lib/keyboard/`, `frontend/scripts/proof.mjs`. For the CIRCLE tab read the backend route that serves `GET /circle/series` (`grep -rn "circle/series" backend/routes`) to learn its payload.

## Preconditions

- `git log --oneline -20` shows the `web/12` commits; `npm run test` in `frontend/` is green (record file and case counts as your floor).
- `frontend/src/skins/cinematic/index.ts` lists `readAll` in `PENDING` and no longer lists `reader`.
- `docs/redesign/proof/web-12/report.md` exists; read its engine API section.

## Skills to invoke

1. `superpowers:writing-plans` before any code; the plan goes to `docs/redesign/proof/web-13/plan.md`.
2. `superpowers:test-driven-development` for every engine change and every pure helper.
3. `superpowers:subagent-driven-development` (or `superpowers:executing-plans` inline). At most 6 implementer subagents; one heavy command at a time; verify their work against `git status` and `git diff`, not their reports.
4. `frontend-design:frontend-design`, `impeccable:impeccable` and `taste-skill:taste-skill` for the sheet, panels and paged stage.
5. `superpowers:verification-before-completion` before claiming done.

## Scope: deliver every item below

### A. Skin-neutral engine work (`frontend/src/features/reader/`, no pixels)

A1. **Paged layouts through the engine** (glass §15.4 `setLayout`): `setLayout("strip" | "single" | "double", { direction: "ltr" | "rtl" })` over today's `PagedView` logic (single and double, RTL spreads through `spread.ts`, fit through `fit.ts`), plus a page-turn hook with `{ kind: "cut" | "slide" | "fade" }`. Add the **finger-driven Slide**: `dragTurn(dx)` moves the current page with the finger (the incoming page enters from its reading side), `releaseTurn(vx)` commits when the drag passed 72 px or 600 px/s (§11) and settles with a Motion spring transition passed by the skin, otherwise springs back. Keep the pure decision (`shouldCommitTurn(dx, vx, width)`, RTL mirroring, two-page steps in double) in `frontend/src/features/reader/page-turn.ts` with `page-turn.test.ts`.
A2. **Paged zoom** with `pinchZoom`/`zoomAt` from `web/12`, bounds 1–3×; double tap 1× ⇄ 2× at the point; while zoomed, drags pan and never turn pages.
A3. **Preload 3 pages ahead** in paged modes (§8.14.7) through the engine's preload (`preload.ts`), P0 for the visible page and the next, P3 for the rest (§15.6 limiter).
A4. **Read-all feed**: the windowed batch manifests of `read-all.ts` (`POST /reader/chapters/manifest`, ≤ 20 chapter keys per request, the bulk bucket of 6 requests per minute) with chapter 1 (or `?from`) streamed immediately from its single manifest while the batches fill in; per-chapter `status: "error"` items become a retryable failed chapter in the feed, never a failed feed. The current chapter's position (12 of 201) is `web/03`'s existing `chapterPosition: { index, total }` in engine state: fill it for read-all, do not add a second field for it; add only `readAllBoundaries: readonly { chapterKey, number, startFraction }[]` (the positions of the chapter boundaries along the loaded window, 0–1, which the ruler draws as gaps). Tests for the window arithmetic and the partial-failure mapping.
A5. **Per-page overlay slot** `renderPageOverlay({ page, chapterKey, box })` drawn inside each page's positioned box (absolute children placed in percentages of the page box), so OCR outlines follow scroll and zoom for free. OCR boxes from `GET /ocr/chapter` are fractions 0–1 with a top-left origin (`x`, `y`, `width`, `height`; use `left`, `top`, `right`, `bottom` when `x`/`y` are null); put the conversion in `frontend/src/features/ocr/boxes.ts` with a test.
A6. **Current-page focus for page actions**: `pageAtReadingLine()` (the page under 38 % of the viewport in the strip, the current page in paged modes) for the keyboard and phone paths of the page actions (section G).

### B. Paged modes (§8.14.7)

B1. Stage: the page fits by `fitMode` (`WIDTH │ HEIGHT │ ORIGINAL`) within the viewport minus 24 px, ground colour around (Black `#000000`, Ink `#0B0B0A`, Slate `#1A1A18`).
B2. **Double**: two pages side by side with an 8 px ground gutter and a 1 px `rule.1` centre line; RTL mirrors display order; a wide page (width > height, a landscape spread) occupies both slots alone.
B3. **Page turn** (`pageTurn`): `CUT` (0 ms, default), `SLIDE` (the incoming page pushes in from its reading side, 280 ms `dur.pageturn` `ease.settle`; finger releases use `spring.release` = `{ type: "spring", visualDuration: 0.42, bounce: 0 }`), `FADE` (160 ms). Sound `turn` if UI sounds are on (the web maps `page.turn` to no vibration). Reduced motion: every turn is a 150 ms (`dur.reduced`) opacity cross-fade and a finger release finishes with a 150 ms fade.
B4. **Tap zones** 30 / 40 / 30 % of the width, default previous / menu / next, mirrored for RTL until the user sets their own (`tapZones`). The first time a zone layout is used on this device, paint the zones as three labelled bands (`BACK · MENU · NEXT`, 1 px `ink.30` outlines, labels in `type-kicker`) that fade out over 1000 ms (`dur.fade.hint`) after a 1500 ms hold (`dur.hold.glance`); they reappear whenever the zone layout changes, and on `Show zones` in the setup sheet. Remember the seen layouts in scoped `localStorage` `mm.reader.zones-seen` (a list of layout + zone-config strings). Cursor `pointer` over the side zones, `default` over the centre.
B5. **Wheel**: one page per wheel gesture with a 200 ms idle reset; `Ctrl`/`⌘` + wheel zooms.
B6. **Swipe** (mobile web): horizontal swipe turns pages by reading direction, the page tracking the finger (A1); touches that start within 24 px of either screen edge are ignored (§8.0.5); zoom > 1× pans instead.
B7. **Desktop double-click on a side zone turns two pages and never zooms** (§8.14.5); double-click in the centre zooms 1× ⇄ 2×.
B8. **Zoom** 1–3× (A2) with the `200%` folio chip from `web/12`.
B9. **Chapter end**: after the last page, one more "page" holds the credits (`web/12`'s `Credits` in full form, with the Coming up card and `Read chapter 143`) centred on the stage; turning past it opens the next chapter by Dip.
B10. Keys in paged modes: `→`/`d` and `←`/`a` turn by reading direction, `j`/`k` next/previous page, `Space`/`Shift+Space` next/previous page, `Home`/`End` first/last page; `w` / `v` / `r` switch to strip / single / right-to-left single (the Komga letters). Auto-scroll is absent in paged modes: the folio-bar button is not rendered and `p` does nothing.

### C. Read-all (`/read-all/:sourceId/:seriesKey?from&page&at`, ScreenId `readAll`)

C1. Screen file `frontend/src/skins/cinematic/screens/read-all.tsx` rendering `<MangaReader kind="readAll">`; enters by the Column wipe from the feature page's `Read all` (`web/06`'s `enterReader(href, { entry: "wipe" })` from `motion.ts`), by Dip from elsewhere; exits by Dip.
C2. Continuous strip only: the Layout control and `w`/`v`/`r` are hidden and inert.
C3. **Read-all divider** between chapters: a 48 px band with `142 → 143` in `type-folio` between hairlines (`rule.1`), no card and no pause ("without feeling it"); `scrub.boundary` when crossed (sound `tick`).
C4. Running head: the chapter folio adds `· 12 OF 201` (from A4; spoken "chapter 12 of 201").
C5. Ruler (§8.14.4): the track spans the chapters loaded in the read-all window; chapter boundaries are 2 px gaps in the track with the chapter folio (`CH 143`) shown on hover; `scrub.boundary` at each boundary while dragging; the `07 / 40` folio refers to the current chapter.
C6. Contents in read-all scrolls to the chapter (no Dip).
C7. States: the list failure notice ("This series' chapter list didn't come through, so there's nothing to read through." + `Try again` + `Go to the series`); a chapter whose batch item failed shows the `CORRECTION` notice "Chapter 143 didn't load." + `Try again` + `Open it on its own →` in its place and reading continues past it; a 429 on the batch call shows the `SLOW DOWN` band with the live `Retry-After` countdown; offline reads saved chapters only and the first unsaved chapter shows "Next chapter isn't saved on this device" with `Back to Downloads`; the rest of the §8.14.11 rows as in `web/12`.

### D. Reading setup (§8.14.8)

D1. Entry: the running-head settings button (`sliders-horizontal`, `bare`, tooltip "Reading setup"; inserted into `web/12`'s trailing array after `note-pencil` on tablets and desktop and after bookmark on phones, per the order `web/12` E4 fixes: download, bookmark, guided view, `sidebar-simple`, `note-pencil`, settings, `dots-three`) and `,` (which reveals the chrome). Phones: a `[0.5, 0.92]` sheet (§7.9: `paper.2`, 1 px `rule.2` top edge, grabber 32 × 3 `ink.30`, 56 px header, Rise 360 ms, close 240 ms `lift`, drag release `spring.sheet`, dismiss below 30 % or faster than 800 px/s) with the page live above it at the half detent. Tablets and desktop: the right side panel slot (3 columns, min 320 px, `paper.0`, 1 px `rule.1` inner edge) which hides Margins while open; closing it restores Margins if Margins was open. On the web, the sheet pushes a history entry (`?sheet=setup`) so browser back closes it.
D2. Header: kicker `READING SETUP`, title = the series title (`type-subhead`), `quiet` `Done`. Contents tabs `LAYOUT · IMAGE · CONTROLS · AMBIENT` (§7.12, Rule slide). Every control shows where it is saved as a `type-caption` `ink.60` line: "Saved for this series", "Saved for this profile", "Saved on this device", or "For this reading only".
D3. Every change applies live under the sheet; steppers roll their digits (Folio flip, 80 ms per digit, 40 ms apart, `ease.set`); closing the sheet also hides the chrome. The sheet root carries `data-stock="raised"` (it paints `paper.2`), so `ink.45` roles render `ink.60`.
D4. Rows, exactly (values, defaults and scopes from §8.14.8; storage through `web/12`'s `reader-prefs.ts`):

| Tab | Control | Options and range | Default | Saved |
|---|---|---|---|---|
| LAYOUT | Layout | `STRIP │ SINGLE │ DOUBLE` segmented (hidden in read-all; `GUIDED` is added by `web/23`) | `STRIP` | per series |
| LAYOUT | Direction | `LEFT TO RIGHT │ RIGHT TO LEFT`, captions "Webtoons and western comics" / "Manga" | `LEFT TO RIGHT` | per series |
| LAYOUT | Fit | `WIDTH │ HEIGHT │ ORIGINAL`; Height and Original disabled in strip with tooltips "Fit to height works in the paged layouts." and "Original size works in the paged layouts." | `WIDTH` | per series |
| LAYOUT | Side margin (phones only) | `0 · 5 · 10 · 15 · 20 · 25 %` single-select slug line | `0 %` | per profile |
| LAYOUT | Strip width (tablets and desktop only) | slider 480–860 px, step 20, value flag `640 PX` | `clamp(480px, 46vw, 860px)` until set | per device |
| LAYOUT | Zoom | stepper 50–300 %, step 10, with `Reset`; sets the series' resting zoom | 100 % | per series |
| LAYOUT | Gap between pages | switch (strip only), 8 px of ground | off | per profile |
| LAYOUT | Page turn | `CUT │ SLIDE │ FADE` (paged only) | `CUT` | per profile |
| IMAGE | Brightness | slider −75 … 0, step 1, caption "Dims below your screen's lowest setting." | 0 | per profile |
| IMAGE | Warmth | slider 0–100, step 1 | 0 | per profile |
| IMAGE | Colour | `NORMAL │ SEPIA │ GREY` | `NORMAL` | per profile |
| IMAGE | Ground | `BLACK │ INK │ SLATE` | `BLACK` | per profile |
| CONTROLS | Tap zones | three segmented rows `LEFT / CENTRE / RIGHT` × `PREVIOUS │ MENU │ NEXT`, `Reset`, `Show zones` | automatic: paged previous / menu / next (mirrored for RTL), strip menu everywhere | per profile |
| CONTROLS | Strip taps | `MENU │ TAP TO SCROLL` | `MENU` | per profile |
| CONTROLS | Swipe sideways to change chapter | switch; rendered on coarse pointers only, absent on desktop | on | per profile |
| CONTROLS | Cinema mode | switch | off | per profile |
| CONTROLS | Fullscreen | switch, rendered whenever `document.fullscreenEnabled` is true, at every width | off | session |
| CONTROLS | Auto next chapter | switch | on | per profile |
| AMBIENT | Auto-scroll | play / pause button (strip only; in paged layouts the row reads "Auto-scroll needs the strip.") | stopped | session |
| AMBIENT | Auto-scroll speed | speed ruler 0.50–3.00× in 0.05 steps, labelled at 0.5, 1, 1.5, 2, 2.5, 3 (`type-folio`), value flag while dragging, commits on release, preset slugs `0.8 · 1 · 1.25 · 1.5 · 2`, touch-and-hold (double-click on desktop) resets to 1.00×, and the px/s equivalent under the value (`≈ 47 PX/S` from `web/12`'s `autoScrollPxPerSecondX`) | 1.00× | per series |

   App-only rows (Keep screen awake, Lock controls, Volume keys turn pages, Refresh rate) are not rendered on the web. The other AMBIENT rows (Resume after I let go, Pace by dialogue, Soundscape, Soundscape volume, Page-tinted chrome, Guided view auto-advance) and the `GUIDED` layout are appended by `web/23`: keep the AMBIENT rows as an ordered array.
D5. Footer: `Shortcuts` (desktop only; opens the `?` keyboard sheet) and a `quiet` `Reset reader settings` opening the §7.10 dialog "Restore every reader setting to its default?" whose destructive confirm arms for 1000 ms (a 2 px `proof` rule fills under it, `ease.linear`; reduced motion shows it full at 1000 ms); on confirm every per-series, per-profile and per-device reader value returns to its default.
D6. Semantics per §7 intro: segmented controls are `role="radiogroup"`; switches Base UI Switch with the row label; sliders native ranges with `aria-valuetext` ("Brightness minus 40", "Speed 1.25 times"); every control reachable by `Tab`, arrows step, `Shift`+arrows ×10, `Home`/`End`.

### E. Side panels (§8.14.12)

E1. **Right, "Margins"** (`]`, and the `note-pencil` button inserted into the running head on tablets and desktop right after `sidebar-simple`, tooltip "Margins"): `paper.0`, 1 px `rule.1` inner edge, 3 columns (min 320 px), slides 320 ms `ease.settle` (out 224 ms `ease.lift`); on desktop it never overlaps the strip (the strip recentres in the remaining columns, 320 ms `ease.turn`); on tablets (768–1023) it opens as a column panel over the page. Remembered per profile (`panels.right`); where both panels cannot fit, only the most recently opened is restored. Reduced motion: 150 ms fade in place, the strip recentres at once. Contents tabs `NOTES · DIALOGUE · CIRCLE`.
E2. **NOTES**: this chapter's bookmarks (from `useBookmarks({ sourceId, seriesKey })`, filtered to the chapter) as rows `p. 12` folio + the note in `type-body` (or "No note" in `type-caption` `ink.45`), clicking a row scrolls to it; `Add a note to this page` (a `quiet` button) saves a bookmark on the page at the reading line and opens its note field (Enter saves through `POST /reader/bookmark` with `note`, Esc cancels); empty: "No bookmarks in this chapter yet." plus the same button.
E3. **DIALOGUE**: when `GET /ocr/chapter` answers (`useOcrChapter`), the transcript as subtitle lines per page: a `p. 12` folio and the page's lines in `type-body`; hovering (or focusing) a line outlines its bubble on the page with a 2 px `spot` frame through the A5 overlay; clicking scrolls there (400 ms `dur.glide` `ease.settle`, a jump under reduced motion) and pulses the frame twice (480 ms each). A 404 or empty text: "Dialogue isn't indexed for this chapter." (`type-caption`). Loading: a 24 px leader dial after 400 ms. Error: a `CORRECTION` line with `Try again`.
E4. **CIRCLE**: who in the circle read this chapter (`GET /circle/series` through `useCircleSeries(sourceId, seriesKey)` in `frontend/src/features/circle/hooks.ts`; create `features/circle/api.ts` and `hooks.ts` if they do not exist yet, and keep them minimal for `web/22` to extend), each row a 20 px avatar, the member's name in `type-ui`, and their reaction on this chapter shown as its label in `type-kicker` (`LOVED`, `SHOOK`, `LAUGHED`, `TEARS`, `CHEF'S KISS`, `HYPE`, `WRECKED`; `web/22` swaps in the stamp glyphs). **Spoiler guard**: while the viewer has not finished the open chapter, a reaction on it or on any later chapter shows only the 20 px avatar and "reacted to Ch. 142" in `type-caption` `ink.45`, never the label; reactions on finished chapters show in full; members further on read "Riya is on Ch. 150" with no detail. When `onChapterCompleted` fires, guarded rows unseal: the label fades in over 160 ms `ease.settle` (the Unseal move). `Recommend this series…` is added by `web/22`. When the endpoint answers 404 (Circle not deployed) the CIRCLE tab is not rendered; when the viewer has no Circle members the tab reads "Nobody in your circle has read this yet."
E5. **Narrow desktops** (the `web/12` rule, now with both slots): if viewport − 2 × grid margin − the open panels would leave the strip under 480 px, opening a panel closes the one on the other side (last opened wins, 320 ms `ease.settle`); Reading setup takes the right slot as in D1.
E6. Panels are `aside` landmarks labelled "Contents" and "Margins"; focus moves into a panel when it opens by key and returns to the trigger when it closes; `Esc` closes the top panel first (the escape order).

### F. Page actions (§8.14.13)

F1. Opened by a 450 ms long-press on a page (phones; `longpress.open`, `navigator.vibrate([12])` on Android Chrome when haptics are on; sound none), right-click on a page (desktop, Base UI `ContextMenu` at the pointer), the context-menu key or `Shift+F10` on the reading region (the page at the reading line), and a `dots-three` "Page actions" button appended as the last trailing button of the running head on tablets and desktop (the §11 "running-head overflow" alternative for long-press). On phones, where the running head keeps at most four trailing buttons, the Reading setup sheet footer gains a `quiet` `Page actions for p. 18` button as the non-gesture path.
F2. Phones: a `[0.5, 0.92]` sheet; desktop: a menu (§7.22: `paper.2`, 1 px `rule.2`, 40 px items, clip reveal 200 ms, exit fade 120 ms, arrows, `Home`/`End`, type-ahead, `Esc`).
F3. Items: `Bookmark this spot` (then a note field after saving), `Show dialogue on this page` (overlays that page's OCR boxes as 1 px `spot` outlines through A5; tapping or focusing a box shows its recognised text in a small `paper.2` popover with `type-body`; absent when the chapter has no OCR text), `Retry this page`, `Open page image` (the §7.30 Lightbox with this page: match cut from the page box, pinch to 4×, double tap 1× ⇄ 2.5×, drag down to dismiss back into its box, caption `PAGE 18 · 800 × 12400` on the folio-flag ground, `?view=page` history entry). `React to this chapter` is added by `web/22`; `Scan this chapter's dialogue` is app-only.

### G. Keys added in this step (register in the "Reader" group)

| Key | Action |
|---|---|
| `,` | Reading setup (reveals the chrome) |
| `]` | Toggle the Margins panel (reveals the chrome) |
| `w` / `v` / `r` | Strip / single / right-to-left paged (inert in read-all) |
| paged `→`/`d`, `←`/`a`, `j`/`k`, `Space`/`Shift+Space`, `Home`/`End` | B10 |
| context-menu key, `Shift+F10` | Page actions for the page at the reading line |

The escape order stays: close sheet or panel (the Lightbox first when open) → leave fullscreen → leave cinema → exit to the series page. Update `keys.test.ts`.

### H. Gestures (§8.14.10, §11): every reader row not finished in `web/12`

Tap zones in paged modes (B4); double tap and double-click in paged modes (A2, B7); pinch in paged modes (A2); horizontal swipe in paged modes (B6); long-press 450 ms and right-click on a page (F1); wheel in paged modes (B5); drag on the Reading setup sliders and the speed ruler (`spring.scrub` release); swipe down on the sheet (D1). Each keeps its §11 non-gesture alternative.

### I. States (every one, in both layouts and in read-all)

Loading chapter in paged modes: one galley page plate at the manifest aspect centred on the stage with `LOADING CH 142` in the running head and a 24 px leader dial after 400 ms. Broken page on the stage: kicker `PAGE 18 DIDN'T LOAD`, `quiet` `Retry`, the reason in `type-caption`. No pages, error, offline, rate limited, 18+ rating card, not available: as `web/12` (§8.14.11), also on the paged stage and in read-all. Setup sheet: every control disabled state has its tooltip; the Fullscreen row is absent when fullscreen is unavailable. Margins: the NOTES, DIALOGUE and CIRCLE states of E2–E4.

## Out of scope here (owned by later steps)

- `web/19`: the `PREVIOUSLY ON` chip on the first page.
- `web/22`: reaction stamps, `React to this chapter`, `Recommend this series…`, unseal inside the credits.
- `web/23`: `GUIDED` layout and `u`, page-tinted chrome and the setup sheet's tinted top rule, soundscape rows and indicator, pace by dialogue, resume after release, the auto-scroll chip, guided-view auto-advance.
- Mobile-only rows and behaviours (Lock controls, Keep screen awake, Volume keys, Refresh rate, the K01 sideways-strip migration toast, `Scan this chapter's dialogue`).

## File layout

```
frontend/src/skins/cinematic/screens/read-all.tsx                 ScreenId readAll
frontend/src/skins/cinematic/screens/reader/
  PagedStage.tsx          B1–B9 (single, double, turn animations, credits page)
  TapZoneBands.tsx        B4 first-use bands
  ReadAllDivider.tsx      C3
  ReadingSetup.tsx        D1–D6 (sheet on phones, right panel on tablets and desktop)
  setup-rows.ts           the ordered row definitions per tab (web/23 appends AMBIENT rows)
  SpeedRuler.tsx          the 0.50–3.00× tick ruler (reused by web/15's Listen speed sheet and web/23's chip)
  MarginsPanel.tsx        E1–E4
  DialogueTranscript.tsx  E3
  CircleReaders.tsx       E4
  PageActions.tsx         F1–F3
  OcrOverlay.tsx          the A5 overlay content (bubble frames, 1 px outlines, pulse)
  (extend) MangaReader.tsx, RunningHead.tsx, FolioBar.tsx, Ruler.tsx, SidePanelLayout.tsx, keys.ts, gestures.ts
frontend/src/features/reader/page-turn.ts (+ page-turn.test.ts)   A1
frontend/src/features/reader/<engine hook>                         A1–A6
frontend/src/features/reader/read-all.ts (+ tests)                 A4
frontend/src/features/ocr/boxes.ts (+ boxes.test.ts)               A5
frontend/src/features/circle/api.ts, hooks.ts                      E4 (only if absent)
frontend/src/skins/cinematic/index.ts                              remove readAll from PENDING
docs/redesign/proof/web-13/                                        plan.md, screenshots, report.md
```

Skin files import only data, hooks and their own skin folder (the `web/00` lint rule).

## Acceptance criteria

- [ ] `readAll` is removed from the Cinematic `PENDING` set; the completeness test passes.
- [ ] Single and double layouts render with the 24 px stage inset, the 8 px gutter and the 1 px `rule.1` centre line; an RTL series mirrors the display order and a landscape page occupies both slots; `w`, `v`, `r` switch layouts.
- [ ] Cut, Slide (280 ms `ease.settle`, finger-tracked on touch, `spring.release` on release) and Fade (160 ms) all work; the motion-timings overlay logs each turn within one frame; reduced motion turns with a 150 ms cross-fade.
- [ ] Tap zones: 30 / 40 / 30, mirrored for RTL, labelled bands on first use (hold 1500 ms, fade 1000 ms) and on `Show zones`; the wheel turns one page per gesture; a double-click on a side zone turns two pages; paged zoom 1–3× with double tap 1× ⇄ 2×.
- [ ] Paged chapter end shows the credits page, and turning past it opens the next chapter by Dip.
- [ ] Read-all: opens from the feature page's `Read all` with the Column wipe, shows the first chapter before the batches finish, shows `· 12 OF 201`, the 48 px `142 → 143` divider, ruler gaps with hover folios; a failed batch item shows its inline notice and reading continues; the list-failure copy is exact.
- [ ] Reading setup: every row of D4 is present with its range, default, scope caption and live effect; Height and Original are disabled in strip with their tooltips; app-only rows are absent; the Fullscreen row follows `document.fullscreenEnabled`; `Reset reader settings` arms for 1000 ms.
- [ ] On 1440 × 900 the setup panel takes the right slot and hides Margins, and closing it restores Margins; on 390 × 844 it is a `[0.5, 0.92]` sheet with the page live above it and browser back closes it.
- [ ] Margins: NOTES lists this chapter's bookmarks and saves a note; DIALOGUE outlines the hovered line's bubble with a 2 px `spot` frame and pulses it twice on click; CIRCLE hides guarded reactions as "reacted to Ch. 142" and unseals them in 160 ms when the chapter completes; the tab is absent when `/circle/series` answers 404.
- [ ] The narrow-desktop rule holds at 1024 × 768: opening one panel closes the other; the strip never falls under 480 px and never sits under a panel on desktop.
- [ ] Page actions open by long-press (phone emulation), right-click, `Shift+F10`, the desktop `dots-three` and the phone setup-sheet footer button; `Open page image` opens the Lightbox with the page and returns into its box.
- [ ] Keyboard: every key in G and every `web/12` key works in all three layouts and in read-all with no mouse; focus is trapped in the sheet and the Lightbox and returns to the trigger.
- [ ] Hit targets: every control in the sheet, panels and page-actions menu is ≥ 44 × 44 px on a coarse pointer and ≥ 32 × 32 px on desktop (Playwright `getBoundingClientRect()` check).
- [ ] Reduced motion: panel slides become 150 ms fades, sheet Rise a 150 ms fade, page turns 150 ms fades, the transcript scroll jumps, the Lightbox fades; leader dials keep running.
- [ ] Per-skin difference: the legacy reader at the same URLs (with `mm-skin-debug=legacy`) is unchanged and its settings sheet still reads and writes the legacy fields; the legacy reader tests still pass.
- [ ] `npm run typecheck`, `npm run lint`, `npm run test`, `npm run build` in `frontend/` are green, with counts at or above the precondition floor plus the new tests.

## Verification

**RAM guard.** Before every heavy command run `free -m`; if the `available` figure of the `Mem:` row is under 1024 MB, stop and report. Never run two builds at once, never `next build` while `next dev` runs, and run the commands below one at a time.

From `frontend/`:

```bash
free -m && npm run typecheck
free -m && npm run lint
free -m && npm run test
free -m && npm run build
npm run verify:reader    # prints that it is superseded by e2e/
```

Lint and build stay at 0 errors and 0 warnings (`00-baseline.md`). This step changes nothing under `mobile/` or `backend/`. Prove it on your own commits, not on a range (the mobile, backend and shared sessions push to the same branch in parallel, so a range diff shows their work too): `for c in <each commit SHA you made in this step>; do git show --name-only --format= "$c"; done | grep -E '^(mobile|backend)/'` must print nothing. The other suites are therefore not re-run here; their sessions run them and keep the baseline: `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze` (No issues found), `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter test` (all 2012 passed) and `cd backend && .venv/bin/python -m pytest -q --no-header`.

**Visual proof.** Start the dev stack with `free -m && backend/scripts/dev_stack.sh start` (the dev stack of `backend/scripts/README-dev-stack.md`: uvicorn on 127.0.0.1:8010 against the dev SQLite under `/srv/manhwamaniacs/dev/data/`, never production data; the script already sets `MM_NOVELS_ENABLED=true`, turns rate limits off and leaves the AI key unset; run `backend/scripts/dev_stack.sh seed` once if the `demo` account does not exist yet), then the web client with `cd frontend && free -m && NEXT_PUBLIC_API_URL=/api BACKEND_INTERNAL_URL=http://127.0.0.1:8010 npx next dev -p 3010` (both variables are required: without `NEXT_PUBLIC_API_URL=/api` the browser calls `http://127.0.0.1:8000` directly (`src/config/env.ts`), and without `BACKEND_INTERNAL_URL` the `/api` rewrite in `next.config.ts` targets port 8000). Capture with `node scripts/proof.mjs` (check `--help` for its flags) in the named session `web-13`, skin `cinematic` through the `mm-skin-debug` cookie, at 1440 × 900 and 390 × 844 (touch emulation on the phone), into `docs/redesign/proof/web-13/`:

- `paged-single-{desktop,phone}.png`, `paged-double-desktop.png`, `paged-double-rtl-desktop.png`, `paged-zone-bands-{desktop,phone}.png`, `paged-slide-midturn-phone.png` (captured mid-drag), `paged-credits-page-desktop.png`, `paged-zoomed-phone.png`.
- `readall-{desktop,phone}.png` (with `· 12 OF 201`), `readall-divider-desktop.png`, `readall-ruler-gaps-desktop.png` (hovering a gap), `readall-chapter-failed-desktop.png` (route one batch item to an error), `readall-list-failed-desktop.png`.
- `setup-{layout,image,controls,ambient}-desktop.png`, `setup-{layout,image,controls,ambient}-phone.png`, `setup-reset-arming-desktop.png`.
- `margins-notes-desktop.png`, `margins-dialogue-hover-desktop.png` (a chapter with OCR text, or a Playwright route fixture for `GET /ocr/chapter` stored at `frontend/e2e/fixtures/ocr/chapter.json`), `margins-circle-guarded-desktop.png` (route fixture when Circle has no data on the dev stack), `panels-both-desktop.png`, `panels-narrow-1024.png` (at 1024 × 768).
- `page-actions-menu-desktop.png`, `page-actions-sheet-phone.png`, `page-lightbox-{desktop,phone}.png`, `page-dialogue-outlines-phone.png`.
- `entry-follow-readall-desktop.png` and `entry-source-readall-desktop.png` (read-all opened from `/library/:followedId` and from `/sources/:sourceId/series/:seriesKey`), and the same two for the chapter reader in single layout (`entry-follow-paged-desktop.png`, `entry-source-paged-desktop.png`).
- `reduced-motion-paged-desktop.png`, `legacy-paged-desktop.png`.
- `docs/redesign/proof/web-13/report.md`: each screenshot with the acceptance item it proves.

Stop `next dev` and the dev stack afterwards.

## Git

- Branch `feat/vps-slim-source-native`; small commits (each engine change with its test, then paged, read-all, setup, panels, page actions, proof). Stage paths explicitly, never `git add -A` or `git add .`.
- No Claude or AI attribution anywhere (no `Co-Authored-By`, no "Generated with"); never commit secrets or `.claude/`.
- `npm run build` (after `free -m`) before every push; `git push origin feat/vps-slim-source-native:master` after each working step.
- Never edit `backend/connectors/`; never touch production containers or `/srv/manhwamaniacs/{app,data}`; do not deploy.

## Report back

1. Done items by scope letter A–I, and anything not done with the reason.
2. Screenshot folder `docs/redesign/proof/web-13/` and its file list.
3. Test counts (vitest files and cases before and after), lint and build results, `free -m` before each build.
4. Motion-timings figures for Slide, Fade, the Panel move and the sheet Rise.
5. Engine API added (`setLayout`, `dragTurn`, `releaseTurn`, `renderPageOverlay`, `pageAtReadingLine`, the read-all state) with exact names for `web/23` and the Glass reader.
6. The CIRCLE endpoint status on the dev stack (live data or fixture).
7. Open issues and any place where `cinematic/DESIGN.md` overrode this file (for example the page-actions non-gesture path on phones).

Next prompt: `docs/redesign/prompts/web/14-cinematic-novel-reader.md`.
