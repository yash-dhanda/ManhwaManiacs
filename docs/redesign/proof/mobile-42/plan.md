# mobile-42 plan

One task per scope item of `docs/redesign/prompts/mobile/42-glass-stats-streak-wrapped.md`. Pure modules test first.

## A. Shared data layer (skin-neutral, Dart-tested)
1. `ProgressAnswer` parse (`reading_progress.dart`); `noteProgressResponse` + `PrefsStreakDayStore` (`progress_streak.dart`); `streakEventsProvider` + `progressAnswerHandlerProvider`; `ReaderRepositoryImpl.onAnswer` called after a successful `/reader/progress` and `/batch` (manga reader, novel save and outbox all go through it), `tz_offset_minutes` on both. Tests: `test/features/library/progress_streak_test.dart`.
2. `dailyGoalProvider` applies `StreakToday`/`GoalMet`; `setDailyGoal` optimistic with rollback. Tests: `daily_goal_test.dart`.
3. `reading_stats.dart`: `bestPagesDay`, `daysRead`, `weeklyTotals`, `heatLevel`, `clockBand`. Tests: `reading_stats_test.dart`.
4. `numbers_snapshot.dart` `{savedAt, payload}` + old shape; `snapshotAge`. Tests: same file.
5. `wrapped_cards.dart`: `wrappedCards`, `notEnoughData`, `wrappedTitle`, `kMatureGenres`, `shareEligible`. Tests: same file.
6. Reuse `core/platform/gravity.dart` (mobile/30); nothing added.

## B. "Your reading" (`screens/stats/`)
Screen, router entry out of `PENDING`, range sync, hero, totals, charts, heatmap, clock, radar, lists (content mode), Wrapped entry, footnotes, goal menu, wide layout, states, keys. Tests: `statistics_screen_test.dart`, `stats_charts_test.dart`, `goal_ring_test.dart`, `numbers_purge_test.dart`.

## C. Streak flame
`flame_geometry.dart` (test first), `streak_flame.dart`, `parts/streak/{streak_ui,plus_one}.dart` (listener mounted in the shell), goal ring through `glassGoalRingProvider`, one flame everywhere. Tests: `flame_geometry_test.dart`, `streak_flame_test.dart`, `streak_events_test.dart`, `stats_tilt_motion_test.dart`.

## D. Wrapped (`screens/wrapped/`)
`wrapped_frame.dart`, `page_pile.dart`, `podium.dart`, `story_math.dart` (tests first), `wrapped_screen.dart`, `wrapped_card_face.dart`, figures in `wrapped/wrapped_figures.dart`. Tests: `wrapped_pure_test.dart`, `story_math_test.dart`, `wrapped_screen_test.dart`, `wrapped_gestures_test.dart`.

## E. Share cards
`share_layout.dart` (test first), `share_card.dart` (`renderShareCard`, `ShareSpec`, debug lists), `parts/share/share_side.dart`. Tests: `share_layout_test.dart`, `wrapped_copy_test.dart`, `share_render_test.dart`, `share_side_test.dart`.

## F. Purge
`registerPurgeHolder('mobile-42.numbers', purgeNumbers)`. Test: `numbers_purge_test.dart`.

## Proof
`test/screenshots/glass/mobile_42_stats_wrapped_shots_test.dart` -> this folder; `report.md`, `device-check.md`, `inventory-map.md`.
