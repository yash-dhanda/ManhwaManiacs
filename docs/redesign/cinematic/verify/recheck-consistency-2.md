# Cinematic DESIGN.md: recheck round 2, lens consistency

Input: the 49 findings in the "Confirmed" section of `cinematic/verify/judge-consistency.md` (CONSISTENCY-18 was refuted and is not checked), after the round 2 fixes logged in `fixed-consistency.md`. Target: `cinematic/DESIGN.md`. The other lenses were still writing to the file during this pass: it changed from 652,675 bytes (22:50 UTC) to 661,493 bytes (23:00) and then to 664,006 bytes / 4,657 lines (23:01). Every check was run against the 22:50 snapshot, then re-run against the 23:00 and 23:01 versions. The 23:00 diff (scrim head/sole geometry, the `(app)` route group, `/home` streak shape, Circle endpoints, the `useWordsFit` node-swap fix, the Flutter `FadeTransition`) touched none of the passages below.

Method: for each finding, read the sections the final fix names and compare them with the fix text. Then grep the whole file for every old value that should be gone and for every other place the changed value is repeated. A scripted presence and absence check covers all 49 findings: 120 required phrases and 37 old values, all passing on the 23:01 file. Arithmetic was recomputed:
- avatar contrast (WCAG 2.x): minimum 4.53 on Usher `#95630F`, maximum 6.82 on Phantom;
- caret keyframes: 530 / 3340 = 15.87 %, …, 3180 / 3340 = 95.21 %;
- column-wipe totals: 616 / 744 / 872 ms; Dip saving 176 / 304 / 432 ms;
- fluid line-height ratios (for example 84 / 88 = 0.955);
- splash letters: 252 + 12 × 24 = 540, and 540 + 640 = 1180;
- pager geometry: (390 − 335.4) / 2 − 6 = 21.3 px;
- `scrim.foot.black`: `Alignment(0, -0.2)` sits at 40 % of the height, so the ramp covers the bottom 60 %;
- the `CssEllipse` transform gives radii 1.2 w × 0.9 h centred at (0.5 w, 0.4 h).

Where another lens rewrote a passage after the consistency fix went in, the finding counts as resolved if the goal of the consistency fix still holds everywhere and the new text contradicts nothing.

**Result: 47 resolved, 2 unresolved** (CONSISTENCY-13, CONSISTENCY-37). All six round-1 leftovers (13, 14, 15, 19, 41, 50) now read as their fixes say. CONSISTENCY-13 stays open on one dangling cross-reference, which its own fix text created. CONSISTENCY-37 is reopened because MOBILE-8 later wrote a fixed 18 px default into §3.3, which conflicts with the per-face rule.

---

## Per finding

