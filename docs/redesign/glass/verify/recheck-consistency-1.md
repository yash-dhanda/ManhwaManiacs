# Glass DESIGN.md: recheck round 1, lens consistency

Input: the 44 findings in the "Confirmed" section of `glass/verify/judge-consistency.md` (CONSISTENCY-7 was refuted and is not checked). Target: `glass/DESIGN.md` as it stood at 2026-09-28 23:41:57 UTC (810,971 bytes, 4,585 lines). The other lenses' fixers (web, mobile, product, a11y, stack) were writing to the file during this pass: it grew from 4,419 to 4,585 lines while I read it, and one passage I had flagged (§3.3 rule 5, a `glassThin` "Read this card" button on the Wrapped frame) was rewritten by another lens mid-pass and is no longer a problem. Every check below was therefore re-run as one scripted pass against that snapshot. A last run against the 23:43:48 state (814,583 bytes, 4,598 lines) found the same six unresolved items unchanged. Section numbers are authoritative. Line numbers are from the 23:41:57 snapshot and have since moved down by up to 13 lines.

Method: for each finding, I read the sections the final fix names and compared them with the fix text. Then I grepped the whole file for every old value that should be gone, and for every other place the changed value or rule is repeated. Spring settle and overshoot were recomputed from the closed-form mass-spring solution (mass 1, k and c from §2.8.5, settle = last time |1 − x| > 0.005 from rest), including the new `splashLens` row, which the fixer added and the judge did not compute. Poster counts were recomputed from §7.8's content-width rule. Where another lens later rewrote a passage, the finding counts as resolved if the goal of the consistency fix still holds everywhere and the new text contradicts nothing.

**Result: 38 resolved, 6 unresolved** (CONSISTENCY-1, 3, 10, 13, 25, 34). In all six the fix text itself is in place. What remains is either a second site the fix did not reach (1, 3, 10, 34) or a small defect the edit introduced (13, 25). Each needs a one-line or one-cell edit.

---

## Recomputed values

| Spring | k | c | Settle, closed form (ms) | Document (ms) | Overshoot, closed form | Document |
|---|---|---|---|---|---|---|
| `track` | 1754.6 | 72.05 | 148.9 | 149 | 0.502 % | 0.5 % |
| `press` | 815.7 | 45.70 | 252.7 | 253 | 1.52 % | 1.5 % |
| `tick` | 584.0 | 33.83 | 289.2 | 289 | 4.60 % | 4.6 % |
| `snappy` | 246.7 | 26.70 | 430.9 | 431 | 0.63 % | 0.6 % |
| `morph` | 273.4 | 24.80 | 434.5 | 434 | 2.84 % | 2.8 % |
| `tab` | 195.0 | 21.78 | 518.0 | 518 | 2.00 % | 2.0 % |
| `lens` | 223.8 | 20.94 | 467.2 | 467 | 4.60 % | 4.6 % |
| `sheet` | 171.3 | 24.09 | 448.0 | 447 | 0.062 % | 0.06 % |
| `sheetSnap` | 223.8 | 26.33 | 342.1 | 342 | 0.30 % | 0.3 % |
| `page` | 146.0 | 24.17 | 614.9 | 615 | 0 | 0 % |
| `zoom` | 125.9 | 21.09 | 557.4 | 558 | 0.018 % | 0 % |
| `settle` | 322.3 | 35.90 | 413.9 | 414 | 0 | 0 % |
| `minimize` | 246.7 | 31.42 | 473.1 | 473 | 0 | 0 % |
| `dismiss` | 385.5 | 39.27 | 378.4 | 378 | 0 | 0 % |
| `camera` | 195.0 | 25.13 | 391.7 | 392 | 0.154 % | 0.15 % |
| `celebrate` | 109.7 | 13.61 | 642.3 | 643 | 6.82 % | 6.8 % |
| `drift` | 48.7 | 13.96 | 1064.7 | 1064 | 0 | 0 % |
| `letter` | 219.6 | 26.08 | 345.3 | 345 | 0.30 % | 0.3 % |
| `smooth` | 157.9 | 22.62 | 435.6 | 436 | 0.152 % | 0.15 % |
| `splashLens` (new) | 180.0 | 22.0 | 532.4 | 532 | 1.11 % | 1.1 % |

