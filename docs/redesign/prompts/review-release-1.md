# Review: release track, slice 1

Reviewed 2026-09-29 against `prompts-plan.json` (orders 67 and 110), both `DESIGN.md` files, `inventory/*.md`, `stack-decision.md`, `00-baseline.md`, the neighbouring prompt files, and the real release tooling in the repo (`ops/vps/push.sh`, `ops/vps/deploy.sh`, `ops/fetch-ios-build.sh`, `.github/workflows/{tests,ios-build}.yml`, `codemagic.yaml`, `backend/routes/app_distribution.py`, `frontend/next.config.ts`, `frontend/public/sw*.js`, `frontend/tsconfig.json`), plus the owner's memory on ship verification.

Files in the slice:

- `docs/redesign/prompts/release/00-cinematic-flip-release.md`: exists, fixed in place.
- `docs/redesign/prompts/release/01-glass-final-release.md`: exists, fixed in place.

No file was missing, so none was created.

## Rule checklist (both files, after the fixes)

| Rule | 00 | 01 |
|---|---|---|
| Goal paragraph, "Read first" with exact paths and sections | yes | yes (list extended, see R01-12) |
| Scope matches the plan entry, item by item | yes | yes |
| Skills named (writing-plans, subagent-driven-development / executing-plans, impeccable, taste-skill, frontend-design, verification-before-completion) | yes | yes |
| File layout with exact paths | yes | yes (extended) |
| Acceptance checkboxes incl. reduced motion, keyboard, 44 pt / 48 dp, per-skin | yes | yes |
| Exact gate commands of `00-baseline.md` plus backend pytest | yes | yes |
| Playwright proof at 1440 × 900 and 390 × 844 under `docs/redesign/proof/<step>/` | yes (commands made exact) | yes |
| RAM guard, one build at a time | yes | yes |
| Git: small commits, push after each working step, no AI attribution, no secrets or `.claude/` | fixed (R00-1) | fixed (R01-1) |
| Never `backend/connectors/`; production touched only by the explicit ship section | yes | yes |
| Report back and next prompt file | yes | yes |
| No TBD, "etc.", "as appropriate" | none found | none found |
| Dependencies stated and equal to the plan | yes | yes |
| Values equal to DESIGN.md | yes, after R00-7 | yes, after R01-5, R01-8, R01-10 |

## Findings and fixes: `release/00-cinematic-flip-release.md`

- **R00-1 Push rule.** The file pushed only once at the end, against the series rule "push after each working step". The reason was real: every push of `feat/vps-slim-source-native` publishes an IPA (`ios-build.yml` triggers on that branch only), so an intermediate push would offer the owner a half-deleted app. Fix (Decision 10, Git section, acceptance, `RELEASE.md` checklist): after each working step (A+B, C+D, E, F) whose client gates are green, push to `master` only, which runs the `tests` workflow and publishes nothing; the branch is still pushed once in H1.
- **R00-2 Reading CI broke the owner's rule.** Without `gh` (it is not installed on this VPS: `command -v gh` is empty), the file polled the anonymous GitHub API every 3 minutes. The owner's ship-verification memory forbids that (60 requests an hour, shared with `mm-fetch-ios`, exhausted once already). Fix (H1, H2, H7): record `PREV_IOS` from `/app/source.json` before the push; wait by poking `mm-fetch-ios.service` every 5 minutes and reading `source.json` until the new `version` and a higher `buildVersion` appear, which proves the Publish step and the `tests` job it depends on; then at most two anonymous calls to record run URLs and `run_number`, and annotations only after a 60-minute timeout.
- **R00-3 Deploying another session's work.** `push.sh` and the local mirror rsync the working tree, and other sessions work in the same checkout (today `git status` shows other sessions' edits). Fix (H5, acceptance): before the sync, `HEAD` must equal `$SHA` and `git status --porcelain -- frontend backend ops mobile/pubspec.yaml mobile/docs/screenshots` must be empty; otherwise stop and wait for the owner.
- **R00-4 Stale `headers()` entry.** `next.config.ts` `headers()` lists `offline-fallback.html` (added by `web/02` item 10), which A8 deletes. Fix (A6): the no-cache source becomes `sw.js|sw-policy.js|offline-fallback-cinematic.html|offline-fallback-glass.html`; `output: "standalone"` and `images` are named as kept.
- **R00-5 Manifest fields incomplete.** A7 listed five of the §12.3 manifest fields. Fix: all of them (`id`, `scope`, `display`, icons 192/512/maskable 512, no `orientation`).
- **R00-6 `proof.mjs` still offered `legacy`.** `web/03`'s `--skin <legacy|cinematic|glass>` was outside A10's grep. Fix: A10 greps `frontend/scripts` too and restricts `--skin` to `cinematic | glass`.
- **R00-7 Contract amendment incomplete.** Cinematic §8.0.7 also says "(`│ GLASS` added once Glass's completeness tests pass)", which contradicts the plan's `CINEMATIC │ GLASS` at the flip. Fix: Decision 1's docs commit replaces that parenthesis as well (File layout: E5).
- **R00-8 Hidden `LEGACY` labels.** `web/18` item 13 and `mobile/18` item 14 render the debug row inside Cinematic's Diagnostics with its own `LEGACY │ CINEMATIC` wording, which a `DEBUG_SKINS` edit may not reach. Fix: new E4, a case-insensitive `legacy` sweep over the skins and skin engine on both clients; E1 and E2 also delete the `web/02` / `mobile/01` comments that said `web/25` / `mobile/25` add `glass`.
- **R00-9 Smoke clusters missed ScreenIds.** D5's auth cluster lacked `profileNew`, `profileEdit`, `profilesManage`, and `readerLanding` was in no cluster. Fix: added (with `readerLanding` asserted as the app's redirect to `/library`); the acceptance now requires every `ScreenId` of §8.0.3.
- **R00-10 Visual proof and keyboard check not exact.** I1 said "`next dev -p 3010`" without `BACKEND_INTERNAL_URL`, so the dev front would not reach the dev backend on 8010, and the keyboard acceptance item had no command. Fix: the exact `dev_stack.sh start`, `BACKEND_INTERNAL_URL=http://127.0.0.1:8010 npm run dev -- --port 3010`, the two `proof.mjs` invocations, and the `cinematic-focus.spec.ts` command in Verification.

