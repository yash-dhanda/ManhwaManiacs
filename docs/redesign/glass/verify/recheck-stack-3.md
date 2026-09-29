# Recheck round 3: Glass stack lens (`judge-stack.md`, section "Confirmed")

Method: I re-checked all 28 confirmed findings against the live `glass/DESIGN.md`, which now has 4,611 lines (round 3 added 5). For each finding I re-ran the anchor greps for the text the judge's final fix requires. I read in full every region round 3 edited, as listed in `fixed-stack.md` "Round 3":

- the manifesto (l. 5 and 44);
- §4.1 law 5 (l. 1034);
- §4.9 (l. 1175–1184);
- the §4.10 **Catch** row (l. 1222) and `motion.catch` (l. 1420);
- §7.10 **Physics** and **The on-screen keyboard** (l. 1728, 1747–1750);
- §8.0.5 (l. 2238–2252);
- the §15.3 tree and **Sheets** (l. 4212, 4231–4241).

I also re-ran the old-value greps over the whole file. The STACK-6 mechanism was checked against its primary sources:

- `smooth_sheets` 1.2.0 in `design-ref/flutter/smooth_sheets` (`modal.dart`, `model.dart`, `sheet.dart`, `controller.dart`, `offset_driven_animation.dart`, `paged_sheet.dart`);
- the local Flutter 3.44.6 SDK (`widgets/routes.dart`, `widgets/navigator.dart`, `widgets/binding.dart`, `material/predictive_back_page_transitions_builder.dart`).

Line numbers are from the live file.

Result: **27 resolved, 1 unresolved (STACK-6).**

- Round 2's STACK-6 defect is fixed. §15.3 **Sheets** now drops the mixin's `SlideTransition` and presents the sheet by animating its own offset, and the SDK and library sources confirm that a touch catches that animation:
  - `SheetModel.animateTo` runs an `AnimatedSheetActivity` (`model.dart:478–494`), and `drag()` replaces it with a `DragSheetActivity` through `beginActivity` (`model.dart:318, 455–462`).
  - A route moving forward does not ignore input. `_ModalScopeState` ignores pointers only on `AnimationStatus.reverse` or during a user gesture (`routes.dart:1154–1156, 1220–1222`), and the barrier only when the route is not moving forward or complete (`routes.dart:2278–2281`).
  - A page removed by go_router is popped through `didPop`: `DefaultTransitionDelegate` calls `markForPop` on the last exiting page route (`navigator.dart:1206`).
  - `popGestureEnabled` needs `animation.isCompleted` (`routes.dart:1910–1929`).
  - `barrierBuilder` exists on `ModalSheetRoute` (`modal.dart:158, 190, 328`).
  - `initialOffset` is a `Sheet` parameter (`sheet.dart:60, 72`).
  - `SheetOffsetDrivenAnimation` takes `controller`, `initialValue`, `startOffset` and `endOffset`.
  - Round 2's O1 and O2 are closed as well. The `GlassModalSheet` aside is gone from §7.10, and **Sheets** *Keyboard* names `GlassSheetBody` and a 342 ms `Duration` with a sampled `Curve`.
- STACK-6 is still unresolved, for two reasons. Both are set out below:
  - (a) Round 3 made a new exception to the catch rule: a sheet close that pops the sheet route first runs to completion. That exception is stated only in §4.9's first bullet and §15.3. Law 5, the manifesto, the §4.9 `committed` row and the §4.10 **Catch** row still give exhaustive exception lists without it, and law 5 now says outright that a sheet is not a page route.
  - (b) The *Android predictive back* override is never called. The SDK forwards predictive back events to a route only through `_PredictiveBackGestureDetector`, which a route builds inside its transitions. `GlassSheetRoute.buildTransitions` now returns `child` unchanged, so no detector exists for a sheet.

---

## Old values that must be gone (live-file grep counts)

