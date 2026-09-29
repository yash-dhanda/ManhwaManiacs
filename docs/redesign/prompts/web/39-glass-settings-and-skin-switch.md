# Web Glass Settings and the skin switch

Track: web · Order 96 · Depends on: `docs/redesign/prompts/web/38-glass-search-sources-dialogue.md` · Runs in parallel with: `docs/redesign/prompts/mobile/39-glass-settings-and-skin-switch.md` · Proof folder: `docs/redesign/proof/web-39/`

## Goal

Build Glass Settings on the web client (`frontend/`) at `/settings` and `/settings/:section`: the grouped-list structure with the settings search (phones: pushed section pages and a full-screen search; desktop: a 240 px section list and a section panel), and the sections **Appearance and skin** (the two looping skin previews, Solid glass, Increase contrast, Legible text, Reduce motion, Screen reader mode, Light follows the device), **Reader defaults** with its Novels, Listen and Ambient groups and the one-time per-profile **migration** of stored values, **Content** (the 18+ flow), **Sound and haptics**, **Shortcuts**, **Account and About** (with the open-source licences sheet), **Circle and privacy** and **AI and recaps**. Build the **skin switch**: the alert blooming from the Cinematic card, the persist step, Glass's 615 ms **melt**, the restart, the arriving skin's 10 s Undo, and the offline wording. Finally capture the two **skin preview loops** (animated WebP, 360 × 780, under 900 KB, plus stills) for both skins with a harness script. When you finish, the ScreenId `settings` leaves the Glass `PENDING` map; the admin and device sections (Notifications, Security, Members, Storage, Backup, Diagnostics, System status) and the You hub are `web/40`. Cinematic must not change by a single pixel.

## Read first

Read these completely before planning. Where this file and `glass/DESIGN.md` disagree, `glass/DESIGN.md` wins; say so in the report.

