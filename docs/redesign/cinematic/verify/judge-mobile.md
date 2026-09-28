# Cinematic DESIGN.md: verdicts on the mobile coverage audit

Input: `cinematic/verify/find-mobile.md` (28 findings). Each finding was checked against `cinematic/DESIGN.md` (4,101 lines, grepped for every term the finding says is missing), `inventory/00-decisions.md`, `stack-decision.md`, `inventory/mobile.md`, the Flutter 3.44.6 SDK at `/srv/manhwamaniacs/dev/flutter`, `mobile/ios/Runner/Info.plist`, `mobile/lib/**/novel_audio_session.dart`, and the published sources of `swipeable_page_route` 0.4.8, `flutter_soloud` 5.1.4 and `flutter_dynamic_icon_plus` 1.4.1.

**Result: 28 confirmed, 0 refuted.** No finding was already specified elsewhere or lacked evidence. Some parts of the fixes were wrong, vague or bigger than needed, and those parts are rewritten here:

- **MOBILE-1:** the durations belong on the `PageTransitionsBuilder`. `MaterialPageRoute` reads them from there, so no route subclass is needed.
- **MOBILE-1 and MOBILE-2:** `swipeable_page_route` 0.4.8 already hands its `transitionBuilder` an `isSwipeGesture` flag and has a mutable `canSwipe`. The readers therefore need no hand-rolled drag recognizer.
- **MOBILE-3:** Flutter's gesture arena already gives a drag that starts on a row to the row, so `NeverScrollableScrollPhysics` plus a custom recognizer are not needed.
- **MOBILE-4:** "it stops when other audio starts" cannot be implemented under the proposed focus-less ambient state, so that sentence is replaced.
- **MOBILE-6:** the growing bar and the 3 + 2 wrap are dropped as unnecessary.
- **MOBILE-7:** the enumeration is replaced by one rule per face, which also stops count badges from changing face.
- **MOBILE-16:** the fix now uses the chosen package's own deferred Android switch.
- **MOBILE-17:** on iOS, `PopScope(canPop: false)` disables the edge swipe rather than redirecting it.
- **MOBILE-22 and MOBILE-23:** each "either / or" is replaced by one decision.
- **MOBILE-25:** double tap now works from the series' resting zoom.

Severity follows the audit unless noted.

---

## Refuted

None.

These sub-claims were already covered and are left out of the fixes below:
- MOBILE-17 item 1: §7.9 already says "Android back and iOS swipe-down both close" sheets.
- MOBILE-18 skip 3: a series hidden by the 18+ gate cannot be open in the reader (§8.0.10), so that skip is redundant.

---

## Confirmed

### MOBILE-1 · high · Page and Match cut cannot come from the prescribed page builders

**Why it stands.**
- The Flutter source does exactly what the audit says. In `predictive_back_page_transitions_builder.dart` (lines 159–175), `PredictiveBackFullscreenPageTransitionsBuilder` returns `ZoomPageTransitionsBuilder` whenever `route.popGestureInProgress` is false, which covers every button press and programmatic push or pop.
- `MaterialRouteTransitionMixin.transitionDuration` (`material/page.dart` line 91) comes from the theme's builder, which gives Zoom's 300 ms. A `Hero` flies for its route's duration, so the 480 ms Match cut is impossible.
- On iOS, `SwipeablePage` defaults to a `CupertinoPageTransition` for every push, not the Page move of §4.5.

**Final fix (§8.0.5, §15.3 `router.dart` row).**
- **Programmatic push and pop, both OSes.**
  - **Page:** the incoming page goes x +24 → 0 px and opacity 0 → 1 over 320 ms `ease.settle`. The outgoing page (driven by `secondaryAnimation`) goes x 0 → −24 px and opacity 1 → 0 over 224 ms `ease.lift`. Pop reverses both over 224 ms.
  - **Match cut routes:** `transitionDuration` 480 ms and `reverseTransitionDuration` 336 ms. Covers are `Hero`s with `transitionOnUserGestures: defaultTargetPlatform == TargetPlatform.iOS`. iOS reverses the match cut with the finger (§8.11, §8.17); Android's predictive back fades through instead.
