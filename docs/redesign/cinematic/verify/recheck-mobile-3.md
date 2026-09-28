# Cinematic DESIGN.md: mobile lens, recheck round 3

Input: the 28 findings in the "Confirmed" section of `cinematic/verify/judge-mobile.md`, checked against `cinematic/DESIGN.md` as it stood on 2026-09-28 at about 23:05 UTC (4,657 lines, last written 23:03). Line numbers may drift, so each item also names its section. Round 2 (`recheck-mobile-2.md`) left only MOBILE-6 open, on the web half of the scrims. `fixed-mobile.md` "Round 3" lists the edits made since then. For every finding I re-read the sections its final fix names. I grepped for wording that should be gone and for every other place a changed value is repeated. I also re-checked the 27 findings already resolved, because other lenses are still editing the file.

**Result: 27 resolved, 1 unresolved (MOBILE-6).** The round-2 defect is fixed. Each gradient now lives in its `@utility`, so every `var()` resolves on the element that paints it. The stop arithmetic is correct on both clients. One defect remains: the `scrim.sole` row never says that its host has to be positioned, although the `scrim.head` row does. The Listen transport is an in-flow element "under the transcript" (§8.16.3). If it is built exactly as the row says, the scrim covers the whole full player instead of the transport. The fix is one clause.

As in rounds 1 and 2, two final fixes were superseded by other lenses, and DESIGN.md follows the newer fix in both cases:
- MOBILE-1's release curve follows STACK-28. It is the package's `Curves.fastLinearToSlowEaseIn` (§8.0.5 Back row and "Route transitions in the app").
- MOBILE-2's tablet wipe follows CONSISTENCY-11: 744 ms (§8.14.2).

MOBILE-8 also has a later refinement from another lens. The opening size is now `scale(d)` for the face's default size `d` instead of a literal 18. §3.3, §8.15.5 and §14.7 all agree on it: 36 px in Newsreader and 34 px in Archivo at system 2.0.

---

## Unresolved

### MOBILE-6: `scrim.sole` never requires a positioned host, and the Listen transport is not one

**What round 3 got right.** I checked each of these directly:
- **No `[data-skin]` property.** `--mm-scrim-head`, `--mm-scrim-sole`, `--mm-scrim-foot` and `--scrim-bar` appear nowhere. §2.8 (l. 337) explains why these three keys exist only as utilities.
- **Utilities.** The `@utility scrim-head` and `@utility scrim-sole` rows (§2.8.3 l. 493–494) hold the whole gradient and read `var(--scrim-fade)` on the `::before` itself. The `::before` inherits the unregistered `--scrim-fade` from the bar.
- **`content`.** The installed Tailwind (`frontend/node_modules/tailwindcss` 4.3.2) wraps `before:` as `&::before { content: var(--tw-content); … }`, so `before:scrim-head` generates a box.
- **Fade values.** `--scrim-fade` now has values: `[--scrim-fade:44px] frame:[--scrim-fade:64px]` on the running head, where `frame:` is `--breakpoint-frame: 48rem` (§2.8 `bp.frame`, l. 455), and 64 px on the folio bar and the Listen transport.
- **Stops.** The web head stop at `calc(100% − kScrimStops[i] × fade)` with alpha `.88 × kScrimAlpha[i]` (i = 12 → 0) puts .88 at the bar's bottom edge. It runs to 0 at the fade's end, and the stop positions ascend. The ramp measured from the transparent end matches §2.1.4's table. The Flutter stops `b + (1 − kScrimStops[i]) × f` give the same distance from the transparent end, `kScrimStops[i] × f`. Both lists have 15 entries, and the stop and colour counts match. `Color(0xE0000000)` is .878 and `Color(0xE6000000)` is .902.
- **`scrim.sole` direction.** The utility's `to top` gradient and `inset: calc(-1 * var(--scrim-fade)) 0 0 0` mirror the head correctly. Flutter's `Positioned(top: -fade, left: 0, right: 0, bottom: 0)` also mirrors it (the round-2 note is applied).
- **`scrim.foot`.** `color-mix(in srgb, var(--amb-tint) p%, transparent)` is valid at p = 0 and yields the tint at alpha p. `--amb-tint` is a registered, inheriting `<color>` with an initial value, and `--scrim-solid-at` has a `100%` fallback, so this utility can never compute to `none`.
- **Tests.** §15.7 (l. 4422) now asserts that the computed `background-image` of each scrim `::before` is not `none`. This catches a missing `--scrim-fade`.
- **No stale wording.** "safe area + 88 px (phone)" and "bottom 128 px + safe area" are gone. §2.1.4 (l. 110–111) and §2.8.3 give the same geometry: 120 px desktop, bar + 44 px on phones (min safe area + 88, 92 on Android), and bar + 64 px for the sole (min 128 + bottom inset).

