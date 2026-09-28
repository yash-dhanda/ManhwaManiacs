**Decision: keep the stacks. The web stays Next.js 16 + React 19 + Tailwind 4 + Motion, and Android and iOS stay Flutter 3.44.6. Both skins are built as per-skin screen folders on each client's existing data layer, and design tokens, route paths, screen ids and haptic and sound event names are generated from one JSON source.**

# Stack decision for the Cinematic / Glass redesign

Judged 2026-09-28 from `stack-keep.md`, `stack-expo.md`, `inventory/*.md`, `research/*.md` and `00-baseline.md`. I checked the claims that decide the outcome against the checkout (`feat/vps-slim-source-native`): `mobile/lib/features/reader/widgets/reader_content.dart` (2,065 lines), `frontend/src/lib/scoped-storage.ts`, `frontend/public/sw.js`, `backend/routes/{profiles,settings}.py`, and the existing two-sided palette generator (`frontend/scripts/themes/build-themes.mjs` → `mobile/lib/app/theme/app_palettes.generated.dart`).

---

## 1. Scores

The scale runs from 1 (bad) to 10 (best). Where the two papers disagree on effort, I used the more conservative number and noted why.

| Criterion | Keep (Next + Flutter) | Expo universal | Why |
|---|:---:|:---:|---|
| Time to the first shippable skin on all 3 platforms | **7** | 6 | On paper it is 94.5 CCD for keep against 88 for Expo, but Expo's figure includes 29.5 CCD of parity work at ±30 % plus a 3-day spike that can fail. Keep's early days produce redesign work, not a return to today's features. Expo's own §10.2 admits that a 30 % parity slip puts its flip after keep's. |
| Total effort for two skins | 5 | **7** | 161 CCD against ≈131. Expo's 131 assumes the web-only layer stays small, and §10.3 of its own paper expects Cinematic's scrims, masks and blur to need `.web.tsx` escapes. I score it 7, not 9. |
| Motion, gesture and glass fidelity: **iOS** | 7 | **10** | Expo gets the real UIKit Liquid Glass, native tabs that minimise on scroll, native form sheets and the full-width back swipe. Flutter gets a shader imitation through `liquid_glass_widgets`, plus `swipeable_page_route` and `stupid_simple_sheet`. |
| Motion, gesture and glass fidelity: **Android** | **9** | 5 | Flutter runs the same refraction shader as on iOS. Expo gets `expo-blur` plus a Skia rim, which is frost without refraction (Expo's §10.1). |
| Motion, gesture and glass fidelity: **web** | **9** | 6 | Next gives Tailwind 4 with all of CSS, `@starting-style`, `linear()` springs, and router-integrated `<ViewTransition>`. react-native-web gives NativeWind 4 (Tailwind 3 semantics), a hand-wired `startViewTransition`, and escape hatches for the Cinematic surfaces. |
| Reader performance (long image lists, long novel text) | **9** | 6 | Flutter's strip is already tuned and tested: a 64 MB decode budget, a 2,880 px cap, extent compensation, a 30-frame restore and 120 Hz. Web novel text stays DOM. Under Expo the native strip is rebuilt on FlashList 2 + `expo-image` and has to be re-proven on devices. |
| Risk to downloads, OCR, TTS and tests | **9** | 4 | Keep touches none of them. Expo re-implements the sqflite store (6 tables, blobs, outboxes) on `expo-sqlite`, moves OCR into a new Expo module, ports about 40 test files, replaces 136 passing Dart logic test files, and has to migrate installed data in place. |
| Maintainability for one developer | 5 | **7** | Keep means four UIs (2 skins × 2 codebases) in two languages, with drift between web and phone. Expo means two UIs in one language, but adds Expo SDK majors, a native module that cannot be debugged without a Mac, and a web layer that grows by escape hatches. |
| **Sum (8 rows)** | **60** | **51** | |

### Why keep wins even though Expo is cheaper overall

- **Keep loses on two rows.** One is total effort (about 30 CCD by the end of Glass). The other is long-run maintenance (every future screen is written four times instead of twice). Both are real.
- **Keep wins on the rows where the damage cannot be undone.** Those are the reader, downloads, OCR, TTS and the test suite. They are working and tested today. The owner reads on them every day, and the redesign brief does not ask for any of them to change.
- **Expo's best argument is iOS glass, and that affects only one skin on one platform.** It would pay for it with Android Glass, the web Cinematic skin and the tuned reader.
- **The effort gap is inside the error bars.** It is ≈30 CCD on estimates that both papers put at ±30 %. The risk gap is not.
- **The option to move later stays open.** The web's platform-neutral TypeScript (142 files, 11,712 lines) stays platform-neutral. If Flutter glass or the four-UI cost proves unbearable after Cinematic ships, "Expo for the phones, Next for the web, on a shared `packages/core`" (keep's option A) is still available. It is not a one-way door.

