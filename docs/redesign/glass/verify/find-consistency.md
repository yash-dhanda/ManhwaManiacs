# Glass DESIGN.md: internal-consistency audit

Lens: every token, motion, haptic and sound value identical everywhere it appears; every referenced name defined; no vague values; no contradicting sections. Source of truth: `docs/redesign/glass/DESIGN.md` itself (4,184 lines, read in full). Contrast ratios and spring settle/overshoot values were recomputed with a script (WCAG 2.x luminance; semi-implicit spring integration at dt = 10 µs, settle = last time |1 − x| > 0.005 from rest, the rule §4.2 states).

45 findings: 1 high, 18 medium, 26 low.

---

## CONSISTENCY-1

- **Severity:** high
- **Section:** §2.4.2 rule 7 vs §2.4.2 rule 8, §7.10, §7.11, §7.35, §8.15.5, §8.16.2, §15.7
- **Problem:** Rule 7 forbids glass on glass, but many components put glass controls on glass sheets, alerts and players. Rule 8 even allows a second lit (glass) object on a sheet or alert. An implementer can't tell whether a control on a sheet is glass (an extra backdrop read and `BackdropGroup` member) or a fill. It also breaks the Flutter budget: the §15.7 phone row already counts 8 members with the sheet as one member, so one glass close button on a partial sheet makes 9, over the limit of 8.
- **Evidence:** §2.4.2 rule 7: "**No glass on glass.** Anything drawn on glass uses fills and `onGlass` text." §2.4.2 rule 8: "a sheet or alert may carry its own [`glassTinted`]". §7.10: "close button (`glassThin` 32 circle with ×, 44 hit)". §7.11: buttons are "full-width capsules (L 50)" of the §7.1 variants (Secondary = `glassThin`, Primary = `glassTinted`) on a `glassThick` alert. §8.16.2: "**play/pause** (72 px, `glassTinted` …)", "three 72 px glass tiles", "a 72 px voice orb (a T2 glass sphere)", "a `glassThin` chip under it" (all on the player sheet). §8.15.5: "Face tiles … (selected: `glassThin` + ring)" on the Aa sheet. §7.35: "`glassRegular` capsule 52 tall … actions as glass icon buttons". Only §7.16 applies rule 7: "drawn with a `fill2` fill … (it sits on the sidebar's glass, and nothing on glass is glass, §2.4.2 rule 7)". §15.7: "leading button, title capsule, trailing group, dock, orb, accessory, sheet, toast or menu = **8**".
- **Fix:** Reword rule 7 as: "Controls drawn on a glass surface (sheet, alert, popover, window, sidebar, full player, floating toolbar) are content twins of their variant: same shape and size, `fill2` fill (`rgba(120,120,128,0.30)`), 0.5 px rim `rgba(255,255,255,0.22)`, inner light, `onGlass` label, no backdrop read, no displacement, no dim. The host's single lit action (rule 8) is a tinted twin: fill `iris600` at 86 %, rim `rgba(255,255,255,0.30)`, specular `iris100` at 60 %, caustic kept, and no backdrop read of its own." Then replace "`glassThin`" with "`fill2` twin" in §7.10 (close button), §8.15.5 (face tile), §8.16.2 (tiles, speaking-orb chip) and §7.35 (toolbar icon buttons), and make the §8.16.2 speaking orb a content twin sphere. The §15.7 counts then stay correct as written.

## CONSISTENCY-2

- **Severity:** medium
- **Section:** §2.4.1 mass-class table vs §4.10 (Content sink), §7.7, §7.8, §2.4.1 rule 1
- **Problem:** The mass-class table says cards and posters grow to 1.04 on press. The universal press rule, the motion table and the card spec all say content sinks to 0.97. The Heavy row also lists "the hero card" as T4 Block glass, but the hero card is a cover (content) and rule 1 says content is never glass.
- **Evidence:** §2.4.1: "Medium | … cards and posters (content: scale 1.04, no glass) | T3 Slab | +12 px on the longest side (cards and posters: scale 1.04)". §4.10: "**Content sink** | … | Cards and posters 0.97, rows 0.99, chips 0.96, plain icons 0.92". §7.7: "**pressed** sinks to 0.97 on `press` (content sinks)". §7.0 intro: "Glass swells, content sinks". §2.4.1 Heavy: "the hero card … | T4 Block". §8.8: "a floating portrait card (cover 2:3 …)".
- **Fix:** In the Medium row, replace "cards and posters (content: scale 1.04, no glass)" with "cards and posters (content, no glass)" and replace the press-growth cell with "+12 px on the longest side (glass); content sinks per the Content sink move (cards and posters 0.97, rows 0.99)". Remove "the hero card" from the Heavy row. Add it to the Massive row's content list as "the hero card (content, no glass; lifts on `smooth`)".

## CONSISTENCY-3

- **Severity:** medium
- **Section:** §2.4.1 mass-class table, §2.4.2 (`glassFilm`), §2.4.3 vs §7.1, §7.6, §7.12, §7.13, §7.15, §7.16, §7.21, §7.22
- **Problem:** The mass-class table fixes the glass tier per object class ("Nobody picks … a thickness by feel"), but the component specs name different tiers for the same objects. Buttons are Medium/T3 in the table but `glassThin` (T2) in §7.1. The tab droplet, thumbs and knobs are Feather/T1 `glassFilm` in the table but "`glassThin` clear" (T2) or `glassClear` (the finish reserved for media) in §7. Toasts are T2 in three places but `glassRegular` (T3) in §7.12.
- **Evidence:** §2.4.1 Feather: "Tab droplet, scrub thumb, toggle knob, slider thumb, chips and segmented thumbs **while dragged** … | T1 Film". §2.4.2: "`glassFilm` (transient Feather glass) | T1". §2.4.1 Medium: "Buttons, dock, … | T3 Slab". §7.1: "**Secondary** | `glassThin`". §7.15: "a `glassThin` clear droplet (capsule 56 × 52)". §7.6: "it turns `glassThin` clear". §7.21: "the thumb turns `glassClear`". §7.22: "it turns `glassClear`". §2.4.2: "`glassClear` (controls over the hero spotlight, the series band and the image viewer)". Toasts: §2.4.1 layer 6 "Toasts … T2 capsule", §2.4.3 "toasts are T2", §15.7 counts. §7.12: "**Visual:** `glassRegular` capsule".
- **Fix:** (a) In the Medium row, write "Buttons (T2 Pane: every button is ≤ 56 px; press growth +12 px), dock, accessory, reader capsules, sidebar, minimised pill (T3 Slab)". (b) Define the droplet and transient finish once in §2.4.2 as "`glassFilm` + clear finish: T1 recipe with fill `rgba(255,255,255,0.02)`, rim `rgba(255,255,255,0.28)`, specular 0.50". Use that exact name in §7.6, §7.13, §7.15, §7.16, §7.21, §7.22 and §7.28 in place of "`glassThin` clear" and "`glassClear`". (c) In §7.12, change "`glassRegular` capsule" to "`glassThin` capsule (T2)".

