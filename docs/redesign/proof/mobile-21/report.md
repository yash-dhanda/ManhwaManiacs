# mobile/21 report: The Numbers, the streak flame and The Annual (Cinematic)

Branch `redesign/M21` (restart of lane L12; L12's data layer, screens, share model and native change were merged, then every stand-in was replaced).

## Done, by scope letter
- **A data layer**: models (`shareable`, `annual`, extended `library_statistics`), `NumbersRepository` (a separate interface so the ten `LibraryRepository` fakes stay valid; `days` and the clamped tz offset are sent, the fake Dio adapter test records `days=365`), `numbers_providers` (range per profile, snapshot, annual index; all in `profileScopedInvalidators`, the Annual and Numbers under `reading_stats_service` in the mature audit), `numbers_rules`, `milestones` (+ `readingStreakOf`), `numbers_snapshot`, `HomeStreak.fromReadingStreak`. Genre weights come from mobile/16's `genreWeightsProvider(8)`.
- **B The Numbers**: all of B1-B15 (route, masthead, contents-tab pager with pull to reprint, Annual banner, streak block and stat blocks with the signature moment, chapters per day and the year heatmap, clock, radar, where/most read/recent sessions/library, footnotes, states, keys).
- **C flame and milestone card**: the one `StreakFlame` (size 56 added) everywhere; milestone overlay route (`MilestoneRoute`, Dip) mounted on Tonight and The Numbers; December toast in the shell; December link in Tonight's teaser; the Index row already opened the Annual.
- **D The Annual**: eleven pages, phone frame, column mode, colophon roll, auto-advance rules, screen-reader buttons and custom actions, keys, states.
- **E press run**: model, card, capture, sheet, `Save image` per platform; `mm/media` `canSaveImage`/`saveImage` beside `saveDownload`; `NSPhotoLibraryAddUsageDescription` was NOT present and was added.
- **F** reduced motion, hit targets, text scale: covered by tests.
- **G** not built: listen sessions (`grep listen-sessions mobile/lib/features` is empty; open issue).

## Tests
`flutter analyze`: No issues found. `flutter test`: 5244 passed, 0 failed (baseline floor 2012 per 00-baseline; branch baseline 2155 passed). `free -m` available before the heavy runs: 9.4 GB to 13.5 GB.

## Proof
`docs/redesign/proof/mobile-21/`: the screenshots of the verification list (phone, tablet, landscape) and `card-{time,chapters,no1,genres,streak,clock}-{story,post}.png`. In the proof harness the cover art decodes to the error plate (in-repo art under fake async); the layout, type and states are the point. No web-twin captures exist yet, so no comparison list.

## Names other steps call
`numbersStatisticsProvider(days)`, `annualProvider(year)`, `annualIndexProvider`, `statsRangeProvider`, `numbersScopeProvider`; `pendingMilestone`, `milestonesToMark`, `readingStreakOf`; `renderShareCard(context, template, format)`, `shareTemplates(ShareInput)`, `showPressRun`, `shareFileName`; `MediaStoreChannel.canSaveImage()/saveImage(bytes, name)` (`mediaStoreProvider`); `SetHeading(typedRange: (start:, end:))`; `TypedHeadline(delay:)`; `CineStatBlock(footnote:, signature:, ruleDelay:)`; `CineSectionHeader(footnote:)`; `raisedFolio`; `authedCoverProvider`; `folioLabel` gained `N D AGO` and `CH n`.

## Device checklist
`docs/redesign/proof/mobile-21/device-checklist.md` (owner-todo entry added).

## Open issues and choices
- CI: APK build and iOS dry run have not been read (the integrator pushes).
- Listen sessions are not recorded (mobile/15 territory).
- `CinePagePhysics` (mobile/13) is not integrated: the Annual pager uses a local release-spring physics, `TODO(mobile/13)`.
- Deviations from the prompt: the repository is `NumbersRepository` rather than an extension of `LibraryRepository`; the per-profile numbers providers read the profile (a watch made invalidating them from the profile notifier a circular dependency) and are invalidated on a switch instead.
- The not-enough-data notice splits its copy into headline and deck (CineNotice headlines cap at 60 graphemes).
- The chapters chart's last date label can touch its neighbour at 30 days on a phone.
