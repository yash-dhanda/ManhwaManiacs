# Web Glass Listen mode with the 31 voices

Track: web · Order 92 · Depends on: `docs/redesign/prompts/web/36-glass-novel-reader.md` · Runs in parallel with: `docs/redesign/prompts/mobile/37-glass-listen-mode.md` · Proof folder: `docs/redesign/proof/web-37/`

## Goal

Build Glass Listen mode (glass §8.16) on the web client (`frontend/`): narration that keeps playing across the whole app from a Glass narration host in the Shell; the listen row above the novel reader's bottom capsule, the bottom accessory "Now narrating" on phones and the desktop accessory at the foot of the sidebar; the full player (a `medium` → `large` sheet that grows out of the capsule, a 560 px T5 window on desktop, the Listen tab of the novel reader's right panel) with the artwork, the speaking orb that takes each speaker's colour, the sentence-ticked scrubber, the transport, the three tiles and the lyrics-style sentence list; the speed dial; the voice orbit for all 31 named voices (they introduce themselves when they come to rest) and the cast sheet; the Audiobook sheet from the book page; the sleep timer; highlight-as-read on the page with narration-driven page turns in paged mode; every state and key. Playback, timing, sleep, sessions, saved audio and job polling already exist in the shared data layer from `web/15`: this step adds Glass chrome and gestures on top of them and changes no playback rule. Cinematic must not change by a single pixel.

## Read first

Read these completely before planning. Where this file and `glass/DESIGN.md` disagree, `glass/DESIGN.md` wins; say so in the report.

