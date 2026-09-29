# Web Glass You, About, admin settings and System status

Track: web · Order 98 · Depends on: `docs/redesign/prompts/web/39-glass-settings-and-skin-switch.md` · Runs in parallel with: `docs/redesign/prompts/mobile/40-glass-you-about-admin-status.md` · Proof folder: `docs/redesign/proof/web-40/`

## Goal

Finish the "You" branch of the Glass skin on the web client (`frontend/`): the **You hub** at `/more` (ScreenId `index`) with its profile block, Reading, Wrapped and Circle cards, grouped lists, About group and the Orb lift signature moment; the remaining **Settings sections** that `web/39` did not build (Notifications for admins, Security, Members, Storage, Backup and restore, Diagnostics, and the **Open-source licences** sheet with every OFL font and CC0 artwork and sound credit); and **System status** at `/admin/status` (ScreenId `status`) with its summary banner, cards and the painted health beads. Every state of every screen, desktop (sidebar frame, 1024 px and up), tablet (768–1023 px) and mobile web (below 768 px), keyboard access, reduced motion and Solid glass. When you finish, the ScreenIds `index` and `status` leave the Glass `PENDING` set. Glass stays reachable only through the debug row until `release/01`. The server section (§8.25.11) exists only in the phone apps; the web never renders it.

## Read first

Read these completely before planning. `glass/DESIGN.md` is binding; where this file and `glass/DESIGN.md` disagree, `glass/DESIGN.md` wins and you name the conflict in your report.

1. `docs/redesign/inventory/00-decisions.md` (all of it).
2. `docs/redesign/stack-decision.md` §2.2 (folder layout and the lint boundary), §2.4 (skin storage), §2.6 (shared logic lives in `features/`).
3. `docs/redesign/glass/DESIGN.md`:
   - **§8.24 You and About**, **§8.25** (the structure: search, section list, footnote, capability hiding, server-backed section states), **§8.25.6 Notifications**, **§8.25.7 Security**, **§8.25.8 Members**, **§8.25.9 Storage**, **§8.25.10 Backup and restore**, **§8.25.12 Diagnostics**, **§8.25.14** (About and the Open-source licences sheet), **§8.26 System status**. Read every line.
   - §8.0.1 (frames), §8.0.2 (the You destination), §8.0.3 (rows `index`, `settings`, `status`; the settings slugs `notifications`, `security`, `members`, `storage`, `backup`, `admin`, `diagnostics`, `about`; the sheet id `licenses`), §8.0.6 (global keys, the Single-key switch), §8.0.7, §8.0.8 (first-paint attributes, the debug row "Preview Glass skin", server capabilities), §8.0.9 (sign-out flows), §8.0.10 (the error-code table rows `invalid_credentials`, `weak_password`, `rate_limited`, `cannot_manage_self`, `forbidden`, `check_already_running`, `db_busy`).
   - §2.1.1–§2.1.4 (Graphite ramp, text and fill roles incl. the backing-disc rule and `wellOnGlass`, Iris, semantic colours), §2.3, §2.6, §3.2 (roles `largeTitle`, `title1`, `title2`, `title3`, `headline`, `body`, `callout`, `subhead`, `footnote`, `caption1`, `mono`), §4.2 (springs), §4.7 (timed values), §4.8 (the entrance wave), §4.10 rows **Orb lift**, **Row pulse**, **Bead pulse**, **Bead flicker**, **Hold fill**, **Error shake**, **Liquid spinner**, **Count pop**, §4.11.
   - §5.2 events `toggle.on`, `toggle.off`, `detent.tick`, `detent.magnet`, `detent.limit`, `select`, `hold.ramp`, `hold.done`, `delete.confirm`, `refresh.arm`, `refresh.done`, `success`, `warning`, `error`, `nav.push`; §6 cues `tick`, `toggle-on`, `toggle-off`, `download-done`, `error`, `droplet`.
   - §7.1 (buttons, HoldToConfirm), §7.3 (fields, the Stepper row), §7.6, §7.7 (Stat card, the health bead on source rows), §7.10 (sheets and their desktop forms: `licenses` is a 560 px window), §7.11, §7.12, §7.17 (grouped lists, row anatomy, 30 px icon tiles), §7.18, §7.19, §7.20 (badges incl. Admin / You / This device), §7.21 (the interval slider), §7.22, §7.24 (the object lens and its glyph table: `shield`, `wifi-slash`, `warning-circle`), §7.26 (profile orbs, the goal ring), §7.30 (StatusCapsule, InlineNotice), §7.33 (pull to refresh: You and Members are in its list), §7.34 (swipe rows on Members and sessions), §7.35 (the bulk toolbar geometry the "Unsaved changes" bar copies), §7.36 (content-mode switch), §7.39 (sparkline).
   - §12.7 (what the art and sound credits must say), §9.4.2 (the soundscape recordings are CC0 and listed in About → Licences), §8.7 step 5 (the onboarding art credit line).
   - §14.1–§14.7, §14.11; §15.2 (web structure; `copy/settings-index.ts`), §15.5 (the device keys), §15.7 (the budget table; "Glass layers on screen"), §15.8 (the motion-timings overlay, the calibration page).
4. `docs/redesign/inventory/web.md` §5 (M1–M6, the legacy More hub), §6.4 (SG18–SG24), §6.6 (SG29–SG39), §15 (AS1–AS10), §16 (BK1–BK5), §17 (MB1–MB7), §18.1 rows A5–A9 and §18.10 rows A100, A107–A118. Every row must have a Glass counterpart; write the mapping to `docs/redesign/proof/web-40/inventory-map.md`.
5. `docs/redesign/inventory/capabilities.md` §3 (sessions), §4 (account administration), §22 (backup), §23 (app distribution, system status).
6. `docs/redesign/00-baseline.md` (lint 0/0, build 0/0; the RAM figures).
7. `docs/redesign/prompts-plan.json`: the `web/00` entry (its `TRACK RULE`) and this file's entry.
8. Code you build on (read before planning):
   - `web/39`'s Glass Settings screen: `ls frontend/src/skins/glass/screens/settings/` and `frontend/src/skins/glass/copy/settings-index.ts` (the section registry, the icon-tile colour per section, the search index). New sections plug into that registry; never build a second section list.
   - `web/25`–`web/29` Glass code: `grep -n "^export" frontend/src/skins/glass/motion.ts frontend/src/skins/glass/haptics.ts frontend/src/skins/glass/sounds.ts`, `ls frontend/src/skins/glass/primitives frontend/src/skins/glass/primitives/cards`. Expect `play()`, `GlassSurface`, `useLb`, `AmbientField`, `Button`, `IconButton`, `HoldToConfirm`, `TextField`, `SearchField`, `Segmented`, `Chip`, `StatCard`, `HealthBead`, `ProfileOrb`, `GoalRing`, `LetterReveal`, `Skeleton`, `Progress`, `LiquidProgress`, `Badge`, `Keycap`, `Tooltip`, `Sheet`, `useSheetParam`, `Alert`, `confirmAlert`, `showToast`, `Slider`, `Switch`, `Stepper`, `Menu`, `InlineNotice`, `StatusCapsule`, `PullToRefresh`, `ContentModeSwitch`, `ScrollEdge`, `HardEdge`, the `web/28` lists, `SwipeRow`, `ObjectLens`, `copy/errors.ts`, the `Chart` sparkline, and `web/29`'s Shell (dock with `data-dock-tab` markers, sidebar account menu with "Switch account", the `?sheet=whats-new` overlay, the purge).
   - The shared data layer (legacy hooks you call, never their components): `features/auth` (`useCurrentUser`, `useSessions`, `useChangePassword`, `useRevokeSession`, `useLogout`, `useLogoutAll`), `features/admin` (`useMembers`, `useSetMemberActive`, `useDeleteMember`, and `features/admin/status/` moved there by `web/17`: `useBackendHealth`, `useSourceHealth`, the summary logic in `status.ts`), `features/backup` (`backupApi`, `useBackupStatus`, `useExportBackup`, `useImportBackup`, `useCancelPendingRestore`), `features/updates` (`useUpdateSettings`, `useUpdateSettingsMutation`, `useUpdateRuns`, `useManualCheck`, `useUnreadNotificationCount`), `features/library/hooks.ts` (`useStatistics`), `features/profiles`, `features/offline` (download counts), `features/app/` (`useChangelog`, `useServerVersion` from `web/17`/`web/18`), `frontend/src/config/web-version.ts` (`WEB_VERSION`), the service-worker update hooks `web/18` used (`grep -rn "useWorkerUpdate\|applyWorkerUpdate" frontend/src`), `features/preferences/api.ts` (`source_cache_ttl_minutes`), and the Circle hooks `web/22` added (`grep -rln "circle/members\|circle/feed\|profiles/.*sharing" frontend/src/features`).