**The defect.** Both utilities set `position: absolute` and an `inset` on the `::before`. An absolutely positioned box resolves `inset` against its nearest *positioned* ancestor. `isolation: isolate` creates a stacking context but not a containing block.
- The `scrim.head` row (l. 493) states the requirement: "The bar (positioned: `fixed`, `sticky` or `relative`) sets `isolation: isolate` …".
- The `scrim.sole` row (l. 494) says only "The folio bar and the Listen transport set `isolation: isolate` and `--scrim-fade: 64px`".

The reader folio bar sits in the fixed reader chrome overlay (§2.1.5 l. 178), so it is presumably positioned anyway. The Listen full player's transport is not. §8.16.3 (l. 2541) places it "Under the transcript", in the takeover's column, with the tiles below it.

If the transport is built exactly as the row says, three things follow:
1. **Wrong geometry.** The `::before`'s containing block becomes the takeover, which is fixed. The scrim then spans the whole player plus 64 px above it, and its flat .90 part covers everything from the takeover's bottom edge up to its top.
2. **Wrong layer.** A non-positioned element with `isolation: isolate` is painted as a positioned element at z-index 0, after in-flow content. Its `z-index: -1` child therefore paints above the head and the transcript, which leaves them at about 10 % visibility.
3. **The test misses it.** §15.7's "`background-image` is not `none`" check passes, so nothing catches the failure.

**Fix (§2.8.3 `scrim.sole` row, web column):** "The bar is positioned (the folio bar `absolute` or `fixed` in the reader chrome overlay; the Listen transport `relative`) and sets `isolation: isolate` and `--scrim-fade: 64px`." A matching test clause for §15.7 would read: "and the `::before`'s bounding box is the bar's box extended by `--scrim-fade`". That clause catches a wrong containing block on either bar.

---

## Resolved

