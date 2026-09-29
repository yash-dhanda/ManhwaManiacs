# Glass DESIGN.md: consistency recheck, round 3

Input: the 26 findings in the "Confirmed" section of `glass/verify-sweep/judge-consistency.md`. CONSISTENCY-19 and CONSISTENCY-21 were refuted and are out of scope. For CONSISTENCY-7 the final fix is the judge's fix plus the round-1 and round-2 amendments, the last of which is the Weight bullet proposed in `recheck-consistency-2.md` and reported as applied in `fixed-consistency.md` Round 3. For CONSISTENCY-8 and CONSISTENCY-10 it is the judge's fix plus the round-1 amendments.

Target: `glass/DESIGN.md` in the working tree on 2026-09-29. It has 4,627 lines and is uncommitted. The file was last committed in `d9ee97c`, and `HEAD` is `d522dba`.

Method:

- `git diff -U0 --word-diff HEAD` gave the before and after text of every edit from all three rounds (82 insertions, 67 deletions).
- A script checked each finding in two ways: every string its final fix introduces is present, and every string it replaced is gone. It also reported the lines where each hit sits.
- Every place a changed value is repeated was grepped: T4 and T5 declarations, `glassMonolith`, Undo durations, the segmented thumb, `mod+b`, `aria-keyshortcuts`, and the fan angles.
- For CONSISTENCY-7, a second script listed every role name followed by a weight, size, tracking or `wght` modifier outside §7 to §10 (lines 1–1590 and 3839–4627, leaving out the role tables in §3.2 and §3.7). A second pass listed every `wght` or three-digit weight in the same ranges.

DESIGN.md was not edited. Line numbers below are from the current file.

Result: **26 resolved, 0 unresolved.** CONSISTENCY-7, the one finding round 2 left open, is now resolved.

---

## Per-finding verdicts

