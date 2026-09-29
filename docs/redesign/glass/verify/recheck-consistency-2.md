# Glass DESIGN.md: recheck round 2, lens consistency

Input: the 44 findings in the "Confirmed" section of `glass/verify/judge-consistency.md` (CONSISTENCY-7 was refuted and is not checked), and the six items `recheck-consistency-1.md` left unresolved (CONSISTENCY-1, 3, 10, 13, 25, 34).

Target: `glass/DESIGN.md`. The pass started on the 23:45:57 UTC state (815,811 bytes, 4,603 lines). Other lenses' fixers wrote to the file during the pass, so every check was re-run against the 23:52:18 UTC state (817,745 bytes, 4,606 lines, sha1 `589d3f9d…`). The edits between the two states touch the manifesto and §4.1 law 5 (catchable objects), the §2.8 runtime-values sentence, §5.2 `motion.catch`, §5.3 `swell`, the §7.10 desktop-form table (`offer`), §8.0.7 iOS haptics, the §8.22 Save to Files copy, §9.3.7 and the §11 tap-band rows. None of them changes a consistency verdict. Line numbers below are from the 23:52:18 state. Section numbers are authoritative.

Method: for each finding, I read the sections the final fix names and compared them with the fix text. Then I grepped the whole file for every old value that should be gone, and for every other place the changed value or rule is repeated. This round also covered repeats of values that other lenses changed after round 1. Spring settle and overshoot were recomputed from the closed-form mass-spring solution (mass 1, k and c from §2.8.5, settle = last time |1 − x| > 0.005 from rest). Contrast was recomputed with the WCAG 2.x luminance formula. Every markdown table in the file was checked for rows glued to a preceding paragraph and for column-count mismatches, and none were found. Every Tailwind name in the §2.8 tables (204 of them) was resolved through the §2.8 per-namespace rule, and each one resolves to a declared `--mm-` property.

**Result: 41 resolved, 3 unresolved** (CONSISTENCY-4, 35, 45).

- All six round-1 items are now resolved.
- CONSISTENCY-4: its own fix introduced a contradiction. The listen full player is `solid2` at `large`, but the sentence list, which only shows at `large`, still quotes its contrast on `solid1`.
- CONSISTENCY-35: §7.26 now lists activity-row orbs at 32, while the Friend orb bullet in the same section still says 18.
- CONSISTENCY-45: the new `splashLens` spring owns the splash lens, but the `lens` row still claims it.

Each needs a one-cell or one-line edit.

---

## Round-1 unresolved items: now resolved

| ID | What round 1 asked for | Now in the file |
|---|---|---|
| 1 | Header ⋯, the Fill slider and the Wrapped close button as twins; the §15.7 Takeovers row recounted | §8.16.2 line 2838: "a trailing `fill2` twin circle 32 (44 hit, §2.4.2 rule 7, the recipe of the §7.10 close button)". §7.21 line 1887: "a tall 72 × 160 capsule drawn as the `fill2` twin (§2.4.2 rule 7; it always sits on a glass host…)". §9.2.3 line 3349: "beside the close button (also a `fill2` twin, on the frame)". §15.7 line 4371: "Wrapped: the frame (`glassMonolith`) 1, a card's lens 1 (its close button is a `fill2` twin on the frame, §9.2.3) = **2** \| 2 / 2". |
| 3 | §7.6 vertical droplet; a key for "`glassFilm` clear" and one blur value | §7.6 line 1679: "the `glassFilm` clear droplet indicator". §2.4.2 row (line 377) now has blur **1**. The §2.8 short-name bullet (line 532) maps "`glassFilm` clear" → `glass.t1` + `glass.clear`, whose blur is 1 (line 770). The only remaining "`glassThin` droplet" is the pull-to-refresh droplet (§7.33), which is not a selection droplet and not in the fix's list. |
| 10 | Skin melt 620 → 615 ms in two places | §4.10 Skin melt (line 1237): "615 ms (the three parts run together; the `page` settle ends it)". §8.25.2 step 3 (line 3016): "the 'melt', 615 ms". No "620 ms" remains. |
| 13 | The `spring.format` note broke the §2.8.4 table | The `caustic` row (line 782) now follows the `glass.snap` row. The note (line 784) sits after a blank line, below the table. |
| 25 | The brand aurora had no opacity | §2.1.8 row (line 220): "the mood's own opacity (§2.1.6); the brand aurora (auth, setup, onboarding) 20 %". |
| 34 | `celebrate` still claimed "reaction sent" | §4.2 `celebrate` (line 1062): "Added to library, streak +1, goal met, the podium #1 landing". The §4.10 Podium drop row lands #1 on `celebrate`. Every reaction move is on `lens` / ballistic / `tick` (§2.7, §4.10, §9.3.2). |

