# Web 09: Cinematic Library shelf and browse

## Goal

Build the Cinematic **Library** on the web client (`frontend/`), per `docs/redesign/cinematic/DESIGN.md` §8.9 and §8.9.1: the Library hub frame with its five contents tabs (`SHELF · UPDATES · COLLECTIONS · HISTORY · BOOKMARKS`, each its own route with no back arrow), the shelf at `/library` and `/library/browse` (one screen; browse opens with the toolbar, and on phones opens the Filters sheet once), the wall in `WALL │ COMPACT │ LIST` densities on `@tanstack/react-virtual`, every sort including `Recently read`, `Most unread` and `NEW ONLY` evaluated on the server, status, favourites, new-only and tag filters with the tag sheet, favourites and notify on posters, manual order, bulk select with every bulk action, the book list for novels mode, the `featureByFollow` resolver at `/library/:followedId`, keys `1`–`7`, and the offline and 18+ gate states, for desktop web and mobile web. When you finish, `library` and `featureByFollow` leave the Cinematic `PENDING` set. `docs/redesign/prompts/mobile/09-cinematic-library-shelf-browse.md` runs the same cluster on Flutter in parallel; do not touch `mobile/`.

## Read first

DESIGN.md is binding; where this prompt and DESIGN.md disagree, DESIGN.md wins and you report the conflict.

- `docs/redesign/cinematic/DESIGN.md`:
  - §2.1.1 (raised stock), §2.1.4 (badges on art), §2.2 (grid), §2.8 and §3.5 (the only allowed names), §3.3 (reflow at text scale 1.3, 1.5, 2.0).
  - §4.2–§4.8 (Cut, Set, Rule slide, the match cut, Dip, stagger rules §4.6, reduced motion §4.8).
  - §5 (`select`, `favorite`, `follow.add`, `follow.remove`, `longpress.open`, `delete.confirm`, `undo`, `download.start`, `refresh.arm`, `nav.change`), §6.
  - §7 intro, §7.1, §7.2, §7.3, §7.4 (`compact`), §7.5 (slug lines, removable tokens, the segmented control), §7.6 (Cutting), §7.7 (every poster state: corners, hover icons, select mode, manual order, favourited at rest), §7.8, §7.9 (sheets; column panels on desktop), §7.10 (the arm delay), §7.11, §7.12 (contents tabs), §7.16 (rows, swipe actions, drag to reorder), §7.17, §7.18, §7.19 (and the reading-status vocabulary), §7.21, §7.22 (menus, Quick look, Move items), §7.23, §7.24 (local copies follow the gate), §7.26, §7.27, §7.28, §7.29 (content-mode chip, pull to reprint, select-mode bar, banner strips, spoken folios).
  - §8.0.1–§8.0.9 (frames; the Library hub as branch 1 with five routes; content mode; tablet row for Library), §8.0.10.
  - **§8.9 and §8.9.1, entire.**
  - §8.17 "Mark read and Mark unread" (the calls the bulk bar uses).
  - §10.1 (masthead reveal: `trigger="mount"`), §11 (Library, rows, drag-to-reorder and hub-pager rows), §14, §15.6, §15.7.
- `docs/redesign/inventory/web.md` §7.1 (LS1–LS12), §7.2 (LB1–LB26, BA1–BA10), §10.1 (NS1–NS6), §19.3 (K26 density key), §19.5.
- `docs/redesign/inventory/capabilities.md` §7 (library endpoints and `read_state`), §12 (tags).
- `docs/redesign/inventory/00-decisions.md`, `docs/redesign/stack-decision.md` §2.2 and §2.6, `docs/redesign/00-baseline.md`.
- `docs/redesign/glass/DESIGN.md` §15.6 (the Library query extras Glass shares: `tab`, `reading_status`, `tags`).

## Before you start

1. Work in `/srv/manhwamaniacs/dev/ManhwaManiacs` on branch `feat/vps-slim-source-native`. Run `git status --porcelain` and note files other sessions have modified; never stage them.
2. Dependencies: `docs/redesign/prompts/web/08-cinematic-tonight.md` and `docs/redesign/prompts/backend/02-library-series-ocr-extensions.md`. Check:
   - `ls frontend/src/skins/cinematic/parts/quick-look-actions.ts frontend/src/skins/cinematic/parts/AddToShelfSheet.tsx frontend/src/features/home/continue-hidden.ts` exist (web/08).
   - `grep -n "new_only\|tag_ids\|last_read_at\|new_count" backend/routes/library.py` finds the new list parameters, `grep -n '"/tags/{tag_id}"' backend/routes/library.py` finds a `PATCH`, and `grep -n "manual" backend/routes/reader.py` finds `manual: true` on the progress batch (backend/02).
   If any check fails, stop and report the missing dependency.
3. Inventory what exists and reuse it (never re-implement a primitive inside a screen): `ls frontend/src/skins/cinematic/primitives frontend/src/skins/cinematic/parts` and `grep -n "^export" frontend/src/skins/cinematic/motion.ts frontend/src/features/library/*.ts frontend/src/lib/keyboard/index.ts`. The data layer you will use already exists: `features/library/hooks.ts` (`useSeriesList`, `useAllFollowedSeries`, `useContinueReading`, `usePatchSeries`, `useToggleFavorite`, `useFollow`, `useUnfollow`, `useBulkSeriesAction`, `useCollections`, `useAddSeriesToCollection`), `features/library/bulk.ts` (`runBulk`, `BULK_CONCURRENCY = 4`, `summarizeBulkOutcome`), `features/library/selection.ts` (`toggleSelection`, `extendSelection`, `selectAll`, `clearSelection`, `selectionRange`), `features/library/density.ts` (the stored density, key `manhwamaniacs:library-density`), `features/library/url-state.ts`, `features/library/read-state.ts`, `features/novels/shelf.ts`, `lib/keyboard` (`useShortcut`, `useGridNavigation`), `features/offline/mature-filter.ts` (web/07). If a primitive lacks a variant, add it to the primitive's file and to the primitives gallery under `frontend/src/app/(preview)/`.
4. Record the Vitest baseline before your first edit (RAM guard below): `cd frontend && npm run test 2>&1 | tail -5`.

## Skills to invoke

