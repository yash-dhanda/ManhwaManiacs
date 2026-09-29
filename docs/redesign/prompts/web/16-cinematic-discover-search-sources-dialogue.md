# web/16 · Cinematic Discover: search, sources, catalogues and dialogue search

Step 49 of the redesign series (track `web`, group 2). Depends on `web/15-cinematic-listen-mode.md` and `backend/02-library-series-ocr-extensions.md`. Its twin `mobile/16-cinematic-discover-search-sources-dialogue.md` builds the same cluster in Flutter and may run at the same time in another session; you never touch `mobile/`.

## Goal

Build the whole Discover branch of the Cinematic skin on the web: the search screen at `/search` with its five scopes (`ALL · LIBRARY · SOURCES · DIALOGUE · ASK`), the index field set in Bodoni Moda Italic, the idle page (recent searches, the Ask-the-editors block, genre tiles, pinned sources, the dialogue entry, trending titles), the tiered results set group by group with a group jump; the Sources directory at `/sources` as a festival-listing table with health marks, pins with reorder and 18+ marks; the source catalogue at `/sources/:sourceId` with browse modes, genres, the opening state and the `source_not_browsable` notice; and dialogue search at `/ocr` ("What they said") as subtitled stills cropped from the page around the matched speech bubble, with the jump into the reader that pulses the bubble. Every request goes through the sources request limiter with the right priority. Every state, key, reduced-motion variant and phone layout is delivered for desktop web and mobile web. Picks (`/library/recommendations`) is **not** part of this step; it is `web/19`.

## Read first

Read these before planning. Do not skim the DESIGN sections: they hold the exact values.

1. `docs/redesign/cinematic/DESIGN.md`
   - §1 Manifesto; §2.1.1 (the `ink.45` raised-stock rule), §2.1.3 (health colours), §2.1.4 (scrims and the over-art rule), §2.1.5 (ambient and duotone), §2.1.6 (mood grades), §2.2 (grid), §2.3 (radius 0), §2.7 (icons, including `bubble-search` and `certificate-18`), §2.8 (token names).
   - §3.2 and §3.5 (type roles), §4.2–§4.8 (durations, curves, the motion table, stagger, interruptibility, reduced motion).
   - §5 (haptics: the web only vibrates for five events) and §6 (sounds).
   - §7 intro, §7.1, §7.2, §7.4 (search fields, the `index` variant), §7.5 (slug lines, counts, segmented control), §7.6 (World card, used by the ASK scope), §7.7 (posters), §7.8 (rails, preview slate, rail keyboard), §7.9 (sheets and desktop column panels), §7.11 (toasts), §7.12 (contents tabs), §7.13 (running head and breadcrumb), §7.16 (lists, drag to reorder), §7.17 (galley proofs), §7.18 (progress, leader dial), §7.19 (badges), §7.22 (menus, Quick look, Move items), §7.23 (notices), §7.24 (the 18+ mark and absence rule), §7.26 (keycaps), §7.27 (masthead block), §7.29 (pull to reprint, `folioLabel()`).
   - §8.0.2–§8.0.10 (navigation, route contract, transitions, platform rules, global keys, content mode, tablet layouts, the "no longer available" notice).
   - **§8.20 Discover, §8.21 Sources, §8.22 Source catalogue, §8.24 Dialogue search** (the specs you are building; read every line).
   - §8.14.2 (Dip into the reader), §9.1.3 and §9.1.8 (only for the ASK scope and the Ask-the-editors block), §10.1 and §10.2 (the two signature animations and where they play), §11 (gesture matrix rows for long-press, pull to reprint, drag handle), §13 moment 16, §14 (accessibility), §15.2, §15.6 (performance guards and the request limiter), §15.7.
2. `docs/redesign/glass/DESIGN.md` §8.9 Search, §8.10 Sources, §8.11 Source catalogue, §8.23 Dialogue search and §15.6. Read them only so the shared data-layer code you add stays skin-neutral: Glass (`web/38`) will call the same hooks with its own screens and adds a `text` search scope.
3. `docs/redesign/inventory/00-decisions.md` (binding owner decisions).
4. `docs/redesign/stack-decision.md` §2.2 (folder layout and the lint boundary), §2.6 (single-sourced logic), §4 risk 11 (memory).
5. `docs/redesign/inventory/web.md` §7.10 (SE1–SE11), §8.1 (SL1–SL13), §8.2 (SB1–SB15), §14 (OC1–OC8), §2.8–§2.9 (command palette and keyboard layer), §18.5 and §18.9 (the calls each action makes).
6. `docs/redesign/inventory/capabilities.md` §16 (sources, health, pins, browse), §18 (federated search), §20 (OCR).
7. `docs/redesign/00-baseline.md` (the health baseline every check is compared with).
8. `docs/redesign/prompts-plan.json`, the entry for this file, and the entries for `web/03`, `web/04`, `web/05`, `web/06` and `backend/02`, so you know which primitives, hooks and endpoints already exist.

## Skills to invoke, in this order

1. `superpowers:writing-plans`: write the implementation plan for this step to `docs/redesign/proof/web-16/plan.md` before touching code. The plan lists every item of the Scope section below as a task.
2. `superpowers:subagent-driven-development` to run the plan (one subagent per task group A–F below, run one after the other, never two builds at once). Use `superpowers:executing-plans` instead if subagents are unavailable.
3. `frontend-design:frontend-design`, `impeccable:impeccable` and `taste-skill:taste-skill` while building each screen: they check hierarchy, spacing and craft against this contract. When one of them suggests something that contradicts `cinematic/DESIGN.md`, the contract wins.
4. `superpowers:verification-before-completion` before you claim anything is done.

## Before you start

- `git status` must show branch `feat/vps-slim-source-native`. Other sessions (mobile, backend, shared) commit in the same checkout: never stage their paths, never run `git add -A`, `git stash`, `git reset` or `git checkout` on files you did not change.
- Confirm the dependencies landed. Stop and report if any of these is missing:
  - `frontend/src/skins/cinematic/index.ts` has a `PENDING` set containing `discover`, `sources`, `source` and `dialogue`.
  - The primitives of `web/04` and `web/05` exist under `frontend/src/skins/cinematic/primitives/` (index search field, slug lines, posters, rails, sheets and column panels, notices, toasts, lists with reorder, menus and Quick look).
  - The sources request limiter from `web/03` exists: `frontend/src/features/sources/request-limiter.ts` exporting `sourcesLimiter` with `run(priority, task, signal)` and `acquire(priority, signal)`, priorities `"P0" | "P1" | "P2" | "P3"`; and `fnv1a32` in `frontend/src/features/sources/cover-transition-name.ts`.
  - `backend/02` added `page` and `box` to `/ocr/search` items: `grep -n "box" backend/routes/ocr.py backend/services/*ocr*`.
- Read the current legacy screens you replace, only to learn which hooks and calls they use: `frontend/src/features/library/components/SearchView.tsx`, `GlobalSearchGroupSection.tsx`, `frontend/src/features/sources/components/SourcesListView.tsx`, `SourceBrowserView.tsx`, `frontend/src/features/ocr/components/OcrSearchView.tsx`. Never import from them and never copy their look.