### Conditions attached to the decision

- **Glass gate in the Flutter foundation week (1 CCD).** Build a `liquid_glass_widgets` 1.7.2 floating tab bar plus a detented sheet over a scrolling rail. Run it at 120 Hz on the owner's iPhone (CI IPA → SideStore) and on the Android flagship. If it janks or looks wrong on the iPhone, Flutter Glass uses `BackdropFilter` + `BackdropGroup` frost with a painted rim through the `SkinGlass` wrapper (§3.6). That changes one file, not the stack.
- **Re-estimate after the first two clusters** (primitives, then home and library) on both platforms. If the paired web + Flutter cost per cluster comes in more than 40 % over `stack-keep.md` §6, reopen the choice before Glass starts. That is the cheapest point at which to switch.

---

## 2. Skin-engine architecture

### 2.1 One source for everything both platforms must agree on

```
design/
├── tokens/
│   ├── cinematic.json        colour, type scale, radii, spacing, elevation, blur, motion, haptics, sounds
│   └── glass.json
├── contract.json             ScreenId list, route paths (+ params), haptic event names, sound event names
└── build.mjs                 ~150 lines, Node 22 stdlib only; `--check` mode for CI
```

`build.mjs` writes six files. Each generated file starts with a `GENERATED by design/build.mjs — do not edit` header, the same convention as `themes.generated.ts`.

| Output | Content |
|---|---|
| `frontend/src/skins/cinematic/tokens.generated.css`, `…/glass/tokens.generated.css` | `[data-skin="cinematic"] { --mm-color-bg: #000000; --mm-radius-card: 6px; --mm-ease-out: cubic-bezier(0.16,1,0.3,1); --mm-spring-sheet: linear(…); … }`, with springs pre-sampled into CSS `linear()` easings |
| `frontend/src/skins/<skin>/tokens.generated.ts` | the same values as numbers for Motion: `spring.sheet = { type: "spring", visualDuration: 0.5, bounce: 0.1 }` |
| `frontend/src/skins/contract.generated.ts` | `export const SCREEN_IDS = [...] as const; type ScreenId`, `ROUTES`, `HapticEvent`, `SoundEvent` unions |
| `mobile/lib/skins/<skin>/tokens.g.dart` | `const cinematicTokens = SkinTokens(bg: Color(0xFF000000), radiusCard: 6, sheet: SpringToken(ms: 500, bounce: 0.1), …)` |
| `mobile/lib/skins/contract.g.dart` | `enum ScreenId {…}`, `abstract final class Routes { static const library = '/library'; … }`, `enum HapticEvent {…}`, `enum SoundEvent {…}` |

Rules for the token format:

- **Lengths are logical px.** 1 CSS px equals 1 Flutter logical pixel, so values need no conversion. Letter spacing is authored in em. The generator multiplies it by the font size for Dart, because Flutter takes absolute `letterSpacing`.
- **Motion tokens are either springs or curves.** A spring is `{ "ms": 500, "bounce": 0.1 }`. It maps to Motion `{ visualDuration: 0.5, bounce: 0.1 }` and to Flutter `SpringDescription.withDurationAndBounce(duration: 500ms, bounce: 0.1)`. A curve is `{ "ms": 240, "bezier": [0.2, 0, 0, 1] }`. It maps to CSS `cubic-bezier` and to Flutter `Cubic`.
- **Haptics map each semantic event to a pattern name** (`"toggle": "selection"`, `"streak": "ahap:flame"`). Each platform's `haptics` file maps pattern names to calls, and the web maps them to nothing.
- **CI:** `tests.yml` runs `node design/build.mjs --check` in the web job. It regenerates the files into memory and fails if any committed output differs. The existing base16 pipeline (`frontend/scripts/themes/*`, `mobile/tool/themes/build_palettes.dart`) is deleted at the Cinematic flip, because the owner ruled out light themes and accent pickers.

