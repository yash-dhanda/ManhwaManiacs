# Cinematic DESIGN.md: recheck round 1, lens consistency

Input: the 49 findings in the "Confirmed" section of `cinematic/verify/judge-consistency.md` (CONSISTENCY-18 was refuted and is not checked). Target: `cinematic/DESIGN.md` as it stood at 2026-09-28 22:47 UTC (649,447 bytes, 4,644 lines). The other lenses' fixers were writing to the file during this pass (it changed three times while I read it), so every check below was re-run against that final snapshot.

Method: for each finding, read the sections the final fix names and compare them with the fix text. Then grep the whole file for every old value that should be gone and for every other place the changed value is repeated. Contrast figures were recomputed with the WCAG 2.x formula and the caret keyframe percentages were recomputed (530 / 3340 and so on). Where another lens has since rewritten a passage (`fixed-web.md`, `fixed-product.md`, `fixed-mobile.md`), the finding counts as resolved if the goal of the consistency fix still holds everywhere and the new text contradicts nothing.

**Result: 43 resolved, 6 unresolved** (CONSISTENCY-13, 14, 15, 19, 41, 50). Five of the six were caused by edits from other lenses, or by conflicts between two lenses, after the consistency fixes went in. Only CONSISTENCY-41 (§2.1.4 wording) and CONSISTENCY-50 (an incomplete list) come from how the consistency fix itself was written.

---

## Per finding

