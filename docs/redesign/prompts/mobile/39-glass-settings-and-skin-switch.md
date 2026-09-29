# Mobile Glass Settings and the skin switch

Track: mobile · Order 97 · Depends on: `docs/redesign/prompts/mobile/38-glass-search-sources-dialogue.md` · Web twin: `docs/redesign/prompts/web/39-glass-settings-and-skin-switch.md` (may run at the same time in another session; you never touch `frontend/`) · Proof folder: `docs/redesign/proof/mobile-39/`

## Goal

Build Glass Settings in the Flutter app (ScreenId `settings`, `/settings` and `/settings/:section`): the Settings root with its search overlay and the one settings index, and the sections this step owns: §8.25.1 Appearance and skin (the two live skin preview cards, Solid glass, Increase contrast, Legible text, Reduce motion, Light follows the device, "App icon follows the skin" off by default), §8.25.2 the skin switch and restart (the alert blooming from the card, persist, Glass's 615 ms "melt", `AppRestart`, the arriving skin's 10 s Undo, the offline wording, the profile hand-off switch without an alert), §8.25.3 Reader defaults with its Novels, Listen and Ambient groups and the one-time per-profile migration of the stored mobile values, §8.25.4 Content, §8.25.5 Sound and haptics, §8.25.13 Shortcuts, §8.25.14 Account, language and About with the open-source licences sheet, §8.25.15 Circle and privacy, §8.25.16 AI and recaps; plus the app-icon rules of §12.2 (iOS `setAlternateIconName` inside the restart moment; the Android `activity-alias` swap queued until `AppLifecycleState.paused`) and the Glass skin preview frames `mobile/assets/skin_previews/glass/000–035.png` captured by the screenshot harness. §8.25.6 Notifications, §8.25.7 Security, §8.25.8 Members, §8.25.10 Backup, §8.25.11 Server and §8.25.12 Diagnostics are `mobile/40`: this step lists their rows in the root and the index and routes them to the skin's pending body until then. When you finish, `settings` leaves the Glass `PENDING` set. Cinematic's Settings and edition picker (`mobile/18`) must not change behaviour.

## Read first

Read these completely before planning. Where this file and `docs/redesign/glass/DESIGN.md` disagree, `glass/DESIGN.md` wins; say so in the report.

