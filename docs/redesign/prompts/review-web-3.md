# Review: web track, slice 3 (web/24 to web/35)

Reviewed 2026-09-29 against `prompts-plan.json` (binding), `inventory/00-decisions.md`, `stack-decision.md`, `00-baseline.md`, `inventory/{web,capabilities}.md`, `cinematic/DESIGN.md` and `glass/DESIGN.md`. Every fix below was made in place in the prompt file named. Nothing outside `docs/redesign/` was touched.

## Files in the slice

| File | Exists | Order / deps match plan | Rules (goal, read first, skills, layout, acceptance, verification, RAM guard, git, report back, next file) | Result |
|---|---|---|---|---|
| `web/24-cinematic-qa-polish.md` | yes | 65 / `web/23` | all present | fixed (verification check) |
| `web/25-glass-foundation-material-physics.md` | yes | 68 / `release/00`, `shared/05` | all present | fixed (tier snap, verification check) |
| `web/26-glass-primitives-controls-and-reveals.md` | yes | 70 / `web/25` | all present | fixed (§7.40 cursors added, verification check) |
| `web/27-glass-primitives-overlays.md` | yes | 72 / `web/26` | all present | fixed (detail window, overlay queue, dependency source, cursors, verification check) |
| `web/28-glass-primitives-lists-states-ai-charts.md` | yes | 74 / `web/27` | all present | fixed (cursor on reorder handle) |
| `web/29-glass-shell-navigation-depth.md` | yes | 76 / `web/28`, `shared/05` | all present | fixed (§15.8 web gate added, recede rule ownership) |
| `web/30-glass-auth-profiles-onboarding.md` | yes | 78 / `web/29`, `backend/05` | all present | no change needed |
| `web/31-glass-home.md` | yes | 80 / `web/30` | all present | fixed (hand-off to `web/41` and `web/43`, cursor) |
| `web/32-glass-library-hub-downloads.md` | yes | 82 / `web/31` | all present | fixed (verification check) |
| `web/33-glass-series-and-book.md` | yes | 84 / `web/32` | all present | fixed (verification check) |
| `web/34-reader-engine-glass-commands.md` | yes | 86 / `web/33` | all present (design skills named as not needed: no pixels change) | fixed (sign-off precondition, verification check) |
| `web/35-glass-manga-reader.md` | yes | 88 / `web/34` | all present | fixed (cursors, verification check) |

No file was missing, so none was created. Automated checks over the slice: no "TBD", "etc." or "as appropriate"; every file names `superpowers:writing-plans`, `subagent-driven-development` or `executing-plans`, `impeccable`, `taste-skill:taste-skill`, `frontend-design`, `verification-before-completion`; every file has the `free -m` guard with the 1024 MB stop, `npm run lint` and `npm run build`, 1440 × 900 and 390 × 844 captures under `docs/redesign/proof/web-NN/`, the no-attribution git rule and the `backend/connectors/` ban. Every hex value in the Glass prompts exists in `glass/DESIGN.md` (the only strays are test vectors in `web/34`), every hex in `web/24` exists in `cinematic/DESIGN.md`, and every spring `k, c` pair in `web/25`–`web/35` matches the §4.2 table. Every named move handed to `play()` is a §4.10 row name.

## Findings and fixes

### 1. `web/25`: T5 reached by size (contradicts the contract)

`tierFor` mapped `> 400 → "t5"` with `glass.snap [36, 57, 97, 401]` and the physics test asserted `tierFor(401) == "t5"`. `glass/DESIGN.md` §2.4.3 says a free-sized object snaps `≥ 97 → T4` and "T5 is never reached by size"; §2.8.4 gives `glass.snap = [36, 57, 97]`; §15.8 asserts `tierFor(401) == T4`.
**Fix:** item C now maps `≥ 97 → "t4"` with the §2.8.4 snap and states that T5 is only declared (`tier="t5"`) by the Massive objects; item M and the acceptance criterion assert `tierFor(401) == "t4"`.

### 2. `web/27`: the 960 px detail window drawn as live glass over `dimSheet`

Item B12 built `detailWindow` like the other windows (glass, `dimSheet` behind) and gave the 560 px window `tier="auto"` (T4 or T5 by size). §7.10 makes the series and book window the exception: a content-layer `materialThick` slab (`rgba(19,19,23,0.84)`, blur 36, radius 32, no live glass, alpha labels, bare state glyphs) over a page that recedes to scale 0.97, blur 8 and 50 % brightness by presentation progress; every other panel and window is T4 at every size with `dimSheet` and no scale or blur; the only T5 window is the listen player's. `web/29` and `web/33` already specified the exception, so `web/27` contradicted them.
**Fix:** B12 now builds `detailWindow` as the `materialThick` slab outside the glass budget (`solid2` under Solid glass), adds the `.glass-recede-window` rule driven by `--sheet-progress`, keeps `dimSheet` for panels, windows and the `offer` popover only, and makes the 560 px window T4 (`material="monolith"` for the listen player). The acceptance criterion says the same. `web/29` E3 now uses the rule `web/27` adds instead of adding it again.

### 3. `web/27`: the overlay queue let capsules show over menus

Item A held only toasts while a menu was open. §7.12 holds every top-band item (toast, new-chapters capsule, app-update capsule) while a menu or context menu is open, and an item already showing leaves on `dismiss` (its timer paused) and falls back in on `snappy` when the menu closes; the Offline and Syncing capsules are not in the queue.
**Fix:** item A, the `overlay-queue.test.ts` description and the notices acceptance criterion now carry all three rules.

### 4. `web/27`: dependency attributed to the wrong source

`@use-gesture/react` 10.3.1 was cited as `stack-decision.md` §3; it is in `glass/DESIGN.md` §15.11 as "reused" (installed by `web/01`). **Fix:** the read-first line points at §15.11 and says to add nothing.

### 5. §7.40 pointer cursors were assigned to no step

`web/26` listed §7.40 in its read-first list but no step in the Glass track delivered a cursor (Tailwind 4's preflight resets buttons to `cursor: default`, so without it every Glass button shows the arrow).
**Fix:** `web/26` gains item T, one `glass.css` contract (`pointer`, `not-allowed`, `text`, and a `data-cursor` attribute for `grab`/`grabbing`, `ns-resize`, `zoom-in`, `zoom-out`, `none`, `all-scroll`), a gallery section, a spec assertion and an acceptance line; `web/27` (slider, switch and fill-slider thumbs, speed dial, scrub rail, image viewer), `web/28` (reorder handle), `web/31` (spotlight card) and `web/35` (strip `none` after 3,000 ms still with hidden chrome, middle-click `all-scroll`) each opt in. `web/36` (novel column `text`) and `web/37` (voice orbit `grab`) are named in item T for their reviewers.

### 6. The §15.8 web gate ran only at the end of the track

§15.8 puts the Glass web gate in the foundation week, beside the Flutter device gate, because its result decides a renderer rule (tier A only at rest while a bar group scrolls). The slice never ran it; only `web/45` did, after every screen exists.
**Fix:** `web/29` (the first step where the nav row group, the dock group and the accessory exist) builds a gate scene (`/dev/glass-shell?gate=1`, a 240-poster grid under the phone chrome) and `frontend/scripts/glass-web-gate.mjs` (Playwright + CDP `Input.synthesizeScrollGesture` for 10 s with a timeline trace, pass: mean frame rate within 5 % of refresh and at most 2 dropped frames per second), runs it once headless as a software-raster record, and hands the owner the exact desktop and Android commands. The decision on a failing owner run stays with `web/45`, which already carries the gate.

### 7. Eight files judged "mobile and backend unchanged" by the branch diff

`web/24`, `25`, `26`, `27`, `32`, `33`, `34` and `35` told the session to confirm `git diff --stat origin/feat/vps-slim-source-native -- mobile backend` is empty, and `32`–`35` then ran the full Flutter suite when it was not. Every web step runs in parallel with its `mobile/NN` twin on the same branch, so that diff is routinely non-empty with other sessions' work: the check either fails falsely or triggers a 4-minute `flutter test` (baseline: available memory down to 3,443 MB) on the shared box for nothing. `web/28`–`web/31` already used the correct per-commit check.
**Fix:** all eight now check each of their own commits with `git show --stat --format= <hash>` and run `flutter analyze`, `flutter test` and the backend pytest only if one of their commits touched `mobile/` or `backend/`, one at a time after the RAM guard (the same wording as `web/28`).

### 8. `web/31`: two stand-ins without their hand-off

`web/31` builds `continue-with-recap.ts` and `primitives/FriendOrbTargets.tsx`; `web/41` later replaces the first with `parts/recap/useContinue.ts` and `web/43` moves the second to the Shell-mounted `parts/recommend/RecommendOrbs.tsx`. The later steps say so, but `web/31` did not, so a session could inline the recap rule or couple the orbs to Home.
**Fix:** D11 and E now state that both are stand-ins with a fixed call shape, name the replacing files and ask to keep them free of Home coupling.

### 9. `web/34`: the sign-off precondition could pass on one id

`grep -n "G6\|G14\|S1\|S11"` succeeds when any one id is present. **Fix:** the text now requires all four in the output and names who writes them (`web/12` or `mobile/12` for S1 and S11, `backend/06` for G6 and G14).

## Coverage against the plan scopes

Every element the plan assigns to the slice is listed item by item in its file: `web/24` (strict completeness, §14, every §15.7 check, §4.8 and §14.1, §15.6, the motion-timings pass, every ScreenId at three sizes with and without the grid, Front pages and `og.png`, the signature checks); `web/25` (tiers, finishes, renderers A/B/C, `liquid-map.ts`, caustic, light angle, `useLb`, ambient field, rain, physics with every §15.8 value, `play()`, the six-surface counter, calibration page, document defaults); `web/26`–`web/28` (§7.1–§7.9, §7.10–§7.13, §7.17–§7.39 as the plan splits them, both signature animations with the §15.8 checks, `copy/errors.ts`, the 18+ gate alert, `ReactionPicker`); `web/29` (frames, sidebar, dock, sheet host, palette, depth, transitions, keys, §8.0.8 purge, §8.0.9, §8.0.10, §8.28, §8.29, the Droplet splash, §6 audio session, budget); `web/30`–`web/33` and `web/35` (every inventory row range: L1–L9, RG1–RG5, P1–P8, PF1–PF8, PM1–PM8, LS, LB, BA, CO, CD, RH, BM, UP, DL, SD, SS, NB, DP, RD1–RD42); `web/34` (§15.4 steps 1, 3, 4 and 5 with the 120-page, 2,880 px check).

Glass `PENDING` exits across the whole track (checked against the §8.0.3 table, 35 ScreenIds; `setup` is never in `PENDING`, `web/00` made it a server redirect): `web/30` login, register, profiles, profileNew, profileEdit, profilesManage, onboarding · `web/31` tonight · `web/32` library, collections, collection, history, bookmarks, updates, downloads · `web/33` feature, featureByFollow · `web/35` reader, readAll, readerLanding · `web/36` novel · `web/38` discover, sources, source, dialogue · `web/39` settings · `web/40` index, status · `web/41` picks, recap · `web/42` numbers, annual · `web/43` circle, circleMember. No ScreenId is left unassigned and none is assigned twice.

Assigned twice with explicit reconciliation (acceptable, now stated on both sides): the Continue-with-recap path (`web/31` → `web/41`), the friend-orb drop (`web/31` → `web/43`), the `.glass-recede-window` rule (`web/27`, used by `web/29`), the `detailWindow` material (`web/27`; `web/33` extends `Sheet.tsx` only if the option is missing).

## For the reviewers of neighbouring slices (not edited here)

- `shared/01-glass-tokens-haptics-motion-names-contrast.md` line 14 generates the snap `[36, 57, 97, 401]`; `glass/DESIGN.md` §2.8.4 says `[36, 57, 97]` and T5 is never reached by size.
- `web/45-glass-qa-polish.md` asserts `tierFor(401) == T5` (`mobile/45` already flags this as a web parity issue); §15.8 says T4.
- `web/36` (novel column `data-cursor="text"`) and `web/37` (voice orbit `data-cursor="grab"`) should opt into the `web/26` item T cursor contract; neither mentions §7.40 today.
- `web/43` calls `useCircleMembers({ sourceId, seriesKey })` for recipients; `web/22` defined that shape as `useRecipients(sourceId, seriesKey)` (and `useCircleMembers({ enabled })` for the roster). One of the two names should win before `web/43` runs, so the hook is not forked.
- Spec paths: `web/32`, `web/33` and `web/35` write `frontend/e2e/glass/web-NN-*.spec.ts`, every other Glass step `frontend/e2e/glass-*.spec.ts`. Both match the `e2e/glass` filter the later steps run, so nothing breaks; `web/45` should include the `e2e/glass/` folder when it runs every Glass spec.
