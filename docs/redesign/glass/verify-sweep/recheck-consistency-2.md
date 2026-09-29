# Glass DESIGN.md: consistency recheck, round 2

Input: the 26 findings in the "Confirmed" section of `glass/verify-sweep/judge-consistency.md` (CONSISTENCY-19 and CONSISTENCY-21 were refuted and are out of scope). For CONSISTENCY-7, CONSISTENCY-8 and CONSISTENCY-10, the final fix is the judge's fix plus the amendments that `recheck-consistency-1.md` proposed, which `fixed-consistency.md` Round 2 says were applied. Target: `glass/DESIGN.md` in the working tree on 2026-09-29 (4,627 lines, uncommitted; the file was last committed in `d9ee97c`, and `HEAD` is `d522dba`).

Method:

- `git diff -U0 --word-diff` against `HEAD` (82 insertions, 67 deletions) gave the exact before and after text of every edit from both rounds.
- Each final fix was compared with the edited lines.
- Every old value a fix replaced was grepped for across the whole file, along with every other place the changed value is repeated.
- For CONSISTENCY-7, a script listed every role name in §4 to §15 that is followed by a size, weight, tracking, family, italic or uppercase modifier. Each hit was checked against the new exhaustive list in §3.7.

DESIGN.md was not edited. Line numbers below are from the current file.

Result: **25 resolved, 1 unresolved** (CONSISTENCY-7).

- CONSISTENCY-8 and CONSISTENCY-10, which round 1 left open, are now resolved.
- CONSISTENCY-7's round-2 paragraph covers every tracking, family, italic and size override in §7 to §10. Its weight bullet, though, limits weight overrides to "§7 to §10", and the paragraph declares its list exhaustive. Two weight overrides named outside that range are therefore still contradicted.

---

## Per-finding verdicts

