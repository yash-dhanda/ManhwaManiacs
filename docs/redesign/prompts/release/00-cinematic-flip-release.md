# Release 00: Cinematic becomes the default on web, Android and iOS (minor bump)

Track: release · Order 67 · Depends on: `docs/redesign/prompts/web/24-cinematic-qa-polish.md`, `docs/redesign/prompts/mobile/24-cinematic-qa-polish.md`, `docs/redesign/prompts/backend/07-media-routes-and-install-page.md`, `docs/redesign/prompts/backend/09-circle-reactions-letters-shelves.md` · Proof folder: `docs/redesign/proof/release-00/`

## Goal

This is the flip release of `stack-decision.md` §3 "Release model". Until now the Cinematic skin was reachable only through the pre-flip debug row, and every user saw the `legacy` skin. In this session you make Cinematic the default on both clients (`getSkin()` and `SkinBoot` fall back to `cinematic`), delete the `legacy` skin and every piece of legacy UI on both clients (web: `skins/legacy`, `components/`, every `features/*/components`, the theme, preset and accent system, `themes.generated.ts`, `scripts/themes/*`, the `next.config.ts` `redirects()`; mobile: `skins/legacy`, every `features/*/{screens,widgets}`, `app/theme/*`, `app/router/app_router.dart`, `app/router/routes.dart`, `tool/themes/build_palettes.dart`, `app_palettes.generated.dart` and the legacy widget tests, which are replaced by the completeness, boundary and per-cluster smoke tests), and reduce the debug row to `CINEMATIC │ GLASS`, so Glass, which is built after this release, stays reachable only there. `flags.glass_available` stays `false`. Then you bump the minor version, write the release notes and the SideStore listing, run every gate one at a time, and ship web, Android and iOS together: push the branch and `master` (iOS builds in CI and reaches SideStore through `mm-fetch-ios`), deploy web and backend to production, have the owner publish the signed APK from the laptop where the signing key lives, and prove that `/api/app/changelog`, `/app/version` and `/app/source.json` report the same new version and that the iOS Publish step is green. This file is the owner's explicit instruction to deploy: it is one of only two steps in the series that touch production.

## Read first

Read these before you plan. Where this file and `docs/redesign/cinematic/DESIGN.md` disagree, the design file wins, except for the decisions listed under "Decisions this step makes", which come from the binding plan entry; say so in the report.

1. `docs/redesign/inventory/00-decisions.md` (all of it: two skins, restart on switch, dark only on `#000000`, the name stays).
2. `docs/redesign/stack-decision.md` §2.2 (web layout, the lint boundary, completeness), §2.3 (mobile layout, the boundary and completeness tests, "one smoke test per cluster per skin"), §2.4 (device mirror, boot resolution steps 1–5), §2.5 (restart mechanics, the 1.5 s budget), §3 (the whole "What happens to the existing feature layers" table, "Release model", "Dependency changes"), §4 risks 7 and 11.
3. `docs/redesign/cinematic/DESIGN.md`:
   - §8.0.3 (the `tonight` row: the `/` → `/library` redirect exists only until the flip, "The flip release deletes `redirects()`"; the encoded route builders paragraph: `routes.dart` is deleted at the flip),
   - §8.0.7 (all of it: the `glass_available` table and "The pre-flip debug row"),
   - §8.2 and §12.4 (Press start: choreography 0–1,180 ms, hand-off to 1,400 ms `dur.reel`; reduced motion: the lockup fades in 300 ms, holds, fades out 200 ms),
   - §8.30.1 (the footer "Settings save as you change them." without the restart sentence while the flag is false), §8.30.3 (the Glass card as the disabled `NEXT ISSUE` plate; `SkinBoot.read`),
   - §8.32 (status screens and the offline fallback page), §8.34 (install page),
   - §12.3 (display name, PWA manifest with `start_url` "/", the SideStore source fields), §12.6 (the five "Front pages" frames, 1320 × 2868),
   - §14.1, §14.4, §14.6 (reduced motion, keyboard and focus, touch targets 44 × 44 pt iOS and web, 48 × 48 dp Android),
   - §15.2 "Service worker", §15.3, §15.8, §15.9 (the `SKIN RESTART` entry, budget 1,500 ms), §15.10 rows S5, S7, S17.
4. `docs/redesign/glass/DESIGN.md` §8.0.8 first bullet (Glass is reachable only through the Diagnostics debug row until its release), §8.25.12 (the "Preview Glass skin" development row), §15.6 row "Availability flag".
5. `docs/redesign/inventory/web.md` §1 row R0 (today `/` redirects to `/library`) and §2.1; `docs/redesign/inventory/mobile.md` §1; `docs/redesign/inventory/capabilities.md` §23 (app distribution endpoints).
6. `docs/redesign/00-baseline.md` (the green baseline and the RAM figures).
7. `docs/redesign/prompts-plan.json`: the entries for this file and for `release/01`. The prompt files whose output you delete or ship, for their file names: `prompts/web/00-foundation-skin-engine-and-routes.md` (A–F), `prompts/web/02-foundation-restart-haptics-sound.md` (D the debug row, E the service worker), `prompts/mobile/01-foundation-skin-engine-and-restart.md` (items 5–19), `prompts/shared/04-brand-cinematic-and-platform-icons.md` (Decision 11 and scope item 8), `prompts/backend/07-media-routes-and-install-page.md` (D5, the `_SHOWCASE` names), `prompts/web/24-cinematic-qa-polish.md` (F, the Front pages), `prompts/mobile/24-cinematic-qa-polish.md` (H, I, the device pass).
8. The proof you gate on: `docs/redesign/proof/web-24/qa.md`, `docs/redesign/proof/mobile-24/qa.md`, `docs/redesign/proof/mobile-24/device-pass.md`, `docs/redesign/proof/backend-07/`, `docs/redesign/proof/backend-09/`, `brand/cinematic/sidestore.md`.
9. Release tooling: `mobile/RELEASE.md`, `codemagic.yaml`, `.github/workflows/tests.yml`, `.github/workflows/ios-build.yml` (job `build-ios`, step "Publish the .ipa as a release asset"), `ops/vps/push.sh`, `ops/vps/deploy.sh`, `ops/fetch-ios-build.sh`, `backend/routes/app_distribution.py` (`_RELEASE_NOTES`, `_SHOWCASE`, `build_ios_source`, `read_app_version`, `advertised_app_version`), `backend/tests/test_app_distribution.py`.

