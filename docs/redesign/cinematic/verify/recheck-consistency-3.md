# Cinematic DESIGN.md: recheck round 3, lens consistency

Input: the 49 findings in the "Confirmed" section of `cinematic/verify/judge-consistency.md`. CONSISTENCY-18 was refuted and is not checked. The file was checked after the round 3 fixes logged in `fixed-consistency.md` (CONSISTENCY-13 in §15.8, CONSISTENCY-37 in §3.3 and §8.15.5). Target: `cinematic/DESIGN.md`.

Other lenses were still writing to the file during this pass. It changed three times, staying at 4,657 lines: 665,056 bytes (23:03:21 UTC), then 667,010 bytes (23:09:27), then 667,554 bytes (23:12:11). Every check was run against the 23:03 snapshot and then re-run against each later version. Neither diff touched the passages below.
- The 23:09 diff changed the `scrim.sole` positioning note, the `CineSprings` const/getter note and the `.description` in the sheet release, the preview root layout's `globals.css` import and `preview-query.tsx`, and `milestones_seen` on the `/home` streak object.
- The 23:12 diff changed the over-art clause of the §2.1.1 `ink.45` paragraph, the Source card kicker's chapter count in §7.6, the recap countdown's `keydown` exceptions in §9.1.5, and the §15.6 limiter, which became a sliding window. It left the §2.1.1 "(≥ 5.84:1)" figure discussed under CONSISTENCY-32 unchanged.

## Method

1. For each finding, read the sections the final fix names and compared them with the fix text.
2. Grepped the whole file for every old value that should be gone, and for every other place where a changed value is repeated.
3. Ran a scripted presence and absence check on the 23:09 and 23:12 files. It holds 121 required phrases, one or more per finding, and all 121 are present. It also holds 51 old values. 49 of them are absent. The other two hits are expected:
   - `0.7 ×` is the K32 warmth migration formula (§8.14.8). It is not the old exit rule.
   - `Curves.easeInOutSine` appears only inside the §4.3 caveat, "(not `Curves.easeInOutSine`, which is …)".

### Arithmetic recomputed

- **Avatar contrast** (WCAG 2.x, `ink.100` `#F3F0E8` on all twelve fields): minimum 4.53 on Usher `#95630F`, maximum 6.82 on Phantom `#474B94`. Every field is at or above 4.5.
- **Splash**: 252 + 12 × 24 = 540, and 540 + 640 = 1180. `min(24, 560 / 12)` = 24.
- **Column wipe**:
  - Totals: 616 / 744 / 872 ms.
  - Dip saving: 176 / 304 / 432 ms.
  - Stop-the-press close: 80–456 on desktop, 80–392 on tablets, 80 + 248 on phones.
- **Caret**: keyframes at 530 / 3340 = 15.87 %, 31.74 %, 47.60 %, 63.47 %, 79.34 %, 95.21 %. The Flutter `(ms ~/ 530).isOdd` sequence is off, on, off, on, off, on. 1 / 1.06 s = 0.94 Hz.
- **Fluid line-height ratios**: for example 84 / 88 = 0.955, 48 / 44 = 1.091, 32 / 28 = 1.143 and 88 / 96 = 0.917. All 20 cells match §3.2 and §3.5.
- **Letter stagger**: "Library" (n = 7) ends at 784 ms. 40 graphemes end at 560 + 640 = 1200 ms.
- **Pager**: 0.86 × 390 = 335.4 px, and (390 − 335.4) / 2 − 6 = 21.3 px of neighbour.
- **Novel default size at system 2.0**: 18 → 36 px in Newsreader, 17 → 34 px in Archivo.

A finding also counts as resolved where another lens rewrote a passage after the consistency fix went in, provided the goal of the consistency fix still holds everywhere and the new text contradicts nothing.

**Result: 48 resolved, 1 unresolved (CONSISTENCY-32).**
- Both round-2 leftovers are fixed: CONSISTENCY-13 (§15.8 now contains the audio-session check that §6 cites) and CONSISTENCY-37 (§3.3 uses the per-face default `d`).
- CONSISTENCY-32 is reopened. A stock-contrast figure added to §2.1.1 during the fix rounds repeats the old "every stock" claim, and it now contradicts the fixed §14.2 bullet and §2.1.6. The claim is not in the committed HEAD version, so it was written after the judge ran.

---

## Per finding

