# Glass DESIGN.md: verdicts on the mobile audit (find-mobile.md)

Verifier's method: I tried to refute each of the 27 findings. For each one I grepped `glass/DESIGN.md` (4,184 lines) and read the sections it cites, then checked the claim against `inventory/00-decisions.md`, `stack-decision.md`, `inventory/mobile.md`, `cinematic/DESIGN.md` (both skins ship in one app binary and share one data layer, so a Cinematic decision about the shared native layer binds Glass too) and the real sources:

- the Flutter 3.44.6 SDK at `/srv/manhwamaniacs/dev/flutter` (`material/predictive_back_page_transitions_builder.dart`, `widgets/routes.dart`, `cupertino/route.dart`);
- `liquid_glass_widgets` 1.7.2 in `design-ref/`;
- `mobile/android/app/src/main/AndroidManifest.xml`, `mobile/ios/Runner/Info.plist` and `mobile/lib`.

**Result:** 27 confirmed, 0 refuted. Parts of four findings (MOBILE-10, MOBILE-11, MOBILE-19, MOBILE-27) are already settled in `cinematic/DESIGN.md` for the shared native layer. Those fixes now reuse Cinematic's decision instead of the auditor's new mechanism. I rewrote the fix in 17 of the 27 findings because it was wrong, internally inconsistent, vague or heavier than it needed to be. In the list below, each "Rewritten" note says what changed.

---

## Verdicts

