# Glass DESIGN.md: recheck round 3, lens consistency

Input: the 44 findings in the "Confirmed" section of `glass/verify/judge-consistency.md` (CONSISTENCY-7 was refuted and is not checked), with extra attention on the three items `recheck-consistency-2.md` left unresolved (CONSISTENCY-4, 35, 45) and on `fixed-consistency.md` Round 3.

Target: `glass/DESIGN.md`. The pass started on the 23:58:33 UTC state (817,885 bytes, 4,606 lines). Other lenses' fixers wrote to the file during the pass (`fixed-stack.md` Round 3 at 00:03, `fixed-a11y.md` Round 2 at 00:04), so every check was re-run on a frozen copy of the 00:04:17 UTC state (826,122 bytes, 4,611 lines, sha1 `9d6172dc…`). Line numbers below are from that state. Section numbers are authoritative.

One more write landed while this report was being finished: the 00:11:26 UTC state (827,183 bytes, 4,611 lines, sha1 `11df7073…`, headings unchanged). All automated checks were re-run on it with the same result:

- all 153 fix strings present, and no old values;
- the springs, the §4.10 settles, the 204 Tailwind names and the 99 tables all clean;
- the §15.3 T4 sentence still at line 4239.

Method:

- For each finding, I read the sections the final fix names and compared them with the fix text. A script then asserted 153 exact fix strings (every sentence, row and value the 44 fixes and the round-3 edits write). All 153 are present.
- I grepped for 38 old strings that must be gone, and for the old settle values (203, 297, 337, 429, 485, 528, 494, 399, 621, 591, 444, 497, 411, 445, 723, 1065, 402, 490, 620 and 669 ms). None remain. "Wrapped page pile" survives once, as prose in the `physics.gravityReaction` row, not as a move name.
- I grepped for every other place a changed value is repeated. That includes text the stack and accessibility fixers added after round 2 (§15.3 **Sheets**, §15.8 **T4/T5 bodies**, §8.16.2 **Titles** and the desktop sentence list).
- Springs were recomputed from the closed-form mass-spring solution (mass 1, k and c from §4.2, settle = last time |1 − x| > 0.005 from rest).
- Contrast was recomputed with the WCAG 2.x formula.
- Every §4.10 "settle N ms" was checked against its spring.
- The 204 Tailwind names in §2.8 were resolved through the §2.8 per-namespace rule.
- The file's 99 markdown tables were checked for glued rows and column-count mismatches.

**Result: 43 resolved, 1 unresolved (CONSISTENCY-4).**

All three round-2 items are fixed as asked. CONSISTENCY-4 reopens because of a later edit by another lens. The STACK-6 rewrite of §15.3 **Sheets** says every sheet route's material is `SkinGlass(tier: T4)`. That includes `?sheet=player`, which the CONSISTENCY-4 exception in §7.10 makes T5 at `medium` and `solid2` at `large`. The fix is a one-clause edit.

---

## Round-2 unresolved items

| ID | What round 2 asked for | Now in the file |
|---|---|---|
| 4 | §8.16.2 sentence list: `label2` "6.08:1 on `solid2`" | Line 2845: "others in `label2` (6.08:1 on `solid2`; never dimmed by opacity…)". Recomputed: 6.077:1 on `#26262E`, and 6.572:1 on `solid1`. A11Y-4 Round 2 added the desktop T5 window case in the same bullet ("on the desktop T5 window the inactive sentences are `onGlass` at `wght` 420"), which closes the desktop gap. **The item still reopens, because §15.3 now states a different material for every sheet (below).** |
| 35 | Friend orb bullet 18 / 32 / 56; size list gains 18 and 20 | Line 1954: "sizes 18 (Friend badge, §7.20), 20 (shared-collection adder, §9.3.3), 24 (chips), 32 (sidebar, activity rows), …, 132 (picker focus)". Line 1957: "18 px as the Friend badge (§7.20), 32 px in activity rows (§9.3.1), 56 px as drop targets and in the presence arc". These agree with §7.20 (18 px friend orb), §9.3.1 ("the actor orb 32") and §9.3.3 ("a 20 px orb of who added them"). No "18 px in activity rows" remains. |
| 45 | `lens` use cell no longer claims the splash lens | Line 1053: "Liquid lenses: the scrub magnifier appearing, the splash droplet's impact squash (§12.4), the reaction bloom". §12.4 line 3923 recovers the impact squash on `lens`, and line 3924 grows the lens on `splashLens`. The `splashLens` row (line 1066) and the Droplet reveal row (line 1238) agree. No "the splash lens, the reaction bloom" remains. |

