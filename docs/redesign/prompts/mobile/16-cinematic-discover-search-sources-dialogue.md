# mobile/16 · Cinematic Discover: search, sources, catalogues and dialogue search

Step 50 of the redesign series (track `mobile`, group 5). Depends on `mobile/15-cinematic-listen-mode.md` and `backend/02-library-series-ocr-extensions.md`. Its twin `web/16-cinematic-discover-search-sources-dialogue.md` builds the same cluster on the web and may run at the same time in another session; you never touch `frontend/`.

## Goal

Build the whole Discover branch (shell branch 2) of the Cinematic skin in Flutter for iOS and Android, phone and tablet: the search screen at `/search` with its five scopes (`ALL · LIBRARY · SOURCES · DIALOGUE · ASK`), the index field set in Bodoni Moda Italic, the idle page (recent searches, the Ask-the-editors block, genre tiles, pinned sources, the dialogue entry, trending titles), the tiered results set group by group with the `Jump to source` sheet; the Sources directory at `/sources` with health marks, pins with drag reorder and Move items, and 18+ marks; the source catalogue at `/sources/:sourceId` with browse modes, genres, the opening state and the `source_not_browsable` notice; and dialogue search at `/ocr` ("What they said") as subtitled stills cropped from the page around the matched speech bubble, with the jump into the reader that pulses the bubble. The on-device OCR indexing flow (capabilities §20: Apple Vision and ML Kit run on the phone over downloaded pages, then `POST /ocr/chapter`) keeps running on the existing `mm/ocr` channel (`OcrChannel.kt`, `AppDelegate.swift`, `MethodChannelOcrEngine`, `OcrRunController`) with no native change; this step builds its Cinematic scan widgets. Every source request goes through the sources request limiter at its priority. Every state, hardware key, haptic, reduced-motion variant and tablet layout is delivered. Picks (`/library/recommendations`) is **not** part of this step; it is `mobile/19`.

## Read first

Read these before planning. Do not skim the DESIGN sections: they hold the exact values.

1. `docs/redesign/cinematic/DESIGN.md`
   - §1; §2.1.1 (the raised-stock rule: `ink.45` only on `paper.0`), §2.1.3 (health colours), §2.1.4 (scrims, the over-art rule), §2.1.5 (ambient `duo`, duotone), §2.1.6 (mood grades), §2.2 (grid: phone 4 columns, margin 16, gutter 12; tablet 8 / 32 / 16), §2.3 (radius 0), §2.7 (icons incl. `bubble-search`, `certificate-18`, `image-broken`), §2.8 (the `CineTokens` field names, `CineDur`, `CineCurves`, `CineSprings`).
   - §3.2, §3.3 (text-scale caps, reflow at ≥ 1.3 and ≥ 2.0, the 1.3 cap on dialogue subtitles), §3.5.
   - §4.2–§4.8 (durations, curves, springs, the motion table: Set, Develop, Rack focus, Dip, Page, Match cut, Rule slide, Highlight sweep; stagger; interruptibility; the reduced-motion table).
   - §5 (haptics: `select`, `longpress.open`, `refresh.arm`, `sheet.detent`) and §6 (`tick` for `select` when sounds are on).
   - §7 intro, §7.1, §7.2, §7.4 (search fields, the `index` variant), §7.5 (slug lines), §7.6 (World card, for the ASK scope), §7.7 (posters, caption mode Below), §7.8 (rails), §7.9 (`CineSheetRoute`), §7.11 (toasts), §7.12 (contents tabs), §7.13 (running head), §7.14 (thumb index: third tap on Discover), §7.16 (rows, drag to reorder), §7.17 (galley proofs), §7.18 (leader dial, indeterminate rule), §7.19 (badges), §7.22 (menus, Quick look, Move items), §7.23 (notices), §7.24 (the 18+ mark and absence rule), §7.29 (pull to reprint with `custom_refresh_indicator` 4.0.2, content-mode chip, `folioLabel()`).
   - §8.0.2–§8.0.10 (navigation map, route contract and branch 2, transitions, **§8.0.5 platform rules**, content mode, **§8.0.9 tablet rows for Discover, Sources and Dialogue search**, the not-available notice).
   - **§8.20 Discover, §8.21 Sources, §8.22 Source catalogue, §8.24 Dialogue search** (the specs you are building; read every line, including each "Platform deltas" paragraph).
   - §8.14.2 (Dip into the reader), §8.23 (only the "Dialogue scan" block and the `Scan dialogue` row action, which this step builds as widgets), §9.1.3 and §9.1.8 (only for the ASK scope and the Ask-the-editors block), §10.1 and §10.2 (the two signature animations; Flutter `SetHeading` §10.1.6 and `TypedHeadline` §10.2.4), §11 (gesture matrix: long-press, pull to reprint, drag handle), §13, §14 (accessibility), §15.3, §15.6 (performance guards and the request limiter), §15.7.
2. `docs/redesign/glass/DESIGN.md` §8.9 Search, §8.10 Sources, §8.11 Source catalogue, §8.23 Dialogue search and §15.6, only so the shared data-layer code you add stays skin-neutral: Glass (`mobile/38`) calls the same providers with its own screens and adds a `text` search scope.
3. `docs/redesign/inventory/00-decisions.md` (binding owner decisions).
4. `docs/redesign/stack-decision.md` §2.3 (mobile folder layout, the boundary test, the completeness test), §2.6 (single-sourced logic), §4 risks 9 and 11.
5. `docs/redesign/inventory/mobile.md` S16, S17, S20, S27, S21 #4 and #24 (the OCR banner and chapter OCR button being replaced), G1, G4, G5, G12, §4 (the calls each action makes), §5 (K37 pins, recent searches in §5c), §6c (the OCR run states).
6. `docs/redesign/inventory/capabilities.md` §16 (sources, health, pins, browse, genres, the `cache` block), §18 (federated search tiers), §20 (OCR).
7. `docs/redesign/00-baseline.md` (the health baseline every check is compared with).
8. `docs/redesign/prompts-plan.json`: the entry for this file and those for `mobile/03`, `mobile/04`, `mobile/05`, `mobile/06`, `mobile/08`, `mobile/12` and `backend/02`, so you know which primitives, providers and endpoints already exist.

## Skills to invoke, in this order

1. `superpowers:writing-plans`: write the implementation plan for this step to `docs/redesign/proof/mobile-16/plan.md` before touching code. The plan lists every item of the Scope section below as a task.
2. `superpowers:subagent-driven-development` to run the plan (one subagent per task group A–G below, run one after the other; never two `flutter test` runs at once). Use `superpowers:executing-plans` instead if subagents are unavailable.
3. `impeccable:impeccable` and `taste-skill:taste-skill` while building each screen: they check hierarchy, spacing and craft. When one of them suggests something that contradicts `cinematic/DESIGN.md`, the contract wins. `frontend-design:frontend-design` is for web UI; this step has none, so it is not invoked.
4. `superpowers:verification-before-completion` before you claim anything is done.

## Before you start

- `git status` must show branch `feat/vps-slim-source-native`. Other sessions (web, backend, shared) commit in the same checkout: never stage their paths, never run `git add -A`, `git stash`, `git reset` or `git checkout` on files you did not change.
- Confirm the dependencies landed. Stop and report if any of these is missing:
  - The Cinematic router's `PENDING` set (`grep -rn "PENDING" mobile/lib/skins/cinematic`) contains `ScreenId.discover`, `ScreenId.sources`, `ScreenId.source` and `ScreenId.dialogue`.
  - The primitives of `mobile/04` and `mobile/05` under `mobile/lib/skins/cinematic/primitives/`: `CineSearchField` with the `index` variant, slug lines, `CinePoster`, `CineRail`, galley proofs, the leader dial, `CineSheetRoute`, `CineDialog`, toasts, contents tabs, rows with row menus and reorder, menus and Quick look, notices, the certificate mark, pull to reprint, `SetHeading`, `TypedHeadline`, `CineMotion`.
  - The sources request limiter from `mobile/03` in `mobile/lib/core/network/` (`grep -rln "P3\|Priority.p3\|p3" mobile/lib/core/network`), with priorities P0–P3 and a way to run a request at a priority and to wait for a P2/P3 grant.
  - The shell from `mobile/06`: branch 2 routes, the thumb index with the Discover third-tap focus signal, the running head with `ContentModeChip`, the key registry for hardware keyboards (`Shortcuts`/`Actions`).
  - `backend/02` added `page` and `box` to `/ocr/search` items: `grep -n "box" backend/routes/ocr.py backend/services/*ocr*`.
