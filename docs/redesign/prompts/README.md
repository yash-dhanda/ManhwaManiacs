# Redesign run book

**Missing prompt files: none.** All 110 files listed in `docs/redesign/prompts-plan.json` exist under `docs/redesign/prompts/` (checked 2026-09-29).

## What the series builds

These 110 prompt files rebuild ManhwaManiacs from zero as two complete apps on one shared data layer. Cinematic (dark, film-programme look in the spirit of Netflix, Apple TV+ and Crunchyroll) and Glass (Apple Liquid Glass depth, sheets, springs and haptics) each get their own tokens, type, icons, sounds, motion, navigation and screen implementations, on AMOLED `#000000`, on the web (Next.js) and on Android and iOS (Flutter). The shared track draws the design contract, token generator, icons, sounds and the new wordmark, icon and splash. The backend track adds per-profile skin plus the four new features: AI home and recommendations, reading stats and streaks, Circle (social for your 2 to 3 users), and ambient reader extras. The web and mobile tracks first build Cinematic end to end, including the two required reveals (the letter-by-letter heading reveal and the 50 ms typing headline). Step 67 then ships Cinematic as the default everywhere and deletes the old UI. After that the same tracks build Glass, and step 110 ships it as a real choice in Settings, so switching restarts the app into the other personality.

## Before you start

- Open tmux on the VPS with four windows named `shared`, `backend`, `web` and `mobile`, each in `~/code` (`/srv/manhwamaniacs/dev/ManhwaManiacs`) on branch `feat/vps-slim-source-native`.
- **One step = one fresh Claude Code session.** In the step's window, start `claude` (or type `/clear` in the one that just finished) and paste that step's line from the paste-lines section below. Run one step at a time per window.
- **Start a step only when every step in its "Waits for" column is done.** A step is done when its session has printed its Report back and its commits show in `git log --oneline -10`.
- All four windows work in the same checkout. The prompts stage explicit paths so they do not collide, and a RAM guard makes a step stop if `free -m` shows under 1024 MB available. Only one heavy build should run at a time.
- Every working step pushes with `git push origin feat/vps-slim-source-native:master`: that runs the test workflow only and publishes nothing. **A push of the `feat/vps-slim-source-native` branch itself publishes an iOS build to your SideStore source**, so only the two release steps (67 and 110) push that branch, once each.
- Do not run `docs/redesign/implement.workflow.js` (the automated 15-lane run from `lanes.json`) while you run steps by hand. Pick one of the two ways.

## Run order

Session: `Shared` and `Release` both run in window `shared`. `Web A`, `Web B` and `Web C` are the plan's three web groups, run one after another in window `web`; the same goes for `Mobile A` to `C` in window `mobile`. "Waits for" is the rule: those steps must be done first. "Parallel with" lists the steps that should be running in the other windows at the same time if all four windows keep moving; it comes from a schedule estimate, so treat it as a guide. Time is a rough guess of one session's length from the size of its file, excluding waits for you or for CI.

Rough total: about 340 session-hours of work. With four windows busy it is about 160 hours of wall clock, plus the time the checkpoints wait for you.

