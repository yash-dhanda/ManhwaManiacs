# Review: mobile track, slice 2 (mobile/12 to mobile/23)

Reviewed 2026-09-29 against `docs/redesign/prompts-plan.json`, `docs/redesign/cinematic/DESIGN.md`, `docs/redesign/glass/DESIGN.md` (§15.4, §15.5, §15.6), `docs/redesign/inventory/{00-decisions,mobile,capabilities}.md`, `docs/redesign/stack-decision.md`, `docs/redesign/00-baseline.md`, the web twins `prompts/web/12`–`23`, the neighbours `mobile/08`–`11` and `mobile/24`, and the current checkout (`mobile/lib`, `mobile/test/screenshots`, `frontend/src/app/admin/status`). All twelve files existed; none had to be created. Every fix below was made in place; the originals are not kept in the repository.

## 1. Rule compliance, per file

| File | Exists | Goal / Read first / scope / layout | Skills named | Acceptance (reduced motion, 44 pt / 48 dp, per-skin) | Verification (`free -m`, 1 GB stop, analyze, test, baseline 2012) | Git (small commits, push, no attribution, no secrets, no connectors, no prod) | Report back + next file | Plan scope and deps |
|---|---|---|---|---|---|---|---|---|
| 12 manga reader strip | yes | yes | yes | yes | yes | yes | yes → 13 | match |
| 13 paged, read-all, setup, panels | yes | yes | yes | yes | yes (floor wording fixed) | yes | yes → 14 | match |
| 14 novel reader | yes | yes | yes | yes | yes (floor wording fixed) | yes | yes → 15 | match |
| 15 Listen mode | yes | yes | yes | yes | yes (floor wording fixed) | yes | yes → 16 | match |
| 16 Discover | yes | yes | yes (frontend-design stated as not invoked: no web UI) | yes | yes | fixed (push rule added) | yes → 17 | match |
| 17 Downloads, Index, status | yes | yes | yes (same) | yes | yes | fixed (push rule added) | yes → 18 | match |
| 18 Settings, edition, Stop the press | yes | yes | yes (same) | yes | yes | fixed (push rule added) | yes → 19 | match |
| 19 AI Picks, Similar, recap | yes | yes | yes (same) | yes | yes | fixed (push rule added) | yes → 20 | match |
| 20 onboarding | yes | yes | yes | yes | yes | yes | yes → 21 | match |
| 21 Numbers, streak, Annual | yes | yes | yes | yes | yes (floor wording fixed) | yes | yes → 22 | match |
| 22 Circle | yes | yes | yes | yes | yes (floor wording fixed) | yes | yes → 23 | match |
| 23 ambient extras | yes | yes | yes | yes | yes (floor wording fixed) | yes | yes → 24 | match, with one plan error (§3, item P1) |

Dependencies in every header match `depends_on` in the plan exactly (12 ← 11; 13 ← 12; 14 ← 13; 15 ← 14, backend/06, backend/03; 16 ← 15, backend/02; 17 ← 16; 18 ← 17; 19 ← 18, backend/05; 20 ← 19, backend/05; 21 ← 20, backend/03; 22 ← 21, backend/08, backend/09; 23 ← 22, backend/06, backend/07). No file contains "TBD", "etc." or "as appropriate". Verification commands are the baseline's: `flutter analyze` and `flutter test` from `mobile/` with `/srv/manhwamaniacs/dev/flutter/bin/flutter`; `npm run lint` / `npm run build` and the backend pytest (`backend/.venv/bin/python -m pytest -q --no-header`, the command `backend/00` establishes) are named and correctly skipped because these steps do not touch `frontend/` or `backend/`.

## 2. Findings and fixes

### Track-wide (all twelve files)

