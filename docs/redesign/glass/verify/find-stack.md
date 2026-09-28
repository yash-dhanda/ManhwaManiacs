# Glass DESIGN.md: stack-feasibility audit

Lens: every package exists at the stated version and works with `frontend/package.json` (Next 16.2.9, React 19.2.4, Tailwind 4) and `mobile/pubspec.yaml` on Flutter 3.44.6 (Dart 3.12.2); every effect is implementable at 60/120 fps in Safari, Chrome and on flagship phones; folder layout, skin engine, token pipeline and restart flow match `stack-decision.md`; every backend endpoint exists in `inventory/capabilities.md` or is marked new with its request and response shape.

How it was checked (2026-09-28): npm registry metadata for every web package (`npm view`); pub.dev pubspecs and archives for every Flutter package (gaimon, flutter_soloud 4.1.7, share_plus 12.0.2, sensors_plus, audio_service, haptic_feedback, flutter_dynamic_icon_plus, swipeable_page_route, phosphor_flutter); the `liquid_glass_widgets` 1.7.2 and `smooth_sheets` 1.2.0 clones in `design-ref/`; the local Flutter 3.44.6 SDK source (`packages/flutter/pubspec.yaml`, `icon_data.dart`); `frontend/node_modules/next` (font data, vendored React, config defaults); `backend/routes/app_distribution.py`; `cinematic/DESIGN.md` §15.5, §15.10, §15.11 (the shared contract Glass claims to reuse). One scratch `dart analyze` of a two-file package (no Flutter build) confirmed the `final class` rule in STACK-3. Every "missing" claim was grepped across the whole of DESIGN.md first.

Result: 28 findings: 6 high, 12 medium, 10 low.

---

## STACK-1 · high · §15.3, §15.11, §6 (Playback), §9.4.2 (Playback engines): `flutter_soloud` 5.1.4 cannot resolve on Flutter 3.44.6

**Problem.** The ledger marks `flutter_soloud` 5.1.4 as *reused* (Cinematic adds it first), but Cinematic pins 4.1.7 precisely because every 5.x version fails version solving on this SDK. A Glass session following this file adds a second, unresolvable constraint.

**Evidence.**
- DESIGN §15.11: "| `flutter_soloud` | 5.1.4 | MIT | native (C++ FFI) | UI sounds and the soundscape mixer | reused |"; §6: "`flutter_soloud` 5.1.4 on mobile"; §9.4.2: "Phones: `flutter_soloud` 5.1.4".
- pub.dev: `flutter_soloud` 5.1.4 depends on `native_toolchain_c ^0.19.4`, `hooks ^2.2.0`, `code_assets ^2.0.0`; `native_toolchain_c` 0.19.4 depends on `meta ^1.19.0`. Flutter 3.44.6 `packages/flutter/pubspec.yaml` line 18: `meta: 1.18.0` (exact pin).
- `cinematic/DESIGN.md` §15.11: "`flutter_soloud` | 4.1.7 | … 5.x needs `native_toolchain_c ^0.19.4`, which needs `meta ^1.19.0`, and Flutter 3.44.6 pins `meta` 1.18.0."

**Fix.** Replace 5.1.4 with `flutter_soloud: 4.1.7` in §6, §9.4.2, §15.3 and §15.11 (status stays *reused*). Every API Glass calls exists in 4.1.7 (`SoLoud.instance.loadMem`, `loadFile`, `setVolume(handle, v)`, `fadeVolume(handle, to, Duration)`, checked in the 4.1.7 archive). Revisit only with the Flutter upgrade (stack risk 10).

## STACK-2 · high · §15.3, §15.11, §9.2.4 (Rendering): `share_plus` 13.3.0 cannot resolve against the existing pubspec

**Problem.** `share_plus` 13.x needs `win32 ^6`; three packages already in `mobile/pubspec.yaml` pin `win32` 5.x. Cinematic already moved to 12.0.2 for this reason; Glass still names 13.3.0 and calls it *reused*.

**Evidence.**
- DESIGN §15.11: "| `share_plus` | 13.3.0 | BSD-3-Clause | native | Share cards | reused |"; §9.2.4: "shares with `share_plus` 13.3.0".
- pub.dev: `share_plus` 13.3.0 → `win32: ^6.0.1`. Pub cache: `file_picker-8.3.7` → `win32: ^5.9.0`; `flutter_secure_storage_windows-3.1.2` → `win32: ^5.0.0`; `package_info_plus` 8.3.1 → `win32: ^5.5.3`.
- `cinematic/DESIGN.md` §15.11: "`share_plus` | 12.0.2 | … 13.x needs `win32 ^6`."

**Fix.** Pin `share_plus: 12.0.2` in §9.2.4, §15.3 and §15.11. The call Glass writes is unchanged: `SharePlus.instance.share(ShareParams(files: [XFile.fromData(bytes, mimeType: "image/png", name: "manhwamaniacs-2026.png")]))` (`SharePlus` exists in 12.0.2's `lib/share_plus.dart`).

## STACK-3 · high · §2.7, §15.3, §15.11: `phosphor_flutter` 2.1.0 does not compile on Flutter 3.44.6

**Problem.** Flutter 3.44.6 declares `IconData` as a `final class`, and `phosphor_flutter` 2.1.0 (its last release, 2024-05-10) subclasses it. Class modifiers are enforced even for a dependency whose SDK floor is 2.12, so every file that imports `phosphor_flutter` fails to compile. `flutter pub get` still resolves (which is why the resolution gate would not catch it before `flutter analyze`), but the icon set of the whole skin is unbuildable. Cinematic names the same package, so this is a shared defect.

**Evidence.**
- DESIGN §2.7: "`@phosphor-icons/react` 2.1.10 and `phosphor_flutter` 2.1.0"; §15.11: "| `phosphor_flutter` | 2.1.0 | MIT | pure Dart (font) | The icon set | reused | The Phosphor TTF with a generated `IconData` class |".
- Flutter SDK `packages/flutter/lib/src/widgets/icon_data.dart` line 23: `final class IconData {`.
- `phosphor_flutter` 2.1.0 `lib/src/phosphor_icon_data.dart` line 5: `class PhosphorIconData extends IconData {`; pubspec `sdk: '>=2.12.0 <4.0.0'`.
- Scratch check with the SDK's `dart` 3.12.2: package `b` (`sdk: '>=2.12.0 <4.0.0'`) extending a `final class` from package `a` → "error - The class 'IconDataX' can't be extended outside of its library because it's a final class. - invalid_use_of_type_outside_library".

**Fix.** Use the ledger's fallback now, not as a contingency: bundle the Phosphor 2.1 font files (`Phosphor.ttf`, `Phosphor-Fill.ttf`, `Phosphor-Duotone.ttf`, `Phosphor-Light.ttf`, `Phosphor-Bold.ttf`; the same six files ship in `@phosphor-icons/web` 2.1.2, MIT, and in the `phosphor_flutter` 2.1.0 archive's `lib/fonts/`) under `mobile/assets/fonts/phosphor/`, declare them in `pubspec.yaml` `fonts:`, and generate `mobile/lib/skins/glass/icons/phosphor.g.dart` with plain constants (`static const IconData houseSimple = IconData(<codepoint from the font's JSON>, fontFamily: 'PhosphorRegular');`, never a subclass) in the same build step that emits `GlassGlyphs` (STACK-22). Duotone renders as a `Stack` of the duotone font's two glyphs (secondary layer at 0.2 opacity). Change §15.11's row to "`phosphor_flutter` — not used (IconData is final on Flutter ≥ 3.44); Phosphor TTFs + generated `IconData` constants, added here", and tell Cinematic the same.