| ID | Verdict | Severity | Reason |
|---|---|---|---|
| MOBILE-1 | Confirmed | high | SDK source confirms the problem. In `predictive_back_page_transitions_builder.dart`, `buildTransitions` returns `FadeForwardsPageTransitionsBuilder` whenever `route.popGestureInProgress` is false. As a result, every Android button, key or programmatic push fades instead of doing §8.0.4's slide. **Rewritten:** the auditor's T4 rim value (`rgba(255,255,255,0.16)`) is not the §2.4.3 T4 rim. Its "commit on springDismiss" also cannot be built, because Android back events carry no velocity and `TransitionRoute.handleCommitBackGesture` drives the route controller itself. |
| MOBILE-2 | Confirmed | medium | `ModalRoute.popGestureEnabled` (`widgets/routes.dart`) returns false while `!animation.isCompleted`. The Cupertino-style drag end also finishes with a fixed 350 ms duration and a curve (`_kDroppedSwipePageAnimationDuration`), not with a velocity spring. So §4.9 "a back swipe during a push grabs the incoming page" and §4.10 Pop "with the release velocity" cannot come from `SwipeablePage` as specified. **Rewritten:** the auditor left the choice between accepting the SDK behaviour and forking the package open. The final fix decides it: fork only the drag end (Law 3 is load-bearing across the document) and follow the SDK's no-catch rule for routes (the catch window is at most 621 ms, and the SDK rule protects navigator state). |
| MOBILE-3 | Confirmed | high | Android back is defined only for routes, `?sheet=` sheets, alerts (§7.11) and anchored pickers (§8.0.3). Bulk select, the stack overview, guided view, the dialogue overlay, cinema mode, text selection, the flipped share side, settings search, onboarding steps, Wrapped and the picker have Esc rules (§8.14.7, §7.35, §9.2.3, §8.7, §8.5) but no Android back rule. **Rewritten:** the auditor's onboarding rule ("on step 1 back acts as Skip to Home") would loop, because §8.7 "Resume" sends every Home visit back to `/welcome?step=n`. |
| MOBILE-4 | Confirmed | medium | §8.0.4 "Reader → back" assumes a recessed detail sheet beneath the reader. Nothing covers a reader that is the first route (a cold deep link, the `audio_service` notification, the skin-switch return route). mobile.md A064 and S26 define this case today. |
| MOBILE-5 | Confirmed | high | §8.0.7 gives iOS no reader system-UI mode. mobile.md G11 runs both readers `immersiveSticky`. On Android, Flutter drops the insets of hidden bars from `viewPadding`, so "inset 16 + safe area" collapses to 16 px inside the gesture-navigation zone. The reader's top groups have no y position. **Rewritten:** the auditor hedged ("or `getInsetsIgnoringVisibility` if `viewPadding` reads 0"). The fix now states which source each platform uses. |
| MOBILE-6 | Confirmed | medium | §8.0.1 and §8.14.11 name only four landscape controls. The novel reader has no landscape layout. A `medium` sheet is about 203 px tall on a landscape phone. **Rewritten:** the auditor moved the page readout to the rail's trailing end, which contradicts §8.0.1 ("settings + page top-right"). The readout stays top-right. |
| MOBILE-7 | Confirmed | high | §3.2 and §3.7 cap only `display` through `title2`. Chips (32), segmented controls (36/32), the title capsule (36), status capsules (32), tags (24/22) and toasts (44/60) have fixed heights with no large-text rule. §3.3's reader-chrome rule names no controls and no threshold. **Rewritten:** the auditor's padding table was wrong for S buttons (8 px of padding gives 36 > 34 at 1.0×) and inconsistent for tags. It is replaced by one derived rule. The Wrapped "card ⋯" does not exist, so that entry now uses Wrapped's existing accessibility button row (§9.2.3). |
| MOBILE-8 | Confirmed | low | §3.3 moves dock labels "to long-press tooltips", but §7.15 already uses long-press on a tab for its menu, so one gesture has two meanings. |
| MOBILE-9 | Confirmed | medium | A grep for keyboard, `viewInsets`, `adjustResize` and `onDrag` finds only the search orb (§7.4) and Setup. The fix matches `liquid_glass_widgets` 1.7.2's own `GlassModalSheet`, which already snaps to full when a focusable descendant gains focus (`glass_modal_sheet_state.dart`). `adjustResize` is already in the manifest, so that line only confirms the current setting. |
| MOBILE-10 | Confirmed | low | `MediaStore` `RELATIVE_PATH` needs API 29, and minSdk is 24 (§8.0.7, `build.gradle.kts`). The Android "Where it lives" copy is missing. **Rewritten:** `cinematic/DESIGN.md` §8.23 already specifies the shared export through the `mm/media` channel method `saveDownload`, with path `Download/ManhwaManiacs/Exports/{series}/` and an API 24–28 fallback (app-documents export plus Share, no permission). Glass must use the same channel and folder. The auditor's `WRITE_EXTERNAL_STORAGE` flow would add a permission, a refusal state and a second folder for one app. It also runs against the owner's flagship-only rule. |
| MOBILE-11 | Confirmed | medium | `share_plus` requires `sharePositionOrigin` on iPad, and Glass has iPad frames. Android `ShareResult` cannot report "saved". **Partly refuted:** the iOS crash is already fixed for the shared binary, because `cinematic/DESIGN.md` §9.2.5 adds `NSPhotoLibraryAddUsageDescription` in the native-plugin commit and Glass ships after Cinematic. **Rewritten:** on Android, Save image reuses Cinematic's `mm/media` MediaStore insert, which gives a real "saved" state. |
| MOBILE-12 | Confirmed | medium | The contradictions are real. The §5.1 table maps `rigid(i)` and `soft(i)` to API 34 constants, but the paragraph below it routes every `rigid(i)` and `soft(i)` to a 12 ms one-shot. `nav.push` is `ahap:rise{d}` in §5.2 but a 12 ms pulse in §5.1. The vibrator path needs `VIBRATE`, and the manifest declares only `INTERNET`. |
| MOBILE-13 | Confirmed | low | §7.33 lists "You (activity)" and §11 lists "Circle". Neither covers For you, Statistics or collection detail, which have pull to refresh in mobile.md S11 #20, S12 #17 and S25 #13. **Rewritten:** the auditor's list gave Members pull to refresh but also excluded "Settings sub-pages", and Members is a Settings sub-page (§8.25.8). |
| MOBILE-14 | Confirmed | medium | §8.0.5 says a rail owns horizontal drags. The Continue stack sits in the Continue rail (§8.8, §8.17), AI cards sit in Home rails (§9.1.1), and both also carry horizontal item swipes (§7.7, §7.34, §11). A leftward swipe therefore has three possible owners. |
| MOBILE-15 | Confirmed | medium | §4.6 says single taps are never delayed. In paged mode a side-band tap turns the page and a double tap zooms, so the second tap zooms a different page. In the strip a tap toggles the chrome. In guided view a side-band tap steps a panel. What a double tap does on these surfaces is undefined. **Rewritten:** the auditor fixed the chrome-revert case only for the strip. The paged centre band and the strip's tap-to-scroll bands had the same problem. |
| MOBILE-16 | Confirmed | medium | §6's state machine covers audio focus loss but not `AppLifecycleState.paused` or a locked screen. `UIBackgroundModes audio` is in Info.plist. §15.7 runs sensors only while their screen is visible, so shake to extend cannot work with the screen locked. |
| MOBILE-17 | Confirmed | medium | §8.14.11 says `wakelock_plus` keeps the screen on for iOS unconditionally. §8.14.5 and §8.25.3 make it a switch (K05, default false). Android and the novel reader have no rule at all. |
| MOBILE-18 | Confirmed | low | §2.3 depends on "device corner radius", but no document names where the value comes from. **Rewritten:** the auditor proposed a private iOS key and a new channel method. The pinned `liquid_glass_widgets` 1.7.2 already ships `GlassThemeHelpers.resolveAdaptiveRadius(context)` (46 or 54 on Face ID iPhones), which is the helper `research/glass-language.md` line 709 meant. Android keeps §2.3's 36. |
| MOBILE-19 | Confirmed | medium | The auto-queue of the next chapter (mobile.md S19, A072, K20) is never mentioned. `cinematic/DESIGN.md` makes it a shared engine duty with per-profile switches, so in Glass it would run with no way to turn it off. **Partly refuted:** high refresh rate is already specified ("high refresh rate on launch", §8.0.7; per-reader chips, §8.14.5), so it needs no new row. **Rewritten:** the switches are aligned with Cinematic's. |
| MOBILE-20 | Confirmed | low | mobile.md S27 and the manifest's ML Kit comment ("OcrChannel.isAvailable still probes for real, so a device where this never completed hides the feature") show that the device OCR engine can be missing. Glass gates Dialogue search and Extract text only on the server's `ocr` capability. |
| MOBILE-21 | Confirmed | low | §12.6 names "download notifications through `audio_service`". No section specifies download notifications, downloads are foreground-only (§8.22), and `audio_service` posts media notifications only. **Rewritten:** the fix is only the edit to that line; no notification design is added. |
| MOBILE-22 | Confirmed | low | Integrating the gyroscope's rotation rate and clamping it to ±25° drifts and eventually pins at the clamp. Gravity for the genre field, the flame and the hero tilt is an accelerometer quantity. **Rewritten:** one method chosen (the auditor offered two). |
| MOBILE-23 | Confirmed | low | Android 14 (API 34) has `UiModeManager.getContrast()` and `addContrastChangeListener`, so "Android has no public high-contrast signal" is out of date. Flutter's `highContrastOf` is iOS-only. The Reduce Transparency method is named two ways, and no change stream is specified. |
| MOBILE-24 | Confirmed | low | Several controls are cited but never placed: "the reader's ⋯" (§9.1.3), where neither reader's chrome has a ⋯; "the player's ⋯" (§8.16.2, §9.4.2), which is absent from the full player's layout; the mini-player save icon (§8.16.1). The novel top-right group also reaches 5 icons against §7.2's maximum of 4. **Rewritten:** the in-reader "Previously on" entry reuses the title capsule's series sheet (manga) and adds one row to the Contents sheet (novel), instead of adding a Previously on row to the Ambient settings. |
| MOBILE-25 | Confirmed | low | §8.29 has no install-step copy and no download mechanism, and G9's re-check on every resume is missing. That re-check lives today in a legacy widget (`features/settings/widgets/whats_new_auto_show.dart` invalidates `appUpdateProvider`), which is deleted at the flip unless it moves (`stack-decision.md` §2.3). **Rewritten:** the auditor's step 3 ("Your library and downloads stay") contradicts the sheet's own "Uninstall version 1.2 first" note. |
| MOBILE-26 | Confirmed | low | "12 % band … starts at x ≥ 24 px" can be read in two ways. **Rewritten:** the fix also says who owns a vertical drag that starts in the band, because the strip scrolls vertically everywhere. |
| MOBILE-27 | Confirmed | low | §8.4 has no rule for when "Create account" is enabled and no email check. §8.0.10 points to §8.4 for the copy of `weak_password`, `invalid_username`, `invite_code_required` and `invite_code_invalid`, but §8.4 gives copy only for `username_taken`. **Rewritten:** reuses Cinematic's username rule, which is the backend's pattern (`cinematic/DESIGN.md` §8.4). |