| ID | Status | Evidence in the file |
|---|---|---|
| 1 | Resolved | §7.24 Mark: the 16 and 20 px mark "is the §7.19 badge" (Archivo `wdth` 62 `wght` 800 at 10 / 12 px). The 160 px dialog mark has a 2 px border and Bodoni Moda 900 at 88 px. §2.7 `certificate-18` is "the icon-slot form, for menu items and settings rows only; never drawn in place of the §7.19 badge". §7.25 and §8.5 both read "20 px certificate (the §7.19 badge)". No 4 px border remains. |
| 2 | Resolved | §12.4 rows: 252–572 monogram (`lift`), 252–1180 Letter set at standard timings, 700–1180 Rule draw (480 ms `settle`), the impression at 1180 with haptic `splash.impress`, and the 1180–1400 hand-off (220 ms). Duration rule: `max(probeDone, 1180 ms)`, "the reveal is never stretched", hold after the impression, dial after 2400 ms. §8.2 defers to it ("pending at 1180 ms the masthead holds"). §4.2 `dur.reel` is "1180 ms choreography + 220 ms hand-off". The §6 `reel` cue lands its hit at 1180 ms. `max(probe, 900`, `max(dataReady` and "capped at 1400" are gone. |
| 3 | Resolved | §7.11 Surface is a `paper.2` band with `data-stock="raised"` / `CineStock.raised`. The §2.1.1 raised-scope list names "toast", and §2.4 level 2 lists toasts. |
| 4 | Resolved (superseded by WEB-2) | There is one spine range everywhere: 768–1279 in §1, §7.15 ("Auto-spine at 768–1279; expanded from 1280"), §8.0.1 and §8.0.9. 768–1023 remains only as the 8-column grid range. |
| 5 | Resolved | The §4.3 Use column matches the fix word for word. The §4.5 Lightbox row and §7.30 Dismiss read "320 ms `ease.turn` (a reverse match cut)". Iris: close `turn` (§8.5, 480 ms), out `settle` (560 ms). Every rule slide (§7.5 slug line and segmented control, §7.12 indicator, §7.14 notch, §4.5 Rule slide) is 320 ms `settle`. |
| 6 | Resolved | §4.3 `ease.drift` Flutter: `Cubic(0.37, 0, 0.63, 1)` with the `easeInOutSine` caveat, and JSON `"drift": { "bezier": [0.37, 0, 0.63, 1] }`. |
| 7 | Resolved | §3.2 has the per-breakpoint ratio table, and every cell was recomputed. The five §3.5 fluid rows repeat the same ratios. "cover 0.93, the others 1.0" is gone. |
| 8 | Resolved | §4.6 and §10.1.1 say "`n` = graphemes excluding spaces". Web: `graphemes(text.replaceAll(" ", "")).length`. Flutter: `late final double _step`, `start = 120.0 + _step * k`, and a `.round()`ed controller duration. |
| 9 | Resolved (items 1 and 3 superseded by PRODUCT-12) | `"signal"` / `SetTrigger.signal` never reads or writes `seen` (web `once = !signal && seen.has(id)`, writes guarded by `!signal`; Flutter `_seenAtMount = !_signal && …`). Leaving mid-reveal: the web `idle/run/done` phase with `half` and `any` plus `wasIn`, and Flutter `visible == 0` → `_c.value = 1`. The reveal is per letter at every length (§10.1.1, §10.1.6). No `WORD_LIMIT`, `_byWord` or "60 letters" remains. |
| 10 | Resolved | §10.2.1 and §10.2.3: six 530 ms halves (3180 ms), then a 160 ms fade. The `@theme` keyframes are exact, with `animation-timing-function: linear` at 95.21 %. The §10.2.4 Flutter formula matches the fix, and §14.10 says 0.94 Hz. |
| 11 | Resolved | §4.5 has "tablet (8 blades) 312 + 40 + 392 = 744 ms". §8.14.2 has the close and open steps with tablet figures, the route-duration formula with 616 / 744 / 872, and "304 ms sooner on tablets". §8.30.3 has "tablets: blades close 80–392". |
| 12 | Resolved | 16 × 16 on both clients: the §2.1.5 row (Flutter `ResizeImage(… 16, 16, ResizeImagePolicy.exact)`, web `imageSmoothingQuality = "medium"`), the picker text ("256 pixels … the same input on both clients"), §9.4.4, §15.2, §15.3 `page_tint.dart`, §15.6, Appendix A row 1 and "Adapted, not copied". No `64 × h` or 64 px sampler remains. |
| 13 | Resolved | §15.8 now has the check that §6 cites: "on the iPhone, the pass also logs `AVAudioSession.sharedInstance().category` right after `SoLoud.instance.init()` and after a `Hear` sample ends, and both must read `.ambient` (State A, §6); if they do not, `skin_audio.dart` re-applies State A after init (§6)". The one-session rule is consistent in the §6 summary, the State A / B / Voice sample table, §8.16.10 ("State B, `speech()` … while narration is active"), §9.4.2 Audio session and §14.9. §6 also states that `flutter_soloud` sets no category. The judge wanted a device check instead of a bare assertion; the check is present, so that goal holds. "stays speech" is gone. |
| 14 | Resolved | The §7.25 table and the §2.8.1 rows carry the six darkened fields with their Flutter values. §7.25 says "every field reaches 4.5:1, 4.53:1 minimum on Usher". The §2.1.1 loop checks "`ink.100` on the twelve avatar fields (≥ 4.5:1, §7.25)". Recomputed: 4.53 to 6.82. No old hex, "3.06:1" or "six avatar fields" remains. |
| 15 | Resolved | The seven tokens are in §2.8.1 and the §15.1 JSON. They are used by name in §7.1, §7.2, §7.7 (hairline, and the select-mode outline on `color.onart`), §7.17, §7.18, §7.30, §8.14.8, §8.24, §9.2.4 and §9.4.3. The raw values appear only in the token rows, the JSON, and three plain-language notes after the token name (§7.30, §8.24, §9.4.3). The §10.2.3 `@theme` block holds `--animate-caret-out` and its keyframes. §2.8 has the Lint scope paragraph. |
| 16 | Resolved | §9.4.3 Moving is 30 / 40 / 30, with the centre toggling the chrome. §8.14.7 is 30 / 40 / 30. §11 has "30 / 40 / 30 (manga paged and guided view), 25 / 50 / 25 (novel)", and §8.15.4 has 25 / 50 / 25. "30 / 70" is gone. |
| 17 | Resolved | The §8.15.3 heading ("fades in 240 ms `settle`, out 160 ms `lift`; no slide") matches the §4.8 row "Reader chrome in / out (manga and novel)". §8.14.3 is 240 in / 160 out. No "fades 180 ms" remains. |
| 19 | Resolved | The §7.19 vocabulary paragraph and badge row, the §8.9 slug line, keys `1`–`7` and the phone Filters sheet ("reading status with the slug line's labels"), the §8.17 select and the §7.5 example all match. §8.14.6 and §8.15.2 say `Mark as done` (the body stays `reading_status: "completed"`), and §8.31 says `FINISHED`. `COMPLETED` remains only as a publication status. |
| 20 | Resolved | The §9.1.8 unavailable state shows `NOTE` in `spot` (`color.note`) with the reason in `ink.60`, and the recap slate's `RECAP UNAVAILABLE` stays `ink.45` (§9.1.5 agrees). §7.8 says "(in `spot`, as §9.1.8)". |
| 21 | Resolved | `type.dropcap` in §3.2 and §3.5 is 3 × the paragraph's line height, `opsz` = min(size, 96), web `calc(var(--para-lh) * 3)` and Flutter `CineType.dropcap(double paragraphLineHeightPx)`. No `typeDropcap` or fixed `sizes` remains. |
| 22 | Resolved | §8.14.13 reads "A `[0.5, 0.92]` sheet (phone) or menu (desktop)", which matches §7.9's live-preview list. |
| 23 | Resolved | The §4.8 row lists seven scrolls with seven durations: 560 / 320 / 400 / 400 / 300 / 400 / 400. They match §7.8, §7.14 (tab tap 400), §8.16.3 (transcript 400), §4.3 `ease.scroll` (300), §8.30.1 and §8.20 (both "400 ms `settle`"). |
| 24 | Resolved | §4.1 principle 4 defers to §4.5. §8.0.4 Back has "Page 224 ms; a reversed match cut runs 336 ms `turn`", and the §4.5 Match cut row has "reversed on back 336 ms". The old "0.7 ×" rule is gone; the only remaining "0.7 ×" is the unrelated warmth migration. |
| 25 | Resolved | §8.14.11 reads "(`dur.hold.toast`, 3600 ms)". No 5200 remains. |
| 26 | Resolved | §7.7 Below (`type.title`), §7.10 Title (`type.subhead` (Bodoni Moda)), §7.11 Text (`type.ui` `ink.100`) and §7.15 Items label (`type.ui` `ink.60`) all name the role with no size. A sibling outside these sections is in the Notes. |
| 27 | Resolved | §7.14 Cell is "Icon 24". §7.18 has "32 px circle (24 inline, 16 in controls, 12 inside a switch knob)". Every leader dial in the file is 32, 24, 16 or 12 px, and no "Icon 22" remains. |
| 28 | Resolved | The §7.25 size list (20, 24, 28, 32, 44, 56, 96, 112, 144) covers every avatar size in use: 20, 32, 44, 56, 96, 112, 144. |
| 29 | Resolved | The §2.3 allow-list matches the fix. §8.22 `TOP` is a 40 px square. One unlisted round shape is in the Notes. |
| 30 | Resolved | The first §2.2.2 rule says rails "do not snap to column starts". |
| 31 | Resolved | §7.1 `primary` sm is 32 on every platform with a padded hit area, and `split` is lg 56 / md 48 / sm 32 (the now-showing strip). §14.6's fine-pointer clause agrees. |
| 32 | **Unresolved** | The §14.2 bullet itself matches the fix. See below. |
| 33 | Resolved (cap superseded by A11Y-40) | The §3.5 `type.credit.label` row, the §3.2 `type.credit` row and §7.28 Credits use both roles. The cap is 2.0 in both §3.5 and the §3.3 caps table (A11Y-40), not the fix's 1.5, and it is stated consistently. |
| 34 | Resolved | §5 has a `splash.impress` row, §15.1 has `"splash.impress": "ahap:impress"`, the §6 map sends it to "— (the `reel` cue carries the hit)", and §12.4 reads "haptic `splash.impress` (§5)". No "haptic `impress`" remains. |
| 35 | Resolved | The §7.11 edge is "`spot` for info, `set` for success and completion, `proof` for errors". |
| 36 | Resolved | The §4.8 Recap countdown reduced row and the §9.1.5 reduced clause agree. "Continuing in 12 s" is gone. |
| 37 | Resolved | §3.3 reads "`clamp(round(MediaQuery.textScalerOf(context).scale(d)), 14, 40)` for the face's default size `d` (§3.4, §8.15.5), so a user at system 2.0 starts at 36 px in Newsreader (34 px in Archivo)". §8.15.5 Size says "starts at 36 px (34 px in Archivo)", and Line spacing is 1.60 / 1.70 (Atkinson). Both match §3.4. §14.7 names no fixed size. No `scale(18)` remains. |
| 38 | Resolved | §8.14.7 and §8.15.4 give `SLIDE` = 280 ms `ease.settle` (`dur.pageturn`) with `spring.release`. `dur.pageturn` is in §4.2, §2.8.4 and the JSON. No 300 ms `set` remains. |
| 39 | Resolved | §7.1 `play` is 64 / 56 / 36, matching §8.16.2 (36) and §8.16.3 (64, and 56 on phones). |
| 40 | Resolved | §8.16.5 uses alpha = 0.08 + 0.24 × RMS. The reduced-motion alpha is 0.20 in both §8.16.5 and §4.8. |
| 41 | Resolved | `scrim.foot.black` in §2.1.4 (the bottom 60 %, no text) matches §2.8.3 (`Alignment(0, -0.2)` → `bottomCenter`). §9.1.5 uses it, and §15.7 notes that it carries no text. |
| 42 | Resolved | §8.34 reads "the "Front pages" screenshot set (§12.6)", which matches §12.3 and §12.6. |
| 43 | Resolved | §15.2 and §15.11 give Embla four phone pagers, and §11 names Embla for three of them. §15.3 and §15.11 give `flutter_animate` rack focus, flicker and flame. |
| 44 | Resolved | §2.8.1 has the `color.note` row and the JSON has `"note": "#F4D03F"`. |
| 45 | Resolved | §2.8.3 `scrimVignette` uses `radius: 1.0` with `CssEllipse(rx: 1.2, ry: 0.9)`, and the transform is defined under the table. |
| 46 | Resolved | §9.4.4 Sampling uses the page under the reading line at 38 %, matching §2.1.5. No "≥ 50 %" remains. |
| 47 | Resolved | The §8.15.4 One hand preset is left 25 % plus a full-width 12 % top band, and §14.6 has the band-height rule. No "20 % back" remains. |
| 48 | Resolved | §4.6 "After a skeleton", §4.7, §7.17, §8.22 ("dissolves the plates into posters (160 ms)") and §8.7 step 5 all agree. |
| 49 | Resolved | §8.8 item 3 gives the centred 86 % geometry, with PageView (default `padEnds`) and Embla specified. The §8.9 Library Continue pager points at it. No "12 px peek" remains. |
| 50 | Resolved | §15.1 lists six kinds, including **integer**, and the `"linear"` literal. The structured groups sentence names `font`, `type`, `grid`, `bp`, `rule`, `scrim`, `focus`, `haptics`, `sounds` and `soundEvents`, citing §2.8.2, §2.8.3, §3.5, §5 and §6. The JSON groups visible in the excerpt (`space`, `radius`, `blur`, `z`, `dur`, `ease`, `spring`, `scalar`) each have a kind. |

