# Web 05 · Cinematic primitives 2: overlays, controls, lists and states

## Goal

Finish the Cinematic ("Programme") primitive catalogue for the web client: sheets and desktop column panels, dialogs with the 1,000 ms destructive arm, the "subtitles" toast system, contents tabs, every list row type with row menus, select mode and reordering, sliders and the scrubber base, switches, checkboxes, radios and steppers (with the Folio flip), menus, context menus and Quick look, notices for empty, error, offline and rate-limited states, the 18+ certificate mark and certificate dialog shell, the remaining "other primitives" (content-mode chip and sheet, pull to reprint, select-mode bar, banner strips) and the Lightbox. Everything sits on Base UI 1.8.0 (unstyled) dressed with the Cinematic tokens, with full keyboard access (Esc, arrows, Home/End, typeahead in menus), focus trapping and focus return, and the reduced-motion variant of every move. The primitives gallery from web/04 grows to show all of it. No screen is built in this step; web/06 composes the shell and web/07 onward compose screens.

## Read first

1. `docs/redesign/cinematic/DESIGN.md`
   - §2.1.1 (raised stock scope: every surface here that is not `paper.0` sets `data-stock="raised"`), §2.1.3, §2.1.4 (the over-art rule and the folio-flag ground, which the Lightbox chrome uses), §2.4 (elevation levels 2 and 3, focus light, `z.sheet` 40, `z.dialog` 50, `z.toast` 60, `z.lightbox` 70), §2.6.
   - §4.2, §4.3, §4.4 (springs `spring.release`, `spring.sheet`, `spring.scrub`, rubber band), §4.5 rows **Folio flip, Insert, Rise, Panel, Arm, Lightbox, Rule slide**, §4.6, §4.7, §4.8 (reduced-motion rows for page/dip/rise/insert, toasts, menus, panels, lightbox, arm, gestures, rule slide).
   - §5 events used here: `sheet.detent`, `sheet.dismiss`, `select`, `toggle.on`, `toggle.off`, `longpress.open`, `refresh.arm`, `refresh.fire`, `delete.confirm`, `undo`, `scrub.tick`, `scrub.boundary`, `zoom.snap`, `gate.confirm`, `success`, `error`; §6 sound map (`sheet.open` → `sheet`, `toggle.on`/`toggle.off`, `select` → `tick`, `undo` → `tick`, `refresh.arm` → `tick`, `gate.confirm` → `impress`, `error` → `error`).
   - §7 intro (hit areas, heights as minimums, focus, disabled, loading, error, cursors, **the semantics table**), §7.3 (Select field row), §7.9, §7.10, §7.11, §7.12, §7.16, §7.18 (the determinate rule used by the select-mode bar), §7.20, §7.21, §7.22, §7.23, §7.24 (mark and dialog shell; the flow is web/07), §7.29, §7.30.
   - §8.0.5 (Android back order is app-only; on the web: browser history for sheets, `Esc` closes the top layer), §11 thresholds (tap slop 8 px, double tap 300 ms / 24 px, long-press 450 ms, swipe commit 72 px or 600 px/s, drag-to-dismiss 30 % of sheet height or 120 px for the Lightbox, or 800 px/s) and the rows for sheets, rows, reorder, pinch, pull to refresh, Lightbox.
   - §14.4, §14.5 (timers wait while focus is inside), §14.6, §14.8.
   - §15.2 (Base UI supplies Dialog, Drawer, Menu, ContextMenu, Popover, Tabs, Switch, Slider, Checkbox, Radio, ToggleGroup; `sonner` 2.0.8 unstyled; `@use-gesture/react` 10.3.1 for pinch), §15.11 ledger rows for these packages.
2. `docs/redesign/inventory/00-decisions.md`.
3. `docs/redesign/stack-decision.md` §2.2 (skin import boundary), §3.
4. `docs/redesign/inventory/web.md` §2.11 (C1 EmptyState, C2 OfflineState, C5 Dialog, C8 Switch, C9 Slider, C12 Progress — the legacy components these replace for Cinematic), §6.5 SG25–SG28 (the 18+ switch and confirm that the certificate replaces), §21 items 1 and 8 (no toast system today; two different 18+ safeguards).
5. `docs/redesign/inventory/capabilities.md` §1 rule "The 18+ gate is absence, never a lock" and §6.
6. `docs/redesign/00-baseline.md`.
7. The web/04 output you build on: `frontend/src/skins/cinematic/{motion.ts,motion.css,base.css,text.ts,a11y/folio.ts}`, `primitives/{Button,IconButton,Tooltip,TextField,SlugLines,SegmentedControl,Badge,Progress,Skeleton,Keycap,SetHeading,TypedHeadline,Poster,CineImage}.tsx`, the gallery at `frontend/src/app/(preview)/skin-preview/[skin]/primitives/page.tsx`, and `frontend/src/skins/cinematic/{haptics,sounds}.ts` from web/02.