All within 1 ms of the judge's table (the `sheet` and `zoom` differences are the judge's own rounding of 447.5 and 558). Poster counts: phone (374 + 12) / 136 = 2.84; 1024 px (860 + 16) / 184 = 4.76; 1440 px (1056 + 16) / 200 = 5.36; 1920 px (1360 + 16) / 200 = 6.88; tablet 768 px 636 / 164 = 3.88 and 1023 px 891 / 164 = 5.43. The document's 2.8, 4.8, 5.4, 6.9, 3.9 and 5.4 match.

## Old values that must be gone (live-file grep counts)

| Old value | Count |
|---|---|
| Old settle values with "ms" (203, 297, 337, 429, 485, 528, 494, 399, 621, 591, 444, 497, 411, 445, 723, 1065, 402, 490) | 0 |
| "Anything drawn on glass uses fills" (old rule 7) | 0 |
| "`glassThin` clear" | 0 |
| "Sheet present and dismiss by button" | 0 |
| "podium drop in Wrapped", lower-case "flame flicker" in §4.11 | 0 / 0 ("Wrapped page pile" survives once, as prose in the `physics.gravityReaction` row, which is the CONSISTENCY-45 text, not a move name) |
| `.on-glass {`, `"opsz" auto` | 0 / 0 |
| `var(--mm-X)` (old Tailwind rule), bare `--spacing-reader-strip` | 0 / 0 |
| `g600` "meta text … 15 px" | 0 |
| "`x`/`Delete`", "plus `g` go to chapter" | 0 / 0 |
| onTint "4.61" | 0 (the one "4.61:1" left, §7.23, is a new `danger`-glyph figure from another lens) |
| "15.2:1", `0x4C787880` | 0 / 0 |
| `glassSpring.letter`, `stiffness: 220,` | 0 / 0 |
| "18 to 28" (field opacity), "wide-reader side gutters" | 0 / 0 |
| "blur 16" (§12.4), "16 units" (§12.2) | 0 / 0 |
| "onboarding avatar pick", "Fit (Width · Height · Screen" | 0 / 0 |
| "staging a backup restore", "novel end" (§4.10) | 0 / 0 |
| "dock labels when minimised", "sidebar collapsed tooltips" | 0 / 0 |
| "≤ 50 %" (Aa sheet), "content: scale 1.04" | 0 / 0 |
| "a spring (k 180, c 22)" | 0 |
| "620 ms" (skin melt, derived from the old `page` settle 621) | **2** (see CONSISTENCY-10) |
| "reaction sent" in the `celebrate` row | **1** (see CONSISTENCY-34) |
| "`glassThin` droplet indicator" | **1** (see CONSISTENCY-3) |

---

## Per finding