Checked and correct as written: the default-skin changes (A1–A4, C1–C3), the SW reset and `refreshSavedDocuments()` (A8, stack risk 7), the deletion lists against stack §3 and the plan, Decision 2 (`sidestore.md` spells `front-03-read-aloud.png` and `front-04-your-year.png`, `backend/07`'s `_SHOWCASE` spells `front-03-novels-read-aloud.png` and `front-04-year-in-chapters.png`; the code wins), the SideStore fields against cinematic §12.3 and `shared/04` item 8, `_RELEASE_NOTES` against the real `ChangelogEntry` model, the version bump (repo today: `3.4.3+56`, `2.6.1`), Decision 8 (verified: `ssh ubuntu@135.148.43.147 true` from this box fails with `Host key verification failed`, and `/srv/manhwamaniacs/app` has no `.git`), the local mirror against `push.sh all` and `deploy.sh deploy`, the backup unit and log path, the verify commands against `/app/version` (build of the served APK) and `/api/app/changelog`.

## Findings and fixes: `release/01-glass-final-release.md`

- **R01-1 Push rule.** Same as R00-1 (Decision 7, J1, Git, acceptance). The first `master` push groups A to D, because `brand/check.mjs` fails in CI while the flag is `true` and the icon registration is missing (`shared/05` Decision 4).
- **R01-2 Reading CI.** Same as R00-2 (J1, J2, J7).
- **R01-3 Deploy tree guard.** Same as R00-3 (J5, acceptance).
- **R01-4 Android alias names would not switch.** `shared/05` writes the Dart names as fully qualified class names (`com.manhwamaniacs.reader.GlassIcon`), `mobile/39` E3 stores the short `GlassIcon` in `mm.icon.pending`. Fix (D2, F3.6): the release checks and corrects to the fully qualified names.
- **R01-5 Cinematic's explicit choices were never wired to the icon.** `mobile/18` and `mobile/20` leave the icon alone while the flag is false, and `mobile/39` wires only Glass's paths; nothing assigned Cinematic's Stop the press (Appearance, onboarding step 1, active-profile form) to `AppIconSwitcher`. Fix (D2): assigned here, with the full list of callers and non-callers. Decision 1 adds that Undo is an explicit choice, so the icon follows it back (glass §12.2 "the icon shows the skin last chosen on this device"); F3.6 tests every entry point.
- **R01-6 Preview assets described wrongly for the app.** C1 expected four WebP/PNG files "on both clients"; `mobile/39` uses 36-frame PNG loops, and only the web has the WebPs. Fix: per-client file lists and the exact regeneration commands (`npm run capture:skin-previews`; `MM_WRITE_PREVIEWS=1 … skin_preview_capture_test.dart`; `MM_WRITE_SHOTS=1 … cinematic_preview_frames_test.dart`).
- **R01-7 Debug path not fully deleted.** Missed holders: `web/18` item 13's Cinematic web `diagnostics` registry entry, section and `?debug=1` gate; the exact file of `web/40`'s "Preview Glass skin" row; `mobile/18`'s `Edition picker (flag on)` demo row; `mobile/25`'s dev-index Edition (debug) row; `leavePreview`; and `mobile/45`'s `glass_switch_test.dart`, which switches through the deleted row. Fix: E1 and E2 name each, and the deleted tests go into `deleted-tests.md`.
- **R01-8 Notification accent wrongly "at runtime".** `mobile/37` A3 sets `notificationColor` from the boot skin once, because `AudioService.init` runs once per engine. Fix (D4): confirm that, record the platform limit, and add device-pass row L9.
- **R01-9 Flag-false tests would break silently or be deleted.** Tests that read the generated flag and assert Glass is hidden (`web/45` and `mobile/45` M5, the `NEXT ISSUE` plate and short footer checks) fail once the flag is `true`. Fix (A2): rewrite them to inject `glassAvailable: false` or to assert the flag-true behaviour, never delete them.
- **R01-10 Glass §8.0.8's CI refusal was assigned to no step.** "CI refuses a build with the flag `true` while either client's Glass completeness or boundary test fails." Fix: new A3 ties both completeness tests to the flag.
- **R01-11 The helper could not be imported by the scripts.** Decision 4 put `useSkin` in a `.ts` file while `proof.mjs`, `front-pages.mjs`, `float-frames.mjs` and `capture-skin-previews.mjs` are plain Node ESM. Fix: one implementation in `frontend/scripts/use-skin.mjs` with a `node --test` case, re-exported by `frontend/e2e/support/use-skin.ts` (the tsconfig has `allowJs`), with its signature and restore behaviour.
- **R01-12 Seeding and dev commands not exact.** "Seed two demo profiles" had no command, and Verification started `next dev` without `BACKEND_INTERNAL_URL`. Fix (F, Verification): `A` = Riya and `B` = Aarav through `dev_stack.sh api PATCH /profiles/<id>`, restored to `null` at the end; the exact dev-stack and `next dev` commands. "Read first" now names `mobile/39`, `web/39`, `web/18`, `mobile/18`, `web/40`, `mobile/40`, `mobile/37` and `README-dev-stack.md`.
- **R01-13 Smaller contract fixes.** B6 adds Stop the press's `impress` sound (cinematic §8.30.3); L8 points at cinematic §15.7 "18+ on the device" (the checklist) instead of §14.11 (prose); G2 spells out the `_render_shots(items, kicker, label)` change so the Front pages strip renders byte for byte as before.

Checked and correct as written: the §8.0.7 table and glass §8.0.8 surfaces, all copy strings (confirm, alert, footer and footnote, captions, toasts), the timings (500 ms Stop the press with its 0–160 / 80–456 / 456 ms marks, 615 ms melt, 1,200 ms Droplet, 1,100 ms Step into the light, 480 ms iris close, 10,000 ms undo, 1,500 ms restart budget, 200 ms reduced fades), Decision 2 (it resolves glass §8.25.2 step 5 "Switched to Cinematic · Undo" against cinematic §8.30.3 "Now in the Cinematic edition." in favour of each skin's own words), the icon registration against `shared/05` and glass §12.2, the Glass strip against glass §12.5 and §12.6 (the listing stays Cinematic's), the focus-ring and hit-target values against both §14 sections, and the version and ship steps.

## The slice against its neighbours

Everything the plan gives orders 67 and 110 is now assigned, once:

- **Order 67:** the default flip, the legacy deletion on both clients, the reduced debug row, the minor bump, release notes, the SideStore fields, gates, the three-platform ship and the endpoint checks. `web/25` and `mobile/25` only check the `CINEMATIC │ GLASS` row, so it is not assigned twice.
- **Order 110:** the flag, every gated surface of both skins, the icon registration and its wiring, the debug-path deletion, the cross-skin QA, the §14 suites, the install-page Glass strip, the bump and the ship. `web/45` and `mobile/45` leave all of these to `release/01` in their own "not here" lists.

Conflicts found in neighbouring files (outside this slice, not edited here; the release files now override or absorb them, but their own reviewers should align the text):

1. `web/02` item 7 sends `/settings/diagnostics` to `DebugEditionPage` for every skin, while `web/18` item 13 and `web/40` H1 each put a Diagnostics section with the debug row at the same URL, so neither section is reachable while the `web/02` override stands. `release/01` E1 removes the override and the Cinematic section; `web/18` and `web/40` should say how their sections are reached before then.
2. `mobile/39` E3 stores short alias names; `shared/05` requires fully qualified ones (R01-4).
3. `web/02` and `mobile/01` say `web/25` and `mobile/25` add the `GLASS` segment; the plan gives it to `release/00` (R00-8).
4. `backend/07` used to say `web/24` captures the Front pages straight into `mobile/docs/screenshots/`, while `web/24` writes `front-1-tonight.png` … into its proof folder. The backend reviewer has since aligned `backend/07` D5 with `release/00` F6 and Decision 2 (`web/24` captures, `release/00` copies under the `_SHOWCASE` names, `_SHOWCASE` wins over `sidestore.md`), so this one is resolved.
5. Cinematic §8.0.7 table row "Profile form: The `Skin` row" and §8.6 "`Edition`" name the same control differently; the release files use `Edition` (Cinematic) and `Skin` (Glass), as each skin's §8.6 does.
