# mobile/37 plan: Glass Listen mode

One task per scope letter of `docs/redesign/prompts/mobile/37-glass-listen-mode.md`. Pure logic first with its test, then widgets, then the reader.

| Letter | Task | Files | Check |
|---|---|---|---|
| A1 | `narrationStopOnReaderExitProvider`: Cinematic true, Glass false; the Cinematic reader gates its `stop()` on it | `narration_controller.dart`, Cinematic reader | `glass_narration_controller_test` |
| A2 | `NarrationControlSet` (cinematic, glass), `skipToPrevious`, the controller sets the handler's set from the skin | `narration_audio_handler.dart` | `narration_audio_handler_test` |
| A3 | `narrationAudioServiceConfig(bootSkin)`: `#7563F2` for Glass | `narration_audio_handler.dart`, `main.dart` | `glass_listen_settings_test` |
| A4 | `NarrationLevel` (decoded envelope, segment fallback) | `narration_level.dart` | `narration_level_test` |
| A5 | `ShakeDetector(threshold, window, sampling)`, `glassShakeToExtend`, foreground-only subscription | `shake_detector.dart`, `listen_settings.dart`, controller | controller and settings tests |
| A6 | Notification tap opens the playing chapter | `glass_narration_host.dart` | `reader_listen_test` |
| B | voice hue, cast line, accessory priority, orbit maths, band geometry, paged follow, job rows, skip toast | `skins/glass/listen/*` | `voice_hue_test`, `helpers_test` |
| C | entries: top-right slots, header capsule, `p`, `?listen=1`, Play from here, Audiobook button, Narrating chip | reader, `audiobook_button.dart`, `narrating_chip.dart`, Downloads, sidebar | `reader_listen_test`, `audiobook_test` |
| D | listen row in the bottom capsule's group, accessory variant, desktop accessory | `listen_row.dart`, `bottom_capsule.dart`, shell accessories | `surfaces_test`, `reader_listen_test` |
| E | full player: sheet, window, Listen tab, orb, scrubber, transport, tiles, sentence list, post-play card | `player_*.dart`, `speaking_orb.dart`, `scrubber.dart`, `sentence_list.dart`, `post_play_card.dart` | `player_test` |
| F | speed dial, cast sheet, voice orbit, grid | `speed_dial_tile.dart`, `cast_sheet.dart`, `voice_*.dart` | `player_test`, `voices_test` |
| G | save audio | `save_audio.dart`, `player_more.dart` | states from `savedAudioStateProvider` |
| H | Audiobook sheet | `audiobook_sheet.dart` | `audiobook_test` |
| I | sleep menu | `sleep_menu.dart` | `player_test` |
| J | highlight band, word underline, follow, paged turns | `highlight_layer.dart`, reader | `highlight_test`, `reader_listen_test` |
| K, L, M, N | states, keys, lock screen, budget | reader, `novel_keys.dart`, handler | `surfaces_test`, `reader_listen_test`, `budget` in the shots test |
