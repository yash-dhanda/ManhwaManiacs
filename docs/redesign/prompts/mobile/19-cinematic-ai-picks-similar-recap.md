# mobile/19 · Cinematic AI: Picks, More like this and Previously on (new feature 1)

Step 56 of the redesign series (track `mobile`, group 5). Depends on `mobile/18-cinematic-settings-and-edition-restart.md` and `backend/05-ai-similar-recap-taste-onboarding.md`. Its twin `web/19-cinematic-ai-picks-similar-recap.md` builds the same feature on the web and may run at the same time in another session; you never touch `frontend/`.

## Goal

Deliver new feature 1 of the owner's decisions (AI home and recommendations, "because you read X", similar series and the "previously on" recap) on the Cinematic skin in Flutter for iOS and Android, phone and tablet, with the AI as the magazine's **editorial desk** that is visibly closed when it is unavailable, never broken. Build **Picks** at `/library/recommendations` (shell branch 2, mobile S11: the Ask block, the editors' suggestions as mini reviews, For you, Because you read rails, the Your genres slug line, dismiss and More-like-this on every card); **More like this** on the feature page's `03 MORE LIKE THIS` tab, in the chapter-end credits and in Quick look, and finish the **Because you read** rails on Tonight with in-session re-ranking; the **"Previously on" takeover** at `/recap/:sourceId/:seriesKey?to=:chapterKey` on the root navigator, a title card whose recap streams word by word from the server over SSE (read with the installed `dio` 5, `ResponseType.stream` and a `LineSplitter`, no new package) under a Bodoni drop cap, with a cast list, `Skip recap →`, and a 12 s auto-continue countdown with every pause rule; wire **every entry point** (Tonight, series pages, Continue buttons, cuttings, Quick look, the readers' first-page chip) through the per-profile `mm.recap.u{user}p{profile}` SharedPreferences key exactly as `glass/DESIGN.md` §15.6 resolves it; build the **fallbacks** for a closed desk; and apply the **§9.1.8 state vocabulary** (thinking, unavailable, partial, stale) identically on every AI surface, with `POST /ai/feedback` behind Not for me, More like this and rejected tags.

## Read first

1. `docs/redesign/cinematic/DESIGN.md`
   - **§9.1 in full**: §9.1.1 surfaces and entry points, §9.1.2 (the cover story and its recap case), **§9.1.3 Picks**, **§9.1.4 More like this and Because you read**, **§9.1.5 "Previously on"**, **§9.1.6 fallbacks**, §9.1.7 the backend contract (SSE framing, the no-stream JSON answer, stream headers, "Flutter uses the installed `dio` 5 with `ResponseType.stream` and a `LineSplitter`"), **§9.1.8 the AI state vocabulary and its copy**. Read every line.
   - §8.8 (Tonight: `Picked for you`, `Because you read`, `Where were we?`, the cover story's `Previously on…`, the now-showing strip), §8.14.2 (the Column wipe and the Dip into readers), §8.14.6 (chapter-end credits: caught up and the end), §8.17 (feature page: the actions row, `03 MORE LIKE THIS`, the DETAILS aside with suggested tags), §8.18 (book page: `Previously on…`), §8.25, §8.30.2 rows 03–04 (the recap setting's wording).
   - §2.1.4 (`scrim.foot.black`, `scrim.vignette`, the over-art rule and `on-art` controls), §2.1.5 (duotone), §2.5, §2.8, §3.2 (`type.headline`, `type.pull`, `type.field`, `type.dropcap`), §3.3 (caps), §4.2–§4.8 (incl. **Countdown**, **Type**, **Letter set**, word streaming 160 ms / 30 ms, the reduced-motion rows for the recap countdown), §5 (`tap.primary`, `select`, `longpress.open`, `undo`, `reader.enter`, `recap.countdown.end`), §7.1 (`split`, `on-art`), §7.2, §7.4 (the `index` field in prompt mode), §7.5 (segmented control), §7.6 (**World card**: Available, Information-only and Shelf variants, the certificate rule), §7.7, §7.8 (rails and their AI states), §7.9, §7.11, §7.12, §7.19 (`PICKED 3 DAYS AGO`), §7.22 (Quick look and its `Previously on` row), §7.23, §7.27, §7.29, §10.1 (letter-reveal triggers, incl. `signal` for the recap title; Flutter §10.1.6), §10.2 (typed lines; Flutter §10.2.4), §11, §13, §14.5 (timers wait for screen-reader users: `MediaQuery.accessibleNavigationOf`), §15.3, §15.5, §15.7 (the over-art table rows for the World card buttons and `Skip recap →`).
2. `docs/redesign/glass/DESIGN.md` **§15.6 (the recap setting row, binding)**, §15.5 (the device keys table), §8.25.16 (the mobile key `mm.recap.u{user}p{profile}`), §9.1 (only to keep the shared files skin-neutral: Glass calls the same recap, similar and feedback functions with `shape=deck`).
3. `docs/redesign/inventory/00-decisions.md` (new feature 1; "External AI API only. Design loading and 'AI unavailable' states").
4. `docs/redesign/stack-decision.md` §2.3, §2.6 (AI logic runs on the backend; clients only render).
5. `docs/redesign/inventory/mobile.md` S11 (every numbered element), S10 and S18 (series pages), S15 and S26 (readers), §4 (the calls).
6. `docs/redesign/inventory/capabilities.md` §8, §9 (recommendations and AI suggestions, `WorldItem`), §20 (OCR coverage behind manga recaps).
7. `docs/redesign/00-baseline.md`.
8. `docs/redesign/prompts-plan.json` (this entry and `mobile/08`, `mobile/11`, `mobile/12`, `mobile/14`, `mobile/16`, `mobile/18`, `backend/04`, `backend/05`), and the backend code `backend/05` added: `grep -rn "ai/recap\|ai/similar\|ai/feedback\|ai/tags\|library/suggest" backend/routes` (read the handlers and schemas so the Dart models match exactly).

## Skills to invoke, in this order

1. `superpowers:writing-plans`: plan to `docs/redesign/proof/mobile-19/plan.md`, one task per Scope item.
2. `superpowers:subagent-driven-development` (task groups A–H, one after the other; never two Flutter commands at once); `superpowers:executing-plans` if subagents are unavailable.
3. `impeccable:impeccable` and `taste-skill:taste-skill` while building; the contract wins on conflicts. `frontend-design:frontend-design` is for web UI; this step has none, so it is not invoked.
4. `superpowers:verification-before-completion` before claiming done.

## Before you start

- Branch `feat/vps-slim-source-native`; other sessions commit here: stage only your paths; never `git add -A`, `git stash`, `git reset`, `git checkout` on others' files.
- Stop and report if missing: `picks` and `recap` in the Cinematic `PENDING` set; `backend/05`'s `/ai/similar`, `/ai/recap/availability`, `/ai/recap` and `/ai/feedback` routes; `mobile/18`'s `mobile/lib/features/recap/recap_setting.dart` (if it is missing, create it here exactly as `mobile/18` item A2 specifies: key `mm.recap.u{user}p{profile}`, JSON `{mode: "off" | "ask" | "always", seriesDays, chapterDays, skipSeries[]}`, default `{"ask", 7, 3, []}`, plus `mm.recap.autoContinue.u{user}p{profile}` default `true`); `mobile/16`'s `genreWeightsProvider` and the §9.1.8 copy module (`grep -rln "The picks desk is closed tonight" mobile/lib`); the `mobile/16` scan widgets; the `mobile/08` Quick look actions, source-picker sheet and `homeFeedProvider`; the `mobile/06` takeover route builder and the `mobile/12` reader-entry kinds (Column wipe, Dip) in `GoRouterState.extra`.
- Read the legacy Picks screen only for its providers: `mobile/lib/features/library/screens/recommendations_screen.dart`, `widgets/recommendations/world_title_card.dart`, `providers/intelligence_providers.dart` (`recommendationsProvider`, `suggestAvailabilityProvider`, `suggestionsProvider`), `models/{world_item,suggestion}.dart`. Never import from `screens/` or `widgets/`.

## Ground rules for this step

- **Track rule.** Work in `mobile/` only; stage explicit paths; do not edit `design/`, `brand/`, `frontend/` or `backend/`.
- **Skin boundary** (`test/skins/import_boundary_test.dart`): Cinematic screens import only `features/*/{models,providers,repositories,services,store,queue,utils,controllers}`, `core/`, `shared/`, the generated contract and their own skin.
- **The AI stays server-side.** The client never calls an AI provider; it calls only the backend endpoints below and renders. Branch on the error `code`, never on the HTTP status (429 is both `ai_budget_exhausted` and `rate_limited`).
- **Shared logic in `features/`**, skin-neutral (no Cinematic copy or tokens), each file with a unit test.
- **Paths** from `Routes` in `mobile/lib/skins/contract.g.dart` (`picks`, `recap`, `reader`, `novel`, `feature`, `featureByFollow`, `discover`); extra query keys are added with `Uri.parse(Routes.x(…)).replace(queryParameters: …)`, never by concatenation.
- **Tokens only** in `lib/skins/cinematic/**`.
- **Never** edit `backend/connectors/`, never touch production containers or `/srv/manhwamaniacs/{app,data}`.
- **RAM guard.** `free -m` before every `flutter analyze`, `flutter test` and harness run; stop if `available` < 1024 MB; `pgrep -f "next build"` must print nothing; never two Flutter commands at once.

## Scope: every item this step delivers

Remove `picks` and `recap` from the Cinematic `PENDING` set when their screens are done. Picks registers its hardware-keyboard keys under the group `Picks`, the recap under `Recap`. Route focus lands on each level-1 heading ("Picks"; the recap's series title).

### A. Shared data-layer work (skin-neutral, unit-tested)

1. `mobile/lib/features/recap/sse.dart`: `Stream<SseEvent> parseSse(Stream<List<int>> bytes)` built from `utf8.decoder` (which keeps a multibyte character split across chunks intact) and `const LineSplitter()` (which handles `\n` and `\r\n`): an event ends at a blank line; `event:` names it (default `message`); one or more `data:` lines are joined with `\n`; lines starting with `:` are ignored; a trailing event without its blank line is dropped. Tests: an event split mid-line across chunks, a UTF-8 character split across chunks, multi-line data, CRLF, a comment line, a trailing partial event.
2. `mobile/lib/features/recap/repositories/recap_repository.dart` on the app's authenticated `dio` client (the same interceptors: Bearer, `X-Profile-Id`, `X-App-Version`): `availability({source, series, to})` → `GET /ai/recap/availability` → `RecapAvailability {available, reason: ok | no_dialogue | first_chapter | not_configured | budget_exhausted, range: {fromKey, toKey, fromNumber, toNumber}, estSeconds, cached}`; `open({source, series, to, CancelToken})` → `GET /ai/recap` with `Options(responseType: ResponseType.stream, headers: {'Accept': 'text/event-stream, application/json'})`: when the response `content-type` is JSON it reads the body and returns `RecapOpen.none(reason, retryAfter)` (`reason` among `not_configured`, `budget_exhausted`, `rate_limited`, `no_dialogue`, `first_chapter`; `retryAfter` from the `Retry-After` header); otherwise `RecapOpen.stream(events)` mapping `parseSse` output to `RecapMeta {range, cast: [{name, role}], sourcedFrom: ocr | text, generatedAt?}` (plus any fields `backend/05` added), `RecapDelta {text}`, `RecapDone`, `RecapError {code, message}`. Tests with a fake `HttpClientAdapter` for both kinds and for a mid-stream `error` event.
3. `mobile/lib/features/recap/providers/recap_providers.dart`: `recapAvailabilityProvider` (family by `RecapKey {source, series, to}`, `autoDispose`, kept alive 60 s after the last listener with `ref.keepAlive()` and a timer); `recapStreamProvider` (family, a `Notifier`) exposing `{phase: loading | streaming | done | none | error, reason, retryAfter, meta, words: List<String>, retry(), completeNow()}` (`completeNow` reveals every word already received and every word still to come the moment it arrives), cancelling its `CancelToken` on dispose.
4. `mobile/lib/features/recap/utils/should_open_recap.dart`: pure decisions over the `mm.recap` setting: `shouldOpenRecapFirst({setting, seriesId, lastReadAt, now, available})`: `false` when `seriesId` (`"{sourceId}:{seriesKey}"`) is in `skipSeries` or `mode` is `off`; with `always`, `true` when the last read was on a different local day and `available`; with `ask`, `true` when the gap is at least `seriesDays` days and `available`. `mayAutoOpen({setting, seriesId, lastReadAt, now})` (the same checks without availability: whether a `Continue` whose item carries no `recap` must ask the endpoint first). `chipVisible({setting, lastReadAt, now, available})`: the gap is at least `seriesDays` when `mode` is `ask`, or at least 14 days when `mode` is `always` or `off`, and `available`. Skipping and allowing a series use `recapSettingProvider.skip` / `allow` (`mobile/18`). Tests for every branch, including day boundaries in the local timezone (`DateTime.toLocal()`).
5. `mobile/lib/features/recap/models/recap_origin.dart`: `RecapOrigin {entry: wipe | dip | reader, returnTo}` passed in `GoRouterState.extra` when navigating to a recap; `RecapOrigin readRecapOrigin(Object? extra)` returns it, or `{entry: dip, returnTo: Routes.tonight}` for a cold deep link. Test.
6. `mobile/lib/features/recap/utils/recap_countdown.dart`: a reducer for the 12 s countdown: state `{remainingMs, running, pausedBy: Set<PauseReason>}`, reasons `pointerContinue`, `pointerText`, `pointerCast` (trackpad or mouse hover on iPad and Android tablets), `touch`, `focusText`, `focusCast`, `hidden` (app not `resumed`), `space`, `key` (a hardware key other than `Space`, `Enter`, `s` and `Esc`); actions `start`, `tick(ms)`, `pause(reason)`, `resume(reason)`, `reset` (scrolling back up), `toggleSpace`; `space` is the only reason `toggleSpace` clears, and `key` stays until `Space` resumes. The countdown never starts while a screen reader is running (`MediaQuery.accessibleNavigationOf(context)`, checked by the screen). Tests: never below 0, each reason pauses, reset returns to 12,000 ms, `key` needs `Space`.
7. `mobile/lib/features/ai/utils/ai_state.dart`: `AiState aiState({loading, available, reason, errorCode, generatedAt, now, partial})` → `{state: thinking | ready | unavailable | partial | stale, reason}`; `int? staleDays(DateTime? generatedAt, DateTime now)` → `null` under 24 h, else `max(1, hours ~/ 24)`. Tests, including a 429 with `code: rate_limited` versus `code: ai_budget_exhausted`.
8. `mobile/lib/features/ai/`: `similar({source, series} | {anilistId}, {bool fallbackGenres = false})` → `GET /ai/similar` (`fallback=genres` returns items with `why: null` and `basis: "genres"`, restricted to the profile's sources; type the items exactly as the `backend/05` schema) and `similarProvider` (family); feedback and tags: reuse what `mobile/08` built (`POST /ai/feedback` on `aiRepositoryProvider` in `repository_providers.dart`) and `mobile/11`'s suggested-tags call (`GET /ai/tags`), adding `similar` to that same repository (extend the `similar` method `mobile/12` added there for Up next rather than adding a second one), and adding `aiFeedbackProvider` (a mutation for `POST /ai/feedback {signal: not_interested | liked_pick | tag_rejected, anilist_id?, source_id?, series_key?, tag?}`) only if none exists; `dismissedPicksProvider` (a kept-alive set per profile for the app session, cleared through `profileScopedInvalidators`), so a card dismissed on Picks is also gone from Tonight's rails until the app restarts. Tests for the request builders and the dismissed set.
9. `mobile/lib/features/library/repositories/library_repository{,_impl}.dart`: `localSuggest({prompt, limit = 6})` → `POST /library/suggest` (read its response model in `backend/routes/library.py` and type it exactly; items are `kind: "source"` rows with `why`, plus `remaining_today`), and `localSuggestionsProvider` (an `AsyncNotifier` shaped like `suggestionsProvider`, which stays for `FROM EVERYWHERE`). Test the parser.
10. `mobile/lib/features/home/utils/rerank.dart`: in-session re-ranking (§9.1.4): `rerankNotesProvider` (kept alive for the app session) with `noteOpenedFromRail(String topGenre)` (unique, newest last) called when the reader opens a series from a Tonight rail; `List<R> rerankRails<R>(List<R> rails, List<String> noted, String? Function(R) topGenre)` moving each rail whose top genre matches a noted genre up by one position (newest noted genre applied last), never above the cover story or `Continue`. Tests.

### B. Picks (`/library/recommendations`, ScreenId `picks`), §9.1.3, mobile S11

Data: `recommendationsProvider` (world recommendations: `for_you`, `sections[]` with `because`, `unavailable_reason`, `generated_at` when present), `suggestAvailabilityProvider` (`available`, `reason`, `remaining_today`, `daily_ceiling`), `suggestionsProvider` and `localSuggestionsProvider`, `genreWeightsProvider`, `dismissedPicksProvider`, `aiFeedbackProvider`.

**Phone (< 600 dp):**
1. Masthead: kicker `No. 12 — PICKS`, title "Picks" (`SetHeading` level 1, trigger `mount`), deck by state: "Describe it in your own words. Suggestions are weighed against what you already read." (AI available) / "The picks desk is closed tonight. Asks reset at midnight UTC. The picks below still work." (budget spent) / "Titles from everywhere, picked from what you read." (no ask). When the recommendations carry a `generated_at` older than 24 h, the `PICKED 3 DAYS AGO` micro badge (1 px `ink.45` outline, `type.micro`) sits beside the deck; payloads without `generated_at` are never marked stale.
2. **Ask block** (only while AI is available and configured): the `index` field in prompt mode, a multi-line `TextField` (`minLines: 1`, `maxLines: 4`, then it scrolls) at the phone `type.field` size (Bodoni Moda Italic 28/36, cap 1.3; typed text in Roman), semantics label "Describe what you feel like reading", `textInputAction: TextInputAction.send`; its hint is typed at 50 ms per grapheme and cycles every 6 s through "A murim regressor who comes back stronger", "Magic academy, but the lead is already strong", "Something slow and political, not a power fantasy" (an `ExcludeSemantics` layer; `hintText` holds the first example); the keyboard's send key submits; on a hardware keyboard `Enter` submits and `Shift+Enter` inserts a newline (`Shortcuts` on the field); 3–600 characters, with the folio `12 / 600` (`type.folio` `ink.45`) at the right under the underline; the three examples also as a slug line of `quiet` chips that fill the field and submit; `Ask the editors` (primary, `sparkle` 20 Regular, disabled until the prompt is valid, loading segment while asking; haptic `tap.primary`); the quota folio `8 ASKS LEFT TODAY` shown when `remaining_today` ≤ 10; the source toggle as a segmented control `FROM YOUR SOURCES │ FROM EVERYWHERE` (default `FROM EVERYWHERE`; `POST /library/suggest` vs `POST /library/world/suggest`; haptic `select`). Arriving with `?ask=1` (Discover's `Ask`, `mobile/16`) focuses the field.
3. **Your genres** under the ask block: a weighted slug line from `genreWeightsProvider(40)` (`mobile/16`), four sizes by weight quartile (12 / 14 / 17 / 20 px, Archivo wdth 75, wght 600, uppercase, +0.10em, line height 24; cap 1.5), the top quartile `ink.100` and the rest `ink.60`; each genre `go`es to `Routes.discover` with `?genre={name}` (Discover opens that genre's sheet). Hidden when there are no weights.
4. **Results** (after an ask): kicker `THE EDITORS SUGGEST`, then result cards as **mini reviews** in one column: World cards (§7.6) with the `why` as a Newsreader italic pull quote on a 2 px `spot` left rule; `FROM YOUR SOURCES` answers use the World card's **Shelf** variant. **Thinking:** the line "Reading your shelf…" typed at 50 ms per grapheme, a 24 px leader dial after 1 s; when the answer lands, each card fades in over 160 ms, 30 ms after the previous. **After 40 s** with nothing back, the timeout copy replaces the thinking line: "The editors took too long. Try a shorter description." + `Try again`; the request is **not** cancelled, so a late answer still renders its cards and removes the timeout copy; `Try again` cancels the running request (`CancelToken`) and asks again; the field keeps its text. `remaining_today` refreshes after every answer.
5. **`01 For you`** (H3 section head, `SetHeading` trigger `inView`): a two-column grid of World cards from `for_you` minus dismissed items.
6. **`02 Because you read {title}`, `03 …`**: one `CineRail` of World cards per `sections[]` entry (3.2 visible posters; 2.3 at text scale ≥ 1.3); the H3 sets the seed title in Bodoni Moda **Roman** inside the italic head through `SetHeading`'s roman span (`mobile/08`): "Because you read" italic, "Solo Leveling" roman.
7. **Tablet (600–1023 dp, §8.0.9):** the ask block across the 8 columns with the field at 32/40; For you 2 per row, 3 from 900 dp; results in two columns; the genres line under the ask block; rails at 5.2 visible.
8. Pull to reprint refetches the world recommendations and the suggest availability, never re-asking the AI (haptic `refresh.arm`).
9. **World card behaviour** (every AI card in the app uses the same widget, `mobile/lib/skins/cinematic/primitives/world_card.dart`, extended from `mobile/04` if it lacks these):
   - Available: the whole card opens the series (`Routes.feature`), through `mobile/08`'s source-picker sheet when several sources have it (logos, names, health marks, `Open`).
   - Information only (duotone poster, credit `NOT ON YOUR SOURCES` in `ink.45`): `Search my sources` (`quiet`, `go` to `Routes.discover` with `?q={title}`) and `Read on {site} ↗` (`quiet`; `launchUrl(uri, mode: LaunchMode.externalApplication)`; a `false` result toasts "Couldn't open {url}").
   - **Not for me** and **More like this** live in three places: the long-press menu (450 ms, haptic `longpress.open`: `Not for me`, `More like this`, and `Open` or `Search my sources`), a trailing `dots-three` (`bare`, 20 Regular, 44 pt / 48 dp hit) on the card's credit line that opens the same menu (the visible alternative to the long-press, §14.8), and two `on-art` icon buttons at the poster's top-right that show while the card has keyboard focus or a trackpad or mouse hovers it (`MouseRegion`, `Focus`): `x` (40 px square, `color.onart` fill, 20 Regular `ink.100`, 44/48 hit, label "Not for me") and `thumbs-up` beside it (label "More like this", `Semantics(toggled:)`).
   - Not for me (also `Delete` on a focused card): the card fades out over 240 ms (`durLine` `easeLift`) and the grid closes the gap by a Cut; `POST /ai/feedback {signal: "not_interested", anilist_id}` (or `source_id` + `series_key` for Shelf items); the item joins `dismissedPicksProvider`.
   - More like this: switches to the Fill glyph with a 2 px `spot` rule 4 px under the square, haptic `select`, sends `signal: "liked_pick"`, toasts "Noted. Picks will lean this way."; pressing it again clears it locally (no request).
   - With the profile's gate open, the 16 px certificate on its `#000000` fill sits top-left on the poster when `is_adult` is true or any `available[]` source is mature; with the gate closed such items are absent.
10. **Hardware keys:** `/` focuses the ask field; `Enter` asks; `j` / `k` move through the cards in reading order; `Delete` is Not for me on the focused card.
11. **States** (each built, widget-tested and captured):

| State | Presentation |
|---|---|
| Loading world recs | Masthead live; the `01 For you` header with 6 flicker plates (after the 120 ms skeleton delay) |
| AI thinking | "Reading your shelf…" typed, the leader after 1 s, the cards fade in |
| AI not configured (`reason: not_configured`, or an ask answering `ai_not_configured`) | The ask block replaced by a `NOTE` line "The editors' desk isn't set up on this server."; world recs still show |
| Budget spent (`budget_exhausted`, or `ai_budget_exhausted`) | The ask field disabled; the quota folio reads `0 ASKS LEFT TODAY`; the caption "The picks desk is closed tonight. Asks reset at midnight UTC." |
| Shelf too thin (`suggest_shelf_empty`, 409) | Notice `NOTHING TO PICK FROM YET`: "There isn't enough in the catalogue cache yet. Browse a few sources, then ask again." + `Browse sources` (`go` to `Routes.sources`), and a `quiet` `Ask everywhere instead` that switches the toggle to `FROM EVERYWHERE` |
| Ask failed (`ai_failed`, 502) | "The editors couldn't answer that one. Try describing it differently." + `Try again`; the field keeps its text |
| No matches (`ai_no_matches`) | A notice in the results slot: "Nothing fit that description. Try describing it differently." |
| Rate limited (`rate_limited`, 429 with `Retry-After`) | `SLOW DOWN`: "Too many asks at once. Try again in {n} s." with the live countdown |
| World catalogue unreachable (`unavailable_reason`) | A quiet caption under the masthead with the server's reason; cached recs shown |
| Partial | Loaded sections render; a failed AI section is omitted, the folios renumber, and the grid shows "Some picks didn't come through." |
| Stale | `PICKED 3 DAYS AGO` beside the deck (item 1) |
| Empty (new profile) | Notice `NOTHING TO GO ON YET`: "Read or follow a few series first. Picks start from what you read." + `Find something` (`go` to `Routes.discover`) |
| Offline / error | `OFFLINE EDITION` / `CORRECTION` notices with `Try again` |

### C. More like this, Because you read and suggested tags (§9.1.4, §8.17)

1. **Feature page tab `03 MORE LIKE THIS`** (append it to the tab builder list in `mobile/11`'s `feature_tabs.dart`, which is built so this step adds tab 03 without renumbering): a `Similar` rail from `similarProvider({source, series})` (World cards in poster form; the `why` line shows in Quick look and as a one-line caption under the poster), then a `Because you read {title}` rail when a world-recommendations `sections[]` entry has this series as its `because` seed. States by §9.1.8: thinking (the H3 renders and a typed line "Finding series like this one…" with the leader after 1 s), unavailable (the H3 stays, the `NOTE` line with the copy for `reason` + "Here are series from the same genres.", and the fallback rail from `similarProvider(…, fallbackGenres: true)` whose cards carry the caption `SAME GENRES` instead of a `why`), stale (`PICKED 3 DAYS AGO` beside the H3 when `generated_at` is older than 24 h), empty ("Nothing similar on your sources yet." in `type.body.italic` `ink.45`). Add support for the feature route query `?tab=more-like-this` selecting tab 03 (Quick look's `More like this` uses it) if `mobile/11` has none.
2. **Chapter-end credits** (the `mobile/12` reader credits in `mobile/lib/skins/cinematic/screens/reader/`): the caught-up notice gets the `More like this` rail (Similar, with the genre fallback); **the end** (a Completed series finished) gets the `Up next` rail through `mobile/12`'s `mobile/lib/features/library/providers/up_next_provider.dart` and `up_next_rail.dart`: verify its chain is Similar first (with the genre fallback), then the Because-you-read world section, then `From your shelf` (plan-to-read and favourites from the library), and that it uses `similarProvider` from A8 rather than a second request; fix only what differs.
3. **Quick look** (`mobile/05`'s sheet with `mobile/08`'s action list): add `More like this` (pushes the feature page with `?tab=more-like-this`) and `Not for me` rows on AI-picked items.
4. **Tonight** (`mobile/08`): audit and finish the `Picked for you` and `Because you read` rails against §9.1.8 and §9.1.6: the H3 sets the seed title roman inside the italic head; the rails hide dismissed items; the unavailable state keeps the header with the `NOTE` line (the copy for `ai.reason` followed by "Here is your shelf instead.") and replaces `Picked for you` with `From your shelf` (favourites and plan-to-read, same position); a failed AI rail is omitted and the folios renumber; the stale badge follows `generated_at`. Apply `rerankRails()` to the rail order and call `noteOpenedFromRail()` when a series opens from a rail.
5. **Suggested tags** (feature page DETAILS aside, §8.17 item 4): verify `mobile/11`'s line against this item and §9.1.8 and complete it; if `grep -rn "ai/tags" mobile/lib` finds no Cinematic use, build it: when the AI desk is available, a `SUGGESTED` kicker line follows the own tags with up to 5 suggested tags from `GET /ai/tags?source&series` as dashed-outline tokens (a `CustomPainter` dashed rectangle, 1 px `rule.2`, dashes 4 on 3 off, 28 px tall inside a 44/48 hit), each with `+` to accept (it becomes an own tag through the existing tag API; haptic and sound `select`) and `x` to reject (`POST /ai/feedback {signal: "tag_rejected", source_id, series_key, tag}`, the token fades 160 ms); the line is absent when the desk is closed or nothing is suggested.

### D. "Previously on" (`/recap/:sourceId/:seriesKey?to=:chapterKey`, ScreenId `recap`), §9.1.5

A **Takeover** on the root navigator (no thumb index, no running head; Dip in and Dip out through the `mobile/06` takeover route builder), set as a title card. The screen reads `to` from the query and the origin from `readRecapOrigin(state.extra)`.

1. **Layout:** background `#000000`; the series cover as a duotone band across the top 34 % of the viewport height on phones (28 % from 600 dp), `Image(fit: BoxFit.cover)` duotoned to the series' `ambient.duo` (fallback `#B8B2A4`) with `duotone.dart`, `scrim.vignette` over it and `scrim.foot.black` over the band's bottom 60 % (reaching `#000000` at its bottom edge), both from the `mobile/04` scrim helpers, and grain at 0.05 opacity (`shaders/grain.frag`, jittering at 12 fps; static under reduced motion; `TickerMode` off screen). Kicker `PREVIOUSLY ON` (`SetHeading` trigger `signal`), then the series title in Bodoni Moda Italic at the `type.headline` size (32/36 phone · 44/48 tablet, −0.030em, cap 1.15) with the letter reveal (`signal`), as the level-1 heading; the deck "Chapters 131–142, as a recap." (`type.deck` `ink.60`; one chapter: "Chapter 142, as a recap.").
2. **The recap:** 3–5 paragraphs in Newsreader 18/28 on phones and 20/32 from 600 dp, at most 58 ch wide, `ink.100` on phones and `ink.80` from 600 dp, streamed word by word (each word fades in over 160 ms, 30 ms after the previous); a Bodoni Moda drop cap (Roman, wght 800) on the first paragraph at 3 × its line height (84 px on 28 px leading, 96 px on 32 px): `mobile/lib/skins/cinematic/screens/recap/drop_cap_paragraph.dart` lays the cap in a box beside the paragraph's first three lines, measuring with a `TextPainter` how much of the text fits three lines at `width − capWidth − 8`, breaking on a word boundary, and sets the rest at full width below (re-measured as words stream; unit-test the split). Names from `meta.cast` are italic wherever they occur as whole words. While streaming the text block is `ExcludeSemantics`; when complete it becomes one `Semantics(label: fullText)` and the full text is announced once (`SemanticsService.announce`), never word by word.
3. **Cast list** (when `meta.cast` is not empty): kicker `CHARACTERS IN THIS STORY`, credits rows `Kim Dokja ........ the reader` (name, dot leaders, role).
4. **Footnote** (`type.caption` `ink.60`): "Recap written from the dialogue of chapters 131–142." (`sourcedFrom: ocr`) or "Recap written from the text of chapters 131–142." (`text`), then " AI-written; it can be wrong." When `meta` carries a `generatedAt` older than 24 h, " Recap written 3 days ago." is appended (without that field, no stale line).
5. **`Skip recap →`** (visible from t = 0): an `on-art` button (§7.1: `color.onart` fill, 1 px `ink.100` outline at 40 %, `ink.100` text, 44 pt / 48 dp hit) 16 px from the right edge and `MediaQuery.viewPaddingOf(context).top + 8` from the top. It goes straight to the reader by the recap's way in (item 8) and never waits for the stream.
6. **Actions** (a sticky `#000000` bar at the bottom on phones with a 1 px `rule.1` top and the bottom safe-area padding; inline under the text from 600 dp): `split` primary `Continue │ CH 143` (48 dp phone, 56 tablet; usable from t = 0; haptic `tap.primary`), `quiet` `Skip recaps for this series` (`recapSettingProvider.skip`; toast "Recaps are off for {title}." + `Undo` for 8000 ms, which calls `allow`; haptic `undo` on Undo), `quiet` `Close` (back to `returnTo` by Dip).
7. **Tablet grid:** the recap in columns 1–6 and the cast list in 7–8 from 900 dp; below the recap under 900 dp.
8. **Way into the reader** (from `Continue`, `Skip recap →` and the countdown): origin `wipe` (opened from Tonight or a series page) → the **Column wipe** into the reader at `to` (phone 248 + 40 + 328 = 616 ms with 4 blades; tablet 312 + 40 + 392 = 744 ms with 8 blades; blades `easeSettle`, 16 ms stagger; haptic `reader.enter`, the `wipe` pattern, when the blades land; sound `wipe`); origin `dip` → the **Dip** (160 / 40 / 240 ms); origin `reader` → a Dip back to `returnTo` (the open page: pop the takeover). Novels open the novel reader. `recap.countdown.end` has no haptic and no cue.
9. **Auto-continue countdown** (only when `recapAutoContinueProvider` is on, default on): when the stream is `done`, `Continue` starts a 12 s countdown (`durCountdownRecap`): a 2 px `spot` rule inside the split button's bottom edge drains from full to empty (`easeLinear`) and the folio segment reads `CH 143 · 12 S`, counting down each second; at zero the reader opens by item 8. It **pauses** (A6) while a finger touches the screen (a `Listener` counting pointers), while a trackpad or mouse hovers `Continue`, the recap text or the cast list, while hardware-keyboard focus is inside the recap text or the cast list, while the app is not `resumed` (`AppLifecycleListener`), and after any hardware key other than `Space`, `Enter`, `s` and `Esc` until `Space`; it never starts while a screen reader is running (`Continue` waits). When it first starts, `SemanticsService.announce("Continuing to chapter 143 in 12 seconds. Press Space to pause.")`. Scrolling back up in the recap resets it to 12 s. With the setting off, no countdown runs and `Continue` waits.
10. **Hardware keys:** `Enter` continue; `s` skip the recap (straight to the reader); `Esc` close; `Space` completes the streaming at once (`completeNow`) and, once the recap is complete, pauses or resumes the countdown. Android back closes the takeover (Dip back to `returnTo`).
11. **States:**

| State | Presentation |
|---|---|
| Loading | The title card with kicker and title set; "Writing the recap…" typed at 50 ms per grapheme; a 24 px leader after 1 s |
| Streaming | Words fade in; `Continue` and `Skip recap →` usable at any time |
| Done | The countdown runs, paused by the rules above |
| No recap (`no_dialogue`, as the JSON answer or a stream `error`) | Kicker `NO RECAP FOR THIS ONE`; "The dialogue in these chapters hasn't been read yet, so there's nothing to recap." + `Continue │ CH 143`; when some of the range's chapters are saved manga chapters and on-device OCR is available, also `Scan saved chapters` (secondary): it runs `OcrRunController` over those chapters and shows the `mobile/16` `DialogueScanBlock` inline; when the scan is done the screen offers `Try the recap again` |
| Unavailable (`not_configured`, `budget_exhausted`, `rate_limited`) | A static slate: kicker `RECAP UNAVAILABLE` in `ink.45` (not a `NOTE`, never `proof`); "Pick up where you left off: chapter 143." + `Continue`; rate limited adds `SLOW DOWN` "Too many asks at once. Try again in {n} s." with the live `Retry-After` countdown |
| First chapter (`first_chapter`) | No slate: straight to the reader by item 8 |
| Offline | The unavailable slate with the `OFFLINE EDITION` kicker |
| Error | A `CORRECTION` line + `Try again` + `Continue` |
| Not available (`series_not_found` / `source_not_found` / gated) | The §8.0.10 notice `NOT IN THIS ISSUE` |

### E. Entry points and the `mm.recap` setting

Every `Previously on…` button and the reader chip render **only** when the availability says `available`. The setting is read from `recapSettingProvider` (`mm.recap.u{user}p{profile}`, exactly the glass §15.6 shape; Cinematic `NEVER` / `ALWAYS` / `AFTER N DAYS AWAY` = `off` / `always` / `ask` + `seriesDays`), never from the server.

1. **One helper for every Continue**: `mobile/lib/skins/cinematic/recap/continue_to.dart` (built on `mobile/06`'s one reader-entry helper, `enterReader(context, target, entry: …)` in `mobile/lib/skins/cinematic/navigation.dart`, for the Column wipe and the Dip) exporting `Future<void> continueTo(BuildContext context, WidgetRef ref, {sourceId, seriesKey, chapterKey, title, lastReadAt, RecapAvailability? recap, required RecapEntry origin})`: when `shouldOpenRecapFirst(…)` with the item's `recap` is true, it pushes the recap with `RecapOrigin(origin, returnTo: current location)` by Dip; when the item carries no `recap` and `mayAutoOpen(…)` is true, it calls `availability` on press with a **400 ms** timeout and opens the recap only on an `available` answer in time; otherwise it opens the reader with the origin's transition (Column wipe for `wipe`, Dip for `dip`). Route every `Continue` split button and cutting in the Cinematic skin through it (`grep -rn "Continue" mobile/lib/skins/cinematic/screens`): Tonight's cover story and now-showing strip (`wipe`), Tonight's `Continue` cuttings (`wipe`: §8.14.2 lists "a cutting" and "a rail's Quick look `Continue`" among the Tonight entries that play the Column wipe, as `mobile/12` item C6 wires them), Library's Continue rail cuttings (`dip`), Quick look `Continue` (`wipe` when the Quick look was opened on Tonight, `dip` everywhere else), the feature and book pages' split button (`wipe`). Widget-test the three branches with a fake repository and a fake clock.
2. **Tonight** (`mobile/08`): the cover story's `Previously on…` (secondary, when `cover.recap.available`), the now-showing strip's `Previously on` (`quiet`, in its overflow), and `Where were we?` long-press offering `Previously on` first (when that item's `recap.available`): all open the recap with origin `wipe` (a recap opened on Tonight continues by the Column wipe, §9.1.5 "Entry behaviours"; rail items included).
3. **Feature page and book page** (`mobile/11`): the `Previously on…` secondary in the actions row (and `p` on a hardware keyboard), when `recapAvailabilityProvider({source, series, to: the continue chapter})`, read once on load, answers `available`; origin `wipe`.
4. **Quick look** on cuttings and posters: the `Previously on` row when the item's `recap.available`; for items without `recap`, call the endpoint when Quick look opens and add the row only on an `available` answer, never holding the other rows; origin `wipe` when the Quick look was opened on Tonight, `dip` elsewhere (§9.1.5: "a Library cutting's Quick look" continues by a Dip).
5. **The readers' first-page chip** (the manga reader chrome from `mobile/12`, the novel reader chrome from `mobile/14`): on the first page of a chapter, a slim `quiet` chip `PREVIOUSLY ON · {ceil(estSeconds / 60)} MIN` (e.g. `PREVIOUSLY ON · 2 MIN`, spoken "Previously on, 2 minutes") under the running head when `chipVisible(…)` is true (the reader reads the availability once on its first page); it opens the recap with origin `reader` and `returnTo` = the current reader location; it hides with the chrome like the rest of the running head.

### F. Fallbacks when the AI desk is closed (§9.1.6)

Verify each and fix what is missing: Tonight's cover story uses the local priority rules (§9.1.2 cases 1–3, else the most recently updated followed series) with the synopsis as the deck; `Picked for you` becomes `From your shelf` under the `NOTE` line; `Almost there`, `Where were we?` and `Sent to you` stay; Because-you-read rails come from world recommendations when that catalogue is reachable, otherwise they are omitted; Picks shows world recs without the ask block; recaps show the static slate; Similar uses the genre fallback.

### G. The §9.1.8 state vocabulary on every AI surface

Every AI-backed surface is in exactly one of thinking, unavailable, partial or stale (through `ai_state.dart`) and uses the copy module found in "Before you start" (extend it; never create a second one): Tonight's `Picked for you` and `Because you read`, Picks (ask, results, For you, Because you read), Discover's `ASK` scope and `ASK THE EDITORS` block (`mobile/16`), Similar (feature tab, credits, Quick look), suggested tags, and the recap. **Thinking** is always a typed line plus a leader dial after 1 s, then words (160 ms, 30 ms apart) or cards (160 ms, 30 ms apart): never a spinner and never a skeleton that pretends content exists. **Unavailable** is a `NOTE` kicker in `spot` with the reason in `type.caption` `ink.60`, never `proof`, always beside the non-AI path (the recap slate's `RECAP UNAVAILABLE` stays `ink.45`). **Partial** omits what failed and renumbers folios. **Stale** is `PICKED {n} DAYS AGO` (or `PICKED 1 DAY AGO`) beside the H3, the Picks deck or the recap footnote.

### H. Cross-cutting

- **Reduced motion** (`CineMotion.reduced(context)`): letter reveals fade 200 ms; typed lines and hints show at once with no caret; streamed words appear with no per-word fade (still in order); card fade-ins become one 160 ms fade; the countdown shows no draining rule, only the folio updated once per second; the Column wipe and Dip become a 200 ms / 150 ms cross-fade; grain is static; a dismissed card disappears with a 150 ms fade; programmatic scrolls jump. Leader dials keep running.
- **Screen readers:** the countdown never starts while one is running; streamed text is announced once when complete; every icon-only control has a label.
- **Focus (hardware keyboard):** `CineFocusRing` on every control, including over the cover band (the 6 px black band); the recap's initial focus is its level-1 heading; `Esc` closes the takeover.
- **Hit targets:** 44 × 44 pt iOS, 48 × 48 dp Android (the World card's `dots-three`, `x` and `thumbs-up`, `Skip recap →`, the reader chip, the tag tokens).
- **Contrast:** `Skip recap →` and the World card's on-art buttons sit on `color.onart` (`ink.100` on 0.64 black reaches 5.89:1 over `#FFFFFF`); the recap text sits on `#000000` below the band.
- **Haptics and sound:** `tap.primary` on `Ask the editors` and `Continue` (sound `set`); `select` on the source toggle, More like this and tag accept (sound `tick`); `longpress.open` on card menus; `undo` on Undo; `reader.enter` on a Column-wipe exit (sound `wipe`); nothing on `recap.countdown.end`; `refresh.arm` on pull.

## Values you need (copied from `cinematic/DESIGN.md`)

| What | Value | Section |
|---|---|---|
| Inks and grounds | `paper.0` `#000000`, `paper.1` `#0B0B0A`, `paper.2` `#121211`, `ink.45` `#7A7770` (on `paper.0` only), `ink.60` `#9A978F`, `ink.80` `#C9C6BE`, `ink.100` `#F3F0E8`, `rule.1` `#2B2A27`, `rule.2` `#3D3C38` | §2.1.1 |
| Accent | `spot` `#F4D03F`, `spot.wash` `rgba(244,208,63,0.16)`; `color.onart` `rgba(0,0,0,0.64)`; `proof` `#FF5B4A` (errors only, never for AI unavailability) | §2.1.2–§2.1.4 |
| Scrims | `scrim.foot.black`: the 13 eased stops over the band's bottom 60 % to `#000000`, positions `0, 1.8, 4.8, 9, 13.9, 19.8, 27, 35, 43.5, 53, 66, 81, 100 %`, alphas `0, .002, .008, .021, .042, .075, .126, .194, .278, .382, .541, .738, 1`; `scrim.vignette` radial: transparent to 60 %, black at 0.45 at 100 %, centred 50 % / 40 %, 120 % × 90 % | §2.1.4 |
| Durations (`durX`) | type 50 per grapheme, caret 530, letter 640 (blur 440), line 240, beat 160, clip 200, reduced 150, countdownRecap 12000, holdToastAction 8000, wipeClose 200, wipeOpen 280, holdDip 40 (ms) | §2.8.4, §4.2 |
| Word streaming | each word 160 ms fade, 30 ms after the previous (`scalarStaggerWord`) | §4.6 |
| Column wipe | phone 248 + 40 + 328 = 616 ms (4 blades); tablet 312 + 40 + 392 = 744 ms (8 blades); blades `easeSettle`, 16 ms stagger | §4.5, §8.14.2 |
| Curves | `easeSettle` `Cubic(0.16, 1, 0.3, 1)`, `easeLift` `Cubic(0.7, 0, 0.84, 0)`, `easeTurn` `Cubic(0.65, 0, 0.35, 1)`, `easeLinear` `Curves.linear` | §4.3 |
| Type (phone / tablet) | `type.field` Bodoni Moda Italic 500 28/36 · 32/40; `type.headline` 32/36 · 44/48; `type.pull` Bodoni Moda Italic 500 24/32 · 28/36; recap body Newsreader 18/28 · 20/32; drop cap 3 × line height, Bodoni Moda wght 800 | §3.2, §9.1.5 |
| Grid | phone 4 columns, margin 16, gutter 12; tablet 8 / 32 / 16 | §2.2.2 |
| Hit areas | 44 × 44 pt iOS, 48 × 48 dp Android | §14.6 |

## File layout

```
mobile/lib/features/recap/sse.dart
mobile/lib/features/recap/repositories/recap_repository.dart
mobile/lib/features/recap/providers/recap_providers.dart
mobile/lib/features/recap/utils/{should_open_recap,recap_countdown}.dart
mobile/lib/features/recap/models/{recap_models,recap_origin}.dart
mobile/lib/features/recap/recap_setting.dart                        (from mobile/18; created here only if missing)
mobile/lib/features/ai/utils/ai_state.dart
the repository behind mobile/08's aiRepositoryProvider               (similar added; feedback and tags reused)
mobile/lib/features/ai/providers/ai_providers.dart                  (similarProvider, aiFeedbackProvider, dismissedPicksProvider)
mobile/lib/features/library/repositories/library_repository{,_impl}.dart   (localSuggest)
mobile/lib/features/library/providers/intelligence_providers.dart   (localSuggestionsProvider)
mobile/lib/features/home/utils/rerank.dart
mobile/lib/skins/cinematic/ai_copy.dart                             (or the module mobile/08 / mobile/16 created: extended, not duplicated)
mobile/lib/skins/cinematic/primitives/world_card.dart               (Not for me, More like this, dots-three menu, if not there)
mobile/lib/skins/cinematic/screens/picks/
  picks_screen.dart  ask_block.dart  editors_suggest.dart  for_you_grid.dart  because_rails.dart  genre_line.dart  picks_keys.dart
mobile/lib/skins/cinematic/screens/recap/
  recap_screen.dart  cover_band.dart  recap_text.dart  drop_cap_paragraph.dart  cast_list.dart  recap_actions.dart
  recap_slate.dart  recap_keys.dart
mobile/lib/skins/cinematic/recap/continue_to.dart
mobile/lib/skins/cinematic/screens/feature/…                         (03 MORE LIKE THIS, Previously on, suggested tags)
mobile/lib/skins/cinematic/screens/tonight/…                         (rails audit, rerank, entry points)
mobile/lib/skins/cinematic/screens/reader/…                          (the first-page chip, the credits rails)
mobile/lib/skins/cinematic/screens/novel/…                           (the first-page chip)
mobile/lib/skins/cinematic/router.dart                               (wire picks and recap, remove them from PENDING)
mobile/test/features/recap/{sse,recap_repository,should_open_recap,recap_origin,recap_countdown}_test.dart
mobile/test/features/ai/{ai_state,ai_repository,dismissed_picks}_test.dart
mobile/test/features/library/local_suggest_test.dart
mobile/test/features/home/rerank_test.dart
mobile/test/skins/cinematic/picks/picks_screen_test.dart
mobile/test/skins/cinematic/recap/{recap_screen,drop_cap_paragraph,continue_to,countdown_pauses}_test.dart
mobile/test/skins/cinematic/feature/more_like_this_test.dart
mobile/test/screenshots/cinematic/mobile_19_ai_shots_test.dart
docs/redesign/proof/mobile-19/                                      (plan.md, screenshots, device-checklist.md, report.md)
```

These are the folders `mobile/08`, `mobile/11`, `mobile/12` and `mobile/14` specify; if one of them landed elsewhere, `ls mobile/lib/skins/cinematic/screens` shows where, and you change it there.

## Commit plan (small commits, push after each)

1. `feat(mobile/19): sse parser and the recap repository` (A1–A3).
2. `feat(mobile/19): recap decisions, origin and countdown` (A4–A6).
3. `feat(mobile/19): ai state, similar, feedback, dismissed picks and local suggest` (A7–A9).
4. `feat(mobile/19): tonight rail re-ranking helper` (A10).
5. `feat(mobile/19): cinematic picks`.
6. `feat(mobile/19): more like this, because you read and suggested tags`.
7. `feat(mobile/19): previously on takeover`.
8. `feat(mobile/19): recap entry points and continue routing`.
9. `test(mobile/19): smoke tests and harness proof screenshots`.

`git add` exact paths; **no** `Co-Authored-By`, no "Generated with" line, no AI attribution; `git push origin feat/vps-slim-source-native` after each. Never commit secrets, `.env*` or `.claude/`.

Before every push: `git fetch origin` and `git diff --stat origin/feat/vps-slim-source-native...HEAD -- frontend`. The checkout is shared, so a push also carries other sessions' commits: if that diff lists files, run `free -m && npm run build` in `frontend/` first (never while a Flutter command runs, stop if `available` < 1024 MB) and push only if it passes, because a failed `next build` silently freezes the production deploy. Never deploy from this step.

## Acceptance criteria

- [ ] `picks` and `recap` are gone from the Cinematic `PENDING` set; the completeness and import-boundary tests pass.
- [ ] Picks renders every part of section B on phones and tablets, with every state in the table (harness screenshots of each).
- [ ] The ask field types its three examples cycling every 6 s, submits on the send key and on `Enter`, inserts a newline on `Shift+Enter` (hardware keyboard), shows `n / 600`, enforces 3–600 characters, and switches between `/library/suggest` and `/library/world/suggest` with the toggle; `?ask=1` focuses it.
- [ ] Thinking shows the typed line and the leader after 1 s; after 40 s the timeout copy appears without cancelling; `Try again` cancels and re-asks; a late answer still renders (widget test with a fake clock).
- [ ] Not for me fades the card, closes the gap, sends `not_interested` and hides the item on Tonight too for the session; More like this sends `liked_pick`, fills with the spot rule, fires `select`, toasts, and clears locally on a second press; both are reachable by long-press, by the visible `dots-three` and by `Delete` on a focused card.
- [ ] The feature page's `03 MORE LIKE THIS` shows Similar and the Because-you-read rail, or the `SAME GENRES` fallback under the `NOTE` line when the desk is closed; the credits' caught-up and the-end rails use the same data; Quick look offers `More like this`.
- [ ] Tonight's AI rails follow §9.1.8 and §9.1.6 and re-rank within the session after a series opens from a rail (unit test for `rerankRails`).
- [ ] The recap takeover streams the prose word by word beside the three-line drop cap, italicises cast names, lists the cast, shows the footnote, offers `Skip recap →` from t = 0, and continues by the Column wipe (origin `wipe`), the Dip (origin `dip`) or back to the open page (origin `reader`).
- [ ] The countdown runs 12 s only after the stream completes and only with `mm.recap.autoContinue` on, drains the 2 px rule, updates `CH 143 · 12 S` each second, pauses on touch, hover, focus, app background and a non-reserved hardware key, resets on scrolling up, announces itself once, never starts with a screen reader running (widget test with `accessibleNavigation: true`), and `Space` pauses and resumes it (unit test for the reducer; widget tests for touch and lifecycle pauses).
- [ ] Every recap state in D11 renders (fake repository), and a JSON no-stream answer maps exactly like the matching stream `error`; `Scan saved chapters` appears only with saved manga chapters and OCR available.
- [ ] `mm.recap.u{user}p{profile}` keeps exactly the glass §15.6 shape; `ALWAYS`, `AFTER N DAYS AWAY` and `NEVER` behave per §9.1.5 through `continueTo()`; `Skip recaps for this series` writes `skipSeries` and the series then behaves as `NEVER`; the reader chip shows `PREVIOUSLY ON · N MIN` only under `chipVisible`; a `Continue` without a `recap` field asks the endpoint only when `mayAutoOpen` and gives up after 400 ms.
- [ ] Every `Previously on…` entry renders only on an `available` answer.
- [ ] Every AI surface in section G uses the one state file and the one copy module; no AI state is drawn in `proof`; the client branches on `code`, never on the status.
- [ ] Reduced motion per section H (widget tests with `disableAnimations: true`: no draining rule, the folio still counts, the recap text appears without per-word fades, the hint is complete at once).
- [ ] Hardware keyboard: Picks keys (`/`, `Enter`, `j`, `k`, `Delete`) and recap keys (`Enter`, `s`, `Esc`, `Space`) work; every control is reachable with `CineFocusRing`; route focus lands on each level-1 heading.
- [ ] Hit targets: `meetsGuideline(iOSTapTargetGuideline)` (iOS), `meetsGuideline(androidTapTargetGuideline)` (Android) and `labeledTapTargetGuideline` pass on Picks, the recap and the feature tab.
- [ ] Contrast: `meetsGuideline(textContrastGuideline)` passes on Picks and the recap below the band; the on-art controls sit on `color.onart`.
- [ ] Per-skin difference: the Glass skin still maps `picks` and `recap` to its pending screen; every shared file (A1–A10) contains no Cinematic copy or tokens, so Glass (`mobile/41`) calls the same recap, similar and feedback functions with its own screens; the legacy Recommendations screen still works and its tests pass.
- [ ] `flutter analyze` reports no issues and `flutter test` passes: every test that passed at `00-baseline.md` (2012) and every test added since still passes.

## Verification

From `/srv/manhwamaniacs/dev/ManhwaManiacs`, one at a time, `free -m` first (stop if `available` < 1024 MB), `pgrep -f "next build"` empty:

```bash
free -m
node design/build.mjs --check
cd mobile
/srv/manhwamaniacs/dev/flutter/bin/flutter pub get
/srv/manhwamaniacs/dev/flutter/bin/flutter analyze        # baseline: "No issues found!"
free -m
/srv/manhwamaniacs/dev/flutter/bin/flutter test           # baseline: all 2012 passed; now baseline + every added test, 0 failed
```

`frontend/` and `backend/` are untouched; `git show --name-only --format= <hash> -- frontend backend` for each of your own commits (never a branch or range diff: parallel sessions commit on the same branch) must be empty, so the web checks (`npm run lint`, `npm run build`) and the backend pytest (`cd backend && .venv/bin/python -m pytest -q --no-header`) are not run in this step.

**Proof output location.** The `mobile/03` harness (`mobile/test/screenshots/support/skin_shots.dart`) writes a capture only when `MM_PROOF_DIR` is set, so every proof command below sets `MM_PROOF_DIR=../docs/redesign/proof/mobile-19` (relative to `mobile/`) and never `MM_WRITE_SHOTS`, which makes the legacy marketing tests overwrite `mobile/docs/screenshots/`, the install page's public screenshots. Capture routes with `captureSkinScreen` and anything that is not a route (a sheet held open, a state pumped with fixture providers) with `captureSkinWidget`, at the harness sizes: `kSkinShotSizes` (phone 390 × 844, tablet 834 × 1194), `kSkinShotTabletWide` (1024 × 1366, the ≥ 900 px rows of §8.0.9) and `kSkinShotLandscape` (landscape phone 844 × 390). After the run, `git status --short mobile/docs/screenshots` must print nothing.

**Visual proof.** Write `mobile/test/screenshots/cinematic/mobile_19_ai_shots_test.dart` on the `mobile/03` harness with the in-repo fixtures and a fake recap repository that serves a scripted SSE body (`event: meta`, `event: delta` × n, `event: done`) and JSON no-stream answers for `no_dialogue`, `budget_exhausted`, `rate_limited` with `Retry-After: 12`, and `first_chapter`. Capture at phone 390 × 844 and tablet 834 × 1194 logical px (the harness's sizes if `mobile/03` defined others): Picks thinking, results, the 40 s timeout, not configured, budget spent, shelf too thin, ask failed, no matches, rate limited, partial, stale, empty, a card's menu; the feature tab with Similar and with the genre fallback; the recap loading, mid-stream, done with the countdown at 7 s, no recap (with `Scan saved chapters`), unavailable, rate limited, error; the reader chip; plus a `-reduced` copy of Picks and the recap done state, into `docs/redesign/proof/mobile-19/{screen}-{state}-{phone|tablet}.png`:

```bash
free -m
cd mobile
MM_PROOF_DIR=../docs/redesign/proof/mobile-19 /srv/manhwamaniacs/dev/flutter/bin/flutter test test/screenshots/cinematic/mobile_19_ai_shots_test.dart
```

**Device checks** for the owner (`docs/redesign/proof/mobile-19/device-checklist.md`; iPhone via SideStore from the CI IPA, Android flagship from the CI APK, against the dev or production server with the AI key set): a real recap streaming word by word; the countdown pausing under a finger and when the app is backgrounded; VoiceOver and TalkBack: the countdown never starts and the finished text is read once; the Column wipe from a recap opened on Tonight and the Dip back from the reader chip; Not for me and More like this haptics; the ask field's send key.

## Report back

Reply with:
1. The acceptance checklist, each box ticked or explained.
2. Commits (short SHA and message), confirmed pushed.
3. `docs/redesign/proof/mobile-19/` with the file count and the states captured per surface.
4. Test counts: `flutter test` passed / failed / total vs the baseline total 2012, `flutter analyze` result.
5. The lowest `free -m` available value seen.
6. Open issues: backend fields that were missing (for example `generated_at` on recap `meta` or world recommendations), entry points an earlier step had not built, deviations with reasons.

Next prompt: `docs/redesign/prompts/mobile/20-cinematic-onboarding.md`