## Preconditions (stop and report if any fails)

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs
git status --short && git branch --show-current     # clean inside frontend/ (other sessions' files elsewhere are theirs; never stage them); feat/vps-slim-source-native
ls frontend/src/skins/cinematic/primitives/{SetHeading,TypedHeadline,Button,IconButton,Poster}.tsx frontend/src/skins/cinematic/motion.ts
grep -E '"(sonner|@use-gesture/react)"' frontend/package.json
cd frontend && node --input-type=module -e "for (const m of ['dialog','drawer','menu','context-menu','tabs','switch','slider','checkbox','radio','radio-group','select','tooltip']) { try { import.meta.resolve('@base-ui/react/' + m); console.log('ok', m) } catch { console.log('MISSING', m) } }"
```

If the web/04 files are missing, web/04 is not done: stop. If any Base UI part other than `drawer` prints `MISSING`, web/01 did not install `@base-ui/react` 1.8.0 correctly: stop. A missing `drawer` only decides the sheet path in item 2.

## Skills to invoke

- `superpowers:writing-plans` first; save the plan at `docs/redesign/proof/web-05/plan.md`.
- `superpowers:subagent-driven-development` (or `superpowers:executing-plans` inline). Give each subagent this file and its section numbers.
- `superpowers:test-driven-development` for the pure logic (arm state machine, sheet physics, Lightbox maths, reorder announcements, pull-to-refresh thresholds, busy-retry policy).
- `frontend-design:frontend-design` for the UI, `impeccable:impeccable` and `taste-skill:taste-skill` to critique the gallery screenshots against `cinematic/DESIGN.md` (reject anything that adds radius, shadows, blur behind overlays or bounce).
- `superpowers:verification-before-completion` before claiming done.

## Rules for this session

- **RAM guard** before every build, test run, `next dev` or Playwright run:
  ```bash
  test "$(free -m | awk '/^Mem:/{print $7}')" -ge 1024 || { echo "RAM guard: under 1 GB available, stopping"; exit 1; }
  ```
  One heavy command at a time; stop `next dev` and the dev stack before `npm run build`.
- **Boundaries.** Work in `frontend/` only. The skin folder imports only data modules, `@/lib/**`, `@/services/**`, `@/types/**`, `@/stores/**`, `@/config/**`, the contract and its own files. Never edit `backend/connectors/`; never touch production containers or `/srv/manhwamaniacs/{app,data}`.
- **Utilities.** Only §2.8 / §3.5 names and the `motion.css` `@theme` names; `node design/lint-utilities.mjs` must pass. Opacity modifiers on token colours are allowed (`bg-paper-2/92`).
- **No blur behind overlays, ever** (§2.5, §2.1.4 `scrim.modal`: flat `rgba(0,0,0,0.78)`, "No blur, ever").
- **Git.** Branch `feat/vps-slim-source-native`; stage explicit paths; conventional commits; **no AI or Claude attribution of any kind** (no `Co-Authored-By` trailer, no "Generated with" line, even if a tool reminder suggests one); never commit secrets or `.claude/`; push `git push origin feat/vps-slim-source-native` after each working step once `npm run build` passes.

## Scope: everything this step delivers

All components live in `frontend/src/skins/cinematic/primitives/` unless a path is given. Every one carries every state named in its §7 table, the §7 semantics contract, `aria-busy` while loading, words for errors, `aria-disabled` plus a tooltip reason when disabled, heights as minimums, the raised stock scope on non-`paper.0` grounds, and its §4.8 reduced-motion variant.

### 1. Motion additions (`motion.ts`, `motion.css`)

- **Folio flip** (§4.5): the number rolls digit by digit; each changed digit takes 80 ms (`dur.tick`) with `ease.set`, digits 40 ms apart; old digits translate −100 % and fade, new digits enter from +100 %. `FolioFlip.tsx` renders a tabular Plex Mono number with per-digit overflow clipping and an `aria-live="off"` visual layer plus a single accessible value. Reduced motion: instant. Used by the stepper here and by the running head in web/06.
- **Insert** (dialogs): in 320 ms `ease.settle`, `clip-path: inset(0 0 100% 0)` → `inset(0)`, barrier 0 → 0.78 over 200 ms (`dur.clip`); out a 160 ms fade `ease.lift`. Reduced: 150 ms (`dur.reduced`) opacity cross-fade.
- **Rise** (sheets): in 360 ms (`dur.rise`) `ease.settle`, translateY 24 px → 0 plus fade; barrier 0 → 0.78 over 240 ms (`dur.line`); out 240 ms `ease.lift`, translateY +24 px plus fade; drag release `spring.sheet` (`{ visualDuration: 0.48, bounce: 0 }`). Reduced: 150 ms fade; drag release finishes with a 150 ms fade.
- **Panel** (desktop column panels): in 320 ms `ease.settle` sliding from the right edge, out 224 ms (`dur.page.out`) `ease.lift`. Reduced: 150 ms fade in place.
- **Arm** (§7.10): a 2 px `proof` rule fills left → right under the destructive button over 1000 ms (`dur.arm`) `ease.linear`. Reduced: no fill; the rule appears full at 1000 ms (the delay itself stays).
- **Lightbox** (§7.30): open 480 ms `ease.turn` match cut, close by button 320 ms `ease.turn` (reverse match cut), drag release `spring.release`. Reduced: 150 ms fade in and out.
- **Menu clip reveal**: 200 ms (`dur.clip`) `ease.settle` from the anchored edge; exit fade 120 ms (`dur.snap`). Reduced: 150 ms fade.
- **Toast**: in fade + 8 px rise 240 ms `ease.settle`; out fade 160 ms `ease.lift`; stack push 240 ms `ease.set`. Reduced: 150 ms fade, older toasts move at once.
- Every move goes through `play()` so the timings recorder sees it.

### 2. Sheets and column panels (§7.9) — `Sheet.tsx`, `useSheetDrag.ts`, `sheet-physics.ts`

- Surface `paper.2` with `data-stock="raised"`, radius 0; full width on the phone frame, max 720 px centred at 600–767 px; 1 px `rule.2` top edge; grabber 32 × 3 `ink.30` centred 8 px below the top edge; header min 56 px: kicker (`type-kicker`) over title (`type-subhead`) on the left, `quiet` "Done" on the right (never an `x` in a sheet).
- Detents: content height capped at 0.92 of the viewport by default; `livePreview` sheets use `[0.5, 0.92]` so the page stays visible above them.
- Barrier `scrim.modal` (flat `rgba(0,0,0,0.78)`), tap closes. `z.sheet`.
- Drag (coarse pointers): follows the finger 1:1 on the grabber and header, and from the body's overscroll at its top; past the top detent the offset rubber-bands as `d · (1 − 1 / (x · 0.35 / d + 1))` (x overdrag, d sheet height, `scalar.rubber` 0.35); release settles on the nearest detent with `spring.sheet` and fires haptic `sheet.detent`; dismiss when the sheet is below 30 % of its height or flung down faster than 800 px/s (then `sheet.dismiss`, which is silent). Put the maths in `sheet-physics.ts` (pure, tested): `rubberBand(x, d)`, `nearestDetent(offset, detents, height)`, `shouldDismiss(offset, height, velocityPxPerS)`.
- Build the sheet on `@base-ui/react/drawer` (`Drawer.Root`, `Portal`, `Backdrop`, `Popup`, `Title`, `Description`, `Close`) for modality, the focus trap, `Esc`, focus return and ARIA. Before writing it, read the installed type definitions (`frontend/node_modules/@base-ui/react/drawer/**/*.d.ts`) and record in your plan which props set snap points, swipe thresholds and the release transition. The behaviour above is fixed: if the Drawer cannot express the 30 % / 800 px/s dismissal, the rubber band and a `spring.sheet` release, build `Sheet.tsx` on `@base-ui/react/dialog` instead with the drag in `useSheetDrag.ts` (`useDrag` from `@use-gesture/react` 10.3.1 plus Motion `animate(y, target, { type: "spring", visualDuration: 0.48, bounce: 0 })`), which is the same decision `cinematic/DESIGN.md` §7.9 records for Flutter's `CineSheetRoute`. Record which path you took in the plan and the report.
- States: opening (Rise; haptic none; sound `sheet` through `sounds.ts` event `sheet.open` when sounds are on); dragging; release; closing; loading (header renders, body shows a 24 px leader dial and the kicker `LOADING` after 400 ms); error (a `Notice` inside the body); focus (moves to the first control on open, returns to the trigger on close, `Tab` trapped).
- Browser back: a sheet given `historyKey="type"` pushes `?sheet=type` with `window.history.pushState` on open and closes on `popstate`; closing by any other path calls `history.back()` once so the entry is not left behind.
- Desktop frame (≥ 768 px): the same component renders as a **column panel**: 4 grid columns wide (min 400 px), sliding in from the right edge with **Panel**, `paper.2`, 1 px `rule.2` left edge, full height under the running head (`top: var(--mm-running-head-h, 56px)`, a variable web/06's Shell sets), barrier `scrim.modal` below the running head, `Esc` closes. Confirmations never use a sheet on the desktop frame; they use `Dialog`.

### 3. Dialogs and destructive confirms (§7.10) — `Dialog.tsx`, `ConfirmDialog.tsx`, `useArm.ts`, `InlineConfirm.tsx`, `commitWithUndo.ts`

- `Dialog` on `@base-ui/react/dialog`: surface `paper.3` (`data-stock="raised"`), 1 px `ink.30` border, radius 0, max width 560 (6 desktop columns); on the phone frame 88 % width, centred; `z.dialog`. Title `type-subhead` (Bodoni Moda); body `type-body` `ink.60`, max 48ch. Actions: desktop frame a right-aligned row, `quiet` Cancel then the primary or destructive button; phone frame stacked full-width buttons, the committing action on top and Cancel as `quiet` below. Motion **Insert** in, 160 ms fade out. Initial focus on the least destructive action. `Esc` and the barrier cancel, except while a destructive request is running.
- States: default; **arming** (destructive only, first 1000 ms, rule filling); **armed**; **pending** (the committing button shows its loading state, Cancel disabled); **error** (an error line above the actions in `proof`).
- **The arm** (`useArm(ms = 1000)`, pure state machine in `arm.ts` with tests): every dialog, sheet or inline confirm whose committing action is `destructive` opens with that button disabled for 1000 ms; the 2 px `proof` rule fills under it (Arm); while it fills the label is `ink.30` and `aria-disabled="true"`; when full the label turns `proof` (or, for the final filled confirm, the fill turns `proof` with `#000` text) and a polite live region says "Ready"; Enter, Space, a tap or a click during the arm does nothing, so the double tap that opened the dialog can never confirm it; Cancel is live from the first frame. Pressing the armed button fires haptic `delete.confirm`.
- **Heavy confirmations** (`ConfirmDialog` props `typedPhrase`, `acknowledge`, `typedUsername`): a typed phrase field ("Type RESTORE to confirm", case-insensitive), an acknowledgement checkbox ("I understand this signs me out on this device too") or a typed username; the confirm enables only when both the arm has elapsed and the condition is met.
- **InlineConfirm**: a destructive button that turns into "Confirm {verb}" with the arm, and reverts after 4000 ms without a press (the 4 s inline-confirm revert, §4.2 behaviour timings).
- **Single unfollow / remove** never opens a dialog: `commitWithUndo({ run, undo, message })` commits at once and shows the toast "Removed {title}." with `Undo`, held 8000 ms (`dur.hold.toast.action`); pressing Undo fires haptic `undo`.

