# Cinematic DESIGN.md: mobile coverage audit

Lens: every screen, element, state and interaction in `inventory/mobile.md`, specified for iOS and Android, including gestures, haptics, back behaviour (iOS edge swipe, Android predictive back), safe areas, system text scale up to 200 % and platform differences. Every "missing" claim below was grepped against the whole of `cinematic/DESIGN.md` (4,101 lines) first. Flutter API claims were checked against the SDK at `/srv/manhwamaniacs/dev/flutter` (3.44.6) and the current app's `mobile/ios/Runner/Info.plist` and `mobile/android/app/src/main/AndroidManifest.xml`.

Totals: 5 high, 14 medium, 9 low.

---

## MOBILE-1 · high · §4.5 (Page, Match cut), §8.0.4, §8.0.5, §15.3

**Problem.** The push and pop transitions every screen inherits cannot be produced by the page builders the contract prescribes.
- iOS: `SwipeablePage` draws a full-width Cupertino slide, and §8.0.5 itself describes that slide. That is not the **Page** move (x 24 px + fade, 320 / 224 ms).
- Android: `MaterialPage` with `PredictiveBackFullscreenPageTransitionsBuilder` plays `ZoomPageTransitionsBuilder` for every button push and pop. The Flutter source says: "Only do a predictive back transition when the user is performing a pop gesture. Otherwise, for things like button presses or other programmatic navigation, fall back to ZoomPageTransitionsBuilder". `MaterialPageRoute` also runs for a fixed 300 ms. A Hero flight takes its route's duration, so the 480 ms **Match cut** cannot happen either.
- "Back: the reverse of the forward move at 0.7 × duration" is undefined for the two gesture paths.

**Evidence.**
- §8.0.4: "Drill-in without a shared element | **Page** (x 24 px + fade)" and "Back | The reverse of the forward move at 0.7 × duration".
- §4.5: "**Page** (push) | in 320 ms / out 224 ms".
- §8.0.5 iOS: "incoming page slides from the edge while the outgoing page drifts 30 % left and dims under `#000` to 0.6".
- §15.3: "page builders: `SwipeablePage` (iOS, edge-only 20 pt) or `MaterialPage` with `PredictiveBackFullscreenPageTransitionsBuilder` (Android)".
- `flutter/packages/flutter/lib/src/material/predictive_back_page_transitions_builder.dart`, `PredictiveBackFullscreenPageTransitionsBuilder.buildTransitions`.

**Fix.** Separate programmatic navigation from gestures and state it in §8.0.5 and §15.3.
- **Programmatic push and pop, both OSes.**
  - **Page**: in, x +24 → 0 px and opacity 0 → 1 over 320 ms `ease.settle`; out, x 0 → −24 px and opacity 1 → 0 over 224 ms `ease.lift`. Pop is the reverse at 224 ms.
  - **Match cut**, when the route was opened from a poster: route `transitionDuration` 480 ms, `reverseTransitionDuration` 336 ms, and `Hero(transitionOnUserGestures: true)` on covers.
- **iOS gesture.** Use `SwipeablePage(canOnlySwipeFromEdge: true, backGestureDetectionWidth: 20)` with a custom transition builder. It paints Page when the pop is not a swipe gesture. During a swipe it paints the finger-tracked slide of §8.0.5: the top page follows x = drag, and the page beneath goes from −30 % to 0 under `#000` from 0.6 → 0. Release uses `spring.release`. If 0.4.8 cannot distinguish a swipe, use a `CupertinoPageRoute` subclass that overrides `buildTransitions`.
- **Android gesture.** Add `CinePageTransitionsBuilder` in `mobile/lib/skins/cinematic/transitions.dart`.
  - Its widget is a `WidgetsBindingObserver` that forwards `handleStartBackGesture`, `handleUpdateBackGestureProgress`, `handleCommitBackGesture` and `handleCancelBackGesture` to `route.handle*BackGesture(progress: 1 − event.progress)`, exactly as Flutter's private `_PredictiveBackGestureDetector` does. Ignore button events.
  - It paints Page for programmatic navigation.
  - While `route.popGestureInProgress` is true it paints a full-screen fade-through: the outgoing page scales 1.00 → 0.95 and its opacity goes 1 → 0 over progress 0–0.6; the incoming page's opacity goes 0 → 1 over progress 0.4–1.0. Commit finishes in 240 ms `ease.settle`; cancel returns in 160 ms `ease.settle`.
  - Register it with `PageTransitionsTheme(builders: {TargetPlatform.android: CinePageTransitionsBuilder()})`. Add a `CinePage` whose `MaterialPageRoute` subclass overrides `transitionDuration` (320 ms) and `reverseTransitionDuration` (224 ms).
  - Never ship the Zoom fallback.

---

## MOBILE-2 · high · §8.14.2, §8.14.10, §8.15.8, §11 (Edge swipe back row), §15.3

