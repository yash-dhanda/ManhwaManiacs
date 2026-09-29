# Cinematic DESIGN.md: consistency recheck, round 3

Input: the "Confirmed" section of `cinematic/verify-sweep/judge-consistency.md` (27 findings; CONSISTENCY-13 and CONSISTENCY-22 were refuted and are out of scope), `recheck-consistency-2.md` (26 resolved, CONSISTENCY-9 unresolved) and the fixer's round-3 log in `fixed-consistency.md`. All 27 final fixes were checked again against the current `cinematic/DESIGN.md` (4,773 lines), not only the ones round 3 edited, because the file carries uncommitted edits from every round. For each fix I read the edited passages, then grepped for the old values and for every other place a changed value is repeated. DESIGN.md was not edited.

Mechanical checks run for this round:
- **Duration keys.** The `dur.*` key set was parsed from §2.8.4, §4.2 and the §15.1 JSON (loaded with a JSON parser; it still parses). §2.8.4 and §15.1 hold the same **65 keys** with identical values. Every §2.8.4 row's CSS name, Motion seconds and Flutter `Duration` agree with the key and its ms value. §4.2 lists all 65. Nine are folded into grouped rows: the `dur.hold.toast` variants, `dur.letter` blur, the `dur.hold.panel.*` trio and the `dur.hold.annual.*` pair. No `dur.*`, `durXxx` or `--mm-dur-*` name used anywhere in the file lacks a definition. No literal written next to a key disagrees with that key's value; the only automated hits were ordered lists, such as §4.8's "560 / 320 / 400 … ms (`dur.iris.out`, `dur.column`, …)", and they match.
- **Duration literals.** Every `N ms` / `N s` literal in §4.5, §4.8 and §7–§9 (513 occurrences) was listed. 201 name a key within the same clause. 180 carry a value that only one key has (for example 160, 240, 320 and 480 ms). The other 132 were read one by one. Each is one of these: a behaviour timing that §4.2's closing sentence exempts (debounces, waits before something appears, idle waits, timeouts, polls, gesture windows, audio ramps, user-set values, and now the app preview's 6 fps); a stagger; Column-wipe arithmetic (376 / 312 / 248 ms and so on); a seek amount (±15 s); an asset length (the 90 s soundscape loops); or a base-key value whose context names its role (a Dissolve at 800 ms, a toast with Undo at 8 s, the recap's 12 s). None is a motion duration or display hold without a key.
- **Sound set.** The 13 cue lengths still sum to 3,740 ms. §15.1 `sounds` has 13 entries, `toggle.on` and `toggle.off` included.
- **Colour values.** The six mood-square hexes were re-derived from §2.1.6 (each channel × 3), and they match.
- **Line heights.** Hyperlegible line heights were re-derived: §3.2 / §3.5 plus 4 px gives deck 28 / 32 / 32 / 36 and body 28 / 28 / 32 / 32.
- **Arithmetic.** Auto-scroll migration: level 1 → 0.50×, 5 → 1.80×, 10 → 3.00×. Share-card Post: 252 / 32 px.
- **Key citations.** No bare `K\d+` citation remains, apart from the conventions line and continuations of a prefixed list or range (lines 2366, 2367, 2389, 3002).

Result: **26 resolved, 1 unresolved** (CONSISTENCY-15, low). The round-2 residue on CONSISTENCY-9 is fixed, and the two follow-ups from the round-2 Notes (§8.7's NULL override and the milestone card in the takeover rows) are in place. However, the full re-read found that CONSISTENCY-15's matching rule contradicts an older sentence in the same bullet list, which round 2 missed.

---

## Verdicts

| ID | Verdict | Evidence (current line numbers) |
|---|---|---|
| 1 | Resolved | §2.4 Focus light (281), §2.8.2 `focus.*` (474: `focusHalo` = `6.0`, a black `BorderSide` of width 6, then the ink ring on the rect inflated 2 px, both `strokeAlignOutside`), §7 intro (1072), §14.4 (4264). No `focusHaloWidth` and no "2 px further out" remain. |
| 2 | Resolved | §2.8.3 `scrim.head` / `scrim.sole` (494–495): the stops read `var(--scrim-base, #000000)` with P written as a literal; `--scrim-base` is unregistered and set only on the reader chrome root while page-tinted chrome is on; Flutter takes `{Color? tint}` and uses `Color.lerp(black, tint, 0.25)`. Pointers in §2.1.4 (119), §8.14.3 (2289) and §9.4.4 (3651); §15.7's over-art row at the most saturated `page.tint` (4538). |
| 3 | Resolved | §9.1.5 Skip recap, Continue and countdown bullets (3256–3258) and Entry behaviours (3267) give the same three cases. §5 `recap.countdown.end` (995) and the §6 map cell (1040) are unchanged. The §4.5 Column wipe row (852) and §8.0.4's "a recap opened from them" row (1729) agree. |
| 4 | Resolved | `variable: "--mm-font-newsreader"` in §3.1 (610) and §15.2 `fonts.ts` (4431). The skin block maps `--mm-font-text` (710, 742, 4429), and Hyperlegible overrides only `--mm-font-text` (710). The novel face (702) and the Type sheet tile (2517) use `--mm-font-newsreader` directly. |
| 5 | Resolved | §3.4 (710): deck 28 / 32 / 32 / 36 px, and body and body-italic 28 / 28 / 32 / 32 px under `html[data-legible="on"][data-skin="cinematic"]`, equal to §3.2 (634–636) and §3.5 (726–728) plus 4. Flutter adds 4.0 to each `lines` entry. §15.2 (4429) names the override. |
| 6 | Resolved | §8.0.3 (1681), §8.0.7 (1798), §8.7 intro (1990), States offline (2015, now with "(this overrides the `NULL` rule under Backend, because the Edition step was already shown)"), Backend NULL rule (2017), §15.5 (4511), Appendix B (4747). See Notes for one implementability gap the override leaves open. |
| 7 | Resolved | Conventions (15). The rescan finds no unprefixed key citation (see the mechanical checks). |
| 8 | Resolved | §8.14.8 Auto-scroll speed (2381); the formula and the three sample levels re-compute. |
| 9 | Resolved | **Round-2 residue, §8.1:** `dur.hold.connected` 400 ms is a row in §2.8.4 (562), §4.2 (808) and §15.1 (4366, `"connected": { "value": 400, "unit": "ms" }`). §8.1 States (1869) reads "held 400 ms (`dur.hold.connected`) … the screen leaves before §7.3's `dur.hold.success` runs out", so it no longer contradicts §7.3's 1600 ms Success row (1168). **Round-2 residue, §8.30.3:** `dur.loop.preview` is marked web only in §2.8.4 (570) and §4.2 (815). §4.2's closing literal list (817) names "the app edition preview's frame rate (6 fps; its 6 s loop is fixed by the 36 bundled frames, §8.30.3)". The §8.30.3 *App* bullet (3016) points at both, and the web bullet (3008) still says "a 12 s loop, `dur.loop.preview`". Onboarding step 1 (1998), §15.3 (4475), reduced motion (frame 000 only, §8.30.3) and §14.1's "the scrolling edition preview" are consistent with it. The 19 judge keys, the §4.5 **Flame** and **Dolly** rows (871–872) and every earlier residue are still in place. |
| 10 | Resolved | §4.8 Listen countdown dial row (927). The last row reads "leader dial (§7.18; not the countdown dial)" (946). §7.18 Countdown dial (1480) points to §4.8. §14.1's "countdowns become labels" agrees. |
| 11 | Resolved | §7.11 Motion (1336): in 240 ms `dur.line` `ease.settle`, out 160 ms `dur.beat` `ease.lift`. §7.24 rating card (1577): in 480 ms `dur.spread`, out 240 ms `dur.line`. The §4.2 use columns (761, 762, 764) and the §4.8 toast row (936) agree. No 400 / 600 ms rating-card value remains. |
| 12 | Resolved | §10.1.5 `as: Tag = "h2"` (3770); conventions (17); §14.5 (4274). |
| 14 | Resolved | §6 budget sentence (1013): ≤ 384 KB, 13 files. The cue table has 13 rows summing to 3,740 ms (1017–1029). The event map sends `toggle.on` / `toggle.off` to their own cues and `reader.unlock` to `toggle.on`. §15.1 `sounds` has 13 entries (4416). |
| 15 | **Unresolved** | The table, the case-insensitive first-match rule and the eight descriptions are in §9.4.2 (3602–3626). However, the Picker bullet directly above (3601) still says `MATCH THE MOOD` "chooses by the series' first genre, falling back to the profile mood's default". See "Residue". |
| 16 | Resolved | §2.8 Lint scope (342) allows the modifier on §2.8 colour names, runtime colours included, and on `(--mm-*)` references. The examples are `bg-stock-page/90` and `border-stock-muted/30`. §2.8.1 runtime colours (430) define `--stock-page`, `--stock-ink` and `--stock-muted`. They also say how these differ from the Ink stock's full-name tokens (`bg-stock-ink-page` …), so `text-stock-ink` versus `text-stock-ink-ink` is spelled out, not ambiguous. |
| 17 | Resolved | §8.14.3 Title (2266) and §9.4.2 Indicator (3630). Trailing (2267) still caps phones at four buttons. The novel top bar (2496) keeps the indicator in its title area. |
| 18 | Resolved | §8.15.6 (2542) `[0.5, 0.92]`. The only remaining "85 %" hits are the lock-mode tap area (2287) and the guided matte (3640). |
| 19 | Resolved | §7.1 `split` (1098) equals `primary` (1097); `secondary` is "as primary". |
| 20 | Resolved | §2.6 (319), §7.15 Head ("with `rule.oxford` under it"), §12.3 (24 + 16 + 8 px), §12.6 (9 + 6 + 3 px). No "1 px Oxford rule" remains. |
| 21 | Resolved | §10.2.2 (4012–4014). |
| 23 | Resolved | §9.2.7 (3461) and §15.5 (4500) use `(profile_id, mature_content_enabled, year, tz_offset_minutes)`; `/home` keeps `content_kind`. |
| 24 | Resolved | §8.6: the six hexes re-derive exactly. §8.18 (2737) ends at "(§8.0.8)". §8.22 (2833): FNV-1a mod 360, S 0.35, L 0.06. |
| 25 | Resolved | §2.8.3 `scrim.foot` (492): `scrimFoot(double solidAtPx, double height)` with `Alignment(0, 2 * solidAtPx / height - 1)`. `scrim.foot.black` (493) has no solid point and ends at `Alignment.bottomCenter`, which is correct. |
| 26 | Resolved | §8.33.1 (3130) uses `type.field`, as §7.4 (1174) does; no "Bodoni Italic 28" remains. |
| 27 | Resolved | §9.2.5 Card anatomy: Story 360 / 48 px, Post 252 / 32 px. No 256 / 36 px values remain. |
| 28 | Resolved | §8.14.8 (2349) and §8.14.12 (2462, 2464): the right side panel, 3 columns, min 320 px, `paper.0`; opening it hides Margins. |
| 29 | Resolved | §8.0.3 root navigator (1714), §9.2.2 Actions (3400), Appendix B (4754). The round-2 note is also done: §8.0.1 Takeover row (1657) and §8.0.4 Takeovers row (1734) now name the milestone title card. |

---

## Residue

### CONSISTENCY-15: the Picker bullet still states the old matching rule

§9.4.2 now gives the matching rule twice, and the two statements disagree:

| Where | Text | Reading |
|---|---|---|
| Picker bullet (line 3601) | "`MATCH THE MOOD` (chooses by the series' first genre, falling back to the profile mood's default in §2.1.6)" | Look only at genre 1. If it is not in the table, use the mood default. |
| `MATCH THE MOOD` bullet (line 3602) | "take the series' genres in order and use the first one that appears in this table" | Walk the genres until one matches. |

Example: a series tagged `["Gender Bender", "Romance"]`. The Picker bullet gives the mood default, while the table rule gives Rain on glass. The judge's fix defined the second reading. The sentence in the Picker bullet is the pre-fix wording, which the judge quoted as the gap. It is a place where the changed rule is repeated, and it was not updated.

**Fix.** Line 3601: replace "(chooses by the series' first genre, falling back to the profile mood's default in §2.1.6)" with "(plays the loop of the first of the series' genres that the table below lists, falling back to the profile mood's default in §2.1.6)". No other passage states the rule: rows 2384, 2534 and 2990 only name the option.

---

## Notes (no action needed for this finding set)

- **CONSISTENCY-6, the offline override.** §8.7 States now says a profile that saved nothing offline resumes at step 2, and that this "overrides the `NULL` rule". Offline, nothing reached the server, so the server still returns `onboarding_step: NULL`. The fact that the Edition step "was already shown" can only live on the device, and the contract does not say where the client records it. An edition picked offline is also never saved, because the `PUT` could not be sent. So resuming at step 2 means that profile never gets to pick an edition. There are two consistent ways out, and neither is required by the judge's text:
  - (a) Name a per-profile local flag, for example scoped `localStorage` / SharedPreferences `mm.onboarding.editionShown`.
  - (b) The simpler one: drop the override, so the rule reads "resumes at the saved step, or at the first shown step (the `NULL` rule) if none was saved". The Edition step then shows again, and the unsaved pick is recovered with one tap.
- **Carried, still optional.** `dur.tapscroll` (300 ms) also times the splash's reduced-motion masthead fade (§4.2 line 789, §8.2 line 1883), so the name reads as scroll-only. The fixer declined the rename in round 3, for a stated reason. It is not a contradiction.
- **§8.0.4, recap into the reader.** §8.0.4's "Takeovers (Annual, recap, onboarding, milestone title card) | Dip in, Dip out" row (1734) and its "a recap opened from them → Column wipe" row (1729) both cover a recap. They read correctly only because the more specific row wins; the same was true before this sweep. One clause in the Takeovers row, "(a recap's exit into the reader follows §9.1.5 Entry behaviours)", would make that precedence explicit.
