# Cinematic DESIGN.md: recheck round 2, accessibility, privacy and safety lens

Rechecked 2026-09-28 against `cinematic/verify/judge-a11y.md`, section "Confirmed" (34 findings), on the live `cinematic/DESIGN.md` (4,657 lines, last written 23:09). The 8 refuted findings (A11Y-12, 24, 25, 26, 27, 34, 36, 42) are not rechecked. `recheck-a11y-1.md` and the round 2 part of `fixed-a11y.md` were used only to locate the edits. Every finding was rechecked, not only the three that round 1 left open, because other lenses kept editing the file after round 1.

Method, for each finding:

1. Read the section the final fix names and compare it with the fix text, value by value.
2. Grep for the old value and for every other place the changed value is repeated.
3. Recompute the figures the fix states with the WCAG 2.x relative-luminance formula, alpha composited in sRGB (script in the session scratchpad; results below).

**Result: 31 resolved, 3 unresolved (A11Y-1, A11Y-3, A11Y-33).** All three round 1 items that the round 2 fixes targeted are now correct where they were edited (A11Y-18, A11Y-10 and the §2.1.4 / §14.2 half of A11Y-3). The three open items are small wording conflicts, and each can be fixed with one sentence or one clause:

- **A11Y-3.** The fix left one stale clause in §2.1.1.
- **A11Y-1.** A contradiction that round 1 missed: the "Previously on" `Skip recap →` button sits on the art band that §2.1.4 says carries no text.
- **A11Y-33.** A contradiction the fix introduced: "any keydown pauses" makes the documented `Space` resume impossible.

## Unresolved

### A11Y-3: §2.1.1 still says `ink.45` is never used over art

The round 2 fix is correct where it was applied:

- **§2.1.4.** The over-art rule now says "`ink.30` is never used over art, and `ink.45` only on a solid ground (below)". The solid-ground paragraph names a badge's `#000000` fill: "On a solid ground (alpha 1: a badge's fill, the rating card's `paper.0` box) the ± 8 px margin is the box's own padding, and `ink.45` is allowed there (4.70:1 on `#000000`, as on the `TEXT` poster badge)".
- **§14.2.** The "Over art" bullet says the same.
- **§7.19.** Unchanged and consistent: `#000000` fill inside every outlined badge that can sit on art. The quoted figures reproduce: ink.100 18.44, spot 13.94, set 11.41, ink.60 7.20, proof 6.85, ink.45 4.70.

**Contradiction.** §2.1.1, in the "`ink.45` lives on black only" paragraph, still carries the wording from before the fix: "Over art the §2.1.4 over-art rule applies instead, and **`ink.45` is never used there**." That forbids exactly what §2.1.4 and §14.2 now allow, and what §7.19 prescribes for the `TEXT` badge (`ink.45` text on its black fill over a cover). A reader starting at §2.1.1 gets the old rule.

**Fix.** In §2.1.1 replace "and `ink.45` is never used there" with "and `ink.45` is used there only on a solid ground (a badge's `#000000` fill, the rating card's `paper.0` box)".

### A11Y-1: `Skip recap →` sits on the recap's art band, which §2.1.4 says carries no text

Everything the judge's fix lists is in place and consistent (details in the Resolved table). The recap band is where it breaks:

- The judge's fix item 4 put "the recap band" under `scrim.foot`, so that its text would sit on a solid ground.
- The file solves the band differently. In §2.1.4 `scrim.foot.black` covers "the bottom 60 % of its band … (no text sits on the band)", for "the 'Previously on' cover band (§9.1.5)". §15.7 repeats "`scrim.foot.black` carries no text". That approach is valid only if the statement is true.

**Contradiction.** §9.1.5 Layout places **Skip recap** "a `quiet` button `Skip recap →` at the top-right of the takeover (desktop: aligned to column 12 under the running-head height; phones: top-right under the safe area …)". The band is "a duotone band across the top 28 % (phone 34 %)" of the takeover, so the button sits inside the band's top part:

- `scrim.foot.black` only covers the band's lower 60 %, so the button has no ground under it.
- If a running-head scrim is present, the button still falls below the bar, on the `scrim.head` fade.
- A `quiet` button is `ink.60` text (§7.1), which needs black ≥ 0.82 under the over-art rule. Over a white area of the cover with no ground, `ink.60` measures about 2.9:1.

