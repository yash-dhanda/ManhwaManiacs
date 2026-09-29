# Glass DESIGN.md: consistency recheck, round 1

Input: the 26 findings in the "Confirmed" section of `glass/verify-sweep/judge-consistency.md` (CONSISTENCY-19 and CONSISTENCY-21 were refuted and are out of scope). Target: `glass/DESIGN.md` in the working tree on 2026-09-29 (4,621 lines, uncommitted on top of `d522dba`). Method: each final fix was compared with the edited lines, `git diff -U0 --word-diff` confirmed the exact before and after text, and every old value that the fix replaced was grepped for across the whole file, along with every other place the changed value is repeated. DESIGN.md was not edited. Line numbers below are from the current file.

Result: **23 resolved, 3 unresolved** (CONSISTENCY-7, CONSISTENCY-8, CONSISTENCY-10). Each of the three fixes went in exactly as the judge wrote it. In each case, though, the judge's own wording creates a new defect: a closed list that the rest of the file contradicts, an invalid ARIA token, and a placement that collides with the tablet accessory.

---

## Per-finding verdicts

| Id | Verdict | Evidence (current lines) and residue grep |
|---|---|---|
| 1 | Resolved | §2.4.3 L414 snaps `≥ 97 → T4` and declares T5 only for the Massive objects; §2.8.4 L785 `glass.snap` value and Dart cell are `[36, 57, 97]` (the TypeScript cell names the constant only); §15.1 L4116 `"snap": [36, 57, 97]`; §15.8 L4389 `tierFor(401) == T4`; §7.10 L1740 "Panel and window bodies are T4 glass (`glassThick`); the one T5 window is the listen player's"; §8.25.14 L3112 "the desktop T4 window". Grep: no `401` left in any snap context, no `> 400`, and no "desktop T5 window". The remaining T5 uses (L353, L382, L2845, L2849, L4249, L4395) are all Massive objects. |
| 2 | Resolved | §7.10 L1740 carries the 960 px slab exception word for word (`rgba(19,19,23,0.84)`, blur 36, radius 32, scale 0.97, `blur.recede` 8, `rgba(0,0,0,0.50)`, `--sheet-progress`, every other window over `dimSheet`); §8.12 L2576 "50 % brightness (`rgba(0,0,0,0.50)`)"; §15.2 L4197 parenthesis as specified; §2.3 L319 `r2xl` "Desktop windows (560 and 960 px) and the desktop Login slab (§8.3); desktop panels stay `rXl` 26", and L318 `rXl` gains "desktop side panels (§7.10)". Grep: no `dim 50` left. §8.3's Login slab is radius 32. §8.13 L2598 reuses §8.12's window. |
| 3 | Resolved | §4.6 L1141–1143: three rows (Object magnet, Value magnet, Step magnetism) with the fix's text and haptics; §2.8.5 L835–836 `physics.valueMagnetSpeed` 0.08 and `physics.valueMagnetStepFraction` 0.30 (Flutter `physicsValueMagnetSpeed`, `physicsValueMagnetStepFraction`); §15.1 L4126 `"valueMagnetSpeed": 0.08, "valueMagnetStepFraction": 0.30` beside `"magnetRadius": 64`. Cross-checks: §8.16.3 L2862 "±0.08 … `detent.magnet`" and §7.21 L1896 "within 30 % of a step's spacing" match; §5.2 L1425 limits `detent.magnet` to speed, cruise and the 30-minute interval; 0.08 / 0.05 × 6 = 9.6 px and × 8 = 12.8 px are correct. |
| 4 | Resolved | §2.4.1 Feather row L349 and Light row L350 read as the fix; §4.10 Press swell L1204 "+12 px (Medium) or +17 px capped at 0.35 × side (Light); Feather objects grow per their component (§2.4.1)". Cross-checks: §7.15 L1806 "grows 6 %", §7.21 thumb 28 → 34, §7.22 knob 34 × 27, §4.10 Content sink L1205 chips 0.96. The Light row keeps `snappy`. |
| 5 | Resolved | §7.34 L2047 "the 10 s Undo toast of §7.12". Grep for `5 s Undo` finds nothing; §7.12 L1778 still says 10 s with Undo. |
| 6 | Resolved | §3.2 L913 `display` "(splash wordmark, hero titles, Wrapped card 1 headline)"; §9.2.3 L3328 "the `wrappedNumeral` numeral"; §9.2.4 L3367 "`wrappedNumeral` (88 px × 3 = 264 px on the canvas)". Card 1 L3343 is `display` 44/48. The Code-digit count-up that L3328 and L3339 describe is covered under CONSISTENCY-7 below. |
| 7 | **Unresolved** | The Overrides paragraph is present at L1007 word for word, but its closed list is contradicted elsewhere in §7 to §9. See below. |
| 8 | **Unresolved** | §9.4.3 L3491 counter overview button, §7.37 L2075 "All levels" action and §11 L3845 alternative cell are all applied as written, and the §11 pinch-out row L3867 now points to a button that exists. The problem is that the fix's web value `aria-keyshortcuts="Control+Backslash"` is not a valid ARIA token. See below. |
| 9 | Resolved | §8.14.7 L2700 and §8.14.11 L2727: "menu or popover → dialogue overlay and hit lens → guided view (back to the strip at the current panel) → side panel (desktop) → fullscreen → cinema → leave the reader". §8.0.5 L2272: "It follows the same order as the web's `Esc` (§8.0.6, §8.14.7); side panels and fullscreen do not exist on phones". Android rows 6 to 8 (dialogue overlay, guided view, cinema) follow the same order. §9.4.3 Exit (Esc) matches. |
| 10 | **Unresolved** | §7.30 L2010 is applied as written, but "Tablet and desktop: bottom-centre of the content column" puts the capsule where the tablet frame's accessory floats. See below. |
| 11 | Resolved | §7.35 L2053 carries the 450 ms preview, the 10 px drag, `dimContext` out over 180 ms, 1.02 → 1.03 on `press` and the handle lifting at once, word for word. It agrees with §7.23 L1914 ("drag it … to reorder (rows in reorder-capable lists)") and §11 L3852. |
| 12 | Resolved | §4.10 Throw L1231: "`zoom` … (throw to open); `dismiss` … (AI cards thrown away)", "settle 558 ms (open) / 378 ms (away)". It agrees with §4.2 `dismiss` L1068 ("thrown cards"), `zoom` 558 ms and `dismiss` 378 ms. |
| 13 | Resolved | §4.2 `snappy` L1058 no longer lists the segmented thumb, and `tab` L1060 lists "segmented thumb (§7.6)"; §7.16 L1827 "the width change runs on `minimize`"; §4.10 Minimise L1217 Where cell adds "desktop sidebar collapse and expand (`mod+b`)". §7.6 L1685 and §4.10 Tab droplet use `tab`. |
| 14 | Resolved | §4.10 Fan open L1268 and §8.18 L2912: −24°, −8°, 8°, 24° with the three, two and one cover variants. Grep: no `±12°` or `±24°` left; the resting stack in §7.7 L1702 (−8°, −3°, 3°, 8°) is a different state. |
| 15 | Resolved | §7.20 Downloaded L1885: "`droplet` glyph 14 `success` in rows and lists; on a cover 16 px on a 22 px `rgba(0,0,0,0.72)` circle (`color.coverDisc`; 5.17:1 over white, §7.8)". It agrees with §7.8 L1716 (16 px). |
| 16 | Resolved | §2.7 L491: "Ornamental (empty-state lenses 44, onboarding format cards 40, Wrapped 48 to 64) \| **Light** \| 40 to 64". The fix also widened the size cell, which is consistent. §7.24 L1920 and L1932 (Light 44) and §8.7 L2499 (Light 40) match. |
| 17 | Resolved | §8.0.5 L2297 applied word for word. The PWA strip is 24 px (L2254), the Safari rule is 24 px (§8.0.8 L2356), and the readers' strip is 20 px (L1131, L2252, L2647). |
| 18 | Resolved | §11 L3851: "Reveals the content-twin action pills (§7.34)". Grep for `glass action pill` finds nothing. |
| 20 | Resolved | §2.1.9 Warmth L256 names the favourite star (§7.2) and the Statistics best-day dot (§9.2.1). |
| 22 | Resolved | §7.26 Profile orb L1964 (24 includes the dock's You tab; 56 to 64 for the presence arc, §9.3.1) and Friend orb L1967 (56 to 64 in the presence arc). This matches §9.3.1 L3402 (56 px, up to 64 px). |
| 23 | Resolved | Switch knob shadow `0 2px 8px rgba(0,0,0,0.4)` in §7.22 L1905. Page-slide edge shadow `0 0 8px rgba(0,0,0,0.45)` with alpha scaled by turn progress in §4.10 L1242, §8.14.1 L2616 and §8.15.4 L2799. Lens-pop ring 48 → 96 px, 0.30 → 0 over 300 ms `cubic-bezier(0.4, 0, 1, 1)` in §4.10 L1303 and §8.11 L2565. Deal Bézier (48 px perpendicular) in §4.10 L1224 and §9.1.2 L3213. Orbs Bézier (x + 40 px × s, control 120 px above) in §4.10 L1288 and §9.3.4 L3430. Sending state (60 %, 1.5 px `bloom` ring at 40 %) in §9.3.2 L3418. Grep: no "short arc", "small ripple", "8 px soft shadow", "small shadow" or "curve toward" left. |
| 24 | Resolved | §2.8.1 L570–572 rows as specified, with Flutter bytes 0x99, 0xDB and 0xB8 (0.60 × 255 = 153; 0.86 × 255 = 219.3 → 219; 0.72 × 255 = 183.6 → 184). The keys are cited in §2.1.2 L76, §2.4.1 rule 1 L357, §7.8 L1716, §7.20 L1882, L1883 and L1885, and §15.8 L4393 and L4396. |
| 25 | Resolved | §15.10 G6 L4432 `palette {a, l, lMax}`. It matches §2.1.8 L237 and §15.5 L4296. |
| 26 | Resolved | §8.15.1 L2751 "13.4 to 17.8:1, muted text at 5.8 to 6.6:1". The table below it runs from 13.42 to 17.83 and from 5.84 to 6.56. |
| 27 | Resolved | §3.3 L943, M row, Android cell `n/a`. Grep: no `0.95` left in the table; the steps list at L936 is unchanged. |
| 28 | Resolved | §7.19 Linear L1863: "(bounce 0.15: a 0.6 % overshoot, settled in 431 ms; the fill is clipped to the track, so the overshoot never draws past the end at 100 %)". This matches §4.2 `snappy` L1058 (431 ms, 0.6 %). Grep: no "overshoots nothing" left. |

---

## Unresolved

### CONSISTENCY-7: the override paragraph claims a closed set that the file breaks

L1007 says "Only the overrides that §7 to §10 name are allowed. Size overrides exist for `mono` only: keycaps …; the stepper value, chapter-row number and go-to well …; and the share side's foot line … Every other override is a weight." The signature is `GlassText(role:, text, {int? wght, double? size, double? height})`, and the web side lists only `-wght`, `-size` and `-lh`. The following overrides, all named in §7 to §9, are neither weights nor on the size list, and the mechanism cannot express them:

- **Tracking overrides:**
  - §7.5 Tag L1677: `caption1` uppercase +0.08 em.
  - §7.17 section header L1848: `footnote` 13/600 uppercase +0.04 em.
  - §7.20 Status tag L1882: `caption1` 600 uppercase +0.06 em.
  - §8.14.1 chapter seam L2615: `caption1` +0.2 em.
  - §8.15.2 chapter header L2769: `caption1` +0.22 em.
  - §9.1.3 L3230: "PREVIOUSLY ON" `caption1` +0.18 em.
  - §9.2.3 L3339: eyebrow `caption1` uppercase +0.18 em.
- **Size and line-height overrides that are not listed:**
  - §8.15.2 L2769: "3.4k words · 14 min" in `mono` 12.
  - §8.25.14 L3112: licence text in `mono` 13/20, a height override on the 13/18 role.
- **Family overrides:**
  - §8.16.2 L2855: sentence list in `title3` Literata.
  - §9.2.3 L3328 and L3339: `wrappedNumeral` count-up with "digits in Google Sans Code".
- **Style override:** §7.7 L1699: the `why` line in `footnote` italic.

**Proposed final fix.** Extend the paragraph to `GlassText(role:, text, {int? wght, double? size, double? height, double? trackingEm, String? family, bool italic = false})`, with the web equivalents `[--mm-type-<role>-track:0.08em]`, the `font-mono` / `font-serif` utilities, and `italic`. Then replace the last two sentences with an exhaustive list:

- **Weight:** as now.
- **Size and height (`mono` only):** as now, plus `mono` 12/16 in the §8.15.2 chapter header and `mono` 13/20 for the §8.25.14 licence text.
- **Tracking** (the value replaces the role's tracking): `caption1` 0.06 em (§7.20), 0.08 em (§7.5), 0.18 em (§9.1.3, §9.2.3), 0.2 em (§8.14.1) and 0.22 em (§8.15.2); `footnote` 0.04 em (§7.17).
- **Family:** `title3` in Literata (§8.16.2 sentence list); `wrappedNumeral` in Google Sans Code during the §9.2.3 count-up only.
- **Italic:** `footnote` for the `why` line (§7.7).

Separately, Google Sans Flex ships with `slnt` pinned to 0 (§3.1). The italic `why` line is therefore a synthesized oblique unless it is set in Literata italic, and the fix has to say which.

### CONSISTENCY-8: `aria-keyshortcuts` uses an invalid key token

§7.37 L2075 declares `aria-keyshortcuts="Control+Backslash"` (`Meta+Backslash` on macOS). WAI-ARIA 1.2 requires the non-modifier token to be a printable character or a UI Events KeyboardEvent **`key`** value. `Backslash` is a KeyboardEvent **`code`** value, so screen readers would announce a key name that does not exist. The rest of the fix is correct.

**Proposed final fix.** In §7.37, change it to `aria-keyshortcuts="Control+\"` (`Meta+\` on macOS). §11 L3845 needs no change.

### CONSISTENCY-10: the tablet placement collides with the tablet accessory, and the phone slot can exceed 8 shapes

1. **Introduced by the fix.** §7.30 L2010 places the capsule at "Tablet and desktop: bottom-centre of the content column". On tablets (768 to 1023 px, §8.0.1 L2150), the bottom accessory is "a floating capsule bottom-centre of the content column", so the two capsules take the same spot and no offset or queue rule separates them. Before the fix, the capsule was placed on desktop only. On desktop the accessory sits at the sidebar's foot (L1829, L2151), so desktop is fine.
2. **The budget claim does not hold.** The judge's rationale was that "§15.7's phone rows stay within 8 Flutter shapes". §7.12 L1776 makes only toasts wait while a menu or context menu is open. The app-update capsule (and the global new-chapters capsule, which already had this gap) can therefore show together with a sheet and a menu. That adds up to 9 shapes: nav row 3, dock + orb + accessory 3, sheet 1, capsule 1, menu 1. The §15.7 phone row L4380 counts only "toast or menu".
3. **Related, pre-existing.** The §15.7 tablet Flutter count at L4384 ("sidebar, toolbar group, toast, app-update capsule, window or panel, menu = 6 / 6") leaves out the tablet's floating `glassRegular` accessory. With it, the count is 7 layers.

**Proposed final fix.**

- §7.30: change "Tablet and desktop: bottom-centre of the content column" to "Desktop: bottom-centre of the content column … Tablet: bottom-centre of the content column, 12 px above the floating accessory when it shows (§8.0.1)". The desktop wait rule stays as it is.
- §7.12 L1776: change "A toast also waits while a menu or context menu is open" to "Every item of the top-band queue (toast, new-chapters capsule, app-update capsule) waits, or hides, while a menu or context menu is open".
- §15.7 tablet cell: add the accessory, and make the app-update capsule wait while a window, panel or menu is open, so the count stays at 6.

---

## Checks that found nothing

- Old values grepped with no match left: `401` in a snap context, `> 400`, `97–400`, "desktop T5 window", `dim 50`, "detents with magnets", "Magnet capture", `5 s Undo`, "Wrapped numbers", `` `display` Google Sans Flex ``, `0.95` in the §3.3 table, `±12°`, `±24°`, "short arc", "small ripple", "8 px soft shadow", "small shadow", "curve toward", "glass action pills", `palette {a, l}`, "13 to 15:1", "about 5.9:1", "overshoots nothing", "settles in 0.4 s", "like the reader's strip", "segmented thumb" under `snappy`, and the width change on `snappy` in §7.16.
- Places where a changed value is repeated, all consistent:
  - T4 for sheets, panels, windows, palette and alerts: §2.4.1 L339–352, §2.4.2 L381, §2.1.2 L76, §15.3 L4249.
  - 960 px slab and recession: §7.10, §8.12, §8.13 and §15.2 agree; §2.3 radii are consistent.
  - Magnet radii: §4.6, §7.21, §8.16.3, §8.25.6, §9.3.4 and §9.4.1.
  - Press growth: §2.4.1, §4.10, §7.1, §7.2, §7.15, §7.21 and §7.22.
  - Esc and Android back orders: §8.0.5, §8.14.7, §8.14.11 and §9.4.3. On Flutter a reader sheet is its own route above the reader, so it pops before the reader's `PopScope` rules. The sheet-over-cinema case is therefore not an ordering conflict.
  - Orb sizes: §7.26 and §9.3.1.
  - Backing colour keys: §2.8.1, §2.1.2, §2.4.1, §7.8, §7.20 and §15.8.