## Ground rules for this step

- **Track rule.** Work in `frontend/` only. Stage only your own paths explicitly (`git add <path> …`). `node design/build.mjs` may be run to regenerate outputs, but do not edit anything under `design/`, `brand/`, `mobile/` or `backend/`.
- **Skin boundary.** Screens live in `frontend/src/skins/cinematic/screens/…` and may import only `@/features/**` (not `@/features/*/components/**`), `@/lib/**`, `@/services/**`, `@/stores/**`, `@/types/**`, `@/config/**`, the generated contract and their own skin folder. The eslint `no-restricted-imports` rule from `web/00` enforces this; never disable it.
- **Shared logic goes in `features/`.** Anything Glass will also need (genre union, trending list, crop maths, jump hand-off, scope parsing) is a skin-neutral module in `frontend/src/features/<area>/` with a Vitest test next to it.
- **Paths.** Build every link with the typed route builders in `frontend/src/skins/contract.generated.ts` (`ROUTES`), never by string concatenation (series keys can hold `/`, `%` and spaces). In this file `ROUTES.feature(…)`, `ROUTES.featureByFollow(…)`, `ROUTES.source(…)`, `ROUTES.sources()`, `ROUTES.dialogue()` and `ROUTES.picks()` mean the builder for that ScreenId; use the exact names the generator emits.
- **Tokens only.** Every colour, size, duration, easing and z-index comes from the generated tokens (`design/lint-utilities.mjs` checks utilities in `src/skins/cinematic/**`). No arbitrary colour values.
- **Never** edit `backend/connectors/`, never touch production containers or `/srv/manhwamaniacs/{app,data}`.
- **RAM guard.** Production and five bots share this box. Run `free -m` before every `npm run build`, `npm run test` and Playwright run; if the `available` column is under 1024 MB, stop and report instead of running it. Never run two builds (or a build and `next dev`) at once.

## Scope: every item this step delivers

Remove `discover`, `sources`, `source` and `dialogue` from the Cinematic `PENDING` set when their screens are done. Each screen also registers its keys in the keyboard registry (`frontend/src/lib/keyboard/`) under the group named by its masthead title (`Discover`, `Sources`, `Catalogue`, `Dialogue`), sets `document.title` to `{Page} · ManhwaManiacs`, and receives route focus on its `h1` (§14.4).

### A. Shared data-layer additions (skin-neutral, each with a Vitest test)

1. `frontend/src/features/sources/search-scope.ts`: `parseDiscoverScope(value, { aiAvailable, dialogueAvailable })` returning one of `all | library | sources | dialogue | ask`. Rules: unknown values and Glass's `text` map to `all`; `ask` maps to `all` when AI is unavailable; `dialogue` maps to `all` when not available (novels mode, or `GET /settings` capabilities `ocr` false). Test every branch.
2. `frontend/src/features/sources/genre-index.ts`: `buildGenreIndex(pinnedSources, genresBySource, weights)` returning `[{ genre, label, sourceIds[] }]`: the union of the pinned sources' genre lists, merged case-insensitively (the label keeps the first spelling seen), ordered by the profile's weight (highest first), ties and genres without a weight alphabetical. Weights come from `useGenreWeights()` (item A3). Test merge, ordering and the empty case.
3. `frontend/src/features/library/genre-weights.ts`: the one genre-weights client of the web app, over `GET /library/recommendations?limit=` (`[{genre, weight}]`, the profile's gated genre affinity; the source `cinematic/DESIGN.md` names for Tonight's `Your genres`, the Picks aside §9.1.3 and The Numbers' radar §9.2.1). `genreWeightsApi.get(limit)` through `services/http.ts` and `useGenreWeights(limit = 40)` (React Query key `["library", "genre-weights", profileId, matureEnabled, limit]`, `staleTime: 600_000`) returning the list sorted by weight, highest first (ties alphabetical), or `[]` on an empty answer or an error. `web/19` (the Picks aside) and `web/21` (the radar, `limit` 8) import this hook; neither adds another. Test the request builder, the sorting and the error fallback. Do not derive weights from `useHomeFeed()`: arriving at `/search` directly would otherwise fetch the whole `/home` composition.
4. `frontend/src/features/sources/trending.ts`: `buildTrending(pagesBySource)` taking each pinned source's first page of its `popular` browse mode and returning at most 10 `{ title, sourceId, seriesKey }`: the first two titles per source in pin order, de-duplicated by case-folded title. A source with no `popular` mode contributes nothing. Test the cap, the de-duplication and the per-source limit.
5. `frontend/src/features/sources/health.ts`: `describeHealth(health, now)` returning `{ state: "ok" | "failing" | "dead" | "unknown" | "demoted", label }` with the labels `OK · last checked 4 min ago`, `FAILING · 3 errors`, `DEAD since 12 Sep`, `DEMOTED` (demoted wins over the status; `unknown` when `health` is null or never checked), plus `sortWorstFirst(rows)` (dead, failing, demoted, unknown, ok; then by name). Uses the `SourceHealth` type in `features/sources/types.ts`. Test each label and the sort.
6. `frontend/src/features/sources/source-wash.ts`: `sourceWashHue(sourceId)` = `fnv1a32(sourceId) % 360`, importing `fnv1a32` from `features/sources/cover-transition-name.ts` (`web/03`); do not write a second hash. Test two fixed ids against precomputed hues.
7. `frontend/src/features/ocr/still-crop.ts`: `stillCrop(box, pageAspect)` returning the CSS values for a 16:9 still: `objectPosition` and `scale` so that the box fills 60 % of the still's width, centred on the box, clamped so the crop never leaves the page; with `box === null` it returns the top 16:9 of the page (`objectPosition: "50% 0%"`, scale 1). Boxes are page fractions `{x, y, w, h}` (from `backend/02`). Test a centred box, boxes at each edge and the null case.
8. `frontend/src/features/ocr/types.ts`: add `page: number | null` and `box: { x: number; y: number; w: number; h: number } | null` to `OcrSearchResultItem`.
9. `frontend/src/features/ocr/engine-label.ts`: `engineLabel(engine)` → `VISION` for Apple Vision engine names (`vision`, `apple_vision`, `apple-vision`, case-insensitive), `ML KIT` for `mlkit`, `ml_kit`, `ml-kit`, otherwise the engine string upper-cased. Test.
10. `frontend/src/features/ocr/dialogue-jump.ts`: the reader hand-off. `writeDialogueJump({ sourceId, seriesKey, chapterKey, q, page, box })` stores one entry in `sessionStorage['mm.dialogue.jump']` just before navigating; `takeDialogueJump(sourceId, seriesKey, chapterKey)` returns it once (and deletes it) when the reader for that chapter mounts, or `null`. `findMatchPage(pageTexts, q)` returns the first page whose text contains every term of `q` (case-insensitive, diacritics folded with `normalize("NFD")` and the combining marks removed), or `null`. The route contract (`?page&at&all`) is not changed. Test the one-shot read and the matcher.
11. `frontend/src/features/library/recent-searches.ts`: add `clearRecentSearches()` if it does not exist (it writes an empty list through the same scoped key `manhwamaniacs:recent-searches`), with a test.
12. `frontend/src/features/sources/hooks.ts`: add `useSourceHealthSummary()` for `GET /system/source-health` (through `services/system.ts`; `{total, ok, failing, dead, unknown, demoted}`, already gated per profile by the server) if no hook exists yet.

Request priorities (§15.6) for every call this step adds or renders, through `sourcesLimiter.run(priority, task, signal)` (every function in `features/sources/api.ts` already runs as P1; wrap only what this step adds, and assign `<img src>` for P2 and P3 images only after `sourcesLimiter.acquire(priority)` resolves): **P1** federated search tiers, library search, per-source retry, source lists, pins, browse pages, catalogue search, OCR search, the chapter manifest a dialogue still needs; **P2** covers in view (posters, genre tile covers, source logos loaded from the proxy); **P3** hover or focus prefetch (preview slates), genre lists of pinned sources (cached 24 h per source, `staleTime: 86_400_000`), the popular pages behind Trending, the genre tile cover lookups, and dialogue still page images at 480 px wide. P3 runs only while at least 20 tokens remain, at most 2 in flight. On a `429` the limiter pauses P2 and P3 for `Retry-After`.

### B. Discover screen (`/search`, ScreenId `discover`), §8.20, web SE1–SE11

Hierarchy: the index field, then the scopes, then results grouped by source (or the idle page). URL state: `?q=` and `?scope=` (`all | library | sources | dialogue | ask`), written with `router.replace` (no history entry per keystroke), parsed with `parseDiscoverScope`. The hash `#genre={name}` opens that genre's sheet on mount (Picks' "Your genres" links here in `web/19`).