---

## Recomputed values

| Spring | k | c | Settle, closed form (ms) | Document (ms) | Overshoot, closed form | Document |
|---|---|---|---|---|---|---|
| `track` | 1754.6 | 72.05 | 148.9 | 149 | 0.50 % | 0.5 % |
| `press` | 815.7 | 45.70 | 252.7 | 253 | 1.52 % | 1.5 % |
| `tick` | 584.0 | 33.83 | 289.2 | 289 | 4.60 % | 4.6 % |
| `snappy` | 246.7 | 26.70 | 430.9 | 431 | 0.63 % | 0.6 % |
| `morph` | 273.4 | 24.80 | 434.5 | 434 | 2.84 % | 2.8 % |
| `tab` | 195.0 | 21.78 | 518.0 | 518 | 2.00 % | 2.0 % |
| `lens` | 223.8 | 20.94 | 467.2 | 467 | 4.60 % | 4.6 % |
| `sheet` | 171.3 | 24.09 | 448.0 | 447 | 0.062 % | 0.06 % |
| `sheetSnap` | 223.8 | 26.33 | 342.1 | 342 | 0.30 % | 0.3 % |
| `page` | 146.0 | 24.17 | 615.2 | 615 | 0 | 0 % |
| `zoom` | 125.9 | 21.09 | 557.4 | 558 | 0.018 % | 0 % |
| `settle` | 322.3 | 35.90 | 413.7 | 414 | 0 | 0 % |
| `minimize` | 246.7 | 31.42 | 473.3 | 473 | 0 | 0 % |
| `dismiss` | 385.5 | 39.27 | 378.5 | 378 | 0 | 0 % |
| `camera` | 195.0 | 25.13 | 391.7 | 392 | 0.154 % | 0.15 % |
| `celebrate` | 109.7 | 13.61 | 642.3 | 643 | 6.82 % | 6.8 % |
| `drift` | 48.7 | 13.96 | 1064.7 (ζ = 1 exactly) to 1065.3 (ζ = 1.0002 as rounded) | 1064 | 0 | 0 % |
| `letter` | 219.6 | 26.08 | 345.3 | 345 | 0.30 % | 0.3 % |
| `smooth` | 157.9 | 22.62 | 435.6 | 436 | 0.152 % | 0.15 % |
| `splashLens` | 180.0 | 22.0 | 532.4 | 532 | 1.11 % | 1.1 % |

The document matches the judge's table exactly. The only differences from the closed form are the judge's own rounding (`sheet`, `zoom`, `drift`), all within 1 ms.

The derived values were also checked:

- §4.8: "(431 ms) … within 671 ms".
- §10.2: "settles in 289 ms".
- §10.1 glint delay: `calc(var(--n) * var(--stagger) + var(--mm-spring-letter-ms) + 120ms)`.
- §15.1: `--mm-spring-page-ms: 615ms`.
- §8.0.5: `transitionDuration` 615 ms.
- Skin melt: 615 ms.
- §7.19 Linear progress: "settles in 0.4 s". That is the `snappy` settle of 431 ms rounded to one decimal, so it still holds.

Contrast: `label2` (`rgba(235,235,245,0.64)`) measures 6.57:1 on `solid1` `#1C1C22` and **6.08:1 on `solid2` `#26262E`**. Both are recomputed without rounding the composite (see CONSISTENCY-4).

Poster counts use the §7.8 content-width rule:

| Width | Calculation | Posters |
|---|---|---|
| Phone | (374 + 12) / 136 | 2.84 |
| 1024 px | (860 + 16) / 184 | 4.76 |
| 1440 px | (1056 + 16) / 200 | 5.36 |
| 1920 px | (1360 + 16) / 200 | 6.88 |

The document's 2.8, 4.8, 5.4 and 6.9 match.

## Old values that must be gone (latest-file counts)

| Old value | Count |
|---|---|
| Old settle values with "ms" (203, 297, 337, 429, 485, 528, 494, 399, 621, 591, 444, 497, 411, 445, 723, 1065, 402, 490) and the derived 620 / 669 | 0. Every "558 ms" left is `zoom`'s new settle, not `tab`'s old one; every "620" left is a `wght` or a coordinate. |
| "Anything drawn on glass uses fills" | 0 |
| "content: scale 1.04" | 0 |
| "`glassThin` clear" | 0 |
| "Sheet present and dismiss by button" | 0 |
| "podium drop in Wrapped", "flame flicker" (lower case) | 0 / 0. "Wrapped page pile" survives once as prose in the `physics.gravityReaction` row, which is not a move name. |
| `.on-glass {`, `"opsz" auto` | 0 / 0 |
| `var(--mm-X)` (old Tailwind rule), bare `--spacing-reader-strip` | 0 / 0 |
| `g600` "meta text … 15 px" | 0 |
| "`x`/`Delete`", "plus `g` go to chapter" | 0 / 0 |
| "4.61 over" (onTint), "15.2:1", `0x4C787880` | 0 / 0 / 0 |
| `glassSpring.letter`, `stiffness: 220,` | 0 / 0. The one "k 220" left is `GlassModalSheet`'s hard-coded spring in §15.3, which is not ours. |
| "18 to 28" (field opacity), "wide-reader side gutters" | 0 / 0 |
| "blur 16" (§12.4), "16 units" (§12.2) | 0 / 0 |
| "onboarding avatar pick", "Height · Screen" | 0 / 0 |
| "staging a backup restore", "novel end" | 0 / 0 |
| "dock labels when minimised", "sidebar collapsed tooltips" | 0 / 0 |
| "≤ 50 %" (Aa sheet), `mature` at 22 % | 0 / 0 |
| "a spring (k 180, c 22)" | 0 |
| "reaction sent" | 0 |

---

## Per finding