1. `docs/redesign/inventory/00-decisions.md` (all; the user picks the skin in Settings and the app restarts; dark only; no accent picker; UI sounds off by default; rich haptics).
2. `docs/redesign/stack-decision.md` §2.4 (the profile is the source of truth, the device mirror, the return route, the boot resolution steps), §2.5 "Mobile" steps 1 to 8 (PATCH through the outbox, `mm.skin.active`, the outgoing animation, `AppRestart`, `initialLocation`, downloads resuming, the 1.5 s budget), §3 (release model: Glass behind the debug row until `release/01`), §4 risks 7, 8, 9 and 11.
3. `docs/redesign/glass/DESIGN.md`:
   - "Conventions used everywhere below"; §2.1.2, §2.1.3, §2.1.4, §2.4.2 rules 7 and 8, §2.7 (`gear-six`, `paint-brush`, `book-open`, `age-gate`, `users-three`, `sparkle`, `speaker-high`, `bell-simple`, `lock-simple`, `hard-drives`, `cloud-arrow-up`, `plugs-connected`, `pulse`, `keyboard`, `info`, `caret-right`).
   - §3.2, §3.3, §3.6 (Legible text on Flutter: `GlassTokens.legible` swaps every role to `AtkinsonHyperlegibleNext` and rebuilds the theme without a restart).
   - §4.10 rows Skin melt, Droplet reveal, Bloom, Row pulse, Letter reveal, Title capsule, Toast fall, Hold fill, Sheet present, Sheet snap, Liquid spinner, Skeleton shimmer, Error shake; §4.11; §4.7.
   - §5.1 (the haptics switch), §5.2 events `skin.switch` (`heavy`), `toggle.on`, `toggle.off`, `select`, `detent.tick`, `detent.magnet`, `detent.limit`, `hold.ramp`, `hold.done`, `delete.confirm`, `undo`, `error`; §5.3 ("Feel it"); §6 (the `melt` cue, "Hear it", the volume range, off by default).
   - §7.1 (buttons, HoldToConfirm), §7.3 and §7.4 (in-page filter wells), §7.6 (segmented), §7.10 (sheets; `licenses` is a `large` sheet on phones), §7.11 (alerts: blooming from the control, the stacked buttons, initial focus), §7.12 (toasts with Undo and the draining rim), §7.17 (grouped lists, row anatomy, 30 px icon tiles), §7.21, §7.22 (switches), §7.23, §7.24, §7.25 (the 18+ gate alert), §7.27 (keycaps), §7.30 (inline notices).
   - §8.0.3 (the `settings` row, the **settings section slugs** list and the Glass addition `ai`, the sheet ids `whats-new`, `app-update`, `licenses`), §8.0.5 (Android back order rule 9: the Settings search overlay), §8.0.8 ("Glass before it ships" and `flags.glass_available`; "First-paint attributes": Flutter reads `mm.boot.a11y.u{user}p{profile}` before `runApp`; the 18+ purge), §8.0.9, §8.2 (the Droplet on a skin-switch arrival).
   - **§8.24** (the You hub's Settings group order, which the Settings root mirrors) and **§8.25 entire**. Read every line of §8.25, §8.25.1 to §8.25.5 and §8.25.13 to §8.25.16; skim §8.25.6 to §8.25.12 (they are `mobile/40`, but their rows enter the index here).
   - §9.1.3 and §9.1.5 (the recap modes and the AI unavailable voice), §9.3 (the sharing switch table and the isolation rules), §9.4.1 and §9.4.2 (cruise speed range; the soundscape mixer defaults 80 / 50 / 30 %, master −30 to 0 dB default −12, Match the story on, Lower under narration on), §9.4.3, §9.4.4.
   - **§12.2** (App icon: `setAlternateIconName("AppIcon-Glass")` inside the restart moment on iOS; `.GlassIcon` / `.CinematicIcon` aliases queued until the app next goes to the background on Android; never on a profile switch or a boot-time mismatch; the caption), §12.3, §12.5, §12.6, §12.7 (the "Skin previews" row).
   - §14.1–§14.8, §15.3, §15.5 (the device keys table: `mm.boot.a11y`, `mm.recap`, `mm.soundscape.defaults`, `mm.glass.prefs`, `mm.icon.follow`), §15.6 (the recap setting, sharing switches, app icon, legible text), §15.7, §15.10 (G5, G13 and the owner calls), §15.11 (`flutter_dynamic_icon_plus` 1.4.1).
4. `docs/redesign/cinematic/DESIGN.md` §8.30.3 (the arriving Cinematic skin's own splash and Undo toast, which `mobile/18` built) and the "Per-skin icon" bullet of §12.3 (the shared icon rule).
5. `docs/redesign/inventory/mobile.md` S28 (items 1–27), S31 (the theme gallery the skin picker replaces), G3, G4, G9, §5a K01–K14 and K22–K29, §5b K30, §5c.
6. `docs/redesign/inventory/capabilities.md` §5 (profiles and `PATCH /profiles/{id}`), §6 (`GET /settings` with `capabilities`; `PUT /settings` `mature_content_enabled`), §9 (`GET /library/suggest/availability`, `POST /ai/feedback`), §23 (app version and changelog).
7. `docs/redesign/00-baseline.md`.
8. The web twin `docs/redesign/prompts/web/39-glass-settings-and-skin-switch.md` and `docs/redesign/proof/web-39/report.md` when present (its settings-index entries and its preview capture; keep the phone identical where platforms overlap).
9. Earlier mobile reports: `docs/redesign/proof/mobile-01/report.md` (`switchSkin()` and its parameters, `SkinBoot`, `AppRestart`, `mm.skin.active`, `mm.skin.return`, `mm.skin.t0`, the downloads re-queue at startup), `docs/redesign/proof/mobile-02/report.md` (the haptics toggle and its scope, `skin_audio.dart`, the UI sounds switch and volume), `docs/redesign/proof/mobile-18/report.md` (Cinematic's edition picker, its preview frames under `mobile/assets/skin_previews/cinematic/`, its arriving Undo toast and the key it reads, `flutter_dynamic_icon_plus` left unregistered), `docs/redesign/proof/mobile-19/report.md` and `mobile-22/report.md` (the `mm.recap` provider, the sharing providers), `docs/redesign/proof/mobile-25/report.md` to `mobile-30/report.md` (`SkinGlass` and its registry, the Solid glass and contrast inputs, the primitives incl. HoldToConfirm, the gate alert, keycaps, `GlassSheetPage`, the alert and toast hosts, the shell, the key registry, the Droplet splash, `purgeMatureLocal`, the profile hand-off, onboarding step 2 and the profile form's skin row), `docs/redesign/proof/mobile-32/report.md` (the library-density reading of K15 and Downloads → Storage), `docs/redesign/proof/mobile-35/report.md` (the Glass reader settings store and any migration it already does), `docs/redesign/proof/mobile-36/report.md` and `mobile-37/report.md` (the novel defaults record, the Glass novel settings fields, the listen settings fields).
10. Code: `mobile/lib/main.dart`, `mobile/lib/app/app_restart.dart`, `mobile/lib/skins/skin.dart`, `mobile/lib/skins/contract.g.dart` (`Flags.glassAvailable`, `Routes`, the settings slugs), `mobile/lib/skins/glass/` (`glass_skin.dart`, `router.dart`, `shell.dart`, `skin_glass.dart`, `motion.dart`, `primitives/`, `copy/`), `mobile/lib/features/settings/` (`providers/settings_provider.dart`, `app_update_provider.dart`, `app_changelog_provider.dart`), `mobile/lib/features/reader/`, `mobile/lib/features/novels/`, `mobile/lib/features/circle/`, `mobile/lib/features/profiles/`, `mobile/pubspec.yaml` (`flutter_dynamic_icon_plus`, `package_info_plus`, `assets:`), `mobile/pubspec.lock`, `mobile/ios/Runner.xcodeproj/project.pbxproj` and `mobile/ios/Runner/Info.plist` (the registered alternate icons), `mobile/android/app/src/main/AndroidManifest.xml` (the `.GlassIcon` and `.CinematicIcon` aliases), `mobile/test/screenshots/support/shot_harness.dart`.

## Preconditions (check before writing the plan)

- `git log --oneline -40` shows the `mobile/38` commits; `ScreenId.settings` is still in the Glass `PENDING` set.
- `grep -rn "switchSkin\|class AppRestart\|SkinBoot" mobile/lib | head` finds `mobile/01`'s engine; `grep -n "glassAvailable" mobile/lib/skins/contract.g.dart` shows the flag (it is `false` until `release/01`). If either is missing, stop and report.
- `ls mobile/assets/skin_previews/cinematic/000.png mobile/assets/skin_previews/cinematic/035.png` (from `mobile/18`). If they are missing, capture the Cinematic frames here with the same harness mode as item O, using `mobile/18`'s documented demo sequence, and say so in the report.
- `grep -n "flutter_dynamic_icon_plus" mobile/pubspec.yaml` shows 1.4.1; `grep -n "GlassIcon\|CinematicIcon" mobile/android/app/src/main/AndroidManifest.xml` lists both aliases (from `shared/05`); `grep -n "ALTERNATE_APPICON_NAMES\|AppIcon-Glass\|GlassIcon" mobile/ios/Runner.xcodeproj/project.pbxproj mobile/ios/Runner/Info.plist` records the registered Glass icon name (§12.2 names `AppIcon-Glass`).
- `ls design/settings-index.json` decides item B2's source (present: it is the one list; absent: see B2).
- In `mobile/`: `free -m`, `pgrep -f "next build"` empty, then `/srv/manhwamaniacs/dev/flutter/bin/flutter test` once; record the passed count as your floor.

## Skills to invoke

1. `superpowers:writing-plans` before any code; plan at `docs/redesign/proof/mobile-39/plan.md`, one task per scope letter.
2. `superpowers:test-driven-development` for every pure module (the migration runner and each of its rows, the index filter, the icon switcher decisions, the arriving-toast condition, the licence classifier, the package-version table check, the sharing preview line, the tile contrast check).
3. `superpowers:subagent-driven-development` (or `superpowers:executing-plans` inline). At most 6 implementer subagents, scope-locked, `model: "opus"` passed explicitly, one Flutter command at a time, every subagent's work checked against `git status` and `git diff`.
4. `impeccable:impeccable` and `taste-skill:taste-skill` for the skin cards, the switch alert and the melt: switching skin is the one moment the user sees the whole app as an object; it must feel deliberate and reversible, never like a settings toggle. `frontend-design:frontend-design` only for the side-by-side review against the web twin's phone captures.
5. `superpowers:verification-before-completion` before you claim anything is done.

## Ground rules

- Work in `mobile/` only (plus `node design/build.mjs` regeneration; no edit under `design/`, `brand/`, `frontend/` or `backend/`). Tokens only (`GlassTokens`); named moves through `GlassMotion.play`; haptics through `skins/glass/haptics.dart`; cues through the Glass sound map.
- Skin files import only the shared data layer, `core/`, `shared/`, the generated contract, `skin_haptics.dart`, `skin_audio.dart` and `skins/glass/**`. Settings values both skins read live in `mobile/lib/features/` (skin-neutral), each with a test.
- Every preference that is not a server value lives on the device: per profile with the `.u{user}p{profile}` suffix, or per device where this file says so; captions never claim a device value follows the profile.
- Old keys are read, never rewritten or reinterpreted; new values go under new keys, so a return to the other skin loses nothing (§8.25.3).
- Hit areas 44 × 44 pt (iOS) and 48 × 48 dp (Android), 8 px apart. Never edit `backend/connectors/`; never touch production.

## Scope: deliver every item below

Sections cited are `glass/DESIGN.md`.

### A. Shared data layer (skin-neutral, first commits, no pixels)

A1. **`mm.boot.a11y.u{user}p{profile}`** (`{legible, motion, solid, contrast}`; `sr` is web only): reuse the provider `mobile/29` reads before `runApp`; if it has no writer, add `bootA11yProvider` with `set(field, bool)` in `mobile/lib/features/settings/providers/boot_a11y_provider.dart` (+ test). Cinematic reads `legible` and `motion` from the same record.
A2. **`mm.glass.prefs.u{user}p{profile}`** (`{lightFollowsDevice: true, autoPlayPreviews: true, chartTables: {}}`): reuse the provider `mobile/25` or `mobile/37` created; otherwise create it in `mobile/lib/features/settings/providers/glass_prefs_provider.dart` (+ test; unknown fields kept).
A3. **App icon keys** (per device, plain SharedPreferences): `mm.icon.follow` (bool, default `false`), `mm.icon.pending` (Android alias waiting for the next pause). If `mobile/18` created an icon switcher, extend it; otherwise create `mobile/lib/core/platform/app_icon_switcher.dart` (item E).
A4. **One-time migration of stored mobile values** (§8.25.3, the mobile rows) in `mobile/lib/features/settings/utils/glass_prefs_migration.dart` (+ `mobile/test/features/settings/glass_prefs_migration_test.dart`). It runs once per profile when a profile becomes active in the Glass skin (marker `mm.glass.migrated.v1.u{user}p{profile}`), writes into the Glass reader settings store `mobile/35` created (find it in its report or with `grep -rln "graphite\|Graphite" mobile/lib/features/reader`) and never rewrites an old key. Where `mobile/32`, `mobile/35` or `mobile/36` already implements a row, the runner calls that same function (no second copy of the logic):
   - **Brightness:** K09 `reader_brightness` (0.2–1.0) → the profile default `brightness`, kept as is.
   - **Warmth:** K10 `settings_reader_warmth` (0–1) → the profile default `warmth`, kept as is.
   - **Cruise speed:** nothing is stored on mobile (session only); `cruiseSpeed` defaults to 1.0; write nothing.
   - **Library density:** K15 `settings_library_cover_scale`: < 0.85 → Compact (4 columns), 0.85–1.25 → Comfortable (3), > 1.25 → 2 columns (`mobile/32`'s function).
   - **Direction, fit, zoom:** K01 / K02 device values seed each series' entry on its first open (`mobile/35`); `leftToRight` / `rightToLeft` open Single paged in that direction (§8.14.1). Nothing is written here; the test asserts `mobile/35`'s seeding runs.
   - **Reader background:** K11 `dark` → Graphite; `black` (AMOLED) and `white` (Paper) → Black.
   - **Novel paper:** K26 → the seven papers by the §8.15.1 mapping (`mobile/36`'s read-time fallback; nothing written).
   - **Keep screen awake:** K05 `settings_keep_screen_awake` → the per-profile `keepAwake`, seeded once.
   Tests: each row at its end points and one middle value, idempotent (a second run changes nothing), two profiles isolated, every old key byte-for-byte unchanged afterwards, a profile created later starting from the device values.
A5. **Sharing:** the providers `mobile/22` built over `GET /profiles/{id}/sharing` and `PATCH /profiles/{id}/sharing` (partial bodies) gain `show_presence` (default off) and `share_streak` (default off) if they lack them, and expose `excluded_series` (`[{source_id, series_key, title}]`); test the partial PATCH bodies.
A6. **Recap setting** `mm.recap.u{user}p{profile}` = `{mode: "off" | "ask" | "always", seriesDays: 7, chapterDays: 3, skipSeries: ["source:series", …]}` (default `ask`): reuse `mobile/19`'s provider; if none reads this key, create `mobile/lib/features/ai/providers/recap_settings_provider.dart` (+ test), mapping a Cinematic value stored under another key per §15.6 (`NEVER` → `off`, `ALWAYS` → `always`, `AFTER N DAYS AWAY` → `ask` with `seriesDays = N`) on first read.
A7. **Soundscape defaults** `mm.soundscape.defaults.u{user}p{profile}` = `{scene: "off", matchStory: true, mix: {bed: 0.80, detail: 0.50, tone: 0.30}, volumeDb: -12, lowerUnderNarration: true}` (§9.4.2): create `mobile/lib/features/reader/providers/soundscape_defaults_provider.dart` (+ test) unless one exists; `mobile/44` reads it.
A8. **Reader-default fields Glass adds** to the Glass reader settings store as profile defaults, if absent: `cruiseSpeed` (0.25–4.0, default 1.0) and `guidedDefault` (default `false`); `mobile/44` reads both.

### B. The Settings root and the settings index (§8.25 top, §8.24)

B1. **Route:** ScreenId `settings` at `/settings` and `/settings/:section` (the shared slugs of §8.0.3), pushed on the You tab (dock tab 4); leaving `PENDING`. Phones: the root is a pushed page; each section is a pushed page (`mobile/29`'s Glass page builder). Tablet and desktop frames (§8.0.8 "Tablets"): a 240 px section list at the left of the content column and the section panel at the right; `↑` / `↓` move between sections and `Enter` opens one. `reading-novels`, `listen` and `ambient` open Reader defaults scrolled to that group (`Scrollable.ensureVisible`, alignment 0) with the group header flashed by the Row pulse; `storage` goes to Downloads → Storage (`go(Routes.downloads(tab: 'storage'))`, `mobile/32`; §8.25.9 is only this link on phones, so `mobile/40` has nothing to add for it); `about?sheet=licenses` opens the licences sheet.
B2. **The settings index** (one entry per row of §8.25.1 to §8.25.16: `{id, label, keywords[], section, platforms, admin}`), in `mobile/lib/skins/glass/copy/settings_index.dart`. **Source:** if `design/settings-index.json` exists, it is the one list: regenerate with `node design/build.mjs` when the generator writes the Dart file, otherwise write the Dart constants from that JSON exactly (same ids, order and fields). If it does not exist, write the Dart constants from the table below, and add `mobile/test/skins/glass/settings_index_parity_test.dart`, which, when `frontend/src/skins/glass/copy/settings-index.ts` exists, extracts its `id` values and asserts the same id set; record the missing shared source in the report as an open issue for the shared track. Platforms: `ios`, `android`, `web`; "apps" means `ios` and `android`; "all" means all three.

   | id | Label | Section | Platforms | Admin | Keywords |
   |---|---|---|---|---|---|
   | `skin` | Skin | appearance | all | no | theme, edition, cinematic, glass, look |
   | `solid-glass` | Solid glass | appearance | all | no | transparency, blur, opaque |
   | `increase-contrast` | Increase contrast | appearance | all | no | contrast, borders, accessibility |
   | `legible-text` | Legible text | appearance | all | no | font, atkinson, dyslexia, readable |
   | `reduce-motion` | Reduce motion in this app | appearance | all | no | animation, motion, accessibility |
   | `screen-reader-mode` | Screen reader mode | appearance | web | no | voiceover, talkback, accessibility |
   | `light-follows-device` | Light follows the device | appearance | all | no | tilt, motion, specular |
   | `app-icon-follows-skin` | App icon follows the skin | appearance | apps | no | icon, home screen |
   | `reader-direction` | Direction | reading-manga | all | no | left to right, right to left, vertical, rtl |
   | `reader-brightness` | Brightness | reading-manga | all | no | dim, light |
   | `reader-warmth` | Warmth | reading-manga | all | no | night, amber, blue light |
   | `reader-fit` | Fit | reading-manga | all | no | width, height, original, zoom |
   | `reader-tap-zones` | Tap zones | reading-manga | all | no | taps, left, right, menu |
   | `reader-chapters` | Chapters | reading-manga | all | no | continuous, one at a time |
   | `reader-page-gap` | Page gap | reading-manga | all | no | gap, spacing, strip |
   | `reader-cinema` | Cinema mode by default | reading-manga | all | no | immersive, hide controls |
   | `reader-keep-awake` | Keep screen awake | reading-manga | apps | no | sleep, screen, wake |
   | `reader-auto-next` | Auto next chapter | reading-manga | all | no | next, continue |
   | `reader-lock` | Lock reader controls | reading-manga | all | no | lock, taps, unlock |
   | `reader-volume-keys` | Volume keys turn pages | reading-manga | android | no | volume, buttons |
   | `reader-refresh-rate` | Refresh rate | reading-manga | android | no | 120, hz, smooth, fps |
   | `reader-reset` | Reset reader settings | reading-manga | all | no | defaults, restore, reset |
   | `novel-face` | Reading face | reading-novels | all | no | font, literata, sans, atkinson |
   | `novel-size` | Text size | reading-novels | all | no | font size, bigger, smaller |
   | `novel-line-height` | Line height | reading-novels | all | no | leading, spacing |
   | `novel-measure` | Measure | reading-novels | all | no | column, width, line length |
   | `novel-paper` | Paper | reading-novels | all | no | background, sepia, colour |
   | `novel-mode` | Scroll or paged | reading-novels | all | no | pages, scroll, layout |
   | `novel-page-turn` | Page turn | reading-novels | all | no | slide, lift, fade |
   | `listen-speed` | Default speed | listen | all | no | narration, playback, rate |
   | `listen-continue` | Continue to the next chapter | listen | all | no | autoplay, next |
   | `listen-sleep` | Sleep timer default | listen | all | no | sleep, timer |
   | `listen-shake` | Shake to extend | listen | apps | no | shake, sleep timer |
   | `ambient-page-tint` | Page-tinted chrome | ambient | all | no | colour, tint, dynamic |
   | `ambient-cruise` | Cruise default speed | ambient | all | no | auto-scroll, autoscroll, speed |
   | `ambient-guided` | Guided view by default | ambient | all | no | panels, panel by panel |
   | `ambient-soundscape` | Soundscape defaults | ambient | all | no | ambience, rain, sound |
   | `mature-content` | Show 18+ content | content | all | no | adult, mature, nsfw, gate |
   | `haptics` | Haptics | feedback | apps | no | vibration, taptic |
   | `haptics-feel` | Feel it | feedback | apps | no | test, vibration |
   | `ui-sounds` | UI sounds | feedback | all | no | clicks, sound effects |
   | `ui-sounds-volume` | UI sounds volume | feedback | all | no | loudness |
   | `ui-sounds-hear` | Hear it | feedback | all | no | preview, test |
   | `soundscape-scene` | Soundscape | feedback | all | no | ambience, rain, wind, ocean |
   | `soundscape-match` | Match the story | feedback | all | no | genre, automatic |
   | `soundscape-mix` | Soundscape mix | feedback | all | no | bed, detail, tone |
   | `soundscape-volume` | Soundscape volume | feedback | all | no | loudness |
   | `soundscape-lower` | Lower under narration | feedback | all | no | duck, listen |
   | `updates-schedule` | Update checks | notifications | all | yes | last check, next check |
   | `updates-auto` | Check for new chapters automatically | notifications | all | yes | updates, background |
   | `updates-startup` | Check when the server starts | notifications | all | yes | startup |
   | `updates-notify` | Notify me about new chapters | notifications | all | yes | notifications, alerts |
   | `updates-interval` | Check interval | notifications | all | yes | minutes, frequency |
   | `catalogue-cache` | Source catalogue cache | notifications | all | yes | cache, ttl |
   | `change-password` | Change password | security | all | no | password |
   | `sessions` | Where you're signed in | security | all | no | devices, sessions, sign out |
   | `sign-out-everywhere` | Sign out everywhere | security | all | no | revoke, devices |
   | `members` | Members | members | all | yes | accounts, users, deactivate, delete |
   | `storage` | Storage | storage | all | no | downloads, space, cache |
   | `backup-nightly` | Nightly backup | backup | all | yes | backup status |
   | `backup-export` | Export backup | backup | all | yes | download database |
   | `backup-restore` | Restore from a backup | backup | all | yes | import, restore |
   | `server-url` | API base URL | server | apps | no | server, address, url |
   | `diag-rendering` | Rendering performance | diagnostics | all | no | fps, jank, frames |
   | `diag-display` | Display | diagnostics | apps | no | refresh rate, resolution |
   | `diag-device` | Device | diagnostics | all | no | version, build |
   | `diag-image-cache` | Image cache | diagnostics | apps | no | memory, images |
   | `diag-glass` | Glass renderer | diagnostics | all | no | impeller, refraction, layers |
   | `diag-motion-timings` | Show motion timings | diagnostics | all | no | animation, debug |
   | `diag-calibration` | Glass calibration | diagnostics | all | no | checkerboard, debug |
   | `diag-preview-glass` | Preview Glass skin | diagnostics | all | no | debug, skin |
   | `shortcuts` | Keyboard shortcuts | keyboard | all | no | keys, hotkeys |
   | `single-key-shortcuts` | Single-key shortcuts | keyboard | all | no | keys, letters |
   | `account` | Account | profile | all | no | username, name |
   | `profiles` | Profiles | profile | all | no | manage profiles, add profile |
   | `sign-out` | Sign out | profile | all | no | log out |
   | `app-updates` | Updates | about | all | no | version, update, sidestore, apk |
   | `whats-new` | What's New | about | all | no | changelog, release notes |
   | `licences` | Open-source licences | about | all | no | licenses, credits, fonts |
   | `share-reading` | Share what I'm reading | circle | all | no | sharing, activity, privacy |
   | `show-reactions` | Show my reactions | circle | all | no | reactions |
   | `accept-recommendations` | Accept recommendations | circle | all | no | letters, recommend |
   | `show-presence` | Show me in presence | circle | all | no | reading now, online |
   | `shared-shelves` | Let others add me to shared shelves | circle | all | no | collections, shelves |
   | `share-streak` | Share my streak | circle | all | no | streak, flame |
   | `include-mature-activity` | Include 18+ titles in my activity | circle | all | no | adult, mature |
   | `hidden-from-circle` | Hidden from my Circle | circle | all | no | hide, exclude |
   | `clear-activity` | Clear my activity | circle | all | no | delete, history |
   | `previously-on` | Previously on | ai | all | no | recap, summary |
   | `recap-skip` | Series you asked not to recap | ai | all | no | recap, skip |
   | `clear-not-interested` | Clear "Not interested" | ai | all | no | reset, picks |
   | `ai-status` | AI status | ai | all | no | availability, asks |

   Rows are left out of the results when hidden on this platform, for this role (admin), by the server's `capabilities`, by the gate (`include-mature-activity` only while the gate is open), or by the flag (`diag-preview-glass` only while `Flags.glassAvailable` is false). Filter test: every-word matching on label and keywords, case-insensitive and folded with `foldDiacritics`; each exclusion rule.
B3. **Phone root layout:** large title "Settings" (`LetterReveal` once per session; the title capsule when it scrolls away); a search well "Search settings" (44 px `fill3` content well, leading magnifier); the Account block (a grouped-list row: the profile orb 44, the display name in `headline`, "@username" in `footnote` `label2`, an "Admin" tag for admins; → `profile`); the grouped list "Settings" in §8.24's order, rows 52 tall (§7.17), each with a 30 × 30 icon tile (radius 12, an 18 px white glyph): Appearance and skin (`paint-brush` on `iris600`), Reader (`book-open` on `iris700`), Content (18+) (`age-gate` on `surface3`), Circle and privacy (`users-three` on `surface3`), AI and recaps (`sparkle` on `surface3`), Sound and haptics (`speaker-high` on `iris800`), Notifications (admins; `bell-simple` on `danger`), Security (`lock-simple` on `surface3`), Storage (`hard-drives` on `surface3`), Backup (admins; `cloud-arrow-up` on `surface3`), Server (apps; `plugs-connected` on `surface3`), Diagnostics (`pulse` on `surface3`), Shortcuts (tablet and desktop frames once a hardware key event has been seen this session; `keyboard` on `surface3`); then the group "About" with About (`info` on `surface3`); the footnote "Settings save as you change them. Switching skin restarts the app." §8.25 says only "the section's colour"; the tile colours are this file's choice (name them in the report), and a unit test asserts white on each tile colour is at least 3:1.
B4. **Search overlay (phones):** tapping the well opens a full-screen overlay (the page's black ground, the field at the top with "Cancel") listing the matching index entries grouped by section as rows (label, the section name in `footnote` `label2`); a tap pushes that section, scrolls to the row and flashes it with the **Row pulse** (`iris600` at 14 % fading to 0 over 900 ms on the `fadeOut` curve; reduced motion: shown 900 ms then removed); "No settings match “{q}”" when empty. Android back and `Esc` close the overlay first (§8.0.5 rule 9). **Tablet and desktop frames:** a 36 px `fill3` capsule "Search settings" heads the section list; typing replaces the list in place with the matching rows grouped by section; `Enter` or a tap opens that section at right and flashes the row; `Esc` clears and restores the list; `/` focuses it; under the section list the quick links "Reading history" (`Routes.history`) and, for admins, "System status" (`Routes.status`).
B5. **Section availability:** sections the server does not offer (`GET /settings` `capabilities`) are hidden; with no active profile, profile-scoped sections show the inline notice "Choose a profile first" with a "Choose a profile" link (`Routes.profiles`) and every control disabled; server-backed sections (Content, Circle and privacy, AI and recaps) show row skeletons while loading, an inline error block with "Try again" when the load fails, and, offline, the notice "These settings need a connection" with their controls disabled; device settings (Haptics, UI sounds, Shortcuts, Appearance) always work.
B6. **Sections owned by `mobile/40`** (`notifications`, `security`, `members`, `backup`, `server`, `diagnostics`, `admin`): their rows and index entries exist; opening one renders the Glass skin's pending body until `mobile/40` replaces it (keep them in one `sectionsBuiltLater` set in `settings_sections.dart` that `mobile/40` empties).

### C. Appearance and skin (§8.25.1)

C1. **Skin cards:** two large preview cards (phones stacked, each a row: the preview 160 × 347 at the left, the text at the right; tablet and desktop frames side by side, the preview 240 × 520 on top), each playing its skin's frame loop: Glass `mobile/assets/skin_previews/glass/000–035.png` (item O), Cinematic `mobile/assets/skin_previews/cinematic/000–035.png` (`mobile/18`), 36 frames at 166 ms each (a 6 s loop) driven by a `Ticker` swapping precached `Image.asset` frames with `gaplessPlayback: true`, paused while off screen (`TickerMode` / visibility) and under reduced motion (the still frame `000.png` with a "Play preview" plain button that plays one loop). Each card: the name in `title2` ("Glass", "Cinematic"), the character line in `footnote` `label2` ("Liquid glass, springs and depth." / "Dark cinema, posters and title cards."), and a "Current" tag (20 tall `fill2` capsule, `caption1` 600) on the active one. The cards are one radio group "Skin" (`Semantics(inMutuallyExclusiveGroup: true, checked:, label: 'Cinematic skin. Dark cinema, posters and title cards.')`). Choosing the other card starts item D; choosing the current one does nothing but announce "Glass is the current skin". Both cards show in debug builds while `Flags.glassAvailable` is false (Glass is reachable only through the debug row until `release/01`; switching to Cinematic is always allowed).
C2. **Solid glass** switch (forces the Reduce Transparency look: `SkinGlass` renders `solid1` / `solid2`). **Increase contrast** switch (OR-ed with the OS: Android 14+ `mm/platform` `a11y.contrastLevel`, iOS `MediaQuery.highContrastOf`). **Legible text** switch with the preview sentence "Read the next chapter" set twice (Google Sans Flex and Atkinson Hyperlegible Next); toggling rebuilds the theme through `GlassTokens.legible` without a restart. **Reduce motion in this app** switch (forces the §4.11 rules whatever the OS says). These four are per profile in `mm.boot.a11y` (A1). Screen reader mode is web only and absent here.
C3. **Light follows the device** switch (per profile, `mm.glass.prefs` `lightFollowsDevice`, default on in the apps); off pins the light at 135°.
C4. **App icon follows the skin** switch (apps only; per device `mm.icon.follow`; default off), captioned "Home-screen shortcuts to the old icon stop working." Turning it on changes nothing until the next explicit skin choice on this device (§12.2).
C5. Every switch fires `toggle.on` / `toggle.off` and the `toggle-on` / `toggle-off` cues when sounds are on; the knob travels on `springTick`.

### D. The skin switch and restart (§8.25.2)

D1. **Choose:** tapping the Cinematic card opens a plain **alert** (§7.11: `glassThick` T4, 300 wide on phones and 420 on tablet and desktop frames, radius 26, padding 20) blooming from the card (scale 0.9 from the card's rect on `springMorph`, materialising; `dimModal` over 180 ms): the Cinematic preview loop small at the top (120 × 260), the title "Restart in Cinematic?", the body "Everything about the app changes: layout, navigation, type and motion. Your library, progress and downloads stay exactly as they are, and you'll come back to this screen." plus, when the download queue is not empty, the inline notice "Downloads pause for a moment and resume after the restart.", and, when offline, "This profile will switch on your other devices once you're back online." Buttons: **"Stay in Glass"** (secondary, first, initial focus) and **"Restart in Cinematic"** (the alert's tinted twin). No hold: nothing is lost and the 10 s Undo exists. `Esc` and Android back cancel.
D2. **Persist:** `skin.switch` (`heavy`); `mobile/01`'s `switchSkin(SkinId.cinematic, explicit: true)` (extend it skin-neutrally if its parameters differ): `PATCH /profiles/{id} {skin: "cinematic"}` through the offline outbox; `mm.skin.active` = `cinematic`; `mm.skin.return` = the current location (`GoRouterState.of(context).uri`); `mm.skin.prev` = `glass` (add this key skin-neutrally if `mobile/01` has none; the arriving skin reads it); `mm.skin.t0` = now.
D3. **Outgoing, the melt** (`GlassMotion.play(MotionName.skinMelt)`, 615 ms per §8.25.2 step 3 and the §4.10 Skin melt row; the series plan's "620 ms" is superseded by the contract; the three parts run together and the `springPage` settle ends it): every `SkinGlass` surface dematerialises at once (350 ms; `SkinGlass`'s registry broadcasts one `dematerializeAll`), the whole app blurs 0 → 40 px on `springSmooth` (an `ImageFiltered` at the app root, `ImageFilter.blur(sigmaX: s, sigmaY: s)`), and a circular mask closes from the farthest corner to the centre of the screen on `springPage` (`ClipPath` over `#000000`), leaving black; the `melt` cue when UI sounds are on. Reduced motion: a 200 ms fade to black.
D4. **Restart:** when the mask has closed, item E's icon call runs (iOS only, when it applies), then `AppRestart.of(context).restart()`. Budget: under 1.5 s from the confirm to the Cinematic splash (log the `mm.skin.t0` delta in debug builds; it shows in Settings → Diagnostics → Show motion timings).
D5. **Incoming Cinematic:** Cinematic plays its own splash and its own 10 s "Switched to Cinematic · Undo" toast (`mobile/18`); confirm it reads `mm.skin.prev` / `mm.skin.t0` and, if it reads a different key, write that key too in D2.
D6. **Arriving into Glass** (from Cinematic, on the Glass side): the Glass shell plays the full Droplet reveal (`mobile/29`, §12.4), lands on the return route, and shows the toast "Switched to Glass" + "Undo" with a 10 s draining rim (§7.12) when `mm.skin.prev == "cinematic"` and `mm.skin.t0` is less than 10 s old; it clears both keys after showing. Undo runs D2–D4 back to Cinematic without the alert (an explicit choice, so the icon rule applies); `undo` haptic. `mobile_39_arrival_test.dart` covers the condition (fresh, stale, wrong previous skin).
D7. **Profile hand-off switch:** when a profile whose skin differs is picked, D2–D5 run inside the profile hand-off (`mobile/30`) with no alert, no Undo toast and no icon change (`switchSkin(…, explicit: false)`), per `stack-decision.md` §2.4.
D8. **Other entry points:** expose `GlassSkinSwitch.start(BuildContext context, SkinId target, {Rect? origin})` (the alert and D2–D4) and route onboarding step 2 and the active profile's form skin row (`mobile/30`) through it if they call a placeholder today.

### E. App icon (§12.2, `mobile/lib/core/platform/app_icon_switcher.dart`)

E1. `AppIconSwitcher.onExplicitSkinChoice(SkinId skin)` returns at once unless `mm.icon.follow` is true **and** `Flags.glassAvailable` is true (alternate icons are registered only in `release/01`; until then it logs `icon: skipped, glass_available false`). It is never called for a profile hand-off (D7) or a boot-time mismatch restart.
E2. **iOS:** `FlutterDynamicIconPlus.setAlternateIconName(iconName: skin == SkinId.glass ? glassIosIconName : null)` inside the restart moment (after the melt reaches black, before `AppRestart.restart()`), so the system's one-line alert lands over black; `null` restores the primary icon, which is Cinematic's since `release/00`. `glassIosIconName` = `'AppIcon-Glass'` (§12.2). If the precondition grep found the Glass alternate registered under another name (the `shared/05` plan text says `GlassIcon`), set the constant to the registered name so the call can succeed, and list the mismatch as an open issue for `release/01`.
E3. **Android:** store `mm.icon.pending` = `'GlassIcon'` or `'CinematicIcon'` (the `.GlassIcon` / `.CinematicIcon` aliases of `shared/05`); an `AppLifecycleListener(onPause:)` registered once at app start (skin-neutral) applies it with `FlutterDynamicIconPlus.setAlternateIconName(iconName: pending, blacklistBrands: [], blacklistManufactures: [], blacklistModels: [])` and clears the key; it never runs during the restart, because a component toggle can end the task.
E4. Tests with a fake plugin: follow on + flag on → the iOS call happens in the restart moment and the Android call waits for `paused`; follow off → no call; flag off → no call; a profile hand-off → no call; the icon shows the skin last chosen on this device.

### F. Reader defaults (§8.25.3), section `reading-manga`

Every row writes the profile default in the store that owns it and states its scope in a `caption1` line ("All series", or "Books and series without their own setting"). Rows:

F1. **Manga:** Direction (segmented Left to right · Right to left · Vertical); Brightness default (slider 20–100 %, step 5 %, `detent.tick` per step, writing `brightness` 0.2–1.0); Warmth default (slider 0–100 %, step 5 %); Fit (segmented Width · Height · Original); Tap zones (`mobile/35`'s phone-silhouette diagram, tap a band to cycle Previous · Menu · Next, "Reset to automatic"); Chapters (segmented Continuous · One at a time); Page gap (switch); Cinema mode by default (switch); Keep screen awake (switch, apps); Auto next chapter (switch); Lock reader controls (switch, caption "Tap the centre 5 times to unlock"); Volume keys turn pages (switch, Android); Refresh rate (choice chips Auto · 30 · 60 · 90 · 120, Android, caption "Auto uses the highest rate your screen supports"); **Reset reader settings** (`mobile/26`'s HoldToConfirm, 1,200 ms: `hold.ramp`, the Hold fill, `hold.done`; toast "Reader settings reset"; the always-visible fallback button opens an alert with "Cancel" / "Reset").
F2. **Novels** (the defaults for books with none of their own; `mobile/36`'s records): face (three tiles, each in its own face), size (stepper 15–30), line height (1.40–2.10), measure (48–88 ch), paper (the seven orbs), Scroll · Paged, page turn Slide · Lift · Fade.
F3. **Listen** (the shared listen settings of `mobile/15` / `mobile/37`): Default speed (a stepped slider 0.5–3.0× in 0.05 steps, `detent.tick` every 0.25×, the magnet at 1.0× within ±0.08 with `detent.magnet`, the value in `mono` "1.25×"); "Continue to the next chapter" (switch, `autoPlayNext`); Sleep timer default (a menu: Off · 5 · 10 · 15 · 30 · 45 · 60 min · End of chapter · End of next chapter); "Shake to extend" (switch, apps, `glassShakeToExtend`, caption "Works while ManhwaManiacs is open.").
F4. **Ambient:** Page-tinted chrome (switch; the shared page-tint switch); Cruise default speed (a slider 0.25–4× on a logarithmic track, 0.05 steps, the magnet at 1.0×, writing A8's `cruiseSpeed`); Guided view by default for chapters with panels (switch, A8's `guidedDefault`); a row "Soundscape defaults" → the Sound and haptics section scrolled to its soundscape group.

### G. Content (§8.25.4), section `content`

The 18+ switch and flow of §7.25 (`mobile/28`'s gate alert with hold-to-confirm and its always-visible fallback button; `PUT /settings {mature_content_enabled}` for the active profile); turning it off runs `purgeMatureLocal` (`mobile/29`) at once; with no profile, the blocked notice of B5.

### H. Sound and haptics (§8.25.5), section `feedback`

H1. **Haptics** switch (default on) writing the toggle `skin_haptics.dart` honours; if `mobile/02` made that toggle per profile rather than per device (§8.25.5 says per device), keep `mobile/02`'s scope and record the difference in the report. The **"Feel it"** row plays `selection`, `soft(0.5)`, `rigid(0.6)`, `ahap:droplet` and `success` 400 ms apart; disabled with the caption "Turn haptics on to feel them." while haptics are off.
H2. **UI sounds** switch (per device, default off), the volume slider −24 to 0 dB (step 1 dB, default −6), and the **"Hear it"** row playing `tap`, `push-1`, `push-2`, `push-3`, `push-4`, `back` and `add` 300 ms apart (it plays even while the switch is off, at the slider's volume).
H3. **Soundscape defaults** (A7; caption "Saved on this device."): the scene as a radio group of seven 44 px `fill2` twin orbs (Off `speaker-slash`, Rain `cloud-rain`, Wind `wind`, Ocean `waves`, Hearth `campfire`, Stream `drop-half`, Deep `moon-stars`); Match the story (switch, default on); the mixer Bed · Detail · Tone (sliders 0–100 %, defaults 80 / 50 / 30, `detent.tick` every 10 %); the volume (−30 to 0 dB, default −12); Lower under narration (switch, default on).

### I. Shortcuts (§8.25.13), section `keyboard`

Shown on tablet and desktop frames once a hardware key event has been seen this session (the key registry of `mobile/29` records it). The live registry grouped General, Navigation, Library, Search, Sources, Reader, Novel reader, Listen; each row a description and `mobile/26`'s keycaps; the **Single-key shortcuts** switch (default on); "No shortcuts are active on this screen" when a group is empty.

### J. Account, language and About (§8.25.14), sections `profile` and `about`

J1. **Account:** the orb, the display name, "@username", the Admin tag; rows "Password and security" (→ `security`, `mobile/40`), "Profiles" (→ `Routes.profilesManage`), "Sign out" (an alert "Sign out? You'll need to sign in again on this device." with "Cancel" and the solid `danger` "Sign out").
J2. **App language** is not shown; the stored K14 `settings_language` stays untouched.
J3. **About:** the app card ("ManhwaManiacs", "A self-hosted manga, manhwa and web-novel reader", version and build from `package_info_plus`); the updates row (Android APK channel through `app_update_provider.dart`: "Up to date · 3.5.0" / "Update available · 3.5.0 → 3.5.1" + "Download update" opening `?sheet=app-update` (`mobile/29`) / "Checking…" / `warning` "Couldn't check for updates" + Retry / "Server unreachable"; iOS: "Managed by SideStore" with the source URL, "Copy source URL" (toast "Source URL copied"), and the legacy S28 #23 card's 7-day signature caption reused word for word); "What's New" (`?sheet=whats-new`, `mobile/29`); "Open-source licences" (J4); "Reset reader settings" (the F1 control). An external link that fails to open shows "Couldn't open {site}".
J4. **Open-source licences** (`/settings/about?sheet=licenses`, a `large` `GlassSheetPage`; a 560 px window on the desktop frame): a search well "Search packages"; rows 52 tall grouped by kind: **Fonts** (the `LicenseRegistry` entries whose package name is one of the font families `mobile/03` registers), **App packages** (every other `LicenseRegistry.licenses` entry), **Artwork and sounds** (a `const` list in `mobile/lib/skins/glass/copy/art_licences.dart`, one entry per file present at authoring time in `brand/onboarding/styles/` and `backend/media/soundscapes/glass/SOURCES.md`, plus "Demo covers" and "Demo pages" as the project's own, CC0-1.0; the group is hidden when empty); **Web packages** is web-only and absent here. Each row: the package name in `mono` 13 `label1`, its version in `caption1` `label3` (from `mobile/lib/skins/glass/copy/package_versions.g.dart`, written by `mobile/tool/gen_package_versions.dart` from `pubspec.lock`; `test/skins/glass/package_versions_test.dart` fails when the lock file and the table differ; fonts show "Font"), and a licence tag capsule from `licence_kind.dart` (+ test: "Permission is hereby granted" → MIT; "Redistribution and use in source and binary forms" with "Neither the name" → BSD-3-Clause; "Apache License" → Apache-2.0; "SIL Open Font License" → OFL-1.1; "CC0" → CC0-1.0; otherwise "Other"). A tap pushes the licence text inside the sheet in `mono` 13/20 `label2`, titled with the package name, with "Copy" in the header (toast "Copied"). States: loading (8 row skeletons), no match "No package matches “{q}”", error "Couldn't load the licences" + Try again. Keys: `/` search, arrows, `Enter` opens, `Esc` back. `mobile/40`'s You hub "Licences" row reuses this sheet.

### K. Circle and privacy (§8.25.15), section `circle`

Grouped rows with the plain explanations under each, loaded from `GET /profiles/{id}/sharing`, each change a partial `PATCH /profiles/{id}/sharing` (A5): **Share what I'm reading** (master, default off; "Other readers on this server see what this profile starts and finishes. Never your bookmarks, searches, reading time or downloads."); **Show my reactions** (default on once sharing is on); **Accept recommendations** (default on; "Friends can send you series. Off: you won't appear in their Recommend list."); **Show me in presence** (default off; "Your orb moves to the front of the Circle while you're reading."); **Let others add me to shared shelves** (default on); **Share my streak** (default off); **Include 18+ titles in my activity** (only while this profile's gate is open; default off; "Even when on, 18+ titles are shown only to readers whose own 18+ setting is on."); **Hidden from my Circle** (a list of `excluded_series`, each row a 36 × 54 cover, the title and "Unhide"; empty "Nothing hidden. Hide a series from its ⋯ menu."); **Clear my activity** (a destructive plain button → alert "Remove everything you've shared so far? Your reading stays; your Circle just won't see past activity." with "Keep it" / the solid `danger` "Clear" → `DELETE /circle/activity`; toast "Your shared activity was cleared"; `delete.confirm`); the **preview line** in `footnote` `label2`, typed once at 12 ms per character when a switch changes: "Others see: {profile name} finished chapter {n} of {title}." from the profile's latest completed history row, "Others see: {profile name} started a series." when there is none, and "Others see nothing from this profile." while the master switch is off (the last two lines are this file's wording; name them in the report). States: loading (6 row skeletons), error + Try again, offline ("Sharing settings need a connection"; switches disabled), no profile (B5).

### L. AI and recaps (§8.25.16), section `ai`

**Previously on:** a three-segment control Off · Ask · Always (default Ask) with the explainer "Ask: when you come back to a series after a week, we offer a quick recap. Always: the recap opens first. Chapter recaps are offered after 3 days away." and the caption "Saved on this device." (A6). **Series you asked not to recap:** the `skipSeries` entries with cover and title from the library cache and "Ask again" per row; empty "You haven't turned recaps off for any series." **Clear "Not interested":** "Series you dismissed from AI picks can appear again." → `POST /ai/feedback {signal: "clear"}`, toast "Your AI picks start fresh". **AI status line** from `GET /library/suggest/availability`: "AI picks are on · 7 of 10 asks left today", or the reason's long line from `mobile/28`'s `copy/ai.dart` (§9.1.5).

### M. States, keys and budget

M1. Every section has its loading, error, offline and no-profile states per B5; toasts per §7.12 (a screen reader keeps them until dismissed).
M2. **Hardware keys:** `/` searches settings; `↑` / `↓` move between sections (tablet and desktop frames); `Enter` opens a section; `Esc` returns to the section list (and closes the search overlay first). Register them under "Settings".
M3. **Budget (§15.7):** a Settings page carries the nav row group and at most a toast; the switch alert over it stays within 4 layers / 8 shapes; the melt dematerialises every layer at once.

### N. Semantics and focus

Route focus lands on each page's large title; every row is one semantics node with its value ("Solid glass, off, switch"); the skin cards are a radio group; the alert takes focus on "Stay in Glass" and returns it to the card on cancel; the Row pulse target takes focus after a search hit.

### O. Skin preview frames (§8.25.1, §12.7)

Add a capture mode to the harness: `mobile/test/screenshots/glass/skin_preview_capture_test.dart`, run with `MM_WRITE_PREVIEWS=1`, renders the Glass skin over the seeded demo profile (the harness's demo covers and demo pages; nothing mature) with fake providers and a fake clock, and writes 36 PNG frames 166 ms apart into `mobile/assets/skin_previews/glass/000.png` … `035.png` at 270 × 585 px (the 360 × 780 preview ratio): frames 000–011 Home with the spotlight paging once, 012–020 the poster Zoom into the series sheet, 021–029 the Dive into the manga reader with the demo pages scrolling, 030–035 the dock droplet travelling Home → Library. The 36 frames together must stay at or under 3 MB; if they do not, capture at 240 × 520 instead and record the size. Declare `assets/skin_previews/glass/` under `flutter: assets:` in `mobile/pubspec.yaml`.

## Out of scope here (owned by later steps; do not build)

- `mobile/40`: §8.24 You and About hub, §8.25.6 Notifications, §8.25.7 Security, §8.25.8 Members, §8.25.10 Backup, §8.25.11 Server, §8.25.12 Diagnostics (including the "Preview Glass skin" row), §8.26 System status.
- `mobile/41`, `mobile/42`, `mobile/43`, `mobile/44`: the features whose defaults this step stores (recaps, statistics, the Circle screens, cruise, guided view, the soundscape player).
- `release/01`: registering the alternate icons, flipping `flags.glass_available`, deleting the debug row.
- Any change to `design/`, `frontend/`, `backend/` or Cinematic behaviour.

## File layout

```
mobile/lib/features/settings/providers/boot_a11y_provider.dart, glass_prefs_provider.dart   A1, A2 (only if missing)
mobile/lib/features/settings/utils/glass_prefs_migration.dart (+ test)   A4
mobile/lib/features/circle/…                                             A5 (sharing fields)
mobile/lib/features/ai/providers/recap_settings_provider.dart            A6 (only if missing)
mobile/lib/features/reader/providers/soundscape_defaults_provider.dart   A7 (only if missing)
mobile/lib/features/reader/…                                             A8 (cruiseSpeed, guidedDefault)
mobile/lib/core/platform/app_icon_switcher.dart (+ test)                 A3, E
mobile/lib/app/app_restart.dart, mobile/lib/skins/skin.dart              D2 (mm.skin.prev, only if missing)
mobile/lib/skins/glass/copy/settings_index.dart, art_licences.dart, package_versions.g.dart   B2, J4
mobile/tool/gen_package_versions.dart                                    J4
mobile/lib/skins/glass/screens/settings/
  settings_screen.dart, settings_sections.dart, settings_search_overlay.dart, settings_row.dart, icon_tile.dart   B
  appearance_section.dart, skin_card.dart, preview_loop.dart             C
  skin_switch_alert.dart, skin_melt.dart, glass_skin_switch.dart, arrival_toast.dart   D
  reader_defaults_section.dart                                           F
  content_section.dart, feedback_section.dart, shortcuts_section.dart    G, H, I
  account_section.dart, about_section.dart, licences_sheet.dart, licence_kind.dart     J
  circle_privacy_section.dart, ai_recaps_section.dart                    K, L
  settings_keys.dart                                                     M2
mobile/lib/skins/glass/router.dart                                       settings routes, removed from PENDING
mobile/assets/skin_previews/glass/000.png … 035.png                      O
mobile/pubspec.yaml                                                      assets entry only
mobile/test/skins/glass/settings/                                        widget tests (incl. mobile_39_arrival_test.dart, settings_index_parity_test.dart)
mobile/test/screenshots/glass/mobile_39_settings_shots_test.dart, skin_preview_capture_test.dart
docs/redesign/proof/mobile-39/                                           plan.md, screenshots, device-checklist.md, report.md
```

## Acceptance criteria

- [ ] `settings` is gone from the Glass `PENDING` set; the completeness and import-boundary tests pass.
- [ ] The migration test proves every §8.25.3 mobile row (brightness and warmth kept, K11 Dark → Graphite and AMOLED / Paper → Black, K05 seeding `keepAwake` once, K15 through `mobile/32`'s function, K01 / K02 through `mobile/35`'s seeding, K26 through `mobile/36`), idempotence, isolation between profiles and untouched old keys.
- [ ] The settings index holds every row of the B2 table (or of `design/settings-index.json`), the filter test passes, and the parity test runs when the web file exists; the search overlay finds a row by label or keyword, opens its section and flashes it with the Row pulse; "No settings match “{q}”" shows when empty; Android back closes the overlay first.
- [ ] The Settings root lists every section in §8.24's order with its tile (white glyph ≥ 3:1 on every tile colour, unit test), the Account block and the footnote; hidden sections follow capabilities, role and platform; the no-profile, loading, error and offline states render; `mobile/40`'s sections open the pending body.
- [ ] Appearance: both skin cards play their 36-frame loops at 166 ms per frame and pause off screen; reduced motion shows the still frame with "Play preview"; the four accessibility switches write `mm.boot.a11y`, and Legible text swaps the whole UI without a restart; Light follows the device and App icon follows the skin (off by default, with its caption).
- [ ] Skin switch: the alert blooms from the card with the exact copy, the downloads notice and the offline line; "Stay in Glass" has initial focus; confirming fires `skin.switch`, writes the PATCH to the outbox and the device keys, plays the 615 ms melt (200 ms fade under reduced motion) and restarts into Cinematic in under 1.5 s (debug log); the arriving Glass side shows "Switched to Glass" with a 10 s Undo only when the arrival condition holds; Undo switches back without the alert; the profile hand-off switches without an alert, Undo or icon change.
- [ ] App icon: the fake-plugin tests prove E1–E4 (no call while `Flags.glassAvailable` is false or the switch is off; iOS inside the restart moment with the registered Glass name; Android deferred to `paused` with empty blacklists; never on a hand-off).
- [ ] Reader defaults: every row of F1–F4 with its range, step, default, scope caption and haptics; HoldToConfirm resets with the toast; the Novels, Listen and Ambient values are read by `mobile/35`, `mobile/36`, `mobile/37` and A8's fields.
- [ ] Content, Sound and haptics ("Feel it" timing and disabled caption, "Hear it" sequence, the soundscape defaults with 80 / 50 / 30, −12 dB, both switches), Shortcuts, Account and About (updates row on both platforms, What's New, the licences sheet with its groups, versions, tags, text view and states), Circle and privacy (every switch, partial PATCH bodies, the gated 18+ row, Hidden from my Circle, Clear my activity, the typed preview line) and AI and recaps (the three segments, the skip list, Clear "Not interested", the status line) all behave as specified.
- [ ] The Glass preview frames exist at `mobile/assets/skin_previews/glass/000–035.png`, 36 files, at or under 3 MB together, declared in `pubspec.yaml`, captured by the harness mode.
- [ ] Hardware keyboard: `/`, `↑` / `↓`, `Enter` and `Esc` work in widget tests; focus returns to the card after the alert is cancelled.
- [ ] Hit targets: every control passes the iOS, Android and labelled tap-target guidelines.
- [ ] Reduced motion: the preview loops hold still, the alert fades in place (150 ms), the melt is a 200 ms fade to black, the Row pulse shows without a fade, letter reveals show at once, the typed preview line appears whole.
- [ ] Solid glass and Increase Contrast captures of the root and the alert.
- [ ] Per-skin difference: with the debug skin on CINEMATIC, Cinematic's Settings, edition picker, Stop the press and its Undo toast work as before (its tests pass; its harness capture unchanged); nothing under `mobile/lib/skins/cinematic/**` changed.
- [ ] `flutter analyze` reports "No issues found!"; `flutter test` passes at or above the floor plus the new tests.

## Verification

**RAM guard (production shares this box).** Before every `flutter analyze`, `flutter test`, harness and preview-capture run: `free -m`; if `available` is under 1024 MB, stop and report. `pgrep -f "next build"` must print nothing. One Flutter command at a time. No Gradle or Xcode on this box: CI's iOS dry run proves the icon plugin and `AppIcon-Glass.icon` still compile.

From the repository root, then `mobile/`:

```bash
free -m && node design/build.mjs --check
cd mobile
free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze
free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter test test/features test/skins test/core
free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter test
free -m && MM_WRITE_PREVIEWS=1 /srv/manhwamaniacs/dev/flutter/bin/flutter test test/screenshots/glass/skin_preview_capture_test.dart
du -ch assets/skin_previews/glass/*.png | tail -1
```

`flutter analyze` must report "No issues found!" and the full suite must pass at or above the floor (baseline 2012 plus every earlier step's tests). This step changes nothing in `frontend/` or `backend/` (`git diff --stat origin/feat/vps-slim-source-native -- frontend backend` is empty), so `npm run lint`, `npm run build` (in `frontend/`) and the backend pytest (`cd backend && .venv/bin/python -m pytest -q --no-header`) are not rerun, except the push rule under Git.

**Visual proof.** Write `mobile/test/screenshots/glass/mobile_39_settings_shots_test.dart` on the `mobile/03` harness (signed in as the seeded admin, and as a non-admin for the hidden admin rows) and run `free -m && MM_WRITE_SHOTS=1 /srv/manhwamaniacs/dev/flutter/bin/flutter test test/screenshots/glass/mobile_39_settings_shots_test.dart` at phone 390 × 844, tablet 820 × 1180 and the desktop frame 1180 × 820, into `docs/redesign/proof/mobile-39/`: `root-{phone,tablet,desktop-frame}.png`, `root-non-admin-phone.png`, `search-overlay-phone.png`, `search-no-match-phone.png`, `search-hit-pulse-phone.png`, `appearance-phone.png`, `appearance-desktop-frame.png`, `skin-cards-reduced-motion-phone.png`, `switch-alert-phone.png`, `switch-alert-downloads-offline-phone.png`, `melt-mid-phone.png` (at 300 ms), `arrival-toast-phone.png`, `reader-defaults-{manga,novels,listen,ambient}-phone.png`, `reset-hold-mid-phone.png`, `content-gate-phone.png`, `feedback-phone.png`, `feedback-haptics-off-phone.png`, `shortcuts-tablet.png`, `account-phone.png`, `about-android-phone.png`, `about-ios-phone.png`, `licences-phone.png`, `licence-text-phone.png`, `circle-privacy-phone.png`, `circle-privacy-offline-phone.png`, `ai-recaps-phone.png`, `no-profile-phone.png`, `root-solid-phone.png`, `root-contrast-phone.png`, `cinematic-settings-phone.png` (unchanged). Compare the phone captures with `docs/redesign/proof/web-39/*` phone captures when present and list the differences in the report.

`docs/redesign/proof/mobile-39/device-checklist.md` for the owner (iPhone via SideStore after CI builds the IPA; Android flagship from the CI APK), one line per check with an empty result box: Glass → Cinematic from the skin card lands on Settings in Cinematic with its Undo toast, in under 1.5 s (Show motion timings); Cinematic → Glass through the debug row plays the Droplet and shows "Switched to Glass · Undo", and Undo returns; a queued download resumes after both restarts; switching offline, then reconnecting, reaches the server (`GET /profiles` shows the skin); picking a profile with the other skin switches without an alert; the preview loops play smoothly and pause off screen; Legible text swaps fonts live; Solid glass and Increase contrast; the "Feel it" row; "Hear it"; the melt at 120 Hz; with a debug build that sets `Flags.glassAvailable` true locally (never committed), the iOS icon alert over black and the Android icon changing only after the app goes to the background; VoiceOver and TalkBack reading the skin radio group and the switch values. Write `docs/redesign/proof/mobile-39/report.md` mapping every screenshot to its acceptance item.

## Git

- Branch `feat/vps-slim-source-native`. Commit small and often: each A module with its test; the icon switcher; the index and the root; the search overlay; Appearance; the switch flow and the melt; the arrival toast; Reader defaults; Content, Sound and haptics, Shortcuts; Account, About and the licences sheet; Circle and privacy; AI and recaps; the preview frames (their own commit); the harness proof. Stage paths explicitly, never `git add -A` or `git add .`.
- Conventional messages (`feat(mobile-glass): skin switch melt and restart`). No Claude or AI attribution anywhere: no `Co-Authored-By` line, no "Generated with" line, no AI author. Never commit secrets or `.claude/`, and never commit a local `Flags.glassAvailable = true`.
- Before every push: `git fetch origin` and `git diff --stat origin/feat/vps-slim-source-native...HEAD -- frontend`; if it lists files, run `free -m && npm run build` in `frontend/` first (never while a Flutter command runs) and push only if it passes. Then `git push origin feat/vps-slim-source-native` after each working step; CI's APK build and iOS dry run must stay green.
- Never edit `backend/connectors/` or any backend file; never touch production containers or `/srv/manhwamaniacs/{app,data}`; do not deploy.

## Report back

Reply with:

1. Done items by scope letter (A to O), and anything not done with the reason.
2. The screenshot folder `docs/redesign/proof/mobile-39/` and its file list; the preview frames' total size and resolution; differences against the web twin's phone captures.
3. Test counts (`flutter test` passed before and after), `flutter analyze` result, `free -m` before each heavy command, the CI APK and iOS dry-run results for the last push.
4. The API left for `mobile/40` and later steps: `sectionsBuiltLater`, `GlassSkinSwitch.start`, `AppIconSwitcher`, the settings index entries and its source, the soundscape defaults, `cruiseSpeed` / `guidedDefault`, the recap settings provider, the licences sheet entry point.
5. Decisions made where the contract was silent or the platform differs (the tile colours, the `mm.skin.prev` key, the Glass iOS icon name in use, the haptics toggle scope, the preview frame size, the sharing preview lines, the settings-index source, the 300 ms "Hear it" spacing, the slider steps for brightness, warmth and cruise, `guidedDefault` off), and every place where `glass/DESIGN.md` overrode this file.
6. The owner device checklist path and open issues, each with its `glass/DESIGN.md` section.

Next prompt file: `docs/redesign/prompts/mobile/40-glass-you-about-admin-status.md`.
