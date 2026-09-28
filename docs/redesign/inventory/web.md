# ManhwaManiacs web client — exhaustive UI inventory (redesign checklist)

Source read: `/srv/manhwamaniacs/dev/ManhwaManiacs/frontend/src` (frontend v2.6.1: Next.js 16.2.9, React 19.2.4, Tailwind 4, framer-motion 12.42, TanStack Query 5.101, zustand 5, lucide-react 1.22), every `app/` route, every file in `components/`, every `features/*/components/*`, the feature hooks/API modules that decide what a screen shows, `lib/keyboard`, `stores/ui-store.ts`, `config/*`, `public/offline-fallback.html`. Read on 2026-09-29. Nothing in the app repository was modified.

This is the 100 % coverage checklist for the two-skin redesign (Cinematic / Glass, dark-only, AMOLED `#000000`; see `inventory/00-decisions.md`). It describes what exists today so that nothing is dropped; it deliberately does not propose the new look. Each row has an ID so concept docs can tick it off (e.g. "LB15 → Cinematic card hover bell").

## 0. Counts

| What | Count |
|---|---|
| Routes (`page.tsx`) | 27, plus `/` → `/library` redirect |
| Distinct screens to design | 32 (27 routes + the novel variant of the source series page + 404 + route error + root error + offline fallback page) |
| Global overlays | 6 (command palette, shortcuts dialog, new-chapters banner, app-update prompt, first-run banner, reader bookmark notice) |
| Settings tabs | 8 (6 for non-admins) |
| UI element rows in this document (IDs) | 503 (chrome 90, auth/profiles/more/settings 84, library 131, sources 46, manga reader 42, novels 51, updates/downloads/bookmarks/OCR/admin 59) |
| Keyboard bindings | 34 registered (General 3, Library 2, Search 1, Sources 2, Reader 19, Novel reader 7) + 11 non-registry key handlers |
| User actions → calls | 118 (A1–A118) |
| API endpoints in the client | 84 method+path pairs, 78 reachable from UI |
| Setting keys | 51 (K1–K51) |
| Motion patterns | 22 (MO1–MO22) |
| React components | 133 exported components in 117 `.tsx` files (+ 27 route pages) |
| Dialogs / modals / popovers | 17: Keyboard shortcuts, Command palette, Profile add/edit, Delete profile, Enable mature content, Sign out everywhere, New collection, Edit collection, Add series to collection, Remove series from collection, Delete collection, Restore backup, Delete member, Reader settings sheet, Novel type panel (popover), Account menu (popover), Collections sort menu (popover) |
| Empty / error / offline / loading states | every data screen has all four (listed per screen) |

## 1. Route table

| # | Path | Screen | Purpose | Data shown | Entry points |
|---|---|---|---|---|---|
| R0 | `/` | — | 307 redirect to `/library` (next.config) | — | PWA icon, login success, profile pick, 404 "Back home" |
| R1 | `/login` | Login | Sign in; first-run admin bootstrap | bootstrap status, current user | Auth guard redirect, sign-out, register footer |
| R2 | `/register` | Register | Create an account (open / invite / bootstrap / closed) | bootstrap status | Login footer "Create one" |
| R3 | `/profiles` | Profile picker | Choose the reading profile (full-bleed) | profile list | Profile gate, topbar chip, More → Switch profile, "Choose a profile" links |
| R4 | `/profiles/manage` | Manage profiles | Add / edit / delete / use profiles | profile list, active profile | Sidebar footer "Profiles" (desktop only) |
| R5 | `/library` | Library (followed shelf) | Home: what this profile follows + resume | followed series (200), continue reading (1) | Default route, tab 1, sidebar |
| R6 | `/library/browse` | Browse all | Filter/sort/search/select the followed library, bulk actions | followed series (200) with filters, continue reading (12) | Sidebar, More |
| R7 | `/library/[seriesId]` | Followed series detail | Status, favourite, notifications, chapters, downloads | followed series detail + chapters + progress | Library cards, palette, collection grid |
| R8 | `/library/collections` | Collections | List / create collections | collections | Sidebar, More |
| R9 | `/library/collections/[collectionId]` | Collection detail | Edit, add/remove series, delete | collection + followed series | Collection banner card |
| R10 | `/library/history` | Reading history | Resume anything read | history (50, collapsed per series) | Sidebar, More, Settings desktop card |
| R11 | `/library/bookmarks` | Bookmarks | Jump to / remove saved spots | bookmarks | Sidebar, More |
| R12 | `/library/recommendations` | Find something to read | AI prompt + "for you" + "because you read" | world recs, AI availability, AI results | Sidebar ("Recommendations"), More |
| R13 | `/library/statistics` | Reading statistics | Streak, activity, hours, sources, most read, sessions | statistics (7/30/90 d) | Sidebar, More |
| R14 | `/search` | Global search | Library + every source at once | federated search (2 tiers), recent searches | Tab 3, sidebar, world card "Search" (`?q=`) |
| R15 | `/sources` | Sources | Installed connectors, pins, 18+ filter | sources, pins | Tab 2, sidebar, first-run banner, empty states |
| R16 | `/sources/[sourceId]` | Source catalogue | Browse / search / genre / modes, infinite scroll | source series pages, genres, browse modes | Source rows, palette, genre chips (`?genre=`) |
| R17 | `/sources/[sourceId]/series/[seriesId]` (manga) | Source series detail | Read / continue / read all / follow / chapters / download | series, chapters, server + local progress | Catalogue cards, search results, world cards, history, stats, downloads |
| R17n | same path, novel source | Book (front matter + contents) | Start/continue, add to library, download book, contents with go-to | series, chapters, progress, word counts | Novel shelf rows, novel reader back/contents |
| R18 | `/reader` | Reader landing | Placeholder "open a series" | — | Direct URL only |
| R19 | `/reader/[sourceId]/[seriesKey]/[...chapterKey]` | Manga reader | Read a chapter (strip / single / double) | chapter manifests (windowed), progress | Chapter rows, Continue, history, notifications, bookmarks (`?page=&at=`), downloads, OCR results |
| R20 | `/read-all/[sourceId]/[seriesKey]` | Read-all reader | Whole series as one strip | chapter list + batch manifests | "Read all" pills (`?from=&page=&at=`) |
| R21 | `/novels/[sourceId]/[seriesKey]/[...chapterKey]` | Novel reader | Read prose, TTS audio, voices, type settings | chapter text, attribution, audio, voices | Book contents, Continue, history, bookmarks (`?page=&para=&at=`), downloads |
| R22 | `/updates` | Updates | New-chapter notifications, check now | notifications, settings summary, runs (admin) | Sidebar, bell, More, banner |
| R23 | `/downloads` | Downloads | Offline chapters, storage, retention | service-worker index, storage estimate | Tab 4, sidebar, OfflineState CTAs, offline fallback page |
| R24 | `/ocr` | OCR search | Dialogue search in followed manga | OCR search results | Sidebar (manga mode), More |
| R25 | `/more` | More hub | Phone navigation to everything without a tab | unread count | Tab 5 |
| R26 | `/settings` | Settings | Design, appearance, reader, notifications*, content, security, shortcuts, backup* + members* | per panel | Sidebar footer, More, palette, updates card |
| R27 | `/admin/status` | System status (admin) | Backend, checker, runs, source health | health, settings, runs, source health | Sidebar footer (admin), Settings card, More |
| E1 | any unknown path | 404 | "Nothing here" inside the shell | — | — |
| E2 | any route that throws | Route error | "Something broke" / "Can't reach the server" | — | — |
| E3 | root layout throws | Root error | "ManhwaManiacs failed to start" (own `<html>`) | — | — |
| E4 | `/offline-fallback.html` | Offline fallback (static) | Served by the service worker when a navigation fails offline | online status | Service worker |

\* admin only.

Screen names (32): Login, Register, Profile picker, Manage profiles, Library, Browse all, Followed series detail, Collections, Collection detail, Reading history, Bookmarks, Find something to read, Reading statistics, Global search, Sources, Source catalogue, Source series detail (manga), Book page (novel series), Reader landing, Manga reader, Read-all reader, Novel reader, Updates, Downloads, OCR search, More, Settings, System status, 404, Route error, Root error, Offline fallback.

Shell variants a design must cover: (a) auth frame (no chrome), (b) picker takeover (no chrome), (c) app frame desktop (sidebar + topbar), (d) app frame phone (topbar strip + floating tab bar), (e) manga reader frame (topbar kept, no tabs, obsidian, mood gutters), (f) novel reader frame (no app chrome at all, palette-painted), (g) landscape phone reader (no sidebar, no topbar).

## 2. Global chrome (present on every authenticated route)

Source: `components/layout/app-shell.tsx`, `sidebar.tsx`, `topbar.tsx`, `config/nav.ts`, `config/more-nav.ts`, `stores/ui-store.ts`, `app/providers.tsx`, `app/layout.tsx`.

### 2.1 Frame selector and guards (invisible, but each has a visible state)

| # | Element | Behaviour today | Visible state to design |
|---|---|---|---|
| G1 | Frame selector | `/login`, `/register` render full-bleed with no shell. Everything else goes through `AuthenticatedShell`. | Two frame types: bare auth frame, app frame. |
| G2 | Auth route guard | `GET /auth/me` resolves the session. 401 → `null` → `router.replace("/login")`. A probe that never reached the server (offline) does **not** redirect; the app renders on what the device has (`features/offline/session-gate.ts`). | Session-resolving splash (`AuthPending`: centred spinner `Loader2 size-6`, full-height). |
| G3 | Profile gate | Signed in but no active profile → `router.replace("/profiles")`. Waits for persisted selection to hydrate (`mm.active-profile` in localStorage). | Picker takes over full-bleed (no sidebar/topbar). |
| G4 | Stale-profile check | If `/profiles` list loads and the remembered profile is gone, clear it → picker. | None directly (lands on picker). |
| G5 | Query-cache 401 handler | Any non-auth query that 401s flips current user to `null` → login redirect. | Mid-session "signed out" transition. |
| G6 | Profile-scope error handler | Any query/mutation that returns 400 `profile_required` or 404 `profile_not_found` clears the active profile → picker. | Same as G3. |
| G7 | Profile cache boundary | Switching profile drops every cached query except `auth`, `profiles`. | Full refetch on switch: every screen re-enters loading. |
| G8 | Profile storage boundary | localStorage keys are namespaced per `(userId, profileId)`; unscoped while signed out. | None. |
| G9 | Appearance boot script | Inline `<script>` in `<head>` stamps `data-theme` and `data-preset` on `<html>` before paint from the active profile's stored choices. | Replace with skin boot (Cinematic/Glass) so first paint is already the right skin; see decisions (skin change restarts the app). |
| G10 | Mood tint | Shell background is a radial gradient tinted by the active profile's mood (`moodShellBackground`, 500 ms background transition). Reader keeps `bg-obsidian`. | Per-profile ambient tint layer. |
| G11 | Route cross-fade | `<main>` gets class `route-in` (opacity keyframe) on every pathname change, except inside the two readers. | Route transition per skin. |
| G12 | Skip link | "Skip to content" `sr-only`, visible on focus, top-left, z-70. | Focus-visible skip link. |
| G13 | Service-worker boundary | Registers `/sw.js`, publishes profile scope, sweeps expired downloads on open and every 5 min on tab focus, calls `registration.update()`. | Update prompt (see G40). |

### 2.2 Desktop sidebar (`md:` and up, hidden below 768 px; hidden in reader when viewport height < 500 px)

| # | Element | Details |
|---|---|---|
| G14 | Sidebar container | `<aside aria-label="Main navigation">`, expanded 240 px (`w-60`), collapsed 68 px, 200 ms width transition. Auto-collapses below 1024 px. |
| G15 | Brand header | 56 px tall. Expanded: "MM" 32 px round monogram + "ManhwaManiacs" wordmark (Syne, text-lg). Collapsed: 36 px monogram only. **To redesign: new wordmark + icon.** |
| G16 | Content-mode switch | Segmented control "Manga" (BookOpen icon) / "Novels" (BookText icon). Renders nothing when the server has novels disabled (`novels_enabled` from `/auth/bootstrap-status`). Collapsed: stacked icon-only buttons with `title`. Stored per profile in `mm.content-mode`. Switching re-filters every list in the app by source `content_kind`. |
| G17 | Section header "Browse" | Uppercase, tracking-widest (hidden when collapsed). |
| G18 | Nav link: Library | `/library`, icon Library. |
| G19 | Nav link: Browse all | `/library/browse`, icon BookOpen. |
| G20 | Nav link: Sources | `/sources`, icon Globe. |
| G21 | Nav link: Updates | `/updates`, icon Bell. |
| G22 | Nav link: Search | `/search`, icon Search. |
| G23 | Section header "More" | |
| G24 | Nav link: Downloads | `/downloads`, icon Download. |
| G25 | Nav link: Collections | `/library/collections`, icon List. |
| G26 | Nav link: Recommendations | `/library/recommendations`, icon Heart. |
| G27 | Nav link: Statistics | `/library/statistics`, icon BarChart3. |
| G28 | Nav link: History | `/library/history`, icon History. |
| G29 | Nav link: Bookmarks | `/library/bookmarks`, icon Bookmark. |
| G29a | Nav link: OCR Search | `/ocr`, icon ScanText. Hidden in Novels mode (manga-only route). |
| G29b | Footer nav: Profiles | `/profiles/manage`, icon Users. |
| G29c | Footer nav: Settings | `/settings`, icon Settings. |
| G29d | Footer nav: Status | `/admin/status`, icon Activity. **Admin only.** |
| G29e | Expand-sidebar button | Only when collapsed: ChevronRight icon button, `aria-label="Expand sidebar"`. |

Nav link states: default (muted), hover (surface-2 fill, fg text), active (`aria-current="page"`, primary 10 % fill, glow, 2 × 20 px primary bar on the left edge), collapsed (icon only + `title` tooltip + `sr-only` label). Active matching: exact or prefix (`/library/…` also lights Library — note that `/library/browse`, `/library/collections` etc. therefore light **both** Library and their own entry today).

### 2.3 Topbar (every route except the novel reader; hidden on the manga reader in landscape phones)

| # | Element | Details |
|---|---|---|
| G30a | Topbar container | Min height 56 px (44 px on the manga reader below `lg`) + `env(safe-area-inset-top)`. From `md`: filled `bg-void/80` + `backdrop-blur-sm` + bottom rule. Below `md`: transparent action strip, no title. |
| G30b | Toggle-sidebar icon button | PanelLeft icon, `lg` and up only, `title="Toggle sidebar (Ctrl/Cmd + B)"`. Below 1024 px the store toggles a (currently unrendered) mobile drawer flag. |
| G30c | Keyboard-shortcuts icon button | Keyboard icon, `lg` and up only, opens the Shortcuts dialog. |
| G30d | Notification bell | Bell icon link to `/updates`, 44 px. Badge: primary dot with unread count, "9+" above 9. `aria-live` announces count. Polls `GET /updates/notifications/unread-count` every 60 s. |
| G30e | Connectivity + clock | Wifi icon + `HH:MM` (mono, tabular), `sm` and up, ticks every 30 s. The Wifi icon is decorative (does not reflect online state). |
| G30f | Divider | 1 × 24 px rule, `md` and up. |
| G30g | Account menu trigger | Gradient initials avatar (28 px), display name (`sm`+), ChevronDown that rotates 180° when open. `aria-haspopup="menu"`. |
| G30h | Account menu popover | 240 px, glass panel, right-aligned under trigger. Header: display name, `@username`, email (if any), "Administrator" pill (ShieldCheck) for admins. Item: "Sign out" (LogOut icon; "Signing out…" while pending) → `POST /auth/logout` → `/login`. Closes on outside mousedown or Esc. |

### 2.4 Floating profile switcher chip

| # | Element | Details |
|---|---|---|
| G31 | Profile switcher chip | Centred in the topbar band (`absolute left-1/2 top-2.5`), `lg` and up only, hidden in readers. Pill: 32 px profile avatar + profile name (max 9 rem, truncated) + ChevronsUpDown. Click → `/profiles` picker. `aria-label="Switch profile — currently {name}"`. |

### 2.5 Mobile bottom tab bar (below 768 px; hidden in both readers)

| # | Element | Details |
|---|---|---|
| G32 | Tab bar container | Floating pill inset 16 px, radius 20 px, `surface/90` fill (no backdrop blur, on purpose), two shadows (`0 6px 20px rgba(0,0,0,.43)` + `0 4px 24px primary 9 %`), bottom padding `max(safe-area, 8px)`. `<main>` gets `pb-24` to clear it. |
| G33 | Tab: Library | `/library`, Library icon. |
| G34 | Tab: Sources | `/sources`, Globe icon. |
| G35 | Tab: Search | `/search`, Search icon. |
| G36 | Tab: Downloads | `/downloads`, Download icon. |
| G37 | Tab: More | `/more`, Menu icon. |

Tab states: 44 px min height; inactive = icon only (label `sr-only`), active = primary 12 % pill + icon + label (11 px semibold). No badge on any tab today (the unread badge lives on the More hub row for Updates).

### 2.6 First-run hint banner

| # | Element | Details |
|---|---|---|
| G38 | First-run banner | Shown under the topbar on every route **except** `/library`, `/sources*`, and readers, when the profile follows 0 series. Compass icon, "**Nothing followed yet.** Browse a source and follow a series to start building your library." + pill link "Browse Sources" → `/sources`. `role="note"`. Not dismissible. |

### 2.7 Global floating layers

| # | Element | Details |
|---|---|---|
| G39 | New-chapters banner (toast-like) | Fixed bottom-centre, max 672 px. BookOpenCheck icon, "**N new chapter(s)** across M series available to read." Buttons: "View updates" (link → `/updates`, also dismisses) and X icon "Dismiss new chapters notification". Dismissal stored in `sessionStorage` `mm.updates.banner.dismissedMaxId` (reappears when a newer notification arrives). Hidden on `/updates` and manga readers. Source: `GET /updates/notifications?unread_only=true&limit=100` polled 60 s. |
| G40 | App-update prompt (service worker) | Fixed bottom-centre, glass pill: RefreshCw icon, "A new version is ready.", button "Reload" → posts `mm-offline/skip-waiting` to the waiting worker and reloads. |
| G41 | Command palette | See §2.8. |
| G42 | Keyboard-shortcuts dialog | See §2.9. |

