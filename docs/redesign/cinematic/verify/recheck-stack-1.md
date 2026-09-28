# Cinematic DESIGN.md: recheck round 1, stack lens

Checked 2026-09-28 against the 31 findings in the "Confirmed" section of `cinematic/verify/judge-stack.md`, using `cinematic/verify/fixed-stack.md` as the list of what the fixer changed. DESIGN.md was not edited.

**Snapshot note.** Other lenses' fixers were still writing DESIGN.md while this recheck ran (it grew from 4,577 to 4,645 lines between 22:43 and 22:51 UTC). Every check was repeated on the last copy (mtime 22:51:43, 4,645 lines), and all line numbers below refer to that copy. None of the concurrent edits undid a stack fix. One of them removed the stale `panels_ready` gate that `fixed-stack.md` had flagged at §8.14.3.

**Method.** For each finding I read the target sections and compared them word by word with the judge's final fix. I then grepped the whole file for the old values that should be gone and for every other place the changed value appears. Two claims were checked against the installed code:

- **Motion spring settle times.** `spring(d, 0).toString()` in `frontend/node_modules/motion-dom` returns `800ms` / 27 points for 0.42, `850ms` / 28 points for 0.48 and `500ms` / 17 points for 0.24. These match §2.8.4 and the rule round(T / 30).
- **Next 16 root layouts.** `frontend/node_modules/next/dist/docs/01-app/03-api-reference/03-file-conventions/route-groups.md` l.32 says: "If you use multiple root layouts without a top-level `layout.js` file, make sure your home route (/) is defined within one of the route groups."

**Result: 26 resolved, 5 unresolved** (STACK-4, STACK-8, STACK-16, STACK-18, STACK-23). Each unresolved fix was applied as written, but it left a contradiction with another place in the file, or with another fix from this lens. The 8 refuted findings (STACK-10, 21, 27, 29, 30, 31, 34, 38) were out of scope.

---

## Verdicts

