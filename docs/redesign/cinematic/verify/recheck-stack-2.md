# Cinematic DESIGN.md: recheck round 2, stack lens

Checked 2026-09-28 against the 31 findings in the "Confirmed" section of `cinematic/verify/judge-stack.md`. I used `cinematic/verify/fixed-stack.md` (rounds 1 and 2) as the list of what the fixer changed, and `recheck-stack-1.md` for the round-1 fixes to the five findings reopened there. DESIGN.md was not edited.

**Snapshot note.** Other lenses were still editing DESIGN.md during this recheck. The mtime moved from 22:56 to 23:02 UTC, and the file stayed at 4,657 lines. I diffed my working snapshot against the last copy (mtime 23:02:35). The concurrent edits touched §2.8 (CSS custom properties, scrim tokens), §7.5, §7.6, §7.16, §8.23, §8.33.3, §9.1.5, the §9.1.7 recap row, §15.6 and §15.7. None of them undid a stack fix:

- The §9.1.7 recap row still has the STACK-17 plain-JSON "No stream" answer and all three stream headers. It now also maps each `reason` onto the §9.1.5 states.
- §8.33.3 still places the banner "outside sonner".

All line numbers below refer to the 23:02:35 copy.

**Method.** For each finding I read the target sections and compared them with the judge's final fix. For STACK-4, 8, 16, 18 and 23 I compared them with the round-1 recheck's rewritten fix. I then grepped the whole file for old values that should be gone, and for every other place where a changed value is repeated. I checked four claims against installed code:

- **`rewrites()` array form.** `frontend/next.config.ts` l.43–50 returns an array. Next's `rewrites.md` (installed copy, l.48) says an array is applied "after checking the filesystem (pages and `/public` files) and before dynamic routes". So the `[...missing]` catch-all cannot swallow `/api/:path*`, as §8.30.3 says.
- **Route folders.** `frontend/src/app/` holds the 15 route folders listed in §8.30.3 *Pages move*, plus `error.tsx`, `not-found.tsx`, `global-error.tsx`, `manifest.ts`, `favicon.ico`, `globals.css`, `presets.css`, `themes.generated.css` and `providers.tsx`. `layout.tsx` imports `./globals.css`. That global stylesheet is the only one the app has (see STACK-23 below).
- **Streak fields.** `backend/tests/test_reading_statistics.py` l.62–64 confirms the existing statistics streak object: `current_days`, `longest_days`, `last_active_date`.
- **Flutter springs.** `SpringDescription.withDurationAndBounce` is a `factory` in the Flutter 3.44.6 SDK (`spring_simulation.dart` l.70). See nit N1.

**Result: 29 resolved, 2 unresolved (STACK-18, STACK-23).** Round 2 fully closes STACK-4, STACK-8 and STACK-16.

The two that stay open were each applied as written, but each round-2 fix left a gap in a place the fix itself wrote:

- **STACK-18:** the new streak object's field list disagrees with the sentence right after it, and Tonight's milestone card loses its input.
- **STACK-23:** the only stylesheet import went into one of the two root layouts, so the edition preview renders unstyled.

The 8 refuted findings (STACK-10, 21, 27, 29, 30, 31, 34, 38) are out of scope.

---

## Verdicts

