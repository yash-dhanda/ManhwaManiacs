# Review: mobile track, slice 4 (mobile/36 to mobile/45)

Reviewed on 2026-09-29. The review checked these sources:

- `docs/redesign/prompts-plan.json` (binding);
- `inventory/00-decisions.md`, `inventory/mobile.md` (S11, S12, S16, S17, S20, S22, S26 with N1 to N4, S27 to S34, G1 to G14) and `inventory/capabilities.md`;
- `stack-decision.md` and `00-baseline.md`;
- `glass/DESIGN.md` §2.1, §2.4, §3.4, §4.2, §4.6, §4.7, §4.10, §5.2, §7.16, §8.0.1, §8.0.3, §8.0.8, §8.9 to §8.11, §8.14.2, §8.14.11, §8.15, §8.16, §8.23 to §8.26, §9.1 to §9.4, §12.2 and §15.5;
- the neighbours `mobile/31` to `mobile/35`, `mobile/01`, `mobile/03`, `mobile/12`, `mobile/18`, `mobile/19`, `mobile/21`, `mobile/35`, `shared/03`, `shared/05` and `release/01`;
- the web twins `web/36` to `web/45` and `review-web-4.md`, for parity.

All ten files existed, so none was created. Every fix was made in place. No git command that changes state was run, and nothing outside `docs/redesign/` was touched.

## 1. Rule compliance, per file

| File | Goal, Read first, scope, layout | Skills | Acceptance (reduced motion, keys, 44 pt / 48 dp, per skin) | Verification (RAM guard, analyze, test, floor, npm and pytest named) | Git (small commits, push rule, no attribution, no secrets, no connectors, no prod) | Report back and next file | Plan scope and deps |
|---|---|---|---|---|---|---|---|
| 36 novel reader | yes | yes | yes | fixed (floor, proof harness, own-commit check) | yes | yes, then 37 | match |
| 37 Listen mode | yes | yes | yes | fixed (same) | yes | yes, then 38 | match, with one bounded plan item (§4, item 1) |
| 38 search, sources, dialogue | yes | yes | yes | fixed (same) | yes | yes, then 39 | match |
| 39 Settings and skin switch | fixed (licences, icons, recap, reader defaults) | yes | yes | fixed (same) | yes | yes, then 40 | match; the plan's `'GlassIcon'` is superseded (§4) |
| 40 You, admin, status | fixed (licences owner, `admin` slug, Narrating chip) | yes | yes | fixed (same) | yes | yes, then 41 | match |
| 41 AI | fixed (Ask hand-off, Similar, Continue, rail) | yes | yes | fixed (same) | yes | yes, then 42 | match |
| 42 stats, streak, Wrapped | fixed (genre weights source) | yes | yes | fixed (same) | yes | yes, then 43 | match |
| 43 Circle | fixed (reader reaction and recommend hand-offs) | yes | yes | fixed (same) | yes | yes, then 44 | match |
| 44 ambient extras | fixed (profile-default names) | yes | yes | fixed (harness, own-commit check) | yes | yes, then 45 | match |
| 45 QA and polish | fixed (switch test, flag surfaces) | yes | yes | fixed (harness sizes, own-commit check) | yes | yes, then `release/01` | match |

Each header states its dependency: `mobile/NN` depends on `mobile/NN−1`, as `depends_on` in the plan says. After the fixes, no file contains "TBD", "etc." or "as appropriate". One "and so on" in `mobile/44` F15 became an exact rule. Every file names `superpowers:writing-plans`, `subagent-driven-development` or `executing-plans`, `impeccable`, `taste-skill:taste-skill`, `frontend-design` (limited to the web-twin comparison) and `verification-before-completion`. Hex values, springs (k, c, settle), thresholds, haptic patterns and copy were spot-checked against DESIGN, and all matched. The checks covered:

- the seven papers and their ratios, the page turns, the drop cap and the chapter-end pull;
- the listen row, the orbit, the speed dial and the Audiobook sheet;
- the search tiers, pin fly, Lens pop and Deal;
- the recap deck, the flame, the Wrapped slots, the Circle arc and reactions;
- cruise, the soundscape recipes, guided view and the tint.

