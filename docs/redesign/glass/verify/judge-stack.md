# Judge: Glass stack-feasibility findings (`find-stack.md`)

Method: for each of the 28 findings I tried to refute the claim. I grepped `glass/DESIGN.md` for the missing or contradicting rule, read the cited sections, and checked the claim against its primary source:

- the local Flutter 3.44.6 SDK (`packages/flutter/pubspec.yaml`, `widgets/icon_data.dart`, `widgets/routes.dart`, `sky_engine/lib/ui/painting.dart`);
- the pub cache (`audio_session-0.1.25`, `file_picker-8.3.7`, `flutter_secure_storage_windows-3.1.2`, `package_info_plus-8.3.1`);
- the package archives and registry metadata (`phosphor_flutter` 2.1.0, `flutter_soloud` 4.1.7 and 5.1.4, `native_toolchain_c` 0.19.x, `share_plus` 12.0.2 and 13.3.0, `gaimon` 1.5.0, `swipeable_page_route` 0.4.8, `heroine` 0.7.2);
- the `design-ref/` clones of `liquid_glass_widgets` 1.7.2 and `smooth_sheets` 1.2.0;
- `frontend/node_modules/next` font data, `backend/routes/app_distribution.py`, `mobile/lib/features/novels/utils/novel_audio_session.dart`, `.github/workflows/ios-build.yml` and `codemagic.yaml`;
- `cinematic/DESIGN.md`, `stack-decision.md`, `inventory/00-decisions.md` and `inventory/capabilities.md`.

I also read the other Glass judges (`judge-web.md`, `judge-product.md`, `judge-mobile.md`, `judge-consistency.md`), because eight of these findings overlap theirs. Where a finding duplicates one of theirs, its final fix below points to that fix and adds only what that fix leaves out, so the main session applies each change once.

Note on the live file: while I worked, the web lens's fix mode was already editing `glass/DESIGN.md` (WEB-1's sheet host is now in §15.2). Section references below are stable. Line numbers in the finder's evidence refer to the audited version.

Result: **28 confirmed, 0 refuted.**

- **Eleven fixes were rewritten or corrected:** STACK-3, 5, 6, 12, 14, 15, 16, 20, 21, 24 and 25.
- **Six are duplicates** of findings from other lenses, with additions: STACK-4 (PRODUCT-2), 5 (WEB-1), 9 (PRODUCT-6), 10 (PRODUCT-7), 15 (MOBILE-2), 19 (CONSISTENCY-11). STACK-20 overlaps MOBILE-12 and STACK-24 overlaps PRODUCT-27; both are counted among the rewrites above.
- **The rest stand as written,** with small edits.

**§15.10 row numbers.** PRODUCT-2 already takes G14. The new rows below are therefore labelled "next free G number" and not given fixed numbers, so the lenses cannot collide.

---

## Verdicts and reasons

