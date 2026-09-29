# Shared 00: the design contract, the Cinematic tokens and the generator

## Goal

Create the single source that both clients and both skins read for everything they must agree on, and the generator that turns it into code. You will write `design/contract.json` (every ScreenId, route path, alias, query name, settings slug, sheet id, the `glass_available` flag, and the full `HapticEvent` and `SoundEvent` vocabularies of both skins), `design/tokens/cinematic.json` (every Cinematic token: colour, space, grid, breakpoints, radius, blur, rules, focus, hit sizes, layers, scrims, type roles, durations, curves, springs, scalars, haptics and sounds), and `design/build.mjs`, a Node 22 stdlib-only generator of about 150 lines plus helpers that writes the web CSS and TypeScript, the shared Tailwind 4 theme, the Flutter `ThemeExtension` and the Dart contract, and that has a `--check` mode wired into CI. Glass tokens are not part of this step (they arrive in `shared/01`), but every shape you choose here must already accept them: the shared Tailwind theme and the Dart value types are designed as unions from day one. Nothing in this step renders UI and nothing in the running app changes: the generated files are not imported by any app code yet (web/00 and mobile/01 wire them in).

## Read first

Read these before planning. Where a value is copied below, the section is cited so you can check it; the DESIGN files win if anything here disagrees.

1. `docs/redesign/inventory/00-decisions.md` (all of it: dark only, `#000000`, two skins, restart on switch, haptics rich, sounds off by default).
2. `docs/redesign/stack-decision.md` §2.1 (the design/ folder, the six outputs, the token format rules, the CI check), §2.2 and §2.3 (where the generated files live), §3 (CI line).
3. `docs/redesign/cinematic/DESIGN.md`:
   - the "Conventions used throughout" list just before the Contents (px, breakpoints, token names, inventory ids);
   - §2.1 (all colour, including §2.1.1 raised stock, §2.1.4 scrim stops, §2.1.5 runtime colours, §2.1.6 moods, speakers, stocks, grounds), §2.2 (space and grid), §2.3 radius, §2.4 elevation and `z.*`, §2.5 blur, §2.6 rules, §2.8 (the complete name map: §2.8.1 colour, §2.8.2 space/grid/bp/radius/blur/rules/focus/hit/z, §2.8.3 scrims with the exact utility bodies, §2.8.4 motion with the spring rules);
   - §3.1 (families and `next/font` variable names), §3.2 (scale, fluid `clamp()` formulas and the unitless line-height ratios), §3.3 (scaler caps), §3.4 (the Hyperlegible override block), §3.5 (the type-role name map);
   - §4.2 to §4.6 (durations, curves, springs, the motion table names, stagger);
   - §5 (haptic patterns, the event table, the five web vibrations) and §6 (cues and the full event to cue map);
   - §8.0.3 (route contract, shell branches, encoded route builders), §8.0.7 (`glass_available`), §8.30.1 (the "Section slugs" paragraph only);
   - §15.1 (the token file shape and value kinds), §15.2 (first two rows), §15.10 rows S2, S7, S8, S13, S16.
