# Mobile 10: Cinematic Updates, Collections, History and Bookmarks

Track: mobile · Order 36 · Depends on: `docs/redesign/prompts/mobile/09-cinematic-library-shelf-browse.md` · Web twin: `docs/redesign/prompts/web/10-cinematic-updates-collections-history-bookmarks.md` · Proof folder: `docs/redesign/proof/mobile-10/`

## Goal

Build the other four Library hub tabs of the Cinematic skin in the Flutter app (iOS and Android, phones and tablets), per `docs/redesign/cinematic/DESIGN.md` §8.10–§8.13, inside the `LibraryHub` frame `mobile/09` built: **Updates** (`/updates`, "Stop press": the check with live progress, NEW grouped by day and series with typed chapter folios, the FOLLOWING tab, mark all read, the admin "Recent checks" aside on wide tablets; mobile S23 and the stop-press banner's landing, G39), **Collections** and **collection detail** (`/library/collections`, `/library/collections/:id`; mobile S24, S25: duotone plates from `preview_covers`, smart shelves whose rules are evaluated on the device, custom order and member reorder, and the match cut of the plate into the header, which the iOS edge swipe reverses with the finger through `Hero.transitionOnUserGestures`), **History** (`/library/history`, "The log" with its time margin; mobile S13) and **Bookmarks** (`/library/bookmarks`, "Marked passages" for manga and novels, offline-first through the bookmark outbox; mobile S14), each with every state. Then run the **re-estimate gate** of `docs/redesign/stack-decision.md` §1 for the Flutter half and write `docs/redesign/proof/mobile-10/estimate.md`. When you finish, `updates`, `collections`, `collection`, `history` and `bookmarks` leave the Cinematic `PENDING` set. The web session runs `docs/redesign/prompts/web/10-cinematic-updates-collections-history-bookmarks.md` in parallel; do not touch `frontend/`.

## Read first

Read these completely before writing the plan. `docs/redesign/cinematic/DESIGN.md` is binding; where this file and DESIGN.md disagree, DESIGN.md wins and you say so in the report.

1. `docs/redesign/inventory/00-decisions.md` (all of it).
2. `docs/redesign/stack-decision.md` §1 (the re-estimate condition), §2.3, §2.6; `docs/redesign/stack-keep.md` §6 (the effort table the gate measures against).
3. `docs/redesign/cinematic/DESIGN.md`:
   - §2.1.1, §2.1.4 (`scrim.foot`), §2.1.5 (the duotone matrix; `CineAmbient`), §2.2, §2.8, §3.3, §3.5.
   - §4 (Cut, Set, Page, the match cut and its 336 ms reverse, Dip, Rule slide, stagger, interruptibility, reduced motion §4.8), §5 and §6 (events used here).
   - §7 intro and the semantics table, §7.1, §7.2, §7.3 (fields; the ruled textarea), §7.4 `compact`, §7.5, §7.6 (Collection plate, Stat block), §7.7, §7.9 (`CineSheetRoute`), §7.10 (the arm delay; dialogs), §7.11, §7.12 (contents tabs; nested tabs switch by tap only), §7.16 (rows: standard, swipe slabs with `Dismissible`, drag to reorder), §7.17, §7.18, §7.19, §7.21, §7.22 (menus and Move items), §7.23, §7.24, §7.27, §7.29 (pull to reprint, banner strips, spoken folios).
   - §8.0.2–§8.0.5 (the hub routes in branch 1, `/library/collections/:id` pushed inside it with a back arrow, "Route transitions in the app", the Dip into readers, back inside modal states), §8.0.8, §8.0.9 (tablet rows for Updates, Collections, History, Bookmarks), §8.0.10.
   - **§8.10, §8.11, §8.12 and §8.13, entire.**
   - §8.33.3 (the stop-press banner goes to Updates), §9.3.5 (only to know what is deferred to `mobile/22`), §10.1 and §10.1.6, §10.2 and §10.2.4 (typed notice headlines and Updates folios), §11 (rows for these screens and the precedence rules), §14, §15.3, §15.6, §15.7.
4. `docs/redesign/glass/DESIGN.md` §15.6 row "Collection order and creation date" and §8.18 "Auto (smart) collections" (one evaluator in `mobile/lib/features/library/` for both skins).
5. `docs/redesign/inventory/mobile.md` S13 (8 items), S14 (8 items), S23 (13 items and the "Not surfaced" paragraph), S24 (12 items), S25 (13 items), G13 M8 and M9; `docs/redesign/inventory/web.md` row G39 (the new-chapters banner).
6. `docs/redesign/inventory/capabilities.md` §11 (collections), §14 (history), §15 (bookmarks), §21 (updates).
7. `docs/redesign/00-baseline.md`.
8. The web twin, and when present `docs/redesign/proof/web-10/report.md` and `docs/redesign/proof/web-10/estimate.md`.
9. `docs/redesign/proof/mobile-09/report.md` (the shared names: `LibraryHub`, `HubSlideSliver`, `HubShellScope`, `runBulk`, `changedSortOrders`, `library_poster.dart`, `book_list_row.dart`).
10. Code you build on: `mobile/lib/features/updates/` (`updates_provider.dart`: `UpdatesNotifier.refresh`, `markRead`, `markAllRead`, `triggerCheck`, `unfollow`, `updateCheckPollDelaysProvider`; `repositories/updates_repository.dart`: `getSettings`, `listNotifications`, `getUnreadCount`, `listRuns`, `triggerCheck`, `checkFollowed`; `models/`), `mobile/lib/features/collections/` (`providers/{collections_provider,collection_detail_provider,collection_sort_provider}.dart`, `utils/collection_sorting.dart`), `mobile/lib/features/library/repositories/library_repository.dart` (the collection calls, `readingHistory({limit, offset, bySeries})`), `mobile/lib/features/library/models/{collection,collection_detail,reading_history_item}.dart`, `mobile/lib/features/library/providers/{intelligence_providers,bookmarks_provider}.dart`, `mobile/lib/features/library/screens/reading_history_screen.dart` (its private `_continue` resolution, to move), `mobile/lib/features/library/utils/resume_location.dart` (`seriesContinue`, `nextChapterInReadingOrder`), `mobile/lib/features/downloads/providers/bookmark_outbox_provider.dart`, `mobile/lib/features/downloads/store/bookmarks_dao.dart`, `mobile/lib/features/reader/models/bookmark.dart`, `mobile/lib/skins/cinematic/{router,shell,transitions}.dart`, `mobile/lib/skins/cinematic/screens/library/`, `mobile/lib/skins/cinematic/primitives/`, `mobile/lib/skins/cinematic/parts/`.

## Preconditions (check before writing the plan)

1. Work in `/srv/manhwamaniacs/dev/ManhwaManiacs` on branch `feat/vps-slim-source-native`; `git status --porcelain`, and note other sessions' modified files (never stage them).
2. Dependencies landed:
   - `ls mobile/lib/skins/cinematic/screens/library/library_hub.dart mobile/lib/skins/cinematic/parts/library_poster.dart mobile/lib/features/library/utils/bulk_runner.dart` exist and `library` is out of the Cinematic `PENDING` set (mobile/09).
   - `grep -n "series/order" backend/routes/library.py` finds `PUT /library/collections/{id}/series/order` and `grep -n "created_at\|preview_covers\|rules" backend/services/followed_series_service.py` finds `created_at`, `preview_covers` and `rules` on collections (backend/02).
   If a check fails, stop and report it. This step changes no backend file.
3. Inventory and reuse: `ls mobile/lib/skins/cinematic/primitives mobile/lib/skins/cinematic/parts mobile/lib/skins/cinematic/screens/library`. If a primitive lacks a variant, add it to the primitive file and the Diagnostics primitives gallery.
4. Record your floor after the RAM guard: from `mobile/`, `free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter test 2>&1 | tail -3`, written to `docs/redesign/proof/mobile-10/flutter-test-before.txt`.

## Skills to invoke

1. `superpowers:writing-plans` before any code; save as `docs/redesign/proof/mobile-10/plan.md`.
2. `superpowers:test-driven-development` for every section A helper and provider.
3. `superpowers:subagent-driven-development` (or `superpowers:executing-plans`). At most 6 implementer subagents, scope-locked to named files; one `flutter test` or `flutter analyze` at a time; verify with `git status` and `git diff`, never with an agent's report.
4. `impeccable:impeccable` and `taste-skill:taste-skill` for design review against DESIGN.md (never changing its fixed values or copy); `frontend-design:frontend-design` only for the side-by-side review with the web twin's phone screenshots.
5. `superpowers:verification-before-completion` before claiming done.

## Scope: deliver every item below

Cinematic only (Glass's versions are `mobile/32`). Section numbers refer to `docs/redesign/cinematic/DESIGN.md`. Every hub screen renders inside `LibraryHub` with its own masthead; collection detail is a pushed page inside branch 1 (back arrow in the running head, thumb index visible, no hub tab row). Values go through `CineTokens`, `CineCurves`, `CineSprings` and `CineType`.

### A. Shared data layer additions (skin-neutral, `mobile/lib/features/`)

No widget code, no import from `lib/skins/**`, a test for each logic file, written first.

1. **Collections model and calls.** `Collection` gains `rules` (`ShelfRules?`), `smart` (`rules != null`), `previewCovers` (≤ 4 cover URLs), `previewAmbientDuo` (`Color?`) and `createdAt` (`DateTime?`), parsed tolerantly; `createCollection` and `updateCollection` accept `rules` (with an explicit `clearRules` flag that sends `"rules": null`); add `Future<Result<void>> reorderCollectionMembers(int collectionId, List<({String sourceId, String seriesKey})> items)` → `PUT /library/collections/{id}/series/order {items: [{source_id, series_key}]}` (204; the list must equal the visible membership exactly, else `422 order_mismatch`, backend/02). Test the parsing and the request body.
2. **`library/utils/smart_shelf.dart`**, the one smart-shelf evaluator both skins use (glass §8.18): `ShelfRules {all: List<ShelfRule>}`, `ShelfRule {field: reading_status | is_favorite | new_count | format | content_kind, op: eq | gte | in | ne, value}` with `fromJson`/`toJson`; `List<FollowedSeries> evaluateShelf(ShelfRules rules, List<FollowedSeries> rows)` (`new_count` from the row's read state, `format` and `content_kind` from the row), AND across rules, keeping the library order; `String describeRules(ShelfRules rules)` → the credit text (`READING · 3+ NEW · FAVOURITES · MANHWA, MANGA · UNFINISHED NOVELS`); `const unfinishedNovels = [ShelfRule(field: 'content_kind', op: 'eq', value: 'novel'), ShelfRule(field: 'reading_status', op: 'ne', value: 'completed')]`. Test: each operator, AND, empty rules, the unfinished-novels pair, unknown fields ignored.
3. **`collections/providers/collection_order.dart`**: `reorderCollections(ref, before, after)` (`updateCollection(id, sortOrder:)` for the changed collections only, through `runBulk` with concurrency 4, optimistic with rollback) and `reorderMembers(ref, collectionId, orderedItems)` (optimistic with rollback on failure; the caller shows the toast). Extend `collection_sorting.dart` and `collectionSortProvider` with `recentlyCreated` (by `createdAt`, newest first; by `id` descending when absent), persisted per profile under `profileScopedKey(prefix: 'mm.collections.sort.')`. Test the rollback and the sort.
4. **`library/providers/history_pages_provider.dart`**: `historyPagesProvider(bool bySeries)` (`AsyncNotifierProvider.autoDispose.family`) over `readingHistory(limit: 50, offset:, bySeries:)` with `loadEarlier()` appending the next 50 while a page returned 50 rows; `int? nextHistoryOffset(List<List<ReadingHistoryItem>> pages)` pure and tested. Add it to `profileScopedInvalidators` and the gate invalidation list.
5. **`library/utils/history_continue.dart`**: move the next-chapter resolution out of `reading_history_screen.dart`'s private `_continue` (fetch the chapter list, `seriesContinue()` / `nextChapterInReadingOrder()`, fall back to the series page when there is no next chapter) into `Future<HistoryContinue> resolveHistoryContinue(Ref ref, ReadingHistoryItem item)` returning `({ReaderTarget? target, bool toSeriesPage})`, in its own commit that changes no pixels; the legacy screen calls the moved function and its tests stay green. Test the resume, next and fallback branches.
6. **`updates/utils/notification_grouping.dart`**: `List<UpdateDay> groupNotifications(List<UpdateNotification> items, DateTime now, {String? sourceId})` → days (`TODAY`, `YESTERDAY`, else `MONDAY 28 SEPTEMBER` with English day and month names, uppercase) → series groups `{sourceId, seriesKey, title, coverUrl, ambient, chapters: [{notificationId, chapterKey, chapterNumber, read}], newestAt}`, chapters in ascending chapter number, groups newest first; `firstUnread(group)`. Test included.
7. **Updates extras**: add to `UpdatesRepository` `Future<Result<UpdateRun>> getRun(int runId)` (`GET /updates/runs/{id}`) and `Future<Result<List<String>>> listUpdateSources()` (`GET /updates/sources`) if missing; `updateSettingsProvider` (`FutureProvider.autoDispose` over `getSettings()`) if missing; a session-lifetime `seenUpdateIdsProvider` (`StateProvider<Set<int>>`, not persisted) for the typed-folio moment.
8. **Bookmark notes**: make sure the bookmark outbox can upsert a note: if `BookmarkOp` carries no `note`, add it (the one-item upsert through `POST /reader/bookmarks/batch` with the bookmark's position fields and `note`), map a `409 bookmark_deleted` answer to a typed `BookmarkDeletedElsewhere` error, and add `restoreBookmark(bookmark)` (the same upsert with every field) for the Undo after a remove. Test the op payloads and the 409 mapping.

### B. Updates: `mobile/lib/skins/cinematic/screens/updates/updates_screen.dart` (ScreenId `updates`)

Hub tab `02 UPDATES`. Hierarchy: masthead → the check → new chapters by series → the following list (tab).

1. Masthead: kicker `No. 03 — STOP PRESS`, title "Updates", deck "14 new chapters across 6 series · last checked 12 min ago · checking every 30 min" (from the notifications and `updateSettingsProvider`; drop unknown parts). The deck is a button (`Semantics(button: true)`): for admins it goes to Settings → Notifications (`go('/settings/notifications')`; Settings is pending until `mobile/18`); for everyone else it opens a `CineSheetRoute` (kicker `SCHEDULE`, title "When chapters are checked", lines "Checking every 30 minutes.", "Last check: 21:04." and, when the profile's `notify_enabled` is off, "New-chapter notices are off for this profile.", `Done`).
2. Actions under the masthead: primary `Check now` (`UpdatesNotifier.triggerCheck()`; loading: the label keeps its box and a 2 px `spot` segment 25 % wide runs along the inside bottom edge on a 1200 ms `durLoopRule` linear loop; after 400 ms the label reads "Checking 212 series…"; for admins the run is polled with `getRun(id)` every 2000 ms and the deck updates live "Checked 180 of 212 · 3 new"; for others the unread count is re-polled at 3, 5 and 7 s (`updateCheckPollDelaysProvider`); haptic `tap.primary` on press and `success` when the check finds chapters; `409 check_already_running` → a caption "A check is already running." under the button); secondary `Mark all read` (`markAllRead(mode:)`, labelled `Mark all manga read` / `Mark all novels read` by content mode when novels are enabled; disabled with nothing unread; toast "Marked every new chapter as seen."). Phones: both full width, stacked; tablets: one row.
3. Nested contents tabs (§7.12, **tap only**, §11: `TabBarView` physics `NeverScrollableScrollPhysics()`, the hub owns every horizontal drag): `NEW ¹⁴ · FOLLOWING ²¹²`, with a `SOURCE ▾` compact select at the row's right end (`All sources` plus `listUpdateSources()`, filtering both tabs client-side; a sheet on phones, a menu on tablets; hidden when only one source has follows).
4. **NEW**: `groupNotifications()` rendered as date rules (`type.kicker` over a `rule.hair`) then series groups: a 48 × 72 cover (`Hero` tagged `(sourceId, seriesKey)`, match cut to the feature page), the series title (`type.title`), a `NEW` count badge (fill `spot`, `#000`), the new chapter folios as a slug line `CH 141 · CH 142 · CH 143` (each folio a button with a 44 pt / 48 dp hit box, into the reader by **Dip** through the reader-entry helper with `entry: dip`), the source credit and time (`type.caption`), and the row actions `Read from 141` (`split` sm, Dip into the reader at the group's first unread chapter) and `Mark read` (`quiet`; marks the group's notifications read through `markRead`, concurrency 4). Fully read groups fade to `ink.45` text (160 ms) and stay listed. Swipe a group left to `Mark read` (§7.16: `Dismissible(direction: DismissDirection.endToStart, dismissThresholds: {DismissDirection.endToStart: 0.5})` with a 72 px flat slab filled `ink.100` and a `#000` label as its `background`, `confirmDismiss: (_) async { markRead(); return false; }` so the row springs back and dims; haptic `select`); long-press opens the row menu `Read from 141`, `Mark read`, `Open series` (haptic `longpress.open`); a trailing `dots-three` is the non-gesture path.
5. **Signature moment**: the new chapter folios of a fresh notification type themselves (50 ms per character, `TypedHeadline` as a non-heading, caret per §10.2.1) the first time they appear after a check: ids not yet in `seenUpdateIdsProvider` are typed, then added once typing ends.
6. **FOLLOWING**: the followed series (filtered by content mode and the source select) as §7.16 standard rows: 48 × 72 cover, title, source name, "Checked 12 min ago" / "Not checked yet" (from `last_checked_at`), a Notify bell toggle (`bare` icon button, `Semantics(button: true, toggled:)`, selected: Fill glyph + 2 px `spot` rule under the square; `patchSeries(notify:)`), and a trailing `dots-three` menu with `Check this series` (`checkFollowed(id)`, toast "Checking {title}.") and `Unfollow` (`proof` item; commits at once through `LibrarySeriesActions.remove` with the toast "Removed {title}." + `Undo`, 8000 ms, restoring status, favourite, notify, override and position).
7. **Aside** (tablets ≥ 900 px wide, admins only): "Recent checks" as a `Credits` list (label → dot leaders → value; `trigger · status · series · new · started`) from `listRuns()`; 3 greeked rows while loading; "No check runs yet." when empty. From 900 px the NEW and FOLLOWING lists take columns 1–5 for everyone (the row measure never depends on the role) and columns 6–8 hold the aside for admins, empty otherwise (§8.0.9). Below 900 px: one column; the aside is not shown (it lives in Settings → Notifications, `mobile/18`).
8. The reserved push prompt of §8.10 is not built (no push support exists).
9. Pull to reprint reloads the list and never starts a server check (`Check now` does).
10. **States**: loading (3 greeked groups); NEW empty (kicker `NOTHING NEW`, typed headline "No new chapters yet.", deck "Follow a series and this fills in the moment a chapter lands.", primary `Find something` → Discover); FOLLOWING empty (kicker `NOTHING FOLLOWED YET`, headline "Nothing followed yet.", primary `Find something`); notices off for the profile (`notify_enabled` false: a `NOTE` kicker line in `spot` "New-chapter notices are off for this profile." with `Turn on` → `PATCH /profiles/{id} {notify_enabled: true}`); a check already running (the 409 caption); offline (kicker `OFFLINE EDITION`, headline "Updates need a connection to check.", the last loaded list shown read-only below it, every action disabled with the tooltip "Needs a connection."); error (kicker `CORRECTION`, headline "Updates didn't load.", deck "The server didn't answer.", primary `Try again`); rate limited (kicker `SLOW DOWN`, a live "Retrying in 12 s" folio from `Retry-After`). 18+: notifications of hidden series are absent (the server filters) and counts never imply them.
11. **Hardware keys** (group "Updates"): `R` reload the list; `C` `Check now`; `J`/`K` move between series groups; `Enter` reads the focused group; `M` marks it read; `Shift+M` marks all read.
12. **Transitions and the banner**: in by the hub tab Cut; the stop-press banner (`mobile/06`, §8.33.3) is hidden while Updates is on screen, and its `Read updates` is `go(Routes.updates)` into branch 1 (from another branch: Cut + Set + Folio flip with the notch moving to Library; from inside branch 1: the hub tab Cut; from the novel reader: the Dip out of a reader); verify both and fix them in `shell.dart` if they differ. Out: Dip into the reader; match cut from covers to the feature page.

Inventory coverage: S23 1 (app bar, back, mode chip, refresh) → the running head (no back on a hub root; the mode chip is the shell's; `Check now` replaces the refresh icon); S23 2 → masthead and deck; S23 3 → `Check now` with live progress; S23 4 → `Mark all read`; S23 5 → the nested tabs `NEW · FOLLOWING`; S23 6 → the grouped NEW rows; S23 7 → FOLLOWING rows; S23 8, 9 → the empty notices; S23 10, 11 → loading and `CORRECTION`; S23 12 → error toasts; S23 13 → pull to reprint; "Not surfaced" settings, runs and per-series check → the schedule deck, the admin aside, `Check this series`; G39 → the stop-press banner's landing.

### C. Collections: `mobile/lib/skins/cinematic/screens/collections/collections_screen.dart` (ScreenId `collections`)

Hub tab `03 COLLECTIONS`.

1. Masthead: kicker `No. 06 — SHELVES`, title "Collections", deck "9 shelves" (the " · 2 shared" and " · 1 shared with you" parts are `mobile/22`'s).
2. Toolbar: below 768 px, a search icon button (expands the `compact` field "Search shelves" in place; filters by name and description client-side) and a `Sort` quiet button opening a sheet (radio list: `Name A–Z`, `Most series`, `Recently created`, `Custom order`), with `New shelf` as a full-width `secondary` under the masthead; at ≥ 768 px one row: the compact search, the Sort menu, primary `New shelf`.
3. **Collection plates** (§7.6): 1 per row on phones (full width, 16:9, 16 px apart), 2 per row on tablets (3 from 900 px). A plate is 16:9: a mosaic of the first four member covers as four vertical strips (each 25 % wide, full height, `BoxFit.cover`, `Alignment(0, -0.56)`, 1 px `#000` gaps; fewer than four widen to fill), all duotoned (`duotone.dart`) to the collection's `previewAmbientDuo` (smart shelves: the first computed member's `ambient.duo`; fallback `#B8B2A4`); the name in `type.subhead` on the solid end of a `scrimFoot` (end colour the first member's `ambient.tint` when known, otherwise `colorAmbientFallbackTint` `#0E0D0B`; solid 24 px above the name's first line box); the credit `24 SERIES · SMART` (`type.credit`) under the name. Pressed: 1 px impression; focus ring around the plate; zero members: the name in `type.subhead` over `paper.1` inside a 1 px `rule.2` frame, no mosaic. Smart shelves compute their mosaic from `evaluateShelf()` (the server's `preview_covers` is empty for rules-based shelves).
4. Tapping a plate opens the detail by the **match cut** of the mosaic into the detail header: the mosaic is a `Hero` tagged `('collection', id)` with `transitionOnUserGestures: defaultTargetPlatform == TargetPlatform.iOS`, pushed through `mobile/06`'s match-cut page (iOS `SwipeablePage` 480 / 336 ms; Android `CineMatchCutPage` 480 / 336 ms). On iOS the 20 pt edge swipe back reverses the match cut with the finger (the Hero flies back as the page follows); on Android the predictive back uses the full-screen fade-through instead; a button pop reverses it in 336 ms `durMatchBack` `CineCurves.turn` into the plate. Reduced motion: 200 ms cross-fades.
5. **Custom order**: in `Custom order`, plates reorder by long-press then drag or by a 40 px `on-art` `dots-six-vertical` handle at the bottom-left (always visible on touch): phones through `SliverReorderableList` (one column), tablets through `mobile/05`'s wall-reorder primitive; the lifted plate rises 1 px with a 1 px `ink.100` outline and siblings shift over 240 ms `CineCurves.set`; drop haptic `select`; the selected plate shows a 2 px `spot` inset frame; `Alt+arrows` move the focused plate with `SemanticsService.announce("Reading plan moved to position 2 of 9", …)`; every plate's long-press menu and `dots-three` hold `Move up`, `Move down`, `Move to top`, `Move to bottom`, also as `Semantics(customSemanticsActions:)`. Writes through `reorderCollections()`; on failure the order reverts with the toast "Couldn't save the order."
6. **New shelf** (a `CineSheetRoute` on phones, a `CineDialog` on tablets; §7.10): `Name` as a big field (`type.field` Bodoni Moda Italic; required, 1–255 characters), `Description` (§7.3 textarea with ruled lines every line height in 1 px `rule.1`, grows to 6 lines then scrolls), a switch `Smart shelf` that reveals the rule chips (AND): *status is* ▸ (a select of the six statuses → `reading_status eq`), *favourite* (a toggle → `is_favorite eq true`), *new chapters ≥* n (a stepper 1–99 → `new_count gte`), *format* ▸ (a multi-select of Manhwa, Manga, Manhua → `format in`), *unfinished novels* (a toggle → `unfinishedNovels`). Actions `Create` (primary, loading while saving) and `Cancel` (quiet). `createCollection(name:, description:, rules:)` (`rules` null when Smart is off). Errors (for example a duplicate name) show under the field in `proof`. Haptic `tap.primary`. The `Share with the circle` switch is `mobile/22`'s.
7. Everything that depends on sharing (the `SHARED WITH YOU` group, `SHARED` badges and member avatars on plates, `CAN ADD` / `VIEW ONLY` captions, Share, Leave shelf, the permission table of §8.11) is `mobile/22`'s; this step builds the owner's view and ignores `shared` and `shared_with_me`.
8. **States**: loading (4 flicker plates); empty (kicker `NO SHELVES YET`, typed headline "No shelves yet.", deck "Group series by theme, mood or reading plan.", primary `New shelf`); no search match (kicker `NOTHING MATCHES`, headline "No shelves match that.", quiet `Clear search`); offline (kicker `OFFLINE EDITION`, headline "Collections need a connection to load."); error (kicker `CORRECTION`, headline "Collections didn't load.", primary `Try again`).
9. Pull to reprint and `R` refetch. **Hardware keys**: `N` new shelf; `/` search; arrows, `Home`/`End`, `Enter` on the grid; `Alt+arrows` in Custom order.

Inventory coverage: S24 1, 2 (app bar add, FAB) → `New shelf`; S24 3 → masthead; S24 4 → search; S24 5 → the Sort sheet or menu; S24 6 → the collection plate; S24 7 → the New shelf form; S24 8–11 → states; S24 12 → pull to reprint.

### D. Collection detail: `mobile/lib/skins/cinematic/screens/collections/collection_screen.dart` (ScreenId `collection`)

Pushed inside branch 1 at `/library/collections/:id` (the mobile alias `/collections/:id` stays), with a back arrow in the running head, the thumb index visible, and no hub tab row.

1. **Header**: the duotone mosaic (as C3, the `Hero` target) across the full width at 16:9 on phones and tablets, with `scrimFoot`; on its solid end: kicker `SHELF · 24 SERIES` (smart: `SMART SHELF · 24 SERIES`), the name in `type.masthead` as `SetHeading` with `SetTrigger.signal` and `level: 1` (it plays when the route animation completes, 480 ms after a match cut, else 160 ms after the first frame), the description deck (`type.deck`, 62 characters max per line), and credits `SMART RULES: READING · 3+ NEW` from `describeRules()` (smart shelves only). The header's `FocusNode` receives focus on arrival.
2. **Actions** (a row under the header): `Add series` (secondary; not on smart shelves), `Edit` (quiet with `pencil-simple-line`), `Reorder` (a toggle; not on smart shelves), `Select` (quiet), and an overflow `dots-three` with `Delete shelf` (`proof`). `Share` is `mobile/22`'s.
   - `Add series`: a `CineSheetRoute` (kicker `ADD SERIES`, a `compact` search, then rows of followed series not on the shelf: 48 × 72 cover, title, source, from `librarySeriesPickerProvider`); tapping a row adds it (`addSeriesToCollection`, haptic `follow.add`, sound `impress` if on) and the row shows a `check` with `ADDED` and stays; "No series available." when all are already on it; loading: 4 greeked rows.
   - `Edit`: the New shelf form prefilled (name, description, and for smart shelves the rule chips); `Save` disabled while unchanged; `updateCollection(... rules:)`.
   - `Delete shelf`: `CineDialog` "Delete {name}? The series stay in your library." with `Delete shelf` (filled `proof`, the 1000 ms arm with the draining 2 px `proof` rule and the "Ready" announcement) and `Cancel`; on success pop back to Collections and toast "Deleted {name}."; haptic `delete.confirm`.
3. **Member wall**: `parts/library_poster.dart` posters with Library captions, 3 per row on phones, 5 on tablets; members joined to library rows by series identity; an orphan (no longer followed) shows the title card and the caption `NO LONGER FOLLOWED`. Select mode (`Select`, or `Remove from shelf` in a poster's Quick look) removes members: `CineDialog` "Remove {n} from {shelf}? It stays in your library." with the arm; `removeSeriesFromCollection` per member through `runBulk` (concurrency 4). Android back leaves select mode first (§8.0.5).
4. **Reorder** (manual shelves): with `Reorder` on, posters show the drag handle and move as C5; writes through `reorderMembers()` with the full ordered visible list; on failure the order reverts with "Couldn't save the order." Android back leaves reorder mode first; on iOS `PopScope(canPop: false)` while reordering, and `Reorder` (toggled off) is the way out.
5. **Smart shelves**: no Add, Remove or Reorder; their rules are edited through `Edit`; the wall is `evaluateShelf(rules, allFollowed)` and updates live by **Cut + Set** when the library changes or the rules are saved.
6. **States**: loading (the header plate flickering + 6 flicker posters); empty (kicker `EMPTY SHELF`, typed headline "This shelf is empty.", primary `Add series`); smart shelf matching nothing (kicker `NOTHING MATCHES`, headline "Nothing matches these rules.", primary `Edit rules`); mode mismatch (every member is of the other content kind: kicker `NOTE`, headline "Everything on this shelf is a novel.", deck "Switch to Novels to see it.", primary `Switch`, which sets the reading mode; the manga wording mirrors it); error (kicker `CORRECTION`, headline "This shelf didn't load.", `Try again`, quiet `Back to collections`); not found or gate-hidden (the §8.0.10 notice with `Back to collections` in place of `Back to Tonight`).
7. Pull to reprint and `R` refetch. **Hardware keys**: `E` edit; `A` add series; `Delete` removes the focused member (after the dialog); grid keys; `X` select mode.

Inventory coverage: S25 1 → the running head with back; S25 2 → the header; S25 3 → `Add series`; S25 4 → `Edit`; S25 5, 6 → `Delete shelf` with the arm; S25 7, 8 → the member wall and `Remove from shelf` with the arm; S25 9 → the Add series sheet; S25 10–12 → states; S25 13 → pull to reprint; M8, M9 (collection form, confirmations) → the New shelf form and the dialogs.

### E. History: `mobile/lib/skins/cinematic/screens/history/history_screen.dart` (ScreenId `history`)

Hub tab `04 HISTORY`.

1. Masthead: kicker `No. 07 — THE LOG`, title "History", deck "What you've been reading, most recent first."
2. Nested contents tabs (tap only): `BY SERIES · BY CHAPTER` (`bySeries` true / false), kept in the screen's state for the branch's lifetime.
3. **The log** from `historyPagesProvider`, grouped by day with date rules (`TODAY`, `YESTERDAY`, `MONDAY 28 SEPTEMBER`). Each row: the time in the left margin (`type.folio` `ink.45`, "21:04"; 40 px margin on phones, 56 px on tablets), a 40 × 60 cover (`Hero`, match cut to the feature page), the title (`type.title`), the caption `CH 142 · p.12 OF 40` (novels `42% IN`), a 2 px progress rule under the caption (`spot` on a `rule.1` track), and the trailing action. Phones: an icon-plus-folio button (`play` 20 Regular + `p.12`, 44 pt / 48 dp hit); tablets: `Continue` (`split` sm with the folio `p.12`). Both enter the reader at the saved spot by **Dip** (`entry: dip`). For a finished chapter the action is `Next │ CH 143` (tablets) or `play` + `CH 143` (phones), resolved with `resolveHistoryContinue()` (A5), showing the button's loading segment and `Semantics` busy while resolving, and falling back to the feature page when there is no next chapter. BY CHAPTER shows one row per chapter read.
4. Tablets: the log spans the 8 columns; no aside (the "This week" aside is desktop-only).
5. **Pagination**: a `quiet` `Load earlier` button at the end (offset + 50; no infinite scroll, §8.12); appended rows fade in as one block over 160 ms.
6. **States**: loading (8 greeked rows); empty (kicker `NOTHING READ YET`, typed headline "Nothing read yet.", deck "Open a chapter and it shows up here.", primary `Go to library`); offline (kicker `OFFLINE EDITION`, headline "Reading history needs a connection to load."); error (kicker `CORRECTION`, headline "History didn't load.", `Try again`). Gated rows are absent (the server removes them).
7. Pull to reprint. **Transitions**: Cut in; Dip into the reader; match cut on the cover. **Hardware keys**: `J`/`K` rows; `Enter` continue; `O` open the series; `T` toggle BY SERIES / BY CHAPTER.

Inventory coverage: S13 1 → the running head (hub root, the shell's mode chip); S13 2 → masthead; S13 3 → the log row (progress rule, fallbacks "Unknown series" in `ink.45`); S13 4 → `Continue` / `Next │ CH n` with the busy state; S13 5–7 → states; S13 8 → pull to reprint.

### F. Bookmarks: `mobile/lib/skins/cinematic/screens/bookmarks/bookmarks_screen.dart` (ScreenId `bookmarks`)

Hub tab `05 BOOKMARKS`. Mobile reads the offline store first and syncs through the bookmark outbox (`bookmarksProvider`); it flushes the outbox before loading, and a caption "Synced 3 bookmarks" appears after a flush.

1. Masthead: kicker `No. 08 — MARKED PASSAGES`, title "Bookmarks", deck "Exact places you marked, in both readers."
2. Filter: a `compact` select "All series ▾" (a sheet listing the series that have bookmarks); the list follows the reading mode.
3. Grouped by series: a subhead per series (`type.subhead`) with its 32 × 48 cover. Each bookmark is a **marginal note**: the folio (`CH 14 · 62% IN` for novels, `CH 14 · PAGE 7` for manga, `type.folio`), for novels the snippet as a pull quote in Newsreader italic with a 2 px `spot` left rule, the user's note in `type.body` (or a `quiet` `Add a note`), the saved date caption (`type.caption`), and for a stale anchor the note in `colorInfo` `#9CC8FF` "The text here changed. This opens at the nearest spot."
4. **Actions per bookmark**: tapping the note opens the right reader at `?page=&at=` (manga) or `?para=&at=` (novel) by **Dip**; `Edit note` opens an inline ruled textarea (§7.3: ruled lines in 1 px `rule.1`, grows to 6 lines then scrolls) saved on focus loss, on the keyboard's done action and on Ctrl/⌘ + Enter through the outbox upsert (A8); a `BookmarkDeletedElsewhere` answer shows the toast "That bookmark was removed on another device." and drops the note; `Remove` (`quiet`) tombstones it through the outbox, with the toast "Bookmark removed" + `Undo` for 8 s (`restoreBookmark()`).
5. Tablets: one column below 900 px, two columns with a 1 px `rule.1` column rule from 900 px (§8.0.9).
6. Phones: a note swipes left to `Remove` (a 72 px `proof` slab with a `#000` label, `Dismissible` end-to-start at 0.5; haptic `delete.confirm`; then the Undo toast); long-press opens `Edit note`, `Remove`, `Open series`; a trailing `dots-three` is the non-gesture path.
7. **States**: loading (5 greeked notes); empty (kicker `NO MARKS YET`, typed headline "No bookmarks yet.", deck "Press B while reading, or tap the bookmark in the reader.", primary `Go to library`); offline (the local store is shown with the caption "Changes sync when you're back online"; editing and removing still work through the outbox); error (kicker `CORRECTION`, headline "Bookmarks didn't load.", `Try again`). Bookmarks of gated series are absent: the local store goes through `mature_filter.dart`.
8. **Hardware keys**: `J`/`K` move between notes; `Enter` open; `E` edit the note; `Delete` remove (with the Undo toast, no dialog).

Inventory coverage: S14 1 → the running head; S14 2 → masthead; S14 3 → the marginal note; S14 4 → `Remove`, now with Undo; S14 5–7 → states; S14 8 → pull to reprint with the outbox flush first.

### G. Wiring

Wire the `updates`, `collections`, `collection`, `history` and `bookmarks` routes in `mobile/lib/skins/cinematic/router.dart` (the mobile aliases `/collections` and `/collections/:id` stay) and remove all five from `PENDING`. Every screen's arrival focus is its masthead or header `FocusNode`. Every icon-only button carries a `Tooltip` and a semantics label.

### H. The re-estimate gate: `docs/redesign/proof/mobile-10/estimate.md`

`docs/redesign/stack-decision.md` §1: "Re-estimate after the first two clusters (primitives, then home and library) on both platforms. If the paired web + Flutter cost per cluster comes in more than 40 % over `stack-keep.md` §6, reopen the choice before Glass starts."

1. **Budget from `stack-keep.md` §6** (Claude-Code-days, CCD): Flutter Cinematic primitives 3.5 + home and library cluster 3.0 + Updates as one fifth of the 3.0 "Updates, downloads, OCR, stats, recommendations" row (0.6) = **7.1 CCD**; web 4.0 + 3.5 + 0.6 = **8.1 CCD**; paired **15.2 CCD**; the reopen threshold is 40 % over: Flutter 9.94, web 11.34, paired 21.28.
2. **Actuals for Flutter**: the steps `mobile/04`, `mobile/05` (primitives) and `mobile/08`, `mobile/09`, `mobile/10` (home and library). For each step count the distinct calendar days with at least one commit of that step (1 CCD = one day on which a session worked that step): `git log --date=short --format='%ad %h %s' --grep='mobile-0[4589]:\|mobile-10:'`, plus, for steps whose messages carry no `mobile-NN:` prefix, `git log --date=short --format='%ad %h %s' -- mobile/lib/skins/cinematic/primitives mobile/lib/skins/cinematic/motion.dart mobile/lib/skins/cinematic/motion_timings.dart` (primitives), `-- mobile/lib/features/home mobile/lib/skins/cinematic/screens/tonight` (mobile/08), `-- mobile/lib/skins/cinematic/screens/library` (mobile/09) and `-- mobile/lib/skins/cinematic/screens/updates mobile/lib/skins/cinematic/screens/collections mobile/lib/skins/cinematic/screens/history mobile/lib/skins/cinematic/screens/bookmarks` (mobile/10). Also report active hours per step: the sum over commit clusters (commits less than 60 minutes apart) of last minus first commit plus 30 minutes.
3. **Web half**: read `docs/redesign/proof/web-10/estimate.md` if it exists. If it does, write the **paired verdict** here and append the same "Paired verdict" section to `docs/redesign/proof/web-10/estimate.md`. If it does not, write the Flutter figures and the rule, and state that `web/10` appends the paired verdict when it finishes (whichever of the two finishes second writes the "Paired verdict" section in both files).
4. **Recommendation**: `PROCEED` when the paired actual is at most 21.28 CCD (or, without the web half, the Flutter actual is at most 9.94 CCD), otherwise `REOPEN` with a one-paragraph case (which rows ran over, why, and the stack decision's cheapest switch point: "Expo for the phones, Next for the web", before Glass starts). Put the recommendation in bold on the first line, then a table: step, days, active hours, budget share, over or under.
5. This file is a document only; do not change `stack-decision.md`.

## File layout

```
mobile/lib/features/library/models/collection.dart                     (rules, smart, previewCovers, previewAmbientDuo, createdAt)
mobile/lib/features/library/repositories/{library_repository,library_repository_impl}.dart   (rules, reorderCollectionMembers)
mobile/lib/features/library/utils/{smart_shelf,history_continue}.dart
mobile/lib/features/library/providers/history_pages_provider.dart
mobile/lib/features/library/screens/reading_history_screen.dart        (calls the moved resolver; no pixel change)
mobile/lib/features/collections/providers/{collection_order,collection_sort_provider}.dart
mobile/lib/features/collections/utils/collection_sorting.dart
mobile/lib/features/updates/utils/notification_grouping.dart
mobile/lib/features/updates/repositories/{updates_repository,updates_repository_impl}.dart   (getRun, listUpdateSources if missing)
mobile/lib/features/updates/providers/…                                 (updateSettingsProvider, seenUpdateIdsProvider)
mobile/lib/features/downloads/providers/bookmark_outbox_provider.dart   (note upsert, 409 mapping, restore)
mobile/lib/features/reader/models/bookmark.dart                         (only if the op lacks note)
mobile/lib/features/profiles/providers/profile_scope.dart               (new providers in the invalidators)
mobile/lib/skins/cinematic/router.dart                                  (five ScreenIds out of PENDING)
mobile/lib/skins/cinematic/shell.dart                                   (only if the banner's landing or hiding is wrong)
mobile/lib/skins/cinematic/screens/updates/{updates_screen,updates_new,updates_following,recent_checks,schedule_sheet}.dart
mobile/lib/skins/cinematic/screens/collections/{collections_screen,collection_plate,collection_screen,shelf_form,add_series_sheet,rule_chips}.dart
mobile/lib/skins/cinematic/screens/history/{history_screen,history_row}.dart
mobile/lib/skins/cinematic/screens/bookmarks/{bookmarks_screen,marginal_note}.dart
mobile/test/features/library/{smart_shelf,history_continue,history_pages}_test.dart
mobile/test/features/collections/collection_order_test.dart
mobile/test/features/updates/notification_grouping_test.dart
mobile/test/features/downloads/bookmark_note_test.dart
mobile/test/skins/cinematic/{updates,collections,history,bookmarks}/*_test.dart
mobile/test/fixtures/{updates,collections,history,bookmarks}/*.json
mobile/test/screenshots/…                                               (the mobile-10 group)
docs/redesign/proof/mobile-10/{plan.md,estimate.md,report.md,device-checklist.md,flutter-test-before.txt,*.png}
docs/redesign/proof/web-10/estimate.md                                  (only the appended "Paired verdict" section, when you finish second)
```

## Acceptance criteria

- [ ] `updates`, `collections`, `collection`, `history`, `bookmarks` are out of `PENDING`; the completeness and import-boundary tests pass; none of the four hub tabs shows a back arrow, and collection detail does.
- [ ] Updates: `Check now` shows the running segment, then "Checking 212 series…" after 400 ms; for an admin the deck counts "Checked N of M" live from `getRun` polls every 2000 ms (fake repository); a 409 shows "A check is already running."; NEW groups by day then series; fresh notifications type their folios once per session; `Mark read` fades a group to `ink.45`; a swipe left marks a group read and does not move the hub (widget test).
- [ ] The admin aside renders only for admins and only from 900 px wide, in columns 6–8; the lists keep columns 1–5 at that width for every role.
- [ ] The stop-press banner is hidden on Updates, and its `Read updates` lands on the Updates tab by `go` from Tonight (Cut, notch on Library) and from inside the hub (tab Cut).
- [ ] Collections: plates are 16:9 duotone mosaics with the name on the solid `scrimFoot`; `Recently created` orders by `createdAt`; Custom order writes only changed `sort_order` values; `Alt+arrows` moves a plate with an announcement; the Move items work from the menu and as semantics custom actions.
- [ ] Smart shelves: creating a shelf with *status is READING* and *new chapters ≥ 3* shows exactly the matching library series (fixture), updates live by Cut + Set when the rules change, and offers no Add, Remove or Reorder.
- [ ] The plate → header match cut runs 480 ms and a button pop reverses it in 336 ms (motion-timings entries); with `TargetPlatform.iOS` the header `Hero` has `transitionOnUserGestures: true` and an edge-swipe drag test moves the page and the Hero together; under reduced motion both are 200 ms cross-fades.
- [ ] Collection detail: Add series adds with the `ADDED` row state; Remove from shelf and Delete shelf have the 1000 ms arm (a tap on the confirm during the arm does nothing); member Reorder sends `PUT /library/collections/{id}/series/order` with the full ordered list; Android back leaves reorder and select modes first.
- [ ] History: day rules, the 40 px (phone) and 56 px (tablet) time margins, the Continue action and `Next │ CH n` with the busy state, `Load earlier` appends 50 rows with one 160 ms fade; the legacy history screen still passes its tests after the resolver move.
- [ ] Bookmarks: marginal notes with pull quotes for novels; a note saves on focus loss and on the done action through the outbox; a 409 shows the removed-elsewhere toast; Remove shows the 8 s Undo toast and Undo restores the bookmark; offline edits queue in the outbox; with the gate closed a mature series' bookmarks are absent.
- [ ] Every state listed in B10, C8, D6, E6 and F7 renders on phone and tablet (screenshots).
- [ ] Reduced motion: letter reveals become 200 ms fades, typed headlines and folios show at once with no caret, Set becomes a 150 ms fade, swipe releases finish with a 150 ms fade, programmatic scrolls jump.
- [ ] Hit targets: `meetsGuideline(iOSTapTargetGuideline)` (iOS) and `meetsGuideline(androidTapTargetGuideline)` (Android) pass for all five screens and the New shelf and Add series sheets; `meetsGuideline(labeledTapTargetGuideline)` passes; the Updates chapter folios each have their own 44 pt / 48 dp box with at least 8 px between them.
- [ ] Hardware keyboard: the keys of B11, C9, D7, E7 and F8 work in widget tests, with `CineFocusRing` on keyboard focus only.
- [ ] `docs/redesign/proof/mobile-10/estimate.md` exists with the bold `PROCEED` or `REOPEN` first line and the per-step table, and the paired verdict when the web half exists.
- [ ] Per skin: `smart_shelf.dart`, `collection_order.dart`, `history_pages_provider.dart`, `history_continue.dart`, `notification_grouping.dart` and the outbox note changes import nothing from `lib/skins/**`, so Glass's hub (`mobile/32`) reuses them (the smart-shelf evaluator is the one both skins run, glass §8.18); Glass's five entries stay in Glass's own `PENDING` set; the legacy screens are unchanged.
- [ ] `flutter analyze` reports "No issues found"; `flutter test` passes with 0 failures at or above the recorded floor; `node design/build.mjs --check` passes.

## Verification

**RAM guard (production shares this box).** Before every heavy command run `free -m` and read the `available` column of the `Mem:` row; under 1024 MB, stop and report "RAM guard: N MB available". Run `pgrep -af "next build|vitest|flutter_tester|flutter test|pytest"` first; never run two heavy commands at once and never `flutter test` while a `next build` runs. No `flutter build`, Gradle, Xcode or `pod install` here; no new packages.

```bash
node design/build.mjs --check
cd mobile && free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze          # baseline: No issues found
cd mobile && free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter test test/features test/skins
cd mobile && free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter test             # baseline: 2012 passed; now >= the floor, 0 failed
```

This step changes nothing in `frontend/` or `backend/` (`git show --stat --format= <hash>` of each of your commits lists neither), so `npm run lint`, `npm run build` and the backend pytest (`cd backend && .venv/bin/python -m pytest -q --no-header`) are not rerun, except the push rule under Git; if a commit touched either, revert that part and run those baseline commands one at a time after the RAM guard.

**Visual proof.** Add a `mobile-10` group to the screenshot harness (invented fixtures only; the repository is public), run `free -m && MM_WRITE_SHOTS=1 /srv/manhwamaniacs/dev/flutter/bin/flutter test test/screenshots/marketing_screenshots_test.dart --plain-name "mobile-10"`, at phone 390 × 844 and tablet 820 × 1180 (the admin aside also at 1024 × 1366), into `docs/redesign/proof/mobile-10/`:

- `updates-new-{phone,tablet}.png`, `updates-following-{phone,tablet}.png`, `updates-checking-phone.png` (admin, live deck), `updates-aside-1024x1366.png`, `updates-{loading,empty,offline,error,notices-off}-{phone,tablet}.png`
- `collections-{phone,tablet}.png`, `collections-custom-order-phone.png`, `collections-new-shelf-smart-{phone,tablet}.png`, `collections-{loading,empty,offline,error}-{phone,tablet}.png`
- `collection-{phone,tablet}.png`, `collection-smart-phone.png`, `collection-reorder-phone.png`, `collection-add-series-phone.png`, `collection-delete-dialog-phone.png`, `collection-{empty,nothing-matches,mode-mismatch,notfound}-phone.png`, `collection-match-cut-mid-phone.png` (the route animation pumped to 240 ms)
- `history-{phone,tablet}.png`, `history-by-chapter-phone.png`, `history-{loading,empty,offline,error}-{phone,tablet}.png`
- `bookmarks-{phone,tablet}.png`, `bookmarks-two-columns-1024x1366.png`, `bookmarks-editing-phone.png`, `bookmarks-{loading,empty,offline,error}-{phone,tablet}.png`
- `hub-reduced-motion-phone.png`, `hub-text-2.0-phone.png`
- Compare the phone captures with `docs/redesign/proof/web-10/*-390x844.png` when present and list the differences.
- `docs/redesign/proof/mobile-10/device-checklist.md` (owner, iPhone via SideStore after CI builds the IPA and the Android flagship): the plate → header match cut and its iOS edge-swipe reversal with the finger, the Android predictive-back fade-through from detail, a swipe row versus the hub swipe, the Updates check with the `tap.primary` and `success` haptics, the arm dialogs with a double tap, VoiceOver and TalkBack on marginal notes, text scale 1.3 and 2.0, with the motion-timings overlay on (no `proof` rows).
- `docs/redesign/proof/mobile-10/report.md` mapping each screenshot to its acceptance item.

## Git

- Branch `feat/vps-slim-source-native`; small commits, one per working step (collection model and calls; the smart-shelf evaluator; collection order; the history resolver move (no pixels); history pages; notification grouping; bookmark notes; Updates; Collections; collection detail; History; Bookmarks; wiring; the estimate; proof), messages starting `mobile-10:`.
- Stage only your paths with explicit `git add <path>`; never `git add -A` or `git add .`. Never commit secrets, demo credentials, `.claude/` or `.env` files.
- **No Claude or AI attribution anywhere**: no `Co-Authored-By`, no "Generated with" line, no AI author, even if your harness asks for it (the owner's `~/.claude/CLAUDE.md` forbids it).
- Before every push: `flutter analyze` is clean; `git fetch origin` and `git diff --stat origin/feat/vps-slim-source-native...HEAD -- frontend`; if that lists files, run `free -m && npm run build` in `frontend/` first (never while `flutter test` runs) and push only if it passes. Then `git push origin feat/vps-slim-source-native` after each working step.

## Guardrails

- Never edit `backend/connectors/`; never touch production containers or `/srv/manhwamaniacs/{app,data}`; do not deploy.
- No changes under `frontend/`, `backend/` or `design/` (the only file outside `mobile/` and `docs/redesign/proof/mobile-10/` you may write is the appended section of `docs/redesign/proof/web-10/estimate.md`).
- Nothing from `mobile/lib/features/*/screens/`, `mobile/lib/features/*/widgets/`, `mobile/lib/shared/widgets/` or `mobile/lib/app/theme/` is imported by skin code; logic found in a legacy widget or screen moves first in a no-pixel commit. Never reproduce the legacy look.
- Do not build what later steps own: sharing on shelves, `SHARED WITH YOU`, Leave shelf and letters (`mobile/22`); Settings → Notifications (`mobile/18`); the readers (`mobile/12`–`mobile/15`).

## Report back

1. **Done**: items A1–A8, B1–B12, C1–C9, D1–D7, E1–E7, F1–F8, G and H with a one-line status each.
2. **Screenshots**: `docs/redesign/proof/mobile-10/`, the file list and the differences against the web twin.
3. **Tests**: `flutter test` passed before and after (0 failed), `flutter analyze`, `node design/build.mjs --check`, and `free -m` before each heavy command.
4. **Estimate**: the bold recommendation line of `estimate.md`, the Flutter actual in CCD, and whether the paired verdict was written (and into which files).
5. **Open issues**: ambiguities and the choices made, blocked items, conflicts with DESIGN.md.
6. **Commits**: the hashes pushed.

Next prompt file: `docs/redesign/prompts/mobile/11-cinematic-feature-and-book-pages.md`.
