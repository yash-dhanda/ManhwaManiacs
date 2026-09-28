# Glass DESIGN.md: verdicts on the internal-consistency findings

Input: `docs/redesign/glass/verify/find-consistency.md` (45 findings). Every finding was checked against `docs/redesign/glass/DESIGN.md` (the cited lines read in context, plus greps for every other occurrence of the value), `inventory/00-decisions.md` and `stack-decision.md`. Spring settle and overshoot values were recomputed from the closed-form mass-spring solution (k and c from §2.8.5, mass 1, settle = last time |1 − x| > 0.005 from rest, the rule §4.2 states). Contrast ratios were recomputed with the WCAG 2.x luminance formula.

Result: **44 confirmed, 1 refuted.** Fixes were rewritten where the original was vague (an either/or), wrong, or collided with another confirmed fix. The biggest collision: CONSISTENCY-1 makes controls drawn on glass into content twins. CONSISTENCY-4's original fix still declared the speaking orb and the soundscape scene orbs as T2 glass, but both sit on glass sheets, so its fix was narrowed to match.

---

## Verdicts

| ID | Verdict | Reason |
|---|---|---|
| CONSISTENCY-1 | **Confirmed**, fix rewritten | §2.4.2 rule 7 ("Anything drawn on glass uses fills") contradicts glass controls drawn on glass: the sheet close button (§7.10, `glassThin` 32), alert buttons (§7.11, the §7.1 glass variants), the player's play/pause, tiles, speaking orb and chip (§8.16.2), the accessory's play/pause (§8.16.1), the Aa face tiles (§8.15.5), the six scene orbs on the soundscape sheet (§9.4.2), the bulk toolbar's "glass icon buttons" (§7.35), and Wrapped's Export capsule and accessibility buttons on the `glassMonolith` frame (§9.2.3). The §15.7 phone row already counts 8 Flutter members with the sheet as one, so one more glass control on the sheet breaks the limit of 8. The original fix missed the accessory, the scene orbs and the Wrapped frame, and it kept a caustic on the tinted twin. §2.4.4 draws a caustic only onto content, and a sheet is not content, so the rewritten fix drops it. |
| CONSISTENCY-2 | **Confirmed**, fix rewritten | The §2.4.1 Medium row gives cards and posters "scale 1.04" as press growth. §4.10 Content sink and §7.7 say they sink to 0.97. The Heavy row lists "the hero card" as T4 glass, but §8.8 makes it a cover that receives the caustic, so it is content. Moving it to the Massive row, as the original fix did, has no basis. It keeps its Heavy mass (its springs) and is marked as content. |
| CONSISTENCY-3 | **Confirmed**, fix adjusted | The mass table says buttons are T3, but §7.1 makes Secondary `glassThin` (T2) on black and `glassRegular` over media. The Feather droplets and thumbs are T1 in the table, but §7 calls them "`glassThin` clear" (T2) or `glassClear` (a finish that §2.4.2 reserves for controls over media, "on the host tier"). Toasts are T2 in §2.4.1, §2.4.3 and §15.7 but `glassRegular` in §7.12. Part (a) of the fix now keeps §7.1's over-media variant. |
| CONSISTENCY-4 | **Confirmed**, fix narrowed | The tier snap is defined only for free-sized objects, and no rule covers fixed-size lenses (96 px object and source lenses, Wrapped card 10's lens, the panel-sized guided-view lens that §9.4.3 calls T2). The tooltip is a ~30 px free-sized capsule, which the snap puts at T1, yet §7.27 names `glassThick` (T4). The listen full player is T5 in §2.4.1 and §2.4.2, but on phones it is a §7.10 sheet, which is `glassThick` turning `solid1` at `large`, so its material is undefined. The speaking orb and scene orbs were dropped from the fix: they sit on glass sheets and become twins under CONSISTENCY-1. |
| CONSISTENCY-5 | **Confirmed** | The §4.2 `sheet` row (bounce 0.08) says it handles "dismiss by button". Law 10 bans bounce on exits, and §7.10 already uses `dismiss`. |
| CONSISTENCY-6 | **Confirmed**, fix extended | All four mismatches are real. Back swipe: §4.6 `rigid` 0.5 vs §5.2 `rigid(0.6)`. Image dismiss: §4.6 `soft` 0.5 vs `threshold.cross` `rigid(0.6)`. Throws: §4.6 `rigid` 0.7 vs velocity-scaled `throw.commit` (0.6 at the 1200 px/s threshold). Magnet: §4.6 "`soft` on release" vs `magnet.drop` `ahap:magnet`. The §4.6 magnet row also covers "detents with magnets", which §5.2 maps to `detent.magnet` `rigid(0.4)`, so the fix now names both. |
| CONSISTENCY-7 | **Refuted** | No real ambiguity. Every cited §4.10 row states its own duration in the Duration column (Tab switch 120 ms, Row pulse 900 ms, Field ripple 600 ms, Word stream 120 ms per word, colour pour 600 ms). The curve column names the easing, and `CurveToken` exposes `.curve` separately. §4.10 is the source `play()` is generated from, so the row's ms is what runs. Adding five single-use tokens would only duplicate the table. |
| CONSISTENCY-8 | **Confirmed**, fix extended | The sheet contradiction is real: §4.7 says `reducedCrossfade` is 200 ms for sheets, while §4.10 and §4.11 say 150 ms. §8.0.4 says every row becomes a 200 ms cross-fade, but its own rows include Tab switch (120 ms, §4.10) and Sheet routes (150 ms, §4.11), so both need an exception. |
| CONSISTENCY-9 | **Confirmed**, fix completed | §4.10 claims to be exhaustive and says `play()` throws on unknown names, yet §4.11 names "flame flicker", "podium drop in Wrapped" and "Wrapped page pile", and more than a dozen specified animations have no row. Loops such as Thinking orbit and Lens bob do have rows, so the missing spinner, dots and similar loops are gaps, not out-of-scope items. The podium drop really has no numbers. The original fix left out most of the Reduce Motion values, so they were filled in from the sources (§7.39, §2.7, §4.11, §9.4.2). |
| CONSISTENCY-10 | **Confirmed**, one option chosen and values corrected | The recomputation confirms it. The five critically damped springs all settle at 1.183 × their duration (page 615, settle 414, minimize 473, dismiss 378, drift 1064), but the table gives ratios from 1.18 to 1.28. `camera` and `smooth` both overshoot 0.15 %. The finding's numbers are right except `track`, which settles at 149.1 ms (not 147), and `sheet`, at 447.5 ms (447). The original "either … or" fix was replaced with one option: publish the recomputed values. They also feed the `linear()` sampling window and the motion-timings overrun check. |
| CONSISTENCY-11 | **Confirmed** | `"opsz" auto` is not a `<string> <number>` pair, so browsers drop the whole `.on-glass` declaration. Its axis list also omits `wght`, which conflicts with §3.7's utility. Deleting the rule is the right fix, because §3.7 already reads `--glass-rond` and `--glass-grad`, and §3.2 already sets `font-optical-sizing: auto`. |
| CONSISTENCY-12 | **Confirmed** | `--mm-border-slab-color` appears exactly once in the file, in the Tailwind cell, and is never defined. |
| CONSISTENCY-13 | **Confirmed** | `edgeSoft`, used on every screen, has no row in §2.8. §15.1's `glass.json` carries `dim.edgePlateau`, `dim.edgeFade` and `glass.snap`, which §2.8 never maps, so they get no generated names. |
| CONSISTENCY-14 | **Confirmed**, fix adjusted | The rim has three definitions: flat per tier (§2.4.2), a gradient ending at `S × 0.55` (§2.4.3), and a gradient ending at 0.20 (§2.6). `GlassTier` has no rim field, although content twins need "the tier's rim". The original fix said tier B "frosted" uses the flat rim as a fallback. §2.4.3 says tier B keeps the rim, so that claim was invented and is removed. The Dart alphas were checked (0x42, 0x38, 0x33, 0x29, 0x24). |
| CONSISTENCY-15 | **Confirmed** | The stated rule "Tailwind `X` maps to `var(--mm-X)`" gives `var(--mm-spacing-touch-min)` and `var(--mm-ease-spring-track)`, and neither exists. `--spacing-reader-strip` does not match its CSS name either. |
| CONSISTENCY-16 | **Confirmed**, one option chosen | Recomputed: phone (374 + 12) / 136 = 2.84; desktop 1440 → (1056 + 16) / 200 = 5.36; 1920 → (1360 + 16) / 200 = 6.88; tablet 768 → 3.88 and 1023 → 5.43. None of the stated counts (3.2, 7 to 9, 5 to 6) can be reached. The alternative of changing the poster width was dropped, because the counts are the claims that are wrong. |
| CONSISTENCY-17 | **Confirmed**, fix rewritten | At 15 px, `g600` meta text at 4.12:1 on `surface1` fails WCAG 1.4.3 and §14.2's own 4.5:1 rule. The proposed hex `#7D7D86` gives 5.15 on black and 4.54 on `surface1`, but still fails on `surface2` (4.25) and `surface3` (3.88), and the proposed "any size ≥ 13 px" wording would allow those. No screen actually uses `g600` as text: its uses are chevrons, checkbox and radio borders, dashed rings and the unknown-state tint, all non-text at ≥ 3:1. The lazier correct fix removes the text role and keeps the hex. |
| CONSISTENCY-18 | **Confirmed** | `x` is both "select" (§8.0.6, §7.35, §8.12) and "remove" (§7.34). The book page's bare `g` (§8.13) collides with the global `g` chord prefix, and the book page is not a reader, where §8.14.7 turns the chords off. |
| CONSISTENCY-19 | **Confirmed** | §15.2 renders Increase Contrast with the opaque tier C, while §4.11 raises the translucent glass's dim floor and ceiling under Increase Contrast. Those changes only make sense on tiers A and B. |
| CONSISTENCY-20 | **Confirmed** | `#7262DD` gives 4.66 (§2.1.2 says 4.61). `label1` on `machineWash` over black is 15.12 (the document says 15.2). 0.30 × 255 = 76.5 rounds to 0x4D, as `glass.tinted`'s rim already does, but `fill2` uses 0x4C. Every other alpha in §2.8.1 rounds half-up. |
| CONSISTENCY-21 | **Confirmed** | §10.1 and §12.4 use rounded k 220 / c 26 in place of the token (219.6 / 26.08). `glassSpring.letter` is not a generated name (§15.1 emits `spring.<name>`). In per-word mode `--n` counts words staggered 40 ms apart, but the glint delay multiplies by 24 ms, so the glint starts before the last word lands. |
| CONSISTENCY-22 | **Confirmed** | With 18 and 22 px displacement, scale multipliers of 1.00 / 1.02 / 1.04 give 0.36 / 0.72 and 0.44 / 0.88 px, not the stated 0.6 / 1.2 and 1.2 / 2.4. The proposed multipliers reproduce the stated offsets exactly. |
| CONSISTENCY-23 | **Confirmed**, fix tightened | `--mm-tracking-legible` is set but never read, because §3.7's `letter-spacing` reads only `-track`. The `calc()` fix only works if `-track` carries its `em` unit, so the fix now says it must. |
| CONSISTENCY-24 | **Confirmed** | §3.1 says Atkinson is "never preloaded", while §15.2 says "preload only with legible=1". |
| CONSISTENCY-25 | **Confirmed** | The §2.1.8 prose says 18 to 28 %, but its own table has 30 % and 10 %. The mood row's flat 20 % ignores the per-mood opacities of §2.1.6. Home is 26 % in the table and 36 % in §8.8. The image viewer (40 %, §7.31) has no row. |
| CONSISTENCY-26 | **Confirmed** | The `g50` role says "wide-reader side gutters", but §8.14.11 gutters are `g25` wells (or `#000000`), and `g50` is actually used for Graphite and page placeholders (§8.14.1). |
| CONSISTENCY-27 | **Confirmed**, one option chosen | "Connect your server" (§8.1) and "Who's reading?" (§8.5) use the letter reveal but fall under no placement in the "exactly these" list: neither is a tab root nor a pushed screen. §12.4 says blur 16 → 0, against §10.1's single 12 px value and `blur.reveal` 12. |
| CONSISTENCY-28 | **Confirmed** | The avatar arc is 280 ms in §8.6 and 420 ms in the §4.10 Cover arc row. That row also calls §8.6 "onboarding", but §8.6 is the profile form. |
| CONSISTENCY-29 | **Confirmed** | Reader defaults offer Fit "Screen", but the reader offers "Original" (§8.14.1, §8.14.5). |
| CONSISTENCY-30 | **Confirmed** | §7.1 lists "staging a backup restore" as hold-to-confirm, while §8.25.10 specifies a typed "RESTORE" phrase and a destructive button. |
| CONSISTENCY-31 | **Confirmed** | §7.38 abandons a request at 40 s, while §9.1.3 keeps a recap whose sheet was closed alive for up to 60 s. Nothing says which rule wins. |
| CONSISTENCY-32 | **Confirmed** | §4.10 gives "novel end" the Chapter card rise with `zoom`, but §8.15.2 slides the next chapter up in place on `page`. |
| CONSISTENCY-33 | **Confirmed** | §5.2 fires `detent.tick` "one per step" for the speed dial (0.05 steps), but §8.16.3 ticks every 0.25×. |
| CONSISTENCY-34 | **Confirmed** | The reaction landing is `celebrate` in §2.7 but `tick` in §4.10 and §9.3.2. The in-page tab indicator settles on `settle` in §7.13 but is listed under the `tab` spring's Tab droplet row in §4.10. |
| CONSISTENCY-35 | **Confirmed** | §7.26 lists orb sizes, but the picker uses 128 on desktop (§8.5), You uses 72 (§8.24), the friend sheet 112 (§9.3.5) and the avatar grid 56 (§8.6). Picker hover is 1.08 (§8.5) against §7.26's 1.04. The milestone toast's 20 px flame is missing from the §9.2.2 sizes. |
| CONSISTENCY-36 | **Confirmed** | ÷4, the §12.1 master gives x 60–196, top M y 48–120, bottom M y 136–208 (M height 72, aspect ≈ 0.85). §2.7 draws the same MM column 88 units per M (aspect ≈ 0.63). On the master, cap height is the M's 288 units, so a 2 px bow at 64 px cap height is 9 units, not 16. |
| CONSISTENCY-37 | **Confirmed** | `caption2` "dock labels when minimised" contradicts §7.15, where the minimised dock shows only the active icon. `tabLabel` "sidebar collapsed tooltips" contradicts §7.27, where tooltips are `footnote`. |
| CONSISTENCY-38 | **Confirmed**, fix rewritten | The bare frame uses a 16 px margin (§8.0.1) and Login uses 20 px (§8.3). The proposed "20 px everywhere" would break §2.2, where phones up to 413 px wide use a 16 px margin and phones from 414 px use 20 px. Both places now cite the §2.2 margins. |
| CONSISTENCY-39 | **Confirmed** | §4.5 gives manga a 3× ceiling, but paged mode goes to 4× (§8.14.3, §11, §15.4). |
| CONSISTENCY-40 | **Confirmed** | A 6 px wide capsule cannot hold a sun glyph and a value. HUDs are Light-class T2 capsules (§2.4.1), which the fix matches. |
| CONSISTENCY-41 | **Confirmed** | The dialogue boxes use a twin fill of 0.82, but the defined twin is 0.62, and no token exists for 0.82. 0.82 × 255 = 209 = 0xD1. |
| CONSISTENCY-42 | **Confirmed** | `save-files` appears twice in the "once each" table, and `run` (§8.21 Updates, `?sheet=run`) is filed under Downloads. |
| CONSISTENCY-43 | **Confirmed** | Four cue triggers are not contract events: the "Wrapped summary card" `shimmer` in §6, the podium `add` and `success` and the summary `shimmer` in §9.2.3, and the Reduce Motion `light` haptic in §12.4 (`light` is a pattern, not an event). §15.10 G8 names only `sheet.close`, while §6 and §15.6 add both `sheet.open` and `sheet.close`. |
| CONSISTENCY-44 | **Confirmed** | All six component values contradict their defining sections: 18+ badge 22 % vs the §2.1.4 badge rule of 18 %; hold fill 70 % vs liquid fill 60 %; progress button `snappy` vs liquid fill `lens`; icon tile radius 8 vs `rIconTile` 12; poster focus 1.04 vs card focus 1.03 (a series card *is* a poster, §7.7); Aa sheet "≤ 50 %" vs the `medium` detent of 52 %. |
| CONSISTENCY-45 | **Confirmed**, fix extended | Four compound thresholds emit only their first number (280, 180, 10, 450), so the 24 px, 800 px/s, 18 px and 500 ms halves have no key. The §12.4 lens spring (k 180, c 22 = `{468 ms, 0.18}`) is the only spring outside the token table. The prose-only numbers are real too. `fantasticon` has no version, and it is marked "reused" although `cinematic/DESIGN.md` never uses it, so its status is wrong as well. |

---

## Confirmed

Final fixes, ready to apply to `glass/DESIGN.md`. Each one says where to edit and what to write.

### CONSISTENCY-1 (high): glass controls drawn on glass

1. Replace §2.4.2 rule 7 with: "**No glass on glass.** A control drawn on a glass surface (sheet, alert, popover, desktop panel or window, sidebar, bottom accessory, full player, floating toolbar, the Wrapped frame) is the **content twin** of its variant: same shape and size, `fill2` fill `rgba(120,120,128,0.30)`, 0.5 px rim `rgba(255,255,255,0.22)`, inner light, `onGlass` label, and no backdrop read, displacement or dim. It is not a `BackdropGroup` member.
   - The host's one lit action (rule 8) is the **tinted twin**: fill `iris600` at 86 %, rim `rgba(255,255,255,0.30)`, specular `iris100` at 60 %, no backdrop read, no caustic (the caustic falls only on content, §2.4.4).
   - Two exceptions. Selection droplets (dock, sidebar, segmented, palette) are a clear-finish region of their host bar's own surface, not a second backdrop read. Wrapped card 10's source lens (§9.2.3) stays glass and is counted in §15.7.
   - A menu, popover or the speed dial that blooms from a control on glass is a second stacked layer (the two-layer budget of §2.5), not glass on glass.
   - Sibling glass objects share one container so they sample the same backdrop and can merge. A third stacked glass layer forces the lowest one to `solid1`."
2. In rule 8, change "a sheet or alert may carry its own" to "a sheet or alert may carry its own lit action, drawn as the tinted twin (rule 7)".
3. Apply the rule at each site:
   - §7.10: close button → "`fill2` twin circle 32 with ×, 44 hit".
   - §7.11: add "Alert buttons are the twins of their §7.1 variants (rule 7); the solid `danger` confirm is unchanged".
   - §7.15 and §8.16.1: the accessory's play/pause 44 → "`fill2` twin".
   - §7.35: "actions as `fill2` twin icon buttons".
   - §8.15.5: face tile selected → "`fill2` twin + `selectedRing`".
   - §8.16.2:
     - Artwork card → "`fill2` twin card, radius 20".
     - Play/pause → "72 px tinted twin, the sheet's lit action".
     - Tiles → "three 72 px `fill2` twin tiles".
     - Speaking orb → "a 72 px twin sphere (`fill2` base tinted with the narrator's hue)".
     - The speaker chip and the "Back to the voice" capsule → "`fill2` twin".
   - §9.4.2: "six scene orbs (64 px `fill2` twins)".
   - §9.2.3: the Export capsule and the 44 px accessibility buttons → "`fill2` twins".
4. The §15.7 member counts then stay correct as written.

### CONSISTENCY-2 (medium): press growth and the hero card in the mass table

1. §2.4.1 Medium row, Objects cell: replace "cards and posters (content: scale 1.04, no glass)" with "cards and posters (content, no glass)".
2. Same row, Press growth cell: "+12 px on the longest side (glass); content sinks per the Content sink move (§4.10: cards and posters 0.97, rows 0.99)".
3. Heavy row: replace "the hero card" with "the hero card (content, no glass; the class sets its springs only)".

### CONSISTENCY-3 (medium): glass tiers of buttons, droplets and toasts

1. §2.4.1 Medium row: "Buttons (T2 Pane on black, T3 over media, §7.1; press growth +12 px), dock, accessory, reader capsules, the desktop sidebar, the minimised pill (T3 Slab)".
2. §2.4.2: add the row "`glassFilm` clear (droplets and dragged thumbs) | T1 | `rgba(255,255,255,0.02)` | `dimLegibility` | 2 | 1.4 | `rgba(255,255,255,0.28)` | 0.50 | none | 6 / 12".
3. Use the name "`glassFilm` clear" in place of "`glassThin` clear" and "`glassClear`" in §7.5 (choice droplet twin), §7.6, §7.13, §7.15, §7.16, §7.21, §7.22 and §7.28 (palette droplet).
4. Leave `glassClear` for controls over the hero, the series band and the image viewer only.
5. §7.12: "`glassThin` capsule (T2)".

### CONSISTENCY-4 (medium): tiers of fixed-size lenses, the tooltip and the full player

1. Add to §2.4.3: "The size snap applies to free-sized objects only. Fixed-size lenses keep a declared tier whatever their size:
   - T2 Pane: the object lens (§7.24, 96 px), the source "Opening" lens (§8.11, 96 px), Wrapped card 10's lens (96 px) and the guided-view lens (§9.4.3).
   - T1 Film: the hit lens (§8.14.9)."
2. List the same objects in the §2.4.1 Light and Feather rows.
3. §7.27: "**Tooltip:** `glassThin` capsule (T2), min height 36, padding 9 12, `footnote` `onGlass`".
4. §7.10: add "Exception: the listen full player sheet (§8.16.2) is `glassMonolith` (T5) at `medium` and cross-fades to `solid2` at `large`."

### CONSISTENCY-5 (medium): `sheet` spring and button dismissal

§4.2 `sheet` row, use cell: "Sheet present by button (dismissal by button uses `dismiss`, law 10)".

### CONSISTENCY-6 (medium): §4.6 haptics vs §5.2 events

In §4.6, cite the §5.2 events:

- **Back swipe:** "`threshold.cross` `rigid(0.6)` when the projection crosses the line, `threshold.back` `rigidBack` (soft 0.3) when it crosses back".
- **Image dismiss:** "`threshold.cross` `rigid(0.6)` at the line, `threshold.back` `rigidBack` back".
- **Throw to open** and **Throw away:** "`throw.commit`, `rigid` velocity-scaled `clamp(0.3 + |v| / 4000, 0.3, 1.0)` (0.6 at 1200 px/s)".
- **Magnet capture:** "friend orb and collection targets: `magnet.capture` `selection` on capture, `magnet.drop` `ahap:magnet` on release into it; value detents with magnets: `detent.magnet` `rigid(0.4)`".

### CONSISTENCY-8 (medium): Reduce Motion durations for sheets and the tab switch

1. §4.7 `reducedCrossfade`: "150 ms (in-page and sheets) / 200 ms (routes) linear".
2. §8.0.4: "Reduce Motion: every row becomes a 200 ms cross-fade, except Tab switch (120 ms fade, no wave, §4.10) and Sheet routes (fade + 16 px translate, 150 ms, §4.11)".

### CONSISTENCY-9 (medium): moves missing from the exhaustive motion table

Add these §4.10 rows. Each row lists duration, spring or curve, spec, where used, and Reduce Motion.

| Row | Duration | Spring or curve | Spec | Where used | Reduce Motion |
|---|---|---|---|---|---|
| **Flame flicker** | continuous | tip on `drift` | Lean `0.004 × a` px, tilt and lean together capped at 18 % of the flame height; value noise 2 % of the height at 5 Hz | §9.2.2 | Frozen |
| **Count-up** | settle of `drift` | `drift` | Numeral 0 → value | Wrapped card 2 | Final value |
| **Page pile** | continuous | gravity 2,400 px/s² | Restitution 0.3, ≤ 200 bodies | Wrapped card 3 | At rest |
| **Podium drop** | 120 ms apart | gravity 3,000 px/s², restitution 0.3 | Each item from 200 px above its slot; order #5, #4, #3, #2, #1; #1 lands on `celebrate` with `annual.podium` (CONSISTENCY-43) | Wrapped card 4 | At rest, 150 ms fade |
| **Liquid spinner** | 900 ms per turn, loop | linear rotation | Arc 90° ↔ 270° | §7.19 | Static ring, opacity 0.4 ↔ 1 over 1.2 s |
| **Button dots** | loop | `tick` | 3 px bob, 80 ms phase | §7.19 | Static dots |
| **Count pop** | settle of `tick` | `tick` | 1 → 1.25 → 1 | §7.20 | Count changes with a 150 ms fade |
| **Queued ring** | 4,000 ms per turn | linear | Dashed ring rotates | §7.29 | Static dashed ring |
| **Orb breathe** | 2,000 ms loop | sine | Scale 1 ↔ 1.02 | §8.5 manage mode | Frozen at 1 |
| **Spotlight drop** | settle of `lens` | `lens` | Scale 0.9 → 1 and −24 px → 0 | §8.8 | 200 ms fade in place |
| **Lens pop** | settle of `lens` | `lens` | Scale → 0 with a small ripple | §8.11 | 150 ms fade |
| **Chart rise** | settle of `snappy` per bar | `snappy` wave from the left; radar on `celebrate` | Bars rise from the baseline; radar springs out from the centre | §7.39 | Marks appear with a 150 ms fade |
| **Spoiler unseal** | 160 ms per glyph, 40 ms apart | fade | Guarded reaction glyphs fade in | §9.3 | Glyphs shown at once |
| **Tap light** | 300 ms | fade | 120 px radial light at 10 % white | §8.14.3 | Unchanged (opacity only) |
| **Scene glyph loops** | continuous | per §9.4.2 | Per §9.4.2 | Soundscape picker | Frozen |
| **Quick type** | 12 ms per character | step clock | Line types in | Deal `why` lines, §8.25.15 preview line | Text shown whole |

Then rename the §4.11 entries to these exact names: "flame flicker" → Flame flicker, "podium drop in Wrapped" → Podium drop, "Wrapped page pile" → Page pile.

### CONSISTENCY-10 (medium): settle and overshoot values

1. Replace the §4.2 Settle column, every `--mm-spring-*-ms` in §2.8.5, and every "settle N ms" in §4.10 with the recomputed values (last time |1 − x| > 0.005 from rest).

   | Spring | Settle (ms) |
   |---|---|
   | `track` | 149 |
   | `press` | 253 |
   | `tick` | 289 |
   | `snappy` | 431 |
   | `morph` | 434 |
   | `tab` | 518 |
   | `lens` | 467 |
   | `sheet` | 447 |
   | `sheetSnap` | 342 |
   | `page` | 615 |
   | `zoom` | 558 |
   | `settle` | 414 |
   | `minimize` | 473 |
   | `dismiss` | 378 |
   | `camera` | 392 |
   | `celebrate` | 643 |
   | `drift` | 1064 |
   | `letter` | 345 |
   | `smooth` | 436 |

2. Overshoot: `camera` 0.15 %, `smooth` 0.15 %, `sheet` 0.06 %.
3. Update the dependants:
   - §4.8: "(431 ms) … within 671 ms".
   - §10.1 CSS: the glint delay becomes `var(--mm-spring-letter-ms)`, per CONSISTENCY-21.
   - §10.2: "settles in 289 ms".
   - §15.1 CSS example: `--mm-spring-page-ms: 615ms`.

### CONSISTENCY-11 (medium): `font-variation-settings` on glass text

1. Delete the `.on-glass { … }` rule from §3.5.
2. Write instead: "The `type-<role>` utility (§3.7) already reads `--glass-rond` and `--glass-grad`; optical size comes from `font-optical-sizing: auto`."
3. In §3.7, write the weight axis as `"wght" calc(var(--mm-type-<role>-wght) + var(--press-wght, 0))`, where the press animation drives `--press-wght` from 0 to 40. The press weight then lives in the same declaration.

### CONSISTENCY-12 (medium): undefined slab border variable

In §2.8.3 `border.slab`, add `--mm-border-slab-color: rgba(255,255,255,0.06)` to the Web CSS column, keeping `--mm-border-slab`. The Flutter value stays `BorderSide(color: Color(0x0FFFFFFF), width: 1)`.

### CONSISTENCY-13 (medium): unmapped `edgeSoft` and `glass.json` keys

1. Add to §2.8.4:
   - `dim.edgePlateau` 0.72 → `--mm-dim-edge-plateau: 0.72` / `dimEdgePlateau = 0.72`.
   - `dim.edgeFade` 24 px → `--mm-dim-edge-fade: 24px` / `dimEdgeFade = 24.0`. The edge's blur is the existing `blur.edge` (6).
   - `glass.snap` [36, 57, 97, 401] → TypeScript `glassSnap` / Dart `glassSnap = [36, 57, 97, 401]`.
2. State once that `spring.format` is generator configuration, not a token.

### CONSISTENCY-14 (medium): three rim definitions

1. §2.4.3, Specular rim bullet, add: "Live glass (tiers A and B) draws this gradient. The flat Rim column of §2.4.2 is used only by content twins of that tier."
2. §2.6 `rim`: change the end stop to "`rgba(255,255,255,S × 0.55)` at 100 %".
3. §2.8.4, `glass.t1` to `glass.t5`, add `rim`:
   - CSS `-rim: rgba(255,255,255,0.26 | 0.22 | 0.20 | 0.16 | 0.14)`.
   - Dart `rim: Color(0x42FFFFFF | 0x38FFFFFF | 0x33FFFFFF | 0x29FFFFFF | 0x24FFFFFF)`.
4. §2.4.1 rule 1: write "the rim of the tier it replaces (0.5 px)" in place of "the tier's rim (0.5 px, `rgba(255,255,255,0.22)`)".

### CONSISTENCY-15 (medium): the Tailwind mapping rule

1. Replace the §2.8 rule with: "Each Tailwind name maps to the CSS variable in its own row's Web CSS column:
   - colours `--color-X: var(--mm-color-X)`
   - radius `--radius-X: var(--mm-radius-X)`
   - blur `--blur-X: var(--mm-blur-X)`
   - layout `--spacing-X: var(--mm-layout-X)`
   - springs `--ease-spring-X: var(--mm-spring-X)`
   - curves `--ease-X: var(--mm-ease-X)`."
2. In §2.8.2, rename `--spacing-reader-strip` to `--spacing-reader-strip-max` (utility `w-reader-strip-max`).

### CONSISTENCY-16 (medium): rail poster counts

- §7.9: "(2.8 posters visible at 390 px wide)".
- §8.8 desktop: "Rails show 5.4 (1440 px) to 6.9 (1920 px, where the content column caps at 1440) posters".
- §8.8 tablet: "rails show 3.9 (768 px) to 5.4 (1023 px) posters".

### CONSISTENCY-17 (medium): `g600` as meta text

1. §2.1.1 `g600` role: "Non-text only: chevrons, checkbox and radio borders, dashed rings, the unknown-state tint (≥ 3:1 on black and `surface1`); never text".
2. §14.2: delete "`g600` meta text is used only at 15 px and larger (4.12:1 on `surface1`)" and add "`g600` is never used for text".
3. The hex `#76767F` stays.

### CONSISTENCY-18 (medium): conflicting keys

1. §7.34: change "`x`/`Delete` remove with undo" to "`Delete` remove with undo".
2. §8.13: delete "plus `g` go to chapter" (§8.12's `/` already focuses the go-to field).

### CONSISTENCY-19 (medium): Increase Contrast rendered as solid

1. §15.2 `GlassSurface`: "C "solid" (Reduce Transparency, Solid glass). Increase Contrast is a modifier on tiers A and B: dim clamp 0.40–0.72, `hcBorder`, `label2` → `label1`, `label3` → `label2`, `iris300` accent text, 3 px focus ring."
2. §2.8.4 `dim.legibility`: add `--mm-dim-min-hc: 0.40; --mm-dim-max-hc: 0.72` / `dimMinHc = 0.40`, `dimMaxHc = 0.72`.

### CONSISTENCY-20 (low): three numeric slips

- §2.1.2 `onTint`: "4.66 over a white page".
- §2.1.9: "15.1:1".
- §2.8.1: `colorFill2` = `Color(0x4D787880)`.

### CONSISTENCY-21 (low): letter spring constants and the glint delay

1. Write "k 219.6, c 26.08" in the §10.1 table and in §12.4.
2. Replace `glassSpring.letter = { … stiffness: 220, damping: 26 … }` with the generated `spring.letter` from `tokens.generated.ts`.
3. Set `--stagger` on the heading element (24ms per grapheme, 40ms when per-word).
4. Use `calc(var(--i) * var(--stagger))` for letter delays.
5. Write the glint delay as `calc(var(--n) * var(--stagger) + var(--mm-spring-letter-ms) + 120ms)`.

### CONSISTENCY-22 (low): dispersion multipliers

§2.4.3 Web mapping: "three displacement passes at scale × 1.000 / 1.033 / 1.067 (T4) and × 1.000 / 1.055 / 1.109 (T5)". These give the stated 0 / 0.6 / 1.2 px and 0 / 1.2 / 2.4 px offsets.

### CONSISTENCY-23 (low): legible tracking never applied

1. §3.7: the utility's `letter-spacing: calc(var(--mm-type-<role>-track) + var(--mm-tracking-legible, 0em))`.
2. State that `build.mjs` emits every `-track` value with its `em` unit (for example `-0.02em`).

### CONSISTENCY-24 (low): Atkinson preload

§15.2 `fonts.ts`: "Atkinson_Hyperlegible_Next (`preload: false`; fetched when the boot script stamps `data-legible="on"`, §3.1)".

### CONSISTENCY-25 (low): ambient field opacities

1. §2.1.8 prose: "opacity 10 to 40 % per the source (table below)".
2. Mood row opacity: "the mood's own opacity (§2.1.6)".
3. Add two rows:
   - "Home hero enlargement | the spotlight's cover palette | 36 %"
   - "Image viewer | the viewed image's palette | 40 %"

### CONSISTENCY-26 (low): reader gutter colour

1. §2.1.1 `g50` role: "Reader background option "Graphite" and page placeholders (§8.14.1)".
2. `g25` role: add "page-lit gutter wells (§8.14.11)".
3. §8.14.1: "centred on desktop with the gutters of §8.14.11".

### CONSISTENCY-27 (low): letter reveal placements and blur

1. §10.1 placements: add "8. The Setup title (§8.1) and the profile picker title (§8.5), once per session".
2. §12.4 Wordmark row: "(24 ms stagger, the `letter` spring k 219.6 / c 26.08, blur 12 → 0)".

### CONSISTENCY-28 (low): avatar arc timing

1. Add a §4.10 row: "**Avatar arc** | 280 ms flight, then `tick` landing | parabolic arc (gravity 3,000 px/s²), then `tick` | A copy of the tapped avatar arcs into the live preview; lands with `tick` and `selection` | Profile form avatar pick (§8.6) | The preview takes the avatar with a 150 ms fade".
2. Remove "onboarding avatar pick (§8.6)" from the Cover arc row.

### CONSISTENCY-29 (low): Fit options

§8.25.3: "Fit (Width · Height · Original)".

### CONSISTENCY-30 (low): backup restore confirmation

Remove "staging a backup restore" from the §7.1 hold-to-confirm list, and add "(the backup restore uses the typed confirmation of §8.25.10 instead)".

### CONSISTENCY-31 (low): recap timeout

§7.38, after the 40 s sentence: "Exception: a recap whose sheet was closed stays alive in the background for up to 60 s from the request (§9.1.3); the 40 s limit applies while its sheet is open."

### CONSISTENCY-32 (low): novel chapter end

1. Remove "novel end" from the §4.10 Chapter card rise row.
2. Add a row: "**Novel next** | settle 615 ms | `page` | The Next card locks at 72 displayed px; the next chapter slides up in place | Novel chapter end (§8.15.2) | 200 ms cross-fade".

### CONSISTENCY-33 (low): speed dial ticks

§5.2 `detent.tick`: "…, one per step (the speed dial: one per 0.25×; its 0.05 steps are silent)".

### CONSISTENCY-34 (low): reaction landing and tab indicator springs

1. §2.7 Reactions row: "Scale 0.6 → 1 on `tick` with a 6-particle burst in `bloom` (the landing of §9.3.2)".
2. §4.10 Tab droplet row: remove "in-page tab indicator" and add "(the in-page tab indicator follows its pager and settles with it on `settle`, §7.13)".

### CONSISTENCY-35 (low): orb sizes, picker hover, flame sizes

1. §7.26 sizes: "24 (chips), 32 (sidebar, activity rows), 44 (nav row), 56 (avatar grid, drop targets, presence arc), 72 (You), 96 (picker, phone), 112 (friend sheet), 128 (picker, desktop), 132 (picker focus)".
2. §7.26 hover: "scale 1.04 (picker: 1.08, §8.5) + specular sweep".
3. §9.2.2 sizes: add "20 (milestone toast)".

### CONSISTENCY-36 (low): MM column geometry

1. §2.7 `mm-mark`: "the §12.1 geometry on the 256 grid: M boxes x 60–196; top M y 48–120; gutter bar x 60–196, y 120–136; bottom M y 136–208; M strokes 22 units".
2. §12.2: "bows 2 px at 64 px cap height, 9 units on the 1024 master".

### CONSISTENCY-37 (low): type-role usage notes

§3.2: "`caption2` (micro labels)" and "`tabLabel` (dock labels)".

### CONSISTENCY-38 (low): bare-frame phone margins

1. §8.0.1 Bare: "content column max 420 (phone: full width minus the §2.2 screen margins, 16 px up to 413 px wide and 20 px from 414 px)".
2. §8.3: "the same column full width with the §2.2 screen margins".

### CONSISTENCY-39 (low): manga zoom limit

§4.5: "Zoom below 1× and above 3× (manga strip), below 1× and above 4× (manga paged and the image viewer)".

### CONSISTENCY-40 (low): brightness HUD size

§8.14.3: "a 36 × 140 `glassThin` HUD capsule (T2): a 16 px sun glyph at the top, the fill level inside, the value in `caption1` `onGlass` at the bottom".

### CONSISTENCY-41 (low): dense twin fill for dialogue boxes

1. §2.4.1 rule 1: add "Text-bearing twins over art (the dialogue boxes, §8.14.9) use `twinDense` `rgba(19,19,23,0.82)`".
2. §2.8.1: add `color.twinDense` → `--mm-color-twin-dense: rgba(19,19,23,0.82)` / `--color-twin-dense` / `colorTwinDense = Color(0xD1131317)`.
3. §8.14.9: cite `twinDense`.

### CONSISTENCY-42 (low): sheet id table

1. Merge `save-files` into one row, "Series, book and Downloads".
2. Move `run` to a new row, "Updates | `run` (update-run detail, §8.21)".

### CONSISTENCY-43 (low): cues that are not contract events

1. Add three events to §5.2, §6 and the §15.6 Glass-added list:
   - `annual.podium` → haptic `success`, sound `add`.
   - `annual.summary` → haptic none, sound `shimmer`.
   - `logo.reduced` → haptic `light`, sound none.
2. §6 `shimmer` row: replace "the Wrapped summary card" with `annual.summary`.
3. §9.2.3 and §12.4: cite these event names.
4. §15.10 G8: "the sound-only `sheet.open` and `sheet.close`".

### CONSISTENCY-44 (low): six single values

- §7.20: "`mature` at 18 %".
- §7.1 hold-to-confirm: "`iris600` at 60 %".
- §7.1 progress button: "the fill level follows progress on `lens`".
- §7.17: "leading icon tile (30 × 30, radius `rIconTile` 12, …)".
- §7.7 focused: "ring + scale 1.04 (cards and posters)".
- §8.15.5: "`medium` sheet (52 %, §7.10)".

### CONSISTENCY-45 (low): values with no token key

1. Add these §2.8.5 rows (web CSS `--mm-…`, TypeScript constant, Flutter field):
   - **Thresholds:**
     - `threshold.doubleTapSlop` 24
     - `threshold.imageDismissVelocity` 800
     - `threshold.dragSlopTouchScroll` 18
     - `threshold.stackLongPressWebTouch` 500
     - `threshold.pullRest` 60
     - `threshold.dockHide` 20
     - `threshold.dockShow` 12
     - `threshold.sidebarCollapse` 1180
     - `threshold.topCapsule` 400
   - **Physics:**
     - `physics.impactMinInterval` 120
     - `physics.rubberBandChapterC` 0.35
     - `physics.gravitySplash` 9000
     - `physics.gravityArc` 3000 (avatar, cover and droplet arcs, dots merge, podium)
     - `physics.gravityReaction` 2400 (also the Wrapped page pile)
     - `physics.emberRise` 300
     - `physics.genreRestitution` 0.4
     - `physics.genreCentreK` 4
   - **Spring:** `spring.splashLens` `{ms: 468, bounce: 0.18}` (k 180.0, c 22.0), used by §12.4 and the Droplet reveal row in place of "a spring (k 180, c 22)".
2. §15.11: `fantasticon` version "3.0.0" (exact), status "added here (build only)". `cinematic/DESIGN.md` does not use it, so "reused" is wrong.

---

## Refuted (1)

- **CONSISTENCY-7.** The row's explicit Duration column is authoritative, and the named curve supplies only the easing, so nothing needs guessing. No fix needed.
