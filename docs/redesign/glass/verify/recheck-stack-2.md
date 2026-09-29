# Recheck round 2: Glass stack lens (`judge-stack.md`, section "Confirmed")

Method: I re-checked all 28 confirmed findings against the live `glass/DESIGN.md` (4,606 lines, the same length as at the end of round 1; the round 2 fixes were edits in place). For each finding I re-ran the anchor greps for the text the judge's final fix requires. I read in full the four places `fixed-stack.md` round 2 edited: the manifesto (l. 5 and 44), §4.1 law 5, §2.8, §8.0.7 and §9.3.7. I also re-ran the old-value greps over the whole file and grepped every place a changed value is repeated. Where a fix depends on a library's behaviour, I rechecked the primary source: the `smooth_sheets` 1.2.0 clone in `design-ref/flutter/smooth_sheets` (`lib/src/modal.dart`, `model.dart`, `activity.dart`, `sheet.dart`). Line numbers are from the live file.

Result: **27 resolved, 1 unresolved (STACK-6).**

- The four round 1 residuals are closed: STACK-15, STACK-19, STACK-20 and STACK-24. In each, the one sentence that repeated the old rule now matches the fix, and no other copy of the old rule remains.
- STACK-6 is reopened. Round 2's law 5 edit now names "a sheet" as catchable in flight, and §4.9 says "touching a sheet in flight catches it". The §15.3 **Sheets** *Route* that STACK-6 wrote cannot do that on Flutter. It presents a sheet with `ModalSheetRoute`'s route-driven `SlideTransition` and sets `swipeDismissible: false`. Details and a fix are below.

---

## Old values that must be gone (live-file grep counts)