1. `superpowers:writing-plans` before any code; save the plan as `docs/redesign/proof/web-09/plan.md`.
2. `superpowers:subagent-driven-development` (or `superpowers:executing-plans` inline). Scope-lock every subagent prompt to named files and verify with `git status` and `git diff`, never with the agent's report.
3. `frontend-design:frontend-design`, `impeccable:impeccable` and `taste-skill:taste-skill` for design-quality review of each finished part, always against DESIGN.md (they never change a token, duration, copy string or layout rule).
4. `superpowers:verification-before-completion` before claiming done.

## Scope

Cinematic only; Glass's Library is web/32. Section numbers refer to `docs/redesign/cinematic/DESIGN.md`.

### A. Shared data layer additions (skin-neutral, `frontend/src/features/`)

No JSX, no import from `src/skins/**`, a Vitest `*.test.ts` beside each file that holds logic.

1. `features/library/shelf-query.ts`: the Cinematic URL contract for the shelf (§8.0.3 `?status&sort&fav&view&q&select`, plus `new` and `tags`): `parseShelfQuery(searchParams)` and `shelfQueryToSearchParams(query)` for `status` = `all | reading | unread | completed | on_hold | plan_to_read | dropped`, `sort` = `updated | added | read | title | unread | manual`, `fav=1`, `new=1`, `tags=1,4`, `view=wall | compact | list`, `q`, `select=1`; and `shelfQueryToListParams(query)` mapping to `GET /library/series`: `updated` → `sort=recently_updated`, `added` → `recently_added`, `read` → `-last_read_at`, `title` → `title`, `unread` → `-new_count`, `manual` → `sort_order`; `status` → `reading_status` (omitted for `all`); `fav` → `is_favorite=true`; `new` → `new_only=true`; `tags` → `tag_ids=1,4`; `q` → `search`; always `page=1&per_page=200`. The legacy parser in `url-state.ts` stays untouched for the legacy skin until the flip. Test: round trips, defaults, unknown values fall back to defaults.
2. `features/library/tags.ts`: `useTags()` (`GET /library/tags`), `useCreateTag()` (`POST /library/tags {name, category: "custom"}`), `useRenameTag()` (`PATCH /library/tags/{id} {name}`), `useDeleteTag()` (`DELETE /library/tags/{id}`), `useTagSeries()` / `useUntagSeries()` (`POST` / `DELETE /library/series-tags {source_id, series_key, tag_id}`), each invalidating the tags list and the library series queries.
3. `features/library/mark-read.ts`: the §8.17 calls, shared by the bulk bar here and by web/11: `markChaptersRead(rows)` → `POST /reader/progress/batch` with rows `{source_id, series_key, chapter_key, chapter_number, last_page: max(page_count, 1), page_count: max(page_count, 1), scroll_offset_px: 0, is_completed: true, time_spent_seconds: 0, manual: true}` in chunks of 200; `markChaptersUnread(ref, chapterKeys)` → `DELETE /reader/progress {source_id, series_key, chapter_keys}` in chunks of 200 (204). `manual: true` rows never move statistics or streaks. Test: chunking, row shape.
4. `features/library/shelf-counts.ts`: `shelfCounts(rows)` → `{total, withNew, favourites, byStatus}` over the full followed list (from `useAllFollowedSeries()`), for the masthead deck and the slug-line counts. Test included.
5. `features/library/manual-order.ts`: `reorder(list, from, to)` and `changedSortOrders(before, after)` → the minimal `[{id, sort_order}]` patch list after renumbering 0…n − 1. Test included.

### B. The Library hub frame: `frontend/src/skins/cinematic/screens/library/LibraryHub.tsx`

Shared by the five hub screens (`library` here; `updates`, `collections`, `history`, `bookmarks` in web/10). Props: `tab` (`shelf | updates | collections | history | bookmarks`), `masthead` (`{kicker, title, deck}`), `children`.

1. **Masthead block** (§7.27): kicker (`type.kicker`, e.g. `No. 02 — YOUR SHELF`) → the title in `type.masthead` (Bodoni Moda Roman opsz 96 wght 800, fluid `clamp(2.5rem, 1.582rem + 3.92vw, 5.5rem)`, tracking −0.035em; 40/40 on phones) as `SetHeading` with `trigger="mount"`, `as="h1"`, `id="library.<tab>.masthead"` (once per session) → deck (`type.deck` `ink.60`, one line of live facts) → `rule.oxford` on desktop (3 px `ink.100` + 2 px gap + 1 px `ink.100`) or `rule.heavy` on phones (3 px `ink.100`), drawn after the letters land (Rule draw 480 ms `ease.settle`). Bottom margin 48 px desktop, 32 px phone. The profile's mood grade (§2.1.6) sits behind the top 30 vh; the masthead's kicker and deck render `ink.45` roles as `ink.60` on it.
2. **Hub tabs** (§7.12 contents tabs): `01 SHELF · 02 UPDATES ³ · 03 COLLECTIONS · 04 HISTORY · 05 BOOKMARKS`, each label a `Link` with `replace` to its route (`/library`, `/updates`, `/library/collections`, `/library/history`, `/library/bookmarks`, from the typed route builders in `frontend/src/skins/contract.generated.ts`); folios in Plex Mono `ink.45`; labels `type.nav` (desktop size 13/16, +0.12em, uppercase); the Updates count as a raised superscript folio (`font-size: 0.72em; vertical-align: 0.5em`, spoken "Updates, 3" through `folioLabel()`) from `useUnreadNotificationCount()` (already computed after the 18+ gate on the server); the row is 48 px with a 1 px `rule.1` under it, sticky under the running head (`top` = the running head's height, `z.sticky` 10), with `scroll-padding-block` so focus rings are never covered. The active tab is `ink.100` with a 2 px `spot` underline that slides and stretches to the new tab over 320 ms `ease.settle` (Rule slide; reduced motion: the rule fades out under the old tab and in under the new one over 150 ms `dur.reduced`), `aria-current="page"`. States: default `ink.45`; hover `ink.100`; pressed 1 px impression; focus ring; loading (count `–`); error (count replaced by `!` in `proof`). No back arrow on any of the five tabs. Switching tabs is a **Cut** with the new content running **Set**; haptic `select`.
3. **Phone hub pager** (below 768 px; §11 "Horizontal swipe | Contents tabs"; mobile web uses a scroll-snap pager): the masthead and the tab row sit above a horizontal scroll container (`overflow-x: auto; scroll-snap-type: x mandatory; overscroll-behavior-x: contain; scrollbar-width: none`) holding three panes: the previous tab's galley proof (masthead-free: 6 greeked rows), the current route's content, the next tab's galley proof (omitted at the ends). The container starts scrolled to the current pane with no animation. The tab rule's x and width lerp with `scrollLeft / paneWidth` while the finger moves. When scrolling settles on a neighbour pane (`scrollend`, with a 120 ms `scroll` debounce where `scrollend` is missing), call `router.replace(neighbourRoute, { scroll: false })`, fire haptic `select`, and let the new route render its content in the centre pane by Cut + Set. Rows with swipe actions set `touch-action: pan-y` so a drag that starts on them never moves the pager, and nested tabs inside a hub panel switch by tap only (§11 precedence). Reduced motion: the pager still follows the finger (finger-tracked motion is allowed) and settles with a jump.
4. Desktop and tablet frames show the same masthead and tab row without the pager. The sidebar item that lights and the breadcrumb follow §7.15's table (web/06's shell already maps routes).

