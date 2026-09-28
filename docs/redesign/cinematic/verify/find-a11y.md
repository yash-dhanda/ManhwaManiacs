# Cinematic DESIGN.md — adversarial audit: accessibility, privacy and safety

Scope: `docs/redesign/cinematic/DESIGN.md` (final contract, critic pass applied), checked against `inventory/00-decisions.md` and `inventory/capabilities.md`. Lens: WCAG 2.2 contrast of every text/icon token pair the doc uses, hit targets (44 pt / 48 dp), reduced motion for every named move, reduced transparency, screen-reader semantics and focus order, text scale to 200 % without clipping, and 18+ gate / per-profile isolation leaks. Every item was grepped across the whole file before being reported as missing.

Contrast method: WCAG 2.x relative luminance, alpha composited in sRGB. Over-art cases use the worst case a real page or cover produces: `#FFFFFF`, and the brightest possible `ambient.duo` (`#F5F547`, hue 60°, L 0.62, S 0.90).

## Contrast table (flat grounds, computed)

| Ink | paper.0 | paper.1 | paper.2 | paper.3 | paper.4 | worst mood grade |
|---|---|---|---|---|---|---|
| ink.30 `#4D4B47` | 2.41 | 2.26 | 2.15 | 2.00 | 1.83 | 2.13 |
| ink.45 `#7A7770` | 4.70 | 4.41 | 4.20 | 3.90 | 3.56 | 4.14 |
| ink.60 `#9A978F` | 7.20 | 6.75 | 6.42 | 5.97 | 5.45 | 6.35 |
| ink.80 `#C9C6BE` | 12.30 | 11.54 | 10.98 | 10.21 | 9.31 | — |
| ink.100 `#F3F0E8` | 18.44 | 17.29 | 16.46 | 15.30 | 13.96 | — |
| spot `#F4D03F` | 13.94 | 13.07 | 12.44 | 11.57 | 10.55 | 12.29 |
| proof `#FF5B4A` | 6.85 | 6.42 | 6.11 | 5.68 | 5.18 | 6.04 |
| set `#57D68D` | 11.41 | 10.70 | 10.18 | 9.47 | 8.64 | 10.06 |
| info `#9CC8FF` | 12.12 | 11.36 | 10.82 | 10.06 | 9.17 | 10.69 |
| rule.2 `#3D3C38` (non-text) | 1.90 | 1.78 | 1.70 | 1.58 | 1.44 | 1.68 |

Flat-ground results that pass: every `ink.60`+ text, every semantic colour, black on spot (13.94), black on proof (6.85), all six paper stocks (ink ≥ 13.42, muted ≥ 5.84), speaker-tint backgrounds under stock ink (≥ 10.26), dialogue-search subtitle band. Failures are on non-paper.0 grounds that keep `ink.45`, on wash bands, and above all over art (below).

## Findings

### A11Y-1 · high

**Section.** §2.1.4 Scrims; §8.14.3 reader chrome; §8.8 Tonight phone hero; §8.17 feature phone hero; §8.20 genre tiles; §7.6/§8.11 collection plates and header; §8.8 Sources tiles; §8.14.6 Coming up card; §7.24 rating card; §9.1.5 recap band; §9.2.4 Annual pages; §14.2; §15.7

**Problem.** Text and icons laid over art (covers, manga pages, duotone fields) have no contrast guarantee. Every contrast rule in the contract (§2.1.1 surface × ink loop, §14.2, §15.7) covers flat grounds only, and the scrims that sit under text are too thin where the text actually is. On a white manga page or a bright cover, the reader's running-head title, chapter folio and every chrome glyph, the folio bar's time-left caption, and the kicker and headline of every phone hero fail WCAG 1.4.3 and 1.4.11 by a wide margin. The same holds for genre tiles, collection plates and the collection header, Sources tiles, the Coming up card, the rating card, the recap's duotone band and the Annual pages, where text sits on duotone art whose highlight colour can be as bright as #F5F547 (ambient.duo at hue 60°, L 0.62, S 0.90).

**Evidence.** §2.1.4: "`scrim.head` | Top 120 px (desktop) / safe area + 88 px (phone) | `#000` .86 at 0 %, .52 at 45 %, 0 at 100 %" and "`scrim.sole` ... `#000` .90 at 0 %, .60 at 40 %, 0 at 100 %". §8.14.3: "Title: series title in `type.nav` `ink.60` + ` · ` + `CH 142` in `type.folio` `spot`", "`6 MIN LEFT` (`type.caption` `ink.45`...)". §8.8 phone: "Over its lower third: kicker, typed headline in `type.cover` (44/44, up to 3 lines), deck (2 lines)" over "`scrim.foot` into `ambient.tint`". §8.20: "the genre in `type.subhead` italic over `scrim.foot`". §8.14.6: "a 16:9 panel of the next chapter's first page blurred 24 px and duotoned ... kicker `COMING UP`; headline `Chapter 143`". §7.24 rating card: "top-left under the running head ... `type.caption` `ink.60`" with no ground. Computed (WCAG 2.x, white page or cover underneath): phone reader running head at the title row (safe area 59 pt) the scrim is alpha 0.42, so ink.60 = 1.05:1, spot folio = 2.04:1, ink.100 = 2.70:1, glyphs (ink.60) 1.05:1; with a 47 pt inset alpha 0.46: ink.60 1.20:1. Desktop reader head at 28 px: alpha 0.68, ink.60 2.72:1. Folio bar caption rows: alpha 0.52–0.64, ink.45 1.06–1.52:1. Phone Tonight hero (390 × 487, scrim over the bottom 292 px): kicker 200 px above the bottom sits on alpha 0.16 (ink.100 1.29:1), headline middle at 150 px on alpha 0.33 (ink.100 2.04:1, large text needs 3:1). Text straight on the brightest duo: ink.100 1.02:1, ink.60 2.51:1.

