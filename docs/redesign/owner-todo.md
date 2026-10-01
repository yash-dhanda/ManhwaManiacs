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

## mobile/16 (L09)

- Run `docs/redesign/proof/mobile-16/device-checklist.md` on the iPhone and the Android flagship once CI builds them.

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

## mobile/16 (lane L09, fix pass 2)
- After mobile/12 lands: mount `DialogueLandingHost` in the Cinematic reader and check on a device that a Dialogue hit lands on the matched page and the bubble pulses twice.
- mobile/06 landed: Discover listens to `focusSearchSignalProvider` and the Dialogue screen uses `enterReader(entry: dip)`. Check both on a device.

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

## web/06
- Device check of the Cinematic shell on a phone: thumb index long-press (Library, Downloads, Index), edge safe areas, Press start splash, Column wipe into a reader.
- Open: web/11's feature-page motion log overlay (screens/feature/MotionTimings.tsx) still coexists with the shell's mod+shift+m overlay; unify later.
## mobile/26 (Glass primitives 1)
- Device check on iPhone and Android flagship: `docs/redesign/proof/mobile-26/device-check.md` (haptic ramp, 120 Hz press feel, throw, snap, screen readers).

## mobile/06
- Device checks: `docs/redesign/proof/mobile-06/device-checklist.md` (Press start haptics, iOS edge back, Android predictive back, offline edition, tablet keyboard, screen-reader announcements).

## mobile/07
- Device checks: `docs/redesign/proof/mobile-07/device-checklist.md` (Setup keyboard and rule move, keychain and autofill, the Iris haptic and frame timing, Switch profile back gestures, the certificate stamp haptic, screen readers).
- 18+ on-device run: `docs/redesign/proof/mobile-07/18plus-checklist.md` (throwaway profile, own server; undo afterwards).
- mobile/27: device checks listed in docs/redesign/proof/mobile-27/device-check.md (predictive back, keyboard rule, viewer gestures, real blur, haptics).
- mobile/27: run docs/redesign/proof/mobile-27/device-check.md on the iPhone (SideStore) and the Android flagship.

