# Web Glass primitives 1: controls, posters, rails and the two reveals

Track: web · Order 70 · Depends on: `docs/redesign/prompts/web/25-glass-foundation-material-physics.md` · Runs in parallel with: `docs/redesign/prompts/mobile/26-glass-primitives-controls-and-reveals.md` · Proof folder: `docs/redesign/proof/web-26/`

## Goal

Build the first half of the Glass skin's component catalogue on the web client, in `frontend/src/skins/glass/primitives/`, on top of the material, physics and motion foundation of `web/25`: buttons (including `HoldToConfirm` with its 1,200 ms hold, its `hold.ramp` haptics and the always-visible fallback button), icon buttons with 44 px hit areas, inputs, search fields, chips, the segmented control, cards (content layer, with their glass twins), posters (with the press-and-hold lift at 150 and 450 ms and the throw), rails (with the projection snap), "wet glass" skeletons, every progress indicator including `LiquidProgress`, badges and markers, avatars and profile orbs, tooltips and keycaps, and the Glass versions of the two required signature animations: `LetterReveal` (each grapheme a droplet settling; at most 60 graphemes per letter run, at most two runs at once, starting at 25 % visibility) and `TypedHeadline` (one grapheme every 50 ms, the caret of light on the `track` spring, the skip rules), with the Playwright checks of §15.8. Every primitive ships every state (default, hover, pressed, focus-visible, disabled, loading, selected, error), its press physics ("glass swells, content sinks"), its reduced-motion variant and its Solid glass variant, and all of it is shown in a development primitives gallery. No screen is built in this step; Glass stays behind the debug row.

## Read first

Read these completely before planning. Where this file and `glass/DESIGN.md` disagree, `glass/DESIGN.md` wins; say so in the report.

1. `docs/redesign/inventory/00-decisions.md` (all of it; the two signature animations are binding: "each letter fades in, slides up, and un-blurs, staggered" and "one character every 50 ms").
2. `docs/redesign/stack-decision.md` §2.2 (the lint boundary: skins import only the shared data layer and their own primitives), §3 (packages).
3. `docs/redesign/glass/DESIGN.md`:
   - §2.1.2 (text and fill roles: `onGlass`, `onTint`, `label1`–`label4`, `fill1`–`fill4`, `wellOnGlass`, the backing disc `rgba(0,0,0,0.60)` 28 px behind a 22 px glyph, 20 px behind a 16 px glyph, and the glyph and text mappings on T4/T5 glass), §2.1.3, §2.1.4, §2.1.9.
   - §2.2 (spacing tokens, `touchMin` 44), §2.3 (radius tokens and the concentric rule), §2.4.1 (mass classes; rule 1 content twins for anything repeated per item; rule 2 the two page-level controls; transient glass), §2.4.2 rules 1–8 (materialise, thickness follows size, press lights from inside, stretch, one lit object per screen), §2.4.4 (caustic, specular sweep), §2.6 (the focus ring on glass and on content), §2.7 (Phosphor weights and sizes per context, the custom glyphs `droplet`, `age-gate`, `strip-scroll`), §2.8.5 (springs, curves, thresholds).
   - §3.2, §3.3 rule 2 (heights are minimums), §3.5, §3.7 (type roles and their `type-*` utilities).
   - §4.1–§4.11, especially §4.6 (thresholds: tap 450 ms, lift at 150 ms reaching 1.06 at 450 ms, context menu at 450 ms, hold to confirm 1,200 ms with the fill starting at 200 ms, throw 1,200 px/s, magnets 64 px), §4.8 (the entrance wave), §4.10 rows Press swell, Content sink, Stretch, Tab droplet, Wave, Throw, Catch, Rubber band, Liquid fill, Hold fill, Letter reveal, Typing reveal, Error shake, Skeleton shimmer, Liquid spinner, Button dots, Count pop, Hero tilt, Orb idle drift, Specular sweep, Caustic press, and §4.11.
   - §5.2 (the haptic events these components fire: `tap.primary`, `select`, `toggle.on`/`toggle.off`, `press.lift`, `longpress.open`, `throw.commit`, `motion.catch`, `magnet.capture`, `magnet.drop`, `hold.ramp`, `hold.done`, `delete.confirm`, `error`, `download.start`, `download.done`, `download.fail`, `follow.add`, `follow.remove`, `favorite`) and §6 (sounds off by default).
   - §7 intro (every height is a minimum; "hit 44" means 44), §7.1, §7.2, §7.3 (except the Stepper row, which is `web/27`), §7.4, §7.5, §7.6, §7.7, §7.8, §7.9, §7.18, §7.19, §7.20, §7.26, §7.27, §7.40 (pointer cursors).
   - §9.2.2 (the daily goal ring on the profile orb), §10.1 and §10.2 (all of it, including the web code), §11 (the alternative for every gesture these components own), §14.1–§14.10, §15.2 (the primitives list), §15.7 (per-letter reveals capped at 60 graphemes and at most two at once), §15.8 ("Signature animations actually play").