1. `docs/redesign/inventory/00-decisions.md` (all; "novel TTS with 31 named voices", haptics rich, UI sounds off by default).
2. `docs/redesign/stack-decision.md` §2.2, §2.6 (one data layer), §4 risk 11.
3. `docs/redesign/glass/DESIGN.md`:
   - "Conventions used everywhere below"; §2.1.2 (`onGlass`, the backing disc, the T4/T5 text mapping), §2.1.3, §2.1.5 (speaker palette), §2.4.2 (variants incl. `glassMonolith`, rule 2 "thickness follows size", rule 7, rule 8), §2.4.3, §2.7 (`headphones`, `voice-31`, `play`, `pause`, `skip-back`, `skip-forward`, `dots-three`).
   - §3.2 (`title2`, `title3`, `subhead`, `footnote`, `caption1`, `caption2`, `mono`, `monoLarge`), §3.5 (ROND on T5 glass).
   - §4.2, §4.3, §4.4 (voice orbit projection), §4.5 (sliders and dials rubber-band 12 px), §4.6, §4.7, §4.10 rows Bloom, Sheet present, Sheet snap, Recede, Toast fall, Tab droplet, Rubber band, Catch, Highlight band, Lozenge morph, Follow scroll, Speaking orb pulse, Preview orb pulse, Liquid fill, Liquid spinner, Page slide, Page lift; §4.9; §4.11 (the screen-reader rules: voice previews never auto-play).
   - §5.2 events `listen.toggle`, `voice.center`, `voice.assign`, `sleep.fade`, `detent.tick`, `detent.magnet`, `detent.limit`, `chapter.next`, `select`, `motion.catch`, `sheet.pass`, `sheet.detent`, `undo`, `error`; §6 (UI sounds are suppressed while narration plays; the audio-session table: the `narration` state).
   - §7.10 (sheets: detents, the full-player exception `glassMonolith` → `solid2`), §7.11, §7.12 (toasts, Undo with the draining rim), §7.15 (the bottom accessory "Now narrating" variant, minimise, the non-gesture paths), §7.16 (the desktop accessory and the "Narrating 3" chip), §7.19 (liquid ring, liquid bar), §7.21 (the speed dial), §7.23 (menus), §7.24, §7.34 (swipe alternatives), §7.40 (pointer cursors: `grab` on the speed dial and the voice orbit).
   - **§8.16 entire** (§8.16.1 to §8.16.8). Read every line; it is the contract for this step.
   - §8.13 (the book page's Audiobook button and its live statuses; owner = `is_admin`), §8.15.2 (the header's "Listen · 14 min" capsule, the right panel's Listen tab), §8.15.3 (the listen and voices buttons), §8.15.4 ("Narration in paged mode"), §8.15.8 (keys).
   - §8.0.3 (sheet ids `player`, `voices`, `cast`, `audiobook`; the speed dial and sleep menu are anchored pickers with no `?sheet=`), §8.0.10 (`narration_unavailable`, `audio_preparing`, `audio_convert_failed`).
   - §11 (gesture rows for the listen row, the orbit, the speed dial), §14.5 (screen reader), §14.9, §15.2, §15.5 (`mm.glass.prefs.autoPlayPreviews`), §15.7 (the novel reader row: the listen row is one live surface).
4. `docs/redesign/cinematic/DESIGN.md` §8.16 (the shared playback, sleep, sessions and saved-audio behaviour its step built into `features/novels/`), only to know what the shared engine already does; never copy its look.
5. `docs/redesign/inventory/web.md` §10.3 (NR9, NR10, NR13, NR14, NR15), §18.7 (A82–A86), §12 (Downloads).
6. `docs/redesign/inventory/capabilities.md` §19.3 (audio, jobs, `available`, `highlight_safe`, segments, `503 audio_preparing`, "iOS must use m4a", job statuses) and §19.4 (voices and casting payloads).
7. `docs/redesign/00-baseline.md`.
8. `docs/redesign/proof/web-15/report.md` (the exact API of `useNarration()` including the gain-node accessor, `useSavedAudio`, `useActiveNarrationJobs`, the sleep timer, sessions, media session) and `docs/redesign/proof/web-36/report.md` (the `GlassListenBridge` shape, the chrome slot arrays, the right-panel tab array, the keys reducer).
9. Code you build on: `frontend/src/features/novels/` (`use-narration.ts`, `narration-timing.ts`, `sleep-timer.ts`, `listen-sessions.ts`, `audio-save.ts`, `narration-jobs.ts`, `media-session.ts`, `listen-settings.ts`, `hooks.ts`, `api.ts`, `types.ts`), `frontend/src/skins/glass/` (`Shell.tsx` with the accessory, the desktop accessory and the `SheetHost` registry; `primitives/SpeedDial.tsx`, `Slider.tsx`, `Sheet.tsx`, `Menu.tsx`, `Toast.tsx`, `LiquidProgress.tsx`, `Segmented.tsx`, `Chip.tsx`, `Stepper.tsx`, `IconButton.tsx`, `ObjectLens.tsx`; `soundscape.ts` or the audio-session module from `web/29`; `screens/novel/*` from `web/36`; `screens/series/*` book page from `web/33`; `screens/library/*` Downloads from `web/32`), `frontend/src/skins/cinematic/screens/listen/voice-pulse.ts` (read only), `backend/routes/novels.py` (read only: the exact payloads of `/novels/audio`, `/novels/audio/series`, `/novels/audio/render` with its `skipped` reasons, `/novels/audio/jobs`, `/novels/voices`, `/novels/cast`, `/novels/cast/alias`, `/novels/narrator`), `frontend/e2e/fixtures/listen/` (from `web/15`).

## Preconditions (check before writing the plan)

- `git log --oneline -30` shows the `web/36` commits; `novel` is not in the Glass `PENDING` map; `grep -rn "GlassListenBridge" frontend/src/skins/glass` finds `web/36`'s bridge.
- `grep -rn "export function useNarration\|export const useNarration" frontend/src/features/novels` and `grep -rn "useActiveNarrationJobs" frontend/src/features/novels` both match. If either is missing, stop and report that `web/15` has not run.
- `grep -n "SpeedDial" frontend/src/skins/glass/primitives/*.tsx` finds `web/27`'s dial.
- In `frontend/`: `free -m && npm run test` is green; record the vitest file and case counts (your floor).

## Skills to invoke

1. `superpowers:writing-plans` before any code; plan at `docs/redesign/proof/web-37/plan.md`, one task per scope letter.
2. `superpowers:test-driven-development` for every pure module (voice hue, cast line, orbit maths, highlight band geometry, the paged-turn decision, the accessory priority, job-row mapping, skip-reason toast wording).
3. `superpowers:subagent-driven-development` (or `superpowers:executing-plans` inline). At most 6 implementer subagents, scope-locked, `model: "opus"` passed explicitly, one heavy command at a time, every subagent's work checked against `git status` and `git diff`.
4. `frontend-design:frontend-design`, `impeccable:impeccable` and `taste-skill:taste-skill` for the player, the orbit and the lyrics list: the speaking orb and the voices must feel like physical objects of light, not a media widget.
5. `superpowers:verification-before-completion` before you claim anything is done.

## Scope: deliver every item below

Tokens only (`--mm-…`, `tokens.generated.ts`); every animated move goes through `play(name, …)` with its `MotionName`; every haptic through `skins/glass/haptics.ts` and every cue through `sounds.ts` (UI cues stay silent while narration plays: the shared `narrationActive` flag). Sections cited are `glass/DESIGN.md`.

### A. The Glass narration host and pure helpers

1. **`skins/glass/listen/NarrationHost.tsx`**, mounted once in the Glass `Shell` above the routes, so narration survives leaving the reader. It owns the playing reference `{ sourceId, seriesKey, chapterKey }` and calls `useNarration()` for it (if `web/15`'s hook creates its audio element per mount, the host is that one mount; do not change the hook's behaviour for Cinematic). It provides `GlassNarrationContext` = `{ ref, state, play, pause, toggle, playFrom(para), seekBy(ms), seekToSegment(i), setSpeed(x), next(), previous(), stop(), analyser }` and replaces `web/36`'s default `GlassListenBridge` provider (same shape). The novel reader registers its paragraphs and fingerprint with the host so `highlightSafe` is computed against the text on screen.
2. **Level analyser:** on the first play gesture, tap `web/15`'s gain node with one `AnalyserNode` (`fftSize` 256); the level is the RMS of `getFloatTimeDomainData`, smoothed with an 80 ms attack and a 240 ms release (`a = 1 − exp(−dt / τ)`). If the smoothing lives in `skins/cinematic/`, move it to `features/novels/voice-pulse.ts` in a no-behaviour-change commit and import it from both skins. Sampled at most 30 times a second.
3. **Audio session:** request the `narration` state from `web/29`'s audio-session module when playback starts (`navigator.audioSession.type = "playback"` where supported) and return to `idle` (`"ambient"`) when it stops with no soundscape playing (§6). Listen sessions post exactly as in Cinematic through `listen-sessions.ts` (open on play, close after a 30 s pause, on chapter change, on `pagehide`); media session metadata and handlers through `media-session.ts`.
4. **`voice-hue.ts`** (+ test). §8.16 uses "the voice's hue" without a rule; this step fixes it: `voiceHue(pitchHz)` = OKLCH(L 0.80, C 0.12, h) with `h = 250 − (clamp(pitchHz, 80, 300) − 80) / 220 × 210` (deep voices blue-violet at 250°, bright voices warm at 40°), converted to sRGB hex with the chroma reduced in 0.01 steps until in gamut. The test asserts ≥ 9:1 against `#000000` at 80, 190 and 300 Hz (the speaker palette's floor is 9.71:1). Name this decision in the report.
5. **`cast-line.ts`** (+ test): the player's third title line. "Narrated by {narrator voice name}" and, when characters have their own voices, " · {voice} voices {n} characters" for the voice that voices the most characters (ties: the one earlier in the server's voice order); "Narrated by the default voice" when the narrator is automatic.
6. **`listen-accessory.ts`** (+ test): the accessory priority of §7.15 (Now narrating > Downloading > Continue) as a pure function over `{ narration, downloads, continueItem, onHome, heroVisible }`.
7. **`orbit-math.ts`** (+ test): for a card at signed offset `o` from the centre (in cards, fractional while scrolling): `rotateY = 18° × clamp(o, −2, 2)`, `scale = 1 − 0.14 × min(|o|, 1)`, `opacity = 1 − 0.4 × min(|o|, 1)`; `snapIndex(scrollLeft, velocity, stride = 176)` = `round(project(scrollLeft, v) / stride)` clamped to the list (stride = 160 px card + 16 px gap); `pitchPosition(pitchHz)` on the 80–300 Hz track; `expressivenessDots(rank, n) = ceil(5 × rank / n)` (the raw `expressiveness` has no fixed range, so voices are ranked among the loaded list).
8. **`band-geometry.ts`** (+ test): from a sentence's `Range.getClientRects()` (merged per line, converted to the column's coordinates) produce the band rects with padding 2 × 4 px and radius 6; `bandMorph(prev, next)` pairs rects by index, extra rects grow from the last previous rect, missing ones collapse into it.
9. **`paged-follow.ts`** (+ test): in paged mode, `shouldTurn(activeFirstLineTop, pageBottom)` is true when the active sentence's first line lies below the current page's last line; a manual turn sets `decoupled` until "Back to the voice".
10. **Sheet registration:** register `player` (form `sheet`, detents `medium` and `large`; desktop form `window` 560 px outside a reader), `voices` and `cast` (`large`; desktop `panel` 440 px outside a reader) and `audiobook` (`large`; desktop `panel` 440 px) with `web/29`'s `registerGlobalSheet(id, { component, form, detents })`, so the accessory, the desktop accessory and the book page open them over any screen; inside the novel reader on desktop, `web/36`'s screen claims `player`, `voices` and `cast` (`useClaimSheet`) and shows them as the right panel's Listen and Voices tabs.