- Read the legacy screens you replace, only to learn which providers and calls they use: `mobile/lib/features/library/screens/search_screen.dart`, `mobile/lib/features/sources/screens/sources_list_screen.dart`, `source_browser_screen.dart`, `mobile/lib/features/ocr/screens/ocr_search_screen.dart`, `mobile/lib/features/ocr/widgets/ocr_run_banner.dart`, `ocr_chapter_action.dart`. Never import from `screens/` or `widgets/` and never copy their look.
- Read the data layer you build on: `features/sources/{models,providers,repositories,utils}`, `features/library/providers/library_list_provider.dart` (`searchListProvider`, `SearchListNotifier.retrySource`, `searchGroupFilterProvider`), `features/library/utils/recent_searches.dart`, `features/ocr/{models,providers,repositories,services,controllers}`, `features/content_mode/`.

## Ground rules for this step

- **Track rule.** Work in `mobile/` only. Stage only your own paths explicitly (`git add <path> …`). `node design/build.mjs` may be run to regenerate outputs, but do not edit anything under `design/`, `brand/`, `frontend/` or `backend/`.
- **Skin boundary.** Screens live in `mobile/lib/skins/cinematic/screens/discover/…` and import only `features/*/{models,providers,repositories,services,store,queue,utils,controllers}`, `core/`, `shared/`, the generated contract and their own skin folder. `test/skins/import_boundary_test.dart` enforces it; never weaken it.
- **Shared logic goes in `features/`.** Anything Glass will also need (scope parsing, genre union, trending, health text, crop maths, the dialogue jump, source wash hue) is a skin-neutral Dart file in `mobile/lib/features/<area>/` with a unit test under `mobile/test/features/<area>/`.
- **Paths.** Build every location with the typed builders in `mobile/lib/skins/contract.g.dart` (`Routes`), never by string concatenation (series keys can hold `/`, `%` and spaces). Inside branch 2 use `push` for drill-ins (Sources → catalogue), `go` for cross-branch links (Dialogue → Downloads).
- **Tokens only.** Every colour, size, duration, curve and spring comes from `CineTokens` (`context.cine`) or the `static const` classes of `tokens.g.dart`. No literal `Color(0x…)` or `Duration(milliseconds: …)` in `lib/skins/cinematic/**` except the ones the DESIGN writes as literals (the 480 ms bubble pulse, the 3 s and 3.5 s opening-state timers).
- **Never** edit `backend/connectors/`, never touch production containers or `/srv/manhwamaniacs/{app,data}`.
- **RAM guard.** Production and five bots share this box. Run `free -m` before every `flutter analyze`, `flutter test` and harness run; if the `available` column is under 1024 MB, stop and report instead of running it. `pgrep -f "next build"` must print nothing before you start a Flutter command; never run two Flutter commands at once. No Gradle or Xcode on this box.

## Scope: every item this step delivers

Remove `discover`, `sources`, `source` and `dialogue` from the Cinematic `PENDING` set when their screens are done. Each screen registers its hardware-keyboard keys (iPad and Android keyboards, through the `mobile/06` key registry and `Shortcuts`/`Actions`) under the group named by its masthead title (`Discover`, `Sources`, `Catalogue`, `Dialogue`), and gives route focus to its level-1 heading through a `FocusNode` on its `Semantics(header: true, headingLevel: 1)`. Discover and Dialogue search have no visible title, so each renders a zero-size box carrying that semantics with the label `Discover` / `Dialogue search` (§8.20, §14.4).

### A. Shared data-layer additions (skin-neutral, each with a unit test)