**Problem.** Back from either reader cannot be implemented as written and is partly undefined.
1. The readers are a custom `PageRouteBuilder` (the Column wipe). So the iOS "20 pt edge swipe" cannot come from `swipeable_page_route`, which is where §11 says it comes from, and nothing says what the swipe looks like.
2. A single `transitionsBuilder` built from `Interval`s of the route animation replays the blades in reverse on pop. That contradicts "Exit: Dip, never a wipe". No `reverseTransitionDuration` is given.
3. "Predictive back (Dip)" is undefined. A custom route has no predictive-back observer, so there is no preview. The contract has to say that this is intended.
4. The back target when nothing is beneath is given only for the novel reader, and only for Android. Nothing beneath covers a deep link, a notification, a cold-start restore, or a Downloads → reader open after a tab switch. The manga reader, the iOS gesture and the back button have no target. The inventory requires S15 "pop, or go to the series page when nothing is beneath" and S19 "always go to the source series page" (A064).

**Evidence.**
- §8.14.2: "Flutter: a custom `PageRouteBuilder` whose `transitionsBuilder` paints N `Transform(scaleY)` blades from `Interval`s of the route animation" and "Exit (back, `Esc` at the end of the escape order, `s`): **Dip** (160 / 40 / 240), never a wipe".
- §8.14.10: "Back | 20 pt edge swipe (disabled when zoomed or in paged mode) | Predictive back (Dip)".
- §11: "Edge swipe back | Every pushed screen | 20 pt left edge (`swipeable_page_route`)".
- §8.15.8: "Android predictive back (leaves to the book page when nothing is beneath)".
- inventory A064.

**Fix.**
- **Route.** Use `CineReaderRoute extends PageRouteBuilder(opaque: true, transitionDuration: 616 ms on phones / 872 ms from 600 px, reverseTransitionDuration: 440 ms)`. The builder paints the blades only while `animation.status == AnimationStatus.forward`, and the Dip while it is `reverse`: fade to `#000` over 160 ms `ease.lift`, hold 40 ms, then the destination fades in over 240 ms `ease.settle`. Dip entries use the same route with `transitionDuration: 440 ms`.
- **iOS edge swipe.** Put a 20 pt leading-edge `HorizontalDragGestureRecognizer` in the reader.
  - It is active in the strip and scroll layouts at zoom 1.0 and outside guided view. It is disabled in paged layouts, as specified.
  - The reader layer translates x = drag over the screen beneath (made visible with `navigator.didStartUserGesture()`). The screen beneath is dimmed by `#000` at 0.6 × (1 − progress).
  - The swipe commits at ≥ 50 % of the width or ≥ 1 width/s with `spring.release`; otherwise it springs back. A committed swipe pops without playing the Dip.
- **Android.** Readers have no predictive preview. A committed back gesture or the back button plays the Dip.
- **Back target.** Both OSes, both readers, gesture and button: `pop()` when a route lies beneath in the same navigator; otherwise `go('/sources/:sourceId/series/:seriesKey')` (the manga Feature or the novel Book) with the Dip.

---

## MOBILE-3 · high · §7.12, §7.16, §8.9, §8.10, §8.13, §8.14.5, §8.17, §8.23, §11

**Problem.** Horizontal gestures compete and no precedence is given.
- Contents-tab pagers (`TabBarView` swipe) contain rows with swipe-left actions:
  - the feature page's CHAPTERS rows ("swipe a chapter row left → Mark read" alongside "Swipe between contents tabs");
  - the Library hub's UPDATES and BOOKMARKS panels;
  - the SAVED rows in Downloads.
- UPDATES also nests its own `NEW · FOLLOWING` tabs inside the Library hub pager.
- In the manga strip, the ≥ 72 px chapter swipe collides with three other things:
  - the iOS 20 pt edge back;
  - Android gesture-navigation back, which owns both screen edges;
  - horizontal panning while zoomed (strip zoom is 1–3×).

  The 24 px edge exclusion is written for mobile web only.

**Evidence.**
- §11 row: "Horizontal swipe | Contents tabs (Library hub, feature page, Numbers ranges, Circle, Downloads, Settings sections on phones) | Pager".
- §11 row: "Swipe row left | Updates groups, bookmarks, Downloads chapter rows, feature schedule rows, book contents rows".
- §8.17 Gestures: "Swipe between contents tabs (phones) … swipe a chapter row left → Mark read".
- §8.0.5: "Edge swipes | n/a | n/a | In-reader horizontal gestures … ignore touches that start within 24 px of either screen edge".
- §8.14.5: "Horizontal swipe ≥ 72 px (phones, on by default in strip mode) changes chapter".

**Fix.** Add this precedence rule to §11.
- **Rows.** A horizontal drag that starts on a row with swipe actions belongs to the row.
- **Pagers.** A pager receives only drags that start outside rows: the masthead, the tab row, the toolbar or empty space. Implement it with `TabBarView(physics: const NeverScrollableScrollPhysics())` on panels that have swipe rows, plus a `HorizontalDragGestureRecognizer` on the non-row areas that calls `TabController.animateTo(i)` (320 ms `ease.settle`, commit at 72 px or 600 px/s).
- **Nested tabs.** The nested `NEW · FOLLOWING` tabs switch by tap only.
- **Strip chapter swipe.** It is live only when all of these hold:
  - zoom = 1.0;
  - the touch starts ≥ max(24 px, `MediaQuery.systemGestureInsetsOf(context).left/right`) from both edges (on iOS, ≥ 24 pt from the leading edge);
  - the drag is within 30° of horizontal.

  While zoomed above 1×, horizontal drags pan the page.

---

## MOBILE-4 · high · §6, §8.16.5, §8.16.10, §9.4.2, §14.9