## 2. Findings and fixes

### Track-wide (all ten files)

1. **Proof captures would overwrite the install page's screenshots.** Every file ran its harness with `MM_WRITE_SHOTS=1` at 820 × 1180 and 1180 × 820. The track convention that `mobile/03` set and `review-mobile-1` and `review-mobile-2` applied is different:
   - use `MM_PROOF_DIR` only;
   - `MM_WRITE_SHOTS` writes the backend-served `mobile/docs/screenshots/`;
   - the proof sizes are `kSkinShotSizes` (phone 390 × 844, tablet 834 × 1194), `kSkinShotTabletWide` (1024 × 1366) and `kSkinShotLandscape` (844 × 390);
   - captures go through `captureSkinScreen` and `captureSkinWidget` in `support/skin_shots.dart`.

   **Fix:** every Visual proof section now does the following:
   - adds a "Proof output location" paragraph;
   - runs with `MM_PROOF_DIR=../docs/redesign/proof/mobile-NN` from `mobile/`;
   - maps "desktop frame" to `kSkinShotTabletWide` (width ≥ 1024, so §8.0.1's desktop frame);
   - explains the `-tablet-wide` file suffix;
   - requires `git status --short mobile/docs/screenshots` to be empty.

   The test files moved under `mobile/test/screenshots/glass/` in 40 to 43. `mobile/39`'s preview frames keep their own `MM_WRITE_PREVIEWS=1`. `mobile/45` keeps two local sizes that the plan's QA list needs and no harness size reaches, and names both in `qa.md`:
   - `phone-max` 440 × 956 @3: `web/45`'s large phone and §12.5's Float viewport;
   - `desktop` 1180 × 820: §8.0.1's full 280 px sidebar starts at 1180.

   Each `mobile-45` group sets its own `MM_PROOF_DIR` subfolder.
2. **Test floor for Glass steps.** The files said "at or above the floor (baseline 2012 …)". Every Glass step runs after `release/00`, which deletes the legacy widget tests by design and lists them in `docs/redesign/proof/release-00/deleted-tests.md`. So the count can legitimately fall below 2012, and a session would stop on a false failure. **Fix:** the floor is the count recorded at the start of the step, and every baseline test not listed in `deleted-tests.md` must still pass. `mobile/44` and `mobile/45` already said this, and 36 to 43 now say it too.
3. **"This step changes nothing in `frontend/` or `backend/`" was checked with a branch or range diff.** Examples are `git diff --stat origin/… -- frontend backend` and `<first commit>^..HEAD`. Each mobile step runs beside its web twin on the same branch, so either check shows the twin's commits, and the session would fail itself or run `npm run build` for nothing (`review-web-4` finding 1 is the mirror image). **Fix:** all ten files now check each of their own commits with `git show --stat --format= <hash>`. The push rule that builds `frontend/` when other sessions' commits ride along is unchanged.

### mobile/36 (novel reader)

4. **A second page-tint switch, and wrong store names.** C4 would create `mm.ambient-settings` `{pageTint}` or read Cinematic's `pageTint` (`mobile/23`). D12 read `autoNext`, and E8 read `keepAwake`. `mobile/35` already defines Glass's per-profile values in the `glass` object of `mm.reader-settings` through `glass_reader_values.dart`: `glass.pageTinted`, `glass.keepAwake`, and the record's shared `autoNextChapter`. `mobile/44` G8 also needs one switch for both readers. **Fix:**
   - C4, H5, D12 and E8 use those names;
   - a precondition greps for them;
   - `ambient_settings_provider.dart` is gone from the file layout.
5. **No top-centre slot for the "Previously" pill.** `mobile/41` C3 puts the pill into "`mobile/35`'s and `mobile/36`'s top-centre pill slot", but `mobile/36` never defined one (`review-web-4` finding 14 fixed the same gap in `web/36`). **Fix:** new E9 defines a one-at-a-time slot for the rate-limit capsule, the pinch capsule and the pill, inside the L budget. It is listed in Report back.
6. The header length line is now `mono` 12/16, the §3.7 override that §8.15.2 names. The router line now registers the `contents`, `type` and `note` sheet ids.

### mobile/37 (Listen)

7. **Sheet ids never registered.** The `player`, `voices`, `cast` and `audiobook` ids were used but never added to `mobile/29`'s `?sheet=` registry (`review-web-4` finding 7). **Fix:** the file layout now names the registration in `router.dart`.

### mobile/39 (Settings and the skin switch)

8. **The licences sheet and its data were assigned twice, with conflicting files.**
   - `mobile/39` J4 built the sheet, `mobile/tool/gen_package_versions.dart`, `skins/glass/copy/package_versions.g.dart`, `art_licences.dart` and `licence_kind.dart`.
   - `mobile/40` A4 and I2 built the same sheet with `mobile/tool/licenses/build_licences.dart`, `features/settings/utils/package_versions.g.dart`, `licenses.dart`, `assets/licenses/art_and_sounds.json` and the CC0 text.

   The plan gives "licences incl. OFL and CC0 credits" to `web/40`, and `review-web-4` finding 2 made the same call on the web. **Fix:**
   - `mobile/39` keeps only the About row, and J4 is now a hand-off;
   - the `licenses` sheet id sits on the pending body in `sectionsBuiltLater`;
   - the goal, TDD list, file layout, acceptance, captures, out-of-scope list and report were updated;
   - `mobile/40` A4 and I2 now state that they own the only pipeline and replace the pending body.
9. **Icon names and registration.**
   - The precondition expected the `.GlassIcon` and `.CinematicIcon` aliases in `AndroidManifest.xml` and a registered Glass icon in `project.pbxproj`. `shared/05`'s gate forbids both while `flags.glass_available` is false, because `release/01` applies `brand/glass/icon-registration.md`.
   - E3 stored the short names `'GlassIcon'` and `'CinematicIcon'`, but the plugin compares fully qualified class names (`shared/05`, and `release/01` D2).

   **Fix:**
   - the precondition reads `brand/glass/icon-registration.md` and asserts that no alias is registered yet;
   - E2 uses `'AppIcon-Glass'` and states that the plan's `'GlassIcon'` is superseded;
   - E3 stores `'com.manhwamaniacs.reader.GlassIcon'` and `'…CinematicIcon'` as constants;
   - E4 injects `glassAvailable` so the tests can pass `true`.
10. **The icon switch is a flag-gated surface.** `release/01` section C item 2 turns "App icon follows the skin" on, and `mobile/45` M5 expects it to be absent while the flag is false. `mobile/39` C4 showed it always. **Fix:** C4 renders the row only when `showIconRow` is true (default `Flags.glassAvailable`, both values widget-tested). The B2 index hides `app-icon-follows-skin` while the flag is false. C1 now says the skin cards show in every build (in Glass, the Glass card is never a target).
11. **Recap setting provider in the wrong place.** A6 pointed at `mobile/19` and would have created `features/ai/providers/recap_settings_provider.dart`. The owner is `mobile/18`'s `features/recap/recap_setting.dart` (`recapSettingProvider`), which `mobile/19` and `mobile/41` read. **Fix:** A6 and the file layout use that file and forbid a second key.
12. **Profile-default names differed from `mobile/44`.** A8 added `cruiseSpeed` and `guidedDefault` "to the Glass reader settings store", `mobile/44` A2 created `cruiseDefault` and `pageTint` in `mm.reader-settings`, and `mobile/35` already has per-series `cruiseSpeed` and `glass.pageTinted`. **Fix:**
    - A8 adds `glass.cruiseDefault` and `glass.guidedDefault` to `mobile/35`'s `glass` object;
    - F4 writes them;
    - the migration row for cruise falls back to `glass.cruiseDefault`;
    - the Keep-awake row seeds `glass.keepAwake` through `mobile/35`'s function;
    - `mobile/44` A2 reads exactly these names.
13. The CI note no longer claims that the iOS dry run compiles `AppIcon-Glass.icon`, which is unregistered until `release/01`.

### mobile/40 (You, admin, status)

14. **The `admin` slug was never built.** `mobile/39` put `admin` in `sectionsBuiltLater` ("the Administration list (System status, Members, Backup)", §8.0.3), and no step built it. **Fix:** a new "Administration list" paragraph (after F) with admin-only rows and the non-admin lens. `sectionsBuiltLater` must be empty at the end of the step, and an acceptance line checks both.
15. **Narrating chip missing on the You tab.** `mobile/37` C7 hands the "Narrating 3" chip on You → Library → Downloads to `mobile/40` (§8.16.8), but `mobile/40` did not have it. **Fix:** B5 and an acceptance line.
16. **Wrong soundscape credits file.** A4 read `backend/media/soundscapes/SOURCES.md`, which lists Cinematic's own synthesised loops. The CC0 recordings §9.4.2 requires credit for are in `backend/media/soundscapes/glass/SOURCES.md` (`shared/03`). **Fix:** A4 now reads:
    - the Glass file's rows that carry a Freesound URL and `CC0 1.0`;
    - a "Deep soundscape layers" entry for the synthesised Deep layers.

    `assets/licenses/` is declared by `mobile/03` already, so A4 adds the line only if it is missing.
17. **Storage row owned twice.** `mobile/39` owns the Storage row as a cross-tab `go`; `mobile/40` said the row "pushes" and would have rebuilt it. **Fix:** F adds only the `/settings/storage` redirect. The Read-first line now names `settings_sections.dart` and `icon_tile.dart` as the registry and the tile colours, not `settings_index.dart`.
18. **The debug row left Glass without the melt.** I1's "Preview Glass skin" restarted with a 200 ms fade, while `mobile/45` M2 (and `web/45`) verify the melt on that row. **Fix:** choosing Cinematic leaves Glass through `mobile/39`'s melt, then `mobile/01`'s `debugSwitchSkin`. It still never writes the profile's skin, `mm.skin.active` or `mm.skin.prev`.

### mobile/41 (AI)

19. **The Ask hand-off used two providers.** `mobile/38` B2 writes `pendingAskProvider` in `features/library/providers/pending_ask_provider.dart`, while `mobile/41` A8 read a new `askDraftProvider`, so a query typed in Search would never reach For you (`review-web-4` finding 3). **Fix:** A8 and B12 use `pendingAskProvider`, and the file layout was updated.
20. **A second Similar client.** A7, B9 and D1 called `aiSimilar(…, fallback: 'genres')`. `mobile/19` already exposes `similar({…}, {bool fallbackGenres})` behind `similarProvider`, which `review-mobile-2` fix 6 made the one client. **Fix:** every call uses it.
21. **`should_open_recap.dart` path.** A4 used `features/recap/should_open_recap.dart`; `mobile/19` created `features/recap/utils/should_open_recap.dart`. **Fix:** the path is corrected, and the new decisions sit beside `shouldOpenRecapFirst`.
22. **Two Continue rules and two More like this rails.**
    - `mobile/31` built the stand-in `continueWithRecap(…, HomeContinueTarget item, Rect)`, and `mobile/41` created `continueSeries(…, ContinueTarget item, …)` beside it.
    - `mobile/33` item 4 built the More like this rail, and `mobile/41` D1 built another.

    (`review-web-4` findings 5 and 6 are the same on the web.) **Fix:**
    - C1 takes `HomeContinueTarget`, repoints every `continueWithRecap` caller and deletes the stand-in;
    - D1 moves `mobile/33`'s rail into `parts/ai/more_like_this_rail.dart` and replaces its `AiNotice` branch with the `fallback=genres` path;
    - a new acceptance line and the file layout check both.

### mobile/42 (stats, streak, Wrapped)

23. **Genre weights attributed to the wrong step.** Read first listed `genreWeightsProvider` as `mobile/21`'s, but the current `mobile/21` A3 reads `mobile/16`'s `genreWeightsProvider(8)` ("the app's one genre-weights client"). **Fix:** Read first and B7 name `mobile/16`'s provider and forbid a second one.

### mobile/43 (Circle)

24. **Reader reaction paths rebuilt.** C4 would rebuild the novel long-press "React" path, which `mobile/36` F6 already builds in full (picker, send, arc, failure, offline and sharing-off states). **Fix:** C4 now points both reader menu paths at C1's `copy/reactions.dart`, mounts the strip in `mobile/36`'s end-matter slot and `mobile/35`'s end card, and fixes only what differs. E3 registers `recommend` in `mobile/29`'s `?sheet=` registry, which is what makes `mobile/36` F7's "Recommend to…" row appear.

### mobile/44 (ambient extras)

25. **Profile-default names and the defaults store.** A2 now reads `glass.cruiseDefault`, `glass.pageTinted`, `glass.guidedDefault` and `glass.keepAwake` (item 12). It also uses `mobile/39`'s `soundscapeDefaultsProvider` in `features/reader/providers/soundscape_defaults_provider.dart` instead of creating `skins/glass/soundscape/soundscape_defaults.dart`, and adds the clamping tests only if they are missing. G8 names `glass.pageTinted`.
26. **`walkSteps` gave a negative stop for short panels.** F15's rule "0, 0.8 V, … and so on, then H − V" returns `[−0.1 V]` for a panel 0.9 viewports tall, although the test expects `[0]`. **Fix:** "`[0]` when `H ≤ V`; otherwise the stops `k × 0.8 V` with `k × 0.8 V < H − V`, then `H − V`". This also removes "and so on".

### mobile/45 (QA)

27. **The switch test contradicted the debug path.** M1 expected the following after a switch through the debug row:
    - `mm.skin.active = glass` and a queued `PATCH /profiles/{id}`;
    - a landing on `/library/collections`;
    - the "Switched to Glass" toast.

    `mobile/01`'s `debugSwitchSkin` writes only `mm.skin.debug` and `mm.skin.t0` and returns to `/settings/diagnostics`, and `mobile/40` I1 says the row never writes the profile's skin. **Fix:**
    - M1 and M2 assert the debug path's real effects, with no toast (the explicit flow is `mobile/39`'s arrival test and `release/01`);
    - M2 asserts the melt, per item 18;
    - the acceptance line matches.