There is **no generic toast system** in the web client. Feedback is inline (text under forms, bar messages, button label swaps). The redesign should add one (see §21).

### 2.8 Command palette (`components/command-palette/`)

Opened by `mod+k` from anywhere (registered in the shell). Not mounted until opened.

| # | Element | Details |
|---|---|---|
| CP1 | Scrim | Full-screen `bg/70` + `backdrop-blur-sm`, click closes. |
| CP2 | Panel | `role="dialog"`, glass panel, max-width 672 px, max-height 70 vh, placed at 12 vh from top. |
| CP3 | Search input | `role="combobox"`, 56 px tall, leading Search icon, placeholder "Search series, sources, pages and actions…", trailing `Esc` Kbd (`sm`+). Autofocuses on open, restores prior focus on close. |
| CP4 | Live region | `sr-only` "Searching…" / "N results". |
| CP5 | Result list | `role="listbox"`, grouped; group label row (11 px uppercase). Groups in rank order: **Library** (series from `GET /library/search?q=&per_page=8`, debounced 220 ms), **Sources** (all sources from `GET /sources`), **Go to** (every nav route, de-duplicated), **Actions**, **Design**, **Themes**. Max 40 results, fuzzy-ranked with matched characters highlighted in primary. |
| CP6 | Row | 32 px leading visual (cover image / source icon / theme swatch square with accent dot / kind icon: ArrowRight route, BookOpen series, Globe source, Sparkles action, Settings, LogOut), title with highlight, subtitle (chapter count, source description, route path, theme description), CornerDownLeft glyph on the active row. Hover moves the highlight. |
| CP7 | Empty row | "Searching…" or "Nothing matches “{q}”." |
| CP8 | Footer | `↑ ↓ to navigate`, `↵ to open`, result count (`sm`+). |
| CP9 | Action: Open settings | → `/settings`. |
| CP10 | Action: Sign out | `POST /auth/logout` → `/login`. |
| CP11 | Action ×5: "Design: {preset}" | Applies a design preset (Signature, Matte, Compact, Editorial, Cinema); "(current)" suffix. **Replace with the two skins.** |
| CP12 | Action ×42: "Theme: {palette}" | Applies a reading palette; swatch preview. **Remove in redesign (dark-only, no palette picker).** |

Palette keys: `Esc` close, `↑/↓` move (wraps), `Home/End`, `Enter` run, `mod+k` again closes.

### 2.9 Keyboard layer (`lib/keyboard/`)

- One global `keydown` listener on `window`; a registry of `useShortcut` entries. First match wins. Ignored while focus is in `input/textarea/select/contenteditable` unless `allowInInput`. `mod` = ⌘ on Mac, Ctrl elsewhere. Formatter renders ⌘ ⌥ ⇧ glyphs on Mac.
- Groups are ordered: General, Navigation, Library, Search, Sources, Reader, then others alphabetically (e.g. "Novel reader").
- **Shortcuts dialog** (`?` or `shift+?`, or the topbar Keyboard button): Dialog "Keyboard shortcuts", max-width 576 px; intro "Only what works right here is listed. Shortcuts pause while you are typing in a field. Press ? anywhere to reopen this, Esc to close."; one bordered list per group, each row = description + `KbdCombo` chips (secondary combos at 80 % opacity); empty "No shortcuts are active on this screen."
- **Settings → Shortcuts** shows the same live registry as a panel.
- Grid navigation hook (`useGridNavigation`): arrow keys (via `onKeyDown` on the grid) and `h j k l` (via registry) move focus between `[data-grid-item]` cards, measuring columns from layout; Home/End jump.

Complete shortcut inventory:

| Key(s) | Action | Group | Where active |
|---|---|---|---|
| `mod+k` | Open command palette | General | Everywhere in the app frame |
| `mod+b` | Toggle the sidebar | General | Everywhere in the app frame |
| `?`, `shift+?` | Show keyboard shortcuts | General | Everywhere in the app frame |
| `/` | Focus library search | Library | `/library/browse` |
| `h j k l` (+ arrows) | Move through the series grid | Library | Library grids with items (Browse all, collection detail) |
| `/` | Focus search | Search | `/search` |
| `/` | Focus source search | Sources | `/sources/[id]` |
| `h j k l` (+ arrows) | Move through the catalog grid | Sources | Source catalogue grid |
| `→`, `d` | Turn page right (next or previous depending on RTL) | Reader | Manga reader |
| `←`, `a` | Turn page left | Reader | Manga reader |
| `j` | Next page | Reader | Manga reader |
| `k` | Previous page | Reader | Manga reader |
| `space` | Advance one screen | Reader | Manga reader |
| `shift+space` | Back one screen | Reader | Manga reader |
| `home` | First page | Reader | Manga reader |
| `end` | Last page | Reader | Manga reader |
| `f` | Toggle fullscreen | Reader | Manga reader |
| `c` | Toggle cinema mode (hide all chrome) | Reader | Manga reader |
| `p` | Play/pause auto-scroll (continuous mode) | Reader | Manga reader |
| `escape` | Close overlay, leave fullscreen, or exit the reader | Reader | Manga reader |
| `h` | Previous chapter | Reader | Manga reader |
| `l` | Next chapter | Reader | Manga reader |
| `s` | Go to series page | Reader | Manga reader |
| `b` | Bookmark this spot | Reader | Manga reader |
| `=`, `+`, `shift+=` | Zoom in | Reader | Manga reader |
| `-` | Zoom out | Reader | Manga reader |
| `0` | Reset zoom | Reader | Manga reader |
| `h` | Previous chapter | Novel reader | Novel reader |
| `l` | Next chapter | Novel reader | Novel reader |
| `=`, `+`, `shift+=` | Larger text | Novel reader | Novel reader |
| `-` | Smaller text | Novel reader | Novel reader |
| `t` | Type and page settings | Novel reader | Novel reader |
| `b` | Bookmark this spot | Novel reader | Novel reader (when bookmarkable) |
| `escape` | Back to the book | Novel reader | Novel reader |

Non-registry key handling: Dialog (Esc closes, Tab/Shift+Tab focus trap), Command palette (listed above), Account menu (Esc), Novel type panel (Esc closes, captured), Suggestion prompt (Enter submits, Shift+Enter newline), Search page input (Enter searches immediately), Series card in select mode (Space/Enter toggles), scrub bar (arrow keys), reader chrome auto-hide (any key reveals), wheel-zoom arming (Ctrl held + wheel zooms), book go-to-chapter field (Enter jumps, Esc clears), reader jump-to-page field (Enter jumps, Esc clears).

**Total: 34 registered bindings** (General 3, Library 2, Search 1, Sources 2, Reader 19, Novel reader 7).

### 2.10 Status screens (errors / 404)

| # | Screen | Copy | Actions |
|---|---|---|---|
| S1 | 404 `not-found.tsx` (inside the shell) | Giant faint "404", heading "Nothing here", "This page does not exist. It may have been renamed, or the series it pointed at may have been removed from your library." Footnote "Looking for something specific? Press Ctrl K to search everything." | Primary pill "Back home" → `/`; ghost pill "Open library" → `/library`. |
| S2 | Route error `error.tsx` | Normal: "500" / "Something broke" / "This page failed while rendering. Nothing was lost — trying again is usually enough." Backend unreachable (`ApiError` status 0): "···" / "Can't reach the server" / "The ManhwaManiacs backend did not answer. It may still be starting up, or the connection dropped. Your library is untouched." Footnote: "Reference {digest}" mono chip. | "Try again" (`reset()`), "Back home". |
| S3 | Root error `global-error.tsx` (replaces the document, no fonts, no providers) | "500" / "ManhwaManiacs failed to start" / "The application shell could not render. Reloading usually clears it; if it does not, the backend or the running build is the place to look." | "Try again", "Reload the app" (hard navigation to `/`). |
| S4 | Offline fallback `public/offline-fallback.html` (served by the service worker when a navigation fails offline) | App icon 72 px, status pill with dot "No connection"/"Back online" (live), "This page needs the server", "ManhwaManiacs can't reach your library right now. Chapters you saved for offline reading are still on this device and open as normal." Note "This page is served from your device by the app's service worker." | "Try again" (reload), link "Downloads". Static HTML, must be styled standalone per skin. |
| S5 | Reader landing `/reader` | Placeholder: BookOpen icon in a 64 px circle, "Reader", "Open a series from your library to start reading." | "Go to library". |

### 2.11 Shared state components used across screens

| # | Component | Variants / copy |
|---|---|---|
| C1 | `EmptyState` | Tones `empty` (primary icon disc), `error` (danger), `offline` (warning). 56 px icon disc, title, description, up to two action buttons (primary / secondary). |
| C2 | `OfflineState` | WifiOff, "You're offline", "{reason} Chapters you've downloaded still open with no connection at all." Actions: "Try again" + "Go to Downloads" (or only "Go to Downloads" when no retry). Auto-retries when the browser fires `online` (3 s cooldown). |
| C3 | `resolveViewState` | Every list screen resolves to `loading / offline / error / empty / content`. Offline = network-unreachable `ApiError` status 0. |
| C4 | Skeletons | `animate-pulse` blocks on `surface-2`; each screen has its own shape (listed per route). |
| C5 | `Dialog` | Centred modal, scrim `bg/85` (no blur), `overlay-in`/`panel-in` keyframes, glass panel max-width 512 px, max-height `100dvh-2rem`, title + 44 px "×" close button, Esc closes, focus trap, focus restore. |
| C6 | `Button` | Variants primary / secondary / ghost / danger; sizes sm (32 px, 40 px on coarse pointers), md 40, lg 44, icon 36 (40 coarse). `active:scale-[0.98]`, 200 ms transitions. |
| C7 | `PrimaryPillButton`, `GhostPillButton` | Uppercase pill CTAs (gradient fill / 2 px outline). |
| C8 | `Switch` | 44 × 24 track, 20 px knob, `role="switch"`. |
| C9 | `Slider` | Native range, 8 px track, 16 px primary thumb. |
| C10 | `Input` | 40 px, rounded-lg. `PasswordInput` adds an Eye/EyeOff reveal button (not in tab order). |
| C11 | `Badge` | default / primary / success / warning pills. |
| C12 | `Progress` | 8 px bar, default / gradient fill, 500 ms width transition. |
| C13 | `Kbd`, `KbdCombo` | Key caps. |
| C14 | `Card` (+Header/Title/Content) | Glass card, rounded-xl. |
| C15 | `CoverImage` | `next/image` wrapper with `data-cover-settled` for a CSS fade-in on load or error. |
| C16 | `FadeIn` | IntersectionObserver fade + translate (700 ms, `cubic-bezier(.25,.1,.25,1)`, scaled by preset motion factor). |
| C17 | `HeroHeading` | Syne black uppercase gradient heading (`clamp(1.5rem,6.5vw,6rem)`). |
| C18 | `GlassPanel` | Glass surface wrapper. |
| C19 | Unused premium components | `AnimatedText` (scroll-linked per-char opacity), `Magnet`, `ScrollMarquee`, `StickyStack`, `ContrastSection` exist but are not mounted on any route. |

## 3. Auth screens

### 3.1 `/login` — Login (`features/auth/components/login-screen.tsx`, `login-form.tsx`, `auth-card.tsx`)

Full-bleed, no shell. Calls `GET /auth/me` (already signed in → `router.replace("/")`) and `GET /auth/bootstrap-status`.

States:

| # | State | UI |
|---|---|---|
| L1 | Resolving | `AuthPending` full-screen spinner. |
| L2 | Server unreachable | AuthCard title "ManhwaManiacs", subtitle "We couldn't reach the server.", danger text (API message or "Could not load the sign-in page. Check that the backend is running."), secondary full-width "Try again" (refetch bootstrap). |
| L3 | Bootstrap mode (no accounts exist) | AuthCard "Welcome to ManhwaManiacs", subtitle "Create the first account to finish setup. It becomes the administrator." + RegisterForm in bootstrap mode (see 3.2). |
| L4 | Normal login | AuthCard "Welcome back", subtitle "Sign in to your ManhwaManiacs library." + LoginForm + footer "Need an account? **Create one**" (link `/register`, only when registration is open). |

AuthCard anatomy: centred column max 448 px, 56 px gradient "MM" logo tile (glow), HeroHeading title, muted subtitle, glass panel body, footer line. FadeIn y=20.

LoginForm elements:

| # | Element | Details |
|---|---|---|
| L5 | Username input | label "Username", `autoComplete=username`, autofocus, placeholder "yourname". |
| L6 | Password input | label "Password", reveal toggle (Eye/EyeOff, "Show password"/"Hide password"), placeholder "Your password". |
| L7 | "Keep me signed in" switch | default on → `remember` flag. |
| L8 | Inline error | `role="alert"` danger text (API message or "Could not sign in. Please try again."). |
| L9 | Submit | Full-width gradient pill "Sign in" (LogIn icon), "Signing in…" while pending; disabled until both fields filled. → `POST /auth/login {username,password,remember}` → `router.replace("/")` (→ `/library` → profile gate). |

### 3.2 `/register` — Register (`register-screen.tsx`, `register-form.tsx`)

States:

| # | State | UI |
|---|---|---|
| RG1 | Resolving | AuthPending. |
| RG2 | Server unreachable | AuthCard "Create your account" / "We couldn't reach the server." + "Try again". |
| RG3 | Registration closed | AuthCard "Registration closed" / "This ManhwaManiacs instance isn't accepting new accounts." body "Ask an administrator to create an account for you, then sign in." + "Back to sign in". |
| RG4 | Bootstrap | "Create the first account" / "This first account becomes the administrator." |
| RG5 | Open | "Join ManhwaManiacs" / "Join this ManhwaManiacs library." Footer "Already have an account? **Sign in**". |

RegisterForm elements: Username (autofocus), Password (reveal), Confirm password (reveal, live "Passwords don't match." alert, `aria-invalid`), Invite code (only when server says `invite_code_required`; placeholder "Ask whoever invited you"), Display name (optional, placeholder "How your name appears"), Email (optional, `type=email`, "you@example.com"), "Keep me signed in" switch, inline error (codes: `invite_code_required`, `invite_code_invalid`, `registration_disabled`, `username_taken`, `rate_limited`), submit "Create admin account" (ShieldCheck, bootstrap) or "Create account" (UserPlus), "Creating account…" while pending. → `POST /auth/register` → `router.replace("/")`. **9 elements.**

## 4. Profiles

### 4.1 `/profiles` — Profile picker (`profile-picker.tsx`, `profile-tile.tsx`)

Full-bleed takeover (no sidebar/topbar), base `#0D1117`. Entered from: profile gate, profile switcher chip, More → Switch profile.

| # | Element | Details |
|---|---|---|
| P1 | Heading | "What are you going to read today?" (hero gradient, 3xl→5xl). |
| P2 | Subtitle | "Choose a reading profile. Your progress, library, and mood follow the profile you pick." |
| P3 | Profile tile ×N (max 5) | Button `aria-label="Read as {name}"`: glass frame around an XL avatar (112–128 px gradient rounded-2xl with a lucide glyph) + name. Entrance: `mm-profile-in` 340 ms `cubic-bezier(.215,.61,.355,1)`, staggered 80 ms, from `translateY(10px) scale(.92)`. Hover ring primary/25. |
| P4 | Selection choreography | On click: chosen tile scales to 1.35 with primary ring + glow; others scale 0.9, fade to 20 %, blur 3 px; the chosen profile's mood tint cross-fades in behind (500 ms). After 450 ms hold, a full-screen mood fill fades in over 400 ms, then `router.push("/")`. Reduced motion: commit immediately. |
| P5 | "Add profile" tile | Dashed 112–128 px square with Plus, label "Add profile". Hidden at 5 profiles. Opens ProfileForm dialog. |
| P6 | Loading | "Loading profiles…". |
| P7 | Error | Danger text + secondary "Try again". |
| P8 | Empty | "You don't have any profiles yet. Create your first one to start reading." |

API: `GET /profiles`. Selecting writes the active profile to localStorage (`mm.active-profile`) and every subsequent request carries `X-Profile-Id`.

### 4.2 Profile form dialog (`profile-form.tsx`) — shared by picker and manage page

Dialog "Add profile" / "Edit profile".

| # | Element | Details |
|---|---|---|
| PF1 | Live avatar preview | 80 px avatar reflecting the current pick. |
| PF2 | Name input | label "Name", max 30 chars, placeholder "e.g. Late-night reads", autofocus. |
| PF3 | Avatar grid | 6-column grid of 12 presets (`aria-pressed`, `title`): Violet Spark (Sparkles, violet→fuchsia), Cyan Rocket (Rocket), Rose Heart (Heart), Amber Coffee (Coffee), Emerald Cat (Cat), Ember Flame (Flame), Steel Blade (Sword), Phantom (Ghost), Arcane Wand (Wand2), Lunar Moon (Moon), Starlight (Star), Bookworm (BookOpen). Selected: primary ring with offset. |
| PF4 | Mood tint chips | 7 pills with a colour dot: Romantic `#7a4650`, Action `#6e3228`, Comedy `#6f5228`, Horror `#4a3138`, Slice of Life `#5b5340`, Fantasy `#5a4658`, Default (`#0D1117`, untinted). Helper: "Tints the app background while this profile is active — never the reader." |
| PF5 | Mature (18+) switch | "Show mature (18+) content" / "Lets this profile see 18+ sources and series. Confirm you are of legal age where you live." No confirm dialog here (unlike Settings → Content). |
| PF6 | Error line | API message or "Could not save this profile." |
| PF7 | Cancel | ghost. |
| PF8 | Submit | "Create profile" / "Save changes" / "Saving…". → `POST /profiles` or `PATCH /profiles/{id}` `{name, avatar_key, mood, mature_content_enabled}`. |