### B. Entry points

1. **Novel reader top-right group** (`web/36`'s slots): **listen** (`headphones`, "Listen") shown when the chapter has audio, or when the viewer is the owner (`is_admin`) and `GET /novels/audio/series` says `can_render`; for the owner on an un-narrated chapter it opens the Audiobook sheet (item H) in Narrate mode with this chapter selected; for everyone else it starts or opens narration. **Voices** (`voice-31`, "Voices") opens the cast sheet (item F). The group stays at four icons; in landscape phones both move into the ⋯ menu.
2. **Chapter header** (`web/36`'s slot): a `glassThin` capsule "Listen · 14 min" (`headphones`; "· saved" appended when `useSavedAudio` reports the audio on the device) that starts narration at the reading line's paragraph; under it the quiet line "Audio plays without follow-along for this chapter" when `highlightSafe` is false.
3. **`p`** play / pause (replacing `web/36`'s bridge default), the listen row, the accessory and the desktop accessory play buttons.
4. **`?listen=1`**: the reader starts at the resume point and calls `play()` on arrival; when the browser refuses (`NotAllowedError` on a cold load), the listen row shows paused with its play button focused.
5. **Play from here** (`web/36`'s menu) now runs through the host.
6. **Book page** (`web/33`): the **Audiobook** button with its live status ("Make audiobook", "Make audiobook · 12 done", "Narrating · 3 in progress, 5 waiting", "Waiting for the narration PC · 5", "Audiobook · 40 narrated"), the note "Narration of new chapters is not available right now" when `narration_unavailable`; add the button if `web/33` did not render it. Non-owners see it as status only ("Audiobook · 40 narrated") and it opens the sheet in Save mode where Save exists. The book page ⋯ "Voices for this book" opens the cast sheet.
7. **"Narrating 3" chip** (`useActiveNarrationJobs()`): a plain `fill2` chip (no machine light) on the desktop sidebar's Library → Downloads item and at the top of the Downloads screen (`web/32`), opening the book's Audiobook sheet (the book of the first active job). The You tab row gets it in `web/40`.

### C. The listen row, the accessory and the desktop accessory (§8.16.1, §7.15, §7.16)

1. **Listen row in the novel reader:** a `glassRegular` capsule 48 px tall, 8 px above the bottom capsule, the same insets and max width 520: the narrating voice's orb 32 (a `fill2` twin disc with the voice's initial in `voiceHue`), "Ch 12 · Aurora" in `subhead` `onGlass`, a play/pause button 44 (`fill2` twin; `listen.toggle`), and a 2 px progress line along its bottom edge (played part `iris500`, buffered segment at 35 %). It shows with the chrome and lingers 5000 ms after the chrome hides, unless pinned. It is the novel reader's third live surface (§15.7).
2. **Gestures on the row and on the accessory:** a horizontal swipe changes chapter when the projection passes 30 % of its width (`chapter.next`, `rigid(0.8)`); a tap opens the full player (item D); a swipe down whose projection passes 40 px (§7.15) stops narration with the toast "Stopped reading aloud" + "Undo" (10 s draining rim; Undo resumes at the same position, `undo`). Long-press (500 ms on touch) or `.` / `shift+F10` opens a menu with "Pin" / "Unpin" and "Hide for this session"; on the web, Delete or Esc while it has focus hides it for the session (narration pauses first, with the Undo toast). Swipes use Motion `drag` with `dragDirectionLock` and `touch-action: pan-y`, on coarse pointers only.
3. **Bottom accessory (phones and mobile web, outside the readers):** fill `web/29`'s "Now narrating" variant with the same content ("Chapter 12 · Aurora", voice orb 32, play/pause 44, the progress line); tap grows it into the full player along `morph`; when the dock minimises, it shrinks inline on `minimize` showing only the orb, title and play control. Priority from A6.
4. **Desktop accessory** (sidebar foot, 56 px, `fill2` fill on the sidebar's glass, `onGlass` text): "Now narrating" (voice orb 32, "Ch 12 · Aurora", play/pause, the 2 px progress line); a click opens the 560 px player window (D2). Collapsed sidebar: a 56 px orb with the voice orb and a play overlay on hover.
5. **Desktop inside the novel reader:** narration lives in the right panel's **Listen** tab (append **Voices** and **Listen** to `web/36`'s tab array: "Aa · Voices · Listen"; `v` opens Voices; the Listen tab opens from the listen button or when narration starts; `p` keeps meaning play/pause). No listen row on desktop while the panel is open; with the panel closed, the listen row shows as on phones.

### D. The full player (§8.16.2), `?sheet=player`

1. **Phones and tablets:** a sheet grown out of the listen row or the accessory on `morph` (the capsule's glass interpolates T3 → T5, §2.4.2 rule 2), detents `medium` (52 %: artwork, orb, titles, scrubber, transport, tiles) and `large` (adds the sentence list); `glassMonolith` (T5: fill `rgba(22,22,28,0.60)`, blur 32, saturate 1.7, rim `rgba(255,255,255,0.14)`) at `medium`, cross-fading to `solid2` `#26262E` at `large` (§7.10). Its lit action is the play button; while the sheet is up, the screen's own lit object drops to `glassThin` and its caustic fades over 180 ms.
2. **Desktop outside the reader:** a 560 px window (T5 `glassMonolith`, radius 32) blooming from the desktop accessory on `morph`, max height 88 vh, one column with the sentence list below the tiles. **Desktop inside the reader:** the Listen tab as a column (artwork 200 px, speaking orb, scrubber, transport, tiles, sentence list).
3. **Header:** the grabber (phones); a trailing `fill2` twin circle 32 (44 hit) holding ⋯: **Save audio** (phones only, item G) and **Soundscape** (rendered only when the `SheetHost` registry has `soundscape`, which `web/44` registers).
4. **Artwork:** the book plate on a `fill2` twin card, radius 20, 200 px on desktop and `min(60vw, 240px)` on phones, with parallax: on coarse pointers with device tilt available and "Light follows the device" on, the art moves up to ±6 px against the card from the `useLightAngle` tilt source (`web/25`); static on desktop, with the switch off and under reduced motion.
5. **Titles** (all `onGlass`, hierarchy by size, §2.1.2): chapter title `title2`, book title `footnote`, the cast line (A5) `caption1`.
6. **The speaking orb:** a 72 px twin sphere (`fill2` base tinted with the narrator's `voiceHue`, radial highlight at the light angle) pulsing with the level (scale `1 + 0.10 × level`, 30 fps); when a character's segment plays, that speaker's band hue (§2.1.5, the same slot as on the page) flows into the orb over 300 ms (a timed colour cross-fade, never sprung) and returns to the narrator's hue after the line; a `fill2` twin chip under it names the voice: "Narrator · Aurora" or "Mira · voiced by Ada" (`caption1` 600). A polite live region announces a speaker change at most once per 5 s ("Now speaking: Mira"). Reduced motion: the orb is static; the colour cross-fade stays.
7. **Scrubber:** `web/27`'s slider at 6 px with the chapter's sentence boundaries as 1 px ticks (`rgba(255,255,255,0.22)`); the thumb shows a `mono` time bubble while dragged; "5:12" and "−18:40" in `mono` at each end; drag seeks live and commits on release; `role="slider"`, `aria-valuetext="5 minutes 12 of 23 minutes 52"`; arrows step one sentence, Page Up / Down 15 s.
8. **Transport:** back 15 s, previous sentence, **play/pause** (72 px, the tinted twin: `iris600` at 86 %, rim `rgba(255,255,255,0.30)`, the caustic under it), next sentence, forward 15 s; names "Back 15 seconds", "Previous sentence", "Play" / "Pause", "Next sentence", "Forward 15 seconds".
9. **Tiles:** three 72 px `fill2` twin tiles: **Speed** ("1.25×" in `monoLarge`; opens the speed dial, item E), **Voices** (the narrator's orb + "Cast of 6"; opens the cast sheet), **Sleep** ("Off" or the live countdown "12:40"; opens the sleep menu, item I).
10. **Sentence list** (at `large`, and always in the desktop window and the Listen tab): lyrics-style, `title3` Literata; the sentences from `sentenceRuns()`; the active one at 100 % inside a **lozenge** (radius 12, the content twin of `glassThin`: fill `rgba(19,19,23,0.62)`, 0.5 px rim, inner light) that **morphs** between sentences on `snappy` (k 246.7, c 26.70), stretching across line breaks with `band-geometry.ts`; the others in `label2` on `solid2` (never dimmed by opacity: they stay tappable); in the desktop T5 window the inactive sentences are `onGlass` at `wght` 420 and the active one `onGlass` at 700; speaker tints as bands; a tap or Enter plays from that sentence (`seekToSegment`). The active sentence has `aria-current="true"`; the list is a list of buttons. Follow keeps the active sentence at 38 % and scrolls on `settle` only when it leaves 20–70 % (`followDecision`); beyond two panel heights it jumps with a 120 ms cross-fade. A manual scroll decouples and shows a `fill2` twin capsule "Back to the voice"; in this list it re-couples on its own after 4000 ms idle.
11. **Chapter boundary:** at the end of the chapter's audio a post-play card "Next chapter in 5" with a ring draining over 5 s, "Play now" (tinted) and "Cancel"; when it completes (it pauses while focus or the pointer is inside it), playback continues into the next chapter and, when the reader is open, the text swaps in place through `useNovelReader().next()` (in paged mode the new chapter re-paginates and opens at page 1). The shared `mm.listen-settings.autoPlayNext` ("Continue to the next chapter", default on) off: playback stops at the end with no card. Under reduced motion the ring is replaced by a `mono` "5 s … 1 s" count.
12. **Collapse:** a downward drag (sheet physics of `web/27`: projection, `sheetSnap`, dismiss past 50 % of the lowest detent or at ≥ 1500 px/s), the grabber, Esc and browser back (`?sheet=player` history entry). Focus moves to the sheet title on open and back to the listen row or accessory on close. Reduced motion: fade + 16 px translate, 150 ms.

### E. Speed dial (§8.16.3)

Tapping the Speed tile blooms `web/27`'s `SpeedDial` out of the tile on `morph`: a vertical glass capsule 64 × 240. Check the primitive against every rule and extend `slider-math.ts` where it differs: 0.5× to 3.0× in 0.05 steps, 6 px of drag per step, labelled marks at 0.5, 1, 1.5, 2, 2.5, 3; `detent.tick` every 0.25× (the 0.05 steps are silent); a magnet at 1.0× (values within ±0.08 snap to 1.0 with `detent.magnet`, `rigid(0.4)`); a 12 px rubber band past the ends (`detent.limit`); the value previews live while dragging and commits on release through `setSpeed` (saved in the shared `mm.listen-settings.speed`); touch-and-hold for 600 ms without moving resets to 1.0×; on desktop the mouse wheel over the dial steps 0.05× per notch (§11 "Vertical drag on the speed dial"), and the dial shows `grab` / `grabbing` (§7.40). Under the value, "≈ 190 wpm" in `caption1` (`narrationWpm`). Preset chips beneath: 0.8 · 1 · 1.25 · 1.5 · 2. Pitch preserved (`preservesPitch`). Semantics: `role="slider" aria-orientation="vertical" aria-valuemin="0.5" aria-valuemax="3" aria-valuenow="1.25" aria-valuetext="1.25 times, about 190 words a minute"`; arrows step 0.05, Page Up / Down 0.25, Home / End the ends. It is an anchored picker: Esc, an outside tap or back closes it without a history entry. `<` / `>` change speed by 0.05 while narrating.

### F. Voices: the orbit and the cast (§8.16.4)

1. **Cast sheet** (`?sheet=cast`, `large`; desktop outside a reader: the 440 px right panel; inside the desktop reader: the Voices tab): title "Voices in this chapter"; status lines "Looking up who speaks here…", "Nobody has been identified in this chapter, so the narrator reads it all.", "Narrated by Kade: Kade's own lines use the narrator's voice because they are the same person."; the **Narrator** row pinned at the top (orb in `voiceHue`, the voice name or "Default voice", chevron → the orbit for the narrator); then one row per character in cast order: speaker swatch 12 px (dashed when unhued), name, a **gender capsule** (`caption1`: Male · Female · Unknown; for the owner a tap opens a three-item menu that sends `POST /novels/cast {source_id, series_key, name, gender}` and shows the lock glyph; read-only for others), the assigned voice or "Automatic", the share of lines ("31 %"), a lock glyph when set by hand; a tap opens the orbit filtered to that character's gender; the owner's row ⋯ holds "Same character as…" (a menu of the other names → `POST /novels/cast/alias {source_id, series_key, alias, canonical}`) and "Reset to automatic" (`POST /novels/cast` with `voice_id: null`). Non-owners see the rows read-only with the caption "Voices are set by the server's owner".
2. **Voice orbit** (`?sheet=voices`, `large`; desktop: inside the right panel or the 440 px panel): the voices of `GET /novels/voices` (31 in production; never hard-code the count) as cards on a horizontal native scroll container with the projection snap (`orbit-math.ts`, settling on `settle`, k 322.3, c 35.90): the centred card at scale 1.0, neighbours 0.86 and 60 % opacity, each card rotated `18° × offset` capped at two cards, recomputed per frame from the scroll position; `voice.center` (`selection`) at each settle. **Card** (160 × 220, `surface1` `#131317` slab, radius 26, padding 12): a 72 px orb filled with `voiceHue` (radial highlight at the light angle) holding the voice's initial in `#000000`, the name in `title3`, "{Female|Male} · {character}" in `footnote`, a **pitch scale** (a 1-D track labelled "deeper" and "brighter" for screen readers, a dot at `pitchPosition`), an **expressiveness meter** (five 6 px dots, `expressivenessDots`), the tag "In use for Kade" (or "Narrator") when assigned in this book, the duration ("0:07") under the name when the clip is longer than 3 s, and the licence and attribution in `caption2`.
3. **Introductions:** the centred voice auto-plays `GET /novels/voices/sample?voice={id}&format=` (`m4a` when `new Audio().canPlayType('audio/ogg; codecs="opus"') === ""`, else `ogg`) after 400 ms of rest, its orb pulsing with the sample's level (the A2 smoothing on a second analyser); moving again stops it. Auto-play runs only when Screen reader mode is off (`data-sr` absent), the orbit was not reached by keyboard (focus arriving by Tab or arrows disables auto-play until the next pointer interaction), and the orbit's ⋯ switch **"Auto-play previews"** is on (`mm.glass.prefs.autoPlayPreviews`, default on, per profile); otherwise each card shows a 44 px play button and plays only when asked. The playing card always shows a visible 44 px `pause` stop button. A preview never plays over narration: narration pauses for it and resumes when it ends.
4. **Choose:** "Use this voice" (tinted, under the orbit) sends `POST /novels/cast {…, voice_id}` for a character or `POST /novels/narrator {source_id, series_key, voice_id}` for the narrator; `voice.assign` (`success`) and the `add` sound; failure toast with the §8.0.10 copy for the code. A grid toggle switches to a searchable grid (2 columns below 768 px, 4 on desktop) with filter chips All · Female · Male · In use, counts from the list.
5. **Semantics and cursor:** the orbit's scroll container opts into `web/26`'s cursor contract with `data-cursor="grab"` (`grabbing` while dragged, §7.40); the orbit is `role="region" aria-roledescription="carousel" aria-label="Voices"`; each card `role="group" aria-roledescription="voice" aria-label="Aurora, 3 of 31, female, warm, in use for Kade"`; `←` / `→` move one card; trackpad horizontal scroll works.
6. **States:** loading (the orbit shows 5 card skeletons; the cast sheet 1 narrator row + 5 character row skeletons with "Looking up who speaks here…"); voices failed ("Couldn't load the voices" + Try again); cast failed ("Couldn't load who speaks here" + Try again; the narrator row still works); offline ("Voices need a connection"; a book with saved audio still plays with its saved voices; rows read-only); no voices installed ("No voices are installed on the server, so characters can't be cast here yet."); voice save failed (toast); preview unavailable ("No preview available" on the card).

### G. Save audio (§8.16.2 Save audio, phones only)

In the player's ⋯ on phones (below 768 px with a coarse pointer) when `useStorageScope()` reports a downloads scope: "Save audio to this device" → a liquid ring "Saving audio…" → "Audio saved" (a tap asks "Remove saved audio?" with Keep / Remove) → failed "Couldn't save the audio · tap to retry" → unplayable "The saved audio can't play here · tap to save again", through `web/15`'s `audio-save.ts`. A first request answered `503 audio_preparing` shows "Preparing audio" with the liquid ring and retries after `Retry-After`, or 3 s when the header is absent.

### H. Audiobook sheet (§8.16.5), `?sheet=audiobook`

A `large` sheet; desktop: the 440 px right panel (T4, so state glyphs sit on the backing disc). Title "Audiobook"; segmented **Narrate · Save to device** (Save only on phones with a downloads scope; Narrate only for the owner); the unavailable note "Narration of new chapters isn't available right now. Chapters that already have audio can still be saved." on `narration_unavailable`; assist chips "Next 10" (narrate), "All un-narrated (n)" / "All narrated (n)", "None"; a windowed list, one row per chapter with a checkbox and status ("Narrated · saved on this device", "Narrated", "Download the text first", "Not narrated yet"; Save mode: "Saved on this device", "Saved copy can't play here · select to save again", "Saving…", "Couldn't be saved · select to retry"); the estimate caption ("About 45 minutes of rendering on the narration PC" at 9 minutes per chapter) or "Saves while the app is open. The text is saved too, so the chapter plays and follows along offline."; the primary "Make audiobook of 5 chapters" (`POST /novels/audio/render {source_id, series_key, chapter_keys, priority: 0, force: false}`, in groups of at most 200) / "Save audio of 5 chapters"; a **Jobs** section (`GET /novels/audio/jobs` with `narration-jobs.ts`'s cadence: every 5 s, 15 s while everything waits for the render PC, backing off to 60 s after failures) with a liquid bar per job and an owner-only "Cancel" (`DELETE /novels/audio/jobs/{job_id}`, caption "Stops shortly"). **Job rows** (`job-rows.ts` + test): Queued "Waiting for the narration PC" (`g700` clock, `onGlass` on the panel) · Planning "Working out who speaks" (liquid ring) · Rendering "Rendering · 42 %" (liquid bar) · Done "Narrated" (`success` droplet) · Failed (`danger`; `lease_expired` → "The narration PC stopped responding", `audio_convert_failed` → "Rendering failed: the audio couldn't be converted", any other code → "Rendering failed ({code})"; "Render again" for the owner, re-sending that key with `force: true`) · Cancelled ("Cancelled", `label3`, removable). **Toasts** (`skip-toast.ts` + test): "Queued 5 chapters for narration. Skipped: 2 already narrated, 1 not on the server yet." with the reason wording `already_rendered` "{n} already narrated", `chapter_not_cached` "{n} not on the server yet", `chapter_unreadable` "{n} couldn't be read", `already_queued` "{n} already waiting"; "Nothing to narrate."; "Saving the audio of 5 chapters to this device." **States:** loading (4 row skeletons under the live header), error ("Couldn't load the audiobook status" + Try again), offline ("The audiobook needs a connection. Saved audio still plays."; Narrate hidden; Save lists only chapters whose text is downloaded), jobs failed ("Couldn't load narration jobs" + Try again while the list works). Owner = `is_admin` on `GET /auth/me`.

### I. Sleep timer (§8.16.6)

A menu blooming from the Sleep tile (`morph`, `glassThick`, an anchored picker): Off · 5 · 10 · 15 · 30 · 45 · 60 min · End of chapter · End of next chapter · Custom (a minutes stepper 1–180), through `web/15`'s `sleep-timer.ts`; the tile and the listen row show the live countdown ("12:40" in `mono`); the volume fades over the last 8 s (`sleep.fade`, `soft(0.3)`). The default comes from `mm.listen-settings.sleepDefault`. "Shake to extend" is app-only (`sensors_plus`) and is not rendered on the web.

### J. Highlight-as-read on the page (§8.16.7) and paged narration (§8.15.4)

1. While narrating with `highlightSafe` true, the active sentence gets a band at 14 % of its speaker's tint (narration: `iris500` `#8F7EFF`), radius 6, padding 2 × 4 px, drawn in an overlay layer inside the column from `band-geometry.ts`; the band **slides** between sentences on `snappy` (never a cross-fade); speaker bands drop their background under it (their underline stays). The current word brightens to the full ink with a 2 px underline in the tint, stepping with the word estimate (`narration-timing.ts`), never animated.
2. **Follow:** keep the active sentence at 38 % of the viewport, scrolling on `settle` (k 322.3, c 35.90) only when it leaves the 20–70 % band; beyond two viewports it jumps with a 120 ms cross-fade. A manual scroll decouples and shows a `fill2` twin capsule "Back to the voice" above the listen row; on the page there is no automatic return.
3. **Stale timing:** when `highlight_safe` is false or the fingerprint changed, nothing is highlighted and a quiet capsule says "Highlight paused: the text changed".
4. **Paged mode:** while narrating, the reader turns the page with the chosen transition (Slide, Lift or Fade; Fade under reduced motion) the moment `paged-follow.ts` says so; a manual turn decouples and shows "Back to the voice", which turns back to the spoken page.
5. Reduced motion: the band jumps with a 120 ms cross-fade; follow scrolls are instant.

### K. States (§8.16.8)

| State | Presentation |
|---|---|
| No audio | The listen button and the header capsule are hidden (the owner case of B1 excepted) |
| Preparing (`503 audio_preparing`) | The play buttons show a liquid ring and "Preparing audio", retrying after `Retry-After` or every 3 s |
| Buffering | The liquid spinner inside the play button |
| Failed | "Audio couldn't load" + Retry (`error` haptic) in the player and a `warning` ring on the row's play button |
| Offline with saved audio | Plays; a "Saved audio" tag under the titles |
| Offline without saved audio | Play disabled with the reason "Needs a connection or saved audio" (tooltip and `aria-describedby`) |
| Narration unavailable | The Audiobook note (H); playback of existing audio still works |
| Conversion failed (`audio_convert_failed`) | "This chapter's audio couldn't be prepared." + Try again (owners: "Render again") |
| Highlight paused | J3 |

### L. Keys (§8.16.8, §8.15.8), extending `web/36`'s reducer

`p` play / pause · `[` / `]` previous / next sentence · Shift+`[` / Shift+`]` back / forward 15 s · `<` / `>` speed −/+ 0.05 while narrating (cruise speed otherwise, `web/44`) · `v` voices · Esc collapses the player (inside the reader the Esc order becomes: menu or popover → the player → sheet or side panel → return to the book). The keys also work from the full player and the desktop window. Register them under a "Listen" group in `lib/keyboard`.

## Out of scope here (owned by later steps; do not build)

- `web/39`: Settings → Reader defaults → Listen (default speed, "Continue to the next chapter", sleep default). `web/40`: the "Narrating 3" chip on the You hub. `web/44`: the soundscape (the ⋯ row appears once it registers its sheet), ducking under narration, cruise's `<` / `>`.
- Lock screen, `audio_service`, shake to extend: apps only.
- Any change to `design/`, `mobile/`, `backend/` or the Cinematic skin (except the A2 move, which changes no Cinematic behaviour).

## File layout

```
frontend/src/features/novels/voice-pulse.ts (+ test)          A2 (only if it still lives in the Cinematic skin)
frontend/src/skins/glass/listen/
  NarrationHost.tsx, useGlassNarration.ts                     A1–A3
  voice-hue.ts, cast-line.ts, listen-accessory.ts, orbit-math.ts, band-geometry.ts, paged-follow.ts,
  job-rows.ts, skip-toast.ts                                  (each + .test.ts)
  ListenRow.tsx, AccessoryNarrating.tsx, DesktopAccessoryNarrating.tsx                  C
  PlayerSheet.tsx, PlayerWindow.tsx, PlayerColumn.tsx, SpeakingOrb.tsx, Scrubber.tsx,
  Transport.tsx, PlayerTiles.tsx, SentenceList.tsx, PostPlayCard.tsx                    D
  SpeedDialTile.tsx                                           E
  CastSheet.tsx, VoiceOrbit.tsx, VoiceCard.tsx, VoiceGrid.tsx                           F
  SaveAudio.tsx                                               G
  AudiobookSheet.tsx, AudiobookButton.tsx, NarratingChip.tsx  H, B6, B7
  SleepMenu.tsx                                               I
  HighlightLayer.tsx                                          J
frontend/src/skins/glass/Shell.tsx                            mounts NarrationHost; accessory variant
frontend/src/skins/glass/screens/novel/*                      B1–B5, C5, J, L insertions into web/36's slots
frontend/src/skins/glass/screens/series/*                     B6 (book page)
frontend/src/skins/glass/screens/library/*                    B7 (Downloads chip)
frontend/e2e/glass-listen.spec.ts
docs/redesign/proof/web-37/                                   plan.md, screenshots, sessions-log.json, report.md
```

Skin files import only `@/features/**` (never `@/features/*/components/**`), `@/lib/**`, `@/services/**`, `@/stores/**`, `@/types/**`, `@/config/**`, the generated contract and `skins/glass/**`; the lint rule bans `@/skins/cinematic/**`.

## Acceptance criteria

- [ ] Narration started in the novel reader keeps playing after leaving it: the phone accessory and the desktop accessory show "Now narrating" and control it; returning to the reader re-attaches the highlight.
- [ ] Every entry point of B starts playback at the right place: the header capsule, the listen button, `p`, Play from here, `?listen=1` (with the paused-and-focused fallback on a cold load); the owner on an un-narrated chapter lands in the Audiobook sheet with the chapter selected.
- [ ] Listen row: 48 px `glassRegular`, 8 px above the bottom capsule, orb in `voiceHue`, the 2 px progress with the buffered part at 35 %, the 5000 ms linger, Pin, swipe sideways past 30 % changes chapter, swipe down stops with Undo, the menu and Delete/Esc paths hide it.
- [ ] Full player: grows out of the capsule on `morph`, `medium` / `large` detents, T5 at `medium` and `solid2` at `large`, the 560 px desktop window and the reader's Listen tab; artwork parallax ±6 px only on tilt-capable coarse pointers; the speaking orb pulses and takes each speaker's hue over 300 ms with the chip and the throttled announcement; scrubber ticks and `aria-valuetext`; five transport buttons with their names; three tiles; the sentence list with the morphing lozenge, follow at 38 % / 20–70 %, "Back to the voice" re-coupling after 4000 ms; the post-play card with its 5 s ring and the `autoPlayNext` switch honoured.
- [ ] Speed dial: 0.5–3.0 in 0.05 steps at 6 px per step, ticks every 0.25, the 1.0 magnet within ±0.08, 12 px rubber band, 600 ms hold resets, "≈ 190 wpm", presets, pitch preserved, the desktop wheel step, the `grab` cursor, vertical-slider semantics and keys.
- [ ] `?sheet=player`, `voices`, `cast` and `audiobook` open over Library, Home and the book page through the global registry, and inside the desktop novel reader as the right-panel tabs.
- [ ] Voice orbit: every voice from the server as a 160 × 220 card, depth maths per `orbit-math.ts`, projection snap with `voice.center`, auto-play after 400 ms rest only when allowed (never with `data-sr="on"`, never after keyboard arrival, never with the switch off), a visible stop button, durations over 3 s, narration paused during a preview, "Use this voice" posts the right endpoint, grid view with filters.
- [ ] Cast sheet: narrator pinned, rows in cast order with swatch, gender capsule (owner menu and lock), voice, share and lock; alias and reset in the owner ⋯; read-only for non-owners with the caption; every state of F6.
- [ ] Audiobook sheet: segments, chips, statuses, the estimate, `POST /novels/audio/render` in groups of ≤ 200, the jobs section with the 5 / 15 / 60 s cadence, every job-row status and failure wording, owner cancel, the skip toasts with the four reasons, every state; non-owners get status-only and Save.
- [ ] Sleep timer: every option, live countdown in the tile and the row, the 8 s fade with `sleep.fade`; no shake row on the web.
- [ ] Highlight-as-read: the 14 % band slides on `snappy` across line breaks, the word underline steps, follow and decouple rules hold, stale timing shows "Highlight paused: the text changed"; paged mode turns the page for the voice and decouples on a manual turn.
- [ ] States of K all render (screenshots); `audio_preparing` retries on `Retry-After` or 3 s.
- [ ] UI sounds are silent while narration plays; one `POST /novels/listen-sessions` is sent with correct `seconds` and `voice_ids` after play, a 30 s pause and leaving.
- [ ] Keyboard: every binding of L works; every control in the row, accessory, player, sheets, dial and orbit is reachable by Tab with the two-tone focus ring; focus returns to the row or accessory when the player collapses.
- [ ] Hit targets: every control ≥ 44 × 44 CSS px at 390 × 844 and 1440 × 900 (Playwright walk).
- [ ] Reduced motion: player and sheets fade + 16 px (150 ms), the bloom is a 150 ms fade in place, the orb is static (colour still changes), the lozenge and band jump with 120 ms cross-fades, follow scrolls are instant, the post-play ring is a count, the orbit snaps with a 150 ms fade.
- [ ] Budget: the novel reader never exceeds 5 live glass elements with the listen row and the player open (`useGlassCount()`).
- [ ] Per-skin difference: with `mm-skin-debug=cinematic` the Cinematic mini player, reading room and voice picker work unchanged at the same URLs (screenshots before and after); no file under `frontend/src/skins/cinematic/**` changed except import paths from the A2 move.
- [ ] `npm run typecheck`, `npm run lint` (0 errors, 0 warnings), `npm run test` (at or above the floor plus the new tests) and `npm run build` (0 errors, 0 warnings) are green.

## Verification

**RAM guard (production shares this box).** Before every heavy command (build, the vitest suite, `next dev`, a Playwright run) run `free -m`; if the `available` figure of the `Mem:` row is under 1024 MB, stop and report. Never run two builds at once, and never run `next build` while `next dev` or a Playwright browser is running.

From `frontend/`:

```bash
free -m && npm run typecheck
free -m && npm run lint
free -m && npm run test
free -m && npm run build
```

Lint and build stay at 0 errors and 0 warnings (`00-baseline.md`). This step changes nothing in `mobile/` or `backend/`: check each of your commits with `git show --stat --format= <hash>` (the parallel `mobile/37` session and the backend and shared sessions commit `mobile/` and `backend/` on the same branch, so never judge by the branch diff). If one of your commits touched them, revert that part and prove the baseline with `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze` (No issues found), `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter test` (all 2012 tests pass, or the current higher count) and `cd backend && .venv/bin/python -m pytest -q --no-header`, one at a time after the RAM guard.

**Fixtures.** The dev stack has no narration PC and may have no voice pack. Use the live endpoints whenever they answer; otherwise install `web/15`'s generated fixtures (`node e2e/fixtures/listen/make-fixtures.mjs`, then `node scripts/proof.mjs --fixtures e2e/fixtures/listen`; run `node scripts/proof.mjs --help` first and use its real flags). Say in the report which data was live.

**Visual proof.** Start the dev stack from `backend/scripts/README-dev-stack.md` with `MM_NOVELS_ENABLED=1` (127.0.0.1:8010, dev SQLite only), sign in as the seeded admin for owner views and as the second, non-admin account for read-only views, then `free -m && npm run dev -- -p 3010`. Capture in the named session `web-37`, `mm-skin-debug=glass`, headless Chromium at 1440 × 900 and 390 × 844 (touch emulation on the phone size), into `docs/redesign/proof/web-37/`:

- `listen-row-phone.png`, `listen-row-preparing-phone.png`, `listen-row-failed-phone.png`, `accessory-narrating-phone.png` (on Library), `accessory-minimised-phone.png`, `desktop-accessory-desktop.png`, `desktop-accessory-collapsed-desktop.png`.
- `player-medium-phone.png`, `player-large-phone.png`, `player-window-desktop.png`, `player-listen-tab-desktop.png`, `speaking-orb-speaker-phone.png` (a character line playing), `sentence-list-decoupled-phone.png`, `post-play-phone.png`.
- `speed-dial-phone.png` (at the 1.0 magnet), `sleep-menu-phone.png`, `sleep-countdown-tile-phone.png`.
- `cast-owner-desktop.png`, `cast-readonly-phone.png`, `orbit-phone.png`, `orbit-playing-phone.png`, `orbit-grid-desktop.png`, `orbit-empty-phone.png`.
- `audiobook-narrate-desktop.png`, `audiobook-save-phone.png`, `audiobook-jobs-desktop.png`, `audiobook-unavailable-desktop.png`, `book-page-audiobook-status-desktop.png`, `narrating-chip-desktop.png`.
- `highlight-band-desktop.png`, `highlight-band-multiline-phone.png`, `back-to-the-voice-phone.png`, `highlight-paused-phone.png`, `paged-narration-turn-phone.png`.
- `save-audio-states-phone.png`, `offline-no-audio-phone.png`, `reduced-motion-player-phone.png`, `solid-player-phone.png`, `cinematic-{before,after}-desktop.png`.
- `sessions-log.json` (the captured `POST /novels/listen-sessions` bodies).

`frontend/e2e/glass-listen.spec.ts` (`free -m && E2E_BASE_URL=http://127.0.0.1:3010 npx playwright test e2e/glass-listen.spec.ts --workers=1`) asserts the hit targets, focus return, the keys, the reduced-motion checks, the auto-play rules (with `data-sr="on"` and after keyboard arrival no sample request is made), the sessions post, and the budget. Write `docs/redesign/proof/web-37/report.md` mapping every file to its acceptance item. Stop `next dev` and the dev stack afterwards.

## Git

- Branch `feat/vps-slim-source-native`. Commit small and often: the A2 move alone (only when A2 applies); the pure helpers with their tests; the host; the row and accessories; the player; the speed dial; the orbit and cast; save audio; the audiobook sheet and book-page button; the sleep menu; the highlight; states and keys; the spec and proof. Stage your paths explicitly, never `git add -A` or `git add .`.
- Conventional messages (`feat(web-glass): voice orbit with self-introducing voices`). No Claude or AI attribution anywhere: no `Co-Authored-By` line, no "Generated with" line, no AI author. Never commit secrets or `.claude/`.
- `npm run build` (after `free -m`, with `next dev` stopped) before every push; `git push origin feat/vps-slim-source-native` after each working step.
- Never edit `backend/connectors/` or any backend file. Never touch production containers or `/srv/manhwamaniacs/{app,data}`. Do not deploy.

## Report back

Reply with:

1. Done items by scope letter (A to L), and anything not done with the reason.
2. The screenshot folder `docs/redesign/proof/web-37/` and its file list; which data was live and which came from fixtures.
3. Test counts (vitest files and cases before and after), the Playwright spec result, lint and build results, the `free -m` available figure before each build.
4. The `GlassNarrationContext` API and the accessory hooks `web/39`, `web/40` and `web/44` will use (speed default, sleep default, the soundscape ducking hook-in point).
5. Decisions made where the contract was silent (the `voiceHue` formula, the cast-line rule, the owner's listen button on an un-narrated chapter, the "Stopped reading aloud" toast wording), and any place where `glass/DESIGN.md` overrode this file.
6. Open issues, each with its `glass/DESIGN.md` section.

Next prompt file: `docs/redesign/prompts/web/38-glass-search-sources-dialogue.md` (`docs/redesign/prompts/mobile/37-glass-listen-mode.md` runs in parallel).
