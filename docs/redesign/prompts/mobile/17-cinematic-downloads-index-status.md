# mobile/17 · Cinematic Downloads, Index, app updates and System status

Step 52 of the redesign series (track `mobile`, group 5). Depends on `mobile/16-cinematic-discover-search-sources-dialogue.md`. Its twin `web/17-cinematic-downloads-index-status.md` builds the same cluster on the web and may run at the same time in another session; you never touch `frontend/`.

## Goal

Build four pieces of the Cinematic skin in Flutter for iOS and Android, phone and tablet. **Downloads, "The offline edition"** at `/downloads` (shell branch 3): the storage meter set as one typographic line over a live rule, the native queue on the existing sqflite store with pause, resume, cancel, per-chapter retry and every pause reason, the dialogue scan and narration blocks, the saved library by series with pins, Save to Files and undoable removal, the STORAGE tab (cap, chapters at once, retention, Wi-Fi only, the two new per-profile download switches, Free up space, the image and metadata caches, the platform note), the device-side 18+ filter on every list and count, and downloads that resume on their own after an app restart. **The Index** at `/more` (branch 4): the phone hub set as a magazine index with folios and dot leaders that draw themselves. **What's new and app updates**: the release notes as errata and additions, shown once after an update, the Android APK update banner with its "Install now" steps, and the update and SideStore cards that Settings → About mounts in `mobile/18`. **System status** at `/admin/status` for admins. Every state, hardware key, haptic, reduced-motion variant and tablet layout is delivered.

## Read first

1. `docs/redesign/cinematic/DESIGN.md`
   - §2.1.1 (the raised-stock rule, and why `REMOVING…` is `ink.45`, never `ink.30`), §2.1.3, §2.1.6 (mood grades: the Index gets one), §2.2, §2.3, §2.4 (layers), §2.6 (rules, dot leaders), §2.7, §2.8.
   - §3.2, §3.3 (text-scale caps and reflow), §3.5, §4.2–§4.8 (durations, curves, the motion table incl. **Leader draw**, stagger, the reduced-motion table).
   - §5 (haptics: `download.start`, `download.done`, `download.fail`, `delete.confirm`, `undo`, `select`, `toggle.on/off`, `longpress.open`, `sheet.detent`, `success`, `error`) and §6 (`done`, `error`, `tick`, `toggle.on/off`).
   - §7 intro, §7.1, §7.2, §7.5 (slug lines), §7.9 (`CineSheetRoute`, the 0.92 detent), §7.10 (dialogs, the 1000 ms **arm delay**), §7.11 (toasts: 3600, errors 6000, with an action 8000), §7.12 (contents tabs, `TabBarView`), §7.13 (running head, `OFFLINE EDITION`), §7.14 (thumb index: the Downloads badge and its long-press to the queue), §7.16 (rows, **swipe slabs with `Dismissible`**), §7.17, §7.18 (determinate rule, leader dial, **download mark**, **storage meter**), §7.19 (badges), §7.21 (switches), §7.22 (row menus), §7.23 (notices), §7.24 (**local copies follow the gate**), §7.25 (avatars), §7.27 (masthead), §7.28 (`Credits`), §7.29 (content-mode chip, banner strips, `folioLabel()`).
   - §8.0.3 (route contract, branches 3 and 4), §8.0.4 (transitions), §8.0.5 (platform rules, the modal back order: exit select or reorder mode first), §8.0.8 (content mode), §8.0.9 (tablet rows for Downloads, Index and System status), §8.0.10.
   - **§8.23 Downloads and storage, §8.28 Index, §8.29 What's new and app updates, §8.31 System status** (read every line), §8.19 (the foreground note and pause-reason wording shared with series pages), §8.30.1 (server-backed section states, which the Status cards follow), §8.30.2 row 07 (the same storage controls appear in Settings in `mobile/18`), §8.32 (the offline edition in the app).
   - §10.1.2 and §10.2.2 (where the letter and typing reveals play), §11 (swipe row, long-press rows), §14, §15.3, §15.6, §15.7 (the 18+ on-device checklist), §15.8.