| ID | Status | Evidence in the file |
|---|---|---|
| 1 | Resolved | §7.24 Mark: the 16 and 20 px mark "is the §7.19 badge" (Archivo `wdth` 62 `wght` 800 at 10 / 12 px). The 160 px dialog mark has a 2 px border and Bodoni 900 at 88 px. §2.7 `certificate-18` is "the icon-slot form, for menu items and settings rows only". §7.25 and §8.5 read "(the §7.19 badge)". No 4 px border remains. |
| 2 | Resolved | §12.4 rows: 252–572 monogram, 252–1180 Letter set, 700–1180 Rule draw, the 1180 impression with `splash.impress`, 1180–1400 hand-off. Duration rule: `max(probeDone, 1180 ms)`. §8.2 defers to it ("pending at 1180 ms the masthead holds"). §4.2 `dur.reel` is "1180 ms choreography + 220 ms hand-off". `max(probe, 900`, `max(dataReady` and "capped at 1400" are gone. |
| 3 | Resolved | §7.11 Surface is `paper.2` with `data-stock="raised"` / `CineStock.raised`. "toast" is in the §2.1.1 raised-scope list, and §2.4 level 2 lists toasts. |
| 4 | Resolved (superseded by WEB-2) | The spine is 768–1279 in §1, §7.15 (expanded from 1280), §8.0.1 and §8.0.9. 768–1023 remains only as the 8-column grid range. There is one spine range everywhere. |
| 5 | Resolved | The §4.3 Use column matches the fix word for word. The §4.5 Lightbox row and §7.30 Dismiss read "320 ms `ease.turn` (a reverse match cut)". Iris is close `turn`, out `settle` (§4.5, §8.5). Every rule slide (§7.5 slug line and segmented control, §7.12, §7.14 notch) uses 320 ms `settle`. |
| 6 | Resolved | The §4.3 `ease.drift` Flutter column is `Cubic(0.37, 0, 0.63, 1)` with the `easeInOutSine` caveat. `easeInOutSine` is used nowhere else. |
| 7 | Resolved | §3.2 has the per-breakpoint ratio table, and every value was recomputed. The five §3.5 fluid rows repeat the same ratios. "cover 0.93, the others 1.0" is gone. |
| 8 | Resolved | §4.6 and §10.1.1 say "`n` = graphemes excluding spaces". Web: `graphemes(text.replaceAll(" ", "")).length`. Flutter: `double _step`, `start = 120.0 + _step * k`, and a `.round()`ed duration. |
| 9 | Resolved (items 1 and 3 superseded by PRODUCT-12) | `trigger: "signal"` / `SetTrigger.signal` never reads or writes `seen`. The reveal is "per letter at every length", with no word fallback, in §10.1.1, §10.1.6 and §15.6. The leave-mid-reveal jump is on the web (the `idle/run/done` phase with `half` and `any`) and in Flutter (`visible == 0`). No `WORD_LIMIT`, `_byWord` or "60 letters" remains. |
| 10 | Resolved | §10.2.1 and §10.2.3: six 530 ms halves, then a 160 ms fade. The keyframes are exact, with a per-keyframe `linear` at 95.21 %. The §10.2.4 Flutter formula matches the fix. §14.10 says 0.94 Hz. |
| 11 | Resolved | §4.5 has "tablet (8 blades) 312 + 40 + 392 = 744 ms". §8.14.2 has the steps, the formula, 616 / 744 / 872, and "304 ms sooner on tablets". §8.30.3 has "tablets: blades close 80–392". |
| 12 | Resolved | 16 × 16 on both clients in the §2.1.5 row and picker (256 pixels, vectors note), §9.4.4, §15.2, §15.3 `page_tint.dart`, §15.6, the Appendix A graft row and "Adapted, not copied". No 64 px or 64 × h sampler remains. |
| 13 | **Unresolved** | See below. The round-1 leftover is fixed: §6 now reads "whenever neither narration nor a voice sample is active (State A) … UI cues never duck the user's music", and §14.9 reads "(`.ambient` outside narration and voice samples, §6)". |
| 14 | Resolved | The §7.25 table and the §2.8.1 rows (with Flutter values) carry the six darkened fields. The §7.25 intro says "≥ 3:1 is required … every field reaches 4.5:1, 4.53:1 minimum on Usher". The §2.1.1 loop says "`ink.100` on the twelve avatar fields (≥ 4.5:1, §7.25)". Recomputed: 4.53 (Usher) to 6.82 (Phantom). No old hex, "3.06:1" or "six avatar fields" remains. |
| 15 | Resolved | The seven tokens are in §2.8.1 and in the §15.1 JSON. The §10.2.3 `@theme` block holds `--animate-caret-out` and its keyframes, and there is a §2.8 "Lint scope" paragraph. §7.7 "Select mode, unselected" is now "on `color.onart`". The raw values appear only in the §2.8.1 rows, the JSON, and three plain-language notes right after the token name (§7.30, §8.24, §9.4.3). |
| 16 | Resolved | §9.4.3 Moving is 30 / 40 / 30 with the centre toggling the chrome. §11 reads "30 / 40 / 30 (manga paged and guided view), 25 / 50 / 25 (novel)". "30 / 70" is gone. |
| 17 | Resolved | The §8.15.3 heading and the §4.8 "Reader chrome in / out (manga and novel)" row match. §8.14.3 is 240 in / 160 out, and no 180 ms chrome remains. |
| 19 | Resolved | The §7.19 vocabulary paragraph, the §8.9 slug line, keys `1`–`7` and the Filters sheet, the §8.17 select, the §7.19 badge row and the §7.5 example all match. §8.14.6 and §8.15.2 now say `Mark as done` (the body stays `reading_status: "completed"`), and §8.31 says `FINISHED` (set). `COMPLETED` is left only as a publication status. |
| 20 | Resolved | §9.1.8 unavailable shows `NOTE` in `spot` (`color.note`), and the recap slate kicker stays `ink.45`. §7.8 says "(in `spot`, as §9.1.8)". |
| 21 | Resolved | §3.2 and §3.5 `type.dropcap` = 3 × the paragraph line height, `opsz` = min(size, 96), `calc(var(--para-lh) * 3)` and `CineType.dropcap(lh)`. No `typeDropcap` remains. |
| 22 | Resolved | §8.14.13 reads "A `[0.5, 0.92]` sheet", which matches §7.9. |
| 23 | Resolved | §4.8 has seven scrolls with seven durations. §8.30.1 and §8.20 both say "400 ms `settle`". |
| 24 | Resolved | §4.1 principle 4 defers to §4.5. §8.0.4 Back and the §4.5 Match cut row say 336 ms. "0.7 ×" is gone. |
| 25 | Resolved | §8.14.11 reads "(`dur.hold.toast`, 3600 ms)". No 5200 remains. |
| 26 | Resolved | §7.7 Below, §7.10 Title, §7.11 Text and §7.15 Items label all name the role with no size. (Two siblings outside the fix's list are in the Notes.) |
| 27 | Resolved | §7.14 Cell is "Icon 24". Every leader dial in the file is 32, 24, 16 or 12 px. |
| 28 | Resolved | The §7.25 size list covers every avatar size used (20, 32, 44, 56, 96, 112, 144). 24 and 28 are spares. |
| 29 | Resolved | The §2.3 allow-list matches the fix. §8.22 `TOP` is a 40 px square. |
| 30 | Resolved | The §2.2.2 first rule says rails "do not snap to column starts". |
| 31 | Resolved | §7.1 `primary` sm is 32 on every platform with a padded hit area, and `split` is lg 56 / md 48 / sm 32. §14.6's fine-pointer clause agrees. |
| 32 | Resolved | §14.2: six fixed stocks at ≥ 13.4 / 5.8, and the Issue stock at ≥ 13 / 5.5. |
| 33 | Resolved (cap superseded by A11Y-40) | The §3.5 `type.credit.label` row, the §3.2 `type.credit` row and the §7.28 Credits primitive all use both roles. The fix gave the label `cap: 1.5`. The file has `cap: 2.0`, set deliberately by A11Y-40 and stated consistently in the §3.3 caps table ("`kicker`, `credit`, `credit.label` \| 2.00") and in §3.5. |
| 34 | Resolved | §5 has a `splash.impress` row, §15.1 has `"splash.impress": "ahap:impress"`, the §6 map sends it to "—", and §12.4 fires it by name. No bare "haptic `impress`" remains. |
| 35 | Resolved | The §7.11 edge is `spot` / `set` / `proof`. No other toast edge rule exists. |
| 36 | Resolved | The §4.8 Recap countdown reduced row and the §9.1.5 reduced clause agree. "Continuing in 12 s" is gone. |
| 37 | **Unresolved** | See below. The §8.15.5 Default column itself is correct. |
| 38 | Resolved | §8.14.7 and §8.15.4 give `SLIDE` = 280 ms `ease.settle` (`dur.pageturn`). `dur.pageturn` appears in §4.2, §2.8.4 and the JSON. |
| 39 | Resolved | §7.1 `play` is 64 / 56 / 36, matching §8.16.2 (36) and §8.16.3 (64, and 56 on phones). |
| 40 | Resolved | §8.16.5 uses alpha = 0.08 + 0.24 × RMS, with a reduced-motion alpha of 0.20 in both §8.16.5 and §4.8. |
| 41 | Resolved | The §2.1.4 Geometry cell ("The bottom 60 % of its band … reaching `#000000` at the band's bottom edge (no text sits on the band)") now matches §2.8.3. §9.1.5 uses it, and §15.7 notes that it carries no text. |
| 42 | Resolved | §8.34 reads "the "Front pages" screenshot set (§12.6)". |
| 43 | Resolved | §15.2 and §15.11 give Embla four phone pagers. §15.3 and §15.11 give `flutter_animate` rack focus, flicker and flame. |
| 44 | Resolved | §2.8.1 has a `color.note` row and the JSON has `"note": "#F4D03F"`. |
| 45 | Resolved | §2.8.3 `scrimVignette` uses `radius: 1.0` with `CssEllipse(rx: 1.2, ry: 0.9)`, and the transform is defined under the table. |
| 46 | Resolved | §9.4.4 Sampling uses the page under the reading line at 38 %. No "≥ 50 %" remains. |
| 47 | Resolved | §8.15.4 One hand is left 25 % plus a full-width 12 % top band, and §14.6 has the band-height rule. |
| 48 | Resolved | §4.6 "After a skeleton", §7.17, §4.7, §8.22 ("Data arrival dissolves the plates into posters (160 ms)") and §8.7 all agree. |
| 49 | Resolved | §8.8 item 3 gives the centred 86 % geometry, with PageView and Embla specified, and §8.9 Continue points at it. No "12 px peek" remains. |
| 50 | Resolved | §15.1 has six kinds (including **integer**) and the `"linear"` literal. The structured groups are `font`, `type`, `grid`, `bp`, `rule`, `scrim`, `focus`, `haptics`, `sounds` and `soundEvents`, citing §2.8.2, §2.8.3, §3.5, §5 and §6. Every §2.8 key group now has a kind: `hit.*` and `blur.*` are lengths, and `z.*` is an integer. |

---

## Unresolved

### CONSISTENCY-13: §6 cites a §15.8 check that §15.8 does not contain
The one-session rule is now consistent everywhere: the §6 summary sentence, the policy table, §8.16.5, §8.16.10, §9.4.2 and §14.9. The fix text ended with "the iPhone device pass (§15.8) checks that `SoLoud.instance.init()` leaves the category unchanged, and if it does not, `skin_audio.dart` re-applies the configuration right after init". That sentence is in §6, but the §15.8 device pass does not include the check. §15.8 lists the Column wipe, the Iris, the trailer scrub, Cut to home, the Lightbox, the reader at 120 Hz, the Listen highlighter, the Rack focus cap and the edition switch, and nothing about the audio session. Anyone who follows §15.8 would skip the check that §6 depends on.

**Fix:** In §15.8, after "…the Rack focus cap)", add: "; on the iPhone, the pass also logs `AVAudioSession.sharedInstance().category` right after `SoLoud.instance.init()` and after a `Hear` sample ends, and both must read `.ambient` (State A, §6); if they do not, `skin_audio.dart` re-applies State A after init (§6)".

### CONSISTENCY-37: §3.3 still gives every face an 18 px default
§8.15.5 now follows §3.4 per face (Size: 19 / 18, or 18 / 17 for Archivo; Line spacing: 1.60, or 1.70 for Atkinson). Its app clause also uses the face default: "`clamp(round(MediaQuery.textScalerOf(context).scale(d)), 14, 40)` for the face default `d`". MOBILE-8 later added a sentence to §3.3 (Layout reflow, the novel-body bullet) that repeats this rule with a fixed value: "A book with no stored size opens at `clamp(round(MediaQuery.textScalerOf(context).scale(18)), 14, 40)`, so a user at system 2.0 starts at 36 px". For an Archivo book with no stored size, §3.3 gives 18 px at 1.0 and 36 px at 2.0, while §8.15.5 gives 17 and 34. That is the defect CONSISTENCY-37 removed: one fixed default for every face. The "starts at 36 px" clause in §8.15.5 is also true only when `d` = 18.

**Fix:** In §3.3, change it to "A book with no stored size opens at `clamp(round(MediaQuery.textScalerOf(context).scale(d)), 14, 40)` for the face's default size `d` (§3.4, §8.15.5), so a user at system 2.0 starts at 36 px in Newsreader (34 px in Archivo)". In the §8.15.5 Size row, change "so a user at system 2.0 starts at 36 px" to "so a user at system 2.0 starts at 36 px (34 px in Archivo)".

---

## Notes (not blocking; no id reopened)

- §4.7 still says a letter reveal that leaves the viewport mid-reveal "never replays in the same session", but `signal` titles replay on every mount (§10.1.1). Both texts predate the fixes. Suggested wording: "… jumps to its end state; it does not replay while mounted, and `inView` and `mount` headings never replay in the same session".
- §8.2 says "Tap anywhere skips to the hold" and §12.4 says "Tap skips to the hand-off". These agree if read as "to the hold while the probe is pending, otherwise to the hand-off". One clause in §12.4 would make that explicit.
- §7.19's badge row says "16 × 16 (20 × 20 on feature pages)". §7.24 also uses the 20 px badge on the rating card at reader start and on the picker's avatar marker, which are not feature pages. The judge left §7.19 unchanged. Suggested wording: "(20 × 20 in the places §7.24 lists)".
- Same class as CONSISTENCY-26, but outside its named sections: §7.26 Keycaps "`type.folio` 12" is 13 px at wide. Suggested wording: "`type.folio`".
- §8.16.4's speed ruler opens a `[0.5]` sheet, while §7.9 names only content-fit or `[0.5, 0.92]` detents. This is a deliberate fixed half sheet, but §7.9 does not list it as an exception.