**Problem.** On iOS the audio-session rules contradict each other. The app has one app-wide `AVAudioSession`, and three sources ask for three different settings:
- Narration keeps `audio_session` "speech", which is the playback category.
- The soundscape plays "under the same `audio_session` (ambient category on iOS)". It also ducks to 30 % under narration, so both play at once under one category.
- `flutter_soloud` UI cues use `.ambient`.

Voice samples (`Hear`) also go through `flutter_soloud`, so under `.ambient` the ring/silent switch mutes the 31-voice previews.

On Android, the audio focus the soundscape player requests is unspecified. `just_audio` requests focus by default, which contradicts "it never ducks the user's music".

**Evidence.**
- §8.16.10: "the `audio_session` category stays speech".
- §9.4.2: "a second `just_audio` player (`LoopMode.one`, already installed) under the same `audio_session` (ambient category on iOS so the silent switch mutes it; it never ducks the user's music, and it stops when other audio starts)" and "Ducks to 30 % while Listen narration plays".
- §6: "iOS uses the `.ambient` session category so the ring/silent switch mutes cues".
- §8.16.5: "Flutter: the sample plays through `flutter_soloud` 5.1.4".

**Fix.** Add one session policy to §6 and reference it from §8.16 and §9.4.2.

| State | When | iOS session | Android focus | Behaviour |
|---|---|---|---|---|
| **A** | Idle, UI cues only, or soundscape only | `AVAudioSessionCategoryAmbient` (mixes with others; the silent switch mutes; stops in the background) | The soundscape `just_audio` player uses `handleAudioSessionActivation: false` and requests no focus | Soundscape and cues play |
| **B** | Narration playing, or paused inside the reader | `AudioSessionConfiguration.speech()`: `.playback`, mode `.spokenAudio` | `AUDIOFOCUS_GAIN`, usage media, content type speech | The soundscape keeps playing at 30 % gain, or pauses per the switch, and the silent switch no longer mutes it; UI cues are suppressed |
| **Voice sample** | While a sample plays | `.playback` with `.duckOthers` | `AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK` | The ringer switch never silences a sample |

- Switch between A and B with `AudioSession.instance.configure` when narration starts and stops.
- After a sample ends, return to the previous state.

---

## MOBILE-5 · high · §7.13, §7.14, §8.0.2, §8.0.3, §8.0.5

**Problem.** The five-branch phone shell has no route-to-branch map, so tab ownership and back behaviour are guesses.
- **Library hub tabs.** They are "each its own route" and swipeable. It is not said whether switching hub tabs pushes, replaces, or is a nested shell.
- **Back arrow.** It is not said whether `/updates`, `/library/collections`, `/library/history` and `/library/bookmarks` show a back arrow ("nothing on tab roots").
- **Android back from UPDATES.** It is not said whether back goes to SHELF or to Tonight.
- **Multi-entry routes.** It is not said which branch owns routes that are reached from several tabs:
  - Picks (Discover, Index, Tonight);
  - The Numbers and The Annual (Index, Tonight);
  - Updates, Collections, History and Bookmarks when opened from Index;
  - Sources;
  - Settings.

The inventory flags exactly this ("More → History/Bookmarks/Stats/Recs switches the user into the Library tab's stack").

**Evidence.**
- §8.0.2: "*Library* is a hub with contents tabs `SHELF · UPDATES · COLLECTIONS · HISTORY · BOOKMARKS`, each its own route".
- §7.13: "nothing on tab roots".
- §8.0.5: "branch roots return to Tonight, then the system takes over".
- §8.28: Index lists Updates, Collections, History, Bookmarks, The Numbers and Picks.
- inventory §7 gap 11.

**Fix.** Add a branch table to §8.0.3.
- **Branch 0 (Tonight):** `/`.
- **Branch 1 (Library):** a nested `StatefulShellRoute.indexedStack` whose five hub tabs are the roots `/library`, `/updates`, `/library/collections`, `/library/history` and `/library/bookmarks`.
  - Switching hub tabs replaces the route; none of the five shows a back arrow.
  - Android back from a hub tab other than SHELF goes to SHELF, then to Tonight.
  - `/library/collections/:id` is pushed inside branch 1, with a back arrow.
- **Branch 2 (Discover):** `/search`, `/sources`, `/sources/:sourceId`, `/ocr`, `/library/recommendations`.
- **Branch 3 (Downloads):** `/downloads`.
- **Branch 4 (Index):** `/more`, `/settings…`, `/library/statistics`, `/circle`, `/circle/:profileId`, `/profiles/manage`.
- **Root navigator** (thumb index hidden): `feature`, `featureByFollow`, `reader`, `readAll`, `novel`, `recap`, `annual`, `onboarding`, `profiles*`, the Lightbox.
- **Cross-branch links** switch branch, and the notch moves; they never push a duplicate. For example, Index → Updates does `go('/updates')` into branch 1.

---

## MOBILE-6 · medium · §3.3, §7.1, §7.14, §8.14.3, §8.17

**Problem.** The reflow rules miss real overflows at the stated caps.
- **Thumb index.** At ≥ 1.3, `type.nav` switches to `wdth` 100 and grows to 13–15 px. "DOWNLOADS" and "DISCOVER" then measure about 90–108 px and overflow a 75–86 px cell on 375–430 pt phones.
- **Feature page.** The labelled icon row `FOLLOW · FAVOURITE · NOTIFY · DOWNLOAD · SEND` overflows the same way.
- **Fixed heights.** These are never said to grow:
  - buttons 44 / 48 / 56;
  - the split button stacked at ≥ 1.5, which needs about 54 px;
  - the running head, 44;
  - the folio bar, 64.
