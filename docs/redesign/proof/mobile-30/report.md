# mobile/30 report

Done: A to K. Removed from Glass `PENDING`: setup, login, register, profiles, profileNew, profileEdit, profilesManage, onboarding (none left of these).

Crops/previews: `kGlassStyleArtBundled` false (typographic tiles), `kGlassPreviewFramesBundled` false (neutral mark on aurora). Light angle had its own accelerometer subscription; it now rides `gravityProvider` (`core/platform/gravity.dart`). Restart path: `restartIntoSkin` wraps `switch_skin.dart`'s `restartInto` (no second copy). Gate effects extracted to `features/settings/utils/mature_gate_effects.dart` (Cinematic imports it). mobile/29 has no gate watcher, so the profile form runs the purge itself when the active profile's gate closes.

Onboarding headings: 2 "Pick a look", 3 "What do you read?", 4 "Which genres pull you in?", 5 "Which art styles do you like?", 6 "Pick a few you've read or want to read"; 7 "Your shelf is ready."

Tests: full `flutter test` 6572 passed, 0 failed (baseline run was cut off at 6366 passed, 0 failed); analyze clean; new-suite run 142 passed. Captures: this folder.

Differences from the contract (open issues): the picker's colour pour uses the field's 900 ms tint shift, not 600 ms (8.5); the drain, condense and flights use the root overlay / effects layer, not GlassHandoffLayer's own API (4.10); the Dots merge droplet flies on springZoom, not a 400 ms gravity fall (8.7); onboarding swipe uses the stock page threshold and is off on steps 4, 6, 7 (8.7); the 18+ alert title has no name variant (mobile/28 primitive); the popular-lists notice uses GlassInlineNotice; the Skin row is a custom two-segment radio; the picker's Step-into-the-light inflate/repel use a small spring integrator, not GlassMotion; the auth frame is transparent over the ambient field. web/30 reads 2.1.6 mood opacities; the picker uses 2.1.8's 30 %.
Env: 5 of 6 mobile slots are held by orphaned flutter_tester PIDs of M29/M24 (parent 1), which made heavy runs queue for minutes.