| Step | File | Track | Session | Parallel with steps | Waits for steps | Time |
|---:|---|---|---|---|---|---|
| 1 | `shared/00-design-contract-and-token-generator.md` | shared | Shared | 2, 5, 14 | none | 4 h |
| 2 | `backend/00-profile-columns-and-dev-stack.md` | backend | Backend | 1, 5 | none | 2.5 h |
| 3 | `shared/01-glass-tokens-haptics-motion-names-contrast.md` | shared | Shared | 4, 8, 14, 19, 22 | 1 | 3 h |
| 4 | `web/00-foundation-skin-engine-and-routes.md` | web | Web A | 3, 6, 8, 14, 19, 22 | 1, 2 | 3.5 h |
| 5 | `mobile/00-foundation-reader-engine-extraction.md` | mobile | Mobile A | 1, 2, 14 | none | 3 h |
| 6 | `shared/02-icon-sets-and-custom-glyphs.md` | shared | Shared | 4, 22, 25 | 1 | 3.5 h |
| 7 | `web/01-foundation-motion-deps-fonts-icons.md` | web | Web A | 9, 25 | 4, 6 | 2 h |
| 8 | `mobile/01-foundation-skin-engine-and-restart.md` | mobile | Mobile A | 3, 4, 14, 19, 22 | 5, 1, 2 | 3 h |
| 9 | `shared/03-ui-sounds-and-soundscape-audio.md` | shared | Shared | 7, 25, 28 | 3 | 2.5 h |
| 10 | `web/02-foundation-restart-haptics-sound.md` | web | Web A | 11, 13, 15, 28, 31 | 7, 3, 9 | 3.5 h |
| 11 | `mobile/02-foundation-native-plugins-haptics-sound.md` | mobile | Mobile A | 10, 15, 28, 31 | 8, 3, 9 | 3 h |
| 12 | `web/03-foundation-reader-seam-limiter-proof.md` | web | Web A | 13, 15, 16, 18, 31, 34 | 4, 2 | 3 h |
| 13 | `mobile/03-foundation-fonts-icons-harness-glass-gate.md` | mobile | Mobile A | 10, 12, 15, 16, 31, 34 | 11, 6 | 3 h |
| 14 | `backend/01-cover-ambient-and-palette.md` | backend | Backend | 1, 3, 4, 5, 8 | 2 | 2 h |
| 15 | `shared/04-brand-cinematic-and-platform-icons.md` | shared | Shared | 10, 11, 12, 13, 28, 31 | 6 | 4 h |
| 16 | `shared/05-brand-glass-and-art-intake.md` | shared | Shared | 12, 13, 17, 18, 31, 34 | 15 | 3.5 h |
| 17 | `web/04-cinematic-primitives-core-and-reveals.md` | web | Web A | 16, 18, 34, 37 | 10, 12 | 3 h |
| 18 | `mobile/04-cinematic-primitives-core-and-reveals.md` | mobile | Mobile A | 12, 16, 17, 34, 37 | 13 | 3.5 h |
| 19 | `backend/02-library-series-ocr-extensions.md` | backend | Backend | 3, 4, 8 | 14 | 2 h |
| 20 | `web/05-cinematic-primitives-overlays-controls-states.md` | web | Web A | 21, 37, 40 | 17 | 3 h |
| 21 | `mobile/05-cinematic-primitives-overlays-controls-states.md` | mobile | Mobile A | 20, 37, 40 | 18 | 3 h |
| 22 | `backend/03-stats-streaks-annual-listen-sessions.md` | backend | Backend | 3, 4, 6, 8 | 2 | 2.5 h |
| 23 | `web/06-cinematic-shell-navigation-transitions.md` | web | Web A | 24, 27, 40 | 20, 15 | 3.5 h |
| 24 | `mobile/06-cinematic-shell-navigation-transitions.md` | mobile | Mobile A | 23, 40 | 21, 15 | 3 h |
| 25 | `backend/04-ai-home-composition.md` | backend | Backend | 6, 7, 9 | 14, 22 | 3.5 h |
| 26 | `web/07-cinematic-auth-profiles-18plus.md` | web | Web A | 27, 30 | 23, 2 | 3 h |
| 27 | `mobile/07-cinematic-auth-profiles-18plus.md` | mobile | Mobile A | 23, 26 | 24, 2 | 3 h |
| 28 | `backend/05-ai-similar-recap-taste-onboarding.md` | backend | Backend | 9, 10, 11, 15 | 25 | 3 h |
| 29 | `web/08-cinematic-tonight.md` | web | Web A | 30, 33 | 26, 25, 14 | 3.5 h |
| 30 | `mobile/08-cinematic-tonight.md` | mobile | Mobile A | 26, 29 | 27, 25, 14 | 3.5 h |
| 31 | `backend/06-reader-tints-panels-novel-audio.md` | backend | Backend | 10, 11, 12, 13, 15, 16 | 2 | 2.5 h |
| 32 | `web/09-cinematic-library-shelf-browse.md` | web | Web A | 33, 36 | 29, 19 | 2.5 h |
| 33 | `mobile/09-cinematic-library-shelf-browse.md` | mobile | Mobile A | 29, 32 | 30, 19 | 2.5 h |
| 34 | `backend/07-media-routes-and-install-page.md` | backend | Backend | 12, 13, 16, 17, 18 | 9, 15 | 3 h |
| 35 | `web/10-cinematic-updates-collections-history-bookmarks.md` | web | Web A | 36, 39 | 32 | 2.5 h |
| 36 | `mobile/10-cinematic-updates-collections-history-bookmarks.md` | mobile | Mobile A | 32, 35 | 33 | 2.5 h |
| 37 | `backend/08-circle-core-sharing-presence.md` | backend | Backend | 17, 18, 20, 21 | 25, 22 | 3.5 h |
| 38 | `web/11-cinematic-feature-and-book-pages.md` | web | Web A | 39, 42 | 35, 19 | 3 h |
| 39 | `mobile/11-cinematic-feature-and-book-pages.md` | mobile | Mobile A | 35, 38 | 36, 19 | 3 h |
| 40 | `backend/09-circle-reactions-letters-shelves.md` | backend | Backend | 20, 21, 23, 24 | 37, 19 | 3 h |
| 41 | `web/12-cinematic-manga-reader-strip.md` | web | Web A | 42, 44 | 38 | 3.5 h |
| 42 | `mobile/12-cinematic-manga-reader-strip.md` | mobile | Mobile B | 38, 41 | 39 | 3 h |
| 43 | `web/13-cinematic-manga-reader-paged-readall-panels.md` | web | Web A | 44, 46 | 41 | 2.5 h |
| 44 | `mobile/13-cinematic-manga-reader-paged-readall-panels.md` | mobile | Mobile B | 41, 43 | 42 | 2.5 h |
| 45 | `web/14-cinematic-novel-reader.md` | web | Web B | 46, 48 | 43 | 3 h |
| 46 | `mobile/14-cinematic-novel-reader.md` | mobile | Mobile B | 43, 45 | 44 | 3 h |
| 47 | `web/15-cinematic-listen-mode.md` | web | Web B | 48, 50 | 45, 31, 22 | 2.5 h |
| 48 | `mobile/15-cinematic-listen-mode.md` | mobile | Mobile B | 45, 47 | 46, 31, 22 | 3 h |
| 49 | `web/16-cinematic-discover-search-sources-dialogue.md` | web | Web B | 50, 52 | 47, 19 | 3.5 h |
| 50 | `mobile/16-cinematic-discover-search-sources-dialogue.md` | mobile | Mobile B | 47, 49 | 48, 19 | 3.5 h |
| 51 | `web/17-cinematic-downloads-index-status.md` | web | Web B | 52, 54 | 49 | 3 h |
| 52 | `mobile/17-cinematic-downloads-index-status.md` | mobile | Mobile B | 49, 51 | 50 | 3 h |
| 53 | `web/18-cinematic-settings-and-edition-restart.md` | web | Web B | 54, 56 | 51 | 3 h |
| 54 | `mobile/18-cinematic-settings-and-edition-restart.md` | mobile | Mobile B | 51, 53 | 52 | 3 h |
| 55 | `web/19-cinematic-ai-picks-similar-recap.md` | web | Web B | 56, 58 | 53, 28 | 3 h |
| 56 | `mobile/19-cinematic-ai-picks-similar-recap.md` | mobile | Mobile B | 53, 55 | 54, 28 | 3 h |
| 57 | `web/20-cinematic-onboarding.md` | web | Web B | 58, 60 | 55, 28 | 3 h |
| 58 | `mobile/20-cinematic-onboarding.md` | mobile | Mobile B | 55, 57 | 56, 28 | 3 h |
| 59 | `web/21-cinematic-numbers-streak-annual.md` | web | Web B | 60, 62 | 57, 22 | 3 h |
| 60 | `mobile/21-cinematic-numbers-streak-annual.md` | mobile | Mobile B | 57, 59 | 58, 22 | 2.5 h |
| 61 | `web/22-cinematic-circle.md` | web | Web B | 62, 64 | 59, 37, 40 | 3 h |
| 62 | `mobile/22-cinematic-circle.md` | mobile | Mobile B | 59, 61 | 60, 37, 40 | 2.5 h |
| 63 | `web/23-cinematic-ambient-reader-extras.md` | web | Web B | 64, 66 | 61, 31, 34 | 2.5 h |
| 64 | `mobile/23-cinematic-ambient-reader-extras.md` | mobile | Mobile B | 61, 63 | 62, 31, 34 | 2 h |
| 65 | `web/24-cinematic-qa-polish.md` | web | Web B | 66 | 63 | 5 h |
| 66 | `mobile/24-cinematic-qa-polish.md` | mobile | Mobile B | 63, 65 | 64 | 5 h |
| 67 | `release/00-cinematic-flip-release.md` | release | Release | none | 65, 66, 34, 40 | 6 h |
| 68 | `web/25-glass-foundation-material-physics.md` | web | Web B | 69 | 67, 16 | 3 h |
| 69 | `mobile/25-glass-foundation-material-physics.md` | mobile | Mobile B | 68 | 67, 13, 16 | 3 h |
| 70 | `web/26-glass-primitives-controls-and-reveals.md` | web | Web B | 71 | 68 | 4 h |
| 71 | `mobile/26-glass-primitives-controls-and-reveals.md` | mobile | Mobile B | 70 | 69 | 4 h |
| 72 | `web/27-glass-primitives-overlays.md` | web | Web B | 73 | 70 | 3 h |
| 73 | `mobile/27-glass-primitives-overlays.md` | mobile | Mobile B | 72 | 71 | 3 h |
| 74 | `web/28-glass-primitives-lists-states-ai-charts.md` | web | Web B | 75 | 72 | 3 h |
| 75 | `mobile/28-glass-primitives-lists-states-ai-charts.md` | mobile | Mobile B | 74 | 73 | 3 h |
| 76 | `web/29-glass-shell-navigation-depth.md` | web | Web B | 77 | 74, 16 | 3 h |
| 77 | `mobile/29-glass-shell-navigation-depth.md` | mobile | Mobile B | 76 | 75, 16 | 3 h |
| 78 | `web/30-glass-auth-profiles-onboarding.md` | web | Web B | 79 | 76, 28 | 2 h |
| 79 | `mobile/30-glass-auth-profiles-onboarding.md` | mobile | Mobile C | 78, 80 | 77, 28 | 3 h |
| 80 | `web/31-glass-home.md` | web | Web C | 79, 81 | 78 | 2.5 h |
| 81 | `mobile/31-glass-home.md` | mobile | Mobile C | 80, 82 | 79 | 2.5 h |
| 82 | `web/32-glass-library-hub-downloads.md` | web | Web C | 81, 83 | 80 | 2.5 h |
| 83 | `mobile/32-glass-library-hub-downloads.md` | mobile | Mobile C | 82, 84 | 81 | 3 h |
| 84 | `web/33-glass-series-and-book.md` | web | Web C | 83, 85 | 82 | 2.5 h |
| 85 | `mobile/33-glass-series-and-book.md` | mobile | Mobile C | 84, 86 | 83 | 2.5 h |
| 86 | `web/34-reader-engine-glass-commands.md` | web | Web C | 85, 87 | 84 | 2 h |
| 87 | `mobile/34-reader-engine-glass-commands.md` | mobile | Mobile C | 86, 88 | 85 | 2 h |
| 88 | `web/35-glass-manga-reader.md` | web | Web C | 87, 89 | 86 | 3 h |
| 89 | `mobile/35-glass-manga-reader.md` | mobile | Mobile C | 88, 90 | 87 | 3 h |
| 90 | `web/36-glass-novel-reader.md` | web | Web C | 89, 91 | 88 | 3 h |
| 91 | `mobile/36-glass-novel-reader.md` | mobile | Mobile C | 90, 92 | 89 | 3 h |
| 92 | `web/37-glass-listen-mode.md` | web | Web C | 91, 93 | 90 | 2.5 h |
| 93 | `mobile/37-glass-listen-mode.md` | mobile | Mobile C | 92, 94 | 91 | 3 h |
| 94 | `web/38-glass-search-sources-dialogue.md` | web | Web C | 93 | 92 | 2 h |
| 95 | `mobile/38-glass-search-sources-dialogue.md` | mobile | Mobile C | 96 | 93 | 2.5 h |
| 96 | `web/39-glass-settings-and-skin-switch.md` | web | Web C | 95, 97 | 94 | 3 h |
| 97 | `mobile/39-glass-settings-and-skin-switch.md` | mobile | Mobile C | 96, 98 | 95 | 3.5 h |
| 98 | `web/40-glass-you-about-admin-status.md` | web | Web C | 97 | 96 | 3 h |
| 99 | `mobile/40-glass-you-about-admin-status.md` | mobile | Mobile C | 100, 102 | 97 | 3 h |
| 100 | `web/41-glass-ai-for-you-recaps.md` | web | Web C | 99 | 98 | 2.5 h |
| 101 | `mobile/41-glass-ai-for-you-recaps.md` | mobile | Mobile C | 102, 104 | 99 | 2.5 h |
| 102 | `web/42-glass-stats-streak-wrapped.md` | web | Web C | 99, 101 | 100 | 2.5 h |
| 103 | `mobile/42-glass-stats-streak-wrapped.md` | mobile | Mobile C | 104, 106 | 101 | 2.5 h |
| 104 | `web/43-glass-circle.md` | web | Web C | 101, 103 | 102 | 2.5 h |
| 105 | `mobile/43-glass-circle.md` | mobile | Mobile C | 106 | 103 | 2.5 h |
| 106 | `web/44-glass-ambient-reader-extras.md` | web | Web C | 103, 105 | 104 | 3 h |
| 107 | `mobile/44-glass-ambient-reader-extras.md` | mobile | Mobile C | 108 | 105 | 6 h |
| 108 | `web/45-glass-qa-polish.md` | web | Web C | 107 | 106 | 5 h |
| 109 | `mobile/45-glass-qa-polish.md` | mobile | Mobile C | none | 107 | 5.5 h |
| 110 | `release/01-glass-final-release.md` | release | Release | none | 108, 109, 67 | 6 h |

