# Web Cinematic Listen mode with the 31 voices

Track: web · Order 47 · Depends on: `docs/redesign/prompts/web/14-cinematic-novel-reader.md`, `docs/redesign/prompts/backend/06-reader-tints-panels-novel-audio.md`, `docs/redesign/prompts/backend/03-stats-streaks-annual-listen-sessions.md` · Proof folder: `docs/redesign/proof/web-15/`

## Goal

Build Cinematic Listen mode, "The reading", on the web client, inside the novel reader `web/14` built: every entry point, the mini player above the novel's bottom bar, the full player takeover "The reading room" with its transcript, the highlighter stroke that sweeps through the sentence being read (on the page and in the transcript), the speed ruler, the cast sheet and the voice picker for all 31 named voices (samples with the RMS pulse, `Hear`, cast assignment, `RE-VOICE` and `RE-VOICING` from `rendered_at`, `cast_changed_at` and `force`), the sleep timer, the chapter boundary with its post-play countdown, the owner's Audiobook sheet (narrate and save), saved audio on the device through the service worker, the Media Session controls, every state and key, and listen sessions reported to `POST /novels/listen-sessions`. Audio is pre-rendered per chapter with measured segment timings: the player follows the text sentence by sentence and never guesses beyond the word estimate this file defines. First, the playback logic that still lives in the legacy `NovelAudioPlayer.tsx` moves into a skin-neutral hook in a no-pixel commit.

## Read first

Read these completely before planning. Where this file and `cinematic/DESIGN.md` disagree, `cinematic/DESIGN.md` wins; say so in the report.

