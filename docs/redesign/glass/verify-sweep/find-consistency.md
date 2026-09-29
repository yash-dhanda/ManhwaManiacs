# Glass DESIGN.md: follow-up sweep, lens consistency

Target: `glass/DESIGN.md` as of 2026-09-29 (831,757 bytes, 4,612 lines). The whole file was read, section by section. Line numbers below are from that state; section numbers are authoritative.

Automated checks run first:

- All 20 springs were recomputed from `{ms, bounce}`: k, c, settle and overshoot match §4.2 and the `--mm-spring-*-ms` values of §2.8.5.
- The Flutter alpha bytes of every `rgba()` token in §2.8.1 and §2.8.4 were recomputed and all match.
- The label, g-ramp and paper contrast values in §2.1.1, §2.1.2 and §8.15.1 were recomputed with the WCAG 2.x formula and all match.
- Every spring or curve name used as "on `x`" is defined in §4.2 or §2.8.5.
- Every haptic and sound event name used in the file is in §5.2 or §6, and §15.6's list of added names is a subset of them.
- Every `?sheet=` id used in the file is in the §8.0.3 list.
- The §3.3 scale table, the §7.8 column and rail counts, and the §15.8 physics fixtures were recomputed and all match.

The findings of the earlier `verify/` round are not repeated here. Findings are listed most severe first.

---

## CONSISTENCY-1

- **Severity:** medium
- **Section:** §2.4.3 (size snap) vs §7.10, §7.28, §8.25.14, §8.29, §15.3 **Sheets**, §2.4.1 Massive row, §15.8
- **Problem:** The size-snap rule gives many large glass surfaces a different tier from the one their component spec declares, in both directions. An implementation that uses `tierFor(shortSide)` (§15.3 `glass_physics.dart`) builds these surfaces at the wrong tier: blur 32 instead of 22, a different fill, shadow and dispersion, and `ROND` 100 instead of 80 on their text. Two 560 px windows also get different tiers from each other.
- **Evidence:**
  - §2.4.3, line 414: "A free-sized glass object (a context menu, a sheet, a popover, a window) **snaps by its shorter side**: … `97–400 → T4`, `> 400 → T5`."
  - §15.8: "`tierFor(401) == T5`".
  - §7.10, line 1731: the desktop panel is "440 wide … `glassThick`". The snap gives 440 → T5.
  - §7.28: the palette is "a `glassThick` panel 640 wide … `max-height: 70vh`". The snap gives T5 whenever the palette is taller than 400 px.
  - §8.29: the shortcuts window is a "`glassThick` window 560 wide".
  - §8.25.14: the licences window, also 560 px, is "the desktop T5 window".
  - §15.3 *Driven values*: "The material is `SkinGlass(tier: T4)` inside the sheet". On the 440 × 956 phone that §15.8 screenshots, a partial sheet is 424 px wide, so the snap gives T5.
  - In the other direction, §2.4.1 declares the Wrapped frame and the listen full player T5. On a 390 px phone they are 374 px wide, so the snap gives T4.
- **Fix:** Make the snap top out at T4, and make T5 declared-only.
  - §2.4.3: change the snap to "`< 36 px → T1`, `36–56 → T2`, `57–96 → T3`, `≥ 97 → T4`", and add: "T5 is never reached by size. It is declared only for the Massive objects of §2.4.1 (the listen full player at `medium` and its 560 px desktop window, the Wrapped frame, the image viewer frame and the splash lens). Sheets, desktop panels, desktop windows, the command palette and alerts are T4 (`glassThick`) at every size."
  - §2.8.4: change `glass.snap` to `[36, 57, 97]`.
  - §15.8: change the fixture to `tierFor(401) == T4`.
  - §7.10: change "Panel and window bodies are T4 or T5 glass" to "Panel and window bodies are T4 glass (`glassThick`); the one T5 window is the listen player's (§8.16.2)".
  - §8.25.14: change "the desktop T5 window" to "the desktop T4 window".

## CONSISTENCY-2

