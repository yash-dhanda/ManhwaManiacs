# Web 10: Cinematic Updates, Collections, History and Bookmarks

## Goal

Build the other four Library hub tabs of the Cinematic skin on the web client (`frontend/`), per `docs/redesign/cinematic/DESIGN.md` §8.10–§8.13: **Updates** (`/updates`, "Stop press": the check with live progress, NEW grouped by day and series with typed chapter folios, the FOLLOWING tab, mark all read, the admin "Recent checks" aside), **Collections** and **collection detail** (`/library/collections`, `/library/collections/:id`: duotone plates from `preview_covers`, smart shelves whose rules are evaluated on the device, custom order and member reorder, the match cut into the header and its reverse), **History** (`/library/history`, "The log" with its time margin) and **Bookmarks** (`/library/bookmarks`, "Marked passages" for manga and novels), each with every state, for desktop web and mobile web, inside the Library hub frame web/09 built. Then run the **re-estimate gate** of `docs/redesign/stack-decision.md` §1: measure the actual cost of the Cinematic primitives and library clusters against `docs/redesign/stack-keep.md` §6 and write `docs/redesign/proof/web-10/estimate.md` with a proceed or reopen recommendation. When you finish, `updates`, `collections`, `collection`, `history` and `bookmarks` leave the Cinematic `PENDING` set. `docs/redesign/prompts/mobile/10-cinematic-updates-collections-history-bookmarks.md` runs the same cluster on Flutter in parallel; do not touch `mobile/`.

## Read first

DESIGN.md is binding; conflicts are reported, and DESIGN.md wins.

- `docs/redesign/cinematic/DESIGN.md`:
  - §2.1.1, §2.1.4 (`scrim.foot`), §2.1.5 (duotone matrix), §2.2, §2.8, §3.5.
  - §4 (Cut, Set, Page, match cut and its 336 ms reverse, Dip, Rule slide, stagger, reduced motion §4.8), §5 and §6 (events used here).
  - §7 intro, §7.1, §7.2, §7.3 (fields; textarea), §7.4 `compact`, §7.5, §7.6 (Collection plate, Stat block), §7.7, §7.9, §7.10 (arm delay; dialogs), §7.11, §7.12 (contents tabs; nested tabs are tap only), §7.16 (rows: standard, schedule, swipe slabs, drag to reorder), §7.17, §7.18, §7.19, §7.21, §7.22 (menus and Move items), §7.23, §7.24, §7.27, §7.29 (pull to reprint, banner strips, spoken folios).
  - §8.0.2–§8.0.5 (the hub routes, the Library branch, Page and match-cut rules, the Dip into readers), §8.0.8, §8.0.9 (tablet rows for Updates, Collections, History, Bookmarks), §8.0.10.
  - **§8.10, §8.11, §8.12, §8.13, entire.**
  - §8.33.3 (the stop-press banner goes to Updates), §9.3.5 (only to know what is deferred to web/22), §10.1, §10.2 (typed notice headlines and Updates folios), §11 (rows for these screens), §14, §15.6, §15.7.
- `docs/redesign/glass/DESIGN.md` §15.6 row "Collection order and creation date" and §8.18 "Auto (smart) collections" (one evaluator in `frontend/src/features/library/` for both skins).
- `docs/redesign/inventory/web.md` §7.4 (CO1–CO10), §7.5 (CD1–CD12), §7.6 (RH1–RH5), §11 (UP1–UP8), §13 (BM1–BM5), §18.9.
- `docs/redesign/inventory/capabilities.md` §11 (collections), §14 (history), §15 (bookmarks), §21 (updates).
- `docs/redesign/stack-decision.md` §1 (the re-estimate condition), §2.2, §2.6; `docs/redesign/stack-keep.md` §6 (the estimate table); `docs/redesign/inventory/00-decisions.md`; `docs/redesign/00-baseline.md`.

## Before you start

1. Work in `/srv/manhwamaniacs/dev/ManhwaManiacs` on branch `feat/vps-slim-source-native`; `git status --porcelain` and note other sessions' modified files (never stage them).
2. Dependency: `docs/redesign/prompts/web/09-cinematic-library-shelf-browse.md`. Check `ls frontend/src/skins/cinematic/screens/library/LibraryHub.tsx frontend/src/skins/cinematic/parts/LibraryPoster.tsx frontend/src/features/library/mark-read.ts` and that `library` is out of `PENDING` in `frontend/src/skins/cinematic/index.ts`. Also check backend/02 landed: `grep -n "rules\|preview_covers" backend/routes/library.py backend/services/followed_series_service.py`. If a check fails, stop and report it.
3. Inventory and reuse (never re-implement a primitive inside a screen): `ls frontend/src/skins/cinematic/primitives frontend/src/skins/cinematic/parts`; `grep -n "^export" frontend/src/features/updates/hooks.ts frontend/src/features/bookmarks/hooks.ts frontend/src/features/bookmarks/api.ts frontend/src/features/library/hooks.ts frontend/src/features/library/collections.ts frontend/src/features/library/history-continue.ts`. Existing hooks: `useUpdateSettings`, `useUpdateNotifications`, `useUnreadNotificationCount`, `useUpdateRuns`, `useManualCheck`, `useCheckFollowed`, `useMarkNotificationRead`, `useMarkAllNotificationsRead`; `useBookmarks`, `useDeleteBookmark`; `useCollections`, `useCollection`, `useCreateCollection`, `useUpdateCollection`, `useDeleteCollection`, `useAddSeriesToCollection`, `useRemoveSeriesFromCollection`, `resolveCollectionMembers`; `useReadingHistory`, `historyResumePoint`, `seriesContinue`; `useStatistics`; `useAllFollowedSeries`. If a primitive lacks a variant, add it to the primitive file and the gallery under `frontend/src/app/(preview)/`.
4. Record the Vitest baseline (RAM guard below): `cd frontend && npm run test 2>&1 | tail -5`.