### 4. Toasts: "subtitles" (§7.11) — `ToastHost.tsx`, `subtitles.ts`

- `sonner` 2.0.8 in unstyled mode (`<Toaster toastOptions={{ unstyled: true }} … />`) rendering Cinematic subtitles through `toast.custom`. Public API in `subtitles.ts`: `subtitle.info(text, opts)`, `.success`, `.error`, `.action(text, { label, onAction })`, `.undo(text, onUndo)` (the skin-switch undo uses `dur.hold.toast.undo`).
- Surface `paper.2` with `data-stock="raised"`, 1 px `rule.2` border, a 2 px left edge rule (`spot` info, `set` success and completion, `proof` error); text `type-ui` `ink.100`, never truncated (the toast grows), 12 × 16 px padding, max width 560; one `quiet` action in `ink.100` with an underline ("Undo", "View", "Retry").
- Holds: 3600 ms default, 6000 ms errors, 8000 ms with an action, 10000 ms skin undo, indefinite while hovered or while focus is inside the region; with a screen reader the hold never runs out for a toast with an action (the web cannot detect a screen reader, so rely on the focus rule, §14.5).
- Position: phone frame bottom-centre, 16 px above the thumb index (the Shell passes `anchorBottom`) or above the safe area where there is no thumb index; desktop frame bottom-left of the content column, 24 px from the bottom. Max 2 visible (`visibleToasts={2}`); a newer toast pushes the older one up by its height. `ToastHost` accepts `bannerHeight`: while the stop-press banner (web/06) shows, it renders `offset={{ bottom: anchorBottom + bannerHeight + 8 }}`, `mobileOffset={{ bottom: anchorBottomPhone + bannerHeight + 8 }}` and `visibleToasts={1}`. It also accepts a `frame` prop (`"reader" | "page"`) for the reader rule: bottom-centre, max 560, 16 px above the highest bottom element showing, 24 px above the bottom edge when the chrome is hidden, never over the ruler; in the novel reader the stock colours apply (`--stock-page`, `--stock-ink`, `--stock-muted`).
- Dismiss: swipe down (touch), `Esc` while focused, or timeout. Semantics: `role="status"` (polite), errors `role="alert"`. `Alt+T` moves focus into the region: `<Toaster hotkey={["altKey", "KeyT"]} />`; focusing the region pauses every hold. Verify in the gallery that sonner pauses on focus-within; if it does not, pause by calling `toast.custom` again with `duration: Infinity` on `focusin` and re-issue with the remaining time on `focusout`.
- `ToastHost` also listens for the `mm:db-busy` window event (item 10 below) and shows "The server is busy. Your progress is saved on this device and will sync." as an info subtitle.

### 5. Contents tabs (§7.12) — `ContentsTabs.tsx`

