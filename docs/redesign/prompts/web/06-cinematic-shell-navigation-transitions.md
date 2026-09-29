# Web 06 · Cinematic shell, navigation, transitions, overlays and the Press start splash

## Goal

Build the Cinematic frame that every web screen will live in: the `Shell` with its six frames (Bare, Takeover, Desktop, Phone, Reader, Page), the session and profile guards, the desktop **Contents** sidebar (248 px, the 72 px spine), the **running head** (56 px desktop, 44 px phone), the phone **thumb index** (Tonight · Library · Discover · Downloads · Index), route transitions through React `ViewTransition` (Page, Match cut, Dip, Cut + Set + Folio flip), the **Column wipe**, **Dip** and **Iris** overlays that finish before `router.push`, the global key map with the `g` sequence, the command palette "Index", the keyboard sheet, the status screens (in-frame 404, route error, root error, offline fallback), the "no longer available" notice, content mode, the stop-press banner, the first-run note, the offline badge and the rating-card host, the **Press start** splash, the motion-timings overlay and the Lenis hook for Tonight and The Annual. After this step a Cinematic user (reached through the debug row) moves through a complete frame whose screens are still the skin-neutral pending screen; web/07 onward replace those screens one cluster at a time. Legacy users see no change.

## Read first

1. `docs/redesign/cinematic/DESIGN.md`
   - §2.2.2 grid, **horizontal safe areas** and the debug overlays; §2.4 `z.*` layers; §2.1.4 `scrim.head` and §2.8.3 `scrim-head` (`--scrim-fade`, `isolation: isolate`, applied as `before:scrim-head`).
   - §4.2, §4.3, §4.5 rows **Cut, Set, Folio flip, Page, Match cut, Dip, Column wipe, Iris, Rule slide, Letter set, Rule draw**, §4.7, §4.8 (rows for column wipe, iris, match cut, page, dip, sidebar collapse, rule slide, toasts).
   - §5 events `nav.change`, `longpress.open`, `reader.enter`, `profile.select`, `splash.impress`; §6 cues `tick` (for `nav.change`), `wipe` (`reader.enter`), `reel` (`splash.reveal`).
   - §7.13 running head (phone and desktop tables), §7.14 thumb index, §7.15 Contents sidebar **and its route table** ("Which item lights and what the breadcrumb names"), §7.11 "Stacking with the stop-press banner", §7.24 rating card (the card itself is web/07), §7.29 content-mode switch.
   - §8.0.1 frames, §8.0.2 navigation map, §8.0.3 route contract and **shell branches**, §8.0.4 transitions (including the web `transitionTypes` notes), §8.0.5 platform rules (mobile web and desktop web columns, the long-press row, edge swipes), §8.0.6 global web keys and **the `g` sequence**, §8.0.7 `glass_available`, §8.0.8 content mode, §8.0.9 tablet and landscape, §8.0.10 no longer available.
   - §8.2 splash and pre-roll (outcomes), §8.5 steps 1–3 of the Iris (mechanics only; the picker is web/07), §8.14.2 the Column wipe (steps 1–4, reduced motion, tap to skip, the entry kinds), §8.32 status screens, §8.33 global overlays (command palette, keyboard sheet, stop-press, first-run note, toasts / rating card / offline badge).
   - §10.1.1 trigger `"signal"` (a title starts 480 ms after a match cut), §12.2 wordmark and stacked lockup, §12.3 web favicon and manifest lines, §12.4 **the Press start timeline**.
   - §14.4 (skip link, route focus, `document.title`, forced colours, hidden chrome leaves the tab order), §14.5, §14.6.
   - §15.2 (`Shell.tsx`, `Splash.tsx`, `motion.ts` row with `ColumnWipe` and `Iris`, `motion-timings.tsx`, the view-transition paragraph, the home-route paragraph, the service-worker paragraph), §15.6, §15.9 motion-timings overlay.
2. `docs/redesign/glass/DESIGN.md` §15.10 row **G5**: the splash flag is keyed per skin (`mm.skin.splash.cinematic`), which supersedes the single key named in cinematic §12.4; web/02 implemented the per-skin key.
3. `docs/redesign/inventory/00-decisions.md` (web gets a full desktop design: sidebars, hover states, keyboard-first navigation; mobile web mirrors the phone app).
4. `docs/redesign/stack-decision.md` §2.2 (`app/` thin route files, `components/keyboard` and `components/command-palette` logic moves to `lib/` first), §2.4, §2.5.
5. `docs/redesign/inventory/web.md` §2 (G1–G42 frame, guards, sidebar, topbar, profile chip, tab bar, first-run banner, floating layers), §2.8 (CP1–CP12 command palette), §2.9 (keyboard layer and every binding), §2.10 (S1–S5 status screens), §20 MO1, MO15, §21 items 3, 4, 5, 9, 10, 13.
6. `docs/redesign/00-baseline.md`.
7. Code you build on: `frontend/src/components/layout/app-shell.tsx` (the legacy guards to replicate as logic, lines around `AuthenticatedShell` and `StaleProfileCheck`), `frontend/src/app/providers.tsx`, `frontend/src/lib/keyboard/*`, `frontend/src/components/command-palette/{commands,fuzzy}.ts`, `frontend/src/features/{auth,profiles,offline,updates,library,content-mode,preferences}/*.ts` hooks, `frontend/src/skins/{index,types,server}.ts`, `frontend/src/skins/cinematic/**` from web/01–05, `brand/cinematic/` masters from shared/04, `frontend/public/offline-fallback-cinematic.html` from web/02.