### 2.2 Web folder layout (`frontend/src`)

```
app/                          thin route files only:  export default async () => { const S = skins[await getSkin()].screens.library; return <S/>; }
skins/
├── index.ts                  export const skins = { cinematic, glass, legacy } satisfies Record<SkinId, Skin>
├── server.ts                 getSkin(): reads the `mm-skin` cookie, falls back to 'cinematic' (to 'legacy' until the flip)
├── types.ts                  SkinId, Skin interface (tokens, fonts, Shell, screens: Record<ScreenId, Screen>, haptics, sounds, Splash)
├── contract.generated.ts
├── cinematic/                tokens.generated.{css,ts}, fonts.ts, Shell.tsx, Splash.tsx, primitives/*, screens/*, motion.ts, haptics.ts, sounds.ts
├── glass/                    same shape
└── legacy/                   index.ts only: maps ScreenId → today's page bodies (Partial; new-feature screens absent). Deleted at the flip.
features/<feature>/*.ts       THE SHARED DATA LAYER, left where it is: api, hooks, stores, reader strip/preload/scrub, offline queue, keyboard registry
features/<feature>/components legacy UI, deleted at the Cinematic flip
components/                   legacy UI, deleted at the Cinematic flip (keyboard/ and command-palette/ logic moves to lib/ first)
lib/, services/, stores/, types/, config/   shared, unchanged
```

- **The data layer does not move.** `stack-keep.md` and `discovery-ux.md` §10.3 propose moving the non-UI TypeScript into `src/core/`. That rewrites the import paths of about 200 files and their tests and buys nothing. After the flip deletes every `components/` folder, `features/` *is* the core.
- **The boundary is enforced by lint.** `eslint.config` puts `no-restricted-imports` on `src/skins/**`. It bans `@/components/**`, `@/features/*/components/**` and the other skin's folder. A skin screen can therefore import only data, hooks and its own primitives.
- **Completeness.** `screens: {...} satisfies Record<ScreenId, Screen>` makes a missing screen a type error for `cinematic` and `glass`. `legacy` is typed `Partial` so it never blocks new screens.

### 2.3 Mobile folder layout (`mobile/lib`)

```
main.dart                     reads SkinId from SharedPreferences, runApp(AppRestart(child: ProviderScope(overrides: [skinIdProvider.overrideWithValue(id)], child: SkinApp())))
app/
├── app_restart.dart          ~15 lines: StatefulWidget that swaps a UniqueKey above ProviderScope
└── skin_app.dart             MaterialApp.router(theme: skin.theme, routerConfig: skin.buildRouter(ref))
skins/
├── skin.dart                 enum SkinId { cinematic, glass, legacy }; abstract interface class Skin { theme; buildRouter; splash; haptics; sounds }
├── contract.g.dart
├── skin_haptics.dart         HapticEvent → haptic_feedback 0.6.5 / gaimon 1.5.0 AHAP / mm/haptics channel
├── cinematic/                tokens.g.dart, cinematic_skin.dart, shell.dart, router.dart, primitives/, screens/<cluster>/…
├── glass/                    same shape, plus glass/skin_glass.dart (the one wrapper around liquid_glass_widgets)
└── legacy/                   legacy_skin.dart: today's app_router.dart + AppTheme, unchanged. Deleted at the flip.
core/                         unchanged (config, network, storage, platform bridges, diagnostics)
shared/providers/             unchanged
features/<feature>/{models,providers,repositories,services,store,queue,utils,controllers}   THE SHARED DATA LAYER, left in place
features/<feature>/{screens,widgets}                                                     legacy UI, deleted at the flip
features/reader/engine/       NEW: extracted from reader_content.dart (feed reconcile, restore, extents, prefetch, progress, auto-scroll, taps)
```