## mobile/17
- Device checks: `docs/redesign/proof/mobile-17/device-checklist.md` (real queue with pause and background, the meter growing, swipe removal with Undo, Save to Files into Files and Download/ManhwaManiacs, Open Files, restart resume, automatic new-chapter downloads, What's new after an update, the APK banner and Install now, System status as admin, screen readers).
- The native commit (`MediaChannel.kt`, `getTotalDiskSpace` in `MainActivity.kt` and `AppDelegate.swift`) is not built on this box (no Gradle, no Xcode): CI's APK build and iOS dry run must go green once the integrator pushes.
## mobile/08 (Tonight)
- Device checks: see docs/redesign/proof/mobile-08/device-checklist.md (iPhone via SideStore, Android flagship).

## mobile/09 (Cinematic Library shelf)
- Device checks: see docs/redesign/proof/mobile-09/device-checklist.md (hub swipe at 120 Hz, back order, haptics, VoiceOver/TalkBack Move actions). Shipped with widget-test coverage as the fallback.

## mobile/18
- Run the device checks in `docs/redesign/proof/mobile-18/device-checklist.md`.
- Owner-only: optionally re-run `pngquant` on the 36 preview frames if a smaller bundle is wanted.

## mobile/10 (Cinematic Updates, Collections, History, Bookmarks)
- Device checks: see docs/redesign/proof/mobile-10/device-checklist.md (plate to header match cut and its iOS edge-swipe reversal, Android predictive back from a shelf, swipe rows against the hub swipe, the Updates check haptics, arm dialogs with a double tap, VoiceOver and TalkBack on marginal notes, text scale 1.3 and 2.0). Shipped with widget-test coverage as the fallback.

- mobile/12: run `docs/redesign/proof/mobile-12/device-checklist.md` on the iPhone and the Android flagship.
## mobile/19 (L15)

- Device checks for the AI surfaces: see `docs/redesign/proof/mobile-19/device-checklist.md` (real recap stream, countdown under a finger and in the background, VoiceOver and TalkBack, the Column wipe from a recap, Not for me / More like this haptics, the ask field's send key).

## mobile/20 (M20)

- Device checks for the onboarding: see `docs/redesign/proof/mobile-20/device-checklist.md` (iris out into step 2, typing at 50 ms, the 450 ms hold, backward swipe only, Android back 4 to 3 to 2 to picker, no iOS edge swipe, Cut to home at 120 Hz, VoiceOver and TalkBack actions, text scale 2.0). Shipped with widget-test coverage as the fallback.
- Art: the nine commissioned CC0 art-style crops (600 x 600 WebP, <= 60 KB, `mobile/assets/onboarding/styles/01-painted.webp` ... `09-chibi.webp`). Until they land the step ships typographic plates; the commit that adds them declares the folder under `flutter: assets:` and flips `kStyleArtBundled` in `mobile/lib/features/onboarding/utils/art_styles.dart`.

- mobile/13: device checks in `docs/redesign/proof/mobile-13/device-checklist.md` (120 Hz slide, haptics, volume keys, refresh rate, OCR scan on a saved chapter).
## mobile/21 (The Numbers, the streak flame and The Annual)

- **Run the device checklist** in `docs/redesign/proof/mobile-21/device-checklist.md` on the iPhone (SideStore build) and the Android flagship: numerals and rules at 120 Hz, flame tiers, Ignite and milestone haptics, the Annual's gestures and colophon, Share to Messages and Instagram Stories, `Save image` into Photos and into Pictures > ManhwaManiacs. Fallback meanwhile: the widget tests and the proof screenshots cover layout and behaviour; only feel and the share-sheet targets need a device.
- **After the integrator pushes, read CI**: the APK build and the iOS dry run must pass (native files changed: `MediaChannel.kt`, `MainActivity.kt`, `Info.plist`; no Gradle or Xcode runs on the VPS).

## mobile/14
- Device checks: see `docs/redesign/proof/mobile-14/device-checklist.md` (faces from the bundle, pagination time, 120 Hz Slide, status bar, back gestures, drop cap sizes, screen readers, text scale, Bold Text).

## mobile/15 (M15, Listen)

- **Run the device checklist** in `docs/redesign/proof/mobile-15/device-checklist.md` on the iPhone (SideStore build) and the Android flagship: 5 minutes of narration with the screen locked and in the background, the lock-screen and notification controls (title, chapter, cover, play/pause, back 15 s, forward 15 s, next chapter), the `ic_stat_mm` icon with the `#F4D03F` accent in the `Listen` channel, the iOS audio-session log (§15.8), a `Hear` sample with the silent switch on, shake to extend only in the last minute, the 8 s sleep fade, a listen session reaching the server after a flight-mode round trip, VoiceOver and TalkBack on the transcript and the `-18:40` folio. Fallback meanwhile: the widget tests with a fake player and the proof screenshots; only the native audio behaviour needs a device.
- **After the integrator pushes, read CI**: the APK build and the iOS dry run must pass (`AudioServiceConfig` now names `drawable/ic_stat_mm`; no native file changed).
## mobile/22
- Run docs/redesign/proof/mobile-22/device-checklist.md on two devices/profiles.

- mobile/23: built (engine duties, auto-scroll, house sound, guided view, tinted chrome, novel extras). Device checks in docs/redesign/proof/mobile-23/device-checklist.md. The guided-panel proof shot shows a blank page (image not painted in the harness); verify on device.
- mobile/23: M23 is only partly built (engine pure modules + parity vectors); UI, house sound, guided view and engine integration remain. See the M23 report.
- mobile/28: run docs/redesign/proof/mobile-28/device-check.md on an iPhone (SideStore) and the Android flagship.

- mobile/24: run docs/redesign/proof/mobile-24/device-pass.md on the iPhone (Build iOS IPA through SideStore) and the Android flagship (signed release APK built where the signing key lives). It includes the Audio session (iOS) row in Settings, Diagnostics.
## mobile/29
- Device checks: docs/redesign/proof/mobile-29/device-check.md

## mobile/30
- Device checks: docs/redesign/proof/mobile-30/device-check.md and 18plus-checklist.md (iPhone through SideStore, the Android flagship with an APK signed where the key lives).
- The nine Glass art-style crops (`mobile/assets/onboarding/styles/glass/{01..09}-{id}.webp`, each under 40,000 bytes, brief in glass/DESIGN.md 12.7) are still to be supplied through `shared/05`'s intake. Fallback in place: typographic tiles (`kGlassStyleArtBundled` is false).
- The Glass preview frames (`mobile/assets/skin_previews/glass/000.png` to `035.png`) are captured by `mobile/39`. Fallback in place: the neutral mark on the brand aurora (`kGlassPreviewFramesBundled` is false).
- mobile/31: device checks in docs/redesign/proof/mobile-31/device-check.md
- mobile/32: run the device checks in docs/redesign/proof/mobile-32/device-check.md (pinch density 120 Hz, pager vs back swipe, dock badge, Save to Files, VoiceOver/TalkBack, gate).
- mobile/42: device checks in docs/redesign/proof/mobile-42/device-check.md
- mobile/39: run docs/redesign/proof/mobile-39/device-checklist.md on iPhone and Android; recapture assets/skin_previews/glass once the series sheet and reader exist (MM_WRITE_PREVIEWS=1).

- mobile/41: run the eight device checks in `docs/redesign/proof/mobile-41/device-check.md` (Deal frame timing, throw and Undo, offer bloom, deck swipe and word fade against a real AI key, ready toast and haptic, chapter pill in both readers, VoiceOver and TalkBack, Reduce Motion). The step shipped with fixture-driven captures.
## mobile/38 (Glass search, sources, catalogue, dialogue)
- Device checks: see `docs/redesign/proof/mobile-38/device-checklist.md` (orb morph on both OSs, 120 Hz late groups, jump-bar ticks, pin fly haptics, FTS4 tokenizer log line on the Android flagship, VoiceOver and TalkBack).
## mobile/34 (reader engine, Glass commands)

- Device check on the iPhone (SideStore) and the Android flagship: see `docs/redesign/proof/mobile-34/device-check.md` (120 Hz, 0 dropped frames on the long strip and on a real 120-page chapter; `mode=single` pull readout; sample turns `decode`).

## mobile/40 (Glass You, About, admin settings, Server, Diagnostics, System status)

- Device checks on the iPhone (SideStore) and the Android flagship: see `docs/redesign/proof/mobile-40/device-check.md` (Orb lift at 120 Hz with 0 dropped frames, the 30 min slider magnet, the Sign out everywhere hold, a backup export to Files, Diagnostics while scrolling, the bead pulse, VoiceOver and TalkBack custom actions, Reduce Motion and Reduce Transparency).

## mobile/43 (Glass Circle)

- Device checks on the iPhone (SideStore) and the Android flagship: see `docs/redesign/proof/mobile-43/device-check.md` (presence drift with and without "Show me in presence", the reaction bloom haptics at 120 Hz, the lift-to-orb magnet and Undo, Orbs fly out, the friend orb flight, the letter dot, the gate-closed profile, VoiceOver and TalkBack, Reduce Motion).

## mobile/33 (Glass series detail and book page)

- Device checks on the iPhone (SideStore) and the Android flagship: see `docs/redesign/proof/mobile-33/device-check.md` (cover landing from a throw, sheet tracking and snap at 120 Hz, the 1,000-chapter fling and list-to-sheet hand-off, the hero tilt stopping when covered, Android predictive back, iPad two-column window, VoiceOver/TalkBack select mode, Save to Files, Book open paper).

## mobile/35 (Glass manga reader)

- Device checks on the iPhone (SideStore) and the Android flagship: see `docs/redesign/proof/mobile-35/device-check.md`.
- CI for the `display.stableInsets` commit (APK job and the iOS dry run): lanes do not push; the integrator runs `gh run watch` on the integration push.

## mobile/36 (Glass novel reader)

- [ ] Run `docs/redesign/proof/mobile-36/device-checklist.md` on the iPhone (SideStore IPA) and an Android flagship (CI APK): native selection and the Glass menu, Lift/Slide at 120 Hz, Book open, paper ripple, pinch, system UI around the notch and gesture bar, rotation, iOS edge strip, keep awake, VoiceOver/TalkBack, text scale, Bold Text, the 12,000-word pagination time.

## mobile/37 (Glass Listen mode)

- [ ] Run `docs/redesign/proof/mobile-37/device-checklist.md` on the iPhone (SideStore IPA) and an Android flagship (CI APK).