**Fix.** Add a rule to §2.1.4 and §14.2: every text run and icon drawn over art sits on black of at least this alpha across its line box ± 8 px (values measured against #FFFFFF, the worst case): ink.100 0.60, ink.80 0.68, spot 0.66, set 0.70, ink.60 0.82, proof 0.84; ink.45 and ink.30 are never used over art (use ink.60). Retune the tokens: `scrim.head` = `#000` 0.88 flat from 0 to the bar's bottom edge (phone: safe area + 44; desktop: 56 px), then the 13 eased stops reversed to 0 over the next 44 px (phone) / 64 px (desktop); `scrim.sole` = `#000` 0.90 flat from the bottom edge through the bar's top edge (64 px + inset), then eased to 0 over 64 px (at 0.88 over white: ink.60 5.65:1, spot 10.94:1, ink.100 14.47:1). The folio bar's time-left caption becomes ink.60. `scrim.foot` (phone heroes, genre tiles, Sources tiles, collection plates and header, recap band, Annual pages) reaches alpha 1 of its end colour 24 px above the top of the text block's first line box, so the whole text block sits on the solid end colour (ink.60 ≥ 6.35:1 on any ambient.tint); implementations measure the text block and place the ramp above it. The Coming up card and the rating card put their text on a `#000000` 0.84 band (rating card: a paper.0 box, 8 × 12 px padding). Add to §15.7 a test per client that renders each over-art component on a #FFFFFF fixture and a #F5F547 fixture and asserts sampled text contrast ≥ 4.5:1 (≥ 3:1 for type ≥ 24 px regular or ≥ 18.66 px at wght ≥ 700, and for icons).

### A11Y-2 · high

**Section.** §8.16.3 Full player ("The reading room"); §2.5 blur.card

**Problem.** The Listen full player's transcript fails contrast everywhere: inactive sentences are bone at 35 % opacity, which is 2.77:1 even on pure black, and the background is a duotone cover copy at 50 % over black, which puts the active sentence, the head and the speaker-name kickers below 4.5:1 on bright covers. This is the screen a Listen user stares at for the whole chapter.

**Evidence.** §8.16.3: "Background | The series cover duotoned to `ambient.duo`, `blur.card`, at 50 % over `#000`"; "The active sentence is `ink.100` on a **highlighter** band (`spot.wash`) ... other sentences at 35 %"; "dialogue sentences carry a small kicker above them with the speaker's name in their tint colour". Computed with the brightest duo (#F5F547) at 50 % over black = (122,122,36): active ink.100 on spot.wash 3.23:1; inactive sentence (ink.100 at 35 %) 1.73:1; ink.60 1.55:1; ink.100 at 35 % on pure #000 2.77:1.

**Fix.** Background: the duotone copy at 15 % over #000000 (not 50 %), keeping `scrim.vignette` and grain. Inactive sentences: `ink.60` at full opacity (5.34:1 on the 15 % field, 7.20:1 on black); active sentence `ink.100` on `spot.wash` (9.21:1). Speaker-name kickers keep their tint (≥ 6.22:1 on an 18 % field, ≥ 9.17:1 on black). Head kicker `NOW READING ALOUD` in ink.60. Add the full player to the over-art test of A11Y-1.

### A11Y-3 · high

**Section.** §7.19 Badges; §7.7 Posters; §7.6 Cutting nudge badges; §7.13 OFFLINE EDITION badge

**Problem.** Badges that sit on cover art have no ground: only `NEW`, `NOW`, count badges and `YOU` are filled. Status, reading-status, `SAVED`, `TEXT`, `SAVED COPY`, `PICKED`, the 18+ certificate and the running head's `OFFLINE EDITION` micro badge are outline-plus-text on whatever the art is, so their 10–11 px text becomes unreadable on light covers. The 18+ certificate is the one badge the owner decisions require to be legible.

**Evidence.** §7.7: "Badges sit top-left in a 4 px inset stack (§7.19): `NEW`/`3 NEW`, status, `18` certificate ..., `SAVED`, `TEXT` (dialogue indexed)." §7.19: "Status ... | 1 px `ink.45` outline, text `ink.60`", "Reading status ... 1 px `ink.100` outline, text `ink.100`", "18+ certificate | ... 1 px `proof` outline and `18` in `proof`", "`SAVED` | 1 px `set` outline, text `set`". §7.13: "a micro badge `OFFLINE EDITION` in a 1 px `ink.45` box" over a running head that is "Transparent over the masthead or art". Computed on a white cover: ink.100 1.14:1, spot 1.51:1, set 1.84:1, ink.60 2.92:1, proof 3.07:1; on the brightest duo: ink.100 1.02:1.

**Fix.** §7.19: every badge that can sit on art (all poster, cutting and running-head badges) gets a `#000000` fill under its outline. Resulting text contrast: ink.100 18.44, spot 13.94, set 11.41, ink.60 7.20, proof 6.85, ink.45 4.70 (all on #000). The 18+ certificate on art: `#000` square, 1 px proof outline, `18` in proof. Keep the 4 px stack gap.

### A11Y-4 · high

**Section.** §8.21 Sources; §7.7 Posters (Disabled state); §8.20 Discover idle page; §8.8 Tonight `sources` section

**Problem.** A pinned 18+ source that the gate now hides is drawn as a greyed row labelled `UNAVAILABLE ON THIS PROFILE`. That is exactly the "locked row" the gate forbids: it names the mature source and tells a gated profile that something is hidden. The consumers of the pin list (Discover's `02 Sources`, genre tiles, `04 Trending on your sources`, the tier-1 search status line, Tonight's `Sources` section, the `PINNED⁶` count) do not say that mature pins are dropped either.

**Evidence.** §8.21: "Unavailable pinned sources (pinned but no longer visible on this profile) show at 40 % with `UNAVAILABLE ON THIS PROFILE` and cannot be opened." §7.7: "Disabled (unavailable source, pinned source missing) | 40 % opacity, caption `UNAVAILABLE`". capabilities.md §16.1: `GET /sources/pins` returns `[{source_id, sort_order, name, icon_url, mature, available}]`; capabilities.md §1: "The redesign must never draw a 'hidden: 18+' placeholder, a blurred tile, or a count that implies hidden rows." §7.24: "Absence, never a lock ... no locked rows."

**Fix.** §8.21 and §7.7: a pin whose `mature` is true while the active profile's gate is closed is dropped from every list and count (Sources pinned section, `PINNED` count, Discover `02 Sources`, genre-tile union, `04 Trending`, the search status line's "N pinned sources", Tonight `sources`, the sidebar/command palette `SOURCES` group); it reappears when the gate opens. Keep the 40 % `UNAVAILABLE` row only for a non-mature pin whose connector was removed, labelled `REMOVED FROM THIS SERVER` (never "on this profile"). Add a case to the §15.7 "18+ on the device" check: pin an 18+ source, close the gate, confirm no row, count or tile names it.

### A11Y-5 · high

**Section.** §7.4 Search fields (`index` variant); §8.20 Discover; §8.24 Dialogue; §8.33.1 Command palette; §9.1.3 Picks ask field; §14.2

**Problem.** The big index field has no visible label and its only identification is a placeholder set in `ink.30` (2.41:1 on paper.0, 2.15:1 on the command palette's paper.2), which the contract itself reserves for disabled, non-informational text. On Discover and Dialogue the field replaces the page title, so once focused (placeholder gone) nothing on screen says what it searches. No accessible name is specified for it on either client.

**Evidence.** §7.4: "`index` (big) | `type.field` ... placeholder in `ink.30` typed at 50 ms per character when empty and unfocused". §2.1.1: "`color.ink.30` | `#4D4B47` | 2.4:1 | Disabled text and glyphs only, never information"; "`ink.45` ... placeholders in large type". §14.2: "no control relies on them alone (inputs are identified by their visible kicker label)" — the index variant has no kicker label part. §8.20: "then instead of a title the **index field**". §8.24: "the index field with the typed placeholder 'Search what a character said'".

**Fix.** §7.4 `index`: placeholder in `ink.45` (4.70:1 on paper.0; renders ink.60 inside raised stock, 6.42:1 on paper.2); add a visible label part: a `type.kicker` line 8 px above the field (`SEARCH EVERY SOURCE`, `SEARCH WHAT THEY SAID`, `SEARCH OR JUMP`, `ASK THE EDITORS`) that stays visible when focused, wired as `<label for>` (web) and `InputDecoration(labelText)` or `Semantics(textField: true, label: …)` (Flutter). The typed placeholder is a visual layer only (`aria-hidden`), the real `placeholder`/`hintText` holds the same string.

### A11Y-6 · medium

**Section.** §7.7 Posters (Ranked); §8.7 Onboarding genre paragraph; §8.32 404; §7.7 and §8.24 image-broken glyph; §2.1.1

**Problem.** `ink.30` (2.41:1 on paper.0, 2.26:1 on paper.1) carries information in several places despite the rule that it never does: the Top-ten rank numerals, the skipped state of a genre word (an active control, not a disabled one), the 404 folio numeral, and the `image-broken` glyph that says a cover failed. Large text needs 3:1 and state glyphs need 3:1.

**Evidence.** §7.7: "**Ranked** (Top ten): a Bodoni Moda Roman numeral in `ink.30`". §8.7: "Hold 450 ms: 1 px `proof` strike-through + `ink.30` (skip)." §8.32: "A folio numeral `p. 404` ... in `ink.30`". §7.7: "a 16 px `image-broken` Regular glyph `ink.30` bottom-right". §2.1.1: "Disabled text and glyphs only, never information"; §14.2: "`ink.30` (2.4:1) never carries information."

**Fix.** Ranked numerals: `ink.45` (4.70:1; large text passes 3:1 on paper.0 and on paper.1 at 4.41). Skipped genre: `ink.45` with the 1 px proof strike-through, and its state in the accessible name ("Romance, skipped"). 404 numeral: `ink.45` or mark it decorative (`aria-hidden`, `ExcludeSemantics`) since the headline says the same. `image-broken` glyph: `ink.45` (4.41:1 on paper.1) plus the accessible label "Cover didn't load".

### A11Y-7 · medium

**Section.** §2.1.1 raised-stock rule; §8.14.5 chapter seam; §7.16 Current row; §8.30.4 destructive area; §8.30.5 own member row; §7.29 select-mode bar; §8.15.3 margins panel; §9.3.3 spoiler caption

**Problem.** The implementation list of surfaces that switch `ink.45` to `ink.60` is incomplete, so several grounds keep `ink.45` below 4.5:1: the manga reader's Ink and Slate grounds (chapter seam kicker, read-all divider, top band), `spot.wash` bands (current chapter and TOC rows), `proof.wash` destructive areas and error rows, the member table's own row (paper.4), the select-mode bar (paper.2) and the novel reader's margins panel painted in stock colours ("reacted to Ch. 212" in `ink.45`). Inside `spot.wash` on paper.3 even `ink.60` fails.

**Evidence.** §2.1.1: "the web sets `[data-stock=\"raised\"]` ... on the root of every sheet, menu, popover, command palette, dialog, plate, selected or pressed row, masthead grade band and spread" — reader grounds, wash bands, paper.4 own row, the select-mode bar and stock-painted panels are not in it. §8.14.5: "`CH 143 · THE RETURN` in `type.kicker` `ink.45`" on the chosen ground (Ink #0B0B0A, Slate #1A1A18). §8.15.3: "the Circle panel with the spoiler guard" in stock colours; §9.3.3: "'reacted to Ch. 212' (`type.caption` `ink.45`)". Computed: ink.45 on Ink ground 4.41, Slate 3.90; on spot.wash over #000 3.59, over paper.2 2.95; on proof.wash over #000 4.23, over paper.3 3.36; on paper.4 3.56; on stock pages 4.20–4.40. ink.60 on spot.wash over paper.3 4.08.

**Fix.** Replace the enumerated list with a structural rule: every primitive that paints a background other than paper.0 applies the raised scope (web `data-stock="raised"`, Flutter `CineStock.raised`), explicitly including the reader canvas when its ground is Ink or Slate, the select-mode bar, own/tinted table rows, `proof.wash` areas and rows. Inside any `spot.wash` band, `ink.45` and `ink.60` roles render `ink.80` (9.41:1 on wash over #000, 6.98:1 over paper.3). In stock-painted panels (novel margins, stop-press in stock, toasts in stock) `ink.45` roles render the stock's `muted` (≥ 5.84:1). Extend the §2.1.5 surface × ink loop to: ground.ink, ground.slate, spot.wash over paper.0–paper.3, proof.wash over paper.0–paper.3, and the six stock pages.

### A11Y-8 · medium

**Section.** §10.2.3 TypedHeadline; §10.2.2 where typing plays; §14.5 headings; §8.20 Discover; §8.24 Dialogue

**Problem.** The web `TypedHeadline` always renders an `<h1>`, but the typing reveal is used for notice headlines inside pages that already have an h1, numerals, placeholders, reader captions, the Listen card title, loading lines, tips and chapter folios. Following the code gives many h1s per page and headings made of placeholders and numbers, breaking the "one h1 per page" rule and screen-reader heading navigation. Discover and Dialogue have no visible title, so the route-change focus target (the page h1) is undefined there.

**Evidence.** §10.2.3: `<h1 aria-label={text} className={className} onClick={skip} tabIndex={done ? -1 : 0}`. §10.2.2 lists: "Notice headlines (every empty, error, offline and caution state)", "The Numbers' and The Annual's key numerals", "The index field placeholders", "New chapter folios on Updates", "Source catalogue loading tips". §14.5: "each page has one `h1` (its masthead)". §14.4: "focus moves to the new page's `h1`". §8.20: "instead of a title the **index field**".

**Fix.** `TypedHeadline` takes `as: 'h1' | 'h2' | 'h3' | 'p' | 'span'` (default `p`); only Tonight's cover headline, the picker question, Login/Register/Setup headlines, onboarding step headlines, the 404 headline and System status's summary use `h1`; notice headlines use `h2`; numerals, folios, tips, captions and placeholders use `span`/`p`. The Flutter version takes the same level (see A11Y-9). Discover and Dialogue render a visually hidden `<h1>Discover</h1>` / `<h1>Dialogue search</h1>` (web `sr-only` class; Flutter `Semantics(header: true, label: …)` with zero size) as the route focus target.

### A11Y-9 · medium

**Section.** §10.1.6 Flutter SetHeading; §10.2.4 Flutter TypedHeadline; §14.4

**Problem.** The Flutter heading widgets expose no heading semantics: `SetHeading` wraps its text in `Semantics(label:, excludeSemantics: true)` with no `header` flag, and the reduced-motion branch is a bare `FadeTransition(Text)`. VoiceOver's headings rotor and TalkBack's heading navigation will find nothing on any screen, and the §14.4 route-focus rule points at a `Semantics(header: true)` that the given code never creates.

**Evidence.** §10.1.6: `if (_seenAtMount) return Semantics(label: widget.text, excludeSemantics: true, child: whole);` and `return Semantics(label: widget.text, excludeSemantics: true, child: Wrap(...))`; `if (_reduced) return FadeTransition(opacity: _c, child: whole);`. §10.2.4: "`Semantics(label: text, excludeSemantics: true)`". §14.4: "in Flutter a `FocusNode` on the masthead's `Semantics(header: true)`". The web version passes `as="h1"|"h2"|"h3"`.

**Fix.** Add `final int level` (1–3) to both widgets and wrap every branch (seen, reduced, animating) in `Semantics(header: true, headingLevel: level, label: text, excludeSemantics: true, child: …)` (`headingLevel` exists on `Semantics` in the pinned Flutter 3.44.6; it drives `<h1>`–`<h3>` on Flutter web and is ignored on iOS/Android, where `header: true` is what VoiceOver and TalkBack read). Masthead = level 1, `type.section` heads = 2, subsections = 3. Extend `set_heading_test.dart` with `expect(tester.getSemantics(find.byType(SetHeading)), matchesSemantics(isHeader: true, label: 'Library'))`.

### A11Y-10 · medium

**Section.** §10.1.5 and §10.1.6 SetHeading; §3.3 text scale caps; §14.7

**Problem.** The per-letter reveal groups each word in a non-wrapping box (web `inline-block whitespace-nowrap`, Flutter `Row(mainAxisSize: min)`), so a word wider than the line can never break and overflows (clipped in release Flutter, horizontal scroll on web). The Flutter code also builds every letter with `Text(ch, style: s)`, which uses the unclamped system text scaler, so the §3.3 caps (display 1.15, section 1.30) are not applied: at 2.0 a 44 px cover title renders at 88 px and a 10-letter word is about 480 px wide on a 390 px phone. On the web the same happens at 320 CSS px reflow (WCAG 1.4.10) for long title words.

**Evidence.** §10.1.5: `<span key={wi} aria-hidden className="inline-block whitespace-nowrap">`. §10.1.6: `Row(mainAxisSize: MainAxisSize.min, children: [ for (final ch in words[w].characters) letter(ch), …])`, `return AnimatedBuilder(... child: Text(ch, style: s) ...)`, `final whole = Text(widget.text, style: s);` with no `textScaler`. §3.3: "Each role clamps it with `TextScaler.clamp(maxScaleFactor: cap)`".

**Fix.** Flutter: pass `textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: widget.role.cap)` to the whole `Text` and every letter `Text`, and compute `rise` from the scaled size. Both clients: before revealing, measure each word at the resolved size (Flutter `TextPainter`, web a hidden measuring span or `ResizeObserver` on the container); if any word is wider than the available width, render the plain whole string (normal wrapping, `overflow-wrap: anywhere` on web, `softWrap: true` in Flutter) with the reduced-motion 200 ms fade instead of the letter reveal. Add a test case: "Transmigration" in `type.cover` at text scale 2.0 in a 390 px column must not overflow.

### A11Y-11 · medium

**Section.** §7.19 Badges; §7.11 Toasts; §8.14.3 folio bar; §7.1 Buttons; §7.3 Inputs; §7.22 Menus; §7.9 Sheet header; §8.16.2–§8.16.3 Listen; §3.3 reflow

**Problem.** Several containers have fixed heights that clip at text scale 2.0 (and under WCAG 1.4.12 text-spacing overrides on the web), and the toast truncates its message: the §3.3 reflow list covers rows, split buttons, the tab bar and one folio-bar caption but not these. A clipped badge or a cut toast loses information (toasts like "You're further ahead on another device (CH 145, p.3). Jump there?" exceed two lines at 2.0).

**Evidence.** §7.19: "Square boxes, height 16" with `type.micro` 10/12 capped at 1.5 → 15/18. §7.11: "`type.ui` 15 `ink.100`, 2 lines max". §8.14.3: "**Folio bar** (bottom, over `scrim.sole`; 64 px + bottom inset)" holding `type.folio.lg` (2.0 → 30/40) plus a caption line. §7.1: "md 44 (desktop) / 48 (phone); lg 56". §7.3: "Height | 48" plus a kicker label above. §7.22: "Item | 40 px (48 phone)". §7.9: "Header | 56 px". §8.16.3: "Three square outlined tiles (1 px `rule.2`, 88 px tall)". §8.16.2: "A 56 px bar".

**Fix.** State in §7 that every listed height is a minimum (web `min-height`, Flutter `ConstrainedBox(minHeight: …)` with intrinsic growth): badges `min-height: 16px; padding-block: 2px`; buttons min 44/48/56 and the label may wrap to 2 lines at scale ≥ 1.5; inputs min 48; menu items min 40/48; sheet header min 56; Listen tiles min 88; mini player min 56; folio bar min 64 + inset, growing to two rows at scale ≥ 1.5 (≈ 96 px at 2.0). Toasts wrap to as many as 6 lines at any text scale (never truncated below that); a longer message shows its first 6 lines plus a `More` action that opens the full text in a sheet; the live region always announces the full string.

### A11Y-12 · medium

**Section.** §14 Accessibility (missing reduced-transparency rule); §2.1.4 scrims; §7.1 on-art; §8.16.3; §2.5 blur

**Problem.** There is no reduced-transparency behaviour at all. The skin has no backdrop blur, but it relies on translucency for legibility: scrims over art, `on-art` fills at 0.64, the dialogue-search subtitle band at 64 %, the Listen full player's duotone field, `blur.card`/`blur.bleed` copies behind text, grain over art and the modal barrier at 0.78. iOS Reduce Transparency and web `prefers-reduced-transparency` users get no opaque variant, and Flutter has no API for the iOS setting, so an implementer would have to guess both the signal and the result.

**Evidence.** grep of DESIGN.md: 0 hits for `prefers-reduced-transparency`, `Reduce Transparency`, `reduceTransparency`. §2.1.4 scrims (`scrim.modal` `rgba(0,0,0,0.78)`), §7.1 `on-art` "Fill `rgba(0,0,0,0.64)`", §8.24 "`#000000` band at 64 %", §8.16.3 "duotoned ... at 50 % over `#000`".

**Fix.** Add §14.12 Reduced transparency. Signal: web `@media (prefers-reduced-transparency: reduce)`; iOS `UIAccessibility.isReduceTransparencyEnabled` plus `reduceTransparencyStatusDidChangeNotification` read through a 20-line `MethodChannel('mm/a11y')` (checked: `AccessibilityFeatures` in the pinned Flutter 3.44.6 exposes `highContrast`, `boldText`, `reduceMotion`, `disableAnimations` but no reduce-transparency flag); Android has no OS setting; all platforms also get Settings → Appearance → "Reduce transparency" (`SYSTEM · ON`, per profile, stamped into `mm.boot.a11y` as `transparency`, web `html[data-transparency="reduced"]`). Effects: `scrim.head`/`scrim.sole` become solid `#000000` bands at the bar heights; `scrim.foot` becomes a solid end-colour band under the text block; `on-art` fills and the subtitle band `#000000` at 1.0; `scrim.modal` `#000000` at 0.94; the Listen full player and `blur.card`/`blur.bleed` fields become solid `ambient.tint`; grain off. `spot.wash` and `proof.wash` stay (they are tints on solid ground).

### A11Y-13 · medium

**Section.** §14.4 Forced colours and more contrast; §3.1 Delivery (Flutter font variations); §3.3

**Problem.** OS contrast and weight settings are honoured only on the web. Flutter ignores iOS Increase Contrast / Android high-contrast text (`MediaQuery.highContrastOf`) and iOS/Android Bold Text (`MediaQuery.boldTextOf`). Worse, the contract tells Flutter to set an explicit `FontVariation('wght', …)` on every role, which pins the variable weight axis, so the framework's automatic bolding under Bold Text (it merges `FontWeight.bold` into `Text` styles) has no visible effect on these variable fonts.

**Evidence.** §14.4: "**Forced colours and more contrast** (web). ... Under `@media (prefers-contrast: more)` the `ink.45` role renders `ink.80` and `rule.1` renders `rule.2`." §3.1: "set both `fontWeight` and `FontVariation('wght', …)`". grep: 0 hits for `highContrast`, `boldText`, `Bold Text`.

**Fix.** Flutter: when `MediaQuery.highContrastOf(context)` is true apply the same remap as web `prefers-contrast: more` (ink.45 → ink.80, rule.1 → rule.2) through `CineTokens.copyWith`. When `MediaQuery.boldTextOf(context)` is true, `CineType` adds 150 to every role's `wght` variation (clamped to the axis maximum: Bodoni Moda 900, Archivo 900, Newsreader 800, Atkinson Hyperlegible Next 800, Plex Mono uses the 600 static) and sets the matching `fontWeight`; the novel reader's own Bold text setting stacks on top, clamped to the same maxima. Add both to the §15.7 text-scale pass.

### A11Y-14 · medium

**Section.** §7 Component catalog (semantics of custom primitives); §7.5; §7.2; §7.21; §9.3.3; §7.18; §9.2.2

**Problem.** Roles and states are not specified for the custom controls, so screen readers cannot tell what they are or whether they are on. The web gets roles only where Base UI supplies them (Switch, Tabs, Checkbox, Radio, ToggleGroup, Slider); the Flutter primitives are hand-built and none has a semantics contract. Unspecified on both clients: the tri-state genre filter (neutral/include/exclude), slug-line filters, icon-button toggles (Follow, Favourite, Notify, Bookmark, Guided view, Auto-scroll), reaction stamps (one-of-five, with counts), download marks (seven states conveyed by shape), the storage meter, progress rules, the streak flame (tier and state), the week dots, badges and the running head's two-target title. Only the Sources pin toggle carries `aria-pressed`.

**Evidence.** grep: `aria-pressed` 1 hit (§8.21 pin only); 0 hits for `aria-checked`, `aria-selected`, `aria-expanded`, `role="switch"`, `tablist`, `Semantics(selected`. §7.21 switch and checkbox are custom drawn ("a `#000` check drawn as a 2 px square-capped path (not an icon glyph)"); §7.5 tri-state: "tap cycles *neutral* ... → *include* ... → *exclude*"; §9.3.3 stamps: "pressing another moves it; pressing the same one removes it"; §7.18 download mark states by shape only plus a tooltip.

**Fix.** Add a semantics column to each §7 table. Minimum contract: switch → web Base UI Switch / Flutter `Semantics(toggled: v, label: row label)`; checkbox → `Semantics(checked: v)` (tristate for indeterminate); radio and single-select slug lines/segmented → `role="radiogroup"`/`radio` + `aria-checked`, Flutter `Semantics(inMutuallyExclusiveGroup: true, checked: v)`; multi-select slug lines and icon toggles → `aria-pressed`, Flutter `Semantics(toggled: v)` with a fixed label ("Favourite", not "Unfavourite"); tri-state filter → a button whose name includes the state ("Romance: included" / "excluded" / "not filtered") with a polite announcement on change; contents tabs → Base UI Tabs / Flutter `Semantics(selected: v)` inside a `TabBar`; reaction stamps → radio-like buttons "Loved, 3 reactions, selected" (guarded: "2 reactions, hidden until you finish the chapter"); download mark → label from the DP7 wording ("Saved", "Queued", "Downloading, 30 percent", "Failed, tap to retry"); storage meter → `role="meter"` with `aria-valuetext` ("4.1 of 10 gigabytes used"); progress rules → `role="progressbar"`; streak flame → `role="img"` label "12-day streak, read today" / "at risk"; week dots → one label "Read on Monday, Tuesday, Thursday".

### A11Y-15 · medium

**Section.** §7.5 counts; §7.12 counts; §7.6 Cutting; §7.16 rows; §9.3.2; §7.24 certificate; §12.5 voice

**Problem.** Abbreviated folios and superscript counts have no spoken form, and the contract writes counts with Unicode superscript digits, so implementers will render `READING¹²` literally. Screen readers read these as letters and symbols ("C H 142 dot 63 percent", "2 H", "paused 21 D", "reading superscript one superscript two"), and the 18+ certificate reads as "18".

**Evidence.** §7.5: "Superscript folio ... after the label: `READING¹²`". §7.12: "`CHAPTERS²⁰¹`". §9.3.2: "`LETTERS ²`", "time folio `2 H`". §7.6: "`CH 142 · 63%`", "`PAUSED 21 D`". §8.16.8: "`ALL UN-NARRATED ⁽³⁸⁾`". §7.16: "'3 D AGO'". §7.24 mark: "`18` set in Bodoni Moda".

**Fix.** Counts are ordinary digits positioned with CSS `font-variant-position: super` or `vertical-align: 0.5em; font-size: 0.72em` (Flutter: a `WidgetSpan` with `Transform.translate(Offset(0, -0.35em))`), never Unicode superscripts. One `folioLabel()` helper per client (`frontend/src/skins/cinematic/a11y/folio.ts`, `mobile/lib/skins/cinematic/a11y/folio.dart`) turns every folio into its spoken form, applied as `aria-label` / `Semantics(label:)` with the visual text `aria-hidden`: `CH 142 · 63%` → "Chapter 142, 63 percent read"; `2 H` → "2 hours ago"; `PAUSED 21 D` → "Paused 21 days"; `READING¹²` → "Reading, 12"; `p.12` → "page 12"; `12 MIN` → "12 minutes". The certificate's label is "Mature, 18 plus".

### A11Y-16 · medium

**Section.** §8.14.3 auto-hide; §7.30 Lightbox chrome; §8.16.2 mini player; §14.4; §14.5

**Problem.** Chrome hides on an idle timer even when keyboard focus is inside it. Because hidden chrome becomes `visibility: hidden` / `Offstage`, a keyboard user who tabs to a reader button or the Lightbox Close and pauses for 3 s loses focus to the document body. On the web the screen-reader exemption cannot work (no detection), so a VoiceOver/NVDA virtual cursor reading the running head also has it vanish under it.

**Evidence.** §8.14.3: "After a tap or hover opened the chrome, hide after 3000 ms idle (paused while a sheet, menu or the ruler is in use)"; "Hidden chrome is `visibility: hidden` / `Offstage` so it leaves the tab order." §7.30: "Chrome hides after 3000 ms idle and returns on tap or pointer move." §8.16.2: "lingers 5000 ms after the chrome hides". §14.5: "web: no reliable detection, so the web instead pauses every timer while focus is inside the timed element".

**Fix.** Add to §8.14.3, §8.15.3, §7.30 and §8.16.2: the idle timer does not run while `:focus-within` is true on the chrome (web) or any chrome `FocusNode` has focus (Flutter), nor for 10 s after any `keydown`; chrome opened by keyboard (`m`, any key, focus entering) stays until `m`/`Esc` or a pointer tap on the page. If chrome must hide while it holds focus (a scroll gesture), focus first moves to the reader canvas (`tabIndex={-1}` region labelled "Reader, Chapter 142"), never to the body.

### A11Y-17 · medium

**Section.** §7.8 Rails (Preview slate)

**Problem.** The desktop preview slate is a portal opened by `Space` on a focused poster, but its focus behaviour is not specified: nothing says whether focus enters it, how its `Read`, `+ Library` and `Details` buttons are reached, or where focus returns. As a portal outside the rail's DOM, its buttons are unreachable by Tab from the poster, so keyboard users cannot use it.

**Evidence.** §7.8: "Preview slate (desktop, dwell 600 ms or `Space` on a focused poster) | A portal overlay, not a layout push ... buttons `Read` (primary sm), `+ Library` (secondary sm), `Details` (quiet) ... `Esc` closes." and "`Space` toggles the slate". No focus rule in §7.8 or §14.4.

**Fix.** Keyboard-opened slate (`Space`): a non-modal `role="dialog"` labelled by its title (`aria-labelledby`), focus moves to `Read`; `Tab`/`Shift+Tab` cycle its three buttons; `Esc` or `Space` closes and returns focus to the poster; the poster carries `aria-expanded` and `aria-controls` pointing at the slate. Pointer-dwell slates never take focus. Flutter tablet/desktop with a hardware keyboard: the same with a `FocusScope` in the `OverlayEntry`.

### A11Y-18 · medium

**Section.** §8.8 Scrub the trailer

**Problem.** During the trailer scrub the spread's text column fades to opacity 0 at p = 0.55 but stays focusable, while the strip's controls join the tab order only at p = 1. Between p 0.55 and 1, and at p = 1 for anything still focused in the spread, keyboard focus sits on invisible `Continue`, `Previously on…` and `Details` buttons (WCAG 2.4.7, 2.4.11).

**Evidence.** §8.8: "The text column rises 12 px and fades out by `p` = 0.55."; "From `p` = 0.6 to 1 the **now-showing strip** fades in"; "The strip's controls enter the tab order only when `p` = 1."

**Fix.** At p ≥ 0.55 the spread's text column becomes `inert` (web) / `ExcludeFocus` + `ExcludeSemantics` (Flutter); the strip's controls join the tab order at p ≥ 0.6 (when they become visible). If focus was inside the text column when it goes inert, move it to the strip's `Continue`; scrolling back below p 0.55 reverses both. Under reduced motion, the same switch happens when the strip fades in.

### A11Y-19 · medium

**Section.** §7.3 Inputs (Password reveal) vs §8.3 Login

**Problem.** The password Show/Hide button is removed from the tab order in the component spec, which makes it unreachable for keyboard-only users, and it contradicts the Login screen's tab order, which includes it. An implementer has to guess.

**Evidence.** §7.3: "Password reveal | A `quiet` text button 'Show' / 'Hide' at the right end (words, not an eye); excluded from the tab order". §8.3: "`Tab` order username → password → Show → switch → Sign in → Create one." §8.30.4: "each with Show/Hide".

**Fix.** §7.3: the Show/Hide button stays in the tab order, directly after its field, with `aria-pressed` ("Show password", pressed when visible) and `aria-controls` the field; Flutter `Semantics(toggled: visible, label: 'Show password')`. Applies to Login, Register, Change password.

### A11Y-20 · medium

**Section.** §7.16 Drag to reorder; §11 Gesture matrix; §8.9, §8.11, §8.21, §8.6

**Problem.** Reordering (manual library order, pinned sources, collections, collection members, profiles) is available only by dragging or by `Alt+↑/↓`. WCAG 2.2 AA 2.5.7 (Dragging Movements) requires a single-pointer alternative that is not a drag; a keyboard shortcut does not satisfy it for touch users.

**Evidence.** §7.16: "Drag to reorder ... Keyboard: `Alt+↑/↓` moves the focused row". §11: "Drag handle / long-press then drag | ... | Non-gesture alternative | `Alt+↑/↓` (announced)". grep: 0 hits for "Move up".

**Fix.** Every reorderable row's and poster's menu (the trailing `dots-three`, Quick look, right-click) gains `Move up`, `Move down`, `Move to top`, `Move to bottom` (disabled at the ends); each move animates with the existing 240 ms `set` sibling shift, writes `sort_order`, and is announced ("Solo Leveling moved to position 3 of 12"). Update the §11 row's alternative column.

### A11Y-21 · medium

**Section.** §9.2.1 heatmap; §2.1.6 Chart palette; §9.2.3

**Problem.** The YEAR heatmap encodes reading volume only by the lightness of four heat levels whose contrast against black and against each other is far below 3:1, and the zero-day cell is not specified at all. A day with a little reading is indistinguishable from an empty day for most viewers (WCAG 1.4.11). Per-mark accessible labels help screen-reader users, not low-vision sighted users.

**Evidence.** §2.1.6: "heat levels (4) `rgba(243,240,232, .10 / .28 / .52 / .86)`". §9.2.1: "53 × 7 squares (10 px, 2 px gaps), 4 heat levels (§2.1.6), today outlined in `spot`". Computed: heat.1 vs #000 1.18:1; adjacent levels 1.80, 2.40, 2.62:1.

**Fix.** Encode the level by size as well as tone: each 10 px cell draws an `ink.100` square of 3, 5, 7 or 10 px (levels 1–4) centred in the cell (18.44:1 against black), and a zero day is a 10 px 1 px `rule.2` outline square. Keep the `heat.*` tokens for The Annual's decorative uses only. The legend under the heatmap shows the five cell forms with their chapter ranges ("0 · 1–2 · 3–5 · 6–10 · 11+").

### A11Y-22 · medium

**Section.** §2.4 Focus light; §7 focus rule; §7.1 on-art; §7.30; §9.2.4

**Problem.** The single focus ring (2 px bone at 2 px offset) has no separation from light art, so wherever a focusable control sits on art (on-art buttons on heroes and Annual pages, the phone running head over art, reader chrome over pages, the Lightbox chrome over a bright cover, posters in zero-gap walls) the ring measures about 1.1:1 against its surroundings and fails WCAG 1.4.11 for focus indication.

**Evidence.** §2.4: "Focus light | n/a | 2 px `ink.100` outline, 2 px offset | Keyboard focus on anything". §7.1: "`on-art` | Fill `rgba(0,0,0,0.64)` ... Buttons laid over covers (phone hero, Annual pages)". Computed: ink.100 vs #FFFFFF 1.14:1; vs a poster dimmed to `brightness(0.55)` 2.95:1.

**Fix.** Define the ring as a double ring everywhere: 2 px `ink.100` outline at 2 px offset plus a 2 px `#000000` halo outside it (web `outline: 2px solid var(--mm-color-ink-100); outline-offset: 2px; box-shadow: 0 0 0 6px #000` on the focus-visible element, or an absolutely positioned ring element; Flutter `CineFocusRing` paints the bone stroke then a black stroke 2 px further out). On black the halo is invisible, on art it guarantees ≥ 3:1 (bone vs black 18.44:1).

### A11Y-23 · medium

**Section.** §7 global hit-area rule; §7.1; §7.2; §7.5; §7.13; §7.20; §7.22; §8.14.3; §8.14.4; §9.1.5; §7.30

**Problem.** Component sizes contradict the global target rule and each other, so implementers must guess: the rule says 44 × 44 on web and 48 × 48 on Android, yet many parts hard-code 44 hits with no Android value, desktop parts are smaller than 44, the phone running head is only 44 tall (it cannot hold 48 dp targets), and slug-line labels 12 px apart cannot each have a 44 px-wide hit box without overlapping.

**Evidence.** §7: "**Hit area** ≥ 44 × 44 (iOS, web) and ≥ 48 × 48 (Android)". §7.2: "`on-art` | 40 px square ... | 44 hit", "`ruled` | 36 px square ... | 44 hit". §7.1: "sm 32 (desktop dense rows only)". §7.22: "Item | 40 px (48 phone)". §7.5: "Separator | `·` in `ink.30`, 12 px spacing either side"; "Removable ... height 28"; segmented "40 px tall". §7.13: "Height | 44 + status bar inset". §7.20: "44 × 44 hit area". §8.14.3: "its own 44 px hit area". §8.14.4: "the hit area is 44 px tall". §9.1.5: "44 hit". §7.30: "`x` bare icon button (`Close`, 44 hit)".

**Fix.** Rewrite the rule by input type: coarse pointer (touch, all phones and tablets, mobile web) 44 × 44 pt on iOS and mobile web, 48 × 48 dp on Android; fine pointer (desktop web, `@media (pointer: fine)`) 32 × 32 px minimum with ≥ 24 px spacing to the next target (WCAG 2.5.8), which legitimises menu items 40, `sm` 32, segmented 40 and filter tokens 28 (hit 32). Replace every hard-coded "44 hit" with "44 (48 Android) hit". Phone running head: 44 + inset on iOS and mobile web, 56 + inset on Android (Material top bar). Slug lines: each item's hit box is `max(label width + 24, 44)` × 44 (48 Android), and the separator gap becomes 8 px of non-interactive space between hit boxes (label-to-label 32 px, dot centred).

### A11Y-24 · high

**Section.** §7.24 Local copies; §7.13 Back online; §8.13; §8.19; §8.23; §8.8 offline edition

**Problem.** Local stores and outboxes are not scoped to the profile that wrote them. Rows carry only `mature: bool`; the progress and bookmark outboxes flush "when back online" with whatever profile is active then. If profile A reads offline and the device switches to profile B before the flush, A's progress and bookmarks are written into B's history (an isolation leak and data corruption). The offline Tonight/Library caches and the download index have no profile key either, which contradicts "Downloads belong to a reading profile" and "Saved for {profile}".

**Evidence.** §7.24: "Every locally stored row that names a series carries `mature: bool` ... mobile sqflite download rows (series and chapter), the offline bookmark store and outbox, the offline follow cache ..., the progress outbox, ... the cached payloads behind the offline editions of Tonight ..., Library and Downloads" — no profile id. §7.13: "when the progress and bookmark outboxes flush, a toast confirms 'Synced 12 reads and 2 bookmarks.'" §8.19: "Downloads belong to a reading profile." §8.23: "deck 'Saved for {profile}'". capabilities.md §1: "Writes to profile-owned data require it [`X-Profile-Id`]".

**Fix.** §7.24 gains a scoping rule: every local row (download index rows, bookmark store and outbox, progress outbox, follow cache, offline edition payloads, saved narration index, web service-worker download index) carries `(server_id, user_id, profile_id)`; outbox flushes send each row's own `X-Profile-Id` (never the active one) and flush on reconnect for every profile of the signed-in account; lists read `profile_id = active` first, then apply the mature filter. Content-addressed page blobs stay shared across profiles (bytes, not data), and the storage meter keeps the device total. Add to §15.7: read offline as profile A, switch to B, reconnect, and check B's History is unchanged and A's shows the reads.

### A11Y-25 · medium

**Section.** §8.16.10 Lock screen and background; §8.10 reserved push prompt

**Problem.** Listen publishes the series title, chapter and cover to the lock screen, the Android media notification and the OS media overlay, with no rule for mature series (a novel is mature when its source is 18+ or its rating/override says so). Anyone who picks up the locked phone or glances at a desktop media overlay sees the mature title and cover, outside the per-profile gate. The reserved push prompt has no content rule either.

**Evidence.** §8.16.10: "lock-screen and notification controls (title, chapter, cover, play/pause, ±15 s, next chapter) through `audio_service` 0.18.19"; "`navigator.mediaSession.metadata` with title, chapter, cover artwork at 256 and 512 px". §8.10: "A reserved **push prompt** (ships only with push support)". §7.24 defines `mature` for local rows but nothing for OS surfaces.

**Fix.** For a series whose `mature` is true (source mature OR resolved rating mature after `mature_override`): `MediaItem(title: 'Chapter 12', album: 'ManhwaManiacs', artist: null, artUri: <bundled mm-mark 512 px PNG>)` and `navigator.mediaSession.metadata = new MediaMetadata({ title: 'Chapter 12', album: 'ManhwaManiacs', artwork: [mm-mark 256/512] })`; controls unchanged. Add Settings → Listen → "Show titles on the lock screen" (`ALL · NOT 18+`, default `NOT 18+`, per profile). Any future push or local notification for a mature series uses the same neutral text ("A new chapter is out.").

### A11Y-26 · medium

**Section.** §14.11 Content safety; §8.14 and §8.15 readers (app); §8.30.2 Content

**Problem.** Nothing covers the OS app switcher (recents). iOS and Android keep a screenshot of the last screen, so a mature page or cover read by a profile with the gate open is visible in the switcher to anyone using the device, including other profiles of the account whose gate is closed.

**Evidence.** grep of DESIGN.md: 0 hits for "app switcher", "recents", "FLAG_SECURE", "setRecentsScreenshotEnabled", "snapshot". §14.11 covers gated content inside the app only.

**Fix.** Settings → Content gains "Hide in the app switcher" (`OFF · 18+ ONLY · ALWAYS`, default `18+ ONLY`, per profile). iOS: on `AppLifecycleState.inactive` insert a full-screen `#000000` overlay with the 72 px `mm-mark` (removed on `resumed`), applied when the setting is `ALWAYS`, or `18+ ONLY` and the visible route shows a mature series. Android 13+: `Activity.setRecentsScreenshotEnabled(false)` through a `MethodChannel('mm/privacy')` under the same condition (this does not block user screenshots); Android 12 and below: the same black overlay on `inactive`. Web: not applicable.

### A11Y-27 · medium

**Section.** §8.20 Discover idle page (`RECENT` searches)

**Problem.** Recent searches are kept per profile but are not filtered by the 18+ gate. A query typed while the gate was open (a mature title or genre) keeps showing on the idle page after the gate closes, which reveals 18+ content to the gated profile.

**Evidence.** §8.20: "`RECENT` slug line of the last 4 searches (per profile, min 2 characters) with `Clear`." §7.24's list of locally stored, gate-filtered data does not include recent searches.

**Fix.** Each stored recent-search entry carries `mature: true` when it was entered while the profile's gate was open; the idle page reads entries through the same mature filter (`features/offline/mature-filter.ts`, `mature_filter.dart`), so they are absent while the gate is closed and return when it reopens, with nothing said about it. Add recent searches to the §7.24 list and to the §15.7 gate check.

### A11Y-28 · medium

**Section.** §8.5 Profile picker; §7.25 Avatars

**Problem.** Before any profile is chosen, the picker shows every profile's 18+ state (a certificate on the avatar) and its last reading time ("LAST READ 2 H AGO"). Anyone at the device sees which profiles read mature content and when each profile last read, which breaks per-profile isolation and advertises the mature profiles to gated users.

**Evidence.** §8.5: "a credit line in `type.caption` `ink.45` ('LAST READ 2 H AGO', or 'NEW' for a profile with no sessions). An 18+ profile shows the 20 px certificate at its avatar's bottom-right." §7.25: "18+ marker on the picker: a 20 px certificate at the avatar's bottom-right." §9.3.1: "A profile never sees another profile's library, history or bookmarks".

**Fix.** Remove the certificate and the `LAST READ` credit from the picker (keep `NEW` for a profile still in onboarding, which is not reading data). The 18+ state stays visible only in Manage profiles rows ("{Mood} mood · 18+ on") and in the profile form, which are explicit account-management screens. Delete the "18+ marker on the picker" sentence from §7.25.

### A11Y-29 · medium

**Section.** §9.2.5 Share cards (Privacy rules, templates); §9.2.4 Annual

**Problem.** The share-card privacy rule covers 18+ series but not 18+ genres or the art chosen for a card. The Genres card is drawn from the profile's genre weights, which include genres such as Smut or Ecchi when the gate is open, so a shared image can print mature genre names. The "relevant cover" of the Time, Chapters and Clock cards and the No. 1 card's series are not defined when the top series is mature.

**Evidence.** §9.2.5: "Templates (six): Time, Chapters, No. 1, Genres, Streak ..., Clock"; "a duotone art band (the relevant cover)"; "**Privacy rules.** 18+ series never appear on a card, whatever the gate." §9.2.1: genre radar "from `/library/recommendations`". §8.7: "mature genres such as Smut or Ecchi".

**Fix.** Share cards use a shareable data set: `GET /library/annual` (and the range payload behind The Numbers' Share) returns `shareable: {genre_weights, top_series, art_series}` computed only from series that are not mature (source not mature and resolved rating not mature after `mature_override`). The Genres card uses `shareable.genre_weights`; the No. 1 card and every art band use `shareable.top_series` / `art_series`; a template whose shareable data is empty is omitted from the slug line. The in-app Annual pages keep the full, gated data.

### A11Y-30 · medium

**Section.** §9.2.4 Annual page 9 and colophon `WITH`; §8.8 `circle` and `circle_top`; §9.3.7 member page; §9.3.1

**Problem.** Several Circle-derived aggregates are defined without the sharing rules, so they can expose what another member chose not to share: The Annual's "You and Riya both finished Solo Leveling", the colophon's `WITH` line, Tonight's `Most read in the circle` ranking and the member page's "Reading 4 series". None says it honours the member's `Share what I'm reading` switch, their `Hide this series from my activity` list, their `Include 18+ titles` switch, or reading done before they turned sharing on.

**Evidence.** §9.2.4: "9 The circle ... 'You and Riya both finished Solo Leveling.'"; colophon "`WITH` circle members who shared at least one series with this profile". §9.2.7: `GET /library/annual` returns "circle overlaps". §8.8: "`Most read in the circle` (`circle_top`) | Ranked this week across sharing profiles, 18+ gated per viewer". §9.3.7: "deck 'Reading 4 series'". §9.3.1 switches: "`Include 18+ titles in my activity`", §9.3.6: "`Hide this series from my activity` list".

**Fix.** Define in §9.3.1 the shareable activity set S(member, viewer): activity events recorded while the member's `Share what I'm reading` was on, for series not in the member's excluded list, and for a mature series only when the member's `Include 18+ titles` is on and the viewer's gate is open. Every Circle-derived figure (Annual overlaps and `WITH`, `circle` and `circle_top` rails and their counts, member-page rails and deck counts, reactions lists, `now`) is computed from S only, server-side, at serve time.

### A11Y-31 · medium

**Section.** §7.6 World card; §9.1.3 Picks; §9.1.4 Similar; §8.7 onboarding seed wall; §7.19

**Problem.** World recommendations carry `is_adult`, but the contract never uses it: nothing says adult world items are removed for gated profiles (Picks, Because-you-read, Similar, the AI ask results, onboarding seeds), and nothing marks them when the gate is open. Information-only World cards have no source `mature` flag or series `rating`, so the poster badge rule ("only when ... the series is mature") cannot be applied to them.

**Evidence.** capabilities.md §9: "`WorldItem`: ... genres[≤5], cover_url ..., is_adult, platforms ...". grep of DESIGN.md: 0 hits for `is_adult`. §7.7: "`18` certificate (only when the profile's gate is open and the series is mature)". §15.5's blanket "All gate 18+ on serve" covers only the new endpoints listed there, not the existing `/library/world/recommendations` and `/library/world/suggest`.

**Fix.** Gate on serve: `/library/world/recommendations`, `/library/world/suggest`, `/ai/similar`, `GET /home` (`picked`, `because`, `also`), and the onboarding seed wall drop WorldItems with `is_adult: true`, and drop `available[]` entries on mature sources, when the active profile's gate is closed. With the gate open, World cards show the 16 px certificate when `is_adult` is true or any `available` source is mature. Add a World card to the §15.7 gate check.

### A11Y-32 · medium

**Section.** §9.1.7 `GET /home` caching; §9.2.7 `GET /library/annual`; §9.1.4 `/ai/similar`; §7.24 Confirm moment

**Problem.** Server caches are keyed per profile (or per series) but not by the gate state, while the gate can change at any moment. After a profile closes its gate, `/home` (cached 10 min) and `/library/annual` (cached per day) can serve a composition that contains 18+ series, including an 18+ cover story that a post-filter cannot replace without recomposing; `/ai/similar` is cached 7 days per series with no gate note. The client-side "invalidate every mature-gated query root" does not reach server caches.

**Evidence.** §9.1.7: "cached 10 min per profile; 18+ gated on serve"; `/ai/similar`: "Seeded similarity; budget-free cache 7 days". §9.2.7: "cached per profile per day". §7.24: "Every mature-gated query root is invalidated, and the next screen re-enters its skeleton."

**Fix.** Key the `/home` and `/library/annual` caches by `(profile_id, mature_content_enabled, content_kind)` and purge that profile's entries whenever `PATCH /profiles/{id}` or `PUT /settings` changes `mature_content_enabled`; per-series caches (`/ai/similar`, `/ai/tags`, `/series/enrichment`) store the ungated result and filter at response time with the requester's gate (shared caches gate on serve, never at store). State this in §15.5.

### A11Y-33 · medium

**Section.** §9.1.5 Auto-continue countdown; §14.5 timers

**Problem.** The recap's 12 s auto-continue is a time limit that moves the user into the reader, and it has no off switch: the only escape is setting recaps to `NEVER`. On the web the screen-reader exemption cannot apply (no detection) and a virtual cursor reading the recap does not move focus, so the countdown fires while a screen-reader user is still reading (WCAG 2.2.1).

**Evidence.** §9.1.5: "When the recap has finished streaming, `Continue` starts a **12 s countdown** ... At zero the reader opens"; "whenever a screen reader is running (then it never starts...)". §14.5: "web: no reliable detection, so the web instead pauses every timer while focus is inside the timed element".

**Fix.** Add Settings → Reading → "Continue automatically after a recap" (`ON · OFF`, default ON, per profile); OFF shows no countdown. On the web the countdown also pauses on any `keydown`, `pointerdown`, text selection inside the recap or `focusin` anywhere in the takeover, and the first time it starts a polite live region says "Continuing to chapter 143 in 12 seconds. Press Escape to stop."; `Esc` stops it (then closes on a second `Esc`).

### A11Y-34 · low

**Section.** §8.0.10 Content that is no longer available

**Problem.** The not-available notice is worded identically for removed and gated content, but its `Search for it` action pre-fills Discover with the title "when the title is known". After a profile closes its gate, the client can still know a mature title from route state or an in-memory cache, so the action types the hidden 18+ title into the search field and gives the gate away.

**Evidence.** §8.0.10: "quiet `Search for it` (Discover with the title prefilled when the title is known). The wording is identical for removed and gated content, so the notice never reveals 18+."

**Fix.** Pre-fill only when the active profile's gate is open (then the refusal cannot be the gate) or when the title came from a payload fetched after the last gate change; otherwise `Search for it` opens Discover with an empty field.

### A11Y-35 · low

**Section.** §9.3.4 Recommend to ("Pass it on")

**Problem.** For an 18+ series the recipients list carries the caption "Only readers who can see 18+ titles are listed." With two or three members, that caption plus the shortened list tells the sender exactly which other profiles have their gate closed, which is another profile's private setting.

**Evidence.** §9.3.4: "for an 18+ series, only recipients whose gate is open are listed, with the caption 'Only readers who can see 18+ titles are listed.'"

**Fix.** Drop the caption; list eligible recipients without explanation, and when none are eligible use the existing neutral line "Nobody is taking recommendations right now."

### A11Y-36 · low

**Section.** §14.4 Route changes (`document.title`); §8.17; §8.14

**Problem.** On the web every route sets `document.title` to `{Page} · ManhwaManiacs`, so mature series titles land in the browser's history, tab titles and address-bar suggestions, which other profiles of the account using the same browser will see.

**Evidence.** §14.4: "`document.title` becomes `{Page} · ManhwaManiacs`".

**Fix.** For a mature series (feature page, book page, both readers, recap), `document.title` is the section name only: "Series · ManhwaManiacs", "Reader · ManhwaManiacs", "Previously on · ManhwaManiacs". The route URL still carries keys; note that in §14.11 as a known limit.

### A11Y-37 · low

**Section.** §4.8 Reduced motion; §14.1

**Problem.** §14.1 declares the §4.8 table authoritative for every named move, but several moves and loops are missing, and the general rules contradict each other for them ("loops stop" would freeze loading indicators; "a sweep shows its end state" vs "countdowns become labels" for the Listen dial).

**Evidence.** §4.5 names **Set** ("Items fade 0 → 1 and rise 8 px → 0 in reading order") and **Countdown** ("the dial sweeps (Listen)"), neither in §4.8. Paged page turns `SLIDE` (§8.14.7, 280 ms; §8.15.4, 300 ms) are not in §4.8. §7.18 leader dial "one revolution per 1000 ms linear", indeterminate rule "1200 ms linear loop", §7.1 button loading "1200 ms linear loop" have no reduced variant while §14.1 says "loops stop".

**Fix.** Add rows to §4.8: Set → the whole block fades in once over 150 ms, no rise, no stagger; Listen countdown dial → a static dial with the label `NEXT IN 5 S`, updated once per second; `SLIDE` page turns → 150 ms opacity cross-fade; leader dial, indeterminate rule and button loading segment → keep running unchanged (essential progress indicators, WCAG 2.3.3), and say so in §14.1's list of what does not change.

### A11Y-38 · low

**Section.** §7.11 Toasts

**Problem.** Toasts with actions (`Undo`, `View`, `Retry`) hold 8–10 s and pause only while hovered or focused, but there is no way for a keyboard user to move focus to the toast region, so the action is effectively pointer-only on the web and on hardware keyboards.

**Evidence.** §7.11: "Hold | 3600 ms; errors 6000; with an action 8000; skin undo 10000; indefinite while hovered or focused"; "Dismiss | Swipe down (phone), `Esc` (focused), or timeout"; "Web uses `sonner` 2.0.8".

**Fix.** Web: `<Toaster hotkey={['altKey','KeyT']} />` (sonner's region hotkey) and list `Alt+T` "Go to notifications" in the keyboard sheet and Settings → Keyboard; focusing the region pauses every hold. Flutter with a hardware keyboard: the same `Alt+T` through `Shortcuts`, moving focus to the newest toast's action.

### A11Y-39 · low

**Section.** §8.15.2 Speaker tints; §14.3

**Problem.** Outside Listen mode, who is speaking is conveyed only by the tint colour of the underline and background; there is no name on demand and no screen-reader equivalent. §14.3's claim that speaker tints are backed by names holds only in Listen mode.

**Evidence.** §8.15.2: "attributed dialogue runs get their speaker's slot colour (§2.1.6) as a 2 px underline at 70 % and a 12 % background". §14.3: "speaker tints are backed by the speaker's name above the sentence in Listen mode".

**Fix.** A tinted run shows the speaker's name on hover (web tooltip, 500 ms) and on long-press (phones, a small popover `KIM DOKJA` in `type.kicker`); screen readers get the name through `aria-describedby` (web) or `Semantics(hint: 'Kim Dokja')` (Flutter) on the run's paragraph. The cast sheet already lists each slot's colour square.

### A11Y-40 · low

**Section.** §3.3 Mobile text scale (caps role group)

**Problem.** Informational small text is capped at 1.5×: `kicker`, `credit` (author, artist, status values), `micro` (badges such as NEW, 18+, status, READ) and `nav`. At the 200 % system setting a 10 px badge reaches only 15 px and an 11 px kicker 16.5 px, so the smallest text in the app is the text that scales least.

**Evidence.** §3.3: "Caps: `kicker`, `credit`, `nav`, `micro` | 1.50 | kicker 11 → 14.3 → 16.5 px".

**Fix.** Raise the cap to 2.0 for `kicker`, `credit` and `micro` (they already switch to `wdth` 100 at ≥ 1.3; with A11Y-11's min-height rule nothing clips). Keep `nav` at 1.5 in the thumb index only, and at ≥ 1.5 a long-press on a tab shows a 64 px large-label HUD (the iOS Large Content Viewer pattern) in `type.subhead`.

### A11Y-41 · low

**Section.** §7.25 Avatars; §2.1.2; §2.1.1; §8.16.5 voice monograms

**Problem.** Several stated contrast figures do not match the WCAG formula, although §2.1.1 says "every contrast figure is exact"; the avatar claim is materially wrong and would fail any test written from it. The voice-picker monogram circles have no colour values, so their letter contrast cannot be checked.

**Evidence.** §7.25: "a Phosphor Fill glyph at 45 % of the diameter in `ink.100` (≥ 4.5:1 on every field)" — computed: cyan #1F8FA8 3.32, amber #B87A12 3.16, emerald #1E8C60 3.71, ember #C24724 4.37, star #A8850F 3.06, reader #187C7C 4.38. §2.1.2: spot "13.5:1" (computed 13.94), "Bone on spot is 1.4:1" (1.32). §2.1.1: rule.1 "1.5:1" (1.46), rule.2 "2.0:1" (1.90). §8.16.5: "a 40 px monogram circle in a hue derived from pitch".

**Fix.** Either state "≥ 3:1 (non-text), 3.06 minimum" or darken the six fields to reach 4.5:1: cyan #1A778C (4.54), amber #95630F (4.53), emerald #1A7B54 (4.60), ember #BE4523 (4.54), star #85690C (4.58), reader #177878 (4.62). Correct the four figures to 13.9, 1.3, 1.5 (1.46) and 1.9. Voice monograms: field HLS L 0.28, S 0.45, hue from 220° (80 Hz) to 30° (300 Hz) linearly, letter in `ink.100` (≥ 5.13:1 at every hue); add the avatar and monogram fields to the surface × ink loop.

### A11Y-42 · low

**Section.** §8.31 System status (admin)

**Problem.** It is not specified whether System status follows the active profile's 18+ gate. The source-health table names every source and the summary counts problems; if it is instance-wide, an admin profile with the gate closed sees 18+ source names, contradicting the gate; if it is gated, the summary silently omits 18+ failures. An implementer has to guess.

**Evidence.** §8.31: "**Source health**: a table sorted worst-first: mark, name, id (Plex)..."; "System status is instance-wide." §8.21 reads the same endpoint as "from `/system/source-health`, gated counts".

**Fix.** State that System status follows the active profile's gate like every other screen: 18+ sources are absent from the table, the summary and the counts while the gate is closed; an admin who needs them opens the gate on their profile.

## Count

42 findings: 6 high, 27 medium, 9 low.