## Preconditions (stop and report if any fails)

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs
git status --short && git branch --show-current     # clean inside frontend/ (other sessions' files elsewhere are theirs; never stage them); feat/vps-slim-source-native
ls frontend/src/skins/cinematic/primitives/{Sheet,Dialog,ToastHost,Menu,Notice,FolioFlip,ContentModeToggle,ContentModeChip,BannerStrip}.tsx
ls brand/cinematic frontend/public/favicon.svg frontend/public/offline-fallback-cinematic.html frontend/src/skins/brand.generated.ts frontend/src/skins/cinematic/mark.generated.ts
grep -n "viewTransition" frontend/next.config.ts
grep -rn "export function coverTransitionName" frontend/src
```

If web/05's primitives, shared/04's brand masters, web/02's fallback page or web/00's `experimental.viewTransition` are missing, stop and report which step is incomplete.

## Skills to invoke

- `superpowers:writing-plans` first; save the plan at `docs/redesign/proof/web-06/plan.md`.
- `superpowers:subagent-driven-development` (or `superpowers:executing-plans`). Suggested slices: (a) no-pixel moves and guards, (b) sidebar, running head, thumb index, (c) transitions and overlays, (d) keys, palette, keyboard sheet, (e) status screens and notices, (f) splash, timings overlay, Lenis.
- `superpowers:test-driven-development` for `frames.ts`, `nav-map.ts`, `g-sequence.ts`, `wipe-geometry.ts`, `splash-timeline.ts`.
- `frontend-design:frontend-design`; `impeccable:impeccable` and `taste-skill:taste-skill` to critique the shell screenshots against `cinematic/DESIGN.md` (reject rounded, glassy or floating-pill suggestions: the thumb index is a flat black bar with a rule, not a floating pill).
- `superpowers:verification-before-completion` before claiming done.

## Rules for this session

- **RAM guard** before every build, test run, `next dev`, dev stack or Playwright run:
  ```bash
  test "$(free -m | awk '/^Mem:/{print $7}')" -ge 1024 || { echo "RAM guard: under 1 GB available, stopping"; exit 1; }
  ```
  One heavy command at a time; stop `next dev` and the dev stack before `npm run build`.
- **Boundaries.** Work in `frontend/` only. The skin imports only data modules, `@/lib/**`, `@/services/**`, `@/types/**`, `@/stores/**`, `@/config/**`, the contract and its own folder; route files under `app/` may import both skins. Never edit `backend/connectors/`; never touch production containers or `/srv/manhwamaniacs/{app,data}`.
- **Legacy stays identical.** With the `mm-skin` and `mm-skin-debug` cookies unset, every legacy screen, the legacy shell and the legacy palette must look and behave as before this step.
- **Utilities**: §2.8 / §3.5 names only; `node design/lint-utilities.mjs` passes.
- **Git.** Branch `feat/vps-slim-source-native`; explicit `git add` paths; conventional commits; **no AI or Claude attribution** of any kind (no `Co-Authored-By` trailer, no "Generated with" line, even if a tool reminder suggests one); no secrets or `.claude/`; push `git push origin feat/vps-slim-source-native` after each working step once `npm run build` passes.

## Scope: everything this step delivers

Paths are relative to `frontend/src/skins/cinematic/` unless they start with `frontend/` or `app/`.

### 1. No-pixel moves (first commit, legacy unchanged)

- Move `frontend/src/components/command-palette/{commands,fuzzy}.ts` and their tests to `frontend/src/lib/command-palette/` (stack-decision §2.2); update the legacy `CommandPalette.tsx` imports. No behaviour change; `npm run test` stays green.
- `frontend/src/lib/keyboard/single-key.ts`: the "Single-key shortcuts" preference (per profile, scoped localStorage key `mm.shortcuts.single`, `"on"` by default, read through `@/lib/scoped-storage`), and `KeyboardProvider` skips every binding whose combo has no modifier when it is `"off"` (§8.14.9, §8.30.2 row 12; the Settings switch is web/18). Add tests.
- `frontend/src/lib/not-available.ts`: `notAvailableKind(error)` returns `"series"` for `ApiError` codes `series_not_found`, `"source"` for `source_not_found`, `"not-browsable"` for `source_not_browsable`, else `null` (§8.0.10; gated content answers the same codes, so the wording never reveals 18+). Tested.
- If no hook exposes the server capabilities yet, add `useServerCapabilities()` to `frontend/src/features/preferences/hooks.ts` reading `capabilities {online_sources, client_downloads, ocr, collections, bookmarks, continue_reading, reading_progress}` from the existing `GET /settings` query (skin-neutral).

### 2. Frames and the shell — `Shell.tsx`, `shell/frames.ts`, `shell/Gate.tsx`, `shell/running-head-context.tsx`

- `frameFor(pathname)` (pure, tested in `frames.test.ts`): **Bare** for `/login`, `/register`; **Takeover** for `/profiles` (the picker, with or without `?switch=1`), `/welcome`, `/recap/…`, `/library/statistics/annual/…`; **Reader** for `/reader/:s/:k/:c` and `/read-all/…`; **Page** for `/novels/…`; **App** for everything else (including `/profiles/manage`, `/profiles/new`, `/profiles/:id/edit`, `/reader` and the 404). Inside App, the desktop frame (≥ 768 px: sidebar + running head) and the phone frame (< 768 px: running head + thumb index) are chosen **by CSS media queries on one server-rendered tree**, never by JavaScript width checks, so hydration is stable.
- Grids per width (§2.2.2, §8.0.9): below 600 px the phone frame on the 4-column grid; 600–767 px still the phone frame, laid out on the 8-column tablet grid (32 px margins, 16 px gutters); 768–1023 px the desktop frame with the spine, each screen's desktop layout on 8 columns; from 1024 px 12 columns (48 / 72 / 96 px margins at desktop / wide / cinema, content max 1760 px centred from 1440 px). The generated `--mm-grid-*` properties already switch at these breakpoints; the Shell's content area uses web/04's `Grid` so the sidebar's width is excluded from the grid. Horizontal safe areas: the running head, thumb index, toasts and bars inset their content by `max(var(--mm-grid-margin), calc(env(safe-area-inset-left) + 8px))` (and the right equivalent) while their `#000` grounds bleed edge to edge.
- The Shell sets `--mm-running-head-h` on its root (`56px` from 768 px; `calc(44px + env(safe-area-inset-top))` below), which sheets, column panels and sticky tabs from web/05 read.
- It mounts, once: `MotionRoot`, `DuotoneDefs`, `ToastHost` (with `anchorBottom` = thumb index height + 16 px on the phone frame, and `bannerHeight` from the stop-press banner), `GridOverlay` and the motion-timings overlay (development builds), the overlays host (item 6), the command palette (lazy, on first open), the keyboard sheet, the rating-card host, the stop-press banner, the first-run note and the splash.
- `useRunningHead({ title, back, trailing, overArt, breadcrumbTail })`: the context screens use to set the phone running title (`LIBRARY · UPDATES`), the back target, up to two trailing icon buttons, whether the bar sits over art, and the last breadcrumb segment on the desktop frame (`SOLO LEVELING`).
- **Gate** (G2–G7, same logic as the legacy `AuthenticatedShell`, reusing `useCurrentUser`, `resolveSessionGate`, `isSessionUnresolved`, `isPublicAuthPath`, `useActiveProfileStore`, `useProfiles`, `shouldRedirectToPicker`, `isSelectionGone`, `PROFILE_PICKER_PATH`): an unresolved session holds the splash (the web's `AuthPending`); a signed-out user on an app route goes to `/login` with a Dip; a signed-in user with no active profile goes to `/profiles` with a Dip; a stale remembered profile is cleared and goes to the picker; a probe that never reached the server does not redirect (the app renders on what the device has). The 401 and `profile_required` / `profile_not_found` handlers already in `app/providers.tsx` stay the source of truth; the Gate reacts to their state. The "signed out mid-session" toast and the picker's recovery toast are web/07.
- Replace whatever Shell stub web/00 left in `skins/cinematic/index.ts` with this `Shell`.

### 3. Contents sidebar (§7.15) — `shell/Sidebar.tsx`, `shell/SidebarView.tsx`, `shell/nav-map.ts`

- Width 248 expanded, 72 collapsed (the **spine**). Auto-spine at 768–1279 px; expanded from 1280 px. `mod+b` toggles; the width animates 320 ms `ease.turn`, labels fade out first (120 ms `dur.snap`) and back in last. Below 1280 px, `mod+b` or the toggle opens the 248 px sidebar as an overlay at `z.panel` over `scrim.modal`, closing on `Esc`, an outside click or navigation, with no content reflow. At ≥ 1280 px the sidebar pushes the content and the choice is stored per device in `localStorage['mm.sidebar']` (`expanded` | `spine`; not stored below 1280). Reduced motion: width changes at once, labels fade 150 ms.
- Head: the wordmark (Bodoni masthead at 20 px, "Manhwa" Roman + "Maniacs" Italic, `wght` 800, tracking −0.035em) with `rule.oxford` under it; in the spine, the `mm-mark` glyph. The splash hand-off flies to this wordmark's rect.
- Content mode: `ContentModeToggle` (web/05) under the head, only when novels are enabled; in the spine `M` / `N` stacked.
- Kickers `IN THIS ISSUE` then `THE BACK PAGES` (`type-kicker` `ink.45`), hidden in the spine.
- Items: folio (`type-folio` `ink.45`) + label (`type-ui` `ink.60`) + optional count (Plex Mono `ink.45`) at the right. In this issue: `01 Tonight` `/`, `02 Library` `/library`, `03 Updates` `/updates` (unread count from `useUnreadNotificationCount()`), `04 Discover` `/search`, `05 Downloads` `/downloads` (queued + downloading + failed, from `useOfflineState()`). Back pages: `06 Collections` `/library/collections`, `07 History` `/library/history`, `08 Bookmarks` `/library/bookmarks`, `09 Dialogue` `/ocr` (manga mode only, `isMangaOnlyRoute`), `10 The Numbers` `/library/statistics`, `11 Circle` `/circle`, `12 Picks` `/library/recommendations`. Footer: `Profiles` `/profiles/manage`, `Settings` `/settings`, `Status` `/admin/status` (admins only), and the collapse toggle (`bare` icon button `sidebar-simple` 24 Light, tooltip `Collapse sidebar` / `Expand sidebar` with the `mod+b` keycap, `aria-expanded`). Build every href with the contract's route builders. Capabilities hide items the server does not offer: `client_downloads` false hides Downloads, `ocr` false hides Dialogue, `collections` / `bookmarks` false hide those.
- States: hover label `ink.100` and folio `spot` (160 ms); active label `ink.100`, folio `spot`, a 2 px `spot` bar on the item's left edge at full item height, `aria-current="page"`, **exact section only** (`/library/collections` lights `06 Collections`, never `02 Library`); focus ring around the item. Spine: folio numbers only (Plex Mono 14), labels as tooltips (with the `g` shortcut, e.g. "Library  G 2"), counts as spot squares.
- `nav-map.ts` (pure, tested): the §7.15 route table mapping each route to the lit item and the breadcrumb (`No. 01 · TONIGHT`, `No. 02 · LIBRARY`, `No. 03 · UPDATES`, `No. 04 · DISCOVER` with `/ SOURCES` or `/ {source}`, `No. 05 · DOWNLOADS`, `No. 06 · COLLECTIONS` with `/ {shelf}`, `No. 07 · HISTORY`, `No. 08 · BOOKMARKS`, `No. 09 · DIALOGUE`, `No. 10 · THE NUMBERS`, `No. 11 · CIRCLE` with `/ {member}`, `No. 12 · PICKS`, `PROFILES`, `SETTINGS / {section}`, `STATUS`, `INDEX` for `/more` with nothing lit). Feature and book pages (`/sources/:s/series/:k`, `/library/:followedId`) and `/recap/…` keep the item lit before the navigation (held in shell state); on a cold load `02 Library` lights when the series is followed (`followedIdFor` from `features/library/followed-index.ts`) and `04 Discover` otherwise; the breadcrumb follows the same rule (`No. 04 · DISCOVER / SOLO LEVELING`). Every static `/library/...` path is matched before `/library/:followedId`.
- Viewport height below 500 px: the spine's section list scrolls inside it (`overflow-y: auto`) and its footer items fold into a `dots-three` menu at its bottom.
- `<nav aria-label="Contents">`. A section change fires `nav.change` (a no-op on the web) and the `tick` cue when sounds are on.

### 4. Running head (§7.13) — `shell/RunningHead.tsx`, `shell/RunningHeadView.tsx`, `shell/AccountMenu.tsx`

- **Desktop frame**: 56 px, `#000`, 1 px `rule.1` bottom; when a screen sets `overArt`, the bar is transparent with `before:scrim-head` (the bar sets `isolation: isolate` and `[--scrim-fade:64px]`) until 80 px of scroll, then turns `#000` (240 ms). Left: the breadcrumb (`type-folio` folio + `type-nav` segments), each segment a link with the tab states (hover `ink.100`) plus a 1 px underline at 4 px offset (160 ms); the section folio rolls with **Folio flip** on a section change. Right: the index search trigger (a 280 px `compact` field reading "Search or jump…" with the platform `mod+k` keycap, `⌘K` on Mac and `Ctrl K` elsewhere, that opens the command palette), the Updates bell (`badged` icon button `bell-simple` → `/updates`, count from `useUnreadNotificationCount()`, "99+" cap, the count announced in a polite live region when it changes), and the profile chip (32 px avatar + the profile name in `type-ui`) opening the **account menu** (web/05 `Menu`): display name, `@username`, an `ADMINISTRATOR` credit for admins, `Switch profile` (→ `/profiles?switch=1` with a Dip), `Settings`, `Sign out` (a `ConfirmDialog`, destructive with the arm: "Sign out on this device?", then `useLogout()` → `/login` with a Dip). No clock. Offline: an `OFFLINE EDITION` micro badge beside the breadcrumb for as long as the device is offline.
- **Phone frame**: min 44 px + `env(safe-area-inset-top)`, growing to the title line + 2 × 12 px at large root font sizes. Leading: back (`arrow-left` 24 Light, label "Back") on pushed screens (from `useRunningHead`), nothing on tab roots. Centre: the running title in `type-nav` `ink.60`, hidden while the page's masthead `h1` is visible and cross-fading in (160 ms) once it scrolls under the bar (an `IntersectionObserver` on the masthead). Trailing: up to two `bare` icon buttons from the screen. Surface: transparent over the masthead or art (`before:scrim-head` with `[--scrim-fade:44px]` when `overArt`); after 24 px of scroll `#000` with a 1 px `rule.1` bottom (160 ms). Content inset by the horizontal safe areas while the ground bleeds edge to edge (§2.2.2).
- **Offline edition** (both frames): `useOnlineStatus()` from `features/offline/hooks.ts` plus the session gate's unreachable state decide offline. Phone: the `OFFLINE EDITION` micro badge (1 px `ink.45` box, `#000` fill) sits under the running title for 4000 ms (`dur.hold.edition`) after the change, then collapses into a 16 px `wifi-slash` glyph at the trailing edge; tapping it opens a `Sheet` (kicker `OFFLINE EDITION`, "The server isn't reachable right now. Chapters you saved still open on this device.", primary `Go to Downloads`). On reconnection the badge reads `BACK ONLINE` for 2000 ms (`dur.hold.brief`). The web has no progress or bookmark outbox (they are the app's, `capabilities.md`), so the "Synced N reads" toast is not wired on the web.
- **Content-mode chip**: Library, Discover, Downloads and Index put web/05's `ContentModeChip` in their phone running head through `useRunningHead`; hidden when novels are disabled.

### 5. Thumb index (§7.14) — `shell/ThumbIndex.tsx`, `shell/ThumbIndexView.tsx`

- Height 56 px + `env(safe-area-inset-bottom)`; `#000`; 1 px `rule.1` top; `<nav aria-label="Sections">`. Tabs: 1 `TONIGHT` (`moon-stars`), 2 `LIBRARY` (`books`), 3 `DISCOVER` (`compass`), 4 `DOWNLOADS` (`download-simple`), 5 `INDEX` (`list-numbers`).
- Cell: icon 24 (Light; Fill when active) above the label in `type-nav` 10/12; the label keeps `wdth` 62 at every text size, scales with the root font size but is capped at 13 px and never goes below 10 px (`font-size: clamp(10px, 0.625rem, 13px)`, `white-space: nowrap`), and takes tracking +0.06em from a root font size of 130 %. Active: `ink.100` icon and label plus the **thumb notch**, a 24 × 2 px `spot` bar on the cell's top edge that slides between cells with **Rule slide** (320 ms `ease.settle`; reduced motion fades). Inactive: `ink.60`.
- Badges (spot square, `#000` Plex Mono 10, min 16 × 16, "99+"): Library = unread update count; Downloads = queued + downloading + failed (after the 18+ filter of web/07); Index = unread Circle letters (Circle arrives in web/22; no badge until then).
- Branches (§8.0.3): Tonight `/`; Library `/library`, `/library/browse`, `/updates`, `/library/collections…`, `/library/history`, `/library/bookmarks`; Discover `/search`, `/sources`, `/sources/:id`, `/ocr`, `/library/recommendations`; Downloads `/downloads`; Index `/more`, `/settings…`, `/admin/status`, `/library/statistics`, `/circle…`, `/profiles/manage`.
- Tapping the active tab: first tap scrolls to top (400 ms `dur.glide` `ease.settle`; reduced motion jumps), second tap goes to the branch root, and on Discover a third tap focuses the search field (dispatches `mm:focus-search`, which the Discover screen handles). Long-press 450 ms: Library → `/updates`, Downloads → `/downloads#queue`, Index → `/profiles?switch=1`; haptic `longpress.open`; the non-gesture paths are the destinations' own entries.
- Visible on every screen of the five branches including second-level lists; hidden on feature and book pages, readers, auth, the picker, onboarding, The Annual and recap title cards; it never minimises.
- A section change is a **Cut**: the new branch's content runs **Set** (its lists' `useEntrance`), the masthead kicker's folio rolls with **Folio flip**, and `nav.change` / `tick` fire.

### 6. Transitions and overlays — `shell/PageTransition.tsx`, `shell/CineLink.tsx`, `shell/use-cine-router.ts`, `view-transitions.css`, `shell/Overlays.tsx`, `shell/wipe-geometry.ts`, `shell/reader-entry.ts`

- **ViewTransition** (§8.0.4, §15.2). Import React's view-transition component from `"react"` under the name Next 16.2.9's bundled React exports (check with `grep -o "unstable_ViewTransition" frontend/node_modules/next/dist/compiled/react/cjs/react.development.js | head -1`; use `ViewTransition` if that is the export). The page wrapper around `<main>` content is `<ViewTransition default="none" enter={{ "nav-forward": "mm-page-in", "nav-back": "mm-page-back-in", "nav-section": "mm-dip-in", "nav-match": "mm-dissolve-in", default: "none" }} exit={{ "nav-forward": "mm-page-out", "nav-back": "mm-page-back-out", "nav-section": "mm-dip-out", "nav-match": "mm-dissolve-out", default: "none" }}>`. The two extra types implement the §8.0.4 rows "Section change" (Dip on the desktop frame, Cut on the phone frame) and "Drill-in from a poster" (everything except the shared cover dissolves 240 ms).
- `CineLink` wraps `next/link` and sets `transitionTypes` from a `nav` prop: `"forward"` (default), `"back"` (in-app back links), `"section"` (sidebar, thumb index, `g` jumps), `"match"` (a link whose poster carries a match-cut name). `useCineRouter().push(href, nav)` calls `router.push(href, { transitionTypes: [...] })`. Browser back (popstate) carries no type and gets `none`.
- `view-transitions.css` (imported by `app/globals.css` after `base.css`), values from §4.5:
  - Page: `::view-transition-new(.mm-page-in)` from `translateX(24px)`, opacity 0, 320 ms `var(--mm-ease-settle)`; `::view-transition-old(.mm-page-out)` to `translateX(-24px)`, opacity 0, 224 ms (`dur.page.out`) `var(--mm-ease-lift)`. Back reverses both over 224 ms: old `.mm-page-back-out` to `translateX(24px)` and opacity 0 with `ease.lift`, new `.mm-page-back-in` from `translateX(-24px)` and opacity 0 with `ease.settle`.
  - Dip (desktop frame, ≥ 768 px): old `.mm-dip-out` to opacity 0 over 160 ms `ease.lift`; new `.mm-dip-in` from opacity 0 over 240 ms `ease.settle` after a 200 ms delay (160 + the 40 ms `dur.hold.dip`), on the `#000` page. Below 768 px both are `animation: none` (Cut).
  - Match cut: `::view-transition-group(.mm-match-cut)` 480 ms `var(--mm-ease-turn)`; `html:active-view-transition-type(nav-back)::view-transition-group(.mm-match-cut)` 336 ms (`dur.match.back`); `.mm-dissolve-in` / `.mm-dissolve-out` 240 ms `ease.turn` opacity.
  - Reduced motion (`@media (prefers-reduced-motion: reduce)` and `html[data-motion="reduced"]`): page, back, dip and dissolve become 150 ms (`dur.reduced`) opacity cross-fades; the match-cut group gets `animation: none` and its old/new images a 200 ms (`dur.clip`) cross-fade.
- **Overlays host** at `z.shutter`, `aria-hidden`, pointer-events only for the skip tap:
  - `dip(then)`: a `#000` layer fades in 160 ms `ease.lift`, `await then()` (the navigation) during the 40 ms hold, fades out 240 ms `ease.settle`. Used for auth → picker, entering and leaving takeovers, leaving a reader, reader entries from anywhere but Tonight and series pages, and `Switch profile`. Reduced: 150 ms fade.
  - **Column wipe** (the `ColumnWipe` component; §8.14.2, §4.5): blades follow the current grid (4 below 600 px, 8 at 600–1023, 12 from 1024), each blade spanning from one column's left edge to the next column's left edge so margins and gutters are covered and blade edges land on column edges (geometry from `--mm-grid-columns`, `--mm-grid-margin`, `--mm-grid-gutter` and the 1760 px max, pure and tested in `wipe-geometry.ts`). **Close**: each blade `#000`, `scaleY` 0 → 1 from the top edge, 200 ms (`dur.wipe.close`) `ease.settle`, staggered 16 ms left → right (desktop 376, tablet 312, phone 248 ms). **Hold** 40 ms (`dur.hold.dip`): `router.push` runs as the last blade lands; haptic `reader.enter` and the `wipe` cue fire then. **Open**: blades retract `scaleY` 1 → 0 toward the bottom edge (transform-origin bottom), 280 ms (`dur.wipe.open`) `ease.settle`, 16 ms stagger (desktop 456, tablet 392, phone 328 ms). Totals 872 / 744 / 616 ms. A tap during the wipe jumps to the open state in 120 ms (`dur.snap`). If the first page is not decoded after the hold the blades still open (the reader shows its galley plate). Reduced motion: a 200 ms (`dur.clip`) cross-fade through black. Transform only, Motion `animate` with `stagger`, all through `play()` with the Column wipe member of `CineMotionName`.
  - `enterReader(href, { entry: "wipe" | "dip", prefetch })` in `reader-entry.ts`: `"wipe"` from Tonight, feature and book pages and recaps opened from them; `"dip"` from everywhere else (§8.0.4). `useReaderPrefetch(chapter)` returns pointer and focus handlers: after a 150 ms dwell (hover or focus) it prefetches the chapter manifest and first two pages at **P3** through web/03's sources limiter, and on press at **P1**. Use the prefetch web/03 exposes from `features/reader` (`grep -rn "prefetch" frontend/src/features/reader`); if none exists, add `prefetchChapterStart({ sourceId, seriesKey, chapterKey }, priority)` in `frontend/src/features/reader/prefetch.ts` (skin-neutral) calling the existing manifest fetch and page URLs through the limiter.
  - **Iris** (the `Iris` component; §8.5 mechanics; the picker's ring draw and fades are web/07): `irisClose(element, { x, y, radius })` animates `clip-path: circle(R at x y)` on the given takeover element from the viewport diagonal to the avatar radius, 480 ms `ease.turn`, resolving when it lands (the caller fires `profile.select`); `requestIrisOut({ x, y })` stores the point in shell state so the next route's content wrapper opens with `circle(0 at x y)` → `circle(diagonal at x y)` over 560 ms (`dur.iris.out`) `ease.settle`. A tap during the close skips to the open in 120 ms. Reduced motion: a 200 ms cross-fade. Both go through `play()` with the Iris member of `CineMotionName`.
- `motion.ts` re-exports `ColumnWipe`, `Iris`, `dip`, `enterReader` and `useReaderPrefetch` so every screen imports motion from one place (§15.2 lists `ColumnWipe` and `Iris` under `motion.ts`).
- Scroll: forward navigations and section changes start at the top; `nav-back` restores the previous scroll position (Next's default).

### 7. Focus, titles, skip link, mood (§14.4, §2.1.6)

- `useRouteFocus()`: after each pathname change (not a search-param change), once the new `main h1` exists, focus it (every masthead `h1` has `tabIndex={-1}`) and set `document.title` to `{h1 text} · ManhwaManiacs`. Reader and Page frames are left to web/12 and web/14 (they focus the reading surface).
- **Skip to content**: the first focusable element of the Shell; `sr-only` until focused, then top-left, a `paper.2` band with `type-ui`; it moves focus to `main h1`.
- Hidden chrome leaves the tab order (`visibility: hidden` / `inert` on the hidden sidebar overlay and on collapsed spine labels).
- **Mood grade**: `useShellMood()` returns the active profile's `mood`; Tonight, Library, Discover and Index pass it to the web/04 `MoodGrade` behind their mastheads; readers, auth, the picker and every other screen stay ungraded.

### 8. Global keys (§8.0.6) — `shell/GlobalKeys.tsx`, `shell/g-sequence.ts`

Registered with `useShortcut` from `@/lib/keyboard` in the groups `General` and `Navigation`:

| Key | Action |
|---|---|
| `mod+k` | Open or close the command palette |
| `mod+b` | Toggle the sidebar spine |
| `?`, `shift+?` | Keyboard sheet (reuse `HELP_SHORTCUT_KEYS`) |
| `/` | Focus the page's search field (dispatch `mm:focus-search`) |
| `Alt+T` | "Go to notifications": a listing-only registry entry with a no-op handler and `preventDefault: false`; the web/05 sonner hotkey moves focus into the toast region |
| `g` then `1`…`12` / `0` | Jump to a numbered section / Settings |
| `Esc` | Close the top layer (palette, sidebar overlay; Base UI layers close themselves) |
| `mod+shift+g` | Grid overlay (development builds) |
| `mod+shift+m` | Motion-timings overlay (development builds) |

- **The `g` sequence** (`g-sequence.ts`, a pure state machine plus a hook, tested): `g` arms for 1500 ms; `g 2`…`g 9` and `g 0` jump at once; `g 1` waits 600 ms for `0`, `1` or `2` (10, 11, 12) and otherwise jumps to `01`; `Enter` jumps to `01` at once; any other key, `Esc` or the timeout cancels. Targets: 1 `/`, 2 `/library`, 3 `/updates`, 4 `/search`, 5 `/downloads`, 6 `/library/collections`, 7 `/library/history`, 8 `/library/bookmarks`, 9 `/ocr` (manga mode only; in novels mode `g 9` cancels), 10 `/library/statistics`, 11 `/circle`, 12 `/library/recommendations`, 0 `/settings`; each navigates with `nav: "section"`. While armed a keycap chip `G 1_` shows at the toast anchor and fades 160 ms after the sequence ends. Keys consumed by the sequence never reach page bindings: listen in the **capture** phase on `window` and call `stopImmediatePropagation()` for consumed keys. The sequence is off in the Reader and Page frames (there `g` means "go to page" or "go to %"), while typing in a field, and when single-key shortcuts are off.
- **Long-press on mobile web** (§8.0.5): in the phone frame, a delegated listener calls `preventDefault()` on `contextmenu` for elements with the `.cine-press` class (posters, covers, cuttings, reader pages, thumb-index tabs, rows with row menus, source rows, profile avatars, the Listen mini player and the auto-scroll chip).

### 9. Command palette "Index" (§8.33.1) — `shell/CommandPalette.tsx`, `shell/palette-commands.ts`

- Lazy-loaded on first open. Scrim `scrim.modal`; panel `paper.2` with `data-stock="raised"`, 1 px `rule.2`, max width 720, max height 70 vh, placed 12 vh from the top; **Insert** motion; `z.dialog`.
- The web/04 `SearchField` `index` variant with the placeholder "Search or jump…" (`aria-label` "Search or jump") and an `Esc` keycap; `role="combobox"` with a `role="listbox"` of results.
- Groups by kicker in rank order: `LIBRARY` (series from `GET /library/search?q=&per_page=8`, 220 ms debounce, 40 × 60 covers), `SOURCES` (from `GET /sources`, with logos), `GO TO` (every route with its folio: "01 Tonight" … "12 Picks", "Index", "Profiles", "Settings", "Status" for admins), `ACTIONS` (Continue {series} from the first continue-reading row, Check for updates (the existing update-check mutation), Open settings, Toggle reading mode (only when novels are enabled), Sign out (the same `ConfirmDialog` as the account menu)), `EDITION` (absent while `FLAGS.glassAvailable` is false; web/18 adds it), `SETTINGS` (the settings sections by name: Profile & account, Appearance, Reading: manga, Reading: novels, Listen, Ambient, Downloads & storage, Content, Circle & privacy, Feedback, Notifications, Keyboard, Admin for admins, About; web/18 extends it to every row). Max 40 results, ranked with `rankCommands` / `groupCommands` from `@/lib/command-palette`, matched characters in `spot`.
- Row: leading visual (40 × 60 cover, source logo, route folio, or a 20 Regular action icon), title, subtitle (`type-caption`), the `↵` glyph on the active row; hover moves the highlight (`paper.4` + a 2 px `ink.100` left bar). Footer keycaps: `↑ ↓` navigate · `↵` open · the result count. Live region "Searching…" / "12 results". Empty: "Nothing matches "{q}"." Keys: `Esc`, `↑` / `↓` (wraps), `Home` / `End`, `Enter`, `mod+k` closes; focus returns to where it was.

### 10. Keyboard sheet (§8.33.2) — `shell/KeyboardSheet.tsx`

- A web/05 `Dialog` (max 720) titled "Keyboard", intro "Only what works on this screen is listed. Shortcuts pause while you type in a field.", then the live registry (`useRegisteredShortcuts()` + `groupShortcuts()`) as two-column credits lists (description → dot leaders → keycaps) in this group order (`CINEMATIC_GROUP_ORDER`, defined in the skin; the legacy `SHORTCUT_GROUP_ORDER` is untouched): General, Navigation, Tonight, Library, Updates, Discover, Sources, Catalogue, Downloads, Collections, History, Bookmarks, Dialogue, The Numbers, Circle, Picks, Profiles, Settings, System status, Series page, Reader, Novel reader, Listen, Recap, The Annual. Empty: "No shortcuts on this screen." The General group always lists `Alt+T` "Go to notifications".

### 11. Status screens (§8.32) and "no longer available" (§8.0.10)

- `screens/system/NotFound.tsx`: a folio numeral `p. 404` in Bodoni Moda Roman at `type-numeral` × 1.5 in `ink.30`, `aria-hidden`; kicker `NOT IN THIS ISSUE`; `TypedHeadline as="h1"` "This page doesn't exist."; deck on the desktop frame "It may have been renamed, or the series it pointed to left your library. Press ⌘K to search everything." (the keycap reads `Ctrl K` off Mac), on the phone frame "It may have been renamed, or the series it pointed to left your library. Search everything from Discover." with `Discover` as a `link` to `/search`; actions `Back to Tonight` (primary → `/`) and `Open library` (quiet → `/library`). `app/(app)/not-found.tsx` renders it when `await getSkin()` is `"cinematic"` and the legacy body otherwise; unmatched URLs already reach it through web/00's `app/(app)/[...missing]/page.tsx`.
- `screens/system/RouteError.tsx` (client): the web/05 `Notice` with kicker `CORRECTION`, headline "Something broke on this page.", deck "Nothing was lost; trying again usually fixes it.", actions `Try again` (`reset()`) and `Back to Tonight`, and a `REF {digest}` keycap; when the error is network-unreachable (`isNetworkUnreachableError`): kicker `OFFLINE EDITION`, "The server didn't answer.", deck "It may still be starting, or the connection dropped. Your library is untouched." `app/(app)/error.tsx` imports only this component and the legacy error body, and picks by `document.documentElement.dataset.skin === "cinematic"` (never import `@/skins` there, which would pull every screen into the error bundle).
- Root error `frontend/src/app/global-error.tsx`: when `document.cookie` holds `mm-skin=cinematic` or `mm-skin-debug=cinematic`, render the Cinematic root error in pure HTML with inline styles on `#000000`: the wordmark as inline SVG (paths from the `brand/cinematic` wordmark master), "ManhwaManiacs failed to start." in a system serif (`Georgia, "Times New Roman", serif`) in `#F3F0E8`, the explainer "The app shell didn't render. Reloading usually fixes it; if it doesn't, check that the server is running." in `#9A978F`, and two square buttons styled inline (bone `#F3F0E8` fill, `#000` text, min 44 px tall, radius 0): `Try again` (`reset()`) and `Reload the app` (`location.assign("/")`). Otherwise the legacy root error, unchanged.
- Offline fallback: web/02 owns `frontend/public/offline-fallback-cinematic.html` (its item 11 sets every value: the 72 px `mm-mark`, the `NO CONNECTION` badge in `proof` `#FF5B4A` / `BACK ONLINE` in `set` `#57D68D`, the Bodoni-first italic headline stack, the deck, the note, the bone `Try again` and the quiet `Downloads`) and the worker's serving logic. Do not rewrite it or touch `public/sw.js`. Check it against the §8.32 row "Offline fallback page" (open it directly and offline through the worker) and change it only if a line of that row is missing, keeping web/02's values; list any change in the report.
- `primitives/NotAvailableNotice.tsx` (§8.0.10): kicker `NOT IN THIS ISSUE`, typed headline "This series isn't available here any more." (source variant "This source isn't available here any more."), deck "It may have been removed from its source.", primary `Back to Tonight`, quiet `Search for it` (→ `/search?q={title}` when the title is known, else `/search`). The `not-browsable` variant: headline "This source can only be searched, not browsed." with `Search it` (→ `/sources/{sourceId}?mode=search`). Screens choose the variant with `notAvailableKind(error)`; the wording is the same for removed and gated content.
- The reader landing (`/reader`, `readerLanding`) is web/12.

### 12. Stop-press banner, first-run note, rating-card host (§8.33.3–§8.33.5)

- `shell/StopPressBanner.tsx`: when unread notifications exist (reuse `useUpdateNotifications(true)` and `computeNewChaptersBanner` from `features/updates/hooks.ts`, polled every 60 s) and the user is not on `/updates` and not in the Reader frame: a subtitle-style strip (`paper.2` with `data-stock="raised"`, 1 px `rule.2`, a 2 px `spot` left rule) bottom-left of the content column 24 px from the bottom (desktop frame, max 560) or above the thumb index (phone frame), at the toast anchor under the toast stack (it reports its height to `ToastHost`, which then renders one toast above it). Content: kicker `STOP PRESS`, "{n} new chapters across {m} series." ("1 new chapter in 1 series." and "{n} new chapters in 1 series." for the singular cases), `Read updates` (quiet → `/updates`) and an `x` `bare` icon button labelled "Dismiss" that hides it until a newer notification (`sessionStorage['mm.updates.banner.dismissedMaxId']`, the existing key K49). A `placement="top"` prop puts it at the top edge in the stock colours for the Page frame (the novel reader verifies it in web/14). Counts are already 18+ gated by the server.
- `shell/FirstRunNote.tsx`: web/05's `BannerStrip` under the running head with kicker `NOTHING FOLLOWED YET`, "Follow a series from Discover to start your shelf." and a `Discover` action (→ `/search`), `role="note"`, not dismissible; shown when `shouldShowFirstRunHint` (from `features/library/first-run.ts`) says the profile follows nothing, on every App-frame screen except `/`, `/library`, `/library/browse`, `/search`, `/sources`, `/sources/:id`, feature and book pages; never in readers or takeovers.
- `shell/RatingCardHost.tsx` and `shell/rating-card.ts`: a slot at the top-left under the running head (`z.toast`) and `showRatingCard(node)` / `hideRatingCard()`; the card itself, its timing and its callers are web/07, web/11 and web/12.

### 13. The Press start splash (§8.2, §12.4) — `Splash.tsx`, `shell/splash-timeline.ts`, `brand/Monogram.tsx`, `brand/Wordmark.tsx`

- First frame: the `(app)` layout server-renders, for the Cinematic skin, a fixed full-viewport `#000` layer at `z.shutter` with the monogram as inline SVG in its centre (the two Didone M's in `#F3F0E8`, the intersection filled `#000000` at first), 160 px wide on the desktop frame and 112 px on the phone frame. `Monogram.tsx` draws `MM_MARK` from `frontend/src/skins/cinematic/mark.generated.ts` (shared/04: `viewBox` `0 0 1024 1024`, the `upright` and `italic` paths, `bone` and `spot`; the intersection is a `<mask>` of one path over the other, so the fill can animate `#000` → `spot`). Never copy paths by hand; the file is regenerated from the brand masters. `Wordmark.tsx` renders the **stacked lockup** as live text (`Manhwa` in Bodoni Moda Roman over `Maniacs` in Bodoni Moda Italic, `wght` 800, `opsz` 96, tracking −0.035em, leading 0.86, flush left, in `type-masthead`) with the Oxford rule under both whose first 12 % is `spot` (add a `spotLead` prop to web/04's `OxfordRule`).
- Timeline (`splash-timeline.ts`, a table of `{ element, startMs, endMs, easing }`, tested; played with `play()` from one `performance.now()` origin taken at hydration):

  | t (ms) | Element | Motion |
  |---|---|---|
  | 0–100 | Monogram | already painted by the server; holds |
  | 100–420 | Intersection | fill `#000` → `spot`, plus a bloom behind it from 0 to 0.35 (`color.spot.glow`), `ease.settle` |
  | 252–572 | Monogram | opacity 1 → 0 and scale 1.00 → 0.96, `ease.lift` |
  | 252–1180 | Wordmark letters | **Letter set** at its standard timings (640 ms per grapheme, blur 440 ms, 24 ms stagger, 13 graphemes, last letter starts at 540 and lands at 1180): `SetHeading` with `trigger="signal"` and a `startDelay={0}` prop added to it (the timeline start replaces the 120 ms start delay); upright "Manhwa", then italic "Maniacs" |
  | 700–1180 | Oxford rule | **Rule draw** 480 ms `ease.settle`, left → right, first 12 % in `spot` |
  | 1180 | Impression | the lockup translates 1 px down and back over 80 ms; haptic `splash.impress` (a no-op on the web) |
  | 1180–1400 | Hand-off | desktop frame: the lockup shrinks and flies to the sidebar head wordmark (a FLIP, 220 ms `ease.turn`); phone frame: the lockup dissolves over 220 ms as the page's typed headline starts |

- The `reel` cue (`splash.reveal`) starts at t = 0 when UI sounds are on; its hit lands at 1180 by recipe.
- Duration rule: the choreography always runs 0–1180 ms; the hand-off starts at `max(probeDone, 1180)` where `probeDone` is the session query settling (signed in, signed out or unreachable); the reveal is never stretched. If the probe is still pending at 1180 ms the lockup holds after the impression; at 2400 ms a 24 px `LeaderDial` and the caption `CONNECTING` (`type-kicker` `ink.60`) appear under the Oxford rule.
- Tap anywhere, or `Enter`, `Space` or `Esc`, skips to the hand-off (or to the hold while the probe is pending).
- `useSplashDone()` lets the first screen start its typed headline when the hand-off begins (web/08 uses it for Tonight's cover headline).
- Warm start: when `sessionStorage[splashKey("cinematic")]` exists (`splashKey` from web/02's `frontend/src/features/skin/skin-storage.ts`, i.e. `mm.skin.splash.cinematic`), the stacked lockup fades in over 200 ms and out over 200 ms (`dur.clip`), with no letters and no haptic. On a full reveal the splash writes `"1"` to that key after the hand-off. (web/02's `restartInto` removes the outgoing skin's key before every restart, so a switch always plays the arriving reveal.)
- `SKIN RESTART`: on its first client frame the splash calls `logSkinRestart("cinematic")` from `frontend/src/lib/motion-timings.ts` (web/02), which reads and clears `sessionStorage['mm.skin.t0']` and records the entry even while recording is off.
- Reduced motion: the lockup fades in over 300 ms (`dur.tapscroll`), holds until ready, fades out over 200 ms.
- Accessibility: the layer is `aria-hidden` apart from a visually hidden `role="status"` "Loading ManhwaManiacs"; it never traps focus.
- Outcomes after the hand-off come from the Gate (item 2): remembered profile → the requested route (Tonight at `/`); no profile → the picker (Dip); signed out → Login (Dip); offline with a cached user → the route in the offline edition; unreachable with no cache → Login's unreachable state (web/07).
- Favicon and install metadata (§12.3): `app/(app)/layout.tsx`'s `generateMetadata` returns, for the Cinematic skin, values imported from shared/04's `frontend/src/skins/brand.generated.ts`: `icons: { icon: [{ url: SKIN_FAVICONS.cinematic, type: "image/svg+xml" }, { url: "/favicon.ico", sizes: "16x16 32x32" }], apple: APPLE_TOUCH_ICON }` (`/favicon.svg`, and `/icons/apple-touch-icon.png`; `favicon.ico` stays at `app/favicon.ico`) and `appleWebApp: { capable: true, title: "Maniacs", statusBarStyle: "black-translucent", startupImage: APPLE_STARTUP_IMAGES }` (the home-screen label of §12.3 and §15.10 "Owner calls"; `black-translucent` is today's value, kept so the `#000` page runs under the status bar). Never hard-code these paths. Legacy keeps its current icons.

### 14. Motion-timings overlay (§15.9) — `motion-timings.tsx`

- Development builds only, loaded with a dynamic `import()` behind `process.env.NODE_ENV !== "production"` so production bundles never contain it; `mod+shift+m` toggles it; per device, off after reload.
- A 320 px wide panel pinned bottom-left at `z.debug`, `bg-paper-2/92`, 1 px `rule.2` border; the last 20 entries of the web/02 recorder (`frontend/src/lib/motion-timings.ts`: `setRecording(true)` when the panel opens and `false` when it closes, `entries()`, `subscribe()`, `clearEntries()`) as rows in IBM Plex Mono 11/16, each the recorder's `formatEntry(e)` string (`COLUMN WIPE   872 → 880 MS   53/53 F   0 DROP`); a row is `proof` when `isLate(e)` (over its planned duration by more than one frame interval, any dropped frame, or a restart over 1,500 ms) and `set` otherwise; gesture entries (scroll-linked moves) show frames and drops; the `SKIN RESTART` entry is included. Header buttons `Clear` and `Copy log` (the entries as JSON through `navigator.clipboard.writeText`). The recorder already mirrors each entry to `console.table` while recording; the overlay adds no logging of its own.

### 15. Lenis (§8.0.5, §15.2) — `smooth-wheel.ts`

- `useSmoothWheel()`: only on the desktop frame (≥ 768 px), with `(pointer: fine)`, and never under reduced motion; creates `new Lenis({ autoRaf: true })` (`lenis` 1.3.26) on mount and calls `destroy()` on unmount or when a condition changes. Only Tonight (web/08) and The Annual (web/21) call it; never readers or lists.

### 16. Shell gallery, tests and proof

- Gallery route `frontend/src/app/(preview)/skin-preview/[skin]/shell/page.tsx` (development only, `notFound()` in production and for other skins): the pure views with fixture props so every state can be captured without data: `SidebarView` (expanded, spine, overlay, 480 px tall), `RunningHeadView` (desktop default, over art with `scrim-head`, phone with back, title and two trailing icons, the offline badge, `BACK ONLINE`), `ThumbIndexView` (each tab active, with badges), `StopPressBannerView`, the first-run note, the keyboard sheet with a fixture registry, the palette with fixture results and the empty state, `NotFound` on both frames, `RouteError` in both variants, `NotAvailableNotice` in its three variants, and the splash, Column wipe and Iris frozen at given times through a `freezeAt` prop (splash at t = 0, 300, 560, 900, 1180, 1400; wipe at close end and mid-open; iris mid-close).
- Vitest: `shell/frames.test.ts`, `shell/nav-map.test.ts` (every row of the §7.15 route table, the held item, the cold-load rule), `shell/g-sequence.test.ts` (1500 ms arm, `g 1` + 600 ms, `Enter`, cancel paths, novels-mode `g 9`), `shell/wipe-geometry.test.ts` (4, 8, 12 blades, coverage of the full width, totals 616 / 744 / 872 ms), `shell/splash-timeline.test.ts` (last letter starts at 540 and lands at 1180; hand-off at `max(probe, 1180)`), `lib/keyboard/single-key.test.ts`, `lib/not-available.test.ts`, the moved command-palette tests.
- Playwright `frontend/e2e/cinematic/shell.spec.ts` (signs in with `signIn(context, { base, user, password, profile })` exported by `frontend/scripts/proof.mjs`, credentials from `MM_PROOF_USER` / `MM_PROOF_PASSWORD` (the demo account in `backend/scripts/README-dev-stack.md`), and sets the `mm-skin-debug=cinematic` cookie):
  - Sidebar: 248 px at 1440 × 900, 72 px at 1024 × 768; `mod+b` toggles; at 1024 the toggle opens an overlay that `Esc` closes; exactly one item has `aria-current="page"` on `/library/collections` and it is `06 Collections`.
  - `g` then `2` goes to `/library`; `g` then `1` then `1` goes to `/circle`; `g`, `1`, wait 700 ms goes to `/`; keys consumed by the sequence do not trigger page bindings.
  - `mod+k` opens the palette with focus in its field; typing filters; `↓` then `Enter` navigates; `Esc` closes and restores focus.
  - `?` opens the keyboard sheet and it lists `Alt+T`.
  - The skip link is the first Tab stop and moves focus to `main h1`; after a sidebar navigation `document.activeElement` is the new `h1` and `document.title` ends with `· ManhwaManiacs`.
  - At 390 × 844 the thumb index shows five tabs, each ≥ 44 × 44; the active tab has the notch; the running title appears only after the masthead scrolls under the bar.
  - `/does-not-exist` renders the in-frame 404 inside the Shell.
  - `context.setOffline(true)` shows the `OFFLINE EDITION` badge; going back online shows `BACK ONLINE` for about 2 s.
  - Splash: with the splash flag cleared, the letters land by 1,400 ms and the overlay is gone after the hand-off; with the flag set, only the 200 ms fades play; under reduced motion no letter transforms occur.
  - `enterReader` with `"wipe"` at 1440 × 900 renders 12 blades whose union covers the viewport, and navigation happens only after the close; with reduced motion there are no blades, only a fade.
  - Reduced motion: page transitions are opacity-only.

## File layout (create or change exactly these)

```
frontend/src/lib/command-palette/{commands,fuzzy}.ts (+ tests)          moved from components/command-palette
frontend/src/components/command-palette/CommandPalette.tsx               import paths only
frontend/src/lib/keyboard/{single-key.ts,single-key.test.ts,context.tsx} single-key guard
frontend/src/lib/not-available.ts, not-available.test.ts
frontend/src/features/preferences/hooks.ts                               useServerCapabilities (only if missing)
frontend/src/features/reader/prefetch.ts                                 only if web/03 exposes no prefetch
frontend/src/app/globals.css                                             import view-transitions.css
frontend/src/app/(app)/layout.tsx                                        generateMetadata icons per skin; splash first frame
frontend/src/app/(app)/not-found.tsx, error.tsx                          pick the Cinematic body by skin
frontend/src/app/global-error.tsx                                        Cinematic root-error branch
frontend/src/app/(preview)/skin-preview/[skin]/shell/page.tsx            shell gallery
frontend/public/offline-fallback-cinematic.html                          only if a §8.32 line is missing (web/02 owns it)
frontend/src/skins/cinematic/
  index.ts                                   Shell wired in
  Shell.tsx Splash.tsx motion-timings.tsx smooth-wheel.ts view-transitions.css
  brand/{Monogram,Wordmark}.tsx
  shell/{frames.ts,frames.test.ts,Gate.tsx,running-head-context.tsx,
         Sidebar.tsx,SidebarView.tsx,nav-map.ts,nav-map.test.ts,
         RunningHead.tsx,RunningHeadView.tsx,AccountMenu.tsx,
         ThumbIndex.tsx,ThumbIndexView.tsx,
         PageTransition.tsx,CineLink.tsx,use-cine-router.ts,
         Overlays.tsx,wipe-geometry.ts,wipe-geometry.test.ts,reader-entry.ts,
         GlobalKeys.tsx,g-sequence.ts,g-sequence.test.ts,
         CommandPalette.tsx,palette-commands.ts,KeyboardSheet.tsx,
         StopPressBanner.tsx,FirstRunNote.tsx,RatingCardHost.tsx,rating-card.ts,
         splash-timeline.ts,splash-timeline.test.ts,route-focus.ts}
  screens/system/{NotFound,RouteError}.tsx
  primitives/{NotAvailableNotice.tsx, OxfordRule.tsx (spotLead), SetHeading.tsx (startDelay)}
frontend/e2e/cinematic/shell.spec.ts
docs/redesign/proof/web-06/plan.md
docs/redesign/proof/web-06/…
```

Do not touch `frontend/src/skins/glass/**`, `frontend/public/sw.js`, `mobile/`, `backend/`. This step finishes no `ScreenId` (`readerLanding` is web/12), so the `PENDING` set is unchanged.

## Working steps, commits and pushes

1. `refactor(web): move command-palette logic to lib, add single-key guard and not-available helper` (1) → verify legacy unchanged, build, push.
2. `feat(web-cinematic): shell frames and session/profile gate` (2).
3. `feat(web-cinematic): contents sidebar and running head` (3, 4).
4. `feat(web-cinematic): thumb index, focus, skip link and mood` (5, 7) → verify, push.
5. `feat(web-cinematic): view transitions, dip, column wipe and iris overlays` (6) → verify, push.
6. `feat(web-cinematic): global keys, g sequence, command palette and keyboard sheet` (8, 9, 10).
7. `feat(web-cinematic): status screens and not-available notice` (11).
8. `feat(web-cinematic): stop-press banner, first-run note, rating-card host` (12) → verify, push.
9. `feat(web-cinematic): press start splash, motion timings overlay, smooth wheel` (13, 14, 15).
10. `test(web-cinematic): shell gallery and e2e` (16) → verify, push.
11. `docs(redesign): web-06 proof screenshots` → push.

## Acceptance criteria

- [ ] Frames: `/login` and `/register` Bare; `/profiles` and `/welcome` Takeover; readers and the novel reader without app chrome; every other route in the App frame, desktop from 768 px, phone below, with no hydration warnings.
- [ ] Sidebar: 248 / 72 widths, auto-spine at 768–1279, the overlay below 1280, `mm.sidebar` stored only from 1280, the exact-match active item, counts, capability hiding, the < 500 px height rule, 320 ms `ease.turn` width animation with label fades, reduced-motion variant.
- [ ] Running head: desktop 56 px with breadcrumb (Folio flip on section change), search trigger with `⌘K` / `Ctrl K`, bell with count and live region, profile chip and account menu; phone 44 px + inset with back, running title cross-fade after the masthead, ≤ 2 trailing icons, transparent → `#000` after 24 px; `scrim-head` over art resolves (computed `background-image` of the `::before` is not `none`).
- [ ] Thumb index: 56 px + inset, five labelled tabs, Fill icon and notch on the active tab, Rule slide between tabs, badges, tap-active behaviours, long-press shortcuts, correct visibility per route.
- [ ] Transitions: Page (320 / 224 ms), back (224 ms), desktop section Dip (160 / 40 / 240 ms), phone section Cut + Set + Folio flip, match cut 480 ms forward and 336 ms back with everything else dissolving 240 ms, popstate without animation; every reduced-motion variant is an opacity change of 150–200 ms.
- [ ] Column wipe: 4 / 8 / 12 blades on column edges covering the viewport, close 200 ms with 16 ms stagger from the top, 40 ms hold with the navigation underneath, open 280 ms toward the bottom, totals 616 / 744 / 872 ms, tap to skip in 120 ms, `reader.enter` haptic and `wipe` cue at the landing, a 200 ms fade under reduced motion. Dip and Iris behave as specified and both finish their close before `router.push`.
- [ ] Global keys and the `g` sequence behave exactly as §8.0.6, including the 1500 ms and 600 ms rules, the `G 1_` chip, consumed keys not reaching page bindings, and being off inside readers, while typing and with single-key shortcuts off.
- [ ] Command palette and keyboard sheet match §8.33.1–§8.33.2 (groups, rank order, 40-result cap, keys, live region, empty state, no `EDITION` group while `glass_available` is false).
- [ ] Status screens: the 404 renders inside the frame with the typed h1; the route error has both variants and the digest keycap; the Cinematic root error is standalone and on-brand, and web/02's offline fallback passes the §8.32 check; the legacy versions are unchanged.
- [ ] Stop-press banner, first-run note, offline badge and the rating-card slot behave per §8.33; toasts sit above the banner with one visible while it shows.
- [ ] Splash: the §12.4 timeline to the millisecond (checked in `splash-timeline.test.ts` and the gallery frames), hand-off at `max(probe, 1180)`, `CONNECTING` at 2400 ms, skip by tap and keys, warm start by the per-skin flag, reduced-motion fades, `SKIN RESTART` logged, per-skin favicon links.
- [ ] Motion-timings overlay: development only (absent from `.next` production chunks: `grep -rl "COLUMN WIPE" frontend/.next/static` finds nothing after `npm run build`), `mod+shift+m`, 20 rows, colours, `Clear`, `Copy log`.
- [ ] Focus: skip link first; route changes focus the new `h1` and update `document.title`; hidden chrome is out of the tab order; the focus ring shows on `:focus-visible` only and is never clipped by the bars.
- [ ] Hit targets ≥ 44 × 44 on the phone frame and coarse pointers, ≥ 32 × 32 on a fine pointer.
- [ ] Legacy unchanged with both skin cookies unset (before and after screenshots of `/library` and the legacy palette match).
- [ ] `node design/lint-utilities.mjs`, the ESLint skin boundary, `node design/build.mjs --check` pass; every vitest test that passed before still passes; lint 0 / 0; build passes.

## Verification

Record the vitest total before the first edit, then:

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs
node design/build.mjs --check
node design/lint-utilities.mjs
cd frontend
test "$(free -m | awk '/^Mem:/{print $7}')" -ge 1024 || { echo "RAM guard"; exit 1; }
npm run typecheck
npm run lint            # 0 errors, 0 warnings
npm run test            # every earlier test passes; report old and new totals
npm run build           # passes; stop next dev and the dev stack first
grep -rl "COLUMN WIPE" .next/static || echo "timings overlay absent from production chunks"
```

Then, with the RAM guard before each, start the dev stack and `next dev` on port 3010 as `backend/scripts/README-dev-stack.md` and the usage header of `frontend/scripts/proof.mjs` describe:

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs/frontend
export MM_PROOF_USER=<demo user from README-dev-stack> MM_PROOF_PASSWORD=<its password>
E2E_BASE_URL=http://127.0.0.1:3010 npx playwright test e2e/cinematic
node scripts/proof.mjs --step web-06 --skin cinematic --routes /,/library,/updates,/search,/downloads,/more,/settings,/library/collections,/does-not-exist --grid
node scripts/proof.mjs --step web-06 --skin cinematic --routes /,/library --reduced
node scripts/proof.mjs --step web-06 --skin cinematic --no-auth --routes /skin-preview/cinematic/shell
```

The frontend runs as the harness's usage header says (`NEXT_PUBLIC_API_URL=/api BACKEND_INTERNAL_URL=http://127.0.0.1:8010 npm run dev -- --port 3010`). Screenshots land in `docs/redesign/proof/web-06/` at 1440 × 900 and 390 × 844 (and, from the e2e spec, 1024 × 768 for the spine and the palette, keyboard sheet, sidebar overlay and offline badge states into `docs/redesign/proof/web-06/states/`). Use `playwright-cli -s=web-06` for ad-hoc sessions.

Mobile and backend: this step changes neither. Judge that by your own commits, never by the branch diff: every web step runs in parallel with its `mobile/NN` twin on the same branch, so `git diff origin/...HEAD -- mobile backend` is routinely non-empty with other sessions' work. `git show --stat --format= <hash>` for each commit of this step must list no `mobile/` or `backend/` path. Only if one does, revert that part and prove the baseline still holds with its own commands, one at a time after the RAM guard and never while a `next build` runs: `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze` (baseline: No issues found), `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter test` (baseline: all 2012 tests passed) and `cd backend && .venv/bin/python -m pytest -q --no-header`.

## Report back

1. Done items by number (1–16), anything not done with the reason, and the `ViewTransition` export name you found.
2. `docs/redesign/proof/web-06/` file list; the impeccable and taste-skill critiques and the changes they caused.
3. Vitest before and after, Playwright passed / failed, lint, build, `build.mjs --check`, `lint-utilities`, and the production-chunk check for the timings overlay.
4. Commit SHAs, each pushed.
5. Open issues (for example a Base UI or Next behaviour that forced a deviation) and how you resolved them.

Next prompt: `docs/redesign/prompts/web/07-cinematic-auth-profiles-18plus.md`.
