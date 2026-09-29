# Owner to-do (redesign)

Items only the owner can do. Each names its step; the step shipped with the stated fallback.

## shared/03 (UI sounds and soundscape audio)

- **Pick fifteen CC0 recordings for Glass's recorded soundscape layers.** Follow the intro of `backend/media/soundscapes/glass/SOURCES.md`: freesound.org, licence "Creative Commons 0" only, at least 96 s each; drop each original into `design/sounds/incoming/glass/{scene}-{layer}.<ext>`, fill its row, run `node design/sounds/trim-loop.mjs`, commit the two outputs and the row. `node design/sounds/trim-loop.mjs --check` lists the 30 missing files. Fallback meanwhile: web/44 and mobile/44 play the procedural layer for any missing recording.
- **Listen through every cue and loop on headphones** (`ffplay -nodisp -autoexit <file>`): `mobile/assets/sounds/{cinematic,glass}/*.wav`, `backend/media/soundscapes/*.ogg`, `backend/media/soundscapes/glass/deep-*.ogg`. The render was checked by measurement only (lengths, peaks, LUFS, true peak, seams); nobody has listened to it. Flag anything harsh, clicky or off-scale; recipes live in `design/sounds/recipes.json` and re-render with `node design/sounds/render.mjs cues|loops`.
- **Decide the Glass cue budget.** Glass §6 says "under 320 KB for the whole set", but its own lengths need 546,704 bytes at 48 kHz 16-bit mono. Either raise the figure in glass §6 or shorten cues (the logo alone is 134 KB).
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
- mobile/01: run docs/redesign/proof/mobile-01/device-check.md on the iPhone build and the Android flagship.

## mobile/02 (L01)
- Run docs/redesign/proof/mobile-02/device-check.md on the iPhone build and the Android flagship.
- After the integrator pushes: read CI (`android-apk`, `build-ios`) for the dependency, audio_service and mm/platform commits and record run ids in dependency-gate.md; apply a package's ledger fallback if a native job fails.

- shared/04: owner to check the new launcher icon, `Maniacs` label and black native frame on a real iPhone and Android device after the next build; hairlines of the Bodoni monogram are ~1 unit, judge the icon at 60 px.

## shared/05
- Deliver the eleven art masters per brand/onboarding/styles/BRIEF.md, fill LICENSE.md, run node brand/onboarding/styles/intake.mjs, commit outputs.
- Optional (Mac): open mobile/ios/Runner/AppIcon-Glass.icon in Icon Composer to tune translucency.

## web/25 (Glass foundation, lane L03)

- Device checks on real hardware: the Glass motion-timings overlay (`mod+shift+m` on `/dev/glass-calibration`) showed 0 dropped frames for Materialise, Dematerialise, Dim shift, Specular sweep and the rubber-band release in headless Chromium at 1440x900 (software raster). Confirm on the GPU laptop, and on a phone (Android Chrome tilt for the light angle; iOS Safari needs `requestDeviceTilt()` from the Settings switch, web/39).
- Safari and Firefox: the frosted tier (blur + 6 px, no displacement) was not looked at in those engines. Open `/dev/glass-calibration` in both once.
- Side by side with the Flutter page (`mobile/25`): count the 16 px squares the rim bends on the web (T2 44 px button: 10 px max displacement inside a 10 px bezel, about 0.6 square; T4 240 px menu: 18 px inside an 18 px bezel, about 1.1 squares) and say if a tier should bend more or less; the knob is `design/tokens/glass.json` (shared track).
- Demo art: `/dev/glass-calibration` uses 24 generated stand-in covers in `frontend/public/dev-covers/` (dark, mid and pale, one dark with a white patch) because `frontend/public/skin-preview/covers/` (shared/05) is not integrated yet. Swap them when it lands.
- web/01 open: shared/02 ICON_RULES has no per-role fixed weight (design/icons.json defines none), so the Cinematic streak flame renders Light at 24, never Fill; Icon.tsx keeps a no-op roleWeights hook.
- mobile/03: confirm tests + build-ios CI run ids/conclusions for commit abbace5 (liquid_glass_widgets pin), record in docs/redesign/proof/mobile-03/glass-gate.md

## mobile/21 (The Numbers, the streak flame and The Annual)

- **Run the device checklist** in `docs/redesign/proof/mobile-21/device-checklist.md` on the iPhone (SideStore build) and the Android flagship: numerals and rules at 120 Hz, flame tiers, Ignite and milestone haptics, the Annual's gestures and colophon, Share to Messages and Instagram Stories, `Save image` into Photos and into Pictures > ManhwaManiacs. Fallback meanwhile: the widget tests and the proof screenshots cover layout and behaviour; only feel and the share-sheet targets need a device.
- **After the integrator pushes, read CI**: the APK build and the iOS dry run must pass (native files changed: `MediaChannel.kt`, `MainActivity.kt`, `Info.plist`; no Gradle or Xcode runs on the VPS).