1. **Proof screenshots went to the wrong place or nowhere.** Every visual-proof command used `MM_WRITE_SHOTS=1`. In the current harness that variable makes the legacy marketing tests overwrite `mobile/docs/screenshots/` (the install page's public screenshots, served by `backend/routes/app_distribution.py`), while the `mobile/03` skin harness writes only when `MM_PROOF_DIR` is set, so the step's captures would not have been written. The slice-1 reviewer has already set the track convention in `mobile/03` / `mobile/04` (`MM_PROOF_DIR` only, never `MM_WRITE_SHOTS`; `kSkinShotSizes` phone 390 × 844 and tablet 834 × 1194, `kSkinShotTabletWide` 1024 × 1366, `kSkinShotLandscape` 844 × 390; `captureSkinScreen` and `captureSkinWidget`). **Fix:** every command now sets `MM_PROOF_DIR=../docs/redesign/proof/mobile-NN` and no `MM_WRITE_SHOTS`; a "Proof output location" paragraph before each Visual proof section names the harness API and sizes and requires `git status --short mobile/docs/screenshots` to be empty afterwards; every `820 × 1180` became `834 × 1194`, `mobile/22`'s `1180 × 820` and `mobile/18`'s `1194 × 834` became `kSkinShotTabletWide` 1024 × 1366. `mobile/18`'s edition-preview frames (bundled assets, not proof) now write with their own `MM_WRITE_PREVIEWS=1`.
2. **Baseline floor.** 13, 14, 15, 21, 22 and 23 recorded "your floor" without tying it to the baseline. **Fix:** "never below the 2012 of `00-baseline.md`: every test that passed there must still pass".
3. **Push rule missing in 16–19.** The other eight files make the session run `npm run build` before a push when other sessions' `frontend/` commits ride along (the queueless rule: a failed `next build` freezes production). **Fix:** the same "Before every push" paragraph added to 16, 17, 18 and 19.

### mobile/12 (manga reader 1)

4. **Pinch recognizer contradicted DESIGN without saying so.** A2 builds the pinch on a pointer-counting `Listener` ("no `ScaleGestureRecognizer`"), but §8.14.5 says "Flutter `ScaleGestureRecognizer` driving the engine's zoom", and the file also says DESIGN wins on conflicts, so a session could rip the approach out. The `Listener` is the right engineering call (a scale recognizer in the arena fights the one-finger vertical drag of the 120 Hz strip). **Fix:** A2 now declares it a deliberate deviation, forbids switching, and requires it in the report.
5. **The Up next chain did not match §8.14.6 / §9.1.6.** A11 used one chain for both end states, took "Because you read" from the home feed, and defined "From your shelf" as "reading or plan-to-read with `new_count` > 0"; `mobile/19` C2 would then have rewritten it. §8.14.6 gives the caught-up notice only the `More like this` rail (Similar), and the end the chain Similar → Because you read (world recommendations, "the source of every Because-you-read rail", §9.1.6) → From your shelf (favourites and plan-to-read, as `mobile/08` and `mobile/19` use it). **Fix:** `upNextProvider` takes `UpNextMode.caughtUp | theEnd` (the modes the reviewed `web/12` K3 now uses); Similar with the `fallback=genres` `SAME GENRES` fallback in both; `theEnd` continues to the first world-recommendations section, then favourites (`is_favorite`) then plan-to-read, excluding this series and completed series, at most 12; L3 names the modes.
6. **Two `GET /ai/similar` clients.** A11 called the endpoint on its own while `mobile/19` A8 adds `similar` to `mobile/08`'s AI repository. **Fix:** A11 adds `similar({sourceId, seriesKey})` to the repository behind `aiRepositoryProvider`; `mobile/19` A8 now extends that method instead of adding a second one.
7. **The per-profile "Save the next chapter while I read" switch** (§8.14.11, §8.23) gated the auto-queue in DESIGN but nowhere in B2. **Fix:** B2 gives the queue a `saveNextEnabled` input (default on) and names `mobile/17` as the owner of `saveNextProvider`; `mobile/17` A2 now wires that input.
8. **Running-head button order.** F4 left the final order open and `mobile/13` inserted settings "after bookmark" while `mobile/23` listed the phone order as "download mark, bookmark, settings, guided"; §8.14.3 is download, bookmark, guided view when ready, (tablets) `sidebar-simple` and `note-pencil`, settings. **Fix:** F4 fixes the full order (plus the tablet `dots-three` last); `mobile/13` D1, E1 and F1 and `mobile/23` D1 insert at their place in it.
8a. Smaller: the chapter folio's tooltip "Contents" (§8.14.3) added to F3; `chapter.next` gets its `turn` cue (§6) in J6; A12 now points at the real file (`features/downloads/models/download_chapter_state.dart` is a model at the baseline, not a widget).

### mobile/13 (manga reader 2)

9. **Cinematic code inside the skin-neutral engine.** A3 put `CinePagePhysics` (which uses `CineSprings.release`) in `features/reader/engine/page_turn.dart`, and A2's `turnTo` hard-wired `durPageturn` and `CineCurves.settle`. The engine must hold no skin value (glass §15.4: "skin-neutral, tested once for both skins"), and Glass builds its own `GlassPagePhysics` (`mobile/35`). **Fix:** `turnTo` takes `slideDuration`, `slideCurve` and `fadeDuration` from the skin; `setLayout` takes an optional `pagePhysics`; `CinePagePhysics` moves to `mobile/lib/skins/cinematic/screens/reader/cine_page_physics.dart`; the engine keeps only the pure `shouldCommitTurn`. File layout and Report back updated. `mobile/14`'s reference to `CinePagePhysics` now names its path; `mobile/20` and `mobile/21` use it from skin code, which stays valid.

### mobile/14 (novel reader)

10. **A second Hyperlegible store.** A4 would create `mm.appearance.legible.u{user}p{profile}` if `legibleTextProvider` was missing, but `mobile/04` A8 already defines `a11yPrefsProvider` over `mm.boot.a11y.u{user}p{profile}` with the derived `legibleTextProvider`, and `mobile/18` A5 binds to that key. **Fix:** A4 and the file layout point at `mobile/04`'s store and forbid a second key.
11. **A second contents sheet.** I1 built a new §8.15.6 contents widget "so the book page can reuse it", but `mobile/11` already built the book page's `contents_sheet.dart` / `contents_row.dart` (N2). **Fix:** I1 extends `mobile/11`'s widgets with an optional `CineStockColors? stock` (null leaves the book page unchanged and its tests green) and wraps them for the reader.

### mobile/15 (Listen)

12. **Listen sessions under 10 s would be rejected.** A5 dropped only sessions under 5 s, but §9.2.7 says clients send only sessions of 10 s or more and `backend/03` validates `seconds >= 10`. **Fix:** 10 s, with a 7 s case in the acceptance test.
13. **Flush timing.** §9.2.7 batches "when the app goes to the background"; A5 flushed only on `resumed`. **Fix:** also flush on `AppLifecycleState.paused` (a session still playing in the background stays open).
14. **Migration pattern.** A5 said "a new `onUpgrade` branch", but `downloads_db.dart` routes both `onUpgrade` and `onDowngrade` through the idempotent `_migrate`. **Fix:** an idempotent `CREATE TABLE IF NOT EXISTS` step in `_migrate` and `onCreate`, with upgrade and downgrade-reopen tests (the same pattern `mobile/23` already used).

### mobile/16 (Discover)

15. **Duplicate `GET /ocr/chapter` client.** A10 added `ocrRepository.chapter()`, but `mobile/12` A10 already added `fetchChapterText` and `ocrChapterTextProvider` to the same files. **Fix:** A10 reuses them; `findMatchPage` works on their page-text type; the file-layout line removed.
16. **A third way to map page fractions.** E3 added an engine query `pageRectOnScreen`, while `mobile/13` A7 added the per-page overlay slot `pageOverlayBuilder` (and its DIALOGUE tab already pulses a 2 px `spot` frame twice for 480 ms) and `mobile/23` adds `pageToViewport`. **Fix:** the bubble pulse draws through `pageOverlayBuilder` with `mobile/13`'s `ocr_overlay.dart` pulse; the jump uses `jumpToPage` and `mobile/12`'s `openReader` (Dip); no new engine query.

### mobile/17 (Downloads, Index, status)

17. **Status headline did not match DESIGN.** A8 and E2 used "Two things need attention." with numbers spelled out; §8.31 writes "2 things need attention.". **Fix:** digits, as §8.31 ("1 thing needs attention." for one).
18. **Wrong path for the web status rules.** A8 pointed at `frontend/src/app/(app)/admin/status/status.ts`; at the baseline the file is `frontend/src/app/admin/status/status.ts` (the route-group move comes later). **Fix:** a `find` command and all three possible locations; the port copies the state rules and tests, the headline comes from §8.31 (the legacy file says "Everything is healthy.").
19. **Index flame missing.** §9.2.2 puts the 24 px streak flame in the Index `The Numbers` row; C5 showed only the folio. **Fix:** the row carries `mobile/08`'s `StreakFlame` (the ember dot at 0).
20. **Profile-scoped key helper in a second place.** A2 would move the private `_scopedKey` to `mobile/lib/shared/providers/profile_scoped_key.dart`, but `mobile/08` item 2 creates the public `profileScopedKey` in `mobile/lib/core/storage/profile_scoped_key.dart`. **Fix:** A2 and the file layout use `mobile/08`'s helper and path; `mobile/20` A8 fixed the same way.

### mobile/18 (Settings)

21. **Forward reference to a preview that did not exist.** The Ambient bullet of A4 said the soundscape `Hear` preview "reuses `mobile/13`'s", but no soundscape code exists before `mobile/23`; the fields it binds to (`soundscape`, `pageTint`, `paceByDialogue`, `guidedAutoAdvance`) are also created only in `mobile/23`, and its fade timings (300 ms) contradicted `mobile/23` C6. **Fix:** A4 creates the missing fields with exactly `mobile/23` A8's names and defaults; the Ambient rows leave a trailing slot, and `mobile/23` C6 inserts `Hear` there (its text updated to match). No audio plays in `mobile/18`.

### mobile/19 (AI)

22. **Recap entries from Tonight used the Dip.** E1 routed Tonight's `Continue` cuttings and every Quick look `Continue` as `dip`, E2 gave Tonight rail recaps origin `dip`, and E4 gave every Quick look recap `dip`. §8.14.2 lists "a cutting" and "a rail's Quick look `Continue`" among the Tonight entries that play the Column wipe, and §9.1.5 continues a recap opened on Tonight by the wipe (only "a Library cutting's Quick look" and other places use the Dip); `mobile/12` C6 already wires Tonight that way. **Fix:** Tonight entries are `wipe`; Quick look is `wipe` when opened on Tonight and `dip` elsewhere.

### mobile/20 (onboarding)

23. The genre paragraph's 26 px tablet size is not in §8.7 (28 desktop, 22 phones); `web/20` uses the same 26, so the file now keeps 26 and requires it in the report as an interpretation, so a session does not "correct" it and drift from the web.

### mobile/21 (Numbers)

24. **Two genre-weights providers with one name and two sources.** `mobile/16` A5 defined `genreWeightsProvider` over the home feed's `genres` section (used by Discover and Picks), and `mobile/21` A3 defined a second `genreWeightsProvider` over `GET /library/recommendations`, the source cinematic §9.1.3 (Picks' `Your genres`) and §9.2.1 (the radar) actually name. **Fix (parity with the reviewed `web/16`, which made one `useGenreWeights(limit)` client over the same endpoint):** `mobile/16` A5 builds the app's one client, `genreWeights({limit = 40})` on the library repository and `genreWeightsProvider` as a family keyed by `limit` (sorted, `[]` on error, profile- and gate-invalidated, with a test), and says not to derive weights from `/home`; `mobile/19` reads `genreWeightsProvider(40)` and `mobile/21` reads `genreWeightsProvider(8)` with no provider or repository call of its own.

