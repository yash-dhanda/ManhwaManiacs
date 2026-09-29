# Cinematic monogram construction

Decision 1 (shared/04): the construction wins over the 560 x 480 box of cinematic 12.2. Two Bodoni Moda M's (upright and italic, `opsz` 96, `wght` 800), the italic overlapping the upright's right stem by 22 % of the upright's width, the union scaled uniformly to 560 units wide.

Measured (resvg render of the upright at 1024, filled-run widths at 25 %, 50 %, 75 % of its height, 1024-canvas units):

- Union box: x 232 to 792 (560), y 386.97 to 637.03 (250.06), about 2.24 : 1. Centred on y 512.
- Thickest stem: 61 units. Thinnest hairline: about 1 unit (below one pixel at 1024; use `monogram-small.svg`, whose 16-unit stroke lifts hairlines to about 17 to 24, for any use under 64 px).
- Geometry lives in `monogram.json` (shared/02); `mark.mjs` reads it and never recomputes it.
- The intersection is drawn by mask, never stored as a path; on the app icon it is a sliver of Subtitle Yellow with a bloom.
