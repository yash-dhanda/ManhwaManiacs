# Recheck round 2: Glass mobile lens (`judge-mobile.md`, section "Confirmed")

Method: I re-verified all 27 confirmed findings against the live `glass/DESIGN.md` (4,606 lines), not only the two findings round 2 edited (MOBILE-10, MOBILE-15). Other lenses keep editing the file, so a finding marked resolved in round 1 can still regress. For each finding I:

- read the edited sections in full;
- compared them with the judge's final fix;
- grepped for the old values the fix should have removed;
- grepped for every other place that repeats a changed value or rule.

I also re-checked the `cinematic/DESIGN.md` cross-references that Glass relies on:

- §8.14.11, l. 2380: the auto-queue of the next chapter;
- §8.23, l. 2789: `saveDownload`, `Download/ManhwaManiacs/Exports/{series}/`, the iOS path `On My iPhone › ManhwaManiacs › Exports › {series}`, and the flow named "Save to Files" on both platforms;
- §9.2.5, l. 3375: the `mm/media` MediaStore insert at `Pictures/ManhwaManiacs`;
- §8.4: the username rule.

All four still say what Glass cites. Line numbers below refer to the 4,606-line state.

**Result: 27 resolved, 0 unresolved.** Round 2 closed the two residual contradictions from round 1. The other 25 findings still hold in the live file, and none has regressed.

Five resolved findings differ on purpose from the judge's wording. Each difference aligns the text with a value that already binds the document, so none of them should be re-applied:

| Finding | Judge's wording | What the file says now | Why |
|---|---|---|---|
| MOBILE-1, MOBILE-2 | 621 ms | 615 ms | 615 ms is the `page` settle in §4.2 (l. 1056), §4.10 (l. 1198–1199) and `--mm-spring-page-ms: 615ms` (l. 799, 4132) |
| MOBILE-12 | API 30+ for the `GESTURE_*` rows | API 34+, with `CONFIRM`/`REJECT` at 30+ | `GESTURE_THRESHOLD_*` is an API 34 constant |
| MOBILE-7 | Wrapped "Read this card" button | Wrapped reflows into a scrolling column at `f ≥ 1.3` | This is the a11y judge's fix, which supersedes the mobile one |
| MOBILE-27 | The mobile judge's short copy | The product judge's per-code table | The product judge's table was added to §8.4 first |
| MOBILE-10 | Android flow named "Save to Downloads" | "Save to Files" on both platforms | Round 1's option (b), which matches `cinematic/DESIGN.md` §8.23 |

MOBILE-24 also changed after round 1. The full player's header ⋯ was a `glassThin` 32 button in the judge's fix, and it is now a `fill2` twin circle 32 (l. 2838). This follows §2.4.2 rule 7 ("no glass on glass"): a control drawn on the full player, which is a glass surface, is the content twin of its variant, with the same shape and size. The ⋯ is still the one the judge placed, so this is not a regression.

---

## Old values that must be gone (live-file grep counts)