## Preconditions (check before writing the plan)

Stop and report which one failed if any of these is false:

- `git branch --show-current` prints `feat/vps-slim-source-native`. Run `git status --porcelain` and note files other sessions have modified; never stage them.
- `git log --oneline -40` shows the `web/39` commits; `grep -n "index\|status" frontend/src/skins/glass/index.ts` shows both ScreenIds still in `PENDING`; `settings` is no longer in `PENDING`.
- `frontend/src/skins/glass/copy/settings-index.ts` exists and lists the sections of §8.25.1 to §8.25.16.
- `node design/build.mjs --check` passes.
- After the RAM guard, `cd frontend && npm run test 2>&1 | tail -5`: record the Vitest file and case counts (your floor).

## Skills to invoke

1. `superpowers:writing-plans` before any code: write the plan to `docs/redesign/proof/web-40/plan.md`, one task per Scope item, and commit it with the proof.
2. `superpowers:test-driven-development` for every pure module below (Vitest first).
3. `superpowers:subagent-driven-development` to run the plan (or `superpowers:executing-plans` inline). At most 5 implementer subagents, split by item group (A–B; C; D–E; F–G; H–I). Start each subagent prompt with a scope lock that names its files, pass `model: "opus"` explicitly, run builds, tests and browsers one at a time, and verify each subagent's work against `git status` and `git diff`, never against its report alone.
4. `frontend-design:frontend-design` for the web UI, then `impeccable:impeccable` and `taste-skill:taste-skill` on the proof screenshots. A critique never overrides a token, duration, copy string or layout rule that `glass/DESIGN.md` fixes.
5. `superpowers:verification-before-completion` before you claim anything is done.

## Ground rules

