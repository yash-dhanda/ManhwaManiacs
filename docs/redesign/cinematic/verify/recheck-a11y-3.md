# Cinematic DESIGN.md: recheck round 3, accessibility, privacy and safety lens

Rechecked 2026-09-28 against `cinematic/verify/judge-a11y.md`, section "Confirmed" (34 findings). The live `cinematic/DESIGN.md` was 4,657 lines, last written 23:14:12, md5 `373e7a2b…`, and it was unchanged at the end of the recheck. Line numbers below refer to that version. The 8 refuted findings (A11Y-12, 24, 25, 26, 27, 34, 36, 42) are not rechecked.

`recheck-a11y-2.md` and the round 3 part of `fixed-a11y.md` were used only to find the edits. Every finding was rechecked, not only the three that round 2 left open, because the stack, consistency, product and mobile lenses (and a main-session round 4) wrote to the file after round 2.

Method, for each finding:

1. Read the section the final fix names and compare it with the fix text, value by value.
2. Grep for the old value and for every other place the changed value is repeated.
3. Recompute the stated figures with the WCAG 2.x relative-luminance formula, alpha composited in sRGB. The script is `scratchpad/ra3/cr.py` in this session.

For A11Y-1, the over-art rule is general, so I also swept the file for components placed over art: corner controls, chips, HUDs, captions and `bare` icon buttons.

**Result: 33 resolved, 1 unresolved (A11Y-1).**

- **Round 3 fixes that hold.** All three round 3 fixes are correct where they were applied:
  - A11Y-3: the stale §2.1.1 clause is gone.
  - A11Y-1: `Skip recap →` and The Annual's close `x` are `on-art`.
  - A11Y-33: the `keydown` pause now excludes `Space`, `Enter`, `s` and `Esc`.
- **Round 3 observation fixes that hold.** The preview slate and the onboarding tiles now sit on `scrim.foot`, and the storage meter segment is now `ink.60`.
- **Why A11Y-1 is still open.** The sweep found five more places, all present since before the verify rounds, that contradict the over-art rule. Two are specified as `bare` icon buttons over a poster or a cover. Three are chips, HUDs or captions over pages with no ground. Each is fixed with one clause.

## Unresolved

### A11Y-1: more controls and labels over art with no ground

**What is in place.** Every item of the judge's fix, plus the round 2 and round 3 additions, is in place and consistent (details in the Resolved table). The rules now in the file are:

- **§2.1.4, l.118.** "Every text run and icon drawn over art … sits on black whose alpha across its line box ± 8 px is at least the value below."
- **§2.1.4, l.129.** "Controls where no scrim reaches use the `on-art` variants (§7.1, §7.2)."

The component rows below contradict those rules. An implementer who builds from the component row gets a failing result.

1. **World card dismiss `x` and `More like this` (§7.6 l.1143, §9.1.3 l.3142).**
   - **Spec.** The `x` is "(bare icon button) appears top-right on hover", and the `thumbs-up` is "a … bare icon button beside the dismiss `x`". Both sit on the card's top-right corner, which is the poster's corner.
   - **Why it fails.** A `bare` icon is a 24 Light glyph in `ink.60` with no ground (§7.2). It measures 2.92:1 over a white cover and 2.51:1 over the worst-case duo `#F5F547`. That is under the 3:1 icon threshold, and the rule asks for black at 0.82 under `ink.60`.
   - **Inconsistency.** Library posters already use `on-art` icon buttons for the same hover corner (§7.7 l.1172).
   - **Fix.** Both become `on-art` icon buttons (§7.2: a 40 px `color.onart` square, glyph `ink.100`, 5.89:1 over `#FFFFFF`).
2. **Lightbox chrome (§7.30 l.1564, l.1566).**
   - **Spec.**
     - The `x` is a `bare` icon button.
     - The caption is `type.caption` `ink.60` with no ground.
     - The zoom level shows as "a folio chip `250%` top-centre", and "folio chip" is not defined anywhere.
     - The keyboard zoom buttons (`+`, `−`, `Fit`) have no variant.
   - **Why it fails.** At rest the art is contained, so the chrome usually falls on the 0.96 barrier. Zoomed, it does not: pinch goes up to 4× and double tap to 2.5×, the art fills the viewport, and the chrome returns on tap over it. The zoom chip shows only while zoomed, so it is always over art.
   - **Fix.**
     - `x`, `+`, `−` and `Fit` are `on-art` icon buttons.
     - The caption and the zoom chip sit on the §7.20 folio-flag ground: a `#000` box with a 1 px `ink.100` border (l.1441). `ink.60` measures 7.20:1 there.