| ID | Status | Evidence in the snapshot |
|---|---|---|
| 1 | **Unresolved** | Rule 7 (the content twin, the tinted twin, the two exceptions, the bloom rule, the third-layer rule) and rule 8 read as the fix says. Every enumerated site is converted: §7.10 close "`fill2` twin circle 32 with ×, 44 hit"; §7.11 "alert buttons are the twins of their §7.1 variants"; §7.15 and §8.16.1 play/pause "`fill2` twin"; §7.35 "`fill2` twin icon buttons"; §8.15.5 "`fill2` twin + `selectedRing`"; §8.16.2 artwork card, 72 px tinted-twin play/pause, three twin tiles, twin sphere, twin chip and "Back to the voice" capsule; §9.4.2 scene orbs; §9.2.3 Export capsule, pause/play and previous/next. Three glass controls on glass remain (below). |
| 2 | Resolved | §2.4.1 Medium row reads "cards and posters (content, no glass)" with the Content sink press cell (0.97 / 0.99); Heavy row reads "the hero card (content, no glass; the class sets its springs only)". |
| 3 | **Unresolved** | §2.4.1 Medium row, the new §2.4.2 "`glassFilm` clear (droplets and dragged thumbs)" row with the judge's values, "`glassFilm` clear" at §7.5, §7.6 (drag), §7.13, §7.15, §7.16, §7.21, §7.22, §7.28, `glassClear` kept for the hero, band and image viewer, and §7.12 "`glassThin` capsule (T2)" are all in place. Two contradictions remain (below). |
| 4 | Resolved | §2.4.3 paragraph (free-sized snap only; T2 fixed lenses; T1 hit lens); §2.4.1 Light and Feather rows list them; §7.27 "`glassThin` capsule (T2), min height 36, padding 9 12"; §7.10 Geometry exception for the listen full player. §7.24 (96 px `glassThin`), §8.14.9 (T1 `glassFilm`), §9.2.3 card 10 (96 px T2) and §9.4.3 (T2) agree. |
| 5 | Resolved | §4.2 `sheet` use cell reads "Sheet present by button (dismissal by button uses `dismiss`, law 10)"; §7.10 Physics already says "Dismiss by button: `dismiss`". |
| 6 | Resolved | §4.6 Back swipe, Image dismiss, Throw to open, Throw away and Magnet capture rows cite `threshold.cross` / `threshold.back`, velocity-scaled `throw.commit`, `magnet.capture` / `magnet.drop` and `detent.magnet` exactly; §5.2 agrees. |
| 8 | Resolved | §4.7 `reducedCrossfade` "150 ms (in-page and sheets) / 200 ms (routes) linear"; §8.0.4 exceptions for Tab switch and Sheet routes. §2.8.5 `curve.reducedCrossfade` 150 and `curve.reducedRoute` 200, §4.10 and §4.11 agree. |
| 9 | Resolved | All 16 rows are in §4.10 with the judge's values; §4.11 uses "Flame flicker", "Podium drop" and "Page pile". The source sections agree: §7.19 spinner (90° ↔ 270°, 900 ms, RM opacity 0.4 ↔ 1 over 1.2 s) and dots (3 px, 80 ms), §7.20 count pop, §7.29 queued ring (4 s), §8.5 breathe (1.02, 2 s), §8.8 drop (0.9, 24 px, `lens`), §8.11 pop, §7.39 chart, §8.14.3 tap light (120 px, 10 %, 300 ms), §9.2.2 flicker, §9.2.3 cards 2 to 4. |
| 10 | **Unresolved** | The §4.2 Settle column, all 19 `--mm-spring-*-ms` values, every "settle N ms" in §4.10, the overshoots (0.15 / 0.15 / 0.06 %), §4.8 (431 ms, 671 ms), §10.1 glint delay, §10.2 (289 ms), §15.1 (`--mm-spring-page-ms: 615ms`) and §8.0.5 (615 ms) are updated. One dependant of the old `page` settle was missed (below). |
| 11 | Resolved | The `.on-glass` rule is gone; §3.5 says the `type-<role>` utility reads `--glass-rond` / `--glass-grad` and optical size comes from `font-optical-sizing: auto`. §3.7 carries `"wght" calc(var(--mm-type-<role>-wght) + var(--press-wght, 0))` with `--press-wght` 0 → 40. Another lens has since made `--glass-rond` / `--glass-grad` unregistered with registered `-t` twins (§3.5, §2.8, §15.1, §15.2); that change keeps the utility's `var()` fallback working and contradicts nothing here. |
| 12 | Resolved | §2.8.3 `border.slab` Web CSS declares `--mm-border-slab-color: rgba(255,255,255,0.06)` beside `--mm-border-slab`; Flutter unchanged. |
| 13 | **Unresolved** | The `dim.edgePlateau`, `dim.edgeFade` and `glass.snap` rows are in §2.8.4, the short-name bullet maps `edgeSoft`, and §15.1 `glass.json` carries the keys. The `spring.format` sentence was inserted in the middle of the §2.8.4 table and broke it (below). |
| 14 | Resolved | §2.4.3 rim bullet ("Live glass (tiers A and B) draws this gradient…"); §2.6 `rim` end stop `S × 0.55`; `glass.t1`–`t5` carry `-rim` 0.26 / 0.22 / 0.20 / 0.16 / 0.14 and `rim: Color(0x42 / 0x38 / 0x33 / 0x29 / 0x24FFFFFF)`; §2.4.1 rule 1 "the rim of the tier it replaces (0.5 px)"; the §15.1 `t2` / `t4` examples have `rim`. |
| 15 | Resolved | §2.8 Tailwind bullet gives the per-namespace mapping; §2.8.2 reads `--spacing-reader-strip-max` (`w-reader-strip-max`). Every Tailwind cell checked (`--spacing-touch-min`, `--ease-spring-track`, `--radius-xs`, `--ease-fade-in`) now resolves to an existing `--mm-` name. |
| 16 | Resolved | §7.9 "(2.8 posters visible at 390 px wide)"; §8.8 desktop "4.8 at 1024 px, 5.4 at 1440 px and 6.9 at 1920 px" (WEB-4's sentence, which includes the judge's 5.4 and 6.9); §8.8 tablet "3.9 (768 px) to 5.4 (1023 px)". All recomputed above. |
| 17 | Resolved | §2.1.1 `g600` role is the judge's text; hex `#76767F` kept. §14.2 now reads "`g600` is non-text only (icons, rings, chevrons and borders; 4.12:1 on `surface1` ≥ 3:1)" (reworded by another lens after the fixer wrote "never used for text"); it says the same thing. |
| 18 | Resolved | §7.34 "`Delete` remove with undo"; §8.13 has no bare `g` ("`/` focuses the go-to field (no bare `g`…)"). `x` means select everywhere (§7.35, §8.0.6, §8.12, §8.17). |
| 19 | Resolved | §15.2 `GlassSurface.tsx`: tier C is Reduce Transparency and Solid glass; Increase Contrast is a modifier on tiers A and B with the 0.40–0.72 clamp. §2.8.4 `dim.legibility` has `--mm-dim-min-hc` / `--mm-dim-max-hc` and `dimMinHc` / `dimMaxHc`; §4.11 agrees. |
| 20 | Resolved | §2.1.2 "4.66 over a white page", §2.1.7 "4.66:1", §14.2 "≥ 4.66:1"; §2.1.9 "15.1:1"; §2.8.1 `colorFill2` = `Color(0x4D787880)`. |
| 21 | Resolved | §10.1 table and §12.4 "k 219.6, c 26.08"; the TSX sets `--stagger` (24ms / 40ms) on the heading; letter delays `calc(var(--i) * var(--stagger))`; glint `calc(var(--n) * var(--stagger) + var(--mm-spring-letter-ms) + 120ms)`; the interruptible variant uses the generated `spring.letter`. |
| 22 | Resolved | §2.4.3 Web mapping: × 1.000 / 1.033 / 1.067 (T4) and × 1.000 / 1.055 / 1.109 (T5). 18 × 0.033 = 0.6, 18 × 0.067 = 1.2, 22 × 0.055 = 1.2, 22 × 0.109 = 2.4. |
| 23 | Resolved | §3.7 `letter-spacing: calc(var(--mm-type-<role>-track) + var(--mm-tracking-legible, 0em))` and "`build.mjs` emits every `-track` value with its `em` unit". |
| 24 | Resolved | §15.2 `fonts.ts`: Atkinson `preload: false`, fetched when the boot script stamps `data-legible="on"`, matching §3.1. |
| 25 | **Unresolved** | The prose ("10 to 40 % per the source"), the two new rows (Home hero enlargement 36 %, Image viewer 40 %) and the mood-opacity rule are in place. The edit left the brand-aurora screens with no opacity (below). |
| 26 | Resolved | `g50` "Graphite and page placeholders (§8.14.1)"; `g25` adds "page-lit gutter wells (§8.14.11)"; §8.14.1 "centred on desktop with the gutters of §8.14.11"; §8.14.11 gutters are `g25` wells. |
| 27 | Resolved | §10.1 placement 8 (Setup and picker titles, once per session); §12.4 "blur 12 → 0", matching §10.1 and `blur.reveal` 12. |
| 28 | Resolved | §4.10 Avatar arc row (280 ms, `tick`, `selection`); the Cover arc row names only collection detail; §8.6 agrees (280 ms, 3,000 px/s²). |
| 29 | Resolved | §8.25.3 "Fit (Width · Height · Original)", matching §8.14.5. |
| 30 | Resolved | §7.1 hold-to-confirm list drops the backup restore and points to §8.25.10's typed "RESTORE" confirmation. |
| 31 | Resolved | §7.38 carries the 60 s exception for a closed recap sheet; §9.1.3 agrees. |
| 32 | Resolved | Chapter card rise reads "Manga chapter end (one at a time)"; the new Novel next row (`page`, settle 615 ms) matches §8.15.2. |
| 33 | Resolved | §5.2 `detent.tick` "(the speed dial: one per 0.25×; its 0.05 steps are silent)", matching §8.16.3. |
| 34 | **Unresolved** | §2.7 Reactions row is on `tick` with the burst; the §4.10 Tab droplet row hands the in-page indicator to `settle` (§7.13). One repetition of the old reaction spring remains (below). |
| 35 | Resolved | §7.26 sizes and hover (1.08 on the picker) are the judge's text; §9.2.2 lists 20 (milestone toast). §8.5 (96 / 128), §8.6 (56), §8.24 (72) and §9.3.5 (112) agree. |
| 36 | Resolved | §2.7 `mm-mark` is the §12.1 master ÷ 4 (x 60–196, y 48–120 / 120–136 / 136–208, stroke 22); §12.2 "9 units on the 1024 master" (2 / 64 × 288 = 9). |
| 37 | Resolved | §3.2 `caption2` (micro labels) and `tabLabel` (dock labels). |
| 38 | Resolved | §8.0.1 Bare and §8.3 cite the §2.2 margins (16 px up to 413 px, 20 px from 414 px). |
| 39 | Resolved | §4.5 zoom row (3× strip; 4× paged and image viewer), matching §7.31, §8.14.3, §11 and §15.4. |
| 40 | Resolved | §8.14.3 HUD is a 36 × 140 `glassThin` capsule (T2) with the 16 px sun glyph and a `caption1` value. |
| 41 | Resolved | §2.4.1 rule 1 names `twinDense`; §2.8.1 has `color.twinDense` (`Color(0xD1131317)`, 0.82 × 255 = 209 = 0xD1); §8.14.9 cites it. (Cosmetic only: §8.14.9 now has an unmatched ")" after "no backdrop read", left over from the old parenthesis.) |
| 42 | Resolved | §8.0.3 id table: one "Series, book and Downloads | `save-files`" row and a new "Updates | `run`" row; §7.10's desktop table lists `run`. |
| 43 | Resolved | §5.2 has `annual.podium` (`success`), `annual.summary` (none, sound only) and `logo.reduced` (`light`); §6 `add` and `shimmer` cues use them; §15.6 lists all three; §9.2.3 card 4 and Sound line and §12.4 cite them; §15.10 G8 names `sheet.open` and `sheet.close`. |
| 44 | Resolved | §7.20 18+ at 18 %; §7.1 hold fill `iris600` at 60 % (and §7.19 agrees); progress fill on `lens`; §7.17 `rIconTile` 12; §7.7 focus "ring + scale 1.04" (from WEB-18, same value); §8.15.5 `medium` sheet 52 %. |
| 45 | Resolved (partly superseded) | All nine threshold rows, eight physics rows and `spring.splashLens` are in §2.8.5 (plus a matching §4.2 row); §12.4 and the Droplet reveal row cite `splashLens`. The `fantasticon` part was later rewritten by the stack lens (STACK-22) to "4.1.0 … reused", not the judge's "3.0.0 … added here". That is correct now: `cinematic/DESIGN.md` §15.11 pins `fantasticon` 4.1.0, so the judge's premise that Cinematic never uses it no longer holds, and §2.7, §12.6 and §15.11 all say 4.1.0. The consistency defect (no version, wrong status) is gone; do not re-apply 3.0.0. |