28. **M5 treated flag-gated surfaces loosely.** It now names what stays hidden while the flag is false: Cinematic's Edition picker, onboarding step 2, the profile form and the icon row. It also says that Glass's own Appearance offers only Cinematic as a target. Harness sizes and env vars were fixed as in item 1. The audit and focus tests use 834 × 1194, and the desktop-frame budget moment keeps 1180 × 820, the docked-sidebar frame.

## 3. Cross-slice assignment check

Each item below has one owner, and both ends of each hand-off now name it.

| Item | Owner | Consumers (checked) |
|---|---|---|
| Glass per-profile reader values (`glass.pageTinted`, `glass.keepAwake`, `autoNextChapter`) and per-series `cruiseSpeed` | `mobile/35` | 36, 39, 44 |
| `glass.cruiseDefault`, `glass.guidedDefault` | `mobile/39` A8 | 44 |
| `mm.soundscape.defaults` provider | `mobile/39` A7 | 44 |
| `recapSettingProvider` (`mm.recap`) | `mobile/18` | 19, 39, 41 |
| `pendingAskProvider` | `mobile/38` B2 | 41 |
| `similar` / `similarProvider`, `dismissedPicksProvider` | `mobile/19` (with `mobile/12`) | 41 |
| `genreWeightsProvider(8)` | `mobile/16` | 21, 41, 42 |
| The Continue path | `mobile/41` C1 (the `mobile/31` stand-in is deleted) | 31, 32, 33, 29 accessories |
| More like this rail | `mobile/41` D1 (moved from `mobile/33`) | 33, 35 |
| Licences sheet and data | `mobile/40` A4 and I2 | 39 About row, 40 You row |
| Settings sections and index | `mobile/39`; `sectionsBuiltLater` emptied by `mobile/40` (incl. `admin`, `licenses`) | 40 |
| Skin melt | `mobile/39` D3 | 40 debug row, 45 M2 |
| Top-centre reader slot | `mobile/36` E9 (novel), `mobile/35` (manga) | 41 pill |
| Reactions in the novel reader | `mobile/36` F6 (menu path), `mobile/43` C (strip, table, surfaces) | 43, 45 |
| `?sheet=` registrations | 36 (`contents`, `type`, `note`), 37 (`player`, `voices`, `cast`, `audiobook`), 40 (`licenses`), 41 (`offer`, `how-it-works`), 43 (`recommend`, `letter-note`, `collection-share`), 44 (`soundscape`) | 29 registry |
| "Narrating 3" chip | `mobile/37` C7 (widget, Downloads, sidebar) | 40 (You tab row) |
| `StreakFlame`, `gravityProvider`, `wrappedOriginProvider` | `mobile/42` | 31, 40, 43 |
| `AppIconSwitcher` and its two name constants | `mobile/39` E | `release/01` D2 |

