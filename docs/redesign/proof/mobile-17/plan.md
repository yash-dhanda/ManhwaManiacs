# mobile/17 plan: Cinematic Downloads, Index, app updates, System status

One task per item of the prompt's Scope section, run in the prompt's order (A data layer, B Downloads, C Index, D What's new and update cards, E System status, F cross-cutting).

## A. Shared data layer (skin-neutral, each with a unit test)
1. `features/downloads/utils/pending_removals.dart` + `pendingRemovalsProvider` (injected timer; undo, expiry, flushAll, replace).
2. `providers/download_switches_provider.dart` (`saveNextProvider`, `autoNewProvider`), `core/storage/profile_scoped_key.dart`; `NextChapterAutoQueue` reads `saveNextProvider`.
3. `utils/auto_download.dart`: `planAutoDownload`, `AutoDownloadRunner`, `AutoDownloadTrigger` (mounted in `shell.dart`, toast "Queued 6 new chapters.").
4. `utils/storage_meter.dart`: `storageMeter(...)` model.
5. `utils/queue_summary.dart`: `summariseQueue(...)`.
6. `features/settings/utils/whats_new_policy.dart` (moved out of the widget, no pixels).
7. `features/settings/services/metadata_cache.dart` (thin twin of the legacy invalidation list).
8. `features/admin/utils/status_summary.dart` (+ `status_format.dart`, providers in `status_providers.dart`), a port of the web's `status.ts` and its tests.
9. Save to Files destinations: `core/platform/media_store.dart`, `MediaChannel.kt` (`mm/media`), Share on Android 7-9, `Open Files` on iOS.
10. `getTotalDiskSpace` (Android `StatFs`, iOS `volumeTotalCapacityKey`) and `totalSpaceBytes()`.
11. Lifecycle under Cinematic: `skin_app.dart` already wraps every skin in `DownloadsLifecycleGate`; widget test added, nothing moved.
12. Resume after restart: widget test over `AppRestart`.

## B. Downloads (`screens/downloads/`)
Storage meter, Activity (every pause reason), queue rows, dialogue scan and narration blocks, saved library by series with pins, expandable chapter rows with swipe removal and Undo, Save to Files sheet and dialogs, STORAGE tab (`StoragePanel`), states (no profile, checking, empty, offline, error), keys `j` `k` `p` `Enter` `Delete` `↓` `↑`.

## C. Index (`screens/index/`)
Profile block, content-mode toggle, APK update banner and Install now, four sections with folio values, narration row, tablet columns, leader draw once per session.

## D. What's new and update cards
`overlays/whats_new_sheet.dart` (0.92 sheet, auto-open once per new build from the shell), `app_update_card.dart`, `sidestore_card.dart`.

## E. System status (`screens/admin/`)
Summary banner (typed headline), backend, checker, recent checks, source health (blocks on phones, own horizontal scroll table on tablets), per-card loading and error, non-admin notice, keys `r` `c` `j` `k` `Enter`.

## F. Cross-cutting
18+ absence (widget test with a real store), reduced motion, screen readers (`folioLabel` patterns added), focus rings, hit targets (tap target and label guidelines on every screen and the sheet).