| Old value | Count |
|---|---|
| `PredictiveBackPageTransitionsBuilder` in use | 0. The one hit is the "is not used, because it falls back to `FadeForwardsPageTransitionsBuilder`" sentence (§8.0.5, l. 2247). |
| 621 ms | 0 |
| "a back swipe during a push grabs the incoming page" | 0 |
| "long-press tooltip(s)" | 0 |
| "above `xxxL`" as a rule | 0. The hits are the §3.3 table row (l. 941) and the "This replaces category names such as 'above `xxxL`'" clause (l. 950). |
| "`wakelock_plus` keeps the screen on" | 0 |
| "swiping the stack left" / §11 row "Swipe the Continue stack left" | 0 / 0 |
| gyroscope or "rotation rate" as the tilt method | 0. The one hit is the clause "never the gyroscope (integrated rotation rate drifts and pins at its clamp)" (§2.4.2 rule 5, l. 402). |
| "Android has no public high-contrast signal" | 0 |
| "download notifications through `audio_service`" | 0 |
| "and as a trailing icon on the mini player" | 0 |
| "the reader's ⋯" | 0 |
| `WRITE_EXTERNAL_STORAGE` | 0 |
| "starts at x ≥ 24" (the brightness band) | 0 |
| "Read this card" / the Wrapped `f ≥ 1.35` rule | 0 / 0. The three "1.35" hits are the §3.3 xxxL factor, the §7.2 pressed-growth cap and Step into the light's 1.35 inflate, none of them the old rule. |
| **Round 2:** "Save to Downloads" / "Saving to Downloads" | 0 / 0 |
| **Round 2:** the Android sheet-title exception ("On Android the sheet's title reads …") | 0 |
| **Round 2:** the iOS export path `ManhwaManiacs/{series}/` (without `Exports`) | 0 |
| **Round 2:** guided view listed under the "Previous · Menu · Next" tap bands | 0. §11 l. 3852 now lists only manga paged and novel paged. |
| `topBorderRadius` (the judge's `GlassModalSheet` wording, superseded by `smooth_sheets`) | 0 |

---

## Per finding

| ID | Verdict | Evidence (live file) |
|---|---|---|
| MOBILE-1 | Resolved | **§8.0.5 Android row** (l. 2243): `MaterialPage` with `GlassPageTransitionsBuilder`, and "FadeForwards never plays in Glass". **"The Android page transition"** (l. 2247–2252) holds the whole fix: <br>- the file path and registration for `TargetPlatform.android`; <br>- the copied `_PredictiveBackGestureDetector` (BSD-3), forwarding the four `handle*BackGesture` calls; <br>- the `GlassPushTransition` slide: 100 % → 0, outgoing 0 → −30 % under `#000000` going 0 → 0.30, 615 ms on `springPage` (k 146.0, c 24.17); <br>- the predictive geometry: 0.90 scale, `screenWidth / 20 − 8`, the y clamp ±`(height / 20 − 8)`, radius 0 → 36 through `ClipRSuperellipse`, the T4 rim (0.5 px, `S` 0.30) and the T4 shadow `0 24px 64px rgba(0,0,0,0.60)`; <br>- the SDK commit/cancel mapping, with "no spring hand-off". <br>**§15.3:** l. 4202 (`glass_skin.dart` registers the builder) and l. 4210 (`transitions/glass_page_transitions.dart`). <br>**Repeats agree:** the §4.10 Pop row (l. 1199, "Android predictive back: driven by back progress, no velocity"), §8.14.11 Android ("scales the reader to 90 % as a glass card") and §11 Back swipe ("shrinks to 90 %"). |
| MOBILE-2 | Resolved | **§8.0.5 iOS row** (l. 2242) uses `GlassSwipePage`. **"The iOS route"** (l. 2254–2260) is the MIT fork of 0.4.8 with its three changes: <br>- 615 ms `GlassPushTransition`; <br>- `animateWith(SpringSimulation(...))` at `velocityX / width`, with `springDismiss` → 0 and `springSettle` → 1 (both are defined Flutter names, l. 801–803); <br>- the full width kept, and readers on 20 px. <br>**§4.9:** the `committed` row (l. 1175) ends "a route push or pop is never caught". The first bullet (l. 1179) carries the judge's amendment. **§4.10:** the Catch row (l. 1222) says "never a route push or pop". **§15.3** l. 4203, 4211 and 4230 (the Packages line: "kept for Cinematic; Glass uses the vendored `GlassSwipePage` fork"). **§15.11** l. 4452: "vendored route, forked from 0.4.8". |
| MOBILE-3 | Resolved | **"Android back order"** (l. 2262–2277): rules 1 to 10 in the fix's order, plus the `PopScope(canPop: false, onPopInvokedWithResult:)` sentence. **"Takeovers on Android back"** (l. 2279–2285): all five cases, including onboarding step 1 leaving the app, with "never skips to Home" and its reason (§8.7 Resume). "Who owns a horizontal drag" (l. 2287) says "Android back follows the takeover rules above". |
| MOBILE-4 | Resolved | **§8.14.2 "Nothing beneath"** (l. 2624) matches the judge's text. **§8.15.3 "Nothing beneath"** (l. 2783) sends back to the book page by `content_kind`. **§8.16.2 System media controls** (l. 2848): `/novels/:sourceId/:seriesKey/:chapterKey?listen=1`, pushed over the stack, or the first route on a cold start. **§8.0.4 Reader → back** (l. 2231) points to the rule. |
| MOBILE-5 | Resolved | **§8.14.11 "Reader system UI"** (l. 2722–2726): <br>- **Mode:** `immersiveSticky` on both platforms, `edgeToEdge` on exit, and the iOS home indicator auto-hides. <br>- **Insets:** iOS `viewPaddingOf`; Android `mm/platform` `display.stableInsets` = `getInsetsIgnoringVisibility(systemBars() \| displayCutout())` / density. <br>- **Positions:** top groups at `inset.top + 8`; edges at `max(inset.left/right, 16)`; the five bottom elements at `max(inset.bottom, systemGestureInsetsOf.bottom) + 16`; the hairline at `inset.top`. <br>- **Cutout:** `SHORT_EDGES`. <br>**Repeats agree:** §8.0.7 "Readers (phones)" and its Android line (l. 2318, 2320), the §8.14.2 bottom capsule, the §8.15.3 hairline, and §15.3 Native `display.stableInsets` (l. 4239). |
| MOBILE-6 | Resolved | **§8.0.1** (l. 2144) and **§8.14.11 "Landscape phone"** (l. 2729–2734) hold the full layout. <br>- **Manga:** 40 % title; the page capsule and bookmark, settings and ⋯ top-right (the ⋯ holds Download, Cruise, Guided view, Previous and Next); a 44 px bottom scrub rail with a 3 px track, 12 px thumb, 120 × 164 magnifier, 2 px read-all gaps and the cruise pill above its trailing end. <br>- **Novel:** centred measure; bookmark, listen, Aa and ⋯ (Voices and Soundscape inside); the bottom capsule stays; a 320 px listen row. <br>- **Sheets:** height − safe-top − 10 and `min(560, width − 16)`. <br>The page readout stays top-right, as the judge required. |
| MOBILE-7 | Resolved (the Wrapped half superseded by the a11y fix) | **§3.3 "Rules at large sizes"** (l. 950–962): rule 1 defines `f` (1.6 / 1.9 and "replaces category names"); rule 2 has the height minimums with the exact `padV` list; rule 3 the 1.5 clamp; rule 4 the 1.3 clamp, with cruise and download moving at `f > 1.3`. Rule 5 is the a11y judge's reflowing column at `f ≥ 1.3`, repeated in §9.2.3 **Large text** (l. 3346) and §14.7 (l. 4052), which points to §3.3's rules. No trace of "Read this card" is left. |
| MOBILE-8 | Resolved | **§3.3** (l. 929): at `f ≥ 1.6` the dock labels move to semantics only, the dock shows no tooltip, and each tab menu gains a `headline` header row. **§7.15 Long-press a tab** (l. 1800) says the same. "Long-press tooltips" gets 0 hits. |
| MOBILE-9 | Resolved | **§7.10 "The on-screen keyboard"** (l. 1747–1751): <br>- focus moves the sheet to `large` on `sheetSnap`, through the sheet route's own `Focus` listener (§15.3 Sheets *Keyboard*, l. 4237), with `GlassModalSheet` cited only as the same behaviour; <br>- `ensureVisible(alignment: 0.3)`; <br>- `viewInsetsOf` bottom padding; <br>- capsule popovers rise on `snappy`. <br>**§7.15** (l. 1802): the dock, orb and accessory leave and return on `minimize` by their height + safe-bottom; `ScrollViewKeyboardDismissBehavior.onDrag`; `adjustResize` kept. |
| MOBILE-10 | **Resolved** (round 2) | **The fix:** §8.22 Save to Files (phones) (l. 2959) keeps every element of the judge's fix: <br>- `mm/media` `saveDownload(relativePath, name, mime, path)`; <br>- `RELATIVE_PATH = "Download/ManhwaManiacs/Exports/{series}/"` on API 29+, with no permission; <br>- the result "Saved to Download/ManhwaManiacs/Exports/Solo Leveling"; <br>- on API 24–28, the app-documents export with "Share"; <br>- "No storage permission is declared". <br>The Android "Where it lives" copy is in the Chapters tab (l. 2955). <br>**Round-1 contradiction closed (option b):** <br>- the Android note now ends "use Save to Files." and says the flow is named Save to Files on both platforms, as in Cinematic §8.23; <br>- the Android sheet-title exception is gone; <br>- a closing sentence names every label (series ⋯, chapter row, §7.29 menu, sheet title, progress alert, error toast) as "Save to Files". <br>**Every entry point checked:** series ⋯ "Save to Files…" (l. 2955), chapter row "Save to Files (phones)" (l. 2955), §7.29 "Save to Files on phones" (l. 1993), the §8.0.3 `save-files` label (l. 2213), "Saving to Files…" and "Couldn't save to Files." (l. 2959), and Appendix B (l. 4583). No Android-only name is left anywhere. <br>**O8 applied:** iOS now writes to Documents `Exports/{series}/` (On My iPhone → ManhwaManiacs → Exports → {series}), the folder Cinematic §8.23 uses, so "one app has one folder" holds on both platforms. This does not conflict with the Storage tab's iOS note ("On My iPhone → ManhwaManiacs", l. 2957), which names the parent folder. See observation N1 for the result-alert wording. |
| MOBILE-11 | Resolved | **§9.2.4 "Phone share flow"** (l. 3363–3368) has all five bullets: <br>- `sharePositionOrigin`; <br>- iOS `SaveToCameraRoll` → "Saved to Photos", otherwise "Shared", a dismissal silent, and `NSPhotoLibraryAddUsageDescription` referenced from Cinematic §9.2.5; <br>- Android API 29+ `MediaStore.Images` at `Pictures/ManhwaManiacs` through `mm/media`, with a toast; <br>- Save image hidden on API 24–28; <br>- Android Share "Shared" or silent. <br>The flow strip's Save image button and the States list agree. §7.31 (l. 2006) and the §8.14.3 page menu (l. 2642) point to the flow. `share_plus` is 12.0.2 in §9.2.4, §15.3 and §15.11. |
| MOBILE-12 | Resolved | **§5.1 "One Android haptic rule"** (l. 1384–1389): <br>- literal intensities use the table constants (API 34+, `CONFIRM`/`REJECT` 30+); <br>- only `throw.commit`, `motion.catch` and the velocity-scaled catches and throws use `createOneShot(12, round(i × 255))` through `haptics.oneShot`; <br>- `nav.push` plays gaimon's `rise{d}` conversion; <br>- `VIBRATE` is declared; <br>- `haptics.systemEnabled` gates every vibrator-path pattern. <br>**Repeats agree:** §5.2 `nav.push` = `ahap:rise{d}` (l. 1404), and §15.3 Native gates the constants at 34 / 30 / 26 and lists `haptics.systemEnabled` (l. 4239). |
| MOBILE-13 | Resolved | **§7.33 Where** (l. 2018–2027) has the one list and the "No pull to refresh" list. **§11 "Pull down at the top"** (l. 3840) points to it with the same members. The per-screen Gestures lines agree: Home l. 2517, Sources l. 2544, catalogue l. 2557, Library l. 2890, History l. 2921, Updates l. 2946, and Downloads "No pull to refresh" l. 2953. |
| MOBILE-14 | Resolved | **§7.7 Continue stack** (l. 1688): no horizontal swipe. "Previously on" is reached through the first long-press row, a trailing ⋯ with a 44 px hit area, and `p`. **Also agree:** §8.8 Gestures (l. 2517), §9.1.3 Explicit entries (l. 3216), and §7.34 Where (l. 2035: For you's vertical lists on phones only; AI cards in Home rails take no swipe). **§11:** the Continue-stack row is deleted, and "Swipe a row left or right" (l. 3841) lists "For you answer and section cards (phones)". |
| MOBILE-15 | **Resolved** (round 2) | **The fix:** <br>- §8.14.3 Double tap (l. 2634): centre-band-only recognition in paged mode and with "Tap to scroll"; side bands act at once; a centre-band chrome toggle reverts within 280 ms / 24 px before the `camera` zoom. <br>- §9.4.3 Double tap bullet (l. 3482): guided view's centre band has no single-tap action, so it needs no revert. The Counter bullet (l. 3481) says "in the centre band". <br>- §4.6 Double tap (l. 1122) keeps "single taps are never delayed". <br>**Round-1 contradiction closed:** §11 "Tap bands" is split. Manga paged and novel paged keep "Previous · Menu · Next" (l. 3852). The new row "Tap bands / Guided view" (l. 3853) reads "Previous panel · (none) · Next panel (30 / 40 / 30)", with no single-tap action and no chrome toggle in the centre. The §11 Double tap row (l. 3854) adds that guided view's centre double tap shows the whole page for 1.5 s and has nothing to revert. This matches §9.4.3 Camera ("one tap on the side bands (right 30 % next, left 30 % previous)") and the Swipe horizontally row (l. 3863, "the side bands"). No other text gives guided view a Menu band. Every §11 row still has 7 cells. |
| MOBILE-16 | Resolved | **§6 "In the background"** (l. 1565–1571): narration through `audio_service` (iOS `UIBackgroundModes audio`, Android `mediaPlayback`); the soundscape ducked 12 dB under narration (or paused with "Lower under narration" off), following the 8 s sleep fade; otherwise a 1.5 s fade on `paused` and resume on `resumed`; UI sounds never; shake to extend in the foreground only. **Repeats agree:** §8.16.6 carries the caption "Works while ManhwaManiacs is open.", and §9.4.2 Mixing rules say the same. |
| MOBILE-17 | Resolved | **§8.14.5 "Keep screen awake"** (l. 2670–2675): the switch holds the wakelock while a reader is in the foreground (default off, per profile, seeded from K05); it is always on during cruise or guided view; it is released on leaving the reader, on `paused`, and 2 s after cruise stops; narration does not hold it. **Repeats agree:** §8.14.11 iOS (l. 2727), §8.15.5 Screen (l. 2808), §9.4.1 (l. 3448) and the §8.25.3 K05 row (l. 3040). |
| MOBILE-18 | Resolved | **§2.3 `rSheet`** (l. 319): on iOS phones `GlassThemeHelpers.resolveAdaptiveRadius(context)` gives 46 / 54, falls back to 36 on Home-button phones, and is read once per launch. Android, tablets and web use 36. No channel method and no private API. **Repeats agree:** shape rule 3 (46 → 30 → 26), §2.8.3 `radius.sheet` (l. 729), and §15.3 Sheets *Driven values* (l. 4235, on `smooth_sheets`, a sanctioned change). |
| MOBILE-19 | Resolved | **§8.14.4 "Saving the next chapter"** (l. 2654): cites Cinematic §8.14.11 (verified at Cinematic l. 2380), with the full condition and skip list, and no toast or haptic. **§8.22 Storage tab** (l. 2957) has the three switches with Cinematic's scopes and defaults. High refresh rate is unchanged, as the fix says. |
| MOBILE-20 | Resolved | **§8.0.8 "Device OCR engine"** (l. 2344) defines `ocrEngineAvailable`. "Extract text" is gated in §7.29 (l. 1993), §8.22 (l. 2955), §8.14.9 (l. 2701) and §9.1.3 (l. 3232). The §8.23 hint row has the false-engine copy (l. 2976). |
| MOBILE-21 | Resolved | **§12.6** (l. 3939): "the narration lock-screen and media notification through `audio_service` 0.18.19; downloads post no notification". |
| MOBILE-22 | Resolved | **§2.4.2 rule 5** (l. 402) matches the fix: accelerometer at 33 ms, α 0.15, the pose captured at screen entry, the light-angle formula, ±6° hero tilt, 1 g = 400 px/s², and web `DeviceOrientationEvent`. Every tilt consumer points to rule 5, including §8.14.4, §8.16.2 and §11 Tilt. §15.3 Packages says "accelerometer only". |
| MOBILE-23 | Resolved | **§4.11** (l. 1316–1317): `a11y.reduceTransparency` plus a change stream; Android 14+ `a11y.contrastLevel` at ≥ 0.5, OR-ed with the in-app switch; "older Android relies on the in-app switch". **Repeats agree:** §8.25.1 (l. 3004) and §15.3 Native (l. 4239). |
| MOBILE-24 | Resolved | **§8.16.2 Header ⋯** (l. 2838) holds Save audio and Soundscape and is "the player's ⋯" (now a `fill2` twin per §2.4.2 rule 7; see above). **§8.16.1** has no save icon. **§9.1.3** (l. 3216): manga uses title capsule → series sheet; novel uses the Contents-sheet row, and §8.15.6 has that row. **§8.15.3 top-right** is four icons, with the Aa dot badge and the "Type and page, soundscape playing" name. §9.4.2 Entry and §7.10 (l. 1735) cite "the listen player's ⋯". |
| MOBILE-25 | Resolved | **§8.29 App update (Android APK)** (l. 3160): external-browser download (`LaunchMode.externalApplication`); the "Install the update" alert with its three droplets and "Got it"; a resume re-check at most every 15 min; the hook's move out of `whats_new_auto_show.dart` in a no-pixel commit before the flip. |
| MOBILE-26 | Resolved | **§8.14.3** (l. 2638): iOS x ∈ [24, 24 + 0.12 W] (24–71 px on 390); Android x ∈ [0, 0.12 W] with only its middle 200 dp excluded; ownership at `abs(dy) > 2 × abs(dx)` after 10 px; portrait only. **Repeats agree:** §11 (l. 3860) and §8.0.5 (l. 2287). |
| MOBILE-27 | Resolved (copy per the product table) | **§8.4 Fields** (l. 2436): the Cinematic helper and backend pattern, checked live. **Validation** (l. 2437): the enabling rule, the on-blur password and email checks, and `errorRing` + 6 px shake + `error` haptic. The per-code table covers `weak_password`, `invalid_username`, `invite_code_required` and `invite_code_invalid`. |

---

## Unresolved

None.

---

## Observations (not blocking; outside the final fixes)

### New in round 2

- **N1 (MOBILE-10 wording).** §8.22 (l. 2959) states the result alert twice:
  - generally, as "Saved to Files · 12 chapters · 480 pages" with the selectable path;
  - for Android, as "the result alert reads 'Saved to Download/ManhwaManiacs/Exports/Solo Leveling'".

  The Chapters-tab note ("only its result path says where an Android copy landed") shows the intent: the heading stays "Saved to Files · …" and the Android path line is `Download/ManhwaManiacs/Exports/Solo Leveling`, as in Cinematic §8.23 (heading plus path). One wording change makes this literal: "…and the result alert's path line reads 'Download/ManhwaManiacs/Exports/Solo Leveling'".
- **N2 (MOBILE-15 edge case).** Paged tap bands are configurable ("each band configurable (Previous · Menu · Next)", §8.14.3 l. 2632, and the Taps row l. 2664). The double-tap rule is tied to "the centre band". If a reader sets the centre band to Next, the first tap turns the page and the second zooms a different page, which is the defect MOBILE-15 fixed. A clause in §8.14.3 would close it: "a double tap is recognised only in a band whose action is Menu (the centre band by default)".
- **N3 (MOBILE-15, RTL).** The new §11 guided-view row says its side bands are "mirrored for RTL". §9.4.3 Camera mirrors only the swipe and states the bands without a mirror ("right 30 % next, left 30 % previous"). The two readings agree in spirit, but §9.4.3 could add "mirrored for right-to-left" after the bands.
- **N4 (MOBILE-20 neighbour).** On a phone where `ocrEngineAvailable` is false, the recap's "How it works" sheet line 2 still says "Your phone reads the speech bubbles…" (§9.1.3, l. 3235). This extends round-1 observation O4.

### Carried from round 1, still present

- **O1:** in the phone readers, toasts sit at "safe-top + 60" (§7.12, l. 1765). On Android in `immersiveSticky`, `viewPadding.top` is 0, so a toast lands over the top groups. A fix: "inside the phone readers: `inset.top` + 60 (§8.14.11)".
- **O2:** §7.12 (l. 1764) still uses a category name, "from text scale AX1". It should read "from `f ≥ 1.6`" (§3.3 rule 1).
- **O3:** §7.27 (l. 1964) still lists "dock" among the 150 ms tooltip delays. This is pointer and focus only, so it does not clash with MOBILE-8.
- **O4:** the §9.1.3 "no source text" body still says "Extract text from downloaded chapters" when the engine is missing (l. 3232).
- **O5:** the §11 "Long-press text" alternative (l. 3859) names "the chapter's ⋯". The portrait novel reader has no ⋯.
- **O6:** the landscape novel reader gives no touch path to cruise. Only `a` reaches it, and its ⋯ holds only Voices and Soundscape.
- **O7:** the §8.22 "Device-wide" list (l. 2962) omits "Download on Wi-Fi only" (K20, a device value), so that row lacks the "For everyone on this device" caption.
- **O8:** applied in round 2. See MOBILE-10.