---

## Unresolved, with the edit each needs

### CONSISTENCY-1: three glass controls still drawn on glass

1. **§8.16.2 Full player, Header ⋯** (line 2826): "a trailing `glassThin` 32 button (44 hit) in the sheet header". It sits on the full-player sheet, which rule 7 names as a glass host. Edit: "a trailing `fill2` twin circle 32 (44 hit, §2.4.2 rule 7) in the sheet header", the same recipe as the §7.10 close button.
2. **§7.21 Fill slider** (line 1875): "a tall 72 × 160 `glassRegular` capsule … used in the reader sheet for brightness and warmth". §8.14.5 (line 2653) puts two of them in the Light row of the phone reader settings sheet, which is a `glassThick` sheet at `medium` (§7.10). Edit §7.21: "a tall 72 × 160 capsule drawn as the `fill2` twin (§2.4.2 rule 7) that fills from the bottom with `onGlass` at 90 %". On desktop the sliders sit in the `materialThick` right panel, where a twin is also correct.
3. **§15.7 Takeovers row** (line 4350): "the close or back button 1, the frame (Wrapped `glassMonolith`) 1, a card's lens 1 = **3** | 3 / 3". Wrapped's close button sits in the frame's buttons row (§9.2.3 Card layout, y 24–68, beside the pause/play twin), so under rule 7 it is a `fill2` twin and not a live glass element. The judge's note that "the §15.7 member counts then stay correct as written" does not hold for this row. Edits: §9.2.3 Accessibility, "beside the close button (also a `fill2` twin)"; §15.7 Takeovers row, "the close or back button 1 (picker, onboarding; on Wrapped it is a twin on the frame), the frame (Wrapped `glassMonolith`) 1, a card's lens 1 = **2** | 2 / 2".