| Id | Verdict | Evidence (current lines) |
|---|---|---|
| 1 | Resolved | The fix is in place at every point it names: §2.4.3 L414 (`≥ 97 → T4`, T5 declared only for the Massive objects), §2.8.4 L785 (`[36, 57, 97]` in the value and the Dart cell), §15.1 L4122 (`"snap": [36, 57, 97]`), §15.8 L4395 (`tierFor(401) == T4`), §7.10 L1746 (bodies T4, the listen player's window the one T5) and §8.25.14 L3118 ("the desktop T4 window"). Grep finds no `97–400`, no `> 400 →`, no `97, 401` and no `tierFor(401) == T5`. Every remaining T5 or `glassMonolith` use is a Massive object or a rule stated for T4 and T5 together: L353, L382, L456, L1740, L2851, L2855, L2861, L3331, L4255 and L4391. |
| 2 | Resolved | §7.10 L1746 carries the 960 px slab exception (`rgba(19,19,23,0.84)`, blur 36, radius 32, scale 0.97, `blur.recede` 8, `rgba(0,0,0,0.50)`, `--sheet-progress`), and every other window and panel sits over `dimSheet`. §8.12 L2582 reads "50 % brightness (`rgba(0,0,0,0.50)`)". The §15.2 parenthesis is at L4203. The §2.3 `r2xl` row, L319, reads "Desktop windows (560 and 960 px) and the desktop Login slab (§8.3)". Grep finds no `dim 50`. |
| 3 | Resolved | §4.6 L1147–1149 has the Object magnet, Value magnet and Step magnetism rows. §2.8.5 L835–836 has `physics.valueMagnetSpeed` 0.08 and `physics.valueMagnetStepFraction` 0.30. §15.1 L4132 has both beside `"magnetRadius": 64`. Grep finds no "Magnet capture" and no "detents with magnets". |
| 4 | Resolved | §2.4.1 Feather row L349 and Light row L350 read as the fix, and so does §4.10 Press swell L1210. The old "(Feather, Light;" is gone. |
| 5 | Resolved | §7.34 L2053: "the 10 s Undo toast of §7.12". Every Undo duration in the file is 10 s (L1784, L2053, L3030, L3036). |
| 6 | Resolved | §3.2 L913, §9.2.3 L3334 and §9.2.4 L3373 read as the fix. Grep finds no "Wrapped numbers", no "the `display` numeral" and no "`display` Google Sans Flex". |
| 7 | Resolved | §3.7 L1007–1013 holds the Overrides paragraph. The Weight bullet at L1009 now reads, word for word as `recheck-consistency-2.md` proposed: "any role, wherever this contract names a weight: §7 to §10, the §4.10 Plus one chip (`caption1` 700), and the §2.1.2 rule that sets text a spec dims by opacity inside T4 and T5 glass in `onGlass` at `wght` 460". The details follow this table. |
| 8 | Resolved | §9.4.3 L3497 has the counter's overview button (`squares-four` 20, 44 hit, `aria-label` and a Flutter `Semantics` label). §7.37 L2081 has the "All levels" `CustomSemanticsAction` and `aria-keyshortcuts="Control+\"` (`Meta+\` on macOS). §11 L3851 has the alternative cell. Grep finds no `Control+Backslash"`, no `Meta+Backslash` and no "the screen-reader custom action". |
| 9 | Resolved | §8.14.7 L2706 and §8.14.11 L2733 give the full reader Esc order. §8.0.5 L2278: "It follows the same order as the web's `Esc` … side panels and fullscreen do not exist on phones". Grep finds no "It matches the web". |
| 10 | Resolved | §7.30 L2016 gives phones the top-band queue, desktop bottom-centre with the bar wait rule, and tablet 12 px above the floating accessory with the extra wait. §7.12 L1782 makes every queue item wait for a menu. In §15.7, the phone row (L4386) counts "toast or capsule or menu" and the tablet frame (L4390) is 6 / 6. Grep finds no "Bottom-centre above the dock". |
| 11 | Resolved | §7.35 L2059 has the 450 ms preview, the 10 px drag, `dimContext` out over 180 ms, 1.02 → 1.03 on `press`, and the handle lifting at once. The old "(or drag its handle immediately)" is gone. |
| 12 | Resolved | §4.10 Throw, L1237: `zoom` to open and `dismiss` for AI cards thrown away, settling in 558 ms (open) and 378 ms (away). |
| 13 | Resolved | The §4.2 `snappy` row (L1064) no longer names the segmented thumb, and the `tab` row (L1066) does. §7.16 L1833 runs the width change on `minimize`, and §4.10 Minimise L1223 names `mod+b`. The other `mod+b` lines (L1847, L1848, L2310, L2330, L4044) name no spring. |
| 14 | Resolved | §4.10 Fan open L1274 and §8.18 L2918: −24°, −8°, 8°, 24°, plus the three-, two- and one-cover variants. Grep finds no `±12°` and no `±24°`. |
| 15 | Resolved | §7.20 Downloaded, L1891: 14 in rows and lists, 16 on the 22 px cover disc. This matches §7.8 L1722. |
| 16 | Resolved | §2.7 L491: the Ornamental row gives lenses 44, format cards 40 and Wrapped 48 to 64, all **Light**, 40 to 64. |
| 17 | Resolved | §8.0.5 L2303 has the fix's text. Grep finds no "like the reader's strip". |
| 18 | Resolved | §11 L3857: "Reveals the content-twin action pills (§7.34)". Grep finds no "glass action pill". |
| 20 | Resolved | §2.1.9 Warmth, L256, names the favourite star (§7.2) and the Statistics best-day dot (§9.2.1). |
| 22 | Resolved | §7.26 L1970: 24 includes the dock's You tab, and the presence arc is 56 to 64. L1973: the Friend orb is 56 to 64 px in the presence arc. Grep finds no "drop targets, presence arc)". |
| 23 | Resolved | All six values are in place: the knob shadow at L1911; the edge shadow at L1248, L2622 and L2805; the lens-pop ring at L1309 and L2571; the Deal Bézier at L1230 and L3219; the Orbs Bézier with its sign rule at L1294 and L3436; and the sending state at L3424. Grep finds none of the vague phrases (listed under the checks below). |
| 24 | Resolved | §2.8.1 L570–572 has `color.backingDisc` `0x99`, `color.coverBacking` `0xDB` and `color.coverDisc` `0xB8`. The keys are cited in §2.1.2, §2.4.1, §7.8, §7.20 and §15.8. |
| 25 | Resolved | §15.10 G6 L4438: `palette {a, l, lMax}`. No `palette {a, l}` remains. |
| 26 | Resolved | §8.15.1 L2757: "13.4 to 17.8:1, muted text at 5.8 to 6.6:1". |
| 27 | Resolved | §3.3 L943, M row: the Android cell is `n/a`. |
| 28 | Resolved | §7.19 L1869 has the fix's text. Grep finds no "overshoots nothing" and no "settles in 0.4". |

### CONSISTENCY-7 in detail

**What round 3 changed.** The git diff shows the round-2 text of the Overrides paragraph with one change: the Weight bullet's range. It used to be "wherever §7 to §10 name a weight". It is now "wherever this contract names a weight", followed by an explicit list: §7 to §10, the §4.10 Plus one chip, and the §2.1.2 dimmed-text rule. The old phrase is gone.

**The two cited sources are real, and each says what the bullet claims:**

- **§4.10 Plus one, L1296:** "A "+1" `caption1` 700 chip in `streakCore`". §9.2.2 L3320 only cites the move.
- **§2.1.2, L76:** "Text that a spec dims by opacity inside such a surface uses `onGlass` at `wght` 460 instead". Here "such a surface" is T4 or T5 glass, from the previous sentence. The Wrapped frame is excluded later in the same paragraph. The bullet points to "the §2.1.2 rule", so that exclusion still governs.

**No other weight override is named outside §7 to §10.** The role scan outside §7 to §10 found exactly one role with a weight: L1296, now covered. Its other hits are text-scale caps (L937, L939, L968), not overrides. The `wght` scan found only:

- font axis ranges (L896–901) and Bold Text rules (L931, L991, L4069);
- the novel reader's Literata settings (L981, L983), which are the serif face, not role text;
- the dock label contrast example (L179), which is `tabLabel`'s own weight, 600;
- the press `wght` +40 in §4.10 (L1210), which the paragraph already names;
- the wordmark (L3908, L3911), a logotype and not role text;
- the §15.1 JSON sample (L4138), which is `largeTitle`'s own 700.

**The rest of the paragraph is unchanged since round 2,** when its Size and height, Tracking, Family and Italic lists were checked against every role hit in §7 to §10.

**No contradiction was introduced:**

- The bullet is weight only, so "Size and height (`mono` only)" still holds. `onGlass` at 460 and `caption1` at 700 are weight changes, not size changes.
- "Bold Text still adds +100 and press still adds +40" agrees with §3.2 L931, §3.5 L991 and §14 L4069.

---

## Observations outside the findings (carried from round 2, not counted)

These predate the round-3 edit, and none contradicts a final fix.

- **Tablet top chrome is named two ways.** §8.0.1 gives the tablet a "floating nav row". §7.30 L2015 and the §15.7 tablet count (L4390) say "toolbar row" and "toolbar group". The budget holds under either reading (6 layers or 8 Flutter shapes, L4382), but a later pass could name the tablet bar once.
- **Stacked toasts are not counted.** §7.12 allows two stacked toasts. The phone budget row (L4386) counts one "toast or capsule or menu" slot.
- **Two use cells miss a new use.** They are not worded as exhaustive.
  - `blurRecede` (L457) does not mention the 960 px window's 0.97 recession.
  - §4.2 `minimize` (L1073) does not list the desktop sidebar that §7.16 and §4.10 now run on it.

---

## Checks that found nothing

- **Old values with no match left:**
  - `97–400`, `> 400 →`, `97, 401`, `tierFor(401) == T5`, `dim 50`
  - "Magnet capture", "detents with magnets", "(Feather, Light;", `5 s Undo`
  - "Wrapped numbers", "the `display` numeral", "`display` Google Sans Flex", "wherever §7 to §10 name a weight"
  - `Control+Backslash"`, `Meta+Backslash`, "the screen-reader custom action", "It matches the web", "Bottom-centre above the dock"
  - "(or drag its handle immediately)", "width change runs on `snappy`", "Chips, segmented thumb"
  - `±12°`, `±24°`, "(empty states, onboarding, Wrapped)", "like the reader's strip", "glass action pill"
  - "drop targets, presence arc)", "short arc", "small ripple", "soft shadow", "small shadow", "curve toward", "thin ring"
  - `palette {a, l}`, "13 to 15:1", "about 5.9", "| M | 0.95 |", "overshoots nothing", "settles in 0.4"
- **Every new value is present** at the lines listed in the table. The fix text for CONSISTENCY-1 to 6, 8 to 18, 20 and 22 to 28 is unchanged since round 2, which verified it.
