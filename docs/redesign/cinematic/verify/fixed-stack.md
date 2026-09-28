# Cinematic DESIGN.md: fixes applied from the stack-feasibility judge

## Round 1

Source: `cinematic/verify/judge-stack.md`, section "Confirmed" (31 findings). 30 were applied as the judge wrote or narrowed them. STACK-19 was not applied (see below). The 8 refuted findings (STACK-10, 21, 27, 29, 30, 31, 34, 38) are not applied. Section numbers refer to `cinematic/DESIGN.md`.

| ID | Sections changed |
|---|---|
| STACK-1 | `share_plus` 13.3.0 → **12.0.2** in §8.0.5 Share row, §9.2.5 Flutter export (full `ShareParams` call), §15.3 packages, §15.11 ledger row (with the `win32 ^6` note) |
| STACK-2 | `flutter_soloud` 5.1.4 → **4.1.7** in §6 playback, §8.16.5 voice pulse, §15.3 packages, §15.11 ledger row (with the `meta` 1.18.0 / `native_toolchain_c` note); §8.16.5 gains "always request `format=ogg`, on iOS too" and names `updateSamples()` / `getAudioData()` |
| STACK-3 | §3.1 Delivery and §15.2 `fonts.ts`: all four `next/font/google` calls carry `subsets: ["latin", "latin-ext"]`; §3.1 notes the reading faces and Noto stay `preload: false` |
| STACK-4 | §8.30.3 outgoing table: t = 0 row (PATCH sent, mirror not yet written), t = 500 split into web (await PATCH ≤ 1,000 ms, then cookie, return route, SW message, `location.replace`) and app (mirror, restart, PATCH in outbox) rows; new "The switch waits for the server" paragraph (error/timeout reversal, toast, outbox wins at mobile boot); reduced-motion line; §8.30.1 offline caption; §15.10 row **S12** |
| STACK-5 | §2.8.4 spring rows: Flutter durations 504 / 576 / 288 ms (`ms × 1.2`); §4.4 spring table Flutter column; new "Springs on each client" paragraph after the §2.8.4 table; §15.1 generator mapping sentence; §15.10 row **S13** |
| STACK-6 | §2.8.4 spring rows: CSS `--mm-spring-*-ms` = settle time 800 / 850 / 500 ms (verified against the installed `motion-dom` `spring().toString()`); stdlib generator and `tokens.test.ts` Vitest equality case in the "Springs on each client" paragraph; §15.1 |
| STACK-7 | §7.9 new "Flutter: `CineSheetRoute`" paragraph (`PageRoute`, controller, detents, spring release, 30 % / 800 px/s dismissal, rubber band); §15.3 `primitives/` cell |
| STACK-8 | §8.0.3 `tonight` row (`app/page.tsx`, two-cookie `missing` redirect gate until the flip); §15.2 new "Home route" paragraph (supersedes WEB-29's single-cookie gate; the web fixer kept it) |
| STACK-9 | §8.0.4 web paragraph rewritten (types on `<Link>` / `router.push`, wrapper `enter`/`exit` maps, shared covers with the FNV-1a `coverTransitionName`, popstate `none`); §15.2 View transitions paragraph |
| STACK-11 | §8.16.10 new "Native wiring and a single init" block (`AudioServiceActivity`, manifest service/receiver/permissions, `AudioService.init` once in `main()`, `audioHandlerProvider`); §15.3 "Outside the skin folder"; §15.10 row **S14** |
| STACK-12 | §8.30.3 new "The restart re-reads the boot state" block (`AppRestart` builder, `main.dart` overrides, `SkinBoot.read`, `initialLocation`); §8.30.3 app restart call is `AppRestart.of(context).restart()`; §15.3 "Outside the skin folder"; §15.10 row **S15** |
| STACK-13 | §2.1.5 reader-page row: `createImageBitmap(img, { resizeWidth: 16, resizeHeight: 16, resizeQuality: "medium" })`, fallback downsample, `bitmap.close()` |
| STACK-14 | §4.5 Rack focus "Where" (cap of 12 at once, counted in `play("rack")` / `CineMotion.play`) and new **Develop** row; §4.8 Develop reduced row; §15.6 blur bullet; §15.8 device pass (desktop Library wall and Discover results at first load) |
| STACK-15 | §9.4.2 new **Formats** bullet (web soundscape `canPlayType` Vorbis probe, else `.m4a`; narration keeps `pickNovelAudioFormat`; app formats) |
| STACK-16 | §9.3.8 new "Response shapes" (members, feed, reactions, letters, `GET /profiles/{id}/sharing`) and "Adders" (`added_by_profile_id`, role-based `DELETE`) bullets; §9.3.5 adder avatar source; §8.11 permission table `Remove from shelf` row |
| STACK-17 | §9.1.7 `GET /ai/recap` notes: plain-JSON "no stream" answer and the three stream headers |
| STACK-18 | §9.1.7 `GET /ai/similar` envelope (`items`, `available`, `reason`, `generated_at`); new "`GET /home` section items" table under the §9.1.7 table |
| STACK-20 | §9.2.7 `GET /library/annual` response by field name, `partial`, 18+ filter on serve |
| STACK-22 | §8.11 smart-shelf bullet (rules stored server-side, `rules` shape, `smart = rules != null`, "Unfinished novels" rule); §15.5 new collections `rules` row |
| STACK-23 | §8.30.3 web preview bullet (route path under `app/(preview)/`, three sub-bullets: separate root layouts, `HydrationBoundary` fixture, build-context copies); §15.2 "Outside the skin folder" |
| STACK-24 | §2.1.5 intro ("or null until the cover has been served once") and new "When `ambient` exists" paragraph; §2.1.5 computed-by table (Series cover, AniList cover rows); §15.5 first row |
| STACK-25 | §2.1.5 duotone: `<filter … color-interpolation-filters="sRGB">` |
| STACK-26 | §2.1.5 Animating colour (write registered properties only on the painting elements); §2.8.1 runtime-colours line; §15.6 ("transition on the main thread", no longer "compositor-friendly") |
| STACK-28 | §8.0.5 iOS Back cell and the iOS route-transition paragraph (release on the package's `Curves.fastLinearToSlowEaseIn`, no fork); §4.4 `spring.release` use column; §7.22 Quick look (pushes `CineSheetRoute`, `Hero` flies into the 96 px header) |
| STACK-32 | §15.3 table: the `assets/skin_previews/…` row moved to "Outside the skin folder" as `mobile/assets/skin_previews/{cinematic,glass}/000–035.png` under `flutter: assets:`; §15.10 row **S16** (`theme.generated.css`, per-skin `ThemeExtension`) |
| STACK-33 | §15.11 ledger: `fantasticon` 4.1.0, new `@resvg/resvg-js` 2.6.2 and `sox` 14.4.2 rows; §15.11 resolution check gains the CI `flutter build apk --release` job; §2.7 and §12.7 name the pinned tools; §15.3 native-plugin commit line |
| STACK-35 | §8.32 offline fallback row, §15.2 Service worker paragraph (boot and switch messages carry the skin, `mm-sw-meta` Cache Storage, `offline-fallback-{skin}.html`); §8.30.3 web restart row posts `{ type: "skin-changed", skin }` |
| STACK-36 | §8.2 Warm start ("except a skin change"); §12.4 web `sessionStorage['mm.skin.splash']` rule |
| STACK-37 | §7.11 "Stacking with the stop-press banner" row (outside sonner, `offset` / `mobileOffset` / `visibleToasts`); §8.33.3 banner text |
| STACK-39 | §8.17 and §8.18 repoint path `POST /library/series/{followed_id}/repoint` with `keep_old` and its response; §8.17 suggested-tag reject body; §9.1.7 `POST /ai/feedback` row; §2.1.5 and §15.5 page-tints → 204; §15.5 milestones seen → 204; §15.5 repoint row; §15.5 collections `preview_covers` / `preview_ambient_duo`; §8.7 Backend (`seeds`, `styles` values) |

**Not applied: STACK-19** (guided-view panels as a bounded server job). The judge marks it as exclusive with PRODUCT-4 ("apply one or the other, not both"). When this round reached it, PRODUCT-4 (client-side detection, sign-off **S11**) had already been applied to §9.4.3, §15.5, §15.6, §15.8 and §15.10. Applying STACK-19 on top would have left two contradictory designs, so it was skipped. If the owner rejects S11, STACK-19 is the ready fallback: `POST /reader/panels/request`, the one-job queue at 480 px, the `ready | pending | failed` poll, and the rewording of §2.1.5 and §15.5. Note for the main session: §8.14.3 (the reader's trailing buttons) still gates the `panel-focus` button on `panels_ready`, which PRODUCT-4 removes. That line belongs to the PRODUCT-4 fix and was left alone here.

The Coverage appendix (Appendix B) is unchanged: no screen was added, removed or renamed. `/` now actually reaches `tonight` (STACK-8), which the appendix already lists.

## Round 2

Source: the five findings `cinematic/verify/recheck-stack-1.md` left unresolved (STACK-4, 8, 16, 18, 23), each fixed as the recheck wrote it; the other 26 confirmed findings were resolved in round 1 and a grep of their old values (`13.3.0`, `5.1.4`, `compositor-friendly`, `DraggableScrollableSheet`, `panels_ready`, `chosen by the mm-skin cookie`, `member of the same stack`) still returns 0. Two of the recheck's non-blocking nits were also applied.

| ID | Sections changed |
|---|---|
| STACK-4 | §8.2 Outcomes: the mismatch restart now applies only "with no outbox `PATCH /profiles/{id}` carrying `skin` queued (a queued one wins and the restart is skipped, §8.30.3)". §8.30.3 "The switch waits for the server": a failed web switch also removes `mm.skin.t0` from `sessionStorage`, so the next splash cannot log a false `SKIN RESTART` |
| STACK-8 | §8.0.3 `tonight` row and §15.2 "Home route": Home is `frontend/src/app/(app)/page.tsx` (Next 16 needs `/` inside a route group when there is no top-level layout); redirect gate unchanged |
| STACK-16 | §9.3.8 lead paragraph and §15.5 Circle row: `now` points at the §9.3.8 response shape (with `chapter_number` and `title`) instead of the old field list. §9.3.8 feed filter is `kind=reading|reaction` with the mapping `reading` = `started \| finished_chapter \| finished_series`, `reaction` = `reacted`; `letter` dropped (the LETTERS tab reads `GET /circle/letters`). Member page returns `shares: {activity, reactions, shelves, recommendations}` (was `sharing`). §15.5 Circle row adds `GET /profiles/{id}/sharing`, the feed filter values and `added_by_profile_id` with the role-based series `DELETE` |
| STACK-18 | One streak object `{current_days, longest_days, at_risk, last_active_date}` (the existing `GET /library/statistics` streak plus `at_risk`): §9.1.7 `GET /home` top-level `streak`, §9.1.7 `numbers` section item (`{streak, chapters_week, seconds_week}`, same object, `alive_today` dropped), §9.1.2 at-risk recompute (`current_days ≥ 2`), §15.5 `GET /home` row |
| STACK-23 | §8.30.3 web preview "Separate root layouts" sub-bullet split into *Pages move* (every existing route folder plus `error.tsx` / `not-found.tsx` under `app/(app)/`, Home at `app/(app)/page.tsx`), *Root files stay* (`global-error.tsx`, `manifest.ts`, `favicon.ico`, the CSS files; `providers.tsx` stays), *404* (catch-all `app/(app)/[...missing]/page.tsx` calling `notFound()` instead of `experimental.globalNotFound`; the array-form `/api/:path*` rewrite is `afterFiles`, applied before dynamic routes, so the proxy is not swallowed) and *Preview layout*. §15.2 "Outside the skin folder" repeats the move. §8.32 404 row names the file and the catch-all. New §15.10 row **S17** |
| Nit N1 (STACK-7) | §15.3 Packages: "the built-in `Hero`, `SpringSimulation` and `PageRoute` (for `CineSheetRoute`, §7.9)" |
| Nit N2 (STACK-18) | §8.7 Backend: `GET /ai/similar?anilist_id` returns the §9.1.7 envelope with 3 WorldItems in `items` |

Not applied: nit N3 (moving the `GET /library/annual` response block into its own paragraph). It is unambiguous as it stands, and moving a block while other lenses edit §9.2.7 risks a merge collision.

Old values now at 0 hits: `alive_today`, `streak: {current,`, `` `current` `` / `current ≥` for the streak, `kind=reading|reaction|letter`, `sharing: {activity`, `now {source_id`, `src/app/page.tsx`. The Coverage appendix (Appendix B) is unchanged: no screen was added, removed or renamed.

## Round 3

Source: the two findings `cinematic/verify/recheck-stack-2.md` left unresolved (STACK-18, STACK-23), each fixed as the recheck wrote it, plus two small follow-ons that make the same fixes work end to end. The other 29 confirmed findings were already resolved (recheck-stack-2: 29 resolved); STACK-19 stays the documented fallback to PRODUCT-4 (S11). Two of the recheck's non-blocking nits were also applied.

| ID | Sections changed |
|---|---|
| STACK-18 | The one streak object gains `milestones_seen`: `{current_days, longest_days, at_risk, last_active_date, milestones_seen}` in §9.1.7 `GET /home` top-level `streak`, the §9.1.7 `numbers` section item and the §15.5 `GET /home` row, so "the `GET /library/statistics` streak object plus `at_risk`" is literally true. §15.5 milestones row: `milestones_seen` sits on "the one streak object that `GET /library/statistics` and `GET /home` share". §9.2.2 milestone title cards: stored as `streak.milestones_seen`, returned by both endpoints so Tonight and The Numbers agree; the card opens when `current_days` has reached a milestone missing from the list, and opening it posts `POST /library/statistics/milestones/{days}/seen` |
| STACK-23 | §8.30.3 *Root files stay*: both root layouts import `app/globals.css` (`../globals.css` from `(app)`, `../../../globals.css` from the preview layout). §8.30.3 *Preview layout*: imports the same global stylesheet (a stylesheet imported by one root layout never reaches routes under another) and mounts no `Providers`. §8.30.3 **Fixture**: `HydrationBoundary` sits inside `preview-query.tsx` (`"use client"`, `QueryClientProvider` around a fresh `QueryClient`, `staleTime: Infinity`, `retry: false`), because without a provider `HydrationBoundary` throws, and with the app's provider the iframe would refetch the viewer's own `/home` over the fixture. §15.2 "Outside the skin folder": `{layout,page,preview-query}.tsx`, "own root layout and query client", "both root layouts import `app/globals.css`". §15.10 S17: "both import `app/globals.css`" |
| Nit N1 (STACK-5) | §2.8.4 "Springs on each client", Flutter bullet: `CineSprings` holds `const SpringToken`s (`CineSprings.release`, `.sheet`, `.scrub`); `SpringToken.description` builds the `SpringDescription` at run time because `withDurationAndBounce` is a `factory` (Flutter 3.44.6 `spring_simulation.dart` l.70). §7.9 `CineSheetRoute` release: `SpringSimulation(CineSprings.sheet.description, …)` |
| Nit N2 (STACK-16) | §9.3.8 `GET /circle/members/{profile_id}`: `now (the GET /circle/members shape, or null)` |

Not applied: nit N3 (READING tab empty-state copy vs the `kind=reading` filter). It is copy for the product lens.

Checks after the edits: `last_active_date}` (the four-field object) 0 hits; `milestones_seen` 5 hits, all on the one object; `globals.css` named for both root layouts at §8.30.3 and §15.2 and in S17; `SpringSimulation(CineSprings.sheet,` without `.description` 0 hits. The Coverage appendix (Appendix B) is unchanged: no screen was added, removed or renamed.

## Round 4 (main session)

- STACK-23: edition preview layout now mounts `duotone.tsx` (§8.30.3, §15.2 row), and §15.2 states that `app/globals.css` @imports `tokens.generated.css` and `motion.css` after `theme.generated.css`, so the preview gets the `[data-skin]` values and the duotone filter defs.
