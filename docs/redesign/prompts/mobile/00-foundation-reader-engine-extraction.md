# Mobile foundation 00: pixel-free reader engine extraction

## Goal

Split the Flutter manga reader into a skin-neutral **engine** and a replaceable **chrome**, without changing a single pixel or behaviour. Today `mobile/lib/features/reader/widgets/reader_content.dart` (2,065 lines) is one `ConsumerStatefulWidget` that owns everything: feed reconcile, scroll restore, page extents, prefetch, progress saves, auto-scroll, tap zones, lock mode, bookmarks and the bars drawn over the pages. Both redesigned skins need that logic but must draw their own chrome, so you move the logic into `mobile/lib/features/reader/engine/`: a `ReaderEngine` controller (with a scoped Riverpod provider), an immutable `ReaderEngineState`, the engine commands, the next-chapter auto-queue, and a `ReaderEngineView` that renders the page strip and hands every overlay to a `chromeBuilder(context, ReaderEngineState)` slot. The legacy reader (`ReaderContent`) becomes a thin frame over the engine whose chrome builder returns today's bars, so `ReaderScreen` (library reader, mobile S15) and `SourceReaderScreen` (source reader, mobile S19) both run on the engine in the same commit. This is stack risk 6: the most-tuned code in the app. It lands as **one commit** gated by golden parity images taken before the change and by every existing reader test (baseline: 2,012 Flutter tests, all green). After it, separate no-pixel commits move the pure logic that still lives in `features/*/widgets/` into `providers/` or `utils/`, so the flip can later delete every `widgets/` folder without losing logic.

## Read first

Read these before you plan. Section numbers are binding.

