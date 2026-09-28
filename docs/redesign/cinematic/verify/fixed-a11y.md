# Cinematic DESIGN.md: fixes applied from the accessibility, privacy and safety judge

## Round 1

Source: `cinematic/verify/judge-a11y.md`, section "Confirmed" (34 findings). The 8 refuted findings (A11Y-12, 24, 25, 26, 27, 34, 36, 42) are not applied. Every fix was applied as the judge rewrote, narrowed or trimmed it. Section numbers refer to `cinematic/DESIGN.md`.

| ID | Sections changed |
|---|---|
| A11Y-1 | §2.1.4 `scrim.head` (0.88 flat over the bar, then the 13 eased stops reversed over 44 / 64 px), `scrim.sole` (0.90 flat over the folio bar, then eased over 64 px), `scrim.foot` and `scrim.foot.black` (solid end colour from 24 px above the text block; genre tiles, collection plates and header, Sources tiles, Annual pages added); new over-art rule and per-ink minimum-alpha table, rating-card and Coming-up grounds, over-art test table; §2.8.3 `scrim.head`, `scrim.sole` and `scrim.foot` rows (web and Flutter builds); §8.14.3 `6 MIN LEFT` in `ink.60`; §7.24 rating card in a `paper.0` box with 8 × 12 px padding; §8.14.6 Coming up text on a `#000000` band at 0.84; §14.2 Over art bullet; §15.7 Over art check |
| A11Y-2 | §8.16.3 Background (duotone at 15 %), Head kicker `ink.60`, Transcript inactive sentences `ink.60` at full opacity with the recomputed figures; the full player is a row in the over-art table (§2.1.4, §15.7) |
| A11Y-3 | §7.19 "Badges on art" (a `#000000` fill for every outlined badge on art: poster, Cutting nudge, World card, `OFFLINE EDITION`) and the 18+ certificate row; §14.2 |
| A11Y-4 | §8.21 deletes the `UNAVAILABLE ON THIS PROFILE` sentence and adds the server-omits-stale-pins line; §7.7 Disabled state drops "pinned source missing" |
| A11Y-5 | §7.4 `index` placeholder `ink.45` (raised scope `ink.60` in the palette), new "`index` accessibility" paragraph (four accessible names, typed placeholder is an `aria-hidden` visual layer, real `placeholder` / `hintText`, static full placeholder while focused and empty, masthead kicker as visible context); §10.2.2 index placeholder line |
| A11Y-6 | §7.7 Ranked numerals `ink.45` with the rank in the accessible name, Error state `image-broken` in `ink.45` labelled "Cover didn't load"; §8.7 skipped genre `ink.45` + strike-through, "Romance, skipped"; §8.24 `image-broken` `ink.45` labelled "Page didn't load"; §8.32 404 numeral decorative |
| A11Y-7 | §2.1.1 raised scope as a structural rule (every primitive on a ground other than `paper.0`, explicitly the Ink / Slate reader canvas, select-mode bar, own and tinted rows, `proof.wash` areas and error rows), `spot.wash` bands render `ink.80` (`data-stock="wash"`, `CineStock.wash`), stock-painted panels use the stock's `muted`, extended surface × ink loop; §14.2 |
| A11Y-8 | §10.2.3 `TypedHeadline` `as` prop (default `p`), `sr-only` full text, heading-level rules (where `h1` applies, `h2` notices, `span`/`p` elsewhere); §10.2.1 Accessibility row; §10.2.4 Flutter `level`; §8.20 and §8.24 visually hidden h1 route focus targets; §14.4 route focus; §14.5 |
| A11Y-9 | §10.1.6 Flutter `SetHeading` gains `level` (and `cap`), every branch wrapped in `Semantics(header: true, headingLevel: level)`, rules paragraph, `containsSemantics(isHeader: true)` test case; §10.1.1 Accessibility row; §10.2.4 `TypedHeadline` semantics; §14.5 |
| A11Y-10 | §10.1.1 new Text scale and Long words rows (with the "Transmigration" at 2.0 in 358 px test); §10.1.6 clamped `textScaler` on the whole `Text` and every letter, rise `0.42 × scaler.scale(fontSize)`, `LayoutBuilder` + `TextPainter` long-word fallback, overflow test case; §10.1.5 web `useWordsFit` (hidden span + `ResizeObserver`) and the plain-string fallback |
| A11Y-11 | §7 intro Heights bullet (web `min-height`, Flutter `ConstrainedBox` minimums; badges, buttons, inputs, menu items, sheet header, Listen tiles, mini player, folio bar); §7.19 badge min height 16 with `padding-block: 2px`; §7.11 toast Text "never truncated"; §14.7 |
| A11Y-13 | §14.4 phones apply the `prefers-contrast: more` remap under `MediaQuery.highContrastOf` through `CineTokens.copyWith`; §14.7 and §15.7 (Bold Text and Increase Contrast in the text-scale pass). The Bold Text weight rule was already in §3.1 (+120, the novel reader's Bold text step, set by another fix this round); it was kept, so the judge's +150 was not written over it |
| A11Y-14 | §7 intro new Semantics bullet and contract table (switch, checkbox, radio / single-select / segmented, toggles, tri-state genre filter, contents tabs, reaction stamps, download mark, storage meter, progress rules, streak flame, week dots); §14.5 |
| A11Y-15 | §7.5 Count row (ordinary digits styled smaller and raised, never Unicode superscripts); §7.29 new "Spoken folios" `folioLabel()` helper with its conversion table and per-client test; §14.5 |
| A11Y-16 | §14.5 "Timers wait while focus is inside" for every user on both clients; §14.4 hidden-chrome bullet (no idle or scroll hide with focus inside, focus moves to the reader canvas on a user-commanded hide); §8.14.3 Cinema mode. §8.14.3 had already gained the focus-inside suspension from another fix this round |
| A11Y-17 | §7.8 new Slate focus row (keyboard-opened non-modal dialog, focus to `Read`, Tab cycle, `Esc`/`Space` return focus, `aria-expanded` / `aria-controls`, pointer-dwell slates never take focus, Flutter `FocusScope`) |
| A11Y-18 | §8.8 new "Focus during the scrub" bullet (column inert at p ≥ 0.55, strip in the tab order at p ≥ 0.8, focus rescue, reversal, reduced motion); §14.4 wording |
| A11Y-19 | §7.3 Password reveal stays in the tab order after its field, `aria-pressed` "Show password", `aria-controls`, Flutter `Semantics(button: true, toggled:)` |
| A11Y-20 | §7.22 new "Move items" paragraph (`Move up`, `Move down`, `Move to top`, `Move to bottom`, 240 ms `set`, `sort_order`, announcement); §11 drag row alternative column; §8.21 phone long-press list |
| A11Y-21 | §9.2.1 heatmap encoded by `ink.100` square size (3 / 5 / 7 / 10 px), zero-day outline, today outline, legend `0 · 1–2 · 3–5 · 6–10 · 11+`; §2.1.6 chart palette; §2.8.1 `color.heat.1`–`color.heat.4` rows deleted |
| A11Y-22 | §2.4 Focus light row (double ring with a 6 px black halo); §2.8.2 `focus.halo` token; §7 intro Focus bullet; §7.7 Focused state (halo combined with the inset hairline); §14.4 focus ring bullet; §14.2 |
| A11Y-23 | §7 intro Hit area and §14.6 by input type (coarse 44 pt / 48 dp; fine pointer ≥ 32 px with 24 px spacing); §2.7 icon sizes; §2.8.2 `hit.*` row (`hit.fine`); "44 hit" entries given their Android value in §7.20 thumb, §7.30 close, §8.8 phone strip, §8.14.4 ruler touch, §9.1.5 Skip recap; §7.5 slug-line hit box and separator spacing. The phone running head's Android height was already raised to 48 by another fix this round (§7.13, §8.14.3), so the judge's overflow alternative was not needed |
| A11Y-28 | §8.5 picker credit line shows only `NEW` (no last-read time) |
| A11Y-29 | §9.2.5 Privacy rules (cards draw only on `shareable`); §9.2.7 `shareable: {genre_weights, top_series, art_series}` in the text and the response shape; §15.5 new row; §14.11 |
| A11Y-30 | §9.3.1 new shareable activity set S(member, viewer) and where it applies; §9.3.8 opening sentence; §9.2.7 Circle figures; §15.5 new row; §14.11 |
| A11Y-31 | §7.6 World card badge rule; §7.19 18+ certificate row (World card: `is_adult` or any mature `available[]` source); §15.7 new 18+ badges check |
| A11Y-32 | §9.1.7 `/home` cache key gains `mature_content_enabled`; §9.2.7 `/library/annual` cache key `(profile_id, mature_content_enabled, content_kind)`; §15.5 new row |
| A11Y-33 | §9.1.5 Auto-continue countdown (web pause triggers: `keydown`, `pointerdown`, text selection, `focusin`; polite announcement; the new setting); §8.30.2 rows 03 and 04 gain "Continue automatically after a recap" (`ON · OFF`, default `ON`, per profile) |
| A11Y-35 | §9.3.4 recipients caption dropped; eligible recipients listed without explanation |
| A11Y-37 | §14.1 What does not change (leader dial, indeterminate rule, button loading segment keep running); §4.8 new Progress indicators row |
| A11Y-38 | §7.11 Accessibility row (`Alt+T` keyboard route, sonner default hotkey, Flutter `Shortcuts`); §8.0.6 Global web keys; §8.33.2 keyboard sheet and §8.30.2 row 12 General group |
| A11Y-39 | §8.15.2 Speaker tints (hover tooltip on the web, long-press popover on phones, inline name for screen readers); §8.15.8 Gestures; §14.3 |
| A11Y-40 | §3.3 caps table (`kicker`, `credit`, `credit.label` rise to 2.0; `nav` and `micro` keep 1.5) and the Archivo literal note; §3.5 `typeKicker`, `typeCredit`, `typeCreditLabel` `cap: 2.0`; §15.1 kicker `scaleCap` 2.0 |
| A11Y-41 | §7.25 avatar glyph "≥ 3:1, non-text; 3.06 minimum on Marquee"; §2.1.1 `rule.1` 1.46:1, `rule.2` 1.9:1; §2.1.2 spot 13.9:1 (table and prose); §2.1.3 `note` 13.9:1 and bone on spot 1.3:1; §14.2 13.9:1; §8.16.5 voice monogram field (HLS L 0.28, S 0.45, hue 220° → 30° over 80–300 Hz, 5.13:1 worst case); §2.1.1 loop gains the avatar fields and monogram endpoints |

Coverage appendix: no screen was added or removed, so Appendix B is unchanged.

## Round 2

Source: `cinematic/verify/recheck-a11y-1.md`, which found 31 of the 34 confirmed findings resolved and 3 unresolved. This round fixes those 3 and four recheck observations that reintroduced a defect a confirmed finding had closed. The other 31 findings were left as round 1 applied them.

| ID | Sections changed |
|---|---|
| A11Y-18 | §8.8 implementation paragraph (Flutter half): "The strip's controls enter the tab order only when `p` = 1" replaced with the rule from "Focus during the scrub" and §14.4 (strip in the tab order at `p` ≥ 0.8, text column inert at `p` ≥ 0.55 via `ExcludeFocus` + `ExcludeSemantics`) |
| A11Y-10 | §10.1.5 web `useWordsFit` now reads `ref.current` inside `check()` and observes the parent captured at mount, so the `ResizeObserver` re-check keeps working after `SetHeading` swaps `<M>` for `<Tag>` at `"done"` (comment explains why). Also, from the recheck observations: §10.1.6 Flutter long-word fallback uses `_c.drive(CurveTween(…))` instead of a `CurvedAnimation` built on every build, which left an undisposed status listener on `_c`; the fifth test case asserts no overflow only, because whether "Transmigration" fits 358 px depends on the loaded font, and a new sixth case pumps it in a 160 px column and asserts the plain-string fallback rendered |
| A11Y-3 | §2.1.4 over-art rule: `ink.30` never over art, `ink.45` only on a solid ground; the solid-ground paragraph names badge fills (§7.19) as solid grounds, where the ± 8 px margin is the box's own padding and `ink.45` is allowed (4.70:1, the `TEXT` poster badge); §14.2 Over art bullet says the same |
| A11Y-6 (regression) | §8.23 "Web activity and removal": `REMOVING…` in `ink.45` instead of `ink.30` |
| A11Y-1 (regression) | §9.2.4 Annual story: the focus-revealed page buttons are `on-art` buttons (`ink.100` on `color.onart`, which meets the 0.60 minimum) instead of `quiet` buttons (`ink.60`, which needs 0.82) |
| A11Y-15 (extension) | §7.5 Count row: the raised-digit drawing and `folioLabel()` spoken form apply to every superscript count in the document (`CHAPTERS²⁰¹`, `Filters ⁽²⁾`, `FEMALE ¹⁸`, `PINNED⁶`, `Show queue ⁽⁸⁾`) |
| A11Y-20 (consistency) | §7.16 drag-to-reorder list gains collection members and points to the §7.22 Move items |

No token, motion, haptic or sound value changed. Coverage appendix: no screen was added or removed, so Appendix B is unchanged.

## Round 3

Source: `cinematic/verify/recheck-a11y-2.md`, which found 31 of the 34 confirmed findings resolved and 3 unresolved (A11Y-1, A11Y-3, A11Y-33). This round fixes those 3 and the recheck's two observations that fall under confirmed findings (text on duotone with no named ground, A11Y-1; an information segment in `ink.30`, A11Y-6). The other 31 findings were left as rounds 1 and 2 applied them.

| ID | Sections changed |
|---|---|
| A11Y-3 | §2.1.1 "`ink.45` lives on black only": "and `ink.45` is never used there" replaced with "and `ink.45` is used there only on a solid ground (a badge's `#000000` fill, the rating card's `paper.0` box)", matching §2.1.4, §7.19 and §14.2 |
| A11Y-1 | §9.1.5 `Skip recap →` is an `on-art` button (it sits on the cover band above the part `scrim.foot.black` covers); §9.2.4 The Annual's phone close `x` is the `on-art` icon button (no scrim at the top edge); §2.1.4 `scrim.foot.black` row (the band's one control brings its own ground) and a new solid-ground sentence for `on-art` controls where no scrim reaches (`color.onart` 0.64 under `ink.100`: 5.89:1 over `#FFFFFF`, 6.51:1 over `#F5F547`, recomputed); §7.1 `on-art` usage column; §14.2 Over art bullet; §15.7 over-art rows gain the `on-art` controls (Skip recap, Annual close `x` and page buttons) |
| A11Y-1 (observation) | §7.8 preview slate: the title sits on the solid end colour of a `scrim.foot` over the duotone backdrop; §8.7 onboarding format tiles: the Bodoni word sits on the tile's `scrim.foot` solid end colour; §2.1.4 `scrim.foot` Where column lists both (so both fall under the §15.7 "every `scrim.foot` text block" row) |
| A11Y-6 (observation) | §7.18 storage meter: the other-apps segment is `ink.60` instead of `ink.30` (it carries information) |
| A11Y-33 | §9.1.5 Auto-continue countdown: the web pause trigger is "any `keydown` other than `Space`, `Enter`, `s` and `Esc` (which keep their own actions: `Space` pauses or resumes, `Enter` continues, `s` skips the recap, `Esc` closes)". `s` was added to the judge's three because the §9.1.5 Keys line also assigns it |

No token, motion, haptic or sound value changed. Coverage appendix: no screen was added or removed, so Appendix B is unchanged. Not changed: The Annual's 2 px story segments at the top of the phone frame also sit on bleeding art with no scrim; no finding covers them, so they are left for the next recheck to judge.

## Round 4 (main session)

- A11Y-1: §2.1.4 now puts every floating chip, HUD value, flag and caption over art on the folio-flag ground and makes icon buttons over art `on-art`; applied to the World card dismiss and More-like-this buttons (§7.6, §9.1.3), the Lightbox chrome, zoom chip and +/−/Fit buttons (§7.30), the reader zoom chip and HUDs (§8.14.5), the new-chapter caption (§8.14.6), the guided-view whole-page folios (§9.4.3), and listed them in the §15.7 over-art check.
