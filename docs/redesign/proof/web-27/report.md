# web/27 report

Glass primitives 2 (overlays and controls), items A to N. Where this prompt and `glass/DESIGN.md` differ, DESIGN.md was followed; no conflict needed a deviation except the ones listed at the end.

## Verification
- `npm run typecheck`, `npm run lint` (0 errors, 0 warnings), `npm run test` (229 files, 3225 tests), `npm run build` (0 errors; the three Turbopack font-override warnings are pre-existing), `node design/build.mjs --check` (exit 0, only the pre-existing sound-intake warnings).
- `e2e/glass-overlays.spec.ts` (17 tests) and `e2e/glass-primitives.spec.ts` (7 tests, the web/26 spec) all pass against `next dev`.
- Vitest files: `sheet-physics.test.ts`, `pull-physics.test.ts`, `slider-math.test.ts`, `overlay-queue.test.ts` (plus `scroll-edge-math`, `viewer-math`, `useSheetParam`).
- Nothing under `frontend/src/skins/cinematic/`, `mobile/` or `backend/` changed.

## Screenshots to acceptance items
Sections (`<section>-desktop|phone|solid-desktop|contrast-desktop.png`, twelve sections) prove: every component and state present and in the gallery; Solid glass recipe and hard edges (`-solid-`); Increase contrast (`-contrast-`).
- `sheet-medium-phone`, `sheet-large-recession-phone`, `sheet-stacked-phone`, `sheet-rubberband-phone`: sheet detents, recession at large, stacked rules, 60 px rubber band.
- `panel-desktop`, `window-desktop`, `detail-window-desktop`, `offer-popover-desktop`: desktop forms.
- `alert-from-source-desktop` (mid-bloom), `alert-error-phone`: alerts.
- `toasts-stacked-phone`, `toast-undo-rim-desktop`: toast stack and draining rim.
- `menu-bloom-desktop` (mid-bloom), `context-lift-phone`: menus and the lift over `dimContext`.
- `image-viewer-zoomed-phone`, `image-viewer-dismiss-drag-phone`: viewer.
- `pull-droplet-60px-phone`, `pull-snapped-phone`: droplet and snapped meniscus.
- `scrub-lens-phone`, `speed-dial-phone`: scrub lens and speed dial.
`capture.mjs` regenerates them against `next dev -p 3033`.

## Not proven here
- Motion-timings "no dropped frames" on real hardware: the gallery logs Bloom, Sheet present, Sheet snap, Recede, Toast fall, Meniscus refresh, Scrub lens and Zoom, but headless software raster cannot vouch for frame pacing; listed in `owner-todo.md`.
- Pull-to-refresh, pinch and double-tap are covered by unit maths and the screenshots; the browser spec drives `refresh()` and keyboard paths, not a multi-touch pinch.

## Deviations from the prompt
- Base UI `Menu.Trigger` cannot drive our `Button` (it does not forward Base UI's injected props), so `Menu` wraps its trigger in a `display: contents` span that owns click, aria-haspopup and aria-expanded, and returns focus on close.
- Base UI's modal Dialog did not keep Tab inside the sheet, alert or viewer in this setup, so `trapTab` (overlay-utils) wraps focus on the popup's keydown.
- `ContentModeSwitch` also exports `ContentModeSwitchView` (state passed in) so the gallery shows the switch without the bootstrap query.

## Fix pass 1: measured figures

Software-rasterised headless Chromium (no GPU), so drop counts are an upper bound and hardware figures stay an owner item (owner-todo.md). Script: `docs/redesign/proof/web-27/moves.mjs` (reads `window.__glassMoves()`, a dev-only hook in `motion-recorder.ts`). Frames / dropped are summed over all runs of the move.

| Move | 1440x900 runs, frames, dropped | 390x844 runs, frames, dropped |
|---|---|---|
| Bloom | 2, 40, 13 | 2, 65, 4 |
| Sheet present | 2, 3, 2 | 4, 35, 11 |
| Sheet snap | phone-only | 1, 13, 8 |
| Recede | phone-only | 4, 45, 11 |
| Toast fall | 1, 13, 3 | 1, 24, 0 |
| Meniscus refresh | touch-only | 1, 55, 0 |
| Scrub lens | 1, 1, 1 (100 ms move) | 1, 1, 1 (31 ms move) |
| Zoom | 3, 97, 11 | 3, 132, 0 |

Every move that drops here does so under software raster only (desktop drops are larger because 1440x900 is rasterised on the CPU); the phone size drops none for Toast fall, Meniscus refresh and Zoom. No move exceeds its planned time by a frame except through those drops.

## Live glass budget (report-back item 5)

Measured in `e2e/glass-overlays.spec.ts` ("budget") through the dev hook `window.__glassBudget()` at 390x844: the gallery wraps its specimens and portals in an exempt scope, so overlay glass is counted as growth of glass + exempt after opening. Sheet with a toast requested: +1 live glass surface (toast is held under an open sheet; scrims are not counted). Menu open: +1. Both are at or under the limit of 5. The stacked-layer rule (a third overlapping layer forces the lowest solid) is covered by `budget.test.ts` ("forces the lowest layer solid under two overlapping higher layers"). The gallery has no dock or nav row, so the full 5-surface phone case is an integration check for the screens step.

## Fix pass 1: haptics and other notes

- Sheet haptics are now asserted with touch input at 390x844: `sheet.pass` (slow drag across a detent), `sheet.detent` (settle), `threshold.cross` then `threshold.back`, `sheet.dismiss`.
- `.g-sheet-d__slab` no longer has the inset hairline: detailWindow has no specular rim.
- The three Turbopack build warnings (font override values for Atkinson Hyperlegible Next, Google Sans Code, Google Sans Flex) are inherited from the merged trunk fonts (`skins/glass/fonts.ts`, `skins/cinematic/reading-fonts.ts`), not caused by web/27; they belong to the fonts owner's lane.