| ID | Status | Evidence (current line numbers) | Notes |
|---|---|---|---|
| STACK-1 | Resolved | `share_plus` 12.0.2 at l.1676 (§8.0.5), l.3007 (Backup export), l.3373 (§9.2.5, full `ShareParams` call), l.4361 (§15.3), l.4498 (§15.11, with the `win32 ^6` note) | `13.3.0` appears 0 times |
| STACK-2 | Resolved | `flutter_soloud` 4.1.7 at l.978 (§6), l.2560 (§8.16.5: `updateSamples()` / `getAudioData()`, "always requests … `format=ogg`, on iOS too", no AAC decoder), l.4361 (§15.3, `loadMem`), l.4496 (§15.11, the `meta` 1.18.0 / `native_toolchain_c` note) | `5.1.4` appears 0 times |
| STACK-3 | Resolved | l.575 (§3.1) and l.4315 (§15.2 `fonts.ts`): the four calls are character-identical and all carry `subsets: ["latin", "latin-ext"]` | Literata, Source Serif 4 and Atkinson (l.668–670) and Noto keep `preload: false` |
| STACK-4 | Resolved | §8.2 Outcomes (l.1807): the mismatch restart applies only "with no outbox `PATCH /profiles/{id}` carrying `skin` queued". §8.30.3 t = 0 row (l.2953), `500, web` / `500, app` rows. "The switch waits for the server" (l.2960) removes `mm.skin.t0` from `sessionStorage` on a failed web switch. §8.30.1 offline caption (l.2901); §15.10 S12 (l.4465) | §15.9 (l.4444) and S4 (l.4457) still agree: t0 is written before the restart, and the budget is 1.5 s. §8.2 cites stack §2.4 step 4 (the restart) and §8.30.3 cites step 2 (the comparison); both steps exist as cited |
| STACK-5 | Resolved | §2.8.4 Flutter cells 504 / 576 / 288 ms (l.543–545); "Springs on each client" (l.557–559); §4.4 Flutter column; §15.1 mapping sentence (`ms × 1.2`); S13 (l.4466) | No Flutter spring at 420 / 480 / 240 ms remains. Nit N1 |
| STACK-6 | Resolved | `--mm-spring-*-ms` 800 / 850 / 500 ms (l.543–545); stdlib generator and the `tokens.test.ts` equality test (l.560–561); §15.1 | "at least 30 points" appears 0 times; no 420 ms CSS pairing |
| STACK-7 | Resolved | §7.9 "Flutter: `CineSheetRoute`" (l.1226 onward, all seven behaviour bullets); §15.3 `primitives/` cell (l.4351); §15.3 Packages now reads "`Hero`, `SpringSimulation` and `PageRoute` (for `CineSheetRoute`, §7.9)" (round-1 nit N1 applied) | `showModalBottomSheet` appears once, in the §7.9 rationale; `DraggableScrollableSheet` 0 times |
| STACK-8 | Resolved | §8.0.3 `tonight` (l.1608) and §15.2 "Home route" (l.4336): `frontend/src/app/(app)/page.tsx`, with the two-cookie `missing` gate | No `app/page.tsx` outside a route group remains. Every `src/app/…` path is under `(app)` or `(preview)`, except `manifest.ts`, which stays at `app/` by design |
| STACK-9 | Resolved | §8.0.4 web block (l.1662–1666); §15.2 View transitions (l.4334) | `transitionTypes` appears only on `<Link>` / `router.push` |
| STACK-11 | Resolved | §8.16.10 "Native wiring and a single init" (l.2586): `AudioServiceActivity`, manifest service, receiver and permissions, one `AudioService.init` in `main()`, `audioHandlerProvider`; §15.3 "Outside the skin folder" (l.4359); S14 (l.4467) | — |
| STACK-12 | Resolved | "The restart re-reads the boot state" (l.2964–2985): builder API, `main.dart` overrides, `SkinBoot.read`, `initialLocation`; the `500, app` row calls `AppRestart.of(context).restart()`; S15 (l.4468) | `AppRestart(child:` and "logic runs again" appear 0 times |
| STACK-13 | Resolved | §2.1.5 reader-page row (l.159): `createImageBitmap(img, { resizeWidth: 16, resizeHeight: 16, resizeQuality: "medium" })`, the fallback downsample, `bitmap.close()` | — |
| STACK-14 | Resolved | §4.5 Rack focus "Where" with the cap of 12 (l.787); **Develop** row (l.788); §4.8 Develop (l.842); §15.6 (l.4409); §15.8 device pass | — |
| STACK-15 | Resolved | §9.4.2 **Formats** (l.3529) | Web soundscape Vorbis probe, else `.m4a`; `pickNovelAudioFormat` kept; app formats stated |
| STACK-16 | Resolved | §9.3.8 lead (l.3488): `now` points at "Response shapes". Member page returns `shares` (l.3491). Feed filter `kind=reading\|reaction` with the item mapping, and letters read from `GET /circle/letters` (l.3492). Response shapes (l.3497–3502); Adders (l.3503). §15.5 Circle row (l.4386) lists `GET /profiles/{id}/sharing`, the feed filters and `added_by_profile_id` with the role-based `DELETE` | `sharing: {activity`, `kind=…\|letter` and the old `now {source_id, …, since}` list all appear 0 times. The §7.25 hover line "Reading Omniscient Reader · CH 212" (l.1529) is now served by `title` and `chapter_number`. Nit N2 |
| STACK-17 | Resolved | §9.1.7 `GET /ai/recap` row (l.3225): the **No stream** JSON answer and the three stream headers | A concurrent edit added the per-`reason` state mapping. It is consistent with the fix |
| STACK-18 | **Unresolved** | §9.1.7 top-level `streak` (l.3222); `numbers` item (l.3243); §9.1.2 at-risk recompute (l.3128); §15.5 `GET /home` row (l.4378) | The clash is gone, but the field list contradicts §15.5 and drops `milestones_seen`. See below |
| STACK-19 | Resolved (by the exclusive alternative) | PRODUCT-4 stays applied: §9.4.3 client-side detection (l.3539–3540), §15.5 `pages[].panels` from client reports (l.4377), S11 (l.4464) | `panels_ready` appears 0 times. STACK-19 stays the documented fallback if the owner rejects S11 |
| STACK-20 | Resolved | §9.2.7 response by field name (l.3389 onward), `partial` (l.3407), 18+ filter on serve | Round-1 nit N3 (placement) was deliberately not applied; the block names its endpoint, so it is unambiguous |
| STACK-22 | Resolved | §8.11 (l.2109): rules stored server-side, `rules` shape, `smart = rules != null`, "Unfinished novels"; §15.5 collections `rules` row (l.4388) | — |
| STACK-23 | **Unresolved** | §8.30.3 "Separate root layouts" with *Pages move*, *Root files stay*, *404* and *Preview layout* (l.2935–2939); §8.32 404 row (l.3036); §15.2 "Outside the skin folder" (l.4330); S17 (l.4470) | Pages, Home and the 404 are settled. The preview's root layout imports no stylesheet. See below |
| STACK-24 | Resolved | §2.1.5 intro (l.133), "When `ambient` exists" (l.135), computed-by rows (l.158); §15.5 first row (l.4373) | "on every series payload" is followed by "or null until the cover has been served once" in both places |
| STACK-25 | Resolved | l.151: `<filter id="duo-<id>" color-interpolation-filters="sRGB">` | — |
| STACK-26 | Resolved | §2.1.5 Animating colour (l.178): writes scoped to the painting elements, `inherits: true` kept; §2.8.1 runtime-colours line (l.429); §15.6 (l.4412) | "compositor-friendly" appears 0 times |
| STACK-28 | Resolved | §8.0.5 iOS Back cell (l.1672) and route-transition paragraph (l.1684): the package's `Curves.fastLinearToSlowEaseIn`, no fork; §4.4 use column; §7.22 Quick look pushes `CineSheetRoute`, and its `Hero` flies into the 96 px header (l.1476) | — |
| STACK-32 | Resolved | §15.3 "Outside the skin folder" holds `mobile/assets/skin_previews/{cinematic,glass}/000–035.png` under `flutter: assets:` (l.4359); the §15.3 table has no preview row; S16 (l.4469); §15.2 `../theme.generated.css` row | — |
| STACK-33 | Resolved | §15.11: `fantasticon` 4.1.0 (l.4505), `@resvg/resvg-js` 2.6.2 (l.4506), `sox` 14.4.2 (l.4507); the resolution check has the CI `flutter build apk --release` job (l.4479); §15.3 native-plugin commit line (l.4361); §2.7 (l.330) and §12.7 name the pinned tools | "build time" is not used as a version anywhere |
| STACK-35 | Resolved | §15.2 Service worker (l.4340); §8.32 offline-fallback row (l.3039); the §8.30.3 `500, web` row posts `{ type: "skin-changed", skin }` | "chosen by the `mm-skin` cookie" appears 0 times |
| STACK-36 | Resolved | §8.2 Warm start "except a skin change" (l.1805); §12.4 `sessionStorage['mm.skin.splash']` rule (l.4093) | — |
| STACK-37 | Resolved | §7.11 "Stacking with the stop-press banner" (l.1263): outside sonner, `offset` / `mobileOffset` / `visibleToasts`; §8.33.3 (l.3069) | "member of the same stack" appears 0 times |
| STACK-39 | Resolved | Repoint path with `keep_old` and its response at l.2630, l.2662 and l.4381. `POST /ai/feedback` (l.3226, l.2620). Page-tints → 204 (l.160, l.4374). Milestones seen → 204 (l.4379). `preview_covers` / `preview_ambient_duo` (l.4389). §8.7 `seeds` and `styles` (l.1943) | Every repoint mention uses `/library/series/{followed_id}/repoint`. The nine `styles` match `01-painted` … `09-chibi` (l.1927) |