1. `docs/redesign/inventory/00-decisions.md` (all: the skin is picked in Settings, the app restarts, everything changes; UI sounds off by default; dark only).
2. `docs/redesign/stack-decision.md` §2.4 (where the skin choice lives: profile, device mirror, return route), §2.5 (how restart works on the web), §2.2, §4 risks 7 and 8.
3. `docs/redesign/glass/DESIGN.md`:
   - "Conventions used everywhere below"; §2.1.2, §2.1.4 (the badge-fill rule), §2.1.6 (moods: the Settings ambient field), §2.4.2 (rule 7, rule 8), §2.7 (icons), §3.2, §3.6 (Legible text), §3.7.
   - §4.2, §4.7, §4.8, §4.10 rows **Skin melt**, **Skin preview**, **Droplet reveal**, Row pulse, Bloom, Push, Pop, Sheet present, Toast fall, Hold fill, Quick type, Letter reveal, Title capsule, Tab droplet; §4.11 (every row: the sources of each setting and what each one forces).
   - §5.2 (`skin.switch` `heavy`, `toggle.on`/`toggle.off`, `select`, `detent.tick`, `detent.magnet`, `hold.ramp`, `hold.done`, `undo`, `delete.confirm`, `gate.confirm`), §5.3 ("Feel it" is absent on the web), §6 (UI sounds: per device, off by default, −24 to 0 dB default −6, the "Hear it" sequence, the `melt` cue, `sheet.open`/`sheet.close`).
   - §7.1 (buttons incl. HoldToConfirm and its visible fallback), §7.6, §7.7 (slabs), §7.10, §7.11 (alerts: bloom from the source, stacked buttons), §7.12 (toasts with Undo and the draining rim), §7.14, §7.17 (grouped lists and row anatomy), §7.21, §7.22, §7.25 (the 18+ gate), §7.26 (orbs), §7.27 (keycaps), §7.28 (the palette's actions).
   - §8.0.3 (the `settings` route and every section slug, including Glass's `ai`; the `?sheet=` rule and the `licenses` and `whats-new` ids), §8.0.6 (the Single-key shortcuts switch), §8.0.8 (`flags.glass_available`, first-paint attributes from `mm.boot.a11y`, the 18+ purge, server capabilities), §8.0.9 (profile switch into a different skin), §8.2 (splash and first paint), §8.5 (the hand-off with the skin-mismatch restart), §8.24 (the list of Settings sections and their order).
   - **§8.25 intro, §8.25.1, §8.25.2, §8.25.3 (the full migration table), §8.25.4, §8.25.5, §8.25.13, §8.25.14, §8.25.15, §8.25.16.** Read every line; they are the contract for this step.
   - §9.1.3 and §9.1.5 (the recap setting's meaning; the AI reasons' long lines), §9.3 (the sharing model and switch table), §9.4.1 (cruise speed range), §9.4.2 (soundscape scenes, mixer defaults, Match the story, `mm.soundscape.defaults`).
   - §12.2 (App icon follows the skin; the PWA manifest and icons are shared and skin-neutral), §12.4 (the Droplet reveal on arrival), **§12.7 (the skin-preview asset brief)**.
   - §14, §15.2 (service worker protocol, document defaults), §15.5 (device keys: `mm.boot.a11y`, `mm.recap`, `mm.glass.prefs`, `mm.soundscape.defaults`, `mm.icon.follow`, `mm.skin.splash.glass`), §15.6 (shared: the recap key, sharing switches, Legible text, the availability flag), §15.7 (desktop budget of 6), §15.10 rows G4, G5, G13 and the owner calls.
4. `docs/redesign/cinematic/DESIGN.md` §8.0.7 (`glass_available` and the pre-flip debug row) and §8.30.3 (the preview route `/skin-preview/{skin}` and its fixture; the switch mechanics shared by both skins).
5. `docs/redesign/inventory/web.md` §6 (SG1–SG40), §18.3 (A17–A24), §19 (K1–K51), §2.9 (the keyboard layer).
6. `docs/redesign/inventory/capabilities.md` §5 (profiles, `PATCH /profiles/{id}`), §6 (settings and the 18+ gate), §23 (version, what's new).
7. `docs/redesign/00-baseline.md`.
8. `docs/redesign/proof/web-02/report.md` (`switchSkin`, `restartInto`, `resolveBootSkin`, `SkinBoot`, the debug page, the SKIN RESTART recorder), `docs/redesign/proof/web-18/report.md` (`runSkinSwitch`, `takeSkinArrival`, `recap-setting.ts`, `features/settings/search.ts`, `series-defaults.ts`, `book-defaults.ts`, `listen-settings.ts`, `ambient-settings.ts`, `setBootA11y`, `useServerVersion`, the preview route and `design/previews/`), `docs/redesign/proof/web-28/report.md` (the §7.25 gate alert), `docs/redesign/proof/web-29/report.md` (Splash, the palette, the `SheetHost`, `purgeMatureLocal`, the audio-session module), `docs/redesign/proof/web-35/report.md` (the Glass reader settings store and its field names, the tap-zone diagram), `docs/redesign/proof/web-36/report.md` (`glass-novel-prefs.ts`), `docs/redesign/proof/web-37/report.md` (listen defaults).
9. Code you build on: `frontend/src/features/skin/`, `frontend/src/features/preferences/` (the boot-a11y writer, `appearance-boot-source.ts`, the mature hooks), `frontend/src/features/settings/search.ts`, `frontend/src/features/recap/recap-setting.ts`, `frontend/src/features/reader/`, `frontend/src/features/novels/`, `frontend/src/features/circle/` (the sharing hooks from `web/22`), `frontend/src/features/library/suggestions.ts` (availability), `frontend/src/features/app/` (`useServerVersion`), `frontend/src/config/web-version.ts`, `frontend/src/lib/keyboard/` (registry, `formatKeyCombo`, the Single-key store), `frontend/src/skins/glass/` (Shell, Splash, `primitives/*`, `copy/ai.ts`, `copy/errors.ts`, `sounds.ts`, `haptics.ts`, `glass/useLightAngle.ts` with `requestDeviceTilt()`), `frontend/src/app/(preview)/skin-preview/[skin]/`, `design/build.mjs`, `design/previews/`, `frontend/scripts/proof.mjs`.

## Preconditions (check before writing the plan)

- `git log --oneline -30` shows the `web/38` commits; the Glass `PENDING` map still lists `settings`.
- `grep -rn "runSkinSwitch\|export async function switchSkin" frontend/src/features/skin` matches; `grep -rn "takeSkinArrival" frontend/src/features/skin` matches; `ls frontend/src/app/\(preview\)/skin-preview/\[skin\]/` lists `layout.tsx` and `page.tsx`; `ls design/previews/demo-feed.json` succeeds. If any is missing, stop and report which step (`web/02`, `web/18`) has not run.
- `grep -n "glassAvailable" frontend/src/skins/contract.generated.ts` shows `false` (Glass is still debug-only; `release/01` flips it).
- `cd frontend && node -e "console.log(require('sharp/package.json').version)"` prints `0.34.5`.
- In `frontend/`: `free -m && npm run test` is green; record the vitest file and case counts (your floor).

## Skills to invoke

1. `superpowers:writing-plans` before any code; plan at `docs/redesign/proof/web-39/plan.md`, one task per scope letter.
2. `superpowers:test-driven-development` for the migration, the skin outbox and boot precedence, the settings index generator, the section registry and search grouping, the direction mapping, the licences builder's pure parts, the capture script's size loop.
3. `superpowers:subagent-driven-development` (or `superpowers:executing-plans` inline). At most 6 implementer subagents, scope-locked, `model: "opus"` passed explicitly, one heavy command at a time, every subagent's work checked against `git status` and `git diff`.
4. `frontend-design:frontend-design`, `impeccable:impeccable` and `taste-skill:taste-skill` for the skin cards, the alert and the melt: switching skin must feel like the glass itself draining away, not a page reload.
5. `superpowers:verification-before-completion` before you claim anything is done.

## Scope: deliver every item below

Tokens only; every animated move through `play(name, …)` with its `MotionName`; every stored value through the stores named below (bind to existing stores; grep before creating one; never create a second store for the same value). Sections cited are `glass/DESIGN.md`.

### A. Shared data layer (skin-neutral unless named, first commits)

1. **The Glass switch path** over `web/18`'s `runSkinSwitch` (itself over `web/02`'s `switchSkin`/`restartInto`), in `features/skin/glass-switch.ts` (+ test with fake timers):
   - **While `FLAGS.glassAvailable` is false** (now: Glass is reachable only through the `mm-skin-debug` override): pass `patch` as a resolved no-op, persist through `restartInto({ cookie: "mm-skin-debug", skin: to, from: "glass", returnPath })`, and `undoable: false`; the profile's `skin` is never written.
   - **When the flag is true** (`release/01`): `PATCH /profiles/{id} { skin }`, `restartInto({ cookie: "mm-skin", … })`, `undoable: true`, and expire any `mm-skin-debug` cookie (`clearSkinCookie`).
   - **Offline with the flag true:** `patch` = `queueSkinPatch(profileId, to)` in the new **`features/skin/skin-outbox.ts`** (+ test): a profile-scoped `mm.skin.outbox` entry `{ skin, queuedAt }`, flushed with `PATCH /profiles/{id}` on `online` and at boot; `SkinBoot`'s resolution treats a pending entry as the profile's skin (`pendingSkin(profileId) ?? profile.skin`) so a boot before the flush never restarts back. If the shared switch refuses offline (web/02 returns `"failed"` when `navigator.onLine` is false), add an option `allowOffline` (default `false`, so Cinematic's disabled-offline edition row is unchanged) and pass `true` from Glass.
   - Leaving Glass removes `sessionStorage['mm.skin.splash.glass']` (`restartInto` removes `splashKey(from)`), so a later arrival plays the Droplet again (§15.10 G5).
   - Tests: the three modes, the outbox flush order, boot precedence with a pending entry, `allowOffline` default false.
2. **The one-time migration** (§8.25.3), `features/preferences/glass-migration.ts` (+ test). The Glass `Shell` runs `migrateForGlass(scope)` once per profile on first Glass launch, as soon as the active profile's storage scope is known and before any reader screen renders; the marker is the profile-scoped `mm.glass.migrated = 1`. Old keys are read, never rewritten or reinterpreted; new values go under new keys or new fields, and only when the new field is absent:
   | Setting | Read (web) | Write | Rule |
   |---|---|---|---|
   | Brightness | K31 `mm.reader-settings.dimmer` 0–0.92 | `brightness` 0.2–1.0 | `1 − dimmer / 0.92 × 0.8`, rounded to 0.01 (0 → 1.00, 0.46 → 0.60, 0.92 → 0.20) |
   | Warmth | K32 `mm.reader-settings.warmth` 0–0.7 | `warmth` 0–1 | `old / 0.7`, rounded to 0.01 |
   | Cruise speed | K39 `mm.reader-preferences[{source}:{series}].autoScrollSpeed` 1–10 | `cruiseSpeed` beside it in the same entry | `round((20 + (v − 1) × 22.2) / 60 / 0.05) × 0.05`, clamped 0.25–4 (1 → 0.35, 5 → 1.80, 10 → 3.65) |
   | Page transition | K33 `mm.reader-settings.pageTransition` | `pageTransition` | `true` → `"fade"`, `false` → `"none"`, absent → `"slide"` (Slide is never produced from the stored boolean) |
   | Library density | K26 | none | kept |
   | Direction, fit, zoom | K35–K38 per series | none | kept |
   | Novel paper | K40 `mm.novel-settings.palette` | `mm.novel-settings.paper` | the §8.15.1 mapping in `web/36`'s `glass-novel-prefs.ts` |
   | Tap zones | K34 | none | read as is (advance = Next, retreat = Previous, toggle = Menu) |
   | Reader background, keep awake | mobile only | none | the web has nothing to migrate |

   The Glass reader fields live in the **Glass reader settings store `web/35` created** (use its module and names; `grep -rn "brightness" frontend/src/features/reader frontend/src/skins/glass`). It must hold, with these defaults (add the missing fields there): `brightness` 1.0, `warmth` 0, `pageTransition` `"slide"`, `colour` `"normal"`, `background` `"black"`, `chapters` `"continuous"`, `autoNext` true, `swipeChapter` false, `tapToScroll` false, `lockControls` false, `keepAwake` false, `cruiseDefault` 1.0 (0.25–4, step 0.05), `guidedDefault` false. Only if no such store exists, create `features/reader/glass-reader-settings.ts` (profile-scoped key `mm.glass.reader`). If `web/35` migrated some rows at read time, fold that logic into this module (one migration, idempotent) and keep its read-time fallbacks for scopes the one-time run has not reached. Tests: every row at its boundary values, a second run writes nothing, the old keys are byte-identical afterwards, per-profile isolation.
3. **The settings index** (§8.25 "generated into both from the same list"). A narrow `design/` exception, like `web/18`'s preview fixture: `design/glass-settings-index.json` holds one entry per row of §8.25.1 to §8.25.16 (every section, including the ones `web/40` renders) as `{ id, label, keywords[], section, platforms: ("web" | "ios" | "android")[], admin }`; a generator step in `design/build.mjs` (Node stdlib, about 40 lines, covered by `--check`) writes `frontend/src/skins/glass/copy/settings-index.ts` and `mobile/lib/skins/glass/copy/settings_index.dart`, each with the `GENERATED by design/build.mjs — do not edit` header. The mobile session (`mobile/39`) needs the same file: run `git log --oneline -- design/glass-settings-index.json design/build.mjs` first; if it already landed, use it and add only missing web rows; otherwise create it. Commit it alone as `design: glass settings index` (stage only those four paths) and push at once. Then run `node design/build.mjs` and `node design/build.mjs --check`, and `node --test design/*.test.mjs` if such self-checks exist.
4. **Boot attributes:** extend `web/18`'s `setBootA11y(patch)` so it writes all five fields of `mm.boot.a11y` (`legible`, `motion`, `solid`, `contrast`, `sr`) and stamps `data-legible="on"`, `data-motion="reduced"`, `data-solid="on"`, `data-contrast="more"`, `data-sr="on"` on `<html>` at once (removing them when off; `data-motion` stays when the OS asks); test.
5. **Glass-only device and profile stores** (grep first; extend what `web/25`–`web/37` created):
   - `mm.glass.prefs` (per profile): `{ lightFollowsDevice, autoPlayPreviews, chartTables }`; `lightFollowsDevice` defaults to `true`, except `false` on iOS Safari (`typeof DeviceOrientationEvent !== "undefined" && typeof DeviceOrientationEvent.requestPermission === "function"`); `useLightAngle` reads it (off pins 135°).
   - `mm.soundscape.defaults` (per profile): `{ scene: "off" | "rain" | "wind" | "ocean" | "hearth" | "stream" | "deep", matchStory: true, mix: { bed: 80, detail: 50, tone: 30 }, volumeDb: -12, lowerUnderNarration: true }`, default scene `"off"`; `web/44` reads it. If no module exists, create `skins/glass/prefs/soundscape-defaults.ts` (+ test).
   - UI sounds are **per device** in Glass (§6, §8.25.5): plain `localStorage['mm.glass.sounds']` = `{ on: false, volumeDb: -6 }` (range −24 to 0). Change `skins/glass/sounds.ts` (from `web/02`) to read this key instead of a per-profile one; Cinematic's store is unchanged. Haptics stay the shared per-device `localStorage['mm.haptics']`.

### B. Settings structure (§8.25 intro)

1. **Registry** `screens/settings/registry.ts`: ordered sections `{ slug, title, icon, tone, order, visible(ctx), rows }`. This step registers: Account (`profile`, 10), Appearance and skin (`appearance`, 20), Reader (`reading-manga`, 30; its groups Novels, Listen and Ambient answer the slugs `reading-novels`, `listen`, `ambient` by scrolling to the group and flashing its header), Content (`content`, 40), Circle and privacy (`circle`, 50), AI and recaps (`ai`, 60), Sound and haptics (`feedback`, 70), Shortcuts (`keyboard`, 130), About (`about`, 140). `web/40` inserts Notifications (80), Security (90), Storage (100), Backup (110), Administration (115), Diagnostics (120) into the same array. A slug the registry does not know yet renders the Settings root on phones and the first section on desktop. `/settings/diagnostics` stays `web/02`'s debug page, untouched.
2. **Row anatomy** (§7.17): grouped `surface1` containers, radius 20, 16 px from the screen edges; rows 52 tall (64 with a subtitle), hairlines inset to the text; section headers in `footnote` 13/600 uppercase +0.04 em `label2`; footers in `footnote` `label3`. **Icon tiles** 30 × 30, radius 12, glyph 18. Semantic sections use the §2.1.4 badge-fill rule (the colour at 18 % over `surface1`, the glyph in the colour, so every glyph clears 3:1; §7.17's white-on-colour would fail on the pale tones): Appearance and skin `drop-half` in `iris400`, Reader `book-open` in `info`, Content `age-gate` in `mature`, Circle and privacy `users-three` in `bloom`, AI and recaps `sparkle` in `machine`. Neutral sections use `surface3` with the glyph in `label1`: Sound and haptics `speaker-high`, Shortcuts `keyboard`, About `info`. Account shows the profile orb (§7.26) at 30 px instead of a tile.
3. **Phones and tablets (below 1024 px):** `/settings` is a pushed page "Settings" (large title with the letter reveal once per session; the title capsule when it scrolls away) with a search well ("Search settings", 44 px) and one grouped list of the sections, each row opening its section as a pushed page (`Push` on `page`, 615 ms; each section's large title reveals once per session). The search well opens a full-screen overlay (a history entry: `?sheet=settings-search` if `SHEET_IDS` has it, the id Cinematic uses; otherwise a plain `history.pushState({ mmOverlay: "settings-search" })`, so back closes it) listing matches from `matchSettings()` (`features/settings/search.ts`) over the generated index, grouped by section, with rows hidden on the web, for non-admins, or by server capabilities left out; a result opens its section and flashes the row with **Row pulse** (`iris600` at 14 % fading over 900 ms). Empty: "No settings match “{q}”".
4. **Desktop (≥ 1024 px):** a 240 px section list at left inside the content column (not the sidebar), the section panel at right (max 720 wide). A 36 px `fill3` search capsule "Search settings" heads the list; typing replaces the list in place with the matching rows grouped by section ("No settings match “{q}”" when empty); Enter or a click opens that section at right, scrolls to the row and flashes it; Esc clears the field and restores the list; `/` focuses it. The active section row carries the `glassFilm` clear droplet that travels on `tab`. **Quick links** under the list: Reading history (→ `ROUTES.history()`), System status for admins (→ `ROUTES.status()`). `/settings` renders the first visible section in the panel (no redirect).
5. **Footnote** (end of the list on phones, under the section list on desktop): "Settings save as you change them. Switching skin restarts the app."
6. **No profile:** profile-scoped sections show the notice "Choose a profile first" with a link to `ROUTES.profiles()` and disabled controls. **Server-backed sections** (Content, Circle and privacy, the AI status and the Clear action) show row skeletons while loading, an inline error block with Try again when a load fails, and offline the notice "These settings need a connection" with their controls disabled; device settings (haptics, UI sounds, shortcuts, the appearance switches) always work. Sections the server does not offer (`GET /settings` capabilities) are hidden.
7. **Keys:** `/` searches settings; `↑` / `↓` move between sections in the list; Enter opens a section; Esc returns to the section list (after closing an open overlay first). `document.title` = "Settings · ManhwaManiacs" or "{Section} · Settings · ManhwaManiacs"; route focus lands on the `h1`.
8. The Settings ambient field is the profile's mood colour at its own opacity (§2.1.6, §2.1.8).

### C. Appearance and skin (§8.25.1)

1. **Skin cards:** two large preview cards side by side on desktop (each half the panel), stacked on phones: a `surface1` slab (radius 26, padding 12) holding the skin's looping animated WebP (`/skin-preview/loops/skin-glass.webp` and `skin-cinematic.webp`, 360 × 780, shown at the card's width, radius 14, `width`/`height` attributes set so nothing shifts), the name in `title2` ("Glass", "Cinematic"), the one-line character in `footnote` `label2` ("Liquid glass, springs and depth." / "Dark cinema, posters and title cards."), and a "Current" tag on the Glass card (`aria-current="true"`, not activatable). Under reduced motion each card shows its still (`skin-{id}-still.png`) with a plain "Play preview" button that swaps in the WebP for 6,000 ms and then back. Solid glass does not affect them. The Cinematic card is one button ("Cinematic. Dark cinema, posters and title cards. Restart in Cinematic"); it sinks to 0.97 on press and starts D.
2. **Solid glass** switch (per profile, `solid`; forces the Reduce Transparency look at once through `data-solid="on"`).
3. **Increase contrast** switch (per profile, `contrast`; OR-ed with `prefers-contrast: more`; `data-contrast="more"`).
4. **Legible text** switch (per profile, `legible`; `data-legible="on"`), with the preview sentence "Read the next chapter" shown in both faces (Google Sans Flex and Atkinson Hyperlegible Next) under the row.
5. **Reduce motion in this app** switch (per profile, `motion`; `data-motion="reduced"` regardless of the OS).
6. **Screen reader mode** (web only) switch (per profile, `sr`; `data-sr="on"`), caption "Keeps toasts until you close them, keeps reader controls visible, stops Wrapped from advancing and voice previews from playing on their own."
7. **Light follows the device** switch (`mm.glass.prefs.lightFollowsDevice`). On iOS Safari it is off by default; turning it on calls `requestDeviceTilt()` (`web/25`) from that tap, with the caption "Allow motion so the glass follows your phone"; a refusal flips it back with the caption "Motion access was declined. You can allow it in Safari's settings for this site." Off freezes the light at 135° (and the player's artwork parallax and the hero tilt).
8. **App icon follows the skin** is an app-only row (phones, default off, per device `mm.icon.follow`, through `flutter_dynamic_icon_plus` 1.4.1 in `mobile/39`); the web renders nothing for it and never writes `mm.icon.follow`, because the PWA manifest and its icons are shared and skin-neutral and the favicon already follows the server-rendered skin (§12.2).
9. **Palette actions** (registered with `web/29`'s command palette, group "Settings"): "Skin: Cinematic" (opens the D1 alert from the centre) and "Legible text: on" / "Legible text: off" (§3.6).

### D. The skin switch and restart (§8.25.2)

1. **Choose:** choosing the Cinematic card (or the palette action) opens `web/27`'s alert blooming from the card on `morph` (scale 0.9 from the card; from the centre 0.94 → 1 when opened from the palette), `glassThick`, width 300 on phones and 420 on desktop, radius 26, padding 20, over `dimModal` (`rgba(0,0,0,0.48)`, 180 ms): the Cinematic preview small at the top (72 × 156, radius 12; the still under reduced motion), title "Restart in Cinematic?" (`title3`), body "Everything about the app changes: layout, navigation, type and motion. Your library, progress and downloads stay exactly as they are, and you'll come back to this screen." (`callout` `onGlass`); when downloads are queued or running (`features/offline` queue not empty) an inline notice "Downloads pause for a moment and resume after the restart."; when offline with the flag true, the line "This profile will switch on your other devices once you're back online." Buttons stacked full width (L 50; long labels): **"Stay in Glass"** (secondary, first, initial focus) and **"Restart in Cinematic"** (the alert's tinted twin). No hold: nothing is lost and the Undo exists. Esc cancels; focus is trapped and returns to the card.
2. **Persist:** `skin.switch` (`heavy`; no web vibration), the `melt` cue when UI sounds are on (descending glide A6 → A5, 420 ms, −18 dBFS), then A1's path.
3. **The melt** (`skins/glass/overlays/SkinMelt.tsx`, passed as `outgoing`; 615 ms, the three parts together, the `page` settle ends it):
   - every live glass surface **dematerialises** at once: `html[data-glass-melt]` makes every `GlassSurface` ramp its displacement scale to 0 and its opacity to 0 over `dematerialize` (350 ms `cubic-bezier(0.2, 0, 0, 1)`);
   - the app root's content blurs `filter: blur(0 → 40px)` on `smooth` (k 157.9, c 22.62, settle 436 ms);
   - a single droplet contracts: `clip-path: circle(R at 50% 50%)` on the app root with `R` from half the viewport diagonal to 0 on `page` (k 146.0, c 24.17, settle 615 ms), a 1 px `rgba(255,255,255,0.22)` ring riding the circle's edge, leaving `#000000`;
   - logged by `play()` as "Skin melt" in the motion-timings overlay; the SKIN RESTART entry stays `web/02`'s.
   - **Reduce motion:** a 200 ms linear fade to black.
   - **`reverse()`** (a failed switch with the flag true): the circle reopens on `page`, the blur returns to 0 on `smooth`, the surfaces materialise (250 ms), then the toast with the §8.0.10 copy for the failure ("Couldn't reach the server." for a network error, "Something went wrong. Try again." otherwise; `error` haptic).
4. **Restart:** `location.replace(returnPath)` through `restartInto` (`sessionStorage['mm.skin.return']` = the current path and search; `{ type: "skin-changed", skin }` posted to the service worker). Budget: under 1,500 ms from the confirm tap to the new skin's first splash frame (SKIN RESTART).
5. **Arriving into Glass** (from Cinematic): `web/29`'s Splash plays the full Droplet reveal (§12.4: 1,200 ms; 200 ms cross-fade under reduced motion), lands on the return route, and then the Glass Shell calls `takeSkinArrival()`; when it returns `"cinematic"`, the toast "Switched to Glass" + "Undo" shows for 10 s with the draining rim (§7.12; kept until dismissed with Screen reader mode on). Undo runs the switch back to Cinematic with the melt and no alert, `undoable: false`, `undo` haptic. Before the flag flips the debug path never writes the arrival marker, so no toast appears there; test the toast by setting `sessionStorage['mm.skin.from'] = "cinematic"` before load.
6. **Profile switch into a profile with a different skin:** the hand-off of §8.5 (`web/30`) runs steps 2 to 5 with no alert and no Undo; verify it still works after this step (no change expected).
7. Cinematic's own arrival toast ("Now in the Cinematic edition." with Undo) is `web/18`'s and appears after a flag-true switch from Glass; nothing in Cinematic changes here.

### E. Reader defaults (§8.25.3), `/settings/reading-manga`

Each row states its scope in `caption1` ("All series", "This device"). Rows edit the same stores the readers use (A2 and `web/18`, `web/36`, `web/37`), so changing a default here changes a series with no value of its own the next time the reader opens.

1. **Manga:**
   - **Direction** segmented Left to right · Right to left · Vertical over `mm.reader-defaults` (`series-defaults.ts`): Vertical ↔ `layout: "strip"` (a stored `guided` also reads as Vertical); Left to right / Right to left set `direction` and set `layout: "single"` only when the current layout is `strip` or `guided` (a stored `double` is kept). `direction-map.ts` + test.
   - **Brightness default** slider 20–100 % (step 1, `detent.tick` every 10 %, the value in `mono` "80 %") → `brightness` 0.2–1.0.
   - **Warmth default** slider 0–100 % → `warmth` 0–1.
   - **Fit** segmented Width · Height · Original → `mm.reader-defaults.fit`.
   - **Tap zones:** `web/35`'s diagram (a phone silhouette with three bands; tap a band to cycle Previous · Menu · Next) with "Reset to automatic", writing K34 `mm.reader-settings.tapZones` (`null` = automatic).
   - **Chapters** segmented Continuous · One at a time → `chapters`.
   - **Page gap** switch → K29; **Cinema mode by default** switch → K30.
   - **Keep screen awake** switch (rendered on coarse pointers with `"wakeLock" in navigator`) → `keepAwake`.
   - **Auto next chapter** switch → `autoNext`; **Lock reader controls** switch with the caption "Tap the centre 5 times to unlock" → `lockControls`.
   - Volume keys and Refresh rate are Android-app rows and are not rendered on the web.
   - **Reset reader settings:** `web/26`'s `HoldToConfirm` ("Hold to reset", 1,200 ms: the fill starts at 200 ms and rises over 1,000 ms with `hold.ramp`, `hold.done` on completion; a click opens the confirm alert "Reset every reader setting?" with a "Reset" confirm): restores the Glass reader store fields and `mm.reader-defaults` to their defaults, K29 and K30 to `false` and K34 to `null`; toast "Reader settings reset".
2. **Novels** (`reading-novels`): default face (three tiles, each in its own face: Literata, Sans, Atkinson), size stepper 15–30, line height 1.40–2.10, measure 48–88 ch, paper (seven 44 px orbs as a radio group with the selected ring), mode Scroll · Paged, page turn Slide · Lift · Fade, through `web/36`'s `glass-novel-prefs.ts` (`mm.novel-defaults` and `mm.novel-settings`); caption "For books that have no settings of their own." Literata and Atkinson load on this page only while the Novels group is on screen.
3. **Listen** (`listen`): default speed (a slider 0.5–3.0× in 0.05 steps with `detent.tick` every 0.25 and the 1.0 magnet, value "1.25×") → `mm.listen-settings.speed`; "Continue to the next chapter" switch → `autoPlayNext`; sleep timer default (a menu: Off · 5 · 10 · 15 · 30 · 45 · 60 min · End of chapter · End of next chapter) → `sleepDefault`. "Shake to extend" is app-only and is not rendered.
4. **Ambient** (`ambient`): Page-tinted chrome switch → `mm.ambient-settings.pageTint`; Cruise default speed (a slider 0.25–4× on a logarithmic track, steps of 0.05, the 1.0 magnet) → `cruiseDefault`; "Guided view on by default for chapters with panels" switch → `guidedDefault`; a row "Soundscape defaults" → `/settings/feedback`, scrolled to its soundscape group.

### F. Content (§8.25.4), `/settings/content`

The 18+ switch through the shared `useContentPreferences` / `useSetMatureContent` / `useMatureToggleBlockReason` hooks: turning it on opens `web/28`'s §7.25 gate alert exactly as built there (hold-to-confirm 1,200 ms with the always-visible explicit confirm button; `gate.confirm`); turning it off applies at once and runs `purgeMatureLocal()` (`web/29`); the blocked state without a profile shows the "Choose a profile first" notice and disables the switch with the hook's reason.

### G. Sound and haptics (§8.25.5), `/settings/feedback`

1. **Haptics** switch (per device `localStorage['mm.haptics']`, default on), rendered only when `"vibrate" in navigator` and `(pointer: coarse)` (Android Chrome); the web has no "Feel it" row (§5.3).
2. **UI sounds** switch (per device, default **off**, A5) with a volume slider −24 to 0 dB (step 1, default −6, value "−6 dB" in `mono`) and a **"Hear it"** row that plays `tap`, `push-1`, `push-2`, `push-3`, `push-4`, `back`, `add`, 400 ms apart; disabled with the caption "Turn UI sounds on to hear them." while sounds are off.
3. **Soundscape defaults** (per profile, `mm.soundscape.defaults`): the scene as a grouped radio list (Off · Rain · Wind · Ocean · Hearth · Stream · Deep, a trailing check on the chosen row), "Match the story" switch (default on), the mixer sliders Bed · Detail · Tone (0–100 %, defaults 80 / 50 / 30, `detent.tick` every 10 %), the volume slider −30 to 0 dB (default −12), and "Lower under narration" switch (default on); caption "Saved on this device." The soundscape engine and its previews arrive with `web/44`.

### H. Shortcuts (§8.25.13), `/settings/keyboard`

The registry from `lib/keyboard` grouped General, Navigation, Library, Search, Sources, Reader, Novel reader, Listen: each row the description and its keycaps (`web/26`'s `Keycap` through `formatKeyCombo`: "⌘K" on macOS, "Ctrl K" elsewhere). List every declared group, not only the mounted ones: if the registry only knows mounted groups, collect the Glass groups' declarations from each screen's `keys.ts` into `screens/settings/shortcut-groups.ts`. The **Single-key shortcuts** switch (default on; the shared store the keyboard layer reads) sits at the top; "No shortcuts are active on this screen" when a group list is empty.

### I. Account, language and about (§8.25.14), `/settings/profile` and `/settings/about`

1. **Account:** the orb (56 px, §7.26), display name, "@username", the "Administrator" tag for admins; rows "Password and security" (→ `/settings/security`, built by `web/40`), "Profiles" (→ `ROUTES.profilesManage()`); "Sign out" (destructive plain) → alert "Sign out? You'll need to sign in again on this device." with "Keep me signed in" and the destructive "Sign out" (`delete.confirm`), then `useLogout` and `/login`. **App language** is not shown (the stored mobile K14 stays untouched).
2. **About:** the app card (`surface1`, radius 26: the `mm-mark` at 48, "ManhwaManiacs", "A self-hosted manga, manhwa and web-novel reader", "Web {WEB_VERSION} · Server {version} ({build})" from `useServerVersion()`); the update row for the web's service worker ("Up to date", or "A new version is ready" + "Reload", which posts `skip-waiting` and reloads through `applyWorkerUpdate`); "What's new" (→ `?sheet=whats-new`, `web/29`'s sheet); **Open-source licences** (→ `?sheet=licenses`); "Reset reader settings" (the E1 hold). An external link that fails to open shows the toast "Couldn't open {site}".
3. **Open-source licences sheet** (`?sheet=licenses` on `/settings/about`; a `large` sheet on phones, a 560 px window on desktop): a search well "Search packages"; rows 52 tall grouped **Fonts**, **Web packages**, **Artwork and sounds** (the Flutter app's packages are listed only in the app): the package name in `mono` 13 `label1` (`onGlass` in the desktop window), its version in `caption1` `label3` (`onGlass` in the window), and a licence tag capsule (MIT, BSD-3-Clause, Apache-2.0, ISC, MPL-2.0, OFL-1.1, CC0-1.0); a tap pushes the licence text inside the sheet in `mono` 13/20 `label2` (`onGlass` in the window) with the package name as the title and "Copy" in the header. States: loading (8 row skeletons), no match "No package matches “{q}”", error "Couldn't load the licences" + Try again. Keys: `/` search, arrows, Enter opens, Esc back.
4. **The data:** `frontend/scripts/build-licenses.mjs` (Node 22 stdlib; `npm run licenses`) writes `frontend/public/licenses.json`, fetched only when the sheet opens: every direct dependency in `frontend/package.json` `dependencies` with its installed version (`npm ls --json --omit=dev --depth=0`), its `license` field and the text of its `LICENSE*` file from `node_modules` (truncated at 64 KB); the fonts (Google Sans Flex, Google Sans Code, Literata, Atkinson Hyperlegible Next, Noto Sans KR, Noto Sans JP, Noto Sans SC) with the `OFL.txt` of each, fetched once from `https://raw.githubusercontent.com/google/fonts/main/ofl/<family>/OFL.txt` (`googlesansflex`, `googlesanscode`, `literata`, `atkinsonhyperlegiblenext`, `notosanskr`, `notosansjp`, `notosanssc`; if a path 404s, find the folder in the `google/fonts` `ofl/` listing) and committed under `frontend/scripts/licenses/fonts/<family>.txt`; artwork and sounds from `backend/media/soundscapes/SOURCES.md` (the `glass-*` rows: file, URL, licence), the onboarding art-style licence record under `brand/onboarding/styles/`, and one entry "Demo covers: procedural art made for ManhwaManiacs" (entries whose source file does not exist yet are skipped and printed). Pure parts (the grouping, the truncation, the SOURCES.md row parser) in `licenses-lib.mjs` with a `node --test` file. Keep `licenses.json` under 1.5 MB.

### J. Circle and privacy (§8.25.15), `/settings/circle`

Rows from `GET /profiles/{id}/sharing` through the shared hook from `web/22` (grep `/sharing` in `frontend/src/features`); each change writes a partial `PATCH /profiles/{id}/sharing` body, optimistic with rollback and an inline error line:

- **Share what I'm reading** (`activity`, the master, default off): "Other readers on this server see what this profile starts and finishes. Never your bookmarks, searches, reading time or downloads."
- **Show my reactions** (`reactions`, default on once sharing is on); **Accept recommendations** (`recommendations`, default on): "Friends can send you series. Off: you won't appear in their Recommend list."; **Show me in presence** (`show_presence`, default off): "Your orb moves to the front of the Circle while you're reading."; **Let others add me to shared shelves** (`shelves`, default on); **Share my streak** (`share_streak`, default off); **Include 18+ titles in my activity** (`include_mature`, rendered only while this profile's gate is open, default off): "Even when on, 18+ titles are shown only to readers whose own 18+ setting is on." While the master is off, the rows under it are disabled (40 %) with the reason "Share what I'm reading is off" in their tooltip and `aria-describedby`.
- **Hidden from my Circle** (`excluded_series`): rows with a 36 × 54 cover, the title and "Unhide"; empty "Nothing hidden. Hide a series from its ⋯ menu."
- **Clear my activity:** destructive plain → alert "Remove everything you've shared so far? Your reading stays; your Circle just won't see past activity." with "Keep it" and the destructive "Clear" (`DELETE /circle/activity`; toast "Your shared activity was cleared").
- **Preview line** (`footnote` `label2`), shown while the master is on and typed once at 12 ms per character (Quick type) each time a switch changes: "Others see: {profile name} finished chapter {n} of {title}." from the profile's latest history row.
- States: loading (6 row skeletons), error + Try again, offline ("Sharing settings need a connection"; switches disabled), no profile. `web/43` reuses this section and adds nothing to it.

### K. AI and recaps (§8.25.16), `/settings/ai`

- **Previously on:** a segmented control Off · Ask · Always (default Ask) over `web/18`'s `recap-setting.ts` (`useRecapSetting`, `setRecapMode`; the one `mm.recap` key both skins read) with the explainer "Ask: when you come back to a series after a week, we offer a quick recap. Always: the recap opens first. Chapter recaps are offered after 3 days away." and the caption "Saved on this device."
- **Series you asked not to recap:** the `skipSeries` entries as rows (cover and title from the library cache; unknown series show "{sourceId} · {seriesKey}" in `mono`) with "Ask again" (removes the entry); empty "You haven't turned recaps off for any series."
- **Clear "Not interested":** a plain button with the caption "Series you dismissed from AI picks can appear again." → `POST /ai/feedback {signal: "clear"}`; toast "Your AI picks start fresh".
- **AI status line:** from `GET /library/suggest/availability`: "AI picks are on · 7 of 10 asks left today", or the reason's long line from `copy/ai.ts` (§9.1.5), with the `sparkle` (or `sparkle-slash` in `label2`) glyph.

### L. The skin preview loops (§12.7, §4.10 "Skin preview")

1. **Preview route readiness:** `/skin-preview/glass` must render Glass Home (`web/31`) from the fixture with **zero** `/api/*` requests. Add to `app/(preview)/skin-preview/[skin]/layout.tsx`, for `skin === "glass"`, the providers Glass needs (`LensDefs`, `GlassMotionConfig`, `AmbientProvider` + `AmbientField`; a route file may import both skins). If the Glass Home issues a request the fixture does not answer, add that query's result to `design/previews/demo-feed.json` (the same narrow `design/` exception as `web/18`), then `node design/build.mjs` and `--check`.
2. **`?capture=1`** on the preview page turns off its self-scroll and stamps `html[data-capture]`, so the script owns the scroll position.
3. **`frontend/scripts/capture-skin-previews.mjs`** (`npm run capture:skin-previews`; `--base` defaults to `http://127.0.0.1:3010`): Playwright headless Chromium, viewport 360 × 780, `deviceScaleFactor: 1`, `reducedMotion: "no-preference"`. For each of `glass` and `cinematic`: open `/skin-preview/{skin}?capture=1`, wait for `networkidle` plus 3,000 ms (reveals and typing finish), then capture 60 frames 100 ms apart: for frame `i`, `t = i × 100`, set `document.scrollingElement.scrollTop = 150 × (1 − cos(2π t / 6000))` (down 300 px and back, a seamless 6 s loop), wait two animation frames, take a PNG screenshot buffer. Encode with `sharp(frames, { join: { animated: true } }).webp({ quality, effort: 6, loop: 0, delay: frames.map(() => 100) })`, starting at quality 75 and stepping down by 5 until the file is at most 921,600 bytes (900 KB), floor 40; if it is still larger at 40, recapture at 6 fps (36 frames, 167 ms) and repeat. Frame 0 becomes the still (`sharp(frames[0]).png({ compressionLevel: 9 })`). Output: `frontend/public/skin-preview/loops/skin-glass.webp`, `skin-cinematic.webp`, `skin-glass-still.png`, `skin-cinematic-still.png`; the script prints each file's size, frame count and quality. The size loop is a pure function in the script with a `node --test` case (fake encoder).
4. Record `sharp` in `frontend/package.json` `devDependencies` pinned exactly: `free -m && npm install --save-dev --save-exact sharp@0.34.5` (it is already in `node_modules` through Next, so this only records it).
5. Glass onboarding step 2 (`web/30`) reads the same files; check whether it shows them now and say so in the report.

### M. Cross-cutting

- **Reduced motion:** section pushes and pops are 200 ms cross-fades; Row pulse shows 900 ms then disappears without a fade; alerts and sheets fade (150 ms, 16 px translate for sheets); the droplet on the section list jumps; the melt is a 200 ms fade to black; skin cards show stills; letter reveals show at once.
- **Keyboard and focus:** every control reachable by Tab with the two-tone focus ring (2 px black inner, 2 px `iris300`, 6 px glow; 3 px under Increase Contrast); switches are Base UI switches named by their row; segmented controls are radio groups; sliders carry `aria-valuetext` ("80 percent", "minus 6 decibels", "1.25 times").
- **Hit targets:** 44 × 44 CSS px on every control at every width.
- **Haptics and sounds:** `toggle.on` / `toggle.off`, `select`, `detent.tick`, `detent.magnet`; UI cues per the device setting.
- **Budget (§15.7):** desktop at most 6 live glass elements (sidebar, toolbar group, toast, the "Unsaved changes" slot, window or panel, menu); the section panel's content is never glass.

## Out of scope here (owned by later steps; do not build)

- `web/40`: §8.24 You and About on the You hub (it reuses this step's About rows and licences sheet), §8.25.6 Notifications, §8.25.7 Security, §8.25.8 Members, §8.25.9 Storage, §8.25.10 Backup, §8.25.12 Diagnostics, §8.26 System status. `web/43` reuses J. `web/44` builds the soundscape engine and its previews.
- `release/01`: flipping `flags.glass_available`, deleting the debug row and the `mm-skin-debug` path.
- Mobile icon rules and the Flutter preview frames (`mobile/39`).
- Any change to `mobile/` or `backend/` other than the generated `settings_index.dart` of A3; any change to the Cinematic skin.

## File layout

```
design/glass-settings-index.json, design/build.mjs (generator step)          A3 (narrow design/ exception)
frontend/src/skins/glass/copy/settings-index.ts                               generated
mobile/lib/skins/glass/copy/settings_index.dart                               generated (same design commit)
design/previews/demo-feed.json                                                L1 (only if the Glass Home needs more queries)
frontend/src/features/skin/glass-switch.ts, skin-outbox.ts (+ tests)          A1
frontend/src/features/skin/<switch and boot modules from web/02 and web/18>  allowOffline option, pending-skin precedence
frontend/src/features/preferences/glass-migration.ts (+ test)                 A2
frontend/src/features/reader/glass-reader-settings.ts (+ test)                A2 (only if web/35 created no store)
frontend/src/features/preferences/<boot a11y writer>                          A4
frontend/src/skins/glass/prefs/soundscape-defaults.ts (+ test)                A5 (only if missing)
frontend/src/skins/glass/sounds.ts                                            A5 (device key)
frontend/src/skins/glass/screens/settings.tsx                                 ScreenId settings
frontend/src/skins/glass/screens/settings/
  SettingsScreen.tsx, registry.ts, SectionList.tsx, SettingsSearch.tsx, SectionPanel.tsx, SettingsRow.tsx,
  shortcut-groups.ts, direction-map.ts (+ test), keys.ts (+ test)                                              B, E, H
  sections/Account.tsx, Appearance.tsx, ReaderDefaults.tsx, Content.tsx, CirclePrivacy.tsx, AiRecaps.tsx,
  SoundHaptics.tsx, Shortcuts.tsx, About.tsx                                                                  C, E–K
  skin/SkinCards.tsx, SkinCard.tsx, SwitchAlert.tsx                                                           C1, D1
  LicencesSheet.tsx                                                                                           I3
frontend/src/skins/glass/overlays/SkinMelt.tsx                                D3
frontend/src/skins/glass/Shell.tsx                                            migration call, arrival toast
frontend/src/skins/glass/glass.css                                            html[data-glass-melt] rules
frontend/src/app/(preview)/skin-preview/[skin]/layout.tsx, page.tsx           L1, L2
frontend/scripts/capture-skin-previews.mjs, build-licenses.mjs, licenses-lib.mjs (+ tests), licenses/fonts/*.txt   L3, I4
frontend/public/skin-preview/loops/skin-{glass,cinematic}.webp, skin-{glass,cinematic}-still.png                    L3
frontend/public/licenses.json                                                 I4
frontend/package.json                                                         scripts licenses, capture:skin-previews; sharp devDependency
frontend/src/skins/glass/index.ts                                             settings removed from PENDING
frontend/e2e/glass-settings.spec.ts
docs/redesign/proof/web-39/                                                   plan.md, routes.txt, screenshots, report.md
```

Skin files import only `@/features/**` (never `@/features/*/components/**`), `@/lib/**`, `@/services/**`, `@/stores/**`, `@/types/**`, `@/config/**`, the generated contract and `skins/glass/**`; the lint rule bans `@/skins/cinematic/**`. The thin settings route file stays thin.

## Acceptance criteria

- [ ] `settings` is gone from the Glass `PENDING` map; the completeness test passes.
- [ ] Vitest: `glass-switch` (three modes), `skin-outbox` (queue, flush, boot precedence), `glass-migration` (every row, boundaries, idempotence, old keys untouched, isolation), `direction-map`, `setBootA11y` (five fields and attributes), the settings search grouping, `keys`; `node --test` for the licences library and the capture size loop; `node design/build.mjs --check` passes with the settings index.
- [ ] Phones: the Settings list with icon tiles (badge-fill tones), pushed sections, the full-screen search whose result flashes the row, the footnote; desktop: the 240 px list with the travelling droplet, the section panel, the in-place search, quick links; unknown slugs fall back as specified; `/settings/diagnostics?debug=1` is still `web/02`'s page.
- [ ] Appearance: both cards play their loops (stills + "Play preview" under reduced motion), "Current" on Glass; Solid glass, Increase contrast, Legible text (with the two-face preview), Reduce motion and Screen reader mode switch `data-solid`, `data-contrast`, `data-legible`, `data-motion`, `data-sr` at once and survive a reload before first paint; Light follows the device pins the light at 135° when off and asks for permission on iOS Safari; no App-icon row on the web.
- [ ] The switch: the alert blooms from the card with the preview, the copy, the downloads notice, initial focus on "Stay in Glass"; the melt plays for 615 ms (dematerialise 350 ms, blur to 40 px on `smooth`, the circle closing on `page` with its rim) or a 200 ms fade under reduced motion; the restart lands in Cinematic on the same path; SKIN RESTART is under 1,500 ms in the motion-timings overlay; with the flag false the switch writes only `mm-skin-debug` and never PATCHes the profile.
- [ ] Arriving into Glass: the Droplet reveal plays, then "Switched to Glass" with Undo for 10 s (with `mm.skin.from = "cinematic"` set before load); Undo melts back to Cinematic without the alert and shows no second Undo.
- [ ] Flag-true behaviour, exercised by unit tests: PATCH then `mm-skin`, `undoable`, the debug cookie cleared; offline queues the PATCH, shows the offline line, and a boot before the flush does not restart back.
- [ ] Reader defaults: every row of E with its range, default and scope; editing a default changes a series without its own value when a Glass reader opens (Playwright check on the novel size and the manga fit); the hold-to-confirm reset with its click fallback and toast.
- [ ] The migration runs once per profile on the first Glass launch (marker set) and a profile with K31 = 0.46, K32 = 0.35, K39 = 5 and K40 = `sepia` opens the Glass readers at brightness 60 %, warmth 50 %, cruise 1.80× and Night Paper, with the old keys unchanged.
- [ ] Content: turning 18+ on goes through the §7.25 hold alert with its visible confirm button; off purges at once; the no-profile state disables it.
- [ ] Sound and haptics: haptics row only on coarse pointers with `vibrate`; UI sounds per device, default off, −24 to 0 dB, "Hear it" plays the seven cues 400 ms apart and is disabled while off; soundscape defaults write `mm.soundscape.defaults` with the stated defaults.
- [ ] Shortcuts: every group with keycaps via `formatKeyCombo` and the Single-key switch.
- [ ] Account and About: the account block and Sign out alert; the app card with both versions; the service-worker update row; What's new; the licences sheet with its three groups, search, the pushed licence text with Copy, every state; `licenses.json` holds every direct dependency, the seven font OFL texts and the art and sound rows found.
- [ ] Circle and privacy: every switch with its copy and field, the master disabling the rows under it, Hidden from my Circle with Unhide, Clear my activity with its alert and toast, the typed preview line, every state.
- [ ] AI and recaps: Off · Ask · Always over `mm.recap` (Cinematic reads the same value), the skip list with Ask again, Clear "Not interested" with its toast, the status line or reason.
- [ ] Skin preview loops: both WebPs are 360 × 780, loop forever, last 6 s (60 frames at 100 ms or 36 at 167 ms), are at most 921,600 bytes, and both stills exist; `/skin-preview/glass` makes zero `/api/*` requests.
- [ ] Keyboard: every key of B7 works; every control reachable with the focus ring; route focus on the `h1`; titles as specified.
- [ ] Hit targets: every interactive element at least 44 × 44 CSS px at 390 × 844 and 1440 × 900 (Playwright walk of every section).
- [ ] Reduced motion per M; Solid glass and Increase contrast snapshots of Appearance and the alert.
- [ ] Per-skin difference: with `mm-skin-debug=cinematic`, Cinematic Settings, its edition picker and Stop the press are unchanged (screenshots before and after) and its tests pass; nothing under `frontend/src/skins/cinematic/**` changed.
- [ ] `npm run typecheck`, `npm run lint` (0 errors, 0 warnings), `npm run test` (at or above the floor plus the new tests) and `npm run build` (0 errors, 0 warnings) are green.

## Verification

**RAM guard (production shares this box).** Before every heavy command (build, the vitest suite, `next dev`, a Playwright run, the capture script, `npm install`) run `free -m`; if the `available` figure of the `Mem:` row is under 1024 MB, stop and report. Never run two builds at once, and never run `next build` while `next dev` or a Playwright browser is running.

From the repository root, then `frontend/`:

```bash
free -m && node design/build.mjs --check
ls design/*.test.mjs 2>/dev/null && node --test design/*.test.mjs
cd frontend
free -m && npm run typecheck
free -m && npm run lint
free -m && npm run test
free -m && node --test scripts/*.test.mjs
free -m && npm run build
```

Lint and build stay at 0 errors and 0 warnings (`00-baseline.md`). This step's only file outside `frontend/` and `design/` is the generated `mobile/lib/skins/glass/copy/settings_index.dart`; it is a data file, so run `/srv/manhwamaniacs/dev/flutter/bin/flutter analyze lib/skins/glass/copy/settings_index.dart` from `mobile/` (after `free -m`) to prove it compiles, and confirm `git diff --stat origin/feat/vps-slim-source-native -- backend` is empty, so the full `flutter test` suite and the backend pytest (`backend/.venv/bin/python -m pytest -q --no-header`) are not rerun here (`mobile/39` runs the Flutter suite).

**Skin preview capture.** Start the dev stack from `backend/scripts/README-dev-stack.md` (127.0.0.1:8010, dev SQLite only) and `free -m && npm run dev -- -p 3010`, then `free -m && npm run capture:skin-previews` and record the printed sizes.

**Visual proof.** Write `docs/redesign/proof/web-39/routes.txt`:

```
/settings
/settings/profile
/settings/appearance
/settings/reading-manga
/settings/reading-novels
/settings/listen
/settings/ambient
/settings/content
/settings/circle
/settings/ai
/settings/feedback
/settings/keyboard
/settings/about
/settings/about?sheet=licenses
```

Capture with `node scripts/proof.mjs --step web-39 --skin glass --routes ../docs/redesign/proof/web-39/routes.txt` (run `node scripts/proof.mjs --help` first; its real flags win) in the named session `web-39`, headless Chromium, at 1440 × 900 and 390 × 844 (touch emulation on the phone size), into `docs/redesign/proof/web-39/`. Then `frontend/e2e/glass-settings.spec.ts` (`free -m && E2E_BASE_URL=http://127.0.0.1:3010 npx playwright test e2e/glass-settings.spec.ts --workers=1`), signed in as the seeded admin and once as the non-admin, saves `docs/redesign/proof/web-39/state-*.png` for: the search overlay and a flashed row (phone and desktop), the no-profile notice, a server-backed section loading and in error (`page.route` failing `/api/settings` and `/api/profiles/*/sharing`), the offline notice, the switch alert (phone and desktop, with the downloads notice), the melt at 150, 350 and 550 ms, the reduced-motion fade, the arrival toast with Undo, the 18+ gate alert mid-hold, the hold-to-confirm reset mid-fill, the licences sheet and a pushed licence text, the Circle preview line mid-typing, Solid glass and Increase contrast on Appearance, `cinematic-settings-{before,after}-desktop.png`; it asserts the hit targets, the keys, route focus, the titles, the boot attributes after a reload, the debug-only switch writing no `PATCH`, and zero `/api/*` requests from `/skin-preview/glass`. Copy the four loop files' sizes into the report. Write `docs/redesign/proof/web-39/report.md` mapping every file to its acceptance item. Stop `next dev` and the dev stack afterwards.

## Git

- Branch `feat/vps-slim-source-native`. Commit small and often: the `design:` settings-index commit alone (only `design/glass-settings-index.json`, `design/build.mjs` and the two generated files), pushed at once for `mobile/39`; the switch path and outbox; the migration; the stores; the structure; each section; the switch alert and melt; the arrival toast; the licences builder and data; the preview route and capture script with the four media files; the spec and proof. Stage your paths explicitly, never `git add -A` or `git add .`; the mobile, backend and shared sessions commit in the same checkout.
- Conventional messages (`feat(web-glass): skin melt and restart`). No Claude or AI attribution anywhere: no `Co-Authored-By` line, no "Generated with" line, no AI author. Never commit secrets or `.claude/`.
- `npm run build` (after `free -m`, with `next dev` stopped) before every push; `git push origin feat/vps-slim-source-native` after each working step.
- Never edit `backend/connectors/` or any backend file. Never touch production containers or `/srv/manhwamaniacs/{app,data}`. Do not deploy: Glass stays behind the debug row until `release/01`.

## Report back

Reply with:

1. Done items by scope letter (A to M), and anything not done with the reason.
2. The screenshot folder `docs/redesign/proof/web-39/` and its file list, plus the four preview files with their byte sizes, frame counts and final quality.
3. Test counts (vitest files and cases before and after, the `node --test` results), the Playwright spec result, `build.mjs --check`, lint and build results, the `free -m` available figure before each build, and the SKIN RESTART figures measured.
4. The migration marker and store names used, and whether `web/35` had already migrated any row.
5. Decisions made where the contract was silent (the tile tones, the desktop breakpoint at 1024 px for the two panes, the Circle rows disabled under the master, the preview-line source, the `mm.glass.sounds` device key), and any place where `glass/DESIGN.md` overrode this file.
6. Whether Glass onboarding step 2 (`web/30`) now shows the loops, and whether the parallel `mobile/39` session had already landed the settings index.
7. Open issues, each with its `glass/DESIGN.md` section.

Next prompt file: `docs/redesign/prompts/web/40-glass-you-about-admin-status.md` (`docs/redesign/prompts/mobile/39-glass-settings-and-skin-switch.md` runs in parallel).
