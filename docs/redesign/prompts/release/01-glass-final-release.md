# Final release 01: Glass joins Cinematic, cross-skin QA, minor bump, three platforms

Track: release · Order 110 (the last file of the series) · Depends on: `docs/redesign/prompts/web/45-glass-qa-polish.md`, `docs/redesign/prompts/mobile/45-glass-qa-polish.md`, `docs/redesign/prompts/release/00-cinematic-flip-release.md` · Proof folder: `docs/redesign/proof/release-01/`

## Goal

Glass is built and has passed its QA on both clients, but it is still reachable only through the Settings → Diagnostics debug row, because `flags.glass_available` in `design/contract.json` is `false`. In this session you make Glass a real choice for every profile and ship it on web, Android and iOS together. You set the flag to `true` and regenerate; turn on every surface the flag gates in Cinematic (`cinematic/DESIGN.md` §8.0.7: the onboarding Edition step, the profile-form Edition row, the command palette's `EDITION` group, the live Glass edition card, the Settings footer's restart sentence, the alternate-icon registration) and in Glass (glass §8.0.8: the Appearance skin cards, onboarding step 2, the profile form's Skin control, the palette's skin action; "App icon follows the skin" off by default); apply the alternate-icon registration that `shared/05` wrote but left unapplied; delete the debug row and the `mm-skin-debug` and `mm.skin.debug` keys on both clients; run the cross-skin QA on the web, the iPhone and Android with the motion-timings overlay (switches in both directions with `SKIN RESTART` under 1,500 ms, the return route restored, the 10 s Undo, downloads resuming, the service-worker pages cache rebuilt, the per-skin offline fallback, the profile hand-off switch with no alert, the shared-device icon rule) and the §14 checks for both skins; add the Glass screenshots to the install page gallery (glass §12.6); bump the minor version; and ship through the same gates, pushes, deploy, APK hand-off and verification as `release/00`. This file is the owner's explicit instruction to deploy.

## Read first

Read these before you plan. Where this file and a DESIGN.md disagree, the DESIGN.md wins, except for the decisions listed under "Decisions this step makes"; say so in the report.

1. `docs/redesign/inventory/00-decisions.md` (all of it).
2. `docs/redesign/stack-decision.md` §2.4 (the device mirror and boot resolution steps 1–5; "a per-device override is left out on purpose"), §2.5 (restart mechanics, downloads resume, budget under 1.5 s), §3 "Release model", §4 risks 3, 7, 8 and 11.
3. `docs/redesign/cinematic/DESIGN.md`: §8.0.7 (the table of everything the flag gates, and "The pre-flip debug row" as amended by `release/00`), §8.5 (the Iris, step 4: a Glass profile restarts inside the black, no confirm, no undo, never an icon change), §8.6 (the `Edition` segmented control and its save rules), §8.7 (step 1 Edition, the deferred restart), §8.30.1 (the footer), §8.30.3 (picker, confirm, the 500 ms Stop the press, "The switch waits for the server", "Budget and misses", the 10 s undo toast), §8.33.1 (the `EDITION` group), §12.3 (per-skin icon), §14 (all), §15.9 (the `SKIN RESTART` entry).
4. `docs/redesign/glass/DESIGN.md`: §8.0.8 (first bullet, and "First-paint attributes"), §8.0.9 ("Switching profile mid-use"), §8.2 (splash; `mm.skin.splash.glass`), §8.5 (the Step into the light hand-off, 1,100 ms), §8.6 (the Skin segmented control and its write rules), §8.7 step 2 (Look), §8.25 (footnote), §8.25.1 (skin cards, "App icon follows the skin"), §8.25.2 (the switch, the 615 ms melt, arrival, profile switch, offline), §8.25.12 (Diagnostics), §8.28 (offline fallback), §12.2 (per-skin icon), §12.4 (Droplet), §12.5 (the "Float" set), §12.6 (install page and the SideStore listing are shared), §14 (all, with the gate-close checklist of §14.11), §15.6 (rows "Availability flag", "App icon", "PWA manifest, startup images, OG image, install page"), §15.8.
5. `brand/glass/icon-registration.md` (the exact Android, iOS and CI edits and the Dart icon names), `brand/check.mjs` (its registration gate).
6. The proof you build on: `docs/redesign/proof/release-00/release.md` (the ship runbook as it actually ran, and its deviations), `docs/redesign/proof/web-45/qa.md`, `docs/redesign/proof/mobile-45/qa.md`, `docs/redesign/proof/mobile-45/device-checklist.md`, `docs/redesign/proof/web-45/float/`.
7. `docs/redesign/inventory/capabilities.md` §23 (app distribution endpoints); `docs/redesign/00-baseline.md`.
8. `docs/redesign/prompts-plan.json` (the entry for this file) and, for file names and helpers: `prompts/web/39-glass-settings-and-skin-switch.md` (A1: the flag-true branch of the Glass switch, `skin-outbox.ts`), `prompts/web/45-glass-qa-polish.md` (B, E, M, L), `prompts/mobile/45-glass-qa-polish.md` (M, the device checklist), `prompts/shared/05-brand-glass-and-art-intake.md` (Decisions 1 and 4, item 4), `prompts/backend/07-media-routes-and-install-page.md` (D5, the Front pages strip markup), `prompts/mobile/39-glass-settings-and-skin-switch.md` (A3, C1, E1–E4: `AppIconSwitcher`, `mm.icon.pending`, the preview frames), `prompts/web/39-glass-settings-and-skin-switch.md` (L3, the WebP loops), `prompts/web/18-cinematic-settings-and-edition-restart.md` and `prompts/mobile/18-cinematic-settings-and-edition-restart.md` (web item 13 and mobile item 14: the Cinematic Diagnostics debug rows), `prompts/web/40-glass-you-about-admin-status.md` and `prompts/mobile/40-glass-you-about-admin-status.md` (H1: "Preview Glass skin"), `prompts/mobile/37-glass-listen-mode.md` (A3, the notification colour), `backend/scripts/README-dev-stack.md` (the dev stack, `demo`, Riya and Aarav).
9. Release tooling: `mobile/RELEASE.md` (its "Release checklist (VPS)" from `release/00`), `codemagic.yaml`, `.github/workflows/{tests,ios-build}.yml`, `ops/vps/push.sh`, `ops/vps/deploy.sh`, `ops/fetch-ios-build.sh`, `backend/routes/app_distribution.py`, `backend/tests/test_app_distribution.py`.