---

## Recomputed values

| Spring | k (doc / from ms, bounce) | c (doc / from ms, bounce) | Settle, closed form (ms) | Doc (ms) | Overshoot, closed form | Doc |
|---|---|---|---|---|---|---|
| `track` | 1754.6 / 1754.6 | 72.05 / 72.05 | 148.9 | 149 | 0.50 % | 0.5 % |
| `press` | 815.7 / 815.7 | 45.70 / 45.70 | 252.7 | 253 | 1.52 % | 1.5 % |
| `tick` | 584.0 / 584.0 | 33.83 / 33.83 | 289.2 | 289 | 4.60 % | 4.6 % |
| `snappy` | 246.7 / 246.7 | 26.70 / 26.70 | 430.9 | 431 | 0.63 % | 0.6 % |
| `morph` | 273.4 / 273.4 | 24.80 / 24.80 | 434.5 | 434 | 2.84 % | 2.8 % |
| `tab` | 195.0 / 195.0 | 21.78 / 21.78 | 518.0 | 518 | 2.00 % | 2.0 % |
| `lens` | 223.8 / 223.8 | 20.94 / 20.94 | 467.2 | 467 | 4.60 % | 4.6 % |
| `sheet` | 171.3 / 171.3 | 24.09 / 24.09 | 447.5 (exact k, c) to 448.0 (rounded) | 447 | 0.062 % | 0.06 % |
| `sheetSnap` | 223.8 / 223.8 | 26.33 / 26.33 | 342.1 | 342 | 0.30 % | 0.3 % |
| `page` | 146.0 / 146.0 | 24.17 / 24.17 | 615.2 | 615 | 0 | 0 % |
| `zoom` | 125.9 / 125.9 | 21.09 / 21.09 | 557.4 | 558 | 0.018 % | 0 % |
| `settle` | 322.3 / 322.3 | 35.90 / 35.90 | 413.7 | 414 | 0 | 0 % |
| `minimize` | 246.7 / 246.7 | 31.42 / 31.42 | 473.3 | 473 | 0 | 0 % |
| `dismiss` | 385.5 / 385.5 | 39.27 / 39.27 | 378.4 | 378 | 0 | 0 % |
| `camera` | 195.0 / 195.0 | 25.13 / 25.13 | 391.7 | 392 | 0.154 % | 0.15 % |
| `celebrate` | 109.7 / 109.7 | 13.61 / 13.61 | 642.3 | 643 | 6.82 % | 6.8 % |
| `drift` | 48.7 / 48.7 | 13.96 / 13.96 | 1064.7 (ζ = 1) to 1065.2 (rounded) | 1064 | 0 | 0 % |
| `letter` | 219.6 / 219.6 | 26.08 / 26.08 | 345.2 | 345 | 0.30 % | 0.3 % |
| `smooth` | 157.9 / 157.9 | 22.62 / 22.62 | 435.6 | 436 | 0.152 % | 0.15 % |
| `splashLens` | 180.0 / 180.2 | 22.00 / 22.02 | 532.4 | 532 | 1.11 % | 1.1 % |

- Every settle and overshoot is within 1 ms and 0.05 points of the judge's table. The only differences are the judge's own rounding (`sheet`, `zoom`, `drift`, `splashLens`).
- The 20 `--mm-spring-*-ms` properties in §2.8.5 carry the same settles. `--mm-spring-page-ms: 615ms` appears twice, in §2.8.5 and in the §15.1 CSS example.
- The derived values hold: §4.8 "(431 ms) … within 671 ms", §10.2 "settles in 289 ms", §8.0.5 `transitionDuration` 615 ms and Skin melt 615 ms.
- Every "settle N ms" in the 116 rows of §4.10 matches the settle of a spring named in that row, with zero mismatches.
- The new §15.3 **Sheets** text uses 447 ms (`sheet`), 378 ms (`dismiss`), 342 ms (`sheetSnap`) and `springSheetSnap` k 223.8 / c 26.33. All four agree with §4.2 and with CONSISTENCY-5 (present by button on `sheet`, dismiss by button on `dismiss`).
- Splash fall: 180 px at 9,000 px/s² takes 200 ms and lands at 1,800 px/s, as §12.4 states.

**Other numbers:**