## Checkpoints: look before you continue

Screenshots and records land in `docs/redesign/proof/<track>-<NN>/` (for example `docs/redesign/proof/web-04/`). On the phone, open them on GitHub at `github.com/yash-dhanda/ManhwaManiacs/tree/feat/vps-slim-source-native/docs/redesign/proof`, or ask the session that made them to send you the screenshots. If something looks wrong, say so in that same session before you start the next step that builds on it.

1. **After steps 3 and 6 (tokens, contrast, icons).** Open `proof/shared-00/`, `proof/shared-01/` and `proof/shared-02/`: colour swatches, the contrast table and the icon sheets for both skins. Steps 7 and 13 build on them.
2. **After step 9 (sounds).** `proof/shared-03/`. Your job, any time before step 106: fifteen CC0 1.0 field recordings from freesound.org for the Glass soundscapes, named `{scene}-{layer}.<ext>` and dropped into `design/sounds/incoming/glass/`, as listed in `backend/media/soundscapes/glass/SOURCES.md`. Then ask a session to run `node design/sounds/trim-loop.mjs` and commit the output. Without them the Glass ambient step ships with the layers it has.
3. **After step 13 (Glass device gate, required).** Update the iPhone through SideStore to the build for that commit, put the release APK on the Android flagship, and run the checklist in `proof/mobile-03/glass-gate.md`. Paste the FPS / JANK / WORST readings per device back into the step 13 session (or a fresh session in `mobile`). Its `Decision:` line decides how Glass is built on the phones, so finish this before step 69.
4. **After steps 15 and 16 (brand).** `proof/shared-04/` and `proof/shared-05/`: the new wordmark, app icon, splash frame and the Glass icon. Your job before step 78: the eleven onboarding style masters and `LICENSE.md` rows described in `brand/onboarding/styles/BRIEF.md`, then `node brand/onboarding/styles/intake.mjs` and a commit.
5. **After steps 17 and 18 (the two signature reveals).** `proof/web-04/` and `proof/mobile-04/`. This is the most important look check of the series: the heading letter set (fade, slide up, un-blur, staggered) and the typing headline at one character every 50 ms.
6. **After steps 23, 24, 26 and 27 (shell, Press start splash, login, profiles, 18+ gate).** `proof/web-06/`, `proof/mobile-06/`, `proof/web-07/`, `proof/mobile-07/`.
7. **After step 31 (reader sign-offs).** Read `docs/redesign/signoffs.md`. Step 31 records S1, S11, G6 and G14 for you (page tint and panel detection run on the client, as the design contracts decided). If you disagree, say so before steps 41 and 42; reversing it is a new plan step.
8. **After steps 29 to 39 (Tonight home, library, book pages).** `proof/web-08/` to `proof/web-11/` and `proof/mobile-08/` to `proof/mobile-11/`.
9. **After steps 41 to 48 (manga reader, novel reader, Listen with the 31 voices).** `proof/web-12/` to `proof/web-15/` and `proof/mobile-12/` to `proof/mobile-15/`.
10. **After steps 65 and 66 (Cinematic QA, required).** `proof/web-24/` and `proof/mobile-24/` (`qa.md`, `screens/`, `states/`, `a11y/`). Then fill every row of `proof/mobile-24/device-pass.md` on the iPhone and the Android flagship. Step 67 refuses to ship while a row is empty or failed.
11. **After step 67.** Fill `proof/release-00/owner-check.md` (see the release section).
12. **After steps 68 and 69 (Glass foundation).** `proof/web-25/` and `proof/mobile-25/`, and run `proof/mobile-25/device-check.md` on both phones.
13. **After steps 70 to 77 (Glass primitives, shell, Droplet splash).** `proof/web-26/` to `proof/web-29/` and `proof/mobile-26/` to `proof/mobile-29/`.
14. **After steps 108 and 109 (Glass QA).** `proof/web-45/pairs/` shows every screen with Cinematic on the left and Glass on the right; also `proof/mobile-45/`. Do the hardware checks listed in both `qa.md` files.
15. **After step 110.** The device pass in `proof/release-01/device-pass.md` (see the release section).

