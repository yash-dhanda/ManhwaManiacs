# Review: web track, slice 2 (web/12 to web/23)

Reviewed 2026-09-29 against `prompts-plan.json` (binding), `inventory/00-decisions.md`, `00-baseline.md`, `stack-decision.md`, `cinematic/DESIGN.md` (§4, §7, §8.14 to §8.31, §9, §11, §14), `glass/DESIGN.md` §15.4 to §15.6, the inventories, the neighbouring prompts (`web/03`, `web/04` to `web/11`, `backend/00`, `backend/02`, `backend/05` to `backend/07`) and the frontend checkout (`next.config.ts`, `src/config/env.ts`, `playwright.config.ts`, `package.json`). Every fix below was made in place in the prompt file named. No file of the slice was missing, so none was created.

## Result

All twelve files exist, follow the plan's scope and order, name their dependencies and the next prompt, list the required skills, carry checkbox acceptance criteria (reduced motion, web keyboard access, 44 px coarse and 32 px fine hit targets, a per-skin difference), a RAM guard, the no-attribution git rules and a Report back section. Values checked against DESIGN.md (durations, curves, springs, the Column wipe totals, sheet and panel specs, stock and speaker palettes, type sizes, the Lightbox, the heatmap geometry, token names) matched, apart from the items fixed below.

Four classes of defect were found and fixed:

1. **Proof runs could not reach the dev backend** (12 files). The web client defaults `NEXT_PUBLIC_API_URL` to `http://127.0.0.1:8000` (`src/config/env.ts`) and `BACKEND_INTERNAL_URL` to the same port (`next.config.ts`), and nothing listens there on this box. `web/12` to `web/19` started `next dev` without `NEXT_PUBLIC_API_URL=/api` (and `web/12` to `web/15` also without `BACKEND_INTERNAL_URL`), so every API call in the proof run would fail. `web/16` to `web/19` also carried a garbled "the README win if they differ) (the README wins" sentence.
2. **The "mobile and backend untouched" check was meaningless** (12 files). `git diff --stat -- mobile backend` shows only uncommitted changes; `git diff origin/…` is empty right after a push; `git diff <first commit>^..HEAD` includes the parallel mobile and backend sessions' commits on the same branch. `web/16` to `web/19` also omitted the exact Flutter and pytest commands.
3. **Cross-step conflicts** inside the slice: a duplicate `useGenreWeights` with two data sources, the Up next chain differing from DESIGN §9.1.6 and between `web/12` and `web/19`, ambient preference fields that `web/18` said `web/13` created (it does not), a novel "Auto next chapter" row rendered on the web although DESIGN makes it app-only, saved narration audio rows that `web/15` handed to `web/17` although DESIGN §8.23 makes them absent on the web, and a running-head button order that contradicted DESIGN §8.14.3.
4. **Gaps handed over by neighbours** that no slice file picked up: the book page "In the circle" avatars and the phone `SEND` button (handed to `web/22` by `web/11`), the palette's per-row `SETTINGS` group and `EDITION` group (handed to `web/18` by `web/06`), `VOICE_FIELD_ROWS` (handed to `web/15` by `web/04`), and the `#audiobook` deep link that `web/17` links to.

## Fixes applied to every file of the slice

| Fix | Files |
|---|---|
| Dev stack started with `free -m && backend/scripts/dev_stack.sh start` (seed once if needed; the script already sets novels on, rate limits off, AI key unset) and the web client with `cd frontend && free -m && NEXT_PUBLIC_API_URL=/api BACKEND_INTERNAL_URL=http://127.0.0.1:8010 npx next dev -p 3010`, with the reason both variables are required. The inaccurate "with `MM_NOVELS_ENABLED=1`" instruction removed. | 12, 13, 14, 15, 16, 17, 18, 19 (20 to 23 already had the right command) |
| The untouched check replaced by a per-commit check (`git show --name-only --format= <own SHA>` piped to `grep -E '^(mobile\|backend)/'` prints nothing), plus the exact baseline commands `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze`, `… flutter test` (2012 passed) and `cd backend && .venv/bin/python -m pytest -q --no-header`. | all 12 |

## Per-file findings and fixes

### web/12 manga reader 1: strip, chrome, ruler, credits

- **A4 slots duplicated `web/03`.** `web/03` A2 already made every in-strip decoration a slot of `ReaderSurfaceSlots` (`loading`, `error`, `empty`, `chapterDivider`, `head`, `tail`, `pagePlaceholder`, `brokenPage`); web/12 defined a parallel `renderPageState` / `renderBand` set. Fixed: A4 now maps each Cinematic element onto the existing slots, extends `StripEdge` and `brokenPage` where they lack arguments, and adds only `rateLimited`, `credits` and the presentation props.
- **K3 Up next chain differed from DESIGN §9.1.6.** "From your shelf" was "reading or plan-to-read with new chapters"; DESIGN says favourites and plan-to-read. The caught-up rail (DESIGN: Similar with the `SAME GENRES` fallback) and The end rail (Similar, else Because you read, else From your shelf) were one chain. Fixed: `useUpNext(sourceId, seriesKey, mode)` with the two modes, Because-you-read from `useWorldRecommendations()` (the §9.1.6 source), shelf = `is_favorite` or `plan_to_read`, and `up-next.test.ts` covering the order.
- **E4 trailing-button order.** The later steps were told to insert "after bookmark", which would put settings before the panel toggles. Fixed: E4 states the final §8.14.3 order (download, bookmark, guided view, `sidebar-simple`, `note-pencil`, settings, `dots-three`), the phone four, and that the `waveform` belongs to the title group.