- **Track rule.** Work in `frontend/` only (plus `docs/redesign/proof/web-40/`). Do not edit `design/`, `brand/`, `mobile/` or `backend/`; a missing token is reported, not added.
- **Skin boundary** (the eslint rule): files under `src/skins/glass/**` import only `@/features/**` (never `@/features/*/components/**`), `@/lib/**`, `@/services/**`, `@/stores/**`, `@/types/**`, `@/config/**`, `@/skins/contract.generated` and their own `skins/glass/**`. Never `@/components/**` or `@/skins/cinematic/**`.
- **Shared logic in `features/`**, skin-neutral (no Glass copy or tokens), each module with a Vitest test. Vitest runs `src/**/*.test.ts` in the `node` environment, so logic lives in `.ts` modules with injected dependencies.
- **Paths** come from `ROUTES` in `frontend/src/skins/contract.generated.ts` (use the generator's builder names). Every named move goes through `play()`; an unknown name throws in development.
- **Copy** comes from `glass/DESIGN.md` verbatim; errors from `copy/errors.ts` keyed by `code`.
- Never edit `backend/connectors/`. Never touch production containers or `/srv/manhwamaniacs/{app,data}`.

## Scope: deliver every item below

Sections cited are `glass/DESIGN.md`. Sizes are CSS px and minimums. Web "hit 44" is the element's own box at 390 × 844. Text on T4/T5 glass bodies is `onGlass`; state glyphs on glass sit on the `rgba(0,0,0,0.60)` backing disc (§2.1.2).

### A. Shared data-layer additions (skin-neutral, Vitest-tested)

1. `frontend/src/features/library/daily-goal.ts`: if `grep -rn "daily_goal_minutes" frontend/src/features` finds no hook, add `useDailyGoal()` → `{ goalMinutes: number | null, todaySeconds: number, met: boolean, loading: boolean }` from the active profile's `daily_goal_minutes` (`useProfiles`) and `GET /library/statistics?days=1&tz_offset_minutes=` (the existing `useStatistics(1)`; `todaySeconds = daily.at(-1)?.seconds_read ?? 0`), `staleTime` 5 min, refetched on window focus; `met = goalMinutes !== null && todaySeconds >= goalMinutes × 60`. Pure helper `goalProgress(todaySeconds, goalMinutes)` → a fraction clamped to 0–1 (0 when no goal). Test the helper (no goal, half, exactly met, over). `web/42` adds the live updates from `POST /reader/progress`.
2. `frontend/src/features/backup/api.ts`: if `exportDatabase` takes no options, give it `exportDatabase({ includeCache }: { includeCache?: boolean } = {})`, which appends `?include_cache=true` only when `includeCache` is true (the backend's `export_backup(include_cache: bool = False)` already accepts it); pass the option through `useExportBackup`. Test the URL for both values.
3. `frontend/src/features/you/you-cards.ts` (new folder, skin-neutral): `wrappedCardYear(now)` → the current year from 1 to 31 December local, the previous year from 1 to 31 January, else `null`; `weekSummary(daily)` → `{ seconds, chapters, sparkline: number[7] }` from the last 7 `daily` entries (seconds for the sparkline; missing days as 0); `formatDuration(seconds)` → "3 h 12 min", "45 min", "0 min". Tests: 30 Nov → null, 1 Dec → 2026, 31 Jan 2027 → 2026, 1 Feb → null; a 5-day `daily` padded to 7; the three duration forms.
4. `frontend/src/features/app/licenses.ts` + `frontend/scripts/build-licenses.mjs` + `frontend/src/features/app/licenses.generated.json` (the licence data of the Open-source licences sheet, §8.25.14):
   - The script (Node 22 stdlib only; `npm run licenses` added to `frontend/package.json`) writes `licenses.generated.json` = `{ generatedAt, groups: [{ kind: "fonts" | "web" | "art", items: [{ name, version, licence, text }] }] }`, deduplicated by name and version, sorted by name. It is run by hand and its output is committed; it never runs inside `npm run build` (the production image builds from `frontend/` alone).
   - **Web packages:** `npm ls --json --all --omit=dev` from `frontend/`, flattened; for each package, `licence` from its `node_modules/<name>/package.json` (`license` string, or `license.type`), `text` from the first file in the package folder matching `/^(licen[cs]e|copying)(\.|$)/i`, else the line "{licence} (the package ships no licence file)".
   - **Fonts:** `frontend/licenses/fonts.json` = `[{ family, file }]`, one entry per family passed to `next/font/google` anywhere in `frontend/src` (list them with `grep -rhn "from \"next/font/google\"" -A3 frontend/src`), both skins included; each `file` is `frontend/licenses/fonts/<slug>.OFL.txt`, fetched once in this step with `curl -fsSL https://raw.githubusercontent.com/google/fonts/main/ofl/<dir>/OFL.txt` (the folder name is the family lower-cased without spaces, for example `ofl/googlesansflex/`, `ofl/literata/`; confirm each with `curl -fsI` first) and committed. Every font item has `version: "Google Fonts"` and `licence: "OFL-1.1"`.
   - **Artwork and sounds:** `frontend/licenses/CC0-1.0.txt`, fetched once from `https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt` and committed; fixed CC0 entries for each folder that exists in the repo: `brand/onboarding/styles/` → "Onboarding art" ("Onboarding art © ManhwaManiacs contributors, CC0"), `brand/demo/` → "Demo covers and pages" ("Procedural demo art made for ManhwaManiacs, CC0"), `design/sounds/glass/` → "Glass UI sounds" ("Synthesized with sox for ManhwaManiacs, CC0"); plus one entry per row of `backend/media/soundscapes/SOURCES.md` when that file exists (parse its Markdown table by its header row: the file name as `name`, the URL and licence into `text` above the CC0 text). The script reads other folders but writes only the JSON.
   - `licenses.ts`: `loadLicenses()` = `import("./licenses.generated.json")` (a dynamic import, so the data never enters the first-load bundle); `filterLicenses(groups, q)` (case-insensitive over name and licence; empty groups dropped); `LICENCE_TAGS` = `MIT, BSD-3-Clause, Apache-2.0, OFL-1.1, CC0` plus any other value shown as-is. Test (`licenses.test.ts`, reading the JSON through `fs`): every key of `frontend/package.json` `dependencies` appears in the `web` group; every font item's text contains "SIL OPEN FONT LICENSE Version 1.1"; every `art` item's licence is `CC0`; `filterLicenses` drops empty groups.

### B. The You hub (`frontend/src/skins/glass/screens/you/`, ScreenId `index`, §8.24)

Wire `screens.index` to `YouScreen` and remove `index` from `PENDING`. `document.title` "You · ManhwaManiacs". Phone: tab root of dock tab 4 (large title "You", letter reveal once per session, §10.1 placement 1). Desktop and tablet: a page at every width (no viewport redirect), the profile block and the cards in two columns at most 880 px wide and centred, the grouped lists beneath at the same width.

1. **Profile block:** `ProfileOrb` 72 wearing `GoalRing` (`useDailyGoal()`; no ring without a goal); name `title1` (one line, ellipsis, full name in the accessible name); "@yash · Administrator" in `footnote` `label2` ("@yash" alone for non-admins, from `useCurrentUser`); the secondary button "Switch profile", which navigates to `ROUTES.profiles` inside `startTransition` with the orb wrapped in `<ViewTransition name={"profile-orb-" + profileId}>` (if `web/30`'s picker orb for the active profile does not carry the same name, add the `name` prop there, one line); `ContentModeSwitch variant="sidebar"` (rendered only when novels are enabled).
2. **Reading card** (`surface1` slab, radius 26, padding 16, the whole card a link to `ROUTES.numbers`): a flame glyph at 44 px (Phosphor `flame` Fill in `streak` `#FF8A3D`; `web/42` replaces it with the physics `StreakFlame` at the same size and slot), "12-day streak" in `headline` (the unlit-wick line "Read today to start a streak" when the streak is 0), "This week: 3 h 12 min · 14 chapters" (`weekSummary`, `formatDuration`) in `footnote` `label2`, and the 7-day `Chart` sparkline (24 px tall, `iris500`). Data: `useStatistics(7)`.
3. **"Your {year} in chapters" card:** rendered only when `wrappedCardYear(now)` is not null; a tall `surface1` card with the year in `display` 44/48 and "Your 2026 in chapters", linking to `ROUTES.annual(year)`.
4. **Circle card:** up to five presence orbs (32 px, bloom ring rules of §9.3.1: reading now breathing, active today static at 40 %, away none) and the last three feed items as one-line rows (actor orb 24, the sentence in `footnote`), the whole card linking to `ROUTES.circle`. For a profile whose `activity` sharing is off: the line "Read together: share what this profile reads with the other readers on this server." and a plain button "Turn on sharing" → `ROUTES.settings("circle")`. Data: the `web/22` Circle hooks (members and feed); if a call has no hook, add it in `frontend/src/features/circle/` with a test.
5. **Grouped lists** (§7.17 anatomy, 30 px icon tiles; tile colour and glyph from `copy/settings-index.ts`, and for entries that file lacks: `iris600` for Library rows, `surface3` for Administration and About rows, glyph 18 `#FFFFFF`):
   - **Library:** Updates (count badge from `useUnreadNotificationCount`), For you, Dialogue search (Manga mode only; hidden without the `ocr` capability), Collections, History, Bookmarks, Downloads (count badge of queued + downloading + failed from `features/offline`). Rows hidden by the server's `capabilities` flags stay hidden.
   - **Settings:** Appearance and skin, Reader, Content (18+), Circle and privacy, AI and recaps, Sound and haptics, Notifications (admin only), Security, Storage, Backup (admin only), Diagnostics, Shortcuts. Each opens `ROUTES.settings(slug)` with the §8.0.3 slugs. Server is never rendered on the web.
   - **Administration** (admin only): System status → `ROUTES.status`, Members → `ROUTES.settings("members")`.
   - **About:** What's New (opens `?sheet=whats-new`, the `web/29` overlay); the version row "ManhwaManiacs 3.5.0 (57)" (`useServerVersion()`) with the second line "Web 2.6.1" (`WEB_VERSION`) in `footnote` `label2`; the update row (web: "Up to date" in `label2`, or "A new version is ready" with a plain "Reload" button through the service-worker update hooks; the Android APK and SideStore rows are app-only); Licences → `/settings/about?sheet=licenses`.
   - **Switch account** (reuse the mechanism `web/29` built for the sidebar account menu: signs out and opens Login with the username empty) and **Sign out** (destructive plain; `confirmAlert` "Sign out?" / "You'll need to sign in again on this device." with "Cancel" and the destructive "Sign out"; `useLogout`, then `/login`).
6. **Orb lift (signature, phone frame only):** on the first arrival on `/more` per session per profile (`sessionStorage['mm.glass.orbLift']` holds the profile id), a fixed-position copy of the orb starts at the dock's You tab icon rect (`[data-dock-tab="you"]`), flies to the profile block's orb rect on `zoom` (k 125.9, c 21.09; `play("Orb lift")`), then the real orb shows and the copy unmounts; later arrivals, desktop and tablet use the 120 ms tab cross-fade. Reduced motion: a 200 ms cross-fade.
7. **Pull to refresh** (touch, §7.33): refetches the statistics, Circle and version queries; `r` on desktop and a "Refresh" item in the nav row's ⋯ menu.
8. **States:** loading (the profile block as a skeleton: 72 px circle, two text bars; each card as its own skeleton), offline (the "Offline" capsule in the nav row; settings rows stay usable; the Reading and Circle cards show the `warning` `StatusCapsule` "Saved copy · 2 h" over their last cached data, or the per-card offline line "Needs a connection"), per-card error (a 120 px inline card "Couldn't load this" + "Retry" plain button, never a full-screen error).
9. **Keys:** `r` refresh, `g ,` Settings (global), arrows move through the rows (roving focus inside each group), Enter opens.

### C. Settings: Notifications (admin, `notifications`, §8.25.6)

Plug into `web/39`'s section registry; hidden for non-admins (the row, the search index entry and the direct URL, which shows the object lens `shield` "Administrators only" with "Back").

1. **Schedule strip:** three cells in a `surface1` slab (radius 20): "Last check 12 min ago", "Next check in 18 min" (overdue: `warning` "Overdue by 7 min" with a plain link "See System status" → `ROUTES.status`), "Every 30 min". From `useUpdateSettings` and `useUpdateRuns`.
2. **Switches** (`Switch`, `toggle.on`/`toggle.off`): "Check for new chapters automatically" (caption "Nothing is checked and nothing notifies while this is off."), "Check when the server starts", "Notify me about new chapters" (caption "The master switch. Turn one series off from its own page.").
3. **Interval slider** 5 to 120 min, step 5, `detent.tick` per step, a value magnet at 30 (within 30 % of one step's spacing, `detent.magnet`, `rigid(0.4)`), value in `mono` 13 trailing ("30 min"). If `web/27`'s `Slider` has no `magnet` prop, add `magnet?: number` to `Slider.tsx` and a case to `slider-math.test.ts`.
4. **"Source catalogue cache" `Stepper`** 5 to 1,440 min, default from the server (`source_cache_ttl_minutes`), helper "How long a browsed catalogue is reused before asking the source again."
5. **Draft then save:** edits collect in the floating "Unsaved changes" bar with "Discard" (plain) and the tinted "Save": phones in the bottom accessory slot; desktop 52 px tall, fixed at `bottom: 24px`, centred on the content column, max width 720 px, `glassRegular`; it sets `html[data-bottom-bar]` while visible. Reuse the bar if `grep -rn "Unsaved changes" frontend/src/skins/glass` finds one; otherwise build `primitives/UnsavedChangesBar.tsx` (with a gallery entry). Save → `PUT /updates/settings` (`useUpdateSettingsMutation`) and `PUT /settings { source_cache_ttl_minutes }` → toast "Saved"; a failure shows the inline error above the bar with the Error shake on "Save". Leaving the section with a dirty draft opens `confirmAlert` "Discard your changes?" ("Keep editing" / destructive "Discard").
6. **States:** loading (5 row skeletons, 52 px), error (inline block + "Try again"), offline (the notice "These settings need a connection", controls disabled).

### D. Settings: Security (`security`, pushed page, §8.25.7)

1. **Change password:** `TextField`s Current, New (helper "At least 8 characters"), Confirm, each with a trailing 44 px reveal `IconButton` (`eye` / `eye-slash`, `aria-pressed`, label "Show password", `aria-controls`). Client errors: "Enter your current password", "Enter a new password", "At least 8 characters", "Password is too long" (over 4,096), "The new passwords don't match", "Your new password must be different". Server: `invalid_credentials` → inline on Current "That isn't your current password.", `error` haptic + the 6 px field shake, focus back in Current, never the §8.0.9 signed-out flow; `weak_password` → the server's `message` under New; `rate_limited` → the button reads "Try again in 42 s" in `mono`, counting down from `Retry-After`, disabled until 0. Primary "Change password" (`useChangePassword`, three-dot loading). Success toast "Password changed. Your other devices were signed out; this one stays signed in."
2. **Where you're signed in:** a plain list (§7.17) of `useSessions` rows: device glyph (`device-mobile` for "ManhwaManiacs app", `browser` otherwise, `question` for unknown), label ("ManhwaManiacs app", "Safari on macOS", "Unknown device"), the "This device" badge (§7.20), "Last used 3 h ago · 10.0.0.2", "Signed in 12 Sep · expires 11 Dec" (`footnote` `label2`); a refresh `IconButton` (`arrows-clockwise`, spins while fetching). Other rows: swipe left (`SwipeRow`, coarse pointers) or ⋯ → "Sign out this device" → `confirmAlert` "Sign out this device?" / "It will have to sign in again." (`useRevokeSession`); the current row → "Sign out" → the same alert as B5.
3. **Sign out everywhere:** a `danger` `InlineNotice` "Every device, including this one, will have to sign in again. Downloaded chapters stay." and a `HoldToConfirm` "Sign out everywhere" (danger variant, 1,200 ms: 200 ms start + 1,000 ms fill, `hold.ramp`, `hold.done`). Its `onRequestConfirm` (the click path) opens an `Alert` with the acknowledgement `Switch` "I understand this signs me out here too"; the destructive "Sign out everywhere" in the alert is enabled only when the switch is on. Both paths → `useLogoutAll`, then `/login`.
4. **States:** sessions loading (4 row skeletons), error (inline + "Try again"), empty ("No active sessions").

### E. Settings: Members (admin, `members`, pushed page, §8.25.8)

1. **Explainer** above the list: "Registration is open on this server. Deactivating keeps an account's data and signs it out everywhere; deleting removes the account and everything it owns."
2. **Phone** (below 768 px): a grouped list, one row per account (`useMembers`): "@aarav", badges Admin · You · Deactivated, "Joined 27 Jul · last seen 2 h ago · 2 sessions" (or "Never signed in"); ⋯ menu and swipe actions: Deactivate / Reactivate (`useSetMemberActive`, toast "Deactivated @aarav" / "Reactivated @aarav"), Delete. The owner's own row: actions disabled, subtitle "You can't deactivate or delete your own account".
3. **Desktop and tablet:** a table (min width 640 px, inside its own `overflow-x: auto` container) with columns Member, Status, Joined, Last seen, Sessions, Actions; the own row tinted `iris600` at 6 %; actions as M 44 secondary buttons (fine pointer: 32 px visual, 44 px hit column).
4. **Delete:** an `Alert` "Delete @aarav?" / "This removes their profiles, library, progress, bookmarks and everything else they own. It can't be undone." holding a danger `HoldToConfirm` "Hold to delete @aarav" and "Cancel"; `delete.confirm` on completion; `useDeleteMember`; toast "Deleted @aarav". A refused action shows `cannot_manage_self` or `forbidden` with the `copy/errors.ts` line.
5. **Footer:** "2 other accounts" (`footnote` `label2`) + a plain "Refresh"; pull to refresh on phones.
6. **States:** loading (3 row skeletons), error (inline + "Try again"), empty ("Only your account so far").

### F. Settings: Storage (`storage`, §8.25.9)

On the web, Storage opens Downloads → Storage. The Settings row links to `/downloads?tab=storage`; a direct visit to `/settings/storage` is a server redirect: at the top of the server part of the Glass settings screen (the component the thin route renders, before any Suspense boundary; add a small server wrapper file if the screen is entirely `"use client"`), `section === "storage"` calls `redirect("/downloads?tab=storage")` from `next/navigation`, so no Settings content ever renders. (If a `loading.tsx` above the page makes Next stream the redirect as a client redirect instead of a 307, that is acceptable: the app frame may paint, the Settings content must not.) The settings search entry for Storage points at the same URL.

### G. Settings: Backup and restore (admin, `backup`, pushed page, §8.25.10)

1. **Nightly backup card** (`useBackupStatus`, polled every 30 s): "Last nightly backup: 03:10 · 42 MB · OK" with a `success` `check-circle` glyph, or "Unknown" with a `warning` glyph (unknown is never shown as healthy).
2. **Restore staged banner:** a `warning` `InlineNotice` "A restore is staged and applies when the server restarts." + the plain action "Cancel staged restore" (`useCancelPendingRestore`, loading dots).
3. **Export:** explainer "The whole database, every account. Keep it private."; the switch "Include caches (larger, restores faster)", default off; primary "Export backup" ("Preparing…" with three dots) → `exportDatabase({ includeCache })` → download through an object URL on a temporary `<a download>` (revoked after use), then the confirmation line "Saved manhwamaniacs-2026-09-28.db" (the filename from `Content-Disposition`).
4. **Restore:** a section with a 3 px `danger` leading bar: explainer "Restoring replaces everything on this server with the backup. It applies on the next restart, and nothing of the current state is kept."; "Choose backup file" (secondary, opening a visually hidden `<input type="file" accept=".db">`); errors "That isn't a .db file", "That file is empty"; the chosen file's name and size ("manhwamaniacs-2026-09-28.db · 42 MB") or "No file chosen. Nothing is uploaded until you confirm."; "Restore from this file…" (destructive) → an `Alert` "Restore from “{file}”?" with the four consequences as bullets (replaces every account; sign-ins come from the backup; applies on the next restart; nothing of the current state is kept), a `TextField` "Type RESTORE to confirm" (case-insensitive match), and the destructive "Restore" enabled only when the phrase matches (`useImportBackup`, "Uploading…"); success: the alert "Restore staged. Restart the server to finish." with "OK".
5. **Members link:** on desktop a row "Members" under this section → `ROUTES.settings("members")`.
6. **States:** status loading (card skeleton), status error ("Couldn't read the backup status" + "Try again"), export failure (inline `danger` line "Couldn't export the backup. Try again."), offline (the notice "These settings need a connection", controls disabled).

### H. Settings: Diagnostics (`diagnostics`, §8.25.12) and About's licences (§8.25.14)

1. **Diagnostics** (visible to everyone; the web shows the rows below and omits the Flutter-only Display, Image cache, CPU build and GPU raster rows):
   - **Rendering performance:** sampled with `requestAnimationFrame` in 2 s windows while the section is visible: FPS in `mono` `iris400`; Jank % (a frame is janky when its delta exceeds 1.5 × the median delta of the first 60 frames) coloured `success` below 5, `warning` below 15, `danger` above; Worst frame (ms); Average frame (ms); Samples. "Starting profiler…" for the first second.
   - **Device:** Platform (`navigator.userAgentData?.platform ?? navigator.platform`), Browser (the UA brand and major version), CPU cores (`navigator.hardwareConcurrency`), Screen ("1440 × 900 @2x"), Web version (`WEB_VERSION`), Build mode (`process.env.NODE_ENV`).
   - **Glass:** "Renderer: liquid (tier A)" / "frosted (tier B)" / "solid (tier C)" from `html[data-glass-renderer]` (`web/25`); "Refraction: on" or "frosted"; "Glass layers on screen: 4", the live count from `web/25`'s `budget.ts`, turning `warning` above 6.
   - **Development rows:** the `web/02` debug row "Preview Glass skin" (the segmented Cinematic | Glass writing the `mm-skin-debug` cookie and restarting) rendered whenever the URL has `?debug=1` or the `mm-skin-debug` cookie is set (it is deleted by `release/01`); "Glass calibration" (→ `/dev/glass-calibration`) and "Show motion timings" (a switch toggling the `mod+shift+m` overlay) only in development builds (`process.env.NODE_ENV !== "production"`).
2. **Open-source licences** (`/settings/about?sheet=licenses`; a `large` sheet on phones, the 560 px window on desktop; `useSheetParam("licenses")`). If `web/39` already built a licences sheet (`grep -rn "sheet=licenses\|\"licenses\"" frontend/src/skins/glass`), bring that one to this spec; never create a second.
   - A `SearchField` "Search packages" at the top (`/` focuses it; `filterLicenses`).
   - Rows 52 tall grouped **Fonts**, **Web packages**, **Artwork and sounds** (section headers per §7.17): the package name in `mono` 13 `label1`, its version in `caption1` (`label3` on the phone's `solid1` large sheet, `onGlass` in the desktop T4 window), and a licence tag capsule (`caption1` 600 on `fill2`, MIT, BSD-3-Clause, Apache-2.0, OFL-1.1, CC0, or the raw value).
   - Tapping a row (or Enter) pushes the licence text inside the sheet: the package name as the title, a "Copy" plain button in the header (`navigator.clipboard.writeText`, toast "Copied"), the text in `mono` 13/20 (`label2` on the phone sheet, `onGlass` in the desktop window), preserving line breaks; Esc or the back chevron returns to the list with focus on the row.
   - States: loading (8 row skeletons while `loadLicenses()` resolves), no match ("No package matches “{q}”"), error ("Couldn't load the licences" + "Try again").
   - Keys: `/` search, arrows move through rows, Enter opens, Esc back, then closes.
   - The About section row "Open-source licences" (from `web/39`) opens this sheet.

### I. System status (`frontend/src/skins/glass/screens/status/`, ScreenId `status`, §8.26)

Wire `screens.status` to `StatusScreen` and remove `status` from `PENDING`. `document.title` "System status · ManhwaManiacs". Phone: pushed page; desktop: page with the sidebar footer item "Status" active. Data: `useBackendHealth` (15 s poll), `useSourceHealth` (30 s poll), `useUpdateSettings`, `useUpdateRuns`, `useManualCheck`, the summary logic in `features/admin/status/status.ts`.

1. **Header:** the eyebrow "Administration" (`caption1` uppercase +0.06 em `label2`), large title "System status" (letter reveal once per session), nav row "Refresh" (`arrows-clockwise`, spins while any query refetches).
2. **Summary banner:** a `surface1` slab tinted by the worst state (a 3 px leading bar and the glyph in `success` / `warning` / `danger` / `g600` for unknown; glyphs `check-circle`, `warning`, `warning-circle`, `question`), headline "Everything is running" or "2 problems need attention" (`headline`), and a bullet list of the problems (`callout` `label2`).
3. **Backend card:** a state capsule Healthy · Warning · Down · Unknown with its **health bead**; the name; the version in `mono`; "Probe GET /health" in `footnote` `label3`.
4. **Update checker card:** "Check now" (secondary; `useManualCheck`; `check_already_running` → toast "A check is already running"); last run + "12 min ago"; next run + "in 40 min"; interval; failed runs in `danger` when above 0; the server error in a `mono` block (`surface2`, radius 12, padding 12, horizontal scroll inside).
5. **Recent checks card:** up to 8 runs: a status tag (§7.20 status-tag recipe: completed `success`, running `iris400`, failed `danger`, other `warning`), the trigger, "142 series · 5 new", the time, the error line when present; empty "No checks have run yet".
6. **Source health card:** rows (state bead, name `headline`, id in `mono`, a "demoted" `warning` badge, "last probe 3 min ago", the message, the last error in a `mono` block); sorted worst first (reuse `sortWorstFirst` from `features/sources/health.ts` if `web/16` added it).
7. **Footer note** (`footnote` `label3`): "Everything here reads endpoints that already exist; nothing on this page changes the server except Check now."
8. **Health beads (signature):** every health dot here uses `HealthBead` (`web/26`, a content twin: a 10 px sphere lit from inside in its state colour, `success` / `warning` / `danger` / `g600`, with a 1 px specular highlight at the light angle; no backdrop read). The healthy backend bead pulses once per successful 15 s poll (scale 1 → 1.3 → 1 on `tick`, k 584.0, c 33.83; `play("Bead pulse")`); a failing or dead source's bead flickers once (opacity 1 → 0.3 → 1 over 120 ms linear; `play("Bead flicker")`) when a new probe for it lands; a demoted source's bead gets a 1 px `warning` ring. Add `pulseKey` and `flickerKey` props to `HealthBead.tsx` if it lacks them (with gallery entries). Reduced motion: colour changes only.
9. **Desktop:** a two-column grid at 1280 px and wider (Backend and Update checker in the first row, Recent checks and Source health below; Source health spans both columns when it has more than 8 rows), one column below 1280 px, max width 1200 px, 20 px gaps.
10. **Non-admin:** the object lens (`shield`, Empty tone) "Administrators only" / "System status is instance-wide. Ask the account owner to check it." + primary "Back home".
11. **States:** loading (a 4 px indeterminate `Progress` bar while `/auth/me` resolves, then card skeletons), per-card errors (inline "Couldn't load this" + "Retry"), offline (the offline lens `wifi-slash` "You're offline" / "System status needs a connection." + "Try again").
12. **Keys:** `r` refresh all, `c` check now, arrows through the source-health rows (roving `tabindex`); all listed in the `?` sheet under "System status".

### J. Cross-cutting

- **Focus on navigation:** each screen's `h1` takes focus with `preventScroll: true` after a route change; sheets focus their title and return focus to the trigger.
- **Semantics:** the You grouped lists are `list` / `listitem` with each row a link or button whose name carries its badge ("Updates, 3 new"); status capsules carry text; the members table has `scope` headers and a `<caption>` "Members"; the diagnostics readouts are a `dl`.
- **Haptics and sounds** (web: only the `navigator.vibrate` events of §5.2 on Android Chrome, the rest no-ops through `skins/glass/haptics.ts`; sounds only when UI sounds are on).
- **Solid glass and Increase contrast:** every surface here renders its §4.11 variant (solid recipe `solid1`/`solid2` with the 1 px `rgba(255,255,255,0.10)` rim; `label2` → `label1`, `label3` → `label2`).

## Out of scope here (do not build)

- `web/41`: For you, recaps, More like this. `web/42`: Statistics, the physics `StreakFlame`, Wrapped, live goal-ring updates. `web/43`: Circle, reactions, letters, shared shelves, the friend sheet. `web/44`: ambient reader extras.
- The Server section (§8.25.11, apps only); any change under `mobile/`, `backend/`, `design/` or `brand/`.

## File layout

```
frontend/src/features/library/daily-goal.ts (+ daily-goal.test.ts)             A1 (only if no hook exists)
frontend/src/features/backup/api.ts, hooks.ts (+ api.test.ts)                   A2
frontend/src/features/you/you-cards.ts (+ you-cards.test.ts)                    A3
frontend/src/features/app/licenses.ts, licenses.generated.json (+ licenses.test.ts)   A4
frontend/scripts/build-licenses.mjs, frontend/licenses/{fonts.json,CC0-1.0.txt,fonts/*.OFL.txt}   A4
frontend/package.json                                                            "licenses" script only
frontend/src/skins/glass/index.ts                                                index and status out of PENDING
frontend/src/skins/glass/screens/you/{YouScreen,ProfileBlock,ReadingCard,WrappedCard,CircleCard,YouLists,OrbLift}.tsx   B
frontend/src/skins/glass/screens/settings/sections/{Notifications,Security,Members,Backup,Diagnostics}.tsx   C–E, G, H1
frontend/src/skins/glass/screens/settings/{LicensesSheet.tsx,diagnostics-sampler.ts (+ test)}   H
frontend/src/skins/glass/screens/settings/<server wrapper>.tsx                   F (only if needed)
frontend/src/skins/glass/copy/settings-index.ts                                  new entries and tile colours
frontend/src/skins/glass/screens/status/{StatusScreen,SummaryBanner,BackendCard,CheckerCard,RecentChecks,SourceHealth}.tsx   I
frontend/src/skins/glass/primitives/{UnsavedChangesBar.tsx, Slider.tsx, slider-math.test.ts, cards/HealthBead.tsx}   only the additions named above
frontend/src/skins/glass/dev/Gallery.tsx                                         entries for any new primitive prop
frontend/e2e/glass-you-admin-status.spec.ts
docs/redesign/proof/web-40/                                                      plan.md, inventory-map.md, screenshots, report.md
```

Follow the screen-folder naming `web/31`–`web/39` used if it differs. No CSS modules.

## Values you need (copied from `glass/DESIGN.md`)

| What | Value | Section |
|---|---|---|
| Canvas and slabs | `g0` `#000000`, `surface1` `#131317`, `surface2` `#1A1A20`, `surface3` `#222229`, `g300` `#2D2D35`, `g500` `#56565F`, `g600` `#76767F`, `slabBorder` 1 px `rgba(255,255,255,0.06)` | §2.1.1, §2.6 |
| Labels | `label1` `#F2F2F7`, `label2` `rgba(235,235,245,0.64)`, `label3` `rgba(235,235,245,0.52)`, `label4` `rgba(235,235,245,0.24)`, `onGlass` `#F2F2F7`, `onTint` `#FFFFFF` | §2.1.2 |
| Fills | `fill1` `rgba(120,120,128,0.36)`, `fill2` `rgba(120,120,128,0.30)`, `fill3` `rgba(118,118,128,0.22)`, `fill4` `rgba(118,118,128,0.16)`, `wellOnGlass` `rgba(0,0,0,0.35)`, backing disc `rgba(0,0,0,0.60)` | §2.1.2 |
| Iris | `iris300` `#BCB0FF`, `iris400` `#A99BFF`, `iris500` `#8F7EFF`, `iris600` `#7563F2`, `iris700` `#5B4AD1` | §2.1.3 |
| Semantic | `success` `#3DDC84`, `warning` `#FFB547`, `danger` `#FF5C5C`, `info` `#6CB8FF`, `streak` `#FF8A3D`, `bloom` `#FF9ED8`, `machine` `#5CE1E6` | §2.1.4 |
| Dims | `dimSheet` `rgba(0,0,0,0.28)`, `dimModal` `rgba(0,0,0,0.48)` | §2.1.7 |
| Springs (k, c; mass 1) | `tick` 584.0 / 33.83, `press` 815.7 / 45.70, `snappy` 246.7 / 26.70, `morph` 273.4 / 24.80, `sheet` 171.3 / 24.09, `sheetSnap` 223.8 / 26.33, `page` 146.0 / 24.17, `zoom` 125.9 / 21.09, `dismiss` 385.5 / 39.27, `celebrate` 109.7 / 13.61 | §4.2 |
| Timed | `fadeIn` 180 ms `cubic-bezier(0.2,0,0,1)`, `fadeOut` 120 ms `cubic-bezier(0.4,0,1,1)`, `colorShift` 240 ms, `materialize` 250 ms / `dematerialize` 350 ms, `shimmer` 1400 ms, reduced cross-fade 150 ms (in page, sheets) / 200 ms (routes) | §4.7 |
| Wave | `delay = min(distance / 1.6 px·ms⁻¹, 240 ms)`, 12 px translate + scale 0.98 → 1 on `snappy` | §4.8 |
| Row pulse | the row's `iris600` fill at 14 % fades to 0 over 900 ms | §4.10 |
| Hold to confirm | 1,200 ms: fill starts at 200 ms and runs 1,000 ms; release before 200 ms within 8 px = click | §4.6, §7.1 |
| Error shake | `x(t) = 8 × e^(−t / 90 ms) × sin(2π × 7 Hz × t)` over 420 ms (6 px for fields) | §4.10 |
| Radii | cards `rXl` 26, grouped lists 20, icon tiles `rIconTile` 12, sheets 36 (web), alerts 26, windows 32 | §2.3, §7.10, §7.11 |
| Grouped list | rows 52 (64 with subtitle), 16 px from screen edges, header `footnote` 13/600 uppercase +0.04 em `label2` | §7.17 |
| Type | `largeTitle` 34/40 · 36/42 · 40/46 · 44/50 w700; `title1` 28/34 · 30/36 · 32/38 · 34/40 w680; `title2` 22/28 · 22/28 · 24/30 · 26/32 w650; `headline` 17/22 · 17/22 · 16/22 · 16/22 w600; `body` 17/24 · 17/24 · 16/24 · 16/24 w420; `callout` 16/22 · 16/22 · 15/22 · 15/22; `footnote` 13/18 w460; `caption1` 12/16 w520; `mono` 13/18 Google Sans Code 500 | §3.2 |
| Health bead | 10 px, pulse 1 → 1.3 → 1 on `tick`, flicker 1 → 0.3 → 1 over 120 ms | §8.26, §4.10 |

## Acceptance criteria

- [ ] `index` and `status` are out of the Glass `PENDING` set; the Vitest completeness test passes; `docs/redesign/proof/web-40/inventory-map.md` maps M1–M6, SG18–SG24, SG29–SG39, AS1–AS10, BK1–BK5, MB1–MB7, A5–A9, A100, A107–A118 to their Glass sections.
- [ ] You hub: the profile block, Reading card (with this week's figures and the 7-day sparkline), the Wrapped card only from 1 December to 31 January (checked with `page.clock` at 30 Nov, 1 Dec and 31 Jan), the Circle card (and its "Read together" line when sharing is off), and every grouped list with admin-only rows hidden for a non-admin and Dialogue search hidden in Novels mode; the Server row never appears on the web.
- [ ] Desktop `/more` renders the two-column layout at most 880 px wide at 1440 × 900 and never redirects by viewport.
- [ ] Orb lift plays once per session per profile on the phone frame (a second visit cross-fades) and becomes a 200 ms cross-fade under reduced motion.
- [ ] Notifications: admin-only (a non-admin's direct visit shows the "Administrators only" lens), the schedule strip incl. the overdue form, three switches, the interval slider with `detent.tick` per 5 min and the `detent.magnet` at 30, the stepper 5–1,440, the "Unsaved changes" bar (52 px, `bottom: 24px`, max 720 px on desktop; `html[data-bottom-bar]` set while shown), Save, Discard and the discard alert.
- [ ] Security: every client error string, `invalid_credentials` inline on Current (no sign-out), `weak_password` under New, the `rate_limited` countdown on the button, the sessions list with "This device", revoke by swipe and ⋯, and Sign out everywhere by hold (1,200 ms) and by click (the alert whose confirm needs the acknowledgement switch).
- [ ] Members: phone rows and the desktop table (640 px min inside its own scroll container), own row actions disabled with the reason, Delete only through the hold-to-confirm alert, the footer count and every state.
- [ ] A visit to `/settings/storage` lands on `/downloads?tab=storage` without ever rendering Settings content (the spec checks the final URL and that no Settings section list or heading appears in the DOM at any point, with a `MutationObserver` installed by `page.addInitScript`).
- [ ] Backup: the nightly card never shows "Unknown" as healthy, the staged banner cancels, export with and without caches (the spec checks the request URL carries `include_cache=true` only when the switch is on), the restore file validation, the RESTORE phrase gate (case-insensitive) and the staged alert.
- [ ] Diagnostics: FPS, jank, worst and average frame and samples update every 2 s; device rows; the renderer tier and "Glass layers on screen" live count (warning above 6); the debug row only with `?debug=1` or the `mm-skin-debug` cookie; calibration and motion-timings rows absent from a production build.
- [ ] Licences: `npm run licenses` regenerates `licenses.generated.json` with no diff; the sheet lists the three groups; every `next/font/google` family appears with OFL-1.1 and its OFL text; the art and sound entries show CC0; search, no-match, the text view with Copy, and every key work; the JSON is not in the first-load bundle (`npm run build` output shows it only in a separate chunk).
- [ ] System status: summary banner by worst state, the four cards, the backend bead pulsing on each successful poll, a failing source's bead flickering on a new probe, the demoted ring, "Check now" and its `check_already_running` toast, the two-column grid at ≥ 1280 px with Source health spanning both columns above 8 rows, the non-admin lens, every state, and `r` / `c` / arrows.
- [ ] Keyboard: every control reachable by Tab in reading order with the two-tone focus ring, never clipped; sheets and alerts trap focus and return it to their trigger; no single-key binding fires while typing, and none fires with Single-key shortcuts off (checked for `r` and `c`).
- [ ] Hit targets: every `button, a, [role="button"], [role="switch"], [role="slider"]` inside `main` and inside open sheets is at least 44 × 44 px at 390 × 844 with at least 8 px between adjacent hit boxes (the spec measures them).
- [ ] Reduced motion (`page.emulateMedia({ reducedMotion: "reduce" })` and `html[data-motion="reduced"]`): Orb lift and routes cross-fade 200 ms, sheets fade + 16 px over 150 ms, letter reveals show at once, beads change colour only, the hold fill steps in 4 visible increments, skeletons are static.
- [ ] Solid glass and Increase contrast: screenshots of You, Security and System status at 1440 × 900 with `data-solid="on"` and with `data-contrast="more"` show the solid recipe and the contrast rules.
- [ ] Per-skin difference: nothing under `frontend/src/skins/cinematic/` changed (`git diff --stat` of your commits); with `mm-skin-debug=cinematic`, `/more`, `/settings/security` and `/admin/status` still render Cinematic's screens.
- [ ] `npm run typecheck`, `npm run lint` (0 errors, 0 warnings), `npm run test` (counts at or above the floor plus the new tests, 0 failed), `npm run build` (0 errors, 0 warnings) and `node design/build.mjs --check` are green; `frontend/e2e/glass-you-admin-status.spec.ts` passes, and `glass-primitives.spec.ts` and `glass-overlays.spec.ts` still pass.

## Verification

**RAM guard (production shares this box: 7,746 MB total, production containers and five Minecraft bots).** Before every heavy command (`npm run test`, `npm run build`, `next dev`, a Playwright run, the dev-stack start) run `free -m` and read the `available` column of the `Mem:` row. If it is under 1024 MB, do not start; stop and report "RAM guard: N MB available". Run `pgrep -af "next build|next dev|vitest|flutter_tester|pytest"` first and wait for another session's build or test run to exit; never run two builds at once, and never run `next build` while `next dev` or a Playwright browser is running. No `npm install`: every dependency this step uses is already installed by `web/01` and `web/25`.

From the repository root, one command at a time, each after the RAM guard:

```bash
node design/build.mjs --check
cd frontend && npm run licenses && git diff --stat -- src/features/app/licenses.generated.json   # no diff after the first commit
cd frontend && npm run typecheck
cd frontend && npm run lint          # baseline: exit 0, 0 errors, 0 warnings
cd frontend && npm run test          # passed >= the floor, 0 failed
cd frontend && npm run build         # baseline: exit 0, 0 errors, 0 warnings (stop next dev first)
```

Browser checks against the dev stack (`docs/redesign/prompts/backend/00-profile-columns-and-dev-stack.md`; credentials in `backend/scripts/README-dev-stack.md`, never committed):

1. `curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8010/health` must print `200`, else `backend/scripts/dev_stack.sh start`.
2. `cd frontend && NEXT_PUBLIC_API_URL=/api BACKEND_INTERNAL_URL=http://127.0.0.1:8010 npx next dev -p 3010`.
3. In a second shell: `cd frontend && E2E_BASE_URL=http://127.0.0.1:3010 E2E_USERNAME=demo E2E_PASSWORD=<from the README> npx playwright test e2e/glass-you-admin-status.spec.ts --workers=1`. The spec sets the cookie `mm-skin-debug=glass`, uses the live dev stack where it suffices (the demo account is the admin), and `page.route` fixtures for the states the dev stack cannot produce (backend down, a failing and a demoted source, an unknown nightly backup, a staged restore, `rate_limited` with `Retry-After: 42`, a second member, a non-admin `/auth/me`), `page.clock` for the Wrapped-card dates, and `context.setOffline(true)` after a first load for the offline states. It counts haptic events through the development `mm:haptic` window events.
4. Re-run `glass-primitives.spec.ts` and `glass-overlays.spec.ts` the same way.

**Visual proof** with `frontend/scripts/proof.mjs` (run `node scripts/proof.mjs --help` first and use its flags for step, skin, routes and sizes) in the named session `web-40`, headless Chromium, skin `glass`, at 1440 × 900 and 390 × 844 (touch emulation at the phone size), into `docs/redesign/proof/web-40/`, each at both sizes: `you`, `you-loading`, `you-offline`, `you-nonadmin`, `you-wrapped-card` (clock set to 5 Dec), `orb-lift-phone` (mid-flight), `settings-notifications`, `settings-notifications-dirty` (the bar showing), `settings-security`, `security-rate-limited`, `security-sign-out-everywhere-alert`, `settings-members`, `members-delete-alert`, `settings-backup`, `backup-restore-alert`, `settings-diagnostics`, `licenses`, `licenses-text`, `status`, `status-problems`, `status-nonadmin`, `status-offline`; plus `you-solid-desktop.png`, `you-contrast-desktop.png`, `security-solid-desktop.png`, `status-solid-desktop.png`, `status-contrast-desktop.png` at 1440 × 900, and `you-reduced-motion-phone.png`. With `playwright-cli`, always pass `-s=web-40`. Open the motion-timings overlay (`mod+shift+m`) after Orb lift and a bead pulse and capture `motion-timings-1440x900.png`. Write `docs/redesign/proof/web-40/report.md` mapping each screenshot to the acceptance item it proves. Stop `next dev` and run `backend/scripts/dev_stack.sh stop` when done.

`00-baseline.md` records lint and build at 0 errors and 0 warnings; keep them there. This step changes nothing in `mobile/` or `backend/`: confirm `git diff --stat <first commit of this step>^..HEAD -- mobile backend` prints nothing, so `flutter analyze`, `flutter test` (Flutter at `/srv/manhwamaniacs/dev/flutter/bin`, baseline 2,012 tests) and the backend pytest (`backend/.venv/bin/python -m pytest -q --no-header`) are not rerun. If that diff is not empty, you broke the track rule: revert it.

## Git

- Branch `feat/vps-slim-source-native`. Commit small and often, one working step per commit after typecheck, lint, test and build pass, messages starting `web-40:`: (1) `web-40: shared daily goal, you cards, backup export option and licence data`; (2) `web-40: Glass You hub and Orb lift`; (3) `web-40: Glass notifications, security and members settings`; (4) `web-40: Glass storage redirect, backup and restore, diagnostics and licences`; (5) `web-40: Glass System status with health beads`; (6) `web-40: e2e and proof`.
- Stage your paths explicitly (`git add frontend/src/skins/glass/screens/you/YouScreen.tsx …`); never `git add -A`, `git add .` or `git commit -a`, because the mobile, backend and shared sessions commit in the same checkout.
- **No Claude or AI attribution anywhere:** no `Co-Authored-By` line, no "Generated with" line, no AI author, no mention of an assistant, even if your harness asks for one (the owner's `~/.claude/CLAUDE.md` forbids it). Never commit secrets, the demo credentials, `.env` files or `.claude/`.
- Run `npm run build` (after `free -m`, with `next dev` stopped) before every push, then `git push origin feat/vps-slim-source-native` after each working step.
- Never edit `backend/connectors/`. Never touch production containers or `/srv/manhwamaniacs/{app,data}`. Do not deploy: Glass stays behind the debug row until `release/01`.

## Report back

Reply with:

1. **Done:** items A1–A4, B1–B9, C1–C6, D1–D4, E1–E6, F, G1–G6, H1–H2, I1–I12, J, one line each, and anything not done with the reason.
2. **Screenshots:** the folder `docs/redesign/proof/web-40/` and its file list, plus `inventory-map.md`.
3. **Tests:** Vitest files and cases before and after; lint, typecheck, build and `build.mjs --check` results; each Playwright spec's passed and failed counts; the lowest `free -m` available figure seen.
4. **Motion:** the motion-timings rows for Orb lift, Bead pulse and the sheet and alert moves (planned vs actual settle, dropped frames).
5. **Open issues:** anything `glass/DESIGN.md` left ambiguous and the choice you made, any conflict between this file and `glass/DESIGN.md`, fonts whose OFL file could not be fetched, and whether `web/39` had already built any part of H2.
6. **Commits:** the hashes pushed.

Next prompt file: `docs/redesign/prompts/web/41-glass-ai-for-you-recaps.md` (`docs/redesign/prompts/mobile/40-glass-you-about-admin-status.md` runs in parallel).