## CONSISTENCY-4

- **Severity:** medium
- **Section:** §2.4.2 (`glassThin` "controls ≤ 56 px"), §2.4.3 size snap vs §7.24, §7.27, §8.16.2, §9.2.3 card 10, §9.4.2, §9.4.3, §2.4.1 Massive row
- **Problem:** Several fixed-size glass objects use tiers that contradict the tier size ranges and the variant definitions. No rule says whether fixed-size objects follow the size snap. The listen full player is T5 Monolith in the mass table, but on phones it is a sheet, and sheets are T4 `glassThick` that turn `solid1` at `large`.
- **Evidence:** §2.4.2: "`glassThin` (controls ≤ 56 px) | T2". §2.4.3: "`36–56 → T2`, `57–96 → T3`, `97–400 → T4`". §7.24: "a 96 px `glassThin` circle". §9.2.3 card 10: "a 96 px T2 lens". §9.4.2: "six glass scene orbs (T2, 64 px)". §8.16.2: "a 72 px voice orb (a T2 glass sphere)". §9.4.3: "framed by a **T2 glass lens**" around a whole panel. §7.27: tooltip "`glassThick` capsule" (T4) with `footnote` text and 6 px vertical padding, about 30 px tall. §2.4.1 Massive: "The listen full player … | T5 Monolith". §8.16.2: "A sheet from the mini player … detents `medium` … and `large`". §7.10: "at `large` … the material cross-fades `glassThick` → `solid1`".
- **Fix:** Add to §2.4.3: "Fixed-size lens objects keep a declared tier regardless of size: object lens 96, Wrapped lens 96, scene orbs 64, speaking orb 72 and the guided-view lens are T2 Pane; the hit lens is T1." List them in the §2.4.1 Light row. Change §7.27 to "`glassThin` capsule (T2), min height 36 px, padding 9 12". Add to §7.10: "Exception: the listen full player sheet is `glassMonolith` (T5) at `medium` and cross-fades to `solid2` at `large`."

## CONSISTENCY-5

- **Severity:** medium
- **Section:** §4.2 (`sheet` row) vs §4.1 law 10, §7.10
- **Problem:** The spring table says `sheet` (bounce 0.08) handles dismiss by button. Law 10 bans bounce on exits, and §7.10 says button dismissal uses `dismiss`.
- **Evidence:** §4.2: "`sheet` | 480 | 0.08 | … | Sheet present and dismiss by button". §4.1 law 10: "Dismissals and exits use bounce 0". §7.10: "Dismiss by button: `dismiss`."
- **Fix:** Change the §4.2 `sheet` use cell to "Sheet present by button (dismissal by button uses `dismiss`, law 10)".

## CONSISTENCY-6

- **Severity:** medium
- **Section:** §4.6 thresholds table vs §5.2 events table
- **Problem:** Four haptics in §4.6 disagree with the event mapping in §5.2, which is what `GlassHaptics` actually plays.
- **Evidence:**
  - Back swipe: §4.6 has "`rigid` 0.5 when the projection crosses the line", but §5.2 has "`threshold.cross` | … back swipe … | `rigid(0.6)`".
  - Image dismiss: §4.6 has "`soft` 0.5 at the line", but §5.2 `threshold.cross` covers "image dismiss" with `rigid(0.6)`.
  - Throws: §4.6 has "Throw to open … | `rigid` 0.7" and "Throw away … | `rigid` 0.7", but §5.2 has "`throw.commit` | … | `rigid` (velocity-scaled)" (§5.1: `i = clamp(0.3 + |v| / 4000, 0.3, 1.0)`).
  - Magnet: §4.6 has "`selection` on capture, `soft` on release into it", but §5.2 has "`magnet.drop` | Released into a magnet | `ahap:magnet`".
- **Fix:** Make §4.6 cite the events: back swipe and image dismiss use "`threshold.cross` rigid(0.6) / `threshold.back` rigidBack (soft 0.3)". Both throw rows use "`throw.commit`, rigid velocity-scaled `clamp(0.3 + |v|/4000, 0.3, 1.0)`" (0.6 at 1200 px/s). The magnet row uses "`magnet.capture` selection on capture, `magnet.drop` `ahap:magnet` on release into it".

## CONSISTENCY-7

- **Severity:** medium
- **Section:** §4.10 motion table vs §2.8.5 / §4.7 curve tokens
- **Problem:** `CurveToken` binds a duration to a curve (`CurveToken(ms: 180, curve: …)`), and `play()` accepts only table names. Yet five moves use a curve token at a different duration, so the implementer must guess whether the token's ms or the row's ms wins.
- **Evidence:** §2.8.5: "`curve.fadeIn` | 180 ms", "`curve.tintShift` | 900 ms", "`curve.fadeOut` | 120 ms". §4.10:
  - "**Tab switch** | 120 ms | `fadeIn`"
  - "**Step into the light** | 1,100 ms total | … `tintShift` (colour pour, 600 ms)"
  - "**Row pulse** | 900 ms | `fadeOut` curve on the fill"
  - "**Field ripple** | 600 ms | `fadeIn` curve"
  - "**Word stream** | 120 ms fade per word | `fadeIn`"
- **Fix:** Add five tokens to §4.7 and §2.8.5 and name them in §4.10:
  - `curve.tabSwitch` 120 ms `cubic-bezier(0.2, 0, 0, 1)`
  - `curve.colorPour` 600 ms `cubic-bezier(0.2, 0, 0, 1)`
  - `curve.rowPulse` 900 ms `cubic-bezier(0.4, 0, 1, 1)`
  - `curve.fieldRipple` 600 ms `cubic-bezier(0.2, 0, 0, 1)`
  - `curve.wordStream` 120 ms `cubic-bezier(0.2, 0, 0, 1)`

  Emit each with its `--mm-ease-*` / `--mm-dur-*` pair and a `CurveToken`.

## CONSISTENCY-8

- **Severity:** medium
- **Section:** §4.7 (`reducedCrossfade`) vs §4.10, §4.11, §8.0.4
- **Problem:** The Reduce Motion replacement durations disagree for sheets and for the tab switch.
- **Evidence:** §4.7: "`reducedCrossfade` | 150 ms (in-page) / 200 ms (routes, sheets)". §4.10: "**Sheet present** … | Fade + 16 px translate, 150 ms". §4.11: "Sheets | … | Fade + 16 px translate, 150 ms". §4.10: "**Tab switch** … | 120 ms fade, no wave". §8.0.4: "Reduce Motion: every row becomes a 200 ms cross-fade" (the Tab switch is one of its rows).
- **Fix:** Change §4.7 to "150 ms (in-page and sheets) / 200 ms (routes)". Change §8.0.4 to "Reduce Motion: every row becomes a 200 ms cross-fade, except Tab switch (120 ms fade, no wave, §4.10)".