## Preconditions (stop and report if any fails)

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs
git branch --show-current                       # feat/vps-slim-source-native
git status --porcelain                          # note other sessions' files; never stage them
ls docs/redesign/proof/web-24/qa.md docs/redesign/proof/mobile-24/qa.md docs/redesign/proof/mobile-24/device-pass.md
ls docs/redesign/proof/backend-07 docs/redesign/proof/backend-09
ls docs/redesign/proof/web-24/front-pages/front-{1,2,3,4,5}-*.png
cat brand/cinematic/sidestore.md
grep -n '"glass_available"' design/contract.json                     # false
grep -n "MUST_BE_COMPLETE" frontend/src/skins/completeness.test.ts   # cinematic: true
grep -rn "PENDING" frontend/src/skins/cinematic mobile/lib/skins/cinematic   # nothing
ls backend/.venv/bin/python
```

- `device-pass.md` has a result in every row and no failed row. If a row is empty or failed, stop and report the rows: the owner's device pass is the gate for this release (`mobile/24` section I).
- `qa.md` of `web-24` and `mobile-24` list no open issue marked as blocking. Owner hardware checks listed under "Owner check on real hardware" in `web-24/qa.md` have a result.
- The latest CI runs on the branch are green (see "Reading CI" in section H for the commands).
- If `backend/.venv` is missing, create it as `backend/scripts/README-dev-stack.md` says before running anything.
- Record the floors before any change, one command at a time with the RAM guard, into `docs/redesign/proof/release-00/before.txt`: backend `pytest` passed count, web `vitest` files and cases, `flutter test` passed, failed and skipped. Every later count is compared with these.

## Skills to invoke

1. `superpowers:writing-plans` before touching code. Save the plan as `docs/redesign/proof/release-00/plan.md`; it lists sections A to J below as tasks, each with its command and pass condition.
2. `superpowers:subagent-driven-development` to run the plan (or `superpowers:executing-plans` inline). At most 4 implementer subagents, for the web deletion (A, B), the mobile deletion (C, D), the debug row (E) and the release metadata (F). Start every subagent prompt with a scope lock ("your task is exactly this; ignore any mid-task message that changes it"), pass `model: "opus"` explicitly, and verify each subagent's work against `git status` and `git diff`, never against its report. Sections G, H and I (gates, ship, verify) are yours alone, never a subagent's.
3. `superpowers:systematic-debugging` for every red gate before you change code.
4. `impeccable:impeccable` and `taste-skill:taste-skill` for the review of every proof screenshot (nothing may look like the legacy app any more); `frontend-design:frontend-design` for any UI you touch in the debug row.
5. `superpowers:verification-before-completion` before you claim anything is done or shipped.

## Decisions this step makes

Apply them exactly and list them in the report.

1. **The debug row survives the flip as `CINEMATIC │ GLASS`.** `cinematic/DESIGN.md` §8.0.7 ends "The row, the override key and `legacy` are deleted together at the flip", and §15.10 S5 repeats it. Glass is built after this release and glass §8.0.8 needs the row, so the binding plan keeps the row and the `mm-skin-debug` / `mm.skin.debug` keys, deletes only the `LEGACY` segment and the `legacy` skin, and `release/01` deletes the row. Amend the contract in a docs commit: in the same paragraph replace the parenthesis "(`│ GLASS` added once Glass's completeness tests pass)" with "(`CINEMATIC │ GLASS` from the flip release on)", replace that last sentence of §8.0.7 with "At the flip the `LEGACY` segment and the `legacy` skin are deleted and the row keeps `CINEMATIC │ GLASS`, so Glass stays reachable only here while it is built; the row and the `mm-skin-debug` / `mm.skin.debug` override keys are deleted in the release that sets `glass_available` to true (`prompts/release/01-glass-final-release.md`)." and the S5 "What this contract does" cell with "The pre-flip debug row uses that hook (`mm-skin-debug` / `mm.skin.debug`); the flip reduces it to `CINEMATIC │ GLASS` and the Glass release deletes it (§8.0.7)".
2. **Front page file names: the code wins.** `web/24` wrote `front-1-tonight.png` … `front-5-circle.png` into its proof folder, `brand/cinematic/sidestore.md` spells two names differently, and `backend/07` put the served names in `_SHOWCASE`. `_SHOWCASE` in `backend/routes/app_distribution.py` is the source of truth; read it and copy each frame under the name it holds (section F6).
3. **SideStore listing:** exactly the fields `brand/cinematic/sidestore.md` lists, emitted by `build_ios_source`, with both `screenshots` and `screenshotURLs` carrying the same URLs (shared/04 Decision 11). The versions logic is untouched.
4. **The flip resets the web caches.** Every user moves from `legacy` to Cinematic without running the switch flow, so no `skin-changed` message ever reaches the service worker. `RUNTIME_VERSION` in `frontend/public/sw-policy.js` is bumped (the pages, shell, static, state and API caches are dropped on activate; saved chapters under `CONTENT_VERSION` are not), and activation runs the saved-document refresh that `skin-changed` runs, so an offline cold launch never serves legacy HTML (stack risk 7).
5. **Stored `legacy` values are cleaned, not honoured.** A device can still hold `mm-skin=legacy`, `mm-skin-debug=legacy`, `mm.skin.active = legacy` or `mm.skin.debug = legacy`. They are already invalid once `legacy` leaves the `SkinId` lists; boot additionally removes them once (web: rewrite `mm-skin` to `cinematic`, expire `mm-skin-debug`; app: `prefs.remove`), without a restart.
6. **All of `frontend/src/components/` goes**, including `keyboard/` and `command-palette/`, whose logic `web/06` moved to `frontend/src/lib/` (stack §2.2: "`components/` legacy UI, deleted at the Cinematic flip"). On mobile, `lib/shared/widgets/` goes with `features/*/{screens,widgets}` (the boundary test already forbids skins to import any `/widgets/` path); `lib/shared/providers/` stays.
7. **Dependencies.** Web: remove `framer-motion` and `lucide-react` with `npm uninstall` only if nothing under `frontend/src`, `frontend/e2e` or `frontend/scripts` imports them after the deletion; touch no other package. Mobile: remove no package in this step (native-plugin changes need their own isolated commit, stack §3); list every package that only legacy used in the report, for a later cleanup.
8. **Deploying from this VPS.** `ops/vps/push.sh` is written to run on the laptop and reach this box over SSH, and this box cannot SSH to itself (`Host key verification failed`, no key in `authorized_keys`). If `ssh -o BatchMode=yes -o ConnectTimeout=5 ubuntu@135.148.43.147 true` succeeds, run `bash ops/vps/push.sh all`. Otherwise run the local mirror of `push.sh all` in section H5, which runs the same syncs, stamp and `deploy.sh deploy` against the local paths. Never edit `authorized_keys` or SSH configuration.
9. **The APK is built on the owner's laptop.** The signing key (`mobile/android/key.properties`, `*.jks`) never comes to this box, so the owner runs `bash ops/vps/push.sh apk` there (section H6). Never run `flutter build apk`, Gradle or `push.sh apk` on this VPS.
10. **The branch is pushed once; `master` after each working step.** Every push of `feat/vps-slim-source-native` publishes an iOS build to the owner's SideStore source (`ios-build.yml` triggers on that branch only, then `mm-fetch-ios`), so an intermediate branch push would offer the owner a half-deleted app under the old version name. A push to `master` runs only the `tests` workflow and publishes nothing. So: commit small and often; after each working step (sections A+B, C+D, E, F) whose client gates are green (web: `npm run typecheck`, `npm run lint`, `npm run test`; mobile: `flutter analyze`, `flutter test`; backend: `pytest`; always with the RAM guard), push that step to `master` only: `git fetch origin && git merge-base --is-ancestor origin/master HEAD && git push origin HEAD:master` (never force; if `origin/master` is not an ancestor, stop and report). The branch itself is pushed once, in section H1, after every gate in section G is green on the final tree.
11. **The Cinematic confirm's Android icon line** does not apply yet: no alternate icon is registered while the flag is false (§8.0.7, §12.3). Nothing about icons changes in this step.

## Scope: deliver every item below

Sections cited are `cinematic/DESIGN.md` unless another file is named.

### A. Web: Cinematic is the default and `legacy` leaves the skin engine

1. `frontend/src/skins/types.ts`: `export const SKIN_IDS = ["cinematic", "glass"] as const;` and `export const DEFAULT_SKIN: SkinId = "cinematic";` (drop the "release/00 changes this" comment). `SKIN_COOKIE` and `SKIN_DEBUG_COOKIE` stay.
2. `frontend/src/skins/index.ts`: `export const skins = { cinematic, glass } satisfies Record<SkinId, Skin>;`. `Skin.screens` becomes `Record<ScreenId, Screen>` (no `Partial`, since no skin may lack a screen now).
3. `frontend/src/skins/server.ts`: `getSkin()` keeps its precedence: (1) `mm-skin-debug` when it holds a valid `SkinId`, `glass` included; (2) `mm-skin` when valid, with `glass` resolving to `cinematic` while `FLAGS.glassAvailable` is false (§8.0.7); (3) `DEFAULT_SKIN`, now `cinematic`. `renderScreen` loses its `notFound()` branch for a missing screen (the type now guarantees one).
4. `frontend/src/features/skin/boot.ts` (`resolveBootSkin`) and `SkinBoot.tsx`: `defaultSkin` is `DEFAULT_SKIN` (`cinematic`). One-time cleanup in `SkinBoot` (Decision 5): if `readCookie("mm-skin") === "legacy"`, `writeSkinCookie("mm-skin", "cinematic")`; if `readCookie("mm-skin-debug") === "legacy"`, `clearSkinCookie("mm-skin-debug")`; no restart, because the server already ignored both. Extend `boot.test.ts`: a profile with `skin: null` and the mirror `cinematic` → no restart (it used to restart into legacy); a profile with `skin: "glass"` and the flag false → no restart, the stored value kept; the two cleanup cases.
5. `frontend/src/app/(app)/layout.tsx`: `generateViewport()` returns `{ themeColor: "#000000", colorScheme: "dark", viewportFit: "cover" }` for every skin (the legacy light and dark pair goes).
6. `frontend/next.config.ts`: delete `redirects()` and its comment (§8.0.3 `tonight`); keep `output: "standalone"`, `experimental` (`proxyTimeout: 120_000`, `viewTransition: true`), the array-form `rewrites()` and `images`. In `headers()` the no-cache source becomes `/:path(sw.js|sw-policy.js|offline-fallback-cinematic.html|offline-fallback-glass.html)` (the legacy `offline-fallback.html` leaves the list with the file, item 8); the two headers stay. `/` now renders Tonight for everyone.
7. `frontend/src/app/manifest.ts` (§12.3): `name` `"ManhwaManiacs"`, `short_name` `"Maniacs"`, `id` `"/"`, `start_url` `"/"`, `scope` `"/"`, `display` `"standalone"`, `background_color` and `theme_color` `"#000000"`, `icons` 192, 512 and maskable 512 (the `shared/04` files), and no `orientation` key; fix whichever differs.
8. Service worker (Decision 4), `frontend/public/sw.js` and `frontend/public/sw-policy.js`:
   - the `"skin"` and `"skin-changed"` messages validate against `["cinematic", "glass"]`;
   - the offline navigation branch serves `offline-fallback-glass.html` when the stored skin is `glass` and `offline-fallback-cinematic.html` otherwise (also when nothing, or an old `legacy`, is stored); `OFFLINE_URL` becomes `"/offline-fallback-cinematic.html"`; `frontend/public/offline-fallback.html` is deleted and removed from the precache list;
   - `RUNTIME_VERSION` goes up by one (for example `"v3"` → `"v4"`; read the current value); `CONTENT_VERSION` does not change;
   - the saved-document refresh that the `"skin-changed"` case runs (walk every cache whose `policy.parseCacheName(name).kind === "offline"`, re-fetch each stored `text/html` response with `credentials: "include"` and `cache.put` it when `policy.isCacheableResponse` passes; a failed fetch keeps the old copy) becomes one named function, `refreshSavedDocuments()`, called from `"skin-changed"` as before and from `activate` after the old caches are deleted (not awaited by `waitUntil`, so activation never blocks on the network);
   - tests in `frontend/src/features/offline/sw-integration.test.ts` and `policy-contract.test.ts`: an offline navigation with `legacy` or nothing stored serves the Cinematic page; activation deletes `-pages-<old RUNTIME_VERSION>` and keeps `-offline-<CONTENT_VERSION>-u…p…`; activation re-fetches a saved HTML document and stores the fresh copy; an offline activation keeps the old copy.
9. `frontend/src/features/preferences/appearance-boot-source.ts` stops stamping `data-theme` and `data-preset` and keeps the `mm.boot.a11y` channel (stack §3 "reduced to stamping reader preferences"); `appearance-boot.test.ts` drops the theme and preset cases and keeps the a11y ones.
10. Every test, spec and script that names `legacy` as a skin is updated: `grep -rn "legacy" frontend/src/skins frontend/src/features/skin frontend/src/features/offline frontend/e2e frontend/scripts --include=*.ts --include=*.tsx --include=*.mjs`. In `frontend/e2e`, the `web/24` assertions "Legacy users see no change" are deleted (there are no legacy users); the Cinematic specs otherwise run unchanged. In `frontend/scripts/proof.mjs` the `--skin` flag accepts `cinematic | glass` only (its `--help` table and its validation), still writing `mm-skin-debug`.

### B. Web: delete the legacy UI

Work in this order: an inventory, then no-pixel rescue commits, then the deletions.

1. **Inventory.** `git ls-files frontend/src/skins/legacy frontend/src/components 'frontend/src/features/*/components' frontend/scripts/themes > docs/redesign/proof/release-00/deleted-web.txt`, plus the theme files of item 4.
2. **Kept importers.** List every kept file that imports something you are about to delete:
   ```bash
   grep -rlE "@/components/|@/skins/legacy|/components/|features/[a-z-]+/components|themes\.generated|preset-store|theme-store|legacy-bridge" frontend/src --include=*.ts --include=*.tsx --include=*.css \
     | grep -vE "^frontend/src/(components|skins/legacy)/|^frontend/src/features/[^/]+/components/"
   ```
   and every `frontend/src/features/*/index.ts` barrel that re-exports from `./components/…`. For each hit: if the importer is legacy-only (for example `frontend/src/config/more-nav.ts` and `config/settings-tabs.ts`, which only the legacy shell reads; confirm with `grep -rn "@/config/<name>" frontend/src`), it is deleted too and added to the inventory; if it is kept code that needs logic living in a legacy folder (for example `app/(app)/layout.tsx` rendering `ServiceWorkerBoundary` from `@/features/offline`), move that logic-only module out of `components/` into `frontend/src/features/<feature>/<Name>.tsx` (tests move beside it) in its own commit, `refactor(web): move ServiceWorkerBoundary out of legacy components`, with no pixel and no behaviour change; barrels drop their `./components/*` re-exports.