| ID | Where it now lives | Checked |
|---|---|---|
| MOBILE-1 | §8.0.5 Back row (l. 1672), "Route transitions in the app" (l. 1682–1686), §15.3 `router.dart` and `transitions.dart` rows (l. 4348–4349) | Page 320 / 224 ms, match cut 480 / 336 ms with `transitionOnUserGestures: defaultTargetPlatform == TargetPlatform.iOS`. iOS `SwipeablePage`, edge-only, 20 pt, with the builder switched by `isSwipeGesture` and the page beneath reading `userGestureInProgress`. Android `CinePageTransitionsBuilder` copies `_PredictiveBackGestureDetector` with the fade-through values and 240 / 160 ms commit and cancel; `CineMatchCutPage`. `ZoomPageTransitionsBuilder` and `PredictiveBackFullscreenPageTransitionsBuilder` appear only as "never ship". Release curve per STACK-28. |
| MOBILE-2 | §8.14.2 route, Exit, back target, iOS edge swipe, Android (l. 2180–2186); §8.15.8 Gestures; §11 Edge swipe back (l. 4045) | One `SwipeablePage` with `{entry: 'wipe' \| 'dip'}` in `extra`. 616 / 744 / 872 ms from the blade formula, 440 ms for `dip`, reverse 440 ms. The builder paints blades only on forward, the Dip on a non-swipe reverse, and the slide while `isSwipeGesture` is true. Back target: `canPop` → pop, else `go('/sources/:sourceId/series/:seriesKey')` by Dip, with Android `PopScope(canPop: context.canPop(), …)`. `canSwipe` is on only on iOS, in strip or novel scroll, at zoom ≤ 1.0, with guided view off. |
| MOBILE-3 | §11 "Precedence between horizontal gestures" (l. 3998), §8.0.5 Edge swipes row (l. 1680), §11 Contents tabs row (l. 4027), §7.16 | Rows win in the arena; web rows use `touch-action: pan-y`; nested contents tabs switch by tap only (`NeverScrollableScrollPhysics`). The strip chapter swipe needs zoom ≤ 1.0, a start at max(24 px, `systemGestureInsetsOf`) from both edges, and a drag within 30°. |
| MOBILE-4 | §6 "Audio session and focus policy" (l. 984–988), §9.4.2 Playback (l. 3528) | States A, B and Voice sample; `handleAudioSessionActivation: false`; the startup `configureNovelAudioSession()` is replaced by State A. "Mixes with other audio at its own volume, never ducking or stopping it". "stops when other audio starts" is gone. |
| MOBILE-5 | §8.0.3 Shell branches (l. 1631–1644), §8.28 Transitions, §8.10 Transitions, §8.33.3 | Every route has a branch, and the push / `go` / declaration-order rules are present. §8.28 pushes branch-4 destinations with Page and `go`es cross-branch with the §8.0.4 section change. §8.10's `Read updates` is `go('/updates')`. "Page to each destination" is gone. The round-2 note is applied: §8.33.3 now hides the banner only "on Updates or in the manga reader", which agrees with its own last sentence and with §8.10. |
| MOBILE-6 | §3.3, §7 intro, §7.1 `split`, §7.13, §7.14, §8.14.3, §8.17, §2.1.4, §2.8, §2.8.3, §15.7 | Text, the Flutter scrims and the web gradients are all correct. **The `scrim.sole` host is not required to be positioned (above).** |
| MOBILE-7 | §3.3 "Literal sizes" (l. 650–658), §7.14 Badges (l. 1314) | One cap per face through `CineType.literal`. Counts and badges cap at 1.3 with a box growing from min 16. Dialogue subtitles cap at 1.3, two lines at most. |
| MOBILE-8 | §3.3 (l. 644), §8.15.5 Size (l. 2444), §14.7 (l. 4195) | `TextScaler.noScaling`, absolute 14–40, opening size `clamp(round(textScalerOf(context).scale(d)), 14, 40)` stored per book (the face-default refinement above). "independent of this cap" is gone. |
| MOBILE-9 | §2.2.2 "Horizontal safe areas" (l. 258), §8.0.9, §8.14.1 (l. 2167) | App `viewPaddingOf` + 8 and web `env(safe-area-inset-left)` + 8. Bars inset their content while their grounds bleed. Readers are centred in the safe rectangle. |
| MOBILE-10 | §8.14.1 Landscape phone (l. 2167) | Both bars hidden at rest and shown together on a centre tap; 44 / 48 + inset; back plus four trailing buttons. "folio bar only on tap" is gone. |
| MOBILE-11 | §8.0.5 System bars (l. 1673), §8.14.3, §8.15.3 | iOS `manual` with `overlays: []`, Android `immersiveSticky`. `overlays: [SystemUiOverlay.top]` with the 240 / 160 ms chrome. Exit is `edgeToEdge` with transparent bars and `systemNavigationBarContrastEnforced: false`. |
| MOBILE-12 | §8.19 (l. 2686), §8.23 Activity (l. 2783) | The note and "Paused while the app is in the background." show on both OSes, with "background (app)" ×2. The only "(iOS)" left is the About row's SideStore card, which is correct. |
| MOBILE-13 | §8.16.2 "Following along on the page" (l. 2514–2529) | `spot.wash` band at 200 ms `set`, stepped 2 px underline, tint backgrounds dropped, 38 % hold inside the 20–70 % band with a 400 ms `ease.settle` scroll, `Back to the voice ↓`, 4000 ms re-follow, reduced motion. |
| MOBILE-14 | §9.2.5 (l. 3374–3376) | `NSPhotoLibraryAddUsageDescription` with the exact string. Android 29+ uses `MediaStore`, `Pictures/ManhwaManiacs` and `mm/media`. The button is hidden on API 24–28. |
| MOBILE-15 | §11 Pull row (l. 4036), §8.11 (l. 2740), §8.21, §9.1.3 (l. 3140) | Sources (`GET /sources`, `GET /sources/pins`), Collections and the collection detail, and Picks (`GET /library/world/recommendations`, `GET /library/suggest/availability`, never re-asking the AI). |
| MOBILE-16 | §12.3 (l. 4074), §8.30.3 (l. 2947, 2958, 2965), §8.32 | `setAlternateIconName` with empty blacklists, with the alias applied on task removal. `setComponentEnabledSetting` appears only as "not added". The new confirm line is in place, and `AppRestart.of(context).restart()` is used everywhere. `AppRestart.restart()` and "being replaced anyway" are gone. |
| MOBILE-17 | §8.0.5 "Back inside modal states" (l. 1689–1697), §11 Edge swipe back | Android order 1–5; the Switch-profile picker is a pushed takeover; iOS `PopScope(canPop: false)` for states 1–4, while the picker keeps its swipe. |
| MOBILE-18 | §8.14.11 (l. 2380), §8.23 STORAGE (l. 2788), §15.4 | Trigger, skips, no toast or haptic, the Downloads badge and `SAVED`, and a per-profile switch that defaults to on. The heading reads "an existing engine duty, extended here". |
| MOBILE-19 | §8.9 Phone layout (l. 2046), Tag sheet (l. 2038) | `TAGS` checklist hidden when empty, `Manage tags…` as its last row, removable tokens, and the active-filter count on `Filters`. |
| MOBILE-20 | §8.14.8 (l. 2315) | Copies K01–K03, K06 and K09–K12; K04, K05, K07 and K08 stay device keys. "K01–K12" appears only as "device-wide today". |
| MOBILE-21 | §7.13 Height (l. 1288), §2.1.4 and §2.8.3 `scrim.head`, §7 intro (l. 996), §7.1 `quiet` and `primary` sm, §7.2 `on-art` and `ruled` (l. 1052–1053), §8.0.1 (l. 1585), §8.14.3 chapter folio (l. 2192), §9.1.5 (l. 3182) | Android running head 48 + inset. Every "44 hit" reads 44 / 48 (`hitMin` / `hitAndroid`). The `scrim.head` flat part follows the measured bar, so Android's 48 px sits on the .88 ground. |
| MOBILE-22 | §7.14 Cell (l. 1311), §7.1 `play` (l. 1031), §8.16.3 Transport (l. 2541), §7.7 Below | Icon 24. `play` is 64 (desktop, tablet) / 56 (phones) / 36 (mini), which matches "56 px play". The Below caption is `type.title` with no literal 14/20 (the remaining "14/20" are `type.ui` and `type.label` breakpoint sizes). |
| MOBILE-23 | §7.16 (l. 1382), §11, §15.3, §15.11 | `flutter_slidable` and `Slidable` appear nowhere. `Dismissible(direction: DismissDirection.endToStart, dismissThresholds: {…: 0.5})` with the 72 px slab, and `Mark read` through `confirmDismiss` returning false. |
| MOBILE-24 | §3.1 "OS bold text" (l. 583), §14.4 (l. 4165), §14.7 | +120 `wght` with per-face clamps, `fontWeight` to the nearest hundred, Plex Mono at 600. `highContrastOf` maps `ink.45` → `ink.80` and `rule.1` → `rule.2`. No "+150" is left. |
| MOBILE-25 | §8.14.5 (l. 2236), §8.14.8 (l. 2289), §8.14.10 (l. 2353–2354), §11 (l. 4011, 4025) | Resting zoom comes from the stepper. Strip pinch runs 0.5–3.0× with a 0.1 snap. Double tap goes resting ⇄ min(2 × resting, 3.0)×. Paged is 1–3× with 1 ⇄ 2×. |
| MOBILE-26 | §8.15.6 (l. 2470) | From the book page it is a standard §7.9 sheet (`paper.2`, `rule.2` top edge, `spot.wash` current row); inside the reader it uses the stock colours. |
| MOBILE-27 | §8.30.2 row 12 (l. 2922) | "Keyboard (web; app on tablets, `MediaQuery.sizeOf(context).shortestSide ≥ 600`, iPad and Android)". "(web, iPad)" is gone. |
| MOBILE-28 | §9.2.4 Frame, phone (l. 3340) | Full bleed with a centred 9:16 safe box. Segments at `viewPadding.top + 8` with 16 px margins. The close `x` has a 44 / 48 hit and sits 8 px under the segments. The tap thirds skip the top `viewPadding.top + 64` px and the bottom `viewPadding.bottom + 48` px. |