- **Scale factor.** "Scale factor ≥ 1.3" is undefined under Android 14's non-linear scaler, because `TextScaler` has no single factor.

**Evidence.**
- §3.3: "at ≥ 1.3 these switch from `wdth` 62–75 to `wdth` 100" and "≥ 1.5: split buttons (§7.1) stack label over folio; the tab bar keeps its labels at the 1.5 cap and drops the icons".
- §7.14: "Icon 22 … label (`type.nav` 10/12)".
- §8.17 phone: "a row of the icon buttons with labels under them (`FOLLOW · FAVOURITE · NOTIFY · DOWNLOAD · SEND`)".
- §7.1: "md 44 (desktop) / 48 (phone); lg 56".

**Fix.**
- **Scale factor.** Define it as `MediaQuery.textScalerOf(context).scale(16) / 16`.
- **Thumb index and the feature icon-row labels:**
  - keep `wdth` 62 at every scale;
  - cap at 1.3 (13/16);
  - tracking +0.06em at ≥ 1.3;
  - `maxLines: 1` inside `FittedBox(fit: BoxFit.scaleDown)`, down to 10 px.
- **Thumb index at ≥ 1.5.** Keep the 24 px icons and grow the bar to 64 + the bottom inset (replace "drops the icons").
- **Feature icon row at ≥ 1.3.** It wraps to two rows (3 + 2).
- **Heights in §7 are minimums:**
  - general rule: height = max(token, line height of the scaled text + 2 × 12 px);
  - split button stacked at ≥ 1.5: label line + folio line + 2 × 8 px, min 64;
  - running head: min 44, grows to the title line + 2 × 12;
  - folio bar: min 64, grows by the second caption line.

---

## MOBILE-7 · medium · §3.3, §3.5 (literal styles outside the role table)

**Problem.** Many phone styles are given as a literal family and size instead of a role, so they have no Dynamic Type or font-scale cap. Whether they scale, and how far, is a guess:
- slug-line chips (Archivo `wdth` 75, 12/16);
- count badges (Plex Mono 10);
- poster title cards (Bodoni Moda Italic 14/16);
- book-list titles (Bodoni Moda Italic 20) and blurbs (Newsreader 15);
- novel contents rows (Newsreader 16);
- voice names (Bodoni Moda Italic 20);
- the Listen transcript (Newsreader 20/30 on phones);
- recaps (Newsreader 18/28);
- dialogue subtitles (Newsreader 18/24) and transcripts (18/28);
- the onboarding genre paragraph (Bodoni Moda Italic 22 on phones);
- What's new (Newsreader 16, Plex Mono 15).

**Evidence.**
- §7.5: "Label | Archivo `wdth` 75, `wght` 600, 12/16 uppercase".
- §7.19: "Count badge … Plex Mono 10".
- §7.7: "Bodoni Moda Italic 14/16".
- §8.9.1: "title in Bodoni Moda Italic 20 … blurb (Newsreader 15".
- §8.16.3: "Full width, Newsreader 20/30".
- §8.24: "Newsreader 18/24".
- §8.7: "Bodoni Moda Italic 28 (22 on phones)".
- §3.3 gives caps only per role.

**Fix.** Add these to §3.2, §3.3 and §3.5 as roles so `CineType` resolves them.
- **New role `type.slug`** (Archivo `wdth` 75, `wght` 600, 12/16, +0.10em, cap 1.5): slug-line labels.
- **Count badges:** use `type.micro`, cap 1.3; the badge box grows from min 16 to min 20 at the cap.
- **Display-face literals** (title card, book-list title, voice name, onboarding paragraph): cap 1.30, like `section`.
- **Reading literals** (Newsreader 15–22, Plex Mono 15): cap 2.0, like `body`.
- **Subtitles laid over dialogue stills:** cap 1.3, with two lines at most.

---

## MOBILE-8 · medium · §3.3, §8.15.5, §14.7

**Problem.** It is contradictory whether the novel body follows the system text scale. §3.3 lists "up to 40 px body text independent of this cap" as a ≥ 2.0 reflow rule, which implies the range only opens at 2.0 or that the scaler is ignored. §8.15.5 gives everyone a Size range of 14–40 px with an 18 px phone default. At system 2.0 it cannot be told whether 18 px renders as 18, 36 or 40.

**Evidence.**
- §3.3: "≥ 2.0: … the novel reader's type steps allow up to 40 px body text independent of this cap (its own setting)".
- §8.15.5: "Size | 14–40 px, stepper step 1 | 19 desktop / 18 phone".
- §14.7: "The novel reader has its own size range up to 40 px".

**Fix.**
- The novel body uses `TextScaler.noScaling`. Its Size is absolute: 14–40 px.
- When a book with no stored size is first opened, its default is `clamp(round(18 × textScaler.scale(18) / 18), 14, 40)`. A user at system 2.0 therefore starts at 36 px.
- The reader's chrome text follows the normal role caps.
- Reword the §3.3 bullet to say this.

---

## MOBILE-9 · medium · §2.2.2, §7.13, §7.14, §8.0.9