- **Severity:** medium
- **Section:** §7.10 (Desktop, desktop-form table) vs §8.12 Presentation, §15.2 **Sheet host**, §2.3 (`r2xl`)
- **Problem:** The desktop series window has two definitions, one of them contradicting §7.10's rules. First, its material: §7.10 says every panel and window body is T4/T5 glass, so its `label2`/`label3` text must render as `onGlass` and its state glyphs must sit on discs. §8.12 makes the 960 px window a content-layer `materialThick` slab. Second, what sits behind it: §7.10 says `dimSheet` sits behind panels and windows. §8.12 and §15.2 recess the covered page to scale 0.97, blur 8 and "dim 50 %". §15.2 also applies that recession to every SheetHost route on desktop, including the 560 px recap, friend and profile-form windows. "dim 50 %" is undefined either way: it could mean 50 % black or 50 % brightness, while §7.10's recession says "dims to 60 %" and means brightness. Separately, §2.3 labels `r2xl` 32 "Desktop panels", but every desktop panel in the file uses 26.
- **Evidence:**
  - §7.10, line 1731: "The backdrop behind both is `dimSheet`, as behind a partial detent. … Panel and window bodies are T4 or T5 glass".
  - Line 1738: the "960 px window (`layout.detailWindow`) | Series detail and Book page" is listed as a sheet form.
  - §8.12, line 2567: "a **window** 960 wide …, radius 32, `materialThick`, over the recessed page (scale 0.97, blur 8, dim 50 %)".
  - §15.2, line 4188: "the recession (desktop: scale 0.97, blur 8, dim 50 %; …)" for all SheetHost routes.
  - §2.3: "`r2xl` | 32 | Desktop panels and desktop "windows"". Panels use 26: §7.10 panel "radius 26", §8.14.11 "radius 26", §8.15.2 "radius 26".
- **Fix:**
  - §7.10: add "Exception: the 960 px series and book window is a content-layer `materialThick` slab (`rgba(19,19,23,0.84)`, blur 36, radius 32, no live glass). Its text keeps the alpha labels, and its state glyphs stay bare, as on slabs. Behind it the covered page recedes to scale 0.97, blur 8 and 50 % brightness (`rgba(0,0,0,0.50)` over the page), driven by `--sheet-progress`. Every other desktop panel and window has `dimSheet` behind it, with no scale or blur."
  - §8.12: write "dim 50 %" as "50 % brightness (`rgba(0,0,0,0.50)`)".
  - §15.2: change "desktop: scale 0.97, blur 8, dim 50 %" to "desktop: the series and book window only (scale 0.97, blur 8, `rgba(0,0,0,0.50)`); other desktop sheet routes use `dimSheet` only".
  - §2.3: change the `r2xl` use to "Desktop windows (560 and 960 px) and the desktop Login slab". Desktop panels stay `rXl` 26.

## CONSISTENCY-3

- **Severity:** medium
- **Section:** §4.6 (Magnet capture row), §2.8.5 (`physics.magnetRadius`) vs §7.21, §8.16.3, §8.25.6, §9.4.1
- **Problem:** The file gives four different capture rules for value magnets. §4.6 says "detents with magnets" capture within 64 px, but the speed dial uses ±0.08×, stepped sliders use 30 % of a step's spacing, and the cruise pill and the interval slider give no radius at all. On the cruise pill (8 px per 0.05×), 64 px would capture ±0.40×, from 0.6× to 1.4×. An implementer cannot tell which rule each control follows.
- **Evidence:**
  - §4.6: "Magnet capture (friend orb, detents with magnets) | within 64 px of the target centre | … value detents with magnets: `detent.magnet` `rigid(0.4)`".
  - §2.8.5: "`physics.magnetRadius` | 64 px".
  - §7.21: "within 30 % of a step's spacing the thumb is pulled toward the step".
  - §8.16.3: "values within ±0.08 are pulled to 1.0".
  - §9.4.1: "8 px per 0.05×, … a magnet at 1.0× (`detent.magnet`)", with no radius.
  - §8.25.6: "a magnet at 30 (`detent.magnet`)", with no radius.
- **Fix:**
  - §4.6: split the row. "Magnet capture (friend orb, collection target) | within 64 px (`physics.magnetRadius`), pull 0.35 per frame" and "Value magnet (speed dial 1.0×, cruise 1.0×, interval 30 min, stepped sliders) | within ±0.08× of 1.0× on the speed dial (±9.6 px at 6 px per 0.05) and the cruise pill (±12.8 px at 8 px per 0.05); within 30 % of one step's spacing on stepped sliders, including the interval slider's 30 min | `detent.magnet` `rigid(0.4)`".
  - §2.8.5: add `physics.valueMagnetSpeed` = 0.08 and `physics.valueMagnetStepFraction` = 0.30.