1. `mobile/lib/features/sources/utils/discover_scope.dart`: `enum DiscoverScope { all, library, sources, dialogue, ask }` and `DiscoverScope parseDiscoverScope(String? value, {required bool aiAvailable, required bool dialogueAvailable})`. Unknown values and Glass's `text` map to `all`; `ask` maps to `all` when AI is unavailable; `dialogue` maps to `all` when not available (novels mode, `ocrFeatureVisibleProvider` false, or `GET /settings` capabilities `ocr` false). Test every branch.
2. `mobile/lib/features/sources/models/source.dart`: parse, if missing, `health` into `SourceHealth {status: ok | failing | dead | unknown, consecutiveFailures, demoted, lastOkAt, lastErrorAt, lastError, lastCheckedAt}` plus `language`, `browsable`, `mature`, `contentKind` and `iconUrl` from `GET /sources` rows (capabilities §16.1). Keep every existing field and constructor working.
3. `mobile/lib/features/sources/utils/source_health.dart`: `HealthDescription describeHealth(SourceHealth? health, DateTime now)` returning `{state: ok | failing | dead | unknown | demoted, label}` with the labels `OK · last checked 4 min ago`, `FAILING · 3 errors`, `DEAD since 12 Sep`, `DEMOTED` (demoted wins over the status; `unknown` when `health` is null or never checked), and `List<T> sortWorstFirst<T>(rows, SourceHealth? Function(T) health, String Function(T) name)` (dead, failing, demoted, unknown, ok; then by name). Test each label and the sort. `mobile/17` reuses both for System status.
4. `mobile/lib/features/sources/utils/genre_index.dart`: `List<GenreEntry> buildGenreIndex(List<SourcePin> pinned, Map<String, List<SourceGenre>> genresBySource, List<GenreWeight> weights)` returning `GenreEntry {genre, label, sourceIds}`: the union of the pinned sources' genre lists, merged case-insensitively (the label keeps the first spelling seen), ordered by weight (highest first), ties and genres without a weight alphabetical. Test merge, ordering and the empty case.
5. `mobile/lib/features/library/providers/genre_weights_provider.dart`: the one genre-weights client of the app, over `GET /library/recommendations?limit=` (`[{genre, weight}]`, the profile's gated genre affinity, capabilities §9; the source cinematic §9.1.3 names for Picks' `Your genres` and §9.2.1 for The Numbers' radar, and the same client `web/16` builds). Add `genreWeights({int limit = 40})` to `library_repository{,_impl}.dart` (`Result<List<GenreWeight>>`, `GenreWeight {genre, weight}` in `features/library/models/`) and `genreWeightsProvider` (`FutureProvider.autoDispose.family<List<GenreWeight>, int>` keyed by `limit`, kept alive for 10 minutes after the last listener, added to `profileScopedInvalidators` and to `mobile/07`'s mature-gate invalidation list) returning the list sorted by weight, highest first (ties alphabetical), or `[]` on an empty answer or an error. Discover reads `genreWeightsProvider(40)`; `mobile/19` (Picks' `Your genres`, `limit` 40) and `mobile/21` (the radar, `limit` 8) watch the same provider and add no other. Do not derive weights from `homeFeedProvider`: opening `/search` directly would otherwise fetch the whole `/home` composition. Test the request, the sort and the error fallback.
6. `mobile/lib/features/sources/utils/trending.dart`: `List<TrendingTitle> buildTrending(List<SourcePin> pinned, Map<String, List<SourceSeriesSummary>> popularFirstPage)` returning at most 10 `{title, sourceId, seriesKey}`: the first two titles per source in pin order, de-duplicated by case-folded title; a source with no `popular` browse mode contributes nothing. Test the cap, the de-duplication and the per-source limit.
7. `mobile/lib/features/sources/utils/source_wash.dart`: `int sourceWashHue(String sourceId)` = FNV-1a 32 of the UTF-8 bytes mod 360, and `Color sourceWash(String id)` = `HSLColor.fromAHSL(1, hue, 0.35, 0.06).toColor()`. Reuse an existing Dart FNV-1a if `grep -rn "0x811c9dc5\|0x811C9DC5" mobile/lib` finds one; otherwise add `mobile/lib/core/utils/fnv1a.dart` (offset basis `0x811C9DC5`, prime `0x01000193`, masked to 32 bits after each multiply). Test vectors (the same hash the web uses, §8.0.4): `asurascans` → `0x641F4639`, hue 33; `mangadex` → `0x899A8380`, hue 40; `weebcentral` → `0x88D2BCDB`, hue 3.
8. `mobile/lib/features/sources/utils/browse_freshness.dart`: from the `cache` block of `GET /sources/{id}/series` (`{status: fresh | live | stale, stale, fetched_at}`), `FreshnessLabel? browseFreshness(cache, now)` → `UPDATED 12 MIN AGO` when not stale, `SAVED COPY · 3 H` when stale (the same buckets as the web's `browse-freshness.ts`: `JUST NOW` under 1 min, `N MIN AGO` under 60, `N H AGO` under 48 h, `N D AGO` after), `null` when the block is absent. Parse the block into `SourceBrowseState` (add a `cache` field). Test.
9. Repository additions in `mobile/lib/features/sources/repositories/sources_repository{,_impl}.dart`, each returning `Result<…>` like the existing methods: `listGenres(sourceId)` (`GET /sources/{id}/genres`), `listHealth()` (`GET /sources/health`), `healthSummary()` (`GET /system/source-health` → `{total, ok, failing, dead, unknown, demoted}`), `searchGrouped(q, {page, perPage, int? tier})` passing `tier` and parsing `tier`, `next_tier`, `sources_failed`, `sources_deferred` and each group's `health`; `listSeries(…, {String? genre, bool refresh = false})`. Providers in `mobile/lib/features/sources/providers/discover_providers.dart`: `sourceGenresProvider` (family by source id; `ref.keepAlive()` with a 24 h timer that closes the link, so genres are fetched at most once per source per 24 h), `sourcesHealthProvider`, `sourceHealthSummaryProvider`, `popularFirstPageProvider` (family; the `popular` browse mode's page 1, only for sources whose `browse-modes` include `popular`), `genreIndexProvider`, `trendingProvider`. Extend `SearchListNotifier` (or add `federatedSearchProvider` beside it if the notifier cannot take tiers cleanly) to run tier 1, publish its groups, then run tier 2 when `next_tier == 2`, exposing `phase: idle | tier1 | tier2 | done`, `sourcesPending` and the failed count; keep `retrySource` and its per-source skeleton.
10. `mobile/lib/features/ocr/models/ocr_search_result.dart`: add `int? page` and `OcrBox? box` (`OcrBox {x, y, w, h}`, page fractions, from `backend/02`); both nullable, so old payloads parse. `GET /ocr/chapter` is already on the phone: `mobile/12` added `fetchChapterText(ChapterRef)` to `ocr_repository{,_impl}.dart` and `ocrChapterTextProvider` to `ocr_providers.dart` (404 → `null`). Reuse both; do not add a second method for the same call (if `mobile/12` did not land them, add exactly those names as `mobile/12` item A10 specifies).
11. `mobile/lib/features/ocr/utils/still_crop.dart`: `Rect stillCropWindow(OcrBox? box, double pageAspect)` returning the 16:9 crop window in page fractions (`left, top, width, height`), where `pageAspect` = page width / height (from the page list's `width` and `height`). Rules: the window width fraction is `box.w / 0.6` (the box fills 60 % of the still's width), capped at 1; its height fraction is `width × (9 / 16) × pageAspect`, capped at 1 (then the width is recomputed from the height); the window is centred on the box centre and clamped inside `[0, 1]` on both axes; `box == null` gives the top 16:9 (`left 0, top 0, width 1, height min(1, 9 / 16 × pageAspect)`). Test a centred box, a box at each edge, the null case and a very wide page.
12. `mobile/lib/features/ocr/utils/engine_label.dart`: `engineLabel(String? engine)` → `VISION` for `vision`, `apple_vision`, `apple-vision` (case-insensitive), `ML KIT` for `mlkit`, `ml_kit`, `ml-kit`, otherwise the engine string upper-cased, `—` for null. Test.
13. `mobile/lib/features/ocr/providers/dialogue_jump_provider.dart`: `DialogueJump {sourceId, seriesKey, chapterKey, q, page, box}` and `dialogueJumpProvider` (a kept-alive `Notifier<DialogueJump?>`) with `set(jump)` and `DialogueJump? take(sourceId, seriesKey, chapterKey)` that returns a matching entry once and clears it. `int? findMatchPage(List<PageText> pages, String q)` (over the page-text type `fetchChapterText` returns) returns the first page whose text contains every whitespace-separated term of `q`, case-insensitive, with diacritics folded, or `null`. The folding lives in `mobile/lib/core/utils/text_fold.dart` (`mobile/18`'s settings search reuses it): `foldDiacritics(String)` maps the Latin-1 Supplement and Latin Extended-A letters (U+00C0–U+00FF, U+0100–U+017F) to their base ASCII letters through a `const` map (Dart has no `normalize('NFD')`; this covers the Latin text OCR produces), tested in `mobile/test/core/utils/text_fold_test.dart`. The route contract (`?page&at&all`) is not changed. Test the one-shot take and the matcher including `é`, `ñ`, `ł`.
14. `mobile/lib/features/library/utils/recent_searches.dart`: add `clearRecentSearches(SharedPreferences prefs, {int? profileId})` writing an empty list under the same `recentSearchesKeyFor(profileId)` key, with a test.

**Request priorities** (§15.6) for every call this step adds or renders, through the `mobile/03` limiter: **P1** federated search tiers, library search, per-source retry, source lists, pins, browse pages, catalogue search, OCR search, the chapter page list a dialogue still needs; **P2** covers in view (posters, genre tile covers, source logos loaded through the proxy); **P3** genre lists of pinned sources, the `popular` pages behind Trending, the genre tile cover lookups and dialogue still page images at 480 px wide (`?w=480`). P3 runs only while at least 20 tokens remain, at most 2 in flight; on a `429` the limiter pauses P2 and P3 for `Retry-After`. Images already in the image cache or on disk (downloaded chapters) cost nothing. Add a unit test asserting that the dialogue still image loader and the genre cover lookup request at P3.

### B. Discover screen (`/search`, ScreenId `discover`), §8.20, mobile S20

Hierarchy: the index field, then the scopes, then results grouped by source (or the idle page). Query state: `?q=` and `?scope=` written with `context.go` on the same branch location (replace, no new stack entry per keystroke), parsed with `parseDiscoverScope`. A `genre` query key (`/search?genre=Romance`, written by Picks in `mobile/19`) opens that genre's sheet on mount.

**Phone (< 600 dp, 4 columns):**
1. Mood grade behind the top 30 % of the viewport height (§2.1.6: the profile mood's grade colour to `#000000`; none for `default`), with the raised-stock scope (`CineStock.raised`) on it.
2. Masthead block without a title: kicker `No. 04 — DISCOVER` (`type.kicker`, `SetHeading` trigger `mount`), the zero-size route-focus heading `Discover`, then the **index field** (§7.4 `index` variant) at the phone `type.field` size: Bodoni Moda Italic, opsz 48, wght 500, 28/36, tracking −0.015em, text-scale cap 1.3; the placeholder "Search every source" typed at 50 ms per grapheme in `ink.45` while the field is empty and unfocused (`TypedHeadline` in an `ExcludeSemantics` layer; the `InputDecoration.hintText` holds the full string for semantics and shows statically while focused and empty); typed text switches to Bodoni Moda Roman; a `spot` cursor 3 px wide (`cursorWidth: 3`, `cursorColor: colorSpot`); a 1 px `rule.2` underline that becomes 2 px `spot` drawn from the left over 240 ms `easeSettle` on focus; a trailing `quiet` "Clear" once there is text. `TextInputAction.search`, `keyboardType: TextInputType.text`, `textCapitalization: none`, `autocorrect: false`; `onSubmitted` searches at once. Semantics label "Search every source".
3. The running head shows `DISCOVER` once the masthead scrolls under it, and carries the `ContentModeChip` (`MANGA ▾`, §7.29) when novels are enabled.
4. Scope tabs under the field as contents tabs (§7.12), a horizontally scrolling row: `01 ALL · 02 LIBRARY · 03 SOURCES · 04 DIALOGUE · 05 ASK`. `DIALOGUE` renders only in manga mode with OCR available; `ASK` only when `suggestAvailabilityProvider` says `available`. Folios renumber over the visible tabs. A scope change is a **Cut** (0 ms), never moves focus, and fires haptic `select`.
5. **Idle page** (no query), sections separated by the §2.2.2 rhythm (1 px `rule.1` → 12 → header → 12 → content → 64):
   - `RECENT`: a slug line of the last 4 searches of this profile (min 2 characters, `readRecentSearches`), each a chip that fills the field and searches, plus a `quiet` `Clear` (`clearRecentSearches`). Hidden when empty.
   - `ASK THE EDITORS` (only when AI is available): a Feature-sized block (§7.6 proportions, no image): kicker `ASK THE EDITORS`, the example "A murim regressor who comes back stronger" typed at 50 ms per grapheme in `type.pull` (Bodoni Moda Italic 24/32), a deck in `type.deck` `ink.60` "Describe it in your own words; the editors pick from everywhere.", and `Ask` (secondary with `sparkle` 20 Regular) that `go`es to `Routes.picks` with `?ask=1` (Picks focuses its ask field on that key, `mobile/19`).
   - `01 Browse by genre` (H3 section head, `SetHeading` trigger `inView`): genre tiles from `genreIndexProvider`, capped at 12 tiles, then a `quiet` toggle `All {n} genres` revealing the rest. Tile: 16:9, radius 0, the cover of the first series of that genre on the first pinned source that has it (a P3 `GET /sources/{id}/series?genre=&page=1` lookup, first item), duotoned to that series' own `ambient.duo` (fallback `#B8B2A4`) with `duotone.dart`, the genre name in Bodoni Moda Italic 20/24 (`type.subhead` phone size) in `ink.100` on the solid end of `scrim.foot`. Pressed: a 1 px impression (80 ms `easeSet` down, 160 ms `easeSettle` up). While the cover loads the tile is a `paper.1` plate with the genre name set on it. Two tiles per row. A tile opens a **genre sheet** (`CineSheetRoute`, content-fit): kicker `GENRE`, title the genre, one row per pinned source exposing it (logo 24, name `type.title`, health mark) that `push`es `Routes.source(id)` with `?genre=`; when only one pinned source has the genre, the tile opens that catalogue directly (Cut). No pinned sources: the section is not rendered.
   - `02 Sources`: pinned sources as a credits list (logo 24, name, the 6 × 6 health mark with its label, the 16 px `18` certificate when the source is mature and visible), then `All {n} sources →` (`quiet` with `arrow-right` 16) that `push`es `Routes.sources`.
   - `03 Search what they said` (manga mode with OCR only): an entry block with the `bubble-search` glyph at 32 px Light `ink.45`, kicker `DIALOGUE`, the line "Find the chapter by a line someone said." and a link that `push`es `Routes.dialogue`.
   - `04 Trending on your sources`: a slug line of up to 10 titles from `trendingProvider`, each opening its feature page (match cut). Absent when no pinned source has a `popular` mode.
   - The idle sections renumber with no gaps when one is absent.
6. **Results** (after a 300 ms debounce, or at once on the keyboard's search key):
   - Status line (`type.caption`, Archivo wdth 90 wght 450 13/16) in a `Semantics(liveRegion: true)`: "Searching your library and 12 pinned sources…" → "48 results · 12 sources" → "48 results so far · searching 77 more sources…" with the indeterminate rule (a 25 %-wide `spot` segment, 1200 ms linear loop) while tier 2 runs; failures add "3 sources didn't answer." under the `NOTE` kicker in `spot`.
   - Filter slugs above the groups: `ALL · WITH RESULTS · PINNED` (single-select, the underline slides 320 ms `easeSettle`; haptic `select`), bound to `searchGroupFilterProvider`.
   - Group order: `IN YOUR LIBRARY` (library search, the Library mark = the `mm-mark` glyph 24 px), then source groups in tier order, then `IN DIALOGUE` (manga mode with OCR only: the top 3 OCR hits as compact transcript rows, and `See all` that `push`es `Routes.dialogue` with `?q=`).
   - Each group: a subhead row (24 px source logo or the Library mark, source name in `type.title`, count badge: fill `spot`, `#000` Plex Mono 10, health mark) and a `CineRail` of posters in caption mode **Below**: title on 2 lines (`type.title`), folio caption `CHAPTERS 120` in `ink.45`, 3.2 visible posters (2.3 at text scale ≥ 1.3), gap 8. Library hits open `Routes.featureByFollow(id)`, source hits `Routes.feature(sourceId, seriesKey)`, both with the match cut (a `Hero` keyed by the `(sourceId, seriesKey)` tuple; `CineMatchCutPage` on Android).
   - Failed group: the header stays; a `CORRECTION` caption "This source didn't answer." in `proof` and a `quiet` `Retry` retrying only that source, showing two flicker plates while it runs.
   - Empty groups collapse into one `quiet` toggle `Show 31 sources with no matches` (and `Hide …` when open).
   - A `Jump to source` `quiet` button under the status line opens a sheet listing the groups with their counts; tapping one scrolls to the group in 400 ms `durGlide` `easeSettle` (a `jumpTo` under reduced motion) and focuses its header.
   - Results **Set** group by group as tiers arrive (first data paint only; a later tier's groups use one 160 ms fade for the appended block, §4.6).
7. **ASK scope**: the field's hint and semantics label become "Describe what you feel like reading"; the search key submits `POST /library/world/suggest {prompt}` (3–600 characters, through the existing `suggestionsProvider`). Thinking state: the typed line "Reading your shelf…", a 24 px leader dial after 1 s, then World cards (§7.6) fading in 160 ms each, 30 ms apart, one column. A `quiet` button `Search sources for "{q}" instead` switches to `ALL` with the same text. Unavailable, budget, rate-limited and failure states use the §9.1.8 copy (item G) and never `proof`.

**Tablet (≥ 600 dp, 8 columns, §8.0.9):** the index field across 8 columns at 32/40; genre tiles 3 per row; result rails at 5.2 visible posters (gap 12); the group jump stays a sheet button; the idle sections' content spans 8 columns.

**Keyboard and third tap.** The keyboard opens on the third tap of the Discover thumb-index tab (the `mobile/06` signal) and on `/` with a hardware keyboard. The Discover, Sources, catalogue and Dialogue screens each listen for the shell's focus-search signal and focus their own search field.

**Transitions.** In: the shell's section change (Cut + Set + Folio flip). `?q=` prefilled when arriving from Picks' `Search my sources`. Out: match cut to feature pages, Page to Sources.

**Hardware keys (iPad, Android keyboards).** `/` focuses the field; `Esc` clears, then unfocuses; `Enter` searches now; `↓` moves focus into the first result rail; `1`–`5` switch to the visible scope at that position; `[` / `]` previous and next result group.

**States (each built, widget-tested and captured):** idle; searching (tier 1: three groups of four flicker plates after the 120 ms skeleton delay); partial (tier 2 running); results; no results (notice `NOTHING FOUND`, headline typed "No series match "{q}" in your library or sources.", plus `Ask the editors` when AI is available); offline (notice `OFFLINE EDITION`, "Search needs a connection to reach your library and sources.", plus the global offline line "Saved chapters still open." and `Go to Downloads`, which `go`es to `Routes.downloads`); error (`CORRECTION` notice with `Try again`); rate limited (`SLOW DOWN` notice with the live "Retrying in 12 s" folio from `Retry-After`). Pull to reprint (§7.29) reruns the current query; haptic `refresh.arm` at the 96 px trigger.

**Signature moment.** Typing in the index field in Bodoni Italic that turns Roman as it becomes a query; results then Set group by group as tiers arrive.

### C. Sources screen (`/sources`, ScreenId `sources`), §8.21, mobile S16

1. Masthead: kicker `No. 04 — DISCOVER / SOURCES`, title "Sources" (`type.masthead` 40/40, `SetHeading` trigger `mount`), deck "89 sources · 84 healthy · 6 pinned" from `sourceHealthSummaryProvider` and the pins (counts after the 18+ gate, so a gated profile sees about 33 with no gaps), `rule.heavy` drawn after the letters land.
2. Toolbar: a `compact` search field (§7.4) "Filter sources" matching name or id (`sourcesFilterQueryProvider`); the slug line `ALL · PINNED⁶ · 18+` (`sourcesFilterProvider`; the `18+` slug only when the profile's gate is open; raised counts per §7.5), scrolling horizontally. The list follows the reading mode (`ContentModeChip` in the running head when novels are enabled).
3. **Pinned** section first: rows in pin order, each with a `dots-six-vertical` drag handle (20 Regular) at the trailing edge in a `ReorderableListView` (`buildDefaultDragHandles: false`, `ReorderableDragStartListener` on the handle). The lifted row rises 1 px with a 1 px `ink.100` outline (no shadow: `proxyDecorator` returns the row with a `Border.all(color: colorInk100)`); siblings shift 240 ms `easeSet`; drop fires haptic `select`. Every drop and every Move item writes the full ordered list with `PUT /sources/pins` (`SourcePinsNotifier`, max 50). Row menus carry `Move up`, `Move down`, `Move to top`, `Move to bottom` (disabled at the ends), each announced with `SemanticsService.announce` ("Asura moved to position 3 of 6", polite); `ReorderableListView` exposes the same four actions to screen readers. Pins whose `available` is `false` are not rendered and are kept in the list written back, so they return when the source does.
4. **All sources** section: rows 64 dp: logo 32 (favicon, or a Bodoni Moda initial on `paper.1`), name (`type.title`) with the description under it (`type.caption`, 1 line, ellipsis), at the right the health mark (6 × 6 square) and the 16 px `18` certificate for mature sources, and the pin toggle (`bare` icon button, `push-pin` 24 Light; pinned = Fill with a 2 px `spot` rule 4 px under the square; 44 pt / 48 dp hit; `Semantics(toggled: pinned, label: "Pin {name}")`). Health colours: ok `set` `#57D68D`, failing `spot` `#F4D03F`, dead `proof` `#FF5B4A`, unknown `ink.45` `#7A7770`, demoted `ink.60` `#9A978F`; the `describeHealth` text sits in the row's semantics label and in Health details.
5. Row tap `push`es the catalogue (Page). Pin: haptic `select`, toast "{name} pinned" / "{name} unpinned"; failure toast "Couldn't update your pinned sources." (error, 6000 ms, `proof` edge). Pins that fail to load: a `NOTE` banner strip "Pinned sources couldn't be loaded, so pinning is off until they are." with `Try again`, and every pin toggle disabled with that reason as its tooltip.
6. **Long-press** a row (450 ms; haptic `longpress.open`) opens the row menu: `Pin` / `Unpin` / `Open` / `Health details` (a `CineSheetRoute` with the last error in Plex Mono on `paper.1` in `ink.60` and the last OK time), plus the four Move items on pinned rows. A trailing `dots-three` button on each row opens the same menu (the non-gesture alternative). Pull to reprint refetches `GET /sources` and `GET /sources/pins`.
7. **Tablet (≥ 600 dp):** the desktop directory table of §8.21 on 8 columns without the `LANGUAGE` column: logo 32, name + description, `KIND` (`MANGA` / `NOVEL`), health (mark plus `describeHealth` text on one aligned column rule, "DEMOTED" with a 1 px strike-through), `18`, pin toggle.
8. Hardware keys: `/` filter; `j` / `k` next / previous row; `Enter` open; `p` pin toggle on the focused row; `Alt+↑` / `Alt+↓` move the focused pinned row.
9. States: loading (10 greeked rows at their exact heights, flicker); error (`CORRECTION` notice + `Try again`); offline (notice `OFFLINE EDITION` "The source list needs a connection." with the pinned rows below it from the last cached list `source_pins_cache.dart`, read-only); none installed ("No sources installed on this server."); no match ("No sources match "{q}"."); pinned empty ("No pinned sources. Tap the pin on any source to keep it at the top.").
10. Transitions: in by Page from Discover; out by Page to the catalogue. Signature: the health column reads like a festival listing (on tablets, every mark and status on one column rule, dead sources struck through).

### D. Source catalogue (`/sources/:sourceId`, ScreenId `source`), §8.22, mobile S17

Query state `?mode=`, `?genre=`, `?q=` (replaced on the same location).

1. Running head: back, logo 24 and the source name. Masthead: logo 48 beside the name in `type.masthead` (`SetHeading` trigger `signal`); deck "Catalogue · 1,240 series" (+ ` · "{q}"` when searching); the freshness credit `UPDATED 12 MIN AGO` or the `SAVED COPY · 3 H` badge (1 px `spot` outline, `NOTE` semantics, tooltip and semantics "The source is down; this is the last copy we saved."), re-rendered every 30 s by a `Timer.periodic`; `Refresh` (`quiet` with `arrow-clockwise` 16; while refreshing the glyph becomes a 16 px leader dial; `SourceBrowseNotifier.refresh` with `refresh=true`).
2. Toolbar: the `compact` search field "Search this source" (300 ms debounce, `TextInputAction.search`); browse modes as contents tabs with the server's labels (any string, horizontally scrollable, hidden while searching); a `Genre` control that opens a sheet (single-select list, first item "All genres"; only when `sourceGenresProvider` returns genres).
3. **Grid**: a `SliverGrid` poster wall in caption mode Below, title on 2 lines, no folio line: 3 per row on phones, 5 per row on tablets. Novel sources render the book list of §8.9.1 (the `mobile/09` component).
4. Infinite scroll: load the next page when the scroll position is within 600 px of the end (`SourceBrowseNotifier.loadMore`); `LOADING MORE` caption with a 16 px leader dial; load-more failure "Couldn't load more." + `Retry` (refetches only that page); the end: a 1 px `rule.1` and the `END OF CATALOGUE` kicker centred.
5. **Opening state** (first load): the source name sets itself with the letter reveal; a 32 px leader dial beside the deck (after the 400 ms delay); flicker plates for the grid; after 3 s the deck changes to "This source can take about 10 s." and a line of tips types itself at 50 ms per grapheme, rotating every 3.5 s through exactly the §8.22 list: "Press / to search this source.", "Pick a browse mode to change the order.", "Tap a genre on any series to browse it here.", "Your progress syncs across devices."; also after 3 s a background wash fades in over 800 ms `durDissolve` `easeTurn`: `sourceWash(id)` behind the masthead band (top 30 %, a `LinearGradient` to `#000000`, raised-stock scope on it). Data arrival dissolves the plates into posters (160 ms). Haptic `select` once when the first page of results lands.
6. A floating `TOP` square button: 40 px, `paper.2`, 1 px `rule.2`, `arrow-up` 20 Regular inside a 44 pt / 48 dp hit area, semantics "Back to top", bottom-right 16 px from the edge and 16 px above the thumb index; appears after 400 px of scroll; scrolls to top in 400 ms `durGlide` (`jumpTo` under reduced motion).
7. Pull to reprint refreshes from the source (`refresh=true`).
8. Hardware keys: `/` search; arrows and `h j k l` move through the wall, `Home` / `End`; `Enter` open; `[` / `]` previous and next browse mode; `r` refresh.
9. States: opening; loaded; empty ("No series found." or `No results for "{q}" on this source.`); full error (`CORRECTION` "Couldn't load the catalogue." + the server message + `Try again`); stale (the badge above); offline (the saved copy if one exists, else the `OFFLINE EDITION` notice); rate limited (a live countdown in the deck from `Retry-After`: "Rate limited · retrying in 12 s"); not available (`source_not_found` or a gated source: the §8.0.10 notice with kicker `NOT IN THIS ISSUE`, headline typed "This source isn't available here any more.", deck "It may have been removed from its source.", `Back to Tonight` and `Search for it`); **not browsable** (`browsable == false` on the source, or a `source_not_browsable` error code): notice "This source can only be searched, not browsed." with `Search it`, which focuses this catalogue's own search field; while not browsable, the browse-mode tabs and the genre control are hidden and a search renders in the wall as usual (a search here is scoped to this one source through `GET /sources/{id}/series?query=`).
10. Transitions: in by Page from Sources, Cut when opened from a genre link; out by match cut to feature pages.

### E. Dialogue search (`/ocr`, ScreenId `dialogue`), §8.24, mobile S27

The mobile alias `/ocr/search` stays registered (the `mobile/06` router). The route is reachable only when `ocrFeatureVisibleProvider` is true (on-device engine available and manga mode); otherwise it shows the notice "Dialogue search isn't available on this device." and every entry to it (Discover's section 03 and `IN DIALOGUE`, the Index row in `mobile/17`) is hidden. When `GET /settings` capabilities say `ocr` is false the notice reads "Dialogue search isn't available on this server."

1. Masthead: kicker `No. 09 — DIALOGUE`, the zero-size route-focus heading "Dialogue search", the index field with the typed hint "Search what a character said" (semantics label the same), deck "Across chapters whose dialogue has been read, in series you follow.", then the mobile scanning entry: a caption line "Scan more chapters from Downloads" whose `Downloads` link `go`es to `Routes.downloads`. `?q=` in the location.
2. Results as **subtitled stills** (`ocrSearchProvider` with `limit=20`, then `Show more` with `offset`), one per block, in a `ListView.builder`:
   - The 16:9 still, radius 0, full width, darkened to brightness 0.8 (`ColorFiltered` with the matrix `[0.8,0,0,0,0, 0,0.8,0,0,0, 0,0,0.8,0,0, 0,0,0,1,0]`): the page image cropped in layout with `stillCropWindow(box, aspect)`: a `ClipRect` around an `AspectRatio(16 / 9)` whose `LayoutBuilder` sizes the page at `pageW = maxWidth / window.width`, `pageH = pageW / aspect`, and places it with an `OverflowBox(alignment: Alignment.topLeft, maxWidth: double.infinity, maxHeight: double.infinity)` and `Transform.translate(offset: Offset(−window.left × pageW, −window.top × pageH))` (a pure layout crop; §8.24 names `FittedBox` + `Alignment`, and this is the exact-window form of the same idea). The matched line is laid over the lower third as a subtitle: Newsreader 18/24 `ink.100` (text-scale cap 1.3, max two lines), centred, on a `color.onart` band (`#000000` at 0.64), 8 × 12 px padding, the matched terms under the `spot.wash` highlighter (`rgba(244,208,63,0.16)`). With no box, the top 16:9 of the page; with no known page the still is absent and the block is text only.
   - Crops load when `ListView.builder` builds the item: the chapter page list (`GET /sources/{id}/chapters/{key}/pages`, cached per chapter, P1) gives the page URL, `width` and `height`; the image comes from the existing proxy at `?w=480` (P3). Downloaded chapters crop from the local blob store (the store's page file for that page), with no request. No image work runs on the server.
   - Under the still: the transcript, the full snippet in Newsreader 18/28 with the matched terms under the highlighter in `ink.100` (use the existing `features/ocr/services/ocr_snippet.dart` parser and `highlighted_terms`; never render raw markup), then a credit line `TOWER OF GOD · CH 88 · PAGE 12 · 214 WORDS · VISION` (series title joined from the followed library cache; `engineLabel()`), and the series cover at 32 × 48.
   - Block states: pressed fills `paper.3`; focus ring around the block (hardware keyboard).
3. Tap a block: `dialogueJumpProvider.set(…)`, then open the reader for that chapter through `mobile/06`'s `enterReader(context, target, entry: ReaderEntry.dip)`, the **Dip** (440 ms). In the Cinematic reader chrome (`mobile/lib/skins/cinematic/screens/reader/`, from `mobile/12`), call `take(…)` once when the chapter's first frame lays out: when `page` is known, move there with the engine's `jumpToPage(page)`; otherwise read `ocrChapterTextProvider` for the chapter and use `findMatchPage`. Then draw `BubblePulse` (`mobile/lib/skins/cinematic/screens/reader/bubble_pulse.dart`): a 2 px `spot` frame around the box, drawn inside the page's own box through the engine's per-page overlay slot `pageOverlayBuilder` (`mobile/13` item A7, box fractions converted by `mobile/13`'s `ocr_boxes.dart`) and reusing the pulse `mobile/13`'s `ocr_overlay.dart` draws for the DIALOGUE tab, so the frame follows scroll and zoom; add no new engine query. It shows twice for 480 ms each (opacity 0 → 1 → 0, `easeSettle`), with the toast "Found on page 12." When no page matches: toast "Opened at the chapter start. The line is in this chapter." Reduced motion: the frame shows once, statically, for 960 ms. Test the reader hook in a widget test with a fake engine for both paths.
4. Overflow note: "Showing the first 20 of 134 matches. Narrow the search." + `Show more`.
5. Novels mode: the notice "Dialogue search is for manga. Switch to Manga, or search the novels' text." with `Search novels` (`go` to `Routes.discover`).
6. **Tablet (≥ 600 dp):** the desktop two-column block of §8.24 on 8 columns: the still in columns 1–4, the transcript and credit line in columns 5–8, cover 40 × 60.
7. Signature moment: each still racks into focus (Rack focus: blur 14 → 0, brightness 0.6 → 1, scale 1.03 → 1 over 520 ms `durRack` `easeSettle`; at most 12 at once per screen through `CineMotion.play`, the rest **Develop**) with its subtitle already set, then the highlighter sweeps across the matched words in the subtitle and the transcript (Highlight sweep: 200 ms `durClip` per band, left to right, 60 ms apart, `easeSet`).
8. Hardware keys: `/` field; `j` / `k` next / previous block; `Enter` open.
9. States: idle ("Type a line you remember."); loading (three greeked blocks: a flickering 16:9 plate plus greeked lines); crop loading (a `paper.1` plate with the subtitle already set over it); crop failed or page not found (the plate stays, subtitle intact, a 16 px `image-broken` glyph in `ink.60` at its bottom-right corner, semantics "Page didn't load"); no matches (notice: "Nothing found for "{q}". Only chapters whose dialogue was scanned, in series you follow, can be searched."); offline (`OFFLINE EDITION`, "Dialogue search needs a connection."); error (`CORRECTION` + `Try again`); not available on this device or server (above).

### F. The on-device scan widgets (capabilities §20, §8.23 "Dialogue scan"), kept on `mm/ocr`

No change to `OcrChannel.kt`, `AppDelegate.swift`, `ocr_engine.dart` or `ocr_run_controller.dart` beyond what a test needs. Build the Cinematic widgets that drive the existing `ocrRunControllerProvider`, so `mobile/17` mounts them in Downloads and `mobile/19` in the recap's `Scan saved chapters`:

1. `mobile/lib/skins/cinematic/screens/discover/dialogue/scan/dialogue_scan_block.dart`: shown only while an OCR run exists: kicker `READING THE DIALOGUE`; recognizing: "Page 3 of 40" with a 2 px determinate rule (track `rule.1`, fill `spot`, width 240 ms `easeSet`); paused: a `NOTE` line "Text extraction pauses in the background; keep the app open."; uploading: "Saving the transcript…" with the indeterminate rule; done: "214 words are now searchable." + `Search dialogue` (`go` to `Routes.dialogue`); cancelled: "Scan cancelled."; failed: `CORRECTION` line with the error and `Try again` (reruns that chapter); `Cancel` (`quiet`) while busy. Haptic `success` on done, `error` on failure.
2. `mobile/lib/skins/cinematic/screens/discover/dialogue/scan/scan_dialogue_button.dart`: the chapter-row action for a saved manga chapter when OCR is available: `bare` icon button with `bubble-search` 20 Regular (semantics "Scan dialogue"); while that chapter is scanning the glyph becomes a 16 px leader dial; when the chapter is indexed (`ocrCoverageProvider` word count > 0) it shows the `TEXT` badge (1 px `ink.45` outline, `type.micro`) and a tap asks "Scan this chapter again?" in a `CineDialog` (`Scan again` primary, `Cancel` quiet).
3. Add both to the `mobile/04` Diagnostics-only primitives gallery with fixture states for the harness.

### G. Cross-cutting on all four screens

- **18+:** mature sources, series and badges are absent when the gate is closed; no count, placeholder or blurred tile mentions them. With the gate open, the 16 px certificate (§7.19) marks mature sources and posters.
- **Content mode** (§8.0.8): Discover results, Sources and catalogues follow the reading mode; dialogue search is manga-only.
- **Long-press** (450 ms, haptic `longpress.open`) on posters and result cards opens Quick look (§7.22, the `mobile/05` sheet with the `mobile/08` actions), mirrored by a trailing `dots-three` on result rows.
- **Reduced motion** (`CineMotion.reduced(context)`: the OS setting or Settings → Appearance `ON`): letter reveals become a 200 ms whole-string fade; typed hints, tips and headlines show the full text with no caret; Set and Develop become a 160 ms fade; Rack focus a 160 ms opacity fade; rules present at rest; slug and tab underlines fade 150 ms in place; programmatic scrolls (group jump, TOP) `jumpTo`; highlighter bands show at their end state; skeletons static at 0.8 opacity; Dip and Page become 150 ms cross-fades; the source wash appears without the dissolve. Leader dials and the indeterminate rule keep running.
- **Screen readers:** every control has a label; health marks carry the `describeHealth` text; counts and folios read through `folioLabel()`; the status line is a live region.
- **Haptics and sound:** `select` on scope, filter, slug, pin and reorder drop, and once when a catalogue's first page lands; `longpress.open` on Quick look and row menus; `refresh.arm` on pull; `sheet.detent` when a sheet settles. Sound, when on: `tick` for `select` and `refresh.arm`; nothing else here.
- **Focus (hardware keyboard):** `CineFocusRing` (2 px `ink.100` at 2 px offset over a 6 px `#000000` band) on every control; rails and walls keep 8 px vertical padding so it is never clipped.

### H. AI copy for the ASK scope and the Ask-the-editors block

Use the §9.1.8 vocabulary exactly. Find the Dart module `mobile/08` created for it (`grep -rln "The picks desk is closed tonight" mobile/lib`) and reuse it; if none exists, create `mobile/lib/skins/cinematic/ai_copy.dart` exporting this table keyed by reason or error code, and `mobile/19` extends it:

| Key | Copy |
|---|---|
| `budget_exhausted` / `ai_budget_exhausted` | "The picks desk is closed tonight. Asks reset at midnight UTC." |
| `not_configured` / `ai_not_configured` | "The editors' desk isn't set up on this server." |
| `rate_limited` | `SLOW DOWN`: "Too many asks at once. Try again in {n} s." with the live `Retry-After` countdown |
| `ai_failed` | "The editors couldn't answer that one. Try describing it differently." |

The unavailable state is a `NOTE` kicker in `spot` with the reason in `type.caption` `ink.60`, never `proof`. Branch on the error `code`, never on the HTTP status (429 is both `ai_budget_exhausted` and `rate_limited`).

## Values you need (copied from `cinematic/DESIGN.md`)

| What | Value | Section |
|---|---|---|
| Ground, plates, sheets | `paper.0` `#000000` (`colorPaper0`), `paper.1` `#0B0B0A`, `paper.2` `#121211`, `paper.3` `#1A1A18`, `paper.4` `#232220` | §2.1.1, §2.8.1 |
| Rules | `rule.1` `#2B2A27`, `rule.2` `#3D3C38` | §2.1.1 |
| Inks | `ink.30` `#4D4B47` (disabled only), `ink.45` `#7A7770` (on `paper.0` only), `ink.60` `#9A978F`, `ink.80` `#C9C6BE`, `ink.100` `#F3F0E8` | §2.1.1 |
| Spot | `spot` `#F4D03F`, `spot.press` `#D9B62C`, `spot.wash` `rgba(244,208,63,0.16)` | §2.1.2 |
| Semantic | `proof` `#FF5B4A`, `set` `#57D68D`, `color.onart` `rgba(0,0,0,0.64)` | §2.1.3, §2.8.1 |
| Durations (`CineDur` / `durX`) | cut 0, tick 80, beat 160, line 240, column 320, spread 480, dissolve 800, type 50 per grapheme, snap 120, reduced 150, clip 200, pageOut 224, rack 520, glide 400, loopRule 1200, flicker 1400, leader 1000 (ms) | §2.8.4, §4.2 |
| Curves | `easeSettle` `Cubic(0.16, 1, 0.3, 1)`, `easeLift` `Cubic(0.7, 0, 0.84, 0)`, `easeTurn` `Cubic(0.65, 0, 0.35, 1)`, `easeSet` `Cubic(0.2, 0, 0, 1)` | §2.8.4, §4.3 |
| Springs | `springRelease` `{ms 420, bounce 0}` → `SpringDescription.withDurationAndBounce(duration: 504 ms, bounce: 0)`; `springSheet` `{480, 0}` → 576 ms | §2.8.4, §4.4 |
| Stagger | grids +32 ms per item, +64 ms per row, cap 480; lists +24 ms, cap 360; letters +24 ms, cap 560, start 120 ms after the rule | §4.6 |
| Letter reveal | opacity 0 → 1 and rise 0.42 em over 640 ms, blur 8 → 0 px over 440 ms, `easeSettle` | §10.1.1 |
| Typing | one grapheme per 50 ms, caret `spot` 0.12 em × 0.86 em, blink 530 ms halves | §10.2.1 |
| Type (phone / tablet) | `type.field` 28/36 · 32/40; `type.masthead` 40/40 · 56/56; `type.subhead` 20/24 · 22/28; `type.pull` 24/32 · 28/36; `type.title` 15/20; `type.caption` 13/16; `type.kicker` 11/16 · 12/16; `type.folio` 12/16; `type.micro` 10/12; caps: display 1.15, field/subhead/pull 1.30, reading and UI 2.0, micro 1.5 | §3.2, §3.3 |
| Rails | visible posters 3.2 phone (2.3 at text scale ≥ 1.3) · 5.2 tablet; gap 8 · 12 | §7.8 |
| Grid | phone 4 columns, margin 16, gutter 12; tablet (≥ 600) 8 / 32 / 16 | §2.2.2 |
| Hit areas | 44 × 44 pt iOS, 48 × 48 dp Android, ≥ 8 px apart | §14.6 |
| Running head / thumb index | 44 pt iOS, 48 dp Android + top inset / 56 + bottom inset | §7.13, §7.14 |
| Sheet | `paper.2`, grabber 32 × 3 `ink.30`, header 56, Rise 360 ms, barrier `scrim.modal` `rgba(0,0,0,0.78)`, dismiss below 30 % or faster than 800 px/s | §7.9 |

## File layout

```
mobile/lib/features/sources/utils/{discover_scope,source_health,genre_index,trending,source_wash,browse_freshness}.dart
mobile/lib/features/sources/models/source.dart                     (health, language, browsable, mature, contentKind, if missing)
mobile/lib/features/sources/models/source_genre.dart
mobile/lib/features/sources/repositories/sources_repository{,_impl}.dart   (genres, health, summary, tier, genre/refresh)
mobile/lib/features/sources/providers/discover_providers.dart
mobile/lib/features/library/providers/library_list_provider.dart   (tiered search, or a sibling federatedSearchProvider)
mobile/lib/features/library/utils/recent_searches.dart             (clearRecentSearches)
mobile/lib/features/library/providers/genre_weights_provider.dart   (+ library_repository genreWeights, the GenreWeight model)
mobile/lib/core/utils/fnv1a.dart                                   (only if no Dart FNV-1a exists)
mobile/lib/core/utils/text_fold.dart
mobile/lib/features/ocr/models/ocr_search_result.dart              (page, box, OcrBox)
mobile/lib/features/ocr/utils/{still_crop,engine_label}.dart
mobile/lib/features/ocr/providers/dialogue_jump_provider.dart
mobile/lib/skins/cinematic/ai_copy.dart                            (only if mobile/08 did not create an equivalent)
mobile/lib/skins/cinematic/screens/discover/
  discover_screen.dart  index_field_header.dart  scope_tabs.dart  discover_idle.dart  genre_tiles.dart
  genre_sheet.dart  pinned_credits.dart  trending_line.dart  discover_results.dart  result_group.dart
  group_jump_sheet.dart  ask_scope.dart  discover_keys.dart
mobile/lib/skins/cinematic/screens/discover/sources/
  sources_screen.dart  source_row.dart  source_table.dart  health_mark.dart  health_details_sheet.dart  sources_keys.dart
mobile/lib/skins/cinematic/screens/discover/catalogue/
  catalogue_screen.dart  catalogue_toolbar.dart  opening_state.dart  catalogue_wall.dart  top_button.dart  catalogue_keys.dart
mobile/lib/skins/cinematic/screens/discover/dialogue/
  dialogue_screen.dart  subtitled_still.dart  transcript_block.dart  dialogue_keys.dart
  scan/dialogue_scan_block.dart  scan/scan_dialogue_button.dart
mobile/lib/skins/cinematic/screens/reader/bubble_pulse.dart        (+ the take() call in the mobile/12 reader chrome)
mobile/lib/skins/cinematic/router.dart                             (wire the four screens, remove them from PENDING)
mobile/test/features/sources/{discover_scope,source_health,genre_index,trending,source_wash,browse_freshness}_test.dart
mobile/test/features/ocr/{still_crop,engine_label,dialogue_jump}_test.dart
mobile/test/features/library/{recent_searches_clear,genre_weights_provider}_test.dart
mobile/test/core/utils/text_fold_test.dart
mobile/test/core/network/discover_priorities_test.dart
mobile/test/skins/cinematic/discover/{discover_screen,sources_screen,catalogue_screen,dialogue_screen,bubble_pulse,scan_widgets}_test.dart
mobile/test/screenshots/cinematic/mobile_16_discover_shots_test.dart
docs/redesign/proof/mobile-16/                                     (plan.md, screenshots, device-checklist.md, report.md)
```

## Commit plan (small commits, push after each)

1. `feat(mobile/16): shared discover helpers and source models` (A1–A9 with tests).
2. `feat(mobile/16): ocr page boxes, still crop and the dialogue jump` (A10–A14 and the priority test).
3. `feat(mobile/16): cinematic discover index field, scopes and idle page`.
4. `feat(mobile/16): cinematic discover results, group jump and ask scope`.
5. `feat(mobile/16): cinematic sources directory with health and pins`.
6. `feat(mobile/16): cinematic source catalogue`.
7. `feat(mobile/16): cinematic dialogue search, the reader jump and the scan widgets`.
8. `test(mobile/16): smoke tests and harness proof screenshots`.

Each commit: `git add` the exact paths, `git commit -m "<message>"` with **no** `Co-Authored-By`, no "Generated with" line and no other AI attribution, then `git push origin feat/vps-slim-source-native`. Never commit secrets, `.env*` files or `.claude/`.

Before every push: `git fetch origin` and `git diff --stat origin/feat/vps-slim-source-native...HEAD -- frontend`. The checkout is shared, so a push also carries other sessions' commits: if that diff lists files, run `free -m && npm run build` in `frontend/` first (never while a Flutter command runs, stop if `available` < 1024 MB) and push only if it passes, because a failed `next build` silently freezes the production deploy. Never deploy from this step.

## Acceptance criteria

- [ ] `discover`, `sources`, `source` and `dialogue` are gone from the Cinematic `PENDING` set; `test/skins/completeness_test.dart` and `test/skins/import_boundary_test.dart` pass.
- [ ] Every item in sections A–H exists and behaves as written; every listed state renders (widget tests with overridden providers, and harness screenshots).
- [ ] The index field types its hint at 50 ms per grapheme in Bodoni Moda Italic, switches to Roman while typing, draws the 2 px `spot` underline on focus, submits on the keyboard's search key, and exposes the semantics label "Search every source" (or the ASK and dialogue labels); the third Discover tap and `/` focus it.
- [ ] Scopes: `DIALOGUE` is absent in novels mode and when OCR is unavailable; `ASK` is absent when AI is unavailable; `?scope=text` and unknown values render `ALL`; hardware keys `1`–`5` switch the visible scopes.
- [ ] Results show the tiered status line, `IN YOUR LIBRARY` first and `IN DIALOGUE` last, per-source `Retry` retrying only that source, the collapsed empty-groups toggle and the `ALL · WITH RESULTS · PINNED` filter; `Jump to source` scrolls in 400 ms (a jump under reduced motion); `[` / `]` work on a hardware keyboard.
- [ ] Genre tiles come from the union of the pinned sources' genres ordered by the profile's weights, capped at 12 with `All {n} genres`, a single-source genre opens its catalogue directly, and `/search?genre=Romance` opens that genre's sheet.
- [ ] Sources: pinned rows reorder by drag, by the four Move items and by `Alt+↑/↓`, each announced; `PUT /sources/pins` carries the full order including unavailable pins; long-press opens the row menu with Health details; tablets show the table without `LANGUAGE`.
- [ ] Catalogue: browse modes as tabs, the genre sheet, the search field, the wall at 3 / 5 per row, infinite scroll with `LOADING MORE`, load-more retry and `END OF CATALOGUE`; after 3 s the opening state changes the deck, types the tips and fades in the source-hued wash; `browsable: false` shows the not-browsable notice; `source_not_found` shows the §8.0.10 notice; haptic `select` fires once on the first page.
- [ ] Dialogue: each hit renders a 16:9 still cropped around its box with the subtitle band, the transcript with highlighted terms and the credit line; downloaded chapters crop from disk with no request; opening a hit lands on the matched page and pulses the 2 px `spot` frame twice, or shows the chapter-start toast; novels mode shows its notice; the scanning entry links to Downloads.
- [ ] The scan widgets render every OCR run phase from `ocrRunControllerProvider` and the `mm/ocr` channel code is unchanged (`git diff --stat` shows no change under `android/`, `ios/`, `lib/features/ocr/services/` or `lib/features/ocr/controllers/`).
- [ ] Every request added here passes through the limiter with the priority in section A; the unit test proves dialogue page images and genre cover lookups are P3.
- [ ] Reduced motion: with `MediaQuery(data: …copyWith(disableAnimations: true))`, a widget test asserts no letter-reveal controller is running after 250 ms, the typed hint is complete at once, and the group jump uses `jumpTo`.
- [ ] Hardware keyboard: every control is reachable with `Tab` in reading order and shows `CineFocusRing`; the listed keys work (widget tests with `tester.sendKeyEvent`); route focus lands on each screen's level-1 heading.
- [ ] Hit targets: each screen's widget test passes `meetsGuideline(iOSTapTargetGuideline)` under `TargetPlatform.iOS` and `meetsGuideline(androidTapTargetGuideline)` under `TargetPlatform.android`, and `meetsGuideline(labeledTapTargetGuideline)`.
- [ ] Contrast: no `ink.45` text on any ground other than `paper.0` (inside sheets, the mood grade and the source wash it renders `ink.60`); subtitles and genre names over art sit on their §2.1.4 grounds; `meetsGuideline(textContrastGuideline)` passes on each screen.
- [ ] Per-skin difference: only `lib/skins/cinematic/**` and skin-neutral `lib/features/**` / `lib/core/**` files changed; the Glass skin still maps these four ScreenIds to its pending screen; the legacy screens still work (their existing tests pass).
- [ ] `flutter analyze` reports no issues and `flutter test` passes: every test that passed at `00-baseline.md` (2012) and every test added by earlier steps still passes.

## Verification

Run from `/srv/manhwamaniacs/dev/ManhwaManiacs`, one command at a time, `free -m` first each time (stop if `available` < 1024 MB) and `pgrep -f "next build"` empty:

```bash
free -m
node design/build.mjs --check
cd mobile
/srv/manhwamaniacs/dev/flutter/bin/flutter pub get
/srv/manhwamaniacs/dev/flutter/bin/flutter analyze        # baseline: "No issues found!"
free -m
/srv/manhwamaniacs/dev/flutter/bin/flutter test           # baseline: all 2012 passed; now baseline + every added test, 0 failed
```

`frontend/` and `backend/` are not touched in this step, so the web checks (`npm run lint`, `npm run build` in `frontend/`) and the backend pytest (`cd backend && .venv/bin/python -m pytest -q --no-header`) are not run here; confirm with `git show --name-only --format= <hash> -- frontend backend` for each of your own commits (never a branch or range diff: parallel sessions commit on the same branch) that nothing changed there.

**Proof output location.** The `mobile/03` harness (`mobile/test/screenshots/support/skin_shots.dart`) writes a capture only when `MM_PROOF_DIR` is set, so every proof command below sets `MM_PROOF_DIR=../docs/redesign/proof/mobile-16` (relative to `mobile/`) and never `MM_WRITE_SHOTS`, which makes the legacy marketing tests overwrite `mobile/docs/screenshots/`, the install page's public screenshots. Capture routes with `captureSkinScreen` and anything that is not a route (a sheet held open, a state pumped with fixture providers) with `captureSkinWidget`, at the harness sizes: `kSkinShotSizes` (phone 390 × 844, tablet 834 × 1194), `kSkinShotTabletWide` (1024 × 1366, the ≥ 900 px rows of §8.0.9) and `kSkinShotLandscape` (landscape phone 844 × 390). After the run, `git status --short mobile/docs/screenshots` must print nothing.

**Visual proof.** Write `mobile/test/screenshots/cinematic/mobile_16_discover_shots_test.dart` on the `mobile/03` harness (read `mobile/test/screenshots/support/shot_harness.dart` and the proof helper `mobile/03` added: `grep -n "docs/redesign/proof" mobile/test/screenshots/support/*.dart`), with overridden providers and the in-repo fixtures of `shot_fixtures.dart` and `shot_covers.dart` (invented series, painted covers, nothing mature). Capture, at phone 390 × 844 and tablet 834 × 1194 logical px (the harness's sizes if `mobile/03` defined others; say so in the report), each screen and state: Discover idle, searching, partial, results, no results, offline, error, rate limited, ASK thinking and unavailable, the genre sheet, the group jump sheet; Sources default, loading, offline, pinned empty, the row menu, Health details, a row mid-drag; catalogue opening at 0.5 s and at 3.5 s, loaded, not browsable, not available, stale, end of catalogue; Dialogue idle, results with crops, crop loading, crop failed, no matches, novels mode, not available; the bubble pulse in the reader; the scan block in each phase; plus a `-reduced` copy of each screen's default state. Files go to `docs/redesign/proof/mobile-16/{screen}-{state}-{phone|tablet}.png`:

```bash
free -m
cd mobile
MM_PROOF_DIR=../docs/redesign/proof/mobile-16 /srv/manhwamaniacs/dev/flutter/bin/flutter test test/screenshots/cinematic/mobile_16_discover_shots_test.dart
```

**Device checks** (the owner runs them; write them as a checklist in `docs/redesign/proof/mobile-16/device-checklist.md`, iPhone via SideStore after CI builds the IPA, Android flagship from the CI APK): the keyboard opens on the third Discover tap; the search key submits; Rack focus on a first-load results page never racks more than 12 images and holds 120 Hz; the source wash; drag reorder of pinned sources with the drop haptic; long-press Quick look haptic; a dialogue hit on a downloaded chapter crops offline in airplane mode; the bubble pulse lands on the right bubble; a real scan of a downloaded chapter on each OS (Vision on the iPhone, ML Kit on Android) reaches "words are now searchable".

## Report back

Reply with:
1. The checklist above with each box ticked or, if not, why.
2. The list of commits (short SHA and message) and confirmation they are pushed.
3. The screenshot folder `docs/redesign/proof/mobile-16/` with the file count, and the states captured per screen.
4. Test counts: `flutter test` passed / failed / total (and the baseline total 2012), `flutter analyze` result.
5. The lowest `free -m` available value you saw.
6. Open issues: anything in the spec you could not build, backend fields that were missing (for example `page` or `box` on `/ocr/search`, `health` on `GET /sources`), limiter or engine hooks an earlier step did not deliver, and any deviation with the reason.

Next prompt: `docs/redesign/prompts/mobile/17-cinematic-downloads-index-status.md`