**Problem.** Horizontal safe areas are not handled. The iPhone app allows landscape (`UISupportedInterfaceOrientations` lists Portrait, LandscapeLeft and LandscapeRight in `mobile/ios/Runner/Info.plist`), which puts the sensor housing on the left or right, an inset of about 47–62 pt. Android cutouts do the same. Yet the grid margins (16, or 32 on the tablet grid that landscape phones use at ≥ 600 px), the running head, the thumb index and the reader chrome are given without left and right insets. Content and controls would render under the notch.

**Evidence.**
- §8.0.9: "Landscape phones (height < 500 px): … every other screen uses its tablet row when the width is ≥ 600 px".
- §2.2.2 margin column (16 / 32).
- A grep for inset, safe area, cutout and landscape finds no horizontal-inset rule.

**Fix.** Add to §2.2.2 and §8.0.9:
- Horizontal margin = max(grid margin, `MediaQuery.viewPaddingOf(context).left` or `.right` + 8 px).
- The running head, thumb index, toasts and select-mode bar inset their content by the same amounts. Their `#000` grounds still bleed edge to edge.
- The readers centre the strip or column inside the safe rectangle, and no chrome control sits inside an inset.
- Full-bleed art (the Tonight cover and the feature hero) may bleed under the inset.

---

## MOBILE-10 · medium · §8.14.1

**Problem.** In landscape on a phone, the manga reader hides its running head and shows only the folio bar, on tap. The running head holds back, download, bookmark, guided view and Reading setup, so Reading setup and the download mark become unreachable. Bookmark is reachable only through a page long-press, and back only through the system gesture or button.

**Evidence.** §8.14.1: "Landscape phone | Strip column 70 % of the width, centred; running head hidden, folio bar only on tap".

**Fix.**
- In landscape the running head is hidden at rest and returns together with the folio bar on a centre tap, with the same auto-hide rules.
- Its height is 40 px + the top inset, and it keeps the back button and the four trailing buttons.
- Change the row to: "Strip column 70 % of the width, centred; both chrome bands hidden at rest and shown together on tap".

---

## MOBILE-11 · medium · §8.0.5 (System bars), §8.14.3, §8.15.3

**Problem.** Reader system UI is underspecified on both OSes.
- iOS: only "home indicator auto-hidden in readers" is given. Nothing says whether the status bar is hidden in the readers.
- Both OSes: nothing says whether the system bars appear together with the chrome.
- Android: `immersiveSticky` keeps the bars hidden while the chrome shows, yet the running head is "44 + status inset". It is unclear whether that inset stays reserved while the bar is hidden.

Today both readers hide the status bar on both OSes (inventory G11: "Reading mode (both readers): `immersiveSticky`").

**Evidence.**
- §8.0.5: "Status bar light content; home indicator auto-hidden in readers | … readers use `immersiveSticky`".
- §8.14.3: "44 + status inset phone".

**Fix.**
- **On reader enter:** Android `SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky)`; iOS `SystemUiMode.manual` with `overlays: []`, which hides the status bar and the home indicator.
- **When the chrome shows:** show the status bar only (`SystemUiMode.manual`, `overlays: [SystemUiOverlay.top]`) on both OSes, in step with the 240 ms chrome-in. Hide it again with the 160 ms chrome-out.
- **Running head height:** always 44 + `MediaQuery.viewPaddingOf(context).top`. Use `viewPadding`, not `padding`, so nothing jumps.
- **On exit:** restore `SystemUiMode.edgeToEdge` with `SystemUiOverlayStyle.light`, `statusBarColor` and `systemNavigationBarColor` `Color(0x00000000)`, and `systemNavigationBarContrastEnforced: false`.

---

## MOBILE-12 · medium · §8.19, §8.23

**Problem.** The foreground-only download note and the "paused in the background" reason are specified for iOS only. Android downloads also pause in the background: inventory G10 says so, and so does §8.23's own K-row ("downloads run only in the foreground (G10)"). Android users therefore get no explanation. Today the note is shown on both platforms (inventory S10 #13, S21 #14).

**Evidence.**
- §8.19: "and on iOS the foreground note".
- §8.23: "background (iOS): "Paused while the app is in the background."" and "the iOS foreground note".

**Fix.** Show both on iOS and Android.
- The note "Downloads run while the app is open; leaving pauses them and coming back picks up where they stopped." appears in the Activity block and in the series download card.
- The pause reason "Paused while the app is in the background." appears on both.
- Replace "(iOS)" and "on iOS" with "(app)".

---

## MOBILE-13 · medium · §8.15, §8.16 (in-page follow-along)

