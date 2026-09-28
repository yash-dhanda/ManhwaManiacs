# ManhwaManiacs mobile (Flutter) — UI inventory

Source: `/srv/manhwamaniacs/dev/ManhwaManiacs/mobile/lib` (Flutter ≥3.22, Riverpod 2.5, go_router 14, cached_network_image 3.3, just_audio 0.9.40, sqflite 2.4, wakelock_plus 1.2.8, flutter_displaymode 0.6, url_launcher 6.3, file_picker 8.1, connectivity_plus 6.0, package_info_plus 8.0). Read on 2026-09-29: every file under `app/router`, `app/theme`, `features/*/screens`, `features/*/widgets`, `shared/widgets`, plus the providers, repositories and utils that decide what those widgets show.

This is the 100 % coverage checklist for the two-skin redesign (Cinematic / Glass). It records **what exists and what it does**, not how it should look; current colours and sizes are noted only where they are behaviour (reader backgrounds, novel palettes, avatar presets) or where a designer needs the exact copy/limits. Do not treat any current styling as a constraint.

**Token legend used below** (current Signature preset; other presets rescale): spacing `xxs 2, xs 4, sm 8, md 12, lg 16, xl 20, xl2 24, xl3 32, xl4 40, xl5 48, xl6 64, xl7 80` px; radius `xs 4, sm 6, md 10, lg 14, xl 20, xl2 28, xl3 40, xl4 60` px, `pill/full 999`. Icon names are Material Icons.

## Counts