| ID | Verdict | Reason |
|---|---|---|
| STACK-1 | Confirmed | Glass names `flutter_soloud` 5.1.4 in §6, §9.4.2, §15.3 and §15.11. Registry metadata: 5.1.4 depends on `native_toolchain_c ^0.19.4`, and 0.19.3 and later need `meta ^1.19.0`. The SDK's `packages/flutter/pubspec.yaml` pins `meta: 1.18.0`, so version solving fails. 4.1.7 has no `native_toolchain_c` dependency. `loadMem`, `loadFile`, `setVolume(handle, v)` and `fadeVolume(handle, to, Duration)` exist in 4.1.7 (`lib/src/soloud.dart` lines 978, 884, 2928, 3301). |
| STACK-2 | Confirmed | `share_plus` 13.3.0 needs `win32 ^6.0.1`. Pub cache: `file_picker-8.3.7` pins `win32 ^5.9.0`, `flutter_secure_storage_windows-3.1.2` pins `^5.0.0`, `package_info_plus-8.3.1` pins `^5.5.3`. 12.0.2 needs `^5.5.3`, and its `lib/share_plus.dart` defines `SharePlus`. |
| STACK-3 | Confirmed, fix corrected | SDK `widgets/icon_data.dart` line 23: `final class IconData {`. `phosphor_flutter` 2.1.0 `lib/src/phosphor_icon_data.dart` line 5: `class PhosphorIconData extends IconData`, with SDK floor `>=2.12.0`. The pre-3.0 exemption from class modifiers covers only `dart:` platform libraries, not `package:flutter`. The finder's fix lists five font files while saying "six" and omits `Phosphor-Thin.ttf`, which the archive ships (`lib/fonts/`); the corrected list and the codepoint source are below. |
| STACK-4 | Confirmed (duplicate of PRODUCT-2) | §9.4.3 and §15.5 call the server-side `GET /reader/panels` + `panels_ready` "Cinematic's", while `cinematic/DESIGN.md` §9.4.3 and §15.10 S11 detect panels on the client and cache client reports. PRODUCT-2's fix resolves it. This lens adds one thing: §15.4 lists both `panels` (in the Cinematic base set) and `panelBoxes`, so two fields exist for one duty. |
| STACK-5 | Confirmed, narrowed (core duplicate of WEB-1, already applied) | The audited file had no mechanism for sheet routes over a live page. WEB-1's `SheetHost` (pushState, the covered page stays mounted) is now in §15.2. It rightly rejects the finder's intercepting routes, because shared `app/` route files would also intercept Cinematic's navigations, and the finder's `<OpaqueLayer>` fallback would change Cinematic's page model. One gap remains: the host has a single slot and says nothing about a sheet route pushed from a sheet. `recap` over the `feature` sheet is exactly that case (§8.0.3; §7.10 allows two stacked sheets). |
| STACK-6 | Confirmed, fix rewritten | `liquid_glass_widgets` 1.7.2 `GlassModalSheet` has a hard-coded `SpringDescription(mass: 1, stiffness: 220, damping: 30)` (`glass_modal_sheet_state.dart:227`) and a velocity-threshold plus 40 % progress detent rule (`glass_modal_sheet_mechanics.dart:311–349`). One `velocityThreshold` (default 700) serves both snapping and dismissal, and the sheet is shown through `showGeneralDialog` (`glass_modal_sheet.dart:472`), so it is not a go_router `Page`. The stack names `stupid_simple_sheet`, and Glass has no §15.10 row for the change. **Two parts of the finder's claim or fix are wrong.** (d) is false: `GlassModalSheetController.progressListenable` fires on every position change (`glass_modal_sheet_mechanics.dart:442–448`). And `smooth_sheets` 1.2.0's `SwipeDismissSensitivity` has no `minDragDistance`: it has `minFlingVelocityRatio` against the **navigator height** (not the sheet height) and `dismissalOffset`, and its dismissal is by fling ratio or resting offset, not by projection (`modal.dart:552–590, 682–715`). The rewrite keeps §4.6's projection rule exactly. |
| STACK-7 | Confirmed | Glass's `narration` state is `.playback + .duckOthers`. Setting `.duckOthers` implies `.mixWithOthers`, and a mixable session cannot own Now Playing, which removes the `audio_service` lock screen that §15.3 and MOBILE-16 rely on. The claim "(the category narration uses today through `audio_session`)" is false: today's call is `AudioSessionConfiguration.speech()` (`novel_audio_session.dart:13`), which is `.playback`, `.spokenAudio`, `AndroidAudioFocusGainType.gain`, with no `duckOthers` (`audio_session-0.1.25/lib/src/core.dart:561–571`). Cinematic makes `skins/skin_audio.dart` the single owner. With both skins in one binary, two owners cannot both hold. |
| STACK-8 | Confirmed | `flutter_soloud` 4.1.7 README line 30: "Support for MP3, WAV, OGG, and FLAC". It has no AVFoundation path, so `.m4a` never loads on iOS. Cinematic already requests Ogg on iOS for the same reason (its §8.16.5). |
| STACK-9 | Confirmed (duplicate of PRODUCT-6) | `app_distribution.py`: `@router.get("/app/media/{name}")` keeps only `Path(name).name`, reads `SCREENSHOTS_DIR` and allows image suffixes only. Cinematic defines the allowlisted `GET /app/soundscapes/{id}.{ext}`. PRODUCT-6's fix omits the response headers the players need; they are added below. |
| STACK-10 | Confirmed (duplicate of PRODUCT-7) | §8.7 sends `onboarding_step` and seeds through `POST /library/taste/seed`; Cinematic's payload has `step` and `GET /onboarding/catalog`. PRODUCT-7's fix resolves the payload but not the vocabulary: Cinematic's `styles` enum is `painted, cel, screentone, manhua-3d, sketch, retro, pastel, noir, chibi`, and Glass's crops add `watercolour` and `dark-realism` (§8.7 step 5). A server validating Cinematic's enum would reject Glass's picks. |
| STACK-11 | Confirmed | §8.28 specifies one `offline-fallback.html` with both skins' CSS, and §8.25.2 posts `{type: "skin-changed"}` without a skin. `cinematic/DESIGN.md` §15.2 has the one shared worker serve `offline-fallback-{skin}.html` from a skin the page posts on every boot (`{type: "skin", skin}`) and on a switch, and fall back to Cinematic when nothing is stored. Under that worker, a Glass user offline gets Cinematic's page. |
| STACK-12 | Confirmed, fix corrected | `liquid_glass_widgets` 1.7.2 `lib/src/engine/liquid_glass_layer.dart:242` wraps every layer in its own `BackdropGroup`, so "one `BackdropGroup` per Flutter screen, eight members" (§2.5, §15.7) cannot be built. The finder's cap of 4 layers is wrong for the tablet and Flutter desktop frame, whose separately placed objects (sidebar, toolbar group, toast, app-update capsule, window or panel, menu) need 6 layers. The corrected budget is 6 layers and 8 shapes. |
| STACK-13 | Confirmed, fix simplified | `glass_accessibility_scope.dart`: `reduceTransparency: reduceTransparency ?? MediaQuery.highContrastOf(context)`, so Increase Contrast turns every glass surface into the library's frosted panel, against §4.11. A scope with explicit arguments takes precedence over the global flag (`liquid_glass_setup.dart`: "A GlassAccessibilityScope placed anywhere in the widget tree always takes precedence"). `adaptiveQuality` already defaults to `false`, so no `wrap()` call is needed. |
| STACK-14 | Confirmed, fix rewritten | The map generator is keyed by one rounded rectangle `(w, h, r, tier)` (§15.2), yet a bar group is one element masked to several shapes (§2.4.1). A `backdrop-filter` element nested in the masked group, such as the dock's droplet, sits under a Backdrop Root and cannot sample the page. CONSISTENCY-1 already makes selection droplets "a clear-finish region of their host bar's own surface, not a second backdrop read", so the fix follows that ruling. The finder switched the whole dock to the frosted tier during a drag; I replaced that with per-group cached maps, so the dock keeps its refraction and only the moving droplet goes without lensing. |
| STACK-15 | Confirmed (Flutter half duplicates MOBILE-2) | `swipeable_page_route` 0.4.8 `page_route.dart:184–185` refuses a swipe while the route animates (as does `ModalRoute.popGestureEnabled`, per MOBILE-2). On the web every push is a React `<ViewTransition>`, whose pseudo-element overlay takes the input until it finishes. §4.9 still promises "a back swipe during a push grabs the incoming page", and its `committed` row lists "pages". `heroine` 0.7.2 flights are springs that redirect on a pop with their velocity (`flight_controller.dart`), so the Flutter poster zoom stays catchable. The web zoom is a view transition and is not. |
| STACK-16 | Confirmed, fix refined | §8.0.4 says each tab keeps its own stack and scroll offset, and §7.37 pops with `history.go(−n)` over a per-tab record. The browser history is linear, so after a tab switch `n` counts the wrong entries, and no web tab-switch behaviour is specified. The finder's "every entry between belongs to the same tab" test is not computable from the record. Contiguity (`currentSeq − row.seq == levels above`) is, and replaces it. |
| STACK-17 | Confirmed | `next/font/google` emits a hashed family name (`style.fontFamily`), so `document.fonts.load('600 64px "Google Sans Flex"')` and a matching `ctx.font` resolve to a fallback face. Canvas 2D has no `font-variation-settings`, so `ROND 100` numerals (§9.2.3 `type.wrappedNumeral`) cannot be drawn. The `next` font data lists the ROND, GRAD, opsz, slnt, wdth and wght axes, so a static instance can be cut. |
| STACK-18 | Confirmed | §15.8's only frame-rate gate is the Flutter one. Web tier A runs up to six SVG `feDisplacementMap` backdrop filters, with three displacement passes on T4 and T5 (§2.4.3), re-evaluated on every scroll frame, and nothing gates it. |
| STACK-19 | Confirmed (duplicate of CONSISTENCY-11), fix extended | `"opsz" auto` is not a `<string> <number>` pair, so the whole `.on-glass` declaration is dropped. CONSISTENCY-11 deletes it and folds the press weight into the utility. That fix still relies on `var(--glass-rond, var(--mm-type-<role>-rond))` falling back outside glass, but §3.5 registers `--glass-rond` and `--glass-grad` with `@property` as `<number>`. A registered property always has a value (its initial value), so the fallback never applies and every title on content renders at `ROND` 0, not 100. The finder's `font-weight` addition is kept. |
| STACK-20 | Confirmed, fix rewritten (overlaps MOBILE-12) | `gaimon` 1.5.0 `lib/gaimon.dart`: `rigid()` and `soft()` take no arguments, and no impact takes an intensity. §5 claims "named impacts with intensity" through `gaimon`. §5.1 says Android one-shots go through a gaimon waveform, while §15.3 puts them on `mm/platform`. `stack-decision.md` §2.3 names the channel `mm/haptics`, and Glass renames it with no amendment row (`grep "mm/haptics"` finds 0 hits in DESIGN.md). MOBILE-12 already specifies the one-shot as `VibrationEffect.createOneShot(12, round(i × 255))`, which is §15.3's `mm/platform` path. The finder's "move it to gaimon" would contradict that, so the one-shot stays on `mm/platform`. "Tell Cinematic" is dropped, because Cinematic uses no haptics channel. |
| STACK-21 | Confirmed, fix simplified | §5.3 says `build.mjs` writes the AHAP files, while §15.1 and G2 say `design/build-haptics.mjs`. G2 gives the motion-name unions to that same script, but §15.1 names no writer. §2.8 says `build.mjs --check` greps utilities, while §15.1 says `design/lint-utilities.mjs`. `motion.generated.ts` and `motion_names.g.dart` are in neither tree. The finder added a third script, `build-motion-names.mjs`, which G2 does not need; the fix follows G2 instead. |
| STACK-22 | Confirmed | `fantasticon`: Cinematic pins 4.1.0 and runs it with `npx` (its §15.11), so there is no lockfile. `@resvg/resvg-js` and `sox` are *added here* in Glass but already added by Cinematic, and Glass's "CI only" `sox` contradicts Cinematic's "authoring only; outputs committed". `@use-gesture/react` is "reader pinch only", yet §11 also pinches the image viewer, and §9.4.3 pinches guided view. Base UI "Toast primitives" and `sonner` "the queue behind the Glass toast" are two toast systems. |
| STACK-23 | Confirmed | Series keys may contain `/` and `%` (`capabilities.md` §1), which are invalid in `view-transition-name`. Cinematic uses `coverTransitionName()` (FNV-1a hash). The raw `cover-{sourceId}-{seriesKey}` also appears in the sheet-host paragraph WEB-1 just added to §15.2. |
| STACK-24 | Confirmed, fix corrected (item 1 overlaps PRODUCT-27) | Four problems. (1) `tag_ids` is named as a row field, but Cinematic's row field is `tags`. The tag object in `capabilities.md` §12 is `{id, name, category, color}`, so PRODUCT-27's `{id, name, color}` is incomplete. (2) §15.6 says Cinematic has not listed `DELETE /circle/activity`, but Cinematic line 3493 defines it (→ 204). (3) `busiest_day.series` and `firsts_lasts.*.series` have no element shape. (4) §9.3.7 gives `streak {current, alive_today}`, while every other streak object uses `current_days`. The finder's `{current_days}` dropped `alive_today`, which §9.3.7 defines. |
| STACK-25 | Confirmed, fix corrected | `ios-build.yml:33` uses `runs-on: macos-latest` and `codemagic.yaml:25` uses `xcode: latest`, so compiling the `.icon` bundle depends on whichever image the runner has that day. The finder's alternate-icon names (`GlassIcon CinematicIcon`) do not match the bundle §12.6 names (`AppIcon-Glass.icon`). Its "PNG fallback when the job runs on an older image" contradicts the pin; the PNG set is the fallback for iOS 18 *devices*, which §12.2 already specifies. |
| STACK-26 | Confirmed, one option chosen | `stack-decision.md` §2.5 step 4 restarts through `AppRestart` without rerunning `main()`. `LiquidGlassWidgets.initialize()` loads the `FragmentProgram`s that prevent the first-frame flash (`liquid_glass_setup.dart:104–143`). If `main()` calls it only for a Glass boot, a switch into Glass skips it. Calling it on every Cinematic boot would cost Cinematic cold-start disk I/O, so the Glass boot path is chosen. |
| STACK-27 | Confirmed, uniform order corrected | A `FragmentProgram` drawn on a layer cannot read the backdrop. `ImageFilter.shader` exists on Impeller only (`isShaderFilterSupported => _impellerEnabled`, `painting.dart:4506`). Its first uniform must be the engine-set `vec2` size, and its first `sampler2D` is the filter input (`painting.dart:4444–4448`). The finder listed the sampler first. |
| STACK-28 | Confirmed, fix clarified | One column of a CSS multi-column box is not an element and cannot be transformed. §8.15.4 promises CSS-3D Lift on the web with "no bitmap capture". The finder's "two clipped copies" really needs one clone above the live container. |