---

## Unresolved

### CONSISTENCY-32: §2.1.1 still claims ≥ 5.84:1 for every stock's muted colour

§14.2's last bullet now reads as the fix says: "the six fixed stocks: ink ≥ 13.4:1, muted ≥ 5.8:1; the Issue stock: ink ≥ 13:1, muted ≥ 5.5:1 (§2.1.6)". §2.1.6 agrees: the lowest fixed-stock muted value is Moss at 5.84:1, and the Issue stock's muted is darkened "until 5.5:1 on the page".

The raised-scope paragraph of §2.1.1, however, gives one figure for every stock. It was added during the fix rounds and is not in the committed HEAD version. It reads: "**Stock-painted panels** (the novel margins panel, the contents sheet, the mini player, the next card and a rating card drawn in stock colours) render `ink.45` roles in the stock's `muted` colour (≥ 5.84:1)".

The Issue stock is one of the seven stocks in the §8.15.5 Stock control. In a book read on the Issue stock, those panels use a muted colour that is only guaranteed ≥ 5.5:1. So §2.1.1 repeats, for stock-painted panels, the "every stock" claim that CONSISTENCY-32 removed from §14.2, and it now contradicts §14.2 and §2.1.6. The accessibility floor is not affected, because 5.5 is still ≥ 4.5. What is wrong is the stated figure, which is the same defect the finding fixed.

