# Mobile Cinematic Listen mode with the 31 voices and the lock screen

Track: mobile · Order 48 · Depends on: `docs/redesign/prompts/mobile/14-cinematic-novel-reader.md`, `docs/redesign/prompts/backend/06-reader-tints-panels-novel-audio.md`, `docs/redesign/prompts/backend/03-stats-streaks-annual-listen-sessions.md` · Web twin: `docs/redesign/prompts/web/15-cinematic-listen-mode.md` · Proof folder: `docs/redesign/proof/mobile-15/`

## Goal

Build Cinematic Listen mode, "The reading", in the Flutter app, inside the novel reader `mobile/14` built: every entry point, the mini player above the novel's bottom bar, the full player takeover "The reading room" with its transcript, the highlighter band that sweeps through the sentence being read (on the page and in the transcript), the speed ruler, the cast sheet and the voice picker for all 31 named voices (samples fetched with the authenticated client and played through `SoLoud.instance.loadMem` with the RMS pulse, `Hear`, cast assignment, `RE-VOICE` and `RE-VOICING` from `rendered_at`, `cast_changed_at` and `force`), the sleep timer with shake to extend (`sensors_plus` 7.1.0), the chapter boundary with its post-play countdown, the owner's Audiobook sheet (narrate and save), saved audio on the device (§8.16.9), the lock screen and background playback through `audio_service` 0.18.19 (notification small icon `ic_stat_mm`, accent `#F4D03F`), the audio-session states of cinematic §6, every state, the hardware keys, and listen sessions queued through a sqflite outbox and sent to `POST /novels/listen-sessions`. Audio is pre-rendered per chapter with measured segment timings: the player follows the text sentence by sentence and never guesses beyond the word estimate this file defines. First, the playback logic that lives in the widget `features/novels/widgets/novel_audio_player.dart` (which owns its own `just_audio` `AudioPlayer`) and in `novel_reader_screen.dart` moves into a skin-neutral controller in a no-pixel commit. Listen adds no ScreenId, so the Cinematic `PENDING` set does not change in this step.

## Read first

Read these completely before planning. Where this file and `docs/redesign/cinematic/DESIGN.md` disagree, `cinematic/DESIGN.md` wins; say so in the report.

