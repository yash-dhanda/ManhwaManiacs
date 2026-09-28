# Cinematic DESIGN.md: recheck round 1, accessibility, privacy and safety lens

Rechecked 2026-09-28 against `cinematic/verify/judge-a11y.md`, section "Confirmed" (34 findings). The 8 refuted findings (A11Y-12, 24, 25, 26, 27, 34, 36, 42) are not rechecked. The fix log `cinematic/verify/fixed-a11y.md` was used only to locate the edits.

Method, for each finding:

1. Read the section the final fix names and compare it with the fix text, value by value.
2. Grep for the old value and for every other place the changed value is repeated.
3. Recompute the figures that the fix states. Every contrast figure below was recomputed with the WCAG 2.x relative-luminance formula.

Other lenses were still writing to DESIGN.md during this recheck. It grew from 4,645 to 4,652 lines, and the `scrim.head`, `scrim.sole` and `scrim.foot.black` rows changed under me. Section numbers are used instead of line numbers for that reason. The three unresolved markers were re-grepped on the live file just before this report was written.

**Result: 31 resolved, 3 unresolved (A11Y-3, A11Y-10, A11Y-18).** Each unresolved item has a small fix: two are one-sentence wording conflicts and one is a single line of reference code.

## Unresolved

### A11Y-18: the Flutter paragraph under the trailer scrub still says "p = 1"

The applied fix is correct in two places:

- §8.8 "Focus during the scrub": the column becomes inert at p ≥ 0.55, the strip's controls join the tab order at p ≥ 0.8, and there are rules for focus rescue, reversal and reduced motion.
- §14.4 "Hidden chrome" bullet: the same thresholds, "inert at trailer progress p ≥ 0.55 and the strip's controls enter the tab order at p ≥ 0.8".

**Contradiction.** A few lines further down in §8.8, the implementation paragraph ("Web: Motion `useScroll(…)` … Flutter: the spread is a pinned `SliverPersistentHeader` …") still ends its Flutter half with the pre-fix sentence: **"The strip's controls enter the tab order only when `p` = 1."** That sentence is exactly the defect the judge described ("The strip's controls join the tab order only at p = 1"), and it contradicts the new bullet directly above it.

**Fix.** Replace that sentence with "The strip's controls enter the tab order at `p` ≥ 0.8 and the text column goes inert at `p` ≥ 0.55 (`ExcludeFocus` + `ExcludeSemantics`), as in "Focus during the scrub" above."

### A11Y-10: the web `useWordsFit` re-check measures a detached element after the heading swaps elements

The spec half is complete:

- §10.1.1 has the Text scale and Long words rows and the "Transmigration" test.
- §10.1.6 Flutter passes the clamped `textScaler` to the whole `Text` and to every letter, computes the rise as `0.42 × scaler.scale(fontSize)`, and has the `LayoutBuilder` + `TextPainter` fallback and the fifth test case.
- §10.1.5 web has `useWordsFit` and the plain-string branch.

**Defect in the reference code (§10.1.5).** `useWordsFit` captures the element once, when the effect first runs:

```tsx
useLayoutEffect(() => {
  const el = ref.current, box = el?.parentElement;
  …
  const check = () => { el.appendChild(probe); … setFits(widest <= box.clientWidth); };
  check();
  const ro = new ResizeObserver(check); ro.observe(box);
  …
}, [ref, text]);
```

`SetHeading` renders `<M>` (`motion[Tag]`) while idle or running and plain `<Tag>` once `phase === "done"`. These are different element types, so React replaces the DOM node at the end of every reveal. The effect does not re-run (`ref` and `text` are unchanged), so every later `ResizeObserver` callback appends the probe to the old, detached node. There `offsetWidth` is 0, `widest` becomes 0 and `setFits(true)` wins.

The result: the §10.1.1 promise to re-check on resize holds only until the first reveal finishes. A heading that fitted at mount and is later narrowed will overflow again with no fallback. Two examples are rotating a phone to portrait and expanding the sidebar from the spine at 1280. The same happens to a seen-at-mount heading that switched to the fallback once.

**Fix (one line).** Inside `check`, read the element at call time: `const el = ref.current; if (!el) return;`. Keep `box` as the observed parent. Alternatively, render the `"done"` branch as `<M>` as well, so the node is never replaced.

