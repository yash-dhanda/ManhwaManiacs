# Mobile Glass primitives 1: controls, posters, rails and the two reveals

Track: mobile · Order 71 · Depends on: `docs/redesign/prompts/mobile/25-glass-foundation-material-physics.md` · Web twin: `docs/redesign/prompts/web/26-glass-primitives-controls-and-reveals.md` · Proof folder: `docs/redesign/proof/mobile-26/`

## Goal

Build the first half of the Glass skin's component catalogue in the Flutter app, in `mobile/lib/skins/glass/primitives/`, on the `mobile/25` foundation (`SkinGlass`, `GlassType`, `GlassMotion`, `GlassHaptics`, `glass_physics.dart`, the prefs bridge and the registry). You deliver: the shared press behaviour ("glass swells, content sinks") with every state; `GlassButton` in all its variants including the split button, the progress button and `HoldToConfirm` (the 1,200 ms liquid hold with `hold.ramp` and the always-visible fallback); icon buttons and glass groups with 44 pt hit areas on iOS and 48 dp on Android; text fields, the password field, the text area and the number field with the right keyboard types; the search fields; chips and chip rows; the segmented control whose thumb turns into transient glass while dragged; the cards, drawn as content with their glass twins; posters with the press-and-hold lift at 150 and 450 ms and the throw on `motor` springs; rails with `SnapPhysics`; "wet glass" skeletons and the entrance wave; every progress indicator including `LiquidProgress`; badges and markers; profile orbs and the goal ring; tooltips and keycaps; and the Glass versions of the two required signature animations: `letter_reveal.dart` (each grapheme a droplet settling, at most 60 graphemes per letter run, at most two runs at once, starting at 25 % visibility) and `typed_headline.dart` (one grapheme every 50 ms, the caret of light on the `track` spring, the skip rules, and focus never skipping it), each with widget tests. Every primitive ships every state (default, hover, pressed, focused, disabled, loading, selected, error), its reduced-motion variant and its Solid glass variant, full hardware-keyboard access and screen-reader semantics, and all of it appears in a development primitives gallery. No screen is built; Glass stays behind the debug row.

## Read first

Read these completely before planning. Where this file and `docs/redesign/glass/DESIGN.md` disagree, `glass/DESIGN.md` wins; say so in the report.

1. `docs/redesign/inventory/00-decisions.md` (all of it; the two signature animations are binding: "each letter fades in, slides up, and un-blurs, staggered" and "one character every 50 ms").
2. `docs/redesign/stack-decision.md` §2.3 (the import boundary: skins import only the shared data layer and their own primitives), §3 (packages).
3. `docs/redesign/glass/DESIGN.md`:
   - §2.1.2 (text and fill roles: `onGlass`, `onTint`, `label1`–`label4`, `fill1`–`fill4`, `wellOnGlass`, the backing disc `rgba(0,0,0,0.60)` 28 px behind a 22 px glyph and 20 px behind a 16 px glyph, the glyph and text mappings on T4/T5 glass), §2.1.3, §2.1.4 (semantic colours: `success` `#3DDC84`, `warning` `#FFB547`, `danger` `#FF5C5C`, `info` `#6CB8FF`, `mature` `#FF5C93`, `streak` `#FF8A3D`, `streakCore` `#FFD166`, `bloom` `#FF9ED8`, `machine` `#5CE1E6`), §2.1.5 (speaker palette, for the source monogram), §2.1.9.
   - §2.2 (spacing, `touchMin` 44 iOS / 48 Android), §2.3 (radius tokens, the concentric rule), §2.4.1 (mass classes; rule 1 content twins for anything repeated per item; rule 2 the two page-level controls; transient glass), §2.4.2 rules 1–8, §2.4.4 (caustic, sweep), §2.6 (the focus ring), §2.7 (icons: weights and sizes per context, the custom glyphs `droplet`, `age-gate`, `strip-scroll`), §2.8.5 (springs, curves, thresholds).
   - §3.2, §3.3 (rules 1 to 3: heights are minimums, `f ≥ 1.6` and `f ≥ 1.9`, the 1.5 clamp in capsule controls), §3.5, §3.7 (type roles and `GlassText` overrides).
   - §4.1–§4.11, especially §4.6 (thresholds: tap 450 ms, lift at 150 ms reaching 1.06 at 450 ms, context menu at 450 ms, hold to confirm 1,200 ms with the fill starting at 200 ms, click slop 8 px, throw 1,200 px/s, magnets 64 px), §4.8 (the entrance wave), §4.9, §4.10 rows Press swell, Content sink, Stretch, Tab droplet, Wave, Throw, Catch, Rubber band, Liquid fill, Hold fill, Letter reveal, Typing reveal, Error shake, Skeleton shimmer, Liquid spinner, Button dots, Count pop, Hero tilt, Orb idle drift, Specular sweep, Caustic press, Goal ring close, and §4.11.
   - §5.2 (the events these components fire: `tap.primary`, `tap.secondary` (none), `select`, `toggle.on`/`toggle.off`, `press.lift`, `longpress.open`, `throw.commit`, `motion.catch`, `magnet.capture`, `magnet.drop`, `hold.ramp`, `hold.done`, `delete.confirm`, `error`, `download.start`, `download.done`, `download.fail`, `follow.add`, `follow.remove`, `favorite`, `stack.open`, `goal.met`) and §6 (sounds off by default).
   - §7 intro (every height is a minimum: `ConstrainedBox(minHeight:)` plus padding, never `SizedBox(height:)` around text; "hit 44" means 44 and 48 on Android), §7.1, §7.2, §7.3 (except the Stepper row, which is `mobile/27`), §7.4, §7.5, §7.6, §7.7, §7.8, §7.9, §7.18, §7.19, §7.20, §7.26, §7.27.
   - §9.2.2 (the daily goal ring on the profile orb), §10.1 and §10.2 (all of it, including the Flutter code and notes), §11 (the alternative for every gesture these components own), §14.1–§14.10, §15.3 (the Flutter file map), §15.7 (per-letter reveals capped at 60 graphemes and at most two at once), §15.8 ("Signature animations actually play": Flutter widget tests).
4. `docs/redesign/inventory/mobile.md` §3 G14 (shared primitives: each needs a Glass variant), §4 (the actions these controls trigger), §6c (download states, for the progress button) as a checklist that no state is lost.
5. `docs/redesign/inventory/capabilities.md` §7 (library item fields: status, favourite, progress, `palette`), §16.1 (source `health.status`, `health.demoted`, `language`, `icon_url`).
6. `docs/redesign/00-baseline.md`.
7. `docs/redesign/prompts-plan.json`: the `mobile/00` entry (its `TRACK RULE`) and this file's entry.
8. Code you build on (from `mobile/25`): `mobile/lib/skins/glass/skin_glass.dart` (`SkinGlass`, `SkinGlassGroup`, `GlassHost`, `GlassTextAxes`, `twin`, `tierValue`, `glow`, `GlassSweep`, `GlassCaustic`, `GlassFocusRing`), `glass/registry.dart` (`GlassBudgetScope`), `glass/lb.dart` (`GlassLbItem`), `glass/palette.dart`, `glass/ambient_field.dart`, `physics/glass_physics.dart` (`project`, `rubberband`, `SnapPhysics`, `Magnet`, `CatchableSpring`, `impactIntensity`), `motion.dart` (`GlassMotion`), `haptics.dart` (`GlassHaptics`, `debugLog`), `prefs.dart`, `frame.dart` (`hitMin`, `screenMargin`), `type.dart` (`GlassType`, `GlassText`), the Glass icons (`mobile/lib/skins/glass/icons/`: `phosphor.g.dart`, `glass_glyphs.g.dart`, the Icon-role widget), `dev/glass_dev_index.dart` and `router.dart` (the `/dev/glass` routes), the harness `mobile/test/screenshots/support/`. The shared cover-loading helper of the data layer (`grep -rn "CachedNetworkImage\|coverUrl" mobile/lib/features mobile/lib/core`; never import a Cinematic widget). `motor` 1.1.0 in `~/.pub-cache/hosted/pub.dev/motor-1.1.0/lib/` (`SingleMotionController({required Motion motion, required TickerProvider vsync, double initialValue})`, `animateTo(double target, {double? from, double? withVelocity})`, `stop()`, `value`, `velocity`, `SpringMotion(SpringDescription)`; confirm each name there before use and note any difference in the report).

## Preconditions (check before writing the plan)

- `git log --oneline -20` shows the `mobile/25` work; `mobile/test/skins/glass/glass_physics_test.dart` and `skin_glass_test.dart` pass.
- `node design/build.mjs --check` passes. `GlassTokens` carries the avatar presets (`grep -n "colorAvatar" mobile/lib/skins/glass/tokens.g.dart`) and the type roles (`typeHeadline`, `typeSubhead`, `typeFootnote`, `typeCaption1`, `typeMono`, `typeTitle2`, `typeLargeTitle`); if the presets are missing, use the values in item N inside one constant with a comment citing §7.26, and report it for the shared track.
- In `mobile/`: `free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter test` passes; record the passed, failed and skipped counts (your floor).

## Skills to invoke