- **The same rules apply as on the web.** Data stays where it is, and skins import only `features/*/{models,providers,repositories,…}`, `core/` and `shared/`.
- **The boundary is enforced by a test.** `test/skins/import_boundary_test.dart` greps `lib/skins/cinematic/**` and `lib/skins/glass/**` and fails on any import of `/screens/`, `/widgets/`, `app/theme/`, or the other skin.
- **Completeness is a test too.** `test/skins/completeness_test.dart` loops over `ScreenId.values` for `cinematic` and `glass` and asserts that each skin's router has a route for the path.
- **The reader engine is extracted first.** It happens in one commit that changes no pixels, before any skin work: `ReaderEngine` (a controller + Riverpod provider) plus a `chromeBuilder: (context, ReaderEngineState) → Widget` slot. `ReaderScreen` and `SourceReaderScreen` move to it in the same commit, and the existing reader tests must stay green.
- **Logic that lives in a widget moves first.** Some `widgets/` files hold logic, such as `download_chapter_state.dart`. Before its cluster is reskinned, that logic moves into `providers/` or `utils/` in a no-pixel commit.

### 2.4 Where the skin choice is stored: per profile and per device

| Layer | Where | Role |
|---|---|---|
| **Profile (source of truth, synced)** | New nullable column `reading_profiles.skin` (`'cinematic' \| 'glass'`, NULL means the default). One Alembic migration, `skin` added to `ProfileUpdate` and to `service.serialize` in `backend/routes/profiles.py`, set through the existing `PATCH /profiles/{id}` | The choice. It follows the profile to every device, so a profile sees the same skin on phone and desktop. |
| **Device mirror (boot cache)** | Web: cookie `mm-skin` (`Path=/; Max-Age=31536000; SameSite=Lax; Secure`, not httpOnly because the client writes it). Mobile: SharedPreferences `mm.skin.active` | Which skin to paint *before* a profile is known: first paint, login, setup and the profile picker. It is device-global on purpose and holds only the last active profile's skin, never profile data, so it does not break `scoped-storage.ts` isolation. |
| **Return route** | Web: `sessionStorage['mm.skin.return']`. Mobile: SharedPreferences `mm.skin.return` (cleared after it is read) | Brings the app back to the same path after the restart, through the shared `Routes` contract. |

Resolution at boot, on both platforms:

1. Render in the device mirror's skin. A fresh install gets `cinematic` (`legacy` until the flip).
2. When the active profile loads (or is picked), compare `profile.skin ?? default` with the mirror.
3. If they match, carry on.
4. If they differ, write the mirror, save the current path as the return route, and restart inside the profile-entry transition, with no confirm and no undo, as in `discovery-ux.md` §10.5 step 6.
5. Offline with no profile payload: keep the mirror.

A per-device override (for example Glass on the iPhone and Cinematic on the desktop) is left out on purpose. If the owner asks for it, it is one more key read before step 2.

### 2.5 How "restart to switch skin" works

The Settings flow is the one in `discovery-ux.md` §10.5: live previews, a confirm sheet, the outgoing transition, persist, restart, the incoming splash, and a 10 s undo toast.

**Web**

1. `PATCH /profiles/{id} { skin }`.
2. `document.cookie = "mm-skin=glass; …"` and `sessionStorage['mm.skin.return'] = location.pathname + location.search`.
3. `navigator.serviceWorker.controller?.postMessage({ type: 'skin-changed' })`. The service worker deletes `policy.pagesCacheName()` and re-fetches every saved chapter's `documentUrl` in the background, so an offline cold launch does not serve old-skin HTML.
4. The outgoing animation plays (Cinematic: 500 ms fade to `#000000` with the wordmark; Glass: blur to 40 px on the smooth spring).
5. `location.replace(returnPath)`.
6. The server reads the cookie in `getSkin()`, stamps `<html data-skin="glass">`, and renders `skins.glass.screens.X`. RSC sends only the Glass client chunks and `next/font` faces. Glass's `Splash` plays once, keyed on a `mm.skin.splash` sessionStorage flag.

**Mobile**

1. `PATCH /profiles/{id}` (the offline outbox queues it if needed).
2. `prefs.setString('mm.skin.active', 'glass')` and save the return route.
3. The outgoing animation plays.
4. `AppRestart.of(context).restart()` swaps the `UniqueKey`, which disposes every provider, the router and the caches.
5. `main`'s logic runs again, reads the new SkinId, and builds the Glass `GoRouter` with `initialLocation` set to the return route.
6. Glass's `splash()` plays.
7. Downloads resume on their own: a chapter found in `downloading` state at startup is re-queued. The confirm sheet shows "Downloads will resume after restart" when the queue is not empty.
8. Budget: under 1.5 s from confirm to the new splash.