## CONSISTENCY-4

- **Severity:** medium
- **Section:** §2.4.1 mass-class table (Press growth column), §4.10 Press swell vs §7.5, §7.15, §7.21, §7.22
- **Problem:** The mass-class table says each class fixes its press growth, "Nobody picks a duration or a thickness by feel". The Feather and Light rows give "+17 px on the longest side, capped at 0.35 × the side". No Feather object in the component specs grows that way, and the chips in the Light row sink instead of growing.
- **Evidence:**
  - §2.4.1: "Feather | Tab droplet, scrub thumb, toggle knob, slider thumb, chips and segmented thumbs **while dragged** … | +17 px on the longest side, capped at 0.35 × the side", and "Light | Chips at rest (content fills, not glass) … | +17 px capped at 0.35 × side".
  - §4.10 Press swell: "+17 px (Feather, Light; capped at 0.35 × side)".
  - The component specs say otherwise:
    - §7.15, droplet 56 × 52: "the droplet lifts (turns fully clear, grows 6 %)". The rule would give +17 px.
    - §7.21, thumb 28 px: "grows to 34 px on `press`". The rule would give 28 + 9.8 = 37.8 px.
    - §7.22, knob 27 px: "stretches to 34 × 27 while held".
    - §7.5: "pressed sinks to 0.96 on `press` (chips are content)", and §4.10 Content sink: "chips 0.96".
- **Fix:**
  - §2.4.1 Feather row Press growth: change to "per component, on `press`: droplets +6 % (§7.15), slider thumb 28 → 34 px (§7.21), switch knob 27 → 34 × 27 (§7.22)".
  - §2.4.1 Light row: move "Chips at rest" out of the Objects cell and into the Medium row's content list, as "chips (content, sink 0.96)".
  - §4.10 Press swell Spec: change to "Glass grows +12 px (Medium) or +17 px capped at 0.35 × side (Light); Feather objects grow per their component (§2.4.1)".

## CONSISTENCY-5

- **Severity:** medium
- **Section:** §7.34 (Full swipe) vs §7.12 (Timing)
- **Problem:** A toast with Undo lasts 10 s in the toast spec but 5 s in the swipe-row spec. Both apply to the same toast, a destructive swipe's Undo toast.
- **Evidence:** §7.12: "4 s default, 10 s with Undo (the capsule's rim drains clockwise…)". §7.34: "destructive actions show a 5 s Undo toast instead of a confirm."
- **Fix:** §7.34: change to "destructive actions show the 10 s Undo toast of §7.12 instead of a confirm".

## CONSISTENCY-6

- **Severity:** medium
- **Section:** §3.2 (`display` row) and §9.2.3 card 2 and §9.2.4 Design vs §3.7 (`type.wrappedNumeral`) and §9.2.3 Card layout and §9.2.4 Coordinates
- **Problem:** The big Wrapped and share numerals are assigned two different roles. `display` is 44/48 on phone with tracking −0.025. `wrappedNumeral` is 88/88 with tracking −0.03. The card coordinates (an 88 px box, and 264 px on the ×3 share canvas) only fit `wrappedNumeral`, but three places name `display`.
- **Evidence:**
  - §3.2: "`display` (splash wordmark, Wrapped numbers, hero titles) | 44/48".
  - §9.2.3 card 2: "the `display` numeral counting up on `drift`".
  - §9.2.3 Card layout: "Big numbers use `type.wrappedNumeral` (88/88 …)", and card 2's figure is "the numeral "212" centred at y 236–324", an 88 px box.
  - §9.2.4 Design: "the big numeral in `display` Google Sans Flex". §9.2.4 Coordinates: "264 px type", which is 88 × 3.
- **Fix:**
  - §3.2 `display` row: change the use to "(splash wordmark, hero titles, Wrapped card 1 headline)".
  - §9.2.3 card 2: change to "the `wrappedNumeral` numeral counting up on `drift`".
  - §9.2.4 Design: change to "the big numeral in `wrappedNumeral` (88 px ×3 = 264 px on the canvas)".

## CONSISTENCY-7