| ID | Status | Evidence (current line numbers) | Notes |
|---|---|---|---|
| STACK-1 | Resolved | `share_plus` 12.0.2 at l.1676 (§8.0.5), l.3367 (§9.2.5, full `ShareParams` call), l.4350 (§15.3), l.4486 (§15.11, with the `win32 ^6` note); also l.3002 (Backup export, same version) | `13.3.0` appears 0 times |
| STACK-2 | Resolved | `flutter_soloud` 4.1.7 at l.978 (§6), l.2559 (§8.16.5, with `updateSamples()` / `getAudioData()` and the `format=ogg` rule), l.4350 (§15.3, `loadMem`), l.4484 (§15.11, the `meta` 1.18.0 / `native_toolchain_c` note) | `5.1.4` appears 0 times. §6 l.980 still says the miniaudio context sets no category, which matches the judge's note |
| STACK-3 | Resolved | l.575 (§3.1) and l.4304 (§15.2 `fonts.ts`): all four calls carry `subsets: ["latin", "latin-ext"]` and are identical in both places | Literata, Source Serif 4 and Atkinson (l.668–670) keep `preload: false` |
| STACK-4 | **Unresolved** | §8.30.3 table t = 0 (l.2948) and `500, web` / `500, app` rows (l.2952–2953); "The switch waits for the server" (l.2955); §8.30.1 offline caption; §15.10 S12 (l.4454) | Applied as written, but §8.2 still describes an unconditional mismatch restart. See below |
| STACK-5 | Resolved | §2.8.4 Flutter cells 504 / 576 / 288 ms (l.543–545); "Springs on each client" (l.557); §4.4 Flutter column; §15.1 mapping sentence (`ms × 1.2`); S13 (l.4455) | No other Flutter spring duration remains |
| STACK-6 | Resolved | `--mm-spring-*-ms` = 800 / 850 / 500 ms (l.543–545); stdlib generator and `tokens.test.ts` equality test (l.557 block); §15.1 | Values match the installed `motion-dom` output (see Method). No "420ms" CSS pairing and no "at least 30 points" left |
| STACK-7 | Resolved | §7.9 "Flutter: `CineSheetRoute`" (l.1226 onward); §15.3 `primitives/` cell | `showModalBottomSheet` appears only in the rationale; `DraggableScrollableSheet` 0 times. `CineSprings` is a declared static-const class (l.339). Nit N1 below |
| STACK-8 | **Unresolved** | §8.0.3 `tonight` row (l.1608); §15.2 "Home route" (l.4325) | Applied as written, but it conflicts with STACK-23's route-group move. See below |
| STACK-9 | Resolved | §8.0.4 web block (l.1662 onward); §15.2 View transitions paragraph | `transitionTypes` appears only on `<Link>` / `router.push`, never on `<ViewTransition>` |
| STACK-11 | Resolved | §8.16.10 "Native wiring and a single init" (l.2585); §15.3 "Outside the skin folder"; S14 (l.4456); `audioHandlerProvider` in the `main.dart` sample (§8.30.3) | The `mm/media` channel in `MainActivity.kt` (§9.2.5) is covered by "any other `MainActivity` channel … goes into the same class" |
| STACK-12 | Resolved | "The restart re-reads the boot state" (l.2959 onward): builder API, `main.dart` overrides, `SkinBoot.read`, `initialLocation`; app row calls `AppRestart.of(context).restart()`; §15.3; S15 (l.4457) | No `AppRestart(child:` form and no "main's logic runs again" claim remain |
| STACK-13 | Resolved | §2.1.5 reader-page row (l.159): `createImageBitmap(img, { resizeWidth: 16, resizeHeight: 16, resizeQuality: "medium" })`, fallback downsample, `bitmap.close()` | — |
| STACK-14 | Resolved | §4.5 Rack focus "Where" + cap (l.787), **Develop** row (l.788); §4.8 Develop (l.842); §15.6 (l.4398); §15.8 device pass (l.4424) | — |
| STACK-15 | Resolved | §9.4.2 **Formats** (l.3523) | Web soundscape Vorbis probe, else `.m4a`; `pickNovelAudioFormat` kept; app formats given |
| STACK-16 | **Unresolved** | §9.3.8 "Response shapes" (l.3491–3496), "Adders" (l.3497); §9.3.5; §8.11 permission table (l.2115) | Applied as written, but the changed `now` shape is repeated elsewhere with the old field list, and the feed and member vocabularies disagree. See below |
| STACK-17 | Resolved | §9.1.7 `GET /ai/recap` notes (l.3220): **No stream** JSON answer and the three stream headers | — |
| STACK-18 | **Unresolved** | §9.1.7 `GET /ai/similar` envelope; "`GET /home` section items" table (l.3225 onward) | Applied as written, but the `numbers` item adds a second streak object whose field names clash with the top-level `streak` in the same response. See below |
| STACK-19 | Resolved (by the exclusive alternative) | PRODUCT-4 is applied instead: §9.4.3 client-side detection, §15.5 `pages[].panels` from client reports, §15.6, S11 (l.4453); §8.14.3 gate now reads "only once the current page has panels" (l.2192) | The judge said "apply either this or PRODUCT-4, not both". `panels_ready` appears 0 times and no server-side panel analysis remains. STACK-19 stays the documented fallback if the owner rejects S11 |
| STACK-20 | Resolved | §9.2.7 response by field name (l.3383 onward), `partial`, 18+ filter on serve | Nit N3 below. A concurrent fix added `shareable` to the same block, consistently |
| STACK-22 | Resolved | §8.11 smart-shelf bullet (l.2108); §15.5 collections `rules` row | — |
| STACK-23 | **Unresolved** | §8.30.3 web preview sub-bullets (l.2934 onward); §15.2 "Outside the skin folder" (l.4319) | Applied as written, but the route-group move leaves STACK-8's home page, and today's root files, without a root layout. See below |
| STACK-24 | Resolved | §2.1.5 intro and "When `ambient` exists" (l.135); computed-by table rows; §15.5 first row | "on every series payload" is followed by "or null until the cover has been served once" in both places |
| STACK-25 | Resolved | l.151: `<filter id="duo-<id>" color-interpolation-filters="sRGB">` | — |
| STACK-26 | Resolved | §2.1.5 Animating colour (scoped writes, `inherits: true` kept); §2.8.1 runtime-colours line; §15.6 (l.4401) | "compositor-friendly" appears 0 times |
| STACK-28 | Resolved | §8.0.5 iOS Back cell (l.1672) and the route-transition paragraph (l.1684); §4.4 use column; §7.22 Quick look (l.1476) | No "release `spring.release`" for the iOS back swipe remains |
| STACK-32 | Resolved | §15.3 "Outside the skin folder" (l.4348); the table no longer holds the `assets/skin_previews` row; S16 (l.4458); §15.2 `../theme.generated.css` row | — |
| STACK-33 | Resolved | §15.11 `fantasticon` 4.1.0 (l.4493), `@resvg/resvg-js` 2.6.2, `sox` 14.4.2; resolution check with the CI `flutter build apk --release` job (l.4467); §2.7, §12.7 and §15.3 name the pinned tools | "build time" is no longer used as a version |
| STACK-35 | Resolved | §15.2 Service worker (l.4329); §8.32 offline fallback row; §8.30.3 web row posts `{ type: "skin-changed", skin }` | "chosen by the `mm-skin` cookie" appears 0 times |
| STACK-36 | Resolved | §8.2 Warm start "except a skin change" (l.1805); §12.4 `sessionStorage['mm.skin.splash']` rule (l.4082) | — |
| STACK-37 | Resolved | §7.11 "Stacking with the stop-press banner" row (l.1263); §8.33.3 | "is a member of the same stack" appears 0 times |
| STACK-39 | Resolved | Repoint path, `keep_old` and response in §8.17, §8.18 and §15.5 (l.4370); `POST /ai/feedback` row; page-tints → 204; milestones seen → 204; `preview_covers` / `preview_ambient_duo`; §8.7 `seeds` and `styles` (l.1943) | The nine `styles` values match the step-4 file names `01-painted` … `09-chibi` |