3. **Status screens.** `frontend/src/app/(app)/not-found.tsx`, `frontend/src/app/(app)/error.tsx` and `frontend/src/app/global-error.tsx` must not import legacy UI. If one still does, replace its body with the Cinematic §8.32 status screen the Cinematic skin already exports (find it with `grep -rln "Nothing here\|NOT IN THIS ISSUE\|StatusScreen" frontend/src/skins/cinematic`): `not-found.tsx` is a server component that renders it; `error.tsx` (a client component) renders it with its `reset` wired to the screen's retry action. Every skin shows Cinematic's status screens until the Glass step that builds glass §8.28 switches them per skin.
4. **Delete** (one commit per group, each followed by `npm run typecheck`):
   - `frontend/src/skins/legacy/` (the moved page bodies, `index.ts`, `fonts.ts` with the Syne and DM Sans faces);
   - `frontend/src/components/` whole (`ui/`, `layout/`, `premium/`, `settings/`, `keyboard/`, `command-palette/`; first check that `frontend/src/lib/command-palette/{commands,fuzzy}.ts` and `frontend/src/lib/keyboard/` exist, and move them now if `web/06` did not);
   - every `frontend/src/features/*/components/` folder (today: admin, auth, backup, bookmarks, content-mode, library, novels, ocr, offline, preferences, profiles, reader, sources, updates; delete whatever exists then);
   - the theme, preset and accent system in `frontend/src/features/preferences/`: `theme.ts`, `theme-store.ts`, `theme-types.ts`, `themes.generated.ts`, `presets.ts`, `preset-store.ts`, `theme-css.testkit.ts`, `shape-css.testkit.ts`, `theme.test.ts`, `theme-contrast.test.ts`, `preset.test.ts`, `preset-contrast.test.ts`, `shape-tokens.test.ts`, `glass-cost.test.ts` (it measures the legacy glass preset), and the theme and preset exports of `hooks.ts`, `api.ts` and `index.ts`; keep `mature-gate.ts` and its test, `appearance-boot-source.ts`, `appearance-boot.tsx`, `appearance-boot.test.ts` and the content-preference hooks (`useContentPreferences`, `useMatureToggleBlockReason`, `useSetMatureContent`);
   - `frontend/scripts/themes/` whole (`audit.json`, `base16-cache.json`, `build-themes.mjs`, `curated.mjs`, `fetch-base16.mjs`, `map.mjs`);
   - `frontend/src/app/presets.css`, `frontend/src/app/themes.generated.css`, and in `frontend/src/app/globals.css` their two `@import` lines, the `@import "../skins/legacy-bridge.css";` line and the legacy `@theme { … }` block (the generated `@theme inline` block of `theme.generated.css` now defines every shared key alone);
   - `frontend/src/skins/legacy-bridge.css` and `frontend/src/skins/legacy-bridge.test.ts`;
   - `frontend/src/app/motion.test.ts` keeps only assertions about rules that still exist in `globals.css`; if none remain, delete the file.
5. **Dead-file sweep.** For each non-test file under `frontend/src/{features,lib,config,stores,services,types}` whose name matches `theme|preset|accent|palette|shell|nav`, run `grep -rn "<its import path>" frontend/src`; a file with no importer other than its own test is deleted only when it served the legacy theme, preset, accent or navigation system; any other unimported file is listed in the report, not deleted.
6. **Dependencies** (Decision 7): `grep -rln "framer-motion" frontend/src frontend/e2e frontend/scripts` and the same for `lucide-react`; for each with no hit, `free -m && npm uninstall <package>` in `frontend/`.
7. **The completeness test** (`frontend/src/skins/completeness.test.ts`) never imported `legacy`; confirm it still passes and still asserts `MUST_BE_COMPLETE = { cinematic: true, glass: false }`. The lint boundary in `frontend/eslint.config.mjs` drops the patterns that name `legacy` (`@/skins/legacy`, `@/skins/legacy/**`, `../legacy/**`, `../../legacy/**`, `../../../legacy/**`) and the now-missing `@/components` targets stay banned (harmless and future-proof).
8. **Evidence of the deletion.** `docs/redesign/proof/release-00/deleted-tests.md` lists every deleted web test file with its case count (from the `before.txt` vitest JSON or `npx vitest list <file> | wc -l` before deleting). After the build, `find frontend/.next/static -name '*.css' -exec grep -l 'data-theme\|data-preset' {} +` prints nothing and `ls frontend/src/components frontend/src/skins/legacy` fails.