## If a step fails

- **Paste the error, or the session's stop report, back into the same session** and tell it to fix the cause and carry on. Do not start a new session for the same step while the old one still has context.
- **Never skip a step** and never run a later one to catch up. Later steps check their preconditions and stop anyway, and a half-built step breaks everything after it.
- A precondition stop that names a missing step ("shared/02 has not run"): run that step in its window first, then tell the stopped session "shared/02 is done now, continue".
- A RAM-guard stop: wait until the other window's build ends (`free -m`, available at least 1024 MB), then type "continue".
- A red CI run after a push: paste the failing job name and its log lines into the same session.
- The session died or ran out of context: start a fresh session in the same window and paste `Continue docs/redesign/prompts/<file>.md: check git log and docs/redesign/proof/<track>-<NN>/plan.md for what is already done, then finish the rest of the file and its Report back.`
- Never run `git reset`, `git stash` or `git checkout` yourself in `~/code`: the other windows are working in the same checkout.
- Production is not touched before the release steps. If a session wants to restart containers or deploy earlier, stop it.

## Paste lines

Copy each line exactly into a fresh Claude Code session in the named window, in step order.

### Window `shared` (shared track, then both releases)

Steps 1 to 16 need nothing but each other. Step 67 waits for steps 65, 66, 34 and 40. Step 110 waits for steps 108 and 109.

