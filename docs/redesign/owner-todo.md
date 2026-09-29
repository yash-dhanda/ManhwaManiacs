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

## mobile/11 (Cinematic Feature, Book, downloads)
- Device checks from the prompt (match cut, edge swipe, predictive back, Column wipe, Lightbox, a real download read offline, `mature_override` hiding saved chapters, VoiceOver / TalkBack, text scale 1.3 and 2.0): docs/redesign/proof/mobile-11/device-checklist.md.
- mobile/11: `mature_override: null` does not clear on the server until web/11 lands the backend fix in `followed_series_service.py`; then re-check the third radio of the override menu on a device.
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

## web/11 (L19)
- Device check of the Feature and Book pages on a phone (long-press row menu, swipe to Mark read, Lightbox drag down).
- Confirm `DELETE /reader/progress` exists once backend/02 lands; Mark unread and Undo call it.

## web/11 fix pass (L19)
- The `?` shortcuts sheet is hosted by the legacy AppShell only; the Series keys are registered in the app keyboard registry (group "Series"), so they show as soon as the Cinematic shell (web/06) mounts `ShortcutsDialog`. Check the sheet once then.
- Posters elsewhere in the app must wear `coverTransitionName(sourceId, seriesKey)` (`screens/feature/cover-name.ts`) inside a `<ViewTransition share="mm-match-cut">` for the match cut into the Feature page; web/09-web/10 posters do not exist in this tree, so the cut was verified between the two routes of one series.

- mobile/03: confirm tests + build-ios CI run ids/conclusions for commit abbace5 (liquid_glass_widgets pin), record in docs/redesign/proof/mobile-03/glass-gate.md


## web/26 (Glass primitives 1)
- Device check: touch lift (150/450 ms), throw and magnet on a real phone; the software raster in the harness cannot show frame cost. Record the motion-timings overlay (Press swell, Content sink, Tab droplet, Hold fill, Liquid fill, Count pop, Wave, Letter reveal, Typing reveal) on the 3090 Ti desktop at 1440 x 900.
- iOS Safari: the bottom search field's visualViewport offset (`--vv-h`, `--vv-top`) needs an iPhone.
- web/26: read the motion-timings overlay on a GPU browser at 1440x900 (headless run here was software raster; dropped-frame counts in docs/redesign/proof/web-26/report.md are an upper bound).

## mobile/25 (Glass foundation)
- Run proof/mobile-25/device-check.md on iPhone (SideStore) and the Android flagship.
- Fill the Decision line of proof/mobile-03/glass-gate.md; `kGateRenderer` (skin_glass.dart) defaults to liquid until then.
- Integrator: push ab48531 alone, watch `tests` and `Build iOS`, paste run URLs into proof/mobile-25/resolution.md.

## mobile/11 (Cinematic feature and book pages)
- Some mobile/04-10 stand-ins may remain (check TODO(mobile/NN)); still open: web/11 (mature_override null-clears in followed_series_service.py:953). Swap the TODO(mobile/NN) stand-ins when they land.

## web/11 open issues
- mature_override re-stamp not wired: web/07's local-row mature filter is not integrated; use-series-page.ts setMature only invalidates MATURE_GATED_QUERY_ROOTS (TODO(web/07)).
- Stand-ins remain until web/06, web/07, web/09 integrate: reader-entry.ts (enterReader wipe), toasts.tsx (toast host), standins.tsx (AddToShelfSheet, TagSheet), tags-standin.ts (tag hooks), SetHeading.tsx and use-feature-keys.tsx (single-key setting).

## web/05 owner checks (device only)
- Real-device touch pass on a phone: sheet drag (rubber band, detent settle, 30 % / 800 px/s dismissal), swipe rows, reorder handle, pull to reprint, Lightbox pinch and drag-to-dismiss. The Playwright suite drives the same code with emulated touch, not a real finger.
- Haptics on a real Android device for `sheet.detent`, `refresh.arm`, `zoom.snap`, `delete.confirm` (Cinematic web haptics only cover five events; the others are silent by design).

## web/27 (owner-only)
- Hardware check of the motion-timings overlay (Bloom, Sheet present, Sheet snap, Recede, Toast fall, Meniscus refresh, Scrub lens, Zoom) from `/dev/glass-primitives` at 1440x900 and 390x844 on a real GPU and a real phone; headless Chromium is software raster.
- Real-finger check of pinch, double-tap and the pull-to-refresh snap at 100 px on a phone.
- mobile/05: run docs/redesign/proof/mobile-05/device-checklist.md on iPhone (SideStore) and the Android flagship.
## mobile/26 (Glass primitives 1)
- Device check on iPhone and Android flagship: `docs/redesign/proof/mobile-26/device-check.md` (haptic ramp, 120 Hz press feel, throw, snap, screen readers).

## mobile/06
- Device checks: `docs/redesign/proof/mobile-06/device-checklist.md` (Press start haptics, iOS edge back, Android predictive back, offline edition, tablet keyboard, screen-reader announcements).