- **Severity:** medium
- **Section:** §3.7 (`GlassText(role:, text)`, `@utility type-<role>`) vs component and screen specs
- **Problem:** On Flutter, role text is drawn only through `GlassText(role:, text)`, which takes a role and nothing else. On the web, `type-<role>` hard-wires `font-variation-settings "wght"` to `--mm-type-<role>-wght`, so a class such as `font-bold` cannot override it. About 25 places nevertheless set a role at a different weight or size, and no mechanism for doing so exists on either client.
- **Evidence:** §3.7: "role text is drawn only through a **`GlassText(role:, text)`** widget … It is the only way Glass draws role text on Flutter." The overrides, counted by script:
  - Sizes: §7.27 keycap "`mono` 12/600"; §7.3 stepper, §7.17 chapter row and §8.14.2 go-to well "`mono` 15"; §9.2.4 foot line "`mono` 24". The `mono` role is 13 px everywhere.
  - Weights: §7.20 "`caption1` 700" (×3) and "`caption1` 600" (×4); §7.17 and §7.3 "`footnote` 13/600" (×4); §7.1 and §7.6 "`subhead` 15/620" (×2); §7.13 and §7.37 "`subhead` 15/600" (×2); §7.11 "`title3` 20/700".
  - Weights on glass: `onGlass` "at `wght` 700" (×3), "460" (×3), "600" (×2) and "420" (×1).
- **Fix:**
  - §3.7: add "Overrides: `GlassText(role:, text, {int? wght, double? size})`. `wght` replaces the role's weight (Bold Text still adds +100, press still adds +40). `size` replaces the base size before the role's text-scale cap. On the web, set the same values as inline custom properties on the element: `[--mm-type-<role>-wght:700]` and `[--mm-type-<role>-size:0.9375rem]`. Only the overrides that §7 to §10 name are allowed."
  - Alternatively, add three roles: `monoSmall` 12/16 wght 600 (keycaps), `monoMedium` 15/20 wght 500 (stepper value, chapter number, go-to well) and `monoShare` 24 (share canvas only).

## CONSISTENCY-8

- **Severity:** medium
- **Section:** §11 (Alternative column) vs §9.4.3 (Counter) and §7.37 (Accessibility)
- **Problem:** The gesture matrix names two non-gesture alternatives that the component specs never define, so an implementer has nothing to build from. Both are the WCAG 2.5.1 path for their gesture.
- **Evidence:**
  - §11: "Pinch out | Guided view | … | The counter pill's overview button". §9.4.3 Counter: "a `glassRegular` pill at the bottom, "Panel 4 of 38 · Page 7" + a close ×". It has no overview button.
  - §11: "Long-press Back | … | the screen-reader custom action "All levels" on every back button". §7.37 Accessibility gives only a hint: "the back button's semantics hint says "Double-tap and hold for all levels"". No custom action is defined.
- **Fix:**
  - §9.4.3 Counter: change to "… "Panel 4 of 38 · Page 7" + an overview button (`squares-four`, 44 hit, `aria-label="Show the whole page"`, toggles the Overview of this section) + a close ×".
  - §7.37 Accessibility: add "every back button also carries a custom action "All levels" (Flutter `CustomSemanticsAction(label: "All levels")`; web a visually hidden `aria-haspopup="menu"` button after it) that opens the stack overview, or the back menu on the web".

## CONSISTENCY-9

- **Severity:** medium
- **Section:** §8.14.7 and §8.14.11 (reader Esc order) vs §8.14.9, §9.4.3, §8.0.5 (Android back order)
- **Problem:** The reader's Esc order leaves out the hit lens, the dialogue overlay and guided view, so, read literally, Esc in guided view leaves the reader. §8.14.9 and §9.4.3 both say Esc closes those layers. §8.0.5 also claims that Android back "matches the web's `Esc` order", but its list has guided view, the dialogue overlay and the hit lens where the Esc order has the side panel and fullscreen.
- **Evidence:**
  - §8.14.7: "Esc order: menu or popover → side panel (desktop, §8.14.11) → fullscreen → cinema → leave the reader". §8.14.11 repeats the same order.
  - §8.14.9: "Esc or the capsule's × removes the lens and outlines".
  - §9.4.3 Exit: "swipe down …, the pill's ×, Esc".
  - §8.0.5: "**Android back order.** It matches the web's `Esc` order (§8.0.6, §8.14.7)", with rows "6 Dialogue overlay or hit lens showing" and "7 Guided view".
