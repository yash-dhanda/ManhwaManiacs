# Cinematic DESIGN.md: verdicts on the stack-feasibility audit (`find-stack.md`)

Judged 2026-09-28. For each of the 39 findings I tried to refute the claim. I grepped `cinematic/DESIGN.md` (4,101 lines) for any place that already settles it, read the cited lines, and checked the fix against `inventory/00-decisions.md`, `stack-decision.md` and the rest of DESIGN.md. I also re-checked the external evidence myself:

- pub.dev metadata for `share_plus`, `flutter_soloud`, `native_toolchain_c`, `package_info_plus`, `file_picker`, `flutter_secure_storage_windows` and `smooth_sheets`;
- the published sources of `flutter_soloud` 4.1.7, `share_plus` 12.0.2, `smooth_sheets` 1.2.0, `audio_service` 0.18.19, `swipeable_page_route` 0.4.8, `flutter_dynamic_icon_plus` 1.4.1 and `sonner` 2.0.8;
- the Flutter 3.44.6 SDK (`meta` pinned to 1.18.0, `spring_simulation.dart`, `bottom_sheet.dart`, `draggable_scrollable_sheet.dart`, `heroes.dart`);
- `frontend/node_modules` (next 16.2.9 font validation, `viewTransition` docs, `prepare-destination.js` `matchHas`; motion-dom 12.42.2 `spring()`, `getSpringOptions` and `generateLinearEasing`);
- the checkout: `frontend/next.config.ts`, `docker-compose.yml`, `mobile/pubspec.yaml`, `MainActivity.kt`, `novel_audio_session.dart`, `main.dart`, `backend/routes/{app_distribution,novels}.py`, `backend/services/image_resize.py`, `ops/vps/push.sh`, `.github/workflows/*`.

The five other judges (`judge-web.md`, `judge-product.md`, `judge-consistency.md`, `judge-mobile.md`, `judge-a11y.md`) had already confirmed fixes that cover some of these findings. A finding that another judge's confirmed fix already covers in full is refuted as a duplicate, so the main session does not apply two different fixes for one defect. Where another fix covers only part of a finding, I confirm the rest and say which part I dropped.

**Result: 31 confirmed, 8 refuted.** Of the confirmed findings, 12 have a rewritten or narrowed fix. One confirmed fix (STACK-19) conflicts with a fix another judge confirmed (PRODUCT-4). Only one of the two can be applied, and the entry explains which one to keep and why.

---

## Verdicts