## CONSISTENCY-9

- **Severity:** medium
- **Section:** §4.10 ("This table is exhaustive … `play()` throws on a name that is not in this table") vs §4.11, §7, §8, §9
- **Problem:** §4.11 names moves that don't exist in §4.10, and many specified animations have no §4.10 row. A development build would throw on them, and the generated `MotionName` enum can't express them. The podium drop has no numbers at all.
- **Evidence:**
  - §4.11: "flame flicker", "podium drop in Wrapped", "Wrapped page pile". None is a §4.10 name.
  - Missing rows:
    - §9.2.2 flame tip (`drift`, lean `0.004 × a`, noise 2 %/5 Hz)
    - §9.2.3 card 2 "the `display` numeral counting up on `drift`"
    - §9.2.3 card 3 glyph pile ("2,400 px/s² gravity … restitution 0.3")
    - §9.2.3 card 4 "covers drop in from above with gravity and bounce" (no gravity, restitution, start height or spacing)
    - §7.19 liquid ring spinner ("once per 900 ms")
    - §7.19 three dots ("bobs 3 px on `tick`, 80 ms apart")
    - §7.20 count pop ("1 → 1.25 → 1 on `tick`")
    - §7.29 queued ring ("one turn per 4 s")
    - §8.5 manage-mode breathe ("scale 1 ↔ 1.02 over 2 s")
    - §8.8 spotlight drop ("from scale 0.9 and 24 px above" on `lens`)
    - §8.11 lens pop ("`lens` shrink to 0")
    - §7.39 chart rise (`snappy`) and radar (`celebrate`)
    - §9.3 spoiler unseal ("fade in 160 ms, 40 ms apart")
    - §8.14.3 tap light ("fades over 300 ms")
    - §9.4.2 scene-orb glyph loops
    - §8.25.15 preview line ("typed once at 12 ms per character")
- **Fix:** Add §4.10 rows, each with duration, spring or curve, spec, where used and a Reduce Motion column:
  - Flame flicker: tip spring `drift`, lean `0.004 × a` px capped at 18 % of height, value noise 2 % at 5 Hz; RM: frozen.
  - Count-up: numeral on `drift`, 0 → value; RM: final value.
  - Page pile: gravity 2,400 px/s², restitution 0.3, ≤ 200 bodies; RM: at rest.
  - Podium drop: gravity 3,000 px/s², restitution 0.3, from y −200 px, 120 ms apart, #5 first and #1 last, the #1 landing on `celebrate`; RM: at rest.
  - Liquid spinner: 900 ms/turn, arc 90° ↔ 270°; RM: opacity 0.4 ↔ 1 over 1.2 s.
  - Button dots: 3 px bob on `tick`, 80 ms phase.
  - Count pop: 1 → 1.25 → 1 on `tick`.
  - Queued ring: 4,000 ms/turn linear.
  - Orb breathe: 1 ↔ 1.02, 2,000 ms sine.
  - Spotlight drop: scale 0.9 → 1, −24 px → 0 on `lens`.
  - Lens pop: `lens` to scale 0.
  - Chart rise: `snappy` wave; radar out on `celebrate`.
  - Spoiler unseal: 160 ms fade, 40 ms apart.
  - Tap light: 120 px radial at 10 % white, 300 ms fade.
  - Scene glyph loops per §9.4.2.
  - Quick type: 12 ms per character (also used by Deal).

  Rename the §4.11 entries to these exact names.

## CONSISTENCY-10

- **Severity:** medium
- **Section:** §4.2 Settle and Overshoot columns, mirrored in §2.8.5 (`--mm-spring-*-ms`), §4.8, §4.10, §10.1, §10.2
- **Problem:** §4.2 defines Settle as "the time to stay within 0.5 % of the target from rest", but the column doesn't follow that rule, or any single threshold. The five critically damped springs (identical shape, bounce 0) must share one settle/duration ratio, yet the column gives 1.19, 1.27, 1.24, 1.28 and 1.18. A `build.mjs` written to the stated rule emits `-ms` values and `linear()` sample windows that differ from every table. The motion-timings overlay's "overruns its settle time" check then uses numbers that disagree with the document. Two springs with the same ζ = 0.90 (`camera`, `smooth`) are also given different overshoots (0.1 % vs 0.2 %).
- **Evidence:** §4.2 (doc → recomputed with the stated rule):

  | Spring | Doc settle | Recomputed |
  |---|---|---|
  | `track` | 203 | 147 |
  | `press` | 297 | 253 |
  | `tick` | 337 | 289 |
  | `snappy` | 429 | 431 |
  | `morph` | 485 | 434 |
  | `tab` | 558 | 518 |
  | `lens` | 528 | 467 |
  | `sheet` | 494 | 448 |
  | `sheetSnap` | 399 | 342 |
  | `page` | 621 | 615 |
  | `zoom` | 591 | 558 |
  | `settle` | 444 | 414 |
  | `minimize` | 497 | 473 |
  | `dismiss` | 411 | 378 |
  | `camera` | 445 | 392 |
  | `celebrate` | 723 | 643 |
  | `drift` | 1065 | 1064 |
  | `letter` | 402 | 345 |
  | `smooth` | 490 | 436 |

  Overshoot: `camera` and `smooth` both compute to 0.15 %.
- **Fix:** Either replace the Settle column, every `--mm-spring-*-ms` value in §2.8.5 and every "settle N ms" in §4.10 with the recomputed values above, and update the dependants: §4.8 "429 ms … within 670 ms" → "431 ms … within 671 ms"; §10.1 CSS glint delay `+ 402ms` → `+ 345ms`; §10.2 "settles in 337 ms" → "289 ms". Or state that settle is not a documented constant: "`build.mjs` computes settle as the last time |1 − x| > 0.005 from rest; the ms values in this file are informative", and delete the numeric settle values from §2.8.5 and §4.10. In both cases set the `camera` and `smooth` overshoot to 0.15 %.

## CONSISTENCY-11

- **Severity:** medium
- **Section:** §3.5 (Implementation) vs §3.7 (`@utility type-<role>`)
- **Problem:** Two rules set `font-variation-settings` on glass text. `font-variation-settings` replaces the whole axis list, so whichever rule wins drops the other's axes. The `.on-glass` rule omits `"wght"`, which silently resets role weights (and the +40 press weight) on glass. It is also invalid CSS: `"opsz" auto` is not a `<string> <number>` pair, so browsers drop the whole declaration.
- **Evidence:** §3.5: "`.on-glass { font-variation-settings: "ROND" var(--glass-rond), "GRAD" var(--glass-grad), "opsz" auto; }`". §3.7: "`font-variation-settings: "wght" var(--mm-type-<role>-wght), "ROND" var(--glass-rond, var(--mm-type-<role>-rond)), "GRAD" var(--glass-grad, 0)`".
- **Fix:** Delete the `.on-glass` rule from §3.5 and say "the `type-<role>` utility (§3.7) already reads `--glass-rond` and `--glass-grad`; optical size comes from `font-optical-sizing: auto`". Also state that the press weight is applied as `calc(var(--mm-type-<role>-wght) + var(--press-wght, 0))` inside the same declaration.