## Notes (not blocking, outside the MOBILE findings)

- **The page tint never reaches the scrims (predates round 3; `fixed-mobile.md` records it as left for another lens).** Three places say the page tint mixes into the ends of `scrim.head` and `scrim.sole`:
  - §2.1.4 (l. 118): "The §9.4.4 page-tint mix (25 % of `page.tint`) still applies to the end colours of `scrim.head` and `scrim.sole`";
  - §8.14.3 (l. 2215);
  - §9.4.4 (l. 3552).

  The §2.8.3 web utilities hard-code `rgb(0 0 0/…)`, and the Flutter fields hard-code `Color(0xE0000000)` / `Color(0xFF000000)`. The committed version had the same gap. Because the gradient now lives in the utility, and `--page-tint` is written on the reader chrome root that holds these `::before`s (§2.1.5 l. 178), the web can now read it:
  - web: `color-mix(in srgb, var(--page-tint) 25%, #000)` at the stop alpha;
  - Flutter: `Color.lerp(black, pageTint, .25)`.

  Outside the reader, a fallback to `#000` keeps the scrims black.
- **Something pinned in the Listen transport's fade.** §8.16.3's Decouple row (l. 2540) pins `Back to the voice ↓` "at the bottom of the transcript". That is exactly the 64 px band where the transport's `scrim.sole` fade paints. On the web the fade sits in the transport's stacking context. In Flutter the transport paints after the transcript in the column. Either way the button would sit under .90 × ramp black. Giving the button `z.sticky` or more on the web, and painting it after the transport in Flutter, would keep it at full contrast. Alternatively, it could be pinned above the fade: bottom offset ≥ 64 px.