## STACK-4 · high · §9.4.3 (Data), §15.5, §15.4: the guided-view panel contract Glass calls "Cinematic's" does not exist in Cinematic

**Problem.** Glass specifies a server-side panel detector and a `GET /reader/panels` endpoint and labels both "shared with Cinematic". Cinematic's registered decision S11 is the opposite: panels are detected on the client, the backend only stores client reports, and the image proxy never analyses pages. Neither `GET /reader/panels` nor `panels_ready` appears in Cinematic or in `capabilities.md`, so the backend session would get two incompatible contracts for one engine duty (`panelBoxes` / `panels`).

**Evidence.**
- DESIGN §9.4.3: "`GET /reader/panels?source&series&chapter` (shared with Cinematic) returns `pages: [{number, panels: [{x, y, w, h}]}]` … computed server-side from the page proxy (a whitespace and blackspace gutter projection in Pillow) … the manifest carries `panels_ready: bool`." §15.5: "| `GET /reader/panels` + `panels_ready` (Cinematic's) | Guided view |".
- `cinematic/DESIGN.md` §15.5: "`pages[].panels` (optional) in manifests, filled only from client reports: `POST /reader/panels {source_id, series_key, chapter_key, pages: [{page, panels}]}`, stored per page ETag; the image proxy does no image analysis (S11)". §15.10 S11: "Panel detection runs on the client … the backend only caches client reports".

**Fix.** Adopt S11 in Glass: replace §9.4.3 "Data" with "Panels come from the manifest's `pages[].panels` when an earlier read reported them; otherwise the shared engine's on-device detector (the page-tint worker on the web, `ResizeImage(width: 360)` + `compute()` on Flutter, one page ahead of the reading position) produces them, and the engine posts `POST /reader/panels {source_id, series_key, chapter_key, pages: [{page, panels}]}` → 204 on chapter exit." Rewrite the states: "Finding panels…" = the detector running for the current page; drop "not ready (the backend finishes)" and `panels_ready`; the `panel-focus` button shows once the current page has panels. Change the §15.5 row to "`pages[].panels` + `POST /reader/panels` (Cinematic's S11)" and add S11 to the §15.10 table as "conforms". `panelBoxes` in §15.4 is then Cinematic's `panels` for the current page (one field, not two).

## STACK-5 · high · §8.0.3 (`feature`, `recap`, `circleMember`, `profileNew`/`profileEdit`), §7.10 "Behind", §7.37, §15.2 Routes: web route-sheets over a live, receding page have no Next.js mechanism

**Problem.** On the web these routes are presented as sheets or windows over the page that pushed them, with that page receding by sheet position; a deep link renders a full page. The stack's App Router model (thin route files that each render one screen) unmounts the previous page on navigation, and DESIGN itself says so in §7.37. Nothing names the only App Router construct that keeps the covered page mounted (parallel routes plus intercepting routes), so an implementation session either builds full-page routes (wrong presentation) or invents a mechanism in the shared `app/` folder.

**Evidence.**
- DESIGN §8.0.3: "`feature` … Sheet (medium → large) / 960 px window over the recessed page; a deep link without a parent renders it as a full page"; "`recap` … Sheet over the series detail (a deep link opens the series sheet first, then the recap sheet over it)"; "a friend is a sheet / window".
- §7.37 line 1886: "The App Router cannot keep covered pages mounted, so the web never fans live screens".
- `stack-decision.md` §2.2: "app/ thin route files only: export default async () => { const S = skins[await getSkin()].screens.library; return <S/>; }". No `@slot` or `(.)` route appears in DESIGN.md, `cinematic/DESIGN.md` or `stack-decision.md` (grepped "intercept", "parallel route", "@modal", "(.)").

**Fix.** Specify the web mechanism in §15.2 and register it as §15.10 row G14 (amendment to stack §2.2):
- `frontend/src/app/layout.tsx` renders `{children}{sheet}{overSheet}`; `app/@sheet/default.tsx` and `app/@overSheet/default.tsx` return `null`.
- Intercepting thin routes: `app/@sheet/(.)sources/[sourceId]/series/[seriesKey]/page.tsx`, `app/@sheet/(.)library/[followedId]/page.tsx`, `app/@sheet/(.)circle/[profileId]/page.tsx`, `app/@sheet/(.)profiles/new/page.tsx`, `app/@sheet/(.)profiles/[id]/edit/page.tsx`, and `app/@overSheet/(.)recap/[sourceId]/[seriesKey]/page.tsx` (the recap stacks over the feature sheet). Each renders `skins[skin].sheets?.[id] ?? <OpaqueLayer>{skins[skin].screens[id]}</OpaqueLayer>`, so Cinematic (no `sheets`) still shows a full-screen page; add `sheets?: Partial<Record<ScreenId, Screen>>` to the `Skin` interface in `skins/types.ts`.
- Hard loads and deep links hit the normal `app/sources/[sourceId]/series/[seriesKey]/page.tsx`, which renders the full page (as DESIGN already says).
- The recede is applied by the Glass `Shell` to the `{children}` wrapper from a sheet-position context (`transform: scale(…)`, `border-radius`, `filter: blur(…) brightness(…)`), never by the sheet itself.
- The ESLint boundary rule of stack §2.2 exempts `app/@*/**` like every other route file.

