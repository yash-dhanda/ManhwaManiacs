# Mobile Cinematic manga reader 2: paged, read-all, setup sheet, panels

Track: mobile · Order 44 · Depends on: `docs/redesign/prompts/mobile/12-cinematic-manga-reader-strip.md` · Web twin: `docs/redesign/prompts/web/13-cinematic-manga-reader-paged-readall-panels.md` · Proof folder: `docs/redesign/proof/mobile-13/`

## Goal

Finish the Cinematic manga reader in the Flutter app on top of what `mobile/12` built (the reader route with the Column wipe and Dip, the strip, chrome, ruler, credits, Contents, the preferences record, `pinchZoom` and `zoomAt`). This step adds a new skin-neutral engine command, `setLayout(single | double, {direction})`, which introduces the app's first page-by-page `PageView` (today's LTR and RTL modes are continuous horizontal strips, glass §15.4) with a page-turn hook for Cut, Slide and Fade and a finger-tracked Slide; the one-time K01 migration toast for readers whose sideways strips became pages; the read-all route `/read-all/:sourceId/:seriesKey` as one continuous strip across the whole series fed by windowed batch manifests; the "Reading setup" sheet with every control the app offers, including the app-only rows (Keep screen awake, Lock controls, Volume keys, Refresh rate); the right "Margins" column panel on tablets (NOTES, DIALOGUE, CIRCLE); the page actions sheet on a 450 ms long-press with its non-gesture paths, including `Scan this chapter's dialogue` on the device's OCR engine; and every state. When you finish, the ScreenId `readAll` leaves the Cinematic `PENDING` set, and the chapter reader and read-all are both proven from both entry points (the followed-series page and the source series page).

## Read first

Read these completely before planning. Where this file and `docs/redesign/cinematic/DESIGN.md` disagree, `cinematic/DESIGN.md` wins; say so in the report.

1. `docs/redesign/inventory/00-decisions.md` (all of it).
2. `docs/redesign/stack-decision.md` §2.3 (mobile layout, boundary and completeness tests, "logic that lives in a widget moves first"), §2.6, §4 risks 1, 6, 9 and 11.
3. `docs/redesign/cinematic/DESIGN.md`:
   - §2.1.1 (raised stock), §2.1.4 (the folio-flag ground and the over-art rule), §2.1.6 (manga reader grounds), §2.2.2 (grids), §2.4, §2.7.
   - §4.2 to §4.8 (`durPageturn` 280 ms, `durFadeHint` 1000 ms, `durHoldGlance` 1500 ms, `CineSprings.release` 504 ms, `CineSprings.sheet` 576 ms, `CineSprings.scrub` 288 ms; the motion rows Rise, Panel, Rule slide, Folio flip, Lightbox, Unseal, Arm; reduced motion).
   - §5 (`page.turn`, `scrub.boundary`, `longpress.open` = `heavy`, `select`, `toggle.on` / `toggle.off`, `sheet.detent`, `bookmark.add`, `delete.confirm`) and §6 (cues `turn`, `tick`, `sheet`, `set`, `toggle.on`, `toggle.off`).
   - §7 intro, §7.5 (slug lines and the segmented control), §7.9 (`CineSheetRoute`, the `[0.5, 0.92]` live-preview detents, tablets max 720 wide), §7.10 (the 1000 ms arm), §7.12 (contents tabs), §7.16, §7.18, §7.20 (sliders), §7.21 (switches, steppers), §7.23, §7.30 (Lightbox, Flutter `Hero` + `InteractiveViewer`).
   - §8.0.5 (back rules: iOS edge swipe disabled in paged readers; modal states), §8.0.9, §8.14 intro, §8.14.1, §8.14.3 (trailing buttons, auto-hide keys `,` and `]`), §8.14.4 (the read-all ruler), §8.14.5 (the read-all divider), §8.14.6, §8.14.7, §8.14.8 (every row, every default, every scope and the "Inventory key (migration)" column), §8.14.9, §8.14.10, §8.14.11, §8.14.12, §8.14.13.
   - §9.3.3 (the spoiler guard wording for the CIRCLE tab), §9.4.5 (the tooltip "Auto-scroll needs the strip.").
   - §11 (every reader row: tap zones, double tap, pinch, horizontal swipe in paged modes, long-press on a reader page, volume keys, drag on sliders and speed rulers, swipe down on sheets), §14.4, §14.5, §14.6, §15.4, §15.6 (limiter), §15.7, §15.9.