1. `docs/redesign/stack-decision.md` §2.3 (mobile layout: `features/reader/engine/` is new, "the reader engine is extracted first … in one commit that changes no pixels", "logic that lives in a widget moves first"), §3 (row "Flutter `features/reader/widgets/reader_content.dart`: split"), §4 risk 6 (the 120-page, 2,880 px device check before any chrome work), risk 11 (dev-box memory).
2. `docs/redesign/cinematic/DESIGN.md` §15.4 (the engine seam: the base state fields and commands, the chrome builder, "the engine also owns the next-chapter auto-queue"; the five later duties `pageTint`, words on screen, `panels`, words per panel and `chapterCompleted` are **not** added now), §8.14.11 (reader states and "Saving the next chapter (auto-queue)", which mobile/12 extends; you only move today's behaviour).
3. `docs/redesign/glass/DESIGN.md` §15.4 (the Glass engine fields and commands, and the **commit order**: this step is step 0, "the pixel-free engine extraction … gated by the existing reader tests"; shape the state so `currentPageSample`, `scrollVelocity`, `seamProgress`, `overscrollExtent`, `panelBoxes` and the later commands can be added without renaming anything), §15.10 G11.
4. `docs/redesign/inventory/mobile.md` S15/S19 (every element of today's reader, items 1–41, and the gestures line) and §6a (reader internals: modes, continuous feed, tap zones, position and progress, prefetch and memory, the 64 MB decode budget, the 2,880 px decode cap, offline).
5. `docs/redesign/inventory/00-decisions.md` (Webtoon-style reader reference; performance: flagship-only, no degraded paths).
6. `docs/redesign/00-baseline.md` (flutter analyze: no issues; flutter test: 2,012 passed; RAM figures).
7. `docs/redesign/prompts/web/03-foundation-reader-seam-limiter-proof.md` §A (the web mirror of this step; keep the vocabulary aligned: `ReaderEngineState`, `nextState`, commands, surface slots, auto-queue).
8. Today's code you restructure (read in full before planning): `mobile/lib/features/reader/widgets/reader_content.dart`, `reader_page_image.dart`, `chapter_seam.dart`, `reader_controls.dart`, `reader_shortcuts.dart`, `reader_edge_back_gesture.dart`, `mobile/lib/features/reader/providers/{reader_ui_provider,reader_filter_provider}.dart`, `mobile/lib/features/reader/utils/*.dart`, `mobile/lib/features/reader/models/{reader_feed,reader_chapter,reader_page}.dart`, `mobile/lib/features/reader/screens/reader_screen.dart`, `mobile/lib/features/sources/screens/source_reader_screen.dart`, and every test under `mobile/test/features/reader/`, plus `mobile/test/features/sources/source_reader_*_test.dart`, `mobile/test/features/downloads/offline_reader_acceptance_test.dart`, `mobile/test/screenshots/support/{shot_harness,shot_network}.dart`.

## Preconditions (stop and report if any fails)

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs
git branch --show-current                                   # feat/vps-slim-source-native
git status --short mobile/                                  # empty: no one else is editing mobile/
/srv/manhwamaniacs/dev/flutter/bin/flutter --version | head -1   # Flutter 3.44.6
wc -l mobile/lib/features/reader/widgets/reader_content.dart     # about 2,065
ls mobile/lib/features/reader/engine 2>/dev/null                 # must not exist yet
```

This step has no upstream dependency. Other sessions (web, backend, shared) may be committing in the same checkout; that is expected.

## Skills to invoke

- `superpowers:writing-plans` before touching code. Save the plan at `docs/redesign/proof/mobile-00/plan.md`; list the golden baseline commit, the extraction commit (with the tests that gate it) and each no-pixel move commit, one line each.
- `superpowers:executing-plans` for section B (the extraction): it runs in **this** session, never split across parallel subagents, because the parts only compile together. `superpowers:subagent-driven-development` is allowed for section E (the widget-logic moves), one subagent per move; verify each against `git status` and `git diff`, never against the subagent's report.
- `superpowers:test-driven-development` for the new engine tests of section C (write each test first, watch it fail on a stub, then pass).
- `superpowers:verification-before-completion` before you claim anything is done.
- `impeccable`, `taste-skill:taste-skill` and `frontend-design` are **not** used: this step must not change a pixel.

## Track rules (every mobile step)

- Work in `mobile/` only, plus `docs/redesign/proof/mobile-00/`. Never touch `frontend/`, `backend/` (never `backend/connectors/`), `design/` sources, or generated `*.g.dart` files.
- Stage only your own paths with explicit `git add <path>`; never `git add -A`, `git add .` or `git commit -a` (web, backend and shared sessions commit in the same checkout).
- Flutter is `/srv/manhwamaniacs/dev/flutter/bin/flutter`. Run `flutter analyze` and `flutter test` only after `free -m`, one at a time, never while a `next build` runs anywhere on the box (`pgrep -fa "next build"` must print nothing).
- No Gradle and no Xcode on this box: never run `flutter build`. CI builds the iOS app (`.github/workflows/ios-build.yml`); the owner builds signed APKs on his own machine.
- Device checks are written as a checklist for the owner (iPhone through SideStore, the Android flagship); you cannot run them.

## Scope, item by item

### A. Golden parity baseline (first commit, before any production change)

1. Create `mobile/test/features/reader/reader_parity_golden_test.dart` on the **unchanged** code. It pumps today's `ReaderContent` inside a `ProviderScope` with the overrides the existing `reader_content_test.dart` uses, fonts loaded with `loadAppFonts()` from `test/screenshots/support/shot_harness.dart` in `setUpAll`, and page images served by `setUpShotCoverCache()` + `addShotCovers()` from `shot_network.dart` (painted 800 × 1,200 PNGs, four distinct hues plus one all-white and one near-black page, generated in the test with `dart:ui` `PictureRecorder`; never real artwork). Scenes, each captured with `expectLater(find.byType(ReaderContent), matchesGoldenFile('goldens/reader_parity_<scene>_<w>x<h>.png'))`:
   - `strip_chrome` — vertical strip, chapter of 12 pages, page 3 reading line, controls visible;
   - `strip_bare` — the same after the auto-hide (pump 3,100 ms);
   - `seam` — a two-chapter continuous feed scrolled so the 96 px chapter seam is mid-screen;
   - `ltr` — left-to-right mode (page cards with the `sm` radius, shadow and gap);
   - `broken` — a page whose image fails (serve a 404 for its URL) showing the broken tile;
   - `locked_end` — lock mode on, scrolled to the chapter end so the "Next chapter" edge prompt shows;
   - `zoom2` — after a double tap (zoom 2.0×).
   Sizes: phone 390 × 844 logical at device pixel ratio 3, and tablet 834 × 1,194 at ratio 2 (set `tester.view.physicalSize` and `devicePixelRatio`, reset in `addTearDown`). 14 goldens in total.
2. Generate them with `flutter test --update-goldens test/features/reader/reader_parity_golden_test.dart`, look at every PNG (Read them), and commit the test plus `mobile/test/features/reader/goldens/*.png` alone: `test(reader): golden parity baseline before the engine extraction`. From here on `--update-goldens` is forbidden for these files.
3. Record the full-suite baseline on this commit: `flutter test 2>&1 | tail -3` (expect 2,012 from the baseline, plus the generated tests shared/00 and shared/01 added if they have run, plus the 14 new goldens; write the exact numbers into the plan).

### B. The extraction (one commit: `refactor(reader): extract the pixel-free reader engine`)

Everything in this section lands in a single commit, because the engine, the legacy frame and both entry points only compile together. Use `git mv` for whole-file moves inside that commit so rename detection keeps history.

4. **`mobile/lib/features/reader/engine/reader_engine_state.dart`**

   ```dart
   enum ReaderNextState { loading, ready, failed, none }

   @immutable
   class ReaderEngineState {
     const ReaderEngineState({ … all fields required … });
     final String chapterId;              // chapter under the reading line (id, never a feed index)
     final String chapterTitle;
     final int chapterIndex;              // index into feed.chapters
     final int page;                      // 1-based, chapter-local (what the counter shows)
     final int pageCount;                 // pages in that chapter
     final double progress;               // 0–1 through that chapter, quantised to 0.001
     final bool atStart;                  // today's _atStartNotifier
     final bool atEnd;                    // today's _atEndNotifier
     final bool hasPrevious;              // an onPreviousChapter route exists
     final bool hasNext;                  // an onNextChapter route exists
     final List<String> loadedChapterIds; // the feed's chapters, in order (the loaded neighbours)
     final ReaderNextState nextState;
     final List<ReaderAnchor> bookmarks;  // current chapter only
     final double zoom;                   // readerUiProvider.zoomLevel (0.5–3.0)
     final bool autoScrolling;
     final double autoScrollSpeed;        // px/s (30 / 60 / 120 today)
     final bool chromeVisible;            // readerUiProvider.controlsVisible
     final bool locked;                   // readerUiProvider.isLocked
     static const ReaderEngineState initial = …; // empty ids and title, page 1 of 1, progress 0, nextState none, zoom 1.0, speed 60
     ReaderEngineState copyWith({ … });
     // == and hashCode over every field (listEquals for the lists)
   }
   ```

   Rules:
   - `progress = ((page − 1) + fraction) / pageCount`, where `fraction` is the reading line's position inside the page from the same geometry `_handleBookmark` uses (`anchorAtOffset(_metrics, offset)`), rounded to 3 decimals. The engine notifies listeners only when the new state is not `==` to the old one, so a scroll that moves less than 0.001 costs no rebuild.
   - `nextState`: `ready` when the feed holds a chapter after the reading chapter, or `onNextChapter` is non-null; otherwise `loading` while an `onReachedFeedEnd()` call is in flight; otherwise `failed` when the most recent `onReachedFeedEnd()` completed (with or without an error) without adding a chapter after the reading one; otherwise `none`.
   - `bookmarks`: the anchors passed in the new optional `ReaderContent`/`ReaderEngineView` input `bookmarkAnchors` (`Map<String, List<ReaderAnchor>>`, keyed by chapter id, default `const {}`; both screens pass nothing today) plus every anchor the engine saved through `bookmark()` in this session, for the reading chapter. mobile/12 feeds the map from the device bookmarks table for the Cinematic ruler.
   - Do not add `pageTint`, `panels`, words on screen or any Glass field (cinematic §15.4, glass §15.4 commit order: later steps).
5. **`mobile/lib/features/reader/engine/reader_engine.dart`**

   ```dart
   abstract interface class ReaderEngineCommands {
     void seekToPage(int page);               // chapter-local, 1-based (today's _seekToPage)
     void pageBy({required bool forward});    // 85 % of the viewport, 240 ms easeOutCubic (today's _pageBy)
     void nextChapter();                      // light haptic + onNextChapter (today's wrapped callback)
     void previousChapter();
     void toggleAutoScroll();
     void setAutoScrollSpeed(double pxPerSecond);
     void zoomIn(); void zoomOut(); void resetZoom(); void toggleDoubleTapZoom();
     Future<bool> bookmark();                 // today's _handleBookmark; true when stored
     void showChrome(); void hideChrome();    // today's _showControls / _hideControls
     void holdChrome();                       // cancel the auto-hide (a sheet is open)
     void scheduleHideChrome();               // re-arm the auto-hide
   }

   sealed class ReaderEngineEvent {}
   final class ReaderUnlocked extends ReaderEngineEvent {}
   final class ReaderBookmarkSaved extends ReaderEngineEvent { final int page; final int? percent; }
   final class ReaderStaleAnchor extends ReaderEngineEvent { … the values today's SnackBar text uses … }

   class ReaderEngine extends ValueNotifier<ReaderEngineState> implements ReaderEngineCommands {
     ReaderEngine() : super(ReaderEngineState.initial);
     // attach(host) / detach(host) by ReaderEngineView's state, like ScrollController ↔ ScrollPosition.
     // Every command forwards to the attached host; with no host attached it is a no-op.
   }
   ```

   The controller is owned by whoever creates it (the legacy frame now, each skin's reader screen later) and disposed by it.
6. **`mobile/lib/features/reader/engine/reader_engine_provider.dart`**: `final readerEngineProvider = Provider<ReaderEngine>((ref) => throw StateError('readerEngineProvider is scoped: read it below ReaderEngineView.'), dependencies: const []);`. `ReaderEngineView` wraps its subtree in `ProviderScope(overrides: [readerEngineProvider.overrideWithValue(controller)], child: …)`, so chrome widgets deep in the tree can `ref.watch(readerEngineProvider)`.
7. **`mobile/lib/features/reader/engine/reader_surface_slots.dart`**: the legacy decorations drawn *inside* the strip become injectable, so the engine folder holds no legacy visuals:

   ```dart
   class ReaderSurfaceSlots {
     const ReaderSurfaceSlots({required this.chapterSeam, required this.brokenPage, required this.pagedCornerRadius});
     final Widget Function(BuildContext context, ReaderChapter chapter, Axis axis) chapterSeam;   // today's ChapterSeam
     final Widget Function(BuildContext context, VoidCallback retry) brokenPage;                   // today's broken tile
     final double pagedCornerRadius;                                                                // today's context.radii.sm in LTR/RTL
   }
   ```

   If a decoration needs an argument this class lacks, extend the class; never move the markup into `engine/`.
8. **`mobile/lib/features/reader/engine/reader_engine_view.dart`**: `ReaderEngineView` is today's `_ReaderContentState` logic plus the page list, as a `ConsumerStatefulWidget` taking every `ReaderContent` constructor argument plus `required ReaderEngine controller`, `required ReaderSurfaceSlots slots`, `required Duration autoHideAfter` (the legacy frame passes `context.readerChrome.autoHideAfter`; the engine must not read `context.readerChrome`), `required Widget Function(BuildContext context, ReaderEngineState state) chromeBuilder`, `ValueChanged<ReaderEngineEvent>? onEvent`, and `bookmarkAnchors`. It owns, unchanged in logic and constants: `_reconcileFeed`, restore (`_restoreInitialScroll`, `_attemptRestoreJump`, the 30-frame limit), extents (`_commitPageExtents`), `_handleScroll`, `_prefetchUpcoming` (64 MB budget, 2,880 px decode cap), `_maybeExtendFeed`, progress and scroll saves (250 ms / 500 ms), `_maybeAutoNextChapter` (900 ms), auto-scroll (frame-delta based), wakelock, refresh-rate and volume-key sync, tap handling (thirds, 300 ms post-scroll cooldown, 280 ms double tap, five-tap unlock in the 20–80 % × 15–85 % centre within 2 s), the auto-hide timers, `_ReaderPageDelegate`, and haptics through `hapticsProvider` exactly where they fire today. Its build returns, in today's order and nesting: `NotificationListener<ScrollNotification>` → `GestureDetector` → `Stack[ AnimatedContainer background (300 ms easeOut, zero under disableAnimations), RepaintBoundary(ListView.custom …, tone ColorFiltered when set), ValueListenableBuilder<ReaderEngineState>(valueListenable: controller, builder: (c, s, _) => chromeBuilder(c, s)) ]`. The snack bars become `onEvent` calls: `ReaderUnlocked` where "Reader unlocked" was shown, `ReaderBookmarkSaved` where the bookmark SnackBar was, `ReaderStaleAnchor` where the stale-anchor SnackBar was.
9. **`git mv mobile/lib/features/reader/widgets/reader_page_image.dart mobile/lib/features/reader/engine/reader_page_image.dart`**: the page tile is part of the strip. Replace its broken-state markup with `slots.brokenPage(context, retry)` (passed in as a constructor argument `brokenBuilder`), its `context.radii.sm` with a `cornerRadius` argument, and make `backgroundColor` required (no `ReaderColors.bg` default). After this it imports nothing from `app/theme/` or `features/reader/theme/`.
10. **`mobile/lib/features/reader/engine/next_chapter_auto_queue.dart`**: today's `_SourceReaderScreenState._maybeQueueNextChapter` and its `_prefetchedFor` guard, moved verbatim into `class NextChapterAutoQueue { void maybeQueue(WidgetRef ref, {required String sourceId, required String seriesKey, required String routeChapterId, required String? nextChapterId}); }` with the same gates (a downloads scope exists; with "Wi-Fi only downloads" on, only on Wi-Fi) and the same once-per-route-chapter guard, deferred with `addPostFrameCallback` as today. `SourceReaderScreen` owns one instance and calls it at the exact place it calls `_maybeQueueNextChapter` now. `ReaderScreen` does not call it (it does not auto-queue today). mobile/12 extends it per cinematic §8.14.11 (storage floor, the per-profile switch, both entry points).
11. **The legacy frame** `mobile/lib/features/reader/widgets/reader_content.dart`: keeps its class name and its whole constructor (so both screens and the tests keep compiling), becomes a `ConsumerStatefulWidget` that creates and disposes a `ReaderEngine`, and builds:

    ```
    ReaderShortcuts(onPreviousChapter: engine.previousChapter, onNextChapter: engine.nextChapter,
                    onBookmark: engine.bookmark, onZoomIn: engine.zoomIn, onZoomOut: engine.zoomOut, onZoomReset: engine.resetZoom,
      child: Scaffold(backgroundColor: <readerFilterProvider background colour>,
        body: ReaderEngineView(controller: engine, …every ReaderContent argument…,
          slots: ReaderSurfaceSlots(chapterSeam: <today's ChapterSeam>, brokenPage: <today's broken tile markup, moved verbatim>, pagedCornerRadius: context.radii.sm),
          autoHideAfter: context.readerChrome.autoHideAfter,
          onEvent: <today's SnackBars, same text, same durations, same behaviour>,
          chromeBuilder: (context, state) => Stack(children: [ReaderEdgeBackGesture(…), const ReaderFilterOverlay(), _ReaderControlsLayer(… values from state and engine commands …)]))))
    ```

    `_showMoreOptions` (the `ReaderMoreSheet` with `context.colors.surfaceElevated`, `showDragHandle`, the `xl` top radius) stays here and calls `engine.holdChrome()` before and `engine.scheduleHideChrome()` after, as today. `_ReaderControlsLayer` and `_AnimatedEdgePrompt` stay here, fed from `state` instead of the three `ValueNotifier`s. Keep the edge prompts' positions, the top and bottom bars and every callback's haptic exactly as today.
12. **Both entry points in the same commit.** `ReaderScreen` and `SourceReaderScreen` keep calling `ReaderContent` (now the frame over the engine); `SourceReaderScreen` swaps its private auto-queue for `NextChapterAutoQueue` (item 10). Nothing else in either screen changes.
13. **Engine boundary test** `mobile/test/features/reader/engine/engine_boundary_test.dart`: reads every `.dart` file under `lib/features/reader/engine/` and fails on any import containing `/widgets/`, `/screens/`, `app/theme/`, `app/router/`, `features/reader/theme/`, or `skins/`. It includes one self-check on an in-memory string with a banned import, so the scan itself is proven.

Tests may change only import paths and constructor arguments that the move forces (for example a test that pumps `ReaderPageImage` directly now passes `brokenBuilder`, `cornerRadius` and `backgroundColor`). No `expect` line may be changed or removed. The 14 goldens of section A must pass untouched.

### C. New engine tests (in the extraction commit or right after it)

14. `mobile/test/features/reader/engine/reader_engine_state_test.dart`: `==`/`hashCode` over every field; `progress` quantisation (0.12345 → 0.123); `nextState` in each of its four cases with a fake `onReachedFeedEnd` (a `Completer` that is pending → `loading`; completes without growing the feed → `failed`; a longer feed handed back → `ready`; no next anywhere → `none`).
15. `mobile/test/features/reader/engine/reader_engine_commands_test.dart`: pump `ReaderContent` with a 3-chapter feed (reuse the feed builders of `reader_content_test.dart`) and assert through a `ReaderEngine` obtained with `tester.state` or a test-only `debugEngine` getter: `seekToPage(7)` updates `state.page` to 7; `toggleAutoScroll()` flips `autoScrolling`; `zoomIn()` moves `zoom` from 1.0 to 1.1; `bookmark()` returns `true` with a fake `onAddBookmark` and the anchor appears in `state.bookmarks`; `chromeBuilder` receives a new state when the reading page changes and does not rebuild while the state is `==`.
16. `mobile/test/features/reader/engine/next_chapter_auto_queue_test.dart`: no downloads scope → nothing enqueued; Wi-Fi-only on and not on Wi-Fi → nothing; otherwise exactly one `enqueueChapter` for the next chapter; a second call for the same route chapter → still one.

### D. The owner's device check (written, not run)

17. `docs/redesign/proof/mobile-00/device-check.md`, a checklist the owner runs on the iPhone (the build `ios-build.yml` publishes after your push, updated through SideStore) and on the Android flagship (the next signed APK he builds). Each line is a checkbox with a pass condition:
    - Open a 120-page webtoon chapter whose pages decode at the 2,880 px cap (a long-strip source; note the series you used). Settings → Diagnostics: with "Use the highest refresh rate everywhere" on (Android), scroll the whole chapter top to bottom by fling. Pass: Diagnostics shows FPS ≥ 115 at 120 Hz, JANK < 5 %, WORST < 16.7 ms (the same pass rule as the mobile/03 Glass gate).
    - Resume: leave mid-chapter, reopen from History. Pass: it opens on the same page within one page height.
    - Bookmark at 62 % of a page, reopen the bookmark. Pass: same spot.
    - Read-all across three chapters. Pass: seams appear, no jump backwards at a seam, progress lands in each chapter.
    - Auto-scroll at Slow, Medium and Fast. Pass: speeds unchanged, stops at the end.
    - Lock mode, five centre taps. Pass: "Reader unlocked".
    - Double tap zoom, keyboard H / L / B / + / − / 0 (iPad or Android with a keyboard), volume keys (Android, when enabled). Pass: all as before.
    - Offline: a downloaded chapter with flight mode on. Pass: opens from disk.
    - Source reader (Sources tab): the next chapter is queued in Downloads when on Wi-Fi.
    Head the file with the commit hash under test and a one-paragraph note that nothing should look or behave differently.

### E. Widget-held logic moves out of `widgets/` (separate no-pixel commits)

At the flip every `features/*/widgets/` folder is deleted (stack-decision §3). Pure logic that lives there today must move first, one commit per item (`refactor(<feature>): move <name> out of widgets/`), updating every import (no re-export shims). Found on 2026-09-29 with the command below; re-run it and include anything new that matches the same rule (a top-level function or class with no `BuildContext` parameter that returns no widget and shows no UI).

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs/mobile
grep -rnE "^(String|int|double|bool|Future<[^(]*>|[A-Z][A-Za-z0-9_<>?, ]*\??) [a-z][A-Za-z0-9_]*\(|^class [A-Z]\w* (\{|extends (Notifier|AsyncNotifier|ChangeNotifier|StateNotifier))" lib/features/*/widgets lib/features/*/screens lib/shared/widgets
grep -rlnE "features/[a-z_]*/widgets/|shared/widgets/" lib/features/*/{providers,utils,services,models,queue,store,repositories,controllers} lib/core lib/shared/providers 2>/dev/null
```

18. `git mv lib/features/downloads/widgets/downloads_lifecycle_gate.dart lib/features/downloads/providers/downloads_lifecycle_gate.dart` (a widget with no UI; mobile/01 mounts it for every skin).
19. `git mv lib/features/downloads/widgets/open_chapter_scope.dart lib/features/downloads/providers/open_chapter_scope.dart` (no UI; every reader entry point wraps with it).
20. `chapterDownloadAction()` from `downloads/widgets/chapter_download_action.dart` → `downloads/utils/chapter_download_action.dart`, and the plain data types it returns, `SeriesChapterDownloadAction` and `SeriesChapterDownloadPhase` (today in `lib/shared/widgets/series_detail/series_chapter_tile.dart`, line 53 and above), → `downloads/models/series_chapter_download_action.dart`, in one commit; `series_chapter_tile.dart` (the widget) imports them from there.
21. `formatDownloadBytes()` from `downloads/widgets/downloads_storage_card.dart` → `downloads/utils/format_bytes.dart`.
22. `exportLocationDescription()` from `downloads/widgets/export_downloads_action.dart` → `downloads/utils/export_location.dart`.
23. `continueRowTitle()`, `continueRowCoverUrl()` and `ContinueFollowLookup` from `library/widgets/library/continue_reading_strip.dart` → `library/utils/continue_rows.dart`.
24. `followedSeriesCardSubtitle()` from `library/widgets/home/followed_series_card.dart` → `library/utils/followed_series_subtitle.dart`.
25. `relativeReadTime()` from `library/widgets/history/history_series_card.dart` → `library/utils/relative_read_time.dart`.
26. `audiobookButtonLabel()` (novels/widgets/novel_series_detail_view.dart) and `skippedNarrationLine()` (novels/widgets/audiobook_picker_sheet.dart) → `novels/utils/audiobook_labels.dart` (one commit).
27. Whatever `lib/features/library/utils/library_shelf.dart` imports from `novels/widgets/novel_shelf.dart` → `novels/utils/novel_shelf_logic.dart`, so no data-layer file imports a widget file.
27a. `SeriesChapterSortOrder` and `sortSeriesChapters()` from `lib/shared/widgets/series_detail/series_chapter_sort.dart` → `lib/features/library/utils/series_chapter_sort.dart` (three data-layer files import them today: `library/utils/resume_location.dart`, `novels/utils/novel_book.dart`, `reader/providers/series_reading_order_provider.dart`); the `SeriesChapterSortToggle` widget stays and imports the moved code. `lib/shared/widgets/` is legacy UI too (the skins never import it) and goes at the flip with the rest.
28. `lib/features/downloads/models/download_chapter_state.dart`, named by stack-decision §2.3 as an example, already lives in `models/`: nothing to move; say so in the report.

Functions that take a `BuildContext` and show UI (`showWhatsNewSheet`, `showSeriesActionsSheet`, `showContentModeSheet`, `showDownloadExportSheet`) are legacy UI and stay. Tests that import a moved symbol change only their import line. Each move commit runs `flutter analyze` and the tests of that feature folder before committing (`flutter test test/features/<feature>`), and the full suite once at the end.

## File layout (create or change; nothing else)

```
mobile/lib/features/reader/engine/reader_engine.dart               new
mobile/lib/features/reader/engine/reader_engine_state.dart         new
mobile/lib/features/reader/engine/reader_engine_provider.dart      new
mobile/lib/features/reader/engine/reader_engine_view.dart          new (logic moved from reader_content.dart)
mobile/lib/features/reader/engine/reader_surface_slots.dart        new
mobile/lib/features/reader/engine/reader_page_image.dart           git mv from widgets/, then edited
mobile/lib/features/reader/engine/next_chapter_auto_queue.dart     new (moved from source_reader_screen.dart)
mobile/lib/features/reader/widgets/reader_content.dart             rewritten as the legacy frame (same constructor)
mobile/lib/features/sources/screens/source_reader_screen.dart      change (auto-queue call only)
mobile/lib/features/downloads/providers/{downloads_lifecycle_gate,open_chapter_scope}.dart   git mv from widgets/
mobile/lib/features/{downloads,library,novels}/utils/*.dart        new files of section E
mobile/lib/features/downloads/models/series_chapter_download_action.dart   new (item 20)
mobile/lib/shared/widgets/series_detail/{series_chapter_tile,series_chapter_sort}.dart   moved code removed, imports only (items 20, 27a)
mobile/lib/app/app.dart and every importer of a moved file         import lines only
mobile/test/features/reader/reader_parity_golden_test.dart         new (section A)
mobile/test/features/reader/goldens/*.png                          new (14 files)
mobile/test/features/reader/engine/*_test.dart                     new (4 files)
mobile/test/**                                                     import / constructor-argument fixes only
docs/redesign/proof/mobile-00/plan.md                                   new
docs/redesign/proof/mobile-00/device-check.md                      new
docs/redesign/proof/mobile-00/*.png                                copies of the 14 goldens for the review
```

## Acceptance criteria

- [ ] The golden baseline commit precedes the extraction commit, and the extraction commit changes none of the 14 PNGs (`git diff <baseline>..HEAD --stat -- mobile/test/features/reader/goldens` is empty) while `reader_parity_golden_test.dart` passes.
- [ ] `flutter analyze` prints "No issues found!" (baseline).
- [ ] `flutter test` passes with 0 failures and a count of at least the baseline recorded in item 3 plus the new engine tests; every test that passed before still passes, and no `expect` line in an existing test was edited (`git diff <baseline>..HEAD -- mobile/test | grep '^-.*expect'` prints nothing).
- [ ] The extraction is exactly one commit touching both `reader_screen.dart`'s path (through `ReaderContent`) and `source_reader_screen.dart`.
- [ ] `engine_boundary_test.dart` passes: nothing under `lib/features/reader/engine/` imports `widgets/`, `screens/`, `app/theme/`, `app/router/`, `features/reader/theme/` or `skins/`.
- [ ] `ReaderEngineState` carries every field of item 4 and none of the later ones; `ReaderEngine` implements every command of item 5; `readerEngineProvider` is readable below `ReaderEngineView`.
- [ ] The next-chapter auto-queue lives in `engine/next_chapter_auto_queue.dart`; `SourceReaderScreen` queues exactly as before and `ReaderScreen` does not queue (unchanged behaviour).
- [ ] Reduced motion: the background cross-fade is still `Duration.zero` under `MediaQuery.disableAnimationsOf`; no animation, duration or curve anywhere changed (`git diff <baseline>..HEAD -- mobile/lib | grep -E "Duration\(|Curves\."` shows only moved lines, identical on both sides).
- [ ] Hit targets: unchanged (the tap thirds are ≥ 25 % of the width, the bars' icon buttons keep their sizes); the goldens prove it.
- [ ] Hardware keyboard: H, L, B, =/+, −, 0 still act (the existing `reader_shortcuts` coverage passes).
- [ ] Per-skin differences: none in this step. The engine is skin-neutral; `grep -rn "skins/" mobile/lib/features/reader` is empty.
- [ ] Section E: each move is its own commit; `grep -rlnE "features/[a-z_]*/widgets/|shared/widgets/" mobile/lib/features/*/{providers,utils,services,models,queue,store,repositories,controllers} mobile/lib/core mobile/lib/shared/providers` prints nothing.
- [ ] `docs/redesign/proof/mobile-00/device-check.md` exists with every checkbox of item 17 and the commit hash under test.

## Verification

Run one heavy command at a time and check memory first. Production shares this box.

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs/mobile
free -m                                    # stop if "available" is under 1024 MB; wait and re-check
pgrep -fa "next build" && echo "WAIT: a next build is running"
F=/srv/manhwamaniacs/dev/flutter/bin/flutter
free -m && $F test 2>&1 | tail -3          # BEFORE anything: 2012 at the baseline, plus any generated shared/* tests
# section A, then B …
free -m && $F analyze                      # baseline: No issues found!
free -m && $F test test/features/reader test/features/sources test/features/downloads/offline_reader_acceptance_test.dart
free -m && $F test 2>&1 | tail -3          # full suite, 0 failed
```

Web and backend: this step changes neither, so no local `npm run lint`, `npm run build` or `backend/.venv/bin/python -m pytest -q --no-header` run is needed; the CI `frontend` and `backend` jobs must stay green on your pushed commits.

**Visual proof.** The goldens are the proof: copy the 14 PNGs to `docs/redesign/proof/mobile-00/` (phone 390 × 844 and tablet 834 × 1,194) and open a few of them to confirm they show real pages and chrome, not placeholder boxes.

**CI.** After pushing, check the `tests` workflow for your head commit. If `command -v gh` works, use `gh run list --branch feat/vps-slim-source-native --limit 5`. Otherwise use the anonymous API sparingly (60 requests per hour per IP, shared with production's `mm-fetch-ios` timer on this box): `curl -s "https://api.github.com/repos/yash-dhanda/ManhwaManiacs/actions/runs?branch=feat/vps-slim-source-native&per_page=5" | python3 -c "import json,sys; [print(r['head_sha'][:7], r['name'], r['status'], r['conclusion']) for r in json.load(sys.stdin)['workflow_runs']]"`, at most once every 5 minutes; a failed job's messages are at `https://api.github.com/repos/yash-dhanda/ManhwaManiacs/check-runs/<job_id>/annotations`. A push to this branch also publishes an iPhone build through `ios-build.yml` when the tests job is green, which is how the owner gets the device-check build.

## Git

- Branch `feat/vps-slim-source-native`. Commits, in order: plan; golden baseline (A); the extraction (B, one commit, with C's tests or C right after); one commit per item of E; device checklist and proof copies. Push after each working step: `git push origin feat/vps-slim-source-native`.
- Stage explicit paths only (`git add mobile/lib/features/reader mobile/test/features/reader …`). Never `git add -A`, `git add .` or `git commit -a`.
- No Claude or AI attribution anywhere: no `Co-Authored-By`, no "Generated with" line, no AI author. Never commit secrets, `.env*` files or `.claude/`.

## Guardrails

- Never edit `backend/connectors/`, `frontend/`, `design/`, generated files, or anything under `/srv/manhwamaniacs/{app,data}`; no Docker commands; never touch production containers.
- RAM guard: `free -m` before every `flutter analyze` and `flutter test`; stop under 1,024 MB available; never two heavy commands at once, never alongside a `next build`.
- If a test cannot stay green without changing an `expect`, stop, revert to the last green commit and report the test and the reason; do not weaken the test.

## Report back

Reply with:
1. Done items by section (A–E), each with its commit hash, and the list of `git mv` pairs.
2. The final `ReaderEngineState` field list and the command list as implemented, and anything you had to add to `ReaderSurfaceSlots`.
3. Test counts: baseline before A, after A, after B/C, final (passed / failed / skipped), and the `flutter analyze` result.
4. Golden parity: confirmation that the 14 PNGs are byte-identical across the extraction, and the proof folder `docs/redesign/proof/mobile-00/`.
5. The section E moves, including any extra item your grep found, and the note on `download_chapter_state.dart`.
6. CI status of your last pushed commit, the lowest `free -m` available figure you saw, and open issues (anything deferred, and why).

Next prompt in the mobile track: `docs/redesign/prompts/mobile/01-foundation-skin-engine-and-restart.md` (it also needs `shared/00` and `backend/00` done). Next in the global order: `docs/redesign/prompts/shared/02-icon-sets-and-custom-glyphs.md`.