## Skills to invoke

1. `superpowers:writing-plans` before any code; save as `docs/redesign/proof/web-10/plan.md`.
2. `superpowers:subagent-driven-development` (or `superpowers:executing-plans`). Scope-lock subagent prompts to named files; verify with `git status` and `git diff`, never with an agent's report.
3. `frontend-design:frontend-design`, `impeccable:impeccable`, `taste-skill:taste-skill` for design review against DESIGN.md (never changing its fixed values or copy).
4. `superpowers:verification-before-completion` before claiming done.

## Scope

Cinematic only (Glass's versions are web/32). Section numbers refer to `docs/redesign/cinematic/DESIGN.md`. Every screen renders inside `LibraryHub` (web/09) with its own masthead, except collection detail, which is a pushed page (back arrow on phones, breadcrumb `No. 06 · COLLECTIONS / {shelf}` on desktop) with no hub tab row.

### A. Backend contract (read only; backend/02 owns it)

The two values both skins need for collections (`docs/redesign/glass/DESIGN.md` §15.6 "Collection order and creation date") are built by `docs/redesign/prompts/backend/02-library-series-ocr-extensions.md` items C.3 and C.4, which run before this step (plan order 19; web/09 already checked backend/02 landed). This step changes nothing under `backend/`. The contract the client follows:

- `created_at` (ISO 8601 string) on every serialized collection.
- `PUT /library/collections/{id}/series/order` (profile context, 204), body `{"items": [{"source_id", "series_key"}]}`: the **full** ordered list of the members the active profile can see. It must equal the visible membership exactly (same pairs, no duplicates), otherwise `422 order_mismatch`; members hidden by the 18+ gate keep their relative order after the visible ones, so the call never reveals or drops them; another profile's collection is 404. (backend/09 later adds 403 for shared-shelf members; web/22 handles it.)

Check before you start: `grep -n "series/order" backend/routes/library.py` and `grep -n "created_at" backend/services/followed_series_service.py` both find their lines. If either is missing, backend/02 is not done: stop and report it (never add the endpoint here; a second implementation would fork the exact-set rule).

### B. Shared data layer additions (skin-neutral, `frontend/src/features/`)

No JSX, no import from `src/skins/**`, a Vitest `*.test.ts` beside each logic file.

1. `features/library/smart-shelf.ts`: the one smart-shelf evaluator both skins use (glass §8.18). Types `ShelfRules = {all: ShelfRule[]}`, `ShelfRule = {field: "reading_status" | "is_favorite" | "new_count" | "format" | "content_kind", op: "eq" | "gte" | "in" | "ne", value}`; `evaluateShelf(rules, rows)` over `FollowedSeries` list rows (`new_count` from `read_state.new_count`; `format` from the row's format field; `content_kind` from the row's content kind), AND across rules, keeping the library order; `describeRules(rules)` → the credit text (`READING · 3+ NEW · FAVOURITES · MANHWA, MANGA · UNFINISHED NOVELS`); `UNFINISHED_NOVELS = [{field: "content_kind", op: "eq", value: "novel"}, {field: "reading_status", op: "ne", value: "completed"}]`. Test: each operator, AND, empty rules, the unfinished-novels pair, unknown fields ignored.
2. `features/library/collection-order.ts`: `useReorderCollections()` (PATCH `sort_order` for the changed collections only, concurrency 4, optimistic with rollback) and `useReorderCollectionMembers(id)` (`PUT /library/collections/{id}/series/order {items}` with every visible member in the new order, never a partial list; optimistic with rollback; a `422 order_mismatch` means the membership changed underneath, so it refetches the shelf before the caller's failure toast). Uses `changedSortOrders()` from web/09's `manual-order.ts`.
3. `features/library/history-pages.ts`: `useReadingHistoryPages({ collapse: "series" | "none" })` on `useInfiniteQuery` over `GET /reader/history?limit=50&offset=&collapse=`, `getNextPageParam` = offset + 50 while a page returned 50 rows. Test for the page-param function.
4. `features/bookmarks/note.ts`: `saveBookmarkNote(bookmark, note)` → `POST /reader/bookmarks/batch` with the one-item upsert carrying `note` (and the bookmark's existing position fields), mapping a `bookmark_deleted` (409) refusal to a typed error; `restoreBookmark(bookmark)` (the same upsert with every field, for Undo after a remove). Test for the payload shape.
5. `features/updates/grouping.ts`: `groupNotifications(items, now, sourceFilter)` → days (`TODAY`, `YESTERDAY`, else `MONDAY 28 SEPTEMBER` in the device locale's English names, uppercase) → series groups `{source_id, series_key, title, cover_url, ambient, chapters: [{notification_id, chapter_key, chapter_number, read}], newestAt}`, chapters in ascending chapter number, groups by newest first; `firstUnread(group)`. Test included.

### C. Updates: `frontend/src/skins/cinematic/screens/updates/UpdatesScreen.tsx` (ScreenId `updates`)

Hub tab `02 UPDATES`. `document.title` "Updates · ManhwaManiacs". Hierarchy: masthead → the check → new chapters by series → the following list (tab).

1. Masthead: kicker `No. 03 — STOP PRESS`, title "Updates", deck "14 new chapters across 6 series · last checked 12 min ago · checking every 30 min" (from the notifications and `useUpdateSettings()`; drop parts that are unknown). The deck is a button: for admins it links to `/settings/notifications` (Settings arrives in web/18); for everyone else it opens a sheet (kicker `SCHEDULE`, title "When chapters are checked", lines "Checking every 30 minutes.", "Last check: 21:04.", and, when the profile's `notify_enabled` is off, "New-chapter notices are off for this profile.").
2. Actions under the masthead: primary `Check now` (`POST /updates/check {}` via `useManualCheck()`; loading state: the label keeps its box and a 2 px `spot` segment 25 % wide runs along the button's inside bottom edge on a 1200 ms linear loop; after 400 ms the label reads "Checking 212 series…"; for admins the run is polled through `GET /updates/runs/{id}` every 2000 ms and the deck updates live "Checked 180 of 212 · 3 new"; for others the unread count is re-polled at 3, 5 and 7 s; haptic `tap.primary`; `409 check_already_running` → a caption "A check is already running." under the button); secondary `Mark all read` (`POST /updates/notifications/read-all`, labelled `Mark all manga read` / `Mark all novels read` by content mode when novels are enabled, disabled with nothing unread; toast "Marked every new chapter as seen.").
3. Nested contents tabs (tap only, §11): `NEW ¹⁴ · FOLLOWING ²¹²` (`?tab=following`), with a `SOURCE ▾` compact select at the row's right end (`All sources` plus `GET /updates/sources`, filtering both tabs client-side; hidden when only one source has follows).
4. **NEW**: `groupNotifications()` rendered as date rules (`type.kicker` over a `rule.hair`) then series groups: a 48 × 72 cover (match cut to the feature page), the series title (`type.title`), a `NEW` count badge (fill `spot`, `#000`), the new chapter folios as a slug line `CH 141 · CH 142 · CH 143` (each a link into the reader by **Dip**), the source credit and time (`type.caption`), and the row actions `Read from 141` (`split` sm, Dip into the reader at the group's first unread chapter) and `Mark read` (`quiet`; marks the group's notifications read through `useMarkNotificationRead()`, concurrency 4). Fully read groups fade to `ink.45` text (160 ms) and stay listed. Desktop: the row actions sit at the right end; hover gives the §7.16 left bar. Phones: a group swipes left to `Mark read` (a 72 px flat slab filled `ink.100` with a `#000` label; release past 50 % commits with `spring.release` 420 ms bounce 0, the row springs back and dims; `touch-action: pan-y`); long-press opens the row menu `Read from 141`, `Mark read`, `Open series` (haptic `longpress.open`); a trailing `dots-three` is the non-gesture path.
5. **Signature moment**: new chapter folios type themselves (50 ms per character, `TypedHeadline` as `span`, no caret after it finishes) the first time a fresh notification appears after a check: ids not yet in the session set `sessionStorage['mm.updates.seen']` (updated after typing).
6. **FOLLOWING**: the followed series (from `useAllFollowedSeries()`, filtered by the content mode and the source select) as §7.16 standard rows: 48 × 72 cover, title, source name, "Checked 12 min ago" / "Not checked yet" (from `last_checked_at`), a Notify bell toggle (`bare` icon button, `aria-pressed`, selected: Fill glyph and the 2 px `spot` rule; `PATCH /library/series/{id} {notify}`), and a trailing `dots-three` menu with `Check this series` (`POST /updates/followed/{id}/check` via `useCheckFollowed()`, toast "Checking {title}.") and `Unfollow` (`proof` item; commits at once with the toast "Removed {title}." + `Undo`, 8000 ms, re-following with status, favourite, notify, override and position).
7. **Aside** (desktop ≥ 1024 px, admins only): "Recent checks" as a credits list (§7.28 `Credits`, label → dot leaders → value): `trigger · status · series · new · started` rows from `useUpdateRuns()`; 3 greeked rows while loading; "No check runs yet." when empty. The NEW and FOLLOWING lists keep columns 1–8 at every role (so the row measure never changes); columns 9–12 hold the aside for admins and stay empty otherwise. Tablet widths (768–1023 px): one column across 8, and from 900 px the NEW list takes columns 1–5 and the aside columns 6–8.
8. The reserved push prompt of §8.10 is not built (no push support exists).
9. **Phones**: one column; the admin aside is not shown (it lives in Settings → Notifications, web/18); pull to reprint reloads the list and never starts a server check (`Check now` does).
10. **States**: loading (3 greeked groups); NEW empty (kicker `NOTHING NEW`, typed headline "No new chapters yet.", deck "Follow a series and this fills in the moment a chapter lands.", primary `Find something` → `/search`); FOLLOWING empty (kicker `NOTHING FOLLOWED YET`, headline "Nothing followed yet.", primary `Find something`); notices off for the profile (`notify_enabled` false: a `NOTE` kicker line in `spot` "New-chapter notices are off for this profile." with `Turn on` → `PATCH /profiles/{id} {notify_enabled: true}`); a check already running (the 409 caption); offline (kicker `OFFLINE EDITION`, headline "Updates need a connection to check.", the cached list shown read-only below it, every action disabled with the tooltip "Needs a connection."); error (kicker `CORRECTION`, headline "Updates didn't load.", deck "The server didn't answer.", primary `Try again`); rate limited (kicker `SLOW DOWN`, the live "Retrying in 12 s" folio from `Retry-After`). The 18+ gate: notifications of hidden series are absent (the server filters) and counts never imply them.
11. **Keys (web)**: `r` reload the list; `c` `Check now`; `j`/`k` move between series groups; `Enter` reads the focused group; `m` marks it read; `shift+m` marks all read. All in the `?` sheet.
12. **Transitions**: in by the hub tab Cut; the stop-press banner's `Read updates` is web/06's `go('/updates')`; out by Dip into the reader and by the match cut from covers to the feature page.

Inventory coverage: UP1 → masthead; UP2 → `Check now` with live progress; UP3 → the error notice and caption lines; UP4 → the masthead deck link or schedule sheet; UP5 → `Mark all read`; UP6 → the grouped rows; UP7 → states; UP8 → the admin aside.

### D. Collections: `frontend/src/skins/cinematic/screens/collections/CollectionsScreen.tsx` (ScreenId `collections`)

Hub tab `03 COLLECTIONS`. `document.title` "Collections · ManhwaManiacs".

1. Masthead: kicker `No. 06 — SHELVES`, title "Collections", deck "9 shelves" (the " · 2 shared" and " · 1 shared with you" parts are added by web/22).
2. Toolbar: the `compact` search ("Search shelves"; filters by name and description client-side), a Sort menu (`Name A–Z`, `Most series`, `Recently created` (by `created_at`, newest first; by `id` descending when the field is absent), `Custom order`), remembered per profile in scoped `localStorage` `mm.collections.sort`, and primary `New shelf`. Phones: the toolbar collapses to a search icon (expands the compact field) and a `Sort` sheet; `New shelf` sits under the masthead as a full-width secondary.
3. Grid of **collection plates** (§7.6): 3 per row on desktop, 4 at wide and cinema, 2 per row at 768–1023 px (3 from 900 px), 1 per row on phones (full width, 16 px apart). A plate is 16:9: a mosaic of the first four member covers as four vertical strips (each 25 % wide, full height, `object-fit: cover`, `object-position: 50% 22%`, 1 px `#000` gaps; fewer than four widen to fill), all duotoned (§2.1.5 matrix) to the collection's `preview_ambient_duo` (smart shelves: the first computed member's `ambient.duo`; fallback `#B8B2A4`); the name in `type.subhead` on the solid end of a `scrim.foot` (end colour the matching `ambient.tint`, fallback `#0E0D0B`; the gradient reaches alpha 1 24 px above the name's first line box); the credit `24 SERIES · SMART` (`type.credit`) under the name. Hover: the mosaic zooms 1.03 inside its frame (200 ms `dur.clip` `ease.settle`) and the name underlines; pressed: 1 px impression; focus ring around the plate; zero members: the name in `type.subhead` over `paper.1` inside a 1 px `rule.2` frame, no mosaic. Plates of smart shelves compute their mosaic from `evaluateShelf()` (the server's `preview_covers` is empty for rules-based shelves).
4. Tapping a plate opens the detail by the **match cut** of the mosaic into the detail header (`<ViewTransition name={"collection-" + id} share="mm-match-cut">`, 480 ms `ease.turn`); back reverses it (336 ms `dur.match.back` `ease.turn`) into the plate when it is still in the tree, otherwise Page.
5. **Custom order**: in `Custom order`, plates are draggable (a 40 px `on-art` `dots-six-vertical` handle at the bottom-left, always visible on coarse pointers; `@use-gesture/react` `useDrag` with Motion `layout` shifting siblings over 240 ms `ease.set`; the lifted plate rises 1 px with a 1 px `ink.100` outline; drop haptic `select`); the selected plate in reorder mode shows a 2 px `spot` inset frame; `Alt+arrows` move the focused plate with a polite announcement ("Reading plan moved to position 2 of 9"); every plate's menu (right-click, long-press, `dots-three`) has `Move up`, `Move down`, `Move to top`, `Move to bottom`. Writes through `useReorderCollections()`; on failure the order reverts with the toast "Couldn't save the order."
6. **New shelf** dialog (§7.10; a sheet on phones): `Name` as a big field (`type.field` Bodoni Moda Italic; required, 1–255 characters), `Description` (§7.3 textarea with ruled lines, grows to 6 lines), a switch `Smart shelf` that reveals the rule chips (combined with AND): *status is* ▸ (a select of the six statuses → `reading_status eq`), *favourite* (a toggle → `is_favorite eq true`), *new chapters ≥* n (a stepper 1–99 → `new_count gte`), *format* ▸ (a multi-select of Manhwa, Manga, Manhua → `format in`), *unfinished novels* (a toggle → the `UNFINISHED_NOVELS` pair). Actions `Create` (primary, loading while saving) and `Cancel` (quiet). `POST /library/collections {name, description, rules}` (`rules: null` when Smart is off). Errors (for example a duplicate name) show under the field in `proof` with `‸` on desktop. Haptic `tap.primary`. The `Share with the circle` switch is added by web/22.
7. Everything that depends on sharing (the `SHARED WITH YOU` group, `SHARED` badges and member avatars on plates, `CAN ADD` / `VIEW ONLY` captions, Share, Leave shelf and the shared-shelf permission table of §8.11) is web/22's; this step builds the owner's view and ignores `shared` and `shared_with_me`.
8. **States**: loading (4 flicker plates); empty (kicker `NO SHELVES YET`, typed headline "No shelves yet.", deck "Group series by theme, mood or reading plan.", primary `New shelf`); no search match (kicker `NOTHING MATCHES`, headline "No shelves match that.", quiet `Clear search`); offline (kicker `OFFLINE EDITION`, headline "Collections need a connection to load."); error (kicker `CORRECTION`, headline "Collections didn't load.", primary `Try again`).
9. Pull to reprint (phones) and `r` refetch. **Keys**: `n` new shelf; `/` search; `h j k l`, arrows, `Home`/`End`, `Enter` on the grid; `Alt+arrows` in Custom order.

Inventory coverage: CO1 → masthead; CO2 → `New shelf`; CO3 → search; CO4 → Sort menu; CO5 → the collection plate; CO6 → the New shelf dialog; CO7–CO10 → states.

### E. Collection detail: `frontend/src/skins/cinematic/screens/collections/CollectionScreen.tsx` (ScreenId `collection`)

Pushed inside the Library branch (`/library/collections/:id`), with a back arrow on phones and the breadcrumb on desktop; no hub tab row; `document.title` "{Shelf} · ManhwaManiacs".

1. **Header spread**: the duotone mosaic (as D3) across the full content width at 3:1 on desktop and 16:9 on phones and tablets, with `scrim.foot`; on its solid end: kicker `SHELF · 24 SERIES` (smart: `SMART SHELF · 24 SERIES`), the name in `type.masthead` as `SetHeading` `trigger="signal"` `as="h1"` (plays 480 ms after the route commits when it arrived by the match cut, else 160 ms after first paint), the description deck (`type.deck`, 62ch), and credits `SMART RULES: READING · 3+ NEW` from `describeRules()` (smart shelves only).
2. **Actions** (row under the header): `Add series` (secondary; not on smart shelves), `Edit` (quiet with `pencil-simple-line`), `Reorder` (a toggle button; not on smart shelves), and an overflow `dots-three` with `Delete shelf` (`proof`). `Share` is web/22's.
   - `Add series`: a sheet on phones, a column panel on desktop (4 columns, min 400 px, from the right edge, `Esc` closes): kicker `ADD SERIES`, a `compact` search, then rows of followed series not on the shelf (48 × 72 cover, title, source), from `useAllFollowedSeries()`; tapping a row adds it (`useAddSeriesToCollection()`, haptic `follow.add`, sound `impress` if on) and the row shows a `check` with `ADDED` and stays; "No series available." when all are already on it; loading: 4 greeked rows.
   - `Edit`: the New shelf dialog prefilled (name, description, and for smart shelves the rule chips), `Save` (disabled while unchanged) through `useUpdateCollection()` with `rules`.
   - `Delete shelf`: dialog "Delete {name}? The series stay in your library." with `Delete shelf` (filled `proof`, the 1000 ms arm) and `Cancel`; on success navigate back to Collections and toast "Deleted {name}."; haptic `delete.confirm`.
3. **Member wall**: `parts/LibraryPoster.tsx` posters with Library captions, 6 per row on desktop (8 at wide), 5 at 768–1023 px, 3 on phones; members joined to library rows (`resolveCollectionMembers()`); an orphan (no longer followed) shows the title card and the caption `NO LONGER FOLLOWED`. Select mode (the `Select` quiet button in the action row, or long-press) and the per-poster menu offer `Remove from shelf`: dialog "Remove {n} from {shelf}? It stays in your library." with the arm; `useRemoveSeriesFromCollection()` per member, concurrency 4.
4. **Reorder** (manual shelves): with `Reorder` on, posters show the drag handle and move as D5 (Motion `layout`, `useDrag`, `Alt+arrows`, Move items); writes through `useReorderCollectionMembers(id)`; on failure the order reverts with "Couldn't save the order."
5. **Smart shelves**: no Add and no Remove; their rules are edited through `Edit`; the wall is `evaluateShelf(rules, useAllFollowedSeries())` and updates live by **Cut + Set** when the library changes or rules are saved.
6. **States**: loading (the spread plate flickering + 6 flicker posters); empty (kicker `EMPTY SHELF`, typed headline "This shelf is empty.", primary `Add series`); smart shelf matching nothing (kicker `NOTHING MATCHES`, headline "Nothing matches these rules.", primary `Edit rules`); mode mismatch (every member is of the other content kind: kicker `NOTE`, headline "Everything on this shelf is a novel.", deck "Switch to Novels to see it.", primary `Switch`, which sets the reading mode; the manga wording mirrors it); error (kicker `CORRECTION`, headline "This shelf didn't load.", `Try again`, quiet `Back to collections`); not found or gate-hidden (the §8.0.10 notice with `Back to collections` in place of `Back to Tonight`).
7. Pull to reprint (phones) and `r` refetch. **Keys**: `e` edit; `a` add series; `Delete` removes the focused member (after the dialog); grid keys; `x` select mode.

Inventory coverage: CD1 → header spread; CD2 → back arrow and breadcrumb; CD3 → name, description, count in the kicker; CD4 → Edit; CD5 → Add series; CD6 → Remove from shelf; CD7 → Delete shelf; CD8 → the member wall; CD9–CD12 → states.

### F. History: `frontend/src/skins/cinematic/screens/history/HistoryScreen.tsx` (ScreenId `history`)

Hub tab `04 HISTORY`. `document.title` "History · ManhwaManiacs".

1. Masthead: kicker `No. 07 — THE LOG`, title "History", deck "What you've been reading, most recent first."
2. Nested contents tabs (tap only): `BY SERIES · BY CHAPTER` (`collapse=series` / `collapse=none`), remembered in the URL as `?view=chapter` for BY CHAPTER.
3. **The log** from `useReadingHistoryPages()`, grouped by day with date rules (`TODAY`, `YESTERDAY`, `MONDAY 28 SEPTEMBER`). Each row: the time in the left margin (`type.folio` `ink.45`, "21:04"; the margin is 56 px on desktop and tablets, 40 px on phones), a 40 × 60 cover (match cut to the feature page), the title (`type.title`), the caption `CH 142 · p.12 OF 40` (novels `42% IN`), a 2 px progress rule under the caption (`spot` on a `rule.1` track), and the trailing action: `Continue` (`split` sm with the folio `p.12`, Dip into the reader at the saved spot) or, for a finished chapter, `Next │ CH 143` (resolves the next chapter from the chapter list with `seriesContinue()`/`historyResumePoint()`, shows the button's loading segment and `aria-busy` while resolving, and falls back to the feature page when there is no next chapter). BY CHAPTER shows one row per chapter read.
4. **Desktop**: the log spans columns 1–8; a 4-column aside "This week" holds two stat blocks (§7.6: 3 px `rule.heavy`, kicker, `type.numeral`, caption): `CHAPTERS` and `TIME` from `useStatistics(7)`.
5. **Pagination**: a `quiet` `Load earlier` button at the end (offset + 50; no infinite scroll); appended rows fade in as one block over 160 ms.
6. **Phones**: the log runs full width with the 40 px time margin; the aside is dropped; `Continue` becomes an icon-plus-folio button (`play` 20 Regular + `p.12`, 44 px hit); pull to reprint.
7. **States**: loading (8 greeked rows); empty (kicker `NOTHING READ YET`, typed headline "Nothing read yet.", deck "Open a chapter and it shows up here.", primary `Go to library`); offline (kicker `OFFLINE EDITION`, headline "Reading history needs a connection to load."); error (kicker `CORRECTION`, headline "History didn't load.", `Try again`). Gated rows are absent (the server removes them).
8. **Transitions**: Cut in; Dip into the reader on Continue and Next; match cut on the cover. **Keys**: `j`/`k` rows; `Enter` continue; `o` open the series; `t` toggle BY SERIES / BY CHAPTER.

Inventory coverage: RH1 → masthead; RH2 → the log row; RH3 → `Continue`; RH4 → `Next │ CH n`; RH5 → states (and pagination is new).

### G. Bookmarks: `frontend/src/skins/cinematic/screens/bookmarks/BookmarksScreen.tsx` (ScreenId `bookmarks`)

Hub tab `05 BOOKMARKS`. `document.title` "Bookmarks · ManhwaManiacs".

1. Masthead: kicker `No. 08 — MARKED PASSAGES`, title "Bookmarks", deck "Exact places you marked, in both readers."
2. Filter: a `compact` select "All series ▾" listing the series that have bookmarks (and `?source&series` in the URL, the query state glass §15.6 shares); the list follows the reading mode.
3. Grouped by series: a subhead per series (`type.subhead`) with its 32 × 48 cover. Each bookmark is a **marginal note**: the folio (`CH 14 · 62% IN` for novels, `CH 14 · PAGE 7` for manga, `type.folio`), for novels the snippet as a pull quote in Newsreader italic with a 2 px `spot` left rule, the user's note in `type.body` (or a `quiet` `Add a note`), the saved date caption (`type.caption`), and for a stale anchor the note in `color.info` `#9CC8FF` "The text here changed. This opens at the nearest spot."
4. **Actions per bookmark**: tapping the note opens the right reader at `?page=&at=` (manga) or `?para=&at=` (novel) by **Dip**; `Edit note` opens an inline textarea (§7.3: ruled lines every line height in 1 px `rule.1`, grows to 6 lines then scrolls) saved on blur or `mod+Enter` through `saveBookmarkNote()`; a `bookmark_deleted` (409) refusal shows the toast "That bookmark was removed on another device." and drops the note; `Remove` (`quiet`) deletes it (`useDeleteBookmark()`) with the toast "Bookmark removed" + `Undo` for 8 s (`restoreBookmark()`).
5. **Desktop**: notes in one column across 8 columns at 1024–1439 px; at wide widths (≥ 1440 px) two columns with a 1 px `rule.1` column rule; tablets two columns from 900 px.
6. **Phones**: groups full width; a note swipes left to `Remove` (a 72 px `proof` slab with a `#000` label; haptic `delete.confirm`; then the Undo toast); long-press opens `Edit note`, `Remove`, `Open series`; a trailing `dots-three` is the non-gesture path.
7. **States**: loading (5 greeked notes); empty (kicker `NO MARKS YET`, typed headline "No bookmarks yet.", deck "Press B while reading, or tap the bookmark in the reader.", primary `Go to library`); offline (the web reads the server list: the cached list stays readable under a `NOTE` line "Bookmarks need a connection to change.", and Edit and Remove are disabled with the tooltip "Needs a connection."); error (kicker `CORRECTION`, headline "Bookmarks didn't load.", `Try again`). Bookmarks of gated series are absent.
8. **Keys**: `j`/`k` move between notes; `Enter` open; `e` edit the note; `Delete` remove (with the Undo toast, no dialog).

Inventory coverage: BM1 → masthead; BM2 → the grouped list; BM3 → the marginal note; BM4 → Remove, now with Undo; BM5 → states.

### H. Wiring

Wire `screens.updates`, `screens.collections`, `screens.collection`, `screens.history` and `screens.bookmarks` in `frontend/src/skins/cinematic/index.ts` and remove all five from `PENDING`. Every focus-on-arrival target is the page's `h1` (`tabIndex={-1}`). Every icon-only button carries `aria-label` and a tooltip.

### I. The re-estimate gate: `docs/redesign/proof/web-10/estimate.md`

`docs/redesign/stack-decision.md` §1: "Re-estimate after the first two clusters (primitives, then home and library) on both platforms. If the paired web + Flutter cost per cluster comes in more than 40 % over `stack-keep.md` §6, reopen the choice before Glass starts."

1. **Budget from `stack-keep.md` §6** (Claude-Code-days, CCD): Web Cinematic primitives 4.0 + home and library cluster 3.5 + Updates as one fifth of the 3.0 "Updates, downloads, OCR, stats, recommendations" row (0.6) = **8.1 CCD**; Flutter Cinematic 3.5 + 3.0 + 0.6 = **7.1 CCD**; paired **15.2 CCD**; the reopen threshold is 40 % over: web 11.34, Flutter 9.94, paired 21.28.
2. **Actuals for the web**: the steps web/04, web/05 (primitives) and web/08, web/09, web/10 (home and library). For each step, count the distinct calendar days with at least one commit of that step (1 CCD = one day on which a session worked that step): `git log --date=short --format='%ad %h %s' --grep='web-0[4589]:\|web-10:'` plus, for steps whose messages carry no `web-NN:` prefix, `git log --date=short --format='%ad %h %s' -- frontend/src/skins/cinematic/primitives frontend/src/skins/cinematic/motion.ts 'frontend/src/app/(preview)'` (primitives), `-- frontend/src/features/home frontend/src/skins/cinematic/screens/tonight` (web/08), `-- frontend/src/skins/cinematic/screens/library` (web/09), and `-- frontend/src/skins/cinematic/screens/{updates,collections,history,bookmarks}` (web/10). Also report active hours per step: the sum over commit clusters (commits less than 60 minutes apart) of last minus first commit plus 30 minutes.
3. **Flutter half**: read `docs/redesign/proof/mobile-10/estimate.md` if it exists (written by mobile/10). If it does, write the **paired verdict**. If it does not, write the web figures and the rule, and state that mobile/10 appends the paired verdict when it finishes (whichever of web/10 and mobile/10 finishes second writes the "Paired verdict" section in both files).
4. **Recommendation**: `PROCEED` when the paired actual is at most 21.28 CCD (or, without the Flutter half, the web actual is at most 11.34 CCD), otherwise `REOPEN` with the one-paragraph case (which rows ran over, why, and the stack-decision's cheapest switch point: "Expo for the phones, Next for the web", before Glass starts). Put the recommendation in bold on the first line of the file, then a table: step, days, active hours, budget share, over or under.
5. This file is a document only; do not change `stack-decision.md`.

## File layout

```
frontend/src/features/library/{smart-shelf,collection-order,history-pages}.ts (+ smart-shelf.test.ts, history-pages.test.ts)
frontend/src/features/bookmarks/note.ts (+ note.test.ts)
frontend/src/features/updates/grouping.ts (+ grouping.test.ts)
frontend/src/skins/cinematic/index.ts                         (five ScreenIds out of PENDING)
frontend/src/skins/cinematic/screens/updates/{UpdatesScreen,UpdatesNew,UpdatesFollowing,RecentChecks,ScheduleSheet}.tsx
frontend/src/skins/cinematic/screens/collections/{CollectionsScreen,CollectionPlate,CollectionScreen,ShelfDialog,AddSeriesPanel,RuleChips}.tsx
frontend/src/skins/cinematic/screens/history/{HistoryScreen,HistoryRow}.tsx
frontend/src/skins/cinematic/screens/bookmarks/{BookmarksScreen,MarginalNote}.tsx
frontend/src/app/(preview)/…                                   (gallery entries for new variants)
frontend/e2e/cinematic/web-10-hub.spec.ts
frontend/e2e/fixtures/{updates,collections,history,bookmarks}/*.json
docs/redesign/proof/web-10/{plan.md,estimate.md,*.png}
```

Skin code imports only `@/features/**` data files (never barrels that re-export components), `@/lib/**`, `@/skins/contract.generated` and its own folder; utilities only from §2.8 and §3.5.

## Acceptance criteria

- [ ] `updates`, `collections`, `collection`, `history`, `bookmarks` are out of `PENDING`; the completeness test passes; none of the four hub tabs shows a back arrow, and collection detail does.
- [ ] Updates: `Check now` shows the running segment, then "Checking 212 series…" after 400 ms; for an admin the deck counts "Checked N of M" live; a 409 shows "A check is already running."; NEW groups by day then series with typed folios on fresh notifications only; `Mark read` fades a group to `ink.45`; swipe left marks a group read on the phone frame without moving the hub pager.
- [ ] The admin aside renders only for admins and only from 1024 px (from 900 px in the 768–1023 frame, in columns 6–8); lists keep columns 1–8 for everyone.
- [ ] Collections: plates are 16:9 duotone mosaics with the name on the solid `scrim.foot`; `Recently created` orders by `created_at`; Custom order writes only changed `sort_order` values; `Alt+arrows` moves a plate with an announcement.
- [ ] Smart shelves: creating a shelf with *status is READING* and *new chapters ≥ 3* shows exactly the matching library series (checked against a fixture), updates live by Cut + Set when the rules change, and has no Add or Remove.
- [ ] The plate → header match cut runs 480 ms and back reverses it in 336 ms (checked in the motion-timings overlay); under reduced motion both are 200 ms cross-fades.
- [ ] Collection detail: Add series adds with the `ADDED` row state; Remove from shelf and Delete shelf both have the 1000 ms arm (a double click on the trigger never confirms); member Reorder calls `PUT /library/collections/{id}/series/order` with the full ordered list.
- [ ] History: day rules, the 56 px (desktop) and 40 px (phone) time margins, `Continue` and `Next │ CH n` with the busy state, `Load earlier` appends 50 rows with one 160 ms fade; the desktop aside shows "This week" stat blocks.
- [ ] Bookmarks: marginal notes with pull quotes for novels; editing a note saves on blur and on `mod+Enter`; a 409 shows the removed-elsewhere toast; Remove shows the 8 s Undo toast and Undo restores the bookmark.
- [ ] Every state listed in C10, D8, E6, F7, G7 renders at both sizes (screenshots).
- [ ] Reduced motion: letter reveals become 200 ms fades, typed headlines and folios show at once with no caret, Set becomes a 150 ms fade, the swipe release finishes with a 150 ms fade, programmatic scrolls jump.
- [ ] Keyboard (desktop): every control reachable in reading order with the double focus ring; the keys of C11, D9, E7, F8 and G8 work and appear in the `?` sheet.
- [ ] Hit targets: at least 44 × 44 px on the phone frame (8 px apart) and 32 × 32 px on the desktop fine pointer (measured by the e2e spec).
- [ ] `docs/redesign/proof/web-10/estimate.md` exists with the bold `PROCEED` or `REOPEN` first line and the per-step table.
- [ ] Nothing under `backend/` changed (section A is read only): `git show --stat --format= <hash>` of each of your commits lists no `backend/` path.
- [ ] Per skin: `smart-shelf.ts`, `collection-order.ts`, `history-pages.ts`, `note.ts` and `grouping.ts` import nothing from `src/skins/**`, so Glass's hub (web/32) reuses them (the smart-shelf evaluator is the single one both skins run, glass §8.18); the Glass skin's five entries stay in Glass's own `PENDING` set; the legacy screens are unchanged.
- [ ] Lint, typecheck, Vitest, build and the `design/` checks are green; Vitest totals at least the start-of-step totals with 0 failed.

## Verification

From `/srv/manhwamaniacs/dev/ManhwaManiacs`, one at a time, each after the RAM guard:

```
node design/build.mjs --check
node design/lint-utilities.mjs
cd frontend && npm run typecheck
cd frontend && npm run lint          # baseline: exit 0, 0 errors, 0 warnings
cd frontend && npm run test          # passed >= start-of-step count, 0 failed
cd frontend && npm run build         # baseline: exit 0
```

Nothing under `mobile/` or `backend/` changes (`git show --stat --format= <hash>` of each of your commits lists no `mobile/` or `backend/` path); `flutter analyze`, `flutter test` and the backend pytest (`cd backend && .venv/bin/python -m pytest -q --no-header`) are their own sessions'.

If any commit you made touches `mobile/` (check each of your commits with `git show --stat --format= <hash>`; other sessions commit `mobile/` on the same branch, so never judge by the branch diff), revert that part, then prove the baseline still holds with the baseline's own commands, one at a time after the RAM guard and never while a `next build` runs: `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze` (baseline: No issues found) and `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter test` (baseline: all 2012 tests passed).

Visual proof against the backend/00 dev stack (uvicorn 127.0.0.1:8010, `next dev` on port 3010; `backend/scripts/README-dev-stack.md`):

1. Route shots with `frontend/scripts/proof.mjs` (web/03): `node scripts/proof.mjs --step web-10 --skin cinematic --routes /updates,/library/collections,/library/history,/library/bookmarks --grid` writes `cinematic-<route>-*` at 1440 × 900 and 390 × 844 with their `-grid` copies into `docs/redesign/proof/web-10/` (`--skin cinematic` sets the `mm-skin-debug` cookie; without it the pre-flip default, legacy, would be captured). The e2e spec of step 2 saves every named shot below with `page.screenshot` into the same folder:
   - `updates-new-{1440x900,390x844}.png`, `updates-following-{1440x900,390x844}.png`, `updates-checking-1440x900.png` (admin, live deck), `updates-{loading,empty,offline,error,notices-off}-{1440x900,390x844}.png`
   - `collections-{1440x900,390x844}.png`, `collections-custom-order-1440x900.png`, `collections-new-shelf-smart-{1440x900,390x844}.png`, `collections-{loading,empty,offline,error}-{1440x900,390x844}.png`
   - `collection-{1440x900,390x844}.png`, `collection-smart-1440x900.png`, `collection-reorder-1440x900.png`, `collection-add-series-{1440x900,390x844}.png`, `collection-delete-dialog-1440x900.png`, `collection-{empty,nothing-matches,mode-mismatch,notfound}-1440x900.png`
   - `history-{1440x900,390x844}.png`, `history-by-chapter-1440x900.png`, `history-{loading,empty,offline,error}-{1440x900,390x844}.png`
   - `bookmarks-{1440x900,390x844}.png`, `bookmarks-wide-1920x1080.png` (two columns), `bookmarks-editing-1440x900.png`, `bookmarks-{loading,empty,offline,error}-{1440x900,390x844}.png`
   - `hub-pager-mid-swipe-390x844.png`
2. `frontend/e2e/cinematic/web-10-hub.spec.ts` drives the states with `page.route("**/api/updates/**", …)`, `"**/api/library/collections**"`, `"**/api/reader/history**"`, `"**/api/reader/bookmarks**"` fixtures and checks the arm delays, hit sizes, the smart-shelf membership and the member-order request. Run: `cd frontend && E2E_BASE_URL=http://127.0.0.1:3010 E2E_USERNAME=<demo user> E2E_PASSWORD=<demo password> npx playwright test e2e/cinematic/web-10-hub.spec.ts` (credentials from the dev-stack README, never committed). With `playwright-cli`, pass `-s=web-10`.
3. Motion-timings overlay (`mod+shift+m`): open a plate and go back; screenshot `collections-motion-timings-1440x900.png` with no `proof` rows.

## RAM guard

- Before every `npm run test`, `npm run build`, Playwright run or dev-stack start: `free -m`; if `available` on `Mem:` is under 1024, stop and report "RAM guard: N MB available".
- `pgrep -af "next build|vitest|flutter_tester|pytest"` first; never run two builds at once; wait for other sessions' builds and tests to finish.
- One heavy command at a time; no Gradle, Xcode or `flutter build`; no `npm install` (every package was pinned in web/01; if `npm ls @use-gesture/react motion @tanstack/react-query` reports one missing, stop).

## Git

- Branch `feat/vps-slim-source-native`; small commits, one per working step (smart-shelf evaluator; updates grouping; Updates; Collections; collection detail; History; Bookmarks; e2e and proof; the estimate), messages starting `web-10:`.
- Stage only your paths with explicit `git add <path>` (all under `frontend/` and `docs/redesign/`). Never `git add -A` or `git add .`; never commit secrets, demo credentials, `.claude/` or `.env` files.
- **No Claude or AI attribution anywhere** (no `Co-Authored-By`, no "Generated with" line, no AI author), even if your harness asks for it; the owner's `~/.claude/CLAUDE.md` forbids it.
- `npm run build` (after the RAM guard) before any push with frontend code; `git push origin feat/vps-slim-source-native:master` after each working step.

## Guardrails

- Never edit `backend/connectors/`. Never touch production containers or `/srv/manhwamaniacs/{app,data}`; the dev stack's database lives under `/srv/manhwamaniacs/dev/data/`.
- No changes under `backend/`, `mobile/` or `design/` (section A only reads the backend).
- Skin code never imports `frontend/src/components/**` or `frontend/src/features/*/components/**`, and never reproduces the legacy look.

## Report back

1. **Done**: A (the two backend/02 checks passed), B1–B5, C1–C12, D1–D9, E1–E7, F1–F8, G1–G8, H, I, with a one-line status each.
2. **Screenshots**: `docs/redesign/proof/web-10/` and the file list.
3. **Tests**: Vitest totals before and after; lint, typecheck and build; the e2e spec result.
4. **Estimate**: the bold recommendation line from `estimate.md` and the web actual against 8.1 CCD (and the paired figure against 15.2 CCD when available).
5. **Open issues**: ambiguities and the choices made, blocked items, conflicts with DESIGN.md.
6. **Commits**: the hashes pushed.

Next prompt file: `docs/redesign/prompts/web/11-cinematic-feature-and-book-pages.md`.