- **Fix:**
  - §8.14.7 and §8.14.11: change the order to "menu or popover → dialogue overlay and hit lens → guided view (back to the strip at the current panel) → side panel (desktop) → fullscreen → cinema → leave the reader".
  - §8.0.5: change "It matches the web's `Esc` order" to "It follows the same order as the web's `Esc` (§8.0.6, §8.14.7); side panels and fullscreen do not exist on phones".

## CONSISTENCY-10

- **Severity:** low
- **Section:** §7.12 (Top-band priority) vs §7.30 (App update capsule)
- **Problem:** On phones the app-update capsule is placed in two different spots. §7.12 queues it in the one top slot under the nav row. §7.30 puts it bottom-centre above the dock.
- **Evidence:** §7.12: "**Top-band priority** (one slot under the nav row on phones): alert > toast > global new-chapters capsule > app-update capsule." §7.30: "Bottom-centre above the dock (phone) and bottom-centre of the content column (desktop)".
- **Fix:** §7.12: drop "> app-update capsule" from the top-band priority, and add "The app-update capsule sits bottom-centre above the dock (§7.30), outside this queue; it waits while the bulk toolbar or the "Unsaved changes" bar is up."

## CONSISTENCY-11

- **Severity:** low
- **Section:** §7.23 (Context menu) vs §7.35 (Reorder)
- **Problem:** A 450 ms press on a row in a reorder-capable list gets two different results. §7.23 opens the context preview: the row at 1.02, `dimContext`, a menu and `longpress.open`. §7.35 starts the reorder lift: the row at 1.03, no menu and `reorder.lift`.
- **Evidence:** §7.23: "The preview (poster 1.12, row 1.02, image 1.0) stays interactive: drag it … to reorder (rows in reorder-capable lists)". §7.35: "press 450 ms on a row (or drag its handle immediately): the row lifts (scale 1.03 …), `reorder.lift` haptic".
- **Fix:** §7.35: change to "press 450 ms on a row: the context preview opens (§7.23, row 1.02, `longpress.open`); dragging the preview more than 10 px closes the menu and turns it into the reorder lift (scale 1.02 → 1.03 on `press`, `reorder.lift`). Dragging the handle starts the reorder lift immediately."

## CONSISTENCY-12

- **Severity:** low
- **Section:** §4.10 (Throw) vs §9.1.1 (Not interested), §4.1 law 10
- **Problem:** The motion table and the AI-rail spec give different springs for throwing an AI card away: `zoom` (bounce 0.06, settle 558 ms) in §4.10 and `dismiss` (bounce 0, settle 378 ms) in §9.1.1. Law 10 requires bounce 0 for exits.
- **Evidence:** §4.10 Throw: "`zoom` with the release velocity | … | Lifted posters, the hero card, AI cards (away)". §9.1.1: "The card flies off on `dismiss` with its velocity and spins up to 12°". §4.1 law 10: "Dismissals and exits use bounce 0".
- **Fix:** §4.10 Throw row: change the spring cell to "`zoom` with the release velocity (open, recommend); `dismiss` with the release velocity for AI cards thrown away (settle 378 ms)", and the Duration cell to "projected, settle 558 ms (open) / 378 ms (away)".

## CONSISTENCY-13

- **Severity:** low
- **Section:** §4.2 (`snappy` use cell) vs §7.6 and §4.10 (Tab droplet); §7.16 vs §2.4.1 Medium row
- **Problem:** Two objects are given a spring that contradicts other sections.
  - The spring table assigns the segmented thumb to `snappy`, but §7.6 and §4.10 move it on `tab`.
  - The sidebar is Medium class (move springs `morph` / `minimize`), but its width change runs on `snappy`.
- **Evidence:**
  - §4.2: "`snappy` | … | Chips, segmented thumb, icon morphs, row expand, list entrances". §7.6: "tap a segment → the thumb travels on `tab`". §4.10 Tab droplet: "… choice chips, segmented thumbs, palette rows".
  - §2.4.1: "Medium | … the desktop sidebar … | `morph` / `minimize`". §7.16: "the width change runs on `snappy`".