## 3. Cross-slice assignment check

Every item of the slice's plan scopes is owned by exactly one file, and the hand-offs are named at both ends:

| Item | Owner | Consumers (checked) |
|---|---|---|
| `pinchZoom`, `zoomAt`, `chapterCompleted`, `furtherElsewhere`, builder slots, reader prefs record, `ocrChapterTextProvider`, Up next, `openReader` | 12 | 13, 14, 16, 19, 21, 22, 23, Glass 34/35 |
| `setLayout` (PageView), `turnTo`, `shouldCommitTurn`, `pageOverlayBuilder`, `pageAtReadingLine`, read-all, setup sheet, `SpeedRuler`, Margins, page actions, minimal `features/circle/` | 13 | 14, 15, 16, 20, 21, 22, 23 |
| `paginateNovel`, `NovelReaderController`, `NovelParagraph` decorations, Type sheet, stocks | 14 | 15, 18, 22, 23, Glass 36 |
| Listen, `NarrationController`, voice picker, `NarratingIndicator`, saved audio, listen-session outbox | 15 | 17, 18, 21, 23 |
| Discover, Sources, catalogue, dialogue search, scan widgets, `genreWeightsProvider`, `text_fold.dart`, `describeHealth` | 16 | 17, 18, 19 |
| Downloads, `StoragePanel`, `saveNextProvider`, `mm/media` channel, Index, What's new, update and SideStore cards, System status | 17 | 18, 21, 22 |
| Settings (all sections except `circle`), edition picker, Stop the press, `mm.recap`, `a11yPrefs` binding | 18 | 19, 22 (registers `circle`), 23 (Ambient `Hear`) |
| Picks, Similar, recap takeover, `continueTo`, reader chips, AI state vocabulary | 19 | 20 |
| Onboarding, Cut to home flight | 20 | Glass 30 |
| The Numbers, flame verification, milestone cards, The Annual, press run | 21 | 22 |
| Circle, reactions and the spoiler guard, Pass it on, shared shelves, Settings → Circle | 22 | 23, Glass 43 |
| Page tint, panel detection, camera commands, guided view, auto-scroll model and chip, house sound | 23 | 24, Glass 34/35/44 |