1. `superpowers:writing-plans` before any code: write the plan to `docs/redesign/proof/mobile-26/plan.md` (commit it with the proof).
2. `superpowers:test-driven-development` for every pure piece (the hold state machine, the throw decision, the wave delays, the segmented projection, the rail column mapping, the reveal slot queue): the failing test first.
3. `superpowers:subagent-driven-development` to run the plan (or `superpowers:executing-plans` inline). At most 6 implementer subagents, split by component family; start each subagent prompt with a scope lock, pass `model: "opus"` explicitly, run analyze, tests and captures one at a time, and verify each subagent's work against `git status` and `git diff`, never against its report alone.
4. `impeccable:impeccable`, `taste-skill:taste-skill` and `frontend-design:frontend-design` for every component and for the gallery review (Meniscus: glass swells and lights up under the finger, content sinks as if pressed into water, nothing moves on a timer).
5. `superpowers:verification-before-completion` before you claim anything is done.

## Scope: deliver every item below

Sizes are logical px (1 px = 1 pt); heights are minimums (`ConstrainedBox(constraints: BoxConstraints(minHeight: token))` plus padding, never `SizedBox(height:)` around text). Hit areas are `GlassFrame.hitMin(context)`: 44 on iOS, 48 on Android, with at least 8 px between adjacent hit areas (or one merged glass group). Colours, springs and curves come from `GlassTokens`; every named move goes through `GlassMotion`; haptics through `GlassHaptics`; sounds through `skin_audio.dart`. Every pressable is a `FocusableActionDetector` (focus, hover, `ActivateIntent` on `Enter` and `Space` from a hardware keyboard) wrapped in `Semantics`. Every icon-only control has a `Semantics(label:)` and a `GlassTooltip` (item O). Transient errors are announced with `SemanticsService.sendAnnouncement(View.of(context), message, Directionality.of(context), assertiveness: Assertiveness.assertive)` (use the non-deprecated announcement API the Flutter 3.44 analyzer accepts if its signature differs). Sections cited are `glass/DESIGN.md`.

### A. Shared press behaviour (`primitives/press.dart`, `primitives/lit.dart`, §2.4.2 rules 3–4, §4.10, §7.1)

`GlassPressable` (a widget) and `GlassWidgetStates` (`hovered`, `pressed`, `focused`, `disabled`, `loading`, `selected`, `error`), with a `forceStates` parameter so the gallery can show any state.