---

## Confirmed

### STACK-1 (high): `flutter_soloud` 4.1.7

Replace 5.1.4 with 4.1.7 in §6 **Playback**, §9.4.2 **Playback engines**, §15.3 **Packages** and the §15.11 row. The status stays *reused*. In the §15.11 row's "Why" cell add: "5.x needs `native_toolchain_c ^0.19.4`, which needs `meta ^1.19.0`; Flutter 3.44.6 pins `meta` 1.18.0. Revisit with the Flutter upgrade (stack risk 10)." No Glass call changes: `loadMem`, `loadFile`, `setVolume(handle, v)` and `fadeVolume(handle, to, Duration)` all exist in 4.1.7.

### STACK-2 (high): `share_plus` 12.0.2

Replace 13.3.0 with 12.0.2 in §9.2.4 **Rendering**, §15.3 **Packages** and the §15.11 row. The status stays *reused*. Add the reason to the row: "13.x needs `win32 ^6`; `file_picker` 8.3.7, `flutter_secure_storage_windows` 3.1.2 and `package_info_plus` 8.3.1 pin `win32 ^5`." The call `SharePlus.instance.share(ShareParams(files: [XFile.fromData(bytes, mimeType: "image/png", name: …)]))` is unchanged, and MOBILE-11's `sharePositionOrigin` still applies.