1. `docs/redesign/inventory/00-decisions.md` (all; "novel TTS with 31 named voices", rich haptics, sound off by default).
2. `docs/redesign/stack-decision.md` §2.3 ("logic that lives in a widget moves first"), §2.6, §4 risks 1, 9 and 11.
3. `docs/redesign/cinematic/DESIGN.md`:
   - §2.1.1 (stock-painted panels: the mini player uses the stock's muted colour for `ink.45` roles; inside a `spot.wash` band `ink.45` and `ink.60` roles render `ink.80`), §2.1.2 (`color.spot` `#F4D03F`, `color.spot.wash` `rgba(244,208,63,0.16)`), §2.1.4 (the Listen full player row of the over-art table; `scrim.sole` under the transport; `scrim.vignette`), §2.1.5 (the duotone matrix and `CineAmbient`), §2.1.6 (speaker tints), §2.5 (`blur.card` 24 px), §7.25, and §2.1.1's note on the voice-monogram field.
   - §4.2 (`durClip` 200, `durGlide` 400, `durCountdownNext` 5000, `durRise` 360, `durMatchBack` 336, `durSpread` 480), §4.4 (`CineSprings.sheet` 576 ms, `CineSprings.scrub` 288 ms in Flutter), §4.5 rows Match cut, Rise, Highlight sweep, Countdown, Voice pulse, Letter set, Type; §4.6; §4.8 rows Listen countdown dial, Voice pulse, Highlight sweep, programmatic scrolls, Gestures.
   - §5 (`listen.toggle` = `rigid`, `voice.assign` = `impress`, `sleep.fade` = `soft`, `select`, `chapter.next` = `heavy`, `longpress.open` = `heavy`) and §6 (cues are suppressed while narration plays; `set` for `voice.assign`; the audio-session table: State A, State B, Voice sample).
   - §7.1 (the round `play` button 64 / 56 / 36 px, `split`, `secondary sm`), §7.9 (`CineSheetRoute`, detents), §7.10 (the 1000 ms arm), §7.11, §7.16 (credits rows with dot leaders), §7.18 (leader dial, countdown dial, determinate rule), §7.20, §7.21, §7.23, §7.29 (`folioLabel()`).
   - §8.0.5 ("Back inside modal states" item 2: collapse the Listen full player; `PopScope(canPop: false)` on iOS for that state), §8.15.2 (the opener, the voices line), §8.15.3 (the top bar voices button, the Margins VOICES tab, the mini player placement), §8.15.5 (auto-scroll and Listen never run together), §8.15.8 (keys), §8.15.9 (stale text withholds follow-along).
   - §8.16 entire (§8.16.1 to §8.16.12, including §8.16.10's native wiring and single init).
   - §8.18 (the book page's `Listen` secondary and the owner-only `Audiobook` button, "Rise to the audiobook sheet"), §8.30.2 row 05 (the Listen settings this step stores: default speed, sleep timer default, shake to extend, auto-play the next chapter, keep the player visible).
   - §10.1.6 (Flutter `SetHeading`: the full player's series title is a Letter set), §10.2.4 (Flutter `TypedHeadline`: the post-play card's chapter title is typed), §11 (rows: long-press on the mini player, press and hold on the Listen speed ruler, horizontal swipe on the mini player, swipe down on the full player, drag on the Listen chapter ruler, Shake), §14.1, §14.3, §14.4, §14.5 (timers wait while focus is inside; the Listen post-play countdown waits for screen-reader users), §14.9, §15.3 (packages: `flutter_soloud` 4.1.7 with `loadMem`, `audio_service` 0.18.19, `sensors_plus` 7.1.0), §15.5 (the `listen-sessions` and `audio/series` rows), §15.7, §15.8 (the iPhone audio-session log), §15.10 S14, §15.11 (ledger rows and fallbacks for `flutter_soloud`, `audio_service`, `sensors_plus`).
4. `docs/redesign/glass/DESIGN.md` §15.4 (the `paginateNovel` row: Listen continues across chapters in paged mode too) and §15.6 (the audio session row: one owner, `skin_audio.dart`; narration is State B on both skins).
5. `docs/redesign/inventory/mobile.md` S26 items 3, 4, 8, 13, 15, 16, 20, 23; N3 (Audiobook picker); N4 (Voices / cast panel); §5a K38, K39; §5d (novel playback speed is session-only today); §6b (narration follow, job polling); §6c (narration audio states).
6. `docs/redesign/inventory/capabilities.md` §19.3 and §19.4 (audio, jobs, voices, casting; `audio_preparing`, `narration_unavailable`; "iOS must use m4a"), §1 (error envelope, `Retry-After`, `X-Profile-Id`), §24.
7. `docs/redesign/00-baseline.md`.
8. The web twin `docs/redesign/prompts/web/15-cinematic-listen-mode.md`, and `docs/redesign/proof/web-15/report.md` when present.
9. `docs/redesign/proof/mobile-14/report.md` (the `NovelReaderController` API, the `NovelParagraph` decoration model, the novel keys reducer, the stock scope), `docs/redesign/proof/mobile-13/report.md` (`SpeedRuler`), and `docs/redesign/proof/mobile-02/report.md` (how `audio_service`, `flutter_soloud`, `sensors_plus`, `skin_audio.dart` and `skin_haptics.dart` were wired).
10. Code: `mobile/lib/features/novels/` (`widgets/novel_audio_player.dart`, `widgets/narration_save_button.dart`, `widgets/novel_cast_panel.dart`, `widgets/audiobook_picker_sheet.dart`, `utils/narration_playback.dart`, `utils/novel_audio_session.dart`, `utils/novel_speaking.dart`, `models/novel_audio.dart`, `models/novel_audio_format.dart`, `models/narration_save_state.dart`, `models/novel_cast.dart`, `providers/novel_audio_provider.dart`, `providers/novel_cast_provider.dart`, `providers/series_audio_provider.dart`, `repositories/novels_repository_impl.dart`), `mobile/lib/features/downloads/store/downloads_db.dart` (the schema version and the outbox tables), `mobile/lib/features/downloads/providers/progress_outbox_provider.dart` (the flush pattern to copy), `mobile/lib/core/network/dio_client.dart` and `network_connectivity.dart`, `mobile/lib/main.dart` (the `AudioService.init` call from `mobile/02`), `mobile/lib/skins/skin_audio.dart`, `mobile/lib/skins/cinematic/screens/novel/` and the book page screen from `mobile/11`, `mobile/android/app/src/main/AndroidManifest.xml` and `MainActivity.kt` (read only, to confirm `mobile/02`'s wiring). Backend, read only: `backend/routes/novels.py` (the exact payloads of `/novels/audio`, `/novels/audio/series` with `rendered_at` and `cast_changed_at`, `/novels/audio/render` with `force` and `priority`, `/novels/audio/jobs`, `/novels/audio/jobs/active`, `/novels/voices`, `/novels/voices/sample`, `/novels/cast`, `/novels/cast/alias`, `/novels/narrator`) and the listen-sessions route from `backend/03`.

## Preconditions

- `git log --oneline -30` shows the `mobile/14`, `backend/06` and `backend/03` commits. Check the backend pieces: `grep -rn "listen-sessions" backend/routes` and `grep -rn "cast_changed_at" backend/routes` each return a match. If either is missing, stop and report which prerequisite step has not run.
- `grep -n "audio_service\|flutter_soloud\|sensors_plus" mobile/pubspec.yaml` shows `audio_service: 0.18.19`, `flutter_soloud: 4.1.7` and `sensors_plus: 7.1.0` (added by `mobile/02`), and `grep -n "AudioService.init" mobile/lib/main.dart` returns a match. If a package is missing because its CI resolution gate failed, apply that package's fallback from cinematic §15.11 and say so in the report: without `flutter_soloud` the voice pulse becomes the static band and samples play through a second `just_audio` player; without `audio_service` narration stays foreground-only; without `sensors_plus` shake to extend is dropped.
- Run `free -m`, then `/srv/manhwamaniacs/dev/flutter/bin/flutter test` from `mobile/` once and record the passed count as your floor (never below the 2012 of `00-baseline.md`: every test that passed there must still pass).

## Skills to invoke

1. `superpowers:writing-plans` before any code; plan at `docs/redesign/proof/mobile-15/plan.md`.
2. `superpowers:test-driven-development` for the extraction and every pure helper (timing, sleep, sessions, shake, pulse smoothing, polling cadence, the handler's control mapping).
3. `superpowers:subagent-driven-development` (or `superpowers:executing-plans` inline). At most 6 implementer subagents, one heavy command at a time, their work verified against `git status` and `git diff`.
4. `impeccable:impeccable` and `taste-skill:taste-skill` for the reading room, the transcript and the cast list (the highlighter is the skin's way of marking the voice: no bloom, no glow, no waveform art); `frontend-design:frontend-design` only for the side-by-side review against the web twin's phone captures.
5. `superpowers:verification-before-completion` before claiming done.

## Scope: deliver every item below

### A. Skin-neutral data layer (`mobile/lib/features/`, no pixels, first commits)

A1. **Extract playback** into `mobile/lib/features/novels/controllers/narration_controller.dart` (a Riverpod `Notifier`): one `just_audio` `AudioPlayer` for the app (the same instance the `audio_service` handler wraps, A9); the source is the saved blob's playback copy (`narration_playback.dart`) when the chapter's audio is saved, otherwise `GET /novels/audio/file?source&series&chapter&format=` in the device's `NovelAudioFormat` (`m4a` on iOS, as today) with the `Authorization: Bearer` and `X-Profile-Id` headers; `503 audio_preparing` waits for `Retry-After` and retries (state `preparing`); speed 0.50–3.00 through `setSpeed` (pitch preserved; `setPitch` stays 1.0); `seekBy(±15 s)`, `seekToSegment(i)`, `seekToParagraph(p)`; the current segment (`segmentAt(position)`); `highlightSafe` (the payload's `highlight_safe` and the fingerprint check against the text on screen); chapter-end events; and `narrationActiveProvider` (true while narration plays or is paused inside the reader), which `skin_audio.dart` reads to suppress UI cues and to switch the audio session (A2). `NovelAudioPlayerBar`, `novel_speaking.dart` and the legacy reader switch to the controller in the same commit with no pixel change; `novel_audio_test.dart`, `novel_background_audio_test.dart`, `novel_speaking_test.dart` and the other novel tests stay green.
A2. **Audio session states** through `skin_audio.dart` (§6 table; glass §15.6): State B (`AudioSessionConfiguration.speech()`, `.playback` with mode `.spokenAudio`; Android `AUDIOFOCUS_GAIN`, usage media, content type speech) when narration starts; State A (`.ambient` + `.mixWithOthers`, no Android focus) restored when it stops or the reader closes; the Voice-sample state for A11. Confirm that `mobile/02` replaced the startup `configureNovelAudioSession()` (`AudioSessionConfiguration.speech()` app-wide) with State A; if it did not, replace it here, and make the legacy player enter State B through the controller when it plays.
A3. **Word estimate** `mobile/lib/features/novels/utils/narration_timing.dart` (+ test): the spoken word is the word containing character offset `s + floor((t − start_ms) / (end_ms − start_ms) × (e − s))` inside the current segment `{p, s, e}`; it steps without animation. Also `sentenceRuns(paragraphs, segments)` (the transcript's sentences with speaker and voice), `narrationWpm(wordCount, totalMs, speed)` (the `≈ 182 WPM` figure), `followDecision(activeTop, viewportHeight)` (inside 20–70 % do nothing; outside, scroll to put it at 38 %; more than 2 viewports away, jump).
A4. **Sleep timer** `sleep_timer.dart` (+ test with a fake clock): `Off · 5 · 10 · 15 · 30 · 45 · 60 min · End of chapter · End of next chapter · Custom (1–180 min, step 1)`; a live remaining time; the last 8 s ramp the player volume to 0 (`setVolume` stepped every 50 ms, linear) with haptic `sleep.fade` at the start of the ramp, then pause and restore the volume; "End of chapter" stops at the chapter end with no post-play card; "End of next chapter" lets one boundary pass.
A5. **Listen sessions** `listen_sessions.dart` (+ test): a session is a contiguous stretch of playback of one chapter; it closes on a pause lasting 30 s, on chapter change, on leaving the reader and on `AppLifecycleState.detached`; `seconds` is wall-clock playing time (not audio time), rounded; sessions under **10 s** are dropped (cinematic §9.2.7 "send only sessions with `seconds ≥ 10`"; `backend/03` validates `seconds >= 10` and rejects shorter rows); `voice_ids` are the up-to-3 voices with the most played segment time; `started_at` is ISO 8601 UTC. Closed sessions go into a new sqflite table `listen_session_outbox` in `downloads_db.dart` (`id INTEGER PRIMARY KEY AUTOINCREMENT, scope TEXT NOT NULL` (the `u{user}p{profile}` scope), `source_id TEXT, series_key TEXT, chapter_key TEXT, seconds INTEGER, voice_ids TEXT` (JSON), `started_at TEXT, created_at INTEGER`): raise `_dbVersion` by one from whatever it is when you start (3 at the baseline; an earlier step may have raised it), create the table in `onCreate` and as a new idempotent step in `_migrate` (`CREATE TABLE IF NOT EXISTS`; `_migrate` is what both `onUpgrade` and `onDowngrade` call, so every step there must stay idempotent and additive), and add a migration test from the previous version and for the downgrade-reopen path. The flush (`listen_session_outbox_provider.dart`, modelled on the progress outbox) sends the active profile's rows, oldest first, as one `POST /novels/listen-sessions` array of at most 200, at reader start, when a session closes (a 30 s pause, the chapter end or change, leaving the reader), on `AppLifecycleState.paused` (the app going to the background, §9.2.7; a session still playing in the background stays open and is sent when it closes), when connectivity returns (`network_connectivity.dart`) and on `AppLifecycleState.resumed`; a 2xx deletes the sent rows; a 4xx other than 429 deletes them (drops the batch); 429, 503 and network errors keep them.
A6. **Saved audio** on the device (§8.16.9), over the existing narration save (downloads store audio rows, `narration_save_state.dart`, `savedNarrationProvider`, `unplayableNarrationSavesProvider`): one `savedAudioStateProvider(ChapterRef)` exposing `none | preparing | saving | saved | failed | unplayable`; iOS requests `m4a`; a first request answered `503 audio_preparing` shows "Preparing the audio…" and retries after the server's `Retry-After`; the `mature` stamp `mobile/07` added to saved narration stays. Export it for `mobile/17`'s Downloads rows.
A7. **Narration jobs**: reuse the existing polling cadence (every 5 s; 15 s while every job only waits for the render PC; back-off to 60 s after failures); add `GET /novels/audio/jobs/active` to the repository and `activeNarrationJobsProvider`, which stops polling when no job is active and no Audiobook sheet is open. Test for the cadence.
A8. **Casting mutations** (repository + `novel_cast_provider.dart`): `POST /novels/cast {source_id, series_key, name, gender?, voice_id?}`, the new `POST /novels/cast/alias {source_id, series_key, alias, canonical}`, `POST /novels/narrator {source_id, series_key, voice_id | null}`, `POST /novels/audio/render {source_id, series_key, chapter_keys, priority, force}` (add `priority` and `force`), the new `DELETE /novels/audio/jobs/{job_id}`; each invalidates the attribution, `audio/series` and jobs providers. Repository tests on a fake Dio adapter.
A9. **Lock screen and background** (§8.16.10): `NarrationAudioHandler extends BaseAudioHandler with SeekHandler` in `mobile/lib/features/novels/services/narration_audio_handler.dart` (complete it if `mobile/02` created a stub; `AudioService.init` stays the single call in `main()` before `runApp`, reaching the tree as `audioHandlerProvider.overrideWithValue(handler)`):
   - `mediaItem`: `id` `source:series:chapter`, `title` "Chapter 12 · The Tower", `album` the book title, `artist` "Read by Iris" (the narrator voice's name), `artUri` the cover through the cover proxy at `?w=512`, `artHeaders` with the bearer and `X-Profile-Id`, `duration` from `total_ms`.
   - `playbackState` from the player's events: `controls: [MediaControl.rewind, playing ? MediaControl.pause : MediaControl.play, MediaControl.fastForward, MediaControl.skipToNext]`, `systemActions: {MediaAction.seek, MediaAction.seekForward, MediaAction.seekBackward}`, `androidCompactActionIndices: [0, 1, 2]`, the processing state mapped from `just_audio`.
   - Handlers: `play`, `pause`, `seek`, `rewind` (−15 s), `fastForward` (+15 s), `skipToNext` (the reader's next chapter, through the novel controller), `stop`.
   - The `AudioServiceConfig` in `main.dart` must read `androidNotificationIcon: 'drawable/ic_stat_mm'`, `notificationColor: Color(0xFFF4D03F)`, `androidNotificationChannelName: 'Listen'`, `fastForwardInterval` and `rewindInterval` `Duration(seconds: 15)`; correct only those fields if `mobile/02` wrote others.
   - Narration keeps playing with the screen locked and the app in the background while the novel reader route is mounted; leaving the reader stops it and removes the notification (`stop()`).
   - Unit test with a fake player: the media item fields, the controls, and that rewind and fastForward seek by exactly 15 s.
A10. **Shake to extend** `shake_detector.dart` (+ test with a fake event stream): subscribes to `sensors_plus` `userAccelerometerEventStream()` only while a sleep timer is in its last minute or its fade, and cancels the subscription otherwise; a shake is two peaks of magnitude above 25 m/s² within 600 ms; a shake adds 5 minutes, shows the toast "Sleep timer +5 min" and fires haptic `select`. Governed by the per-profile `shakeToExtend` setting (A12, default on).
A11. **Voice samples** `voice_sample_player.dart` in `features/novels/services/`: fetch the bytes with the app's authenticated Dio client from `GET /novels/voices/sample?voice={id}&format=ogg` (always `ogg`, on iOS too: the pack is Ogg Opus, which SoLoud 4.1.7 decodes itself, and it has no AAC decoder), `SoLoud.instance.loadMem('voice-sample-$id.ogg', bytes)`, play it with `SoLoud.instance.setVisualizationEnabled(true)`; while it plays, an `AudioData(GetSamplesKind.wave)` updated each `Ticker` frame (`updateSamples()`, then `getAudioData()`, 256 samples) gives RMS 0–1. Only one sample plays at a time; a sample pauses narration and resumes it when it stops; the audio session enters the Voice-sample state (`.playback` + `.duckOthers`; Android `AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK` through `AudioSession.setActive(true)`) and returns to the previous state after; the source is disposed after it stops; the last 8 samples' bytes stay in memory for the session. The smoothing lives in `mobile/lib/features/novels/utils/voice_pulse.dart` (+ test): attack 80 ms, release 240 ms, `a = 1 − exp(−dt / τ)`.
A12. **Listen settings** record `mobile/lib/features/novels/models/listen_settings.dart` + `providers/listen_settings_provider.dart`, per profile in SharedPreferences `mm.listen-settings.u{user}p{profile}` (JSON): `speed` 1.00, `sleepDefault` `off`, `shakeToExtend` true, `autoPlayNext` true, `keepPlayerVisible` false. Normalisers keep unknown fields; test. The Settings → Listen screen that edits them is `mobile/18`.

### B. Entry points (§8.16.1)

B1. The opener's `Listen │ 14 MIN` button (added to `mobile/14`'s `chapter_opener.dart`): a `split` secondary in the stock ink with `headphones`, and a small check when the audio is saved on the device. It starts at the reading line's paragraph. Haptic `listen.toggle`.
B2. `p` on a hardware keyboard (play / pause), and the mini player's play.
B3. The book page's `Listen` secondary (add it to `mobile/11`'s book screen if it is not there, only when `GET /novels/audio/series` lists narrated chapters): opens the reader at the resume point with `?listen=1` by the Column wipe (`extra: {'entry': 'wipe'}`); the reader calls `play()` when its first frame is laid out.
B4. The Downloads row for saved audio belongs to `mobile/17`; export `savedAudioStateProvider` and a `playSavedAudio(ChapterRef)` entry.
B5. The lock-screen and notification controls (A9).
B6. When the chapter has no audio, the Listen button is absent; the owner sees `NOT NARRATED` in the opener with a `quiet` `Narrate this chapter` that sends `POST /novels/audio/render {chapter_keys: [key], priority: 9}`.

### C. The novel reader additions (in `mobile/14`'s screens)

C1. The top bar's voices button (`voice-31`, "Voices"), inserted after bookmark in the ordered button list; it opens the cast sheet.
C2. The voices line under the text, right-aligned: `VOICES IN THIS CHAPTER (5)` in `type.kicker` (stock muted), a button opening the cast sheet, present when the attribution has a cast or a narrator.
C3. The tablet Margins panel's `VOICES` tab: the cast list (F1) inline, in the stock colours.
C4. **Mini player** (§8.16.2): a 56 px bar above the bottom bar, in the stock colours with a 1 px top rule (stock muted at 30 %):
   - a 36 px round `play` button (stock ink fill, the glyph in the page colour) with states play, pause, preparing (16 px leader dial), failed (`!` in `proof`, a tap retries);
   - centre: `CHAPTER 12 · READ BY IRIS` (`type.kicker`) over a 2 px progress rule (played part stock ink, buffered part at 35 %);
   - right: the `−18:40` folio (`type.folio`, spoken "18 minutes 40 seconds left") and an overflow `dots-three` ("More") holding `Keep player visible`, `Sleep timer…`, `Voices…` and the audio save state (G);
   - a tap on the centre opens the full player; a horizontal swipe on the bar (72 px or 600 px/s) goes to the next or previous chapter (`chapter.next`);
   - it rides with the chrome and lingers 5000 ms after the chrome hides unless pinned; a 450 ms press toggles `Keep player visible` (`longpress.open`); the linger timer pauses while focus is inside the player and never runs out while a screen reader runs (§14.5).
C5. **Following along on the page** while narration plays with the mini player (§8.16.2): the active sentence gets a `spot.wash` band that sweeps in left → right over 200 ms (`durClip`) `CineCurves.set`, painted as a `NovelParagraph` decoration across the sentence's line boxes in reading order (so a multi-line sentence sweeps line after line); the spoken word gets a 2 px underline in the stock ink that steps without animation; speaker tints keep their underline but drop their 12 % background under the band; the spoken paragraph is held at the reading line (38 %) by a 400 ms (`durGlide`) `settle` scroll that runs only when it leaves the 20–70 % band; a manual scroll decouples it and shows a `quiet` `Back to the voice ↓` in the stock colours above the mini player, and it re-follows after 4000 ms idle. In paged mode, when the active sentence moves to another page, the reader turns to that page with the chosen page turn (a manual turn decouples it the same way). Under reduced motion the band appears at once and scrolls and turns jump. Everything here is withheld when `highlightSafe` is false.
C6. Hardware keys added to `novel_keys.dart`: `p` play / pause; `[` / `]` previous / next sentence; `Shift+[` / `Shift+]` back / forward 15 s; `<` / `>` Listen speed ±0.05× (`mobile/23` gives them to auto-scroll while it runs); `Esc` order: close sheet → collapse the full player → back to the book. Tests for the reducer.
C7. `?listen=1` handling (B3).
C8. "Auto-scroll and Listen never run together" is completed by `mobile/23`; expose `isPlaying` and `pause()` from the controller for it. The novel controller's 900 ms auto-next stays suppressed while narration plays.
C9. The book page's owner-only `Audiobook` icon button (`headphones`, semantics "Audiobook", tooltip "Narrate or save this book's audio"), built only for admins, opening the Audiobook sheet (J) with the Rise.
C10. `NarratingIndicator`: `NARRATING 3 CHAPTERS` in `type.kicker` with a mini determinate rule (the average job progress), built when active jobs exist; export it for `mobile/17` (Index and Downloads); do not edit those screens here.

### D. Full player "The reading room" (§8.16.3)

D1. A takeover inside the novel reader route (an overlay state of the reader, not a new route), so Android back collapses it first (§8.0.5 item 2) and on iOS a `PopScope(canPop: false)` guards it while open (its `Done` and the swipe down are the way out). Motion: the content Rises (translateY 24 px → 0 and fade, 360 ms `durRise` `settle`); the background field runs the match cut from the mini player's rect to the full screen over 480 ms `CineCurves.turn` (the mini player has no separate cover square in §8.16.2, so its whole bar is the source rect; record this reading in the report); collapse reverses it over 336 ms (`durMatchBack`). A swipe down collapses it, finger-tracked, released with `SpringSimulation(CineSprings.sheet.description, …)` (576 ms): dismiss past 30 % of the height or faster than 800 px/s. Reduced motion: 200 ms cross-fades both ways; the drag still collapses and finishes with a 150 ms fade. While it is open the status bar is shown (`manual`, `[SystemUiOverlay.top]`).
D2. Background: the series cover duotoned to `ambient.duo` through `duotone.dart` (fallback `#B8B2A4`), `ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24))` (`blur.card`), at **15 %** opacity over `#000000`, with `scrimVignette` and the grain shader (`shaders/grain.frag`) at 0.05 on the art only, paused off screen (`TickerMode`) and static under reduced motion.
D3. Head: kicker `NOW READING ALOUD` in `ink.60`; the series title in `type.headline` through `SetHeading` (the Letter set); the chapter title as the deck (`type.deck` `ink.60`); `quiet` `Done` (collapses). When timings no longer match, the caption "Highlight paused: the text changed." (`type.caption`) under the head; audio keeps playing and the transcript shows unhighlighted.
D4. Transcript ("lyrics"): phones full width in Newsreader 20/30; tablets the centre 6 of the 8 columns in Newsreader 22/32 (the desktop value, §8.16.3). The active sentence is `ink.100` on the highlighter band that sweeps across it left → right in 200 ms `CineCurves.set` when it becomes active; the spoken word gets a 2 px underline that steps; other sentences are `ink.60` at full opacity; dialogue sentences carry a small kicker above them with the speaker's name in their tint colour (`IRIS`, `DOKJA`, `type.kicker`). The active sentence is held at 38 % of the panel height; the view scrolls 400 ms `settle` only when it leaves the 20–70 % band and jumps when it is 2 panels away. A manual scroll stops following and shows a `Back to the voice ↓` secondary pinned at the bottom of the transcript; it re-follows after 4000 ms idle. A tap on a sentence plays from it (`seekToSegment`, haptic `select`); each sentence is a semantics button.
D5. Transport under the transcript, over `scrimSole(bar, 64)`: a chapter ruler in time (§7.20 styling; drag seeks live, `CineSprings.scrub` release, semantics value "12 minutes 5 seconds of 30 minutes" with increase and decrease actions of 15 s), the `0:00` and `−18:40` folios, and the buttons previous chapter, `−15 s`, the round `play` (56 px on phones, 64 px on tablets), `+15 s`, next chapter.
D6. Tiles: three square outlined tiles (1 px `rule.2`, 88 px tall min) in a row: `SPEED 1.00×` with `≈ 182 WPM` under it (opens E), `VOICES IRIS + 4` (opens F1), `SLEEP END OF CH.` or the live countdown folio (opens H).
D7. Focus moves to `Done` on open and returns to the mini player on collapse; the takeover is `Semantics(scopesRoute: true, namesRoute: true, label: 'Now reading aloud, {series}')`.

### E. Speed ruler (§8.16.4)

A `CineSheetRoute` with the single detent `[0.5]`, holding `mobile/13`'s `SpeedRuler`: 0.50–3.00× in 0.05 steps, labelled at 0.5, 1, 1.5, 2, 2.5, 3 (`type.folio`); the value previews while dragging (folio flag) and commits on release; preset slugs `0.8 · 1 · 1.25 · 1.5 · 2`; touch-and-hold anywhere on the ruler resets to 1.00×; the WPM equivalent under the value; haptic `select` per 0.25× crossed. Pitch preserved. Saved per profile (`listen_settings.speed`). Keys `<` / `>` ±0.05×.

### F. Voices and the cast (§8.16.5)

F1. **Cast sheet** (the voices button, the voices line, the `VOICES` tile): a `CineSheetRoute`, credits rows with dot leaders (§7.16):
   - `Narrator ........................ Iris` pinned first (a tap opens the narrator picker);
   - `Kim Dokja ■ .................... Arlo · 34 %`: a 10 px square of the speaker's tint, the voice, the share of lines, a lock mark when set by hand (`locked`); rows ordered by line count;
   - status lines above the list: "Looking up who speaks here…", "Nobody else was identified with enough confidence, so the narrator reads every line.", "Narrated by {name}: their own lines use the narrator's voice.";
   - owner-only row overflow: `Same character as…` (a list of the other names → `POST /novels/cast/alias`) and `Set gender` (`MALE │ FEMALE │ UNKNOWN` → `POST /novels/cast` with `gender`); non-owners see the list read-only (voice names, no pickers, no overflow);
   - a row shows `RE-VOICING` (`type.micro`) while the book has an active render job created after that character's last cast change;
   - after any cast or narrator change, the owner sees a `quiet` `Re-narrate 38 chapters` in the footer (the count = narrated chapters whose `rendered_at` is older than `cast_changed_at`), opening the Audiobook sheet (J) with `RE-VOICE` selected; nothing re-renders until it is sent.
F2. **Voice picker, "the cast list of 31"** (from a cast row, filtered to the character's gender; exported for `mobile/18`'s Settings → Listen → Voices):
   - masthead: kicker `A VOICE FOR KIM DOKJA`, filters `ALL · FEMALE ¹⁸ · MALE ¹³ · IN USE` as a single-select slug line (the counts come from `GET /novels/voices`; never hard-code 18 and 13), a compact search by name;
   - phones: one column with the genders as section heads; tablets: two columns `MALE` and `FEMALE`, each in the server's order (deepest first);
   - top row `Automatic` ("Assigned by gender and speaking order") and, in the narrator picker, `Book default`;
   - each voice row (64 px min): a 40 px monogram circle filled with `voiceMonogramField(pitchHz)` (HLS L 0.28, S 0.45, hue linear from 220° at 80 Hz to 30° at 300 Hz, clamped) with the initial in `ink.100`; the name in Bodoni Moda Italic 20 (`CineType.literal`, cap 1.30); the `character` descriptor in `type.caption`; a pitch scale (an 80–300 Hz hairline ruler with a `spot` tick at `pitch_hz`, semantics "Deeper" to "Brighter"); an expressiveness meter of five 6 × 6 squares filled `ink.100` by the voice's rank among the loaded voices (`ceil(5 × rank / n)`, because `expressiveness` is a raw pitch spread with no fixed range); actions `Hear` (`secondary sm`) and `Cast` (the selected voice reads `CAST`, filled);
   - `Hear` plays the sample (A11); the button shows a 16 px leader dial while fetching and reads `Stop` while playing;
   - the sample pulses with the voice: while it plays, a highlighter band in `color.spot` at alpha 0.08 + 0.24 × RMS sits behind the voice's name, and a 2 px `spot` rule under the row runs left → right with the sample's progress; reduced motion: a static `color.spot` band at alpha 0.20; no bloom, no glow;
   - caption: while a sample plays, the voice's `transcript` appears under its row in `type.caption` `ink.60` in a `Semantics(liveRegion: true)` block, collapsing when it stops;
   - footer caption "Chapters already rendered keep the voice they were made with until they're rendered again."; licence and attribution per voice under `Details` in the row's overflow;
   - casting posts `POST /novels/cast` (character) or `POST /novels/narrator` (narrator), haptic `voice.assign` (`impress`), sound `set` if on; error toast "That voice couldn't be saved." with the server's reason (6000 ms, `proof` edge);
   - empty: "No voices are installed on the server, so characters can't be cast from here yet.";
   - put `voiceMonogramField` in `mobile/lib/skins/cinematic/tint.dart` and extend `tint_test.dart`: `ink.100` on the field at 80 Hz, 300 Hz and the 60° worst case is ≥ 4.5:1 (5.13:1 at 60°).

### G. Saved audio on the device (§8.16.9)

The mini player's overflow and the opener show the save state from A6: `Save audio to this device` → saving (16 px leader dial) → `Audio saved` (check) → a tap asks "Remove saved audio? The chapter stays on this device to read." (destructive, the 1000 ms arm; haptic `delete.confirm`) / failed "Couldn't save the audio. Tap to try again." / unplayable "The saved audio can't play on this device. Tap to save it again." / preparing "Preparing the audio…" with a leader dial. Built only when a downloads scope exists.

### H. Sleep timer (§8.16.6)

`SLEEP` (tile or overflow) opens a list sheet with the A4 options (Custom opens a minutes stepper, 1–180, step 1); the tile and the mini player show the live countdown folio (`12:04`); the last 8 s fade the volume out; shake to extend (A10) during the fade or the last minute.

### I. Chapter boundary (§8.16.7)

At the end of a chapter's audio: a post-play card at the bottom of the transcript (and, when the full player is collapsed, above the mini player in the stock colours): kicker `NEXT`, `Chapter 13` typed at 50 ms per character (`TypedHeadline`), a 40 px countdown dial (a `spot` sweep over 5000 ms, `durCountdownNext`, one pass; reduced motion: no sweep, a `5 S` … `1 S` folio updated once per second), `Play now` (primary) and `Cancel` (quiet). When the countdown completes, playback continues into chapter 13 and the reader swaps the text in place (the novel controller's seamless `next()`); in paged mode the new chapter re-paginates and opens at page 1. The countdown pauses while focus is inside the card and does not start while a screen reader runs (the card waits for `Play now`). With `autoPlayNext` off the card shows without the dial and waits. With the sleep timer at "End of chapter" the card is skipped and playback stops; "End of next chapter" lets one boundary pass.

### J. Audiobook: narrate and save (§8.16.8, owner)

J1. Only the owner (an admin account) sees the `Audiobook` button (C9). The sheet (a `CineSheetRoute`, content-fit up to 0.92) replaces N3 for the Cinematic skin; the legacy `AudiobookPickerSheet` stays for the legacy skin.
J2. Kicker `AUDIOBOOK`; segmented `NARRATE │ SAVE TO THIS DEVICE` (Save only when a downloads scope exists); quick picks as a slug line `NEXT 10 · ALL UN-NARRATED ⁽³⁸⁾ · RE-VOICE ⁽ⁿ⁾ · NONE` (in SAVE: `NEXT 10 · ALL NARRATED · NONE`); `RE-VOICE` selects the narrated chapters whose `rendered_at` is older than the book's `cast_changed_at` and is absent when there are none.
J3. A checklist of chapters (`ListView.builder`) with status captions: NARRATE `ALREADY NARRATED · SAVED`, `ALREADY NARRATED`, `DOWNLOAD THE TEXT FIRST`; SAVE `SAVED`, `SAVED COPY CAN'T PLAY ON THIS PHONE`, `SAVING…`, `COULDN'T BE SAVED`, `NARRATED`, `NOT NARRATED YET`. In NARRATE, already-narrated chapters are selectable and captioned `ALREADY NARRATED · WILL BE RE-VOICED` when selected.
J4. An estimate caption: "About 9 minutes of rendering per chapter on the narration PC." (NARRATE) / "Saves while the app is open; the text is saved too." (SAVE).
J5. The primary `Narrate 12 chapters` sends `POST /novels/audio/render {chapter_keys, priority: 0, force: true}` for the already-narrated keys and `force: false` for the rest (one request per group, ≤ 200 keys each); `Save audio of 12 chapters` queues the existing download queue's audio saves (the text is saved too). Haptic `tap.primary`.
J6. When jobs exist: a job list with a determinate rule per job (queued, planning, rendering with progress, done, failed with the error, cancelled) and `Cancel` per job (`DELETE /novels/audio/jobs/{job_id}`, caption "It stops shortly."). `narration_unavailable` (503): the caption "Narration of new chapters isn't available right now. Chapters that already have audio can still be saved."

### K. States (§8.16.11), every one

Preparing (`503 audio_preparing`: "Preparing the audio…" and a leader dial in the play button), playing, paused, buffering (a leader dial in the play button), failed ("Audio couldn't be loaded." + `Retry`), no audio for this chapter (B6), highlight paused (D3; C5 withheld), offline with saved audio (plays), offline without saved audio ("This chapter's audio isn't saved on this device."), voices unavailable (the F2 empty copy and an empty cast list), background and locked (the notification and lock-screen controls from A9).

### L. Gestures (§8.16.12, §11)

Swipe down on the full player collapses it (finger-tracked, `CineSprings.sheet`); swipe the mini player sideways to change chapter; tap a transcript sentence to play from it; press and hold on the speed ruler resets to 1.00×; drag on the Listen chapter ruler seeks; a 450 ms press on the mini player toggles `Keep player visible`; shake during the sleep timer's last minute extends it. Each has its §11 alternative (the transport buttons, `Done`, the `1` preset, the overflow items, the sleep sheet).

## Out of scope here (owned by later steps)

- `mobile/17`: mounting `NarratingIndicator` in Index and Downloads, the Downloads rows for saved audio.
- `mobile/18`: Settings → Listen (voices entry through the exported picker, default speed, sleep timer default, shake to extend, auto-play the next chapter, keep the player visible) on the A12 record.
- `mobile/21`: the Annual's `NARRATED BY` colophon (fed by the sessions you send).
- `mobile/23`: auto-scroll in the novel reader and its mutual exclusion (`PAUSED FOR LISTEN`), the soundscape and its ducking to 30 % under narration.

## File layout

```
mobile/lib/features/novels/controllers/narration_controller.dart        A1 (legacy player switched to it)
mobile/lib/features/novels/services/narration_audio_handler.dart        A9 (+ test)
mobile/lib/features/novels/services/voice_sample_player.dart            A11
mobile/lib/features/novels/utils/narration_timing.dart (+ test)         A3
mobile/lib/features/novels/utils/sleep_timer.dart (+ test)              A4
mobile/lib/features/novels/utils/listen_sessions.dart (+ test)          A5
mobile/lib/features/novels/utils/shake_detector.dart (+ test)           A10
mobile/lib/features/novels/utils/voice_pulse.dart (+ test)              A11
mobile/lib/features/novels/models/listen_settings.dart, providers/listen_settings_provider.dart (+ test)   A12
mobile/lib/features/novels/providers/listen_session_outbox_provider.dart (+ test)                          A5
mobile/lib/features/novels/providers/novel_audio_provider.dart, novel_cast_provider.dart, series_audio_provider.dart (extended)   A6–A8
mobile/lib/features/novels/repositories/novels_repository.dart, novels_repository_impl.dart (extended, + tests)                   A7, A8
mobile/lib/features/downloads/store/downloads_db.dart (+ migration test) the listen_session_outbox table
mobile/lib/skins/skin_audio.dart                                        A2 (only the state switches, if mobile/02 left them out)
mobile/lib/main.dart                                                    A9 (only the AudioServiceConfig fields, if they differ)
mobile/lib/skins/cinematic/screens/listen/
  listen_button.dart       B1, B6
  mini_player.dart         C4
  follow_along.dart        C5 (decorations for mobile/14's NovelParagraph, follow scrolling and page turns)
  reading_room.dart        D1–D3, D7
  transcript.dart          D4
  transport.dart           D5
  listen_tiles.dart        D6
  speed_sheet.dart         E
  cast_sheet.dart          F1
  voice_picker.dart, voice_row.dart                                     F2
  audio_save_state.dart    G
  sleep_sheet.dart         H
  post_play_card.dart      I
  audiobook_sheet.dart     J
  narrating_indicator.dart C10
mobile/lib/skins/cinematic/screens/novel/*                               C1–C3, C6–C8 insertions
mobile/lib/skins/cinematic/screens/<book page from mobile/11>           B3, C9 insertions
mobile/lib/skins/cinematic/tint.dart (+ tint_test.dart)                  voiceMonogramField
mobile/test/fixtures/listen/                                             audio.json, audio-stale.json, audio-series.json, voices.json, attribution.json, jobs.json
mobile/test/skins/cinematic/listen/                                      widget tests
docs/redesign/proof/mobile-15/                                           plan.md, screenshots, device-checklist.md, report.md
```

## Acceptance criteria

- [ ] The extraction commit changes no legacy pixels and every existing novel and audio test passes.
- [ ] Every entry point of §8.16.1 starts playback at the right place: the opener's split button, `p`, the mini player, the book page's `Listen` (Column wipe, `?listen=1`), and the lock-screen and notification controls.
- [ ] The mini player matches C4 (56 px, stock colours, 36 px play with four states, `CHAPTER 12 · READ BY IRIS`, buffered part at 35 %, `−18:40` spoken in full, the 5000 ms linger, `Keep player visible` on a 450 ms press, the sideways swipe).
- [ ] Following along: the band sweeps in 200 ms, the word underline steps, tints drop their background under the band, the paragraph is held at 38 % only when it leaves 20–70 %, a manual scroll shows `Back to the voice ↓` and re-follows after 4000 ms, paged mode turns to the active sentence's page; nothing is highlighted when timings are stale.
- [ ] The reading room: the 15 % duotone field with vignette and grain, the Letter-set title, the transcript at 20/30 (phone) and 22/32 (tablet) with speaker kickers in tint colours, the transport over `scrimSole`, the three 88 px tiles, the swipe-down collapse on the 576 ms spring, Android back collapses it first, `Esc` collapses it.
- [ ] Speed: 0.50–3.00 in 0.05 steps, presets, hold to reset, WPM shown, pitch preserved, `<` / `>` ±0.05×, `select` per 0.25×.
- [ ] Cast sheet and voice picker: the narrator pinned first, rows by line count with share and lock, owner-only overflow actions (alias and gender), read-only for non-owners, filters with counts from the server, one column on phones and two on tablets, monogram colours from pitch, the pitch scale, the expressiveness meter, `Hear` fetched with the authenticated client and played through `SoLoud.instance.loadMem` with the RMS pulse and the transcript caption, the `CAST` state, `RE-VOICING`, and `Re-narrate 38 chapters` opening the Audiobook sheet with `RE-VOICE`.
- [ ] Sleep timer: every option, a live countdown in the tile and the mini player, the 8 s fade with `sleep.fade`, End of chapter skipping the post-play card, and shake to extend adding 5 minutes only during the last minute or the fade (the accelerometer is not subscribed otherwise; verified by the fake-stream test).
- [ ] Chapter boundary: the post-play card types `Chapter 13`, counts 5 s on the dial (a folio countdown under reduced motion), `Play now` and `Cancel` work, it waits while a screen reader runs, and the text swaps in place in scroll and paged modes.
- [ ] Audiobook sheet (owner only): segments, quick picks with `RE-VOICE` computed from `rendered_at` < `cast_changed_at`, every status caption, `force: true` only for already-narrated keys, `priority: 0` (and `priority: 9` from the opener), the job list with `Cancel`, the `narration_unavailable` caption.
- [ ] Saved audio: save, remove (with the 1000 ms arm), failed, unplayable and preparing states; offline, saved audio plays and unsaved audio shows its copy.
- [ ] Listen sessions: a test drives play, a 30 s pause and leaving the reader, and sees one outbox row with the right `seconds`, `voice_ids` (≤ 3) and `started_at` (and a 7 s session produces no row), flushed as one `POST /novels/listen-sessions` array; an offline session is sent after connectivity returns; a 400 drops the batch and a 429 keeps it; the `downloads_db.dart` migration test passes from the previous version.
- [ ] Lock screen: the handler test proves the media item, the controls `rewind, play/pause, fastForward, skipToNext`, the compact indices `[0, 1, 2]`, and ±15 s seeks; `AudioServiceConfig` names `drawable/ic_stat_mm`, `Color(0xFFF4D03F)` and the channel `Listen`.
- [ ] Audio session: narration enters State B and leaving restores State A; a sample enters the Voice-sample state and returns to the previous one; UI cues are silent while narration plays.
- [ ] Hardware keyboard: `p`, `[`, `]`, `Shift+[`, `Shift+]`, `<`, `>`, `Esc` all work in widget tests; focus moves to `Done` on open and back to the mini player on collapse.
- [ ] Hit targets: every control in the player, sheets and picker (including `Hear` and `Cast`) is ≥ 44 × 44 under `TargetPlatform.iOS` and ≥ 48 × 48 under `TargetPlatform.android` (widget test).
- [ ] Reduced motion: the match cut and Rise become 200 ms cross-fades, the highlight band appears at once, follow scrolls jump, the voice pulse is a static 0.20 band, the countdown is a folio, the Letter set a 200 ms fade, the typed title appears whole; leader dials keep running.
- [ ] Per-skin difference: with `Edition (debug)` on `LEGACY` the legacy audio player bar, cast panel and audiobook picker still work, now on the extracted controller.
- [ ] `flutter analyze` reports no issues; `flutter test` passes at or above the floor plus the new tests.

## Verification

**RAM guard.** Before every heavy command run `free -m`; if the `available` figure of the `Mem:` row is under 1024 MB, stop and report. One heavy command at a time; never alongside a `next build`; no Gradle or Xcode on this box (CI builds the APK and the iOS dry run, which also prove the native `audio_service`, `flutter_soloud` and `sensors_plus` wiring still builds).

From `mobile/`:

```bash
free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze
free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter test test/features/novels test/features/downloads test/skins
free -m && /srv/manhwamaniacs/dev/flutter/bin/flutter test
```

`flutter analyze` reports "No issues found"; the full suite passes at or above the floor. This step changes nothing in `frontend/` or `backend/` (`git show --name-only --format= <hash> -- frontend backend` for each of your own commits (never a branch or range diff: parallel sessions commit on the same branch) is empty), so `npm run lint`, `npm run build` (in `frontend/`) and the backend pytest (`backend/.venv/bin/python -m pytest -q --no-header` from `backend/`) are not rerun, except the push rule under Git.

**Fixtures.** `mobile/test/fixtures/listen/`: `audio.json` (segments `{i, start_ms, end_ms, p, s, e, voice, speaker, speech}` aligned to `mobile/14`'s fixture chapter, `highlight_safe: true`, `total_ms` 60000), `audio-stale.json` (`highlight_safe: false`), `audio-series.json` (chapters with `rendered_at`, and a `cast_changed_at` later than two of them), `voices.json` (31 voices named `Voice 01` … `Voice 31`, 13 `male` and 18 `female`, pitches spread over 80–300 Hz and ordered deepest first within each gender, each with a one-line `transcript`), `attribution.json` (a narrator and four speakers) and `jobs.json` (one queued, one rendering at 0.4, one failed). Playback, SoLoud and `audio_service` are faked through provider overrides in widget tests and the harness; no real audio plays on this box.

**Proof output location.** The `mobile/03` harness (`mobile/test/screenshots/support/skin_shots.dart`) writes a capture only when `MM_PROOF_DIR` is set, so every proof command below sets `MM_PROOF_DIR=../docs/redesign/proof/mobile-15` (relative to `mobile/`) and never `MM_WRITE_SHOTS`, which makes the legacy marketing tests overwrite `mobile/docs/screenshots/`, the install page's public screenshots. Capture routes with `captureSkinScreen` and anything that is not a route (a sheet held open, a state pumped with fixture providers) with `captureSkinWidget`, at the harness sizes: `kSkinShotSizes` (phone 390 × 844, tablet 834 × 1194), `kSkinShotTabletWide` (1024 × 1366, the ≥ 900 px rows of §8.0.9) and `kSkinShotLandscape` (landscape phone 844 × 390). After the run, `git status --short mobile/docs/screenshots` must print nothing.

**Visual proof.** In the harness `mobile/03` extended (`grep -rln "docs/redesign/proof" mobile/test/screenshots`), add a `mobile-15` group over the fixtures (signed in as the seeded admin for owner views, and as a non-admin for the read-only cast view) and run `free -m && MM_PROOF_DIR=../docs/redesign/proof/mobile-15 /srv/manhwamaniacs/dev/flutter/bin/flutter test test/screenshots/marketing_screenshots_test.dart --plain-name "mobile-15"` at phone 390 × 844 and tablet 834 × 1194, into `docs/redesign/proof/mobile-15/`:

- `mini-player-{phone,tablet}.png`, `mini-player-preparing-phone.png`, `mini-player-failed-phone.png`, `follow-along-{phone,tablet}.png` (mid-sweep and at rest), `follow-along-paged-phone.png`, `back-to-the-voice-phone.png`.
- `reading-room-{phone,tablet}.png`, `reading-room-dialogue-kickers-phone.png`, `reading-room-highlight-paused-phone.png`, `reading-room-post-play-{phone,tablet}.png`, `post-play-above-mini-player-phone.png`.
- `speed-sheet-phone.png`, `sleep-sheet-phone.png`, `sleep-countdown-tile-phone.png`.
- `cast-sheet-owner-phone.png`, `cast-sheet-readonly-phone.png`, `voice-picker-{phone,tablet}.png`, `voice-picker-hear-pulse-phone.png` (mid-sample with the transcript caption), `voice-picker-empty-phone.png`, `re-narrate-footer-phone.png`.
- `audiobook-narrate-phone.png`, `audiobook-save-phone.png`, `audiobook-jobs-phone.png`, `audiobook-unavailable-phone.png`, `book-page-listen-phone.png`.
- `audio-save-states-phone.png` (saving, saved, remove arming), `offline-no-audio-phone.png`, `opener-not-narrated-owner-phone.png`.
- `reduced-motion-reading-room-phone.png`, `legacy-audio-player-phone.png`.
- Compare the phone captures with `docs/redesign/proof/web-15/*-phone.png` when present and list differences in the report.
- `docs/redesign/proof/mobile-15/device-checklist.md` for the owner (iPhone via SideStore after CI builds the IPA, Android flagship after CI builds the APK), one line per check with an empty result box: narration continues for 5 minutes with the screen locked and with the app in the background; the lock screen and notification show the title, chapter, cover, play/pause, −15 s, +15 s and next chapter, and each works; the Android notification uses `ic_stat_mm` with the `#F4D03F` accent in the `Listen` channel; leaving the reader removes the notification; on the iPhone, `AVAudioSession.sharedInstance().category` logged after `SoLoud.instance.init()` and after a `Hear` sample ends both read `.ambient`, and during narration `.playback` with mode `.spokenAudio` (§15.8); a `Hear` sample plays with the silent switch on and ducks music; narration pauses other music (Android `AUDIOFOCUS_GAIN`); shake extends the sleep timer only in its last minute; the sleep fade over 8 s; a listen session reaches the server after a flight-mode round trip; VoiceOver and TalkBack read the transcript sentences as buttons and the `−18:40` folio in full.
- `docs/redesign/proof/mobile-15/report.md` mapping each screenshot to its acceptance item.

## Git

- Branch `feat/vps-slim-source-native`; the extraction first as its own no-pixel commit, then each data-layer module with its test, the outbox table and its migration, the handler, then each screen part, then fixtures and proof. Stage paths explicitly, never `git add -A` or `git add .`.
- No Claude or AI attribution anywhere (no `Co-Authored-By`, no "Generated with", no AI author); never commit secrets or `.claude/`.
- Before every push: `git fetch origin` and `git diff --stat origin/feat/vps-slim-source-native...HEAD -- frontend`; if it lists files, run `free -m && npm run build` in `frontend/` first (never while `flutter test` runs) and push only if it passes. Then `git push origin feat/vps-slim-source-native` after each working step; the push also runs CI's APK build and iOS dry run, which must stay green.
- Never edit `backend/connectors/` or any backend file; never touch production containers or `/srv/manhwamaniacs/{app,data}`; do not deploy.

## Report back

1. Done items by scope letter A–L, and anything not done with the reason (including any §15.11 fallback taken).
2. The screenshot folder `docs/redesign/proof/mobile-15/` and its file list; which data was live and which came from fixtures; differences against the web twin.
3. Test counts (`flutter test` passed before and after), `flutter analyze` result, `free -m` before each heavy command, and the CI APK and iOS dry-run results for the last push.
4. The exact API of `NarrationController` (state, commands, `narrationActiveProvider`, `isPlaying` and `pause()` for `mobile/23`), `savedAudioStateProvider`, `activeNarrationJobsProvider`, `NarratingIndicator`, the listen settings provider and the exported `VoicePicker` constructor, for `mobile/17`, `mobile/18` and the Glass Listen mode (`mobile/37`).
5. The `downloads_db.dart` version before and after, and the listen-sessions evidence (the test's captured request body).
6. Interpretations made (the match-cut source rect, the `RE-VOICING` condition, the expressiveness quintiles, following along in paged mode, tablet transcript sizes, the status bar shown while the full player is open) and every place where `cinematic/DESIGN.md` overrode this file.
7. The owner device checklist path and open issues.

Next prompt: `docs/redesign/prompts/mobile/16-cinematic-discover-search-sources-dialogue.md`.
