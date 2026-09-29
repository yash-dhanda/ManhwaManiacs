# Web Glass AI: For you, Ask, recaps and More like this (new feature 1)

Track: web · Order 100 · Depends on: `docs/redesign/prompts/web/40-glass-you-about-admin-status.md` · Runs in parallel with: `docs/redesign/prompts/mobile/41-glass-ai-for-you-recaps.md` · Proof folder: `docs/redesign/proof/web-41/`

## Goal

Deliver new feature 1 of the owner's decisions (AI home and recommendations, "because you read X", similar series and the "previously on" recap before continuing a series or chapter) on the Glass web skin, exactly as `glass/DESIGN.md` §9.1 specifies, with the external AI always drawn in the **machine light** and always honest about waiting and about being unavailable. Build **For you and Ask** at `/library/recommendations` (ScreenId `picks`, with `?genre=`): the Ask box, example chips, "Only my sources" and "Use my taste", the quota meter, the thinking orbit with its honest phase lines, the **dealt** answer cards, For you and Because you read sections, Not interested and More like this one; the **"Previously on" recaps**: the `mm.recap` modes Off · Ask · Always, the offer sheet that blooms out of Continue, the chapter pill "Previously · 20 s", every explicit entry, the **recap deck** (route `recap`, a sheet over the series, `shape=deck`, `scope=series|chapter`, streaming words, the spoiler-guard footer, the compact chapter recap, keep-alive after close with the "ready" toast, How it works); **More like this** on series detail, the book page and the caught-up end card with the `fallback=genres` rail; and the **§9.1.5 one voice for "unavailable"** on every AI surface. Every state, desktop, tablet and mobile web, keyboard access and reduced motion. When you finish, the ScreenIds `picks` and `recap` leave the Glass `PENDING` set. The AI is called only by the server; the client never talks to an AI provider.

## Read first

Read these completely before planning. `glass/DESIGN.md` is binding; where this file and `glass/DESIGN.md` disagree, `glass/DESIGN.md` wins and you name the conflict in your report.