### CONSISTENCY-3: droplet material, and the new variant has no token

1. **§7.6 Vertical variant** (line 1669): "the `glassThin` droplet indicator travels vertically on `tab`" (added by WEB-17). This contradicts the fix, which makes every selection droplet "`glassFilm` clear" (T1), and the rule-7 exception, which treats selection droplets as a clear-finish region. Edit: "the `glassFilm` clear droplet indicator".
2. **"`glassFilm` clear" has no token key, and its blur disagrees with the finish it maps to.** The new §2.4.2 row (line 376) gives blur 2. But neither the §2.8 short-name bullet (line 531) nor §2.8.4 has a key for it. `GlassSurface` (§15.2) builds a surface from a tier plus a finish, so `glass.t1` with the `clear` finish would take `glass.clear`'s blur 1 (line 769), not 2. That leaves two values for one surface. Edit, the smaller of two options: in the §2.4.2 row, change Blur 2 to 1, and add to the short-name bullet "'`glassFilm` clear' → `glass.t1` + `glass.clear`". The other option is a new `glass.filmClear` key in §2.8.4, which adds a token for one use.

### CONSISTENCY-10: the skin melt still uses the old `page` settle

§4.10 Skin melt row (line 1236) reads "620 ms (the three parts run together)", and §8.25.2 step 3 (line 3004) reads "the 'melt', 620 ms". The three parts are `dematerialize` 350 ms, `smooth` settle 436 ms and `page` settle 615 ms. Because they run together, the melt ends at 615 ms. The 620 was the old `page` settle (621) rounded, and the fix's dependants list missed it. Edit both to "615 ms".