3. **Manga reader zoom chip and edge HUDs (§8.14.5 l.2236, l.2240–2241).**
   - **Spec.**
     - The zoom level is "a folio chip `200%` top-centre", which is the same undefined chip.
     - The brightness HUD (the `sun-dim` glyph and the folio value, `NIGHT −40`) and the auto-scroll speed HUD (`1.5×`) sit over the page at the left and right 12 % edges with no ground. `ink.100` over a white page measures 1.14:1.
   - **Fix.** The chip, and the HUD's glyph and value, sit on the same folio-flag ground. The HUD's bar can keep its outline and fill.
4. **New-chapter caption after a pull (§8.14.6 l.2251).**
   - **Spec.** "the new chapter's title is typed … as a caption top-left (`CH 143 — The Return`), fading after 2 s". It lies over the next chapter's first page, and no ground is stated. The running head's scrim is visible only for the first 800 ms (§8.14.2), and the caption lasts longer than that.
   - **Fix.** The folio-flag ground.
5. **Guided view folio (§9.4.3 l.3541, l.3545).**
   - **Spec.** `PANEL 3 / 7 · PAGE 18` sits at the bottom-left on the 0.85 matte, where `ink.60` measures 5.17:1, which passes. But in the states where "the page shows whole" (`PAGE 18 · FINDING PANELS`, `PAGE 18 · WHOLE PAGE` and the double-tap overview), no matte is drawn, and the folio can fall on the page.
   - **Fix.** The folio-flag ground in every state.

**Suggested edit.**

- Add one sentence to the §2.1.4 solid-ground paragraph: "Floating chips, HUDs, flags and captions drawn over art or pages (the Lightbox and reader zoom chips, the brightness and speed HUDs, the new-chapter caption, the guided-view folio, the Lightbox caption) sit on the §7.20 folio-flag ground (`#000000` box, 1 px `ink.100` border); icon buttons over art are `on-art` (the World card's dismiss and `More like this`, the Lightbox's close and zoom buttons)."
- Change "bare" to "`on-art`" at l.1143, l.3142 and l.1564.
- Add the same components as rows of the §15.7 over-art check (l.4422).

## Resolved

