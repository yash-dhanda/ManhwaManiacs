# Cinematic DESIGN.md: judge pass on the accessibility, privacy and safety audit

Input: `verify/find-a11y.md` (42 findings). Checked against `cinematic/DESIGN.md`, `inventory/00-decisions.md`, `stack-decision.md`, `inventory/capabilities.md`, and, where a finding claims a data-layer leak, the code the redesign keeps in place (`backend/services/`, `mobile/lib/features/downloads/store/`, `frontend/src/lib/scoped-storage.ts`) plus the pinned Flutter SDK at `/srv/manhwamaniacs/dev/flutter`.

How each finding was tested:

- Every quoted sentence was grepped in DESIGN.md and read in context, and I searched the rest of the file for a rule that already covers the case.
- Every contrast figure was recomputed with the WCAG 2.x relative-luminance formula, with alpha composited in sRGB. The auditor's figures reproduce to ±0.04. The worst-case duo `#F5F547` is HLS(60°, 0.62, 0.90).
- Flutter API claims were checked in the SDK source. `Semantics.headingLevel` exists and accepts 1–6. `AccessibilityFeatures` has `highContrast` and `boldText`, but no reduce-transparency flag. `MediaQuery.highContrastOf` and `boldTextOf` exist. `containsSemantics(isHeader:)` exists.

Result: **34 confirmed** (several with rewritten or narrowed fixes) and **8 refuted** (A11Y-12, 24, 25, 26, 27, 34, 36, 42).

## Verdict table

| ID | Verdict | Final severity | Reason in one line |
|---|---|---|---|
| A11Y-1 | Confirmed | high | Scrims are graded thin exactly where the text sits. Recomputed: phone running head over a white page gives ink.60 1.04:1, spot 2.01:1, ink.100 2.66:1. No over-art contrast rule exists anywhere. |
| A11Y-2 | Confirmed | high | Transcript sentences at 35 % opacity reach 1.73:1 on the brightest 50 % duotone field and 2.77:1 on pure black. The active sentence on the wash is 3.23:1. |
| A11Y-3 | Confirmed | high | Outline-only badges have no ground on cover art. Over a white cover: ink.100 1.14, spot 1.51, set 1.84, proof 3.07. |
| A11Y-4 | Confirmed, fix rewritten | low | The "UNAVAILABLE ON THIS PROFILE" row contradicts "absence, never a lock". The server already omits such pins, so the fix is to delete the row, not to filter on the client. |
| A11Y-5 | Confirmed, fix rewritten | medium | The index placeholder uses ink.30 (2.41:1), which the contract reserves for non-information. The field has no specified accessible name and no rule for its focused-empty state. |
| A11Y-6 | Confirmed | low | ink.30 carries rank, the skipped state, and cover-failed state, against §2.1.1 and §14.2. |
| A11Y-7 | Confirmed | medium | The raised-stock list misses reader grounds, wash bands, paper.4 rows and stock-painted panels. Recomputed: ink.45 on proof.wash 4.23, on spot.wash over paper.2 2.95, on Slate 3.90. |
| A11Y-8 | Confirmed | medium | `TypedHeadline` hard-codes `<h1>` but is used for notices, numerals, tips and folios. Discover and Dialogue have no h1 to take route focus. |
| A11Y-9 | Confirmed | medium | Flutter `SetHeading` and `TypedHeadline` never set `header: true`, while §14.4 depends on it. |
| A11Y-10 | Confirmed | medium | Flutter letter `Text` widgets ignore the §3.3 role caps. Nowrap word boxes overflow at large scale or at narrow reflow widths. |
| A11Y-11 | Confirmed, fix trimmed | medium | Fixed heights (the 16 px badge at the 1.5 cap gives an 18 px line) and "2 lines max" toasts clip or truncate at scale 2.0. |
| A11Y-12 | **Refuted** | — | See Refuted. |
| A11Y-13 | Confirmed | low | Increase Contrast is honoured on the web only. The explicit `FontVariation('wght')` makes OS Bold Text an undesigned result on the phones. |
| A11Y-14 | Confirmed | medium | No semantics contract exists for the custom controls. `aria-pressed` appears once in the whole file, and no Flutter primitive has roles or states. |
| A11Y-15 | Confirmed | medium | Folio abbreviations ("2 H", "PAUSED 21 D", "CH 142 · 63%") have no spoken form. |
| A11Y-16 | Confirmed, fix narrowed | low | The web case is partly covered by §14.5 (timers pause while focus is inside). Flutter hardware keyboards and scroll-hide with focus inside are not covered. |
| A11Y-17 | Confirmed | medium | The Space-opened preview slate has no focus behaviour, and as a portal it cannot be reached by Tab. |
| A11Y-18 | Confirmed, fix adjusted | low | The spread's buttons stay focusable at opacity 0 between p 0.55 and 1. |
| A11Y-19 | Confirmed | medium | §7.3 removes Show/Hide from the tab order, while §8.3 puts it in the tab order. |
| A11Y-20 | Confirmed | medium | Reorder is drag or `Alt+arrows` only, which gives no single-pointer path (WCAG 2.2 2.5.7). |
| A11Y-21 | Confirmed, fix adjusted | low | Heat level 1 is 1.18:1 on black, and the zero-day cell is unspecified. |
| A11Y-22 | Confirmed | medium | A bone ring over light art measures 1.14:1. The only ring spec is single-colour. |
| A11Y-23 | Confirmed, fix trimmed | medium | The global 44/48 rule contradicts desktop sizes (32, 40, 28) and "44 hit" entries that give no Android value. |
| A11Y-24 | **Refuted** | — | See Refuted. |
| A11Y-25 | **Refuted** | — | See Refuted. |
| A11Y-26 | **Refuted** | — | See Refuted. |
| A11Y-27 | **Refuted** | — | See Refuted. |
| A11Y-28 | Confirmed in part | low | `LAST READ` publishes every profile's activity timing before a profile is chosen, which bypasses the Circle sharing switches. The 18+ certificate half is refuted, because Manage (one tap away on the same screen) shows it anyway. |
| A11Y-29 | Confirmed | medium | Genre weights from mature reading can print "Smut" on a public PNG. The "18+ series never appear" rule does not cover genres. |
| A11Y-30 | Confirmed | medium | Annual overlaps, `WITH`, `circle_top` and member-page counts do not reference the per-member exclusion list or the `Include 18+` switch. |
| A11Y-31 | Confirmed, fix narrowed | low | Gate-on-serve for world recs already exists in `backend/services/world_recs.py`. What is missing is how a World card decides to show the 18+ badge. |
| A11Y-32 | Confirmed, fix narrowed | low | A cached composed `/home` filtered at serve time can lose its cover story after the gate closes. Keying by gate state avoids the hole. |
| A11Y-33 | Confirmed, fix rewritten | low | The recap countdown has no off switch, and on the web the screen-reader pause cannot trigger. The auditor's `Esc` fix conflicts with the existing `Esc` = close. |
| A11Y-34 | **Refuted** | — | See Refuted. |
| A11Y-35 | Confirmed | low | The caption states another profile's gate state, against the contract's own "nothing says it is hidden". |
| A11Y-36 | **Refuted** | — | See Refuted. |
| A11Y-37 | Confirmed, fix narrowed | low | Only the loop conflict is real. Set, `SLIDE` and the Listen dial are already resolved by the §14.1 rule of thumb and the "countdowns become labels" rule. |
| A11Y-38 | Confirmed | low | Action toasts have no documented keyboard route on either client. |
| A11Y-39 | Confirmed, fix rewritten | low | Outside Listen, speaker identity is colour-only, against §14.3's own heading. |
| A11Y-40 | Confirmed, fix narrowed | low | Form labels are `type.kicker`, capped at 1.5 (16.5 px) while field text reaches 32 px. Badges and tab labels can keep the 1.5 cap. |
| A11Y-41 | Confirmed, fix rewritten | low | The avatar claim "≥ 4.5:1" is false (3.06–4.38). Four other stated figures do not match the formula. Voice monograms have no colour values. |
| A11Y-42 | **Refuted** | — | See Refuted. |

