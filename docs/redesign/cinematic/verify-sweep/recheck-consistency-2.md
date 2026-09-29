# Cinematic DESIGN.md: consistency recheck, round 2

Input: the "Confirmed" section of `cinematic/verify-sweep/judge-consistency.md` (27 findings; CONSISTENCY-13 and CONSISTENCY-22 were refuted and are out of scope), `recheck-consistency-1.md` (24 resolved, 3 unresolved) and the fixer's round-2 log in `fixed-consistency.md`. Every final fix was re-checked against the current `cinematic/DESIGN.md` (4,771 lines) by reading the edited passages and grepping for the old values and for every other place a changed value is repeated. DESIGN.md was not edited.

Mechanical checks run for this round:
- The `dur.*` key set was parsed from §2.8.4, §4.2 and the §15.1 JSON (the JSON block was loaded with a JSON parser). §2.8.4 and §15.1 hold the same 64 keys with identical values. §4.2 lists all of them; five are folded into grouped rows (`dur.hold.toast` errors / action / undo, `dur.letter` blur, `dur.hold.panel.cap`). No backticked `dur.*` name or `dur…` Dart name anywhere in the file lacks a definition. No literal written next to a key disagrees with that key's value.
- Every `N ms` / `N s` literal in §4.5, §4.8 and §7–§9 (528 occurrences) was listed and sorted into three groups: named by a key; unambiguous for a base key (80, 160, 240, 320 and 480 ms, and the like); or a behaviour timing that §4.2's closing sentence exempts. Two literals fit none of the three groups (CONSISTENCY-9 residue below).
- Sound arithmetic was re-run: the 13 cue lengths sum to 3,740 ms (reel counted at its 1,600 ms cap), and 3,740 × 96 = 359,040 B, plus 13 × 44 = 572 B of headers, gives 359,612 B, under the 384 KB budget.
- Mood-square hexes were re-derived (each channel of the §2.1.6 grade × 3). Hyperlegible line heights were re-derived (§3.5 + 4). The key-citation scan was re-run: no bare `K\d+` is left outside a prefixed list or range.

Result: **26 resolved, 1 unresolved** (CONSISTENCY-9, low). The three round-1 residues are fixed: CONSISTENCY-14 and CONSISTENCY-16 fully, and CONSISTENCY-9 for every item round 1 listed. However, CONSISTENCY-9's broadened completeness sentence (§4.2, line 815) now also covers display holds, and two literals still break it.

---

## Verdicts