| ID | Status | Evidence |
|---|---|---|
| 1 | Resolved | Rule 7 (line 404) and rule 8 read as the fix says. Every site the fix enumerated is converted, and so are the three round-1 sites (table above). The §15.7 phone row (sheet 1) and the Takeovers row (2 / 2) are consistent with rule 7. |
| 2 | Resolved | §2.4.1 Medium row: "cards and posters (content, no glass)" with the Content sink press cell. Heavy row: "the hero card (content, no glass; the class sets its springs only)". §7.7 pressed state sinks to 0.97. |
| 3 | Resolved | See the round-1 table. §2.4.1 Medium row has the fix's button text. The "`glassFilm` clear" row is present, and the name is used at §7.5, §7.6 (drag and vertical), §7.13, §7.15, §7.16, §7.21, §7.22 and §7.28. `glassClear` is left only for the hero, band and image viewer. §7.12 reads "`glassThin` capsule (T2)". |
| 4 | **Unresolved** | The §2.4.3 fixed-lens paragraph, the §2.4.1 Light and Feather rows, the §7.27 tooltip (`glassThin` T2, min height 36, padding 9 12) and the §7.10 exception (line 1724: the listen full player is `glassMonolith` at `medium`, `solid2` at `large`) are all in place. The exception left one stale repeat (below). |
| 5 | Resolved | §4.2 `sheet`: "Sheet present by button (dismissal by button uses `dismiss`, law 10)". §7.10 Physics agrees. |
| 6 | Resolved | The §4.6 rows cite `threshold.cross` / `threshold.back` `rigidBack`, the velocity-scaled `throw.commit` and `magnet.capture` / `magnet.drop` / `detent.magnet`. The §5.1 `rigidBack` and the §5.2 rows agree. |
| 8 | Resolved | §4.7 `reducedCrossfade`: "150 ms (in-page and sheets) / 200 ms (routes) linear". §8.0.4 has the Tab switch and Sheet routes exceptions. §2.8.5 `curve.reducedCrossfade` 150 and `curve.reducedRoute` 200, §4.10 and §4.11 agree. |
| 9 | Resolved | All 16 rows are in §4.10 with the judge's values. §4.11 uses "Flame flicker", "Podium drop" and "Page pile". The source sections agree (§7.19 spinner and dots, §7.20, §7.29, §8.5, §8.8, §8.11, §7.39, §8.14.3, §9.2.2, §9.2.3). |
| 10 | Resolved | All settle values, `-ms` properties, overshoots and dependants (above). |
| 11 | Resolved | No `.on-glass` rule. §3.5 carries the fix sentence. §3.7 has `"wght" calc(var(--mm-type-<role>-wght) + var(--press-wght, 0))`, with `--press-wght` driven from 0 to 40. |
| 12 | Resolved | §2.8.3 `border.slab` declares `--mm-border-slab-color: rgba(255,255,255,0.06)`. Flutter is unchanged. |
| 13 | Resolved | §2.8.4 has the `dim.edgePlateau`, `dim.edgeFade` and `glass.snap` rows, the table is intact, and the `spring.format` note follows it. The short-name bullet maps `edgeSoft`, and the §15.1 `glass.json` carries the keys. |
| 14 | Resolved | The §2.4.3 rim bullet has the tier-A/B sentence. §2.6 `rim` ends at `S × 0.55`. `glass.t1`–`t5` carry `-rim` 0.26 / 0.22 / 0.20 / 0.16 / 0.14 and `rim: Color(0x42 / 0x38 / 0x33 / 0x29 / 0x24FFFFFF)`. §2.4.1 rule 1 reads "the rim of the tier it replaces (0.5 px)". §15.1 `t2` / `t4` have `rim`. |
| 15 | Resolved | The §2.8 per-namespace Tailwind rule is in place, and all 204 Tailwind names resolve to declared `--mm-` properties. `--spacing-reader-strip-max` (`w-reader-strip-max`). |
| 16 | Resolved | §7.9 "(2.8 posters visible at 390 px wide)". §7.8 and §8.8 desktop: "4.8 at 1024 px, 5.4 at 1440 px and 6.9 at 1920 px". §8.8 tablet: "3.9 (768 px) to 5.4 (1023 px)". |
| 17 | Resolved | §2.1.1 `g600` "Non-text only … never text", hex `#76767F` kept. §14.2: "`g600` is non-text only". Every `g600` use is a glyph, border, ring or tint. |
| 18 | Resolved | §7.34 "`Delete` remove with undo". §8.13 "no bare `g`". `x` means select in every list. The onboarding genre field's local "`x` sets −1" is older and applies only inside that focused widget. |
| 19 | Resolved | §15.2 `GlassSurface.tsx`: tier C is Reduce Transparency and Solid glass, and Increase Contrast is a modifier on A and B. §2.8.4 has `--mm-dim-min-hc` / `--mm-dim-max-hc` and `dimMinHc` / `dimMaxHc`. §4.11 agrees. |
| 20 | Resolved | §2.1.2 "4.66 over a white page". §2.1.9 "15.1:1". §2.8.1 `Color(0x4D787880)`. |
| 21 | Resolved | §10.1 and §12.4 read k 219.6 / c 26.08. `--stagger` is set on the heading (24ms / 40ms). Letter delays use `calc(var(--i) * var(--stagger))`, and the glint is keyed to `--mm-spring-letter-ms`. The interruptible variant uses the generated `spring.letter`. |
| 22 | Resolved | §2.4.3 Web mapping: × 1.000 / 1.033 / 1.067 (T4) and × 1.000 / 1.055 / 1.109 (T5). These give 0.6 / 1.2 px and 1.2 / 2.4 px. |
| 23 | Resolved | §3.7 `letter-spacing: calc(var(--mm-type-<role>-track) + var(--mm-tracking-legible, 0em))`, and "`build.mjs` emits every `-track` value with its `em` unit". |
| 24 | Resolved | §15.2 `fonts.ts`: Atkinson `preload: false`, fetched on `data-legible="on"`. This matches §3.1 "never preloaded". |
| 25 | Resolved | See the round-1 table. The prose reads "10 to 40 % per the source", the two new rows are present and the mood rule is in place. The mood opacities (16 to 30 %) stay inside 10 to 40. |
| 26 | Resolved | `g50` is "Graphite and page placeholders". `g25` adds "page-lit gutter wells". §8.14.1 and §8.14.11 agree. |
| 27 | Resolved | §10.1 placement 8 (Setup and picker titles). §12.4 "blur 12 → 0". |
| 28 | Resolved | §4.10 Avatar arc row (280 ms, `tick`, `selection`). The Cover arc row names only collection detail (420 ms). |
| 29 | Resolved | §8.25.3 "Fit (Width · Height · Original)". |
| 30 | Resolved | §7.1 drops the backup restore and points to the typed confirmation of §8.25.10. |
| 31 | Resolved | §7.38 carries the 60 s closed-sheet exception. §9.1.3 agrees. |
| 32 | Resolved | Chapter card rise: "Manga chapter end". Novel next row (`page`, 615 ms). §8.15.2 agrees. |
| 33 | Resolved | §5.2 `detent.tick` "(the speed dial: one per 0.25×; its 0.05 steps are silent)". §8.16.3 agrees. |
| 34 | Resolved | See the round-1 table. |
| 35 | **Unresolved** | The fix text is in place: the §7.26 sizes, hover 1.04 (picker 1.08) and §9.2.2 "20 (milestone toast)". The Friend orb bullet in the same section still contradicts the new size list (below). |
| 36 | Resolved | §2.7 `mm-mark` is the §12.1 master ÷ 4. §12.2 says "9 units on the 1024 master" (2 / 64 × 288 = 9). |
| 37 | Resolved | §3.2 `caption2` (micro labels), `tabLabel` (dock labels). |
| 38 | Resolved | §8.0.1 Bare and §8.3 cite the §2.2 margins (16 px up to 413 px, 20 px from 414 px), matching §2.2 `s6` / `s7`. |
| 39 | Resolved | §4.5 zoom row (3× strip; 4× paged and image viewer). §7.31, §8.14.3, §11 and §15.4 agree. |
| 40 | Resolved | §8.14.3: a 36 × 140 `glassThin` HUD capsule (T2), 16 px sun glyph, `caption1` value. |
| 41 | Resolved | §2.4.1 rule 1, §2.8.1 `color.twinDense` (`Color(0xD1131317)`) and §8.14.9 agree. (Cosmetic: §8.14.9 still has the unmatched ")" after "no backdrop read".) |
| 42 | Resolved | §8.0.3: one "Series, book and Downloads \| `save-files`" row and a new "Updates \| `run`" row. The §7.10 desktop table lists `run`. |
| 43 | Resolved | §5.2 `annual.podium`, `annual.summary` and `logo.reduced`. The §6 `add` / `shimmer` cues, §15.6, §9.2.3 and §12.4 cite them. §15.10 G8 names `sheet.open` and `sheet.close`. |
| 44 | Resolved | §7.20 18+ at 18 %. §7.1 hold fill `iris600` at 60 %, progress on `lens`. §7.17 `rIconTile` 12. §7.7 / §7.8 focus 1.04. §8.15.5 `medium` sheet (52 %). |
| 45 | **Unresolved** | All nine threshold rows, eight physics rows and `spring.splashLens` are in §2.8.5 (and in §4.2). §12.4 and the Droplet reveal row cite `splashLens`. The `fantasticon` part stays as STACK-22 set it (4.1.0, "reused", matching `cinematic/DESIGN.md` §15.11); do not re-apply the judge's 3.0.0. One stale claim on the `lens` row remains (below). |