## CONSISTENCY-12

- **Severity:** medium
- **Section:** §2.8.3 (`border.slab` row)
- **Problem:** The Tailwind column references a CSS variable that is never defined. `border-(--mm-border-slab-color)` resolves to an invalid value, the border colour falls back to `currentColor`, and every slab gets a `label1`-coloured 1 px border instead of 6 % white.
- **Evidence:** "`border.slab` | … | `--mm-border-slab: 1px solid rgba(255,255,255,0.06)` | `border border-(--mm-border-slab-color)`". No `--mm-border-slab-color` appears anywhere else in the file.
- **Fix:** Add `--mm-border-slab-color: rgba(255,255,255,0.06)` to the Web CSS column (keep `--mm-border-slab`), and write the Flutter value as `borderSlab = BorderSide(color: Color(0x0FFFFFFF), width: 1)` (unchanged).

## CONSISTENCY-13

- **Severity:** medium
- **Section:** §2.8 ("emits every key below three ways") vs §2.1.7, §15.1
- **Problem:** `edgeSoft`, used on every screen, has no key, CSS variable, Tailwind name or Flutter field; only `edgeHard` is mapped. `glass.json` holds keys that §2.8 never lists, so no generated names exist for them.
- **Evidence:** §2.1.7 defines `edgeSoft` ("`rgba(0,0,0,0.72)` … then a 24 px linear fade … backdrop blur 6"). §2.8.1 lists "`color.edgeHard`" and no edgeSoft row. §15.1 JSON: `"dim": { … "edgePlateau": 0.72, "edgeFade": 24 }`, `"glass": { … "snap": [36, 57, 97, 401] }`, `"spring": { "format": "physical", … }`. None of these appears in §2.8.
- **Fix:** Add to §2.8.4:
  - `dim.edgePlateau` 0.72 → `--mm-dim-edge-plateau: 0.72` / `dimEdgePlateau = 0.72`
  - `dim.edgeFade` 24 px → `--mm-dim-edge-fade: 24px` / `dimEdgeFade = 24.0` (blur uses the existing `blur.edge` 6)
  - `glass.snap` [36, 57, 97, 401] → TypeScript `glassSnap` / `glassSnap = [36, 57, 97, 401]`

  State that `spring.format` is generator configuration, not a token.

## CONSISTENCY-14

- **Severity:** medium
- **Section:** §2.4.2 (Rim column), §2.4.3 (Specular rim), §2.6 (`rim`), §2.8.4 (`GlassTier`)
- **Problem:** There are three incompatible definitions of the glass rim, and the per-tier rim colours are not in the token map. The content twin needs "the tier's rim", but the generated `GlassTier` has no rim field.
- **Evidence:** §2.4.2 gives a flat rim per tier ("`rgba(255,255,255,0.26)`" T1 … "0.14" T5). §2.4.3 gives a gradient ending at "`rgba(255,255,255,S × 0.55) 100%`" (T3: 0.22). §2.6 `rim` ends "`rgba(255,255,255,0.20)` at 100 %". §2.4.1: content twin uses "the tier's rim (0.5 px, `rgba(255,255,255,0.22)`)". §2.8.4 `GlassTier(thickness:, bezel:, displacement:, blur:, saturate:, fill:, specular:, shadow:, dispersion:, rond:)` has no rim.
- **Fix:** State once in §2.4.3: "Live glass draws the specular-rim gradient (end stop `S × 0.55`); the flat Rim value of §2.4.2 is used by frosted tier B's fallback stroke and by content twins." Change §2.6 `rim` end stop to "`rgba(255,255,255,S × 0.55)` at 100 %". Add `rim` to `glass.t1`–`t5` in §2.8.4: CSS `-rim: rgba(255,255,255,0.26 | 0.22 | 0.20 | 0.16 | 0.14)`, Dart `rim: Color(0x42FFFFFF | 0x38FFFFFF | 0x33FFFFFF | 0x29FFFFFF | 0x24FFFFFF)`. Set the content-twin text to "the rim of the tier it replaces".

## CONSISTENCY-15