| ID | Verdict | Evidence (current line numbers) |
|---|---|---|
| 1 | Resolved | §2.4 Focus light (281), §2.8.2 `focus.*` (474: `focusHalo` = `6.0`, black `BorderSide` width 6, then the ink ring on the rect inflated 2 px, both `strokeAlignOutside`), §7 intro (1070), §14.4 (4262). No `focusHaloWidth` and no "2 px further out" remain. |
| 2 | Resolved | §2.8.3 `scrim.head` / `scrim.sole` (494–495): stops read `var(--scrim-base, #000000)` with P as a literal; `--scrim-base` is unregistered and set only on the reader chrome root while page-tinted chrome is on; Flutter `{Color? tint}` with `Color.lerp(black, tint, 0.25)`. Pointers in §2.1.4 (119), §8.14.3 (2287) and §9.4.4 (3649). §15.7 over-art row at the most saturated `page.tint` (4536). |
| 3 | Resolved | §9.1.5 Skip recap, Continue and countdown bullets (3254–3256) and Entry behaviours (3265) state the same three cases. §5 `recap.countdown.end` (993) and §6 map cell (1038) are unchanged. §4.5 Column wipe row (850) and the §8.0.4 row (1727) agree. |
| 4 | Resolved | `variable: "--mm-font-newsreader"` in §3.1 (609) and §15.2 `fonts.ts` (4429); the skin block maps `--mm-font-text` (609, 709, 741); Hyperlegible overrides only `--mm-font-text` (709); the novel face (701) and the Type sheet tile (2515) use `--mm-font-newsreader` directly. The round-1 note on §15.2 `tokens.generated.css` (4427) is fixed: the skin-block mapping is now its own clause, separate from the `@property` list. |
| 5 | Resolved | §3.4 (709): deck 28 / 32 / 32 / 36 px, body and body-italic 28 / 28 / 32 / 32 px under `html[data-legible="on"][data-skin="cinematic"]`, equal to §3.5 (725–727) + 4; Flutter adds 4.0 to each `lines` entry. |
| 6 | Resolved | §8.0.3 (1679), §8.0.7 (1796), §8.7 intro (1988), States offline (2013), Backend NULL rule (2015), §15.5 (4509), Appendix B (4745). |
| 7 | Resolved | Conventions (15). A rescan finds no unprefixed key citation except continuations of a prefixed list or range (2364, 2365, 2387, 2957, 2986, 2993, 3000). |
| 8 | Resolved | §8.14.8 Auto-scroll speed (2379); level 1 → 0.50×, 5 → 1.80×, 10 → 3.00× re-computed. |
| 9 | **Unresolved** | The 19 keys from the judge and the 14 round-2 keys are in §4.2 (782–813), §2.8.4 (537–569) and §15.1 (4352–4380) with identical values. **Flame** and **Dolly** are §4.5 rows (869–870). Every round-1 residue now names its key: §8.2 (1875), §8.14.6 (2323), §8.14.7 (2338), §7.18 (1477), §7.3 (1166), §7.30 (1638), §8.14.5 (2308), §4.8 (939), §8.30.1 (2961). Two literals still break the new closing sentence: see "Residue". |
| 10 | Resolved | §4.8 Listen countdown dial row (925); the last row reads "leader dial (§7.18; not the countdown dial)" (944); §7.18 Countdown dial (1478) points to §4.8. |
| 11 | Resolved | §7.11 Motion (1334): in 240 ms `dur.line` `ease.settle`, out 160 ms `dur.beat` `ease.lift`. §7.24 rating card (1575): in 480 ms, out 240 ms. §4.2 use columns (760, 761, 763) and §4.8 toast row (934) agree. No 400 ms or 600 ms rating-card value remains. |
| 12 | Resolved | §10.1.5 `as: Tag = "h2"` (3768); conventions (17); §14.5 (4272). |
| 14 | Resolved | §6 budget sentence (1011): 13 files, one per cue, `toggle.on` and `toggle.off` included. The cue table has 13 rows with `toggle.on` 2.6 kHz / 40 ms and `toggle.off` 1.9 kHz / 40 ms (1024–1025). The event map sends `toggle.on` → `toggle.on`, `toggle.off` → `toggle.off` and `reader.unlock` → `toggle.on` (1035, 1046). §15.1 `sounds` lists 13 files, including `press/toggle-on.wav` and `press/toggle-off.wav` (4412–4415). No single `toggle` cue and no `toggle.wav` remain. |
| 15 | Resolved | §9.4.2 (3598–3624): the case-insensitive first-match rule, the eight-row genre table with the §2.1.6 fallback (186–193), and the eight descriptions. |
| 16 | Resolved | §2.8 Lint scope (342): the modifier is allowed on §2.8 colour names, runtime colours included, and on `(--mm-*)` references. The examples are `bg-stock-page/90` and `border-stock-muted/30`. §2.8.1 runtime colours (430) define `--stock-page`, `--stock-ink` and `--stock-muted` on the novel reader root (from `color.stock.<stock>.*` or the Issue derivation), map them through `@theme inline`, leave them unregistered, and give the Flutter source. The examples match the real uses: stock page at 90 % (2496) and the muted rule at 30 % (2493). No `(--stock-…)` arbitrary reference remains. |
| 17 | Resolved | §8.14.3 (2264) and §9.4.2 Indicator (3628); the phone trailing buttons are still capped at four (2265, end of the Trailing bullet). |
| 18 | Resolved | §8.15.6 (2542) `[0.5, 0.92]`. The only remaining "85 %" hits are the lock-mode tap area (2285) and the guided matte (3638). |
| 19 | Resolved | §7.1 `split` (1098) equals `primary` (1097). |
| 20 | Resolved | §2.6 (319), §7.15 Head (1397), §12.3 (4171), §12.6 (4201). No "1 px Oxford rule" remains. |
| 21 | Resolved | §10.2.2 (4010–4012). |
| 23 | Resolved | §9.2.7 (3459) and §15.5 (4498) use `(profile_id, mature_content_enabled, year, tz_offset_minutes)`; `/home` keeps `content_kind`. |
| 24 | Resolved | §8.6 (1967): the six hexes re-derive exactly. §8.18 (2735) now ends at "(§8.0.8)", because the round-1 leftover ", as a soft field" is gone. §8.22 (2831): FNV-1a mod 360, S 0.35, L 0.06. |
| 25 | Resolved | §2.8.3 `scrim.foot` (492): `scrimFoot(double solidAtPx, double height)`, `Alignment(0, 2 * solidAtPx / height - 1)`. |
| 26 | Resolved | §8.33.1 (3128) `type.field`; no "Bodoni Italic 28". |
| 27 | Resolved | §9.2.5 Card anatomy (3441): Story 360 / 48 px, Post 252 / 32 px. |
| 28 | Resolved | §8.14.8 (2347) and §8.14.12 (2461–2462); the desktop frame row gives 3 columns, min 320 px. |
| 29 | Resolved | §8.0.3 root navigator (1712), §9.2.2 Actions (3398), Appendix B (4752). |