### STACK-3 (high): Phosphor on Flutter without `phosphor_flutter`

- **§2.7 and §15.3:** drop `phosphor_flutter` 2.1.0.
  - Bundle the six Phosphor 2.1 TTFs from the `phosphor_flutter` 2.1.0 archive's `lib/fonts/` under `mobile/assets/fonts/phosphor/`: `Phosphor.ttf`, `Phosphor-Thin.ttf`, `Phosphor-Light.ttf`, `Phosphor-Bold.ttf`, `Phosphor-Fill.ttf` and `Phosphor-Duotone.ttf` (MIT; the licence goes in the licences list).
  - Declare them in `pubspec.yaml` `fonts:` as the families `PhosphorRegular`, `PhosphorThin`, `PhosphorLight`, `PhosphorBold`, `PhosphorFill` and `PhosphorDuotone`.
- **Generator:** `brand/glass/glyphs.mjs` (STACK-22) also writes `mobile/lib/skins/glass/icons/phosphor.g.dart`.
  - It contains plain constants only, never a subclass: `static const IconData houseSimple = IconData(0x…, fontFamily: 'PhosphorRegular');`, one class per weight.
  - The codepoints are read from the same archive's `lib/src/phosphor_icons_{regular,thin,light,bold,fill,duotone}.dart`, which were generated from these fonts.