- **Contrast.** `#7262DD` against white is 4.66:1, and `onTint` reads "4.66 over a white page". The document's other rounded values (15.1:1, `Color(0x4D787880)`) were not recomputed this round; round 2 recomputed them. §7.23's "4.61:1" is a different pair (a `danger` glyph on its disc), not `onTint`.
- **Dispersion.** T4 displaces 18 px: 18 × 0.033 = 0.59 and 18 × 0.067 = 1.21, giving 0.6 / 1.2 px. T5 displaces 22 px: 22 × 0.055 = 1.21 and 22 × 0.109 = 2.40, giving 1.2 / 2.4 px.
- **MM mark.** Dividing the §12.1 master by 4 gives x 60–196, y 48–120, 120–136 and 136–208, and a stroke of 22. The bow is 2 / 64 × 288 = 9 units.
- **Poster counts** are unchanged from round 2: 2.8 / 4.8 / 5.4 / 6.9, and 3.9 to 5.4 on tablet.

---

## Per finding

| ID | Status | Evidence (line numbers from the 00:04:17 state) |
|---|---|---|
| 1 | Resolved | Rule 7 (line 404) and its four sub-bullets match the fix word for word. Rule 8 reads "a sheet or alert may carry its own lit action, drawn as the tinted twin (rule 7)". Every site is converted: the §7.10 close button, §7.11 alert buttons, §7.15 / §8.16.1 play/pause, §7.35, §8.15.5, all five §8.16.2 items plus the header ⋯, §9.4.2, and §9.2.3 Export and the pause/play, previous/next and close buttons. The §7.21 Fill slider is converted too. §15.7 counts the sheet as 1 and Takeovers as 2 / 2. No "Anything drawn on glass uses fills" remains. |
| 2 | Resolved | §2.4.1 Medium row: "cards and posters (content, no glass)", with the Content sink press cell (0.97 / 0.99). Heavy row: "the hero card (content, no glass; the class sets its springs only)". |
| 3 | Resolved | The Medium row carries the fix's button text. The "`glassFilm` clear" row in §2.4.2 matches cell for cell. The name is used in §7.5, §7.6 (twice), §7.13, §7.15, §7.16, §7.21, §7.22 and §7.28, and in the §2.8 short-name bullet (→ `glass.t1` + `glass.clear`). `glassClear` remains only for the hero, the band and the image viewer. §7.12 reads "`glassThin` capsule (T2)". No "`glassThin` clear" remains. |
| 4 | **Unresolved** | The §2.4.3 fixed-lens paragraph, the §2.4.1 Light and Feather rows, the §7.27 tooltip and the §7.10 exception are in place. So are the §8.16.2 Titles (T5 at `medium`) and the sentence list (6.08:1 on `solid2`). §15.8 **T4/T5 bodies** asserts `onGlass` on T5 "(the full player's titles at `medium`, 8.36:1)". **§15.3 *Driven values* (line 4239) contradicts the exception** (below). |
| 5 | Resolved | §4.2 `sheet`: "Sheet present by button (dismissal by button uses `dismiss`, law 10)". The new §15.3 *Present* and *Button dismiss* sub-bullets use `springSheet` 447 ms and `springDismiss` 378 ms, which agree. |
| 6 | Resolved | The four §4.6 rows cite `threshold.cross` / `threshold.back` `rigidBack`, the velocity-scaled `throw.commit` (written `abs(v)` because a pipe cannot sit in a table cell) and `magnet.capture` / `magnet.drop` / `detent.magnet`. §5.1 and §5.2 agree. |
| 8 | Resolved | §4.7: "150 ms (in-page and sheets) / 200 ms (routes) linear". §8.0.4 lists the Tab switch and Sheet routes exceptions. §2.8.5 has `curve.reducedCrossfade` 150 and `curve.reducedRoute` 200. |
| 9 | Resolved | All 16 rows are in §4.10 (lines 1283–1298) with the judge's durations, springs, specs, uses and Reduce Motion values. §4.11 uses "Flame flicker", "Podium drop" and "Page pile". |
| 10 | Resolved | See the recomputed values above. |
| 11 | Resolved | No `.on-glass` rule and no `"opsz" auto` remain. §3.5 has the fix sentence. §3.7 has `"wght" calc(var(--mm-type-<role>-wght) + var(--press-wght, 0))` and "The press animation drives `--press-wght` from 0 to 40". |
| 12 | Resolved | §2.8.3 `border.slab` declares `--mm-border-slab-color: rgba(255,255,255,0.06)`, and its Tailwind cell uses it. Flutter is unchanged. |
| 13 | Resolved | §2.8.4 has the `dim.edgePlateau`, `dim.edgeFade` and `glass.snap` rows, followed by the `spring.format` note after the table. The short-name bullet maps `edgeSoft`, and §15.1 `glass.json` carries `snap`, `edgePlateau` and `edgeFade`. |
| 14 | Resolved | §2.4.3 has the tier-A/B sentence. §2.6 `rim` ends at `S × 0.55`. §2.8.4 has `-rim` 0.26 / 0.22 / 0.20 / 0.16 / 0.14 and `rim: Color(0x42 / 0x38 / 0x33 / 0x29 / 0x24FFFFFF)`. Rule 1 reads "the rim of the tier it replaces (0.5 px)". |
| 15 | Resolved | The §2.8 per-namespace rule is word for word. All 204 Tailwind names resolve, and `--spacing-reader-strip-max` (`w-reader-strip-max`) is in place. |
| 16 | Resolved | §7.9 "(2.8 posters visible at 390 px wide)". §7.8 and §8.8 read "4.8 … 5.4 … 6.9". §8.8 tablet reads "3.9 (768 px) to 5.4 (1023 px)". |
| 17 | Resolved | The §2.1.1 `g600` role and §14.2 "`g600` is non-text only" are in place. Every other `g600` use (§7.7, §7.17, §7.22, §7.29, §8.5, §8.26) is a glyph, border, ring or tint. |
| 18 | Resolved | §7.34 "`Delete` remove with undo". §8.13 "no bare `g`". `x` is select everywhere; the onboarding genre field's local `x` applies only inside that widget. |
| 19 | Resolved | §15.2 `GlassSurface.tsx`: tier C is Reduce Transparency and Solid glass, and Increase Contrast is a modifier on A and B. §2.8.4 has the `-hc` pair and `dimMinHc` / `dimMaxHc`. §4.11 agrees (0.40 / 0.72). |
| 20 | Resolved | "4.66 over a white page", "15.1:1", `Color(0x4D787880)`. No `0x4C…` alpha remains. |
| 21 | Resolved | k 219.6 / c 26.08 in §10.1 and §12.4. The generated `spring.letter` is used. `--stagger` is set on the heading (40ms / 24ms), letter delays use `calc(var(--i) * var(--stagger))`, and the glint delay matches the fix. No `glassSpring` or "stiffness: 220," remains. |
| 22 | Resolved | §2.4.3 Web mapping: × 1.000 / 1.033 / 1.067 (T4) and × 1.000 / 1.055 / 1.109 (T5). |
| 23 | Resolved | §3.7 `letter-spacing: calc(var(--mm-type-<role>-track) + var(--mm-tracking-legible, 0em))` and the `em`-unit sentence. §3.6 sets `--mm-tracking-legible: 0.01em`. |
| 24 | Resolved | §15.2 `fonts.ts`: Atkinson `preload: false`, fetched on `data-legible="on"`. This matches §3.1 "never preloaded". |
| 25 | Resolved | The prose reads "10 to 40 %". The mood row uses its own opacity (§2.1.6 values are 16 to 30 %). The brand aurora is 20 %. The two new rows (36 % and 40 %) match §8.8 and §7.31. |
| 26 | Resolved | `g50` is Graphite and page placeholders, `g25` adds page-lit gutter wells, and §8.14.1 reads "with the gutters of §8.14.11". |
| 27 | Resolved | §10.1 placement 8 is present. §12.4 reads "blur 12 → 0", matching `blur.reveal` 12. No "blur 16" remains. |
| 28 | Resolved | The Avatar arc row matches word for word. The Cover arc row names only collection detail. §8.6 says 280 ms. |
| 29 | Resolved | §8.25.3 "Fit (Width · Height · Original)". |
| 30 | Resolved | §7.1 no longer lists the restore, and it cites the §8.25.10 typed confirmation. |
| 31 | Resolved | §7.38 has the 60 s closed-sheet exception, and §9.1.3 agrees. |
| 32 | Resolved | The Chapter card rise row reads "Manga chapter end". The Novel next row matches word for word. No "novel end" remains. |
| 33 | Resolved | §5.2 `detent.tick` "(the speed dial: one per 0.25×; its 0.05 steps are silent)". §8.16.3 agrees. |
| 34 | Resolved | §2.7 Reactions row on `tick`. The Tab droplet row's use cell carries the in-page indicator note, and §7.13 settles on `settle`. |
| 35 | Resolved | See the round-2 table. The §7.26 hover reads "scale 1.04 (picker: 1.08, §8.5)", and §9.2.2 has "20 (milestone toast)". |
| 36 | Resolved | §2.7 `mm-mark` is the §12.1 master ÷ 4. §12.2 reads "9 units on the 1024 master". No "16 units" remains. |
| 37 | Resolved | §3.2 `caption2` (micro labels) and `tabLabel` (dock labels). |
| 38 | Resolved | §8.0.1 Bare and §8.3 cite the §2.2 margins (16 px up to 413 px, 20 px from 414 px). |
| 39 | Resolved | §4.5 gives 3× for the strip and 4× for paged mode and the image viewer. §7.31, §8.14.3, §11 and §15.4 agree. |
| 40 | Resolved | §8.14.3 has the 36 × 140 `glassThin` HUD capsule (T2), the 16 px sun glyph and the `caption1` value. |
| 41 | Resolved | Rule 1's `twinDense` sentence, the §2.8.1 `color.twinDense` row (`Color(0xD1131317)`) and §8.14.9 agree. |
| 42 | Resolved | §8.0.3 has one "Series, book and Downloads \| `save-files`" row and an "Updates \| `run`" row. `save-files` appears twice in the file: once in that table and once in the §7.10 id list. |
| 43 | Resolved | §5.2 has `annual.podium`, `annual.summary` and `logo.reduced`. The §6 `add` / `shimmer` rows, §9.2.3, §12.4 and the §15.6 list use them. §15.10 G8 names "the sound-only `sheet.open` and `sheet.close`". |
| 44 | Resolved | §7.20 `mature` at 18 %. §7.1 hold fill `iris600` at 60 %, progress on `lens`. §7.17 `rIconTile` 12. §7.7 focus "ring + scale 1.04 (the same keyboard focus scale as posters)". §8.15.5 `medium` sheet (52 %). |
| 45 | Resolved | All nine threshold rows, eight physics rows and `spring.splashLens` are in §2.8.5, and `splashLens` is in §4.2. The `lens` row is fixed (above). `fantasticon` stays as STACK-22 set it (4.1.0, "reused"). `cinematic/DESIGN.md` §15.11 now pins the same 4.1.0, so "reused" is correct and the judge's "3.0.0, added here" must not be re-applied. |