## STACK-6 · high · §15.3 (Sheets), §7.10, §4.4, §4.6, §8.0.3 (URL state), §8.0.5 (Android sheets): `GlassModalSheet` cannot implement the sheet contract, and the stack's sheet package is dropped without an amendment

**Problem.** The Flutter sheet is specified as `liquid_glass_widgets`' `GlassModalSheet`, but in 1.7.2 that widget (a) settles on a hard-coded spring, not `sheetSnap` or `sheet`; (b) chooses the detent by a velocity threshold plus a 40 % progress rule, not by projection; (c) has one `velocityThreshold` (default 700) for both snapping and dismissal, where §4.6 needs 1500 px/s for dismissal only; (d) reports only settled states, so `sheet.pass` per detent passed and the position-driven recede cannot be driven; (e) is shown imperatively through `showGeneralDialog`, so it is not a go_router `Page` and cannot back the URL-state sheets (`?sheet=`, `feature`, `recap`, `circleMember`) or carry the custom `PredictiveBackRoute` §8.0.5 asks for. The stack lists `stupid_simple_sheet` 0.9.1+1 (and `smooth_sheets` 1.2.0) for these sheets; Glass swaps in `GlassModalSheet` with no §15.10 row.

**Evidence.**
- DESIGN §15.3: "Sheets use `liquid_glass_widgets`' `GlassModalSheet` with `peekSize: 96`, `halfSize: 0.52`, `horizontalMargin: 8` …". §7.10: "release projects the top edge (§4.4) and picks a detent → `sheetSnap` with the release velocity; `sheet.pass` ticks as detents are passed during a drag". §4.6: "Sheet dismiss | … or downward velocity ≥ 1500 px/s".
- `liquid_glass_widgets` 1.7.2 `glass_modal_sheet_state.dart` lines 226–231: `SpringSimulation(const SpringDescription(mass: 1.0, stiffness: 220.0, damping: 30.0), …)`; `glass_modal_sheet_mechanics.dart` lines 311–349: `if (velocity > velocityThreshold) …` / `progress >= snapThreshold ? s2 : s1`; `glass_modal_sheet.dart` line 472: `return showGeneralDialog<T>(`, defaults `velocityThreshold = 700.0`, `snapThreshold = 0.4`. `sheetSnap` is k 223.8, c 26.33 (§4.2).
- `stack-decision.md` §1: "Flutter gets a shader imitation through `liquid_glass_widgets`, plus `swipeable_page_route` and `stupid_simple_sheet`"; §3 pinned list includes `stupid_simple_sheet 0.9.1+1`. §15.10 has no row for the change (grepped "stupid").

**Fix.** Build the Flutter `GlassSheet` primitive on `smooth_sheets` 1.2.0 (already in the stack list and ledger): `ModalSheetPage<T>` as the go_router `pageBuilder` for every sheet route and `?sheet=` id; a `GlassSheetPhysics extends SheetPhysics with SheetPhysicsMixin` whose `spring` returns `GlassSprings.sheetSnap.description` and whose ballistic target comes from a `GlassSnapGrid implements SheetSnapGrid` returning the detent nearest to `project(offset, velocity)` (peek 96 px, medium 0.52 × height, large = height − safe-top − 10); `swipeDismissSensitivity: SwipeDismissSensitivity(minFlingVelocityRatio: 1500 / sheetHeight, minDragDistance: 0.5 × lowestDetentHeight)`; the recede and the inset/radius/material lerps from `SheetOffsetDrivenAnimation`; `sheet.pass` from a `SheetNotification` listener crossing detent offsets; the material from `SkinGlass(tier: T4)` inside the sheet. `transitionCurve` for button-present is a `Curve` sampled from the `sheet` spring over its 494 ms settle. Keep `GlassModalSheet` out. Add §15.10 row G15: "stack §1/§3 name `stupid_simple_sheet`; Glass uses `smooth_sheets` 1.2.0 for every sheet because it offers a go_router `Page`, pluggable spring physics and offset-driven animation" and drop `stupid_simple_sheet` from §15.11 explicitly.

---

## STACK-7 · medium · §6 ("One audio session, one owner"), §9.4.2 (Your own music), §15.3 (`audio_service`): Glass's narration session is mixable, which removes the iOS lock-screen controls, and it contradicts the one shared owner Cinematic defines

**Problem.** Glass's `narration` state sets `.playback + .duckOthers`. On iOS `.duckOthers` implies `.mixWithOthers`, and a mixable session cannot become the Now Playing app, so the `audio_service` 0.18.19 lock-screen and Control Center controls that §15.3 relies on ("the listen lock screen, shared with Cinematic") do not appear. Glass also makes `mobile/lib/skins/glass/soundscape/mixer.dart` the owner of `AVAudioSession`, while Cinematic makes `mobile/lib/skins/skin_audio.dart` the only owner and narration (shared data layer) uses its State B. With both skins in one binary, the shared narration controller cannot follow two owners with different Android focus types.

**Evidence.**
- DESIGN §6 table: "`narration` | … `.playback` + `.duckOthers`, mode `.spokenAudio` | `AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK`"; "a single state machine (`mobile/lib/skins/glass/soundscape/mixer.dart` …) owns it".
- `cinematic/DESIGN.md` §6: "only `mobile/lib/skins/skin_audio.dart` configures `AudioSession.instance`"; State B: "`AudioSessionConfiguration.speech()` (`.playback`, mode `.spokenAudio`) | `AUDIOFOCUS_GAIN`".
- Apple `AVAudioSession.CategoryOptions.duckOthers`: setting it also sets `mixWithOthers`; Now Playing eligibility requires a non-mixable playback session.

**Fix.** One owner for both skins: `mobile/lib/skins/skin_audio.dart` (shared). Glass's mixer requests states from it and never calls `AudioSession.instance.configure`. Glass's `narration` state = Cinematic's State B exactly (`AudioSessionConfiguration.speech()`, `AUDIOFOCUS_GAIN`, usage media, content speech, no `duckOthers`); the soundscape ducks itself by 12 dB inside the app as §6 already says. Glass's `soundscape` state (`.playback + .mixWithOthers`, no focus request) and `idle` (`.ambient + .mixWithOthers`) become named states of `skin_audio.dart`. Add the audio session to the §15.6 alignment table.

## STACK-8 · medium · §9.4.2 (Recorded layers, Playback engines): SoLoud has no AAC decoder, so iOS recorded layers fetched as `.m4a` never play

