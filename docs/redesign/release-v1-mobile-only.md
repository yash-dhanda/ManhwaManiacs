# Release v1 (3.5.0+57): mobile only, Cinematic

Scope: iPhone + Android, Cinematic skin. Web is postponed (the web app is not rebuilt, not redeployed with the new UI). Glass comes later. The backend changes (changelog, endpoints) still deploy because the apps read them.

Version: `mobile/pubspec.yaml` = `3.5.0+57`; `_RELEASE_NOTES[0]` in `backend/routes/app_distribution.py` = 3.5.0 / 57. The build number is overwritten in CI (iOS: 1000 + run number).

## Order

1. Gates on the final tree, one at a time via `/srv/manhwamaniacs/dev/heavy.sh`: backend `pytest`, mobile `flutter analyze`, `flutter test`. Web gates only if web files changed.
2. Backend deploy: done by another agent (see `ops/vps/deploy.sh`, `ops/vps/push.sh backend`). Verify `/api/app/changelog` and `/app/version` report `3.5.0` before step 3.
3. iOS: merge `redesign/V2` into `feat/vps-slim-source-native` (owner decision), then push `feat/vps-slim-source-native`. Push triggers `.github/workflows/ios-build.yml` (tests, then `build-ios`, then the release asset). Push `master` too (contribution graph rule, never force).
4. Wait for the `build-ios` Publish step to be green (poll `source.json`, not the unauthenticated GitHub API). Poke `mm-fetch-ios` (`ops/fetch-ios-build.sh`) so the VPS serves the new .ipa.
5. SideStore source update: `/app/source.json` must list 3.5.0 (`build_ios_source` reads the pubspec version). Owner opens SideStore, refreshes the source, updates the app.
6. Android APK, on the owner's laptop only (signing key lives there; never build on the VPS): `bash ops/vps/push.sh apk`. It builds, checks ABIs and the baked prod URL, and publishes to the app subdomain (`/app/download`). Install over the existing app so downloads survive.
7. Proof: `/api/app/changelog`, `/app/version`, `/app/source.json` all say 3.5.0; iOS Publish step green; APK `apk_version` = 3.5.0.
8. Owner runs `docs/redesign/proof/mobile-24/device-pass.md` (Cinematic checklist below) on both devices.

## Web: explicitly skipped

- No `push.sh frontend` / `push.sh all`.
- No web flip, no `RUNTIME_VERSION` bump, no service-worker change.
- `release/00` web sections (A, B, web part of F, web deploy) are out of scope for v1.

## Later

Glass release (`prompts/release/01`), web flip.
