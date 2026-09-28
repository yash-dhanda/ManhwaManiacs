# Cinematic DESIGN.md: fixes applied from the mobile coverage judge

## Round 1

Source: `cinematic/verify/judge-mobile.md`, section "Confirmed" (28 findings, none refuted). Every fix was applied as the judge rewrote it. Section numbers refer to `cinematic/DESIGN.md`. No screens were added or removed, so Appendix B (Coverage) is unchanged.

| ID | Sections changed |
|---|---|
| MOBILE-1 | §8.0.5 Back row (iOS `SwipeablePage` slide on a linear curve; Android via `CinePageTransitionsBuilder`) and a new "Route transitions in the app" block after the table (Page 320 / 224 ms for every push and button or programmatic pop; match cuts 480 / 336 ms with `Hero.transitionOnUserGestures` on iOS only; iOS `transitionBuilder` switching on `isSwipeGesture` with `userGestureInProgress` for the page beneath; Android `CinePageTransitionsBuilder` copying `_PredictiveBackGestureDetector`, fade-through values, `CineMatchCutPage`; Zoom and `PredictiveBackFullscreenPageTransitionsBuilder` never ship); §15.3 `router.dart` row and a new `transitions.dart` row |
| MOBILE-2 | §8.14.2 Flutter route (one `SwipeablePage` for both readers, `{entry: 'wipe' \| 'dip'}` in `extra`, 616/744/872 or 440 ms in, 440 ms reverse, builder paints blades only on forward, Dip in, Dip on reverse, slide on swipe) and Exit (back target `canPop` or `go` to the series page by Dip; iOS `canSwipe` only in strip or novel scroll at zoom ≤ 1.0 with guided view off; Android no predictive preview); §8.14.10 Back row; §8.15.8 gestures paragraph; §11 Edge swipe back row; §15.3 `router.dart` row |
| MOBILE-3 | §11 new "Precedence between horizontal gestures" paragraph (rows win, `touch-action: pan-y` on the web, nested contents tabs tap only), §11 Contents tabs and strip chapter swipe rows; §8.0.5 Edge swipes row now covers iOS and Android (edge width max(24 px, `systemGestureInsetsOf`), zoom ≤ 1.0, 30° rule); §8.14.5 chapter-swipe bullet |
| MOBILE-4 | §6 new "Audio session and focus policy" table (State A ambient with no Android focus and `handleAudioSessionActivation: false`; State B `speech()` with `AUDIOFOCUS_GAIN`; Voice sample `.playback` + `.duckOthers` with `AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK`; startup `configureNovelAudioSession()` replaced by State A), which absorbs the iOS session rule CONSISTENCY-13 had put in §9.4.2; §9.4.2 Playback ("mixes with other audio at its own volume, never ducking or stopping it") and its Audio session bullet now references §6; §8.16.5 `Hear`; §8.16.10; §14.9 reference |
| MOBILE-5 | §8.0.3 new "Shell branches" table (five branches, the nested Library hub `StatefulShellRoute.indexedStack`, root-navigator routes) with the push / `go` rules and the static-`/library/...`-before-`/library/:followedId` declaration order; §15.3 `router.dart` row |
| MOBILE-6 | §3.3 scale-factor definition (`textScalerOf(context).scale(16) / 16`), the ≥ 1.5 bullet (thumb index keeps its icons; "drops the icons" deleted), new "Labels in fixed cells" and "Heights are minimums" paragraphs; §7 intro Heights bullet; §7.1 `split` size; §7.13 Height; §7.14 Cell; §8.14.3 running head and folio bar heights; §8.17 phone icon-row labels |
| MOBILE-7 | §3.3 new "Literal sizes" paragraph (one cap per face via `CineType.literal`, with the 1.3 exceptions for count badges and dialogue subtitles); §7.14 Badges |
| MOBILE-8 | §3.3 (the "≥ 2.0 … independent of this cap" clause replaced by the `TextScaler.noScaling` rule); §8.15.5 Size row; §14.7 |
| MOBILE-9 | §2.2.2 new "Horizontal safe areas" rule (app and web formulas, bars inset content, readers centre in the safe rectangle, art may bleed); §8.0.9 Landscape phones; §8.14.1 and §8.15.1 landscape rows |
| MOBILE-10 | §8.14.1 Landscape phone row (running head and folio bar hidden at rest and shown together on a centre tap; portrait heights and buttons kept) |
| MOBILE-11 | §8.0.5 System bars row (enter, chrome shown, exit modes and colours; strip and column ignore insets); §8.14.3 Auto-hide Motion bullet; §8.15.3 new System UI bullet |
| MOBILE-12 | §8.19 series download card and §8.23 Activity block (foreground note and the background pause reason now shown on iOS and Android, "(app)") |
| MOBILE-13 | §8.16.2 new "Following along on the page" block (spot.wash band, stepped word underline, tint backgrounds dropped under the band, 38 % hold with the 20–70 % band, decouple with `Back to the voice ↓`, 4000 ms re-follow, reduced motion) |
| MOBILE-14 | §9.2.5 Flutter export (`Save image` per platform: iOS `NSPhotoLibraryAddUsageDescription` in the native-plugin commit; Android 29+ `MediaStore` through the `mm/media` channel; hidden on API 24–28) |
| MOBILE-15 | §11 Pull row (Sources, Collections, collection detail, Picks with their endpoints); new Gestures lines in §8.11 phone, §8.21 and §9.1.3 phone layout |
| MOBILE-16 | §12.3 Per-skin icon (package-deferred Android alias swap, empty blacklists, no custom `setComponentEnabledSetting`); §8.30.3 Android confirm line; §8.32 `AppRestart.of(context).restart()` (§8.30.3 already used it) |
| MOBILE-17 | §8.0.5 new "Back inside modal states" block (Android back order, Switch-profile picker as a pushed takeover, iOS `PopScope(canPop: false)` for states 1–4); §8.0.5 Back row and §11 Edge swipe back row point to it |
| MOBILE-18 | §8.14.11 new "Saving the next chapter" paragraph (trigger, skips, feedback, setting); §8.23 STORAGE tab gains the `Save the next chapter while I read` switch; §15.4 engine duty |
| MOBILE-19 | §8.9 Phone layout (`TAGS` section in the Filters sheet, tag tokens after the slug line, active-filter count on `Filters`) |
| MOBILE-20 | §8.14.8 migration paragraph (only K01–K03, K06, K09–K12 copied into profiles; K04, K05, K07, K08 stay device keys) |
| MOBILE-21 | §7.13 Height (48 on Android); §8.0.1 Phone frame; §8.8 trailer scrub (Android 48 → 64); §7.2 `on-art` and `ruled`, §7.1 `quiet`, §8.14.3 chapter folio (44 / 48 with `hitMin` / `hitAndroid`). §9.1.5 Skip recap already read "44 (48 Android) hit" |
| MOBILE-22 | Already consistent in the working copy when this round ran (§7.14 icon 24, §7.1 `play` 64 / 56 / 36, §7.7 Below captions without the literal 14/20); verified, no further edit |
| MOBILE-23 | §7.16 swipe actions (one action per row, `Dismissible` with `endToStart` and 0.5 threshold, `Mark read` springs back via `confirmDismiss`); §11 Swipe row; §15.3 packages list; §15.11 ledger row removed |
| MOBILE-24 | §3.1 new "OS bold text" rule; §14.7. The contrast half was already in §14.4 (A11Y-13). A11Y-13 had written +150 in §14.7 while MOBILE-24 says +120; they are merged as +120 (the novel reader's existing Bold text step, 400 → 520) with A11Y-13's per-face axis clamps (900, or 800 for Newsreader and Atkinson) and Plex Mono at its 600 static |
| MOBILE-25 | §8.14.5 Zoom bullet (stepper sets the resting zoom; strip pinch 0.5–3.0× with 0.1 snap; double tap resting ⇄ min(2 × resting, 3.0)×; paged 1–3×); §8.14.8 Zoom row; §8.14.10 Double tap and Pinch rows; §11 Double tap and Pinch rows |
| MOBILE-26 | §8.15.6 (from the book page the Contents sheet is a standard §7.9 sheet: `paper.2`, `rule.2` top edge, `spot.wash` current row) |
| MOBILE-27 | §8.30.2 row 12 scope (web; app on tablets, `shortestSide ≥ 600`, iPad and Android) |
| MOBILE-28 | §9.2.4 intro and Frame, phone (full-bleed page with a centred 9:16 safe box, segments at `viewPadding.top + 8`, close `x` placement and hit, tap-third exclusions) |

## Round 2

Source: the three findings `cinematic/verify/recheck-mobile-1.md` left unresolved, plus its three non-blocking notes. The other 25 findings were already resolved and were not touched. No screens were added or removed, so Appendix B (Coverage) is unchanged.

| ID | Sections changed |
|---|---|
| MOBILE-5 | §8.28 Index Transitions ("Page to each destination" replaced: branch-4 destinations are pushed with Page; Updates, Collections, History, Bookmarks, Picks, Dialogue search and Storage use `go` and play the §8.0.4 phone section change, Cut + Set + Folio flip, moving the notch; The Annual as a root takeover, Switch profile by Dip, What's new and Switch account as sheet and dialog); §8.10 Updates Transitions (stop-press `Read updates` is `go('/updates')`: section change from another branch, hub tab Cut inside branch 1, Dip out of the novel reader); §8.0.3 Shell branches table completed so every route has a branch: `/admin/status` in branch 4, `/library/browse` in the SHELF tab, `setup`, `login`, `register` on the root navigator |
| MOBILE-6 | §2.1.4 `scrim.head` and `scrim.sole` Geometry and §2.8.3 `scrim.head` and `scrim.sole` rows: the flat part follows the bar's laid-out height (running head min safe area + 44 / 48, growing to title line + 2 × 12; folio bar min 64 + inset, growing by its second caption line), fades unchanged (44 / 64 px phone, 64 px desktop); web `--mm-scrim-sole` now uses `--scrim-bar` / `--scrim-fade` like `--mm-scrim-head`, both painted on the bar's own `::before` with `--scrim-bar: calc(100% - var(--scrim-fade))` and `isolation: isolate` on the bar; Flutter `scrimHead` / `scrimSole` painted by the bar as `Positioned(bottom: -fade)` in `Stack(clipBehavior: Clip.none)`, bar = `constraints.maxHeight − fade`; §15.7 over-art test rows checked at scale 1.0 and the largest scale |
| MOBILE-21 | §2.1.4 and §2.8.3 `scrim.head`: phone flat part is safe area + 44 px (48 on Android), total min safe area + 88 px (92 on Android), so the Android 48 px buttons and chapter folio sit on the flat .88 ground |
| MOBILE-13 (note) | §8.16.2 "Following along on the page": trailing ";" → "." |
| MOBILE-18 (note) | §8.14.11 heading now reads "an existing engine duty, extended here, §15.4" |
| MOBILE-4 (note) | Already reads "whenever neither narration nor a voice sample is active" in §6; no edit |

## Round 3

Source: the one finding `cinematic/verify/recheck-mobile-2.md` left unresolved (MOBILE-6, web half) and its two non-blocking notes. The other 27 findings were already resolved; a grep for their removed wording (`drops the icons`, `+150`, `flutter_slidable`, `AppRestart.restart()`, `(web, iPad)`, `folio bar only on tap`, `independent of this cap`, `stops when other audio starts`, `Page to each destination`) still finds nothing. No screens were added or removed, so Appendix B (Coverage) is unchanged.

| ID | Sections changed |
|---|---|
| MOBILE-6 | §2.8.3 `scrim.head`, `scrim.sole` and (same root) `scrim.foot` rows: no `--mm-scrim-head` / `--mm-scrim-sole` / `--mm-scrim-foot` property in the `[data-skin]` block any more; `build.mjs` writes each gradient into its `@utility`, so every `var()` resolves on the painting element. `scrim-head` / `scrim-sole` carry the `::before` geometry (`position: absolute`, `inset` extended by `calc(-1 * var(--scrim-fade))` at the bottom / top, `z-index: -1`, `pointer-events: none`) and stops at `calc(100% - kScrimStops[i] * var(--scrim-fade))`, applied as `before:scrim-head` / `before:scrim-sole`; `--scrim-bar` is gone. The running head (positioned, `isolation: isolate`) sets `--scrim-fade` `44px`, `64px` from 768 px (`frame:`); the folio bar and the Listen transport set `64px`. `scrim-foot` reads `--amb-tint` (through `color-mix(in srgb, …, transparent)`) and `--scrim-solid-at` (px, fallback `100%`) on its own element. §2.8 web-property bullet: why these three keys exist only as utilities. §15.7 over-art row: the web Playwright tests assert these `background-image`s are not `none` |
| MOBILE-6 (note) | §2.8.3 `scrim.sole` Flutter: painted as `Positioned(top: -fade, left: 0, right: 0, bottom: 0)` |
| MOBILE-5 (note) | §8.33.3: the banner is hidden on Updates and in the manga reader only, matching its own last sentence (novel reader, top edge) and §8.10 |

Not touched, outside this lens: §2.1.4 and §9.4.4 say the page-tint mix (25 %) applies to the `scrim.head` / `scrim.sole` colour, but neither the web utilities nor the Flutter fields read `--page-tint` / `pageTint`. This predates round 3 (the old `[data-skin]` value could not read it either); with the gradient now in the utility, `color-mix(in srgb, var(--page-tint) 25%, #000)` could replace the black there.

## Round 4 (main session)

- MOBILE-6: §2.8.3 `scrim.sole` web column now requires the bar to be positioned (folio bar absolute/fixed in the reader chrome overlay, Listen transport relative), so the `::before` sizes against the bar.
