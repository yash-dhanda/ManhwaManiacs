# mobile/44 device checklist (owner)

Settings -> Diagnostics -> Edition (debug) GLASS. Read Rendering performance and "Show motion timings".

1. Cruise at 120 Hz on a 120-page 2,880 px webtoon: mean FPS >= 114, jank < 5 %, no `danger` row for Cruise ramp.
2. Flick to cruise: a gentle and a hard forward flick engage at the coasting speed and the pill shows it.
3. Pill drag and its magnet click at 1.0x; ticks every 0.25x; end stops click.
4. Each of the six scenes sounds as named; record time to first audio (`soundscape.start`).
5. Recorded layer cross-fades in over 2 s once files are dropped (/app/soundscapes/glass-{scene}-{layer}.ogg).
6. Narration ducks the scene 12 dB over 400 ms; Lower under narration off pauses it.
7. Spotify or Apple Music playing first gives the muted toast and its Mix in action.
8. Background with and without narration, and the lock screen.
9. A phone call interrupts: paused, toast offers Resume.
10. Rain on glass on both phones: droplets refract a white page, Diagnostics layer row +1. Confirms the vec3[10] uniform layout and the device-pixel coordinate space.
11. Guided view sliver at 120 Hz, no `danger` row for Panel camera.
12. Page tint over the white demo panels.
13. Landscape on both phones (cruise pill above the rail's trailing end; novel has no landscape menu yet).
14. Android: rail drag while cruising never triggers system back.
15. Android audio focus: audio_session has no AUDIOFOCUS_NONE type, the soundscape state uses the default gain config; check that it does not interrupt music.
