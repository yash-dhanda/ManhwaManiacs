# mobile/37 report: Glass Listen mode

Branch `redesign/M37` (not pushed). Captures in this folder come from `mobile/test/screenshots/glass/mobile_37_listen_shots_test.dart` (frost path: shader glass does not run under `flutter test`, so T5 surfaces read as translucent frost here).

## Done by scope letter
- A1 to A6: per-skin parameters (`narrationStopOnReaderExitProvider`, `NarrationControlSet` + `skipToPrevious`, `narrationAudioServiceConfig(bootSkin)`, `NarrationLevel` with the decoded envelope (`readSamplesFromMem` exists in `flutter_soloud` 4.1.7) and the segment fallback, parameterised `ShakeDetector` + `glassShakeToExtend`, notification tap). Cinematic defaults unchanged.
- B: `voice_hue`, `cast_line`, `listen_accessory`, `orbit_math`, `band_geometry`, `paged_follow`, `job_rows`, `skip_toast`, each tested.
- C: top-right Listen and Voices slots, the "Listen · 14 min" header capsule and follow-along line, `p`, `?listen=1`, Play from here through the Glass host, the Audiobook button and "Voices for this book" on the book page, the "Narrating 3" chip on Downloads and the sidebar item.
- D: listen row (one `SkinGlassGroup` with the bottom capsule), accessory variant, desktop accessory and rail orb.
- E: player sheet (monolith), 560 px window, Listen tab, parallax artwork, speaking orb, scrubber, transport, tiles, lozenge sentence list, post-play card.
- F: speed dial from the tile, cast sheet, voice orbit (`SnapPhysics`, 176 stride), introductions, grid.
- G: save audio rows. H: Audiobook sheet. I: sleep menu. J: highlight band, word underline, follow, paged turns. K, L: states and keys. M: lock screen set and accent. N: the novel reader keeps the row and the capsule in one group.

## Decisions and deviations
- `voiceHue`: the web twin's rule (OKLCH L 0.80, C 0.12, hue 250 to 40 over 80 to 300 Hz); the web twin had no test file yet, so the hexes are asserted for contrast only.
- Cast line: the voice with the most characters, ties to the earlier voice in the server's order.
- Owner on an un-narrated chapter: the Listen button opens the Audiobook sheet in Narrate mode with the chapter selected.
- Notification colour is fixed at process start (an in-process skin switch keeps the boot skin's colour until a cold start).
- Voice samples use Ogg through SoLoud on iOS too (SoLoud has no AAC decoder).
- Shake peak: two peaks above 2.2 g within 300 ms.
- Post-play card waits for "Play now" when `accessibleNavigation` is on.
- Lozenge and band are spring-driven values outside the named moves of 4.10. The word is underlined; the text itself is already full ink so no re-draw is done.
- Artwork at `medium`: capped at 13 % of the screen height so the transport and tiles fit 52 % of a phone (a 240 px plate cannot share it); glass/DESIGN.md lists everything at `medium`.
- `GlassSheetSpec` gained `material`, `origin`, `trailing`; the sheet host stacks a second `?sheet=` over the first (Voices tile opens the cast sheet); the desktop window form honours the monolith (T5, radius 32, 88 %).
- The listen sheet ids are registered by the listen layer as well as the shell's overlays, because a reader opened cold never passes the shell.
- Fixed in passing: the shell accessory's swipe used a wrong projection constant; it now uses `project()`.
- Jump follow cross-fade is a 120 ms dip of the reading body (not a true cross-fade); the lozenge's inactive sentences use `label2`.
- Cast "Couldn't load who speaks here" cannot be reached (the attribution provider swallows errors into `none`).
- Not captured: Save mode of the Audiobook sheet and the saved-audio rows with a live downloads scope (the shell harness has no store; labels are in `save-audio-states-phone.png`), `cinematic-reading-room-phone.png` (unchanged, Cinematic reader code only gained a gate), CI APK and iOS dry run (not pushed).

## Captures
`listen-row*`, `accessory-*`, `desktop-accessory-*` (D); `player-*`, `speaking-orb-speaker-phone`, `sentence-list-decoupled-phone`, `post-play-phone`, `offline-no-audio-phone`, `solid-player-phone`, `reduced-motion-player-phone` (E, K); `speed-dial-phone`, `sleep-*` (F0, I); `cast-*`, `orbit-*` (F); `audiobook-*`, `book-page-audiobook-status-phone`, `narrating-chip-phone` (H, C6, C7); `highlight-*`, `back-to-the-voice-phone`, `paged-narration-turn-phone` (J). The two files ending `-tablet-wide` are the desktop-frame captures. No web-37 captures existed to compare.

## API for later steps
Host: `glassNarrationActionsProvider` (`startChapter`, `changeChapter`, `stopWithUndo`, `openPlayer`, `openSheet(id, extra)`), `glassNarratorProvider`, `glassListenScopeProvider`. Accessory slot: `GlassNarrationAccessory` (now with orb colour, initial, stop). `NarrationControlSet`. Settings fields `speed`, `sleepDefault`, `autoPlayNext`, `glassShakeToExtend`. Soundscape hook: the player's ⋯ shows "Soundscape" once `glassSheetRegistered('soundscape')`. Keys: `kListenKeyBindings`; cruise `<` `>` outside narration is mobile/44's.

## Device checks
`device-checklist.md` (owner).