## Confirmed

Each entry gives the final fix to apply to DESIGN.md. Where the auditor's fix was wrong, heavier than needed or vague, the text below replaces it.

### A11Y-1 · high · Text and icons over art

**Defect.** The contract has no contrast rule for text or icons over art. Scrim alpha at the text line recomputes as follows:

- Phone reader running head: alpha 0.42, giving ink.60 1.04:1 over white.
- Desktop head: alpha 0.68, giving ink.60 2.68:1.
- Folio bar caption: alpha 0.52–0.64, with `ink.45`.
- Phone hero headline: alpha about 0.33.

**Fix.**

1. **Over-art rule.** Add to §2.1.4 and §14.2: every text run and icon drawn over art (covers, manga pages, duotone fields, blurred copies) sits on black whose alpha across its line box ± 8 px is at least the value below. Each value gives ≥ 4.5:1 composited over `#FFFFFF`. `ink.45` and `ink.30` are never used over art.

   | Ink | Minimum alpha |
   |---|---|
   | `ink.100` | 0.60 |
   | `ink.80` | 0.68 |
   | `spot` | 0.66 |
   | `set` | 0.70 |
   | `ink.60` | 0.82 |
   | `proof` | 0.84 |

2. **Scrim tokens.**
   - `scrim.head` becomes `#000000` at 0.88 flat from the top edge to the bar's bottom edge (phone: safe area + 44 px; desktop: 56 px). Then the 13 eased stops run, reversed, to 0 over the next 44 px (phone) or 64 px (desktop). At 0.88 over white: ink.60 5.65:1, spot 10.94:1, ink.100 14.47:1.
   - `scrim.sole` becomes `#000000` at 0.90 flat from the bottom edge through the folio bar's top edge (64 px + bottom inset), then eased to 0 over 64 px.
   - The §8.14.3 page-tint mix (25 % of `page.tint`) still applies to these end colours.
3. **Folio bar.** `6 MIN LEFT` becomes `ink.60`.
4. **`scrim.foot`.** This covers the phone Tonight and series heroes, genre tiles, collection plates and the collection header, Sources tiles, the recap band and Annual pages. The scrim reaches alpha 1 of its end colour 24 px above the top of the text block's first line box, so the whole block sits on solid `ambient.tint` or black (ink.60 ≥ 6.35:1). Each component measures its text block and places the ramp above it.
5. **Rating card.** Its text sits in a `paper.0` box with 8 × 12 px padding.
6. **Coming up card.** Its text block sits on a `#000000` band at 0.84.
7. **Test.** Add a runnable check to the existing `tint` tests (`tint.test.ts`, `tint_test.dart`). A table lists (component, ink, ground alpha at the text line). Each row is composited over `#FFFFFF` and `#F5F547` and must reach ≥ 4.5:1. The threshold is ≥ 3:1 for text ≥ 24 px regular, text ≥ 18.66 px at wght ≥ 700, and icons.
8. **§15.7.** List the over-art table there.

### A11Y-2 · high · Listen full player transcript

**Defect.** Recomputed with the brightest duo at 50 % over black, `rgb(122,122,36)`:

- Inactive sentences (ink.100 at 35 % opacity): 1.73:1. On pure black the same ink is 2.77:1.
- Active sentence (ink.100 on `spot.wash`): 3.23:1.

**Fix.** In §8.16.3:

- **Background.** The duotone copy runs at **15 %** over `#000000`, not 50 %. Keep `scrim.vignette` and grain 0.05.
- **Inactive sentences.** `ink.60` at full opacity: 5.34:1 on the brightest 15 % field, 7.20:1 on black.
- **Active sentence.** `ink.100` on `spot.wash`: 9.21:1 in the worst case.
- **Speaker-name kickers.** They keep their tints: ≥ 6.80:1 on the brightest 15 % field, ≥ 9.17:1 on black.
- **Head.** The `NOW READING ALOUD` kicker becomes `ink.60`.
- **Test.** Add the full player to the A11Y-1 over-art table.