### 4.3 `/profiles/manage` — Manage profiles (`profiles-settings-panel.tsx`)

Page header "Profiles" (display 4xl) + "Create, edit, and switch the reading profiles for your account." Entered from the sidebar footer "Profiles".

| # | Element | Details |
|---|---|---|
| PM1 | Panel header | Users icon tile, "Profiles", "Reading personas for this account — up to 5. Each carries its own mood tint." |
| PM2 | "Add" button | Plus, disabled at 5 profiles → ProfileForm. |
| PM3 | Profile row ×N | 44 px avatar, name, "Active" pill (Check) on the current one, "{Mood} mood" subline. Active row tinted primary. |
| PM4 | "Use" button | Ghost, on non-active rows → sets active profile in place (no picker animation). |
| PM5 | Edit icon button | Pencil, `aria-label="Edit {name}"` → ProfileForm (edit). |
| PM6 | Delete icon button | Trash2, hover danger → confirm dialog. |
| PM7 | Delete dialog | "Delete profile?" / "Delete **{name}**? This removes the profile from this account. It cannot be undone." Error line; Cancel / danger "Delete" ("Deleting…"). → `DELETE /profiles/{id}`. |
| PM8 | States | Loading "Loading profiles…"; error text + "Try again"; empty dashed box "No profiles yet. Add one to get started." |

## 5. `/more` — More hub (phone navigation)

Mobile tab "More". Mirrors the Flutter `more_screen.dart`. Also reachable on desktop by URL.

| # | Element | Details |
|---|---|---|
| M1 | Title | "More" (display 3xl). |
| M2 | Content-mode switch | Same component as sidebar (G16), full-width. Hidden when novels are off. |
| M3 | Section "Discover" | Rows: **Updates** ("New chapters the checker has found.", Bell, unread count badge), **Browse all** ("Every series on this server, filterable.", BookOpen), **Collections** ("Your own groupings of series.", List), **Find something to read** ("Describe what you feel like; get suggestions.", Heart). |
| M4 | Section "Library" | **Reading History** ("Revisit everything you've read, most recent first."), **Bookmarks** ("Pages you marked to come back to."), **Statistics** ("Reading time, streak, and pace."), **OCR Search** ("Search the text inside your chapters."). Note: OCR row is not mode-filtered here (sidebar hides it in Novels mode). |
| M5 | Section "Account" | **Switch profile** (→ `/profiles`, "Each profile keeps its own library and progress."), **Settings** ("Design, theme, reader, mature content, and shortcuts."), **System Status** (admin only, "Backend health, the update checker, and the queue."). |
| M6 | Row anatomy | Rounded-2xl bordered card: 40 px primary-tinted icon tile, label + optional count badge, one-line description, ChevronRight. 11 rows total (10 for non-admins). |

API: `GET /auth/me`, `GET /updates/notifications/unread-count`.

## 6. `/settings` — Settings (`app/settings/page.tsx`, `config/settings-tabs.ts`)

Entered from sidebar footer "Settings", More → Settings, command palette "Open settings", Updates settings card, "Choose a profile" links. Default tab: Design. The tab is local state (not in the URL, not persisted). All panels FadeIn (y 20, delays 0 / 0.05 / 0.1 / 0.15 s).

Page chrome:

| # | Element | Details |
|---|---|---|
| SG1 | Hero heading | "Settings" (6xl on md) + "Design, theme, reader, and account." |
| SG2 | Shortcut card: Reading History | `lg`+ only; glass card, 48 px History tile, "Reading History" / "Revisit everything you've read, most recent first.", ChevronRight that nudges on hover → `/library/history`. |
| SG3 | Shortcut card: System Status | `lg`+ and admin only → `/admin/status`. |
| SG4 | Tab rail | Horizontal scroll row on phone, 224 px vertical rail on `lg`; each tab = icon + label (+ description on `lg`); active = primary 15 % fill + glow. 8 tabs (6 for non-admins): Design (LayoutTemplate, "How the app is shaped"), Appearance (Palette, "Reading theme"), Reader (BookOpenText, "Page gap and cinema mode"), Notifications (Bell, "Update checks and alerts", admin), Content (ShieldAlert, "Mature (18+) content"), Security (ShieldCheck, "Password and sessions"), Shortcuts (Keyboard, "Keyboard bindings"), Backup (DatabaseBackup, "Export and restore", admin). |
| SG5 | Footer note | Bell icon "Settings save immediately and apply without restarting the app." (Must change: the new skin switch restarts the app.) |
| SG6 | Panel header (shared anatomy) | 40 px gradient icon tile + display title + muted description. |
| SG7 | No-profile warning box (shared) | Warning box "No reading profile is active… there is nowhere to put this choice yet." + "Choose a profile" link (Design, Appearance, Reader, Content). Controls disabled. |

### 6.1 Design panel