---

## Unresolved, with the edit each needs

### CONSISTENCY-4: the sentence list quotes its contrast on the wrong surface

The fix added the §7.10 exception (line 1724): the listen full player "is `glassMonolith` (T5) at `medium` and cross-fades to `solid2` at `large`".

The §8.16.2 **Sentence list** exists only "at `large`" (line 2845), but it still reads "others in `label2` (6.57:1 on `solid1`; …)". That figure came from A11Y-20, which assumed the default §7.10 `solid1`. Under the exception the list sits on `solid2`, where `label2` measures **6.08:1**. It still passes 4.5:1, but the stated surface and ratio are wrong.

Edit §8.16.2: "others in `label2` (6.08:1 on `solid2`; …)".

### CONSISTENCY-35: activity-row orbs are both 32 px and 18 px

The fix wrote the §7.26 size list (line 1954), which includes "32 (sidebar, activity rows)". Three places disagree with it:

- The **Friend orb** bullet in the same section (line 1957) still says "18 px in activity rows, 56 px as drop targets and in the presence arc". §9.3.1 draws activity rows with "the actor orb 32 with a bloom ring" (line 3393), so the 18 contradicts both the list and the screen.
- The 18 px size is real, but it belongs to the §7.20 **Friend** badge (line 1878). The list does not include it.
- The shared-collection "20 px orb of who added them" (§9.3.3, line 3413) is also missing from the list.