### A11Y-3 · high · Badges on cover art

**Defect.** Outline-only badges (status, reading status, `SAVED`, `TEXT`, `PICKED`, the 18+ certificate, `OFFLINE EDITION`) sit directly on art. On a white cover: ink.100 1.14:1, spot 1.51:1, ink.60 2.92:1, proof 3.07:1.

**Fix.** In §7.19, every badge that can sit on art gets a `#000000` fill inside its 1 px outline. That covers all poster badges, Cutting nudge badges, World card badges and the running head's `OFFLINE EDITION` micro badge. Text contrast then equals the flat-black figures: ink.100 18.44, spot 13.94, set 11.41, ink.60 7.20, proof 6.85, ink.45 4.70. The 18+ certificate on art is a `#000000` square with a 1 px `proof` outline and `18` in `proof`. Sizes and the 4 px stack gap do not change.

### A11Y-4 · low · "UNAVAILABLE ON THIS PROFILE" pinned rows

**Defect.** §8.21 specifies a greyed row that names a pinned source "no longer visible on this profile". That is a locked row, which §7.24 and capabilities §1 forbid. The auditor's fix is wrong: it assumes the client receives such pins and must filter them in every consumer.

The server already omits every pin that no longer resolves: a mature source under a closed gate, a removed connector, or the novels flag being off. See the docstring of `backend/services/source_pin_service.py` and `backend/tests/test_audit_mature_gate_stale_pin_disclosure.py`. `available` is always `true` in `GET /sources/pins` today, and the capabilities table describing an `available: false` state is out of date.

**Fix.**
- §8.21: delete the sentence "Unavailable pinned sources (pinned but no longer visible on this profile) show at 40 % with `UNAVAILABLE ON THIS PROFILE` and cannot be opened."
- §7.7 Disabled state: delete "pinned source missing" from the trigger list.
- §8.21: add one line stating that pins that no longer resolve are omitted by the server and come back when the source does.

No client-side filtering is needed. The `PINNED` count, Discover `02 Sources`, the genre-tile union, `04 Trending`, the search status line, Tonight `sources` and the palette `SOURCES` group all read the same, already-filtered list.

### A11Y-5 · medium · The `index` search field

**Defect.** The placeholder is `ink.30` (2.41:1 on `paper.0`), which §2.1.1 reserves for non-information, although §2.1.1 assigns large-type placeholders to `ink.45`. No accessible name is specified, and nothing says what shows while the field is focused and empty.

**Fix.** In §7.4 `index`:

- **Placeholder colour.** `ink.45`: 4.70:1 on `paper.0`. The raised scope renders it `ink.60` inside the command palette's `paper.2`, at 6.42:1.
- **Accessible name**, per instance (web `aria-label`; Flutter `Semantics(textField: true, label: …)`):
  - Discover: "Search every source"
  - Dialogue: "Search what a character said"
  - Command palette: "Search or jump"
  - Picks ask field and the Discover `ASK` scope: "Describe what you feel like reading"
- **Typed placeholder.** It is a visual layer only (`aria-hidden`). The input's real `placeholder` / `hintText` holds the same full string, and while the field is focused and empty the full placeholder shows statically. The field's purpose therefore stays visible until the user types.
- **No extra label.** The masthead kicker directly above the field (`No. 04 — DISCOVER`, `No. 09 — DIALOGUE`, `No. 12 — PICKS`) stays as the visible context. A second kicker is not added.

### A11Y-6 · low · `ink.30` used for information

**Defect.** Top-ten rank numerals, the skipped genre word, the 404 numeral and the `image-broken` glyph are all `ink.30` (2.41:1 on `paper.0`, 2.26:1 on `paper.1`).

**Fix.**
- **Ranked numerals** (§7.7): `ink.45`. As large text they need 3:1 and get 4.70 on `paper.0` and 4.41 on `paper.1`. The poster's accessible name carries the rank: "Number 3, Solo Leveling".
- **Skipped genre** (§8.7): `ink.45` plus the 1 px `proof` strike-through, with the state in the accessible name ("Romance, skipped").
- **404 numeral** (§8.32): mark it decorative (`aria-hidden`, `ExcludeSemantics`). It may stay `ink.30` because the headline carries the message.
- **`image-broken` glyph** (§7.7, §8.24): `ink.45` (4.41:1 on `paper.1`), labelled "Cover didn't load" (posters) or "Page didn't load" (dialogue stills).

### A11Y-7 · medium · Raised-stock scope is incomplete

**Defect.** The §2.1.1 prose says `ink.45` renders `ink.60` on any ground other than `paper.0`, but the implementation list names only sheets, menus, popovers, the palette, dialogs, plates, selected and pressed rows, grade bands and spreads. These grounds are missing, with recomputed `ink.45` contrast:

| Ground | ink.45 contrast |
|---|---|
| Reader Ink ground | 4.41 |
| Reader Slate ground | 3.90 |
| `paper.4` own row | 3.56 |
| `proof.wash` over `#000` | 4.23 |
| `spot.wash` over `paper.2` | 2.95 |

Stock-painted novel panels are missing too. Separately, `ink.60` on `spot.wash` over `paper.3` is only 4.08:1.

**Fix.** Replace the enumerated list in §2.1.1 with a structural rule, and extend the loop:

1. **Raised scope.** Every primitive that paints a ground other than `paper.0` applies the raised scope (web `data-stock="raised"`, Flutter `CineStock.raised`). This explicitly includes:
   - the manga reader canvas when its ground is Ink or Slate (chapter seam, read-all divider, top band)
   - the select-mode bar
   - own and tinted table rows
   - `proof.wash` areas and error rows