---

## Unresolved

### STACK-18: the one streak object disagrees with its own description and drops `milestones_seen`

Round 2 applied the recheck's fix. The streak object is now `{current_days, longest_days, at_risk, last_active_date}` in:

- the §9.1.7 top-level `streak` (l.3222);
- the `numbers` item (l.3243);
- the §15.5 `GET /home` row (l.4378).

The clash between `current` and `current_days` is gone. But the same §15.5 row goes on to call the object "the `GET /library/statistics` streak object plus `at_risk`". The next row (l.4379) puts `milestones_seen: [7, 30]` on that statistics object, so it has five fields and the list gives four. The file therefore defines the `/home` streak in two incompatible ways.

**Consequence.** §9.2.2 opens the milestone title card on "the first visit to Tonight **or The Numbers**" after a milestone chapter, once per profile, "stored server-side with the streak". The Numbers reads `GET /library/statistics`, which carries `milestones_seen`. A Tonight built from §9.1.7 receives no `milestones_seen`, so it cannot tell whether the 30-day card was already seen. It would either re-open the card on every visit or never open it.

**Fix.** Add `milestones_seen` to the one streak object, everywhere it is listed. It becomes `{current_days, longest_days, at_risk, last_active_date, milestones_seen}`:

- l.3222 (§9.1.7 top-level `streak`);
- l.3243 (the `numbers` item's parenthesis);
- l.4378 (§15.5 `GET /home` row).

The §15.5 phrase "the statistics streak object plus `at_risk`" is then literally true.

### STACK-23: the preview's root layout never loads the app stylesheet

Round 2 settled pages, Home and the 404 under two root layouts. It also added the sentence "`app/(app)/layout.tsx` imports `../globals.css`" (l.2937). Today's `frontend/src/app/layout.tsx` imports `./globals.css`, and that is the app's only global stylesheet. According to §15.2 (the `../theme.generated.css` row, l.4314), it brings in Tailwind and the shared `@theme inline` / `@utility` block.

In Next's App Router, a stylesheet imported by one root layout is bundled only for the routes under that layout. The *Preview layout* sub-bullet (l.2939) and §15.2 (l.4330) describe `app/(preview)/skin-preview/[skin]/layout.tsx` as rendering `<html data-skin={skin}>` with the fonts classes and no Shell. Neither place says it imports any CSS.

**Consequence.** The preview runs "the skin's real Tonight … unchanged" (l.2940), but without the utilities and tokens that Tonight is written in. The edition picker's live preview card would show an unstyled page.

**Fix.**

- **l.2939 (*Preview layout*).** After "with that skin's `fonts.ts` classes and no Shell", add: "and imports the same global stylesheet as `(app)` (`import "../../../globals.css"`), because a stylesheet imported by one root layout never reaches routes under another".
- **l.2937 (*Root files stay*).** Change "`app/(app)/layout.tsx` imports `../globals.css`" to "both root layouts import it (`../globals.css` from `(app)`, `../../../globals.css` from the preview layout)".
- **l.4330 (§15.2).** Add "both root layouts import `app/globals.css`" to the parenthesis.

---

## Non-blocking nits (no finding reopened)

- **N1 (STACK-5, pre-existing).** §2.8 (l.339) emits springs as `static const` members of `CineSprings`. §2.8.4 maps each spring to `SpringDescription.withDurationAndBounce(…)`, but in Flutter 3.44.6 that constructor is a `factory` (`spring_simulation.dart` l.70), so it cannot initialise a `const`.
  - The generator can emit the equivalent `const SpringDescription(mass: 1, stiffness: k, damping: c)`, which gives the same motion:

    | Spring | Stiffness k | Damping c |
    |---|---|---|
    | release (504 ms) | 155.42 | 24.933 |
    | sheet (576 ms) | 118.99 | 21.817 |
    | scrub (288 ms) | 475.96 | 43.633 |

  - The alternative is to declare `CineSprings` members `static final`.
  - Separately, §7.9 calls the member `CineSprings.sheet`, while §2.8.4 names the token `springSheet`. Pick one name.
- **N2 (STACK-16).** `GET /circle/members/{profile_id}` (l.3491) returns a bare `now`. Suggested: "`now` (the `GET /circle/members` shape, or `null`)".
- **N3 (STACK-16, copy).** The READING tab now reads `kind=reading`, which covers `started | finished_chapter | finished_series`. Its empty-state copy is "Nobody is reading right now." (§9.3.2), which describes live reading, not recent dispatches. This is for the product lens, if it wants the copy to match the filter.

## Old values confirmed gone (live file, 23:02:35)

| Grep | Hits |
|---|---|
| `13.3.0`, `5.1.4` | 0 |
| `DraggableScrollableSheet`, `panels_ready`, `compositor-friendly` | 0 |
| `chosen by the \`mm-skin\` cookie`, `member of the same stack` | 0 |
| `alive_today`, `streak: {current,` | 0 |
| `sharing: {activity`, `kind=reading\|reaction\|letter` | 0 |
| the old `now {source_id, series_key, chapter_key, ambient, since}` list | 0 |
| `app/page.tsx` or `app/layout.tsx` as a live path outside a route group | 0 (`app/layout.tsx` appears only as "no top-level `app/layout.tsx`") |
| `AppRestart(child:`, "logic runs again" | 0 |
| "at least 30 points", a 420 / 480 / 240 ms CSS or Flutter spring duration | 0 |
| `showModalBottomSheet` | 1, the §7.9 rationale only |