Glass `PENDING` exits in this slice, checked against the §8.0.3 table:

| Step | ScreenIds |
|---|---|
| 36 | `novel` |
| 38 | `discover`, `sources`, `source`, `dialogue` |
| 39 | `settings` |
| 40 | `index`, `status` |
| 41 | `picks`, `recap` |
| 42 | `numbers`, `annual` |
| 43 | `circle`, `circleMember` |

`mobile/37` and `mobile/44` add none, and `mobile/45` deletes the empty map. Every other ScreenId is owned by `mobile/29` to `mobile/35` (checked by grep). All four new features have one owner each: AI in 41, stats in 42, social in 43 and ambient in 44. The two signature animations are verified end to end by `mobile/45` H.

## 4. Left as they are on purpose

1. **Notification accent "at runtime" (plan, `mobile/37`).** `AudioServiceConfig.notificationColor` is fixed when `AudioService.init` runs once per engine. A3 sets it from the boot skin, and an in-process skin switch keeps the old colour until the next cold start. The file records this platform limit, and `release/01` D4 confirms the same reading.
2. **Plan text superseded by the contract**, as each file already states:
   - the melt is 615 ms, not 620 ms (§4.10, §8.25.2);
   - the iOS icon is `AppIcon-Glass`, not `GlassIcon` (§12.2, `shared/05` Decision 1).
