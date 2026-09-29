# Review: mobile track, slice 1 (mobile/00 to mobile/11)

Reviewed on 2026-09-29 against `docs/redesign/prompts-plan.json` (binding), `inventory/00-decisions.md`, `inventory/mobile.md`, `inventory/capabilities.md`, `stack-decision.md`, `stack-keep.md` §6, `00-baseline.md`, `cinematic/DESIGN.md` and `glass/DESIGN.md`, plus the live checkout where a prompt makes a claim about today's code (`mobile/lib`, `.github/workflows`, the Flutter SDK). Every fix below was applied in place in the prompt file named. No file of the slice was missing, so none was created. Nothing outside `docs/redesign/` was touched and no git command that changes state was run.

## 1. Verdict per file

All twelve files exist and already carried the required skeleton: goal paragraph, "Read first" with exact paths and section numbers, preconditions, skills (`superpowers:writing-plans`, `subagent-driven-development` / `executing-plans`, `impeccable`, `taste-skill:taste-skill`, `frontend-design` where there is UI to compare, `verification-before-completion`), scope item by item, file layout, checkbox acceptance criteria (reduced motion, hardware keyboard, 44 pt / 48 dp, per-skin differences), verification with `free -m` before each heavy command and the exact `flutter analyze` / `flutter test` commands from the baseline, the frontend and backend baseline commands with the reason they are not rerun, git rules without AI attribution, guardrails (`backend/connectors/`, production), "Report back" and the next prompt file. No "TBD", "etc." or "as appropriate" was found. Values spot-checked against DESIGN.md matched (type scale rows, springs × 1.2, scrim modal 0xC7, the Column wipe totals 616 / 744 ms, the thumb index, the twelve avatar colours, the mood grades and their × 3 squares, the Glass T3 / T4 `LiquidGlassSettings`, the Android haptic constants of glass §5.1, the `stack-keep.md` §6 budget used by the re-estimate).

| File | Plan scope covered | Dependencies stated | Problems found | Status |
|---|---|---|---|---|
| 00 reader engine extraction | yes | yes (none) | Section E missed pure logic in `lib/shared/widgets/` (imported by three data-layer files) and put `SeriesChapterDownloadAction` in the wrong file; WORST threshold differed from mobile/03's gate | fixed |
| 01 skin engine and restart | yes | yes | `readerLanding` was both in `PENDING` and a redirect, which contradicts its own completeness test and mobile/12's precondition | fixed |
| 02 native plugins, haptics, sound | yes, with two justified deviations (below) | yes | proof only at phone size | fixed |
| 03 fonts, icons, harness, Glass gate | yes (bundled Phosphor TTFs instead of `phosphor_flutter`, justified) | yes | harness had one tablet size and no landscape or ≥ 900 px size, no non-route capture helper, and no rule against `MM_WRITE_SHOTS`, so later steps diverged | fixed |
| 04 Cinematic primitives 1 | yes | yes | proof via `MM_WRITE_SHOTS` (overwrites the served marketing screenshots); tablet 820 × 1180 instead of the harness's 834 × 1194; precondition grepped for `phosphor_flutter`; no precondition for shared/04's demo covers; recorder had no rule for scroll-linked moves that mobile/08 needs | fixed |
| 05 Cinematic primitives 2 | yes | yes | `MM_WRITE_SHOTS`, 820 × 1180 | fixed |
| 06 shell, router, transitions | yes | yes | a second app-frame hook (`buildAppFrame`) beside mobile/01's `Skin.wrap`; a Library hub pager that conflicted with mobile/09's hub frame; `prefetchChapterStart` took the skin's `ReaderTarget` into the engine folder (breaks mobile/00's boundary test); `Skin.splash` left unused; `MM_WRITE_SHOTS`, 820, "add the landscape size if missing" | fixed |
| 07 auth, profiles, 18+ | yes | yes | `MM_WRITE_SHOTS`, 820; the picker's ≥ 900 px row had no proof size | fixed |
| 08 Tonight | yes | yes | prefetch on press as P3 (mobile/06 owns it as P1); `CineMotion.play('trailerScrub')` / `('rack')` with hand-typed strings; the offline stamp described with a different 18+ rule than mobile/07's; a false legacy claim ("`/` redirects to `/library`": on mobile `/` is the legacy home); placeholder paths in the file layout; `parts/quick_look_actions.dart` clashed in name with mobile/05's `primitives/quick_look_actions.dart`; `MM_WRITE_SHOTS`, 820 | fixed |
| 09 Library shelf and browse | yes | yes | Android back for hub tabs assigned to both mobile/06 and mobile/09; `HubShellScope` ownership unclear; placeholder paths; `MM_WRITE_SHOTS`, 820 | fixed |
| 10 Updates, Collections, History, Bookmarks | yes (incl. the re-estimate gate) | yes | `resolveHistoryContinue` returned `ReaderTarget` from the data layer; placeholder path; `MM_WRITE_SHOTS`, 820, ad hoc 1024 × 1366 names | fixed |
| 11 Feature and Book pages | yes | yes | backend `mature_override` fix raced with web/11 running in parallel; OCR coverage asked for a provider that already exists; download-mark labels contradicted mobile/04's `CineDownloadMark`; re-stamp could run twice; prefetch on press as P3; placeholder paths; `MM_WRITE_SHOTS`, 820 | fixed |

