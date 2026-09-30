# mobile/34 plan (as executed)

| Commit | Section | Gating tests |
| --- | --- | --- |
| pure helpers | A live thresholds, B sample + resolve + LRU, C velocity, D seam, E neighbour maths, F swipe, G lens layout, H cruise, I panel boxes | `<name>_test.dart` for each |
| engine integration | state fields, `ReaderEngine.live`, streams, commands, `ChapterEndPhysics`, view wiring (velocity, seams, sampler, overscroll, wheel, neighbour, fling, cruise, lens) | `chapter_end_physics_test`, `engine_tracking_test`, `flutter test test/features/reader` |
| probe + fixture + 120 | J1 probe page, J2 long-strip fixture, J3 `strip_120_test` | `strip_120_test` |
| proof | J4 parity captures, reader tests before/after, full suite | `cmp` of every pair |
