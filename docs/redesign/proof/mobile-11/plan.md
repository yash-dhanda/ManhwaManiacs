# mobile-11 plan (lane L25)

Cinematic series pages in the Flutter app: the manga Feature page, the novel Book page and chapter downloads. One `FeatureView` serves `/sources/:sourceId/series/:seriesKey` and `/library/:followedId`.

Fix pass 1 replaced the first pass's local stand-ins with the smallest local primitives that behave as the specification says, because mobile/04-10 are not integrated yet. Every stand-in carries a `TODO(mobile/NN)` and is listed in report.md.

## Working steps (one commit each, messages start `mobile-11:`)

1. Data layer (B1-B13): enrichment, suggested tags, repoint mapping, `timeHere`, mark-read helpers, download mark and run summary, chapter sort, content window, `clearMatureOverride`. Tests first.
2. Primitives the page needs: `CineDownloadMark`, `CineFocusRing`, `SetHeading`, `CineAmbient`, `CineMatchCutPage` (+ iOS `SwipeablePage`), `ReaderPrefetch`, Column wipe (`enterReader`), `DashedToken`, `CineSegmented`, `DropCapParagraph` (third-baseline aligned).
3. Shell (C): routes on match-cut pages, `FeatureView`, ambient wash, running head, rating card, Lightbox, states.
4. Feature page (D): phone hero and tablet spread, actions, tabs, schedule rows, marks with Undo, At a glance (tags, suggested, shelves, OCR), DETAILS, overflow, repoint.
5. Book page (E): front matter, actions, windowed contents as slivers, contents sheet (N2), states.
6. Downloads (F): selection bar, run line (free-space figure), series card; the legacy series card reads the same summary provider (B9).
7. Hardware keys (D10, E6): `feature_shortcuts.dart`.
8. Tests, screenshots, docs.

## Floor

`flutter-test-before.txt`: 2133 passed before this lane's fix pass (whole suite).