**Step 1.** Foundation: design/ contract, Cinematic tokens and the generator

```
Execute docs/redesign/prompts/shared/00-design-contract-and-token-generator.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 3.** Foundation: Glass tokens, haptic patterns, motion names and the contrast gate

```
Execute docs/redesign/prompts/shared/01-glass-tokens-haptics-motion-names-contrast.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 6.** Foundation: icon sets and custom glyphs for both skins

```
Execute docs/redesign/prompts/shared/02-icon-sets-and-custom-glyphs.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 9.** Foundation: UI sound sets and soundscape audio assets

```
Execute docs/redesign/prompts/shared/03-ui-sounds-and-soundscape-audio.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 15.** Brand: Cinematic masters, shared platform icons, splash frame and demo art

```
Execute docs/redesign/prompts/shared/04-brand-cinematic-and-platform-icons.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 16.** Brand: Glass masters, the alternate icon and the art intake

```
Execute docs/redesign/prompts/shared/05-brand-glass-and-art-intake.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 67.** Release: Cinematic becomes the default on web, Android and iOS (minor bump)

```
Execute docs/redesign/prompts/release/00-cinematic-flip-release.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 110.** Final release: Glass joins Cinematic, cross-skin QA, minor bump, three platforms

```
Execute docs/redesign/prompts/release/01-glass-final-release.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

### Window `backend`

Runs straight through; nothing outside the backend blocks it except step 34 (waits for steps 9 and 15).

**Step 2.** Backend: per-profile skin and profile columns, plus the dev stack

```
Execute docs/redesign/prompts/backend/00-profile-columns-and-dev-stack.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 14.** Backend: cover ambient colours and palettes

```
Execute docs/redesign/prompts/backend/01-cover-ambient-and-palette.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 19.** Backend: library, collections, tags, series enrichment and OCR boxes

```
Execute docs/redesign/prompts/backend/02-library-series-ocr-extensions.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 22.** Backend: statistics, streaks, the Annual and listen sessions (new feature 2)

```
Execute docs/redesign/prompts/backend/03-stats-streaks-annual-listen-sessions.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 25.** Backend: GET /home composition for the AI home (new feature 1, part 1)

```
Execute docs/redesign/prompts/backend/04-ai-home-composition.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 28.** Backend: similar, recaps, feedback, taste and onboarding catalogue (new feature 1, part 2)

```
Execute docs/redesign/prompts/backend/05-ai-similar-recap-taste-onboarding.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 31.** Backend: page tints, panel reports and novel audio fields

```
Execute docs/redesign/prompts/backend/06-reader-tints-panels-novel-audio.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 34.** Backend: soundscape and font routes, and the new install page

```
Execute docs/redesign/prompts/backend/07-media-routes-and-install-page.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 37.** Backend: Circle core, sharing, feed and presence (new feature 3, part 1)

```
Execute docs/redesign/prompts/backend/08-circle-core-sharing-presence.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 40.** Backend: reactions, letters and shared shelves (new feature 3, part 2)

```
Execute docs/redesign/prompts/backend/09-circle-reactions-letters-shelves.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

### Window `web` (Web A, then Web B, then Web C)

Step 68 (the first Glass step) waits for the Cinematic release, step 67.

