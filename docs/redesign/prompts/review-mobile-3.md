# Review: mobile track, slice 3 (mobile/24 to mobile/35)

Reviewed 2026-09-29 against `docs/redesign/prompts-plan.json` (binding), `docs/redesign/glass/DESIGN.md` (§2.4.3, §4.2, §7.10, §7.12, §7.25, §8.0.1, §8.0.3, §8.12, §9.3.2, §10.1, §15.3, §15.7, §15.8, §15.10, §15.11), `docs/redesign/cinematic/DESIGN.md` (§8.0.7, §8.0.9, §15.8, §15.9), `inventory/00-decisions.md`, `00-baseline.md`, the web twins `prompts/web/24`–`35`, the neighbours `mobile/23`, `mobile/36` and `mobile/42`, the harness contract of `mobile/03` item 9, and the earlier reviews `review-mobile-1.md` and `review-mobile-2.md`. All twelve files existed; none had to be created. Every fix was made in place; nothing outside `docs/redesign/` was touched and no git command that changes state was run.

## 1. Rule compliance, per file

| File | Exists | Goal / Read first / scope / layout | Skills | Acceptance (reduced motion, keyboard, 44 pt / 48 dp, per-skin) | Verification (`free -m`, 1 GB stop, analyze, test, baseline) | Proof harness | Git + guardrails | Report back + next | Plan scope and deps |
|---|---|---|---|---|---|---|---|---|---|
| 24 Cinematic QA | yes | yes | yes | yes | fixed (floor) | fixed (`MM_WRITE_SHOTS`, 820 / 1180 sizes) | yes | yes → release/00 | match; device pass gained the §15.8 Rack-focus row |
| 25 Glass foundation | yes | yes | yes | yes | fixed (floor) | fixed | yes | yes → 26 | match (plan's `GlassModalSheet` wording overridden by §15.3, stated in the file) |
| 26 primitives 1 | yes | yes | yes | yes | fixed (floor) | fixed | yes | yes → 27 | match |
| 27 primitives 2 | yes | yes | yes | yes | fixed (floor) | fixed | yes | yes → 28 | match (plan's `GlassModalSheet` overridden, stated) |
| 28 primitives 3 | yes | yes | yes | yes | fixed (floor) | fixed | fixed (push-rule diff direction) | yes → 29 | match |
| 29 shell | yes | yes | yes | yes | fixed (floor) | fixed; adds `kSkinShotDesktop` | fixed (push-rule diff direction) | yes → 30 | match (plan's `PredictiveBackPageTransitionsBuilder` / `SwipeablePage` now declared as overridden by §15.3) |
| 30 auth, profiles, onboarding | yes | yes | yes | yes | fixed (floor) | fixed | yes | yes → 31 | match |
| 31 Home | yes | yes | yes | yes | fixed (floor) | fixed | yes | yes → 32 | match (plan's "gyroscope" overridden by §2.4.2 rule 5, stated) |
| 32 Library hub | yes | yes | yes | yes | fixed (floor) | fixed | yes | yes → 33 | match |
| 33 series and book | yes | yes | yes | yes | fixed (floor) | fixed | yes | yes → 34 | match |
| 34 engine commands | yes | yes | yes (design skills stated as not needed: no pixels) | yes | fixed (floor in acceptance) | fixed (`MM_WRITE_SHOTS` for JSON and parity captures) | yes | fixed (wrong web twin named) → 35 | match |
| 35 manga reader | yes | yes | yes | yes | fixed (floor) | fixed | yes | fixed (wrong web twin named) → 36 | match, one double assignment removed (§2, item 6) |

Dependencies in every header equal `depends_on` in the plan (24 ← 23; 25 ← release/00, mobile/03, shared/05; 26 ← 25; 27 ← 26; 28 ← 27; 29 ← 28, shared/05; 30 ← 29, backend/05; 31 ← 30; 32 ← 31; 33 ← 32; 34 ← 33; 35 ← 34). No file contains "TBD", "etc." or "as appropriate". Verification commands are the baseline's (`/srv/manhwamaniacs/dev/flutter/bin/flutter analyze` and `flutter test` from `mobile/`; `npm run lint` / `npm run build` in `frontend/` and `backend/.venv/bin/python -m pytest -q --no-header` named and skipped with the reason, plus the queueless `npm run build` before a push that carries frontend commits). Values spot-checked against DESIGN.md matched: the spring table (k / c of `press`, `tab`, `lens`, `sheet`, `sheetSnap`, `page`, `zoom`, `settle`, `dismiss`, `letter`), the §2.4.3 Flutter mapping (thickness 12 / 20 / 24 / 40 / 56, blur 2 / 8 / 10 / 22 / 32, `S`, chromatic aberration 0 / 0.35 / 0.5), the rim gradient stops, the §15.8 physics vectors, the §10.1 letter-reveal table, the §7.25 gate copy, the §9.3.2 reactions and stored kinds, the §7.12 toast rules, the 960 px `materialThick` slab `Color(0xD6131317)`.

## 2. Findings and fixes

### Track-wide (all twelve files)

1. **Proof captures went to the served marketing folder.** Every visual-proof command used `MM_WRITE_SHOTS=1`, which makes the legacy marketing tests overwrite `mobile/docs/screenshots/` (the install page's public screenshots), while the `mobile/03` harness writes proof only when `MM_PROOF_DIR` is set; files also said "reusing `support/shot_harness.dart`" and used the retired tablet size 820 × 1180 (and 1180 × 820, 1366x1024-style names). This was already flagged for 24–45 by `review-mobile-1.md` §4 item 2 and `review-mobile-2.md` §5. **Fix:** every command sets `MM_PROOF_DIR=../docs/redesign/proof/mobile-NN`; each file has a **Proof output location** paragraph after its verification block (the harness file, `captureSkinScreen` / `captureSkinWidget` and their `<name>-<size.name>.png` naming, the allowed size constants, and `git status --short mobile/docs/screenshots` must print nothing); every "820 × 1180" became 834 × 1194; capture names now end in the size name.
2. **Glass desktop frame had no harness size.** Glass §8.0.1 gives the Flutter desktop frame its 280 px sidebar only from 1180 px wide, and none of `mobile/03`'s four sizes reaches that width (`kSkinShotTabletWide` 1024 × 1366 is the desktop frame with the collapsed 76 px sidebar). Steps 29–35 each invented a size (1180 × 820, 1366 × 1024, 1100 × 800). **Fix:** `mobile/29` adds one constant to `skin_shots.dart`, `kSkinShotDesktop = SkinShotSize('desktop', Size(1366, 1024), 2.0, EdgeInsets.only(top: 24, bottom: 20))`, outside the default loop, and records why; 30–35 capture their desktop frames with it (1366 wide also fits both manga-reader side panels, which need 1,212 px); the collapsed and narrow cases use `kSkinShotTabletWide`. Widget tests keep their own window sizes (they are not proof captures).
3. **Baseline floor.** "At or above the floor" was never tied to the baseline in most files. **Fix:** every acceptance line and every verification paragraph now reads "never below the 2012 passed of `00-baseline.md`: every test that passed there must still pass".
4. **Push rule direction.** 28 and 29 checked `git diff --stat HEAD...origin/… -- frontend`, which lists commits on the remote, not the frontend commits of other sessions that ride along in this push. **Fix:** `origin/feat/vps-slim-source-native...HEAD`, as every other file.

### mobile/24 (Cinematic QA)

5. Sizes: "tablet 820 × 1180 and 1180 × 820 … add any missing size to the harness" contradicted the harness contract. **Fix:** the four harness constants only (phone, tablet 834 × 1194, tablet-wide 1024 × 1366 for the ≥ 900 px rows of cinematic §8.0.9, landscape 844 × 390 for §8.0.9 **Landscape phones**); the QA audit runs at all four; the focus test at tablet-wide; section E split into three groups (`screens`, `states`, `a11y`), each run with its own `MM_PROOF_DIR`, with harness file names. The device pass gained the §15.8 row it lacked: the Rack-focus cap on a Library wall and a Discover results page at first load.

### mobile/25 (Glass foundation)

6. "The Glass Settings screen is `mobile/40`" was wrong: Settings is `mobile/39`, its Diagnostics section `mobile/40` (plan). **Fix:** the sentence names both.

### mobile/27 (overlays)

7. **Overlay queue incomplete against §7.12.** Only toasts waited behind an open menu; §7.12 makes every queue item (toast, global new-chapters capsule, app-update capsule) wait, and an item already showing leave on `dismiss` and fall back on `snappy` when the menu closes; the Offline and Syncing capsules are outside the queue. **Fix:** item A says so, and `overlay_queue_test.dart` lists those cases.
8. `glassBottomBarProvider` was said to be set by "`mobile/28` and `mobile/39`"; the "Unsaved changes" bar is `mobile/40`'s (its §8.25.6 Notifications page, and `mobile/28` D4 says the same). **Fix:** names `mobile/40`.

### mobile/28 (lists, states, AI, charts)

9. The reaction outbox was attributed to `mobile/43`; it is `mobile/22`'s `features/circle/store/reaction_outbox.dart` (the file's own Read first says so). **Fix:** path and owner stated, `mobile/43` only wires the Glass screens to it.

### mobile/29 (shell)

10. The plan entry names `PredictiveBackPageTransitionsBuilder`, `SwipeablePage` and `MaterialPage`; the file (correctly) builds the contract's `GlassPageTransitionsBuilder` and the vendored `GlassSwipePage` but did not say it overrides the plan. **Fix:** Read first item 7 states the deviation and asks for it in the report (as 25, 27 and 31 already do for theirs).
11. **Series window on tablets.** G4 gave `feature` a 960 px detail window on "tablet and desktop frames"; glass §8.12 **Presentation** and `mobile/33` B3 make the tablet frame the full content width with the phone's one-column anatomy. **Fix:** G4 says 960 on the desktop frame and full width on the tablet frame, with the layout owned by `mobile/33`.
12. Captures renamed to size names (`shell-desktop.png`, `shell-collapsed-tablet-wide.png`, `sidebar-overlay-tablet-wide.png`, `palette-desktop.png` …); `skin_shots.dart` added to the file layout for `kSkinShotDesktop`.

### mobile/32 (Library hub)

13. `profileScopedKey` was pointed at `mobile/lib/shared/providers/profile_scoped_key.dart`; `mobile/08` creates it at `mobile/lib/core/storage/profile_scoped_key.dart` (and `review-mobile-2.md` fix 20 aligned 17 and 20 to it). **Fix:** the real path.
14. **Second accessory.** H8 re-specified the whole Downloading accessory that `mobile/29` D12 builds. **Fix:** H8 feeds `mobile/29`'s slot from `QueueSummary` and `activeDownloadCountProvider` and only verifies it; no second widget.
15. **`?sheet=save-files` never registered.** `mobile/29` G5 names `mobile/32` as the owner of the global id and `mobile/28` G3's saved-chapter menu opens it, but H7 only built the widget. **Fix:** H7 registers it once with `registerGlobalSheet('save-files', …)`.

### mobile/33 (series and book)

16. **A second accelerometer subscription.** C2 read `accelerometerEventStream` directly, against `mobile/30` A4's rule of one reference-counted `gravityProvider` feeding every tilt effect (§2.4.2 rule 5), which `mobile/31` already follows. **Fix:** C2 reuses `gravityProvider` and moves `mobile/31`'s pure `hero_tilt.dart` mapping to `skins/glass/glass/tilt.dart`; the goal line and the listener-count test were updated (with `glassLightAngleProvider` overridden so the chrome is not a second consumer).
17. **Book open built twice.** H5 built the Book open move here and `mobile/36` B3 builds `GlassBookOpenPage` too. **Fix:** `mobile/33` builds it once as `transitions/book_open_page.dart` `GlassBookOpenPage` with exactly the extra shape `mobile/36` expects (`{'entry': 'book', 'plateRect', 'cover'}`), used by the router for the `novel` route's book entry (the `novel` ScreenId stays pending); `mobile/36` reuses it (see §5).

### mobile/34 (engine commands)

18. `strip-120.json` was written "when `MM_WRITE_SHOTS` is set" and the Cinematic parity captures ran `test/screenshots --plain-name` with `MM_WRITE_SHOTS=1` at 820 × 1180. **Fix:** the JSON goes to `MM_PROOF_DIR`; the parity runs call `marketing_screenshots_test.dart --plain-name "mobile-12"` / `"mobile-13"` into `parity/before` and `parity/after` through `MM_PROOF_DIR`, with an exact `cmp` loop.
19. The sign-off precondition grep (`"G6\|G14\|S1\|S11"`) matched loosely; now `"^S1 \|^S11 \|^G6 \|^G14 "`, the lines `backend/06` writes.
20. "Next prompt file" named `web/34` as the twin of `mobile/35`. **Fix:** `web/35`. The acceptance floor line was also missing and was added.

### mobile/35 (manga reader)

21. **`readerLanding` owned twice.** `mobile/29` registers the `/reader` → `/library` redirect and removes `readerLanding` from `PENDING` (its acceptance: "Glass PENDING lost only readerLanding"; `review-mobile-1.md` fix for `mobile/01` names `mobile/29`), and 35 claimed the same removal. **Fix:** 35 only verifies the redirect; goal, B5, tests, file layout and acceptance changed.
22. Captures: narrow panels at `kSkinShotTabletWide` (1024 wide, where the second panel closes the first), both panels at `kSkinShotDesktop`; "Next prompt file" named `web/35` as the twin of `mobile/36`: now `web/36`.

## 3. Cross-slice assignment check

Glass `PENDING` removals in this slice, each exactly once:

| Step | ScreenIds |
|---|---|
| mobile/24 | the Cinematic `PENDING` map is deleted (every Cinematic id) |
| mobile/29 | `readerLanding` |
| mobile/30 | `setup`, `login`, `register`, `profiles`, `profileNew`, `profileEdit`, `profilesManage`, `onboarding` |
| mobile/31 | `tonight` |
| mobile/32 | `library`, `collections`, `collection`, `history`, `bookmarks`, `updates`, `downloads` |
| mobile/33 | `feature`, `featureByFollow` |
| mobile/35 | `reader`, `readAll` |

The rest (`novel`, `picks`, `numbers`, `annual`, `recap`, `circle`, `circleMember`, `discover`, `sources`, `source`, `dialogue`, `index`, `settings`, `status`) belong to `mobile/36`–`mobile/43`, and `mobile/45` empties the map.

Shared pieces on the slice's boundaries, one owner each:

| Item | Owner | Users |
|---|---|---|
| Dependency gate, `SkinGlass`, physics, `GlassMotion`, `GlassHaptics`, `mm/platform` additions, orientation lock, calibration page | 25 | every later Glass step |
| Primitives (controls, posters, rails, reveals / overlays, sheet route, queue / lists, gate, download control, stack snapshots, AI, charts, reactions) | 26 / 27 / 28 | 29–45 |
| Shell, router, `?sheet=` registry, Dive, poster zoom, purge, splash, accessory, dock badges, `readerLanding` | 29 | 30–45 |
| `kSkinShotDesktop` harness size | 29 | 30–35 and, by convention, 36–45 |
| `gravityProvider` (one accelerometer source) | 30 | 31, 33, 42 (see §5) |
| `homeFeedProvider` refresh, `continueWithRecap` signature | 31 | 41 |
| `activeDownloadCountProvider`, `save-files` sheet and its registration, density storage | 32 | 29's badge and accessory slot, 28's saved-chapter menu, 33 |
| `GlassBookOpenPage` | 33 | 36 |
| Engine state and commands of glass §15.4 steps 1, 3–5 | 34 | 35, 36, 44 |
| `display.stableInsets`, `glass_reader_values.dart`, reader system UI | 35 | 36, 39 |

The four new features in the slice: AI home (31: AI rails, "because you read", thinking, stale, partial and unavailable states; 28's `AiNotice`, `ThinkingOrbit`, `copy/ai.dart`; recap entry through `continueWithRecap`, deck in 41); stats and streaks (31's streak chip and This week card, 28's charts, 30's daily-goal field; screens in 42); social (31's friend-orb drop and letters rail, 28's `ReactionPicker`; screens in 43); ambient extras (34's engine commands for cruise, samples and panels; 35's page-tinted chrome and cruise button; the rest in 44). Both signature animations are built in 26 (`LetterReveal`, `TypedHeadline`) with the focus-does-not-skip tests, placed in 29–33, and proven for Cinematic in 24 F.

Double assignments removed: `readerLanding` (29/35), the Downloading accessory (29/32), the accelerometer subscription (30/33), Book open (33/36, this side). Conflicting instructions resolved: the tablet series window (29 vs 33 and §8.12), the "Unsaved changes" bar owner (27 vs 28/40), the overlay queue blockers (27 vs §7.12).

## 4. Deliberately left as they are

- **Plan wording overridden by the contract** (the files already say so and ask for it in the report): `GlassModalSheet` with `smooth_sheets` as a fallback (plan 25, 27, 33) versus §15.3 **Sheets** and §15.10 G15 (every Glass sheet on `smooth_sheets` 1.2.0); "gyroscope light" (plan 31) versus §2.4.2 rule 5 (accelerometer gravity); `PredictiveBackPageTransitionsBuilder` / `SwipeablePage` (plan 29, now stated, fix 10).
- `mobile/25` keeps the calibration page and the layers row on `/dev/glass` routes until `mobile/40` moves them into Diagnostics, as the plan splits that work.
- `mobile/34` names no design skill because it changes no pixels; the file says why.
- The Rain-on-glass shader and the soundscape stay in `mobile/44` (the web twin puts `rain.ts` in `web/25`; the plan gives the Flutter shader to `mobile/44`).

## 5. Notes for the other reviewers (outside this slice; not edited)

- `mobile/36` B3 builds `GlassBookOpenPage` in `transitions/book_open_page.dart`; `mobile/33` now builds that same file with the same extra shape. B3 should reuse it ("verify and wire"), not build it. The same double assignment exists on the web between `web/33` item H5 and `web/36` item 3.
- `mobile/36` B3 also refers to "`mobile/35`'s Dive page"; the Dive is `mobile/29`'s `transitions/dive.dart` (`enterReader`, an `OverlayEntry` plus a `NoTransitionPage`), and `mobile/35` builds no page type unless `mobile/29` left one pending.
- `mobile/42` A6 describes `core/platform/gravity.dart` as if it were new and says "if `mobile/30`'s genre field opened its own accelerometer subscription, move it"; `mobile/30` A4 creates `gravityProvider` itself. A6 should become "reuse `mobile/30`'s `gravityProvider`, add only what is missing".
- Glass steps 36–45 should capture desktop frames with `kSkinShotDesktop` (1366 × 1024, added by `mobile/29`) and the collapsed desktop frame with `kSkinShotTabletWide`, never `MM_WRITE_SHOTS` or 820 × 1180 (the same convention as fix 1 and 2).
- `mobile/03` item 9 says its four sizes are "the only proof sizes of the whole mobile track"; `mobile/29` now adds a fifth for the Glass desktop frame. If the slice-1 reviewer prefers, the constant can move into `mobile/03`'s list with the same name and values; `mobile/29` reuses it when present.
