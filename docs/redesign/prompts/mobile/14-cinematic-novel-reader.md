# Mobile Cinematic novel reader "The page"

Track: mobile · Order 46 · Depends on: `docs/redesign/prompts/mobile/13-cinematic-manga-reader-paged-readall-panels.md` · Web twin: `docs/redesign/prompts/web/14-cinematic-novel-reader.md` · Proof folder: `docs/redesign/proof/mobile-14/`

## Goal

Build the Cinematic novel reader, "The page", in the Flutter app: a text column painted edge to edge in one of seven dark paper stocks (including the book's own "Issue" colour), an in-page running head, the chapter opener, a body set in one of five bundled reading faces with a Bodoni Moda drop cap, scene-break rules and speaker-tinted dialogue, the end matter and the seamless next chapter, solid stock-coloured chrome that fades (never slides) with the status bar following it, scroll and paged reading where paged mode runs on a new skin-neutral engine command `paginateNovel` (`TextPainter` pages in a `PageView`) with Cut, Slide and Fade turns, the "Text and page" Type sheet, the Contents sheet (phones) and column panel (tablets), bookmarks, the hardware-keyboard map, gestures, the screen-reader semantics and every state. Before any pixels, the logic that lives in the 1,245-line `features/novels/screens/novel_reader_screen.dart` and in `novel_chapter_view.dart` moves into a skin-neutral controller in a no-pixel commit (stack-decision §2.3). When you finish, the ScreenId `novel` leaves the Cinematic `PENDING` set. Listen mode is the next step (`mobile/15`); the ambient extras are `mobile/23`.

## Read first

Read these completely before planning. Where this file and `docs/redesign/cinematic/DESIGN.md` disagree, `cinematic/DESIGN.md` wins; say so in the report.

1. `docs/redesign/inventory/00-decisions.md` (all; "Novels: Apple Books / Kindle (paper themes, typography controls, page turns)").
2. `docs/redesign/stack-decision.md` §2.3 (mobile layout, boundary test, "logic that lives in a widget moves first"), §2.6, §3 (novel paper themes and typography stay as reader settings), §4 risks 1, 9 and 11.
3. `docs/redesign/cinematic/DESIGN.md`:
   - §2.1.1 (stock-painted panels: `ink.45` roles render the stock's `muted`), §2.1.5 (the Issue stock derived in `tint.dart` and its contrast test), §2.1.6 (speaker tints and paper stocks, both tables, and the stored-value mapping), §2.7 (icons: `list-numbers`, `bookmark-simple`, `text-aa`, `note-pencil`, `wifi-slash`), §2.8.1 (the `colorStock…` and `colorSpeaker1`…`colorSpeaker10` `CineTokens` fields).
   - §3.1 (global type rules: old-style figures in running text), §3.2 (`type.dropcap`), §3.3 (the novel body renders with `TextScaler.noScaling`; the system-scaled default size), §3.4 (the five faces, their axes, default sizes and leading, the Flutter asset families, Hyperlegible text and `legibleTextProvider`), §3.5 (`CineType.dropcap(double paragraphLineHeightPx)`).
   - §4.2 to §4.8 (chrome fade 240 / 160 ms, `durPageturn`, `CineSprings.release`, the Letter set, Folio flip, reduced-motion rows "Reader chrome in / out" and "Gestures").
   - §5 (`bookmark.add` = `impress`, `page.turn` = `selection`, `chapter.complete`, `chapter.next` = `heavy`, `scrub.boundary` = `medium`, `select`, `longpress.open` = `heavy`) and §6 (`set`, `turn`, `done`, `tick`).
   - §7.9, §7.11 (toasts in the Page frame use the stock), §7.16 (the novel contents row), §7.17, §7.18, §7.19, §7.20, §7.21, §7.23, §7.24 (rating card), §7.29 (`folioLabel()`).
   - §8.0.1 (the Page frame), §8.0.3 (row `novel` and its mobile alias `/novels/read/…`), §8.0.4, §8.0.5 (System bars, Back, Edge swipes, modal back order), §8.0.9, §8.0.10.
   - §8.14.2 (Column wipe and Dip entries, back target, iOS edge swipe rules), §8.14.6 ("The end" block), §8.14.12 (the Margins panel the novel reuses).
   - §8.15 entire (§8.15.1 to §8.15.9).
   - §10.1.2 and §10.1.6 (`End of chapter 12` is a Letter set; Flutter `SetHeading`), §11 (rows: tap zones 25 / 50 / 25, horizontal swipe in novel paged and novel scroll, over-scroll 140 px at the novel scroll bottom, left-edge vertical swipe, edge swipe back), §14.1, §14.3 (speaker tints are never the only signal), §14.4, §14.5, §14.6, §14.7 (the absolute 14–40 px body range, OS Bold Text), §15.3 (fonts in `pubspec.yaml` with their `OFL.txt`), §15.6, §15.7.
4. `docs/redesign/glass/DESIGN.md` §15.4 (the `paginateNovel(measure, type)`, `pageIndex`, `pageCount` row: "Flutter `TextPainter` pages in a `PageView`"; Glass's novel reader, `mobile/36`, will call the command you add).
5. `docs/redesign/inventory/mobile.md` S26 (items 1 to 23), N1 (Type panel), N2 (Contents sheet), N4 (only the parts the novel screen hosts), §5a K25 and K26, §6b.
6. `docs/redesign/inventory/capabilities.md` §1 (`cache.stale`, rate limits, 18+ absence), §13 (novel progress uses paragraph buckets), §15 (bookmarks: `media_type: "novel"`, `snippet`, `anchor_stale`), §19.1 and §19.2 (chapter text, attribution, `text_fingerprint`), §24.
7. `docs/redesign/00-baseline.md`.
8. The web twin `docs/redesign/prompts/web/14-cinematic-novel-reader.md`, and `docs/redesign/proof/web-14/report.md` when present.
9. `docs/redesign/proof/mobile-12/report.md` and `docs/redesign/proof/mobile-13/report.md` (the reader route page, `reader_system_ui.dart`, `mobile/06`'s `enterReader`, `SidePanelLayout`, `EdgeHud`, `EndStates`, `UpNextRail`, the Circle tab, `CinePagePhysics` and `shouldCommitTurn`).
10. Code: `mobile/lib/features/novels/` (all of `models/`, `providers/`, `utils/`, `repositories/`, and read `screens/novel_reader_screen.dart`, `widgets/novel_chapter_view.dart`, `widgets/novel_reader_chrome.dart`, `widgets/novel_type_panel.dart`, `widgets/novel_contents_sheet.dart` to find the logic you must extract), `mobile/lib/features/downloads/services/offline_novel_reader.dart`, `mobile/lib/features/downloads/providers/progress_outbox_provider.dart` and `bookmark_outbox_provider.dart`, `mobile/lib/skins/cinematic/tint.dart` (the Issue derivation from `mobile/04`), `mobile/lib/skins/cinematic/screens/reader/`, `mobile/pubspec.yaml` (`fonts:`), `mobile/test/features/novels/`.

## Preconditions

- `git log --oneline -25` shows the `mobile/13` commits; the Cinematic `PENDING` set lists `novel` and no longer lists `reader` or `readAll`.
- `grep -n "family: \(Newsreader\|Literata\|SourceSerif4\|AtkinsonHyperlegibleNext\|Archivo\|BodoniModa\)" mobile/pubspec.yaml` lists all six families (bundled by `mobile/03`). For any family that is missing, add it in its own commit before other work: the TTFs of §3.4 (`Newsreader[opsz,wght].ttf` + Italic, `Literata[opsz,wght].ttf` + Italic, `SourceSerif4[opsz,wght].ttf` + Italic, `AtkinsonHyperlegibleNext[wght].ttf` + Italic) from the Google Fonts GitHub repository into `mobile/assets/fonts/`, each family's `OFL.txt` registered through `LicenseRegistry.addLicense` where `mobile/03` registers the others.
- `grep -in "issue" mobile/lib/skins/cinematic/tint.dart` finds the Issue-stock derivation; if it does not, add it in this step with its test (§2.1.6: page = `ambient.tint`; ink = `ink.100` mixed 10 % toward `ambient.ink` in OKLab, then lightened in 0.01 L steps until ≥ 13:1 on the page; muted = `ambient.ink` darkened in 0.01 L steps until 5.5:1 on the page).
- Run `free -m`, then `/srv/manhwamaniacs/dev/flutter/bin/flutter test` from `mobile/` once and record the passed count as your floor (never below the 2012 of `00-baseline.md`: every test that passed there must still pass).

## Skills to invoke

1. `superpowers:writing-plans` before any code; plan at `docs/redesign/proof/mobile-14/plan.md`.
2. `superpowers:test-driven-development` for the extraction, the paginator, the preference migration and every pure helper.
3. `superpowers:subagent-driven-development` (or `superpowers:executing-plans` inline). At most 6 implementer subagents, one heavy command at a time, their work verified against `git status` and `git diff`.
4. `impeccable:impeccable` and `taste-skill:taste-skill` for the page typography (this screen is the skin's best argument for Newsreader and Bodoni Moda: measure, leading, the drop cap, no ornament beyond the rules); `frontend-design:frontend-design` only for the side-by-side review against the web twin's phone captures.
5. `superpowers:verification-before-completion` before claiming done.

## Scope: deliver every item below

### A. Skin-neutral data and engine work (no pixels, first commits)

A1. **Extract the novel reader logic** from `novel_reader_screen.dart` and `novel_chapter_view.dart` into `mobile/lib/features/novels/controllers/novel_reader_controller.dart` (a Riverpod `AutoDisposeFamilyNotifier` keyed by the chapter reference): the chapter window and seamless next (the next chapter swapped in at the top, the route location replaced without a navigation), prefetch of the next chapter, the paragraph-bucket progress save (debounced 500 ms as today, flushed on leave through the progress outbox, `is_completed` on seamless next), `furtherElsewhere` when a save answers `advanced: false`, the reading line as a parameter (`readingLineFraction`: the legacy screen passes its 0.25, the Cinematic skin passes 0.38), bookmark capture (paragraph anchor + fraction + a 180-character snippet through `novel_snippet.dart`), stale-anchor resolution, attribution loading with the `text_fingerprint` check, `?page=&para=&at=` restore with up to 30 frames of re-jumps, the auto-next after 900 ms at the end unless narration is playing, the offline copy through `offline_novel_reader.dart`. State: `chapter`, `paragraphs`, `attribution`, `readingBucket`, `bookPercent`, `nextState`, `furtherElsewhere`, `saved`, `stale`, `cacheStale`; commands: `next()`, `previous()`, `jumpToBucket(int)`, `bookmark()`, `markComplete()`. `NovelReaderScreen` switches to the controller in the same commit and keeps its pixels; every existing novel test (`test/features/novels/`, 21 files) stays green.
A2. **`paginateNovel(double measureCh, NovelType type)`** on the controller (glass §15.4), with state `pageIndex` and `pageCount`, over `mobile/lib/features/novels/engine/novel_paginator.dart`:
   - One shared paragraph layout, `NovelParagraphLayout`, used by both the painter (C, E) and the paginator, so a page can never clip a line: a `TextPainter` per paragraph with `TextScaler.noScaling`, the face style of A4, `textAlign` from `justify`, laid out at the column width.
   - Column width = min(`measureCh` × the advance width of `0` in the body style, viewport width − 2 × margin); page height = viewport height − the top and bottom reserved bands of the paged frame (the in-page head is not shown in paged mode; the page folio sits in a 40 px band at the bottom).
   - Pages are lists of `NovelPageSlice(paragraphIndex, startChar, endChar, continues)`. A paragraph that does not fit is split after the last whole line that fits (from `computeLineMetrics()` and `getLineBoundary(getPositionForOffset(Offset(0, lineBottom)))`); its continuation starts the next page with no indent. Scene breaks never split. The opener takes the first page's top.
   - Re-pagination on size change, Type change and after the fonts load keeps the first paragraph of the current page on screen.
   - Tests in `mobile/test/features/novels/novel_paginator_test.dart`: every character appears exactly once and in order across pages; no page's line heights sum beyond the page height; a size change keeps the anchor paragraph on the current page; page ↔ bucket mapping and clamping; a scene break is never split.
   - Pagination runs on the UI isolate (`TextPainter` needs `dart:ui`); log its duration for the fixture chapter in debug builds (`debugPrint('paginate: N paragraphs, T ms')`) for the owner device check.
A3. **Preferences, extended not replaced** (`novel_typography.dart`, `novel_palette.dart`, `novel_preferences_provider.dart`), keeping the legacy constants and fields so the legacy reader still works:
   - Per book, the existing K25 map `mm.novel-prefs.u{user}p{profile}` (keyed `source:series`): new `face` (`newsreader | literata | source-serif | atkinson | archivo`) with the read-time fallback from `fontFamily` (`serif` → `newsreader`, `sans` → `archivo`); `fontSize` now 14–40 (the legacy normaliser still clamps to its own 15–26 when it reads, and must not strip the new fields); `lineHeight` 1.30–2.10 step 0.05; `measure` 48–88ch step 2 (default 64 for the Cinematic skin when absent; stored values are kept); new `paragraphSpacing` 0–1.2em step 0.1 (default 0) and `letterSpacing` −0.02 to +0.08em step 0.01 (default 0).
   - Per profile, a new `mm.novel-settings.u{user}p{profile}` (JSON): `stock` (`nitrate | ink | sepia-night | dusk | moss | rosewood | issue`) with the read-time fallback from K26 `mm.novel-palette.u{user}p{profile}` (§2.1.6: `black`, `app` or no value → Nitrate; `paper`, `soft-grey` → Ink; `sepia`, `cream`, `dusk` → Sepia Night; `midnight`, `solarized-dark`, `solarized-light` → Dusk; `forest` → Moss; `rose-pine`, `dawn` → Rosewood), `margins` (`NARROW | STANDARD | WIDE`, default `STANDARD`), `bold` (false), `justify` (false), `layout` (`SCROLL | PAGED`, default `SCROLL`), `pageTurn` (`CUT | SLIDE | FADE`, default `CUT`), `tapZones` (`STANDARD | BOTH_MARGINS | ONE_HAND`, default `STANDARD`), `swipeChapter` (false), `brightness` (−75…0, default 0).
   - Normalisers keep unknown fields. Tests: every migration mapping, range clamps, unknown-field preservation through a legacy write, two profiles isolated.
A4. **Faces and sizes** (§3.4, §3.3): `faceDefaults(NovelFace face, {required bool tablet})` in `novel_typography.dart` (+ test): size 18 on phones and 19 on tablets (shortest side ≥ 600) for Newsreader, Literata, Source Serif and Atkinson; 17 / 18 for Archivo; leading 1.60 (Newsreader, Literata, Source Serif, Archivo) and 1.70 (Atkinson). A book with no stored size opens at `clamp(round(MediaQuery.textScalerOf(context).scale(d)), 14, 40)` for the face default `d` (system 2.0 starts Newsreader at 36 px, Archivo at 34 px); the value is stored per book once changed. A book with no stored face uses Newsreader, or Atkinson when Hyperlegible text is on (`legibleTextProvider`, derived from `mobile/04`'s `a11yPrefsProvider` over `mm.boot.a11y.u{user}p{profile}` (`legible`), the one store `CineType` and `mobile/18`'s Settings switch use; if `grep -rn "legibleTextProvider" mobile/lib` finds nothing, create `a11yPrefsProvider` and `legibleTextProvider` exactly as `mobile/04` specifies them, never a second key). The `newsreader` face always uses the `Newsreader` asset family, so Hyperlegible text never changes a book stored as `newsreader`. Axes: `FontVariation('opsz', size clamped to the face's range: Newsreader 6–72, Literata 7–72, Source Serif 8–60)`, `FontVariation('wght', 400)`, or 520 with Bold text; OS Bold Text (`MediaQuery.boldTextOf`) adds 120 as well, clamped to the axis maximum. `FontFeature.oldstyleFigures()` in Newsreader, Literata and Source Serif. Archivo uses `wdth` 100, `wght` 400.

### B. Route, frame and system bars

B1. ScreenId `novel` at `/novels/:sourceId/:seriesKey/:chapterKey` with `?page&para&at&listen=1`, plus the alias `/novels/read/:sourceId/:seriesKey/:chapterKey`; root navigator; decode once; encoded builders from `contract.g.dart`. `listen=1` is read by `mobile/15`; ignore it here.
B2. The route uses `mobile/12`'s reader `SwipeablePage`: Column wipe (616 ms phone, 744 ms tablet) from Tonight, the book page (`Start reading`, `Continue`, a contents row) or a recap opened from them; Dip (440 ms) from History, Bookmarks, Updates, Downloads, Library cuttings, Circle, notifications and deep links; exit always by Dip. Back target: pop when `context.canPop()`, otherwise `go(Routes.feature(sourceId, seriesKey))` to the book page, which enters by Dip. iOS: the 20 pt edge swipe is live only in the scroll layout and pops without a Dip. Android: `PopScope` back plays the Dip, no predictive preview.
B3. System bars through `mobile/12`'s `reader_system_ui.dart`: on entry iOS `manual` with `overlays: []`, Android `immersiveSticky`; the status bar shows with the chrome (`manual`, `[SystemUiOverlay.top]`) at the start of its 240 ms fade-in and hides at the start of its 160 ms fade-out; on exit `edgeToEdge` with the transparent light style. The column ignores system insets, so toggling the bars never reflows the text.
B4. The Page frame (§8.0.1): no app chrome; everything is painted in the stock. Toasts use the stock's page colour for the band and its ink for the text, placed per §7.11 16 px above the bottom bar (24 px above the bottom edge when the chrome is hidden).
B5. Semantics: the reading surface has a `FocusNode` that takes focus on entry and `Semantics(label: 'Chapter 12, 42 percent')`; a live region announces "Chapter 12, The Tower · Omniscient Reader's Viewpoint" on entry and on every chapter change (drop the middle part when there is no title).

### C. Stocks (§2.1.6): the page, painted edge to edge

| Stock | Page | Ink | Muted |
|---|---|---|---|
| Nitrate (default) | `#000000` | `#D9D6D0` | `#8A877F` |
| Ink | `#0B0B0C` | `#E6E3DD` | `#8F8C86` |
| Sepia Night | `#15110C` | `#E8D8BE` | `#9C8E78` |
| Dusk | `#0D1117` | `#D3DAE3` | `#8590A0` |
| Moss | `#0E130F` | `#D5DECF` | `#879384` |
| Rosewood | `#160E10` | `#EBD5D8` | `#A08A8E` |
| Issue | the series' `ambient.tint` | derived in `tint.dart` (≥ 13:1) | derived in `tint.dart` (≥ 5.5:1) |

C1. Read the generated fields (`colorStockNitratePage`, `colorStockNitrateInk`, `colorStockNitrateMuted` and the others). The frame provides one `CineStock.stock(CineStockColors(page, ink, muted))` scope (an `InheritedWidget` beside `CineStock.raised`; `CineStockColors` is defined in `page_frame.dart`) that every part of the page, chrome, sheets, panels and toasts paints from. Issue resolves per book from `CineAmbient` and falls back to Nitrate when the series has no `ambient`.
C2. Inside the stock scope every `ink.45` role renders the stock's muted colour (§2.1.1). Add the six fixed stocks and the Issue pair to the surface × ink loop in `test/skins/cinematic/tint_test.dart` if `mobile/04` did not.
C3. The profile's mood grade never reaches the page.

### D. Layout (§8.15.1)

D1. Phone (shortest side < 600): the column fills the width minus the margin preset (`NARROW` 16, `STANDARD` 24, `WIDE` 48 px).
D2. Tablet and landscape phone: the measure-limited column (A2's width rule, default 64ch) centred inside the safe rectangle; no chrome control inside a horizontal inset (§2.2.2).
D3. In-page running head at the top of the chapter (scroll layout): the series title and the chapter kicker on the left in `type.kicker` (stock muted), the `42%` folio on the right in `type.folio`; its opacity follows its distance from the top of the viewport over 120 px as it scrolls away; under reduced motion it simply scrolls away.

### E. The chapter (§8.15.2)

E1. Opener: kicker `CHAPTER 12` in `type.kicker` (stock muted); the title in Bodoni Moda Roman at 1.9 × the body size (stock ink, `opsz` = min(size, 96), sentence case), as `Semantics(header: true, headingLevel: 1)`; a 48 px rule (1 px, stock muted); a facts line in `type.folio` (`3.4K WORDS · 14 MIN`, from the existing 250 wpm estimate). The `Listen │ 14 MIN` button is added by `mobile/15`.
E2. Body, painted by one `NovelParagraph` widget (`mobile/lib/skins/cinematic/screens/novel/novel_paragraph.dart`): a `CustomPainter` over the paragraph's cached `NovelParagraphLayout` that paints, in order, the decoration backgrounds, the text (`TextPainter.paint`), then the decoration strokes; decoration geometry comes from `getBoxesForSelection` for each run, so `mobile/15` can add the Listen highlighter band and the spoken-word underline as further decorations. The chosen face at the chosen size (absolute, 14–40) and leading; paragraphs indented 1.3em except the first and any paragraph after a scene break; `paragraphSpacing` adds space between paragraphs and removes the indent when > 0; `letterSpacing` applies to the body only; `bold` sets `wght` 520; `justify` sets `TextAlign.justify` (Flutter has no automatic hyphenation, so the text justifies without hyphens; keep the row's label and record this in the report); otherwise ragged right.
E3. Drop cap: the first paragraph, only when it is ≥ 80 characters, gets a Bodoni Moda `wght` 800 drop cap three lines tall from `CineType.dropcap(lineHeightPx)` (size 3 × line height, `opsz` min(size, 96), tracking −0.02em), in the stock ink, with 0.08em between the cap and the text. `NovelParagraphLayout` lays the first three lines at the width minus the cap's advance plus that gap and the rest at full width, and the paginator uses the same layout. The paragraph's semantics label is the full text, so the word stays intact for screen readers.
E4. Scene breaks: a paragraph of ≤ 12 ornament characters (`*`, `#`, `~`, `•`, `·`, `-`, `—`, `=`, `◇`, `❖`, `⁂`, spaces; reuse the detection the legacy view uses) renders as a centred 32 px rule (1 px, stock muted) with 24 px above and below, excluded from semantics.
E5. Speaker tints, only when `attribution.attributed` is true and its `text_fingerprint` matches the text on screen. The cast order (by line count, busiest first) assigns slots 1–10 from `colorSpeaker1` … `colorSpeaker10`:

| Slot | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| Hue | `#7CC4FF` | `#FF8A7A` | `#9BE08A` | `#D6A3FF` | `#FFC266` | `#6FE3D6` | `#FF9FCB` | `#C9B38A` | `#A6B4FF` | `#E0E0A0` |

   Slots 11+ reuse 1–10 with a dotted underline. Each attributed run gets its slot colour as a 2 px underline at 70 % alpha, whose top sits 0.18em below the line's baseline (from `computeLineMetrics()`; dotted = 2 px on, 2 px off), and a background at 12 % alpha over its boxes; the text keeps the stock ink; narration is never tinted. A 450 ms long-press on a tinted run (`LongPressGestureRecognizer(duration: Duration(milliseconds: 450))` on the paragraph; the hit is mapped with `getPositionForOffset` to the run) shows the speaker's name in a small popover (`KIM DOKJA` in `type.kicker`, stock page ground, 1 px stock-muted border), haptic `longpress.open`. Semantics: the paragraph label carries "Kim Dokja: " before each attributed run. Put the slot assignment in `mobile/lib/features/novels/utils/speaker_slots.dart` (+ test: ordering, the 11th speaker, a stale fingerprint returns no tints).
E6. End matter: 96 px of space, a 96 px rule, `End of chapter 12` in `type.section` through `SetHeading` (the Letter set), the facts line (`READ IN 14 MIN`), the reactions slot (an optional widget, filled by `mobile/22`), then the next card in stock colours: kicker `NEXT`, `Chapter 13` in Bodoni Moda (`type.subhead` size), the chapter title, `→`, the whole card one button (it advances seamlessly). Without a next chapter: "You've reached the last chapter this source has published."; for a Completed book whose last chapter completes, `mobile/12`'s The end block in stock colours (`THE END`, "You finished {title}.", the `Up next` rail, `Mark as done`). Then `Previous chapter` and `Back to the book`.
E7. Seamless next: over-scrolling 140 px at the bottom (accumulated from `OverscrollNotification`s while dragging; haptic `scrub.boundary`), `l`, or the next card marks the chapter complete (`chapter.complete`, sound `done`) and swaps the next chapter in at the top with the location replaced (no navigation, no wipe); the live region announces it. With "Auto next chapter" on (the per-profile `autoNextChapter` of `mobile/12`'s preferences record), reaching the end advances after 900 ms unless narration is playing.

### F. Chrome (§8.15.3)

F1. A tap anywhere toggles the chrome; it fades in 240 ms (`durLine`) `settle` and out 160 ms (`durBeat`) `lift`, never slides; hidden chrome is `Offstage`.
F2. Solid stock-coloured bars with a 1 px rule in the stock's muted colour at 30 %:
   - Top: 52 px + `MediaQuery.viewPaddingOf(context).top`: back (`arrow-left`, "Back to the book"), the running title (`type.nav`, stock muted, `{SERIES} · CHAPTER 12`), the offline mark (`wifi-slash`) when reading a saved copy, the `SAVED COPY · 3 H` micro badge when `cache.stale`, then as an ordered list: contents (`list-numbers`), bookmark (`bookmark-simple`; Fill when saved), type (`text-aa`), on tablets the margins toggle (`note-pencil`). `mobile/15` inserts voices (`voice-31`) after bookmark and `mobile/23` inserts the soundscape indicator.
   - Bottom: 52 px + bottom inset: previous chapter; the progress folio `42% · 6 MIN LEFT` in `type.folio` (a tap cycles chapter %, book %, time left; a 450 ms press or `g` turns it into a number field `42 %` with `TextInputType.number`, IME done jumps to that paragraph bucket, the back gesture or `Esc` cancels); next chapter; a 1 px progress hairline along the top edge of the bar in the stock ink. The auto-scroll button is added by `mobile/23`.
F3. Auto-hide: hides on a downward scroll ≥ 24 px, shows on an upward scroll ≥ 56 px, at chapter end or on a tap; never while the chrome's `FocusScopeNode` has focus; never while a screen reader runs; when a command hides it while it holds focus, focus moves to the reading surface.
F4. Margins panel on tablets (`note-pencil`, `m`): `mobile/13`'s right column panel in the stock colours (page ground, 1 px stock-muted rule at 30 %), over the page, one side panel at a time, with contents tabs `NOTES · CIRCLE · VOICES`: NOTES lists this chapter's bookmarks and notes with `Add a note to this paragraph`; CIRCLE reuses `mobile/13`'s Circle tab with the spoiler guard (unsealed on chapter complete); VOICES is appended by `mobile/15` (build the tab list as an ordered list). §8.15.3 names this panel for desktop; the app offers it on tablets as the manga reader does (§8.14.12, "column panels on tablets"); record the reading in the report.
F5. Every chrome button is `bare` with a 44 × 44 (iOS) / 48 × 48 (Android) hit, a tooltip and a semantics label.

### G. Reading modes and page turns (§8.15.4)

G1. Scroll (default): one continuous column (a `ListView.builder` of `NovelParagraph`s) with seamless next (E7).
G2. Paged (Type sheet → Layout): `paginateNovel` pages in a `PageView.builder`; the page folio `p. 7 of 22` (this chapter) in the bottom band, centred, `type.folio` stock muted, spoken "page 7 of 22".
G3. Turns: `CUT` (default, 0 ms), `SLIDE` (280 ms `settle`; swipes track the finger through `mobile/13`'s `CinePagePhysics` (`mobile/lib/skins/cinematic/screens/reader/cine_page_physics.dart`, passed to the paginated `PageView`) and the engine's `shouldCommitTurn`: 72 px or 600 px/s, release on `CineSprings.release`), `FADE` (160 ms). No curl. Haptic `page.turn`, sound `turn` if on. Reduced motion: every turn is a 150 ms opacity cross-fade.
G4. Tap zones: `STANDARD` 25 / 50 / 25 % (back / menu / forward); `BOTH_MARGINS` (both 25 % side zones go forward, the centre is menu); `ONE_HAND` (left 25 % back, the top 12 % across the full width menu, the rest forward). In scroll mode a tap only toggles the chrome. Pure mapping in `mobile/lib/features/novels/utils/novel_tap_zones.dart` (+ test).
G5. Progress is always the paragraph bucket (1–100) at the reading line: 38 % from the top in scroll mode, the first paragraph on the page in paged mode.
G6. The last page of a chapter in paged mode is followed by the end matter as its own page; turning past it swaps the next chapter in at page 1.

### H. Type sheet "Text and page" (§8.15.5)

H1. Opened by `text-aa`, `t` and `,`: a `CineSheetRoute` with detents `[0.5, 0.92]` (max 720 wide on tablets), painted in the current stock so the preview is honest, kicker `TEXT AND PAGE`, `quiet` `Done`. Every change applies live under it; steppers roll their digits (Folio flip). Haptics: `select` on segments, tiles and swatches, `toggle.on` / `toggle.off` on switches, `sheet.detent` on settle.
H2. Rows, exactly:

| Control | Range | Default | Scope |
|---|---|---|---|
| Face | Five tiles, each label set in its own face: `Newsreader`, `Literata`, `Source Serif`, `Atkinson Hyperlegible`, `Archivo`; a caption under Atkinson reads "Designed for low vision"; the chosen tile has a 2 px `spot` frame | Newsreader (Atkinson when Hyperlegible text is on) | per book |
| Size | 14–40 px, stepper step 1 | the face default (A4) | per book |
| Line spacing | 1.30–2.10, stepper step 0.05 | the face default (A4) | per book |
| Measure | 48–88ch, stepper step 2 | 64 | per book |
| Margins (phones) | `NARROW · STANDARD · WIDE` (16 / 24 / 48 px) | Standard | per profile |
| Paragraph spacing | 0–1.2em, stepper step 0.1 | 0 (indents) | per book |
| Character spacing | −0.02 to +0.08em, stepper step 0.01 | 0 | per book |
| Bold text | switch (wght 400 → 520) | off | per profile |
| Justify and hyphenate | switch | off (ragged) | per profile |
| Layout | `SCROLL │ PAGED` | Scroll | per profile |
| Page turn | `CUT │ SLIDE │ FADE` (paged only) | Cut | per profile |
| Tap zones | `STANDARD │ BOTH MARGINS ADVANCE │ ONE HAND` (paged only) | Standard | per profile |
| Swipe sideways to change chapter | switch (scroll layout) | off | per profile |
| Stock | Seven 48 × 48 swatches, each showing "Aa" in its own ink on its page, the chosen one with a 2 px `spot` frame: Nitrate, Ink, Sepia Night, Dusk, Moss, Rosewood, Issue (drawn in this book's `ambient` colours; hidden when the series has no `ambient`) | Nitrate | per profile (Issue resolves per book) |
| Reset | a `quiet` `Reset text and page`, which restores every row above to its default at once | — | — |

   The Fullscreen row is web-only. The `AMBIENT` group (auto-scroll, speed, resume, soundscape, volume) is appended by `mobile/23`: keep the rows as an ordered list. Each row states its scope in a `type.caption` line (stock muted): "Saved for this book", "Saved for this profile" or "For this reading only".
H3. Semantics: face tiles and stock swatches are `Semantics(inMutuallyExclusiveGroup: true, checked: …)` with names ("Sepia Night"); steppers are buttons labelled "Larger text" / "Smaller text" with a live value; every control reachable with a hardware keyboard.

### I. Contents (§8.15.6)

I1. Opened by `list-numbers` and `o`. Phones: a `CineSheetRoute` `[0.5, 0.92]` pre-scrolled to the current chapter; tablets: the left column panel (`mobile/12`'s `SidePanelLayout` left slot, over the page) in the stock colours. Do not build a second contents list: `mobile/11` already built the §8.15.6 sheet for the book page (`mobile/lib/skins/cinematic/screens/feature/book/contents_sheet.dart` and `contents_row.dart`, N2). Extend those two widgets with an optional `CineStockColors? stock` parameter (with `null` they stay exactly as the book page renders them today: `paper.2`, `rule.2` top edge, `spot.wash` current row; the book page's widget tests must pass unchanged) and a `currentChapterKey` for the pre-scroll, and wrap them here for the reader's sheet and tablet panel.
I2. Kicker `CONTENTS`; a go-to field ("Chapter number", `TextInputType.numberWithOptions(decimal: true)`; IME done jumps to the first match; typing shows up to 30 matches and "and 12 more"; no match reads "No chapter 480 in this book."); then contents rows (§7.16 novel variant, 48 px: ordinal `type.folio` right-aligned → title in Newsreader 16 → dot leaders → length `12 MIN` → state mark: `42%` in `spot`, `READ`, the headphones glyph when narrated from `GET /novels/audio/series`, the §7.18 download mark), in a `ListView.builder`, pre-scrolled to the current chapter on its `spot.wash` band (semantics "current"). A tap opens that chapter by Dip.
I3. States as notices: loading (10 greeked rows), offline ("The contents need a connection to load."), error (`CORRECTION` + `Try again`).

### J. Bookmarks and notices (§8.15.7)

`b` or the bookmark button saves the paragraph at the reading line plus its fraction and a 180-character snippet through the bookmark outbox (`media_type: "novel"`), with no dialog (haptic `bookmark.add`, sound `set`); the toast offers `Add a note` (a note field inline in the toast's place; IME done saves). A stale anchor opens at the nearest paragraph with the toast "The text here changed. Opened at the nearest paragraph." Failure: "Couldn't save that spot." with the `proof` edge (6000 ms).

### K. Hardware keys (§8.15.8), a "Novel reader" group in `mobile/06`'s shortcut registry

`h` / `l` (previous / next chapter), `j` / `k` and `Space` / `Shift+Space` (scroll or page forward / back), `Home` / `End` (chapter start / end), `=` `+` / `-` / `0` (text size up, down, reset to the face default), `t` and `,` (Type sheet), `o` (Contents), `b` (bookmark), `m` (Margins panel on tablets), `g` (go to %), `Esc` (close sheet or panel → back to the book). `p`, `[`, `]`, `Shift+[`, `Shift+]` and the Listen meaning of `<` / `>` are `mobile/15`; `a` and the auto-scroll meaning of `<` / `>` are `mobile/23`. The escape order is a pure reducer (`novel_keys.dart` + test) that `mobile/15` extends. The "Single-key shortcuts" setting disables every unmodified binding.

### L. Gestures (§8.15.8, §11)

A tap toggles the chrome (scroll) or acts by zone (paged); a 450 ms press on a tinted run shows the speaker's name (E5); a horizontal swipe turns pages in paged mode and, when `swipeChapter` is on, changes chapter in scroll mode (≥ 72 px or 600 px/s, within 30° of horizontal, starting ≥ max(24 px, the system gesture inset) from both edges; `mobile/12`'s recognizer; the next chapter swaps in as in E7, haptic `chapter.next`); a left-edge (12 %) vertical swipe changes `brightness` (−75 … 0) with `mobile/12`'s `EdgeHud` over an `IgnorePointer` `#000000` layer at alpha `|v|/100`; over-scroll 140 px at the bottom opens the next chapter; the iOS edge back and Android back (B2).

### M. States (§8.15.9), every one

| State | Presentation |
|---|---|
| Loading | The page in the stock colour with 12 greeked lines at the body's line height (`colorGalley` bars at the §7.17 ragged widths 92, 78, 96, 64, 88 %, Flicker at half strength: opacity 0.775 ↔ 1, 1400 ms half-period; static at 0.8 under reduced motion) |
| Offline | Reads the saved copy; the top bar shows `wifi-slash`; at the end of the last saved chapter the end matter reads "End of the downloaded copy." with `Back to Downloads` in place of the next card |
| Error | Notice "Couldn't load this chapter." + `Back to the book` |
| Not available (removed source or series, or hidden by the gate) | The §8.0.10 `NOT IN THIS ISSUE` notice in the stock colours, identical for every cause |
| 18+ book | The rating card (§7.24) at the top-left of the page for its 3000 ms hold, in the stock colours |
| Empty | "This chapter came through empty — usually a page that was pulled or is still being published." |
| Stale text | Speaker tints (and, in `mobile/15`, follow-along) are withheld when the fingerprint does not match |
| Rate limited | The `SLOW DOWN` band with the live `Retry-After` countdown |
| Further on another device | Toast in stock colours "You're further ahead on another device (CH 214, 38%). Jump there?" with `Jump` (8000 ms) |
| Saved copy (`cache.stale` true) | The `SAVED COPY · 3 H` micro badge in the top bar (1 px stock-muted outline, stock-muted text); a tap shows the tooltip "The source is down; this is the last copy we saved." |

## Out of scope here (owned by later steps)

- `mobile/15`: the opener's `Listen │ 14 MIN` button, `p`, the voices button and the `VOICES IN THIS CHAPTER (5)` line, the VOICES tab, the mini player and full player, `[` `]` `Shift+[` `Shift+]`, `?listen=1`, the follow-along highlight (it adds decorations to `NovelParagraph`).
- `mobile/19`: the `PREVIOUSLY ON` chip. `mobile/22`: reactions in the end matter. `mobile/23`: the Type sheet `AMBIENT` group, auto-scroll and its chip, the soundscape and its indicator.

## File layout

```
mobile/lib/features/novels/controllers/novel_reader_controller.dart     A1 (legacy NovelReaderScreen switched to it)
mobile/lib/features/novels/engine/novel_paginator.dart                  A2 (+ test/features/novels/novel_paginator_test.dart)
mobile/lib/features/novels/engine/novel_paragraph_layout.dart           A2, E2, E3 (shared by painter and paginator; + test)
mobile/lib/features/novels/models/novel_typography.dart, novel_palette.dart, providers/novel_preferences_provider.dart   A3, A4 (extended; + tests)
mobile/lib/features/novels/utils/speaker_slots.dart (+ test)            E5
mobile/lib/features/novels/utils/novel_tap_zones.dart (+ test)          G4
mobile/lib/features/settings/providers/a11y_prefs_provider.dart         A4 (only if mobile/04's a11yPrefsProvider / legibleTextProvider are absent; exactly mobile/04's shape)
mobile/lib/skins/cinematic/screens/novel/
  novel_reader_screen.dart   composition: controller, frame, chrome, sheets, panels, keys (ScreenId novel)
  page_frame.dart            the CineStock.stock scope, brightness layer
  stocks.dart                the stock table, K26 fallback, Issue resolution (+ test)
  in_page_head.dart          D3
  chapter_opener.dart        E1
  novel_paragraph.dart       E2–E5 (painter, decorations, long-press popover, semantics)
  end_matter.dart            E6
  top_bar.dart, bottom_bar.dart, progress_folio.dart           F1–F3
  novel_margins_panel.dart   F4
  paged_columns.dart         G2, G3, G6
  type_sheet.dart, type_rows.dart                              H
  novel_contents.dart        I (the reader's sheet and panel wrapper around mobile/11's contents_sheet.dart / contents_row.dart, which gain the optional stock parameter)
  novel_keys.dart            K (+ test)
mobile/lib/skins/cinematic/tint.dart (+ tint_test.dart)         Issue stock, only if missing
mobile/lib/skins/cinematic/router.dart                          novel route and alias, remove novel from PENDING
mobile/test/skins/cinematic/novel/                              widget tests
mobile/test/fixtures/novel/                                     chapter and attribution fixtures (proof and tests)
docs/redesign/proof/mobile-14/                                  plan.md, screenshots, device-checklist.md, report.md
```

## Acceptance criteria

- [ ] The extraction commit changes no legacy pixels (the legacy harness capture before and after is identical) and every existing novel test passes.
- [ ] `novel` is removed from the Cinematic `PENDING` set; the completeness and import-boundary tests pass.
- [ ] All seven stocks paint the page, chrome, sheets, panels and toasts from the stock scope; Issue follows the book's `ambient` and is hidden without it; K26 values migrate per the table; `tint_test.dart` asserts Issue ink ≥ 13:1 and muted ≥ 5.5:1 over the loop.
- [ ] The five faces render in their own face on the tiles and in the body; the default size follows the system text scale on first open (36 px at 2.0 in Newsreader) and is absolute afterwards; Hyperlegible text makes Atkinson the default for books without a stored face and never changes a book stored as `newsreader`.
- [ ] Opener, drop cap (only for a first paragraph ≥ 80 characters, full word in semantics), indents, scene-break rules, speaker tints with the 2 px underline and 12 % background, the long-press name popover and the "Kim Dokja: " semantics prefix, end matter with the Letter set and the next card all match §8.15.2.
- [ ] Seamless next swaps the next chapter in at the top with the location replaced, by over-scroll 140 px, `l` and the next card; auto next after 900 ms works when on; the live region announces it.
- [ ] Chrome fades in 240 ms and out 160 ms with no slide; the status bar appears and hides with it on both platforms (mocked `SystemChannels.platform` test); auto-hide follows 24 / 56 px; focus inside the chrome and a running screen reader both prevent hiding.
- [ ] Paged mode paginates with `paginateNovel` (the paginator tests prove no clipped line and no lost or duplicated character), re-paginates on size and Type changes keeping the current paragraph, shows `p. 7 of 22`, turns with Cut, Slide (finger-tracked) and Fade, and honours the three tap-zone presets.
- [ ] The Type sheet has every row of H2 with its range, default and scope caption, opens at the half detent with the page live above it, and is painted in the stock.
- [ ] Contents: the go-to field matches up to 30 with "and 12 more" and "No chapter 480 in this book."; rows show narrated and saved marks; the current chapter sits on its `spot.wash` band; the tablet panel and the phone sheet both work; offline and error notices render.
- [ ] Bookmark by `b` with no dialog, `Add a note` in the toast, stale-anchor toast copy exact; progress saves the paragraph bucket at the 38 % reading line (scroll) and the first paragraph on the page (paged).
- [ ] Every state of M renders in the stock colours (harness screenshots).
- [ ] Hardware keyboard: every key of K works in a widget test; the escape order is exact; the reading surface takes focus on entry.
- [ ] Hit targets: every control in the bars, sheets and panels is ≥ 44 × 44 under `TargetPlatform.iOS` and ≥ 48 × 48 under `TargetPlatform.android` (widget test).
- [ ] Reduced motion: the chrome fades only, page turns are 150 ms fades, the Letter set is a 200 ms fade, panels fade in place, the in-page head scrolls away without fading; leader dials keep running.
- [ ] Per-skin difference: with `Edition (debug)` on `LEGACY` the legacy novel reader and its type panel look and behave as before and still read and write K25 and K26.
- [ ] `flutter analyze` reports no issues; `flutter test` passes at or above the floor plus the new tests.

## Verification

**RAM guard.** Before every heavy command run `free -m`; if the `available` figure of the `Mem:` row is under 1024 MB, stop and report. One heavy command at a time; never alongside a `next build`; no Gradle or Xcode on this box.

From `mobile/`:

```bash
free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze
free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter test test/features/novels test/skins
free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter test
```

`flutter analyze` reports "No issues found"; the full suite passes at or above the floor. This step changes nothing in `frontend/` or `backend/` (`git show --name-only --format= <hash> -- frontend backend` for each of your own commits (never a branch or range diff: parallel sessions commit on the same branch) is empty), so `npm run lint`, `npm run build` (in `frontend/`) and the backend pytest (`backend/.venv/bin/python -m pytest -q --no-header` from `backend/`) are not rerun, except the push rule under Git.

**Fixtures.** `mobile/test/fixtures/novel/chapter.json`: copy the paragraphs of `frontend/e2e/fixtures/novel/chapter.json` when the web twin has written it; otherwise write the first chapter of Lewis Carroll's *Alice's Adventures in Wonderland* (public domain, Project Gutenberg #11) split into paragraphs, with one scene-break paragraph `* * *` inserted after paragraph 12 so the rule renders. `attribution.json` tints the chapter's two speakers (Alice in slot 1, the White Rabbit in slot 2; narration stays untinted) with a `text_fingerprint` that matches, and `attribution-stale.json` with one that does not. A second, 12,000-word fixture (the chapter's paragraphs repeated) is used by the paginator test and the pagination timing.

**Proof output location.** The `mobile/03` harness (`mobile/test/screenshots/support/skin_shots.dart`) writes a capture only when `MM_PROOF_DIR` is set, so every proof command below sets `MM_PROOF_DIR=../docs/redesign/proof/mobile-14` (relative to `mobile/`) and never `MM_WRITE_SHOTS`, which makes the legacy marketing tests overwrite `mobile/docs/screenshots/`, the install page's public screenshots. Capture routes with `captureSkinScreen` and anything that is not a route (a sheet held open, a state pumped with fixture providers) with `captureSkinWidget`, at the harness sizes: `kSkinShotSizes` (phone 390 × 844, tablet 834 × 1194), `kSkinShotTabletWide` (1024 × 1366, the ≥ 900 px rows of §8.0.9) and `kSkinShotLandscape` (landscape phone 844 × 390). After the run, `git status --short mobile/docs/screenshots` must print nothing.

**Visual proof.** In the harness `mobile/03` extended (`grep -rln "docs/redesign/proof" mobile/test/screenshots`), add a `mobile-14` group with fake providers over the fixtures and run `free -m && MM_PROOF_DIR=../docs/redesign/proof/mobile-14 /srv/manhwamaniacs/dev/flutter/bin/flutter test test/screenshots/marketing_screenshots_test.dart --plain-name "mobile-14"` at phone 390 × 844, tablet 834 × 1194 and landscape phone 844 × 390, into `docs/redesign/proof/mobile-14/`:

- `novel-{nitrate,ink,sepia-night,dusk,moss,rosewood,issue}-phone.png` (chrome shown on one, hidden on the rest), `novel-nitrate-tablet.png`, `novel-landscape.png`.
- `novel-opener-dropcap-phone.png`, `novel-scene-break-phone.png`, `novel-speaker-popover-phone.png`, `novel-end-matter-phone.png`, `novel-the-end-phone.png`.
- `novel-faces-{newsreader,literata,source-serif,atkinson,archivo}-phone.png`, `novel-text-scale-2-phone.png` (system scale 2.0, first open at 36 px).
- `novel-paged-{phone,tablet}.png`, `novel-paged-slide-midturn-phone.png`, `novel-paged-one-hand-phone.png`.
- `novel-type-sheet-phone.png`, `novel-type-sheet-full-phone.png` (0.92 detent), `novel-contents-sheet-phone.png`, `novel-contents-panel-tablet.png`, `novel-contents-no-match-phone.png`, `novel-margins-tablet.png`, `novel-progress-field-phone.png`, `novel-brightness-hud-phone.png`.
- `novel-{loading,offline-end,error,not-available,empty,rate-limited,saved-copy,rating-card}-phone.png`.
- `novel-reduced-motion-phone.png`, `novel-legacy-phone.png`.
- Compare the phone captures with `docs/redesign/proof/web-14/*-phone.png` when present and list differences in the report.
- `docs/redesign/proof/mobile-14/device-checklist.md` for the owner (iPhone via SideStore, Android flagship): each face renders from the bundle with no network, the pagination time of the 12,000-word fixture chapter from `flutter logs` (budget 16 ms; report the figure), Slide turns at 120 Hz with 0 dropped frames, the status bar with the chrome, iOS edge back in the scroll layout only, Android back plays the Dip, the drop cap at sizes 14, 18 and 40, VoiceOver and TalkBack reading the "Kim Dokja:" prefix and the chapter announcement, system text scale 1.0, 1.3 and 2.0, OS Bold Text on.
- `docs/redesign/proof/mobile-14/report.md` mapping each screenshot to its acceptance item.

## Git

- Branch `feat/vps-slim-source-native`; the extraction first as its own no-pixel commit, then the paragraph layout and paginator with tests, the preferences with tests, then each screen part, then fixtures and proof. Stage paths explicitly, never `git add -A` or `git add .`.
- No Claude or AI attribution anywhere (no `Co-Authored-By`, no "Generated with", no AI author); never commit secrets or `.claude/`.
- Before every push: `git fetch origin` and `git diff --stat origin/feat/vps-slim-source-native...HEAD -- frontend`; if it lists files, run `free -m && npm run build` in `frontend/` first (never while `flutter test` runs) and push only if it passes. Then `git push origin feat/vps-slim-source-native:master` after each working step.
- Never edit `backend/connectors/`; never touch production containers or `/srv/manhwamaniacs/{app,data}`; do not deploy.

## Report back

1. Done items by scope letter A–M, and anything not done with the reason.
2. The screenshot folder `docs/redesign/proof/mobile-14/` and its file list; which fixture chapter was used; differences against the web twin.
3. Test counts (`flutter test` passed before and after), `flutter analyze` result, `free -m` before each heavy command.
4. The exact API of `NovelReaderController`, `paginateNovel`, `NovelParagraphLayout` and the `NovelParagraph` decoration model (names, arguments, state fields), for `mobile/15`, `mobile/23` and the Glass novel reader (`mobile/36`).
5. Whether fonts, the Issue derivation or `legibleTextProvider` had to be added here.
6. Interpretations made (justify without hyphenation, the tablet Margins panel, tablet default sizes) and every place where `cinematic/DESIGN.md` overrode this file.
7. The owner device checklist path and open issues.

Next prompt: `docs/redesign/prompts/mobile/15-cinematic-listen-mode.md`.