## Preconditions (stop and report if any fails)

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs
git branch --show-current                                  # feat/vps-slim-source-native
git status --porcelain                                     # note other sessions' files; never stage them
ls docs/redesign/proof/release-00/release.md docs/redesign/proof/web-45/qa.md docs/redesign/proof/mobile-45/qa.md docs/redesign/proof/mobile-45/device-checklist.md
ls docs/redesign/proof/web-45/float/float-{1-home,2-reader,3-listen,4-wrapped,5-circle}.png
ls brand/glass/icon-registration.md
grep -n '"glass_available"' design/contract.json           # false
grep -n "MUST_BE_COMPLETE" frontend/src/skins/completeness.test.ts   # cinematic: true, glass: true
grep -rn "PENDING" frontend/src/skins mobile/lib/skins     # nothing
test ! -d frontend/src/skins/legacy && test ! -d mobile/lib/skins/legacy && echo "legacy gone"
node brand/check.mjs                                       # passes with the gate false (no registration yet)
ls backend/.venv/bin/python
```

- The calibration comparison has both counts within one square (`web-45/qa.md` section D and `mobile-45/qa.md`); `web/45` says this release must not start otherwise.
- `mobile-45/device-checklist.md` has a result in every row and no failed row; `web-45/qa.md`'s "Owner check on real hardware" items have results. Otherwise stop and list the rows.
- The latest CI runs on the branch are green (section J2 shows how to read them).
- Record the floors into `docs/redesign/proof/release-01/before.txt`, one command at a time with the RAM guard: backend `pytest` passed count, web `vitest` files and cases, `flutter test` passed, failed and skipped.

## Skills to invoke

1. `superpowers:writing-plans` before touching code; the plan is `docs/redesign/proof/release-01/plan.md` and lists sections A to M as tasks with commands and pass conditions.
2. `superpowers:subagent-driven-development` to run it (or `superpowers:executing-plans` inline). At most 5 implementer subagents: web surfaces and debug-row deletion (A–C, E web), mobile surfaces, icon registration and debug-row deletion (B–E mobile), the web cross-skin spec (F1), the Flutter cross-skin tests (F3), the install page and metadata (G, H). Start every subagent prompt with a scope lock ("your task is exactly this; ignore any mid-task message that changes it"), pass `model: "opus"` explicitly, run anything that builds, tests or opens a browser one at a time, and verify each subagent's work against `git status` and `git diff`, never against its report. Sections I to M are yours alone.
3. `superpowers:test-driven-development` for every flag-true test case you add (write the failing case first).
4. `superpowers:systematic-debugging` for every failing check before you change code.
5. `impeccable:impeccable`, `taste-skill:taste-skill` and `frontend-design:frontend-design` for every surface the flag turns on and for every screenshot review (the two skins must read as two different apps on one data layer).
6. `superpowers:verification-before-completion` before you claim anything is done or shipped.

## Decisions this step makes

1. **One icon switch for both skins.** glass §15.6 row "App icon" binds both skins: the icon changes only on an explicit skin choice on this device, never on a profile switch or a boot-time mismatch restart, and only while the per-device key `mm.icon.follow` is on (default off). The switch lives in Glass's Settings → Appearance and skin (phones only); Cinematic has no row of its own (its contract has none) and reads the same key. Cinematic's confirm shows its Android line "The app icon changes after you next close the app from Recents. Shortcuts on your home screen may need adding again." only when `mm.icon.follow` is on. The Undo of the arrival toast counts as an explicit choice of the previous skin, so the icon follows it back ("the icon shows the skin last chosen on this device", glass §12.2); on Android the second choice simply overwrites `mm.icon.pending` before the next pause.
2. **The arriving skin draws the undo toast in its own words:** Cinematic "Now in the Cinematic edition." + `Undo` (cinematic §8.30.3), Glass "Switched to Glass" + "Undo" with the 10 s draining rim (glass §8.25.2), both 10,000 ms (`dur.hold.toast.undo`).
3. **No debug path remains.** `getSkin()` and `SkinBoot` stop reading `mm-skin-debug` and `mm.skin.debug`, and each client removes a leftover value once at boot (web: expire the cookie and remove `sessionStorage['mm.debug']`; app: `prefs.remove('mm.skin.debug')`), without a restart. A device that was previewing Glass through the row lands in its profile's skin (Cinematic when the profile's `skin` is `NULL`), and the owner chooses Glass in Settings from then on.
4. **Tests and scripts choose a skin the way users do:** the active demo profile's `skin` through `PATCH /api/profiles/{id}` plus the matching `mm-skin` cookie, restored to the seed's value at teardown (a cookie alone would be undone by the boot check, stack §2.4 step 4). One implementation, in plain ESM so the `.mjs` scripts can import it: `frontend/scripts/use-skin.mjs` exporting `async function useSkin(context, { base, profileId, skin })`, which reads the profile's current `skin` (`GET /api/profiles` through `context.request`), sends the `PATCH`, adds the `mm-skin` cookie for `base` (`Path=/`, `SameSite=Lax`), and returns an async `restore()` that `PATCH`es the previous value back (`null` for the seed) and clears the cookie. `frontend/e2e/support/use-skin.ts` is one line, `export { useSkin } from "../../scripts/use-skin.mjs";` (the tsconfig has `allowJs`). It replaces every `mm-skin-debug` cookie in `frontend/e2e`, `frontend/scripts/proof.mjs` (its `--skin` flag now calls `useSkin` and restores at exit), `frontend/scripts/front-pages.mjs`, `frontend/scripts/float-frames.mjs` and `frontend/scripts/capture-skin-previews.mjs` if it sets one; a `node --test` case in `frontend/scripts/use-skin.test.mjs` with a fake `context` covers the patch, the cookie and the restore. Flutter tests write `mm.skin.active` and the profile fixture's `skin`.
5. **Install page, not the listing.** The install page gains a second screenshot strip for Glass (glass §12.6); the SideStore listing keeps the five Cinematic front pages, because "the app display name and the SideStore listing are shared by both skins" (glass §12.6).
6. **Deploy from this VPS** exactly as `release/00` Decision 8 (SSH to itself is not configured; the local mirror of `push.sh all`), and **the APK is built on the owner's laptop** (`push.sh apk`, where the signing key lives; never Gradle on this box).
7. **`master` after each working step, the branch once, iOS first.** Every push of `feat/vps-slim-source-native` publishes an iOS build to SideStore (`ios-build.yml` triggers on that branch only); a push to `master` runs only the `tests` workflow. So commit small and often; after each working step (A to D together, because `brand/check.mjs` fails in CI while the flag is `true` and the registration is missing; then E; F; G+H) whose client gates are green (web: `npm run typecheck`, `npm run lint`, `npm run test`; mobile: `flutter analyze`, `flutter test`; backend: `pytest`; with the RAM guard), push it to `master` only: `git fetch origin && git merge-base --is-ancestor origin/master HEAD && git push origin HEAD:master` (never force; stop and report if `origin/master` is not an ancestor). Push the branch once after every gate of section I is green, wait until CI has published the iOS build, and only then deploy web and backend and hand the APK to the owner. This release also compiles the Glass alternate icon with `actool` for the first time, so a red iOS build stops the release before any other platform moves.
8. **The device pass runs on the shipped builds.** The flag-true builds exist only after the push, so the owner's cross-skin device pass (section L) runs on the released IPA and APK. A failed row is fixed forward in this session as a patch release (`X.Y.1+(N+1)`), through sections I to K again.

## Scope: deliver every item below

### A. The flag

1. `design/contract.json`: `"flags": { "glass_available": true }`. Run `node design/build.mjs`, then `node design/build.mjs --check`. `git diff --stat` shows `design/contract.json`, `frontend/src/skins/contract.generated.ts` (`FLAGS = { glassAvailable: true }`) and `mobile/lib/skins/contract.g.dart` (`static const bool glassAvailable = true;`) and nothing else from the generator.
2. Every unit test that pinned the flag to `false` gets its flag-true twin where one is missing (grep `glassAvailable` in `frontend/src`, `frontend/e2e` and `mobile/test`): `shownSteps(true)` → `[1, 2, 3, 4, 5]` and `folioFor(2, true)` → `2 / 5` (web/20, mobile/20); `resolveBootSkin` and `resolveBootRestart` with a profile `skin: "glass"` → restart into Glass; the Glass `resumeStep` and step-2 visibility. A test that asserted the flag-false behaviour by reading the generated constant (for example `web/45` and `mobile/45` item M5 "the flag holds", the `web/18` and `mobile/18` `NEXT ISSUE` plate and short-footer checks, the `web/24` and `mobile/24` QA cases) now fails: rewrite it to inject `glassAvailable: false` explicitly where the component takes it, or to assert the flag-true behaviour; never delete it to get green.
3. **The CI refusal of glass §8.0.8** ("CI refuses a build with the flag `true` while either client's Glass completeness or boundary test fails"): add to `frontend/src/skins/completeness.test.ts` a case that fails when `FLAGS.glassAvailable` is true and `MUST_BE_COMPLETE.glass` is not, and to `mobile/test/skins/completeness_test.dart` a case that fails when `Flags.glassAvailable` is true and the Glass pending set is not empty. Both boundary tests already run in the `tests` workflow.

### B. Cinematic surfaces the flag turns on (cinematic §8.0.7 table, on both clients unless named)

Each surface already exists behind the flag (`web/07`, `web/18`, `web/20`, `web/06`, `mobile/07`, `mobile/18`, `mobile/20`); find each with `grep -rn "glassAvailable" frontend/src/skins/cinematic mobile/lib/skins/cinematic`, check it against the contract text below, and fix what differs.

1. **Onboarding Edition step** (§8.7): `/welcome?step=1..5`, folio `1 / 5` … `5 / 5` in Plex Mono with five 24 × 2 rules (`spot` when done); step 1 kicker `YOUR EDITION`, headline "Pick how the app looks.", the two live previews (web: the `/skin-preview/{skin}` iframes; app: the 36-frame PNG loops), the current one marked `THIS EDITION`. Choosing Glass defers the restart: steps 2–5 run in Cinematic, then `Print my first issue` saves the taste and the follows and Stop the press runs with no confirm into Glass's Home.
2. **Profile form `Edition` row** (§8.6): the segmented control `CINEMATIC │ GLASS`, kicker `EDITION`, caption "The look of the whole app for this profile." It writes `reading_profiles.skin`; for another or a new profile it applies at the next pick (inside the Iris); for the active profile `Save changes` saves the other fields first, then opens the confirm; `Stay in Cinematic` keeps the other saved fields and leaves the edition unchanged.
3. **Command palette `EDITION` group** (web, §8.33.1): "Switch to the Glass edition…" opens the confirm.
4. **Settings → Appearance → Edition, the live Glass card** (§8.30.3): the preview (web `<iframe src="/skin-preview/glass">` at 390 × 844 CSS px scaled into the 9:16 frame, `inert`, `tabindex="-1"`, `aria-hidden="true"`; app the loop `mobile/assets/skin_previews/glass/000.png`…`035.png` at 6 fps), "Glass" set in Glass's display face, the description "Glass: layered glass, springs and depth.", the secondary `Switch to Glass`, and under both cards the caption "Switching restarts the app. You'll come back to this page. Your edition follows this profile to every device." Reduced motion: the iframe does not scroll and the app shows frame 000.
5. **Settings footer** (§8.30.1): "Settings save as you change them. Changing the edition restarts the app."
6. **Confirm** (§8.30.3): title "Restart in Glass?", body "The app closes and reopens in the Glass edition, on this page.", "Downloads resume after the restart." when the queue is not empty, the Android icon line only under Decision 1; actions `Restart in Glass` (primary) and `Stay in Cinematic` (quiet). Stop the press: 500 ms (`dur.stoppress`): rack out 0–160 ms (`blur.defocus` 0 → 6 px, brightness 1 → 0.3, `turn`), blades close 80–456 ms, masthead cuts in at 456 ms with haptic `skin.switch` (`heavy`) and the sound `impress` when UI sounds are on; web awaits the `PATCH` for at most 1,000 ms more, and on an error or timeout the blades reverse (200 ms `dur.clip` `ease.set`) with the toast "Couldn't switch editions. Try again."; the app writes `mm.skin.active` and `mm.skin.return` at 500 ms and restarts with the `PATCH` in the outbox. Reduced motion: a 200 ms fade to black with the masthead cutting in at 160 ms, restart at 200 ms.
7. **The Iris step 4** (§8.5): picking a profile whose `skin` is `glass` restarts inside the black when the iris closes (480 ms `turn`), with no confirm and no undo; Glass's splash plays instead of the iris out; the icon never changes on a pick.
8. **Boot check and undo**: a device whose mirror differs from the active profile's skin restarts once at boot (stack §2.4 step 4) with no confirm and no undo; an explicit switch arrives with the undo toast of Decision 2. The web Edition row stays disabled offline ("Needs a connection."); the app's stays enabled offline with "Saves when you're back online." until the outbox flushes.

### C. Glass surfaces the flag turns on (glass §8.0.8, on both clients unless named)

Find each with `grep -rn "glassAvailable" frontend/src/skins/glass mobile/lib/skins/glass frontend/src/features/skin`.

1. **Settings → Appearance and skin** (§8.25.1): two preview cards side by side (phone: stacked), name in `title2` ("Glass", "Cinematic"), one line ("Liquid glass, springs and depth." / "Dark cinema, posters and title cards."), and a "Current" tag on the active one; under Reduce Motion the still first frame with "Play preview". The loops differ by client, as `web/39` and `mobile/39` built them:
   - **Web:** the looping animated WebPs of Home, 360 × 780, at most 921,600 bytes, 6 s, plus stills: `frontend/public/skin-preview/loops/skin-glass.webp`, `skin-cinematic.webp`, `skin-glass-still.png`, `skin-cinematic-still.png`. Regenerate all four with `free -m && npm run capture:skin-previews` in `frontend/` (dev stack and `next dev` on 3010 running) when the newest commit touching `frontend/src/skins/glass/screens/home` or `frontend/src/skins/cinematic/screens/tonight` (`git log -1 --format=%ct -- <folder>`) is newer than the newest commit touching `frontend/public/skin-preview/loops/`.
   - **App:** 36-frame PNG loops (the `mobile/39` decision; Flutter does not use the WebPs): `mobile/assets/skin_previews/glass/000.png`…`035.png` and `mobile/assets/skin_previews/cinematic/000.png`…`035.png`, frame `000.png` as the still. Regenerate Glass's with `free -m && MM_WRITE_PREVIEWS=1 /srv/manhwamaniacs/dev/flutter/bin/flutter test test/screenshots/glass/skin_preview_capture_test.dart` when `mobile/lib/skins/glass/screens/home` changed after `mobile/assets/skin_previews/glass/`, and Cinematic's with `free -m && MM_WRITE_PREVIEWS=1 /srv/manhwamaniacs/dev/flutter/bin/flutter test test/screenshots/skin_previews/cinematic_preview_frames_test.dart` when `mobile/lib/skins/cinematic/screens/tonight` changed after `mobile/assets/skin_previews/cinematic/` (same `git log -1 --format=%ct` comparison), from `mobile/`, one at a time. Commit regenerated frames in their own commit.
2. **"App icon follows the skin"** (phones only; §8.25.1, §12.2): a switch, default off, stored per device as `mm.icon.follow`, caption "Home-screen shortcuts to the old icon stop working."
3. **Onboarding step 2, Look** (§8.7): the two previews, Glass selected; choosing Cinematic shows "The app will restart in Cinematic after the last step." and the restart runs after step 7, with no confirm. The step now shows for a profile that started in Cinematic too.
4. **Profile form Skin control** (§8.6): segmented Glass · Cinematic with 32 px mini previews; a new profile's control is preselected to the skin this device shows and that value is written explicitly right after `POST /profiles` succeeds (so a profile created in Glass never boots as `NULL` → Cinematic); for the active profile, Save saves the other fields first, then runs the §8.25.2 alert, and "Stay in Glass" keeps them.
5. **Palette action** (desktop web, §7.28): "Skin: Cinematic (restarts the app)" opens the alert.
6. **The switch flow, flag-true branch** (`web/39` A1 and its mobile twin): `PATCH /profiles/{id} { skin }`, `restartInto({ cookie: "mm-skin", … })`, `undoable: true`; offline, the Glass `skin-outbox` entry is queued and flushed on `online` and at boot, and boot treats the pending entry as the profile's skin. Alert (§8.25.2): its live preview small at the top, title "Restart in Cinematic?", body "Everything about the app changes: layout, navigation, type and motion. Your library, progress and downloads stay exactly as they are, and you'll come back to this screen.", the notice "Downloads pause for a moment and resume after the restart." when the queue is not empty, offline the line "This profile will switch on your other devices once you're back online.", buttons "Stay in Glass" (secondary, first, initial focus) and "Restart in Cinematic" (tinted). Haptic `skin.switch` (`heavy`); the melt, 615 ms (dematerialise 350 ms, blur 0 → 40 px on `smooth`, the circular mask closing on `page`), sound `melt` when sounds are on; Reduce Motion a 200 ms fade to black. Arriving into Glass: the full Droplet (1,200 ms cold) and the toast of Decision 2.
7. **Footnote** (§8.25): "Settings save as you change them. Switching skin restarts the app."

### D. The alternate icon, registered

1. Apply `brand/glass/icon-registration.md` exactly, in one commit with the flag already `true` (its gate): the Android manifest (`.MainActivity` loses its MAIN/LAUNCHER intent filter; `activity-alias` `.CinematicIcon`, enabled, and `.GlassIcon`, disabled, both `android:label="Maniacs"`, targeting `.MainActivity`, with the icons and service entry the file names); the iOS project (`AppIcon-Glass.icon` file reference and build file in the Runner target, and in Debug, Release and Profile `ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES;` and `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES = AppIcon-Glass;`); the CI edits (`.github/workflows/ios-build.yml` gains `maxim-lobanov/setup-xcode@v1` with `xcode-version: '26.0'` on the runner image the file names, and `codemagic.yaml` sets `xcode: 26.0`).
2. The Dart side is `mobile/39`'s `AppIconSwitcher` (`grep -rn "class AppIconSwitcher" mobile/lib`), which calls `flutter_dynamic_icon_plus` 1.4.1: iOS `setAlternateIconName(iconName: 'AppIcon-Glass')` (and `iconName: null` for Cinematic) inside the restart moment, where the system's one-line alert lands over the black; Android the alias swap stored in `mm.icon.pending`, applied when the app next goes to the background (`AppLifecycleState.paused`) with empty `blacklistBrands`, `blacklistManufactures` and `blacklistModels`, never inside the restart. Check and fix, each fix in its own commit with its test:
   - **Android names.** The plugin compares fully qualified class names, so the Android calls use `'com.manhwamaniacs.reader.GlassIcon'` and `'com.manhwamaniacs.reader.CinematicIcon'` exactly as `brand/glass/icon-registration.md` lists them (`shared/05`). `mobile/39` E3 stored the short names `'GlassIcon'` / `'CinematicIcon'` in `mm.icon.pending`; if the code still does, store and pass the fully qualified names.
   - **Every explicit choice calls it, and nothing else does.** `AppIconSwitcher.onExplicitSkinChoice(skin)` must be called from every explicit choice on this device and from nowhere else: Glass's Appearance skin cards, Glass onboarding step 2's deferred restart after step 7, Glass's profile form for the active profile; Cinematic's Stop the press started from Settings → Appearance → Edition, from onboarding step 1's deferred restart after `Print my first issue`, and from the active profile's form (`mobile/18` and `mobile/20` left the icon untouched because the flag was false, and no later step wired them: wire them now); and the Undo of either skin's toast (it is an explicit choice of the previous skin, so the icon follows it back). Never the Iris or Step into the light hand-off, the boot mismatch restart, or the debug path (deleted in section E). `onExplicitSkinChoice` returns at once unless `mm.icon.follow` is true.
3. `node brand/check.mjs` passes with the gate `true` (registration present). `mobile/test/android/manifest_permissions_test.dart` and `launch_window_test.dart` read the manifest: update them for the launcher alias; add a test that exactly one alias is enabled by default and it is `.CinematicIcon`.
4. The Android notification accent (glass §12.6: Glass `iris600` `#7563F2`, Cinematic `spot` `#F4D03F`): `AudioServiceConfig.notificationColor` is fixed when `AudioService.init` runs once in `main()`, so `mobile/37` A3 sets it from the boot skin (`SkinBoot.read`) and an in-process skin switch keeps the colour of the skin the process started in until the next cold start. Confirm `mobile/lib/main.dart` does exactly that, record the file and this platform limit in `release.md`, and keep the device-pass row of section L9.