| # | Element | Details |
|---|---|---|
| SG8 | Description | Explicit: "5 presets. Each one reshapes the whole app — density, surfaces, type, layout. Independent of the palette, and saved for this profile on this device." / default: "Using the app's own design. Pick one of 5 presets…". |
| SG9 | Preset radio cards ×5 | 1/2/3-column grid; each = PresetSwatch (mini mock of a title + card grid at the preset's radius, gap, padding, translucency, border, serif) + label + description + character line + Check when selected. **Hover or focus live-previews the whole app**, leaving restores. Signature ("Glass panels, generous spacing, poster-led browse."), Matte ("Solid surfaces, crisp hairlines, no blur."), Compact ("Tighter rhythm, smaller type, many more covers per screen."), Editorial ("Serif headings, wide margins, metadata beside the artwork."), Cinema ("No frames, edge-to-edge, almost no motion."). Each preset also sets default library density, default reader cinema, motion scale 1 / .7 / .6 / .8 / .35. |
| SG10 | Footnote | "Applies as you pick it — hover a preset to see the whole app in it. No reload, and nothing here interrupts a chapter you are in the middle of." |

**Redesign: this panel becomes the Skin picker (Cinematic / Glass) with an "app restarts" confirmation.**

### 6.2 Appearance panel

| # | Element | Details |
|---|---|---|
| SG11 | Description | "42 palettes. Each one recolours the whole app. Saved for this profile on this device." / "Using the default palette. Pick one of 42…". |
| SG12 | Filter input | Search icon, "Filter palettes — name, author, mood", clear X icon button ("Clear filter"). |
| SG13 | Group headers | "Dark" 28 (Eclipse, Midnight + 26 generated) and "Light" 14 (Sepia, Daylight + 12 generated), with counts. |
| SG14 | Palette radio cards ×42 | ThemeSwatch (80 px: mini sidebar, card with two text bars, accent pill), label, description, author line, Check. Generated set: Gruvbox Hard, Gruvbox, Gruvbox Material, Nord, Dracula, Catppuccin Mocha / Macchiato / Latte, Rosé Pine / Moon / Dawn, Kanagawa, Everforest, Tokyo City, Ayu Dark / Mirage, One Dark / One Light, Monokai, Material, GitHub Dark / Light, Flexoki Dark / Light, Oxocarbon, Spaceduck, Eldritch, Selenized Black / White, Horizon Dark / Light, Zenburn, Vesper, Gruvbox Light, Nord Light, Tokyo Night Light, Equilibrium Light, Sakura. Default GitHub Dark. |
| SG15 | No match | Dashed box "No palette matches “{q}”." |

**Redesign: removed (dark-only AMOLED, no accent picker).** The novel reader keeps its own paper palettes (§10.3).

### 6.3 Reader panel

| # | Element | Details |
|---|---|---|
| SG16 | Toggle "Gap between pages" | "Off by default so a webtoon strip reads as one seamless image. Turn on for a thin separator between pages in continuous mode." |
| SG17 | Toggle "Cinema mode" | "Auto-hide every reader control after a few idle seconds; a tap, pointer move or the C key brings them back. Can also be toggled from inside the reader." |

(The reader's own settings sheet exposes the rest: dimmer, warmth, page transition, tap zones, layout, fit, direction, zoom, auto-scroll — §9.5.)

### 6.4 Notifications panel (admin, instance-wide)

| # | Element | Details |
|---|---|---|
| SG18 | Schedule strip | 3 cells: Last check, Next check (est.) (warning colour when overdue; "Not scheduled yet"), Interval "{n} min". Overdue note: "The next check was expected N minutes ago. See System Status for whether the scheduler is running." |
| SG19 | Toggle "Check for new chapters automatically" | "Nothing is checked and nothing notifies while this is off." |
| SG20 | Toggle "Check on startup" | "Run one check as soon as the server starts." |
| SG21 | Interval slider | Clock icon "Check interval", live mono value "{n} min", range 5–120 step 5, helper "How often followed series are checked (5–120 minutes). The server enforces a five-minute floor." |
| SG22 | Toggle "Notify me about new chapters" | "The master switch. Turn a single series off from its own page." |
| SG23 | Save | "Save settings" / "Saving…" + feedback "Saved." or error. Draft-then-save (not instant, unlike every other panel). |
| SG24 | States | Skeleton 5 × 56 px; error text + "Try again". |

API: `GET /updates/settings`, `PUT /updates/settings {enabled, check_interval_minutes, notify_enabled, check_on_startup}`.

### 6.5 Content panel (18+ gate)

| # | Element | Details |
|---|---|---|
| SG25 | Toggle "Show mature (18+) content" | "Reveals adult sources, search results, and recommendations. Hidden by default — enabling requires confirming you are 18 or older." Off applies immediately. |
| SG26 | Confirm dialog "Enable mature content?" | Warning box ("This shows adult (18+) sources, search results, and recommendations throughout ManhwaManiacs. Only continue if you are of legal age to view mature content where you live. You can turn this off again at any time.") + Cancel / "I am 18 or older — Enable". |
| SG27 | Blocked state | Warning box with the no-profile reason + "Choose a profile"; switch disabled. |
| SG28 | Errors | Inline "Failed to update this setting."; load error + "Try again". |

API: `GET /settings`, `PUT /settings {mature_content_enabled}` (profile via header), then every mature-gated query root is invalidated.

### 6.6 Security panel

| # | Element | Details |
|---|---|---|
| SG29 | Current password | Reveal toggle, "Your current password". |
| SG30 | New password | Reveal toggle, "At least 8 characters" (max 4096). |
| SG31 | Confirm new password | Reveal toggle, "Type it again". |
| SG32 | Validation / result lines | "Enter your current password.", "Enter a new password.", too short, "Password is too long.", "The new passwords don't match.", "Your new password must be different from your current one."; success (primary) "Password changed. Every other device has been signed out — this one stays signed in." |
| SG33 | "Change password" | KeyRound, "Changing…", helper "Changing it signs out every other device. This one stays signed in." → `POST /auth/change-password`. |
| SG34 | Session row | Device label ("ManhwaManiacs app" for the Flutter client, "{Browser} on {Platform}", or "Unknown device"), "This device" pill (Laptop) on the current one (tinted row), "Last used {date} · {ip}", "Signed in {date} · expires {date}". |
| SG35 | Session "Sign out" (current) | Secondary → `POST /auth/logout` → `/login`. |
| SG36 | Session "Revoke" (others) | Danger → `DELETE /auth/sessions/{id}`. |
| SG37 | Sessions refresh | Ghost RefreshCw (spins) "Refresh" / "Refreshing…"; states "Loading sessions…", error + "Try again". |
| SG38 | "Sign out everywhere" | Danger zone box (TriangleAlert) + danger button. |
| SG39 | Sign-out-everywhere dialog | Danger explainer, acknowledgement switch "I understand this signs me out on this device too", Cancel / danger "Sign out everywhere" ("Signing out…", disabled until acknowledged) → `POST /auth/logout-all` → `/login`. |

### 6.7 Shortcuts panel

| # | Element | Details |
|---|---|---|
| SG40 | Live registry list | Grouped rows (description + key chips) — the same data as the `?` dialog; "No shortcuts registered yet." Read-only (no rebinding). |

### 6.8 Backup panel (admin) — see §16. 6.9 Members panel (admin, rendered under Backup) — see §17.

## 7. Library screens

### 7.1 `/library` — Library shelf (followed series) (`LibraryShelfView.tsx`)

Default landing (`/` → 307 → `/library`; PWA `start_url`). Mobile tab 1, sidebar "Library".
API: `GET /library/series?page=1&per_page=200&sort=recently_updated`, `GET /library/continue-reading?limit=1`. Rows filtered client-side by content mode.

| # | Element | Details |
|---|---|---|
| LS1 | Hero heading | "Library" (`clamp(1.5rem,6.5vw,3rem)`), FadeIn. |
| LS2 | Count line | "{n} series followed" / Novels: "{n} novel(s) on your shelf". |
| LS3 | Browse-sources icon button | Telescope, 44 px round, `title="Browse Sources"` → `/sources`. |
| LS4 | Continue strip (phone, `<md`) | One row card: 44 px cover, title, "{chapter label} · page X of Y" (novels: "N% in"), 4 px progress bar, ChevronRight. Links into the reader at the saved page. Hidden when nothing is in progress. |
| LS5 | Continue rail (`md`+) | Section label "Continue Reading" + **hero card** "Jump back in" (cover 112–176 px with Play overlay on hover, 2-line title, chapter label, page x of y / "% in", progress bar, "{n}% through this chapter"). With limit=1 only the hero shows here. |
| LS6 | Followed grid (manga mode) | 3 / 4 / 6 / 8 columns (`sm/md/lg`), `stagger-in` entrance. |
| LS7 | Followed series card | 2:3 cover (hover scale 1.05, 300 ms), "N new" / "99+ new" primary pill top-right, 2-line title, subtitle = read state ("Ch 12 of 40", "Not started", "Started") or "{n} chapters". Link → `/library/{followedId}`. |
| LS8 | Novel shelf (novels mode) | `NovelShelf` component instead of the grid (see §10.1). Book link → source series page. Note line = read state or reading status. |
| LS9 | Loading | Skeleton: 40 × 160 heading bar + 12 cover placeholders. |
| LS10 | Offline | OfflineState "Your library needs a connection to load." |
| LS11 | Error | EmptyState error "Couldn't load your library" + "Try again". |
| LS12 | Empty | Full-height centre: BookOpen 40 px, "Your library is empty" / "Your shelf is empty", "Follow series from Sources to build your warm little shelf." / "Add a book from a novel source to start your shelf.", gradient pill "Browse Sources" (Compass). |

### 7.2 `/library/browse` — Browse all (full catalogue with filters) (`LibraryView.tsx`, `LibraryToolbar.tsx`, `SeriesGrid.tsx`, `SeriesCard.tsx`, `BulkActionBar.tsx`)

Sidebar "Browse all", More → Browse all. URL state: `?search=&sort=&status=&reading_status=&is_favorite=`.
API: `GET /library/series?page=1&per_page=200&sort&search&reading_status&is_favorite`, `GET /library/continue-reading?limit=12`.

Toolbar:

| # | Element | Details |
|---|---|---|
| LB1 | Hero heading | "Browse" (6xl on md) + "{n} series" / "{n} novels". |
| LB2 | Select toggle | CheckSquare, "Select" / "Done" (icon-only below `sm`), `aria-pressed`. |
| LB3 | Filters toggle | SlidersHorizontal "Filters", active style when open or filters applied. |
| LB4 | Sort select | Native `<select>`: Recently Updated (default), Recently Added, Title, Manual Order. |
| LB5 | Density switch (`md`+, manga only) | 3 icon buttons: Comfortable (LayoutGrid), Compact (Grid3X3), List (LayoutList). Stored per profile `manhwamaniacs:library-density`; default comes from the design preset. |
| LB6 | Search input | 44 px, leading Search icon, placeholder "Search by title...", debounced 300 ms into URL. `/` focuses it. |
| LB7 | Status chip rail | Horizontally scrolling single row: All, Reading, Not Started (`unread`), Completed + "★ Favorites" toggle chip. Active = primary fill + glow. |
| LB8 | Filters panel | Glass panel: "Shelf status" select (Any, Unread, Reading, Completed, On hold, Plan to read, Dropped); "Clear filters" ghost button (when active); hint (lg+) "Press / to focus search · shift-click a cover to select a range". |

Body:

| # | Element | Details |
|---|---|---|
| LB9 | Continue Reading section (`md`+, only when no search/filter) | Hero card + horizontal snap rail of 280 px cards (70 × 104 cover with Play overlay, title, chapter label, "Page N" / "In progress", % and 4 px bar). Loading skeleton: title bar, 220–260 px hero block, 4 × 280 px cards. |
| LB10 | Series grid — Comfortable | `densityGridClassName`; cards 2:3 with bottom gradient, title (2 lines) + meta line over the cover. |
| LB11 | Series grid — Compact | Smaller cards, title only (xs), no row actions. |
| LB12 | Series list — List density | Row card: optional checkbox, 64 px square cover, title + status pill, meta line, Follow bell + favourite star buttons (36 px). |
| LB13 | Card: status badge | Top-left pill (reading = primary, completed = success, on_hold = accent, plan_to_read/other = dark translucent), text = status with underscores → spaces, uppercase. Hidden while selecting. |
| LB14 | Card: select checkbox | 24 px, top-right. Hover/focus-revealed on pointer devices (`sm`+), always visible on phones. Click toggles; Shift-click selects a range. |
| LB15 | Card: follow/unfollow bell | 32 px round `bg-black/60`, Bell / BellRing (primary when followed), hover-revealed. `aria-label` Follow/Unfollow; error shown via `title` + danger colour. → `POST /library/follow` / `DELETE /library/follow/{id}`. |
| LB16 | Card: favourite star | 32 px round, "★"/"☆" glyphs, always visible when favourited else hover-revealed. → `PATCH /library/series/{id} {is_favorite}`. |
| LB17 | Card hover | Cover scale 1.05, ring primary/30, outer glow `0 0 24px rgba(88,166,255,.22)`. Selected: 2 px primary ring with offset, cover dimmed to 75 %. |
| LB18 | Select mode | Whole card becomes a checkbox (`role="checkbox"`, Space/Enter), `select-none`. |
| LB19 | Grid keyboard nav | Arrows / h j k l / Home / End move focus. |
| LB20 | Overflow note | "Showing the first {n} of {total} series — narrow it with search or a filter." (when >200). |
| LB21 | Novel shelf (novels mode) | NovelShelf with selection support; empty copy per state ("No results found", "No novels match these filters", "No novels yet" + "Browse sources"). |
| LB22 | Loading | 12 / 24 / 8 skeleton tiles by density. |
| LB23 | Offline / Error | Same copy as 7.1. |
| LB24 | Empty (library) | Library icon, "Nothing followed yet", "This account has no series yet. Browse a source and follow one to start your library.", "Browse Sources" (Compass). |
| LB25 | Empty (search) | SearchX, "No results found", "Try a different search term or clear filters." |
| LB26 | Empty (filter) | SlidersHorizontal, "No series match these filters", "Adjust your filters or favorites toggle to see more series." |

Bulk action bar (fixed bottom sheet, `sheet-up-in` animation, glass, max 896 px):

| # | Element | Details |
|---|---|---|
| BA1 | Count | "{n} selected". |
| BA2 | Select all | ghost "Select all {visible}" (disabled when all selected). |
| BA3 | Favourite | Star → `PATCH /library/series/{id} {is_favorite:true}` per row. |
| BA4 | Unfavourite | StarOff → `is_favorite:false`. |
| BA5 | Mark read | BookCheck → `PATCH … {reading_status:"completed"}`. |
| BA6 | Mark unread | → `{reading_status:"unread"}`. |
| BA7 | Unfollow | danger Trash2 → `DELETE /library/follow/{id}` per row. **No confirmation dialog.** |
| BA8 | Clear | ghost, right-aligned. |
| BA9 | Running state | Spinner + "{done} of {total} · {failed} failed" + Progress bar + "Stop" (aborts; concurrency 4). |
| BA10 | Result message | "Stopped: N series {verb}, M failed, K skipped." / "Nothing {verb} — all N failed." / success line + X "Dismiss". |

### 7.3 `/library/[seriesId]` — Followed series detail (`SeriesDetailView.tsx`)

Entered from followed cards, command palette Library results, collection grids. API: `GET /library/series/{followedId}` (includes chapters + per-chapter progress).

| # | Element | Details |
|---|---|---|
| SD1 | Backdrop banner | 280–320 px, cover blurred (`blur-sm`, brightness .35) + void gradient. |
| SD2 | Back link | ArrowLeft "Back to library" (top-left over banner) → `/library`. |
| SD3 | Poster | 220 px 2:3, rounded-3xl, glow, sticky on `lg`. Overlaps banner by −144 px. |
| SD4 | Title | 3xl/4xl bold. |
| SD5 | Favourite button | Star (filled when on), "Favorited" / "Add Favorite" pill → `PATCH /library/series/{id} {is_favorite}`. |
| SD6 | Author | "by {author}". |
| SD7 | Reading-status select | Pill-styled native select with 6 statuses (unread, reading, completed, on hold, plan to read, dropped), tinted per status → `PATCH {reading_status}`. |
| SD8 | Notifications chip toggle | "Notifications on" / "Notifications off" → `PATCH {notify}` (per-series new-chapter alerts). |
| SD9 | Meta row | "{n} chapters", first 4 genres comma-joined. |
| SD10 | Primary CTA | Gradient pill with Play: "Read" (nothing started) / "Continue" (resume point) → reader at saved page. |
| SD11 | Caught-up state | Disabled pill "All caught up". |
| SD12 | "Read all" ghost pill | `title="Every chapter in one continuous scroll"` → `/read-all/{source}/{series}?from=…` (manga only, >1 chapter). |
| SD13 | Description | Paragraph, fg/80. |
| SD14 | Chapters header | BookOpen icon, "CHAPTERS", "({n})", Download trigger (see offline), sort pills "Newest" / "Oldest" (persisted per series in scoped `mm.chapter-sort:{source}:{series}`). |
| SD15 | Chapter row | Number tile (36 px mono, hover primary), title (or "Chapter N"), sub-line: upload date ("Today", "Yesterday", "Nd ago", or date), "x/y pages" (in progress) or "N pages", "Read" pill with Check (completed rows dimmed with `bg-black/25`), SavedChapterMark (download state icon), "In progress" primary Badge, hover ChevronRight. Link → reader at last page. |
| SD16 | Chapter row — select mode | Leading ChapterCheckbox (disabled if already saved), click toggles, Shift-click range, `aria-pressed`. |
| SD17 | Chapter download bar | Sticky bottom glass bar (see §12.2). |
| SD18 | Links-not-ready skeleton | Up to 6 rows with 36 px tile + bar while content mode resolves. |
| SD19 | Empty chapters | "No chapters found for this series." |
| SD20 | Loading | Banner block + poster + title/description blocks. |
| SD21 | Error | Danger text + primary pill link "Back to library". |

### 7.4 `/library/collections` — Collections (`CollectionsView.tsx`)

API: `GET /library/collections`, `POST /library/collections {name, description?}`.

| # | Element | Details |
|---|---|---|
| CO1 | Title + count | "Collections" (display 4xl), "{n} collection(s)" or "Organize your library into custom collections." |
| CO2 | "New Collection" button | Plus, primary with glow → dialog. |
| CO3 | Search input | "Search collections…" (client filter on name/description). Only when ≥1 collection. |
| CO4 | Sort dropdown | SlidersHorizontal button showing current label; popover menu (w-48) "Name A–Z" / "Most series" / "Recently created"; invisible full-screen button closes it. |
| CO5 | Collection banner card | 21:9 (24:9 on `sm`) min 140 px, layered gradients (accent → panel → primary, void fades), giant faint initials (display 6xl, `sm`+), name (xl/2xl, hover primary), 1-line description, BookOpen "{n} series". Hover scale 1.01 + glow. → `/library/collections/{id}`. |
| CO6 | New Collection dialog | Name ("My Reading List"), Description ("Optional description"), error line, Cancel / "Create" ("Creating…"). |
| CO7 | Loading | 4 banner skeletons. |
| CO8 | Offline / Error | "Collections need a connection to load." / "Couldn't load collections". |
| CO9 | Empty | FolderOpen, "No collections yet", "Create collections to group your series by theme, mood, or reading list.", "Create your first collection" (Plus). |
| CO10 | No search match | Dashed glass box "No collections match your search" / "Try a different term or clear the search." |

### 7.5 `/library/collections/[collectionId]` — Collection detail (`CollectionDetailView.tsx`)

API: `GET /library/collections/{id}`, `GET /library/series` (all followed, for the add dialog), `PATCH /library/collections/{id} {name?, description?}`, `DELETE /library/collections/{id}`, `POST /library/collections/{id}/series {source_id, series_key}`, `DELETE /library/collections/{id}/series` (body `{source_id, series_key}`).

| # | Element | Details |
|---|---|---|
| CD1 | Header band | Gradient (accent → void → primary) with bottom fade + border. |
| CD2 | Back link | "Back to collections". |
| CD3 | Name / description / count | Display 4xl; "{n} series" with BookOpen. |
| CD4 | Edit button | Pencil → Edit dialog (Name, Description, error, Cancel / "Save" / "Saving…"; disabled when unchanged). |
| CD5 | Add Series button | Plus → Add dialog: search "Search series…", scrollable list (max 400 px) of followed series not already in it (32 × 48 cover + title), click adds and closes; loading 4 skeleton rows; "No series available." |
| CD6 | Remove Series button | Minus (only when non-empty) → Remove dialog: explainer "Removing a series takes it out of this collection only — it stays in your library.", member rows (cover, title, "No longer followed" subline for orphans), X icon → inline confirm Cancel / danger "Remove" ("Removing…"). |
| CD7 | Delete button | danger Trash2 → dialog "Delete collection?" "Delete **{name}**? The series in it stay in your library. This cannot be undone." Cancel / "Delete" ("Deleting…"). |
| CD8 | Member grid | `SeriesGrid` (comfortable), same cards as Browse (follow bell + favourite star), no selection. |
| CD9 | Empty | BookOpen "This collection is empty" + "Add series" action. |
| CD10 | Mode-mismatch empty | "No {novels/series} in this collection" / "It holds titles from the other mode. Switch modes to see them." |
| CD11 | Loading | Back-link bar, 192 px header block, 6 cover skeletons. |
| CD12 | Error | Danger text + "Back to collections". |

### 7.6 `/library/history` — Reading history (`ReadingHistoryView.tsx`)

API: `GET /reader/history?limit=50&offset=0&collapse=series`; "Next" on a finished entry fetches `GET /sources/{s}/series/{k}/chapters`.

| # | Element | Details |
|---|---|---|
| RH1 | Title | "Reading History" (page-title) + "Books you have been reading, most recent first." |
| RH2 | History tile | 2:3 cover (link → series page; History icon placeholder when no cover), bottom 4 px progress line (chapter %), 2-line title (muted when the series title is unknown), subline "{chapter label}[ · done] · {date}". |
| RH3 | Continue chip | Bottom-right pill over cover: Play + "p. {n}" (manga) / "{n}%" (novel) → reader at the saved spot. |
| RH4 | Next chip | For completed chapters: Play "Next" button (fetches chapter list, opens the next chapter or falls back to the series page); `aria-busy` while resolving. |
| RH5 | States | 10 skeleton covers; offline "Reading history needs a connection to load."; error "Couldn't load reading history"; empty History "Nothing read yet" / "Open a chapter from your library and it will show up here as you go." + "Go to library". |

No pagination control (fixed 50).

### 7.7 `/library/bookmarks` — Bookmarks — see §13.

### 7.8 `/library/recommendations` — Find something to read (`RecommendationsView.tsx`, `SuggestionPromptBox.tsx`, `WorldTitleCard.tsx`)

API: `GET /library/world/recommendations` (sections + for_you + unavailable_reason), `GET /library/suggest/availability` (available, remaining_today, reason), `POST /library/world/suggest {prompt}` (AI, DeepSeek, up to ~40 s+).

| # | Element | Details |
|---|---|---|
| RC1 | Title / subtitle | "Find something to read"; subtitle varies: "Describe it in your own words. Suggestions are weighed against what you already read." / "You've used today's AI suggestions. They reset at midnight UTC — the picks below still work." / "Titles from everywhere, picked from what you already read." |
| RC2 | Prompt textarea | 3 rows, resizable, placeholder "e.g. a revenge story with a competent lead, no harem", max 600 chars, min 3 to submit. Enter submits, Shift+Enter newline. Only when AI is available. |
| RC3 | Example chips ×3 | "A murim regressor who comes back stronger", "Magic academy, but the lead is already strong", "Something slow and political, not a power fantasy" — click fills and submits. |
| RC4 | Submit button | Sparkles "Suggest something" / "Thinking…". |
| RC5 | Quota hint | "{n} left today" when ≤10. |
| RC6 | AI results | Pending: 4 card skeletons. Error: "Couldn't suggest anything" + message ("Try describing it differently."). Success: grid of WorldTitleCards. |
| RC7 | Unavailable note | Quiet muted line with the server's `unavailable_reason`. |
| RC8 | Section "For you" | Grid (1/2/3 columns) of WorldTitleCards. |
| RC9 | Sections "Because you read {title}" | One per seed series. |
| RC10 | WorldTitleCard | Glass card: 80 × 120 cover (ImageOff placeholder on error), 2-line title, badge line "{format} · {status}", numbers "{n} ch · ★ 8.4", up to 3 genre chips, footer: if on an installed source → Globe pill "On: {source} [+N more]" and the whole card links to that source series page; else "Not on your sources" + "Search" chip (→ `/search?q=`) + optional external "Read on {site}" chip (new tab). Optional "why" line under the card (AI reason). |
| RC11 | States | Loading: "For you" + 6 skeletons; offline; error "Couldn't load recommendations"; empty Heart "Nothing to go on yet" / "Read or follow a few series first — picks here start from what you read." + "Browse Sources". |

### 7.9 `/library/statistics` — Reading statistics (`StatisticsView.tsx`, `ActivityChart.tsx`)

API: `GET /library/statistics?days={7|30|90}&tz_offset_minutes={n}`.

| # | Element | Details |
|---|---|---|
| ST1 | Title | "Reading Statistics" + "What you have actually read, from every session recorded on this profile." |
| ST2 | Range picker | Segmented "7 days" / "30 days" (default) / "90 days". Only shown with content. |
| ST3 | Scope note | Explains that totals are all-mode while lists are mode-scoped (novels on). |
| ST4 | Stat cards ×4 | Pages read (BookOpen), Time read (Clock), Chapters (Layers), Series (BarChart3); big display value in primary + caption ("{n} all time", "{n} finished all time", "{n} followed"). |
| ST5 | Streak card | Flame "Current streak" N days, "Longest" N days, "Days read" N of {window}; 14 dot sparkline (primary = read, fg/15 = not) with per-dot tooltip; "Last read {date}" / "Not read yet". |
| ST6 | Activity chart | Custom SVG, 260 px (200 px compact < 520 px wide). Bars = pages/day (primary, .85), dashed line + square markers = time/day, left axis pages, right axis time, x date labels (4–6), gridlines, per-day transparent hit rects with native tooltips, legend. Aside: "Best day {date} · {n} pages". Empty window note. |
| ST7 | "When you read" | 24-bar hour histogram (h-32), bar opacity by value, hour labels 0/6/12/18/23, aside "Peak {range}". |
| ST8 | "Where you read" | Per-source rows: name, "{pages|chapters} · {time}", Progress bar with share %. |
| ST9 | "Most read" | Series rows: 44 × 64 cover, title link (→ series page), "{pages} · {chapters} · {time}", "Last read {date}". |
| ST10 | "Recent sessions" (all time) | Bordered rows: series link, chapter link (primary), "{pages} · {time}", started datetime. |
| ST11 | "Your library" | Aside "{n} followed · {n} favourites · {n} chapters finished"; per-reading-status rows with count + Progress. |
| ST12 | Footnote | Badge "Days start at UTC±HH:MM", session cap explanation "Reading time counts each session up to {cap}…", "Recording since {date}." |
| ST13 | States | Skeleton (4 cards, streak bar, 320 px chart, 2 panels); offline "Statistics need a connection to load."; error "Couldn't load statistics"; empty BarChart3 "No reading recorded yet" (+ "Browse Sources", "Go to library"); followed-but-never-read BookOpen "Nothing read on this profile yet" + Library shape card. |

### 7.10 `/search` — Global search (`SearchView.tsx`, `GlobalSearchGroupSection.tsx`, `GlobalSearchResultCard.tsx`)

Mobile tab, sidebar "Search", `?q=` seeds the box (used by WorldTitleCard "Search").
API: `GET /sources/search?q=&page=1&per_page=40&tier=1` then, if the response says `next_tier: 2`, `…&tier=2` for slow sources; per-source retry `GET /sources/{id}/series?query=`. Recent searches stored per profile (`manhwamaniacs:recent-searches`, max 4, min 2 chars).

| # | Element | Details |
|---|---|---|
| SE1 | Title | "SEARCH" (display 4xl/5xl, centred) + (`md`+) "Find your next favorite series". |
| SE2 | Search input | 56 px, rounded-2xl, leading 20 px Search icon, placeholder "Search manga, manhwa, webtoons...", debounced 300 ms, Enter searches now, `/` focuses. |
| SE3 | Recent chips | Clock "RECENT" label + chips (horizontal scroll on phones). |
| SE4 | Trending chips | TrendingUp "TRENDING": fantasy, romance, action, manhwa, manga, webtoon, horror, sci-fi. |
| SE5 | "Advanced Filters" toggle | Pill with SlidersHorizontal → glass info panel ("Search spans your local library and every enabled source connector at once." + "/" hint + "Use the Library page for status, sort, and collection filters."). No real filters. |
| SE6 | Idle empty state (`md`+) | Search icon "Start typing to search" / "Search your library and every source connector at once." |
| SE7 | Results header | BookOpen "RESULTS"; line "Searching sources…" / "{n} results found" / "{n} results so far · searching {k} more sources…"; scope "Searched {n} sources ({m} failed)". |
| SE8 | Source group section | Header: Library tile (local group) or 28 px SourceLogo + source name + total count pill. Body: result cards, or a note box ("No matches" / error text with CloudOff in danger tone) + secondary "Retry" (RefreshCw) for failed sources; retrying shows 2 skeleton cards. |
| SE9 | Result card | Glass card: 80 × 120 cover (ImageOff placeholder), 2-line title (hover primary), author, footer chips: source badge ("LIBRARY" cyan / source name primary Globe — hidden inside groups), "{n} chapters". → `/library/{id}` for local hits, `/sources/{s}/series/{id}` otherwise. |
| SE10 | Quiet sources disclosure | "Show/Hide {n} sources with no matches" pill with Chevron → reveals those groups. |
| SE11 | States | Loading 4 skeleton cards; offline "Search needs a connection to reach your library and sources."; error "Search failed" + retry; empty SearchX "No results found" / "Try a different search term across your library and sources." |

## 8. Source screens

### 8.1 `/sources` — Sources list (`SourcesListView.tsx`)

Mobile tab 2, sidebar "Sources", first-run hint target, empty-library CTAs.
API: `GET /sources` (all installed connectors, ~50; mature ones only when the profile's 18+ gate is on), `GET /sources/pins`, `PUT /sources/pins {source_ids[]}` (full replace, ordered).

| # | Element | Details |
|---|---|---|
| SL1 | Title | "Sources" (display 3xl bold). |
| SL2 | Filter input | Rounded-full 44 px `type=search`, Search icon, "Filter sources…". |
| SL3 | Filter chips | "All" / "Pinned" / "18+" (44 px min on touch). |
| SL4 | Pin error banner | Danger box "Failed to update your pinned sources." (or API message). |
| SL5 | Pins load error | Muted box "Your pinned sources could not be loaded, so pinning is unavailable until they are." + "Try again". |
| SL6 | Section "Pinned" | Pin icon header; pinned rows in pin order. |
| SL7 | Section "All sources" / "Sources" | Telescope icon header. |
| SL8 | Source row card | Rounded-2xl bordered row: 44 px SourceLogo (icon or favicon fallback, or initial letter on gradient), name (body face), "18+" danger pill for mature sources, description or "Unavailable" (pinned but no longer installed → row at 60 % opacity, not clickable). Row link → `/sources/{id}`. Hover border primary/40. |
| SL9 | Pin toggle | 44 px round icon button on each row: Pin (unpinned) / PinOff in primary (pinned); `aria-pressed`, "Pin {name}" / "Unpin {name}". Disabled while pins load or save. |
| SL10 | Loading | 36 × 128 heading bar + 10 row skeletons. |
| SL11 | Error | Centred danger text + "Try again". |
| SL12 | Empty | "No sources installed". |
| SL13 | No match | "No sources match" / "Try a different name." — Pinned filter: "No pinned sources" / "Tap the pin on any source to keep it at the top." |

Content mode filters sources by `content_kind` (manga vs novel).

### 8.2 `/sources/[sourceId]` — Source catalogue browser (`SourceBrowserView.tsx`)

Entered from source rows, command palette Sources, genre chips on a source series page (`?genre=`), "Back to source" links.
API: `GET /sources` (name/icon), `GET /sources/{id}/browse-modes`, `GET /sources/{id}/genres`, `GET /sources/{id}/series?page=&query=&sort=&genre=` (infinite, auto-loads on scroll), refresh = same with `refresh=true`, `GET /library/continue-reading?limit=9` (loading carousel covers).

| # | Element | Details |
|---|---|---|
| SB1 | Header | 48 px SourceLogo + source name (display 3xl, hover primary). |
| SB2 | Count line | "{shown}[ of {total}] series/books[ · “{query}”]". |
| SB3 | Freshness chip | "Updated {n} min/h/d ago" (muted) or stale "Saved copy · {age}" (warning, CloudOff) with tooltip explaining the cached catalogue; ticks every 30 s. |
| SB4 | Refresh button | Ghost 28 px, RefreshCw (spins) "Refresh" / "Refreshing…", `title="Refresh this catalog from the source"`. |
| SB5 | Genre select | Label "Genre", native select "All genres" + source genres; writes `?genre=` with `router.replace` (no scroll). |
| SB6 | Search field + button | Label "Search", input "Search this source…" (debounced 300 ms, `/` focuses) + primary "Search" submit. |
| SB7 | Browse-mode buttons | Only when not searching and the source exposes >1 mode (e.g. Latest, Popular…): sm buttons, active = primary. |
| SB8 | Catalogue grid (manga sources) | 2 / 3 / 4 / 5 / 6 columns, `stagger-in`. Card: 2:3 cover with border (hover primary border + ring + scale 1.05), 2-line title under. Keyboard grid nav. → `/sources/{id}/series/{seriesId}`. |
| SB9 | Novel shelf (novel sources) | `NovelShelf` with author, description, chapter count, status, genres (see §10.1). Empty "No books found". |
| SB10 | Loading overlay | Absolute over the grid, rounded-3xl surface: 56 px SourceLogo, "Opening {source}" + 3 pulsing dots (0/150/300 ms delays), sub-line "Fetching catalog…" → after 3 s "This source can take ~10s." plus a source-hued radial wash (hue hashed from source id). Carousel: slides of 3 covers from the reader's continue-reading history cross-fading every 3.5 s (700 ms), or 3 skeleton covers + rotating tips ("Tip: press / anywhere…", "Tip: pick a browse mode…", "Tip: tap any genre chip…", "Tip: your reading progress syncs…"). Fades out over 500 ms when data arrives. Under it: 12 skeleton tiles. |
| SB11 | Infinite-scroll sentinel | 32 px invisible element; "Loading more…" text while fetching. |
| SB12 | Load-more failure | "Couldn’t load more." + secondary "Retry" (refetches only the failed page). |
| SB13 | End marker | "End of results". |
| SB14 | Full error | EmptyState error "Could not load source catalog" + message + "Try again". |
| SB15 | Empty | SearchX "No series found" / `No results for "{q}" on this source.` / "This source returned no series." |

### 8.3 `/sources/[sourceId]/series/[seriesId]` — Source series detail (manga) (`SourceSeriesDetailView.tsx`)

Branches on `useIsNovelSource`: undefined → skeleton; novel → Novel series page (§10.2); manga → this screen. `?chapter=` (novel only) focuses a chapter.
API: `GET /sources/{s}/series/{id}`, `GET /sources/{s}/series/{id}/chapters`, `GET /reader/progress/series?source=&series=` (server progress, merged with local `mm.source-progress`), follow index `GET /library/series?per_page=…`, `POST /library/follow`, `DELETE /library/follow/{id}`. Prefetches the first 5 chapters' reader payloads (`GET /reader/chapter/manifest`) and any chapter on hover-intent / focus.

| # | Element | Details |
|---|---|---|
| SS1 | Back link | "← Back to source" (44 px tall on touch). |
| SS2 | Poster card | 2:3 cover, max 200 px centred on phones, 220 px sticky column on `lg`. |
| SS3 | Title | Display 3xl/4xl. |
| SS4 | Author / Artist lines | "Author: …", "Artist: …". |
| SS5 | Status badge | Primary Badge, capitalised (ongoing/completed…). |
| SS6 | Genre chips | Badge links → `/sources/{s}?genre={g}` (filters that source's catalogue). |
| SS7 | Description | Muted paragraph, leading 6. |
| SS8 | Primary CTA | Gradient pill "Read Online" (start) / "Continue" (resume at page) → `/reader/{s}/{series}/{chapter}?page=`. Hover/focus prefetches that chapter. |
| SS9 | Caught up | Disabled pill "All caught up". |
| SS10 | Read all | Ghost pill "Read all" (`title="Every chapter in one continuous scroll"`) → `/read-all/{s}/{series}?from=`. Only with >1 chapter. |
| SS11 | Follow toggle | Secondary "Follow" / ghost "Unfollow" ("Following…" / "Unfollowing…"). |
| SS12 | Follow feedback | "Following {title}. New chapters will notify you." / "Unfollowed {title}." / error. |
| SS13 | Chapters card header | "Chapters" title, Download trigger ("{n} of {total} downloaded" + secondary CloudDownload "Download"), sort segmented "Newest" / "Oldest" (by chapter number, nulls last; not persisted here). |
| SS14 | Chapter row | Primary label ("Chapter 12" or title), secondary de-duplicated title, progress line ("x/y pages" in primary when reading, "N pages", "Read"), upload date, SavedChapterMark, trailing "Read" pseudo-button (hover fill). Completed rows dimmed (`bg-void/40`, text fg/50). Row link → reader. |
| SS15 | Row in select mode | ChapterCheckbox, click/Shift-click to pick, saved chapters disabled. |
| SS16 | Chapter download bar | Inside the card footer (see §12.2). |
| SS17 | Chapter list states | Skeleton 8 rows; offline "The chapter list needs a connection to load."; error "Couldn't load the chapter list" + "Try again"; unavailable "Chapters didn't come through" / "This source lists {n} chapters for this series but returned none just now — usually the source, not you." + "Try again"; empty BookX "No chapters yet" / "This source has not published any chapters for this series." + "Back to source". |
| SS18 | Page states | Skeleton (back bar, poster, title/meta/genre/desc bars, CTA pills, chapter rows); offline "This series page needs a connection to load."; error "Couldn't load this series" / "The source did not answer." + "Try again" + "Back to source". |

## 9. Manga / manhwa reader

Two routes share one reader (`ChapterReader.tsx` + `ReaderControls.tsx` + `ContinuousStrip.tsx` / `PagedView.tsx`):

- `/reader/[sourceId]/[seriesKey]/[...chapterKey]?page=&at=` — chapter reader (`SourceReader`). Entered from every chapter row, Continue buttons, continue-reading cards, history, notifications, bookmarks, downloads, statistics sessions.
- `/read-all/[sourceId]/[seriesKey]?from=&page=&at=` — whole series as one scroll (`ReadAllReader`, "continuous only", shows "{n} of {total}" chapter position). Entered from "Read all" pills.

Shell behaviour: sidebar hidden below 500 px viewport height, topbar kept (hidden in landscape phones), no bottom tabs, no profile chip, no first-run banner, no update banner, obsidian page background, gutters tinted by profile mood (`moodReaderMargin`, 7 % tint outside the 48 rem column), no route fade.

API:
- `GET /reader/chapter/manifest?source=&series=&chapter=` (page list with width/height, prev/next keys) — the strip loads a window of chapters (neighbours) and prefetches the next chapter.
- `POST /reader/chapters/manifest {source_id, series_key, chapter_keys[]}` — batch manifests for Read all and bulk downloads.
- `POST /reader/progress {source_id, series_key, chapter_key, chapter_number, last_page, page_count, scroll_offset_px, is_completed, time_spent_seconds}` — debounced 500 ms as the visible page changes; also mirrored to local `mm.source-progress`.
- `POST /reader/bookmark {…anchor_index, anchor_fraction, anchor_total, media_type:"manga"}`.
- Page images: `GET {apiBase}/…` proxied URLs with a width parameter sized to the column (`page-url.ts`).
- Offline save (control top-right): service-worker messages, see §12.

### 9.1 Reader states

| # | State | UI |
|---|---|---|
| RD1 | Loading chapter | 3 stacked 2:3 page skeletons (max-w-md) + "Loading chapter…". |
| RD2 | Error | Danger message, primary "Try again", outline "Go to series". Read-all list failure copy: "This series' chapter list didn't come through, so there is nothing to read through." |
| RD3 | No pages | "This chapter has no pages." |
| RD4 | Broken page | Inside the page box: ImageOff, "Failed to load page", outline "Retry" (remounts the image). |
| RD5 | Page placeholder | Box sized from manifest aspect (or 800 px × unknown aspect) before the image loads. |

### 9.2 Reading surface

| # | Element | Details |
|---|---|---|
| RD6 | Continuous strip (default mode, "Strip") | Virtualised vertical column, max width 48 rem, pages seamless (no gap unless Page gap on: `pb-2`). Renders chapters within a radius of 2 around the active one; images preloaded 5 ahead. `pb-28` bottom padding for the control bar. |
| RD7 | Chapter divider (inside the strip) | Hairline — "CHAPTER N" (11 px uppercase, tracking .22em) — hairline, between chapters. |
| RD8 | Strip head card | At the very top when a previous chapter exists: glass pill "↑ {Ch N}" / "Previous chapter" + "· keep scrolling up"; "Loading {label}…" while loading. Also loads by over-scrolling up 140 px at the top (wheel). |
| RD9 | Strip tail | Loading next: pulsing dot + "{Ch N} is on its way…" / "Loading the next chapter…". Next failed: glass end card (`reader-end-card-enter` animation) with label, danger error, "Try again", "Open it on its own →". End of series: "That is everything this source has published so far." |
| RD10 | Paged view ("Single" / "Double") | Fit-to-stage page(s), 8 px spread gap, RTL spreads mirror display order, fit width / height / original, zoom 50–300 %, wheel zoom with Ctrl, optional page-turn fade (`reader-page-transition-enter`), preloads 3 ahead. |
| RD11 | Tap zones | Left 28 % / centre / right 28 % of the reading surface. Default paged: left = previous (next in RTL), centre = toggle controls, right = next. Default continuous: all three toggle chrome. User-configurable (see RD35). A tap pauses auto-scroll. |
| RD12 | Page counter pill | Fixed top-centre, mono "{page} / {total}" in primary, flat glass. Visible only while the chrome is hidden and cinema is off. |
| RD13 | Offline download control | Fixed top-right glass pill, fades with chrome. States: "Download" (CloudDownload) → saving "{saved}/{total} · {pct}% ×" (click cancels) → "Downloaded" (Check, success) → click → "Remove download?" confirm (auto-reverts after 4 s) → removed. Warn states: "Save again" (stale) / "Resume {saved}/{total}" (incomplete) with TriangleAlert. Hidden when downloads are unsupported or no profile. |
| RD14 | Night dimmer overlay | Fixed full-screen `bg` layer at opacity 0–0.92, under all chrome. |
| RD15 | Warmth overlay | Fixed full-screen primary layer at opacity warmth×0.55 (warmth 0–0.7). |
| RD16 | Bookmark notice toast | Fixed top-centre pill (top 80 px): "Saved this spot." (BookmarkCheck), "Couldn't save that spot." (TriangleAlert, danger), "That page is gone from this chapter — opened at the nearest one." (moved, auto-hides after 5.2 s). |
| RD17 | Wheel-zoom arming | In continuous mode, holding Ctrl/⌘ turns the wheel into zoom; plain wheel always scrolls. |

### 9.3 Chrome auto-hide and cinema
- Bottom control bar slides down + fades (300 ms, `invisible` when hidden so it leaves the tab order). Hides on downward scroll > 24 px; returns on upward scroll, pointer in the bottom 120 px / top 80 px band, any key, Tab focus into the chrome, or a centre tap. The settings sheet closes when chrome hides.
- **Cinema mode** (setting, `c` key, sheet toggle): all chrome hides after 3 s idle; tap / pointer move / `c` brings it back; Esc exits cinema before leaving the reader. The page counter pill is suppressed in cinema. Reduced motion removes the transitions.
- **Auto-scroll** (continuous only): speed 1–10 → 20–220 px/s, `p` toggles, any manual scroll or tap pauses, stops at the end, never auto-starts under reduced motion.
- **Fullscreen** (`f`, bar button, sheet button) via the Fullscreen API when supported.

### 9.4 Bottom control bar (glass panel, max 768 px, bottom safe-area padding)

| # | Element | Details |
|---|---|---|
| RD18 | Chapter title | Truncated semibold ("Chapter 12"); Read-all adds mono "{n} of {total}". |
| RD19 | Page line | Mono primary "Page {n} / {total} · {pct}%". |
| RD20 | Series link | BookOpen "Series" (`title="Go to series page (S)"`), exits fullscreen then navigates to the series page. |
| RD21 | Scrub bar | 6 px track + primary fill with glow + 14 px thumb; transparent native range on top (keyboard accessible, `aria-valuetext="Page n of N"`), RTL-aware; disabled for 1-page chapters. |
| RD22 | Jump-to-page input | 56 × 32 mono numeric field (placeholder = current page) + "/ {total}"; Enter jumps, Esc clears. |
| RD23 | Prev chapter | ChevronLeft "Prev" (disabled 30 % when none). In continuous mode scrolls to the loaded previous chapter instead of navigating. |
| RD24 | Next chapter | "Next" ChevronRight, `title` = next chapter label. |
| RD25 | Bookmark | Bookmark icon "Save" (`title="Bookmark this spot (B)"`), disabled while pending. |
| RD26 | Auto-scroll play/pause | 36 px icon button (continuous only), active tint when playing. |
| RD27 | Fullscreen toggle | Maximize / Minimize icon button (when supported). |
| RD28 | Settings gear | Settings2 icon button, `aria-pressed`, opens the settings sheet. |

### 9.5 Reader settings sheet (bottom sheet, `role="dialog"`, max 768 px, 75 vh scroll, rounded-t-3xl, 300 ms slide; scrim `black/40` closes)

| # | Control | Options / range | Persistence |
|---|---|---|---|
| RD29 | Close (X) | — | — |
| RD30 | Layout segmented | Single (Square) / Double (Columns2) / Strip (ScrollText). Hidden in Read all. | per series, `mm.reader-preferences[{source}:{series}].readingMode` (default `continuous`) |
| RD31 | Direction segmented | LTR (ArrowLeftRight, "Left to right — webtoons and western comics") / RTL (ArrowRightLeft, "Right to left — manga") | per series `.direction` (default `ltr`) |
| RD32 | Fit segmented | Width / Height / Original (Height and Original disabled in Strip with explanatory titles) | per series `.fitMode` (default `width`) |
| RD33 | Zoom stepper | − / "{pct}%" reset (RotateCcw) / +; 0.5–3.0 step 0.1; hint "Hold Ctrl (or ⌘) while scrolling to zoom; scrolling on its own always scrolls." | per series `.zoom` (default 1) |
| RD34 | Page gap toggle | Rows3 "On/Off" (continuous only) | profile `mm.reader-settings.pageGap` (default off) |
| RD35 | Cinema mode toggle | Film "On/Off" + "Hides all controls after a few idle seconds. Press C, or tap to bring them back." | profile `.cinema` (default from design preset) |
| RD36 | Page transition toggle | Sparkles "On/Off" + "A subtle fade between page turns." (paged only) | profile `.pageTransition` (default off) |
| RD37 | Auto-scroll block | Play/Pause button + "Scrolls the strip for you at the speed below. Press P, tap anywhere, or scroll manually to pause." + Speed slider 1–10 step 1 with value; reduced-motion note. (continuous only) | per series `.autoScrollSpeed` (default 5) |
| RD38 | Brightness slider | SunDim, 0–0.92 dimmer shown as "{100…0}%" | profile `.dimmer` (default 0) |
| RD39 | Warmth slider | Flame, 0–0.7 shown as "{0…100}%" | profile `.warmth` (default 0) |
| RD40 | Tap zones | Hand icon, helper "What each side of the page does when tapped. Mirrors automatically for a right-to-left series until you set your own." Three segmented rows Left / Center / Right, each Previous (ChevronLeft) / Toggle (Hand) / Next (ChevronRight). | profile `.tapZones` (default null = auto) |
| RD41 | Fullscreen button | "Fullscreen" / "Exit fullscreen". | — |
| RD42 | Shortcuts button | Keyboard "Shortcuts" → opens the `?` dialog. | — |

Reader keyboard shortcuts: see §2.9 (19 bindings, group "Reader"). Escape order: close shortcuts dialog → leave fullscreen → leave cinema → go to series page.

Local position memory: per chapter `{page, offset}` written 250 ms after scroll stops and on unmount (`scroll-storage.ts`), restored on re-entry unless `?page=`/`?at=` is given.

Gestures today: vertical scroll, tap zones, Ctrl+wheel zoom, top over-scroll to load previous chapter. **No swipe/pinch handlers** (browser-native pinch only).

## 10. Novel screens

Novels exist only when the server reports `novels_enabled` (bootstrap status) **and** the source's `content_kind` is `novel`. In Novels mode every list swaps poster grids for the book shelf.

### 10.1 Novel shelf component (`NovelShelf.tsx`, `BookPlate.tsx`) — used on `/library`, `/library/browse`, `/sources/[id]` for novel sources

| # | Element | Details |
|---|---|---|
| NS1 | Shelf list | `<ul>` with hairline dividers top/bottom and between rows. |
| NS2 | Shelf row | Book plate 48 × 68 px (square-cornered, 1 px border; BookOpen placeholder when no cover), title in the book serif (`font-book`, lg, hover primary), meta line "{author} · {n} chapters · {status}", 2-line blurb (serif, muted), genres line (xs uppercase, tracking .14em, "·"-joined), optional note (read state). Whole row links to the source series page. |
| NS3 | Row in select mode | Row becomes a `role="checkbox"` button with a 20 px check square; selected row tinted primary 7 %. Shift-click range. |
| NS4 | Skeleton | 8 rows of plate + 3 bars. |
| NS5 | Empty | SearchX + caller-supplied title/description/action (defaults "Nothing on this shelf" / "Nothing here yet."). |
| NS6 | Error | "Couldn't load these books" + "Try again". |

### 10.2 `/sources/[sourceId]/series/[seriesId]` for novel sources — Book front matter + contents (`NovelSeriesDetailView.tsx`)

Entered from shelf rows, novel reader running head ("Back to the book", Contents icon → `?chapter={key}`), library shelf, world cards.
API: `GET /sources/{s}/series/{id}`, `GET /sources/{s}/series/{id}/chapters`, `GET /reader/progress/series`, follow/unfollow, `POST /novels/chapters {chapter_keys[3]}` (prefetch opening chapters), cached word counts from the novels query cache.

| # | Element | Details |
|---|---|---|
| NB1 | Back link | "← Back to source". |
| NB2 | Book plate | 144 × 208 px (168 × 248 on `sm`), right column on desktop. |
| NB3 | Title | Book serif 2rem/2.5rem, weight normal, leading 1.15. |
| NB4 | Byline | Italic serif "by {author}". |
| NB5 | Rule | 56 px hairline. |
| NB6 | Facts row | "{n} chapters", "≈ {n}k words", "≈ {n} h", status. |
| NB7 | Estimate note | "Length estimated from {n} chapter(s) read so far." |
| NB8 | Genre links | xs uppercase tracking .16em, each → `/sources/{s}?genre=`. Up to 24. |
| NB9 | Blurb | Serif 17 px, leading 1.75, max 62ch. |
| NB10 | Primary CTA | Gradient pill "Start reading" / "Continue reading" → `/novels/{s}/{k}/{chapter}?page={bucket}`; "All caught up" disabled. |
| NB11 | Library toggle | Secondary "Add to library" / ghost "In your library" ("Adding…" / "Removing…"). Feedback: "Added {title} to your library. New chapters will notify you." / "Removed {title} from your library." |
| NB12 | Download book | Ghost CloudDownload "Download book" + mono count of unsaved chapters (hidden when all saved or while running; disabled without a profile). |
| NB13 | Contents header | "Contents" (serif xl), "Pick chapters" trigger (download picker), Go-to field, order toggle "First → last" / "Last → first" (uppercase text buttons). Default order oldest-first. |
| NB14 | Go-to-chapter field | 144 px input "Go to chapter" (`inputMode=decimal`), Enter jumps to the first match, Esc clears. Match list below: up to 12 buttons "{title}" + "row {n}", "and {n} more"; "Type a chapter number."; "No chapter {n} in this book." |
| NB15 | Windowed list | Shows 400 chapters around the focus; "Show earlier chapters {n}" (ghost) above, "Show more chapters {n}" (secondary) below. Focused chapter (`?chapter=` or go-to) scrolls to centre and is tinted primary 7 % (`aria-current="location"`). |
| NB16 | TOC row | Right-aligned ordinal (serif, tabular, 40 px column; "·" when none), title (serif 15.6 px; dimmed to 45 % when read), SavedChapterMark, right column "{pct}%" in primary (reading) or "Read", and chapter length ("{n} min" / words). |
| NB17 | TOC row select mode | ChapterCheckbox, click / Shift-click picks. |
| NB18 | Download bar | ChapterDownloadBar with helpers "Next 10", "All unread", "Whole book". |
| NB19 | States | Front-matter skeleton; offline "This book needs a connection to load."; error "Couldn't load this book" + "Back to source"; contents: 10-row skeleton, offline "The contents need a connection to load.", error "Couldn't load the contents", unavailable "Contents didn't come through", empty BookX "No chapters yet" / "This source has not published any chapters for this book." |

### 10.3 `/novels/[sourceId]/[seriesKey]/[...chapterKey]?page=&para=&at=` — Novel reader (`NovelReader.tsx`, `NovelChapterView.tsx`)

Immersive: no topbar, no profile chip, no first-run banner, no bottom tabs, sidebar dropped below 500 px viewport height; the page paints its own reading palette edge to edge. Unlike the manga reader, the new-chapters banner (G39) is not suppressed here and can float over the text.
API: `GET /novels/chapter?source=&series=&chapter=` (paragraphs, word count, prev/next), `GET /novels/attribution` (speaker spans, cast, narrator), `GET /novels/audio` (availability, total_ms, per-segment timing), `GET /novels/audio/file?…&format=` (blob, on Play), `GET /novels/voices` (when the cast panel opens), `GET /novels/voices/sample?voice=&format=` (preview blob), `POST /novels/cast {name, voice_id}`, `POST /novels/narrator {voice_id}`, `POST /reader/progress` (bucket-based, debounced 500 ms, flushed on leave; `is_completed` on seamless next), `POST /reader/bookmark` (paragraph anchor), `GET /sources/{s}/series/{k}` (series title). Next chapter prefetched.

Running head (sticky, painted in the reading palette):

| # | Element | Details |
|---|---|---|
| NR1 | Back to the book | ArrowLeft icon button (32 px, 44 px touch) → series page. |
| NR2 | Running title | "{SERIES} · {CHAPTER N}" uppercase 11 px tracking .18em, truncated. |
| NR3 | Percent readout | "{n}%" tabular. |
| NR4 | Contents | ListOrdered icon → series page `?chapter={key}`. |
| NR5 | Bookmark | Bookmark / BookmarkCheck (just saved) icon, `title="Bookmark this spot (B)"`. |
| NR6 | Type & page settings | Type icon button with border when open → NovelTypePanel popover. |
| NR7 | Progress hairline | 1 px track, muted fill = reading %, 150 ms width transition. |

Chapter body:

| # | Element | Details |
|---|---|---|
| NR8 | Chapter header | Eyebrow "CHAPTER N" (0.6875em, tracking .22em), title (1.55em), 56 px rule. |
| NR9 | Audio player (when TTS exists) | Bordered row: 36 px round play button ("▶" / "❚❚" / "…" loading / "!" failed; label "Listen to this chapter"), range scrubber (position), mono "m:ss / m:ss", speed select 0.75× 1× 1.25× 1.5× 1.75× 2×. Plays a fetched blob. |
| NR10 | Follow-along highlight | While audio plays, the current segment is highlighted and scrolled into view. |
| NR11 | Paragraphs | Measure 48–88ch (default 68), size 15–26 px (19), line height 1.4–2.1 (1.75), serif (Iowan Old Style/Palatino/Charter/Georgia stack) or sans (system-ui). First paragraph gets a 3.1em drop cap; subsequent paragraphs indent 1.3em; scene breaks centred with 0.5em tracking. |
| NR12 | Speaker tint runs | Attributed dialogue gets a per-speaker hue background `hsl(h 70% 50% / .16)` with a 1 px underline `hsl(h 60% 45% / .55)`. |
| NR13 | "Voices ({n})" / "Hide voices" link | Right-aligned under the text when a cast or narrator exists. |
| NR14 | Cast panel | "VOICES IN THIS CHAPTER" + Close; error line; narrator note "Narrated by {name} — their own lines are read in the narrator's voice, because they are the same person."; "Narration is read by {voice|the default voice} — change" link → voice picker; per-character rows: hue swatch (dashed when unhued), name, "{voice|Automatic} · {lines}" button (or "{n} lines · Automatic" read-only); empty "Nobody else was identified with enough confidence to be given a voice, so this chapter is read by the narrator throughout." |
| NR15 | Voice picker (inline) | "A VOICE FOR {NAME}" + Done; helper "Press a name to hear it introduce itself. Chapters already rendered keep the voice they were made with until they are rendered again."; "Automatic voice" row ("The book's default narration voice" / "Assigned automatically, not pinned"); groups "Male" / "Female" of the named voices (31 on the server), each row: "▸ {name}" (click previews the sample, "❚❚" while playing), "{character} · {pitch} Hz" or "No preview available", "Use" / "Chosen" button. |
| NR16 | End matter | 96 px rule, "END OF CHAPTER N", length line, Next card ("NEXT" eyebrow + "Chapter N+1", ChevronRight; seamless in-place advance), or "You have reached the last chapter this source has published."; links "Previous chapter", "Back to the book". |
| NR17 | Seamless next | Wheel over-scroll ≥ 140 px at the bottom, `l`, or the Next card: marks the chapter complete, swaps in the next chapter at the top (URL replaced, no navigation). |
| NR18 | Bookmark notice | Top pill in the reading palette: "Saved this spot." / "Couldn't save that spot." / "The text here changed — opened at the nearest paragraph." (5.2 s). |
| NR19 | States | Skeleton (12 text bars at varied widths in the palette); offline "This chapter needs a connection to load."; error "Couldn't load this chapter" + "Back to the book"; empty "This chapter came through empty" / "The source answered, but with no text in it — usually a page that has been pulled or is still being published." |

NovelTypePanel (popover under the Type button, 352 px, painted in the palette; Esc or outside click closes):

| # | Control | Range / options | Persistence |
|---|---|---|---|
| NT1 | Text size stepper | 15–26 px, step 1 (−/+ disabled at bounds) | per book `mm.novel-preferences[{source}:{series}].fontSize` |
| NT2 | Line spacing stepper | 1.40–2.10, step 0.05 | per book `.lineHeight` |
| NT3 | Line width stepper | 48–88 ch, step 2 | per book `.measure` |
| NT4 | Typeface | "Serif" / "Sans" buttons rendered in their own face | per book `.fontFamily` (default serif) |
| NT5 | Page: "Follow site theme" | shows "{theme label} · {light|dark}" | profile `mm.novel-settings.palette = "site"` |
| NT6 | Page: Light swatches | "Aa" 36 px tiles: Paper `#F5F1E8`, Sepia `#F4ECD8`, Solarized light `#FDF6E3`, Soft grey `#E9E9E7`, Cream `#FBF7EF`, Dawn `#FAF4ED` | profile `.palette` |
| NT7 | Page: Dark swatches | Dusk `#1E1B18`, Midnight `#0F1419`, True black `#000000`, Solarized dark `#002B36`, Forest `#1E2326`, Rosé Pine `#191724` | profile `.palette` (default: Paper if site is light, Dusk if dark) |

Novel shortcuts: `h` / `l` chapters, `=`/`+` / `-` text size, `t` type panel, `b` bookmark, `Esc` (close panel, else back to the book).

## 11. `/updates` — Updates (`UpdatesView.tsx`)

Entered from sidebar "Updates", topbar bell, More → Updates, the new-chapters banner.
API: `GET /updates/settings`, `GET /updates/notifications?limit=100` (60 s poll), `GET /updates/runs` (admin), `POST /updates/check {}`, `PATCH /updates/notifications/{id}/read`, `POST /updates/notifications/read-all {content_kind?}`.

| # | Element | Details |
|---|---|---|
| UP1 | Hero heading | "Updates" + "New chapters found for the series you follow." |
| UP2 | "Check now" | Gradient pill (Search icon) → `POST /updates/check` (triggers a run for all followed series). Disabled while busy. No progress feedback beyond the disabled state. |
| UP3 | Error banner | Danger box with settings/runs API error. |
| UP4 | Settings summary card | Link → `/settings`: Bell tile, "Update & notification settings", "{Checking|Not checking} every {n} min · notifications {on|off} · last check {datetime}", ChevronRight. (Non-admins land on a settings page without the Notifications tab.) |
| UP5 | Notifications card header | "Notifications" + secondary "Mark all read" / "Mark all manga read" / "Mark all novels read" (disabled when all read). |
| UP6 | Notification row | Bordered card (70 % opacity when read): "{series title} · {chapter title}", "{source_id} · {created datetime}", "Read" button-link (→ reader/novel reader), ghost "Mark read" (unread only). |
| UP7 | States | 3 × 64 px skeleton; offline "Updates need a connection to check."; error "Couldn't load notifications"; empty BellOff "No new chapters yet" / "Follow a series and this fills in the moment a new chapter is found." + "Browse Sources". |
| UP8 | "Recent checks" card (admin) | Rows "{trigger} · {status} · {n} series · {n} new" + started datetime; 3 skeleton bars; "No check runs yet." |

## 12. Downloads (offline reading)

### 12.1 `/downloads` — Downloads (`DownloadsView.tsx`)

Mobile tab 4, sidebar "Downloads", OfflineState CTAs, fallback page link. Data lives in the service worker's Cache Storage + IndexedDB index for this browser and profile; no backend API except page/manifest fetches during saves.

| # | Element | Details |
|---|---|---|
| DL1 | Eyebrow + hero | "ON THIS DEVICE" / "Downloads" + "Chapters downloaded here are stored in this browser and open with no connection at all. They belong to the profile that downloaded them." |
| DL2 | Offline pill | WifiOff (warning) "You are offline — only saved chapters will open." |
| DL3 | Storage card | HardDrive tile, "{size} in {n} chapter(s)", "{usage} of {quota} used by this site · {free} free" (or "This browser does not report a storage quota."), gradient Progress bar, explainer "Saving stops before the last 250 MB of the quota. When it gets close, finished chapters are removed oldest-first — never one you have not read, and never the one you have open." |
| DL4 | Persistent-storage control | Success pill "Storage protected" (ShieldCheck) or secondary "Ask to protect storage" (`navigator.storage.persist()`). |
| DL5 | Retention card | "Delete finished chapters after" + explainer; chip group "2 days" / "7 days" / "30 days" / "Never" (`aria-pressed`) → service-worker `set-retention`. |
| DL6 | Series group card | Header: series title link (→ series page), mono size, "Remove series" → inline confirm "Remove all {n}?" → "Removing…". |
| DL7 | Saved chapter row | Title link (→ reader or novel reader, works offline), status line coloured by tone: "{n} pages · {size}" / "Saved · {size}" / "Saving {x}/{y}" (primary) / "Incomplete — {x}/{y} pages" / "Paused — device is full" / "Pages changed on the server — save again" (warning) + " · Deletes in about {n} days/hours / within the hour / next time you open the app" + " · open now, kept". Progress bar while saving. Trash2 icon button (Loader2 while removing), `aria-label="Remove {title} from this device"`. |
| DL8 | Footer actions | "Remove all downloads" → inline confirm "Delete everything saved?" (danger); ghost "Reset offline storage" (RotateCcw; unregisters the worker, clears every cache) + explainer. |
| DL9 | States | Unsupported (no SW / insecure origin): error "Downloads are unavailable here"; no profile: CloudOff "No profile selected"; pending: spinner "Checking what is stored…"; empty: CloudOff "Nothing downloaded yet" / "No series downloaded yet" / "No novels downloaded yet" + explainer + "Go to library". |

Filtered by content mode when novels are enabled.

### 12.2 Chapter download picker (on every series page: §7.3 SD14–17, §8.3 SS13–16, §10.2 NB12–18)

| # | Element | Details |
|---|---|---|
| DP1 | Trigger | "{n} of {total} downloaded" + secondary CloudDownload "Download" (novels: "Pick chapters"). Enters select mode. |
| DP2 | Row checkbox | 20 px square; already-saved rows disabled. Click toggles, Shift-click selects a range. |
| DP3 | Download bar (sticky bottom-4 glass) | "Select chapters to download" / "{n} selected · {k} already downloaded"; helper chips with counts: "Next 10", "All unread", "Whole book" (novels); ghost X "Done"; primary CloudDownload "Download {n}". |
| DP4 | Running state | Spinner "Downloading {i} of {n}", thin Progress, ghost "Stop". |
| DP5 | Summary line | "{n} chapters downloaded." / "Nothing to download — those chapters are already saved." / "{a} of {b} downloaded, {c} with missing pages, {d} failed." / "Out of room. … Only {size} is free. Remove some downloads and run it again." / "Stopped. …" + "Manage downloads" link + "Dismiss". Warning tone for problems. |
| DP6 | No-profile note | "Downloads belong to a reading profile. Choose one to save chapters here." |
| DP7 | Per-row state mark (`SavedChapterMark`) | Icons with tooltips: queued (CircleDashed, "Queued to download"), saving (Loader2 spin, primary), saved (Check, success, "Downloaded — opens with no connection"), incomplete (TriangleAlert, "Incomplete — some pages are missing"), paused (PauseCircle, "Paused — this browser is out of room"), stale (CloudDownload, "The source changed these pages — download it again"). |

Service-worker protocol messages (the "API" of downloads): `mm-offline/set-scope`, `get-state`, `save-chapter`, `cancel-save`, `remove-chapter`, `mark-opened`, `mark-finished`, `chapter-closed`, `sweep`, `set-retention`, `clear-scope`, `skip-waiting`; the worker pushes `mm-offline/state`.

## 13. `/library/bookmarks` — Bookmarks (`BookmarksView.tsx`)

API: `GET /reader/bookmarks`, `DELETE /reader/bookmarks/{id}`. Created from the readers via `POST /reader/bookmark`.

| # | Element | Details |
|---|---|---|
| BM1 | Title | "Bookmarks" + "Jump back to the exact spot you saved, or remove ones you no longer need." |
| BM2 | Card "Saved places" | Contains the list. |
| BM3 | Bookmark row | Link: series title (or key), "{Chapter N} · {62% in | Page 7 | Paragraph 118}", novel snippet (italic, 2 lines), stale note "The text here changed — this opens at the nearest spot.", note text, saved date. Opens the reader with `?page=&at=` (manga) or `?para=&at=` (novel). |
| BM4 | Remove button | Ghost "Remove" / "Removing…", `aria-label="Remove bookmark in {series}"`. No confirm, no undo. |
| BM5 | States | 5 × 96 px skeleton; offline "Bookmarks need a connection to load."; error "Couldn't load bookmarks"; empty Bookmark "No bookmarks yet" / "Press B while reading — or use the bookmark control — to save the exact spot you are on." + "Go to library". |

## 14. `/ocr` — OCR dialogue search (`OcrSearchView.tsx`)

Manga only. Sidebar "OCR Search" (hidden in Novels mode), More → OCR Search.
API: `GET /ocr/search?q=&limit=20` (debounced 300 ms). (`GET /ocr/chapter` exists in the client but is unused.)

| # | Element | Details |
|---|---|---|
| OC1 | Hero | "OCR Search" + "Search extracted dialogue across the series you follow, and jump straight to the chapter it appears in." |
| OC2 | Section label | "Dialogue search". |
| OC3 | Search input | `type=search`, leading Search icon, placeholder "Search dialogue, e.g. “I will protect you”", trailing spinner while fetching. |
| OC4 | Idle | ScanText "Search the dialogue you remember" / "Type at least one word…". |
| OC5 | Result card | Link "{series title} — {chapter key}" → reader; snippet with `<mark>` highlights (primary 20 % background); "{n} words · {engine}". |
| OC6 | Overflow note | "Showing the first {n} of {total} matches. Refine your query to narrow results." |
| OC7 | States | 3 × 80 px skeleton; offline "Dialogue search needs a connection to run."; error "Search failed"; empty "No dialogue matches" / `Nothing found for "{q}" in the chapters you follow.` |
| OC8 | Novels-mode block | BookText "OCR search is for manga" / "…Switch to Manga in the sidebar to use it." + "Search novels instead" (→ `/search`). |

No result jumps to the matching page (only to the chapter start).

## 15. `/admin/status` — System status (admin) (`app/admin/status/StatusView.tsx`)

Sidebar "Status" (admin), Settings desktop card, More → System Status.
API: `GET /health` (15 s poll), `GET /updates/settings`, `GET /updates/runs`, `GET /sources/health` (30 s poll), `POST /updates/check`.

| # | Element | Details |
|---|---|---|
| AS1 | Eyebrow + hero | "ADMINISTRATION" / "System Status" + "Backend health, the update checker, per-source failures, and update runs — everything that can break quietly." |
| AS2 | Refresh all | Secondary RefreshCw "Refresh" / "Refreshing…". |
| AS3 | Summary banner | Tinted by worst state (ok / warn / down / unknown), state icon (CheckCircle2 / TriangleAlert / AlertCircle / CircleHelp), headline, bullet list of problems. |
| AS4 | Backend card | Server icon, state pill (Healthy / Warning / Down / Unknown with dot), message, facts: Name, Version (mono), Probe `GET /health`. |
| AS5 | Update checker card | Clock icon, "Check now" (secondary, "Starting…"), facts: Last run (+ relative "12 min ago"), Next run (est.) (+ "in 40 min"), Interval, Failed runs (recent) (danger when >0), server error block (mono, danger), footnote about the estimate. |
| AS6 | Recent update checks card | Up to 8 runs: status Badge (completed success / running primary / failed danger / other warning), trigger (uppercase), "{n} series · {n} new", started time, error `<pre>`. Empty note. Footnote about per-series failures. |
| AS7 | Source health card | Per-source rows: state icon, name, mono id, "demoted" warning badge, "last probe {time}", message, last error `<pre>`. Empty / error notes. Footnote about federated-search probing. |
| AS8 | Footer note | "Everything on this page is read from endpoints that already exist…" |
| AS9 | Non-admin block | ShieldAlert "Administrators only" / "System status is instance-wide configuration and health. Ask the account owner to check it for you." + "Back to home". |
| AS10 | Loading | 48 × 256 bar while `/auth/me` resolves. |

## 16. Settings → Backup & restore (admin) (`features/backup/components/BackupPanel.tsx`)

API: `GET /backup/status` (30 s poll), `GET /backup/export` (blob download, filename from Content-Disposition), `POST /backup/import` (multipart `file`), `DELETE /backup/pending`.

| # | Element | Details |
|---|---|---|
| BK1 | Panel header | DatabaseBackup tile, "Backup & restore", "Take a copy of this server's database, or put one back." |
| BK2 | Pending-restore banner | Hourglass "Restore staged" (warning) + explainer + secondary "Cancel staged restore" / "Cancelling…". |
| BK3 | Export section | Explainer (whole SQLite DB, every account), privacy note, primary Download "Export backup" / "Preparing…", "Saved {filename}", danger alert on failure. |
| BK4 | Restore section (danger-tinted box) | Explainer (replaces everything, staged until restart), hidden `.db` file input, secondary FileUp "Choose backup file", "{name} · {size}" + danger "Restore from this file…" or "No file chosen. Nothing is uploaded until you confirm."; validation errors ("isn't a .db file", "is empty"); danger alert; warning alert with the server's staged message. |
| BK5 | Restore confirm dialog | Title "Restore from “{file}”?"; danger alert with 4 bullets (replaces every account, sign-ins come from the backup, applies on next restart, nothing kept); input "Type **RESTORE** to confirm."; Cancel / danger "Restore" ("Uploading…"), disabled until the phrase matches (case-insensitive). |

## 17. Settings → Members (admin) (`features/admin/components/MembersPanel.tsx`)

API: `GET /auth/users`, `PATCH /auth/users/{id} {is_active}`, `DELETE /auth/users/{id}`.

| # | Element | Details |
|---|---|---|
| MB1 | Panel header | Users tile, "Members", "Everyone with an account on this server." |
| MB2 | Explainer | Registration is open; deactivate vs delete. |
| MB3 | Table (min 640 px, horizontal scroll) | Columns: Member (username + "Admin" primary badge + "You" badge), Status ("Active" success / "Deactivated" danger), Joined (date), Last seen (datetime), Sessions ("No sessions" / "1 session" / "{n} sessions"), Actions. Own row tinted primary 5 %; self rows have actions disabled with a `title` reason. |
| MB4 | Deactivate / Reactivate | Secondary sm, `aria-label="{verb} {username}"`. |
| MB5 | Delete | Danger sm Trash2 → confirm dialog "Delete {username}?" with danger box body, error line, Cancel / "Delete {username}" ("Deleting…"). |
| MB6 | Footer | "Only your account so far…" / "{n} other account(s)." + ghost Refresh (spins). |
| MB7 | States | 3 × 40 px skeleton; error + "Try again"; empty dashed note. |

## 18. Every user action and the call it triggers

All HTTP calls go to same-origin `/api/*` (Next rewrite → FastAPI), `credentials: include` (session cookie), and carry `X-Profile-Id: {activeProfileId}` when a profile is active. Network failure = `ApiError(0, "network_error")` → offline states. Mutations invalidate the matching TanStack Query roots.

### 18.1 Session and account

| # | Action | Where | Call |
|---|---|---|---|
| A1 | Resolve session | every load | `GET /auth/me` |
| A2 | Load public config (bootstrap / registration / invite / novels flag) | login, register, content-mode | `GET /auth/bootstrap-status` |
| A3 | Sign in | Login form | `POST /auth/login {username, password, remember}` |
| A4 | Register / create first admin | Register form, bootstrap login | `POST /auth/register {username, password, email?, display_name?, invite_code?, remember}` |
| A5 | Sign out | Account menu, command palette, Security → current session "Sign out" | `POST /auth/logout` → `/login` |
| A6 | Sign out everywhere | Security danger zone (with acknowledgement) | `POST /auth/logout-all` → `/login` |
| A7 | Change password | Security form | `POST /auth/change-password {current_password, new_password}` |
| A8 | List sessions / refresh | Security | `GET /auth/sessions` |
| A9 | Revoke a session | Security row | `DELETE /auth/sessions/{id}` |

### 18.2 Profiles

| # | Action | Where | Call |
|---|---|---|---|
| A10 | List profiles | Picker, manage page, stale check | `GET /profiles` |
| A11 | Pick profile (animated) | Picker tile | local only: store `mm.active-profile`, drop profile-scoped caches, `router.push("/")` |
| A12 | Use profile (instant) | Manage row "Use" | local only (same as A11 without animation) |
| A13 | Create profile | Picker "Add profile", manage "Add" | `POST /profiles {name, avatar_key, mood, mature_content_enabled}` |
| A14 | Edit profile | Manage pencil | `PATCH /profiles/{id} {…}` |
| A15 | Delete profile | Manage trash → confirm | `DELETE /profiles/{id}` |
| A16 | Switch profile | Topbar chip, More → Switch profile | navigate `/profiles` |

### 18.3 Preferences

| # | Action | Where | Call |
|---|---|---|---|
| A17 | Pick / hover-preview design preset | Settings → Design, command palette | local `manhwamaniacs:design-preset` + `data-preset` on `<html>` |
| A18 | Pick / filter reading palette | Settings → Appearance, command palette | local `manhwamaniacs:reading-theme` + `data-theme` + `<meta theme-color>` |
| A19 | Toggle page gap / cinema default | Settings → Reader | local `mm.reader-settings` |
| A20 | Load 18+ setting | Settings → Content | `GET /settings` |
| A21 | Enable 18+ (confirm dialog) / disable | Settings → Content | `PUT /settings {mature_content_enabled}` then invalidate `preferences, sources, library, library-discovery, bookmarks, novels, ocr, updates, reader` |
| A22 | Switch content mode Manga / Novels | Sidebar, More | local `mm.content-mode` (client-side filtering of every list) |
| A23 | Collapse / expand sidebar | Topbar button, `mod+b`, sidebar expand button | UI store only (not persisted) |
| A24 | Open command palette / shortcuts sheet | `mod+k`, `?`, topbar button, reader sheet | none (palette queries A26/A38 on type) |

### 18.4 Library

| # | Action | Where | Call |
|---|---|---|---|
| A25 | Load followed shelf / browse list | `/library`, `/library/browse`, follow index (sort=title, paged) | `GET /library/series?page&per_page&sort&search&reading_status&is_favorite` |
| A26 | Search own library (palette) | Command palette | `GET /library/search?q=&per_page=8` |
| A27 | Load continue reading | `/library` (1), `/library/browse` (12), source loading carousel (9) | `GET /library/continue-reading?limit=` |
| A28 | Open followed series | Cards, palette | `GET /library/series/{followedId}` |
| A29 | Follow | Card bell, source series "Follow", novel "Add to library" | `POST /library/follow {source_id, series_key}` |
| A30 | Unfollow | Card bell, series page, bulk bar | `DELETE /library/follow/{followedId}` |
| A31 | Favourite / unfavourite | Card star, series page, bulk bar | `PATCH /library/series/{id} {is_favorite}` |
| A32 | Set reading status | Series page select, bulk "Mark read" / "Mark unread" | `PATCH /library/series/{id} {reading_status}` |
| A33 | Toggle per-series notifications | Series page chip | `PATCH /library/series/{id} {notify}` |
| A34 | Bulk run / stop | Bulk bar | A30/A31/A32 per row, concurrency 4, abortable |
| A35 | Change sort / status chips / favourites / shelf status / search / clear filters | Browse toolbar | URL query → A25 |
| A36 | Change grid density | Browse toolbar | local `manhwamaniacs:library-density` |
| A37 | Sort chapters newest/oldest | Library series page | local `mm.chapter-sort:{source}:{series}` |
| A38 | Load history | `/library/history` | `GET /reader/history?limit=50&offset=0&collapse=series` |
| A39 | History "Next" on a finished entry | History tile | `GET /sources/{s}/series/{k}/chapters` then navigate |
| A40 | Load statistics / change range | `/library/statistics` | `GET /library/statistics?days={7|30|90}&tz_offset_minutes=` |
| A41 | Load recommendations | `/library/recommendations` | `GET /library/world/recommendations` |
| A42 | Check AI availability / quota | `/library/recommendations` | `GET /library/suggest/availability` |
| A43 | Ask for AI suggestions (text or example chip) | Suggestion box | `POST /library/world/suggest {prompt}` (≤ 120 s proxy timeout) |
| A44 | List collections | `/library/collections` | `GET /library/collections` |
| A45 | Create collection | New Collection dialog | `POST /library/collections {name, description?}` |
| A46 | Open collection | Banner card | `GET /library/collections/{id}` (+ A25 for members) |
| A47 | Edit collection | Edit dialog | `PATCH /library/collections/{id} {name?, description?}` |
| A48 | Delete collection | Delete dialog | `DELETE /library/collections/{id}` |
| A49 | Add series to collection | Add dialog row | `POST /library/collections/{id}/series {source_id, series_key}` |
| A50 | Remove series from collection | Remove dialog (inline confirm) | `DELETE /library/collections/{id}/series` body `{source_id, series_key}` |

### 18.5 Search and sources

| # | Action | Where | Call |
|---|---|---|---|
| A51 | Global search (tier 1 fast sources) | `/search` input, chips, Enter | `GET /sources/search?q=&page=1&per_page=40&tier=1` |
| A52 | Global search (tier 2 slow sources) | automatic when tier 1 returns `next_tier: 2` | `GET /sources/search?…&tier=2` |
| A53 | Retry one source | Search group "Retry" | `GET /sources/{id}/series?query=` |
| A54 | Record recent search | after a settled query ≥ 2 chars | local `manhwamaniacs:recent-searches` |
| A55 | List sources | `/sources`, palette, name lookups | `GET /sources` |
| A56 | List pins | `/sources` | `GET /sources/pins` |
| A57 | Pin / unpin a source | Source row pin toggle | `PUT /sources/pins {source_ids[]}` (full ordered replace) |
| A58 | Browse modes / genres | Source catalogue | `GET /sources/{id}/browse-modes`, `GET /sources/{id}/genres` |
| A59 | Browse / search / filter / page a source | Source catalogue (auto infinite scroll, genre select writes `?genre=`) | `GET /sources/{id}/series?page&query&sort&genre` |
| A60 | Refresh catalogue from source | Freshness "Refresh" | `GET /sources/{id}/series?…&refresh=true` |
| A61 | Retry failed page | "Couldn't load more. Retry" | next page of A59 |
| A62 | Open source series | Catalogue card, search result, world card | `GET /sources/{s}/series/{id}` + `GET …/chapters` + `GET /reader/progress/series?source=&series=` |
| A63 | Hover / focus a chapter row or Continue button (prefetch) | Source series page | `GET /reader/chapter/manifest?source=&series=&chapter=` (first 5 chapters prefetched on load) |
| A64 | Tap genre chip | Source series page | navigate `/sources/{s}?genre=` → A59 |

### 18.6 Manga reader

| # | Action | Where | Call |
|---|---|---|---|
| A65 | Open chapter / read all | Reader routes | `GET /reader/chapter/manifest` per chapter (window), `POST /reader/chapters/manifest {chapter_keys}` (read-all batches) |
| A66 | Scroll / turn page / scrub / jump to page | Reader | `POST /reader/progress {…last_page, page_count, scroll_offset_px, is_completed, time_spent_seconds}` (debounced 500 ms) + local `mm.source-progress` + local scroll position |
| A67 | Next / previous chapter | Bar, keys, strip edges | in-strip scroll or navigate; next chapter prefetched |
| A68 | Bookmark this spot | Bar "Save", `b` | `POST /reader/bookmark {source_id, series_key, chapter_key, chapter_number, media_type:"manga", anchor_index, anchor_fraction, anchor_total}` |
| A69 | Change layout / direction / fit / zoom / auto-scroll speed | Settings sheet, keys | local `mm.reader-preferences[{source}:{series}]` |
| A70 | Change page gap / cinema / page transition / brightness / warmth / tap zones | Settings sheet, `c` | local `mm.reader-settings` |
| A71 | Fullscreen, auto-scroll play/pause, show shortcuts, go to series | Bar, sheet, keys | none |
| A72 | Retry a broken page | Broken page "Retry" | refetch that image |
| A73 | Retry next chapter / open it on its own | Strip tail card | manifest refetch / navigate |

### 18.7 Novels

| # | Action | Where | Call |
|---|---|---|---|
| A74 | Open book page | Shelf row, world card | A62 + `POST /novels/chapters {chapter_keys[3]}` (prefetch opening chapters) |
| A75 | Go to chapter / widen contents window | Contents | none (client) |
| A76 | Open chapter | TOC, Continue | `GET /novels/chapter?source=&series=&chapter=`, `GET /novels/attribution`, `GET /novels/audio`, `GET /sources/{s}/series/{k}`; next chapter prefetched |
| A77 | Read / scroll | Novel reader | `POST /reader/progress {last_page: bucket, page_count: buckets, is_completed, time_spent_seconds}` (500 ms debounce, flushed on leave) |
| A78 | Seamless next chapter | Next card, `l`, bottom over-scroll | `POST /reader/progress {is_completed:true}` then A76 for the next key (URL replaced) |
| A79 | Bookmark paragraph | Running head, `b` | `POST /reader/bookmark {…media_type:"novel", anchor_index (paragraph), anchor_fraction}` |
| A80 | Change text size / spacing / width / face | Type panel, `+`/`-` | local `mm.novel-preferences[{source}:{series}]` |
| A81 | Change page palette | Type panel | local `mm.novel-settings.palette` |
| A82 | Play / pause / seek / speed chapter audio | Audio player | `GET /novels/audio/file?source=&series=&chapter=&format=` (blob on first play) |
| A83 | Open voices panel | "Voices (n)" | `GET /novels/voices` |
| A84 | Preview a voice | Voice picker row | `GET /novels/voices/sample?voice=&format=` (blob) |
| A85 | Set a character's voice | Voice picker "Use" | `POST /novels/cast {source_id, series_key, name, voice_id|null}` |
| A86 | Set the narration voice | Narrator picker "Use" | `POST /novels/narrator {source_id, series_key, voice_id|null}` |

### 18.8 Downloads (service worker, not HTTP API)

| # | Action | Where | Call |
|---|---|---|---|
| A87 | Download selected / helper / whole book | Series page picker | manifests (A63 / `POST /reader/chapters/manifest` / `POST /novels/chapters`) then SW `mm-offline/save-chapter` per chapter; images fetched and cached by the worker |
| A88 | Stop a download run | Picker bar "Stop" | SW `cancel-save` |
| A89 | Download / cancel / resume / remove the open chapter | Reader top-right control | SW `save-chapter` / `cancel-save` / `remove-chapter` |
| A90 | Remove chapter / remove series / remove all | `/downloads` | SW `remove-chapter` (×n) / `clear-scope` |
| A91 | Set retention | `/downloads` chips | SW `set-retention` |
| A92 | Ask to protect storage | `/downloads` | `navigator.storage.persist()` |
| A93 | Reset offline storage | `/downloads` | unregister worker + clear caches |
| A94 | Reload into new version | Update prompt | SW `skip-waiting` + reload |
| A95 | Housekeeping (auto) | app open, tab focus every 5 min | SW `sweep`, `registration.update()`; `mark-opened` / `mark-finished` / `chapter-closed` from the reader |

### 18.9 Updates, bookmarks, OCR

| # | Action | Where | Call |
|---|---|---|---|
| A96 | Poll unread count | Topbar bell, More | `GET /updates/notifications/unread-count` (60 s) |
| A97 | Poll unread notifications (banner) | Shell | `GET /updates/notifications?unread_only=true&limit=100` (60 s) |
| A98 | Dismiss / follow the banner | Banner | sessionStorage `mm.updates.banner.dismissedMaxId` |
| A99 | List notifications | `/updates` | `GET /updates/notifications?limit=100` |
| A100 | Check now | `/updates`, Status | `POST /updates/check {}` |
| A101 | Mark one read | Notification row | `PATCH /updates/notifications/{id}/read` |
| A102 | Mark all read (mode-scoped) | `/updates` | `POST /updates/notifications/read-all {content_kind?}` |
| A103 | Read notified chapter | Row "Read" | navigate to reader |
| A104 | List bookmarks | `/library/bookmarks` | `GET /reader/bookmarks` |
| A105 | Remove bookmark | Row "Remove" | `DELETE /reader/bookmarks/{id}` |
| A106 | OCR dialogue search | `/ocr` | `GET /ocr/search?q=&limit=20` |

### 18.10 Admin

| # | Action | Where | Call |
|---|---|---|---|
| A107 | Load / save update-checker settings | Settings → Notifications | `GET /updates/settings`, `PUT /updates/settings {enabled, check_interval_minutes, notify_enabled, check_on_startup}` |
| A108 | List update runs | `/updates` (admin), Status | `GET /updates/runs` |
| A109 | Backend health | Status (15 s poll) | `GET /health` |
| A110 | Source health | Status (30 s poll) | `GET /sources/health` |
| A111 | Refresh all status | Status | refetch A107–A110 |
| A112 | Backup status | Settings → Backup (30 s poll) | `GET /backup/status` |
| A113 | Export backup | Settings → Backup | `GET /backup/export` (blob → file save) |
| A114 | Stage restore (typed "RESTORE") | Settings → Backup | `POST /backup/import` multipart `file` |
| A115 | Cancel staged restore | Settings → Backup | `DELETE /backup/pending` |
| A116 | List members | Settings → Backup → Members | `GET /auth/users` |
| A117 | Deactivate / reactivate member | Members row | `PATCH /auth/users/{id} {is_active}` |
| A118 | Delete member | Members row → confirm | `DELETE /auth/users/{id}` |

Defined in the client but never called from any screen: `POST /reader/progress/batch`, `GET /ocr/chapter`, `GET /` (system service), `GET /library/recently-updated`, `POST /updates/followed/{id}/check` (per-series check), `GET /sources/{s}/series/{id}/chapters/{c}/reader` (legacy reader payload). Covers load from `GET /sources/{s}/series/{k}/cover?w=` or proxied `cover_url`s.

**Endpoint total: 84 distinct method+path pairs in the client, 78 reachable from UI.** Backend fields with no UI: followed-series `mature_override`, `sort_order` (the "Manual Order" sort exists but there is no reorder control), profile `sort_order`, collection `sort_order`, bookmark `note` (displayed, never editable).

## 19. Every setting key (type, options, default, scope, where edited)

Scoped local keys are stored as `{base}::u{userId}:p{profileId}` in localStorage, so every one of them is per account + profile, per browser.

### 19.1 Server-side, per profile or per account

| # | Key | Type | Options / range | Default | Scope | Edited in |
|---|---|---|---|---|---|---|
| K1 | `mature_content_enabled` (`/settings`) | bool | on / off (on requires 18+ confirm dialog) | off | profile (via `X-Profile-Id`) | Settings → Content |
| K2 | profile `name` | string | 1–30 chars | — | profile | Profile form |
| K3 | profile `avatar_key` | enum(12) | violet, cyan, rose, amber, emerald, ember, blade, phantom, arcane, lunar, star, reader | violet | profile | Profile form |
| K4 | profile `mood` | enum(7) | romantic, action, comedy, horror, slice_of_life, fantasy, default | default | profile | Profile form |
| K5 | profile `mature_content_enabled` | bool | — | off | profile | Profile form (no confirm) |
| K6 | profile `sort_order` | int | — | server | profile | **no UI** |
| K7 | followed `is_favorite` | bool | — | false | followed series | Card star, series page, bulk |
| K8 | followed `reading_status` | enum(6) | unread, reading, completed, on_hold, plan_to_read, dropped | server | followed series | Series page select, bulk |
| K9 | followed `notify` | bool | — | server default | followed series | Series page chip |
| K10 | followed `mature_override` | bool | — | — | followed series | **no UI** |
| K11 | followed `sort_order` | int | — | — | followed series | **no UI** (only "Manual Order" sort reads it) |
| K12 | collection `name` / `description` | string | — | — | collection | Collection dialogs |
| K13 | source pins | ordered string[] | installed source ids | [] | profile | `/sources` pin toggles |
| K14 | novel cast voice | voice id \| null | 31 named voices + Automatic | Automatic | series × character | Cast panel |
| K15 | novel narrator voice | voice id \| null | 31 named voices + Automatic | book default | series | Cast panel |
| K16 | login `remember` | bool | — | on | session | Login / register |
| K17 | password | string | 8–4096 chars | — | account | Security |
| K18 | member `is_active` | bool | — | true | account (admin) | Members |

### 19.2 Server-side, instance-wide (admin only)

| # | Key | Type | Options / range | Default | Edited in |
|---|---|---|---|---|---|
| K19 | `enabled` (update checker) | bool | — | server | Settings → Notifications |
| K20 | `check_interval_minutes` | int | 5–120, step 5 (server floor 5) | server | Settings → Notifications |
| K21 | `notify_enabled` | bool | — | server | Settings → Notifications |
| K22 | `check_on_startup` | bool | — | server | Settings → Notifications |
| K23 | staged restore | file | `.db` + typed "RESTORE" | none | Settings → Backup |

### 19.3 Client-side, per profile (scoped localStorage)

| # | Key | Type | Options / range | Default | Edited in |
|---|---|---|---|---|---|
| K24 | `manhwamaniacs:design-preset` | enum(5) | signature, flat (Matte), compact, editorial, cinema | signature | Settings → Design, palette |
| K25 | `manhwamaniacs:reading-theme` | enum(42) | eclipse (`dark`), midnight, sepia, daylight (`light`) + 38 generated | github-dark | Settings → Appearance, palette |
| K26 | `manhwamaniacs:library-density` | enum(3) | comfortable, compact, list | from preset (comfortable / compact / list) | Browse toolbar |
| K27 | `manhwamaniacs:recent-searches` | string[] | max 4, min 2 chars each | [] | automatic from `/search` |
| K28 | `mm.content-mode` | enum(2) | manga, novel (forced manga when novels disabled) | manga | Sidebar, More |
| K29 | `mm.reader-settings.pageGap` | bool | — | false | Settings → Reader, reader sheet |
| K30 | `mm.reader-settings.cinema` | bool | — | preset's `readerCinema` (true only for Cinema preset) | Settings → Reader, reader sheet, `c` |
| K31 | `mm.reader-settings.dimmer` | float | 0–0.92 step 0.01 (shown as Brightness 100→0 %) | 0 | Reader sheet |
| K32 | `mm.reader-settings.warmth` | float | 0–0.7 step 0.01 (shown 0→100 %) | 0 | Reader sheet |
| K33 | `mm.reader-settings.pageTransition` | bool | — | false | Reader sheet (paged modes) |
| K34 | `mm.reader-settings.tapZones` | {left,center,right} each advance \| retreat \| toggle, or null | 27 combinations + auto | null (auto: paged = turn/toggle/turn mirrored for RTL; strip = all toggle) | Reader sheet |
| K35 | `mm.reader-preferences[{source}:{series}].readingMode` | enum(3) | single, double, continuous | continuous | Reader sheet (Layout) |
| K36 | `….fitMode` | enum(3) | width, height, original | width | Reader sheet (Fit) |
| K37 | `….direction` | enum(2) | ltr, rtl | ltr | Reader sheet (Direction) |
| K38 | `….zoom` | float | 0.5–3.0 step 0.1 | 1.0 | Reader sheet, `+ - 0`, Ctrl+wheel |
| K39 | `….autoScrollSpeed` | int | 1–10 (20–220 px/s) | 5 | Reader sheet |
| K40 | `mm.novel-settings.palette` | enum(14) | site, paper, sepia, solarized-light, soft-grey, cream, dawn, dusk, midnight, black, solarized-dark, forest, rose-pine, or null | null → Paper (light site) / Dusk (dark site) | Novel type panel |
| K41 | `mm.novel-preferences[{source}:{series}].fontSize` | int px | 15–26 step 1 | 19 | Type panel, `+ -` |
| K42 | `….lineHeight` | float | 1.40–2.10 step 0.05 | 1.75 | Type panel |
| K43 | `….measure` | int ch | 48–88 step 2 | 68 | Type panel |
| K44 | `….fontFamily` | enum(2) | serif, sans | serif | Type panel |
| K45 | `mm.chapter-sort:{source}:{series}` | enum(2) | newest, oldest | newest | Library series page |
| K46 | `mm.source-progress` | map | `{source}:{series}:{chapter}` → page, pageCount, completed | {} | automatic (reader) |
| K47 | `manhwamaniacs-reader-scroll:{chapter}` | `p:{page}:{offset}` | capped at 500 entries (LRU order key) | — | automatic (reader) |

### 19.4 Device-global and other storage

| # | Key | Type | Notes |
|---|---|---|---|
| K48 | `mm.active-profile` (localStorage, zustand persist) | `{activeProfile:{id,name,avatar_key,mood}, ownerUserId}` | Cleared on profile errors; not scoped (it chooses the scope). |
| K49 | `mm.updates.banner.dismissedMaxId` (sessionStorage) | int | Hides the new-chapters banner until a newer notification. |
| K50 | Offline retention (service-worker IndexedDB) | enum(4) | 2 days, 7 days, 30 days, Never. Per profile scope. |
| K51 | Persistent storage grant | browser permission | `/downloads` "Ask to protect storage". |

### 19.5 Screen state that is NOT persisted (candidates for the redesign to remember)
Sidebar collapsed, statistics range (7/30/90), collections sort and search, sources list filter chip and text, source catalogue browse mode and search (genre is in the URL), source/novel chapter sort (except library series page), history/bookmark scroll, search "Advanced Filters" and quiet-sources disclosure. Library browse filters live in the URL (`?search&sort&status&reading_status&is_favorite`).

**Totals: 51 setting keys** (18 server per-profile/account, 5 instance-wide, 24 scoped client, 4 device/other).

**For the redesign:** the skin choice (Cinematic / Glass) will be one new key (probably profile-scoped like K24, plus a boot script that reads it before paint and a restart flow). The decisions file removes K25 (palette picker, dark-only) and replaces K24 (design preset) with the skin; K40 novel paper palettes stay (Apple Books reference). New features will add: UI sound on/off (default off), haptics (mobile), AI recap preferences, ambient soundscape, streak goals, social visibility.

## 20. Motion, transitions and feedback that exist today (every one needs a Cinematic and a Glass version)

All CSS durations are multiplied by `--shape-motion` (1 / 0.7 / 0.6 / 0.8 / 0.35 by preset) and removed under `prefers-reduced-motion`.

| # | Motion | Where | Current values |
|---|---|---|---|
| MO1 | Route cross-fade `route-in` | `<main>` on every non-reader route change | opacity .55 → 1, 240 ms ease-out |
| MO2 | Content entrance `content-in` / `stagger-in` | grids (library, sources), history tiles | opacity 0 + 10 px → rest, 360 ms `cubic-bezier(.25,.1,.25,1)`; stagger in bands of 6 items at 0/60/120/180/240 ms |
| MO3 | Scroll fade `FadeIn` | page headers, settings, downloads, status | opacity + translate 20–30 px, 700 ms `cubic-bezier(.25,.1,.25,1)`, staggered delays 0.05–0.2 s, IntersectionObserver with 50 px root margin |
| MO4 | Cover fade | every `CoverImage` | opacity 0 → 1 on load/error, 320 ms ease-out |
| MO5 | Card hover | series, source, world, search cards | cover scale 1.05 (200–300 ms), ring/glow, collection banner scale 1.01 |
| MO6 | Dialog | every `Dialog` | scrim `overlay-in` 200 ms ease-out; panel `panel-in` 260 ms `cubic-bezier(.16,1,.3,1)` from 8 px + scale .985 |
| MO7 | Bottom sheet/bar entrance `sheet-up-in` | bulk action bar | 16 px up + fade, 280 ms `cubic-bezier(.16,1,.3,1)` |
| MO8 | Reader settings sheet | manga reader | translateY 100 % → 0, 300 ms ease-out; scrim fade 300 ms |
| MO9 | Reader chrome hide/show | manga reader bar + download pill + page counter | translate-y full + fade, 300 ms; cinema hides after 3000 ms idle |
| MO10 | Reader end card `reader-end-card-enter` | strip tail error card | 1.5 rem up + fade, 300 ms |
| MO11 | Page-turn fade `reader-page-transition-enter` | paged reader (opt-in) | opacity 0 → 1, 220 ms ease-out |
| MO12 | Profile picker entrance | profile tiles | `mm-profile-in` 340 ms `cubic-bezier(.215,.61,.355,1)`, 80 ms stagger, from 10 px + scale .92 |
| MO13 | Profile selection hand-off | picker | chosen ×1.35, others ×0.9 + 20 % + blur 3 px (500 ms ease-out), mood tint 500 ms, 450 ms hold, 400 ms full-screen mood fade |
| MO14 | Shell mood tint | shell background | 500 ms background transition |
| MO15 | Sidebar collapse | sidebar | width 240 ↔ 68 px, 200 ms |
| MO16 | Source loading overlay | source catalogue | 3 pulsing dots (0/150/300 ms), cover carousel cross-fade 700 ms every 3.5 s, hue wash fades in after 3 s (700 ms), overlay fade-out 500 ms |
| MO17 | Skeleton pulse | all loading states | Tailwind `animate-pulse` |
| MO18 | Spinners | Loader2 / RefreshCw `animate-spin` | auth pending, saving, refreshing |
| MO19 | Progress bars | Progress, reading %, novel hairline | width 500 ms ease-out (hairline 150 ms) |
| MO20 | Toggle / chevron micro-motion | Switch knob, account chevron rotate 180°, ChevronRight nudge 0.5 on hover | 200 ms |
| MO21 | Novel follow-along highlight `.novel-speaking` | novel reader while audio plays | background 120 ms ease-out, auto-scroll to the segment |
| MO22 | Smooth scroll | continue-reading rail (snap-x), strip `scroll-smooth` | native |

Haptics: none on web. Sound: none. Unused motion components: `AnimatedText` (scroll-linked per-character opacity 0.2 → 1), `Magnet` (cursor attraction, 300/600 ms), `ScrollMarquee` (two counter-scrolling image rows), `StickyStack` (stacking sticky cards scaling to 0.97) — they are the only framer-motion users and none is mounted.

## 21. Gaps and inconsistencies the redesign should resolve (observed, not opinions)

1. No toast/snackbar system: success and failure are inline text, bar messages or button label swaps (bookmark notice is the only floating toast). Destructive single actions have no undo (bookmark remove, bulk unfollow, download remove).
2. Two different "series detail" screens for the same series: `/library/[followedId]` (followed, has favourite, status, notifications, Read all) and `/sources/[s]/series/[id]` (source view, has genres, author/artist, follow). Novel series only have the source view. Links from history/stats/downloads go to the source view.
3. Settings footer says settings "apply without restarting", which the skin switch will contradict.
4. On phones `/profiles/manage` (edit / delete profiles) is unreachable: its only link is the desktop sidebar footer, More → "Switch profile" opens the picker (which can add but not edit or delete), and Settings has no Profiles tab despite a code comment claiming one.
5. Sidebar prefix matching lights "Library" together with every `/library/*` entry.
6. Search "Advanced Filters" has no filters (info only). OCR results jump to the chapter start, not the page.
7. Several backend capabilities have no UI: manual series order, `mature_override` per series, bookmark notes, profile ordering, batch progress sync, OCR per-chapter text.
8. Mature (18+) gate is edited in two places with different safeguards (Settings → Content asks for confirmation; profile form does not).
9. The Wifi icon beside the clock is decorative and never reflects offline state; there is no global offline indicator outside `/downloads`.
10. Unread state is split: the bell (topbar strip, every width) and the More hub Updates row carry counts, but no bottom tab shows a badge and Updates has no tab of its own on phones.
11. The reader has no swipe gestures and no pinch zoom handling; tap zones and keys only.
12. Statistics has no share/export, no year view (new feature §decisions 2).
13. Themes: 42 palettes and 5 presets are removed by the dark-only two-skin decision; command palette groups "Design" and "Themes" must be replaced by "Skin" (with restart confirm).
