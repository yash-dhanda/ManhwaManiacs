# mobile/14 report: Cinematic novel reader

## Done, by scope letter
- A1 controller (`features/novels/controllers/novel_reader_controller.dart`); legacy `NovelReaderScreen` renders it, all 21+ existing novel tests pass. A2 `paginateNovel` + `NovelParagraphLayout` + `novel_paginator.dart`. A3 preferences (K25 record kept verbatim in `raw`, `resolveNovelType`), A4 faces/defaults/axes.
- B route `novel` (+ alias), Dip/Wipe page, page key = book + nonce so the seamless next replaces the location on the same page; system bars follow the chrome; Page frame; semantics and live region.
- C stocks (`stocks.dart`, K26 migration, Issue via `issueStock`); the stock scope re-provides the surface and ink tokens so sheets, panels and toasts paint in the stock.
- D layout, E opener, body painter, drop cap, scene breaks, speaker tints + 450 ms popover + "Name: " semantics, end matter, seamless next (over-scroll 140 px, `l`, card, auto next 900 ms).
- F chrome (fade only, auto-hide 24/56 px, focus and screen-reader guards), tablet Margins panel (NOTES, CIRCLE), G scroll and paged (Cut/Slide/Fade, tap zones), H Type sheet (every row), I Contents (sheet and panel), J bookmarks, K keys, L gestures (swipe chapter, brightness edge, over-scroll), M states.

## Not done / partial
- The `Listen` button, voices, follow-along, reactions, ambient rows are later steps (slots left).
- Fonts: the Folio flip rolls integers only; decimal steppers (leading, spacing) fade the value instead.
- Pagination runs on the whole chapter at once (about 345 ms for 12,000 words in the JIT test host); owner device figure pending.
- The web-twin comparison was not made (`proof/web-14` absent).

## Screenshots
`docs/redesign/proof/mobile-14/`: stocks, faces, scale 2, opener, scene break, speaker popover, end matter, the end, paged (phone, tablet, mid-turn, one hand), Type sheet (half, full), Contents (sheet, no match, panel), Margins, progress field, brightness HUD, every state, reduced motion, legacy. Fixture: Alice ch. 1 (public domain) with a `* * *` after paragraph 12; attribution fixtures with a matching and a stale fingerprint.

## API for mobile/15, 23, 36
- `NovelReaderController` (family arg `NovelReaderArgs`): state `chapterValue/chapter, attribution, speakerRuns, readingBucket, prevKey, nextKey, nextState, furtherElsewhere, saved, stale, pageIndex, pageCount, revision`; commands `attach/detach(NovelReadingSurface)`, `beginRestore`, `jumpToBucket`, `jumpToParagraph`, `onScrolled`, `onPaged`, `next`, `previous`, `open`, `swapTo`, `markComplete`, `bookmark`, `addNoteToLast`, `clearFurther`, `setViewport`, `paginateNovel(measureCh, NovelType)`, flags `autoNext`, `narrationBusy`, `seamless`, `locationReplacer`.
- `NovelParagraphLayout({text,type,width,ink,indent,dropCap})`: `height`, `lines`, `paintText`, `boxesFor(start,end)`, `offsetAt`, `hasDropCap`.
- `NovelParagraph(... decorations: List<NovelDecoration>)`; `NovelDecoration(start,end,fill,underline,dotted,speaker)`: Listen adds its band and spoken-word underline as more decorations.
- Ordered lists to extend: `kNovelTypeRows` (AMBIENT), `NovelMarginsPanel.extraTabs` (VOICES), `novelTopActions(afterBookmark:)`, `NovelBottomBar.trailing`.

## Interpretations
- Stored spellings follow mobile/18's record (`sepiaNight`, `sourceserif`, lowercase layout values). `pageTurn` and `stock` defaults are now Cut and Nitrate.
- `CineStockColors` lives in `stock.dart` (re-exported by `page_frame.dart`) to avoid an import cycle; `contents_sheet.dart` of the book page was left untouched because the token remap makes the optional `stock` parameter unnecessary (the reader has its own `novel_contents.dart` reusing `ContentsRow`).
- Justify sets `TextAlign.justify` without hyphenation. Margins panel on tablets follows the manga reader (§8.14.12). Tablet default sizes 19 (18 for Archivo).
- Fonts, the Issue derivation and `legibleTextProvider` already existed; none were added.