4. `docs/redesign/glass/DESIGN.md` §15.4 (the `setLayout` row: "new: no `PageView` exists; LTR/RTL are continuous horizontal strips", `jumpToPage`, and the commit order step 2).
5. `docs/redesign/inventory/mobile.md` S15 and S19 (the reader settings sheet items 20 to 33, the edge prompts, the gestures line), §5a K01 to K12, §6a (modes table, "There is no page-by-page PageView", continuous feed and Read all, tap zones), §6c (OCR run states).
6. `docs/redesign/inventory/capabilities.md` §1 (rate limits: the bulk bucket is 6 requests per minute for `POST /reader/chapters/manifest`), §13 (batch manifests and partial failure), §15 (bookmark notes), §20 (`GET /ocr/chapter` boxes, `POST /ocr/chapter` for the scan), §25.
7. `docs/redesign/00-baseline.md`.
8. The web twin `docs/redesign/prompts/web/13-cinematic-manga-reader-paged-readall-panels.md` and `frontend/src/features/reader/spread.ts` with `spread.test.ts` (the pairing rules you port, so both clients pair the same pages).
9. `docs/redesign/proof/mobile-12/report.md` (the engine API names and the preferences record `mobile/12` added, and its open issues).
10. Code: `mobile/lib/features/reader/engine/` (all of it), `mobile/lib/features/reader/models/reader_prefs.dart` and its provider, `mobile/lib/features/reader/utils/reader_tap_zones.dart`, `mobile/lib/skins/cinematic/screens/reader/` (everything `mobile/12` built), `mobile/lib/skins/cinematic/primitives/` (`sheet_route.dart`, `lightbox.dart`, the segmented control, switch, stepper, slider, contents tabs, notices), `mobile/lib/features/ocr/` (`controllers/ocr_run_controller.dart`, `services/ocr_engine.dart`, the `ocrChapterTextProvider` from `mobile/12`), `mobile/lib/features/library/providers/bookmarks_provider.dart`, `mobile/lib/features/downloads/providers/bookmark_outbox_provider.dart`, `mobile/lib/core/platform/native_bridge.dart`, `mobile/lib/features/reader/utils/reader_display_mode.dart`, `mobile/lib/features/reader/utils/reader_wakelock.dart`. For the CIRCLE tab read the backend route that serves `GET /circle/series` (`grep -rn "circle/series" backend/routes`) to learn its payload.

## Preconditions

- `git log --oneline -25` shows the `mobile/12` commits; `docs/redesign/proof/mobile-12/report.md` exists and you have read its engine API section.
- The Cinematic `PENDING` set lists `readAll` and no longer lists `reader`.
- Run `free -m`, then `/srv/manhwamaniacs/dev/flutter/bin/flutter test` from `mobile/` once and record the passed count as your floor (never below the 2012 of `00-baseline.md`: every test that passed there must still pass).

## Skills to invoke

1. `superpowers:writing-plans` before any code; plan at `docs/redesign/proof/mobile-13/plan.md`.
2. `superpowers:test-driven-development` for every engine change and every pure helper (page turn, spreads, read-all window, OCR box conversion, bulk limiter).
3. `superpowers:subagent-driven-development` (or `superpowers:executing-plans` inline). At most 6 implementer subagents; one heavy command at a time; verify their work against `git status` and `git diff`, never against their reports.
4. `impeccable:impeccable` and `taste-skill:taste-skill` for the sheet, the panels and the paged stage; `frontend-design:frontend-design` only for the side-by-side review against the web twin's phone captures.
5. `superpowers:verification-before-completion` before claiming done.

## Scope: deliver every item below

### A. Skin-neutral engine work (`mobile/lib/features/reader/engine/`, no pixels first)