- **iOS.**
  - Every pushed route is a `SwipeablePage` with:
    - `canOnlySwipeFromEdge: true` and `backGestureDetectionWidth: 20`;
    - `transitionDuration` 320 ms (480 ms for match cuts) and `reverseTransitionDuration` 224 ms (336 ms for match cuts);
    - a `transitionBuilder`.
  - The builder uses 0.4.8's `SwipeableTransitionBuilder`, `(context, animation, secondaryAnimation, isSwipeGesture, child)`, where `isSwipeGesture` is `route.popGestureInProgress`.
    - When `isSwipeGesture` is false, it paints Page.
    - When it is true, it paints the finger-tracked slide of §8.0.5 on a linear curve. The top page's x follows the animation. The page beneath goes from −30 % to 0 under a `#000` dim that falls from 0.6 to 0.
    - The page beneath cannot use its own `isSwipeGesture`, which is false. It reads `Navigator.of(context).userGestureInProgress` instead.
  - Release uses `spring.release`.
- **Android.**
  - Add `CinePageTransitionsBuilder` in `mobile/lib/skins/cinematic/transitions.dart` and register it with `PageTransitionsTheme(builders: {TargetPlatform.android: CinePageTransitionsBuilder()})`.
    - It overrides `transitionDuration` (320 ms) and `reverseTransitionDuration` (224 ms), which `MaterialPageRoute` picks up directly.
  - Its widget is a `WidgetsBindingObserver` that copies Flutter's private `_PredictiveBackGestureDetector`:
    - `handleStartBackGesture` returns false for `isButtonEvent` or when `!(route.isCurrent && route.popGestureEnabled)`;
    - otherwise it calls `route.handleStartBackGesture(progress: 1 − event.progress)`;
    - `handleUpdateBackGestureProgress`, `handleCommitBackGesture` and `handleCancelBackGesture` forward the same way.
  - When `route.popGestureInProgress` is false, it paints Page.
  - When it is true, it paints the full-screen fade-through:
    - the outgoing page's scale goes 1.00 → 0.95 and its opacity 1 → 0 over progress 0–0.6;
    - the incoming page's opacity goes 0 → 1 over progress 0.4–1.0;
    - a commit finishes in 240 ms `ease.settle`, and a cancel returns in 160 ms `ease.settle`.
  - Match-cut routes use `CineMatchCutPage`, a `Page` whose `PageRoute` uses 480 / 336 ms with the same builder.
  - `ZoomPageTransitionsBuilder` never ships.
- **§8.0.5 Android Back cell:** replace "via `PredictiveBackFullscreenPageTransitionsBuilder`" with "via `CinePageTransitionsBuilder` (§15.3)".

### MOBILE-2 · high · Back from either reader is unimplementable as written and partly undefined

**Why it stands.**
- §8.14.2 and §15.3 make the readers custom `PageRouteBuilder`s. §11 still sources their iOS edge swipe from `swipeable_page_route`.
- A single `Interval`-driven `transitionsBuilder` replays the blades in reverse on pop. That contradicts "Exit: Dip, never a wipe", and no reverse duration is given.
- Inventory A064 requires "pop, or go to the series page when nothing is beneath". The contract gives that target only for the novel reader on Android (§8.15.8).

**Final fix (§8.14.2, §8.14.10, §8.15.8, §11, §15.3).**
- **Route.** Both readers use one `SwipeablePage` (the same package, no extra code).
  - The entry kind travels in `GoRouterState.extra` as `{entry: 'wipe' | 'dip'}`.
  - `transitionDuration` is 616 ms on phones and 872 ms from 600 px for `wipe`, and 440 ms for `dip`. `reverseTransitionDuration` is 440 ms.
  - The `transitionBuilder` paints:
    - the blades while `animation.status == AnimationStatus.forward` and the entry is `wipe`;
    - the Dip in (160 ms to `#000` `ease.lift`, 40 ms hold, 240 ms in `ease.settle`) for a `dip` entry;
    - the Dip while the status is `reverse` and `!isSwipeGesture`;
    - the §8.0.5 finger-tracked slide while `isSwipeGesture` is true.
- **iOS edge swipe (20 pt, `canOnlySwipeFromEdge: true`).** The reader keeps `context.getSwipeablePageRoute()!.canSwipe` (a mutable field in 0.4.8) true only when all of these hold:
  - the device runs iOS;
  - the layout is strip or novel scroll;
  - zoom ≤ 1.0;
  - guided view is off.

  A committed swipe pops without a Dip. When nothing lies beneath, the route is first and the swipe is off, and the back button is the way out.
- **Android.** `canSwipe` is false, and the reader has no predictive preview on purpose. A committed back gesture or the back button plays the Dip.
- **Back target (both readers, both OSes, the button and the system back).**
  - When `context.canPop()`, it pops.
  - Otherwise it calls `go('/sources/:sourceId/series/:seriesKey')` (the manga Feature or the novel Book), and the series page enters by Dip. On Android this is wired through `PopScope(canPop: context.canPop(), onPopInvokedWithResult: …)`.

### MOBILE-3 · high · Competing horizontal gestures have no precedence