| ID | Status | Evidence in the snapshot |
|---|---|---|
| 1 | Resolved | §7.24 Mark says the 16 and 20 px mark is the §7.19 badge (Archivo 10/12 px), and the 160 px dialog mark has a 2 px border with Bodoni 900 at 88 px. §2.7 limits `certificate-18` to the icon slot. §7.25 and §8.5 read "(the §7.19 badge)". |
| 2 | Resolved | §12.4 rows are 252–572 monogram, 252–1180 Letter set (13 graphemes, 24 ms, last starts 540 and lands 1180), 700–1180 Rule draw, `splash.impress`, and a 220 ms hand-off. The duration rule is `max(probeDone, 1180 ms)`. §8.2 defers to it. §4.2 `dur.reel` = 1180 + 220. `max(probe, 900`, `max(dataReady` and "capped at 1400" are gone. |
| 3 | Resolved | §7.11 Surface is `paper.2` with `data-stock="raised"` / `CineStock.raised`, and the §2.1.1 raised-scope list names "toast". |
| 4 | Resolved (superseded) | WEB-2 set the spine to 768–1279 everywhere: §1, §7.15 Width, §8.0.1 and §8.0.9. 768–1023 is kept only as the 8-column grid range. There is still one spine range, which was the goal of CONSISTENCY-4. |
| 5 | Resolved | §4.3 Use column matches the fix word for word. The §4.5 Lightbox row and §7.30 Dismiss say "close by button … 320 ms `ease.turn` (a reverse match cut)". The Iris row (close `turn`, out `settle`) and §8.5 agree. |
| 6 | Resolved | §4.3 `ease.drift` Flutter column is `Cubic(0.37, 0, 0.63, 1)` with the `easeInOutSine` caveat. |
| 7 | Resolved | §3.2 has the per-breakpoint ratio table (recomputed: cover 1.0 / 0.9375 / 0.955 / 0.933, and so on), and each §3.5 fluid row repeats the same ratios. "cover 0.93, the others 1.0" is gone. |
| 8 | Resolved | §4.6 and §10.1.1 say "`n` = graphemes excluding spaces". Web: `n = graphemes(text.replaceAll(" ", "")).length` with `custom={n}`. Flutter: `_step` is a double, `start = 120.0 + _step * k`, and the controller duration is `.round()`ed. Since then PRODUCT-12 rewrote both components, and the count is still the same. |
| 9 | Resolved (items 1 and 3 superseded) | PRODUCT-12 replaced `replay` with `trigger: "signal"` / `SetTrigger.signal`, which does the same thing: it never reads or writes `seen` and plays on every mount. It also removed the 60-letter word fallback ("per letter at every length", with no cap), consistently in §10.1.1, §10.1.5, §10.1.6 and §15.6. No "60 letters", `WORD_LIMIT` or `_byWord` remains. Item 2 (a heading that leaves mid-reveal jumps to its end) is present on the web (the `idle/run/done` phase with `half` and `any`) and in Flutter (`visible == 0`). |
| 10 | Resolved | §10.2.1 and §10.2.3 give the six 530 ms halves ending on, then a 160 ms fade. The keyframes 15.87 / 31.74 / 47.60 / 63.47 / 79.34 / 95.21 % are correct, with a per-keyframe `linear` on the last one. The §10.2.4 Flutter formula matches. §14.10 says 0.94 Hz. |
| 11 | Resolved | The §4.5 Column wipe row has the tablet total, 744 ms. §8.14.2 has the formula, 616 / 744 / 872, and "304 ms sooner on tablets". §8.30.3 has "tablets: blades close 80–392". |
| 12 | Resolved | 16 × 16 on both clients: §2.1.5 row and picker (256 pixels, vectors note), §9.4.4, §15.3 `page_tint.dart`, §15.6, Appendix A graft row and "Adapted, not copied". "64 × h" and "64 px sampler" are gone. The web path has since gained a `createImageBitmap` resize from another lens, which does not conflict. |
| 13 | **Unresolved** | See below. |
| 14 | **Unresolved** | See below. |
| 15 | **Unresolved** | See below. |
| 16 | Resolved | §9.4.3 Moving uses 30 / 40 / 30 with a centre chrome zone. §11 reads "30 / 40 / 30 (manga paged and guided view), 25 / 50 / 25 (novel)". "30 / 70" is gone. |
| 17 | Resolved | §8.15.3 heading reads "fades in 240 ms `settle`, out 160 ms `lift`; no slide", and §4.8 has "Reader chrome in / out (manga and novel)". No 180 ms chrome value remains. |
| 19 | **Unresolved** | See below. |
| 20 | Resolved | §9.1.8 unavailable shows `NOTE` in `spot` (`color.note`) with the reason in `ink.60`, and the recap slate kicker stays `ink.45`. The §7.8 AI-unavailable line points at it. |
| 21 | Resolved | §3.2 and §3.5 `type.dropcap` = 3 × the paragraph line height with `opsz` = min(size, 96). Web uses `calc(var(--para-lh) * 3)` and Flutter uses `CineType.dropcap(lh)`. No `typeDropcap` with fixed sizes remains. |
| 22 | Resolved | §8.14.13 reads "A `[0.5, 0.92]` sheet", which matches §7.9. |
| 23 | Resolved | The §4.8 row has seven scrolls with seven durations. §8.30.1 has "it scrolls 400 ms `settle`" and §8.20 has "400 ms `settle`". |
| 24 | Resolved | §4.1 principle 4 defers to §4.5. §8.0.4 Back has "Page 224 ms; a reversed match cut runs 336 ms `turn`", and §4.5 Match cut has "reversed on back 336 ms". "0.7 × the entrance" is gone. |
| 25 | Resolved | §8.14.11 reads "(`dur.hold.toast`, 3600 ms)". No 5200 remains. |
| 26 | Resolved | §7.7 Below is `type.title` with no size, §7.10 Title is `type.subhead` (Bodoni Moda), §7.11 Text is `type.ui` `ink.100`, and §7.15 Items label is `type.ui` `ink.60`. No "`type.ui` 15", "14/20" or "24/28" remains attached to those roles. |
| 27 | Resolved | §7.14 Cell is "Icon 24". §7.18 leader dial lists 32 / 24 / 16 / 12, and every leader dial in the file uses one of these sizes. |
| 28 | Resolved | The §7.25 size list includes 28, 56 and 112. Note: WEB-26 has since moved the §7.13 profile chip to 32 px, so 28 is now unused. A spare size is harmless. |
| 29 | Resolved | The §2.3 `radius.round` allow-list matches the fix, and §8.22's `TOP` button is a 40 px square. No scroll-to-top dot remains. |
| 30 | Resolved | §2.2.2's first rule says rails "do not snap to column starts". |
| 31 | Resolved | §7.1 `primary` sm is 32 on every platform with a padded hit area. `split` is lg 56 / md 48 / sm 32. "desktop dense rows only" is gone, and §14.6's "desktop `sm` button (32)" is consistent under a fine pointer. |
| 32 | Resolved | §14.2 gives the six fixed stocks at ≥ 13.4 / 5.8 and Issue at ≥ 13 / 5.5. Recomputed: the minimum is 13.42 (Sepia Night) / 5.84 (Moss). |
| 33 | Resolved | §3.5 has a `type.credit.label` row (web and Flutter), §3.2 `type.credit` names both, and §7.29 Credits uses both. |
| 34 | Resolved | §5 has a `splash.impress` row, §15.1 has `"splash.impress": "ahap:impress"`, the §6 map sends `splash.impress` to "—", and §12.4 fires the event by name. No bare "haptic `impress`" remains. |
| 35 | Resolved | §7.11 edge colours are `spot` / `set` / `proof`. |
| 36 | Resolved | The §4.8 Recap countdown reduced row and §9.1.5's reduced clause both say the folio segment updates once per second. "Continuing in 12 s" is gone. |
| 37 | Resolved | §8.15.5 Size and Line spacing defaults follow §3.4 per face (Atkinson 1.70, Archivo 18 / 17). |
| 38 | Resolved | §8.14.7 and §8.15.4 have `SLIDE` = 280 ms `ease.settle` (`dur.pageturn`). `dur.pageturn` appears in §4.2, §2.8.4 and the §15.1 JSON. No 300 ms `set` slide remains. |
| 39 | Resolved | §7.1 `play` is 64 / 56 / 36. It matches §8.16.2 (36) and §8.16.3 (64, and 56 on phones). |
| 40 | Resolved | §8.16.5 uses alpha = 0.08 + 0.24 × RMS, and the reduced-motion static band at 0.20 appears in both §8.16.5 and §4.8. "0.08–0.32" is gone. |
| 41 | **Unresolved** | See below. |
| 42 | Resolved | §8.34 reads "the "Front pages" screenshot set (§12.6)". |
| 43 | Resolved | §15.2 and §15.11 give Embla four phone pagers (and §11 agrees). §15.3 and §15.11 give `flutter_animate` rack focus, flicker and flame. |
| 44 | Resolved | §2.8.1 has a `color.note` row and the §15.1 JSON has `"note": "#F4D03F"`. |
| 45 | Resolved | §2.8.3 `scrimVignette` is `radius: 1.0` with `CssEllipse(rx: 1.2, ry: 0.9)`, defined under the table. The geometry was re-derived: centre (0.5 w, 0.4 h) and radii 1.2 w × 0.9 h. |
| 46 | Resolved | §9.4.4 Sampling uses the page under the reading line at 38 %, and §2.1.5 keeps its wording. "occupying ≥ 50 %" is gone. |
| 47 | Resolved | §8.15.4 One hand is left 25 % plus a full-width 12 % top band, and §14.6 has the band-height rule. |
| 48 | Resolved | §4.6 "After a skeleton", §7.17, §4.7, §8.22 ("dissolves the plates into posters (160 ms)") and §8.7 step 5 agree. |
| 49 | Resolved | §8.8 item 3 has the centred 86 % pager, 6 px padding and about 21 px of neighbour, with PageView and Embla specified. Re-derived: (390 − 335.4) / 2 − 6 = 21.3. §8.9 Library Continue points at the same geometry. "12 px peek" is gone. |
| 50 | **Unresolved** | See below. |