### 2.6 How shared logic stays single-sourced

1. **Within each client there is one data layer.** Both skins call the same hooks and providers (`useHomeFeed()` / `homeFeedProvider` return typed rows with `state: 'loading' | 'ready' | 'empty' | 'unavailable'`), and the lint rule and boundary test in §2.2 and §2.3 stop a skin from growing its own. A hook that both skins need goes in `features/`, never in a skin.
2. **Across web and mobile, logic that must agree runs on the backend.** All four new feature areas are designed server-first, so each client only renders:
   - AI rails and the "previously on" recap
   - stats aggregates, streaks and Wrapped totals
   - the social feed and its per-profile and 18+ filtering
   - per-cover and per-page dynamic palettes
   - panel boxes for the guided view

   This is the 8 CCD backend line both papers already price. Shared caches apply the 18+ gate when serving, never when storing.
3. **Everything else that must match comes from `design/`:** screen ids, route paths, token values and event names (§2.1).
4. **Not single-sourced, on purpose:** the two reader engines (Dart and TS). Each is already tuned and tested on its own platform, and merging them is what the Expo option would have cost.
5. **Not built:** OpenAPI codegen for API types. Hand-written types on both sides work today. Add codegen from FastAPI's `/openapi.json` if a type drift bug ever ships.

---

## 3. What happens to the existing feature layers

| Layer | Fate |
|---|---|
| Web `features/*/*.ts`, `lib/`, `services/`, `stores/`, `types/`, `config/` (≈25k lines) and all 159 `*.test.ts` (2,304 cases) | **Kept in place.** They are the shared data layer. |
| Web `lib/keyboard`, command-palette logic, `features/offline`, `public/sw.js` | Kept. The palette *UI* is rebuilt per skin, and the SW gains the `skin-changed` message (§2.5). |
| Web `features/*/components/`, `components/{ui,layout,premium,settings}` | Become the `legacy` skin, then are deleted in the Cinematic flip release. |
| Web `features/preferences` theme/preset/accent system, `themes.generated.ts`, `scripts/themes/*` | Deleted at the flip (no light theme, no accent picker). The mature gate (`mature-gate.ts`) stays. Novel paper themes and typography stay as reader settings. |
| Web `appearance-boot-source.ts` | Reduced to stamping reader preferences. `data-skin` now comes from the server through the cookie. |
| Flutter `features/*/{models,providers,repositories,services,store,queue,utils,controllers}`, `core/`, `shared/providers` (≈27k lines), native channels (`OcrChannel.kt`, `MainActivity.kt`, `AppDelegate.swift`) and 136 logic test files | **Kept in place.** |
| Flutter `features/reader/widgets/reader_content.dart` | Split: the engine goes to `features/reader/engine/` and the chrome goes to each skin (§2.3). |
| Flutter `features/*/{screens,widgets}` (≈33.9k lines) and 76 widget-test files (24k lines) | Become the `legacy` skin, then are deleted at the flip. They are replaced by the completeness test, the boundary test and one smoke test per cluster per skin. |
| Flutter `app/theme/*`, `app/router/app_router.dart` | Wrapped by `legacy_skin.dart`, then deleted at the flip. The path constants in `app/router/routes.dart` are replaced by `skins/contract.g.dart`. |
| Backend | Unchanged except `reading_profiles.skin` and the new-feature endpoints. `backend/connectors/` is not touched. |
| CI (`tests.yml`, `ios-build.yml`, `codemagic.yaml`), SideStore path, APK channel | Unchanged, plus one `node design/build.mjs --check` step. |

**Release model.** Build beside `legacy`. The new skins are reachable only through a debug row in Settings until their completeness checks pass on both clients, so every sitting still releases web, Android and iOS together. The release that flips the default to Cinematic also deletes the `legacy` skin on both clients. Glass is built and flipped on the same way.