Double assignments found and removed: the OCR chapter call (12/16), the page-fraction mapping (13/16/23), the Similar call (12/19), the Hyperlegible store (04/14/18), the contents sheet (11/14), the genre-weights client (16/21), the profile-scoped key helper path (08/17/20), the soundscape preview and ambient fields (18/23). Conflicting instructions resolved: the Up next chain and "From your shelf" (12 vs 08/19/DESIGN), the running-head button order (12/13/23 vs DESIGN), recap origins (19 vs 12/DESIGN), the auto-queue switch (12/17), the status headline (17 vs DESIGN).

## 4. Deliberately left as they are

- **P1 (plan error, DESIGN wins).** The plan entry for `mobile/23` says the soundscape plays "through flutter_soloud"; §9.4.2 and the §6 State A row specify a second `just_audio` player with `handleAudioSessionActivation: false`. `mobile/23` already follows DESIGN and reports the difference; unchanged.
- **Recap default of 7 days.** `mobile/18` A2 uses glass §15.6's shared `mm.recap` default (`seriesDays: 7`) over cinematic §8.30.2's 14; the plan requires "exactly as glass §15.6 resolves it", and the file reports it. Unchanged.
- **Presence for Cinematic-only households.** `now` and the reading-now ring appear only for members whose `show_presence` is on, a switch only Glass exposes (glass §15.6 binds Cinematic to leave it untouched). `mobile/22` already lists this as an owner call in Report back; no prompt can resolve it.
- **Tablet default novel size 19** (`mobile/14` A4) and the tablet Margins panel are interpretations the file already asks the session to report.

## 5. Notes for the other reviewers (outside this slice; not edited)

- `web/15` A5 drops listen sessions under 5 s; §9.2.7 and `backend/03` require 10 s (see fix 12).
- `web/17` item 2 writes "2 things need attention." and "numbers under ten spelled out" in one sentence; §8.31 uses digits (see fix 17).
- The soundscape `Hear` preview in Settings: the reviewed `web/18` builds a temporary `soundscape-preview.ts` that `web/23` replaces; `mobile/18` builds none and leaves a row slot that `mobile/23` fills (fix 21). Both reach the same end state after step 23; the owner sees `Hear` in Settings one step later on the phones.
- `mobile/24` still runs its harness with `MM_WRITE_SHOTS=1` and sizes 820 × 1180 / 1180 × 820, against the `mobile/03` convention (see track-wide fix 1).