**Problem.** The follow-along on the novel page while narration plays with the mini player is not specified. The inventory has it (S26 #8): spoken text gets a background, the current phrase a stronger one, and the spoken paragraph auto-scrolls to the reading line over 260 ms unless the user is scrolling. The contract specifies highlight, hold line and decouple rules only for the full player's transcript (§8.16.3). The page, where the mini player sits, has none: no highlight colours on the paper stocks, no scroll timing and no decouple rule.

**Evidence.**
- §8.16.3 gives these rules for the transcript only.
- §8.15.2 has no Listen state.
- §13 item 8 says "the page holds the line at the reading height" with no values.
- inventory S26 #8.

**Fix.** Add "Following along on the page" to §8.16.2:
- the active sentence gets a `spot.wash` band (`rgba(244,208,63,0.16)`) on every stock;
- the spoken word gets a 2 px underline in stock ink that steps without animation;
- the spoken paragraph is held at the reading line (38 %) by a 400 ms `ease.settle` scroll that runs only when it leaves the 20–70 % band;
- a manual scroll decouples it and shows a `quiet` `Back to the voice ↓` in stock colours above the mini player; it re-follows after 4000 ms idle;
- under reduced motion, scrolls jump;
- speaker tints stay as underlines.

---

## MOBILE-14 · medium · §9.2.5

**Problem.** Two things are missing for Save image:
- **iOS.** Save image goes through the share sheet's "Save Image", which writes to Photos and needs `NSPhotoLibraryAddUsageDescription`. The current `Info.plist` has only `NSPhotoLibraryUsageDescription`, and the contract gives neither the key nor its copy.
- **Android.** The share sheet has no guaranteed save-to-gallery target, so the phone `Save image` button has no defined behaviour.

**Evidence.**
- §9.2.5: ""Save image" writes to the photo library through the share sheet's own Save option (no photos permission plugin)".
- `mobile/ios/Runner/Info.plist` has `NSAppleMusicUsageDescription` and `NSPhotoLibraryUsageDescription` only.

**Fix.**
- **iOS.** In the native-plugin commit, add `NSPhotoLibraryAddUsageDescription` = "ManhwaManiacs saves share cards to Photos only when you choose Save image. It never reads your library." `Save image` opens the share sheet.
- **Android API 29+.** `Save image` inserts the PNG into `MediaStore.Images.Media` under `Pictures/ManhwaManiacs/manhwamaniacs-{template}-{format}.png`, through a small `mm/media` method channel that needs no permission. Toast: "Card saved to Pictures › ManhwaManiacs."
- **Android API 24–28.** The button is hidden, and `Share` is the only action.

---

## MOBILE-15 · medium · §7.29, §8.11, §8.21, §9.1.3, §11 (Pull down row)

**Problem.** Pull to refresh was dropped from four inventory screens, and the phone gets no other way to refresh them:
- Sources (S16 #16, sources and pins);
- Collections (S24 #12);
- Collection detail (S25 #13);
- Recommendations / Picks (S11 #20).

The web alternative is the `r` key, which phones do not have.

**Evidence.** The §11 row "Pull down past the top (96 px) | Tonight, Library, Updates (reloads the list), History, Bookmarks, The Numbers, Circle, source catalogue" omits them, and §8.11, §8.21 and §9.1.3 never mention it.

**Fix.** Add Sources, Collections, Collection detail and Picks to that §11 row and to each screen's Gestures line.
- Sources refetches `GET /sources` and `GET /sources/pins`.
- Collections and the collection detail refetch their payloads.
- Picks refetches `GET /library/world/recommendations` and `GET /library/suggest/availability`, never re-asking the AI.

---

## MOBILE-16 · medium · §12.3, §8.30.3, §8.32

**Problem.** Two problems with the Android icon switch:
- **The alias swap.** §12.3 applies the activity-alias swap "at the restart (the task is being replaced anyway)". But the skin restart runs in-process: `stack-decision.md` §2.5 describes `AppRestart` as a UniqueKey swap in the same Activity. The task is not replaced, and disabling, through PackageManager, the alias the task was launched from can kill the process in the middle of the restart. That loses the return route and the `SKIN RESTART` measurement.
- **The API name.** The contract calls `AppRestart.restart()`, but the stack defines `AppRestart.of(context).restart()`.

**Evidence.**
- §12.3: "On Android the switch is an `activity-alias` swap applied at the restart (the task is being replaced anyway)".
- `stack-decision.md` lines 97 ("app_restart.dart ~15 lines: StatefulWidget that swaps a UniqueKey above ProviderScope") and 155 ("`AppRestart.of(context).restart()`").
- §8.30.3 and §8.32: "`AppRestart.restart()`".

**Fix.**
- Stop the press writes the chosen alias to SharedPreferences `mm.icon.pending`.
- The swap (`setComponentEnabledSetting`, `DONT_KILL_APP`) runs when the app next reaches `AppLifecycleState.paused` or `detached`, never during the restart.
- The Android confirm line becomes "The app icon changes the next time you leave the app. Shortcuts on your home screen may need adding again."
- Use `AppRestart.of(context).restart()` in §8.30.3 and §8.32.

---

## MOBILE-17 · medium · §7.29, §8.5, §8.7, §8.16.3, §8.19, §8.30.1

**Problem.** Android back and the iOS edge swipe are undefined inside modal states and takeovers:
- select mode (Library, chapter selection, collection Reorder);
- the Listen full player (only swipe-down and `Esc` are given);
- the full-screen settings search;
- onboarding steps: it is unclear whether back goes to the previous step or leaves onboarding, and "committed on Next, not on swipe alone" does not say whether a swipe can move forward at all;
- the profile picker opened from Switch profile: the picker "shows whenever no profile is active … after `Switch profile`", so back could leave the app with no profile active.

**Evidence.**
- §8.7: "Phones use a horizontal pager between steps with swipe (the step is committed on Next, not on swipe alone)".
- §8.5: "The picker shows whenever no profile is active on this device (after sign-in, after `Switch profile` …)".
- §8.16.12: "Esc collapses the full player".
- §7.29: select-mode bar "and `Done`".

**Fix.** Add a back order to §8.0.5 that applies to Android back and the iOS edge swipe alike:
1. Close the open sheet, menu or dialog.
2. Exit select or reorder mode, the same as `Done`; the selection is discarded.
3. Collapse the Listen full player to the mini player.
4. Close the settings search.
5. In onboarding, go from step n to step n − 1 with the pager's 320 ms `ease.settle`. The pager swipes backward only; forward needs `Next`. From the first shown step, back returns to the picker.
6. On a picker opened by Switch profile, back returns to the previous screen with the previous profile still active. The active profile is replaced only when another profile is picked. On the sign-in picker, back is left to the system.

---

## MOBILE-18 · medium · §8.14, §8.23 (K20 row)

**Problem.** S19's automatic queueing of the next chapter (A072: "auto-queue next chapter download; skipped on cellular when wifi-only is set") is mentioned only as the thing K20 gates. The unified reader never says whether the next chapter is still auto-queued, from which entries, under what limits, or how that is shown. S15 and S19 are now one route, so behaviour today depends on the entry and has no rule.

**Evidence.**
- §8.23: "`Download on Wi-Fi only` switch (K20: gates the auto-queue of the next chapter)".
- §8.14 has no auto-queue rule (grep for "auto-queue" returns only the K20 line).

**Fix.** Add to §8.14 (engine duty, §15.4).
- **Trigger.** When a downloads scope exists and `client_downloads` is on, opening any manga chapter whose next chapter is not saved queues that one chapter once per open.
- **Skips.** It is skipped when:
  - K20 is on and the device is not on Wi-Fi;
  - the storage cap or the 1.5 GB floor is reached;
  - the 18+ gate hides the series.
- **Feedback.** There is no toast and no haptic. The Downloads badge counts it, and the Coming up card's folio shows `SAVED` once it has finished.
- **Setting.** Add a per-profile switch, Settings → Downloads & storage "Save the next chapter while I read", default on.

---

## MOBILE-19 · medium · §8.9 (Phone layout)

**Problem.** Phones cannot filter the library by tag. The desktop toolbar has `TAGS ▾` with removable tokens, but the phone Filters sheet lists only favourites, new only, sort, density and reading status. Tags can be managed from a feature page, but not used to filter.

**Evidence.**
- §8.9 desktop: "`TAGS ▾` (a menu of the profile's own tags as a multi-select checklist …)".
- §8.9 phone: "a `Filters` quiet button opening a sheet (favourites, new only, sort, density, reading status)".

**Fix.**
- Add a `TAGS` section to the phone Filters sheet: a multi-select checklist of the profile's tags, hidden when there are none, with a last row `Manage tags…` that opens the tag sheet.
- Active tags appear as removable tokens after the status slug line, and the `Filters` button shows the count of active filters as a superscript folio.

---

## MOBILE-20 · low · §8.14.8

**Problem.** The storage scope contradicts the migration. The table makes refresh rate (K04), keep awake (K05), lock controls (K07) and volume keys (K08) per device, but the migration copies "K01–K12" into every profile.

**Evidence.**
- §8.14.8 rows for K04, K05, K07 and K08 say "per device".
- §8.14.8: "Mobile keys K01–K12 are device-wide today. On the first launch of this skin, their values are copied into every profile on the device".

**Fix.** Copy only K01–K03, K06 and K09–K12 into profiles. K04, K05, K07 and K08 stay device keys, unchanged.

---

## MOBILE-21 · low · §7.2, §7.13, §8.14.3, §9.1.5, §14.6

**Problem.** Several phone controls are sized at 44 px, which contradicts the Android 48 × 48 target rule:
- the running head is 44 px tall but carries 48 px Android hit targets;
- the reader's chapter folio gets "its own 44 px hit area";
- the `on-art` and `ruled` icon-button variants list "44 hit";
- Skip recap says "44 hit".

**Evidence.**
- §7.13: "Height | 44 + status bar inset".
- §8.14.3: "the chapter folio (its own 44 px hit area, tooltip "Contents")".
- §7.2: "`on-art` | 40 px square … | 44 hit".
- §14.6: "At least 44 × 44 (iOS, web) and 48 × 48 (Android)".

**Fix.**
- The Android running head is 48 + inset; iOS stays 44 + inset.
- Every "44 hit" in §7.2, §8.14.3 and §9.1.5 reads "44 (iOS, web) / 48 (Android)", using `hitMin` and `hitAndroid`.

---

## MOBILE-22 · low · §2.7, §7.1, §7.7, §7.14, §8.16.3

**Problem.** Three sizes contradict other sections:
- The thumb-index icon is 22, which is outside the icon size set (16 / 20 / 24 / 32; "24 (bars, tabs)").
- The Listen full-player play button is "56 px" on phones, but §7.1 says 64.
- Poster captions use "`type.title` 14/20", but the role is 15/20 on phones.

**Evidence.**
- §7.14: "Icon 22".
- §2.7: "24 (bars, tabs)".
- §8.16.3: "same, 56 px play".
- §7.1: "64 (Listen full player)".
- §7.7: "`type.title` 14/20".
- §3.2: "`type.title` … 15/20".

**Fix.**
- The thumb-index icon is 24.
- §7.1 `play` reads "64 (Listen full player, desktop), 56 (phones), 36 (mini player)".
- Poster captions use `type.title` 15/20 on phones; if 14 px is intended, add a `type.title.sm` role at 14/20 with cap 2.0.

---

## MOBILE-23 · low · §7.16, §8.23, §15.3, §15.11

**Problem.** `flutter_slidable` is added for "two-action rows in Downloads", but §8.23 gives Downloads chapter rows a single swipe action, Remove.

**Evidence.**
- §7.16: "`flutter_slidable` 4.0.3 only where a row needs two (Downloads chapter rows)".
- §8.23: "`Remove` (swipe left or trash; toast with Undo for 8 s)".

**Fix.** Either name the second slab (for example `Save to Files`, fill `ink.100`, `#000` label, manga saved chapters only), or drop `flutter_slidable` from §7.16, §15.3 and §15.11 and use `Dismissible` for Remove.

---

## MOBILE-24 · low · §3.1, §14.2, §14.4

**Problem.** Two OS accessibility settings are not mapped in the app:
- **Bold text.** Flutter's `Text` merges `FontWeight.bold` when `MediaQuery.boldTextOf` is true (iOS Bold Text, Android bold text). But every Cinematic role sets an explicit `FontVariation('wght', …)`, and the variation wins, so the OS setting silently does nothing.
- **Contrast.** iOS Increase Contrast and Android high-contrast text (`MediaQuery.highContrastOf`) are not mapped, although the web maps `prefers-contrast: more`.

**Evidence.**
- §3.1: "set both `fontWeight` and `FontVariation('wght', …)`".
- §14.4: "Under `@media (prefers-contrast: more)` the `ink.45` role renders `ink.80` and `rule.1` renders `rule.2`" (web only).

**Fix.**
- When `MediaQuery.boldTextOf(context)` is true, add +120 to every role's `wght` variation and to `fontWeight`, capped at 900 (the same rule as the novel reader's Bold text).
- When `MediaQuery.highContrastOf(context)` is true, apply the web mapping: `ink.45` → `ink.80`, `rule.1` → `rule.2`.

---

## MOBILE-25 · low · §8.14.5, §8.14.8, §11 (Pinch)

**Problem.** The zoom ranges in strip mode disagree:
- pinch is 1–3×;
- the setup stepper is 50–300 % (from the inventory's 0.5–3.0×);
- double tap toggles 1× ⇄ 2×.

Nothing says what a pinch does at a stepper value below 100 %, or what double tap does from 150 %.

**Evidence.**
- §8.14.5: "pinch 1–3×".
- §8.14.8: "Zoom | stepper 50–300 %, step 10".
- §11: "Pinch | Reader (strip, paged) | 1–3×".

**Fix.**
- Strip pinch clamps to 0.5–3.0×, the same as the stepper, and snaps to 0.1 steps on release.
- Double tap goes to 2.0× from exactly 1.0×, and to 1.0× from any other value.
- Paged modes stay at 1–3×.

---

## MOBILE-26 · low · §8.15.6, §8.18

**Problem.** The Contents sheet is "in the stock colours", but on phones it also opens from the book page, which has no stock (the book page uses the app surfaces). The inventory specifies app colours for that entry (N2: "page-coloured (or app surface when opened from the series page)").

**Evidence.**
- §8.15.6: "An 85 % sheet (phone) … in the stock colours".
- §8.18 phone: "go-to via a search icon that opens the contents sheet in search mode (N2)".

**Fix.** From the book page the sheet is a standard §7.9 sheet (`paper.2`, `rule.2` top edge, `spot.wash` current row). Inside the novel reader it uses the stock colours.

---

## MOBILE-27 · low · §8.30.2 (row 12), §8.0.5, §14.4

**Problem.** Settings → Keyboard is scoped "(web, iPad)", yet the contract promises hardware-keyboard use on Android as well ("keyboard map as iOS"; "hardware keyboard on iPad and Android tablets"). Android users with a keyboard therefore cannot see the key registry or switch off single-key shortcuts.

**Evidence.**
- §8.30.2: "12 | **Keyboard** (web, iPad)".
- §8.0.5: "Volume keys page in the reader (opt-in); keyboard map as iOS".
- §14.4.

**Fix.** Row 12 reads "Keyboard (web; app on tablets, `MediaQuery.sizeOf(context).shortestSide ≥ 600`, iPad and Android)", with the same "Single-key shortcuts" switch.

---

## MOBILE-28 · low · §9.2.4 (Frame, phone)

**Problem.** The Annual's phone frame is set as "9:16 story pages", but phones are about 9:19.5. It is not said whether the page letterboxes or fills the screen. The top segment row and the close `x` are also not placed against the status bar or Dynamic Island. §9.1.5 does place Skip recap "under the safe area"; the Annual has no such rule.

**Evidence.**
- §9.2.4: "each a spread on desktop and a 9:16 story page on phones" and "a row of 2 px segments at the top … close `x` top-right".

**Fix.**
- On phones the page fills the screen: art bleeds to all edges, and text and figures sit in a centred 9:16 safe box.
- The segments sit at `viewPadding.top + 8`, with 16 px margins.
- The close `x` has a 44 / 48 hit, 8 px under the segments at the right margin.
- Tap thirds ignore the top `viewPadding.top + 64` px and the bottom `viewPadding.bottom + 48` px.