This is the same class of gap the finding targeted (orb sizes used elsewhere but missing from §7.26). The contradiction is older than the fix, but it now sits beside the rewritten list.

Edit §7.26:

1. Friend orb: "the same orb with a `bloom` ring; 18 px as the Friend badge (§7.20), 32 px in activity rows (§9.3.1), 56 px as drop targets and in the presence arc".
2. Size list: add "18 (friend badge)" and "20 (shared-collection adder, §9.3.3)".

### CONSISTENCY-45: `lens` still claims the splash lens

The fix created `spring.splashLens` for "the splash lens growing out of the droplet" (§4.2 line 1066, §2.8.5, §12.4 line 3924). But the §4.2 `lens` row (line 1053) still lists "Liquid lenses: the scrub magnifier appearing, **the splash lens**, the reaction bloom".

In §12.4, `lens` drives only the droplet's squash recovery at impact (line 3923). Two rows of the same table now name different springs for the splash lens.

Edit the `lens` use cell: "Liquid lenses: the scrub magnifier appearing, the splash droplet's impact squash (§12.4), the reaction bloom".

---

## Observations outside the confirmed fixes (not counted)

- **Carried over from round 1, still open:**
  - The phone series-detail sheet never states its material. If it is a glass sheet, its "trailing glass group" and its §2.4.1 rule-2 buttons are glass on glass under rule 7 (§8.12).
  - The §8.15.2 "Listen · 14 min" capsule is `glassThin` inside the novel column. Rule 1 forbids that; it should be the `glassThin` content twin.
  - Rule 7 fixes the twin rim at 0.22, while rule 1 and §2.4.3 give twins "the rim of the tier it replaces". The two disagree for the 72 px twins of §8.16.2, which are T3-sized with a 0.20 rim.
- **§9.2.4 share strip on the Wrapped frame.** On Wrapped, the share side's "`glassThick` strip" (Story · Post tabs, switch, buttons) sits inside the `glassMonolith` frame. Rule 7 names the frame as a host, and its bloom exception covers only "a menu, popover or the speed dial". One sentence should settle it: either the strip is the frame's second stacked layer, like a popover (the §15.7 Takeovers count stays 2, because card 10's lens is flattened on the share side), or it is drawn as twins. On Statistics, where there is no frame, the strip is fine as written.
- **The exhaustive motion table has gaps beyond the 16 rows the judge added.** Examples: the indeterminate linear progress "30 % band sweeping a linear track every 1.2 s" (§7.19), the switch knob travel on `tick` (§7.22), and the picker orb's "`celebrate` hop" after a profile save (§8.6). They predate the fix and were not in its list.
- **Cosmetic:** the unmatched ")" in §8.14.9 after "no backdrop read" (also noted in round 1).