4. `docs/redesign/inventory/web.md` §2.11 (shared state components used across screens), §7.2 (the series card, bulk selection and the grid today), §12.2 (the per-chapter download picker, for the progress button's states) as a checklist that no state is lost.
5. `docs/redesign/inventory/capabilities.md` §7 (library item fields: status, favourite, progress, `palette`), §16.1 (source `health.status`, `health.demoted`, `language`, `icon_url`).
6. `docs/redesign/00-baseline.md`.
7. `docs/redesign/prompts-plan.json`: the `web/00` entry (its `TRACK RULE`) and this file's entry.
8. Code you build on (from `web/25`): `frontend/src/skins/glass/glass/GlassSurface.tsx` (tiers, finishes, twins, `pressedGlow`, `tierValue`, `sweepGlass`, `LensDefs`), `glass/Caustic.tsx`, `glass/useLb.ts` (`useLbItem`), `glass/budget.ts`, `glass/material.ts`, `glass/palette.ts`, `glass/AmbientField.tsx`, `physics/*`, `motion.ts` (`play`, `useGlassReduced`, `GlassMotionConfig`), `motion-timings.tsx`, `glass.css`, `haptics.ts`, `sounds.ts`, `icons/` and the Glass `Icon` component (`web/01`), the keyboard helpers in `frontend/src/lib/keyboard` (find `formatKeyCombo` with `grep -rn "formatKeyCombo" frontend/src/lib`), `frontend/public/skin-preview/covers/` (demo covers), `frontend/src/app/(preview)/dev/glass-calibration/` (the page pattern to follow).

## Preconditions (check before writing the plan)

- `git log --oneline -20` shows the `web/25` work; `frontend/src/skins/glass/glass/GlassSurface.tsx` and `physics/physics.test.ts` exist and pass.
- `node design/build.mjs --check` passes. The Glass `type-*` utilities exist in `frontend/src/skins/theme.generated.css` (`grep -n "type-headline" frontend/src/skins/theme.generated.css`), and the avatar presets exist in the Glass tokens (`grep -n "avatar" frontend/src/skins/glass/tokens.generated.css`); if the presets are missing, use the values in item N below inside one constant with a comment citing §7.26, and report it for the shared track.
- `ls node_modules/@base-ui/react` lists `tooltip` (Base UI 1.8.0).
- In `frontend/`: `free -m && npm run test` is green; record the vitest file and case counts (your floor).

## Skills to invoke

1. `superpowers:writing-plans` before any code: write the plan to `docs/redesign/proof/web-26/plan.md` (commit it with the proof).
2. `superpowers:test-driven-development` for every pure piece (the hold state machine, the throw decision, the wave delays, the segmented projection, the rail column mapping): vitest first.
3. `superpowers:subagent-driven-development` to run the plan (or `superpowers:executing-plans` inline). At most 6 implementer subagents, split by component family; start each subagent prompt with a scope lock, pass `model: "opus"` explicitly, run builds, tests and browsers one at a time, and verify each subagent's work against `git status` and `git diff`, never against its report alone.
4. `frontend-design:frontend-design`, `impeccable:impeccable` and `taste-skill:taste-skill` for every component and for the gallery review (Meniscus: glass swells and lights up under the finger, content sinks as if pressed into water, nothing moves on a timer).
5. `superpowers:verification-before-completion` before you claim anything is done.

## Scope: deliver every item below

All sizes are CSS px; heights are minimums (`min-height` in `rem`, never `height` around text, §7 intro). Colours, springs and curves come from the generated tokens (`--mm-…`, `type-*`, `tokens.generated.ts`); every named move goes through `play()`. On the web "hit 44" means the interactive element's own box is at least 44 × 44 px (the visual can be smaller and is drawn by a child or `::before`), with at least 8 px between adjacent hit boxes (§14.6). Every icon-only control has an `aria-label` and a tooltip after the 600 ms hover delay. Haptics go through `skins/glass/haptics.ts` (which maps only its seven Android Chrome events and no-ops the rest) and sounds through `sounds.ts`. Sections cited are `glass/DESIGN.md`.

### A. Shared press behaviour (`primitives/usePress.ts`, §2.4.2 rules 3–4, §4.10, §7.1)

One hook every pressable primitive uses. It sets `data-hover`, `data-pressed`, `data-focus-visible`, `data-disabled`, `data-loading`, `data-selected` and `data-error` on the element, so every state is styled from CSS and the gallery can force a state with a `forceState` prop that sets the same attribute.

- **Glass swells** (`material: "glass"`): on press the glass grows by `+12 px` on its longest side for the Medium class (buttons, the split button), or `+17 px` capped at `0.35 × side` for Feather and Light (icon buttons, a selected chip's glass, badges, toggles' knobs), on the `press` spring (k 815.7, c 45.70; settle 253 ms), as a scale of `(L + growth) / L`; the press glow at the touch point (`GlassSurface` `pressedGlow`, 16 %, `glowIn` 150 ms / `glowOut` 60 ms); the label's `wght` + 40; while the finger drags, a stretch of up to 6 % along the drag axis, `scale = 1 + 0.06 × clamp(dx / width, −1, 1)`, with the other axis at `1 / √scale` so the area looks conserved, on `track`.
- **Content sinks** (`material: "content"`): cards and posters 0.97, rows 0.99, chips 0.96, plain icons 0.92, on `press`.
- **Activation** happens on release inside the target. Dragging more than 1.5 × the hit area away cancels: the glow fades over 60 ms, no activation, no haptic.
- **Hover** (only under `@media (hover: hover)`): glass gets an inner glow at 8 % centred on the pointer (following it with no lag) and the label eases to full white over `colorShift` (240 ms); a secondary button lifts −1 px with shadow `0 10px 28px rgba(0,0,0,0.5)` on `snappy`.
- **Reduced motion** (`useGlassReduced()`): glass shows the glow only (no growth, no stretch); content shows a `fill2` colour wash instead of sinking.
- **Solid glass**: the press darkens `tinted` from `#5B4AD1` to `#4A3CB0`; other surfaces keep the glow.
- **Error shake** (§4.10): `x(t) = 8 × e^(−t / 90 ms) × sin(2π × 7 Hz × t)` for 420 ms (6 px amplitude for fields), fired with the `error` haptic; none under reduced motion.
- **One lit object per screen** (§2.4.2 rule 8): `primitives/lit.ts` keeps a registry of mounted `tinted` objects. In development, two visible lit objects outside an overlay log one `console.warn`. `suppressLit()` (called by sheets and alerts in `web/27`) drops the screen's lit object to `glassThin` and fades its caustic over 180 ms until released.
- The dev-page budget: add `GlassBudgetScope` (`exempt`, `label`) to `glass/budget.ts` so development galleries, which show many live specimens at once, do not trip the six-surface warning; screens never use it.

### B. Buttons (`primitives/Button.tsx`, `SplitButton.tsx`, `HoldToConfirm.tsx`, §7.1)

| Variant | Material | Heights visual / hit | Padding | Label | Icon |
|---|---|---|---|---|---|
| `primary` (one per screen) | `glassTinted` + `CausticWrap` when over content | L 50 / 50, M 44 / 44, S 34 / 44 | L 0 24, M 0 20, S 0 14 | `headline` 17/600 `onTint` (S: `subhead` 15/620) | 20 px Regular, 8 px gap, leading |
| `secondary` | `glassThin` on black, `glassRegular` when `overMedia` | same | same | `headline` `onGlass` | same |
| `plain` | none | 44 hit | 0 8 | `headline` `iris400` on black, `onGlass` on glass | optional |
| `destructive` | `glassThin` | same | same | `headline` `onGlass` | leading `trash` or `warning-circle` in `danger` on the backing disc |
| `destructiveConfirm` | solid `danger` `#FF5C5C` | L 50 | 0 24 | `headline` black (6.94:1) | optional |
| `progress` (download) | `glassThin` capsule whose fill becomes a liquid progress | M 44 | 0 16 | `subhead` + `mono` count | `cloud-arrow-down` → spinner → check |

All capsules (`rCapsule`). On a glass host (inside a live surface) each variant renders its §2.4.2 rule 7 twin automatically (`GlassSurface` does it); the host's one lit action is the tinted twin. Every glass primitive passes a `twin` prop through to `GlassSurface`: a button repeated per item (inside a card, row or tile) takes `twin="content"` (§2.4.1 rule 1), and a scrolling page may carry at most two live page-level controls (§2.4.1 rule 2; screens enforce it, the gallery documents it next to the buttons).

States (every variant): **default** (rim and specular at the light angle); **hover** (A); **pressed** (A; the tinted fill shifts to `iris700` at 86 %); **focused** (the two-tone focus ring of §2.6 appears over a 120 ms fade, no movement); **disabled** (fill at 40 %, label `label4`, no specular, no glow, no press growth, no haptic; `tinted` becomes `glassThin` at 40 %; `aria-disabled="true"` and a tooltip with the reason, passed as `disabledReason`); **loading** (the width locks; the label fades out over `fadeOut` 120 ms and three 5 px `onGlass` dots appear 6 px apart, each bobbing 3 px on `tick` 80 ms apart; not activatable; `aria-busy="true"`; the label returns over `fadeIn` 180 ms; reduced motion: static dots); **selected** (toggle buttons such as "In library", "Following", "Favourited": stays a secondary; a 22 % `iris600` wash inside the glass spreading from the touch point as a 200 ms radial wipe, the icon morphs Regular → Fill in `onGlass` on `tick`, label `onGlass`, rim tinted `iris300` at 40 %); **error** (the label swaps to a short error such as "Couldn't save" for 2 s in `onGlass` (`onTint` on the primary), led by a `warning-circle` in `danger` on the backing disc; the same text goes to a visually hidden `role="alert"` region whose text stays 6 s; the shake and the `error` haptic).

**Toggle semantics (§7.2):** a button whose visible label changes ("Add to library" / "In library") takes no `aria-pressed` and its accessible name follows the visible label (WCAG 2.5.3).

**Split button (`SplitButton.tsx`):** one glass container holding a tinted primary segment (padding 0 20) and a trailing `glassThin` segment 50 × 50 with `caret-down`, separated by a 0.5 px `separator` (`rgba(84,84,96,0.55)`), height L 50. Pressing either lights both, the pressed one more (its glow at 16 %, the other at 8 %). Semantics: two buttons, for example "Continue, chapter 143" and "More ways to read" (`aria-haspopup="menu"`, `aria-expanded`). The trailing segment calls `onMore(anchorElement)`; the menu itself (Read from the start, Read all, Pick a chapter, Download next 10) is the `web/27` `Menu`, which blooms from this segment on `morph`.

**Progress button:** "Download" → on press the label cross-fades to "Queued" and a liquid fill enters from the left at the queue's progress (`download.start`); while saving it shows `mono` "12/40" and the level follows progress on `lens` (the `LiquidProgress` of item L); complete: the fill turns `success` at 24 %, the glyph morphs to a check on `tick`, label "Saved" (`download.done`); failed: label "Retry" led by a `danger` `warning-circle` on the backing disc, with the shake, the assertive announcement and `download.fail`. `role="progressbar"` semantics while saving (`aria-valuetext="12 of 40 pages saved"`).

**`HoldToConfirm` (§7.1, §4.6, §14.8):** `glassThin` capsule, L 50, padding 0 24, leading glyph, `headline` `onGlass` label (for example "Hold to delete"). Behaviour, as a pure state machine in `primitives/hold.ts` with `hold.test.ts`:

- Pointer down starts nothing for 200 ms (`threshold.holdStart`). A release before 200 ms with less than 8 px of movement (`threshold.holdClickSlop`) is a **click**. Moving 8 px or more before 200 ms, or a `pointercancel`, **cancels** the press: no fill, and the release does nothing.
- From 200 ms the liquid fill rises left to right inside the capsule over 1,000 ms (`iris600` at 60 % with a 3 px meniscus curve on its leading edge), so a completed hold is 1,200 ms in all (`threshold.holdConfirm`); `hold.ramp` fires a transient every 150 ms from the fill's start, rising 0.2 → 0.8; the label changes to "Keep holding…".
- A release after 200 ms and before completion is an **aborted hold**: the fill drains from its current level on `dismiss` (k 385.5, c 39.27), and the helper "Keep holding, or click once to confirm" shows under the button in `footnote` `label2` (`onGlass` inside an alert) for 2 s.
- Completion fires `hold.done`, flashes the capsule to `glassTinted`, and calls `onConfirm`.
- `Enter` and `Space` are always a click.
- Reduced motion: the fill steps in 4 visible increments (25 % each, 250 ms apart) with no meniscus.
- **The fallback is never optional (WCAG 2.5.1).** `mode="standalone"` (outside an alert: sign out everywhere, delete a collection, remove all downloads, reset offline storage): a click calls the required `onRequestConfirm()`, which opens the §7.11 confirm alert with an explicit confirm button (`web/27` provides `confirmAlert()` and makes it the default). `mode="inAlert"` (the 18+ gate, delete profile, delete member): the component renders, visibly and for everyone, the explicit confirm as a secondary button under the hold button (label from the `fallbackLabel` prop, for example "Turn on 18+"); a click on the hold button moves focus to that button and shows the helper "Hold, or use the button below"; it never opens a second alert. Nothing depends on detecting a screen reader.

### C. Icon buttons (`primitives/IconButton.tsx`, `GlassGroup.tsx`, §7.2)

| Variant | Visual | Hit |
|---|---|---|
| `nav` | `glassThin` circle 44, icon 22 Regular `onGlass` | 44 |
| `group` (`GlassGroup`) | one `glassThin` capsule 44 tall holding 2 to 4 icons 44 px apart, 8 px internal gap; one live surface for the whole group | 44 each |
| `plain` | no background; icon 22 `g800` `#BDBDC6` on black; hover a `fill4` circle 40 | 44 |
| `row` | `fill3` circle 32, icon 18 | 44 |
| `toggle` | any of the above; off = Regular `g800`, on = Fill in its colour (`iris400` for pin and follow, `streakCore` `#FFD166` for favourite, `success` `#3DDC84` for downloaded); on glass the coloured glyph sits on the backing disc | as above |
| `badged` | any; a count badge (item M) at the top-right | as above |

States: default; hover (inner glow 8 % on glass, the `fill4` circle on plain); pressed (glass grows +17 px on the longest side capped at 0.35 × side, so a 44 px button reaches about 1.35×; glow 16 % from the touch point; Duotone → Fill morph; plain icons sink to 0.92); focused (ring, concentric); disabled (icon `g500`, no glow); loading (the icon becomes a 16 px liquid ring spinner); selected (Fill glyph in its colour with a `tick` pop 1 → 1.12 → 1); error (the glyph swaps to `warning-circle` in `danger`, on the backing disc when on glass, for 2 s, with the shake, and "Couldn't {action}" goes to the assertive region). In a `GlassGroup`, a pressed icon's glow spreads into its neighbours at 30 % (one container, one light). Constant-label toggles (favourite star, pin, notify bell, bookmark, the password eye) carry `aria-pressed` with a fixed accessible name ("Favourite", "Pin source", "Notify me", "Bookmark", "Show password"). `nav` accepts `onLongPress` with the 450 ms threshold (500 ms on web touch, `threshold.stackLongPressWebTouch`) for the back menu that `web/29` wires; the long press fires `stack.open`.

### D. Inputs (`primitives/TextField.tsx`, `TextArea.tsx`, §7.3)

Form fields are content-layer wells, never glass. `TextField` types `text`, `password`, `url`, `number` (go-to):

- **Text:** min height 50, radius 14 squircle, fill `fill3` on black, `fill2` on a solid sheet, `wellOnGlass` `rgba(0,0,0,0.35)` inside T4/T5 glass (read from the glass host context); padding 0 16; text `body` 17 `label1`; placeholder `label3` (`label2` inside `wellOnGlass`); label above in `footnote` 13/600 `label2` (`onGlass` on glass) with a 6 px gap; helper below in `footnote` `label3` (`onGlass` on glass); `autocomplete`, and `autocapitalize="none"` for usernames and URLs.
- **Password:** trailing eye toggle (plain icon 22, hit 44, `aria-pressed`, fixed accessible name "Show password"; the glyph swaps `eye` / `eye-slash`, the name does not); toggling keeps the caret position.
- **URL:** leading `globe` glyph, `inputmode="url"`, trailing status (a 16 px spinner while validating, a `success` check when reachable).
- **Number / go-to:** 96 wide, `mono` 13, `inputmode="decimal"`, centred; `Enter` jumps, `Esc` clears.
- **Text area (`TextArea.tsx`):** min 3 rows (≈ 96 px), grows with content up to 8 rows on `snappy`, then scrolls; a counter in `caption1` `label3` bottom-right from 80 % of the limit, `warning` at 95 %; with `submitOnEnter` (the AI prompt), `Enter` submits and `Shift+Enter` inserts a newline.
- **States:** default; hover (the well brightens to `fill2`); focused (the focus ring, `caret-color: var(--mm-color-iris400)`, the well to `fill2`); disabled (40 %, not focusable); loading (a trailing 16 px spinner); selected text (`::selection` `iris600` at 40 %); error (`errorRing` 1.5 px `danger`, the message below in `footnote` `danger` led by `warning-circle`, `aria-invalid="true"` and `aria-describedby` on the message; on submit the field shakes at 6 px and the first invalid field takes focus); validation messages appear over `fadeIn` and push content down on `snappy`.
- The autofill override from `web/25` applies.

### E. Search fields (`primitives/SearchField.tsx`, §7.4)

Variants (the orb that morphs into the bottom field is the dock's, `web/29`; this step builds the fields):

- `bottom` (phone and mobile web): a 50 px `glassRegular` capsule, full width minus 21 px insets, riding on top of the keyboard. On iOS Safari it is positioned from the visual viewport: `bottom: calc(100lvh - var(--vv-h) - var(--vv-top))`, with `--vv-h` and `--vv-top` written from `visualViewport.height` and `visualViewport.offsetTop` by one `resize` + `scroll` listener on `visualViewport`, at most one write per animation frame, only while the field is focused; Chrome on Android relies on `interactive-widget=resizes-content` (set in `web/25`), which yields `bottom: 0` above the keyboard. A trailing plain "Cancel" button. Dragging down on the field dismisses the keyboard first, then calls `onCollapse` when the projected drag passes 80 px.
- `page`: a 56 px `glassRegular` capsule centred at the top of the content (the desktop Search screen).
- `filter`: a 44 px content well (`fill3`) with a leading magnifier and a trailing clear × (hit 44) when non-empty.
- `sidebar`: a 36 px `fill3` capsule reading "Search" with the `mod+k` keycap from `formatKeyCombo` ("⌘K" on macOS, "Ctrl K" elsewhere); it is a button that calls `onOpenPalette` (the palette is `web/29`).

States: idle (placeholder "Search series, sources and dialogue"); focused; typing (`onQuery` debounced 300 ms, `Enter` fires at once); searching (the magnifier becomes a 16 px liquid ring spinner); results; no results; error; offline (a `warning` `wifi-slash` on the backing disc replaces the magnifier and the helper reads "Offline: searching this device only").

### F. Chips (`primitives/Chip.tsx`, `ChipRow.tsx`, §7.5)

| Chip | Visual | Behaviour |
|---|---|---|
| `filter` (multi-select) | 32 tall visual inside a 44 tall hit box, `rCapsule`, `fill2`, `subhead` 15/460 `label1`, 12 px horizontal padding, optional 16 px leading glyph | Selected: becomes the `glassThin` look with a leading check that grows in on `tick`, label `wght` 600 |
| `choice` (single-select group) | same size; the selected one sits under a shared droplet (`glassFilm` clear capsule) | The droplet slides between chips on `tab` (k 195.0, c 21.78), stretching `scaleX = 1 + min(abs(v) / 2000, 0.25)`, `scaleY = 1 / √scaleX` |
| `count` | filter chip + a `mono` count in `label2` after a 6 px gap | "Pinned 4", "With results 12" |
| `input` (removable) | filter chip + a trailing × (16 px glyph; hit 44 × 44 extending beyond the chip) | × removes it: the chip shrinks on `dismiss`, siblings close the gap on `snappy` |
| `assist` | 32 tall, `glassThin` outline style (no fill, rim only), leading glyph | "Next 10", "All unread", "Whole book" |
| `tag` (genre, status) | 24 tall, `fill4`, `caption1` uppercase +0.08 em `label2`, 8 px padding | Non-interactive, or a link (hover `fill3`, focus ring) |

Chips live in scrolling rows, so the selected filter chip's glass, the assist chip's rim and the choice droplet are **content twins** (§2.4.1 rule 1): the same capsule, rim and inner light, sliding and stretching as described, with no backdrop read. `ChipRow` scrolls horizontally with momentum, rubber-bands at both ends where the platform does, masks its trailing 24 px with a gradient to hint at more, and never snaps; it pads 8 px vertically so focus rings are never clipped. States: default; hover `fill3`; pressed sinks to 0.96 on `press` while a selected chip's glass swells; focused ring; disabled 40 %; loading (a count chip's count becomes a 12 px spinner); selected as above; error (the chip's glyph becomes `warning-circle` in `danger` and a tooltip explains). Selection fires `select`.

### G. Segmented control (`primitives/Segmented.tsx`, §7.6)

- **Track:** `fill3` capsule (`wellOnGlass` inside T4/T5 glass), visual height 36 (compact 32 inside sheets) inside a 44 px hit row, 2 px inner padding.
- **Thumb:** a `surface3` `#222229` capsule at rest with a 0.5 px rim; label `subhead` 15/620 `label1` on the thumb, `label2` elsewhere.
- **Physics:** tapping a segment moves the thumb on `tab`. Dragging the thumb turns it into **transient glass** (a live `GlassSurface` T1 `glassFilm` clear, registered in the budget only while dragged), following on `track`, stretching `scaleX = 1 + min(|v| / 2000, 0.25)`, with a `select` haptic at each segment boundary; release projects (`project()`) to the nearest segment and settles on `tab`.
- **Segments:** 2 to 5 (more than 5 must be a menu: the component throws in development); equal widths, or content-fit widths when labels differ by more than 40 %.
- **States:** default; hover (an unselected segment gets `fill4`); pressed (the pressed label sinks to 0.96); focused (the ring around the whole control; arrows move the selection; `Home`/`End` jump); disabled (40 %, the thumb stays); loading (the selected label is replaced by a spinner while its data loads, the thumb stays); selected (the thumb); error (the thumb springs back to the previous segment on `tick` and the caller shows a toast).
- **Roles:** `role="radiogroup"` with `role="radio"` segments, or `role="tablist"` with `role="tab"` when it switches panels (`as="tabs"`), roving `tabindex`.
- **Vertical variant** (`orientation="vertical"`, the desktop Search scopes in a 220 px column): 40 px rows (44 px hit), `role="tablist"` with `aria-orientation="vertical"`, the `glassFilm` clear droplet travelling vertically on `tab` (drawn as its content twin: clear rim and inner light, no backdrop read, because a selection droplet is never a second backdrop read, §2.4.2 rule 7), `↑`/`↓` moving between scopes.
- The projection and boundary logic is pure (`segmented-math.ts` with a test).

### H. Cards (`primitives/cards/`, content layer, §7.7)

Cards sit on black or on the ambient field and are never glass. Default slab: `surface1` `#131317` with `slabBorder` (1 px `rgba(255,255,255,0.06)`), radius `rXl` 26, padding 12; media inside at radius 14.

1. `SeriesCard` (grids): a `Poster` (item I) + 8 px + title `footnote` 13/600 in 2 lines + meta `caption1` `label3` in 1 line. No slab: the poster is the card.
2. `ContinueStack` (Home, Library): 280 × 132 on phones, 320 × 148 on desktop: the cover 88 × 132 on the left; behind it the next page's thumbnail peeks 8 px right and 6 px down, rotated 2°, like a deck; on the right the title `headline`, "Ch 142 · p. 18 of 40" `footnote` `label2`, a 24 px progress ring (3 px stroke `iris500` on `fill1`) around the chapter number, and a plain "Continue" button. **Unopened next chapter** (`page_count == 0`): "Up next · Ch 143", the ring shows its track only, the button reads "Start", no ratio is computed. Slab `surface1`. No horizontal swipe. "Previously on" is the first row of its long-press context menu, sits behind a trailing ⋯ (a 44 px hit area on its top-right corner) and is the `p` key on a focused stack (the recap itself is `web/41`; the card exposes `onPreviouslyOn`).
3. `WorldCard` (AI and "For you"): 300 × 132: cover 80 × 120, title `headline` in 2 lines, "Manhwa · Ongoing" `caption1`, "120 ch · ★ 8.4" `mono` 13, up to 3 tags, the `why` line in `footnote` italic `label2` after the machine sparkle glyph (`sparkle` in `machine` `#5CE1E6`; the AI surfaces themselves are `web/28`). **Available** variant: a small "On MangaSource" source chip (and "+2"), and the whole card opens the series. **Info-only** variant: a dashed 1 px `slabBorder`, "Not on your sources" `caption1` `label3`, and two plain buttons "Search my sources" and "Read on {site}" (external).
4. `ResultCard` (search): 112 wide × 208: a 112 × 168 poster + title in 2 lines `footnote`; its source glyph badge is hidden inside source groups (`hideSource`).
5. `StatCard`: a 2-up grid cell, slab radius 26, padding 16: glyph 20 `iris400`, a `numeral` value, a label `footnote` `label2`, an optional 7-point sparkline 24 px tall in `iris500`.
6. `CollectionCard`: a 21:9 slab with a fanned stack of up to four member covers on the left (each 72 × 108, rotated −8°, −3°, 3°, 8°, overlapping 40 %), the name `title3` and "12 series" on the right. The fan opening on the zoom into the collection (`celebrate`) is exposed as `fanOpen` for `web/32`.
7. `NotificationCard`: one per series: cover 44 × 66, series title `headline`, "3 new · Ch 141–143" `footnote` `iris400`, time `caption1` `label3`, chapter chips that each open the reader. (Its swipe actions are `web/28`.)
8. `SourceRowCard`: a 64 tall row: a 44 px source logo (radius 10); the name `headline` followed by a 10 px **health bead** (a content twin: `success` ok, `warning` failing, `danger` dead, `g600` unknown; a 1 px `warning` ring when `health.demoted`; accessible text "working", "having trouble", "not working", "not checked yet", plus ", skipped by search" when demoted), and the source's `language` as a `caption1` tag ("EN"); description `footnote` `label2` in 1 line; an 18+ tag when mature; the pin toggle icon. **Logo fallback** (no `icon_url`, or the logo fails to load): a monogram tile, the source name's first letter in `headline` 600 `label1` on `surface3`, radius 10, tinted by a hash of the source id into the speaker palette (§2.1.5) at 24 %.
9. `HistoryTile`: a poster with a 3 px progress line along its bottom edge; a 36 px play orb bottom-right ("p. 18" or "42 %") drawn as a content twin on the cover-overlay backing (`rgba(0,0,0,0.86)` disc, 0.5 px `rgba(255,255,255,0.22)` rim, inner light, no backdrop read; `label1` on it 13.96:1 over a white cover); the title and "Ch 12 · 3 h ago" below.

States (all cards): default; hover (desktop: lift −2 px on `snappy`, shadow `0 12px 32px rgba(0,0,0,0.5)`; posters tilt toward the pointer up to 6° with the specular highlight sweeping across the cover); pressed (sinks to 0.97); focused (ring + scale 1.04); disabled (unavailable source, pinned-but-hidden: 55 % opacity, not activatable, the reason in `caption1`); loading (a skeleton of the same shape); selected (select mode: a 2 px `iris500` inset ring + a 24 px check orb top-right that pops on `tick`, media dimmed to 80 %); error (cover failed: a `surface2` fill with a 24 px broken-image glyph in `g600` centred, the title still shown).

### I. Posters (`primitives/Poster.tsx`, `PosterGrid.tsx`, `poster-throw.ts`, §7.8)

- **Geometry:** 2:3, radius 14 squircle, a 1 px inner highlight `rgba(255,255,255,0.08)` along the top edge, no outer border. Widths: phone 124 in rails and by columns in grids; tablet 148; desktop 168; wide 184.
- **`PosterGrid`** (the one rule for every poster grid on tablet and desktop): `grid-template-columns: repeat(auto-fill, minmax(var(--grid-min), 1fr))`, gap 20 px (`s7`) on tablet and desktop and 12 px on phones; `--grid-min` 148 px on tablet, 152 px on desktop and wide at Comfortable density, 112 px at Compact. That yields 5 columns at 1024 px (collapsed sidebar), 6 at 1440 px, 8 at 1920 px. Content width `W = min(viewport − sidebarOffset, 1440) − 2 × margin` (`sidebarOffset` 304 expanded or 100 collapsed; margin 32 desktop, 40 wide), exposed as a CSS custom property for screens.
- **Image arrival:** the placeholder is `surface2` with the ambient hue at 12 %; the image arrives with opacity 0 → 1 over `fadeIn` and scale 1.02 → 1 on `snappy`. Each poster registers its `palette.lMax` with `useLbItem` (from `web/25`), so bars above it thicken over pale covers.
- **Overlays** (every overlay sits on an opaque backing, because a cover can be white): a status tag top-left (item M, the cover recipe), an "N NEW" badge top-right (`iris400` capsule, black `caption1` 700, "99+"), the downloaded droplet bottom-left (`success` 16 px on a 22 px `rgba(0,0,0,0.72)` circle), an 18+ capsule top-left when mature and the gate is open (the status-tag cover recipe in `mature` `#FF5C93`), the favourite star and the `age-gate` glyph each on a 22 px `rgba(0,0,0,0.72)` disc, and progress as a 3 px `iris500` bar inside a 5 px `rgba(0,0,0,0.86)` track along the bottom inside the radius.
- **Corner conflicts:** on desktop hover and keyboard focus, the status tag and the "N new" badge fade out over 120 ms while the favourite star (top-left, 8 px inset) and the follow bell (top-right, 8 px inset) fade in on 32 px `rgba(0,0,0,0.86)` discs; the 18+ capsule moves to the bottom-right while those buttons show. In select mode the status tag, badge, star and bell hide, the check orb takes the top-right, and the new-chapter count stays in the accessible name ("Solo Leveling, 3 new").
- **Hover (desktop):** pointer tilt up to 6° (`rotateX`/`rotateY` on `track`), a white radial specular highlight at 12 % following the pointer, lift −2 px; after 600 ms of rest a peek capsule (the content twin of `glassThin`) grows out of the bottom edge on `morph` with "Continue Ch 12" or "Open" and a ⋯ button. The peek follows WCAG 1.4.13: `Esc` closes it without moving the pointer, it stays while the pointer is over it or within 8 px of it, and it never disappears on its own while hovered or focused.
- **Press and lift (touch), physics in `poster-throw.ts` with `poster-throw.test.ts`:** a release before 450 ms without passing the slop is a tap (the growth between 150 and 450 ms is only a preview). At 150 ms the poster starts growing toward 1.06 (reached at 450 ms) and its shadow deepens to `0 18px 40px rgba(0,0,0,0.55)`, firing `press.lift`. At 450 ms it calls `onContextPreview()` (the `web/27` context menu takes `dimContext`, raises the poster to 1.12 and blooms the `glassThick` menu beneath; `longpress.open` fires there). While lifted the poster is a physical object: drag moves it 1:1 (`physics/tracker.ts`); on release, `decideThrow({ centre, velocity, viewport, targets })` returns: `open` when the projected centre is above the top 20 % of the screen or `vy ≤ −1,200 px/s` (`onThrowOpen(velocity)`; the zoom inherits the velocity); `away` when `allowAway` (AI cards) and the projected centre passes a side edge or `|vx| ≥ 1,200 px/s` (`onThrowAway`, "Not interested"); `target` when the poster is within 64 px of a registered friend-orb target (`physics/magnet.ts`, `magnet.capture` on capture, `magnet.drop` on release, `onDropOnTarget(id)`); otherwise `drop`, back into place on `zoom`. A committed throw fires `throw.commit` with intensity `clamp(0.3 + |v| / 4000, 0.3, 1.0)`. Reduced motion: the outcome happens with a 150 ms fade.
- **Keyboard:** focus scale 1.04 + ring; `.` or `Shift+F10` calls `onContextPreview` from the item; `Enter` opens.
- **States:** as the cards in H.

### J. Rails (`primitives/Rail.tsx`, `RailGroup.tsx`, §7.9)

- **Header:** `title2` rendered through `LetterReveal` (first appearance per session, item O) with `revealKey`, an optional subtitle `footnote` `label2` ("Because you read Solo Leveling"), and a trailing "See all" plain button; the scroller 12 px below.
- **Scroller:** leading and trailing insets equal to the screen margin, gap 12 px (phone) or 16 px (desktop); posters peek at the trailing edge (2.8 posters visible at 390 px wide); 8 px vertical padding so focus rings are never clipped; `overscroll-behavior-x: contain` so a trackpad flick at the start never navigates back.
- **Physics:** free native momentum; on `scrollend`, `railSnap(scrollLeft, 0, posterWidth + gap)` from `physics/project.ts` gives the snap target and Motion's `animate(scrollLeft)` carries it there on `settle` (k 322.3, c 35.90). No snapping while the pointer or a finger is down.
- **Desktop arrows:** content-twin 44 px circles (`rgba(19,19,23,0.62)` fill, 0.5 px `rgba(255,255,255,0.22)` rim, inner light, no backdrop read; hover `rgba(40,40,48,0.72)`), fading in over `fadeIn` at each end when the pointer enters the rail and out 300 ms after it leaves; they do not count toward the glass budget; each press scrolls by (visible count − 1) posters on `page`.
- **Keys (`RailGroup`):** each rail is one tab stop (roving `tabindex`); `←`/`→` move focus within a rail; `↑`/`↓` move between rails of the same `RailGroup` keeping the column (the column index mapping is a pure function with a test).
- **States:** loading (4 to 8 skeleton posters with the header already in place); empty (the rail renders nothing, unless it is an AI rail, which renders its `unavailable` slot: the `AiNotice` of `web/28`); error (a 120 px tall inline card "Couldn't load this row" with a "Retry" plain button); partial (the loaded posters plus a trailing skeleton while tier-2 sources answer).

### K. Skeletons "wet glass" and the entrance wave (`primitives/Skeleton.tsx`, `wave.ts`, §7.18, §4.8)

- `Skeleton`: `aria-hidden`; the region it fills carries `aria-busy="true"`; shapes and radii match the content they stand for; fill `surface2` `#1A1A20`; a sheen band 40 % of the element's width, `linear-gradient(100deg, transparent, rgba(255,255,255,0.05), transparent)`, sweeping left to right every 1,400 ms (`shimmer`, linear; 2,800 ms for AI skeletons), phase-offset 60 ms per row so the sheen travels down a list; skeletons appear only after 180 ms. Reduced motion: static `surface2`.
- `wave.ts`: `waveDelays(items, cause)` → `delay_i = min(distance_i / 1.6 px·ms⁻¹, 240 ms)` from the cause point (the touch point for taps, the source element's centre for route arrivals, the top-left of the list for data arrivals); only items inside the viewport take part. `useWave(containerRef, cause)` runs each item's entrance through `play()` (Wave row): opacity 0 → 1 over `fadeIn` and a 12 px translate toward rest from the cause's direction plus scale 0.98 → 1 on `snappy`. Exits never stagger. Reduced motion: everything fades together over 150 ms. `wave.test.ts` checks the delays and the 240 ms cap.

### L. Progress (`primitives/Progress.tsx`, `LiquidProgress.tsx`, §7.19)

| Kind | Visual | Motion |
|---|---|---|
| `linear` | 4 px capsule track `fill1`, fill `iris500` (variant `success`), a 1 px `iris300` leading highlight | width on `snappy` |
| `hairline` (reader, novel running head) | 2 px, fill `iris500` at 80 % | follows on `track` |
| `ring` | 24 or 32 px, 3 px stroke, track `fill1`, arc `iris500`, round caps | arc on `snappy` |
| `LiquidProgress` (downloads meter, storage, hold-to-confirm, progress button) | inside a capsule, the filled part is `iris600` at 60 % with a meniscus: its leading edge curves 3 px and wobbles when the value changes | the level follows on `lens` (k 223.8, c 20.94, bounce 0.3), so a jump sloshes once; the meniscus bulge is `3 px + clamp(velocity / 400, −3, 3) px` |
| `spinner` (liquid ring, indeterminate) | a 16 or 24 px ring whose 90° arc stretches to 270° and back while rotating once per 900 ms | loop; reduced motion: a static ring pulsing opacity 0.4 ↔ 1 over 1.2 s |
| `dots` (button loading) | 5 px `onGlass` dots 6 px apart | each bobs 3 px on `tick`, 80 ms apart |
| `segmented` (read-all scrub, storage breakdown) | a capsule divided into segments with 2 px gaps | segment widths on `snappy` |

`role="progressbar"` with `aria-valuenow` and `aria-valuetext` ("12 of 40 pages saved"). States: default (determinate); loading (indeterminate: the spinner, or a 30 % band sweeping a linear track every 1.2 s); complete (the fill turns `success` and a check springs in on `tick`); paused (fill `warning` at 60 %, the meniscus still); error (fill `danger`, a retry glyph at the end); disabled (track and fill at 40 %). Reduced motion: values jump, no meniscus wobble. Indicators have no hover, pressed or selected state.

### M. Badges and markers (`primitives/Badge.tsx`, §7.20)

| Badge | Visual |
|---|---|
| `count` | min 18 × 18 capsule, `iris400` fill, black `caption1` 700 (8.82:1); "9+" above nine (dock and bell), "99+" on posters; pops 1 → 1.25 → 1 on `tick` when the count changes (Count pop) |
| `dot` | an 8 px `iris400` circle with a 2 px black ring |
| `new` | "N NEW" capsule, `iris400` with black text, top-right on posters |
| `status` | a 22 tall capsule, `caption1` 600 uppercase +0.06 em: READING `iris400`, COMPLETED `success`, ON HOLD `warning`, PLAN TO READ `info` `#6CB8FF`, DROPPED `g700`, UNREAD `g800`. On black and slabs: the colour at 18 % over black with the colour as text. On a cover (`onCover`): no wash; colour text on a `rgba(0,0,0,0.86)` capsule with a 1 px rim in the colour at 40 % |
| `mature` | a 20 tall capsule, `mature` at 18 % with `mature` text "18+" on black; on a cover the status-tag cover recipe in `mature`; or the `age-gate` glyph 14 on a 22 px `rgba(0,0,0,0.72)` disc |
| `source` | a 20 tall capsule `fill3`, a 12 px favicon (or the 12 px monogram tile) + the source name `caption1` |
| `downloaded` | the `droplet` glyph 14 `success`; on a cover on a 22 px `rgba(0,0,0,0.72)` circle |
| `offline` | "Saved copy · 2 h" capsule, `warning` at 18 % |
| `role` (Admin, You, This device) | a 20 tall capsule `fill2`, `caption1` 600 `label1` |
| `friend` | an 18 px friend orb with a `bloom` ring (item N) |

Badges are never the only signal: every badge contributes a text fragment to its host's accessible name through `badgeLabel()` ("Solo Leveling, 3 new chapters, downloaded"). States: default; loading (a 10 px spinner in place of a count); updated (the `tick` pop); disabled (40 % with the host); error (a `warning` dot replaces a count that failed to load).

### N. Avatars and profile orbs (`primitives/ProfileOrb.tsx`, `GoalRing.tsx`, §7.26, §9.2.2)

- **Profile orb:** a circle with the preset's two-colour gradient (top-left → bottom-right) and a Light-weight glyph in the preset's glyph colour; sizes 18, 20, 24, 32, 44, 56, 72, 96, 112, 128, 132; a 2 px ring in the profile's mood colour at 60 %; on glass surfaces the orb gets a glass bezel (0.5 px rim + specular).
- **Presets** (from the tokens `color.avatar.<preset>`; these are the values): Violet Spark `#8B5CF6 → #D946EF` `sparkle` white; Cyan Rocket `#06B6D4 → #0EA5E9` `rocket-launch` dark; Rose Heart `#F43F5E → #EC4899` `heart` white; Amber Coffee `#F59E0B → #F97316` `coffee` dark; Emerald Cat `#10B981 → #14B8A6` `cat` dark; Ember Flame `#EF4444 → #F59E0B` `flame` dark; Steel Blade `#94A3B8 → #475569` `sword` dark; Phantom `#6366F1 → #334155` `ghost` white; Arcane Wand `#A855F7 → #6366F1` `magic-wand` white; Lunar Moon `#0284C7 → #4338CA` `moon` white; Starlight `#FACC15 → #F59E0B` `star` dark; Bookworm `#14B8A6 → #0891B2` `book-open` dark ("dark" = `rgba(0,0,0,0.85)`, "white" = `#FFFFFF`).
- **Idle drift** (`drift` prop, the picker only): ±3 px on a sine with a 5 to 7 s period and a random phase; frozen under reduced motion.
- **Friend orb:** the same orb with a `bloom` `#FF9ED8` ring; 18 px as the Friend badge, 32 px in activity rows, 56 px as drop targets.
- **Names** under or beside an orb and in chips: one line truncated with an ellipsis; the accessible name carries the full name.
- **`GoalRing`:** with a daily goal set, a 2 px ring 3 px outside the orb fills clockwise from 12 o'clock with today's minutes toward the goal, in `streak` `#FF8A3D` at 80 %; on `goal.met` it closes and fills solid for 600 ms (`success`, then a `shimmer`), then stays closed in `streakCore` `#FFD166` for the rest of the local day. Accessible name "Today: 8 of 10 minutes". On glass hosts other than the plateau and the docked sidebar it sits on a backing disc 8 px wider than the ring (`onDisc` prop).
- **States:** default; hover (scale 1.04, or 1.08 with `size >= 96` on the picker, + the specular sweep); pressed (grows +12 px); focused (the ring outside the mood ring); disabled (40 %); loading (the glyph becomes a spinner); selected (the mood ring becomes 3 px `iris300`); error (a warning glyph overlay).

### O. Tooltips and keycaps (`primitives/Tooltip.tsx`, `Keycap.tsx`, §7.27)

- **Tooltip** on `@base-ui/react` Tooltip (positioning, `aria-describedby`, the hoverable popup): a `glassThin` T2 capsule, min height 36, padding 9 12, `footnote` `onGlass`, 8 px from its target; delays by level: 0 ms for icon-only buttons on keyboard focus, 150 ms for the dock and the collapsed sidebar (`level="bar"`), 600 ms for everything else on hover; appears on `snappy` from scale 0.9 while materialising; follows its target if it moves. WCAG 1.4.13: `Esc` closes it without moving the pointer or focus; it stays while the pointer is over it or within 8 px of it; it never disappears on its own while its target is hovered or focused. If Base UI's defaults cannot meet one of these rules, implement that rule on top of it; do not drop the rule. A tooltip is a live glass surface in the budget.
- **Keycap:** `mono` 12/600 `label1` on `surface3`, radius 6, min width 20, height 20, a 0.5 px rim; combos separated by 4 px; macOS shows `⌘ ⌥ ⇧ ⌃` (through `formatKeyCombo`). Used in tooltips and trailing menu rows.

### P. The heading reveal: `primitives/LetterReveal.tsx` (§10.1, §15.7)

Start from the web code in §10.1 (the component and its CSS, including the `wait`/`run`/`done` states, the 1,500 ms CSS fail-safe, the `sr-only` copy with `aria-hidden` letters, the word wrappers that keep Latin words on one line and let CJK runs break between graphemes, the per-word mode above 60 graphemes at 40 ms per word, and the glint) and complete it:

| Parameter | Value |
|---|---|
| Unit | grapheme (`Intl.Segmenter`) |
| Opacity | 0 → 1 over `fadeIn` (180 ms `cubic-bezier(0.2, 0, 0, 1)`) |
| Translate | +0.40 em → 0 on the `letter` spring `{424 ms, bounce 0.12}` (k 219.6, c 26.08; CSS `var(--mm-spring-letter)` over `var(--mm-spring-letter-ms)`) |
| Blur | 12 px → 0 on the same spring |
| Scale | 0.96 → 1 on the same spring |
| Stagger | 24 ms per grapheme; spaces take no time |
| Glint | 120 ms after the last letter settles, a 30° band (white at 18 %, 40 % of the heading's width) sweeps once, left to right, over 500 ms |
| Colour on hover and state | `colorShift` 240 ms |
| Size and tracking | the role's responsive size with tight tracking (`largeTitle` −0.020 em, `title2` −0.010 em, `display` −0.025 em) |

1. **Starts at first visibility:** an `IntersectionObserver` with `threshold: 0.25`; never on mount.
2. **At most two at once (§15.7):** a module-level slot counter; when a third heading becomes visible it waits in a queue and starts when a running reveal ends (the end is `n × stagger + 345 ms + 120 ms + 500 ms`), if it is still visible; otherwise it completes at once.
3. **Once per session per profile:** keys `"{profileId}:{screenId}:{headingKey}"` in `sessionStorage["mm.glass.revealed"]`; the hero title and chapter seams (`revealKey` omitted) play whenever their text changes or they enter the viewport.
4. **Interruptibility:** scrolling the heading fully off-screen, tapping it, or navigating completes it instantly (`data-reveal="done"`); keyboard focus arriving on the heading (route focus) does not.
5. **Live variant** (`mode="live"`, for the Home spotlight title in `web/31`): Motion 13 `animate` per letter with the generated physical `spring.letter`, so new text retargets letters mid-flight; the old letters leave together over `fadeOut` with blur 4 px while the new wave starts; same visibility and reduced-motion decisions.
6. **Reduced motion** (OS or `data-motion="reduced"`): the full text at once, no glint.
7. Placements are wired by the screens (tab-root and pushed large titles, rail headers, the hero title, series and book titles, chapter seams, onboarding, For you, Statistics, Wrapped, the splash wordmark, Setup, the picker title); this step builds the component and uses it in `Rail` headers.

### Q. The typing reveal: `primitives/TypedHeadline.tsx` (§10.2)

Start from the web code in §10.2 (component and CSS) and keep its behaviour exactly: the string laid out in full from frame 0 with the untyped tail transparent; every 50 ms the next grapheme fades in over 40 ms while scaling 0.8 → 1 on `tick`; the caret is a 2 px × 0.72 em capsule in `iris400` `#A99BFF` with `inset 0 0 0 0.5px #fff` and a `0 0 6px rgba(169,155,255,0.45)` glow, moving by `translate` on the `track` spring's `linear()` easing; when typing ends it blinks three times (530 ms on, 530 ms off) and dematerialises (blur 0 → 6 px, opacity 1 → 0, 350 ms `dematerialize`); a cap of 48 graphemes, the tail fading in as one span over 200 ms when the caret reaches grapheme 48; **skip** on a `pointerdown` on the headline, or on a key press while focus is on the headline or on `document.body`, or on navigating away (the caret still blinks and leaves); **focus arriving on the headline never skips it**; once per app session per profile per placement (`sessionStorage['mm.glass.typed']`, recorded when typing starts); `aria-label` carries the full text and the typed spans are `aria-hidden`; no haptic and no sound per character; nothing animates until the effect sets `data-typing="run"`, in the same tick as the interval; the 1,500 ms fail-safe; reduced motion shows the full text at once with no caret. Placements (Home greeting, Login heading, onboarding's first step, the Wrapped cover, the recap deck heading) are wired by their screens.

### R. The primitives gallery

`frontend/src/app/(preview)/dev/glass-primitives/page.tsx` (a server component that calls `notFound()` when `process.env.NODE_ENV === "production"`; no session needed) renders `frontend/src/skins/glass/dev/Gallery.tsx` inside `<div data-skin="glass">` with `LensDefs`, `GlassMotionConfig`, `AmbientProvider` + `AmbientField` (the brand aurora), the light-angle hook, the motion-timings overlay and a `GlassBudgetScope exempt label="gallery"`. One section per family, anchored and filterable with `?section=`: `buttons`, `hold`, `icon-buttons`, `inputs`, `search`, `chips`, `segmented`, `cards`, `posters`, `rails`, `skeletons`, `progress`, `badges`, `avatars`, `tooltips`, `reveals`, `cursors` (item T). Each section shows every variant in every state (forced through `forceState` for hover, pressed and focus; real props for disabled, loading, selected and error) over three grounds side by side: black `#000000`, the ambient field, and a white `#FFFFFF` panel (to show the legibility dim and the backing discs). The `reveals` section has a `TypedHeadline` "Good evening, Yash" (`typedKey` `gallery:greeting`) at the top, and three rails far below the fold (their headers use `LetterReveal` with distinct `revealKey`s) placed so that all three enter the viewport together when scrolled, plus a 70-grapheme heading for the per-word mode. A toolbar (content layer, 44 px controls) toggles Solid glass, Increase contrast and Reduce motion by setting the `html` attributes.

### S. Browser checks

- `frontend/e2e/glass-reveals.spec.ts` (the §15.8 check, adapted to the gallery until the Glass Home exists; a fresh context per test, desktop 1440 × 900): 200 ms after navigating to `/dev/glass-primitives?section=reveals`, the greeting's 10th grapheme still has computed `opacity` below 0.1 (with focus moved to the heading at 100 ms, typing still runs); whenever grapheme 6 has opacity above 0.9 the caret's computed `translate` is past grapheme 0; after 3 s every grapheme is at opacity 1; a `pointerdown` on the headline completes it; a key press with focus on `document.body` completes it. A rail header below the fold keeps `data-reveal="wait"` until scrolled 25 % into view, then becomes `run`; when all three rail headers enter together, at most two are `run` at any sampled moment and the third runs after one finishes. A reload in the same context shows every heading at rest at once (`data-reveal="done"`, `.typed.is-done`). With `reducedMotion: "reduce"`: full text at once, the caret not displayed. The 70-grapheme heading animates per word.
- `frontend/e2e/glass-primitives.spec.ts`: at 390 × 844 with touch emulation, every `button`, `a[href]`, `input`, `textarea` and `[role=button|radio|tab|switch|slider|checkbox]` in the gallery has a bounding box of at least 44 × 44 px; the keyboard works: `Tab` shows the two-tone ring on every control, the segmented control moves with arrows and `Home`/`End`, a rail is one tab stop with `←`/`→` inside and `↑`/`↓` between rails keeping the column, a tooltip closes on `Esc` and stays while the pointer rests on it; `HoldToConfirm`: `Enter` is a click (calls `onRequestConfirm`), a 1,300 ms pointer hold confirms, a 600 ms hold aborts and shows the helper for 2 s, 10 px of movement before 200 ms cancels with no click; in `inAlert` mode the fallback button is visible without any interaction; the error state sets the assertive region's text; toggles carry `aria-pressed` with fixed names; an invalid field has `aria-invalid` and `aria-describedby`.
- Vitest: `hold.test.ts`, `poster-throw.test.ts`, `wave.test.ts`, `segmented-math.test.ts`, `rail-columns.test.ts`.

### T. Pointer cursors (§7.40, web only)

Tailwind 4's preflight resets buttons to `cursor: default`, so Glass sets every cursor explicitly, once, in `glass.css` under `[data-skin="glass"]`, as one contract later steps only opt into:

- `cursor: pointer` on `button`, `a[href]`, `summary`, `label[for]`, `[role=button|link|tab|switch|checkbox|radio|menuitem|menuitemcheckbox|menuitemradio|option]` and every element `usePress` marks (posters, cards, rows, orbs, chips);
- `cursor: not-allowed` on `:disabled`, `[aria-disabled="true"]` and `[data-disabled]` (this wins over pointer);
- `cursor: text` on `input:not([type=checkbox]):not([type=radio]):not([type=range])`, `textarea` and `[contenteditable="true"]`;
- a `data-cursor` attribute for the rest: `grab` (and `grabbing` while `[data-dragging]` or `:active`), `ns-resize`, `zoom-in`, `zoom-out`, `none`, `all-scroll`. This step applies `data-cursor="grab"` to the segmented thumb and the lifted poster; `web/27` applies it to slider, switch and fill-slider thumbs, the speed dial (`grab`), the scrub rail (`ns-resize`) and the image viewer (`zoom-in` at 1×, `zoom-out` when zoomed); `web/28` to reorder handles (`grab`); `web/31` to the spotlight card (`grab`); `web/35` to the strip (`none` after 3,000 ms without pointer movement while the chrome is hidden, restored on move) and the middle-click anchor (`all-scroll`); `web/36` to the novel column (`text`); `web/37` to the voice orbit (`grab`).
- The gallery's `cursors` section shows each cursor on a labelled 44 px target; `glass-primitives.spec.ts` asserts the computed `cursor` of a button, a disabled button, a text field and the dragged segmented thumb.

## Out of scope here (owned by later steps; do not build)

- `web/27`: sheets, alerts (`confirmAlert()`), toasts, tabs and pagers, sliders, toggles, the Stepper, menus and context menus (the poster's context preview and the split button's menu attach there), banners, the image viewer, scroll edges, pull to refresh, the content-mode switch.
- `web/28`: lists, swipe rows, reorder and bulk selection, empty/error/offline states and `copy/errors.ts`, the 18+ gate alert (which uses `HoldToConfirm mode="inAlert"`), the download control, the depth glyph, AI surfaces (`AiNotice`, `ThinkingOrbit`), charts, `ReactionPicker`.
- `web/29`: the dock, search orb, sidebar, top bars, the command palette, the back menu that `IconButton`'s long press opens.
- Every screen and every placement wiring of the two reveals.

## File layout

```
frontend/src/skins/glass/primitives/
├── usePress.ts, lit.ts                           A
├── Button.tsx, SplitButton.tsx                   B
├── HoldToConfirm.tsx, hold.ts (+ hold.test.ts)   B
├── IconButton.tsx, GlassGroup.tsx                C
├── TextField.tsx, TextArea.tsx                   D
├── SearchField.tsx                               E
├── Chip.tsx, ChipRow.tsx                         F
├── Segmented.tsx, segmented-math.ts (+ test)     G
├── cards/SeriesCard.tsx, ContinueStack.tsx, WorldCard.tsx, ResultCard.tsx, StatCard.tsx,
│   CollectionCard.tsx, NotificationCard.tsx, SourceRowCard.tsx, HistoryTile.tsx, HealthBead.tsx, SourceMonogram.tsx   H
├── Poster.tsx, PosterGrid.tsx, poster-throw.ts (+ test)   I
├── Rail.tsx, RailGroup.tsx, rail-columns.ts (+ test)      J
├── Skeleton.tsx, wave.ts (+ test)                K
├── Progress.tsx, LiquidProgress.tsx              L
├── Badge.tsx                                     M
├── ProfileOrb.tsx, GoalRing.tsx                  N
├── Tooltip.tsx, Keycap.tsx                       O
├── LetterReveal.tsx                              P
└── TypedHeadline.tsx                             Q
frontend/src/skins/glass/glass/budget.ts          GlassBudgetScope (A)
frontend/src/skins/glass/glass.css                primitive styles that are shared (states by data attribute, reveal CSS from §10, the §7.40 cursor contract of T)
frontend/src/skins/glass/dev/Gallery.tsx          R
frontend/src/app/(preview)/dev/glass-primitives/page.tsx   R
frontend/e2e/glass-reveals.spec.ts, glass-primitives.spec.ts   S
docs/redesign/proof/web-26/                       plan.md, screenshots, report.md
```

Skin files import only `@/features/**` (never `@/features/*/components/**`), `@/lib/**`, `@/services/**`, `@/stores/**`, `@/types/**` and their own `skins/glass/**`; the lint rule bans `@/skins/cinematic/**`. Keep component styles in `glass.css` or Tailwind utilities; do not add CSS modules.

## Acceptance criteria

- [ ] Every primitive in items B to Q exists with every state of its section, visible in the gallery over black, the ambient field and white.
- [ ] Press physics: glass controls grow (+12 px Medium, +17 px capped at 0.35 × side Feather/Light) on `press` with the glow at the touch point and the stretch toward a drag; content sinks (0.97 / 0.99 / 0.96 / 0.92); a drag beyond 1.5 × the hit area cancels with no activation and no haptic.
- [ ] `HoldToConfirm`: the fill starts at 200 ms and completes at 1,200 ms with `hold.ramp` every 150 ms and `hold.done`; click, cancel and aborted-hold behave as specified; `Enter`/`Space` are clicks; the `inAlert` fallback button is always visible; the `standalone` click calls `onRequestConfirm`; reduced motion steps the fill in 4 increments.
- [ ] One lit object per screen: two visible `tinted` objects outside an overlay warn in development; `suppressLit()` drops the lit object to `glassThin` and fades its caustic over 180 ms.
- [ ] Posters: the lift starts at 150 ms (1.06 at 450 ms, `press.lift`), `onContextPreview` fires at 450 ms, a tap is a release before 450 ms within the slop; the throw decisions (`open`, `away`, `target`, `drop`) follow `poster-throw.test.ts`; `.`/`Shift+F10` and `Enter` work from the keyboard; the peek capsule follows WCAG 1.4.13.
- [ ] Rails: the scroll comes to rest on a multiple of `posterWidth + gap` after momentum (the `settle` spring), `overscroll-behavior-x: contain` is set, desktop arrows page by (visible − 1), and the keyboard model (one tab stop, `←`/`→`, `↑`/`↓` keeping the column) passes.
- [ ] Content twins: no chip (the choice droplet and a selected chip's glass included), poster, card, row action or rail arrow creates a `backdrop-filter` element; the only transient live glass is the segmented thumb while it is dragged, and the gallery's live counts show it.
- [ ] Every interactive element's own box is at least 44 × 44 px (390 × 844 touch), with at least 8 px between adjacent hit boxes or one merged glass group.
- [ ] Keyboard: every control is reachable and operable, shows the two-tone focus ring (2 px black, 2 px `iris300` at 2 px offset, 6 px glow; 3 px under Increase Contrast), and the ring is never clipped (rails and chip rows pad 8 px).
- [ ] Reduced motion (OS query and `data-motion="reduced"`): glass press is glow only, content press a `fill2` wash, no shakes, no stretch, skeletons static, spinners pulse, liquid levels jump, the reveals show full text, the rail snap and droplet moves become 150 ms fades.
- [ ] Solid glass (`data-solid="on"`): every glass primitive renders its solid recipe (`#1C1C22` / `#26262E`, 1 px `rgba(255,255,255,0.10)` rim), the primary is `#5B4AD1` with `#4A3CB0` pressed, and no caustic or sweep appears (screenshot of each section).
- [ ] `glass-reveals.spec.ts` passes: typing is still running 200 ms after navigation with focus on the heading, starts letters and caret together, completes by 3 s, skips on pointer and on a body key press, runs once per session; a below-the-fold header waits for 25 % visibility; at most two letter reveals run at once; reduced motion shows everything at once.
- [ ] Pointer cursors (§7.40): buttons, links and pressable content show `pointer`, disabled controls `not-allowed`, fields `text`, and the `data-cursor` values (`grab`/`grabbing`, `ns-resize`, `zoom-in`, `zoom-out`, `none`, `all-scroll`) resolve from `glass.css`; the gallery's `cursors` section shows them.
- [ ] `glass-primitives.spec.ts` and the five vitest files pass.
- [ ] The motion-timings overlay logs Press swell, Content sink, Tab droplet, Hold fill, Liquid fill, Count pop, Wave, Letter reveal and Typing reveal from the gallery at 1440 × 900 with no dropped frames (or a trace showing software-raster-only cost, listed for the owner's hardware check).
- [ ] Per-skin difference: nothing under `frontend/src/skins/cinematic/` changed; the default (Cinematic) skin renders `/` and `/library` as before.
- [ ] Glass `PENDING` is unchanged; the completeness test passes.
- [ ] `npm run typecheck`, `npm run lint` (0 errors, 0 warnings), `npm run test` (counts at or above the floor plus the new tests), `npm run build` (0 errors, 0 warnings) and `node design/build.mjs --check` are green.

## Verification

**RAM guard (production shares this box).** Before every heavy command (a build, the vitest suite, `next dev`, a Playwright run) run `free -m` and read the `available` column of the `Mem:` row. If it is under 1024 MB, stop and report instead of running it. Never run two builds at once, and never run `next build` while `next dev` or a Playwright browser is running.

From `frontend/`:

```bash
free -m && npm run typecheck
free -m && npm run lint
free -m && npm run test
free -m && npm run build
cd .. && node design/build.mjs --check && cd frontend
```

Browser checks (from `frontend/`):

```bash
free -m && NEXT_PUBLIC_API_URL=/api BACKEND_INTERNAL_URL=http://127.0.0.1:8010 npm run dev -- -p 3010
# second shell, one spec at a time
free -m && E2E_BASE_URL=http://127.0.0.1:3010 npx playwright test e2e/glass-reveals.spec.ts --workers=1
free -m && E2E_BASE_URL=http://127.0.0.1:3010 npx playwright test e2e/glass-primitives.spec.ts --workers=1
```

**Visual proof** with `frontend/scripts/proof.mjs` (run `node scripts/proof.mjs --help` first) in the named session `web-26`, headless Chromium, at 1440 × 900 and 390 × 844 (touch emulation on the phone size), into `docs/redesign/proof/web-26/`: one full-page capture per gallery section (`/dev/glass-primitives?section=<name>`) named `<section>-{desktop,phone}.png`; the same for every section with `data-solid="on"` (`<section>-solid-desktop.png`) and with Increase contrast (`<section>-contrast-desktop.png`); `reveals-typing-200ms-desktop.png` (captured 200 ms after navigation), `reveals-rails-running-desktop.png` (two headers running, the third waiting), `poster-lift-phone.png` (captured at 450 ms of a press), `hold-aborted-desktop.png` (the helper line showing). If you use `playwright-cli`, pass `-s=web-26`. Write `docs/redesign/proof/web-26/report.md` mapping each screenshot to the acceptance item it proves. Stop `next dev` when done.

`00-baseline.md` records lint and build at 0 errors and 0 warnings; keep them there. This step changes nothing in `mobile/` or `backend/`: check each of your commits with `git show --stat --format= <hash>` (the parallel `mobile/NN` session and the backend and shared sessions commit `mobile/` and `backend/` on the same branch, so never judge by the branch diff). If one of your commits touched them, revert that part and prove the baseline with `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze` (No issues found), `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter test` (all 2012 tests pass, or the current higher count) and `cd backend && .venv/bin/python -m pytest -q --no-header`, one at a time after the RAM guard.

## Git

- Branch `feat/vps-slim-source-native`. Commit small and often, one component family per commit with its test (`feat(web-glass): HoldToConfirm with the 1,200 ms liquid hold`), then the gallery, then the browser specs, then the proof. Stage your paths explicitly (`git add frontend/src/skins/glass/primitives/HoldToConfirm.tsx …`), never `git add -A` or `git add .`, because the mobile, backend and shared sessions commit in the same checkout.
- No Claude or AI attribution anywhere: no `Co-Authored-By` line, no "Generated with" line, no AI author. Never commit secrets or `.claude/`.
- Run `npm run build` (after `free -m`, with `next dev` stopped) before every push, then `git push origin feat/vps-slim-source-native` after each working step.
- Never edit `backend/connectors/`. Never touch production containers or `/srv/manhwamaniacs/{app,data}`. Do not deploy: Glass stays behind the debug row until `release/01`.

## Report back

Reply with:

1. Done items by letter (A to T), and anything not done with the reason.
2. Any token key missing from the generated files (avatar presets, type roles), for the shared track.
3. The screenshot folder `docs/redesign/proof/web-26/` and its file list.
4. Test counts: vitest files and cases before and after; each Playwright spec's result; lint, build and `build.mjs --check` results; the `free -m` available figure before each build.
5. The motion-timings figures for the moves listed in the acceptance criteria, and any raster-only move for the owner's hardware check.
6. Open issues, each with its `glass/DESIGN.md` section.

Next prompt file: `docs/redesign/prompts/web/27-glass-primitives-overlays.md` (`docs/redesign/prompts/mobile/26-glass-primitives-controls-and-reveals.md` runs in parallel).
