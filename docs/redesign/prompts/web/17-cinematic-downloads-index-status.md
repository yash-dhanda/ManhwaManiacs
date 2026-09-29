# web/17 · Cinematic Downloads, Index, What's new and System status

Step 51 of the redesign series (track `web`, group 2). Depends on `web/16-cinematic-discover-search-sources-dialogue.md`. Its twin `mobile/17-cinematic-downloads-index-status.md` builds the same cluster in Flutter and may run at the same time in another session; you never touch `mobile/`.

## Goal

Build four pieces of the Cinematic web skin. **Downloads, "The offline edition"** at `/downloads`: the storage meter set as one typographic line over a live rule, the activity of saves the service worker reports, the saved library by series with deferred, undoable removal, retention and storage protection, the two new per-profile download switches, and the device-side 18+ filter on every list and count. **The Index** at `/more`: the phone hub set as a magazine index with folios and dot leaders that draw themselves. **What's new**: the release notes as errata and additions, plus the service-worker "new edition" toast. **System status** at `/admin/status` for admins: the worst-state summary, backend, update checker, recent checks and the worst-first source health table. Every state, key, reduced-motion variant and phone layout is delivered for desktop web and mobile web.

## Read first

1. `docs/redesign/cinematic/DESIGN.md`
   - §2.1.1 (the `ink.45` raised-stock rule, and why `REMOVING…` is `ink.45`, never `ink.30`), §2.1.3, §2.1.6 (mood grades: Index gets one), §2.2, §2.3, §2.4 (layers), §2.6 (rules, dot leaders), §2.7, §2.8.
   - §3.2 and §3.5 (type roles), §4.2–§4.8 (durations, curves, the motion table incl. **Leader draw**, stagger, reduced motion).
   - §5 (the web vibrates only for five events: `download.fail` and `error` use `[20,40,20]`) and §6 (`download.done` plays `done`, `error` plays `error`).
   - §7 intro, §7.1, §7.2, §7.5 (slug lines), §7.9 (sheets and desktop column panels), §7.10 (dialogs, the 1000 ms **arm delay**, inline confirms), §7.11 (toasts, holds: 3600, errors 6000, with an action 8000), §7.12 (contents tabs and the phone pager), §7.13 (running head, `OFFLINE EDITION` badge), §7.16 (rows, swipe slabs), §7.17, §7.18 (determinate rule, leader dial, **download mark**, **storage meter**), §7.19 (badges), §7.21 (switches), §7.22 (row menus), §7.23 (notices), §7.24 (**local copies follow the gate**), §7.25 (avatars), §7.27 (masthead), §7.29 (content-mode chip, banner strips, `folioLabel()`).
   - §8.0.3 (route contract and branches), §8.0.4 (transitions), §8.0.8 (content mode), §8.0.9 (tablet rows for Downloads and Index), §8.0.10.
   - **§8.23 Downloads and storage, §8.28 Index, §8.29 What's new and app updates, §8.31 System status** (read every line), §8.30.1 (server-backed section states, which the Status cards follow), §8.30.2 row 07 (the same storage controls appear in Settings in `web/18`).
   - §10.1.2 and §10.2.2 (where the letter and typing reveals play: Downloads and System status mastheads, the Status summary headline, notice headlines), §11 (swipe row, long-press rows), §14, §15.2 (service worker), §15.6, §15.7 (the 18+ on-device checklist).