### C. Mobile: Cinematic is the default and `legacy` leaves the skin engine

1. `mobile/lib/skins/skin.dart`: `enum SkinId { cinematic, glass }`; `const SkinId kDefaultSkin = SkinId.cinematic;`; `skinFor` and every `switch` over `SkinId` lose the legacy case; `skinIdFromName('legacy')` returns `null`.
2. `SkinBoot` (`mobile/lib/main.dart` or the file `mobile/01` put it in; `grep -rn "class SkinBoot" mobile/lib`): `resolveSkin` and `read` ignore an invalid name as before, and additionally `prefs.remove` a stored `legacy` in `mm.skin.active` or `mm.skin.debug` (Decision 5). Tests in `mobile/test/skins/`: both removals; with no keys the app boots into `cinematic`; a stored `glass` in `mm.skin.active` still boots `cinematic` while `Flags.glassAvailable` is false.
3. `resolveBootRestart(…, defaultSkin: kDefaultSkin)`: a profile with `skin == null` while the app runs Cinematic → `null` (no restart); update its tests.
4. `mobile/lib/app/skin_app.dart` and `main.dart` lose every legacy branch (the legacy `ThemeData`, overlay style and the `WhatsNewAutoShow` wrapper). The what's-new resume hook must live in a provider under `mobile/lib/features/settings/providers/` (glass §8.28 row "App update"); if it is still in `features/settings/widgets/whats_new_auto_show.dart`, move it there first in a no-pixel commit, `refactor(mobile): move the what's-new resume hook into a provider`. `DownloadsLifecycleGate` stays mounted for every skin (downloads resume after a restart, stack §2.5 step 7).
5. `mobile/lib/app/app.dart` (`typedef ManhwaManiacsApp = SkinApp;`) is deleted once no kept file or test imports it (after section D).

### D. Mobile: delete the legacy UI, and the tests that replace its widget tests

1. **Inventory** into `docs/redesign/proof/release-00/deleted-mobile.txt`: `git ls-files mobile/lib/skins/legacy 'mobile/lib/features/*/screens' 'mobile/lib/features/*/widgets' mobile/lib/shared/widgets mobile/lib/app/theme mobile/lib/app/router mobile/tool/themes`.
2. **Kept importers:**
   ```bash
   grep -rlE "/(screens|widgets)/|app/theme/|app/router/|skins/legacy/" mobile/lib --include=*.dart \
     | grep -vE "^mobile/lib/(skins/legacy|shared/widgets|app/theme|app/router)/|^mobile/lib/features/[^/]+/(screens|widgets)/"
   ```
   For each hit: logic that lives in a widget file moves into `features/<feature>/{providers,utils,controllers}/` in its own no-pixel commit (stack §2.3 "Logic that lives in a widget moves first"); a path constant from `app/router/routes.dart` is replaced by the generated, percent-encoding builders of `mobile/lib/skins/contract.g.dart` (`Routes.…`, §8.0.3 "Encoded route builders"); a colour or metric from `app/theme/` used by kept code (for example a notification colour) is replaced by the active skin's token (`CineTokens`).
3. **Delete** (one commit per group, `flutter analyze` after each): `mobile/lib/skins/legacy/`; every `mobile/lib/features/*/screens/` and `mobile/lib/features/*/widgets/`; `mobile/lib/shared/widgets/`; `mobile/lib/app/theme/` whole (including `app_palettes.generated.dart`, `app_theme_provider.dart`, `theme_controller.dart`, `preset_controller.dart`); `mobile/lib/app/router/app_router.dart` and `mobile/lib/app/router/routes.dart` (and the folder); `mobile/tool/themes/build_palettes.dart` (and the folder). `mobile/lib/app/display/high_refresh_rate.dart`, `mobile/lib/app/app_restart.dart` and `skin_app.dart` stay.
4. **Legacy tests.** `flutter analyze` now reports every test that imports a deleted file. A test file is deleted only when everything it tests was deleted; a file that also tests kept logic keeps those cases (split it). Expected candidates: the `screens` and `widgets` tests under `mobile/test/features/*`, `mobile/test/app/theme/` (8 files), `mobile/test/app/router/` (4 files: `downloads_tab_test.dart`, `more_navigation_test.dart`, `profile_gate_test.dart`, `routes_test.dart`), `mobile/test/shared/widgets/`, `mobile/test/widget_test.dart`, and the legacy skin in the screenshot harness loop (`mobile/test/screenshots/`, which loops over the skins; drop `legacy` from the loop). Add every deleted file with its case count to `deleted-tests.md`. The logic suites (`test/features/*` repositories, providers, stores, queues and outboxes, `test/core`, `test/audit`, `test/android`) stay and must stay green.
5. **What replaces them** (stack §2.3):
   - `mobile/test/skins/completeness_test.dart` (strict for Cinematic since `mobile/24`) drops `SkinId.legacy` and keeps the lenient Glass check;
   - `mobile/test/skins/import_boundary_test.dart` drops its legacy exemptions; its banned list stays;
   - **one smoke test per cluster for Cinematic.** For each cluster below, confirm a test under `mobile/test/skins/cinematic/` pumps the cluster's screens through the real Cinematic router with fixture providers and asserts its level-1 heading and a working primary action (`grep -rln "smoke" mobile/test/skins/cinematic`). For every cluster without one, add a `group` to a new `mobile/test/skins/cinematic/smoke/cluster_smoke_test.dart` that reuses `mobile/test/skins/cinematic/qa/qa_screens.dart` (`mobile/24`) and, per screen: asserts exactly one `Semantics` node with `isHeader` and `headingLevel == 1`; finds the first widget of the Cinematic button primitive with the `primary` variant (§7.1), or on a screen without one the first tappable row (§7.16); taps it; and asserts `tester.takeException()` is null. Clusters: auth (`login`, `register`, `profiles`, `profileNew`, `profileEdit`, `profilesManage`, `setup`); Tonight (`tonight`); Library (`library`, `updates`, `collections`, `collection`, `history`, `bookmarks`); series (`feature`, `featureByFollow`); manga reader (`reader`, `readAll`, and `readerLanding`, which in the app is a redirect: assert it lands on `/library` with the Library h1 instead of tapping an action); novel (`novel`); Discover (`discover`, `sources`, `source`, `dialogue`, `picks`); Downloads and Index (`downloads`, `index`, `status`); Settings (`settings`); recap (`recap`); The Numbers (`numbers`, `annual`); Circle (`circle`, `circleMember`); onboarding (`onboarding`). Write the cluster → test file mapping into `deleted-tests.md` under "Replacements".
6. `mobile/test/skins/cinematic/qa/cinematic_qa_test.dart` and the other `mobile/24` suites lose their "debug row on LEGACY" cases; everything else runs unchanged.

### E. The debug row: `CINEMATIC │ GLASS`

1. **Web.** Find the list with `grep -rn "DEBUG_SKINS" frontend/src`. It becomes `export const DEBUG_SKINS = ["cinematic", "glass"] as const;` (if `web/02`'s comment on the list still says anything but that `release/00` adds `"glass"`, replace it; this step adds it, and `web/25` only checks it) with labels `CINEMATIC` and `GLASS` (13 px, weight 600, uppercase, letter-spacing 0.12em). Everything else stays as `web/02` D built it: native radio inputs inside labels (arrow keys and Space move between segments), each segment at least 44 px tall and 120 px wide with a 1 px `rgba(255,255,255,0.40)` border and the checked one filled `#FFFFFF` with `#000000` text, the `aria-live="polite"` status "Restarting in Cinematic…" / "Restarting in Glass…", the 200 ms (`dur.clip`) fade to black, `restartInto({ cookie: "mm-skin-debug", … })` with the return path `/settings/diagnostics?debug=1`, and "Clear override", which expires `mm-skin-debug` and restarts into the resolved skin (now Cinematic). The row never writes `reading_profiles.skin`. `/settings/diagnostics` still shows the row only with `?debug=1` or `sessionStorage['mm.debug'] = "1"`, and otherwise replaces itself with `/settings`.
2. **Mobile.** `const List<SkinId> kDebugSkins = [SkinId.cinematic, SkinId.glass];` in `mobile/lib/skins/skin.dart` (delete `mobile/01`'s comment on the list: this step adds `SkinId.glass`, and `mobile/25` only checks it). The row lives in Cinematic Settings → Diagnostics as `Edition (debug)` (the legacy Diagnostics screen is gone with section D); segments `CINEMATIC` and `GLASS`, each at least 120 × 44 logical px, 48 dp tall on Android (§14.6); choosing a segment calls `debugSwitchSkin` (200 ms `dur.clip` fade, restart, return route `/settings/diagnostics`); "Clear override" restarts into `SkinBoot.resolveSkinWithoutDebug` (now Cinematic).
3. Choosing `GLASS` on either client restarts into the Glass skeleton: every screen is the skin-neutral pending screen, whose "Leave the preview" button clears the override and returns to Cinematic. This is exactly what `web/25` and `mobile/25` check before they start.
4. No rendering of the row names `LEGACY` any more: `web/18` item 13 and `mobile/18` item 14 put the row inside Cinematic's Diagnostics too, so after E1 and E2 `grep -rni "legacy" frontend/src/skins frontend/src/features/skin mobile/lib/skins mobile/lib/app` prints nothing (fix every hit to read the `DEBUG_SKINS` / `kDebugSkins` lists).
5. The DESIGN.md amendment of Decision 1, as its own commit `docs(redesign): the debug row keeps CINEMATIC | GLASS after the flip`.

### F. Release metadata

1. **`mobile/pubspec.yaml`:** read `version: X.Y.Z+N` and write `version: X.(Y+1).0+(N+1)` (both halves; for example `3.4.3+56` → `3.5.0+57`). The `+N` is the Android `versionCode`, which is what phones compare; the iOS build number stays automatic (`1000 + github.run_number`).
2. **`frontend/package.json`:** the `"version"` field goes to the next minor with patch 0 (for example `2.6.1` → `2.7.0`), edited by hand. `package-lock.json`'s root `"version"` (`0.1.0`) is not the app version; leave the lock alone.
3. **`backend/routes/app_distribution.py` `_RELEASE_NOTES`:** a new first `ChangelogEntry` with `version` and `build` equal to the new pubspec halves and `date` the month and year of the release day in the existing style (`"October 2026"`). Highlights in the voice of the existing entries (plain full sentences, no exclamation marks), one string each, keeping only what the `web-24` and `mobile-24` proof shows shipped:
   - "A new look for every screen: Cinematic, a black, magazine-style edition with film-title type, posters that fill the screen and a front page called Tonight"
   - "Tonight chooses what to read next for each profile: a cover story, rows picked for you, and a short \"Previously on\" recap before you return to a series you left a while ago"
   - "The Numbers: chapters per day, time read, a streak flame, and The Annual, your year in chapters, with cards you can save and share"
   - "Circle: see what the other profiles are reading, react to chapters, share shelves and pass a series on, always within each profile's privacy and 18+ settings"
   - "Reading extras: auto-scroll with a speed control, background soundscapes, a panel-by-panel view for manhwa, and reader controls tinted by the page"
   - "A welcome for new profiles, rebuilt Settings, a new app icon and a new install page"
   - "A second edition, Glass, is being built and arrives in a later update"
4. **`build_ios_source`** (the returned dict, around the `"apps"` entry), per `brand/cinematic/sidestore.md` (Decision 3): `"tintColor": "#F4D03F"`; the app's `"subtitle": "Every source, one shelf."`; the app's `"localizedDescription": "Every source. One shelf. Novels, read aloud. Your year in chapters. Read together."`; `"iconURL": f"{base}/app/media/app-icon.png"` (the file is the new 1024 icon from `shared/04`); `"screenshots"` and `"screenshotURLs"`, both the same list of `f"{base}/app/media/{name}"` for the `_SHOWCASE` names whose files exist (the `backend/07` filter). `"name"` stays `"ManhwaManiacs"`. Replace the stale comment about server-side downloads with one line: "The listing text is the Cinematic brand copy (cinematic §12.3); both editions share one listing (glass §12.6)." Tests in `backend/tests/test_app_distribution.py`: `test_ios_source_carries_the_cinematic_listing` (the four values and both screenshot keys equal, listing only the frames present in a temp `SCREENSHOTS_DIR`), and `test_release_notes_match_pubspec` (reads `REPO_ROOT / "mobile" / "pubspec.yaml"`, asserts `_RELEASE_NOTES[0].version` and `.build` equal its two halves; skipped with a reason when the file is absent), so a missing entry fails CI before `deploy.sh`'s deployed-code check has to roll back.
5. **Install page:** `backend/07` already rebuilt it; check that `GET /` on the dev stack renders the "Front pages" section once F6 has put the frames in place (five `<figure>`s, captions as `alt`).
6. **Front pages into the served folder** (Decision 2). Read `_SHOWCASE`; copy `docs/redesign/proof/web-24/front-pages/front-1-tonight.png`, `front-2-reader.png`, `front-3-listen.png`, `front-4-annual.png`, `front-5-circle.png` to `mobile/docs/screenshots/` under the five `_SHOWCASE` names in order (expected `front-01-every-source.png`, `front-02-long-scroll.png`, `front-03-novels-read-aloud.png`, `front-04-year-in-chapters.png`, `front-05-read-together.png`). Assert each is 1320 × 2868 (`python3 -c "import struct,sys; b=open(sys.argv[1],'rb').read(24); print(struct.unpack('>II', b[16:24]))" <file>`). Delete the legacy `mobile/docs/screenshots/shot-library.png`, `shot-novels.png`, `shot-statistics.png` and `shot-themes.png` after `grep -rn "shot-library\|shot-novels\|shot-statistics\|shot-themes" --include=*.py --include=*.ts --include=*.dart --include=*.sh . | grep -v node_modules` finds only tests you update. `app-icon.png` stays.
7. **Edition preview frames** (§8.30.3: "regenerated whenever either skin's Tonight changes, a step of the release checklist"). If the newest commit touching `mobile/lib/skins/cinematic/screens/tonight` (`git log -1 --format=%ct -- <that folder>`) is newer than the newest commit touching `mobile/assets/skin_previews/cinematic/`, rerun the `mobile/18` capture, `free -m && MM_WRITE_PREVIEWS=1 /srv/manhwamaniacs/dev/flutter/bin/flutter test test/screenshots/skin_previews/cinematic_preview_frames_test.dart` in `mobile/`, and commit the 36 frames. The web preview is a live iframe (`/skin-preview/cinematic`) and needs nothing.
8. **`mobile/RELEASE.md`:** replace the NAS-era "Deploy & verify" block (it names `ops/deploy.sh production`) with a section "Release checklist (VPS)" of numbered lines naming, in order, the steps of sections F to I of this file: bump both pubspec halves and `frontend/package.json`; add `_RELEASE_NOTES`; regenerate edition previews when a Tonight changed; gates one at a time; push `master` after each working step and the branch once at the end; wait until `/app/source.json` serves the new build (`sudo systemctl start mm-fetch-ios.service` every 5 minutes; `gh run list` when `gh` is logged in; never poll the GitHub API anonymously); back up the database; check that the synced paths have no uncommitted file; deploy web and backend (`ops/vps/push.sh all` from the laptop, or the local mirror from the VPS); `ops/vps/push.sh apk` on the laptop; start `mm-fetch-ios`; check `/api/app/changelog`, `/app/version` and `/app/source.json`.

### G. Gates, one at a time

RAM guard before every command: `free -m`, read the `available` column of `Mem:`; under 1024 MB, stop and report. `pgrep -af "next build|next dev|vitest|flutter_tester|pytest|uvicorn"` must show nothing of yours or another session's before a heavy command; wait for it to finish. Stop the dev stack and `next dev` before the first build.

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs/backend && free -m && .venv/bin/python -m pytest -q --no-header 2>&1 | tail -5
cd /srv/manhwamaniacs/dev/ManhwaManiacs && node design/build.mjs --check && node brand/check.mjs
cd frontend && free -m && npm run typecheck
free -m && npm run lint        # baseline: 0 errors, 0 warnings
free -m && npm run test
free -m && npm run build       # baseline: 0 errors, 0 warnings
cd ../mobile && free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze   # "No issues found"
free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter test
```

Pass: backend passed count ≥ its floor plus your two new tests, 0 failed; web and Flutter counts ≥ their floors minus exactly the cases listed in `deleted-tests.md`, plus the new tests, 0 failed, 0 skipped. Save every command's tail into `docs/redesign/proof/release-00/gates.txt` with the `free -m` figure before it. Any red gate: `superpowers:systematic-debugging`, fix in its own commit, then rerun that gate and every gate after it.

### H. Ship web, Android and iOS together

1. **Push the branch once** (Decision 10). `git status --porcelain` shows none of your paths; `git fetch origin`; `git merge-base --is-ancestor origin/feat/vps-slim-source-native HEAD` succeeds (otherwise stop: someone pushed from elsewhere). Record the iOS build the source serves now: `PREV_IOS=$(curl -fsS https://app.manhwamaniacs.xyz/app/source.json | python3 -c 'import json,sys; v=json.load(sys.stdin)["apps"][0]["versions"]; print(v[0]["buildVersion"] if v else 0)')`. Then:
   ```bash
   git push origin feat/vps-slim-source-native:master
   git fetch origin && git merge-base --is-ancestor origin/master HEAD && git push origin HEAD:master
   ```
   If `origin/master` is not an ancestor, stop and report; never force-push. Record `SHA=$(git rev-parse HEAD)`.
2. **Reading CI.** If `command -v gh && gh auth status` succeeds, use `gh run list --commit "$SHA" --limit 10` and `gh run view <id> --json jobs --jq '.jobs[] | {name, conclusion, steps: [.steps[] | select(.name == "Publish the .ipa as a release asset") | .conclusion]}'`, polling every 3 minutes. Otherwise do not install `gh` and **do not poll the GitHub API** (the owner's rule: 60 anonymous requests an hour, shared with `mm-fetch-ios`, ran out during an earlier release). Wait on our own server instead: every 5 minutes run `sudo systemctl start mm-fetch-ios.service` and read `curl -fsS https://app.manhwamaniacs.xyz/app/source.json | python3 -c 'import json,sys; v=json.load(sys.stdin)["apps"][0]["versions"][0]; print(v["version"], v["buildVersion"])'` (a background until-loop or the Monitor tool, never a busy loop). The wait ends when `version` is the new `X.Y.0` and `buildVersion` is greater than `$PREV_IOS`: `mm-fetch-ios` only finds a release that the step "Publish the .ipa as a release asset" created, and that step runs only when the `tests` job inside the iOS run succeeded, so this proves both. Then, once, record the runs for the report with at most two anonymous calls from this VPS:
   ```bash
   API=https://api.github.com/repos/yash-dhanda/ManhwaManiacs
   curl -fsS "$API/actions/runs?head_sha=$SHA&per_page=10" | python3 -c 'import json,sys; [print(r["id"], r["name"], r["run_number"], r["status"], r["conclusion"], r["html_url"]) for r in json.load(sys.stdin)["workflow_runs"]]'
   curl -fsS "$API/actions/runs/<IOS_RUN_ID>/jobs?per_page=50" | python3 -c 'import json,sys; [print(j["id"], j["name"], s["name"], s["conclusion"]) for j in json.load(sys.stdin)["jobs"] for s in j["steps"] if s["name"].startswith(("Publish","pytest","Unit","Production","Static"))]'
   ```
   If 60 minutes pass without the new build in `source.json`, make those same two calls once to find the failing job and step, then read that job's annotations once (`$API/check-runs/<job_id>/annotations`, anonymous). A `skipped` Publish step means its `tests` job failed or was cancelled, and nothing was published. Runner-side failures (`ENOTFOUND`, `Request timeout`, `Failed to CreateArtifact`) are fixed by `gh run rerun <id> --failed` or, without `gh`, by asking the owner to press "Re-run failed jobs"; a code failure is fixed, committed, gated again (section G for the touched client) and pushed again. Web, backend and Android move only after iOS has built, so a failed iOS build never leaves the three platforms on different versions.
3. **Nothing heavy is running.** Stop the dev stack, `next dev` and any Playwright browser. `free -m`: under 1024 MB available, wait and re-check; the deploy runs `next build` inside Docker, and two `next build`s never run at once.
4. **Back up the production database** (this release runs the Alembic migrations of `backend/00` to `backend/09` at container start, and `deploy.sh rollback` refuses to cross a migration): `sudo systemctl start mm-db-backup.service`, then `systemctl show -p Result --value mm-db-backup.service` prints `success` and `tail -3 /srv/manhwamaniacs/backups/backup.log` shows a line from the last minutes.
5. **Deploy web and backend** (Decision 8). `push.sh` and its mirror sync the working tree, not a commit, and other sessions work in this checkout, so first prove the tree is exactly `$SHA`: `test "$(git rev-parse HEAD)" = "$SHA"` and `git status --porcelain -- frontend backend ops mobile/pubspec.yaml mobile/docs/screenshots` prints nothing (another session's uncommitted or untracked file there would reach production: stop, report the paths, and wait for the owner). If SSH to the box works, `bash ops/vps/push.sh all`. Otherwise, the local mirror of `push.sh all` (its gates already ran in section G on this exact `HEAD`):
   ```bash
   REPO=/srv/manhwamaniacs/dev/ManhwaManiacs
   LIVE=/srv/manhwamaniacs/app
   EXCL=(--exclude .git --exclude node_modules --exclude .next --exclude .venv --exclude __pycache__ \
         --exclude '*.pyc' --exclude .pytest_cache --exclude manhwamaniacs.db --exclude build \
         --exclude .dart_tool --exclude .gradle --exclude .cxx --exclude captures \
         --exclude key.properties --exclude '*.jks' --exclude '*.keystore' --exclude .env)
   for d in frontend backend ops; do rsync -a --delete "${EXCL[@]}" "$REPO/$d/" "$LIVE/$d/"; done
   rsync -a --inplace "$REPO/mobile/pubspec.yaml" "$LIVE/mobile/pubspec.yaml"
   rsync -a --delete "${EXCL[@]}" "$REPO/mobile/docs/screenshots/" "$LIVE/mobile/docs/screenshots/"
   printf '%s  %s  %s\n' "$(git -C "$REPO" rev-parse --short HEAD)" "$(date -u +%FT%TZ)" feat/vps-slim-source-native > "$LIVE/.deploy-info"
   cd "$LIVE" && bash ops/vps/deploy.sh deploy 2>&1 | tee "$REPO/docs/redesign/proof/release-00/deploy.log"
   ```
   `deploy.sh` builds both images, waits for health, checks that the mounted pubspec and the compiled changelog agree, checks the public URL, and rolls back on any failure. If the log shows `ROLLED BACK` or `DEPLOY NOT VERIFIED`, stop and report with the log; do not retry blindly.
6. **Android: the owner publishes the signed APK.** Send the owner this block with `<SHA>` and `<X.Y.0+N>` filled in, and wait for the reply with the output of its last two commands:
   ```bash
   # On the laptop, in the checkout that holds mobile/android/key.properties
   git status --short                            # must print nothing
   git remote -v                                 # use the remote that points at github.com:yash-dhanda/ManhwaManiacs
   git fetch <remote> && git checkout feat/vps-slim-source-native && git merge --ff-only <remote>/feat/vps-slim-source-native
   git rev-parse --short HEAD                    # must print <SHA>
   grep '^version:' mobile/pubspec.yaml          # must print version: <X.Y.0+N>
   bash ops/vps/push.sh apk                      # builds FLAVOR=prod with the baked HTTPS URL, checks version, ABIs and URL, publishes, syncs the pubspec
   sha256sum mobile/build/app/outputs/flutter-apk/app-release.apk
   ```
   Then on this box `sha256sum /srv/manhwamaniacs/apk/app-release.apk` must print the owner's hash.
7. **iOS.** The Publish step already succeeded (item 2). When item 2 waited through `gh`, `sudo systemctl start mm-fetch-ios.service` now (instead of waiting up to 15 minutes for the timer); either way `journalctl -u mm-fetch-ios.service -n 20 --no-pager` shows the new build published into `/srv/manhwamaniacs/ipa`.

### I. Verify, and prove it

Save every command and its output to `docs/redesign/proof/release-00/verify.txt`.

```bash
curl -fsS https://manhwamaniacs.xyz/api/app/changelog | python3 -c 'import json,sys; e=json.load(sys.stdin)["entries"][0]; print("changelog", e["version"], e["build"])'
curl -fsS https://app.manhwamaniacs.xyz/app/version     # {"version": "<X.Y.0>", "build": <N>, "apk": "/app/download"}
curl -fsS https://app.manhwamaniacs.xyz/app/source.json | python3 -c 'import json,sys; a=json.load(sys.stdin)["apps"][0]; v=a["versions"][0]; print("ios", v["version"], v["buildVersion"], a["subtitle"], a["localizedDescription"]); print(a["screenshots"] == a["screenshotURLs"], len(a["screenshots"]))'
curl -fsS https://app.manhwamaniacs.xyz/app/source.json | python3 -c 'import json,sys; print(json.load(sys.stdin)["tintColor"])'   # #F4D03F
for u in $(curl -fsS https://app.manhwamaniacs.xyz/app/source.json | python3 -c 'import json,sys; print(" ".join(json.load(sys.stdin)["apps"][0]["screenshots"]))'); do curl -s -o /dev/null -w "%{http_code} $u\n" "$u"; done
curl -sI https://manhwamaniacs.xyz/ | grep -i '^location' || echo "no redirect"      # must not point at /library
curl -fsS https://manhwamaniacs.xyz/login | grep -o 'data-skin="[a-z]*"' | head -1     # data-skin="cinematic"
curl -fsS https://manhwamaniacs.xyz/login | grep -c 'theme-color" content="#000000"'   # 1
docker ps --format '{{.Names}} {{.Status}}' | grep manhwamaniacs                        # both "(healthy)"
```

Pass: the changelog, `/app/version` and `source.json` name the same new version; the changelog build and `/app/version` build are both `N` (the new pubspec code, proving the served APK is the new one); `buildVersion` equals `1000 +` the `run_number` of the iOS run for `$SHA`; five screenshot URLs, each 200; the Publish step is green.

**Visual proof.**
1. Before the ship, on the dev stack (never production data): `free -m && backend/scripts/dev_stack.sh start` (seed it with `backend/scripts/dev_stack.sh seed` if `status` shows an empty database), then in `frontend/` `free -m && NEXT_PUBLIC_API_URL=/api BACKEND_INTERNAL_URL=http://127.0.0.1:8010 npm run dev -- --port 3010`. Signed in as `demo` (password in `backend/scripts/README-dev-stack.md`) and with **no** `mm-skin` or `mm-skin-debug` cookie (so the default is what you see), capture with `frontend/scripts/proof.mjs` (run `node scripts/proof.mjs --help` first; its real flags win) at 1440 × 900 and 390 × 844 into `docs/redesign/proof/release-00/dev/`: `MM_PROOF_USER=demo MM_PROOF_PASSWORD=<from README-dev-stack.md> node scripts/proof.mjs --step release-00/dev --routes "/,/library,<a reader route from GET /api/library/continue-reading>,/settings/appearance,/settings/diagnostics?debug=1,/no-such-page"` (Tonight, Library, the reader, the Glass `NEXT ISSUE` plate, the `CINEMATIC │ GLASS` row, the Cinematic 404), then `node scripts/proof.mjs --step release-00/dev --skin glass --routes "/"` (the Glass pending screen the `GLASS` segment restarts into). Review each with `impeccable` and `taste-skill`: nothing of the legacy app may remain. Stop `next dev` and `backend/scripts/dev_stack.sh stop` before section G's build.
2. After the ship, save this script as `docs/redesign/proof/release-00/shoot-live.mjs` and run `node docs/redesign/proof/release-00/shoot-live.mjs docs/redesign/proof/release-00/live` (public pages only; never sign in to production):
   ```js
   import { createRequire } from "node:module";
   import { mkdirSync } from "node:fs";
   const require = createRequire("/srv/manhwamaniacs/dev/ManhwaManiacs/frontend/package.json");
   const { chromium } = require("playwright");
   const out = process.argv[2]; mkdirSync(out, { recursive: true });
   const pages = [["login", "https://manhwamaniacs.xyz/login"], ["install", "https://app.manhwamaniacs.xyz/"]];
   const browser = await chromium.launch();
   for (const [w, h, dpr] of [[1440, 900, 1], [390, 844, 3]]) {
     const ctx = await browser.newContext({ viewport: { width: w, height: h }, deviceScaleFactor: dpr, hasTouch: w < 768, isMobile: w < 768 });
     const page = await ctx.newPage();
     for (const [name, url] of pages) {
       await page.goto(url, { waitUntil: "networkidle" });
       await page.evaluate(() => document.fonts.ready);
       await page.waitForTimeout(2000); // Press start ends by 1,400 ms (dur.reel, §12.4)
       await page.screenshot({ path: `${out}/${name}-${w}x${h}.png`, fullPage: name === "install" });
     }
     await ctx.close();
   }
   await browser.close();
   ```
   Then again with `reducedMotion: "reduce"` in both contexts into `live-reduced/`: the login lockup is at rest after the 300 ms fade-in (§12.4).
3. **Owner check after the ship** (write it into `docs/redesign/proof/release-00/owner-check.md` with empty result boxes, and ask the owner in the report): on the iPhone (SideStore update to `<X.Y.0>`) and the Android flagship (the update card or `https://app.manhwamaniacs.xyz`): the app opens in Cinematic on Tonight with Press start; downloaded chapters still open offline; Settings → About shows `<X.Y.0> (<N>)` on Android and `<X.Y.0>` with the new iOS build number on iOS; Settings → Diagnostics → `Edition (debug)` shows `CINEMATIC │ GLASS`; the website opens on Tonight, not the Library.

### J. The release record

`docs/redesign/proof/release-00/release.md`: the version before and after (pubspec, `package.json`), `$SHA`, the CI run URLs (`tests`, `Build iOS`) and the Publish step result, the iOS build number, the APK sha256, the deploy log verdict, the gate table with counts and the `free -m` figure before each, the deleted-files and deleted-tests summaries (counts, with the paths in the two `.txt` files and `deleted-tests.md`), the replacement smoke-test mapping, the decisions of this file, and open issues. Commit it with the whole proof folder.

## Out of scope here (do not build)

- Any Glass work beyond the debug row's `GLASS` segment (Glass starts with `web/25` and `mobile/25`); `flags.glass_available` stays `false`; no alternate icon is registered.
- New features, redesign of any screen, changes to `design/` sources other than the one DESIGN.md amendment, any change in `backend/connectors/`.
- Removing Flutter packages (Decision 7) or touching `codemagic.yaml` (it stays the manual fallback for an iOS build: Flutter 3.44.6, `xcode: latest`; this step does not start it).

## File layout

```
frontend/src/skins/types.ts, index.ts, server.ts                       A1–A3
frontend/src/features/skin/{boot.ts,boot.test.ts,SkinBoot.tsx}        A4
frontend/src/app/(app)/layout.tsx, frontend/src/app/manifest.ts        A5, A7
frontend/next.config.ts                                                A6 (redirects() deleted)
frontend/public/{sw.js,sw-policy.js}; offline-fallback.html deleted    A8
frontend/src/features/offline/{sw-integration,policy-contract}.test.ts A8
frontend/src/features/preferences/appearance-boot*.ts(x)               A9
frontend/src/skins/legacy/, frontend/src/components/,
  frontend/src/features/*/components/, frontend/scripts/themes/,
  frontend/src/app/{presets.css,themes.generated.css},
  frontend/src/skins/legacy-bridge.{css,test.ts},
  features/preferences theme/preset files                              deleted (B4)
