# web/26 report

Screenshots (`<section>` in buttons, hold, icon-buttons, inputs, search, chips, segmented, cards, posters, rails, skeletons, progress, badges, avatars, tooltips, reveals, cursors):

| File | Proves |
|---|---|
| `<section>-desktop.png`, `<section>-phone.png` | every primitive with every state over black, ambient and white; 44 px targets at 390 wide |
| `<section>-solid-desktop.png` | Solid glass recipe per section (no caustic or sweep) |
| `<section>-contrast-desktop.png` | Increase contrast |
| `reveals-typing-200ms-desktop.png` | typing still running 200 ms after navigation |
| `reveals-rails-running-desktop.png` | rail headers waiting/running, at most two at once |
| `hold-aborted-desktop.png` | aborted hold, helper line showing |
| `poster-lift-phone.png` | poster lifted at 450 ms of a press |

Playwright: `glass-reveals.spec.ts` 6 tests and `glass-primitives.spec.ts` 5 tests pass against `next dev` on :3033.
Deviations: `glass/DESIGN.md` wins where the prompt differs; the grid columns (6 at 1440, 8 at 1920) hold with the expanded sidebar.