---

## Unresolved

### STACK-4: §8.2 still restarts on any mismatch, which contradicts the outbox rule

The fix makes a queued outbox `PATCH /profiles/{id}` that carries `skin` win over the server's `profile.skin` at boot on mobile, and skips the mismatch restart while it is queued (§8.30.3 l.2955, §8.30.1, S12). The rule is repeated in one more place, and that place was not updated:

- **§8.2 Outcomes (l.1807).** "Remembered profile whose saved skin differs from the device mirror (`stack-decision.md` §2.4 step 4; only once `glass_available` is true) → the reveal is cut … then the restart". It has no exception.
- **Failure scenario.** A phone switches editions offline. The mirror is written at t = 500, and the `PATCH` sits in the outbox. On the next cold start, §8.2 sees `profile.skin` (old) differ from the mirror (new) and restarts back into the old edition. That is the defect STACK-4 fixed.

Also open, secondary: after a failed web switch, `mm.skin.t0`, written at t = 0 in `sessionStorage`, is never cleared (l.2948, l.4433). The next full page load's splash would read it and log a false `SKIN RESTART` entry, although l.2955 says no entry is logged.

**Fix.**
- In §8.2 Outcomes, after "differs from the device mirror", add: "and no outbox `PATCH /profiles/{id}` carrying `skin` is queued (a queued one wins, §8.30.3)".
- In l.2955, after "The mirror is left unchanged", add: "and `mm.skin.t0` is removed".

### STACK-8: the home page path breaks once STACK-23 moves the root into a route group

- **What the file says.** §8.0.3 `tonight` (l.1608) and §15.2 "Home route" (l.4325) put Home at `frontend/src/app/page.tsx`. STACK-23 moves today's root layout to `app/(app)/layout.tsx` and adds a second root layout under `app/(preview)/` (l.2934, l.4319). So there is no top-level `app/layout.tsx` any more.
- **What Next requires.** Next 16's route-groups doc (`route-groups.md` l.32, installed copy) requires the home route inside a route group in that case. So `app/page.tsx` would have no root layout, and `next build` would fail.

**Fix.** Change both lines to `frontend/src/app/(app)/page.tsx`. Keep the same contents and the same redirect gate.

### STACK-16: the changed `now` shape and the Circle vocabularies disagree across the file

The fix added full response shapes to §9.3.8 (l.3491–3497). Three places now contradict them:

1. **`now` is defined three ways.**
   - The new shape (l.3492): `now: {source_id, series_key, chapter_key, chapter_number, title, ambient, since} | null`.
   - The §9.3.8 lead paragraph (l.3482) and the §15.5 Circle row (l.4375) still give the old list, `now: {source_id, series_key, chapter_key, ambient, since}`.
   - The hover line "Reading Omniscient Reader · CH 212" (§9.3.2) needs `title` and `chapter_number`, so a backend built from §15.5 cannot draw it.
2. **Feed filter and item `kind` use different vocabularies.**
   - PRODUCT-3's filter (l.3486) is `GET /circle/feed?…&kind=reading|reaction|letter`.
   - The new item enum (l.3493) is `kind: "started" | "finished_chapter" | "finished_series" | "reacted"`.
   - No mapping is given, and `letter` matches no feed item, because letters come from `GET /circle/letters`.
3. **The same object has two names.**
   - The member page (l.3485) returns `sharing: {activity, reactions}`.
   - The members list (l.3492) returns `shares: {activity, reactions, shelves, recommendations}`.

Also, the judge's header says backend additions also go into §15.5. The §15.5 Circle row lists its extras item by item, but it leaves out the new `GET /profiles/{id}/sharing` and `added_by_profile_id` with its role-based `DELETE`.

**Fix.**
- In l.3482 and l.4375, replace the `now {…}` field list with "`now` (the §9.3.8 response shape)".
- In l.3486, state the mapping: `reading` = `started | finished_chapter | finished_series`, `reaction` = `reacted`. Drop `letter`, because the LETTERS tab reads `GET /circle/letters`.
- In l.3485, rename `sharing` to `shares`.
- In the §15.5 Circle row, add `GET /profiles/{id}/sharing` and `added_by_profile_id` (role-based collection `DELETE`).

### STACK-18: two streak objects with clashing field names in one `GET /home` response

The same `GET /home` response now carries two differently named streak objects, and §9.2.2 uses a third mix:

| Where | Streak fields |
|---|---|
| Top-level `streak` in §9.1.7 (l.3217) and §15.5 (l.4367) | `{current, at_risk, last_active_date}` |
| New `numbers` section item (l.3237) | `{streak: {current_days, longest_days, alive_today}, …}` |
| §9.2.2, which the `numbers` teaser renders (tiered flame, §8.8) | `streak.current_days` and `streak.last_active_date` |

- **Clashes.** `current` vs `current_days`. `alive_today` vs `at_risk` / `last_active_date`.
- **Missing data.** The flame's "Alive, not yet today" and "At risk" tiers need `last_active_date` or `at_risk`, and the `numbers` item carries neither.

**Fix.**
- Define one streak object, `{current_days, longest_days, at_risk, last_active_date}`.
- Use it for the top-level `streak` in l.3217 and l.4367.
- Make the `numbers` item `{streak, chapters_week, seconds_week}`, where `streak` is that same object. Drop `alive_today`.

### STACK-23: the route-group move leaves today's root files and Home without a root layout

The preview split (l.2934, l.4319) was applied as written. It says only that "today's root moves into a route group, `app/(app)/layout.tsx` (URLs unchanged)". With no top-level layout, Next needs more than that:

- **Pages.** Every page must sit under a root layout. Today's `frontend/src/app/` has `admin/`, `downloads/`, `library/`, `login/`, `more/`, `novels/`, `ocr/`, `profiles/`, `read-all/`, `reader/`, `register/`, `search/`, `settings/`, `sources/` and `updates/` next to `layout.tsx`. The contract never says they move into `(app)/`, and Home must be inside a group (STACK-8).
- **404.** The root `not-found.tsx` no longer composes a global 404 inside a shared layout. Next's `not-found.md` (installed copy, l.55) names multiple root layouts as the case for `experimental.globalNotFound` + `app/global-not-found.tsx`, which bypasses layouts. §8.32 wants the 404 "inside the frame".

**Fix.** Extend the "Separate root layouts" sub-bullet and the §15.2 line with the following.

- **Pages move.** Every existing route folder, together with `error.tsx` and `not-found.tsx`, moves under `app/(app)/` (URLs unchanged). Home is `app/(app)/page.tsx`.
- **Root files stay.** `global-error.tsx`, `manifest.ts`, `globals.css` and the generated CSS stay at `app/`. `providers.tsx` is only imported, so it can stay where it is.
- **404.** Unmatched URLs reach the in-frame 404 through `app/(app)/[...missing]/page.tsx` calling `notFound()`. Record the multiple-root-layout 404 handling in §15.10 with S16's siblings.

---

## Non-blocking nits (no finding reopened)

- **N1 (STACK-7).** §15.3 Packages (l.4350) still says "Cinematic uses the built-in `Hero`, `SpringSimulation` and sheets". Sheets are now the custom `CineSheetRoute` on `PageRoute`. Suggested: "the built-in `Hero`, `SpringSimulation` and `PageRoute` (for `CineSheetRoute`)".
- **N2 (STACK-18).** §8.7 l.1945 says `GET /ai/similar?anilist_id` "returns 3 WorldItems". Since STACK-18 they arrive in `items` of the envelope. Suggested: "returns the §9.1.7 envelope with 3 `items`".
- **N3 (STACK-20).** The `GET /library/annual` response block (l.3383) is introduced at the end of the `POST /novels/listen-sessions` paragraph ("The response, by field name"). It names its endpoint, so it is unambiguous, but it would read better as its own paragraph directly after the first §9.2.7 paragraph.

## Old values confirmed gone

| Grep | Hits |
|---|---|
| `13.3.0`, `5.1.4` | 0 |
| `transitionTypes` on `<ViewTransition>` | 0 |
| `compositor-friendly` | 0 |
| `DraggableScrollableSheet` | 0 |
| `panels_ready` | 0 |
| `chosen by the \`mm-skin\` cookie` | 0 |
| `member of the same stack` | 0 |
| "release `spring.release`" for the iOS back swipe | 0 |
| a 420 / 480 / 240 ms CSS spring duration | 0 |
| a Flutter spring at 420 / 480 / 240 ms | 0 |
| `showModalBottomSheet` | 1, the §7.9 rationale only |
