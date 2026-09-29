# mobile/00 plan: pixel-free reader engine extraction

Lane mobile1, worktree `/srv/manhwamaniacs/dev/wt/mobile1`, branch `redesign/mobile1`.

## Baseline

- `flutter test` before any change: **2,012 passed, 0 failed** (05:22 wall, `-j 2`).
- `flutter analyze`: No issues found (docs/redesign/00-baseline.md).

## Commits, in order

1. `docs(redesign): mobile/00 plan` — this file.
2. `test(reader): golden parity baseline before the engine extraction` —
   `mobile/test/features/reader/reader_parity_golden_test.dart` + 14 PNGs in
   `mobile/test/features/reader/goldens/` (7 scenes x phone 390x844@3 and
   tablet 834x1194@2), generated on the unchanged reader.
3. `refactor(reader): extract the pixel-free reader engine` — ONE commit:
   `engine/{reader_engine,reader_engine_state,reader_engine_provider,
   reader_engine_view,reader_surface_slots,next_chapter_auto_queue}.dart`,
   `git mv widgets/reader_page_image.dart engine/`, `reader_content.dart` as the
   legacy frame, `source_reader_screen.dart` auto-queue swap, test
   import/constructor fixes, and the four engine tests (boundary, state,
   commands, auto-queue). Gated by the 14 goldens (untouched), every reader,
   sources and offline-reader test, and the full suite.
4. One `refactor(<feature>): move <name> out of widgets/` commit per section E
   item (18-27a), each gated by `flutter analyze` + `flutter test
   test/features/<feature>`.
5. `docs(redesign): mobile/00 device check and golden proof` — device-check.md,
   the 14 golden copies, final numbers below.

## Notes

- The 14 goldens are captured in ONE `testWidgets` (so the suite count grows by
  1, not 14): the cache manager is a process-wide singleton and a page fetch
  left in flight by one test's fake clock never completes and holds one of its
  download slots, which starved every later test's pages. In one test every
  fetch lands on the same clock.
- Goldens are captured at logical size (Flutter's golden capture); the device
  pixel ratio still drives decode width and layout.

## Numbers

Filled in by the final docs commit.
