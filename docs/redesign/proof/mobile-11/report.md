# mobile-11 report (lane L25, fix pass 1)

Cinematic series pages for the Flutter app: the manga Feature page, the novel Book page and chapter downloads, one `FeatureView` for `/sources/:sourceId/series/:seriesKey` and `/library/:followedId`.

## 1. Done

- **A** `mature_override: null` on the server: not applied. `web/11` (owner) has not landed (`git log --grep='^web-11:.*proof'` is empty) and `followed_series_service.py` still ignores an explicit null. The client sends `"mature_override": null` (`clearMatureOverride`) and is tested; the backend test and fix are left to `web/11` (open issue).
- **B1-B13** data layer: enrichment, suggested tags, repoint + `mappingSentence`, `timeHere`, `chaptersUpTo` / `undoMarkReadKeys` / `manualReadRows`, download mark state / label / tooltip, `describeRun`, `seriesDownloadSummaryProvider` (now read by the legacy `series_download_progress.dart` too, no pixels moved), chapter sort store, `clearMatureOverride`, contents window, `isNovelSource`. `chapter_selection_actions.dart` already calls the model helpers in `models/chapter_selection.dart`; nothing left to move. Added here: `ProgressPush.manual`, `ProgressDeleter.deleteProgress` (chunks of 200), `TagsController` (+ optimistic overlay), `seriesShelvesProvider`, `deviceOnlineProvider`, `SourceProgressNotifier.forget / restoreRecords`, `SourceSeriesSummary.cacheStale`, `FollowedSeries.tags`.
- **C1-C3** routes on match-cut pages (iOS `SwipeablePage`, edge only 20 pt, 480 / 336 ms, Hero with `transitionOnUserGestures`; Android `CineMatchCutPage` + `fadeThrough`), title `SetHeading` (signal trigger, step-down for long titles), 800 ms ambient wash, rating card (3000 ms), Lightbox, running head, Column wipe through `enterReader`, `ReaderPrefetch` on press and dwell, haptics and sounds.
- **D1-D11** phone hero, tablet spread, follow / favourite / notify (with Undo and the limit line), tabs as a data list (`FeatureTab`, `extraTabs`), schedule rows (56 px, issue-colour numbers, READING badge, `CineDownloadMark`), Mark read / up to here / unread with Undo, Bookmark start, At a glance (Stat block, status slug line, time, own tags with `x`, Add tag sheet with `New tag…`, SUGGESTED dashed tokens with accept / reject, shelves, OCR rule), DETAILS (drop cap, genres, enrichment), overflow, repoint, hardware keys, every state (galley, offline, unavailable, none, error, offline edition, saved copy, not available).
- **E1-E7** Book: typographic front matter, 56 px rule, plate 96 x 144 / 168 x 248, collapsed blurb with More, actions (split primary, Listen or its caption, Library, Download book), contents as slivers with the 400-row window, N2 contents sheet, contents rows with dot leaders, keys, states.
- **F1-F9** select mode (tap, range long-press), selection bar with counted quick picks, run line with Stop and the summary (free-space figure for `Out of room`), series download card, no-profile state uses the existing disabled Download, seven download marks, haptics `download.start / done / fail`.

## 2. Screenshots

`docs/redesign/proof/mobile-11/`, from `test/screenshots/marketing_screenshots_test.dart --plain-name mobile-11` (group in `mobile_11_shots.dart`, invented fixtures in `test/fixtures/series/`). Names follow the prompt's list; each acceptance item maps as: hero / spread `feature-*`, tabs and rows `feature-*`, motion `feature-match-cut-mid-phone`, At a glance `feature-at-a-glance-phone`, DETAILS `feature-details-*`, overflow and override `feature-overflow-phone` `feature-mature-override-phone`, rating card `feature-rating-card-phone`, Lightbox `feature-lightbox-*`, repoint `feature-repoint-*`, downloads `feature-select-*` `feature-downloading-phone` `feature-download-card-phone` `feature-download-summary-*`, states `feature-{loading,chapters-offline,chapters-unavailable,no-chapters,error,offline-saved,notavailable}-*`, Book `book-*`, marks `download-marks-gallery`, `feature-text-2.0-phone`, `feature-reduced-motion-phone`. `web-11` proof does not exist yet, so no phone comparison was made.

## 3. Tests

Whole suite after the fix pass and the merge of the integration branch: 2317 passed, 1 failed (`test/features/settings/mature_invalidators_test.dart`, the audited backend service list; it fails on the integration branch too, a backend lane added a service, not touched here). `flutter analyze` (lib and test): No issues found. `node design/build.mjs --check`: passes (warnings pre-existing). Screenshot group: 12 tests, 45 PNGs. Floor before the fix pass: 2133 passed (`flutter-test-before.txt`). New suites under `test/skins/cinematic/feature/` (screen, view, chapters panel, details, book page, selection bar and marks, repoint, lightbox, shortcuts, accessibility, states, feedback, motion rows, drop cap) and `test/features/library/mark_read_wire_test.dart`.

## 4. Motion

`feature_motion.dart` lists the rows (match cut in 480 / out 336, dissolve 800, letter set, rule draw 480, Column wipe 616 phone / 744 tablet, Drift 26 s, Lightbox 480); `motion_rows_test.dart` pins them and the wipe timings. The shared `MotionRecorder` is not integrated; rows are fed when it is.

## 5. Shared API

`seriesEnrichmentProvider`, `suggestedTagsProvider`, `ocrCoverageProvider` (existing), `LibraryRepository.repoint`, `mappingSentence`, `timeHere`, `chaptersUpTo`, `undoMarkReadKeys`, `manualReadRows`, `downloadMarkState / Label / Tooltip`, `describeRun`, `seriesDownloadSummaryProvider`, `clearMatureOverride`, `chapterSortFor / saveChapterSort`, `FeatureTab`, `FeatureCommands`, `TagsController`, `ProgressDeleter`, `deviceOnlineProvider`, `CineDownloadMark`, `CineFocusRing`, `SetHeading`, `CineAmbient`, `CineMatchCutPage`, `ReaderPrefetch`, `enterReader`, `DashedToken`, `CineSegmented`, `DropCapParagraph`.

## 6. Open issues and choices

- Restart pass: mobile/04-10 are integrated; the local `CineFocusRing`, `CineSegmented` and `CineAmbient` stand-ins are deleted for the shared `focus_ring.dart`, `CineSegmentedControl` and `ambient_scope.dart` (`SeriesAmbient` mounts on the fallback and takes the series colours one frame later for the 800 ms wash). `CineDownloadMark` here stays: it takes the model's `DownloadMarkState` and tooltip, the shared one has another state set. Whole suite 4814 passed, 0 failed. Predictive back paints only the fade-through function, not the platform gesture.
- Series payload carries no `ambient`, source URL or health: the ambient colours derive from a hash of the series key, `Open the source's page` and the 6 px health mark are absent.
- Long-press outside select mode opens the row menu (DESIGN §11 wins over §8.19); in select mode it selects the range.
- Counts on labels are plain figures (` 201`): the bundled Archivo has no superscript zero.
- `Share link` uses `share_plus`; the re-stamp after an override change is `TODO(mobile/07)` (only the follow list is invalidated).
- Grain on hero art is not drawn.
- Section A backend fix pending `web/11`.

## 7. Commits

`git log --oneline 6df9273..HEAD --grep '^mobile-11'` on `redesign/L25`.
