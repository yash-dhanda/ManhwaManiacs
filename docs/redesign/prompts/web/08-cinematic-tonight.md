# Web 08: Cinematic Tonight (home)

## Goal

Build the Cinematic skin's landing screen, **Tonight**, at `/` on the web client (`frontend/`), exactly as `docs/redesign/cinematic/DESIGN.md` §8.8, §9.1.1 and §9.1.2 specify: the cover story spread with its typed main headline, the trailer scrub that compresses the cover story into a now-showing strip in the running head, Continue reading, New this week, Also in this issue, the AI rails (Picked for you, Because you read), the numbers teaser with the streak flame, the novel-mode title page, the offline edition, and every loading, empty, new-profile, AI-unavailable, offline, error and stale state, for desktop web (768 px and up), tablet widths and mobile web (below 768 px). The data comes from one new shared hook, `useHomeFeed()` in `frontend/src/features/home/`, which both skins use (Glass's home in web/31 reads the same hook), including a local fallback composer for when `GET /home` fails. When you finish, the `tonight` ScreenId leaves the Cinematic `PENDING` set. The mobile session runs `docs/redesign/prompts/mobile/08-cinematic-tonight.md` in parallel on Flutter; do not touch `mobile/`.

## Read first

Read these before writing the plan. DESIGN.md is binding; where this prompt and DESIGN.md disagree, DESIGN.md wins and you note the conflict in your report.

- `docs/redesign/cinematic/DESIGN.md`:
  - §1 Manifesto; §2.1.1 (the `ink.45` raised-stock rule), §2.1.2, §2.1.4 (scrims and the over-art rule), §2.1.5 (ambient colour and how it animates), §2.1.6 (mood grades), §2.2 (grid and rhythm), §2.3, §2.4 (stacking layers), §2.7 (icons, including `flame-1` and `flame-3`), §2.8 and §3.5 (token and type-role names; only these names may appear in skin code).
  - §3.1–§3.3 (type rules: sentence case, lining figures, `text-wrap: balance`, long titles step down one role past 24 graphemes).
  - §4 entire (durations, curves, the motion table, stagger, interruptibility, the reduced-motion table §4.8).
  - §5 and §6 (the events this screen fires).
  - §7 intro (hit areas, focus, cursors, semantics), §7.1, §7.2, §7.6 (Feature, Cutting, World, Stat block cards), §7.7, §7.8, §7.11, §7.13 (running head), §7.14, §7.17, §7.18, §7.19, §7.22 (Quick look), §7.23, §7.24, §7.28, §7.29 (spoken folios), §7.30.
  - §8.0.1–§8.0.9 (frames, route contract, transitions §8.0.4, platform rules, global keys, content mode and the novel title page §8.0.8, tablet layouts §8.0.9), §8.0.10.
  - **§8.8 Tonight, entire.**
  - §9.1.1, §9.1.2, §9.1.4 (the Because-you-read heading rule), §9.1.5 (only the availability object and the "Rendering" rule), §9.1.6, §9.1.7 (the `GET /home` shape and section items), §9.1.8; §9.2.2 (the streak flame).
  - §10.1 and §10.2 (the two signature animations), §11 (Tonight rows of the gesture matrix), §13 moments 2 and 17, §14 entire, §15.2, §15.6, §15.7, §15.9.
- `docs/redesign/glass/DESIGN.md` §8.8 first paragraph, §9.1.6 and §15.6 (the shared home feed contract Glass reads through the same hook).
- `docs/redesign/inventory/00-decisions.md` (binding owner decisions).
- `docs/redesign/stack-decision.md` §2.2 (web folder layout and the import boundary), §2.6 (one data layer).
- `docs/redesign/inventory/web.md` §7.1 rows LS4 and LS5 (continue reading today), §2.11 (shared state components).
- `docs/redesign/inventory/capabilities.md` §1 (auth, `X-Profile-Id`, error envelope, 18+ absence), §8 (home strips), §9 (AI).
- `docs/redesign/00-baseline.md` (health baseline and RAM figures).

## Before you start

1. Work in `/srv/manhwamaniacs/dev/ManhwaManiacs` on branch `feat/vps-slim-source-native` (`git branch --show-current`). Run `git status --porcelain` and note any files other sessions have modified; never stage them.
2. This step depends on `docs/redesign/prompts/web/07-cinematic-auth-profiles-18plus.md`, `docs/redesign/prompts/backend/04-ai-home-composition.md` and `docs/redesign/prompts/backend/01-cover-ambient-and-palette.md`. Check they landed:
   - `grep -n '"/home"' backend/routes/*.py` finds the `GET /home` route, and `grep -rn "ambient" backend/services/image_resize.py` finds the ambient extractor.
   - `ls frontend/src/features/offline/mature-filter.ts` exists (web/07).
   - `grep -n "tonight" frontend/src/skins/cinematic/index.ts` shows `tonight` still in the `PENDING` set.
   If any check fails, stop and report which dependency is missing.
3. Inventory what earlier web steps built, and reuse it; never re-implement a primitive inside a screen:
   - `ls frontend/src/skins/cinematic frontend/src/skins/cinematic/primitives` and `grep -n "^export" frontend/src/skins/cinematic/motion.ts frontend/src/skins/cinematic/haptics.ts frontend/src/skins/cinematic/sounds.ts frontend/src/skins/contract.generated.ts`.
   - Expect (from web/04, web/05, web/06, per DESIGN.md §15.2): `play()`, `SetHeading`, `useTitleSignal`, `TypedHeadline`, `useTyped`, `RackImage`, `Drift`, `Flicker`, `RuleDraw`, `ColumnWipe` and the Dip in `motion.ts`; `Grain.tsx`, `duotone.tsx`, `tint.ts`; primitives for §7.1 buttons, §7.2 icon buttons, §7.4 search fields, §7.5 slug lines, §7.6 cards, §7.7 posters, §7.8 rails with the preview slate, §7.9 sheets, §7.11 toasts, §7.12 contents tabs, §7.17 galley proofs, §7.18 progress and leader dials, §7.19 badges, §7.22 menus and Quick look, §7.23 notices, §7.24 certificate and rating card host, §7.26 keycaps, §7.27 masthead and section header, §7.28 `Grid`, `Measure`, `Spread`, `Credits`, §7.29 pull to reprint, §7.30 Lightbox; the shell (`Shell.tsx`) with the running head, thumb index, sidebar and toast host (web/06).
   - The reader entry is web/06's: `enterReader(href, { entry: "wipe" | "dip", prefetch })` and `useReaderPrefetch(chapter)` (P3 manifest and first two pages after a 150 ms hover or focus dwell, P1 on press), both re-exported from `frontend/src/skins/cinematic/motion.ts` (`grep -n "enterReader\|useReaderPrefetch" frontend/src/skins/cinematic/motion.ts`). They play the Column wipe or the Dip through `play()` and push after the close. Use them everywhere below; never write a second helper. If they are missing, web/06 is not done: stop and report.
   - If a primitive lacks a variant this screen needs, add the variant to the primitive's own file and to the primitives gallery under `frontend/src/app/(preview)/`, never inside the screen.
4. Record the baseline for this step before your first edit, one command at a time (RAM guard below): `cd frontend && npm run test 2>&1 | tail -5` (note passed and failed totals). Every test that passes now must still pass at the end.

## Skills to invoke

1. `superpowers:writing-plans` before any code: write the plan to `docs/redesign/proof/web-08/plan.md` (task list in the order of the Scope sections below).
2. `superpowers:subagent-driven-development` to run the plan (or `superpowers:executing-plans` if you work inline). If you dispatch subagents, give each one a scope-locked prompt that names its files, and verify their work against `git status` and `git diff`, never against the agent's own report.
3. `frontend-design:frontend-design`, `impeccable:impeccable` and `taste-skill:taste-skill` for design quality reviews of each finished part. They review against DESIGN.md; they never change a token, a duration, a copy string or a layout rule that DESIGN.md fixes.
4. `superpowers:verification-before-completion` before you claim anything is done.

## Scope

