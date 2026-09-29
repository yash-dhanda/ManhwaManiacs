# web/02 plan

Slices: (E) service worker + policy + two fallbacks; (I) motion-timings; (A-C) skin storage, switchSkin, boot resolution;
(F) first-paint a11y; (D) debug row + SkinBoot + proxy exception; (G-H) haptics, sounds, audio activity.
Shared `features/audio/ui-sound-engine.ts` carries the Web Audio loading/priming for both skins; each skin owns its prefs and cue map.
Proof: skin-restart.txt (debug restarts, SKIN RESTART timings, boot cases), screenshots here.

Fix pass 1 additions: boot cases and offline-nav results are in skin-restart.txt (script drove headless Chromium against the dev stack, NEXT_PUBLIC_ENABLE_SW=1);
offline-nav-{cinematic,glass}-{1440,390}.png are what the worker served for an uncached URL; legacy-{before,after}-{library,settings}-{1440,390}.png
(before = frontend at ad8b6ba) differ only by the header clock. Novel reader with narration playing: fix pass 2 captured legacy-{before,after}-novel-reader-{1440,390}.png (before = frontend at ad8b6ba, after = HEAD). The API routes for the novel chapter, audio map, audio file and series were stubbed in the proof script (a synthetic 80 s tone, one 20 s segment per paragraph), the player was pressed and the shot taken about 1.5 s into playback (button reads Pause, audio.paused=false). 390 is byte-for-pixel identical; 1440 differs by a handful of anti-aliased pixels on the playhead. Sounds arm at boot from SkinBoot (sounds.test.ts, "arming at boot").