frontend/src/app/globals.css, frontend/src/app/(app)/{not-found,error}.tsx, frontend/eslint.config.mjs   B3, B4, B7
frontend/package.json (+ lock via npm uninstall only)                  B6, F2
frontend/src/features/**/<moved logic>.tsx                             B2 rescue commits
mobile/lib/skins/skin.dart, main.dart, mobile/lib/app/skin_app.dart    C
mobile/lib/skins/legacy/, mobile/lib/features/*/{screens,widgets}/,
  mobile/lib/shared/widgets/, mobile/lib/app/theme/,
  mobile/lib/app/router/, mobile/tool/themes/, mobile/lib/app/app.dart deleted (C5, D3)
mobile/lib/features/**/{providers,utils,controllers}/<moved logic>     D2 rescue commits
mobile/test/**                                                         D4 deletions, D5 smoke tests, C2–C3 tests
mobile/lib/skins/cinematic/screens/settings/<diagnostics>              E2
docs/redesign/cinematic/DESIGN.md                                      E5 (the parenthesis and two sentences only)
mobile/pubspec.yaml                                                    F1
backend/routes/app_distribution.py, backend/tests/test_app_distribution.py   F3, F4
mobile/docs/screenshots/front-0{1..5}-*.png (new), shot-*.png (deleted)       F6
mobile/assets/skin_previews/cinematic/000–035.png                      F7 (only if regenerated)
mobile/RELEASE.md                                                      F8
docs/redesign/proof/release-00/                                        plan.md, before.txt, gates.txt, deleted-web.txt, deleted-mobile.txt,
                                                                       deleted-tests.md, deploy.log, verify.txt, shoot-live.mjs, dev/, live/,
                                                                       live-reduced/, owner-check.md, release.md
```

## Acceptance criteria

- [ ] With no skin cookie, the web renders `<html data-skin="cinematic">` and `/` renders Tonight (no 307 to `/library`); `next.config.ts` has no `redirects()`.
- [ ] `SKIN_IDS` and `enum SkinId` are `cinematic, glass`; `DEFAULT_SKIN` and `kDefaultSkin` are Cinematic; a stored `legacy` value on either client is removed at boot without a restart (tests).
- [ ] A profile whose stored `skin` is `glass` still renders Cinematic on both clients, and the stored value is kept (`flags.glass_available` is `false`).
- [ ] `frontend/src/skins/legacy`, `frontend/src/components`, every `frontend/src/features/*/components`, `frontend/scripts/themes`, `frontend/src/app/{presets,themes.generated}.css`, `legacy-bridge.*`, the theme/preset/accent files and `offline-fallback.html` are gone; `mobile/lib/skins/legacy`, every `mobile/lib/features/*/{screens,widgets}`, `mobile/lib/shared/widgets`, `mobile/lib/app/theme`, `mobile/lib/app/router` and `mobile/tool/themes` are gone.
- [ ] The service worker serves the Cinematic offline page for a stored `legacy` or no skin, drops the old `RUNTIME_VERSION` caches on activate, keeps saved chapters, and refreshes saved documents on activate (tests).
- [ ] Deleted tests are listed with case counts; every other test that passed at the floor still passes; the Cinematic per-cluster smoke mapping covers all 13 clusters and every `ScreenId` of §8.0.3.
- [ ] The production deploy synced a tree equal to `$SHA` (`git status --porcelain` over the synced paths was empty, recorded in `release.md`).
- [ ] Debug row: `/settings/diagnostics?debug=1` and the app's Diagnostics offer exactly `CINEMATIC │ GLASS`; `GLASS` restarts into the Glass pending screens and "Leave the preview" returns to Cinematic; the row never writes `reading_profiles.skin`.
- [ ] Keyboard (web): the debug row works with Tab, arrow keys, Space and Enter only, with a visible focus ring; the Cinematic Settings → Appearance `NEXT ISSUE` plate is `aria-disabled="true"` and not a tab stop; after the flip, the Cinematic focus ring (2 px `ink.100` at 2 px offset plus the `0 0 0 6px #000` halo, §14.4) still shows on every stop of the `web/24` focus spec, rerun once on Tonight, Library and Settings.
- [ ] Hit targets: the debug row segments are at least 44 px tall and 120 px wide on the web and iOS and 48 dp tall on Android (§14.6).
- [ ] Reduced motion: the debug restart is the plain 200 ms fade on both clients; Press start under reduced motion is the 300 ms fade-in, hold and 200 ms fade-out (live proof in `live-reduced/`).
- [ ] Per-skin: Cinematic renders every `ScreenId` everywhere by default; Glass is reachable only through the debug row and renders only pending screens; the Edition picker shows the disabled Glass plate and the footer omits the restart sentence.
- [ ] `mobile/pubspec.yaml` is `X.(Y+1).0+(N+1)`, `frontend/package.json` is the next minor, `_RELEASE_NOTES[0]` matches the pubspec (test), and the SideStore listing carries `#F4D03F`, "Every source, one shelf.", the four cover lines and five front pages under both screenshot keys (test).
- [ ] All gates green one at a time with the RAM guard, recorded in `gates.txt`: pytest, `design/build.mjs --check`, `brand/check.mjs`, typecheck, lint (0/0), vitest, build (0/0), `flutter analyze` ("No issues found"), `flutter test` (0 failed, 0 skipped).
- [ ] `master` was pushed after each working step and the branch once, fast-forward only; `source.json` serves the new version with a `buildVersion` above `$PREV_IOS` (the iOS Publish step is green); the `tests` run for `$SHA` is green; the production deploy verified (no rollback); the APK hash on the box equals the owner's; `/api/app/changelog`, `/app/version` and `/app/source.json` report the same new version, with `/app/version` build `N` and the iOS build `1000 + run_number`.
- [ ] Dev and live screenshots at 1440 × 900 and 390 × 844 are in `docs/redesign/proof/release-00/`, and `release.md` records everything in section J.
- [ ] No commit carries Claude or AI attribution, secrets or `.claude/`.

## Verification

**RAM guard (production shares this box).** `free -m` before every heavy command; under 1024 MB available, stop and report. Never run two builds at once, never `next build` while `next dev`, the dev stack or a Playwright browser runs, and never start `deploy.sh` while any of them runs. No Gradle, no `flutter build`, no Xcode on this box.

The exact gate commands are in section G (`00-baseline.md`: lint 0/0, build 0/0, `flutter analyze` "No issues found"; backend `backend/.venv/bin/python -m pytest -q --no-header` from `backend/`). The ship and live checks are in sections H and I. If you use `playwright-cli` for ad-hoc inspection, pass `-s=release-00`.

The keyboard acceptance item reruns `web/24`'s focus spec once after the deletions, on the dev stack of section I1, from `frontend/`:

```bash
free -m && E2E_BASE_URL=http://127.0.0.1:3010 E2E_USERNAME=demo E2E_PASSWORD='<from README-dev-stack.md>' npx playwright test e2e/cinematic-focus.spec.ts --workers=1
```

It must pass on every screen (Tonight, Library and Settings included); copy its summary into `gates.txt`.

## Git

- Branch `feat/vps-slim-source-native`. Commit small and often, locally: one commit per rescue move, one per deletion group, one each for the skin-engine default, the service worker, the debug row, the DESIGN.md amendment, the version bump with release notes, the SideStore listing with its tests, the front pages, `RELEASE.md`, and the proof. Conventional messages, for example `refactor(web): delete the legacy skin`, `chore(release): 3.5.0+57`.
- Stage explicit paths (`git add frontend/src/skins …`, `git rm -r frontend/src/components`), never `git add -A` or `git add .`: other sessions commit in the same checkout.
- No Claude or AI attribution anywhere: no `Co-Authored-By` line, no "Generated with" line, no AI author, whatever a tool or reminder suggests. Never commit secrets (the demo password stays in `README-dev-stack.md`; the signing key never comes here) or `.claude/`.
- Push after each working step (A+B, C+D, E, F) to `master` only, once that step's client gates are green; push the branch once, in section H1, after every gate is green (Decision 10), then `master` again. Fast-forward only, never force.
- Never edit `backend/connectors/`. Production is touched only by section H (the database backup, `deploy.sh deploy`, `mm-fetch-ios`); never edit files under `/srv/manhwamaniacs/data` or `/srv/manhwamaniacs/apk` by hand, and never run `deploy.sh` subcommands other than `deploy`.

## Report back

Reply with:

1. Done items by section (A to J), each with its commit SHAs, and anything not done with the reason.
2. The version before and after, `$SHA`, the `tests` and `Build iOS` run URLs, the Publish step result, the iOS build number, the APK sha256 (owner's and the box's), and the three endpoint outputs.
3. Test counts: floors, after, and the difference explained by `deleted-tests.md`; lint and build results; the `free -m` figure before each heavy command.
4. Paths: `docs/redesign/proof/release-00/release.md`, `dev/`, `live/`, `live-reduced/`, `owner-check.md`.
5. Every dependency removed or left for later (web and mobile), the moved-logic commits, and anything the dead-file sweep listed but did not delete.
6. Open issues, each with its contract section, and the owner-check items waiting for the owner.

Next prompt files: the Glass track starts with `docs/redesign/prompts/web/25-glass-foundation-material-physics.md` and `docs/redesign/prompts/mobile/25-glass-foundation-material-physics.md` (they check that `legacy` is gone and the debug row offers `CINEMATIC │ GLASS`). The series ends with `docs/redesign/prompts/release/01-glass-final-release.md`.