- On `@base-ui/react/tabs`. Label: folio + label (`01 CHAPTERS`, `02 DETAILS`, `03 MORE LIKE THIS`) in `type-nav` at its desktop size, the folio in Plex Mono `ink.45`; counts as the raised folio after the label (`CHAPTERS²⁰¹` drawn as label + raised digits, spoken "Chapters, 201" through `folioLabel()`).
- Indicator: a 2 px `spot` underline under the active label, sliding and stretching between tabs (its x and width lerp with the pager position during a swipe; a tap slides it with **Rule slide**, 320 ms `ease.settle`; reduced motion fades out under the old and in under the new over 150 ms).
- Row 48 px with a 1 px `rule.1` under the whole row; scrolls horizontally on the phone frame; `sticky` prop pins it under the running head (`top: var(--mm-running-head-h)`, `z.sticky`).
- Panels: on the phone frame a CSS scroll-snap pager (`scroll-snap-type: x mandatory`, one panel per snap point) whose scroll position drives the indicator; on the desktop frame click, `[` and `]` (registered with `useShortcut` from `@/lib/keyboard`, group named by the caller). `pager={false}` makes nested tabs tap-only (Updates `NEW · FOLLOWING`, History `BY SERIES · BY CHAPTER`, §11). Swipe rows inside a pager set `touch-action: pan-y` so rows win (§11 precedence).
- States: default `ink.45`; hover `ink.100`; pressed 1 px impression; focus ring; selected `ink.100` plus the rule; disabled `ink.30` with a tooltip (e.g. `04 CIRCLE` when sharing is off); loading (count `–`); error (count replaced by `!` in `proof`). Haptic `select` on commit.

### 6. Lists and rows (§7.16) — `rows/{Row,SettingsRow,ScheduleRow,ContentsRow,CreditsRow,DotLeader,SwipeRow,ReorderList}.tsx`, `reorder.ts`

- Row types: **Standard** (leading 20 Regular icon, or a 40 × 60 cover, or a 32 avatar → `type-title` + `type-caption` `ink.45` → trailing folio value or chevron; 56 one line / 72 two lines); **Settings** (label `type-ui` + description `type-caption` `ink.45` → trailing control: switch, value with dot leaders, or chevron; min 56); **Schedule** (chapter row: chapter number `type-folio-lg` right-aligned in a 56 px column, `·` when null, decimals as-is → title `type-title`, de-duplicating "Chapter 12" when the source title repeats the number, plus a caption with the release date `TODAY`, `YESTERDAY`, `3 D AGO`, `12 SEP 2026` and the page count → progress `14/27` in `spot` Plex Mono when in progress, `READ` micro `ink.45` when complete with the row text dimmed to `ink.45`, nothing when unread → a `DownloadMark` slot → a reaction-count folio slot for Circle (empty until web/22); 56); **Contents** (novel TOC: ordinal `type-folio` right-aligned → title Newsreader 16 → dot leaders → length `12 MIN` → state mark `42%` in `spot`, `READ`, a headphones glyph when narrated, the download mark; 48); **Credits** (label → dot leaders → value on one baseline; 40).
- `DotLeader`: `·` at 0.5 em intervals in `ink.30` and `type-folio`, drawn as a `radial-gradient` background repeating every 0.5 em on the baseline, `aria-hidden`.
- States: default (1 px `rule.1` dividers); hover (a 2 px `ink.100` bar on the left edge, text `ink.100`, 120 ms `dur.snap`); pressed (fill `paper.3`, 80 ms); focus (ring inset 2 px); selected (fill `paper.3` + 2 px `spot` left bar, `data-stock="raised"`; in select mode a leading 20 px checkbox; 120 ms); disabled (`ink.30`, no hover); loading (galley lines at the exact line heights, flicker); error (caption turns `proof` with the reason and a trailing `quiet` Retry); current (novel TOC current chapter or go-to target: `spot.wash` band + 2 px `spot` left bar, `data-stock="wash"`, `aria-current="location"`, band fades in 240 ms).
- **Row menus**: every row with actions has a trailing `dots-three` icon button (the non-gesture path), opens its menu on right-click (desktop) and on a 450 ms long-press (coarse pointers, 8 px slop), with haptic `longpress.open`.
- **Swipe actions** (`SwipeRow`, coarse pointers only): one flat square slab per row, 72 px, revealed under the row: `Mark read` (fill `ink.100`, `#000` label) or `Remove` (fill `proof`, `#000` label); release past 50 % commits with `spring.release` (`{ visualDuration: 0.42, bounce: 0 }`); `Mark read` rows spring back and dim instead of leaving; `touch-action: pan-y`; haptic `select`, and `delete.confirm` for Remove; the same action is in the row menu.
- **Reorder** (`ReorderList` on Motion 13 `Reorder`): a `dots-six-vertical` 20 Regular handle at the trailing edge; the lifted row rises 1 px and gains a 1 px `ink.100` outline (no shadow); siblings shift 240 ms `ease.set`; drop fires haptic `select`. Keyboard: `Alt+↑` / `Alt+↓` moves the focused row. Every row menu gains **Move up, Move down, Move to top, Move to bottom** (disabled at the ends), each animating with the same 240 ms shift, calling the caller's `onMove(from, to)` (which writes `sort_order`), and announcing in a polite live region "Solo Leveling moved to position 3 of 12" (the string built by `reorder.ts`, tested).
- **Select mode** (row variant): leading 20 px checkbox, selected rows as above; the bar is item 11.

### 7. Sliders and the scrubber base (§7.20) — `Slider.tsx`, `Scrubber.tsx`

- On `@base-ui/react/slider`. Track 2 px `rule.2`, fill `ink.100` up to the value, step ticks 1 × 6 px `ink.30` under the track when steps ≤ 20; thumb a 2 × 20 px `ink.100` bar with a 44 × 44 hit area (32 on a fine pointer); while dragging a folio flag above the thumb (`#000000` box, 1 px `ink.100` border, `type-folio`: "1.25×", "19 px", "−40"); min and max captions in `ink.45` when given.
- States: hover thumb 2 × 24 (80 ms); pressed / dragging thumb 3 × 28 with the flag and haptic `select` per step; release returns with `spring.scrub` (CSS: `transition: transform var(--mm-spring-scrub-ms) var(--mm-spring-scrub)`); focus ring around the thumb's hit square; arrow keys step, `Shift+arrow` × 10, `Home` / `End`; disabled track `rule.1` and thumb `ink.30`.
- `Scrubber`: the same control exposing `onTick(page)` and `onBoundary(chapter)` callbacks that fire haptics `scrub.tick` and `scrub.boundary` and `aria-valuetext` from the caller ("Page 18 of 40"). The reader ruler (§8.14.4) extends it in web/12 and the speed ruler (§8.16.4) in web/15.