| What | Count |
|---|---|
| Screens (routed + pushed) | **34** (31 go_router routes + 3 `MaterialPageRoute` pushes), plus the `/` → `/library` redirect |
| Screen variants rendered by one route | 6 (login bootstrap vs form; register closed vs form; source series detail manga vs novel; downloads Chapters vs Storage tab; settings 4 tabs counted as one screen; reader S15/S19 share one body) |
| Modal bottom sheets | 9 (series actions, reading mode, What's New, Save to Files, reader settings, novel type, novel contents, audiobook picker, voices) + 2 full-screen overlays (settings search, stock license page) + 2 popup menus (downloads series options, collection sort) |
| Dialogs | 20 `AlertDialog` instances |
| Screen-level UI elements (section 2) | **496** numbered items + **24** novel-sheet items |
| Global chrome items (section 3) | **42 itemised entries across 14 areas (G1–G14)** |
| Shared primitives (section 3, G14) | **19 (+ 19 themed and 11 unthemed Material components)** |
| User actions mapped to API/storage (section 4) | **157 (A001–A157)** |
| Settings / persisted keys (section 5) | **40** (K01–K40) |
| Distinct backend endpoints called | **94 (82 reachable from the UI; 12 have no UI yet — see end of section 4)** |
| Snackbar call sites | 81 |
| Loading / empty / error / offline state entries | 77 itemised in section 2 |

Elements per screen (section 2 numbered items): S01 9 · S02 4 · S03 13 · S04 17 · S05 15 · S06/S07 15 (shared form) · S08 18 · S09 21 · S10 21 · S11 20 · S12 17 · S13 8 · S14 8 · S15/S19 41 (shared reader) · S16 16 · S17 14 · S18 30 · S20 20 · S21 40 · S22 18 · S23 13 · S24 12 · S25 13 · S26 23 (+24 in its four sheets) · S27 7 · S28 27 · S29 6 · S30 6 · S31 7 · S32 4 · S33 7 · S34 6 = 496.

## 1. Routes and screens

Transitions: unless noted, a route uses go_router's default `MaterialPage`, i.e. the platform's stock Material page transition (Cupertino horizontal slide with swipe-back on iOS; Material default on Android). Tab switches (`goBranch`) are instant (IndexedStack, each branch keeps its stack and scroll). The three readers use a custom **immersive fade** (FadeTransition, 280 ms in / 220 ms out, `Curves.easeOutCubic`) on the root navigator, above the tab shell. "go" replaces the branch stack; "push" stacks. More → History/Bookmarks/Statistics/Recommendations use **go**, which jumps into the Library tab's branch (nav bar hidden because they are not tab roots).

| # | Path | Screen (class) | Purpose | Data shown | Entry points | Transition |
|---|---|---|---|---|---|---|
| S01 | `/setup` | Setup (`SetupScreen`) | enter + validate backend URL on first run | default URL, validation error | forced by router until setup completes | default |
| S02 | `/splash` | Splash (`SplashScreen`) | hold during token probe | logo, spinner | router on cold start (`AuthUnknown`) | default |
| S03 | `/login` | Login (`LoginScreen`) | sign in / bootstrap prompt | server host, bootstrap + registration status | router when signed out; Register back; after sign-out or 401 | default |
| S04 | `/register` | Register (`RegisterScreen`) | create account / claim server / closed notice | bootstrap, invite requirement | Login "Create an account", "Create the first account" | default (+AppBar back) |
| S05 | `/profiles` | Profile picker (`ProfilePickerScreen`) | "Who's reading?" gate + switcher | profiles (≤5), avatars, moods | router once per session after auth; Library home profile chip; More → Switch profile; profile-scope error recovery | default; in-screen 5 s mood-bloom selection animation |
| S06 | `/profiles/create` | Add profile (`ProfileCreateScreen`) | create profile | form | picker "Add profile" tile / empty CTA | default |
| S07 | `/profiles/edit/:id` | Edit profile (`ProfileEditScreen`) | edit / delete profile | profile | picker long-press or Manage-mode tap | default |
| S08 | `/library` (tab 0) | Library home (`DashboardScreen`) | followed shelf + continue rail | followed series, unread counts, continue-reading, local read marks | bottom nav; `/` redirect; after profile select; Stats "Continue Reading" | tab |
| S09 | `/library/browse` | Library browse (`LibraryScreen`) | search/sort/filter/multi-select the followed library | paged follows, reading status, favourites | only the back fallback of S10 (no forward entry today) | default |
| S10 | `/library/:seriesId` | Series detail — library (`SeriesDetailScreen`) | followed series by follow id; offline-capable | series meta, chapters, per-chapter progress, downloads | S09 card / sheet "Open"; Search tab local-library hits | default; cover Hero from S09 |
| S11 | `/library/recommendations` | Recommendations (`RecommendationsScreen`) | AI prompt + "For you"/"Because you read" rails | world recs, AI budget, suggestions | More → Recommendations (go) | default |
| S12 | `/library/statistics` | Statistics (`StatisticsScreen`) | reading stats | streak, 30-day activity, clock, totals, sources, most read, sessions, library shape | More → Statistics (go) | default |
| S13 | `/library/history` | Reading history (`ReadingHistoryScreen`) | recently read series | history items (collapsed by series) | More → Reading History (go); Settings → Reading history card (push) | default |
| S14 | `/library/bookmarks` | Bookmarks (`BookmarksScreen`) | exact-position bookmarks | bookmarks (manga + novel) | More → Bookmarks (go); S09 bookmark icon (push) | default |
| S15 | `/library/read/:sourceId/:seriesKey/:chapterKey` `?page&at&all` | Manga reader (`ReaderScreen`) | read images by opaque triple | chapter pages, neighbours, progress | continue rail, S10, S18 Continue/Read Online, history, bookmarks, updates, stats sessions, dialogue search, downloads, prev/next | immersive fade, root navigator |
| S16 | `/sources` (tab 1) | Sources (`SourcesListScreen`) | installed connectors, pins | sources, pins, 18+ flags | bottom nav; Library home icon/empty CTA; Recs/Stats "Browse Sources" | tab |
| S17 | `/sources/:sourceId` | Source browser (`SourceBrowserScreen`) | browse/search one source | browse modes, paged series | S16 row (go) | default |
| S18 | `/sources/:sourceId/series/:seriesId` | Source series detail (`SourceSeriesDetailScreen` / `NovelSeriesDetailView`) | canonical series page, manga or novel body | series meta, chapters, progress, downloads, narration, word counts | Library home, history, stats, recs, search, collections, source browser, readers' "Go to series" | default |
| S19 | `/sources/:sourceId/series/:seriesId/chapters/:chapterId/read` `?page&all` | Source reader (`SourceReaderScreen`) | read images by source chapter id | as S15 | S18 chapter tap / Read all; prev/next | immersive fade, root navigator |
| S20 | `/search` (tab 2) | Search (`SearchScreen`) | federated multi-source search | grouped results per source, recent + trending | bottom nav; Recommendations "Search" | tab |
| S21 | `/downloads` (tab 3) | Downloads (`DownloadsScreen`) | offline library, queue, storage policy | queue, saved series/chapters, sizes, OCR run | bottom nav (count badge) | tab |
| S22 | `/more` (tab 4) | More (`MoreScreen`) | hub | unread count, app version, APK update | bottom nav | tab |
| S23 | `/updates` | Updates (`UpdatesScreen`) | notifications + follows | notifications, unread count, follows | More → Updates | default |
| S24 | `/collections` | Collections (`CollectionsScreen`) | user collections | collections | More → Collections | default |
| S25 | `/collections/:collectionId` | Collection detail (`CollectionDetailScreen`) | one collection | members | S24 banner | default |
| S26 | `/novels/read/:sourceId/:seriesKey/:chapterKey` `?page&para&at` | Novel reader (`NovelReaderScreen`) | read text + narration | paragraphs, audio manifest, cast, progress | novel series page, continue rail, bookmarks, updates, history, downloads, prev/next/contents | immersive fade, root navigator |
| S27 | `/ocr/search` | Dialogue search (`OcrSearchScreen`) | OCR text search | results with snippets | More → Dialogue Search (OCR available + manga mode) | default |
| S28 | `/settings` | Settings (`SettingsScreen`) | preferences (General / Server / About / Debug) | account, mature flag, theme, preset, reader defaults, URL, version | More → Settings; More app-info tile | default |
| S29 | (pushed) | Password & security (`SecurityScreen`) | password, sessions, sign out everywhere | sessions | Settings → Account | `MaterialPageRoute` |
| S30 | (pushed) | Members (`MembersScreen`) | admin account management | accounts | Settings → Account (admins) | `MaterialPageRoute` |
| S31 | (pushed) | Theme gallery (`ThemeGalleryScreen`) | pick palette | 45 palettes | Settings → Theme card | `MaterialPageRoute` |
| S32 | `/settings/storage` | Storage (`StorageScreen`) | download policy + caches | usage, cap, breakdown | More → Storage | default |
| S33 | `/settings/backup` | Backup & Restore (`BackupScreen`) | export / stage restore | restore status | More → Backup & Restore | default |
| S34 | `/settings/diagnostics` | Diagnostics (`DiagnosticsScreen`) | perf + device info | FPS, jank, display modes, device, image cache | Settings → Debug | default |

Router guards (in order): no server URL → `/setup`; auth unknown → `/splash`; signed out → `/login` (or `/register`); signed in without a profile chosen this session → `/profiles` (create/edit reachable); signed in → auth/splash/setup redirect to `/library`.

## 2. Screens: every element

Numbered items are the per-screen checklist (states and gestures included).
### S01 Setup — `/setup` (`SetupScreen`)

Purpose: first-run gate; the user types the backend URL before anything else. The router forces every path here until `setupCompleted` is true.

1. **Scaffold + SafeArea + centered scroll**, content capped at 420 px wide.
2. **GlassPanel card** (the whole form sits in one frosted panel, padding `xl2`).
3. **Logo tile** 56x56, primary→accent linear gradient, radius `lg`, glow shadow (primary @ 28 %, blur 24, spread -4), white "M" in `h1`.
4. **HeroHeading** "Get Started" (38 px, the letter-reveal heading widget).
5. **Body copy** "Connect to your ManhwaManiacs backend to browse, download, and read." (muted).
6. **TextField "Server URL"**: prefix icon `dns_outlined`, hint = `Env.defaultApiUrl`, keyboard type URL, inline `errorText`, submit-on-enter, disabled while pending.
7. **PrimaryPillButton** "Continue" / "Connecting…" (full width; 60 % opacity + ignore pointer while pending).
8. **State: error** — backend validation failure shown as the field's `errorText` (`AppError.userMessage`).
9. **State: pending** — label swap + dimmed button, field disabled.

Transition: plain MaterialPage (platform default push). On success `context.go('/library')`.

### S02 Splash — `/splash` (`SplashScreen`)

Purpose: holds while the stored token is validated on cold start (`AuthUnknown`).

1. **Full-bleed `bg` scaffold**, centered column.
2. **Logo tile** 72x72, primary→accent gradient, radius `xl`, glow (primary @ 30 %, blur 32), white "M" in `displayMd`.
3. **Wordmark text** "ManhwaManiacs" in `labelLg`, muted, letter-spacing 2.
4. **Spinner** 22x22 CircularProgressIndicator, stroke 2, primary.

No interactions. The router leaves automatically when auth resolves.

### S03 Login — `/login` (`LoginScreen`)

Purpose: sign in; also doubles as the "server has no accounts" bootstrap prompt.

Variant A: bootstrap prompt (`bootstrap-status` says no accounts exist):
1. **AuthHeader** (56 px gradient "M" tile + HeroHeading 38 px + muted subtitle): "Welcome to ManhwaManiacs" / "This server has no accounts yet. Create the first account — it becomes the administrator."
2. **PrimaryPillButton** "Create the first account" → `/register`.

Variant B: sign-in form:
3. **AuthHeader** "Welcome back" / "Sign in to your ManhwaManiacs account to continue."
4. **Server host row** (tap target): caption "Server: <host>" + `copy_outlined` 14 px icon. Tap copies the full base URL.
5. **Snackbar** "Copied <url>".
6. **TextField "Username"** (prefix `person_outline`, no autocorrect/suggestions, next action).
7. **TextField "Password"** (prefix `lock_outline`, obscured).
8. **IconButton (suffix) show/hide password** `visibility_outlined` ⇄ `visibility_off_outlined`, tooltips "Show password"/"Hide password".
9. **SwitchListTile "Keep me signed in"** (default on; decides token persistence).
10. **AuthError box** (danger @ 24 alpha fill, danger @ 90 border, radius `md`, `error_outline` 18 px + message). Messages include "Enter your username and password." and server errors.
11. **PrimaryPillButton** "Sign in" / "Signing in…" (full width, dimmed while pending).
12. **TextButton** "Create an account" (only when registration is open) → `/register`.
13. **State: pending** — all inputs disabled, button label swap.

Container: GlassPanel, max width 420, SafeArea, scrollable.

### S04 Register — `/register` (`RegisterScreen`)

Purpose: create an account; first account on an empty server becomes admin ("claim this server").

1. **AppBar** with **BackButton** → `context.go('/login')`.
2. **GlassPanel** container (max 420).
Variant "closed" (registration disabled):
3. **AuthHeader** "Registration closed" / "This server is not accepting new accounts right now. Ask an administrator for access."
4. **PrimaryPillButton** "Back to sign in".
Variant "form":
5. **AuthHeader** "Claim this server" (bootstrap) or "Join ManhwaManiacs" with matching subtitle.
6. **TextField "Username"**.
7. **TextField "Password"** with helper "At least 8 characters".
8. **IconButton show/hide** (password).
9. **TextField "Confirm password"**.
10. **IconButton show/hide** (confirm).
11. **TextField "Invite code"** (`vpn_key_outlined`; only when the server requires one and it is not a bootstrap).
12. **TextField "Display name (optional)"** (`badge_outlined`).
13. **TextField "Email (optional)"** (`mail_outline`, email keyboard).
14. **AuthError box**. Client-side messages: "Choose a username and password.", "Password must be at least 8 characters.", "Passwords don't match.", "Enter the invite code for this server.", "Enter a valid email address, or leave it blank." Server codes mapped: invite_code_required, invite_code_invalid, registration_disabled, rate_limited, username_taken.
15. **PrimaryPillButton** "Create account" / "Create the administrator account" / "Creating account…".
16. **TextButton** "I already have an account" → `/login`.
17. **State: pending** — all fields disabled.

### S05 Profile picker — `/profiles` (`ProfilePickerScreen`)

Purpose: the Netflix-style "Who's reading?" gate shown once per app session after auth, and the profile switcher target from anywhere. Outside the tab shell.

1. **MoodBackdrop (picker variant)** — radial glow from top-center, tint ratio 0.34, radius 1.15, fade stop 0.72, crossfades 420 ms easeOut when mood changes.
2. **Transparent AppBar** (no title).
3. **TextButton "Manage" / "Done"** in the app bar (hidden while empty, loading, error, or mid-selection). Toggles manage mode.
4. **HeroHeading** "Who's reading?" (44 px, centered).
5. **Subheading** "What are you going to read today?" (`h3`).
6. **Helper line** "Choose a profile to continue." / "Tap a profile to edit it." (manage mode).
7. **Profile tile** (one per profile, Wrap centered, spacing `xl2`): 108 px wide glass card (BackdropFilter blur 12, surface @ 42 % / 62 % focused, border 1 px / 1.5 px amber focused, amber glow when focused), **ProfileAvatar** 96 px with ring in the profile's mood tint, name in `labelLg`.
8. **Manage overlay on avatar** — scrim circle with white `edit_outlined` 28 px.
9. **"Add profile" tile** — 96 px dashed-feel circle (surface2 @ 90, amber @ 35 % 2 px border), amber `add` 34 px, muted label; shown while fewer than `kMaxProfiles` profiles exist.
10. **Staggered reveal** — each tile uses `ScrollReveal(index)` (skipped under reduced motion).
11. **Selection takeover animation (5 s)** — `_MoodTakeover`: phases focus 0–0.12, expand 0.10–0.50, identity 0.42–0.72, handoff 0.90–1.0. Tapped tile lifts to 1.18x with easeOutBack; others fall to 0.9x, 12 % opacity, blur 9. A radial mood bloom grows from the tap point (easeInOutCubic) toward (0, -0.6) and settles at (0, -0.95); a vignette fades in; the chosen avatar (132 px, amber ring) + name scale 0.82→1.0 and un-blur 16→0, then fade on handoff. Copy fades out with the focus phase. Under reduced motion the selection is instant.
12. **State: loading** — AsyncValueWidget default loader.
13. **State: empty** — EmptyState `group_add_outlined` "Create your first profile" / "Reading profiles keep progress, follows and a mood theme separate for everyone who shares this account." + PrimaryPillButton "Add profile" (`add` icon).
14. **State: unreachable (no cached profile)** — EmptyState `cloud_off_outlined` "Profiles are unavailable" + error text + PrimaryPillButton "Retry" (`refresh`).
15. **State: unreachable (cached profile)** — HeroHeading, error text, "Continue as your last profile, or retry once it is back.", a single resumable glass tile for the last active profile, and a "Retry" pill.

Gestures: tap tile = select (or edit in manage mode); **long-press tile = edit**; tap-down records the bloom origin.

### S06 Add profile — `/profiles/create` (`ProfileCreateScreen` → `ProfileFormScaffold`)
### S07 Edit profile — `/profiles/edit/:id` (`ProfileEditScreen` → `ProfileFormScaffold`)

Purpose: create or edit a reading profile (name, avatar, mood tint, 18+ opt-in). Both use the same form.

1. **MoodBackdrop (shell variant)** that live-previews the selected mood.
2. **Transparent AppBar** with title "Add profile" / "Edit profile" and default back.
3. **Large avatar preview** — ProfileAvatar 96 px with amber @ 30 % ring.
4. **Section label "Name"** + **TextField** (hint "e.g. Weeknight reads", `badge_outlined`, maxLength 255 with counter).
5. **Section label "Avatar"** + **Avatar picker grid**: 12 presets as 56 px gradient circles with white glyphs; selected gets a primary ring. Presets: violet "Violet Spark" (#8B5CF6→#D946EF, auto_awesome), cyan "Cyan Rocket" (#06B6D4→#0EA5E9, rocket_launch), rose "Rose Heart" (#F43F5E→#EC4899, favorite), amber "Amber Coffee" (#F59E0B→#F97316, local_cafe), emerald "Emerald Cat" (#10B981→#14B8A6, pets), ember "Ember Flame" (#EF4444→#F59E0B, local_fire_department), blade "Steel Blade" (#94A3B8→#475569, shield), phantom "Phantom" (#6366F1→#334155, blur_on), arcane "Arcane Wand" (#A855F7→#6366F1, auto_fix_high), lunar "Lunar Moon" (#0284C7→#4338CA, dark_mode), star "Starlight" (#FACC15→#F59E0B, star), reader "Bookworm" (#14B8A6→#0891B2, menu_book). Default `violet`.
6. **Section label "Mood"** + helper "Tints the app while this profile is active."
7. **Mood chips** (pill, 12 px colour dot + label): Romantic, Action, Comedy, Horror, Slice of Life, Fantasy, Default. Selected = mood swatch fill + fg border.
8. **SwitchListTile "Mature content"** / "Show 18+ sources and series for this profile." (this is the per-profile 18+ gate).
9. **AuthError box** ("Give this profile a name." or server error).
10. **PrimaryPillButton** "Create profile" / "Save changes" (replaced by a 22 px spinner while pending).
11. **TextButton.icon "Delete profile"** (danger, `delete_outline`; edit only).
12. **Dialog "Delete profile?"** — "This removes "<name>" and its reading preferences. This cannot be undone." Actions: TextButton "Cancel", FilledButton "Delete" (danger fill).
13. **State: loading** (edit) — centered spinner scaffold.
14. **State: error** (edit) — AppBar "Edit profile" + EmptyState `error_outline` "Couldn't load profile".
15. **State: not found** (edit) — EmptyState `person_off_outlined` "Profile not found" / "This profile may have been removed."

On success: pop, or go to `/profiles` when nothing to pop.
### S08 Library home (tab 0) — `/library` (`DashboardScreen`)

Purpose: the landing tab. Shows the active profile's followed series as a cover grid (manga mode) or a typographic shelf (novel mode), with a continue-reading rail on top. Data: `updatesProvider` (followed list + update notifications), `continueReadingProvider`, local read marks, content-mode scope.

1. **Transparent AppBar** (body extends behind it, no leading).
2. **IconButton** `travel_explore_rounded` "Browse Sources" (only when something is followed) → `go('/sources')`.
3. **ProfileSwitcherChip** (see global chrome G3) → push `/profiles`.
4. **HeroHeading** "Library" (40 px) inside a FadeIn.
5. **Count line** caption: "<n> series followed" / "<n> novel(s) on your shelf".
6. **ContentModeSwitch** segmented pill (Manga | Novels) — only when novels are enabled server-side (see G5).
7. **Continue reading rail** (`ContinueReadingStrip`): muted label "Continue reading", horizontal list, 74 px tall cards 232 px wide.
8. **Continue card** (GlassCard): 40 px cover thumb (radius `sm`), title (`labelLg`), secondary "Chapter N · Page x of y" or "NN% through" for novels, 3 px LinearProgressIndicator in primary. Tap → resume location in the right reader.
9. **Followed series card (grid)** (`FollowedSeriesCard`, aspect 0.5, `Pressable` scale-on-press): full-bleed cover radius `xl` (surface2 placeholder when no cover), title 2 lines w600, subtitle 1 line (read state "Ch 12 of 40", "Latest: Chapter 41", or "N chapters").
10. **"N NEW" badge** on the cover's top-right (primary pill, 10 px w700, tracking 0.6; caps at "99+ NEW").
11. **Novel shelf row** (novel mode; `NovelShelf`): serif title 17 px w600, meta line (unread badge, favourite star, "by Author · N chapters · Status · note"), 2-line blurb, 46x66 cover plate (or serif initial on surface2), hairline dividers between rows.
12. **Grid reveal** — each card wrapped in `ScrollReveal(index)` stagger.
13. **Pull-to-refresh** (RefreshIndicator in primary) → refreshes updates state.
14. **Series actions sheet** on long-press (see shared sheet M1).
15. **State: loading** — skeleton: 200x40 heading bar + 6 grid tiles radius `xl` (or 6 x 92 px rows in novel mode), not scrollable.
16. **State: empty** — EmptyState `menu_book_outlined` "Your library is empty" / "Follow series from Sources to build your warm little shelf." (novel: "Your shelf is empty" / "Add a book from a novel source to start your shelf.") + PrimaryPillButton "Browse Sources" (`travel_explore_rounded`); still pull-to-refresh.
17. **State: error** — 72 px danger circle with `error_outline`, HeroHeading "Oops", message, FilledButton.icon "Try Again" (`refresh`).
18. **Snackbars cleared** on first frame (stale messages from other tabs are dropped).

Gestures: tap card → push `/sources/:sourceId/series/:seriesKey` (source detail, not `/library/:id`); long-press card → actions sheet; pull-to-refresh.

### S09 Library browse — `/library/browse` (`LibraryScreen`)

Purpose: searchable/sortable/filterable paged list of the whole followed library with multi-select. Reached only as the fallback "back" target of Series detail (no forward entry point in the current app). Data: `libraryListProvider` (paged `GET /library/series`), `libraryQueryProvider` (persisted), `libraryCoverScaleProvider`.

1. **AppBar (normal)**: transparent, **IconButton back** `arrow_back` (pop or go `/library`), **IconButton** `checklist` "Select series", **IconButton** `bookmark_outline` "Bookmarks" → push `/library/bookmarks`.
2. **AppBar (selection mode)**: title "<n> selected", **IconButton** `close` "Cancel selection", **IconButton** `select_all` "Select all".
3. **HeroHeading** "Library" (FadeIn).
4. **Toolbar title block**: "Library" in `h1` + "<count> series|novels" muted.
5. **View mode toggle** (grid `grid_view` / list `view_list`; 32x32 segments, selected = primary fill) — hidden in novel mode.
6. **Search TextField** "Search by title, author, or tag..." with `search` prefix; 300 ms debounce.
7. **Filter chips** (horizontal scroll): All, Reading, Completed (FilterChip, selected = primary fill, no checkmark).
8. **Sort dropdown** `DropdownButtonFormField` labelled "Sort": Recently Updated, Recently Added, Alphabetical.
9. **Cover size slider** (0.7–1.6) flanked by `photo_size_select_small` / `photo_size_select_large`; grid mode only; changes column count; persisted after 250 ms.
10. **Inline error banner** (danger @ 26 fill, danger @ 77 border) when a page load fails after data exists.
11. **Series card (grid)** (`SeriesCard`, aspect 2/3, Hero tag `seriesCoverHeroTag(id)`): cover, bottom gradient to `bg` @ 240 over 110 px, reading-status tag top-left (colour by status: reading = primary, completed = success, on_hold = warning, plan_to_read = #3B82F6, unread = #3B82F6 @ 60 %), title in white, "<n> ch" line (hidden when card detail = minimal), progress label below the card ("Ch 12 of 40 · 3 new", or a favourite star + label in warning colour).
12. **Favourite star button** (32 px circle on `bg` @ 50 %, `star` warning / `star_border`).
13. **Selection checkbox** (26 px circle, primary fill + white check when selected) replaces the star in selection mode; selected card gets primary @ 60 overlay + 3 px primary border.
14. **Series list tile** (`SeriesListTile`, list mode): GlassCard row, 64x64 cover (Hero), title + status tag, meta line, compact 36 px star or checkbox.
15. **Novel shelf rows** (novel mode) with 24 px selection mark in selection mode.
16. **Load-more spinner** at the bottom (infinite scroll triggers 320 px before the end).
17. **Selection action bar** (bottom, shown when ≥1 selected): OutlinedButton.icon "Favorite (<n>)" (`star` warning) and "Unfavorite" (`star_border`).
18. **Empty panel** (panel-filled box radius `xl`): "No results found" / "No series match these filters" / "Your library is empty" (novel variants) with explanatory line.
19. **State: loading** — toolbar stays live + LibrarySkeleton (12 grid tiles 2/3 radius 16, or 8 x 80 px rows).
20. **State: error** — `error_outline` 48 px, "Could not load library", message, FilledButton.icon "Try Again".
21. **Pull-to-refresh**.

Gestures: tap card → push `/library/:id` (or toggle in selection mode); long-press → series actions sheet (M1; disabled in selection mode); infinite scroll.

### S10 Series detail (library) — `/library/:seriesId` (`SeriesDetailScreen`)

Purpose: detail for a followed series by follow-row id (`GET /library/series/:id`), with progress, downloads and favourites. Entry points: Library browse, Search tab's library hits. Offline-capable (`view.isOffline`).

1. **AppBar**: **IconButton back** (pop or go `/library/browse`), title = series title (fallback "Series", 1 line ellipsis).
2. **Cover** full content width, aspect 2/3, radius 12, Hero-linked from the grid.
3. **Title** `displayMd`; **author** muted; **meta line** in primary `label`: "Latest: Chapter 41 · 40 chapters".
4. **Description** body text (full, not collapsed).
5. **PrimaryPillButton** "Continue" (`play_arrow_rounded`) or "Start Reading" (`menu_book_outlined`), full width; resumes at the saved page.
6. **ReadAllButton** "Read all" (`all_inclusive_rounded`, outlined pill, tooltip "Read the whole series as one continuous scroll"); manga only.
7. **SeriesFollowButton** full-width FilledButton.icon: "Unfollow" (`notifications_off_outlined`) / "Follow" (`notifications_active_outlined`) / "Following…" / "Unfollowing…". Snackbars "Unfollowed" / "Following — you'll be notified of new chapters" / error.
8. **"Select" OutlinedButton** (`checklist_rounded`) — enters chapter multi-select (only with a downloads scope).
9. **Selection bar** (bordered box): ActionChips "Next 10", "All unread (n)", "All (n)", "None"; FilledButton.icon "Download N chapters" / "Select chapters" (disabled at 0); TextButton "Cancel".
10. **"Download Series" OutlinedButton** (`download_outlined`, inline 16 px spinner while queueing). Snackbar "Queued N chapters for download."
11. **Favourite OutlinedButton** "Add Favorite" (`star_border`) / "Favorited" (`star` in warning, warning-tinted fill and border).
12. **Status + genre chips** (pill, fg @ 5 % fill, status chip coloured by reading status, uppercase).
13. **Series download progress card** (GlassCard with glow primary or warning when blocked): `offline_pin`/`downloading_outlined` icon, "X of Y chapters saved on this phone", 6 px progress bar (success when complete), "Downloading now · page a of b", "N waiting in the queue · N failed", pause reason row (`info_outline` warning), and the foreground-only note "Downloads only run while ManhwaManiacs is open — leaving the app pauses them, and coming back picks up exactly where they stopped."
14. **"Chapters" header** (`h3`) + **Newest/Oldest segmented toggle** (150 ms easeOut, primary fill on the active segment).
15. **Chapter tile** (GlassCard): primary label (e.g. "Chapter 12"), optional secondary (chapter title), "Reading" pill (primary @ 40 fill) on the current chapter, progress "12/40 pages" (primary when in progress), upload date line, download status line + 3 px bar while downloading, 60 % opacity when read.
16. **Chapter checkbox** (leading, selection mode).
17. **Chapter download control** (trailing): IconButton `download_outlined` "Download Chapter"; `schedule` badge "Queued for download"; 20 px determinate ring "Downloading — page a of b"; `offline_pin` success "Saved offline — reads with no connection"; IconButton `refresh` danger "Retry Download".
18. **State: loading** — SeriesDetailSkeleton (2/3 cover box, 220x32 title, 140x16, 200x14, 72 px description, 48 px pill, 120x20 header, 6 x 64 px chapter rows).
19. **State: error** — `error_outline` 48 px, "Could not load series", FilledButton.icon "Try Again", OutlinedButton "Back to library".
20. **State: no chapters** — EmptyState `menu_book_outlined` "No chapters available" / "This source hasn't listed any chapters for this series yet."
21. **State: offline** — rendered from the local cache (`isOffline`), same layout.

Transitions: chapter open → reader route (fade 280/220 ms). Snackbars on favourite error.

### S11 Recommendations — `/library/recommendations` (`RecommendationsScreen`)

Purpose: "Find something to read". Two halves: a free-text AI prompt (external AI API, daily budget) and world recommendations ("For you" + "Because you read X" rails) built from reading history. Data: `GET /library/suggest/availability`, `POST /library/world/suggest`, `GET /library/world/recommendations`.

1. **AppBar**: IconButton back (pop or go `/library`), title "Find something to read".
2. **HeroHeading** "What do you feel like?".
3. **Intro copy** (three variants): AI available — "Describe it in your own words…"; budget exhausted — "You've used today's AI suggestions. They reset at midnight UTC — the picks below are still yours."; AI off — "Picks from everything out there, based on what you read."
4. **Prompt TextField** (2–4 lines, max 600 chars, hidden counter, panel fill, radius `lg`, hint "e.g. a revenge story with a competent lead, no harem"); only when AI is available.
5. **Example ActionChips** (3): "A murim regressor who comes back stronger", "Magic academy, but the lead is already strong", "Something slow and political, not a power fantasy". Tap fills and submits.
6. **PrimaryPillButton** "Suggest something" / "Thinking" (enabled at ≥3 chars and not busy).
7. **Remaining budget caption** "<n> left today" (shown when ≤10).
8. **Suggestion results** — vertical list of WorldTitleCards.
9. **Suggestion error** — danger text ("That didn't work. Try describing it differently.") + FilledButton "Try again".
10. **Skeleton** — 3 x 124 px boxes (for suggestions and for the world section).
11. **Quiet notice** row (`info_outline` 16 px + caption) when the server returns `unavailableReason`.
12. **Rail "For you"** (`labelLg` header + horizontal scroll of 300 px cards).
13. **Rails "Because you read <title>"** (one per seed).
14. **WorldTitleCard** (GlassCard): 72x108 cover (no credentials), title 2 lines w600, badge line "Manhwa · Ongoing", stats "120 ch · ★ 4.5", up to 3 genres, availability "On: <source> (+N more)" in cyan-400 w600, optional "why" line. Tap → push the source series detail.
15. **"Not on your sources" branch** on a card: muted label + TextButton.icon "Search" (`search`; sets the search query and goes to `/search`) + TextButton.icon "Read on <site>" (`open_in_new`; external browser).
16. **Snackbar** "Could not open: <url>".
17. **State: empty** — EmptyState `auto_awesome_outlined` "Read or follow a few series first" / "Recommendations are built from what you read." + PrimaryPillButton "Browse Sources".
18. **State: offline** — EmptyState `cloud_off_outlined` "You're offline" + FilledButton "Retry".
19. **State: error** — danger text "Couldn't load recommendations." + FilledButton "Retry".
20. **Pull-to-refresh** (re-fetches recommendations and AI availability).

### S12 Statistics — `/library/statistics` (`StatisticsScreen`)

Purpose: reading stats from in-app reading sessions (`GET /library/statistics`), filtered by content mode for the breakdowns.

1. **AppBar**: back, title "Statistics", **ContentModeChip**.
2. **HeroHeading** "Reading Statistics" + subtitle ("Built from every chapter you read in the app." / "Your library at a glance.").
3. **Mode caveat caption** (when novels are enabled): "Streak, totals and the clock cover everything you read; the breakdowns below are manga|novels only."
4. **No-history card** (GlassCard with primary glow): 44 px gradient tile `insights_outlined` violet-400, "No reading recorded yet" `h3`, explanation, PrimaryPillButton "Continue Reading" (`play_arrow_rounded` → `/library`) or "Browse Sources" (`explore_outlined` → `/sources`).
5. **Streak card** (primary glow while alive): flame `local_fire_department_rounded` 22 px, current days in `h1` tabular, "day/days", "Current streak" or "Read today to start a new streak", "Longest" count in violet-400 `h3`, 7-day row of 26 px circles (check for read days) with weekday initials.
6. **Activity card**: "Activity" `h4`, range pill "LAST 30 DAYS" (uppercase, tracking 0.8), readout line (totals or the tapped day "Mon, Sep 1 · 42 pages · 3 chapters · 25 min"), **ActivityBars** chart 96 px tall (custom painter, bars max 16 px wide, 3 px gap, rounded tops, amber-400→accent gradient, empty bars fg @ 28, selected bar solid fg, 1 px baseline), first/last date labels, hint "Tap a bar for that day."
7. **Reading clock card**: "Reading Clock", "You read most around <hour>.", 72 px ActivityBars by hour, axis labels 0/6/12/18.
8. **SectionHeader** with icon (`query_stats_outlined` "All-Time Reading", `workspace_premium_outlined` "Most Read", `history` "Recent Sessions", `collections_bookmark_outlined` "Your Library").
9. **Totals grid** (2 cols, aspect 1.45) of StatCards: Chapters Read, Pages Read (amber), Series Read, Time Read or Sessions (emerald).
10. **Sources breakdown card**: "Sources" `h4`, rows with 8 px colour dot (primary fading by rank), name, pages/sessions, 6 px proportion bar.
11. **Most read rows** (GlassCard): 44x60 cover, title, "N pages · N chapters · 2h 5m", "3d ago", chevron → source series detail.
12. **Recent sessions list** (one GlassCard, divided rows): chapter title, "Chapter 12 · 40 pages · 12 min · 2h ago", chevron → manga reader.
13. **Library shape grid** StatCards: Followed Series, Favorites (amber), Completed, Chapters Finished (emerald).
14. **By reading status card**: title-cased status, count, proportion bar coloured by status.
15. **State: loading** — skeleton (220x30, 160x14, 140 px, 220 px, two rows of 2 x 90 px).
16. **State: error** — danger text "Failed to load statistics." + FilledButton "Retry".
17. **Pull-to-refresh**.

Gesture: tap-down on the activity chart selects a day; tapping the same bar clears it.

### S13 Reading history — `/library/history` (`ReadingHistoryScreen`)

Purpose: series you have been reading, most recent first (`GET /reader/history`), filtered by content mode.

1. **AppBar**: back, title "Reading History", **ContentModeChip**.
2. **HeroHeading** "Reading History" + "Books you have been reading, most recent first."
3. **History card grid** (same column logic as the library; `HistorySeriesCard`, `Pressable`): 2/3 cover radius `xl` (or muted `history_rounded` placeholder), 3 px progress bar along the cover bottom for unfinished chapters, title 2 lines ("Unknown book" muted fallback), subtitle "Ch. 12 · done · 3h ago".
4. **Continue button** on the cover (bottom-right black @ 55 % circle, white `play_arrow_rounded` 18 px; 18 px white spinner while resolving). Resolves the next chapter when the last one was completed (fetches the chapter list) and opens the right reader.
5. **State: loading** — two 100 px skeleton boxes.
6. **State: empty** — EmptyState `history` "No reading history yet" / "Open a chapter from your library to start tracking history."
7. **State: error** — danger text "Failed to load reading history." + FilledButton "Retry".
8. **Pull-to-refresh**.

Tap card → push source series detail.

### S14 Bookmarks — `/library/bookmarks` (`BookmarksScreen`)

Purpose: exact-position bookmarks from both readers. Offline-first: reads the local store when a downloads scope exists and syncs through the bookmark outbox (`POST /reader/bookmarks/batch`); falls back to `GET /reader/bookmarks`.

1. **AppBar**: back, title "Bookmarks", **ContentModeChip**.
2. **HeroHeading** "Bookmarks" + "Jump back to exactly where you were, or remove ones you no longer need."
3. **Bookmark card** (GlassCard): title (series title or chapter label), source id (muted), position row with `auto_stories_rounded`/`menu_book_rounded` 14 px + "42% of chapter 12" / "Page 7" / "Paragraph 18", italic 3-line snippet (novels), user note, created timestamp "Sep 28, 2026 9:41 PM". Tap → reader at `?page=&at=` or novel reader at `?para=&at=`.
4. **IconButton** `delete_outline` "Remove bookmark" (disabled while an action is pending).
5. **State: loading** — two 100 px skeletons.
6. **State: empty** — EmptyState `bookmark_border` "No bookmarks yet" / "Tap the bookmark icon in either reader to save the exact spot you are on."
7. **State: error** — danger text "Failed to load bookmarks." + FilledButton "Retry".
8. **Pull-to-refresh** (flushes the outbox first).
### S15 Manga reader — `/library/read/:sourceId/:seriesKey/:chapterKey` (`ReaderScreen` → `ReaderContent`)
### S19 Source reader — `/sources/:sourceId/series/:seriesId/chapters/:chapterId/read` (`SourceReaderScreen` → `ReaderContent`)

Purpose: the image reader for manga/manhwa/manhua. Two routes, one reader body (`ReaderContent`); they differ only in data source (S15: manifest `GET /reader/chapter/manifest` keyed by the opaque triple; S19: `GET /sources/:id/series/:sid/chapters/:cid/reader`), in back behaviour, and S19 also records source-local progress and auto-queues the next chapter for download. Both run on the root navigator (no bottom nav), open with the **immersive fade** (280 ms in / 220 ms out, easeOutCubic), switch the system UI to immersive reading mode on enter and back to the resting mode on exit. Query flags: `?page=N`, `?at=0.0–1.0` (exact anchor, S15 only), `?all=1` (Read all). Full internals in section 6.

Page canvas:
1. **Background** colour from the reader filter (Dark #0A0A0A, AMOLED #000000, Paper #F5F1E8), animated 300 ms easeOut on change.
2. **Page list** — virtualised ListView (vertical, or horizontal for LTR/RTL), 6000 px cache extent, pages seamless in vertical mode (no radius, no gap); in horizontal mode each page gets radius `sm`, a 16 px black @ 40 % drop shadow and a `xs` gap.
3. **Page image** loading placeholder — an empty box at the page's known/estimated aspect ratio in the background colour (no spinner).
4. **Broken page tile** — `broken_image_outlined`, "Failed to load page", OutlinedButton "Retry" (re-requests that single page).
5. **Chapter seam** (96 px between chapters in a continuous feed): chapter title 12 px w600, tracking 1.6, muted #9AA8B4, flanked by 1 px rules (max 64 px) in vertical mode; rotated 270° in horizontal mode.
6. **Colour filter** over the page list (Sepia or Grayscale matrix) when set.
7. **Brightness/warmth overlay** — black at up to 184 alpha for dim, #FF8A00 at up to 92 alpha for warmth; pointer-transparent.
8. **iOS edge-back strip** (20 px on the leading edge, vertical mode only): drag ≥50 % of the width or fling ≥1 screen-width/s → leave the reader.

Chrome (auto-hides; slide + fade 220 ms easeOutCubic; auto-hide delay comes from the theme preset: 3000 ms on most presets, 1200 ms on one):
9. **Top bar** (floating glass capsule, radius `xl`, chrome blur, surface @ preset opacity, 1 px border, black @ 35 % shadow blur 18 + optional primary glow): IconButton `arrow_back_ios_new_rounded` "Back".
10. **Chapter title button** (tooltip "Go to series"): current chapter title `labelLg` w600 + `chevron_right_rounded` → series detail (pops if the series is directly beneath).
11. **IconButton** `bookmark_add_outlined` "Bookmark" (primary; saves the exact page + fraction).
12. **IconButton** `tune_rounded` "Reader settings" → reader settings sheet.
13. **Bottom bar** (same glass capsule): IconButton `skip_previous_rounded` "Previous chapter" (disabled @ muted 70 alpha when none).
14. **Page counter** "Page 7 / 40" (`labelSm` muted).
15. **Page scrubber** Slider (3 px track, 6 px thumb, 14 px overlay, one division per page, RTL-mirrored for right-to-left). Dragging seeks live; disabled for single-page chapters.
16. **IconButton** `skip_next_rounded` "Next chapter".
17. **IconButton** `tune_rounded` "More options" (same sheet).
18. **Edge prompt "Previous chapter"** (GlassCard pill with primary chevron) — appears at the reading start (top in vertical, bottom-left in horizontal), scale 0.9→1 easeOutBack 240 ms + fade 200 ms.
19. **Edge prompt "Next chapter"** — appears at the reading end (bottom 96 px up in vertical).

Reader settings sheet (`ReaderMoreSheet`; modal bottom sheet, drag handle, surfaceElevated, top radius `xl`, scroll-controlled):
20. **Prev / Next outlined buttons** (chevrons; disabled styling when unavailable).
21. **"Go to series" outlined button** (`menu_book_outlined`).
22. **SegmentedButton "Reading direction"**: Left to right | Right to left | Vertical.
23. **SegmentedButton "Fit mode"**: Fit width | Fit height | Fit screen.
24. **ChoiceChips "Refresh rate"**: Auto, 30 FPS, 60 FPS, 90 FPS, 120 FPS (Android display-mode switch; iOS no-op).
25. **Tap zones picker**: "Tap zones" label + TextButton "Reset" (when custom), helper copy "What each side of the page does when tapped. Mirrors automatically for a right-to-left series until you set your own.", three rows Left / Center / Right each a SegmentedButton Previous | Toggle | Next.
26. **Slider "Brightness"** (0.2–1.0) with `brightness_low` / `brightness_high`.
27. **Slider "Warmth"** (0–1) with `nightlight_round` / `wb_sunny_outlined`.
28. **ChoiceChips "Page background"**: Dark, AMOLED, Paper.
29. **ChoiceChips "Color mode"**: Normal, Sepia, Gray.
30. **Zoom row**: IconButton `remove` "Zoom out", TextButton.icon `restart_alt` "<zoom>%" (reset), IconButton `add` "Zoom in" (0.5x–3.0x, 0.1 steps).
31. **Switch "Auto-scroll"** (`play_circle_outline`).
32. **Slider "Speed: Slow/Medium/Fast"** (30 / 60 / 120 px/s, 2 divisions; only while auto-scroll is on).
33. **TextButton.icon "Save bookmark"** (`bookmark_outline`).

Feedback:
34. **Snackbar (floating)** "Bookmarked page 7 — 42% of the chapter" / "Bookmarked page 7".
35. **Snackbar (floating)** "Reader unlocked" (2 s) after five centre taps while locked.
36. **Snackbar (floating)** "This chapter changed — opened at page N instead of M." (stale bookmark anchor).
37. **Haptics**: selection on page turn and auto-next, light on bookmark / double-tap zoom / chapter nav, medium on unlock.

States:
38. **State: loading** — ReaderSkeleton on #0A0A0A: three 360 px skeleton pages (max 420 wide, radius `lg`) + "Loading chapter…".
39. **State: error** — `error_outline` 40 px #EF4444, message in #DDE4EA, FilledButton "Retry", TextButton "Go back".
40. **State: empty chapter** — the same error panel with "This chapter has no pages."
41. **State: offline** — silently reads from downloaded pages (whole chapter on disk, or per-page local overlay on a network manifest); if the network fails and the chapter is on disk it opens offline with no neighbours.

Gestures (details in section 6): tap zones, double-tap zoom toggle (1.0x ⇄ 2.0x within 280 ms), five-tap unlock, drag-scroll hides chrome, scrubber drag, iOS edge swipe back, Android volume keys page (opt-in), hardware keys H/L/B/+/-/0.
### S16 Sources (tab 1) — `/sources` (`SourcesListScreen`)

Purpose: every installed connector (`GET /sources`), pinned ones first (`GET/PUT /sources/pins`), filtered by content mode and the active profile's 18+ setting (the server omits mature sources for profiles without it).

1. **HeroHeading** "Sources" (40 px) — no app bar; SafeArea top.
2. **ContentModeSwitch** (Manga | Novels) under the heading.
3. **Pinned filter bar** (SliverPersistentHeader, 48 px field + 34 px pills, `bg`-filled so it covers scrolled rows):
4. **TextField "Filter sources…"** — `search` prefix, fg @ 3 % fill, radius `xl`, primary @ 30 % focused border, **IconButton clear** `close` when non-empty. Filters by name or id locally.
5. **FilterPill "All"**, **FilterPill "Pinned" + count**, **FilterPill "18+"** (34 px, full radius, selected = primary fill).
6. **SectionHeader** with icon — `push_pin` "Pinned", `travel_explore` "Sources" / "All sources".
7. **Source row card** (`SourceRowCard`, Pressable; surface fill, radius `lg`, 1 px border): 44 px **SourceLogo** (favicon from the connector or a hard-coded map, radius `md`, surface2 + glassEdge border; fallback letter avatar on a surface2→panel gradient with the initial in violet-400), name `bodyLg` w600, 1-line description, **"18+" badge** (danger @ 28 fill, danger @ 90 border, `labelSm` w700).
8. **Pin IconButton** (44 px target, `push_pin` primary / `push_pin_outlined` muted; tooltip "Pin <name>" / "Unpin <name>").
9. **Snackbar** "<name> pinned" / "<name> unpinned" (2 s) or a danger-coloured error snackbar.
10. **Unavailable pinned row** — 55 % opacity logo, muted name, "Unavailable on this profile", not tappable (a pin whose source the current profile cannot see; manga mode only).
11. **Row entrance** — FadeIn with 40 ms stagger for the first 8 rows, 12 px upward offset.
12. **State: loading** — 8 SourceRowSkeletons (44 px box + 140x14 + 90x10 bars).
13. **State: error** — danger text ("Failed to load sources.") + FilledButton "Retry".
14. **State: none installed** — EmptyState `public_off` "No sources installed" / "No novel sources installed".
15. **State: no match** — EmptyState `search_off` "No pinned sources" / "Tap the pin on any source to keep it at the top." or "No sources match" / "Try a different name."
16. **Pull-to-refresh** (sources + pins).

Tap row → `go('/sources/:sourceId')`.

### S17 Source browser — `/sources/:sourceId` (`SourceBrowserScreen`)

Purpose: browse or search one connector's catalogue (`GET /sources/:id/browse-modes`, paged `GET /sources/:id/series?sort=&search=`).

1. **AppBar**: IconButton `arrow_back_ios_new_rounded` 20 px (pop or go `/sources`), title row = 28 px SourceLogo + source name in `h4` primary.
2. **AppBar bottom search field** "Search series…" (`search` prefix; suffix IconButton `arrow_forward` submit, or `close` clear when a search is active). 300 ms debounce; submit on enter.
3. **Browse-mode ChoiceChips** (horizontal, 44 px strip, compact): e.g. Popular / Latest / … as returned by the connector; hidden while searching.
4. **Result count caption** "<n> series" / "<n> book(s)".
5. **Dense series card grid** (3 columns base, aspect 0.56, 4 px spacing; surface fill, radius `md`, border): cover (flex 6) + 1-line 10 px title. `ScrollReveal` stagger.
6. **Novel shelf rows** instead of the grid for novel sources (serif title, byline, chapter count, status, blurb, plate).
7. **Load-more spinner** (infinite scroll 600 px before the end).
8. **"Top" pill** (floating bottom-right above the nav bar; panel @ 90 %, border, `keyboard_arrow_up` + "Top"); appears after 400 px, animates to 0 over 400 ms easeOut.
9. **Opening state** (loading): 72 px SourceLogo, "Opening <source>…" in `h4`, 28 px primary spinner (stroke 2.5).
10. **State: empty** — EmptyState `search_off` "No series found" / "This source returned no browse results." or "No results for "<q>"" / "Try a different search term."
11. **State: error** — danger text ("Failed to load source series.") + FilledButton "Retry".
12. **AnimatedSwitcher** between loading/error/empty/data (450 ms, easeOut in / easeIn out).
13. **Haptic** light tick when a load finishes.
14. **Pull-to-refresh**.

Tap card → `go('/sources/:sourceId/series/:seriesId')`.

### S18 Source series detail — `/sources/:sourceId/series/:seriesId` (`SourceSeriesDetailScreen`)

Purpose: the canonical series page (`GET /sources/:id/series/:sid` + `/chapters`), reached from almost everywhere (library home, history, stats, search, recommendations, collections, updates). Renders one of two completely different bodies depending on the source's content kind.

Common:
1. **AppBar**: IconButton back `arrow_back` (pop or go the source browser), title = series title or "Series".
2. **State: loading** — plain centered CircularProgressIndicator.
3. **State: error** — danger text "Failed to load series." + FilledButton "Retry".

Manga body (same `SeriesDetailBody` layout as S10):
4. **Cover** (full width 2/3, radius 12, panel fill when missing).
5. **Title** `displayMd`, **author**, **"Art by <artist>"** caption, **meta line** "Latest: … · N chapters" in primary.
6. **Description**.
7. **PrimaryPillButton** "Read Online" (`menu_book_outlined`) / "Continue" (`play_arrow_rounded`) / "All caught up" (`done_all_rounded`, disabled).
8. **ReadAllButton** "Read all" → `?all=1` source reader from the continue point.
9. **SeriesFollowButton** (Follow / Unfollow / Following… / Unfollowing…) + snackbars.
10. **"Select" chapter multi-select** + selection bar (Next 10, All unread, All, None, Download N, Cancel).
11. **"Download Series" button**.
12. **Series download progress card** (as S10 #13).
13. **Status + genre chips** (status chip in primary, uppercase).
14. **Chapters header + Newest/Oldest toggle**.
15. **Chapter tiles** with Reading pill, page progress, release date ("chapterDateLabel"), download status line/bar, checkbox in selection mode, trailing download control. Tap → `go` source reader.
16. **State: no chapters** — EmptyState "No chapters available" / "This source did not return any chapters for this series."

Novel body (`NovelSeriesDetailView`, a book "front matter" + table of contents):
17. **Serif title** 27 px w600 + meta "by Author · N chapters · Status" 13 px muted.
18. **Cover plate** 76x112, radius `md` (right of the title).
19. **Length estimate line** "~1.2M words · ~80 h estimated from 12 chapters".
20. **PrimaryPillButton** "Start reading" / "Continue" / "All caught up" → push novel reader at the resume bucket.
21. **SeriesFollowButton** (expanded) + **"Download book" OutlinedButton** side by side.
22. **Audiobook button** (full-width OutlinedButton.icon `graphic_eq_rounded`): labels "Make audiobook", "Make audiobook · N done", "Making audiobook · N in progress, N waiting", "Make audiobook · N waiting for the narration PC", "Audiobook · N narrated". Opens the Audiobook picker sheet (N3).
23. **Narration unavailable note** "Narration of new chapters is not available right now." (when rendering is off).
24. **Serif blurb** 15 px / 1.6.
25. **Genre tags** (11 px muted, hairline border, radius `sm`).
26. **"CONTENTS" label** (11 px, tracking 2, w700 muted).
27. **IconButton** `search_rounded` "Go to chapter" → Contents sheet in search mode (N2) (only with >1 chapter).
28. **Newest/Oldest toggle** (defaults to Oldest here).
29. **TOC row**: 40 px serif ordinal (tabular), serif title 15 px 2 lines, meta "3.4k words · 42% in · Audio saved" / "Read"; read rows muted; trailing download control. Tap → push novel reader.
30. **State: no chapters** — "This source did not return any chapters for this book."
### S20 Search (tab 2) — `/search` (`SearchScreen`)

Purpose: federated search across every installed source plus the local library (`GET /sources/search?q=&page=&per_page=`, grouped per source with a per-source retry). Content-mode aware.

1. **HeroHeading** "Search" (40 px, FadeIn) + **ContentModeChip** on the right (no app bar).
2. **Search TextField** "Search manga, manhwa, webtoons…" (`search` prefix, fg @ 3 % fill, radius `xl`, 300 ms debounce, submit on enter).
Idle (no query):
3. **Section label "RECENT"** (`history` 14 px cyan-400, uppercase tracking 1.5) + **recent search ActionChips** (max 4, per profile, persisted after a search that returned results).
4. **Section label "TRENDING"** (`trending_up`) + fixed ActionChips: fantasy, romance, action, manhwa, manga, webtoon, horror, sci-fi.
5. **OutlinedButton.icon "Advanced Filters"** (`tune`) — currently a no-op (its toggle callback is empty); the explanation panel it would open ("Search matches titles, authors, and descriptions in your local library…") never shows.
6. **Idle panel** (panel fill, radius `xl`): `search` 32 px, "Start typing to search", "Search across titles, authors, and descriptions in your library."
With a query:
7. **Status line** "Searching sources…" → "N results found · N sources" + warning caption "Some sources unavailable" when any failed.
8. **Group filter pills** (FilterPill with counts): All, With results, Pinned.
9. **Source section header**: 28 px SourceLogo (or a primary-tinted `bookmark_outline` tile for the local "Library" group), source name `labelLg` w600, **count badge** pill.
10. **Result shelf** — horizontal list 200 px tall of 112 px **GlobalSearchResultGridCard** (surface fill, radius `md`, border; cover flex 6 + 2-line 10 px title; source badge hidden here). Tap → library detail (local hit) or source series detail.
11. **Section note — failed source** (`cloud_off` 14 px danger + message "This source did not answer." + TextButton "Retry").
12. **Section note — no matches** (`search_off` muted "No matches").
13. **Section retry skeleton** (4 x 112x200 boxes) while retrying one source.
14. **Note card "No sources in this view"** (`filter_alt_off`): "Pin a source on the Sources tab to keep it here." / "Switch back to All to see every source that answered."
15. **Empty panel** "No results found" / "Try a different search term or clear filters." (LibraryEmptyPanel).
16. **Loading skeleton** — 3 x (28 px logo box + 120x14 bar + a 4-card shelf).
17. **Load-more spinner** (infinite scroll 320 px before the end → next page of every source).
18. **State: error** — `error_outline` 48 px, "Search failed", message, PrimaryPillButton "Try Again" (`refresh`).
19. **Pull-to-refresh**.
20. **Source badge** component (used in grid/list card variants elsewhere): "LIBRARY" cyan-400 with `bookmark_outline`, or "<SOURCE>" violet-400 with `public`, 8–10 px w700 uppercase.

Cross-screen: Recommendations' "Search" button pre-fills this screen's query (`searchQueryProvider`) and switches to this tab. Dead code present: `SearchToolbar` and `SearchResultCard` widgets are defined but not used by any screen.
### S21 Downloads (tab 3) — `/downloads` (`DownloadsScreen`)

Purpose: the offline library and the client-side download queue for the active `(user, profile)` scope. Everything here is local (SQLite store + blob files); nothing is fetched except by the queue itself. Tab icon carries a live count badge (G1).

1. **AppBar** "Downloads" + **ContentModeChip**.
2. **TabBar**: "Chapters" | "Storage" (primary label + indicator, muted unselected).
3. **State: no scope** — EmptyState `person_outline` "No active profile" / "Choose a reading profile to see its downloads." (no tabs).

Chapters tab:
4. **OCR run banner** (GlassCard; only while an OCR run exists): icon + message per phase — recognizing "Extracting text — page 3 of 40" (`text_fields` primary), paused "Text extraction pauses while the app is in the background — keep it open to continue." (`pause_circle_outline` warning), uploading "Uploading the transcript…" (`cloud_upload_outlined`), done "Text extracted — N words are now searchable." (`check_circle_outline` success), cancelled (`cancel_outlined` muted), failed (`error_outline` danger); TextButton "Cancel" while busy; 3 px progress bar while recognizing/paused.
5. **Active downloads panel** (GlassCard, glow primary or warning when blocked; hidden when idle):
6. — **Header**: `downloading_outlined` / `pause_circle_outline` + "Downloading" / "Waiting to start" / "Paused" (`h4`).
7. — **IconButton pause/resume** `pause` / `play_arrow` ("Pause downloads" / "Resume downloads").
8. — **IconButton cancel all** `clear_all` "Cancel all downloads".
9. — **Dialog "Cancel all downloads?"** "Everything still queued, downloading or failed is dropped. Chapters already finished stay on your phone." TextButton "Keep them" / TextButton "Cancel all" (danger).
10. — **Current chapter block**: series name, "Chapter 12 · page 7 of 40" (or "reading chapter details…", novels "fetching/saving the text…", audio "fetching/saving the audio…"), 6 px progress bar, "N more chapters downloading alongside this one", "X of Y chapters saved in this series".
11. — **Pause reason notice** (`info_outline` warning + copy): user paused "Paused by you. Nothing was lost — resuming carries on from the page it stopped at."; free-space floor "Paused because this phone is almost full. Downloads stop before the last ~1.5 GB…"; storage cap "Paused because downloads have filled your 10 GB limit. Raise the limit or free up space in Downloads → Storage."
12. — **OutlinedButton "Storage settings"** (cap pause; jumps to the Storage tab) / **FilledButton.icon "Resume"** (user pause).
13. — **Queue summary** "N in the queue · N failed" (danger when failures) + **TextButton.icon "Show queue" / "Hide queue"**.
14. — **Foreground-only note** (caption).
15. **Queued chapter rows** (expanded): dense ListTile, `schedule` / `error_outline` leading, "<series> · Chapter 12", "Waiting in the queue" / "Downloading" / "Failed — <error>", **IconButton `refresh` "Retry"** (failed only), **IconButton `close` "Remove from queue"**.
16. **"Where it lives" info card** (`info_outline`, fg @ 5 % fill): "Downloaded chapters are stored inside ManhwaManiacs and read offline straight from this tab — there is nothing to find in the Files app. For a copy you can open elsewhere, use Save to Files on a series or chapter."
17. **Section caption** "On this phone — biggest first" (`labelSm`, tracking 1.0).
18. **Series download card** (GlassCard, tap header to expand): title, subtitle "40 chapters · 3 with audio · 1.2 GB" or "12 of 40 chapters saved · 800 MB".
19. — **IconButton pin** `push_pin` / `push_pin_outlined` "Pin series" / "Unpin series" (pinned series are exempt from auto-delete).
20. — **PopupMenuButton** `more_vert` "Series options": "Save to Files…", "Remove all downloads".
21. — **Expand chevron** `expand_more` / `expand_less`.
22. — **Dialog "Remove downloads?"** "Deletes every downloaded chapter of <series> from this phone. Your reading progress is kept, and you can download them again any time." TextButton "Keep" / "Remove" (danger).
23. **Downloaded chapter row** (dense ListTile inside an expanded card): `headphones_rounded` leading for narration audio rows, "Chapter 12" or "Chapter 12 · audio", "Downloaded · 24.3 MB" / "Queued" / "Downloading…" / "Failed — …"; tap (complete only) → manga reader or novel reader.
24. — **OCR IconButton** (`text_fields` muted "Extract text (OCR)" / `text_snippet` success "Text already extracted — tap to redo"; 16 px spinner on the chapter being processed; manga, complete, OCR enabled only).
25. — **IconButton `save_alt` "Save to Files"** (complete manga chapters).
26. — **IconButton `delete_outline` "Remove download" / "Remove saved audio"** (no confirmation).
27. **Save to Files sheet** (modal, surfaceElevated): "Save to Files" + explanation; ListTile "Page images" (`photo_library_outlined`, "A numbered folder per chapter. Tap any page to view it."); ListTile "CBZ file" (`folder_zip_outlined`, "One file per chapter, for comic reader apps.").
28. **Export progress dialog** (non-dismissible): 20 px spinner + "Saving to Files…".
29. **Export result dialog** "Saved to Files" / "Nothing to save": "N chapters · N pages", selectable path in primary ("Files → On My iPhone → ManhwaManiacs → Exports → <series>" on iOS, the directory path on Android), skipped-count note, TextButton "Done".
30. **Snackbars**: "Nothing to save yet — these chapters are still downloading.", "Could not save to Files. Check your free space."
31. **State: loading** — centered spinner. **State: error** — "Could not load downloads." (danger).
32. **State: empty** — EmptyState `download_outlined` "No downloads yet" / "Chapters you download for offline reading show up here." (novel: "No books downloaded" / "Chapters you download read offline, text and all.").

Storage tab (`DownloadsStorageCard`, also used on S32):
33. **Header** `download_done_outlined` "Downloaded chapters" + explanation ("…Deleting a chapter here never rewinds your reading progress…").
34. **Usage line** "1.2 GB of 10 GB used" / "1.2 GB used" (`h3` + muted), 120x20 skeleton while loading, "Unable to read download usage" on error.
35. **ChoiceChips "Storage cap"**: 2 GB, 5 GB, 10 GB (default), 20 GB, Unlimited.
36. **ChoiceChips "Chapters at once"** + explanation: 1 chapter, 2 chapters (default), 3 chapters.
37. **ChoiceChips "Auto-delete after reading"** + explanation: Off, 24 hours, 48 hours (default), 7 days.
38. **Platform note**: iOS "Browse, copy or delete downloaded chapters from the Files app: On My iPhone → ManhwaManiacs." (`folder_open_outlined` box) / Android "Files live in the app's private storage. A folder picker for Android is planned but not in this build."
39. **"By series" breakdown rows** (pin icon for pinned, title, "N ch · 240 MB"); 60 px skeleton while loading.
40. **OutlinedButton "Free up space"** → snackbar "Nothing to free up right now." / "Removed N chapter(s)."
### S22 More (tab 4) — `/more` (`MoreScreen`)

Purpose: hub for everything that is not a tab.

1. **AppBar** title "More" + **ContentModeChip** action (opens the reading-mode sheet, G5).
2. **Section header** (uppercase `labelSm`, tracking 1.0, muted): DISCOVER, ACCOUNT, LIBRARY, APP, ABOUT.
3. **Row "Updates"** (`notifications_outlined`, amber) + **unread badge** (primary pill with count) → push `/updates`.
4. **Row "Collections"** (`collections_bookmark_outlined`) → push `/collections`.
5. **Row "Switch profile"** (`person_outline`) → push `/profiles`.
6. **Row "Reading History"** (`history_outlined`) → go `/library/history`.
7. **Row "Bookmarks"** (`bookmark_outline`) → go `/library/bookmarks`.
8. **Row "Statistics"** (`bar_chart_outlined`) → go `/library/statistics`.
9. **Row "Recommendations"** (`auto_awesome_outlined`) → go `/library/recommendations`.
10. **Row "Settings"** (`settings_outlined`) → push `/settings`.
11. **Row "Storage"** (`storage_outlined`) → push `/settings/storage`.
12. **Row "Dialogue Search"** (`text_fields_outlined`) → push `/ocr/search`; only when OCR is enabled and content mode is manga.
13. **Row "Backup & Restore"** (`backup_outlined`) → push `/settings/backup`.
14. **Update-available banner** (Android APK channel only): GlassPanel with amber→rose wash, `system_update_outlined` "Update available", "Installed vX (build N)" / "Available vY (build M)" rows, FilledButton.icon "Download update" (`download_outlined`), two caption notes ("Downloading does not install automatically…", "Updating from 1.2.x? Uninstall the old app first.").
15. **Dialog "Install now"** after launching the download: `install_mobile_outlined` title, three numbered amber step circles, TextButton "Got it".
16. **Snackbar** "Could not open: <url>" when the browser cannot launch.
17. **Row "What's New"** (`new_releases_outlined`) → What's New sheet (M4).
18. **App info tile**: 40 px amber→rose gradient "M" tile, "ManhwaManiacs", "v<version> (<build>)", chevron → push `/settings`.

Each row: ListTile with amber leading icon 22 px, `labelLg` title, trailing `chevron_right` 18 px muted, radius `md`.
### S23 Updates — `/updates` (`UpdatesScreen`)

Purpose: new-chapter notifications and the follow list. Data: `GET /updates/notifications`, `GET /updates/notifications/unread-count`, all pages of `GET /library/series` (the follow cache shared app-wide as `updatesProvider`).

1. **AppBar** (bg-filled): IconButton back `arrow_back` "Back" (pop or go `/more`), title "Updates" (`h3`), **ContentModeChip**, **IconButton `refresh` "Check now"** (primary; disabled while a check runs).
2. **HeroHeading** "Updates" (40 px, FadeIn) + "<n> unread · <n> followed series|books".
3. **PrimaryPillButton** "Check all now" / "Checking…" (`sync`) → `POST /updates/check`, then polls unread count at 3 s, 5 s, 7 s.
4. **GhostPillButton** "Mark all read" / "Mark all manga read" / "Mark all novels read" (`done_all`; only with unread).
5. **Section header** (3x18 px primary bar + `h3` title): "Notifications", "Followed series".
6. **Notification card** (GlassCard): series title (or chapter title), **"NEW" badge** (primary @ 20 % fill, 45 % border) when unread, chapter title (or source id), timestamp "Sep 28, 2026 9:41 PM", **TextButton "Mark read"** (unread only). Tap → marks read + push the manga or novel reader at that chapter.
7. **Followed series card** (GlassCard): title, **source-id pill badge**, "N chapters" / "Not checked yet", **TextButton "Unfollow"** (danger; disabled while an action is pending; no confirmation).
8. **Empty notifications** — EmptyState `notifications_none` "No update notifications" / "Follow series to get notified of new chapters."
9. **Empty follows** — EmptyState `rss_feed` "No followed series" / "Follow series from sources to monitor new chapters."
10. **State: loading** — skeleton (200x44 + two 100 px boxes).
11. **State: error** — `error_outline` 48 px, message, PrimaryPillButton "Retry" (`refresh`).
12. **Snackbar** with the error message when any action fails.
13. **Pull-to-refresh**.

Not surfaced in the UI although the repository supports it: update settings (`GET/PUT /updates/settings`: enabled, check interval minutes, notify enabled, check on startup), run history (`GET /updates/runs`), per-series check (`POST /updates/followed/:id/check`).

### S24 Collections — `/collections` (`CollectionsScreen`)

Purpose: user-made shelves (`GET/POST /library/collections`).

1. **AppBar**: back (pop or go `/more`), title "Collections", **IconButton `add` "New Collection"**.
2. **FloatingActionButton.extended** "New" (`add`).
3. **HeroHeading** "Collections" + "N collection(s)" / "Organize your library into custom collections."
4. **Search TextField** "Search collections…" (`search` prefix; local filter by name/description).
5. **Sort chip** (Chip with `sort` avatar) opening a **PopupMenu**: Name A–Z, Most series, Custom order.
6. **Collection banner card** (21:9, radius `xl`, border @ 80 alpha): cover image (network) or gradient fallback (primary @ 40 % → panel → accent @ 20 %) with giant faint initials (`displayMd`, white @ 10 %, tracking 8); left-to-right bg scrim + bottom scrim; name `h3` white, 1-line description, `menu_book_outlined` "N series".
7. **Dialog "New Collection"** (CollectionFormDialog): TextField "Name" (hint "My Reading List"), TextField "Description" (2 lines, "Optional description"), inline danger error, TextButton "Cancel", FilledButton "Create" / "Saving…" (disabled while name empty).
8. **State: loading** — 4 x 140 px skeletons radius `xl`.
9. **State: empty** — EmptyState `collections_bookmark_outlined` "No collections yet" / "Create collections to group your series by theme, mood, or reading list." + FilledButton.icon "Create your first collection".
10. **State: no match** — EmptyState `search_off` "No collections match your search" / "Try a different term or clear the search."
11. **State: error** — danger text + FilledButton "Retry".
12. **Pull-to-refresh**.

Tap banner → push `/collections/:id`.

### S25 Collection detail — `/collections/:collectionId` (`CollectionDetailScreen`)

Purpose: one collection's members (`GET /library/collections/:id`), filtered by content mode.

1. **AppBar**: back (pop or go `/collections`), title = collection name ("Collection" while loading), **ContentModeChip**.
2. **Hero banner** (220 px): cover (explicit or the first member's cover) or gradient; vertical scrim bg @ 40 % → 80 % → bg; name `displayMd`, 2-line description, `menu_book_outlined` accent + "N series".
3. **OutlinedButton.icon "Add Series"** (`add`).
4. **OutlinedButton.icon "Rename"** (`edit_outlined`) → CollectionFormDialog "Rename Collection" / "Save".
5. **TextButton.icon "Delete"** (`delete_outline`, danger).
6. **Dialog "Delete collection?"** "Series will not be removed from your library." Cancel / FilledButton "Delete" (danger). On success pops; on failure snackbar.
7. **Member tile** (panel fill, radius 12): 44x66 cover, series key as title (no human title in this payload), source id caption, **IconButton `remove_circle_outline` "Remove from collection"** (danger). Tap → source series detail.
8. **Dialog "Remove series?"** "This series will be removed from the collection but stay in your library." Cancel / FilledButton "Remove".
9. **Add Series dialog** ("Add Series to Collection"): search TextField "Search series…", 320 px list of followed series not already in it (36x54 cover + title; tap adds and closes), spinner / danger error / "No series available." / "No series match your search.", TextButton "Close".
10. **State: loading** — 220 px banner skeleton + 6 grid skeleton tiles.
11. **State: empty** — EmptyState `menu_book_outlined` "This collection is empty" / "Add series from your library to start building this collection." + FilledButton.icon "Add series".
12. **State: error** — danger text, FilledButton "Retry", OutlinedButton "Back to collections".
13. **Pull-to-refresh**.
### S26 Novel reader — `/novels/read/:sourceId/:seriesKey/:chapterKey` (`NovelReaderScreen`)

Purpose: the text reader for web novels with TTS narration follow-along. Data: `GET /novels/chapter` (or the downloaded text), `GET /novels/audio` (audio manifest + timing), `GET /novels/audio/file` (streamed opus/m4a with bearer header), `GET /novels/attribution`, `GET /novels/voices`. Query: `?page=` (progress bucket 1–100), `?para=` + `?at=` (bookmark paragraph + fraction). Root navigator, immersive fade 280/220 ms, immersive system UI; Android back is intercepted (PopScope) to leave via the series page when nothing is beneath.

Page:
1. **Page surface** — colours from the chosen novel palette (12 palettes + "App theme"; default Dusk #1E1B18 / ink #D6D0C6 / muted #8A8078 on a dark app), `Scrollbar` on the right.
2. **Chapter heading**: "CHAPTER 12" (12 px, tracking 2.4, w600 muted), title in the body face at 1.55x the body size w600, 48 px hairline rule, word count ("3.4k words") muted.
3. **"Listen to this chapter · 14 min · saved" OutlinedButton** (`headphones_rounded`, ink foreground, rule border) — only when audio exists; tapping reveals the chrome (which holds the player).
4. **Audio-only note** (when the audio cannot follow the text, e.g. a mismatch) under the button.
5. **Paragraph text** — centred column of width = measure (48–88 ch), body 15–26 px, line-height 1.4–2.1, letter-spacing 0.1, first-line indent 1.4 em (flush after headings/scene breaks).
6. **Drop cap** on the first paragraph (2.6x size, w600; only when the paragraph is ≥80 chars).
7. **Scene break ornament** (e.g. "* * *"; 0.9x size, muted, tracking 0.35 em, 1.6 em vertical padding).
8. **Speech highlight** while narrating: spoken text gets ink @ 5 % background, the current phrase ink @ 15 %; the view auto-scrolls the spoken paragraph to the reading line (25 % down) over 260 ms easeOut unless the user is scrolling.
9. **Chapter foot**: 48 px rule + OutlinedButton "Next chapter" (24x14 padding), or "End of the downloaded copy" / "End of the book, for now".

Chrome (tap anywhere toggles; fade 180 ms easeOut; bars are solid page-coloured with a hairline rule, 52 px tall):
10. **Top bar**: IconButton `arrow_back` "Back", chapter title (15 px w600), **offline indicator** `cloud_off_rounded` (when reading a downloaded copy).
11. **IconButton `toc_rounded` "Contents"** → Contents sheet (N2).
12. **IconButton `bookmark_add_outlined` "Bookmark this spot"** (disabled while saving) — anchors to the paragraph under the reading line plus the fraction within it and stores a 180-char snippet.
13. **IconButton `record_voice_over_outlined` "Voices"** → Cast panel (N4).
14. **IconButton `text_fields_rounded` "Text and page"** → Type panel (N1).
15. **Audio player bar** (above the bottom bar, when audio exists): bordered radius 10 box; IconButton play/pause (`play_arrow` / `pause` / `error_outline` when it failed; tooltips "Listen to this chapter" / "Pause" / "Audio could not be loaded"); seek Slider; "m:ss / m:ss" tabular 11 px; speed DropdownButton 0.75x, 1x, 1.25x, 1.5x, 1.75x, 2x.
16. **Narration save button** (next to the player): `download_for_offline_outlined` "Save audio to this phone" → 18 px spinner "Saving audio to this phone…" → `download_done_rounded` "Audio saved on this phone" (tap → Dialog "Remove saved audio?" "The chapter stays on this phone to read. You can save its audio again any time." Keep / Remove) / `error_outline_rounded` failed "…tap to try again" / `sync_problem_rounded` "The saved audio cannot play on this phone — tap to save it again".
17. **Bottom bar**: IconButton `chevron_left_rounded` "Previous chapter", centred progress "42%" (tabular, muted), IconButton `chevron_right_rounded` "Next chapter" (disabled ones drawn in the rule colour).

Feedback and states:
18. **Snackbar (floating)** "Bookmarked at 42% of this chapter" / "Bookmark saved".
19. **Snackbar (floating)** "This chapter changed — opened at paragraph N instead of M."
20. **Snackbar** "That voice could not be saved. <error>".
21. **State: loading** — full Dusk-coloured screen with a muted spinner.
22. **State: error / no text** — ReaderErrorState ("This chapter has no text.") with Retry / Go back.
23. **Auto-next** — when the reader reaches the end (and auto-next is on, and narration is not playing), the next chapter opens after 900 ms.

#### N1 Type panel ("Text and page", `NovelTypePanel`) — modal bottom sheet in the page colour, black @ 40 % barrier, top radius `xl`, 36x4 grabber
- **Face toggle**: two tiles "Serif" / "Sans", each set in its own face (serif stack: Iowan Old Style, Charter, Bitstream Charter, Georgia, Palatino, Noto Serif, Tinos, Times New Roman; sans stack: SF Pro Text, Roboto, Helvetica Neue, Noto Sans); selected = ink @ 10 % fill + ink border.
- **Stepper "Text size"** 15–26 px, step 1 (default 19), 36 px round − / + buttons, value tabular.
- **Stepper "Line spacing"** 1.40–2.10, step 0.05 (default 1.75).
- **Stepper "Line width"** 48–88 ch, step 2 (default 68).
- **"PAGE" label + palette swatches** (each swatch rendered in its own bg/ink, 2 px ink outline when chosen): Paper #F5F1E8/#2A2622, Sepia #F4ECD8/#5B4636, Solarized light #FDF6E3/#4A5C62, Soft grey #E9E9E7/#2F2F2E, Cream #FBF7EF/#33302B, Dawn #FAF4ED/#575279, Dusk #1E1B18/#D6D0C6, Midnight #0F1419/#C5CDD6, True black #000000/#B8B5AF, Solarized dark #002B36/#A1ADAD, Forest #1E2326/#C5CDD0, Rosé Pine #191724/#E0DEF4, plus "App theme".
- Typography is saved **per series**; the palette is saved per profile.

#### N2 Contents sheet (`NovelContentsSheet`) — 85 % height modal, page-coloured (or app surface when opened from the series page)
- **"CONTENTS" label + "Go to chapter" TextField** (`search_rounded`, autofocused when opened from the series page's search button; enter jumps to the first match).
- **Chapter list** (52 px rows, oldest first, pre-scrolled to the current chapter): 48 px tabular ordinal + title; current row ink @ 7 % fill and w600.
- **Match list** when typing a number (max 30 + "and N more"), "Type a chapter number.", "No chapter N in this book."
- **Loading spinner** / "The contents need a connection to load."

#### N3 Audiobook picker sheet (`AudiobookPickerSheet`) — opened from the novel series page
- **Header** "Audiobook" + TextButton "Close".
- **SegmentedButton**: "Narrate" (`graphic_eq_rounded`) | "Save to phone" (`download_for_offline_outlined`) (only when rendering is possible and a downloads scope exists).
- **Unavailable note** "Narration of new chapters is not available right now. Chapters that already have audio can be saved to this phone."
- **ActionChips**: "Next 10" (narrate only), "All un-narrated (N)" / "All narrated (N)", "None".
- **CheckboxListTile per chapter** — narrate mode subtitles "Already narrated · saved on this phone", "Already narrated", "Download the text first" (`headphones_rounded` secondary when narrated); save mode subtitles "Saved on this phone", "Saved copy cannot play on this phone — select to save again", "Saving…", "Could not be saved — select to retry", "Narrated", "Not narrated yet".
- **Estimate caption** "About N minutes of rendering on the PC." (9 min per chapter) or "Saves while the app is open. The text is saved too, so the chapter plays and follows along offline."
- **FilledButton.icon** "Make audiobook of N chapters" (→ `POST /novels/audio/render`) / "Save audio of N chapters" (→ download queue) / "Select chapters".
- **Snackbars**: "Queued N chapters for narration. Skipped: 2 already narrated, 1 not downloaded to the server yet." / "Nothing to narrate." / "Saving the audio of N chapters to this phone."
- Job status is polled every 5 s (15 s while every job is only waiting for the render PC; exponential back-off to 60 s on failures).

#### N4 Voices / cast panel (`NovelCastPanel`) — 85 % max-height sheet in the page colour
- **"Voices" label**; status copy "Looking up who speaks here…", "Nobody has been identified in this chapter yet, so it is read by the narrator throughout.", "Narrated by <name> — their own lines are read in the narrator's voice…".
- **Cast row "Narration"** → current voice name or "default voice", chevron; expands a picker.
- **Cast row per character** (name → voice name / "Automatic" / "voiced").
- **Voice picker** (bordered box): "A voice for <name>", helper "Press a name to hear it introduce itself. Chapters already rendered keep the voice they were made with.", row "Default voice" / "Automatic voice", then **Male** and **Female** groups of the 31 named voices; each row: play/pause glyph + name, detail "<character> · 180 Hz" (or "No preview available"), TextButton "Use" / "Chosen". Tapping a name streams `GET /novels/voices/sample`; "Use" posts `POST /novels/narrator` or `POST /novels/cast`.
- **No-voices note** "No voices are installed on the server, so characters cannot be cast from here yet."
### S27 Dialogue search — `/ocr/search` (`OcrSearchScreen`)

Purpose: full-text search over OCR'd chapter dialogue (`GET /ocr/search?q=&limit=&offset=`). Only visible when the on-device OCR engine is available (Android ML Kit / iOS Vision via a method channel) and content mode is manga. Text is extracted on the phone from downloaded chapters (Downloads → chapter row OCR button) and uploaded with `POST /ocr/chapter`.

1. **AppBar**: IconButton back "Back" (pop), title "Dialogue search".
2. **Search TextField** "Search text inside chapters" (`search` prefix, outlined radius `lg`, autofocus, 350 ms debounce, submit on enter).
3. **Idle state** — EmptyState `text_fields` "Search chapter dialogue" / "Finds words inside chapters whose text has been extracted, across the series you follow."
4. **Loading** — centered spinner.
5. **Error** — danger text "Search failed — check your connection and try again."
6. **No matches** — EmptyState `search_off` "No matches" / "Only chapters you have extracted text from, in series you follow, can be searched."
7. **Result card** (GlassCard): series key (`labelLg`), "<source> · <chapter key>" caption, snippet (4 lines, `bodySm` muted with matched words in primary w600). Tap → manga reader at that chapter (page 1; no jump to the matching page).

### S28 Settings — `/settings` (`SettingsScreen`)

Purpose: all app preferences. Four tabs.

1. **AppBar**: back (pop or go `/more`), title "Settings", **IconButton `search` "Search settings"**.
2. **Scrollable TabBar** (start-aligned): General | Server | About | Debug.
3. **Section heading** (3x15 px primary bar + uppercase 14 px w600 tracking 2).
4. **Settings search** (full-screen `SearchDelegate`, field label "Search settings"): back arrow, clear `clear` action, list of 21 indexed settings (label + keywords subtitle, Android-only rows hidden on iOS); tap switches to that tab. Empty: "No matching settings".

General tab:
5. **Account card** (GlassCard): CircleAvatar with the initial on primary, display label + "@username", **"Admin" pill** (admins), OutlinedButton.icon **"Password & security"** (`shield_outlined`) → S29, OutlinedButton.icon **"Members"** (`group_outlined`, admins) → S30, OutlinedButton.icon **"Sign out"** (`logout`).
6. **Dialog "Sign out?"** "You will need to sign in again to use the app." Cancel / FilledButton "Sign out".
7. **SwitchListTile "Show mature content (18+)"** / "Include adult-only series in browsing, search and sources for this profile. Enabling requires confirming you are 18 or older." (`GET/PUT /settings` `mature_content_enabled`, per profile).
8. **Dialog "Enable mature content?"** "This shows adult (18+) sources, search results and recommendations throughout ManhwaManiacs. Only continue if you are of legal age… You can turn this off again at any time." Cancel / FilledButton "I am 18 or older — Enable".
9. **Section error card** "Couldn't load the mature content setting." + TextButton "Retry".
10. **Reading history link card** (GlassCard with glow): `history_rounded` tile, "Reading history" / "See what you read last", chevron → `/library/history`.
11. **Theme card**: 84x56 ThemeMiniature ("Aa" + primary/accent dots on the palette's bg/surface), theme name + description (or "N themes"), chevron → S31; below it a **horizontal theme strip** of 64x44 miniatures (primary 2 px ring + check badge on the active one); tap applies immediately with a selection haptic. 45 palettes (7 hand-made + 38 base16; 30 dark, 15 light; default GitHub Dark).
12. **Design card**: one row per preset (Signature, Matte, Compact, Editorial, Cinema) with a 64x48 "Aa" preview drawn in that preset's radii/stroke/type, name + description, radio icon.
13. **Dropdown "App language"**: English, Español, Français, Deutsch, 日本語, 한국어 (stored; not wired to translations).
14. **SwitchListTile "Haptic feedback"** / "Subtle vibrations on page turns, chapter changes and actions".
15. **Default reader preferences card**: SegmentedButton "Reading direction" (Left to right | Right to left | Vertical), SegmentedButton "Fit mode" (Fit width | Fit height | Fit screen), Tap zones picker (same as reader sheet), ChoiceChips "Refresh rate" + "Auto uses the highest rate your screen supports." (Android only), SwitchListTile "Keep screen awake", SwitchListTile "Auto next chapter", SwitchListTile "Lock reader controls" / "Tap center 5× to unlock during reading", SwitchListTile "Volume key navigation" / "Turn pages with the volume buttons" (Android only).

Server tab:
16. **"Server connection" heading** + "Configure the ManhwaManiacs backend URL for this device."
17. **TextField "API base URL"** (hint = default URL).
18. **FilledButton "Save URL"** → snackbar "Server URL saved and applied." or the validation error (https required in release).
19. **OutlinedButton "Reset to default"** → snackbar "Reset to default URL."
20. **Loading / error** states for the stored URL.

About tab:
21. **App card**: "ManhwaManiacs" `h3`, "Local-first manga & manhwa reader", Version and Build info rows (100 px skeleton while loading; "Unable to read app info").
22. **Updates card (Android APK channel)**: skeleton 64 px; "Could not check for updates" / "Server unreachable" (`cloud_off_outlined`); "Up to date — v3.4.2" (`check_circle_outline` success); "Update available" + "v3.4.1 → v3.4.2" + OutlinedButton.icon "Download Update" (`GET /app/version`).
23. **Updates card (iOS SideStore channel)**: `install_mobile_outlined` "Managed by SideStore", explanation, selectable source URL, OutlinedButton.icon "Copy source URL" (snackbar "Source URL copied"), 7-day signature caption.
24. **OutlinedButton "Open source licenses"** → Flutter's stock LicensePage.

Debug tab:
25. **Diagnostics link card** (`speed_rounded`): "Performance & display" / "Refresh rate, FPS, frame timing, device info, cache" → S34.
26. **Reset card**: "Restore reader defaults" + explanation + OutlinedButton.icon "Reset reader settings" (`restart_alt`).
27. **Dialog "Reset reader settings?"** "This restores all reader preferences to their defaults." Cancel / FilledButton "Reset" → snackbar "Reader settings reset to defaults."

### S29 Password & security (pushed from Settings; `SecurityScreen`)

1. **AppBar** "Password & security" (default back).
2. **Change password card**: header (`lock_outline` primary) "Change password" + "Your other devices are signed out when the password changes. This one stays signed in."; three password TextFields (Current / New / Confirm new, each with `lock_outline` prefix and show/hide IconButton); AuthError box ("Enter your current and new password.", "Password must be at least 8 characters.", "Passwords don't match.", server error); FilledButton "Update password" / "Updating…". Snackbar "Password changed. Your other devices were signed out."
3. **Sessions card**: header (`devices_outlined` accent) "Where you are signed in" + description; **IconButton `refresh` "Refresh sessions"**; session rows (ListTile: `smartphone_outlined` primary for this device / `devices_other`, parsed device label, **"This device" pill**, "Last used 3h ago · 10.0.0.2", **IconButton `logout` danger "Sign out this device"**); 220x20 skeleton; error text; "No active sessions."
4. **Dialog "Sign out this device?"** "<device> will have to sign in again to use the app." Cancel / FilledButton "Sign out" (danger) → snackbar "<device> signed out."
5. **Sign out everywhere card**: header (`gpp_maybe_outlined` danger) + "Revokes every session on the account, this device included. Downloaded chapters are left alone — clear those in Settings → Storage."; OutlinedButton.icon "Sign out everywhere" / "Signing out…" (danger).
6. **Dialog "Sign out everywhere?"** "Every device — including this one — will have to sign in again. Downloaded chapters stay on this device." Cancel / FilledButton "Sign out everywhere" (danger).

### S30 Members (admin only; pushed from Settings; `MembersScreen`)

1. **AppBar** "Members".
2. **Error box** (AuthError style) for load/action failures ("That did not work." fallback).
3. **Skeleton** — three 96 px boxes. **Empty** — "No accounts yet."
4. **Member card** (GlassCard): "@username", tags **"Admin"**, **"You"**, **"Deactivated"** (danger), subtitle "joined 2026-07-27 · last seen 2026-09-28 · 2 sessions" / "never signed in", OutlinedButton **"Deactivate" / "Reactivate"**, OutlinedButton **"Delete"** (danger), guard note "You cannot deactivate or delete your own account" on your own card (buttons disabled).
5. **Dialog "Delete @user?"** "…This removes their profiles, library, reading progress, bookmarks and everything else they own. It cannot be undone." Cancel / FilledButton "Delete" (danger).
6. **Pull-to-refresh**. Self first, then by join date.

### S31 Theme gallery (pushed from Settings; `ThemeGalleryScreen`)

1. **AppBar** "Theme" (surface fill) with a 108 px bottom holding:
2. **Search field** "Search themes" (name, description, author).
3. **Filter chips** All / Dark / Light.
4. **Group header** "DARK 30" / "LIGHT 15" (uppercase label + count).
5. **Theme row**: 84x56 miniature, name w600, description (2 lines), author (10 px), `check_circle` / `circle_outlined`; selected row primary @ 8 % fill + 2 px primary border. Tap applies instantly (selection haptic).
6. **No matches** — `palette_outlined` 40 px + "Nothing in this group" / "No theme matches "<q>"".
7. **Footer credit** "Colour schemes from the base16 community set (tinted-theming/schemes), mapped onto this app and checked for contrast. The same set the website wears."

(The redesign replaces this whole palette/preset system with two skins and dark-only AMOLED; this screen becomes the skin picker.)

### S32 Storage — `/settings/storage` (`StorageScreen`)

1. **AppBar**: back (pop or go `/settings`), title "Storage".
2. **Downloads storage card** — identical to the Downloads → Storage tab (S21 #33–#40).
3. **Image cache card** (`image_outlined` primary): "Image cache", explanation, current size (`h3`; 100x20 skeleton; "Unable to read cache size"), OutlinedButton "Clear image cache" → snackbar "Image cache cleared."
4. **Metadata cache card** (`refresh_outlined` accent): "Metadata cache", explanation, OutlinedButton "Clear metadata cache" → snackbar "Metadata cache cleared." (invalidates 8 in-memory providers).

### S33 Backup & Restore — `/settings/backup` (`BackupScreen`)

1. **AppBar**: back, title "Backup & Restore".
2. **Pending-restore banner** (warning gradient, `pending_actions_outlined`): "Restore pending" + "A backup is staged and will be applied the next time your server restarts." + OutlinedButton "Cancel restore" (`DELETE /backup/pending`; snackbar "Staged restore cancelled.").
3. **Export card** (`upload_outlined` accent): "Export backup" + description + FilledButton.icon "Export backup" / "Starting download…" (opens `GET /backup/export` in the external browser; snackbar "Could not start the download.").
4. **Import card** (`download_outlined` warning): "Import backup" + description + OutlinedButton.icon "Choose backup file" / "Uploading…" (`folder_open_outlined`; system file picker).
5. **Dialog "Restore this backup?"** ""<file>" will replace your ENTIRE library, reading history, bookmarks and collections the next time the server restarts. This cannot be undone." Cancel / FilledButton "Restore" (danger) → `POST /backup/import` (multipart).
6. **Dialog "Restore staged"** "Your backup was validated and is ready. Restart your ManhwaManiacs server to finish restoring it." FilledButton "Got it".
7. **Floating snackbars** for errors.

### S34 Diagnostics — `/settings/diagnostics` (`DiagnosticsScreen`)

1. **AppBar**: back, title "Diagnostics".
2. **Section headings**: RENDERING PERFORMANCE, DISPLAY, DEVICE, IMAGE CACHE.
3. **Performance card**: three big metrics FPS (primary) / Jank % (success <5, warning <15, danger) / Worst ms (accent) in `h2` + uppercase labels; divider; rows Avg frame time, CPU (build), GPU (raster), Samples. Placeholders "Starting profiler…", "Collecting frames… scroll a screen to sample."
4. **Display card** (Android): Current refresh rate, Device capability, Active resolution; "Reading display modes…"; iOS "Switchable display modes are only available on Android devices."
5. **Device card**: Platform (OS version), CPU cores, Screen (w × h @ dpr), App version, Build mode.
6. **Image cache card**: Live images, Cached images (n / max), Memory used (MB / MB).
## 3. Global chrome

### G1 Bottom navigation (tab shell)

`StatefulShellRoute.indexedStack` with five branches; each keeps its own stack and scroll position. The bar is shown only on the five tab roots (`/library`, `/sources`, `/search`, `/downloads`, `/more`) and hidden on every pushed/child route (series pages, readers, settings…). Body extends behind it.

1. **Floating bar container** — inset `lg` left/right, bottom = safe-area inset (or `sm`), radius `xl`, black @ 43 % shadow (blur 20, y 6) + optional primary @ 9 % halo (blur 24, y 4), backdrop blur when the preset is glass, surface fill at the preset's chrome opacity, 1 px border.
2. **Destination "Library"** `menu_book_outlined` / `menu_book` → `/library`.
3. **Destination "Sources"** `public_outlined` / `public` → `/sources`.
4. **Destination "Search"** `search_outlined` / `search` → `/search`.
5. **Destination "Downloads"** `download_outlined` / `download` → `/downloads`, with a **count badge** (primary fill, primaryFg text; hidden at 0) showing queued + downloading + failed chapters.
6. **Destination "More"** `more_horiz_outlined` / `more_horiz` → `/more`.
7. **Selection styling** — label shown only on the selected destination (w600, primary), unselected icons muted; indicator pill primary @ 12 %.
8. **Tab switch** — `goBranch` (no animation beyond Material's default indicator morph).

### G2 Mood backdrop

The active profile's mood tints the whole shell: a radial glow from (0, -0.95), radius 1.25, fading to `bg` by 62 %, tint ratio 24 % of the mood colour; cross-fades 420 ms easeOut when the profile changes. Moods: Romantic, Action, Comedy, Horror, Slice of Life, Fantasy, Default (untinted). The picker uses a stronger variant (34 %, top-centre, 1.15, 72 %). Readers, auth and setup sit outside the shell and stay untinted.

### G3 Profile switcher

1. **ProfileSwitcherChip** (Library home app bar only): pill (surface2 @ 55 %, amber @ 28 % border) with a 24 px ProfileAvatar, name (max 96 px, ellipsis), `expand_more` 16 px → push `/profiles`.
2. **More → "Switch profile"** row → push `/profiles`.
3. **Per-session gate** — after sign-in the router forces `/profiles` once per app session (Netflix-style) before any tab; picking a profile persists it (`mm.active_profile`), sets the `X-Profile-Id` header on every request and invalidates every profile-scoped cache (library, updates, history, stats, recs, bookmarks, collections, mature flag, search).
4. **Offline resume** — if the session was restored offline and a profile is cached, the gate is skipped; if profiles cannot load the picker offers "continue as last profile".
5. **Profile-scope recovery** — any API error `profile_required` / `profile_not_found` clears the active profile and returns the user to the picker.
6. Max 5 profiles per account.

### G4 18+ (mature) gate

Per profile, enforced server-side (mature sources/series are omitted for profiles without it). Surfaces:
1. Profile form switch "Mature content" (create/edit) — S06/S07 #8.
2. Settings → General "Show mature content (18+)" switch with the "Enable mature content?" confirmation dialog ("I am 18 or older — Enable") — S28 #7–9.
3. Sources list: "18+" badge on mature sources and an "18+" filter pill — S16 #5, #7.
4. Pinned sources that the current profile cannot see render as "Unavailable on this profile" — S16 #10.
5. Follow restore keeps a per-series `mature_override` (not surfaced as a control).

### G5 Reading mode (Manga | Novels)

Only exists when the server reports `novels_enabled` (from `GET /auth/bootstrap-status`). One per-(user, profile) setting that filters Library, Sources, Search, Downloads, Updates, History, Bookmarks, Stats, Collections and decides OCR visibility.
1. **ContentModeSwitch** — two-segment pill (Manga `auto_stories_rounded` | Novels `menu_book_rounded`), selected = primary fill, 160 ms easeOut, selection haptic. On Library home and Sources.
2. **ContentModeChip** — compact pill (icon + "Manga"/"Novels" + `expand_more`) in app bars: More, Search, Statistics, History, Bookmarks, Updates, Downloads, Collection detail.
3. **Reading mode sheet** (M3) opened by the chip: drag handle, surfaceElevated, max width 640, "Reading mode" `h4`, "One setting for the whole app. Your library, sources, search, downloads and updates all show what you pick here.", the switch; closes itself when the mode changes.

### G6 Authentication

- Cold start: splash (S02) while the stored token is probed (`GET /auth/me`, 3 s timeout). 401 → login. Network failure with a cached user → signed in **offline** (no UI indicator beyond reader offline icons).
- Any 401 later (outside a password check) → session cleared, active profile cleared, back to `/login`.
- Login "Keep me signed in" decides whether the token is persisted (secure storage `manhwamaniacs_auth_token`).
- Registration: open / invite-code / closed / bootstrap (first user = admin), all from `GET /auth/bootstrap-status`.
- Every request carries `Authorization: Bearer`, `X-Profile-Id`, `X-App-Version: <version>+<build>`.

### G7 First-run setup

`/setup` is forced until a server URL has been validated (`GET /health` on the typed URL; https enforced in release builds). The URL lives in secure storage (`manhwamaniacs_api_url`) and can be changed later in Settings → Server.

### G8 What's New (M4)

Shown automatically once after an app update (build number increased since `settings_last_seen_changelog_build`) and on demand from More → "What's New". Sheet: drag handle, max width 640, 80 % max height, "What's new" `h2` + "Recent improvements to ManhwaManiacs", release cards (panel, radius `lg`): version pill (amber→rose gradient), "Latest" pill on the first, "date · build N", bullet list with gradient dots. Loading spinner; "Release notes unavailable" EmptyState (`cloud_off_outlined`). Data `GET /app/changelog`.

### G9 App update (Android APK channel)

`GET /app/version` compared with the installed build: banner on More (S22 #14–16) and card in Settings → About (S28 #22). iOS SideStore builds show the SideStore card instead. Re-checked on every app resume.

### G10 Background/lifecycle behaviours (no UI of their own, but they drive states the UI must show)

- Downloads and OCR run only in the foreground; backgrounding pauses them (`backgrounded`), resuming restarts them.
- On resume: retention sweep (auto-delete read chapters older than the interval, skipping open chapters), queue resume, progress backfill + outbox flush, bookmark outbox flush + sync.
- On connectivity regained: progress and bookmark outboxes flush.

### G11 System UI and display

- Resting mode: Android `immersiveSticky` (status + nav bars hidden, swipe to peek), iOS `edgeToEdge`. Reading mode (both readers): `immersiveSticky`.
- Android high refresh rate is requested app-wide on launch (`settings_high_refresh_rate`, default on, no UI toggle); the manga reader can further pin 30/60/90/120 Hz.
- Status/navigation bar icon brightness follows the palette.

### G12 Haptics vocabulary (current)

Global switch "Haptic feedback" (default on). Uses: selection click — page turn (tap/volume), auto-next, theme/preset pick, content-mode switch, long-press on a card; light impact — bookmark saved, double-tap zoom, chapter prev/next, source browse load complete; medium impact — reader unlock.

### G13 Shared sheets and dialogs used from several screens

- **M1 Series actions sheet** (long-press a followed series on Library home / Library browse): drag handle, series title `h4`, ListTile "Open" (`open_in_new`), ListTile "Add to favorites"/"Remove from favorites" (`star_border`/`star` warning), divider, ListTile "Remove from library" (danger `remove_circle_outline`) with subtitle "Your reading progress is kept". Removal shows a snackbar "Removed "<title>" from your library" with **"Undo"** (re-follows and restores favourite/status/notify/mature override and the shelf position).
- **M2 Chapter selection bar** (library + source series pages; see S10 #8–9).
- **M3 Reading mode sheet** (G5).
- **M4 What's New sheet** (G8).
- **M5 Save to Files sheet + progress + result dialogs** (S21 #27–30).
- **M6 Reader settings sheet** (S15 #20–33).
- **M7 Novel sheets** N1 Type, N2 Contents, N3 Audiobook picker, N4 Voices (S26).
- **M8 Collection form dialog** (create/rename) and **Add Series dialog** (S24/S25).
- **M9 Confirmation dialogs** (all AlertDialog): Delete profile, Sign out, Enable mature content, Reset reader settings, Sign out this device, Sign out everywhere, Delete member, Restore backup, Restore staged, Cancel all downloads, Remove downloads, Remove saved audio, Delete collection, Remove series (collection), Install now (APK guidance).

### G14 Shared primitives (every one of these needs a Cinematic and a Glass variant)

| Primitive | Where | Current behaviour to re-spec |
|---|---|---|
| HeroHeading | every screen title (Library, Sources, Search, Updates, Collections, Stats, History, Bookmarks, Recs, auth, profiles) | uppercase display face w800, top→bottom gradient fill, auto size 40–72 px |
| PrimaryPillButton | primary CTA everywhere | pill, diagonal gradient, primary glow, 2 px inner border, uppercase label tracking 1.2 |
| GhostPillButton | Updates "Mark all read" | pill, 2 px fg outline, uppercase |
| GlassCard | most cards and rows | radius `xl`, panel fill or gradient per preset, 1 px border, optional coloured glow, ink ripple |
| GlassPanel / ChromeBlur | auth/setup cards, update banner, bottom nav, reader bars | backdrop blur + translucent surface when the preset is glass |
| Pressable | cover cards, source rows, history cards | press scale 0.97–0.99 by preset 110 ms easeOut, long-press haptic |
| FadeIn | headings, source rows | 700 ms, 30 px rise, cubic(0.25, 0.1, 0.25, 1), optional delay |
| ScrollReveal | every grid/list item | 260 ms easeOutCubic, 8 px rise, 24 ms stagger (index mod 5), starts when within 32 px of the viewport |
| SkeletonBox + ShimmerFill | all loading states | 1150 ms looping shimmer sweep, surface2 → glassEdge → surface2 |
| EmptyState | all empty/error panels | 80 px muted circle + 36 px icon, `h4` title, muted subtitle, optional action |
| SectionHeader (with icon) | Stats, Sources | 3x18 px gradient bar (cyan-400→primary), icon, uppercase label, optional "View All" pill (unused) |
| StatCard | Stats grids | accent icon tile, big tabular value, label, gradient underline, accent glow |
| SeriesCoverImage | all covers | cached network image with auth + profile headers, resized decode, 250 ms fade-in; placeholder = surface2→panel gradient box; error = surface2 box with `broken_image_outlined` |
| ProfileAvatar | picker, form, chip | gradient circle + white glyph, optional ring |
| SourceLogo | sources, search, browser | favicon or letter avatar, radius `md` |
| FilterPill | Sources, Search | 34 px pill, optional count |
| SeriesChapterTile + download control | all series pages | see S10 #15–17 |
| AsyncValueWidget | profile picker, misc | default spinner / error icon + message |
| Snackbar | ~60 messages | Material snackbar (some floating) |
| Material components themed today | — | AppBar, NavigationBar, Card, FilledButton, OutlinedButton, TextButton, IconButton, InputDecoration, Chip, Divider, SnackBar, BottomSheet, Dialog, ListTile, ProgressIndicator, Switch, Checkbox, FAB, Scrollbar. Unthemed (stock Material): Slider, SegmentedButton, ChoiceChip, FilterChip, ActionChip, DropdownButton, PopupMenu, TabBar, Badge, SearchDelegate, LicensePage. |
## 4. User actions → API / local storage

Base URL is user-configured; every call sends `Authorization: Bearer <token>`, `X-Profile-Id` (when a profile is active) and `X-App-Version`. "prefs" = SharedPreferences, "secure" = flutter_secure_storage, "store" = the on-device SQLite downloads store + blob files, "outbox" = a store-backed queue flushed to the server.

| # | Screen | User action | Result | API / storage |
|---|---|---|---|---|
| A001 | S01 | Continue (submit server URL) | validate, save, go Library | `GET <url>/health`; secure `manhwamaniacs_api_url`; prefs `settings_setup_completed` |
| A002 | S02 | (cold start) | restore session | secure `manhwamaniacs_auth_token`; `GET /auth/me` (3 s timeout); prefs `auth_cached_user` |
| A003 | S03/S04 | open screen | decide bootstrap / open / invite / closed | `GET /auth/bootstrap-status` (also yields `novels_enabled`) |
| A004 | S03 | tap "Server: host" | copy URL | clipboard |
| A005 | S03/S04/S29 | show/hide password | toggle obscure | local |
| A006 | S03 | toggle "Keep me signed in" | persist token or not | local → secure |
| A007 | S03 | Sign in | sign in | `POST /auth/login` {username, password, remember}; secure token; prefs cached user |
| A008 | S03 | "Create an account" / "Create the first account" | navigate | go `/register` |
| A009 | S04 | Create account | register (+admin if bootstrap) | `POST /auth/register` {username, password, email?, display_name?, invite_code?, remember} |
| A010 | S04 | back / "I already have an account" / "Back to sign in" | navigate | go `/login` |
| A011 | S05 | open picker / Retry | list profiles | `GET /profiles` |
| A012 | S05 | tap profile | select (5 s bloom animation) | prefs `mm.active_profile`; header `X-Profile-Id`; invalidates profile caches; go `/library` |
| A013 | S05 | long-press profile / tap in manage mode | edit | push `/profiles/edit/:id` |
| A014 | S05 | Manage / Done | toggle manage mode | local |
| A015 | S05 | Add profile tile / empty CTA | create | push `/profiles/create` |
| A016 | S05 | tap cached profile (unreachable state) | resume offline | local |
| A017 | S06 | Create profile | create | `POST /profiles` {name, avatar_key, mood, mature_content_enabled} |
| A018 | S07 | Save changes | update | `PATCH /profiles/:id` |
| A019 | S07 | Delete profile → confirm | delete | `DELETE /profiles/:id`; clears active profile if it was active |
| A020 | S06/S07 | pick avatar / mood / toggle mature | form state (mood previews live) | local |
| A021 | S08 | open / pull-to-refresh | load shelf + notifications | `GET /updates/notifications`, `GET /updates/notifications/unread-count`, `GET /library/series` (all pages); prefs `manhwamaniacs:followed-series` cache |
| A022 | S08 | (render) | continue rail | `GET /library/continue-reading?limit=10`; local read marks |
| A023 | S08 | tap continue card | resume | push reader `?page=` (manga) / novel reader `?page=` bucket |
| A024 | S08/S13/S12/S11/S25 | tap series card | open series | push `/sources/:sid/series/:key` → `GET /sources/:sid/series/:key`, `GET …/chapters`, `GET /reader/progress/series?source&series` (server progress) |
| A025 | S08/S09 | long-press series | actions sheet M1 | — |
| A026 | M1/S09/S10 | favourite / unfavourite | toggle favourite | `PATCH /library/series/:id` {is_favorite} |
| A027 | M1 | Remove from library | unfollow (optimistic, undo) | `DELETE /library/follow/:id` |
| A028 | M1 | Undo | re-follow + restore fields | `POST /library/follow` {source_id, series_key} + `PATCH /library/series/:id` {is_favorite, reading_status, notify, mature_override} |
| A029 | S08/S11/S12/S16 | Browse Sources | navigate | go `/sources` |
| A030 | G5 | switch Manga / Novels | filter whole app | prefs `mm.content-mode.u{user}p{profile}` |
| A031 | S09 | open / scroll to end / refresh | page library | `GET /library/series?page&per_page=40&sort&search&reading_status&is_favorite` |
| A032 | S09 | type search (300 ms) / pick filter / sort / view mode | re-query | same; prefs `manhwamaniacs:library-query` (sort, filter, favoritesOnly, viewMode) |
| A033 | S09 | cover size slider | change columns | prefs `settings_library_cover_scale` (250 ms debounce) |
| A034 | S09 | Select / Select all / tap in selection | multi-select | local |
| A035 | S09 | Favorite (n) / Unfavorite | batch | n × `PATCH /library/series/:id` {is_favorite} |
| A036 | S09 | Bookmarks icon | navigate | push `/library/bookmarks` |
| A037 | S09 | tap series | open library detail | push `/library/:id` → `GET /library/series/:id` (falls back to the store offline) |
| A038 | S10/S18 | Continue / Start Reading / Read Online | open reader | push/go reader `?page=` |
| A039 | S10/S18 | Read all | continuous reader | reader `?all=1` (series chapter order from `GET /sources/:sid/series/:key/chapters`) |
| A040 | S10/S18/S26-series | Follow | follow | `POST /library/follow` |
| A041 | S10/S18/S23 | Unfollow | unfollow | `DELETE /library/follow/:id` |
| A042 | S10/S18 | Select → range chips → Download N | queue chosen chapters | store (queue rows) |
| A043 | S10/S18/novel | Download Series / Download book | queue all chapters | store |
| A044 | S10/S18/novel TOC | chapter download / retry icon | queue one chapter | store; queue fetches `POST /reader/chapters/manifest` (window of ≤20) or `GET /reader/chapter/manifest`, then page images; novels `POST /novels/chapters` (window) |
| A045 | S10/S18 | Newest / Oldest | sort chapters | local |
| A046 | S10/S18 | tap chapter | open reader | push/go reader |
| A047 | S11 | open / refresh | load recs + AI budget | `GET /library/world/recommendations?seeds&per_seed`, `GET /library/suggest/availability` |
| A048 | S11 | Suggest something / example chip | AI suggestion | `POST /library/world/suggest` {prompt, limit} |
| A049 | S11 | "Search" on an unavailable title | pre-fill search | local `searchQueryProvider`; go `/search` |
| A050 | S11 | "Read on <site>" | open external | url_launcher (external browser) |
| A051 | S12 | open / refresh | stats | `GET /library/statistics?tz_offset_minutes=` |
| A052 | S12 | tap activity bar | show that day | local |
| A053 | S12 | tap recent session | open chapter | push manga reader |
| A054 | S13 | open / refresh | history | `GET /reader/history?limit=50&offset=0&collapse=series` |
| A055 | S13 | play button on a card | resume (next chapter if finished) | may call `GET /sources/:sid/series/:key/chapters`; push reader |
| A056 | S14 | open / refresh | bookmarks | store bookmarks (+ outbox sync `POST /reader/bookmarks/batch`) or `GET /reader/bookmarks` |
| A057 | S14 | tap bookmark | open at exact spot | reader `?page=&at=` / novel reader `?para=&at=` |
| A058 | S14 | delete bookmark | remove | outbox op → `POST /reader/bookmarks/batch`, or `DELETE /reader/bookmarks/:id` |
| A059 | S15/S19 | open chapter | load pages | `GET /reader/chapter/manifest?source&series&chapter` (S15) / `GET /sources/:sid/series/:key/chapters/:cid/reader` (S19); store for downloaded pages; images via `GET` page URLs with auth headers |
| A060 | S15/S19 | scroll / page turn | save progress (500 ms debounce) | outbox → `POST /reader/progress` / `POST /reader/progress/batch` {source, series, chapter, chapter_number, last_page, page_count, is_completed, time_spent_seconds}; prefs `manhwamaniacs-reader-scroll:<profile>:<source>:<series>:<chapter>` (250 ms); store `markRead` on completion; S19 also prefs source-local progress |
| A061 | S15/S19 | bookmark (bar, sheet, key B) | exact bookmark | outbox `create` → `POST /reader/bookmarks/batch` |
| A062 | S15/S19 | prev/next chapter (bar, sheet, edge prompt, keys H/L, auto-next) | change chapter | go reader route for that chapter |
| A063 | S15/S19 | chapter title / "Go to series" | open series | pop or go source series detail |
| A064 | S15/S19 | back / iOS edge swipe | leave | S15: pop, or go to the series page when nothing is beneath; S19: always go to the source series page |
| A065 | S15/S19 | scrub slider | seek page | local |
| A066 | S15/S19 | reading direction / fit mode / tap zones / refresh rate | reader defaults | prefs `settings_reading_direction`, `settings_reader_fit_mode`, `settings_reader_tap_zones`, `settings_reader_refresh_rate` |
| A067 | S15/S19 | brightness / warmth / background / colour mode | reader filter | prefs `reader_brightness`, `settings_reader_warmth`, `settings_reader_background`, `settings_reader_color_mode` |
| A068 | S15/S19 | zoom − / reset / + (keys −, 0, +; double-tap) | zoom 0.5–3.0 | local (session only) |
| A069 | S15/S19 | Auto-scroll switch / speed | auto-scroll | local (session only) |
| A070 | S15/S19 | five centre taps while locked | unlock | local |
| A071 | S15/S19 | Android volume keys | page | native bridge (opt-in) |
| A072 | S19 | (open chapter with a next one) | auto-queue next chapter download | store (skipped on cellular when wifi-only is set) |
| A073 | S16 | open / refresh | sources + pins | `GET /sources`, `GET /sources/pins`; prefs `manhwamaniacs:source-pins` cache |
| A074 | S16 | filter text / All / Pinned / 18+ | filter | local |
| A075 | S16/S21 | pin / unpin source | reorder | `PUT /sources/pins` {source_ids}; prefs cache |
| A076 | S16 | tap source | browse | go `/sources/:sid` |
| A077 | S17 | open / mode chip / search / scroll / refresh | browse | `GET /sources/:sid/browse-modes`, `GET /sources/:sid/series?page&sort&search` |
| A078 | S17 | Top pill | scroll to top | local |
| A079 | S18 novel | Go to chapter / Contents | chapter picker | local (chapters already loaded) |
| A080 | S18 novel | Make audiobook → Narrate | request TTS render | `POST /novels/audio/render` {source_id, series_key, chapter_keys}; polls `GET /novels/audio/jobs` |
| A081 | S18 novel | Audiobook → Save to phone | save narration | store (audio rows); fetch `GET /novels/audio/file` + `GET /novels/audio` |
| A082 | S18 novel | (render) | audiobook state, word counts | `GET /novels/audio/series?source&series`, `GET /novels/audio/jobs` |
| A083 | S20 | type (300 ms) / submit / suggestion chip | federated search | `GET /sources/search?q&page&per_page`; prefs `manhwamaniacs:recent-searches:<profile>` (max 4) |
| A084 | S20 | group filter pill | filter groups | local |
| A085 | S20 | Retry on a failed source | re-query one source | `GET /sources/:sid/series?search=<q>` (that source only) |
| A086 | S20 | scroll to end | next page | `GET /sources/search?page=n` |
| A087 | S20 | tap result | open | library detail (local hit) or source series detail |
| A088 | S21 | pause / resume queue | pause | store / controller state |
| A089 | S21 | Cancel all → confirm | drop queue | store |
| A090 | S21 | Show / Hide queue | expand list | local |
| A091 | S21 | queued row Retry / Remove | per chapter | store |
| A092 | S21 | series card pin | exempt from auto-delete | store `setSeriesPinned` |
| A093 | S21 | Remove all downloads → confirm | delete series files | store |
| A094 | S21 | chapter delete | delete one | store |
| A095 | S21 | Save to Files → Page images / CBZ | export | writes files to app Documents/Exports (iOS Files app visible) |
| A096 | S21 | OCR button on a chapter | extract text on device | platform OCR engine; `POST /ocr/chapter`; `GET /ocr/coverage` |
| A097 | S21 | OCR banner Cancel | stop OCR | local |
| A098 | S21/S32 | storage cap / chapters at once / auto-delete chips | download policy | prefs `settings_download_storage_cap`, `settings_download_concurrency`, `settings_download_retention_interval` |
| A099 | S21/S32 | Free up space | delete read chapters | store |
| A100 | S21 | tap downloaded chapter | open offline | reader / novel reader |
| A101 | S22 | any row | navigate | push/go target route |
| A102 | S22/S28 | Download update | open APK URL | url_launcher; `GET /app/version` |
| A103 | S22 | What's New | changelog sheet | `GET /app/changelog` |
| A104 | S23 | open / refresh | notifications + follows | as A021 |
| A105 | S23 | Check all now / refresh icon | server update check | `POST /updates/check`; polls `GET /updates/notifications/unread-count` at 3/5/7 s |
| A106 | S23 | Mark all (manga/novels) read | mark read | `POST /updates/notifications/read-all` {content_kind?} |
| A107 | S23 | Mark read / tap notification | mark one read (+ open reader) | `PATCH /updates/notifications/:id/read` |
| A108 | S24 | open / refresh | list | `GET /library/collections` |
| A109 | S24 | New / FAB / empty CTA → Create | create | `POST /library/collections` {name, description} |
| A110 | S24 | search / sort | local filter + sort | local |
| A111 | S25 | open / refresh | detail | `GET /library/collections/:id` |
| A112 | S25 | Add Series → pick | add member | `POST /library/collections/:id/series` {source_id, series_key} |
| A113 | S25 | Rename → Save | update | `PATCH /library/collections/:id` {name, description} |
| A114 | S25 | Delete → confirm | delete | `DELETE /library/collections/:id` |
| A115 | S25 | remove member → confirm | remove | `DELETE /library/collections/:id/series` {source_id, series_key} |
| A116 | S26 | open chapter | load text (+ audio) | `GET /novels/chapter?source&series&chapter` (or store); `GET /novels/audio`; `GET /novels/attribution` |
| A117 | S26 | scroll | save progress bucket (1–100) | outbox `POST /reader/progress`; prefs source-local progress; store `markRead` |
| A118 | S26 | play / pause / seek / speed | narration playback | stream `GET /novels/audio/file?source&series&chapter&format=m4a (iOS) / ogg-opus (Android)` (bearer) or local file |
| A119 | S26 | save / remove / re-save audio | narration download | store (audio row) |
| A120 | S26 | bookmark | exact bookmark with snippet | outbox → `POST /reader/bookmarks/batch` |
| A121 | S26 | Contents / Next / Previous / auto-next | change chapter | go novel reader route; `GET /sources/:sid/series/:key` + chapters for contents |
| A122 | S26 | type panel face / size / spacing / width | per-series typography | prefs `mm.novel-prefs.u{user}p{profile}` (JSON map keyed `source:series`) |
| A123 | S26 | page palette | reading surface | prefs `mm.novel-palette.u{user}p{profile}` |
| A124 | S26 | Voices → preview a voice | hear sample | `GET /novels/voices`, stream `GET /novels/voices/sample?voice&format` |
| A125 | S26 | Voices → Use (narration) | set narrator voice | `POST /novels/narrator` |
| A126 | S26 | Voices → Use (character) | cast character | `POST /novels/cast` |
| A127 | S27 | type (350 ms) / submit | dialogue search | `GET /ocr/search?q&limit&offset` |
| A128 | S27 | tap result | open chapter | push manga reader |
| A129 | S28 | Search settings → pick | jump to tab | local |
| A130 | S28 | Sign out → confirm | sign out | `POST /auth/logout`; clears secure token, cached user, active profile |
| A131 | S28 | mature toggle (+ confirm) | 18+ for this profile | `GET/PUT /settings` {mature_content_enabled} |
| A132 | S28/S31 | pick theme | palette | prefs `mm.theme.u{user}p{profile}` |
| A133 | S28 | pick design preset | preset | prefs `mm.preset.u{user}p{profile}` |
| A134 | S28 | language | stored only | prefs `settings_language` |
| A135 | S28 | haptics switch | global haptics | prefs `settings_haptic_feedback` |
| A136 | S28 | keep awake / auto-next / lock controls / volume keys | reader defaults | prefs `settings_keep_screen_awake`, `settings_auto_next_chapter`, `settings_lock_reader_controls`, `settings_volume_key_navigation` |
| A137 | S28 | Save URL | change server | secure `manhwamaniacs_api_url` (policy check, rebuilds HTTP client) |
| A138 | S28 | Reset to default | clear server URL | secure |
| A139 | S28 | Copy source URL (SideStore) | copy | clipboard |
| A140 | S28 | Open source licenses | license page | local |
| A141 | S28 | Reset reader settings → confirm | reset | removes 13 reader prefs keys |
| A142 | S29 | Update password | change password | `POST /auth/change-password` {current_password, new_password} |
| A143 | S29 | open / refresh sessions | list sessions | `GET /auth/sessions` |
| A144 | S29 | sign out a device → confirm | revoke | `DELETE /auth/sessions/:id` |
| A145 | S29 | Sign out everywhere → confirm | revoke all | `POST /auth/logout-all` |
| A146 | S30 | open / refresh | list accounts | `GET /auth/users` |
| A147 | S30 | Deactivate / Reactivate | toggle account | `PATCH /auth/users/:id` {is_active} |
| A148 | S30 | Delete → confirm | delete account | `DELETE /auth/users/:id` |
| A149 | S32 | Clear image cache | clear | image cache service (disk + memory) |
| A150 | S32 | Clear metadata cache | refetch | invalidates providers (no API call until next use) |
| A151 | S33 | open | restore status | `GET /backup/status` |
| A152 | S33 | Export backup | download snapshot | external browser → `GET /backup/export` |
| A153 | S33 | Choose backup file → confirm | stage restore | file picker; `POST /backup/import` (multipart) |
| A154 | S33 | Cancel restore | unstage | `DELETE /backup/pending` |
| A155 | S34 | open | profiler, display modes | local (frame timings, flutter_displaymode) |
| A156 | G8 | (after update) | What's New | prefs `settings_last_seen_changelog_build`; `GET /app/changelog` |
| A157 | G10 | app resume / reconnect | sweep + flush | store retention sweep; `POST /reader/progress/batch` (after a one-time backfill of locally recorded source progress into the outbox); `POST /reader/bookmarks/batch` |

Repository capabilities with **no UI today** (candidates to surface in the redesign): tags (`GET/POST /library/tags`, `DELETE /library/tags/:id`, `POST/DELETE /library/series-tags`), library-only search (`GET /library/search`), recently updated (`GET /library/recently-updated`), update settings (`GET/PUT /updates/settings`: enabled, check_interval_minutes, notify_enabled, check_on_startup), update run history (`GET /updates/runs`), per-series check (`POST /updates/followed/:id/check`), cancel a narration job (`DELETE /novels/audio/jobs/:id`), reading-status and notify fields on a follow (`PATCH /library/series/:id` reading_status / notify / sort_order), Wi-Fi-only downloads (`settings_wifi_only_downloads`, honoured by S19 but no toggle), high refresh rate (`settings_high_refresh_rate`, no toggle).
## 5. Settings: every key, type and option

### 5a. User-facing preferences (SharedPreferences unless noted)

| # | Key | Type | Options (default **bold**) | Scope | Where it is set |
|---|---|---|---|---|---|
| K01 | `settings_reading_direction` | enum | leftToRight "Left to right", rightToLeft "Right to left", **vertical "Vertical"** | device | Settings → General; reader sheet |
| K02 | `settings_reader_fit_mode` | enum | **width "Fit width"**, height "Fit height", screen "Fit screen" | device | Settings; reader sheet |
| K03 | `settings_reader_tap_zones` | string `left,center,right` | each of advance "Next" / retreat "Previous" / toggle "Toggle"; **unset = Previous/Toggle/Next, mirrored for RTL** | device | Settings; reader sheet ("Reset" clears) |
| K04 | `settings_reader_refresh_rate` | enum | **auto "Auto"**, fps30, fps60, fps90, fps120 | device, Android only | Settings; reader sheet |
| K05 | `settings_keep_screen_awake` | bool | **false** | device | Settings |
| K06 | `settings_auto_next_chapter` | bool | **true** (900 ms after reaching the end) | device | Settings |
| K07 | `settings_lock_reader_controls` | bool | **false** (reader opens locked; 5 centre taps unlock) | device | Settings |
| K08 | `settings_volume_key_navigation` | bool | **false** | device, Android only | Settings |
| K09 | `reader_brightness` | double | 0.2–**1.0** | device | reader sheet |
| K10 | `settings_reader_warmth` | double | **0.0**–1.0 | device | reader sheet |
| K11 | `settings_reader_background` | enum | **dark "Dark" #0A0A0A**, black "AMOLED" #000000, white "Paper" #F5F1E8 | device | reader sheet |
| K12 | `settings_reader_color_mode` | enum | **normal "Normal"**, sepia "Sepia", grayscale "Gray" | device | reader sheet |
| K13 | `settings_haptic_feedback` | bool | **true** | device | Settings → Feedback |
| K14 | `settings_language` | enum | **en English**, es Español, fr Français, de Deutsch, ja 日本語, ko 한국어 (stored, not applied) | device | Settings → Language |
| K15 | `settings_library_cover_scale` | double | 0.7–**1.0**–1.6 | device | Library browse slider |
| K16 | `manhwamaniacs:library-query` | JSON | sort **recently_updated** / recently_added / title; filter **all** / reading / completed; favoritesOnly **false**; viewMode **grid** / list | device | Library browse toolbar |
| K17 | `settings_download_storage_cap` | enum | gb2 "2 GB", gb5 "5 GB", **gb10 "10 GB"**, gb20 "20 GB", unlimited "Unlimited" | device | Downloads → Storage; Settings → Storage |
| K18 | `settings_download_concurrency` | enum | one "1 chapter", **two "2 chapters (default)"**, three "3 chapters" | device | same |
| K19 | `settings_download_retention_interval` | enum | off "Off", hours24 "24 hours", **hours48 "48 hours (default)"**, days7 "7 days" | device | same |
| K20 | `settings_wifi_only_downloads` | bool | **false** (only gates S19's auto-queue of the next chapter) | device | **no UI** |
| K21 | `settings_high_refresh_rate` | bool | **true** | device, Android | **no UI** |
| K22 | `mm.theme.u{user}p{profile}` (`mm.theme.device` before a profile) | palette id | 45 palettes (30 dark, 15 light); **githubDark** | per user+profile | Settings → Theme, Theme gallery |
| K23 | `mm.preset.u{user}p{profile}` (`mm.preset.device`) | preset id | **signature** "Frosted glass, generous spacing, poster-led browse.", matte "No blur or translucency. Solid surfaces, crisp hairlines.", compact "Density first — tighter rhythm, list-led browse.", editorial "Serif headings, wide margins, metadata over artwork.", cinema "Chrome recedes. Covers and pages take the screen." | per user+profile | Settings → Design |
| K24 | `mm.content-mode.u{user}p{profile}` (`mm.content-mode.device`) | enum | **manga**, novel (only when the server enables novels) | per user+profile | G5 switch/chip |
| K25 | `mm.novel-prefs.u{user}p{profile}` | JSON map `"source:series" → {fontFamily, fontSize, lineHeight, measure}` | fontFamily **serif** / sans; fontSize 15–**19**–26 step 1; lineHeight 1.40–**1.75**–2.10 step 0.05; measure 48–**68**–88 ch step 2 | per user+profile, per series | Novel reader → Type panel |
| K26 | `mm.novel-palette.u{user}p{profile}` | palette id | paper, sepia, solarized-light, soft-grey, cream, dawn, **dusk (dark app)** / **paper (light app)**, midnight, black, solarized-dark, forest, rose-pine, `app` (follow app theme) | per user+profile | Novel reader → Type panel |
| K27 | `mm.active_profile` | JSON snapshot {id, name, avatarKey, mood, …} | — | device | Profile picker |
| K28 | secure `manhwamaniacs_api_url` | string URL | **Env.defaultApiUrl** | device | Setup; Settings → Server |
| K29 | secure `manhwamaniacs_auth_token` | string | — | device | Login ("Keep me signed in") |

### 5b. Server-side settings the UI edits

| # | Field | Type | Options | Where |
|---|---|---|---|---|
| K30 | `/settings` `mature_content_enabled` | bool | **false**; enabling needs the 18+ confirmation | Settings → Content (per profile) |
| K31 | Profile `name` | string ≤255 | — | Profile form |
| K32 | Profile `avatar_key` | enum | violet (default), cyan, rose, amber, emerald, ember, blade, phantom, arcane, lunar, star, reader | Profile form |
| K33 | Profile `mood` | enum | romantic, action, comedy, horror, slice_of_life, fantasy, **default** | Profile form |
| K34 | Profile `mature_content_enabled` | bool | **false** | Profile form |
| K35 | Follow `is_favorite` | bool | — | star buttons, M1 |
| K36 | Follow `reading_status` / `notify` / `mature_override` / `sort_order` | string / bool / bool / int | reading, completed, on_hold, plan_to_read, unread… | **only restored by Undo; no UI** |
| K37 | Source pins | ordered list of source ids | — | pin buttons |
| K38 | Narrator voice per series | voice id or null (default) | 31 named voices, male/female | Voices panel |
| K39 | Character voice per series+name | voice id or null (automatic) | same | Voices panel |
| K40 | Update settings `enabled`, `check_interval_minutes`, `notify_enabled`, `check_on_startup` | bool/int/bool/bool | — | **no UI** |

### 5c. Internal persisted state (not settings, but must survive the redesign)

`settings_setup_completed` (bool), `settings_last_seen_changelog_build` (int), `auth_cached_user` (JSON), `manhwamaniacs:recent-searches[:profileId]` (≤4 strings), `manhwamaniacs-reader-scroll:<profileId>:<source>:<series>:<chapter>` (double px), `mm.source_progress:<profileId>` (JSON per chapter page/pageCount/completed), `mm.source_progress.backfilled:<profileId>` (bool), `manhwamaniacs:followed-series:<scopeId>` (offline follow cache), `manhwamaniacs:source-pins:<user>:<profile>` (pin cache), `pinned_sources` + `pinned_sources_migrated` (legacy), `reader_mode` and `settings_theme_mode` (legacy, unused). Downloads SQLite store: chapters, pages, blobs, audio rows, bookmarks, progress/bookmark outboxes, series pins, read stamps.

### 5d. Session-only UI state (resets on restart)

Reader zoom (0.5–3.0, step 0.1, double-tap 2.0), auto-scroll on/off + speed (30/60/120 px/s), reader chrome visible/locked, novel playback speed (0.75x–2x), chapter list sort (Newest; novel TOC Oldest), library selection, sources filter (All/Pinned/18+) and query, search group filter (All/With results/Pinned) and query, collection search and sort (Name A–Z / Most series / Custom order), theme gallery query and filter, downloads queue expanded, Settings tab.
## 6. Reader internals

### 6a. Manga / manhwa reader (S15, S19 → `ReaderContent`)

**Modes (reading direction × fit):**

| Direction | Scroll axis | Layout | Notes |
|---|---|---|---|
| Vertical (default) | vertical | seamless webtoon strip, pages edge to edge, no gaps or radius, max content width 768 px at zoom ≤1 | iOS 20 px left-edge swipe-back only here |
| Left to right | horizontal | continuous horizontal strip; each page a card (radius `sm` 6 px, 16 px black @ 40 % shadow, 4 px gap) | tap zones default Previous / Toggle / Next |
| Right to left | horizontal, reversed | same strip mirrored; scrubber runs RTL | tap zones default mirror to Next / Toggle / Previous |

Fit width → `BoxFit.fitWidth`, Fit height → `fitHeight`, Fit screen → `contain`. There is no page-by-page PageView; "paging" in any direction scrolls 85 % of the viewport (240 ms easeOutCubic). Zoom (0.5–3.0x, 0.1 steps, double-tap toggles 1.0 ⇄ 2.0) scales the page width inside the list rather than pinch-zooming; there is **no pinch gesture** today.

**Continuous feed / Read all:** the reader holds a window of at most 3 chapters (current ± 1). When the reading position is within 4 pages of either end, the next/previous chapter is loaded and stitched in with a 96 px chapter seam (title between hairlines). Chapters scrolled past are marked complete. Failed neighbour loads retry with back-off from 2 s up to 30 s; until then the edge prompt stays as the way across. `?all=1` hands the feed the whole series order (oldest→newest) so it never asks the server for neighbours. Without a feed extension (single chapter), "Auto next chapter" navigates after 900 ms at the end.

**Tap zones and gestures:**
- Screen split into thirds: left < 33.3 %, centre, right > 66.7 % of width. Each third maps to Previous / Toggle / Next (configurable, see K03).
- Any tap while chrome is visible hides it. Taps are ignored during a drag-scroll and for 300 ms after one ends.
- Double tap (two taps within 280 ms) toggles zoom 1.0x ⇄ 2.0x (light haptic).
- Lock mode: only the centre region (20–80 % x, 15–85 % y) counts; five taps, each within 2 s of the last, unlock ("Reader unlocked", medium haptic).
- Starting a drag hides the chrome. Chrome auto-hides after the preset's delay (3000 ms; 1200 ms on the Cinema preset).
- Keyboard: H previous chapter, L next chapter, B bookmark, = / + / numpad + zoom in, − / numpad − zoom out, 0 / numpad 0 reset.
- Android volume keys page up/down when enabled (native bridge intercepts them).
- iOS edge swipe (vertical mode): drag ≥50 % of width or fling ≥1 width/s from the 20 px leading strip → back.
- Scrubber drag seeks live, one division per page.
- Auto-scroll: continuous scroll at 30 / 60 / 120 px/s (frame-delta based, clamps long frames to 1/60 s), stops at the end.

**Position, progress and bookmarks:**
- Opening order of precedence: bookmark anchor (`?page=&at=` fraction within the page) → saved scroll offset for this profile + chapter → `?page=` estimate → top. Restoration re-jumps for up to 30 frames while page heights resolve. A stale anchor (page no longer exists) opens at the last page with a snackbar.
- Scroll offset saved 250 ms after scrolling stops (per profile + chapter key); progress saved 500 ms after the visible page changes and flushed on exit. Completion = last page reached. Reading time is accumulated by a clock that drops gaps > 300 s.
- Progress goes into a local outbox (works offline) and is pushed to `POST /reader/progress` / `/reader/progress/batch`; bookmarks likewise through a bookmark outbox (`POST /reader/bookmarks/batch`).

**Prefetch and memory:**
- List cache extent 6000 px of pre-built pages.
- Image prefetch ahead of the visible page: at least 2 and at most 16 pages, within a 64 MB decoded-bytes budget (assumes 24 MB per unknown page, learns real sizes as pages decode); decode width = viewport width × DPR capped at 2880 px; the first 2 pages are marked priority.
- Flutter image cache raised to 8 % of device RAM, clamped 384–768 MB.
- Page heights start from declared width/height (or 2:3) and are corrected as images decode, with scroll-offset compensation so the page under the reader never jumps.
- Source reader (S19) also auto-queues the **next chapter for download** when a downloads scope exists (skipped off Wi-Fi if the hidden Wi-Fi-only flag is set).

**Offline:** a chapter fully saved on the phone opens from disk with no network; a partially saved one overlays local pages on the network manifest; if the network fails the reader falls back to the saved copy (no neighbours, so no edge prompts).

**Display:** keep-screen-awake wakelock (K05); Android refresh-rate pin (K04) via flutter_displaymode, reset on exit; immersive-sticky system UI while reading.

**Per-page states:** loading (blank box at the page's aspect ratio in the background colour), loaded, broken ("Failed to load page" + Retry).

### 6b. Novel reader (S26)

- One scrolling column (not paginated) of width = measure in characters, centred; body face, size, line height per series (K25); page palette (K26).
- Progress = bucket 1–100 derived from the paragraph under the **reading line** (25 % down the viewport); only forward progress is pushed; completion when scrolled to within 8 px of the end. Bookmarks anchor to paragraph + fraction and store a ≤180-char snippet.
- Restoration: `?para=&at=` → exact paragraph at the reading line; `?page=` bucket → proportional paragraph; up to 30 frames of re-jumps.
- Narration: audio manifest per chapter with timings; the follower maps playback position to a paragraph/character range, highlights spoken text, and auto-scrolls the spoken paragraph to the reading line (260 ms easeOut) unless the user is scrolling. Auto-next is suppressed while audio plays.
- Estimates use 250 words per minute. Drop cap only for a first paragraph ≥80 chars; a paragraph ≤12 chars of ornament is a scene break.
- Narration job polling: every 5 s, ×3 slower while all jobs wait for the render PC, exponential back-off to ×12 on failures.

### 6c. Download states (the vocabulary every download control must express)

| Level | States |
|---|---|
| Chapter (store row) | queued, downloading (pages done / total, or "reading chapter details…"; novels "fetching/saving the text…"; audio "fetching/saving the audio…"), complete, failed (error text, retryable) |
| Chapter control on series pages | not downloaded (download icon), queued (clock), downloading (determinate ring + "page a of b" line + 3 px bar), saved offline (success badge), failed (retry icon + error line) |
| Series | "X of Y chapters saved on this phone" bar; waiting/failed counts; pinned (exempt from auto-delete) |
| Queue | Downloading / Waiting to start / Paused; pause reasons: none, noScope (no profile), backgrounded (auto-resumes), freeSpaceFloor (<1.5 GB free), cap (storage cap reached), userPaused |
| Narration audio | none, saving, saved, failed, unplayable (saved but the phone cannot decode it → re-save) |
| OCR run | idle, recognizing (page n of N), paused (backgrounded), uploading, done (N words searchable), cancelled, failed |

Queue mechanics: 1–3 chapters in parallel (K18); pages fetched 2 at a time; never more than 4 HTTP requests open; manifests requested in windows of up to 20 chapters (shrinks to 2 on server limits; 30 s cool-down after a refusal); 3 retries per manifest (2 s back-off) and per page (600 ms back-off); stops before the 1.5 GB free-space floor and at the storage cap; runs only in the foreground; retention sweep on launch/resume deletes read chapters older than K19 except pinned series and open chapters. Kinds: manga, novel (text), audio (narration).

## 7. Gaps and oddities found while reading (inputs for the redesign, not requests)

1. **Library browse (S09) has no forward entry point**; it is only the back fallback of S10. The redesign must either give it a home (e.g. a "See all" on the Library rail) or fold it into Library home.
2. **Search "Advanced Filters" button is a no-op** (its toggle callback is empty); `SearchToolbar` and `SearchResultCard` are dead widgets.
3. **Two series pages for the same series**: S10 (by follow id, library data) and S18 (by source key, live data). Library home, history, stats, recs and collections all open S18; only S09 and search's library hits open S10.
4. **Collection members and OCR results show raw series keys / chapter keys**, not titles (the payloads carry no titles).
5. **Dialogue search results open the chapter at page 1**, not at the matching page.
6. **No pinch-to-zoom** in the manga reader; zoom is buttons, keys and double-tap only. No page-by-page (PageView) mode; LTR/RTL are continuous horizontal strips.
7. **No offline indicator** outside the novel reader (manga reader, library, series pages silently read from the store).
8. **App language picker is stored but not applied** (no localisation).
9. **Settings exist without UI**: Wi-Fi-only downloads, high refresh rate, update-check schedule; follow `reading_status` / `notify` cannot be edited (only shown as tags).
10. **Two theming axes today (45 palettes × 5 presets) plus a mood tint per profile**; the redesign's two-skin model replaces palettes and presets. The mood tint, novel reading palettes (12) and manga reader backgrounds (3) are reading/identity features and need an explicit decision per skin.
11. **Bottom nav hides on every non-root route**, including More's destinations; More → History/Bookmarks/Stats/Recs switches the user into the Library tab's stack.
12. **Profile picker selection animation is 5 s** long (skipped only under reduced motion).