- **Fix:**
  - §4.2 `snappy` use: change to "Chip selection checks, icon morphs, row expand, list entrances" (the thumb stays on `tab`).
  - §7.16: change to "the width change runs on `minimize`".

## CONSISTENCY-14

- **Severity:** low
- **Section:** §7.7 (Collection card) vs §4.10 (Fan open) and §8.18 (Signature moment)
- **Problem:** Four covers are given five fan angles, so the spread is undefined. The rest angles in §7.7 are four values.
- **Evidence:** §7.7: "up to four member covers (each 72 × 108, rotated −8°, −3°, 3°, 8° …)". §4.10 and §8.18: "the four covers spread to 0°, ±12°, ±24°".
- **Fix:** §4.10 and §8.18: change to "spread to −24°, −8°, 8°, 24° (three covers: −16°, 0°, 16°; two: −8°, 8°; one: 0°)".

## CONSISTENCY-15

- **Severity:** low
- **Section:** §7.8 (Overlays) vs §7.20 (Downloaded)
- **Problem:** The downloaded droplet glyph on a cover is 16 px in one spec and 14 px in the other.
- **Evidence:** §7.8: "downloaded droplet glyph bottom-left (`success`, 16 px, on a 22 px `rgba(0,0,0,0.72)` circle …)". §7.20: "`droplet` glyph 14 `success`; on a cover on a 22 px `rgba(0,0,0,0.72)` circle".
- **Fix:** §7.20: change to "`droplet` glyph 14 `success` on black; 16 px on a cover, on a 22 px `rgba(0,0,0,0.72)` circle (§7.8)".

## CONSISTENCY-16

- **Severity:** low
- **Section:** §2.7 (size table) vs §7.24 and §8.7 step 3
- **Problem:** The icon table sets ornamental Light glyphs at 48 to 64 px. The empty-state lens and the onboarding format cards, both named as ornamental uses, draw them smaller.
- **Evidence:** §2.7: "Ornamental (empty states, onboarding, Wrapped) | **Light** | 48 to 64". §7.24: "a 96 px `glassThin` circle holding a 44 px Light glyph" and "**Lens glyphs** (Phosphor Light 44 …)". §8.7 step 3: "a Light 40 px glyph".
- **Fix:** §2.7: change the row to "Ornamental (empty-state lenses 44, onboarding format cards 40, Wrapped 48 to 64) | Light".

## CONSISTENCY-17

- **Severity:** low
- **Section:** §8.0.5 (Who owns a horizontal drag) vs §8.0.5 iOS row, §4.6
- **Problem:** The back-swipe strip inside drag-owning components is 24 px, yet the text calls it "like the reader's strip", which is 20 px.
- **Evidence:** §8.0.5: "the iOS back swipe starts only in the leading 24 px (like the reader's strip)". The same section: "the readers use an edge-only 20 px strip". §4.6: "reader edge-only 20 px".
- **Fix:** §8.0.5: change to "starts only in the leading 24 px (the same 24 px Safari keeps free, §8.0.8; the reader's own strip is 20 px)".

## CONSISTENCY-18

- **Severity:** low
- **Section:** §11 (Swipe a row) vs §7.34 (Reveal), §2.4.1 rule 1
- **Problem:** The gesture matrix calls the swipe-row pills "glass". §7.34 and §2.4.1 rule 1 make them content twins with no backdrop read.
- **Evidence:** §11: "Reveals glass action pills; full swipe past 60 % commits". §7.34: "**separate pills** … drawn as content twins (§2.4.1: `rgba(19,19,23,0.62)` fill, 0.5 px rim, inner light, no backdrop read …)".
- **Fix:** §11: change to "Reveals the content-twin action pills (§7.34); full swipe past 60 % commits".

## CONSISTENCY-19

- **Severity:** low
- **Section:** §7.1 (Hold-to-confirm, "It is used for") vs §8.14.5, §8.25.3
- **Problem:** The hold-to-confirm use list reads as exhaustive but leaves out one use: "Reset reader settings" is hold-to-confirm in two sections.
- **Evidence:** §7.1: "It is used for: turning on the 18+ gate, signing out everywhere, deleting a profile, deleting a collection, removing all downloads, resetting offline storage and deleting a member". §8.14.5: "Reset reader settings (hold-to-confirm)". §8.25.3: ""Reset reader settings" (hold-to-confirm; toast …)".
- **Fix:** §7.1: add "resetting reader settings (§8.14.5, §8.25.3)" to the list. It opens the §7.11 confirm alert on click, like the other uses outside an alert.