**Why it stands.**
- The only edge rule in the contract is §8.0.5's 24 px exclusion, which is written for mobile web.
- Pagers (§7.12, §11) contain swipe rows (§8.10, §8.13, §8.17, §8.23), and Updates and History nest their own contents tabs inside the Library hub pager.
- On the web a scroll-snap pager takes a horizontal pan before the row's pointer handler can, so the two clients would behave differently.

**Final fix (a precedence paragraph in §11; the §8.0.5 Edge swipes row applies to all phone clients).**
- **Rows win.** A horizontal drag that starts on a row with swipe actions belongs to the row.
  - In Flutter this is the gesture arena's default: the innermost horizontal recognizer (the row's `Dismissible`) accepts first. Pagers keep their normal physics and only receive drags that start outside rows: the masthead, the tab row, the toolbar or gaps.
  - On the web, swipe rows set `touch-action: pan-y`, so the scroll-snap pager never takes a drag that starts on a row.
- **Nested contents tabs** inside a hub panel (Updates `NEW · FOLLOWING`, History `BY SERIES · BY CHAPTER`) switch by tap only. In Flutter their `TabBarView` uses `NeverScrollableScrollPhysics()`; on the web the panel swaps with no scroll-snap. The hub pager owns every horizontal drag there.
- **Strip chapter swipe** is live only when all of these hold:
  - zoom ≤ 1.0;
  - the touch starts at least max(24 px, `MediaQuery.systemGestureInsetsOf(context).left` / `.right`) from both edges, which also clears iOS's 20 pt back strip;
  - the drag is within 30° of horizontal.

  Above 1.0× a horizontal drag pans the page.

### MOBILE-4 · high · The iOS audio-session rules contradict each other; Android focus is unspecified

**Why it stands.**
- The shipping app configures `AudioSessionConfiguration.speech()` once, app-wide, at startup (`novel_audio_session.dart`, `configureNovelAudioSession()`). That is the playback category.
- `flutter_soloud` 5.1.4 leaves the session to the app: its miniaudio context sets `coreaudio.sessionCategory = ma_ios_session_category_none` and `noAudioSessionActivate = true`.
- So under today's configuration, UI cues, voice samples and the soundscape all play in `.playback`. The silent switch mutes none of them, which contradicts §6 and §9.4.2.
- When the soundscape's `just_audio` player activates the session (its default), a non-mixable session stops the user's music, which contradicts §9.4.2 "never ducks the user's music". On Android it requests `AUDIOFOCUS_GAIN`, with the same result.
- Voice samples under `.ambient` would be muted by the ring/silent switch.

**Final fix (one session policy in §6, referenced from §8.16.5, §8.16.10 and §9.4.2).**

| State | When | iOS session | Android focus | Behaviour |
|---|---|---|---|---|
| **A** | At launch; idle; UI cues only; soundscape only | `AVAudioSessionCategoryAmbient` (mixes with others; the silent switch mutes; stops in the background) | none: the soundscape `just_audio` player uses `handleAudioSessionActivation: false` and requests no focus | Soundscape and cues play |
| **B** | Narration playing, or paused inside the reader | `AudioSessionConfiguration.speech()` (`.playback`, mode `.spokenAudio`) | `AUDIOFOCUS_GAIN`, usage media, content type speech | The soundscape continues at 30 % gain, or pauses per the switch, and is no longer muted by the silent switch; UI cues are suppressed |
| **Voice sample** | While a `Hear` sample plays | `.playback` with `.duckOthers` | `AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK` (via `AudioSession.setActive(true)` with that gain type) | The ringer switch never silences a sample |

- Replace the startup call to `configureNovelAudioSession()` with State A. State B is configured through `AudioSession.instance.configure` when narration starts, and State A is restored when it stops. After a sample ends, the previous state returns.
- §9.4.2: replace "and it stops when other audio starts" with "it mixes with other audio at its own volume, never ducking or stopping it". A focus-less ambient player receives no interruption to stop on.

### MOBILE-5 · high · The five-branch shell has no route-to-branch map

**Why it stands.** §8.0.2, §7.13, §7.14 and §8.0.5 talk about branches and tab roots but never assign routes to them. Index (§8.28) links to Library hub tabs with "Page to each destination", yet `/library/history` can live in only one go_router branch. Inventory §7 gap 11 flags this.

**Final fix (a branch table in §8.0.3).**
- **Branch 0, Tonight:** `/`.
- **Branch 1, Library:** a nested `StatefulShellRoute.indexedStack` whose five hub tabs are the branch roots `/library`, `/updates`, `/library/collections`, `/library/history` and `/library/bookmarks`.
  - Switching hub tabs replaces the route, and none of the five shows a back arrow.
  - Android back from a tab other than SHELF goes to SHELF, then to Tonight.
  - `/library/collections/:id` is pushed inside branch 1 and has a back arrow.