A1. **`setLayout(ReaderLayout layout, {ReadingDirection direction = ReadingDirection.ltr})`** with `ReaderLayout.strip | single | double` (glass §15.4). `single` and `double` render the chapter as a `PageView.builder` of screens (one page, or a spread), `reverse: direction == rtl`; switching layout keeps the current page. The strip path is untouched. Spreads: port `buildSpreads(pageCount, coverAlone: true)` and `spreadDisplayOrder` from `frontend/src/features/reader/spread.ts` into `engine/spread.dart` with its test cases, and extend both ports with the §8.14.7 rule that a wide page (manifest `width > height`) occupies a spread alone and pairing resumes after it. The mobile track never edits `frontend/`: if the web port still lacks the wide-page rule, name it in the report so `web/24` picks it up.
A2. **Page-turn hook** `turnTo(int page, {PageTurn kind, required Duration slideDuration, required Curve slideCurve, required Duration fadeDuration})` with `PageTurn.cut | slide | fade`: Cut is `jumpToPage` (0 ms); Slide animates the `PageController` over `slideDuration` along `slideCurve` with the incoming page pushing in from its reading side; Fade cross-fades over `fadeDuration` over a `jumpToPage`. The engine holds no skin value: the Cinematic reader passes `context.cine.durPageturn` (280 ms), `CineCurves.settle` and `context.cine.durBeat` (160 ms); Glass (`mobile/35`) passes its own. Swipes always track the finger whatever `kind` is set (the Slide physics below); `kind` applies to taps, keys, volume keys and the ruler.
A3. **Finger-tracked Slide.** `setLayout` takes an optional `ScrollPhysics? pagePhysics` from the skin (default `PageScrollPhysics()`), so the engine never imports a skin. The Cinematic skin passes `CinePagePhysics extends PageScrollPhysics` from `mobile/lib/skins/cinematic/screens/reader/cine_page_physics.dart` (Glass passes its own `GlassPagePhysics`, `mobile/35`), overriding `createBallisticSimulation`: a release commits to the neighbour when the drag passed 72 px or the velocity exceeds 600 px/s (§11), otherwise it returns; both settle with `SpringSimulation(CineSprings.release.description, position, target, velocity)` (504 ms, bounce 0). Double layout steps two pages (one spread). The skin-neutral pure decision `shouldCommitTurn(double dx, double vx, double width)` with RTL mirroring lives in `engine/page_turn.dart`, and `CinePagePhysics` calls it (+ `page_turn_test.dart`: 71 px no, 72 px yes, 599 px/s no, 600 px/s yes, RTL mirror, spread step).
A4. **Paged zoom**: each page sits in an `InteractiveViewer` (min 1.0, max 3.0) through `pinchZoom` / `zoomAt`; double tap 1× ⇄ 2× at the tap point in 240 ms `settle`; while a page is zoomed above 1.0 the `PageView` physics become `NeverScrollableScrollPhysics`, so drags pan and never turn pages.
A5. **Preload 3 pages ahead** in paged layouts through the engine's prefetch: the visible page and the next at P0, the rest at P3 in the sources limiter (§15.6).
A6. **Read-all feed**: a new engine mode for ScreenId `readAll` (the legacy `?all=1` hand-off stays for the legacy reader). Chapter 1, or `?from`, is streamed at once from its single manifest (`GET /reader/chapter/manifest`) while `POST /reader/chapters/manifest` fills a window of up to 20 chapter keys per request in series order; batch calls go through a sliding-window limiter of 6 starts per 60 s in `mobile/lib/core/network/bulk_limiter.dart` (+ test), and a 429 pauses it for `Retry-After`. Items with `status: "error"` become a retryable failed chapter inside the feed, never a failed feed. Engine state gains `readAll: ReadAllState(index, total, boundaries)` (the current chapter's position, for example 12 of 201, and the page offsets of the chapter boundaries in the loaded window). Tests for the window arithmetic, the partial-failure mapping and the limiter.
A7. **Per-page overlay slot** `pageOverlayBuilder(context, page, chapterKey, Size box)` drawn inside each page's positioned box (children placed in fractions of the box), so OCR outlines follow scroll and zoom in both layouts. OCR boxes from `GET /ocr/chapter` are fractions 0–1 with a top-left origin (`x`, `y`, `width`, `height`; use `left`, `top`, `right`, `bottom` when `x` / `y` are null): put the conversion in `mobile/lib/features/ocr/utils/ocr_boxes.dart` (+ test).
A8. **`pageAtReadingLine()`**: the page under 38 % of the viewport in the strip, the current page in paged layouts; used by the page-actions paths that are not a long-press.
A9. **Volume keys in paged layouts** (K08): volume down turns forward and volume up back by reading direction with the chosen page turn, haptic `page.turn`.

### B. Paged layouts (§8.14.7)

B1. Stage: the page fits by `fit` (`WIDTH │ HEIGHT │ ORIGINAL`) within the viewport minus 24 px, ground colour around (Black `#000000`, Ink `#0B0B0A`, Slate `#1A1A18`).
B2. Double: two pages with an 8 px ground gutter and a 1 px `rule.1` centre line; RTL mirrors display order; a wide page occupies both slots alone (A1).
B3. Page turns (`pageTurn`): `CUT` (default), `SLIDE` (280 ms `settle`; finger releases on `CineSprings.release`), `FADE` (160 ms). Haptic `page.turn` (`selection`), sound `turn` if on. Reduced motion: every turn is a 150 ms (`durReduced`) opacity cross-fade, and a finger release finishes with a 150 ms fade.
B4. Tap zones 30 / 40 / 30 % of the width, default previous / menu / next, mirrored for RTL until the user sets their own (`tapZones`). The first time a zone layout is used on this device, paint the zones as three labelled bands (`BACK · MENU · NEXT`, 1 px `ink.30` outlines, labels in `type.kicker`) that hold 1500 ms (`durHoldGlance`) and fade out over 1000 ms (`durFadeHint`); they reappear whenever the zone layout changes and on `Show zones` in the setup sheet. Remember the seen layouts in the device key `mm.reader.zones-seen` (a string list of `layout:left,centre,right`).
B5. Swipe: horizontal swipes turn pages by reading direction with the page tracking the finger (A3); touches that start within max(24 px, `MediaQuery.systemGestureInsetsOf(context).left` / `.right`) of either edge are ignored (§8.0.5); zoom above 1× pans instead. The iOS edge back is off in paged layouts (`canSwipe` false, §11 "disabled in paged readers").
B6. Chapter end: after the last page, one more screen holds `mobile/12`'s credits in full form (Coming up card and `Read chapter 143`) centred on the stage; turning past it opens the next chapter by Dip.
B7. Hardware keys in paged layouts: `→` / `d` and `←` / `a` turn by reading direction, `j` / `k` next / previous page, `Space` / `Shift+Space` next / previous page, `Home` / `End` first / last page; `w` / `v` / `r` switch to strip / single / right-to-left single. Auto-scroll is absent in paged layouts: its folio-bar button is not built and `p` does nothing.
B8. **The K01 migration toast** (§8.14.8 Direction row): the first time a reader opens after the `mobile/12` migration turned K01 `leftToRight` or `rightToLeft` into `SINGLE`, the toast "Sideways strips are now pages. Change it in Reading setup." shows once per device (device key `mm.reader.k01-toast-seen`).

### C. Read-all (`/read-all/:sourceId/:seriesKey?from&page&at`, ScreenId `readAll`)

C1. Route on the root navigator through `mobile/12`'s reader `SwipeablePage`; enters by the Column wipe from the feature page's `Read all` (check `mobile/11` passes `extra: {'entry': 'wipe'}`), by Dip from everywhere else; exits by Dip. Encoded builders from `contract.g.dart`.
C2. Continuous strip only: the Layout row and `w` / `v` / `r` are hidden and inert.
C3. Read-all divider between chapters: a 48 px band with `142 → 143` in `type.folio` between `rule.1` hairlines, no card and no pause; `scrub.boundary` when crossed (sound `tick`).
C4. Running head: the chapter folio adds `· 12 OF 201` (from A6; spoken "chapter 12 of 201").
C5. Ruler (§8.14.4): the track spans the chapters loaded in the read-all window; chapter boundaries are 2 px gaps in the track; while dragging, the folio flag reads `CH 143 · p. 7` because the app has no hover (record this reading of "shown on hover" in the report); `scrub.boundary` at each boundary crossed while dragging; `07 / 40` refers to the current chapter.
C6. Contents in read-all scrolls to the chapter (no Dip).
C7. States: the list failure notice ("This series' chapter list didn't come through, so there's nothing to read through." + `Try again` + `Go to the series`); a failed batch item shows the `CORRECTION` notice "Chapter 143 didn't load." + `Try again` + `Open it on its own →` in its place and reading continues past it; a 429 on the batch call shows the `SLOW DOWN` band with the live `Retry-After` countdown; offline reads saved chapters only and the first unsaved chapter shows "Next chapter isn't saved on this device" with `Back to Downloads`; the rest of §8.14.11 as in `mobile/12`.

### D. Reading setup (§8.14.8)

D1. Entry: the running-head settings button (`sliders-horizontal`, `bare`, tooltip "Reading setup"; inserted at its place in `mobile/12` F4's order: after bookmark and guided view, and on tablets after `note-pencil`) and `,` on a hardware keyboard (it reveals the chrome). A `CineSheetRoute` with detents `[0.5, 0.92]` on phones and tablets (max 720 wide and centred on tablets, §8.0.9), the page live above it at the half detent: `paper.2`, 1 px `rule.2` top edge, 32 × 3 `ink.30` grabber, 56 px header, Rise 360 ms `settle`, close 240 ms `lift`, drag release `CineSprings.sheet`, dismiss below 30 % or faster than 800 px/s, haptic `sheet.detent` on settle, sound `sheet` on open if on; Android back and iOS swipe-down close it.
D2. Header: kicker `READING SETUP`, title = the series title (`type.subhead`), `quiet` `Done`. Contents tabs `LAYOUT · IMAGE · CONTROLS · AMBIENT` (§7.12, Rule slide 320 ms). Every control states where it is saved in a `type.caption` `ink.60` line: "Saved for this series", "Saved for this profile", "Saved on this device" or "For this reading only".
D3. Every change applies live under the sheet; steppers roll their digits (Folio flip, 80 ms per digit, 40 ms apart, `CineCurves.set`); closing the sheet also hides the chrome. The sheet root sits in `CineStock.raised` (it paints `paper.2`), so `ink.45` roles render `ink.60`.
D4. Rows, exactly (values, defaults and scopes from §8.14.8; storage through `mobile/12`'s preferences record):

| Tab | Control | Options and range | Default | Saved |
|---|---|---|---|---|
| LAYOUT | Layout | `STRIP │ SINGLE │ DOUBLE` segmented (hidden in read-all; `GUIDED` is appended by `mobile/23`) | `STRIP` | per series |
| LAYOUT | Direction | `LEFT TO RIGHT │ RIGHT TO LEFT`, captions "Webtoons and western comics" / "Manga" | `LEFT TO RIGHT` | per series |
| LAYOUT | Fit | `WIDTH │ HEIGHT │ ORIGINAL`; Height and Original disabled in the strip with the tooltips "Fit to height works in the paged layouts." and "Original size works in the paged layouts." | `WIDTH` | per series |
| LAYOUT | Side margin (phones, width < 600) | `0 · 5 · 10 · 15 · 20 · 25 %` single-select slug line | `0 %` | per profile |
| LAYOUT | Strip width (tablets, width ≥ 600) | slider 480–860 px, step 20, value flag `640 PX` | 100 % up to 720 px until set | per device |
| LAYOUT | Zoom | stepper 50–300 %, step 10, with `Reset`; sets the series' resting zoom | 100 % | per series |
| LAYOUT | Gap between pages | switch (strip only), 8 px of ground | off | per profile |
| LAYOUT | Page turn | `CUT │ SLIDE │ FADE` (paged only) | `CUT` | per profile |
| IMAGE | Brightness | slider −75 … 0, step 1, caption "Dims below your screen's lowest setting." | 0 | per profile |
| IMAGE | Warmth | slider 0–100, step 1 | 0 | per profile |
| IMAGE | Colour | `NORMAL │ SEPIA │ GREY` | `NORMAL` | per profile |
| IMAGE | Ground | `BLACK │ INK │ SLATE` | `BLACK` | per profile |
| CONTROLS | Tap zones | three segmented rows `LEFT / CENTRE / RIGHT` × `PREVIOUS │ MENU │ NEXT`, `Reset`, `Show zones` | automatic: paged previous / menu / next (mirrored for RTL), strip menu everywhere | per profile |
| CONTROLS | Strip taps | `MENU │ TAP TO SCROLL` | `MENU` | per profile |
| CONTROLS | Swipe sideways to change chapter | switch | on | per profile |
| CONTROLS | Cinema mode | switch | off | per profile |
| CONTROLS | Keep screen awake | switch (K05) | off | per device |
| CONTROLS | Auto next chapter | switch | on | per profile |
| CONTROLS | Lock controls | switch (K07; the reader opens locked) | off | per device |
| CONTROLS | Volume keys turn pages | switch (K08), Android only | off | per device |
| CONTROLS | Refresh rate | `AUTO │ 30 │ 60 │ 90 │ 120` (K04 through `ReaderDisplayMode`), Android only | `AUTO` | per device |
| AMBIENT | Auto-scroll | play / pause (strip only; in paged layouts the row reads "Auto-scroll needs the strip.") | stopped | session |
| AMBIENT | Auto-scroll speed | the speed ruler 0.50–3.00× in 0.05 steps, labelled at 0.5, 1, 1.5, 2, 2.5, 3 (`type.folio`), value flag while dragging, commits on release, preset slugs `0.8 · 1 · 1.25 · 1.5 · 2`, touch-and-hold anywhere on it resets to 1.00×, the px/s equivalent under the value (`≈ 47 PX/S` from `autoScrollPxPerSecondX`), haptic `select` per 0.25× crossed | 1.00× | per series |

   The Fullscreen row is web-only and is not built. The other AMBIENT rows (Resume after I let go, Pace by dialogue, Soundscape, Soundscape volume, Page-tinted chrome, Guided view auto-advance) and the `GUIDED` layout are appended by `mobile/23`: keep the rows of each tab as an ordered list.
D5. `SpeedRuler` is its own widget in `mobile/lib/skins/cinematic/primitives/speed_ruler.dart` (`mobile/15` reuses it for Listen and `mobile/23` for the auto-scroll chip), with a widget test for the step, the presets and the hold-to-reset.
D6. Footer: a `quiet` `Reset reader settings` opening the §7.10 dialog "Restore every reader setting to its default?" whose destructive confirm arms for 1000 ms (a 2 px `proof` rule fills under it on `Curves.linear`; reduced motion shows it full at 1000 ms; a polite "Ready" announcement); on confirm every per-series, per-profile and per-device reader value returns to its default (haptic `delete.confirm`). On phones the footer also carries a `quiet` `Page actions for p. 18` button (the non-gesture path of section F). The desktop `Shortcuts` link is web-only.
D7. Semantics per the §7 contract: segmented controls and slug lines `Semantics(inMutuallyExclusiveGroup: true, checked: …)`; switches `Semantics(toggled: …, label: <row label>)`; sliders with values "Brightness minus 40", "Speed 1.25 times" and increase / decrease actions; switches fire `toggle.on` / `toggle.off`, segments `select`.

### E. Side panels on tablets (§8.14.12)

E1. Right, "Margins": the `note-pencil` button in the running head on tablets (width ≥ 600; tooltip "Margins"; right after `sidebar-simple`, `mobile/12` F4's order) and `]` on a hardware keyboard. A column panel over the page (it does not push the strip): 3 of the 8 columns (min 320), `paper.0`, 1 px `rule.1` inner edge, slides 320 ms `settle` in and 224 ms `lift` out; reduced motion fades in place in 150 ms. Only one side panel is open at a time on tablets (opening Margins closes Contents and the reverse, last opened wins); remembered per profile (`panels.right`, `lastOpened`). Contents tabs `NOTES · DIALOGUE · CIRCLE`. Phones have no Margins panel; their paths are the page actions (F).
E2. NOTES: this chapter's bookmarks (from `bookmarks_provider.dart`, filtered to the chapter) as rows `p. 12` folio + the note in `type.body` (or "No note" in `type.caption` `ink.45`); a tap scrolls to it; `Add a note to this page` (`quiet`) saves a bookmark on the page at the reading line and opens its note field (IME done saves through the bookmark outbox with `note`; the back gesture cancels); empty: "No bookmarks in this chapter yet." plus the same button.
E3. DIALOGUE: when `ocrChapterTextProvider` answers, the transcript as subtitle lines per page (a `p. 12` folio and the page's lines in `type.body`); a tap on a line scrolls there (400 ms `durGlide` `settle`; a jump under reduced motion) and pulses a 2 px `spot` frame around its bubble twice (480 ms each) through A7's overlay. A 404 or empty text: "Dialogue isn't indexed for this chapter." (`type.caption`), and for a downloaded chapter the hint `Scan it on your phone` that starts the scan of F3. Loading: a 24 px leader dial after 400 ms. Error: a `CORRECTION` line with `Try again`.
E4. CIRCLE: who in the circle read this chapter, from `GET /circle/series` through `circleSeriesProvider(sourceId, seriesKey)` in `mobile/lib/features/circle/providers/circle_providers.dart` (create `features/circle/repositories/circle_repository.dart`, `circle_repository_impl.dart` and the provider if they do not exist yet, minimal, for `mobile/22` to extend). Each row: a 20 px avatar, the member's name in `type.ui`, and their reaction on this chapter as its label in `type.kicker` (`LOVED`, `SHOOK`, `LAUGHED`, `TEARS`, `CHEF'S KISS`, `HYPE`, `WRECKED`; `mobile/22` swaps in the stamp glyphs). Spoiler guard: while the viewer has not finished the open chapter, a reaction on it or on any later chapter shows only the 20 px avatar and "reacted to Ch. 142" in `type.caption` `ink.45`, never the label; reactions on finished chapters show in full; members further on read "Riya is on Ch. 150" with no detail. When `chapterCompleted` fires, guarded rows unseal (the label fades in over 160 ms `settle`, 40 ms after the previous one). A 404 (Circle not deployed) removes the tab; no members: "Nobody in your circle has read this yet."

### F. Page actions (§8.14.13)

F1. Opened by a 450 ms long-press on a page (a `LongPressGestureRecognizer(duration: Duration(milliseconds: 450))` on the page layer, which yields to scrolling once the finger moves past the 8 px slop; haptic `longpress.open` = `heavy`), by the phone setup-sheet footer button (D6, the page at the reading line), by a `dots-three` "Page actions" button appended last to the running head's trailing list on tablets, and by the context-menu key or `Shift+F10` on a hardware keyboard.
F2. A `CineSheetRoute` with detents `[0.5, 0.92]` (phones and tablets), kicker `PAGE 18`.
F3. Items: `Bookmark this spot` (then its note field); `Show dialogue on this page` (overlays that page's OCR boxes as 1 px `spot` outlines through A7; tapping a box shows its recognised text in a small `paper.2` popover in `type.body`; absent when the chapter has no OCR text); `Retry this page`; `Open page image` (the §7.30 Lightbox from `primitives/lightbox.dart` with this page: `Hero` from the page box, pinch 1–4×, double tap 1× ⇄ 2.5× at the point in 240 ms `settle`, drag down at 1× to dismiss back into its box (past 120 px or 800 px/s, `CineSprings.release`), caption `PAGE 18 · 800 × 12400` on the folio-flag ground, `x` close with a 320 ms reverse match cut `CineCurves.turn`; reduced motion 150 ms fades); `Scan this chapter's dialogue` (app only, shown for chapters saved on the device: starts the existing `OcrRunController` for this chapter, whose progress shows in Downloads per §8.23; the item then reads `SCANNING 4 OF 40` and is disabled). `React to this chapter` is `mobile/22`.

### G. Keys added in this step (the "Reader" group)

`,` (Reading setup, reveals the chrome), `]` (Margins panel on tablets, reveals the chrome), `w` / `v` / `r` (strip / single / right-to-left single; inert in read-all), the paged keys of B7, the context-menu key and `Shift+F10` (page actions for the page at the reading line). The escape order: close the Lightbox, then a sheet or panel → leave cinema → exit to the series page. Update `reader_keys.dart` and its test.

### H. Gestures (§8.14.10, §11): every reader row `mobile/12` did not finish

Tap zones in paged layouts (B4); double tap in paged layouts (A4); pinch in paged layouts (A4); horizontal swipe in paged layouts (B5); long-press 450 ms on a page (F1); volume keys in paged layouts (A9); drag on the setup sliders and the speed ruler (`CineSprings.scrub` release, `select` per step); swipe down on the sheet (D1). Each keeps its §11 non-gesture alternative.

### I. States (every one, in both paged layouts and in read-all)

Loading a chapter in paged layouts: one galley page plate at the manifest aspect centred on the stage with `LOADING CH 142` in the running head and a 24 px leader dial after 400 ms. Broken page on the stage: kicker `PAGE 18 DIDN'T LOAD`, `quiet` `Retry`, the reason in `type.caption`. No pages, error, offline, rate limited, the 18+ rating card and not available: as `mobile/12`, also on the paged stage and in read-all. Setup sheet: every disabled control has its tooltip; the Android-only rows are absent on iOS. Margins: the NOTES, DIALOGUE and CIRCLE states of E2 to E4. Page actions: `Show dialogue on this page` absent without OCR text, `Scan this chapter's dialogue` absent for chapters not saved on the device.

## Out of scope here (owned by later steps)

- `mobile/19`: the `PREVIOUSLY ON` chip. `mobile/22`: reaction stamps, `React to this chapter`, `Recommend this series…`, unseal inside the credits.
- `mobile/23`: `GUIDED` and `u`, page-tinted chrome, soundscape rows and indicator, pace by dialogue, resume after release, the auto-scroll chip, guided-view auto-advance.
- `mobile/18`: Settings → Reading: manga (the profile defaults screen) using the same preferences record.

## File layout

```
mobile/lib/features/reader/engine/spread.dart (+ test)          A1
mobile/lib/features/reader/engine/page_turn.dart (+ test)       A2, A3 (turnTo, shouldCommitTurn)
mobile/lib/skins/cinematic/screens/reader/cine_page_physics.dart   A3 (CinePagePhysics, Cinematic only; + widget test)
mobile/lib/features/reader/engine/<engine files>                A1–A9 (setLayout, PageView, read-all mode, overlay slot, pageAtReadingLine)
mobile/lib/features/reader/engine/read_all_window.dart (+ test) A6
mobile/lib/core/network/bulk_limiter.dart (+ test)              A6
mobile/lib/features/ocr/utils/ocr_boxes.dart (+ test)           A7
mobile/lib/features/circle/repositories/circle_repository.dart, circle_repository_impl.dart, providers/circle_providers.dart   E4 (only if absent)
mobile/lib/skins/cinematic/primitives/speed_ruler.dart (+ test) D5
mobile/lib/skins/cinematic/screens/reader/
  read_all_screen.dart      C (ScreenId readAll)
  paged_stage.dart          B1–B6
  tap_zone_bands.dart       B4
  read_all_divider.dart     C3
  reading_setup_sheet.dart  D1–D7
  setup_rows.dart           the ordered row lists per tab (mobile/23 appends AMBIENT rows)
  margins_panel.dart        E1
  notes_tab.dart, dialogue_tab.dart, circle_tab.dart           E2–E4
  page_actions_sheet.dart   F
  ocr_overlay.dart          the A7 overlay content (frames, outlines, pulse, popover)
  (extend) manga_reader.dart, running_head.dart, folio_bar.dart, ruler.dart, side_panel_layout.dart, reader_keys.dart, reader_gestures.dart
mobile/lib/skins/cinematic/router.dart                          readAll route, remove readAll from PENDING
mobile/test/skins/cinematic/reader/                             widget tests
docs/redesign/proof/mobile-13/                                  plan.md, screenshots, device-checklist.md, report.md
```

## Acceptance criteria

- [ ] `readAll` is removed from the Cinematic `PENDING` set; the completeness and import-boundary tests pass.
- [ ] `setLayout` renders single and double in a `PageView` with the 24 px stage inset, the 8 px gutter and the 1 px `rule.1` centre line; RTL mirrors display order; the cover stands alone and a wide page occupies both slots (`spread_test.dart`); `w`, `v`, `r` switch layouts; the strip path is byte-for-byte unchanged in behaviour (every `mobile/12` and legacy reader test still passes).
- [ ] Cut, Slide (280 ms `settle`, finger-tracked, committing at 72 px or 600 px/s, settling on the 504 ms release spring) and Fade (160 ms) work; the motion-timings overlay logs each turn; reduced motion turns with a 150 ms cross-fade.
- [ ] Tap zones: 30 / 40 / 30, mirrored for RTL, labelled bands on first use (1500 ms hold, 1000 ms fade) and on `Show zones`; paged zoom 1–3× with double tap 1× ⇄ 2× and no page turn while zoomed; volume keys turn pages when K08 is on (Android).
- [ ] The K01 toast shows once per device after the migration and never again.
- [ ] The paged chapter end shows the credits screen, and turning past it opens the next chapter by Dip.
- [ ] Read-all opens from the feature page's `Read all` with the Column wipe, shows the first chapter before any batch returns, shows `· 12 OF 201`, the 48 px `142 → 143` divider and ruler gaps; a failed batch item shows its inline notice and reading continues; the list-failure copy is exact; the bulk limiter never starts a seventh batch inside 60 s.
- [ ] Reading setup: every row of D4 is present with its range, default, scope caption and live effect; Height and Original are disabled in the strip with their tooltips; the Android-only rows are absent on iOS; `Reset reader settings` arms for 1000 ms; the sheet opens at the half detent with the page live above it and closes on Android back and on swipe-down.
- [ ] Margins on 834 × 1194: NOTES lists this chapter's bookmarks and saves a note; DIALOGUE pulses the tapped line's bubble twice; CIRCLE shows guarded rows as "reacted to Ch. 142" and unseals them in 160 ms when the chapter completes; the tab is absent when `/circle/series` answers 404; opening Margins closes Contents.
- [ ] Page actions open by long-press, by the phone setup footer, by the tablet `dots-three` and by `Shift+F10`; `Open page image` opens the Lightbox and returns into the page's box; `Scan this chapter's dialogue` starts the OCR run for a saved chapter.
- [ ] Hardware keyboard: every key in G and in B7 works in a widget test in all three layouts and in read-all; the escape order is exact.
- [ ] Hit targets: every control in the sheet, the panels and the page-actions sheet is ≥ 44 × 44 under `TargetPlatform.iOS` and ≥ 48 × 48 under `TargetPlatform.android` (widget test).
- [ ] Reduced motion: panel slides become 150 ms fades, the sheet Rise a 150 ms fade, page turns 150 ms fades, transcript scrolls jump, the Lightbox fades; leader dials keep running.
- [ ] Per-skin difference: with `Edition (debug)` on `LEGACY`, the legacy reader's LTR and RTL continuous strips and its settings sheet behave exactly as before and still read and write K01–K12.
- [ ] `flutter analyze` reports no issues; `flutter test` passes at or above the floor plus the new tests.

## Verification

**RAM guard.** Before every heavy command run `free -m`; if the `available` figure of the `Mem:` row is under 1024 MB, stop and report. One heavy command at a time; never alongside a `next build`; no Gradle or Xcode on this box.

From `mobile/`:

```bash
free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze
free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter test test/features/reader test/features/ocr test/core test/skins
free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter test
```

`flutter analyze` reports "No issues found"; the full suite passes at or above the floor. This step changes nothing in `frontend/` or `backend/` (`git show --name-only --format= <hash> -- frontend backend` for each of your own commits (never a branch or range diff: parallel sessions commit on the same branch) is empty), so `npm run lint`, `npm run build` (in `frontend/`) and the backend pytest (`backend/.venv/bin/python -m pytest -q --no-header` from `backend/`) are not rerun, except the push rule under Git.

**Proof output location.** The `mobile/03` harness (`mobile/test/screenshots/support/skin_shots.dart`) writes a capture only when `MM_PROOF_DIR` is set, so every proof command below sets `MM_PROOF_DIR=../docs/redesign/proof/mobile-13` (relative to `mobile/`) and never `MM_WRITE_SHOTS`, which makes the legacy marketing tests overwrite `mobile/docs/screenshots/`, the install page's public screenshots. Capture routes with `captureSkinScreen` and anything that is not a route (a sheet held open, a state pumped with fixture providers) with `captureSkinWidget`, at the harness sizes: `kSkinShotSizes` (phone 390 × 844, tablet 834 × 1194), `kSkinShotTabletWide` (1024 × 1366, the ≥ 900 px rows of §8.0.9) and `kSkinShotLandscape` (landscape phone 844 × 390). After the run, `git status --short mobile/docs/screenshots` must print nothing.

**Visual proof.** In the harness `mobile/03` extended (`grep -rln "docs/redesign/proof" mobile/test/screenshots`), add a `mobile-13` group over the demo pages `brand/demo/pages/*.webp` with `brand/demo/demo.json` (its `panels` and `bubbles` boxes give a realistic OCR fixture; store it as `mobile/test/fixtures/ocr/chapter.json`) and a fixture for `GET /circle/series` when the endpoint has no data. Run `free -m && MM_PROOF_DIR=../docs/redesign/proof/mobile-13 /srv/manhwamaniacs/dev/flutter/bin/flutter test test/screenshots/marketing_screenshots_test.dart --plain-name "mobile-13"` at phone 390 × 844, tablet 834 × 1194 and landscape phone 844 × 390, into `docs/redesign/proof/mobile-13/`:

- `paged-single-{phone,tablet}.png`, `paged-double-tablet.png`, `paged-double-rtl-tablet.png`, `paged-zone-bands-phone.png`, `paged-slide-midturn-phone.png` (pumped mid-drag), `paged-credits-screen-phone.png`, `paged-zoomed-phone.png`, `k01-toast-phone.png`.
- `readall-{phone,tablet}.png` (with `· 12 OF 201`), `readall-divider-phone.png`, `readall-ruler-drag-phone.png` (flag `CH 143 · p. 7`), `readall-chapter-failed-phone.png`, `readall-list-failed-phone.png`.
- `setup-{layout,image,controls,ambient}-phone.png`, `setup-controls-tablet.png`, `setup-reset-arming-phone.png`, `setup-controls-ios-phone.png` (no Android-only rows).
- `margins-notes-tablet.png`, `margins-dialogue-tablet.png`, `margins-circle-guarded-tablet.png`.
- `page-actions-sheet-phone.png`, `page-dialogue-outlines-phone.png`, `page-lightbox-phone.png`.
- `entry-follow-readall-phone.png`, `entry-source-readall-phone.png`, `entry-follow-paged-phone.png`, `entry-source-paged-phone.png`.
- `reduced-motion-paged-phone.png`, `legacy-horizontal-strip-phone.png`.
- Compare the phone captures with `docs/redesign/proof/web-13/*-phone.png` when present and list differences in the report.
- `docs/redesign/proof/mobile-13/device-checklist.md` for the owner (iPhone via SideStore, Android flagship): finger-tracked Slide at 120 Hz with 0 dropped frames, the 504 ms release, Fade and Cut, RTL double spreads on a tablet, the zone bands, read-all through a chapter boundary at 120 Hz, the setup sheet's live preview at the half detent, the refresh-rate row on Android taking effect (Diagnostics display mode), volume keys in paged layouts, the long-press page actions sheet with its `heavy` haptic, `Scan this chapter's dialogue` on a saved chapter.
- `docs/redesign/proof/mobile-13/report.md` mapping each screenshot to its acceptance item.

## Git

- Branch `feat/vps-slim-source-native`; small commits (each engine change with its test, then paged, the K01 toast, read-all, the setup sheet, the panels, page actions, the proof). Stage paths explicitly, never `git add -A` or `git add .`.
- No Claude or AI attribution anywhere (no `Co-Authored-By`, no "Generated with", no AI author); never commit secrets or `.claude/`.
- Before every push: `git fetch origin` and `git diff --stat origin/feat/vps-slim-source-native...HEAD -- frontend`; if it lists files, run `free -m && npm run build` in `frontend/` first (never while `flutter test` runs) and push only if it passes. Then `git push origin feat/vps-slim-source-native:master` after each working step.
- Never edit `backend/connectors/`; never touch production containers or `/srv/manhwamaniacs/{app,data}`; do not deploy.

## Report back

1. Done items by scope letter A–I, and anything not done with the reason.
2. The screenshot folder `docs/redesign/proof/mobile-13/` and its file list; differences against the web twin.
3. Test counts (`flutter test` passed before and after), `flutter analyze` result, `free -m` before each heavy command.
4. Engine API added with exact Dart names (`setLayout` with its `pagePhysics` input, `turnTo`, `shouldCommitTurn`, the skin's `CinePagePhysics` path, `pageOverlayBuilder`, `pageAtReadingLine`, `ReadAllState`, the bulk limiter) for `mobile/23` and the Glass reader (`mobile/34`, `mobile/35`).
5. The CIRCLE endpoint status on the dev stack (live data or fixture), and whether `features/circle/` was created here.
6. The owner device checklist path.
7. Interpretations made (the read-all drag flag, one panel at a time on tablets) and every place where `cinematic/DESIGN.md` overrode this file.

Next prompt: `docs/redesign/prompts/mobile/14-cinematic-novel-reader.md`.