**Fix:** In §2.1.1, replace "render `ink.45` roles in the stock's `muted` colour (≥ 5.84:1)" with "render `ink.45` roles in the stock's `muted` colour (≥ 5.84:1 on the six fixed stocks, ≥ 5.5:1 on the Issue stock, §2.1.6)". Nothing else changes. §14.2's first bullet cites §2.1.1 without a figure.

---

## Notes (not blocking; no id reopened)

These are carried over from round 2 unless marked new. All still apply to the 23:12 file.

- **§4.7 replay wording.** §4.7 still says a letter reveal that leaves the viewport mid-reveal "never replays in the same session", but `signal` titles replay on every mount (§10.1.1). Suggested wording: "… jumps to its end state; it does not replay while mounted, and `inView` and `mount` headings never replay in the same session".
- **Splash tap target.** §8.2 says "Tap anywhere skips to the hold" and §12.4 says "Tap skips to the hand-off". They agree only if read as "to the hold while the probe is pending, otherwise to the hand-off". Adding that clause to §12.4 would make it explicit.
- **20 px badge places.** §7.19's badge row says "16 × 16 (20 × 20 on feature pages)". §7.24 also uses the 20 px badge on the rating card at reader start and on the picker's avatar marker, which are not feature pages. The judge left §7.19 unchanged. Suggested wording: "(20 × 20 in the places §7.24 lists)".
- **Keycap size (CONSISTENCY-26 class).** §7.26 Keycaps still says "`type.folio` 12", which is 13 px at wide, and it lies outside the fix's named sections. Suggested wording: "`type.folio`".
- **Speed ruler detent.** §8.16.4's speed ruler opens a `[0.5]` sheet, while §7.9 names only content-fit or `[0.5, 0.92]` detents. §9.2.5's share sheet is likewise `[0.92]`. Both are deliberate fixed detents that §7.9 does not list.
- **Audio check precondition (new).** §15.8's check requires `.ambient` "after a `Hear` sample ends". Per §6 ("after a sample ends, the previous state returns"), that holds only when the sample was played from State A. A `Hear` pressed in the reader's AMBIENT group while narration is paused returns to State B (`.playback`). Suggested wording: "after a `Hear` sample ends with no narration active".
- **Clock chart shape (new, CONSISTENCY-29 class).** §9.2.1 draws the 24-hour clock chart inside "a 160 px circle", which the §2.3 `radius.round` allow-list does not name. It is a polar chart's frame rather than a rounded control. Adding "the 24-hour clock chart" to the list, or saying the chart has no drawn outline, would close it.