| Old value | Count | Note |
|---|---|---|
| `flutter_soloud` 5.x (`5.1.4`) | 0 | The one `5.1.4` hit is "glass-1 §5.1.4" in Appendix A (l. 4483), a section reference |
| `share_plus` `13.3.0` | 0 | |
| `phosphor_flutter` as a dependency | 0 | 4 hits, all "not used" or "from its 2.1.0 archive" (l. 479, 481, 4347, 4462) |
| `GlassModalSheet` as the sheet | 0 | 3 hits: §2.3 `rSheet` (the helper's origin, l. 319), §15.3 **Sheets** ("is not used", l. 4231), G15 (l. 4431). The §7.10 aside (round 2's O1) is gone |
| `stupid_simple_sheet` in use | 0 | 2 hits (G15, and the §15.11 `smooth_sheets` row), both "not used by Glass" |
| `GET /reader/panels`, `panels_ready`, `/app/media/` | 0 / 0 / 0 | |
| "(the category narration uses today …)" | 0 | |
| `duckOthers` on narration | 0 | 1 hit, "no `duckOthers`" (l. 1561) |
| `offline-fallback.html` (both skins in one file) | 0 | 3 hits, all `offline-fallback-glass.html` (l. 3148, 4193, 4577) |
| "eight `BackdropGroup` members" | 0 | 5 `BackdropGroup` hits, all about the 1.7.2 per-layer wrap or the frosted-fallback path |
| `cover-{sourceId}-{seriesKey}` | 0 | |
| `tag_ids` as a row field | 0 | 3 hits, all the `GET /library/series` query parameter |
| `{id, name, color}` | 0 | |
| `mm/haptics` as Glass's channel | 0 | 1 hit, G16 |
| `sox` "CI tool" / "(CI image)" | 0 / 0 | |
| Base UI "Toast primitives", "reader pinch only" | 0 / 0 | |
| `POST /library/taste/seed` | 0 | |
| `.on-glass` utility, `"opsz" auto` | 0 / 0 | |
| `macos-latest`, `xcode: latest` | 0 / 0 | |
| `GlassIcon CinematicIcon` as iOS names | 0 | The one `GlassIcon` hit is Android's `.GlassIcon` `activity-alias` (l. 3908), which is correct |
| "`LiquidGlassWidgets.initialize()` before `runApp`" | 0 | The one "before `runApp`" hit is the web first-paint script (l. 2329) |
| `build-motion-names.mjs`, `minDragDistance` | 0 / 0 | |
| "a back swipe during a push grabs the incoming page" | 0 | |
| "Everything is catchable", "every moving thing" | 0 / 0 | |
| "each surface's dim and grade … registered" | 0 | The one "dim and grade" hit is §15.4 `currentPageSample` (l. 4254), which is unrelated |
| "haptics through gaimon" | 0 | |
| "`DELETE /circle/activity` (Glass addition)" | 0 | The "Glass addition" hits label `use_taste`, `show_presence`, `share_streak`, `box=sent`, `series_count` and `content_kind` |
| Round 3: `barrierColor` on the sheet route | 0 | |
| Round 3: bare `GlassSheet` (the undeclared class) | 0 | `GlassSheetBody`, `GlassSheetPage` and `GlassSheetRoute` are declared in the §15.3 tree (l. 4212) |
| Round 3: "route push or pop" / "route pushes and pops" without "page-" | 0 / 0 | 4 + 2 hits, all "page-route" (l. 5, 44, 1034, 1175, 1179, 1222) |
| Round 3: the judge's stale `transitionDuration` 494 ms | 0 | The one `494` hit is the `model.dart:478–494` citation |
| Round 3: a sheet driven by `SlideTransition` | 0 | 1 hit, the sentence that drops it (l. 4233) |

Repeated values that round 3 touched all agree:

- `sheet` settles in 447 ms: §2.8 l. 797, §4.2 l. 1054, §4.10 l. 1208 and §15.3 l. 4232 and 4234.
- `dismiss` settles in 378 ms: §2.8 l. 803, §4.2 l. 1060 and §15.3 l. 4232, 4235 and 4236.
- `sheetSnap` settles in 342 ms, with k 223.8 and c 26.33: l. 798, 1055, 4237 and 4241.
- `colorDimSheet` is `Color(0x47000000)`, which is 0.28 (l. 167, 620, 4232).
- `springSheet`, `springSheetSnap` and `springDismiss` use the Dart token names of §2.8.

---

## Per finding

