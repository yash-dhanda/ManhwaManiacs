# web/18 · Cinematic Settings, the edition picker and Stop the press

Step 53 of the redesign series (track `web`, group 2). Depends on `web/17-cinematic-downloads-index-status.md`. Its twin `mobile/18-cinematic-settings-and-edition-restart.md` builds the same cluster in Flutter and may run at the same time in another session; you never touch `mobile/`.

## Goal

Build Cinematic Settings on the web as one screen at `/settings` and `/settings/:section`: a two-pane table of contents with numbered sections and a settings search on desktop, a credits-list table of contents with pushed sections on phones, and every section and control of `cinematic/DESIGN.md` §8.30.2 that the web client has (profile and account, appearance with the **edition picker**, reading defaults for manga and novels including "Previously on", Listen, Ambient, downloads and storage, content with the 18+ certificate, feedback with sound and haptics, notifications with the per-profile `notify_enabled` master and the admin checker block, the keyboard registry, admin links, about with licences, and the debug-only diagnostics row), plus the pushed pages Password & security, Members and Backup & restore. The edition picker shows a live preview of each skin's Tonight rendered in an iframe from a separate root layout with its own query client and a static demo fixture; while `glass_available` is false the Glass card is the disabled `NEXT ISSUE` plate. The skin switch plays **Stop the press** (500 ms outgoing: rack out, blades close, masthead cuts in on black, then the restart after the awaited `PATCH`), and the arriving Cinematic skin shows the 10 s undo toast. Every state, key and reduced-motion variant is delivered for desktop web and mobile web.

## Read first

