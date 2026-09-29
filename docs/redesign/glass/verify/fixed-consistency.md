# Glass DESIGN.md: fixes applied from the internal-consistency judge

## Round 1

Source: `glass/verify/judge-consistency.md`, section "Confirmed" (44 findings; CONSISTENCY-7 was refuted and is not applied). Every fix was applied as the judge rewrote it, except where noted. Section numbers refer to `glass/DESIGN.md`. No screens were added or removed, so Appendix B (Coverage) is unchanged.

| ID | Sections changed |
|---|---|
| CONSISTENCY-1 | §2.4.2 rule 7 rewritten (content twin for controls on glass: `fill2` `rgba(120,120,128,0.30)`, 0.5 px rim `rgba(255,255,255,0.22)`, no backdrop read, not a `BackdropGroup` member; tinted twin for the host's lit action with no caustic; droplet and Wrapped card 10 lens exceptions; blooms are a second stacked layer) and rule 8 ("lit action, drawn as the tinted twin"); §7.10 Header close button; §7.11 Buttons; §7.15 accessory play/pause; §8.16.1 play/pause; §7.35 bulk toolbar actions; §8.15.5 face tiles; §8.16.2 artwork card, speaking orb, speaker chip, play/pause (72 px tinted twin), tiles, "Back to the voice" capsule; §9.4.2 scene orbs; §9.2.3 Export capsule and the 44 px accessibility buttons |
| CONSISTENCY-2 | §2.4.1 mass table Medium row (cards and posters "content, no glass"; press growth cell cites the Content sink move, 0.97 / 0.99) and Heavy row (hero card marked content, class sets springs only) |
| CONSISTENCY-3 | §2.4.1 Medium row (buttons T2 on black, T3 over media); §2.4.2 new `glassFilm` clear row (T1, fill 0.02, rim 0.28, S 0.50, blur 2, saturate 1.4); "`glassFilm` clear" in §7.5 choice droplet, §7.6 dragged thumb, §7.13 indicator, §7.15 dock droplet, §7.16 sidebar droplet, §7.21 slider thumb, §7.22 switch knob, §7.28 palette droplet; `glassClear` kept for the hero, series band and image viewer; §7.12 toast `glassThin` (T2) |
| CONSISTENCY-4 | §2.4.3 new paragraph (size snap is for free-sized objects; fixed-size lenses: T2 object lens, source "Opening" lens, Wrapped card 10 lens, guided-view lens; T1 hit lens); §2.4.1 Light and Feather rows list them; §7.27 tooltip `glassThin` (T2), min height 36, padding 9 12; §7.10 Geometry exception for the listen full player (`glassMonolith` at `medium`, `solid2` at `large`) |
| CONSISTENCY-5 | §4.2 `sheet` row use cell (present by button; dismissal uses `dismiss`, law 10) |
| CONSISTENCY-6 | §4.6 Back swipe, Image dismiss, Throw to open, Throw away and Magnet capture rows cite the §5.2 events (`threshold.cross` / `threshold.back`, velocity-scaled `throw.commit`, `magnet.capture` / `magnet.drop`, `detent.magnet`) |
| CONSISTENCY-8 | §4.7 `reducedCrossfade` (150 ms in-page and sheets / 200 ms routes); §8.0.4 Reduce Motion sentence (Tab switch and Sheet routes exceptions) |
| CONSISTENCY-9 | §4.10 sixteen new rows (Flame flicker, Count-up, Page pile, Podium drop, Liquid spinner, Button dots, Count pop, Queued ring, Orb breathe, Spotlight drop, Lens pop, Chart rise, Spoiler unseal, Tap light, Scene glyph loops, Quick type); §4.11 Reduce Motion table names aligned (Flame flicker, Podium drop, Page pile) |
| CONSISTENCY-10 | §4.2 Settle column (all 19 springs) and Overshoot (`camera` 0.15 %, `smooth` 0.15 %, `sheet` 0.06 %); §2.8.5 every `--mm-spring-*-ms`; §4.10 every "settle N ms" (56 values, mapped per spring); §4.8 cap (431 ms, 671 ms); §10.1 glint delay reads `--mm-spring-letter-ms`; §10.2 (settles in 289 ms); §15.1 CSS example (`--mm-spring-page-ms: 615ms`) |
| CONSISTENCY-11 | §3.5 Implementation (the `.on-glass` rule deleted; the `type-<role>` utility reads `--glass-rond` / `--glass-grad`, optical size from `font-optical-sizing: auto`); §3.7 utility weight axis `calc(var(--mm-type-<role>-wght) + var(--press-wght, 0))` with `--press-wght` 0 → 40 |
| CONSISTENCY-12 | §2.8.3 `border.slab` Web CSS adds `--mm-border-slab-color: rgba(255,255,255,0.06)` |
| CONSISTENCY-13 | §2.8.4 new rows `dim.edgePlateau` (0.72), `dim.edgeFade` (24 px; blur is `blur.edge`) and `glass.snap` ([36, 57, 97, 401]), plus the note that `spring.format` is generator configuration; §2.8 short-name bullet maps `edgeSoft` (and `twinDense`) |
| CONSISTENCY-14 | §2.4.3 Specular rim bullet (live glass draws the gradient; the flat Rim column is for content twins); §2.6 `rim` end stop `S × 0.55`; §2.8.4 `glass.t1`–`glass.t5` gain `rim` (CSS `-rim: 0.26 / 0.22 / 0.20 / 0.16 / 0.14`, Dart `0x42 / 0x38 / 0x33 / 0x29 / 0x24FFFFFF`); §2.4.1 rule 1 ("the rim of the tier it replaces"). Also added `rim` to the `t2` and `t4` entries of the §15.1 `glass.json` example so the example matches the tier shape |
| CONSISTENCY-15 | §2.8 Tailwind bullet (per-namespace mapping rule); §2.8.2 `--spacing-reader-strip-max` (`w-reader-strip-max`) |
| CONSISTENCY-16 | §7.9 (2.8 posters at 390 px); §8.8 Tablet (3.9 at 768 px to 5.4 at 1023 px). The §8.8 desktop sentence already read "4.8 at 1024 px, 5.4 at 1440 px and 6.9 at 1920 px" (from WEB-4) and matches the judge's numbers, so it was left as is |
| CONSISTENCY-17 | §2.1.1 `g600` role (non-text only, never text); §14.2 ("`g600` is never used for text"); hex `#76767F` unchanged |
| CONSISTENCY-18 | §7.34 keys (`Delete` only). The §8.13 bare `g` had already been removed by WEB-7 |
| CONSISTENCY-19 | §15.2 `GlassSurface.tsx` tree row (tier C is Reduce Transparency and Solid glass; Increase Contrast is a modifier on tiers A and B); §2.8.4 `dim.legibility` adds `--mm-dim-min-hc: 0.40; --mm-dim-max-hc: 0.72` / `dimMinHc`, `dimMaxHc` |
| CONSISTENCY-20 | §2.1.2 `onTint` (4.66 over a white page); §2.1.9 (15.1:1); §2.8.1 `colorFill2` = `Color(0x4D787880)` |
| CONSISTENCY-21 | §10.1 parameter table (k 219.6, c 26.08); §10.1 TSX (`--stagger` on the heading, 24ms / 40ms) and CSS (`calc(var(--i) * var(--stagger))`, the per-word 40 ms rule folded in, glint `calc(var(--n) * var(--stagger) + var(--mm-spring-letter-ms) + 120ms)`); §10.1 interruptible variant uses the generated `spring.letter`; §12.4 Wordmark row |
| CONSISTENCY-22 | §2.4.3 Web mapping dispersion multipliers (× 1.000 / 1.033 / 1.067 for T4, × 1.000 / 1.055 / 1.109 for T5) |
| CONSISTENCY-23 | §3.7 utility `letter-spacing: calc(var(--mm-type-<role>-track) + var(--mm-tracking-legible, 0em))` and the note that `build.mjs` emits `-track` with its `em` unit |
| CONSISTENCY-24 | §15.2 `fonts.ts` row (Atkinson `preload: false`, fetched when `data-legible="on"` is stamped) |
| CONSISTENCY-25 | §2.1.8 field prose (10 to 40 % per the source); mood row uses the mood's own opacity (§2.1.6); new rows Home hero enlargement (36 %) and Image viewer (40 %) |
| CONSISTENCY-26 | §2.1.1 `g50` role (Graphite and page placeholders) and `g25` role (page-lit gutter wells); §8.14.1 Strip (gutters of §8.14.11) |
| CONSISTENCY-27 | §10.1 placement 8 (Setup and profile picker titles); §12.4 Wordmark row (blur 12 → 0) |
| CONSISTENCY-28 | §4.10 new Avatar arc row (280 ms flight, `tick` landing); "onboarding avatar pick" removed from the Cover arc row |
| CONSISTENCY-29 | §8.25.3 Fit (Width · Height · Original) |
| CONSISTENCY-30 | §7.1 Hold-to-confirm list (backup restore removed; it uses the typed confirmation of §8.25.10) |
| CONSISTENCY-31 | §7.38 thinking states (the 60 s background exception for a closed recap sheet) |
| CONSISTENCY-32 | §4.10 Chapter card rise row ("novel end" removed) and new Novel next row (`page`, settle 615 ms) |
| CONSISTENCY-33 | §5.2 `detent.tick` (speed dial: one per 0.25×; 0.05 steps silent) |
| CONSISTENCY-34 | §2.7 Reactions motion row (`tick`, the landing of §9.3.2); §4.10 Tab droplet row (in-page tab indicator follows its pager and settles on `settle`, §7.13) |
| CONSISTENCY-35 | §7.26 orb sizes (56, 72, 96 phone, 112, 128 desktop added) and hover (picker 1.08); §9.2.2 flame sizes (20 for the milestone toast) |
| CONSISTENCY-36 | §2.7 `mm-mark` (the §12.1 geometry on the 256 grid); §12.2 gutter bow (9 units on the 1024 master) |
| CONSISTENCY-37 | §3.2 `caption2` (micro labels). The `tabLabel` row already read "dock labels" (from WEB-2) |
| CONSISTENCY-38 | §8.0.1 Bare frame (the §2.2 screen margins, 16 px up to 413 px, 20 px from 414 px); §8.3 Login mobile layout (the §2.2 screen margins) |
| CONSISTENCY-39 | §4.5 zoom row (3× manga strip; 4× manga paged and the image viewer) |
| CONSISTENCY-40 | §8.14.3 brightness HUD (36 × 140 `glassThin` capsule, T2, 16 px sun glyph, `caption1` value) |
| CONSISTENCY-41 | §2.4.1 rule 1 (`twinDense` for text-bearing twins over art); §2.8.1 new `color.twinDense` row (`rgba(19,19,23,0.82)`, `Color(0xD1131317)`); §8.14.9 boxes cite `twinDense` |
| CONSISTENCY-42 | §8.0.3 sheet id table (`save-files` in one "Series, book and Downloads" row; `run` moved to a new Updates row) |
| CONSISTENCY-43 | §5.2 new events `annual.podium` (`success`), `annual.summary` (none, sound only) and `logo.reduced` (`light`); §6 `add` cue gains `annual.podium`, `shimmer` cue uses `annual.summary`; §15.6 Glass-added list; §9.2.3 card 4 and Sound line cite the events; §12.4 Reduce Motion cites `logo.reduced`; §15.10 G8 (`sheet.open` and `sheet.close`) |
| CONSISTENCY-44 | §7.20 18+ badge (18 %); §7.1 hold fill (`iris600` at 60 %); §7.1 progress button (fill on `lens`); §7.17 icon tile (radius `rIconTile` 12); §8.15.5 Aa sheet (`medium`, 52 %). §7.7 focused already read "scale 1.04", so it was left as is |
| CONSISTENCY-45 | §2.8.5 new threshold rows (`doubleTapSlop` 24, `imageDismissVelocity` 800, `dragSlopTouchScroll` 18, `stackLongPressWebTouch` 500, `pullRest` 60, `dockHide` 20, `dockShow` 12, `sidebarCollapse` 1180, `topCapsule` 400), physics rows (`impactMinInterval` 120, `rubberBandChapterC` 0.35, `gravitySplash` 9000, `gravityArc` 3000, `gravityReaction` 2400, `emberRise` 300, `genreRestitution` 0.4, `genreCentreK` 4) and `spring.splashLens` `{ms: 468, bounce: 0.18}` (k 180.0, c 22.0; computed settle 532 ms, overshoot 1.1 %); §4.2 gains a matching `splashLens` row so the spring table stays complete; §12.4 Lens grows row and the §4.10 Droplet reveal row cite `splashLens`; §15.11 `fantasticon` 3.0.0 (exact), "added here (build only)" |

## Round 2

Source: the six items that `glass/verify/recheck-consistency-1.md` left unresolved (CONSISTENCY-1, 3, 10, 13, 25, 34). The other 38 confirmed findings were resolved in round 1 and were not touched again. No screens were added or removed, so Appendix B (Coverage) is unchanged.

| ID | Sections changed |
|---|---|
| CONSISTENCY-1 | §8.16.2 Header ⋯ (a trailing `fill2` twin circle 32, 44 hit, §2.4.2 rule 7, the recipe of the §7.10 close button); §7.21 Fill slider (the 72 × 160 capsule is drawn as the `fill2` twin, because it always sits on a glass host: the phone reader sheet of §8.14.5, or the `materialThick` right panel on desktop); §9.2.3 Accessibility (the close button is also a `fill2` twin on the frame); §15.7 Takeovers row (picker and onboarding: close or back button 1; Wrapped: frame 1 + card lens 1, its close button a twin; total **2**, Flutter 2 / 2) |
| CONSISTENCY-3 | §7.6 Vertical variant (the "`glassFilm` clear" droplet indicator); §2.4.2 "`glassFilm` clear" row blur 2 → 1 (the `glass.clear` finish's blur); §2.8 short-name bullet maps "`glassFilm` clear" → `glass.t1` + `glass.clear` (no new token) |
| CONSISTENCY-10 | §4.10 Skin melt row (615 ms, ended by the `page` settle; its cross-reference corrected from "§8.25.2 step 4" to "step 3", where the melt is described); §8.25.2 step 3 ("the melt", 615 ms) |
| CONSISTENCY-13 | §2.8.4: the `caustic` row moved back up under `glass.snap` so the table is contiguous; the `spring.format` note now follows the table after a blank line |
| CONSISTENCY-25 | §2.1.8 "Settings, You, admin, auth, onboarding" opacity cell adds "the brand aurora (auth, setup, onboarding) 20 %" |
| CONSISTENCY-34 | §4.2 `celebrate` use cell ("reaction sent" dropped; "the podium #1 landing" added, matching the §4.10 Podium drop row) |

## Round 3

Source: the three items that `glass/verify/recheck-consistency-2.md` left unresolved (CONSISTENCY-4, 35, 45). The other 41 confirmed findings were resolved in rounds 1 and 2 and were not touched again. No screens were added or removed, so Appendix B (Coverage) is unchanged. No token, motion, haptic or sound value changed.

| ID | Sections changed |
|---|---|
| CONSISTENCY-4 | §8.16.2 Sentence list: "others in `label2` (6.08:1 on `solid2`; …)", matching the §7.10 Geometry exception that makes the listen full player `solid2` at `large` (the only detent where the list shows) |
| CONSISTENCY-35 | §7.26 Profile orb size list gains 18 (Friend badge, §7.20) and 20 (shared-collection adder, §9.3.3); §7.26 Friend orb bullet now reads "18 px as the Friend badge (§7.20), 32 px in activity rows (§9.3.1), 56 px as drop targets and in the presence arc" |
| CONSISTENCY-45 | §4.2 `lens` use cell: "the splash lens" replaced by "the splash droplet's impact squash (§12.4)"; the lens itself stays on `splashLens` (§4.2, §2.8.5, §12.4) |

## Round 4 (main session)

- CONSISTENCY-4 (reopened by STACK-6): §15.3 Driven values now carries the player-sheet exception (T5 at medium, solid2 at large) that §7.10 and §8.16.2 already state.