---

## Unresolved

### CONSISTENCY-13: the §6 summary sentence contradicts the policy table under it
MOBILE-4 moved the one-session rule into §6 as the "Audio session and focus policy" table. The move itself is fine, and §9.4.2, §8.16.10 and §14.9 all point at the table. The table also adds a **Voice sample** state (`.playback` with `.duckOthers`; §8.16.5 `Hear` uses it). Two sentences next to it still describe the older two-state rule:
- §6 "Playback" paragraph says the session is "`.ambient` with `mixWithOthers` whenever narration is not active … the user's music is never ducked". During a `Hear` sample the session is `.playback` + `.duckOthers`, and the user's music ducks.
- §14.9 says "(`.ambient` category outside narration; …)".

**Fix:** In §6, change the sentence to "is `.ambient` with `mixWithOthers` whenever neither narration nor a voice sample is active (State A), so the ring/silent switch mutes cues; cues are suppressed while narration or a soundscape plays; UI cues never duck the user's music". In §14.9, change it to "(`.ambient` outside narration and voice samples, §6)".

### CONSISTENCY-14: §7.25 states a contrast figure for a hex that no longer exists
The six darkened fields are in place in §7.25 and §2.8.1 (Flutter values included), and the old hexes are gone. After that, the A11Y-41 fix (written against the old hexes) rewrote the §7.25 claim as "(≥ 3:1, a non-text glyph; **3.06:1 minimum on Marquee**, …)". Marquee is now `#85690C`, which is **4.58:1** against `ink.100`. Recomputed across all twelve fields, the minimum is 4.53:1 (Usher `#95630F`). The A11Y-41 loop line in §2.1.1 also says "the **six** avatar fields (≥ 3:1 …)", but there are twelve fields.

