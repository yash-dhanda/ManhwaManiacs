# Review: web track, slice 1 (web/00 to web/11)

Reviewed 2026-09-29. I checked the slice against these sources:

- `prompts-plan.json` (binding)
- `inventory/00-decisions.md`, `stack-decision.md`, `stack-keep.md` §6, `00-baseline.md`, `inventory/{web,capabilities}.md`
- `cinematic/DESIGN.md` and `glass/DESIGN.md`
- the neighbouring prompts that produce what this slice consumes or consume what it produces: `shared/00`–`04`, `backend/00`, `backend/02`, `mobile/10`, `mobile/11`, `web/12`–`web/25`, `release/00`
- the checkout itself: `frontend/package.json` scripts, `frontend/src/app/**`, `features/offline`, `lib/keyboard`, and next 16.2.9's `font-data.json`

Every fix was made in place in the prompt file named below. Nothing outside `docs/redesign/` was touched. All twelve files exist, so none was created.

## Files in the slice

| File | Exists | Order / deps match plan | Rules (goal, read first, scope, skills, layout, acceptance, verification, RAM guard, git, report back, next file) | Result |
|---|---|---|---|---|
| `web/00-foundation-skin-engine-and-routes.md` | yes | 4 / `shared/00`, `backend/00` | all present | fixed: mobile/backend check added, plan path |
| `web/01-foundation-motion-deps-fonts-icons.md` | yes | 7 / `web/00`, `shared/02` | all present | fixed: duplicate icon generator removed (finding 1), mobile/backend check, plan path |
| `web/02-foundation-restart-haptics-sound.md` | yes | 10 / `web/01`, `shared/01`, `shared/03` | all present | fixed: debug-row GLASS owner, mobile/backend check, plan path |
| `web/03-foundation-reader-seam-limiter-proof.md` | yes | 12 / `web/00`, `backend/00` | all present. It says the design skills are not needed because no pixels change, which is acceptable. | fixed: `verify:reader` wording, mobile/backend check, plan path |
| `web/04-cinematic-primitives-core-and-reveals.md` | yes | 17 / `web/02`, `web/03` | all present | fixed: preconditions (shared checkout, shared/04 covers), mobile/backend check, plan path |
| `web/05-cinematic-primitives-overlays-controls-states.md` | yes | 20 / `web/04` | all present | fixed: shared-checkout precondition, mobile/backend check, plan path |
| `web/06-cinematic-shell-navigation-transitions.md` | yes | 23 / `web/05`, `shared/04` | all present | fixed: offline page conflict, brand hand-off, precondition, mobile/backend check, plan path |
| `web/07-cinematic-auth-profiles-18plus.md` | yes | 26 / `web/06`, `backend/00` | all present | fixed: shared-checkout precondition, mobile/backend check, plan path |
| `web/08-cinematic-tonight.md` | yes | 29 / `web/07`, `backend/04`, `backend/01` | all present | fixed: reader entry, prefetch, Lenis, scrub recorder, proof command |
| `web/09-cinematic-library-shelf-browse.md` | yes | 32 / `web/08`, `backend/02` | all present | fixed: offline edition source, proof command |
| `web/10-cinematic-updates-collections-history-bookmarks.md` | yes | 35 / `web/09` | all present | fixed: backend section conflicting with backend/02 removed, proof command |
| `web/11-cinematic-feature-and-book-pages.md` | yes | 38 / `web/10`, `backend/02` | all present | fixed: reader entry and prefetch, mobile/11 coordination, proof command |

**Automated checks over the slice**

- No file contains "TBD", "etc." or "as appropriate".
- Every file names `superpowers:writing-plans`, `subagent-driven-development` or `executing-plans`, `impeccable`, `taste-skill:taste-skill`, `frontend-design` and `verification-before-completion`.
- Every file has the `free -m` guard with the 1024 MB stop, `npm run lint` and `npm run build` in `frontend/`, captures at 1440 × 900 and 390 × 844 under `docs/redesign/proof/web-NN/`, the no-attribution git rule, the `backend/connectors/` ban, a Report back section and the next prompt file.
- Every "next in the global order" line matches the plan order: web/00 → mobile/00, web/01 → mobile/01, web/02 → mobile/02, web/03 → mobile/03.

**Values checked against the contracts and the checkout**

- **Hex values:** every hex value in the slice exists in `cinematic/DESIGN.md` or `glass/DESIGN.md`. The only exception is `#F5F5F5`, the deliberately skin-neutral text colour of web/00's pending screen.
- **Motion and grid values:** the ones spot-checked match: §4.5 durations and curves, §7.x component values, §8.8 and §12.4 timelines, the §9.2.2 flame, §10.1 and §10.2, and the §8.0.4 transitions.
- **Haptics:** web/02's patterns match cinematic §5 (five web events) and glass §5.2 (seven Android-web events).
- **FNV-1a vectors:** I recomputed all of web/03's vectors in Node and each one is correct: `811c9dc5`, `e40c292c`, `bf9cf968`, `cover-050c5d1f`, `cover-a07012e1`, `cover-a34e56be`, `cover-7f4c64fd`.
- **Fonts:** every family and axis that web/01 names exists in next 16.2.9's `font-data.json`, including Google Sans Flex with `GRAD`, `ROND` and `opsz`.
- **Route table:** web/00's route table covers all 27 of today's `page.tsx` files, with the folder renames it names.
- **framer-motion:** it is imported in 4 files on 7 lines, as web/01 says.
- **Re-estimate budget:** web/10's figures follow from `stack-keep.md` §6. Web is 4.0 + 3.5 + 0.6 = 8.1 CCD and Flutter is 7.1 CCD, so the pair is 15.2 CCD. With the 40 % margin the thresholds are 11.34, 9.94 and 21.28.

## Findings and fixes

### 1. `web/01`: a second icon-role generator duplicated shared/02's output

Item 12 told the session to write `frontend/scripts/icon-roles.mjs`, which would generate `icon-roles.generated.ts` for both skins from `design/icons.json`. But `shared/02` (order 6) already generates `frontend/src/skins/{cinematic,glass}/icons/roles.generated.ts` from the same file:

- `ICON_ROLES`: each role maps to `{kind, name, component}`
- `type IconRole`
- `ICON_RULES`: the weight rules, sizes, hit sizes and `glyphFallback`

It also generates `icons/glyphs.generated.tsx` (`GLYPHS`, `Strata` with `level`). Two generators for one role map would drift apart.

**Fix:** item 12 now uses shared/02's files and adds only a hand-written `icons/phosphor.ts` per skin. It holds static named imports from `@phosphor-icons/react/ssr` for exactly the `component` names in `ICON_ROLES`. It never uses `import *` or computed access, which would defeat `optimizePackageImports`. A test fails when a role has no import. Other changes:

- The two `Icon` components take `IconRole` from `./icons/roles.generated`.
- Glass `Icon` gains `level` for `Strata`, and maps glyph `light` and `bold` through `glyphFallback`.
- The file layout, acceptance criteria, verification (`icon-roles.mjs --check` removed), preconditions and commit list are updated to match.

### 2. `web/10`: a backend "exception" contradicted backend/02's collection-order contract

Section A told the session to add `PUT /library/collections/{id}/series/order` and `created_at` "if absent", with its own rules: a partial list, and `422 invalid_order`. `backend/02` items C.3 and C.4 (plan order 19) already own both, with the opposite exact-set rule: the body must equal the visible membership, otherwise `422 order_mismatch`, and gated members keep their order after the visible ones. web/10 always runs after backend/02, because web/09 checks that it landed. So the fallback could never run, yet it wrote a second, conflicting rule and broke the track rule "work in frontend/ only". `mobile/10` already treats the call as a backend/02 precondition.

**Fix:**

- Section A is now "Backend contract (read only; backend/02 owns it)". It states the exact-set contract and checks that both lines exist, stopping if they do not.
- `useReorderCollectionMembers` sends every visible member, and on `order_mismatch` it refetches before the failure toast.
- The backend file-layout line, pytest step, backend commit, backend staging and report item are removed. Guardrails now forbid `backend/` changes.

### 3. `web/06`: it rewrote web/02's Cinematic offline page with different values

web/02 item 11 builds `offline-fallback-cinematic.html` with exact values: the badge in `proof` `#FF5B4A` or `set` `#57D68D`, a Bodoni-first italic headline stack, and bone buttons. web/06 item 11 then told the session to "rewrite the body" with a `#7A7770` box badge and a system-serif headline. The plan assigns the page to both steps. The two sets of instructions conflicted, and the second session would have silently overwritten the first.

**Fix:** web/06 now treats web/02 as the owner. It checks the page against the §8.32 "Offline fallback page" row, changes it only if a line of that row is missing (keeping web/02's values), and reports any change. The file layout and acceptance criteria say the same.

### 4. `web/06`: it ignored shared/04's brand hand-off and used a wrong icon path

shared/04 generates `frontend/src/skins/cinematic/mark.generated.ts` (`MM_MARK` paths) and `frontend/src/skins/brand.generated.ts` (`SKIN_FAVICONS`, `APPLE_TOUCH_ICON = "/icons/apple-touch-icon.png"`, `APPLE_STARTUP_IMAGES`), and says "Web/06 wires these". web/06 instead:

- had `Monogram.tsx` copy paths from the SVG master by hand;
- set `apple: "/apple-touch-icon.png"`, a file that does not exist at that path;
- never wired the four black iOS startup images of §8.0.5 and §12.3.

**Fix:**

- `Monogram.tsx` draws `MM_MARK`, with the intersection as a `<mask>` so its fill can animate.
- `generateMetadata` imports `SKIN_FAVICONS.cinematic`, `APPLE_TOUCH_ICON` and `APPLE_STARTUP_IMAGES`, and sets `appleWebApp` to title "Maniacs" (the §12.3 home-screen label) with today's `black-translucent` status bar. `favicon.ico` stays at `app/`.
- The preconditions check both generated files.

### 5. `web/08`–`web/11`: proof commands captured the legacy skin

The example commands (`node scripts/proof.mjs --step web-08 --routes / --grid` and the like) had no `--skin cinematic`. Before the flip, proof.mjs sets no cookie without that flag, so they would have screenshotted legacy. They also said "if its flags differ, use its equivalents" (web/03 fixes the flags exactly), and they demanded file names (`tonight-1440x900.png`) that contradict proof.mjs's fixed naming (`cinematic-home-1440x900.png`, `-grid`).

**Fix:** each file now gives the exact command with `--skin cinematic`, names what it writes, and assigns every other named shot to the step's e2e spec (`page.screenshot`). The hedge is gone.

### 6. `web/08`: hedges that would fork web/06's shared helpers

- **Reader entry:** "if there is no single exported function… add `enterReader(router, href, entry)` to `navigation.ts`". web/06 defines `enterReader(href, { entry, prefetch })` and `useReaderPrefetch()` and re-exports both from `motion.ts`. **Fix:** use them, and stop if they are missing. The `navigation.ts` layout line is removed.
- **Prefetch priority:** "prefetch as P3 … and on press". web/06 and §15.6 make a press P1. **Fix:** P3 after the 150 ms dwell, P1 on press.
- **Lenis:** "mount `new Lenis({…})` in `TonightScreen`… if web/06 provides a wrapper, use it". **Fix:** always web/06's `useSmoothWheel()`. The options web/08 listed are Lenis 1.3.26's defaults, and a second instance is forbidden.
- **Trailer scrub:** "logs … through `play("trailerScrub")`". That is a hand-typed name (web/04 requires the generated `CineMotionName` members) on the timed path. **Fix:** web/02's `startGesture(<Trailer scrub member>)`, because scroll-linked moves log frames and drops per gesture (§15.9).

### 7. `web/09`: the offline edition read a store the web does not have

The offline Library joined "the offline follow cache `manhwamaniacs:followed-series`" with the download index. That cache exists only in the app. web/07 and `capabilities.md` say so, and `grep` finds no such key in `frontend/src`.

**Fix:** the offline edition now comes from the service-worker download index (`useOfflineState()`, whose records carry `sourceId`, `seriesKey`, `seriesTitle` and the cover, with mature records already dropped by web/07's worker), joined with the followed rows still in React Query memory, through `filterMature()`. It also says explicitly not to add a web follow cache.

### 8. Shared-checkout checks that fail falsely

**The branch-diff check.** `web/04`–`web/07` confirmed "mobile and backend untouched" with `git diff --stat origin/feat/vps-slim-source-native...HEAD -- mobile backend`. Every web step runs in parallel with its `mobile/NN` twin on the same branch, so that diff is routinely non-empty. The check fails falsely, or tempts a 4-minute `flutter test` for nothing. This is the same defect review-web-3 finding 7 fixed in its slice.

**Fix:** all four now judge by their own commits (`git show --stat --format= <hash>`) and run `flutter analyze`, `flutter test` and the backend pytest, one at a time after the RAM guard, only if one of their commits touched `mobile/` or `backend/`. `web/00`–`web/03` had no mobile/backend statement at all, and now carry the same paragraph.

**The clean-tree precondition.** `web/04`–`web/07` also required `git status --short` to be clean. In the shared checkout that fails whenever a parallel session has work in progress. They now use web/00's wording: clean inside `frontend/`, and never stage other sessions' files.

### 9. `web/02`: the wrong step named for adding `GLASS` to the debug row

web/02 said "web/25 adds `"glass"` when Glass work starts". But `release/00` Decision 1 converts the row to `CINEMATIC │ GLASS` when it deletes `legacy`, and `web/25`'s precondition expects that state.

**Fix:** web/02 now names release/00, and says web/25 does not edit the list.

### 10. `web/03`: `verify:reader` described inaccurately

It said the script "points at the e2e suite". In fact `scripts/verify-reader.mjs` is a stub that prints that it is superseded by `npm run test:e2e` and exits 0. **Fix:** the text says so, leaves the stub alone, and names `test:e2e` as the real reader check.

### 11. `web/04`: an unchecked dependency on shared/04

The gallery copies the procedural demo covers from `brand/demo/covers/` (shared/04, plan order 15), but the preconditions checked only web/01–web/03. **Fix:** added `ls brand/demo/covers/*.webp`, with the stop message.

### 12. `web/11`: the `mature_override: null` backend fix is kept, with its coordination stated

No backend step owns clearing the override, and today the service ignores `null`. web/11 and mobile/11 both carry the same guarded fix. mobile/11 waits until web/11's `web-11:` proof commit is in the log, but web/11 did not know it was the designated owner. **Fix:** web/11 says so. The section otherwise stays, because it is the only place the fix exists. See "For the reviewers of neighbouring slices".

### 13. Plan file location unified

`web/00`–`web/07` saved plans at `docs/redesign/plans/web-NN.md`. `web/08`–`web/45` and the whole mobile track use `docs/redesign/proof/<step>/plan.md`. **Fix:** `web/00`–`web/07` now use `docs/redesign/proof/web-NN/plan.md`: the plan lines, file layouts, `git add` lines and guardrails. No other prompt referenced the old paths.

## Coverage against the plan scopes

Every element the plan assigns to the slice is listed item by item in its file:

- **web/00:** skin types and registry; `getSkin()` with the debug cookie first and `glass` → `cinematic` while `glass_available` is false; the legacy map; `PENDING` maps onto one skin-neutral screen; the two root layouts; the `[...missing]` 404; the thin route file for every ScreenId (`setup` a redirect); server-side `data-skin`; `viewTransition`; the two-cookie `/` redirect; the lint boundary; the completeness test with the `MUST_BE_COMPLETE` release gates for web/24 and web/45.
- **web/01:** the Motion 13.4.4 swap and the eight pins; `optimizePackageImports`; the `npm ls` gate; the spring parity for both skins (S13, G1); every font of cinematic §3.1 and §3.4 and glass §3.1 with the CJK fallbacks; the network isolation check; the `Icon` components.
- **web/02:** `switchSkin` (the 1,000 ms await, the undo on failure); the cookie and session keys; the SW `skin` and `skin-changed` messages; `mm-sw-meta`; both offline pages; boot resolution steps 1–5; the debug row with its 200 ms fade; the five `mm.boot.a11y` attributes before paint; 5 + 7 web haptics; both sound layers; the 200-entry recorder and `SKIN RESTART`.
- **web/03:** the reader engine (A1–A7, including the auto-queue); the §15.6 limiter; `coverTransitionName`; `proof.mjs` with grid, reduced-motion and DPR 3 options.
- **web/04:** §7.1–7.8, §7.17–7.19, §7.25–7.28, both signature animations with their Playwright checks, `play()`, `motion.css`, grain, duotone, the 1,440-case tint test, the gallery.
- **web/05:** §7.9–7.12, §7.16, §7.20–7.24 (mark and shell), §7.29, §7.30, the 1,000 ms arm.
- **web/06:** frames and guards; the sidebar, running head and thumb index; `ViewTransition` types; Dip, Column wipe and Iris; global keys and the `g` sequence; the palette and keyboard sheet; §8.32; §8.0.10; content mode; stop-press, first-run note and rating-card host; Press start; timings overlay; Lenis.
- **web/07:** L1–L9, RG1–RG5 (plus the nine form elements), P1–P8, PF1–PF8, PM1–PM8, the 18+ gate end to end, `mature-filter.ts` with the worker gate, the §15.7 checklist.
- **web/08:** §8.8, §9.1.1, §9.1.2, `useHomeFeed()`, every state.
- **web/09:** LS1–LS12, LB1–LB26, BA1–BA10, NS1–NS6, the hub frame, `featureByFollow`.
- **web/10:** UP1–UP8, CO1–CO10, CD1–CD12, RH1–RH5, BM1–BM5, the re-estimate gate.
- **web/11:** SD1–SD21, SS1–SS18, NB1–NB19, DP1–DP7.

### Cinematic `PENDING` exits in the slice (15 of the 35 ScreenIds; `setup` is never in `PENDING`)

| Step | ScreenIds |
|---|---|
| web/07 | `login`, `register`, `profiles`, `profileNew`, `profileEdit`, `profilesManage` |
| web/08 | `tonight` |
| web/09 | `library`, `featureByFollow` |
| web/10 | `updates`, `collections`, `collection`, `history`, `bookmarks` |
| web/11 | `feature` |

The other 19 belong to the next slices by plan: `reader`, `readAll`, `readerLanding` (web/12–13), `novel` (14), `discover`, `sources`, `source`, `dialogue` (16), `downloads`, `index`, `status` (17), `settings` (18), `picks`, `recap` (19), `onboarding` (20), `numbers`, `annual` (21), `circle`, `circleMember` (22). None is assigned twice.

### Assigned twice, reconciled (now stated on both sides)

- **The Cinematic offline page:** web/02 builds it, web/06 checks it (finding 3).
- **`FeatureView.tsx`:** web/09 creates it with the pending body, web/11 replaces the body and keeps the props.
- **The `Continue reading` rows:** web/08's `continue-hidden.ts` is reused by web/09.
- **Quick-look actions:** built in `parts/quick-look-actions.ts` by web/08, reused by web/09 and web/11.
- **`mark-read.ts`:** web/09 creates it, web/11 extends it.
- **`streak.ts` and `StreakFlame`:** web/08 builds them, web/21 adds the milestone cards.
- **`SetHeading`:** web/04 builds it; web/06 adds `startDelay` and web/08 adds `roman`.
- **`OxfordRule`:** web/04 builds it, web/06 adds `spotLead`.

### Plan-scope notes (not changed, recorded)

- **"The Coming up band" in the web/08 plan scope.** §8.8 has no such element. The Coming up card is §8.14.6, the reader's chapter end, which the plan gives to web/12 ("chapter-end credits and the next-chapter card"). The over-art row "the Coming up band at 0.84" belongs to the reader too. It was not added to web/08, and web/12's reviewer should confirm web/12 builds it.
- **`design/make-grain.mjs` (web/04) sits outside `frontend/`.** The plan scope names it explicitly, and no shared prompt writes it, so it stays with web/04.
- **web/07 marks a profile `NEW` in the picker when `onboarding_step` is not `"done"`.** §8.5 says "a profile with no sessions", and `GET /profiles` carries no session count. This is a reasonable proxy, and no contract field would serve better.

## For the reviewers of neighbouring slices (not edited here)

- **`web/20`, `web/21`, `web/22`, `web/23`:** each gives a `proof.mjs` example without `--skin cinematic` and says "if its flags differ". Before the flip, these capture the legacy skin (finding 5).
- **`web/18`:** its plan scope lists "the debug-only diagnostics row", but web/02 builds that row (`features/skin/DebugEditionPage.tsx`, served at `/settings/diagnostics?debug=1` for every skin). web/18 should reuse it inside Cinematic Settings → Diagnostics, not build a second one.
- **`web/19`:** its scope includes "Because you read on Tonight", but web/08 already renders those rails from `GET /home` (section `because`, the Roman seed title). web/19 should add only its own part (in-session re-ranking, More like this) and not rebuild the rails.
- **`web/29` (Glass shell):** it should take `SKIN_FAVICONS.glass` and `APPLE_STARTUP_IMAGES` from `brand.generated.ts`, the way web/06 now does.
- **Backend track:** clearing `mature_override` with an explicit `null` still has no backend owner. web/11 section A makes the change, and mobile/11 defers to it. If a backend step is reopened, the one-line service fix and its test belong in `backend/02` next to `repoint` and `manual`.
- **Plan paths:** the web track now saves every plan at `docs/redesign/proof/web-NN/plan.md`. The mobile track uses `docs/redesign/plans/` in four files.
