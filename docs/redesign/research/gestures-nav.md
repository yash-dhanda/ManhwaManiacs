# Gestures and navigation vocabulary

ManhwaManiacs redesign research. Covers web desktop, web mobile (standalone PWA), iOS and Android (Flutter), for both skins, **Cinematic** and **Glass**.

Researched 2026-09-29. Version numbers come from the npm registry and the pub.dev API on that date. Flutter framework constants come from the `3.44.6` tag, the version CI pins in `.github/workflows/ios-build.yml` and `tests.yml`. Browser support comes from `mdn/browser-compat-data` `main`.

---

## 0. Decisions in one screen

| Area | Web (Next 16 / React 19 / Motion) | Flutter 3.44 (iOS + Android) |
|---|---|---|
| Back | No custom JS edge swipe. The OS or browser back goes through history. Every sheet and overlay that should close on back gets a history entry. In-app links animate with React `<ViewTransition>` plus `transitionTypes={['nav-forward'\|'nav-back']}`. Browser back animates nothing, so the browser's own swipe animation never plays twice. | **iOS:** `swipeable_page_route` 0.4.8 (MIT). Cinematic uses an edge-only swipe; Glass uses a full-width swipe to match iOS 26. **Android:** predictive back through `PageTransitionsTheme`. Cinematic uses `PredictiveBackFullscreenPageTransitionsBuilder`, Glass uses `PredictiveBackPageTransitionsBuilder`. Add `android:enableOnBackInvokedCallback="true"`. |
| Sheets | `@base-ui/react` 1.8.0 `Drawer` (swipe to dismiss, snap points, nested drawers). **Not vaul**: its README says the repo is unmaintained. | Glass: `showCupertinoSheet` / `CupertinoSheetRoute` (built in). Cinematic: `showModalBottomSheet` + `DraggableScrollableSheet(snap: true)`. Move to `smooth_sheets` 1.2.0 (MIT) only if detent-to-scroll handoff stutters. |
| Long press / preview | `@base-ui/react` `ContextMenu` (right-click and long press), with a preview card inside the popup. | Glass: `CupertinoContextMenu` (built in). Cinematic: `onLongPress` opens a Quick Look sheet. **Avoid `super_context_menu`** (Rust build via cargokit). |
| Drag to reorder | Motion 13 `Reorder` (13.1.0 added grid, auto-axis and RTL), plus keyboard and menu alternatives. | `ReorderableListView` (built in). Poster grid: `flutter_reorderable_grid_view` 5.7.0 (BSD-3). |
| Swipe between top tabs | CSS `scroll-snap-type: x mandatory`. No library. | `TabBar` + `TabBarView` (built in). |
| Pull to refresh | About 60 lines of pointer-event code with a rubber-band formula. No library. | Glass: `CupertinoSliverRefreshControl` with a custom `builder`. Cinematic: `custom_refresh_indicator` 4.0.2 (MIT). |
| Pinch / double tap | `@use-gesture/react` 10.3.1 `usePinch` for the reader only. It normalises touch pinch, Chrome/Firefox `ctrl+wheel` and Safari `GestureEvent`. | Reader strip: `ScaleGestureRecognizer` drives the existing zoom level. Paged mode and image viewers: `InteractiveViewer`. Viewer with dismiss: `extended_image` 10.1.0 (MIT). |
| Swipe row actions | Motion `drag="x"`. | `Dismissible` (built in) for one action. `flutter_slidable` 4.0.3 (MIT) when a row needs several revealed actions. |
| Keyboard | Keep and extend the existing `lib/keyboard` registry, `CommandPalette` and `ShortcutsDialog`. **No cmdk or tinykeys.** | `Shortcuts` / `Actions` with the same key map for hardware keyboards (iPad, tablets). |
| Haptics | Android: `navigator.vibrate`. iOS 18+ Safari: a hidden `<input type="checkbox" switch>` label click (about 10 lines; `ios-haptics` 3.2.0 is the reference). | Existing `Haptics` wrapper over `HapticFeedback` (3.44 has `successNotification` / `warningNotification` / `errorNotification`). Android threshold constants go through a 15-line channel in `MainActivity.kt`. |

The dependency changes are:

- **Web adds:** `@base-ui/react`, `@use-gesture/react`, and `framer-motion` 12 migrated to `motion` 13.
- **Flutter adds:** `swipeable_page_route`, `custom_refresh_indicator`, `extended_image`, `flutter_reorderable_grid_view`, and later `smooth_sheets` / `flutter_slidable` if they turn out to be needed.

Everything else uses the platform or code that already exists in the repo.

---

## 1. What the current code already decides (behaviour contracts, not looks)

These facts come from `/srv/manhwamaniacs/dev/ManhwaManiacs`. They describe behaviour the redesign has to re-implement or deliberately replace. None of them is a visual to preserve.

- **Flutter reader back gesture.** The code is hand-rolled in `mobile/lib/features/reader/widgets/reader_edge_back_gesture.dart`: a 20 px strip, commit at 50 % of screen width or on a fling of at least 1.0 screen-width per second. It exists because the reader route is a `CustomTransitionPage` (a 280/220 ms fade, `app_router.dart:384`), which bypasses `PageTransitionsTheme` and so loses both the Cupertino swipe and predictive back. It is only enabled in vertical (webtoon) mode, because paged LTR/RTL mode is a horizontal `ListView`. **In the redesign:** delete it and use `SwipeablePage(canSwipe: verticalMode && !zoomed, canOnlySwipeFromEdge: true)` (§3.1).
- **Reader taps.** Tap zones are `left | center | right` bands with a default edge ratio of 0.28, configurable per band (`advance | retreat | toggle`) and mirrored for RTL. The rule is shared by web (`features/reader/keymap.ts`) and Flutter (`reader_content.dart`).
  - Double tap zooms. Flutter detects it by timestamp **on purpose**, because `GestureDetector.onDoubleTap` would add a 300 ms delay to every single tap.
  - Five centre taps unlock a locked reader.
  - Controls auto-hide after 3 s.
- **Android back.** There is no `android:enableOnBackInvokedCallback` in `AndroidManifest.xml`. Flutter 3.44 defaults to `targetSdkVersion 36`, so Android 16+ devices get predictive back anyway (the OS enables it by default for apps targeting 36). Android 13 to 15 devices do not. `MainActivity` is a `FlutterActivity`, which is good: issue #192551 reports predictive back route transitions failing with `FlutterFragmentActivity` on 3.41.9.
- **Flutter shell.** `StatefulShellRoute.indexedStack` with a floating bottom bar. `go_router: ^14.0.0` is pinned; the latest is 18.0.2.
- **Web keyboard registry.** `lib/keyboard` (`useShortcut`, chord support such as `"g l"`, `allowInInput`, `enabled`).
  - Global bindings: `mod+k` palette, `mod+b` sidebar, `?` help sheet (reads the live registry), `/` focuses search.
  - Grids: arrows plus `h j k l`.
  - Reader: `j`/`k`, `←`/`→` and `a`/`d`, `space` / `shift+space`, `home`/`end`, `h`/`l` chapters, `f` fullscreen, `c` cinema, `p` auto-scroll, `s` series, `b` bookmark, `=` `-` `0` zoom, `esc`.
  - Novels: `h`/`l`, `=` `-`, `t`, `b`, `esc`.
  - **Gap:** Settings › Shortcuts is a read-only list. No toggle exists for single-character shortcuts, which WCAG 2.1.4 requires (§5).
- **Web overscroll.** `globals.css` sets `overscroll-behavior: none` on **both `html` and `body`** to stop iOS pull-to-refresh and rubber-band in the reader. On the root scroller that also covers the **x** axis. In Chromium, that turns off trackpad swipe-to-go-back. There is also a report that it turns off WebKit's edge swipe in a home-screen PWA. **In the redesign:** use `overscroll-behavior-y: none` on the root so the horizontal OS gesture survives. Verify on the owner's iPhone in standalone mode.
- **PWA mode.** `manifest.ts` sets `display: "standalone"` and `orientation: "portrait-primary"`. On iPhone the web app runs without Safari chrome, so there is no browser back button. Swipe-back and in-app back buttons are the only ways out.

---

## 2. Platform ground truth

### iOS (UIKit and Flutter)

- **Edge swipe back.** The native interactive pop works everywhere. Flutter's `CupertinoPageRoute` reproduces it with these constants (`cupertino/route.dart`, 3.44.6):

  | Constant | Value |
  |---|---|
  | `_kBackGestureWidth` | 20.0 (or the left safe-area inset, whichever is larger) |
  | `_kMinFlingVelocity` | 1.0 screen widths/s |
  | Commit rule | past 50 % of width |
  | `_kDroppedSwipePageAnimationDuration` | 350 ms, `Curves.fastEaseInToSlowEaseOut` |
  | `kTransitionDuration` (push/pop) | 500 ms, `linearToEaseOut` / `easeInToLinear` |

