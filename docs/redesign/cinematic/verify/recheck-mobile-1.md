# Cinematic DESIGN.md: mobile lens, recheck round 1

Input: the 28 findings in the "Confirmed" section of `cinematic/verify/judge-mobile.md`, checked against `cinematic/DESIGN.md` as it stood on 2026-09-28 at about 22:48 UTC. Other lenses were writing to DESIGN.md while this check ran: the file grew from 4,580 to more than 4,606 lines. Line numbers below are from the end of the check and may drift, so each item also names its section. For every finding I read the sections the final fix names. I also grepped for the old wording that should be gone and for every other place the changed value is repeated.

**Result: 25 resolved, 3 unresolved (MOBILE-5, MOBILE-6, MOBILE-21).** In all three the fix text is in place. What remains is an older passage that repeats the old value and now contradicts it.

Two final fixes were later replaced by fixes from other lenses. DESIGN.md follows the newer fix in both cases, and I count both as resolved:
- **MOBILE-1, iOS back-swipe release.** The judge wrote "Release uses `spring.release`". STACK-28 (`judge-stack.md`) changes that line to the package's hard-coded `Curves.fastLinearToSlowEaseIn`, with no fork. §8.0.5's Back row and "Route transitions in the app" say exactly this. §4.4's `spring.release` row also notes that "the iOS back swipe releases on its package curve".
- **MOBILE-2, reader route duration on tablets.** The judge wrote "872 ms from 600 px". CONSISTENCY-11 fixes the tablet value at 744 ms (8 blades). §8.14.2 now reads 616 / 744 / 872, and §4.5's Column wipe row matches.

---

## Unresolved

### MOBILE-5: two screens still promise Page on a cross-branch jump

The branch table, the push and `go` rules and the declaration order are all in §8.0.3 as the fix asks. Two older lines contradict the new rule "Cross-branch links use `go` into the owning branch, and the notch moves", and the judge quoted the first one when explaining why the finding stands:
- **§8.28 Index, Transitions (l. 2871):** "Cut in; Page to each destination." Updates, Collections, History and Bookmarks are in branch 1; Dialogue search (`/ocr`) and Picks (`/library/recommendations`) are in branch 2; Storage lands in Downloads, branch 3. The fix's own example is Index → Updates as `go('/updates')`. A `go` into another `StatefulShellRoute.indexedStack` branch only switches the stack index, so no page route plays. §8.0.4 plays a section change on phones as Cut + Set + Folio flip.
- **§8.10 Updates, Transitions (l. 2086):** "from the stop-press banner (§8.33.3), Page." The banner appears on any screen except Updates and the readers (§8.33.3), so from Tonight, Discover, Downloads or Index its `Read updates` is a cross-branch `go`.

**Fix:** in §8.28, write "Cut in. In-branch destinations (The Numbers, Circle, Settings, Members, Backup & restore, System status) are pushed with Page. Destinations in another branch (Updates, Collections, History, Bookmarks, Dialogue search, Picks, Storage) use `go` and play the section change of §8.0.4 (Cut + Set + Folio flip); The Annual opens on the root navigator." In §8.10, write "from the stop-press banner: a `go` into branch 1, so the section change of §8.0.4 plays (Page only when the banner was tapped inside branch 1)".

### MOBILE-6: the scrims still use fixed bar heights, but the bars now grow

§3.3, the §7 intro, §7.1 `split`, §7.13, §7.14, §8.14.3 and §8.17 all carry the fix: scale factor `textScalerOf(context).scale(16) / 16`, "Labels in fixed cells", "Heights are minimums", and "drops the icons" removed. The two scrims under those bars were not updated:
- **§2.1.4 and §2.8.3 `scrim.sole` (l. 111, l. 494):** "flat … through the folio bar's top edge (64 px + bottom inset) … bottom 128 px + safe area in all". The web `--mm-scrim-sole` is a fixed `background-image`.
- **§2.1.4 and §2.8.3 `scrim.head` (l. 110, l. 493):** "phone: safe area + 44 px … safe area + 88 px phone in all".