- **Branch 2, Discover:** `/search`, `/sources`, `/sources/:sourceId`, `/ocr`, `/library/recommendations`.
- **Branch 3, Downloads:** `/downloads`.
- **Branch 4, Index:** `/more`, `/settings…`, `/library/statistics`, `/circle`, `/circle/:profileId`, `/profiles/manage`.
- **Root navigator** (thumb index hidden, as §7.14 requires): `feature`, `featureByFollow`, `reader`, `readAll`, `novel`, `recap`, `annual`, `onboarding`, the other `profiles*` routes, and the Lightbox.
- **Navigation rules.**
  - Inside a branch, drill-ins use `push`, so they get a back arrow.
  - Cross-branch links use `go` into the owning branch, and the notch moves. They never push a duplicate. For example, Index → Updates is `go('/updates')`.
  - Declare every static `/library/...` path before `/library/:followedId`. go_router matches in declaration order, and `featureByFollow` would otherwise capture `/library/history`.

### MOBILE-6 · medium · Reflow misses real overflows at the stated caps

**Why it stands.**
- The thumb-index labels overflow. At 1.3 and above, `type.nav` switches to `wdth` 100 and 13–15 px (§3.3), so "DOWNLOADS" needs about 90–105 px, but a 375 pt phone gives each of the five cells 75 px.
- The feature page's labelled icon row (§8.17) overflows the same way.
- Split buttons stacked at 1.5 need about 54 px, and the folio bar's second line at 1.5 needs more than its 64 px. §7 never says fixed heights may grow.
- "≥ 1.3" has no definition under Android 14's non-linear `TextScaler`.

**Final fix (§3.3, §7.1, §7.13, §7.14, §8.14.3, §8.17).**
- **Scale factor:** `MediaQuery.textScalerOf(context).scale(16) / 16`.
- **Thumb-index labels and the feature icon-row labels:**
  - keep `wdth` 62 at every scale, as an exception to the 1.3 switch to `wdth` 100;
  - cap the scale at 1.3 (13/16);
  - tracking +0.06em at 1.3 and above;
  - `maxLines: 1` inside `FittedBox(fit: BoxFit.scaleDown)` as a guard, never below 10 px.

  "FAVOURITE" at 13 px `wdth` 62 is about 56 px, which fits the roughly 62 px cell.
- **Thumb index at 1.5:** with labels capped at 1.3, the 24 px icons stay. Delete "and drops the icons" from §3.3. The bar stays 56 + bottom inset: icon 24 + gap 4 + label line 16 = 44.
- **§7 heights are minimums.** A control's height is max(token, the scaled line height of its text + 2 × 12 px).
  - A split button stacked at 1.5 is label line + folio line + 2 × 8 px, min 64.
  - The running head is min 44 (48 on Android, MOBILE-21) and grows to title line + 2 × 12.
  - The folio bar is min 64 and grows by the height of its second caption line.

### MOBILE-7 · medium · Literal styles outside the role table have no text-scale cap

**Why it stands.** §3.3 caps only named roles. Many phone styles are given as a literal face and size, with no role and so no cap:
- slug-line labels (§7.5);
- superscript counts and thumb-index badges in Plex Mono 10 (§7.5, §7.14);
- poster title cards (§7.7);
- book-list titles and blurbs (§8.9.1);
- novel contents rows (§7.16);
- voice names (§8.16.5);
- the Listen transcript (§8.16.3);
- dialogue subtitles and transcripts (§8.24);
- the onboarding paragraph (§8.7).

