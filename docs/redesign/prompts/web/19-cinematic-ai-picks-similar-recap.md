# web/19 · Cinematic AI: Picks, More like this and Previously on (new feature 1)

Step 55 of the redesign series (track `web`, group 2). Depends on `web/18-cinematic-settings-and-edition-restart.md` and `backend/05-ai-similar-recap-taste-onboarding.md`. Its twin `mobile/19-cinematic-ai-picks-similar-recap.md` builds the same feature in Flutter and may run at the same time in another session; you never touch `mobile/`.

## Goal

Deliver new feature 1 of the owner's decisions (AI home and recommendations, "because you read X", similar series and the "previously on" recap) on the Cinematic web skin, with the AI as the magazine's **editorial desk** that is visibly closed when it is unavailable, never broken. Build **Picks** at `/library/recommendations` (the Ask block, the editors' suggestions as mini reviews, For you, Because you read rails, the Your genres aside, dismiss and More-like-this on every card); **More like this** on the feature page's `03 MORE LIKE THIS` tab, in the chapter-end credits and in Quick look, and finish the **Because you read** rails on Tonight with in-session re-ranking; the **"Previously on" takeover** at `/recap/:sourceId/:seriesKey?to=:chapterKey`, a title card whose recap streams word by word from the server over SSE under a Bodoni drop cap, with a cast list, `Skip recap →`, and a 12 s auto-continue countdown with every pause rule; wire **every entry point** (Tonight, series pages, Continue buttons, cuttings, Quick look, the reader's first-page chip) through the `mm.recap` setting exactly as `glass/DESIGN.md` §15.6 resolves it; build the **fallbacks** for a closed desk; and apply the **§9.1.8 state vocabulary** (thinking, unavailable, partial, stale) identically on every AI surface, with `POST /ai/feedback` behind Not for me, More like this and rejected tags.

## Read first

1. `docs/redesign/cinematic/DESIGN.md`
   - **§9.1 in full**: §9.1.1 surfaces and entry points, §9.1.2 (the cover story and its recap case), **§9.1.3 Picks**, **§9.1.4 More like this and Because you read**, **§9.1.5 "Previously on"**, **§9.1.6 fallbacks**, §9.1.7 the backend contract (SSE framing, the no-stream JSON answer, stream headers), **§9.1.8 the AI state vocabulary and its copy**. Read every line.
   - §8.8 (Tonight: the `Picked for you`, `Because you read`, `Where were we?` rails, the cover story's `Previously on…`, the now-showing strip, keys `p` and `c`), §8.14.2 (the Column wipe and the Dip into readers), §8.14.6 (chapter-end credits: caught up and the end), §8.17 (feature page: the actions row, `03 MORE LIKE THIS`, the DETAILS aside with suggested tags, keys `p`, `1`–`4`), §8.18 (book page: `Previously on…`, key `p`), §8.25, §8.30.2 rows 03–04 (the recap setting's wording).
   - §2.1.4 (`scrim.foot.black`, `scrim.vignette`, the over-art rule and `on-art` controls), §2.1.5 (duotone), §2.5, §2.8, §3.2 (`type.headline`, `type.pull`, `type.field`, `type.dropcap`), §4.2–§4.8 (incl. **Countdown**, **Type**, **Letter set**, word streaming 160 ms / 30 ms, reduced motion rows for the recap countdown), §5 (`recap.countdown.end`, `reader.enter`; the web vibrates only for five events), §7.1 (`split`, `on-art`), §7.2, §7.4 (the `index` field in prompt mode), §7.5 (segmented control), §7.6 (**World card**: Available, Information-only and Shelf variants, the certificate rule), §7.7, §7.8 (rails and their AI states), §7.9, §7.11, §7.12, §7.19 (`PICKED 3 DAYS AGO`), §7.22 (Quick look and its `Previously on` row), §7.23, §7.27, §7.29, §10.1 (letter reveal triggers, incl. `signal` for the recap title), §10.2 (the Picks thinking line and "Writing the recap…" are typed), §11, §13 moment 9, §14.5 (timers wait for screen-reader users), §15.5, §15.7 (the over-art table rows for the World card buttons and `Skip recap →`).
2. `docs/redesign/glass/DESIGN.md` **§15.6 (the recap setting row, binding)**, §15.5 (the device keys table), §9.1 (only to keep the shared modules skin-neutral: Glass calls the same recap, similar and feedback functions with `shape=deck`).
3. `docs/redesign/inventory/00-decisions.md` (new feature 1; "External AI API only. Design loading and 'AI unavailable' states").
4. `docs/redesign/stack-decision.md` §2.6 (AI logic runs on the backend; clients only render), §2.2.
5. `docs/redesign/inventory/web.md` §7.8 (RC1–RC11), §7.3 and §8.3 (series pages), §9 (reader), §18.4 (the calls).
6. `docs/redesign/inventory/capabilities.md` §8, §9 (recommendations and AI suggestions), §20 (OCR coverage behind manga recaps).
7. `docs/redesign/00-baseline.md`.
8. `docs/redesign/prompts-plan.json` (this entry and `web/08`, `web/11`, `web/12`, `web/14`, `web/16`, `web/18`, `backend/04`, `backend/05`), and the backend code `backend/05` added: `grep -rn "ai/recap\|ai/similar\|ai/feedback\|ai/tags" backend/routes` (read the handlers and schemas so the client types match exactly).

## Skills to invoke, in this order

1. `superpowers:writing-plans`: plan to `docs/redesign/proof/web-19/plan.md`, one task per Scope item.
2. `superpowers:subagent-driven-development` (task groups A–G, one after the other); `superpowers:executing-plans` if subagents are unavailable.
3. `frontend-design:frontend-design`, `impeccable:impeccable`, `taste-skill:taste-skill` while building; the contract wins on conflicts.
4. `superpowers:verification-before-completion` before claiming done.

## Before you start

- Branch `feat/vps-slim-source-native`; other sessions commit here: stage only your paths; never `git add -A`, `git stash`, `git reset`, `git checkout` on others' files.
- Stop and report if missing: `picks` and `recap` in the Cinematic `PENDING` set; `backend/05`'s `/ai/similar`, `/ai/recap/availability`, `/ai/recap` and `/ai/feedback` routes; `web/18`'s `frontend/src/features/recap/recap-setting.ts` (if it is missing, create it here exactly as `web/18` item A2 specifies: key `mm.recap`, shape `{ mode: "off" | "ask" | "always", seriesDays, chapterDays, skipSeries[] }`, default `{ "ask", 7, 3, [] }`, plus `mm.recap.autoContinue` default `true`); `web/16`'s `features/home/genre-weights.ts` and the §9.1.8 copy module (`grep -rln "The picks desk is closed tonight" frontend/src`).
- Read the legacy Picks screen only for its hooks: `frontend/src/features/library/components/RecommendationsView.tsx`, `SuggestionPromptBox.tsx`, and `features/library/{hooks,api,types,world-card,suggestions}.ts`. Never import from `components/`.

## Ground rules for this step

- **Track rule.** Work in `frontend/` only; stage explicit paths; do not edit `design/`, `brand/`, `mobile/` or `backend/`.
- **Skin boundary** (the eslint rule): Cinematic screens import `@/features/**` (never `*/components/**`), `@/lib/**`, `@/services/**`, `@/stores/**`, `@/types/**`, `@/config/**`, the generated contract and their own skin.
- **The AI stays server-side.** The client never calls an AI provider; it calls only the backend endpoints below and renders. Branch on the error `code`, never on the HTTP status (429 is both `ai_budget_exhausted` and `rate_limited`).
- **Shared logic in `features/`**, skin-neutral (no Cinematic copy or tokens), each module with a Vitest test (Vitest runs `src/**/*.test.ts` in the `node` environment, so logic lives in `.ts` modules with injected dependencies).
- **Paths** from `ROUTES` in `frontend/src/skins/contract.generated.ts` (use the generator's names for the builders of `picks`, `recap`, `reader`, `novel`, `feature`, `featureByFollow`, `discover`).
- **Tokens only** in `src/skins/cinematic/**`.
- **Never** edit `backend/connectors/`, never touch production containers or `/srv/manhwamaniacs/{app,data}`.
- **RAM guard.** `free -m` before every build, test and Playwright run; stop if `available` < 1024 MB; never run two builds (or a build and `next dev`) at once.

## Scope: every item this step delivers

Remove `picks` and `recap` from the Cinematic `PENDING` set when their screens are done. Picks registers its keys under the keyboard group `Picks`, the recap under `Recap`. Titles: `Picks · ManhwaManiacs`, `Previously on {title} · ManhwaManiacs`. Route focus lands on each `h1`.

### A. Shared data-layer work (skin-neutral, Vitest-tested)

1. `frontend/src/services/http.ts`: export `requestStream(path, { query, signal })`, reusing the private `send()` (same `credentials: "include"`, same `X-Profile-Id` header, same `ApiError` contract) with `Accept: text/event-stream, application/json`, returning the `Response`. `EventSource` is not used, because it cannot send `X-Profile-Id`.
2. `frontend/src/features/recap/sse.ts`: `parseSse(stream: ReadableStream<Uint8Array>)` as an async generator of `{ event, data }`: UTF-8 decoding across chunk boundaries (`TextDecoder` with `stream: true`), events separated by a blank line (`\n\n` or `\r\n\r\n`), `event:` and one or more `data:` lines joined with `\n`, comment lines starting with `:` ignored. Tests: an event split mid-line across chunks, multi-line data, CRLF, a trailing partial event dropped.
3. `frontend/src/features/recap/api.ts`: `recapAvailability({ source, series, to })` → `GET /ai/recap/availability` (`{ available, reason: "ok" | "no_dialogue" | "first_chapter" | "not_configured" | "budget_exhausted", range: { from_key, to_key, from_number, to_number }, est_seconds, cached }`); `openRecap({ source, series, to, signal })` → `requestStream("/ai/recap", …)`; when the response's `Content-Type` is JSON it resolves `{ kind: "none", reason, retryAfter }` (`reason` among `not_configured`, `budget_exhausted`, `rate_limited`, `no_dialogue`, `first_chapter`; `retryAfter` from the `Retry-After` header); otherwise `{ kind: "stream", events }` where events are `meta` (`{ range, cast: [{ name, role }], sourced_from: "ocr" | "text" }` plus any fields `backend/05` added, such as `generated_at`), `delta` (`{ text }`), `done`, `error` (`{ code, message }`). Tests with fake `Response` objects for both kinds.
4. `frontend/src/features/recap/hooks.ts`: `useRecapAvailability({ source, series, to }, { enabled })` (React Query key `["ai", "recap-availability", source, series, to]`, `staleTime: 60_000`); `useRecapStream({ source, series, to })` returning `{ phase: "loading" | "streaming" | "done" | "none" | "error", reason, retryAfter, meta, words: string[], retry() }`, aborting on unmount.
5. `frontend/src/features/recap/should-open-recap.ts`: pure decisions over the `mm.recap` setting: `shouldOpenRecapFirst({ setting, seriesId, lastReadAt, now, available })`: `false` when `seriesId` is in `skipSeries` or `mode` is `off`; with `always`, `true` when the last read was on a different local day and `available`; with `ask`, `true` when the gap is at least `seriesDays` days and `available`. `mayAutoOpen({ setting, seriesId, lastReadAt, now })` (the same checks without availability: whether a `Continue` press whose item carries no `recap` must ask the endpoint first). `chipVisible({ setting, lastReadAt, now, available })`: the gap is at least `seriesDays` when `mode` is `ask`, or at least 14 days when `mode` is `always` or `off`, and `available`. `skipRecapsFor(seriesId)` / `allowRecapsFor(seriesId)` edit `skipSeries` (`"{sourceId}:{seriesKey}"`). Tests for every branch, including day boundaries in the local timezone.
6. `frontend/src/features/recap/recap-origin.ts`: `writeRecapOrigin(recapPath, { entry: "wipe" | "dip" | "reader", returnTo })` in `sessionStorage['mm.recap.origin']` just before navigating to a recap; `readRecapOrigin(recapPath)` returns it when the path matches, else `{ entry: "dip", returnTo: "/" }` (a cold deep link). Test.
7. `frontend/src/features/recap/countdown.ts`: a reducer for the 12 s countdown: state `{ remainingMs, running, pausedBy: Set<Reason> }`, reasons `pointer-continue`, `pointer-text`, `pointer-cast`, `touch`, `focus-text`, `focus-cast`, `hidden`, `space`, `key`, `pointerdown`, `selection`, `focusin`; actions `start`, `tick(ms)`, `pause(reason)`, `resume(reason)`, `reset` (scrolling back up), `toggleSpace`; `space` is the only reason that `toggleSpace` clears; the one-shot reasons (`key`, `pointerdown`, `selection`, `focusin`) stay until `Space` resumes. Tests: it never goes below 0, each reason pauses, reset returns to 12,000 ms.
8. `frontend/src/features/ai/state.ts`: `aiState({ loading, available, reason, errorCode, generatedAt, now, partial })` → `{ state: "thinking" | "ready" | "unavailable" | "partial" | "stale", reason }`; `staleDays(generatedAt, now)` → `null` under 24 h, else `max(1, floor(hours / 24))`. Tests, including a 429 with `code: "rate_limited"` versus `code: "ai_budget_exhausted"`.
9. `frontend/src/features/ai/similar.ts` and `hooks.ts`: `aiSimilar({ source, series } | { anilistId }, { fallback })` → `GET /ai/similar` (`fallback=genres` returns items with `why: null` and `basis: "genres"`, restricted to the profile's sources; type the items exactly as the `backend/05` schema says) and `useSimilar(…)`. Feedback and tags already exist: `sendAiFeedback({ signal, anilist_id?, source_id?, series_key?, tag? })` in `features/ai/feedback.ts` (`web/08`) and `features/ai/tags.ts` (`web/11`); reuse them and add a `useAiFeedback()` mutation hook around `sendAiFeedback` if none exists. `useDismissedPicks()`: a per-profile, per-session set (React Query cache key `["ai", "dismissed"]`) so a card dismissed on Picks is also gone from Tonight's rails until reload. Tests for the request builders and the dismissed set.
10. `frontend/src/features/library/api.ts` and `hooks.ts`: `librarySuggest({ prompt, limit })` → `POST /library/suggest` (read its response model in `backend/routes/library.py` and type it exactly; items are `kind: "source"` rows with `why`) and `useLocalSuggest()`. Keep `useWorldSuggest()` for `FROM EVERYWHERE`.
11. `frontend/src/features/home/rerank.ts`: in-session re-ranking (§9.1.4): `noteOpenedFromRail(topGenre)` appends to `sessionStorage['mm.home.rerank']` (unique, newest last) when the reader opens a series from a Tonight rail; `rerankRails(rails, noted)` moves each rail whose top genre matches a noted genre up by one position (newest noted genre applied last), never above the cover story or `Continue`. Tests.

### B. Picks (`/library/recommendations`, ScreenId `picks`), §9.1.3, web R12 RC1–RC11

Data: `useWorldRecommendations()` (`for_you`, `sections[]` with `because`, `unavailable_reason`), `useSuggestAvailability()` (`available`, `reason`, `remaining_today`, `daily_ceiling`), `useWorldSuggest()` and `useLocalSuggest()`, `useGenreWeights()` (`web/16`), `useDismissedPicks()`, `useAiFeedback()`.

**Desktop (≥ 1440 px: 12 columns; the ask block in 1–8, the aside in 9–12):**
1. Masthead: kicker `No. 12 — PICKS`, title "Picks" (letter reveal on mount), deck by state: "Describe it in your own words. Suggestions are weighed against what you already read." (AI available) / "The picks desk is closed tonight. Asks reset at midnight UTC. The picks below still work." (budget spent) / "Titles from everywhere, picked from what you read." (no ask). When the world recommendations carry a `generated_at` older than 24 h, the `PICKED 3 DAYS AGO` micro badge (1 px `ink.45` outline, `type.micro`) sits beside the deck; payloads without `generated_at` are never marked stale.
2. **Ask block** (only while AI is available and configured): the `index` field in prompt mode as an auto-growing `<textarea>` (1 line, growing to 4, then scrolling) in `type.field` (Bodoni Moda Italic; typed text in Roman), accessible name "Describe what you feel like reading"; its placeholder is typed at 50 ms per character and cycles every 6 s through "A murim regressor who comes back stronger", "Magic academy, but the lead is already strong", "Something slow and political, not a power fantasy" (an `aria-hidden` visual layer; the real `placeholder` holds the first example); `Enter` submits, `Shift+Enter` inserts a newline; 3–600 characters (`canSubmitPrompt`), with the folio `12 / 600` (`type.folio` `ink.45`) at the right under the underline; the three examples also as a slug line of `quiet` buttons that fill the field and submit; `Ask the editors` (primary, `sparkle` 20 Regular, disabled until the prompt is valid, loading segment while asking); the quota folio `8 ASKS LEFT TODAY` shown when `remaining_today` ≤ 10; the source toggle as a segmented control `FROM YOUR SOURCES │ FROM EVERYWHERE` (default `FROM EVERYWHERE`; maps to `POST /library/suggest` vs `POST /library/world/suggest`). Arriving with the hash `#ask` (Discover's `Ask`) focuses the field.
3. **Results** (after an ask): kicker `THE EDITORS SUGGEST`, then result cards as **mini reviews** in two columns: World cards (§7.6) with the `why` as a Newsreader italic pull quote on a 2 px `spot` left rule; `FROM YOUR SOURCES` answers use the World card's **Shelf** variant. **Thinking:** the line "Reading your shelf…" typed at 50 ms per character, a 24 px leader dial after 1 s; when the answer lands, each card fades in over 160 ms, 30 ms after the previous. **After 40 s** with nothing back, the timeout copy replaces the thinking line: "The editors took too long. Try a shorter description." + `Try again`; the request is **not** aborted, so a late answer still renders its cards and removes the timeout copy; `Try again` aborts the running request and asks again; the field keeps its text. `remaining_today` refreshes after every answer.
4. **`01 For you`** (H3 section head with the letter reveal): a grid of World cards, 3 per row, from `for_you` minus dismissed items.
5. **`02 Because you read {title}`, `03 …`**: one rail (§7.8) of World cards per `sections[]` entry; the H3 sets the seed title in Bodoni Moda **Roman** inside the italic head through `SetHeading`'s `roman` prop (`web/08`): "Because you read" italic, "Solo Leveling" roman.
6. **Aside `YOUR GENRES`** (columns 9–12 at ≥ 1440): a weighted slug line from `useGenreWeights()`: four sizes by weight quartile (12 / 14 / 17 / 20 px, Archivo wdth 75, wght 600, uppercase, +0.10em, line height 24), the top quartile in `ink.100` and the rest in `ink.60`; each genre links to `/search#genre={name}` (Discover opens that genre's sheet, `web/16`). Hidden when there are no weights.
7. **1024–1439 px:** the ask block spans columns 1–12 and the aside renders under it as a full-width `YOUR GENRES` slug line. **Tablet (600–1023):** the ask block across the 8 columns; For you 2 per row, 3 from 900 px; the aside under the ask block.
8. **Phone (< 600):** the ask block full width with the field at 28 px; results in one column; For you as a two-column grid; Because-you-read as rails (3.2 visible); the aside under the ask block. Pull to reprint (touch) refetches `GET /library/world/recommendations` and `GET /library/suggest/availability`, never re-asking the AI.
9. **World card behaviour** (every AI card in the app uses the same component and rules):
   - Available: the whole card opens the series (`ROUTES.feature`), through `web/08`'s `parts/SourcePickerSheet.tsx` when several sources have it (logos, names, health marks, `Open`).
   - Information only (duotone poster, credit `NOT ON YOUR SOURCES`): `Search my sources` (`quiet`, `ROUTES.discover` with `?q={title}`) and `Read on {site} ↗` (`quiet`; `window.open(url, "_blank", "noopener,noreferrer")`; a `null` result toasts "Couldn't open {url}").
   - **Not for me:** an `x` `on-art` icon button (40 px square, `color.onart` fill, 20 Regular `ink.100`, 44 hit) at the poster's top-right, shown on hover or focus on desktop, always in the long-press / right-click menu ("Not for me"), and `Delete` on a focused card: the card fades out over 240 ms (`dur.line` `ease.lift`) and the grid closes the gap by a Cut; `POST /ai/feedback { signal: "not_interested", anilist_id }` (or `source_id` + `series_key` for Shelf items); the item joins `useDismissedPicks()`.
   - **More like this:** a `thumbs-up` `on-art` icon button beside the `x` (hover on desktop, always in the menu; tooltip "More like this"; `aria-pressed`, fixed label "More like this"); on press it switches to the Fill glyph with a 2 px `spot` rule 4 px under the square, sends `signal: "liked_pick"` and toasts "Noted. Picks will lean this way."; pressing it again clears it locally (no request).
   - With the profile's gate open, the 16 px certificate on its `#000000` fill sits top-left on the poster when `is_adult` is true or any `available[]` source is mature; with the gate closed such items are absent.
10. **Keys (web):** `/` focuses the ask field; `Enter` asks; `j` / `k` move through the cards in reading order; `Delete` is Not for me on the focused card.
11. **States** (each built and screenshot-tested):

| State | Presentation |
|---|---|
| Loading world recs | Masthead live; the `01 For you` header with 6 flicker plates (after the 120 ms skeleton delay) |
| AI thinking | "Reading your shelf…" typed, the leader after 1 s, the cards fade in |
| AI not configured (`reason: not_configured`, or an ask answering `ai_not_configured`) | The ask block replaced by a `NOTE` line with the copy "The editors' desk isn't set up on this server."; world recs still show |
| Budget spent (`budget_exhausted`, or `ai_budget_exhausted`) | The ask field disabled; the quota folio reads `0 ASKS LEFT TODAY`; the caption "The picks desk is closed tonight. Asks reset at midnight UTC." |
| Shelf too thin (`suggest_shelf_empty`, 409) | Notice `NOTHING TO PICK FROM YET`: "There isn't enough in the catalogue cache yet. Browse a few sources, then ask again." + `Browse sources`, and a `quiet` `Ask everywhere instead` that switches the toggle to `FROM EVERYWHERE` |
| Ask failed (`ai_failed`, 502) | "The editors couldn't answer that one. Try describing it differently." + `Try again`; the field keeps its text |
| No matches (`ai_no_matches`) | A notice in the results slot: "Nothing fit that description. Try describing it differently." |
| Rate limited (`rate_limited`, 429 with `Retry-After`) | `SLOW DOWN`: "Too many asks at once. Try again in {n} s." with the live countdown |
| World catalogue unreachable (`unavailable_reason`) | A quiet caption under the masthead with the server's reason; cached recs shown |
| Partial | Loaded sections render; a failed AI section is omitted, the folios renumber, and the grid shows "Some picks didn't come through." |
| Stale | `PICKED 3 DAYS AGO` beside the deck (item 1) |
| Empty (new profile) | Notice `NOTHING TO GO ON YET`: "Read or follow a few series first. Picks start from what you read." + `Find something` (Discover) |
| Offline / error | `OFFLINE EDITION` / `CORRECTION` notices with `Try again` |

### C. More like this, Because you read and suggested tags (§9.1.4, §8.17)

1. **Feature page tab `03 MORE LIKE THIS`** (fill the slot `web/11` left in `frontend/src/skins/cinematic/screens/feature/manga/FeatureTabs.tsx`): a `Similar` rail from `useSimilar({ source, series })` (World cards in poster form with their `why` lines in the hover slate, Quick look and the caption), then a `Because you read {title}` rail when a world recommendations `sections[]` entry has this series as its `because` seed. States by §9.1.8: thinking (the H3 renders and a typed line "Finding series like this one…" with the leader after 1 s), unavailable (the H3 stays, the `NOTE` line with the copy for `reason` + "Here are series from the same genres.", and the fallback rail from `useSimilar(…, { fallback: "genres" })` whose cards carry the caption `SAME GENRES` instead of a `why`), stale (`PICKED 3 DAYS AGO` beside the H3 when `generated_at` is older than 24 h), empty ("Nothing similar on your sources yet." in `type.body.italic` `ink.45`). If the feature page's contents tabs are local state, add support for the hash `#more-like-this` selecting tab 03 (Quick look's `More like this` uses it).
2. **Chapter-end credits** (the `web/12` reader's credits in `frontend/src/skins/cinematic/screens/reader/`): the caught-up notice gets the `More like this` rail (Similar, with the genre fallback); **the end** (a Completed series finished) gets the `Up next` rail through `web/12`'s `features/library/up-next.ts`: plug Similar in as its first choice, then the Because-you-read world section, then `From your shelf` (plan-to-read and favourites from the library).
3. **Quick look** (`web/05`'s sheet, its actions listed in `web/08`'s `parts/quick-look-actions.ts`): add `More like this` (to the feature page with `#more-like-this`) and `Not for me` rows on AI-picked items.
4. **Tonight** (`web/08`): audit and finish the `Picked for you` and `Because you read` rails against §9.1.8 and §9.1.6: the H3 sets the seed title roman inside the italic head; the rails hide dismissed items; the unavailable state keeps the header with the `NOTE` line (the copy for `ai.reason` followed by "Here is your shelf instead.") and replaces `Picked for you` with `From your shelf` (favourites and plan-to-read, same position); a failed AI rail is omitted and the folios renumber; the stale badge follows `generated_at`. Apply `rerankRails()` to the rail order and call `noteOpenedFromRail()` when a series opens from a rail.
5. **Suggested tags** (feature page DETAILS aside, §8.17 item 4): `web/11` planned them on `features/ai/tags.ts`; verify the line against this item and §9.1.8 and complete it; if `grep -rn "ai/tags" frontend/src/skins` finds nothing, build it: when the AI desk is available, a `SUGGESTED` kicker line follows the own tags with up to 5 suggested tags from `GET /ai/tags?source&series` as dashed-outline tokens (1 px dashed `rule.2`, 28 px tall), each with `+` to accept (it becomes an own tag through the existing tag API; `select` cue when sounds are on) and `x` to reject (`POST /ai/feedback { signal: "tag_rejected", source_id, series_key, tag }`, the token fades 160 ms); the line is absent when the desk is closed or nothing is suggested.

### D. "Previously on" (`/recap/:sourceId/:seriesKey?to=:chapterKey`, ScreenId `recap`), §9.1.5

A **Takeover** (no sidebar, no thumb index, no running head; Dip in and Dip out), set as a title card. The route reads `to` from the query and the origin from `readRecapOrigin()`.

1. **Layout (all platforms):** background `#000000`; the series cover as a duotone band across the top 28 % of the viewport height (34 % on phones), `object-fit: cover`, duotoned to the series' `ambient.duo` (fallback `#B8B2A4`) with the skin's SVG filter, `scrim.vignette` over it, `scrim.foot.black` over the band's bottom 60 % (reaching `#000000` at its bottom edge), grain at 0.05 opacity (`Grain.tsx`, jittering at 12 fps; static under reduced motion). Kicker `PREVIOUSLY ON` with the letter reveal (trigger `signal`), then the series title in Bodoni Moda Italic at the `type.headline` sizes (32/36 phone · 44/48 tablet · 56/56 desktop · 64/64 wide, −0.030em) with the letter reveal (`signal`), as the page's `h1`; the deck "Chapters 131–142, as a recap." (`type.deck` `ink.60`; one chapter: "Chapter 142, as a recap.").
2. **The recap:** 3–5 paragraphs in Newsreader 20/32 (phone 18/28) at 58ch, `ink.80` on desktop and `ink.100` on phones, streamed word by word (each word fades in over 160 ms, 30 ms after the previous); a Bodoni Moda drop cap (Roman, wght 800) on the first paragraph at 3 × its line height (`--para-lh: 32px` gives 96 px; 84 px at 28 px); names from `meta.cast` in italic wherever they occur as whole words. The finished text is announced once to screen readers (a polite live region), never word by word.
3. **Cast list** (when `meta.cast` is not empty): kicker `CHARACTERS IN THIS STORY`, credits rows `Kim Dokja ........ the reader` (name, dot leaders, role).
4. **Footnote** (`type.caption` `ink.60`): "Recap written from the dialogue of chapters 131–142." (manga, `sourced_from: "ocr"`) or "Recap written from the text of chapters 131–142." (novels), then " AI-written; it can be wrong." When `meta` carries a `generated_at` older than 24 h, " Recap written 3 days ago." is appended (without that field, no stale line).
5. **`Skip recap →`** (visible from t = 0): an `on-art` button (§7.1: `color.onart` fill, 1 px `ink.100` outline at 40 %, `ink.100` text, 44 px hit) at the top-right: on desktop aligned to the right edge of column 12, 72 px from the top; on phones 16 px from the right and `env(safe-area-inset-top) + 8px` from the top. It goes straight to the reader by the recap's way in (item 8) and never waits for the stream.
6. **Actions** (sticky at the bottom on phones: a `#000000` bar with a 1 px `rule.1` top and the bottom safe-area padding): `split` primary `Continue │ CH 143` (lg 56 desktop / 48 phone; usable from t = 0), `quiet` `Skip recaps for this series` (`skipRecapsFor`; toast "Recaps are off for {title}." + `Undo` for 8000 ms, which calls `allowRecapsFor`), `quiet` `Close` (back to `returnTo` by Dip).
7. **Grid:** desktop, the recap column spans columns 3–9 and the cast list columns 10–12; tablet (600–1023), the recap in columns 1–6 and the cast in 7–8 (below the recap under 900 px); phone, one column.
8. **Way into the reader** (from `Continue`, `Skip recap →` and the countdown): origin `wipe` (opened from Tonight or a series page) → the **Column wipe** (desktop 376 + 40 + 456 ms, tablet 312 + 40 + 392, phone 248 + 40 + 328, blades `ease.settle`, 16 ms stagger) into the reader at `to`; origin `dip` → the **Dip** (160 / 40 / 240 ms); origin `reader` → a Dip back to `returnTo` (the open page). Novels open the novel reader. `recap.countdown.end` has no haptic or cue; `reader.enter` fires only when the exit is a Column wipe (no web vibration either way).
9. **Auto-continue countdown** (only when `mm.recap.autoContinue` is on, default on): when the stream is `done`, `Continue` starts a 12 s countdown (`dur.countdown.recap`): a 2 px `spot` rule inside the split button's bottom edge drains from full to empty (`ease.linear`) and the folio segment reads `CH 143 · 12 S`, counting down each second; at zero the reader opens by item 8. It **pauses** (A7) while the pointer is over `Continue`, the recap text or the cast list; while a finger touches the screen; while keyboard focus is inside the recap text or the cast list; while the page is hidden (`visibilitychange`); on the web also on any `keydown` other than `Space`, `Enter`, `s` and `Esc`, on `pointerdown`, on a text selection inside the recap and on `focusin` anywhere in the takeover. When it first starts, a polite live region says "Continuing to chapter 143 in 12 seconds. Press Space to pause." Scrolling back up in the recap resets it to 12 s. With the setting off, no countdown runs and `Continue` waits.
10. **Keys (web):** `Enter` continue; `s` skip the recap (straight to the reader); `Esc` close; `Space` completes the streaming at once (shows all text) and, once the recap is complete, pauses or resumes the countdown.
11. **States:**

| State | Presentation |
|---|---|
| Loading | The title card with kicker and title set; "Writing the recap…" typed at 50 ms per character; a 24 px leader after 1 s |
| Streaming | Words fade in; `Continue` and `Skip recap →` usable at any time |
| Done | The countdown runs, paused by the rules above |
| No recap (`no_dialogue`, as the JSON answer or a stream `error`) | Kicker `NO RECAP FOR THIS ONE`; "The dialogue in these chapters hasn't been read yet, so there's nothing to recap." + `Continue │ CH 143` |
| Unavailable (`not_configured`, `budget_exhausted`, `rate_limited`) | A static slate: kicker `RECAP UNAVAILABLE` in `ink.45` (not a `NOTE`, never `proof`); "Pick up where you left off: chapter 143." + `Continue`; rate limited adds `SLOW DOWN` "Too many asks at once. Try again in {n} s." with the live `Retry-After` countdown |
| First chapter (`first_chapter`) | No slate: straight to the reader by item 8 |
| Offline | The unavailable slate with the `OFFLINE EDITION` kicker |
| Error | A `CORRECTION` line + `Try again` + `Continue` |
| Not available (`series_not_found` / `source_not_found` / gated) | The §8.0.10 notice `NOT IN THIS ISSUE` |

### E. Entry points and the `mm.recap` setting

Every `Previously on…` button and the reader chip render **only** when the availability says `available`. The recap setting is read from `features/recap/recap-setting.ts` (`mm.recap`, per profile, exactly the glass §15.6 shape; Cinematic `NEVER`/`ALWAYS`/`AFTER N DAYS AWAY` = `off`/`always`/`ask` + `seriesDays`), never from the server.

1. **One helper for every Continue**: `frontend/src/skins/cinematic/recap/continue-to.ts` (built on the reader-entry helper `web/08` and `web/12` use, `frontend/src/skins/cinematic/navigation.ts` / `screens/reader/entry.ts`, for the Column wipe and the Dip) exporting `continueTo({ sourceId, seriesKey, chapterKey, title, lastReadAt, recap, origin: "wipe" | "dip" })`: when `shouldOpenRecapFirst(…)` with the item's `recap` is true, it writes the origin and navigates to the recap by Dip; when the item carries no `recap` and `mayAutoOpen(…)` is true, it calls `recapAvailability` on press with a **400 ms** timeout and opens the recap only on an `available` answer in time; otherwise it opens the reader with the origin's transition (Column wipe for `wipe`, Dip for `dip`). Route every `Continue` split button and cutting in the Cinematic skin through it (find them with `grep -rn "Continue" frontend/src/skins/cinematic/screens`): Tonight's cover story and now-showing strip (`wipe`), Tonight's `Continue` section cuttings (`dip`), Library's Continue rail cuttings (`dip`), Quick look `Continue` (`dip`), the feature and book pages' split button (`wipe`).
2. **Tonight** (`web/08`): the cover story's `Previously on…` (secondary, when `cover.recap.available`), the now-showing strip's `Previously on` (`quiet`, in its overflow below 1440 px), the key `p`, and `Where were we?` long-press offering `Previously on` first (when that item's `recap.available`): all open the recap with origin `wipe` (cover and strip) or `dip` (rail items).
3. **Feature page and book page** (`web/11`: `screens/feature/manga/FeatureSpread.tsx`, `FeaturePhoneHero.tsx`, `use-feature-keys.ts`, and `screens/feature/book/BookFrontMatter.tsx`): the `Previously on…` secondary in the actions row and the key `p`, when `useRecapAvailability({ source, series, to: the continue chapter })` (called once on load) answers `available`; origin `wipe`.
4. **Quick look** on cuttings and posters: the `Previously on` row when the item's `recap.available`; for items without `recap`, call the endpoint when Quick look opens and add the row only on an `available` answer, never holding the other rows; origin `dip`.
5. **The reader's first-page chip** (the manga reader in `screens/reader/` from `web/12`, the novel reader in `screens/novel/` from `web/14`): on the first page of a chapter, a slim `quiet` chip `PREVIOUSLY ON · {ceil(est_seconds / 60)} MIN` (e.g. `PREVIOUSLY ON · 2 MIN`) under the running head when `chipVisible(…)` is true (the reader calls the availability endpoint once on its first page); it opens the recap with origin `reader` and `returnTo` = the current reader URL; it hides with the chrome like the rest of the running head.

### F. Fallbacks when the AI desk is closed (§9.1.6)

Verify each and fix what is missing: Tonight's cover story uses the local priority rules (§9.1.2 cases 1–3, else the most recently updated followed series) with the synopsis as the deck; `Picked for you` becomes `From your shelf` under the `NOTE` line; `Almost there`, `Where were we?` and `Sent to you` stay; Because-you-read rails come from world recommendations when that catalogue is reachable, otherwise they are omitted; Picks shows world recs without the ask block; recaps show the static slate; Similar uses the genre fallback.

### G. The §9.1.8 state vocabulary on every AI surface

Every AI-backed surface is in exactly one of thinking, unavailable, partial or stale (through `features/ai/state.ts`) and uses the copy module found in "Before you start" (extend it; do not create a second one): Tonight's `Picked for you` and `Because you read`, Picks (ask, results, For you, Because you read), Discover's `ASK` scope and `ASK THE EDITORS` block (`web/16`), Similar (feature tab, credits, Quick look), suggested tags, and the recap. **Thinking** is always a typed line plus a leader dial after 1 s, then words (160 ms, 30 ms apart) or cards (160 ms, 30 ms apart): never a spinner and never a skeleton that pretends content exists. **Unavailable** is a `NOTE` kicker in `spot` with the reason in `type.caption` `ink.60`, never `proof`, always beside the non-AI path (the recap slate's `RECAP UNAVAILABLE` stays `ink.45`). **Partial** omits what failed and renumbers folios. **Stale** is `PICKED {n} DAYS AGO` (or `PICKED 1 DAY AGO`) beside the H3, the Picks deck or the recap footnote.

### H. Cross-cutting

- **Reduced motion:** letter reveals fade 200 ms; typed lines and placeholders show at once with no caret; streamed words appear with no per-word fade (still in order); card fade-ins become one 160 ms fade; the countdown shows no draining rule, only the folio updated once per second; the Column wipe and Dip become a 200 ms / 150 ms cross-fade; grain is static; the dismissed card disappears with a 150 ms fade; programmatic scrolls jump. Leader dials keep running.
- **Screen readers:** the countdown never starts while a screen reader is known to be running (web: rely on the pause triggers above); streamed text is announced once when complete.
- **Focus:** the double ring on every control, including over the cover band (the 6 px black halo); the recap's initial focus is its `h1`; `Esc` closes the takeover.
- **Hit targets:** 44 × 44 on coarse pointers (the World card's `x` and `thumbs-up`, `Skip recap →`, the chip), 32 × 32 on fine pointers.
- **Contrast:** `Skip recap →` and the World card buttons sit on `color.onart` (`ink.100` on 0.64 black reaches 5.89:1 over `#FFFFFF`); the recap text sits on `#000000` below the band.

## Values you need (copied from `cinematic/DESIGN.md`)

| What | Value | Section |
|---|---|---|
| Inks and grounds | `paper.0` `#000000`, `paper.1` `#0B0B0A`, `paper.2` `#121211`, `ink.45` `#7A7770` (on `paper.0` only), `ink.60` `#9A978F`, `ink.80` `#C9C6BE`, `ink.100` `#F3F0E8`, `rule.1` `#2B2A27`, `rule.2` `#3D3C38` | §2.1.1 |
| Accent | `spot` `#F4D03F`, `spot.wash` `rgba(244,208,63,0.16)`; `color.onart` `rgba(0,0,0,0.64)`; `proof` `#FF5B4A` (errors only, never for AI unavailability) | §2.1.2–§2.1.4 |
| Scrims | `scrim.foot.black`: the 13 eased stops over the band's bottom 60 % to `#000000`; `scrim.vignette` `radial-gradient(120% 90% at 50% 40%, rgb(0 0 0/0) 60%, rgb(0 0 0/.45) 100%)` | §2.1.4 |
| Scrim stops | positions `0, 1.8, 4.8, 9, 13.9, 19.8, 27, 35, 43.5, 53, 66, 81, 100 %`, alphas `0, .002, .008, .021, .042, .075, .126, .194, .278, .382, .541, .738, 1` | §2.1.4 |
| Durations | `dur.type` 50 per grapheme, `dur.caret` 530, `dur.letter` 640 (blur 440), `dur.line` 240, `dur.beat` 160, `dur.clip` 200, `dur.reduced` 150, `dur.countdown.recap` 12000, `dur.hold.toast.action` 8000, `dur.wipe.close` 200, `dur.wipe.open` 280, `dur.hold.dip` 40 (ms) | §4.2 |
| Word streaming | each word 160 ms fade, 30 ms after the previous | §4.6 |
| Curves | `ease.settle` `cubic-bezier(0.16,1,0.3,1)`, `ease.lift` `cubic-bezier(0.7,0,0.84,0)`, `ease.turn` `cubic-bezier(0.65,0,0.35,1)`, `ease.linear` `linear` | §4.3 |
| Type | `type.field` Bodoni Moda Italic 500 (28/36 · 32/40 · 36/44 · 40/48); `type.headline` 32/36 · 44/48 · 56/56 · 64/64; `type.pull` Bodoni Moda Italic 500 (24/32 · 28/36 · 36/44 · 40/48); recap body Newsreader 20/32 (phone 18/28); drop cap 3 × line height, Bodoni Moda wght 800 | §3.2, §9.1.5 |
| Grid | desktop 12 cols margin 48 gutter 24; wide margin 72, max 1760; tablet 8 / 32 / 16; phone 4 / 16 / 12 | §2.2.2 |

## File layout

```
frontend/src/services/http.ts                               (requestStream)
frontend/src/features/recap/{sse,api,hooks,should-open-recap,recap-origin,countdown}.ts   (+ .test.ts each, except hooks)
frontend/src/features/recap/recap-setting.ts                (from web/18; created here only if missing)
frontend/src/features/ai/{state,similar,hooks}.ts           (+ state.test.ts, similar.test.ts; feedback.ts and tags.ts are reused)
frontend/src/features/library/{api,hooks,types}.ts          (librarySuggest, useLocalSuggest)
frontend/src/features/home/rerank.ts                        (+ .test.ts)
frontend/src/skins/cinematic/ai-copy.ts                     (or the module web/08 / web/16 created: extended, not duplicated)
frontend/src/skins/cinematic/screens/picks/
  PicksScreen.tsx  AskBlock.tsx  EditorsSuggest.tsx  ForYou.tsx  BecauseRails.tsx  GenreAside.tsx  keys.ts
frontend/src/skins/cinematic/parts/{SourcePickerSheet.tsx,quick-look-actions.ts}   (web/08's, reused; quick-look-actions gains More like this, Not for me, Previously on)
frontend/src/skins/cinematic/primitives/WorldCard.tsx       (extend the web/04 card with Not for me and More like this, if not there)
frontend/src/skins/cinematic/screens/recap/
  RecapScreen.tsx  CoverBand.tsx  RecapText.tsx  CastList.tsx  RecapActions.tsx  RecapSlate.tsx  keys.ts
frontend/src/skins/cinematic/recap/continue-to.ts
frontend/src/skins/cinematic/screens/feature/manga/…       (FeatureTabs 03 MORE LIKE THIS, Previously on, suggested tags)
frontend/src/skins/cinematic/screens/feature/book/…        (Previously on)
frontend/src/features/library/up-next.ts                    (Similar as the first choice)
frontend/src/skins/cinematic/screens/tonight/…              (rails audit, rerank, entry points)
frontend/src/skins/cinematic/screens/reader/…               (the first-page chip, the credits rails)
frontend/src/skins/cinematic/screens/novel/…                (the first-page chip)
frontend/src/skins/cinematic/index.ts                       (wire picks and recap, remove them from PENDING)
frontend/e2e/cinematic/web-19-ai.spec.ts
docs/redesign/proof/web-19/                                 (plan.md, routes.txt, screenshots, report.md)
```

These are the folders `web/08`, `web/11`, `web/12` and `web/14` specify; if one of them landed elsewhere, `ls frontend/src/skins/cinematic/screens` shows where, and you change it there.

## Commit plan (small commits, push after each)

1. `feat(web/19): streaming requests and the SSE parser` (A1–A2).
2. `feat(web/19): recap api, decisions, origin and countdown` (A3–A7).
3. `feat(web/19): ai state, similar, feedback and local suggest` (A8–A10).
4. `feat(web/19): tonight rail re-ranking helper` (A11).
5. `feat(web/19): cinematic picks`.
6. `feat(web/19): more like this, because you read and suggested tags`.
7. `feat(web/19): previously on takeover`.
8. `feat(web/19): recap entry points and continue routing`.
9. `test(web/19): ai e2e checks and proof screenshots`.

`git add` exact paths; **no** `Co-Authored-By`, no "Generated with" line, no AI attribution; `git push origin feat/vps-slim-source-native` after each. Never commit secrets, `.env*` or `.claude/`.

## Acceptance criteria

- [ ] `picks` and `recap` are gone from the Cinematic `PENDING` set; the completeness test passes.
- [ ] Picks renders every part of section B at 1440, 1024–1439, tablet and phone widths, with every state in the table (screenshots of each).
- [ ] The ask field types its three examples cycling every 6 s, submits on `Enter`, inserts a newline on `Shift+Enter`, shows `n / 600`, enforces 3–600 characters, and switches between `/library/suggest` and `/library/world/suggest` with the toggle; `#ask` focuses it.
- [ ] Thinking shows the typed line and the leader after 1 s; after 40 s the timeout copy appears without aborting; `Try again` aborts and re-asks; a late answer still renders.
- [ ] Not for me fades the card, closes the gap, sends `not_interested` and hides the item on Tonight too for the session; More like this sends `liked_pick`, fills with the spot rule, toasts, and clears locally on a second press; `Delete` dismisses the focused card.
- [ ] The feature page's `03 MORE LIKE THIS` shows Similar (with `why`) and the Because-you-read rail, or the `SAME GENRES` fallback under the `NOTE` line when the desk is closed; the credits' caught-up and the-end rails use the same data; Quick look offers `More like this`.
- [ ] Tonight's AI rails follow §9.1.8 and §9.1.6 and re-rank within the session after a series opens from a rail (Vitest for `rerankRails`).
- [ ] The recap takeover streams the prose word by word under the drop cap, italicises cast names, lists the cast, shows the footnote, offers `Skip recap →` from t = 0, and continues by the Column wipe (origin `wipe`), the Dip (origin `dip`) or back to the open page (origin `reader`).
- [ ] The countdown runs 12 s only after the stream completes and only with `mm.recap.autoContinue` on, drains the 2 px rule, updates `CH 143 · 12 S` each second, pauses on every listed trigger, resets on scrolling up, announces itself once, and `Space` pauses and resumes it (Vitest for the reducer; the e2e spec checks hover and `keydown` pauses).
- [ ] Every recap state in D11 renders (mocked in the e2e spec), and a JSON no-stream answer maps exactly like the matching stream `error`.
- [ ] `mm.recap` keeps exactly the glass §15.6 shape; `ALWAYS`, `AFTER N DAYS AWAY` and `NEVER` behave per §9.1.5 through `continueTo()`; `Skip recaps for this series` writes `skipSeries` and the series then behaves as `NEVER`; the reader chip shows `PREVIOUSLY ON · N MIN` only under `chipVisible`; a `Continue` without a `recap` field asks the endpoint only when `mayAutoOpen` and gives up after 400 ms.
- [ ] Every `Previously on…` entry renders only on an `available` answer.
- [ ] Every AI surface in section G uses the one state module and the one copy module; no AI state is drawn in `proof`; the client branches on `code`, never on the status.
- [ ] Reduced motion per section H (the e2e spec emulates `reducedMotion: "reduce"`: no draining rule, the folio still counts, the recap text appears without per-word fades, the placeholder is complete at once).
- [ ] Keyboard: Picks keys (`/`, `Enter`, `j`, `k`, `Delete`) and recap keys (`Enter`, `s`, `Esc`, `Space`) work; every control is reachable with the double ring; route focus lands on each `h1`; the titles match.
- [ ] Hit targets: at 390 × 844 every interactive element on Picks and the recap is at least 44 × 44 CSS px (the e2e spec checks bounding boxes); at 1440 × 900 at least 32 × 32.
- [ ] Per-skin difference: the Glass skin still maps `picks` and `recap` to `PENDING`; every shared module (A1–A11) contains no Cinematic copy or tokens, so Glass (`web/41`) calls the same recap, similar and feedback functions with its own screens; lint passes (no Glass or legacy imports under `src/skins/cinematic/**`).
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

`mobile/` and `backend/` are untouched; `git diff --stat origin/feat/vps-slim-source-native -- mobile backend` must be empty, so `flutter analyze`, `flutter test` and the backend pytest are not run in this step.

**Visual proof.** Start the `backend/00` dev stack in the background as `backend/scripts/README-dev-stack.md` says (uvicorn `127.0.0.1:8010`, dev SQLite only; the AI key is normally unset there, which gives the real unavailable states), then `cd frontend && free -m && BACKEND_INTERNAL_URL=http://127.0.0.1:8010 npm run dev -- --port 3010` (the usage comment at the top of `frontend/scripts/proof.mjs`, from `web/03`, and the README win if they differ) (the README wins if it differs). Write `docs/redesign/proof/web-19/routes.txt` (replace `{s}`, `{k}` and `{c}` with a followed demo series and a chapter the demo profile has read):

```
/library/recommendations
/library/recommendations#ask
/sources/{s}/series/{k}#more-like-this
/recap/{s}/{k}?to={c}
/
```

and capture at 1440 × 900 and 390 × 844, plain and with the grid overlay:

```bash
free -m
cd frontend
MM_PROOF_USER=<demo user> MM_PROOF_PASSWORD=<demo password> node scripts/proof.mjs --step web-19 --skin cinematic --routes /srv/manhwamaniacs/dev/ManhwaManiacs/docs/redesign/proof/web-19/routes.txt --grid
free -m
MM_PROOF_USER=<demo user> MM_PROOF_PASSWORD=<demo password> node scripts/proof.mjs --step web-19 --skin cinematic --routes /srv/manhwamaniacs/dev/ManhwaManiacs/docs/redesign/proof/web-19/routes.txt --reduced
```

The credentials are the seeded demo account's, from `backend/scripts/README-dev-stack.md` (never hard-code them in a file). `--grid` saves a `-grid` copy of every shot and `--reduced` a `-reduced` set; both viewports (1440 × 900 and 390 × 844) are captured by default.

Then the mocked AI states, from `frontend/`:

```bash
free -m
E2E_BASE_URL=http://127.0.0.1:3010 MM_PROOF_USER=<demo user> MM_PROOF_PASSWORD=<demo password> npx playwright test e2e/cinematic/web-19-ai.spec.ts
```

`e2e/cinematic/web-19-ai.spec.ts` signs in with `signIn` imported from `scripts/proof.mjs`, sets `mm-skin-debug=cinematic`, and uses `page.route` to answer `/api/library/suggest/availability`, `/api/library/world/**`, `/api/library/suggest`, `/api/ai/similar*`, `/api/ai/tags*`, `/api/ai/recap/availability*` and `/api/ai/recap*` with fixtures (an SSE body `event: meta` / `event: delta` × n / `event: done` served with `Content-Type: text/event-stream`, plus JSON no-stream answers for `no_dialogue`, `budget_exhausted`, `rate_limited` with `Retry-After: 12`, and `first_chapter`). It saves `docs/redesign/proof/web-19/state-*.png` at both sizes for: Picks thinking, results, the 40 s timeout (with `page.clock` advanced), not configured, budget spent, shelf too thin, ask failed, no matches, rate limited, partial, stale, empty; the feature tab with Similar and with the genre fallback; the recap loading, done with the countdown at 7 s, no recap, unavailable, rate limited; the reader chip. It asserts the checks above (countdown pauses on hover and on a non-reserved `keydown`, `Space` toggles, `Esc` closes, hit targets, focus, titles, reduced motion, and that no AI state uses the `proof` colour). Stop `next dev` and the dev stack afterwards.

## Report back

Reply with:
1. The acceptance checklist, each box ticked or explained.
2. Commits (short SHA and message), confirmed pushed.
3. `docs/redesign/proof/web-19/` with the file count and the states captured per surface.
4. Test counts: Vitest passed / failed / total vs the baseline total, lint errors and warnings, typecheck, `next build` result and time, e2e passed / failed.
5. The lowest `free -m` available value seen.
6. Open issues: backend fields that were missing (for example `generated_at` on recap `meta` or world recommendations), entry points an earlier step had not built, deviations with reasons.

Next prompt: `docs/redesign/prompts/web/20-cinematic-onboarding.md`