---

## Residue

### CONSISTENCY-9: two literals the closing sentence does not cover

§4.2's closing sentence (line 815) now reads "Every motion duration and every display hold in §4.5, §4.8 and §7–§9 is one of these keys and is written with it". It then lists the behaviour timings that stay literal. Two literals are neither keyed nor listed:

| Where | Literal | Why it breaks the rule |
|---|---|---|
| §8.1 Setup, States (line 1867) | "success (check in `set`, 400 ms hold)" | A display hold with no key. The 400 ms keys are `dur.dwell.backdrop` and `dur.glide`, both unrelated. It also disagrees with §7.3's Success row (1166), which shows an input's success `check` for 1600 ms (`dur.hold.success`). The server-URL field is §7.3's own example of an async-validated input (1164), so the two passages give the same check two hold times. |
| §8.30.3 edition preview, *App* (line 3014) | "a bundled PNG loop per skin: 36 frames at 6 fps (6 s)" | A 6 s motion loop with no key. The §4.2 key for this loop, `dur.loop.preview` (813: "One loop of the edition preview card's self-scroll"), is 12000 ms and is also emitted as the Flutter field `durLoopPreview`, yet the app's preview loops every 6 s. The key reads as cross-client, but only the web uses it. |

**Fix.**
- §8.1: add `dur.hold.connected` 400 ms ("Setup's success check before the underline becomes the login Oxford rule, §8.1") as a row in §4.2, §2.8.4 and §15.1 (`"hold": { … "connected": { "value": 400, "unit": "ms" } }`). Write the state as "success (the §7.3 `check` in `set`, held 400 ms, `dur.hold.connected`, then the signature move; the screen leaves before §7.3's `dur.hold.success` runs out)".
- §8.30.3, either option:
  - (a) Capture 72 frames at 6 fps, so the app loop is 12 s and reads `durLoopPreview`. This roughly doubles the stated 1.1 MB per skin, so update that figure.
  - (b) Keep 36 frames and mark the key web-only: in §4.2 and §2.8.4 write "the web edition preview's self-scroll", and add "the app preview's frame rate (6 fps), fixed by its bundled frames" to the §4.2 literal list.

  (b) is the smaller edit.

---

## Notes (no action needed for this finding set)

- §8.7 States (2013) says the next online pick "resumes at the saved step, or at step 2 if none was saved", while Backend (2015) says `NULL` means "the first shown step (1, or 2 while `glass_available` is false)". When Glass is available and a fully offline profile saved nothing, the two rules name different steps (2 versus 1). The judge prescribed both sentences, and the offline rule reads as the more specific one: the Edition step was already shown offline. One clause in §8.7 States, "(this overrides the `NULL` rule, because the Edition step was already shown)", would settle it.
- Carried from round 1, still optional. `dur.tapscroll` (300 ms) also times the splash's reduced-motion masthead fade-in (§4.2 line 788, §8.2 line 1881), so the name reads as scroll-only. The milestone title card is a Dip-in / Dip-out takeover, but §8.0.2's Takeover row (1655) and §8.0.4's "Takeovers (Annual, recap, onboarding)" row (1732) do not name it. Both rows read as example lists.