- **iOS 26 full-width swipe back.** `UINavigationController.interactiveContentPopGestureRecognizer` lets the user start the pop swipe **anywhere** in the content. Flutter does not support this: issue #180309 is open (P2) and the 20 pt limit remains. Issue #184507 records native conflicts with horizontal scrollers. `swipeable_page_route` fills the gap (§3.1).
- **Context menus.** 3D Touch "Peek and Pop" is gone: hardware stopped shipping it with iPhone XR/11, and iOS 13 replaced it with Haptic Touch context menus. **Design only for long press.** Flutter's `CupertinoContextMenu`:

  | Constant | Value |
  |---|---|
  | `_previewLongPressTimeout` (time to open) | 800 ms |
  | Modal popup transition | 335 ms |
  | `_kOpenScale` | 1.15 (min 1.02, clamped to fit) |
  | Barrier | `Color(0x6604040F)` |
  | Menu width | 250 |

- **Sheets.** iOS 15+ detents; iOS 26 sheets float inset as Liquid Glass at partial height and attach to the edges at full height. Flutter's `CupertinoSheetRoute` (`cupertino/sheet.dart`):

  | Constant | Value |
  |---|---|
  | Top gap | 8 % of height (`_kTopGapRatio 0.08`; 0.072 when stretched) |
  | Covered page scale | shrinks by `_kSheetScaleFactor 0.0835` (about 0.92) |
  | Dismiss fling | at least 2.0 screen heights/s |
  | Dropped-drag animation | 300 ms |

- **Tab bar (iOS 26).** The bar is a capsule inset from the edges.
  - `tabBarMinimizeBehavior(.onScrollDown)` collapses it to the active tab while scrolling down.
  - `Tab(role: .search)` gives search its own circular button.
  - `tabViewBottomAccessory` is a strip above the bar (e.g. a Now Playing bar) that merges into it when the bar minimises.

  This is the reference for Glass's dock.
- **Springs.** Cupertino dialogs and action sheets use stiffness 522.35 and damping 45.71 (critically damped). Flutter 3.44 has `SpringDescription.withDurationAndBounce(duration:, bounce:)`, the same parameters as SwiftUI `.spring(duration:bounce:)` and Motion `visualDuration`/`bounce`.

### Android