2. **Inside any `spot.wash` band.** The `ink.45` and `ink.60` roles render `ink.80`: 9.41:1 on the wash over `#000`, 6.98:1 over `paper.3`.
3. **Stock-painted panels.** This covers the novel margins panel, the contents sheet, the mini player, the next card and the rating card in stock colours. Inside them, `ink.45` roles render the stock's `muted` colour (≥ 5.84:1). This fixes "reacted to Ch. 212".
4. **Loop.** Extend the §2.1.1/§2.1.5 surface × ink loop with `ground.ink`, `ground.slate`, `spot.wash` over `paper.0`–`paper.3`, `proof.wash` over `paper.0`–`paper.3`, and the six stock pages.

### A11Y-8 · medium · `TypedHeadline` heading level

**Defect.** §10.2.3 always renders `<h1>`, yet §10.2.2 uses the component for notices, numerals, folios, tips and loading lines. Discover and Dialogue have no h1, although §14.4 moves route focus to the page h1.

**Fix.**

1. **Component.** `TypedHeadline` takes `as?: 'h1' | 'h2' | 'h3' | 'p' | 'span'`, default `'p'`.
2. **Where `h1` applies.** Only where the typed line is the page's only title:
   - Tonight's cover headline
   - the picker question
   - the Login, Register and Setup headlines
   - onboarding step headlines
   - the 404 headline
   - a §8.0.10 notice that replaces a whole page
3. **Everything else.**
   - Other notice headlines use `h2`. That includes System status's summary headline, because its masthead "System status" is the h1.
   - Numerals, folios, tips, captions, loading lines and next-chapter captions use `span` or `p`.
   - Index-field placeholders do not use `TypedHeadline` at all (A11Y-5).
4. **Flutter.** Takes the same level (see A11Y-9).
5. **Discover and Dialogue.** Each renders a visually hidden h1 as the route focus target: web `<h1 className="sr-only" tabIndex={-1}>Discover</h1>` / "Dialogue search"; Flutter `Semantics(header: true, headingLevel: 1, label: …)` on a zero-size box with the route `FocusNode`.

### A11Y-9 · medium · Flutter headings expose no heading semantics

**Defect.** `SetHeading` (§10.1.6) wraps its text in `Semantics(label:, excludeSemantics: true)` with no `header`, and its reduced-motion branch is a bare `FadeTransition`. `TypedHeadline` (§10.2.4) does the same.

**Fix.**
- Add `final int level` (1–3) to both widgets.
- Wrap every branch (seen, reduced, animating) in `Semantics(header: true, headingLevel: level, label: text, excludeSemantics: true, child: …)`. `headingLevel` exists in the pinned Flutter 3.44.6 (asserted 1–6). It drives `<h1>`–`<h3>` on Flutter web. On iOS and Android, `header: true` is what VoiceOver and TalkBack read.
- Levels: masthead = 1, `type.section` heads = 2, subsections = 3.
- Extend `set_heading_test.dart` with `expect(tester.getSemantics(find.byType(SetHeading)), containsSemantics(isHeader: true, label: 'Library'))`. Use `containsSemantics`, not `matchesSemantics`, because the strict matcher fails on the other flags present.

### A11Y-10 · medium · Letter reveal: overflow and uncapped text scale

**Defect.** Each word sits in a non-wrapping box (web `inline-block whitespace-nowrap`, Flutter `Row(mainAxisSize: min)`), so a word wider than the line cannot break. On top of that, the Flutter letter `Text` widgets use the unclamped system text scaler, so the §3.3 caps never apply.