**Final fix (one rule in §3.3; the audit's per-item list is not needed).**
- Any literal size in §7–§9 takes the cap of its face's role group:
  - Bodoni Moda literals: 1.30, like `section`;
  - Newsreader and other reading-face literals: 2.0, like `body`;
  - Archivo uppercase literals: 1.5, like the caps group (`wdth` stays as written, and slug labels switch to `wdth` 100 at 1.3 and above like the caps roles);
  - Archivo sentence-case literals: 2.0;
  - Plex Mono literals: 2.0, like `folio`.
- `CineType.literal(face, size, line)` applies the rule, so no new roles are needed.
- **Exceptions.**
  - Superscript counts and count badges cap at 1.3. The badge box grows from min 16 to the scaled line height.
  - Subtitles laid over dialogue stills (§8.24) cap at 1.3 and never exceed two lines.

### MOBILE-8 · medium · Whether the novel body follows the system text scale is contradictory

**Why it stands.** §3.3 says the novel body reaches 40 px "at ≥ 2.0 … independent of this cap". §8.15.5 gives Size as 14–40 px with an 18 px phone default, and §14.7 repeats the 40 px range. Under a Flutter `Text`, which applies the ambient `TextScaler` by default, it cannot be told whether 18 px renders as 18, 36 or 40 at system 2.0.

**Final fix (§3.3, §8.15.5, §14.7).**
- The novel body renders with `TextScaler.noScaling`. Its Size is absolute, 14–40 px.
- A book with no stored size opens at `clamp(round(MediaQuery.textScalerOf(context).scale(18)), 14, 40)`, so a user at system 2.0 starts at 36 px. The value is stored per book once changed.
- The reader chrome follows the normal role caps.
- Replace the §3.3 "≥ 2.0" bullet with this rule.

### MOBILE-9 · medium · Horizontal safe areas are not handled

**Why it stands.**
- `mobile/ios/Runner/Info.plist` allows `LandscapeLeft` and `LandscapeRight` on iPhone.
- The web sets `viewportFit: "cover"` (`frontend/src/app/layout.tsx:58`).
- A grep for viewPadding, safe area, cutout and `safe-area-inset-left` finds only vertical insets. §8.0.9 sends landscape phones to tablet rows (32 px margins), and a landscape sensor housing inset is 47–62 pt.

**Final fix (§2.2.2, §8.0.9).**
- **Horizontal margin.**
  - App: max(grid margin, `MediaQuery.viewPaddingOf(context).left` or `.right` + 8 px).
  - Web: `max(var(--mm-margin), calc(env(safe-area-inset-left) + 8px))`, and the same on the right.
- The running head, thumb index, toasts and select-mode bar inset their content by the same amounts. Their `#000` grounds still bleed edge to edge.
- The readers centre the strip or column inside the safe rectangle, and no chrome control sits inside an inset.
- Full-bleed art (the Tonight cover and the feature hero) may bleed under the inset.

### MOBILE-10 · medium · The landscape phone manga reader loses its running head

**Why it stands.** §8.14.1 says "running head hidden, folio bar only on tap". The running head carries back, download, bookmark, guided view and Reading setup (§8.14.3), so Reading setup and the download mark become unreachable in landscape.

**Final fix (§8.14.1 row).** Change the row to: "Strip column 70 % of the width, centred; the running head and folio bar are both hidden at rest and shown together on a centre tap, under the normal auto-hide rules." The running head keeps its portrait height (44 on iOS, 48 on Android, plus the top inset) and its back button plus four trailing buttons. The audit's 40 px variant is dropped: it would be one more size, with hit targets taller than the bar.

### MOBILE-11 · medium · Reader system UI is underspecified

**Why it stands.**
- §8.0.5 gives iOS only "home indicator auto-hidden in readers" and Android `immersiveSticky`.
- Nothing says whether the iOS status bar is hidden, or whether the system bars appear together with the chrome.
- Inventory G11 records that today both readers hide the status bar on both OSes.

**Final fix (§8.0.5 System bars row, §8.14.3, §8.15.3).**
- **On reader enter:**
  - Android: `SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky)`;
  - iOS: `SystemUiMode.manual` with `overlays: []`, which hides the status bar and auto-hides the home indicator.
- **When the chrome shows,** on both OSes: `SystemUiMode.manual` with `overlays: [SystemUiOverlay.top]`, in step with the 240 ms chrome-in. The bars hide again with the 160 ms chrome-out.
- **Layout.** The strip and the novel column ignore system insets and stay edge to edge, so toggling the bars never reflows pages. The running head's height is 44 (48 on Android) + `MediaQuery.viewPaddingOf(context).top`.
- **On exit:** restore `SystemUiMode.edgeToEdge` with `SystemUiOverlayStyle.light`, `statusBarColor` and `systemNavigationBarColor` set to `Color(0x00000000)`, and `systemNavigationBarContrastEnforced: false`.

### MOBILE-12 · medium · The foreground-only download note and pause reason are iOS-only

**Why it stands.**
- §8.19 says "on iOS the foreground note", and §8.23 has "background (iOS)" and "the iOS foreground note".
- §8.23's own K-row says "downloads run only in the foreground (G10)", and inventory G10 applies that to both platforms.
- Inventory S10 #13 and S21 #14 show the note with no platform restriction.

**Final fix (§8.19, §8.23).**
- On both iOS and Android, the note "Downloads run while the app is open; leaving pauses them and coming back picks up where they stopped." appears in the Activity block and the series download card.
- The pause reason "Paused while the app is in the background." also shows on both.
- Replace "(iOS)" and "on iOS" with "(app)".

### MOBILE-13 · medium · Follow-along on the novel page is unspecified

**Why it stands.**
- Highlight, hold line and decouple rules exist only for the full player's transcript (§8.16.3).
- §8.15.9 refers to "follow-along" being withheld, and §13 item 8 says "the page holds the line at the reading height", but neither gives any values.
- Inventory S26 #8 has the behaviour today.

**Final fix (a "Following along on the page" paragraph in §8.16.2).** While narration plays with the mini player:
- the active sentence gets a `spot.wash` band (`rgba(244,208,63,0.16)`) that sweeps in over 200 ms `set`, as in §8.16.3, on every stock;
- the spoken word gets a 2 px underline in stock ink that steps without animation;
- speaker tints keep their underline but drop their 12 % background under the band;
- the spoken paragraph is held at the reading line (38 %, §8.15.4) by a 400 ms `ease.settle` scroll that runs only when it leaves the 20–70 % band;
- a manual scroll decouples it and shows a `quiet` `Back to the voice ↓` in stock colours above the mini player, and it re-follows after 4000 ms idle;
- under reduced motion the band appears at once and the scrolls jump.

### MOBILE-14 · medium · Save image is undefined on Android and missing its iOS plist key

**Why it stands.**
- The share sheet's Save Image (`UIActivityTypeSaveToCameraRoll`) requires `NSPhotoLibraryAddUsageDescription`. `Info.plist` has only `NSAppleMusicUsageDescription` and `NSPhotoLibraryUsageDescription`, and without the add key iOS terminates the app when Save Image is chosen.
- Android's share chooser has no guaranteed save target.

**Final fix (§9.2.5).**
- **iOS.** In the native-plugin commit, add `NSPhotoLibraryAddUsageDescription` = "ManhwaManiacs saves share cards to Photos only when you choose Save image. It never reads your library." `Save image` opens the share sheet.
- **Android API 29 and above.** `Save image` inserts the PNG into `MediaStore.Images.Media` with `RELATIVE_PATH` `Pictures/ManhwaManiacs`, named `manhwamaniacs-{template}-{format}.png`, through a small `mm/media` method channel in `MainActivity.kt`. It needs no permission. Toast: "Card saved to Pictures › ManhwaManiacs."
- **Android API 24–28** (minSdk is 24). The button is hidden, and `Share` is the only action.

### MOBILE-15 · medium · Pull to reprint is missing from four screens

**Why it stands.** The §11 row lists the screens that have pull to reprint, and §8.11, §8.21 and §9.1.3 have none. Inventory S16 #16, S24 #12, S25 #13 and S11 #20 all have pull-to-refresh today. Phones have no `r` key.

**Final fix (§11 Pull row and each screen's Gestures line).**
- Add Sources, Collections, Collection detail and Picks.
- Sources refetch `GET /sources` and `GET /sources/pins` (A073).
- Collections and the collection detail refetch their payloads.
- Picks refetch `GET /library/world/recommendations` and `GET /library/suggest/availability` (A047) and never re-ask the AI.

### MOBILE-16 · medium · The Android icon swap "at the restart" is wrong, and the API name is wrong

**Why it stands.**
- `stack-decision.md` §2.5 step 4 and line 97 define the restart as an in-process `UniqueKey` swap, so "the task is being replaced anyway" is false.
- The stack's API is `AppRestart.of(context).restart()` (line 155), but §8.30.3 and §8.32 call `AppRestart.restart()`.
- `flutter_dynamic_icon_plus` 1.4.1, the chosen package, applies the Android `activity-alias` change from its `FlutterDynamicIconPlusService` (`android:stopWithTask="false"`) when the task is removed. Only blacklisted devices get its "force restart" path.

**Final fix (§12.3, §8.30.3, §8.32).**
- **Android.** Stop the press calls the package's `setAlternateIconName` before the restart with empty `blacklistBrands`, `blacklistManufactures` and `blacklistModels`, so the force-restart path is never taken. The package defers the alias swap to task removal, and no custom `setComponentEnabledSetting` code is added.
- **§12.3.** Replace "applied at the restart (the task is being replaced anyway)" with "applied by the package when the app's task is next closed".
- **Android confirm line:** "The app icon changes after you next close the app from Recents. Shortcuts on your home screen may need adding again."
- **API name.** Use `AppRestart.of(context).restart()` in §8.30.3 and §8.32.

### MOBILE-17 · medium · Back inside modal states and takeovers is undefined

**Why it stands.** None of these states has an Android back or iOS edge-swipe rule:
- select mode (§8.9, §7.29);
- collection Reorder;
- the Listen full player (only swipe-down and `Esc`, §8.16.12);
- the settings search;
- onboarding steps (§8.7 says only "committed on Next, not on swipe alone");
- the picker opened by Switch profile.

Sheets are already covered by §7.9.

**Final fix (a back order in §8.0.5).**
- **Android back** takes the first of these that applies:
  1. exit select or reorder mode, like `Done` (the selection is discarded);
  2. collapse the Listen full player to the mini player;
  3. close the settings search;
  4. in onboarding, go from step n to step n − 1 with the pager's 320 ms `ease.settle` (the pager swipes backward only, and forward needs `Next`); from the first shown step, back returns to the picker;
  5. on a picker opened by Switch profile, pop to the previous screen with the previous profile still active.
- **Switch profile and the picker.** Switch profile opens the picker as a pushed takeover without clearing the active profile. The active profile is replaced only when another is picked. On the sign-in picker, back is left to the system.
- **iOS.** States 1–4 wrap their route in `PopScope(canPop: false)`, which disables the edge swipe (a swipe cannot be redirected). Their visible `Done`, collapse, close and `Back` controls are the way out. The Switch-profile picker keeps its edge swipe.

### MOBILE-18 · medium · Auto-queue of the next chapter is referenced but never defined

**Why it stands.** The only mention is §8.23's "K20: gates the auto-queue of the next chapter". Inventory A072 (S19 only) queues the next chapter today, and §8.14 unifies S15 and S19 without saying what happens to it.

**Final fix (§8.14, as an engine duty in §15.4).**
- **Trigger.** When a downloads scope exists and `client_downloads` is on, opening a manga chapter whose next chapter is not saved queues that one chapter, once per open.
- **Skips.** It is skipped when K20 is on and the device is not on Wi-Fi, or when the storage cap or the 1.5 GB floor has been reached.
- **Feedback.** There is no toast and no haptic. The Downloads badge counts it, and the Coming up card's folio shows `SAVED` once it finishes.
- **Setting.** Settings → Downloads & storage gets a per-profile switch "Save the next chapter while I read", default on.

### MOBILE-19 · medium · Phones cannot filter the library by tag

**Why it stands.** On desktop, §8.9 has `TAGS ▾`, but the phone `Filters` sheet lists only favourites, new only, sort, density and reading status.

**Final fix (§8.9 Phone layout).**
- The Filters sheet gets a `TAGS` section: a multi-select checklist of the profile's tags, hidden when there are none, with a last row `Manage tags…` that opens the tag sheet.
- Active tags show as removable tokens after the status slug line.
- The `Filters` button shows the number of active filters as a superscript folio.

### MOBILE-20 · low · The migration copies device keys into profiles

**Why it stands.** The §8.14.8 table saves K04, K05, K07 and K08 per device, but the paragraph under it copies "K01–K12" into every profile.

**Final fix.** Copy only K01–K03, K06 and K09–K12 into profiles. K04, K05, K07 and K08 stay device keys, unchanged.

### MOBILE-21 · low · Several phone controls are sized for 44 px on Android

**Why it stands.**
- §7 and §2.7 require 48 × 48 hit areas on Android. But the §7 intro yields to tables ("Unless a table says otherwise"), and these tables say 44:
  - §7.2 `on-art` and `ruled` "44 hit";
  - §8.14.3 chapter folio "its own 44 px hit area";
  - §9.1.5 Skip recap "44 hit".
- A 44 px running head (§7.13) cannot hold 48 px targets.

**Final fix.**
- The Android running head is 48 + inset (iOS and mobile web stay 44 + inset). §8.8's trailer scrub therefore grows 48 → 64 on Android.
- Every "44 hit" in §7.2, §8.14.3 and §9.1.5 reads "44 (iOS, web) / 48 (Android)", using the `hitMin` and `hitAndroid` tokens.

### MOBILE-22 · low · Three sizes contradict other sections

**Why it stands.**
- §7.14 sets the thumb-index icon at 22, against §2.7's "24 (bars, tabs)".
- §8.16.3 gives the phone play button 56 px, against §7.1's 64.
- §7.7 sets poster captions at "`type.title` 14/20", but no `type.title` breakpoint is 14 px (§3.2: 15/20 on phones and tablets, 16/20 on desktop).

**Final fix.**
- The thumb-index icon is 24.
- §7.1 `play` reads "64 (Listen full player, desktop), 56 (Listen full player, phones), 36 (mini player)".
- §7.7 Below captions read "`type.title` on 1 line (2 at text scale ≥ 1.3)", with the literal 14/20 deleted, so the role's size applies.

### MOBILE-23 · low · `flutter_slidable` serves no row

**Why it stands.**
- §7.16 and §15.11 add `flutter_slidable` 4.0.3 for "two-action rows in Downloads", but §8.23 gives Downloads chapter rows one swipe action, `Remove`.
- Every other swipe row has one action too: Updates, feature and book contents rows `Mark read`; bookmarks `Remove`.

**Final fix.**
- Drop `flutter_slidable` from §7.16, §11 (the "`flutter_slidable` for two actions" note), §15.3 and §15.11.
- Every swipe row uses `Dismissible(direction: DismissDirection.endToStart, dismissThresholds: {DismissDirection.endToStart: 0.5})`, with the 72 px slab painted as its `background`.
- `Mark read` rows use `confirmDismiss: (_) async { markRead(); return false; }`, so the row springs back and dims instead of leaving.

### MOBILE-24 · low · OS bold text and increased contrast are not mapped

**Why it stands.**
- Flutter's `Text` merges `FontWeight.bold` when `MediaQuery.boldTextOf` is true, but every Cinematic role also sets `FontVariation('wght', …)` (§3.1). The variation decides the rendered weight, so the OS setting does nothing.
- The web maps `prefers-contrast: more` (§14.4), but the app has no equivalent of `MediaQuery.highContrastOf`.

**Final fix (§3.1, §14.2, §14.4).**
- **Bold text.** When `MediaQuery.boldTextOf(context)` is true, `CineType` adds 120 to every role's `wght` variation, capped at 900; this is the novel reader's Bold text rule. `fontWeight` is set to the nearest hundred, and Plex Mono's static faces resolve to the nearest bundled weight, 600.
- **Contrast.** When `MediaQuery.highContrastOf(context)` is true, apply the web mapping: `ink.45` → `ink.80`, `rule.1` → `rule.2`.

### MOBILE-25 · low · Strip zoom ranges disagree

**Why it stands.** In strip mode the ranges are inconsistent:
- pinch is 1–3× (§8.14.5, §11);
- the Reading setup stepper is 50–300 % per series (§8.14.8, migrated from K38's 0.5–3.0);
- double tap toggles 1× ⇄ 2×.

Behaviour below 100 % or from 150 % is undefined.

**Final fix (§8.14.5, §8.14.10, §11 Pinch and Double tap rows).**
- The stepper sets the series' resting zoom.
- In strip mode, pinch clamps to 0.5–3.0× and snaps to 0.1 steps on release.
- Double tap goes from the resting zoom to min(2 × resting, 3.0)×, and from any other zoom back to the resting zoom.
- Paged modes stay at 1–3×.
- The chapter swipe and the iOS edge swipe count as "not zoomed" at zoom ≤ 1.0 (MOBILE-2, MOBILE-3).

### MOBILE-26 · low · The Contents sheet is painted in stock colours from the book page, which has no stock

**Why it stands.** §8.15.6 paints the sheet "in the stock colours", and §8.18 opens it from the book page on phones. Inventory N2 says: "or app surface when opened from the series page".

**Final fix (§8.15.6).**
- Opened from the book page, it is a standard §7.9 sheet: `paper.2`, a `rule.2` top edge and a `spot.wash` current row.
- Inside the novel reader it keeps the stock colours.

### MOBILE-27 · low · Settings → Keyboard excludes Android tablets

**Why it stands.**
- §8.30.2 row 12 is scoped "(web, iPad)".
- §14.4 promises the full keyboard map and "Single-key shortcuts can be turned off" on Android tablets too, and §8.0.5 says "keyboard map as iOS".

**Final fix.** Row 12 reads "Keyboard (web; app on tablets, `MediaQuery.sizeOf(context).shortestSide ≥ 600`, iPad and Android)", with the same "Single-key shortcuts" switch.

### MOBILE-28 · low · The Annual's phone frame and its controls are not placed against the safe area

**Why it stands.**
- §9.2.4 says "9:16 story page" and "full-screen takeover", but phones are about 9:19.5.
- The segments and the close `x` are not placed against the status bar or Dynamic Island, while §9.1.5 does place Skip recap "under the safe area".

**Final fix (§9.2.4 Frame, phone).**
- The page fills the screen: art bleeds to every edge, and text and figures sit in a centred 9:16 safe box.
- The segments sit at `viewPadding.top + 8`, with 16 px side margins.
- The close `x` has a 44 hit (48 on Android) and sits 8 px under the segments at the right margin.
- The tap thirds ignore the top `viewPadding.top + 64` px and the bottom `viewPadding.bottom + 48` px.
