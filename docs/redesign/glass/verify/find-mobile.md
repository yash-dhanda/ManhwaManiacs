# Glass DESIGN.md audit: mobile coverage (iOS and Android)

Lens: every screen, element, state and interaction in `inventory/mobile.md`, specified for iOS and Android, including gestures, haptics, back behaviour (iOS edge swipe, Android predictive back), safe areas, system text scale up to 200 % and platform differences. Every "missing" claim below was checked by grepping the whole of `glass/DESIGN.md` (4,184 lines). Screen coverage against mobile.md S01 to S34, G1 to G14, K01 to K40 and §6a to §6c is otherwise complete; the findings are the places where an implementation session would build the wrong thing or have to guess.

Summary: 27 findings (5 high, 13 medium, 9 low).

---

## MOBILE-1 · high · §8.0.4, §8.0.5 (Android), §15.3 `glass_skin.dart`

**Problem.** Every Android push and pop is specified twice, with incompatible mechanisms. §8.0.4 and the §4.10 Push/Pop moves require the Glass slide on the `page` spring (incoming 100 % → 0 from the trailing edge, outgoing −30 % under `rgba(0,0,0,0.3)`, settle 621 ms). §8.0.5 and §15.3 prescribe `MaterialPage` with the stock `PredictiveBackPageTransitionsBuilder`. That builder only animates while a back gesture is in progress; for button taps, keys, the 3-button back key and programmatic navigation it falls back to `FadeForwardsPageTransitionsBuilder` (450 ms fade-forward), so no Android push would ever slide. The stock builder also draws no glass, so "floats as a glass card" cannot come from it.

**Evidence.** §8.0.4: "Push (row, button, link) | Incoming page slides in from the trailing edge on `page` (100 % → 0); the outgoing page moves −30 % and dims under `rgba(0,0,0,0.3)`". §8.0.5: "Android | `MaterialPage` with `PredictiveBackPageTransitionsBuilder` (the page shrinks to 90 % and floats as a glass card…)". §15.3: "PageTransitionsTheme with PredictiveBackPageTransitionsBuilder". `research/gestures-nav.md` line 106: "It falls back to `FadeForwardsPageTransitionsBuilder`, and the default duration rose from 300 ms to 450 ms."

**Fix.** Replace the stock builder with `GlassPageTransitionsBuilder` (`mobile/lib/skins/glass/transitions/glass_page_transitions.dart`), registered for `TargetPlatform.android` in the skin's `PageTransitionsTheme`:
- No gesture in progress (button, key, 3-button back, programmatic): the §8.0.4 slide driven by `route.animation`, `transitionDuration` = `reverseTransitionDuration` = 621 ms, curve sampled from `springPage` (k 146.0, c 24.17); `secondaryAnimation` moves the outgoing page 0 → −30 % under a `#000000` scrim 0 → 0.30.
- `route.popGestureInProgress`: the predictive geometry (scale 1 → 0.90, x shift `screenWidth / 20 − 8` toward the swipe edge, y shift `(touchY − height / 2) / 20` capped at `height / 20 − 8`, corner radius 0 → 36 through `ClipRSuperellipse`, the T4 rim `rgba(255,255,255,0.16)` 0.5 px and shadow `0 24px 64px rgba(0,0,0,0.60)` painted around the card); commit finishes on `springDismiss` from the gesture's progress, cancel returns on `springSettle`.
- Build it on the SDK's `_PredictiveBackGestureDetector` pattern (copy, since it is private), as `research/flutter-motion-libs.md` step 3 describes. Add to §8.0.5: "FadeForwards never plays in Glass."

## MOBILE-2 · medium · §8.0.5 (iOS), §4.9, §4.10 Push/Pop, §15.11

**Problem.** The iOS route contract cannot be built with the chosen package as written. §4.9 makes route transitions springs that a back swipe can catch mid-push, and §4.10 Pop releases on `settle` or `dismiss` with the finger's velocity. `SwipeablePage`, like `CupertinoPageRoute`, refuses a pop gesture until `route.animation` is `completed`, and finishes a release with its own duration and curve. DESIGN.md sets no transition duration and no `transitionBuilder`, so the implementer must guess between forking the package and accepting duration-based pops.

**Evidence.** §4.9: "A **back swipe during a push animation** grabs the incoming page where it is." §4.10 Pop: "`page` (back gesture: 1:1, then `settle` or `dismiss` with the release velocity)". §8.0.5: "`swipeable_page_route` 0.4.8 `SwipeablePage(canOnlySwipeFromEdge: false)`". `research/gestures-nav.md` line 164 lists `transitionBuilder`, `backGestureDetectionWidth` and the other parameters; DESIGN.md uses none of them.

**Fix.** Specify `SwipeablePage(canOnlySwipeFromEdge: false, transitionBuilder: GlassPageTransition.ios)` with 621 ms forward and reverse durations (subclass `SwipeablePageRoute` and override `transitionDuration` / `reverseTransitionDuration` if `SwipeablePage` exposes no parameter). The builder draws §8.0.4's geometry from `animation` with a curve sampled from `springPage`. Amend §4.9: "On Flutter (iOS and Android) a back gesture starts only after the push has settled (the SDK rule); catch-in-flight applies to sheets, the droplet, toasts and zooms before 80 %." If velocity-carrying release stays a must, name the fork explicitly: `mobile/lib/skins/glass/routes/glass_swipe_route.dart`, a copy of the 0.4.8 gesture controller whose `dragEnd` calls `controller.animateWith(SpringSimulation(springPage.description, value, target, velocityX / width))`.