**Step 4.** Web foundation: skin engine, route groups and the completeness contract

```
Execute docs/redesign/prompts/web/00-foundation-skin-engine-and-routes.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 7.** Web foundation: Motion 13, dependencies, fonts and icons for both skins

```
Execute docs/redesign/prompts/web/01-foundation-motion-deps-fonts-icons.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 10.** Web foundation: restart-to-switch, first-paint accessibility, haptics and sound

```
Execute docs/redesign/prompts/web/02-foundation-restart-haptics-sound.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 12.** Web foundation: reader engine seam, request limiter and the proof harness

```
Execute docs/redesign/prompts/web/03-foundation-reader-seam-limiter-proof.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 17.** Web Cinematic primitives 1: core components and the two signature reveals

```
Execute docs/redesign/prompts/web/04-cinematic-primitives-core-and-reveals.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 20.** Web Cinematic primitives 2: overlays, controls, lists and states

```
Execute docs/redesign/prompts/web/05-cinematic-primitives-overlays-controls-states.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 23.** Web Cinematic shell, navigation, transitions, overlays and the Press start splash

```
Execute docs/redesign/prompts/web/06-cinematic-shell-navigation-transitions.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 26.** Web Cinematic login, register, profiles and the 18+ gate

```
Execute docs/redesign/prompts/web/07-cinematic-auth-profiles-18plus.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 29.** Web Cinematic Tonight (home)

```
Execute docs/redesign/prompts/web/08-cinematic-tonight.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 32.** Web Cinematic Library shelf and browse

```
Execute docs/redesign/prompts/web/09-cinematic-library-shelf-browse.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 35.** Web Cinematic Updates, Collections, History and Bookmarks

```
Execute docs/redesign/prompts/web/10-cinematic-updates-collections-history-bookmarks.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 38.** Web Cinematic Feature page, Book page and chapter downloads

```
Execute docs/redesign/prompts/web/11-cinematic-feature-and-book-pages.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 41.** Web Cinematic manga reader 1: strip, chrome, ruler, credits

```
Execute docs/redesign/prompts/web/12-cinematic-manga-reader-strip.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 43.** Web Cinematic manga reader 2: paged, read-all, setup sheet, side panels

```
Execute docs/redesign/prompts/web/13-cinematic-manga-reader-paged-readall-panels.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 45.** Web Cinematic novel reader 'The page'

```
Execute docs/redesign/prompts/web/14-cinematic-novel-reader.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 47.** Web Cinematic Listen mode with the 31 voices

```
Execute docs/redesign/prompts/web/15-cinematic-listen-mode.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 49.** Web Cinematic Discover: search, sources, catalogues and dialogue search

```
Execute docs/redesign/prompts/web/16-cinematic-discover-search-sources-dialogue.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 51.** Web Cinematic Downloads, Index, What's new and System status

```
Execute docs/redesign/prompts/web/17-cinematic-downloads-index-status.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 53.** Web Cinematic Settings, the edition picker and Stop the press

```
Execute docs/redesign/prompts/web/18-cinematic-settings-and-edition-restart.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 55.** Web Cinematic AI: Picks, More like this and Previously on (new feature 1)

```
Execute docs/redesign/prompts/web/19-cinematic-ai-picks-similar-recap.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 57.** Web Cinematic onboarding 'the first issue'

```
Execute docs/redesign/prompts/web/20-cinematic-onboarding.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 59.** Web Cinematic The Numbers, the streak flame and The Annual (new feature 2)

```
Execute docs/redesign/prompts/web/21-cinematic-numbers-streak-annual.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 61.** Web Cinematic Circle (new feature 3)

```
Execute docs/redesign/prompts/web/22-cinematic-circle.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 63.** Web Cinematic ambient reader extras (new feature 4)

```
Execute docs/redesign/prompts/web/23-cinematic-ambient-reader-extras.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 65.** Web Cinematic QA and polish before the flip

```
Execute docs/redesign/prompts/web/24-cinematic-qa-polish.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 68.** Web Glass foundation: materials, ambient field, physics and motion

```
Execute docs/redesign/prompts/web/25-glass-foundation-material-physics.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 70.** Web Glass primitives 1: controls, posters, rails and the two reveals

```
Execute docs/redesign/prompts/web/26-glass-primitives-controls-and-reveals.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 72.** Web Glass primitives 2: sheets, alerts, menus, toasts and controls

```
Execute docs/redesign/prompts/web/27-glass-primitives-overlays.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 74.** Web Glass primitives 3: lists, states, 18+ gate, AI surfaces and charts

```
Execute docs/redesign/prompts/web/28-glass-primitives-lists-states-ai-charts.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 76.** Web Glass shell: sidebar, dock, sheet host, depth and the Droplet splash

```
Execute docs/redesign/prompts/web/29-glass-shell-navigation-depth.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 78.** Web Glass login, register, profiles, onboarding and the 18+ gate

```
Execute docs/redesign/prompts/web/30-glass-auth-profiles-onboarding.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 80.** Web Glass Home with AI rails

```
Execute docs/redesign/prompts/web/31-glass-home.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 82.** Web Glass Library hub: shelf, collections, history, bookmarks, updates, downloads

```
Execute docs/redesign/prompts/web/32-glass-library-hub-downloads.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 84.** Web Glass series detail and book page

```
Execute docs/redesign/prompts/web/33-glass-series-and-book.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 86.** Web reader engine: the commands Glass needs