## CONSISTENCY-20

- **Severity:** low
- **Section:** §2.1.9 (One light per meaning) vs §7.2, §8.17, §9.2.1
- **Problem:** §2.1.9 gives each light exactly one job, and the Warmth light (`streak`/`streakCore`) is limited to the streak. The file also uses `streakCore` for the favourite star and for the Statistics best-day dot.
- **Evidence:** §2.1.9: "each colour of light has exactly one job" and "**Warmth** | … | The streak flame, milestone numerals, the goal ring, record sparks". §7.2: "`streakCore` `#FFD166` for favourite". §8.17: "a favourited star's `streakCore` 10.81:1". §9.2.1: "the best day marked with a small `streakCore` dot".
- **Fix:** Either add them to §2.1.9's Warmth job cell ("…, record sparks, the favourite star and the Statistics best-day dot") or recolour the favourite star to `warning` `#FFB547` (semantic, not a light). Its contrast values (10.55:1 on `surface1`) would then need re-checking in §15.8.

## CONSISTENCY-21

- **Severity:** low
- **Section:** §7.10 ("Desktop form of every sheet") vs §8.0.3 (sheet ids)
- **Problem:** The desktop-form table says it covers every sheet but leaves out six of the 29 ids. Their desktop forms are defined only in other sections.
- **Evidence:** §8.0.3 lists `chapters`, `settings`, `contents`, `type`, `player` and `image`. None of them appears in §7.10's form table. Their forms are in §8.14.11 (left and right reader panels), §8.15.2 (novel panels), §8.16.2 (a 560 px T5 window) and §7.31 (the image viewer).
- **Fix:** §7.10: add two rows. "Reader side panels (§8.14.11, §8.15.2) | `chapters`, `contents` (300 px left); `settings`, `type` (360 px right)". "Own forms | `player` (560 px T5 window, §8.16.2), `image` (full-window viewer, §7.31)".

## CONSISTENCY-22

- **Severity:** low
- **Section:** §7.26 (profile orb sizes) vs §7.15 and §9.3.1
- **Problem:** §7.26's list of orb sizes is meant to be complete, but two orbs are missing from it. The dock's You orb has no size anywhere. The presence arc uses orbs up to 64 px, which is not in the list.
- **Evidence:** §7.26: "sizes 18 …, 20 …, 24 (chips), 32 …, 44 (nav row), 56 (avatar grid, drop targets, presence arc), 72 (You), 96 …, 112 …, 128 …, 132 …". §7.15: "Each tab: icon 22 …", and You is "the profile orb, never a glyph" (§2.7). §9.3.1: "each member's 56 px orb …, nearer to the viewer (larger, up to 64 px …)".
- **Fix:** §7.26: add "24 (the dock's You tab, in the 22 px icon slot, with the 2 px goal ring outside it)" and change "56 (… presence arc)" to "56 to 64 (presence arc, interpolated by recency)".

## CONSISTENCY-23

- **Severity:** low
- **Section:** §7.22, §4.10, §8.14.1, §8.15.4, §8.11, §9.1.2, §9.3.4, §9.3.2
- **Problem:** Several values are given with no number:
  - §7.22: "knob 27 px white with a small shadow".
  - §4.10 Page slide, §8.14.1 and §8.15.4: "8 px soft shadow", with no colour or alpha.
  - §4.10 Lens pop and §8.11: "Scale → 0 with a small ripple".
  - §4.10 Deal and §9.1.2: "along a short arc".
  - §4.10 Orbs fly out and §9.3.4: "along a curve toward the top edge".
  - §9.3.2: "waits in the strip at 60 % with a thin ring".
- **Evidence:** The quotes above.
- **Fix:**
  - Knob shadow: `0 2px 6px rgba(0,0,0,0.35)`.
  - Page-slide shadow: `0 0 8px rgba(0,0,0,0.45)` on the moving edge.
  - Lens-pop ripple: a 1 px `rgba(255,255,255,0.30)` ring, radius 48 → 96 px, opacity 0.30 → 0 over 300 ms `fadeOut`.
  - Deal arc: a quadratic Bézier whose control point sits 48 px above the midpoint of the start and end.
  - Orbs fly out: a quadratic Bézier to the top edge at the orb's x ± 40 px, control point 120 px above the start.
  - Sending ring: a 1.5 px `bloom` ring at 40 %.