| ID | Where it now lives | Checks |
|---|---|---|
| A11Y-1 (except the five places above) | §2.1.4 l.97–129, §2.8.3 l.486–500, §7.1, §7.2, §7.8, §7.24, §8.7, §8.14.3, §8.14.6, §9.1.5, §9.2.4, §14.2, §15.7 | **Scrims.** `scrim.head` is `#000` 0.88 flat over the bar's laid-out height, then the 13 stops reversed over 44 / 64 px. `scrim.sole` is 0.90 flat over the folio bar, then the stops over 64 px. **Over-art table.** 0.60 / 0.68 / 0.66 / 0.70 / 0.82 / 0.84. Recomputed over `#FFFFFF`: 5.04 / 4.61 / 4.82 / 4.63 / 4.66 / 4.76. Over `#F5F547`: 5.62 / 5.04 / 5.30 / 5.04 / 4.88 / 4.94. **Other grounds.** `scrim.foot` is solid 24 px above the text block. `6 MIN LEFT` is `ink.60`. The rating card sits in a `paper.0` box with 8 × 12 px padding. Coming up is on black at 0.84. No 0.42, 0.52–0.64 or 0.68 scrim alpha is left. **Round 3.** `Skip recap →` is `on-art` (§9.1.5 l.3182; §7.1 on-art row; §2.1.4 `scrim.foot.black` row, "the one control on the band … brings its own ground"). The Annual phone close `x` is the `on-art` icon button (§9.2.4 l.3340). A new §2.1.4 sentence, repeated in §14.2 and §15.7, covers `on-art` controls where no scrim reaches: `color.onart` is `rgba(0,0,0,0.64)` = Flutter `0xA3000000` (l.369), and `ink.100` on it measures 5.89:1 over `#FFFFFF` and 6.51:1 over `#F5F547` (recomputed). The preview slate title (§7.8 l.1192) and the onboarding format words (§8.7) sit on a `scrim.foot` solid end colour, and both are in the `scrim.foot` Where column. The dialogue subtitle (§8.24 l.2819: `ink.100` on `color.onart`, crop at `brightness(0.8)`) holds at 7.85:1, and 5.62:1 under the `spot.wash` on matched terms. |
| A11Y-2 | §8.16.3 l.2531–2541 | The duotone runs at 15 % with the vignette and grain 0.05. Inactive sentences are `ink.60` at full opacity (5.34 / 7.20). The active sentence measures 9.21. The speaker kickers measure ≥ 6.80 / ≥ 9.17. The head kicker is in `ink.60`. The full player is an over-art row in §15.7. The only remaining "35 %" values are the skeleton width and the mini player's buffered rule. |
| A11Y-3 | §2.1.1 l.71, §2.1.4 l.118 and l.129, §7.19 l.1415, §14.2 l.4151 | §2.1.1 now reads "Over art the §2.1.4 over-art rule applies instead, and `ink.45` is used there only on a solid ground (a badge's `#000000` fill, the rating card's `paper.0` box)", which is word for word the round 2 fix. No "never used there" is left. All four places now agree: `ink.30` is never used over art, and `ink.45` only on a solid ground. The §7.19 figures reproduce: 18.44 / 13.94 / 11.41 / 7.20 / 6.85 / 4.70. |
| A11Y-4 | §8.21 l.2734, §7.7 | `UNAVAILABLE ON THIS PROFILE` and "pinned source missing" appear 0 times. The server-omits line is present. |
| A11Y-5 | §7.4 l.1100–1103 | The placeholder is `ink.45` (4.70), and `ink.60` (6.42) in the palette. The four accessible names are present. The typed layer is `aria-hidden` and not a `TypedHeadline`. The real `placeholder` / `hintText` shows statically while the field is focused and empty. The masthead kicker gives the context. |
| A11Y-6 | §7.7 l.1156 and l.1176, §8.7, §8.24 l.2834, §8.32 l.3036, §8.23, §7.18 l.1409 | **Unchanged since round 2.** Rank numerals are `ink.45` with "Number 3, Solo Leveling". The skipped genre is "Romance, skipped". `image-broken` is `ink.45`, labelled "Cover didn't load" / "Page didn't load". The 404 numeral is decorative. `REMOVING…` is `ink.45`. **Round 3.** The storage meter's other-apps segment is now `ink.60` ("information, so never `ink.30`"). **Grep.** Every remaining `ink.30` is disabled text, a rule, an outline, a separator, a tick, a grabber or the decorative 404 numeral. |
| A11Y-7 | §2.1.1 l.71, §14.2 l.4150 | The structural raised-scope rule is in place, with the Ink / Slate canvas, the select-mode bar, own and tinted rows, and `proof.wash` and error rows. `spot.wash` renders `ink.80`. Stock panels use `muted`. The main-session round 4 (CONSISTENCY-32) now states "≥ 5.84:1 on the six fixed stocks, ≥ 5.5:1 on the Issue stock". That is more precise than the judge's single "≥ 5.84", both floors are above 4.5, and §14.2 matches. The loop is extended as the fix lists. |
| A11Y-8 | §10.2.3, §10.2.1, §8.20 l.2698, §8.24 l.2817, §14.4 l.4164 | `as?: "h1" \| "h2" \| "h3" \| "p" \| "span"`, default `"p"`. The h1 list and the h2 notices (including System status) match the fix. Discover and Dialogue have visually hidden h1 route targets on both clients. |
| A11Y-9 | §10.1.6 l.3822, §10.2.4, §14.5 | `Semantics(header: true, headingLevel: widget.level, …)` wraps every branch, and `TypedHeadline` uses `header: level != null`. The fourth test uses `containsSemantics(isHeader: true, label: 'Library')`. |
| A11Y-10 | §10.1.1 l.3584–3585, §10.1.5 l.3643–3668, §10.1.6 l.3821–3875 | The clamped `textScaler` is on the whole `Text`, every letter and the spacer. The rise is `0.42 × scaler.scale(fontSize)`. The web `useWordsFit` reads `ref.current` inside `check()` and observes the parent. The Flutter `LayoutBuilder` + `TextPainter` fallback uses `_c.drive(CurveTween(…))`. The fifth and sixth test cases are unchanged. |
| A11Y-11 | §7 intro l.997, §7.19 l.1413, §7.11 l.1259 | Every §7 height is a minimum (`min-height` / `ConstrainedBox`). The badge is min 16 with `padding-block: 2px`. The toast is "never truncated". No "2 lines max" is left, and "height 16" appears only as "min height 16". |
| A11Y-13 | §3.1 l.583, §14.4 l.4165, §14.7 l.4195 | **In place.** `highContrastOf` maps to `CineTokens.copyWith(colorInk45: colorInk80, colorRule1: colorRule2)`. Bold Text is clamped to the per-face maxima, and Plex Mono uses its 600 static. **Kept from round 1.** Bold Text adds +120, not the judge's +150. It reuses the novel Bold text step, the file is consistent in three places, and the defect is fixed. |
| A11Y-14 | §7 intro Semantics table l.1004–1019 | Every row of the judge's contract is present, with Flutter values. |
| A11Y-15 | §7.5 Count l.1114, §7.29 l.1554, §14.5 | Counts are raised ordinary digits, and no Unicode superscripts are used. `folioLabel()` exists at both paths, with the seven conversions and one table test per client. The rule covers every superscript count. |
| A11Y-16 | §14.5 l.4177, §14.4 l.4168, §8.14.3 l.2205 | Timers wait while focus is inside, on both clients and for every user. There is no idle or scroll hide while focus is inside. A user-commanded hide moves focus to the reader canvas. |
| A11Y-17 | §7.8 Slate focus l.1193 | Unchanged and complete. |
| A11Y-18 | §8.8 l.1990 and l.1992, §14.4 l.4168 | The column is inert at `p` ≥ 0.55. The strip joins the tab order at `p` ≥ 0.8, and it fades in over 0.6 → 1 (l.1985), so its opacity is 0.5 at 0.8. No "`p` = 1" tab-order sentence is left. |
| A11Y-19 | §7.3 l.1080 | The Show/Hide button stays in the tab order with `aria-pressed` "Show password", `aria-controls` and Flutter `Semantics(button: true, toggled:)`. "excluded from the tab order" appears 0 times. |
| A11Y-20 | §7.22 l.1478, §7.16 l.1384, §11 l.4041, §8.21 l.2740 | The four Move items are disabled at the ends, with the 240 ms `set` shift, `sort_order` and the announcement. The §11 row lists them plus `Alt+↑/↓`. |
| A11Y-21 | §9.2.1 l.3280, §2.1.6 l.218 | `ink.100` squares of 3 / 5 / 7 / 10 px, the zero-day `rule.2` outline, the today `spot` outline and the legend `0 · 1–2 · 3–5 · 6–10 · 11+` are present. `heat.1`–`heat.4` appear 0 times. |
| A11Y-22 | §2.4 l.280, §2.8.2 l.473, §7 intro l.998, §7.7 l.1168, §14.4 l.4162 | The double ring (`box-shadow: 0 0 0 6px #000`, 5 hits) combines with the poster's inset hairline. `CineFocusRing` and `focusHaloWidth` are present. |
| A11Y-23 | §7 intro l.996, §14.6 l.4188–4189, §7.5 l.1116 | Coarse pointers get 44 pt / 48 dp, and fine pointers ≥ 32 px with 24 px spacing. The slug-line hit box is `max(label width + 24, 44)` × 44 (48 Android). A scripted scan finds no 44 hit, target or tap mention without its 48. |
| A11Y-28 | §8.5 l.1862 | The credit line shows only "NEW". `LAST READ` appears 0 times. |
| A11Y-29 | §9.2.5, §9.2.7 l.3387 and l.3403, §15.5 l.4383 | `shareable: {genre_weights, top_series, art_series}` is computed only from non-mature series. It appears in the text, the response shape and §15.5. |
| A11Y-30 | §9.3.1 l.3421, §9.3.8 l.3488, §7.25 l.1529, §9.3.4 l.3467 | S(member, viewer) is defined, including "reading done before sharing was turned on never counts" and the double 18+ condition. It is repeated in the `now` rule, the reading-now ring and the recipients rule. |
| A11Y-31 | §7.6 l.1143, §7.19, §15.7 l.4423 | "Every variant" (after PRODUCT-9's three-variant rewrite) shows the certificate on its black fill when `is_adult` is true or any `available[]` source is mature. The Shelf variant follows the poster rule. |
| A11Y-32 | §9.1.7 l.3222, §9.2.7 l.3387, §15.5 l.4384 | The keys include `mature_content_enabled`, with "no purge hook". "cached 10 min per profile" appears 0 times. |
| A11Y-33 | §9.1.5 l.3184 and l.3208, §8.30.2 l.2914 | The pause trigger is "any `keydown` other than `Space`, `Enter`, `s` and `Esc` (which keep their own actions …)". The Keys line (l.3208) matches. `Space` skips the stream, then pauses or resumes. `s` skips the recap. The countdown starts only after the stream, so "Press Space to pause" is correct when it is announced. The "Continue automatically after a recap" setting is present, `ON · OFF`, default `ON`, per profile. Adding `s` goes beyond the judge's three keys, and it is needed because the Keys line assigns `s`. |
| A11Y-35 | §9.3.4 l.3467 | "Only readers who can see" appears 0 times. Recipients are "listed without explanation". The neutral empty line is kept. |
| A11Y-37 | §14.1 l.4144–4145, §4.8 l.873 | The progress indicators keep running, and "loops stop" never applies to them. |
| A11Y-38 | §7.11 l.1266, §8.0.6 l.1706, §8.30.2 l.2922, §8.33.2 l.3065 | `Alt+T` "Go to notifications" is in all four places, with the sonner default hotkey and Flutter `Shortcuts`. |
| A11Y-39 | §8.15.2 l.2414, §8.15.8 l.2498, §14.3 l.4158 | The 500 ms tooltip, the long-press popover, and the inline `sr-only` / `semanticsLabel` name are present. §14.3 has the new wording. |
| A11Y-40 | §3.3 l.636–637, §3.5 l.697–704, §15.1 l.4244 | `kicker`, `credit` and `credit.label` cap at 2.0. `nav` and `micro` stay at 1.5. The token-source kicker `scaleCap` is 2.0. |
| A11Y-41 | §2.1.1–§2.1.3, §7.25 l.1510, §8.16.5 l.2560 | Spot measures 13.9 and bone on spot 1.3, with no "13.5" or "1.4:1" left; the only "13.5" hit is the stock value 13.57. `rule.1` measures 1.46 and `rule.2` 1.9. Avatars recomputed on the live hexes: 4.53 minimum (Usher), then 4.54 (Newsreel and Premiere). The monogram field HLS(h, 0.28, 0.45) measures 5.16 at 60°, against the stated 5.13. |

## Observations (not caused by the a11y fixes, not blocking)

- **Progress graphics over art have no ground.** None of these is text or an icon, so the A11Y-1 rule does not strictly cover them. `fixed-a11y.md` round 3 left the Annual segments for this recheck to judge. My call: WCAG 1.4.11 (3:1 for graphics needed to understand state) applies to the Annual segments, which are the only visual page position. It applies less to the two rules below, whose state is also shown in text.
  - **The Annual's 2 px story segments** (§9.2.4 l.3340) sit on bleeding art. `spot` measures 1.51:1 on white and 1.29:1 on `#F5F547`, and the unfilled segment colour is not specified. Suggested fix: the segment row sits on a `color.onart` strip (8 px + segment + 8 px), and unfilled segments are `ink.100` at 40 %.
  - **The reader's micro progress** (§8.14.3) and the poster and Cutting progress rules (§7.7, §7.6) are also 2 px `spot` on art.
- **The page-tint mix is stated but not built.** §2.1.4 l.118, §2.1.5 l.173 and §9.4.4 l.3552 mix 25 % of `page.tint` into the end colour of `scrim.head` and `scrim.sole`. The §2.8.3 builds (l.493–494) hard-code `rgb(0 0 0/…)` and `Color(0xE0000000)` / `0xE6000000`.
  - This was already so at HEAD, and the mobile lens flagged it and left it.
  - It has no contrast impact. At the worst tint (L 0.06, S 0.35, hue 60°), `ink.60` at 0.88 over white measures 5.39:1 with the mix, against 5.68:1 without it.
  - Either end the utilities in `color-mix(in srgb, var(--page-tint, #000) 25%, #000)` (Flutter `Color.lerp(black, pageTint, .25)`) or drop the sentence. The over-art test rows should composite whichever end colour ships.
- **Recap countdown edge case.** If keyboard focus is already on a button in the takeover when the stream ends (for example `Continue`), no new `focusin` fires, so the countdown starts. The announced "Press Space to pause" would then activate the focused button natively instead of pausing.
  - The safe direction still holds: any other key pauses, and `Continue` is what the countdown does anyway.
  - One clause would close it: the countdown starts paused when focus is on a control inside the takeover.
