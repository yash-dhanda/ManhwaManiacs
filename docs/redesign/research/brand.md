# ManhwaManiacs brand system (research)

Scope: the name "ManhwaManiacs" is fixed. Everything else here is new: wordmark, icon, splash, logo motion, type, icons, haptics, sound, screenshot style. There are two skins, **Cinematic** and **Glass**. Both are dark-only on an AMOLED `#000000` base. Binding owner decisions are in `inventory/00-decisions.md`.

Verified 2026-09-29 against live sources: the Google Fonts metadata API, `google/fonts` METADATA.pb files, the `google_fonts` 8.2.1 package source, `next` 16.2.9 `font-data.json` / `index.d.ts` from the app's `node_modules`, npm and pub.dev package archives, and Apple and Android documentation. Section 14 lists the sources.

---

## 0. Recommendations at a glance

| Decision | Recommendation |
|---|---|
| Master mark | **W2 "Stack"** wordmark. Its "MM column" monogram doubles as app icon **I1**, favicon, nav mark and loader |
| App icon | **I1 "MM Column"**: a Cinematic rendition and a Glass rendition, swapped as alternate icons when the skin changes |
| Cinematic type | **Big Shoulders** (display, `opsz`+`wght`) + **Geist** (body/UI) + **Geist Mono** (numerals/meta). Novel serif: **Newsreader** |
| Glass type | **Google Sans Flex** (display *and* body, via `ROND`/`opsz`/`wght`) + **Google Sans Code** (mono). Novel serif: **Literata** |
| Font delivery, Flutter | Bundle the variable TTFs as assets with `FontVariation` (the app's current pattern). **Do not add `google_fonts`**: it serves static weights only (no `ROND`/`opsz`/`wdth`), and its 9.0.0 release needs Flutter 3.47 while CI pins 3.44.6 |
| Font delivery, web | `next/font/google` with the `axes: [...]` option. All seven families are present in next 16.2.9 |
| Icons | **Phosphor** on both platforms: `@phosphor-icons/react` 2.1.10 + `phosphor_flutter` 2.1.0, both MIT, with verified parity of 1,512/1,512 icons in all 6 weights. Cinematic uses Bold + Fill; Glass uses Regular/Light + Duotone. Six custom glyphs cover domain concepts |
| Haptics | `gaimon` 1.5.0 (MIT) for named impacts plus AHAP signature patterns on iOS, auto-converted to Android waveforms. Cinematic = weight (low sharpness), Glass = texture (high sharpness, frequent ticks) |
| Sound | Off by default. About 12 synthesized WAVs per skin: Cinematic "Projector" in D, Glass "Prism" in E-major pentatonic. `flutter_soloud` 5.1.4 on mobile, the Web Audio API on web |
| Splash | Native splash shows a **neutral** MM mark on `#000`. The first Flutter or web frame redraws it pixel-identically, then plays the skin's logo reveal: Cinematic "Projector" 1,400 ms, Glass "Droplet" 1,200 ms |
| Screenshots | 1320×2868 (captured as a 440×956 CSS viewport at DPR 3 with Playwright, which the frontend already has). Cinematic "Poster" set and Glass "Float" set, 5 frames each. Demo profile only |
| SideStore `tintColor` | `#FF4D2E` (Ember). Currently `#7C5CFF` in `backend/routes/app_distribution.py` |

---

## 1. Inputs from the codebase that shape the brand

- **Novels are the most-read surface on this instance "by a wide margin"** (`frontend/src/app/manifest.ts` comment), yet the current store copy says "Manga & manhwa reader". The brand must read as *comics and prose*, not comics only. This pushes the icon toward a page/strip form and away from a speech bubble.
- **Fonts are bundled, never fetched at runtime.** `mobile/pubspec.yaml` bundles Syne and DM Sans as variable TTFs and drives weight through `FontVariation('wght', …)`. Keep that pattern; it is the correct one for the new axes too.
- **CI pins Flutter 3.44.6** (`.github/workflows/ios-build.yml` and `tests.yml`). Every Flutter package below was checked against that pin.
- **Haptics already route through one class** (`mobile/lib/core/utils/haptics.dart`) with a user toggle (`hapticsProvider`). The new vocabulary replaces its three methods but keeps the single choke point.
- **Screenshot surfaces are sideload surfaces, not the App Store.** The `_SHOWCASE` list in `backend/routes/app_distribution.py` feeds both the install page at `app.manhwamaniacs.xyz` and the SideStore source's `screenshots` / `iconURL` / `tintColor`, served from `mobile/docs/screenshots/`.
- The display name is `ManhwaManiacs` in `CFBundleDisplayName` and in `android:label`. At 13 characters it truncates under an iOS home-screen icon (see Open questions). The PWA `short_name` is "Manhwa".

---

## 2. Brand core

**Idea: the double M.** *Manhwa* + *Maniacs*: two M's, two panels, one gutter between them. The gutter is the white strip between webtoon panels, the moment between one chapter and the next. Every mark in the system is built from **M, gutter, M**.

**Voice.** Short, dry and confident, with no exclamation marks.
- Cinematic uses title-card phrasing: "Tonight's lineup", "Previously on", "Up next", "The end of chapter 142".
- Glass is calm and plain: "Continue", "Up next", "You're caught up".

**Brand colours.** These are brand-asset colours only; the full UI token set belongs to the tokens research. WCAG contrast is measured against `#000000`.

| Skin | Name | Hex | On `#000` | Use |
|---|---|---|---|---|
| Cinematic | Void | `#000000` | n/a | base |
| Cinematic | Ember | `#FF4D2E` | 6.35:1 | primary accent, gutter light, icon stroke |
| Cinematic | Tungsten | `#FFB25C` | 11.77:1 | lamp highlight, rim light, glow core |
| Cinematic | Paper | `#F3EEE6` | 18.18:1 | wordmark ink, primary text |
| Cinematic | Ash | `#8C877F` | 5.89:1 | secondary text |
| Cinematic | Ember Deep | `#8A1C0E` | 2.25:1 | gradient foot, pressed state (never text) |
| Glass | Void | `#000000` | n/a | base |
| Glass | Glacier | `#8FD8FF` | 13.43:1 | primary tint |
| Glass | Iris | `#A99BFF` | 8.82:1 | secondary tint |
| Glass | Bloom | `#FF9ED8` | 11.13:1 | aurora third stop |
| Glass | Frost | `#F5F7FA` | 19.57:1 | wordmark ink, primary text |
| Glass | Mist | `#8E96A3` | 7.04:1 | secondary text |
| Glass | Glass fill / stroke / specular | `rgba(255,255,255,.08)` / `.22` / `.55` | n/a | brand glass material |

Rule: **text on an Ember fill is black** (`#000` on `#FF4D2E` = 6.35:1). Paper on Ember is only 2.86:1 and fails.

---

## 3. Wordmark directions (each with a Cinematic and a Glass rendition)

### W1 "Gutter": single-line condensed caps

- **Setting:** `MANHWAMANIACS` on one line, in caps. It is drawn from Big Shoulders at `opsz 72`, `wght 850`, redrawn with flat terminals, squared counters and a flat `A` apex 0.18 em wide. Tracking is −12/1000 em. Aspect ratio is about 6.1:1.
- **The two M's:** tall "cathedral" M's with vertical stems. The inner V runs to the baseline (full depth), and each M is 0.62 em wide against roughly 0.44–0.50 em for the other letters. **Only the M's** carry a horizontal knockout slit, 0.06 cap-height tall at 54% cap height. That slit is the panel gutter. Both slits sit on one horizontal line, so the eye jumps from M to M; the second slit marks the word joint, and no space or case change is needed.
- **Cinematic rendition:** Paper glyphs. Each slit is lit from behind, filled with a linear gradient from Ember `#FF4D2E` (left) to Tungsten `#FFB25C` (right), plus a 12 px outer glow at 40% Ember. In the reveal the slits switch on last, like a projector lamp.
- **Glass rendition:** redrawn from Google Sans Flex at `wdth 35`, `wght 760`, `ROND 30` (condensed but softened). The glyphs are frosted glass: backdrop blur 24 px, fill `rgba(255,255,255,.10)`, and a 1 px top-edge highlight at `rgba(255,255,255,.55)`. Each slit is a clear refractive cut that shows the background with a 2 px chromatic offset.
- **Short form:** two slit-cut M's side by side (`MM`).
- **Verdict:** the strongest poster, but at 6:1 it is too long for a nav bar. Keep it for marketing headers and the Cinematic splash end-frame.

### W2 "Stack": two-line lockup whose M's form a column (RECOMMENDED)

- **Setting:** "Manhwa" above "Maniacs", flush left, with a leading of 0.84 so the two lines nearly touch. The capitals stack into a column. The lowercase is a geometric grotesk with an x-height of 0.54 cap, a single-storey `a` and a −20/1000 em track. The lockup's aspect ratio is about 2.3:1.
- **The two M's:** they are joined by a **gutter bar**. The top M stands on a horizontal bar and the bottom M's peaks hang from its underside, so M, bar and M form one connected shape: the **MM column**. The bar overhangs each side by 6% of the M width, like a panel border. The M stems are vertical, and the inner V depth is 60% of the M's height.
- **MM column geometry** on a 1024 canvas, used as the icon master: bounding box x 240–784, y 192–832. Top M y 192–480; bar y 480–544 (64 thick, x 208–816); bottom M y 544–832. Stroke 88 units, miter joins, flat caps.
- **Cinematic rendition:** the M column is filled in Ember, with the bar in Tungsten as the lit gutter. The lowercase is Paper, drawn from Geist `wght 700`. The `i` tittle is square.
- **Glass rendition:** the M column is a glass capsule (corner radius 40% of its width) with the M's engraved: inner shadow `rgba(0,0,0,.45)` 2 px, specular edge `rgba(255,255,255,.55)`. The bar is a refractive seam. The lowercase is Frost, drawn from Google Sans Flex `ROND 100`, `wght 620`. The `i` tittle is round.
- **Single-line fallback** (tight headers, the web sidebar): `ManhwaManiacs` with only the two M's in the accent.
- **Verdict:** recommended. The same shape scales from lockup to monogram, icon, favicon and loader, and the vertical column reads as a vertical-scroll strip.

### W3 "Echo": wide single line, the second M echoes the first

- **Setting:** `ManhwaManiacs` in mixed case, set wide: Mona Sans `wdth 125`, `wght 780` (Cinematic) or Google Sans Flex `wdth 125`, `wght 700`, `ROND 70` (Glass). Tracking is −20/1000 em.
- **The two M's:** the second M is an exact copy of the first, trailed by three afterimages offset −0.08 / −0.16 / −0.24 em at 35% / 18% / 8% opacity. These read as manga speed lines, or as the compulsion to re-read (the "maniacs" half of the name).
- **Cinematic rendition:** the afterimages become Ember light streaks with a 6 px horizontal motion blur, like an anamorphic flare. The letters are Paper.
- **Glass rendition:** the afterimages become three stacked glass layers at z −8 / −16 / −24 with blur 2 / 4 / 8 px and slight parallax while scrolling.
- **Verdict:** memorable in motion, but it smears below about 24 px and needs a clean static fallback. Use it as a motion accent: the typing-reveal cursor on the Home headline could leave an echo trail.

---

## 4. App icon concepts (each with a Cinematic and a Glass rendition)

### I1 "MM Column" (RECOMMENDED, from W2)

The MM column (M, gutter bar, M) sits vertically centred in the squircle and reads both as "MM" and as a scroll strip.
- **Cinematic:** a `#000` field. The stroke is a vertical gradient from `#FF4D2E` (top) to `#8A1C0E` (bottom); the bar is `#FFB25C` with a 24 px bloom at 45%. A Tungsten rim light is a radial gradient at 30% opacity centred at (20%, 15%). Monochrome film grain sits at 2.5%, with a thin horizontal anamorphic streak across the top M's apexes (Ember at 25%, 2 px tall, fading over 70% of the width).
- **Glass:** a deep field running from `#0A0F1F` to `#000`, with an aurora blob of `#8FD8FF`, `#A99BFF` and `#FF9ED8` at 45% opacity and 180 px blur. The MM column is glass in two layers: the bottom M and bar in a back group, the top M in front. With Icon Composer the settings are translucency 0.5, specular on, and a neutral shadow.
- **Why:** it has the strongest silhouette at 29 pt / 48 dp, survives iOS tinted and Android monochrome modes as a pure shape, and matches the wordmark.

### I2 "Gutter Panel"

A tall rounded panel, like a webtoon page, split into an upper and a lower panel by an **M-shaped gutter**: the cut between the panels zigzags as an M.
- **Cinematic:** the upper panel is solid Ember and the lower panel is black. Tungsten light leaks through the M-shaped crack at 60% with a 40 px spill, under a 20% edge vignette.
- **Glass:** two panes, the upper frosted and the lower clear. The M seam is a refractive edge catching a specular line.
- **Why not first:** the M reads only at sizes of 60 px and above. Below that it is "a page with a crack".

### I3 "Open Book M"

An open book seen end-on from above. The top edges of the two page spreads, meeting at the spine, draw an M, and three fanned page layers show behind them. This is the only concept that speaks for novels, the most-read surface.
- **Cinematic:** a Paper book silhouette whose page edges glow Ember from below, as if lit by a screen in a dark room.
- **Glass:** three translucent sheets, fanned and offset in depth (three Icon Composer layers), with a specular highlight along the spine.
- **Why not first:** it lands closer to generic book-app icons (Apple Books, Play Books).

### Platform deliverables for the chosen icon

| Target | Spec | Tool |
|---|---|---|
| iOS master | 1024×1024 PNG, opaque `#000` background | `flutter_launcher_icons` 0.14.4 (MIT) `image_path` |
| iOS 18+ dark | Transparent background; mark only | `image_path_ios_dark_transparent` |
| iOS 18+ tinted | Grayscale mark | `image_path_ios_tinted_grayscale` |
| iOS 26 Liquid Glass (Glass skin, optional) | Icon Composer `.icon` package: a folder holding `icon.json` + `Assets/` (SVG/PNG layers), 1024 canvas, with default/dark/clear/tinted appearances generated from the layers | The `.icon` bundle can be written as text on Linux, but it must compile on the CI runner. The runner is `macos-latest`, so confirm that Xcode is 26 or later (add an `xcodebuild -version` step). Keep the PNG set as a fallback |
| Android adaptive | 108 dp canvas (432 px at xxxhdpi). The mark must stay inside the 66 dp (264 px) safe circle, which puts the MM-column bounding box at about 160×188 px | `adaptive_icon_foreground` / `adaptive_icon_background` |
| Android 13+ themed | Monochrome layer, same geometry | `adaptive_icon_monochrome` |
| Per-skin icon | Both renditions ship; the skin switch (which restarts the app) calls the alternate icon | `flutter_dynamic_icon_plus` 1.4.1 (MIT). On iOS, UIKit shows its own "You have changed the icon" alert after `setAlternateIconName`, even though the package README says the change is silent; test on a device. It lands naturally inside the restart moment. On Android it uses `activity-alias`, and the package keeps a blacklist for launchers that misbehave |
| Web favicon | `favicon.svg`. At 16 px use a single M on the bar (stroke 1.5 px); the full MM column needs 32 px or more | hand-drawn SVG |
| PWA | `icon-192/512.png`, `apple-touch-icon` 180×180 (opaque). `maskable-512`: mark inside the 40%-radius safe circle, a 290×290 px box | export script |
| Web per skin | The PWA icon cannot change at runtime, but `<link rel="icon">` can be swapped to the active skin's SVG on load | 3 lines |
| SideStore source | `iconURL` → new I1 PNG; `tintColor` → `#FF4D2E` | `backend/routes/app_distribution.py` |

---

## 5. Splash screens

**The native layer is neutral.** An iOS `LaunchScreen.storyboard` is static and cannot know which skin is active, so both platforms show one neutral mark: the MM column in `#F3EEE6` on `#000000`. This keeps the native splash honest on both platforms.
- `flutter_native_splash` 2.4.8 (MIT): `color: "#000000"`, `image: brand/splash/mm-neutral.png` (1152×1152), and `android_12: { image: brand/splash/mm-neutral-a12.png, color: "#000000" }`.
- Android 12+ sizing: with no icon background the icon box is 288 dp and the visible circle 192 dp; with an icon background it is 240 dp and 160 dp. The mark sits inside the 192 dp circle.
- Optional, Android 13+ only: `SplashScreen.setSplashScreenTheme()` persists a per-skin splash theme for future cold starts, so Android could show an Ember or aurora mark. iOS cannot match this, so skip it unless the asymmetry is acceptable.

**Handoff.** The first Flutter frame redraws the neutral mark at exactly the native size and position, then plays the skin's reveal (section 6), so there is no visible seam.

**Web.** There is no native splash. The root layout server-renders an inline SVG of the neutral mark, centred on `#000`, and it plays the same reveal after hydration. For the installed iOS PWA, set `appleWebApp.startupImage` to black images; without them there is a white flash before the first paint.

**Skin-switch restart.** The old state is gone, so play the new skin's full reveal. That moment is the event where "everything changes".

---

## 6. Logo reveal motion

The owner-mandated letter reveal (fade, slide up and un-blur per letter, staggered) is reused for the wordmark. The mandated 50 ms-per-character typing reveal runs *after* the logo, on the Home greeting ("Tonight's lineup" in Cinematic, "Welcome back, {profile}" in Glass).

### Cinematic: "Projector" (cold start 1,400 ms; warm start 450 ms)

| t (ms) | Element | Motion |
|---|---|---|
| 0–120 | whole frame | hold on black (the flash frame) |
| 120–520 | light sweep | a 24 px Tungsten `#FFB25C` band, blurred 40 px, crosses the MM column left to right as a gradient mask; `cubic-bezier(0.65, 0, 0.35, 1)` |
| 300–900 | wordmark letters | per letter: opacity 0→1, y +0.35 em→0, blur 12 px→0; 420 ms each, 28 ms stagger; `cubic-bezier(0.16, 1, 0.3, 1)` (expo-out) |
| 820 | the "stamp" | MM column scales 1.06→1.00 over 160 ms, `cubic-bezier(0.2, 0, 0, 1)`; haptic `stamp` and (if sound is on) `sting` hit |
| 900–1,300 | ember bloom | a radial `#FF4D2E` glow behind the mark rises from 0 to 35% then settles at 18%; radius 0.6→1.1× the mark |
| 1,300–1,400 | handoff | the mark flies to the nav slot as a shared element (Flutter `Hero`, framer-motion `layoutId`) over 380 ms, `cubic-bezier(0.2, 0, 0, 1)` |

Warm start (app resumed within 4 h): mark opacity 0→1 over 200 ms, then the same 250 ms handoff, with no sweep, letters or haptic.

### Glass: "Droplet" (cold start 1,200 ms; warm start 400 ms)

| t (ms) | Element | Motion |
|---|---|---|
| 0–200 | droplet | a 24 px glass circle drops to centre on a spring (stiffness 260, damping 20, mass 1); haptic `soft` on landing |
| 200–700 | lens | the droplet grows into a squircle lens (corner 28%) on a spring (stiffness 180, damping 22). Inside it the MM column is refracted: displacement 40→0, chromatic aberration 3 px→0 |
| ~700 | settle | haptic `rigid` (a light tick); if sound is on, the `logo` arpeggio starts |
| 500–1,000 | wordmark letters | letters rise from behind the lens: blur 16 px→0, opacity 0→1, 24 ms stagger, spring stiffness 220 / damping 26 |
| 1,000–1,200 | handoff | the lens morphs into the tab-bar capsule or the nav glass (shared element), spring 180/22 |

Implementation, with no new dependency (ladder rung: already installed):
- **Web:** framer-motion 12 (`transition={{ type: "spring", stiffness: 180, damping: 22 }}`); animate `filter: blur()` per letter `<span>`. The refraction is an SVG `feDisplacementMap`; the kube.io liquid-glass write-up and `liquid-glass-react` 1.1.1 (MIT) in `design-ref/` are references.
- **Flutter:** `SpringSimulation(SpringDescription(mass: 1, stiffness: 180, damping: 22), …)`; `Cubic(0.16, 1, 0.3, 1)`; per-glyph `ImageFiltered(imageFilter: ImageFilter.blur(...))` across 13 glyphs (flagship-only, per the owner). The Glass lens can use `liquid_glass_renderer` 0.2.0-dev.4 (MIT, Flutter ≥3.32.4, Impeller) or `liquid_glass_widgets` 1.7.2 (MIT, Flutter ≥3.41). Both are in `design-ref/` and both fit CI's 3.44.6.
- **Reduced motion** (OS setting): both skins fall back to a 200 ms crossfade with no blur, no sweep or droplet, and one `light` haptic.
- Tapping anywhere skips to the handoff.
- Lottie and Rive are skipped: both reveals are code-driven, and exported animation files would duplicate them per platform.

---

## 7. Typography

### Verified availability

| Family | Axes (Google Fonts API) | License (`google/fonts` METADATA.pb) | Variable TTF size | `google_fonts` 8.2.1 (max for Flutter 3.44.6) | `next/font` 16.2.9 |
|---|---|---|---|---|---|
| Big Shoulders | `opsz 10–72`, `wght 100–900` | OFL | 320,800 B | yes (static weights only) | yes, `Big_Shoulders`, `axes: ['opsz']` |
| Geist | `wght 100–900` | OFL | 169,056 B | yes | yes, `Geist` |
| Geist Mono | `wght 100–900` | OFL | 171,948 B | yes | yes, `Geist_Mono` |
| Google Sans Flex | `GRAD 0–100`, `ROND 0–100`, `opsz 6–144`, `slnt −10–0`, `wdth 25–151`, `wght 1–1000` | OFL (added 2025-11-12) | 4,153,392 B raw → **510,192 B** subset (see below) | yes (static w100–w900 only, about 123 KB each; no `ROND`) | yes, `Google_Sans_Flex`, `axes: ['GRAD','ROND','opsz','slnt','wdth']` |
| Google Sans Code | `wght 300–800` | OFL | 126,224 B | yes | yes, `Google_Sans_Code` |
| Newsreader | `opsz 6–72`, `wght 200–800` | OFL | 451,664 B | yes | yes |
| Literata | `opsz 7–72`, `wght 200–900` | OFL | 955,132 B | yes | yes |
| Mona Sans (alternate) | `wdth 75–125`, `wght 200–900` | OFL | 349,140 B | yes | yes, `Mona_Sans` |
| Noto Sans KR / JP / SC (CJK fallback) | `wght 100–900` | OFL | several MB each | yes | yes; `preload: false` (the `subsets` enum lacks `korean`, but Google's CSS still ships the unicode-range slices) |

**Key finding for Flutter.** The `google_fonts` package source maps each family to static per-weight files (`GoogleFontsVariant(fontWeight: w100…w900)`), and the library never uses `FontVariation`. `ROND`, `opsz` and `wdth` are therefore unreachable through it. Version 9.0.0 (2026-09-28) also requires Flutter ≥3.47 / Dart ^3.13, above the CI pin. So bundle the variable TTFs from `github.com/google/fonts/tree/main/ofl/<family>` as assets, exactly as `Syne.ttf` and `DMSans.ttf` are bundled today.
- In Flutter, set both `fontWeight` (for fallback and semantics) and `FontVariation('wght', …)`.
- Flutter does not apply `opsz` automatically, so pass `FontVariation('opsz', fontSize)` per style. CSS gets this free through `font-optical-sizing: auto`.

**Subsetting Google Sans Flex** with fonttools (MIT, dev-only), measured on 2026-09-29:
- Latin subset plus pinning `GRAD=0 slnt=0 wdth=100`, keeping `opsz`, `wght` and `ROND`: **510,192 B TTF / 229,052 B WOFF2**. Keeping `wdth 75:125` instead gives 1,126,876 B. Pinning further to `opsz 18:144`, `wght 300:800` gives 395,852 B.
- Commands:
  - `pyftsubset GoogleSansFlex[...].ttf --unicodes="U+0000-024F,U+1E00-1EFF,U+2000-206F,U+2070-209F,U+20AC,U+2100-214F,U+2190-21FF,U+2212,U+2215" --layout-features='*' --output-file=gsf-latin.ttf`
  - `fonttools varLib.instancer gsf-latin.ttf GRAD=0 slnt=0 wdth=100 -o GoogleSansFlex-MM.ttf`

### Cinematic pairing

| Role | Family and settings | Mobile → desktop |
|---|---|---|
| Hero title | Big Shoulders `opsz 72`, `wght 900`, UPPERCASE, tracking −0.01 em | 56/52 → 96/88 |
| Section header (H3, letter reveal) | Big Shoulders `opsz 36`, `wght 800`, UPPERCASE | 28/28 → 40/40 |
| Title | Geist `wght 600`, tracking −0.01 em | 20/26 → 24/30 |
| Body | Geist `wght 400` | 15/22 → 16/24 |
| Label | Geist `wght 560`, UPPERCASE, +0.06 em | 12/16 |
| Numerals / meta | Geist Mono `wght 500`, `tnum`, e.g. `CH 142 · 12 MIN` | 12/16 → 13/18 |
| Novel reader default | Newsreader `opsz` = size, `wght 420` | 18/30 |

The rationale is poster condensed display over a crisp Swiss UI face: Big Shoulders' Chicago-signage caps give the title-card energy, and Geist with Geist Mono is one design family, so body and meta never fight. Alternate display: **Mona Sans**, with `wdth 75` for poster titles and `wdth 125` for credit-style labels in one file, if Big Shoulders reads too narrow.

### Glass pairing

| Role | Family and settings | Mobile → desktop |
|---|---|---|
| Large title | Google Sans Flex `wght 680`, `ROND 100`, `opsz` = size, tracking −0.02 em | 34/40 → 56/60 |
| Title | GSF `wght 620`, `ROND 60` | 20/25 → 24/30 |
| Body | GSF `wght 420`, `ROND 0`, `opsz` = size | 16/22 → 17/24 |
| Caption | GSF `wght 520`, `ROND 30` | 12/16 |
| Mono | Google Sans Code `wght 500` | 13/18 |
| Novel reader default | Literata `opsz` = size, `wght 400` (designed for Google Play Books) | 18/30 |

The rationale follows Apple's own model. One superfamily with optical sizes serves both display and text, the way SF Pro serves visionOS, and `ROND` 0→100 gives the SF Pro Rounded softness on titles without a second family. Google Sans Code pairs by design. One display/body file plus one mono file keeps the bundle to two files plus the reading serif. If a separate body face is wanted anyway, Inter (`opsz 14–32`, 876,576 B, OFL) is the fallback.

### Loading recipes

```ts
// web: frontend/src/app/layout.tsx (next 16.2.9)
import { Big_Shoulders, Geist, Geist_Mono, Google_Sans_Flex, Google_Sans_Code, Newsreader, Literata } from "next/font/google";
const cineDisplay = Big_Shoulders({ subsets: ["latin"], axes: ["opsz"], variable: "--font-cine-display" });
const glassSans   = Google_Sans_Flex({ subsets: ["latin"], axes: ["ROND", "opsz"], variable: "--font-glass-sans", preload: false });
// …the rest the same way. Only the default skin's fonts preload; the splash covers the other skin's swap.
```

```dart
// Flutter: bundled asset, family "GoogleSansFlexMM"
const TextStyle(
  fontFamily: 'GoogleSansFlexMM', fontSize: 34, fontWeight: FontWeight.w700,
  fontVariations: [FontVariation('wght', 680), FontVariation('ROND', 100), FontVariation('opsz', 34)],
);
```

**CJK titles.** Manhwa titles often arrive in Hangul. On mobile, rely on the system fallback (Apple SD Gothic Neo, Noto CJK) and do not bundle multi-MB CJK fonts. On web, add `Noto_Sans_KR` / `JP` / `SC` with `preload: false` to each skin's `font-family` stack.

---

## 8. Iconography

### Comparison (verified from the published packages)

| | Phosphor | Lucide | Hugeicons |
|---|---|---|---|
| Web package | `@phosphor-icons/react` 2.1.10 (MIT); core 2.1.1 | `lucide-react` 1.48.0 (ISC); the app currently uses `^1.22.0` | `@hugeicons/react` 1.1.10 + `@hugeicons/core-free-icons` 4.3.5 (MIT) |
| Icons (web) | **1,512 × 6 weights**: thin, light, regular, bold, fill, duotone (duotone secondary layer at opacity 0.2) | 2,118, stroke only | about 6,070, **free style is stroke-rounded only**; solid, duotone, bulk and sharp are Pro (paid) |
| Flutter package | `phosphor_flutter` 2.1.0 (MIT), 6 icon fonts | `lucide_icons_flutter` 3.1.20 (MIT, third-party, `vqh2602`), stroke weights as 6 fonts `Lucide100…600` | `hugeicons` 1.2.0 (MIT), 6,063 icons as SVG path data rendered through `flutter_svg` (not a font) |
| Parity | **1,512/1,512 in every weight** (name diff; the only quirk is the Dart name `pictureInpicture`) | Tracks Lucide 1.46.0, so 2,098 of 2,118: 16 missing vs 1.48.0 (e.g. `house-cog`, `rotate-cw-clock`, `square-sparkles`) | ≈ equal free set |
| Filled or active states | **Fill + Duotone built in** | none; active tabs need custom fills | none in the free set |
| Freshness | Frozen: core last released 2024-03-29, Flutter 2024-05-10 | Active (weekly) | Active |
| Next.js | Not in Next's default `optimizePackageImports` list, so add it; use `@phosphor-icons/react/ssr` (exported, also `/dist/ssr`) in server components | Optimized by default | n/a |

**Decision: Phosphor on both platforms.** It is the only set with filled and duotone variants on both React and Flutter at exact parity, and its six weights give each skin its own icon voice from one library. The freeze does not matter here: the set is complete for this app, and domain gaps are custom anyway.

| Skin | Default | Active / selected | Large ornamental (≥32 px) | Sizes |
|---|---|---|---|---|
| Cinematic | **Bold** (24/256 stroke, ≈2.25 px at 24 px) | **Fill** | Bold | 20 / 24 / 28 |
| Glass | **Regular** (16/256 ≈ 1.5 px at 24 px) | **Duotone** (secondary at 0.2) morphing to **Fill** on press | Light (12/256) | 20 / 22 / 28 |

Phosphor covers the domain words checked: `book-open`, `books`, `scroll`, `film-strip`, `film-reel`, `popcorn`, `projector-screen`, `flame`, `fire`, `waveform`, `user-sound`, `headphones`, `subtitles`, `closed-captioning`, `chat-circle-text`, `magnifying-glass`, `text-aa`, `text-columns`, `shield-check`, `lock-key`, `plugs`, `download-simple`, `cloud-arrow-down`, `bell-ringing`, `users-three`, `hand-heart`, `share-network`, `sparkle`, `robot`, `brain`, `chart-pie-slice`, `trophy`, `calendar-check`, `clock-counter-clockwise`, `gauge`, `frame-corners`, `arrows-vertical`, `eyeglasses`, `scan`, `ticket`, `music-notes`, `hand-tap`, `hand-swipe-left/right`. It lacks `sparkles` (plural) and `hand-swipe-up`.

**Custom glyphs (6).** Draw these on Phosphor's 256×256 grid in the two weights each skin needs (Bold + Fill, Regular + Duotone), exported as flattened paths:
1. `mm-mark`: the MM column
2. `strip-scroll`: a vertical webtoon strip with a down chevron, for the manhwa reader and auto-scroll
3. `panel-focus`: a panel inside corner brackets, for the panel-by-panel guided view
4. `bubble-search`: a speech bubble with a magnifier, for OCR dialogue search
5. `age-gate`: a seal with "18", for the 18+ gate
6. `voice-31`: `user-sound` plus a stacked badge, for the TTS voice picker

On the web they become React components from the SVGs. For Flutter, build one small TTF with `fantasticon` (npm, MIT; build-time only) plus a `const IconData` class, so the glyphs tree-shake like Phosphor's.

---

## 9. Haptic identity

**Package: `gaimon` 1.5.0** (MIT, Flutter ≥3.41, fits CI's 3.44.6). It gives:
- named calls: `selection`, `light`, `medium`, `heavy`, `rigid`, `soft`, `success`, `warning`, `error`
- `Gaimon.patternFromData(ahapJson)`, which plays Core Haptics AHAP on iOS and auto-converts it to an amplitude waveform on Android

The converter ignores `AttackTime`, `DecayTime` and sustained events, so **author the AHAP signatures below with transients and continuous events only**, and Android will match them. On Android, gaimon's `light/medium/heavy` hit graded effects rather than `performHapticFeedback` constants, which "carry no strength" (from its source).

The alternative is `haptic_feedback` 0.6.5 (BSD-3). It has named types only with no custom patterns, and its 0.7+/0.8.0 releases need Flutter 3.47.

**Principle.**
- **Cinematic = weight.** Low sharpness (0.15–0.35), higher intensity, and few events. Silence is part of the style: most taps get no haptic.
- **Glass = texture.** High sharpness (0.7–0.95), lower intensity (0.3–0.6), and frequent detent ticks, like fingertips on glass.

All calls route through the existing `Haptics` class and its user toggle. Reader chrome show/hide is silent in both skins because reading is uninterrupted.

| Event | Cinematic | Glass |
|---|---|---|
| Primary button press | `rigid` | `soft` |
| Icon button / chip tap | none | `selection` |
| Toggle on / off | `medium` / `light` | `light` / `selection` |
| Tab switch | `rigid` | `selection` |
| Long-press → context menu | `heavy` | `medium` |
| Sheet detent snap | `medium` (Cinematic prefers full-screen overlays) | `selection` per detent, `soft` at full |
| Overlay / sheet dismiss | `light` | `soft` |
| Pull-to-refresh armed / done | `medium` / none | `rigid` / `selection` |
| Add to library / follow | AHAP **stamp** | `success` |
| Remove from library | `light` | `light` |
| Download start / complete / failed | `light` / AHAP **reel-lock** / `error` | `selection` / `success` / `error` |
| Next-chapter card appears | AHAP **curtain** | `soft` |
| Chapter change committed | `heavy` | `medium` |
| Novel page turn | `selection` | `selection` |
| Scrubber / slider | `selection` every 10% | `selection` every step |
| Auto-scroll speed step | `rigid` | `selection` |
| 18+ gate unlocked | AHAP **vault** | AHAP **unlock** |
| Streak +1 / goal met | AHAP **ignite** | `success` then AHAP **shimmer** |
| Reaction sent | `medium` | AHAP **pop** |
| "Recommend to" sent | `success` | `success` |
| TTS play / pause | `rigid` | `soft` |
| Logo reveal | **stamp** at 820 ms | `soft` at 200 ms, `rigid` at ~700 ms |
| Skin switch confirmed (before restart) | `heavy` | `heavy` |
| Error | `error` | `error` |

AHAP signatures. Each is `{"Version":1.0,"Pattern":[…]}`; T = `HapticTransient`, C = `HapticContinuous`, I = intensity, S = sharpness, all times in seconds.

- **stamp** (Cinematic): T@0.000 I1.0 S0.25; T@0.060 I0.35 S0.10
- **reel-lock** (Cinematic): T@0.000 I0.7 S0.35; T@0.080 I0.9 S0.30
- **curtain** (Cinematic): C@0.000 dur 0.300 I0.35 S0.15; T@0.300 I0.6 S0.2
- **vault** (Cinematic): T@0.000 I0.4 S0.3; T@0.060 I0.6 S0.3; T@0.120 I1.0 S0.25
- **ignite** (Cinematic): C@0.000 dur 0.400 I0.5 S0.2; T@0.400 I1.0 S0.3
- **unlock** (Glass): C@0.000 dur 0.120 I0.4 S0.85; T@0.120 I0.7 S0.9
- **shimmer** (Glass): T@0.00/0.04/0.08/0.12/0.16, I 0.25→0.45, S0.9
- **pop** (Glass): T@0.000 I0.5 S1.0

Example of the literal JSON (stamp):

```json
{"Version":1.0,"Pattern":[
 {"Event":{"Time":0.0,"EventType":"HapticTransient","EventParameters":[{"ParameterID":"HapticIntensity","ParameterValue":1.0},{"ParameterID":"HapticSharpness","ParameterValue":0.25}]}},
 {"Event":{"Time":0.06,"EventType":"HapticTransient","EventParameters":[{"ParameterID":"HapticIntensity","ParameterValue":0.35},{"ParameterID":"HapticSharpness","ParameterValue":0.1}]}}]}
```

**Web.** Android Chrome gets `navigator.vibrate` for a small subset only (add to library `[12]`, error `[20,40,20]`). iOS Safari has no Vibration API. The hidden `<input type="checkbox" switch>` trick (npm `ios-haptics`, `@haptics/*`) is a hack that is reported closed in iOS 26.5, so do not build on it.

---

## 10. Sound identity (UI sound layer, OFF by default)

**Principle.** Each skin gets one small, tonal palette, so that a sequence of sounds resolves musically. There are about 12 files per skin, all synthesized, so there is no licensing and no sample library. Peak levels: ticks −28 dBFS, confirmations −18 dBFS, the logo sting −12 dBFS. Every file has 5 ms fade-in and fade-out.

### Cinematic: "Projector" (key of D, warm, low-passed below 4 kHz, short 0.4 s room)

| Sound | Recipe |
|---|---|
| tap | 8 ms noise burst, band-pass 1.8 kHz (Q 2), plus a 60 Hz sine 30 ms |
| toggle-on / off | two mechanical clicks 18 ms apart / one click |
| stamp (add to library) | 55 Hz sine, 120 ms exponential decay, plus a felt click, synced to the haptic |
| reel-lock (download done) | 2 clicks 80 ms apart, then a Tungsten swell: saw D3 (146.83 Hz), 300 ms, low-pass sweep 400→1600 Hz |
| curtain (next chapter) | filtered-noise riser, 600 ms, high-pass sweep 200 Hz→2 kHz |
| ignite (streak) | 250 ms whoosh plus a D3+A3 fifth, 200 ms |
| error | minor second down, D3→C♯3, saw, low-pass 900 Hz, 180 ms |
| page-turn | pink noise with a 180 ms swish envelope |
| sting (logo) | D2 (73.42 Hz) + A2 (110 Hz) saw pad, low-pass sweep 300→2400 Hz over 700 ms, 1.4 s tail; the transient lands at 820 ms with the stamp |

### Glass: "Prism" (E-major pentatonic, E5 659.25 · F♯5 739.99 · G♯5 830.61 · B5 987.77 · C♯6 1108.73 · E6 1318.51 Hz; sine + FM bell at ratio 3.5 / index 1.2; plate reverb 1.2 s, 18% wet)

| Sound | Recipe |
|---|---|
| tap | 1.2 kHz sine, 14 ms |
| detent | 2.4 kHz click, 6 ms, −30 dBFS |
| toggle-on / off | G♯5→B5 / B5→G♯5, 60 ms each |
| sheet-up / down | sine glide 520→1040 Hz / reverse, 110 ms |
| add | E5+B5 bell dyad, 250 ms |
| download-done | E5, G♯5, B5 arpeggio, 40 ms steps |
| error | two soft taps, B4 (493.88) → G♯4 (415.30), 90 ms each |
| shimmer (streak) | 5 E6 grains, 40 ms apart, rising level |
| logo | E5, G♯5, B5, E6 at 24 ms steps (matching the letter stagger), plus a 1.2 s air pad |

**Production.** A script of `sox -n` `synth` commands (sox is a GPL tool; its output is unencumbered), for example `sox -n -r 48000 -b 16 -c 1 glass-tap.wav synth 0.014 sine 1200 fade 0.005 0.014 0.005 gain -28`. Output is WAV, 48 kHz, 16-bit mono. Each file is a few KB, and each skin stays under 350 KB.

**Playback.**
- Mobile: `flutter_soloud` 5.1.4 (MIT, Flutter ≥3.41). It is low-latency, loads WAV/OGG/MP3/FLAC, and has built-in reverb and waveform synthesis. The Glass tones could even be generated at runtime; ship files first.
- Web: the Web Audio API (native). Decode the WAVs once into `AudioBuffer`s on the first user gesture (autoplay policy), then play them with `AudioBufferSourceNode`.

**Rules.**
- iOS UI sounds must follow the ring/silent switch, which means an `.ambient` session category.
- The app's `audio_session` currently declares SPEECH for TTS narration, so **suppress UI sounds while narration or an ambient soundscape is playing**. Do not switch categories under a live narration.
- Never duck the user's music.

---

## 11. Showcase and "store" screenshot style

**Where the screenshots appear:**
- the install page at `app.manhwamaniacs.xyz`
- the SideStore source's `screenshots` array (AltStore format accepts URLs or `{imageURL, width, height}`, corners auto-rounded, 9:19.5)
- the README
- the OG image

Both the install page and the SideStore source read from `_SHOWCASE` / `mobile/docs/screenshots/`.

**Canvas.**
- Phone: **1320×2868** (App Store 6.9" canonical, and valid 9:19.5 for SideStore).
- Produce it by capturing the web client's mobile layout, which mirrors the phone app, at a **440×956 CSS viewport with `deviceScaleFactor: 3`** (440×3 = 1320, 956×3 = 2868). Use `@playwright/test` ^1.62.1, which the frontend already has, and compose the frame by rendering a small HTML template page in the same Playwright run.
- Desktop section of the install page: 2880×1800. OG image: 1200×630.

**Two sets, one per skin, 5 frames each.** Captions are 5 words or fewer and plain:
1. Home: "Every source. One shelf."
2. Manhwa reader: "Built for the long scroll."
3. Novel + TTS: "Novels, read aloud." (sub: "31 named voices")
4. Stats / Wrapped: "Your year in chapters."
5. Social: "Read together."

**Cinematic "Poster".**
- Frame: the UI capture fills 86% of the width, anchored to the bottom and bleeding off the lower edge, with 64 px corner radius.
- Top band: 640 px of `#000`. Caption in Big Shoulders `opsz 72`, `wght 900`, uppercase, 132 px, line-height 0.92, tracking −0.01 em, Paper, with one keyword in Ember. Subcaption in Geist 500, 44 px, Ash.
- Background: an Ember radial glow (`#FF4D2E` at 22%, radius 900 px) behind the top edge of the UI, plus 3% film grain.
- The caption baseline sits at the same y in every frame, so the carousel reads as a title sequence.

**Glass "Float".**
- Frame: the UI capture sits on a glass slab with 88 px radius, a 1.5 px inner highlight at `rgba(255,255,255,.35)` and a shadow of `0 60px 120px rgba(0,0,0,.6)`, tilted `rotateY(-8deg) rotateX(4deg)`.
- Background: `#000` with aurora blobs of `#8FD8FF`, `#A99BFF` and `#FF9ED8` at 35%, blurred 200 px.
- Caption in Google Sans Flex `ROND 100`, `wght 660`, 112 px, tracking −0.02 em, Frost. Subcaption in GSF `ROND 40`, `wght 450`, 44 px, Mist.

**Content rules.**
- The install page is public, so use a **seeded demo profile**, never a real account. The social and activity frames would otherwise expose what the 2–3 real users read, which breaks per-profile isolation.
- No 18+ content.
- Covers should be self-made placeholder art, or at least not real publisher art in the hero frame.

---

## 12. Asset pipeline and package list

- **Sources.** Keep the masters as SVG in one `brand/` folder: marks, icons in both skins, splash, favicon and custom glyphs. One export script renders PNGs with `resvg` (MPL-2.0) or `rsvg-convert`, then runs `flutter_launcher_icons` and `flutter_native_splash`. There is no design-tool lock-in, and it runs on the Linux laptop.
- **Checks.** Add one script that asserts:
  - each exported PNG's size
  - no alpha on the iOS master
  - the mark's bounding box sits inside the adaptive-icon 66 dp circle and the maskable 40% circle

| Package | Version (verified) | License | Why |
|---|---|---|---|
| `phosphor_flutter` | 2.1.0 | MIT | icons (Flutter) |
| `@phosphor-icons/react` | 2.1.10 | MIT | icons (web) |
| `gaimon` | 1.5.0 (Flutter ≥3.41) | MIT | haptics + AHAP |
| `flutter_soloud` | 5.1.4 (Flutter ≥3.41) | MIT | UI sound |
| `flutter_launcher_icons` | 0.14.4 | MIT | icons incl. iOS dark/tinted + Android monochrome |
| `flutter_native_splash` | 2.4.8 | MIT | native splash incl. Android 12 |
| `flutter_dynamic_icon_plus` | 1.4.1 | MIT | per-skin alternate icon |
| `liquid_glass_renderer` / `liquid_glass_widgets` | 0.2.0-dev.4 / 1.7.2 | MIT / MIT | Glass lens in the splash (shared with the Glass UI) |
| fonttools (dev only) | 4.x | MIT | subset/instance Google Sans Flex |
| `google_fonts` | **not used** | BSD-3 | static weights only; 9.0.0 needs Flutter 3.47 |
| `haptic_feedback` | not used (0.6.5 is the max for 3.44.6) | BSD-3 | no custom patterns |

Fonts: all OFL, bundled from `github.com/google/fonts` (`ofl/bigshoulders`, `ofl/geist`, `ofl/geistmono`, `ofl/googlesansflex`, `ofl/googlesanscode`, `ofl/newsreader`, `ofl/literata`). Ship each `OFL.txt` with the app's licenses (Flutter `LicenseRegistry.addLicense`).

---

## 13. Open questions for the owner

1. **Home-screen label.** "ManhwaManiacs" (13 characters) truncates under an iOS icon. Keep it, or set `CFBundleDisplayName` / `android:label` to "Maniacs" or "Manhwa" (the PWA `short_name` is already "Manhwa")?
2. **Default skin on first launch.** This doc assumes Cinematic, which drives which fonts preload on web and which icon is primary.
3. **Should the app icon follow the skin?** Recommended yes; the cost is one iOS system alert, at the restart.
4. **Android per-skin native splash** via `setSplashScreenTheme` (Android 13+ only; iOS stays neutral)?

---

## 14. Sources

- Google Fonts metadata API: https://fonts.google.com/metadata/fonts, and `google/fonts` METADATA.pb files (license + axes), for example https://raw.githubusercontent.com/google/fonts/main/ofl/googlesansflex/METADATA.pb
- `google_fonts` 8.2.1 source (pub.dev archive), CHANGELOG ("Added fonts: … Google Sans Flex … Science Gothic" in 8.0.0), https://github.com/flutter/packages/tree/main/packages/google_fonts
- Next.js 16.2.9 `dist/compiled/@next/font/dist/google/font-data.json` and `index.d.ts`, and `dist/server/config.js` (default `optimizePackageImports`), read from the app's `node_modules`
- Phosphor: https://github.com/phosphor-icons/react, https://github.com/phosphor-icons/phosphor-flutter, grid notes via https://iconoop.com/phosphor-icons.html
- Lucide: https://github.com/lucide-icons/lucide; Flutter port https://github.com/vqh2602/lucide-flutter-main
- Hugeicons: https://github.com/hugeicons/hugeicons/tree/main/packages/flutter
- gaimon: https://pub.dev/packages/gaimon, https://github.com/istornz/Gaimon; haptic_feedback: https://pub.dev/packages/haptic_feedback
- flutter_soloud: https://pub.dev/packages/flutter_soloud
- flutter_launcher_icons iOS 18 dark/tinted keys: https://pub.dev/packages/flutter_launcher_icons, https://codewithandrea.com/tips/dark-tinted-icons-ios-18/
- flutter_dynamic_icon_plus: https://pub.dev/packages/flutter_dynamic_icon_plus
- Android splash screen spec: https://developer.android.com/develop/ui/views/launch/splash-screen
- Icon Composer / `.icon` format: https://developer.apple.com/icon-composer/, https://www.virtualsanity.com/202507/icon-composer-notes/, https://useyourloaf.com/blog/adding-icon-composer-icons-to-xcode/
- App Store screenshot sizes: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/
- AltStore source format: https://faq.altstore.io/developers/make-a-source
- iOS web haptics hack status: https://github.com/tijnjh/ios-haptics, https://haptics.kushagragolash.dev/
- Liquid glass references in `design-ref/`: https://github.com/whynotmake-it/flutter_liquid_glass, https://github.com/sdegenaar/liquid_glass_widgets, https://github.com/rdev/liquid-glass-react, https://github.com/kube/kube.io