1. `docs/redesign/inventory/00-decisions.md` (new feature 1: "External AI API only. Design loading and 'AI unavailable' states").
2. `docs/redesign/stack-decision.md` §2.2, §2.6 (AI logic runs on the backend; clients only render).
3. `docs/redesign/glass/DESIGN.md`:
   - **§9 intro and §9.1 in full**: §9.1.1 (the AI card rules you reuse: Not interested, liked pick, the loading orbit), **§9.1.2 For you and Ask**, **§9.1.3 "Previously on" recaps**, **§9.1.4 More like this**, **§9.1.5 AI states**, §9.1.6 (the endpoints and the SSE framing). Read every line.
   - §7.38 (machine light, thinking orbit, phase lines and their timers, AI notice, states), §7.7 (the world title card, the continue stack's "Previously on" entries), §7.8 (press and lift, throw), §7.9 (rails and their AI states), §7.10 (sheets, the `offer` popover, the 560 px window for the recap), §7.11, §7.12 (toasts, Undo), §7.24 (lens glyphs `bubble-search`, `sparkle-slash`), §7.3 (text area), §7.5 (chips), §7.19 (three dots, the liquid capsule).
   - §8.0.3 (rows `picks` and `recap`, the sheet ids `offer` and `how-it-works`), §8.0.6 (keys; `alt+` combinations match on `event.code`), §8.0.8 (content mode: Novels on For you; the 18+ purge steps 1 and 5 for recaps; `ocrEngineAvailable`), §8.0.9 (recaps cancelled on profile switch), §8.0.10 rows `suggest_shelf_empty`, `ai_no_matches`, `ai_budget_exhausted`, `ai_not_configured`, `ai_failed`, `rate_limited`.
   - §8.8 (Home: the spotlight's "Previously on" candidate, Continue with recap offer), §8.12 and §8.13 (the "Previously on" row and the More like this rail placement; the desktop right column order), §8.14 (the manga reader title capsule → series sheet; the caught-up end card), §8.15.6 (the novel Contents sheet's "Previously on" row), §8.23 (Dialogue search's hint row → How it works), §8.25.16 (the setting you read).
   - §2.1.4 (`machine` `#5CE1E6`), §2.1.9 (one light per meaning), §3.2, §4.2, §4.4 (projection), §4.6 (Throw away), §4.7, §4.8, §4.9, §4.10 rows **Deal**, **Quick type**, **Word stream**, **Typing reveal**, **Letter reveal**, **Deck lift-off**, **Bloom**, **Sheet present**, **Surface from depth**, **Thinking orbit**, **Throw**, **Dive**, §4.11.
   - §5.2 events `recap.ready`, `throw.commit`, `undo`, `select`, `toggle.on`, `toggle.off`, `sheet.detent`, `threshold.cross`, `threshold.back`, `reader.enter`, `error`; §6 cues `add`, `throw`, `dive`.
   - §10.1 (placement 6: the For you title), §10.2 (placement 5: the recap deck heading), §11 rows (throw sideways, recap deck swipe), §14.1, §14.4, §14.5 (the recap deck reads as one list with four headings), §15.2 (`copy/ai.ts`; the sheet host for `recap`), §15.5 (`mm.recap`), §15.6 (the recap setting and the recap stream rows).
4. `docs/redesign/inventory/web.md` §7.8 (RC1–RC11) and §18.4 rows A41–A43. Every row must have a Glass counterpart; write the mapping to `docs/redesign/proof/web-41/inventory-map.md`.
5. `docs/redesign/inventory/capabilities.md` §9 (recommendations and AI suggestions), §20 (OCR coverage behind manga recaps).
6. `docs/redesign/00-baseline.md`.
7. `docs/redesign/prompts-plan.json`: the `web/00` entry (its `TRACK RULE`), this entry, and `backend/05` (what the server offers).
8. Code you build on:
   - The backend handlers (read them so the client types match exactly): `grep -rn "ai/recap\|ai/similar\|ai/feedback\|suggest\|world/recommendations" backend/routes`.
   - The shared data layer `web/18` and `web/19` added: `frontend/src/features/recap/{recap-setting,sse,api,hooks,should-open-recap}.ts`, `frontend/src/features/ai/{state,api,hooks}.ts`, `frontend/src/services/http.ts` (`requestStream`), `frontend/src/features/library/{api,hooks}.ts` (`useWorldRecommendations`, `useSuggestAvailability`, `useWorldSuggest`, `useLocalSuggest`, `useGenreWeights`), `features/home/rerank.ts`. Read every export before adding anything.
   - Glass code from `web/25`–`web/40`: `play()` and the motion names, `GlassSurface`, `AmbientField`/`useAmbient`, `Button`, `IconButton`, `TextArea`, `Chip`, `Switch`, `LiquidProgress`, `WorldCard`, `Poster` (lift, throw), `PosterGrid`, `Rail`, `Skeleton`, `Sheet`/`useSheetParam` (with the `popover` desktop form), `Alert`, `showToast`, `Menu`, `ContextMenu`, `ObjectLens`, `ThinkingOrbit`, `AiNotice`, `copy/ai.ts`, `copy/errors.ts`, `LetterReveal`, `TypedHeadline`, `web/29`'s `SheetHost` API (`grep -n "export" frontend/src/skins/glass/Shell.tsx frontend/src/skins/glass/*sheet-host*`), `web/31` Home (spotlight, Continue, AI rails), `web/32` continue stack in Library, `web/33` series detail and book page (the "Previously on" row slot and More like this slot), `web/35` manga reader (title capsule, caught-up end card, top-centre pill slot), `web/36` novel reader (Contents sheet), `web/38` Search (`ask` scope, Dialogue search hint row), `web/39` AI and recaps settings.

## Preconditions (check before writing the plan)

Stop and report which one failed if any of these is false:

- `git branch --show-current` prints `feat/vps-slim-source-native`; `git status --porcelain` noted (never stage other sessions' files).
- `git log --oneline -40` shows the `web/40` commits; `grep -n "picks\|recap" frontend/src/skins/glass/index.ts` shows both ScreenIds still in `PENDING`.
- The backend routes exist: `GET /ai/similar` (with `fallback`), `GET /ai/recap/availability`, `GET /ai/recap` (with `shape` and `scope`), `POST /ai/feedback` (with `clear`), `GET /library/world/recommendations` (with `genre`), `POST /library/suggest` and `POST /library/world/suggest` (with `use_taste`; `content_kind` on the local one).
- `frontend/src/features/recap/recap-setting.ts` exists with the key `mm.recap`.
- `ThinkingOrbit`, `AiNotice` and `copy/ai.ts` exist under `frontend/src/skins/glass/`.
- `node design/build.mjs --check` passes; after the RAM guard, `cd frontend && npm run test 2>&1 | tail -5` gives your Vitest floor (files and cases).

## Skills to invoke

1. `superpowers:writing-plans` before any code: the plan goes to `docs/redesign/proof/web-41/plan.md`, one task per Scope item.
2. `superpowers:test-driven-development` for every pure module in A (Vitest first).
3. `superpowers:subagent-driven-development` to run the plan (or `superpowers:executing-plans` inline). At most 5 implementer subagents (A; B; C1–C4; C5–C10; D–E), each prompt starting with a scope lock naming its files, `model: "opus"` passed explicitly; builds, tests and browsers run one at a time; verify each subagent's work against `git status` and `git diff`, never against its report alone.
4. `frontend-design:frontend-design`, then `impeccable:impeccable` and `taste-skill:taste-skill` on the proof screenshots; a critique never overrides a token, duration, copy string or layout rule `glass/DESIGN.md` fixes.
5. `superpowers:verification-before-completion` before you claim anything is done.

## Ground rules

- **Track rule.** Work in `frontend/` only (plus `docs/redesign/proof/web-41/`); do not edit `design/`, `brand/`, `mobile/` or `backend/`.
- **Skin boundary** (eslint): Glass files import only `@/features/**` (never `@/features/*/components/**`), `@/lib/**`, `@/services/**`, `@/stores/**`, `@/types/**`, `@/config/**`, `@/skins/contract.generated` and `skins/glass/**`.
- **Shared logic in `features/`**, skin-neutral, each module with a Vitest test in the `node` environment. Extensions of `web/19`'s modules must keep Cinematic's calls unchanged (defaults `shape=prose`, `use_taste` omitted).
- **The AI stays server-side.** Branch on the error `code`, never on the HTTP status (429 is both `ai_budget_exhausted` and `rate_limited`); only `rate_limited` starts the automatic `Retry-After` retry.
- **Paths** from `ROUTES` in `frontend/src/skins/contract.generated.ts`; every named move through `play()`.
- **Copy** verbatim from `glass/DESIGN.md`; AI reasons from `copy/ai.ts`, errors from `copy/errors.ts`.
- Never edit `backend/connectors/`; never touch production containers or `/srv/manhwamaniacs/{app,data}`.

## Scope: deliver every item below

Sections cited are `glass/DESIGN.md`. Every AI-written line is led by the `sparkle` glyph (Regular 14, Fill when final) in `machine` `#5CE1E6`, and its accessible name ends ", suggested by AI". AI cards carry the 0.5 px `machineRim` `rgba(92,225,230,0.45)` instead of `slabBorder`.

### A. Shared data-layer extensions (skin-neutral, Vitest-tested)

1. `features/library/api.ts` and `hooks.ts`: `librarySuggest({ prompt, limit, use_taste, content_kind })` → `POST /library/suggest` (Glass sends `limit: 8`, `use_taste`, and `content_kind: "novel"` in Novels mode), `worldSuggest({ prompt, limit, use_taste })` → `POST /library/world/suggest` (Glass sends `limit: 12`), and `worldRecommendations({ genre })` → `GET /library/world/recommendations?genre=` (query key includes the genre). Omitted fields are not sent, so Cinematic's calls are unchanged. Test the request builders.
2. `features/recap/api.ts`: `openRecap({ source, series, to, shape, scope, signal })`; `shape` defaults to `"prose"` and is sent only when `"deck"`; `scope` (`"series" | "chapter"`) sent only with `shape: "deck"`. Keep the JSON "no stream" answer (`{ kind: "none", reason, retryAfter }`).
3. `features/recap/deck.ts`: `deckReducer(state, event)` over the deck stream: `phase` `{phase}` → `state.phase`; `section` `{kind: "left_off" | "happened" | "cast" | "threads" | "last_time", title}` → a section in arrival order; `delta` `{kind, text}` → appended to that section's text (and to a per-section `words` array split on spaces, for the word fade); `done` `{range: [from, to], covered_through, cast: [{name, note}], sourced_from, model, generated_at, available, reason}` → `state.done`; `error` `{code, message}` → `state.error`. Helpers: `sectionBullets(text)` (split on `\n` when present, else on sentence ends `/(?<=[.!?])\s+/`, empty items dropped); `lastThirdStart(chapterKeys)` → `chapterKeys[Math.floor(n × 2 / 3)]` for the "Start from Ch … instead" button; `gapWords(days)` → "3 days" (under 14), "3 weeks" (under 9 weeks, i.e. under 63 days), "3 months" (after; months = `Math.round(days / 30)`), singular forms "1 day", "1 week", "1 month". Tests: events split across chunks (through `sse.ts`), deltas for two sections interleaved, `done` without `cast`, the three gap forms and their boundaries (13, 14, 62, 63 days), `lastThirdStart` for 1, 3 and 22 chapters.
4. `features/recap/should-open-recap.ts` (extend `web/19`'s module, keeping its functions): `recapEntryDecision({ setting, seriesId, lastReadAt, now, available })` → `"offer" | "open" | "none"`: `none` when `mode` is `off`, `seriesId` is in `skipSeries`, the series was never read, or `available` is false; with `ask`, `offer` when the gap is at least `seriesDays` (7) days; with `always`, `open` when the gap is at least `seriesDays` days; else `none`. `chapterPillDecision({ setting, lastReadAt, now, seriesDecision, seriesDeclined })` → `true` when `mode` is not `off`, the gap is at least `chapterDays` (3) days, and either the gap is below `seriesDays` or `seriesDeclined` is true. Tests for every branch at local-day boundaries.
5. `features/recap/background-recaps.ts`: `keepRecapAlive(key, { controller, title, sourceId, seriesKey, mature }, onReady)`: holds a closed sheet's running request for up to 60 s from the request start (`setTimeout` abort after the remainder), calls `onReady(key)` when `done` arrives, and exposes `cancelRecaps(predicate)` for the profile switch (all) and the 18+ purge (`mature: true`). Register `cancelRecaps` with the shared purge and the profile-switch flow `web/29` built (`grep -rn "purgeMatureLocal" frontend/src`). Test with fake timers: ready inside 60 s calls back once; after 60 s the request aborts; cancel drops it.
6. `features/recap/recap-cache.ts`: a finished deck is saved in profile-scoped `localStorage` (`lib/scoped-storage.ts`) under `mm.recap.cache` as `{ "{source}:{series}:{to}:{scope}": { sections, done, savedAt } }`, at most 20 entries (least recently opened evicted); `readCachedRecap(key)`; the §8.0.8 purge deletes the whole key (cached recap payloads are deleted outright, never refetched offline). Test the LRU and the round trip.
7. `features/ai/api.ts`: `aiFeedback` accepts `signal: "undo" | "clear"` beside `web/19`'s signals (Cinematic never sends them); `aiSimilar(…, { fallback: "genres" })` returns items with `why: null, basis: "genres"`. Test the bodies.
8. `features/ai/ask-draft.ts`: `writeAskDraft(text)` / `takeAskDraft()` over `sessionStorage['mm.glass.askDraft']` (one-shot), so Search's `ask` scope hands its text to For you. Test.

### B. For you and Ask (`frontend/src/skins/glass/screens/picks/`, ScreenId `picks`, §9.1.2)

Wire `screens.picks` to `ForYouScreen`; remove `picks` from `PENDING`. `document.title` "For you · ManhwaManiacs". Phone: pushed page; desktop: page with the sidebar "For you" (child of Home) active. Data: `useSuggestAvailability()`, `useWorldRecommendations`/`worldRecommendations({ genre })`, `useGenreWeights()`, the A1 suggest mutations, the content-mode store, `useAiFeedback()`, `useDismissedPicks()`.

1. **Title:** large title "What do you feel like?" (`LetterReveal`, §10.1 placement 6, once per session).
2. **Genre filter** (`?genre=`): a dismissible `Chip` "Fantasy ×" under the title; For you and Because you read then come from `worldRecommendations({ genre })`; clearing drops the parameter with `router.replace` (scroll kept). Empty: "No picks in Fantasy yet" + a plain "Clear the filter".
3. **Ask box** (only while AI is available; otherwise item 10's notice replaces it): a content-layer `TextArea`, 3 rows growing to 6, 3 to 600 characters (a `mono` 13 counter "12 / 600" trailing under it), placeholder "A revenge story with a competent lead, no harem", whose 0.5 px rim turns `machineRim` while focused or thinking (`colorShift` 240 ms). Enter asks, Shift+Enter inserts a newline (the field's own handler, not the registry).
4. **Example chips:** "A murim regressor who comes back stronger", "Magic academy, but the lead is already strong", "Something slow and political, not a power fantasy"; a tap fills the box and asks; `alt+1` to `alt+3` (matched on `event.code` `Digit1`–`Digit3`) do the same.
5. **Controls:** the tinted **Ask** button (the screen's one lit action, `Caustic`; three-dot loading while asking; disabled until 3 characters); the switch **"Only my sources"** (default off, kept for the visit only: on → `librarySuggest` with `limit: 8`; off → `worldSuggest` with `limit: 12`); in Novels mode this switch is hidden and every ask is local with `content_kind: "novel"`; the switch **"Use my taste"** (default on → `use_taste: true`; off → `false`); the **quota meter** shown when `remaining_today` ≤ 10: a 72 × 8 px `LiquidProgress` capsule plus "7 of 10 asks left today" in `caption1`, both `warning` at 3 or fewer; it refreshes after every answer.
6. **Asking:** under the box, the 64 px `ThinkingOrbit` with its honest phase lines on the §7.38 timers (these endpoints report no phases): "Reading your library" (0 s), "Asking for ideas" (1.5 s), "Checking which of your sources have them" (4 s), "Still working. This can take up to a minute." (15 s); each line to the polite live region; a plain "Cancel" aborts the request (`AbortController`); after 40 s the request is abandoned: "That took too long. Try again." + "Try again". The rest of the screen stays usable. If `ThinkingOrbit` has no phase-timer support, add `thinking-phases.ts` (pure, with a test) beside it in `primitives/`.
7. **Deal (signature):** answer cards fly out of the Ask button's centre along a short arc (control point 80 px above the straight line) into their slots, each landing on `snappy` (k 246.7, c 26.70) with 40 ms spacing (`play("Deal")`); each card's `why` line types in at 12 ms per character (`play("Quick type")`). Arrival announces "8 picks ready" (or "Some picks didn't come through." for a partial answer). Reduced motion: the cards fade in together over 150 ms and the `why` lines show whole.
8. **Answer cards** (wide): poster 96 × 144 at left (radius 14); right: title `headline` (2 lines), meta `caption1` `label2` ("Manhwa · Ongoing"), the `why` in `callout` after the sparkle, the availability chip ("On MangaSource +2", or "Not on your sources"), actions Open (available; a source picker `Menu` when several sources have it) / "Search my sources" (→ `ROUTES.discover` with `?q={title}`) / "Read on {site}" (external; `window.open(url, "_blank", "noopener,noreferrer")`, a `null` result toasts "Couldn't open {site}"). A plain "Show as grid" switches the answers to a `PosterGrid` (and "Show as list" back); "Ask again" (secondary) sits under the list and re-sends the kept prompt. Phone: one column; desktop: a two-column list, the box max 720 px wide.
9. **Not interested and liked pick** on every AI card here: throw a lifted card sideways (projection past a side edge or |vx| ≥ 1,200 px/s; the card flies off on `dismiss` with its velocity and spins up to 12° in the throw direction; `throw.commit`; the list closes the gap on `snappy`), or ⋯ → "Not interested", or `Delete`/`Backspace` on a focused card → `aiFeedback({ signal: "not_interested", … })`, toast "We'll show fewer like this · Undo" (10 s, draining rim; Undo sends `signal: "undo"` and the card returns on `snappy`). ⋯ → "More like this one" sends `signal: "liked_pick"` and: for an available card, opens its series sheet scrolled to its More like this rail (`#more-like-this`); for an info-only card (AniList id only), inserts up to 3 cards from `aiSimilar({ anilistId })` right after it, surfacing from depth (`play("Surface from depth")`), and nothing when the call returns none.
10. **States** (§9.1.2): available idle; thinking; results (up to 8 local, 12 worldwide); **no matches** (`ai_no_matches`: "Nothing matched that. Try describing it differently." with the prompt kept); **empty shelf** (`suggest_shelf_empty`: "Read or follow a few series first. Picks here start from what you read." + "Browse sources"); **not configured**, **budget exhausted** (with the reset time and a live countdown to 00:00 UTC), **rate limited** (the button counts down "Try again in 12 s"), **offline**, **upstream error**: the Ask box is replaced by the `AiNotice` with the reason's long line (admins also see "Add an AI API key on the server to turn it on." under `not_configured`), and the sections below still work; **world catalogue unreachable** (`unavailable_reason`: "The worldwide catalogue isn't reachable, so these picks come from a saved copy."); **timeout** (item 6); **loading sections** (6 skeleton cards per section; skeleton sheen at half speed, 2,800 ms); **stale** ("Picked 3 days ago" beside a section title when `generated_at` is older than 24 h).
11. **For you** and **Because you read {title}** sections (`title2` headers with `LetterReveal` on first view, the sparkle subtitle "Because you read Solo Leveling"): phone vertical `WorldCard` lists; desktop grids `grid-template-columns: repeat(auto-fill, minmax(300px, 1fr))`, 20 px gaps (2 to 3 columns). Items dismissed this session (`useDismissedPicks`) are gone here and on Home. In Novels mode the worldwide sections are replaced by the note "Worldwide picks cover manga, manhwa and manhua." (`footnote` `label2`).
12. **Entry points to verify or add** (each file named by grep, one line each): Home "See all" on AI rails and the Home ⋯ menu (`web/31`); the Search idle "Ask" card and the `ask` scope (`web/38`): submitting writes `writeAskDraft(text)` and navigates to `ROUTES.picks`, where `takeAskDraft()` fills the box and asks once; the sidebar "For you" (`web/29`); the command palette action "Ask for something to read" (`web/29`; add it if missing); You → For you (`web/40`); `g f` (global).
13. **Pull to refresh** (touch) refetches `GET /library/world/recommendations` and `GET /library/suggest/availability`, never re-asking the AI; `r` on desktop.
14. **Keys** (group "For you"): `/` focuses the box, Enter asks, Esc cancels a running ask, `alt+1`–`alt+3` fill an example, `j`/`k` or arrows through answers (roving focus), `.` item menu, `Delete` = Not interested on a focused AI card.

### C. "Previously on" recaps (§9.1.3)

The setting is read from `mm.recap` (`useRecapSetting()`): **Off · Ask (default) · Always**, `seriesDays` 7, `chapterDays` 3, `skipSeries`. Availability comes from `useRecapAvailability` (`GET /ai/recap/availability`); `reason: "first_chapter"` shows no entry anywhere.

1. **One Continue path.** `frontend/src/skins/glass/parts/recap/useContinue.ts`: `continueSeries(item, originEl)` applies `recapEntryDecision`: `offer` → the offer sheet (C2) anchored to `originEl`; `open` → the recap route (C4) with `?to=` the continue chapter; `none` → the Dive into the reader. Route every Glass Continue through it: Home spotlight and continue stacks (`web/31`), Library continue stack (`web/32`), series detail and book page primary (`web/33`), the bottom accessory and the desktop accessory (`web/29`). List the call sites in the report (`grep -rn "Continue" frontend/src/skins/glass/screens frontend/src/skins/glass/Shell.tsx`).
2. **Offer** (`?sheet=offer`): a T4 `glassThick` sheet at `medium` blooming (`morph`) out of the Continue button on phones; on desktop the 420 px popover anchored to that button (`web/27`'s `popover` form). Content: "It's been 3 weeks" (`title3`, `gapWords`), "Want a quick recap of what happened?" (`callout` `onGlass`), the tinted "Show recap" (→ C4, replacing the offer), the plain "Just continue" (→ the Dive), and the `Switch` "Don't ask for this series" (adds `"{sourceId}:{seriesKey}"` to `skipSeries`; the offer closes and continues). Esc, an outside click and browser back close it without continuing.
3. **Chapter pill** (both readers): when the next chapter opens and `chapterPillDecision` is true (and the series offer was not just shown), a `glassThin` pill at the top-centre of the reader "Previously · 20 s" (machine sparkle, `caption1` 600; the seconds from the availability's `est_seconds`) shows for 6 s (it still leaves after 6 s under reduced motion); a tap opens the compact recap (C4 with `scope=chapter`); a swipe up (projection past 24 px) dismisses it. Place it in `web/35`'s and `web/36`'s top-centre pill slot; it counts as the pill in the reader's live-surface budget.
4. **The recap deck** (route `recap`, `/recap/:sourceId/:seriesKey?to=:chapterKey`, `&scope=chapter` for the compact form): a `SheetHost` sheet route over the series detail (`medium` → `large`; desktop the 560 px window); a hard load renders the series page with the recap sheet over it. The ambient field takes the series palette.
   - **Header:** the eyebrow "PREVIOUSLY ON" (`caption1`, uppercase, +0.18 em, `machine`, with the sparkle) and the heading "Previously on Solo Leveling" with the **typing reveal** (`TypedHeadline`, §10.2 placement 5, 50 ms per grapheme, the `iris400` capsule caret); a refresh `IconButton` ("Write it again"; costs one ask; disabled with the reason as its tooltip when the budget is spent). If the backend handler has no cache-bypass parameter (read it), do not render the refresh button and list that under open issues.
   - **The deck:** four cards stacked in depth: the front card 88 % of the sheet width, radius 26, `surface1` with the 0.5 px `machineRim`; the next two visible above it, each 8 px higher, at scale 0.94 and 0.89 and brightness 60 % and 40 %. Cards: (1) **Where you left off** (2–3 sentences); (2) **What happened** (`sectionBullets`, 4–6 bullets with a `droplet` marker); (3) **Who's who** (up to 6 rows from `done.cast`: a 24 px orb in the character's speaker hue from the book's cast for novels, matched by name case-insensitively against the novel cast hook `web/37` uses, else `g700`; name `headline`; the note `footnote`); (4) **Open threads** (2–3 questions). A row of four progress capsules sits above the deck.
   - **Navigation:** swipe up, a tap on the right half, `→` or Space lift the front card toward the viewer and away upward (scale 1 → 1.06, translateY −40 px, on `smooth`, k 157.9, c 22.62; `play("Deck lift-off")`), revealing the next rising from 0.94; swipe down, the left half or `←` bring it back. With Screen reader mode on (`data-sr="on"`), the four cards render as one scrolling list with four `h3` headings.
   - **Streaming:** `openRecap({ shape: "deck", scope })` through `deckReducer`; section titles arrive first and the deck appears with skeleton lines that fill from the top; each word fades in over 120 ms (`fadeIn`, no movement; `play("Word stream")`). The 50 ms typing is reserved for the heading. While writing: the 64 px orbit and "Writing your recap".
   - **Footer (spoiler guard):** `footnote` `label3` (`onGlass` in the desktop window) with the sparkle: "Written by {model} from chapters 120–141. Covers up to chapter 141. Nothing after where you stopped." (from `done`); a cached recap adds "Written 2 d ago".
   - **Actions** (sticky at the bottom on phones): the tinted "Continue · Ch 142, p. 12" (the Dive into the reader at the saved page), the secondary "Start from Ch 138 instead" (`lastThirdStart` of the covered range).
   - **Compact recap** (`scope=chapter`, from the pill): `medium`, one card "Last time" (3–4 sentences) + "Continue"; the same footer.
5. **Leaving during generation:** closing the sheet while writing hands the request to `keepRecapAlive` (60 s from the request start); when it lands, a toast anywhere in the app "Recap for Solo Leveling is ready" + "Open" (`recap.ready` haptic, `add` sound when UI sounds are on); the recap is saved in `recap-cache.ts`. A profile switch or the 18+ purge cancels it and the toast never shows.
6. **States:** writing; ready (cached: instant, "Written 2 d ago"); **no source text** (manga without extracted dialogue: the object lens `bubble-search` over a `machineWash` pool, "No recap yet" / "Recaps are written from chapter text. Extract text from downloaded chapters, or just continue." + the tinted "Continue" + the plain "How it works"; the web never shows "Extract text"); **not enough read** ("Read a couple of chapters first; there's nothing to recap yet." + "Continue"); **AI unavailable** (`AiNotice` with the long line + "Continue"; the recap is skipped); **offline** (a cached recap opens with "Saved recap from 2 d ago"; otherwise "Recaps need a connection." + "Continue"); **error** ("Couldn't write a recap." + "Try again" + "Continue"); **first chapter** (no entry anywhere).
7. **Explicit entries** (each opens C4, or C2 when that entry is a Continue): the continue stack's long-press context menu first row "Previously on", its trailing ⋯ (a 44 px hit on its top-right corner) and `p` on a focused stack (`web/31`, `web/32`); series detail ⋯ "Previously on" and the "Previously on" row above the chapters when the profile has progress (`web/33`, the book page too); the Home spotlight's "Previously on" candidate (a series paused 7 days or more, "Previously on" as its secondary action; `web/31`); long-press any Continue button → "Recap first"; `p` on a focused series anywhere; the manga reader's title capsule → series sheet → its "Previously on" row (`web/35`); the novel reader's Contents sheet "Previously on" row at the top when the profile has progress in the book (`web/36`).
8. **How it works** (`?sheet=how-it-works`, `medium`; desktop the 560 px window; also linked from Dialogue search's hint row, `web/38`): title "How recaps and dialogue search read manga"; three rows, each a 30 px icon tile and two lines: `cloud-arrow-down` "Download the chapter" / "Text is read from pages saved on this phone."; `bubble-search` "Extract text" / "Extract text on the phone app" (the web variant); `sparkle` (in `machine`) "Recaps and dialogue search use it" / "Recaps are written from these words, and you can search what characters said."; only the plain "Close" (the web has no "Open downloads"). No states.
9. **Keys** (group "Recap"): Space / `→` next card, `←` previous, Enter continue reading, `s` skip to the reader, `r` write it again, Esc closes; `p` opens a recap from a focused series or continue stack (group "Library" and "Home").
10. **Reduced motion:** the heading appears at once; cards cross-fade over 150 ms instead of lifting; words appear without the fade; the offer and the sheet fade + 16 px over 150 ms.

### D. More like this (§9.1.4)

1. `frontend/src/skins/glass/parts/ai/MoreLikeThisRail.tsx`: a `Rail` (header `title2` "More like {title}", id `more-like-this` for the anchor) of up to 10 `WorldCard`s from `aiSimilar({ source, series })`, each with its `why` line. Loading: the rail skeleton with the 28 px `ThinkingOrbit` beside the title. Empty: the rail is omitted. AI unavailable: the rail reloads with `fallback: "genres"`; items carry `why: null, basis: "genres"`, the rail's subtitle reads "Same genres" with no sparkle and the cards carry no `machineRim`; with fewer than 3 such items the rail is omitted.
2. Place it at the bottom of series detail and the book page (`web/33`; on the desktop window in the right column after Circle, before Chapters) and on the manga reader's caught-up end card (`web/35`). Replace any placeholder those steps left.
3. The AI card behaviours of B9 apply to these cards (Not interested, More like this one).

### E. AI states and one voice (§9.1.5, §7.38)

1. Every AI surface (Home AI rails, For you, recaps, More like this, onboarding step 6) is in one of thinking, ready, stale, partial or unavailable, decided by `features/ai/state.ts` (`web/19`), and when unavailable says exactly one line from `copy/ai.ts`: short for rails and badges, long for For you, recaps and More like this. Verify each surface built in `web/30`, `web/31` and `web/33` uses `copy/ai.ts` and `AiNotice` (`grep -rn "AI picks\|AI isn't" frontend/src/skins/glass` must find the strings only in `copy/ai.ts`); fix any duplicate string.
2. The 18+ gate: AI payloads are gated by the server; the client adds nothing, and on gate close the purge drops cached recaps (A6) and cancels background ones (A5).

## Out of scope here (do not build)

- Home's AI rails and spotlight (built by `web/31`; only the entry wiring of C1, C7 and B12 changes them), the AI and recaps settings (`web/39`), onboarding step 6 (`web/30`), Statistics, Wrapped and the Circle (`web/42`, `web/43`); any change under `mobile/`, `backend/`, `design/`, `brand/`.

## File layout

```
frontend/src/features/library/{api,hooks}.ts (+ tests)                          A1
frontend/src/features/recap/{api,deck,should-open-recap,background-recaps,recap-cache}.ts (+ tests)   A2–A6
frontend/src/features/ai/{api,ask-draft}.ts (+ tests)                           A7, A8
frontend/src/skins/glass/index.ts                                               picks and recap out of PENDING
frontend/src/skins/glass/screens/picks/{ForYouScreen,AskBox,AskControls,AnswerList,DealLayer,ForYouSections,GenreFilterChip}.tsx   B
frontend/src/skins/glass/screens/recap/{RecapSheet,RecapDeck,DeckCard,RecapFooter,CompactRecap,RecapStates}.tsx   C4–C6
frontend/src/skins/glass/parts/recap/{useContinue.ts,OfferSheet.tsx,ChapterPill.tsx,HowItWorksSheet.tsx}   C1–C3, C8
frontend/src/skins/glass/parts/ai/{MoreLikeThisRail.tsx,useNotInterested.ts}      D, B9
frontend/src/skins/glass/primitives/thinking-phases.ts (+ test)                 only if ThinkingOrbit lacks the timers
frontend/src/skins/glass/screens/{home,library,series,reader,novel,search}/…    only the entry wiring of B12, C1, C3, C7, D2
frontend/e2e/glass-ai.spec.ts
frontend/e2e/fixtures/glass-ai/{availability-*.json, world-recs*.json, suggest-*.json, recap-deck.sse, recap-chapter.sse, similar*.json}
docs/redesign/proof/web-41/                                                     plan.md, inventory-map.md, screenshots, report.md
```

Follow the folder names `web/31`–`web/40` used if they differ. No CSS modules.

## Values you need (copied from `glass/DESIGN.md`)

| What | Value | Section |
|---|---|---|
| Machine light | `machine` `#5CE1E6`, `machineWash` `rgba(92,225,230,0.14)`, `machineRim` `rgba(92,225,230,0.45)` (0.5 px) | §2.1.4, §2.1.9 |
| Accent and labels | `iris400` `#A99BFF`, `iris500` `#8F7EFF`, `iris600` `#7563F2`, `label1` `#F2F2F7`, `label2` `rgba(235,235,245,0.64)`, `label3` `rgba(235,235,245,0.52)`, `onGlass` `#F2F2F7`, `g700` `#9A9AA4`, `surface1` `#131317`, `warning` `#FFB547` | §2.1.1–§2.1.4 |
| Thinking orbit | 28 px (dots 4 / 3 / 2) or 64 px (dots 8 / 6 / 4), ellipse rx 24 ry 9 at 64 px, tilt 12°, one revolution per 1,400 ms; near dot 1.2 × full brightness, far 0.8 × at 0.4; reduced: dots pulse 0.4 ↔ 1 over 1.2 s | §7.38 |
| Phase timers | 0 s, 1.5 s, 4 s, 15 s; abandon at 40 s (recap keep-alive 60 s after close) | §7.38, §9.1.3 |
| Springs (k, c) | `snappy` 246.7 / 26.70, `morph` 273.4 / 24.80, `smooth` 157.9 / 22.62, `sheet` 171.3 / 24.09, `sheetSnap` 223.8 / 26.33, `dismiss` 385.5 / 39.27, `zoom` 125.9 / 21.09, `tick` 584.0 / 33.83, `track` 1754.6 / 72.05, `letter` 219.6 / 26.08 | §4.2 |
| Timed | `fadeIn` 180 ms `cubic-bezier(0.2,0,0,1)`, `colorShift` 240 ms, word fade 120 ms, `caretBlink` 530 ms, `dematerialize` 350 ms, reduced 150 ms (in page, sheets) / 200 ms (routes) | §4.7, §4.10 |
| Deal | 40 ms spacing, `snappy` landing, `why` at 12 ms per character | §4.10 |
| Typing reveal | 50 ms per grapheme, fade 40 ms, scale 0.8 → 1 on `tick`; caret 2 × 0.72 em `iris400`, 1 px white core, glow `0 0 6px rgba(169,155,255,0.45)`, 3 blinks, cap 48 graphemes | §10.2 |
| Letter reveal | 24 ms stagger, +0.40 em and blur 12 px → 0 on `letter`, scale 0.96 → 1, glint 500 ms | §10.1 |
| Deck | front 88 % width, radius 26; behind: +8 px up each, scale 0.94 / 0.89, brightness 60 % / 40 %; lift scale 1 → 1.06, −40 px on `smooth` | §9.1.3, §4.10 |
| Throw away | projection past a side edge or \|vx\| ≥ 1,200 px/s; `dismiss` with velocity; spin ≤ 12° | §4.6, §9.1.1 |
| Sheets | `medium` 52 % height, `large` = height − safe-top − 10; web radius 36; desktop window 560 px radius 32; offer popover 420 px T4 | §7.10 |
| World card | 300 × 132, cover 80 × 120, title `headline`, meta `caption1`, "120 ch · ★ 8.4" `mono` 13, why `footnote` italic `label2` | §7.7 |
| Type | `largeTitle` 34/40 · 36/42 · 40/46 · 44/50 w700; `title2` 22/28 · 22/28 · 24/30 · 26/32 w650; `title3` 20/25 · 20/25 · 20/26 · 22/28; `headline` 17/22 · 16/22 w600; `callout` 16/22 · 15/22; `footnote` 13/18; `caption1` 12/16 w520 | §3.2 |

## Acceptance criteria

- [ ] `picks` and `recap` are out of the Glass `PENDING` set; the completeness test passes; `inventory-map.md` maps RC1–RC11 and A41–A43.
- [ ] Ask: 3–600 characters with the counter, Enter asks and Shift+Enter breaks a line, the examples fill and ask (tap and `alt+1`–`alt+3`), "Only my sources" switches between `POST /library/suggest` (`limit: 8`) and `POST /library/world/suggest` (`limit: 12`), "Use my taste" sends `use_taste` true/false, Novels mode hides the switch and sends `content_kind: "novel"` (the spec reads the request bodies), the quota meter shows at ≤ 10 and turns `warning` at ≤ 3.
- [ ] Thinking: the 64 px orbit with the four phase lines at 0 / 1.5 / 4 / 15 s (checked with `page.clock`), Cancel aborts, the 40 s timeout copy, and the rest of the screen stays interactive while asking.
- [ ] Deal: answer cards start at the Ask button's rect and land in their slots 40 ms apart (the spec reads each card's first-frame transform), `why` lines type at 12 ms per character, and reduced motion fades them in together.
- [ ] Not interested: a sideways throw, ⋯ and `Delete` each post `not_interested`, show the Undo toast, and Undo posts `undo` and restores the card; "More like this one" posts `liked_pick`.
- [ ] `?genre=Fantasy` shows the chip, requests `GET /library/world/recommendations?genre=Fantasy`, and clearing it drops the parameter; the empty-genre state renders.
- [ ] Every For you state renders from fixtures: no matches, empty shelf, not configured (admin line visible only for admins), budget exhausted with the countdown to 00:00 UTC, rate limited with the button countdown and the automatic retry, offline, upstream error, world catalogue unreachable, timeout, loading, stale.
- [ ] Recap entry: with `mode: "ask"` and a 21-day gap, Continue blooms the offer ("It's been 3 weeks"); "Don't ask for this series" writes `skipSeries`; with `always` the recap opens first; with `off` Continue dives straight in; the chapter pill appears after a 4-day gap for 6 s and opens the compact recap; `first_chapter` shows no entry.
- [ ] Deck: the typed heading, four stacked cards with the 0.94 / 0.89 depth, words fading in as SSE deltas arrive (fixture stream through `page.route`), swipe up / right-half tap / `→` / Space lift the front card, the footer quotes `model` and `covered_through`, Continue and "Start from Ch … instead" dive into the right chapter, and with `data-sr="on"` the deck is one list with four headings.
- [ ] Closing the sheet mid-stream then waiting shows "Recap for … is ready" with Open inside 60 s; a profile switch during that window suppresses it.
- [ ] Recap states: no source text (no "Extract text" on the web), not enough read, AI unavailable, offline with and without a cached recap, error; How it works shows the web copy.
- [ ] More like this: the rail on series detail, the book page and the caught-up end card; the `fallback=genres` rail reads "Same genres" with no sparkle; fewer than 3 items omit it.
- [ ] `copy/ai.ts` is the only file holding the §9.1.5 lines (grep check in the spec's setup or a Vitest).
- [ ] Keyboard: every control reachable by Tab with the two-tone ring; the For you and Recap key groups appear in the `?` sheet; Esc cancels a running ask; no single-key binding fires while typing in the Ask box.
- [ ] Hit targets: every interactive element in `main`, the offer, the deck sheet and How it works is at least 44 × 44 px at 390 × 844 with 8 px spacing.
- [ ] Reduced motion (`emulateMedia` and `data-motion="reduced"`): no Deal flight, no typing caret, no card lift (150 ms cross-fades), words without fade, the orbit's dots pulse in place.
- [ ] Per-skin difference: nothing under `frontend/src/skins/cinematic/` changed, and Cinematic's recap still streams `shape=prose` (the spec loads the Cinematic recap route with `mm-skin-debug=cinematic` and checks the request has no `shape` parameter).
- [ ] `npm run typecheck`, `npm run lint` (0/0), `npm run test` (at or above the floor, 0 failed), `npm run build` (0/0) and `node design/build.mjs --check` are green; `glass-ai.spec.ts` passes and the earlier Glass specs still pass.

## Verification

**RAM guard (production shares this box).** Before every `npm run test`, `npm run build`, `next dev`, Playwright run or dev-stack start: `free -m`, read the `available` column of `Mem:`; under 1024 MB do not start; stop and report "RAM guard: N MB available". `pgrep -af "next build|next dev|vitest|flutter_tester|pytest"` first; never two builds at once; never `next build` while `next dev` or a browser runs. No `npm install`.

From the repository root, one at a time, each after the RAM guard:

```bash
node design/build.mjs --check
cd frontend && npm run typecheck
cd frontend && npm run lint          # baseline: exit 0, 0 errors, 0 warnings
cd frontend && npm run test          # passed >= the floor, 0 failed
cd frontend && npm run build         # baseline: exit 0, 0 errors, 0 warnings (stop next dev first)
```

Browser checks against the dev stack (`backend/scripts/README-dev-stack.md` holds the credentials; never commit them):

1. `curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8010/health` → `200`, else `backend/scripts/dev_stack.sh start`. The dev stack has no AI key, so live calls answer `not_configured`: use that for the live unavailable path and `page.route` fixtures for everything else.
2. `cd frontend && NEXT_PUBLIC_API_URL=/api BACKEND_INTERNAL_URL=http://127.0.0.1:8010 npx next dev -p 3010`.
3. `cd frontend && E2E_BASE_URL=http://127.0.0.1:3010 E2E_USERNAME=demo E2E_PASSWORD=<from the README> npx playwright test e2e/glass-ai.spec.ts --workers=1` (cookie `mm-skin-debug=glass`; `page.route("**/api/library/suggest**")`, `**/api/library/world/**`, `**/api/ai/recap**` (an SSE body from `recap-deck.sse` served with `content-type: text/event-stream` in chunks), `**/api/ai/similar**`, `**/api/ai/feedback`; `page.clock` for the phase timers, the 40 s timeout, the 60 s keep-alive and the recap gaps; `context.setOffline(true)` for offline). Re-run `glass-primitives.spec.ts`, `glass-overlays.spec.ts` and `glass-you-admin-status.spec.ts`.

**Visual proof** with `frontend/scripts/proof.mjs` (`node scripts/proof.mjs --help` first) in the named session `web-41`, headless Chromium, skin `glass`, at 1440 × 900 and 390 × 844 (touch at the phone size), into `docs/redesign/proof/web-41/`, each at both sizes: `for-you-idle`, `for-you-thinking` (the 4 s phase), `for-you-deal` (mid-flight), `for-you-results`, `for-you-grid`, `for-you-genre`, `for-you-no-matches`, `for-you-budget`, `for-you-not-configured`, `for-you-offline`, `for-you-novels`, `offer` (phone sheet and desktop popover), `recap-writing`, `recap-deck-card1`, `recap-deck-card3`, `recap-lift` (mid-lift), `recap-compact`, `recap-no-source-text`, `recap-unavailable`, `recap-offline-cached`, `recap-ready-toast`, `how-it-works`, `chapter-pill` (in the manga reader), `more-like-this`, `more-like-this-genres`; plus `for-you-reduced-motion-phone.png` and `recap-sr-list-desktop.png`. With `playwright-cli`, pass `-s=web-41`. Capture `motion-timings-1440x900.png` after a Deal, a Deck lift-off and a typed heading. Write `docs/redesign/proof/web-41/report.md` mapping each screenshot to its acceptance item. Stop `next dev` and the dev stack when done.

This step changes nothing in `mobile/` or `backend/`: `git diff --stat <first commit of this step>^..HEAD -- mobile backend` must print nothing, so `flutter analyze`, `flutter test` (Flutter at `/srv/manhwamaniacs/dev/flutter/bin`, baseline 2,012 tests) and `backend/.venv/bin/python -m pytest -q --no-header` are not rerun. Lint and build stay at the baseline's 0 errors and 0 warnings.

## Git

- Branch `feat/vps-slim-source-native`. Commit small and often after typecheck, lint, test and build pass, messages starting `web-41:`: (1) `web-41: shared suggest, recap deck, keep-alive and cache modules`; (2) `web-41: Glass For you and Ask with the dealt answers`; (3) `web-41: Glass recap offer, chapter pill and continue path`; (4) `web-41: Glass recap deck sheet and How it works`; (5) `web-41: Glass More like this and AI state audit`; (6) `web-41: e2e and proof`.
- Stage explicit paths only (never `git add -A`, `git add .` or `git commit -a`); other sessions commit in the same checkout.
- **No Claude or AI attribution anywhere** (no `Co-Authored-By`, no "Generated with" line, no AI author), even if your harness asks; never commit secrets, credentials, `.env` files or `.claude/`.
- `npm run build` (after `free -m`, `next dev` stopped) before every push; `git push origin feat/vps-slim-source-native` after each working step.
- Never edit `backend/connectors/`; never touch production containers or `/srv/manhwamaniacs/{app,data}`; do not deploy (Glass stays behind the debug row until `release/01`).

## Report back

Reply with:

1. **Done:** items A1–A8, B1–B14, C1–C10, D1–D3, E1–E2, one line each, and anything not done with the reason.
2. **Screenshots:** `docs/redesign/proof/web-41/` and its file list, plus `inventory-map.md`.
3. **Tests:** Vitest files and cases before and after; lint, typecheck, build and `build.mjs --check`; `glass-ai.spec.ts` and the re-run specs' pass and fail counts; the lowest `free -m` available figure.
4. **Motion:** motion-timings rows for Deal, Quick type, Deck lift-off, the typing reveal and the offer Bloom (planned vs actual, dropped frames).
5. **Open issues:** every Continue call site now routed through `useContinue` (and any that could not be), whether the recap endpoint supports a cache bypass for "Write it again", anything `glass/DESIGN.md` left ambiguous and the choice made, and any conflict with this file.
6. **Commits:** the hashes pushed.

Next prompt file: `docs/redesign/prompts/web/42-glass-stats-streak-wrapped.md` (`docs/redesign/prompts/mobile/41-glass-ai-for-you-recaps.md` runs in parallel).