- **Predictive back** (Android 13+ with the manifest flag; default for `targetSdk 36` on Android 16+, where `onBackPressed` and `KEYCODE_BACK` are no longer delivered). Material's specification:

  | Variant | Numbers |
  |---|---|
  | **Full-screen** | exit scale 100 → 90 %, enter scale 110 → 100 %, fade-through at **35 %** progress, interpolator `(0.1, 0.1, 0, 1)` |
  | **Shared-element** (Flutter's default) | surface scales to **90 %**; x shift `(screenWidth/20 − 8) dp`, y shift `(height/20 − 8) dp`; 8 dp edge gap; progress interpolator `(0, 0, 0, 1)` |

  Flutter 3.38+ uses `PredictiveBackPageTransitionsBuilder` as the default Android page transition. It falls back to `FadeForwardsPageTransitionsBuilder`, and the default duration rose from 300 ms to 450 ms. `PredictiveBackFullscreenPageTransitionsBuilder` implements the full-screen variant and falls back to `ZoomPageTransitionsBuilder`.
- **Sheets on back.** In Flutter 3.44.6, modal routes follow back progress generically (`TransitionRoute` implements `PredictiveBackRoute`). `bottom_sheet.dart` has no Material-specific predictive-back shrink, so a skin that wants that shape builds it itself.
- **Root back.** From a non-home tab, back goes to the home tab first. From home, the system plays back-to-home.
- **Haptics.** API 34 added `HapticFeedbackConstants.GESTURE_THRESHOLD_ACTIVATE`, `GESTURE_THRESHOLD_DEACTIVATE`, `DRAG_START`, `SEGMENT_TICK`, `SEGMENT_FREQUENT_TICK`, `TOGGLE_ON` and `TOGGLE_OFF`. `CONFIRM` and `REJECT` date from API 30. Flutter's `HapticFeedback` does not expose them; call `window.decorView.performHapticFeedback(...)` over a `MethodChannel` from the existing `MainActivity.kt`.

### Web desktop

- **Keyboard** is primary (§3.12).
- **Mouse:** hover and right-click.
- **Trackpad:**
  - A two-finger horizontal swipe is browser history navigation when the root overscrolls on x. Set `overscroll-behavior-x: contain` on every horizontal rail so a rail flick at its start never goes back.
  - Pinch arrives as `wheel` with `ctrlKey: true` in Chrome/Edge/Firefox, and as `GestureEvent` (`gesturestart/change/end`, Safari only) in Safari. The reader already arms wheel zoom (`wheel-zoom-arming.ts`).
- **Useful platform APIs:**
  - Popover API: Chrome 114, Firefox 125, Safari 17.
  - `commandfor` invoker buttons: Chrome 135, Firefox 144, Safari 26.2.
  - `inert`: universal.
  - `:focus-visible`: Chrome 86, Firefox 85, Safari 15.4.

### Web mobile (standalone PWA)

- **iOS back swipe.** WebKit ties the edge swipe to `history.pushState` entries in home-screen apps, but it is **reported flaky**, and root `overscroll-behavior-x: none` can suppress it. **Rule:** everything the user can "go back" from must be a history entry: routes, and sheets or viewers that should close on back. Test before building anything custom.
- **Android back.** In Chrome it pops history.
  - `CloseWatcher` (Chrome 126, Firefox 149, Safari only in Technology Preview) and `<dialog closedby>` (Chrome 134, Firefox 141) close layers on Android back.
  - Base UI dialogs are not native `<dialog>`. So either add a history entry, or register a `CloseWatcher` when it exists and fall back to history.
- **Double animation guard.** When the UA animates a back swipe itself, `PopStateEvent.hasUAVisualTransition` is `true` (Chrome 118, Safari 18, Firefox 149). Next's guide leaves browser back/forward on `default: 'none'`, which handles most cases. Any custom history animation must check the flag.
- **Transitions.** `document.startViewTransition` (Chrome 111, Safari 18, Firefox 144). Next 16's App Router ships React canary, so `import { ViewTransition } from 'react'` works without configuration. React 19.3.0 (2026-09-09) made it stable. Motion 13.4.0 adds `AnimateView` on top of it.
- **Haptics.**
  - `navigator.vibrate` works in Chrome Android and not in Safari.
  - On iOS 18+, toggling a `<input type="checkbox" switch>` (Safari 17.4+) through a `<label>` click fires the system haptic tick. It is a hack, but the only one available.
  - Gate both behind the per-skin haptics setting.

---

## 3. Gesture catalogue

Each entry covers: where it is used in ManhwaManiacs, thresholds, the web and Flutter implementation, how each skin differs, the non-gesture alternative (required by §5), and reduced-motion behaviour.

The shared physics tokens are:

| Token | Cinematic ("weight, no wobble") | Glass ("liquid, alive") |
|---|---|---|
| Release spring, web (Motion) | `{ type: "spring", visualDuration: 0.42, bounce: 0 }` | `{ type: "spring", visualDuration: 0.38, bounce: 0.18 }` |
| Release spring, Flutter | `SpringDescription.withDurationAndBounce(duration: Duration(milliseconds: 420), bounce: 0)` | `…(duration: 380 ms, bounce: 0.18)` |
| Close / dismiss spring | same, `bounce: 0` | `visualDuration: 0.32, bounce: 0` (never bounce on the way out) |
| Timed ease (non-gesture) | enter 450 ms `cubic-bezier(0.32, 0.72, 0, 1)`, exit 240 ms `cubic-bezier(0.4, 0, 1, 1)` | springs only |
| Rubber-band constant `c` in `d·(1 − 1/(x·c/d + 1))` | 0.35 (stiff, heavy) | 0.55 (the iOS constant) |
| Motion `dragElastic` past bounds | 0.12 | 0.35 (Motion default) |
| Long-press delay | 500 ms (`kLongPressTimeout`) | 500 ms to start; preview grows until 800 ms (`CupertinoContextMenu`) |
| Pressed / lifted scale | press 0.97, lift 1.04 | press 0.96, lift 1.08, preview up to 1.15 |
| Haptic density | sparse and heavier: commits only | frequent and light: every detent, tick and tab |
| Scroll physics (Flutter) | platform: iOS bounce, Android stretch overscroll | `BouncingScrollPhysics` on **both** platforms (the skin is Apple-flavoured, and switching skins restarts the app) |

Velocities are in px/s, distances in logical px/pt.

### 3.1 Back navigation

- **Where:** every pushed screen (series page, source page, settings subpages, stats, collections, reader, novel reader, OCR results).
- **iOS, Flutter:** replace `builder:` with `pageBuilder:` returning `SwipeablePage` (from `swipeable_page_route` 0.4.8, MIT, 2026-01-02).
  - Parameters: `canSwipe`, `canOnlySwipeFromEdge`, `backGestureDetectionWidth` (default `kMinInteractiveDimension` = 48), `backGestureDetectionStartOffset`, and `transitionBuilder` for a skin-specific transition that still tracks the finger.
  - **Cinematic:** `canOnlySwipeFromEdge: true`, width `max(20, padding.left)`. Transition: the incoming page slides in from the right edge. The outgoing page drifts 30 % left, scales 1 → 0.94 and dims under a `#000000` scrim from 0 to 0.6 opacity. Commit happens past 50 % or on a fling of at least 1 width/s. Release uses the Cinematic spring.
  - **Glass:** `canOnlySwipeFromEdge: false` (full width, iOS 26 parity). Standard parallax slide (the underlying page moves 1/3). The glass nav bar title cross-fades (`MorphingAppBar` from the same package, if it fits the chrome). Release uses the Glass spring.
  - **Exceptions, both skins:** the reader uses edge-only swipe, disabled when zoomed past 1× or in paged mode (it replaces `ReaderEdgeBackGesture`). Screens whose first child is a horizontal `PageView` or `TabBarView` must pop only when the pager is at index 0 and the drag goes right. **Verify on device**: this is exactly the conflict in Flutter issue #184507.
- **Android, Flutter:** use `MaterialPage` (not `SwipeablePage`) so `PageTransitionsTheme` applies. Branch on `defaultTargetPlatform` in one `pageBuilder` helper.
  - Cinematic: `PredictiveBackFullscreenPageTransitionsBuilder`. Full-screen fade-through at 35 % reads as a film cut.
  - Glass: `PredictiveBackPageTransitionsBuilder`. The card shrinks to 90 % and floats, which matches glass.
  - Add `android:enableOnBackInvokedCallback="true"` to `<application>`.
  - Use `PopScope(canPop:, onPopInvokedWithResult:)` only where back must be intercepted (unsent OCR query, active reorder).
  - Shell root: `PopScope` on `_AppShell`. If `navigationShell.currentIndex != 0`, go to branch 0; otherwise let the system play back-to-home.
- **Web mobile:** no JS edge swipe. Routes are real URLs, and sheets or viewers that should close on back are URL state (`?sheet=chapters`, `?view=cover`) or history entries. Transitions use `<ViewTransition>` with `enter`/`exit` keyed by `nav-forward` / `nav-back` and `default: "none"`, so UA swipe-backs are not animated twice.
  - Slide offsets: Cinematic 60 px with a crossfade to black; Glass 40 px with a scale from 0.98 plus blur 8 → 0 px.
  - Fallback, only if an on-device test in standalone shows no native swipe: a 20 px left strip, gated on `matchMedia('(display-mode: standalone)')` and iOS, that calls `history.back()` past 50 % width or at at least 1000 px/s.
- **Web desktop:** a visible back affordance in the top bar or sidebar. `alt+←` and `mod+[` belong to the browser; leave them. `Esc` closes the topmost layer first, then in the reader exits to the series page (existing behaviour).
- **Alternative:** a back button is always visible, even in Glass's minimised-chrome state and in the reader chrome.
- **Reduced motion:** the swipe still tracks the finger (direct manipulation is not decorative motion). On release, and for button-triggered navigation, use a 150 ms opacity cross-fade with no slide, scale or blur.

### 3.2 Swipe between top tabs

- **Where:** source page browse modes (server-provided arbitrary labels such as `Popular`, `Latest` and `Top Rated`, so tabs must scroll horizontally); Library Manga/Novels; Updates Manga/Novel; search result types; stats periods.
- **Never:** bottom or dock tabs are not swipeable. That would fight back-swipe and horizontal rails.
- **Web mobile:** the pager is a flex row with `overflow-x: auto; scroll-snap-type: x mandatory; overscroll-behavior-x: contain; scrollbar-width: none`. Each panel is `flex: 0 0 100%; scroll-snap-align: start; scroll-snap-stop: always`.
  - The tab indicator follows `scrollLeft / clientWidth`, read in a passive scroll listener on `requestAnimationFrame`. A tap on a tab calls `panel.scrollIntoView({ behavior, inline: 'start' })`.
  - Each panel virtualises its own list with the existing `@tanstack/react-virtual`.
- **Web desktop:** the same markup, but panels switch on click, `[` and `]`, or arrow keys inside the `tablist`, with `overflow-x: hidden` so trackpad swipes cannot drift. ARIA: `role="tablist" / "tab" / "tabpanel"`, `aria-selected`, roving `tabindex`.
- **Flutter:** `TabBar(isScrollable: true)` with `TabBarView`, driven by one `TabController`. The indicator reads `controller.animation` so it tracks the drag continuously.
  - **Cinematic:** a 2 px underline that stretches between tabs during the drag (width follows `lerp` of the two tab widths). Labels jump from 60 % to 100 % white. No haptic.
  - **Glass:** a sliding glass capsule behind the label, in the spirit of a segmented control. `selectionClick` when the page settles.
- **Alternative:** tabs are tappable, `[` and `]` on keyboards.
- **Reduced motion:** the pager snaps without its settle animation (`behavior: 'auto'` on web; `animateToPage` becomes `jumpToPage`). The indicator jumps.

### 3.3 Pull to refresh

- **Where:** Home, Library, Updates, source browse, History, Collections. Not Downloads: it is local data, and pulling there would suggest a network refresh that does not happen.
- **Flutter Glass:** `CustomScrollView(physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()))` with `CupertinoSliverRefreshControl(builder: …, onRefresh: …)`.
  - Defaults: `refreshTriggerPullDistance` 100, `refreshIndicatorExtent` 60, activity-indicator radius 14.
  - The custom `builder` draws a liquid droplet whose meniscus stretches with `pulledExtent` and pops at the trigger. `lightImpact` fires at the trigger.
- **Flutter Cinematic:** `custom_refresh_indicator` 4.0.2 (MIT, 2026-08-18) works with clamping physics (Android) and bouncing physics (iOS).
  - Visual: a thin light-leak bar grows across the top edge and a film-leader ring counts in.
  - Trigger at 96 px; the indicator rests at 56 px. `mediumImpact` at the trigger.
  - Built-in `RefreshIndicator` has no custom builder. Its mechanics, for reference: 25 % container extent × 1.5 limit, 150 ms snap, 200 ms scale.
- **Web mobile:** about 60 lines on the list's scroll container.
  - Only `pointerType === 'touch'` counts, and only when `scrollTop === 0`.
  - Displacement uses the rubber-band formula with the skin's `c`. Commit when the raw pull passes 96 px (Cinematic) or 100 px (Glass), with one haptic at the crossing.
  - The container gets `overscroll-behavior-y: contain` so Chrome Android's native pull-to-refresh never fires.
  - Motion `animate` returns the indicator to its 56 or 60 px rest height while the request is in flight, then back to 0.
- **Web desktop:** no pull. `r` on list screens, a refresh icon button, and a "Refresh" command in the palette.
- **Alternative:** the same refresh button or menu item on every platform. Also announce "Updated" or the error in an `aria-live="polite"` region (web), or with `SemanticsService.sendAnnouncement` (Flutter). `announce` is deprecated in 3.44; check `MediaQuery.supportsAnnounceOf` because Android discourages announcements.
- **Reduced motion:** the indicator appears at rest height without the stretch or droplet effects. The spinner stays, because it communicates status.

### 3.4 Sheets: drag, detents, swipe to dismiss

- **Where:** chapter list inside the reader, reader settings, series quick look, filters and sort, add-to-collection, profile switcher, narrator voice picker (31 voices), download picker, share card.
- **Web (both form factors):** `@base-ui/react` 1.8.0 (MIT, 2026-09-04) `Drawer`.
  - API: `swipeDirection` (`down` by default; `up`, `left` or `right` for side panels), `snapPoints` (fractions of viewport or px, e.g. `['148px', 1]`), nested drawers (`--nested-drawers`, `[data-nested-drawer-open]`), and `Drawer.SwipeArea` for swipe-to-open.
  - CSS variables `--drawer-swipe-progress`, `--drawer-swipe-movement-y`, `--drawer-swipe-strength` and `--drawer-snap-point-offset`; the `data-swiping` attribute.
  - `data-base-ui-swipe-ignore` opts out descendants such as horizontal voice carousels.
  - The docs' reference motion is **450 ms `cubic-bezier(0.32, 0.72, 0, 1)`** for open, and `calc(var(--drawer-swipe-strength) * 400ms)` for release, so a hard fling closes faster.
  - It replaces `vaul` 1.1.2, last published 2024-12-14; its README says "This repo is unmaintained".
  - **Cinematic:** full-bleed black sheet, the backdrop dims to `rgba(0,0,0,0.72)`, and the page behind does not scale (film does not shrink the stage). Open uses the timed ease. No bounce at detents.
  - **Glass:** an inset floating sheet (8 px inset at partial detents, edge-attached at the top detent, following iOS 26). The page behind scales to 0.92 and its corner radius rises to about 12 px. Detents at `[0.45, 1]`. `selectionClick`-equivalent haptic on each detent snap. Release uses the Glass spring.
  - **Desktop:** the same component becomes a right-side panel (`swipeDirection="right"`, 400 to 480 px wide) or a centred dialog. Swipe is irrelevant with a mouse; `Esc` and a click on the backdrop close it.
  - **Back:** open sheets push `?sheet=…` (see 3.1) so Android back and the iOS swipe close them.
- **Flutter Glass:** `showCupertinoSheet` / `CupertinoSheetRoute` for full-height stacked sheets. For detents, `showModalBottomSheet(isScrollControlled: true, useSafeArea: true)` wrapping `DraggableScrollableSheet(snap: true, snapSizes: [0.45], initialChildSize: 0.45, maxChildSize: 1)`.
  - If a detent sheet with a long inner list (the 31-voice picker, a 1,000-chapter list) stutters on handoff between sheet drag and list scroll, move to `smooth_sheets` 1.2.0 (MIT, 2026-09-07). It handles scroll handoff and navigation inside sheets properly.
- **Flutter Cinematic:** `showModalBottomSheet` with `sheetAnimationStyle: AnimationStyle(duration: 450 ms, reverseDuration: 240 ms)`.
  - Material defaults for reference: enter 250 ms, exit 200 ms, close fling at least 700 px/s, close-progress threshold 0.5.
  - `showDragHandle: false`: Cinematic uses a 36 × 4 px handle bar inside its own header with a 44 × 44 hit area.
- **Dismiss rule (all platforms):** close when dragged past 50 % of sheet height, or on a fling of at least 700 px/s (Material) or 2 sheet-heights/s (Cupertino). Glass Flutter keeps Cupertino's rule; everything else uses 700 px/s.
- **Alternative:** a visible close button in every sheet header (44 × 44), and `Esc`. Detents also change with a tap on the handle (it cycles detents) and with `↑`/`↓` when the handle has focus.
- **Reduced motion:** sheets fade and translate 16 px (not full height) over 150 ms. There is no background scale.

### 3.5 Swipe to dismiss images and viewers

- **Where:** full-screen cover viewer, page or panel viewer opened from OCR dialogue search and bookmarks, share-card preview, avatar.
- **Commit rule:** `|dy| ≥ 120` or `|vy| ≥ 800 px/s`, and only while zoom is 1×. When zoomed, a drag pans the image instead.
- **Backdrop:** opacity `1 − min(|dy| / 320, 1)`.
- **Cinematic:** the image does not scale; the backdrop fades and the letterbox bars (top and bottom `#000`) retract. On close, the image flies back to its thumbnail (shared element).
- **Glass:** the image scales `1 − min(|dy| / 1200, 0.15)` (to 0.85), corner radius goes from 0 to 28, the background blur falls from 24 to 0 px, then it springs back to the thumbnail.
- **Web:** Motion `drag` with `dragSnapToOrigin`, `dragElastic` from the skin table, and `useTransform(y, [-320, 0, 320], [0, 1, 0])` for the backdrop. `onDragEnd` checks `info.offset.y` and `info.velocity.y` against the rule.
  - The return-to-thumbnail is `<ViewTransition name={"cover-"+id} share="morph" default="none">` on both ends.
  - Motion drag defaults, for reference (source `constraints.ts` / `VisualElementDragControls.ts`): `dragElastic` 0.35, momentum `bounceStiffness` 200, `bounceDamping` 40, `timeConstant` 750, `restDelta` 1, `restSpeed` 10.
- **Flutter:** `Hero` + `InteractiveViewer(minScale: 1, maxScale: 4)` (defaults are 0.8 and 2.5). A vertical `GestureDetector` is active only while `transformationController.value.getMaxScaleOnAxis() == 1`.
  - Or use `extended_image` 10.1.0 (MIT, 2026-07-12): `ExtendedImageSlidePage` plus `ExtendedImageGesturePageView` gives slide-out, pinch, double-tap zoom and paging in one package.
  - Avoid `photo_view` 0.15.0 (last release 2024-04-17) and `dismissible_page` 1.0.2 (2023-04-18).
- **Alternative:** a close button (top-left, 44 × 44), `Esc`, and Android back.
- **Reduced motion:** the viewer opens and closes with a 150 ms cross-fade with no shared-element flight. The drag still tracks.

### 3.6 Long-press preview (context menus)

- **Where:**
  - Posters in rails and grids: a Quick Look with cover, synopsis, progress, and actions (Continue, Add to collection, Mark read, Download, Not interested for AI recommendations, Recommend to a friend).
  - Chapter rows: mark read/unread, download, bookmark.
  - Source tiles: pin/unpin.
  - Profile avatars: edit.
  - Dock tabs: §3.11.
  - Activity-feed items: react.
- **Flutter Glass:** `CupertinoContextMenu` (or `.builder` for a custom lift). The preview lifts toward 1.15 while the press is held and the menu opens at 800 ms. Haptic: `mediumImpact` at open.
- **Flutter Cinematic:** Netflix-style. `onLongPress` (500 ms) triggers `mediumImpact`, the poster lifts 1.0 → 1.04 in 180 ms, then a **Quick Look sheet** opens. The sheet has a hero backdrop from the cover (use `w=720` from the cover endpoint, blurred and vignetted, per `capabilities.md`), the title, a progress bar and large action buttons. A tap on a poster in Cinematic can open the same sheet (Netflix mobile does this); the long press is a shortcut.
- **Avoid `super_context_menu` 0.9.1** (last release 2025-06-11). Its `super_native_extensions` core compiles Rust through cargokit and downloads precompiled binaries when Rust is absent. That fights the offline, CocoaPods-only iOS CI (`pubspec.yaml` comments) and the hostel network's GitHub CDN block. `pull_down_button` is marked discontinued on pub.dev.
- **Web:** `@base-ui/react` `ContextMenu`, which opens "at the pointer on right click or long press".
  - Put a preview card (poster 96 px wide, title, progress) at the top of `ContextMenu.Popup`, followed by the actions. That gives a "peek" on touch and a normal context menu on desktop.
  - On triggers: `-webkit-touch-callout: none; user-select: none` so iOS Safari's link-preview callout never competes.
  - **Desktop hover preview** (a pointer-only extra):
    - Cinematic: after 450 ms of hover, the poster expands to 1.35× in place with a details strip (Netflix hover card). Enter uses the timed ease; leaving collapses it after 120 ms.
    - Glass: a pointer-tracked tilt (max 6°) with a moving specular highlight. No expansion.
- **Alternative:** every long-press menu also sits behind a visible `⋯` button on the item. The button is always visible on touch (`any-pointer-coarse`), appears on hover or focus on desktop, and opens from `.` or `shift+F10` on the focused item. Base UI's own docs say context menus must not be the only path to an action.
- **Reduced motion:** no lift or scale. The menu fades in over 100 ms. The hover card is replaced by a static tooltip-style info panel.

### 3.7 Swipe row actions

- **Where:** notifications and updates (mark read), chapter list (mark read/unread, download), downloads (delete), history (remove), sessions (revoke), recommendation cards (Not interested).
- **Rules:**
  - Each revealed action is 88 px wide (the visible button is at least 44 × 44).
  - A full swipe commits the primary action when the drag passes 60 % of row width or `|vx| ≥ 1000 px/s`.
  - Haptic when crossing the commit line (Android `GESTURE_THRESHOLD_ACTIVATE`, iOS `mediumImpact`) and when crossing back (`GESTURE_THRESHOLD_DEACTIVATE` / `lightImpact`).
  - Destructive actions show an undo toast for 5 s instead of a confirm dialog.
- **Flutter:** `Dismissible` (defaults: threshold 0.4, fling 700 px/s, move 200 ms, resize 300 ms) with `dismissThresholds: {DismissDirection.endToStart: 0.6}` and `confirmDismiss` for single-action rows. Rows that reveal two or three actions use `flutter_slidable` 4.0.3 (MIT, 2025-09-27).
  - Cinematic: actions are flat colour slabs (e.g. red for delete) revealed under the row.
  - Glass: actions are separate glass pills that inflate from 0.6 to 1.0 as they are revealed.
- **Web mobile:** Motion `drag="x"`, `dragDirectionLock`, `dragConstraints={{ left: -176, right: 0 }}`, `dragElastic: 0.1`, and `touch-action: pan-y` on the row so vertical scrolling survives. Enable `drag` only when `matchMedia('(pointer: coarse)')` matches.
- **Web desktop:** action icons appear on row hover or focus. Keys on the focused row: `m` mark read, `d` download, `x` or `Delete` to remove (with undo), `u` undo.
- **Alternative:** the same actions in the row's `⋯` menu (§3.6). On Flutter, also as `Semantics(customSemanticsActions: {CustomSemanticsAction(label: 'Mark read'): …})`, so VoiceOver's actions rotor and TalkBack's actions menu reach them without swiping.
- **Reduced motion:** the committed row fades out over 150 ms instead of sliding away and collapsing.

### 3.8 Drag to reorder

- **Where** (from `capabilities.md`):
  - library manual sort (`PATCH /library/series/{id}` `sort_order`)
  - collection shelves (`sort_order`)
  - source pins (`PUT /sources/pins`, at most 50, ordered)
  - profiles
  - home-rail order (a customise mode)
  - download queue priority
- **Flutter lists:** `ReorderableListView.builder(buildDefaultDragHandles: false)` with a visible `ReorderableDragStartListener` handle (drag starts immediately). A long press anywhere on the row uses `ReorderableDelayedDragStartListener` (500 ms). The framework handles auto-scroll at the edges.
  - `proxyDecorator` carries the skin's lift: Cinematic scales 1.03 with a `#000` shadow at 60 % opacity and blur 24; Glass scales 1.05 with a brightened glass rim.
  - Haptics: `lightImpact` at pick-up (Android `DRAG_START`); Glass only: `selectionClick` each time the item passes a slot; drop: `mediumImpact` (Cinematic) or `lightImpact` (Glass).
- **Flutter poster grid:** `flutter_reorderable_grid_view` 5.7.0 (BSD-3, 2026-05-31).
- **Web:** migrate `framer-motion` ^12.42.2 to `motion` 13.4.x (import from `motion/react`; the `framer-motion` package publishes the same 13.4.4 code). Then use `Reorder.Group` / `Reorder.Item`. 13.1.0 added multi-dimensional (grid) reordering, automatic axis detection and RTL. Breaking change in 13.0.0: `@emotion/is-prop-valid` is gone, so pass it explicitly through `<MotionConfig isValidProp>` if needed.
  - Motion `Reorder` has no keyboard model, so add one: on the focused item, `alt+↑`/`alt+↓` (grids also `alt+←`/`alt+→`) moves it one slot, and `alt+shift+↑`/`↓` moves it to the top or bottom. Announce each move in `aria-live="assertive"` ("Solo Leveling moved to position 3 of 12").
  - Skip `@dnd-kit` for now: `@dnd-kit/core` 6.3.1 was last published 2024-12, and `@dnd-kit/react` is still 0.5.0. Revisit only if built-in screen-reader drag semantics become a need.
- **Alternative (WCAG 2.5.7, AA):** "Move up", "Move down", "Move to top" and "Move to bottom" in the item's `⋯` menu on every platform. Flutter `ReorderableListView` already adds `customSemanticsActions` for move up/down/start/end.
- **Reduced motion:** siblings jump to their new positions instead of animating a layout shift. The lift keeps its shadow but not its scale.

### 3.9 Pinch zoom and double tap

- **Manhwa strip (vertical, virtualised):** zoom means width zoom. The code already scales the content width by `zoomLevel`.
  - **Flutter:** a `ScaleGestureRecognizer` wrapper that handles only `pointerCount == 2` and writes the zoom level continuously (range 1.0 to 3.0). While scaling, it keeps the focal point fixed by adjusting the scroll offset: `offset' = (offset + focalY) · (z'/z) − focalY`.
  - Double tap keeps the timestamp detector (contract in §1) and toggles 1× ↔ 2× anchored at the tap point.
  - While zoom is above 1×, horizontal pan is enabled and edge-back is disabled.
  - **Web:** the strip gets `touch-action: pan-y`: the browser keeps native vertical scrolling, and two-finger pinch reaches JavaScript instead of zooming the page. Use `@use-gesture/react` 10.3.1 (MIT) `usePinch` with `{ scaleBounds: { min: 1, max: 3 }, rubberband: true, pinchOnWheel: true }`. It normalises touch pinch, `ctrl+wheel` trackpad pinch and Safari `GestureEvent`. Keep the existing wheel-zoom arming on desktop.
  - `@use-gesture`'s last release was 2024-03-21. It is stable and small, and only the reader imports it.
  - Web double tap: compare two `pointerup` events within 300 ms and 24 px of each other (Flutter's `kDoubleTapTimeout` is 300 ms; `kDoubleTapSlop` is 100).
- **Paged mode and image viewers:** per-page `InteractiveViewer(minScale: 1, maxScale: 4, boundaryMargin: EdgeInsets.zero)`. When `scale > 1`, the `PageView` gets `NeverScrollableScrollPhysics` so panning a zoomed page never turns it. Web uses `usePinch` + `useDrag` on the page, or `react-zoom-pan-pinch` 4.2.0 (MIT, 2026-09-03) if the hand-rolled version grows past about 100 lines.
- **Novel reader:** pinch changes the **text size step** (Kindle-style), not a visual zoom. One step per ×1.15 of scale, `selectionClick` per step, and the layout reflows once when the pinch ends.
- **Skins:**
  - Cinematic: the zoom release has no bounce; overscroll past 3× rubber-bands with `c = 0.35`.
  - Glass: the release springs with `bounce: 0.18`; overscroll uses `c = 0.55`.
- **Alternative:** `=`, `-` and `0` keys (existing), zoom +/− buttons in the reader settings sheet, and double tap.
- **Reduced motion:** double-tap and reset zoom jump with no animation. Pinching still tracks.

### 3.10 Reader-specific gestures

| Gesture | Behaviour | Threshold | Notes |
|---|---|---|---|
| Tap zones | Left and right bands turn pages; the centre toggles chrome (configurable, mirrored for RTL). | edge ratio 0.28 | This is the existing contract; keep it on both platforms. |
| Chrome auto-hide | Scrolling down hides the chrome; scrolling up by 24 px shows it. The Webtoon app's model. | 3 s idle hide | Never auto-hide while `MediaQuery.accessibleNavigationOf(context)` is true (screen reader on), or on web while focus is inside the chrome. |
| Overscroll to next chapter | Pull up past the end: the next-chapter card rubber-bands in. Pull down past the top: previous chapter. | commit at 96 px raw pull, plus a haptic at the crossing | The web already has `OVERSCROLL_TRIGGER` in `ChapterReader.tsx`. The card doubles as the button alternative. |
| Scrub rail | Drag the right-edge rail (a 44 px hit strip, a 3 px visible track) to seek. A page-number bubble follows. | `selectionClick` per page (Glass), per 10 pages (Cinematic) | Keyboard: `home`/`end`; the rail is also a `role="slider"` with `aria-valuetext="Page 12 of 40"`. |
| Auto-scroll speed | Tap the pill to play or pause; drag it vertically to change speed (0.25× to 4×, logarithmic). | — | Keyboard: `p` plus `shift+↑`/`shift+↓`. Flutter: a `Semantics` slider with increase/decrease actions. |
| Panel-by-panel view | Swipe left/right or tap the edge bands to move to the next or previous panel; the camera moves between panel rectangles. | swipe ≥ 50 px or ≥ 500 px/s (use-gesture's swipe defaults are 50 px / 0.5 px·ms⁻¹ / 250 ms) | Cinematic: 520 ms `cubic-bezier(0.65, 0, 0.35, 1)` "dolly". Glass: spring 0.45 s, bounce 0.1. Reduced motion: cut, no move. |
| Novel page turn (paged) | Horizontal swipe via `PageView` (Flutter) or scroll-snap (web); tap zones as above. | Flutter paging slop `kPagingTouchSlop` 36 | Cinematic: slide with 20 % parallax. Glass: slide plus a soft 8 px shadow on the turning page. No page curl: it costs a package and a shader for one effect. |
| Back inside the reader | Edge-only swipe in vertical mode at 1× zoom; nothing in paged mode or when zoomed. | 20 pt strip, 50 % or 1 width/s | Exit otherwise by the chrome back button, `Esc`, or Android back. |

### 3.11 Dock and tab bar

These rules apply to whatever tab set the IA settles on.

- **Tap an inactive tab:** switch branches. `StatefulShellRoute` keeps each stack.
- **Tap the active tab:** if the branch has pushed routes, pop to its root (`navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex)`). Otherwise scroll to top. On Search, focus the field and raise the keyboard. The web uses the same rules.
- **Long press a tab:**
  - Profile or "You" tab: the **profile switcher**, in the style of Instagram's account switcher. It fits per-profile isolation: one gesture to switch profile.
  - Library: a jump list of collections.
  - Updates: "Mark all read".
  - Cinematic presents this as a bottom sheet; Glass as a context menu growing from the tab.
- **Scroll behaviour:**
  - **Glass:** the iOS 26 model. After 32 px of downward scroll the capsule dock shrinks to a pill showing only the active icon (350 ms Glass spring). It restores after 8 px of upward scroll, on a tap, or at the top of the list.
  - The **bottom accessory** strip above the dock carries active TTS narration ("Now narrating · Voice name", play/pause, tap to open) or active download progress, and collapses into the pill when the dock minimises.
  - **Cinematic:** the bottom bar stays solid `#000000` with a 1 px hairline at 8 % white and never minimises. The top app bar starts transparent over the hero and fades to a black gradient scrim over the first 120 px of scroll (Netflix). Both bars are removed in immersive screens (reader, trailer-style hero autoplay).
- **Badges:** Updates shows the unread count (`GET /updates/notifications/unread-count`); Downloads shows the active count (it already exists, `activeDownloadCountProvider`). Badge counts also go into the semantics label: "Updates, 12 new".
- **Haptics:**
  - Glass: `selectionClick` on every tab change.
  - Cinematic: none on a tab change; `lightImpact` on scroll-to-top.
  - Both: `mediumImpact` when a long-press menu opens.
- **Web desktop:** the dock becomes a sidebar (`mod+b` collapses it; existing). Glass uses a floating translucent rail; Cinematic uses a black rail with the top bar. The same long-press menus open with right-click.

### 3.12 Keyboard-first web

Build on the existing `useShortcut` registry. The command palette and `?` sheet read that registry, so every new binding documents itself.

| Scope | Keys | Action |
|---|---|---|
| Global | `mod+k` | Command palette: navigation, series, commands, recent. Keep the existing fuzzy matcher. |
| Global | `?` | Shortcuts sheet (existing) |
| Global | `/` | Focus search on the current screen (existing) |
| Global | `mod+b` | Toggle sidebar (existing) |
| Global (new chords, 1 s window) | `g h` home · `g l` library · `g s` sources · `g u` updates · `g d` downloads · `g n` novels · `g t` stats · `g p` profiles · `g ,` settings | Linear/GitHub-style go-to. The registry already parses `"g l"` chords. |
| Global (new) | `mod+enter` | Continue reading the most recent series |
| Lists and grids | arrows and `h j k l` (existing grid nav), `enter`/`o` open, `.` or `shift+F10` item menu, `x` select, `shift+x` range select, `esc` clear selection | Roving `tabindex`: one tab stop per grid |
| Rails (Cinematic desktop, TV model) | `←`/`→` within a rail, `↑`/`↓` between rails, keeping the focused column | Each rail is one tab stop. Focus scrolls in with `scrollIntoView({ block: 'nearest', inline: 'nearest' })`. The focused poster scales 1.06 and shows the ring (§5). |
| Tabs | `[` / `]` | Previous or next top tab (§3.2) |
| Rows | `m`, `d`, `x`/`Delete`, `u` | Row actions (§3.7) |
| Reorder | `alt+↑/↓/←/→`, `alt+shift+↑/↓` | Move the focused item (§3.8) |
| Reader and novel | existing map (§1) | Unchanged |

- **Focus after navigation:** move focus to the page `<h1 tabIndex={-1}>`. Next's route announcer then reads the title.
- **Focus after closing:** the palette, menus and sheets return focus to whatever opened them.
- **Discoverability:** buttons that have shortcuts carry `aria-keyshortcuts`, and menus and tooltips show the key hints.
- **Flutter hardware keyboards** (iPad, Android tablets, Bluetooth keyboards): register the same reader and list bindings with `Shortcuts` + `Actions` (`FocusableActionDetector`) so a keyboard behaves identically.

---

## 4. Library reference

### Web

| Package | Version (npm, 2026-09-29) | Published | License | Repo | Verdict |
|---|---|---|---|---|---|
| `motion` (and `framer-motion`) | 13.4.4 | 2026-09-25 | MIT | github.com/motiondivision/motion | **Use**. Migrate from 12.42.2. It covers drag, `Reorder`, springs, `useReducedMotion`, `MotionConfig reducedMotion="user"` and `AnimateView` (13.4.0). |
| `@base-ui/react` | 1.8.0 | 2026-09-04 | MIT | github.com/mui/base-ui | **Use**. Provides Drawer (swipe, snap points, nesting), ContextMenu (long press), Menu, Dialog, Toast (swipe to dismiss). |
| `@use-gesture/react` | 10.3.1 | 2024-03-21 | MIT | github.com/pmndrs/use-gesture | **Use, reader only**, for pinch and wheel normalisation. Drag defaults: swipe 0.5 px/ms, 50 px, 250 ms; drag delay 180 ms; `preventScroll` delay 250 ms; taps threshold 3 px. |
| `vaul` | 1.1.2 | 2024-12-14 | MIT | github.com/emilkowalski/vaul | **Avoid**: the README says it is unmaintained. |
| `cmdk` | 1.1.1 | 2025-03-14 | MIT | github.com/pacocoursey/cmdk | **Skip**: the repo already has `CommandPalette` with fuzzy search. |
| `tinykeys` | 4.0.1 | — | MIT | github.com/jamiebuilds/tinykeys | **Skip**: the repo already has `lib/keyboard` with chords. |
| `@dnd-kit/core` / `@dnd-kit/react` | 6.3.1 / 0.5.0 | 2024-12 / 2026-06 | MIT | github.com/clauderic/dnd-kit | **Skip for now** (§3.8). |
| `@atlaskit/pragmatic-drag-and-drop` | 4.0.0 | — | Apache-2.0 | github.com/atlassian/pragmatic-drag-and-drop | Skip: aimed at cross-window and file drag, which is not needed here. |
| `react-zoom-pan-pinch` | 4.2.0 | 2026-09-03 | MIT | github.com/BetterTyped/react-zoom-pan-pinch | Fallback for the paged-mode viewer only. |
| `embla-carousel-react` | 8.6.0 | 2025-04-04 | MIT | github.com/davidjerleke/embla-carousel | Skip: CSS scroll-snap covers the pager and rails. |
| `ios-haptics` / `web-haptics` | 3.2.0 / 0.0.6 | — | MIT | github.com/tijnjh/ios-haptics, github.com/lochie/web-haptics | Reference only. Write the roughly 10-line switch-input trick inline. |

### Flutter

| Package | Version (pub.dev, 2026-09-29) | Published | License | Repo | Verdict |
|---|---|---|---|---|---|
| framework 3.44.6 | — | — | BSD-3 | github.com/flutter/flutter | `CupertinoPageRoute`, `CupertinoSheetRoute`, `CupertinoContextMenu`, `CupertinoSliverRefreshControl`, `PredictiveBack*PageTransitionsBuilder`, `PopScope`, `Dismissible`, `ReorderableListView`, `InteractiveViewer`, `DraggableScrollableSheet`, `TabBarView`, `HapticFeedback` (incl. `success`/`warning`/`errorNotification`), `SemanticsService.sendAnnouncement`, `SpringDescription.withDurationAndBounce`. |
| `swipeable_page_route` | 0.4.8 | 2026-01-02 | MIT | github.com/JonasWanke/swipeable_page_route | **Use** for iOS back in both skins. Provides `SwipeablePage` for go_router, `SwipeablePageTransitionsBuilder`, `MorphingAppBar`. |
| `custom_refresh_indicator` | 4.0.2 | 2026-08-18 | MIT | github.com/gonuit/flutter-custom-refresh-indicator | **Use** for Cinematic pull-to-refresh. |
| `extended_image` | 10.1.0 | 2026-07-12 | MIT | github.com/fluttercandies/extended_image | **Use** for image viewers (slide-out, pinch, double tap, paging). |
| `flutter_reorderable_grid_view` | 5.7.0 | 2026-05-31 | BSD-3 | github.com/karvulf/flutter-reorderable-grid-view | **Use** for poster-grid reorder. |
| `smooth_sheets` | 1.2.0 | 2026-09-07 | MIT | github.com/fujidaiti/smooth_sheets | **On demand** if built-in detents stutter. |
| `flutter_slidable` | 4.0.3 | 2025-09-27 | MIT | github.com/letsar/flutter_slidable | **On demand** for multi-action rows. |
| `animations` | 3.0.0 | 2026-08-19 | BSD-3 | github.com/flutter/packages | Optional: `OpenContainer` (poster to series page, Cinematic), `SharedAxisTransition`. |
| `haptic_feedback` / `gaimon` | 0.8.0 / 1.5.0 | 2026-09-26 / 2026-08-30 | BSD-3 / MIT | github.com/nohli/haptic_feedback, github.com/istornz/Gaimon | Skip: the built-in API plus a 15-line Android channel is enough. Gaimon only if custom AHAP patterns are wanted. |
| `go_router` | 18.0.2 (repo pins ^14) | 2026-09-28 | BSD-3 | flutter/packages | Upgrade during the redesign. `pageBuilder` plus `StatefulShellRoute` are the integration points. |
| `super_context_menu` | 0.9.1 | 2025-06-11 | MIT | github.com/superlistapp/super_native_extensions | **Avoid** (Rust build, see §3.6). |
| `pull_down_button` | 0.10.2 | 2024-09-30 | MIT | github.com/notDmDrl/pull_down_button | **Avoid** (discontinued). |
| `photo_view`, `dismissible_page`, `modal_bottom_sheet`, `reorderables` | 0.15.0, 1.0.2, 3.0.0, 0.6.0 | 2023–2024 | MIT | — | **Avoid** (stale). |

---

## 5. Accessibility rules (both skins, all platforms)

1. **Hit size.**
   - At least 44 × 44 pt on iOS and web touch (Apple HIG; WCAG 2.5.5 AAA). At least 48 × 48 dp on Android (Material; Flutter `kMinInteractiveDimension` 48, `MaterialTapTargetSize.padded`). Never below 24 × 24 CSS px anywhere (WCAG 2.5.8 AA).
   - Icons may be drawn at 20 to 24 px. The hit area grows through padding (web: `::before { content: ''; position: absolute; inset: -10px }`; Flutter: `SizedBox(48×48)` + `Center`).
   - Keep at least 8 px between adjacent targets.
   - The scrub rail and edge strips are hit areas, not visuals, and have to meet the same minimum.
2. **Focus rings.**
   - Show them on `:focus-visible` only (Flutter: `FocusManager.instance.highlightMode == FocusHighlightMode.traditional`).
   - Ring: 2 px solid, 2 px offset, contrast at least 3:1 against both the AMOLED `#000000` page and the component (WCAG 2.4.7 AA, 2.4.13 AAA guidance).
   - Cinematic uses `#FFFFFF` with a poster scale of 1.06. Glass uses `rgba(255,255,255,0.92)` plus a 6 px outer glow at 24 % white.
   - The ring must never be clipped by `overflow: hidden` rails: pad the rail by 8 px vertically.
   - Focused items must not hide under the sticky dock or top bar (WCAG 2.4.11 AA): use `scroll-padding-block` equal to the bar heights.
3. **Every gesture has a single-pointer, non-drag, visible alternative** (WCAG 2.5.1 and 2.5.7 AA). The mapping is spelled out per gesture in §3: back button, sheet close button, `⋯` menus, Move up/down, zoom buttons, refresh button, tappable tabs.
4. **Character-key shortcuts** (WCAG 2.1.4 A). Add a "Single-key shortcuts" switch to Settings › Shortcuts (`components/settings/keyboard-shortcuts-panel.tsx`), default on. When it is off, the registry skips bindings with no modifier (`j`, `k`, `?`, `/`, `g …`, `m`, `x`, and so on). `mod+…` combos stay. Shortcuts never fire while typing (the existing `allowInInput` default).
5. **Screen readers.**
   - Every icon-only control has a label (web `aria-label`; Flutter `Semantics(label:)` / `tooltip:`).
   - Swipe actions are exposed as custom actions (§3.7). Reorder moves are announced.
   - Reader page changes are **not** announced per page (too chatty for webtoons). Chapter changes are, along with a page counter reachable on demand.
   - The auto-hide timeout and any 3 s dismissals turn off while a screen reader is active (`MediaQuery.accessibleNavigationOf`).
   - VoiceOver and TalkBack long-press (double-tap and hold) reaches `onLongPress`. `GestureDetector` exposes `SemanticsAction.longPress` automatically; the web `⋯` button covers it there.
6. **Haptics are optional feedback, never the only signal.** Every haptic is paired with a visual state change. A single per-skin toggle mutes everything (the existing `Haptics(enabled:)` pattern).
7. **Pointer cancellation** (WCAG 2.5.2): actions fire on up or release, not down, except the drag start itself. Dragging back past the threshold cancels a swipe commit, and a haptic marks the crossing back.

---

## 6. Reduced motion

- **Sources.**
  - Web: `prefers-reduced-motion: reduce`, with `<MotionConfig reducedMotion="user">` at the root (Motion then drops transform and layout animations and keeps opacity) and `useReducedMotion()` for custom code. View-transition CSS goes inside `@media (prefers-reduced-motion: no-preference)`.
  - Flutter: `MediaQuery.disableAnimationsOf(context)`. Android fills it from the animator/transition scale set to 0. On iOS, also read `PlatformDispatcher.instance.accessibilityFeatures.reduceMotion`, which is iOS-only and "certain animations simplified, parallax removed", and treat either as reduce.
  - The existing `--shape-motion` multiplier (0 to 1) in `globals.css` stays as the in-app override.
- **Principle:** gestures keep tracking the finger 1:1, because direct manipulation is not decorative motion. Everything the app animates **by itself** after release or on a button press becomes an opacity cross-fade of at most 150 ms, or an instant change.

| Element | Normal | Reduced |
|---|---|---|
| Route push/pop (buttons) | skin transition (slide, parallax, scale, blur) | 150 ms cross-fade |
| Back swipe (finger) | tracks, then spring release | tracks, then 150 ms fade to finish |
| Android predictive back | system and Flutter builders | leave to the OS. Android's "remove animations" already shortens them. |
| Sheet open/close | spring or ease plus background scale | fade + 16 px translate, 150 ms, no background scale |
| Shared-element cover flight | `ViewTransition` morph / `Hero` | cross-fade only (`share="none"` / `HeroMode(enabled: false)`) |
| Context-menu lift | scale to 1.04–1.15 | no scale; the menu fades in over 100 ms |
| Desktop hover card (Cinematic) | expand to 1.35× | static info panel |
| Glass tilt and specular | pointer-tracked | off |
| Pull-to-refresh | stretch, droplet, light-leak | the indicator appears at rest height; the spinner stays |
| Tab indicator | slides with the drag | jumps on settle |
| Reorder siblings | animate layout | jump |
| Panel-by-panel camera | dolly or spring | cut |
| Dock minimise (Glass) | morph to pill | instant swap |
| Heading letter reveal / 50 ms typing reveal (decisions file) | staggered | full text immediately |
| Hero autoplay / Ken Burns | on | off (still frame) |

---

## 7. Matrices

### 7a. Gesture × platform: mechanism and availability

`C:` and `G:` mark where the skins differ. "—" means not offered on that platform: a visible alternative covers it instead.

| Gesture | Web desktop | Web mobile (PWA) | iOS (Flutter) | Android (Flutter) |
|---|---|---|---|---|
| Back | back button, `esc`; `alt+←` belongs to the browser; trackpad swipe = browser history (keep `overscroll-behavior-x` off the root) | OS/UA back through history; sheets are history entries; `<ViewTransition>` with `nav-*` types | `SwipeablePage`. C: 20 pt edge. G: full width (iOS 26). Reader: edge only | predictive back. C: `…Fullscreen…Builder`. G: `PredictiveBackPageTransitionsBuilder`. Needs the manifest flag. |
| Swipe between top tabs | — (click, `[` `]`, arrows) | CSS scroll-snap pager | `TabBarView`. C: stretch underline. G: glass capsule + tick | same as iOS |
| Pull to refresh | — (`r`, button, palette) | custom pointer code. C: 96 px, `c` 0.35. G: 100 px, `c` 0.55 | G: `CupertinoSliverRefreshControl`. C: `custom_refresh_indicator` | same; G forces bouncing physics |
| Sheet drag / detents / dismiss | — (side panel or dialog; `esc`) | Base UI `Drawer`. C: full-bleed, no bounce. G: inset + detents + background scale | G: `CupertinoSheetRoute` / detent sheet. C: modal sheet 450 ms | same widgets; Android back closes |
| Image swipe-dismiss | — (`esc`, click backdrop) | Motion drag-y + `ViewTransition` | `extended_image` slide page + `Hero` | same |
| Long-press preview | right-click → same Base UI `ContextMenu`; hover card (C: expand, G: tilt) | Base UI `ContextMenu` long press with preview card | G: `CupertinoContextMenu`. C: long press → Quick Look sheet | same as iOS |
| Swipe row actions | — (hover icons, `m` `d` `x`) | Motion drag-x (coarse pointer only) | `Dismissible` / `flutter_slidable` | same |
| Drag to reorder | Motion `Reorder` + `alt+arrows` | Motion `Reorder` (long press 500 ms or handle) | `ReorderableListView`, reorderable grid | same |
| Pinch zoom | `ctrl+wheel` / Safari `GestureEvent` via `usePinch`; `=` `-` `0` | `usePinch`, `touch-action: pan-y` | `ScaleGestureRecognizer` (strip) / `InteractiveViewer` (pages) | same |
| Double tap | double-click toggles zoom | 300 ms / 24 px detector | timestamp detector (existing contract) | same |
| Reader tap zones | click zones + keys | tap zones | tap zones | tap zones |
| Dock: tap active | sidebar item: pop to root or scroll top | pop to root, scroll top, focus search | same | same |
| Dock: long press | right-click the sidebar item | long press → menu or sheet | G: context menu from the tab. C: sheet | same |
| Dock: minimise on scroll | — | G: pill + accessory. C: static | G: pill + accessory. C: static bar, fading top scrim | same |
| Keyboard nav | full (§3.12) | external keyboard: same map | `Shortcuts`/`Actions` for the reader and lists | same |
| Haptics | — | Android `vibrate`; iOS 18+ switch trick | `HapticFeedback` | `HapticFeedback` + API 34 constants via channel |

### 7b. Gesture × skin: feel

| Gesture | Cinematic | Glass |
|---|---|---|
| Back (push/pop) | Incoming slides from the edge; outgoing drifts 30 %, scales to 0.94, dims to 60 % black. Spring 420 ms, bounce 0. | Parallax slide at 1/3, chrome title cross-fade. Spring 380 ms, bounce 0.18. Full-width swipe on iOS. |
| Top tabs | 2 px stretching underline; label jumps from 60 % to 100 % white; no haptic | sliding glass capsule; `selectionClick` on settle |
| Pull to refresh | light-leak bar plus leader ring; 96 px trigger; `mediumImpact` | liquid droplet meniscus; 100 px trigger; `lightImpact` |
| Sheets | full-bleed black; backdrop `rgba(0,0,0,.72)`; stage does not shrink; 450 ms `(0.32, 0.72, 0, 1)` | inset floating glass; background scales to 0.92 with radius 12; detents `[0.45, 1]`; tick per detent |
| Image dismiss | no scale; backdrop fades; letterbox bars retract | scales to 0.85, radius 0 → 28, blur 24 → 0 |
| Long press | poster lifts to 1.04, then a Quick Look sheet with hero backdrop; desktop hover expands to 1.35× | preview grows to 1.15 with menu (800 ms); desktop tilt ≤ 6° with specular |
| Row actions | flat colour slabs | inflating glass pills |
| Reorder lift | scale 1.03, black shadow 60 % at blur 24; drop `mediumImpact` | scale 1.05, bright rim; tick per slot; drop `lightImpact` |
| Zoom release | no bounce, `c` 0.35 | bounce 0.18, `c` 0.55 |
| Panel camera | 520 ms `(0.65, 0, 0.35, 1)` dolly | spring 0.45 s, bounce 0.1 |
| Dock | solid black bar with hairline; never minimises; top bar scrim fades in over 120 px | floating capsule; minimises to a pill after 32 px down; bottom accessory for TTS or downloads |
| Haptic density | commits only, heavier | every tick, lighter |
| Focus ring | `#FFF` 2 px + poster scale 1.06 | 92 % white 2 px + 6 px glow |

---

## 8. Pitfalls to design around

- **Gesture arena conflicts in Flutter.**
  - A horizontal `PageView` or `TabBarView` or a rail inside a route with full-width swipe-back: back has to lose until the child scroller reaches its leading edge (issue #184507 class).
  - `InteractiveViewer` inside a scrollable: disable the scroller's physics while zoomed.
  - `GestureDetector.onDoubleTap` delays every single tap by 300 ms: keep the timestamp detector wherever single taps must feel instant.
- **Web `touch-action`.** The reader strip uses `pan-y`; row swipes use `pan-y`; pinch surfaces use `pan-y` (the vertical strip) or `none` (a full-screen page viewer only). Never set `touch-action: none` on a scroll container.
- **Web root overscroll.** Only the y axis should be `none` on the root (§1). Every horizontal rail, pager or row-swipe container gets `overscroll-behavior-x: contain` so edge flicks never become history navigation.
- **iOS link callout.** Long-press targets need `-webkit-touch-callout: none` and `user-select: none`, or Safari's preview competes with the context menu.
- **Transitions playing twice.** With a UA back animation (iOS swipe, Chrome Android back preview), skip the in-app animation: `default: "none"` for untyped navigations, and check `event.hasUAVisualTransition` in any `popstate` handler.
- **Predictive back and custom routes.** A go_router `CustomTransitionPage` bypasses `PageTransitionsTheme`, and predictive back with it. On Android, pushed screens must be `MaterialPage` (or a page whose route implements the predictive-back builders), or back pops without the preview.
- **FlutterFragmentActivity.** Keep `FlutterActivity`; predictive back transitions are reported broken with `FlutterFragmentActivity` (issue #192551, 3.41.9).
- **Skin switch restarts the app.** Read the skin once before `runApp` (Flutter) or on the server from a cookie (web, as `data-skin` on `<html>`). Then build the `PageTransitionsTheme`, `ScrollBehavior`, page builders and the table in §3 from one constant map per skin. Nothing needs to switch at runtime.

---

## Sources

- Flutter framework source at tag `3.44.6`: `cupertino/route.dart`, `cupertino/sheet.dart`, `cupertino/context_menu.dart`, `cupertino/refresh.dart`, `material/refresh_indicator.dart`, `material/bottom_sheet.dart`, `material/predictive_back_page_transitions_builder.dart`, `gestures/constants.dart`, `widgets/dismissible.dart`, `widgets/interactive_viewer.dart`, `services/haptic_feedback.dart`, `physics/spring_simulation.dart`, `widgets/media_query.dart`, `flutter_tools/gradle/.../FlutterExtension.kt` (github.com/flutter/flutter)
- [Default Android page transition is now PredictiveBackPageTransitionsBuilder](https://docs.flutter.dev/release/breaking-changes/default-android-page-transition)
- [PredictiveBackFullscreenPageTransitionsBuilder](https://api.flutter.dev/flutter/material/PredictiveBackFullscreenPageTransitionsBuilder-class.html)
- [flutter/flutter#180309 iOS 26 back gesture area](https://github.com/flutter/flutter/issues/180309)
- [flutter/flutter#184507 interactiveContentPopGestureRecognizer conflicts](https://github.com/flutter/flutter/issues/184507)
- [flutter/flutter#192551 predictive back with FlutterFragmentActivity](https://github.com/flutter/flutter/issues/192551)
- [AccessibilityFeatures](https://api.flutter.dev/flutter/dart-ui/AccessibilityFeatures-class.html)
- [Android predictive back design](https://developer.android.com/design/ui/mobile/guides/patterns/predictive-back)
- [Android 16 behaviour changes](https://developer.android.com/about/versions/16/behavior-changes-16)
- [Donny Wals, tab bars on iOS 26](https://www.donnywals.com/exploring-tab-bars-on-ios-26-with-liquid-glass/)
- [WWDC25 Build a UIKit app with the new design](https://developer.apple.com/videos/play/wwdc2025/284/)
- [Base UI Drawer](https://base-ui.com/react/components/drawer.md)
- [Base UI Context Menu](https://base-ui.com/react/components/context-menu.md)
- [vaul README](https://github.com/emilkowalski/vaul)
- [Motion CHANGELOG](https://github.com/motiondivision/motion/blob/main/CHANGELOG.md)
- [Motion drag](https://motion.dev/docs/react-drag)
- Motion source `gestures/drag/*`
- use-gesture source `dragConfigResolver.ts`
- [Next.js view transitions guide](https://nextjs.org/docs/app/guides/view-transitions)
- [React 19.3](https://react.dev/blog/2026/09/09/react-19-3)
- [MDN CloseWatcher](https://developer.mozilla.org/en-US/docs/Web/API/CloseWatcher)
- MDN browser-compat-data (`api/CloseWatcher`, `api/Document.startViewTransition`, `html/elements/dialog.closedby`, `api/Navigation`, `api/PopStateEvent.hasUAVisualTransition`, `api/Navigator.vibrate`, `html/elements/input.switch`, `api/GestureEvent`)
- [WCAG 2.2](https://www.w3.org/TR/WCAG22/)
- [iOS PWA limitations 2026](https://www.magicbell.com/blog/pwa-ios-limitations-safari-support-complete-guide)
- [PWA edge swipe-back fix (history + overscroll)](https://github.com/Pshenovich/assistent/pull/6)
- [swipeable_page_route](https://github.com/JonasWanke/swipeable_page_route)
- [super_native_extensions / cargokit](https://matejknopp.com/post/flutter_plugin_in_rust_with_no_prebuilt_binaries/)
- npm registry and pub.dev API (versions, dates, licenses) queried 2026-09-29