| ID | Verdict | Severity | Reason |
|---|---|---|---|
| STACK-1 | Confirmed | high | `share_plus` 13.0.0 and later need `win32 ^6.0.x`. `package_info_plus` 8.x and 9.x need `win32 ^5.5.3`, `file_picker` 8.3.7 needs `^5.9.0` and `flutter_secure_storage_windows` 3.1.2 needs `^5.0.0`. The lockfile has `win32` 5.15.0. So 13.3.0 cannot resolve. 12.0.2 (2026-03-30) needs `win32 ^5.5.3` and `flutter >=3.22.0`, ships a podspec, and has `SharePlus.instance.share(ShareParams)`. DESIGN names 13.3.0 at l.1509, l.3056, l.3825 and l.3943. |
| STACK-2 | Confirmed | high | Every `flutter_soloud` 5.x release depends on `native_toolchain_c ^0.19.4`, which needs `meta ^1.19.0`. Flutter 3.44.6 pins `meta: 1.18.0`. So 5.1.4 cannot resolve. 4.1.7 (2026-08-08) needs `meta ^1.15.0` and no build hooks, ships `ios/flutter_soloud.podspec`, and has `AudioData`, `updateSamples()`, `getAudioData()`, `setVisualizationEnabled` and `loadMem`. The voice pack is Ogg Opus (`novels.py` l.531). 4.1.7 loads Ogg Opus through its buffer-stream fallback (CHANGELOG #479), but it has no AAC decoder. So the "always request `ogg`" rule is correct. |
| STACK-3 | Confirmed | high | `validate-google-font-function-call.js` defaults `preload` to `true` and calls `nextFontError` when `subsets` is missing. l.544 (§3.1) and l.3783 (§15.2) both omit `subsets` for Archivo, Newsreader and IBM Plex Mono. l.544 omits it for Bodoni Moda too. `font-data.json` lists `latin` and `latin-ext` for all four. The three reading faces and the Noto fallbacks are `preload: false`, so they are fine. |
| STACK-4 | Confirmed, fix rewritten | high | l.2699 sends the `PATCH` at t = 0 and l.2703 restarts at t = 500. Nothing awaits the `PATCH`, and "keepalive" and "outbox" never appear in §8.30.3. `location.replace` aborts a fetch still in flight. On mobile, l.2654 allows the switch offline through the outbox. Either way, boot resolution (stack §2.4 step 4) can see the old `skin` and restart back. The auditor's `keepalive` plus cancel-on-timeout can leave the server on the new skin while the user stays on the old one. The rewrite awaits the response and writes the mirror only after it succeeds. |
| STACK-5 | Confirmed | medium | motion-dom `getSpringOptions` (l.896): ω = 2π / (1.2 · visualDuration). Flutter `withDurationAndBounce` (l.77): stiffness = 4π² / d², so ω = 2π / d. The same `{ms, bounce}` is therefore 1.2× stiffer on Flutter. The damping ratio matches for 0 ≤ bounce < 0.95. l.528–530 map `ms` straight through. |
| STACK-6 | Confirmed, fix tightened | medium | `spring(0.42, 0).toString()` returns `"800ms linear(0, 0.0572, …)"`, with the duration embedded (motion-dom l.1070–1074). l.528 pairs the curve with `--mm-spring-release-ms: 420ms`, so the CSS spring runs about 1.9× fast. Stack §2.1 makes `build.mjs` "Node 22 stdlib only", so it cannot import `motion`. Two corrections to the auditor's fix: Motion samples at a 30 ms resolution (27 points for 800 ms), so "at least 30 points" would break the equality test it also asks for. And the Docker-context point is irrelevant, because the generated files are committed (stack §2.1 `--check`). |
| STACK-7 | Confirmed, fix decided | medium | `bottom_sheet.dart` l.30–31 fixes `_kMinFlingVelocity = 700` and `_kCloseProgressThreshold = 0.5`, both private. `_SnappingSimulation` (l.1128) moves at a constant velocity, and the sheet clamps at `maxChildSize`. §7.9 asks for a `spring.sheet` release, a 30 % / 800 px/s dismissal and a c = 0.35 rubber band. The auditor offered two options. `smooth_sheets` 1.2.0 also misses the spec: `BouncingSheetPhysics.spring` is a fixed getter, overdrag uses its own exponential friction, and fling dismissal is a ratio of the viewport height. So the custom route wins. It is built on `PageRoute`, which also makes STACK-28's Quick look `Hero` work. |
| STACK-8 | Confirmed, fix aligned | medium | `next.config.ts` redirects `/` to `/library` with a 307. There is no `src/app/page.tsx`. DESIGN never mentions the redirect. WEB-29 (judge-web) already gates the redirect on the `mm-skin` cookie, but before the flip Cinematic is reached through `mm-skin-debug` (§8.0.7, l.1544), so under WEB-29 Tonight stays unreachable. `matchHas` (prepare-destination.js) skips the redirect when any `missing` item matches, and it anchors `value` as a regex. |
| STACK-9 | Confirmed, narrowed | medium | Part 1 (the `experimental.viewTransition` flag) is WEB-29's fix. Part 3 (invalid `view-transition-name`, FNV-1a hash) is PRODUCT-15's fix. Part 2 is still open: `transitionTypes` is a `LinkProps` field (`link.d.ts` l.102) and a `router.push` option (`app-router-context` l.14), but l.1499 and l.3802 put it on `<ViewTransition>`. The vendored React 19.3 canary exports `ViewTransition`. |
| STACK-10 | **Refuted (duplicate)** | — | The defect is real, but CONSISTENCY-13 and MOBILE-4 both confirm fixes for it, including removing the startup `configureNovelAudioSession()`. MOBILE-4 also covers Android focus. See Refuted. |
| STACK-11 | Confirmed | medium | `MainActivity.kt` l.33 is `class MainActivity : FlutterActivity()`. The `audio_service` README needs `AudioServiceActivity` (or its engine hooks), the `AudioService` `<service>`, `MediaButtonReceiver` and the two foreground-service permissions. `AudioService.init` asserts `_cacheManager == null` (l.1007), so it can run only once per engine, and the stack's restart (§2.5 step 4) disposes every provider in the same engine. DESIGN never mentions `MainActivity` or `AudioService.init`. |
| STACK-12 | Confirmed | medium | Stack §2.3 builds `AppRestart(child: ProviderScope(overrides: [skinIdProvider.overrideWithValue(id)], …))` once in `main`. Swapping a `UniqueKey` rebuilds that same child, so the override keeps the old id, and nothing feeds the return route into `initialLocation`. Stack §2.5 step 5 ("`main`'s logic runs again") is not what a key swap does. "initialLocation" appears 0 times in DESIGN. MOBILE-16 only fixes the API name. |
| STACK-13 | Confirmed, narrowed | low (was medium) | The different inputs are covered by CONSISTENCY-12 (16 × 16 on both clients), and the two sampling rules by CONSISTENCY-46. Once the inputs are equal, the shared-cache point goes away too. What is left: `createImageBitmap(img)` copies the whole decoded page. `image_resize.py` l.354–369 records real 720 × 14,668 strips (about 42 MB of bitmap), and the engine makes that copy on each sample, up to every 600 ms. |
| STACK-14 | Confirmed, fix rewritten | medium | l.728 racks "every cover and page image except inside the reader strip" with a 14 px blur, while §15.6 (l.3864) allows "at most one animated blur layer per screen outside letter reveals". A wall that decodes 24–48 covers at once breaks the rule. The auditor removed the blur from every poster. That trims an effect the owner asked to keep at maximum (`00-decisions.md` Performance), so the rewrite keeps Rack focus and caps how many rack at once. |
| STACK-15 | Confirmed, narrowed | low (was medium) | The routes are PRODUCT-11's fix (`/app/soundscapes/{id}.{ext}`, `/app/fonts/{file}.woff2`). Still open: no rule says which format the web requests for soundscapes. The auditor's rule tested `vorbis` for all three audio kinds, but narration and voice samples are Ogg **Opus**, and the web already picks their format in `frontend/src/features/novels/audio-url.ts` (`pickNovelAudioFormat`, Ogg Opus probe). |
| STACK-16 | Confirmed, narrowed | medium | PRODUCT-3 covers `DELETE /circle/activity`, the `DELETE` body, shared collections in the list, `can_add` adds and `Leave shelf`. Still open: §9.3.8 (l.3146) gives no response shape for `GET /circle/members`, `/circle/feed`, `/circle/reactions` or `/circle/letters`. No endpoint returns the sharing switches the Settings rows display (§9.3.6). And "Remove: only series they added" (§8.11 permission table) and the adder avatar (§9.3.5) need an adder id on member rows. |
| STACK-17 | Confirmed, narrowed | low (was medium) | PRODUCT-1 covers `fetch` instead of `EventSource`, the `meta`/`delta`/`done`/`error` framing and dio streaming. Still open: the answer when no recap can be written (availability can change between PRODUCT-1's check and the stream), and the stream headers. `Cache-Control: no-transform` is what stops the `compression` middleware in Next's server from buffering the proxied stream. |
| STACK-18 | Confirmed, narrowed | medium | The time zone is PRODUCT-10's fix. Still open: l.2932 lists 14 section `type`s but no `items` shape for any of them. `GET /ai/similar` (l.2933) returns "World items with `why`", with no `available`, `reason` or `generated_at`, yet §9.1.8's unavailable and stale states need all three. PRODUCT-2 adds an `anilist_id` variant but no envelope. |
| STACK-19 | Confirmed (conflicts with PRODUCT-4) | medium | l.3175 runs Pillow panel detection "in the background" on the server, with no trigger, no bound and no not-ready response, and `panels_ready` gives the client nothing to poll. Meanwhile l.147, l.3838 and l.3867 argue that the VPS must not analyse pages. PRODUCT-4 resolves this by moving detection to the client (sign-off S11). This fix keeps it on the server and bounds it. Apply one or the other; see the Confirmed entry. |
| STACK-20 | Confirmed, narrowed | low (was medium) | Calendar year and time zone are covered by PRODUCT-24 and PRODUCT-10, and the voices by PRODUCT-18. Still open: §9.2.7 (l.3067) describes the response in prose, with no field names, although both clients must render identical figures from it. |
| STACK-21 | **Refuted (duplicate)** | — | PRODUCT-2 confirms `GET /onboarding/catalog` (seeds by format and genre, gated) and `GET /ai/similar?anilist_id`. See Refuted. |
| STACK-22 | Confirmed | medium | §8.11 (l.1904, l.1908, l.1911) has rule chips, a `SMART` badge and `SMART RULES` credits. Collections store only `name`, `description` and `sort_order` (capabilities §11), and §15.5 adds no rules field. So rules exist only on the device that made them, and the same shelf is empty and manual on every other device. No other judge covers this. |
| STACK-23 | Confirmed | medium | `app/skin-preview/[skin]/page.tsx` (l.2687, l.3798) sits under the root layout, which stamps `<html data-skin>` from the cookie and mounts that skin's Shell. The fixture's path into the shared hooks is unspecified. And `docker-compose.yml` builds with `context: ./frontend`, so `design/previews/*` is outside the image. The frontend already uses `@tanstack/react-query` 5, so hydration can seed the cache. |
| STACK-24 | Confirmed, fix trimmed | medium | §2.1.5 (l.119, l.141) promises `ambient` "on every series payload", "once per cover URL". It never says what a list or search payload carries before that cover was ever resized, and AniList covers (capabilities §9, absolute CDN URLs) pass through no proxy at all. No other judge covers this. The auditor's background job for followed series is dropped: their covers are proxied the first time any list shows them, and that computes the value. |
| STACK-25 | Confirmed | low | SVG filter primitives default to `color-interpolation-filters: linearRGB`. So the web matrix (l.137) runs on linearised values, while Flutter `ColorFilter.matrix` and the Canvas 2D share card work in sRGB. "color-interpolation-filters" appears 0 times in DESIGN. |
| STACK-26 | Confirmed, fix rewritten | low | l.163 and l.406 write the registered properties with `inherits: true` on "the nearest provider element", and l.3867 calls the transitions "compositor-friendly". That is wrong: custom-property transitions run on the main thread and restyle every descendant. The auditor's `inherits: false` needs every painting element listed. Scoping where the value is written is smaller. |
| STACK-27 | **Refuted** | — | Speculative. `background-position` is not composited, but the grain is limited to the one visible hero and paused off screen (§15.6, l.3863). A 12 fps repaint of a tiled 256 px PNG breaks no budget in the contract, and nothing shows a dropped frame. |
| STACK-28 | Confirmed, fix decided | low | `swipeable_page_route` 0.4.8 `dragEnd` (page_route.dart l.541–596) releases with a hard-coded `Curves.fastLinearToSlowEaseIn`, so "release `spring.release`" (l.1505, and repeated in MOBILE-1's fix) cannot be built without a fork. `heroes.dart` l.917–918 ends a flight unless both routes are `PageRoute`s, and `ModalBottomSheetRoute` is a `PopupRoute` (l.870), so Quick look's match cut (l.1332) cannot fly. The rewrite accepts the package curve instead of forking it, and reuses STACK-7's route. |
| STACK-29 | **Refuted (duplicate)** | — | The same defect and the same `GradientTransform` fix are CONSISTENCY-45. |
| STACK-30 | **Refuted (duplicate)** | — | The same defect and the same fix are CONSISTENCY-8 and PRODUCT-12 ("One count"). |
| STACK-31 | **Refuted (duplicate)** | — | CONSISTENCY-15 items 2 and 3 already define the lint scope and add `--animate-caret-out` to `@theme`. |
| STACK-32 | Confirmed | low | §15.10's own rule (l.3902) is that every departure from the stack is recorded there. Three departures are not. `theme.generated.css` (l.321, l.3782) is missing from stack §2.1's output table. Per-skin `CineTokens extends ThemeExtension` (l.323, l.3810) replaces the stack's shared `SkinTokens`. And the preview frames sit at `mobile/assets/skin_previews/` in l.2688 but under the `mobile/lib/skins/cinematic/` table in l.3821. |
| STACK-33 | Confirmed | low | `fantasticon` has "build time" as its version (l.3951). `resvg` (l.3585) and `sox` (l.3167) are missing from the ledger. The gate (l.3924) runs `pub get`, `analyze` and the iOS dry run, but no Android build, although `flutter_soloud` compiles C++ with the NDK and `audio_service` and `flutter_dynamic_icon_plus` edit the manifest. Today APKs are built only by `ops/vps/push.sh` at release time, and no workflow in `.github/workflows/` builds one. npm has `fantasticon` 4.1.0 (`node >= 22.0`) and `@resvg/resvg-js` 2.6.2. |
| STACK-34 | **Refuted (duplicate)** | — | The same defect is MOBILE-16, whose fix also uses the package's deferred swap and rewrites the confirm line. |
| STACK-35 | Confirmed, fix trimmed | low | A service worker has no `document.cookie`, and `Cookie` is a forbidden header, so it cannot read `mm-skin` from a navigation request. l.2759 and l.3804 choose the fallback "by the `mm-skin` cookie". No other judge covers this. The auditor's `cookieStore` branch is dropped: the boot message already reaches the worker on every page load, so a second source adds nothing. |
| STACK-36 | Confirmed | low | l.1617 makes "any web navigation after the first in a session" a warm start. The restart's `location.replace` is such a navigation, so it gets the 200 ms fade, while l.3573 says the skin-switch restart plays the full reveal. The stack keys the splash on `sessionStorage['mm.skin.splash']` (§2.5 web step 6), which appears 0 times in DESIGN. |
| STACK-37 | Confirmed, fix extended | low | Sonner 2.0.8 orders toasts by creation time and has no pinned slot, so the banner cannot "keep its bottom slot" as a stack member (l.1149). `ToasterProps` has `offset`, `mobileOffset` and `visibleToasts`, and `Offset` is `{top, right, bottom, left} \| string \| number`. Phones use `mobileOffset`, which the auditor left out. |
| STACK-38 | **Refuted (duplicate)** | — | MOBILE-5's fix already says "Declare every static `/library/...` path before `/library/:followedId`". |
| STACK-39 | Confirmed, narrowed | low | The gaps stand: repoint has no `keep_old` field for the "Keep following it on MangaDex too" checkbox (l.2398) and no response (l.2399). `POST /ai/feedback` (l.2935) does not say which tag `tag_rejected` (l.2389) rejects. `page-tints` and `milestones/{days}/seen` have no responses. The collection preview field has no name (l.3848). The taste `seeds` and `styles` values are unspecified. Dropped: `genres {name: 1\|2\|-1}` and `formats[]` are already in the §8.7 table (l.1737–1738). |

---

## Confirmed

Final fixes, ready to apply to `cinematic/DESIGN.md`. Backend additions also go into §15.5. None touches `backend/connectors/`, and all of them gate 18+ on serve and scope by profile.

### STACK-1 · high · `share_plus` 12.0.2 (§8.0.5, §9.2.5, §15.3, §15.11)

- Replace `share_plus` 13.3.0 with **12.0.2** in l.1509 (§8.0.5 Share row), l.3056 (§9.2.5 export pipeline), l.3825 (§15.3 packages) and l.3943 (§15.11 ledger). The call stays as written: `SharePlus.instance.share(ShareParams(files: [XFile.fromData(bytes, mimeType: 'image/png', name: 'manhwamaniacs-{template}-{format}.png')]))`.
- Add to the §15.11 row: "13.x needs `win32 ^6`. `package_info_plus` 8.x, `file_picker` 8.x and `flutter_secure_storage` 9.x pin `win32 ^5`, so move to 13.x only together with their win32-6 majors."
- The same version change applies wherever other judges' fixes cite `share_plus` 13.3.0 (PRODUCT-26, PRODUCT-17).

### STACK-2 · high · `flutter_soloud` 4.1.7 and Ogg voice samples (§6, §8.16.5, §15.3, §15.11)

- Replace `flutter_soloud` 5.1.4 with **4.1.7** in l.914 (§6), l.2338 (§8.16.5), l.3825 (§15.3) and l.3941 (§15.11), and in MOBILE-4's and CONSISTENCY-13's fixes. The §8.16.5 API stays as written: `setVisualizationEnabled(true)`, `AudioData(GetSamplesKind.wave)` with `updateSamples()` and `getAudioData()`, and `loadMem`. 4.1.7's miniaudio context also sets `ma_ios_session_category_none`, so MOBILE-4's session analysis still holds.
- Add to §8.16.5: "The app always requests `GET /novels/voices/sample?voice={id}&format=ogg`, on iOS too. The pack is Ogg Opus, which SoLoud 4.1.7 decodes itself; it has no AAC decoder, so an `m4a` sample would not play."
- Add to the §15.11 row: "5.x needs `native_toolchain_c ^0.19.4`, which needs `meta ^1.19.0`, and Flutter 3.44.6 pins `meta` 1.18.0. 5.0 also removed `AudioData`. Revisit with the Flutter upgrade (stack risk 10)."

### STACK-3 · high · `next/font` subsets (§3.1, §15.2)

In both l.544 and l.3783, the four calls read, identically:

```ts
Bodoni_Moda({ subsets: ["latin", "latin-ext"], axes: ["opsz"], style: ["normal", "italic"], display: "block", preload: true, variable: "--mm-font-display" })
Archivo({ subsets: ["latin", "latin-ext"], axes: ["wdth"], display: "swap", variable: "--mm-font-grotesk" })
Newsreader({ subsets: ["latin", "latin-ext"], axes: ["opsz"], style: ["normal", "italic"], display: "swap", variable: "--mm-font-text" })
IBM_Plex_Mono({ subsets: ["latin", "latin-ext"], weight: ["400", "500", "600"], display: "swap", variable: "--mm-font-folio" })
```

The reading faces (§3.4) and the Noto fallbacks keep `preload: false` and need no subsets.

### STACK-4 · high · The switch waits for the profile `PATCH` (§8.30.3, §15.10)

Replace the t = 0 and t = 500 rows of the §8.30.3 outgoing table and add a paragraph under it:

- **t = 0:** the profile `PATCH /profiles/{id} {skin}` is sent (an ordinary `fetch` on the web; the outbox on mobile) and `mm.skin.t0` is written. The mirror and the return route are **not** written yet.
- **t = 500, web:** await the `PATCH`, for at most 1,000 ms more (an `AbortController` timeout). While it waits, the black frame with the masthead holds.
  - On a 2xx: write the `mm-skin` cookie and `sessionStorage['mm.skin.return']`, post `skin-changed` to the service worker, then call `location.replace(returnPath)`.
  - On an error or a timeout: abort the request, reverse the blades (200 ms `ease.set`), rack back into focus, and show the error toast "Couldn't switch editions. Try again." The mirror is left unchanged. The `SKIN RESTART` entry is not logged.
  - The web Edition row stays disabled offline, like the other server-backed rows (§8.30.1).
- **t = 500, mobile:** write `mm.skin.active` and `mm.skin.return`, then restart. The `PATCH` stays in the outbox.
- **Boot resolution, mobile (stack §2.4 step 2):** a queued outbox `PATCH /profiles/{id}` that carries `skin` wins over the server's `profile.skin`. While such an entry is queued, the mismatch restart is skipped. When the connection returns, the outbox flushes before the next comparison.
- Record both rules as a §15.10 row, "S12 · stack §2.4, §2.5 · the skin `PATCH` is awaited on the web and wins from the outbox on mobile · amendment". Also add them to §8.30.1's offline caption.

### STACK-5 · medium · Spring tokens mean the same on both clients (§2.8.4, §15.1, §15.10)

- **Mapping.** The generator maps a spring token `{ms, bounce}` to:
  - Motion: `{ type: "spring", visualDuration: ms / 1000, bounce }`, unchanged;
  - Flutter: `SpringDescription.withDurationAndBounce(duration: Duration(milliseconds: (ms * 1.2).round()), bounce: bounce)`.
- **Why.** Motion computes stiffness from ω = 2π / (1.2 · visualDuration), while Flutter uses ω = 2π / duration. With the ×1.2, stiffness matches exactly, and damping matches for 0 ≤ bounce < 0.95.
- **Resulting Flutter durations:** `springRelease` 504 ms, `springSheet` 576 ms, `springScrub` 288 ms. Update the three Flutter cells in §2.8.4 and state the rule in §15.1.
- **§15.10 row** "S13 · stack §2.1 motion-token mapping · Flutter springs use `ms × 1.2` so they match Motion's `visualDuration` · amendment; generator change only".

### STACK-6 · medium · CSS springs: settle-time duration, stdlib generator (§2.8.4, §15.1)

- **Generator.** `design/build.mjs` ports Motion's spring generator using Node stdlib only, about 30 lines:
  - stiffness k = (2π / (1.2 · ms / 1000))², damping ratio ζ = clamp(0.05, 1, 1 − bounce), mass 1;
  - the critically damped branch x(t) = 1 − (1 + ωt)·e^(−ωt), plus the underdamped branch Glass needs;
  - step t in 50 ms increments until |1 − x| ≤ 0.005 and |v| ≤ 0.01, computed as motion-dom computes them (its "granular" rest thresholds). That gives the settle time T;
  - emit `linear()` with round(T / 30) samples of x(i · T / (n − 1)), each rounded to 4 decimals. This is Motion's `generateLinearEasing` at its 30 ms `toString` resolution.
- **Tokens.** `--mm-spring-{release,sheet,scrub}` is that `linear(…)`, and `--mm-spring-*-ms` is **T**, not the visual duration: 800 ms, 850 ms and 500 ms for today's tokens. State in §2.8.4 that the CSS pair is "curve + settle time". Motion JS and Flutter keep `visualDuration` (STACK-5).
- **Test.** A Vitest case in `frontend/src/skins/cinematic/tokens.test.ts` asserts that for each spring token, `` `${T}ms ${curve}` `` equals `spring(ms / 1000, bounce).toString()` from the installed `motion`. Today that is `"800ms linear(0, 0.0572, 0.1795, …)"` for release. A Motion upgrade that changes the curve then fails CI instead of drifting silently.

### STACK-7 · medium · `CineSheet` on its own route (§7.9, §15.3)

- **§15.3 `primitives/` cell.** Replace "`CineSheet` over `showModalBottomSheet` + `DraggableScrollableSheet(snap: true, snapSizes: [0.5, 0.92])`" with "`CineSheet`, pushed as `CineSheetRoute<T> extends PageRoute<T>` (`opaque: false`, `barrierColor: scrimModal`, `barrierDismissible: true`) in `primitives/sheet_route.dart`".
- **Route behaviour:**
  - one `AnimationController` in pixels of sheet offset, driven by a `VerticalDragGestureRecognizer` on the grabber and header, and by the body's scroll overscroll at the top;
  - detents: content height (capped at 0.92 of the screen), or `[0.5, 0.92]` for live-preview sheets;
  - open: Rise (§7.9, 360 ms `settle`). Close: 240 ms `lift`;
  - release: `controller.animateWith(SpringSimulation(CineSprings.sheet, offset, nearestDetent, velocity))`;
  - dismiss when the sheet is below 30 % of its height, or on a downward fling faster than 800 px/s;
  - above the top detent, the offset is d · (1 − 1 / (x · 0.35 / d + 1)), with x the overdrag and d the sheet height (`scalar.rubber`);
  - Android back and iOS swipe-down close it (§7.9).
- **Packages.** No package is added: `smooth_sheets` stays Glass-only, as l.3825 says. Because the route is a `PageRoute`, `Hero` can fly into it (STACK-28).

### STACK-8 · medium · `/` reaches Tonight (§8.0.3, §15.2); supersedes the redirect bullet of WEB-29

- Add `frontend/src/app/page.tsx`, a thin route that renders `skins[await getSkin()].screens.tonight`.
- Until the Cinematic flip, keep the `/` → `/library` redirect in `next.config.ts` with:

  ```ts
  missing: [
    { type: "cookie", key: "mm-skin", value: "(cinematic|glass)" },
    { type: "cookie", key: "mm-skin-debug", value: "(cinematic|glass)" },
  ]
  ```

  Next skips the redirect when either cookie matches (`!missing.some(…)`). So `legacy`, which has no Tonight, still gets its 307, while both the pre-flip debug row (§8.0.7) and a Cinematic profile reach Tonight. The flip release deletes `redirects()`.
- Add both points to the `tonight` row of §8.0.3 and to WEB-29's §15.2 row, replacing WEB-29's single-cookie condition.

### STACK-9 · medium · Where `transitionTypes` goes (§8.0.4, §15.2)

The flag is WEB-29's fix and the match-cut name is PRODUCT-15's. Replace the §8.0.4 web paragraph (l.1499) and the §15.2 "View transitions" line (l.3802) with:

- **Links and pushes carry the type:** `<Link href={…} transitionTypes={["nav-forward"]}>`, and `router.push(href, { transitionTypes: ["nav-back"] })` for in-app back links.
- **The page wrapper maps types to classes:**

  ```tsx
  <ViewTransition
    default="none"
    enter={{ "nav-forward": "mm-page-in", "nav-back": "mm-page-back-in", default: "none" }}
    exit={{ "nav-forward": "mm-page-out", "nav-back": "mm-page-back-out", default: "none" }}>
  ```

- **Shared covers:** `<ViewTransition name={coverTransitionName(sourceId, seriesKey)} share="mm-match-cut">`, where the name is PRODUCT-15's FNV-1a name.
- **Browser back** (popstate) carries no type, so it gets `default: "none"` and the OS or browser animation is never doubled.

### STACK-11 · medium · `audio_service` native wiring and a single init (§8.16.10, §15.3, §15.10)

- **`MainActivity.kt`:** `class MainActivity : AudioServiceActivity()`, from `com.ryanheise.audioservice.AudioServiceActivity`, which extends `FlutterActivity`. The existing `configureFlutterEngine` (native channel and `OcrChannel`), `onCreate`, `onResume` and key handling stay as they are.
- **`AndroidManifest.xml`:**
  - `<service android:name="com.ryanheise.audioservice.AudioService" android:foregroundServiceType="mediaPlayback" android:exported="true">` with the `android.media.browse.MediaBrowserService` intent filter;
  - `<receiver android:name="com.ryanheise.audioservice.MediaButtonReceiver" android:exported="true">` with `android.intent.action.MEDIA_BUTTON`;
  - `<uses-permission>` for `android.permission.FOREGROUND_SERVICE` and `android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK`.
- **iOS:** already has `UIBackgroundModes: audio` (`Info.plist` l.78–81).
- **Init.** `AudioService.init(builder: () => NarrationAudioHandler(player), config: AudioServiceConfig(...§8.16.10...))` runs once in `main()`, before `runApp(AppRestart(...))`. The handler reaches the tree as `audioHandlerProvider.overrideWithValue(handler)` in the root `ProviderScope`, so a skin switch (STACK-12) never calls `init` again.
- **Commit and record.** This lands in the isolated native-plugin commit (§15.3) and gets a §15.10 row: "S14 · stack §3 'native channels kept in place' · `MainActivity` now extends `AudioServiceActivity`; the manifest gains the service, receiver and permissions · amendment". PRODUCT-17's `mm/media_store` channel goes into the same class.

### STACK-12 · medium · `AppRestart` re-reads the boot state (§8.30.3, §15.3, §15.10)

- **`app/app_restart.dart`:** `AppRestart({required Widget Function() builder})`. `restart()` swaps the `UniqueKey` **and** calls `builder()` again. The API name is `AppRestart.of(context).restart()`, as MOBILE-16 says.
- **`main.dart`** keeps its existing overrides (`apiBaseUrlProvider`, `sharedPrefsProvider`):

  ```dart
  runApp(AppRestart(builder: () {
    final boot = SkinBoot.read(prefs);
    return ProviderScope(
      overrides: [
        apiBaseUrlProvider.overrideWith((ref) => apiUrl),
        sharedPrefsProvider.overrideWithValue(prefs),
        audioHandlerProvider.overrideWithValue(handler),
        skinIdProvider.overrideWithValue(boot.skin),
        returnRouteProvider.overrideWithValue(boot.returnRoute),
      ],
      child: const SkinApp(),
    );
  }));
  ```

- **`SkinBoot.read(prefs)`** is synchronous, on the already-loaded `SharedPreferences`. The skin is `mm.skin.debug` (the pre-flip override, S5), else `mm.skin.active`, else the default. It reads `mm.skin.return` and then removes it.
- **Router.** Each skin's `buildRouter` passes `initialLocation: ref.read(returnRouteProvider) ?? Routes.tonight`.
- **Record.** A §15.10 row: "S15 · stack §2.3, §2.5 step 5 · `AppRestart` rebuilds its child from a builder, because a key swap does not re-run `main` · amendment".

### STACK-13 · low · The engine hands the worker a small bitmap (§2.1.5)

Applies on top of CONSISTENCY-12 (16 × 16 on both clients) and CONSISTENCY-46 (one sampling rule).

- **§2.1.5 web cell:** "the engine makes the bitmap with `createImageBitmap(img, { resizeWidth: 16, resizeHeight: 16, resizeQuality: "medium" })`. If the returned bitmap is not 16 × 16 (the options are unsupported), the worker downsamples it as before. Either way the worker calls `bitmap.close()` after reading."
- **Why.** A 720 × 14,668 strip page (`image_resize.py` l.354) would otherwise be copied as about 42 MB of bitmap on every sample.

### STACK-14 · medium · Rack focus stays, capped at 12 at once (§4.5, §4.8, §7.7, §15.6, §15.8)

- **§4.5 Rack focus row, "Where" column:** "every cover and page image except inside the reader strip; at most 12 images rack at once per screen".
- **New §4.5 row, Develop:** 520 ms `ease.settle`; opacity 0 → 1, brightness 0.6 → 1, scale 1.03 → 1, no blur. It plays for an image that decodes while 12 are already racking. The count is kept in `play("rack")` / `CineMotion.play`.
- **§4.8:** Develop's reduced variant is Rack focus's 160 ms opacity fade.
- **§15.6 bullet:** "At most one animated blur layer per screen outside letter reveals and Rack focus; Rack focus runs on at most 12 images at once." PRODUCT-12 removes the 60-grapheme half of this bullet.
- **§15.8 device pass** adds a desktop Library wall and a Discover results page at first load, with the timings overlay on.

### STACK-15 · low · Web audio formats (§9.4.2)

The routes are PRODUCT-11's. Add to §9.4.2 Playback:

- **Soundscapes on the web:** request `.ogg` when `new Audio().canPlayType('audio/ogg; codecs="vorbis"')` is non-empty, otherwise `.m4a`. The loops are Ogg Vorbis, and `decodeAudioData` needs a decodable file.
- **Narration and voice samples on the web** keep the existing Ogg Opus probe, `pickNovelAudioFormat` in `frontend/src/features/novels/audio-url.ts`.
- **The app:** `m4a` for iOS narration and the iOS soundscape (`just_audio`); `ogg` for SoLoud samples (STACK-2).

### STACK-16 · medium · Circle response shapes, the sharing read, adder ids (§9.3.8, §9.3.5, §8.11)

These go on top of PRODUCT-3. Add to §9.3.8:

- **`GET /circle/members`** → `[{profile_id, name, avatar_key, username, shares: {activity, reactions, shelves, recommendations}, now: {source_id, series_key, chapter_key, chapter_number, title, ambient, since} | null}]`.
- **`GET /circle/feed?cursor&limit=50`** (plus PRODUCT-3's filters) → `{items: [{id, kind: "started" | "finished_chapter" | "finished_series" | "reacted", actor: {profile_id, name, avatar_key, username}, source_id, series_key, title, cover_url, ambient, chapter_key?, chapter_number?, reaction?, created_at}], next_cursor}`.
- **`GET /circle/reactions?source&series`** → `{chapters: [{chapter_key, counts: {loved, shook, laughed, tears, chefs_kiss}, by: [{profile_id, avatar_key, kind}]}]}`. The spoiler guard stays on the client (§9.3.3).
- **`GET /circle/letters`** → `[{id, from: {profile_id, name, avatar_key, username}, source_id, series_key, title, cover_url, ambient, note, state: "new" | "read" | "kept" | "dismissed", created_at}]`.
- **`GET /profiles/{id}/sharing`** → `{activity, reactions, shelves, recommendations, include_mature, excluded_series: [{source_id, series_key, title}]}`. It feeds the §9.3.6 rows. `PATCH` takes the same shape.
- **Adders.** `GET /library/collections/{id}` member rows gain `added_by_profile_id`, which draws the 20 px adder avatar of §9.3.5. `DELETE /library/collections/{id}/series/{…}` is authorised by role: the owner removes any series, a `can_add` member only the rows where `added_by_profile_id` is their own, and anyone else gets `403 forbidden`.

### STACK-17 · low · Recap: non-stream answers and stream headers (§9.1.7)

These go on top of PRODUCT-1:

- **No stream.** When no recap can be written at request time, `GET /ai/recap` answers plain JSON 200 before any stream: `{"available": false, "reason": "not_configured" | "budget_exhausted" | "rate_limited" | "no_dialogue" | "first_chapter"}`. The clients treat that `Content-Type: application/json` as the §9.1.8 unavailable state.
- **Stream headers:** `Content-Type: text/event-stream`, `Cache-Control: no-cache, no-transform`, `X-Accel-Buffering: no`. `no-transform` stops the Next server's compression middleware from buffering the `/api` rewrite.

### STACK-18 · medium · `GET /home` item shapes and the Similar envelope (§9.1.7)

The time zone is PRODUCT-10's. Add a table under the `GET /home` row:

| Section `type` | `items[]` |
|---|---|
| `continue` | continue-reading rows + `ambient`, `nudge: "new" \| "almost_done" \| "paused" \| null`, `new_count`, `paused_days` (the §8.8 badges `3 NEW`, `ALMOST DONE`, `PAUSED 21 D`) |
| `new_this_week`, `where_were_we` | FollowedSeries list rows + `ambient` |
| `almost_there` | FollowedSeries list rows + `ambient`, `chapters_left` |
| `sent_to_you` | Letter (the `GET /circle/letters` shape, STACK-16) |
| `picked`, `because`, `first_picks`, `popular` | `{kind: "world", item: WorldItem}` or `{kind: "source", item: SourceSeries}`, each with `why` |
| `circle`, `circle_top` | `{member: {profile_id, name, avatar_key}, series: {source_id, series_key, title, cover_url, ambient}, rank?}` |
| `sources` | pin rows + `latest_covers: [cover_url × 3]` |
| `genres` | `[{genre, weight}]` |
| `numbers` | `{streak: {current_days, longest_days, alive_today}, chapters_week, seconds_week}` |

`GET /ai/similar` (both the `source&series` and the PRODUCT-2 `anilist_id` form) → `{items: WorldItem[] (each with why), available, reason: "ok" | "not_configured" | "budget_exhausted" | "rate_limited", generated_at}`.

### STACK-19 · medium · Guided-view panels: bounded server job (§9.4.3, §2.1.5, §15.5). Conflicts with PRODUCT-4

**Apply either this or PRODUCT-4, not both.** The stack lens recommends this one:

- it conforms to `stack-decision.md` §2.6 item 2 without a sign-off;
- it is one Python implementation instead of two parity-tested ones (TS and Dart) plus 24 fixtures;
- it decodes only chapters where someone asked for guided view.

PRODUCT-4's offline advantage is kept by copying `pages[].panels` into the local manifest when a chapter is downloaded after its panels are ready.

- **Trigger:** `POST /reader/panels/request {source_id, series_key, chapter_key}` → 202. The client sends it when a profile first opens guided view on a chapter whose manifest has `panels_ready: false`.
- **Bounds:**
  - one job at a time (a single in-process queue, deduplicated by chapter);
  - pages are fetched through the page proxy at its 480 px width (`PAGE_WIDTHS` in `image_resize.py`);
  - chapters over 200 pages are skipped and answer `failed`;
  - results are cached per page ETag, as §9.4.3 says.
- **`GET /reader/panels?source&series&chapter`:**
  - `200 {status: "ready", pages: [{number, panels: [{x, y, w, h}]}]}`;
  - `200 {status: "pending", retry_after_s: 10}`;
  - `200 {status: "failed"}`.
- **Client:** while guided view waits, it polls every 10 s (visible screen only) and shows the §9.4.3 not-ready state. The `panel-focus` button appears when the status is `ready`.
- **Reword §2.1.5's rationale** (l.147): "page tint must exist on the first read of every page, so it is sampled on the client; panels are computed once per chapter, only on request, in a bounded server job." Also change §15.5 l.3838 to "the image proxy itself does no image analysis".

### STACK-20 · low · `GET /library/annual` response (§9.2.7)

These go on top of PRODUCT-24, PRODUCT-10 and PRODUCT-18. `GET /library/annual?year=2026&tz_offset_minutes=330` →

```
{
  year, partial, since, until, recorded_days, seconds_read, chapters_read,
  chapters_by_month: [12 ints],
  top_series: [{source_id, series_key, title, cover_url, ambient, seconds_read, chapters_read}] (≤ 5),
  genres: [{genre, weight}] (≤ 8),
  by_hour: [24 × {hour, seconds_read}],
  longest_streak: {days, month},
  top_sources: [{source_id, name, share}] (≤ 3),
  circle: [{profile_id, name, avatar_key, finished_together: [title]}] | null,
  top_voices: [{voice_id, name, seconds}] (≤ 3),
  available_years: [int]
}
```

`partial` is true for the current year. It drives the existing "Your year so far" line (l.2963). 18+ series are filtered on serve for a gated profile.

### STACK-22 · medium · Smart shelf rules are stored (§8.11, §15.5)

- Collections gain `rules: null | {all: [{field: "reading_status" | "is_favorite" | "new_count" | "format" | "content_kind", op: "eq" | "gte" | "in" | "ne", value}]}` on `POST`, `PATCH` and both `GET`s.
- `smart` is `rules != null`.
- "Unfinished novels" is `content_kind eq "novel"` AND `reading_status ne "completed"`.
- Membership is still computed on the device from `/library/series`, as l.1911 says. The server only stores the rules, so every device shows the same smart shelf.
- Add the row to §15.5.

### STACK-23 · medium · The edition preview route (§8.30.3, §15.2)

- **Separate root layouts.** Move today's root into a route group, `app/(app)/layout.tsx` (URLs unchanged). Add `app/(preview)/skin-preview/[skin]/layout.tsx`, a second root layout that renders `<html data-skin={skin}>` with that skin's `fonts.ts` classes and no Shell (in Next 16, `const { skin } = await params`). It is a full page load, which the iframe is anyway.
- **Fixture.** `page.tsx` seeds React Query from the fixture, `<HydrationBoundary state={dehydratedFixture}>`, with the same query keys `useHomeFeed()` uses, so the skin's real Tonight renders unchanged.
- **Build context.** `design/build.mjs` copies `design/previews/demo-feed.json` to `frontend/src/skins/preview-feed.generated.json`, and `design/previews/covers/*.webp` to `frontend/public/skin-preview/covers/`. Both are committed and checked by `--check`, because the Docker build context is `./frontend`.

### STACK-24 · medium · When `ambient` exists (§2.1.5, §15.5)

- **Computed in one place.** `ambient` is computed only in the cover proxy's resize path (`image_resize.py`), the first time a cover URL is served at any width, and cached with it. List, search and browse endpoints never fetch or decode a cover to fill it.
- **Payloads carry `ambient: {duo, tint, ink} | null`,** where null means "not computed yet". Clients paint `color.ambient.fallback.*` for null. When a later payload carries the value, they dissolve to it over 800 ms `ease.turn`, the normal ambient transition of §2.1.5.
- **WorldItem.** WorldItem `ambient` comes from a background fetch of the AniList cover through the same extractor, limited to 20 per minute. The first recommendation payload may carry null.
- Replace "on every series payload" in l.119 and the §15.5 row with "on every series payload, or null until the cover has been served once".

### STACK-25 · low · Duotone in sRGB (§2.1.5)

l.137 web: `<filter id="duo-{id}" color-interpolation-filters="sRGB">` with the same `feColorMatrix`. The web, Flutter `ColorFilter.matrix` and the Canvas 2D share-card renderer then apply the one matrix to the same encoded values.

### STACK-26 · low · Scope the registered colour properties (§2.1.5, §2.8.1, §15.6)

- **Page tint.** Write `--page-tint` and `--page-light` on the reader chrome's root (the overlay holding the running head, folio bar, ruler and scrims) and on the two desktop gutter elements, never on an ancestor of the strip. The setup sheet sets them on its own root when it opens. A tint transition then restyles only the chrome, not hundreds of page boxes.
- **Ambient.** `--amb-*` go on the hero or spread element that paints them, not on the page root.
- **Registration.** `inherits: true` stays.
- **§15.6:** replace "CSS registered properties (compositor-friendly)" with "CSS registered properties, which transition on the main thread, so they are set only on the few elements that paint them".

### STACK-28 · low · iOS back release and the Quick look match cut (§8.0.5, §7.22)

- **Back release.** §8.0.5 iOS Back cell: replace "release `spring.release`" with "release: the package's own `Curves.fastLinearToSlowEaseIn` (0.4.8 hard-codes it in `dragEnd`), which is the iOS system back curve". Make the same change to MOBILE-1's "Release uses `spring.release`" line. No fork.
- **Quick look.** §7.22: replace "`onLongPress` + `showModalBottomSheet`" with "`onLongPress`, then pushes a `CineSheetRoute` (STACK-7). It is a `PageRoute`, so the poster's `Hero` flies into the 96 px header over the Rise."

### STACK-32 · low · Record the generator and layout departures (§15.10, §15.3)

- **§15.10 row S16** "stack §2.1 outputs, §2.3 tokens":
  - the generator also writes `frontend/src/skins/theme.generated.css`, the shared `@theme inline` and `@utility` block;
  - the Dart output per skin is a `ThemeExtension` (`CineTokens`, and `GlassTokens` later) plus the `static const` classes of §2.8, and the stack's shared `SkinTokens` type is not used;
  - status: amendment; generator change only.
- **§15.3.** Move the `assets/skin_previews/…` row out of the `mobile/lib/skins/cinematic/` table and into the "Outside the skin folder" line, as `mobile/assets/skin_previews/{cinematic,glass}/000–035.png`, declared under `flutter: assets:` (the path §8.30.3 already uses).

### STACK-33 · low · Pin the build tools; build Android in the gate (§15.11, §12.7, §6)

- **Ledger:**
  - `fantasticon` **4.1.0** (npm, needs Node ≥ 22, which this box has) and `@resvg/resvg-js` **2.6.2** (npm), both dev only, run with `npx` from `brand/` scripts;
  - `sox` **14.4.2**, as an authoring-only system tool whose outputs are committed.
- **Resolution check (l.3924).** Add a `flutter build apk --release` job to `.github/workflows/tests.yml` (a GitHub runner, never the dev box). With no `key.properties` it builds unsigned, which is enough for the check. The job runs in the isolated native-plugin commit and after any change to `pubspec.yaml` or `android/`. Today an APK is built only by `ops/vps/push.sh` at release time, so an NDK or manifest break in `flutter_soloud`, `audio_service` or `flutter_dynamic_icon_plus` would first show up there.

### STACK-35 · low · The service worker learns the skin by message (§8.32, §15.2)

- **Messages.** The page posts `{ type: "skin", skin }` to `navigator.serviceWorker.controller` on every boot, and `{ type: "skin-changed", skin }` on a switch (stack §2.5 step 3, now with the skin).
- **Storage.** The worker stores the value as the response of the `/__skin` request in a `mm-sw-meta` Cache Storage entry, because a worker can be stopped at any time.
- **Serving.** On an offline navigation it serves `offline-fallback-{skin}.html`, or `offline-fallback-cinematic.html` when nothing is stored.
- In l.2759 and l.3804, replace "chosen by the `mm-skin` cookie" with "chosen by the skin the page last posted to the worker".

### STACK-36 · low · The switch plays the full splash on the web (§8.2, §12.4)

§8.2 Warm start: "(resumed within 4 h, or any web navigation after the first in a session, except a skin change)". Add to §12.4: "Web: the splash plays the full reveal when `sessionStorage['mm.skin.splash']` is missing or differs from the current skin, then writes the current skin to it; otherwise it plays the warm fade (stack §2.5 web step 6)."

### STACK-37 · low · The stop-press banner lives outside sonner (§7.11, §8.33.3)

- The banner renders in the toast host's fixed container, at the anchor WEB-3 sets. It is not a sonner toast.
- While it shows, the host renders `<Toaster offset={{ bottom: anchorBottom + bannerHeight + 8 }} mobileOffset={{ bottom: anchorBottomPhone + bannerHeight + 8 }} visibleToasts={1} />`. Otherwise it renders `visibleToasts={2}` with the plain anchors. The toast then always sits above the banner, and a second toast replaces the first (§7.11).
- Replace "is a member of the same stack" in l.1149 with "shares the toast anchor and sits under the stack".

### STACK-39 · low · Small request and response gaps (§8.17, §9.1.7, §15.5, §8.7)

- **Repoint:**
  - `POST /library/series/{followed_id}/repoint {source_id, series_key, keep_old: bool}` → `{followed: FollowedSeries, mapped_chapter_key, mapped_chapter_number | null}`, joining the existing `/library/series/{followed_id}` family;
  - `keep_old: true` keeps the old follow row and creates a new one; `false` repoints the row and fills `migrated_from_*`;
  - fix the path in l.2399 and l.3844.
- **AI feedback:** `POST /ai/feedback {signal: "not_interested" | "liked_pick" | "tag_rejected", anilist_id?, source_id?, series_key?, tag?}` → 204. `tag` is required for `tag_rejected`. Update l.2935.
- **Responses:** `POST /reader/page-tints` → 204 (unknown pages are ignored). `POST /library/statistics/milestones/{days}/seen` → 204.
- **Collection plates:** list rows gain `preview_covers: [cover_url] (≤ 4)` and `preview_ambient_duo`. Name the fields in l.3848.
- **Taste** (the §8.7 table already fixes `formats[]` and `genres{name: 1|2|-1}`):
  - `seeds: [{anilist_id} | {source_id, series_key}]`;
  - `styles: ["painted" | "cel" | "screentone" | "manhua-3d" | "sketch" | "retro" | "pastel" | "noir" | "chibi"]`, the nine crops of step 4 by file name.

---

## Refuted

| ID | Why |
|---|---|
| STACK-10 | Duplicate. CONSISTENCY-13 and MOBILE-4 already confirm a single session policy: ambient with mixing by default, `speech()` while narration plays, the startup `configureNovelAudioSession()` replaced, and Android focus rules (MOBILE-4). Apply MOBILE-4's table, and keep the `legacy` skin on `speech()` for narration until the flip, since it also loses the startup call. |
| STACK-21 | Duplicate. PRODUCT-2 confirms `GET /onboarding/catalog` (formats, genres and 24 gated seed WorldItems from AniList) and `GET /ai/similar?anilist_id` for the "insert 3 similar" step. |
| STACK-27 | Speculative optimisation. The grain runs only on the one visible hero, pauses off screen (§15.6), and repaints a tiled 256 px PNG 12 times a second. No budget in the contract is broken, and no dropped frame is shown. |
| STACK-29 | Duplicate of CONSISTENCY-45 (the same `GradientTransform` ellipse fix). |
| STACK-30 | Duplicate of CONSISTENCY-8 and PRODUCT-12 ("One count": non-space graphemes on both clients). |
| STACK-31 | Duplicate of CONSISTENCY-15 items 2 and 3 (lint scope, `--animate-caret-out` in `@theme`). |
| STACK-34 | Duplicate of MOBILE-16 (the deferred Android alias swap via the package's service, and the rewritten confirm line). |
| STACK-38 | Duplicate of MOBILE-5 ("Declare every static `/library/...` path before `/library/:followedId`"). |