### 8. Toggles, checkboxes, radios, steppers (§7.21) — `Switch.tsx`, `Checkbox.tsx`, `Radio.tsx`, `Stepper.tsx`

- **Switch** ("slug switch", Base UI Switch): a 44 × 24 rectangle, 1 px `ink.45` outline, a 16 × 16 square knob inset 4 px. Off: knob left, knob fill `ink.45`, track transparent. On: track fills `spot`, knob right, knob fill `#000`. The row's label says what it does; the switch's accessible name is the row label (`Semantics`-equivalent: `role="switch"` + `aria-checked`). Motion: knob slides 160 ms `ease.set`; while pressed the knob widens to 20 px (a squash, not a bounce); haptic `toggle.on` / `toggle.off` and the matching sound cue. States: hover outline `ink.100`; focus ring around the track; disabled outline `rule.1`, knob `ink.30`; loading (server-backed switches such as 18+ or notify: the knob becomes a 12 px leader dial, `aria-busy`); error (outline `proof` for 2000 ms, the switch reverts, an error line appears).
- **Checkbox** (Base UI Checkbox): 20 × 20 square, 1 px `ink.45` outline; checked fill `ink.100` with a `#000` check drawn as a 2 px square-capped SVG path (not an icon glyph); indeterminate fill `ink.100` with a 10 × 2 `#000` dash; hover outline `ink.100` (80 ms); fill 120 ms (`dur.snap`).
- **Radio** (Base UI RadioGroup / Radio): 20 px circle (round is allowed here), 1 px `ink.45`; selected a 10 px `ink.100` dot; hover outline `ink.100` (80 ms); 120 ms. `inMutuallyExclusiveGroup` semantics through `radiogroup`.
- **Stepper**: `−` value `+`: two 36 px `ruled` icon buttons around a `type-folio-lg` value, min width 64; the bounds disable their button; press and hold repeats every 120 ms after 400 ms; the value rolls with **Folio flip**; haptic `select` per step.

### 9. Menus, context menus, Select and Quick look (§7.22, §7.3) — `Menu.tsx`, `ContextMenu.tsx`, `Select.tsx`, `QuickLook.tsx`, `actions.ts`

- Menu surface (Base UI Menu and ContextMenu): `paper.2` with `data-stock="raised"`, 1 px `rule.2` border, radius 0, min width 224, max height 60 vh, `z.dialog`. Item 40 px on the desktop frame and 48 on the phone frame, optional leading 20 Regular icon, `type-ui`, trailing shortcut `Keycap` or a submenu caret; separators `rule.hair`; destructive items `proof`; checked items a leading `check`. Hover and focus: fill `paper.4` + a 2 px `ink.100` left bar. Motion: the clip reveal from the anchored edge, 120 ms exit fade. Keyboard: arrows, `Home` / `End`, type-ahead, `Enter`, `Esc`, submenus with `→` / `←`. Desktop right-click opens `ContextMenu` at the pointer.
- **Select** (§7.3 select row): the editorial underline field with a trailing `caret-down` 16; on the desktop frame it opens a Base UI `Select` popup styled as the menu above; on the phone frame it opens a `Sheet` listing the options as radio rows; the value shows in the field; keyboard as the menu.
- **Quick look** (phones, 450 ms long-press on a poster, cutting or row that offers it): the pressed element dims to 70 % for 120 ms (`dur.snap`), then a `Sheet` rises whose header match-cuts the poster into a 96 px cover beside the title, kicker and credits (a Motion FLIP from the poster's rect to the header slot, 480 ms `ease.turn`, run during the Rise), followed by the action list. Haptic `longpress.open`. `actions.ts` exports the standard action ids, labels and icons in this order: Open, Continue, Previously on, Add to collection, Favourite, Mark read, Download next 5, Recommend to…, Not for me, Remove from row, Unfollow (destructive); callers pass the subset that applies and the handlers. On the desktop frame the same actions appear in the right-click `ContextMenu`. Reduced motion: the header cover fades in, no FLIP.
- **Move items** for reorderable rows and posters: Move up, Move down, Move to top, Move to bottom (item 6).

### 10. Notices (§7.23) — `Notice.tsx`, `lib/busy-retry.ts`

- One component, set like a short article: a 3 px `rule.heavy` above, drawn on entrance (Rule draw, 480 ms `ease.settle`); kicker `type-kicker` by tone: `empty` → `EMPTY SHELF` or `NOTHING HERE YET` (caller chooses), `error` → `CORRECTION` in `proof`, `offline` → `OFFLINE EDITION`, `caution` → `NOTE` in `spot`, `rateLimit` → `SLOW DOWN`; headline **typed** with `TypedHeadline` (§10.2) in `type-subhead` on the phone frame and `type-headline` at 0.6 scale on the desktop frame, `as="h1"` when the notice is the whole page and `as="h2"` otherwise; deck `type-deck` `ink.60`, max 48ch; up to two actions (`primary` + `quiet`); an optional 32 px Light glyph `ink.45` above the kicker; left-aligned on the grid over 6 desktop columns or 4 phone columns, offset 15 vh from the top when it is the whole screen.
- Rate limit: the deck includes a live countdown folio "Retrying in 12 s" computed from `Retry-After`. Use `ApiError.retryAfterMs` (`number | null`, parsed from `Retry-After` by web/03 in `frontend/src/services/http.ts`).
- Global offline preset: the deck adds "Saved chapters still open." and a `Go to Downloads` action.
- `503 db_busy`: `lib/busy-retry.ts` exports `busyRetry(failureCount, error)` for React Query's `retry` and `retryDelay` (retry up to 3 times, each after the error's `retryAfterMs` when it is not null, else 2000 ms); after the third failure it dispatches `window.dispatchEvent(new CustomEvent("mm:db-busy"))`; every other error keeps today's policy (`retry: 1` in `providers.tsx`), so legacy behaviour does not change. Wire it into the `QueryClient` defaults in `frontend/src/app/providers.tsx` so every skin benefits; only skins with a toast host show the subtitle (legacy has none, which keeps legacy unchanged).
- Nothing ever shows a count or a placeholder for 18+ content the gate hides (§7.23 last line, §7.24 "Absence, never a lock").