- **Glass swells** (`material: GlassMaterial.glass`): on press the glass grows by +12 px on its longest side for the Medium class (buttons, the split button), or +17 px capped at `0.35 × side` for Feather and Light (icon buttons, a selected chip's glass, badges), as `scale = (L + growth) / L`, on `springPress` (k 815.7, c 45.70; settle 253 ms) through a `motor` `SingleMotionController` with `SpringMotion(springOf(springPress))`; the press glow at the touch point (`SkinGlass.glow`, 16 %, `glowIn` 150 ms / `glowOut` 60 ms); the label `wght` + 40 (`GlassText(wght:)`); while the finger drags, a stretch of up to 6 % along the drag axis, `scale = 1 + 0.06 × clamp(dx / width, −1, 1)`, with the other axis at `1 / sqrt(scale)`, following on `springTrack`.
- **Content sinks** (`material: GlassMaterial.content`): cards and posters 0.97, rows 0.99, chips 0.96, plain icons 0.92, on `springPress`.
- **Activation** happens on release inside the target. Dragging more than 1.5 × the hit area away cancels: the glow fades over 60 ms, no activation, no haptic.
- **Hover** (a hover pointer: iPad trackpad, Android mouse, via `MouseRegion`): glass gets an inner glow at 8 % centred on the pointer, following it with no lag, and the label eases to full white over `curveColorShift` (240 ms); a secondary button lifts −1 px with shadow `0 10px 28px rgba(0,0,0,0.5)` on `springSnappy`.
- **Reduced motion** (`glassMotionPrefsProvider.reduced`): glass shows the glow only (no growth, no stretch); content shows a `fill2` wash (`Color(0x4D787880)`) instead of sinking.
- **Solid glass:** the press darkens `tinted` from `#5B4AD1` to `#4A3CB0`; other surfaces keep the glow.
- **Error shake** (§4.10): `x(t) = 8 × e^(−t / 90 ms) × sin(2π × 7 Hz × t)` for 420 ms (6 px amplitude for fields), fired with the `error` haptic; none under reduced motion.
- **One lit object per screen** (§2.4.2 rule 8): `lit.dart` keeps a registry of mounted `tinted` objects; in debug, two visible lit objects outside an overlay `debugPrint` one warning. `suppressLit()` (called by sheets and alerts in `mobile/27`) drops the screen's lit object to `glassThin` and fades its caustic over 180 ms until released.

### B. Buttons (`primitives/glass_button.dart`, `split_button.dart`, `hold_to_confirm.dart`, `hold.dart`, §7.1)

| Variant | Material | Heights visual / hit | Padding | Label | Icon |
|---|---|---|---|---|---|
| `primary` (one per screen) | `SkinGlass(finish: tinted)` + `GlassCaustic` when over content | L 50 / 50, M 44 / `hitMin`, S 34 / `hitMin` | L 0 24, M 0 20, S 0 14 | `headline` 17/600 `onTint` (S: `subhead` 15/620) | 20 px Regular, 8 px gap, leading |
| `secondary` | `glassThin` (T2) on black, `glassRegular` (T3) when `overMedia` | same | same | `headline` `onGlass` | same |
| `plain` | none | `hitMin` | 0 8 | `headline` `iris400` on black, `onGlass` on glass | optional |
| `destructive` | `glassThin` | same | same | `headline` `onGlass` | leading `trash` or `warning-circle` in `danger` on the backing disc |
| `destructiveConfirm` | solid `danger` `#FF5C5C` | L 50 | 0 24 | `headline` black (6.94:1) | optional |
| `progress` (download) | `glassThin` capsule whose fill becomes a liquid progress | M 44 | 0 16 | `subhead` + `mono` count | `cloud-arrow-down` → spinner → check |

All capsules. Inside a live surface each variant renders its §2.4.2 rule 7 twin automatically (`GlassHost`); the host's one lit action is the tinted twin. Every glass primitive passes a `twin` through to `SkinGlass`: a button repeated per item (inside a card, row or tile) takes `GlassTwin.content` (§2.4.1 rule 1); a scrolling page may carry at most two live page-level controls, with `role: GlassRole.pageControl` (`GlassQuality.standard`) (§2.4.1 rule 2; screens enforce it, the gallery documents it next to the buttons).

States (every variant): **default** (rim and specular at the light angle); **hover** (A); **pressed** (A; the tinted fill shifts to `iris700` at 86 %); **focused** (the two-tone `GlassFocusRing` over a 120 ms fade, no movement); **disabled** (fill at 40 %, label `label4`, no specular, no glow, no growth, no haptic; `tinted` becomes `glassThin` at 40 %; `Semantics(enabled: false)` and a tooltip with the reason, passed as `disabledReason`); **loading** (the width locks; the label fades out over `curveFadeOut` 120 ms and three 5 px `onGlass` dots appear 6 px apart, each bobbing 3 px on `springTick` 80 ms apart; not activatable; semantics value "Loading"; the label returns over `curveFadeIn` 180 ms; reduced motion: static dots); **selected** (toggle buttons "In library", "Following", "Favourited": stays a secondary; a 22 % `iris600` wash inside the glass spreading from the touch point as a 200 ms radial wipe, the icon morphs Regular → Fill in `onGlass` on `springTick`, label `onGlass`, rim tinted `iris300` at 40 %); **error** (the label swaps to a short error such as "Couldn't save" for 2 s in `onGlass` (`onTint` on the primary), led by a `warning-circle` in `danger` on the backing disc; the same text is announced assertively; the shake and the `error` haptic). The primary fires `tap.primary`; secondary and plain fire nothing (`tap.secondary` maps to none).

**Toggle semantics (§7.2):** a button whose visible label changes ("Add to library" / "In library") has no `toggled` flag and its semantics label follows the visible label.

**Split button (`split_button.dart`):** one glass container (a `SkinGlassGroup` of two shapes) holding a tinted primary segment (padding 0 20) and a trailing `glassThin` segment 50 × 50 with `caret-down`, separated by a 0.5 px `separator` (`rgba(84,84,96,0.55)`), height L 50. Pressing either lights both, the pressed one more (glow 16 %, the other 8 %). Semantics: two buttons, "Continue, chapter 143" and "More ways to read". The trailing segment calls `onMore(Rect anchor)`; the menu itself (Read from the start, Read all, Pick a chapter, Download next 10) is `mobile/27`'s `GlassMenu`.

**Progress button:** "Download" → on press the label cross-fades to "Queued" and a liquid fill enters from the left at the queue's progress (`download.start`); while saving it shows `mono` "12/40" and the level follows progress on `springLens` (the `LiquidProgress` of item L); complete: the fill turns `success` at 24 %, the glyph morphs to a check on `springTick`, label "Saved" (`download.done`); failed: label "Retry" led by a `danger` `warning-circle` on the backing disc, with the shake, the assertive announcement and `download.fail`. Semantics value "12 of 40 pages saved" while saving. States map to the download vocabulary of `inventory/mobile.md` §6c.

**`HoldToConfirm` (§7.1, §4.6, §14.8):** `glassThin` capsule, L 50, padding 0 24, leading glyph, `headline` `onGlass` label ("Hold to delete"). Behaviour as a pure state machine in `hold.dart` (`HoldMachine` with `down(t, pos)`, `move(t, pos)`, `up(t)`, `cancel()`, `tick(t)` returning `HoldEvent`s) tested in `mobile/test/skins/glass/primitives/hold_test.dart`:

- Pointer down starts nothing for 200 ms (`thresholdHoldStart`). A release before 200 ms with less than 8 px of movement (`thresholdHoldClickSlop`) is a **click**. Moving 8 px or more before 200 ms, or a pointer cancel (a scroll taking the gesture), **cancels** the press: no fill, and the release does nothing.
- From 200 ms the liquid fill rises left to right inside the capsule over 1,000 ms (`iris600` at 60 % with a 3 px meniscus on its leading edge), so a completed hold is 1,200 ms in all (`thresholdHoldConfirm`); `hold.ramp` fires every 150 ms from the fill's start (the `ahap:swell` pattern, intensity rising 0.2 → 0.8); the label changes to "Keep holding…".
- A release after 200 ms and before completion is an **aborted hold**: the fill drains from its current level on `springDismiss` (k 385.5, c 39.27), and the helper "Keep holding, or tap once to confirm" shows under the button in `footnote` `label2` (`onGlass` inside an alert) for 2 s.
- Completion fires `hold.done`, flashes the capsule to `glassTinted`, and calls `onConfirm`.
- `Enter` and `Space` from a hardware keyboard, and the screen reader's activate, are always a click.
- Reduced motion: the fill steps in 4 visible increments (25 % each, 250 ms apart) with no meniscus.
- **The fallback is never optional (WCAG 2.5.1).** `mode: HoldMode.standalone` (sign out everywhere, delete a collection, remove all downloads, reset offline storage): a click calls the required `onRequestConfirm()`, which opens the §7.11 confirm alert with an explicit confirm button (`mobile/27` provides `confirmAlert()` and makes it the default). `mode: HoldMode.inAlert` (the 18+ gate, delete profile, delete member): the widget renders, visibly and for everyone, the explicit confirm as a secondary button under the hold button (label from `fallbackLabel`, for example "Turn on 18+"); a click on the hold button moves focus to that button and shows "Hold, or use the button below"; it never opens a second alert. Nothing depends on detecting a screen reader.

### C. Icon buttons (`primitives/icon_button.dart`, `glass_group.dart`, §7.2)

| Variant | Visual | Hit |
|---|---|---|
| `nav` | `glassThin` circle 44, icon 22 Regular `onGlass` | `hitMin` |
| `group` (`GlassGroup`) | one `glassThin` capsule 44 tall holding 2 to 4 icons 44 px apart, 8 px internal gap; one `SkinGlassGroup` (one layer, one shape) | `hitMin` each |
| `plain` | no background; icon 22 `g800` `#BDBDC6` on black; hover a `fill4` circle 40 | `hitMin` |
| `row` | `fill3` circle 32, icon 18 | `hitMin` |
| `toggle` | any of the above; off = Regular `g800`, on = Fill in its colour (`iris400` for pin and follow, `streakCore` `#FFD166` for favourite, `success` `#3DDC84` for downloaded); on glass the coloured glyph sits on the backing disc | as above |
| `badged` | any; a count badge (item M) at the top-right | as above |

States: default; hover (inner glow 8 % on glass, the `fill4` circle on plain); pressed (glass grows +17 px on the longest side capped at 0.35 × side, so a 44 px button reaches about 1.35×; glow 16 % from the touch point; Duotone → Fill morph; plain icons sink to 0.92); focused (ring, concentric); disabled (icon `g500`, no glow); loading (the icon becomes a 16 px liquid ring spinner); selected (the Fill glyph in its colour with a `springTick` pop 1 → 1.12 → 1); error (the glyph swaps to `warning-circle` in `danger`, on the backing disc when on glass, for 2 s, with the shake, and "Couldn't {action}" is announced assertively). In a `GlassGroup`, a pressed icon's glow spreads into its neighbours at 30 % (one container, one light). Constant-label toggles (favourite star, pin, notify bell, bookmark, the password eye) carry `Semantics(toggled:)` with a fixed label ("Favourite", "Pin source", "Notify me", "Bookmark", "Show password"). `nav` accepts `onLongPress` at 450 ms (`thresholdStackLongPress`) for the stack overview that `mobile/29` wires; the long press fires `stack.open`; its alternative is the visible back menu that `mobile/29` adds.

### D. Inputs (`primitives/text_field.dart`, `text_area.dart`, §7.3)

Form fields are content-layer wells, never glass. `GlassTextField` kinds `text`, `password`, `url`, `number` (go-to), built on `TextField` with `InputDecoration.collapsed` inside the well:

- **Text:** min height 50, `ClipRSuperellipse` radius 14, fill `fill3` on black, `fill2` on a solid sheet, `wellOnGlass` `rgba(0,0,0,0.35)` inside T4/T5 glass (read from `GlassHost`); padding 0 16; text `body` 17 `label1`; placeholder `label3` (`label2` inside `wellOnGlass`); label above in `footnote` 13/600 `label2` (`onGlass` on glass) with a 6 px gap; helper below in `footnote` `label3` (`onGlass` on glass); `keyboardAppearance: Brightness.dark`; `autofillHints` (`AutofillHints.username`, `password`, `newPassword`, `url` where they apply); `textCapitalization: TextCapitalization.none`, `autocorrect: false` and `enableSuggestions: false` for usernames and URLs.
- **Password:** `keyboardType: TextInputType.visiblePassword`, `obscureText` toggled by a trailing eye (plain icon 22, hit `hitMin`, `Semantics(toggled:)`, fixed label "Show password"; the glyph swaps `eye` / `eye-slash`); toggling keeps the selection and caret.
- **URL:** leading `globe` glyph, `keyboardType: TextInputType.url`, `textInputAction: TextInputAction.go`, trailing status (a 16 px spinner while validating, a `success` check when reachable).
- **Number / go-to:** 96 wide, `mono` 13, `TextInputType.numberWithOptions(decimal: true)`, centred; the IME action and `Enter` jump; `Esc` from a hardware keyboard clears.
- **Text area (`text_area.dart`):** `minLines: 3` (≈ 96 px), grows with content up to 8 lines on `springSnappy`, then scrolls; a counter in `caption1` `label3` bottom-right from 80 % of the limit, `warning` at 95 %; with `submitOnEnter` (the AI prompt), `Enter` from a hardware keyboard submits and `Shift+Enter` inserts a newline.
- **States:** default; hover (the well brightens to `fill2`); focused (the focus ring, `cursorColor` `iris400`, `cursorWidth` 2, the well to `fill2`); disabled (40 %, `enabled: false`); loading (a trailing 16 px spinner); selected text (`TextSelectionThemeData(selectionColor: Color(0x667563F2))`, `iris600` at 40 %); error (`errorRing` 1.5 px `danger`, the message below in `footnote` `danger` led by `warning-circle`, `Semantics(validationResult: SemanticsValidationResult.invalid)` where available and the message in the field's semantics hint; on submit the field shakes at 6 px and the first invalid field takes focus); validation messages appear over `curveFadeIn` and push content down on `springSnappy`.

### E. Search fields (`primitives/search_field.dart`, §7.4)

Variants (the orb that morphs into the bottom field is the dock's, `mobile/29`):

- `bottom` (phone): a 50 px `glassRegular` (T3) capsule, full width minus 21 px insets, riding on top of the keyboard (`Padding(bottom: MediaQuery.viewInsetsOf(context).bottom)` under `Scaffold.resizeToAvoidBottomInset`), with a trailing plain "Cancel" button. Dragging down on the field dismisses the keyboard first (`FocusScope.of(context).unfocus()`), then calls `onCollapse` when the projected drag passes 80 px.
- `page`: a 56 px `glassRegular` capsule centred at the top of the content (the desktop-frame Search screen).
- `filter`: a 44 px content well (`fill3`) with a leading magnifier and a trailing clear × (hit `hitMin`) when non-empty.
- `sidebar`: a 36 px `fill3` capsule reading "Search" with the `mod+K` keycap (item O: "⌘K" on iOS, "Ctrl K" on Android); a button that calls `onOpenPalette` (the palette is `mobile/29`).

States: idle (placeholder "Search series, sources and dialogue"); focused; typing (`onQuery` debounced 300 ms, the IME search action fires at once); searching (the magnifier becomes a 16 px liquid ring spinner); results; no results; error; offline (a `warning` `wifi-slash` on the backing disc replaces the magnifier and the helper reads "Offline: searching this device only").

### F. Chips (`primitives/chip.dart`, `chip_row.dart`, §7.5)

| Chip | Visual | Behaviour |
|---|---|---|
| `filter` (multi-select) | 32 tall visual inside the hit (6 px vertical hit padding on iOS for 44, 8 px on Android for 48), capsule, `fill2`, `subhead` 15/460 `label1`, 12 px horizontal padding, optional 16 px leading glyph | Selected: the `glassThin` look with a leading check that grows in on `springTick`, label `wght` 600 |
| `choice` (single-select group) | same size; the selected one sits under a shared droplet (`glassFilm` clear capsule) | The droplet slides between chips on `springTab` (k 195.0, c 21.78), stretching `scaleX = 1 + min(|v| / 2000, 0.25)`, `scaleY = 1 / sqrt(scaleX)`; catchable mid-flight |
| `count` | filter chip + a `mono` count in `label2` after a 6 px gap | "Pinned 4", "With results 12" |
| `input` (removable) | filter chip + a trailing × (16 px glyph; hit 44 × 44, 48 × 48 on Android, extending beyond the chip) | × removes it: the chip shrinks on `springDismiss`, siblings close the gap on `springSnappy` |
| `assist` | 32 tall, `glassThin` outline style (no fill, rim only), leading glyph | "Next 10", "All unread", "Whole book" |
| `tag` (genre, status) | 24 tall, `fill4`, `caption1` uppercase +0.08 em `label2`, 8 px padding | Non-interactive, or a link (hover `fill3`, focus ring) |

Chips live in scrolling rows, so the selected filter chip's glass, the assist chip's rim and the choice droplet are **content twins** (§2.4.1 rule 1): the same capsule, rim and inner light, sliding and stretching as described, with no backdrop read. Chip text uses the 1.5 clamp (§3.3 rule 3). `GlassChipRow` scrolls horizontally with `BouncingScrollPhysics` (momentum, rubber band at both ends), masks its trailing 24 px with a `ShaderMask` gradient to hint at more, never snaps, and pads 8 px vertically so focus rings are never clipped. States: default; hover `fill3`; pressed sinks to 0.96 on `springPress` while a selected chip's glass swells; focused ring; disabled 40 %; loading (a count chip's count becomes a 12 px spinner); selected as above; error (the chip's glyph becomes `warning-circle` in `danger` and the tooltip explains). Selection fires `select`. Semantics: filter chips `Semantics(button: true, selected:)`; choice chips `Semantics(inMutuallyExclusiveGroup: true, checked:)`.

### G. Segmented control (`primitives/segmented.dart`, `segmented_math.dart`, §7.6)

- **Track:** `fill3` capsule (`wellOnGlass` inside T4/T5 glass), visual height 36 (compact 32 inside sheets) inside a `hitMin` row, 2 px inner padding.
- **Thumb:** a `surface3` `#222229` capsule at rest with a 0.5 px rim; label `subhead` 15/620 `label1` on the thumb, `label2` elsewhere (1.5 clamp).
- **Physics:** tapping a segment moves the thumb on `springTab`. Dragging the thumb turns it into **transient glass** (`SkinGlass(tier: t1, finish: clear, role: GlassRole.transient)`, registered only while dragged), following on `springTrack`, stretching `scaleX = 1 + min(|v| / 2000, 0.25)`, with a `select` haptic at each segment boundary; release projects (`project()`) to the nearest segment and settles on `springTab`.
- **Segments:** 2 to 5 (more than 5 must be a menu: an `assert` in debug); equal widths, or content-fit widths when labels differ by more than 40 %.
- **States:** default; hover (an unselected segment gets `fill4`); pressed (the pressed label sinks to 0.96); focused (the ring around the whole control; `←`/`→` move the selection, `Home`/`End` jump); disabled (40 %, the thumb stays); loading (the selected label becomes a spinner while its data loads, the thumb stays); selected (the thumb); error (the thumb springs back to the previous segment on `springTick` and the caller shows a toast).
- **Semantics:** each segment `Semantics(inMutuallyExclusiveGroup: true, checked:, button: true, label: "Library, 1 of 4")`; with `asTabs: true` (it switches panels) each is `Semantics(selected:, button: true)` with the same label.
- **Vertical variant** (`axis: Axis.vertical`, desktop-frame Search scopes in a 220 px column): 40 px rows (`hitMin` hit), the `glassFilm` clear droplet travelling vertically on `springTab`, drawn as its content twin, `↑`/`↓` moving between scopes.
- `segmented_math.dart` (pure, tested): segment widths, the projected segment on release, boundary crossings for the haptic.

### H. Cards (`primitives/cards/`, content layer, §7.7)

Cards sit on black or on the ambient field and are never glass. Default slab: `surface1` `#131317` with `slabBorder` (1 px `rgba(255,255,255,0.06)`), radius `radiusXl` 26, padding 12; media inside at radius 14.

1. `series_card.dart`: a `GlassPoster` (item I) + 8 px + title `footnote` 13/600 in 2 lines + meta `caption1` `label3` in 1 line. No slab: the poster is the card.
2. `continue_stack.dart` (Home, Library): 280 × 132 on phones, 320 × 148 on desktop frames: the cover 88 × 132 on the left; behind it the next page's thumbnail peeks 8 px right and 6 px down, rotated 2°, like a deck; on the right the title `headline`, "Ch 142 · p. 18 of 40" `footnote` `label2`, a 24 px progress ring (3 px stroke `iris500` on `fill1`) around the chapter number, and a plain "Continue" button. **Unopened next chapter** (`page_count == 0`): "Up next · Ch 143", the ring shows its track only, the button reads "Start", no ratio is computed. Slab `surface1`. No horizontal swipe (it sits in a rail). "Previously on" is the first row of its long-press context menu, sits behind a trailing ⋯ (a `hitMin` hit area on its top-right corner), and is the `P` key on a focused stack from a hardware keyboard (the recap itself is `mobile/41`; the card exposes `onPreviouslyOn`).
3. `world_card.dart` (AI and "For you"): 300 × 132: cover 80 × 120, title `headline` in 2 lines, "Manhwa · Ongoing" `caption1`, "120 ch · ★ 8.4" `mono` 13, up to 3 tags, the `why` line in `footnote` italic `label2` after the machine `sparkle` glyph in `machine` `#5CE1E6`. **Available** variant: a small "On MangaSource" source badge (and "+2"), and the whole card opens the series. **Info-only** variant: a dashed 1 px `slabBorder` (a `CustomPainter`), "Not on your sources" `caption1` `label3`, and two plain buttons "Search my sources" and "Read on {site}" (external, `url_launcher`).
4. `result_card.dart` (search): 112 wide × 208: a 112 × 168 poster + title in 2 lines `footnote`; its source glyph badge is hidden inside source groups (`hideSource`).
5. `stat_card.dart`: a 2-up grid cell, slab radius 26, padding 16: glyph 20 `iris400`, a `numeral` value, a label `footnote` `label2`, an optional 7-point sparkline 24 px tall in `iris500`.
6. `collection_card.dart`: a 21:9 slab with a fanned stack of up to four member covers on the left (each 72 × 108, rotated −8°, −3°, 3°, 8°, overlapping 40 %), the name `title3` and "12 series" on the right; `fanOpen()` (the Fan open move on `springCelebrate`: −24°, −8°, 8°, 24°; three covers −16°, 0°, 16°; two −8°, 8°; one 0°) is exposed for `mobile/32`.
7. `notification_card.dart`: one per series: cover 44 × 66, series title `headline`, "3 new · Ch 141–143" `footnote` `iris400`, time `caption1` `label3`, chapter chips that each open the reader (its swipe actions are `mobile/28`).
8. `source_row_card.dart` (+ `health_bead.dart`, `source_monogram.dart`): a 64 tall row: a 44 px source logo (radius 10); the name `headline` followed by a 10 px **health bead** (a content twin: `success` ok, `warning` failing, `danger` dead, `g600` unknown; a 1 px `warning` ring when `health.demoted`; semantics text "working", "having trouble", "not working", "not checked yet", plus ", skipped by search" when demoted), and the source's `language` as a `caption1` tag ("EN"); description `footnote` `label2` in 1 line; an 18+ tag when mature; the pin toggle icon. **Logo fallback** (no `icon_url`, or the logo fails to load): a monogram tile, the source name's first letter in `headline` 600 `label1` on `surface3`, radius 10, tinted by a hash of the source id into the speaker palette (§2.1.5) at 24 %.
9. `history_tile.dart`: a poster with a 3 px progress line along its bottom edge; a 36 px play orb bottom-right ("p. 18" or "42 %") drawn as a content twin on the cover-overlay backing (`rgba(0,0,0,0.86)` disc, 0.5 px `rgba(255,255,255,0.22)` rim, inner light, no backdrop read; `label1` on it 13.96:1 over a white cover); the title and "Ch 12 · 3 h ago" below.

States (all cards): default; hover (a hover pointer: lift −2 px on `springSnappy`, shadow `0 12px 32px rgba(0,0,0,0.5)`; posters tilt toward the pointer up to 6° with the specular highlight sweeping across the cover); pressed (sinks to 0.97); focused (ring + scale 1.04); disabled (unavailable source, pinned-but-hidden: 55 % opacity, not activatable, the reason in `caption1`); loading (a skeleton of the same shape); selected (select mode: a 2 px `iris500` inset ring + a 24 px check orb top-right that pops on `springTick`, media dimmed to 80 %; `Semantics(checked:)`); error (cover failed: a `surface2` fill with a 24 px broken-image glyph in `g600` centred, the title still shown).

### I. Posters (`primitives/poster.dart`, `poster_grid.dart`, `poster_throw.dart`, §7.8)

- **Geometry:** 2:3, `ClipRSuperellipse` radius 14, a 1 px inner highlight `rgba(255,255,255,0.08)` along the top edge, no outer border. Widths: phone 124 in rails and by columns in grids; tablet 148; desktop frame 168; wide 184. The cover image comes from the shared cover-loading helper.
- **`GlassPosterGrid`** (every poster grid on tablet and desktop frames): a `SliverGrid` with `SliverGridDelegateWithMaxCrossAxisExtent`-equivalent columns from a minimum width (`gridMin` 148 on tablet, 152 on desktop at Comfortable density, 112 at Compact), gap 20 on tablet and desktop frames and 12 on phones; at `f ≥ 1.9` phone grids drop to 2 columns (§3.3 rule 1). The column count is a pure function `posterColumns(contentWidth, gridMin, gap)` = `floor((W + gap) / (gridMin + gap))`, where `W = min(windowWidth − sidebarOffset, 1440) − 2 × margin` (`sidebarOffset` 304 expanded or 100 collapsed, `margin` 32, or 40 at 1440 and wider, §7.8), with a test: `W` 860 (a 1024 window, collapsed sidebar) gives 5, `W` 1056 (1440, expanded) gives 6, `W` 1360 (1920) gives 8, at `gridMin` 152 and gap 20.
- **Image arrival:** the placeholder is `surface2` with the ambient hue at 12 %; the image arrives with opacity 0 → 1 over `curveFadeIn` and scale 1.02 → 1 on `springSnappy`. Each poster wraps itself in `GlassLbItem(lMax: palette.lMax)`, so bars above it thicken over pale covers.
- **Overlays** (every overlay sits on an opaque backing, because a cover can be white): a status tag top-left (item M, the cover recipe), an "N NEW" badge top-right (`iris400` capsule, black `caption1` 700, "99+"), the downloaded droplet bottom-left (`success` 16 px on a 22 px `rgba(0,0,0,0.72)` circle), an 18+ capsule top-left when mature and the gate is open (the status-tag cover recipe in `mature` `#FF5C93`), the favourite star and the `age-gate` glyph each on a 22 px `rgba(0,0,0,0.72)` disc, and progress as a 3 px `iris500` bar inside a 5 px `rgba(0,0,0,0.86)` track along the bottom inside the radius.
- **Corner conflicts:** on hover-pointer hover and on keyboard focus, the status tag and the "N new" badge fade out over 120 ms while the favourite star (top-left, 8 px inset) and the follow bell (top-right, 8 px inset) fade in on 32 px `rgba(0,0,0,0.86)` discs; the 18+ capsule moves to the bottom-right while those show. In select mode the status tag, badge, star and bell hide, the check orb takes the top-right, and the new-chapter count stays in the semantics label ("Solo Leveling, 3 new").
- **Press and lift (touch), physics in `poster_throw.dart` with `poster_throw_test.dart`:** a release before 450 ms within the slop (10 px; 18 px inside a scroll view, `thresholdDragSlopTouchScroll`) is a tap (the growth between 150 and 450 ms is only a preview). At 150 ms (`thresholdLiftStart`) the poster starts growing toward 1.06, reached at 450 ms (a 300 ms linear ramp of the scale target), and its shadow deepens to `0 18px 40px rgba(0,0,0,0.55)`, firing `press.lift`. At 450 ms (`thresholdLiftMenu`) it calls `onContextPreview()` (`mobile/27`'s context menu takes `dimContext`, raises the poster to 1.12 and blooms the `glassThick` menu beneath; `longpress.open` fires there). While lifted the poster is a physical object: drag moves it 1:1 (x and y on two `SingleMotionController`s with `SpringMotion(springOf(springZoom))`, set directly during the drag); on release, `decideThrow({centre, velocity, viewport, targets, allowAway})` (pure) returns: `open` when the projected centre is above the top 20 % of the screen or `vy ≤ −1,200 px/s` (`onThrowOpen(velocity)`; the `heroine` zoom of `mobile/29` inherits the velocity); `away` when `allowAway` (AI cards) and the projected centre passes a side edge or `|vx| ≥ 1,200 px/s` (`onThrowAway`, "Not interested", the poster leaves on `springDismiss` with the release velocity); `target(id)` when the poster is within 64 px of a registered friend-orb target (`Magnet`: `magnet.capture` on capture, `magnet.drop` on release, `onDropOnTarget(id)`); otherwise `drop`, back into place on `springZoom` via `animateTo(0, withVelocity: v)`. A committed throw fires `throw.commit` with `impactIntensity(v)`. A touch during the return catches it (`stop()`, `motion.catch`). Reduced motion: the outcome happens with a 150 ms fade.
- **Hover (a hover pointer):** tilt up to 6° (`Transform` with `Matrix4.rotationX`/`rotationY` on `springTrack`), a white radial specular highlight at 12 % following the pointer, lift −2 px; after 600 ms of rest a peek capsule (the content twin of `glassThin`) grows out of the bottom edge on `springMorph` with "Continue Ch 12" or "Open" and a ⋯ button; `Esc` closes it, it stays while the pointer is over it or within 8 px of it, and it never disappears on its own while hovered or focused.
- **Keyboard:** focus scale 1.04 + ring; `.` or `Shift+F10` from a hardware keyboard calls `onContextPreview`; `Enter` opens. Screen readers: a "More actions" custom semantics action calls `onContextPreview` (the long press's alternative, §11).
- **States:** as the cards in H.

### J. Rails (`primitives/rail.dart`, `rail_group.dart`, `rail_columns.dart`, §7.9)

- **Header:** `title2` rendered through `LetterReveal` (first appearance per session, item P) with `revealKey`, an optional subtitle `footnote` `label2` ("Because you read Solo Leveling"), and a trailing "See all" plain button; the scroller 12 px below.
- **Scroller:** a horizontal `ListView.builder` (lazy beyond any count), padding: horizontal = `GlassFrame.screenMargin`, vertical 8 (focus rings never clipped); gap 12 on phones, 16 on tablet and desktop frames; posters peek at the trailing edge (2.8 posters visible at 390 px wide; 1.6 at `f ≥ 1.9`).
- **Physics:** `SnapPhysics(stride: posterWidth + gap, settle: springSettle)` from `glass_physics.dart`: free momentum, the ballistic end projected and rounded to the stride, `springSettle` (k 322.3, c 35.90) carrying the remaining velocity into the snap; rubber band at both ends (`BouncingScrollPhysics` parent). No snapping while a finger is down (the simulation starts only on release).
- **Page arrows** (tablet and desktop frames with a hover pointer): content-twin 44 px circles (`rgba(19,19,23,0.62)` fill, 0.5 px `rgba(255,255,255,0.22)` rim, inner light, no backdrop read; hover `rgba(40,40,48,0.72)`), fading in over `curveFadeIn` at each end when the pointer enters the rail and out 300 ms after it leaves; they do not count toward the glass budget; each press scrolls by (visible count − 1) posters on `springPage`.
- **Keys (`GlassRailGroup`, hardware keyboards):** each rail is one tab stop (a `FocusTraversalGroup` whose items skip traversal except the remembered one); `←`/`→` move focus within a rail (the list scrolls the item into view with 8 px of padding); `↑`/`↓` move between rails of the same group keeping the column (`railColumn(fromIndex, fromScroll, toScroll, stride)` pure, tested).
- **States:** loading (4 to 8 skeleton posters with the header already in place); empty (the rail renders nothing, unless it is an AI rail, which renders its `unavailable` slot: `mobile/28`'s `AiNotice`); error (a 120 px tall inline card "Couldn't load this row" with a "Retry" plain button); partial (the loaded posters plus a trailing skeleton while tier-2 sources answer).

### K. Skeletons "wet glass" and the entrance wave (`primitives/skeleton.dart`, `wave.dart`, §7.18, §4.8)

- `GlassSkeleton`: excluded from semantics; the region it fills carries a semantics value "Loading"; shapes and radii match the content they stand for; fill `surface2` `#1A1A20`; a sheen band 40 % of the element's width (`LinearGradient` from transparent through `Color(0x0DFFFFFF)` back to transparent, angled 100°) sweeping left to right every 1,400 ms (`curveShimmer`, linear; 2,800 ms for AI skeletons), one `AnimationController` per skeleton group, phase-offset 60 ms per row so the sheen travels down a list; skeletons appear only after 180 ms. Reduced motion: static `surface2`.
- `wave.dart`: `Map<int, Duration?> waveDelays(List<Rect> items, Offset cause, Rect viewport)` → `delay_i = min(distance_i / 1.6 px·ms⁻¹, 240 ms)` from the cause point (the touch point for taps, the source element's centre for route arrivals, the top-left of the list for data arrivals); items outside the viewport get `null` (no entrance). `GlassWave` runs each item's entrance through `GlassMotion` (the Wave row): opacity 0 → 1 over `curveFadeIn` and a 12 px translate toward rest from the cause's direction plus scale 0.98 → 1 on `springSnappy`. Exits never stagger. Reduced motion: everything fades together over 150 ms. `wave_test.dart` checks the delays, the 240 ms cap and the viewport exclusion.

### L. Progress (`primitives/progress.dart`, `liquid_progress.dart`, §7.19)

| Kind | Visual | Motion |
|---|---|---|
| `linear` | 4 px capsule track `fill1`, fill `iris500` (variant `success`), a 1 px `iris300` leading highlight | width on `springSnappy` |
| `hairline` (reader, novel running head) | 2 px, fill `iris500` at 80 % | follows on `springTrack` |
| `ring` | 24 or 32 px, 3 px stroke, track `fill1`, arc `iris500`, round caps | arc on `springSnappy` |
| `LiquidProgress` (downloads meter, storage, hold-to-confirm, progress button) | inside a capsule, the filled part is `iris600` at 60 % (`Color(0x997563F2)`) with a meniscus: its leading edge curves 3 px and wobbles when the value changes | the level follows on `springLens` (k 223.8, c 20.94, bounce 0.3) through a `SingleMotionController`, so a jump sloshes once; the meniscus bulge is `3 px + clamp(velocity / 400, −3, 3) px` from the controller's velocity |
| `spinner` (liquid ring, indeterminate) | a 16 or 24 px ring whose 90° arc stretches to 270° and back while rotating once per 900 ms | loop; reduced motion: a static ring pulsing opacity 0.4 ↔ 1 over 1.2 s |
| `dots` (button loading) | 5 px `onGlass` dots 6 px apart | each bobs 3 px on `springTick`, 80 ms apart |
| `segmented` (read-all scrub, storage breakdown) | a capsule divided into segments with 2 px gaps | segment widths on `springSnappy` |

Semantics: a label and a value ("12 of 40 pages saved"), updated at most once a second. States: default (determinate); loading (indeterminate: the spinner, or a 30 % band sweeping a linear track every 1.2 s); complete (the fill turns `success` and a check springs in on `springTick`); paused (fill `warning` at 60 %, the meniscus still); error (fill `danger`, a retry glyph at the end); disabled (track and fill at 40 %). Reduced motion: values jump, no meniscus wobble. Indicators have no hover, pressed or selected state.

### M. Badges and markers (`primitives/badge.dart`, §7.20)

| Badge | Visual |
|---|---|
| `count` | min 18 × 18 capsule, `iris400` fill, black `caption1` 700 (8.82:1); "9+" above nine (dock and bell), "99+" on posters; pops 1 → 1.25 → 1 on `springTick` when the count changes (Count pop) |
| `dot` | an 8 px `iris400` circle with a 2 px black ring |
| `new` | "N NEW" capsule, `iris400` with black text, top-right on posters |
| `status` | a 22 tall capsule, `caption1` 600 uppercase +0.06 em: READING `iris400`, COMPLETED `success`, ON HOLD `warning`, PLAN TO READ `info` `#6CB8FF`, DROPPED `g700`, UNREAD `g800`. On black and slabs: the colour at 18 % over black with the colour as text. On a cover (`onCover`): no wash; colour text on a `rgba(0,0,0,0.86)` capsule with a 1 px rim in the colour at 40 % |
| `mature` | a 20 tall capsule, `mature` at 18 % with `mature` text "18+" on black; on a cover the status-tag cover recipe in `mature`; or the `age-gate` glyph 14 on a 22 px `rgba(0,0,0,0.72)` disc |
| `source` | a 20 tall capsule `fill3`, a 12 px favicon (or the 12 px monogram tile) + the source name `caption1` |
| `downloaded` | the `droplet` glyph 14 `success`; on a cover on a 22 px `rgba(0,0,0,0.72)` circle |
| `offline` | "Saved copy · 2 h" capsule, `warning` at 18 % |
| `role` (Admin, You, This device) | a 20 tall capsule `fill2`, `caption1` 600 `label1` |
| `friend` | an 18 px friend orb with a `bloom` ring (item N) |

Badges are never the only signal: every badge contributes a text fragment to its host's semantics label through `badgeLabel()` ("Solo Leveling, 3 new chapters, downloaded"). Badge text uses the 1.5 clamp. States: default; loading (a 10 px spinner in place of a count); updated (the pop); disabled (40 % with the host); error (a `warning` dot replaces a count that failed to load).

### N. Profile orbs and the goal ring (`primitives/profile_orb.dart`, `goal_ring.dart`, §7.26, §9.2.2)

- **Profile orb:** a circle with the preset's two-colour gradient (top-left → bottom-right) and a Light-weight glyph in the preset's glyph colour; sizes 18, 20, 24, 32, 44, 56, 64, 72, 96, 112, 128, 132; a 2 px ring in the profile's mood colour at 60 %; on glass surfaces the orb gets a glass bezel (0.5 px rim + specular).
- **Presets** (from `GlassTokens` `colorAvatar<Preset>`; these are the values): Violet Spark `#8B5CF6 → #D946EF` `sparkle` white; Cyan Rocket `#06B6D4 → #0EA5E9` `rocket-launch` dark; Rose Heart `#F43F5E → #EC4899` `heart` white; Amber Coffee `#F59E0B → #F97316` `coffee` dark; Emerald Cat `#10B981 → #14B8A6` `cat` dark; Ember Flame `#EF4444 → #F59E0B` `flame` dark; Steel Blade `#94A3B8 → #475569` `sword` dark; Phantom `#6366F1 → #334155` `ghost` white; Arcane Wand `#A855F7 → #6366F1` `magic-wand` white; Lunar Moon `#0284C7 → #4338CA` `moon` white; Starlight `#FACC15 → #F59E0B` `star` dark; Bookworm `#14B8A6 → #0891B2` `book-open` dark ("dark" = `rgba(0,0,0,0.85)`, "white" = `#FFFFFF`).
- **Idle drift** (`drift: true`, the picker only): ±3 px on a sine with a 5 to 7 s period and a random phase; frozen under reduced motion.
- **Friend orb:** the same orb with a `bloom` `#FF9ED8` ring; 18 px as the Friend badge, 32 px in activity rows, 56 px as drop targets (it registers as a `Magnet` target through `registerAsTarget`).
- **Names** under or beside an orb and in chips: one line with an ellipsis; the semantics label carries the full name.
- **`GoalRing`:** with a daily goal set, a 2 px ring 3 px outside the orb fills clockwise from 12 o'clock with today's minutes toward the goal, in `streak` `#FF8A3D` at 80 %; on `goal.met` it closes and fills solid for 600 ms (`success`, then a shimmer; the Goal ring close move), then stays closed in `streakCore` `#FFD166` for the rest of the local day. Semantics "Today: 8 of 10 minutes". On glass hosts other than the edge plateau and the docked sidebar it sits on a backing disc 8 px wider than the ring (`onDisc: true`).
- **States:** default; hover (scale 1.04, or 1.08 at size ≥ 96 on the picker, + the specular sweep); pressed (grows +12 px); focused (the ring outside the mood ring); disabled (40 %); loading (the glyph becomes a spinner); selected (the mood ring becomes 3 px `iris300`); error (a warning glyph overlay).

### O. Tooltips and keycaps (`primitives/tooltip.dart`, `keycap.dart`, §7.27)

- **`GlassTooltip`** (built on `OverlayPortal`, `MouseRegion` and `Focus`; not Material's `Tooltip`): a `glassThin` T2 capsule, min height 36, padding 9 12, `footnote` `onGlass`, 8 px from its target, `GlassLayerKind.hud`; delays by level: 0 ms for icon-only buttons on hardware-keyboard focus, 150 ms for the dock and the collapsed sidebar (`level: bar`), 600 ms for everything else on hover; appears on `springSnappy` from scale 0.9 while materialising; follows its target if it moves. On touch, a long press shows it (held while pressed and 1,500 ms after release) only for icon-only buttons that have no long-press action of their own. WCAG 1.4.13: `Esc` closes it without moving focus; it stays while the pointer is over it or within 8 px; it never disappears on its own while its target is hovered or focused. It is a live glass surface in the registry. The tooltip text is also the control's semantics `tooltip`.
- **`GlassKeycap`:** `mono` 12/600 `label1` on `surface3`, radius 6, min width 20, height 20, a 0.5 px rim; combos separated by 4 px; `keycapLabel(SingleActivator)` renders `⌘ ⌥ ⇧ ⌃` on iOS and `Ctrl`, `Alt`, `Shift` words on Android. Used in tooltips and trailing menu rows in tablet and desktop frames.

### P. The heading reveal: `primitives/letter_reveal.dart` (§10.1, §15.7)

Start from the Flutter code in §10.1 (`LetterReveal`, `_LetterRun`, `revealWhenVisible`, the wrap units that keep Latin words on one line and let CJK runs break between graphemes, `Semantics(header: true, label: text)` over `ExcludeSemantics` on every path, `MediaQuery.withClampedTextScaling` at the role's cap, `AnimatedDefaultTextStyle` over `colorShift`, the keyed `AnimatedSwitcher` for new text) and complete it:

| Parameter | Value |
|---|---|
| Unit | grapheme (`characters`) |
| Opacity | 0 → 1 over `curveFadeIn` (180 ms `Cubic(0.2, 0, 0, 1)`) |
| Translate | +0.40 em → 0 on the `letter` spring `{424 ms, bounce 0.12}` (k 219.6, c 26.08) |
| Blur | 12 px → 0 on the same spring (`ImageFiltered`, dropped once under 0.05 σ) |
| Scale | 0.96 → 1 on the same spring |
| Stagger | 24 ms per grapheme; spaces take no time |
| Glint | 120 ms after the last letter settles, a 30° band (white at 18 %, 40 % of the heading's width) sweeps once, left to right, over 500 ms: a `ShaderMask` with a `LinearGradient` rotated by `GradientRotation(π / 6)` |
| Colour on hover and state | `curveColorShift` 240 ms |
| Size and tracking | the role's responsive size with tight tracking (`largeTitle` −0.020 em, `title2` −0.010 em, `display` −0.025 em) |
| Limit | above 60 graphemes the run animates per word with the same parameters at 40 ms per word |

1. **Starts at first visibility:** `revealWhenVisible` fires once at 25 % of the heading inside the nearest `Scrollable`'s viewport (a heading outside any scroll view fires after the first frame); never on mount.
2. **At most two at once (§15.7):** `reveal_slots.dart`, a module-level slot counter (pure queue, tested): a third heading becoming visible waits and starts when a running reveal ends (`n × 24 ms + 345 ms + 120 ms + 500 ms`), if it is still visible; otherwise it completes at once.
3. **Once per session per profile:** `revealedHeadingsProvider` (`Provider<Set<String>>`, read once in `initState`, never watched) holds `"{profileId}:{screenId}:{headingKey}"`, added when the reveal starts; the hero title and chapter seams (`revealKey` null) play whenever their text changes or they enter the viewport.
4. **Interruptibility:** scrolling the heading fully off-screen, a tap on it, or a route push over it (its `ModalRoute`'s `secondaryAnimation` starts) completes it instantly; keyboard focus arriving on the heading (route focus) does not.
5. **Live text:** a new string lets the old letters leave together over `curveFadeOut` with blur 4 px while the new wave starts (the `AnimatedSwitcher` path of the §10.1 code; the Home spotlight title uses it in `mobile/31`).
6. **Reduced motion** (`glassMotionPrefsProvider.reduced`): the full text at once, no glint.
7. Placements are wired by the screens (tab-root and pushed large titles, rail headers, the hero title, series and book titles, chapter seams, onboarding, For you, Statistics, Wrapped, the splash wordmark, Setup, the picker title); this step builds the widget and uses it in rail headers.

### Q. The typing reveal: `primitives/typed_headline.dart` (§10.2)

Build it exactly as §10.2's Flutter note says: a `StatefulWidget` with a `Ticker` setting `visible = min(n, elapsed ~/ 50 ms)` (timestamp-based, so dropped frames never slow it) and stopping itself at `n`; one `Text.rich` laid out in full from frame 0, whose first `visible` graphemes use the style's colour and whose tail uses `Color(0x00000000)` (layout never changes); each newly visible grapheme a `WidgetSpan` fading in over 40 ms while scaling 0.8 → 1 on `springTick`; the caret a `CustomPaint` capsule 2 px × 0.72 em in `iris400` `#A99BFF` with a 1 px white centre line and a 6 px glow `Color(0x73A99BFF)`, positioned from `TextPainter.getOffsetForCaret(TextPosition(offset: visibleCodeUnits), Rect.zero)` and moving on `springTrack`; when typing ends it blinks three times (530 ms on, 530 ms off) and dematerialises (blur 0 → 6 px, opacity 1 → 0, 350 ms `curveDematerialize`); a cap of 48 graphemes, the tail fading in as one span over 200 ms when the ticker reaches 48; **skip** on a `GestureDetector` `onTapDown` on the headline, on a hardware key event while focus is on the headline or while no widget holds primary focus, and on navigating away (the caret still blinks and leaves); **focus arriving on the headline never skips it** (`Focus(onFocusChange:)` is not used for skipping); once per app session per profile per placement (`"{profileId}:{placement}"` added to `revealedHeadingsProvider` when the ticker starts); `Semantics(header: level != null, headingLevel: level, label: text)` over `ExcludeSemantics`; no haptic and no sound per character; reduced motion renders the plain `Text` at once with no caret. Placements (Home greeting, Login heading, onboarding's first step, the Wrapped cover, the recap deck heading) are wired by their screens.

### R. The primitives gallery

`mobile/lib/skins/glass/dev/glass_gallery.dart` at the development route `/dev/glass/primitives` (declared in `router.dart` beside `/dev/glass`; add a "Primitives gallery" row to the index), with a `section` query parameter, inside `GlassBudgetScope(exempt: true, label: 'gallery')` over the brand-aurora ambient field. One section per family: `buttons`, `hold`, `icon-buttons`, `inputs`, `search`, `chips`, `segmented`, `cards`, `posters`, `rails`, `skeletons`, `progress`, `badges`, `avatars`, `tooltips`, `reveals`. Each shows every variant in every state (forced through `forceStates` for hover, pressed and focused; real props for disabled, loading, selected and error) over three grounds side by side on tablet and stacked on phones: black `#000000`, the ambient field, and a white `#FFFFFF` panel (to show the legibility dim and the backing discs). Covers come from `dev/calibration_covers.dart` (the painted demo palettes of `mobile/25`). The `reveals` section has a `TypedHeadline` "Good evening, Yash" (placement `gallery:greeting`) at the top, and three rails far below the fold whose `LetterReveal` headers enter the viewport together when scrolled, plus a 70-grapheme heading for the per-word mode. A toolbar (content layer, `hitMin` controls) toggles Solid glass, Increase contrast and Reduce motion through the in-app keys.

### S. Tests and captures

Under `mobile/test/skins/glass/primitives/`:

- `hold_test.dart`, `poster_throw_test.dart` (open by position and by −1,200 px/s, away only with `allowAway`, target within 64 px and not at 65, drop otherwise), `wave_test.dart`, `segmented_math_test.dart`, `rail_columns_test.dart`, `poster_columns_test.dart`, `reveal_slots_test.dart`.
- `letter_reveal_test.dart`: the §10.1 check (a 40-grapheme title of several words at 200 px width: no word's letters on two lines; then a change to a longer title: no `RangeError`); a heading below the fold stays at opacity 0 until 25 % visible and then runs; with focus requested on the heading at 100 ms it still runs (focus does not complete it); a tap completes it; three headings entering together run at most two at once and the third starts when one ends; a second pump in the same session (same profile) shows it at rest; reduced motion renders the plain text; above 60 graphemes it animates per word.
- `typed_headline_test.dart` (the §15.8 check on Flutter): request focus on the headline at 100 ms; at 200 ms the 10th grapheme's span is still `Color(0x00000000)` (focus did not skip the typing); when grapheme 6 is visible the caret's offset is past grapheme 0 (letters and caret started together); after `n × 50 ms + 3 × 1,060 ms + 350 ms + 200 ms` every grapheme is visible and the caret is gone; `onTapDown` completes it; a key event with focus on the headline completes it; the layout width of frame 0 equals the final width; a second pump in the same session shows the text at once; reduced motion renders the plain `Text` with no caret; a 60-grapheme headline types 48 and fades the tail in.
- `primitives_a11y_test.dart`: pump every gallery section at 390 × 844 under `TargetPlatform.iOS` and `TargetPlatform.android`: `meetsGuideline(iOSTapTargetGuideline)` (44) and `meetsGuideline(androidTapTargetGuideline)` (48), `meetsGuideline(labeledTapTargetGuideline)`; hardware-keyboard `Tab` reaches every control and each shows the `GlassFocusRing` unclipped; the segmented control moves with arrows and `Home`/`End`; a rail is one tab stop with `←`/`→` inside and `↑`/`↓` between rails keeping the column; a tooltip closes on `Esc`; `HoldToConfirm`: `Enter` is a click (calls `onRequestConfirm`), a 1,300 ms hold confirms, a 600 ms hold aborts and shows the helper for 2 s, 10 px of movement before 200 ms cancels with no click, `hold.ramp` appears in `GlassHaptics.debugLog` every 150 ms; in `inAlert` mode the fallback button is visible without interaction; constant-label toggles expose `toggled` with fixed labels; an invalid field exposes its error.
- `primitives_budget_test.dart`: no chip (the choice droplet and a selected chip's glass included), poster, card, row action or rail arrow creates a `BackdropFilter` or an `AdaptiveGlass`; the only transient live glass is the segmented thumb while dragged (the registry count rises by one during the drag and returns after).
- `primitives_reduced_test.dart` and `primitives_solid_test.dart`: reduced motion (glass press is glow only, content press a `fill2` wash, no shake, no stretch, skeletons static, spinners pulse, liquid levels jump, reveals show full text, the rail snap and droplet moves become 150 ms fades); Solid glass (`#1C1C22` / `#26262E`, 1 px `rgba(255,255,255,0.10)` rim, primary `#5B4AD1` with `#4A3CB0` pressed, no caustic, no sweep).
- Harness captures (`mobile/test/screenshots/glass_primitives_shots_test.dart`, reusing `support/skin_shots.dart` (`captureSkinScreen`, `captureSkinWidget`); the test renderer draws the frost path): one capture per gallery section at phone 390 × 844 and tablet 834 × 1194 (`<section>-{phone,tablet}.png`), each section again with Solid glass (`<section>-solid-phone.png`) and Increase contrast (`<section>-contrast-phone.png`), plus `reveals-typing-200ms-phone.png` (pumped to 200 ms), `reveals-rails-running-phone.png` (two headers running, the third waiting), `poster-lift-phone.png` (pumped to 450 ms of a press), `hold-aborted-phone.png` (the helper showing), into `docs/redesign/proof/mobile-26/`.
- `docs/redesign/proof/mobile-26/device-check.md` for the owner (iPhone through SideStore, the Android flagship with a signed APK built where the key lives, never on this box), one line per check with an empty result box: Glass development → Primitives gallery; press swell and stretch on a button and an icon button feel liquid at 120 Hz with 0 dropped frames in the Glass motion-timings overlay; the poster lift at 150 and 450 ms and a throw up, sideways (AI card) and onto a friend orb; the rail snap after a fling; the choice droplet and the segmented thumb drag; the hold-to-confirm haptic ramp; the typed greeting and the letter reveals on the rails; VoiceOver and TalkBack read every control's label and state; Reduce Motion and Reduce Transparency variants.

## Out of scope here (owned by later steps; do not build)

- `mobile/27`: sheets, alerts (`confirmAlert()`), toasts, tabs and pagers, sliders, switches, the Stepper, menus and context menus (the poster's context preview and the split button's menu attach there), banners, the image viewer, scroll edges, pull to refresh, the content-mode switch.
- `mobile/28`: lists, swipe rows, reorder and bulk selection, empty, error and offline states and `copy/errors.dart`, the 18+ gate alert (which uses `HoldToConfirm(mode: HoldMode.inAlert)`), the download control, the depth glyph, AI surfaces (`AiNotice`, `ThinkingOrbit`), charts, `ReactionPicker`, the stack-overview snapshot primitive.
- `mobile/29`: the dock, search orb, sidebar, top bars, the command palette, the stack overview that the nav button's long press opens, the `heroine` poster zoom.
- Every screen and every placement wiring of the two reveals.

## File layout

```
mobile/lib/skins/glass/primitives/
├── press.dart, lit.dart                                    A
├── glass_button.dart, split_button.dart                    B
├── hold_to_confirm.dart, hold.dart                         B
├── icon_button.dart, glass_group.dart                      C
├── text_field.dart, text_area.dart                         D
├── search_field.dart                                       E
├── chip.dart, chip_row.dart                                F
├── segmented.dart, segmented_math.dart                     G
├── cards/series_card.dart, continue_stack.dart, world_card.dart, result_card.dart, stat_card.dart,
│   collection_card.dart, notification_card.dart, source_row_card.dart, health_bead.dart,
│   source_monogram.dart, history_tile.dart                 H
├── poster.dart, poster_grid.dart, poster_throw.dart        I
├── rail.dart, rail_group.dart, rail_columns.dart           J
├── skeleton.dart, wave.dart                                K
├── progress.dart, liquid_progress.dart                     L
├── badge.dart                                              M
├── profile_orb.dart, goal_ring.dart                        N
├── tooltip.dart, keycap.dart                               O
├── letter_reveal.dart, reveal_slots.dart, revealed_headings.dart   P
└── typed_headline.dart                                     Q
mobile/lib/skins/glass/dev/glass_gallery.dart               R
mobile/lib/skins/glass/router.dart                          /dev/glass/primitives (R)
mobile/lib/skins/glass/dev/glass_dev_index.dart             "Primitives gallery" row (R)
mobile/test/skins/glass/primitives/*_test.dart              S
mobile/test/screenshots/glass_primitives_shots_test.dart    S
docs/redesign/proof/mobile-26/                              plan.md, captures, device-check.md, report.md
```

Glass files import only `features/*/{models,providers,repositories,services,store,queue,utils,controllers,engine}`, `core/`, `shared/`, the pinned packages and their own `skins/glass/**`; `import_boundary_test.dart` bans `skins/cinematic/**`; only `skin_glass.dart` imports `liquid_glass_widgets`.

## Acceptance criteria

- [ ] Every primitive in items B to Q exists with every state of its section, visible in the gallery over black, the ambient field and white, on phone and tablet.
- [ ] Press physics: glass controls grow (+12 px Medium, +17 px capped at 0.35 × side Light) on `springPress` with the glow at the touch point and the stretch toward a drag; content sinks (0.97 / 0.99 / 0.96 / 0.92); a drag beyond 1.5 × the hit area cancels with no activation and no haptic.
- [ ] `HoldToConfirm`: the fill starts at 200 ms and completes at 1,200 ms with `hold.ramp` every 150 ms and `hold.done`; click, cancel and aborted hold behave as specified; `Enter`/`Space` and the screen reader's activate are clicks; the `inAlert` fallback button is always visible; the `standalone` click calls `onRequestConfirm`; reduced motion steps the fill in 4 increments.
- [ ] One lit object per screen: two visible `tinted` objects outside an overlay warn in debug; `suppressLit()` drops the lit object to `glassThin` and fades its caustic over 180 ms.
- [ ] Posters: the lift starts at 150 ms (1.06 at 450 ms, `press.lift`), `onContextPreview` fires at 450 ms, a tap is a release before 450 ms within the slop; the throw decisions follow `poster_throw_test.dart` on `motor` springs with the release velocity and can be caught; `.`/`Shift+F10`, `Enter` and the "More actions" semantics action work.
- [ ] Rails: after a fling the scroll rests on a multiple of `posterWidth + gap` through `SnapPhysics` on `springSettle`; page arrows page by (visible − 1) on hover-pointer frames; the hardware-keyboard model (one tab stop, `←`/`→`, `↑`/`↓` keeping the column) passes.
- [ ] Content twins: no chip, poster, card, row action or rail arrow creates a live glass surface; the only transient live glass is the dragged segmented thumb.
- [ ] Every interactive element's hit area is at least 44 × 44 on iOS and 48 × 48 on Android (`meetsGuideline`), with at least 8 px between adjacent hit areas or one merged glass group; every icon-only control has a label and a tooltip.
- [ ] Hardware keyboard: every control is reachable and operable and shows the two-tone focus ring (3 px `iris300` under Increase Contrast), never clipped (rails and chip rows pad 8 px).
- [ ] Reduced motion (the OS flag and the in-app switch): glass press is glow only, content press a `fill2` wash, no shakes or stretch, skeletons static, spinners pulse, liquid levels jump, the reveals show full text, the rail snap and droplet moves become 150 ms fades.
- [ ] Solid glass: every glass primitive renders its solid recipe, the primary is `#5B4AD1` with `#4A3CB0` pressed, and no caustic or sweep appears (captures of each section).
- [ ] `letter_reveal_test.dart` and `typed_headline_test.dart` pass: typing still runs 200 ms after navigation with focus on the headline, letters and caret start together, tap and key skip, once per session, reduced motion shows everything at once; a below-the-fold header waits for 25 % visibility; at most two letter reveals run at once; no word breaks across lines.
- [ ] All tests under `mobile/test/skins/glass/primitives/` pass; the captures and `device-check.md` are in `docs/redesign/proof/mobile-26/`.
- [ ] Per-skin difference: nothing under `mobile/lib/skins/cinematic/` changed; the Cinematic harness captures of Tonight and Library are identical before and after.
- [ ] Glass `PENDING` is unchanged; the completeness and boundary tests pass.
- [ ] `flutter analyze` reports "No issues found"; `flutter test` passes at or above the floor plus the new tests (never below the 2012 passed of `00-baseline.md`: every test that passed there must still pass); `node design/build.mjs --check` passes.

## Verification

**RAM guard (production shares this box).** Before every heavy command run `free -m` and read the `available` column of the `Mem:` row. If it is under 1024 MB, stop and report instead of running it. Never run two heavy commands at once, never run `flutter test` while a `next build` runs (`pgrep -fa "next build"` prints nothing first), and no Gradle or Xcode on this box (CI builds the APK and the iOS dry run).

From `mobile/`:

```bash
free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze
free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter test test/skins/glass
free -m && MM_PROOF_DIR=../docs/redesign/proof/mobile-26 /srv/manhwamaniacs/dev/flutter/bin/flutter test test/screenshots/glass_primitives_shots_test.dart
free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter test
cd .. && node design/build.mjs --check
```

**Proof output location.** The `mobile/03` harness (`mobile/test/screenshots/support/skin_shots.dart`) writes a capture only when `MM_PROOF_DIR` is set, so every proof command in this file sets `MM_PROOF_DIR=../docs/redesign/proof/mobile-26` (relative to `mobile/`) and never `MM_WRITE_SHOTS`, which makes the legacy marketing tests overwrite `mobile/docs/screenshots/`, the install page's public screenshots. Capture routes with `captureSkinScreen` and everything that is not a route (a gallery section, a sheet or menu held open, a state pumped with fixture providers, a mid-animation frame) with `captureSkinWidget`, which writes `<name>-<size.name>.png`; the capture names in this file are those final file names. The only proof sizes are the harness constants: `kSkinShotSizes` (phone 390 × 844 at 3×, tablet 834 × 1194 at 2×), `kSkinShotTabletWide` (1024 × 1366; on Glass the desktop frame with the collapsed 76 px sidebar, on Cinematic the ≥ 900 px rows of §8.0.9) and `kSkinShotLandscape` (landscape phone 844 × 390). After every capture run, `git status --short mobile/docs/screenshots` must print nothing.

`flutter analyze` must report "No issues found" and the full `flutter test` run must pass with no failures, at or above the floor. This step changes nothing in `frontend/` or `backend/` (`git diff --stat origin/feat/vps-slim-source-native -- frontend backend` is empty), so `npm run lint`, `npm run build` (in `frontend/`) and the backend pytest (`backend/.venv/bin/python -m pytest -q --no-header` from `backend/`) are not rerun, except the push rule under Git.

**Visual proof.** The captures of item S land in `docs/redesign/proof/mobile-26/`. Compare each phone capture with the web twin's `docs/redesign/proof/web-26/<section>-phone.png` when present and list the differences the contract does not explain (stack-decision risk 1). Write `docs/redesign/proof/mobile-26/report.md` mapping each capture to the acceptance item it proves.

## Git

- Branch `feat/vps-slim-source-native`. Commit small and often, one component family per commit with its tests (`feat(mobile-glass): HoldToConfirm with the 1,200 ms liquid hold`), then the gallery, then the tests that span families, then the captures and proof. Stage your paths explicitly (`git add mobile/lib/skins/glass/primitives/hold_to_confirm.dart …`), never `git add -A` or `git add .`, because the web, backend and shared sessions commit in the same checkout.
- No Claude or AI attribution anywhere: no `Co-Authored-By` line, no "Generated with" line, no AI author. Never commit secrets or `.claude/`.
- Before every push: `git fetch origin` and `git diff --stat origin/feat/vps-slim-source-native...HEAD -- frontend`. If it lists files (another session's commits), run `free -m && npm run build` in `frontend/` first (never while `flutter test` runs) and push only if it passes; then `git push origin feat/vps-slim-source-native` after each working step.
- Never edit `backend/connectors/`. Never touch production containers or `/srv/manhwamaniacs/{app,data}`. Do not deploy: Glass stays behind the debug row until `release/01`.

## Report back

Reply with:

1. Done items by letter (A to S), and anything not done with the reason.
2. Any token key missing from the generated files (avatar presets, type roles), for the shared track, and any `motor` API name that differed from this file.
3. The capture folder `docs/redesign/proof/mobile-26/` and its file list, and `device-check.md`.
4. Test counts: `flutter test` passed, failed and skipped before and after; `flutter analyze` result; `build.mjs --check` result; the `free -m` available figure before each heavy command.
5. The differences from the web twin's captures that the contract does not explain.
6. Open issues, each with its `glass/DESIGN.md` section.

Next prompt file: `docs/redesign/prompts/mobile/27-glass-primitives-overlays.md` (`docs/redesign/prompts/web/27-glass-primitives-overlays.md` runs in parallel).