### A11Y-3: the over-art rule's wording forbids what the badge fix prescribes

§7.19 "Badges on art" is applied as written. Every outlined badge that can sit on art (poster badges, Cutting nudges, World card badges, the running head's `OFFLINE EDITION`) gets a `#000000` fill inside its 1 px outline. The 18+ certificate on art is a black square with a `proof` outline, and "Sizes and the 4 px stack gap do not change". The listed flat-black figures reproduce: ink.100 18.44, spot 13.94, set 11.41, ink.60 7.20, proof 6.85, ink.45 4.70. §14.2 and the §15.7 over-art rows include badges on their fill.

**Contradiction.** The §2.1.4 over-art rule (repeated in §14.2) says two things that the badges cannot meet:

- Every text run over art "sits on black whose alpha across its line box **± 8 px** is at least the value below". A badge's fill extends only 2 px above and below its text (`padding-block: 2px`) and 4 px to each side, and §7.19 forbids changing the size.
- "`ink.45` and `ink.30` are **never used over art**." The `TEXT` badge (dialogue indexed) is `ink.45` text, and it is one of the poster badges listed in §7.7. §7.19 itself quotes the `ink.45` 4.70 figure for badges on their fill.

The list of solid grounds in §2.1.4 ("Components that cannot meet it with a scrim get a solid ground: the rating card … the Coming up card …") does not name badges. Read literally, the rule therefore requires 8 px of black around every badge and bans the `TEXT` badge's ink.

**Fix.** Add one sentence to that §2.1.4 paragraph, and a matching clause to the §14.2 "Over art" bullet: "Badges that can sit on art get a `#000000` fill (§7.19). On a solid ground (alpha 1: a badge fill, the rating card's `paper.0` box) the ± 8 px margin is the box's own padding, and `ink.45` is allowed there (4.70:1)."

## Resolved

| ID | Where it now lives | Checks |
|---|---|---|
| A11Y-1 | §2.1.4 `scrim.head`, `scrim.sole`, `scrim.foot`, `scrim.foot.black`, the over-art rule and table, the solid grounds and the test table; §2.8.3 rows; §8.14.3 `6 MIN LEFT`; §7.24 rating card; §8.14.6 Coming up; §14.2; §15.7 | `scrim.head` is flat 0.88 over the bar's laid-out height, then the 13 reversed stops over 44 / 64 px. At 0.88 over white: ink.60 5.65, spot 10.94, ink.100 14.47. `scrim.sole` is flat 0.90. Flutter uses `0xE0` and `0xE6` (0.878 and 0.902). Another lens has since made the flat part follow the grown bar and the Android 48 px bar, which is consistent with the fix. The minimum-alpha table matches the judge's (0.60 / 0.68 / 0.66 / 0.70 / 0.82 / 0.84). `scrim.foot` reaches its solid end colour 24 px above the text block in both §2.1.4 and §2.8.3 (`solidAt`). `scrim.foot.black` now says "no text sits on the band" in §2.1.4, and that agrees with §2.8.3 and §15.7. `6 MIN LEFT` is `ink.60`. No 0.42, 0.52–0.64 or 0.68 scrim alphas are left. The page-tint mix is kept (§9.4.4). The badge wording conflict is filed under A11Y-3. |
| A11Y-2 | §8.16.3 | Duotone at 15 % with the vignette and 0.05 grain. Inactive sentences are `ink.60` at full opacity (5.34 / 7.20). The active sentence is 9.21. Speaker kickers are ≥ 6.80 / ≥ 9.17. `NOW READING ALOUD` is `ink.60`. The full player is a §15.7 over-art row. No "35 %" or "50 %" remains in Listen. |
| A11Y-4 | §8.21, §7.7 Disabled | `UNAVAILABLE ON THIS PROFILE` and "pinned source missing" are gone. The omitted-by-server line is present, and the client never shows or filters stale pins. The phone long-press list gained the move items (A11Y-20). |
| A11Y-5 | §7.4 `index` and "`index` accessibility"; §10.2.2 | Placeholder `ink.45` (4.70), and `ink.60` (6.42) inside the palette's `paper.2`. Four accessible names. The typed layer is `aria-hidden` and not a `TypedHeadline`. There is a real `placeholder` / `hintText`, the placeholder is static while focused and empty, and the masthead kicker gives visible context. |
| A11Y-6 | §7.7 Ranked and Error, §8.7, §8.24, §8.32 | Rank numerals `ink.45` with "Number 3, Solo Leveling". The skipped genre is `ink.45` + `proof` strike + "Romance, skipped". The 404 numeral is `aria-hidden` / `ExcludeSemantics`. `image-broken` is `ink.45`, labelled "Cover didn't load" / "Page didn't load". No `ink.30` carries a rank, a state or a glyph now (see Observations for a new `ink.30` use from another lens). |
| A11Y-7 | §2.1.1 | Structural raised-scope rule with the explicit Ink/Slate canvas, select-mode bar, own and tinted rows, `proof.wash` and error rows. `spot.wash` renders `ink.80` (9.41 / 6.98). Stock panels use `muted` (≥ 5.84). The loop is extended with `ground.ink`, `ground.slate`, the washes over `paper.0`–`paper.3` and the six stocks. §14.2 agrees. |
| A11Y-8 | §10.2.3 (`as`, default `p`, `sr-only` span), §10.2.1, §10.2.2, §8.20, §8.24, §14.4, §14.5 | The h1 list matches the judge's. Other notices are `h2`, including System status. Discover and Dialogue have the `sr-only` h1 and the Flutter zero-size `Semantics(header: true, headingLevel: 1)` target. No hard-coded `<h1>` is left in `TypedHeadline`. |
| A11Y-9 | §10.1.6 (`level`, `cap`, `head()` wrapper on the seen, reduced and animating branches), §10.1.1, §10.2.4, §14.5 | `Semantics(header: true, headingLevel: …)` on every branch. `TypedHeadline` uses `header: level != null`, and `headingLevel` accepts null in the pinned SDK (`widgets/basic.dart`, `semantics.dart` assert 0–6). The `containsSemantics(isHeader: true, label: 'Library')` case is present. |
| A11Y-11 | §7 intro Heights, §7.19, §7.11 Text, §3.3 "Heights are minimums", §14.7 | Every listed height is a minimum. Badge min 16 with `padding-block: 2px`. Toasts are "never truncated", keeping the 560 max. No "2 lines max" or "height 16" is left. |
| A11Y-13 | §14.4, §14.7, §3.1, §15.7 | `highContrastOf` applies the same remap through `CineTokens.copyWith(colorInk45: colorInk80, colorRule1: colorRule2)`. Bold Text is honoured with the per-face clamps from the judge's table (Bodoni Moda, Archivo, Literata, Source Serif 4: 900; Newsreader, Atkinson: 800) and Plex Mono 600. **Deviation:** the step is +120, not the judge's +150, because it reuses the novel reader's existing Bold text step (400 → 520, §3.4, §8.15.5). §3.1, §3.4 and §14.7 all say 120, so there is no internal conflict, and the defect (no designed weight under OS Bold Text) is fixed. Accepted. |
| A11Y-14 | §7 intro "Semantics" table, §14.5 | Every row from the judge's contract is present, with Flutter values filled in (checkbox, tri-state, meter, progress, flame). |
| A11Y-15 | §7.5 Count, §7.29 "Spoken folios", §14.5 | Ordinary raised digits (`0.72em` / `0.5em`; Flutter `Transform.translate(0, −0.35 × fontSize)`). `folioLabel()` at both paths with the seven conversions and a table test per client. |
| A11Y-16 | §14.5 "Timers wait while focus is inside", §8.14.3 Auto-hide and Cinema mode, §14.4 | Applies on both clients for every user and covers §8.14.3, §8.15.3, §7.30 and §8.16.2. The scroll-hide case is solved more strictly than the judge asked: the chrome never auto-hides (idle or scroll) while it holds focus, and a user-commanded hide moves focus to the reading surface. The canvas label is "Chapter 143, page 1 of 40" (from the web lens) instead of "Reader, Chapter 142". Both are labelled regions, and there is no conflict. |
| A11Y-17 | §7.8 "Slate focus" row | Non-modal `role="dialog"` with `aria-labelledby`; focus to `Read`; Tab cycle; `Esc`/`Space` return focus; `aria-expanded` / `aria-controls`; pointer-dwell slates never take focus; Flutter `FocusScope`. |
| A11Y-19 | §7.3 Password reveal, §8.3 Keys | In the tab order after its field, with `aria-pressed` "Show password", `aria-controls` and Flutter `Semantics(button: true, toggled:)`. §8.3's Tab order (… password → Show → …) now agrees. "excluded from the tab order" is gone. |
| A11Y-20 | §7.22 "Move items", §11 drag row, §8.21 | Four menu items, disabled at the ends, 240 ms `set`, `sort_order`, the announcement, and the `ReorderableListView` note. The §11 alternative column lists them plus `Alt+↑/↓`. |
| A11Y-21 | §9.2.1, §2.1.6 chart palette, §2.8.1 | Squares of 3 / 5 / 7 / 10 px in `ink.100`, the zero-day `rule.2` outline, today's `spot` outline and the `0 · 1–2 · 3–5 · 6–10 · 11+` legend. `color.heat.*` is gone from every table (grep finds no `heat.1`–`heat.4`). |
| A11Y-22 | §2.4 Focus light, §2.8.2 `focus.halo`, §7 intro Focus, §7.7 Focused, §14.4, §14.2 | Double ring, `box-shadow: 0 0 0 6px #000` combined with the inset hairline on posters, Flutter `CineFocusRing` + `focusHaloWidth`. The 8 px focus padding holds the halo. |
| A11Y-23 | §7 intro Hit area, §14.6, §2.7, §2.8.2 `hit.fine`, §7.5, §7.20, §7.30, §8.8, §8.14.3–§8.14.4, §9.1.5 | Coarse 44 pt / 48 dp; fine ≥ 32 px with 24 px spacing. Every "44 hit" has its Android value (grep finds no hit line with 44 but no 48). Item 3 was replaced by another lens raising the Android running head to 48. §7.13, §8.8, §8.14.3, §2.1.4 and §2.8.3 all use 48 on Android, and no stale "safe area + 44" remains for Android. |
| A11Y-28 | §8.5 | The credit line shows only `NEW`, with the reason given. `LAST READ` is gone. The certificate on the picker stays. |
| A11Y-29 | §9.2.5 Privacy rules, §9.2.7 (text and response shape), §15.5, §14.11 | `shareable {genre_weights, top_series, art_series}` is computed from series that are not mature. Templates with empty shareable data are omitted. The in-app Annual keeps the gated data. |
| A11Y-30 | §9.3.1, §9.3.8, §9.2.7, §15.5, §14.11 | S(member, viewer) is defined, including "reading done before sharing was turned on never counts" and the double condition for 18+. The list of where it applies matches the judge's. |
| A11Y-31 | §7.6 World card, §7.19 certificate row, §15.7 | `is_adult` or any mature `available[]` source, gate open, 16 px certificate on its black fill. |
| A11Y-32 | §9.1.7 `/home`, §9.2.7 `/library/annual`, §15.5 | Keyed by `(profile_id, mature_content_enabled, content_kind, …)` with "no purge hook". Per-series caches keep gating on serve. |
| A11Y-33 | §9.1.5 Auto-continue countdown, §8.30.2 rows 03 and 04 | Web pause on `keydown`, `pointerdown`, a text selection and `focusin`. The polite announcement says "Press Space to pause". The setting is `ON · OFF`, default `ON`, per profile, shown in both rows. `Esc` still closes. |
| A11Y-35 | §9.3.4 | The caption is gone ("Only readers who can see" appears nowhere). Eligible recipients are listed without explanation. The neutral empty line is kept. |
| A11Y-37 | §14.1 "What does not change", §4.8 last row | The leader dial, the indeterminate rule and the button loading segment keep running, and "loops stop" never applies to them. |
| A11Y-38 | §7.11 Accessibility, §8.0.6, §8.33.2, §8.30.2 row 12 | `Alt+T` "Go to notifications", `<Toaster hotkey={['altKey','KeyT']} />`, Flutter `Shortcuts`. It appears in the global keys table, the `?` sheet and the General group. |
| A11Y-39 | §8.15.2 Speaker tints, §8.15.8 Gestures, §14.3 | Hover tooltip (500 ms, `type.kicker`), long-press popover, inline `sr-only` / `semanticsLabel` name. §14.3 has the new wording. |
| A11Y-40 | §3.3 caps table and literal note, §3.5 `typeKicker` / `typeCredit` / `typeCreditLabel` `cap: 2.0`, §15.1 kicker `scaleCap` 2.0 | `nav` and `micro` keep 1.5 in §3.3 and §3.5. The form label (§7.3 `type.kicker`) now reaches 22 px at 2.0. |
| A11Y-41 | §2.1.1 (`rule.1` 1.46, `rule.2` 1.9, loop), §2.1.2 (13.9 in the table and prose), §2.1.3 (`note` 13.9, bone on spot 1.3), §14.2, §8.16.5, §7.25 | Recomputed: spot 13.94, bone on spot 1.32, rule.1 1.46, rule.2 1.90. The monogram field HLS(h, 0.28, 0.45) has its worst case at 60° with 5.13:1. No "13.5" is left for spot. **§7.25 differs from the judge's text on purpose:** CONSISTENCY-14 darkened the six weak avatar fields, so the page now says "≥ 3:1 is required for a non-text glyph; every field reaches 4.5:1, 4.53:1 minimum on Usher". Recomputed on the live hexes: Usher 4.53 (min), Newsreel and Premiere 4.54, Marquee 4.58, Phantom 6.82 (max). The statement is true, and the loop checks ≥ 4.5:1. Accepted. |

## Observations outside this recheck (not caused by the a11y fixes, or not blocking)

- **`ink.30` carrying a state (from the web lens, WEB-10).** In §8.23 "Web activity and removal", a chapter awaiting its deferred removal "reads `REMOVING…` in `ink.30`". That breaks §2.1.1 / §14.2 ("`ink.30` … never carries information"): the row is live and the word is a state. Suggest `ink.45` (the raised scope makes it `ink.60` on a plate or row fill).
- **Superscript counts outside §7.5.** The rule "counts are ordinary digits styled smaller and raised; Unicode superscripts are never used (the ¹² in this document is notation)" sits in §7.5's Count row. Other screens also use superscript counts: §7.12 `CHAPTERS²⁰¹`, §8.9 `Filters ⁽²⁾`, §8.16.5 `FEMALE ¹⁸`, §8.16.8 / §8.19 `⁽³⁸⁾` and `⁴²`, §8.21 `PINNED⁶`, §8.23 `Show queue ⁽⁸⁾`. Suggest one sentence in §7.5 (or §7.29): the rule and a `folioLabel()` spoken form apply to every superscript count in the document.
- **§7.16 drag-to-reorder list.** It names manual library order, pinned sources, collections and profiles, but not collection members, which §7.22 "Move items" and the §11 drag row both include.
- **The Annual's focus-revealed story buttons (§9.2.4).** They are "`quiet` buttons on `color.onart`". Quiet text is `ink.60`, which needs black at 0.82 over art, while `onart` is 0.64. Use `ink.100` text on `onart` (as the §7.1 `on-art` variant does), or state that the buttons sit on the page's solid `scrim.foot` end colour.
- **§10.1.6 Flutter fallback.** `CurvedAnimation(parent: _c, …)` is created inside the `LayoutBuilder` on every build and never disposed. That leaves a status listener on `_c` per rebuild of the long-word branch. Build it once (a `late final` field) and dispose it.
- **§10.1.6 fifth test.** Beyond the judge's "must not overflow", it also asserts "that the plain-string fallback rendered" for "Transmigration" in `type.cover` at scale 2.0 in 358 px. With the display cap of 1.15 the word is set at 50.6 px, and in Bodoni Moda 700 at −0.04em it may well fit in 358 px (my rough estimate is 310–340 px; the font is not on this box to measure). If it fits, the assertion fails although nothing overflows. Suggest asserting no overflow only, or choosing a word measured to exceed the column.
- **Raised grounds under Increase Contrast.** On both clients the raised scope re-provides `ink.45` as `ink.60` locally, so the root `prefers-contrast: more` / `highContrastOf` remap to `ink.80` does not reach sheets, menus and plates. This is not a failure (`ink.60` is ≥ 5.45:1 there), but under high contrast the scopes could map to `ink.80` as well.
- **§7.7 and §8.24 figures.** The ranked numeral and the `image-broken` glyph quote "4.41 on `paper.1`" for `ink.45`. On a `paper.1` plate the raised scope renders them `ink.60` anyway, so the figure describes the unscoped ink. This is harmless.