| ID | Verdict | Evidence |
|---|---|---|
| STACK-1 | Resolved | `flutter_soloud` 4.1.7 appears in §6 **Playback** (l. 1553), §9.4.2 **Recorded layers** and **Playback engines** (l. 3464, 3472), §15.3 **Packages** (l. 4230) and the §15.11 row (l. 4461). The row carries the `native_toolchain_c ^0.19.4` → `meta ^1.19.0` reason and "stack risk 10". |
| STACK-2 | Resolved | `share_plus` 12.0.2 appears in §9.2.4 (l. 3359), §15.3 (l. 4230) and §15.11 (l. 4464), with the `win32 ^6` versus `^5` reason. `sharePositionOrigin` is still present (l. 2006, 3364). |
| STACK-3 | Resolved | §2.7 (l. 479–483) lists six TTFs including `Phosphor-Thin.ttf`, the `Phosphor…` families, `phosphor.g.dart` with plain constants, codepoints from `phosphor_icons_*.dart`, and `PhosphorDuotoneIcon`. §15.3 **Fonts**, §15.6 (l. 4347) and §15.11 "not used" (l. 4462) agree. |
| STACK-4 | Resolved | §15.4 `panelBoxes` (l. 4258) is "not a second detector output". `POST /reader/panels` is at l. 3477, and `GET /reader/panels` has 0 hits. |
| STACK-5 | Resolved | §15.2 **Sheet host** (l. 4189) keeps at most two entries, pushes with `pushState({ mmSheet: id, base, parent: previousId })`, scales the lower sheet to 0.9165, pops only the top on `popstate`, and uses `replaceState` for a third. |
| STACK-6 | **Unresolved** | Round 2's defect is fixed: see the result above. Two problems remain. **(a) The catch-rule exception is not propagated.** §4.9 l. 1179 and §15.3 *Pops from outside the sheet* (l. 4236) make a sheet close that pops the route first (Android back, Esc, a go_router location change) run to completion, and the SDK confirms it: a reversing route ignores pointers (`routes.dart:1154–1156, 1220–1222`). Law 5 (l. 1034) still says "Any spring in flight on an object (a sheet, …) can be grabbed … The exceptions are page-route pushes and pops, and the web poster zoom", and adds "A sheet is not a page route". Read literally, law 5 says a sheet closing on Android back can be grabbed. Four more places have the same gap. The manifesto says "**only** a page-route push or pop, and the web poster zoom, runs to completion" (l. 5, l. 44). The §4.9 `committed` row says "can still be caught only for sheets …; a page-route push or pop is never caught" (l. 1175). The §4.10 **Catch** row (l. 1222) has the same wording. **(b) The predictive-back override has no caller.** §15.3 *Android predictive back* (l. 4240) and the §8.0.5 Android row (l. 2243, "sheets shrink by back progress") rely on `GlassSheetRoute.handleUpdateBackGestureProgress`. In Flutter 3.44.6 the only code that forwards `PredictiveBackEvent`s to a route is `_PredictiveBackGestureDetector` (`material/predictive_back_page_transitions_builder.dart:256–272`). It is a `WidgetsBindingObserver` that a route builds inside its transitions; `binding.dart:1148–1180` dispatches only to such observers. `ModalSheetRoute` does not go through the `PageTransitionsTheme`, `smooth_sheets` 1.2.0 has a detector only for `paged_sheet.dart`'s pages, and l. 4233 now says `buildTransitions` returns `child` unchanged. The detector copy in §8.0.5 **Gesture detector** (l. 2249) wraps only `MaterialPage`s through `GlassPageTransitionsBuilder`. The detector in the page below the sheet stays inactive, because that route is not current. So on a sheet nothing handles the gesture's start, the sheet never shrinks, and on commit `_handleCommitBackGesture` falls back to `handlePopRoute` (`binding.dart:1195–1204`): the sheet just closes on its 378 ms pop. |
| STACK-7 | Resolved | §6 **One audio session, one owner** (l. 1555) names the shared `skins/skin_audio.dart`. The `narration` row (l. 1561) is `AudioSessionConfiguration.speech()` with no `duckOthers`. The §15.6 **Audio session** row is at l. 4348. |
| STACK-8 | Resolved | §9.4.2 (l. 3464): the apps always fetch Opus `.ogg`. `.m4a` is fetched only when `canPlayType('audio/ogg; codecs="opus"') === ""`, before `decodeAudioData`. |
| STACK-9 | Resolved | A byte-range `FileResponse` with `audio/ogg` / `audio/mp4` on `GET /app/soundscapes/{id}.{ext}` (l. 3464, 4300). |
| STACK-10 | Resolved | The 11-id union, and Glass's nine ids in §8.7 step 5's order, at l. 4291 and 4352. |
| STACK-11 | Resolved | `{ type: "skin", skin: "glass" }` and `{ type: "skin-changed", skin: "cinematic" }` (l. 3015, 4193). `offline-fallback-glass.html` in §8.28 (l. 3148) and Appendix B (l. 4577). |
| STACK-12 | Resolved | 6 layers / 8 shapes in §2.4.1 (l. 360), §2.5 (l. 461), §8.25.12 (l. 3091), §15.7 (l. 4358, 4366) and G10 (l. 4426). The table's worst rows are 4 / 8, 4 / 7 and 6 / 6 (l. 4370–4375). O6 is still open. |
| STACK-13 | Resolved | §15.3 **Accessibility scope** (l. 4242): `reduceTransparency: false`, precedence over the global flags, `solid1` / `solid2` drawn by `SkinGlass`, no `wrap()`, and `adaptiveQuality` left at `false`. |
| STACK-14 | Resolved | §2.4.1 (l. 362–367) has a map per group keyed by the shape list, 4 per-tab dock maps plus a base map, "No map is built mid-motion" (l. 365), a mask-only neck, and the Backdrop Root rule (l. 367). O3 is still open. |
| STACK-15 | Resolved | Law 5, §4.9, §4.10 **Catch** and `motion.catch` name the same catchable set, and all exempt page-route pushes and pops and the web poster zoom. The web-velocity bullet is at l. 1184. (The new sheet-route exception that these lists lack is counted under STACK-6 (a), because round 3's STACK-6 edit made it.) |
| STACK-16 | Resolved | §7.37 (l. 2072–2073) has `mmSeq` via `replaceState({ ...history.state, mmSeq: seq }, "")`, the contiguity test and `history.go(−n)`, and otherwise `router.push` plus a trim. §8.0.4 (l. 2232) has `router.push(lastPathOf(tab), { scroll: false })`. |
| STACK-17 | Resolved | §9.2.4 (l. 3361–3362) uses the `style.fontFamily` names and `gsf-share-display.woff2` at `wght=720 ROND=100 GRAD=0 opsz=144`, loaded as `FontFace("MMShareDisplay")`. |
| STACK-18 | Resolved | §15.8 **Web gate** (l. 4397): a 10 s fling, mean frame rate within 5 % of refresh, ≤ 2 dropped frames/s, and the renderer-state fallback. |
| STACK-19 | Resolved | `--glass-rond-t` / `--glass-grad-t` are registered and `--glass-rond` / `--glass-grad` stay unregistered (l. 530, 880, 986, 4132, 4161–4162). `font-weight: var(--mm-type-<role>-wght)` is at l. 999. |
| STACK-20 | Resolved | §5 **Libraries** (l. 1360), §8.0.7 (l. 2319) and §15.3 **Native** (l. 4243) route intensity impacts through `mm/platform` `haptics.impact`, `ahap:*` through `gaimon` `patternFromData`, and `selection` through `haptic_feedback` 0.6.5. G16 is at l. 4432. O7 is still open. |
| STACK-21 | Resolved | §15.1 **Generator ownership** (l. 4136) names `build-haptics.mjs`, `lint-utilities.mjs` and `check-contrast.mjs`. §5.3 (l. 1491), §2.8 (l. 531) and G2 (l. 4418) repeat it. `motion.generated.ts` (l. 4145) and `motion_names.g.dart` (l. 4201) are in the trees. |
| STACK-22 | Resolved | §15.11 has `fantasticon` (l. 4451), `@resvg/resvg-js` (l. 4452), `sox` "authoring only" (l. 4453) and `@use-gesture/react`, whose use grew to "reader, image viewer, Library grid, novel column and guided-view pinch" (l. 4184, 4448). Base UI is "Dialog, Menu, ContextMenu and Popover", and `sonner` `toast.custom` is the one toast system (l. 4184, 4446–4447). |
| STACK-23 | Resolved | `coverTransitionName(sourceId, seriesKey)` at l. 2229, 4185 and 4187, with the helper at `features/sources/cover-transition-name.ts`. |
| STACK-24 | Resolved | `tags: [{id, name, category, color}]` at l. 2202, 2881 and 4301. `DELETE /circle/activity` → 204 is "Cinematic's" (l. 3435). The `streak: {current_days, alive_today}` shape appears at l. 3435 and 4296, and `busiest_day` / `firsts_lasts` at l. 4294. |
| STACK-25 | Resolved | §12.2 (l. 3905) has `setup-xcode@v1` with `xcode-version: '26.0'`, `xcode: 26.0`, `INCLUDE_ALL_APPICON_ASSETS`, `ALTERNATE_APPICON_NAMES = AppIcon-Glass`, and the `actool` dry run. |
| STACK-26 | Resolved | §15.3 **Shader prewarm** (l. 4244): `prepare()` runs once per process and is awaited from `main()` and from the `AppRestart` path. |
| STACK-27 | Resolved | §9.4.2 (l. 3471) gives the uniform order `uSize`, `uTime`, `uDrops[10]`, `uBackdrop`, the `IMPELLER_TARGET_OPENGLES` flip, `isShaderFilterSupported`, and one extra layer. |
| STACK-28 | Resolved | §8.15.4 (l. 2791) has one inert `cloneNode(true)` above the live container, both turn directions, removal on settle or cancel, and no bitmap capture. |

---

## What STACK-6 still needs

**(a) One clause in five places.** Add the route-popping sheet close to every exhaustive exception list:

- **Law 5 (l. 1034):** "The exceptions are page-route pushes and pops, a sheet close that pops its route first (Android back, Esc, a location change; §4.9), and the web poster zoom (a view transition): they run to completion."
- **Manifesto l. 5 and l. 44:** "only a page-route push or pop, a sheet closed by the system back or Esc, and the web poster zoom, run to completion (§4.9)".
- **§4.9 `committed` row (l. 1175) and §4.10 Catch row (l. 1222):** after "a page-route push or pop is never caught" and "never a page-route push or pop", add "nor a sheet whose route is already popping".

Changing the text is the only workable fix. Routing Android back through the button dismiss instead would need `PopScope(canPop: false)`, and that turns off the predictive back the sheet is meant to show.

**(b) Give the sheet route its own detector.** In §15.3 **Sheets** *Present and dismiss* (l. 4233), change "overrides `buildTransitions` to return `child` unchanged" to: "overrides `buildTransitions` to return `child` wrapped only in the §8.0.5 **Gesture detector** copy (no transform), dropping `ModalSheetRouteMixin`'s route-driven `SlideTransition`".

In *Android predictive back* (l. 4240), add: "The detector is what calls the override; a route whose transitions build no detector never receives `PredictiveBackEvent`s (`widgets/binding.dart:1148–1180`)."

Nothing else changes:

- The detector enables itself only when `route.isCurrent && route.popGestureEnabled`, so it still waits for the 447 ms present.
- `TransitionRoute.handleCommitBackGesture` calls `navigator.pop()` (`routes.dart:588–603`), which reaches *Pops from outside the sheet*.
- The default `handleStartBackGesture` sets only the invisible route controller.

---

## Observations (not blocking)

- **O3, from round 1, still open.** §9.4.2 **Rain on glass** (l. 3471) and the `rain.ts` tree row (l. 4170) give web tier A "an animated SVG displacement map on the pill and capsules". That conflicts with "No map is built mid-motion" (l. 365).
- **O5, from the web lens, still open.** §15.2 **Routes** (l. 4185) still puts `nav-forward` / `nav-back` types on `<ViewTransition>`. In Next 16.2 they belong on `<Link>` / `router.push`.
- **O6, from round 2, still open.** The §15.7 "Phone search open" row gives Flutter **3 / 3** (l. 4371). The nav row group alone is three shapes, and §8.9 adds the jump bar, so the real count is 3–4 layers and 5–6 shapes. This is still within the budget.
- **O7, from round 2, still open.** §5 **Libraries** (l. 1360) routes only intensity impacts, `ahap:*` and `selection`. Nothing names the route for the §5.1 impacts that have no intensity, or for the three iOS notifications.
- **O8, new: who owns the controller.** Both the barrier (`buildModalBarrier`, which runs when the route installs) and `GlassSheetRoute.didPop` use the sheet's `SheetController`, but l. 4234 has `GlassSheetBody` "build" it. Say that `GlassSheetRoute` creates the controller in `install()`, disposes it in `dispose()`, and passes it to `GlassSheetBody`.
- **O9, new: the reverse duration is a getter override.** `ModalSheetRoute` 1.2.0 has no `reverseTransitionDuration` constructor parameter (`modal.dart:144–159`), so the 378 ms is an override of `TransitionRoute.reverseTransitionDuration` in `GlassSheetRoute`. The *Route* "Settings" list reads as if it were a constructor argument.
- **O10, from before round 3.** §7.10 **Physics** (l. 1728) presents a sheet "from the trigger's position when the trigger is at the bottom (… a `morph`)". §15.3's Flutter present always raises the sheet from `SheetOffset(0)`, and no Flutter mechanism is given for the morph-from-trigger variant.