**Problem.** Glass ships recorded layers as AAC `.m4a` "for iOS" and loads cached recordings on phones with `flutter_soloud` `loadFile`. SoLoud decodes MP3, WAV, OGG (Vorbis, Opus, FLAC) and FLAC only; it does not use AVFoundation, so an `.m4a` file fails to load and iOS silently stays on the procedural fallback forever.

**Evidence.** DESIGN §9.4.2: "Opus 96 kb/s in `.ogg` (web, Android) and AAC-LC 96 kb/s in `.m4a` (iOS and Safari)"; "cached recordings load with `loadFile`". `flutter_soloud` 4.1.7 README line 30: "Support for MP3, WAV, OGG, and FLAC".

**Fix.** Phones (iOS and Android) always fetch `.ogg` (Opus 96 kb/s) for SoLoud; `.m4a` is fetched only by Safari on the web, chosen by `new Audio().canPlayType('audio/ogg; codecs="opus"') === ""` before `decodeAudioData`. Keep both files on the server.

## STACK-9 · medium · §9.4.2, §15.5: the soundscape URL is served by no route and contradicts Cinematic's soundscape endpoint

**Problem.** Glass says its 18 layers are "served by the backend's static media route as `/app/media/soundscapes/glass/{scene}-{bed|detail|tone}.{ogg|m4a}` next to Cinematic's loops". The existing `/app/media/{name}` route takes one path segment, keeps only the basename, serves only image suffixes and reads the screenshots directory; Cinematic's loops are on a different, allowlisted route. As written the URL 404s and the backend session has no route to extend.

**Evidence.**
- `backend/routes/app_distribution.py` line 1985: `@router.get("/app/media/{name}")` … `safe = Path(name).name` … `_ALLOWED_MEDIA_SUFFIXES = {".png", ".jpg", ".jpeg", ".webp", ".gif"}`, directory `SCREENSHOTS_DIR`.
- `cinematic/DESIGN.md` §15.5: "`GET /app/soundscapes/{id}.{ext}` (public under `/app/*`): `id` one of `projector-room, …, temple-bells`, `ext` `ogg` or `m4a`, read from `backend/media/soundscapes/` … anything else 404. The existing `/app/media/{name}` route serves screenshots only".

**Fix.** Extend Cinematic's route: allow the 18 ids `glass-{rain|wind|ocean|hearth|stream|deep}-{bed|detail|tone}` on `GET /app/soundscapes/{id}.{ext}`, files in `backend/media/soundscapes/` (same `MM_SOUNDSCAPES_DIR`, `SOURCES.md` lines per file), `FileResponse` with Range, `Content-Type: audio/ogg` or `audio/mp4`, `Cache-Control: public, max-age=31536000, immutable`. Replace the URL in §9.4.2 and the §15.5 row ("Soundscape layers: 18 ids added to Cinematic's `GET /app/soundscapes/{id}.{ext}` allowlist, 36 files"). The web cache key `mm-soundscapes-v1` stays.

## STACK-10 · medium · §8.7 (Storage, Resume, step 6), §15.5, §15.6 (Taste row): the onboarding taste contract conflicts with the one Cinematic already defined

**Problem.** Glass says it "adds `styles`, `seeds` and `onboarding_step`" to `PUT /profiles/{id}/taste`, and §15.6 marks Taste "conforms". Cinematic already defines `styles` and `seeds`, names the progress field `step` (values `1`–`5` or `"done"`), exposes it as `onboarding_step` on `GET /profiles`, and provides the seed catalogue as `GET /onboarding/catalog`. Glass sends `onboarding_step: n` (1–7, no terminal value), uses a different style vocabulary, and adds a second seed endpoint `POST /library/taste/seed` for the same job. The backend cannot satisfy both.

**Evidence.**
- DESIGN §8.7: "`PUT /profiles/{id}/taste {formats: [...], genres: {name: weight}, styles: [...], seeds: [...], onboarding_step: n}` (… Glass adds `styles`, `seeds` and `onboarding_step`)"; step 5 crops include "watercolour" and "dark realism"; step 6 "drawn … by `POST /library/taste/seed`".
- `cinematic/DESIGN.md` §8.7 Backend: "`PUT /profiles/{id}/taste {step, formats, genres, styles, seeds}` (… `step` is `1`–`5` or `"done"`) … `styles: ["painted" | "cel" | "screentone" | "manhua-3d" | "sketch" | "retro" | "pastel" | "noir" | "chibi"]`"; "`GET /onboarding/catalog?formats=&genres=&styles=` (new) returns … `seeds: WorldItem[]`, 24 items"; §15.5: "`GET /profiles` rows carry `onboarding_step`".

