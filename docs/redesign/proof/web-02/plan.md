# web/02 plan

Slices: (E) service worker + policy + two fallbacks; (I) motion-timings; (A-C) skin storage, switchSkin, boot resolution;
(F) first-paint a11y; (D) debug row + SkinBoot + proxy exception; (G-H) haptics, sounds, audio activity.
Shared `features/audio/ui-sound-engine.ts` carries the Web Audio loading/priming for both skins; each skin owns its prefs and cue map.
Proof: skin-restart.txt (debug restarts, SKIN RESTART timings, boot cases), screenshots here.