Outside this audit's findings, but found while verifying MOBILE-11: §15.11 marks `share_plus` 13.3.0 and `flutter_soloud` 5.1.4 as *reused*. Cinematic's ledger actually pins 12.0.2 and 4.1.7, and explains why the newer majors do not resolve on Flutter 3.44.6 (`win32 ^6`, and `native_toolchain_c` needs a newer `meta`). One app has one `pubspec.yaml`, so Glass's versions must match Cinematic's. The consistency or stack lens should pick this up.

---

## Confirmed

The final fixes, in the order to apply them to `glass/DESIGN.md`.

### MOBILE-1 (high): a Glass Android page transition, not the stock builder

Replace `PredictiveBackPageTransitionsBuilder` in §8.0.5 (Android row) and §15.3 (`glass_skin.dart`) with `GlassPageTransitionsBuilder` in `mobile/lib/skins/glass/transitions/glass_page_transitions.dart`. Register it for `TargetPlatform.android` in the Glass `PageTransitionsTheme`. The router keeps `MaterialPage` on Android.

- **Gesture detector.** It always wraps the page in a copy of the SDK's private `_PredictiveBackGestureDetector` (Flutter 3.44.6 `material/predictive_back_page_transitions_builder.dart`, BSD-3). The copy forwards `PredictiveBackEvent`s to `route.handleStartBackGesture`, `handleUpdateBackGestureProgress`, `handleCommitBackGesture` and `handleCancelBackGesture`.
- **No gesture in progress** (`route.popGestureInProgress == false`: a button, a key, 3-button back or programmatic navigation): the §8.0.4 slide, drawn by a shared `GlassPushTransition` widget (the iOS route in MOBILE-2 uses the same one).
  - The incoming page slides 100 % → 0 from the trailing edge.
  - Driven by `secondaryAnimation`, the outgoing page moves 0 → −30 % under a `#000000` scrim going 0 → 0.30.
  - `transitionDuration` = `reverseTransitionDuration` = 621 ms, on a curve sampled from `springPage` (k 146.0, c 24.17).