2. `docs/redesign/glass/DESIGN.md` §8.22 Downloads, §8.24 You and About, §8.26 System status and §15.6, only so the shared files you add stay skin-neutral (Glass builds these screens in `mobile/32` and `mobile/40` on the same providers).
3. `docs/redesign/inventory/00-decisions.md`.
4. `docs/redesign/stack-decision.md` §2.3 (mobile layout; logic held in widgets moves first in a no-pixel commit), §2.5 step 7 (downloads resume after the restart), §2.6, §3, §4 risks 9 and 11.
5. `docs/redesign/inventory/mobile.md` S21 (every numbered element), S22, S32, G1 (the Downloads count badge), G8, G9, G10 (foreground-only queue, resume, retention sweep), G12, M5, M9, §5a K17–K20, §6c (download states and queue mechanics).
6. `docs/redesign/inventory/capabilities.md` §21 (updates), §23 (app distribution, what's new, system status), §24 (offline downloads).
7. `docs/redesign/00-baseline.md`.
8. `docs/redesign/prompts-plan.json` (this entry and `mobile/01`, `mobile/05`, `mobile/06`, `mobile/07`, `mobile/15`, `mobile/16`).

## Skills to invoke, in this order

1. `superpowers:writing-plans`: write the plan to `docs/redesign/proof/mobile-17/plan.md`, one task per item in the Scope section.
2. `superpowers:subagent-driven-development` to run it (task groups A–F below, one after the other; never two Flutter commands at once); `superpowers:executing-plans` if subagents are unavailable.
3. `impeccable:impeccable` and `taste-skill:taste-skill` while building each screen. Where they contradict `cinematic/DESIGN.md`, the contract wins. `frontend-design:frontend-design` is for web UI; this step has none, so it is not invoked.
4. `superpowers:verification-before-completion` before claiming done.

## Before you start

- Branch `feat/vps-slim-source-native`. Other sessions commit in this checkout: stage only your own paths; never `git add -A`, `git stash`, `git reset` or `git checkout` on files you did not change.
- Stop and report if any of these is missing: `downloads`, `index` and `status` in the Cinematic `PENDING` set (`grep -rn "PENDING" mobile/lib/skins/cinematic`); the `mobile/05` primitives (sheets, dialogs with the arm delay, toasts, rows with swipe slabs, switches, notices, contents tabs); `mobile/lib/features/downloads/utils/mature_filter.dart` from `mobile/07`; the `mobile/16` scan widgets under `mobile/lib/skins/cinematic/screens/discover/dialogue/scan/` and `sourceHealthSummaryProvider`, `sourcesHealthProvider`, `describeHealth`, `sortWorstFirst`; the `mobile/01` startup re-queue of chapters found in `downloading` state (`grep -rn "resumePendingOnLaunch" mobile/lib`).
- Read the legacy screens you replace, only to learn their providers and calls: `mobile/lib/features/downloads/screens/downloads_screen.dart`, `widgets/active_downloads_panel.dart`, `widgets/downloads_storage_card.dart`, `widgets/export_downloads_action.dart`, `mobile/lib/features/more/screens/more_screen.dart`, `mobile/lib/features/settings/screens/storage_screen.dart`, `widgets/whats_new_sheet.dart`, `widgets/whats_new_auto_show.dart`. Never import from them and never copy their look.
- Read the data layer you build on: `features/downloads/{store,queue,providers,models,services,utils}` (`DownloadQueueController`: `pause`, `resume`, `cancelAll`, `cancelChapter`, `retryChapter`, `enqueueChapters`, `resumePendingOnLaunch`, `DownloadQueuePauseReason`), `storage_settings_provider.dart` (cap, retention, concurrency), `downloads_storage_providers.dart` (`totalDeviceDownloadBytesProvider`, `seriesStorageBreakdownProvider`, `freeUpSpace`), `features/settings/providers/{app_update_provider,app_changelog_provider,settings_provider}.dart`, `features/settings/models/app_version.dart`, `features/updates/repositories/updates_repository.dart`.

## Ground rules for this step

- **Track rule.** Work in `mobile/` only (native files under `mobile/android/` and `mobile/ios/` included, for items A9 and A10 only); stage explicit paths; do not edit `design/`, `brand/`, `frontend/` or `backend/`.
- **Skin boundary.** Screens in `mobile/lib/skins/cinematic/screens/…` import only `features/*/{models,providers,repositories,services,store,queue,utils,controllers}`, `core/`, `shared/`, the generated contract and their own skin. `test/skins/import_boundary_test.dart` enforces it.
- **Shared logic in `features/`**, skin-neutral, each file with a unit test. Logic now held in a legacy widget (the What's new auto-show decision, the metadata-cache invalidation list) moves to `features/` first, in its own no-pixel commit.
- **Paths** from `Routes` in `mobile/lib/skins/contract.g.dart`.
- **Tokens only** in `lib/skins/cinematic/**`.
- **Never** edit `backend/connectors/`, never touch production containers or `/srv/manhwamaniacs/{app,data}`.
- **RAM guard.** `free -m` before every `flutter analyze`, `flutter test` and harness run; stop if `available` < 1024 MB; `pgrep -f "next build"` must print nothing; never two Flutter commands at once. No Gradle or Xcode on this box: CI builds the APK and the iOS dry run.

## Scope: every item this step delivers

Remove `downloads`, `index` and `status` from the Cinematic `PENDING` set when their screens are done. Each screen registers its hardware-keyboard keys under its masthead title (`Downloads`, `System status`) and gives route focus to its level-1 heading.

### A. Shared data-layer work (skin-neutral, each with a unit test)

1. `mobile/lib/features/downloads/utils/pending_removals.dart`: deferred chapter removal. `PendingRemovals` (exposed as a kept-alive `pendingRemovalsProvider`) with `schedule(String key, Future<void> Function() run, {Duration delay = const Duration(milliseconds: 8000)})` returning a handle with `undo()`; `isPending(key)` (the rows read it to show `REMOVING…`); `flushAll()` runs every pending removal at once and is called when the app goes to `AppLifecycleState.paused` or `detached` (the Cinematic shell's `AppLifecycleListener`); a second schedule for the same key replaces the first. `run` calls the existing deletion in `features/downloads/store/downloads_deletion.dart`. The timer factory is injected (`Timer Function(Duration, void Function())`), so the test drives time: undo cancels, expiry runs, flush runs all, replace.
2. **The two download switches.** "Save the next chapter while I read": if `mobile/12` did not already add it (`grep -rn "save-next\|saveNext" mobile/lib/features`), add `saveNextProvider` in `mobile/lib/features/downloads/providers/download_switches_provider.dart` over the profile-scoped SharedPreferences key `mm.downloads.save-next.u{user}p{profile}` (default `true`) and make the engine's next-chapter auto-queue read it through the `saveNextEnabled` input `mobile/12` item B2 left for it (default `() => true`). "Download new chapters of followed series automatically": `autoNewProvider` over `mm.downloads.auto-new.u{user}p{profile}` (default `false`) in the same file. Build both keys with `mobile/08`'s public `profileScopedKey(ref, prefix:, deviceKey:, watch:)` in `mobile/lib/core/storage/profile_scoped_key.dart` (`grep -rn "String profileScopedKey" mobile/lib`); if it is missing, create it there exactly as `mobile/08` item 2 specifies (a public copy of the private `_scopedKey`, leaving the private copies alone), never a second helper elsewhere. Test defaults and per-profile isolation.
3. `mobile/lib/features/downloads/utils/auto_download.dart`: `List<ChapterQueueRequest> planAutoDownload({required List<UpdateNotification> unread, required List<FollowedSeries> follows, required Set<String> savedKeys, required int? freeBytes, required int? capBytes, required int usedBytes, required bool wifiOnly, required bool onWifi})` returning at most **20** chapters: the chapters named by **unread** new-chapter notifications of followed series whose per-series `notify` is on, skipping chapters already saved, returning nothing when `wifiOnly && !onWifi`, stopping before the estimated size would push free space under the **1.5 GB** floor or `usedBytes` over the cap (estimate 8 MB per manga chapter and 0.2 MB per novel chapter). And `AutoDownloadRunner` (`autoDownloadRunnerProvider`): runs on app open and on every `AppLifecycleState.resumed`, right after the unread-notifications poll settles, only while `autoNewProvider` is on, a profile is active and the device is online; it queues through `DownloadQueueController.enqueueChapters` and reports the count. Mount it in `mobile/lib/skins/cinematic/shell.dart` with the toast "Queued 6 new chapters." ("Queued 1 new chapter." for one). Test the planner: unread only, notify off skipped, saved skipped, the floor, the cap, Wi-Fi only, the limit of 20.
4. `mobile/lib/features/downloads/utils/storage_meter.dart`: `StorageMeterModel? storageMeter({required int appBytes, required int? capBytes, required int? deviceFree, required int? deviceTotal})` returning the three segment fractions (other apps = `total − free − appBytes` in `ink.60`, ManhwaManiacs in `spot`, free in `rule.1`), the cap tick fraction at `(other + cap) / total` (none when unlimited), `nearFloor` (free ≤ 1.5 GB), `capReached` (`appBytes ≥ capBytes`) and the folio line `4.1 GB OF 10 GB · 21 GB FREE ON THIS PHONE` (unlimited: `4.1 GB · 21 GB FREE ON THIS PHONE`; iPad and Android tablets say `ON THIS TABLET` when the shortest side is ≥ 600 dp, passed in as `deviceNoun`); when `deviceTotal` is null the model has two segments (app and free, over `appBytes + free`) and no "other" segment; `null` only when `deviceFree` is null too. Byte formatting uses the existing formatter (`grep -rn "String formatBytes\|formatBytes(" mobile/lib`); one decimal, `MB` under 1 GB. Test the maths, the tick, the floor, the cap, the unlimited and null cases.
5. `mobile/lib/features/downloads/utils/queue_summary.dart`: from `DownloadQueueState` and the store rows, `QueueSummary {headline: downloading | waiting | paused, current: {seriesTitle, chapterLabel, pageDone, pageTotal, kind: manga | novel | audio}, alongside, seriesTally: {saved, total}, waitingCount, failedCount, pauseReason}` so the skins never read controller internals. Test each pause reason and kind.
6. `mobile/lib/features/settings/utils/whats_new_policy.dart` (moved out of `whats_new_auto_show.dart` in a no-pixel commit): `bool shouldAutoOpenWhatsNew({required int currentBuild, required int? lastSeenBuild})` (true only when a stored build exists and is lower; a first run stores the current build without opening) and `String formatReleaseFolio(ChangelogEntry e)` → `3.5.0 · BUILD 57 · 28 SEP 2026`. The legacy widget keeps working through the moved function. Test both.
7. `mobile/lib/features/settings/services/metadata_cache.dart` (moved in the same no-pixel commit if the invalidation list lives in `storage_screen.dart`): `clearMetadataCache(WidgetRef or Ref)` invalidating the same providers the legacy "Clear metadata cache" invalidates.
8. `mobile/lib/features/admin/utils/status_summary.dart`: a port of the web's summary rules (find the file with `find frontend/src -path '*admin*' -name status.ts`: at the baseline it is `frontend/src/app/admin/status/status.ts`; after the route-group move it is under `app/(app)/admin/status/`, and `web/17` may have moved it to `frontend/src/features/admin/status/status.ts`; mirror its state rules and their test cases exactly): `StatusSummary summarise({backend, checker, runs, sourceHealth, now})` → `{worst: healthy | warning | down | unknown, problems: [String]}`. The headline is §8.31's, not the legacy file's: "Everything is running." when nothing is wrong, otherwise "{n} things need attention." with the count in digits as §8.31 writes it ("2 things need attention."; one problem: "1 thing needs attention."). Port its test cases to `mobile/test/features/admin/status_summary_test.dart`. Providers in `mobile/lib/features/admin/providers/status_providers.dart`: `backendHealthProvider` (`GET /health` every 15 s while listened to, `autoDispose`, exposing the next-poll instant for the `LIVE · 15 S` folio), reuse `sourcesHealthProvider` (every 30 s while listened to), `updateSettingsProvider`, `updateRunsProvider` (limit 8), and `manualCheckProvider` over `UpdatesRepository.triggerCheck` (`409 check_already_running` maps to "A check is already running.").
9. **Save to Files destinations (§8.23 M5).** Keep `ChapterExporter`'s documents export (iOS: Files › On My iPhone › ManhwaManiacs › Exports › {series}). Android API 29 and up: after exporting into the app's documents directory, copy each produced file into MediaStore `Downloads` with `RELATIVE_PATH = "Download/ManhwaManiacs/Exports/{series}/"` through a new method channel `mm/media` method `saveDownload(relativePath, name, mime, path)` (no permission needed): Dart side `mobile/lib/core/platform/media_store.dart`; Kotlin side `mobile/android/app/src/main/kotlin/com/manhwamaniacs/reader/MediaChannel.kt` registered from `MainActivity.configureFlutterEngine`, inserting into `MediaStore.Downloads.EXTERNAL_CONTENT_URI` with `IS_PENDING = 1`, copying the bytes through `contentResolver.openOutputStream`, then `IS_PENDING = 0`; mime `image/webp`, `image/jpeg` or `image/png` by page type (`features/downloads/services/page_image_type.dart`) and `application/vnd.comicbook+zip` for CBZ. API 24–28: the documents export stays and the result dialog offers `Share` (`share_plus` 12.0.2: `SharePlus.instance.share(ShareParams(files: [XFile(path)]))`) instead of a path. iOS `Open Files` launches `shareddocuments://{documentsPath}` through `url_launcher`. Unit-test the Dart side's destination choice by API level with a fake channel. `mobile/21` adds its share-card method to the same `mm/media` channel.
10. **Device total space** for the meter: add `getTotalDiskSpace` beside the existing `getFreeDiskSpace` on the `com.manhwamaniacs.reader/native` channel (Android `StatFs(filesDir.path).totalBytes` in `MainActivity.kt`; iOS `.volumeTotalCapacityKey` on the documents URL in `AppDelegate.swift`) and `totalSpaceBytes()` on `DeviceStorageInfo` (null on failure, like `freeSpaceBytes`). Items 9 and 10 are the only native changes in this step and go in one commit; after pushing it, check the CI run once (`gh run list --branch feat/vps-slim-source-native --workflow tests.yml --limit 3`, no polling loop): the `flutter build apk --release` job and the iOS dry run must be green before the screens that use them are committed.
11. **Lifecycle behaviours (mobile G10) under the Cinematic skin.** Today `features/downloads/widgets/downloads_lifecycle_gate.dart` (a widget holding logic, mounted by the legacy `lib/app/app.dart`) runs the retention sweep on launch and resume, the queue resume on launch, the foreground gating (pause on background with the `backgrounded` reason, resume on return), the progress and bookmark outbox flushes and the source-progress backfill. Check that the skin-neutral `mobile/lib/app/skin_app.dart` from `mobile/01` wraps every skin in it (`grep -rn "DownloadsLifecycleGate" mobile/lib/app`). If it does not, move its logic into `mobile/lib/features/downloads/providers/downloads_lifecycle.dart` in a no-pixel commit (the legacy gate delegates to it) and mount it once in `skin_app.dart`, so Cinematic and Glass both get it. Also call `ocrRunControllerProvider`'s `setForeground` from the same place if the gate does not already. Widget test under the Cinematic skin: `AppLifecycleState.paused` gives the queue the `backgrounded` reason; `resumed` runs the retention sweep and resumes the queue.
12. **Downloads resume after a restart** (stack-decision §2.5 step 7): add a widget test that builds the Cinematic shell over a fake store holding one chapter in `downloading` state, performs `AppRestart.of(context).restart()`, and asserts the queue re-queued it and the Activity block shows it.

### B. Downloads, "The offline edition" (`/downloads`, ScreenId `downloads`), §8.23, mobile S21, S32, M5

Every list, count and badge first passes through `features/downloads/utils/mature_filter.dart` (the active profile's gate), then through the content-mode filter. The storage meter keeps the app's total bytes, because it names no series. Nothing ever says files are hidden. Queued or running downloads of a now-hidden series pause silently (the `mobile/07` filter; verify with a test).

**Masthead:** kicker `No. 05 — ON THIS DEVICE` (`SetHeading` trigger `mount`), title "Downloads" (`type.masthead` 40/40), deck "Saved for {profile} · reads with no connection" (`type.deck` `ink.60`), `rule.heavy` drawn after the letters. The running head carries the `ContentModeChip` (`MANGA ▾`) when novels are enabled.

**Contents tabs** `SAVED · STORAGE` (§7.12, a `TabBarView` pager; the tab is the `?tab=storage` query, written with `context.go` on the same location; nested horizontal rails never steal the swipe). The thumb-index Downloads long-press (§7.14) opens this screen with the queue expanded.

**SAVED tab**, in this order:
1. **Storage meter** (§7.18, model A4): the folio line in `type.folio` (IBM Plex Mono 500 12/16, +0.02em) as one typographic line, then the 8 px bar (radius 0) in its segments, the 2 px `ink.100` cap tick above the bar, and a `NOTE` kicker line (`spot`) when the floor is near ("Downloads stop before the last 1.5 GB of this phone's space.") or the cap is reached ("Your 10 GB limit is full."). Semantics: a value "4.1 of 10 gigabytes used" through `folioLabel()`. Tapping the meter switches to the STORAGE tab. **Signature moment:** when a chapter finishes saving, its row's download mark fills with `set` and the meter's `spot` segment grows by exactly its size (width change 240 ms `durLine` `easeSet`), so the edition visibly gets thicker.
2. **Activity** (only while something runs or is paused, pinned at the top), from `QueueSummary` (A5): kicker `DOWNLOADING` / `WAITING TO START` / `PAUSED`; the current chapter: series title in `type.title`, `CH 12 · PAGE 7 OF 40` in `type.folio` (novels `SAVING THE TEXT…`, audio `SAVING THE AUDIO…`, before the page list `READING CHAPTER DETAILS…`) with a 2 px determinate rule (track `rule.1`, fill `spot`, width 240 ms `easeSet`); "2 more chapters downloading alongside"; "12 of 40 saved in this series" with its own rule; the pause reason as a `NOTE` line: user "Paused by you. Nothing was lost; resuming carries on from the same page." + `Resume`; floor "Paused: this phone is almost full. Downloads stop before the last 1.5 GB."; cap "Paused: your 10 GB limit is full." + `Storage settings` (switches to STORAGE); backgrounded "Paused while the app is in the background."; controls `Pause all` / `Resume all` (secondary sm; `DownloadQueueController.pause` / `resume`) and `Cancel all` (`quiet` `proof`) → dialog "Cancel all downloads?" / "Everything queued, downloading or failed is dropped. Finished chapters stay." with `Cancel all` destructive under the 1000 ms arm and `Keep them` `quiet` (initial focus); `Show queue ⁽⁸⁾` / `Hide queue` (`quiet`, superscript count) expanding the queue rows: a 16 px download mark (`clock`-style queued dashed square or the failed `!` square), "{series} · CH 12", "Waiting" / "Downloading" / "Failed — {error}" (`proof` caption for failures), `Retry` (`quiet`, failed only; `retryChapter`) and `Remove from queue` (`bare` `x`; `cancelChapter`); then the foreground note in `type.caption` `ink.60`: "Downloads run while the app is open; leaving pauses them and coming back picks up where they stopped."
3. **Dialogue scan** (only while an OCR run exists): the `mobile/16` `DialogueScanBlock`.
4. **Narration** (only while `mobile/15`'s `activeNarrationJobsProvider` reports jobs): `mobile/15`'s exported `NarratingIndicator` (kicker `NARRATING 3 CHAPTERS`) with a determinate rule per book, each row opening that book's page with the Audiobook sheet open (the `mobile/15` entry).
5. **Saved library**: kicker `ON THIS PHONE — BIGGEST FIRST` (`ON THIS TABLET` on tablets); one block per series, largest first (`downloadedSeriesProvider`): cover 48 × 72 (radius 0, `paper.1` placeholder, the §7.7 inner hairline), title in `type.title` opening the series page (`featureByFollow` when followed, else `feature`), a folio `40 CHAPTERS · 3 WITH AUDIO · 1.2 GB` or `12 OF 40 SAVED · 800 MB`, the pin toggle (`bare` `push-pin` 24 Light; pinned = Fill + 2 px `spot` rule 4 px under the square; semantics "Pin series" / "Unpin series"; tooltip "Pinned series are never auto-deleted"; haptic `select`), an overflow `dots-three` menu with `Save to Files…` (manga with saved chapters) and `Remove all downloads` → dialog "Remove every saved chapter of {series}? Your reading progress is kept." (destructive, 1000 ms arm; haptic `delete.confirm` on confirm), and an expand chevron (`caret-down` 16, rotates 180° in 240 ms `easeSettle`; semantics expanded state).
6. Expanded chapter rows (§7.16 standard row, 56 dp): the 16 px download mark (§7.18: saved `check-square` Fill `set`; queued dashed square `ink.45`; downloading fills bottom-up in `spot`; failed square outline `proof` with `!`; paused two 2 px `spot` bars; each with a tooltip and semantics from mobile §6c), `CH 12` in `type.folio.lg` plus, for audio rows, `· AUDIO` with a `headphones` 16 glyph, and a status caption (`type.caption`): `SAVED · 24.3 MB`, `QUEUED`, `DOWNLOADING`, `FAILED — {error}` (`proof`); trailing actions: the `mobile/16` `ScanDialogueButton` (saved manga chapters, OCR available), `Save to Files` (`bare` `export` 20; saved manga chapters), and `Remove` (`bare` `trash-simple` 20, semantics "Remove chapter 12 from this phone"; for audio rows "Remove saved audio"). A left swipe reveals the 72 px `proof` `Remove` slab (black label) through `Dismissible(direction: DismissDirection.endToStart, dismissThresholds: {DismissDirection.endToStart: 0.5})`, committing past 50 % with `springRelease` (504 ms Flutter duration). Remove: the row reads `REMOVING…` in `ink.45` (`ink.60` when the row sits on `paper.1`), a toast "Removed chapter 12." + `Undo` held 8000 ms (haptic `undo` on Undo), and the deletion runs through A1. Tapping a saved chapter opens it with the **Dip** (440 ms: out 160 `easeLift`, hold 40, in 240 `easeSettle`) in the manga reader or the novel reader by its kind.
7. Note (`type.caption` `ink.60`): "Saved chapters live inside ManhwaManiacs and open from here. For a copy you can open elsewhere, use Save to Files."

**STORAGE tab** (the `StoragePanel` widget, reused by Settings → Downloads & storage in `mobile/18`):
- The meter at full width.
- `STORAGE CAP` single-select slug line `2 GB · 5 GB · 10 GB · 20 GB · UNLIMITED` (mobile K17, `storageCapProvider`; haptic `select`; a lower cap than the current usage calls `retryAfterStorageChange` and pauses with the cap reason).
- `CHAPTERS AT ONCE` `1 · 2 · 3` (mobile K18, `downloadConcurrencyProvider`) with the explainer "How many chapters download side by side. More is faster on good connections."
- `DELETE AFTER READING` `OFF · 24 H · 48 H · 7 D` (mobile K19, `retentionIntervalProvider`) with the caption "Finished chapters older than this are removed; pinned series and the chapter you're reading never are."
- "Download on Wi-Fi only" switch (mobile K20, `wifiOnlyDownloadsProvider`; caption "Automatic downloads wait for Wi-Fi. Chapters you pick yourself always download."; it gates the next-chapter auto-queue and A3).
- "Save the next chapter while I read" switch (A2, default on, per profile; caption "The chapter after the one you're reading is saved in the background.").
- "Download new chapters of followed series automatically" switch (A2, default off, per profile; caption "When you open the app, new chapters from series with notifications on are saved, up to 20 at a time.").
- `BY SERIES`: credits rows (pin mark `push-pin` 12 Fill for pinned series, title ........ `12 CH · 240 MB`), from `seriesStorageBreakdownProvider`.
- `Free up space` (secondary): `freeUpSpace()`; toast "Removed 14 chapters." or "Nothing to free up right now."
- **Image cache** card: kicker `IMAGE CACHE`, current size in `type.folio.lg` (a greeked bar while loading; "Couldn't read the cache size." on error), `Clear image cache` (`quiet`) → toast "Image cache cleared."
- **Metadata cache** card: kicker `METADATA CACHE`, the line "Series details and lists kept in memory. Clearing it refetches them.", `Clear metadata cache` (`quiet`, A7) → toast "Metadata cache cleared."
- Platform note: iOS "Browse, copy or delete saved chapters in the Files app: On My iPhone › ManhwaManiacs." with `Open Files` (A9); Android "Files live in the app's private storage."

**Save to Files sheet** (M5, a `CineSheetRoute`, content-fit): kicker `SAVE TO FILES`, title the series, two rows: `Page images` ("A numbered folder per chapter.") and `CBZ file` ("One file per chapter, for comic reader apps."); then a non-dismissible progress dialog ("Saving to Files…" + a 24 px leader dial); then the result dialog: "Saved 12 chapters · 480 pages" + the path in `type.folio` inside a `SelectableText` ("Files › On My iPhone › ManhwaManiacs › Exports › {series}" on iOS, "Files › Downloads › ManhwaManiacs › Exports › {series}" on Android 10+) + the skipped count ("2 chapters were still downloading and were skipped.") + `Done`; on Android 7–9 the result offers `Share` instead of a path. Errors as toasts: "Nothing to save yet — these chapters are still downloading.", "Couldn't save to Files. Check your free space."

**Tablet (≥ 600 dp, §8.0.9):** the phone order; the storage meter full width; the saved library in two columns from 900 dp.

**Transitions.** In: Cut (thumb-index tab). Out: Dip into saved chapters.

**Gestures.** Swipe chapter rows to remove; long-press (450 ms, haptic `longpress.open`) a series block for `Pin` / `Unpin`, `Save to Files…`, `Remove all downloads` and `Open series` (the same items as its `dots-three`); no pull to refresh (local data). Android back exits nothing here except an open sheet or dialog.

**Hardware keys.** `j` / `k` next / previous series block; `Enter` expands or collapses it; inside an expanded block `↓` / `↑` move through chapter rows; `Delete` (or `Backspace`) removes the focused chapter, and on a focused series block opens its remove dialog; `p` pauses or resumes all.

**States (each built, widget-tested and captured):** no profile (notice "Choose a profile to see its downloads." + `Choose a profile`, which pushes the picker takeover); checking ("Checking what's stored…" with a 24 px leader dial after 400 ms); empty (notice `NOTHING SAVED YET`, headline typed "Chapters you save open with no connection.", then a rail of Continue reading series (`continueReadingProvider`) with `Download next 5` (secondary sm) on each, which queues the next five unread chapters through the existing series download helper); offline (a banner strip under the running head: kicker `OFFLINE EDITION`, "You're offline. Only saved chapters open."); error (`CORRECTION` notice "Couldn't read downloads." + `Try again`). Haptics: `download.start` when the queue accepts, `download.done` when a chapter saves (sound `done`), `download.fail` on a failure (sound `error`).

### C. The Index (`/more`, ScreenId `index`), §8.28, mobile S22

1. Mood grade behind the top 30 % (§2.1.6) with the raised-stock scope on it. Masthead: kicker `THE INDEX`, title "Index" (`type.masthead`, `SetHeading` trigger `mount`), `rule.heavy`. The running head carries the `ContentModeChip` when novels are enabled.
2. **Profile block**: 44 px avatar (§7.25), the profile name in Bodoni Moda Italic at `type.subhead` 20/24, `@username` in `type.caption` plus the `ADMIN` credit for admins, the mood in `type.caption` `ink.60`; actions `Switch profile` (secondary sm: pushes the picker as a takeover by Dip, the `mobile/07` flow, without clearing the active profile), `Profiles` (`quiet`, pushes `Routes.profilesManage`) and `Switch account…` (`quiet`, the §8.5 sign-out dialog `mobile/07` built).
3. The `mobile/05` content-mode toggle (`MANGA / NOVELS`) when novels are enabled.
4. **Update banner** (Android APK channel only, when `appUpdateProvider` reports a newer build): a banner strip (`paper.0`, 2 px `spot` left rule): kicker `UPDATE AVAILABLE · 3.5.1 (58)`, the credit `INSTALLED 3.5.0 (57)`, `Download update` (primary sm; opens the `/app/download` URL from `AppVersionInfo` with `url_launcher` `LaunchMode.externalApplication`; failure toast "Couldn't open {url}"), and two notes in `type.caption` `ink.60`: "Downloading doesn't install it automatically." and "Updating from 1.2.x? Uninstall the old app first." After the download opens, the **Install now** dialog: title "Install now", body "The new version is downloading to your device.", three steps with folios `01` "Open the downloaded APK from your notification shade or Downloads.", `02` "Tap Install and confirm any prompt.", `03` "Return here: the version updates and this banner clears on its own.", and `Got it` (`quiet`). Re-checked on every app resume (the existing provider behaviour).
5. Sections as credits lists (row 48 dp: label in `type.ui` → dot leaders (`·` at 0.5 em in `ink.30`, `type.folio`) → a folio value in `type.folio` `ink.45` → `caret-right` 16 Regular `ink.45`), each section under a `type.kicker` label:
   - `YOU`: The Numbers ...... `12-DAY STREAK` (the current streak from `statisticsProvider`, preceded by `mobile/08`'s 24 px `StreakFlame` in the same tier and state, §9.2.2 "the same flame … in the Index row"; no value and the ember dot at 0; push `Routes.numbers`); The Annual ...... `2026` (the current year; the root-navigator takeover by Dip); Circle (push `Routes.circle`; no value until `mobile/22` wires `2 NEW`); Picks ...... `8 ASKS LEFT` (`suggestAvailabilityProvider.remainingToday` while available; `go` to branch 2).
   - `READING`: Updates ...... `14` (unread count); Collections ...... `9`; History; Bookmarks ...... `23` (all `go` to branch 1); Dialogue search (only while `ocrFeatureVisibleProvider` is true; `go` to branch 2).
   - `THE HOUSE`: Settings (push `Routes.settings`); Storage ...... `4.1 GB` (`totalDeviceDownloadBytesProvider` for the profile; `go` to `/downloads?tab=storage`); Backup & restore (admin, push `/settings/backup`); Members (admin, push `/settings/members`); System status (admin) ...... `84/89 OK` (`ok`/`total` from `sourceHealthSummaryProvider`; push `Routes.status`).
   - `ABOUT`: What's new ...... `3.5.0` (the latest changelog version; opens the What's new sheet, item D); App update ...... `AVAILABLE` (Android APK channel only, when newer; scrolls to and focuses the banner); Version ...... `3.5.0 (57)` (`package_info_plus`); Licenses (push `/settings/about?licenses=1`, which `mobile/18` opens as the restyled licence page).
   - Every folio value reads through `folioLabel()` ("12-day streak", "4.1 gigabytes").
6. Narration indicator row while `activeNarrationJobsProvider` reports jobs: `mobile/15`'s exported `NarratingIndicator` (`NARRATING 3 CHAPTERS`) laid out in the Index row anatomy, opening the book's page with the Audiobook sheet.
7. **Tablet ≥ 900 dp:** two columns with a 1 px `rule.1` column rule: `YOU` and `READING` left, `THE HOUSE` and `ABOUT` right; the profile block spans both. Below 900 dp one column.
8. **Signature moment:** the dot leaders draw themselves (**Leader draw**: a clip reveal left → right, 320 ms per row, rows 24 ms apart, `easeSettle`) the first time the Index opens in an app session (a kept-alive `indexLeadersDrawnProvider`, reset by a restart). Reduced motion: the leaders are present at rest.
9. Transitions (§8.28): branch-4 destinations are pushed by Page with a back arrow; cross-branch destinations use `go` and play the phone section change (Cut + Set + Folio flip) and move the notch; The Annual opens on the root navigator as a takeover by Dip; Switch profile pushes the picker takeover by Dip; What's new rises as a sheet; Switch account inserts its dialog.
10. States: loading (values show `–`); a failed count hides its value only; offline (values from the provider caches and the `OFFLINE EDITION` micro badge beside the kicker).

### D. What's new and the app update cards (§8.29, mobile G8, G9)

1. **What's new** (`mobile/lib/skins/cinematic/overlays/whats_new_sheet.dart`): a `CineSheetRoute` at the 0.92 detent, max width 720 centred on tablets: kicker `WHAT'S NEW`, title "Release notes" (`type.subhead`); entries from `appChangelogProvider`: the folio `formatReleaseFolio(entry)` in `type.folio.lg` (IBM Plex Mono 500, 15/20), a `LATEST` badge (1 px `ink.100` outline, `ink.100` text, `type.micro`) on the first entry, highlights as a list with `—` dashes in Newsreader 16/24 (`type.body`), 24 px between entries with a `rule.1` hairline. Loading: a 24 px leader dial with the kicker `LOADING` after 400 ms. Unavailable: the notice "Release notes aren't available right now." Opened from the Index, from Settings → About (`mobile/18`), and automatically once per new build when `shouldAutoOpenWhatsNew()` says so, checked by the Cinematic shell after the active profile loads and only while a shell branch route is current (never over a reader, a takeover or a sheet); closing it stores the current build in `settings_last_seen_changelog_build`. The legacy `WhatsNewAutoShow` must run only under the legacy skin (`grep -rn "WhatsNewAutoShow" mobile/lib/app mobile/lib/skins`; move its mount into `skins/legacy/legacy_skin.dart` if it wraps every skin), so the two sheets never both open. Android back and swipe-down close it; `Done` closes it.
2. **App update cards** (`mobile/lib/skins/cinematic/screens/index/app_update_card.dart`, mounted in Settings → About by `mobile/18`): Android APK channel: up to date `UP TO DATE — 3.5.0` in `set`; available `3.5.0 → 3.5.1` + `Download update` (the same flow as the banner); unreachable "Couldn't check for updates."; loading greeked. iOS SideStore channel (`sidestore_card.dart`): kicker `MANAGED BY SIDESTORE`, the explanation "This build is installed through SideStore. It updates when SideStore refreshes this source.", the source URL (`{apiBaseUrl}/app/source.json`, from `AppVersionInfo`) in `type.folio` inside a `SelectableText`, `Copy source URL` (`quiet`; `Clipboard.setData`; toast "Source URL copied"), and the caption "SideStore re-signs the app every 7 days. Open SideStore once a week so it keeps launching."

### E. System status (`/admin/status`, ScreenId `status`), §8.31

Data: the A8 providers.

1. Masthead: kicker `ADMINISTRATION`, title "System status" (`SetHeading` trigger `mount`), deck "Backend health, the update checker, per-source failures and update runs.", `Refresh all` (`quiet`, `arrow-clockwise` that becomes a 16 px leader dial while any card refetches) and a live folio `LIVE · 15 S` counting down once per second to the next health poll.
2. **Summary**: a banner strip on `paper.0` with a 2 px left rule tinted by the worst state (`set` all healthy, `spot` warnings, `proof` something down, `ink.45` unknown), the headline typed at 50 ms per grapheme ("Everything is running." or "2 things need attention."), and the problems in `type.body`.
3. **Backend** credits (§7.28 `Credits`, one column): `STATE HEALTHY` (the value tinted by state), `NAME`, `VERSION 3.5.0` in Plex Mono, `PROBE GET /health`.
4. **Update checker** credits: `LAST RUN 21:04 · 12 MIN AGO`, `NEXT ≈ 21:34 · IN 18 MIN`, `INTERVAL 30 MIN`, `FAILED RUNS (RECENT) 0` (the value in `proof` when > 0), the server's error block in IBM Plex Mono on `paper.1` (text `ink.60`), and `Check now` (secondary; loading segment while starting; haptic `success` or `error` on the answer). A footnote in `type.caption`: "The next run is an estimate from the last run and the interval."
5. **Recent checks**: up to 8 blocks: a status badge (`FINISHED` 1 px `set`, `RUNNING` 1 px `spot`, `FAILED` 1 px `proof`, anything else `ink.45`), the trigger in `type.kicker`, `212 SERIES · 3 NEW` in `type.folio`, the start time, and the error in Plex Mono when present. Empty: "No update checks have run yet."
6. **Source health**: sorted worst-first (`sortWorstFirst`): on phones one block per source (the 6 × 6 mark, name, id in Plex Mono, a `DEMOTED` badge (1 px `ink.60`), `LAST PROBE 4 MIN AGO`, the message, and the last error as a collapsible Plex Mono block with `caret-down` and an expanded semantics state); on tablets a table inside its own horizontal `SingleChildScrollView` (min width 720) so the page never scrolls sideways.
7. Footer note in `type.caption` `ink.60`: "Everything on this page is read from endpoints the server already exposes; nothing here changes a setting except Check now."
8. **Non-admin** (`useCurrentUser` equivalent: the `authControllerProvider` user's admin flag): the notice `ADMINISTRATORS ONLY`, headline typed "System status is instance-wide.", deck "Ask the owner to check it.", `Back to Tonight`.
9. **States:** resolving (masthead only while `/auth/me` resolves); each card's loading (its credits greeked at their exact heights, flicker) and error (a `CORRECTION` line under the card header with the API message and a `quiet` `Retry` for that card only).
10. **Hardware keys:** `r` refreshes every card; `c` runs Check now; `j` / `k` move through the source-health rows; `Enter` expands or collapses the focused row's last error.
11. Pull to reprint refreshes every card (haptic `refresh.arm`).

### F. Cross-cutting on all screens of this step

- **18+:** absence, never a lock (§7.24): hidden series never appear in Downloads, the thumb-index Downloads badge counts only visible chapters, the meter total still includes their bytes, and no caption or count mentions them.
- **Reduced motion** (`CineMotion.reduced(context)`): letter reveals fade the whole string in 200 ms; typed headlines show at once with no caret; Set becomes a 160 ms fade; the leader draw is at rest; rules present at rest; the meter's segment change and the chevron rotation apply at once; Dip and sheet or dialog motion become 150 ms fades; the swipe release finishes with a 150 ms fade; programmatic scrolls jump. Leader dials, the indeterminate rule and determinate rules keep updating.
- **Screen readers:** download marks, meters and folios carry spoken labels (`folioLabel()`); toasts with an action never time out while a screen reader is running (`MediaQuery.accessibleNavigationOf`).
- **Focus (hardware keyboard):** `CineFocusRing` on every control; sheets and dialogs trap focus and return it to the trigger; the initial focus in a destructive dialog is the `quiet` cancel.
- **Hit targets:** 44 × 44 pt iOS, 48 × 48 dp Android on every control, including the trailing chapter-row icons (their hit boxes may overlap the row's padding, never each other).

## Values you need (copied from `cinematic/DESIGN.md`)

| What | Value | Section |
|---|---|---|
| Grounds | `paper.0` `#000000`, `paper.1` `#0B0B0A`, `paper.2` `#121211`, `paper.3` `#1A1A18`, `paper.4` `#232220` | §2.1.1 |
| Inks | `ink.30` `#4D4B47` (disabled only), `ink.45` `#7A7770` (on `paper.0` only), `ink.60` `#9A978F`, `ink.80` `#C9C6BE`, `ink.100` `#F3F0E8` | §2.1.1 |
| Accent and semantic | `spot` `#F4D03F`, `spot.wash` `rgba(244,208,63,0.16)`, `proof` `#FF5B4A`, `proof.wash` `rgba(255,91,74,0.12)`, `set` `#57D68D`, `rule.1` `#2B2A27`, `rule.2` `#3D3C38` | §2.1.2, §2.1.3 |
| Scrim behind dialogs and sheets | `scrim.modal` `rgba(0,0,0,0.78)`, never blurred | §2.1.4 |
| Durations (`durX`) | tick 80, beat 160, line 240, column 320, spread 480, snap 120, reduced 150, clip 200, rise 360, arm 1000, holdToast 3600, holdToastError 6000, holdToastAction 8000, loopRule 1200, leader 1000, flicker 1400, holdDip 40 (ms) | §2.8.4, §4.2 |
| Curves | `easeSettle` `Cubic(0.16, 1, 0.3, 1)`, `easeLift` `Cubic(0.7, 0, 0.84, 0)`, `easeTurn` `Cubic(0.65, 0, 0.35, 1)`, `easeSet` `Cubic(0.2, 0, 0, 1)` | §4.3 |
| Springs | `springRelease` 420 ms bounce 0 → Flutter 504 ms; `springSheet` 480 ms bounce 0 → 576 ms | §2.8.4, §4.4 |
| Sheet release | dismiss below 30 % height or faster than 800 px/s; rubber band c = 0.35 | §7.9 |
| Leader draw | 320 ms per row, 24 ms stagger, `easeSettle` | §4.5 |
| Type (phone) | `type.masthead` Bodoni Moda 800 40/40 (−0.035em); `type.kicker` Archivo wdth 62 wght 700 11/16 (+0.16em, upper); `type.folio` Plex Mono 500 12/16; `type.folio.lg` 15/20; `type.title` Archivo 600 15/20; `type.ui` 15/20; `type.caption` Archivo wdth 90 wght 450 13/16; `type.subhead` Bodoni Moda 600 20/24; `type.body` Newsreader 16/24; `type.micro` Archivo wdth 62 wght 700 10/12 | §3.2 |
| Row heights | standard 56 (one line) / 72 (two lines); credits 40 (Index rows 48); settings rows min 56; Sources rows 64 | §7.16, §8.28 |
| Swipe slab | 72 px, `proof` fill, `#000` label, commit past 50 % | §7.16 |
| Storage meter | 8 px bar; other apps `ink.60`, app `spot`, free `rule.1`; 2 px `ink.100` cap tick above; floor 1.5 GB | §7.18, §8.23 |
| Hit areas | 44 × 44 pt iOS, 48 × 48 dp Android | §14.6 |

## File layout

```
mobile/lib/core/storage/profile_scoped_key.dart                     (only if mobile/08 did not create it; mobile/08's signature)
mobile/lib/features/downloads/utils/{pending_removals,auto_download,storage_meter,queue_summary}.dart
mobile/lib/features/downloads/providers/download_switches_provider.dart
mobile/lib/features/downloads/services/chapter_export.dart          (Android MediaStore destination)
mobile/lib/features/downloads/services/device_storage_info.dart     (totalSpaceBytes)
mobile/lib/core/platform/media_store.dart
mobile/android/app/src/main/kotlin/com/manhwamaniacs/reader/{MediaChannel.kt,MainActivity.kt}
mobile/ios/Runner/AppDelegate.swift                                 (getTotalDiskSpace)
mobile/lib/features/settings/utils/whats_new_policy.dart            (moved, no pixels)
mobile/lib/features/settings/services/metadata_cache.dart           (moved, no pixels, if needed)
mobile/lib/features/admin/utils/status_summary.dart
mobile/lib/features/admin/providers/status_providers.dart
mobile/lib/features/downloads/providers/downloads_lifecycle.dart    (moved, no pixels, only if skin_app.dart lacks the gate)
mobile/lib/app/skin_app.dart                                        (mounts the lifecycle once, only if needed)
mobile/lib/skins/cinematic/screens/downloads/
  downloads_screen.dart  storage_meter.dart  activity_block.dart  queue_rows.dart  narration_block.dart
  saved_library.dart  series_block.dart  chapter_row.dart  storage_panel.dart  save_to_files_sheet.dart
  downloads_empty.dart  downloads_keys.dart
mobile/lib/skins/cinematic/screens/index/
  index_screen.dart  profile_block.dart  index_section.dart  index_row.dart  update_banner.dart
  install_now_dialog.dart  app_update_card.dart  sidestore_card.dart
mobile/lib/skins/cinematic/screens/admin/
  status_screen.dart  summary_banner.dart  backend_card.dart  checker_card.dart  recent_checks.dart
  source_health_list.dart  status_keys.dart
mobile/lib/skins/cinematic/overlays/whats_new_sheet.dart
mobile/lib/skins/cinematic/shell.dart                               (What's new auto-open, AutoDownloadRunner toast, flushAll on pause)
mobile/lib/skins/cinematic/router.dart                              (wire the three screens, remove them from PENDING)
mobile/test/features/downloads/{pending_removals,auto_download,storage_meter,queue_summary,download_switches}_test.dart
mobile/test/features/settings/whats_new_policy_test.dart
mobile/test/features/admin/status_summary_test.dart
mobile/test/core/platform/media_store_test.dart
mobile/test/skins/cinematic/downloads/{downloads_screen,resume_after_restart,lifecycle,mature_hidden}_test.dart
mobile/test/skins/cinematic/index/index_screen_test.dart
mobile/test/skins/cinematic/admin/status_screen_test.dart
mobile/test/skins/cinematic/overlays/whats_new_sheet_test.dart
mobile/test/screenshots/cinematic/mobile_17_downloads_index_status_shots_test.dart
docs/redesign/proof/mobile-17/                                      (plan.md, screenshots, device-checklist.md, report.md)
```

## Commit plan (small commits, push after each)

1. `refactor(mobile/17): move whats-new policy, metadata cache and the downloads lifecycle out of widgets` (no pixel change; legacy tests stay green; the lifecycle part only if A11 needs it).
2. `feat(mobile/17): pending removals, download switches, auto-download planner` (A1–A3).
3. `feat(mobile/17): storage meter model, queue summary and status summary` (A4, A5, A8).
4. `feat(mobile/17): media store export and device total space` (A9, A10: the one native commit; then check CI once).
5. `feat(mobile/17): cinematic downloads, the offline edition`.
6. `feat(mobile/17): cinematic index and the update banner`.
7. `feat(mobile/17): what's new sheet and the update cards`.
8. `feat(mobile/17): cinematic system status`.
9. `test(mobile/17): resume-after-restart, 18+ and harness proof screenshots`.

`git add` exact paths; commit messages carry **no** `Co-Authored-By`, no "Generated with" line and no AI attribution; `git push origin feat/vps-slim-source-native` after each. Never commit secrets, `key.properties`, `.env*` or `.claude/`.

Before every push: `git fetch origin` and `git diff --stat origin/feat/vps-slim-source-native...HEAD -- frontend`. The checkout is shared, so a push also carries other sessions' commits: if that diff lists files, run `free -m && npm run build` in `frontend/` first (never while a Flutter command runs, stop if `available` < 1024 MB) and push only if it passes, because a failed `next build` silently freezes the production deploy. Never deploy from this step.

## Acceptance criteria

- [ ] `downloads`, `index` and `status` are gone from the Cinematic `PENDING` set; the completeness and import-boundary tests pass.
- [ ] Downloads shows the meter line and segmented bar with the cap tick, Activity with every pause reason, `Pause all` / `Resume all`, `Cancel all` with the armed dialog, `Show queue` with per-row `Retry` and `Remove from queue`, the foreground note, the scan and narration blocks, the saved library by series (largest first) with pins, Save to Files and expandable chapter rows, every status caption, and the STORAGE tab with every control, both new switches, `BY SERIES`, `Free up space`, both cache cards and the platform note.
- [ ] Removing a chapter shows `REMOVING…` and an 8 s Undo toast; Undo keeps it; expiry deletes it; backgrounding the app flushes pending removals (unit test with the injected timer, plus a widget test).
- [ ] Save to Files writes to `Download/ManhwaManiacs/Exports/{series}/` on Android 10+ through `mm/media`, offers `Share` on Android 7–9, and shows the Files path on iOS with `Open Files`; CI's APK build and iOS dry run are green for the native commit.
- [ ] With the gate closed, a mature series saved earlier appears in no list, count, badge (the thumb-index Downloads badge included) or caption; the meter still includes its bytes; its queued downloads pause silently; reopening the gate brings everything back at once (widget test).
- [ ] After `AppRestart.of(context).restart()` a chapter left in `downloading` state is re-queued and resumes (widget test).
- [ ] Under the Cinematic skin, backgrounding pauses the queue with the `backgrounded` reason, returning resumes it and runs the retention sweep, and the outboxes flush on resume (widget test, A11).
- [ ] The auto-download planner and runner follow A3 (unread only, notify on, not saved, Wi-Fi only, cap, 1.5 GB floor, max 20) and toast the count.
- [ ] The Index shows the profile block, the content-mode toggle, the four sections with their values, the Android update banner and Install now steps only on the APK channel, two columns with a column rule from 900 dp, and the leader draw once per app session; admin rows are absent for non-admins; Dialogue search is absent when OCR is unavailable.
- [ ] What's new opens from the Index as a 0.92 sheet, lists every changelog entry with its folio and `LATEST` badge, opens automatically once after a new build (never over a reader or takeover), and shows its loading and unavailable states.
- [ ] System status shows the typed summary headline tinted by the worst state, backend and checker credits, recent checks, worst-first source health with collapsible errors (a table on tablets inside its own horizontal scroll), the live `LIVE · 15 S` folio, per-card loading and error states and the non-admin notice; the hardware keys work.
- [ ] Reduced motion per section F (widget tests with `disableAnimations: true`: the Index leaders are at rest, the Status headline is complete at once, the meter width changes with no animation).
- [ ] Hardware keyboard: every control is reachable in reading order with `CineFocusRing`; the listed keys work; route focus lands on each level-1 heading.
- [ ] Hit targets: `meetsGuideline(iOSTapTargetGuideline)` (iOS) and `meetsGuideline(androidTapTargetGuideline)` (Android) and `labeledTapTargetGuideline` pass on the three screens and the What's new sheet.
- [ ] Contrast: `ink.45` only on `paper.0`; on `paper.1` cards and error blocks, sheets, dialogs, the mood grade and banner strips those roles render `ink.60`; `meetsGuideline(textContrastGuideline)` passes.
- [ ] Per-skin difference: only `lib/skins/cinematic/**`, skin-neutral `lib/features/**`, `lib/core/**`, `lib/shared/**` and the two native files changed; the Glass skin still maps these ScreenIds to its pending screen; the legacy Downloads, More and Storage screens still work and their tests pass.
- [ ] `flutter analyze` reports no issues and `flutter test` passes: every test that passed at `00-baseline.md` (2012) and every test added since still passes.

## Verification

From `/srv/manhwamaniacs/dev/ManhwaManiacs`, one at a time, `free -m` first (stop if `available` < 1024 MB), `pgrep -f "next build"` empty:

```bash
free -m
node design/build.mjs --check
cd mobile
/srv/manhwamaniacs/dev/flutter/bin/flutter pub get
/srv/manhwamaniacs/dev/flutter/bin/flutter analyze        # baseline: "No issues found!"
free -m
/srv/manhwamaniacs/dev/flutter/bin/flutter test           # baseline: all 2012 passed; now baseline + every added test, 0 failed
```

After the native commit is pushed, check CI once: `gh run list --branch feat/vps-slim-source-native --workflow tests.yml --limit 3` (the APK build job and the iOS dry run must pass; do not poll in a loop, check again only after your next push).

`frontend/` and `backend/` are untouched here; `git diff --stat origin/feat/vps-slim-source-native -- frontend backend` must be empty, so the web checks (`npm run lint`, `npm run build`) and the backend pytest (`cd backend && .venv/bin/python -m pytest -q --no-header`) are not run in this step.

**Proof output location.** The `mobile/03` harness (`mobile/test/screenshots/support/skin_shots.dart`) writes a capture only when `MM_PROOF_DIR` is set, so every proof command below sets `MM_PROOF_DIR=../docs/redesign/proof/mobile-17` (relative to `mobile/`) and never `MM_WRITE_SHOTS`, which makes the legacy marketing tests overwrite `mobile/docs/screenshots/`, the install page's public screenshots. Capture routes with `captureSkinScreen` and anything that is not a route (a sheet held open, a state pumped with fixture providers) with `captureSkinWidget`, at the harness sizes: `kSkinShotSizes` (phone 390 × 844, tablet 834 × 1194), `kSkinShotTabletWide` (1024 × 1366, the ≥ 900 px rows of §8.0.9) and `kSkinShotLandscape` (landscape phone 844 × 390). After the run, `git status --short mobile/docs/screenshots` must print nothing.

**Visual proof.** Write `mobile/test/screenshots/cinematic/mobile_17_downloads_index_status_shots_test.dart` on the `mobile/03` harness with the in-repo fixtures (a fake downloads store with three invented series, one of them flagged mature to prove its absence, fake queue states, a fake changelog and app version). Capture at phone 390 × 844 and tablet 834 × 1194 logical px (the harness's sizes if `mobile/03` defined others): Downloads SAVED (idle, downloading with the queue shown, each pause reason, a pending removal with its Undo toast, a series expanded), STORAGE, the Save to Files sheet and the result dialog (iOS and Android variants), empty, checking, offline, no profile, error; the Index (member and admin, the Android update banner, the Install now dialog, offline); What's new (entries, loading, unavailable); System status (healthy, two problems, a card in error, non-admin); plus a `-reduced` copy of each screen's default state, into `docs/redesign/proof/mobile-17/{screen}-{state}-{phone|tablet}.png`:

```bash
free -m
cd mobile
MM_PROOF_DIR=../docs/redesign/proof/mobile-17 /srv/manhwamaniacs/dev/flutter/bin/flutter test test/screenshots/cinematic/mobile_17_downloads_index_status_shots_test.dart
```

**Device checks** for the owner, as a checklist in `docs/redesign/proof/mobile-17/device-checklist.md` (iPhone via SideStore from the CI IPA, Android flagship from the CI APK): a real 10-chapter queue with pause, resume, background and return; the meter growing as a chapter lands; swipe-to-remove with Undo; Save to Files as CBZ into Files (iPhone) and into Download/ManhwaManiacs/Exports (Android), opened in another app; `Open Files` on the iPhone; the What's new sheet after installing a newer build; the APK banner and Install now on Android; System status as admin.

## Report back

Reply with:
1. The acceptance checklist, each box ticked or explained.
2. Commits (short SHA and message), confirmed pushed; call out the native commit and its CI result separately.
3. `docs/redesign/proof/mobile-17/` with the file count and the states captured per screen.
4. Test counts: `flutter test` passed / failed / total vs the baseline total 2012, `flutter analyze` result.
5. The lowest `free -m` available value seen.
6. Open issues: providers an earlier step did not deliver, device values the platform could not report, deviations with reasons.

Next prompt: `docs/redesign/prompts/mobile/18-cinematic-settings-and-edition-restart.md`
