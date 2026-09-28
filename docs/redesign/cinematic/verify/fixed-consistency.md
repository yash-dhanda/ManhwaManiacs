# Cinematic DESIGN.md: fixes applied from the internal-consistency judge

## Round 1

Source: `cinematic/verify/judge-consistency.md`, section "Confirmed" (49 findings; CONSISTENCY-18 was refuted and is not applied). Every fix was applied as the judge rewrote it. Section numbers refer to `cinematic/DESIGN.md`.

| ID | Sections changed |
|---|---|
| CONSISTENCY-1 | §7.24 Mark (16/20 px mark is the §7.19 badge, Archivo 10/12 px; 160 px dialog mark keeps the 2 px border and Bodoni 900 at 88 px); §2.7 custom glyphs (`certificate-18` is the icon-slot form only); §7.25 and §8.5 picker marker "(the §7.19 badge)" |
| CONSISTENCY-2 | §12.4 timeline rows (monogram 252–572, Letter set 252–1180 at 24 ms stagger, Rule draw 700–1180 at 480 ms, `splash.impress`, 220 ms hand-off) and duration rule (`max(probeDone, 1180 ms)`, hold after the impression); §8.2 Pre-roll; §4.2 `dur.reel` use text |
| CONSISTENCY-3 | §7.11 Surface (`paper.2`, raised stock); §2.1.1 raised-stock root list gains "toast" |
| CONSISTENCY-4 | §7.15 Width (auto-spine 768–1023, expanded from 1024) |
| CONSISTENCY-5 | §4.3 Use column for `settle`, `lift`, `turn`, `set`; §4.5 Lightbox row; §7.30 Dismiss (close by button 320 ms `ease.turn`) |
| CONSISTENCY-6 | §4.3 `ease.drift` Flutter column (`Cubic(0.37, 0, 0.63, 1)`) |
| CONSISTENCY-7 | §3.2 fluid-role line-height table (unitless ratios per breakpoint); §3.5 intro and the five fluid rows name the same ratios |
| CONSISTENCY-8 | §4.6 Letters and §10.1.1 Stagger (`n` = graphemes excluding spaces); §10.1.5 `custom` count; §10.1.6 `_step` as double and rounded controller duration |
| CONSISTENCY-9 | §10.1.5 web `SetHeading` rewritten (`replay`, `idle/run/done` phase with two `useInView` observers, static end state, 60-letter word fallback); §10.1.6 Flutter (`replay`, word fallback) and its rules paragraph; §10.1.1 Trigger row |
| CONSISTENCY-10 | §10.2.1 Caret; §10.2.3 caret-out description and keyframes (per-keyframe `linear` fade); §10.2.4 Flutter blink formula |
| CONSISTENCY-11 | §4.5 Column wipe (tablet 744 ms); §8.14.2 close/open timings, Dip saving on tablets, route-duration formula (616/744/872); §8.30.3 Outgoing sequence (tablets 80–392) |
| CONSISTENCY-12 | §2.1.5 reader-page row (Flutter `ResizeImage` 16 × 16 exact, web `imageSmoothingQuality`) and picker text (256 pixels on both clients, vectors note); §9.4.4 Source; §15.3 `page_tint.dart`; §15.6; Appendix A graft row and its "Adapted, not copied" note |
| CONSISTENCY-13 | §9.4.2 new "iOS audio session" rule and Playback reference; §6 playback rules; §8.16.10 (`speech()` while narration is active); §14.9 |
| CONSISTENCY-14 | §7.25 avatar table and §2.8.1 avatar rows (six darkened fields with Flutter values) |
| CONSISTENCY-15 | §2.8.1 seven new colour tokens (`color.onart`, `color.hairline.art`, `color.galley`, `color.leader.sweep`, `color.lightbox`, `color.matte.guided`, `color.warmth`); §15.1 JSON; raw values replaced in §7.1, §7.2, §7.7, §7.17, §7.18, §7.30, §8.14.8, §8.24, §9.2.4, §9.4.3; §10.2.3 `@theme` block registering `--animate-caret-out` with its `@keyframes`; §2.8 new "Lint scope" paragraph |
| CONSISTENCY-16 | §9.4.3 Moving (30 / 40 / 30 with a centre chrome zone); §11 Tap zones row |
| CONSISTENCY-17 | §8.15.3 heading (in 240 ms `settle`, out 160 ms `lift`, no slide); §4.8 Reader chrome row (manga and novel) |
| CONSISTENCY-19 | §7.19 new reading-status vocabulary paragraph; §8.9 slug line, keys `1`–`7` and phone Filters sheet; §8.17 status select; §7.5 example slug line |
| CONSISTENCY-20 | §9.1.8 unavailable state (`NOTE` in `spot`, reason in `ink.60`; recap slate kicker stays `ink.45`); §7.8 AI-unavailable line |
| CONSISTENCY-21 | §3.2 and §3.5 `type.dropcap` rows (3 × the paragraph's line height, `opsz` = min(size, 96); web `calc(var(--para-lh) * 3)`; Flutter `CineType.dropcap(lh)`) |
| CONSISTENCY-22 | §8.14.13 page actions sheet `[0.5, 0.92]` |
| CONSISTENCY-23 | §4.8 scroll row (seven durations); §8.30.1 settings search jump and §8.20 group jump (400 ms `settle`) |
| CONSISTENCY-24 | §4.1 principle 4; §8.0.4 Back row; §4.5 Match cut row (reversed on back 336 ms) |
| CONSISTENCY-25 | §8.14.11 stale-bookmark toast (`dur.hold.toast`, 3600 ms) |
| CONSISTENCY-26 | §7.7 Below; §7.10 Title; §7.11 Text; §7.15 Items label (role names without fixed sizes) |
| CONSISTENCY-27 | §7.14 Cell icon 24; §7.18 leader dial sizes (12 inside a switch knob) |
| CONSISTENCY-28 | §7.25 avatar size list (adds 28, 56, 112) |
| CONSISTENCY-29 | §2.3 `radius.round` allow-list (drops the scroll-to-top dot) |
| CONSISTENCY-30 | §2.2.2 first grid rule (rails do not snap to column starts) |
| CONSISTENCY-31 | §7.1 `primary` sm size on every platform with padded hit area; `split` gains sm 32 |
| CONSISTENCY-32 | §14.2 paper-stock bullet (six fixed stocks vs the Issue stock) |
| CONSISTENCY-33 | §3.5 new `type.credit.label` row; §3.2 `type.credit` row; §7.29 Credits line |
| CONSISTENCY-34 | §5 new `splash.impress` event; §15.1 `haptics`; §6 event map; §12.4 impression row |
| CONSISTENCY-35 | §7.11 edge colours (`set` for success and completion) |
| CONSISTENCY-36 | §4.8 Recap countdown reduced row |
| CONSISTENCY-37 | §8.15.5 Size and Line spacing defaults follow §3.4 per face |
| CONSISTENCY-38 | §8.14.7 and §8.15.4 `SLIDE` = 280 ms `ease.settle`; new `dur.pageturn` in §4.2, §2.8.4 and §15.1 |
| CONSISTENCY-39 | §7.1 `play` sizes (64 / 56 / 36) |
| CONSISTENCY-40 | §8.16.5 voice pulse (`color.spot` at alpha 0.08 + 0.24 × RMS; reduced 0.20); §4.8 Voice pulse row |
| CONSISTENCY-41 | §2.1.4 and §2.8.3 new `scrim.foot.black`; §9.1.5 recap band |
| CONSISTENCY-42 | §8.34 "Front pages" screenshot set |
| CONSISTENCY-43 | §15.2 and §15.11 Embla scope (four phone pagers); §15.3 `flutter_animate` scope (no reveals) |
| CONSISTENCY-44 | §2.8.1 `color.note` row; §15.1 JSON `note` |
| CONSISTENCY-45 | §2.8.3 `scrimVignette` (radius 1.0 with `CssEllipse` transform) and the `CssEllipse` definition under the table |
| CONSISTENCY-46 | §9.4.4 Sampling (page under the reading line, 38 %) |
| CONSISTENCY-47 | §8.15.4 One-hand preset (left 25 %, full-width 12 % top band); §14.6 band-height rule |
| CONSISTENCY-48 | §4.6 new "After a skeleton" rule; §8.22 opening state; §8.7 step 5 loading |
| CONSISTENCY-49 | §8.8 phone item 3 pager geometry (centred 86 %, 6 px padding, about 21 px of neighbour); §8.9 Library Continue pager |
| CONSISTENCY-50 | §15.1 token kinds (six kinds with **integer**; curve accepts `"linear"`; structured groups sentence) |

The Coverage appendix (Appendix B) is unchanged: no screen was added, removed or renamed.

### Round 1 re-run check (2026-09-28)

A second pass of this round re-checked every Confirmed finding against the live `cinematic/DESIGN.md` by grepping for the new wording and for each old value. All 49 fixes are in place and no old value from the findings remains (old avatar hexes, 64 px sampler, 5200 ms hold, `max(probe, 900 ms)`, 30 / 70 zones, 180 ms novel chrome, 300 ms `set` SLIDE, 0.08–0.32 pulse, the scroll-to-top dot, fixed drop-cap sizes, "five kinds"). No edits were needed in this pass.

One interaction with another lens: CONSISTENCY-4 set the auto-spine to 768–1023, and WEB-2 (`verify/judge-web.md`) has since set it to 768–1279 in every place that states it (§1 Breakpoints, §7.15 Width, §8.0.1 Desktop frame, §8.0.9 intro), with 768–1023 kept only as the 8-column grid range. The goal of CONSISTENCY-4 (one spine range everywhere) holds, so it was not reverted.

## Round 2

Source: the six findings `verify/recheck-consistency-1.md` left unresolved, fixed as that recheck rewrote them. Each spot was located by grep and edited in place while the other lenses were writing to the file. The other 43 Confirmed findings were re-swept for their old values (old avatar hexes, 64 px sampler, `max(probe, 900`, 30 / 70 zones, 5200 ms, 0.08–0.32 pulse, the scroll-to-top dot, "five kinds", `Mark as completed`, and so on). None had come back, so no other edits were needed.

| ID | Sections changed |
|---|---|
| CONSISTENCY-13 | §6 Playback rules: `.ambient` + `mixWithOthers` "whenever neither narration nor a voice sample is active (State A)"; "UI cues never duck the user's music". §14.9: "(`.ambient` outside narration and voice samples, §6)" |
| CONSISTENCY-14 | §7.25 intro: "(≥ 3:1 is required for a non-text glyph; every field reaches 4.5:1, 4.53:1 minimum on Usher; …)". The twelve fields were recomputed against `ink.100`: the minimum is Usher at 4.53 and the maximum is Phantom at 6.82. §2.1.1 surface × ink loop: "`ink.100` on the twelve avatar fields (≥ 4.5:1, §7.25)" |
| CONSISTENCY-15 | §7.7 "Select mode, unselected": the outline sits on `color.onart` (was raw `rgba(0,0,0,0.64)`). The raw value now appears only in the §2.8.1 token row and the §15.1 JSON |
| CONSISTENCY-19 | §8.14.6 The end and §8.15.2 End matter: `Mark as done` (the request body is unchanged: `reading_status: "completed"`). §8.31 Recent checks: the job badge is now `FINISHED` (set). `COMPLETED` is left only as a publication status (§7.19) |
| CONSISTENCY-41 | §2.1.4 `scrim.foot.black` Geometry: "The bottom 60 % of its band, top → bottom, reaching `#000000` at the band's bottom edge (no text sits on the band)", which matches §2.8.3. Follow-through in §15.7 Over art: the over-art rows cover every `scrim.foot` text block, and a note says `scrim.foot.black` carries no text |
| CONSISTENCY-50 | §15.1 structured-groups sentence: adds `scrim` and `focus`, and cites §2.8.3 |

The Coverage appendix (Appendix B) is unchanged: no screen was added, removed or renamed.

## Round 3

Source: the two findings `verify/recheck-consistency-2.md` left unresolved, fixed as that recheck wrote them. Each spot was located by grep and edited in place while other lenses were writing to the file. The other 47 Confirmed findings were re-swept for their old values (old avatar hexes, `64 × h`, the 64 px sampler, `max(probe, 900`, 30 / 70 zones, 5200 ms, 0.08–0.32 pulse, the scroll-to-top dot, "five kinds", `Mark as completed`, "fades 180 ms", 300 ms `set` SLIDE, "stays speech", fixed drop-cap `sizes`). None had come back, so no other edits were needed.

| ID | Sections changed |
|---|---|
| CONSISTENCY-13 | §15.8 Verification: the device pass now includes the audio-session check that §6 cites. On the iPhone it logs `AVAudioSession.sharedInstance().category` right after `SoLoud.instance.init()` and after a `Hear` sample ends; both must read `.ambient` (State A, §6), and if they do not, `skin_audio.dart` re-applies State A after init. §6 is unchanged (its §15.8 reference now resolves) |
| CONSISTENCY-37 | §3.3 Layout reflow, novel-body bullet: a book with no stored size opens at `clamp(round(MediaQuery.textScalerOf(context).scale(d)), 14, 40)` for the face's default size `d` (§3.4, §8.15.5), "36 px in Newsreader (34 px in Archivo)" at system 2.0. §8.15.5 Size row: "starts at 36 px (34 px in Archivo)". §14's summary ("the system-scaled default, clamped to 14–40") already names no fixed size and is unchanged |

The Coverage appendix (Appendix B) is unchanged: no screen was added, removed or renamed.

## Round 4 (main session)

- CONSISTENCY-32: §2.1.1 raised-scope paragraph now states the per-stock floors (≥ 5.84:1 on the six fixed stocks, ≥ 5.5:1 on the Issue stock, §2.1.6) instead of one blanket 5.84:1 claim.
