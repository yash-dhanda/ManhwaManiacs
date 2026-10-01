# mobile/44 plan (Glass ambient reader extras)

Order of work, one commit each: A prefs fields; cruise maths; cruise controller (CruiseSource seam: engine and novel column); pill, HUD, rail drag, landscape pill; recipes, generator, file cache; mixer, controller, scheduler, level meter; sheet and orbs; entry points (keys, settings rows, Aa rows and badge); rain shader, sim, host; guided geometry; guided view; page-tint rules and fling hold; proof.
A3 and A4 were already in the engine (`AutoScrollController` 400 ms ramp, `NovelAutoScroll`), so only a `touching`/`dragged`/`resumeAfterMomentum` seam was added.
