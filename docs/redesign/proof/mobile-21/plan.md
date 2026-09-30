# mobile/21 plan: The Numbers, the streak flame and The Annual (Cinematic)

Lane L12, branch `redesign/L12`. Cinematic only; Glass statistics and Wrapped are `mobile/42`.

## Parallel-plan preconditions

The lane's waitFor list held `backend/03` and `mobile/03` only. mobile/04 to 08, 13, 17 and 20 are not integrated, so
everything this step needs from them is a small local stand-in under `lib/skins/cinematic/kit/` and `parts/`, each marked
`TODO(mobile/NN)`. The stand-ins are listed in `report.md`.

## Order of work (each step one commit, tests first for the pure modules)

1. **A, data layer** (`features/library`): models `shareable`, `annual`, extended `library_statistics`; a separate
   `NumbersRepository` (ten test fakes implement `LibraryRepository` in full, so its interface stays untouched);
   `numbers_providers` (range per profile, snapshot, index); `numbers_rules`, `milestones`, `streak_state`
   (stand-in for mobile/08's `HomeStreak`), `numbers_snapshot`. Tests: `numbers_data_test.dart`.
2. **Kit stand-ins**: `CineText`, `TypedText`, `SetHeading` (with `typedRange`), rules, buttons, toast, sheet, contents tabs,
   Dip, notice and galley, key map, folios, duotone and grain, cover provider.
3. **B, The Numbers**: pure `chart_math` and `clock_copy` (tests first), the four painters, stat and streak blocks, the
   lists, the panel with its states, the screen (NestedScrollView, pinned tabs, TabBarView, keys).
4. **C, flame and milestone card**: `NumbersStreakFlame` on `flutter_animate`, `MilestoneCard` and its host.
5. **E, press run**: pure `share_card_model` (tests first), `ShareCard` at 1080 x 1920 / 1350, capture, the sheet, then the native
   `mm/media` channel and `NSPhotoLibraryAddUsageDescription` in their own commit.
6. **D, The Annual**: pure `annual_copy` (tests first), player, segments, controls, eleven pages, story frame (phone, column),
   states, screen; router registration.
7. **Proof**: widget tests for every acceptance item, the `mobile-21` screenshot group, `st-map.md`,
   `device-checklist.md`, `report.md`.

## Verification

`flutter analyze` (no issues), `flutter test test/features/library test/skins`, then the full `flutter test`, each through
`heavy.sh mobile`. The floor is the branch baseline measured at the start of the lane: 2155 passed, 5 failed (three of them
outside this step; two were mobile/21's own new providers missing from the mature-gate audit, fixed here).
