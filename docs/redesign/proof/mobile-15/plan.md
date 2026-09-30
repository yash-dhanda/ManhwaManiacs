# mobile/15 plan (as executed)

Order: extraction first, then the pure helpers with tests, then the data layer, then the screens, then proof.

1. Skin-neutral data layer (no pixels): `NarrationController` (one `just_audio` player behind `NarrationPlayer`, the lock-screen handler as `NarrationCommands`), `narration_timing`, `sleep_timer`, `shake_detector`, `voice_pulse`, `listen_sessions`, `listen_settings`, the `listen_session_outbox` table (downloads db v4 -> v5) and its flush, `savedAudioStateProvider` with the `audio_preparing` wait, `activeAudioJobsProvider` and its cadence, the casting and render writes, `VoiceSamplePlayer` (SoLoud `loadMem` + RMS pulse), `voiceMonogramField`.
2. The legacy player bar switched to the controller in the same step (no pixel change).
3. Screens under `skins/cinematic/screens/listen/`: opener row, mini player, follow-along (decorator + follower), reading room (transcript, transport, tiles), speed and sleep sheets, cast sheet, voice picker, Audiobook sheet, saved-audio row, post-play card, narrating indicator; the reader, its keys, top bar, Margins tab, the book page and Settings wired to them.
4. Tests per module and per screen with a fake player; fixtures under `mobile/test/fixtures/listen/`.
5. Proof screenshots (`mobile_15_shots.dart`), report and the owner device checklist.