- **Duotone:** each duotone icon is two constants, primary and secondary. A 20-line `PhosphorDuotoneIcon` widget stacks them, with the secondary at opacity 0.20 (the package's own `duotoneSecondaryOpacity`).
- **§15.11:** change the row to "`phosphor_flutter` | not used: `IconData` is a `final class` on Flutter ≥ 3.44, and 2.1.0 subclasses it | Phosphor TTFs + generated `IconData` constants | added here".
- **§15.6:** add a row "Phosphor on Flutter | bundled TTFs + generated constants for both skins (one copy of the fonts in `pubspec.yaml`) | names `phosphor_flutter` 2.1.0; takes the same edit".

### STACK-4 (high): guided-view panels (duplicate of PRODUCT-2)

Apply PRODUCT-2's final fix (`judge-product.md`) once. In addition, change §15.4's `panelBoxes` row to: "the engine's `panels` entry for the current page (Cinematic's `panels` field, §15.4 base set), exposed as a getter; not a second detector output".

### STACK-5 (low): a sheet route opened from a sheet (residual after WEB-1)

The core mechanism is WEB-1's `SheetHost`, already in §15.2. Add to its paragraph:

"The host keeps a stack of at most two entries (§7.10 stacking). A sheet route pushed while a sheet route is open, such as `recap` from the series sheet or `circleMember` from a recap's friend link, is pushed with `pushState({ mmSheet: id, base, parent: previousId })` and renders above the first. The lower sheet then scales to 0.9165 per §7.10. `popstate` removes only the top entry. A third sheet route replaces the top entry (`replaceState`) and never stacks a third."

### STACK-6 (high): the Flutter sheet on `smooth_sheets` 1.2.0

Replace the §15.3 sentence "Sheets use `liquid_glass_widgets`' `GlassModalSheet` …" with the following, and point §7.10 and §8.0.5 at it:

- **Route.** Every sheet route (`feature`, `recap`, `circleMember`, `profileNew` / `profileEdit`, and every `?sheet=` id) is a `GlassSheetPage` whose `createRoute` returns `GlassSheetRoute extends ModalSheetRoute` (`smooth_sheets` 1.2.0; `ModalSheetRoute` is public, `modal.dart:144`). It is used as the go_router `pageBuilder`, so URL state, Android back and the iOS swipe all go through the router. Settings: `swipeDismissible: false`, `barrierColor: Color(0x47000000)`, `transitionDuration` 494 ms with a `Curve` sampled from `springSheet` (button present only; button dismiss uses `dismiss`, CONSISTENCY-5).
- **Detents and snapping.** Physics: `GlassSheetPhysics extends SheetPhysics with SheetPhysicsMixin`, whose `spring` returns `springSheetSnap`'s `SpringDescription` (k 223.8, c 26.33). The snap grid is `GlassSnapGrid implements SheetSnapGrid`:
  - `getSnapOffset(layout, offset, velocity)` computes `project(offset, velocity)` (§4.4, capped at one screen) and returns the nearest of peek 96 px, medium 0.52 × viewport height, and large = viewport − safe-top − 10.
  - When the projected top edge falls more than 50 % of the lowest detent's height below that detent, or the sheet is at its lowest detent moving down at ≥ 1500 px/s, it returns `SheetOffset(0)`.
  - `getBoundaries` returns `(SheetOffset(0), large)`.
  - A `SheetNotification` listener pops the route (`Navigator.pop`) when the offset settles at 0.
  - This keeps §4.6's projection rule exactly. `smooth_sheets`' own swipe dismissal decides by fling ratio or resting offset instead, which is why it is off.
- **Above the top detent:** the §4.5 rubber band with a 60 px cap, applied in `applyPhysicsToOffset`.
- **Driven values.** Recede, inset, radius and material cross-fade come from `SheetOffsetDrivenAnimation(controller:, initialValue:, startOffset:, endOffset:)` (§7.10 **Behind** and **Geometry**). A `SheetUpdateNotification` listener fires `sheet.pass` when the offset crosses a detent during a drag. The material is `SkinGlass(tier: T4)` inside the sheet, and `rSheet` comes from MOBILE-18's `GlassThemeHelpers.resolveAdaptiveRadius`.
- **Android predictive back:** `GlassSheetRoute` overrides `handleUpdateBackGestureProgress` (from `PredictiveBackRoute`, implemented by every `TransitionRoute` on Flutter 3.44.6). It writes the progress into a `ValueNotifier` that scales the sheet 1 → 0.94 and lifts it 12 px (§8.0.5), instead of moving the route's transition controller.
- **Keyboard:** MOBILE-9 credits the focus-to-large rule to `GlassModalSheet`. Here it becomes `GlassSheet`'s own: a `Focus` listener calls `SheetController.animateTo(large)` on `springSheetSnap` when a descendant field gains focus.
- `GlassModalSheet` is not used.
- **§15.11:** the `smooth_sheets` row becomes "every Glass sheet (a go_router `Page`, pluggable spring physics, offset-driven animation) | stack | fallback: a `PageRoute` with a `DraggableScrollableSheet` and `SpringSimulation`". Add a note that `stupid_simple_sheet` (stack §3) is not used by Glass.
- **§15.10:** add a row (next free G number): "§1 and §3 name `stupid_simple_sheet` | Glass builds every sheet on `smooth_sheets` 1.2.0 (in the same pinned list), because it offers a go_router `Page`, pluggable spring physics and offset-driven animation; `GlassModalSheet` cannot take `sheetSnap`, projection or the 1500 px/s dismissal | amendment".

### STACK-7 (medium): one audio-session owner for both skins

- **§6 "One audio session, one owner":** the owner is the shared `mobile/lib/skins/skin_audio.dart` (Cinematic's), not `glass/soundscape/mixer.dart`. The Glass mixer requests states from it and never calls `AudioSession.instance.configure`.
- **§6 table, `narration` row:** "`AudioSessionConfiguration.speech()` (`.playback`, mode `.spokenAudio`, no `duckOthers`) | `AUDIOFOCUS_GAIN`, usage media, content speech". This is Cinematic's State B and today's `novel_audio_session.dart`. A non-mixable session is what keeps the `audio_service` lock screen and Control Center controls (§15.3, MOBILE-16), so the user's music pauses while narration plays. The soundscape still ducks itself by 12 dB inside the app.
- Delete "(the category narration uses today through `audio_session`)".
- Glass's `soundscape` (`.playback + .mixWithOthers`, no focus request) and `idle` (`.ambient + .mixWithOthers`) become named states of `skin_audio.dart`.
- **§15.6:** add a row "Audio session | one owner, `skins/skin_audio.dart`; narration is State B for both skins; Glass adds the `soundscape` state | owns it; conforms".

### STACK-8 (medium): recorded layers in a format SoLoud decodes

In §9.4.2 **Recorded layers** and **Playback engines**:

- The iOS and Android apps always fetch the Opus 96 kb/s `.ogg` files, which `flutter_soloud` 4.1.7 decodes. It has no AAC decoder.
- The `.m4a` (AAC-LC 96 kb/s) files are fetched only by the web when `new Audio().canPlayType('audio/ogg; codecs="opus"') === ""`, which in practice means Safari. The check runs before `decodeAudioData`.
- The server keeps both files.

### STACK-9 (medium): soundscape route (duplicate of PRODUCT-6)

Apply PRODUCT-6's final fix once, and add to it: `FileResponse` with byte-range support; `Content-Type: audio/ogg` for `.ogg` and `audio/mp4` for `.m4a`.

### STACK-10 (medium): onboarding taste (duplicate of PRODUCT-7)

Apply PRODUCT-7's final fix once, and add to §15.5 and the §15.6 Taste row:

"The server's `styles` enum is the union of both skins' ids (11): `painted, cel, screentone, manhua-3d, sketch, retro, pastel, noir, chibi, watercolour, dark-realism`. Glass sends its nine: `painted, cel, screentone, manhua-3d, watercolour, sketch, retro, chibi, dark-realism`, in §8.7 step 5's order."

### STACK-11 (medium): the shared service worker's skin protocol

Conform to Cinematic's worker (`cinematic/DESIGN.md` §15.2):

- The Glass `Shell` posts `{ type: "skin", skin: "glass" }` to `navigator.serviceWorker.controller` on every boot.
- The switch in §8.25.2 step 2 posts `{ type: "skin-changed", skin: "cinematic" }`.
- Glass ships `frontend/public/offline-fallback-glass.html`: self-contained, inline CSS, the §8.28 content and copy.
- **§8.28:** delete "one static file carrying both skins' CSS; a four-line inline script reads the `mm-skin` cookie and sets `data-skin`". Name the file `offline-fallback-glass.html`, served by the worker from the last posted skin.
- **§15.2 Service worker:** replace "chosen by the `mm-skin` cookie" with "chosen by the skin the page last posted (Cinematic's protocol)".
- **Appendix B:** update the path.

### STACK-12 (medium): the Flutter glass budget in the engine's units

- **§2.5 and §15.7:** replace "all backdrop filters on a Flutter screen in one `BackdropGroup` … eight `BackdropGroup` members per Flutter screen" with: "Flutter counts `LiquidGlassLayer`s (each wraps its own `BackdropGroup` in 1.7.2) and glass shapes. Sibling shapes of one bar group are `LiquidGlass` children of one layer. At most **6 layers** and **8 shapes** are live per frame."
- `SkinGlass` keeps a registry of mounted layers and shapes for the Diagnostics row "Glass layers on screen", which turns `warning` above 6 layers or 8 shapes.
- "One `BackdropGroup` per screen" stays only for the `BackdropFilter` frosted fallback path (stack risk 4).
- Recompute the §15.7 table's Flutter column as layers / shapes. The worst rows:
  - Phone tab root with a sheet and a toast: 4 layers / 8 shapes (nav row group; dock + orb + accessory; sheet; toast or menu).
  - Manga reader: 4 / 7 (top chrome groups; bottom capsule + scrub lens + pill or seam chip; overlay lens; sheet).
  - Tablet or Flutter desktop frame: 6 / 6 (sidebar, toolbar group, toast, app-update capsule, window or panel, menu).

### STACK-13 (medium): the engine's accessibility scope

Add to §15.3 (`skin_glass.dart`):

"`SkinGlass` installs `GlassAccessibilityScope(reduceMotion: ref.watch(glassMotionPrefsProvider).reduced, reduceTransparency: false, child: …)` above the Glass shell. An explicit scope takes precedence over `liquid_glass_widgets`' global flags, so `MediaQuery.highContrastOf` (iOS Increase Contrast) never turns glass into the library's frosted panel. `SkinGlass` itself renders `solid1` / `solid2`, never a library widget, when `mm/platform a11y.reduceTransparency` or the Solid glass setting is on, and applies Increase Contrast per §4.11. `LiquidGlassWidgets.wrap()` is not used (`adaptiveQuality` stays at its default `false`)."

### STACK-14 (medium): web bar groups, droplets and the neck

Replace §2.4.1's single-shape description and the §15.2 `liquid-map.ts` line with the following, and add the droplet sentence to §7.15:

- **Map per group.** `liquidMap(shapes: [{x, y, w, h, r, tier}], groupW, groupH)` draws every shape's bezel into one displacement map. The cache key is the rounded shape list, and the group's `mask-image` is drawn from the same list.
- **Droplets (CONSISTENCY-1: a clear-finish region of the host bar, not a second backdrop read):** the droplet is never a separate `backdrop-filter` element.
  - At rest it is one more shape in the group's map. The dock caches one map per tab position (4) plus one base map without a droplet, built once per size.
  - While the droplet travels (tab tap) or is dragged, the group uses the base map, and the droplet is drawn with `glassFilm` clear's fill, rim and inner light only. On settle it swaps to the cached map for the new tab. No map is built mid-motion.
- **Metaball neck:** during the dock-to-orb merge, the neck is added to the group's mask only, so the neck region gets blur and saturate without displacement, and the base map stays in use. The resting map returns on settle.
- **Rule:** no `backdrop-filter` element is ever nested inside a bar group (a nested one would sample only its Backdrop Root, not the page).

### STACK-15 (medium): what can be caught in flight (Flutter half = MOBILE-2)

Apply MOBILE-2's amendment of §4.9 and §4.10 once, then extend it for the web:

- **§4.9, in place of "A back swipe during a push animation grabs the incoming page where it is":** "Route pushes and pops are not catchable on either client. On Flutter the back gesture starts once the push has settled (MOBILE-2). On the web a `<ViewTransition>` runs to completion and input during it is ignored."
- **§4.9 `committed` row:** "can still be caught only for sheets, the dock droplet and toasts".
- **Zoom bullet:** "The poster zoom can be caught before 80 % on Flutter (`heroine` 0.7.2 flights are springs that redirect with their velocity when the sheet route pops). On the web it is a view transition and runs to completion; the web sheet itself (WEB-1's host) is catchable once it is on screen."
- **§5.2 `motion.catch`:** "(sheet, droplet, toast, image viewer, the Flutter poster zoom before 80 %)".
- **Velocity on the web:** a thrown poster's velocity is still handed to the web zoom. In the `<ViewTransition onShare>` callback, the keyframe easing is generated at navigation time from `{springZoom, v0}` with the same `linear()` sampler `build.mjs` uses, and applied with `instance.new.animate(keyframes, { duration: settleMs, easing })`.

### STACK-16 (medium): per-tab stacks on one browser history

Write into §7.37 **Source** and §8.0.4 **Tab switch** (web):

- **Recording.** Each recorded level in `mm.glass.stack` gains `seq` and `scrollY`. `seq` is a per-browser-tab counter. After every Glass navigation (a Next navigation, or a WEB-1 sheet `pushState`), the shell writes it into the current entry with `history.replaceState({ ...history.state, mmSeq: seq }, "")`. This keeps Next's own state keys.
- **Tab switch (web):** `router.push(lastPathOf(tab), { scroll: false })`, then restore that level's `scrollY`. No history entries are removed.
- **Back-menu row:** let `n` be the number of the current tab's levels above the chosen row.
  - If `history.state.mmSeq − row.seq === n`, the levels are contiguous in history: call `history.go(−n)`.
  - Otherwise, call `router.push(row.path, { scroll: false })`, restore its `scrollY`, and trim the tab's recorded stack to that level.

### STACK-17 (medium): fonts on the share canvas

In §9.2.4 **Rendering** (web, `share-card.ts`):

- **Family names:** use each `next/font` object's generated family for both `document.fonts.load` and `ctx.font`. That is `googleSansFlex.style.fontFamily` for text and `googleSansCode.style.fontFamily` for the `mono` foot line.
- **Display numerals:** Canvas 2D cannot set `ROND` or `GRAD`, so the numerals use one static instance made for the canvas only.
  - File: `frontend/public/fonts/gsf-share-display.woff2`, cut by `fonttools varLib.instancer` from the same Google Sans Flex source as `GoogleSansFlexMM.ttf`, with `wght=720 ROND=100 GRAD=0 opsz=144 slnt=0 wdth=100`.
  - Subset: digits, Latin and punctuation, ≤ 60 KB.
  - Loading: `new FontFace("MMShareDisplay", "url(/fonts/gsf-share-display.woff2)")`, added to `document.fonts` and awaited before drawing.
- Flutter needs no change (`FontVariation`s apply in `RepaintBoundary.toImage`).

### STACK-18 (medium): a web tier-A frame gate

Add to §15.8, beside the Flutter **Device gate**:

- **Web gate** (foundation week): the Library screen with the nav row group, the dock group and the accessory at tier A is flung continuously for 10 s in Chrome on the Android flagship (120 Hz) and in desktop Chrome on the owner's display.
- A Chrome Performance trace must show a mean frame rate within 5 % of the display's refresh rate and at most 2 dropped frames per second.
- If it fails, register in §15.10: "tier A renders only while a bar group's backdrop is at rest; while it scrolls or flings, the group uses the frosted tier". This is a renderer-state rule applied on every device, like "maps rebuild only at rest", not a device tier.

### STACK-19 (low): text axes on glass (duplicate of CONSISTENCY-11, extended)

Apply CONSISTENCY-11's final fix once, and add:

1. **§3.5 Implementation:** "`--glass-rond` and `--glass-grad` stay **unregistered**. A registered custom property always has a value (its initial value), so `var(--glass-rond, var(--mm-type-<role>-rond))` would never fall back, and text on content would lose its role's `ROND`. To interpolate, a glass surface animates two registered twins, `@property --glass-rond-t` and `@property --glass-grad-t` (`syntax: "<number>"; inherits: false; initial-value: 0`), and sets `--glass-rond: var(--glass-rond-t); --glass-grad: var(--glass-grad-t)` on itself. Its descendants inherit the resolved numbers, and content outside glass keeps the fallback."
2. **§3.7 utility:** add `font-weight: var(--mm-type-<role>-wght)` beside `font-variation-settings`, so static fallback faces (system CJK) match the role's weight.

### STACK-20 (low): haptic libraries and the native channel

MOBILE-12's final fix (the §5.1 paragraph) applies once. In addition:

- **§5 Libraries:** "iOS impacts with an intensity go through `mm/platform` `haptics.impact {style: soft | light | medium | heavy | rigid, intensity}` (`UIImpactFeedbackGenerator(style:).impactOccurred(intensity:)`); `gaimon` 1.5.0, whose impacts take no intensity, is used only for `ahap:*` patterns (`Gaimon.patternFromData(json)`: Core Haptics on iOS, its waveform conversion on Android); `haptic_feedback` 0.6.5 for `selection`."
- The Android one-shot stays on `mm/platform` as §15.3 already says: `haptics.oneShot {ms: 12, amplitude: round(i × 255)}` → `VibrationEffect.createOneShot`.
- **§15.10:** add a row (next free G number): "§2.3 names the channel `mm/haptics` | Glass's channel is `mm/platform`, because it carries haptics, `a11y.*`, `audio.isMusicActive` and `gestures.setExclusionRects` | amendment (one name)".

### STACK-21 (low): one statement of generator ownership

Make §15.1 the single statement, and have §5.3, §2.8 and G2 repeat it:

- `design/build.mjs` writes the tokens (CSS, TS, Dart). It calls `design/build-haptics.mjs`, which writes, as G2 already says, both the AHAP files (`mobile/assets/haptics/glass/*.ahap.json`) and the motion-name unions (`frontend/src/skins/glass/motion.generated.ts`, `mobile/lib/skins/glass/motion_names.g.dart`).
- `design/lint-utilities.mjs` (Cinematic's S2, extended to `src/skins/glass/**`) is the utility-name check, and `design/check-contrast.mjs` is the contrast gate. `build.mjs --check` runs all three.

Specific edits:

- **§5.3:** replace "generated by `design/build.mjs`" with "generated by `design/build-haptics.mjs`, called from `build.mjs`".
- **§2.8:** replace "checked by `build.mjs --check`, which greps `src/skins/glass/**`" with "checked by `design/lint-utilities.mjs`, run by `build.mjs --check`".
- Add `motion.generated.ts` to the §15.2 tree and `motion_names.g.dart` to the §15.3 tree.

### STACK-22 (low): dependency ledger rows

- **`fantasticon`:** "4.1.0 | MIT | dev only (run with `npx` from `brand/` scripts; Node ≥ 22) | reused". It emits the `GlassGlyphs` TTF and a codepoint JSON. `brand/glass/glyphs.mjs` turns that JSON into `mobile/lib/skins/glass/icons/glass_glyphs.g.dart` (`static const IconData … = IconData(0x…, fontFamily: 'GlassGlyphs')`), in the same run that writes `phosphor.g.dart` (STACK-3).
- **`@resvg/resvg-js` 2.6.2:** status *reused*, dev only, run with `npx`.
- **`sox` 14.4.2:** status *reused*, "authoring only; the generated WAVs and loops are committed, so no CI runner (the iOS one included) needs `sox`". Replace "CI tool" and "(CI image)".
- **`@use-gesture/react` 10.3.1:** "reader, image viewer and guided-view pinch", in both §15.2 and §15.11.
- **`@base-ui/react`:** the list reads "Dialog, Menu, ContextMenu and Popover". Toasts use `sonner` 2.0.8 `toast.custom` only, in both §15.2 and §15.11.

### STACK-23 (low): a valid shared-cover transition name

- Replace `cover-{sourceId}-{seriesKey}` with `coverTransitionName(sourceId, seriesKey)` in §8.0.4, §15.2 **Routes** and the sheet-host paragraph WEB-1 added to §15.2.
- The name is Cinematic's: `cover-` + the 8-hex-digit 32-bit FNV-1a of `sourceId + "\u0000" + seriesKey`.
- The helper lives in the shared data layer at `frontend/src/features/sources/cover-transition-name.ts`, so both skins import it without crossing the skin boundary. `features/series/` does not exist; series detail data lives under `features/sources/`.

### STACK-24 (low): cross-skin field names and shapes

- **§15.5, §8.0.3 and §8.17** (supersedes PRODUCT-27's element shape): the row field is `tags: [{id, name, category, color}]`, the tag object of `GET /library/tags` (`capabilities.md` §12); `tag_ids=` is the `GET /library/series` query parameter (any-of).
- **§15.5 and the §15.6 Activity row:** `DELETE /circle/activity` → 204 is Cinematic's (its §9.3.6 and §15.5). The "Cinematic today" cell becomes "defines it; conforms".
- **§15.5 Wrapped row**, with element shapes (PRODUCT-11's added fields stay):
  - `busiest_day: {date: "YYYY-MM-DD", chapters: int, series: [{source_id, series_key, title, cover_url}] (≤ 5, non-mature only)} | null`
  - `firsts_lasts: {first: {series: {source_id, series_key, title, cover_url}, read_at}, last: {…same}} | null` (non-mature series only, matching Cinematic's `shareable` rule)
- **§9.3.7 and §15.5:** `GET /circle/members[].streak: {current_days: int, alive_today: bool} | null`, present only when that member's `share_streak` is on. Rename §9.3.7's `current` to `current_days`, matching every other streak object.

### STACK-25 (low): the Icon Composer bundle in CI

- **§12.2 / §12.6, and the native-plugin commit's CI dry run:**
  - Pin Xcode 26 in `.github/workflows/ios-build.yml` (`maxim-lobanov/setup-xcode@v1` with `xcode-version: '26.0'` on a runner image that carries it) and in `codemagic.yaml` (`xcode: 26.0`).
  - In `Runner.xcodeproj`, set `ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES` and list the alternate icons by the names the bundles carry: `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES = AppIcon-Glass` (plus Cinematic's alternate, under its own asset name). `flutter_dynamic_icon_plus` switches to those names.
  - The dry run proves that `actool` compiles `AppIcon-Glass.icon`.
- The PNG set stays what §12.2 already says it is: the fallback for iOS 18 and earlier devices.

### STACK-26 (low): shader prewarm after a switch into Glass

Replace §15.3's "`LiquidGlassWidgets.initialize()` before `runApp`" with:

"The Glass skin's `prepare()` awaits `LiquidGlassWidgets.initialize()` once per process (a static flag skips repeats). The shared boot function awaits `skin.prepare()` before building the router, both from `main()` when the stored skin is Glass and from the `AppRestart` path when switching into Glass, so the shaders are loaded before the Glass splash's first frame. Cinematic boots never load them."

### STACK-27 (low): the rain shader reads the backdrop

In §9.4.2 **Rain on glass** and §15.3:

- **Uniforms**, in this order: `uniform vec2 uSize` (first, set by the engine), `uniform float uTime`, `uniform vec3 uDrops[10]` (x, y, radius), then `uniform sampler2D uBackdrop` (the first sampler, which receives the filter input). Invert `uv.y` under `IMPELLER_TARGET_OPENGLES`.
- **Mounting:** the shader runs through `BackdropFilter(filter: ImageFilter.shader(rainShader))`, clipped to each capsule, and only when `ImageFilter.isShaderFilterSupported` (Impeller, the owner's devices).
- **Budget:** it counts as one extra layer in the §15.7 budget while the Rain scene plays with the chrome visible.

### STACK-28 (low): the web Lift turn

Add to §8.15.4 **Lift** (web):

- The live multi-column container stays the only interactive copy.
- **Pointer-down on a turn:** mount one `cloneNode(true)` of the container, with `inert` and `aria-hidden="true"`, inside a page-sized wrapper (`overflow: hidden; transform-style: preserve-3d; backface-visibility: hidden`) above the live one.
  - Forward: the clone is translated to page n and rotates away (`rotateY` 0 → −100°), while the live container moves to page n+1 beneath it.
  - Backward: the clone shows page n − 1 and rotates in from −100° over the live page n, and the live container moves to n − 1 on settle.
- **On settle or cancel:** remove the clone; a cancel returns the live container to page n. Text selection, find and search therefore stay on the single live container, and nothing is captured as a bitmap.

---

## Refuted

None. Every finding's defect was reproduced against its primary source. Where the finder's evidence or fix was wrong in part, the verdict says so and the fix above replaces it:

- STACK-6 (d): the controller does expose live position.
- STACK-6: `minDragDistance` does not exist.
- STACK-12: the cap of 4 layers.
- STACK-20: moving the one-shot to `gaimon`.
- STACK-21: a third script.
- STACK-24: dropping `alive_today`.
- STACK-25: the icon names.