1. `docs/redesign/inventory/00-decisions.md` (all; "novel TTS with 31 named voices").
2. `docs/redesign/stack-decision.md` §2.2, §2.3 ("logic that lives in a widget moves first"), §2.6, §4 risk 11.
3. `docs/redesign/cinematic/DESIGN.md`:
   - §2.1.1 (stock-painted panels: the mini player uses the stock's muted colour for `ink.45` roles; `spot.wash` bands render `ink.45`/`ink.60` roles as `ink.80`), §2.1.2 (`color.spot.wash` = `rgba(244,208,63,0.16)`), §2.1.4 (the full player is a row in the over-art table; `scrim.sole` under the Listen transport; `scrim.vignette`), §2.1.5 (duotone matrix), §2.1.6 (speaker tints), §2.5 (`blur.card`), §7.25 and §2.1.1's loop note on the voice-monogram field endpoints.
   - §4.2 (`dur.clip`, `dur.glide`, `dur.countdown.next`, `dur.rise`), §4.4 (`spring.sheet`, `spring.scrub`), §4.5 rows Match cut, Rise, Highlight sweep, Countdown, Voice pulse, Letter set, Type; §4.6; §4.8 rows Listen countdown dial, Voice pulse, Highlight sweep, programmatic scrolls, Gestures.
   - §5 (`listen.toggle`, `voice.assign`, `sleep.fade`, `select`, `chapter.next`: the web maps all of these to no vibration) and §6 (UI cues are suppressed while narration plays; the `set` cue for `voice.assign`; the Voice-sample audio state row).
   - §7.1 (the `play` button: 64 / 56 / 36 px; `split`; `secondary sm`), §7.9, §7.10 (the 1000 ms arm), §7.11, §7.16 (credits rows with dot leaders), §7.18 (leader dial, countdown dial, determinate rule), §7.20, §7.21, §7.23, §7.29 (`folioLabel()`).
   - §8.15.2 (the opener, the voices line), §8.15.3 (the top bar voices button, the Margins VOICES tab, the mini player placement), §8.15.5 (auto-scroll and Listen never run together), §8.15.8 (keys), §8.15.9 (stale text withholds follow-along).
   - §8.16 entire (§8.16.1 to §8.16.12; §8.16.10 applies to the web only through its last paragraph, the Media Session API).
   - §8.18 (the book page's `Listen` secondary and owner-only `Audiobook` button, the `l` key, "Rise to the audiobook sheet").
   - §10.1.2 (the full player's series title is a Letter set), §10.2.2 (the post-play card's chapter title is typed), §11 (rows: long-press on the mini player, press and hold on the Listen speed ruler, horizontal swipe on the mini player, swipe down on the full player, drag on the Listen chapter ruler), §14.1, §14.3, §14.4, §14.5 (timers wait while focus is inside), §14.9, §15.5 (the `listen-sessions` and `audio/series` rows), §15.7.
4. `docs/redesign/glass/DESIGN.md` §15.4 (the `paginateNovel` row lists §8.16.7: Listen continues across chapters in paged mode too) and §15.6 (the audio session row: narration is its own state on both skins).
5. `docs/redesign/inventory/web.md` §10.3 (NR9, NR10, NR13, NR14, NR15), §18.7 (A82–A86), §12 (Downloads, for how saved chapters are listed).
6. `docs/redesign/inventory/capabilities.md` §19.3 and §19.4 (audio, jobs, voices, casting; `audio_preparing`, `narration_unavailable`; "iOS must use m4a"), §1 (error envelope, `Retry-After`), §24.
7. `docs/redesign/00-baseline.md`.
8. `docs/redesign/proof/web-14/report.md` (the `useNovelReader()` API, the novel keys reducer, the stock properties) and `docs/redesign/proof/web-13/report.md` (`SpeedRuler`).
9. Code: `frontend/src/features/novels/` (`audio-follow.ts`, `audio-highlight.ts`, `audio-url.ts`, `cast-labels.ts`, `hooks.ts`, `api.ts`, `types.ts`) and the legacy `components/NovelAudioPlayer.tsx`, `NovelCastPanel.tsx`, `NovelVoicePicker.tsx` (logic to extract); `frontend/src/features/offline/` (`protocol.ts`, `types.ts`, `novel-save-request.ts`, `save-request.ts`, `hooks.ts`) and `frontend/public/sw.js` (`runSave`, the `medium` field); `frontend/src/skins/cinematic/sounds.ts` (how it learns narration is playing); `frontend/src/skins/cinematic/screens/novel/` and the book page screen from `web/11`; the backend routes `backend/routes/novels.py` (read only: the exact payloads of `/novels/audio`, `/novels/audio/series` with `rendered_at` and `cast_changed_at`, `/novels/audio/render` with `force` and `priority`, `/novels/audio/jobs`, `/novels/voices`, `/novels/cast`, `/novels/cast/alias`, `/novels/narrator`) and the listen-sessions route from `backend/03`.

## Preconditions

- `git log --oneline -25` shows the `web/14`, `backend/06` and `backend/03` commits. Check the backend pieces exist: `grep -rn "listen-sessions" backend/routes` and `grep -rn "cast_changed_at" backend/routes` each return a match. If either is missing, stop and report which prerequisite step has not run.
- `npm run test` in `frontend/` is green (record file and case counts as your floor).

## Skills to invoke

1. `superpowers:writing-plans` before any code; plan at `docs/redesign/proof/web-15/plan.md`.
2. `superpowers:test-driven-development` for the extraction and every pure helper (timing, sleep, sessions, polling cadence, save request, pulse smoothing).
3. `superpowers:subagent-driven-development` (or `superpowers:executing-plans` inline). At most 6 implementer subagents, one heavy command at a time, their work verified against `git status` and `git diff`.
4. `frontend-design:frontend-design`, `impeccable:impeccable` and `taste-skill:taste-skill` for the reading room, the transcript and the cast list (the highlighter is the skin's way of marking the voice: no bloom, no glow, no waveform art).
5. `superpowers:verification-before-completion` before claiming done.

## Scope: deliver every item below

### A. Skin-neutral data layer (`frontend/src/features/novels/`, no pixels, first commits)

A1. **Extract playback** from `NovelAudioPlayer.tsx` into `use-narration.ts` (the Listen engine): one `HTMLAudioElement` per reader, the audio fetched as a blob through `loadNovelAudioObjectUrl` in `browserNovelAudioFormat()` (`m4a` where Ogg Opus cannot play, which covers iOS Safari), `503 audio_preparing` handled by waiting for `Retry-After` and retrying (state `preparing`), `audio.preservesPitch = true`, speed 0.50–3.00, `seekBy(±15 s)`, `seekToSegment(i)`, `seekToParagraph(p)` (`seekMsForParagraph`), the current segment (`segmentAt`), `highlightSafe` (the payload's `highlight_safe` and `timingMatchesText` against the text on screen), chapter-end events, and a `narrationActive` flag in a small store that `skins/*/sounds.ts` reads (if `web/02`'s `sounds.ts` already reads a flag, write that one). The legacy player switches to the hook in the same commit with no pixel change; its tests stay green.
A2. **Output graph**: on the first user play gesture create one `AudioContext`, route the narration element through `MediaElementAudioSourceNode` → `GainNode` → destination (the gain is what the sleep fade ramps, and what `web/23`'s soundscape ducking reads); if the context cannot start, play the element directly and skip the fade.
A3. **Word estimate** (`narration-timing.ts` + test): the spoken word is the word containing character offset `s + floor((t − start_ms) / (end_ms − start_ms) × (e − s))` inside the current segment `{p, s, e}`; it steps without animation. Also here: `sentenceRuns(paragraphs, segments)` (the transcript's sentences with their speaker and voice), `narrationWpm(wordCount, totalMs, speed)` (the `≈ 182 WPM` figure), `followDecision(activeTop, viewportHeight)` (inside 20–70 % do nothing; outside, scroll to put it at 38 %; more than 2 viewports away, jump).
A4. **Sleep timer** (`sleep-timer.ts` + test): `Off · 5 · 10 · 15 · 30 · 45 · 60 min · End of chapter · End of next chapter · Custom (1–180 min stepper)`; a live remaining-time value; the last 8 s ramp the gain to 0 (`gain.linearRampToValueAtTime(0, now + 8)`), then pause and restore the gain; "End of chapter" stops at the chapter end without the post-play card.
A5. **Listen sessions** (`listen-sessions.ts` + test): a session is a contiguous stretch of playback of one chapter; it closes on pause lasting 30 s, on chapter change, on leaving the reader and on `pagehide`; `seconds` is wall-clock playing time (not audio time), rounded; sessions under 10 s are dropped (§9.2.7 sends only sessions of 10 s or more, and `backend/03` rejects `seconds < 10`; the test includes a 7 s session that is never queued); `voice_ids` are the up-to-3 voices with the most played segment time; `started_at` ISO. Sessions queue in the profile-scoped `localStorage` outbox `mm.listen-outbox` (capped at 200) and flush as one `POST /novels/listen-sessions` array (≤ 200) on close, on `online`, and at reader start; the `pagehide` flush uses `fetch(…, { keepalive: true })` with the profile header. A 4xx other than 429 drops the batch; 429 and 503 keep it for the next flush.
A6. **Saved audio** (`audio-save.ts` + test): a separate download entry per chapter's audio, so it can be removed while the text stays: key `${chapterCacheKey(ref)}::audio`, `medium: "novel-audio"`, `payloadUrl` = the `GET /novels/audio` timing URL, `extraUrls` = [the timing URL, the `GET /novels/audio/file?…&format=` URL in the browser's format], no images, no document URL, carrying the same `mature` stamp `web/07` added to save requests. Add `"novel-audio"` to `SavedChapterMedium` and make `public/sw.js` keep that medium instead of defaulting it to `"novel"`. Playback offline reads the same URLs, so the service worker answers from the cache. "Unplayable" means the saved format fails `audio.canPlayType` on this browser.
A7. **Narration jobs** (`narration-jobs.ts` + test for the cadence): poll `GET /novels/audio/jobs?source&series` (per book) and `GET /novels/audio/jobs/active` (global) every 5 s, every 15 s while a job waits for the render PC, backing off to 60 s after failures; stop polling when no job is active and the sheet is closed. `useActiveNarrationJobs()` feeds `NarratingIndicator` (C10).
A8. **Casting mutations** through the existing hooks (`useSetNovelVoice` and friends; add what is missing): `POST /novels/cast {source_id, series_key, name, gender?, voice_id?}`, `POST /novels/cast/alias {alias, canonical}`, `POST /novels/narrator {voice_id | null}`, `POST /novels/audio/render {chapter_keys, priority, force}`; each invalidates attribution, `audio/series` and jobs.
A9. **Media Session** (`media-session.ts`): `navigator.mediaSession.metadata` with the series title (`title`), the chapter (`artist`: "Chapter 12 · The Tower"), the book (`album`), cover artwork at 256 and 512 px through the cover proxy's `?w=`; handlers `play`, `pause`, `seekbackward` and `seekforward` (15 s), `previoustrack`, `nexttrack`; `playbackState` kept in step; cleared when the reader unmounts. No dependency.

### B. Entry points (§8.16.1)

B1. The opener's `Listen │ 14 MIN` button (added to `web/14`'s `ChapterOpener`): a `split` secondary in the stock ink with `headphones`, and a small "audio saved" check when the audio is saved. It starts at the reading line's paragraph.
B2. `p` in the novel reader (play / pause), and the mini player's play.
B3. The book page's `Listen` secondary (render it in `web/11`'s book screen if it is not there, only when `GET /novels/audio/series` lists narrated chapters) and its `l` key: opens the reader at the resume point with `?listen=1` by the Column wipe; the reader calls `play()` on arrival; if the browser refuses (`NotAllowedError` on a cold load), the mini player shows paused with its play button focused.
B4. The Downloads row for saved audio (§8.16.1) is app-only: the web Downloads screen shows no saved-narration rows or controls (§8.23 "What the web cannot do is absent, not disabled: … saved narration audio"), so on the web saved audio is reached from the opener and the mini player's overflow (G). Export `useSavedAudio(ref)` anyway, because `web/17` must recognise the `novel-audio` entries A6 creates in order to keep them out of its lists and inside its byte totals.
B5. When the chapter has no audio, the Listen button is absent; the owner sees `NOT NARRATED` in the opener with a `quiet` `Narrate this chapter` sending `POST /novels/audio/render {chapter_keys: [key], priority: 9}`.

### C. The novel reader additions (in `web/14`'s screens)

C1. The top bar's voices button (`voice-31`, "Voices"), inserted after bookmark in the ordered button array; it opens the cast sheet.
C2. The voices line under the text, right-aligned: `VOICES IN THIS CHAPTER (5)` in `type-kicker` (stock muted), a button opening the cast sheet; present when the attribution has a cast or a narrator.
C3. The Margins panel's `VOICES` tab: the cast list (D5) inline, in the stock colours.
C4. **Mini player** (§8.16.2): a 56 px bar above the bottom bar, in the stock colours with a 1 px top rule (stock muted at 30 %):
   - a 36 px round `play` button (stock ink fill, the glyph in the page colour); states play, pause, preparing (16 px leader dial), failed (`!` in `proof`, tap retries);
   - centre: `CHAPTER 12 · READ BY IRIS` (`type-kicker`; the narrator voice's name) over a 2 px progress rule (played part stock ink, buffered part at 35 %);
   - right: the `−18:40` folio (`type-folio`, spoken "18 minutes 40 seconds left"); on desktop also `−15 s` and `+15 s` buttons and the speed folio `1.00×` (opens the speed sheet);
   - a tap on the centre opens the full player; a horizontal swipe on the bar (coarse pointers, 72 px or 600 px/s) goes to the next or previous chapter;
   - it rides with the chrome and lingers 5000 ms after the chrome hides, unless pinned: a 450 ms press toggles `Keep player visible` (the bar sets `-webkit-touch-callout: none; user-select: none` and the phone frame calls `preventDefault()` on its `contextmenu`, §8.0.5); the overflow (`dots-three`, "More") holds `Keep player visible`, `Sleep timer…`, `Voices…` and the audio save state (G);
   - the linger timer pauses while focus is inside the player (§14.5).
C5. **Following along on the page** while narration plays with the mini player: the active sentence gets a `spot.wash` band that sweeps in left → right over 200 ms (`dur.clip`) `ease.set` on every stock (implement as an inline `background-image: linear-gradient(var(--mm-color-spot-wash), var(--mm-color-spot-wash))` with `background-size` transitioning 0 % → 100 %, `box-decoration-break: slice`, so a multi-line sentence sweeps in reading order); the spoken word gets a 2 px underline in the stock ink that steps without animation; speaker tints keep their underline but drop their 12 % background under the band; the spoken paragraph is held at the reading line (38 %) by a 400 ms (`dur.glide`) `ease.settle` scroll that runs only when it leaves the 20–70 % band; a manual scroll decouples it and shows a `quiet` `Back to the voice ↓` in the stock colours above the mini player, and it re-follows after 4000 ms idle; under reduced motion the band appears at once and the scrolls jump. Withheld entirely when `highlightSafe` is false (the §8.15.9 stale text rule).
C6. Keys added to the novel keys reducer: `p` play / pause; `[` / `]` previous / next sentence; `Shift+[` / `Shift+]` back / forward 15 s; `<` / `>` Listen speed ±0.05× (`web/23` later gives them to auto-scroll while it runs); `Esc` order: close sheet → collapse the full player → back to the book. Tests for the reducer.
C7. `?listen=1` handling (B3).
C8. The "Auto-scroll and Listen never run together" rule is completed by `web/23`; expose `isPlaying` and `pause()` from the hook for it.
C9. The book page's owner-only `Audiobook` icon button (the `headphones` glyph, `aria-label` "Audiobook", tooltip "Narrate or save this book's audio"), rendered only for admins, opening the Audiobook sheet (J) with the Rise. The book page also opens the sheet on mount when the URL hash is `#audiobook` and the viewer is an admin (the Narration rows `web/17` puts in Downloads and Index link there); for a non-admin the hash is ignored.
C10. `NarratingIndicator`: `NARRATING 3 CHAPTERS` in `type-kicker` with a mini determinate rule (the average job progress), rendered when active jobs exist; `web/17` mounts it in Index and Downloads (export it; do not edit those screens here).

### D. Full player "The reading room" (§8.16.3)

D1. A takeover over the novel reader, pushed as a `?sheet=listen` history entry so browser back collapses it. Motion: the content Rises (translateY 24 px → 0 and fade, 360 ms `dur.rise` `ease.settle`); the background field (the duotoned cover) runs the Match cut from the mini player's rect to the full viewport over 480 ms `ease.turn` (the mini player has no separate cover square in §8.16.2, so its whole bar is the source rect; record this reading in the report); collapse reverses it (the reversed match cut, 336 ms `dur.match.back`). Swipe down on the takeover collapses it, finger-tracked, releasing with `spring.sheet` (`{ type: "spring", visualDuration: 0.48, bounce: 0 }`; dismiss past 30 % of the height or faster than 800 px/s). Reduced motion: 200 ms (`dur.clip`) cross-fades both ways; the drag still collapses and finishes with a 150 ms fade.
D2. Background: the series cover duotoned to `ambient.duo` (fallback `#B8B2A4`), `blur.card` (24 px), at **15 %** opacity over `#000000`, with `scrim-vignette` and the grain at 0.05 (art only, paused off screen, static under reduced motion).
D3. Head: kicker `NOW READING ALOUD` in `ink.60`; the series title in `type-headline` through `SetHeading` (the Letter set); the chapter title as the deck (`type-deck` `ink.60`); `quiet` `Done` (collapses). Under the head, when timings no longer match, the caption "Highlight paused: the text changed." (`type-caption`); audio keeps playing and the transcript shows unhighlighted.
D4. **Transcript** ("lyrics"): desktop, the centre 6 columns, sentences in Newsreader 22/32; phones full width, Newsreader 20/30. The active sentence is `ink.100` on the highlighter band that sweeps across it left → right in 200 ms `ease.set` when it becomes active; the spoken word gets a 2 px underline that steps; other sentences are `ink.60` at full opacity; dialogue sentences carry a small kicker above them with the speaker's name in their tint colour (`IRIS`, `DOKJA`, `type-kicker`). The active sentence is held at 38 % of the panel height; the view scrolls 400 ms `ease.settle` only when it leaves the 20–70 % band and jumps when it is 2 panels away. A manual scroll stops following and shows a `Back to the voice ↓` secondary pinned at the bottom of the transcript; it re-follows after 4000 ms idle. A tap or click on a sentence plays from it (`seekToSegment`). The transcript is a list of buttons for keyboard users (Enter plays from that sentence).
D5. **Transport** under the transcript, over `scrim-sole` (`position: relative`, `isolation: isolate`, `--scrim-fade: 64px`): a chapter ruler in time (§7.20 styling; drag seeks live, `spring.scrub` release, `aria-valuetext="12 minutes 5 seconds of 30 minutes"`), the `0:00` and `−18:40` folios, and the buttons previous chapter, `−15 s`, the round `play` (64 px desktop and tablet, 56 px phones), `+15 s`, next chapter.
D6. **Tiles**: three square outlined tiles (1 px `rule.2`, 88 px tall min), in a row on every width: `SPEED 1.00×` with `≈ 182 WPM` under it (opens E), `VOICES IRIS + 4` (opens F), `SLEEP END OF CH.` or the live countdown folio (opens H).
D7. The takeover traps focus, moves focus to `Done` on open and returns it to the mini player on collapse; it is a `role="dialog"` labelled "Now reading aloud, {series}".

### E. Speed ruler (§8.16.4)

A `[0.5]` sheet (desktop: a column panel per §7.9) with `web/13`'s `SpeedRuler`: a horizontal tick ruler 0.50–3.00× in 0.05 steps, labelled at 0.5, 1, 1.5, 2, 2.5, 3 (`type-folio`); the value previews while dragging (folio flag) and commits on release; preset slugs `0.8 · 1 · 1.25 · 1.5 · 2`; touch-and-hold anywhere on the ruler (desktop: double-click) resets to 1.00×; the WPM equivalent under the value. Pitch preserved. Saved per profile in the scoped `mm.listen-settings` (`speed`). Keys `<` / `>` ±0.05×.

### F. Voices and the cast (§8.16.5)

F1. **Cast sheet** (the voices button, the voices line, the `VOICES` tile): a credits list with dot leaders (§7.16 credits rows):
   - `Narrator ........................ Iris` pinned first (tap to choose the narration voice);
   - `Kim Dokja ■ .................... Arlo · 34 %`: a 10 px square of the speaker's tint, the voice, the share of lines, a lock mark when set by hand (`locked`); rows ordered by line count;
   - status lines above the list: "Looking up who speaks here…", "Nobody else was identified with enough confidence, so the narrator reads every line.", "Narrated by {name}: their own lines use the narrator's voice.";
   - owner-only row overflow: `Same character as…` (a list of the other names → `POST /novels/cast/alias`) and `Set gender` (`MALE │ FEMALE │ UNKNOWN` → `POST /novels/cast` with `gender`); non-owners see the list read-only (voice names, no pickers, no overflow);
   - a row shows `RE-VOICING` (`type-micro`) while the book has an active render job created after that character's last cast change;
   - after any cast or narrator change, the owner sees a `quiet` `Re-narrate 38 chapters` in the footer (the count = narrated chapters whose `rendered_at` is older than `cast_changed_at`), opening the Audiobook sheet (J) with `RE-VOICE` selected; nothing re-renders until it is sent.
F2. **Voice picker, "the cast list of 31"** (from a cast row, filtered to the character's gender; exported for `web/18`'s Settings → Listen → Voices):
   - masthead: kicker `A VOICE FOR KIM DOKJA`, filters `ALL · FEMALE ¹⁸ · MALE ¹³ · IN USE` as a single-select slug line (the counts come from `GET /novels/voices`; never hard-code 18 and 13), a compact search by name;
   - desktop: two columns `MALE` and `FEMALE`, each in the server's order (deepest first); phones: one column with the genders as section heads;
   - top row `Automatic` ("Assigned by gender and speaking order") and, in the narrator picker, `Book default`;
   - each **voice row** (64 px min): a 40 px monogram circle (`radius.round`) filled with `voiceMonogramField(pitch_hz)` (HLS L 0.28, S 0.45, hue linear from 220° at 80 Hz to 30° at 300 Hz, clamped) and the initial in `ink.100`; the name in Bodoni Moda Italic 20; the `character` descriptor in `type-caption`; a **pitch scale** (an 80–300 Hz hairline ruler with a `spot` tick at `pitch_hz`, labelled "Deeper" and "Brighter" for screen readers); an **expressiveness meter** of five 6 × 6 squares filled `ink.100` by the voice's rank among the loaded voices (`ceil(5 × rank / n)`, because `expressiveness` is a raw pitch spread with no fixed range); actions `Hear` (secondary sm) and `Cast` (the selected voice reads `CAST`, filled);
   - **`Hear`** plays `GET /novels/voices/sample?voice={id}&format=` (the browser's format) as a blob in an `<audio>` element routed into a Web Audio `AnalyserNode` (`fftSize` 256); the button shows a leader dial while fetching and reads `Stop` while playing; only one sample plays at a time; it pauses narration while it plays and resumes it when the sample stops;
   - **the sample pulses with the voice**: while it plays, a highlighter band in `color.spot` at alpha = 0.08 + 0.24 × RMS sits behind the voice's name (RMS 0–1 from `getFloatTimeDomainData` each animation frame, smoothed with an 80 ms attack and a 240 ms release: `a = 1 − exp(−dt / τ)`), and a 2 px `spot` rule under the row runs left → right with the sample's progress; reduced motion: a static `color.spot` band at alpha 0.20 while it plays; no bloom and no glow;
   - **caption**: while a sample plays, the voice's `transcript` appears under its row in `type-caption` `ink.60` in a polite live region, collapsing when it stops;
   - footer caption "Chapters already rendered keep the voice they were made with until they're rendered again."; license and attribution per voice under `Details` in the row's overflow;
   - casting posts `POST /novels/cast` (character) or `POST /novels/narrator` (narrator), sound `set` if on; error toast "That voice couldn't be saved." with the server's reason (6000 ms, `proof` edge);
   - empty: "No voices are installed on the server, so characters can't be cast from here yet.";
   - put `voiceMonogramField` in `skins/cinematic/tint.ts` and fill the `VOICE_FIELD_ROWS` array `web/04` left empty in `tint.test.ts` (one row per pitch 80, 100, 120 … 300 Hz plus the 60° worst case): `ink.100` on each field is ≥ 4.5:1 (5.13:1 at 60°); put the pulse smoothing in `voice-pulse.ts` with a test.

### G. Saved audio on the device (§8.16.9)

The mini player's overflow and the opener show the audio save state: `Save audio to this device` → saving (16 px leader dial) → `Audio saved` (check) → a tap asks "Remove saved audio? The chapter stays on this device to read." (destructive, the 1000 ms arm) / failed "Couldn't save the audio. Tap to try again." / unplayable "The saved audio can't play on this device. Tap to save it again." A first request answered `503 audio_preparing` shows "Preparing the audio…" with a leader dial and retries after `Retry-After`. Rendered only when a downloads scope exists (`useStorageScope()`).

### H. Sleep timer (§8.16.6)

`SLEEP` (tile or overflow) opens a list sheet with the A4 options (Custom opens a minutes stepper, 1–180, step 1); the tile and the mini player show the live countdown folio (`12:04`); the last 8 s fade the volume out; the web has no shake (the "Shake to extend" setting is app-only).

### I. Chapter boundary (§8.16.7)

At the end of a chapter's audio: a **post-play card** at the bottom of the transcript (and, when the full player is collapsed, above the mini player in the stock colours): kicker `NEXT`, `Chapter 13` typed at 50 ms per character (`TypedHeadline`), a 40 px countdown dial (a `spot` sweep over 5000 ms, `dur.countdown.next`, one pass; reduced motion: no sweep, a `5 S` … `1 S` folio updated once per second), `Play now` (primary) and `Cancel` (quiet). When the countdown completes (it pauses while focus or the pointer is inside the card, §14.5), playback continues into chapter 13 and the reader swaps the text in place (`useNovelReader().next()`, the seamless next of `web/14`). With the sleep timer at "End of chapter" the card is skipped and playback stops; "End of next chapter" lets one boundary pass. This also works in paged mode (the new chapter re-paginates and opens at page 1).

### J. Audiobook: narrate and save (§8.16.8, owner)

J1. Only the owner (an admin account) sees the `Audiobook` button (C9); for everyone else it is not rendered.
J2. The sheet: kicker `AUDIOBOOK`; segmented `NARRATE │ SAVE TO THIS DEVICE` (Save only when a downloads scope exists); quick picks as a slug line `NEXT 10 · ALL UN-NARRATED ⁽³⁸⁾ · RE-VOICE ⁽ⁿ⁾ · NONE` (in SAVE: `NEXT 10 · ALL NARRATED · NONE`); `RE-VOICE` selects the narrated chapters whose `rendered_at` is older than the book's `cast_changed_at` and is absent when there are none.
J3. A checklist of chapters (virtualised) with status captions: NARRATE `ALREADY NARRATED · SAVED`, `ALREADY NARRATED`, `DOWNLOAD THE TEXT FIRST`; SAVE `SAVED`, `SAVED COPY CAN'T PLAY ON THIS PHONE`, `SAVING…`, `COULDN'T BE SAVED`, `NARRATED`, `NOT NARRATED YET`. In NARRATE, already-narrated chapters are selectable and captioned `ALREADY NARRATED · WILL BE RE-VOICED` when selected.
J4. An estimate caption: "About 9 minutes of rendering per chapter on the narration PC." (NARRATE) / "Saves while the app is open; the text is saved too." (SAVE).
J5. The primary `Narrate 12 chapters` sends `POST /novels/audio/render {chapter_keys, priority: 0, force: true}` for the already-narrated keys and `force: false` for the rest (one request per group, ≤ 200 keys each); `Save audio of 12 chapters` queues A6 saves (the text is saved too, through `buildNovelSaveRequest`).
J6. When jobs exist: a job list with a determinate rule per job (queued, planning, rendering with progress, done, failed with the error, cancelled) and `Cancel` per job (`DELETE /novels/audio/jobs/{job_id}`, caption "It stops shortly."). `narration_unavailable` (503): the caption "Narration of new chapters isn't available right now. Chapters that already have audio can still be saved."

### K. States (§8.16.11) — every one

Preparing (`503 audio_preparing`: "Preparing the audio…" and a leader in the play button), playing, paused, buffering (a leader in the play button), failed ("Audio couldn't be loaded." + `Retry`), no audio for this chapter (B5), highlight paused (D3; C5 withheld), offline with saved audio (plays), offline without saved audio ("This chapter's audio isn't saved on this device."), voices unavailable (the F2 empty copy and an empty cast list).

### L. Gestures (§8.16.12, §11)

Swipe down on the full player collapses it (finger-tracked, `spring.sheet`); swipe the mini player sideways to change chapter; tap a transcript sentence to play from it; press and hold on the speed ruler resets to 1.00×; drag on the Listen chapter ruler seeks; a 450 ms press on the mini player toggles `Keep player visible`. Each has its §11 alternative (the transport buttons, `Done`, the `1.00` preset, the overflow items).

## Out of scope here (owned by later steps)

- `web/17`: mounting `NarratingIndicator` in Index and Downloads, and keeping the `novel-audio` entries out of the Downloads lists (the web has no saved-audio rows, B4).
- `web/18`: Settings → Listen (voices entry, default speed, follow-along options) using the exported picker.
- `web/21`: the Annual's `NARRATED BY` colophon (fed by the sessions you report).
- `web/23`: auto-scroll in the novel reader and its mutual exclusion (`PAUSED FOR LISTEN`), the soundscape and its ducking to 30 % under narration through A2's gain graph.
- App-only: the lock screen, `audio_service`, `sensors_plus` shake, the audio-session states.

## File layout

```
frontend/src/features/novels/use-narration.ts               A1, A2 (legacy NovelAudioPlayer.tsx switched to it)
frontend/src/features/novels/narration-timing.ts (+ test)   A3
frontend/src/features/novels/sleep-timer.ts (+ test)        A4
frontend/src/features/novels/listen-sessions.ts (+ test)    A5
frontend/src/features/novels/audio-save.ts (+ test)         A6
frontend/src/features/novels/narration-jobs.ts (+ test)     A7
frontend/src/features/novels/hooks.ts (extended)            A8
frontend/src/features/novels/media-session.ts               A9
frontend/src/features/offline/types.ts, frontend/public/sw.js   the "novel-audio" medium
frontend/src/skins/cinematic/screens/listen/
  ListenButton.tsx       B1, B5
  MiniPlayer.tsx         C4
  FollowAlong.tsx        C5 (page highlighting through web/14's ChapterBody)
  ReadingRoom.tsx        D1–D3, D7
  Transcript.tsx         D4
  Transport.tsx          D5
  ListenTiles.tsx        D6
  SpeedSheet.tsx         E
  CastSheet.tsx          F1
  VoicePicker.tsx, VoiceRow.tsx, voice-pulse.ts (+ voice-pulse.test.ts)   F2
  AudioSaveState.tsx     G
  SleepSheet.tsx         H
  PostPlayCard.tsx       I
  AudiobookSheet.tsx     J
  NarratingIndicator.tsx C10
frontend/src/skins/cinematic/screens/novel/*                 C1–C3, C6, C7 insertions
frontend/src/skins/cinematic/screens/<book page from web/11>  B3, C9 insertions
frontend/src/skins/cinematic/tint.ts (+ tint.test.ts)        voiceMonogramField
frontend/e2e/fixtures/listen/                                make-fixtures.mjs and its outputs (proof only)
docs/redesign/proof/web-15/                                  plan.md, screenshots, report.md
```

## Acceptance criteria

- [ ] The extraction commit changes no legacy pixels and every existing novel and audio test passes.
- [ ] Every entry point of §8.16.1 available on the web starts playback at the right place: the opener's split button, `p`, the mini player, the book page's `Listen` (with the Column wipe and `?listen=1`, and the paused-and-focused fallback on a cold load).
- [ ] The mini player matches C4 (56 px, stock colours, 36 px play with four states, `CHAPTER 12 · READ BY IRIS`, buffered part at 35 %, desktop ±15 s and speed folio, 5000 ms linger, `Keep player visible`).
- [ ] Following along on the page: the band sweeps in 200 ms, the word underline steps, tints drop their background under the band, the paragraph is held at 38 % only when it leaves 20–70 %, manual scroll shows `Back to the voice ↓` and re-follows after 4000 ms; nothing is highlighted when timings are stale.
- [ ] The reading room: 15 % duotone field with vignette and grain, the Letter-set title, the transcript at 22/32 (desktop) and 20/30 (phone) with speaker kickers in tint colours, the transport over `scrim-sole`, the three 88 px tiles, the swipe-down collapse, browser back collapses, `Esc` collapses.
- [ ] Speed: 0.50–3.00 in 0.05 steps, presets, hold (or double-click) to reset, WPM shown, pitch preserved, `<` / `>` ±0.05×.
- [ ] Cast sheet and voice picker: the narrator pinned first, rows by line count with share and lock, owner-only overflow actions, read-only for non-owners, filters with counts from the server, two columns on desktop and one on phones, monogram colours from pitch, pitch scale, expressiveness meter, `Hear` with the RMS pulse and transcript caption, `CAST` state, `RE-VOICING`, `Re-narrate 38 chapters` opening the Audiobook sheet with `RE-VOICE`.
- [ ] Sleep timer: every option, a live countdown in the tile and the mini player, the 8 s fade, End of chapter skipping the post-play card.
- [ ] Chapter boundary: the post-play card types `Chapter 13`, counts 5 s on the dial (a folio countdown under reduced motion), `Play now` and `Cancel` work, and the text swaps in place in scroll and paged modes.
- [ ] Audiobook sheet (owner only): segments, quick picks with `RE-VOICE` computed from `rendered_at` < `cast_changed_at`, every status caption, `force: true` only for already-narrated keys, `priority: 0` (and `priority: 9` from the opener), the job list with `Cancel`, the `narration_unavailable` caption.
- [ ] Saved audio: save, remove (with the 1000 ms arm), failed, unplayable and preparing states; with the network offline in Playwright, saved audio plays and unsaved audio shows its copy.
- [ ] Listen sessions: a Playwright check sees one `POST /novels/listen-sessions` with the right `seconds`, `voice_ids` (≤ 3) and `started_at` after playing, pausing 30 s and leaving; an offline session is sent after reconnecting.
- [ ] Media Session: `navigator.mediaSession.metadata` is set while playing and the handlers work (checked in Playwright by invoking them through `navigator.mediaSession` in the page).
- [ ] UI sounds are silent while narration plays.
- [ ] Keyboard: `p`, `[`, `]`, `Shift+[`, `Shift+]`, `<`, `>`, `Esc` all work; every control in the player, sheets and picker is reachable by `Tab`; the transcript sentences are buttons; focus returns to the mini player on collapse.
- [ ] Hit targets: every control is ≥ 44 × 44 px on a coarse pointer and ≥ 32 × 32 px on desktop (Playwright `getBoundingClientRect()` check), including the mini player's buttons and the picker's `Hear` and `Cast`.
- [ ] Reduced motion: the match cut and Rise become 200 ms cross-fades, the highlight band appears at once, follow scrolls jump, the voice pulse is a static 0.20 band, the countdown is a folio, the Letter set a 200 ms fade, the typed title appears whole; leader dials keep running.
- [ ] Per-skin difference: with `mm-skin-debug=legacy` the legacy audio player, cast panel and voice picker still work at the same URLs.
- [ ] `npm run typecheck`, `npm run lint`, `npm run test`, `npm run build` in `frontend/` are green, with counts at or above the precondition floor plus the new tests.

## Verification

**RAM guard.** Before every heavy command run `free -m`; if the `available` figure of the `Mem:` row is under 1024 MB, stop and report. Never run two builds at once, never `next build` while `next dev` runs, one heavy command at a time.

From `frontend/`:

```bash
free -m && npm run typecheck
free -m && npm run lint
free -m && npm run test
free -m && npm run build
```

Lint and build stay at 0 errors and 0 warnings (`00-baseline.md`). This step changes nothing under `mobile/` or `backend/`. Prove it on your own commits, not on a range (the mobile, backend and shared sessions push to the same branch in parallel, so a range diff shows their work too): `for c in <each commit SHA you made in this step>; do git show --name-only --format= "$c"; done | grep -E '^(mobile|backend)/'` must print nothing. The other suites are therefore not re-run here; their sessions run them and keep the baseline: `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze` (No issues found), `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter test` (all 2012 passed) and `cd backend && .venv/bin/python -m pytest -q --no-header`.

**Fixtures.** The dev stack has no narration PC and may have no voice pack. Write `frontend/e2e/fixtures/listen/make-fixtures.mjs` (Node 22 stdlib only; run it with `node`) that generates: `chapter.wav` (a 60 s 8 kHz 16-bit mono WAV of a tone with a slow amplitude envelope, so the pulse and progress are visible), `sample-<voice_id>.wav` (3 s tones at each voice's pitch), `audio.json` (segments `{i, start_ms, end_ms, p, s, e, voice, speaker, speech}` aligned to `web/14`'s fixture chapter, `highlight_safe: true`), `audio-stale.json` (`highlight_safe: false`), `audio-series.json` (chapters with `rendered_at`, and `cast_changed_at` later than two of them), `voices.json` (31 voices named `Voice 01` … `Voice 31`, 13 `male` and 18 `female`, pitches spread over 80–300 Hz and served deepest first within each gender, each with a one-line `transcript`), `attribution.json` (a narrator and four speakers) and `jobs.json`. Use the live endpoints whenever the dev stack answers them (`GET /novels/voices` returning voices, a narrated chapter), and the fixtures only for what it cannot serve; say which in the report. Install them with the `--fixtures` option of `frontend/scripts/proof.mjs` that `web/14` added.

**Visual proof.** Start the dev stack with `free -m && backend/scripts/dev_stack.sh start` (the dev stack of `backend/scripts/README-dev-stack.md`: uvicorn on 127.0.0.1:8010 against the dev SQLite under `/srv/manhwamaniacs/dev/data/`, never production data; the script already sets `MM_NOVELS_ENABLED=true`, turns rate limits off and leaves the AI key unset; run `backend/scripts/dev_stack.sh seed` once if the `demo` account does not exist yet), then the web client with `cd frontend && free -m && NEXT_PUBLIC_API_URL=/api BACKEND_INTERNAL_URL=http://127.0.0.1:8010 npx next dev -p 3010` (both variables are required: without `NEXT_PUBLIC_API_URL=/api` the browser calls `http://127.0.0.1:8000` directly (`src/config/env.ts`), and without `BACKEND_INTERNAL_URL` the `/api` rewrite in `next.config.ts` targets port 8000). Sign in as the seeded admin `demo` for the owner views, and for the read-only cast view as a non-admin account that the spec creates in its setup (`POST /auth/register` with the username `proof-reader` and a password generated at run time; the dev stack runs with registration open) and deletes as the admin in its teardown through the endpoint `useDeleteMember` calls (the seed has only the one account). Capture in the named session `web-15`, skin `cinematic` via `mm-skin-debug`, at 1440 × 900 and 390 × 844 (touch emulation on the phone), into `docs/redesign/proof/web-15/`:

- `mini-player-{desktop,phone}.png`, `mini-player-preparing-desktop.png`, `mini-player-failed-desktop.png`, `follow-along-{desktop,phone}.png` (captured mid-sweep and at rest), `back-to-the-voice-phone.png`.
- `reading-room-{desktop,phone}.png`, `reading-room-dialogue-kickers-desktop.png`, `reading-room-highlight-paused-desktop.png`, `reading-room-post-play-{desktop,phone}.png`.
- `speed-sheet-{desktop,phone}.png`, `sleep-sheet-phone.png`, `sleep-countdown-tile-desktop.png`.
- `cast-sheet-owner-desktop.png`, `cast-sheet-readonly-phone.png`, `voice-picker-{desktop,phone}.png`, `voice-picker-hear-pulse-desktop.png` (mid-sample, with the transcript caption), `voice-picker-empty-desktop.png`, `re-narrate-footer-desktop.png`.
- `audiobook-narrate-desktop.png`, `audiobook-save-phone.png`, `audiobook-jobs-desktop.png`, `audiobook-unavailable-desktop.png`, `book-page-listen-desktop.png`.
- `audio-save-states-phone.png` (saving, saved, remove arming), `offline-no-audio-phone.png`, `opener-not-narrated-owner-desktop.png`.
- `reduced-motion-reading-room-desktop.png`, `legacy-audio-player-desktop.png`.
- `sessions-log.json` (the captured `POST /novels/listen-sessions` bodies) and `docs/redesign/proof/web-15/report.md` mapping each file to its acceptance item.

Stop `next dev` and the dev stack afterwards.

## Git

- Branch `feat/vps-slim-source-native`; the extraction first as its own no-pixel commit, then each data-layer module with its test, the service-worker medium, then each screen part, then fixtures and proof. Stage paths explicitly, never `git add -A` or `git add .`.
- No Claude or AI attribution anywhere (no `Co-Authored-By`, no "Generated with"); never commit secrets or `.claude/`.
- `npm run build` (after `free -m`) before every push; `git push origin feat/vps-slim-source-native` after each working step.
- Never edit `backend/connectors/` or any backend file; never touch production containers or `/srv/manhwamaniacs/{app,data}`; do not deploy.

## Report back

1. Done items by scope letter A–L, and anything not done with the reason.
2. Screenshot folder `docs/redesign/proof/web-15/` and its file list; which data was live and which came from fixtures.
3. Test counts (vitest files and cases before and after), lint and build results, `free -m` before each build.
4. The exact API of `useNarration()` (state, commands, the gain node accessor and `isPlaying`/`pause()` for `web/23`), `useSavedAudio`, `useActiveNarrationJobs` and the exported `VoicePicker` props for `web/17` and `web/18`.
5. The listen-sessions evidence (`sessions-log.json` summary).
6. Interpretations made (the match-cut source rect of D1, the `RE-VOICING` condition, the expressiveness quintiles) and any place where `cinematic/DESIGN.md` overrode this file.
7. Open issues.

Next prompt: `docs/redesign/prompts/web/16-cinematic-discover-search-sources-dialogue.md`.
