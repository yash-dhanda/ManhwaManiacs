# mobile/44 report

## Done by section
- A: reader prefs `cruiseSpeed` and `soundscape` (+tests); defaults provider already clamped (mobile/39); engine ramp and novel auto-scroll already existed (A3/A4 no new work, only the `dragged`/`touching`/`resumeAfterMomentum` seam); `GlassSoundscapeFiles` (A5).
- B: `ambient/cruise.dart`, `cruise_controller.dart` (a Notifier with a `CruiseSource` seam: manga engine and novel column), `cruise_pill.dart` (pill, HUD, rail strip), novel `NovelCruiseSource`; keys p/a, < >; text-scale move; landscape pill; keep awake; Reduce Motion; stops via `registerPlaybackStop`/`registerMatureStop`.
- C: `soundscape/` recipes, generator (isolate, 30 s 32 kHz WAV, seam, -24/-18 dBFS), mixer, scheduler, level meter, controller, procedural cache.
- D: sheet, orbs, glyph patterns on one clock, level bars, mixer, entry points (manga and novel Ambient rows, shift+s, global `?sheet=soundscape`).
- E: shader, `RainSim`, host with one registry layer; manga and novel chrome wrapped.
- F: `guided.dart` geometry, `guided_view.dart`, `glass_ambient_bridge.dart` (panel results, manifest seeds, exit report).
- G: `page_tint.dart` (`TintFollower`, fling hold, cover fallback), held legibility sample, 200 ms Reduce Motion cross-fade, rim-tinted micro progress, pill inner glow.
- H: settings pages already read/write the keys (mobile/39).
- I: tests under test/skins/glass/ambient and soundscape, reader-level checks, budget.

## Not done
- Listen player (header Soundscape item, narrator-hue tint): mobile/37 is not integrated, no listen screen exists.
- Novel landscape menu item (no novel menu exists), novel/listen proof shots, cinematic before/after captures, `guided-finding` shot.
- Next-chapter card in guided view past the last panel: arm haptic at 48 and commit at 72 are implemented, the card itself is not drawn.
- The desktop gutters and side-panel rims were already mobile/35's.

## Facts asked for
- Recorded layers: none exist in backend/media/soundscapes/glass at the time; procedural covers all.
- `readSamplesFromFile` exists in flutter_soloud 4.1.7 and is used for recorded envelopes.
- Music check: iOS `AVAudioSession().secondaryAudioShouldBeSilencedHint` via audio_session; Android `mm/platform` `audio.isMusicActive`. No native change.
- Rain shader did not render in the harness (no Impeller); `rain-phone.png` shows the chrome with the registry layer only. Uniform addition: `uLight` after `uDrops`.

## Deviations
- Cruise controller keeps a CruiseSource seam instead of taking the engine directly.
- Guided view draws its own page copy in the overlay (the engine has no strip camera); the lens is a clear T2 pane.
- Increase Contrast dim: the clamp [0.40, 0.72] is on the existing formula, so dimFor(1.0) stays 0.64 (the ceiling is unreachable).
- Autoplay on opening a reader only for a remembered scene or a non-off default scene.
- A tall panel is fitted by width and walked, not fitted whole by height.

## Proof map
cruise-*: B; soundscape-*, rain-phone: C/D/E; guided-*: F; tint-*: G. Tests: cruise_test, cruise_controller_test, cruise_pill_test (B); recipes/generator/scheduler/soundscape_controller/sheet tests (C, D); rain_on_glass_test (E); guided_test, guided_view_test (F); page_tint_test (G); ambient_reader_test (I).