## MOBILE-3 · high · §8.0.3 (URL state rule), §8.0.5, §11

**Problem.** Android system back (gesture or 3-button) is defined only for routes, `?sheet=` sheets, alerts and anchored pickers. Every in-screen mode that Esc closes on the web has no Android back result. Predictive back also has to know in advance (`PopScope.canPop`) whether back is consumed in place (no system preview) or pops the route (preview plays). The modes with no back result are:
- bulk select mode (§7.35 "Esc or Done exits");
- the stack overview (§7.37 "Esc closes");
- guided view (§9.4.3's exit list);
- the dialogue overlay and hit lens (§8.14.9);
- cinema mode (§8.14.2);
- the novel reader's text selection and its glass menu (§8.15.3);
- the flipped share side (§9.2.4 "Esc flips it back");
- the settings search overlay (§8.25);
- onboarding steps (§8.7 "Esc skips the step");
- Wrapped (§9.2.3);
- the profile picker, where the session gate and the picker reached from You behave differently (§8.5 "Esc returns to the app when a profile is already active");
- the Step into the light hand-off while it runs.

Mobile already intercepts back in the novel reader today (S26).

**Evidence.** §8.0.3: "Every sheet … is URL state … so Android back, browser back and the iOS swipe close it; the only exceptions are pickers anchored to a control…". §8.0.5: "**Wrapped and onboarding** are `NoTransitionPage` takeovers with no back swipe at all; Wrapped closes by swipe down or its close button, onboarding by 'Skip'." No Android-back rule exists anywhere for the other modes listed above (grep `android back`, `system back`, `PopScope`).

**Fix.** Add an "Android back order" table to §8.0.5 and state that it matches the web's Esc order. Back does the first rule that applies:

1. clear a text selection;
2. close an anchored picker, menu or context menu;
3. close the stack overview (fan or flat list);
4. flip a share side back;
5. exit bulk select mode (selection cleared);
6. remove the dialogue overlay or hit lens;
7. leave guided view to the strip at the current panel;
8. leave cinema mode;
9. close the settings search overlay;
10. otherwise, pop the route.

Rules 1 to 9 use `PopScope(canPop: false, onPopInvokedWithResult:)` bound to that state, so the system shows no predictive preview while one is active.

Takeovers and the picker:
- **Onboarding:** back goes to the previous step. On step 1, back acts as "Skip" to Home. It never leaves the app mid-onboarding.
- **Wrapped:** back closes, with the same motion as swipe down. If the share side is showing, back flips it back first.
- **Profile picker as the session gate:** back leaves the app (the system back-to-home animation).
- **Profile picker reached from You or the switcher:** back returns to the previous route with no hand-off. Back is ignored while the 1,100 ms hand-off runs.

## MOBILE-4 · medium · §8.0.4 "Reader → back", §8.14.2, §8.15.3 Back

**Problem.** Nothing says how you leave a reader when nothing is beneath it. Readers are root-navigator routes and can be the first route after:
- a cold-start deep link;
- a tap on the `audio_service` notification;
- the skin-switch restart that "lands on the same route" (§8.25.2 step 5);
- "Recap ready → Open".

§8.0.4 assumes "the detail sheet recessed beneath". Mobile defines the case today, and the notification tap target is not stated either.

**Evidence.** §8.0.4: "Reader → back | Edge swipe drags the reader right (1:1), showing the detail sheet recessed beneath". mobile.md A064: "S15: pop, or go to the series page when nothing is beneath; S19: always go to the source series page". S26: "Android back is intercepted (PopScope) to leave via the series page when nothing is beneath".

**Fix.** Add to §8.14.2 and §8.15.3: "When the reader cannot pop (`!Navigator.of(context).canPop()`), back (the button, the iOS 20 px strip, Android back) goes to `feature` `/sources/:sourceId/series/:seriesKey` as the full-page (deep-link) form of §8.12/§8.13, with a 200 ms cross-fade. The iOS strip still tracks 1:1 over black. Android wraps the reader in `PopScope(canPop: false)` for this case only." Add to §8.16.2: "Tapping the `audio_service` notification or the lock-screen artwork opens `/novels/:s/:k/:c?listen=1` for the playing chapter, pushed over the current stack when the app is running, or as the first route when cold."

## MOBILE-5 · high · §8.0.7, §8.14.2, §8.15.3, §8.14.11 (reader system UI and insets)

**Problem.** The readers' system UI and insets are underspecified:
- **iOS:** nothing says what the status bar and home indicator do in the readers, although mobile G11 runs both readers in `immersiveSticky` on both platforms today.
- **Android:** only `immersiveSticky` is named, without saying whether the bars return with the chrome.
- **Top groups:** the reader's top groups have no vertical position at all.
- **Bottom capsule:** "inset 16 + safe area" collapses to 16 px once immersive mode zeroes `MediaQuery.padding`. That places the capsule, and the cruise pill's vertical drag, inside the Android gesture-navigation inset and beside the iOS home indicator.
- **Also unaddressed:** the novel reader's 2 px top hairline "at the very top of the screen" (under the Dynamic Island or a cutout) and landscape cutouts.

**Evidence.** §8.0.7: "**iOS:** status bar light; edge-to-edge…" (no reader mode) and "**Android:** … the readers switch to `immersiveSticky`". §8.14.2: "**Top-left group:** back (44; …) + title capsule" (no offset) and "**Bottom capsule** (56 tall, inset 16 + safe area, max 520 wide)". §8.15.3: "Progress hairline: 2 px at the very top of the screen". mobile.md G11: "Reading mode (both readers): `immersiveSticky`."

**Fix.** Add a "Reader system UI" row to §8.0.7 and §8.14.11.
- **Modes:** both platforms enter `SystemUiMode.immersiveSticky` on reader enter and restore `edgeToEdge` on exit. The status bar stays hidden while the chrome shows (no bar pops in with the chrome). On iOS the home indicator auto-hides in immersive mode.
- **Insets:** use the stable insets of the hidden bars and cutout, not the live padding. That is `MediaQuery.viewPaddingOf(context)`, or Android `getInsetsIgnoringVisibility(systemBars() | displayCutout())` through `mm/platform` if `viewPadding` reads 0 while immersive.
- **Positions:**
  - top groups at y = `viewPadding.top + 8`;
  - left and right edges at `max(viewPadding.left, 16)` and `max(viewPadding.right, 16)`;
  - bottom capsule, minimised pill, guided-view counter pill and "Match 1 of 3" capsule at `max(viewPadding.bottom, MediaQuery.systemGestureInsetsOf(context).bottom) + 16` from the bottom;
  - the novel hairline at y = `viewPadding.top`.
- **Cutout:** Android keeps `LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES`, so pages run under the cutout while the chrome avoids it.

## MOBILE-6 · medium · §8.0.1 "Landscape phone reader", §8.14.11, §8.15

**Problem.** The landscape phone reader names four controls only (back + title top-left, settings + page top-right, and a slim bottom scrub rail). What is missing:
- where the bookmark, download control, cruise button, previous/next chapter, guided-view button and listen row go;
- any landscape layout for the novel reader;
- landscape sheet detents: `medium` = 52 % of ≈ 390 px ≈ 203 px;
- the rail's spec after it moves from a vertical trailing-edge rail to a horizontal bottom rail (magnifier position, hit strip, read-all segmentation);
- which side the cutout is on.

**Evidence.** §8.0.1: "Landscape phone reader | … Chrome shrinks to two corner capsules (back + title top-left, settings + page top-right), the bottom capsule becomes a slim scrub rail". §8.14.11: "Landscape phone: the chrome collapses to two corner capsules … and a slim bottom scrub rail". §8.15 has no landscape line.

**Fix.** Specify the landscape layouts:
- **Manga:**
  - Top-left capsule: back + title, the title at most 40 % of the width.
  - Top-right glass group: bookmark, settings and ⋯. The ⋯ menu holds Download, Cruise, Guided view, Previous chapter and Next chapter, with their usual glyphs.
  - Bottom scrub rail: a 44 px hit strip along the bottom edge, inset `max(viewPadding.left/right, 16)`, with a 3 px track and a 12 px thumb. The 120 × 164 magnifier sits above the thumb. The rail is segmented by chapter in read-all. The page readout (`mono`) sits at the rail's trailing end.
  - A running cruise shows its pill above the rail's trailing end.
- **Novel:**
  - The column is centred at its measure.
  - Top-left: back + title. Top-right: bookmark, listen, Aa and ⋯, with Voices and Soundscape in the ⋯.
  - The bottom capsule stays (previous, percentage, next). The listen row floats bottom-right, 320 wide.
- **Sheets on landscape phones:** `medium` and `large` both use height − safe-top − 10. The sheet is `min(560, width − 16)` wide and centred.

## MOBILE-7 · high · §3.3, §14.7, §7.1 to §7.20, §7.14, §7.15

**Problem.** Only title roles are capped, and only list rows, grids and rails have rules for large text. At Android 2.0 / AX2 (factor 1.94), every fixed-height text container overflows:
- chips (32 tall, `subhead` 15/20 → 29/39);
- segmented controls (36, or 32 in sheets, with 39 px lines);
- the nav-row title capsule (36, 39 px lines);
- status capsules (32; `footnote` → 25/35);
- tags (24) and status tags (22), with `caption1` → 23/31;
- chapter rows (56 → about 78);
- subtitle rows (64 → about 81);
- two-line toasts (60 → about 85).

Nothing says whether these heights grow or the text is clamped. Three more gaps:
- The reader-chrome rule contradicts itself: it keeps "fixed sizes", yet also "moves secondary controls … so the capsule never wraps", naming no controls and no threshold.
- The dock's "above the `xxxL` category" has no Flutter equivalent: the engine exposes only a `TextScaler`, and Android 14+ scales non-linearly.
- Wrapped's fixed 360 × 640 frame says nothing about text scale.

**Evidence.** §3.3: "Meniscus applies the scaler to every style and then **caps titles**"; "the dock drops labels above the `xxxL` category"; "the reader chrome keeps its own fixed sizes and moves secondary controls into the settings sheet so the capsule never wraps". §7.5: "Filter chip | Height 32". §7.14: "title capsule (`glassThin` capsule, 36 tall, `subhead` 15/20…)". §3.7 caps only `display`, `largeTitle`, `title1` and `title2`.

**Fix.** Add to §3.3:
1. **One threshold factor:** `f = MediaQuery.textScalerOf(context).scale(17) / 17`. Dock labels hide when f ≥ 1.6 (AX1, Android 1.8+). Rows stack when f ≥ 1.6. Grids drop to 2 columns when f ≥ 1.9.
2. **Minimum, not fixed, heights:** every text-bearing control uses `height = max(token, ceil(scaledLineHeight) + 2 × padV)`. padV: chips 6, segmented 4, title and status capsules 8, buttons L 14 / M 11 / S 8, toasts 11, tags 3. Capsules keep `rCapsule`.
3. **Clamp inside capsule controls:** text in chips, segmented controls, title and status capsules, tags, badges and `tabLabel` uses `TextScaler.clamp(maxScaleFactor: 1.5)`. Body text in rows and cards is not clamped.
4. **Reader chrome:** all chrome text uses `TextScaler.clamp(maxScaleFactor: 1.3)`. At f > 1.3, the bottom capsule moves the cruise button and the top-right group moves the download control into the reader settings sheet's first row ("Download", "Cruise"). Nothing else moves.
5. **Wrapped:** the frame ignores text scale (it is a poster). At f ≥ 1.35, each card's ⋯ offers "Read this card": a `large` sheet listing the eyebrow, headline, figure text and footnote at the scaled `body` size.

## MOBILE-8 · low · §7.15 Dock, §3.3

**Problem.** At large text sizes the dock moves its labels "to long-press tooltips", but long-pressing a tab already opens that tab's menu (Home: Updates…; Library: jump list; Sources: pinned; You: profile switcher). One gesture ends up with two meanings.

**Evidence.** §3.3: "labels move to long-press tooltips and semantics". §7.15: "**Long-press a tab** (450 ms): Home → a menu…".

**Fix.** At f ≥ 1.6, labels move to semantics only. The long-press menu gains a non-interactive header row with the tab's name in `headline` ("Library"), so the menu names its tab. The dock shows no tooltip.

## MOBILE-9 · medium · §7.10 Sheets, §7.15 Dock, §8.6, §8.12 Tags, §8.14.2 Go to page, §8.18, §9.3.4

**Problem.** Only the phone search field says how it meets the keyboard. Two cases are open:
- **Sheets with fields:** nothing says what a sheet does when one of its fields takes focus. Affected: a `medium` sheet (52 %) such as the Tags sheet's "New tag" field, New collection, the Recommend note or the bookmark "Add note" sheet; the go-to popovers above the reader capsule; Add series (`large`); the profile form (`large`, autofocus).
- **Chrome over the keyboard:** nothing says what the dock, search orb, accessory and toasts do while the keyboard is up over a tab root that has an in-page well. Affected: Library "Search your library", Sources "Filter sources", Collections search, catalogue search and the For you Ask box.

**Evidence.** §7.4: "rides on top of the keyboard" (the search orb only). §7.10 has no keyboard rule. A grep for `viewInsets`, `resizeToAvoidBottomInset` and "keyboard" finds only the search orb and Setup's "drag down dismisses the keyboard".

**Fix.**
- **Add to §7.10:**
  - When a field in a sheet takes focus and the keyboard's top (`MediaQuery.viewInsetsOf(context).bottom`) would cover it, the sheet moves to `large` on `sheetSnap`. The field scrolls to 30 % of the visible height (`Scrollable.ensureVisible(alignment: 0.3)`).
  - The sheet's bottom sits on the keyboard's top (bottom padding = `viewInsets.bottom`) and returns on `sheetSnap` when the keyboard closes.
  - Popovers anchored to the reader capsule rise by the keyboard height on `snappy`.
- **Add to §7.15:**
  - While `viewInsets.bottom > 0`, the dock, search orb and accessory leave on `minimize` (translating down by their height + safe-bottom), and they return on `minimize` when the keyboard closes.
  - Every scroll view uses `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag`.
  - Android keeps `windowSoftInputMode="adjustResize"`.

## MOBILE-10 · medium · §8.22 Save to Files (Android), §8.22 Chapters tab

**Problem.** Android saving writes through `MediaStore.Downloads` with `RELATIVE_PATH`, which exists only on API 29+, while §8.0.7 fixes minSdk at 24. There is no API 24–28 path (runtime `WRITE_EXTERNAL_STORAGE`, a refusal state), and the manifest declares only `INTERNET` today. Separately, the Chapters tab's "Where it lives" note has iOS copy only, although mobile S21 #16 appears on both platforms.

**Evidence.** §8.22: "Android writes through `MediaStore.Downloads` (`RELATIVE_PATH = "Download/ManhwaManiacs/{series}"`, no storage permission on API 29+)". §8.0.7: "(minSdk 24)". `mobile/android/app/src/main/AndroidManifest.xml` declares only `android.permission.INTERNET`. §8.22: "the "Where it lives" note (iOS: "…")".

**Fix.**
- **API 24–28:** declare `<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28"/>` and request it on the first "Save to Downloads". Write to `Environment.getExternalStoragePublicDirectory(DIRECTORY_DOWNLOADS)/ManhwaManiacs/{series}/`, then call `MediaScannerConnection.scanFile`.
- **Refused:** toast "Allow storage access to save to Downloads" with an "Open settings" action (the app-details screen) and the `error` haptic.
- **Android "Where it lives" copy:** "Downloaded chapters live inside ManhwaManiacs. For a copy other apps can open, use Save to Downloads."

## MOBILE-11 · medium · §9.2.4 Share cards (phones), §7.31, §8.14.3 page menu

**Problem.** The phone share flow depends on three things the contract does not state:
- "Save image … through the share sheet's own Save" crashes on iOS without `NSPhotoLibraryAddUsageDescription`, and Info.plist has only `NSPhotoLibraryUsageDescription`.
- `share_plus` on iPad requires `sharePositionOrigin` (Glass has iPad frames), yet the call is written without it.
- The "saved ('Saved to Photos')" state cannot be detected on Android, where `ShareResult` reports only success or dismissed plus the chosen component.

The same applies to the image viewer's share button and the page menu's "Save page image (phones: share sheet)".

**Evidence.** §9.2.4: "**Save image** (phones, through the share sheet's own Save)"; "saved ("Saved to Photos" / "Image downloaded")"; the call `SharePlus.instance.share(ShareParams(files: [XFile.fromData(...)]))`. `mobile/ios/Runner/Info.plist` line 43 has only `NSPhotoLibraryUsageDescription`.

**Fix.**
- Add Info.plist `NSPhotoLibraryAddUsageDescription` = "Save share cards and page images to your photo library."
- Pass `sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size` for the Share button, the image viewer's share button and the page-menu row.
- States per platform:
  - iOS: `ShareResult.raw == "com.apple.UIKit.activity.SaveToCameraRoll"` → toast "Saved to Photos"; any other success → "Shared".
  - Android: success → "Shared" only (no "Saved" state).
  - Dismissed: silent.

## MOBILE-12 · medium · §5.1 Primitives, §5.2 `nav.push`, §15.3 Native

**Problem.** The Android haptic mapping contradicts itself, and the vibrator path is missing a permission and a setting check.
- **Table versus paragraph:** the primitives table maps `rigid(i)` to `GESTURE_THRESHOLD_ACTIVATE` and `soft(i)` to `VIRTUAL_KEY`. The paragraph under it says every `rigid(i)`, `soft(i)` and `nav.push` plays a 12 ms one-shot at `round(i × 255)` instead, so those table rows are never used.
- **`nav.push`:** §5.2 gives it `ahap:rise{d}` (a 120 ms continuous event plus a transient), while §5.1 makes it a single 12 ms pulse.
- **Vibrator path:** gaimon waveforms and one-shots need `android.permission.VIBRATE` (the manifest has only `INTERNET`). Unlike `performHapticFeedback`, this path ignores the system "Touch feedback" switch.

**Evidence.** §5.1 table: "`rigid(i)` | Impact `.rigid`, intensity i | `GESTURE_THRESHOLD_ACTIVATE`". §5.1 paragraph: "every velocity- or depth-scaled event (`rigid(i)`, `soft(i)`, `throw.commit`, `motion.catch`, `nav.push`) plays a one-shot gaimon waveform instead of the constant". §5.2: "`nav.push` | … | `ahap:rise{d}`".

**Fix.**
- **Rewrite the rule:**
  - A literal argument (`rigid(0.6)`, `soft(0.5)`, `soft(0.4)` …) uses the table's constant (API 34+; API 30+ for the `CONFIRM`, `REJECT` and `GESTURE_*` rows).
  - Only runtime-scaled calls (`throw.commit`, `motion.catch`, velocity-scaled catches) use `VibrationEffect.createOneShot(12, round(i × 255))`.
  - `nav.push` on Android plays gaimon's conversion of `rise{d}.ahap.json`.
- **Permission:** declare `<uses-permission android:name="android.permission.VIBRATE"/>`.
- **System setting:** add `haptics.systemEnabled` to `mm/platform` (reading `Settings.System.HAPTIC_FEEDBACK_ENABLED`). Skip every vibrator-path pattern when it is 0.

## MOBILE-13 · medium · §7.33, §11, §9.1.2, §9.2.1, §8.18

**Problem.** The two lists of pull-to-refresh screens disagree: §7.33 includes "You (activity)", while §11 has "Circle" instead. Neither list covers three screens that have pull-to-refresh in mobile.md: Recommendations (S11 #20, which refetches recommendations and AI availability), Statistics (S12 #17) and Collection detail (S25 #13).

**Evidence.** §7.33: "**Where:** Home, Library, Sources, Source catalogue, Updates, History, Bookmarks, Collections, You (activity). Not Downloads". §11: "Pull down at the top | Home, Library, Sources, catalogue, Updates, History, Bookmarks, Collections, Circle". mobile.md S11 #20, S12 #17, S25 #13: "Pull-to-refresh".

**Fix.** Keep one list in §7.33 and have §11 reference it:
- **Pull to refresh:**
  - Home;
  - Library (every section except Downloads);
  - Sources and Source catalogue;
  - Updates;
  - For you (refetches `GET /library/world/recommendations` and `GET /library/suggest/availability`, never re-asks);
  - Statistics (refetches `GET /library/statistics?days=` for the current range);
  - Collections and collection detail;
  - Circle, You and Members.
- **No pull to refresh:** Downloads, the readers, Settings sub-pages and Wrapped.

## MOBILE-14 · medium · §7.7 Continue stack, §9.1.3, §7.34 and §11 swipe rows, §8.0.5 "Who owns a horizontal drag"

**Problem.** Two horizontal swipes sit on items inside horizontal rails, and §8.0.5 says rails own horizontal drags:
- "swiping the stack left reveals 'Previously on'" on the Continue rails of Home and Library (the Library one also sits inside the Shelf · Collections · … pager);
- the swipe-row action "Not interested" on AI cards, which live in Home rails.

A leftward swipe can scroll the rail, change the pager, or reveal the action. No arbitration is given.

**Evidence.** §7.7: "swiping the stack left reveals "Previously on" (§9.1.3)". §8.17: "a "Continue" rail of continue stacks (up to 12)". §11: "Swipe a row left or right | … AI cards". §8.0.5: "A component that owns horizontal drags wins inside its own bounds: pagers and rails…".

**Fix.** Remove horizontal swipes from items inside rails.
- **Continue stack:** reach "Previously on" through the long-press context menu (first row "Previously on"), a trailing ⋯ on the stack (44 hit), and `p`.
- **AI cards in rails:** use the lift-and-throw of §9.1.1 and ⋯ only. The "Not interested" swipe row stays only in vertical lists (For you on phones).
- Update the §11 rows "Swipe the Continue stack left" and "Swipe a row … AI cards" to match.

## MOBILE-15 · medium · §4.6 Double tap, §8.14.3, §9.4.3

**Problem.** Single taps are "never delayed", yet three surfaces put a double tap on top of an immediate single-tap action:
- **Paged manga:** the first tap on a side band turns the page, and the second zooms the new page.
- **Strip:** the first tap toggles the chrome, and the second zooms with the chrome now in the opposite state.
- **Guided view:** a side-band tap steps a panel, and a double tap "shows the whole page".

What a double tap does on these surfaces is undefined.

**Evidence.** §4.6: "Double tap | second tap within 280 ms and 24 px (timestamp detector; single taps are never delayed)". §8.14.3: "Tap (paged) | Bands 30 / 40 / 30: left previous, centre chrome, right next" and "Double tap | Zoom 1× ↔ 2× anchored at the tap point". §9.4.3: "one tap on the side bands … double-tap shows the whole page for 1.5 s".

**Fix.**
- **Paged manga and guided view:** double tap is recognised only in the centre band. Side-band taps act at once and never open a double-tap window.
- **Strip:** when a second tap lands within 280 ms and 24 px, the chrome toggle made by the first tap is reverted instantly (no fade) before the zoom runs on `camera`. A double tap never changes chrome visibility.

## MOBILE-16 · medium · §6 audio session, §9.4.2 Mixing rules, §8.16.6, §15.7

**Problem.** Audio behaviour in the background is not specified. §9.4.2 says the soundscape "pauses when the reader is left", but not what happens when the app is backgrounded or the phone locks with narration and a soundscape running (the usual sleep-timer case). `UIBackgroundModes audio` is present, so both could continue. "Shake to extend" is offered with the sleep timer, yet §15.7 runs sensors only while a screen that uses them is visible, so it cannot work with the screen locked, and the menu does not say so.

**Evidence.** §9.4.2: "it follows the sleep timer; it pauses when the reader is left and resumes on return". §8.16.6: "**Shake to extend +5 min** on phones (accelerometer through `sensors_plus` 7.1.0…)". §15.7: "Sensors run only while a screen that uses them is visible, at 30 Hz." `mobile/ios/Runner/Info.plist`: `UIBackgroundModes` = `audio`.

**Fix.** Add these rules to §6's state machine for `AppLifecycleState.paused` and screen lock:
- **Narration:** keeps playing through `audio_service` (iOS `UIBackgroundModes audio`; Android foreground service type `mediaPlayback`).
- **Soundscape while narration plays:** keeps playing, ducked by −12 dB, and follows the sleep timer's 8 s fade.
- **Soundscape otherwise:** fades out over 1.5 s and resumes on return.
- **UI sounds:** never play in the background.
- **Shake to extend:** works only while the app is in the foreground. The switch caption reads "Works while ManhwaManiacs is open."

## MOBILE-17 · medium · §8.14.5 Screen, §8.14.11 iOS, §8.25.3, §9.4.1, §8.15

**Problem.** Keep-awake is contradictory and under-scoped.
- §8.14.11 says `wakelock_plus` "keeps the screen on" on iOS, unconditionally.
- §8.14.5 and §8.25.3 make it a switch (mobile K05, default false).
- Android has no line at all.
- Nothing says whether the novel reader, cruise, guided view or narration hold the wakelock.

With the switch off, a running cruise stops when the OS locks the screen after its timeout.

**Evidence.** §8.14.11: "**iOS:** … `wakelock_plus` keeps the screen on; 120 Hz." §8.14.5: "Keep screen awake switch (phones)". mobile.md K05: "`settings_keep_screen_awake` | bool | **false**".

**Fix.** Write one rule in §8.14.5:
- **Switch on:** `WakelockPlus.enable()` while a manga or novel reader is in the foreground. The switch defaults off and is per profile after migration from K05.
- **Always on:** while cruise runs or guided view is open, whatever the switch says.
- **Release:** `disable()` on leaving the reader, on `AppLifecycleState.paused`, and 2 s after cruise stops when the switch is off.
- **Narration:** does not hold the wakelock.

Delete "keeps the screen on" from the iOS line.

## MOBILE-18 · low · §2.3 `rSheet`, §7.10 Geometry, §15.3 `GlassModalSheet`

**Problem.** `rSheet` is "device corner radius − 8 on phones", but no source for the device corner radius is given. iOS has no public API for it (nor does Flutter). Android exposes it from API 31 (`WindowInsets.getRoundedCorner`), although §2.3 lists Android as unknown.

**Evidence.** §2.3: "`rSheet` | device corner radius − 8 on phones (for example 55 − 8 = 47 on iPhone 16 Pro), 36 when the device radius is unknown (Android, web)". §15.3: "`fullTopBorderRadius` from the device corner".

**Fix.** Add `display.cornerRadius` to `mm/platform`:
- **Android API 31+:** `rootWindowInsets.getRoundedCorner(RoundedCorner.POSITION_BOTTOM_LEFT)?.radius / density`; otherwise null.
- **iOS:** `UIScreen.main.value(forKey: "_displayCornerRadius")`. This is a private key, acceptable for the SideStore build; guard it with `responds(to:)`, and return null on failure.
- **Rule:** `rSheet = r == null ? 36 : max(r − 8, 20)`, read once at launch.

## MOBILE-19 · medium · §8.14 reader, §8.22 Storage tab

**Problem.** Two inventory behaviours with visible consequences are dropped without a word.
- **Auto-queue:** the source reader auto-queues the next chapter for download when a downloads scope exists, skipping it on cellular when `settings_wifi_only_downloads` is set. Glass merges S15 and S19 into one `reader` route and never says whether this continues, which decides whether queue rows and the accessory's "Downloading" appear on their own.
- **Hidden flags:** the inventory's gap list asks for a decision on the hidden Wi-Fi-only and high-refresh flags. Glass surfaces the update schedule but says nothing about these two.

**Evidence.** mobile.md S19: "S19 also records source-local progress and auto-queues the next chapter for download"; A072: "store (skipped on cellular when wifi-only is set)"; §7 item 9: "Settings exist without UI: Wi-Fi-only downloads, high refresh rate". A grep of DESIGN.md for "auto-queue", "Wi-Fi" and "wifi" finds nothing.

**Fix.**
- **Add to §8.14.4:** "Opening a chapter that has a next one, while a downloads scope exists, queues that next chapter. The accessory and the Library badge show it like any queued item. It is skipped when 'Download on Wi-Fi only' is on and `connectivity_plus` reports cellular."
- **Add to the Downloads Storage tab:** the switch "Download on Wi-Fi only" (default off, `settings_wifi_only_downloads`), which gates only the auto-queue, as today.
- **High refresh rate:** state that it stays always on with no row (the reader's Refresh rate chips cover per-reader pinning).

## MOBILE-20 · medium · §7.29, §8.22, §8.23, §9.1.3 How it works

**Problem.** The on-device OCR engine (Android ML Kit, iOS Vision, through a method channel) can be unavailable, and mobile.md hides Dialogue Search and the OCR buttons when it is. Glass shows "Extract text" "on phones" and gates Dialogue search only on the server `ocr` capability and manga mode, so an implementer must guess what a phone without the engine shows.

**Evidence.** mobile.md S27: "Only visible when the on-device OCR engine is available (Android ML Kit / iOS Vision via a method channel)"; S21 #24: "manga, complete, OCR enabled only". DESIGN §7.29: "Extract text for dialogue search on phones". §8.0.8: "Server capabilities … `ocr`".

**Fix.** Add the device capability `ocrEngineAvailable`: the existing OCR channel's availability probe, read once per launch. When it is false:
- hide "Extract text" in the saved-chapter menu (§7.29), in the Downloads chapter rows, in the dialogue overlay and in the recap's "no source text" lens;
- keep Dialogue search (chapters extracted on another device still search), with its hint row replaced by "This phone can't extract text. Chapters extracted on another device still show up here."

## MOBILE-21 · low · §12.6

**Problem.** "download notifications through `audio_service`" names a feature that no section specifies (downloads run only in the foreground, §8.22) and a package that posts only media notifications.

**Evidence.** §12.6: "**Android notification small icon** (narration lock-screen and download notifications through `audio_service` 0.18.19)".

**Fix.** Change it to "the narration lock-screen and media notification through `audio_service` 0.18.19". If download notifications are wanted, specify them separately: the channel, the copy, and `POST_NOTIFICATIONS` on API 33+.

## MOBILE-22 · low · §2.4.2 rule 5, §8.7 step 4, §9.2.2, §8.8 hero tilt

**Problem.** The tilt effects name the wrong sensor or leave out drift handling. Gravity for the genre field and the flame's lean comes from the accelerometer, not the gyroscope. The light angle integrates the gyroscope's rotation rate "clamped to ±25°", which drifts without a leak term and eventually sticks at a clamp.

**Evidence.** §2.4.2: "On phones it follows the gyroscope (`sensors_plus` 7.1.0, rotation rate integrated and clamped to ±25°)". §8.7: "the gyroscope tilting gravity up to 400 px/s²".

**Fix.**
- **Gravity (genre field, flame lean, hero tilt):** `accelerometerEventStream(samplingPeriod: Duration(milliseconds: 33))`, low-passed with α = 0.15. The hero tilt (±6°) comes from pitch and roll relative to the pose at screen entry.
- **Light angle:** `135° + 25° × clamp(roll / 30°, −1, 1)` from the same vector, or gyroscope integration with a leak toward 0 at τ = 1.5 s.

## MOBILE-23 · low · §4.11, §8.25.1, §15.3

**Problem.** Two platform accessibility signals are wrong or loosely named.
- **Contrast:** Android API 34+ exposes a public contrast level (`UiModeManager.getContrast()`, −1 to 1, with a change listener), contrary to "Android has no public high-contrast signal".
- **Reduce Transparency:** the channel method is `reduceTransparency` in §4.11 but `a11y.reduceTransparency` in §15.3, and neither says the value is observed for changes while the app runs.

**Evidence.** §4.11: "Increase Contrast | … (iOS only: Android has no public high-contrast signal for apps)"; "iOS `UIAccessibility.isReduceTransparencyEnabled` read through the `mm/platform` channel method `reduceTransparency`". §15.3: "`a11y.reduceTransparency` (iOS)".

**Fix.**
- **Reduce Transparency:** one name, `a11y.reduceTransparency`, plus an event stream fed by `UIAccessibility.reduceTransparencyStatusDidChangeNotification`.
- **Contrast:** add `a11y.contrastLevel` (Android API 34+ `UiModeManager.getContrast()` with `addContrastChangeListener`). A value ≥ 0.5 turns Increase Contrast on, OR-ed with the in-app switch.

## MOBILE-24 · low · §9.1.3, §8.16.1, §8.16.2, §9.4.2, §8.15.3, §7.2

**Problem.** Some controls are referenced but never placed, and one group exceeds its own limit:
- "the reader's ⋯ → Previously on": neither reader's chrome has a ⋯.
- "the player's ⋯" (Save audio, the soundscape entry): absent from the full player's layout.
- "Save audio … as a trailing icon on the mini player": absent from the mini player's content.
- The novel top-right group (bookmark, listen, voices, Aa) plus the soundscape `waveform` makes 5 icons, above the glass group's maximum of 4.

**Evidence.** §9.1.3: "the reader's ⋯ → "Previously on"". §8.16.2: "**Save audio** (phones, in the player's ⋯ and as a trailing icon on the mini player)". §8.16.1's content lists the orb, the title, play/pause and the progress line only. §8.15.3: "a `waveform` glyph joins the top-right group while a soundscape plays". §7.2: "Glass group | … holding 2 to 4 icons".

**Fix.**
- **Full player:** a trailing header ⋯ (`glassThin` 32, 44 hit) holding Save audio, Soundscape and Sleep timer settings.
- **Mini player:** drop the save icon (the ⋯ holds it).
- **Readers:** replace "the reader's ⋯" with "reader settings sheet → Ambient → a 'Previously on' row, shown after 3 or more days away".
- **Novel reader:** show the soundscape as a 6 px `waveform` badge on the Aa button instead of a fifth icon.

## MOBILE-25 · low · §8.29 App update (Android APK), §8.24, §8.25.14

**Problem.** Three pieces of the APK update are missing:
- the install-steps alert has no copy (mobile S22 #15 has three numbered steps);
- the mechanism behind "Download update" is not stated (today `url_launcher` to the external browser, A102);
- G9's re-check on every resume is not carried over.

**Evidence.** §8.29: "then the install-steps alert with three numbered droplets". mobile.md G9: "Re-checked on every app resume." A102: "url_launcher; `GET /app/version`".

**Fix.**
- **Step copy:**
  1. "Open the downloaded file from your notifications or the Downloads app."
  2. "Allow installs from this source if Android asks."
  3. "Tap Install. Your library and downloads stay."
- **Download update:** opens the APK URL in the external browser (`LaunchMode.externalApplication`).
- **Re-check:** `GET /app/version` runs on `AppLifecycleState.resumed`, at most once every 15 minutes.

## MOBILE-26 · low · §8.14.3 Left-edge vertical drag, §11

**Problem.** The brightness band's geometry is ambiguous. A "12 % band" that "starts at x ≥ 24 px on iOS" can be read as [24, 0.12 W] (about 23 px wide on a 390 px phone) or as [24, 24 + 0.12 W].

**Evidence.** §8.14.3: "Left-edge vertical drag (12 % band, portrait phones) | … The band starts at x ≥ 24 px on iOS".

**Fix.**
- **iOS band:** x ∈ [24, 24 + 0.12 W] (24–71 px on a 390 px phone).
- **Android band:** x ∈ [0, 0.12 W], with its middle 200 dp excluded from system back.
- **Activation:** a vertical drag (abs(dy) > 2 × abs(dx) after 10 px).

## MOBILE-27 · low · §8.4 Register

**Problem.** Mobile S04 #14's client-side checks are not carried over. Only "Passwords don't match." is given. Empty fields, the 8-character minimum, a missing invite code and an invalid optional email have neither copy nor trigger, and nothing says whether "Create account" stays disabled until the form is valid (Login says it does).

**Evidence.** mobile.md S04 #14: "Client-side messages: "Choose a username and password.", "Password must be at least 8 characters.", "Passwords don't match.", "Enter the invite code for this server.", "Enter a valid email address, or leave it blank."". §8.4 Fields: "Confirm password (live "Passwords don't match." with `aria-invalid`)" only.

**Fix.** "Create account" stays disabled until the username, a password of at least 8 characters, a matching confirmation and (when required) the invite code are filled. The checks:
- **On blur:** password under 8 characters → "At least 8 characters"; an email that is present and fails `^[^@\s]+@[^@\s]+\.[^@\s]+$` → "Enter a valid email address, or leave it blank."
- **On submit:** empty invite → "Enter the invite code for this server."

Each error uses `errorRing`, the 6 px shake and the `error` haptic.