1. `docs/redesign/cinematic/DESIGN.md`
   - §2.1.1 (raised-stock rule), §2.1.2–§2.1.4, §2.1.6 (paper stocks for the novel defaults), §2.2, §2.3, §2.4 (layers, `z.shutter` 80), §2.5 (`blur.defocus` 0 → 6 px), §2.6, §2.7, §2.8.
   - §3.2, §3.4 (the five reading faces and Hyperlegible text), §3.5, §4.2–§4.8 (incl. **Stop the press**, **Highlight sweep**, **Rule slide**, reduced motion), §5 (the web vibrates only for five events; the Feedback row rules), §6 (sounds, per-profile toggle and volume, `Play a sample`).
   - §7 intro, §7.1, §7.2, §7.3 (inputs, password reveal), §7.4 (`compact` search), §7.5 (slug lines, segmented control), §7.9 (sheets, desktop column panels), §7.10 (dialogs, arm delay, heavy confirmations), §7.11 (toasts, `dur.hold.toast.undo`), §7.12, §7.13, §7.15 (the sidebar footer `Settings` item and breadcrumb `SETTINGS / {section}`), §7.16 (settings rows, credits rows), §7.18, §7.19, §7.20 (sliders), §7.21 (switches, checkboxes, radios, steppers), §7.22, §7.23, §7.24 (the certificate), §7.25, §7.26, §7.27, §7.29 (banner strips, `folioLabel()`).
   - §8.0.3 (the `settings` route and its slugs), §8.0.4, §8.0.7 (**`glass_available`**, the pre-flip debug row), §8.0.9 (Settings on tablets), §8.14.8 (the reader setup sheet: every control, range, default and scope your manga defaults bind to), §8.15.5 (the Type sheet: the novel defaults), §8.16.4–§8.16.6 (speed, voices, sleep timer), §9.1.5 (the recap setting's meaning), §9.4.1–§9.4.4 (auto-scroll, soundscape picker and descriptions, guided view, page-tinted chrome).
   - **§8.30 Settings** (read every line: §8.30.1 structure, §8.30.2 every control, §8.30.3 the edition picker and Stop the press, §8.30.4 security, §8.30.5 members, §8.30.6 backup), §8.33.1 (the palette's `EDITION` and `SETTINGS` groups), §10.1.2 (Settings section headers on desktop use the letter reveal), §13 moment 12, §14, §15.2 (the preview route files), §15.9 (the `SKIN RESTART` measurement), §15.10 S5, S6, S12, S15, S17.
2. `docs/redesign/glass/DESIGN.md` §8.25.1–§8.25.2 (Glass's switch uses the same shared mechanics with its 615 ms melt and its own undo toast), §8.25.16 (AI and recaps), §15.5 (the device keys table) and **§15.6 (the recap setting `mm.recap`, binding for both skins)**.
3. `docs/redesign/inventory/00-decisions.md`.
4. `docs/redesign/stack-decision.md` §2.4 (where the skin choice lives), §2.5 (how the restart works), §2.2.
5. `docs/redesign/inventory/web.md` §6 (SG1–SG40), §16 (BK1–BK5), §17 (MB1–MB7), §19 (every setting key K1–K51), §2.9 (the keyboard layer), §18.1, §18.3, §18.10.
6. `docs/redesign/inventory/capabilities.md` §3, §4, §6, §21, §22.
7. `docs/redesign/00-baseline.md`.
8. `docs/redesign/prompts-plan.json` (this entry and `web/02`, `web/07`, `web/13`, `web/14`, `web/15`, `web/17`, `web/22`, `backend/00`).

## Skills to invoke, in this order

1. `superpowers:writing-plans`: plan to `docs/redesign/proof/web-18/plan.md`, one task per Scope item.
2. `superpowers:subagent-driven-development` (task groups A–G, one after the other); `superpowers:executing-plans` if subagents are unavailable.
3. `frontend-design:frontend-design`, `impeccable:impeccable`, `taste-skill:taste-skill` while building the screens; the contract wins on conflicts.
4. `superpowers:verification-before-completion` before claiming done.

## Before you start

- Branch `feat/vps-slim-source-native`; other sessions commit here: stage only your own paths; never `git add -A`, `git stash`, `git reset`, `git checkout` on others' files.
- Stop and report if missing: `settings` in the Cinematic `PENDING` set; `web/02`'s `features/skin/` switch (`grep -rn "mm.skin.return" frontend/src/features`) and its `/settings/diagnostics?debug=1` debug row; `web/07`'s certificate dialog; `web/17`'s `frontend/src/skins/cinematic/screens/downloads/StoragePanel.tsx` and `WhatsNew.tsx`; `backend/00`'s `notify_enabled` on `PATCH /profiles/{id}` (`grep -n notify_enabled backend/routes/profiles.py`).
- Read the legacy settings you replace, only for hooks and calls: `frontend/src/app/(app)/settings/page.tsx`, `frontend/src/config/settings-tabs.ts`, `frontend/src/features/preferences/components/*`, `frontend/src/features/auth/components/{account-security-panel,change-password-form,session-list}.tsx`, `frontend/src/features/admin/components/MembersPanel.tsx`, `frontend/src/features/backup/components/BackupPanel.tsx`, `frontend/src/features/updates/components/NotificationSettingsPanel.tsx`, `frontend/src/components/settings/keyboard-shortcuts-panel.tsx`. Never import from them.
- **Bind to existing stores; never create a second one for the same value.** Before creating any store below, grep `frontend/src/features` for its key or label. The reader setup sheet (`web/13`), the Type sheet (`web/14`) and Listen (`web/15`) already store most reading values and already apply the §8.14.8 and §2.1.6 migrations of old values; Settings shows and edits the same values.

## Ground rules for this step

- **Track rule.** Work in `frontend/`. **One narrow exception:** the edition preview fixture needs `design/previews/` and a copy step in `design/build.mjs` (item A8). Make that change in its own commit, stage only `design/previews/**`, `design/build.mjs` and the two generated outputs, and touch nothing else under `design/`, `brand/`, `mobile/` or `backend/`.
- **Skin boundary** as enforced by the eslint rule: screens import `@/features/**` (never `*/components/**`), `@/lib/**`, `@/services/**`, `@/stores/**`, `@/types/**`, `@/config/**`, the generated contract and their own skin. The preview route file under `app/(preview)/` is a route file and may import both skins.
- **Shared logic in `features/`**, skin-neutral, Vitest-tested (Vitest runs `src/**/*.test.ts` in the `node` environment, so keep logic in `.ts` modules with injected dependencies).
- **Paths** from `ROUTES` in `frontend/src/skins/contract.generated.ts`.
- **Tokens only** in `src/skins/cinematic/**`.
- **Never** edit `backend/connectors/`, never touch production containers or `/srv/manhwamaniacs/{app,data}`.
- **RAM guard.** `free -m` before every build, test and Playwright run; stop if `available` < 1024 MB; never run two builds (or a build and `next dev`) at once.

## Scope: every item this step delivers

Remove `settings` from the Cinematic `PENDING` set when done. The screen registers its keys under the keyboard group `Settings`, sets `document.title` to `Settings · ManhwaManiacs` (`{Section} · Settings · ManhwaManiacs` on a section), and receives route focus on its `h1`.

### A. Shared data-layer work (skin-neutral, Vitest-tested)

1. **The switch orchestration** in `frontend/src/features/skin/` (extend what `web/02` wrote; read it first): a pure function `runSkinSwitch(deps, { to, undoable })` with injected `patch(signal)`, `outgoing(): Promise<void>`, `writeMirror()`, `postToWorker()`, `replace(path)`, `reverse(): Promise<void>`, `onError()` and timers. Timeline: at t = 0 it writes `sessionStorage['mm.skin.t0']`, starts the `PATCH /profiles/{id} {skin}` and `outgoing()` together; when both the 500 ms outgoing and the `PATCH` have finished, and the `PATCH` answered 2xx within 1,000 ms after the outgoing ended (an `AbortController` timeout), it writes the `mm-skin` cookie (`Path=/; Max-Age=31536000; SameSite=Lax; Secure`) and `sessionStorage['mm.skin.return']` (current `pathname + search`), writes `sessionStorage['mm.skin.from']` = the current skin **only when `undoable`**, posts `{ type: "skin-changed", skin: to }` to the service worker, then calls `replace(returnPath)`. On an error or the timeout it aborts, removes `mm.skin.t0`, leaves the mirror unchanged, awaits `reverse()` and calls `onError()`. Also `takeSkinArrival()`: returns the `mm.skin.from` value once and deletes it. Tests with fake timers: the success path order, the 1,000 ms timeout, a 500 response, `undoable: false` writes no `mm.skin.from`, and `takeSkinArrival()` is one-shot. Glass (`web/39`) passes its own 615 ms melt as `outgoing`.
2. **The recap setting, exactly as `glass/DESIGN.md` §15.6 resolves it**: `frontend/src/features/recap/recap-setting.ts` (create it if `grep -rn "mm.recap" frontend/src` finds nothing). One profile-scoped `localStorage` key (through `lib/scoped-storage.ts`) `mm.recap` = `{ mode: "off" | "ask" | "always", seriesDays: number, chapterDays: number, skipSeries: string[] }` (entries `"{sourceId}:{seriesKey}"`), default `{ mode: "ask", seriesDays: 7, chapterDays: 3, skipSeries: [] }`. Cinematic's three values map as `NEVER` ↔ `off`, `ALWAYS` ↔ `always`, `AFTER N DAYS AWAY` ↔ `ask` with `seriesDays = N` (N 3–60). The shared default is the Glass §15.6 register's (7 days); it supersedes the 14 in `cinematic/DESIGN.md` §8.30.2, because §15.6 is the resolution both skins build to. Writes preserve `chapterDays` and `skipSeries`. Hooks `useRecapSetting()` and `setRecapMode(value)`. The Cinematic-only switch "Continue automatically after a recap" is a separate profile-scoped key `mm.recap.autoContinue` (boolean, default `true`), hook `useRecapAutoContinue()`. `web/19` reads both. Tests: default, each mapping both ways, preserved fields, per-profile isolation.
3. **Settings search**: `frontend/src/features/settings/search.ts`: `matchSettings(query, rows)` over `{ id, section, label, keywords[] }`, case-insensitive with diacritics folded (`normalize("NFD")` minus combining marks), label prefix matches first, then label substring, then keyword matches; at most 12 results. Test ordering and folding.
4. **Reading defaults: bind to the records the readers already own, and extend them only with optional fields** (the normalisers keep unknown fields, as `web/12` and `web/14` set up). Each addition gets a Vitest case for its default and its fallback:
   - **Manga** (`frontend/src/features/reader/reader-prefs.ts`, `web/12`): per series the profile-scoped `mm.reader-preferences[{source}:{series}]` (layout, direction, fit, zoom, auto-scroll speed; web K35–K39), per profile the scoped `mm.reader-settings` (gap, page turn, brightness, warmth, colour, ground, tap zones, strip taps, swipe sideways, cinema, auto next chapter, side margin, and the ambient fields listed under **Ambient** below), per device the plain `mm.reader.device.*` keys (strip width, soundscape volume). If `mm.reader-settings` has no profile default for the per-series controls yet, add the optional field `seriesDefaults: { layout: "strip" | "single" | "double" | "guided", direction: "ltr" | "rtl", fit: "width" | "height" | "original", zoom: 50–300 (step 10), autoScrollSpeed: 0.50–3.00 (step 0.05) }` (default `{ "strip", "ltr", "width", 100, 1.00 }`) and make the per-series resolution fall back to it before the built-in defaults.
   - **Novels** (`frontend/src/features/novels/preferences.ts` and `settings.ts`, `web/14`): per book `mm.novel-preferences[{source}:{series}]` (face, size, line spacing, measure; web K41–K44), per profile `mm.novel-settings` (stock, layout, page turn, bold, justify, margins; the novel "Auto next chapter" advance is app-only, §8.15.2, so the web neither stores nor shows it). If there is no profile default for the per-book values yet, add `bookDefaults: { face, fontSize: 14–40, lineHeight: 1.30–2.10, measure: 48–88 }` to `mm.novel-settings` (default: `newsreader`, or `atkinson` with Hyperlegible text on; 19 px on a fine pointer and 18 on a coarse one, 18 and 17 for Archivo; 1.60, or 1.70 for Atkinson; 64) and make the per-book resolution fall back to it.
   - **Listen** (`web/15`'s profile-scoped `mm.listen-settings`, which already holds `speed`; `grep -rn "mm.listen-settings" frontend/src/features` finds its module): add the optional fields `sleepDefault: "off" | 5 | 10 | 15 | 30 | 45 | 60 | "chapter" | "next-chapter"` (default `"off"`), `autoPlayNext` (default `true`, the 5 s countdown) and `keepPlayerVisible` (default `false`) if `web/15` did not.
   - **Ambient**: this step defines the ambient fields, because `web/13` and `web/14` left their AMBIENT rows (apart from auto-scroll and its speed) to `web/23`, which runs after this step and consumes what you add here. Keep any field that already exists (`web/12` added `resumeAfterRelease`); add the rest as optional fields with read-time defaults: in `mm.reader-settings` `soundscape: "off" | "match" | "projector-room" | "rain-on-glass" | "night-city" | "cafe" | "night-wind" | "low-drone" | "afternoon-park" | "temple-bells"` (default `"off"`), `pageTint` (default `true`), `paceByDialogue` (default `false`), `guidedAutoAdvance: { on: boolean, mode: "words" | "fixed", fixedMs: 2000–10000 step 500 }` (default `{ on: false, mode: "words", fixedMs: 3500 }`) and `pauseSoundscapeForNarration` (default `false`); in `mm.novel-settings` `soundscape` (same union, default `"off"`) and `resumeAfterRelease` (default `true`); per device `mm.reader.device.soundscapeVolume` (0–1, default 0.40); and the auto-scroll default speed as `seriesDefaults.autoScrollSpeed` above. Settings → Ambient edits these fields, and its single "Soundscape default" row writes both records' `soundscape`.
   - **Soundscape preview**: no earlier step builds one (`web/13` has no soundscape rows), so add `frontend/src/features/reader/soundscape-preview.ts` with `previewSoundscape(id)` playing 5 s of `/api/app/soundscapes/{id}.ogg` (`.m4a` when `new Audio().canPlayType('audio/ogg; codecs="vorbis"')` is empty) through an `HTMLAudioElement` at the device volume, fading out over the last 300 ms and stopping any earlier preview. `web/23` later points these rows at its `soundscape.ts` mixer and deletes this file.
5. **Boot accessibility writes**: the setter that writes the profile-scoped `mm.boot.a11y` entry (`{ legible, motion }` fields; keep any other fields such as Glass's `solid`, `contrast`, `sr`) and updates `html[data-motion]` and `html[data-legible]` at once. Reuse `web/02`'s module next to `features/preferences/appearance-boot-source.ts`; add `setBootA11y(patch)` there if it is missing, with a test.
6. **Notifications**: `useSetNotifyEnabled()` in `features/profiles/hooks.ts` (`PATCH /profiles/{id} { notify_enabled }`, optimistic, rolled back with an error line on failure); `source_cache_ttl_minutes` (int ≥ 5, admin) added to the `GET/PUT /settings` types in `features/preferences/api.ts` if absent.
7. **Web version** for About: `frontend/src/config/web-version.ts` from `web/17` (`WEB_VERSION`), and `GET /app/version` (`{ version, build }`) through a `useServerVersion()` hook in `features/app/`.
8. **The edition preview fixture** (the one `design/` exception): if `design/build.mjs` does not already copy previews (`grep -n previews design/build.mjs`), add a copy step (about 15 lines, Node stdlib) that writes `design/previews/demo-feed.json` to `frontend/src/skins/preview-feed.generated.json` and `design/previews/covers/*.webp` to `frontend/public/skin-preview/covers/`, both covered by `--check`. Create `design/previews/covers/01.webp`–`06.webp` by copying six of the 24 procedural demo covers `shared/04` made with `brand/demo/make-demo.mjs` (two warm, two cool, one dark, one pale; find them with `ls brand/demo/`), and `design/previews/covers/SOURCES.md` stating they are procedural demo art made from shapes and type by `brand/demo/make-demo.mjs`, with invented titles and no third-party material. This follows the plan's `shared/04` scope ("demo covers … for the edition preview fixture") and replaces the public-domain scans §8.30.3 names, so no download and no licence tracking are needed. `design/previews/demo-feed.json` holds every query the Cinematic Tonight screen reads, keyed exactly as `useHomeFeed()` and its sibling hooks key them (read `frontend/src/features/home/`), with six series using those covers (`cover_url: "/skin-preview/covers/0N.webp"`), no 18+ content and no profile data. If the skin resolves every cover through `lib/cover-url.ts`, make that helper return URLs starting with `/skin-preview/` unchanged (with a Vitest case). Then run `node design/build.mjs` and `node design/build.mjs --check`.

### B. Settings structure (§8.30.1)

**Section registry** (`frontend/src/skins/cinematic/screens/settings/registry.ts`): an ordered list of sections, each `{ slug, title, visible(ctx), rows[] }`, rows `{ id, label, keywords[] }` feeding the search. Web order and titles: `profile` "Profile & account", `appearance` "Appearance", `reading-manga` "Reading: manga", `reading-novels` "Reading: novels" (only when novels are enabled), `listen` "Listen" (only when novels are enabled), `ambient` "Ambient", `storage` "Downloads & storage" (only when `GET /settings` capabilities `client_downloads` is true), `content` "Content", `circle` "Circle & privacy" (**registered by `web/22`**; not rendered in this step), `feedback` "Feedback", `notifications` "Notifications", `keyboard` "Keyboard", `admin` "Admin" (admins only), `diagnostics` "Diagnostics" (only with `?debug=1`, which sets `sessionStorage['mm.debug']` for the tab), `about` "About". Pushed pages: `security`, `members` (admin), `backup` (admin). **Folios** are assigned at render to the visible sections in this order with no gaps (01 Profile & account … About last). The slugs are the stable ids.

**Two panes (viewport ≥ 900 px):** on the 12-column grid (on the 8-column grid at 900–1023, the table of contents in columns 1–3 and the section in 4–8): the **table of contents** in columns 1–3: the settings search at its top, then each section as a row: folio (`type.folio` `ink.45`) + title (`type.ui` `ink.60`); hover `ink.100` with the folio in `spot` (160 ms); the current section `ink.100`, folio `spot`, a 2 px `spot` bar on its left edge, `aria-current="page"`. The right pane (columns 4–12, or 4–8 on the 8-column grid; controls max 720 px wide) shows one section at a time: a section header (§7.27; H3 with the letter reveal, trigger `mount`, `as="h2"`), then settings rows (§7.16, min 56 px: label `type.ui`, description `type.caption` `ink.45`, trailing control), then a section rule. `/settings` renders the first visible section in the right pane (no redirect). Pushed pages render in the right pane under a `quiet` `← {Parent section}` link above their header, and the parent stays lit.

**Settings search** (two panes): a `compact` field "Search settings" at the top of the table of contents; results (≤ 12, `matchSettings`) in a listbox under it: label in `type.ui` and the section title in `type.caption`; `↓`/`↑` move, `Enter` opens: the pane switches to that section, scrolls to the row in 400 ms `dur.glide` `ease.settle` and flashes a `spot.wash` band behind it for 1200 ms `dur.hold.flash` (the **Highlight sweep**, 200 ms `dur.clip` `ease.set`, then the hold), focus moves to the row's control. Empty: "No setting matches "{q}"."

**Command palette** (web/06 left two groups to this step, §8.33.1): feed every registry row (`{ id, label, keywords, section }`) into web/06's palette `SETTINGS` group, which lists only the section names until now; choosing a row navigates to `/settings/{section}` and runs the same scroll-and-flash jump as the settings search. Register the `EDITION` group ("Switch to the Glass edition…", opening the D3 confirm) through one function that returns nothing while `FLAGS.glassAvailable` is false, with a Vitest case that forces the flag true and finds the entry.

**One pane (viewport < 900 px: phones, 600–767 in the phone frame, and 768–899 inside the desktop frame with its sidebar):** `/settings` is the table of contents as a credits list (row 56 px: folio, title, dot leaders, the current value as a folio where one exists, e.g. `Appearance ........ CINEMATIC`, `Downloads & storage ........ 2.3 GB`, then `caret-right`); each section is a pushed page (**Page**: in x +24 → 0 px and fade over 320 ms `ease.settle`, out x 0 → −24 px over 224 ms `ease.lift`) with a back arrow in the running head. The search is a running-head `bare` `magnifying-glass` action that opens a full-screen search list (a history entry `?sheet=settings-search`, so browser back closes it) with the same results.

This 900 px switch is §8.0.9's tablet rule ("Phone structure below 900 px; from 900 px two panes"); the app frame around it (sidebar from 768 px, thumb index below) does not change it.

**Footer** (two panes: under the right pane; one pane: at the end of the table of contents): "Settings save as you change them." (the sentence "Changing the edition restarts the app." is added only when `FLAGS.glassAvailable` is true).

**No-profile guard:** sections that store per-profile values (appearance, both readings, listen, ambient, feedback's sounds, notifications' master, content) show a `NOTE` banner strip "No reading profile is active, so there's nowhere to save this yet." + `Choose a profile`, with their controls disabled.

**Server-backed sections** (content, notifications, the account block, security, members, backup, the edition row): *loading* (the section header renders; its rows are greeked at their exact heights with flicker; controls absent until data lands); *error* (a `CORRECTION` line under the header with the API message and a `quiet` `Retry` for that section only); *offline* (rows show their last known values with controls disabled and the caption "Needs a connection.", also as each control's tooltip). The web edition row is disabled offline too.

**Capabilities** (`GET /settings` → `capabilities`): `client_downloads` false hides Downloads & storage; `ocr` false hides dialogue rows; `collections` and `bookmarks` false hide their rows.

**Admin deep links:** a non-admin opening `/settings/members`, `/settings/backup` or the admin block of notifications sees the notice `ADMINISTRATORS ONLY` with the section's name and `Back to Settings`; the controls never render.

**Keys (web):** `/` focuses the settings search; `j` / `k` move to the next / previous section in the table of contents; `Enter` opens it; `Esc` returns focus to the table of contents (and closes the search results first).

### C. Every section and control (§8.30.2, web)

Rows state their scope in the description where §8.14.8 names one ("Saved for this profile", "Saved on this device").

1. **Profile & account** (`profile`): the profile block (avatar 56 (§7.25), name in Bodoni Moda Italic `type.subhead`, mood in `type.caption`; `Switch profile` secondary sm opening the picker as a pushed takeover by Dip; `Manage profiles` `quiet` → `ROUTES.profilesManage()`); shortcuts `Reading history →` (`ROUTES.history()`) and, for admins, `System status →`; the account credits (display name, `@username`, the `ADMINISTRATOR` credit for admins; `useCurrentUser`); `Password & security` → the pushed page `security`; `Members` (admin) → `members`; `Sign out` (destructive) → dialog "Sign out on this device?" with the 1000 ms arm (`useLogout`, then `/login`).
2. **Appearance** (`appearance`): **Edition** (section D); "Reduce motion in the app" as a single-select slug line `SYSTEM · ON` (`ON` forces the reduced variants regardless of the OS; per profile; A5); "Hyperlegible text" switch (default off, per profile; A5; `data-legible="on"`; caption "Easier-to-read text for decks, synopses, recaps and notices."); "Reading mode" `MANGA · NOVELS` (only when novels are enabled; the `features/content-mode` store, web K28).
3. **Reading: manga** (`reading-manga`), the profile defaults of the §8.14.8 controls the web has: Layout `STRIP │ SINGLE │ DOUBLE` (segmented control, 40 px; `web/23` appends `GUIDED` here and in the setup sheet when it builds guided view, so no profile can default to a layout the reader does not have yet); Direction `LEFT TO RIGHT │ RIGHT TO LEFT` with the captions "Webtoons and western comics" / "Manga"; Fit `WIDTH │ HEIGHT │ ORIGINAL`; Zoom stepper 50–300 % step 10 with `Reset`; Side margin (coarse pointer only) `0 · 5 · 10 · 15 · 20 · 25 %`; Strip width (fine pointer only) slider 480–860 px step 20 (per device); Gap between pages switch (web K29); Page turn `CUT │ SLIDE │ FADE` (web K33); Brightness slider −75 … 0 step 1 with the caption "Dims below your screen's lowest setting." (web K31); Warmth 0–100 step 1 (web K32); Colour `NORMAL │ SEPIA │ GREY`; Ground `BLACK │ INK │ SLATE`; Tap zones (three segmented rows `LEFT / CENTRE / RIGHT` × `PREVIOUS │ MENU │ NEXT`, `Reset`; web K34); Strip taps `MENU │ TAP TO SCROLL`; "Swipe sideways to change chapter" switch (coarse pointer only, default on); Cinema mode switch (web K30); "Auto next chapter" switch (default on); then **Previously on**: the single-select slug line `ALWAYS · AFTER N DAYS AWAY · NEVER` with, when `AFTER N DAYS AWAY` is chosen, the N stepper 3–60 days (`ruled` icon buttons, `type.folio.lg` value, digits roll on change), caption "Plays a short recap before you continue a series you haven't opened for a while.", stored in `mm.recap` (A2); "Continue automatically after a recap" `ON · OFF` (A2, default `ON`); and `Reset reader settings` (`quiet` → dialog "Restore every reader setting to its default?" with the 1000 ms arm). App-only rows (keep screen awake, lock controls, volume keys, refresh rate) are not rendered on the web.
4. **Reading: novels** (`reading-novels`): Default face (five tiles, each label in its own face; the Atkinson tile captioned "Designed for low vision"; the three extra faces load on this page through `skins/cinematic/reading-fonts.ts`); Size stepper 14–40 px; Line spacing 1.30–2.10 step 0.05; Measure 48–88ch step 2; Layout `SCROLL │ PAGED`; Page turn `CUT │ SLIDE │ FADE`; Stock (seven 48 × 48 swatches, "Aa" in each stock's ink on its page, the chosen one framed 2 px `spot`; Issue shown as the fallback Nitrate sample with the caption "Issue uses each book's own colour."; web K40); Bold text switch; "Justify and hyphenate" switch (the novel "Auto next chapter" row is app-only, §8.15.2, and is not rendered on the web); and the same **Previously on** and "Continue automatically after a recap" rows as the manga section (one setting, shown in both).
5. **Listen** (`listen`): `Voices` → opens the §8.16.5 voice picker from `web/15` in browse mode (kicker `THE VOICES`, filters `ALL · FEMALE ¹⁸ · MALE ¹³`, search, rows with `Hear` only, no casting); Default speed (the speed ruler 0.50–3.00× step 0.05 with the preset slugs `0.8 · 1 · 1.25 · 1.5 · 2`); Sleep timer default (a select: `Off · 5 · 10 · 15 · 30 · 45 · 60 min · End of chapter · End of next chapter`); "Auto-play the next chapter" switch (the 5 s countdown); "Keep the player visible" switch. "Shake to extend" is app-only and not rendered.
6. **Ambient** (`ambient`): Soundscape default: rows `OFF`, `MATCH THE MOOD` and the eight loops (name in `type.title`, the §9.4.2 one-line description in `type.caption`: Projector room "A soft hum with distant reel ticks.", Rain on glass "Steady rain on a window.", Night city "Distant traffic after dark.", Café "Low voices and cups.", Night wind "Wind across an empty street.", Low drone "A deep, even hum.", Afternoon park "Birds and far-off voices.", Temple bells "Slow bells over a quiet courtyard."), each loop with a `Hear` (secondary sm, A4 preview), as a radio group; Soundscape volume slider 0–100 % (per device, default 40); "Pause the soundscape during narration" switch (default off; caption "Otherwise it drops to 30 % while a chapter is read aloud."); "Page-tinted chrome" switch (default on); Auto-scroll default speed (ruler 0.50–3.00×); "Resume after I let go" switch (default on); "Pace by dialogue" switch (default off); Guided view auto-advance switch, then `PACE BY WORDS │ FIXED` and the fixed-hold stepper 2–10 s step 0.5 (default 3.5).
7. **Downloads & storage** (`storage`): the `StoragePanel` component from `web/17` unchanged (meter, retention, protection, the two download switches, `BY SERIES`, `Free up space`, the footer actions). `/downloads?tab=storage` stays the other way in.
8. **Content** (`content`): "Show mature content (18+)" switch (web K1; `useContentPreferences` / `useSetMatureContent`): turning it on opens the certificate dialog `web/07` built (§7.24); turning it off needs no confirmation and toasts "18+ content hidden on {profile}"; the switch shows its 12 px leader knob while saving; `useMatureToggleBlockReason()` disables it with its reason. Then `Manage pinned sources →` (`ROUTES.sources()`).
9. **Feedback** (`feedback`): "Haptic feedback" switch, rendered only when `'vibrate' in navigator && matchMedia('(pointer: coarse)').matches` (so never on iOS Safari or desktop), per device in `localStorage['mm.haptics']` (`on` default, `off`), which `skins/cinematic/haptics.ts` checks; no `Feel it` on the web. "UI sounds" switch (default **off**, per profile) and its volume slider 0–100 % (default 60 %, per profile), both through `web/02`'s `sounds.ts` store; `Play a sample` (`quiet`, plays the `set` cue; disabled with the tooltip "Turn UI sounds on to hear them." while sounds are off).
10. **Notifications** (`notifications`): per profile, "Notify me about new chapters" switch (`reading_profiles.notify_enabled`, A6; caption "When this is off, new chapters don't reach your Library badge, Updates or the stop-press banner. Each series keeps its own bell for when you turn it back on."). Admin block (instance-wide, web K19–K22): the schedule strip `LAST CHECK 21:04 · NEXT ≈ 21:34 · EVERY 30 MIN` in `type.folio`, overdue in the `NOTE` tone "Expected 12 min ago. See System status." (link); "Check automatically" switch; "Check on startup" switch; the interval slider 5–120 step 5 with the folio `30 MIN` and the caption "The server enforces a 5-minute floor."; "Notify about new chapters" master switch; these four are a draft saved by `Save` (primary sm, loading segment) with "Saved." or the error line (`useUpdateSettings`, `useUpdateSettingsMutation`); the recent-checks list (up to 5 rows from `useUpdateRuns`, as on System status); "Source cache lifetime" number input in minutes (≥ 5; `PUT /settings { source_cache_ttl_minutes }`) with its own `Save`.
11. **Keyboard** (`keyboard`): the live shortcut registry from `lib/keyboard/` as credits rows (description → dot leaders → keycaps, §7.26: `⌘ ⌥ ⇧` on Mac, `Ctrl` elsewhere, `⌫` / `Del`), grouped General (always listing `Alt+T` "Go to notifications"), Navigation, then one group per screen that binds keys in sidebar order (Tonight, Library, Updates, Discover, Sources, Catalogue, Downloads, Collections, History, Bookmarks, Dialogue, The Numbers, Circle, Picks, Profiles, Settings, System status), then Series page, Reader, Novel reader, Listen, Recap, The Annual; empty groups are omitted. A "Single-key shortcuts" switch (default on) at the top.
12. **Admin** (`admin`, admins only): rows to `Backup & restore` (pushed `backup`), `Members` (pushed `members`) and `System status` (`ROUTES.status()`).
13. **Diagnostics** (`diagnostics`, only with `?debug=1`): the pre-flip `Edition (debug)` row from `web/02` (segmented `LEGACY │ CINEMATIC`, writing the `mm-skin-debug` cookie and restarting with its 200 ms fade to black; never writes `reading_profiles.skin`), plus two credits rows naming the development overlays with keycaps: "Layout grid ........ `mod+shift+g`" and "Motion timings ........ `mod+shift+m`" (development builds only).
14. **About** (`about`): credits `WEB VERSION ........ 2.6.1` (`WEB_VERSION`) and `SERVER ........ 3.5.0 (57)` (`useServerVersion`); `What's new` (opens `web/17`'s `WhatsNew` sheet or dialog); a row "This browser's copy" showing `UP TO DATE` in `set` or `A NEW EDITION IS READY` with `Reload` (`useWorkerUpdate`, `applyWorkerUpdate`); **Licenses** (anchor `#licenses`): a credits list, grouped `TYPE` (Bodoni Moda, Archivo, Newsreader, IBM Plex Mono, Literata, Source Serif 4, Atkinson Hyperlegible Next, Noto Serif and Noto Sans KR/JP/SC — all SIL Open Font License 1.1), `ICONS` (Phosphor Icons — MIT), `SOFTWARE` (Next.js, React, Tailwind CSS, Motion, Base UI, Embla Carousel, Sonner, Lenis, use-gesture, TanStack Query, TanStack Virtual, Zustand — MIT), `DEMO ART` ("Edition previews use procedural demo covers made for ManhwaManiacs."); package names in IBM Plex Mono, licence names in `type.caption`. Keep the list in `frontend/src/skins/cinematic/screens/settings/licenses.ts`.

**Web setting keys covered** (web K1–K51, inventory §19): K1 content; K17 security; K18 members; K19–K22 notifications admin; K23 backup; K24 and K25 are removed by decision (no presets, no palettes, no accent picker; not rendered); K26 stays in the Library toolbar; K28 appearance; K29–K34 reading: manga; K35–K39 reading: manga defaults (A4); K40–K44 reading: novels; K50–K51 downloads & storage; K2–K5 are edited in the profile form (`Manage profiles`); K7–K16, K27, K45–K49 are not settings rows.

### D. The edition picker and Stop the press (§8.30.3)

1. **Picker** (Appearance → Edition): kicker `EDITION`, subhead "Two versions of the same app." (`type.subhead`). Two cards side by side on desktop (6 columns each of the 12, or 4 each of the 8), stacked on phones. Each card: a 3:4 plate (`paper.1`) holding, centred at the plate's full height, a 9:16 frame (1 px `rule.2` border) with the **live preview**, then under the plate the edition name in `type.subhead` and a one-line description in `type.caption` `ink.60`, then the badge or button.
   - **Cinematic card:** the preview is `<iframe src="/skin-preview/cinematic">` rendered at 390 × 844 CSS px, `transform-origin: top left`, `transform: scale(frameWidth / 390)` (recomputed with a `ResizeObserver`), `overflow: hidden` on the frame, with `inert`, `tabindex="-1"`, `pointer-events: none`, `loading="lazy"`, `sandbox="allow-scripts allow-same-origin"`, `aria-hidden="true"` and `title=""`; the card's text is its accessible name. Name "Cinematic" in Bodoni Moda; description "Cinematic: black stock, film titles, a magazine's rhythm."; badge `THIS EDITION` (1 px `ink.100` outline, `ink.100` text, `type.micro`).
   - **Glass card while `FLAGS.glassAvailable` is false:** the disabled plate at the same 3:4 size: `paper.1`, 1 px `rule.1` frame, no iframe and no loop, kicker `NEXT ISSUE` (`type.kicker` in `ink.60`, the raised-stock rule), "Glass" in Bodoni Moda Italic `type.subhead` `ink.60`, caption "In preparation. It arrives in a later update."; no button; `aria-disabled="true"`. The caption under both cards is omitted. The command palette has no `EDITION` group.
   - **Glass card when the flag is true** (built now, exercised by the demo page): the `/skin-preview/glass` iframe, "Glass" set in Glass's own display face, the description "Glass: layered glass, springs and depth.", the secondary `Switch to Glass`, and the caption under both cards "Switching restarts the app. You'll come back to this page. Your edition follows this profile to every device."
   - **Glass's face without crossing the boundary:** a Cinematic screen may never import `src/skins/glass/**`. The thin settings route file (route files may import both skins) reads the Glass display face's class name from `skins.glass.fonts` and passes it to the Cinematic settings screen as the prop `glassNameClass` (`null` while the flag is false); the `EditionCard` applies it to the word "Glass" only.
   - Iframes mount only while the Appearance section is on screen (an `IntersectionObserver` on the picker) and unmount when it leaves. The preview page scrolls itself: a 12 s loop (`dur.loop.preview`), down 600 px and back, `ease.drift`; under reduced motion it does not scroll.
2. **The preview route** (§15.2, §15.10 S17): `frontend/src/app/(preview)/skin-preview/[skin]/layout.tsx` already exists (`web/00` stub, completed by `web/04`); verify it matches this paragraph and fix only what differs. It is a second root layout: `const { skin } = await params`; unknown skins call `notFound()`; it renders `<html data-skin={skin}>` with that skin's `fonts.ts` class names, imports `../../../globals.css` (Tailwind, `theme.generated.css`, the skins' `tokens.generated.css` and `motion.css`), mounts the skin's `duotone.tsx` (Cinematic's; Glass mounts none yet), and mounts no `Providers` and no Shell. `page.tsx` is a thin route file that renders `skins[skin].screens.tonight` inside `<PreviewQuery>` with `<HydrationBoundary state={dehydratedFixture}>` built from `@/skins/preview-feed.generated.json`. `preview-query.tsx` (`"use client"`) wraps a fresh `QueryClient` with `staleTime: Infinity` and `retry: false`. `generateStaticParams()` returns `cinematic` and `glass`. The page makes **zero** requests to `/api/*` (checked in the e2e spec); if it makes any, add that query to the fixture.
3. **Confirm** (only when the flag is true; a dialog on desktop, a sheet on phones): title "Restart in Glass?", body "The app closes and reopens in the Glass edition, on this page."; when a save is running in the service worker (`useOfflineState` reports an active save), the extra line "Downloads resume after the restart."; actions `Restart in Glass` (primary) and `Stay in Cinematic` (`quiet`, initial focus).
4. **Stop the press** (`frontend/src/skins/cinematic/overlays/StopThePress.tsx` at `z.shutter` 80, passed as the `outgoing` of A1), 500 ms `dur.stoppress`:

   | t (ms) | Motion |
   |---|---|
   | 0 | the `PATCH` starts (A1) and `mm.skin.t0` is written |
   | 0–160 | the whole app root racks out of focus: `filter: blur(0 → 6px) brightness(1 → 0.3)` (`blur.defocus`), `ease.turn` |
   | 80–456 | the column blades close top-down with the `ColumnWipe` blades of `motion.ts` in close-only mode: 200 ms per blade (`dur.wipe.close`), 16 ms stagger, `ease.settle`; 12 blades from 1024 px (80–456), 8 at 768–1023 (80–392), 4 on phones (80–328) |
   | 456 | on black, the masthead wordmark and its Oxford rule (3 px + 2 px gap + 1 px `ink.100`) cut in at the centre with no reveal; sound `impress` when UI sounds are on; no web vibration (`skin.switch` is not a web vibrate event) |
   | 500 | A1 awaits the `PATCH` for at most 1,000 ms more while the black frame with the masthead holds; success restarts, failure reverses |

   Failure: the blades reverse (200 ms `dur.clip` `ease.set`), the root racks back into focus (160 ms `ease.turn`), the error toast "Couldn't switch editions. Try again." (6000 ms hold, `proof` edge). Reduced motion: a 200 ms (`dur.clip`) fade to black with the masthead cutting in at 160 ms and the restart at 200 ms (after the same `PATCH` wait); the failure reverses with a 150 ms fade.
5. **Arriving in Cinematic**: after the Cinematic `Splash` (`web/06`) finishes, the Shell calls `takeSkinArrival()`; when it returns `glass`, it shows the subtitle toast "Now in the Cinematic edition." with `Undo`, held 10,000 ms (`dur.hold.toast.undo`; indefinite while hovered or focused). `Undo` runs the switch back to Glass with Stop the press and no confirm, with `undoable: false` (so the other edition shows no second undo toast). A boot-time mismatch restart (profile switch) and the debug row never write `mm.skin.from`, so they show no toast.
6. The `SKIN RESTART` entry (confirm tap → first splash frame, 1,500 ms budget) is logged by `web/02`'s recorder; do not log it twice.

### E. Pushed pages

1. **Password & security** (`/settings/security`, §8.30.4, web SG29–SG39):
   - Change password: fields Current, New ("At least 8 characters"), Confirm (§7.3 editorial fields, each with the `quiet` `Show` / `Hide` reveal carrying `aria-pressed`, label "Show password", `aria-controls`); validation lines "Enter your current password.", "Enter a new password.", "Password must be at least 8 characters.", "Password is too long." (> 4096), "The new passwords don't match.", "Your new password must be different from your current one."; `Change password` (primary, loading segment) with the caption "Changing it signs out every other device. This one stays signed in."; success toast "Password changed. Every other device has been signed out." Server codes: `invalid_credentials` (401) → a field error under Current "That isn't your current password." with focus back in the field (never signs out); `weak_password` (422) → the server's `message` under New; `rate_limited` → a `SLOW DOWN` line with the live `Retry-After` countdown, the button disabled until it reaches 0.
   - Where you're signed in (`useSessions`): rows with the device label ("ManhwaManiacs app on iPhone", "Firefox on Linux", "Unknown device"), the `THIS DEVICE` badge (row with a 2 px `spot` left bar), `LAST USED 3 H AGO · 10.0.0.2`, `SIGNED IN 12 SEP · EXPIRES 19 SEP` in `type.folio`; the current row's `Sign out` (secondary), others' `Revoke` (`quiet` `proof`) → dialog "Sign out {device}? It will have to sign in again." with the arm; `Refresh` (`quiet`, spinning leader while fetching); states loading, error, "No active sessions."
   - Sign out everywhere: a destructive area (`proof.wash` background, 2 px `proof` left edge) with "Revokes every session, this device included. Saved chapters stay on this device." and `Sign out everywhere` → dialog with the checkbox "I understand this signs me out here too"; the confirm enables only when checked **and** the 1000 ms arm has passed (`useLogoutAll`, then `/login`).
2. **Members** (`/settings/members`, admin, §8.30.5, web MB1–MB7): desktop table (min 640 px inside its own `overflow-x: auto` container): `MEMBER` (username + `ADMIN` / `YOU` badges), `STATUS` (`ACTIVE` in `set` / `DEACTIVATED` in `proof`), `JOINED`, `LAST SEEN`, `SESSIONS` ("No sessions" / "1 session" / "{n} sessions"), actions `Deactivate` / `Reactivate` (secondary sm) and `Delete` (`quiet` `proof`); the own row on `paper.4` with actions disabled and the tooltip "You can't deactivate or delete your own account." Phone: one block per member with the same facts as credits and the actions below. Explainer: "Registration is open. Deactivating signs a member out everywhere and blocks sign-in; deleting removes everything they own." Delete dialog: "Delete @{user}? Their profiles, library, progress, bookmarks and everything else they own are removed. This can't be undone." with the field "Type {username} to confirm" and the arm. Footer "{n} other accounts." + `Refresh`. States loading, error, empty ("Only your account so far."). Hooks: `useMembers`, `useSetMemberActive`, `useDeleteMember`.
3. **Backup & restore** (`/settings/backup`, admin, §8.30.6, web BK1–BK5): the staged-restore `NOTE` banner "A restore is staged. It applies the next time the server starts; the current database is kept." + `Cancel staged restore`; the nightly card `LAST NIGHTLY · OK · 28 SEP 03:00 · 412 MB` (or `UNKNOWN`, never shown as healthy; `LAST NIGHTLY · FAILED AT {PHASE} · 28 SEP 03:00` in `proof` when it failed); Export: explainer ("The whole database, every account. Keep it private."), the switch "Include caches (larger, warmer restore)", `Export backup` (primary; downloads the file; "Saved {filename}"); Restore: a destructive area with the explainer, `Choose backup file` (secondary; `.db` only; "{name} · 412 MB" or "No file chosen. Nothing is uploaded until you confirm."), validation "That isn't a .db file." / "That file is empty.", `Restore from this file…` (destructive) → dialog with the four bullets (replaces every account; sign-ins come from the backup; applies on restart; nothing of the current state is kept) and "Type RESTORE to confirm" (case-insensitive) plus the arm; then the dialog "Restore staged. Restart the server to finish." Hooks: `useBackupStatus`, `useExportBackup`, `useImportBackup`, `useCancelPendingRestore`.

### F. Cross-cutting

- **Reduced motion:** letter reveals fade 200 ms; the Highlight sweep shows the band at once (it still holds 1200 ms, then disappears without a fade); the search jump scrolls without smoothing; Page transitions become 150 ms fades; switch knobs, chip underlines and stepper digits change at once; Stop the press as in D4; the preview iframe does not scroll; sheets and dialogs fade 150 ms. Leader dials and loading segments keep running.
- **Focus:** the double ring on every control; dialogs trap focus and start on the least destructive action; `Esc` closes the top layer.
- **Hit targets:** 44 × 44 CSS px on coarse pointers, 32 × 32 with 24 px spacing on fine pointers (sliders' thumbs carry a 44 px hit square).
- **Semantics:** switches `Base UI Switch` named by the row label; slug lines as radiogroups; the storage meter `role="meter"`; stepper values through `folioLabel()`.
- **Haptics and sound:** `toggle.on` / `toggle.off` and `select` play their cues when sounds are on; nothing vibrates on the web in Settings.

## Values you need (copied from `cinematic/DESIGN.md`)

| What | Value | Section |
|---|---|---|
| Grounds | `paper.0` `#000000`, `paper.1` `#0B0B0A`, `paper.2` `#121211`, `paper.3` `#1A1A18`, `paper.4` `#232220` | §2.1.1 |
| Inks | `ink.30` `#4D4B47`, `ink.45` `#7A7770` (on `paper.0` only), `ink.60` `#9A978F`, `ink.80` `#C9C6BE`, `ink.100` `#F3F0E8` | §2.1.1 |
| Accent and semantic | `spot` `#F4D03F`, `spot.wash` `rgba(244,208,63,0.16)`, `proof` `#FF5B4A`, `proof.wash` `rgba(255,91,74,0.12)`, `set` `#57D68D`, `rule.1` `#2B2A27`, `rule.2` `#3D3C38`, `scrim.modal` `rgba(0,0,0,0.78)` | §2.1.2–§2.1.4 |
| Stock swatches | Nitrate `#000000`/`#D9D6D0`, Ink `#0B0B0C`/`#E6E3DD`, Sepia Night `#15110C`/`#E8D8BE`, Dusk `#0D1117`/`#D3DAE3`, Moss `#0E130F`/`#D5DECF`, Rosewood `#160E10`/`#EBD5D8` (page/ink) | §2.1.6 |
| Durations | `dur.beat` 160, `dur.line` 240, `dur.column` 320, `dur.snap` 120, `dur.reduced` 150, `dur.clip` 200, `dur.page.out` 224, `dur.glide` 400, `dur.stoppress` 500, `dur.wipe.close` 200, `dur.arm` 1000, `dur.hold.flash` 1200, `dur.hold.toast.undo` 10000, `dur.loop.preview` 12000 (ms) | §4.2 |
| Curves | `ease.settle` `cubic-bezier(0.16,1,0.3,1)`, `ease.lift` `cubic-bezier(0.7,0,0.84,0)`, `ease.turn` `cubic-bezier(0.65,0,0.35,1)`, `ease.set` `cubic-bezier(0.2,0,0,1)`, `ease.drift` `cubic-bezier(0.37,0,0.63,1)` | §4.3 |
| Blur | `blur.defocus` 6 px | §2.5 |
| Switch | 44 × 24, 1 px `ink.45` outline, 16 px square knob inset 4 px; on: track `spot`, knob `#000`; knob 160 ms `ease.set` | §7.21 |
| Slider | track 2 px `rule.2`, fill `ink.100`, thumb 2 × 20 px (3 × 28 dragging), value flag `#000` box 1 px `ink.100` border | §7.20 |
| Segmented control | 40 px tall, 1 px `rule.2` frame and dividers, active `ink.100` + 2 px `spot` underline sliding 320 ms `ease.settle` | §7.5 |
| Dialog | `paper.3`, 1 px `ink.30` border, max width 560, Insert in 320 ms (barrier 200 ms), out 160 ms fade | §7.10 |
| Type | `type.subhead` Bodoni Moda 600 (20/24 · 22/28 · 24/28 · 24/28); `type.section` Bodoni Moda Italic 600 (24/28 · 28/32 · 32/36 · 36/40, −0.020em); `type.ui` Archivo 500 15/20 phone, 14/20 desktop; `type.caption` 13/16; `type.folio` Plex Mono 500 12/16; `type.folio.lg` 15/20; `type.micro` Archivo wdth 62 wght 700 10/12 +0.12em | §3.2 |

## File layout

```
frontend/src/features/skin/…                               (runSkinSwitch, takeSkinArrival; + tests)
frontend/src/features/recap/recap-setting.ts               (+ .test.ts)
frontend/src/features/settings/search.ts                   (+ .test.ts)
frontend/src/features/reader/reader-prefs.ts               (seriesDefaults and the ambient fields of A4, each only if missing; + tests)
frontend/src/features/reader/soundscape-preview.ts         (A4; web/23 replaces it)
frontend/src/features/novels/{preferences,settings}.ts     (bookDefaults, soundscape, resumeAfterRelease, each only if missing; + tests)
the module that owns mm.listen-settings                    (sleepDefault, autoPlayNext, keepPlayerVisible, only if missing; + tests)
frontend/src/features/preferences/…                        (setBootA11y if missing; source_cache_ttl_minutes type)
frontend/src/features/profiles/hooks.ts                    (useSetNotifyEnabled)
frontend/src/features/app/…                                (useServerVersion)
frontend/src/lib/cover-url.ts                              (pass /skin-preview/ through, only when A8 finds the skin resolving covers through it; + test)
frontend/src/skins/cinematic/screens/settings/
  SettingsScreen.tsx  registry.ts  licenses.ts  Contents.tsx  SettingsSearch.tsx  SectionPane.tsx
  sections/{Profile,Appearance,ReadingManga,ReadingNovels,Listen,Ambient,Storage,Content,Feedback,Notifications,Keyboard,Admin,Diagnostics,About}.tsx
  pages/{Security,Members,Backup}.tsx
  edition/{EditionPicker,EditionCard,NextIssuePlate,ConfirmSwitch}.tsx
  keys.ts
frontend/src/skins/cinematic/overlays/StopThePress.tsx
frontend/src/skins/cinematic/Shell.tsx                     (arrival undo toast)
frontend/src/skins/cinematic/index.ts                      (wire settings, remove it from PENDING)
frontend/src/app/(preview)/skin-preview/[skin]/{layout,page,preview-query}.tsx
frontend/src/app/(preview)/skin-preview/[skin]/edition/page.tsx   (the dry-run demo page: ?demo=stop-the-press, stop-the-press-fail, edition-flag-on)
frontend/src/app/(app)/settings/…                          (the thin route file passes glassNameClass; no other logic)
frontend/src/skins/preview-feed.generated.json             (generated by design/build.mjs)
frontend/public/skin-preview/covers/01.webp … 06.webp      (generated by design/build.mjs)
design/previews/demo-feed.json, design/previews/covers/01–06.webp, SOURCES.md; design/build.mjs (copy step)   (the one design/ exception)
frontend/e2e/cinematic/web-18-settings.spec.ts
docs/redesign/proof/web-18/                                (plan.md, routes.txt, screenshots, report.md)
```

The demo page `/skin-preview/cinematic/edition` (a sibling of `web/04`'s `primitives` gallery and `web/06`'s `shell` page, under the same preview root layout; it mounts the skin's `ToastHost` itself) runs with no `PATCH`, no cookie and no reload: `?demo=stop-the-press` plays Stop the press, holds the black frame 600 ms and then reverses; `?demo=stop-the-press-fail` shows the failure path with its toast; `?demo=edition-flag-on` renders the `EditionPicker` with `glassAvailable` forced true through a prop (the Glass card with its iframe and `Switch to Glass`, the caption under both cards, and the confirm dialog on desktop or sheet on phones), whose confirm runs the dry-run Stop the press. The thin route file `frontend/src/app/(app)/settings/[[...section]]` (or the files `web/00` wrote) stays thin.

## Commit plan (small commits, push after each)

1. `feat(web/18): skin switch orchestration and arrival marker` (A1).
2. `feat(web/18): shared recap setting mm.recap` (A2).
3. `feat(web/18): settings search and reading, listen and ambient defaults` (A3–A7).
4. `design: edition preview fixture and copy step` (A8, only the `design/` paths and the two generated outputs).
5. `feat(web/18): skin preview page, fixture wiring and the edition demo page`.
6. `feat(web/18): cinematic settings structure, contents and search`.
7. `feat(web/18): cinematic settings sections`.
8. `feat(web/18): edition picker, stop the press and the undo toast`.
9. `feat(web/18): security, members and backup pages`.
10. `test(web/18): e2e checks and proof screenshots`.

`git add` exact paths; **no** `Co-Authored-By`, no "Generated with" line, no AI attribution; `git push origin feat/vps-slim-source-native` after each. Never commit secrets, `.env*` or `.claude/`.

## Acceptance criteria

- [ ] `settings` is gone from the Cinematic `PENDING` set; the completeness test passes.
- [ ] From a 900 px viewport the screen shows the two panes with numbered sections (folios with no gaps over the visible sections), the search with the scroll-and-flash jump, pushed pages under `← {Parent}`; phones show the credits-list contents with current values and pushed sections; tablets switch at 900 px.
- [ ] Every row of section C exists with the listed ranges, defaults and scopes, and edits the same store the readers use (changing a manga default in Settings changes a series with no own value when the reader opens; Vitest covers the fallback functions).
- [ ] `mm.recap` has exactly the shape `{mode, seriesDays, chapterDays, skipSeries}` with the §15.6 default; `NEVER`/`ALWAYS`/`AFTER N DAYS AWAY` map to `off`/`always`/`ask` with `seriesDays = N`; the row appears in both reading sections and edits one value; `mm.recap.autoContinue` defaults to `true`.
- [ ] The command palette (`mod+k`) finds individual settings rows (typing "warmth" lists Reading: manga → Warmth and jumps there with the flash); with the flag false it has no `EDITION` group, and the Vitest with the flag forced true finds "Switch to the Glass edition…".
- [ ] The edition picker shows the live Cinematic preview (scaled iframe, inert, self-scrolling 12 s loop, mounted only while visible) and, with `glass_available` false, the disabled `NEXT ISSUE` plate with no button; the footer omits the restart sentence; the palette has no `EDITION` group.
- [ ] `/skin-preview/cinematic` renders Tonight from the fixture with no Shell, no Providers and zero `/api/*` requests; `/skin-preview/glass` renders (Glass's PENDING screen) without errors; `/skin-preview/other` is a 404.
- [ ] `runSkinSwitch` passes its Vitest cases (success order, timeout, error, `undoable`, one-shot arrival); the demo page's dry runs show Stop the press at 0–160 / 80–456 / 456 / 500 ms and the failure reversal; with `sessionStorage['mm.skin.from'] = "glass"` set before load, the Cinematic Shell shows "Now in the Cinematic edition." with `Undo` for 10 s.
- [ ] Content: turning 18+ on goes through the certificate dialog; off toasts "18+ content hidden on {profile}".
- [ ] Feedback: the haptics row renders only on coarse pointers with `navigator.vibrate`; UI sounds default off per profile; `Play a sample` plays `set`.
- [ ] Notifications: the per-profile master writes `notify_enabled`; the admin block saves as a draft; the cache lifetime refuses values under 5.
- [ ] Security, Members and Backup work end to end against the dev stack, with the arm delay and the heavy confirmations (checkbox, typed username, typed RESTORE); a non-admin sees `ADMINISTRATORS ONLY` on the admin pages.
- [ ] Diagnostics renders only with `?debug=1` and switches `LEGACY │ CINEMATIC` with its 200 ms fade.
- [ ] Reduced motion per section F (the e2e spec emulates `reducedMotion: "reduce"`: the search jump sets `scrollTop` without smoothing, the preview iframe's document does not scroll, the demo Stop the press is a 200 ms fade).
- [ ] Keyboard: `/`, `j`, `k`, `Enter`, `Esc` work in Settings; every control is reachable in order with the double ring; route focus lands on the `h1`; titles read `Settings · ManhwaManiacs` and `{Section} · Settings · ManhwaManiacs`.
- [ ] Hit targets: at 390 × 844 every interactive element is at least 44 × 44 CSS px (the e2e spec walks every section); at 1440 × 900 at least 32 × 32.
- [ ] Contrast: `ink.45` only on `paper.0`; on `paper.1` plates, dialogs, sheets and banner strips those roles render `ink.60`.
- [ ] Per-skin difference: the Glass skin's `settings` screen is still `PENDING`; the shared modules (A1–A7) contain no Cinematic copy or tokens, so Glass (`web/39`) reuses them; lint passes (no Glass or legacy imports under `src/skins/cinematic/**`).
- [ ] `node design/build.mjs --check`, `npm run typecheck`, `npm run lint` (0 errors, 0 warnings), `npm run test` and `npm run build` pass; every baseline test still passes.

## Verification

From `/srv/manhwamaniacs/dev/ManhwaManiacs`, one at a time, `free -m` first (stop if `available` < 1024 MB):

```bash
free -m
node design/build.mjs --check
ls design/                   # find the node:test self-check files shared/00 wrote (*.test.mjs)
node --test design/*.test.mjs   # they must still pass, since build.mjs changed
cd frontend
npm run typecheck
npm run lint                 # baseline: exit 0, 0 errors, 0 warnings
npm run test                 # every baseline test plus the new ones
free -m
npm run build                # baseline: exit 0; nothing else running
```

This step changes nothing under `mobile/` or `backend/`. Prove it on your own commits, not on a range (the mobile, backend and shared sessions push to the same branch in parallel, so a range diff shows their work too): `for c in <each commit SHA you made in this step>; do git show --name-only --format= "$c"; done | grep -E '^(mobile|backend)/'` must print nothing. The other suites are therefore not re-run here; their sessions run them and keep the baseline: `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze` (No issues found), `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter test` (all 2012 passed) and `cd backend && .venv/bin/python -m pytest -q --no-header`.

**Visual proof.** Start the dev stack with `free -m && backend/scripts/dev_stack.sh start` (the dev stack of `backend/scripts/README-dev-stack.md`: uvicorn on 127.0.0.1:8010 against the dev SQLite under `/srv/manhwamaniacs/dev/data/`, never production data; the script already sets `MM_NOVELS_ENABLED=true`, turns rate limits off and leaves the AI key unset; run `backend/scripts/dev_stack.sh seed` once if the `demo` account does not exist yet), then the web client with `cd frontend && free -m && NEXT_PUBLIC_API_URL=/api BACKEND_INTERNAL_URL=http://127.0.0.1:8010 npx next dev -p 3010` (both variables are required: without `NEXT_PUBLIC_API_URL=/api` the browser calls `http://127.0.0.1:8000` directly (`src/config/env.ts`), and without `BACKEND_INTERNAL_URL` the `/api` rewrite in `next.config.ts` targets port 8000). Write `docs/redesign/proof/web-18/routes.txt`:

```
/settings
/settings/appearance
/settings/reading-manga
/settings/reading-novels
/settings/listen
/settings/ambient
/settings/storage
/settings/content
/settings/feedback
/settings/notifications
/settings/keyboard
/settings/admin
/settings/about
/settings/security
/settings/members
/settings/backup
/settings/diagnostics?debug=1
/skin-preview/cinematic
```

and capture at 1440 × 900 and 390 × 844, plain and with the grid overlay:

```bash
free -m
cd frontend
MM_PROOF_USER=<demo user> MM_PROOF_PASSWORD=<demo password> node scripts/proof.mjs --step web-18 --skin cinematic --routes /srv/manhwamaniacs/dev/ManhwaManiacs/docs/redesign/proof/web-18/routes.txt --grid
free -m
MM_PROOF_USER=<demo user> MM_PROOF_PASSWORD=<demo password> node scripts/proof.mjs --step web-18 --skin cinematic --routes /srv/manhwamaniacs/dev/ManhwaManiacs/docs/redesign/proof/web-18/routes.txt --reduced
```

The credentials are the seeded demo account's, from `backend/scripts/README-dev-stack.md` (never hard-code them in a file). `--grid` saves a `-grid` copy of every shot and `--reduced` a `-reduced` set; both viewports (1440 × 900 and 390 × 844) are captured by default.

Then, from `frontend/`:

```bash
free -m
E2E_BASE_URL=http://127.0.0.1:3010 MM_PROOF_USER=<demo user> MM_PROOF_PASSWORD=<demo password> npx playwright test e2e/cinematic/web-18-settings.spec.ts
```

The spec signs in as the seeded admin `demo` (and once as a non-admin account that the spec creates in its setup (`POST /auth/register` with the username `proof-reader` and a password generated at run time; the dev stack runs with registration open) and deletes as the admin in its teardown through the endpoint `useDeleteMember` calls), sets `mm-skin-debug=cinematic`, and saves `docs/redesign/proof/web-18/state-*.png` for: the search results and the flashed row, the no-profile banner, a server-backed section loading and in error (`page.route` to fail `/api/settings`), the certificate dialog, the confirm-switch dialog and sheet (`/skin-preview/cinematic/edition?demo=edition-flag-on`), the Stop the press frames at 100, 300 and 470 ms and the failure toast (`/skin-preview/cinematic/edition` demos), the arrival undo toast, the security page with a `rate_limited` answer mocked, the members delete dialog, the backup restore dialog. It asserts zero `/api/*` requests from `/skin-preview/cinematic`, the hit targets, focus, titles and reduced-motion checks. Stop `next dev` and the dev stack afterwards.

## Report back

Reply with:
1. The acceptance checklist, each box ticked or explained.
2. Commits (short SHA and message), confirmed pushed; call out the `design:` commit separately.
3. `docs/redesign/proof/web-18/` with the file count and the states captured.
4. Test counts: Vitest passed / failed / total vs the baseline total, `node --test design/*.test.mjs`, lint errors and warnings, typecheck, `next build` result and time, e2e passed / failed.
5. The lowest `free -m` available value seen.
6. Open issues: stores you had to create because an earlier step lacked them, anything in §8.30.2 the web could not do, deviations with reasons (including the 7-day `mm.recap` default resolution).

Next prompt: `docs/redesign/prompts/web/19-cinematic-ai-picks-similar-recap.md`