The folio bar is now "min 64 … growing by the height of its second caption line". The running head grows to "title line + 2 × 12". At large text sizes the bar's second line and the grown title therefore sit in the fading part of the scrim, not on the .90 / .88 flat part. That breaks the over-art alpha rule of §2.1.4 ("Text and icons over art") for exactly the text the fix added.

**Fix:** in both `scrim.sole` rows, the flat part runs to the folio bar's **measured** top edge (min 64 px + bottom inset) and the fade covers the next 64 px. In both `scrim.head` rows, the flat part runs to the running head's measured bottom edge (min safe area + 44 px, 48 on Android) and the fade covers the next 44 px. Web `--mm-scrim-sole` then takes a `--scrim-bar` variable, as `--mm-scrim-head` already does. Flutter `scrimSole(bar, fade)` and `scrimHead(bar, fade)` are already parametric and are passed the measured heights.

### MOBILE-21: `scrim.head` still gives the phone bar as 44 px on Android

The fix is in place in §7.13 (Android 48), §8.0.1, §8.0.5 System bars, §8.8 (Android 48 → 64), §7.1 `quiet`, §7.2 `on-art` and `ruled`, §8.14.3 chapter folio (44 / 48 with `hitMin` / `hitAndroid`) and §9.1.5. `scrim.head` still reads "phone: safe area + 44 px" and "safe area + 88 px phone in all" at l. 110 (§2.1.4) and l. 493 (§2.8.3). On Android the running head is now 48 + inset, so its bottom 4 px sit on the fade. The icon buttons and the chapter folio in that bar need the flat .88 ground (§2.1.4).

**Fix:** the same `scrim.head` edit as in MOBILE-6: "phone: safe area + 44 px (48 on Android), or the running head's measured height at large text sizes".

---

## Resolved