### web/13 manga reader 2: paged, read-all, setup, panels

- **A4 duplicated engine state.** `readAll: { index, total, … }` repeated `web/03`'s existing `chapterPosition`. Fixed: fill `chapterPosition`, add only `readAllBoundaries`.
- **D1, E1, F1 insertion points** aligned with the order in web/12 E4 (settings after `note-pencil` on tablets and desktop; `note-pencil` right after `sidebar-simple`; `dots-three` last, named as the §11 "running-head overflow" alternative).
- Kept, flagged in its Report back: the phone non-gesture path for page actions (a `Page actions for p. 18` button in the setup sheet footer) fills a DESIGN gap, since §8.14.3 allows only four trailing buttons on phones.

### web/14 novel reader "The page"

- **Margins panel scope.** It said desktop and tablet with `m` on both; DESIGN §8.15.3 makes it desktop only. Fixed in F4 and the key table (1024 px and wider).
- **Top-bar insertion points.** Stated the §8.15.3 order and where `web/15` (voices, after bookmark) and `web/23` (`waveform`, after the offline mark) insert.
- **"as needed"** in the state screenshots replaced by the exact fixture or route for each state.
- Kept, flagged in its Report back: the `Tap zones` and `Swipe sideways to change chapter` rows in the Type sheet fill a DESIGN gap (§8.15.4 names the presets and §8.15.8 the opt-in swipe, but no control location).

### web/15 Listen mode

- **B4 contradicted DESIGN §8.23.** It handed "the Downloads row for saved audio" to `web/17`, but §8.23 lists saved narration audio among what the web leaves absent. Fixed: B4 and the out-of-scope line now say the row is app-only; `useSavedAudio` is still exported so `web/17` can keep `novel-audio` entries out of its lists.
- **C9** gains the `#audiobook` deep link (admins only) that `web/17`'s Narration rows use.
- **F2** fills `web/04`'s empty `VOICE_FIELD_ROWS` array (80 to 300 Hz in 20 Hz steps plus the 60° worst case).
- **Proof:** the read-only cast view needed "a second non-admin account" that the seed does not create; the spec now registers `proof-reader` in setup (registration is open on the dev stack) and deletes it in teardown.

### web/16 Discover, sources, catalogue, dialogue

- **A3 genre weights.** The hook read the home feed's `genres` section, while DESIGN names `GET /library/recommendations` as the source for the Picks aside (§9.1.3) and The Numbers' radar (§9.2.1), and `web/21` added a second `useGenreWeights` over that endpoint. Fixed: one hook, `frontend/src/features/library/genre-weights.ts` (`useGenreWeights(limit = 40)`, key includes profile and gate), reused by `web/19` and `web/21`; the file layout line moved with it.
- Garbled dev-server sentence and the untouched check fixed (table above).

### web/17 Downloads, Index, What's new, System status

- **Saved narration audio** (`medium: "novel-audio"`, created by `web/15` A6) is now explicitly never a row, count or control; its bytes stay in the meter and the series size, and `Remove all downloads` removes it.
- **Proof:** "the second seeded account" does not exist; replaced by the same `proof-reader` setup and teardown.
- "if needed" in the file layout replaced by the A5 condition.

### web/18 Settings, the edition picker, Stop the press