## 2. Fixes applied, file by file

### mobile/00-foundation-reader-engine-extraction.md
- Section E scan now covers `lib/shared/widgets` too; the acceptance grep checks `shared/widgets/` imports from the data layer as well as `features/*/widgets/`.
- Item 20 corrected: `SeriesChapterDownloadAction` and `SeriesChapterDownloadPhase` live in `lib/shared/widgets/series_detail/series_chapter_tile.dart` (verified), and move to `downloads/models/series_chapter_download_action.dart` with `chapterDownloadAction()` going to `downloads/utils/`.
- New item 27a: `SeriesChapterSortOrder` and `sortSeriesChapters()` move from `shared/widgets/series_detail/series_chapter_sort.dart` to `features/library/utils/series_chapter_sort.dart` (imported today by `resume_location.dart`, `novel_book.dart` and `series_reading_order_provider.dart`, verified).
- File layout lists the two new paths; device check WORST threshold aligned to `< 16.7 ms` (mobile/03's gate rule).

### mobile/01-foundation-skin-engine-and-restart.md
- `readerLanding` now builds the pending screen like every other id and stays in `PENDING`; the §8.0.3 redirect is registered by the step that removes it (mobile/12 for Cinematic, mobile/29 for Glass). Acceptance line changed to match. This makes item 20's "PENDING equals the ids whose route builds a PendingScreen" true and keeps mobile/12's precondition ("both ScreenIds still pending") valid.

### mobile/02-foundation-native-plugins-haptics-sound.md
- The Feedback lab proof is captured at phone 390 × 844 and tablet 834 × 1194 (track rule: phone and tablet sizes).
- Kept on purpose, not changed: `phosphor_flutter` is not added (verified: `IconData` is `final class` at `flutter/packages/flutter/lib/src/widgets/icon_data.dart` line 23; glass §2.7, §15.11 and shared/02 say the same); the haptics switch stays per device (cinematic §5 "Scope: … per device", glass §5), although the plan entry says per profile; `flutter_soloud` 4.1.7 and `share_plus` 12.0.2 for both skins (ledger rows).

### mobile/03-foundation-fonts-icons-harness-glass-gate.md
- Harness item 9 gains `kSkinShotTabletWide` (1024 × 1366 at 2×, for the ≥ 900 px rows of §8.0.9) and `kSkinShotLandscape` (844 × 390 at 3×, insets 47 / 47 / 21), outside the default loop, and `captureSkinWidget` for captures that are not routes (gallery sections, fixture states, open overlays), writing `<name>-<size.name>.png`.
- States that these are the only proof sizes of the mobile track (tablet 834 × 1194) and that proof runs use `MM_PROOF_DIR`; `MM_WRITE_SHOTS` writes into `docs/screenshots/`, which the backend serves, so it is reserved for the legacy marketing shots.
- Adds a naming test for `captureSkinWidget`, an acceptance line for the new constants, and the harness API in the report.

### mobile/04-cinematic-primitives-core-and-reveals.md
- Read-first harness note rewritten (`captureSkinWidget`, `MM_PROOF_DIR`, never `MM_WRITE_SHOTS`).
- Preconditions: the grep no longer lists `phosphor_flutter` as expected; it asserts it is absent; adds checks for the harness API and for `brand/demo/covers/*.webp` (shared/04, used by the gallery).
- The recorder (B4) handles scroll-linked entries (`plannedMs == 0`: frames and drops only, late only on a dropped frame; §15.9), which mobile/08's trailer scrub needs.
- Harness group, verification command and visual proof use `captureSkinWidget`, `MM_PROOF_DIR` and 834 × 1194.

### mobile/05-cinematic-primitives-overlays-controls-states.md
- Harness group through `captureSkinWidget` at `kSkinShotSizes`, `MM_PROOF_DIR`, tablet 834 × 1194.

### mobile/06-cinematic-shell-navigation-transitions.md
- 2.1 / 2.3 / 8: the root stack is returned by mobile/01's `Skin.wrap`; no second hook. Only `scrollBehavior` may be added to the interface.
- 7.3 replaced: the nested hub shell keeps go_router's indexed stack and exposes itself through `HubShellScope` (`shell/hub_shell_scope.dart`); the tab row, the finger-tracked swipe and the masthead are mobile/09's `LibraryHub` (the plan gives the hub frame to mobile/09, and §8.9 puts the tab row under the masthead). The hub-tab row was removed from the shell gallery; the file layout, heading, commit subject and report API were renamed; `shell_test` gains "back from `/updates` → `/library` → `/`", because this step owns that back rule.
- 4.9: `prefetchChapterStart` takes plain ids and a `RequestPriority`, never `ReaderTarget` (which lives in the skin and would fail mobile/00's engine boundary test).
- 11: `CinematicSkin.splash()` returns `CineSplash`, so the interface member mobile/01 declared is used.
- Harness at `kSkinShotSizes` plus `kSkinShotLandscape`, `MM_PROOF_DIR`, 834 × 1194 (also in the reader-route test).

### mobile/07-cinematic-auth-profiles-18plus.md
- Harness at `kSkinShotSizes`, the picker also at `kSkinShotTabletWide` (its one row of 144 px avatars starts at 900 px), `MM_PROOF_DIR`.

### mobile/08-cinematic-tonight.md
- B2.4: prefetch through mobile/06's `ReaderPrefetch` (`onPress` P1, `onDwell` P3 after 150 ms), matching mobile/06 and web/06.
- B6: the trailer scrub logs through `CineMotion.track(<TRAILER SCRUB member>, 0)` per gesture; B7: the rack cap is mobile/04's `CineImage` / `CineRackImage`, not a string.
- A8: the offline stamp uses mobile/07's `isMatureLocal()` (the server's `resolve_series_rating` order), not a second rule.
- Acceptance: the legacy mobile `/` is today's home screen (verified in `app/router/routes.dart`: `home = '/'`); tablet 834 × 1194.
- Quick look builders renamed `parts/quick_look_builders.dart` and tied to mobile/05's `primitives/quick_look_actions.dart` ids.
- File layout placeholders replaced by real paths (`reader/models/reading_progress.dart` declares `ProgressPush`; `settings/providers/settings_provider.dart` holds `matureScopedInvalidators`; the gallery files; the harness test file; the proof files). Visual proof uses `captureSkinScreen` / `captureSkinWidget` and `MM_PROOF_DIR`.

### mobile/09-cinematic-library-shelf-browse.md
- B3: `HubShellScope` comes from mobile/06; created here only if missing, with the same API.
- B5: the Android back rule for hub tabs is mobile/06's; this step verifies it and never adds a second `PopScope`.
- Acceptance sizes 834 px (the book list's two columns start at 768 px); quick look file renamed; placeholders replaced; proof through the harness and `MM_PROOF_DIR`.

### mobile/10-cinematic-updates-collections-history-bookmarks.md
- A5: `resolveHistoryContinue` returns a skin-neutral record; the History screen maps it to `ReaderTarget`.
- Proof through the harness, `MM_PROOF_DIR`, tablet 834 × 1194, the ≥ 900 px captures at `kSkinShotTabletWide` (`updates-aside-tablet-wide.png`, `bookmarks-two-columns-tablet-wide.png`); placeholder path replaced.

### mobile/11-cinematic-feature-and-book-pages.md
- Section A: web/11 (order 38, same cluster, parallel) owns the `mature_override: null` backend fix; mobile/11 only backs it up once web/11's last commit (`web-11:` … proof) is in the log and the backend tree is clean, so two sessions never edit `followed_series_service.py` at once. Report line updated.
- B3: reuse the existing `ocrCoverageProvider` (`features/ocr/providers/ocr_providers.dart`, verified) and `OcrCoverage.coveredChapterCount`; nothing new in the OCR folder.
- B7 / F8: `downloadMarkLabel()` uses exactly the labels mobile/04's `CineDownloadMark` speaks (the four of the §7 table are binding) and `CineDownloadMark` reads it; no second download-mark widget.
- B11: every override change goes through the data-layer path mobile/07 hooked, so the re-stamp runs once.
- C3: prefetch as mobile/08.
- Placeholder paths replaced; proof through the harness and `MM_PROOF_DIR`, tablet 834 × 1194.

## 3. Coverage of the slice's scopes

ScreenIds this slice removes from the Cinematic `PENDING` set, each exactly once:

| Step | ScreenIds |
|---|---|
| mobile/07 | `setup`, `login`, `register`, `profiles`, `profileNew`, `profileEdit`, `profilesManage` |
| mobile/08 | `tonight` |
| mobile/09 | `library`, `featureByFollow` |
| mobile/10 | `updates`, `collections`, `collection`, `history`, `bookmarks` |
| mobile/11 | `feature` |

`readerLanding`, `reader`, `readAll` and `novel` stay pending until mobile/12–14 (consistent after the mobile/01 fix). Every other ScreenId belongs to later steps. Nothing in the slice finishes a Glass id.

Elements and states that sit on a boundary, now with one owner each:

| Item | Owner | Users |
|---|---|---|
| App-frame hook | mobile/01 `Skin.wrap` | mobile/06 (Cinematic root stack) |
| Library hub frame (tab row, swipe, masthead) | mobile/09 `LibraryHub` | mobile/10 |
| Hub shell access | mobile/06 `HubShellScope` | mobile/09, mobile/10 |
| Android back on hub tabs | mobile/06 item 6 | verified by mobile/09 |
| Reader prefetch priorities | mobile/06 `ReaderPrefetch` (press P1, dwell P3) | mobile/08, mobile/11 |
| Reader route page and wipe geometry | mobile/06 `reader_route_page.dart`, `wipe_geometry.dart` | mobile/12 (see §4) |
| 18+ predicate and stamps | mobile/07 `isMatureLocal`, `MatureStamper` | mobile/08, mobile/09, mobile/10, mobile/11 |
| Download mark widget and labels | mobile/04 `CineDownloadMark`; labels moved into mobile/11's `downloadMarkLabel()` | mobile/11, mobile/17 |
| Quick look ids / per-item builders | mobile/05 `primitives/quick_look_actions.dart` / mobile/08 `parts/quick_look_builders.dart` | mobile/09 |
| Rating card | mobile/06 slot, mobile/07 card | mobile/11, mobile/12 |
| Motion recorder incl. scroll-linked entries | mobile/04 | mobile/06, mobile/08 |
| Proof harness sizes and helpers | mobile/03 | every later mobile step |
| `mature_override: null` backend fix | web/11 (mobile/11 backs it up) | both series pages |

The four new features in this slice's scope: AI home (mobile/08: AI rails, "because you read", AI-unavailable, stale and rate-limited states; recap entry points deferred to mobile/19 as the plan says), stats and streaks (mobile/08's numbers teaser and `StreakFlame`; The Numbers and The Annual stay mobile/21), social (only the deferrals to mobile/22 are named; no Circle UI is built here, as the plan says), ambient extras (none in this slice). The two signature animations are fully specified in mobile/04 (`SetHeading` per §10.1.6 with its six tests, `TypedHeadline` per §10.2.4) and used in 06–11.

## 4. Issues outside this slice (for the reviewers holding those files)

1. **mobile/12 C1–C6 re-specifies the reader route page that mobile/06 item 4.8 already builds** ("mobile/12 extends this file"). The values agree (616 / 744 / 440 ms), but two instructions conflict: the blade geometry (mobile/12: "each blade spans its column plus half of each neighbouring gutter"; mobile/06 and cinematic §8.14.2: blade edges land on column edges, so blade i runs from column i's left edge to column i + 1's left edge), and the entry helper (mobile/12 C6 adds `openReader(context, String location, {ReaderEntry entry})` in `screens/reader/reader_entry.dart`, while mobile/06 already exports `enterReader(context, ReaderTarget, {required ReaderEntry entry})` in `navigation.dart`, which mobile/08 and mobile/11 use). Recommendation: mobile/12 extends mobile/06's `reader_route_page.dart`, reuses `wipe_geometry.dart`, `ColumnWipePainter` and `enterReader`, and drops `openReader`.
2. **mobile/24 to mobile/45 still use `MM_WRITE_SHOTS=1` and a tablet of 820 × 1180**. `MM_WRITE_SHOTS` overwrites the served marketing screenshots in `docs/screenshots/`; the harness of mobile/03 writes proof only through `MM_PROOF_DIR` and its tablet is 834 × 1194 (`kSkinShotTabletWide` 1024 × 1366 and `kSkinShotLandscape` 844 × 390 are available by name). mobile/12–23 already use `MM_PROOF_DIR` and no 820 size.
3. **Glass `readerLanding`**: mobile/29 removes it from Glass `PENDING` ("PENDING lost only readerLanding"), and mobile/35 also lists it as removed in its own step. One of the two must own it; this review's mobile/01 fix names mobile/29.
4. **web/08** says the Tonight prefetch runs "as P3 … and on press"; web/06 (the owner of the helper) makes press P1. mobile/08 and mobile/11 now follow web/06.
5. **Plan wording** (`prompts-plan.json`, not edited here): the web/08 scope lists "the Coming up band", which is the reader's chapter-end card (§8.14.6), not a Tonight element; the mobile/02 scope says "per-profile haptics toggle" (DESIGN says per device) and lists `phosphor_flutter` 2.1.0, and the mobile/03 scope lists `phosphor_flutter` (it cannot compile on Flutter 3.44.6). The prompts follow DESIGN.md and say so in their reports.

## 5. Not changed, noted

- 00–03 save plans to `docs/redesign/plans/mobile-NN.md`, 04–11 to `docs/redesign/proof/mobile-NN/plan.md`. Both work; no step reads another's plan.
- 04–11 add a pre-push `npm run build` when other sessions' frontend commits are in the push range ("next build before push" in the owner's memory); 00–03 rely on CI. Harmless either way.
- mobile/10's re-estimate counts CCD from commit days per step; mobile/04 and mobile/05 commit with `feat(mobile-cinematic):` subjects, which the path-based `git log` in item H2 already covers.
