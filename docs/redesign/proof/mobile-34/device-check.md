# mobile/34 device check (owner)

Settings -> Diagnostics -> Edition (debug) -> GLASS, then Glass development -> Reader engine probe.

- [ ] `fixture=long-strip`: "Run 120-page scroll" shows 0 dropped frames at 120 Hz in the Glass motion-timings overlay (entry `STRIP SCROLL 120`). Result: ______
- [ ] A real 120-page chapter (`?source=&series=&chapter=`) scrolled by hand end to end at 120 Hz with 0 dropped frames. Result: ______
- [ ] `mode=single`: a pull past the end reads `armed` at 48 and `locked` at 72 in the readout; a fling-commit keeps scrolling the next chapter. Result: ______
- [ ] `currentPageSample.source` turns `decode` within 600 ms of settling and `pTop` reads 1.0 on a page with a top bubble. Result: ______
- [ ] The Cinematic reader looks and feels unchanged. Result: ______