```
Execute docs/redesign/prompts/web/34-reader-engine-glass-commands.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 88.** Web Glass manga reader

```
Execute docs/redesign/prompts/web/35-glass-manga-reader.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 90.** Web Glass novel reader

```
Execute docs/redesign/prompts/web/36-glass-novel-reader.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 92.** Web Glass Listen mode with the 31 voices

```
Execute docs/redesign/prompts/web/37-glass-listen-mode.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 94.** Web Glass search, sources, catalogues and dialogue search

```
Execute docs/redesign/prompts/web/38-glass-search-sources-dialogue.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 96.** Web Glass Settings and the skin switch

```
Execute docs/redesign/prompts/web/39-glass-settings-and-skin-switch.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 98.** Web Glass You, About, admin settings and System status

```
Execute docs/redesign/prompts/web/40-glass-you-about-admin-status.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 100.** Web Glass AI: For you, Ask, recaps and More like this (new feature 1)

```
Execute docs/redesign/prompts/web/41-glass-ai-for-you-recaps.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 102.** Web Glass statistics, streak flame and Wrapped (new feature 2)

```
Execute docs/redesign/prompts/web/42-glass-stats-streak-wrapped.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 104.** Web Glass Circle (new feature 3)

```
Execute docs/redesign/prompts/web/43-glass-circle.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 106.** Web Glass ambient reader extras (new feature 4)

```
Execute docs/redesign/prompts/web/44-glass-ambient-reader-extras.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 108.** Web Glass QA and polish

```
Execute docs/redesign/prompts/web/45-glass-qa-polish.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

### Window `mobile` (Mobile A, then Mobile B, then Mobile C)

Step 69 (the first Glass step) waits for the Cinematic release, step 67.

**Step 5.** Mobile foundation: pixel-free reader engine extraction

```
Execute docs/redesign/prompts/mobile/00-foundation-reader-engine-extraction.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 8.** Mobile foundation: Skin interface, AppRestart and the restart-to-switch mechanics

```
Execute docs/redesign/prompts/mobile/01-foundation-skin-engine-and-restart.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 11.** Mobile foundation: isolated native-plugin commit, haptics channel and sound layer

```
Execute docs/redesign/prompts/mobile/02-foundation-native-plugins-haptics-sound.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 13.** Mobile foundation: fonts, icons, screenshot harness, request limiter and the Glass device gate

```
Execute docs/redesign/prompts/mobile/03-foundation-fonts-icons-harness-glass-gate.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 18.** Mobile Cinematic primitives 1: core components and the two signature reveals

```
Execute docs/redesign/prompts/mobile/04-cinematic-primitives-core-and-reveals.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 21.** Mobile Cinematic primitives 2: overlays, controls, lists and states

```
Execute docs/redesign/prompts/mobile/05-cinematic-primitives-overlays-controls-states.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 24.** Mobile Cinematic shell, router, transitions, overlays and the Press start splash

```
Execute docs/redesign/prompts/mobile/06-cinematic-shell-navigation-transitions.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 27.** Mobile Cinematic setup, login, register, profiles and the 18+ gate

```
Execute docs/redesign/prompts/mobile/07-cinematic-auth-profiles-18plus.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 30.** Mobile Cinematic Tonight (home)

```
Execute docs/redesign/prompts/mobile/08-cinematic-tonight.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 33.** Mobile Cinematic Library shelf and browse

```
Execute docs/redesign/prompts/mobile/09-cinematic-library-shelf-browse.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 36.** Mobile Cinematic Updates, Collections, History and Bookmarks

```
Execute docs/redesign/prompts/mobile/10-cinematic-updates-collections-history-bookmarks.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 39.** Mobile Cinematic Feature page, Book page and chapter downloads

```
Execute docs/redesign/prompts/mobile/11-cinematic-feature-and-book-pages.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 42.** Mobile Cinematic manga reader 1: strip, chrome, ruler, credits

```
Execute docs/redesign/prompts/mobile/12-cinematic-manga-reader-strip.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 44.** Mobile Cinematic manga reader 2: paged, read-all, setup sheet, panels

```
Execute docs/redesign/prompts/mobile/13-cinematic-manga-reader-paged-readall-panels.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 46.** Mobile Cinematic novel reader 'The page'

```
Execute docs/redesign/prompts/mobile/14-cinematic-novel-reader.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 48.** Mobile Cinematic Listen mode with the 31 voices and the lock screen

```
Execute docs/redesign/prompts/mobile/15-cinematic-listen-mode.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 50.** Mobile Cinematic Discover: search, sources, catalogues and dialogue search

```
Execute docs/redesign/prompts/mobile/16-cinematic-discover-search-sources-dialogue.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 52.** Mobile Cinematic Downloads, Index, app updates and System status

```
Execute docs/redesign/prompts/mobile/17-cinematic-downloads-index-status.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 54.** Mobile Cinematic Settings, the edition picker and Stop the press

```
Execute docs/redesign/prompts/mobile/18-cinematic-settings-and-edition-restart.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 56.** Mobile Cinematic AI: Picks, More like this and Previously on (new feature 1)

```
Execute docs/redesign/prompts/mobile/19-cinematic-ai-picks-similar-recap.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 58.** Mobile Cinematic onboarding 'the first issue'

