# mobile-08 report: Cinematic Tonight

Tests: before 3744 passed / 0 failed; after 3858 passed / 0 failed. `flutter analyze`: No issues found. `node design/build.mjs --check`: ok (no token changed).

Done: A1-A14 and B1-B12 (see deviations). Screenshots in this folder (invented fixtures only): tonight-{phone,tablet}, tonight-grid-*, tonight-scrub-half-phone (p 0.5), tonight-scrubbed-*, tonight-novel-*, tonight-also-pager-phone, tonight-quick-look-phone, tonight-lightbox-phone, tonight-{loading,new-profile,onboarded,caught-up,at-risk,ai-unavailable,stale,offline,error}-*, tonight-reduced-motion-phone, tonight-text-2.0-phone, streak-flame-gallery, cinematic-tonight-* (app frame). Web twin proof not present: no comparison.

## Deviations and open issues
- Cover art is blank in the shots: the harness's network-cover path does not reach `CineImage` (limiter route); layout, scrims and text are proved, art is not.
- `homeFeedProvider` is not in `profileScopedInvalidators` (it watches the active profile; invalidating it there is a CircularDependencyError) and does not watch the gate; it is in `matureScopedInvalidators` and the `home_service` audit. `HomeFeedView` gained `retryAfter`.
- Existing stand-ins retired: `ProgressDeleter` -> `ReaderRepository.deleteProgress`; `manualReadRows`/`chunksOf200` per spec (`ChapterMark` keeps the old chapter helpers); `AiRepository.sendFeedback` added to the existing class.
- Genre links use `/search?genre=` built by hand (the typed builder lacks `genre`; Discover's path is `/search`).
- No source health mark and no `Listen` action: the payloads carry neither. Strip `▸` is the play glyph.
- `CineImage` async-after-dispose guard, `CineButton.fullWidth`, `CinePoster.folioColor/duotone`, `CineRail.roman`, `CineFeatureCard.heroTag`, `SetHeading.roman` added in their own files.
- Router-level tests that `pumpAndSettle` at `/` use `tonightIdleOverride()`.
- Motion: TRAILER SCRUB is tracked per scroll gesture; frame/drop figures need the device pass (device-checklist.md).

## Shared API
`homeFeedProvider`, `HomeFeedView`, `HomeFeedState`, `HomeFeedOrigin`, `composeLocalFeed`, `composeOfflineEdition`, `composeHeadline`, `spellCount`, `applyAtRisk`, `streakTier`, `streakState`, `justExtended`, `streakIgnitionProvider`, `manualReadRows`, `chunksOf200`, `deleteProgress`, `profileScopedKey`, `clockProvider`, `continueHiddenProvider`, `hideContinue`/`unhideContinue`, `shouldPlayFrontPage`, `aiRepositoryProvider.sendFeedback`; parts `quick_look_builders.dart` (`openCuttingQuickLook`, `openFollowedQuickLook`, `openPickQuickLook`, `openSourceQuickLook`), `add_to_shelf_sheet.dart`, `source_picker_sheet.dart`; `StreakFlame`, `OnScreen`.