2. `docs/redesign/glass/DESIGN.md` §8.22 Downloads, §8.24 You and About, §8.26 System status and §15.6, only so the shared modules you add stay skin-neutral (Glass builds these screens in `web/32` and `web/40` on the same hooks).
3. `docs/redesign/inventory/00-decisions.md`.
4. `docs/redesign/stack-decision.md` §2.2, §2.6, §3 (the service worker stays), §4 risk 11.
5. `docs/redesign/inventory/web.md` §5 (M1–M6), §12.1 (DL1–DL9), §12.2 (DP7 download marks), §15 (AS1–AS10), §2.7 (G40, the app-update prompt), §18.8 (the service-worker protocol), §19.3–§19.4 (keys K27, K48–K51).
6. `docs/redesign/inventory/capabilities.md` §21 (updates), §23 (app distribution, what's new, system status), §24 (offline downloads).
7. `docs/redesign/00-baseline.md`.
8. `docs/redesign/prompts-plan.json` (this entry and `web/05`, `web/06`, `web/07`, `web/15`).

## Skills to invoke, in this order

1. `superpowers:writing-plans`: write the plan to `docs/redesign/proof/web-17/plan.md`, one task per item in the Scope section.
2. `superpowers:subagent-driven-development` to run it (task groups A–E below, one after the other); `superpowers:executing-plans` if subagents are unavailable.
3. `frontend-design:frontend-design`, `impeccable:impeccable` and `taste-skill:taste-skill` while building each screen. Where they contradict `cinematic/DESIGN.md`, the contract wins.
4. `superpowers:verification-before-completion` before claiming done.

## Before you start

- Branch `feat/vps-slim-source-native`. Other sessions commit in this checkout: stage only your own paths; never `git add -A`, `git stash`, `git reset` or `git checkout` on files you did not change.
- Stop and report if any of these is missing: `downloads`, `index` and `status` in the Cinematic `PENDING` set (`frontend/src/skins/cinematic/index.ts`); the `web/05` primitives (sheets, dialogs with the arm delay, toasts, rows with swipe slabs, switches, notices); `frontend/src/features/offline/mature-filter.ts` from `web/07`.
- Read the legacy screens you replace, only to learn their hooks and calls: `frontend/src/features/offline/components/DownloadsView.tsx`, `frontend/src/app/(app)/more/page.tsx` with `frontend/src/config/more-nav.ts`, `frontend/src/app/(app)/admin/status/StatusView.tsx`. Never import from them and never copy their look.
- Read `frontend/public/sw.js` around `mm-offline/sweep`, `set-retention`, `remove-chapter` and `cancel-save`, and `frontend/src/features/offline/{client,hooks,format,types,download-queue}.ts`: every downloads action below maps to one of those existing messages. No service-worker change is needed in this step.

## Ground rules for this step

- **Track rule.** Work in `frontend/` only; stage explicit paths; do not edit `design/`, `brand/`, `mobile/` or `backend/`.
- **Skin boundary.** Screens in `frontend/src/skins/cinematic/screens/…` import only `@/features/**` (never `@/features/*/components/**`), `@/lib/**`, `@/services/**`, `@/stores/**`, `@/types/**`, `@/config/**`, the generated contract and their own skin. The eslint rule enforces it.
- **Shared logic in `features/`**, skin-neutral, each module with a Vitest test.
- **Paths** from the `ROUTES` builders in `frontend/src/skins/contract.generated.ts` (use the names the generator emits for ScreenIds `reader`, `novel`, `feature`, `featureByFollow`, `downloads`, `status`, `settings`, `numbers`, `annual`, `circle`, `picks`, `updates`, `collections`, `history`, `bookmarks`, `dialogue`, `profiles`, `profilesManage`).
- **Tokens only** (the utility lint checks `src/skins/cinematic/**`).
- **Never** edit `backend/connectors/`, never touch production containers or `/srv/manhwamaniacs/{app,data}`.
- **RAM guard.** `free -m` before every build, test run and Playwright run; stop if `available` < 1024 MB; never run two builds (or a build and `next dev`) at once.

## Scope: every item this step delivers

Remove `downloads`, `index` and `status` from the Cinematic `PENDING` set when their screens are done. Each screen registers its keys in `frontend/src/lib/keyboard/` under its masthead title (`Downloads`, `System status`), sets `document.title` (`Downloads · ManhwaManiacs`, `Index · ManhwaManiacs`, `System status · ManhwaManiacs`) and receives route focus on its `h1`.

### A. Shared data-layer work (skin-neutral, each with a Vitest test)

1. **Move the status logic out of the route folder** (one commit with no pixel change): `frontend/src/app/(app)/admin/status/{api,hooks,status}.ts` and `status.test.ts` move to `frontend/src/features/admin/status/`; the legacy `StatusView.tsx` and its thin `page.tsx` import from the new place; `npm run test` stays green. A skin screen may not import from `app/`.
2. `frontend/src/features/offline/pending-removals.ts`: deferred chapter removal. `scheduleRemoval(key, run, delayMs = 8000)` returns `{ undo() }`; `isRemovalPending(key)` and a `subscribePendingRemovals` store (for `useSyncExternalStore`) let rows show `REMOVING…`; `flushPendingRemovals()` runs every pending removal at once and is registered on `pagehide`; the pending message is `mm-offline/remove-chapter` through `removeSavedChapter()` in `client.ts`. Test with fake timers: undo cancels, expiry runs, flush runs all, a second schedule for the same key replaces the first.
3. **The two download switches.** "Save the next chapter while I read" already exists: `web/03` wrote `frontend/src/features/offline/save-next.ts` (profile-scoped key `mm.downloads.save-next`, default `true`, `readSaveNext()` / `writeSaveNext(on)`), which the engine's auto-queue predicate reads; add a `useSaveNext()` hook there if none exists (a `useSyncExternalStore` over the same key). "Download new chapters of followed series automatically" is new: the profile-scoped key `mm.downloads.auto-new` (default `false`) with `readAutoNew()`, `writeAutoNew(on)` and `useAutoNew()` in `frontend/src/features/offline/auto-download.ts` (item 4). Test the new key's default and per-profile isolation.
4. `frontend/src/features/offline/auto-download.ts`: `planAutoDownload({ notifications, follows, savedKeys, freeBytes })` returning at most **20** chapters: the chapters named by **unread** new-chapter notifications of followed series whose per-series `notify` is on, skipping chapters already saved, stopping before the estimated free space would go under the **250 MB** web floor (use the manifest byte estimate the series-page picker already uses; 8 MB per manga chapter and 0.2 MB per novel chapter when unknown). And `useAutoDownloadNewChapters(onQueued)`: runs when the app loads and on every `visibilitychange` to visible, right after the unread-notifications query settles (`useUnreadNotificationCount` / `useUpdateNotifications` in `features/updates/hooks.ts`), only while `mm.downloads.auto-new` is on, a profile is active, the device is online and the service worker is supported; it queues through the same chapter savers the series-page download picker uses (`chapter-savers.ts`, `download-queue.ts`) and calls `onQueued(n)` when `n > 0`. Mount it in `frontend/src/skins/cinematic/Shell.tsx` with the toast "Queued 6 new chapters." (plural rules: "Queued 1 new chapter."). Test the planner: unread only, notify off skipped, saved skipped, the floor, the cap of 20.
5. `frontend/src/features/offline/download-queue.ts`: if the bulk run state lives only inside the series-page hook, lift it into a module-level store (`subscribeRun`, `getRunSnapshot`, `stopRun`) so the Downloads screen can show its tally (`12 of 40 saved in this series`) and stop it. No behaviour change for the series page; extend `download-queue.test.ts`.
6. `frontend/src/features/offline/storage-meter.ts`: `meterModel(estimate, appBytes)` returning the three segment fractions (other usage of this site = `usage − appBytes` in `ink.60`, ManhwaManiacs in `spot`, free in `rule.1`), the tick position at `quota − 250 MB`, `nearFloor` (free ≤ 250 MB) and the line "2.3 GB in 84 chapters · 2.3 GB of 60 GB used by this site · 57 GB free" (use `formatBytes` and `summariseStorage` from `format.ts`), or `null` when the browser reports no quota. Test the maths, the floor and the null case.
7. `frontend/src/features/app/changelog.ts`: `useChangelog()` for `GET /app/changelog` (`{ entries: [{ version, build, date, highlights[] }] }`, newest first) through `services/http.ts`; `formatReleaseFolio(entry)` → `3.5.0 · BUILD 57 · 28 SEP 2026`; `shouldAutoOpenWhatsNew(latestVersion, seen)` → `true` only when a stored value exists and differs (a first visit stores the latest version without opening). The seen value is device-global `localStorage['mm.whatsnew.seen']` (not profile-scoped). Test all three.
8. `frontend/src/config/web-version.ts`: `export const WEB_VERSION` read from `frontend/package.json` with `import pkg from "../../package.json"` (`resolveJsonModule` is on).

### B. Downloads, "The offline edition" (`/downloads`, ScreenId `downloads`), §8.23, web DL1–DL9

Data: `useOfflineState`, `useStorageScope`, `useOnlineStatus`, `useNow` (`features/offline/hooks.ts`), `groupBySeries`, `describeEntry`, `formatDueIn`, `summariseStorage` (`format.ts`), the run store (A5), pending removals (A2). **Every list, count and badge first passes through `features/offline/mature-filter.ts`** (the active profile's gate) and then through the content-mode filter (`savedChapterMedium` against `useContentMode`). The storage meter keeps the app's total bytes, because it names no series. Nothing ever says files are hidden. Saved narration audio (`medium: "novel-audio"`, the separate entries `web/15` A6 creates) is never a row, a chapter count or a control on the web (§8.23: saved narration audio is absent on the web); its bytes still count in the meter and in its series block's size, and `Remove all downloads` on a series removes its audio entries too.

**Masthead** (both frames): kicker `No. 05 — ON THIS DEVICE` (letter reveal on mount), title "Downloads" (`type.masthead`), deck "Saved for {profile} · reads with no connection" (`type.deck` `ink.60`), `rule.oxford` desktop / `rule.heavy` phone drawn after the letters. Phones: `web/05`'s `ContentModeChip` (`MANGA ▾`, §7.29) in the running head through `useRunningHead` (`web/06`) when novels are enabled.

**The storage meter** (§7.18): the line from A6 in `type.folio` (IBM Plex Mono 500, 12/16, +0.02em) as one typographic line, then the 8 px bar (radius 0) in three segments, the 2 px `ink.100` tick above the bar at `quota − 250 MB`, and, when `nearFloor`, a `NOTE` kicker line (`spot`) "Saving stops here: less than 250 MB of this browser's storage is left." `role="meter"` with `aria-valuetext` "2.3 of 60 gigabytes used" (through `folioLabel()`). With no quota: only the line "This browser doesn't report a storage quota." Explainer under it (`type.caption` `ink.60`): "Saving stops before the last 250 MB of the quota; finished chapters go oldest-first, never one you haven't read and never the one you have open." **Signature moment:** when a chapter finishes saving, its row's download mark fills with `set` and the meter's `spot` segment grows by exactly its size (width change 240 ms `dur.line` `ease.set`), so the edition visibly gets thicker.

**Activity** (only while something runs, pinned at the top of the saved column): kicker `DOWNLOADING`; one row per save the worker reports in its `mm-offline/state` broadcast: series title, `CH 12 · 7/40 PAGES` in `type.folio`, a 2 px determinate rule (track `rule.1`, fill `spot`, width 240 ms `ease.set`), and `Stop` (`quiet`, sends `mm-offline/cancel-save` through `cancelChapterSave`); the bulk run's tally from A5 ("12 of 40 saved in this series") with its own rule; and `Stop all` (secondary sm: a `cancel-save` for every save plus `stopRun()`). The web has no Pause, Resume or queue rows, and `p` is not bound.

**Narration** (only while `useActiveNarrationJobs()` from `web/15`'s `frontend/src/features/novels/narration-jobs.ts` reports active jobs): kicker `NARRATING 3 CHAPTERS` with a determinate rule per book, each row linking to that book's page with the Audiobook sheet open (`#audiobook`).

**Saved library**: kicker `IN THIS BROWSER — BIGGEST FIRST`; one block per series, largest first: cover 48 × 72 (radius 0, `paper.1` placeholder, the §7.7 inner hairline), title in `type.title` linking to the series page (`featureByFollow` when followed, else `feature`), a folio `40 CHAPTERS · 1.2 GB` (plus ` · 2 SAVING` while saves run), an overflow `dots-three` menu with `Remove all downloads` → dialog "Remove every saved chapter of {series}? Your reading progress is kept." (destructive, 1000 ms arm), and an expand chevron (`caret-down` 16, rotates 180° in 240 ms `ease.settle`; `aria-expanded`). There is no pin control on the web: the worker's retention has no pin (inventory DL5–DL7).

Expanded chapter rows (§7.16 standard row, 56 px): the download mark (§7.18: saved `check-square` Fill `set`; saving fills bottom-up in `spot`; incomplete square outline `proof` with `!`; paused two 2 px `spot` bars; stale `cloud-arrow-down` in `spot`; each with the DP7 tooltip), `CH 12` in `type.folio.lg` plus the chapter title in `type.title`, and a status caption (`type.caption`): "Saved · 24.3 MB", "Saving 12/40" with a determinate rule, "Incomplete — 38/40 pages", "Paused — this browser is out of room", "Pages changed on the server — save again" (the last three under a `NOTE` kicker in `spot`, the stale one with a `quiet` `Save again`), with the retention hints " · deletes in about 3 days" or " · open now, kept" (`formatDueIn`). A trailing `bare` `trash-simple` button ("Remove {title} from this device"); on touch pointers a left swipe reveals the 72 px `proof` `Remove` slab (black label), committing past 50 % with `spring.release` (`{ visualDuration: 0.42, bounce: 0 }`), `touch-action: pan-y` on the row. Remove: the row reads `REMOVING…` in `ink.45` (in `ink.60` when the row sits on `paper.1`), a toast "Removed chapter 12." + `Undo` held 8000 ms (`dur.hold.toast.action`), and the worker message is deferred through A2. Tapping a saved chapter opens it with the **Dip** (440 ms: out 160 `ease.lift`, hold 40, in 240 `ease.settle`) in the manga reader or the novel reader by its medium.

Note under the library (`type.caption` `ink.60`): "Chapters saved here are stored in this browser and open with no connection at all. They belong to the profile that saved them."

**Storage controls** (the `StoragePanel` component, reused by Settings → Downloads & storage in `web/18`):
- `DELETE FINISHED CHAPTERS AFTER` as a single-select slug line `2 DAYS · 7 DAYS · 30 DAYS · NEVER` (web K50; `setOfflineRetention`, the worker sweeps after it).
- `Protect storage`: the `STORAGE PROTECTED` badge (1 px `set` outline, `set` text, `type.micro`) when granted, else `Ask to protect storage` (secondary; `requestPersistentStorage()`, i.e. `navigator.storage.persist()`), with the caption "Asks the browser not to clear saved chapters when space runs low."
- "Save the next chapter while I read" switch (`save-next.ts`, default on, per profile), caption "The chapter after the one you're reading is saved in the background."
- "Download new chapters of followed series automatically" switch (`mm.downloads.auto-new`, default off, per profile), caption "When you open the app, new chapters from series with notifications on are saved, up to 20 at a time."
- `BY SERIES`: credits rows `title ........ 12 CH · 240 MB`.
- `Free up space` (secondary): `sweepOffline()`; toast "Removed 14 chapters." or "Nothing to free up right now."
- Footer: `Remove all downloads` (destructive, an inline confirm "Delete everything saved?" with the 1000 ms arm, reverting after 4 s without a second press) and `Reset offline storage` (`quiet` in `proof`) → dialog "Reset offline storage?" / "This unregisters the offline worker and clears every saved chapter and cache in this browser. Your reading progress is kept." (`Reset` destructive with the arm, `Cancel` quiet), running `resetServiceWorker()`.
- Absent on the web (not disabled): Save to Files, `Scan dialogue`, saved narration audio controls, chapters at once, Wi-Fi only, image and metadata cache cards, the platform note.

**Desktop (≥ 768 px, 12 columns; 8 columns at 768–1023):** no contents tabs. Columns 1–8: meter, activity, narration, saved library (series blocks in two columns at ≥ 1440), the note, the footer actions. Columns 9–12: an aside under the kicker `STORAGE` with the storage controls minus the footer. `?tab=storage` scrolls to the aside (a jump) and focuses its `STORAGE` header. At 768–1023 the aside stacks under the meter.

**Phone (< 768 px, including 600–767):** contents tabs `SAVED · STORAGE` (§7.12; the tab is `?tab=storage` written with `router.replace`; the panels form a horizontal scroll-snap pager; nested controls never steal the swipe). SAVED: meter (tapping it switches to STORAGE), activity, narration, saved library (two columns from 600 px), note. STORAGE: the meter at full width, then the storage controls and the footer actions.

**Transitions.** In: Cut (the thumb-index tab) or the desktop section Dip. Out: Dip into saved chapters.

**Gestures.** Swipe chapter rows to remove; long-press (450 ms) a series block for `Remove all downloads` and `Open series` (the same items as its `dots-three`); no pull to refresh (local data).

**Keys (web).** `j` / `k` next / previous series block; `Enter` expands or collapses it; inside an expanded block `↓` / `↑` move through chapter rows; `Delete` (or `Backspace`, not while typing) removes the focused chapter, and on a focused series block opens its remove dialog.

**States (each built and screenshot-tested):** no profile (notice "Choose a profile to see its downloads." + `Choose a profile`); unsupported (`!isServiceWorkerSupported()`: notice "Downloads aren't available in this browser or on this connection."); checking ("Checking what's stored…" with a 24 px leader dial after 400 ms); empty (notice `NOTHING SAVED YET`, headline typed "Chapters you save open with no connection.", then a rail of Continue reading series (`useContinueReading`) with `Download next 5` (secondary sm) on each, which plans the next five unread chapters with `planDownload` and saves them); offline (a banner strip under the running head: kicker `OFFLINE EDITION`, "You're offline. Only saved chapters open."); error (`CORRECTION` notice "Couldn't read downloads." + `Try again` calling `refreshOfflineState`). Failed saves fire `download.fail` (web vibrate `[20,40,20]` on Android Chrome when haptics are on; sound `error` when sounds are on); a finished save fires `download.done` (sound `done`).

### C. The Index (`/more`, ScreenId `index`), §8.28, web M1–M6

The phone hub set as a magazine index. Desktop reaches it by URL (the sidebar covers these destinations).

1. Mood grade behind the top 30 vh (§2.1.6) with the raised-stock scope on it. Masthead: kicker `THE INDEX`, title "Index" (`type.masthead`, letter reveal on mount), `rule.oxford` desktop / `rule.heavy` phone.
2. **Profile block**: 44 px avatar (§7.25), the profile name in Bodoni Moda Italic at `type.subhead` size, `@username` in `type.caption` plus the `ADMIN` credit for admins, the mood in `type.caption` `ink.60`; actions `Switch profile` (secondary sm: the picker as a pushed takeover by Dip, the `web/07` flow), `Profiles` (`quiet` → `ROUTES.profilesManage()`) and `Switch account…` (`quiet` → the §8.5 sign-out dialog `web/07` built).
3. `web/05`'s `ContentModeToggle` (`MANGA / NOVELS`) when novels are enabled; on phones also the `ContentModeChip` in the running head.
4. Sections as credits lists (row 48 px, 44 px hit on phones: label in `type.ui` → dot leaders (`·` at 0.5em in `ink.30`, `type.folio`) → a folio value in `type.folio` `ink.45` → `caret-right` 16 Regular `ink.45`), each section under a `type.kicker` label:
   - `YOU`: The Numbers ...... `12-DAY STREAK` (the current streak from `useStatistics`; no value at 0); The Annual ...... `2026` (the current year, to `ROUTES.annual(year)`); Circle (to `ROUTES.circle()`, no value until `web/22` wires `2 NEW`); Picks ...... `8 ASKS LEFT` (`useSuggestAvailability().remaining_today` while available; no value otherwise).
   - `READING`: Updates ...... `14` (unread count); Collections ...... `9`; History; Bookmarks ...... `23`; Dialogue search (only in manga mode with OCR available).
   - `THE HOUSE`: Settings; Storage ...... `4.1 GB` (this browser's saved bytes for the profile, to `/downloads?tab=storage`); Backup & restore (admin, to `/settings/backup`); Members (admin, to `/settings/members`); System status (admin) ...... `84/89 OK` (`ok`/`total` from `GET /system/source-health`, the `useSourceHealthSummary` hook `web/16` added).
   - `ABOUT`: What's new ...... `3.5.0` (the latest changelog version; opens the What's new sheet or dialog, item D); Version ...... `WEB 2.6.1` (`WEB_VERSION`); Licenses (to `/settings/about#licenses`, built in `web/18`).
   - Absent on the web: App update (Android APK), the update banner, the SideStore card.
5. Narration indicator row while `useActiveNarrationJobs()` (`web/15`) reports active jobs: `NARRATING 3 CHAPTERS`, linking to the book's page with `#audiobook` (reuse `web/15`'s `NarratingIndicator` if it fits the row anatomy).
6. **Desktop and tablets ≥ 900 px:** two columns with a 1 px `rule.1` column rule: `YOU` and `READING` left, `THE HOUSE` and `ABOUT` right; the profile block spans both above them. Phones and 600–899 px: one column.
7. **Signature moment:** the dot leaders draw themselves (**Leader draw**: a clip reveal left → right, 320 ms per row, rows 24 ms apart, `ease.settle`) the first time the Index opens in a session (`sessionStorage['mm.index.leaders']`). Reduced motion: the leaders are present at rest.
8. Transitions: destinations are drill-ins by Page (nav-forward) or, across sections, the shell's section change; The Annual opens as a takeover by Dip; Switch profile pushes the picker takeover by Dip; What's new rises as a sheet on phones and inserts as a dialog on desktop; Switch account inserts its dialog.
9. States: loading (values show `–`); a failed count hides its value only; offline (values from the React Query cache and the `OFFLINE EDITION` micro badge beside the kicker).

### D. What's new and the web edition update (§8.29, web G40)

1. **What's new**: a sheet at the 0.92 detent on phones, a dialog on desktop (max width 560, body scrolling inside a max height of 70 vh): kicker `WHAT'S NEW`, title "Release notes" (`type.subhead`); entries per version from `useChangelog()`: the folio `3.5.0 · BUILD 57 · 28 SEP 2026` in `type.folio.lg` (IBM Plex Mono 500, 15/20), a `LATEST` badge (1 px `ink.100` outline, `ink.100` text, `type.micro`) on the first entry, highlights as a list with `—` dashes in Newsreader 16/24 (`type.body`), 24 px between entries with a `rule.1` hairline. Loading: a 24 px leader dial with the kicker `LOADING` after 400 ms. Unavailable: the notice "Release notes aren't available right now." Opened from the Index (`What's new`), from Settings → About (`web/18`), and automatically once per new release when `shouldAutoOpenWhatsNew()` says so (checked by the Shell after the active profile loads, never over a reader or takeover; closing it stores the latest version). `Esc`, the barrier and `Done` close it; focus returns to the trigger.
2. **Web edition update**: when `useWorkerUpdate()` reports a waiting worker, the Shell shows a subtitle toast that does not time out (info edge `spot`): "A new edition is ready." with `Reload` (`applyWorkerUpdate()`: posts `skip-waiting` and reloads). Mount it as `frontend/src/skins/cinematic/overlays/WorkerUpdateToast.tsx` in `Shell.tsx`.

### E. System status (`/admin/status`, ScreenId `status`), §8.31, web AS1–AS10

Data: the hooks moved in A1 (`useBackendHealth` polling `GET /health` every 15 s, `useSourceHealth` polling `GET /sources/health` every 30 s), `useUpdateSettings`, `useUpdateRuns`, `useManualCheck` (`features/updates/hooks.ts`), and the summary logic in the moved `status.ts`.

1. Masthead: kicker `ADMINISTRATION`, title "System status" (letter reveal on mount), deck "Backend health, the update checker, per-source failures and update runs." with `Refresh all` (`quiet`, `arrow-clockwise` that becomes a 16 px leader dial while any card refetches) and a live folio `LIVE · 15 S` counting down once per second to the next health poll.
2. **Summary**: a banner strip on `paper.0` with a 2 px left rule tinted by the worst state (`set` all healthy, `spot` warnings, `proof` something down, `ink.45` unknown), the headline typed at 50 ms per character ("Everything is running.", "1 thing needs attention." or "2 things need attention."; the count in digits, as §8.31 writes it), and the list of problems in `type.body` (from `status.ts`).
3. **Backend** credits (§7.28 `Credits`, two columns desktop, one phone): `STATE HEALTHY` (the value tinted by state), `NAME`, `VERSION 3.5.0` in Plex Mono, `PROBE GET /health`.
4. **Update checker** credits: `LAST RUN 21:04 · 12 MIN AGO`, `NEXT ≈ 21:34 · IN 18 MIN`, `INTERVAL 30 MIN`, `FAILED RUNS (RECENT) 0` (the value in `proof` when > 0), the server's error block in IBM Plex Mono on `paper.1` (text in `ink.60`, the raised-stock rule), and `Check now` (secondary; loading segment while starting; `useManualCheck`). A footnote in `type.caption` explains that the next run is an estimate.
5. **Recent checks**: up to 8 rows: a status badge (`FINISHED` 1 px `set`, `RUNNING` 1 px `spot`, `FAILED` 1 px `proof`, anything else `ink.45`), the trigger in `type.kicker`, `212 SERIES · 3 NEW` in `type.folio`, the start time, and the error text in Plex Mono under the row when present. Empty: "No update checks have run yet."
6. **Source health**: a table sorted worst-first (`sortWorstFirst` from `web/16`'s `features/sources/health.ts`): the 6 × 6 mark, name, id in Plex Mono, a `DEMOTED` badge (1 px `ink.60`), `LAST PROBE 4 MIN AGO`, the message, and the last error as a collapsible Plex Mono block (`caret-down`, `aria-expanded`). The table sits in its own `overflow-x: auto` container (min width 720 px) so the page never scrolls sideways.
7. Footer note in `type.caption` `ink.60`: "Everything on this page is read from endpoints the server already exposes; nothing here changes a setting except Check now."
8. **Phone:** sections stacked; tables become blocks (one block per run or source, the same facts as credits).
9. **Non-admin:** the notice `ADMINISTRATORS ONLY`, headline typed "System status is instance-wide.", deck "Ask the owner to check it.", `Back to Tonight`. Use the existing admin check in `features/auth/access.ts` / `useCurrentUser()`.
10. **States:** resolving (masthead only while `/auth/me` resolves); each card's loading (its credits greeked at their exact heights, flicker) and error (a `CORRECTION` line under the card header with the API message and a `quiet` `Retry` for that card only).
11. **Keys (web):** `r` refreshes every card; `c` runs Check now; `j` / `k` move through the source-health rows; `Enter` expands or collapses the focused row's last error.
12. Breadcrumb `STATUS`; the sidebar footer item `Status` lights.

### F. Cross-cutting on all screens of this step

- **18+:** absence, never a lock (§7.24): hidden series never appear in Downloads, their bytes stay in the meter total, and no caption or count mentions them; queued saves of a now-hidden series pause silently (the `web/07` filter already pauses them; verify).
- **Reduced motion** (`prefers-reduced-motion: reduce` or `html[data-motion="reduced"]`): letter reveals fade the whole string in 200 ms; typed headlines show at once with no caret; Set becomes a 160 ms fade; the leader draw is at rest; rules are present at rest; the meter's segment change and the chevron rotation apply at once; Dip and sheet or dialog motion become 150 ms opacity fades; swipe release finishes with a 150 ms fade; programmatic scrolls jump. Leader dials, the indeterminate rule and determinate rules keep updating (essential progress).
- **Focus:** the double ring (2 px `ink.100` at 2 px offset over a 6 px `#000000` halo) on every control; dialogs and sheets trap focus and return it to the trigger; the initial focus in a destructive dialog is `Cancel`.
- **Hit targets:** 44 × 44 CSS px on coarse pointers (mobile web), 32 × 32 with 24 px spacing on fine pointers.

## Values you need (copied from `cinematic/DESIGN.md`)

| What | Value | Section |
|---|---|---|
| Grounds | `paper.0` `#000000`, `paper.1` `#0B0B0A`, `paper.2` `#121211`, `paper.3` `#1A1A18`, `paper.4` `#232220` | §2.1.1 |
| Inks | `ink.30` `#4D4B47` (disabled only), `ink.45` `#7A7770` (on `paper.0` only), `ink.60` `#9A978F`, `ink.80` `#C9C6BE`, `ink.100` `#F3F0E8` | §2.1.1 |
| Accent and semantic | `spot` `#F4D03F`, `spot.wash` `rgba(244,208,63,0.16)`, `proof` `#FF5B4A`, `proof.wash` `rgba(255,91,74,0.12)`, `set` `#57D68D`, `rule.1` `#2B2A27`, `rule.2` `#3D3C38` | §2.1.2, §2.1.3 |
| Scrim behind dialogs and sheets | `scrim.modal` `rgba(0,0,0,0.78)`, never blurred | §2.1.4 |
| Durations | `dur.tick` 80, `dur.beat` 160, `dur.line` 240, `dur.column` 320, `dur.spread` 480, `dur.snap` 120, `dur.reduced` 150, `dur.clip` 200, `dur.rise` 360, `dur.arm` 1000, `dur.hold.toast` 3600, `dur.hold.toast.error` 6000, `dur.hold.toast.action` 8000, `dur.loop.rule` 1200, `dur.leader` 1000, `dur.flicker` 1400 (ms) | §4.2 |
| Curves | `ease.settle` `cubic-bezier(0.16,1,0.3,1)`, `ease.lift` `cubic-bezier(0.7,0,0.84,0)`, `ease.turn` `cubic-bezier(0.65,0,0.35,1)`, `ease.set` `cubic-bezier(0.2,0,0,1)` | §4.3 |
| Sheet release | `spring.sheet` `{ visualDuration: 0.48, bounce: 0 }`; dismiss below 30 % height or faster than 800 px/s | §4.4, §7.9 |
| Leader draw | 320 ms per row, 24 ms stagger, `ease.settle` | §4.5 |
| Type | `type.masthead` Bodoni Moda 800 (40/40 phone · 56/56 tablet · 72/68 desktop · 88/84 wide, −0.035em); `type.kicker` Archivo wdth 62 wght 700 (11/16 · 12/16 · 12/16 · 13/16, +0.16em, upper); `type.folio` Plex Mono 500 12/16; `type.folio.lg` Plex Mono 500 15/20; `type.title` Archivo 600 15/20 · 16/20; `type.caption` Archivo wdth 90 wght 450 13/16 | §3.2 |
| Row heights | standard 56 (one line) / 72 (two lines); credits 40 (Index rows 48); settings rows min 56 | §7.16, §8.28 |
| Storage meter | 8 px bar; other usage `ink.60`, app `spot`, free `rule.1`; 2 px `ink.100` tick above | §7.18 |
| Layers | `z.sticky` 10, `z.chrome` 20, `z.panel` 30, `z.sheet` 40, `z.dialog` 50, `z.toast` 60 | §2.4 |

## File layout

```
frontend/src/features/admin/status/{api,hooks,status}.ts, status.test.ts      (moved, A1)
frontend/src/features/offline/pending-removals.ts        (+ .test.ts)
frontend/src/features/offline/save-next.ts              (useSaveNext, only if missing)
frontend/src/features/offline/auto-download.ts          (+ .test.ts)
frontend/src/features/offline/storage-meter.ts          (+ .test.ts)
frontend/src/features/offline/download-queue.ts         (run store, only when A5 finds the run state inside the series-page hook; tests extended)
frontend/src/features/app/changelog.ts                  (+ .test.ts)
frontend/src/config/web-version.ts
frontend/src/skins/cinematic/screens/downloads/
  DownloadsScreen.tsx  StorageMeter.tsx  ActivityBlock.tsx  NarrationBlock.tsx  SavedLibrary.tsx
  SeriesBlock.tsx  ChapterRow.tsx  StoragePanel.tsx  DownloadsEmpty.tsx  keys.ts
frontend/src/skins/cinematic/screens/index/
  IndexScreen.tsx  ProfileBlock.tsx  IndexSection.tsx  IndexRow.tsx
frontend/src/skins/cinematic/screens/status/
  StatusScreen.tsx  SummaryBanner.tsx  BackendCard.tsx  CheckerCard.tsx  RecentChecks.tsx  SourceHealthTable.tsx  keys.ts
frontend/src/skins/cinematic/overlays/WhatsNew.tsx
frontend/src/skins/cinematic/overlays/WorkerUpdateToast.tsx
frontend/src/skins/cinematic/Shell.tsx                   (mounts WhatsNew auto-open, WorkerUpdateToast, useAutoDownloadNewChapters)
frontend/src/skins/cinematic/index.ts                    (wire the three screens, remove them from PENDING)
frontend/src/app/(preview)/skin-preview/[skin]/primitives/page.tsx   (the web/04 gallery: add a [data-gallery="worker-update-toast"] entry)
frontend/e2e/cinematic/web-17-downloads-index-status.spec.ts
docs/redesign/proof/web-17/                              (plan.md, routes.txt, screenshots, report.md)
```

The route files under `frontend/src/app/(app)/downloads/`, `more/` and `admin/status/` stay thin.

## Commit plan (small commits, push after each)

1. `refactor(web/17): move system status logic into features/admin` (A1, no pixel change).
2. `feat(web/17): shared offline helpers for removal, auto-download, meter and settings` (A2–A6).
3. `feat(web/17): changelog helpers and the web version` (A7–A8).
4. `feat(web/17): cinematic downloads, the offline edition`.
5. `feat(web/17): cinematic index`.
6. `feat(web/17): what's new and the edition update toast`.
7. `feat(web/17): cinematic system status`.
8. `test(web/17): e2e checks and proof screenshots`.

`git add` exact paths; commit messages carry **no** `Co-Authored-By`, no "Generated with" line and no AI attribution; `git push origin feat/vps-slim-source-native:master` after each. Never commit secrets, `.env*` or `.claude/`.

## Acceptance criteria

- [ ] `downloads`, `index` and `status` are gone from the Cinematic `PENDING` set; the completeness test passes.
- [ ] The status logic lives in `features/admin/status/`, the legacy status page still works, and its tests pass from the new place.
- [ ] Downloads shows the meter line and three-segment bar with the floor tick, the activity rows with `Stop` and `Stop all`, the saved library by series (largest first) with expandable chapter rows and every web status caption, retention, protection, both new switches, `BY SERIES`, `Free up space`, `Remove all downloads` with the inline armed confirm and `Reset offline storage` with the armed dialog.
- [ ] Removing a chapter shows `REMOVING…` and an 8 s Undo toast; Undo keeps the chapter; expiry sends `mm-offline/remove-chapter`; closing the tab (`pagehide`) flushes pending removals (Vitest with fake timers, plus one e2e check).
- [ ] Desktop has no tabs and the aside in columns 9–12; phones have `SAVED · STORAGE` tabs driven by `?tab=storage`; `/downloads?tab=storage` on desktop focuses the aside header.
- [ ] With the gate closed, a mature series saved earlier does not appear in any list, count or badge, the meter total still includes its bytes, and nothing mentions hidden files; reopening the gate brings it back at once.
- [ ] The auto-download planner and runner follow A4 (unread only, notify on, not saved, 250 MB floor, max 20) and toast the count.
- [ ] The Index shows the profile block, the content-mode toggle, the four sections with the listed values, two columns with a column rule from 900 px, and the leader draw once per session; admin rows are absent for non-admins; Android-only rows are absent.
- [ ] What's new opens from the Index as a sheet on phones and a dialog on desktop, lists every changelog entry with its folio and `LATEST` badge, opens automatically once after a new release version, and shows its loading and unavailable states; the edition-update toast stays until `Reload` or dismissal.
- [ ] System status shows the typed summary headline tinted by the worst state, the backend and checker credits, recent checks, the worst-first source-health table with collapsible errors, the live `LIVE · 15 S` folio, per-card loading and error states, and the non-admin notice; keys `r`, `c`, `j`, `k`, `Enter` work.
- [ ] Reduced motion per section F (the e2e spec emulates `reducedMotion: "reduce"` and asserts the Index leaders are at rest, the Status headline is complete at once, and the Downloads meter width changes with no transition).
- [ ] Keyboard: every control is reachable in reading order with the double focus ring; the listed keys work; route focus lands on each `h1`; titles read `Downloads · ManhwaManiacs`, `Index · ManhwaManiacs`, `System status · ManhwaManiacs`.
- [ ] Hit targets: at 390 × 844 every interactive element is at least 44 × 44 CSS px (checked by the e2e spec on all three screens and the What's new sheet); at 1440 × 900 at least 32 × 32.
- [ ] Contrast: `ink.45` only on `paper.0`; on `paper.1` error blocks, sheets, dialogs, the mood grade and banner strips those roles render `ink.60`.
- [ ] Per-skin difference: only `src/skins/cinematic/**` and skin-neutral `features/**` / `config/**` modules changed; the Glass skin still maps these ScreenIds to `PENDING`; no Cinematic file imports Glass or legacy components (lint passes).
- [ ] `npm run typecheck`, `npm run lint` (0 errors, 0 warnings), `npm run test` and `npm run build` pass in `frontend/`; every baseline test still passes.

## Verification

From `/srv/manhwamaniacs/dev/ManhwaManiacs`, one at a time, `free -m` first (stop if `available` < 1024 MB):

```bash
free -m
node design/build.mjs --check
cd frontend
npm run typecheck
npm run lint            # baseline: exit 0, 0 errors, 0 warnings
npm run test            # every baseline test plus the new ones
free -m
npm run build           # baseline: exit 0; nothing else running
```

This step changes nothing under `mobile/` or `backend/`. Prove it on your own commits, not on a range (the mobile, backend and shared sessions push to the same branch in parallel, so a range diff shows their work too): `for c in <each commit SHA you made in this step>; do git show --name-only --format= "$c"; done | grep -E '^(mobile|backend)/'` must print nothing. The other suites are therefore not re-run here; their sessions run them and keep the baseline: `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze` (No issues found), `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter test` (all 2012 passed) and `cd backend && .venv/bin/python -m pytest -q --no-header`.

**Visual proof.** Start the dev stack with `free -m && backend/scripts/dev_stack.sh start` (the dev stack of `backend/scripts/README-dev-stack.md`: uvicorn on 127.0.0.1:8010 against the dev SQLite under `/srv/manhwamaniacs/dev/data/`, never production data; the script already sets `MM_NOVELS_ENABLED=true`, turns rate limits off and leaves the AI key unset; run `backend/scripts/dev_stack.sh seed` once if the `demo` account does not exist yet), then the web client with `cd frontend && free -m && NEXT_PUBLIC_API_URL=/api BACKEND_INTERNAL_URL=http://127.0.0.1:8010 npx next dev -p 3010` (both variables are required: without `NEXT_PUBLIC_API_URL=/api` the browser calls `http://127.0.0.1:8000` directly (`src/config/env.ts`), and without `BACKEND_INTERNAL_URL` the `/api` rewrite in `next.config.ts` targets port 8000). Sign in as the seeded admin demo account, save two chapters of a demo series from its series page so Downloads has content, then write `docs/redesign/proof/web-17/routes.txt`:

```
/downloads
/downloads?tab=storage
/more
/admin/status
```

and capture at 1440 × 900 and 390 × 844, plain and with the grid overlay:

```bash
free -m
cd frontend
MM_PROOF_USER=<demo user> MM_PROOF_PASSWORD=<demo password> node scripts/proof.mjs --step web-17 --skin cinematic --routes /srv/manhwamaniacs/dev/ManhwaManiacs/docs/redesign/proof/web-17/routes.txt --grid
free -m
MM_PROOF_USER=<demo user> MM_PROOF_PASSWORD=<demo password> node scripts/proof.mjs --step web-17 --skin cinematic --routes /srv/manhwamaniacs/dev/ManhwaManiacs/docs/redesign/proof/web-17/routes.txt --reduced
```

The credentials are the seeded demo account's, from `backend/scripts/README-dev-stack.md` (never hard-code them in a file). `--grid` saves a `-grid` copy of every shot and `--reduced` a `-reduced` set; both viewports (1440 × 900 and 390 × 844) are captured by default.

Then, from `frontend/`:

```bash
free -m
E2E_BASE_URL=http://127.0.0.1:3010 MM_PROOF_USER=<demo user> MM_PROOF_PASSWORD=<demo password> npx playwright test e2e/cinematic/web-17-downloads-index-status.spec.ts
```

The spec signs in with `signIn` imported from `scripts/proof.mjs`, sets the `mm-skin-debug=cinematic` cookie and saves extra screenshots to `docs/redesign/proof/web-17/state-*.png`: Downloads empty, checking, offline (`context.setOffline(true)`), a pending removal with its Undo toast, the What's new sheet and dialog (including the automatic opening, forced by `page.addInitScript(() => localStorage.setItem("mm.whatsnew.seen", "0.0.0"))`), the edition-update toast (render `WorkerUpdateToast` with a forced waiting state as a new `[data-gallery="worker-update-toast"]` entry of the `web/04` primitives gallery at `/skin-preview/cinematic/primitives`, and screenshot that element), System status as a non-admin account that the spec creates in its setup (`POST /auth/register` with the username `proof-reader` and a password generated at run time; the dev stack runs with registration open) and deletes as the admin in its teardown through the endpoint `useDeleteMember` calls and with `/api/health` mocked to fail. It also asserts the hit-target, focus, title and reduced-motion checks above. Stop `next dev` and the dev stack afterwards.

## Report back

Reply with:
1. The acceptance checklist, each box ticked or explained.
2. Commits (short SHA and message), confirmed pushed.
3. `docs/redesign/proof/web-17/` with the file count and the states captured per screen.
4. Test counts: Vitest passed / failed / total vs the baseline total, lint errors and warnings, typecheck, `next build` result and time, e2e passed / failed.
5. The lowest `free -m` available value seen.
6. Open issues: hooks an earlier step did not deliver, anything the service worker could not report, deviations with reasons.

Next prompt: `docs/redesign/prompts/web/18-cinematic-settings-and-edition-restart.md`