- **Ambient fields had no owner.** A4 said `web/13` stores the soundscape, page-tint, pace and guided-view values, but `web/13` leaves those rows to `web/23`, which runs after `web/18`. Fixed: `web/18` defines them (`soundscape`, `pageTint`, `paceByDialogue`, `guidedAutoAdvance {on, mode, fixedMs}`, `pauseSoundscapeForNarration`, the novel `soundscape` and `resumeAfterRelease`, the device volume) with their defaults; `web/23` consumes them.
- **Soundscape preview** is now created unconditionally (no earlier step builds a `Hear`); the file layout listed `soundscape-preview.ts` twice with two different conditions, now once.
- **Novel "Auto next chapter"** is app-only (DESIGN §8.15.2 "(app)", and `web/14` treats it so); removed from the web Reading: novels section and from the novel settings record.
- **Layout default `GUIDED`** offered a layout the reader does not have until `web/23`; the web/18 control now has three values and `web/23` appends `GUIDED` here and in the setup sheet.
- **Command palette:** added the per-row `SETTINGS` group and the flag-gated `EDITION` group that `web/06` handed to this step, with an acceptance criterion.
- **Proof:** the non-admin account is created and deleted by the spec (the seed has one account). "if needed" in the file layout replaced by the A8 condition.
- Kept, with the reason stated in the file: the 7-day `mm.recap` default (glass §15.6 register resolves both skins; Cinematic §8.30.2 says 14) and the procedural demo covers in place of the Wikimedia scans (the plan's `shared/04` scope).

### web/19 AI: Picks, More like this, Previously on

- **C2** rewritten to verify `web/12`'s Up next chain instead of rebuilding it, and to move its `/ai/similar` request onto the A9 client, so there is one client for that endpoint.
- Genre-weights references point at `features/library/genre-weights.ts`.

### web/20 onboarding

- **Order of sections.** "Before you start" came before "Read first"; the series rule is Goal, then Read first. Moved.

### web/21 The Numbers, the streak flame, The Annual

- Same section-order fix.
- **Duplicate hook** removed: the radar uses `web/16`'s `useGenreWeights(8)`; the file-layout line that added a second hook to `features/library/hooks.ts` is gone.
- **`z.overlay` does not exist** in DESIGN §2.4; the milestone card now sits at `z.dialog` (50).

### web/22 Circle

- Same section-order fix.
- **Gaps from `web/11`:** the book page "In the circle" avatars (§8.18 columns 9–12) and the phone `SEND` button in the feature page's labelled icon row (§8.17) were handed to `web/22` and not listed. Both added, with an acceptance criterion.
- **G** now registers the `circle` section in `web/18`'s `registry.ts` (between Content and Feedback), which `web/18` says this step does.

### web/23 ambient reader extras

- Same section-order fix.
- **S1/S11 check** required `docs/redesign/signoffs.md`, while `web/12` may cite an earlier record instead; the check now greps for the record.
- **D1:** the `panel-focus` button is inserted after bookmark in `web/12`'s array (it was described as "left hidden" by `web/12`, which never builds it), and `GUIDED` is appended to Settings → Reading: manga as well as the setup sheet.

## Coverage of the slice's plan scopes

Every item in the plan scopes of `web/12` to `web/23` is assigned to exactly one file. The ownership lines that cross files now agree:

| Element | Owner | Consumers (now consistent) |
|---|---|---|
| `pinchZoom`, `zoomAt`, `onChapterCompleted`, `furtherElsewhere`, slots | web/12 | web/13, web/22, web/23 |
| `setLayout`, finger Slide, `renderPageOverlay`, `pageAtReadingLine`, `SpeedRuler`, `features/circle` minimal hooks | web/13 | web/15, web/22, web/23 |
| `useNovelReader`, `paginateNovel`, novel keys reducer, `--fixtures` in `proof.mjs` | web/14 | web/15, web/23 |
| `useNarration` (`isPlaying`, `pause`, gain), `VoicePicker`, `NarratingIndicator`, `useSavedAudio`, `#audiobook` | web/15 | web/17, web/18, web/23 |
| `useGenreWeights` (`features/library/genre-weights.ts`), `health.ts`, dialogue jump | web/16 | web/17, web/19, web/21 |
| `StoragePanel`, `WhatsNew`, `WEB_VERSION` | web/17 | web/18 |
| `mm.recap`, `mm.recap.autoContinue`, ambient preference fields, settings registry, soundscape preview (temporary) | web/18 | web/19, web/22, web/23 |
| `features/ai/similar.ts`, recap takeover and entry points, Up next client | web/19 | web/20 |
| Reactions, spoiler guard, Pass it on, shared shelves, Circle settings section, In the circle, `SEND` | web/22 | web/24 |
| `GUIDED` layout everywhere, `setCamera`, tint and panel parity files, `soundscape.ts` | web/23 | web/24, Glass web/35 and web/44 |

App-only items stay out of the web files on purpose and each file says so: lock controls, keep screen awake, volume keys, refresh rate, the K01 migration toast, `Scan this chapter's dialogue`, shake to extend, the lock screen, Save to Files, the Android update card, the novel auto-next advance.

## Findings outside this slice (not edited; for their reviewers)

1. **`web/03` and `backend/00`:** the `proof.mjs` usage comment (`BACKEND_INTERNAL_URL=… npm run dev -- --port 3010`) and the README pairing (`BACKEND_INTERNAL_URL=… npx next dev -p 3010`) both omit `NEXT_PUBLIC_API_URL=/api`. Without it the browser calls `http://127.0.0.1:8000` directly (`frontend/src/config/env.ts`) and every proof run fails. Both should read `NEXT_PUBLIC_API_URL=/api BACKEND_INTERNAL_URL=http://127.0.0.1:8010 npx next dev -p 3010`.
2. **`web/08`:** Tonight's `Your genres` slug line links to `/search?q={genre}&scope=sources`, while `web/16` and `web/19` open a genre with `/search#genre={name}` (the genre sheet, §9.1.3 "a link into Discover genres"). `web/08` should use the hash form. Its home-feed genre data is fine for Tonight itself; the other surfaces now use `useGenreWeights`.
3. **The same untouched-check defect** (`git diff --stat -- mobile backend` or a range diff) is likely in other tracks' prompts written from the same template; the per-commit form above is the correct one on a branch shared by parallel sessions.