- **Severity:** medium
- **Section:** Conventions, §2.8 ("Tailwind name `X` maps to `var(--mm-X)`") vs §2.8.2, §2.8.5
- **Problem:** The stated mapping rule doesn't hold for layout lengths or springs, so a generator built to the rule emits undefined variables.
- **Evidence:** §2.8: "The rule "Tailwind name `X` maps to `var(--mm-X)`" is the same for both skins". §2.8.2: "`--mm-layout-touch-min: 44px` | `--spacing-touch-min`" (by the rule this maps to `var(--mm-spacing-touch-min)`, which doesn't exist). "`--mm-layout-reader-strip-max` | `--spacing-reader-strip`" (the name differs). §2.8.5: "`--mm-spring-track: linear(…)` | `--ease-spring-track`" (the rule gives `var(--mm-ease-spring-track)`).
- **Fix:** Replace the rule with: "Each Tailwind name maps to the CSS variable in the Web CSS column of its own row: colours `--color-X: var(--mm-color-X)`; radius `--radius-X: var(--mm-radius-X)`; blur `--blur-X: var(--mm-blur-X)`; layout `--spacing-X: var(--mm-layout-X)`; springs `--ease-spring-X: var(--mm-spring-X)`; curves `--ease-X: var(--mm-ease-X)`." Rename `--spacing-reader-strip` to `--spacing-reader-strip-max` (utility `w-reader-strip-max`).

## CONSISTENCY-16

- **Severity:** medium
- **Section:** §7.9, §8.8 (rail poster counts) vs §7.8 (poster widths), §2.2 (margins, gaps, `contentMax`)
- **Problem:** The stated number of visible rail posters can't be reached with the specified poster widths, gaps and margins.
- **Evidence:** §7.8: "phone 124 (rail) … tablet 148; desktop 168; wide 184". §7.9: "gap 12 (phone) / 16 (desktop) … (3.2 posters visible at 390 px wide)". At 390 px with the 16 px leading margin: (374 + 12) / (124 + 12) = 2.84. §8.8: "Rails show 7 (1440 px) to 9 (1920 px) posters". At 1440: column 1440 − 304 = 1136, minus 2 × 40 = 1056, and (1056 + 16) / 200 = 5.4. At 1920 the column caps at `contentMax` 1440: (1360 + 16) / 200 = 6.9. §8.8: "Tablet: … rails show 5 to 6 posters". At 768: (768 − 100 − 48 + 16) / 164 = 3.9.
- **Fix:** Change §7.9 to "(2.8 posters visible at 390 px wide)", §8.8 desktop to "Rails show 5.4 (1440 px) to 6.9 (1920 px, the 1440 px column cap) posters", and §8.8 tablet to "rails show 3.9 to 5.4 posters". If 3.2 on phone is the intent, set the phone rail poster to 108 px wide × 162 tall instead.

## CONSISTENCY-17

- **Severity:** medium
- **Section:** §2.1.1 (`g600`), §14.2 vs §14.2 last bullet, §15.8 (contrast gate)
- **Problem:** `g600` is allowed as meta text at 15 px on `surface1` at 4.12:1, but the contrast gate fails CI below 4.5:1 for text under 24 px, and the gate checks every text pair declared in `glass.json`. Either CI fails or the rule is not enforced.
- **Evidence:** §2.1.1: "`g600` | `#76767F` | 4.67 | 4.12 | Meta text at 15 px and larger only". §14.2: "`g600` meta text is used only at 15 px and larger (4.12:1 on `surface1`)". §14.2: "fails CI below 4.5:1 (3:1 for text 24 px and larger …)".
- **Fix:** Change `g600` to `#7D7D86`: 5.15:1 on black, 4.54:1 on `surface1` (recomputed). Update §2.1.1, §2.8.1 (`--mm-color-g600: #7D7D86`, `colorG600 = Color(0xFF7D7D86)`) and §14.2 ("4.54:1 on `surface1`, any size ≥ 13 px").

## CONSISTENCY-18

- **Severity:** medium
- **Section:** §8.0.6 (global keys) vs §7.34, §8.13
- **Problem:** Two keys are bound to conflicting actions. `x` is both "select" and "remove". Bare `g` on the book page is "go to chapter", which collides with the global `g` chord prefix (1 s window). Only the readers disable the chords.
- **Evidence:** §8.0.6: "`x`, `shift+x` | Select, range select"; §7.35: "`x` on desktop enters select mode"; §7.34: "`x`/`Delete` remove with undo". §8.0.6: "`g h` · `g l` … (1 s chord window)"; §8.13: "**Keys:** as §8.12 plus `g` go to chapter". §8.14.7: "the global `g` chords are off inside both readers" (the book page is not a reader).
- **Fix:** In §7.34 change "`x`/`Delete` remove with undo" to "`Delete` remove with undo". In §8.13 delete "plus `g` go to chapter", because §8.12's `/` already focuses the go-to field.

## CONSISTENCY-19

- **Severity:** medium
- **Section:** §15.2 (`GlassSurface` rendering tier C) vs §4.11 (Increase Contrast)
- **Problem:** §15.2 renders Increase Contrast with the opaque solid tier, but §4.11 keeps glass translucent under Increase Contrast and raises the legibility dim. That only makes sense for non-solid glass.
- **Evidence:** §15.2: "C "solid" (Reduce Transparency, Solid glass, Increase Contrast)". §4.11: "**Increase Contrast** adds `hcBorder` … raises `dimLegibility`'s floor from 0.22 to 0.40 and its ceiling from 0.64 to 0.72". §2.1.7: "Solid tiers … have no dim: they are opaque."
- **Fix:** Change §15.2 to "C "solid" (Reduce Transparency, Solid glass); Increase Contrast is a modifier on tiers A and B (dim clamp 0.40–0.72, `hcBorder`, `label2` → `label1`, `label3` → `label2`, `iris300` accent text, 3 px focus ring)". Add `dimMinHc = 0.40` and `dimMaxHc = 0.72` to the `dim.legibility` row of §2.8.4 (`--mm-dim-min-hc: 0.40; --mm-dim-max-hc: 0.72`).

## CONSISTENCY-20

- **Severity:** low
- **Section:** §2.1.2 (`onTint`), §2.1.9 (`machineWash`), §2.8.1 (`fill2`)
- **Problem:** Three numeric values don't match their own inputs or the other places that state them.
- **Evidence:** §2.1.2: "`onTint` … 4.61 over a white page". §2.1.7, §14.2 and Appendix A (7) say 4.66, and the recomputation of `#7262DD` gives 4.66. §2.1.9: "`label1` on `machineWash` over black measures 15.2:1" (recomputed 15.1). §2.8.1: `fill2` 0.30 → `Color(0x4C787880)`, but §2.8.4 `glass.tinted` rim 0.30 → `Color(0x4DFFFFFF)` (round(76.5) = 77 = 0x4D).
- **Fix:** Change §2.1.2 to "4.66 over a white page", §2.1.9 to "15.1:1", and `colorFill2` to `Color(0x4D787880)`.

## CONSISTENCY-21

- **Severity:** low
- **Section:** §10.1 (table, web code, CSS), §12.4, §2.8.5 (`spring.letter`)
- **Problem:** The letter spring is written with rounded constants in three places instead of the token values. The web interruptible variant uses an undefined export name, `glassSpring.letter`, where §15.1 names springs `spring.<name>`. In per-word mode (> 60 graphemes) the CSS glint delay still multiplies by 24 ms, so the glint starts before the last word settles.
- **Evidence:** §2.8.5: "`spring.letter` | 424 ms, bounce 0.12 (k 219.6, c 26.08)". §10.1: "(k 220, c 26)"; "`glassSpring.letter = { type: "spring", stiffness: 220, damping: 26, mass: 1 }`". §12.4: "k 220 / c 26". §10.1 CSS: "`lr-glint 500ms linear calc(var(--n) * 24ms + 402ms + 120ms)`", where `--n` counts words in per-word mode and words are staggered 40 ms.
- **Fix:** Use "k 219.6, c 26.08" in §10.1 and §12.4, and replace `glassSpring.letter` with the generated `spring.letter` from `tokens.generated.ts`. Set `--stagger` on the heading (24 ms, or 40 ms when per-word) and write the glint delay as `calc(var(--n) * var(--stagger) + var(--mm-spring-letter-ms) + 120ms)`.

## CONSISTENCY-22

- **Severity:** low
- **Section:** §2.4.3 (Dispersion bullet vs Web mapping bullet)
- **Problem:** The web dispersion recipe doesn't produce the stated channel offsets.
- **Evidence:** "channels offset 0 / 0.6 / 1.2 px (T4) or 0 / 1.2 / 2.4 px (T5)" vs "three displacement passes at scale × 1.00 / 1.02 / 1.04". Those multipliers give 0 / 0.36 / 0.72 px on T4 (displacement 18) and 0 / 0.44 / 0.88 px on T5 (displacement 22).
- **Fix:** Change the web mapping to "scale × 1.000 / 1.033 / 1.067 (T4) and × 1.000 / 1.055 / 1.109 (T5)". Those give the stated 0.6 / 1.2 and 1.2 / 2.4 px offsets.

## CONSISTENCY-23

- **Severity:** low
- **Section:** §3.6 (Legible text, web) vs §3.7 (`@utility type-<role>`)
- **Problem:** Legible text's "+0.01 em" tracking is set as `--mm-tracking-legible`, but the type utility's `letter-spacing` never reads it, so the tracking change never applies on the web.
- **Evidence:** §3.6: "`[data-skin="glass"][data-legible="on"] { --mm-font-sans: var(--mm-font-legible); --mm-tracking-legible: 0.01em; }`". §3.7: the utility declares "`letter-spacing`" from `--mm-type-<role>-track` only.
- **Fix:** In §3.7 write the utility's letter-spacing as `letter-spacing: calc(var(--mm-type-<role>-track) + var(--mm-tracking-legible, 0em))`.

## CONSISTENCY-24

- **Severity:** low
- **Section:** §15.2 (`fonts.ts`) vs §3.1 (Atkinson delivery)
- **Problem:** The two sections contradict each other on whether Atkinson is ever preloaded.
- **Evidence:** §3.1: "never preloaded (the server cannot know the profile's setting)". §15.2: "Atkinson_Hyperlegible_Next (preload only with legible=1)".
- **Fix:** Change §15.2 to "Atkinson_Hyperlegible_Next (`preload: false`; fetched when the boot script stamps `data-legible="on"`, §3.1)".

## CONSISTENCY-25

- **Severity:** low
- **Section:** §2.1.8 (field text and sources table) vs §2.1.6, §8.8, §7.31
- **Problem:** The ambient-field opacities contradict each other.
- **Evidence:**
  - The §2.1.8 prose says "opacity 18 to 28 % per the source", but its table has 30 % (picker) and 10 % (readers).
  - Mood screens: the §2.1.8 table says "Settings, You, admin … mood colour | 20 %", but §2.1.6 gives each mood its own "Blob opacity" (16 % to 30 %).
  - Home: the §2.1.8 table says 26 %, but §8.8 says "its own blurred enlargement (the ambient field turned up to 36 %)".
  - Image viewer: §7.31 says "the ambient field at 40 %", and there is no image-viewer row in §2.1.8.
- **Fix:**
  - Change the prose to "opacity 10 to 40 % per the source (table below)".
  - Change the mood row's opacity to "the mood's own opacity (§2.1.6)".
  - Add rows: "Home hero enlargement | the spotlight's cover palette | 36 %" and "Image viewer | the viewed image's palette | 40 %".

## CONSISTENCY-26

- **Severity:** low
- **Section:** §2.1.1 (`g50` role) vs §8.14.1, §8.14.11, Appendix A
- **Problem:** The desktop reader gutter colour is given three different ways.
- **Evidence:** §2.1.1: "`g50` | `#0B0B0F` | … | Wide-reader side gutters". §8.14.1: "centred on desktop with black gutters". §8.14.11: "the gutters … are `g25` `#060608` wells … Page-tinted chrome off or Reduce Transparency: plain `#000000` gutters". Appendix A: "10 % pools in `g25` wells".
- **Fix:** Change the `g50` role to "Reader background option "Graphite" and page placeholders (§8.14.1)". Add "page-lit gutter wells (§8.14.11)" to the `g25` role. Change §8.14.1 to "centred on desktop with the gutters of §8.14.11".

## CONSISTENCY-27

- **Severity:** low
- **Section:** §10.1 ("Placement (exactly these)") vs §8.1, §8.5, §12.4
- **Problem:** Two screens use the letter reveal but aren't in the exhaustive placement list. The splash wordmark (placement 7) uses a different blur from the reveal's single parameter set.
- **Evidence:** §8.1: "`largeTitle` "Connect your server" (letter reveal)". §8.5: "`largeTitle` "Who's reading?" (letter reveal)". Neither is a tab root, a pushed screen or another listed placement. §10.1: "Blur | 12 px → 0"; §12.4: "letters rise … with the heading reveal (24 ms stagger, k 220 / c 26, blur 16 → 0)".
- **Fix:** Add "8. The Setup title (§8.1) and the profile picker title (§8.5), once per session" to §10.1. Change §12.4 to "blur 12 → 0", or add "(placement 7 starts at 16 px blur)" to the §10.1 Blur row.

## CONSISTENCY-28

- **Severity:** low
- **Section:** §8.6 (avatar pick) vs §4.10 (Cover arc)
- **Problem:** The avatar arc's flight time differs between the two sections, and the motion table points at the wrong screen.
- **Evidence:** §8.6: "a short parabolic arc into the preview: gravity 3,000 px/s², 280 ms, landing with `tick`". §4.10: "**Cover arc** | 420 ms flight, settle 337 ms landing | … | Collection detail "Add series" (§8.18), onboarding avatar pick (§8.6)". §8.6 is the profile form, not onboarding.
- **Fix:** Pick one flight time: add a Cover arc variant "Avatar arc | 280 ms flight, gravity 3,000 px/s², `tick` landing | profile form avatar pick (§8.6)", and change "onboarding avatar pick (§8.6)" to "profile form avatar pick (§8.6)" in the Cover arc row.

## CONSISTENCY-29

- **Severity:** low
- **Section:** §8.25.3 (Reader defaults) vs §8.14.1, §8.14.5
- **Problem:** The Fit options differ between Reader defaults and the reader's own settings.
- **Evidence:** §8.25.3: "Fit (Width · Height · Screen)". §8.14.5: "Fit segmented Width · Height · Original". §8.14.1: "fit width / height / original".
- **Fix:** Change §8.25.3 to "Fit (Width · Height · Original)".

## CONSISTENCY-30

- **Severity:** low
- **Section:** §7.1 (hold-to-confirm uses) vs §8.25.10 (Restore)
- **Problem:** §7.1 says staging a restore uses hold-to-confirm, but §8.25.10 specifies a typed confirmation with a destructive button.
- **Evidence:** §7.1: "It is used for: … staging a backup restore …". §8.25.10: "a field "Type RESTORE to confirm" (case-insensitive) and a destructive "Restore" (enabled once the phrase matches)".
- **Fix:** Remove "staging a backup restore" from the §7.1 list, and add "(the restore uses the typed confirmation of §8.25.10 instead)".

## CONSISTENCY-31

- **Severity:** low
- **Section:** §7.38 (AI timeout) vs §9.1.3 (Leaving during generation)
- **Problem:** A recap request is abandoned at 40 s in one section but kept alive for 60 s in the other.
- **Evidence:** §7.38: "After 40 s the request is abandoned: "That took too long. Try again." … (and for recaps, Continue)". §9.1.3: "closing the sheet while the recap is being written keeps the request alive for up to 60 s".
- **Fix:** Add to §7.38: "Exception: a recap whose sheet was closed stays alive in the background for up to 60 s (§9.1.3); the 40 s limit applies while its sheet is open."

## CONSISTENCY-32

- **Severity:** low
- **Section:** §4.10 (Chapter card rise) vs §8.15.2 (Seamless next)
- **Problem:** The motion table gives the novel's chapter end the manga's zoom, but the novel spec slides the next chapter up on `page`.
- **Evidence:** §4.10: "**Chapter card rise** | … | none, then `zoom` … | Manga chapter end (one at a time), novel end". §8.15.2: "releasing slides the next chapter up in place on `page`".
- **Fix:** Remove "novel end" from Chapter card rise. Add a row "**Novel next** | settle 621 ms | `page` | The Next card locks at 72 displayed px; the next chapter slides up in place | Novel chapter end | 200 ms cross-fade".

## CONSISTENCY-33

- **Severity:** low
- **Section:** §5.2 (`detent.tick`) vs §8.16.3 (speed dial)
- **Problem:** The two sections disagree on how often the speed dial ticks.
- **Evidence:** §5.2: "`detent.tick` | Stepped sliders, steppers, dials, the speed dial and the interval slider, one per step". §8.16.3: "0.5× to 3.0× in 0.05 steps … `detent.tick` ticks every 0.25×".
- **Fix:** Change §5.2 to "…, one per step (the speed dial: one per 0.25×; its 0.05 steps are silent)".

## CONSISTENCY-34

- **Severity:** low
- **Section:** §2.7 (icon motion), §7.13 vs §4.10
- **Problem:** Two animations name different springs in different sections.
- **Evidence:** Reaction landing: §2.7 says "Reactions | Scale 0.6 → 1 on `celebrate`", but §4.10 says "**Reaction bloom and arc** | … land settle 337 ms | `lens` / ballistic / `tick`" and §9.3.2 says "its count ticking up on `tick`". In-page tab indicator: §7.13 says "release projects to the nearest panel and settles on `settle`", but §4.10 says "**Tab droplet** | settle 558 ms | `tab` | … in-page tab indicator".
- **Fix:** Change §2.7 to "Scale 0.6 → 1 on `tick` (the landing of §9.3.2)". Remove "in-page tab indicator" from the Tab droplet row, and add "(the in-page tab indicator follows its pager and settles with it on `settle`, §7.13)".

## CONSISTENCY-35

- **Severity:** low
- **Section:** §7.26 (profile orb sizes and hover) vs §8.5, §8.6, §8.24, §9.3.1, §9.3.5, §9.2.2
- **Problem:** The orb size list is presented as complete, but screens use sizes outside it. The picker hover scale contradicts the orb's hover state. The flame size list misses the milestone toast size.
- **Evidence:** §7.26: "sizes 24 (chips), 32 (sidebar, activity rows), 44 (nav row), 96 (picker), 132 (picker focus)"; "hover (scale 1.04 + specular sweep)". Sizes used elsewhere: §8.5 "orbs (96 phone, 128 desktop)", "hover grows an orb to 1.08"; §8.24 "orb 72"; §9.3.5 "the friend's orb (112 px …)"; §8.6 "6 × 2 orbs of 56 px". §9.2.2 "Sizes: 16 …, 44 …, 96 …, 220" vs "a toast "30 days in a row" with the 20 px flame".
- **Fix:** Change §7.26 sizes to "24, 32, 44, 56 (avatar grid, drop targets, presence arc), 72 (You), 96 (picker phone), 112 (friend sheet), 128 (picker desktop), 132 (picker focus)", and the hover to "scale 1.04 (picker: 1.08, §8.5)". Add "20 (milestone toast)" to the §9.2.2 sizes.

## CONSISTENCY-36

- **Severity:** low
- **Section:** §2.7 (`mm-mark` glyph) vs §12.1, §12.2 (MM column geometry)
- **Problem:** Both geometries describe "the MM column", but their proportions differ. The meniscus bow's unit conversion is also wrong.
- **Evidence:** §2.7: "top M in the box x 72–184, y 32–120; gutter bar x 64–192, y 120–136; bottom M x 72–184, y 136–224" (M height 88 units). §12.1 on the 1024 master: "box x 240–784 … top M y 192–480 … bottom M y 544–832". ÷ 4 this is x 60–196, top M y 48–120, bottom M y 136–208 (M height 72 units). §12.2: "bows 2 px at 64 px cap height, 16 units on the 1024 master". The cap height on the master is 288 units, so 2/64 × 288 = 9 units.
- **Fix:** Make §2.7 `mm-mark` the §12.1 geometry on the 256 grid: M boxes x 60–196, top M y 48–120, bar x 60–196 y 120–136, bottom M y 136–208, strokes 22. Change §12.2 to "9 units on the 1024 master".

## CONSISTENCY-37

- **Severity:** low
- **Section:** §3.2 (role usage notes) vs §7.15, §7.27
- **Problem:** Two type-role usage notes contradict the component specs.
- **Evidence:** §3.2: "`caption2` (micro labels, dock labels when minimised)", but §7.15 says the minimised dock shows "only the active tab's icon". §3.2: "`tabLabel` (dock, sidebar collapsed tooltips)", but §7.27 says "**Tooltip:** `glassThick` capsule, `footnote` `onGlass`".
- **Fix:** Change §3.2 to "`caption2` (micro labels)" and "`tabLabel` (dock labels)".

## CONSISTENCY-38

- **Severity:** low
- **Section:** §8.0.1 (Bare frame) vs §8.3 (Login mobile)
- **Problem:** The two sections give different phone margins for the bare frame.
- **Evidence:** §8.0.1: "content column max 420 (phone full width minus 32)" (16 px margins). §8.3: "the same column full width with 20 px margins".
- **Fix:** Change §8.0.1 to "phone full width minus 40 (20 px margins)".

## CONSISTENCY-39

- **Severity:** low
- **Section:** §4.5 (rubber-band table) vs §8.14.3, §11, §15.4
- **Problem:** The manga zoom limit in §4.5 doesn't match paged mode's 4×.
- **Evidence:** §4.5: "Zoom below 1× and above 3× (manga), below 1× and above 4× (image viewer)". §8.14.3: "paged: `InteractiveViewer` 1× to 4×"; §11: "(strip 1× to 3×; paged 1× to 4×)".
- **Fix:** Change §4.5 to "Zoom below 1× and above 3× (manga strip), below 1× and above 4× (manga paged and the image viewer)".

## CONSISTENCY-40

- **Severity:** low
- **Section:** §8.14.3 (left-edge brightness HUD)
- **Problem:** A 6 px wide capsule can't hold a 22 px sun glyph and a value label, so the size is ambiguous.
- **Evidence:** "Brightness 20 to 100 % … with a 6 × 140 glass HUD capsule (sun glyph and the value)".
- **Fix:** Change to "a 36 × 140 `glassThin` HUD capsule (T2): a 16 px sun glyph at the top, the fill level inside, the value in `caption1` `onGlass` at the bottom".

## CONSISTENCY-41

- **Severity:** low
- **Section:** §8.14.9 (dialogue boxes) vs §2.4.1 rule 1 (content twin)
- **Problem:** The dialogue boxes use a content-twin fill that differs from the defined content twin, and no token exists for it.
- **Evidence:** §2.4.1: content twin fill "`rgba(19,19,23,0.62)` (the `materialRegular` colour with no blur)". §8.14.9: "each box is a content-twin fill (`rgba(19,19,23,0.82)`, …)".
- **Fix:** Add to §2.4.1 rule 1: "Text-bearing twins over art (dialogue boxes) use `twinDense` `rgba(19,19,23,0.82)`". Add `color.twinDense` to §2.8.1: `--mm-color-twin-dense`, `colorTwinDense = Color(0xD1131317)`.

## CONSISTENCY-42

- **Severity:** low
- **Section:** §8.0.3 (sheet id table: "The ids, once each")
- **Problem:** The table lists `save-files` twice and puts Updates' `run` sheet under Downloads.
- **Evidence:** "Series and book | … `save-files` (Save to Files) …" and "Downloads | `save-files`, `run` (update-run detail, §8.21)". §8.21 is Updates.
- **Fix:** Keep `save-files` once (in a "Series, book and Downloads" row), and move `run` to a new "Updates | `run` (update-run detail, §8.21)" row.

## CONSISTENCY-43

- **Severity:** low
- **Section:** §6 (sound table), §9.2.3, §12.4, §15.10 G8 vs §15.6
- **Problem:** Some cues fire from triggers that aren't contract event names, so the event-keyed token maps can't express them. The amendment list also misses one sound-only event.
- **Evidence:**
  - §6: "`shimmer` | `streak.extend`, `streak.milestone`, `goal.met`, the Wrapped summary card". "The Wrapped summary card" is not an event.
  - §9.2.3: "the podium plays `add`, the summary plays `shimmer`" and "1st last, with a `celebrate` land and `success`". There is no podium event, and `add`'s event list has no Wrapped entry.
  - §12.4: "Reduce Motion: … one `light` haptic". `light` is a pattern, not an event.
  - §15.10 G8: "adds … the sound-only `sheet.close`". §15.6 and §6 add both `sheet.open` and `sheet.close`.
- **Fix:** Add three HapticEvent/SoundEvent names to §5.2, §6 and the §15.6 list:
  - `annual.podium` → haptic `success`, sound `add`
  - `annual.summary` → haptic none, sound `shimmer`
  - `logo.reduced` → haptic `light`, sound none

  Replace "the Wrapped summary card" in §6 with `annual.summary`, and change §15.10 G8 to "the sound-only `sheet.open` and `sheet.close`".

## CONSISTENCY-44

- **Severity:** low
- **Section:** §7.1, §7.7, §7.8, §7.17, §7.19, §7.20, §8.15.5 vs §2.1.4, §2.3, §7.10
- **Problem:** Several single component values contradict their defining section.
- **Evidence:**
  - 18+ badge: §7.20 says "`mature` at 22 %", but §2.1.4 says badge fill is "the hex at 18 % over black".
  - Liquid fill: §7.19 says "`iris600` at 60 %" for all users including "hold-to-confirm", but §7.1 says hold fill "`iris600` at 70 %".
  - Progress button: §7.1 says "the fill tracks progress with `snappy`", but §7.19 says liquid fills "follow on `lens`".
  - Icon tile: §7.17 says "leading icon tile (30 × 30, radius 8 …)", but §2.3 says "`rIconTile` | 12 | Icon tiles in settings rows".
  - Focus scale: §7.8 says "focus scale 1.04 + ring", with "**States:** as §7.7 cards", but §7.7 says "**focused** ring + scale 1.03".
  - Medium detent: §8.15.5 says "`medium` sheet (≤ 50 % of the height …)", but §7.10 says "`medium` 52 % of the screen height".
- **Fix:**
  - §7.20: "`mature` at 18 %".
  - §7.1: "`iris600` at 60 %".
  - §7.1: "the fill level follows progress on `lens`".
  - §7.17: "radius `rIconTile` (12)".
  - §7.7: "**focused** ring + scale 1.04 (cards and posters)".
  - §8.15.5: "`medium` sheet (52 %, §7.10)".

## CONSISTENCY-45

- **Severity:** low
- **Section:** §2.8.5 (thresholds and physics) vs §4.6, §4.10, §5, §7.15, §7.16, §8.11, §8.14.3, §9.2.3, §12.4
- **Problem:** Several numeric behaviours are specified only in prose and have no key, although §2.8 claims to list every value and §2.4.1 says nothing is picked by feel. Four compound thresholds emit only their first number. `fantasticon` has no version.
- **Evidence:**
  - Compound thresholds: "`threshold.doubleTapWindow` | 280 ms / 24 px" emits 280 only. "`threshold.imageDismiss` | 180 px or 800 px/s" emits 180. "`threshold.dragSlopTouch` | 10 px (18 px inside Flutter scroll views)" emits 10. "`threshold.stackLongPress` | 450 ms (web touch 500 ms)" emits 450.
  - Prose-only values with no key: dock "after 20 px of cumulative downward scroll … after 12 px of upward scroll"; "impacts to one per 120 ms"; sidebar "auto-collapsing below 1180 px"; "after 400 px of scroll a `glassThin` "Top" capsule".
  - Unnamed springs: "a spring (k 180, c 22)" (§12.4). Physics constants: chapter-swipe rubber band "`c` = 0.35"; gravities 2,400 / 3,000 / 9,000 px/s²; genre field "restitution 0.4", "spring `k = 4`".
  - §15.11: "`fantasticon` (npm) | pinned in the lockfile".
- **Fix:** Add to §2.8.5 (web CSS `--mm-…`, TypeScript constant, Flutter field):
  - Thresholds: `threshold.doubleTapSlop` 24, `threshold.imageDismissVelocity` 800, `threshold.dragSlopTouchScroll` 18, `threshold.stackLongPressWebTouch` 500, `threshold.pullRest` 60, `threshold.dockHide` 20, `threshold.dockShow` 12, `threshold.sidebarCollapse` 1180, `threshold.topCapsule` 400.
  - Physics: `physics.impactMinInterval` 120, `physics.rubberBandChapterC` 0.35, `physics.gravitySplash` 9000, `physics.gravityArc` 3000, `physics.gravityReaction` 2400 (also the Wrapped page pile), `physics.genreRestitution` 0.4, `physics.genreCentreK` 4.
  - Spring: `spring.splashLens` {ms: 468, bounce: 0.18} (k 180.0, c 22.0).

  Give `fantasticon` an exact version in §15.11.