### CONSISTENCY-13: the `spring.format` note broke the §2.8.4 table

Line 782 inserts the paragraph "`spring.format` in `glass.json` (§15.1) is generator configuration, not a token: it emits no name." between the `glass.snap` row and the `caustic` row, with no blank lines. The `caustic` row (line 783) is now a lazy continuation of that paragraph. It renders as text, not as a token row, so the `caustic` key drops out of the token map. Edit: move the sentence below the `caustic` row, after a blank line, so the table reads `… glass.snap | caustic |`, then a blank line, then the note.

### CONSISTENCY-25: the brand aurora has no opacity

The §2.1.8 row "Settings, You, admin, auth, onboarding" (line 220) now gives "the mood's own opacity (§2.1.6)". The same row says auth, setup and onboarding use the brand aurora (`#8FD8FF`, `#A99BFF`, `#FF9ED8`). Setup, Login and Register run before any profile exists, so they have no mood and no opacity. The flat 20 % the fix removed was the only value that covered them. Edit the opacity cell: "the mood's own opacity (§2.1.6); the brand aurora (auth, setup, onboarding) 20 %".

### CONSISTENCY-34: `celebrate` still claims the reaction

§4.2 `celebrate` use cell (line 1061) reads "Added to library, streak +1, reaction sent, goal met". After the fix, no reaction move uses `celebrate`. §2.7 lands on `tick`, the §4.10 Reaction bloom and arc row is `lens` / ballistic / `tick`, and §9.3.2 lands on `tick`. Edit: "Added to library, streak +1, goal met, the podium #1 landing" (the Podium drop row lands #1 on `celebrate`), or simply drop "reaction sent".

---

## Observations outside the confirmed fixes (not counted)

- **Series detail sheet vs rule 7.** On phones, series detail is a sheet (§8.12). §2.4.1 rule 2 allows its split "Continue" and its secondary buttons to be real glass (`standard` quality), while rule 7 says a control on a sheet is a twin. §8.12 never states the sheet's material (its band fades to black), so this may be intended. It needs one sentence in §8.12 saying whether the series sheet is a glass host.
- **§8.15.2 "Listen · 14 min" capsule** is `glassThin` inside the novel column, which §2.4.1 rule 1 forbids ("anything inside the reading surface"). Same fix pattern: the content twin of `glassThin`.
- **Two twin rims.** Rule 7 fixes the twin rim at `rgba(255,255,255,0.22)`. Rule 1 and §2.4.3 say a twin uses "the rim of the tier it replaces". The two agree for T2-sized controls. They differ for the 72 px twins of §8.16.2 (a T3 size, rim 0.20), so one sentence should say which rule wins.