---

## Unresolved, with the edit it needs

### CONSISTENCY-4: §15.3 gives every sheet route T4, including the listen full player

The fix's §7.10 exception (line 1724) reads: "the listen full player sheet (§8.16.2) is `glassMonolith` (T5) at `medium` and cross-fades to `solid2` at `large`". The full player is a sheet route, `?sheet=player` (§8.0.3 Readers row, line 2212; Appendix B line 4561). The route and the material are repeated in several places:

- §2.4.1 Massive row: T5. Agrees.
- §2.4.2 `glassMonolith` row: agrees.
- §3.5: the player's title is ROND 100 (T5). Agrees.
- §8.16.2 Titles: "the player is T5 glass at `medium`". Agrees.
- §15.8 T4/T5 bodies: T5 at `medium`, 8.36:1. Agrees.
- **§15.3 Sheets, *Driven values* (line 4239): "The material is `SkinGlass(tier: T4)` inside the sheet".** The *Route* sub-bullet (line 4232) applies it to "every `?sheet=` id". A Flutter implementer following §15.3 would build the player sheet at T4, which contradicts §7.10, §8.16.2 and the §15.8 contrast case.

This sentence came in with STACK-6 (Round 1, rewritten in Round 3), after the CONSISTENCY-4 fix. Round 2 did not catch it.

