# Glass DESIGN.md: judge of the consistency sweep

Input: `glass/verify-sweep/find-consistency.md` (28 findings). Target: `glass/DESIGN.md` as of 2026-09-29 (4,612 lines). Every finding was checked against the quoted lines of DESIGN.md and against `inventory/00-decisions.md` and `stack-decision.md`. A finding is confirmed only when the defect is really in the file and the fix is correct and consistent with the rest of the contract. Where the proposed fix was wrong, vague or offered two alternatives, the final fix below replaces it.

Result: **26 confirmed, 2 refuted** (CONSISTENCY-19 and CONSISTENCY-21).

---

## Verdicts

| Id | Verdict | Reason |
|---|---|---|
| 1 | Confirmed, fix amended | §2.4.3 line 414 snaps free-sized glass `> 400 → T5`, and §2.8.4 line 782 ships `glass.snap = [36, 57, 97, 401]`. But §2.4.1 (Heavy row, layer table rows 4 and 5), §2.4.2 (`glassThick` is "menus, partial sheets, alerts, lifted previews, palette"), §7.10 (panel `glassThick`), §7.28 (palette `glassThick`), §8.29 (shortcuts `glassThick` window) and §15.3 (`SkinGlass(tier: T4)` inside the sheet) all declare T4. A partial sheet on the 440 px phone is 424 px wide and at least 497 px tall (52 % of 956), so `tierFor` returns T5. The fix is right; the `glass.snap` change must be made in both the TypeScript and Dart cells of the row. |
| 2 | Confirmed | §7.10 line 1731 makes every panel and window body T4/T5 glass over `dimSheet`, and lists the 960 px window as a sheet form. §8.12 line 2567 makes it a `materialThick` slab over a 0.97 / blur 8 / "dim 50 %" recession, and §15.2 line 4188 applies that recession to every SheetHost route on desktop, including the recap, friend and profile-form 560 px windows that §7.10 puts over `dimSheet`. The slab reading is the right one: the band carries its own glass nav group (§2.1.7 `Lb` table), which would be glass on glass on a T4 window. Alpha labels on the slab hold: `label3` on `materialThick` over white at 50 % brightness computes about 4.6:1. `r2xl` 32 is labelled "Desktop panels" but every panel uses 26 and the Login desktop slab (line 2424) uses 32. |
| 3 | Confirmed, fix rewritten | §4.6 gives "detents with magnets" a 64 px capture, which contradicts §8.16.3 (±0.08×, 9.6 px) and §7.21 (30 % of a step), and §9.4.1 and §8.25.6 give no radius. The proposed row, though, puts the ordinary per-step magnetism of stepped sliders under `detent.magnet`, while §7.21 ticks those with `detent.tick` and §5.2 limits `detent.magnet` to speed 1.0×, cruise 1.0× and the 30-minute interval. The rewrite keeps the three behaviours apart and adds the new keys to the §15.1 JSON too. |
| 4 | Confirmed, fix rewritten | The Feather row's "+17 px capped at 0.35 × side" contradicts §7.15 (droplet grows 6 %), §7.21 (thumb 28 → 34 px, where the rule gives 37.8) and §7.22 (knob 34 × 27); the segmented thumb (§7.6) only stretches. "Chips at rest" sit in the Light row with +17 px, but §7.5 and §4.10 sink chips to 0.96. The proposed move of chips to the Medium row is wrong: it would put chips on `morph`/`minimize`, while §2.4.1's own intro and §4.2 give chips `snappy`, the Light move spring. The rewrite keeps chips in the Light row and annotates the growth cell. |
| 5 | Confirmed | §7.12: "10 s with Undo". §7.34 line 2038: "a 5 s Undo toast". Same toast. |
| 6 | Confirmed | §3.2 lists "Wrapped numbers" under `display` (44/48), §9.2.3 card 2 names "the `display` numeral", §9.2.4 names `display`, but §3.7 defines `type.wrappedNumeral` 88/88 and the coordinates are 88 px (y 236–324) and 264 px (88 × 3) boxes. Card 1's headline is `display` 44/48, so the new use text is accurate. |
| 7 | Confirmed, fix rewritten | §3.7 line 1000: `GlassText(role:, text)` is "the only way Glass draws role text on Flutter", and the web utility hard-wires `--mm-type-<role>-wght`. The counted overrides exist (`caption1` 700 ×3, `caption1` 600 ×4, `footnote` 13/600 ×3, `mono` 15 ×3, `mono` 12/600, `title3` 20/700, `onGlass` at `wght` ×7, and others). The finding offered two alternatives; the "three new mono roles" one does not cover any of the weight overrides, so it is dropped and one mechanism is specified. The share side's `mono` 24 is in canvas px (Flutter renders that side at 360 logical px × 3, §9.2.4), which the rewrite states. |
| 8 | Confirmed, fix amended | §11 names "the counter pill's overview button" and a screen-reader custom action "All levels"; neither is defined (§9.4.3 Counter has only text and ×; §7.37 has only a hint). Pinch is multipoint, so the guided-view overview has no WCAG 2.5.1 path today. The proposed web half, a visually hidden button after every back button, adds an invisible tab stop for sighted keyboard users; the rewrite uses `aria-keyshortcuts` for the existing `mod+\` instead. |
| 9 | Confirmed | §8.14.7 (line 2691) and §8.14.11 (line 2718) Esc orders omit the hit lens, dialogue overlay and guided view, which §8.14.9 and §9.4.3 close with Esc. §8.0.5 claims Android back "matches" that order while listing different rows. |
| 10 | Confirmed, fix rewritten | §7.12 queues the app-update capsule in the phone top slot; §7.30 puts it bottom-centre above the dock. The proposed fix (keep it at the bottom, outside the queue) lets it coexist with a toast and a sheet, which takes the phone frame to 9 Flutter glass shapes against the §15.7 limit of 8 (nav row 3, dock + orb + accessory 3, sheet 1, toast or menu 1). The rewrite resolves the other way: top-band queue on phones, bottom-centre on tablet and desktop, where §7.30's reason (not sharing the bottom-left corner with toasts) applies. |
| 11 | Confirmed, fix amended | §7.23: the 450 ms preview (row 1.02) stays interactive and a drag reorders. §7.35: a 450 ms press lifts the row to 1.03 with `reorder.lift` and no menu. Same trigger, two outcomes. The fix is right; it adds what happens to `dimContext`. |
| 12 | Confirmed | §4.10 Throw: `zoom` (bounce 0.06) for "AI cards (away)". §9.1.1: `dismiss`. §4.1 law 10: exits use bounce 0, and §4.2's `dismiss` use cell already names "thrown cards". |
| 13 | Confirmed, fix amended | §4.2 lists "segmented thumb" under `snappy`, but §7.6 and §4.10 Tab droplet move it on `tab`. §7.16 runs the Medium-class sidebar's width change on `snappy`, the Light move spring. The proposed "Chip selection checks" rewording is unneeded (chips are Light and correctly on `snappy`); only the segmented thumb comes out. |
| 14 | Confirmed | §7.7 line 1693: four covers at −8°, −3°, 3°, 8°. §4.10 Fan open and §8.18 line 2903: "the four covers spread to 0°, ±12°, ±24°", five angles. |
| 15 | Confirmed | §7.8 line 1707: 16 px on the 22 px disc; §7.20 line 1876: 14 px on the same disc. |
| 16 | Confirmed | §2.7 sets ornamental Light glyphs at 48 to 64; §7.24 draws 44 px lens glyphs and §8.7 step 3 draws 40 px format-card glyphs. |
| 17 | Confirmed | §8.0.5 calls the 24 px back-swipe start "like the reader's strip"; the reader's strip is 20 px in the same section and in §4.6. 24 px matches the PWA strip in §8.0.5 and the Safari edge rule in §8.0.8. |
| 18 | Confirmed | §11 "Reveals glass action pills" vs §7.34 and §2.4.1 rule 1 (content twins, no backdrop read). |
| 19 | **Refuted** | §7.1's "It is used for:" list is not worded as exhaustive, and its own WCAG 2.5.1 paragraph covers every hold outside an alert with "and so on". "Reset reader settings" is specified as hold-to-confirm in §8.14.5 and §8.25.3, and the §7.1 rules apply to it without the list. Nothing is ambiguous for an implementer. |
| 20 | Confirmed, fix rewritten | §2.1.9 gives each light "exactly one job", and Warmth's job cell omits the favourite star (§7.2 line 1624, §8.17) and the Statistics best-day dot (§9.2.1). The finding offered two options. Recolouring the star to `warning` is wrong: §2.1.9 says semantic colours mark states (saved, stale, failed, 18+), and `warning` already means Offline and stale. The rewrite takes the other option only. |
| 21 | **Refuted** | The six ids missing from §7.10's table (`chapters`, `settings`, `contents`, `type`, `player`, `image`) have fully specified desktop forms in their own sections (§8.14.11, §8.15.2, §8.16.2, §7.31), and §7.10 already says reader sheets stay in the reader's own panels. Adding table rows repeats what is specified elsewhere and resolves no ambiguity. |
| 22 | Confirmed, fix amended | §7.26's size list has no size for the dock's You orb (§7.15 has only "icon 22") and caps the presence arc at 56, while §9.3.1 grows arc orbs to 64. The fix also has to change §7.26's Friend orb bullet, which repeats "56 px … in the presence arc". |
| 23 | Confirmed, fix amended | All six vague values are in the file (lines 1896, 1233/2607/2790, 1294, 1215/3204, 1279/3421, 3409). Two proposed values conflict with the file: the ripple's "300 ms `fadeOut`" (the §4.7 token `fadeOut` is 120 ms), and a new knob shadow where §7.21's slider thumb already has one. The page-slide shadow must also grow with progress, as §8.15.4 line 2790 says. The orb path's "± 40 px" had no rule for the sign. |
| 24 | Confirmed, fix amended | The three backing colours have no row in §2.8.1, although §15.8's gate reads pairs "declared in `design/tokens/glass.json`" and has Backing disc and Cover overlays cases, and `stack-decision.md` §2.1 generates every token from one JSON. The Flutter bytes are correct (0.60 → `0x99`, 0.86 → 219.3 → `0xDB`, 0.72 → 183.6 → `0xB8`, the same rounding as `twinDense`). The proposed rows gave web and Tailwind names for only one of the three. |
| 25 | Confirmed | §15.10 G6 line 4423: `palette {a, l}`; §2.1.8 line 237 and §15.5 line 4287: `{a, l, lMax}`. |
| 26 | Confirmed | §8.15.1: "13 to 15:1, … about 5.9:1"; the Glass paper row is 17.83 and 6.56. |
| 27 | Confirmed | §3.3 lists Android steps 0.85, 0.9, 1.0, 1.15, 1.3, 1.5, 1.8, 2.0, but the M row's Android cell is 0.95. |
| 28 | Confirmed, fix amended | §7.19 line 1854: "overshoots nothing; bounce 0.15 settles in 0.4 s". §4.2 `snappy`: 431 ms, 0.6 % overshoot. At 100 % that overshoot would draw past the track end, so the fix also says where the overshoot is clipped. |

---

## Confirmed

Final fixes, most severe first. Section numbers are authoritative; line numbers are from the 2026-09-29 state.

### CONSISTENCY-1 (medium): size snap tops out at T4, and T5 is declared only

- §2.4.3: replace the snap with "`< 36 px → T1`, `36–56 → T2`, `57–96 → T3`, `≥ 97 → T4`". Add: "T5 is never reached by size. It is declared only for the Massive objects of §2.4.1: the listen full player (the `medium` sheet and its 560 px desktop window, §8.16.2), the Wrapped frame, the image viewer frame and the splash lens. Sheets, desktop panels, desktop windows, the command palette and alerts are T4 (`glassThick`) at every size."
- §2.8.4 `glass.snap` row: change the value and both the TypeScript `glassSnap` and Dart `glassSnap` cells from `[36, 57, 97, 401]` to `[36, 57, 97]`.
- §15.8 physics fixture: change `tierFor(401) == T5` to `tierFor(401) == T4`.
- §7.10 **Desktop**: change "Panel and window bodies are T4 or T5 glass" to "Panel and window bodies are T4 glass (`glassThick`); the one T5 window is the listen player's (§8.16.2)".
- §8.25.14 licences: change "the desktop T5 window" to "the desktop T4 window".

### CONSISTENCY-2 (medium): the 960 px series window is a slab, and only it recedes the page

- §7.10 **Desktop**: add "Exception: the 960 px series and book window (§8.12, §8.13) is a content-layer `materialThick` slab (`rgba(19,19,23,0.84)`, blur 36, radius 32, no live glass). Its text keeps the alpha labels and its state glyphs stay bare, as on slabs; the glass nav group in its band is chrome over content, not glass on glass. Behind it the covered page recedes to scale 0.97, blur 8 (`blur.recede`) and 50 % brightness (`rgba(0,0,0,0.50)` over the page), driven by presentation progress (web `--sheet-progress`, §15.2). Every other desktop panel and window has `dimSheet` behind it, with no scale or blur."
- §8.12 **Presentation**: change "dim 50 %" to "50 % brightness (`rgba(0,0,0,0.50)`)".
- §15.2 *Mechanism*: change "(desktop: scale 0.97, blur 8, dim 50 %; …)" to "(desktop: the series and book window only, scale 0.97, blur 8, `rgba(0,0,0,0.50)`; the recap, friend and profile-form windows use `dimSheet` only, §7.10; phone and mobile web: the §7.10 recession)".
- §2.3 `r2xl` row: change the use to "Desktop windows (560 and 960 px) and the desktop Login slab (§8.3)". Desktop panels stay `rXl` 26.

### CONSISTENCY-3 (medium): three separate magnet rules

- §4.6: replace the "Magnet capture" row with three rows:
  - "Object magnet (friend orb, collection target) | within 64 px of the target centre (`physics.magnetRadius`), pulled 0.35 of the remaining distance per frame (`physics.magnetPull`) | `magnet.capture` `selection` on capture, `magnet.drop` `ahap:magnet` on release into it".
  - "Value magnet (speed dial 1.0×, cruise 1.0×, check interval 30 min) | speed dial and cruise: within ±0.08× of 1.0× (`physics.valueMagnetSpeed`; ±9.6 px at 6 px per 0.05× on the dial, ±12.8 px at 8 px per 0.05× on the cruise pill); interval slider: within 30 % of one 5-minute step's spacing of 30 (`physics.valueMagnetStepFraction`) | `detent.magnet` `rigid(0.4)`".
  - "Step magnetism (every stepped slider, §7.21) | within 30 % of a step's spacing the thumb is pulled toward that step (`physics.valueMagnetStepFraction`) | `detent.tick` per step".
- §2.8.5: add `physics.valueMagnetSpeed` = 0.08 (TypeScript constant; Flutter `physicsValueMagnetSpeed` = `0.08`) and `physics.valueMagnetStepFraction` = 0.30 (Flutter `physicsValueMagnetStepFraction` = `0.30`).
- §15.1 `glass.json` sample: add `"valueMagnetSpeed": 0.08, "valueMagnetStepFraction": 0.30` to the `physics` object beside `"magnetRadius": 64`.

### CONSISTENCY-4 (medium): press growth per class matches the components

- §2.4.1 Feather row, Press growth: change to "per component, on `press`: the tab and choice droplets +6 % (§7.15), slider thumb 28 → 34 px (§7.21), switch knob 27 → 34 × 27 (§7.22); the segmented thumb, scrub thumb and hit lens do not grow (they stretch toward the drag, §2.4.2 rule 4)".
- §2.4.1 Light row, Press growth: change to "+17 px on the longest side, capped at 0.35 × side (glass); chips at rest are content and sink to 0.96 instead (§4.10 Content sink)". Chips stay in the Light row, so they keep `snappy`.
- §4.10 Press swell, Spec: change to "Glass grows +12 px (Medium) or +17 px capped at 0.35 × side (Light); Feather objects grow per their component (§2.4.1)".

### CONSISTENCY-5 (medium): one Undo duration

- §7.34 **Full swipe**: change "destructive actions show a 5 s Undo toast instead of a confirm" to "destructive actions show the 10 s Undo toast of §7.12 instead of a confirm".

### CONSISTENCY-6 (medium): Wrapped numerals use `wrappedNumeral`

- §3.2 `display` row: change the use to "(splash wordmark, hero titles, Wrapped card 1 headline)".
- §9.2.3 card 2 (**Time**): change "the `display` numeral counting up on `drift`" to "the `wrappedNumeral` numeral counting up on `drift`".
- §9.2.4 **Design**: change "the big numeral in `display` Google Sans Flex" to "the big numeral in `wrappedNumeral` (88 px × 3 = 264 px on the canvas)".

### CONSISTENCY-7 (medium): one override mechanism for role text

- §3.7, after the `GlassText` sentence, add: "**Overrides.** `GlassText(role:, text, {int? wght, double? size, double? height})`. `wght` replaces the role's weight (Bold Text still adds +100 and press still adds +40 on top). `size` and `height` replace the base size and line height before the role's text-scale cap. On the web the same overrides are inline custom properties on the element, which win over the inherited `[data-skin="glass"]` values because every declaration of `type-<role>` is a `var()`: Tailwind arbitrary properties such as `[--mm-type-caption1-wght:700]`, `[--mm-type-mono-size:0.9375rem]` and `[--mm-type-mono-lh:1.25rem]`. Only the overrides that §7 to §10 name are allowed. Size overrides exist for `mono` only: keycaps 12/16 at `wght` 600 (§7.27); the stepper value, chapter-row number and go-to well 15/20 (§7.3, §7.17, §8.14.2); and the share side's foot line, which the web draws on the canvas at 24 px (`ctx.font`, no utility) and Flutter draws as `size: 8` inside the 360 px `RepaintBoundary` rendered at pixel ratio 3 (§9.2.4). Every other override is a weight."

### CONSISTENCY-8 (medium): the two missing alternatives exist

- §9.4.3 **Counter**: change to "a `glassRegular` pill at the bottom, "Panel 4 of 38 · Page 7" + an overview button (`squares-four` glyph 20, 44 hit, `aria-label="Show the whole page"`, Flutter `Semantics(button: true, label: "Show the whole page")`, toggling the **Overview** below) + a close ×".
- §7.37 **Accessibility**: add "Every back button also carries the "All levels" action: on Flutter `Semantics(customSemanticsActions: {CustomSemanticsAction(label: "All levels"): openOverview})`, which opens the stack overview (the flat back menu under Reduce Motion or a screen reader); on the web the back button declares `aria-keyshortcuts="Control+Backslash"` (`Meta+Backslash` on macOS) for the existing `mod+\` back menu, and right-click opens the same menu."
- §11 Long-press Back row, alternative cell: change to "`mod+\` (announced through `aria-keyshortcuts`); the Flutter custom action "All levels" on every back button (§7.37)".

### CONSISTENCY-9 (medium): the reader Esc order includes every reader layer

- §8.14.7 and §8.14.11: change the Esc order to "menu or popover → dialogue overlay and hit lens → guided view (back to the strip at the current panel) → side panel (desktop) → fullscreen → cinema → leave the reader".
- §8.0.5: change "It matches the web's `Esc` order (§8.0.6, §8.14.7)" to "It follows the same order as the web's `Esc` (§8.0.6, §8.14.7); side panels and fullscreen do not exist on phones".

### CONSISTENCY-10 (low): the app-update capsule has one place per frame

- §7.30 **App update capsule**: change the placement sentence to "Phones: the top band under the nav row, in the queue of §7.12 (after the global new-chapters capsule), falling in and leaving like a toast. Tablet and desktop: bottom-centre of the content column, so it never shares the bottom-left corner with toasts; there it waits while the bulk-selection toolbar or "Unsaved changes" bar shows." §7.12's top-band priority stays unchanged, and §15.7's phone rows stay within 8 Flutter shapes.

### CONSISTENCY-11 (low): a long press in a reorderable list opens the preview first

- §7.35 **Reorder**: change the trigger to "press 450 ms on a row: the context preview opens (§7.23: row 1.02, `dimContext`, the menu, `longpress.open`); dragging the preview more than 10 px closes the menu, fades `dimContext` out over 180 ms and turns the preview into the reorder lift (scale 1.02 → 1.03 on `press`, rim brightens, `reorder.lift` haptic). Dragging the row's handle starts the reorder lift at once, with no menu."

### CONSISTENCY-12 (low): a thrown-away AI card exits on `dismiss`

- §4.10 Throw row: change the spring cell to "`zoom` with the release velocity (throw to open); `dismiss` with the release velocity (AI cards thrown away)" and the duration cell to "projected, settle 558 ms (open) / 378 ms (away)".

### CONSISTENCY-13 (low): segmented thumb and sidebar springs

- §4.2 `snappy` use cell: change "Chips, segmented thumb, icon morphs, row expand, list entrances" to "Chips, icon morphs, row expand, list entrances" (the segmented thumb stays on `tab`, §7.6).
- §7.16: change "the width change runs on `snappy`" to "the width change runs on `minimize`", and add "desktop sidebar collapse and expand (`mod+b`)" to the Where cell of §4.10's **Minimise** row.

### CONSISTENCY-14 (low): four fan angles for four covers

- §4.10 Fan open and §8.18 **Signature moment**: change "spread to 0°, ±12°, ±24°" to "spread to −24°, −8°, 8°, 24° (three covers: −16°, 0°, 16°; two: −8°, 8°; one: 0°)".

### CONSISTENCY-15 (low): one downloaded-glyph size on covers

- §7.20 **Downloaded**: change to "`droplet` glyph 14 `success` in rows and lists; on a cover 16 px on a 22 px `rgba(0,0,0,0.72)` circle (5.17:1 over white, §7.8)".

### CONSISTENCY-16 (low): ornamental glyph sizes

- §2.7 size table: change the ornamental row to "Ornamental (empty-state lenses 44, onboarding format cards 40, Wrapped 48 to 64) | **Light**".

### CONSISTENCY-17 (low): the 24 px back-swipe start

- §8.0.5: change "starts only in the leading 24 px (like the reader's strip)" to "starts only in the leading 24 px (the width of the installed-PWA back strip above and of the Safari edge rule, §8.0.8; the readers' own strip is 20 px)".

### CONSISTENCY-18 (low): swipe pills are content twins

- §11 "Swipe a row left or right" row: change "Reveals glass action pills" to "Reveals the content-twin action pills (§7.34)".

### CONSISTENCY-20 (low): Warmth names all of its jobs

- §2.1.9 Warmth row, "Its one job": change to "The streak flame, milestone numerals, the goal ring, record sparks, the favourite star (§7.2) and the Statistics best-day dot (§9.2.1)". The star keeps `streakCore`, and the §15.8 contrast values stay as they are.

### CONSISTENCY-22 (low): every orb size is listed

- §7.26 **Profile orb** sizes: change "24 (chips)" to "24 (chips; the dock's You tab, centred on the 22 px icon slot, with the goal ring of §9.2.2 outside it)" and "56 (avatar grid, drop targets, presence arc)" to "56 (avatar grid, drop targets), 56 to 64 (presence arc, larger the more recently active, §9.3.1)".
- §7.26 **Friend orb**: change "56 px as drop targets and in the presence arc" to "56 px as drop targets and 56 to 64 px in the presence arc (§9.3.1)".

### CONSISTENCY-23 (low): numbers for the six vague values

- §7.22 **Switch** knob: "knob 27 px white with `0 2px 8px rgba(0,0,0,0.4)`" (the slider thumb's shadow, §7.21).
- §4.10 Page slide, §8.14.1 and §8.15.4: "`0 0 8px rgba(0,0,0,0.45)` on the moving edge, its alpha scaled from 0 to 0.45 with turn progress".
- §4.10 Lens pop and §8.11: "Scale → 0 on `lens` while a 1 px `rgba(255,255,255,0.30)` ring expands from radius 48 to 96 px on `lens`, its opacity 0.30 → 0 over 300 ms `cubic-bezier(0.4, 0, 1, 1)` (the `fadeOut` curve)".
- §4.10 Deal and §9.1.2: "along a quadratic Bézier whose control point sits 48 px perpendicular to the midpoint of the start–end chord, on the side toward the top of the screen".
- §4.10 Orbs fly out and §9.3.4: "along a quadratic Bézier from the orb's centre to the top edge at the orb's x + 40 px × s, where s is −1 for an orb left of the sheet's centre and +1 otherwise; the control point sits 120 px above the start".
- §9.3.2 sending state: "waits in the strip at 60 % opacity inside a 1.5 px `bloom` ring at 40 %".

### CONSISTENCY-24 (low): token keys for the three backing colours

- §2.8.1: add three rows.
  - `color.backingDisc` | `rgba(0,0,0,0.60)` | `--mm-color-backing-disc: rgba(0,0,0,0.60)` | `--color-backing-disc` (`bg-backing-disc`) | `colorBackingDisc` = `Color(0x99000000)`.
  - `color.coverBacking` | `rgba(0,0,0,0.86)` | `--mm-color-cover-backing: rgba(0,0,0,0.86)` | `--color-cover-backing` (`bg-cover-backing`) | `colorCoverBacking` = `Color(0xDB000000)`.
  - `color.coverDisc` | `rgba(0,0,0,0.72)` | `--mm-color-cover-disc: rgba(0,0,0,0.72)` | `--color-cover-disc` (`bg-cover-disc`) | `colorCoverDisc` = `Color(0xB8000000)`.
- §2.1.2, §2.4.1 rule 1, §7.8 and §7.20 cite the keys beside the literals, and §15.8's Backing disc and Cover overlays cases read these three keys from `glass.json`.

### CONSISTENCY-25 (low): the amendment register carries `lMax`

- §15.10 G6: change "`palette {a, l}`" to "`palette {a, l, lMax}`".

### CONSISTENCY-26 (low): paper intro ranges

- §8.15.1 intro: change "Text sits at 13 to 15:1, muted text at about 5.9:1." to "Text sits at 13.4 to 17.8:1, muted text at 5.8 to 6.6:1."

### CONSISTENCY-27 (low): the Android column uses listed steps only

- §3.3 table, M row: change the Android cell from "0.95" to "n/a" (0.9 is on the S row and 1.0 on the L row).

### CONSISTENCY-28 (low): the `snappy` numbers in §7.19

- §7.19 **Linear**: change "(a large jump overshoots nothing; bounce 0.15 settles in 0.4 s)" to "(bounce 0.15: a 0.6 % overshoot, settled in 431 ms; the fill is clipped to the track, so the overshoot never draws past the end at 100 %)".

---

## Refuted

- **CONSISTENCY-19.** "Reset reader settings" is already hold-to-confirm in §8.14.5 and §8.25.3, and §7.1's list is not exhaustive: its alternative paragraph says "and so on".
- **CONSISTENCY-21.** The six sheet ids have their desktop forms in §8.14.11, §8.15.2, §8.16.2 and §7.31, and §7.10 already sends reader sheets to the reader's own panels.