### 11. Other primitives (§7.29) — `ContentModeToggle.tsx`, `ContentModeChip.tsx`, `PullToReprint.tsx`, `SelectModeBar.tsx`, `BannerStrip.tsx`

- **Content mode**: `ContentModeToggle` is the typographic `MANGA / NOVELS` toggle (active word `ink.100` with a 2 px `spot` underline, the other `ink.45`, a slash between; radiogroup semantics), reading and writing through `useContentMode()` from `@/features/content-mode` (reuse). `ContentModeChip` is the phone-frame chip `MANGA ▾` (or `NOVELS ▾`) that opens a small `Sheet`: kicker `READING MODE`, the toggle, and "One setting for the whole app: library, sources, search, downloads and updates all follow it."; haptic `select` on change. Both render nothing when novels are disabled on the server (`novels_enabled` from bootstrap status, as `useContentMode` already reports). The sidebar version and the chip's placement in running heads are web/06.
- **Pull to reprint**: pulling past the top of a refreshable list (touch, via pointer events, about 60 lines) reveals a 2 px `spot` rule growing from the centre outwards with the pull, rubber-banded with c = 0.35, and the caption `PULL TO REPRINT`, which becomes `RELEASE TO REPRINT` at the 96 px trigger (haptic `refresh.arm` and cue `tick` once when crossing); on release (`refresh.fire`) the rule becomes the indeterminate rule until the caller's promise settles. Desktop: no pull; the caller registers `r` and an overflow `Refresh` item. Thresholds in `pull.ts` (pure, tested). Never used on Downloads.
- **Select-mode bar**: bottom bar on the phone frame (above the safe area, over the thumb index) and a bar under the running head on the desktop frame; `paper.2` with `data-stock="raised"` and a 1 px `rule.2` top; shows `12 SELECTED` (`type-folio`), `Select all 40`, the caller's actions as `quiet` buttons with icons (Favourite, Unfavourite, Mark read, Mark unread, Add to collection, Download, Unfollow in `proof`), and `Done`. Running state: `4 OF 12 · 1 FAILED` + a determinate `RuleProgress` + `Stop`. Result line with `Dismiss` and, for destructive runs, `Undo`. Unfollow in bulk opens a `ConfirmDialog` with the arm first. `Esc` equals `Done`.
- **Banner strip**: `paper.0` with a 2 px left rule (tone colour), kicker + one line + actions, placed under the running head by callers ("Nothing followed yet", staged restore, overdue checker; web/06 uses it for the first-run note).
- **Spoken folios**: already delivered in web/04 (`a11y/folio.ts`); use it for every folio here.

### 12. The certificate mark and the certificate dialog shell (§7.24) — `Certificate.tsx`, `CertificateDialog.tsx`

- `Certificate` at 160 px (the dialog only): a square with a 2 px `proof` border and "18" in Bodoni Moda Roman `wght` 900 at 88 px, `aria-label` "Mature, 18 plus". The 16 px and 20 px marks are the web/04 `Badge variant="certificate"`.
- **Stamp** (the confirm moment): the square fills `proof` for 160 ms while the "18" knocks out to `#000`, then settles back to the outline; haptic `gate.confirm` and cue `impress` are fired by the caller at the fill. Reduced motion: the fill shows for 160 ms without transition.
- `CertificateDialog` shell: full screen on the phone frame (a Takeover with its own close), a 560 px `Dialog` on the desktop frame. Layout: the 160 px certificate on the left (desktop) or top (phone); kicker `RESTRICTED · THIS PROFILE ONLY`; headline "Show mature content on {profile}?" in Bodoni Moda (`type-subhead` on the phone frame, `type-headline` at 0.6 scale on the desktop frame), or "Show mature content on this profile?" when the profile name is empty; body in Newsreader: "Adult (18+) sources, series, search results and recommendations will appear throughout ManhwaManiacs for this profile. Only continue if you are of legal age where you live. You can turn this off any time."; a checkbox "I am 18 or older"; buttons `Enable 18+` (primary, disabled until the box is checked) and `Cancel` (quiet). Props `onConfirm(): Promise<void>` (the button shows its loading state while it runs, then the stamp plays) and `onCancel`. The mutation, invalidation, toasts, rating card and local filtering are web/07.

### 13. Lightbox (§7.30) — `Lightbox.tsx`, `lightbox-math.ts`

- Opens from: long-press 450 ms (touch) or double-click (desktop) on the feature and book page covers, Tonight's cover-story art and the Annual's cover art; the overflow item `View cover` and the key `v` on those screens (callers wire them); the reader page action `Open page image` with the page image.
- Surface: `color.lightbox` (`rgba(0,0,0,0.96)`) over everything at `z.lightbox`, square corners, **no bloom, no grain, no drift**; the art at `object-fit: contain`, centred, never larger than 1.5 × its natural pixels at rest (a 720 × 1080 cover shows at most 1080 × 1620 CSS px).
- Chrome: top-right `x` `on-art` icon button (label "Close"); bottom-left the series title in `type-caption` `ink.60` and a folio `COVER · 720 × 1080` (`PAGE 18 · 800 × 12400` for pages), both on the folio-flag ground (`#000000` box, 1 px `ink.100` border, 4 × 8 px padding); on the desktop frame `+`, `−` and `Fit` `on-art` icon buttons bottom-right. Chrome hides after 3000 ms idle and returns on tap or pointer move; the idle timer pauses while focus is inside.
- Open: a match cut from the art's frame to the contain rect, 480 ms `ease.turn` (Motion `animate` on a FLIP from the source rect); the barrier fades 0 → 0.96 in 240 ms. Haptic `longpress.open`.
- Zoom: pinch 1–4× (`usePinch` from `@use-gesture/react` 10.3.1); double tap or double-click toggles 1× ⇄ 2.5× at the point in 240 ms `ease.settle` (haptic `zoom.snap`); `Ctrl`/`⌘` + wheel zooms around the pointer; keys `=` `-` `0`; pan when zoomed (`useDrag`); the zoom level shows as a folio chip `250%` (`type-folio` `ink.100` on the folio-flag ground) top-centre for 1200 ms (`dur.hold.chip`). Cursors `grab` / `grabbing` when zoomed.
- Dismiss: drag down (only at 1×): the art follows the finger and the barrier opacity is `0.96 × (1 − dy / 400)`; release past 120 px or faster than 800 px/s dismisses by a reverse match cut into the original frame on `spring.release`, otherwise it springs back on `spring.release`. `x`, `Esc` and browser back (a `?view=cover` history entry pushed on open) close by button with a 320 ms `ease.turn` reverse match cut. Maths in `lightbox-math.ts` (pure, tested): the 1.5 × cap, the barrier opacity, the dismiss rule.
- States: loading the full-size image (the cached crop is scaled into place at once and the sharp image racks in with Rack focus when it lands); failed (the crop stays with the caption "Couldn't load the full cover." in `proof`); offline (the cached copy only).
- Accessibility: `role="dialog"`, `aria-modal="true"`, `aria-label="Cover of {title}"`; focus moves to Close and returns to the trigger; the zoom buttons also appear for keyboard users when focus is inside, on every frame.
- Reduced motion: 150 ms fade in and out; drag-to-dismiss still works and finishes with a 150 ms fade.

