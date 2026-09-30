# mobile/15 owner device checklist (iPhone via SideStore after CI builds the IPA, Android flagship after CI builds the APK)

Result box after every line. Nothing here can be proved on the VPS: no real audio plays there.

- [ ] Narration continues for 5 minutes with the screen locked. Result:
- [ ] Narration continues for 5 minutes with the app in the background (home screen, another app in front). Result:
- [ ] The lock screen and the notification show the title (`Chapter 12 · The Tower`), the chapter, the cover, play/pause, back 15 s, forward 15 s and next chapter, and each control works. Result:
- [ ] The Android notification uses `ic_stat_mm` with the `#F4D03F` accent, in the `Listen` channel. Result:
- [ ] Leaving the reader removes the notification and stops the audio. Result:
- [ ] iPhone: `AVAudioSession.sharedInstance().category` logged after `SoLoud.instance.init()` and after a `Hear` sample ends both read `.ambient`; during narration `.playback` with mode `.spokenAudio` (§15.8). Result:
- [ ] A `Hear` sample plays with the silent switch on and ducks music that is playing. Result:
- [ ] Narration pauses other music (Android `AUDIOFOCUS_GAIN`); a phone call or a navigation prompt pauses it and it resumes. Result:
- [ ] Shake extends the sleep timer by 5 minutes only in its last minute (not at 5 minutes left). Result:
- [ ] The sleep fade over the last 8 s is smooth and the volume is restored after the pause. Result:
- [ ] A listen session reaches the server after a flight-mode round trip (`GET /stats` listening time, or the backend `listen_sessions` table). Result:
- [ ] VoiceOver and TalkBack read the transcript sentences as buttons, the speaker's name before a dialogue sentence, and the `-18:40` folio in full ("18 minutes 40 seconds left"). Result:
- [ ] Follow-along: the band sweeps in 200 ms, the word underline steps, the page holds the spoken paragraph near 38 % and a manual scroll shows `Back to the voice`. Result:
- [ ] Reading room: the swipe down feels tracked and collapses on the spring; Android back collapses it before leaving; status bar shown while it is open. Result:
- [ ] A chapter boundary with auto-play on swaps the next chapter in place and keeps the lock-screen item in step. Result:
