# Review: web track, slice 4 (web/36 to web/45)

Reviewed 2026-09-29 against `prompts-plan.json` (binding), `inventory/00-decisions.md`, `stack-decision.md`, `00-baseline.md`, `inventory/{web,capabilities}.md`, `glass/DESIGN.md` (§2, §4.2, §4.6, §4.10, §5.2, §7.10–§7.16, §7.26, §7.38, §7.40, §8.0.3, §8.9–§8.11, §8.14.2, §8.14.5, §8.15, §8.16, §8.23–§8.26, §9.1–§9.4, §11, §15.7, §15.8) and the neighbouring prompts they hand work to or take it from (`web/22`, `web/29`, `web/31`, `web/33`, `web/35`, and `review-web-3.md`'s notes for this slice). Every fix below was made in place in the prompt file named. Nothing outside `docs/redesign/` was touched.

## Files in the slice

| File | Exists | Order / deps match plan | Rules (goal, read first, skills, layout, acceptance, verification, RAM guard, git, report back, next file) | Result |
|---|---|---|---|---|
| `web/36-glass-novel-reader.md` | yes | 90 / `web/35` | all present | fixed (paged columns, Slide shadow, header size, cursor, top-centre slot, shared keep-awake hook, commit check) |
| `web/37-glass-listen-mode.md` | yes | 92 / `web/36` | all present | fixed (sheet registration, swipe-down threshold, dial wheel and cursors, commit check) |
| `web/38-glass-search-sources-dialogue.md` | yes | 94 / `web/37` | all present | fixed (Ask hand-off key, Lens pop values, commit check) |
| `web/39-glass-settings-and-skin-switch.md` | yes | 96 / `web/38` | all present | fixed (licences moved to `web/40`, soundscape mix units, commit check) |
| `web/40-glass-you-about-admin-status.md` | yes | 98 / `web/39` | all present | fixed (registry entries incl. Administration, Narrating chip, Diagnostics route, licences ownership and registration, commit check) |
| `web/41-glass-ai-for-you-recaps.md` | yes | 100 / `web/40` | all present | fixed (Deal curve, Continue stand-in, More like this rail move, sheet registration, Ask hand-off, commit check) |
| `web/42-glass-stats-streak-wrapped.md` | yes | 102 / `web/41` | all present | fixed (dangling D13, entry rects, commit check) |
| `web/43-glass-circle.md` | yes | 104 / `web/42` | all present | fixed (hook names aligned with `web/22`, spoiler guard reuse, Orbs fly out curve, sheet registration, commit check) |
| `web/44-glass-ambient-reader-extras.md` | yes | 106 / `web/43` | all present | fixed (cruise magnet, keep awake, store locations, soundscape registration, guided-view labels, commit check) |
| `web/45-glass-qa-polish.md` | yes | 108 / `web/44` | all present | fixed (`tierFor(401)`, UI-sound scope, web-gate script reuse, regression pass, commit check) |

No file was missing, so none was created. Automated checks over the slice after the fixes: no "TBD", "etc." or "as appropriate"; every file names `superpowers:writing-plans`, `subagent-driven-development` (or `executing-plans`), `impeccable`, `taste-skill:taste-skill`, `frontend-design`, `verification-before-completion`; every file has the `free -m` guard with the 1024 MB stop, `npm run lint` and `npm run build`, 1440 × 900 and 390 × 844 captures under `docs/redesign/proof/web-NN/`, the no-attribution git rule, the `backend/connectors/` ban, a Report back section and the next prompt file. Every hex in the ten files exists in `glass/DESIGN.md` except the legacy `dusk` swatch `#1E1B18` in `web/36` (quoted from inventory K40 for the migration) and six test vectors in `web/44` (`#101010`, `#FFFFFF` fixture pages, `#123456`/`#123457`, `#808080`, `#C0392B`, `#FF0000`). Every spring `k, c` pair matches the §4.2 table and is attached to the right token name. Every `play()` name used exists as a §4.10 row (116 rows, counted).

## Findings and fixes

### 1. Every file judged "mobile and backend unchanged" by a branch or range diff

`web/36`, `37`, `38`, `44` and `45` checked `git diff --stat origin/feat/vps-slim-source-native -- mobile backend`; `web/40`–`43` checked `git diff --stat <first commit of this step>^..HEAD -- mobile backend`; `web/39` the branch diff for `backend`. Each web step runs beside its `mobile/NN` twin and the backend and shared sessions on the same branch, so both forms routinely show other sessions' commits: the check fails falsely or triggers a 4-minute `flutter test` on the shared box (`review-web-3.md` finding 7 fixed the same bug in `web/24`–`35`).
**Fix:** all ten now check each of their own commits with `git show --stat --format= <hash>` and run `flutter analyze`, `flutter test` and the backend pytest only if one of their commits touched `mobile/` or `backend/` (`web/39` allows only its generated `settings_index.dart`), one at a time after the RAM guard, with the same wording `web/25`–`35` use.

### 2. The licences sheet and its data were assigned twice, with conflicting files

`web/39` I3–I4 built the Open-source licences sheet and `frontend/scripts/build-licenses.mjs` writing `frontend/public/licenses.json` (direct dependencies only, fonts under `frontend/scripts/licenses/fonts/`), while `web/40` A4 and H2 built the same sheet and a different `build-licenses.mjs` writing `frontend/src/features/app/licenses.generated.json` (all production dependencies, fonts under `frontend/licenses/fonts/`, CC0 texts). Two scripts with one name and two data files cannot both land. The plan gives "licences incl. OFL and CC0 credits" to `web/40`, and `web/42` E7 already builds on `web/40`'s layout (`frontend/licenses/fonts.json`, `npm run licenses`).
**Fix:** `web/39` no longer builds any licences script, JSON or sheet (goal, TDD list, item I3 rewritten as a pointer to `web/40`, file layout, routes, spec states, acceptance and git steps updated); its About row "Open-source licences" renders only once the `licenses` sheet is registered. `web/40` H2 now states that it owns the sheet and data and registers `licenses` with `registerGlobalSheet`, which makes `web/39`'s row appear.

### 3. The Ask hand-off used two different storage keys

`web/38` B2 wrote `sessionStorage['mm.picks.ask']` for `web/41`; `web/41` A8 reads `sessionStorage['mm.glass.askDraft']` through `takeAskDraft()`. The text typed in Search would never reach For you.
**Fix:** `web/38` writes `mm.glass.askDraft` (through `writeAskDraft` when it exists); `web/41` A8 switches that write to its helper. The report item in `web/38` names the new key.

### 4. `web/43` renamed and re-signatured `web/22`'s Circle hooks

`web/43` A1 defined `useCircleMembers({ sourceId?, seriesKey? })`, `useCircleFeed({ profileId? })`, `useLetters({ box })` and `useSetLetterState()`, and A4 a new `isGuarded(reaction, { viewerProfileId, finishedChapters })`. `web/22` (which Cinematic calls) already defines `useCircleMembers({ enabled })`, `useRecipients(sourceId, seriesKey)` for the `can_receive` form, `useCircleFeed(kind?)`, `useLetters()`, `usePatchLetter()`, `unshareMember(id, "me")` and `isGuarded({ isOwn, sealed, completedLocally, completedThisSession })`; following `web/43` as written would fork the hooks or break Cinematic (`review-web-3.md` flagged the first case).
**Fix:** A1 now maps every call to `web/22`'s names and signatures, extending them only with optional arguments (`useCircleFeed(kind?, { profileId }?)`, `useLetters({ box }?)`, `staleTime` on `useRecipients`) and adding only `useNewLetterCount()` (and `useUnreact()` if `useReact` cannot delete); A4 reuses `web/22`'s guard and adds only `useFinishedChapters` if missing; E1, E2 and F use `useRecipients` and `useCircleFeed(undefined, { profileId })`; an acceptance line says no `web/22` hook was renamed.

### 5. More like this was built twice

`web/33` item 4 already builds the More like this rail on series detail and the book page (with the AI-unavailable `AiNotice`); `web/41` D1 built `parts/ai/MoreLikeThisRail.tsx` from scratch and only "replaced placeholders".
**Fix:** `web/41` D1 moves `web/33`'s rail into `parts/ai/MoreLikeThisRail.tsx` (one component, every placement imports it, the series-screen copy deleted) and replaces its AI-unavailable branch with the §9.1.4 `fallback=genres` path; layout and acceptance updated.

### 6. `web/41` did not retire `web/31`'s Continue stand-in

`web/31` D11 builds `screens/home/continue-with-recap.ts` (`continueWithRecap(item, anchorEl)`) as a stand-in and says `web/41` replaces it and deletes the file; `web/41` C1 created `useContinue.ts` without mentioning it, leaving two Continue rules.
**Fix:** C1 repoints every `continueWithRecap` caller to `continueSeries` and deletes the stand-in; a new acceptance line greps for it; the file layout lists the deletion.

### 7. Global sheet ids nobody registered

`web/29` item 8 built `registerGlobalSheet`, and `web/31`, `web/36` and `web/37` render rows only when an id is registered (`offer`, `recommend`, `soundscape`), but the steps that own those sheets never said to register them.
**Fix:** `web/37` A10 registers `player`, `voices`, `cast`, `audiobook` (the novel reader claims three of them for its desktop panel tabs); `web/40` registers `licenses`; `web/41` registers `offer` (sheet, desktop 420 px popover) and `how-it-works`; `web/43` registers `recommend`, `letter-note` and `collection-share`; `web/44` registers `soundscape` (desktop `panel` 440 px, claimed by the readers). Acceptance lines added where the dependency shows (the novel page menu's "Recommend to…", the player ⋯'s Soundscape).

### 8. Keep awake: `web/44` contradicted `web/36` and `web/39`

`web/44` B8 said "The web has no Keep-screen-awake switch" and built a second hook `ambient/useWakeLock.ts`, while `web/36` E8 and H6 and `web/39` E1 render the switch on coarse pointers with `wakeLock` (the one rule of §8.14.5).
**Fix:** `web/36` E8 exports `useKeepAwake({ force })`; `web/44` B8 reuses it (cruise and guided view force the lock; released 2 s after they end when the switch is off) and `useWakeLock.ts` is gone from the layout; an acceptance line checks there is one `wakeLock.request` call site.

### 9. Soundscape defaults stored in two units

`web/39` A5 created `mm.soundscape.defaults` with `mix: { bed: 80, detail: 50, tone: 30 }` in `skins/glass/prefs/`, while `web/44` A1, A2 and C1 use gain fractions 0–1 (`{ bed: 0.8, … }`) and would create the module in `skins/glass/ambient/` when "missing".
**Fix:** `web/39` stores fractions 0.8 / 0.5 / 0.3 (the sliders still show 80 / 50 / 30 %), clamps `volumeDb` −30 to 0 and tests it; `web/44` A2 names the exact homes `web/39` and `web/36` used (`cruiseDefault` and `guidedDefault` in the Glass reader store, `pageTint` in `mm.ambient-settings`, the defaults in `skins/glass/prefs/soundscape-defaults.ts`) and its layout creates the module there only if missing.

### 10. `web/44`: cruise magnet at ±0.10

§4.6 sets the value magnet for the speed dial and cruise at ±0.08× (`physics.valueMagnetSpeed`, ±12.8 px at 8 px per 0.05× on the pill). **Fix:** B4 uses ±0.08 and the ±12.8 px band (the spec's 1.07× case still snaps). F7 also gains the §9.4.3 `aria-label="Show the whole page"` on the overview button (glyph `squares-four` 20) and the "No panels found on this page" announcement.

### 11. `web/45`: `tierFor(401) == T5`

§2.4.3 says T5 is never reached by size and §15.8 asserts `tierFor(401) == T4` (`review-web-3.md` flagged it). **Fix:** C1 and its acceptance line assert T4. I7 now says UI sounds are off on a fresh device (Glass keeps them per device, `web/39` A5), not "for a new profile".

### 12. `web/45`: a second web-gate script and no regression pass

`web/29` Q built `frontend/scripts/glass-web-gate.mjs` for the §15.8 web gate; `web/45` K described its own fling. The earlier Glass specs (`e2e/glass-*.spec.ts`, and `e2e/glass/` from `web/32`, `33`, `35`) were never rerun at the end of the track.
**Fix:** K reuses `web/29`'s script with a new `--path` flag (`/library`); the Verification section adds a regression pass over every earlier Glass spec, one file at a time, with an acceptance line.

### 13. `web/40`: sections and routes the slice left out

- The §8.0.3 `admin` slug (Administration: System status, Members, Backup) was in `web/39`'s registry note (order 115) but no step built it. **Fix:** `web/40` gains "Settings registry entries" with all six sections, their orders (80–120), glyphs from Phosphor (`bell-ringing`, `lock-simple`, `hard-drives`, `database`, `shield`, `gauge`; `pulse` stays System status's), neutral `surface3` tiles, and the Administration list.
- `web/37` B7 hands the "Narrating 3" chip on the You tab's Library → Downloads row to `web/40` (§7.16, §8.16.8); `web/40` did not have it. **Fix:** B5 adds it.
- `web/02` made the thin route `settings/[section]/page.tsx` return `DebugEditionPage` for `diagnostics` under every skin, so `web/40`'s Glass Diagnostics section could never render. **Fix:** H1 limits that branch to non-Glass skins and embeds the debug control as the "Preview Glass skin" row; layout and acceptance updated.

### 14. `web/36`: values that did not match §8.15

- Paged mode set `column-width` to the text column; §8.15.4 uses a page-sized box (`column-width` = the viewport, gap 0, foliate-js). **Fix:** G2 makes the box page-sized and keeps the measure with `max-inline-size` on each block.
- Slide's edge shadow was "8 px soft"; §8.15.4 fixes `0 0 8px rgba(0,0,0,0.45)` with alpha scaled by progress. **Fix:** G4 and the acceptance line.
- The header's length line is `mono` 12/16 (a §3.7 override). **Fix:** D5.
- §7.40 `text` cursor on the novel column was not delivered (`review-web-3.md` note). **Fix:** F9 and an acceptance line.
- `web/41` places the "Previously · 20 s" pill in `web/36`'s top-centre slot, which did not exist. **Fix:** E9 defines one one-at-a-time top-centre slot (rate-limit capsule, pinch capsule, the pill) inside the chip / popover line of the five-surface budget.

### 15. `web/37`, `web/38`, `web/41`, `web/42`, `web/43`: smaller contract mismatches

- `web/37`: the swipe-down stop now needs the §7.15 40 px projection; the speed dial takes the desktop wheel (§11) and the `grab` cursor, the voice orbit `data-cursor="grab"` (§7.40).
- `web/38`: Lens pop now carries §8.11's ring (1 px `rgba(255,255,255,0.30)`, radius 48 → 96 px on `lens`, opacity 0.30 → 0 over 300 ms `cubic-bezier(0.4, 0, 1, 1)`).
- `web/41`: Deal cards used a control point 80 px above the line; §9.1.2 fixes 48 px perpendicular to the chord's midpoint toward the top (B7 and the values table). How it works is not linked from Dialogue search on the web (the web always shows the no-link hint variant of `web/38` E4).
- `web/42`: B9 pointed at a non-existent "D13"; it now writes `mm.glass.wrapped.origin` for D6, and D8 adds that write to `web/40`'s You card and `web/31`'s spotlight card.
- `web/43`: Orbs fly out now follows §9.3.4's curve (to the top edge at the orb's x ± 40 px, control point 120 px above the start).

## Coverage against the plan scopes

Every element the plan assigns to the slice is listed item by item in its file: `web/36` (the seven papers with the §8.15.1 table and ratios, layout with both desktop panels and the fit rule, capsules tinted by the paper ink at 12 %, scroll and paged modes with Slide, Lift and Fade on `paginateNovel`, the Aa sheet with every §8.15.5 row, Contents, pinch, the long-press menu with its five actions, every §8.15.7 state, the §8.15.8 keys; NR1–NR8, NR11, NR12, NR16–NR19, NT1–NT7, A76–A81); `web/37` (mini player as the accessory and the reader's listen row, the full player, speed dial, orbit and cast for every voice the server lists, the Audiobook sheet, sleep timer, highlight-as-read, every §8.16.8 state and key; NR9, NR10, NR13–NR15, A82–A86); `web/38` (§8.9 with the five scopes and Ask, §8.10 with pins, reorder and health, §8.11 with modes as pagers, §8.23 with hit-lens stills; SE1–SE11, SL1–SL13, SB1–SB15, OC1–OC8); `web/39` (§8.25.1, §8.25.2, the full §8.25.3 migration table, §8.25.4, §8.25.5, §8.25.13–§8.25.16, the two preview loops); `web/40` (§8.24, §8.25.6–§8.25.10, §8.25.12, the `admin` list, §8.26, the licences with OFL and CC0 credits; M1–M6, SG18–SG24, SG29–SG39, AS1–AS10, BK1–BK5, MB1–MB7); `web/41` (§9.1.2–§9.1.5; RC1–RC11, A41–A43); `web/42` (§9.2.1–§9.2.4; ST1–ST13, A40); `web/43` (§9.3.1–§9.3.6 and every 18+ and isolation state); `web/44` (§9.4.1–§9.4.4 in both readers and the listen player); `web/45` (every §15.8 bullet, the §15.7 budget table, §12.5 Float, the two-way debug-row switch).

Glass `PENDING` exits in the slice (checked against the §8.0.3 table): `web/36` novel · `web/38` discover, sources, source, dialogue · `web/39` settings · `web/40` index, status · `web/41` picks, recap · `web/42` numbers, annual · `web/43` circle, circleMember. `web/44` adds none; `web/45` deletes the empty map. Together with `review-web-3.md`'s list for `web/30`–`35`, every ScreenId leaves `PENDING` exactly once.

Assigned twice with explicit reconciliation (acceptable, now stated on both sides): the licences (`web/39` row → `web/40` sheet and data), the More like this rail (`web/33` → moved by `web/41`), the Continue path (`web/31` stand-in → `web/41`), the friend-orb drop (`web/31` → `web/43`, already reconciled), the reaction control in the readers (`web/36` menu path through `web/22`'s mutation → `web/43`'s strip and picker), Keep awake (`web/36` hook, forced by `web/44`), the soundscape defaults (`web/39` store → `web/44` engine), page-tinted chrome (`web/35`/`web/36` first version → made exact by `web/44`), the Circle and privacy section (`web/39` → verified by `web/43`).

## Plan versus contract (the file follows `glass/DESIGN.md`, as each file instructs)

- `web/39`'s plan scope says "the 620 ms melt"; §4.10 and §8.25.2 give 615 ms (the `page` settle). `web/39` uses 615 ms.
- `web/39`'s plan scope lists "App icon follows the skin default off"; §8.25.1 makes it a phones-only row, so the web renders nothing and never writes `mm.icon.follow` (unchanged).
- `web/44`'s plan scope and the backend plan serve recorded layers at `/app/soundscapes/glass/{scene}-{layer}`; §9.4.2 names ids `glass-{scene}-{layer}`. `web/44` already uses the path the backend serves and reports the difference.

## For the reviewers of neighbouring slices (not edited here)

- `web/29` item 8 lists the later registrations as `recommend`, `letter-note`, `offer`, `move-source`; the slice now also registers `player`, `voices`, `cast`, `audiobook` (`web/37`), `licenses` (`web/40`), `how-it-works` (`web/41`), `collection-share` (`web/43`) and `soundscape` (`web/44`).
- `web/33` item 4: its More like this rail is moved into `parts/ai/MoreLikeThisRail.tsx` by `web/41` D1; `web/33` can keep building it as it is.
- `web/18`: whether it changed `web/02`'s `diagnostics` branch in `settings/[section]/page.tsx` decides how `web/40` H1 narrows it; `web/40` is told to keep whatever Cinematic has.
- `web/22`'s `useRecipients` has no `staleTime`; `web/43` adds 60 s only if missing, which does not change Cinematic's calls.
- `mobile/39`: the settings index generated by `web/39` A3 must carry the rows of `web/40`'s six sections, since `web/40` may not edit `design/`.
- `mobile/45` should assert `tierFor(401) == T4`, the same as the corrected `web/45`.