### C. The shelf: `frontend/src/skins/cinematic/screens/library/LibraryScreen.tsx` (ScreenId `library`)

Wire `screens.library` to it and remove `library` from `PENDING`. It serves `/library` and `/library/browse` (read `usePathname()`); `document.title` is "Library · ManhwaManiacs". Hierarchy: masthead → hub tabs → toolbar → Continue cuttings → the wall.

1. **Masthead**: kicker `No. 02 — YOUR SHELF`, title "Library", deck "212 series · 14 with new chapters · 3 favourites" from `shelfCounts()` (novels mode: "38 books on your shelf"); parts with a zero count are dropped ("212 series").
2. **Toolbar, desktop** (one line, wrapping at 1024 px):
   - Status slug line, single-select (§7.5: Archivo `wdth` 75 `wght` 600 12/16 uppercase +0.10em; separators `·` in `ink.30` with 12 px spacing; hit box `max(label width + 24, 44)` × 44 on coarse pointers, 32 px tall on the fine pointer; default `ink.45`, hover `ink.100` 160 ms, selected `ink.100` with a 2 px `spot` underline 4 px below the baseline that slides between labels over 320 ms `ease.settle`): `ALL · READING · NOT STARTED · DONE · ON HOLD · PLAN TO READ · DROPPED` (the §7.19 vocabulary: `unread` → `NOT STARTED`, `completed` → `DONE`, `plan_to_read` → `PLAN TO READ`), each with its raised count folio (`READING¹²`; count `–` while loading). `role="radiogroup"`.
   - `★ FAVOURITES` and `NEW ONLY` multi-select toggles (`aria-pressed`, a fixed label; selected: `ink.100` + the underline drawn over 240 ms).
   - `TAGS ▾`: a Base UI menu of the profile's own tags as a checkbox checklist (items 40 px, leading `check` when checked); series that carry any selected tag match (`tag_ids`); the menu's footer item `Manage tags…` opens the tag sheet (G); the trigger is hidden when the profile has no tags. Active tags show as removable tokens after the slug line (label + `x` 12 inside a 1 px `rule.2` square box, height 28, hit box 32 px tall on the fine pointer, 44 on coarse).
   - A `quiet` `Clear filters` at the end of the status slug line whenever a status other than `ALL`, `★ FAVOURITES`, `NEW ONLY`, a tag or a search is active.
   - Right side: the `compact` search field ("Search your shelf", leading `magnifying-glass` 20 Regular, height 44, underline style; 300 ms debounce into `?q`; `/` focuses it; `Esc` clears only the search, then blurs), the Sort menu (`Recently updated` (default), `Recently added`, `Recently read`, `Title A–Z`, `Most unread`, `Manual order`; a `arrows-down-up` trigger labelled with the current sort), the density segmented control `WALL │ COMPACT │ LIST` (manga mode only; §7.5 segmented: labels divided by 1 px vertical `rule.2` rules inside a 1 px `rule.2` frame, 40 px tall, the active segment `ink.100` with a 2 px `spot` underline sliding 320 ms `ease.settle`), and `Select` (`quiet` with the `check-square-offset` icon).
   - Every sort and filter runs on the server over the whole library through `shelfQueryToListParams()` (never client-side over the 200-row page). The URL is the state (`?status&sort&fav&new&tags&view&q&select`), written with `router.replace` so filtering does not stack history entries.
   - Density: `?view` wins; otherwise the stored per-profile density (`features/library/density.ts`, key `manhwamaniacs:library-density`: `comfortable` → WALL, `compact` → COMPACT, `list` → LIST); changing density writes the store.