**Fix:** In §7.25, change it to "(≥ 3:1 is required for a non-text glyph; every field reaches 4.5:1, 4.53:1 minimum on Usher; checked by the surface × ink loop, §2.1.1)". In §2.1.1, change it to "checks `ink.100` on the twelve avatar fields (≥ 4.5:1, §7.25)". This keeps both lenses' intent: A11Y's 3:1 requirement, and the darkened fields that exceed it.

### CONSISTENCY-15: a raw colour back in §7.7
The seven tokens, their JSON, the `@theme` caret keyframes and the lint-scope paragraph are all in place, and every section the fix names now uses the token names. WEB-12 has since added the §7.7 row "Select mode, unselected … a 1 px `ink.100` outline on `rgba(0,0,0,0.64)`". That value is `color.onart`, written raw inside a component spec, which is the defect class this finding removed. A literal copy into code (`bg-[rgba(0,0,0,0.64)]`) would also fail the §2.8 lint.

**Fix:** In §7.7 "Select mode, unselected", replace "on `rgba(0,0,0,0.64)`" with "on `color.onart`".

### CONSISTENCY-19: "completed" appears again as a label
The vocabulary paragraph, the §8.9 slug line and keys, the Filters sheet, the §8.17 select, the §7.19 badges and the §7.5 example all match. Two places still conflict with "one label per stored value … everywhere" and "`COMPLETED` is reserved for publication status":
- PRODUCT-19 added a quiet **`Mark as completed`** action (it sends `reading_status: "completed"`) to §8.14.6 "The end" and to the §8.15.2 novel end matter. That status is labelled `DONE` everywhere else.
- §8.31 Recent checks shows a checker-job badge "`COMPLETED` set". This text predates the fix, but it now breaks the reservation rule.

**Fix:** In §8.14.6 and §8.15.2, rename the action to `Mark as done` (the request body is unchanged). In §8.31, change the job badge to `FINISHED` (set).

### CONSISTENCY-41: §2.1.4 and §2.8.3 give the new scrim different geometry
§2.8.3 follows the fix: "bottom 60 % of its band, 13 eased stops to `#000000`", with Flutter `Alignment(0, -0.2)` → `Alignment.bottomCenter`, so the scrim is solid at the band's bottom edge. §2.1.4 says instead "Bottom of its band, top → bottom, **with the same 24 px placement rule as `scrim.foot`**". That rule places the ramp relative to a text block measured on the art. In §9.1.5 the recap text sits on the `#000` page below the band, so there is no text block to measure, and the two sections describe different gradients.

**Fix:** Change the §2.1.4 `scrim.foot.black` Geometry cell to "The bottom 60 % of its band, top → bottom, reaching `#000000` at the band's bottom edge (no text sits on the band)".

### CONSISTENCY-50: the kind list still leaves two key groups unclassified
§15.1 now has six kinds (including **integer**), the `"linear"` curve literal and a structured-groups sentence. §15.1 also says the JSON "uses exactly the key space of §2.8 and §3.5". Two §2.8 groups fit none of the six kinds and are missing from the structured-groups list:
- `scrim.*` (§2.8.3): gradient descriptions such as `scrim.foot` and `scrim.vignette`.
- `focus.*` (§2.8.2): `focus.halo` is "6 px `#000000`".

`design/build.mjs`, which "needs one rule per kind", still has no rule for these groups.

**Fix:** In the §15.1 sentence, change it to "`font`, `type`, `grid`, `bp`, `rule`, `scrim`, `focus`, `haptics`, `sounds` and `soundEvents` are structured groups, each emitted by its own rule with the shapes shown in §2.8.2, §2.8.3, §3.5, §5 and §6."

---

## Notes (not blocking; no id reopened)

- §4.7 says "A letter reveal that leaves the viewport before it finishes jumps to its end state; it never replays in the same session". Titles with `trigger: "signal"` replay on every mount (§10.1.1). This predates round 1. Suggested wording: "… it does not replay while mounted; `inView` and `mount` headings never replay in the same session".
- §8.2 says "Tap anywhere skips to the hold" and §12.4 says "Tap skips to the hand-off". Both predate round 1, and they agree if read as "to the hold while the probe is pending, otherwise to the hand-off". One clause in §12.4 would make that explicit.
- The §7.25 avatar size 28 is unused since WEB-26 (see CONSISTENCY-28).
