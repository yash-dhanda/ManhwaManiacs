# Web foundation 02: restart-to-switch, first-paint accessibility, haptics and sound

## Goal

Build the skin-neutral machinery that changing skins and giving feedback depend on, on the web client (`frontend/`):

- `switchSkin()`, which awaits `PATCH /profiles/{id} {skin}` and then restarts the app into the other skin;
- the `mm-skin` device mirror and the session keys around a restart;
- the service worker's `skin` and `skin-changed` messages, and one offline fallback page per skin;
- boot resolution: the profile's saved skin against the device mirror, with the debug override read first;
- the pre-flip debug row at `/settings/diagnostics?debug=1`;
- first-paint accessibility attributes stamped from the profile's `mm.boot.a11y` before paint;
- each skin's web haptics (`navigator.vibrate` on Android Chrome only) and UI sounds (Web Audio, off by default);
- the core of the motion-timings recorder, including the `SKIN RESTART` entry.

Nothing here draws skin UI. The Cinematic "Stop the press" outgoing sequence (web/18) and Glass's "melt" (web/39) plug their animations into `switchSkin()` later. Legacy users see no change except that `/settings/diagnostics` now serves the debug row when `?debug=1` is on the URL.

## Read first

1. `docs/redesign/stack-decision.md` §2.4 (where the skin choice lives; boot resolution steps 1–5), §2.5 (restart to switch, web steps 1–6).
2. `docs/redesign/cinematic/DESIGN.md`:
   - §5 (haptics: the five web events and their `navigator.vibrate` patterns, the `mm.haptics` switch),
   - §6 (UI sounds: off by default, per profile, volume 0–100 % default 60 %, the Press Room cue table and the full event → cue map, Web Audio playback, suppressed while narration or a soundscape plays),
   - §8.0.7 (the `glass_available` flag and "The pre-flip debug row"),
   - §8.30.2 row 10 (Feedback),
   - §8.30.3 "Outgoing sequence" (the 0 / 500 ms web rows), "The switch waits for the server" and "Budget and misses" (these are the mechanics you build; the visuals are web/18's),
   - §8.32 row "Offline fallback page",
   - §3.4 (the Hyperlegible paragraph on `appearance-boot-source.ts` and `mm.boot.a11y`), §14.1 (which reduced-motion setting wins),
   - §15.2 "Service worker" paragraph, §15.9 (motion-timings overlay: what it logs, the `SKIN RESTART` entry, the 200-entry ring buffer),
   - §15.10 S3, S5, S6, S12.
3. `docs/redesign/glass/DESIGN.md`:
   - §5 intro, §5.2 (the seven Android web events in the "Android web" column), §6 (Meniscus cues, per device, volume −24 to 0 dB default −6 dB, `playbackRate` for velocity pitch, depth pitch `push-1` … `push-4`, `back`; the web audio-session line),
   - §8.0.8 "First-paint attributes (web)", §8.2 "Web" bullet (`mm.skin.splash.glass`), §8.25.2 (the switch flow), §8.25.5 (Sound and haptics scopes), §8.28 "Offline fallback",
   - §15.2 "Service worker" bullet, §15.5 (the device-key table, `mm.boot.a11y` shape), §15.10 G4 and G5.
4. `docs/redesign/inventory/00-decisions.md` (haptics rich and on by default; sounds off by default).
5. `docs/redesign/inventory/web.md` §1 row E4 and §2.1 rows G9 and G13 (the boot script and the service-worker boundary as they are today).
6. `docs/redesign/00-baseline.md`.
7. Upstream outputs (read, do not rewrite): `frontend/src/skins/{types,index,server}.ts`, `frontend/src/app/(app)/layout.tsx`, `frontend/src/app/(app)/settings/[section]/page.tsx` (web/00); `frontend/src/skins/contract.generated.ts` (`HapticEvent`, `SoundEvent`, `FLAGS`); `frontend/src/skins/{cinematic,glass}/tokens.generated.ts` (haptic and sound maps); `frontend/public/sounds/{cinematic,glass}/` (shared/03's `.ogg` and `.m4a` cues); `brand/{cinematic,glass}/glyphs/mm-mark-*.svg` (shared/02).
8. Today's code you extend: `frontend/public/sw.js`, `frontend/public/sw-policy.js`, `frontend/public/offline-fallback.html`, `frontend/src/features/offline/{protocol.ts,client.ts,sw-harness.testing.ts,sw-integration.test.ts,policy-contract.test.ts}`, `frontend/src/features/preferences/{appearance-boot-source.ts,appearance-boot.tsx,appearance-boot.test.ts}`, `frontend/src/lib/scoped-storage.ts`, `frontend/src/features/profiles/{types.ts,api.ts,hooks.ts,store.ts}`, `frontend/src/features/novels/components/NovelAudioPlayer.tsx`, `frontend/next.config.ts`.

## Preconditions (stop and report if any fails)

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs
git branch --show-current                                         # feat/vps-slim-source-native
grep -n '"motion"' frontend/package.json                          # web/01 done
ls frontend/src/skins/glass/tokens.generated.ts                   # shared/01 done
ls frontend/public/sounds/cinematic frontend/public/sounds/glass  # shared/03 done
grep -n "skin" backend/routes/profiles.py | head -5               # backend/00 done: PATCH accepts skin
```

## Skills to invoke

- `superpowers:writing-plans` first. Save the plan at `docs/redesign/proof/web-02/plan.md`.
- `superpowers:subagent-driven-development` to run it (or `superpowers:executing-plans` inline). Slices: (A–D) switching and boot; (E) service worker and fallbacks; (F) a11y boot; (G–H) haptics and sounds; (I) recorder. Check every slice against `git diff`, never against its report.
- `superpowers:test-driven-development` for `switchSkin`, `resolveBootSkin`, the recorder and the service-worker cases: write the Vitest case first.
- `frontend-design`, `impeccable` and `taste-skill:taste-skill` for the two offline fallback pages and the debug row.
- `superpowers:verification-before-completion` before claiming done.

## Scope, item by item

### A. Types and storage primitives

1. `frontend/src/features/profiles/types.ts`: add `skin: "cinematic" | "glass" | null` to `Profile` and `skin?: "cinematic" | "glass" | null` to `UpdateProfilePayload`. `frontend/src/features/profiles/api.ts`: `update(id, body, signal?: AbortSignal)` passes `{ signal }` through `http.patch` (`RequestOptions` already carries `signal`).
2. `frontend/src/features/skin/skin-storage.ts`. Every storage access is wrapped in try/catch, because a locked-down browser throws.
   - Cookies: `readCookie(name)`; `writeSkinCookie(name: "mm-skin" | "mm-skin-debug", skin: SkinId)`, which writes `${name}=${skin}; Path=/; Max-Age=31536000; SameSite=Lax; Secure` (stack §2.4; not httpOnly, because the client writes it); `clearSkinCookie(name)` (`Max-Age=0`).
   - Session keys, as exported constants: `RETURN_KEY = "mm.skin.return"`, `T0_KEY = "mm.skin.t0"`, `splashKey(skin) = \`mm.skin.splash.${skin}\`` (per skin, glass §15.10 G5), `DEBUG_KEY = "mm.debug"`, `BOOT_RESTART_KEY = "mm.skin.boot-restart"`.
   - `postToWorker(message: { type: "skin" | "skin-changed"; skin: SkinId })`: `navigator.serviceWorker?.controller?.postMessage(message)`. Add the two type names to `features/offline/protocol.ts` as `SKIN_MESSAGE = { boot: "skin", changed: "skin-changed" } as const`.
   - `restartInto({ cookie, skin, from, returnPath })`, the one restart path every caller uses, in this order: write the cookie; `sessionStorage[RETURN_KEY] = returnPath`; remove `splashKey(from)`, so the arriving skin's reveal plays; post `{ type: "skin-changed", skin }`; `location.replace(returnPath)`.

### B. `switchSkin()` (stack §2.5; cinematic §8.30.3; §15.10 S12)

3. `frontend/src/features/skin/switch-skin.ts`:

   ```ts
   export async function switchSkin(
     opts: { profileId: number; to: "cinematic" | "glass"; from: SkinId;
             outgoing: () => Promise<void>;   // the leaving skin's exit: Cinematic 500 ms, Glass 615 ms
             reverse: () => Promise<void> },  // undo it on failure (Cinematic: blades reverse 200 ms dur.clip ease.set)
     deps: SwitchDeps = browserDeps,          // patch, now, restartInto, session storage, onLine; injectable for tests
   ): Promise<"restarting" | "failed">
   ```

   The sequence, exactly:
   - If `navigator.onLine` is false, return `"failed"` at once, with no animation and no request. The web Edition row is disabled offline (cinematic §8.30.1).
   - t = 0: `markSkinRestartStart()` (item 22; writes `mm.skin.t0 = Date.now()`), then send `profilesApi.update(profileId, { skin: to }, controller.signal)` without awaiting it. The mirror and the return route are **not** written yet.
   - `await outgoing()`.
   - Then wait for the PATCH for at most **1,000 ms more**, timed from the end of `outgoing()`.
   - On a 2xx: `restartInto({ cookie: "mm-skin", skin: to, from, returnPath: location.pathname + location.search })` and return `"restarting"`.
   - On an error or the timeout: `controller.abort()`, remove `mm.skin.t0` (so the next splash cannot log a false entry), `await reverse()`, and return `"failed"`. The calling skin shows its error toast ("Couldn't switch editions. Try again." in Cinematic, §8.30.3). The mirror is left unchanged.

   Haptic `skin.switch` and the sound cue play inside the skin's own `outgoing()` at its moment (Cinematic: 456 ms), not here.
4. `frontend/src/features/skin/switch-skin.test.ts`: t0 is written before `outgoing` starts; the PATCH starts before `outgoing` resolves; a 2xx calls `restartInto` with `mm-skin`, the target skin and the current path+search; a rejection calls `reverse` and removes t0 with no cookie write; a PATCH that resolves 1,001 ms after `outgoing` ends is aborted and returns `"failed"` (use fake timers); offline returns `"failed"` without calling `outgoing`.

### C. Boot resolution (stack §2.4 steps 1–5; cinematic §8.0.7; §15.10 S5)

5. `frontend/src/features/skin/boot.ts`, pure:

   ```ts
   export function resolveBootSkin(i: {
     rendered: SkinId;                                   // <html data-skin>, the server's reading of the cookies (step 1)
     debug: SkinId | null;                               // mm-skin-debug, read first
     profileSkin: "cinematic" | "glass" | null | undefined; // undefined = no profile payload (offline)
     glassAvailable: boolean; defaultSkin: SkinId;
   }): { restartTo: SkinId | null }
   ```

   The rules, in order:
   - With a debug override, return it if it differs from `rendered`, otherwise null. The profile is not consulted.
   - If `profileSkin` is `undefined` (offline, or the profiles list has not loaded), return null: keep the mirror (step 5).
   - Set `desired = profileSkin ?? defaultSkin`, with `glass` coerced to `cinematic` while `glassAvailable` is false. In that case the mirror is left alone and the stored value is kept for when Glass ships.
   - If `desired === rendered`, return null (step 3). Otherwise return `desired` (step 4).

   `boot.test.ts` covers every branch in a table.
6. `frontend/src/features/skin/SkinBoot.tsx` (`"use client"`), mounted by `app/(app)/layout.tsx` inside `Providers`, next to `ServiceWorkerBoundary`:
   - On mount, post `{ type: "skin", skin: rendered }` to the worker, and again on `navigator.serviceWorker`'s `controllerchange`.
   - Read and remove `sessionStorage["mm.skin.return"]`.
   - In the first `requestAnimationFrame` after mount, call `logSkinRestart(rendered)` (item 22). It is a no-op when there is no t0. It is the fallback until each skin's Splash calls it on its own first frame (web/06, web/29); whichever runs first clears t0.
   - When the active profile id (`useActiveProfileStore`) and the `GET /profiles` list (`useProfiles`) are both available, find the row and run `resolveBootSkin` with `debug = readCookie("mm-skin-debug")` (validated), `glassAvailable = FLAGS.glassAvailable` and `defaultSkin = DEFAULT_SKIN`. When it returns a target, restart with `restartInto({ cookie: "mm-skin", skin: target, from: rendered, returnPath: location.pathname + location.search })`, with no confirm and no undo (step 4).
   - Loop guard: before restarting, read `sessionStorage["mm.skin.boot-restart"]` (`"<skin>:<epochMs>"`). If the same target was attempted less than 10,000 ms ago, do not restart; `console.warn("Skin boot: <target> did not take; staying in <rendered>")` instead. Otherwise write the key, then restart. This stops an endless reload when cookies are blocked.
   - Subscribe to the storage scope (`subscribeStorageScope` in `lib/scoped-storage.ts`) and apply the new profile's `mm.boot.a11y` with `applyBootA11y` (item 12) whenever the scope changes, so a profile that loads after first paint gets its attributes.

### D. The pre-flip debug row (cinematic §8.0.7)

7. `frontend/src/app/(app)/settings/[section]/page.tsx`: when `(await props.params).section === "diagnostics"`, return `<DebugEditionPage />` for every skin; otherwise `renderScreen("settings", props)`. The legacy settings wrapper from web/00 still gives 404 for every other section.
8. `frontend/src/features/skin/DebugEditionPage.tsx` (`"use client"`), skin-neutral (it renders under legacy, Cinematic and Glass), with its styles in `DebugEditionPage.module.css` (class selectors only; Turbopack rejects impure CSS-module selectors).
   - **Gate.** If the URL has `?debug=1`, write `sessionStorage["mm.debug"] = "1"`. If neither the query nor the session flag is present, `router.replace("/settings")` and render nothing.
   - **Layout.** Background `#000000`, text `#FFFFFF`, font `system-ui, -apple-system, "Segoe UI", Roboto, sans-serif`, max-width 560 px, padding 24 px.
   - **Content:**
     - `h1` "Edition (debug)", 24 / 32 weight 600;
     - caption, 14 / 20 `rgba(255,255,255,0.64)`: "A device override for this browser. It never changes the profile's edition, and it goes away at the flip.";
     - a line "Now showing: {data-skin}" and "Override: {cookie value or none}";
     - a segmented control built from native `<input type="radio" name="mm-debug-skin">` inside `<label>`s, so arrow keys and Space work natively. Segments come from `DEBUG_SKINS = ["legacy", "cinematic"] as const` in the same file. release/00 changes it to `["cinematic", "glass"]` when it deletes the `legacy` skin (its Decision 1 keeps the row for Glass development, glass §8.0.8); web/25 expects that state and does not edit this list. Labels are `LEGACY` and `CINEMATIC` (13 px, weight 600, uppercase, letter-spacing 0.12em). Each segment is at least 44 px tall and 120 px wide, with a 1 px `rgba(255,255,255,0.40)` border; the checked segment is filled `#FFFFFF` with `#000000` text;
     - a button "Clear override", at least 44 px tall, with the same border.
   - **Focus.** `:focus-visible` gives a 2 px solid `#FFFFFF` outline at 2 px offset. On the radio segments, draw it on the label with `:has(:focus-visible)`.
   - **Choosing a segment:**
     1. `markSkinRestartStart()`, so the restart is measured;
     2. an `aria-live="polite"` status reads "Restarting in {Cinematic|Legacy}…";
     3. a fixed full-screen `#000000` overlay (z-index 2147483000) fades from opacity 0 to 1 over 200 ms `linear` (`dur.clip`, the same under reduced motion: it is already a plain fade);
     4. after 200 ms, `restartInto({ cookie: "mm-skin-debug", skin, from: rendered, returnPath: "/settings/diagnostics?debug=1" })`.

     "Clear override" runs the same fade, then `clearSkinCookie("mm-skin-debug")` and `location.replace("/settings/diagnostics?debug=1")`. The row never writes `reading_profiles.skin` and never calls `switchSkin`.

### E. Service worker and offline fallbacks (cinematic §15.2; glass §15.2, §8.28)

9. `frontend/public/sw.js`:
   - Constants `META_CACHE = "mm-sw-meta"` and `SKIN_URL = "/__skin"`. `storeSkin(skin)` puts `new Response(skin)` at `SKIN_URL` in `META_CACHE`; `readSkin()` returns the stored text or null. A worker can be stopped at any time, so the value lives in Cache Storage, never in a variable.
   - The message handler gets two cases, `"skin"` and `"skin-changed"`, both validating `data.skin` against `["cinematic", "glass", "legacy"]`. `"skin"` stores it. `"skin-changed"` stores it, deletes `policy.pagesCacheName()`, and then re-fetches the saved chapter documents: for every cache whose `policy.parseCacheName(name).kind === "offline"`, walk `cache.keys()`; for each stored response whose `Content-Type` starts with `text/html`, `fetch(url, { credentials: "include" })` and `cache.put` the fresh copy when `policy.isCacheableResponse(response)` passes. A failure (offline) keeps the old copy. All of this runs inside the existing `event.waitUntil`.
   - `handleNavigation`'s offline branch, after the pages cache and saved-document lookups miss: pick `offline-fallback.html` when the stored skin is `legacy`; `offline-fallback-glass.html` when it is `glass`; otherwise `offline-fallback-cinematic.html` (also when nothing is stored, cinematic §8.32). Fall back to `OFFLINE_URL`, then the existing 503 text.
   - Add both new files to the shell precache list, next to `OFFLINE_URL`.
10. `frontend/public/sw-policy.js`: `META_CACHE_NAME = "mm-sw-meta"` exported, and `isObsoleteCacheName` returns `false` for it (today `parseCacheName` reads it as kind `sw`, version `meta` and would delete it on every activate). `frontend/next.config.ts` `headers()`: the no-cache source becomes `/:path(sw.js|sw-policy.js|offline-fallback.html|offline-fallback-cinematic.html|offline-fallback-glass.html)`.
11. `frontend/public/offline-fallback-cinematic.html` and `frontend/public/offline-fallback-glass.html`: standalone HTML with inline CSS and inline JS only, no external fonts or files. Each has `<meta name="color-scheme" content="dark">`, `<meta name="theme-color" content="#000000">` and the viewport meta with `viewport-fit=cover`. Body is `#000000`, and content is centred in a column of max-width 480 px with padding `max(24px, env(safe-area-inset-*))`. A live status badge updates on `online` and `offline` events. `Try again` calls `location.reload()`. `Downloads` is a link to `/downloads`. Both buttons are at least 44 px tall, with visible `:focus-visible` rings. `prefers-reduced-motion` needs nothing: there is no motion.
    - **Cinematic** (§8.32; colours §2.1.1):
      - the `mm-mark` SVG from `brand/cinematic/glyphs/mm-mark-light.svg` (Light is the notice weight at 32 px and up, §2.7), inlined at 72 px in `#F3F0E8`;
      - badge `NO CONNECTION` in `#FF5B4A` (`proof`) or `BACK ONLINE` in `#57D68D` (`set`), 11 / 16 px, weight 700, uppercase, letter-spacing 0.16em, font `"Archivo Narrow", "Arial Narrow", "Roboto Condensed", sans-serif`;
      - headline "This page needs the server." in `"Bodoni Moda", Didot, "Bodoni 72", "Bodoni MT", Georgia, serif`, italic, 32 / 36 px, `#F3F0E8`;
      - deck "Chapters you saved still open on this device." in `Newsreader, Georgia, serif`, 18 / 28 px, `#9A978F` (`ink.60`);
      - note "Served from your device by the app." in `"IBM Plex Mono", ui-monospace, monospace`, 12 / 16 px, `#9A978F`;
      - `Try again`: square (radius 0), fill `#F3F0E8`, text `#000000`, 15 px weight 600;
      - `Downloads`: quiet, text `#F3F0E8` with a 1 px underline on hover;
      - focus ring 2 px `#F3F0E8` at 2 px offset, plus a `0 0 0 6px #000000` halo (`focus.halo`).
    - **Glass** (§8.28; colours §2.1.2–2.1.4):
      - the inline SVG mark from `brand/glass/glyphs/mm-mark-regular.svg` (use whatever `ls brand/glass/glyphs/mm-mark*` shows for the Regular weight), 56 px, `#F2F2F7`, centred in a 120 px CSS "lens": a circle with `background: radial-gradient(circle at 35% 30%, rgba(255,255,255,0.18), rgba(255,255,255,0.04) 60%, rgba(255,255,255,0) 100%)`, `border: 1px solid rgba(255,255,255,0.22)` and `box-shadow: inset 0 1px 0 rgba(255,255,255,0.35)`;
      - status capsule "No connection" in `#FFB547` (`warning`) or "Back online" in `#3DDC84` (`success`): the colour as text on its own 18 % fill, radius 9999 px, 13 px weight 600;
      - headline "This page needs the server" 28 / 34 px weight 700, `#F2F2F7`;
      - deck "Chapters you downloaded are still on this device and open as normal." 17 / 24 px, `#96969D` (`label2` composited);
      - note "This page is served from your device." 13 px `#96969D`;
      - `Try again`: capsule filled `#7563F2` (`iris600`) with `#FFFFFF` text;
      - `Downloads`: capsule with a 1 px `rgba(255,255,255,0.22)` border and `#F2F2F7` text;
      - font `"Google Sans Flex", system-ui, -apple-system, "Segoe UI", Roboto, sans-serif`;
      - focus ring: 2 px `#000000` inner, then 2 px `#BCB0FF` (`iris300`), plus a 6 px `rgba(188,176,255,0.28)` glow (`focusRing`).
    - Keep the legacy `offline-fallback.html` unchanged; it serves legacy until the flip.

### F. First-paint accessibility (cinematic §15.10 S6; glass §8.0.8, §15.10 G4)

12. `frontend/src/features/preferences/boot-a11y.ts`:
    - `BOOT_A11Y_BASE = "mm.boot.a11y"`; `type BootA11y = { legible: boolean; motion: boolean; solid: boolean; contrast: boolean; sr: boolean }` (`motion: true` means "Reduce motion in this app" is forced on);
    - `readBootA11y()` and `writeBootA11y(patch)` through `readScopedString` / `writeScopedString` (per profile, JSON). `writeBootA11y` also calls `applyBootA11y`;
    - `applyBootA11y(root: HTMLElement, value: BootA11y | null)` sets or removes, on `<html>`: `data-motion="reduced"` (when `value.motion`, or when `matchMedia("(prefers-reduced-motion: reduce)")` matches), `data-legible="on"`, `data-solid="on"`, `data-contrast="more"` and `data-sr="on"`.
    - Cinematic reads only `legible` and `motion`; Glass reads all five. The Settings rows that call `writeBootA11y` come with each skin's settings step.
13. `frontend/src/features/preferences/appearance-boot-source.ts`: add the a11y channel to the hand-minified script. Reuse its active-profile lookup and its `:p<id>` suffix scan with the prefix `mm.boot.a11y::u`, `JSON.parse` the value inside the existing `try`, and set the same five attributes the same way (`typeof matchMedia=="function"&&matchMedia("(prefers-reduced-motion: reduce)").matches` for the OS). It keeps declining on `/login` and `/register`, and it keeps stamping `data-theme` and `data-preset` for legacy. Extend `appearance-boot.test.ts`: the profile's entry stamps all five attributes; another profile's entry stamps nothing; malformed JSON stamps nothing and throws nothing; the auth paths stamp nothing.

### G. Haptics (cinematic §5, §15.10 S3; glass §5.2, §15.10 G3)

14. `frontend/src/features/preferences/feedback.ts`, shared by both skins and by both Settings screens:
    - `HAPTICS_KEY = "mm.haptics"` (device-global `localStorage`, `"on"` by default or `"off"`);
    - `readHapticsEnabled()` and `writeHapticsEnabled(on)`;
    - `webHapticsAvailable()`, which is `"vibrate" in navigator && matchMedia("(pointer: coarse)").matches`. The Feedback row renders only when it is true (never on iOS Safari or desktop).
15. `frontend/src/skins/cinematic/haptics.ts`: `export function haptic(event: HapticEvent): void`. It calls `navigator.vibrate(pattern)` only when `webHapticsAvailable()` and `readHapticsEnabled()` are both true and the event has a web pattern: `longpress.open` `[12]`, `follow.add` `[12]`, `streak.milestone` `[12]`, `download.fail` `[20, 40, 20]`, `error` `[20, 40, 20]`. Every other event is a no-op.
16. `frontend/src/skins/glass/haptics.ts`: the same signature and gates, with Glass's seven patterns: `stack.open` `[18]`, `toggle.on` `[10]`, `longpress.open` `[18]`, `follow.add` `[12, 60, 12]`, `download.fail` `[24, 50, 24]`, `streak.milestone` `[12]`, `error` `[24, 50, 24, 50, 24]`. Glass rate-limits (§5): a call within 120 ms of the previous vibration is dropped, unless its pattern's total duration is longer than the previous one's, in which case it replaces it (`navigator.vibrate` cancels the running pattern), so a burst keeps the strongest.
17. `haptics.test.ts` in each skin folder: stub `navigator.vibrate`, `matchMedia` and `localStorage` on `globalThis`, then assert the exact patterns, the no-ops, the `mm.haptics = "off"` gate, the fine-pointer gate and (Glass) the 120 ms rule.

### H. UI sounds (cinematic §6; glass §6)

18. `frontend/src/features/audio/activity.ts`: `setAudioActivity(kind: "narration" | "soundscape", on: boolean)` and `isOtherAudioActive()`. Wire narration in `features/novels/components/NovelAudioPlayer.tsx`: the audio element's `play` event sets it on, and `pause`, `ended` and unmount set it off (no visual change). The soundscape steps (web/23, web/44) set `"soundscape"`.
19. `frontend/src/skins/cinematic/sounds.ts`:
    - Preferences are **per profile** in scoped `localStorage`, key base `mm.sounds`, value `{ on: boolean; volume: number }` with default `{ on: false, volume: 60 }` (percent). Export `readSoundPrefs()` and `writeSoundPrefs(patch)`.
    - `playSound(event: SoundEvent): void` resolves the cue from the event → cue map and the cue → file map in `tokens.generated.ts` (read the file for the export names; never copy the table by hand). The web file is `/sounds/cinematic/<cue file base name>.<ext>`: check the names with `ls frontend/public/sounds/cinematic`. `ext` is `ogg` when `new Audio().canPlayType('audio/ogg; codecs="<codec>"')` is not `""`, otherwise `m4a`; read the codec with `file frontend/public/sounds/cinematic/*.ogg`.
    - Nothing is fetched while sounds are off. After they are on, the first `pointerdown` or `keydown` (a capture listener, once) creates one `AudioContext` and one master `GainNode` (`gain = volume / 100`), then fetches and `decodeAudioData`s every cue of the skin (13 files, 384 KB or less). When `writeSoundPrefs({ on: true })` is called from a click handler, prime at once, inside that gesture.
    - When creating the context, if `navigator.audioSession` exists, set its `type` to `"ambient"`, so iOS Safari's silent switch mutes cues (the web side of State A).
    - `playSound` returns silently, and never queues, when sounds are off, when `isOtherAudioActive()` is true, or when buffers are not decoded yet. Otherwise it plays one `AudioBufferSourceNode` through the master gain.
20. `frontend/src/skins/glass/sounds.ts`:
    - Preferences are **per device** (glass §6 and §8.25.5 say so, unlike Cinematic's per-profile rule): plain `localStorage` key `mm.glass.sounds`, value `{ on: boolean; volumeDb: number }`, default `{ on: false, volumeDb: -6 }`, range −24 to 0; `gain = 10 ** (volumeDb / 20)`.
    - `playSound(event: SoundEvent, opts?: { rate?: number; depth?: 1 | 2 | 3 | 4 })`: `nav.push` with `depth` plays `push-<depth>`; `nav.pop` plays `back`; `rate` sets `playbackRate` (velocity pitch).
    - Export `throwRate(v)`, which is `(1200 + Math.min(Math.abs(v), 3000) * 0.6) / 1200` (the throw whoosh centre frequency over its 1200 Hz base), and `semitoneRate(n) = 2 ** (n / 12)` (scrub ticks rise up to +3 semitones).
    - Same loading, audio-session and suppression rules as Cinematic, with files from `/sounds/glass/`.
21. `sounds.test.ts` in each skin folder: every `SoundEvent` the skin maps resolves to a cue whose `.ogg` and `.m4a` both exist in `public/sounds/<skin>/`; prefs default to off; `playSound` is a no-op while off or while `isOtherAudioActive()` is true (stub `AudioContext`); Glass depth and rate mapping.

### I. Motion-timings recorder core (cinematic §15.9)

22. `frontend/src/lib/motion-timings.ts`, shared by both skins (each skin's overlay UI and `play()` come later: web/04 and web/25):
    - `type MotionEntry = { name: string; kind: "move" | "gesture" | "restart"; plannedMs: number; startMs: number; endMs: number; startFrame: number; endFrame: number; frames: number; plannedFrames: number; dropped: number }`.
    - A ring buffer of **200** entries. `entries()`, `clearEntries()`, `subscribe(listener)` (returns an unsubscribe), `setRecording(on)` and `isRecording()`.
    - `startMove(name, plannedMs)` returns `{ end() }`. While recording is off it returns a shared no-op handle and does no work (§15.9 "Cost"). `startGesture(name)` is the same for scroll-linked moves: frames and drops per gesture, `plannedMs` 0.
    - While any move is open, one shared `requestAnimationFrame` loop counts frames against `performance.now()`. The frame interval is the median of the last 60 frame deltas under 100 ms, starting at `1000 / 60`. A delta over 1.5 × the interval adds `Math.round(delta / interval) - 1` dropped frames to every open move. `plannedFrames = Math.round(plannedMs / interval)`.
    - `isLate(e)`: `endMs - startMs > plannedMs + interval`, or `dropped > 0`, or, for `restart`, the duration is over 1,500 ms.
    - `formatEntry(e)`: `COLUMN WIPE   872 → 880 MS   53/53 F   0 DROP` for moves (name upper-cased, the planned → actual duration, frames / planned frames); `SKIN RESTART  confirm → first splash frame  1,212 MS` for the restart.
    - While recording, each ended entry is mirrored to the console once with `console.table([row])`.
    - `markSkinRestartStart()` writes `sessionStorage["mm.skin.t0"] = String(Date.now())`.
    - `logSkinRestart(skin)` reads and removes t0 and returns null when there is none. Otherwise it **always** records a `restart` entry, even with recording off (§15.9), and calls `console.warn(\`SKIN RESTART ${ms} ms > 1500 ms\`)` over budget.
23. `frontend/src/lib/motion-timings.test.ts` with a fake `requestAnimationFrame` and clock: the ring keeps the last 200; a move with one 50 ms gap at 60 Hz reports 2 dropped; off means no entries and no rAF; `logSkinRestart` records while off, clears t0, warns over 1,500 ms, and returns null without t0; `formatEntry` gives the exact strings above.

### J. Housekeeping

24. If web/00 left out `@import "../skins/glass/tokens.generated.css";` in `frontend/src/app/globals.css` (shared/01 had not run then), add it now, after the Cinematic tokens import, and re-run web/00's `legacy-bridge.test.ts`.

## File layout

```
frontend/public/sw.js, sw-policy.js                                     change
frontend/public/offline-fallback-cinematic.html, offline-fallback-glass.html   new
frontend/next.config.ts                                                 change (no-cache list)
frontend/src/app/(app)/layout.tsx                                       change (mount SkinBoot)
frontend/src/app/(app)/settings/[section]/page.tsx                      change (diagnostics)
frontend/src/app/globals.css                                            change only if item 24 applies
frontend/src/features/skin/{skin-storage.ts,switch-skin.ts,switch-skin.test.ts,boot.ts,boot.test.ts,SkinBoot.tsx,DebugEditionPage.tsx,DebugEditionPage.module.css}   new
frontend/src/features/offline/protocol.ts, sw-integration.test.ts, policy-contract.test.ts   change
frontend/src/features/profiles/types.ts, api.ts                        change
frontend/src/features/preferences/{boot-a11y.ts,feedback.ts}           new
frontend/src/features/preferences/appearance-boot-source.ts, appearance-boot.test.ts   change
frontend/src/features/audio/activity.ts                                 new
frontend/src/features/novels/components/NovelAudioPlayer.tsx            change (activity flag only)
frontend/src/skins/cinematic/{haptics.ts,haptics.test.ts,sounds.ts,sounds.test.ts}     new
frontend/src/skins/glass/{haptics.ts,haptics.test.ts,sounds.ts,sounds.test.ts}         new
frontend/src/lib/motion-timings.ts, motion-timings.test.ts             new
docs/redesign/proof/web-02/plan.md, docs/redesign/proof/web-02/*            new
```

## Acceptance criteria

- [ ] `npm run typecheck`, `lint`, `test` and `build` pass. Vitest counts are at least those recorded before your first change; nothing that passed before fails.
- [ ] `switch-skin.test.ts`, `boot.test.ts`, both `haptics.test.ts`, both `sounds.test.ts`, `motion-timings.test.ts`, the extended `appearance-boot.test.ts` and the new service-worker cases all pass.
- [ ] Service worker, through the existing `sw-harness.testing.ts`:
  - `{ type: "skin", skin: "glass" }` stores `glass` at `/__skin` in `mm-sw-meta`;
  - `skin-changed` deletes `mm-pages-v3` and re-fetches every `text/html` entry of every `mm-offline-*` cache;
  - an offline navigation serves `offline-fallback-glass.html` after `glass`, `offline-fallback-cinematic.html` after `cinematic` or with nothing stored, and `offline-fallback.html` after `legacy`;
  - `isObsoleteCacheName("mm-sw-meta")` is false.
- [ ] Debug row, with the dev server:
  - under legacy, `/settings/diagnostics?debug=1` shows the row;
  - choosing `CINEMATIC` fades to black over 200 ms and reloads to the same URL with `data-skin="cinematic"`;
  - choosing `LEGACY` comes back;
  - `Clear override` removes the cookie;
  - `/settings/diagnostics` without the flag in a fresh tab redirects to `/settings`;
  - no `PATCH /profiles` request is sent (check the network log).
- [ ] After a debug restart, the console shows `SKIN RESTART … MS` (from the SkinBoot fallback), and `mm.skin.t0` is gone from `sessionStorage`.
- [ ] Boot resolution: with `mm-skin=cinematic` and a profile whose `skin` is `null`, the page restarts once into legacy (the pre-flip default) and does not loop. With `mm-skin-debug` set, the profile is ignored. With the network off, the mirror is kept.
- [ ] First paint: a profile with `mm.boot.a11y = {"legible":true,"motion":true,"solid":true,"contrast":true,"sr":true}` loads with all five attributes already on `<html>` in the first HTML paint. Check with Playwright: read `document.documentElement` attributes in an `addInitScript` that runs on `DOMContentLoaded`, before hydration.
- [ ] Offline fallbacks: both pages render standalone (open `/offline-fallback-cinematic.html` and `/offline-fallback-glass.html` directly); the badge flips when `context.setOffline()` toggles; `Try again` and `Downloads` are reachable by Tab, show the per-skin focus ring, and are at least 44 px tall at 390 × 844.
- [ ] Keyboard (web): the debug row works with Tab, arrow keys (between segments), Space and Enter only; focus is always visible.
- [ ] Reduced motion: the debug fade is the same 200 ms plain fade; the offline pages have no motion. Haptics stay available under reduced motion (glass §5; cinematic §14.9).
- [ ] Per-skin differences:
  - Cinematic vibrates 5 events with `[12]` / `[20,40,20]`; Glass vibrates 7 events with its own patterns and the 120 ms rule;
  - Cinematic sound prefs are per profile (`mm.sounds`, 0–100 %, default 60), Glass sound prefs are per device (`mm.glass.sounds`, −24 to 0 dB, default −6);
  - the offline pages use each skin's copy, colours and focus ring.
- [ ] Legacy is unchanged: before and after screenshots of `/library`, `/settings` and the novel reader with narration playing are identical apart from live data.

## Verification

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs/frontend
free -m                                   # stop under 1024 MB available
npm run test 2>&1 | tail -5               # BEFORE changes: record counts
# … implement …
free -m && npm run typecheck
free -m && npm run lint                   # baseline: 0 errors, 0 warnings
free -m && npm run test
free -m && npm run build                  # never alongside next dev or another build
```

Mobile and backend: this step changes neither. Judge that by your own commits, never by the branch diff (mobile, backend and shared sessions commit on the same branch): `git show --stat --format= <hash>` for each of your commits must list no `mobile/` or `backend/` path. Only if one does, revert that part and prove the baseline still holds with its own commands, one at a time after the RAM guard: `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze` (baseline: No issues found), `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter test` (baseline: all 2012 tests passed) and `cd backend && .venv/bin/python -m pytest -q --no-header`.

**Dev checks and proof.** `frontend/scripts/proof.mjs` arrives in web/03, so drive headless Chromium with one-off scripts under `/tmp` (load Playwright with `createRequire("/srv/manhwamaniacs/dev/ManhwaManiacs/frontend/package.json")("playwright")`; sign in with `POST /api/auth/login` and seed `mm.active-profile` exactly as web/00's `/tmp/mm-shoot.mjs` does). Do not commit these scripts.

1. Start the dev stack of `backend/scripts/README-dev-stack.md` (uvicorn 127.0.0.1:8010, dev SQLite under `/srv/manhwamaniacs/dev/data/`, never production data).
2. `free -m && NEXT_PUBLIC_API_URL=/api BACKEND_INTERNAL_URL=http://127.0.0.1:8010 NEXT_PUBLIC_ENABLE_SW=1 npm run dev -- --port 3010`. The worker registers in development only with that flag.
3. Screenshots at 1440 × 900 and 390 × 844 into `docs/redesign/proof/web-02/`:
   - `debug-row-legacy-*.png` and `debug-row-cinematic-*.png`;
   - `debug-fade-*.png` (captured 100 ms after choosing a segment);
   - `offline-cinematic-{offline,online}-*.png` and `offline-glass-{offline,online}-*.png`;
   - `offline-nav-cinematic-*.png`: set the skin, `context.setOffline(true)`, navigate to an uncached URL, and screenshot what the worker served.
4. Save the console output of one debug restart (the `SKIN RESTART` line) as `docs/redesign/proof/web-02/skin-restart.txt`.
5. Stop `next dev` before any `npm run build`.

## Git

- Branch `feat/vps-slim-source-native`. Commit per slice: plan; storage primitives and profile type; `switchSkin` and its test; boot resolution and `SkinBoot`; debug row; service worker and policy; offline pages; a11y boot; feedback prefs and haptics; audio activity and sounds; recorder; proof. Push after each working step: `git push origin feat/vps-slim-source-native`.
- Stage explicit paths only, never `git add -A`: other sessions commit in this checkout.
- No Claude or AI attribution (no `Co-Authored-By`, no "Generated with" line). Never commit secrets, `.env*` or `.claude/`.
- `npm run build` must pass before every push.

## Guardrails

- Work in `frontend/` (plus `docs/redesign/proof/`). Do not edit `design/`, `brand/`, generated files, `mobile/` or `backend/` (never `backend/connectors/`).
- Never touch production containers or `/srv/manhwamaniacs/{app,data}`. The service worker change ships to production only with a deploy that the owner's release step makes, not from here.
- RAM guard: `free -m` before every build, test run and dev server start. Stop under 1024 MB available. One heavy command at a time.

## Report back

1. Done items A–J with commit hashes.
2. The `SKIN RESTART` figure measured on the debug restart, and the boot-resolution cases you exercised by hand.
3. Service-worker test names and results; whether `mm-sw-meta` survived an activate.
4. Screenshot folder `docs/redesign/proof/web-02/`.
5. Test counts before and after, lint and build results, and the lowest `free -m` available figure.
6. Open issues (for example, a sound codec Safari cannot decode, or a haptic event missing from `HapticEvent`).

Next prompt in the web track: `docs/redesign/prompts/web/03-foundation-reader-seam-limiter-proof.md`. Next in the global order: `docs/redesign/prompts/mobile/02-foundation-native-plugins-haptics-sound.md`.
