# Mobile 24b: Cinematic reconcile — replace stand-ins with the real modules and close the open items

Track: mobile · Order 69 · Depends on: `docs/redesign/prompts/mobile/24-cinematic-qa-polish.md` · Proof folder: `docs/redesign/proof/mobile-24b/`

## Goal

Every Cinematic mobile step (mobile/00 to 24) has landed. Several of them were built while a prerequisite step was missing, so they carry local stand-ins marked `TODO(<step-id>)`, and many steps returned "partial" or landed with acceptance items that were never re-checked. This step makes the Cinematic mobile app consistent and finished. It changes only Cinematic and shared mobile code under `mobile/lib/` and `mobile/test/`. Do not touch `mobile/lib/skins/glass/`, `frontend/`, or `backend/`.

## Read first

1. `docs/redesign/unresolved.md` (every Cinematic mobile section: mobile/08, 09, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24).
2. `docs/redesign/owner-todo.md` (skip what needs a device or art).
3. `docs/redesign/cinematic/DESIGN.md` for any value you need.
4. Run `git grep -nE "TODO\((mobile|web|backend|shared)/[0-9]+" -- mobile/lib mobile/test` and keep the output as your worklist.

## Scope (do all of it)

A. **Stand-ins.** For every `TODO(mobile/NN)` where step NN has landed (all mobile/00 to 24 have), replace the stand-in with the real module that step delivered, delete the stand-in file or class, update imports, and remove the marker. Known clusters: `screens/discover` (`cine_kit.dart`, `cine_extras.dart`, `cine_poster.dart`, local key registry), `screens/feature` (`feature_states.dart`, `feature_motion.dart`, `feature_lightbox.dart`, `book/`, `manga/`), `primitives/`, `features/library` (`mark_read.dart`, `progress_deleter.dart`, `tags_controller.dart`), `features/novels` (narration providers), the onboarding page physics (`CinePagePhysics`), `StreakFlame`, `NarratingIndicator`, `PreviouslyOnChip`, `CreditsMoreLikeThis`, `upNextChain` mounting in the readers, the annual pager physics. Markers for Glass steps (mobile/25 and later, web) stay.
B. **Open items.** For each Cinematic mobile section in `unresolved.md`, fix every item that can be fixed in code without a device, art or an unbuilt step: missing keyboard handling and shortcut registry entries, hit-target sizes, reduced-motion behaviour, focus rings, semantics labels, chart label collisions, the mature-gate cache invalidation for the Circle providers (also delete `circle_service` from `noClientCache` in `mobile/test/features/settings/mature_invalidators_test.dart`), the router-level tests that need `tonightIdleOverride()`, and the reader items listed for mobile/12 and mobile/14. Do not chase items that need the owner or a device.
C. **Tests.** Add or fix widget tests for what you change. All tests that passed before must still pass.

## How to work

Split the work by directory into as many parallel subagents as it has independent parts (one Agent call each, all in one message, model sonnet, effort low, no cap). Give each its files and its worklist lines. Do the integration yourself.

## Acceptance

- [ ] `git grep -nE "TODO\(mobile/([0-9]|1[0-9]|2[0-4])\)" -- mobile/lib mobile/test` prints nothing.
- [ ] `flutter analyze` reports no issues.
- [ ] The full `flutter test` run passes (run it once, at the end).
- [ ] Every fixed item is removed from `docs/redesign/unresolved.md`; items that remain have a one-line reason.
- [ ] Nothing under `mobile/lib/skins/glass/`, `frontend/` or `backend/` changed.

## Verification

Use the slot runner only: `/srv/manhwamaniacs/dev/heavy.sh mobile /srv/manhwamaniacs/dev/flutter/bin/flutter analyze` and the same for `flutter test`.

## Report back

Return what you replaced, which items you fixed, which remain and why, and the test counts.