**Fix.**
- **Flutter scale.** Pass `textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: cap)` (the role's §3.3 cap) to the whole `Text` and to every letter `Text`. Compute `rise` as `0.42 × scaler.scale(fontSize)`.
- **Long words, both clients.** Before revealing, measure the longest word at the resolved size. Flutter uses `TextPainter` inside a `LayoutBuilder`; the web measures once with a hidden span and re-checks on a `ResizeObserver` on the container. If that word is wider than the available width, render the plain whole string instead of the letter reveal, with normal wrapping (`overflow-wrap: anywhere` on the web, `softWrap: true` in Flutter) and the reduced-motion 200 ms fade.
- **Test.** "Transmigration" in `type.cover` at text scale 2.0 in a 358 px column (390 − 2 × 16 gutters) must not overflow.

### A11Y-11 · medium · Fixed heights clip at large text

**Defect.** Examples: the badge is "height 16" while `type.micro` at the 1.5 cap has an 18 px line; toasts are "2 lines max" at `type.ui` scaled 2.0; and the §3.3 reflow list does not cover these parts.

**Fix.**
- **General rule.** Add to the §7 intro: every height in §7 is a **minimum** (web `min-height`; Flutter `ConstrainedBox(constraints: BoxConstraints(minHeight: …))` with intrinsic growth). This covers:
  - badges (min 16, `padding-block: 2px`)
  - buttons (44/48/56; the label may wrap to 2 lines at scale ≥ 1.5)
  - inputs (48) and menu items (40/48)
  - the sheet header (56) and Listen tiles (88)
  - the mini player (56)
  - the folio bar (64 + inset, growing to two rows at scale ≥ 1.5 as §3.3 already moves its caption)
- **§7.11 toasts.** Replace "2 lines max" with "never truncated". Copy is written to fit 2 lines at scale 1.0, and the toast grows with the text at larger scales, keeping the 560 px maximum width.

The auditor's 6-line limit plus a `More` sheet is not needed: toast strings are single sentences.

### A11Y-13 · low · OS contrast and bold settings ignored on the phones

**Defect.** Web `prefers-contrast: more` is honoured, but Flutter ignores `MediaQuery.highContrastOf`. Because §3.1 pins `FontVariation('wght', …)` on every role, OS Bold Text (which Flutter's `Text` merges in as `FontWeight.bold`) yields either no change or synthetic emboldening, never a designed weight.

**Fix.**
- **Increase Contrast.** When `MediaQuery.highContrastOf(context)` is true, apply the same remap as web `prefers-contrast: more` (`ink.45` → `ink.80`, `rule.1` → `rule.2`) through `CineTokens.copyWith` at the skin root.
- **Bold Text.** When `MediaQuery.boldTextOf(context)` is true, `CineType` adds 150 to every role's `wght` variation and sets the matching `fontWeight`, clamped to each face's axis maximum:

  | Face | Maximum wght |
  |---|---|
  | Bodoni Moda | 900 |
  | Archivo | 900 |
  | Newsreader | 800 |
  | Atkinson Hyperlegible Next | 800 |
  | Literata | 900 |
  | Source Serif 4 | 900 |

  IBM Plex Mono switches to its 600 static.
- **§15.7.** Add both settings to the text-scale pass.

### A11Y-14 · medium · Semantics of custom controls

**Defect.** `aria-pressed` appears once in DESIGN.md. There are no `aria-checked`, `aria-selected` or `aria-expanded` specs, and no Flutter primitive has a roles-and-states contract.

**Fix.** Add a semantics row to each §7 table. Minimum contract:

| Control | Web | Flutter | Name or value |
|---|---|---|---|
| Switch | Base UI Switch | `Semantics(toggled: v, label: <row label>)` | Row label |
| Checkbox | — | `Semantics(checked: v)`, tristate for indeterminate | — |
| Radio, single-select slug lines, segmented control | `role="radiogroup"` / `radio` + `aria-checked` | `Semantics(inMutuallyExclusiveGroup: true, checked: v)` | — |
| Multi-select slug lines, icon toggles (Follow, Favourite, Notify, Bookmark, Guided view, Auto-scroll) | `aria-pressed` | `Semantics(toggled: v)` | Fixed label ("Favourite", never "Unfavourite") |
| Tri-state genre filter | A button | — | "Romance: included" / "excluded" / "not filtered", plus a polite announcement on change |
| Contents tabs | Base UI Tabs | `Semantics(selected: v)` inside the `TabBar` | — |
| Reaction stamps | Radio-like buttons | Radio-like buttons | "Loved, 3 reactions, selected"; guarded: "2 reactions, hidden until you finish the chapter" |
| Download mark | — | — | DP7 wording: "Saved", "Queued", "Downloading, 30 percent", "Failed, tap to retry" |
| Storage meter | `role="meter"` + `aria-valuetext` | — | "4.1 of 10 gigabytes used" |
| Progress rules | `role="progressbar"` | — | — |
| Streak flame | `role="img"` | — | "12-day streak, read today" / "12-day streak, at risk" |
| Week dots | One label | One label | "Read on Monday, Tuesday, Thursday" |

### A11Y-15 · medium · Folios have no spoken form

**Defect.** Screen readers read the abbreviations literally ("2 H", "PAUSED 21 D", "CH 142 · 63%"), and the certificate reads as "18".

**Fix.**
- **Counts.** Counts are ordinary digits, styled smaller and raised (`font-size: 0.72em; vertical-align: 0.5em` on the web; Flutter a `WidgetSpan` with `Transform.translate(offset: Offset(0, -0.35 * fontSize))`). Unicode superscript characters are never used. The ¹² in this document is notation.
- **Spoken form.** One `folioLabel()` helper per client (`frontend/src/skins/cinematic/a11y/folio.ts`, `mobile/lib/skins/cinematic/a11y/folio.dart`) returns the spoken form. It is applied as `aria-label` / `Semantics(label:)`, with the visual text `aria-hidden`:

  | Visual | Spoken |
  |---|---|
  | `CH 142 · 63%` | "Chapter 142, 63 percent read" |
  | `2 H` | "2 hours ago" |
  | `PAUSED 21 D` | "Paused 21 days" |
  | `READING¹²` | "Reading, 12" |
  | `p. 12` | "page 12" |
  | `12 MIN` | "12 minutes" |
  | 18+ certificate | "Mature, 18 plus" |

- **Test.** One small table test per client asserts the conversions.

### A11Y-16 · low · Chrome hides while it holds keyboard focus

**Defect.** §14.5 already pauses web timers while focus is inside the timed element. Two cases are still open: Flutter with a hardware keyboard, which §14.4 promises to support, and chrome hidden by a scroll while it holds focus.

**Fix.**
- **Timer rule.** In §14.5, make the "pause while focus is inside" rule apply on both clients to every user, not only screen-reader users. The idle hide in §8.14.3 (including cinema mode), §8.15.3, §7.30 and the §8.16.2 mini-player linger does not run while focus is inside the chrome (web `:focus-within`; Flutter any chrome `FocusNode` has focus).
- **Scroll-hide.** If chrome hides for another reason (the downward-scroll threshold) while it holds focus, focus first moves to the reader canvas, never to the body. The canvas is a `tabIndex={-1}` region labelled "Reader, Chapter 142" on the web, and a `Focus` on the strip in Flutter.

### A11Y-17 · medium · Preview slate focus

**Defect.** The slate opens with `Space` on a focused poster, but no focus behaviour is specified. As a portal it sits outside the rail's DOM, so Tab from the poster cannot reach it.

**Fix.** Add to §7.8:
- **Keyboard-opened slate.** It is a non-modal `role="dialog"` with `aria-labelledby` pointing at its title. Focus moves to `Read`, and `Tab` / `Shift+Tab` cycle `Read`, `+ Library` and `Details`. `Esc` or `Space` closes it and returns focus to the poster.
- **Poster.** The poster carries `aria-expanded` and `aria-controls` pointing at the slate.
- **Pointer-dwell slates.** They never take focus.
- **Flutter** (tablets and desktop with a hardware keyboard): the same behaviour with a `FocusScope` in the `OverlayEntry`.

### A11Y-18 · low · Trailer scrub leaves focus on invisible buttons

**Defect.** The spread's text column is at opacity 0 from p = 0.55 but stays focusable. The strip's controls join the tab order only at p = 1.

**Fix.** Apply to §8.8, and adjust the §14.4 wording to match:
- **Inert column.** At p ≥ 0.55 the spread's text column becomes inert (web `inert`; Flutter `ExcludeFocus` + `ExcludeSemantics`).
- **Strip.** The strip's controls join the tab order at p ≥ 0.8, where their opacity is ≥ 0.5.
- **Focus rescue.** If focus was inside the column when it went inert, it moves to the strip's `Continue` once p ≥ 0.8, and before that to Tonight's `main` region (`tabIndex={-1}`).
- **Reversal.** Scrolling back below p = 0.55 reverses all of this.
- **Reduced motion.** The switch happens when the strip fades in.

### A11Y-19 · medium · Password Show/Hide tab order contradiction

**Defect.** §7.3 says "excluded from the tab order", while §8.3 lists `Tab` order username → password → Show → switch → Sign in → Create one.

**Fix.** In §7.3, the Show/Hide button stays in the tab order, directly after its field. It carries `aria-pressed` (label "Show password", pressed when the password is visible) and `aria-controls` pointing at the field. In Flutter it is `Semantics(button: true, toggled: visible, label: 'Show password')`. This applies to Login, Register and Change password.

### A11Y-20 · medium · Reorder has no single-pointer alternative

**Defect.** Reordering works only by drag or `Alt+↑/↓`. WCAG 2.2 AA 2.5.7 needs a single-pointer path that is not a drag, and a keyboard shortcut does not serve touch users.

**Fix.**
- **Menus.** Every reorderable row's and poster's menu (the trailing `dots-three`, Quick look, right-click) gains `Move up`, `Move down`, `Move to top` and `Move to bottom`, disabled at the ends. This applies to manual library order, pinned sources, collections, collection members and profiles.
- **Behaviour.** Each move animates with the existing 240 ms `set` sibling shift, writes `sort_order`, and is announced ("Solo Leveling moved to position 3 of 12").
- **§11.** Update the drag row's alternative column to list the menu items as well as `Alt+↑/↓`.

Flutter's `ReorderableListView` already exposes the same four actions to screen readers.

### A11Y-21 · low · Heatmap levels too faint; zero day unspecified

**Defect.** `heat.1` is 1.18:1 against black, adjacent levels are 1.80–2.62:1 apart, and no zero-day cell is defined. Four tone levels plus black cannot all be 3:1 apart within 18.44:1, so tone alone cannot fix it.

**Fix.**
- **Size encoding.** In §9.2.1, each 10 px cell draws an `ink.100` square of 3, 5, 7 or 10 px for levels 1–4, centred in the cell (18.44:1 against black).
- **Zero day.** A 10 px square with a 1 px `rule.2` outline.
- **Today.** Keeps its 1 px `spot` outline.
- **Legend.** Under the heatmap, show the five cell forms with their chapter ranges: `0 · 1–2 · 3–5 · 6–10 · 11+`.
- **Tokens.** Delete `color.heat.1`–`color.heat.4` from §2.1.6 and §2.8.1: the heatmap is their only use. The auditor's "keep them for The Annual's decorative uses" names uses that do not exist.

### A11Y-22 · medium · Focus ring over art

**Defect.** The ring is a single 2 px bone outline at 2 px offset. Over light art it measures 1.14:1 against `#FFFFFF`. This affects on-art buttons, reader chrome, the Lightbox, and posters in zero-gap walls.

**Fix.** In §2.4, §7 and §14.4, the focus ring is a double ring everywhere:
- **Web.** A 2 px `ink.100` outline at 2 px offset plus a black halo: `outline: 2px solid var(--mm-color-ink-100); outline-offset: 2px; box-shadow: 0 0 0 6px #000`. The halo is combined with any existing shadow, for example the poster's inset hairline: `box-shadow: inset 0 0 0 1px rgba(243,240,232,.08), 0 0 0 6px #000`.
- **Flutter.** `CineFocusRing` paints the bone stroke, then a 2 px `#000000` stroke 2 px further out.
- **Result.** On black the halo is invisible. On art it separates the ring at 18.44:1. The 8 px focus padding that rails and grids already reserve holds the 6 px halo.

### A11Y-23 · medium · Hit-area rule contradicts component sizes

**Defect.** The global rule is 44 × 44 on web and 48 × 48 on Android. The components contradict it: desktop `sm` buttons are 32, menu items 40, the segmented control 40, filter tokens 28, and many entries say "44 hit" with no Android value.

**Fix.**
1. **Rule by input type** (§7 intro and §14.6):
   - Coarse pointer (phones, tablets, mobile web): 44 × 44 pt on iOS and mobile web, 48 × 48 dp on Android.
   - Fine pointer (`@media (pointer: fine)`, desktop web): at least 32 × 32 px with ≥ 24 px target spacing (WCAG 2.2 2.5.8). This makes `sm` 32, menu items 40, segmented 40 and filter tokens valid on desktop, with the tokens' hit box at 32 px tall around the 28 px box.
2. **Android values.** Every "44 hit" becomes "44 (48 Android) hit".
3. **Phone running head on Android.** The bar keeps its 44 px visual height. Its buttons' hit boxes are 48 × 48 dp, centred on the bar and overflowing it by 2 dp top and bottom. This avoids changing every "44 + inset" reference.
4. **Slug lines** (§7.5). Each item's hit box is `max(label width + 24, 44)` wide × 44 (48 Android) tall, centred on the label. The separator spacing grows as needed so adjacent hit boxes never overlap and keep the 8 px gap.

### A11Y-28 · low · Profile picker shows every profile's `LAST READ`

**Defect.** Before any profile is chosen, the picker shows every profile's last-read time. That publishes each profile's reading activity to anyone at the account's picker, bypassing the Circle's opt-in `Share what I'm reading`.

The certificate half of the finding is refuted. A profile's 18+ state is an account-level profile setting that Manage profiles shows one tap away on the same screen (the auditor's fix keeps it there too), so hiding it on the picker protects nothing.

**Fix.** §8.5: remove the `LAST READ …` credit line. The credit line shows only `NEW` for a profile with no sessions, and is empty otherwise. §7.25's certificate-on-picker sentence stays.

### A11Y-29 · medium · Share cards can print mature genres and covers

**Defect.** The rule "18+ series never appear on a card" does not cover genre names. The Genres card is drawn from genre weights that include mature reading, so a public PNG can print "Smut" or "Ecchi". Which cover serves as the "relevant cover" when the top series is mature is also left to the implementer.

**Fix.**
- **Backend.** `GET /library/annual` and the range payload behind The Numbers' `Share` each return `shareable: {genre_weights, top_series, art_series}`. These are computed server-side only from series that are not mature (source not mature, and resolved rating not mature after `mature_override`).
- **Cards.** The Genres card uses `shareable.genre_weights`. The No. 1 card and every art band use `shareable.top_series` / `art_series`. A template whose shareable data is empty is omitted, as §9.2.5 already does for templates without data.
- **In-app.** The Annual pages keep the full, gated data.
- **§15.5.** Add the `shareable` block.

### A11Y-30 · medium · Circle aggregates ignore member exclusions

**Defect.** Several Circle-derived aggregates never reference the member's sharing rules:

- The Annual's overlaps and its colophon `WITH` line
- `circle` and `circle_top`
- the member page deck "Reading 4 series"

None of them references the member's `Hide this series from my activity` list or `Include 18+ titles` switch, or says whether reading done before sharing was turned on counts.

**Fix.**
- **§9.3.1.** Define the shareable activity set S(member, viewer): activity events recorded while the member's `Share what I'm reading` was on, for series not in the member's excluded list. A mature series counts only when the member's `Include 18+ titles` is on **and** the viewer's gate is open.
- **Where S applies.** Every Circle-derived figure is computed from S only, server-side, at serve time. That covers Annual overlaps and `WITH`, the `circle` and `circle_top` rails and counts, member-page rails and deck counts, reaction lists, and `now` on `GET /circle/members`.
- **§9.3.8.** State the same rule.

### A11Y-31 · low · World cards have no 18+ badge rule

**Defect.** The auditor's gate-on-serve half is already implemented. `backend/services/world_recs.py` drops `isAdult` / Hentai items via `_hidden()`, and drops mature `available[]` sources via `_availability_index()`, when the gate is closed. The new `/ai/similar` and `/home` fall under §15.5's "All gate 18+ on serve". What remains is that §7.7's badge rule ("the series is mature") has no definition for a World item, which has no source flag and no resolved rating.

**Fix.** Add to §7.6 World card and §7.19: with the gate open, a World card shows the 16 px certificate when `is_adult` is true or any `available[]` source is mature. Add a World card to the §15.7 gate check.

### A11Y-32 · low · Composed caches and gate changes

**Defect.** `/home` is "cached 10 min per profile; 18+ gated on serve". If the gate closes while a composition whose cover story is mature is cached, filtering at serve time removes the cover story, and the contract does not define a replacement. `/library/annual` has the same problem, cached per day.

**Fix.** In §9.1.7, §9.2.7 and §15.5, key the per-profile composed caches by `(profile_id, mature_content_enabled, content_kind)`. A gate change then reads a different cache entry and composes afresh, and no purge hook is needed.

Per-series caches (`/ai/similar`, `/ai/tags`, `/series/enrichment`) are already covered by the stack rule "shared caches apply the 18+ gate when serving, never when storing", so nothing changes there.

### A11Y-33 · low · Recap auto-continue timer

**Defect.** The recap countdown (a WCAG 2.2.1 time limit) has no off switch. On the web, the screen-reader pause cannot fire, because a virtual cursor does not move focus. The auditor's fix (`Esc` stops, a second `Esc` closes) conflicts with §9.1.5's existing `Esc` = close and `Space` = pause.

**Fix.**
- **Setting.** Settings → Reading gains "Continue automatically after a recap" (`ON · OFF`, default `ON`, per profile). With `OFF`, no countdown runs and `Continue` waits.
- **Web pause triggers.** The countdown also pauses on any `keydown`, on `pointerdown`, on a text selection inside the recap, and on `focusin` anywhere in the takeover.
- **Announcement.** When the countdown first starts, a polite live region says "Continuing to chapter 143 in 12 seconds. Press Space to pause." `Space` is the existing pause key.

### A11Y-35 · low · "Pass it on" caption reveals others' gate state

**Defect.** For an 18+ series the recipients sheet says "Only readers who can see 18+ titles are listed.". That states another profile's private gate setting, against the contract's own rule that nothing says something is hidden (§7.24).

**Fix.** In §9.3.4, drop the caption. List eligible recipients without explanation. When none are eligible, keep the existing neutral line "Nobody is taking recommendations right now."

### A11Y-37 · low · Reduced motion: loops

**Defect.** §14.1's general rule "loops stop" would freeze loading indicators (the leader dial, the indeterminate rule and the button loading segment), which contradicts "reduced motion removes movement, never content or state".

The rest of the finding is refuted: `Set` and the paged `SLIDE` turns fall under §14.1's rule of thumb (a slide becomes a 150 ms opacity change), and the Listen dial falls under "countdowns become labels".

**Fix.** Add to §14.1 "What does not change": the leader dial (§7.18), the indeterminate rule and the button loading segment (§7.1) keep running unchanged under reduced motion, because they are essential progress indicators. Add the same as one row in §4.8.

### A11Y-38 · low · Keyboard route to toast actions

**Defect.** Toasts with `Undo`, `View` or `Retry` hold for 8–10 s, but no keyboard route to them is documented on either client.

**Fix.**
- **Web.** Keep sonner 2.0.8's default region hotkey `Alt+T` (`<Toaster hotkey={['altKey','KeyT']} />`, which is the default). List it in §8.0.6 Global web keys, the `?` sheet and Settings → Keyboard as "Go to notifications". Focusing the region pauses every hold, as §7.11 already says.
- **Flutter** (hardware keyboard): `Alt+T` through `Shortcuts` moves focus to the newest toast's action.

### A11Y-39 · low · Speaker tints are colour-only outside Listen

**Defect.** §14.3 says speaker tints are backed by names, but only Listen mode shows the name.

**Fix.**
- **Web.** A tinted run shows the speaker's name on hover (a 500 ms tooltip in the §7.2 style, `KIM DOKJA` in `type.kicker`).
- **Phones.** Long-press on a tinted run shows the same name as a small popover. Long-press is unassigned in the novel body (§8.15.8).
- **Screen readers.** The name is read inline before the run: a visually hidden "Kim Dokja:" span on the web, and `TextSpan(semanticsLabel: 'Kim Dokja: …')` in Flutter.
- **§14.3.** Update it to "backed by the speaker's name on hover or long-press, and above the sentence in Listen mode".

### A11Y-40 · low · Form labels capped at 1.5×

**Defect.** Input labels are `type.kicker` (§7.3), capped at 1.5, so at the 200 % system setting a label reaches 16.5 px while the field text reaches 32 px. Credits values (author, status) are reading content and are capped the same way.

**Fix.** In §3.3:
- **Raise to 2.0.** The caps for `kicker` and `credit` rise to 2.0. They already switch to `wdth` 100 at ≥ 1.3, and credits blocks become single-column at ≥ 1.3, so there is room.
- **Keep at 1.5.** `micro` (poster badges, where width is fixed by the poster and each badge has an accessible name) and `nav` (the tab bar) keep 1.5.

The Large Content Viewer HUD proposed by the auditor is not needed.

### A11Y-41 · low · Wrong contrast figures and missing monogram colours

**Defect.** §2.1.1 claims every contrast figure is exact, but several are not:

- §7.25 claims the avatar glyphs are "≥ 4.5:1 on every field". Recomputed: cyan 3.32, amber 3.16, emerald 3.71, ember 4.37, star 3.06, reader 4.38.
- Four other stated figures are off: spot is "13.5" (actual 13.94), bone on spot is "1.4" (actual 1.32), rule.1 is "1.5" (actual 1.46) and rule.2 is "2.0" (actual 1.90).
- §8.16.5 gives the voice monograms no colour values, so their letter contrast cannot be checked.

**Fix.**
- **Avatar glyph.** The glyph is a non-text icon. Change §7.25 to "`ink.100` glyph, ≥ 3:1 (non-text; 3.06 minimum on Marquee)". No field colour needs to change.
- **Corrected figures.**
  - spot on `#000` becomes 13.9:1 (in §2.1.2, §14.2, and anywhere else "13.5" appears for spot).
  - Bone on spot becomes 1.3:1.
  - `rule.1` becomes 1.46:1.
  - `rule.2` becomes 1.9:1.
- **Voice monograms** (§8.16.5). The field is HLS L 0.28, S 0.45, with hue linear from 220° at 80 Hz to 30° at 300 Hz, and the letter in `ink.100`. The worst case over that hue range is 5.13:1 at 60°.
- **Loop.** Add the avatar fields and the monogram endpoints to the surface × ink loop.

## Refuted

- **A11Y-12 (reduced transparency).** WCAG has no reduced-transparency criterion. Cinematic has no translucent material: §2.5 bans `backdrop-filter`, and surfaces are solid paper stocks. The only legibility risk from its translucent layers is text over art, which A11Y-1 fixes at the source with solid or ≥ 0.82 grounds. Owner decision "Performance" asks only for OS reduced motion. Adding a native `MethodChannel('mm/a11y')`, a new setting and a boot-stamp key for an effect this skin does not use is out of scope. (This belongs in Glass's contract, where it matters.)
- **A11Y-24 (local stores not profile-scoped).** Already implemented in the shared data layer that `stack-decision.md` §2.3/§3 keeps in place. `mobile/lib/features/downloads/store/downloads_store.dart` is "the on-device chapter store for exactly one `(user, profile)` scope". Every content table, `progress_outbox` and `bookmark_outbox` included, is `scope_id`-led (`downloads_db.dart`), so no query can read or flush another profile's rows. The web offline and preference stores go through `frontend/src/lib/scoped-storage.ts`. The described cross-profile flush cannot happen.
- **A11Y-25 (lock-screen metadata for mature series).** Not a gate leak. The lock screen shows what the device's current listener is playing, and that listener's profile has the gate open (otherwise the chapter could not be playing). The gate is defined as in-app absence per active profile (capabilities §1, §7.24). No owner decision asks to hide OS media surfaces. A new setting plus neutral metadata is feature scope, not a defect.
- **A11Y-26 (app switcher snapshot).** Same reasoning. The snapshot is the current user's own last screen on their own unlocked device, and the private 2–3 user product has no requirement for app-switcher privacy. The proposal adds native code on two platforms for a threat outside the gate's definition.
- **A11Y-27 (recent searches after the gate closes).** Recent searches are the profile's own typed text, stored per profile (`frontend/src/features/library/recent-searches.ts` via scoped storage), not gated content. The gate governs what the server and local stores return, and search results already honour it. The proposed "typed while the gate was open" flag would also hide every harmless query from a profile that usually keeps the gate open.
- **A11Y-34 (`Search for it` prefill).** For a gated profile, a mature title can only be known from that same profile's earlier state (its own restored tab or route). Every server-backed source of links (notifications, history, bookmarks, letters) is already filtered for gated profiles. The prefilled search then returns nothing mature, because search is gated on serve. Nothing is disclosed to anyone who did not already see it.
- **A11Y-36 (`document.title` in browser history).** The proposed fix does not achieve its aim: the route URL still carries `seriesKey`, which for most sources is the title slug, and the auditor concedes this. Browser history belongs to the browser user, not to an app profile, and in-app gating is unaffected.
- **A11Y-42 (System status and the gate).** There is nothing for an implementer to guess. The table comes from `/sources/health`, which returns `list_sources` rows from `_visible_descriptors()` (`backend/services/browse_service.py`), and `/system/source-health` returns gated counts (capabilities §1, §16.1). Both are already gated per active profile on serve. "Instance-wide" in §8.31 refers to the backend and update-checker cards.

## Count

42 findings: 34 confirmed (3 high, 15 medium, 16 low after re-grading), 8 refuted.
