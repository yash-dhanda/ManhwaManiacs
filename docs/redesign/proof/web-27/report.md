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
