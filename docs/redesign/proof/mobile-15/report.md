# mobile/15 report: Cinematic Listen mode, "The reading"

Branch `redesign/M15`, not pushed. Final: flutter analyze clean; full flutter test 5772 passed, 0 failed. Scope A-L implemented; see device-checklist.md for what only a phone can prove.

## Scope status
- A Skin-neutral extraction: `NarrationController` (Notifier singleton `narrationControllerProvider`), `NarrationPlayer` seam over just_audio, `NarrationAudioHandler` behind `NarrationCommands`. Legacy `novel_audio_player.dart` runs on it.
- B Helpers: narration_timing, sleep_timer, shake_detector, voice_pulse, listen_sessions, listen_settings, audiobook_plan. All unit tested.
- C Data: `listen_session_outbox` table (downloads db v4 to v5, migration and downgrade tests), sessions flush, `savedAudioStateProvider` with `audio_preparing` wait, `activeAudioJobsProvider`, casting and render writes, `VoiceSamplePlayer` (SoLoud loadMem + RMS pulse).
- D-L Screens under `skins/cinematic/screens/listen/`: opener, mini player, follow-along, reading room, speed / sleep / cast / voice picker / Audiobook sheets, post-play card, saved-audio row, narrating indicator, lock screen config, Settings voice browser.

## APIs
- `NarrationController`: start, play, pause, toggle, seek, seekBy, seekToSegment, seekToParagraph, stepSentence, setSpeed, stop, retry, pauseForSample, setSleep; `position`, `buffered`, `segment` ValueNotifiers; `ended` stream.
- `savedAudioStateProvider`, `activeAudioJobsProvider`, `NarratingIndicator`, `VoicePicker` / `showVoicePicker` / `showVoiceBrowser` as in the source files.

## Evidence
- Downloads db version is 5; the audit and bookmarks tests assert it.
- Listen-session request body is asserted in test/features/novels/listen/repository_test.dart.
- Screenshots in this folder cover every state named in the prompt; no web-twin comparison shots exist.

## Interpretations
Match-cut source rect is the whole mini bar; RE-VOICING derives from locally recast characters plus an active render job; expressiveness quintiles by rank; paged-mode Listen row reserves 76 px only when owner or book has narration; speed sheet detents [0.5, 0.92]; status bar top-only while the room is open; the active jobs endpoint has no book identity so NarrationJob uses the last queued book remembered locally; skip icons are Phosphor regular with a "15" label. The extraction commit is not strictly first (pure helpers were committed before it).

## Incidents and open issues
- Early checkout/stash mishap was recovered. A pattern pkill killed other lanes' flutter_tester processes twice.
- Long reader test sequences can hit a semantics `!child.attached` assertion; tests were split into short ones, root cause unresolved.
- Real-device checks, CI, and web-twin comparison are not done.