### 14. Gallery, tests and proof

- Extend `frontend/src/app/(preview)/skin-preview/[skin]/primitives/page.tsx` with sections `#sheets`, `#dialogs`, `#toasts`, `#tabs`, `#rows`, `#sliders`, `#toggles`, `#menus`, `#notices`, `#certificate`, `#other`, `#lightbox`, each with triggers that open the overlay in each state (loading, error, arming, armed, pending, heavy confirm), fixture data only, `data-gallery` attributes on every trigger and control, and a `ToastHost` mounted once.
- Vitest (`src/**/*.test.ts`, node): `skins/cinematic/primitives/arm.test.ts` (disabled until 1000 ms; a press at 999 ms is ignored; heavy condition AND arm), `sheet-physics.test.ts` (rubber band at x = 0, d; nearest detent; dismiss at 29 % / 31 % and at 799 / 801 px/s), `lightbox-math.test.ts`, `reorder.test.ts` (announcement strings, disabled ends), `pull.test.ts` (96 px trigger, rubber band), `lib/busy-retry.test.ts` (three retries, delay from `retryAfterMs`, event after the third, any other error retried once as today); web/03 already tests the `Retry-After` parsing.
- Playwright `frontend/e2e/cinematic/overlays.spec.ts` against `next dev` on port 3010:
  - Sheet: opens with Rise, focus lands on its first control, `Tab` stays inside, `Esc` closes and focus returns to the trigger; with `historyKey` the URL gains `?sheet=` and `page.goBack()` closes it; at 1440 × 900 it renders as a right column panel at least 400 px wide.
  - Dialog arm: double-clicking the trigger opens the dialog and does not confirm; pressing Enter at 500 ms does nothing; at 1,100 ms the live region says "Ready" and Enter confirms; Cancel works at 100 ms.
  - Menu: arrow keys move, typing a letter jumps to the matching item, `Esc` closes and returns focus, right-click opens the context menu at the pointer.
  - Toasts: `Alt+T` focuses the region; a focused toast is still present after its hold elapses; max two visible.
  - Tabs: `]` moves to the next tab; the indicator ends under the active label.
  - Stepper and slider: arrow keys, `Shift+arrow` × 10, `Home`/`End`, disabled bounds.
  - Lightbox: opens with focus on Close, `?view=cover` in the URL, `Esc` closes and focus returns; `=` zooms and the `250%` chip appears.
  - Reduced motion (`emulateMedia({ reducedMotion: "reduce" })` and `html[data-motion="reduced"]`): sheet, dialog, menu, toast and Lightbox transitions are opacity-only and ≤ 200 ms; the arm rule appears full at 1000 ms with no fill.
  - Hit targets: every control ≥ 44 × 44 at 390 × 844 with touch emulation and ≥ 32 × 32 at 1440 × 900.
- Extend `primitives-states.spec.ts` (web/04) with the new `data-gallery` elements so their hover, focus and pressed states are captured into `docs/redesign/proof/web-05/states/`.

## File layout (create or change exactly these)

```
frontend/src/skins/cinematic/motion.ts, motion.css                      Folio flip, Insert, Rise, Panel, Arm, Lightbox, menu, toast moves
frontend/src/skins/cinematic/primitives/
  FolioFlip.tsx Sheet.tsx useSheetDrag.ts sheet-physics.ts sheet-physics.test.ts
  Dialog.tsx ConfirmDialog.tsx useArm.ts arm.ts arm.test.ts InlineConfirm.tsx commitWithUndo.ts
  ToastHost.tsx subtitles.ts ContentsTabs.tsx
  rows/{Row,SettingsRow,ScheduleRow,ContentsRow,CreditsRow,DotLeader,SwipeRow,ReorderList}.tsx reorder.ts reorder.test.ts
  Slider.tsx Scrubber.tsx Switch.tsx Checkbox.tsx Radio.tsx Stepper.tsx
  Menu.tsx ContextMenu.tsx Select.tsx QuickLook.tsx actions.ts
  Notice.tsx ContentModeToggle.tsx ContentModeChip.tsx PullToReprint.tsx pull.ts pull.test.ts
  SelectModeBar.tsx BannerStrip.tsx Certificate.tsx CertificateDialog.tsx
  Lightbox.tsx lightbox-math.ts lightbox-math.test.ts
  index.ts                                                               export the new primitives
frontend/src/lib/busy-retry.ts, busy-retry.test.ts                       new (skin-neutral)
frontend/src/app/providers.tsx                                           QueryClient retry → busyRetry
frontend/src/app/(preview)/skin-preview/[skin]/primitives/page.tsx       new gallery sections
frontend/e2e/cinematic/overlays.spec.ts, primitives-states.spec.ts
docs/redesign/proof/web-05/plan.md
docs/redesign/proof/web-05/…
```

Do not touch `frontend/src/skins/glass/**`, `frontend/src/components/**`, `frontend/src/features/*/components/**`, `mobile/`, `backend/`. This step finishes no `ScreenId`; the `PENDING` set is unchanged.

## Working steps, commits and pushes