- **Gesture in progress:** the predictive geometry.
  - Scale 1 → 0.90.
  - x shift `screenWidth / 20 − 8` toward the swipe edge.
  - y shift `(touchY − height / 2) / 20`, clamped to ±`(height / 20 − 8)`.
  - Corner radius 0 → 36 through `ClipRSuperellipse`.
  - The card is drawn with the T4 specular rim (0.5 px, `S` 0.30, §2.4.3) and the T4 shadow `0 24px 64px rgba(0,0,0,0.60)`.
- **Commit and cancel** copy the commit and cancel phase mapping of the SDK's `_PredictiveBackSharedElementPageTransition`, which maps the route's own reverse and forward animation onto the remaining progress over the 621 ms durations above. Android back events carry no velocity, so there is no spring hand-off here.
- **Add to §8.0.5:** "FadeForwards never plays in Glass."

### MOBILE-2 (medium): the iOS route the contract can actually be built on

Add `mobile/lib/skins/glass/routes/glass_swipe_route.dart`, containing `GlassSwipePage` and `GlassSwipePageRoute`. It is a copy of `swipeable_page_route` 0.4.8's page, route and back-gesture controller (MIT; keep the licence header), with three changes:

1. `transitionDuration` = `reverseTransitionDuration` = 621 ms. The transition is `GlassPushTransition` (MOBILE-1), on the `springPage`-sampled curve for button, key and programmatic pushes and pops.
2. `dragEnd` calls `controller.animateWith(SpringSimulation(...))` with the release velocity `velocityX / width`: `springDismiss` toward 0 for a pop, `springSettle` toward 1 for a cancel. The fixed-duration `animateTo` and `animateBack` calls go.
3. The full-width swipe stays (`canOnlySwipeFromEdge: false`). Readers keep their leading 20 px strip.

`router.dart` (§15.3) and §8.0.5's iOS row use `GlassSwipePage`. `swipeable_page_route` stays in the pubspec for Cinematic, and §15.11's Glass row changes to "vendored route, forked from 0.4.8".

**Amend §4.9, and the Catch row of §4.10:** "On Flutter a back gesture (iOS swipe or Android predictive back) starts only after the push has settled, because `ModalRoute.popGestureEnabled` refuses a gesture while the route animates. Catch-in-flight applies to sheets, the droplet, toasts, pagers and zooms before 80 %, not to route pushes."

### MOBILE-3 (high): an Android back order

Add an "Android back order" table to §8.0.5 that matches the web's Esc order (§8.0.6, §8.14.7). Back does the first rule that applies:

1. Clear a text selection (the novel reader's glass menu closes with it).
2. Close an anchored picker, menu or context menu.
3. Close the stack overview (fan or flat list).
4. Flip a share side back.
5. Exit bulk select mode (the selection is cleared).
6. Remove the dialogue overlay or hit lens.
7. Leave guided view to the strip at the current panel.
8. Leave cinema mode.
9. Close the settings search overlay.
10. Otherwise, pop the route.

Rules 1 to 9 are `PopScope(canPop: false, onPopInvokedWithResult:)` bound to that state, so the system shows no predictive preview while one of them applies.

**Takeovers:**

- **Onboarding:** on steps 2 to 7, back goes to the previous step. On step 1, back leaves the app (the system back-to-home animation). The saved `onboarding_step` resumes on the next visit (§8.7 Resume); it never skips to Home, because Home would send the user straight back to `/welcome`.
- **Wrapped:** back closes with the swipe-down motion. If the share side is showing, back flips it back first.
- **Profile picker as the session gate:** back leaves the app.
- **Profile picker reached from You or the switcher:** back returns to the previous route with no hand-off.
- **Step into the light:** back is ignored while the 1,100 ms hand-off runs.

### MOBILE-4 (medium): leaving a reader with nothing beneath

Add to §8.14.2 and §8.15.3: "When the reader cannot pop (`!Navigator.of(context).canPop()`, which covers a cold deep link, a notification tap and the skin-switch return route), back goes to `feature` `/sources/:sourceId/series/:seriesKey` in its full-page, deep-link form (§8.0.3), with a 200 ms cross-fade. The button, the iOS 20 px strip and Android back all do this. The iOS strip still tracks 1:1, over black. Android wraps the reader in `PopScope(canPop: false)` for this case only."

Add to §8.16.2: "Tapping the `audio_service` notification or the lock-screen artwork opens `/novels/:sourceId/:seriesKey/:chapterKey?listen=1` for the playing chapter. It is pushed over the current stack when the app is running, and is the first route on a cold start."

### MOBILE-5 (high): reader system UI and insets

Add a "Reader system UI" row to §8.0.7 and to §8.14.11.

- **Mode:** both platforms call `SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky)` on reader enter and restore `edgeToEdge` on exit. The status bar stays hidden while the chrome shows. On iOS the home indicator auto-hides (the engine sets `prefersHomeIndicatorAutoHidden` when the bottom overlay is hidden).
- **Insets:**
  - iOS reads `MediaQuery.viewPaddingOf(context)`. The safe area survives a hidden status bar.
  - Android reads new `mm/platform` method `display.stableInsets`: `getInsetsIgnoringVisibility(systemBars() | displayCutout())` divided by density. Flutter drops hidden bars from `viewPadding` in immersive mode.
  - Call this value `inset`.
- **Positions:**
  - The top groups sit at y = `inset.top + 8`.
  - Left and right edges sit at `max(inset.left, 16)` and `max(inset.right, 16)`.
  - The bottom capsule, the minimised pill, the cruise pill, guided view's counter pill and the "Match 1 of 3" capsule sit at `max(inset.bottom, MediaQuery.systemGestureInsetsOf(context).bottom) + 16` from the bottom.
  - The novel progress hairline sits at y = `inset.top`.
- **Cutout:** Android keeps `LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES`, so pages run under the cutout and the chrome avoids it.

### MOBILE-6 (medium): the landscape phone readers

Extend §8.0.1's "Landscape phone reader" row and §8.14.11. Edges follow MOBILE-5's `max(inset.left/right, 16)`.

**Manga, landscape:**

- **Top left:** back + title capsule, the title at most 40 % of the width.
- **Top right:** the page capsule (`mono` "18 / 40", the go-to button of §8.14.2), plus a glass group of bookmark, settings and ⋯. The ⋯ menu holds Download (with the §7.29 states), Cruise, Guided view, Previous chapter and Next chapter.
- **Bottom scrub rail:**
  - A 44 px hit strip along the bottom edge, with a 3 px track and a 12 px thumb.
  - The 120 × 164 magnifier sits above the thumb.
  - In read-all the rail is segmented by chapter with 2 px gaps.
  - A running cruise shows its pill above the rail's trailing end.

**Novel, landscape:**

- The column is centred at its measure.
- **Top left:** back + title.
- **Top right:** bookmark, listen, Aa and ⋯. Voices and Soundscape are in the ⋯.
- **Bottom:** the bottom capsule stays (previous, percentage, next). The listen row floats bottom-right, 320 wide.

**Sheets on landscape phones:** `medium` and `large` both use screen height − safe-top − 10. The sheet is `min(560, width − 16)` wide and centred.

### MOBILE-7 (high): large text on fixed-height controls

Add to §3.3:

1. **One threshold factor.** `f = MediaQuery.textScalerOf(context).scale(17) / 17`. Dock labels hide and rows stack at `f ≥ 1.6` (AX1, Android 1.8); grids drop to 2 columns at `f ≥ 1.9` (AX2). This replaces "above `xxxL`", which Flutter cannot read.
2. **Heights are minimums, not fixed.**
   - Every text-bearing control uses `height = max(token, ceil(scaledLineHeight) + 2 × padV)`, where `padV = (token − the role's line height at 1.0×) / 2`. Each control therefore grows exactly when its text needs more room.
   - Resulting `padV`: chips 6; segmented thumb 6 (4 compact) inside the 2 px track padding; title capsule 8; status capsule 7; buttons L 14, M 11, S 7; toasts 11 (one line) and 8 (two lines); tags 4; status tags 3; menu rows 10.
   - Capsules keep `rCapsule`.
3. **Clamp text inside capsule controls.** Chips, segmented controls, the title and status capsules, tags, badges and `tabLabel` use `TextScaler.clamp(maxScaleFactor: 1.5)`. Body text in rows and cards is not clamped.
4. **Reader chrome.** All chrome text uses `TextScaler.clamp(maxScaleFactor: 1.3)`. At `f > 1.3`, two controls move and nothing else does:
   - the cruise button leaves the bottom capsule;
   - the download control leaves the top-right group;
   - both become the first row of the reader settings sheet ("Download", "Cruise").
5. **Wrapped.** The 360 × 640 frame ignores text scale (it is a poster). At `f ≥ 1.35`, the accessibility button row (y 24–68, §9.2.3) is shown and gains a fourth 44 px `glassThin` button, "Read this card". It opens a `large` sheet listing the card's eyebrow, headline, figure text and footnote at the scaled `body` size, and auto-advance pauses while the sheet is open.

Update §14.7 to point to these rules.

### MOBILE-8 (low): dock labels at large sizes

In §3.3, at `f ≥ 1.6` dock labels move to semantics only; the dock shows no tooltip. The long-press menu of each tab gains a non-interactive header row with the tab's name in `headline` ("Library"), so the menu names its tab. Delete "long-press tooltips" from §3.3.

### MOBILE-9 (medium): the on-screen keyboard

**Add to §7.10:**

- When a field in a sheet takes focus, the sheet moves to `large` on `sheetSnap`. This matches `GlassModalSheet` 1.7.2, which already snaps to full on a focused descendant.
- The field scrolls to 30 % of the visible height (`Scrollable.ensureVisible(alignment: 0.3)`).
- The sheet's content gets bottom padding of `MediaQuery.viewInsetsOf(context).bottom`, and returns on `sheetSnap` when the keyboard closes.
- Popovers anchored to the reader capsule (go to page, go to a percentage) rise by the keyboard height on `snappy`.

**Add to §7.15:**

- While `viewInsets.bottom > 0`, the dock, search orb and accessory leave on `minimize`, translating down by their height + safe-bottom. They return on `minimize` when the keyboard closes.
- Every scroll view uses `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag`.
- Android keeps the existing `windowSoftInputMode="adjustResize"`.

### MOBILE-10 (low): Android Save to Downloads on every supported API

Replace §8.22's Android destination with the shared export that Cinematic's §8.23 already specifies:

- Writes go through the `mm/media` channel method `saveDownload(relativePath, name, mime, path)`, with `RELATIVE_PATH = "Download/ManhwaManiacs/Exports/{series}/"` on API 29 and up and no permission. One app has one folder, whichever skin saved the file.
- The result alert reads "Saved to Download/ManhwaManiacs/Exports/Solo Leveling".
- On API 24–28 the export stays in the app's documents directory, and the result alert offers "Share" (`share_plus`) instead of a path. No storage permission is declared.
- Add the Android "Where it lives" copy: "Downloaded chapters live inside ManhwaManiacs. For a copy other apps can open, use Save to Downloads."

### MOBILE-11 (medium): the phone share flow

In §9.2.4, and for the image viewer (§7.31) and the page menu's "Save page image":

- Every `share_plus` call passes `sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size` of the tapped control. It is required on iPad.
- **Save image, iOS:** opens the share sheet. `ShareResult.raw == "com.apple.UIKit.activity.SaveToCameraRoll"` gives the toast "Saved to Photos"; any other success gives "Shared"; a dismissal is silent. `NSPhotoLibraryAddUsageDescription` is the key Cinematic's native-plugin commit already adds (`cinematic/DESIGN.md` §9.2.5). Glass references it and adds nothing.
- **Save image, Android API 29 and up:** inserts the PNG into `MediaStore.Images` at `Pictures/ManhwaManiacs` through the shared `mm/media` channel (Cinematic §9.2.5), with no permission, and shows the toast "Saved to Pictures/ManhwaManiacs".
- **Save image, Android API 24–28:** the button is hidden, and Share remains.
- **Share on Android:** a success gives "Shared"; a dismissal is silent.

### MOBILE-12 (medium): one Android haptic rule

Rewrite the paragraph under §5.1's table:

- **Literal intensity:** a pattern with a literal intensity (`rigid(0.6)`, `soft(0.5)`, `soft(0.4)` …) uses the table's constant. Those constants need API 34+, or API 30+ for the `CONFIRM`, `REJECT` and `GESTURE_*` rows.
- **Runtime-scaled calls:** only these use `VibrationEffect.createOneShot(12, round(i × 255))` (API 26+): `throw.commit`, `motion.catch`, and the velocity-scaled catches and throws of §5.1.
- **`nav.push`:** on Android it plays gaimon's conversion of `rise{d}.ahap.json`, as §5.2 says. It is not a one-shot.

Also:

- Declare `<uses-permission android:name="android.permission.VIBRATE"/>`.
- Add `haptics.systemEnabled` to `mm/platform`, reading `Settings.System.HAPTIC_FEEDBACK_ENABLED`. Every vibrator-path pattern (one-shots and gaimon waveforms) is skipped when it is 0. `performHapticFeedback` already honours that setting.

### MOBILE-13 (low): one pull-to-refresh list

Keep one list in §7.33, and have §11's "Pull down at the top" row point to it.

- **Pull to refresh:**
  - Home.
  - Library, every section except Downloads.
  - Sources and Source catalogue.
  - Updates.
  - For you: refetches `GET /library/world/recommendations` and `GET /library/suggest/availability` and never re-asks.
  - Statistics: refetches `GET /library/statistics?days=` for the current range.
  - Collections and collection detail.
  - Circle, You, and Members (§8.25.8).
- **No pull to refresh:** Downloads, both readers, Wrapped, and every other Settings page.

### MOBILE-14 (medium): no horizontal swipes on items inside rails

- **Continue stack:** remove "swiping the stack left reveals Previously on" (§7.7, §8.8 Gestures, §9.1.3 explicit entries, §11 row). "Previously on" is reached through:
  - the stack's long-press context menu, where it is the first row;
  - a trailing ⋯ on the stack (a 44 px hit area on its top-right corner), which §11's alternative column already assumes;
  - `p` on a focused stack.
- **AI cards in rails:** "Not interested" is reached by the lift-and-throw of §9.1.1, by ⋯, or by `Delete`. The §7.34 "Not interested" swipe row stays only in For you's vertical lists on phones.
- **§11:** delete the row "Swipe the Continue stack left", and change "AI cards" in "Swipe a row left or right" to "For you answer and section cards (phones)".

### MOBILE-15 (medium): double tap over immediate single taps

Add to §8.14.3 and §9.4.3:

- **Paged manga and guided view:** a double tap is recognised only in the centre band. A tap in a side band acts at once and never opens a double-tap window. In guided view the centre band has no single-tap action, so its double tap ("the whole page for 1.5 s") needs no revert.
- **Strip (with "Tap to scroll" on):** the same centre-band-only rule applies.
- **Chrome toggles in the centre band** (the strip in its default mode, and the paged centre band): when a second tap lands within 280 ms and 24 px, the chrome toggle made by the first tap is reverted instantly (no fade) before the zoom runs on `camera`. A double tap never changes chrome visibility.

### MOBILE-16 (medium): audio in the background

Add to §6's state machine for `AppLifecycleState.paused` and screen lock:

- **Narration** keeps playing through `audio_service`: iOS `UIBackgroundModes audio`, and on Android the foreground service of type `mediaPlayback` that Cinematic's `AudioServiceActivity` setup declares.
- **The soundscape while narration plays** keeps playing, ducked by 12 dB, and follows the sleep timer's 8 s fade.
- **The soundscape otherwise** fades out over 1.5 s on `paused` and resumes on `resumed`.
- **UI sounds** never play in the background.
- **Shake to extend** works only while the app is in the foreground (§15.7 sensors rule). Its switch caption in the sleep menu reads "Works while ManhwaManiacs is open."

### MOBILE-17 (medium): one keep-awake rule

Write this once in §8.14.5, and point §8.15 and §9.4.1 to it:

- **Switch on:** `WakelockPlus.enable()` while a manga or novel reader is in the foreground. The switch defaults off. It is per profile (the §8.14.5 rule), seeded once from the device value K05; add that row to §8.25.3's migration table.
- **Always on:** while cruise runs or guided view is open, whatever the switch says.
- **Release:** `disable()` on leaving the reader and on `AppLifecycleState.paused`. When the switch is off, it is also released 2 s after cruise stops.
- **Narration** does not hold the wakelock.

Delete "`wakelock_plus` keeps the screen on" from §8.14.11's iOS line.

### MOBILE-18 (low): where `rSheet` comes from

Replace §2.3's `rSheet` definition:

- **iOS phones:** `GlassThemeHelpers.resolveAdaptiveRadius(context)` from `liquid_glass_widgets` 1.7.2. This is the helper `GlassModalSheet` already uses when its radii are null: 46 on Face ID iPhones under 900 pt tall, 54 at 900 pt and taller, and 0 on Home-button iPhones, where `rSheet` falls back to 36. It is read once per launch.
- **Android, tablets and web:** 36.

§15.3 passes the value to `topBorderRadius`, `bottomBorderRadius` and `fullTopBorderRadius`. There is no native channel method and no private API.

### MOBILE-19 (medium): auto-queue and download switches

- **Add to §8.14.4.** "Saving the next chapter: the shared engine duty of `cinematic/DESIGN.md` §8.14. When a downloads scope exists and `client_downloads` is on, opening a manga chapter whose next chapter is not saved queues that one chapter, once per open. It is skipped when 'Download on Wi-Fi only' is on and `connectivity_plus` does not report Wi-Fi, or when the storage cap or the 1.5 GB floor has been reached. It shows no toast and no haptic. The Library badge and the accessory's Downloading row count it."
- **Add to the Downloads Storage tab (§8.22), phones.** Three switches, the same ones Cinematic's STORAGE tab has. Without them, a per-profile behaviour set in the other skin would keep running with no way to change it:
  - "Download on Wi-Fi only" (K20, device, default off);
  - "Save the next chapter while I read" (per profile, default on);
  - "Download new chapters of followed series automatically" (per profile, default off; the foreground-only pass Cinematic defines).
- **High refresh rate:** no change. §8.0.7 already sets it on launch, and §8.14.5's chips pin it per reader.

### MOBILE-20 (low): phones without an OCR engine

Add the device capability `ocrEngineAvailable` to §8.0.8, read once per launch from the existing `OcrChannel` availability probe. When it is false:

- hide "Extract text" in §7.29, in the Downloads chapter rows (§8.22), in the dialogue overlay (§8.14.9) and in the recap's "no source text" lens (§9.1.3);
- keep Dialogue search, because chapters extracted on another device still search. Its phone hint row (§8.23) becomes "This phone can't extract text. Chapters extracted on another device still show up here."

### MOBILE-21 (low): notification icon wording

In §12.6, change "narration lock-screen and download notifications through `audio_service` 0.18.19" to "the narration lock-screen and media notification through `audio_service` 0.18.19". Downloads post no notification (§8.22: foreground only).

### MOBILE-22 (low): the right sensor, no drift

In §2.4.2 rule 5, §8.7 step 4, §9.2.2 and §8.8:

- All tilt effects on phones read gravity from `accelerometerEventStream(samplingPeriod: Duration(milliseconds: 33))` (`sensors_plus` 7.1.0, 30 Hz per §15.7), low-passed with α = 0.15.
- Pitch and roll are measured relative to the device pose captured at screen entry.
- **Light angle:** `135° + 25° × clamp(roll / 30°, −1, 1)`.
- **Hero tilt:** ±6° from pitch and roll.
- **Flame lean and genre-field gravity:** the gravity vector's screen-plane components, scaled so that 1 g equals 400 px/s² in the field.
- Drop "rotation rate integrated" and every other gyroscope reference on phones. The web keeps `DeviceOrientationEvent`.

### MOBILE-23 (low): accessibility signals

- **Reduce Transparency:** in §4.11, one name, `a11y.reduceTransparency` (as in §15.3), plus an event stream on the same channel fed by `UIAccessibility.reduceTransparencyStatusDidChangeNotification`, so the skin swaps materials live.
- **Contrast:** add `a11y.contrastLevel`, which reads Android API 34+ `UiModeManager.getContrast()` (−1 to 1) and streams `addContrastChangeListener`. A value ≥ 0.5 turns Increase Contrast on, OR-ed with the in-app switch. Change "Android has no public high-contrast signal" to "Android 14+ through `a11y.contrastLevel`; older Android relies on the in-app switch".

### MOBILE-24 (low): referenced controls that were never placed

- **Full player (§8.16.2):** add a trailing header ⋯ (`glassThin` 32, 44 hit) holding Save audio and Soundscape. This is "the player's ⋯" that §8.16.2 and §9.4.2 cite.
- **Mini player (§8.16.1):** no save icon. Delete "and as a trailing icon on the mini player".
- **Readers (§9.1.3):** replace "the reader's ⋯ → Previously on" with two entries:
  - manga: the title capsule → series sheet → its "Previously on" row;
  - novel: a "Previously on" row (machine sparkle) at the top of the Contents sheet (§8.15.6) when the profile has progress in the book.
- **Novel top-right group (§8.15.3):** while a soundscape plays, the Aa button carries a 6 px `iris400` dot badge. Its accessible name becomes "Type and page, soundscape playing". The soundscape sheet opens from Aa → Ambient → Soundscape or `shift+s`. The group stays at four icons (§7.2).

### MOBILE-25 (low): the Android APK update

In §8.29:

- **Download update** opens the APK URL in the external browser (`url_launcher`, `LaunchMode.externalApplication`), as today (A102).
- **The install-steps alert:** title "Install the update", three numbered droplets:
  1. "Open the downloaded file from your notifications or the Downloads app."
  2. "Allow installs from this source if Android asks, then tap Install."
  3. "Come back here. This notice clears once the new version is running."

  Button "Got it".
- **Re-check:** `GET /app/version` runs on every `AppLifecycleState.resumed`, at most once every 15 minutes. The resume hook moves out of the legacy `features/settings/widgets/whats_new_auto_show.dart` into a provider under `features/settings/providers/`, in a no-pixel commit, before the flip (`stack-decision.md` §2.3).

### MOBILE-26 (low): the brightness band

Rewrite the §8.14.3 row and the §11 row:

- **Band on iOS:** x ∈ [24, 24 + 0.12 W], which is 24–71 px on a 390 px phone.
- **Band on Android:** x ∈ [0, 0.12 W], with only its middle 200 dp excluded from system back.
- **Ownership:** a drag that starts inside the band belongs to the band. It activates once `abs(dy) > 2 × abs(dx)` after 10 px, and the strip does not scroll from a drag that starts there.
- Portrait phones only, as before.

### MOBILE-27 (low): Register validation

In §8.4:

- **"Create account" stays disabled until** the username matches the backend's `^[A-Za-z0-9][A-Za-z0-9_.\-]{2,63}$`, the password has at least 8 characters, the confirmation matches, and the invite code is filled when the server requires one.
- **Username:** helper "3–64 letters, digits, dots, dashes or underscores, starting with a letter or digit." (Cinematic §8.4). It is checked live, and the helper turns `danger` when the value fails.
- **On blur:**
  - a password under 8 characters shows "At least 8 characters";
  - an email that is present and fails `^[^@\s]+@[^@\s]+\.[^@\s]+$` shows "Enter a valid email address, or leave it blank."
- **Copy for the server codes that §8.0.10 delegates to §8.4:**
  - `weak_password`: "At least 8 characters".
  - `invalid_username`: the helper line in `danger`.
  - `invite_code_required`: "Enter the invite code for this server."
  - `invite_code_invalid`: "That invite code isn't valid."

Each error uses `errorRing`, the 6 px shake and the `error` haptic.
