# web/02 plan

Slices: (E) service worker + policy + two fallbacks; (I) motion-timings; (A-C) skin storage, switchSkin, boot resolution;
(F) first-paint a11y; (D) debug row + SkinBoot + proxy exception; (G-H) haptics, sounds, audio activity.
Shared `features/audio/ui-sound-engine.ts` carries the Web Audio loading/priming for both skins; each skin owns its prefs and cue map.
Proof: skin-restart.txt (debug restarts, SKIN RESTART timings, boot cases), screenshots here.

Fix pass 1 additions: boot cases and offline-nav results are in skin-restart.txt (script drove headless Chromium against the dev stack, NEXT_PUBLIC_ENABLE_SW=1);
offline-nav-{cinematic,glass}-{1440,390}.png are what the worker served for an uncached URL; legacy-{before,after}-{library,settings}-{1440,390}.png
(before = frontend at ad8b6ba) differ only by the header clock. Novel reader with narration playing: not captured, the fresh dev DB holds no novel or narration
audio; the NovelAudioPlayer diff is limited to setAudioActivity calls. Sounds arm at boot from SkinBoot (sounds.test.ts, "arming at boot").