1. `feat(web-cinematic): overlay motions and folio flip` (1).
2. `feat(web-cinematic): sheets, column panels and dialogs with the destructive arm` (2, 3) → verify, push.
3. `feat(web-cinematic): subtitles toast host` (4).
4. `feat(web-cinematic): contents tabs, rows, reorder and swipe actions` (5, 6) → verify, push.
5. `feat(web-cinematic): sliders, switches, checkboxes, radios, steppers` (7, 8).
6. `feat(web-cinematic): menus, context menus, select and quick look` (9).
7. `feat(web): db_busy retry policy` (10, data layer) and `feat(web-cinematic): notices` → verify, push.
8. `feat(web-cinematic): content mode, pull to reprint, select bar, banners, certificate` (11, 12).
9. `feat(web-cinematic): lightbox` (13).
10. `test(web-cinematic): gallery sections and overlay e2e` (14) → verify, push.
11. `docs(redesign): web-05 proof screenshots` → push.

## Acceptance criteria

- [ ] Every component in items 1–13 exists with every state in its §7 table and shows in the gallery.
- [ ] Sheets: Rise 360 ms in, 240 ms out, barrier to 0.78 in 240 ms; the rubber band, 30 % / 800 px/s dismissal and `spring.sheet` release behave as specified; focus is trapped and returned; `?sheet=` history entries close on back; on the desktop frame they are column panels ≥ 400 px wide sliding with Panel.
- [ ] Dialogs: Insert in 320 ms with the clip, fade out 160 ms; initial focus on the least destructive action; every destructive confirm is disabled for exactly 1000 ms, a double activation cannot confirm it, "Ready" is announced, and heavy confirms need both the arm and their condition.
- [ ] Toasts: correct surface, edge colour, holds (3600 / 6000 / 8000 / 10000 ms), max 2 visible, `Alt+T` focus, holds pause while hovered or focused, `role="status"` / `role="alert"`.
- [ ] Menus: arrows, `Home`/`End`, type-ahead, `Enter`, `Esc`, submenus with `→`/`←`, focus return; right-click context menu; Quick look on a 450 ms long-press with the 96 px header match cut.
- [ ] Rows: all five row types, all states, row menus reachable without gestures, swipe slabs on touch only, reorder by drag, by `Alt+↑/↓` and by the Move items, each announced.
- [ ] Controls: switch, checkbox, radio, stepper and slider semantics match the §7 table; slider keys work; the stepper value rolls with Folio flip; haptic and sound events fire through `haptics.ts` / `sounds.ts` (inspect with the web/02 recorder or a spy in the gallery).
- [ ] Notices: typed headlines, correct kickers per tone, `SLOW DOWN` countdown from `Retry-After`, the offline preset; `503 db_busy` retries three times before the subtitle.
- [ ] Certificate: 160 px mark, stamp, dialog shell with the checkbox gating `Enable 18+`; full screen on the phone frame, 560 px dialog on the desktop frame.
- [ ] Lightbox: 1.5 × natural cap, match-cut open and close, pinch 1–4×, double tap 2.5×, keys, drag-to-dismiss thresholds, `?view=cover`, focus management, idle-hiding chrome that stays while focus is inside.
- [ ] Reduced motion (OS and `data-motion="reduced"`): every overlay transition is an opacity change of 150–200 ms, rule slides fade, the arm shows full at 1000 ms, gestures finish with a 150 ms fade, the leader dial and indeterminate rule keep running.
- [ ] Keyboard: everything operable without a pointer; the focus ring shows on `:focus-visible` only and is never clipped.
- [ ] Hit targets ≥ 44 × 44 on the phone frame and coarse pointers, ≥ 32 × 32 on a fine pointer, ≥ 8 px between adjacent targets.
- [ ] No blur behind any overlay; radius 0 except radios and the round list of §2.3; no shadows.
- [ ] `node design/lint-utilities.mjs` and the ESLint skin boundary pass; legacy screens are unchanged (the only legacy-visible change is the quieter `db_busy` retry, which shows nothing).
- [ ] Every vitest test that passed before this step still passes; lint 0 / 0; build passes.

## Verification

Record the vitest total before the first edit, then:

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs
node design/build.mjs --check
node design/lint-utilities.mjs
cd frontend
test "$(free -m | awk '/^Mem:/{print $7}')" -ge 1024 || { echo "RAM guard"; exit 1; }
npm run typecheck
npm run lint            # 0 errors, 0 warnings
npm run test            # every earlier test passes; report old and new totals
npm run build           # passes; stop next dev first
```

Then, with the RAM guard before each, start `next dev` on port 3010 (the gallery needs no backend):

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs/frontend
E2E_BASE_URL=http://127.0.0.1:3010 npx playwright test e2e/cinematic
node scripts/proof.mjs --step web-05 --skin cinematic --no-auth --routes /skin-preview/cinematic/primitives --grid
node scripts/proof.mjs --step web-05 --skin cinematic --no-auth --routes /skin-preview/cinematic/primitives --reduced
```

Start `next dev` as the harness's usage header says (`BACKEND_INTERNAL_URL=http://127.0.0.1:8010 npm run dev -- --port 3010`). Screenshots go to `docs/redesign/proof/web-05/` at 1440 × 900 and 390 × 844, grid off and on, plus open-state captures of one sheet, one column panel, the arming and armed dialog, two stacked toasts, an open menu, Quick look, a notice of each tone, the certificate dialog on both frames and the Lightbox (the overlays spec saves these with `page.screenshot` into `docs/redesign/proof/web-05/overlays/`). Use `playwright-cli -s=web-05` for any ad-hoc browser session.

Mobile and backend: this step changes neither. Judge that by your own commits, never by the branch diff: every web step runs in parallel with its `mobile/NN` twin on the same branch, so `git diff origin/...HEAD -- mobile backend` is routinely non-empty with other sessions' work. `git show --stat --format= <hash>` for each commit of this step must list no `mobile/` or `backend/` path. Only if one does, revert that part and prove the baseline still holds with its own commands, one at a time after the RAM guard and never while a `next build` runs: `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze` (baseline: No issues found), `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter test` (baseline: all 2012 tests passed) and `cd backend && .venv/bin/python -m pytest -q --no-header`.

## Report back

1. Done items by number (1–14) and anything not done with the reason; which path the sheet took (Drawer or Dialog plus `useSheetDrag`) and why.
2. `docs/redesign/proof/web-05/` file list and the two critiques with the changes they caused.
3. Vitest before and after (files, cases), Playwright passed / failed, lint, build, `build.mjs --check`, `lint-utilities`.
4. Commit SHAs, each pushed.
5. Open issues and contract ambiguities, with how you resolved them.

Next prompt: `docs/redesign/prompts/web/06-cinematic-shell-navigation-transitions.md`.