| Id | Verdict | Evidence (current lines) and residue grep |
|---|---|---|
| 1 | Resolved | §2.4.3 L414: `≥ 97 → T4`, with T5 declared only for the Massive objects. §2.8.4 L785 `glass.snap` and its Dart cell: `[36, 57, 97]`. §15.1 L4122: `"snap": [36, 57, 97]`. §15.8 L4395: `tierFor(401) == T4`. §7.10 L1746: "Panel and window bodies are T4 glass (`glassThick`); the one T5 window is the listen player's (§8.16.2)". §8.25.14 L3118: "the desktop T4 window". Grep finds no `97–400`, no `> 400` and no `401` in a snap context (the other `401`s are HTTP codes, L2368–2386). The one "desktop T5 window" left, L2861, is the listen player's, which is correct. Every remaining T5 or `glassMonolith` use is a Massive object: L353, L382, L1740 (the listen player sheet), L2851, L3331 and L4391. The T4 declarations agree: L341, L342, L352, L381 and §15.3 L4255 (`SkinGlass(tier: T4)`). |
| 2 | Resolved | §7.10 L1746 has the 960 px slab exception word for word: `rgba(19,19,23,0.84)`, blur 36, radius 32, scale 0.97, `blur.recede` 8, `rgba(0,0,0,0.50)`, `--sheet-progress`, and every other window over `dimSheet`. §8.12 L2582: "50 % brightness (`rgba(0,0,0,0.50)`)". §15.2 L4203 carries the parenthesis as specified. §2.3 L319 `r2xl`: "Desktop windows (560 and 960 px) and the desktop Login slab (§8.3); desktop panels stay `rXl` 26". L318 `rXl` adds desktop side panels. Grep finds no `dim 50`. The only desktop window widths in the file are 560 and 960, and the only radius-32 surfaces are the two windows and the Login slab (L2439). `materialThick` (L395) is `rgba(19,19,23,0.84)` / 36. |
| 3 | Resolved | §4.6 L1147–1149 has the three rows (Object magnet, Value magnet, Step magnetism) with the fix's text and haptics. §2.8.5 L835–836 adds `physics.valueMagnetSpeed` 0.08 and `physics.valueMagnetStepFraction` 0.30. §15.1 L4132 puts `"valueMagnetSpeed": 0.08, "valueMagnetStepFraction": 0.30` beside `"magnetRadius": 64`. Cross-checks: §5.2 L1431 limits `detent.magnet` to speed, cruise and the 30-minute interval; §7.21 L1902 "within 30 % of a step's spacing"; §8.16.3 L2868 "±0.08" at 6 px per step (0.08 / 0.05 × 6 = 9.6 px); §8.14 cruise L3459 at 8 px per 0.05× (12.8 px); interval L3070 magnet at 30; §9.3.4 L3435 "within 64 px … 35 % of the remaining distance per frame". Grep finds no "Magnet capture" and no "detents with magnets". |
| 4 | Resolved | §2.4.1 Feather row L349 and Light row L350 read as the fix. §4.10 Press swell L1210: "+12 px (Medium) or +17 px capped at 0.35 × side (Light); Feather objects grow per their component (§2.4.1)". Cross-checks: Content sink L1211 (chips 0.96), buttons L1618 (+12 px), icon buttons L1642 (+17 px capped at 0.35 ×), droplet L1812 (grows 6 %), slider thumb L1902 (28 → 34 px) and switch knob L1911 (34 × 27). The Light row keeps `snappy`. |
| 5 | Resolved | §7.34 L2053: "the 10 s Undo toast of §7.12". A script over every "Undo" with a duration finds only 10 s (L1784, L2053, L3030, L3034, L3036). |
| 6 | Resolved | §3.2 L913: `display` "(splash wordmark, hero titles, Wrapped card 1 headline)". §9.2.3 L3334: "the `wrappedNumeral` numeral". §9.2.4 L3373: "`wrappedNumeral` (88 px × 3 = 264 px on the canvas)". Card 1 (L3349) is `display` 44/48, and the card 2 figure box (L3350, y 236–324) is 88 px, matching `type.wrappedNumeral` 88/88 (L1034) and the Big numbers rule (L3345). Grep finds no "Wrapped numbers" and no "`display` Google Sans Flex". |
| 7 | **Unresolved** | The round-2 Overrides paragraph (L1007–1013) is applied as `recheck-consistency-1.md` proposed. Its tracking, family, italic and size lists match every hit in §7 to §10. The weight bullet's "§7 to §10" scope, combined with "the list is exhaustive", excludes two weight overrides named elsewhere. See below. |
| 8 | Resolved | §9.4.3 L3497: the counter's overview button (`squares-four` 20, 44 hit, `aria-label` and Flutter `Semantics` label), toggling the Overview at L3499. §7.37 L2081: the "All levels" `CustomSemanticsAction` and `aria-keyshortcuts="Control+\"` (`Meta+\` on macOS), with the note that the token is the `key` value, never `Backslash`. Grep finds no `Control+Backslash` and no `Meta+Backslash`. §11 L3851's alternative cell: "`mod+\` (announced through `aria-keyshortcuts`); the Flutter custom action "All levels" on every back button (§7.37)". The §11 pinch-out row (L3873) points to the button that now exists. §8.0.6 L2315 binds `mod+\` to the back menu. |
| 9 | Resolved | §8.14.7 L2706 and §8.14.11 L2733: "menu or popover → dialogue overlay and hit lens → guided view (back to the strip at the current panel) → side panel (desktop) → fullscreen → cinema → leave the reader". §8.0.5 L2278: "It follows the same order as the web's `Esc` (§8.0.6, §8.14.7); side panels and fullscreen do not exist on phones". Android rules 6 to 8 (L2286–2288: dialogue overlay, guided view, cinema) follow the same order. §9.4.3 Exit (L3500) returns to the strip at the current panel. The novel reader's own Esc order (L2839) has no guided view or overlay, so it is unaffected. |
| 10 | Resolved | §7.30 L2016, §7.12 L1782 and §15.7 L4386 and L4390 carry the round-2 fix; details below this table. |
| 11 | Resolved | §7.35 L2059: the 450 ms preview (row 1.02, `dimContext`, menu, `longpress.open`), the 10 px drag, `dimContext` out over 180 ms, 1.02 → 1.03 on `press`, `reorder.lift`, and the handle lifting at once, all word for word. It agrees with §7.23 ("preview (poster 1.12, row 1.02, image 1.0) stays interactive: drag it … to reorder"). |
| 12 | Resolved | §4.10 Throw L1237: "`zoom` … (throw to open); `dismiss` … (AI cards thrown away)", "settle 558 ms (open) / 378 ms (away)". It matches `zoom` 558 ms (L1071), `dismiss` 378 ms with "thrown cards" (L1074), and §9.1.1 L3209 ("flies off on `dismiss` with its velocity"). |
| 13 | Resolved | §4.2 `snappy` L1064 no longer lists the segmented thumb, and `tab` L1066 lists "segmented thumb (§7.6)". §7.16 L1833: "the width change runs on `minimize`". §4.10 Minimise L1223's Where cell adds "desktop sidebar collapse and expand (`mod+b`)". The sidebar is Medium class (L351), whose move spring is `morph` / `minimize`. |
| 14 | Resolved | §4.10 Fan open L1274 and §8.18 L2918: −24°, −8°, 8°, 24°, with the three-, two- and one-cover variants. Grep finds no `±12°` or `±24°`. The resting stack at §7.7 L1708 (−8°, −3°, 3°, 8°) is a different state. |
| 15 | Resolved | §7.20 Downloaded L1891: "14 `success` in rows and lists; on a cover 16 px on a 22 px `rgba(0,0,0,0.72)` circle (`color.coverDisc`; 5.17:1 over white, §7.8)". It matches §7.8 L1722 (16 px). |
| 16 | Resolved | §2.7 L491: "Ornamental (empty-state lenses 44, onboarding format cards 40, Wrapped 48 to 64) \| **Light** \| 40 to 64". It matches the lens glyphs (L1938, Light 44) and the format cards (§8.7 L2505). |
| 17 | Resolved | §8.0.5 L2303 applied word for word. The PWA strip and the Safari edge rule are 24 px, and the readers' strip is 20 px (the same line ends "the 20 px back strip (§8.14.3)"). Grep finds no "like the reader's strip". |
| 18 | Resolved | §11 L3857: "Reveals the content-twin action pills (§7.34)". Grep finds no "glass action pill". |
| 20 | Resolved | §2.1.9 Warmth L256 names the favourite star (§7.2) and the Statistics best-day dot (§9.2.1). |
| 22 | Resolved | §7.26 Profile orb L1970: 24 now includes the dock's You tab, and the presence arc is 56 to 64. Friend orb L1973: "56 to 64 px in the presence arc (§9.3.1)". This matches §9.3.1 L3408 ("56 px orb … larger, up to 64 px"). |
| 23 | Resolved | Switch knob `0 2px 8px rgba(0,0,0,0.4)` at L1911. The page-slide edge shadow `0 0 8px rgba(0,0,0,0.45)`, with alpha scaled by turn progress, at L1248, L2622 and L2805. The lens-pop ring at L1309 and L2571. The Deal Bézier at L1230 and L3219. The Orbs Bézier with the sign rule at L1294 and L3436. The sending state at L3424. Grep finds no "short arc", "small ripple", "soft shadow", "small shadow", "curve toward" or "thin ring". |
| 24 | Resolved | §2.8.1 L570–572, with Flutter bytes `0x99`, `0xDB` and `0xB8` (153; 219.3 → 219; 183.6 → 184), rounded like `twinDense` (0.82 → `0xD1`). The keys are cited at L76, L357, L1722, L1888, L1889, L1891, L4399 and L4402. |
| 25 | Resolved | §15.10 G6 L4438: `palette {a, l, lMax}`. It is the only `palette {…}` in the file. |
| 26 | Resolved | §8.15.1 L2757: "13.4 to 17.8:1, muted text at 5.8 to 6.6:1". The table below it runs from 13.42 to 17.83 and from 5.84 to 6.56. |
| 27 | Resolved | §3.3 L943, M row: the Android cell is `n/a`. The steps list at L937 is unchanged. |
| 28 | Resolved | §7.19 Linear L1869: "(bounce 0.15: a 0.6 % overshoot, settled in 431 ms; the fill is clipped to the track …)". It matches `snappy` at L1064. Grep finds no "overshoots nothing" and no "settles in 0.4". |

**CONSISTENCY-10 in detail (resolved).**

- **Phone.** §7.30 L2016 puts the capsule in the top-band queue of §7.12 "(after the global new-chapters capsule)".
- **Desktop.** It sits bottom-centre and waits while the bulk-selection toolbar or the "Unsaved changes" bar shows.
- **Tablet.** It sits "12 px above the floating accessory when it shows (§8.0.1; 24 px from the window bottom when it does not)", follows the same wait rule, and also waits while a window, panel or menu is open.
- **§7.12 L1782.** Every item of the queue (toast, new-chapters capsule, app-update capsule) waits while a menu or context menu is open. An item already showing leaves on `dismiss` and falls back in on `snappy`. This matches the toast motion (L1783).
- **§15.7 phone row, L4386.** It counts "toast or capsule or menu 1": 5 web elements, 4 / 8 Flutter.
- **§15.7 tablet frame, L4390.** It now counts the floating accessory. With the tablet's app-update capsule waiting while a window, panel or menu is open, that gives 6 / 6.
- **Other placements.** No other placement of the capsule is left in the file (L1752, L2060, L2233, L3175–3176 and L4597 checked). On tablets the bulk-selection toolbar replaces the accessory slot (§7.35 L2060), so it adds no shape.

---

## Unresolved

### CONSISTENCY-7: the weight bullet's range leaves out two weight overrides

L1007 ends: "Only the overrides listed here are allowed, and the list is exhaustive". L1009 then reads: "**Weight** (`wght`): any role, wherever §7 to §10 name a weight."

Everything else in the list checks out:

- **Size and height.** Keycaps (§7.27 L1981); the stepper, chapter-row number and go-to well at 15 (L1659, L1857, L2634); the chapter header at 12/16 (L2775); the licence text at 13/20 (L3118); and the share foot line at 24 on the canvas (L3373–3374).
- **Tracking.** Seven values: L1683, L1854, L1888, L2621, L2775, L3236 and L3345.
- **Family.** L2861, L3334 and L3345.
- **Italic.** L1705.

Every other role-plus-number hit in §7 to §10 is either the role's own base size or a weight. No role override appears after §10.

Two weight overrides are named outside §7 to §10, so the exhaustive list does not allow them:

- **§4.10 Plus one, L1296:** "A "+1" `caption1` 700 chip in `streakCore`". §9.2.2 (L3320) only cites the move ("the Plus one move, §4.10") and names no weight.
- **§2.1.2, L76:** "Text that a spec dims by opacity inside such a surface uses `onGlass` at `wght` 460 instead". This is a weight override of role text that §7 to §9 specify by opacity. The weight itself is named only in §2.1.2.

**Proposed final fix.** At §3.7 L1009, replace the weight bullet with: "**Weight** (`wght`): any role, wherever this contract names a weight: §7 to §10, the §4.10 Plus one chip (`caption1` 700), and the §2.1.2 rule that sets text a spec dims by opacity inside T4 and T5 glass in `onGlass` at `wght` 460." Nothing else changes.

---

## Observations outside the findings (not counted as unresolved)

These are pre-existing, or are use lists that are not worded as exhaustive. None contradicts a final fix.

- **Tablet top chrome is named two ways.** §8.0.1 (L2156) gives the tablet frame a "floating nav row on the right". But §7.30's new-chapters capsule (L2015) is placed "12 px below the toolbar row" on tablets. §8.0.8 L2363 says every screen uses its desktop layout inside the tablet frame. The §15.7 tablet count (L4390) says "toolbar group".
  - If the tablet row is the phone-style nav row (leading button, title capsule, trailing group), the tablet frame is 6 layers and 8 shapes, not "6 / 6". The §7.30 phrase "keeps the tablet frame at 6 Flutter shapes" then reads "6 Flutter layers".
  - The budget holds under either reading: the Flutter limit is 6 layers or 8 shapes (L4382).
  - A later pass could say which bar tablets use, and state the count as 6 / 8 if it is the nav row.
- **Stacked toasts are not counted.** §7.12 Stacking (L1786) allows 2 toasts at once. The phone budget row (L4386) counts one "toast or capsule or menu" slot, so two stacked toasts over a sheet would make 9 phone shapes. This predates the consistency sweep.
- **Two use cells miss a new use.** They are not worded as exhaustive, so this is not a contradiction.
  - `blurRecede` (L457) still describes only "the page behind a sheet at the large detent (with scale 0.94)". It does not mention the desktop 960 px window's recession (scale 0.97), which §7.10 now cites as `blur.recede`.
  - §4.2 `minimize` (L1073) does not list the desktop sidebar, which §7.16 and §4.10 Minimise now run on it.

---

## Checks that found nothing

- **Old values grepped with no match left:**
  - `97–400`, `> 400`, `401` in a snap context, "T4 or T5 glass" for desktop bodies (L76's "T4 or T5 glass" is the mapping rule and includes the full player), `dim 50`.
  - "Magnet capture", "detents with magnets", `5 s Undo`, "Wrapped numbers", "`display` Google Sans Flex".
  - `±12°`, `±24°`, "short arc", "small ripple", "soft shadow", "small shadow", "curve toward", "thin ring", "glass action pill".
  - `palette {a, l}`, "13 to 15:1", "about 5.9", "overshoots nothing", "settles in 0.4", "like the reader's strip".
  - `Control+Backslash`, `Meta+Backslash`, and "segmented thumb" in the `snappy` use cell.
- **Places where a changed value is repeated, all consistent:**
  - T4 for sheets, panels, windows, palette and alerts: L341, L342, L352, L381, L1746, L4255.
  - The slab and recession for the 960 px window: §7.10, §8.12, §8.13, §15.2; radii in §2.3.
  - Magnet radii and haptics: §4.6, §5.2, §7.21, §8.16.3, the cruise pill, the interval slider, §9.3.4.
  - Press growth: §2.4.1, §4.10, §7.1, §7.2, §7.15, §7.21, §7.22.
  - Esc and Android back orders: §8.0.5, §8.14.7, §8.14.11, §9.4.3.
  - App-update placement: §7.12, §7.30, §7.35, §15.7.
  - Orb sizes: §7.26 and §9.3.1.
  - Backing-colour keys: §2.8.1, §2.1.2, §2.4.1, §7.8, §7.20, §15.8.
  - Role overrides: §3.7 against every role hit in §7 to §10.
- **Technical claims in the round-2 text:**
  - `aria-keyshortcuts` takes a KeyboardEvent `key` value (`\`), not a `code` value.
  - Synthetic italic is a 14° skew on Blink, WebKit and Flutter (skew −0.25, atan 0.25 ≈ 14.04°).
  - No `font-synthesis` rule anywhere in the file blocks the synthesized oblique.
  - The Tailwind arbitrary properties resolve to 15/20 px (`0.9375rem` / `1.25rem`).