**Same pass (same rule, no ground specified).** On The Annual's phone frame (§9.2.4), art "bleeds to every edge" and the close `x` "sits 8 px under the segments at the right margin". No scrim covers the top edge: `scrim.foot` is at the bottom, and `scrim.vignette` is still near 0 alpha at that corner. An `ink.100` glyph there measures 1.14:1 on white art, against the 3:1 icon threshold.

**Fix.**

- Make `Skip recap →` an `on-art` button (§7.1: fill `color.onart` 0.64, text `ink.100`, 5.89:1 over `#FFFFFF`, 6.51:1 over `#F5F547`), or move it below the band.
- Make the Annual phone close `x` the `on-art` icon button (§7.2).
- Add both as rows of the over-art table in §2.1.4 and §15.7.

### A11Y-33: "pauses on any `keydown`" contradicts `Space` resuming the countdown

The judge's fix is applied as written:

- **§9.1.5.** The web pause triggers are "any `keydown`, … `pointerdown`, … a text selection inside the recap and … `focusin` anywhere in the takeover". The polite announcement ends "Press Space to pause". The setting "Continue automatically after a recap" is `ON · OFF`, default `ON`, per profile.
- **§8.30.2.** Rows 03 and 04 list that setting.

**Contradiction introduced by the fix.** The §9.1.5 Keys line says "`Space` … once the recap is complete, **pauses or resumes** the countdown". Read literally, every `keydown`, including `Space`, pauses the countdown, so the keyboard can never resume it.

The result depends on handler order:

- A single `Space` press while the countdown runs could pause it through the generic rule and then resume it through the toggle. The announced "Press Space to pause" would then do nothing visible.
- A `Space` press while paused can never resume it.

**Fix.** In §9.1.5 write "on any `keydown` other than `Space`, `Enter` and `Esc` (which keep their own actions: `Space` pauses or resumes, `Enter` continues, `Esc` closes)".

## Resolved