| ID | Where it now lives | Checked |
|---|---|---|
| MOBILE-1 | §8.0.5 Back row, "Route transitions in the app", §15.3 `router.dart` and `transitions.dart` rows | Page 320 / 224 ms; match cut 480 / 336 ms with `transitionOnUserGestures: defaultTargetPlatform == TargetPlatform.iOS`; iOS `SwipeablePage` with edge-only 20 pt and a `transitionBuilder` switched by `isSwipeGesture`, the page beneath reading `userGestureInProgress`; Android `CinePageTransitionsBuilder` copying `_PredictiveBackGestureDetector` (values for the fade-through, commit at 240 ms and cancel at 160 ms), `CineMatchCutPage`; Zoom and `PredictiveBackFullscreenPageTransitionsBuilder` never ship. The Android Back cell reads "via `CinePageTransitionsBuilder` (§15.3". No stale "via `PredictiveBackFullscreenPageTransitionsBuilder`" remains. §4.5 Page and Match cut rows and §8.0.4 Back agree. Release curve per STACK-28 (above). |
| MOBILE-2 | §8.14.2 (route, Exit, back target, iOS `canSwipe`, Android), §8.14.10 Back row, §8.15.8, §11 Edge swipe back row, §15.3 | One `SwipeablePage` for both readers; `{entry: 'wipe' \| 'dip'}` in `extra`; the builder paints blades only on forward, the Dip in for `dip`, the Dip on a non-swipe reverse, and the slide while `isSwipeGesture` is true; reverse 440 ms; `canPop` → pop, otherwise `go('/sources/:sourceId/series/:seriesKey')` by Dip, with Android `PopScope(canPop: context.canPop(), …)`. `PageRouteBuilder` is now used only by the Lightbox. Tablet 744 ms per CONSISTENCY-11 (above). |
| MOBILE-3 | §11 "Precedence between horizontal gestures", §11 Contents tabs and strip-swipe rows, §8.0.5 Edge swipes row (iOS, Android "As iOS", web), §8.14.5, §7.16 | Rows win through the gesture arena; web rows `touch-action: pan-y`; nested contents tabs tap only (`NeverScrollableScrollPhysics()`, web with no scroll-snap); strip chapter swipe at zoom ≤ 1.0, starting max(24 px, `systemGestureInsetsOf`) from either edge, within 30° of horizontal, pan above 1.0×. |
| MOBILE-4 | §6 "Audio session and focus policy" table and paragraph, §8.16.5 `Hear`, §8.16.10, §9.4.2 Playback and Audio session, §14.9 | States A, B and Voice sample exactly as the judge wrote them; `handleAudioSessionActivation: false`; startup `configureNovelAudioSession()` replaced by State A; §9.4.2 reads "it mixes with other audio at its own volume, never ducking or stopping it". "stops when other audio starts" is gone. |
| MOBILE-5 | §8.0.3 "Shell branches" | Table, rules and declaration order present. **Two contradicting lines remain (above).** |
| MOBILE-6 | §3.3, §7 intro, §7.1, §7.13, §7.14, §8.14.3, §8.17 | Text present. **Scrim heights stale (above).** |
| MOBILE-7 | §3.3 "Literal sizes", §7.14 Badges | One cap per face through `CineType.literal`; counts and badges capped at 1.3 with a growing box; dialogue subtitles capped at 1.3 with at most two lines. |
| MOBILE-8 | §3.3, §8.15.5 Size row, §14.7 | `TextScaler.noScaling`; absolute 14–40; opening size `clamp(round(textScalerOf(context).scale(18)), 14, 40)`, stored per book. "independent of this cap" is gone. |
| MOBILE-9 | §2.2.2 "Horizontal safe areas", §8.0.9, §8.14.1, §8.15.1 | App and web formulas; bars inset their content while their grounds bleed; readers centred in the safe rectangle; art may bleed. |
| MOBILE-10 | §8.14.1 Landscape phone row | Running head and folio bar hidden at rest and shown together on a centre tap; portrait heights 44 / 48 + inset; back plus four trailing buttons. "folio bar only on tap" is gone. |
| MOBILE-11 | §8.0.5 System bars row, §8.14.3 Auto-hide Motion bullet, §8.15.3 System UI bullet | iOS `manual` with `overlays: []`, Android `immersiveSticky`; `overlays: [SystemUiOverlay.top]` with the 240 ms chrome-in and hidden with the 160 ms chrome-out; exit `edgeToEdge` with transparent bars and `systemNavigationBarContrastEnforced: false`; the strip and column ignore insets. |
| MOBILE-12 | §8.19 series download card, §8.23 Activity | Foreground note and "Paused while the app is in the background." on iOS and Android; "background (app)". |
| MOBILE-13 | §8.16.2 "Following along on the page" | Every value matches: `spot.wash` 200 ms `set` on every stock, 2 px stepped word underline, tint backgrounds dropped, 38 % hold with the 20–70 % band and a 400 ms `ease.settle` scroll, `Back to the voice ↓`, 4000 ms re-follow, reduced motion. Cosmetic only: the last bullet ends with ";" instead of "." (l. 2528). |
| MOBILE-14 | §9.2.5 Flutter export | iOS `NSPhotoLibraryAddUsageDescription` with the exact string, added in the native-plugin commit; Android 29+ `MediaStore.Images.Media`, `Pictures/ManhwaManiacs`, `mm/media`, toast; API 24–28 hides the button. |
| MOBILE-15 | §11 Pull row; Gestures lines in §8.11, §8.21, §9.1.3 | Sources (`GET /sources`, `GET /sources/pins`), Collections and collection detail, Picks (`GET /library/world/recommendations`, `GET /library/suggest/availability`, never re-asks the AI). |
| MOBILE-16 | §12.3 Per-skin icon, §8.30.3 confirm, §8.30.3 and §8.32 restart calls | `setAlternateIconName` with empty blacklists; the package service applies the alias on task removal; no `setComponentEnabledSetting`; the new Android confirm line. `AppRestart.restart()` and "the task is being replaced anyway" are gone. |
| MOBILE-17 | §8.0.5 "Back inside modal states", §8.0.5 Back row, §11 Edge swipe back row | Android back order 1–5; the Switch-profile picker is a pushed takeover; iOS `PopScope(canPop: false)` for states 1–4, and the picker keeps its swipe. §8.7 ("committed on Next, not on swipe alone") and §11 ("commit on Next only") agree with "the pager swipes backward only". |
| MOBILE-18 | §8.14.11 "Saving the next chapter", §8.23 STORAGE tab, §15.4 | Trigger, skips (K20 off Wi-Fi, cap, 1.5 GB floor), no toast or haptic, Downloads badge and the `SAVED` folio on Coming up, per-profile switch default on; the engine owns it. |
| MOBILE-19 | §8.9 Phone layout | `TAGS` checklist hidden when the profile has no tags, `Manage tags…` as its last row, removable tag tokens after the status slug line, `Filters ⁽²⁾`. |
| MOBILE-20 | §8.14.8 migration paragraph | Copies K01–K03, K06 and K09–K12; K04, K05, K07 and K08 stay device keys. This matches the table's scope column. |
| MOBILE-21 | §7.13, §8.0.1, §8.0.5, §8.8, §7.1, §7.2, §8.14.3, §9.1.5 | Text present; every "44 hit" now reads 44 / 48. **The `scrim.head` phone bar height is stale (above).** |
| MOBILE-22 | §7.14 Cell, §7.1 `play`, §8.16.3 Transport, §7.7 Below | Icon 24; `play` 64 / 56 / 36 matches §8.16.3's "56 px play" on phones; the Below caption is `type.title` with no literal 14/20. |
| MOBILE-23 | §7.16, §11 Swipe row, §15.3, §15.11 | `flutter_slidable` appears nowhere; `Dismissible(direction: DismissDirection.endToStart, dismissThresholds: {…: 0.5})` with the 72 px slab; `Mark read` uses `confirmDismiss` returning false. |
| MOBILE-24 | §3.1 "OS bold text", §14.4, §14.7 | +120 `wght` (merged with A11Y-13's per-face clamps: 900, and 800 for Newsreader and Atkinson), `fontWeight` set to the nearest hundred, Plex Mono at its 600 static; `highContrastOf` remaps `ink.45` → `ink.80` and `rule.1` → `rule.2`. No leftover "+150". |
| MOBILE-25 | §8.14.5 Zoom, §8.14.8 Zoom row, §8.14.10 Double tap and Pinch, §11 Double tap and Pinch | Resting zoom from the stepper; strip pinch 0.5–3.0× with a 0.1 snap; double tap from resting to min(2 × resting, 3.0)× and back; paged 1–3× (§8.14.7 agrees); swipes count as not zoomed at zoom ≤ 1.0. |
| MOBILE-26 | §8.15.6 | From the book page it is a standard §7.9 sheet (`paper.2`, `rule.2` top edge, `spot.wash` current row); stock colours inside the reader. |
| MOBILE-27 | §8.30.2 row 12 | "Keyboard (web; app on tablets, `MediaQuery.sizeOf(context).shortestSide ≥ 600`, iPad and Android)". |
| MOBILE-28 | §9.2.4 intro and Frame, phone | Full bleed with a centred 9:16 safe box; segments at `viewPadding.top + 8` with 16 px margins; close `x` hit 44 / 48, placed 8 px under the segments; tap thirds skip the top `viewPadding.top + 64` px and the bottom `viewPadding.bottom + 48` px. §8.0.9 (landscape Annual as a centred 9:16 column) does not conflict. |

## Notes (not blocking)

- MOBILE-13: fix the trailing ";" at the end of the "Following along on the page" list (§8.16.2).
- MOBILE-18: §15.4 says "The engine also owns the next-chapter auto-queue" and then "This contract adds five engine duties" without the auto-queue. That is accurate, because the queue exists today (A072), but §8.14.11 calls it "an engine duty, §15.4". "(an existing engine duty, extended here)" would read more cleanly.
- MOBILE-4: §6's playback line says the session is `.ambient` "whenever narration is not active". While a voice sample plays it is `.playback` with `.duckOthers`. "whenever neither narration nor a voice sample is active" would match the table exactly.