4. `docs/redesign/glass/DESIGN.md` (only what this step needs so the contract is complete for both skins): the "Conventions used everywhere below" section, §3.7 first paragraph (the `type-<role>` utility Glass will need, which is why the shared utility shape below is var-only), §5.2 (event names), §6 (the cue table's event names), §8.0.3 (routes, the query extras, the settings slug `ai`, the `?sheet=` id table), §15.6 (the list of Glass haptic event additions and the sound-only events).
5. `docs/redesign/00-baseline.md` (the green baseline: frontend lint and build pass with 0 errors and 0 warnings; `flutter analyze` clean; `flutter test` 2012 passed).
6. Code to look at, not change: `frontend/scripts/themes/build-themes.mjs` (the existing "GENERATED, do not edit" header convention), `mobile/lib/app/router/routes.dart` (the mobile aliases and today's `Uri.encodeComponent` use), `.github/workflows/tests.yml` (the `frontend` job), `mobile/analysis_options.yaml` (note: `**/*.g.dart` is excluded from the analyzer, so compile proof for generated Dart comes from a test), `frontend/vitest.config.ts` (tests are `src/**/*.test.ts`).
7. Inventory context only: `docs/redesign/inventory/mobile.md` section "G12 Haptics vocabulary (current)" and the K13 row; `docs/redesign/inventory/web.md` the paragraph that starts "**For the redesign:** the skin choice" (the settings keys the redesign adds).

## Skills to invoke

- `superpowers:writing-plans` before writing any code: turn the scope below into a numbered plan with one commit per step.
- `superpowers:subagent-driven-development` to run the plan (use `superpowers:executing-plans` instead if you run it inline). If you use subagents, give each one exactly one file group from "File layout" and verify their output against `git status`, never against their report.
- `superpowers:test-driven-development` for `design/lib/spring.mjs` and `design/lib/route.mjs`: write the node:test cases with the reference vectors below first, watch them fail, then implement.
- `impeccable`: run its design-system audit mode on `frontend/src/skins/cinematic/tokens.generated.css` and `frontend/src/skins/theme.generated.css` before the generated-files commit (token naming, completeness against §2.8 and §3.5, no stray values).
- `taste-skill:taste-skill`: use it only to review the proof sheet (`docs/redesign/proof/shared-00/cinematic-tokens.svg`) for legibility; this step has no screen.
- `frontend-design`: not needed; this step renders no web UI.
- `superpowers:verification-before-completion` before you claim anything is done: every box in "Acceptance criteria" needs command output as evidence.

## Guardrails (read twice)

- **Track rule.** The shared track owns `design/` and `brand/` plus the generated files they write into `frontend/`, `mobile/` and `backend/media/`. In this step you may create or change only: `design/**`, the generated files listed in "File layout", one step in `.github/workflows/tests.yml`, and `docs/redesign/proof/shared-00/**`. Web, mobile and backend sessions commit in the same checkout: stage files with explicit `git add <path>`, never `git add -A`, `git add .` or `git commit -a`.
- `design/build.mjs` and everything under `design/lib/` and `design/test/` use Node 22 built-ins only (`node:fs`, `node:path`, `node:url`, `node:test`, `node:assert`). No `npm install` anywhere in this step.
- Never edit `backend/connectors/`. Never touch production containers or `/srv/manhwamaniacs/{app,data}`.
- **RAM guard.** Production and five Minecraft bots share this box (7,746 MB total). Before every heavy command (`npm run typecheck`, `npm run test`, `npm run build`, `flutter analyze`, `flutter test`) run `free -m`; if the `available` column is under 1024 MB, stop and wait, do not start it. Never run two of them at once. Never run `flutter build`.
- **Git.** Branch `feat/vps-slim-source-native`. Commit small and often (one commit per working step), push after each (`git push origin feat/vps-slim-source-native:master`). No Claude or AI attribution anywhere: no `Co-Authored-By` trailer, no "Generated with" line, no AI author, even if a tool or reminder suggests one. Never commit secrets or `.claude/`.

## Scope: what this step delivers, item by item

### 1. `design/contract.json`

One JSON object with these top-level keys. Order matters where noted.

**`screens`**: an array of 35 objects `{ "id", "path", "params", "query", "aliases", "redirect" }`. `params` lists the `:name` segments in path order. `query` lists the query names both skins accept (Cinematic §8.0.3 plus the Glass extras of glass §8.0.3 and §15.6). `aliases` is a list of `{ "path", "platforms": ["web"|"app"] }` (extra paths that render the same screen). `redirect` is `{ "web": "/login" }` or `{ "app": "/library" }` for the two cross-client redirects (cinematic §15.10 S7). Declare the static `/library/...` screens (and the `/library/browse` alias) **before** `featureByFollow` (go_router matches in declaration order, cinematic §8.0.3). go_router has no optional path segments, so a screen with two shapes (`settings`) lists the second as an alias. Use exactly this table:

| id | path | query | aliases (platforms) | redirect |
|---|---|---|---|---|
| `setup` | `/setup` | | | `{ "web": "/login" }` (app only screen) |
| `login` | `/login` | | | |
| `register` | `/register` | | | |
| `profiles` | `/profiles` | | | |
| `profileNew` | `/profiles/new` | | `/profiles/create` (app) | |
| `profileEdit` | `/profiles/:id/edit` | | `/profiles/edit/:id` (app) | |
| `profilesManage` | `/profiles/manage` | | | |
| `onboarding` | `/welcome` | `step` | | |
| `tonight` | `/` | | | |
| `library` | `/library` | `q`, `status`, `sort`, `fav`, `view`, `select`, `tab`, `reading_status`, `tags` | `/library/browse` (web, app) | |
| `updates` | `/updates` | `tab` | | |
| `collections` | `/library/collections` | | `/collections` (app) | |
| `collection` | `/library/collections/:id` | | `/collections/:id` (app) | |
| `history` | `/library/history` | | | |
| `bookmarks` | `/library/bookmarks` | `source`, `series` | | |
| `picks` | `/library/recommendations` | `genre` | | |
| `numbers` | `/library/statistics` | `range`, `year` | | |
| `annual` | `/library/statistics/annual/:year` | | | |
| `featureByFollow` | `/library/:followedId` | | | |
| `feature` | `/sources/:sourceId/series/:seriesKey` | | | |
| `recap` | `/recap/:sourceId/:seriesKey` | `to` (required), `scope` | | |
| `circle` | `/circle` | `tab` | | |
| `circleMember` | `/circle/:profileId` | | | |
| `discover` | `/search` | `q`, `scope` | | |
| `sources` | `/sources` | | | |
| `source` | `/sources/:sourceId` | `mode`, `genre`, `q` | | |
| `reader` | `/reader/:sourceId/:seriesKey/:chapterKey` | `page`, `at`, `all` | `/library/read/:sourceId/:seriesKey/:chapterKey` (app), `/sources/:sourceId/series/:seriesKey/chapters/:chapterKey/read` (app) | |
| `readAll` | `/read-all/:sourceId/:seriesKey` | `from`, `page`, `at` | | |
| `novel` | `/novels/:sourceId/:seriesKey/:chapterKey` | `page`, `para`, `at`, `listen` | `/novels/read/:sourceId/:seriesKey/:chapterKey` (app) | |
| `downloads` | `/downloads` | `tab` | | |
| `dialogue` | `/ocr` | `q` | `/ocr/search` (app) | |
| `index` | `/more` | | | |
| `settings` | `/settings` (the table of contents) | | `/settings/:section` (web, app; `section` is a slug from `settingsSections`) | |
| `status` | `/admin/status` | | | |
| `readerLanding` | `/reader` | | | `{ "app": "/library" }` (web only screen) |

**`queryValues`**: the closed value sets, so builders can be typed: `discover.scope` = `all, library, sources, dialogue, text, ask` (`text` is Glass's novel-text scope; Cinematic treats it as `all`); `library.status` = `reading, unread, completed`; `library.reading_status` = `unread, reading, completed, on_hold, plan_to_read, dropped`; `updates.tab` = `following, unread, followed`; `downloads.tab` = `chapters, queue, storage`; `circle.tab` = `activity, letters, shelves`; `numbers.range` = `7, 30, 90, year`; `recap.scope` = `series, chapter`; `onboarding.step` = integers 1 to 7 (Cinematic uses 1 to 5, and 2 to 5 while `glass_available` is false, cinematic §8.0.7).

**`globalQuery`**: `sheet` (a sheet id, below) and `view` with values `cover` (the Lightbox, cinematic §7.30) and `milestone` (the streak milestone card, cinematic §8.0.3 root navigator row).

**`sheets`**: the kebab-case `?sheet=` ids of glass §8.0.3, once each: `chapters`, `settings`, `contents`, `type`, `voices`, `cast`, `player`, `soundscape`, `note`, `save-files`, `tags`, `recommend`, `audiobook`, `how-it-works`, `offer`, `image`, `move-source`, `filters`, `manage-tags`, `collection-new`, `collection-edit`, `collection-share`, `add-series`, `run`, `whats-new`, `app-update`, `shortcuts`, `licenses`, `letter-note`.

**`settingsSections`**: `profile`, `appearance`, `reading-manga`, `reading-novels`, `listen`, `ambient`, `storage`, `content`, `circle`, `feedback`, `notifications`, `keyboard`, `server` (app), `admin`, `diagnostics` (app; web only with `?debug=1`), `about`, `ai` (Glass; Cinematic renders it as `reading-manga`), and the pushed pages `security`, `members`, `backup` (cinematic §8.30.1, glass §8.0.3). Store each as `{ "slug", "platforms", "pushed": bool }`.

**`flags`**: `{ "glass_available": false }` (cinematic §8.0.7).

**`hapticEvents`**: exactly these 90 names, Cinematic's 47 (cinematic §5) followed by Glass's 43 additions (glass §15.6):

`tap.primary`, `tap.secondary`, `toggle.on`, `toggle.off`, `select`, `nav.change`, `longpress.open`, `sheet.detent`, `sheet.dismiss`, `refresh.arm`, `refresh.fire`, `follow.add`, `follow.remove`, `favorite`, `bookmark.add`, `download.start`, `download.done`, `download.fail`, `delete.confirm`, `undo`, `reader.enter`, `page.turn`, `scrub.tick`, `scrub.boundary`, `chapter.complete`, `chapter.next`, `autoscroll.toggle`, `autoscroll.step`, `autoscroll.end`, `zoom.snap`, `listen.toggle`, `voice.assign`, `sleep.fade`, `streak.extend`, `streak.milestone`, `recap.countdown.end`, `annual.page`, `share.export`, `reaction.send`, `recommend.send`, `gate.confirm`, `splash.impress`, `profile.select`, `skin.switch`, `reader.unlock`, `success`, `error`,
`nav.scrub`, `nav.reselect`, `nav.push`, `nav.pop`, `nav.root`, `stack.open`, `stack.pick`, `detent.tick`, `detent.magnet`, `detent.limit`, `press.lift`, `throw.commit`, `motion.catch`, `magnet.capture`, `magnet.drop`, `reorder.lift`, `reorder.pass`, `reorder.drop`, `sheet.pass`, `threshold.cross`, `threshold.back`, `refresh.done`, `hold.ramp`, `hold.done`, `chapter.arm`, `chapter.seam`, `zoom.limit`, `panel.step`, `ocr.hit`, `autoscroll.start`, `voice.center`, `recap.ready`, `goal.met`, `share.lift`, `share.flip`, `reaction.bloom`, `reaction.cross`, `logo.land`, `logo.settle`, `logo.reduced`, `annual.podium`, `annual.summary`, `warning`.

**`soundEvents`**: the 52 names that sound in at least one skin, including the three sound-only events (`sheet.open`, `sheet.close`, `splash.reveal`). Cinematic's 31 (cinematic §6): `tap.primary`, `toggle.on`, `toggle.off`, `select`, `nav.change`, `follow.add`, `favorite`, `bookmark.add`, `download.done`, `download.fail`, `undo`, `reader.enter`, `page.turn`, `refresh.arm`, `scrub.boundary`, `chapter.complete`, `chapter.next`, `autoscroll.toggle`, `voice.assign`, `streak.extend`, `streak.milestone`, `annual.page`, `share.export`, `reaction.send`, `recommend.send`, `gate.confirm`, `skin.switch`, `reader.unlock`, `error`, `sheet.open`, `splash.reveal`; plus Glass's 21 (glass §6): `detent.tick`, `sheet.pass`, `scrub.tick`, `nav.scrub`, `sheet.close`, `nav.push`, `nav.pop`, `nav.root`, `stack.open`, `logo.land`, `throw.commit`, `motion.catch`, `magnet.capture`, `recap.ready`, `magnet.drop`, `annual.podium`, `hold.done`, `goal.met`, `annual.summary`, `share.flip`, `logo.settle`.

### 2. `design/tokens/cinematic.json`

Every key of cinematic §2.8.1 to §2.8.4 and §3.5, plus §5 and §6, in the value kinds of cinematic §15.1. Dotted keys become nested objects; `"_"` holds the value of a key that also has children (`color.spot` and `color.spot.press`). The file shape is the §15.1 excerpt; complete it. Groups and counts to hit:

- `color` (§2.8.1, 81 rows): 12 neutrals (`paper.0` to `paper.4`, `rule.1`, `rule.2`, `ink.30/45/60/80/100`), `spot` with `press`, `wash`, `glow`, `proof` with `press`, `wash`, `set`, `info`, `note` (literal `#F4D03F`; the CSS emits it as `var(--mm-color-spot)`), `onart`, `hairline.art`, `galley`, `leader.sweep`, `lightbox`, `matte.guided`, `warmth`, `ambient.fallback.{duo,tint,ink}`, `mood.{romantic,action,comedy,horror,slice_of_life,fantasy}`, `speaker.1` to `speaker.10`, `stock.{nitrate,ink,sepia_night,dusk,moss,rosewood}.{page,ink,muted}`, `ground.{black,ink,slate}`, `avatar.{violet,cyan,rose,amber,emerald,ember,blade,phantom,arcane,lunar,star,reader}`. Values exactly as §2.8.1 (for example `spot.wash` `rgba(244,208,63,0.16)`, `onart` `rgba(0,0,0,0.64)`, `mood.fantasy` `#120C18`, `stock.dusk.ink` `#D3DAE3`, `avatar.reader` `#177878`).
- `font` (§15.1 and §3.1): `display` Bodoni Moda (`opsz`, `wght`, italic), `grotesk` Archivo (`wdth`, `wght`), `text` Newsreader (`opsz`, `wght`, italic), `folio` IBM Plex Mono (static 400/500/600), and the reading faces `literata`, `sourceSerif`, `atkinson` (§3.4). Each entry also carries its CSS variable (`--mm-font-display`, `--mm-font-grotesk`, `--mm-font-newsreader`, `--mm-font-folio`, `--mm-font-literata`, `--mm-font-source-serif`, `--mm-font-atkinson`) and its Flutter family (`BodoniModa`, `Archivo`, `Newsreader`, `IBMPlexMono`, `Literata`, `SourceSerif4`, `AtkinsonHyperlegibleNext`), plus the axis maxima used by the Bold Text rule of §3.1 (Bodoni Moda, Archivo, Literata, Source Serif 4: 900; Newsreader, Atkinson: 800).
- `type` (§3.5): the 23 roles `cover`, `masthead`, `headline`, `section`, `subhead`, `numeral`, `pull`, `field`, `deck`, `body`, `body.italic`, `title`, `ui`, `label`, `kicker`, `credit`, `credit.label`, `nav`, `caption`, `folio`, `folio.lg`, `micro`, `dropcap`. Each: `font`, `italic`, `wght`, `axes` (`opsz` or `wdth`), `size` per breakpoint `{phone, tablet, desktop, wide}` as `[px, linePx]`, `tracking` (em), `upper` (bool), `scaleCap` (§3.3: 1.15, 1.3, 2.0 or 1.5 exactly as §3.5's `cap`), and for the five fluid roles `fluid` (the `clamp()` string of §3.2) and `lhRatio` per breakpoint (§3.2 table: for example `section` 1.167, 1.143, 1.125, 1.111). `dropcap` carries only `font`, `wght`, `tracking` and `"sizeRule": "3 × paragraph line height"`.
- `space` (14 values: 0, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64, 80, 96, 128 under keys `0 1 2 3 4 5 6 8 10 12 16 20 24 32`), `grid` (`phone [4,16,12]`, `tablet [8,32,16]`, `desktop [12,48,24]`, `wide [12,72,24,1760]`, `cinema [12,96,32,1760]`), `bp` (`tablet 600`, `frame 768`, `desktop 1024`, `wide 1440`, `cinema 1920`), `radius` (`0: 0`, `round: 9999`), `blur` (`letter 8`, `rack 14`, `bleed 56`, `card 24`, `defocus 6`), `rule` (`hair`, `strong`, `ink`, `heavy`, `spot`, `proof`, `oxford` with widths and colour keys of §2.8.2), `focus` (`width 2`, `offset 2`, `halo 6`), `hit` (`min 44`, `android 48`, `fine 32`), `z` (`page 0` … `debug 90`, ten keys).
- `scrim` (§2.8.3): the 13 stops and 13 alphas (`kScrimStops`, `kScrimAlpha`), and per scrim its kind: `gutter`, `foot.black`, `rail-end`, `vignette`, `modal` are complete values; `foot`, `head`, `sole` are utility-only (they read variables set on the painting element).
- `dur` (§2.8.4): all 65 duration keys as `{ "value": n, "unit": "ms" }` (from `cut 0` to `loop.preview 12000`, including `letter` with child `blur`, `hold.toast` with children, `hold.annual.page/list`, `flame.*`).
- `ease` (§4.3): `settle`, `lift`, `turn`, `set`, `drift`, `scroll` as `{ "bezier": [...] }` and `linear` as the literal `"linear"`.
- `spring` (§4.4): `release {ms 420, bounce 0}`, `sheet {ms 480, bounce 0}`, `scrub {ms 240, bounce 0}`. No `format` key (Cinematic uses the stack's visual-duration springs).
- `scalar` (§2.8.4): `stagger.grid {item 32, row 64, cap 480}`, `stagger.list {item 24, cap 360}`, `stagger.letter {item 24, cap 560, startDelay 120}`, `stagger.word {item 30, fade 160}`, `stagger.fly {item 60}` (all ms), `letter.rise 0.42 em`, `rubber 0.35`, `pace.top 1.2`, `pace.words 60`, `pace.min 0.5`, `pace.max 1.0`.
- `ahap` (§5): the six signature patterns as event lists, `T` = `{ "type": "T", "t", "i", "s" }`, `C` = `{ "type": "C", "t", "dur", "i", "s" }`: `impress` T@0 I0.90 S0.20, T@0.045 I0.30 S0.10; `stamp` T@0 I0.50 S0.30, T@0.070 I1.00 S0.20; `wipe` C@0 dur 0.300 I0.30 S0.15, T@0.300 I0.70 S0.25; `ignite` C@0 dur 0.400 I0.50 S0.20, T@0.400 I1.00 S0.30; `pressrun` T@0 I0.40 S0.30, T@0.060 I0.60 S0.30, T@0.120 I0.90 S0.25; `pass` T@0 I0.60 S0.40, T@0.100 I0.30 S0.60.
- `haptics` (§5): **every one of the 90 contract events** maps to a pattern string, a sequence, or `"none"`. Pattern grammar (shared with Glass, so define it now in `design/lib/haptics.mjs` and validate every value against it): a primitive name (`selection`, `light`, `medium`, `heavy`, `rigid`, `soft`, `success`, `warning`, `error`, `toggleOn`, `toggleOff`, `dragStart`, `rigidBack`), optionally `:<0..1>` (literal intensity) or `:velocity` or `:velocity<=<0..1>` (runtime-scaled); or `ahap:<name>` or `ahap:<name>{depth}` (the runtime appends the depth 1 to 4); or `"none"`. A sequence is `[first, { "after": ms, "then": pattern }, …]`; a repeat is `{ "repeat": pattern, "every": ms, "max": n }`. Cinematic's map: `tap.primary` `ahap:impress`; `tap.secondary` none; `toggle.on` `medium`; `toggle.off` `light`; `select` `selection`; `nav.change` `rigid`; `longpress.open` `heavy`; `sheet.detent` `light`; `sheet.dismiss` none; `refresh.arm` `medium`; `refresh.fire` none; `follow.add` `ahap:stamp`; `follow.remove` `light`; `favorite` `light`; `bookmark.add` `ahap:impress`; `download.start` `light`; `download.done` `success`; `download.fail` `error`; `delete.confirm` `warning`; `undo` `light`; `reader.enter` `ahap:wipe`; `page.turn` `selection`; `scrub.tick` `selection`; `scrub.boundary` `medium`; `chapter.complete` `["medium", {"after": 120, "then": "light"}]`; `chapter.next` `heavy`; `autoscroll.toggle` `rigid`; `autoscroll.step` `selection`; `autoscroll.end` `heavy`; `zoom.snap` `light`; `listen.toggle` `rigid`; `voice.assign` `ahap:impress`; `sleep.fade` `soft`; `streak.extend` `ahap:ignite`; `streak.milestone` `["ahap:ignite", {"after": 520, "then": "ahap:stamp"}]`; `recap.countdown.end` none; `annual.page` `selection`; `share.export` `ahap:pressrun`; `reaction.send` `ahap:stamp`; `recommend.send` `ahap:pass`; `gate.confirm` `ahap:stamp`; `splash.impress` `ahap:impress`; `profile.select` `heavy`; `skin.switch` `heavy`; `reader.unlock` `medium`; `success` `success`; `error` `error`; and every one of Glass's 43 additions `none` (cinematic §5, glass §15.6 "Cinematic maps these to none").
- `hapticsWeb` (§5, the S3 amendment): `longpress.open [12]`, `follow.add [12]`, `streak.milestone [12]`, `download.fail [20, 40, 20]`, `error [20, 40, 20]`; nothing else.
- `sounds` (§6, cue to file stem under `sounds/cinematic/`; the web adds `.ogg` or `.m4a`, the app `.wav`, per the plan for `shared/03`): `tick`, `set`, `impress`, `turn`, `wipe`, `done`, `bell`, `pass`, `error`, `toggle.on` → `toggle-on`, `toggle.off` → `toggle-off`, `sheet`, `reel` (13 cues). This replaces the illustrative `press/tick.wav` paths of the §15.1 excerpt.
- `soundEvents` (§6): **every one of the 52 contract sound events** maps to a cue or `null`. Cinematic's map: `tap.primary` set, `toggle.on` toggle.on, `toggle.off` toggle.off, `select` tick, `nav.change` tick, `follow.add` impress, `favorite` tick, `bookmark.add` set, `download.done` done, `download.fail` error, `undo` tick, `reader.enter` wipe, `page.turn` turn, `refresh.arm` tick, `scrub.boundary` tick, `chapter.complete` done, `chapter.next` turn, `autoscroll.toggle` tick, `voice.assign` set, `streak.extend` bell, `streak.milestone` bell, `annual.page` turn, `share.export` set, `reaction.send` impress, `recommend.send` pass, `gate.confirm` impress, `skin.switch` impress, `reader.unlock` toggle.on, `error` error, `sheet.open` sheet, `splash.reveal` reel, and `null` for all 21 Glass-only sound events.

### 3. `design/build.mjs` and helpers

Entry point about 150 lines; helpers in `design/lib/`. Every generated file starts with the one-line header `GENERATED by design/build.mjs from <source json> — do not edit.` in the target language's comment syntax, and contains no timestamps (so `--check` is deterministic).

**Runs.** `node design/build.mjs` reads `design/contract.json` and every `design/tokens/*.json` present (today only `cinematic.json`) and writes the outputs. `node design/build.mjs --check` renders everything in memory, compares byte for byte with the committed files, prints each differing path, and exits 1 on any difference (and on any validation error); it runs `design/lint-utilities.mjs` after the comparison and exits with its status. Validation (both modes): every contract `hapticEvents` name has an entry in each skin's `haptics`; every `soundEvents` name has an entry in each skin's `soundEvents`; every cue a skin's `soundEvents` names exists in its `sounds`; every `ahap:` name exists in its `ahap`; every haptic value matches the grammar; no key appears twice after naming (below).

**Naming (one function per target in `design/lib/naming.mjs`).**
- CSS property: `--mm-` + key with dots and underscores turned into hyphens and camelCase into kebab-case (`color.mood.slice_of_life` → `--mm-color-mood-slice-of-life`; Glass's `color.onGlass` → `--mm-color-on-glass`). The `_` child drops out (`color.spot._` → `--mm-color-spot`).
- Tailwind `@theme` name: the CSS name without `mm-` in its namespace (`--color-paper-2: var(--mm-color-paper-2)`).
- Dart `CineTokens` field: camelCase of the full key (`colorSpotPress`, `colorStockSepiaNightPage`, `durWipeClose`, `typeBodyItalic`, `scalarStaggerGrid`, `space0`, `zPage`).
- Dart static member: the key without its group (`CineColors.paper0`, `CineColors.spot`, `CineDur.wipeClose`, `CineCurves.settle`, `CineSprings.release`, `CineSpace.s0` for numeric-only names). If the stripped name is a Dart reserved word or built-in identifier (`set` from `ease.set`, and the full list in the Dart language spec), keep the full camelCase key instead (`CineCurves.easeSet`).
- TS member: camelCase without the group (`dur.wipeClose`, `spring.sheet`, `scalar.staggerGrid`, as §2.8.4 shows).

**Value kinds** (cinematic §15.1; one rule each):
- Colour: hex or `rgba()`. CSS literal; Dart `Color(0xAARRGGBB)` with `AA = Math.round(alpha × 255)` in hex (so `0.16` → `0x29`, `0.35` → `0x59`, `0.64` → `0xA3`, `0.78` → `0xC7`, `0.96` → `0xF5`, matching §2.8.1).
- Length: logical px. CSS `px`; Dart `double`.
- Integer (`z.*`): CSS unitless; Dart `int`.
- Curve: `{bezier}` → CSS `cubic-bezier(x1, y1, x2, y2)`, TS `[x1, y1, x2, y2]`, Dart `Cubic(x1, y1, x2, y2)`; `"linear"` → `linear`, `"linear"`, `Curves.linear`. (The stack's `{ms, bezier}` form is also accepted and additionally emits a `--mm-dur-<name>` property; Glass needs it.)
- Spring: `{ms, bounce}`. TS (Cinematic, no `format`): `{ type: "spring", visualDuration: ms / 1000, bounce }`. Dart: `SpringToken(ms: ms, bounce: bounce, flutterScale: 1.2)` whose `description` getter returns `SpringDescription.withDurationAndBounce(duration: Duration(milliseconds: (ms * flutterScale).round()), bounce: bounce)` (it is a `factory` in Flutter 3.44.6's `packages/flutter/lib/src/physics/spring_simulation.dart`, so it cannot be `const`; hence a getter). CSS: `--mm-spring-<name>: linear(…)` plus `--mm-spring-<name>-ms: <T>ms` from `design/lib/spring.mjs` (below).
- Scalar: `{value, unit}`, or an object of scalars (a stagger). `dur.*` → CSS `<n>ms`, TS seconds (`dur.tick = 0.08`), Dart `Duration(milliseconds: n)`; `em` → CSS `<n>em`, TS and Dart plain numbers (Dart multiplies by the font size at use); unitless → plain numbers. A stagger → TS object, Dart `MotionStagger(item:, row:, cap:, startDelay:, fade:)` (all optional ints).
- Structured groups (`font`, `type`, `grid`, `bp`, `rule`, `scrim`, `focus`, `hit`, `haptics`, `hapticsWeb`, `ahap`, `sounds`, `soundEvents`): one emitter each, shapes below.

**The spring port (`design/lib/spring.mjs`, about 40 lines, cinematic §2.8.4 and §15.10 S13).** It must reproduce Motion's `spring(visualDuration, bounce).toString()` byte for byte with Node stdlib only. The rules below are those of `motion-dom` 12.42.2 (`frontend/node_modules/motion-dom/dist/cjs/index.js`, functions `getSpringOptions`, `spring` and `generateLinearEasing`, installed today with `framer-motion` 12.42.2); a port written to them was checked on this box against that file for 126 `{ms, bounce}` pairs (ms 120 to 900, bounce 0 to 0.5) with zero differences. Read those three functions once before you write the port. The module exports `motionSpring(ms, bounce)`, returning the whole `"<T>ms linear(…)"` string exactly as Motion's `toString()` prints it, and `springCss(ms, bounce)`, returning `{ ms: T, easing: "linear(…)" }` for the emitters.
- ω = 2π / (1.2 × ms / 1000) (stiffness k = ω², mass 1), ζ = clamp(0.05, 1, 1 − bounce).
- Position from rest at 0 to target 1, t in seconds: critically damped `x(t) = 1 − (1 + ωt)e^(−ωt)`; underdamped (ζ < 1) with ω_d = ω√(1 − ζ²): `x(t) = 1 − e^(−ζωt)(cos ω_d t + (ζω/ω_d) sin ω_d t)`.
- Velocity is the analytic derivative, in units per second (Motion's `resolveVelocity`, not a finite difference): critically damped `v(t) = ω² t e^(−ωt)`; underdamped `v(t) = e^(−ζωt) (ω² / ω_d) sin ω_d t`.
- Rest ("done") at time t: `|1 − x(t)| ≤ 0.005` and `|v(t)| ≤ 0.01` (Motion's granular rest thresholds).
- Settle time T: step t = 0, 50, 100 … ms until rest holds, cap 20,000 ms.
- Samples: n = max(round(T / 30), 2); sample i is taken at t_i = T × i / (n − 1); it is exactly `1` when rest holds at t_i (Motion returns the target once `done`), otherwise `Math.round(x(t_i) × 10000) / 10000`; values are printed with JS number formatting and joined by `", "` inside `linear(…)`. This is why the strings end in `1` (or `1, 1`) rather than `0.9995`.
- Reference vectors (from the installed `motion-dom` 12.42.2 on this box; put them in `design/test/spring.test.mjs`, asserting T, n, the head and the tail): `release {420, 0}` → T 800, n 27, starts `linear(0, 0.0572, 0.1795, 0.3195, 0.4536,`, ends `, 0.999, 1, 1)`; `sheet {480, 0}` → T 850, n 28, starts `linear(0, 0.0471, 0.1512, 0.2754, 0.399,`, ends `, 0.9982, 0.9987, 1)`; `scrub {240, 0}` → T 500, n 17, starts `linear(0, 0.1495, 0.3955, 0.6061, 0.7562,`, ends `, 0.9992, 1, 1)`; underdamped `{400, 0.3}` → T 650, n 22, starts `linear(0, 0.0676, 0.2212, 0.4046, 0.5821,`, ends `, 0.9999, 0.9986, 1)`; `{300, 0.5}` → T 800, n 27, starts `linear(0, 0.1187, 0.3801, 0.6679, 0.9085,`, ends `, 1.0006, 0.9998, 1)`. Also assert the Flutter description numbers: `release` stiffness 155.42 and damping 24.93 (both ±0.01), because Motion's k and Flutter's k match only through the ×1.2. The parity test against the installed `motion` 13.4.4 lands in web/01, not here; if web/01 reports a difference after its upgrade, the fix is in this file's rules (shared track), and web/01 stops rather than editing `design/`.
- Do not add Glass's physical-spring mode here; `shared/01` adds it to the same file with its own vectors.

**Route builders (`design/lib/route.mjs`, cinematic §8.0.3 "Encoded route builders").** Every path segment value is percent-encoded with `encodeURIComponent` on the web and `Uri.encodeComponent` in Dart; both leave `A–Z a–z 0–9 - _ . ! ~ * ' ( )` unencoded, so both clients produce identical segments (checked on this box with Dart 3 from Flutter 3.44.6). Query strings: web `new URLSearchParams(entries).toString()` (WHATWG `application/x-www-form-urlencoded`: UTF-8 bytes, `A–Z a–z 0–9 * - . _` kept, space → `+`, every other byte `%XX` uppercase). Dart must **not** use `Uri(queryParameters: map).query`: it keeps `~` and encodes `*`, the opposite of `URLSearchParams` (checked on this box: `a~b*c` gives `a%7Eb*c` on the web and `a~b%2Ac` in Dart). The generated `contract.g.dart` therefore carries a private `String _formEncode(String s)` of about 12 lines implementing exactly the WHATWG rule above over `utf8.encode(s)`, and query strings are `key=value` pairs joined by `&` in the map's insertion order, appended after `?` (never through `Uri(path: …)`, which would re-encode the `%` of an already encoded path). Undefined and null values are skipped; other values go through `String()` / `toString()`. Reference vectors for `design/test/route.test.mjs` (the same vectors go into the generated Dart test): `feature("mangadex", "a/b c%")` → `/sources/mangadex/series/a%2Fb%20c%25`; `reader("s1", "x!y", "é")` → `/reader/s1/x!y/%C3%A9`; `recap("s1", "k", { to: "12" })` → `/recap/s1/k?to=12`; `library({ q: "solo leveling", fav: 1 })` → `/library?q=solo+leveling&fav=1`; `discover({ q: "a~b*c é" })` → `/search?q=a%7Eb*c+%C3%A9`; `settings()` → `/settings`; `settings("reading-manga")` → `/settings/reading-manga`.

**Outputs** (six files from the stack plus the S16 shared theme and the generated Dart types and test):

1. `frontend/src/skins/cinematic/tokens.generated.css`:
   - `[data-skin="cinematic"] { … }` with every non-utility property of §2.8 and §3.5: colours, `--mm-space-*`, grid variables set per breakpoint media query (`phone` < 600, `tablet` 600 to 1023, `desktop` 1024 to 1439, `wide` 1440 to 1919, `cinema` ≥ 1920; `--mm-grid-columns`, `--mm-grid-margin`, `--mm-grid-gutter`, `--mm-grid-template: repeat(N, minmax(0, 1fr))`), `--mm-bp-*` (documentation), `--mm-radius-*`, `--mm-blur-*`, `--mm-rule-*-width`, `--mm-focus-width: 2px; --mm-focus-offset: 2px; --mm-focus-halo: 0 0 0 6px #000`, `--mm-hit-min: 44px` and `32px` under `@media (pointer: fine)`, `--mm-z-*`, `--mm-scrim-gutter`, `--mm-scrim-foot-black`, `--mm-scrim-rail-end`, `--mm-scrim-vignette`, `--mm-scrim-modal`, every `--mm-dur-*`, `--mm-ease-*`, `--mm-spring-*` and `--mm-spring-*-ms`, `--mm-font-text: var(--mm-font-newsreader)`, and the type-role variables below.
   - Type-role variables, per role: `--mm-type-<role>-family` (`var(--mm-font-display)`, `var(--mm-font-grotesk)`, `var(--mm-font-text)` for `deck`, `body`, `body-italic`, or `var(--mm-font-folio)`), `-style` (`italic` or `normal`), `-size` (rem, redefined per breakpoint media query; a fluid role's size is its `clamp()` once), `-lh` (rem per breakpoint; a fluid role's is the unitless ratio per breakpoint), `-tracking` (em), `-wght`, `-fvs` (a static string such as `"opsz" 48, "wght" 600` or `"wdth" 62, "wght" 700`), `-transform` (`uppercase` or `none`). Sizes and line heights are authored in rem (px / 16) so browser font size scales them (§3.2).
   - The Hyperlegible block of §3.4: `html[data-legible="on"][data-skin="cinematic"] { --mm-font-text: var(--mm-font-atkinson); }` with `--mm-type-deck-lh` 28 / 32 / 32 / 36 px and `--mm-type-body-lh`, `--mm-type-body-italic-lh` 28 / 28 / 32 / 32 px per breakpoint (as rem).
   - The raised and wash stock scopes of §2.1.1: `[data-skin="cinematic"] [data-stock="raised"] { --mm-color-ink-45: var(--mm-color-ink-60); }` and `[data-skin="cinematic"] [data-stock="wash"] { --mm-color-ink-45: var(--mm-color-ink-80); --mm-color-ink-60: var(--mm-color-ink-80); }`, and the `@media (prefers-contrast: more)` remap of §14.4 (`--mm-color-ink-45: var(--mm-color-ink-80); --mm-color-rule-1: var(--mm-color-rule-2)`).
2. `frontend/src/skins/cinematic/tokens.generated.ts`: `as const` objects `color`, `space`, `grid`, `bp`, `radius`, `blur`, `z`, `dur` (seconds), `durMs`, `ease`, `spring` (Motion transitions), `springCss` (`{ ms: T, easing: "linear(…)" }`), `scalar`, `type` (the role data: family key, italic, wght, axes, sizes, lines, trackingEm, cap, upper), `haptics`, `hapticsWeb`, `ahap`, `sounds`, `soundEvents`. Import `HapticEvent` and `SoundEvent` types from `../contract.generated` and type the maps as `Record<HapticEvent, HapticValue>` and `Record<SoundEvent, SoundCue | null>` so a missing event is a type error.
3. `frontend/src/skins/theme.generated.css` (cinematic §15.10 S16): the shared block both skins will fill. It holds:
   - The `@property` registrations of the runtime colours `--amb-duo`, `--amb-tint`, `--amb-ink`, `--page-tint`, `--page-light` (`syntax: "<color>"; inherits: true`), initial values `#B8B2A4`, `#0E0D0B`, `#F3F0E8`, `#0E0D0B`, `#F3F0E8` (the `ambient.fallback` tokens, §2.8.1). They live here, not in the skin file: `@property` is global whatever file declares it (the last registration of a name wins), so every registration goes into this one shared file, deduplicated, and the generator fails if two skins register one name with different descriptors (Glass reuses `--page-tint` in `shared/01`). This is the one deliberate move from cinematic §15.2's first row.
   - `@theme { --breakpoint-tablet: 37.5rem; --breakpoint-frame: 48rem; --breakpoint-desktop: 64rem; --breakpoint-wide: 90rem; --breakpoint-cinema: 120rem; }`.
   - `@theme inline { … }` with one entry per token name: colours `--color-X: var(--mm-color-X)`, radius `--radius-X`, blur `--blur-X`, curves `--ease-X: var(--mm-ease-X)`, springs `--ease-spring-X: var(--mm-spring-X)`, fonts `--font-display`, `--font-grotesk`, `--font-text`, `--font-folio`, type roles `--text-<role>: var(--mm-type-<role>-size); --text-<role>--line-height: var(--mm-type-<role>-lh); --text-<role>--letter-spacing: var(--mm-type-<role>-tracking); --text-<role>--font-weight: var(--mm-type-<role>-wght);`, and the runtime colours `--color-amb-duo: var(--amb-duo)`, `--color-amb-tint`, `--color-amb-ink`, `--color-page-tint`, `--color-page-light`, `--color-stock-page: var(--stock-page)`, `--color-stock-ink`, `--color-stock-muted`. The rule "Tailwind name `X` maps to `var(--mm-X)`" is identical for both skins, so the union never conflicts. When two skins define the same name, emit it once.
   - **Legacy collisions.** Until the flip, legacy pages load the same stylesheet, and the legacy `@theme` block in `frontend/src/app/globals.css` (plus Tailwind 4's default theme) already owns a few names the skins also use. For exactly these names emit the entry with the value legacy renders today as the `var()` fallback, so a page where no `--mm-*` is defined looks unchanged: `--font-display: var(--mm-font-display, var(--font-syne), Impact, sans-serif)` (a Cinematic name) and the eleven Glass names, which you emit now too so web/00 can rely on them whatever order the sessions run in: `--font-sans: var(--mm-font-sans, var(--font-dm-sans), system-ui, sans-serif)`, `--font-mono: var(--mm-font-mono, var(--font-dm-sans), ui-monospace, monospace)`, `--font-serif: var(--mm-font-serif, ui-serif, Georgia, Cambria, "Times New Roman", Times, serif)`, `--color-danger: var(--mm-color-danger, var(--mm-danger, #F85149))`, `--color-success: var(--mm-color-success, var(--mm-success, #3FB950))`, `--color-warning: var(--mm-color-warning, var(--mm-warning, #D29922))`, `--radius-xs: var(--mm-radius-xs, 0.125rem)`, `--radius-sm: var(--mm-radius-sm, 0.375rem)`, `--radius-md: var(--mm-radius-md, 0.5rem)`, `--radius-lg: var(--mm-radius-lg, 0.625rem)`, `--radius-xl: var(--mm-radius-xl, 1.5rem)`. The three colours fall back to the legacy runtime variables, not to literals, because legacy re-points them per theme at runtime (`globals.css` `:root { --color-danger: var(--mm-danger); … }` and the `[data-theme]` blocks set `--mm-danger` to `#F85149`, `#ef4444` or `#B91C1C`); an inlined literal would freeze them. Keep this table in `design/lib/legacy-fallbacks.mjs` (one object, deleted by the flip release). **How web/00 uses it (do not tell web/00 to delete anything):** web/00 imports `theme.generated.css` *before* the legacy `@theme` block, so for the ten names the legacy block defines (`--font-display`, `--font-sans`, `--font-mono`, `--color-danger`, `--color-success`, `--color-warning`, `--radius-sm`, `--radius-md`, `--radius-lg`, `--radius-xl`) the legacy definition wins in Tailwind (the last `@theme` definition of a key wins) and web/00's unlayered `frontend/src/skins/legacy-bridge.css` re-points each of them per skin (`html[data-skin="cinematic"] { --font-display: var(--mm-font-display); }`); the fallbacks above are what `--font-serif` and `--radius-xs` (Tailwind defaults, not legacy) resolve to on a legacy page, and a safety net for the other ten. Name the ten keys in your report so web/00's `legacy-bridge.test.ts` can be checked against them.
   - One `@utility type-<role>` per role name, **var-only and union-safe**, so the same utility serves Glass later without a second definition:
     ```css
     @utility type-<role> {
       font-family: var(--mm-type-<role>-family);
       font-style: var(--mm-type-<role>-style, normal);
       font-size: var(--mm-type-<role>-size);
       line-height: var(--mm-type-<role>-lh);
       font-weight: var(--mm-type-<role>-wght);
       letter-spacing: calc(var(--mm-type-<role>-tracking) + var(--mm-tracking-legible, 0em));
       text-transform: var(--mm-type-<role>-transform, none);
       font-variation-settings: var(--mm-type-<role>-fvs, "wght" calc(var(--mm-type-<role>-wght) + var(--press-wght, 0)), "ROND" var(--glass-rond, var(--mm-type-<role>-rond, 0)), "GRAD" var(--glass-grad, 0));
     }
     ```
     Cinematic defines `-fvs` (a static string, safe to declare on `<html>`); Glass will leave it undefined so the fallback resolves on the element, where `--glass-rond` lives (glass §3.5, §3.7). `type-dropcap` is special: `float: left; font-family: var(--mm-font-display); font-weight: 800; font-size: calc(var(--para-lh) * 3); line-height: 1; letter-spacing: -0.02em; font-optical-sizing: auto; font-variation-settings: "wght" 800;` (automatic optical sizing sets `opsz` to the used font size in px, which Bodoni Moda's axis clamps at 96, so it is exactly §3.5's `opsz = min(size, 96)`; a fixed `"opsz" 96` would be wrong for a 72 px drop cap on 24 px leading) plus `@supports (initial-letter: 3) { initial-letter: 3; }` (cinematic §3.5 row `type.dropcap`).
   - The scrim utilities of §2.8.3 with exactly the bodies given there, the eased stops expanded by the generator as literals: `scrim-gutter`, `scrim-foot` (with `--scrim-solid-at`, `--amb-tint` and the 40 % start), `scrim-foot-black`, `scrim-head` (with `--scrim-fade` and `--scrim-base`, P = 88 × alpha), `scrim-sole` (P = 90 × alpha), `scrim-rail-end`, `scrim-vignette`. `--scrim-base` stays unregistered (§2.8.3 explains why).
4. `frontend/src/skins/contract.generated.ts`: `SCREEN_IDS` (`as const`) and `type ScreenId`; `SCREENS` (id to path, params, query names, aliases, redirect); `ROUTES` with one typed builder per screen (`ROUTES.feature(sourceId, seriesKey, query?)`, `ROUTES.settings(section?)`), each query parameter typed by the screen's names and closed value sets; `SETTINGS_SECTIONS` and `type SettingsSection`; `SHEET_IDS` and `type SheetId`; `FLAGS = { glassAvailable: false } as const`; `HAPTIC_EVENTS`, `type HapticEvent`, `SOUND_EVENTS`, `type SoundEvent`. The builder function is the one in `design/lib/route.mjs`, emitted with TypeScript types.
5. `mobile/lib/skins/cinematic/tokens.g.dart`:
   - `class CineTokens extends ThemeExtension<CineTokens>` with one `final` field per key (colours `Color`, lengths `double`, `z` `int`, durations `Duration`, curves `Curve`, springs `SpringToken`, staggers `MotionStagger`, scalars `double`, type roles `CineTextRole`, grid `GridSpec`, rules `BorderSide` and `OxfordRule`, focus doubles, scrims as the static values of §2.8.3), a `const` constructor, a complete `copyWith` (the raised-stock scope `CineStock.raised` needs `copyWith(colorInk45: …)`, §2.1.1) and `lerp` (colours through `Color.lerp`, everything else switches at t = 0.5).
   - `const cinematicTokens = CineTokens(…)` and `extension CineTokensContext on BuildContext { CineTokens get cine => Theme.of(this).extension<CineTokens>()!; }`.
   - `abstract final class` static-const holders `CineColors`, `CineSpace`, `CineDur`, `CineCurves`, `CineSprings`, `CineScrim` (`kScrimStops`, `kScrimAlpha` as `const List<double>`).
   - `class CineTextRole` (family, italic, wght, axes map, sizes, lines, trackingEm, cap, upper) and `class CineType` with `static TextStyle style(BuildContext context, CineTextRole role, {bool legible = false})`: picks the breakpoint from `MediaQuery.sizeOf(context).width` (< 600 phone, < 1024 tablet, < 1440 desktop, else wide), sets `fontFamily`, `fontStyle`, `fontSize`, `height = line / size`, `letterSpacing = trackingEm × size`, `fontVariations` (`wght`, plus `opsz` = min(size, 96) for Bodoni Moda and Newsreader or the role's `wdth`), adds 120 to `wght` when `MediaQuery.boldTextOf(context)` is true (clamped to the family's axis maximum from `font`) and sets `fontWeight` to the nearest hundred; with `legible: true` the `deck`, `body` and `body.italic` roles switch to `AtkinsonHyperlegibleNext` and add 4 px to the line (§3.4); `static TextScaler scaler(BuildContext context, CineTextRole role)` returns `MediaQuery.textScalerOf(context).clamp(maxScaleFactor: role.cap)`; `static TextStyle dropcap(double paragraphLineHeightPx)` per §3.5.
   - `const Map<HapticEvent, List<HapticStep>> cinematicHaptics` (every event; `none` is an empty list; a sequence becomes several steps with `afterMs`), `const Map<String, List<AhapEvent>> cinematicAhap`, `const Map<String, String> cinematicSoundCues` (cue to `assets/sounds/cinematic/<stem>.wav`) and `const Map<SoundEvent, List<String>> cinematicSoundEvents` (empty list for silent).
6. `mobile/lib/skins/token_types.g.dart` (shared value types both skins' generated files import): `SpringToken` (`ms`, `bounce`, `flutterScale`, the `description` getter), `CurveToken` (`ms`, `curve`), `MotionStagger`, `GridSpec`, `OxfordRule`, `HapticStep` (`pattern`, `afterMs`, `repeatEveryMs`, `maxRepeats`), `AhapEvent` (`type`, `time`, `duration`, `intensity`, `sharpness`) and `FocusRingSpec` (`width`, `offset`, `color`, `innerColor`, `innerWidth`, `glow`, `glowColor`), all with `const` constructors.
7. `mobile/lib/skins/contract.g.dart`: `enum ScreenId` whose values carry `id` and `path` (the Dart value for `index` is `indexHub`, because an enum cannot declare a value named `index`; `ScreenId.indexHub.id == 'index'`); `abstract final class Routes` with `static const` patterns (`Routes.featurePattern = '/sources/:sourceId/series/:seriesKey'`), the alias patterns, and one encoding builder per screen with the same vectors as the web; `enum SettingsSection` (one value per slug of `settingsSections`, named by the camelCase of the slug, `about` → `about`, `reading-manga` → `readingManga`, `reading-novels` → `readingNovels`, with `.slug` carrying the kebab name); `abstract final class SheetIds` constants; `abstract final class Flags { static const bool glassAvailable = false; }`; `enum HapticEvent` and `enum SoundEvent` whose values are the camelCase of the dotted name with `.id` holding the dotted name (`HapticEvent.tapPrimary.id == 'tap.primary'`).
8. `mobile/test/skins/generated_contract_test.dart` (generated; it is the compile proof, because the analyzer skips `*.g.dart`): asserts `ScreenId.values.length == 35`, `ScreenId.indexHub.id == 'index'`, the seven route vectors above (including the `a~b*c é` query vector), `HapticEvent.values.length == 90`, `SoundEvent.values.length == 52`, `CineColors.spot == Color(0xFFF4D03F)`, `cinematicTokens.colorSpotWash == Color(0x29F4D03F)`, `CineSprings.release.description.stiffness` 155.42 ± 0.01 and `.damping` 24.93 ± 0.01, `CineSprings.sheet.description` from a 576 ms duration, `cinematicHaptics[HapticEvent.chapterComplete]!.length == 2` with the second step's `afterMs == 120`, every `HapticEvent` present in `cinematicHaptics`, and every `SoundEvent` present in `cinematicSoundEvents`. The route and spring literals are written into the generator's template, not derived from the JSON, so they catch regressions.

### 4. `design/lint-utilities.mjs` (about 40 lines, cinematic §2.8 "Lint scope", S2)

Scans `frontend/src/skins/cinematic/**/*.{ts,tsx,css}` except `*.generated.*` (and, from `shared/01` on, `glass/**` against Glass's names). Collects class-like tokens from string literals and `@apply` lines, strips variant prefixes (`hover:`, `focus-visible:`, `frame:`, `desktop:`, `wide:`, `tablet:`, `cinema:`, `before:`, `after:`, `motion-reduce:`, `contrast-more:`, `forced-colors:`, a leading `!` or `-`) and an `/NN` opacity suffix, then checks tokens starting with `bg-`, `text-`, `border-`, `outline-`, `fill-`, `stroke-`, `font-`, `tracking-`, `leading-`, `rounded-`, `blur-`, `backdrop-`, `ease-`, `duration-`, `z-`, `animate-`:
- allowed token names: the ones the generator put into `theme.generated.css` for this skin (colours after `bg-`, `text-`, `border-`, `outline-`, `fill-`, `stroke-`; `text-<role>`; `font-display|grotesk|text|folio`; `rounded-0`, `rounded-round`; `blur-<name>`; `ease-<curve>`, `ease-spring-<name>`, `ease-linear`), plus the `animate-*` names found in an `@theme` block of `frontend/src/skins/cinematic/motion.css` when that file exists;
- allowed structural suffixes: `text-left|center|right|justify|start|end|wrap|nowrap|balance|pretty|ellipsis|clip`; `border`, `border-0|2|3|4`, `border-t|r|b|l|x|y` with optional `-0|2|3`, `border-solid|dashed|dotted|none`; `outline-none|hidden|0|1|2`, `outline-offset-0|1|2|4`; `bg-none|cover|contain|center|top|bottom|left|right|no-repeat|repeat|fixed|local|scroll`, `bg-clip-*`, `bg-origin-*`, `bg-[url(…)]`; `fill-none`, `stroke-none`, `stroke-0|1|2`; `animate-none`;
- any arbitrary `(--mm-*)` reference (`duration-(--mm-dur-line)`, `bg-(--mm-scrim-modal)`, `z-(--mm-z-sheet)`, `tracking-(--mm-…)`, `leading-(--mm-…)`);
- always rejected: arbitrary colour values (`[#…]`, `[rgb…]`, `[hsl…]`, `[oklch…]`), any `backdrop-*` utility (cinematic §2.5: no `backdrop-filter` anywhere), `duration-<number>`, `z-<number>`, and every other name.
Prints `file:line token` for each failure and exits 1; exits 0 with a one-line summary when clean. With no hand-written skin files yet it must pass.

### 5. Self-checks: `design/test/spring.test.mjs` and `design/test/route.test.mjs`

node:test files with the vectors above, run by `node --test design/test/`. Add a third, `design/test/contract.test.mjs`: 35 screens, unique ids and paths, static `/library/*` before `/library/:followedId`, 90 haptic events, 52 sound events, every skin's `haptics` and `soundEvents` complete.

### 6. CI

In `.github/workflows/tests.yml`, job `frontend`, add one step right after `actions/setup-node@v4` and before "Install dependencies":

```yaml
      - name: Design contract
        run: node design/build.mjs --check && node --test design/test/
```

### 7. Proof

`design/proof-sheet.mjs` (stdlib, about 80 lines) writes `docs/redesign/proof/shared-00/cinematic-tokens.svg`: every colour key as a 48 × 48 swatch with its key, value and contrast against `#000000` (WCAG 2.x); the three spring curves plotted from the generated `linear()` samples with their settle times; the duration scale as bars; the type roles as rows listing size/line per breakpoint. It is not called by `build.mjs` and not part of `--check`.

## File layout

Create:
```
design/
├── contract.json
├── tokens/cinematic.json
├── build.mjs                  entry, ~150 lines
├── lint-utilities.mjs         ~40 lines
├── proof-sheet.mjs
├── lib/
│   ├── naming.mjs
│   ├── spring.mjs
│   ├── route.mjs
│   ├── haptics.mjs            grammar + validation
│   ├── legacy-fallbacks.mjs   the colliding Tailwind names and their legacy values
│   ├── emit-css.mjs           tokens.generated.css + theme.generated.css
│   ├── emit-ts.mjs            tokens.generated.ts + contract.generated.ts
│   └── emit-dart.mjs          tokens.g.dart, token_types.g.dart, contract.g.dart, the generated test
└── test/
    ├── spring.test.mjs
    ├── route.test.mjs
    └── contract.test.mjs
frontend/src/skins/theme.generated.css
frontend/src/skins/contract.generated.ts
frontend/src/skins/cinematic/tokens.generated.css
frontend/src/skins/cinematic/tokens.generated.ts
mobile/lib/skins/token_types.g.dart
mobile/lib/skins/contract.g.dart
mobile/lib/skins/cinematic/tokens.g.dart
mobile/test/skins/generated_contract_test.dart
docs/redesign/proof/shared-00/cinematic-tokens.svg, tokens-1440.png, tokens-390.png
```
Change: `.github/workflows/tests.yml` (one step). Nothing else. Do not import the generated files anywhere; web/00 adds `@import` lines to `app/globals.css`, mobile/01 imports the Dart files.

## Acceptance criteria

- [ ] `design/contract.json` has 35 screens with the table's paths, params, query names, aliases and the two redirects; the static `/library/*` screens precede `featureByFollow`; 29 sheet ids; 20 settings sections (including `ai`); `flags.glass_available` is `false`; 90 haptic events and 52 sound events, no duplicates.
- [ ] `design/tokens/cinematic.json` contains every key in cinematic §2.8.1 to §2.8.4 and §3.5 with identical values (spot-check at least: `color.spot.wash`, `color.stock.rosewood.muted`, `color.avatar.reader`, `grid.cinema`, `dur.flame.ring`, `dur.hold.annual.list`, `ease.scroll`, `spring.scrub`, `scalar.stagger.letter.startDelay`, `type.micro` sizes `[10,10,10,11]` and cap 1.5); `haptics` covers all 90 events and `soundEvents` all 52.
- [ ] `node design/build.mjs` writes all eight generated files (four under `frontend/src/skins/`, three under `mobile/lib/skins/`, one test under `mobile/test/skins/`); a second run changes nothing (`git status` clean after committing the first).
- [ ] `node design/build.mjs --check` exits 0; after appending one space to `frontend/src/skins/cinematic/tokens.generated.css` it exits 1 and names that file; after re-running `node design/build.mjs` it exits 0 again.
- [ ] `node --test design/test/` passes, including every spring and route vector listed above.
- [ ] `node design/lint-utilities.mjs` exits 0 on today's tree; a scratch file `frontend/src/skins/cinematic/_lintprobe.tsx` containing `className="bg-[#fff] backdrop-blur-sm text-ink-100 duration-300 rounded-md"` makes it exit 1 naming `bg-[#fff]`, `backdrop-blur-sm`, `duration-300`, `rounded-md` and not `text-ink-100`; delete the probe file afterwards and confirm it is gone before any commit.
- [ ] The generated CSS compiles with the installed Tailwind 4 (the scratch check in "Verification" prints `tailwind ok`) and produces classes for `bg-paper-2`, `bg-paper-2/90`, `text-ink-100`, `type-section`, `text-section`, `ease-settle`, `ease-spring-sheet`, `rounded-0`, `blur-letter`, `before:scrim-head`, `scrim-foot`, `duration-(--mm-dur-line)`.
- [ ] `theme.generated.css` carries the twelve legacy-collision entries of `design/lib/legacy-fallbacks.mjs`, each as `var(--mm-…, <legacy value>)`, with `--color-danger`, `--color-success` and `--color-warning` falling back to `var(--mm-danger, …)`, `var(--mm-success, …)` and `var(--mm-warning, …)`; nothing in this step asks web/00 to delete a legacy `@theme` entry.
- [ ] Every generated file starts with the `GENERATED by design/build.mjs` header and contains no timestamp.
- [ ] Reduced motion: no generated file hard-codes a motion behaviour; the tokens carry `dur.reduced` (150 ms) and `dur.clip` (200 ms) so web/04 and mobile/04 can implement cinematic §4.8, and `scalar.*` and every `dur.*` used in §4.8 are present.
- [ ] Hit targets: `--mm-hit-min` is 44 px by default and 32 px under `@media (pointer: fine)`; `CineTokens.hitMin == 44` and `hitAndroid == 48` (the 44 pt / 48 dp rule of cinematic §14.6).
- [ ] Keyboard focus: `--mm-focus-width`, `--mm-focus-offset`, `--mm-focus-halo` and the Dart `focusWidth`, `focusOffset`, `focusHalo` exist with the §2.8.2 values.
- [ ] Per-skin difference is enforced: every `@theme inline` entry and every `type-*` utility declaration in `theme.generated.css` is a `var(…)` (literal values appear only in the breakpoint `@theme` block, the `@property` initial values and the scrim and dropcap utility bodies), so Glass can add its own `[data-skin="glass"]` values in `shared/01` without touching Cinematic's.
- [ ] `frontend`: `npm run lint` 0 errors 0 warnings; `npm run typecheck` passes; `npm run test` passes and its test count is not lower than before this step (the CI header cites about 2,304 cases); `npm run build` passes.
- [ ] `mobile`: `flutter analyze` reports no issues; `flutter test` passes with 2012 + the new generated test's cases, 0 failed.
- [ ] `.github/workflows/tests.yml` has the "Design contract" step in the `frontend` job and nowhere else changed.
- [ ] `docs/redesign/proof/shared-00/cinematic-tokens.svg` exists and shows every colour, the three springs and the type rows; `tokens-1440.png` and `tokens-390.png` (headless Chromium, 1440 × 900 and 390 × 844) exist and you looked at both.
- [ ] The spring port's full strings (not only their heads) equal `spring(ms / 1000, bounce).toString()` of the installed `frontend/node_modules/motion-dom` for the five vectors: the scratch "Spring parity" command in "Verification commands" prints `spring parity ok` (scratch only, nothing committed; the committed parity test is web/01's).
- [ ] Every commit touches only the paths listed in "File layout"; none carries AI attribution; each was pushed.

## Verification commands

Run from the repo root unless a `cd` is shown, one heavy command at a time, `free -m` before each heavy one (stop under 1024 MB available).

```bash
node design/build.mjs
node design/build.mjs --check; echo "check exit $?"
node --test design/test/
node design/lint-utilities.mjs; echo "lint exit $?"

# Spring parity against the installed motion-dom 12.42.2 (scratch, not committed)
node --input-type=module -e "
import { createRequire } from 'node:module';
const { motionSpring } = await import(process.cwd() + '/design/lib/spring.mjs');
const m = createRequire(process.cwd() + '/')('./frontend/node_modules/motion-dom/dist/cjs/index.js');
let bad = 0;
for (const [ms, b] of [[420, 0], [480, 0], [240, 0], [400, 0.3], [300, 0.5]]) if (m.spring(ms / 1000, b).toString() !== motionSpring(ms, b)) { bad++; console.log('DIFF', ms, b); }
console.log(bad ? 'spring parity FAIL' : 'spring parity ok');
"

# Tailwind 4 compile check of the generated CSS (scratch, not committed)
cd frontend && node --input-type=module -e "
import {compile} from '@tailwindcss/node';
import fs from 'node:fs';
const css = '@import \"tailwindcss\";\n' + fs.readFileSync('src/skins/theme.generated.css','utf8') + '\n' + fs.readFileSync('src/skins/cinematic/tokens.generated.css','utf8');
const c = await compile(css, { base: process.cwd(), onDependency() {} });
const out = c.build(['bg-paper-2','bg-paper-2/90','text-ink-100','type-section','text-section','ease-settle','ease-spring-sheet','rounded-0','blur-letter','before:scrim-head','scrim-foot','duration-(--mm-dur-line)']);
const expect = ['.bg-paper-2 {', 'var(--mm-color-paper-2) 90%', '.text-ink-100 {', '.type-section {', '.text-section {', '.ease-settle {', '.ease-spring-sheet {', '.rounded-0 {', '.blur-letter {', 'scrim-head', '.scrim-foot {', 'var(--mm-dur-line)'];
const missing = expect.filter(e => !out.includes(e));
if (missing.length) { console.error('missing', missing); process.exit(1); } console.log('tailwind ok');
" ; cd ..

free -m
cd frontend && npm run lint && cd ..
free -m
cd frontend && npm run typecheck && cd ..
free -m
cd frontend && npm run test && cd ..
free -m
cd frontend && npm run build && cd ..
free -m
cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze && cd ..
free -m
cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter test && cd ..
node design/proof-sheet.mjs
git status --short
```

If the scratch Tailwind check reports a selector missing, print `out` and look at it: what matters is that `compile()` does not throw and every wanted class is emitted (Tailwind escapes `/`, `:` and parentheses in selectors, which is why the expectations above match declaration text rather than escaped selectors). Quote the `Tests  N passed` line of `npm run test` in your report; N must be at least 2,304 with 0 failed.

Backend: this step changes no backend code. `backend/.venv` does not exist yet (backend/00 creates it); if it does exist when you run, also run `cd backend && free -m && timeout 1800 .venv/bin/python -m pytest -q --no-header 2>&1 | tail -3` and quote the summary line. Either way the CI `backend` job (`cd backend && pytest -q --no-header`) must stay green on your pushed commits.

**Visual proof.** This step renders no web screen. The proof is `docs/redesign/proof/shared-00/cinematic-tokens.svg`, captured in headless Chromium at 1440 × 900 and 390 × 844 (full page) into `docs/redesign/proof/shared-00/tokens-1440.png` and `tokens-390.png`. If `~/.cache/ms-playwright` has no `chromium-*` folder, first run `cd frontend && npx playwright install chromium && cd ..` (and, only if the launch then fails on a missing shared library, `cd frontend && sudo npx playwright install-deps chromium && cd ..`):

```bash
cd frontend && node -e "
const { chromium } = require('playwright');
const path = require('node:path');
(async () => {
  const b = await chromium.launch();
  for (const [w, h] of [[1440, 900], [390, 844]]) {
    const p = await b.newPage({ viewport: { width: w, height: h } });
    await p.goto('file://' + path.resolve('../docs/redesign/proof/shared-00/cinematic-tokens.svg'));
    await p.screenshot({ path: '../docs/redesign/proof/shared-00/tokens-' + w + '.png', fullPage: true });
  }
  await b.close();
})();
" && cd ..
```

Look at both PNGs before the proof commit.

## Commit plan

1. `feat(design): route and event contract` — `design/contract.json`, `design/lib/route.mjs`, `design/test/route.test.mjs`, `design/test/contract.test.mjs`.
2. `feat(design): Cinematic token source` — `design/tokens/cinematic.json`, `design/lib/haptics.mjs`.
3. `feat(design): stdlib spring port with Motion reference vectors` — `design/lib/spring.mjs`, `design/test/spring.test.mjs`.
4. `feat(design): token generator with check mode` — `design/build.mjs`, `design/lib/naming.mjs`, `design/lib/emit-*.mjs`, `design/lint-utilities.mjs`.
5. `feat(design): generated Cinematic tokens and contract` — the eight generated files.
6. `ci: check the design contract in the frontend job` — `.github/workflows/tests.yml`.
7. `docs(redesign): Cinematic token proof sheet` — `design/proof-sheet.mjs`, `docs/redesign/proof/shared-00/cinematic-tokens.svg`, `tokens-1440.png`, `tokens-390.png`.

Push after each commit. Use `git add <explicit paths>` every time.

## Report back

Reply with:
- the checklist above with each box ticked or explained;
- counts: screens, sheet ids, settings sections, haptic events, sound events, colour tokens, type roles, duration tokens; the three spring settle times (`800`, `850`, `500` ms expected);
- the output lines of `node design/build.mjs --check`, `node --test design/test/` (pass count), `node design/lint-utilities.mjs`, `npm run lint`, `npm run typecheck`, `npm run test` (test count), `npm run build`, `flutter analyze`, `flutter test` (pass count);
- the lowest `available` value `free -m` showed;
- the proof paths `docs/redesign/proof/shared-00/cinematic-tokens.svg`, `tokens-1440.png` and `tokens-390.png`, and the `spring parity ok` line;
- the pushed commit hashes;
- the hand-off for web/00: the ten legacy-collision names that the legacy `@theme` block in `frontend/src/app/globals.css` also defines (they stay there; web/00 imports `theme.generated.css` before that block and re-points them per skin in `legacy-bridge.css`), plus `--font-serif` and `--radius-xs`, which resolve to this step's fallbacks on legacy pages;
- open issues, including anything in the DESIGN files you had to interpret.

**Next prompt file:** in the series order the next file is `docs/redesign/prompts/backend/00-profile-columns-and-dev-stack.md`; the next file on the shared track is `docs/redesign/prompts/shared/01-glass-tokens-haptics-motion-names-contrast.md`.