| ID | Where it now lives | Checks |
|---|---|---|
| A11Y-1 (everything except the recap band above) | §2.1.4 scrims, over-art rule and table, solid grounds, test table; §2.8.3; §8.14.3; §7.24; §8.14.6; §9.2.4; §14.2; §15.7 | `scrim.head` is `#000` 0.88 flat over the bar's laid-out height (phone min safe area + 44, 48 on Android, growing with the bar; desktop 56), then the 13 stops reversed over 44 / 64 px, in §2.1.4 and §2.8.3 (web `::before` utility; Flutter `Color(0xE0000000)`). `scrim.sole` is 0.90 flat over the folio bar, then eased over 64 px (Flutter `0xE6`). Minimum-alpha table 0.60 / 0.68 / 0.66 / 0.70 / 0.82 / 0.84. Recomputed over `#FFFFFF`: 5.04 / 4.61 / 4.82 / 4.63 / 4.66 / 4.76. Over `#F5F547`: 5.62 / 5.04 / 5.30 / 5.04 / 4.88 / 4.94. All are ≥ 4.5. At 0.88 over white: ink.60 5.68, spot 10.99, ink.100 14.54, within 0.07 of the stated 5.65 / 10.94 / 14.47. `scrim.foot` reaches solid 24 px above the text block (§2.1.4, §2.8.3 `--scrim-solid-at` / `scrimFoot(solidAt)`). `6 MIN LEFT` is `ink.60`. The running title is `type.nav` `ink.60` on 0.88. The rating card sits in a `paper.0` box with 8 × 12 padding (§7.24). Coming up is on `#000000` at 0.84 (§8.14.6); its `ink.45` roles render `ink.60` under the structural raised scope, which needs 0.82. The Annual story buttons are now `on-art` (`ink.100` on 0.64, 5.89:1). The page-tint mix is kept (§9.4.4); `page.tint` is L 0.06, so 25 % of it barely lifts the end colour. No 0.42, 0.52–0.64 or 0.68 scrim alpha is left. |
| A11Y-2 | §8.16.3 | Duotone at 15 % with the vignette and 0.05 grain. Inactive sentences `ink.60` at full opacity (5.34 / 7.20). Active sentence 9.21. Speaker kickers ≥ 6.80 / ≥ 9.17. Head kicker `NOW READING ALOUD` in `ink.60`. The full player is a §15.7 over-art row. No "35 %" opacity or "50 %" duotone remains in Listen (the only "35 %" left are the skeleton bar width and the mini player's buffered rule). |
| A11Y-4 | §8.21, §7.7 Disabled | `UNAVAILABLE ON THIS PROFILE` and "pinned source missing" appear nowhere. §8.21 has "Pins that no longer resolve … are omitted by the server from `GET /sources/pins` and come back when the source does; the client never shows or filters them." |
| A11Y-5 | §7.4, "`index` accessibility", §10.2.2 | Placeholder `ink.45` (4.70), and `ink.60` (6.42) inside the palette's `paper.2`. Four accessible names as in the judge's list. `aria-hidden` visual layer, not a `TypedHeadline`. Real `placeholder` / `hintText`, static while focused and empty. Masthead kicker as context. |
| A11Y-6 | §7.7 Ranked and Error, §8.7, §8.24, §8.32, §8.23 | Rank numerals `ink.45` with "Number 3, Solo Leveling". Skipped genre `ink.45` + `proof` strike + "Romance, skipped". 404 numeral decorative (`aria-hidden`, `ExcludeSemantics`). `image-broken` `ink.45` labelled "Cover didn't load" / "Page didn't load". The round 2 regression fix holds: §8.23 `REMOVING…` is `ink.45` "(a state, so never `ink.30`)". Every remaining `ink.30` is disabled text, a rule, an outline, a separator, a tick or the 404 numeral (the storage meter segment is noted under Observations). |
| A11Y-7 | §2.1.1, §14.2 | Structural raised-scope rule with the explicit reader Ink/Slate canvas, select-mode bar, own and tinted rows, `proof.wash` and error rows. `spot.wash` renders `ink.80`: recomputed 9.38 on the wash over `#000` and 6.97 over `paper.3` (stated 9.41 / 6.98). Stock panels use `muted` (≥ 5.84). The loop is extended with `ground.ink`, `ground.slate`, both washes over `paper.0`–`paper.3` and the six stocks. |
| A11Y-8 | §10.2.1, §10.2.3, §10.2.4, §8.20, §8.24, §14.4, §14.5 | `as?: 'h1' \| 'h2' \| 'h3' \| 'p' \| 'span'`, default `"p"`, `sr-only` full text. The h1 list matches the judge's. Other notices are `h2`, including System status. Discover and Dialogue have a visually hidden h1 route target on the web and a Flutter `Semantics(header: true, headingLevel: 1)`. No hard-coded `<h1>` is left. |
| A11Y-9 | §10.1.6, §10.1.1, §10.2.4, §14.5 | `head()` wraps the seen, reduced and animating branches in `Semantics(header: true, headingLevel: widget.level, …)`. `TypedHeadline` uses `header: level != null`. The pinned SDK has `required int? headingLevel` in `widgets/basic.dart:4046` and asserts `headingLevel == null \|\| (… > 0 && … <= 6)` in `semantics.dart:1737`. The fourth test uses `containsSemantics(isHeader: true, label: 'Library')`. |
| A11Y-10 | §10.1.1 Text scale and Long words rows, §10.1.5, §10.1.6 | **Web:** `useWordsFit` now reads `const el = ref.current; if (!el) return;` inside `check()` and observes the parent captured at mount. That parent is the caller's element, which survives the `<M>` → `<Tag>` swap at `"done"`, so the `ResizeObserver` re-check keeps measuring the live node. **Flutter:** the clamped `textScaler` is on the whole `Text`, every letter and the `' '` spacer. The rise is `0.42 × scaler.scale(fontSize)`. The `LayoutBuilder` + `TextPainter` fallback uses `_c.drive(CurveTween(…))`, which adds no listener to `_c` until the `FadeTransition` subscribes and removes it on dispose. **Tests:** the fifth asserts no overflow only (matching the §10.1.1 row). The sixth (160 px column) asserts the plain fallback rendered. |
| A11Y-11 | §7 intro Heights, §7.19, §7.11, §3.3, §14.7, §15.7 | Every §7 height is a minimum (web `min-height`, Flutter `ConstrainedBox`), with the judge's list. Badge min 16 with `padding-block: 2px`. Toast text "never truncated", 560 max width. No "2 lines max" or "height 16" is left. |
| A11Y-13 | §3.1, §3.4, §14.4, §14.7, §15.7 | `highContrastOf` → `CineTokens.copyWith(colorInk45: colorInk80, colorRule1: colorRule2)`. Bold Text with the judge's per-face maxima (900 / 900 / 800 / 800 / 900 / 900) and Plex Mono 600. **Deviation kept from round 1:** the step is +120, not +150, because it reuses the novel reader's Bold text step. §3.1, §3.4 and §14.7 all say 120, and the defect (no designed weight under OS Bold Text) is fixed. Accepted. |
| A11Y-14 | §7 intro Semantics table, §14.5 | Every row of the judge's contract, with Flutter values filled in. |
| A11Y-15 | §7.5 Count, §7.29 Spoken folios, §14.5 | Raised ordinary digits (`0.72em` / `0.5em`; Flutter `Offset(0, -0.35 * fontSize)`). No Unicode superscripts in the UI. `folioLabel()` at both paths, with the seven conversions and a table test per client. The round 2 extension holds: the rule covers every superscript count (`CHAPTERS²⁰¹`, `Filters ⁽²⁾`, `FEMALE ¹⁸`, `PINNED⁶`, `Show queue ⁽⁸⁾`). |
| A11Y-16 | §14.5, §14.4, §8.14.3 | "Timers wait while focus is inside" on both clients for every user, covering §8.14.3 including cinema mode, §8.15.3, §7.30 and §8.16.2. No idle or scroll hide with focus inside. A user-commanded hide moves focus to the reader canvas. |
| A11Y-17 | §7.8 Slate focus row | Non-modal `role="dialog"` + `aria-labelledby`; focus to `Read`; Tab cycle; `Esc`/`Space` return focus; `aria-expanded` / `aria-controls`; pointer-dwell slates never take focus; Flutter `FocusScope` in the `OverlayEntry`. |
| A11Y-18 | §8.8 "Focus during the scrub", §8.8 implementation paragraph, §14.4 | The Flutter sentence now reads "The strip's controls enter the tab order at `p` ≥ 0.8 and the text column goes inert at `p` ≥ 0.55 (`ExcludeFocus` + `ExcludeSemantics`), as in "Focus during the scrub" above." No "`p` = 1" tab-order sentence is left (the only `p` = 1 is the strip pinning). The strip fades in over `p` 0.6 → 1, so its opacity is 0.5 at `p` = 0.8, which matches "where their opacity is ≥ 0.5". |
| A11Y-19 | §7.3, §8.3 | Show/Hide stays in the tab order after its field, with `aria-pressed` "Show password", `aria-controls` and Flutter `Semantics(button: true, toggled:)`. §8.3's tab order agrees. "excluded from the tab order" appears nowhere. |
| A11Y-20 | §7.22, §7.16, §11, §8.21 | Four Move items, disabled at the ends, 240 ms `set`, `sort_order`, the announcement and the `ReorderableListView` note. The §11 drag row lists them plus `Alt+↑/↓`. The round 2 consistency fix holds: the §7.16 list includes collection members and points to §7.22. |
| A11Y-21 | §9.2.1, §2.1.6 | `ink.100` squares of 3 / 5 / 7 / 10 px, the zero-day `rule.2` outline, today's `spot` outline and the `0 · 1–2 · 3–5 · 6–10 · 11+` legend. No `heat.` token is left anywhere. |
| A11Y-22 | §2.4, §2.8.2 `focus.halo`, §7 intro, §7.7 Focused, §14.4, §14.2 | Double ring with `box-shadow: 0 0 0 6px #000`, combined with the poster's inset hairline. Flutter `CineFocusRing` + `focusHaloWidth`. The 8 px focus padding holds the halo. |
| A11Y-23 | §7 intro, §14.6, §2.7, §2.8.2 `hit.*`, §7.5, §7.13, §3.3 | Coarse 44 pt / 48 dp; fine ≥ 32 px with 24 px spacing (`--mm-hit-min` set to 32 px under `pointer: fine`). A scripted scan finds no hit, target or tap mention of 44 without its 48 (the §9.3.3 reaction stamps are a 44 visual box, and the global rule pads them to 48 on Android). The phone running head is min 44 / 48 Android in §7.13, §3.3, §8.14.3, §2.1.4 and §2.8.3. The web `headBottom` "44 px plus `env(safe-area-inset-top)`" is mobile web, which is 44 by rule. |
| A11Y-28 | §8.5 | The credit line shows only "NEW" and is otherwise empty. `LAST READ` appears nowhere. The certificate on the picker stays. |
| A11Y-29 | §9.2.5, §9.2.7, §15.5, §14.11 | `shareable: {genre_weights, top_series, art_series}` (in the text and the response shape) is computed only from non-mature series. Empty templates are omitted. The in-app Annual keeps the gated data. |
| A11Y-30 | §9.3.1, §9.3.8, §9.2.7, §15.5, §14.11, §7.25 | S(member, viewer) is defined, including "reading done before sharing was turned on never counts" and the double 18+ condition. The where-it-applies list matches the judge's. The §7.25 reading-now ring repeats the same conditions. |
| A11Y-31 | §7.6 World card, §7.19, §15.7 | With the gate open, the 16 px certificate on its black fill when `is_adult` or any `available[]` source is mature. It is in the §15.7 18+ badges check. |
| A11Y-32 | §9.1.7, §9.2.7, §15.5 | `/home` is keyed by `(profile_id, mature_content_enabled, content_kind, tz_offset_minutes, local hour)`, `/library/annual` by `(profile_id, mature_content_enabled, content_kind, year, tz_offset_minutes)`, both with "no purge hook". Per-series caches keep gating on serve. The old "cached 10 min per profile; 18+ gated on serve" appears nowhere. |
| A11Y-35 | §9.3.4 | "Only readers who can see" appears nowhere. Eligible recipients are listed without explanation. The neutral empty line is kept. |
| A11Y-37 | §14.1, §4.8 | The leader dial, indeterminate rule and button loading segment keep running, and "loops stop" never applies to them. §4.8 has the matching row. |
| A11Y-38 | §7.11, §8.0.6, §8.33.2, §8.30.2 row 12 | `Alt+T` "Go to notifications" with `<Toaster hotkey={['altKey','KeyT']} />` and Flutter `Shortcuts`. Listed in the global keys, the `?` sheet and the General group. |
| A11Y-39 | §8.15.2, §8.15.8, §14.3 | 500 ms hover tooltip in `type.kicker`, a long-press popover (long-press is otherwise unassigned in the novel body), and an inline `sr-only` / `semanticsLabel` name. §14.3 has the new wording. |
| A11Y-40 | §3.3, §3.5, §15.1 | `kicker`, `credit` and `credit.label` cap 2.0 in the §3.3 table and in the §3.5 Flutter map. `nav` and `micro` keep 1.5. The §15.1 kicker `scaleCap` is 2.0. |
| A11Y-41 | §2.1.1, §2.1.2, §2.1.3, §14.2, §7.25, §8.16.5 | Recomputed: spot 13.94, bone on spot 1.32, rule.1 1.46, rule.2 1.90. No "13.5", "1.4:1", "1.5:1" or "2.0:1" is left. Avatar fields recomputed on the live hexes: Usher 4.53 (min), Newsreel and Premiere 4.54, Marquee 4.58, Phantom 6.82 (max). The §7.25 text ("every field reaches 4.5:1, 4.53:1 minimum on Usher") is true and stricter than the judge's ≥ 3:1 (this follows CONSISTENCY-14; accepted in round 1). Monogram field HLS(h, 0.28, 0.45): worst case at 60° is 5.16 here against the stated 5.13 (HLS rounding). Both are ≥ 4.5. |

## Observations outside this recheck (not caused by the a11y fixes, or not blocking)

- **Text on duotone with no named ground.** The over-art rule covers these, but the component specs never say how they meet it, and neither is a row in the §15.7 over-art table:
  - The §7.8 preview slate's top half: title in `type.subhead` over "the duotone cover backdrop (`blur.card`)".
  - The §8.7 onboarding format tiles: "the word in Bodoni Moda Italic 32" on a duotone mosaic.

  Give each a `scrim.foot` solid point or a black band, and add both rows.
- **Storage meter segment in `ink.30`.** In §7.18, "other apps `ink.30`" is a meter segment that carries information, against §2.1.1 "`ink.30` … never information". It sits next to the `rule.1` free segment, and the two are about 1.6:1 apart. The accessible `aria-valuetext` covers screen readers only. Suggest `ink.60` for the other-apps segment.
- **Quiet `Close` and `Skip recaps for this series`** (§9.1.5 actions) are sticky at the bottom on phones over the `#000` page, not over the band, so they are fine. They are listed here only so that the A11Y-1 fix does not move them onto the band.