## CONSISTENCY-24

- **Severity:** low
- **Section:** §2.8 (token name map) vs §2.1.2, §2.4.1 rule 1, §7.8, §7.20, §15.8
- **Problem:** Three backing colours are used in dozens of places but have no token key, although §15.8's contrast gate is said to read its pairs from `glass.json`. The three are the backing disc `rgba(0,0,0,0.60)`, the cover-overlay backing `rgba(0,0,0,0.86)` and the 22 px cover disc `rgba(0,0,0,0.72)`. Each client would hard-code its own literal.
- **Evidence:**
  - §2.1.2: "**backing disc** `rgba(0,0,0,0.60)`". §7.8: "`rgba(0,0,0,0.86)` capsule" and "22 px `rgba(0,0,0,0.72)` circle".
  - §15.8: "computes WCAG ratios for every text/background pair declared in `design/tokens/glass.json`", with a Backing disc case and a Cover overlays case.
  - None of the three colours has a row in §2.8.1.
- **Fix:** §2.8.1: add three rows.
  - `color.backingDisc` `rgba(0,0,0,0.60)` → `--mm-color-backing-disc`, `bg-backing-disc`, `colorBackingDisc` = `Color(0x99000000)`.
  - `color.coverBacking` `rgba(0,0,0,0.86)` → `colorCoverBacking` = `Color(0xDB000000)`.
  - `color.coverDisc` `rgba(0,0,0,0.72)` → `colorCoverDisc` = `Color(0xB8000000)`.
  - §2.1.2 and §7.8 then cite the keys.

## CONSISTENCY-25

- **Severity:** low
- **Section:** §15.10 G6 vs §2.1.8 step 1, §15.5
- **Problem:** The amendment register repeats the cover palette's shape without `lMax`, the field every surface over a cover reads.
- **Evidence:** §15.10 G6: "Cover palettes stay on the backend (`palette {a, l}` in the same Pillow pass …)". §2.1.8: "`palette: {a: […], l: 0.41, lMax: 0.88}`". §15.5: "`palette: {a: [hex, hex, hex], l, lMax}`".
- **Fix:** §15.10 G6: change to "`palette {a, l, lMax}`".

## CONSISTENCY-26

- **Severity:** low
- **Section:** §8.15.1 (Paper intro) vs the Paper table
- **Problem:** The sentence introducing the paper table gives ranges that the table's own Glass row falls outside.
- **Evidence:** §8.15.1: "Text sits at 13 to 15:1, muted text at about 5.9:1." The table: "**Glass** | … | 17.83 | 6.56". The other rows run 13.42 to 15.36 and 5.84 to 5.90.
- **Fix:** Change the sentence to "Text sits at 13.4 to 17.8:1, muted text at 5.8 to 6.6:1."

## CONSISTENCY-27

- **Severity:** low
- **Section:** §3.3 (Android steps sentence) vs the §3.3 table
- **Problem:** The table's Android column uses a font scale that is not in the list of Android steps the text gives.
- **Evidence:** "Android's font-scale steps (0.85, 0.9, 1.0, 1.15, 1.3, 1.5, 1.8, 2.0) are listed on the nearest row". The table: "| M | 0.95 | 0.94 | …".
- **Fix:** In the M row, change the Android cell from "0.95" to "n/a". No listed Android step is nearest to 0.94: 0.9 sits on the S row and 1.0 on the L row.

## CONSISTENCY-28

- **Severity:** low
- **Section:** §7.19 (Linear progress) vs §4.2 (`snappy`)
- **Problem:** §7.19 gives the `snappy` settle as 0.4 s, which does not match §4.2.
- **Evidence:** §7.19: "(a large jump overshoots nothing; bounce 0.15 settles in 0.4 s)". §4.2: "`snappy` | 400 | 0.15 | … | 431 ms | 0.6 %". So it does overshoot, by 0.6 %.
- **Fix:** Change to "(bounce 0.15: a 0.6 % overshoot, settled in 431 ms)".
