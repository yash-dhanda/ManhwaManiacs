# mobile/34 report

Sections A to J done on branch redesign/M34. Reader tests 398 before, 446 after (all passing). Parity: 62 capture pairs byte-identical (`parity/result.txt`). `strip-120.json`: 120 pages, max 2 mounted page images, velocity 6000 (+-0.0), 53 sample requests in 31.1 s (bound 53). 120 Hz device run pending on the owner's hardware (`device-check.md`).

Rubber band reading: vertical chapter-end pull c 0.55, sideways chapter swipe c 0.35 (as web/34).
Deviations: new commands live on `ReaderEngineExtrasHost` (strip view only), not `ReaderEngineCommands`, so the paged and guided hosts need no change; extra optional input `loadNeighbour` feeds `armNeighbour`; `commitNeighbour` resets the overscroll, stores the velocity and calls `onReplaceChapter`, the new feed arriving through `didUpdateWidget` starts the chapter at its top (next) or bottom (previous) and calls `continueFling`.