**Dependency changes** (the pinned lists in `stack-keep.md` §1.2–1.3 and `research/{web,flutter}-motion-libs.md`):

- **Web:** `framer-motion` 12 → `motion` 13.4.4, plus `@base-ui/react` 1.8.0, `embla-carousel-react` 8.6.0, `sonner` 2.0.8, and `lenis` 1.3.26 (Cinematic only).
- **Flutter:** `flutter_animate` 4.5.2, `liquid_glass_widgets` 1.7.2 (pinned exactly), `swipeable_page_route` 0.4.8, `stupid_simple_sheet` 0.9.1+1, `smooth_sheets` 1.2.0, `motor` 1.1.0, `heroine` 0.7.2, `haptic_feedback` 0.6.5 and `gaimon` 1.5.0. All of them resolve on Flutter 3.44.6 with `go_router` ≤17.5. Native plugins go in one isolated commit with a CI iOS dry run.

---

## 4. Risks and mitigations

| # | Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| 1 | The same skin feels different on web and phone (rail snap, sheet spring, hero timing) | High | Medium | Tokens and springs are generated from one JSON (§2.1). Each cluster is built on both clients in the same sitting. Review side by side: the Flutter screenshot harness (`test/screenshots/marketing_screenshots_test.dart` looped over both skins) next to Playwright screenshots. |
| 2 | Four UIs slow every future feature (≈139 of 161 CCD is skin UI) | Certain | Medium | Skins are complete or absent, never half-built. New cross-platform logic goes on the backend (§2.6). Re-evaluation gate after two clusters (§1). The Expo-for-phones exit stays open. |
| 3 | Flutter Glass on the owner's iPhone is an imitation, not UIKit Liquid Glass | Certain | Medium | Glass gate in the foundation week (§1). `glass/DESIGN.md` specifies Glass as its own material, not "pixel-exact iOS 26". All glass goes through `SkinGlass`, so the engine can be swapped in one file. |
| 4 | `liquid_glass_widgets` (a young single-maintainer fork) breaks or stalls | Medium | High for Glass | Pin exactly. Use only the `SkinGlass` wrapper. The code is MIT, so vendor it if upstream dies. Fallback: `BackdropFilter` + `BackdropGroup` + a painted rim. |
| 5 | Impeller glass costs GPU and memory on Android Vulkan (flutter#138627, #170820, #161297) | Medium | Medium | At most 2 stacked glass layers. Glass on chrome only, never inside the strip. `premium` quality on static chrome only. Profile with the existing Diagnostics FPS/jank screen. |
| 6 | Reader engine extraction regresses the most-tuned code | Medium | High | First commit, no pixel changes, both entry points together, gated by the existing reader tests. A device check on a 120-page, 2,880 px webtoon before any chrome work. |
| 7 | Stale skin after a switch: the SW serves old-skin HTML offline, or the RSC cache serves old-skin payloads | Medium | Low | `skin-changed` SW message clears the pages cache and re-fetches saved chapter documents (§2.5). A full `location.replace` drops the client router cache. |
| 8 | A skin mirror left behind on a shared device shows the previous profile's skin on the picker | Certain | Low | Intended: the picker is pre-profile. The switch happens inside the profile-entry transition, and no profile ever sees another profile's skin after it is selected. |
| 9 | The iOS loop is remote-only (CI IPA → SideStore) | High | Medium | Tune on Android first, since Flutter draws the same pixels. Batch iOS checks per cluster. Native plugins go in one isolated commit with a CI dry run. |
| 10 | Flutter 3.44.6 is pinned while packages move to 3.47 / `material_ui` / Riverpod 3 | Medium (grows) | Low now | Pin list as above. Do the upgrade as a separate change after Glass ships. |
| 11 | Dev-box memory (7,746 MB total, shared with production and five bots; `stack-keep.md` R10's 3.8 GB figure is out of date) | High | High if ignored | Run edits, `tsc`, `eslint`, `vitest`, `flutter analyze`, `flutter test` and the screenshot harness one at a time, checking `free -m` first. Never run two `next build`s at once. Gradle and Xcode stay in CI. Keep "next build before push". |
| 12 | Owner review bandwidth across about 161 CCD | High | Medium | Order: Cinematic, then the new features on Cinematic, then Glass. Each flip is a shippable end state. |
