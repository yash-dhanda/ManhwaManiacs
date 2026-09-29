# web/25 report (lane L03)

Where the prompt and `glass/DESIGN.md` disagree, DESIGN.md won: Increase Contrast is a modifier on tiers A and B (not tier C), the dim clamp is 0.40 to 0.72 there.

## Items A to P
Done: A document defaults, B renderer stamp, C material maths, D GlassSurface, E liquid map, F budget, G light angle, H caustic and follow ring, I palette (+ `lib/color/oklch.ts`), J useLb, K ambient field, L rain, M physics, N motion table and overlay, O calibration page, P Playwright spec.
Deviations, each on purpose:
- `motion` is 13.4.6, not 13.4.4 (13.4.4 does not resolve: its `motion-dom` is missing from the registry).
- web/02 is not in this lane, so the motion-timings recorder is a local stand-in (`skins/glass/motion-recorder.ts`, TODO(web/02)); the Glass tokens import, `data-solid`, `data-contrast`, `data-motion` are stamped by this step's own CSS and the calibration controls.
- `PageSample` (reader) does not exist yet: local stand-in in `useLb.ts` (TODO(reader)).
- Demo covers are 24 generated stand-ins in `public/dev-covers/` (shared/05 art not integrated).
- The calibration page shows one section at a time (tabs) so the live glass budget stays at 4 to 6; sections are numbered 1, 3, 4, 5, 6 and the rain toggle (item 7) lives on the section-3 bar. "Add glass surface" and "Stack test" exercise the budget.
- Bar-group rim and glow are one rectangle (per-shape rim belongs to web/29 with droplets and the neck).
- The ambient field's vertical fall-off is a top gradient layer instead of a mask (same look, one element, no filter).
- `next.config.ts` gains `allowedDevOrigins: ["127.0.0.1"]` (dev only) so the Playwright specs hydrate through 127.0.0.1; `proxy.ts` matcher skips `/dev/`.
- Computed `backdrop-filter` serialises as `url("#lens-...")` (quoted), the spec matches both spellings.

## Missing or off token keys (for the shared track)
- None missing (`--mm-glass-t2-blur`, `--mm-glass-tinted-fill`, `--mm-dim-min`, `--mm-color-machine-wash`, `--mm-color-bloom-rim`, `--mm-spring-letter`, `--mm-physics-rubber-band-c` all present).
- `theme.generated.css` registers `--glass-dim`, `--glass-grad-t`, `--glass-rond-t` with `inherits: false` (DESIGN 3.5 / prompt A3 say `--glass-dim` inherits true). Handled with `--glass-dim: inherit` on the material spans; consider `inherits: true` in the generator.
- `--mm-spring-drift-ms` is 1064 ms (DESIGN 2.1.8 says 900 ms bounce 0 for the ambient drift): the generated value is used.

## Screenshots to acceptance
| File | Proves |
|---|---|
| calibration-liquid-{desktop,phone} | tier A refraction at the rim, T4/T5 fringe |
| calibration-frosted-{desktop,phone} | tier B blur only |
| calibration-solid-{desktop,phone} | tier C opaque #1C1C22 / #26262E, 1 px rim |
| calibration-contrast-desktop | Increase Contrast hcBorder |
| calibration-forced-colors-desktop | Canvas / CanvasText, no decorative layers |
| calibration-reduced-desktop | reduced motion |
| legibility-{dark,pale}-desktop | dim follows Lb (0.22 to 0.64), onGlass label readable |
| caustic-{rest,pressed}-desktop | caustic 14 % to 22 %, press glow |
| focus-ring-t2-desktop | two-tone ring, unclipped |
| ambient-{mood,palette}-phone | ambient field, light follows the story |
| default-skin-{before,after}-{desktop,phone} | `/library` byte-identical before and after (both land on /login without a backend) |
| motion-timings-desktop | the overlay with the calibration moves |

## Measurements
- Calibration readout: T2 44 px button bends inside a 10 px bezel, max 10 px (0.6 of a 16 px square); T4 240 px menu bends inside an 18 px bezel, max 18 px (1.1 squares), with 0.6 px dispersion.
- Motion (headless Chromium 1440x900, software raster): Materialise 250 to 255 ms, Dematerialise 350 to 363, Dim shift 400 to 410, Specular sweep 520 to 546, rubber band release 414 to 500 (velocity dependent), 0 dropped frames each (one sweep dropped 4 while three other things ran).
