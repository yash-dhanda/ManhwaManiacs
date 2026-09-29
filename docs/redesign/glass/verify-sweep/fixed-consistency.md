# Glass DESIGN.md: consistency sweep fixes

## Round 1

Source: `judge-consistency.md`, "Confirmed" section (26 findings). All 26 applied to `glass/DESIGN.md`. CONSISTENCY-19 and CONSISTENCY-21 were refuted by the judge and not touched. No screen was added or removed, so Appendix B (Coverage) is unchanged.

| Id | Sections changed |
|---|---|
| CONSISTENCY-1 | §2.4.3 size snap (`≥ 97 → T4`, T5 declared only for Massive objects); §2.8.4 `glass.snap` row (value, TypeScript and Dart cells now `[36, 57, 97]`); §15.1 `glass.json` sample `"snap"`; §15.8 physics fixture `tierFor(401) == T4`; §7.10 **Desktop** (panel and window bodies T4, the listen player's window the one T5); §8.25.14 licences ("desktop T4 window") |
| CONSISTENCY-2 | §7.10 **Desktop** (exception: the 960 px series and book window is a `materialThick` slab over the 0.97 / blur 8 / `rgba(0,0,0,0.50)` recession; every other panel and window over `dimSheet` only); §8.12 **Presentation** ("50 % brightness (`rgba(0,0,0,0.50)`)"); §15.2 *Mechanism* recession parenthesis; §2.3 `r2xl` use cell (desktop windows 560 and 960 px, desktop Login slab); §2.3 `rXl` use cell gains "desktop side panels (§7.10)" |
| CONSISTENCY-3 | §4.6 "Magnet capture" row split into Object magnet, Value magnet and Step magnetism rows; §2.8.5 new `physics.valueMagnetSpeed` (0.08) and `physics.valueMagnetStepFraction` (0.30) rows; §15.1 `glass.json` `physics` object |
| CONSISTENCY-4 | §2.4.1 Feather row Press growth (per component: droplets +6 %, slider thumb 28 → 34, switch knob 27 → 34 × 27; segmented thumb, scrub thumb and hit lens stretch only); §2.4.1 Light row Press growth (chips at rest sink to 0.96); §4.10 Press swell Spec |
| CONSISTENCY-5 | §7.34 **Full swipe** (the 10 s Undo toast of §7.12) |
| CONSISTENCY-6 | §3.2 `display` row use; §9.2.3 card 2 (**Time**) numeral; §9.2.4 **Design** big numeral (`wrappedNumeral`, 264 px on the canvas) |
| CONSISTENCY-7 | §3.7 new **Overrides** paragraph after the `GlassText` paragraph (`GlassText(role:, text, {wght, size, height})`, web inline custom properties, `mono`-only size overrides) |
| CONSISTENCY-8 | §9.4.3 **Counter** (overview button, `squares-four` 20, 44 hit, labels); §7.37 **Accessibility** ("All levels" custom semantics action, `aria-keyshortcuts`); §11 Long-press Back alternative cell |
| CONSISTENCY-9 | §8.14.7 and §8.14.11 Esc order (dialogue overlay and hit lens, guided view added); §8.0.5 Android back order intro |
| CONSISTENCY-10 | §7.30 **App update capsule** placement (phones: top-band queue of §7.12; tablet and desktop: bottom-centre of the content column) |
| CONSISTENCY-11 | §7.35 **Reorder** trigger (450 ms opens the §7.23 preview; a 10 px drag turns it into the reorder lift, `dimContext` out over 180 ms; the handle lifts at once) |
| CONSISTENCY-12 | §4.10 **Throw** row (spring and duration cells: `zoom` 558 ms to open, `dismiss` 378 ms for AI cards thrown away) |
| CONSISTENCY-13 | §4.2 `snappy` use cell (segmented thumb removed) and `tab` use cell (segmented thumb added, §7.6); §7.16 sidebar width change on `minimize`; §4.10 **Minimise** Where cell (desktop sidebar `mod+b`) |
| CONSISTENCY-14 | §4.10 **Fan open**; §8.18 **Signature moment** (−24°, −8°, 8°, 24°; three, two and one cover variants) |
| CONSISTENCY-15 | §7.20 **Downloaded** row (14 in rows and lists, 16 on the cover disc) |
| CONSISTENCY-16 | §2.7 glyph size table, Ornamental row (lenses 44, format cards 40, Wrapped 48 to 64; size cell 40 to 64) |
| CONSISTENCY-17 | §8.0.5 **Who owns a horizontal drag** (24 px = PWA back strip and Safari edge rule; readers' strip is 20 px) |
| CONSISTENCY-18 | §11 "Swipe a row left or right" row (content-twin action pills, §7.34) |
| CONSISTENCY-20 | §2.1.9 Warmth row job cell (favourite star, Statistics best-day dot) |
| CONSISTENCY-22 | §7.26 **Profile orb** sizes (24 includes the dock's You tab; presence arc 56 to 64); §7.26 **Friend orb** (56 to 64 in the presence arc) |
| CONSISTENCY-23 | §7.22 **Switch** knob shadow; §4.10 **Page slide**, §8.14.1 **Paged** and §8.15.4 **Slide** edge shadow; §4.10 **Lens pop** and §8.11 signature moment ring; §4.10 **Deal** and §9.1.2 signature moment Bézier; §4.10 **Orbs fly out** and §9.3.4 menu path Bézier with the sign rule; §9.3.2 sending state |
| CONSISTENCY-24 | §2.8.1 new `color.backingDisc`, `color.coverBacking`, `color.coverDisc` rows; key citations in §2.1.2 (backing disc), §2.4.1 rule 1, §7.8 **Overlays**, §7.20 Status tag, 18+ and Downloaded rows; §15.8 Backing disc and Cover overlays cases |
| CONSISTENCY-25 | §15.10 G6 (`palette {a, l, lMax}`) |
| CONSISTENCY-26 | §8.15.1 intro (13.4 to 17.8:1, muted 5.8 to 6.6:1) |
| CONSISTENCY-27 | §3.3 text-scale table, M row Android cell `n/a` |
| CONSISTENCY-28 | §7.19 **Linear** (0.6 % overshoot, 431 ms, fill clipped to the track) |

## Round 2

Source: `judge-consistency.md` "Confirmed" section, with the three findings `recheck-consistency-1.md` left unresolved. The other 23 were re-checked by residue grep (no old value is back) and needed no edit. No screen was added or removed, so Appendix B (Coverage) is unchanged.

| Id | Sections changed |
|---|---|
| CONSISTENCY-7 | §3.7 **Overrides** paragraph: signature extended to `GlassText(role:, text, {int? wght, double? size, double? height, double? trackingEm, String? family, bool italic = false})`; web equivalents (`[--mm-type-<role>-track:…em]`, `font-mono` / `font-serif` beside `type-<role>`, `italic`); uppercase stated as a text transform, not an override; the closed sentence replaced by an exhaustive list: Weight, Size and height (`mono` 12/16 in §8.15.2 and the §8.25.14 licence text 13/20 added), Tracking (`caption1` 0.06 / 0.08 / 0.18 / 0.2 / 0.22 em, `footnote` 0.04 em, each with its section), Family (`title3` Literata in §8.16.2; `wrappedNumeral` in Google Sans Code during the §9.2.3 count-up only), Italic (`footnote` `why` line, §7.7, as a synthesized 14° oblique because Google Sans Flex ships with `slnt` pinned to 0). §8.15.2 **Chapter header**: word count and reading time now `mono` 12/16 with a pointer to the §3.7 override. |
| CONSISTENCY-8 | §7.37 **Accessibility**: `aria-keyshortcuts="Control+\"` (`Meta+\` on macOS), with a note that the token is the KeyboardEvent `key` value, never the `code` value `Backslash`. §11 unchanged. |
| CONSISTENCY-10 | §7.30 **App update capsule**: desktop keeps bottom-centre of the content column with the bar wait rule; tablet now sits 12 px above the floating accessory (24 px from the window bottom without one), with the same wait rule, and also waits while a window, panel or menu is open. §7.12 **Top-band priority**: every item of the queue (toast, new-chapters capsule, app-update capsule) waits while a menu or context menu is open, and one already showing leaves on `dismiss` (toast timer paused) and falls back in on `snappy` when the menu closes. §15.7 budget table: phone row counts "toast or capsule or menu" (still 5 web, 4 / 8 Flutter); the tablet frame is split from the Flutter desktop frame and now counts the floating accessory (sidebar, toolbar group, accessory, toast or new-chapters capsule, window or panel, menu = 6 / 6). |

## Round 3

Source: `judge-consistency.md` "Confirmed" section, with the one finding `recheck-consistency-2.md` left unresolved. The other 25 were re-checked by residue grep (no old value is back: `97–400`, `> 400 →`, `401]`, `dim 50`, "Magnet capture", "detents with magnets", `5 s Undo`, "Wrapped numbers", `±12°`, "short arc", "small ripple", "soft shadow", "glass action pill", `palette {a, l}`, "13 to 15:1", "about 5.9", "overshoots nothing", "settles in 0.4", "like the reader's strip", `Control+Backslash`, `Meta+Backslash` all 0) and by presence of the new values; they needed no edit. No screen was added or removed, so Appendix B (Coverage) is unchanged.

| Id | Sections changed |
|---|---|
| CONSISTENCY-7 | §3.7 **Overrides**, Weight bullet: "any role, wherever this contract names a weight: §7 to §10, the §4.10 Plus one chip (`caption1` 700), and the §2.1.2 rule that sets text a spec dims by opacity inside T4 and T5 glass in `onGlass` at `wght` 460". Both cited overrides were confirmed in place first (§4.10 Plus one row; §2.1.2 "Text that a spec dims by opacity inside such a surface uses `onGlass` at `wght` 460", where "such a surface" is T4 and T5 glass). No other line changed. |