3. **Toolbar, phones** (below 768 px): the content-mode chip `MANGA ▾` sits in the running head (the shell's §7.29 chip, shown only when novels are enabled). The toolbar collapses to: the status slug line (horizontal scroll, a 24 px fade at the trailing edge) + a `Filters` quiet button showing the active-filter count as a superscript folio (`Filters ⁽²⁾`, spoken "Filters, 2") + a search icon button that expands the compact field in place + `Select`. `Filters` opens a sheet (§7.9: `paper.2`, 1 px `rule.2` top edge, grabber 32 × 3 `ink.30`, header 56 px with kicker `FILTERS` over the title "Your shelf" and a `quiet` `Done`; barrier `rgba(0,0,0,0.78)`; Rise 360 ms `ease.settle`, out 240 ms `ease.lift`; drag release `spring.sheet` 480 ms bounce 0; dismiss below 30 % of its height or on a fling faster than 800 px/s) holding: `Favourites` and `New only` switches (§7.21 slug switches, 44 × 24), `SORT` as a radio list of the six sorts, `DENSITY` as the segmented control, `READING STATUS` as the slug line, and a `TAGS` section (a checkbox checklist, hidden when there are no tags, whose last row `Manage tags…` opens the tag sheet). Active tags show as removable tokens after the status slug line. `/library/browse` on phones opens this sheet once on mount (mark it with `history.replaceState({...history.state, mmBrowseSheet: 1})`, so back navigation does not reopen it).
4. **Continue reading** (only with no filter and no search): the §7.8 header row (folio `01`, H3 "Continue reading" as `SetHeading` `trigger="inView"` `as="h2"` `id="library.continue"`), then cuttings (§7.6: 3:2 crop at `object-position: 50% 22%`, 2 px `spot` progress rule flush on the image bottom, `type.title` 1 line, folio caption `CH 142 · 63%` or `NEXT · CH 143` when `page_count == 0`, nudge badges `3 NEW`, `ALMOST DONE`, `PAUSED 21 D`) from `GET /library/continue-reading?limit=12` (its rows carry `recap`, §9.1.5) with `filterHidden()` from `features/home/continue-hidden.ts` applied. Desktop: a rail with 4 cuttings visible (5 at wide, 6 at cinema), paddles on hover (48 px, over `scrim.rail-end`, paging by `visible − 1` over 560 ms `ease.turn`). Phones: an Embla pager of cuttings at 86 % width (the Tonight "Also in this issue" geometry: `align: "center"`, viewport spanning the full screen width, slides `flex: 0 0 86%` with `padding-inline: 6px`), with the folio `1 / 12` between two `ruled` arrow buttons (44 px hit) under it. A cutting's `Continue` and tap enter the reader by **Dip** (160 / 40 / 240 ms; Library cuttings never use the Column wipe, §8.14.2). Quick look uses the cutting actions of `parts/quick-look-actions.ts` (Open series, Continue, Previously on when `recap.available`, Mark read, Remove from row).
5. **The wall** (manga mode), virtualised by rows with `@tanstack/react-virtual` `useWindowVirtualizer` (row count = `ceil(n / perRow)`, estimate = poster height + caption + row gap, overscan 3 rows):
   - Per row: WALL 6 on desktop (1024–1439), 8 at wide and cinema; COMPACT 8 on desktop, 12 at wide and cinema; 768–1023 px and 600–767 px: WALL 5, COMPACT 7; phones below 600 px: WALL 3, COMPACT 4. Column gap = the rail gaps (phone 8, tablet 12, desktop 12, wide 12, cinema 16); row gap 24 px (16 on phones); 8 px padding around the wall for focus halos.
   - WALL posters (§7.7): 2:3, radius 0, `paper.1` placeholder with the inner hairline, snapped cover widths (96, 160, 240, 360, 480, 720 ≥ rendered width × DPR); caption below: `type.title` 1 line (2 at text scale ≥ 1.3), then the folio caption in `ink.45`: `NOT STARTED` (not started), `CH 142 · 3 NEW` (`new_count > 0`), `CAUGHT UP` (started, `new_count == 0` and the latest chapter completed), otherwise `CH 12 OF 40`; favourited at rest: a 12 px `star` Fill in `spot` leads the caption (`★ CH 142 · 3 NEW`) and "Favourite" is appended to the poster's `aria-label`. Badges top-left in a 4 px inset stack, each on its `#000000` fill: `NEW` / `3 NEW` / `99+ NEW` (fill `spot`, `#000` text), the reading-status badge (`READING`, `ON HOLD`, `PLAN`, `DROPPED`, `DONE`: 1 px `ink.100` outline, `ink.100` text; only on this wall), the 16 px `18` certificate only when the gate is open and the series resolves mature, `SAVED` (1 px `set` outline) when the service-worker index holds a chapter of it.
   - Corners (each control keeps its corner in every state): badges top-left, the select square top-right, hover icons bottom-right, the drag handle bottom-left.
   - Hover (desktop, not in select mode): image scales 1.04 inside the fixed frame, 2 px `ink.100` inside outline, art light `0 0 48px -16px` in `ambient.duo` at 60 %, caption title underlines, siblings dim to `brightness(0.55) saturate(0.8)` (200 ms `dur.clip`, sibling dim 280 ms `dur.dim`); Favourite (`star`) and Notify (`bell-ringing`) appear as `on-art` icon buttons (40 px square, `color.onart` fill `rgba(0,0,0,0.64)`, glyph 20 Regular `ink.100`, 44 px hit on coarse pointers) at the bottom-right 4 px inset, Notify 8 px left of Favourite, tooltips "Favourite  F" and "Notify"; the empty 24 px select square (1 px `ink.100` outline on `color.onart`) appears at the top-right, and clicking it enters select mode with that poster selected (LB14). Favourite toggles `PATCH /library/series/{id} {is_favorite}` (haptic `favorite`; selected: Fill glyph + 2 px `spot` rule 4 px under the square); Notify toggles `{notify}`.
   - Pressed: scale 0.98 (80 ms `ease.set`, back 160 ms `ease.settle`); reduced motion: no scale, a 2 px `ink.100` inside outline while pressed. Focus: the double ring with the inset hairline (`box-shadow: inset 0 0 0 1px var(--mm-color-hairline-art), 0 0 0 6px #000` + the 2 px outline at 2 px offset) plus the hover treatment. Loading: flicker plate with a title card (Bodoni Moda Italic 14/16 `ink.45` bottom-left, 8 px inset). Image error: plate + title card + 16 px `image-broken` labelled "Cover didn't load", Quick look offers `Retry cover`. Rack focus on first decode, at most 12 images racking at once, the rest Develop.
   - Tap or click opens the series at `/library/{followedId}` (the `featureByFollow` route) by the **match cut** (`<ViewTransition name={coverTransitionName(source_id, series_key)} share="mm-match-cut">`, 480 ms `ease.turn`; back reverses in 336 ms).
   - COMPACT (every width): no caption; the title in `aria-label` and, on desktop, a tooltip after 500 ms; no hover icons; only the `NEW` badge.
   - LIST, desktop: 72 px rows (§7.16 standard row states: 1 px `rule.1` dividers; hover a 2 px `ink.100` bar on the left edge with text `ink.100` in 120 ms; pressed `paper.3`; focus ring inset 2 px; selected `paper.3` + 2 px `spot` left bar) with a 48 × 72 cover, then columns: title (`type.title`), reading-status badge, progress folio `CH 12 OF 40`, new count (`3 NEW` badge or nothing), last read (`2 H AGO` from `last_read_at`, `—` when absent, spoken through `folioLabel()`), the favourite star and notify bell as `bare` icon buttons (44 px hit).
   - LIST, phones: 72 px rows: 48 × 72 cover, the title (`type.title`, 2 lines) over the folio caption `CH 12 OF 40 · 3 NEW`, the reading-status badge at the trailing edge; favourite, notify and last read are desktop-only (Favourite and Notify stay in Quick look).
   - **Filter changes are Cuts** (the signature moment): the wall swaps instantly and the new posters run **Set** in reading order (fade 0 → 1, rise 8 px → 0 over 320 ms `ease.settle`; grid stagger +32 ms per item, +64 ms per row, capped at 480 ms). Refetches and pull-to-reprint results use one 160 ms fade for the whole block; returning through back never replays the stagger.
   - Overflow note when the library holds more than 200: a caption line under the toolbar "Showing the first 200 of 212 — narrow it with search or a filter."
6. **Manual order** (`Manual order` sort, status `ALL`, no other filter and no search; otherwise the handles are absent and the Sort menu item shows the caption "Clear filters to reorder."): posters show a 40 px `on-art` `dots-six-vertical` handle at the bottom-left on hover (always visible on coarse pointers). WALL and COMPACT: drag the handle with `@use-gesture/react` 10.3.1 `useDrag`; the lifted poster rises 1 px and gains a 1 px `ink.100` outline (no shadow); the insertion index is computed from the pointer over the grid geometry; siblings shift through Motion `layout` over 240 ms `ease.set`; drop fires haptic `select`. LIST: Motion 13 `Reorder.Group axis="y"` with the handle as the drag control. On drop, send `PATCH /library/series/{id} {sort_order}` for every row `changedSortOrders()` returns (concurrency 4, optimistic; on failure revert and toast "Couldn't save the order."). Keyboard: `Alt+←/→/↑/↓` (wall) and `Alt+↑/↓` (list) move the focused poster; every move is announced in a polite live region ("Solo Leveling moved to position 3 of 12"). Every poster's menu (trailing `dots-three` in LIST, Quick look, right-click) gains `Move up`, `Move down`, `Move to top`, `Move to bottom`, disabled at the ends (§7.22 Move items).
7. **Card menus**: long-press 450 ms (phones; the poster dims to 70 % for 120 ms, then Quick look rises with the poster match-cut into its 96 px header) or right-click (desktop, Base UI `ContextMenu` at the pointer), `Shift+F10` or the context-menu key, and in LIST the trailing `dots-three`: Open, Continue, Favourite, Status ▸ (a radio submenu of the six statuses), Notify, Add to collection (`parts/AddToShelfSheet.tsx`), Download next 5, Remove from library (commits at once; toast "Removed {title}. Your reading progress is kept." with `Undo`, held 8000 ms `dur.hold.toast.action`, which re-follows and restores favourite, status, notify, `mature_override` and position), plus the Move items in Manual order. Haptic `longpress.open` on open (Android Chrome `navigator.vibrate([12])`). `Recommend to…` is added by web/22.
8. **Select mode** (LB14, LB18, BA1–BA10): `Select` or `x` enters it (and `?select=1`); tap toggles; Shift-click selects a range (`extendSelection`); `mod+a` selects the visible posters; `Space` toggles the focused poster. Unselected posters show the empty 24 px select square; selected: a 24 px `ink.100` check square with a `#000` check (fill 120 ms `dur.snap`), a 2 px `spot` inset frame and the image at `brightness(0.7)`; hover icons hidden. The **select-mode bar** (§7.29: `paper.2` with a 1 px `rule.2` top, its root `data-stock="raised"`) sits under the running head on desktop (sticky, `z.sticky`) and at the bottom above the thumb index on phones: `12 SELECTED` (folio), `Select all 40`, then `quiet` buttons with icons: Favourite (`star`), Unfavourite, Mark read, Mark unread, Set status ▸, Add to collection, Download next 5, Unfollow (in `proof`), and `Done`.
   - Favourite / Unfavourite / Set status: `PATCH /library/series/{id}` per row.
   - Mark read: for each series, `GET /library/series/{id}` for `known_chapters`, then `markChaptersRead()` for every chapter not completed; Mark unread: `markChaptersUnread()` for every known chapter. Toasts "Marked 42 chapters read." / "Marked 12 series unread." with `Undo` (Mark read's Undo deletes only the keys that were not completed before; Mark unread's Undo re-posts the deleted rows, kept in memory until the toast closes). Offline: both are disabled with the tooltip "Needs a connection."
   - Add to collection: one `AddToShelfSheet` applying the chosen shelves to every selected series.
   - Download next 5: for each series, the next five unread chapters through the `features/offline` download queue (haptic `download.start` once).
   - Unfollow: a dialog first (§7.10: `paper.3`, 1 px `ink.30` border, max 560, Insert in 320 ms with the barrier in 200 ms): title "Unfollow 12 series?", body "Your reading progress is kept. You can follow them again from any series page.", actions `Cancel` (`quiet`, live from the first frame, initial focus) and `Unfollow 12` (filled `proof` with `#000` text), disabled for 1000 ms (`dur.arm`) while a 2 px `proof` rule fills under it left to right (`ease.linear`; reduced motion: the rule appears full at 1000 ms), then a polite live region says "Ready"; haptic `delete.confirm` on confirm.
   - Runs go through `runBulk()` with concurrency 4; the bar shows `4 OF 12 · 1 FAILED` + a determinate 2 px rule (`spot` on `rule.1`, width 240 ms `ease.set`) + `Stop`; then a result line (`summarizeBulkOutcome()` wording) with `Dismiss` and, for Unfollow, `Undo` (re-follows with the saved status, favourite, notify, override and position).
   - `Esc` or `Done` leaves select mode and discards the selection.
9. **Novels mode**: the wall becomes the **book list** (§8.9.1): rows 112 px on desktop in two columns with a 1 px `rule.1` column rule, one column on phones. Each row: a 56 × 84 plate (square-cornered, 1 px `rule.2` border; the title's first grapheme in Bodoni Moda Roman wght 800 `ink.60` on `paper.1` when there is no cover) → the title in Bodoni Moda Italic 20 → byline "by {author}" (`type.body.italic` `ink.60`; the line is dropped when the author is unknown) → credits `412 CHAPTERS · ONGOING · NOVELARCHIVE` (`type.credit`) → blurb (Newsreader 15, 2 lines, `ink.60`, from `shelfBlurb()`) → note (`42% · CH 212` in a `spot` folio, or the reading status). Select mode adds a leading 20 px checkbox (§7.21). Row states as §7.16. Rows open `/library/{followedId}` (the book page) by the match cut of the plate. Covers NS1–NS6.
10. **Pull to reprint** (phones; §7.29) and `r` refetch the shelf, the counts and the Continue rows.
11. **States** (§8.9 States), each with a typed notice headline (§7.23: 3 px `rule.heavy` drawn on entrance, kicker, headline typed at 50 ms per character as `h2`, deck `type.deck` `ink.60` max 48ch, up to two actions; 6 desktop columns, 4 on phones):
    - Loading: the masthead live (kicker, title and deck bars), then 12 (WALL), 24 (COMPACT) or 8 (LIST) flicker plates or greeked rows (Flicker 1400 ms half-period, 0.55 ↔ 1, 60 ms phase offsets; only after 120 ms of waiting).
    - Empty: kicker `EMPTY SHELF`, headline "Nothing on your shelf yet.", deck "Follow a series from Discover and it lands here.", primary `Find something` (`/search`). Novels mode: headline "No books on your shelf yet.", deck "Add a book from a novel source and it lands here."
    - Filtered empty: kicker `NOTHING MATCHES`, headline "No series match these filters.", primary `Clear filters`.
    - Search empty: kicker `NOTHING MATCHES`, headline "Nothing on your shelf matches that.", deck "Try another title, or search every source.", primary `Search every source` (`/search?q=`), quiet `Clear search`.
    - Offline: the offline edition shows only series with chapters saved on this device: the saved series of the service-worker download index (`useOfflineState()` from `features/offline/hooks.ts`; each saved record carries `sourceId`, `seriesKey`, `seriesTitle` and its cover, and web/07's worker already omits mature records while the gate is closed), joined with the followed rows React Query still holds in memory for status and progress when present, every row passed through `filterMature()` from `features/offline/mature-filter.ts` as web/07 requires. The web has no offline follow cache (that store is the app's, `capabilities.md`); do not add one. Show it under a banner strip (§7.29: `paper.0` with a 2 px left rule, kicker `OFFLINE EDITION`, "Only series saved on this device are shown." + `Go to Downloads`). Filters, sorts, favourite, notify, manual order and select mode are disabled with the tooltip "Needs a connection." Nothing on the device is saved: kicker `OFFLINE EDITION`, headline "Your shelf needs a connection.", deck "Saved chapters still open from Downloads.", primary `Go to Downloads`.
    - Error: kicker `CORRECTION` (`proof`), headline "Your shelf didn't load.", deck "The server didn't answer. Saved chapters still open.", primary `Try again`.
    - Page-load error after data: a caption line above the wall in `proof` "Couldn't refresh your shelf." with a `quiet` `Retry`; the wall that loaded stays.
    - 18+ gate: gated series are absent everywhere (wall, counts, Continue, tag counts); the certificate badge appears only with the gate open. A gate change invalidates the library queries (web/07's list) and re-enters the skeleton.
12. **Keys (web)** through `useShortcut` (group "Library"; single-key setting respected; never while typing; `1`–`7` are never delivered while the `g` sequence is armed): `/` search; `h j k l` and the arrows move in the wall (`useGridNavigation`, `data-grid-item`), `Home`/`End`; `Enter` open; `x` select mode; `Space` toggles the focused poster in select mode (outside select mode, `Space` does nothing on the wall); `f` favourite focused; `1`–`7` status filters in slug-line order (`ALL`, `READING`, `NOT STARTED`, `DONE`, `ON HOLD`, `PLAN TO READ`, `DROPPED`); `s` cycles sort; `v` cycles density (manga mode); `mod+a` select all visible (select mode); `r` reprint; `Alt+arrows` move in Manual order. All appear in the `?` sheet.
13. **Focus and landmarks**: on arrival focus moves to the `h1` (the masthead title, `tabIndex={-1}`); the wall is one landmark region `aria-label="Your shelf"` with the posters as grid items; the select-mode bar is a `toolbar` with `aria-label="Selection"`.
14. **Transitions**: in by Cut (hub tab, thumb index) or Dip (desktop sidebar); out by the match cut to the feature or book page, and by Dip into the reader from cuttings.

### D. `featureByFollow`: `frontend/src/skins/cinematic/screens/library/FeatureByFollow.tsx`

Wire `screens.featureByFollow` to it and remove `featureByFollow` from `PENDING`. It resolves `/library/:followedId` with `useSeries(followedId)` and renders the series page **in place** (no redirect, no flash): `<FeatureView sourceId={row.source_id} seriesKey={row.series_key} followedId={row.id} />` from `frontend/src/skins/cinematic/screens/feature/FeatureView.tsx`. Create that file in this step as the resolution target: until web/11 fills it, it renders the skin-neutral pending screen from `frontend/src/skins/pending.tsx` for the `feature` ScreenId (web/11 replaces its body and keeps the props). States of the resolver: loading → the feature galley (a spread plate at `clamp(520px, 64vh, 760px)` flickering, three title bars at `type.headline` height, 8 greeked chapter rows); `series_not_found`, 404 or a gate-hidden series → the §8.0.10 notice (kicker `NOT IN THIS ISSUE`, typed `h1` "This series isn't available here any more.", deck "It may have been removed from its source.", primary `Back to Tonight`, quiet `Search for it` → `/search?q={title}` when the title is known); other errors → `CORRECTION` "Couldn't load this series." with `Try again` and `Back to library`. Every static `/library/...` route keeps winning over `/library/:followedId` (check the thin route files from web/00 still resolve `/library/history`, `/library/bookmarks`, `/library/collections`, `/library/browse`, `/library/statistics`, `/library/recommendations` to their own screens).

### E. Parts reused later

- `frontend/src/skins/cinematic/parts/LibraryPoster.tsx`: the Library wall poster (every state above) used again by web/10's collection member wall.
- `frontend/src/skins/cinematic/parts/BookListRow.tsx`: the §8.9.1 row, used again by web/10 and web/16.
- `frontend/src/skins/cinematic/parts/SelectModeBar.tsx` (if web/05 did not build the §7.29 bar as a primitive; check first).
- `frontend/src/skins/cinematic/parts/TagSheet.tsx` (G).

### F. Inventory coverage (every row lands somewhere)

| Rows | Where it lands |
|---|---|
| LS1, LB1 | Masthead title "Library" (browse is the same screen) |
| LS2 | Masthead deck |
| LS3 (browse-sources icon) | Replaced: Discover is one thumb-index tab away, and the empty state's `Find something` opens it |
| LS4, LS5, LB9 | Continue reading: phone pager of cuttings, desktop rail of cuttings |
| LS6, LS7, LB10, LB13, LB16, LB17 | The WALL poster (§7.7) with captions, reading-status badge, favourite hover icon and favourited-at-rest star |
| LB11 | COMPACT |
| LB12 | LIST rows |
| LB14, LB18 | Select square and select mode |
| LB15 | Notify hover icon (unfollow moves to `Remove from library` in the card menu) |
| LS8, LB21, NS1–NS6 | The book list (§8.9.1) |
| LB2, LB3, LB4, LB5, LB6, LB7, LB8 | `Select`; the always-open desktop toolbar and the phone Filters sheet; the Sort menu (six sorts); the density segmented control; the compact search; the status slug line with `★ FAVOURITES`; `Clear filters` (the old hint text moves to the `?` sheet) |
| LB19 | `h j k l` / arrows / `Home` / `End` |
| LB20 | The overflow caption |
| LS9, LB22 | Loading galley |
| LS10, LS11, LB23 | Offline edition and `CORRECTION` |
| LS12, LB24 | `EMPTY SHELF` |
| LB25 | Search empty |
| LB26 | Filtered empty |
| BA1–BA10 | The select-mode bar: count, Select all, Favourite, Unfavourite, Mark read, Mark unread, Unfollow (now with the arm dialog), `Done`, the running state with `Stop`, the result line with `Dismiss` and `Undo` |

### G. Tag sheet: `frontend/src/skins/cinematic/parts/TagSheet.tsx`

Opened by `Manage tags…` (toolbar menu, Filters sheet) and later by the feature page's `Tags…` → `Manage` (web/11). A sheet on phones, a column panel on desktop (4 columns wide, min 400 px, sliding in from the right edge, `paper.2`, 1 px `rule.2` left edge, full height under the running head, Panel in 320 ms `ease.settle` / out 224 ms `ease.lift`, `Esc` closes). Kicker `TAGS`, title "Your tags". One row per tag: the name as an inline-editable field (§7.3 underline field; `Enter` saves through `useRenameTag()`, `Esc` reverts, success shows the 16 px `check` in `set` for 1600 ms), and a trailing `trash-simple` `bare` icon button that opens the dialog "Delete the tag {name}? It comes off every series." (`Delete tag` destructive with the 1000 ms arm, `Cancel`; `useDeleteTag()`). `New tag` (`quiet`, `plus`) at the bottom adds a row with its field focused; `Enter` creates it. Tag `color` is kept as stored and never drawn. States: loading (greeked rows), empty ("No tags yet. Add one from a series page."), an error line per row (`type.caption` `proof` with `‸` on desktop).

## File layout

```
frontend/src/features/library/{shelf-query,tags,mark-read,shelf-counts,manual-order}.ts (+ .test.ts for shelf-query, mark-read, shelf-counts, manual-order)
frontend/src/skins/cinematic/index.ts                               (library and featureByFollow out of PENDING)
frontend/src/skins/cinematic/screens/library/LibraryHub.tsx
frontend/src/skins/cinematic/screens/library/HubPager.tsx
frontend/src/skins/cinematic/screens/library/LibraryScreen.tsx
frontend/src/skins/cinematic/screens/library/ShelfToolbar.tsx
frontend/src/skins/cinematic/screens/library/FiltersSheet.tsx
frontend/src/skins/cinematic/screens/library/ContinueCuttings.tsx
frontend/src/skins/cinematic/screens/library/ShelfWall.tsx          (WALL, COMPACT, LIST, virtualised)
frontend/src/skins/cinematic/screens/library/ShelfStates.tsx
frontend/src/skins/cinematic/screens/library/use-library-keys.ts
frontend/src/skins/cinematic/screens/library/FeatureByFollow.tsx
frontend/src/skins/cinematic/screens/feature/FeatureView.tsx       (resolution target; web/11 fills it)
frontend/src/skins/cinematic/parts/{LibraryPoster,BookListRow,TagSheet}.tsx, SelectModeBar.tsx (only if missing)
frontend/src/app/(preview)/…                                         (gallery entries for new variants)
frontend/e2e/cinematic/web-09-library.spec.ts
frontend/e2e/fixtures/library/*.json
docs/redesign/proof/web-09/…
```

Skin code imports only `@/features/**` data files (not barrels that re-export components), `@/lib/**`, `@/skins/contract.generated` and its own skin folder; utilities only from §2.8 and §3.5 (`node design/lint-utilities.mjs`).

## Acceptance criteria

- [ ] `library` and `featureByFollow` are out of `PENDING`; the completeness test passes.
- [ ] `/library` and `/library/browse` render the shelf with the `mm-skin-debug=cinematic` cookie at 1440 × 900 and 390 × 844; on 390 × 844, `/library/browse` opens the Filters sheet once and back navigation does not reopen it.
- [ ] Hub tabs: five labels with folios, the Updates count superscript, sticky under the running head, no back arrow on any of the five routes; the spot rule slides 320 ms between tabs (fades under reduced motion); on the phone frame a horizontal swipe on the content settles on the neighbour tab and replaces the route; a drag that starts on a swipe row never moves the pager.
- [ ] Each sort sends the mapped server parameter (the e2e spec asserts the request URLs: `sort=-last_read_at` for Recently read, `sort=-new_count` for Most unread, `new_only=true`, `tag_ids=1,4`) and the URL carries `?status&sort&fav&new&tags&view&q&select`.
- [ ] WALL shows 6 per row at 1440 px and 3 at 390 px; COMPACT 8 and 4; LIST rows are 72 px; the wall is virtualised (with 200 rows, fewer than 60 poster nodes are in the DOM at the top of the page).
- [ ] Filter changes swap the wall instantly and run Set (stagger capped at 480 ms); reduced motion shows the new wall at once with a 150 ms fade.
- [ ] Hover shows favourite and notify at the bottom-right and the select square at the top-right; clicking the square enters select mode with that poster selected; favourited posters show the leading `★` in the caption.
- [ ] Manual order: dragging a poster writes only the changed `sort_order` values; `Alt+→` moves the focused poster and the live region announces the new position; `Move to top` works from the menu.
- [ ] Select mode: Shift-click range, `mod+a`, every bulk action runs with concurrency 4, shows `N OF M · K FAILED` and a result line; Unfollow asks first and its confirm cannot be pressed during the 1000 ms arm (a double click on the trigger never confirms); Undo restores the series with status, favourite, notify, override and position.
- [ ] Novels mode: the book list renders two columns at 1440 px and one at 390 px with plates, bylines, credits, blurbs and notes.
- [ ] Tag filter and tag sheet: a tag can be created, renamed with Enter and deleted after the arm; the filter shows removable tokens; `Clear filters` resets status, favourites, new only, tags and search.
- [ ] `/library/{followedId}` renders in place (no redirect) and the static `/library/*` routes still reach their own screens; an unknown id shows the `NOT IN THIS ISSUE` notice.
- [ ] Keyboard (desktop): every control reachable by Tab in reading order with the double focus ring (never clipped); `/`, `h j k l`, arrows, `Enter`, `x`, `Space`, `f`, `1`–`7`, `s`, `v`, `r`, `mod+a` work and appear in the `?` sheet.
- [ ] Hit targets: every interactive element on the phone frame is at least 44 × 44 px with at least 8 px between adjacent targets (the e2e spec measures `button, a, [role="button"], [role="radio"], [role="checkbox"]` inside `main`); at least 32 × 32 on the desktop fine pointer.
- [ ] Offline with the gate closed: a saved mature series is absent from the offline edition and nothing mentions it; with the gate open it appears with the `18` certificate.
- [ ] Loading, empty, filtered empty, search empty, offline, error and page-load-error states match C11 (screenshots at both sizes).
- [ ] Per skin: the data-layer additions under `frontend/src/features/` import nothing from `src/skins/**` (`grep -rn "skins/" frontend/src/features/library` is empty), so Glass's Library (web/32) reuses them unchanged; the Glass skin's `library` and `featureByFollow` entries stay in Glass's own `PENDING` set; the legacy skin's `/library` is unchanged.
- [ ] Lint, typecheck, Vitest, build and the `design/` checks are green; Vitest totals are at least the start-of-step totals with 0 failed.

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

This step changes nothing under `mobile/` or `backend/` (`git show --stat --format= <hash>` of each of your commits lists no `mobile/` or `backend/` path); `flutter analyze`, `flutter test` and the backend pytest are run by their own sessions.

If any commit you made touches `mobile/` (check each of your commits with `git show --stat --format= <hash>`; other sessions commit `mobile/` on the same branch, so never judge by the branch diff), revert that part, then prove the baseline still holds with the baseline's own commands, one at a time after the RAM guard and never while a `next build` runs: `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze` (baseline: No issues found) and `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter test` (baseline: all 2012 tests passed).

Visual proof against the backend/00 dev stack (uvicorn 127.0.0.1:8010, `next dev` on port 3010; start it as `backend/scripts/README-dev-stack.md` says if `curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8010/health` is not 200):

1. Route shots with `frontend/scripts/proof.mjs` (web/03): `node scripts/proof.mjs --step web-09 --skin cinematic --routes /library,/library/browse --grid` writes `cinematic-library-*` and `cinematic-library-browse-*` at 1440 × 900 and 390 × 844 with their `-grid` copies into `docs/redesign/proof/web-09/` (`--skin cinematic` sets the `mm-skin-debug` cookie; without it the pre-flip default, legacy, would be captured). The e2e spec of step 2 saves every named shot below with `page.screenshot` into the same folder:
   - `library-wall-{1440x900,390x844}.png`, `library-compact-{1440x900,390x844}.png`, `library-list-{1440x900,390x844}.png`, `library-grid-{1440x900,390x844}.png` (grid overlay)
   - `library-browse-sheet-390x844.png`, `library-filters-active-1440x900.png` (status, favourites, new only and two tag tokens)
   - `library-hover-1440x900.png` (a hovered poster with the icons and dimmed siblings), `library-select-{1440x900,390x844}.png`, `library-bulk-running-1440x900.png`, `library-unfollow-dialog-1440x900.png`
   - `library-manual-order-1440x900.png`, `library-books-{1440x900,390x844}.png`, `library-tag-sheet-{1440x900,390x844}.png`
   - `library-{loading,empty,filtered-empty,search-empty,offline,error}-{1440x900,390x844}.png`
   - `feature-by-follow-notfound-1440x900.png`
2. `frontend/e2e/cinematic/web-09-library.spec.ts` produces the states with `page.route("**/api/library/**", …)` fixtures from `frontend/e2e/fixtures/library/`, and checks the request URLs, the hit sizes, the arm delay and the pager. Run: `cd frontend && E2E_BASE_URL=http://127.0.0.1:3010 E2E_USERNAME=<demo user> E2E_PASSWORD=<demo password> npx playwright test e2e/cinematic/web-09-library.spec.ts` (credentials from `backend/scripts/README-dev-stack.md`, never committed). With the `playwright-cli` tool, always pass `-s=web-09`.
3. Motion-timings overlay (`mod+shift+m`): switch filters three times and screenshot `library-motion-timings-1440x900.png`; no `proof` rows.

## RAM guard

- Before every `npm run test`, `npm run build`, Playwright run or dev-stack start: `free -m`; if the `available` column of `Mem:` is under 1024, do not start it; stop and report "RAM guard: N MB available".
- `pgrep -af "next build|vitest|flutter_tester|pytest"` first; never run two builds at once; wait for another session's build or test run to finish.
- One heavy command at a time; no Gradle, Xcode or `flutter build` on this box; no `npm install` (every package was pinned in web/01; if `npm ls @tanstack/react-virtual @use-gesture/react embla-carousel-react motion` reports one missing, stop).

## Git

- Branch `feat/vps-slim-source-native`; small commits, one per working step (shelf query; tags hooks; mark-read helpers; hub frame; hub pager; toolbar; Filters sheet; wall densities; manual order; select mode; book list; tag sheet; featureByFollow; states; e2e and proof), messages starting `web-09:`.
- Stage only your paths with explicit `git add <path>`; never `git add -A` or `git add .`. Never commit secrets, demo credentials, `.claude/` or `.env` files.
- **No Claude or AI attribution anywhere**: no `Co-Authored-By`, no "Generated with" line, no AI author, even if your harness asks for it (the owner's `~/.claude/CLAUDE.md` forbids it).
- `npm run build` (after the RAM guard) before any push that includes frontend code, then `git push origin feat/vps-slim-source-native:master` after each working step.

## Guardrails

- Never edit `backend/connectors/`; never touch production containers or `/srv/manhwamaniacs/{app,data}`.
- No changes under `mobile/`, `backend/` or `design/` in this step; a missing token is reported, not added.
- Nothing from `frontend/src/components/**` or `frontend/src/features/*/components/**` is imported by skin code; never reproduce the legacy look.

## Report back

1. **Done**: items A1–A5, B1–B4, C1–C14, D, E, G with a one-line status each.
2. **Screenshots**: `docs/redesign/proof/web-09/` and the file list.
3. **Tests**: Vitest totals before and after; lint, typecheck and build; the e2e spec result.
4. **Open issues**: ambiguities in DESIGN.md and the choice made, blocked items, conflicts between this prompt and DESIGN.md.
5. **Commits**: the hashes pushed.

Next prompt file: `docs/redesign/prompts/web/10-cinematic-updates-collections-history-bookmarks.md`.