| Old value | Count | Note |
|---|---|---|
| `flutter_soloud` 5.x (`5.1.4`) | 0 | The one `5.1.4` hit is "glass-1 §5.1.4" in Appendix A, a section reference |
| `share_plus` `13.3.0` | 0 | |
| `phosphor_flutter` as a dependency | 0 | 4 hits, all "not used" or "from its 2.1.0 archive" (§2.7 l. 479, 481; §15.6 l. 4343; §15.11 l. 4457) |
| `GlassModalSheet` as the sheet | 0 | 4 hits: §2.3 `rSheet` (the helper's origin), §7.10 l. 1748 (an aside, O1), §15.3 **Sheets** ("is not used"), G15 |
| `stupid_simple_sheet` in use | 0 | 2 hits, G15 and the §15.11 `smooth_sheets` row, both "not used by Glass" |
| `GET /reader/panels`, `panels_ready`, `/app/media/` | 0 / 0 / 0 | |
| "(the category narration uses today …)" | 0 | |
| `duckOthers` on narration | 0 | 1 hit, "no `duckOthers`" (l. 1561) |
| `offline-fallback.html` (both skins in one file) | 0 | 3 hits, all `offline-fallback-glass.html` |
| "eight `BackdropGroup` members" | 0 | The 5 `BackdropGroup` hits are the 1.7.2 per-layer wrap and the frosted-fallback path |
| `cover-{sourceId}-{seriesKey}` | 0 | |
| `tag_ids` as a row field | 0 | 3 hits, all the `GET /library/series` query parameter |
| `{id, name, color}` (PRODUCT-27's tag shape) | 0 | |
| `mm/haptics` as Glass's channel | 0 | 1 hit, G16 |
| `sox` "CI tool" / "(CI image)" | 0 / 0 | |
| Base UI "Toast primitives", "reader pinch only" | 0 / 0 | |
| `POST /library/taste/seed` | 0 | |
| `.on-glass` utility, `"opsz" auto` | 0 / 0 | The 2 `on-glass` hits are the `color.onGlass` and `color.wellOnGlass` tokens |
| `macos-latest`, `xcode: latest` | 0 / 0 | |
| `GlassIcon CinematicIcon` as iOS names | 0 | |
| "`LiquidGlassWidgets.initialize()` before `runApp`" | 0 | The one "before `runApp`" hit is the web first-paint script (l. 2329) |
| `build-motion-names.mjs`, `minDragDistance` | 0 / 0 | |
| "a back swipe during a push grabs the incoming page" | 0 | |
| "Everything is catchable", "every moving thing" | 0 / 0 | Round 1 residual, now gone |
| "each surface's dim and grade … registered" | 0 | Round 1 residual. The one "dim and grade" hit is §15.4 `currentPageSample` (l. 4250), which is unrelated |
| "haptics through gaimon" | 0 | Round 1 residual, now gone |
| "`DELETE /circle/activity` (Glass addition)" | 0 | Round 1 residual. The 10 "Glass addition" hits are `use_taste`, `show_presence`, `share_streak`, `box=sent`, `series_count` and `content_kind`, which are real additions |

---

## Per finding

| ID | Verdict | Evidence |
|---|---|---|
| STACK-1 | Resolved | `flutter_soloud` 4.1.7 in §6 **Playback** (l. 1553), §9.4.2 **Recorded layers** and **Playback engines** (l. 3464, 3472), §15.3 **Packages** (l. 4230) and the §15.11 row (l. 4456). The row carries the `native_toolchain_c ^0.19.4` → `meta ^1.19.0` reason against `meta` 1.18.0, and "stack risk 10". |
| STACK-2 | Resolved | `share_plus` 12.0.2 in §9.2.4 **Rendering** (l. 3359), §15.3 **Packages** and §15.11 (l. 4459), with the `win32 ^6` versus `^5` reason naming all three pinning packages. `sharePositionOrigin` is still present (2 hits). |
| STACK-3 | Resolved | §2.7 (l. 479–483): six TTFs including `Phosphor-Thin.ttf`, the `Phosphor…` families, `phosphor.g.dart` with plain constants, codepoints from `phosphor_icons_*.dart`, and `PhosphorDuotoneIcon` at 0.20. §15.3 **Fonts**, §15.6 **Phosphor on Flutter** (l. 4343) and §15.11 "not used" (l. 4457) all agree. |
| STACK-4 | Resolved | §15.4 `panelBoxes` (l. 4254) is "not a second detector output". PRODUCT-2's `POST /reader/panels` is in place, and `GET /reader/panels` has 0 hits. |
| STACK-5 | Resolved | §15.2 **Sheet host**, *A sheet route opened from a sheet* (l. 4189): at most two entries, `pushState({ mmSheet: id, base, parent: previousId })`, 0.9165 per §7.10, `popstate` pops the top, and a third uses `replaceState`. |
| STACK-6 | **Unresolved** (contradiction with §4.9 and law 5) | Every part of the judge's fix is present in §15.3 **Sheets** (l. 4231–4237), with pointers from §7.10 **Physics** and §8.0.5. `transitionDuration` is 447 ms. That is the current `sheet` settle (§2.8 l. 797, §4.2 l. 1054, §4.10 l. 1208), and `sheetSnap` k 223.8, c 26.33 checks out (k = (2π/0.42)², c = 2 × 0.88 × √k). **The contradiction:** in `smooth_sheets` 1.2.0, `ModalSheetRouteMixin.buildTransitions` slides the sheet with a `SlideTransition` driven by the route's `animation` (`modal.dart:303–316`). The only thing that couples a drag to that transition controller is `_SheetDismissible`, built with `enabled: swipeDismissible` (`modal.dart:294–296`, 406–407), and Glass sets `swipeDismissible: false`. So a touch during a button present starts a `DragSheetActivity` on the sheet's own offset while the route's 447 ms slide carries on moving the whole sheet under the finger. The sheet neither stops nor tracks 1:1. That contradicts §4.9 l. 1181 ("Scrolling during a sheet's present animation is impossible (the sheet is under the finger's control once touched), and **touching a sheet in flight** catches it"), law 5 l. 1034 (whose catchable set now starts with "a sheet"), the §4.10 **Catch** row (l. 1222) and `motion.catch` (l. 1420). A second, smaller symptom: §4.1 law 5 exempts "route pushes and pops", but on Flutter every sheet present **is** a route push (a `GlassSheetRoute`), so the text never says which of the two rules applies to it. |
| STACK-7 | Resolved | §6 **One audio session, one owner** (l. 1555): the owner is the shared `skins/skin_audio.dart`. The `narration` row (l. 1561) is `AudioSessionConfiguration.speech()` with no `duckOthers`. The §15.6 **Audio session** row is at l. 4344. |
| STACK-8 | Resolved | §9.4.2 **Recorded layers** (l. 3464): the apps always fetch Opus `.ogg` (4.1.7 has no AAC decoder), and `.m4a` is fetched only when `canPlayType('audio/ogg; codecs="opus"') === ""`, before `decodeAudioData`. **Playback engines** (l. 3472) load only `.ogg`. |
| STACK-9 | Resolved | Byte-range `FileResponse` with `audio/ogg` / `audio/mp4` in §9.4.2 (l. 3464) and the §15.5 soundscape row (l. 4296), on `GET /app/soundscapes/{id}.{ext}`. |
| STACK-10 | Resolved | The 11-id union and Glass's nine ids, in §8.7 step 5's order, appear in the §15.5 taste row (l. 4287) and the §15.6 **Taste** row (l. 4348). |
| STACK-11 | Resolved | `{ type: "skin", skin: "glass" }` on every boot and `{ type: "skin-changed", skin: "cinematic" }` on a switch (§15.2 l. 4193, §8.25.2). `offline-fallback-glass.html` is in §8.28 (l. 3148), and Appendix B (l. 4572) has the same path. |
| STACK-12 | Resolved | 6 layers / 8 shapes in §2.4.1 (l. 360), §2.5 (l. 461), §8.25.12 (l. 3091, "`warning` above 6 web elements or 6 Flutter layers or 8 shapes"), §15.7 (l. 4354, 4362) and G10 (l. 4421). The three worst rows are the judge's: 4 / 8, 4 / 7 and 6 / 6. The Takeovers row now reads 2 / 2, matching its web count of 2 after another lens made the Wrapped close button a twin. See O6 on the search row. |
| STACK-13 | Resolved | §15.3 **Accessibility scope** (l. 4238): `GlassAccessibilityScope(reduceMotion: …, reduceTransparency: false)`, precedence over the global flags, `solid1` / `solid2` drawn by `SkinGlass`, no `wrap()`, and `adaptiveQuality` left at `false`. |
| STACK-14 | Resolved | §2.4.1 **Web bar groups, droplets and the neck** (l. 362–367): one map per group keyed by the shape list, the dock's 4 per-tab maps plus a base map, no map built mid-motion, a mask-only neck, and no nested `backdrop-filter`. The §15.2 `liquid-map.ts` row (l. 4164–4165) and §7.15 **Droplet** (l. 1796) match. See O3. |
| STACK-15 | Resolved | Law 5 (l. 1034) is now "**Every object in flight is catchable.**" Its set is a sheet, the dock droplet, a toast, a pager page, the image viewer and the Flutter poster zoom before 80 %. Its exceptions are route pushes and pops and the web poster zoom (§4.9). Manifesto l. 5 and l. 44 carry the same exception. The same set now appears in §4.9 (l. 1175, 1179), §4.10 **Catch** (l. 1222) and `motion.catch` (l. 1420, where "pager" was added, closing round 1's O4). No absolute "everything" claim remains. Manifesto l. 44 leaves the Flutter poster zoom out of its parenthetical, but the list only gives examples and l. 44's exception clause is still correct. (The sheet half of this catch rule is the STACK-6 problem above.) |
| STACK-16 | Resolved | §7.37 **Source** (l. 2072–2073): `mmSeq` written with `history.replaceState({ ...history.state, mmSeq: seq }, "")`, the contiguity test `mmSeq − row.seq === n` → `history.go(−n)`, and otherwise `router.push` plus a trim. §8.0.4 **Tab switch** (l. 2232): `router.push(lastPathOf(tab), { scroll: false })`, then the `scrollY` restore, and no entries removed. `history.go` has one hit. |
| STACK-17 | Resolved | §9.2.4 **Share-canvas fonts (web)** (l. 3360): the `next/font` `style.fontFamily` names, and `gsf-share-display.woff2` cut at `wght=720 ROND=100 GRAD=0 opsz=144`, ≤ 60 KB, loaded as `FontFace("MMShareDisplay")`. |
| STACK-18 | Resolved | §15.8 **Web gate** (l. 4392): a 10 s fling, mean frame rate within 5 % of refresh, ≤ 2 dropped frames/s, and the renderer-state fallback rule to register if it fails. |
| STACK-19 | Resolved | §2.8 **Web CSS custom property** (l. 530) now registers `--glass-dim` and the twins `--glass-grad-t` / `--glass-rond-t`, and says `--glass-grad` / `--glass-rond` stay unregistered (§3.5). This matches §2.8.5 (l. 777, 778, 880), §3.5 **Implementation** (l. 986), the §3.7 utility with `font-weight: var(--mm-type-<role>-wght)` and the `var(--glass-rond, …)` fallback (l. 999), §15.1 **CSS** (l. 4132) and the `GlassSurface.tsx` row (l. 4161–4162). No text registers `--glass-grad` or `--glass-rond` any more. §15.1's "(except …)" clause is now redundant but harmless. |
| STACK-20 | Resolved | §8.0.7 **iOS** (l. 2319) now says "haptics per §5", with intensity impacts through `mm/platform` `haptics.impact`, `ahap:*` through `gaimon` and `selection` through `haptic_feedback`. This matches §5 **Libraries** (l. 1360), §5.1 (l. 1380, 1387–1389), §15.3 **Native** (l. 4239), §15.11 (l. 4455) and G16 (l. 4427). No "through gaimon" routing for impacts remains. See O7. |
| STACK-21 | Resolved | §15.1 **Generator ownership** (l. 4136) is the single statement. §5.3 (l. 1491) and §2.8 (l. 531) repeat it. `motion.generated.ts` and `motion_names.g.dart` are in the trees. |
| STACK-22 | Resolved | §15.11 (l. 4441–4448) and §15.2 **Dependencies** (l. 4184): `fantasticon` 4.1.0 through `npx`, `@resvg/resvg-js` through `npx` as *reused*, `sox` for authoring only with committed outputs, `@use-gesture/react` including the image viewer and guided view, Base UI without Toast, and `sonner` as the one toast system through `toast.custom`. |
| STACK-23 | Resolved | `coverTransitionName(sourceId, seriesKey)` in §8.0.4 (l. 2229), §15.2 **Routes** (l. 4185) and **Sheet host** (l. 4187), using FNV-1a and the helper at `features/sources/cover-transition-name.ts`. No raw `cover-{…}` name remains. |
| STACK-24 | Resolved | §9.3.7 **Backend used** (l. 3435) now reads "`DELETE /circle/activity` → 204 (Cinematic's, §15.6)", matching the §15.5 Circle row (l. 4292) and the §15.6 **Activity** row (l. 4336). The other two mentions (l. 3117, 3387) give no ownership. `tags: [{id, name, category, color}]` appears at l. 2202, 2881 and 4297. `streak: {current_days, alive_today} \| null` is at l. 3435 and 4292, and no bare `current` streak field remains; `POST /reader/progress`'s `{current_days, extended_today}` agrees. The `busiest_day` and `firsts_lasts` shapes are at l. 4290. |
| STACK-25 | Resolved | §12.2 (l. 3905): `maxim-lobanov/setup-xcode@v1` with `xcode-version: '26.0'`, `xcode: 26.0`, `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES = AppIcon-Glass`, the `actool` dry run, and the PNG set as the fallback for iOS 18 devices. |
| STACK-26 | Resolved | §15.3 **Shader prewarm** (l. 4240): `prepare()` runs once per process and is awaited from `main()` and from the `AppRestart` path. |
| STACK-27 | Resolved | §9.4.2 **Rain on glass** (l. 3471): the uniform order `uSize`, `uTime`, `uDrops[10]`, `uBackdrop`, the `IMPELLER_TARGET_OPENGLES` flip, `ImageFilter.shader` behind `isShaderFilterSupported`, and one extra layer. The manga reader then reaches 5 of 6 layers. |
| STACK-28 | Resolved | §8.15.4 *Web Lift turn* (l. 2791): one inert `cloneNode(true)` above the live container, both turn directions, removal on settle or cancel, and no bitmap capture. |

---

## What STACK-6 still needs

Add a *Present* sub-bullet to §15.3 **Sheets**, after *Route*, and adjust *Route* to match. The present then becomes a sheet-offset animation, which a touch interrupts. Reading `smooth_sheets` 1.2.0 confirms this: `SheetModel.drag()` calls `beginActivity(DragSheetActivity)`, which replaces a running `AnimatedSheetActivity` (`model.dart:318`, `455–462`, `478–494`).

- *Present.* `GlassSheetRoute` overrides `buildTransitions` to return the child without the mixin's `SlideTransition`. The route's 447 ms animation still drives the barrier fade. The sheet is built with `initialOffset: SheetOffset(0)`. On the route's first frame, `SheetController.animateTo(detent, duration: 447 ms, curve: <springSheet sampled>)` raises it. A touch during that animation starts a drag activity, which stops the sheet under the finger with the finger's velocity, as §4.9 requires. A button dismiss runs `animateTo(SheetOffset(0))` on `dismiss` and pops when it settles, so it can be caught too.
- The *Detents and snapping* pop listener acts only after the sheet has first reached a detent, because the offset starts at 0.
- Law 5 (l. 1034) and the §4.9 first bullet (l. 1179) should say "page-route pushes and pops". A sheet route's present and dismiss are sheet-offset animations and stay catchable.

The alternative is to keep the route slide and state that a button-presented sheet is not catchable until it lands on Flutter. That is a smaller edit, but then l. 1181, law 5, §4.10 **Catch** and `motion.catch` all have to drop "sheet" for Flutter. It also leaves the two clients inconsistent: on the web, the `SheetHost` sheet drives its own position with Motion `drag="y"` (§15.2) and is catchable.

---

## Observations (not blocking; outside the stack findings' final fixes or pre-existing)

- **O1 (carried from round 1, still open).** §7.10 **The on-screen keyboard** (l. 1748) still ends with "; `GlassModalSheet` 1.7.2 snaps to full on a focused descendant the same way". §15.3 says that widget is not used, so the aside can go.
- **O2 (carried, still open).** §15.3 **Sheets** *Keyboard* (l. 4237) says the rule is "`GlassSheet`'s own", but no `GlassSheet` class is declared anywhere. Name the sheet-body widget in `glass_sheet_route.dart` instead. Also, `SheetController.animateTo` takes a `Duration` and a `Curve`, not a spring, so "on `springSheetSnap`" means a 342 ms curve sampled from `sheetSnap`. The text should say so.
- **O3 (carried, still open).** §9.4.2 **Rain on glass** (l. 3471) gives web tier A "an animated SVG displacement map on the pill and capsules". This conflicts with "No map is built mid-motion" (l. 365), "rebuilt at rest … never mid-motion" (l. 4165) and the sidebar's "refraction maps are rebuilt only at rest" (l. 1817). Either say the rain animates a primitive on the group's own filter, or register it as the one exception.
- **O5 (carried, web lens).** §15.2 **Routes** still says "`<ViewTransition>` with `nav-forward` / `nav-back` types". In Next 16.2 the transition types belong on `<Link>` / `router.push` (see `cinematic/DESIGN.md` §15.2).
- **O6 (new, STACK-12 table, below budget).** The §15.7 row "Phone search open" gives Flutter **3 / 3**. The first row counts the nav row group as three shapes (leading button, title capsule, trailing group), and §8.9's results view adds the `glassThin` jump bar (l. 2526), so the honest worst case is 3–4 layers and 5–6 shapes. The budget holds either way, but the web and Flutter counts in that row should be recounted.
- **O7 (new, STACK-20 neighbour, pre-existing in MOBILE-12 / the judge's text).** §5 **Libraries** routes "iOS impacts with an intensity" through `mm/platform`, `ahap:*` through `gaimon` and `selection` through `haptic_feedback`. The §5.1 table also has impacts with no intensity (`light`, `medium`, `heavy`, `dragStart`) and the three iOS notifications (`success`, `warning`, `error`), and nothing names their route. One clause would close this, for example "every other iOS impact through `haptics.impact` with intensity 1.0, and the notifications through `haptic_feedback`".
