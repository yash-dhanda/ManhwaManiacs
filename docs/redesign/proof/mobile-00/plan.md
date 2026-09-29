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

- Before A: 2,012 passed, 0 failed, 0 skipped.
- After A (`572ac14`): 2,013 passed, 0 failed, 0 skipped (measured: full
  `flutter test -j 2` in a detached worktree at `572ac14`, 05:05 wall, last line
  `+2013: All tests passed!`).
- After B/C (`e8be5bf`): 2,030 = 2,013 + 17 engine tests (boundary 2, state 5,
  commands 6, auto-queue 4). Reader + sources + offline-reader subset: 359 passed.
- Final (after E): 2,030 passed, 0 failed, 0 skipped; `flutter analyze`: No issues found!
- Fix pass 2 (after merging `feat/vps-slim-source-native` and adding
  `reader_shortcuts_test.dart`): 2,037 passed, 0 failed, 0 skipped (05:38 wall,
  `-j 2`); `test/features/reader`: 274 passed; `flutter analyze`: No issues found!
- Goldens: `git diff 572ac14..HEAD --stat -- mobile/test/features/reader/goldens`
  is empty; copies in this folder.
- Section E extras found by the grep (same rule, beyond items 18-27a):
  `FollowedSeriesMeta` (needed first, `followedSeriesCardSubtitle` takes it),
  `series_detail_meta.dart` (whole file), `bookmarkPositionLabel`,
  `formatStorageBytes`.
- Fix pass 3 (after merging `feat/vps-slim-source-native` at `ead69bf`, which
  adds shared/01's Glass tokens and `generated_glass_test.dart`): 2,042 passed,
  0 failed, 0 skipped (02:23 wall, `-j 2`); `flutter analyze`: No issues found!
  Goldens still untouched since `572ac14`.
