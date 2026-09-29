# Owner to-do (redesign)

Items only the owner can do, by step.

- **mobile/00** (reader engine extraction): run the device checklist in
  `docs/redesign/proof/mobile-00/device-check.md` on the iPhone (SideStore build)
  and the Android flagship (next signed APK), including the 120-page, 2,880 px
  scroll-performance check (stack risk 6).
- **shared/02** (icon sets and custom glyphs): decide the Cinematic `mm-mark` weights
  (cinematic §12.2/§2.7). The upright and italic M intersect only ~119 px² at 1024, so
  Light, Regular and Fill trace to one identical outline. Either accept one outline for
  all three weights, or change the overlap rule to act on the letterforms instead of
  their bounding boxes. The mark also does not read at 16 px (a ~9x4 px smudge).
  Geometry is unchanged until you decide; see the comment above `case 'mm-mark'` in
  `brand/make-glyph-masters.mjs`.

## web/25 (Glass foundation, lane L03)

- Device checks on real hardware: the Glass motion-timings overlay (`mod+shift+m` on `/dev/glass-calibration`) showed 0 dropped frames for Materialise, Dematerialise, Dim shift, Specular sweep and the rubber-band release in headless Chromium at 1440x900 (software raster). Confirm on the GPU laptop, and on a phone (Android Chrome tilt for the light angle; iOS Safari needs `requestDeviceTilt()` from the Settings switch, web/39).
- Safari and Firefox: the frosted tier (blur + 6 px, no displacement) was not looked at in those engines. Open `/dev/glass-calibration` in both once.
- Side by side with the Flutter page (`mobile/25`): count the 16 px squares the rim bends on the web (T2 44 px button: 10 px max displacement inside a 10 px bezel, about 0.6 square; T4 240 px menu: 18 px inside an 18 px bezel, about 1.1 squares) and say if a tier should bend more or less; the knob is `design/tokens/glass.json` (shared track).
- Demo art: `/dev/glass-calibration` uses 24 generated stand-in covers in `frontend/public/dev-covers/` (dark, mid and pale, one dark with a white patch) because `frontend/public/skin-preview/covers/` (shared/05) is not integrated yet. Swap them when it lands.