```
Execute docs/redesign/prompts/mobile/20-cinematic-onboarding.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 60.** Mobile Cinematic The Numbers, the streak flame and The Annual (new feature 2)

```
Execute docs/redesign/prompts/mobile/21-cinematic-numbers-streak-annual.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 62.** Mobile Cinematic Circle (new feature 3)

```
Execute docs/redesign/prompts/mobile/22-cinematic-circle.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 64.** Mobile Cinematic ambient reader extras (new feature 4)

```
Execute docs/redesign/prompts/mobile/23-cinematic-ambient-reader-extras.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 66.** Mobile Cinematic QA and polish before the flip

```
Execute docs/redesign/prompts/mobile/24-cinematic-qa-polish.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 69.** Mobile Glass foundation: SkinGlass, physics, motion and the dependency gate

```
Execute docs/redesign/prompts/mobile/25-glass-foundation-material-physics.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 71.** Mobile Glass primitives 1: controls, posters, rails and the two reveals

```
Execute docs/redesign/prompts/mobile/26-glass-primitives-controls-and-reveals.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 73.** Mobile Glass primitives 2: sheets, alerts, menus, toasts and controls

```
Execute docs/redesign/prompts/mobile/27-glass-primitives-overlays.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 75.** Mobile Glass primitives 3: lists, states, 18+ gate, AI surfaces and charts

```
Execute docs/redesign/prompts/mobile/28-glass-primitives-lists-states-ai-charts.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 77.** Mobile Glass shell: dock, router, depth stack and the Droplet splash

```
Execute docs/redesign/prompts/mobile/29-glass-shell-navigation-depth.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 79.** Mobile Glass setup, login, register, profiles, onboarding and the 18+ gate

```
Execute docs/redesign/prompts/mobile/30-glass-auth-profiles-onboarding.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 81.** Mobile Glass Home with AI rails

```
Execute docs/redesign/prompts/mobile/31-glass-home.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 83.** Mobile Glass Library hub: shelf, collections, history, bookmarks, updates, downloads

```
Execute docs/redesign/prompts/mobile/32-glass-library-hub-downloads.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 85.** Mobile Glass series detail and book page

```
Execute docs/redesign/prompts/mobile/33-glass-series-and-book.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 87.** Mobile reader engine: the commands Glass needs

```
Execute docs/redesign/prompts/mobile/34-reader-engine-glass-commands.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 89.** Mobile Glass manga reader

```
Execute docs/redesign/prompts/mobile/35-glass-manga-reader.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 91.** Mobile Glass novel reader

```
Execute docs/redesign/prompts/mobile/36-glass-novel-reader.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 93.** Mobile Glass Listen mode with the 31 voices

```
Execute docs/redesign/prompts/mobile/37-glass-listen-mode.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 95.** Mobile Glass search, sources, catalogues and dialogue search

```
Execute docs/redesign/prompts/mobile/38-glass-search-sources-dialogue.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 97.** Mobile Glass Settings and the skin switch

```
Execute docs/redesign/prompts/mobile/39-glass-settings-and-skin-switch.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 99.** Mobile Glass You, About, admin settings, server and System status

```
Execute docs/redesign/prompts/mobile/40-glass-you-about-admin-status.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 101.** Mobile Glass AI: For you, Ask, recaps and More like this (new feature 1)

```
Execute docs/redesign/prompts/mobile/41-glass-ai-for-you-recaps.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 103.** Mobile Glass statistics, streak flame and Wrapped (new feature 2)

```
Execute docs/redesign/prompts/mobile/42-glass-stats-streak-wrapped.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 105.** Mobile Glass Circle (new feature 3)

```
Execute docs/redesign/prompts/mobile/43-glass-circle.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 107.** Mobile Glass ambient reader extras (new feature 4)

```
Execute docs/redesign/prompts/mobile/44-glass-ambient-reader-extras.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

**Step 109.** Mobile Glass QA and polish

```
Execute docs/redesign/prompts/mobile/45-glass-qa-polish.md completely: read it first, follow every section in order, commit and push exactly as it says, and finish with its Report back.
```

## The release steps

There are two releases, both run in window `shared`, and each ships web, Android and iOS together with a minor version bump.

**Step 67, Cinematic becomes the default.** Before you paste its line: steps 65, 66, 34 and 40 are done and `proof/mobile-24/device-pass.md` is complete with no failed row. During the step:

1. The session pushes `master` after each working step and the branch once, then waits for CI and the iOS Publish step.
2. It sends you a command block for the **laptop** (where the signing key lives). Run it there; it ends with `bash ops/vps/push.sh apk` and `sha256sum mobile/build/app/outputs/flutter-apk/app-release.apk`. Paste the output of those last two commands back. The APK is never built on the VPS.
3. It deploys web and backend from this box and checks them.
4. Update the iPhone through SideStore, and Android through the update card or `https://app.manhwamaniacs.xyz`. Then fill `proof/release-00/owner-check.md`: the app opens in Cinematic on Tonight with Press start, downloads still open offline, and About shows the new version.

**Step 110, Glass joins Cinematic.** Before you paste its line: steps 108 and 109 are done. It flips `glass_available` on, removes the debug path, bumps the minor version, and ships the same way as step 67 (laptop APK block, SideStore update). After the ship, run the cross-skin device pass in `proof/release-01/device-pass.md` on both phones and paste the results back into the same session. A failed row is fixed forward there as a patch release `X.Y.1`.

After step 110 the series is finished. Next come new plans, starting with the Flutter 3.47 and Riverpod 3 upgrade that was deferred until Glass shipped.