Edits:

1. **Required.** In §15.3 **Sheets** *Driven values*, write: "The material is `SkinGlass(tier: T4)` inside the sheet, cross-fading to `solid1` at `large`; the `player` sheet is `SkinGlass(tier: T5)` at `medium` and cross-fades to `solid2` at `large` (§7.10 **Geometry**)."
2. **Optional**, for the same scope. In the §2.4.2 `solid2` row, write "(large solid surfaces under Reduce Transparency; the listen full player at `large`, §7.10)". Today the token's own description does not cover the one use the exception adds.

---

## Observations outside the confirmed fixes (not counted)

**New this round.** These come from other lenses' later edits, or from repeats this pass read more closely.

- **§15.3 Sheets vs the full player's entrance and detents.**
  - *Present* opens every sheet route with `animateTo(<opening detent>, 447 ms, springSheet)`. The full player instead grows out of the accessory capsule on `morph` (§7.15 Now narrating, §8.16.2 opening line).
  - *Detents and snapping* snaps every sheet to the nearest of peek 96 px, medium or large. §7.10 says `peek` exists "only for the listen mini player expansion" and that "Detents a given sheet uses are listed per screen".
  - Both should name the `player` exception, or read the detent set per sheet.
- **Cover-overlay and backing-disc fills have no token.** A11Y-3 and A11Y-18 introduced three raw fills:
  - `rgba(0,0,0,0.86)`: the cover-overlay backing and track (§7.7 History tile, §7.8 Overlays, §7.20, §8.17, rule 1). It appears 6 times.
  - `rgba(0,0,0,0.72)`: the droplet, star and `age-gate` discs. It appears 5 times.
  - `rgba(0,0,0,0.60)`: the §2.1.2 backing disc.

  None of them has a §2.8.1 row. §2.8 says a Glass screen uses only the names in the table, and `lint-utilities.mjs` fails on anything else. This is the same gap CONSISTENCY-41 closed for 0.82 with `color.twinDense`. Suggested rows: `color.coverBacking` 0.86 (`Color(0xDB000000)`), `color.coverDisc` 0.72 (`Color(0xB8000000)`) and `color.backingDisc` 0.60 (`Color(0x99000000)`).
