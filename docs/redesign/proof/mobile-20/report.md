# mobile/20 report: Cinematic onboarding ("the first issue")

Lane M20, branch `redesign/M20`. Cinematic only; nothing under `frontend/`, `backend/` or `design/` changed.

## Done, by scope letter

- **A data layer** (`mobile/lib/features/onboarding/`, no import from `lib/skins/`): A1 taste models, A2 catalog, A3 repository (Dio), A4 providers (catalog keyed by profile, gate and answers; `similarSeedsProvider` through mobile/19's AI client, whose `SimilarQuery.anilist` already existed; both added to `profileScopedInvalidators`), A5 step helpers, A6 genre paragraph, A7 art styles (`kStyleArtBundled = false`), A8 device draft and pending `done` (uses the existing `profileScopedKey`), A9 print run. Tests in `test/features/onboarding/`.
- **A10**: `Profile.onboardingStep` stays a `String?` (the many existing tests build it that way); it now parses an int from the server (`3`, not only `"done"`; the old `as String?` cast threw on a numeric step) and gains `Profile.onboarding` (`OnboardingStep?`).
- **B route, frame, chrome**: `onboarding` left `PENDING`; `/welcome?step=` reads the step once (capped at the resume step, 1 becomes 2); Dip entry, Cut when the picker's iris opens it; top bar with folio and four rules; pager over the visited steps only, one step-back action, `PopScope(canPop: false)`, iOS `canSwipe = false`; "Onboarding" shortcut group (`->` Next, `<-` Back; roving groups keep the arrows).
- **C steps**: formats (three-strip duotone plates, grain, foot scrim), genre paragraph (justified `Text.rich` of atomic word widgets: tap cycle, 450 ms hold, `Shift+F10` menu, semantics actions, roving arrows), art style plates, seed wall (Set stagger, similar inserts once per pick, counter, NOTE line).
- **D save and resume**: draft first, background `PUT`, `resumeStep`, `GET /profiles/{id}/taste` restore, pending `done` flushed when the profile is next picked (picker hand-off in `picker_logic.dart` / `picker_screen.dart`).
- **E Print and Cut to home**: follows 4 at a time, `step: done` save (3 tries 2 s apart, then pending), `/home` refetch, `cineFlightProvider` + `FlightLayer` above the Navigator, Tonight's `first_picks` slots keyed by `flightSlotKey`, headline held until `landed`, 3000 ms fail-safe, reduced-motion 200 ms cross-fade (new `CineTransitionKind.crossfade`; the Tonight shell page now honours `extra['transition']` of `dip`/`crossfade`).
- **F states, G accessibility**: loading galleys, unreachable and offline notices, hit-target, overflow (1.3 and 2.0, tablet, landscape) tests.
- **H** not built: step 1 Edition, the nine art crops, Glass onboarding.

## Nothing done and why / open

- Step 1 Edition ships with the Glass flip.
- Art-style crops: `kStyleArtBundled` is still false; owner-todo has the intake note.
- Phone art-style plates draw the name only (name fitted, description in the semantics label); tablets draw both (interpretation of 8.7).
- Genre paragraph is 26 px on tablets (8.7 names 28 for desktop and 22 for phones; web/20 uses 26).
- `CinePagePhysics` (mobile/13) is not in the tree; the stock page physics stand in (`TODO(mobile/13)` in `onboarding_screen.dart`).
- `/home` is refetched after the follows and the save settle (not concurrently) so the answer contains the new follows.
- Tonight holds only the headline until `landed`; the kicker, cover rack and deck are not gated.
- The wall is not hidden after `arm()` (the route swaps in the same frame).
- `SemanticsService.sendAnnouncement` (the current API) is used for the announcements.
- Taste `genres` in the draft is `Map<String, GenreMark?>`: a null is a cleared word and travels as weight 0 (the server needs it to remove a mark).
- `CineButton(fullWidth: true)` now really is full width (`CinePressable`/`CineFocusRing` got an `expand` flag; the other `fullWidth: true` users are in bounded columns).
- Whether `cinematic/DESIGN.md` and the prompt disagreed: the tablet paragraph size only (above); DESIGN.md's 22 phone size is kept.

## `kTasteReadable`

`true`: `GET /profiles/{id}/taste` exists (`backend/routes/profiles.py::get_taste`).

## Screenshots (`docs/redesign/proof/mobile-20/`)

Phone and tablet: `formats`, `formats-selected`, `formats-grid` (column guides), `genres`, `genres-marked`, `genres-menu`, `styles`, `seeds`, `seeds-picked`, `printing`, `flight-mid`, `tonight-landed`. Phone only: `loading-formats|genres|seeds`, `unreachable-formats|genres|seeds`, `ai-unavailable`, `offline`, `follow-partial-toast`, `reduced-motion-genres`, `text-scale-2-genres`, `landscape-genres`. They come from `test/screenshots/cinematic/mobile_20_onboarding_shots_test.dart` (a separate file, as mobile-19 does, instead of a `mobile-20` group in `marketing_screenshots_test.dart`). No `docs/redesign/proof/web-20/` exists yet, so no web comparison was made (list for the web twin's session).

| Screenshot | Proves |
|---|---|
| formats, formats-selected, formats-grid | Formats tiles, selection frame, grid |
| genres, genres-marked, genres-menu | genre paragraph, like/love/skip, menu |
| styles | art style plates |
| seeds, seeds-picked | seed wall, similar inserts, counter |
| printing, flight-mid, tonight-landed | Print, Cut to home, held headline |
| loading-*, unreachable-*, ai-unavailable, offline | F states |
| follow-partial-toast, reduced-motion-genres | E4, reduced motion |
| text-scale-2-genres, landscape-genres | text scale, landscape |

## Tests

- `flutter analyze`: No issues found.
- Full `flutter test`: 5094 tests, 0 failures (5093 passed and 1 failed in the full run; the failure was an outdated expectation in `picker_screen_test.dart`, since fixed and re-run green).
- New: unit tests in `test/features/onboarding/` (20), widget tests in `test/skins/cinematic/onboarding/` (screen 13, steps 13, a11y 29), picker logic and screen updates.
- `free -m` available before each heavy command: 13.6 GB to 19.2 GB.
- The green-baseline floor was not re-measured before the work (the lane merge already carried other lanes' tests).

## Names other steps call

- `onboardingRepositoryProvider`, `onboardingCatalogProvider(CatalogKey)`, `catalogKeyFor`, `similarSeedsProvider(anilistId)`, `onboardingStoreProvider` (`readDraft`, `writeDraft`, `readPending`, `flushPending`), `kTasteReadable`.
- `resumeStep(OnboardingStep?, bool glassAvailable)`, `shownSteps`, `folioFor`, `nextStep`, `prevStep`, `entryStep`, `genreParagraph`, `tapGenre`, `runFollows`, `followedToast`, `flightList`, `tasteBody`.
- `cineFlightProvider`, `FlightItem`, `FlightState.hides(key)`, `flightSlotKey('{source_id}:{series_key}')`, `flightDuration(n)`, `FlightLayer`.
- Tonight hand-off: `context.go(Routes.tonight(), extra: {'transition': 'none' | 'dip' | 'crossfade'})`; `OnboardingScreen.imageLoader` (test seam); `onboardingFlowProvider` (skin side).

## Device checklist

`docs/redesign/proof/mobile-20/device-checklist.md`.
