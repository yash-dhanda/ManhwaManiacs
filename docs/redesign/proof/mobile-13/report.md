# mobile/13 report

## Done by scope letter
- A engine: `ReaderEngine.setLayout(ReaderLayout, {rtl, pagePhysics})` + `layoutSpec`; `turnTo(page, {kind, slideDuration, slideCurve, fadeDuration})`; `pageAtReadingLine()`; `engine/spread.dart` (wide page rule); `engine/page_turn.dart` (`shouldCommitTurn`, `turnDecision`, `turnTarget`); `CinePagePhysics` (`skins/cinematic/screens/reader/cine_page_physics.dart`, 72 px / 600 px/s, 504 ms release spring); `PagedReaderView` (a sibling of the strip view, so the strip path is untouched); zoom 1-3x via raw pointers (as mobile/12 did for the strip, not `InteractiveViewer`); `ReaderEngineOptions.pageOverlayBuilder`, `onPageLongPress` (450 ms / 8 px), `pageHeroTag`, `pageEpoch`, `readAllKeys`; `ReaderEngineState.readAll: ReadAllState(index,total,boundaries)`; `BulkLimiter`; `ocr_boxes.dart`; volume keys in paged layouts.
- B paged layouts: stage, double with gutter/centre line, RTL, Cut/Slide/Fade, reduced-motion fade, tap zones 30/40/30 and bands (`mm.reader.zones-seen`), edge-ignore swipes, credits screen then next chapter by Dip, keys, K01 toast (`mm.reader.k01-toast-seen`). Default page turn is now CUT (DESIGN 8.14.8 overrides the earlier 'slide' default).
- C read-all: `/read-all/:sourceId/:seriesKey?from&page&at` (`ReadAllScreen`, ScreenId `readAll` out of PENDING), `ReadAllFeedController` (window 20, limiter, placeholders, trim at 60, offline end), `readerFeedFactoryProvider` hook in the manifest reader, divider, `· 12 OF 201`, global ruler with 2 px gaps and `CH 143 · p. 7` flag, Contents scrolls, list failure notice (headline "The list didn't load." + the exact sentence as deck, because the typed headline holds 60 graphemes), failed chapter notice, 429 wait, offline end.
- D setup sheet: `reading_setup_sheet.dart`, `setup_rows.dart` (ordered row lists per tab), `SpeedRuler`, reset with the 1000 ms arm.
- E Margins: `margins_panel.dart`, `notes_tab.dart`, `dialogue_tab.dart`, `circle_tab.dart`, `circle_rows.dart`; `features/circle/` created here (readers from `GET /circle/series`, reactions from `GET /circle/reactions`; the prompt's payload note is wrong: reactions are not on /circle/series). Circle endpoint status: not run against a live stack; tests use fixtures (404 removes the tab).
- F page actions: sheet, Lightbox with Hero, OCR outlines and popover, Retry, Scan (OcrRunController). `GET /ocr/chapter` boxes are now parsed.
- G keys `, ] w v r`, context menu, Shift+F10, escape order (panel then cinema then exit). H gestures as listed. I states reuse mobile/12's.

## Not done or reduced
- A5 preload: the next 3 views are warmed with `precacheImage`; not routed through the sources limiter priorities (P0/P3).
- ORIGINAL fit is capped to the stage (not panned sideways).
- A manifest carries no page sizes, so wide pages are learned as they decode.
- Web port `frontend/src/features/reader/spread.ts` lacks the wide-page rule: for web/24.
- Read-all Show zones/keys are inert; the `divider` shot is an approximate scroll position.
- Long-press on hidden-chrome strip uses raw pointers, not `LongPressGestureRecognizer`.

## Interpretations
- Read-all drag flag replaces hover. One side panel at a time on tablets, last opened wins. Stage inset is 12 px per side (24 total).
- Engine API for mobile/23 and Glass: `ReaderEngine.setLayout`, `turnTo`, `shouldCommitTurn`, `CinePagePhysics`, `pageOverlayBuilder`, `pageAtReadingLine`, `ReadAllState`, `BulkLimiter`, `PagedReaderView`, `SetupTab`/`kSetupTabs` (append AMBIENT rows).

## Proof
Screenshots in this folder (phone/tablet per file name); web-13 captures were not in the tree, so no side-by-side. Device checklist: `device-checklist.md`.