- **Lenses outside the §2.4.3 fixed-size list.** The splash lens (128 px) is declared T5 in the §2.4.1 Massive row and the §2.4.2 `glassMonolith` row, but by the size snap 128 px is T4. The Setup `mm-mark` lens (72 px, §8.1) and the Login lens (56 px, §8.3) declare no tier at all. Adding "T5 Monolith: the splash lens (§12.4)" and a tier for the two auth lenses to the §2.4.3 list would close the same class of gap CONSISTENCY-4 closed.
- **§7.19 Linear progress** says "a large jump overshoots nothing" on `snappy`, but §4.2 gives `snappy` a 0.6 % overshoot. Suggested wording: "overshoots 0.6 %; settles in 0.4 s".
- **§10.1 per-word mode on Flutter.** The web sketch switches to per-word reveal above 60 graphemes (`perWord`, 40 ms). The Flutter `_LetterRun` always staggers `24 * i` per grapheme. The Limit row applies to both clients.
- **§10.1 placement 8 and the reveal key.** The Setup title and the picker title show before any profile is active, yet the once-per-session key is `"{profileId}:{screenId}:{headingKey}"`. The key needs a no-profile form, for example `"-:{screenId}:{headingKey}"`.
- **Orb use labels in §7.26.** Every size used anywhere is now listed, but some use labels are incomplete:
  - 44 px is also the Manage profiles row orb (§8.6) and the collapsed sidebar's profile orb (§7.16).
  - 56 px is also the collapsed sidebar's accessory orb (§7.16).

**Carried over from round 2, still open:**

- The phone series-detail sheet (§8.12) never states its material. If it is a glass sheet, its "trailing glass group" and its rule-2 glass secondary buttons are glass on glass under rule 7.
- §8.15.2: the "Listen · 14 min" capsule is `glassThin` inside the novel column, which rule 1 forbids. It should be the `glassThin` content twin.
- Rule 7 fixes the twin rim at 0.22, while rule 1 and §2.4.3 give twins "the rim of the tier it replaces". The two disagree only for twins of a non-T2 variant, such as the 72 px §8.16.2 tiles if they are T3. One clause in rule 7 would settle it, for example "0.5 px rim of the variant's tier (0.22 for T2)".
- §9.2.4: the share side's `glassThick` strip sits inside Wrapped's `glassMonolith` frame. Rule 7's bloom exception does not cover it.
- The exhaustive motion table still misses a few moves that predate the fix:
  - the indeterminate linear band, "a 30 % band sweeping a linear track every 1.2 s" (§7.19, line 1863);
  - the picker orb's `celebrate` hop after a profile save (§8.6, line 2473);
  - the switch knob travel (§7.22).
- Cosmetic: the unmatched ")" after "no backdrop read" in §8.14.9 (line 2701).