Deliver every item below. Cinematic only (Glass's home is web/31). Section numbers refer to `docs/redesign/cinematic/DESIGN.md`.

### A. Shared data layer: `frontend/src/features/home/` (skin-neutral; both skins import it)

No JSX in this folder and no import from `src/skins/**`. Every file gets a Vitest `*.test.ts` beside it where it holds logic (the Vitest config only collects `src/**/*.test.ts`, in the `node` environment).

1. `types.ts`: the `GET /home` response of §9.1.7 as TypeScript types: `HomeFeed {issue_no, headline, deck, streak, cover, also, sections, ai}`, `HomeStreak {current_days, longest_days, at_risk, last_active_date, milestones_seen}`, `HomeCover {source_id, series_key, chapter_key, reason, ambient, content_kind, recap}`, `HomeAlso {kind: "new_chapters" | "because" | "letter" | "almost_there", source_id, series_key, headline, deck, ambient}`, `HomeSection {type, title, seed?, note?, items, why?, state: "ready" | "empty" | "unavailable" | "stale", generated_at}` with the section type union `first_picks | continue | new_this_week | almost_there | where_were_we | sent_to_you | picked | because | circle | circle_top | sources | genres | numbers | popular` plus the client-only `saved` (the offline edition, item 6), the per-type item shapes of the §9.1.7 "section items" table, `RecapAvailability` (the §9.1.5 object), `Ambient {duo, tint, ink} | null`, `AiState {available, reason}`.
2. `api.ts`: `homeApi.get({ contentKind, tzOffsetMinutes })` calling `GET /home` through the existing HTTP client the other `features/*/api.ts` files use (it adds `X-Profile-Id`). `tz_offset_minutes` is always sent as `-new Date().getTimezoneOffset()`; `content_kind` is sent as the active reading mode (`manga` or `novel`, from `features/content-mode`) whenever the server reports `novels_enabled`, and omitted otherwise.
3. `use-home-feed.ts`: `useHomeFeed()` on React Query 5 with the exported key builder `homeFeedQueryKey(profileId, matureEnabled, contentKind)` = `["home", profileId, matureEnabled, contentKind]` (web/18's edition preview seeds this exact key from `frontend/src/skins/preview-feed.generated.json`, §8.30.3). `staleTime` 10 minutes (the server caches 10 minutes), `refetchOnWindowFocus: false`, `retry: 1`. It returns `{ state: "loading" | "ready" | "empty" | "unavailable", feed: HomeFeed | null, origin: "server" | "local" | "offline", offline: boolean, isFetching, refetch }`:
   - `origin: "server"` when `GET /home` answers.
   - `origin: "local"` when `GET /home` fails and the device is online: the feed is composed by `composeLocalFeed()` (item 4) from the existing hooks `useContinueReading(12)`, `libraryApi.recentlyUpdated(12)`, `useWorldRecommendations()`, `useAllFollowedSeries()`, `useStatistics(7)` and `useSourcePins()` (import each from its data file, for example `@/features/library/hooks`, never from a barrel `index.ts` that re-exports components). Inputs that fail leave their sections with `state: "unavailable"`; `state` of the whole feed is `"unavailable"` only when every input failed.
   - `origin: "offline"` when the device is offline (`useOnlineStatus()` from `features/offline/hooks.ts`): the feed is `composeOfflineEdition()` (item 6).
   - `state: "empty"` when the feed holds no cover story and no rendered section (a new profile with no pins and no sources).
   - The client-side at-risk override of §9.1.2 is applied here, after either origin: `at_risk = localHour >= 20 && streak.current_days >= 2 && streak.last_active_date < localToday`; when it differs from the payload's flag, the local value wins and the headline and deck are swapped by `composeHeadline()` (item 5).
4. `local-feed.ts`: `composeLocalFeed(inputs, now)`, a pure function that builds a `HomeFeed` with `ai: {available: false, reason: "not_configured" | the world-recs reason}` by the same rules the backend uses:
   - Cover story by §9.1.2 cases 1–3 (1: a followed series in progress with new chapters since the last read, most recent `last_read_at` first; 2: a chapter in progress, unfinished, read within 21 days; 3: a followed series paused 7–60 days whose continue row carries `recap.available`), else the most recently updated followed series (§9.1.6), else case 5 with the first pinned source's popular titles.
   - `also[]` by the §8.8 priority walk: `new_chapters` (most unread new chapters), `because` (the top world rec), `letter` (never locally: letters need the server), `almost_there` (fewest chapters left); never the cover story's series, never a repeat.
   - Sections `continue`, `new_this_week` (followed series updated in the last 7 days), `almost_there` (reading, ≤ 3 chapters left, fewest first, up to 12), `where_were_we` (reading, last read 21–120 days ago, not finished, most recent first, up to 12), `picked` replaced by `From your shelf` items (favourites and plan-to-read, §9.1.6) with `state: "unavailable"`, `because` from world recs when reachable (omitted otherwise), `sources` from pins, `numbers` from statistics.
   - Test `local-feed.test.ts` covers each cover-story case, the `also` walk (three, two, one and zero candidates), exclusion of the cover series from `also`, and the `ai` block.
5. `headline.ts`: `composeHeadline({ caseId, title, chapterNumber, pagesLeft, pausedDays, pageOf, why, synopsisFirstSentence, streak, now })` returning `{ headline, deck, titleInKicker }` per the §9.1.2 table, with these rules exactly:
   - Time word by local hour: "This morning" 05–11, "This afternoon" 12–17, "Tonight" otherwise.
   - At most 60 graphemes (count with `Intl.Segmenter(undefined, { granularity: "grapheme" })`), sentence case, full stops. When a headline that names the series exceeds 60 graphemes, the title moves to the kicker (`titleInKicker: true`) and the headline takes its chapter form: case 1 "Tonight: chapter 143.", case 3 "Tonight: back to chapter 87.", cases 4 and 4b "Tonight: start chapter 1.". Case 2 over 60 drops its second sentence ("Tonight: finish chapter 142.").
   - Numbers (§12.5): in headlines a count is spelled out when it is under ten or when it opens a sentence ("Twelve pages left.", "Twelve days and counting."); every other count is a numeral, and chapter numbers are always numerals.
   - At-risk line (overrides cases 1–4b, keeps their cover series): the count opens the sentence and is spelled out with a capital ("Two", "Twelve", "Thirty-one", "One hundred and one"): "{Count} days and counting. One chapter keeps it alive."; when that line exceeds 60 graphemes, "Your {n}-day streak ends at midnight." with a numeral. Deck: "Open any chapter before midnight to keep your streak."
   - Every row of the §9.1.2 table (1, 2, 3, 4, 4b, 5, caught up, at risk) and its deck, copied verbatim.
   - Test `headline.test.ts`: each table row, the 60-grapheme fallback of each case, the three time words at 04:59, 05:00, 11:59, 12:00, 17:59, 18:00, and `spellCount` for 2, 12, 31, 99, 100, 101, 123.
6. `offline-edition.ts`: `saveLastFeed(contentKind, feed)` and `readLastFeed(contentKind)` in scoped `localStorage` under `mm.home.last.<manga|novel>` (through `lib/scoped-storage.ts`, so each profile has its own copy), each stored item stamped `mature: bool` (the source's `mature` flag OR the resolved `rating == "mature"` after `mature_override`, §7.24); `composeOfflineEdition({ lastFeed, savedChapters, now })` builds the offline edition: headline "Offline edition.", deck "Only what's saved on this device is here.", sections `saved` ("Saved on this device": the saved series from the service-worker download index) and `continue` ("Continue (saved chapters)": continue rows whose chapter is saved), every row passed through `features/offline/mature-filter.ts` so a closed gate hides mature rows without a trace (§7.24). The cover story is the most recently read saved series, or none. Test covers the gate closed and open, and the empty case.
7. `continue-hidden.ts`: "Remove from row" for the Continue rows (Tonight and Library, both skins). Scoped `localStorage` key `mm.continue.hidden`, a list of `{source_id, series_key, chapter_key}`; `filterHidden(rows)` drops a row while its `chapter_key` is still the stored one (a new chapter brings the series back); `hideContinue(row)` and `unhideContinue(row)` for the toast's Undo. Test included.
8. `front-page.ts`: once-per-day-per-profile memory for the Front page moment: scoped `localStorage` `mm.tonight.typed = {date: "YYYY-MM-DD" local, variant: "normal" | "at-risk"}`; `shouldPlayFrontPage(now, variant)` is true when the stored date is not today or the stored variant differs (so the at-risk line types once more after 20:00, §9.1.2). Test included.
9. `frontend/src/features/library/streak.ts` (shared, The Numbers in web/21 reuses it): `streakTier(days)` → `none` (0), `one` (1–6), `three` (7–29), `ring` (30–99), `sparks` (100+); `streakState(streak, now)` → `alive-today` | `alive-not-today` | `at-risk` | `none` with "read today" meaning `last_active_date == local today` (§9.2.2); `justExtended(streak, now)` reading and writing scoped `mm.streak.seen` (the last `last_active_date` this profile has seen on this device), true once when the date flips to today. Test included.
10. `frontend/src/features/ai/feedback.ts` (create only if `grep -rn "ai/feedback" frontend/src/features` finds nothing): `sendAiFeedback({ signal, anilist_id?, source_id?, series_key?, tag? })` → `POST /ai/feedback`, 204. web/19 reuses it.

### B. The Tonight screen: `frontend/src/skins/cinematic/screens/tonight/`

Wire `screens.tonight` in `frontend/src/skins/cinematic/index.ts` to `TonightScreen` and remove `tonight` from `PENDING`. `document.title` is "Tonight · ManhwaManiacs". The route is `frontend/src/app/(app)/page.tsx` (thin, from web/00); do not change it.

#### B1. Frame and page top

- Desktop frame (≥ 768 px, web/06 shell): Contents sidebar with `01 Tonight` lit, running head transparent over the spread (56 px, `scrim.head` under it: `#000` at .88 flat over the bar then the 13 eased stops reversed to 0 over 64 px, §2.1.4). Phone frame (< 768 px): running head transparent until the cover scrolls away (44 px + safe-area inset), thumb index with `TONIGHT` lit.
- Mood grade (§2.1.6): a 30 vh gradient from the profile's mood colour (`color.mood.*`: romantic `#1A0B10`, action `#1A0D08`, comedy `#17130A`, horror `#0F0A0D`, slice_of_life `#0F120C`, fantasy `#120C18`; `default` has none) to `#000000` behind the top of the page, under the spread art. The text column above it renders `ink.45` roles as `ink.60` (raised stock, §2.1.1).
- Page rhythm (§2.2.2): each section is a 1 px `rule.1` section rule, 12 px, the header row, 12 px, the content, then 64 px (desktop) or 40 px (phone) to the next rule. Content on the 12-column grid (desktop 1024–1439: margin 48, gutter 24; wide 1440–1919: margin 72, gutter 24, max 1760; cinema ≥ 1920: margin 96, gutter 32; 768–1023: 8 columns; phone: 4 columns, margin 16, gutter 12), through the `Grid` primitive.

#### B2. The cover story spread (desktop, 12 columns)

- Height `clamp(560px, 72vh, 820px)`, built on the `Spread` primitive (§7.28).
- Columns 1–5 (text), in reading order:
  1. Kicker `TONIGHT · No. 184` (`type.kicker`; the issue number is `issue_no` from the feed). When `titleInKicker`, the kicker reads `TONIGHT · No. 184 · {SERIES TITLE}`. While at risk, a 16 px at-risk streak flame (§9.2.2) in `spot` sits before the kicker.
  2. The main headline: `TypedHeadline` with `as="h1"`, `type.cover` (fluid `clamp(2.75rem, 1.296rem + 6.2vw, 7.5rem)`, tracking −0.040em, Bodoni Moda Roman opsz 96 wght 700), one grapheme per 50 ms (`dur.type`), the 0.12em × 0.86em `spot` caret, which blinks off/on in 530 ms halves for 3180 ms after the last grapheme and fades 1 → 0 over 160 ms. It is `h1` because it is the page's only title (§10.2.3). `text-wrap: balance`.
  3. Deck: `type.deck` `ink.60` (the AI one-liner, or the synopsis's first sentence), max 62ch.
  4. Credits (§7.28 `Credits`): opens with the series title as a `SetHeading` (`trigger="signal"`, `as="h2"`, `type.subhead`; §10.1.2 "Tonight's cover series title in the credits kicker line"), then label/value pairs `STORY` (author), `ART` (artist), `SOURCE` (name + the 6 × 6 px health mark and its label, §2.1.3), `STATUS`, `NEW CHAPTERS` (count), labels `type.credit.label` `ink.45` (renders `ink.60` on the grade), values `type.credit` `ink.100`.
  5. Actions: `split` primary lg (56 px) `Continue │ CH 143 · p.1` (or `Start │ CH 1` for a new pick; the folio segment in `type.folio` `#000` behind a 1 px `#000` divider), `secondary` `Previously on…` only when `cover.recap.available` (§9.1.5 "Rendering"), `quiet` `Details`. `Continue` enters the reader by the **Column wipe** (§8.14.2: desktop 376 + 40 + 456 = 872 ms, tablet 312 + 40 + 392 = 744 ms, phone 248 + 40 + 328 = 616 ms) through `enterReader(href, { entry: "wipe" })`, with `useReaderPrefetch()` on the button: the chapter manifest and first two pages as P3 after a 150 ms hover or focus dwell and as P1 on press (§15.6 limiter in `features/sources/`). `Previously on…` links to the typed route builder for `recap` (`/recap/:sourceId/:seriesKey?to=:chapterKey`, from `contract.generated.ts`; the recap screen itself is web/19). `Details` opens the feature page by the match cut.
- Columns 6–12 (art): the sharp cover at the full spread height against the right edge (cover proxy width 720, never upscaled); the space to its left is the same cover at `blur.bleed` (56 px), duotoned to `ambient.duo` (the `duotone.tsx` filter, `color-interpolation-filters="sRGB"`); `scrim.gutter` over columns 6–7 (horizontal, the 13 eased stops of §2.1.4, `#000` at the text side); grain at 0.06 (overlay, the `Grain` primitive, art only); `scrim.vignette` (`radial-gradient(120% 90% at 50% 40%, rgb(0 0 0/0) 60%, rgb(0 0 0/.45) 100%)`); **Drift** on the sharp cover (26 s alternate infinite, scale 1.00 → 1.06 and translate −1 %, −1.5 %, `ease.drift` `cubic-bezier(0.37, 0, 0.63, 1)`, paused off screen). `--amb-duo`, `--amb-tint`, `--amb-ink` are written on the spread element only (§2.1.5), starting from the `color.ambient.fallback.*` tokens (`#B8B2A4`, `#0E0D0B`, `#F3F0E8`) when `ambient` is null and dissolving to the real values over 800 ms `ease.turn` when they arrive.
- A 2 px `spot` progress rule runs along the bottom of the art for the chapter in progress (`role="progressbar"`, `aria-valuetext` through `folioLabel()`).
- Click on the art opens the feature page by the match cut (`<ViewTransition name={coverTransitionName(sourceId, seriesKey)} share="mm-match-cut">`, 480 ms `ease.turn`; the reverse on back is 336 ms); double-click, long-press 450 ms and the key `v` open the Lightbox (§7.30) on the cover; an overflow `dots-three` beside `Details` holds `View cover` (the non-gesture path).
- Desktop dwell: pointer resting 400 ms (`dur.dwell.backdrop`) on a poster in any rail swaps the spread's blurred backdrop and ambient colours to that series by **Dissolve** (800 ms `ease.turn`) while the spread is at least 30 % in view (IntersectionObserver threshold 0.3), without changing the headline, kicker, credits or buttons; leaving the rail dissolves back to the cover story's art.

#### B3. Tablet (768–1023 px on the web)

The spread uses 8 columns: text columns 1–4, art columns 5–8, `scrim.gutter` over art columns 5–6. Also in this issue becomes 2 + 1 (two cards across 4 + 4 columns, the third on the next row across 4). Rails show 5.2 posters (12 px gap).

#### B4. Phone layout (below 768 px)

1. Cover: full-bleed cover art 4:5, max `70svh`, with `scrim.foot` into `ambient.tint` (the gradient reaches alpha 1 of `ambient.tint` 24 px above the first line box of the text block, measured, and the whole text block sits on the solid end colour), Drift, grain 0.06. Over its lower third: kicker, the typed headline in `type.cover` at 44/44 (up to 3 lines), the deck (2 lines, `-webkit-line-clamp: 2`).
2. Actions under the art: `split` primary full width (48 px); then a row of `secondary` `Previously on…` (only when available) and `quiet` `Details`.
3. Also in this issue: a horizontal Embla pager (`embla-carousel-react` 8.6.0) with `align: "center"`, the viewport spanning the full screen width outside the grid margins, slides `flex: 0 0 86%` with `padding-inline: 6px` (12 px between cards, about 21 px of each neighbour visible at 390 px). Under the pager: a folio `1 / 3` (`type.folio` `ink.45`) between two `ruled` icon buttons (`arrow-left`, `arrow-right`, 20 Regular, 44 px hit), disabled at the ends: the non-gesture alternative (§11).
4. The numbered sections as rails of 3.2 posters (2.3 at text scale ≥ 1.3), 40 px apart.
5. Pull to reprint (§7.29): the 2 px `spot` rule grows from the centre with the pull (rubber band c = 0.35), caption `PULL TO REPRINT` → `RELEASE TO REPRINT` at the 96 px trigger (haptic `refresh.arm`), then the indeterminate rule until the refetch settles.
6. The trailer scrub (B8) compresses the 4:5 cover into the thumbnail of a 64 px now-showing strip under the status bar.
7. Posters, cuttings and the cover art set `-webkit-touch-callout: none; user-select: none; -webkit-user-drag: none`, and the phone frame calls `preventDefault()` on `contextmenu` for elements with a long-press action (§8.0.5).

#### B5. Also in this issue

- Below the spread with a 64 px gap. Three **Feature** cards (§7.6: image 3:2 on desktop, 4:5 on phone → kicker `type.kicker` in the series `ambient.ink` (or `ink.45`) → headline `type.subhead`, 2 lines → deck `type.body.italic` `ink.60`, 2 lines; no frame; hover: image zooms 1.04 inside its frame and the headline underlines, 200 ms `dur.clip` `ease.settle`; pressed: 1 px impression; focus ring around the whole card; loading: flicker plate + greeked lines).
- Kicker by `kind`: `new_chapters` → `NEW THIS WEEK`, `because` → `BECAUSE YOU READ`, `letter` → `FROM THE CIRCLE`, `almost_there` → `ALMOST THERE`. Headline and deck come from the feed (`also[].headline`, `also[].deck`), for example "3 new chapters of *Tower of God*".
- Three cards: 4 + 4 + 4 columns. Two: 6 + 6 (a phone pager of two). One or none: the row is not rendered.
- A card opens its series' feature page by the match cut; a `letter` card opens `/circle` (the Circle screen arrives in web/22).

#### B6. The numbered sections

Render the sections of `feed.sections` in the server's order. A section with nothing to show is not rendered, and folios (`01`, `02`, …) are assigned to the rendered sections in order so the numbering never has a gap. Each header is the §7.8 header row: folio (`type.folio` `ink.45`) → 12 px → H3 as `SetHeading` (`trigger="inView"`, `as="h2"`, `id="tonight.<type>[.<seed key>]"`, `type.section`: Bodoni Moda Italic opsz 48 wght 600, fluid `clamp(1.5rem, 1.27rem + 0.98vw, 2.25rem)`, tracking −0.020em) → right-aligned `quiet` `See all` with a 16 px `arrow-right` where a destination exists. The section rule draws (Rule draw, 480 ms `ease.settle`, `scaleX` 0 → 1 from the left) 120 ms before the letters start; letters: 640 ms per grapheme (blur 8 px → 0 over 440 ms), rise 0.42em, stagger `min(24, 560 / (n − 1))` ms. Linked headings wipe letter by letter to `spot` on hover (200 ms `ease.set`, `transition-delay: calc(var(--i) * 10ms)`, back in 160 ms). When keyboard focus is inside a rail, its H3 is `ink.100` and its folio `spot` (160 ms).

| Section `type` | H3 text | Content and shape | `See all` |
|---|---|---|---|
| `first_picks` | Your first picks | Posters of the followed seeds, caption `NOT STARTED` | `/library` |
| `continue` | Continue reading | **Cuttings** (§7.6): 3:2 crop at `object-position: 50% 22%`, 2 px `spot` progress rule flush on the image's bottom edge, `type.title` 1 line, folio caption `CH 142 · 63%` or `NEXT · CH 143` when `page_count == 0`; nudge badges top-left `3 NEW` (`nudge: "new"`), `ALMOST DONE`, `PAUSED 21 D`. Up to 12, most recent first, never a finished Completed series. Rows hidden through `continue-hidden.ts` are dropped. Visible cuttings: phone 1.6, tablet 3.2, desktop 4, wide 5, cinema 6 (the §8.9 Library figures, extended) | `/library` |
| `new_this_week` | New this week | Posters with `NEW` / `3 NEW` / `99+ NEW` badges (fill `spot`, `#000` text), caption `CH 142 · 3 NEW` | `/updates` |
| `almost_there` | Almost there | Posters; caption folio `2 LEFT` in `spot`; up to 12, fewest left first | none |
| `where_were_we` | Where were we? | Posters; caption `3 WEEKS AGO · CH 87` (under 7 days `N D AGO`, under 35 days `N WEEKS AGO`, else `N MONTHS AGO`); Quick look offers `Previously on` first when that item's `recap.available`; up to 12 | none |
| `picked` | Picked for you | Posters of `{kind: "world" | "source"}` items; the `why` line appears in the preview slate and in Quick look | Picks (`/library/recommendations`, web/19) |
| `because` | Because you read *{title}* | World items in poster form, one rail per seed (1–3 rails). The seed title is set in **Roman** inside the italic head (§9.1.4): add a `roman: [start, end]` grapheme-range prop to `SetHeading` (in `motion.ts`, with a gallery entry) that renders that range with `font-style: normal` | Picks |
| `sources` | Sources | 16:9 duotone tiles (backdrop: `latest_covers[0]`, `object-fit: cover`, duotoned to `color.ambient.fallback.duo` `#B8B2A4`), the source name in `type.subhead` on the solid end of a `scrim.foot` (end colour `color.ambient.fallback.tint` `#0E0D0B`), and the three newest covers as a strip of 40 × 60 plates 4 px apart at the tile's bottom-right, 12 px inset. Hover and pressed as the §7.6 Feature card (image zoom 1.04 inside the frame + name underline, 200 ms `dur.clip` `ease.settle`; pressed a 1 px impression). Rail of tiles: phone 1.2, tablet 2.2, desktop 3, wide 4, cinema 4 visible. With 0 pins the caption line above the rail reads `SUGGESTED SOURCES` (`type.kicker` `ink.45`) | `/sources` |
| `genres` | Your genres | A slug line of genre links weighted by size: Archivo `wdth` 75 `wght` 600 uppercase +0.10em at 12/16, 15/20 or 20/24 px by weight tercile, separated by `·` in `ink.30` with 12 px spacing; each links to `/search#genre={genre}` (Discover opens that genre's sheet; `web/16` owns the hash, and `web/19` and `web/21` link the same way). Not rendered when there are no genres | none |
| `numbers` | This week in numbers | The numbers teaser (B7) | `/library/statistics` |
| `popular` | Popular on your sources | Posters from the pinned (or the 3 suggested) sources' `popular` browse mode, first 12, caption the source name | `/sources` |

- Posters (§7.7): 2:3, radius 0, `paper.1` placeholder with the inner hairline `inset 0 0 0 1px rgba(243,240,232,0.08)`, requested at the nearest snapped width ≥ rendered width × DPR (96, 160, 240, 360, 480, 720); caption below (`type.title` 1 line, 2 at text scale ≥ 1.3, then the folio caption in `ink.45`); badges top-left in a 4 px inset stack on their `#000000` fill: `NEW` counts, the 16 px `18` certificate only when the gate is open and the series is mature, `SAVED` when the service-worker index holds a chapter of it. Hover: image scales 1.04 inside the fixed frame, 2 px `ink.100` inside outline, art light `0 0 48px -16px` in `ambient.duo` at 60 %, caption title underlines, siblings dim to `brightness(0.55) saturate(0.8)` (200 ms `dur.clip`; sibling dim 280 ms `dur.dim`); pressed: scale 0.98 (80 ms `ease.set`, back 160 ms `ease.settle`); Rack focus on first decode (blur 14 px, brightness 0.6, scale 1.03 → sharp over 520 ms `ease.settle`, at most 12 at once per screen, the rest Develop); loading: flicker plate with the title card (Bodoni Moda Italic 14/16 `ink.45` bottom-left, 8 px inset) when the title is known; image error: plate + title card + 16 px `image-broken` glyph labelled "Cover didn't load".
- World items (`picked`, `because`): available items open the feature page (a source picker sheet when several `available[]` sources have it: kicker `OPEN ON`, rows with source logo 24, name and health mark, `Open` per row); information-only items render the poster in duotone (black → `ambient.duo`) with the caption credit `NOT ON YOUR SOURCES` in `ink.45`, and open Discover with `?q={title}`. With the gate open, the 16 px certificate sits top-left when `is_adult` is true or any `available[]` source is mature.
- Rails (§7.8): native horizontal scroll with `scroll-snap-type: x proximity` snapping to poster starts, `overscroll-behavior-x: contain`; visible posters phone 3.2, tablet 5.2, desktop 6.25, wide 7.25, cinema 8.25; gap phone 8, tablet 12, desktop 12, wide 12, cinema 16; poster width `(content width − visible_floor × gap) / visible`; 8 px vertical padding for the focus halo. Desktop paddles: 48 px wide, full poster height, over `scrim.rail-end` (`#000` 1 → 0 linear over 48 px), `arrow-left`/`arrow-right` 24 Light, appear on rail hover (160 ms), page by `visible − 1` posters over 560 ms `ease.turn`, hidden at the ends. Preview slate on 600 ms dwell or `Space` on a focused poster (the §7.8 slate from the Rail primitive, with `Read`, `+ Library`, `Details`). Keyboard: one tab stop per rail (roving `tabindex`), `←`/`→` move and scroll the poster into the first fully visible column (320 ms `ease.settle`), `↑`/`↓` move to the neighbouring rail with the page scrolled so it sits at 30 % of the viewport, `Home`/`End`, `Enter` opens. Rails with more than 30 items virtualise (§15.6).
- Quick look (long-press 450 ms on phones, right-click on desktop, `Shift+F10` or the context-menu key; the §7.22 primitive, haptic `longpress.open`). Put the per-item action lists in `frontend/src/skins/cinematic/parts/quick-look-actions.ts` (web/09 reuses them); each builder takes `{ entry: "wipe" | "dip" }` for its reader entry (Tonight passes `"wipe"`; Library, History and every other caller pass `"dip"`, §8.14.2):
  - Cutting: Open series, Continue (Column wipe), Previously on (only when `recap.available`), Mark read (the one-chapter call of §8.17: `POST /reader/progress/batch` with one row `{source_id, series_key, chapter_key, chapter_number, last_page: max(page_count, 1), page_count: max(page_count, 1), scroll_offset_px: 0, is_completed: true, time_spent_seconds: 0, manual: true}`, toast "Marked chapter 142 read." with Undo that sends `DELETE /reader/progress` for that key), Remove from row (toast "Removed from Continue reading." with Undo, held 8000 ms `dur.hold.toast.action`).
  - Followed poster: Open, Continue, Previously on (first in the list for `where_were_we`, only when available), Add to collection (the `parts/AddToShelfSheet.tsx` sheet: kicker `ADD TO SHELF`, one checkbox row per collection from `useCollections()`, toggling calls `useAddSeriesToCollection()` / `useRemoveSeriesFromCollection()`, haptic `follow.add` on add; empty: "No shelves yet." + `New shelf` linking to `/library/collections`), Favourite (`PATCH /library/series/{id} {is_favorite}`, haptic `favorite`), Download next 5 (fetch the chapter list as P1, queue the next five unread through the `features/offline` download queue, haptic `download.start`), Unfollow (commits at once, toast "Removed {title}." + Undo re-following with the saved status, favourite, notify, override and position, 8000 ms).
  - World or source pick: Open, Not for me (`sendAiFeedback({signal: "not_interested", …})`, the poster fades out over 240 ms and the rail closes the gap by Cut), and for information-only items `Search my sources` and `Read on {site} ↗`.
  - Source tile: Open.
  - `Recommend to…` is added by web/22 (Circle); do not render it here.

#### B7. The numbers teaser and the streak flame

- `This week in numbers` is a row of stat blocks (§7.6 Stat block: 3 px `rule.heavy` on top → kicker → numeral → caption; no frame): `STREAK` (the streak flame at 24 px beside the day count in `type.numeral`, caption by state below), `THIS WEEK` (`chapters_week` chapters), `TIME READ` (`seconds_week` as `3 H 20 M`), then a `quiet` link `Open The Numbers →` to `/library/statistics` (the screen arrives in web/21). Desktop: blocks across 3 + 3 + 3 columns and the link in the last 3; phone: 2 × 2. Loading: numeral replaced by a greeked bar at 40 % of the numeral size; value changes cross-fade 160 ms. Numerals are not typed on Tonight.
- New primitive `frontend/src/skins/cinematic/primitives/StreakFlame.tsx` (§9.2.2; web/21 reuses it and adds the milestone cards), props `{ streak, size: 16 | 24 | 96, now? }`, always `spot` yellow and never more glow than the one `spot.glow` bloom (`rgba(244,208,63,0.35)`):
  - Tiers by `streakTier()`: 0 → the ember dot, a 6 × 6 px square in `ink.45` centred where the flame would stand, no motion; 1–6 → `flame-1`; 7–29 → `flame-3`, tongues offset 300 ms from each other; 30–99 → `flame-3` inside a 1 px `spot` ring (a circle 1.5 × the glyph size) with a 4 px gap that turns once every 24 s (`dur.flame.ring`, `ease.linear`); 100+ → as 30–99 plus sparks: three 2 × 2 px `spot` squares rising 12 px and fading out over 900 ms (`dur.flame.spark`), one per second, then 3 s of rest.
  - States by `streakState()`: alive, read today → the tier glyph in Fill `spot` with the bloom, flickering 2 s (`dur.flame.flicker`): opacity 0.85 ↔ 1, scaleY 0.98 ↔ 1.02, `ease.drift`; alive, not yet today (before 20:00) → the glyph outlined (Light, `ink.100`), no bloom, no flicker, caption "Read today to keep your 12-day streak."; at risk (after 20:00, not yet today) → outlined in `spot` (Light), no bloom, flickering 0.7 ↔ 1 over 800 ms (`dur.flame.risk`, `ease.drift`), caption "Twelve days and counting. One chapter keeps it alive."; none → the ember dot, caption "Longest: 31 days. Start a new one today."; read today caption `DAYS IN A ROW · LONGEST 31`.
  - Just extended (`justExtended()` true on this visit): **Ignite**, stroke → fill over 400 ms (`dur.glide`) `ease.settle` with the bloom rising 0 → 0.35; when the new count crosses a tier boundary (1, 7, 30, 100) the glyph swaps to the new tier during the ignite; the day numeral types its new value (50 ms per character); haptic `streak.extend`; sound `bell` if on.
  - Loops start once when the flame mounts and pause off screen (IntersectionObserver). Reduced motion: static flame, static ring, no sparks, no flicker; Ignite shows the filled glyph and bloom at once.
  - Semantics: `role="img"` with `aria-label` "12-day streak, read today" / "12-day streak, not read yet today" / "12-day streak, at risk" / "No streak".
  - Add the flame to the primitives gallery in every tier and state.

#### B8. Scrub the trailer and the now-showing strip (§8.8, §13 moment 17)

- The one scroll-linked animation in the skin. Add `useTrailerScrub({ spreadRef, headBottom })` to `frontend/src/skins/cinematic/motion.ts` (§15.2 names it there): Motion ``useScroll({ target: spreadRef, offset: [`end ${headBottom + 240}px`, `end ${headBottom}px`] })`` with `useTransform` on `scrollYProgress` → `p` from 0 to 1, where `headBottom` is the running head's resting bottom edge (56 px desktop; 44 px plus `env(safe-area-inset-top)` in the phone frame). Source and target rects are measured once per layout with a `ResizeObserver` and applied as transforms only (`transform` and `opacity`, never layout; §15.6). It follows scroll frame for frame in both directions and never runs on its own clock. It logs frames and drops per gesture to the motion-timings overlay (§15.9) through web/02's recorder: `startGesture(<the Trailer scrub member of CineMotionName>)` when a scroll gesture moves `p` and `.end()` when it settles (scroll-linked moves have no planned duration, so they never go through `play()`'s timed path).
- As `p` goes 0 → 1:
  - The sharp cover's rect interpolates (FLIP transform, linear against `p`) from its place in columns 6–12 (phone: the 4:5 hero) to a 32 × 48 thumbnail slot in the running head; the `blur.bleed` field, grain and Drift fade out by `p` = 0.3 and then pause.
  - The text column rises 12 px and fades out by `p` = 0.55.
  - The running head grows from 56 to 64 px (phone: 44 to 64 px, plus the status inset) as a `scaleY` on its background (not a layout change) and turns `#000000` with its 1 px `rule.1` bottom.
  - From `p` = 0.6 to 1 the **now-showing strip** fades in inside the running head: desktop between the breadcrumb and the search trigger: the thumbnail, kicker `NOW SHOWING` (`type.kicker` `ink.45`), the series title (`type.title`, one line), and on the right a `split` primary at size sm (32 px visual, hit padded) `Continue │ CH 143` (Column wipe, as the cover story's button) plus `Previously on` (`quiet`) when available; the progress rule becomes a 2 px `spot` rule along the strip's bottom edge.
  - At `p` = 1 the strip is pinned (`z.sticky` 10 inside the running head) for as long as Tonight is scrolled below the spread; scrolling back up un-compresses it exactly.
  - The desktop breadcrumb fades out as the strip fades in and stays hidden while the strip is pinned.
  - Below 1440 px the search trigger collapses to a 44 px `bare` `magnifying-glass` button (tooltip "Search or jump" + the platform `mod+k` keycap, `⌘K` on Mac and `Ctrl K` elsewhere), `Previously on` moves into a `dots-three` overflow at the strip's right end, and the title truncates with an ellipsis at a 120 px minimum.
  - Phone frame: the thumbnail, then the title (one line, min 96 px, no kicker), then a `split` sm reading `▸ CH 143` (44 px hit), then `dots-three` holding `Previously on`.
- Focus during the scrub: at `p` ≥ 0.55 the text column gets `inert`; the strip's controls join the tab order at `p` ≥ 0.8 (opacity ≥ 0.5 there). If focus was inside the column when it went inert, it moves to the strip's `Continue` once `p` ≥ 0.8, and before that to Tonight's `main` region (`tabIndex={-1}`). Scrolling back below `p` = 0.55 reverses all of this.
- Integration with the running head (web/06): add a small slot to the running head, `NowShowingContext` in `frontend/src/skins/cinematic/screens/tonight/now-showing.tsx`, that Tonight provides (strip content + `p`) and the running head renders; the running head renders nothing extra on any other screen.
- Reduced motion: no compression; the spread scrolls away normally and the strip fades in over 150 ms (`dur.reduced`) once the spread's bottom passes the running head; the focus switch happens when the strip fades in.
- The key `c` continues the cover story from anywhere on Tonight, including while the strip is pinned.

#### B9. Novels mode and the title-page cover story (§8.0.8)

- In novels mode (`content_kind=novel`), every section and the cover story come from novels only.
- A novel cover story becomes the book's title page: columns 1–5 carry the kicker, the typed headline in `type.cover` ("Tonight: chapter 213 of The Beginning After the End."), the byline "by {author}" in Newsreader Italic 22, a 56 px wide 1 px rule in `ink.100` (`rule.ink`), the deck and credits (`CHAPTERS`, `≈ WORDS`, `SOURCE`, `STATUS`); columns 6–12 hold the 168 × 248 cover plate (square-cornered, 1 px `rule.2`) centred on a field of the same cover at `blur.bleed`, duotoned to `ambient.duo`, with `scrim.gutter`, grain and Drift on the field only. Actions: `Continue │ CH 213 · 42%`, `Listen` (secondary, only when the book has narrated chapters; it opens the novel reader with `?listen=1`, web/15) and `Previously on…` (when available).
- Phone: the 4:5 hero is the blurred duotone field with the 120 × 176 plate centred in its upper half, the typed headline and deck below it under `scrim.foot`.
- Without a cover, the plate is the Bodoni initial (the title's first grapheme in Bodoni Moda Roman wght 800, `ink.60`, centred) on `paper.1`.
- Rails in novels mode render World and followed items as posters of the book cover (2:3) with the same captions; `Continue` uses cuttings with the caption `42% · CH 212`.

#### B10. The Front page moment (§13 moment 2)

Once per day per profile (`shouldPlayFrontPage()`): the Oxford rule (3 px `ink.100` + 2 px gap + 1 px `ink.100`) draws under the running head (Rule draw, 480 ms `ease.settle`), the cover racks into focus (Rack focus 520 ms), the headline types itself with the `spot` caret, and the credits set in reading order (Set: fade 0 → 1 and rise 8 px → 0 over 320 ms `ease.settle`, 24 ms per row, capped at 360 ms). Later visits the same day show everything at rest: the headline renders complete with no caret and no typing (a plain `h1` with the same classes), sections render with no stagger, headings already seen this session do not replay. The at-risk variant types once more the first time it applies after 20:00. Tapping or clicking the headline, or `Enter`/`Space` on it, completes the typing at once; Tonight also registers `Enter` to call the headline's `skipRef` while it is typing.

#### B11. States (§8.8 States, §9.1.6, §9.1.8)

Every state renders in both frames and in both content modes.

- **Loading**: the galley proof of the whole page (§7.17): headline bars at `type.cover` height (60 % and 35 % wide), the art plate flickering (`paper.1` with the inner hairline), rail plates with title cards when titles are known; the kicker `TONIGHT` is live from the start. Flicker 1400 ms half-period, opacity 0.55 ↔ 1, `ease.drift`, 60 ms phase offsets in reading order; a skeleton appears only after 120 ms of waiting, and data that arrives after a skeleton dissolves in over 160 ms instead of running Set.
- **New profile, nothing read** (case 5): headline "Your first issue starts here."; deck "Follow three series and this page fills itself in."; primary `Find something` (to `/search`); sections `Popular on your sources`, `Sources`, `Your genres`. With 0 pins the server uses the 3 healthiest non-18+ sources; the `sources` rail is captioned `SUGGESTED SOURCES`; `genres` uses the onboarding taste genres (loved first) and is not rendered when there are none.
- **Just onboarded** (follows, nothing read; case 4b): the cover story is the first pick with `Start │ CH 1` and the headline "Tonight: start Omniscient Reader."; deck "Chapter 1 is waiting. The rest of your picks are below."; section 01 is `Your first picks`, then `Popular on your sources`, `Sources`, `Your genres`. (The onboarding flight into this rail is web/20.)
- **Streak at risk**: the at-risk headline and deck of item A5, the 16 px at-risk flame before the kicker, the cover series unchanged, sentence case, no red, no extra glow. In-app only.
- **Caught up everywhere**: headline "Tonight: you're caught up."; deck "Nothing new on your shelf. Here's something else."; the cover story is the top AI pick with `Start │ CH 1`.
- **AI unavailable / not configured / over budget** (`ai.available == false`, or a section with `state: "unavailable"`): the cover story comes from the local rules and the deck is the synopsis; `Picked for you` becomes `From your shelf` (favourites and plan-to-read from the library, same position) headed by a `NOTE` kicker line in `spot` with the §9.1.8 copy for `ai.reason` followed by "Here is your shelf instead." (budget: "The picks desk is closed tonight. Asks reset at midnight UTC. Here is your shelf instead."; not configured: "The editors' desk isn't set up on this server. Here is your shelf instead."; rate limited: `SLOW DOWN` "Too many asks at once. Try again in {n} s." with a live `Retry-After` countdown folio), in `type.caption` `ink.60`, never `proof`. `Because you read` rails come from world recs when reachable, otherwise they are omitted. `Almost there`, `Where were we?` and `Sent to you` are not AI-dependent and stay.
- **Partial**: loaded sections render; a missing AI section is omitted and the folios renumber.
- **Stale**: a non-AI section with `state: "stale"` shows the micro badge `SAVED COPY · 3 H` (1 px `spot` outline, `spot` text, `NOTE` semantics) beside its H3; an AI section whose `generated_at` is older than 24 h shows `PICKED 3 DAYS AGO` (1 px `ink.45` outline, `ink.45` text) beside its H3.
- **Offline** (`origin: "offline"`): headline "Offline edition."; deck "Only what's saved on this device is here."; sections `Saved on this device` and `Continue (saved chapters)`, both filtered by the 18+ gate on the device; everything else hidden; the running head shows the `OFFLINE EDITION` badge (web/06). No saved chapters: the spread collapses to the headline block with no art, and a primary `Go to Downloads`.
- **Error** (both `GET /home` and every local input failed, online): the §7.23 notice across 6 desktop columns (4 on phones) at 15 vh from the top: 3 px `rule.heavy` drawn on entrance, kicker `CORRECTION` in `proof`, typed headline (`h1`) "This issue didn't print.", deck "The server didn't answer. Saved chapters still open." (`type.deck` `ink.60`, max 48ch), primary `Try again` and quiet `Go to Downloads`. A single section whose inputs failed while others loaded keeps its header and shows the §7.8 error line `This row didn't load.` in `proof` `type.caption` with a `quiet` `Retry`.
- **Rate limited on the whole feed** (`429 rate_limited`): the notice with kicker `SLOW DOWN` and the live "Retrying in 12 s" folio from `Retry-After`.
- **18+ gate**: gated content is absent everywhere (no blurred tiles, no counts, no placeholders); the certificate appears only with the gate open. A gate change invalidates `homeFeedQueryKey` (web/07's invalidation list: add the key if it is missing) and the next paint re-enters the skeleton.
- **Footer**: a 1 px rule and `type.caption` "Issue No. 184 · compiled 21:04 · Refresh `r`" (the keycap per §7.26; "compiled" is the local `HH:MM` of the newest `generated_at` among the sections, or the fetch time when none).

#### B12. Keys, gestures, focus, transitions, haptics

- Page keys through `useShortcut` from `@/lib/keyboard` (group "Tonight"; single-key bindings respect the "Single-key shortcuts" setting the registry already guards; never fire while typing in a field; not delivered while the `g` sequence is armed): `r` reprint (refetch the feed; also an overflow `Refresh` item); `↓`/`↑` move focus between sections (to each rail's roving stop, the page scrolling it to 30 % of the viewport); rail keys as B6; `c` continues the cover story (Column wipe; also from the now-showing strip); `p` opens Previously on when available; `v` opens the cover in the Lightbox; `Enter` on the typing headline skips it. Every binding appears in the `?` sheet with its description.
- Focus on arrival moves to the `h1` (the headline, `tabIndex={-1}` once typed; `0` while typing, §10.2.3). Skip link to content (web/06) targets it.
- Transitions: in by Iris from the picker (web/07), Cut on the thumb index, Dip from the desktop sidebar and from readers (the shell's); out by the match cut to feature pages (every poster, cutting, Feature card and the spread cover carries `coverTransitionName`), by the Column wipe on `Continue` and on a cutting's Continue, and by the Dip for nothing on this screen.
- Gestures (§11): pull to reprint (phones); long-press posters and cuttings for Quick look; long-press the cover art for the Lightbox; the Also pager swipe; tap the headline to skip typing; the scroll drives the trailer scrub. Every gesture has its non-gesture alternative listed in §11 (overflow menus, buttons, keys).
- Haptics and sounds through `skins/cinematic/haptics.ts` and `sounds.ts` (web): `tap.primary` on `Continue` (no vibration on the web; sound `set` if on), `longpress.open` on Quick look and the Lightbox (Android Chrome `navigator.vibrate([12])`), `follow.add` on add to shelf and follow (`[12]`; sound `impress`), `favorite` (sound `tick`), `refresh.arm` (sound `tick`), `download.start`, `streak.extend` (sound `bell`). Never on scroll, the trailer scrub, hover, focus, typing or letter reveals.
- Lenis 1.3.26 smooth wheel on Tonight only in the desktop frame (`(min-width: 768px) and (pointer: fine)`), never under reduced motion: call web/06's `useSmoothWheel()` (`frontend/src/skins/cinematic/smooth-wheel.ts`, which applies exactly those conditions and creates `new Lenis({ autoRaf: true })`; Lenis 1.3.26's defaults are `lerp: 0.1`, `smoothWheel: true`, `syncTouch: false`) in `TonightScreen`; it destroys the instance on unmount. Never create a second Lenis instance. A two-finger horizontal trackpad swipe over a rail must still scroll the rail natively.

### C. Out of scope here (owned by later steps; do not build)

`Sent to you`, `From the Circle` and `Most read in the circle` sections and `Recommend to…` (web/22; until then skip section types this screen does not render without consuming a folio); the recap takeover itself and in-session re-ranking of rails (web/19); the streak milestone title cards (web/21); the onboarding flight into `Your first picks` (web/20); the edition preview route and its fixture (web/18); any Glass screen.

## File layout

Create or change only these paths (stage them explicitly):

```
frontend/src/features/home/{types,api,use-home-feed,local-feed,headline,offline-edition,continue-hidden,front-page}.ts
frontend/src/features/home/{local-feed,headline,offline-edition,continue-hidden,front-page}.test.ts
frontend/src/features/library/streak.ts, streak.test.ts
frontend/src/features/ai/feedback.ts                          (only if missing)
frontend/src/skins/cinematic/index.ts                         (tonight out of PENDING)
frontend/src/skins/cinematic/motion.ts                        (useTrailerScrub; SetHeading `roman` prop)
frontend/src/skins/cinematic/primitives/StreakFlame.tsx
frontend/src/skins/cinematic/parts/quick-look-actions.ts
frontend/src/skins/cinematic/parts/AddToShelfSheet.tsx
frontend/src/skins/cinematic/parts/SourcePickerSheet.tsx
frontend/src/skins/cinematic/screens/tonight/TonightScreen.tsx
frontend/src/skins/cinematic/screens/tonight/CoverSpread.tsx        (desktop, tablet and phone cover)
frontend/src/skins/cinematic/screens/tonight/NovelTitlePage.tsx
frontend/src/skins/cinematic/screens/tonight/AlsoInThisIssue.tsx
frontend/src/skins/cinematic/screens/tonight/Sections.tsx           (the section registry keyed by type)
frontend/src/skins/cinematic/screens/tonight/sections/*.tsx         (one file per rendered section type)
frontend/src/skins/cinematic/screens/tonight/NumbersTeaser.tsx
frontend/src/skins/cinematic/screens/tonight/now-showing.tsx
frontend/src/skins/cinematic/screens/tonight/TonightStates.tsx
frontend/src/skins/cinematic/screens/tonight/TonightFooter.tsx
frontend/src/skins/cinematic/screens/tonight/use-tonight-keys.ts
frontend/src/skins/cinematic/Shell.tsx or the running-head primitive   (the NowShowingContext slot only)
frontend/src/app/(preview)/…                                   (gallery entries for StreakFlame and SetHeading roman)
frontend/e2e/cinematic/web-08-tonight.spec.ts
frontend/e2e/fixtures/home/{ready,novel,new-profile,onboarded,caught-up,at-risk,ai-unavailable,stale}.json
docs/redesign/proof/web-08/…
```

Skin files import only `@/features/**` data files, `@/lib/**`, `@/skins/contract.generated`, and their own skin folder; the lint rule bans `@/components/**`, `@/features/*/components/**` and the Glass skin. Utilities in skin code use only the names of §2.8 and §3.5 (checked by `node design/lint-utilities.mjs`).

## Acceptance criteria

- [ ] `tonight` is out of the Cinematic `PENDING` set, and the Vitest completeness test passes.
- [ ] With the `mm-skin-debug=cinematic` cookie, `/` renders Tonight in the desktop frame at 1440 × 900 and in the phone frame at 390 × 844; the legacy skin still redirects `/` to `/library`.
- [ ] Desktop spread: text in columns 1–5, art in columns 6–12 against the right edge, `scrim.gutter` over columns 6–7, height `clamp(560px, 72vh, 820px)`; verified with the `mod+shift+g` grid overlay screenshot.
- [ ] The headline types at one grapheme per 50 ms: the Playwright spec samples it 500 ms after the typing starts and finds 10 ± 2 graphemes visible, and the full string is in the accessibility tree from the first frame (`sr-only` span). Tap, click, `Enter` and `Space` complete it at once. It types once per day per profile; a reload the same day shows it at rest with no caret.
- [ ] The at-risk headline appears when the device clock is after 20:00, `current_days ≥ 2` and `last_active_date` is before today, even when the payload's `at_risk` is false (fixture `at-risk.json` plus a mocked clock).
- [ ] Section H3s reveal per letter (fade, rise 0.42em, un-blur 8 px → 0) with the stagger capped at 560 ms, once per session per heading id; the section rule draws 120 ms before the letters; "Because you read" sets the seed title in Roman.
- [ ] Folios are gapless: with fixture sections `continue`, `picked` (unavailable), `because`, `numbers`, the rendered folios run `01`–`04` and `Picked for you` reads `From your shelf` with the `NOTE` line and "Here is your shelf instead.".
- [ ] Also in this issue renders 4 + 4 + 4 with three cards, 6 + 6 with two, nothing with one or none; never the cover story's series.
- [ ] The trailer scrub: scrolled so the spread's bottom is 120 px above the running head's bottom (p = 0.5), the text column has opacity < 0.2 and the now-showing strip is not yet visible; at p = 1 the strip is pinned with the thumbnail, `NOW SHOWING`, the title and `Continue │ CH n`; scrolling back restores the spread exactly. Only `transform` and `opacity` change on the spread and strip (checked in the Playwright spec by reading computed styles; no layout shift entries in `PerformanceObserver({type: "layout-shift"})` during the scrub).
- [ ] Focus: at p ≥ 0.55 the spread text column is `inert`; the strip's `Continue` is reachable by Tab at p ≥ 0.8.
- [ ] Reduced motion (Playwright `reducedMotion: "reduce"`, and `html[data-motion="reduced"]`): the headline shows complete with no caret, H3s fade in over 200 ms with no rise or blur, no Drift (the cover rests at scale 1.03), Rack focus becomes a 160 ms fade, skeletons static at 0.8 opacity, no trailer compression (the strip fades in over 150 ms once the spread is under the running head), the flame is static, Lenis is not mounted, every programmatic scroll jumps.
- [ ] Keyboard (desktop web): every control reachable by Tab in reading order; the double focus ring (2 px `ink.100` at 2 px offset plus the 6 px `#000` halo) shows on keyboard focus only and is never clipped; `r`, `↓`/`↑`, `c`, `p`, `v`, `Enter`, `←`/`→`/`Home`/`End`/`Space` on rails all work and all appear in the `?` sheet.
- [ ] Hit targets: every interactive element on the phone frame is at least 44 × 44 px (the spec asserts `getBoundingClientRect()` of every `button, a, [role="button"]` inside `main`), with at least 8 px between adjacent targets; on the desktop fine pointer at least 32 × 32 px.
- [ ] Offline (`context.setOffline(true)` after a first online load with one saved chapter): headline "Offline edition.", only `Saved on this device` and `Continue (saved chapters)`; with the gate closed, a saved mature series appears nowhere and nothing mentions it.
- [ ] Novels mode: a novel cover story renders the §8.0.8 title page with the 168 × 248 plate (desktop) and the 120 × 176 plate (phone).
- [ ] New-profile, just-onboarded, caught-up, AI-unavailable, stale, loading and error states match B11 (one screenshot each at both sizes).
- [ ] `useHomeFeed()` falls back to `composeLocalFeed()` when `GET /home` returns 500 (fixture route), and Tonight still renders a cover story and the non-AI sections.
- [ ] Every scrim with text resolves (the Playwright spec asserts the computed `background-image` of the running head's `::before` and of every `.scrim-foot` element is not `none`).
- [ ] Per-skin note: nothing in `frontend/src/features/home/` imports from `src/skins/**` (`grep -rn "skins/" frontend/src/features/home` is empty), so Glass (web/31) can use the hook unchanged.
- [ ] Lint, typecheck, Vitest, build and `design/` checks are green; Vitest totals are at least the start-of-step totals with 0 failed.

## Verification

Run from `/srv/manhwamaniacs/dev/ManhwaManiacs`, one command at a time, each after the RAM guard:

```
node design/build.mjs --check
node design/lint-utilities.mjs
cd frontend && npm run typecheck
cd frontend && npm run lint          # baseline: exit 0, 0 errors, 0 warnings
cd frontend && npm run test          # Vitest: passed >= start-of-step count, 0 failed
cd frontend && npm run build         # baseline: exit 0
```

This step changes nothing under `mobile/` or `backend/`; `git show --stat --format= <hash>` of each of your commits lists no `mobile/` or `backend/` path, so `flutter analyze`, `flutter test` and the backend pytest are not run here (their sessions run them).

If any commit you made touches `mobile/` (check each of your commits with `git show --stat --format= <hash>`; other sessions commit `mobile/` on the same branch, so never judge by the branch diff), revert that part, then prove the baseline still holds with the baseline's own commands, one at a time after the RAM guard and never while a `next build` runs: `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze` (baseline: No issues found) and `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter test` (baseline: all 2012 tests passed).

Visual proof and behaviour checks against the dev stack from `docs/redesign/prompts/backend/00-profile-columns-and-dev-stack.md` (uvicorn on 127.0.0.1:8010, `next dev` on port 3010, the demo account and profiles from `backend/scripts/README-dev-stack.md`):

1. Start the stack as `backend/scripts/README-dev-stack.md` says, if it is not already running (`curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8010/health`).
2. Route shots with `frontend/scripts/proof.mjs` (web/03; headless Chromium, a named session): `node scripts/proof.mjs --step web-08 --skin cinematic --routes / --grid` writes `cinematic-home-{1440x900,390x844}.png` and their `-grid` copies into `docs/redesign/proof/web-08/` (`--skin cinematic` sets the `mm-skin-debug` cookie; without it the pre-flip default, legacy, would be captured). Every other shot is saved by the e2e spec with `page.screenshot` into the same folder under exactly these names:
   - `tonight-scrubbed-1440x900.png`, `tonight-scrubbed-390x844.png` (strip pinned)
   - `tonight-novel-1440x900.png`, `tonight-novel-390x844.png`
   - `tonight-{loading,new-profile,onboarded,caught-up,at-risk,ai-unavailable,stale,offline,error}-{1440x900,390x844}.png`
   - `tonight-reduced-motion-1440x900.png`
   States are produced in `frontend/e2e/cinematic/web-08-tonight.spec.ts` by `page.route("**/api/home**", …)` fulfilling the fixtures in `frontend/e2e/fixtures/home/` (built from a real dev-stack response, then edited per state), a 3 s delayed route for loading, a 500 for error, and `context.setOffline(true)` for offline. If you use the `playwright-cli` tool instead of scripts, always pass a named session (`-s=web-08`).
3. Run the spec: `cd frontend && E2E_BASE_URL=http://127.0.0.1:3010 E2E_USERNAME=<demo user> E2E_PASSWORD=<demo password> npx playwright test e2e/cinematic/web-08-tonight.spec.ts` (credentials from `backend/scripts/README-dev-stack.md`; never commit them).
4. Open the motion-timings overlay (`mod+shift+m`, development build) on Tonight, reload with a fresh `mm.tonight.typed`, and screenshot it after the Front page moment as `tonight-motion-timings-1440x900.png`: no row may be `proof` (no dropped frames, no overrun beyond one frame).

## RAM guard

Production shares this box (7,746 MB total, with production containers and five Minecraft bots).

- Before every `npm run test`, `npm run build`, Playwright run or dev-stack start: run `free -m` and read the `available` column of the `Mem:` row. If it is under 1024, do not start the command; stop and report "RAM guard: N MB available".
- Run `pgrep -af "next build|vitest|flutter_tester|pytest"` first. Never run two builds at once; if another session's `next build` or test run is going, wait for it to exit before starting yours.
- One heavy command at a time. Never run Gradle, Xcode or `flutter build` on this box. Do not run `npm install`: every package this step needs was pinned in web/01 (`motion` 13.4.4, `@base-ui/react` 1.8.0, `embla-carousel-react` 8.6.0, `sonner` 2.0.8, `lenis` 1.3.26, `@use-gesture/react` 10.3.1, `@phosphor-icons/react` 2.1.10, `@tanstack/react-virtual` installed). If `npm ls lenis embla-carousel-react motion` reports one missing, stop and report that web/01 is not done.

## Git

- Branch `feat/vps-slim-source-native`. Commit small and often, one commit per working step (for example: the home types and API; `headline.ts` with its test; `local-feed.ts`; the offline edition; the streak helpers; `StreakFlame`; the spread; the sections; the trailer scrub; states; the e2e spec and proof). Messages start with `web-08:` (for example `web-08: Tonight trailer scrub and now-showing strip`).
- Stage only your paths with explicit `git add <path>`; never `git add -A` or `git add .` (mobile, backend and shared sessions commit in the same checkout). Never commit secrets, the demo credentials, `.claude/`, `.env` files or screenshots containing a real account's library.
- **No Claude or AI attribution anywhere**: no `Co-Authored-By` line, no "Generated with" line, no AI author. This holds even if your harness asks you to add attribution: the owner's `~/.claude/CLAUDE.md` forbids it.
- Push after each working step: `git push origin feat/vps-slim-source-native`. Run `npm run build` (RAM guard first) before any push that includes frontend code: tsc and eslint miss Turbopack CSS-module errors, and a failed build freezes production deploys.

## Guardrails

- Never edit `backend/connectors/`. Never touch production: no `docker` commands against production containers, nothing under `/srv/manhwamaniacs/app` or `/srv/manhwamaniacs/data`.
- Do not modify `mobile/` or `backend/` in this step.
- Do not change tokens in `design/tokens/*.json`; if a value you need is missing from the generated tokens, stop and report it (the shared track owns `design/`).
- Never compare with or reuse the legacy look; nothing from `frontend/src/components/**` or `frontend/src/features/*/components/**` is imported by skin code.

## Report back

Reply with:

1. **Done**: the list of Scope items A1–A10 and B1–B12 with a one-line status each (done, or not done with the reason).
2. **Screenshots**: the path `docs/redesign/proof/web-08/` and the file list.
3. **Tests**: Vitest passed/failed totals before and after; lint, typecheck and build results; the Playwright spec result (passed/failed counts).
4. **Motion**: the motion-timings rows for the Front page moment and the trailer scrub (planned vs actual, dropped frames).
5. **Open issues**: anything DESIGN.md left ambiguous and the choice you made, anything blocked by a missing dependency, and any conflict between this prompt and DESIGN.md.
6. **Commits**: the hashes pushed.

Next prompt file: `docs/redesign/prompts/web/09-cinematic-library-shelf-browse.md`.