3. **`mobile/36` interpretations** the file already asks the session to report: justify without hyphenation, the platform's 500 ms long-press, the Taps row in the Aa sheet, side panels without a backdrop blur, and the old `dusk` swatch mapped to Night Paper.
4. **`mobile/37` Ogg samples on iOS.** SoLoud has no AAC decoder, while §8.16.4 names m4a on iOS. The file reports the difference, and `mobile/44` follows the same rule for its layers.
5. **Widget-test viewports** such as `mobile/42`'s Wrapped at 1180 × 820 and `mobile/45` K's budget moments are test inputs, not proof captures. They keep the sizes their formulas need.

## 5. Notes for the other reviewers (outside this slice; not edited)

- **`mobile/31` D11** says `mobile/41` "replaces the body of this function … keep the signature". `mobile/41` C1 now repoints the callers and deletes the stand-in, the same resolution as `review-web-4` finding 6. `mobile/31` can stay as written.
- **`mobile/30` to `mobile/35`** still judge "this step changes nothing in `frontend/` or `backend/`" with `git diff --stat origin/…`. This fails falsely while the web twin commits (item 3). They also say "at or above the floor (the baseline was 2012 …)", although `release/00` deletes legacy tests before `mobile/25` (item 2).
- **`web/40` H1's** debug row "writing the `mm-skin-debug` cookie and restarting" does not mention the melt that `web/45` M2 asserts on that row. `mobile/40` now leaves Glass through the melt (item 18).
- **`mobile/33`**: its More like this rail file is moved by `mobile/41` D1 and can stay as written.
- **`mobile/35`**: its per-profile Glass values table is now the single source for 36, 39 and 44. A later rename there must update all three.