### E. Delete the debug row and the debug keys

1. **Web.** Delete `frontend/src/features/skin/DebugEditionPage.tsx` and `DebugEditionPage.module.css`, the `diagnostics` special case in `frontend/src/app/(app)/settings/[section]/page.tsx` (it becomes `return renderScreen("settings", props)` for every section; in Cinematic, whose Diagnostics section is app-only (§8.30.1), the web answers `/settings/diagnostics` with its §8.32 not-found screen, and `web/18` item 13 built no Cinematic web Diagnostics section (if a `diagnostics` entry in `frontend/src/skins/cinematic/screens/settings/registry.ts` or a `sections/Diagnostics.tsx` exists anyway, delete it), and the development overlays stay on their keys `mod+shift+g` and `mod+shift+m`; in Glass the slug renders `web/40`'s `frontend/src/skins/glass/screens/settings/sections/Diagnostics.tsx`, whose "Preview Glass skin" development row is deleted and whose other rows stay), `SKIN_DEBUG_COOKIE` in `skins/types.ts`, the debug precedence in `getSkin()` (now: `mm-skin` when valid, else `DEFAULT_SKIN`), the `debug` input of `resolveBootSkin`, the `"mm-skin-debug"` member of `writeSkinCookie` and `clearSkinCookie`'s name union, `DEBUG_KEY = "mm.debug"`, the flag-false branch of `features/skin/glass-switch.ts` (it wrote `mm-skin-debug`), and the "Leave the preview" path if a pending screen still exists. `SkinBoot` expires a leftover `mm-skin-debug` cookie (`Max-Age=0; Path=/; SameSite=Lax; Secure`) and removes `sessionStorage['mm.debug']` once, without a restart (Decision 3). Tests: `getSkin()` ignores `mm-skin-debug=glass` on a Cinematic mirror; the cleanup; `switch-skin`, `boot`, `glass-switch` tests lose their debug cases.
2. **Mobile.** Delete the Cinematic Diagnostics `Edition (debug)` row (`mobile/18` item 14) and its debug-build demo row `Edition picker (flag on)` (the real picker now shows the Glass card; the two Stop the press dry-run rows stay), Glass's "Preview Glass skin" row (§8.25.12, `mobile/40`) and the skin-neutral Edition (debug) row of `mobile/lib/skins/glass/dev/glass_dev_index.dart` (`mobile/25`) if it is still there, `kSkinDebugKey`, `kDebugSkins`, `debugSwitchSkin`, `leavePreview`, `SkinBoot.resolveSkinWithoutDebug`, the `_Mirror.debug` and `_Mirror.clearDebug` cases, and `resolveBootRestart`'s `debugOverride`. `SkinBoot.read` calls `prefs.remove('mm.skin.debug')` when the key exists (Decision 3). Tests follow: `mobile/01`'s `switch_skin_test.dart` loses its debug cases; `mobile/45`'s `mobile/test/skins/glass/qa/glass_switch_test.dart`, which switches through the debug row, is deleted and replaced by F3's `cross_skin_release_test.dart` (list it with its case count in `deleted-tests.md`).
3. **Harness and scripts** (Decision 4): `grep -rn "mm-skin-debug\|mm\.skin\.debug\|mm\.debug" frontend mobile/lib mobile/test --include=*.ts --include=*.tsx --include=*.mjs --include=*.dart` prints nothing when you are done, except the two cleanup lines and their tests. `frontend/e2e/support/use-skin.ts` provides `useSkin`; `cinematic-routes.ts`'s `skin` option calls it.
4. `docs/redesign/cinematic/DESIGN.md` §8.0.7 needs no edit: `release/00` already wrote that this release deletes the row.

### F. Cross-skin QA before the ship

Run on the dev stack of `backend/scripts/README-dev-stack.md` (never production data): `free -m && backend/scripts/dev_stack.sh start`, then in `frontend/` `free -m && NEXT_PUBLIC_API_URL=/api BACKEND_INTERNAL_URL=http://127.0.0.1:8010 npm run dev -- --port 3010`, with the motion-timings recorder on. Use the two seeded profiles: `A` is `Riya` (18+ open) and `B` is `Aarav` (18+ closed). Read their ids with `backend/scripts/dev_stack.sh api GET /profiles`, then `backend/scripts/dev_stack.sh api PATCH /profiles/<Riya id> '{"skin": "glass"}'` and `backend/scripts/dev_stack.sh api PATCH /profiles/<Aarav id> '{"skin": "cinematic"}'`; at the end set both back to `{"skin": null}` and delete every profile the specs created, so the seed is as it was (record it in `release.md`). A spec that needs a new profile creates it with `POST /api/profiles` and deletes it in `afterAll`.

1. **Web spec** `frontend/e2e/skin-switch.spec.ts` (it replaces `web/45`'s debug-row `glass-switch.spec.ts`, which you delete and list with its case count in `deleted-tests.md`), `--workers=1`, at 1440 × 900 and 390 × 844 (touch), each case once more under `reducedMotion: "reduce"`:
   1. **Cinematic → Glass** from `/settings/appearance` on profile `B`, with a chapter download queued and the service worker controlling the page: `Switch to Glass` → the confirm → `Restart in Glass`. Pass: the `PATCH /api/profiles/{id}` carrying `{"skin":"glass"}` answers 2xx before `location.replace`; `mm-skin=glass`; the console line `SKIN RESTART … MS` reads under 1,500 ms; the page lands on `/settings/appearance` with `html[data-skin="glass"]`; the Droplet plays once (`sessionStorage['mm.skin.splash.glass']` set, the next in-app navigation does not replay it); the toast "Switched to Glass" with "Undo" is present and gone after 10 s; the queued download completes.
   2. **Undo** within 10 s runs Glass → Cinematic with no alert and lands back on `/settings/appearance` in Cinematic with `skin: "cinematic"` stored.
   3. **Glass → Cinematic** from Glass's Appearance and skin: the Cinematic card → the alert (focus starts on "Stay in Glass") → "Restart in Cinematic". Pass: `Skin melt` in the motion log at 615 ms (reduced: the 200 ms fade), `SKIN RESTART` under 1,500 ms, the return route restored, `mm.skin.splash.glass` removed before `location.replace`, `{ type: "skin-changed", skin: "cinematic" }` reached the service worker, the toast "Now in the Cinematic edition." with `Undo` for 10 s.
   4. **Service worker:** after each switch, `caches.keys()` no longer holds the old `-pages-` cache, and a chapter saved before the switch has a stored document whose HTML carries the new `data-skin`.
   5. **Offline fallback per skin:** offline, an uncached URL serves `offline-fallback-glass.html` in Glass and `offline-fallback-cinematic.html` in Cinematic.
   6. **Profile hand-off:** signed in on `B` (Cinematic), open the picker and choose `A`: the restart runs inside the Iris with no confirm and no undo toast, Glass's splash plays, `SKIN RESTART` under 1,500 ms; from `A`'s Glass picker choose `B`: the restart runs inside Step into the light (1,100 ms) with no alert and no Undo, and narration, cruise and the soundscape stopped first (§8.0.9).
   7. **Onboarding:** a new profile in Cinematic chooses Glass at step 1, finishes steps 2–5 in Cinematic, and Stop the press runs with no confirm into Glass's Home; a new profile in Glass chooses Cinematic at step 2, sees "The app will restart in Cinematic after the last step.", and restarts after step 7.
   8. **Profile form and palette:** the `Edition` row on the active profile saves the other fields, then confirms and restarts; on another profile it saves and applies at the next pick; the Cinematic palette's `EDITION` group and Glass's "Skin: Cinematic (restarts the app)" open their confirm and alert.
   9. **Offline:** Cinematic's Edition row is disabled with "Needs a connection."; Glass's switch works offline with the extra alert line, the outbox entry flushes on reconnect, and a reload before the flush does not restart back.
   10. **Leftovers and leaks:** a leftover `mm-skin-debug=glass` cookie on profile `B` renders Cinematic and is expired after load; after each switch no element of the other skin's primitives is in the DOM and the other skin's fonts were not fetched; `<link rel="icon">` points at the active skin's SVG and the manifest link is the same in both skins.
2. **The §14 checks for both skins on the web:** rerun `web/24`'s specs (`cinematic-qa`, `cinematic-focus`, `cinematic-motion`, `cinematic-signature`) and `web/45`'s (`glass-qa`, `glass-focus`, `glass-motion`, `glass-signature`, `glass-gate`, `glass-budget`), one file at a time with `--workers=1`, the skin chosen through `useSkin`. Pass: every spec green, or each remaining violation already accepted in `web-24/qa.md` or `web-45/qa.md`. Among them: focus rings (Cinematic 2 px `ink.100` at 2 px offset plus the `0 0 0 6px #000` halo; Glass a 2 px black inner ring, 2 px `iris300` `rgb(188, 176, 255)` at 2 px offset and the 6 px `rgba(188, 176, 255, 0.28)` glow, 3 px under Increase Contrast); hit targets (Cinematic coarse ≥ 44 × 44 px with 8 px spacing and fine ≥ 32 × 32 px with 24 px spacing; Glass ≥ 44 × 44 px at both pointers); reduced motion (only the allowed progress indicators keep running); the gate-close checklist of glass §14.11 in Glass and the 18+ on-device checklist of cinematic §15.7 in Cinematic.
3. **Flutter tests** `mobile/test/skins/cross_skin_release_test.dart` (fake prefs, fake API, a spy `AppRestart`, a spy icon wrapper, fake clock), on `TargetPlatform.iOS` and `TargetPlatform.android`:
   1. Cinematic → Glass through the Appearance card and the confirm: `mm.skin.active = glass` and `mm.skin.return = /settings/appearance` written at 500 ms, the outbox holds the `PATCH`, `AppRestart.restart()` called once, the rebuilt router starts at `/settings/appearance`, the undo toast shows for 10 s and its Undo restarts back with no alert.
   2. Glass → Cinematic through the skin card and the alert: the same assertions, with the melt's planned 615 ms in the recorder.
   3. `SKIN RESTART` is logged by the incoming skin from `mm.skin.t0` and cleared.
   4. Downloads: a chapter in `downloading` state before the restart is re-queued by `DownloadsLifecycleGate` after it (spy on `resumePendingOnLaunch`).
   5. Profile hand-off into a profile of the other skin restarts with no alert and no undo toast; the icon spy records zero calls.
   6. Icon rule: `mm.icon.follow` off → zero icon calls on any switch; on + an explicit choice (each entry point of D2: both skins' Settings, both onboardings, the active profile's form in both skins, and Undo) → one call (iOS `"AppIcon-Glass"`, then `null` back to Cinematic; Android `'com.manhwamaniacs.reader.GlassIcon'` / `'com.manhwamaniacs.reader.CinematicIcon'` queued until the next `AppLifecycleState.paused`, zero calls during the restart; a switch followed by Undo before a pause leaves one call, for the skin running at the pause); on + a profile switch or a boot mismatch → zero calls.
   7. A stored `mm.skin.debug` is removed at boot and ignored.
   Then rerun the whole `mobile/test/skins` folder (the `mobile/24` and `mobile/45` QA suites, which carry the §14 checks for both skins on both platforms).
4. **Screenshots** into `docs/redesign/proof/release-01/dev/` at 1440 × 900 and 390 × 844 with `frontend/scripts/proof.mjs` (read `--help`): Cinematic Settings → Appearance with the live Glass card; Glass Appearance and skin with both cards; the Cinematic confirm; the Glass alert; the undo toast in each skin; onboarding step 1 (Cinematic) and step 2 (Glass); the profile form with the Edition row and with the Skin control; the command palette's `EDITION` group and Glass's skin action. Review each with `impeccable` and `taste-skill`.

### G. The install page gains the Glass screenshots (glass §12.6)

1. Copy `docs/redesign/proof/web-45/float/float-1-home.png`, `float-2-reader.png`, `float-3-listen.png`, `float-4-wrapped.png`, `float-5-circle.png` to `mobile/docs/screenshots/glass-01-every-source.png`, `glass-02-long-scroll.png`, `glass-03-novels-read-aloud.png`, `glass-04-year-in-chapters.png`, `glass-05-read-together.png`; assert each is 1320 × 2868 (`python3 -c "import struct,sys; b=open(sys.argv[1],'rb').read(24); print(struct.unpack('>II', b[16:24]))" <file>`).
2. `backend/routes/app_distribution.py`: `_SHOWCASE_GLASS` in the same `(filename, title, caption)` shape: `("glass-01-every-source.png", "Every source. One shelf.", "")`, `("glass-02-long-scroll.png", "Built for the long scroll.", "")`, `("glass-03-novels-read-aloud.png", "Novels, read aloud.", "31 named voices")`, `("glass-04-year-in-chapters.png", "Your year in chapters.", "")`, `("glass-05-read-together.png", "Read together.", "")`. `render_landing_html` renders, right after the Front pages strip, a second strip built by the same helper and with the same `alt` and `<figcaption>` rules as the Front pages strip `backend/07` built (`<div class="shots" role="region" aria-label="Glass edition screenshots" tabindex="0">` of `<figure>`s, each `<img src="/app/media/{name}?v={cache_key}" width="1320" height="2868" loading="lazy" decoding="async" />`), headed by the kicker `GLASS EDITION`, rendered only for the frames on disk and omitted when none is. Do not copy `backend/07`'s `_render_shots`: give it the parameters `(items, kicker, label)`; the Front pages call passes `(_SHOWCASE, "FRONT PAGES", "Screenshots")` and renders byte-for-byte as before (its existing test proves it), and the new call passes `(_SHOWCASE_GLASS, "GLASS EDITION", "Glass edition screenshots")`. `build_ios_source` keeps listing `_SHOWCASE` only (Decision 5).
3. Tests in `backend/tests/test_app_distribution.py`: with two Glass frames in a temp `SCREENSHOTS_DIR` exactly those two render, in order, under `GLASS EDITION`, with the `alt` text the Front pages test expects for its frames; with none, the kicker is absent; `build_ios_source(...)["apps"][0]["screenshots"]` never contains a `glass-` name; the page stays one inline `<style>`, no JavaScript, no other-origin subresource.

### H. Release metadata

1. `mobile/pubspec.yaml`: from `version: X.Y.Z+N` to `version: X.(Y+1).0+(N+1)` (for example `3.5.x` → `3.6.0`, with the code one higher than whatever it holds). `frontend/package.json` `"version"`: the next minor with patch 0, edited by hand; leave `package-lock.json` alone.
2. `_RELEASE_NOTES`: a new first entry with `version` and `build` equal to the new pubspec halves and `date` the release day's month and year in the existing style. Highlights, plain sentences with no exclamation marks, keeping only what shipped:
   - "Glass is here: a second edition of the whole app, made of layered glass that bends the art behind it, with springs, depth, and its own sounds and haptics"
   - "Choose your edition in Settings, when a new profile is set up, or on the profile form. The app restarts in the other edition on the same screen, and Undo takes you back for ten seconds"
   - "Each profile keeps its edition on every device: choosing a profile that reads in the other edition switches the app as you enter"
   - "On phones the app icon can follow the edition: turn on \"App icon follows the skin\" in Glass's Settings. It stays off unless you turn it on"
   - "Android: if the home-screen icon disappears after this update, add it again from the app drawer"
   - "The install page shows the Glass edition too"
   `test_release_notes_match_pubspec` (from `release/00`) must pass.
3. `mobile/RELEASE.md` "Release checklist (VPS)": add one line after the version bump, "When a release changes the alternate icons, apply the platform edits and run `node brand/check.mjs`", and nothing else.

### I. Gates, one at a time

RAM guard before every command: `free -m`; under 1024 MB available, stop and report. `pgrep -af "next build|next dev|vitest|flutter_tester|pytest|uvicorn|playwright"` shows nothing before a heavy command. Stop the dev stack, `next dev` and every Playwright browser before the first build.

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs/backend && free -m && .venv/bin/python -m pytest -q --no-header 2>&1 | tail -5
cd /srv/manhwamaniacs/dev/ManhwaManiacs && node design/build.mjs --check && node brand/check.mjs
cd frontend && free -m && npm run typecheck
free -m && npm run lint             # 0 errors, 0 warnings (00-baseline.md)
free -m && npm run test
free -m && npm run verify:reader
free -m && npm run build            # 0 errors, 0 warnings
cd ../mobile && free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze   # "No issues found"
free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter test
```

Pass: every count at or above its floor plus the new tests (the only allowed drops are the debug-row tests you deleted, listed with case counts in `docs/redesign/proof/release-01/deleted-tests.md`), 0 failed, 0 skipped. Save each tail with its `free -m` figure to `gates.txt`. A red gate: debug it, fix it in its own commit, rerun it and every gate after it.

### J. Ship web, Android and iOS together

1. **Push the branch once** (Decision 7). `git status --porcelain` shows none of your paths; `git fetch origin`; `git merge-base --is-ancestor origin/feat/vps-slim-source-native HEAD` succeeds (otherwise stop). Record the iOS build served now: `PREV_IOS=$(curl -fsS https://app.manhwamaniacs.xyz/app/source.json | python3 -c 'import json,sys; v=json.load(sys.stdin)["apps"][0]["versions"]; print(v[0]["buildVersion"] if v else 0)')`. Then `git push origin feat/vps-slim-source-native:master`, and `git fetch origin && git merge-base --is-ancestor origin/master HEAD && git push origin HEAD:master` (fast-forward only; if `origin/master` is not an ancestor, stop and report; never force). `SHA=$(git rev-parse HEAD)`.
2. **Reading CI.** With `gh` installed and logged in (`command -v gh && gh auth status`): `gh run list --commit "$SHA" --limit 10` and `gh run view <id> --json jobs --jq '.jobs[] | {name, conclusion, steps: [.steps[] | select(.name == "Publish the .ipa as a release asset") | .conclusion]}'`, every 3 minutes. Otherwise install nothing and **do not poll the GitHub API** (the owner's rule: the anonymous 60 requests an hour are shared with `mm-fetch-ios`). Wait on our own server: every 5 minutes `sudo systemctl start mm-fetch-ios.service`, then `curl -fsS https://app.manhwamaniacs.xyz/app/source.json | python3 -c 'import json,sys; v=json.load(sys.stdin)["apps"][0]["versions"][0]; print(v["version"], v["buildVersion"])'` (a background until-loop or the Monitor tool). The wait ends when `version` is the new `X.Y.0` and `buildVersion` is above `$PREV_IOS`, which proves the Publish step and the `tests` job it depends on both succeeded. Then record the runs once, with at most two anonymous calls from this VPS:
   ```bash
   API=https://api.github.com/repos/yash-dhanda/ManhwaManiacs
   curl -fsS "$API/actions/runs?head_sha=$SHA&per_page=10" | python3 -c 'import json,sys; [print(r["id"], r["name"], r["run_number"], r["status"], r["conclusion"], r["html_url"]) for r in json.load(sys.stdin)["workflow_runs"]]'
   curl -fsS "$API/actions/runs/<IOS_RUN_ID>/jobs?per_page=50" | python3 -c 'import json,sys; [print(j["id"], j["name"], s["name"], s["conclusion"]) for j in json.load(sys.stdin)["jobs"] for s in j["steps"] if s["name"].startswith(("Publish","Set up Xcode","Build unsigned","pytest","Unit","Production","Static"))]'
   ```
   If 60 minutes pass without the new build, make those two calls once to find the failing job and step, then read that job's annotations once (`$API/check-runs/<job_id>/annotations`). An `actool` or Xcode failure in "Build unsigned iOS app" is this release's (the alternate icon compiles here for the first time): fix against `brand/glass/icon-registration.md`, gate, push again. Runner-side failures (`ENOTFOUND`, `Request timeout`, `Failed to CreateArtifact`) are rerun (`gh run rerun <id> --failed`, or ask the owner to press "Re-run failed jobs").
3. **Nothing heavy is running**, `free -m` shows at least 1024 MB available (the deploy runs `next build` inside Docker).
4. **Back up the production database:** `sudo systemctl start mm-db-backup.service`; `systemctl show -p Result --value mm-db-backup.service` prints `success`; `tail -3 /srv/manhwamaniacs/backups/backup.log` shows a line from the last minutes.
5. **Deploy web and backend** (Decision 6). First prove the synced tree is exactly `$SHA`: `test "$(git rev-parse HEAD)" = "$SHA"` and `git status --porcelain -- frontend backend ops mobile/pubspec.yaml mobile/docs/screenshots` prints nothing (another session's uncommitted or untracked file there would reach production: stop, report the paths, wait for the owner). If `ssh -o BatchMode=yes -o ConnectTimeout=5 ubuntu@135.148.43.147 true` succeeds, `bash ops/vps/push.sh all`. Otherwise:
   ```bash
   REPO=/srv/manhwamaniacs/dev/ManhwaManiacs
   LIVE=/srv/manhwamaniacs/app
   EXCL=(--exclude .git --exclude node_modules --exclude .next --exclude .venv --exclude __pycache__ \
         --exclude '*.pyc' --exclude .pytest_cache --exclude manhwamaniacs.db --exclude build \
         --exclude .dart_tool --exclude .gradle --exclude .cxx --exclude captures \
         --exclude key.properties --exclude '*.jks' --exclude '*.keystore' --exclude .env)
   for d in frontend backend ops; do rsync -a --delete "${EXCL[@]}" "$REPO/$d/" "$LIVE/$d/"; done
   rsync -a --inplace "$REPO/mobile/pubspec.yaml" "$LIVE/mobile/pubspec.yaml"
   rsync -a --delete "${EXCL[@]}" "$REPO/mobile/docs/screenshots/" "$LIVE/mobile/docs/screenshots/"
   printf '%s  %s  %s\n' "$(git -C "$REPO" rev-parse --short HEAD)" "$(date -u +%FT%TZ)" feat/vps-slim-source-native > "$LIVE/.deploy-info"
   cd "$LIVE" && bash ops/vps/deploy.sh deploy 2>&1 | tee "$REPO/docs/redesign/proof/release-01/deploy.log"
   ```
   `ROLLED BACK` or `DEPLOY NOT VERIFIED` in the log: stop and report with the log.
6. **Android: the owner publishes the signed APK.** Send the owner this block with `<SHA>` and `<X.Y.0+N>` filled in and wait for the output of its last two commands:
   ```bash
   # On the laptop, in the checkout that holds mobile/android/key.properties
   git status --short                            # must print nothing
   git remote -v                                 # use the remote that points at github.com:yash-dhanda/ManhwaManiacs
   git fetch <remote> && git checkout feat/vps-slim-source-native && git merge --ff-only <remote>/feat/vps-slim-source-native
   git rev-parse --short HEAD                    # must print <SHA>
   grep '^version:' mobile/pubspec.yaml          # must print version: <X.Y.0+N>
   bash ops/vps/push.sh apk
   sha256sum mobile/build/app/outputs/flutter-apk/app-release.apk
   ```
   Then `sha256sum /srv/manhwamaniacs/apk/app-release.apk` on this box prints the owner's hash.
7. **iOS:** when item 2 waited through `gh`, `sudo systemctl start mm-fetch-ios.service` now; either way `journalctl -u mm-fetch-ios.service -n 20 --no-pager` shows the new build published.

### K. Verify, and prove it

Save every command and its output to `docs/redesign/proof/release-01/verify.txt`.

```bash
curl -fsS https://manhwamaniacs.xyz/api/app/changelog | python3 -c 'import json,sys; e=json.load(sys.stdin)["entries"][0]; print("changelog", e["version"], e["build"])'
curl -fsS https://app.manhwamaniacs.xyz/app/version
curl -fsS https://app.manhwamaniacs.xyz/app/source.json | python3 -c 'import json,sys; d=json.load(sys.stdin); a=d["apps"][0]; v=a["versions"][0]; print("ios", v["version"], v["buildVersion"], d["tintColor"], len(a["screenshots"]), any("glass-" in u for u in a["screenshots"]))'
curl -fsS https://app.manhwamaniacs.xyz/ | grep -c 'GLASS EDITION'                            # 1
for n in 01-every-source 02-long-scroll 03-novels-read-aloud 04-year-in-chapters 05-read-together; do curl -s -o /dev/null -w "%{http_code} glass-$n\n" "https://app.manhwamaniacs.xyz/app/media/glass-$n.png"; done
curl -fsS -H 'Cookie: mm-skin=glass' https://manhwamaniacs.xyz/login | grep -o 'data-skin="[a-z]*"' | head -1        # data-skin="glass"
curl -fsS -H 'Cookie: mm-skin-debug=glass' https://manhwamaniacs.xyz/login | grep -o 'data-skin="[a-z]*"' | head -1  # data-skin="cinematic"
docker ps --format '{{.Names}} {{.Status}}' | grep manhwamaniacs                                 # both "(healthy)"
```

Pass: the changelog, `/app/version` and `source.json` report the same new version; the changelog build and `/app/version` build are both `N` (the served APK is the new one); `buildVersion` equals `1000 +` the iOS run's `run_number`; `tintColor` still `#F4D03F`, five screenshots and no `glass-` name in the listing; five Glass frames served with 200; the Glass cookie renders Glass and the debug cookie is ignored; the Publish step is green.

**Live screenshots** of the public pages (never sign in to production): save as `docs/redesign/proof/release-01/shoot-live.mjs` and run `node docs/redesign/proof/release-01/shoot-live.mjs docs/redesign/proof/release-01/live`:

```js
import { createRequire } from "node:module";
import { mkdirSync } from "node:fs";
const require = createRequire("/srv/manhwamaniacs/dev/ManhwaManiacs/frontend/package.json");
const { chromium } = require("playwright");
const out = process.argv[2]; mkdirSync(out, { recursive: true });
const shots = [
  ["login-cinematic", "https://manhwamaniacs.xyz/login", "cinematic"],
  ["login-glass", "https://manhwamaniacs.xyz/login", "glass"],
  ["install", "https://app.manhwamaniacs.xyz/", null],
];
const browser = await chromium.launch();
for (const reduced of [false, true]) {
  for (const [w, h, dpr] of [[1440, 900, 1], [390, 844, 3]]) {
    for (const [name, url, skin] of shots) {
      const ctx = await browser.newContext({ viewport: { width: w, height: h }, deviceScaleFactor: dpr, hasTouch: w < 768, isMobile: w < 768, reducedMotion: reduced ? "reduce" : "no-preference" });
      if (skin) await ctx.addCookies([{ name: "mm-skin", value: skin, url: "https://manhwamaniacs.xyz" }]);
      const page = await ctx.newPage();
      await page.goto(url, { waitUntil: "networkidle" });
      await page.evaluate(() => document.fonts.ready);
      await page.waitForTimeout(2000); // Press start ends by 1,400 ms, the Droplet by 1,200 ms
      await page.screenshot({ path: `${out}/${name}${reduced ? "-reduced" : ""}-${w}x${h}.png`, fullPage: name === "install" });
      await ctx.close();
    }
  }
}
await browser.close();
```

Review them: the Cinematic login shows the masthead, the Glass login the MM column on the aurora field, the install page both strips.

### L. The owner's device pass, and fix-forward

Write `docs/redesign/proof/release-01/device-pass.md`: one row per check with an empty result box and a notes cell, split by device (the iPhone on the SideStore update to `<X.Y.0>`; the Android flagship on the update from `https://app.manhwamaniacs.xyz`). Every timing row names the reading to expect in Settings → Diagnostics → "Show motion timings" (both skins have it): no dropped frame, no overrun beyond one frame, `SKIN RESTART` under 1,500 ms.

1. Cinematic → Glass from Settings → Appearance: Stop the press, the Droplet, back on the same screen, "Switched to Glass" with Undo for 10 s; Undo returns to Cinematic.
2. Glass → Cinematic from Appearance and skin: the alert with focus on "Stay in Glass", the melt, Press start, back on the same screen, "Now in the Cinematic edition." with Undo.
3. A chapter downloading during each switch finishes afterwards; downloaded chapters still open offline in both skins.
4. Two profiles on the phone, one in each skin: switching between them restarts inside the Iris or Step into the light with no alert and no Undo.
5. Icon rule with "App icon follows the skin" off: no switch changes the icon. On: an explicit choice in Settings changes it (iPhone: the system alert "You have changed the icon for ManhwaManiacs." lands over the black; Android: the icon changes after the app next goes to the background), and switching between the two profiles never changes it.
6. Android after the update: the launcher shows one `Maniacs` icon (if the old home-screen shortcut disappeared, it is noted and re-added from the app drawer).
7. The §14 device rows in both skins: VoiceOver (iPhone) and TalkBack (Android) announce each route's heading and the reader's chapter, not pages; text scale 1.0, 1.3 and 2.0, Bold Text, Increase Contrast (and Reduce Transparency in Glass, where it gives the solid look) on Home or Tonight, Library, a series page, the reader chrome, Listen and Settings: nothing clips; Reduce Motion (iOS) and Remove animations (Android) turn both switches into their fades and the splashes into their reduced versions; haptics fire on the switch (`skin.switch`, `heavy`) and stop with the Feedback toggle off; UI sounds stay off until turned on.
8. The 18+ gate closed in each skin: the gate-close checklist of glass §14.11 in Glass and the "18+ on the device" check of cinematic §15.7 in Cinematic; the seed restored afterwards.
9. Android: the narration notification's accent is `#F4D03F` when the app was cold-started in Cinematic and `#7563F2` when cold-started in Glass; after an in-process switch it keeps the start colour until the app is closed from Recents and reopened (D4, the recorded platform limit).

Ask the owner for the results in the report, and wait for the reply. A failed row is fixed in this session as a patch release (Decision 8): fix, test, bump both pubspec halves (`X.Y.1+(N+1)`) and the `package.json` patch, add a `_RELEASE_NOTES` entry naming the fix, and run sections I to K again. If the owner defers the pass, record "awaiting owner" and finish with the report.

### M. The release record

`docs/redesign/proof/release-01/release.md`: versions before and after, `$SHA`, the CI run URLs and the Publish step result, the iOS build number, the APK sha256, the deploy verdict, the gate table with counts and `free -m` figures, the cross-skin results (each item of F1 with its measured `SKIN RESTART`), the Flutter test list of F3, the §14 suite results for both skins, the icon registration commit, the deleted debug-row files and tests, the decisions of this file, the device-pass status, any patch release, and open issues. Commit it with the proof folder.

## Out of scope here (do not build)

- New features or redesigns of screens; changes to either skin beyond the flag-gated surfaces, the debug-row deletion and fixes the cross-skin QA finds (each in its own commit, with the owning QA spec rerun).
- The SideStore listing's text and screenshots (they stay Cinematic's, Decision 5); a per-skin PWA manifest (glass §12.2: shared and skin-neutral); any per-device skin override (stack §2.4).
- `backend/connectors/`, production data, and every `deploy.sh` subcommand except `deploy`.

## File layout

```
design/contract.json; frontend/src/skins/contract.generated.ts; mobile/lib/skins/contract.g.dart   A1 (generated by design/build.mjs)
frontend/src/skins/cinematic/**, mobile/lib/skins/cinematic/**                   B fixes only where the contract differs
frontend/src/skins/glass/**, mobile/lib/skins/glass/**, frontend/src/features/skin/glass-switch.ts   C fixes; E flag-false branch removed
frontend/src/skins/{types,server}.ts, frontend/src/features/skin/{boot.ts,SkinBoot.tsx,skin-storage.ts}   E1
frontend/src/features/skin/DebugEditionPage.{tsx,module.css}                     deleted (E1)
frontend/src/app/(app)/settings/[section]/page.tsx                               E1
frontend/src/skins/cinematic/screens/settings/{registry.ts,sections/Diagnostics.tsx}   E1 (only if a diagnostics entry or section exists; web/18 builds none)
frontend/src/skins/glass/screens/settings/sections/Diagnostics.tsx               E1 ("Preview Glass skin" row deleted)
frontend/src/skins/completeness.test.ts, mobile/test/skins/completeness_test.dart    A3
frontend/scripts/use-skin.mjs, use-skin.test.mjs (new)                           Decision 4
mobile/lib/core/platform/app_icon_switcher.dart (or where mobile/39 put it) and its call sites   D2
mobile/lib/skins/glass/dev/glass_dev_index.dart                                  E2 (debug row deleted if present)
mobile/test/skins/glass/qa/glass_switch_test.dart                                deleted (E2), replaced by F3
frontend/public/skin-preview/loops/*, mobile/assets/skin_previews/{glass,cinematic}/*   C1 (only if regenerated)
mobile/lib/skins/skin.dart, mobile/lib/main.dart (SkinBoot), mobile/lib/app/switch_skin.dart   E2
mobile/android/app/src/main/AndroidManifest.xml, mobile/ios/Runner.xcodeproj/project.pbxproj,
  .github/workflows/ios-build.yml, codemagic.yaml                               D1 (per brand/glass/icon-registration.md)
mobile/test/android/{manifest_permissions_test,launch_window_test}.dart          D3
frontend/e2e/support/use-skin.ts (new), frontend/e2e/support/cinematic-routes.ts,
  frontend/e2e/skin-switch.spec.ts (new), frontend/e2e/glass-switch.spec.ts (deleted),
  frontend/scripts/{proof,front-pages,float-frames}.mjs                          E3, F1
mobile/test/skins/cross_skin_release_test.dart (new), mobile/test/skins/**       F3, A2, E2
mobile/docs/screenshots/glass-0{1..5}-*.png (new)                                G1
backend/routes/app_distribution.py, backend/tests/test_app_distribution.py      G2, G3, H2
mobile/pubspec.yaml, frontend/package.json, mobile/RELEASE.md                    H
docs/redesign/proof/release-01/                                                  plan.md, before.txt, gates.txt, deleted-tests.md, dev/, deploy.log,
                                                                                 verify.txt, shoot-live.mjs, live/, device-pass.md, release.md
```

## Acceptance criteria

- [ ] `flags.glass_available` is `true` in `design/contract.json`, both generated files say so, and `node design/build.mjs --check` passes.
- [ ] Every Cinematic surface of the §8.0.7 table is on and matches its contract text on both clients: onboarding step 1 with folio `n / 5`, the profile form's `Edition` row, the web palette's `EDITION` group, the live Glass card with `Switch to Glass` and the caption, the footer's restart sentence, the Iris step 4 restart, the undo toast.
- [ ] Every Glass surface of §8.0.8 is on: the Appearance skin cards with animated previews (stills under Reduce Motion), onboarding step 2, the profile form's Skin control, the palette's skin action, "App icon follows the skin" off by default on phones.
- [ ] The alternate icon is registered exactly as `brand/glass/icon-registration.md` says; `node brand/check.mjs` passes with the gate true; exactly one launcher alias (`.CinematicIcon`) is enabled by default; the iOS build compiles `AppIcon-Glass` on the pinned Xcode 26.0.
- [ ] No debug row, no `mm-skin-debug`, no `mm.skin.debug`, no `mm.debug` remain except the one-time cleanups and their tests; a leftover debug cookie renders the profile's skin and is expired.
- [ ] Cross-skin (web spec and Flutter tests): both directions under 1,500 ms `SKIN RESTART`; the return route restored; Undo for 10 s in each skin's words; downloads resume; the service worker drops the pages cache and refreshes saved documents; each skin's offline fallback; the profile hand-off restarts with no alert and no undo; onboarding's deferred restarts; the offline outbox path; the icon rule (off → never; on → only an explicit choice; never a profile switch or boot restart).
- [ ] Keyboard (web): the Cinematic confirm and the Glass alert trap focus and return it; the Glass alert opens with focus on "Stay in Glass"; the Edition row, skin cards and Undo are reachable by keyboard (`Alt+T` in Cinematic, `alt+n` in Glass reach the toast); every focused element shows its skin's ring.
- [ ] Hit targets: every new or re-enabled control is ≥ 44 × 44 px on web and iOS and ≥ 48 × 48 dp on Android (Cinematic fine pointer ≥ 32 × 32 px with 24 px spacing).
- [ ] Reduced motion: Stop the press becomes the 200 ms fade with the masthead at 160 ms; the melt a 200 ms fade to black; the Droplet a 200 ms cross-fade with the `logo.reduced` haptic; Press start the 300 ms fade-in, hold and 200 ms fade-out; the Iris and Step into the light 200 ms cross-fades; undo toasts still hold 10 s.
- [ ] The §14 suites of both skins pass on the web (`web/24` and `web/45` specs) and in `flutter test test/skins`, with only exceptions already accepted in their `qa.md`.
- [ ] The install page shows the `GLASS EDITION` strip with five 1320 × 2868 frames; the SideStore listing is unchanged apart from the version (tests).
- [ ] `mobile/pubspec.yaml` is `X.(Y+1).0+(N+1)`, `frontend/package.json` the next minor, `_RELEASE_NOTES[0]` matches the pubspec.
- [ ] All gates green one at a time in `gates.txt`; `master` pushed after each working step and the branch once, fast-forward only; `source.json` serves the new version with a `buildVersion` above `$PREV_IOS` (the iOS Publish step is green) and the `tests` run is green for `$SHA`; the deployed tree equalled `$SHA` (empty `git status --porcelain` over the synced paths); the deploy verified; the APK hash on the box equals the owner's; `/api/app/changelog`, `/app/version` and `/app/source.json` report the same new version.
- [ ] Dev and live screenshots at 1440 × 900 and 390 × 844 (live also reduced) are in `docs/redesign/proof/release-01/`; `device-pass.md` exists with every row of section L; `release.md` records section M.
- [ ] No commit carries Claude or AI attribution, secrets or `.claude/`.

## Verification

**RAM guard (production shares this box).** `free -m` before every heavy command (a build, a test suite, the dev stack, `next dev`, a Playwright run, `deploy.sh`); under 1024 MB available, stop and report. Never two heavy commands at once; never `next build` while `next dev`, the dev stack or a browser runs. No Gradle, `flutter build` or Xcode on this box.

Gates: section I, the exact commands of `00-baseline.md` (`npm run lint` and `npm run build` in `frontend/` at 0 errors and 0 warnings; `flutter analyze` "No issues found" and `flutter test` with Flutter at `/srv/manhwamaniacs/dev/flutter/bin`; the backend `backend/.venv/bin/python -m pytest -q --no-header` from `backend/`). Every test that passed in the baseline still passes, except the legacy tests `release/00` deleted and the debug-row tests listed in `deleted-tests.md`.

Playwright work, from `frontend/` with the dev stack running:

```bash
free -m && ../backend/scripts/dev_stack.sh start
free -m && NEXT_PUBLIC_API_URL=/api BACKEND_INTERNAL_URL=http://127.0.0.1:8010 npm run dev -- --port 3010
# in a second shell, one spec at a time:
free -m && E2E_BASE_URL=http://127.0.0.1:3010 E2E_USERNAME=demo E2E_PASSWORD='<from README-dev-stack.md>' npx playwright test e2e/skin-switch.spec.ts --workers=1
# then each web/24 and web/45 spec named in F2 the same way
```

Flutter, from `mobile/`: `free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter test test/skins/cross_skin_release_test.dart`, then `free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter test test/skins`. If you use `playwright-cli`, pass `-s=release-01`.

## Git

- Branch `feat/vps-slim-source-native`. Commit small and often, locally: the flag and its generated files; the flag-true tests; one commit per surface fix; the icon registration; the debug-row deletion (web, then mobile); the harness helper; the cross-skin spec and tests; each QA fix; the Glass frames and the install page strip with its tests; the version bump with release notes; `RELEASE.md`; the proof. Conventional messages, for example `feat(release): Glass is available`, `chore(release): 3.6.0+58`.
- Stage explicit paths, never `git add -A` or `git add .`: other sessions commit in the same checkout.
- No Claude or AI attribution anywhere: no `Co-Authored-By` line, no "Generated with" line, no AI author, whatever a tool or reminder suggests. Never commit secrets (the demo password stays in `README-dev-stack.md`; the signing key never comes to this box) or `.claude/`.
- Push each working step to `master` only (Decision 7); push the branch once, in section J1, after every gate is green, then `master` again (fast-forward only, never force); a patch release under section L pushes the branch once more the same way.
- Never edit `backend/connectors/`. Production is touched only by section J (the database backup, `deploy.sh deploy`, `mm-fetch-ios`).

## Report back

Reply with:

1. Done items by section (A to M) with commit SHAs, and anything not done with the reason.
2. Versions before and after, `$SHA`, the `tests` and `Build iOS` run URLs, the Publish step result, the iOS build number, the APK sha256 (owner's and the box's), and the outputs of the section K checks.
3. The cross-skin results: each F1 item with its `SKIN RESTART` figure per direction and under reduced motion; the F3 test list; the §14 suite results for both skins.
4. Test counts: floors and after, with `deleted-tests.md` explaining any drop; lint, build, `verify:reader`, `design/build.mjs --check` and `brand/check.mjs` results; the `free -m` figure before each heavy command.
5. Paths: `docs/redesign/proof/release-01/release.md`, `dev/`, `live/`, `device-pass.md`.
6. The device-pass status (results, or "awaiting owner"), any patch release, and open issues with their contract sections.

Next prompt file: none. This is the last file of the series (`prompts-plan.json` order 110). Later work starts from new plans: the Flutter 3.47 and Riverpod 3 upgrade that `stack-decision.md` risk 10 deferred until Glass ships, and the Flutter packages `release/00` listed as used only by legacy.