**Fix.** One payload for both skins: `PUT /profiles/{id}/taste {step: 1..7 | "done", formats, genres, styles, seeds}` (widen Cinematic's `step` to 1–7; Cinematic uses 1–5). Shared `styles` enum = the union of 11 ids: `painted, cel, screentone, manhua-3d, sketch, retro, pastel, noir, chibi, watercolour, dark-realism` (Glass sends its 9: `painted, cel, screentone, manhua-3d, watercolour, sketch, retro, chibi, dark-realism`). Resume reads `GET /profiles[].onboarding_step`; "Finish" and "Skip" send `step: "done"`. Step 6 uses `GET /onboarding/catalog` `seeds`, shows only items with non-empty `available[]`, and follows `available[0]` through `POST /library/follow {source_id, series_key}`; delete `POST /library/taste/seed` from §8.7, §9.1.6, §15.5 and Appendix A. Change the §15.6 Taste row to state this resolution.

## STACK-11 · medium · §8.28 (Offline fallback), §8.25.2 step 2, §15.2 (Service worker): the shared service worker gets two incompatible skin mechanisms

**Problem.** There is one `frontend/public/sw.js` for both skins. Cinematic's worker serves `offline-fallback-{skin}.html` from a skin value the page posts on every boot (`{type: "skin", skin}`) and on a switch (`{type: "skin-changed", skin}`). Glass specifies one fallback file with both skins' CSS and posts `{ type: "skin-changed" }` without a `skin`, and never posts on boot. Under Cinematic's worker a Glass user offline gets Cinematic's fallback (its default when nothing is stored), and the Glass file never ships.

**Evidence.**
- DESIGN §8.28: "one static file carrying both skins' CSS; a four-line inline script reads the `mm-skin` cookie"; §8.25.2 step 2: "the web posts `{ type: "skin-changed" }` to the service worker".
- `cinematic/DESIGN.md` §15.2: "the page posts `{ type: "skin", skin }` … on every boot and `{ type: "skin-changed", skin }` on a switch … On an offline navigation it serves `offline-fallback-{skin}.html`"; §8.32: "`offline-fallback-cinematic.html` when nothing is stored".

**Fix.** Conform to Cinematic's worker: the Glass `Shell` posts `{ type: "skin", skin: "glass" }` to `navigator.serviceWorker.controller` on every boot, the switch posts `{ type: "skin-changed", skin: "cinematic" }`, and Glass ships `frontend/public/offline-fallback-glass.html` (self-contained, inline CSS, the §8.28 content). Remove the "one static file … reads the `mm-skin` cookie" sentence and fix §15.2's "chosen by the `mm-skin` cookie".

## STACK-12 · medium · §2.5 (Budget), §15.7 (bullet 2 and the per-frame table), §8.25.12: "one `BackdropGroup` per Flutter screen, at most eight members" cannot be built on `liquid_glass_widgets`

**Problem.** Every `LiquidGlassLayer` in 1.7.2 wraps its own `BackdropGroup` unconditionally, and sheets, menus and toasts live in other routes or `Overlay` entries, so a screen's glass can never share one group. The budget unit ("BackdropGroup members") and the Diagnostics counter therefore have no well-defined implementation.

**Evidence.** DESIGN §2.5: "On Flutter every `BackdropFilter` on one screen joins one `BackdropGroup` (`BackdropFilter.grouped`)"; §15.7: "all backdrop filters on a Flutter screen in one `BackdropGroup` … eight `BackdropGroup` members per Flutter screen". `liquid_glass_widgets` 1.7.2 `lib/src/engine/liquid_glass_layer.dart` line 242: `return BackdropGroup(child: _ScaleSafeRepaintBoundary(…` inside every layer's `build`.

**Fix.** Restate the Flutter budget in the engine's own units: at most **4 `LiquidGlassLayer`s** live per frame (nav row group; dock + orb + accessory; one sheet, menu or popover; one toast or HUD), with sibling shapes of a bar group as `LiquidGlass` children of one layer, and at most **8 glass shapes** in total. `SkinGlass` keeps a registry that counts layers and shapes for the Diagnostics row "Glass layers on screen" (warning above 4 layers or 8 shapes). Keep "one `BackdropGroup` per screen" only for the `BackdropFilter` frosted fallback path. Update the §15.7 table's Flutter column to "layers / shapes".

## STACK-13 · medium · §15.3 (`GlassAccessibilityScope`), §4.11: the engine's default maps iOS Increase Contrast to Reduce Transparency and would override Glass's rules

**Problem.** `GlassAccessibilityScope` without arguments takes `reduceTransparency` from `MediaQuery.highContrastOf`, so on an iPhone with Increase Contrast every glass surface switches to the library's frosted panel. §4.11 wants Increase Contrast to keep the glass and add `hcBorder` and a raised dim floor, and wants Reduce Transparency and Solid glass to use `solid1`/`solid2`, not the library's frosted panel. DESIGN names the scope but not its arguments.

**Evidence.** DESIGN §15.3: "`SkinGlass` … `GlassAccessibilityScope`"; §4.11: "**Increase Contrast** adds `hcBorder` … raises `dimLegibility`'s floor from 0.22 to 0.40". `liquid_glass_widgets` `glass_accessibility_scope.dart`: "Reduce Transparency — MediaQuery.highContrastOf(context) … AdaptiveGlass replaces the glass shader with a solid frosted surface"; `reduceTransparency: reduceTransparency ?? MediaQuery.highContrastOf(context)`.

**Fix.** In `skin_glass.dart`: `GlassAccessibilityScope(reduceMotion: ref.watch(glassMotionPrefsProvider).reduced, reduceTransparency: false, child: …)` always, and `SkinGlass` itself renders `solid1`/`solid2` (never a library widget) when `mm/platform a11y.reduceTransparency || solidGlass`. Wrap the app with `LiquidGlassWidgets.wrap(child: …, respectSystemAccessibility: false, adaptiveQuality: false)` so neither accessibility nor the experimental adaptive quality (a device tier the owner ruled out) is applied behind `SkinGlass`'s back. Add these two lines to §15.3.

## STACK-14 · medium · §2.4.1 (Budget per screen), §7.15 (droplet, metaball neck), §15.2 (`liquid-map.ts`): one masked `backdrop-filter` element per bar group is incompatible with a per-shape displacement map and with glass nested inside it

**Problem.** Web tier A gives each bar group one element whose `backdrop-filter: url(#lens-{w}x{h})` is masked to several shapes, but the map generator is keyed by a single rounded rectangle `(w, h, r, tier)`, so it cannot describe a group (leading button + title capsule + trailing group, or dock + orb). Separately, an element with `backdrop-filter` or `mask` is a Backdrop Root: a second glass element inside it (the dock's `glassThin` droplet, the metaball neck) samples only the group's own pixels, not the page, so it cannot refract the content beneath.

**Evidence.** DESIGN §2.4.1: "each floating bar group … is **one** element whose backdrop is masked to its shapes with an SVG `mask-image`"; §15.2: "`liquid-map.ts` displacement map generator … cached per (w, h, r, tier)"; §7.15: "the selection indicator is a `glassThin` clear droplet"; "the two surfaces merge with a metaball neck". Filter Effects Level 2, Backdrop Root: triggered by `filter`, `opacity < 1`, `mask`, `clip-path`, `backdrop-filter`, `mix-blend-mode`.

**Fix.** Key the web map by the group's shape list: `liquidMap(shapes: [{x, y, w, h, r, tier}], groupW, groupH)` draws every shape's bezel into one map (cache key = the rounded shape list), and the mask is the same shape list. The droplet and the neck are not separate `backdrop-filter` elements: the droplet is an extra shape in the dock group's map and mask (its lensing drawn by the map), and during a droplet drag or a neck merge the group switches to the frosted tier (maps rebuild only at rest, as §15.2 already requires) and returns to tier A on settle. State this in §2.4.1 and §7.15.

## STACK-15 · medium · §4.9 (route transitions), §5.2 `motion.catch`, §8.0.4: catchable route transitions are impossible with the chosen route mechanisms

**Problem.** §4.9 promises that route transitions are springs on a controller: a back swipe during a push grabs the incoming page, and a poster → detail zoom can be caught and dragged back until 80 %. On the web every push is a React `<ViewTransition>` run as CSS keyframes, during which pointer input does not reach the page and the animation cannot be reversed. On iOS `SwipeablePage` refuses a pop gesture while the push animation runs, and Android pushes use `PredictiveBackPageTransitionsBuilder` (a duration-driven controller).

**Evidence.** DESIGN §4.9 lines 1101–1107; §8.0.4: "Web: React `<ViewTransition>` with `transitionTypes={['nav-forward']}`, CSS keyframes eased by the `page` spring's `linear()` export"; §8.0.5: "`swipeable_page_route` 0.4.8 `SwipeablePage(…)`", "`MaterialPage` with `PredictiveBackPageTransitionsBuilder`". `swipeable_page_route` 0.4.8 `lib/src/page_route.dart` line 185: `// If we're in an animation already, we cannot be manually swiped. if (route.animation!.status != AnimationStatus.completed) return false;`.

**Fix.** Scope §4.9 honestly: catchable in flight = sheets (STACK-6), the dock droplet, toasts, the image viewer and the `heroine` poster zoom on Flutter (motor springs). Route pushes and pops are not catchable on either client: on Flutter the back swipe starts once the push animation has completed; on the web a view transition runs to completion and input during it is ignored. Keep velocity hand-off on the web by generating the keyframe easing at navigation time from `{page spring, v0}` in the `<ViewTransition onEnter / onShare>` callbacks (`instance.new.animate(keyframes, { duration: settleMs, easing: linear(…) })`). Update §5.2 `motion.catch` to "(sheet, droplet, toast, image viewer, Flutter poster zoom before 80 %)".

## STACK-16 · medium · §7.37 (Back menu Source), §8.0.4 (Tab switch), §8.0.8 purge step 2: per-tab stacks on the web versus one linear browser history

**Problem.** The web keeps "its own stack and scroll offset" per dock tab or sidebar section, and the back menu pops to a level with `history.go(−n)` where n is the number of levels above it in the current tab's stack. The browser has one linear history: after the reader switches tabs and back, history entries of the other tab sit between the levels, so `history.go(−n)` lands on the wrong page. How a tab switch restores that tab's top route on the web is not specified at all.

**Evidence.** DESIGN §7.37: "the Glass shell records a per-browser-tab stack in `sessionStorage['mm.glass.stack']` (an array of `{path, title, depth, tab, mature}` …). Choosing a row calls `history.go(−n)`, where `n` is the number of levels above it." §8.0.4: "Tab switch … each tab keeps its own stack and scroll offset".

**Fix.** Web tab switch = `router.push(lastPathOf(tab))` with the scroll offset restored from `mm.glass.stack` (`{…, scrollY}` added to each level). Each recorded level also stores `seq`, a per-tab-session counter written into `history.state` with `history.replaceState({...history.state, mmSeq})` after each Next navigation. Back-menu row: if every history entry between the current `mmSeq` and the row's `seq` belongs to the same tab, `history.go(−(currentSeq − rowSeq))`; otherwise `router.push(row.path)` and trim the stack to that level. Write this rule into §7.37.

## STACK-17 · medium · §9.2.4 (Rendering), §9.2.3 (`type.wrappedNumeral`): the web share canvas cannot find the font by name and cannot set the ROND and GRAD axes

**Problem.** `next/font/google` registers Google Sans Flex under a generated family name (exposed as `font.style.fontFamily`, for example `'__Google_Sans_Flex_1a2b3c'`), so `document.fonts.load('600 64px "Google Sans Flex"')` and a matching `ctx.font` resolve to a fallback face and every exported card is drawn in the wrong font. Canvas 2D also has no `font-variation-settings`, so the `ROND 100` numerals the card and its share side are specified with cannot be drawn on the canvas.

**Evidence.** DESIGN §9.2.4: "web draws the card on a `<canvas>` (fonts awaited with `document.fonts.load('600 64px "Google Sans Flex"')`"; §9.2.3: "Big numbers use `type.wrappedNumeral` (88/88, Google Sans Flex `wght` 720, `ROND` 100 …)"; §3.1: `Google_Sans_Flex({ … variable: "--mm-font-sans" })`.

**Fix.** In `share-card.ts` use the `next/font` object's family (`googleSansFlex.style.fontFamily`) for both `document.fonts.load` and `ctx.font`. For the ROND 100 display face add one static instance for the canvas only: `frontend/public/fonts/gsf-share-display.woff2`, generated by `fonttools varLib.instancer` with `wght=720 ROND=100 GRAD=0 opsz=144 slnt=0 wdth=100` (subset Latin, ≤ 60 KB), loaded with `new FontFace("MMShareDisplay", "url(/fonts/gsf-share-display.woff2)")` before drawing. Flutter needs nothing (its `FontVariation`s apply in `RepaintBoundary.toImage`).

## STACK-18 · medium · §15.8 (Device gate), §15.7: web tier A has no performance gate, while Flutter glass has one

**Problem.** The only frame-rate proof in the contract is the Flutter foundation-week gate. The web runs up to six SVG `feDisplacementMap` backdrop filters per frame (three displacement passes each on T4/T5 for dispersion), re-evaluated on every scroll frame beneath the nav row, dock and accessory, and "flagship-only" includes Chrome on the owner's Android phone. Nothing says how 120 Hz is verified there or what happens if it is missed, so the first implementation session has to invent both.

**Evidence.** DESIGN §15.8: "**Device gate** … the `liquid_glass_widgets` tab bar + a detented sheet over a scrolling rail at 120 Hz on the iPhone and the Android flagship"; §2.4.3 Web mapping: "dispersion is three displacement passes at scale × 1.00 / 1.02 / 1.04"; §15.7: "at most six live `backdrop-filter` elements per web screen". No web counterpart in §15.8 (grepped "trace", "Performance panel", "web gate").

**Fix.** Add to §15.8 a web gate in the foundation week: Library with the nav row group, dock group and accessory at tier A, flung for 10 s in Chrome on the Android flagship (120 Hz) and on desktop Chrome (the owner's display); a Chrome Performance trace must show ≥ 115 fps mean and ≤ 2 dropped frames per second. If it fails, register in §15.10: tier A renders only while the backdrop is at rest, and bar groups use the frosted tier while their backdrop scrolls or flings (a renderer-state rule applied on every device, not a device tier).

---

## STACK-19 · low · §3.5 (Implementation), §3.7: the `.on-glass` rule is invalid CSS and would conflict with the `type-*` utility

**Problem.** `"opsz" auto` is not a valid `font-variation-settings` value (each pair needs a number), so the whole declaration is dropped. If an implementer "fixes" it by deleting `auto`, the rule overrides the `type-*` utility's `font-variation-settings` and drops its `"wght"`, so every label on glass falls back to weight 400.

**Evidence.** §3.5: "`.on-glass { font-variation-settings: "ROND" var(--glass-rond), "GRAD" var(--glass-grad), "opsz" auto; }`"; §3.7: "`@utility type-<role>` … `font-variation-settings: "wght" var(--mm-type-<role>-wght), "ROND" var(--glass-rond, var(--mm-type-<role>-rond)), "GRAD" var(--glass-grad, 0)`".

**Fix.** Delete the `.on-glass` rule from §3.5. Glass surfaces only set `--glass-rond` and `--glass-grad`; the `type-*` utility already reads them, and `font-optical-sizing: auto` (set on `:root`) supplies `opsz`. Add `font-weight: var(--mm-type-<role>-wght)` to the utility so CJK fallback faces get the weight too.

## STACK-20 · low · §5 (Libraries), §5.1, §15.3 (Native): haptic library facts are wrong, and the native channel is renamed without an amendment

**Problem.** `gaimon` 1.5.0 has no intensity parameter on any impact (`light()`, `medium()`, `heavy()`, `rigid()`, `soft()`), so "named impacts with intensity" through gaimon cannot implement `rigid(i)`/`soft(i)` on iOS. §5.1 plays Android one-shots as "a gaimon waveform" while §15.3 puts "the one-shot amplitude pulse of §5.1" on `mm/platform`. The stack names the channel `mm/haptics`; Glass renames it `mm/platform` with no §15.10 row, and `skins/skin_haptics.dart` is shared.

**Evidence.** DESIGN §5: "iOS through `gaimon` 1.5.0 (named impacts with intensity, and AHAP patterns via `Gaimon.patternFromData(json)`)"; §15.3: "one `mm/platform` method channel … `haptics.*` (iOS `AppDelegate.swift`: impact styles with intensity …)". `gaimon` 1.5.0 `lib/gaimon.dart`: `static void rigid() => _channel.invokeMethod('rigid');`, `static void soft() => …`, `static void patternFromWaveForm(List<int> timings, List<int> amplitudes, bool repeat)`. `stack-decision.md` §2.3: "`skin_haptics.dart` HapticEvent → haptic_feedback 0.6.5 / gaimon 1.5.0 AHAP / mm/haptics channel".

**Fix.** §5: iOS impacts with intensity go through `mm/platform` `haptics.impact {style: soft|light|medium|heavy|rigid, intensity}` (`UIImpactFeedbackGenerator(style:).impactOccurred(intensity:)`); gaimon is used only for `ahap:*` (`Gaimon.patternFromData(jsonString)`, iOS) and for Android one-shots (`Gaimon.patternFromWaveForm([0, 12], [0, round(i × 255)], false)`); remove the one-shot pulse from the `mm/platform` list. Add §15.10 row G16: "stack §2.3 `mm/haptics` → `mm/platform` (carries haptics, a11y, audio and gesture-exclusion methods)", and tell Cinematic.

## STACK-21 · low · §5.3, §15.1, §15.10 G2, §2.8, §15.2, §15.3: generator ownership and output paths contradict each other

**Problem.** Three statements disagree on who writes the AHAP files and the motion-name unions, and two disagree on who checks Tailwind utility names; the generated motion-name files have no path.

**Evidence.** §5.3: "generated by `design/build.mjs` from `design/tokens/glass.json`"; §15.1: "written by a separate `design/build-haptics.mjs` that `build.mjs --check` calls"; G2: "The AHAP JSON is written by `design/build-haptics.mjs` and the motion-name unions by the same small script". §2.8: "checked by `build.mjs --check`, which greps `src/skins/glass/**`"; §15.1: "the Tailwind utility-name check is Cinematic's `design/lint-utilities.mjs` … not a second grep inside `build.mjs`". §15.1 names `motion.generated.ts` and `motion_names.g.dart`, which appear in neither the §15.2 nor the §15.3 tree.

**Fix.** One statement in §15.1, repeated by §5.3, §2.8 and G2: `design/build.mjs` writes tokens (CSS, TS, Dart) and calls `design/build-haptics.mjs` (AHAP files to `mobile/assets/haptics/glass/*.ahap.json`) and `design/build-motion-names.mjs` (`frontend/src/skins/glass/motion.generated.ts`, `mobile/lib/skins/glass/motion_names.g.dart`); `design/lint-utilities.mjs` does the utility check; `design/check-contrast.mjs` the contrast gate. Add both generated files to the §15.2 and §15.3 trees.

## STACK-22 · low · §15.11, §15.2, §2.7: dependency ledger inaccuracies

**Problem.** Several rows do not match the sources or the rest of the file.

**Evidence and fix, row by row.**
- `fantasticon`: "pinned in the lockfile". There is no lockfile for it: Cinematic runs it with `npx` from `brand/` scripts and pins 4.1.0 (`engines: node >= 22.0`, verified on npm). fantasticon emits a font and a codepoint JSON, never Dart. Fix: "`fantasticon` 4.1.0 (npx, Node ≥ 22), reused; `brand/glass/glyphs.mjs` writes `mobile/lib/skins/glass/icons/glass_glyphs.g.dart` (`static const IconData … = IconData(0x…, fontFamily: 'GlassGlyphs')`) from its JSON".
- `@resvg/resvg-js` 2.6.2 and `sox` 14.4.2 are marked *added here*, but `cinematic/DESIGN.md` §15.11 already adds both. Fix: status *reused*. For `sox`, say whether WAVs are committed (Cinematic: "authoring only; outputs committed") so the iOS CI runner never needs `sox`.
- `@use-gesture/react` 10.3.1: "reader pinch only" (§15.2) and "Reader pinch on the web" (§15.11), but the image viewer (§7.31, pinch 1× to 4×) and the guided-view overview (§9.4.3, pinch out) also pinch on the web. Fix: "reader, image viewer and guided-view pinch".
- `@base-ui/react` is listed for "Toast primitives" while `sonner` is "the queue behind the Glass toast". Fix: toasts use `sonner` `toast.custom` only; drop Toast from the Base UI list.

## STACK-23 · low · §8.0.4, §15.2 (Routes): the shared-cover view-transition name is not a valid CSS identifier and is not Cinematic's name

**Problem.** Series keys are opaque strings that may contain `/` and `%`, which are invalid in `view-transition-name`, so the poster zoom silently does not morph for those series. Glass says it uses "the same name Cinematic uses", but Cinematic hashes the key.

**Evidence.** DESIGN §15.2: "`name="cover-{sourceId}-{seriesKey}"` pairs for the poster zoom (the same name Cinematic uses)". `capabilities.md` §1: "Keys are opaque strings that may contain `/` and `%`". `cinematic/DESIGN.md` §8.0.4: "`<ViewTransition name={coverTransitionName(sourceId, seriesKey)}>`, where the name is `cover-` + the 8-hex-digit 32-bit FNV-1a of `sourceId + "\u0000" + seriesKey`".

**Fix.** Use `coverTransitionName(sourceId, seriesKey)` in §8.0.4 and §15.2, and place the helper in the shared data layer (`frontend/src/features/series/transition-name.ts`) so both skins import it without crossing the skin boundary.

## STACK-24 · low · §15.5, §15.6: cross-skin backend field names and shapes

**Problem and evidence.**
- §15.5: "`tag_ids` on `FollowedSeries` list rows (both Cinematic's)". Cinematic §15.5: "`tags` on `FollowedSeries` list rows; `GET /library/series` gains `tag_ids=`". The row field is `tags`, the query parameter is `tag_ids`.
- §15.6 Activity row: "`DELETE /circle/activity` … | not listed". Cinematic already defines it (§9.3.6 and §15.5: "`DELETE /circle/activity` → 204").
- §15.5 adds `busiest_day {date, chapters, series: [...]}`, `firsts_lasts {first: {series, read_at}, …}` and `streak` on `GET /circle/members` without element shapes.

**Fix.** Rename to `tags` on rows (`[{id, name, category, color}]`, the row shape of `GET /library/tags`, capabilities §12) and `tag_ids=` on the query. Mark `DELETE /circle/activity` as Cinematic's. Define the shapes: `busiest_day: {date: "YYYY-MM-DD", chapters: int, series: [{source_id, series_key, title, cover_url}] (≤ 5, non-mature only)}`; `firsts_lasts: {first: {series: {source_id, series_key, title, cover_url}, read_at}, last: {…same}} | null` (non-mature only, as `shareable` requires); `GET /circle/members[].streak: {current_days: int} | null` (present only when that member's `share_streak` is on).

## STACK-25 · low · §12.2 (iOS 26 Icon Composer), §12.6: the `.icon` bundle needs Xcode 26, which CI does not pin

**Problem.** An Icon Composer `.icon` bundle is compiled only by Xcode 26's `actool`, and the alternate "GlassIcon" needs asset-catalog alternate-icon settings. `ios-build.yml` runs on `macos-latest` and `codemagic.yaml` uses `xcode: latest`, so whether the bundle compiles depends on the runner image of the day.

**Evidence.** DESIGN §12.2: "an `.icon` bundle … Compiled on the CI runner with `actool`"; §12.6: "the Icon Composer `.icon` bundle lives in `mobile/ios/Runner/AppIcon-Glass.icon/`". `.github/workflows/ios-build.yml` line 33: `runs-on: macos-latest`; `codemagic.yaml` line 25: `xcode: latest`.

**Fix.** Pin Xcode 26.x in `ios-build.yml` (`sudo xcode-select -s /Applications/Xcode_26.0.app` or `maxim-lobanov/setup-xcode` with `xcode-version: '26.0'`) and in `codemagic.yaml`; set `ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES` and `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES = GlassIcon CinematicIcon` in `Runner.xcodeproj`; keep the PNG set as the fallback when the job runs on an older image. Put this in the native-plugin commit's CI dry run.

## STACK-26 · low · §15.3 (Native): `LiquidGlassWidgets.initialize()` only "before `runApp`" is skipped after an in-process switch into Glass

**Problem.** A process that booted in Cinematic and switches to Glass restarts through `AppRestart` (stack §2.5 mobile step 4), which does not rerun `main()`, so the shaders are never prewarmed and the first Glass frames compile them (the "white flash" the library warns about) inside the 1.5 s restart budget.

**Evidence.** DESIGN §15.3: "`LiquidGlassWidgets.initialize()` before `runApp` to precompile shaders". `stack-decision.md` §2.3: `main.dart … runApp(AppRestart(child: ProviderScope(…)))`; §2.5 step 4: "`AppRestart.of(context).restart()` swaps the `UniqueKey`". `liquid_glass_setup.dart`: "Call once in `main()` before [runApp]".

**Fix.** Call `await LiquidGlassWidgets.initialize()` unconditionally in `main()` for both skins (it only prewarms shaders), or in the Glass skin's boot path, awaited before the Glass splash's first frame on every `AppRestart` into Glass. State which in §15.3.

## STACK-27 · low · §9.4.2 (Rain on glass), §15.3 (`shaders/rain_on_glass.frag`): the Flutter rain shader has no backdrop input, so it cannot refract the page

**Problem.** The shader's inputs are "time, droplet positions, the capsule size"; a `FragmentProgram` drawn on a layer cannot read what is behind it. Refracting the page needs a backdrop sampler through `BackdropFilter(filter: ImageFilter.shader(…))`, which is Impeller-only and adds a backdrop pass to the budget.

**Evidence.** DESIGN §9.4.2: "Flutter: a fragment shader `shaders/rain_on_glass.frag` on the capsules' glass layer only (inputs: time, droplet positions, the capsule size)"; "refracting the page behind them".

**Fix.** Specify `uniform sampler2D uBackdrop` plus `uSize`, `uTime`, `uDrops[10]` (x, y, r), run through `BackdropFilter(filter: ImageFilter.shader(rainShader))` clipped to each capsule, guarded by `ImageFilter.isShaderFilterSupported` (true on the owner's Impeller devices), and count it as one extra glass layer in the §15.7 budget while the Rain scene plays.

## STACK-28 · low · §8.15.4 (Lift, web): the web paged novel cannot rotate one page of a CSS multi-column container

**Problem.** Paged mode on the web is one CSS multi-column container translated by page. "Lift" rotates only the turning page around its spine with CSS 3D and "no bitmap capture", but a single column of a multi-column box is not an element and cannot be transformed on its own. The mechanism is left to the implementer.

**Evidence.** DESIGN §8.15.4: "CSS multi-column pagination on web (`column-width` = viewport, `column-gap` 0, the foliate-js approach)"; "**Lift** … `rotateY` 0 → −100° … pure transforms on both clients: CSS 3D … No bitmap capture".

**Fix.** Specify two clipped copies of the chapter's column container during a turn: the turning copy, translated to page n and clipped to one page (`overflow: hidden` wrapper with `transform-style: preserve-3d; backface-visibility: hidden`), rotates; the static copy beneath shows page n+1. The second copy is mounted on pointer-down and removed on settle, so text selection and search stay on the single live container.