**Desktop (≥ 768 px, 12 columns; 8 columns at 768–1023):**
1. Mood grade behind the top 30 vh (§2.1.6: the profile mood's grade colour to `#000000`; none for `default`), with the raised-stock scope on it.
2. Masthead block without a title: kicker `No. 04 — DISCOVER` (`type.kicker`, letter reveal on mount), a visually hidden `<h1 className="sr-only" tabIndex={-1}>Discover</h1>` as the route focus target, then the **index field** (§7.4 `index` variant) spanning 8 columns: `type.field` (Bodoni Moda Italic, opsz 48, wght 500; 28/36 phone · 32/40 tablet · 36/44 desktop · 40/48 wide, tracking −0.015em); the placeholder "Search every source" typed at 50 ms per character in `ink.45` while empty and unfocused (an `aria-hidden` visual layer; the real `placeholder` holds the full string and shows statically while focused and empty); typed text switches to Bodoni Moda Roman; a `spot` caret 3 px wide; a 1 px `rule.2` underline that becomes 2 px `spot` drawn from the left in 240 ms `ease.settle` on focus; a trailing `quiet` "Clear" once there is text. Accessible name "Search every source". `enterkeyhint="search"`, `type="search"`.
3. Scope tabs under the field as contents tabs (§7.12): `01 ALL · 02 LIBRARY · 03 SOURCES · 04 DIALOGUE · 05 ASK`. `DIALOGUE` renders only in manga mode with OCR available; `ASK` only when `useSuggestAvailability()` says `available`. Folios renumber over the visible tabs. Scope changes are a **Cut** (0 ms) and never move focus.
4. **Idle page** (no query), in 12 columns, sections separated by the §2.2.2 rhythm (1 px `rule.1` → 12 px → header → 12 px → content → 64 px):
   - `RECENT`: a slug line of the last 4 searches of this profile (min 2 characters, from `recent-searches.ts`), each a button that fills the field and searches, plus a `quiet` `Clear` (calls `clearRecentSearches()`). Hidden when empty.
   - `ASK THE EDITORS` (only when AI is available): a Feature-sized block (§7.6 Feature proportions, no image): kicker `ASK THE EDITORS`, the example "A murim regressor who comes back stronger" typed at 50 ms per character in `type.pull` (Bodoni Moda Italic), a deck in `type.deck` `ink.60` "Describe it in your own words; the editors pick from everywhere.", and `Ask` (secondary with `sparkle` 20 Regular) linking to `ROUTES.picks()` + `#ask` (Picks focuses its ask field on that hash, `web/19`).
   - `01 Browse by genre` (H3 section head with the letter reveal, trigger `inView`): genre tiles from `buildGenreIndex`, capped at 12 tiles, then a `quiet` toggle `All {n} genres` revealing the rest. Tile: 16:9, radius 0, the cover of the first series of that genre on the first pinned source that has it (a P3 `GET /sources/{id}/series?genre=&page=1` lookup, first item), duotoned to that series' own `ambient.duo` (fallback `#B8B2A4`), the genre name in Bodoni Moda Italic at the `type.subhead` size (20/24 phone · 22/28 tablet · 24/28 desktop) in `ink.100` on the solid end of `scrim.foot` (the component sets `--scrim-solid-at` from its measured text block). Hover: image zoom 1.04 inside the frame and the genre name underlines, 200 ms `dur.clip` `ease.settle`; pressed: a 1 px impression (80 ms `ease.set` down, 160 ms `ease.settle` up). While the cover loads the tile is a `paper.1` plate with the genre name set on it. Grid: 4 per row desktop, 3 per row tablet (600–1023), 2 per row phone. A tile opens a **genre sheet** (a column panel on desktop, 4 columns, min 400 px; a sheet on phones): kicker `GENRE`, title the genre, one row per pinned source exposing it (logo 24, name `type.title`, health mark) linking to `ROUTES.source(id)` with `?genre=`; when only one pinned source has the genre, the tile opens that catalogue directly (Cut). No pinned sources: the section is not rendered.
   - `02 Sources`: pinned sources as a credits list (logo 24, name, the 6 × 6 health mark with its label, the 16 px `18` certificate when the source is mature and visible), then `All {n} sources →` (`quiet` with `arrow-right` 16) to `ROUTES.sources()`.
   - `03 Search what they said` (manga mode with OCR only): an entry block with the `bubble-search` glyph at 32 px Light `ink.45`, kicker `DIALOGUE`, the line "Find the chapter by a line someone said." and a link to `ROUTES.dialogue()`.
   - `04 Trending on your sources`: a slug line of up to 10 titles from `buildTrending`, each linking to its feature page. Absent when no pinned source has a `popular` mode.
   - The idle sections renumber with no gaps when one is absent.
5. **Results** (after the 300 ms debounce, or at once on `Enter`):
   - Status line (`type.caption`, Archivo wdth 90 wght 450, 13/16), a polite live region: "Searching your library and 12 pinned sources…" → "48 results · 12 sources" → "48 results so far · searching 77 more sources…" with the indeterminate rule (a 25 %-wide `spot` segment, 1200 ms `dur.loop.rule` linear loop) while tier 2 runs; failures add "3 sources didn't answer." under the `NOTE` kicker in `spot`.
   - Filter slugs above the groups: `ALL · WITH RESULTS · PINNED` (single-select, underline slides 320 ms `ease.settle`).
   - Group jump bar (desktop, sticky under the running head at `z.sticky`): the source names with raised counts as a slug line; clicking scrolls to the group in 400 ms `dur.glide` `ease.settle` and focuses its header. `[` / `]` move to the previous / next group.
   - Group order: `IN YOUR LIBRARY` (from `useSearch`, the Library mark = the `mm-mark` glyph 24 px), then source groups in tier order (from `useFederatedSearch` with its existing tier resolution), then `IN DIALOGUE` (only in manga mode with OCR: the top 3 OCR hits as compact transcript rows, and `See all` to `ROUTES.dialogue()` with `?q=`).
   - Each group: a subhead row (24 px source logo or the Library mark, source name in `type.title`, count badge (fill `spot`, `#000` Plex Mono 10), health mark) and a rail (§7.8) of posters in caption mode **Below**: title on 2 lines (`type.title`), folio caption `CHAPTERS 120` in `ink.45`. Library hits link to `ROUTES.featureByFollow(id)`, source hits to `ROUTES.feature(sourceId, seriesKey)` with the match cut (`coverTransitionName`).
   - Failed group: header stays; a `CORRECTION` caption "This source didn't answer." in `proof` and a `quiet` `Retry` that retries only that source (`useRetrySearchSource`), showing two flicker plates while it runs.
   - Empty groups collapse into one `quiet` toggle `Show 31 sources with no matches` (and `Hide …` when open).
   - Results **Set** group by group as tiers arrive (first data paint only; a later tier's groups use one 160 ms fade for the appended block, §4.6).
6. **ASK scope**: the field's placeholder and accessible name become "Describe what you feel like reading"; `Enter` submits `POST /library/world/suggest {prompt}` (3–600 characters, `canSubmitPrompt` from `features/library/suggestions.ts`). Thinking state: the typed line "Reading your shelf…", a 24 px leader dial after 1 s, then World cards (§7.6) fading in 160 ms each, 30 ms apart, in a grid (3 per row desktop, 2 per row phone). A `quiet` button `Search sources for "{q}" instead` switches to `ALL` with the same text. Unavailable, budget, rate-limited and failure states use the §9.1.8 copy (see item G) and never `proof`.

**Phone (< 768 px, 4 columns; 8 columns from 600 px):** the index field at 28 px in the masthead area; the running head shows `DISCOVER` once the masthead scrolls under it; scopes as a horizontally scrolling contents row; idle sections stacked; genre tiles 2 per row (3 at 600–767); result rails at 3.2 visible posters (2.3 at text scale ≥ 1.3; 5.2 at 600–767); failed and empty groups as desktop; the group jump bar becomes a `Jump to source` `quiet` button that opens a sheet listing the groups with counts.

**Transitions.** In: the shell's section change (Cut + Set + Folio flip on phones, Dip 160/40/240 on desktop); `?q=` prefilled when arriving from Picks' `Search my sources`. Out: match cut to feature pages, Page to Sources.

**Keys (web).** `/` focuses the field; `Esc` clears, then blurs; `Enter` searches now; `↓` moves into the first result rail; `1`–`5` switch to the visible scope at that position; `[` / `]` previous and next result group. The shell's `/` key and the phone thumb index's third Discover tap dispatch the `mm:focus-search` window event (`web/06`); the Discover, Sources, catalogue and Dialogue screens each listen for it and focus their own search field.

**States (each one built and screenshot-tested):** idle; searching (tier 1: three groups of four flicker plates, after the 120 ms skeleton delay); partial (tier 2 running); results; no results (notice `NOTHING FOUND`, headline typed "No series match "{q}" in your library or sources.", plus `Ask the editors` when AI is available); offline (notice `OFFLINE EDITION`, "Search needs a connection to reach your library and sources.", plus the global offline line "Saved chapters still open." and `Go to Downloads`); error (`CORRECTION` notice with `Try again`); rate limited (`SLOW DOWN` notice with the live "Retrying in 12 s" folio from `Retry-After`).

**Signature moment.** Typing in the index field in Bodoni Italic that turns Roman as it becomes a query; results then Set group by group as tiers arrive.

### C. Sources screen (`/sources`, ScreenId `sources`), §8.21, web SL1–SL13

1. Masthead: kicker `No. 04 — DISCOVER / SOURCES`, title "Sources" (`type.masthead`, letter reveal on mount), deck "89 sources · 84 healthy · 6 pinned" from `useSourceHealthSummary()` and the pins (counts computed after the 18+ gate, so a gated profile sees about 33 with no gaps), `rule.oxford` on desktop / `rule.heavy` on phones drawn after the letters land.
2. Toolbar: a `compact` search field (§7.4) "Filter sources" matching name or id; the slug line `ALL · PINNED⁶ · 18+` (the `18+` slug only when the profile's gate is open; raised counts drawn per §7.5); the content-mode control. The list follows the reading mode (manga or novel sources, `useContentModeFilter`).
3. **Pinned** section: a table of pinned sources in pin order, each row draggable by a `dots-six-vertical` handle (20 Regular) with Motion `Reorder` (the `web/05` list primitive); the lifted row rises 1 px with a 1 px `ink.100` outline; siblings shift 240 ms `ease.set`; every drop and every Move item writes the full ordered list with `PUT /sources/pins` (`useReplaceSourcePins`, max 50). Row menus carry `Move up`, `Move down`, `Move to top`, `Move to bottom` (disabled at the ends), each announced in a polite live region ("Asura moved to position 3 of 6"). Pins whose `available` is `false` are not rendered, and they are kept in the array written back by `PUT`, so they return when the source does.
4. **All sources** section: a directory table (desktop columns): logo 32 (favicon, or a Bodoni Moda initial on `paper.1`), name (`type.title`) with the description under it (`type.caption`, 1 line, truncated with an ellipsis and the full text in `title`), `LANGUAGE` (the `language` field upper-cased, `—` when null; the column is dropped at 768–1023), `KIND` (`MANGA` / `NOVEL`), health (the 6 × 6 square mark plus `describeHealth` text on one aligned column rule, "DEMOTED" with a 1 px strike-through), the 16 px `18` certificate for mature sources, and the pin toggle (`bare` icon button, `push-pin` 24 Light; pinned = Fill with a 2 px `spot` rule 4 px under the square; `aria-pressed`, label "Pin {name}"). Health colours: ok `set` `#57D68D`, failing `spot` `#F4D03F`, dead `proof` `#FF5B4A`, unknown `ink.45` `#7A7770`, demoted `ink.60` `#9A978F`. Desktop: hovering the health mark shows the last error (`health.last_error`) in a tooltip (500 ms delay, 0 ms on focus).
5. Row click → the catalogue (Page transition). Pin feedback: toast "{name} pinned" / "{name} unpinned"; failure toast "Couldn't update your pinned sources." (error, 6000 ms hold, `proof` edge). Pins that fail to load: a `NOTE` banner strip "Pinned sources couldn't be loaded, so pinning is off until they are." with `Try again`, and every pin toggle disabled with that reason as its tooltip.
6. **Phone:** rows 64 px (logo 32, name + description, health mark and `18` at the right, pin button with a 44 px hit); the pinned section first with drag handles; the toolbar as a scrolling slug line plus the filter field; long-press a row (450 ms; `-webkit-touch-callout: none` and `preventDefault()` on `contextmenu` for these rows) opens the row menu `Pin` / `Unpin` / `Open` / `Health details` (a sheet with the last error in Plex Mono on `paper.1` and the last OK time), plus the four Move items on pinned rows; pull to reprint refetches `GET /sources` and `GET /sources/pins`.
7. Keys (web): `/` filter; `j` / `k` next / previous row; `Enter` open; `p` pin toggle on the focused row; `Alt+↑` / `Alt+↓` move the focused pinned row.
8. States: loading (10 greeked rows at their exact heights, flicker); error (`CORRECTION` notice + `Try again`); offline (notice `OFFLINE EDITION` "The source list needs a connection." with the pinned rows below it from the last cached list, read-only); none installed ("No sources installed on this server."); no match ("No sources match "{q}"."); pinned empty ("No pinned sources. Tap the pin on any source to keep it at the top.").
9. Transitions: in by Page from Discover, Cut from the sidebar; out by Page to the catalogue. Signature: the health column reads like a festival listing, every mark and status on one column rule, dead sources struck through.

### D. Source catalogue (`/sources/:sourceId`, ScreenId `source`), §8.22, web SB1–SB15

URL state `?mode=`, `?genre=`, `?q=` (all `router.replace`).

1. Masthead: the source logo (48) beside its name in `type.masthead` with the letter reveal; deck "Catalogue · 1,240 series" (+ ` · "{q}"` when searching); a freshness credit `UPDATED 12 MIN AGO` (from `browse-freshness.ts`) or the `SAVED COPY · 3 H` badge (1 px `spot` outline, `NOTE` semantics, tooltip "The source is down; this is the last copy we saved."), re-rendered every 30 s; `Refresh` (`quiet` with `arrow-clockwise` 16; while refreshing the glyph becomes a 16 px leader dial; calls the existing `useRefreshSourceBrowse` with `refresh=true`).
2. Toolbar: browse modes as contents tabs with the server's labels (any string, horizontally scrollable, hidden while searching); a `Genre` select (single-select menu on desktop, sheet on phones; first item "All genres"; only when the source exposes genres); a `compact` search field "Search this source" (300 ms debounce, `/`).
3. **Grid**: a poster wall in caption mode Below, the title on 2 lines, no folio line: 6 per row desktop, 8 wide (≥ 1440), 5 tablet, 3 phone. Novel sources render the book list of §8.9.1 (the `web/09` component). Desktop hover slates are **off** here. The wall is keyboard navigable (`h j k l`, arrows, `Home` / `End`, `Enter`).
4. Infinite scroll with a sentinel 600 px before the end (`useInfiniteSourceSeries`); `LOADING MORE` caption with a 16 px leader dial; load-more failure "Couldn't load more." + `Retry` (refetches only that page); the end: a 1 px `rule.1` and the `END OF CATALOGUE` kicker centred.
5. **Opening state** (first load): the source name sets itself with the letter reveal; a 32 px leader dial beside the deck (after the 400 ms delay); flicker plates for the grid; after 3 s the deck changes to "This source can take about 10 s." and a line of tips types itself (50 ms per character) rotating every 3.5 s through "Press / to search this source.", "Pick a browse mode to change the order.", "Tap a genre on any series to browse it here.", "Your progress syncs across devices."; also after 3 s a background wash fades in over 800 ms `dur.dissolve` `ease.turn`: `hsl(sourceWashHue(id) 35% 6%)` behind the masthead band (top 30 vh, fading to `#000000`, raised-stock scope on it). Data arrival dissolves the plates into posters (160 ms).
6. A floating `TOP` square button: 40 px, `paper.2`, 1 px `rule.2`, `arrow-up` 20 Regular, label "Back to top", appears after 400 px of scroll (phones: bottom-right, 16 px above the thumb index; desktop: bottom-right of the content column, 24 px in); scrolls to top in 400 ms `dur.glide` (a jump under reduced motion).
7. **Phone:** the running head holds back, logo 24 and the name; the search field under it; browse-mode tabs; the 3-column wall; pull to reprint refreshes from the source.
8. Keys (web): `/` search; grid keys; `Enter` open; `[` / `]` previous and next browse mode; `r` refresh.
9. States: opening; loaded; empty ("No series found." or `No results for "{q}" on this source.`); full error (`CORRECTION` "Couldn't load the catalogue." + the server message + `Try again`); stale (the badge above); offline (the saved copy if one exists, else the `OFFLINE EDITION` notice); rate limited (a live countdown in the deck from `Retry-After`: "Rate limited · retrying in 12 s"); not available (`source_not_found` or a gated source: the §8.0.10 notice with kicker `NOT IN THIS ISSUE`, headline typed "This source isn't available here any more.", deck "It may have been removed from its source.", `Back to Tonight` and `Search for it`); **not browsable** (`browsable === false` on the source summary, or a `source_not_browsable` error code): notice "This source can only be searched, not browsed." with `Search it`, which focuses this catalogue's own search field (a search here is already scoped to this one source: `?q=` runs `GET /sources/{id}/series?query=`); while the source is not browsable the browse-mode tabs and the genre select are hidden and a search renders its results in the wall as usual. This is how "Discover scoped to that source" is delivered, because the federated search has no single-source filter in the route contract.
10. Transitions: in by Page from Sources, Cut when opened from a genre link; out by match cut to feature pages.

### E. Dialogue search (`/ocr`, ScreenId `dialogue`), §8.24, web OC1–OC8

1. Masthead: kicker `No. 09 — DIALOGUE`, a visually hidden `<h1>` "Dialogue search" (route focus target), the index field with the typed placeholder "Search what a character said" (accessible name the same), deck "Across chapters whose dialogue has been read, in series you follow." `?q=` in the URL.
2. Results as **subtitled stills** (`useOcrSearch`, `limit=20`, then `Show more` with `offset`): each hit is a block 8 of 12 columns wide on desktop, two columns of 4:
   - Left: a 16:9 still, radius 0, at `brightness(0.8)`: the page image cropped with `stillCrop(box, aspect)` (`object-fit: cover`, `object-position`, `transform: scale()`), with the matched line laid over its lower third as a subtitle: Newsreader 18/24 `ink.100`, centred, on a `color.onart` band (`#000000` at 0.64), 8 × 12 px padding, max two lines, the matched terms under the `spot.wash` highlighter (`rgba(244,208,63,0.16)`). With no box, the top 16:9 of the page; with no known page the still is absent and the block is text only.
   - Crops load lazily: an `IntersectionObserver` with a 400 px root margin requests the chapter manifest (the cached source chapter query, P1) to find the page URL, then the page image through the existing proxy at 480 px width (P3). Downloaded chapters crop from the saved copy (the service worker answers the same page URL). No image work runs on the server.
   - Right: the transcript: the full snippet in Newsreader 18/28 with the matched terms under the highlighter in `ink.100` (parse the server's `<mark>` markers with `features/ocr/snippet.ts`; never `dangerouslySetInnerHTML`), then a credit line `TOWER OF GOD · CH 88 · PAGE 12 · 214 WORDS · VISION` (series title joined from the followed library index; `engineLabel()`), and the series cover at 40 × 60.
   - Block states: hover adds a 2 px `ink.100` left bar and zooms the still to 1.04 inside its crop (200 ms `dur.clip` `ease.settle`); pressed fills `paper.3`; focus ring around the block.
3. Click or `Enter` on a block: `writeDialogueJump(…)`, then open the reader for that chapter with the **Dip** (440 ms). In the Cinematic reader screen (`frontend/src/skins/cinematic/screens/reader/`, from `web/12`), call `takeDialogueJump()` on mount: when `page` is known, seek to it with the engine's `jumpToPage`; otherwise fetch the chapter transcript (`useOcrChapter`) and use `findMatchPage`. Then draw `BubblePulse`: a 2 px `spot` frame around the box (page fractions mapped onto the page element), shown twice for 480 ms each (opacity 0 → 1 → 0, `ease.settle`), and the toast "Found on page 12." When no page matches: toast "Opened at the chapter start. The line is in this chapter." Reduced motion: the frame shows once, statically, for 960 ms.
4. Overflow note: "Showing the first 20 of 134 matches. Narrow the search." + `Show more`.
5. Novels mode: the notice "Dialogue search is for manga. Switch to Manga, or search the novels' text." with `Search novels` (to Discover).
6. **Phone:** one column; the field at 28 px; each block is the full-width 16:9 still, then the transcript and credit line; the cover at 32 × 48. Mobile web shows search only (no scanning entry).
7. Signature moment: each still racks into focus (Rack focus: blur 14 → 0 px, brightness 0.6 → 1, scale 1.03 → 1 over 520 ms `dur.rack` `ease.settle`; at most 12 at once per screen, the rest **Develop**) with its subtitle already set, then the highlighter sweeps across the matched words in the subtitle and the transcript (200 ms `dur.clip` per band, left to right, 60 ms apart, `ease.set`).
8. Keys (web): `/` field; `j` / `k` next / previous block; `Enter` open.
9. States: idle ("Type a line you remember."); loading (three greeked blocks: a flickering 16:9 plate plus greeked lines); crop loading (a `paper.1` plate with the subtitle already set over it); crop failed or page not found (the plate stays, subtitle intact, a 16 px `image-broken` glyph in `ink.60` at its bottom-right corner (the raised-stock rule on `paper.1`), labelled "Page didn't load"); no matches (notice: "Nothing found for "{q}". Only chapters whose dialogue was scanned, in series you follow, can be searched."); offline (`OFFLINE EDITION`, "Dialogue search needs a connection."); error (`CORRECTION` + `Try again`). When the server's capabilities say `ocr` is false, the route shows the notice "Dialogue search isn't available on this server." and every Discover entry to it is hidden.

### F. Cross-cutting on all four screens

- **18+:** mature sources, series and badges are simply absent when the gate is closed; no count, placeholder or blurred tile mentions them. With the gate open, the 16 px certificate (§7.19) marks mature sources and posters.
- **Content mode** (§8.0.8): Discover results, Sources and catalogues follow the reading mode; dialogue search is manga-only. On phones the Discover running head carries `web/05`'s `ContentModeChip` (`MANGA ▾`, §7.29) through `useRunningHead` (`web/06`) when novels are enabled; on desktop the sidebar's `MANGA / NOVELS` toggle covers it.
- **Long-press** (mobile web, 450 ms) on posters and result cards opens Quick look (§7.22), mirrored by the trailing `dots-three` and right-click on desktop.
- **Reduced motion** (web `prefers-reduced-motion: reduce` or `html[data-motion="reduced"]`): letter reveals become a 200 ms whole-string fade; typed placeholders, tips and headlines show the full text with no caret; Set and Develop become a 160 ms fade; Rack focus a 160 ms opacity fade; rules present at rest; slug and tab underlines fade 150 ms in place; programmatic scrolls (group jump, TOP, rail focus) jump; the highlighter bands show at their end state; skeletons are static at 0.8 opacity; Dip and Page become 150 ms opacity cross-fades; the source wash appears without the dissolve. Leader dials and the indeterminate rule keep running (essential progress).
- **Haptics and sound:** no screen here vibrates on the web (none of the five web vibrate events fires in this cluster). Sounds, when on: `select` for scope, filter and slug changes (`tick`); none elsewhere.
- **Focus:** keyboard focus shows the double ring (2 px `ink.100` at 2 px offset plus the 6 px `#000000` halo); rails and grids reserve 8 px vertical padding so it is never clipped; the sticky group jump bar sets `scroll-padding-block`.

### G. AI copy for the ASK scope and the Ask-the-editors block

Use the §9.1.8 vocabulary exactly. Find the module `web/08` created for it (`grep -rln "The picks desk is closed tonight" frontend/src`) and reuse it; if none exists, create `frontend/src/skins/cinematic/ai-copy.ts` exporting the table below keyed by reason or error code, and `web/19` will extend it:

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
| Ground, plates, sheets | `paper.0` `#000000`, `paper.1` `#0B0B0A`, `paper.2` `#121211`, `paper.3` `#1A1A18`, `paper.4` `#232220` | §2.1.1 |
| Rules | `rule.1` `#2B2A27`, `rule.2` `#3D3C38` | §2.1.1 |
| Inks | `ink.30` `#4D4B47` (disabled only), `ink.45` `#7A7770` (on `paper.0` only), `ink.60` `#9A978F`, `ink.80` `#C9C6BE`, `ink.100` `#F3F0E8` | §2.1.1 |
| Spot | `spot` `#F4D03F`, `spot.press` `#D9B62C`, `spot.wash` `rgba(244,208,63,0.16)` | §2.1.2 |
| Semantic | `proof` `#FF5B4A`, `proof.wash` `rgba(255,91,74,0.12)`, `set` `#57D68D`, `info` `#9CC8FF`, `color.onart` `rgba(0,0,0,0.64)` | §2.1.3, §2.8.1 |
| Durations | `dur.cut` 0, `dur.tick` 80, `dur.beat` 160, `dur.line` 240, `dur.column` 320, `dur.spread` 480, `dur.dissolve` 800, `dur.type` 50 per grapheme, `dur.snap` 120, `dur.reduced` 150, `dur.clip` 200, `dur.page.out` 224, `dur.rack` 520, `dur.glide` 400, `dur.loop.rule` 1200, `dur.flicker` 1400, `dur.leader` 1000 (ms) | §2.8.4, §4.2 |
| Curves | `ease.settle` `cubic-bezier(0.16,1,0.3,1)`, `ease.lift` `cubic-bezier(0.7,0,0.84,0)`, `ease.turn` `cubic-bezier(0.65,0,0.35,1)`, `ease.set` `cubic-bezier(0.2,0,0,1)` | §4.3 |
| Spring (drag release) | `spring.release` `{ type: "spring", visualDuration: 0.42, bounce: 0 }` | §4.4 |
| Stagger | grids +32 ms per item, +64 ms per row, cap 480; lists +24 ms, cap 360; letters +24 ms, cap 560, start 120 ms after the rule | §4.6 |
| Letter reveal | opacity 0 → 1 and y +0.42em → 0 over 640 ms, blur 8 → 0 px over 440 ms, `ease.settle` | §10.1.1 |
| Typing | one grapheme per 50 ms, caret `spot` 0.12em × 0.86em, blink 530 ms halves | §10.2.1 |
| Rails | visible posters 3.2 phone · 5.2 tablet · 6.25 desktop · 7.25 wide · 8.25 cinema; gap 8 · 12 · 12 · 12 · 16 px; paddles 48 px page by `visible − 1` over 560 ms `ease.turn` | §7.8 |
| Grid | phone 4 cols, margin 16, gutter 12; tablet 8 / 32 / 16; desktop 12 / 48 / 24; wide 12 / 72 / 24 max 1760; cinema 12 / 96 / 32 | §2.2.2 |
| Hit areas | 44 × 44 coarse pointer (mobile web), 32 × 32 fine pointer with 24 px spacing | §14.6 |
| Layers | `z.sticky` 10, `z.chrome` 20, `z.panel` 30, `z.sheet` 40, `z.dialog` 50, `z.toast` 60 | §2.4 |

## File layout

```
frontend/src/features/sources/search-scope.ts            (+ .test.ts)
frontend/src/features/sources/genre-index.ts             (+ .test.ts)
frontend/src/features/sources/trending.ts                (+ .test.ts)
frontend/src/features/sources/health.ts                  (+ .test.ts)
frontend/src/features/sources/source-wash.ts             (+ .test.ts)
frontend/src/features/sources/hooks.ts                   (useSourceHealthSummary, if missing)
frontend/src/features/library/genre-weights.ts           (+ .test.ts)
frontend/src/features/ocr/still-crop.ts                  (+ .test.ts)
frontend/src/features/ocr/engine-label.ts                (+ .test.ts)
frontend/src/features/ocr/dialogue-jump.ts               (+ .test.ts)
frontend/src/features/ocr/types.ts                       (page, box)
frontend/src/features/library/recent-searches.ts         (clearRecentSearches, if missing)
frontend/src/skins/cinematic/ai-copy.ts                  (only if web/08 did not create an equivalent)
frontend/src/skins/cinematic/screens/discover/
  DiscoverScreen.tsx  IndexFieldHeader.tsx  ScopeTabs.tsx  DiscoverIdle.tsx  GenreTiles.tsx
  GenrePanel.tsx  PinnedCredits.tsx  TrendingLine.tsx  DiscoverResults.tsx  ResultGroup.tsx
  GroupJump.tsx  AskScope.tsx  keys.ts
frontend/src/skins/cinematic/screens/sources/
  SourcesScreen.tsx  SourceTable.tsx  SourceRow.tsx  HealthMark.tsx  HealthDetailsSheet.tsx  keys.ts
frontend/src/skins/cinematic/screens/catalogue/
  CatalogueScreen.tsx  CatalogueToolbar.tsx  OpeningState.tsx  CatalogueWall.tsx  TopButton.tsx  keys.ts
frontend/src/skins/cinematic/screens/dialogue/
  DialogueScreen.tsx  SubtitledStill.tsx  TranscriptBlock.tsx  keys.ts
frontend/src/skins/cinematic/screens/reader/BubblePulse.tsx   (+ the takeDialogueJump call in the web/12 reader screen)
frontend/src/skins/cinematic/index.ts                      (wire the four screens, remove them from PENDING)
frontend/e2e/cinematic/web-16-discover.spec.ts             (the checks listed under Verification)
docs/redesign/proof/web-16/                                (plan.md, routes.txt, screenshots, report.md)
```

The route files under `frontend/src/app/(app)/search/`, `sources/`, `sources/[sourceId]/` and `ocr/` stay the thin files `web/00` wrote; do not add logic to them.

## Commit plan (small commits, push after each)

1. `feat(web/16): shared discover data helpers` (group A with tests).
2. `feat(web/16): cinematic discover index field, scopes and idle page`.
3. `feat(web/16): cinematic discover results, group jump and ask scope`.
4. `feat(web/16): cinematic sources directory with health and pins`.
5. `feat(web/16): cinematic source catalogue`.
6. `feat(web/16): cinematic dialogue search and the reader jump`.
7. `test(web/16): discover e2e checks and proof screenshots`.

Each commit: `git add` the exact paths, `git commit -m "<message>"` with **no** `Co-Authored-By`, no "Generated with" line and no other AI attribution, then `git push origin feat/vps-slim-source-native`. Never commit secrets, `.env*` files or `.claude/`.

## Acceptance criteria

- [ ] `discover`, `sources`, `source` and `dialogue` are gone from the Cinematic `PENDING` set, and the Vitest completeness test over `SCREEN_IDS` passes.
- [ ] Every item in sections A–G exists and behaves as written; every listed state renders (checked in the proof screenshots or the e2e spec).
- [ ] The index field types its placeholder at 50 ms per character in Bodoni Moda Italic, switches to Roman while typing, draws the 2 px `spot` underline on focus, and exposes the accessible name "Search every source" (or the ASK and dialogue names).
- [ ] Scopes: `DIALOGUE` is absent in novels mode and when OCR is unavailable; `ASK` is absent when AI is unavailable; `?scope=text` and unknown values render `ALL`; keys `1`–`5` switch the visible scopes.
- [ ] Results show the tiered status line, `IN YOUR LIBRARY` first and `IN DIALOGUE` last, per-source `Retry` retrying only that source, the collapsed empty groups toggle and the `ALL · WITH RESULTS · PINNED` filter; the group jump scrolls in 400 ms (a jump under reduced motion) and `[` / `]` work.
- [ ] The genre tiles come from the union of the pinned sources' genres ordered by the profile's weights, are capped at 12 with an `All {n} genres` toggle, and a single-source genre opens its catalogue directly; `/search#genre=Romance` opens that genre's sheet.
- [ ] Sources: the table shows logo, name and description, `LANGUAGE` (not at 768–1023), `KIND`, health mark and text, `18` for mature sources, and the pin toggle; pinned rows reorder by drag, by the four Move items and by `Alt+↑/↓`, each announced; `PUT /sources/pins` carries the full order including unavailable pins.
- [ ] Catalogue: browse modes as tabs, the genre select, the search field, the wall at 6 / 8 / 5 / 3 per row, infinite scroll with `LOADING MORE`, load-more retry and `END OF CATALOGUE`; the opening state changes the deck and starts the typed tips after 3 s and fades in the source-hued wash; `browsable: false` shows the not-browsable notice; `source_not_found` shows the §8.0.10 notice.
- [ ] Dialogue: each hit renders a 16:9 still cropped around its box with the subtitle band, the transcript with highlighted terms and the credit line; opening a hit lands on the matched page and pulses the 2 px `spot` frame twice, or shows the chapter-start toast; novels mode shows its notice.
- [ ] Every request added here passes through the limiter with the priority listed in section A; a Vitest case asserts that dialogue page images and genre cover lookups are issued as P3.
- [ ] Reduced motion: with `page.emulateMedia({ reducedMotion: "reduce" })` the e2e spec asserts that no element under the Discover screen has a running letter-reveal animation after 250 ms, the placeholder text is complete at once, and the group jump sets `scrollTop` without a smooth scroll.
- [ ] Keyboard: every control on the four screens is reachable with `Tab` in reading order, shows the double focus ring, and the listed keys work; route focus lands on each screen's `h1`; `document.title` reads `Discover · ManhwaManiacs`, `Sources · ManhwaManiacs`, `{source} · ManhwaManiacs`, `Dialogue search · ManhwaManiacs`.
- [ ] Hit targets: on the 390 × 844 viewport every interactive element measures at least 44 × 44 CSS px (the e2e spec checks the bounding boxes of buttons, links, tabs and toggles on each screen); on 1440 × 900 at least 32 × 32.
- [ ] Contrast: no `ink.45` text on any ground other than `paper.0` (inside sheets, column panels, the mood grade and the source wash it renders `ink.60`); every subtitle and genre name over art meets the §2.1.4 over-art table.
- [ ] Per-skin difference: only `frontend/src/skins/cinematic/**` and skin-neutral `features/**` modules changed; the Glass skin still maps these four ScreenIds to its `PENDING` screen, and no file under `src/skins/cinematic/**` imports `src/skins/glass/**` or legacy components (the lint rule passes).
- [ ] `npm run typecheck`, `npm run lint` (0 errors, 0 warnings), `npm run test` and `npm run build` pass in `frontend/`; every test that passed at `00-baseline.md` still passes.

## Verification

Run from `/srv/manhwamaniacs/dev/ManhwaManiacs`, one command at a time, `free -m` first each time (stop if `available` < 1024 MB):

```bash
free -m
node design/build.mjs --check
cd frontend
npm run typecheck
npm run lint            # baseline: exit 0, 0 errors, 0 warnings
npm run test            # every baseline test plus the new ones must pass
free -m
npm run build           # baseline: exit 0; nothing else (next dev, playwright) may run meanwhile
```

This step changes nothing under `mobile/` or `backend/`. Prove it on your own commits, not on a range (the mobile, backend and shared sessions push to the same branch in parallel, so a range diff shows their work too): `for c in <each commit SHA you made in this step>; do git show --name-only --format= "$c"; done | grep -E '^(mobile|backend)/'` must print nothing. The other suites are therefore not re-run here; their sessions run them and keep the baseline: `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze` (No issues found), `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter test` (all 2012 passed) and `cd backend && .venv/bin/python -m pytest -q --no-header`.

**Visual proof.** Start the dev stack with `free -m && backend/scripts/dev_stack.sh start` (the dev stack of `backend/scripts/README-dev-stack.md`: uvicorn on 127.0.0.1:8010 against the dev SQLite under `/srv/manhwamaniacs/dev/data/`, never production data; the script already sets `MM_NOVELS_ENABLED=true`, turns rate limits off and leaves the AI key unset; run `backend/scripts/dev_stack.sh seed` once if the `demo` account does not exist yet), then the web client with `cd frontend && free -m && NEXT_PUBLIC_API_URL=/api BACKEND_INTERNAL_URL=http://127.0.0.1:8010 npx next dev -p 3010` (both variables are required: without `NEXT_PUBLIC_API_URL=/api` the browser calls `http://127.0.0.1:8000` directly (`src/config/env.ts`), and without `BACKEND_INTERNAL_URL` the `/api` rewrite in `next.config.ts` targets port 8000). Write `docs/redesign/proof/web-16/routes.txt` with these routes (replace `{id}` with a healthy source id from `GET /sources` on the dev stack):

```
/search
/search?q=solo
/search?q=qzxwv
/search?scope=ask
/search#genre=Action
/sources
/sources/{id}
/sources/{id}?q=a
/ocr
/ocr?q=the
```

Then capture with the `web/03` harness at 1440 × 900 and 390 × 844, once plain and once with the grid overlay:

```bash
free -m
cd frontend
MM_PROOF_USER=<demo user> MM_PROOF_PASSWORD=<demo password> node scripts/proof.mjs --step web-16 --skin cinematic --routes /srv/manhwamaniacs/dev/ManhwaManiacs/docs/redesign/proof/web-16/routes.txt --grid
free -m
MM_PROOF_USER=<demo user> MM_PROOF_PASSWORD=<demo password> node scripts/proof.mjs --step web-16 --skin cinematic --routes /srv/manhwamaniacs/dev/ManhwaManiacs/docs/redesign/proof/web-16/routes.txt --reduced
```

The credentials are the seeded demo account's, from `backend/scripts/README-dev-stack.md` (never hard-code them in a file). `--grid` saves a `-grid` copy of every shot and `--reduced` a `-reduced` set; both viewports (1440 × 900 and 390 × 844) are captured by default.

Then run the e2e checks against the same dev server, from `frontend/`:

```bash
free -m
E2E_BASE_URL=http://127.0.0.1:3010 MM_PROOF_USER=<demo user> MM_PROOF_PASSWORD=<demo password> npx playwright test e2e/cinematic/web-16-discover.spec.ts
```

`e2e/cinematic/web-16-discover.spec.ts` signs in with `signIn` imported from `scripts/proof.mjs` (the seeded demo account from the same environment variables), sets the `mm-skin-debug=cinematic` cookie, and asserts the hit-target, focus, `document.title`, reduced-motion and limiter-priority checks above; it mocks `/api/sources/search*` with `page.route` to force the partial, failed-group and rate-limited states and saves those screenshots too (`docs/redesign/proof/web-16/state-*.png`). Stop `next dev` and the dev stack when done.

## Report back

Reply with:
1. The checklist above with each box ticked or, if not, why.
2. The list of commits (short SHA and message) and confirmation they are pushed.
3. The screenshot folder `docs/redesign/proof/web-16/` with the file count, and the states captured per screen.
4. Test counts: Vitest passed / failed / total (and the baseline total), lint errors and warnings, typecheck result, `next build` result and time, e2e passed / failed.
5. The lowest `free -m` available value you saw.
6. Open issues: anything in the spec you could not build, backend fields that were missing (for example `page` or `box` on `/ocr/search`), and any deviation you had to make, with the reason.

Next prompt: `docs/redesign/prompts/web/17-cinematic-downloads-index-status.md`
