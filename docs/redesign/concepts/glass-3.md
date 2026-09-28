# Glass concept 3: "Meniscus" (physics-first)

Designer 3 of 3 for the Glass skin. Angle: **springs, gestures, interruptible motion and haptics define the feel.** In Meniscus every surface has mass, every boundary has elasticity, every threshold has a detent you can feel, and every moving thing can be caught mid-flight by a finger. The look (Apple Liquid Glass and visionOS depth on an AMOLED `#000000` canvas) exists to make that physics legible.

Binding inputs: `inventory/00-decisions.md`, `inventory/web.md`, `inventory/mobile.md`, `inventory/capabilities.md`, `research/*.md` (chiefly `glass-language.md`, `gestures-nav.md`, `reader-ux.md`, `brand.md`, `discovery-ux.md`, `flutter-motion-libs.md`, `web-motion-libs.md`), and `stack-decision.md` (Next.js 16 + React 19 + Tailwind 4 + Motion on web, Flutter 3.44.6 on iOS and Android, per-skin screen folders on the shared data layer, one JSON token source in `design/tokens/glass.json`, restart on skin switch).

## Contents

1. Manifesto
2. Tokens (colour, type, spacing, radius, materials and elevation, blur, borders, iconography, motion, haptics, sounds)
3. Component catalog
4. Per-screen specs (desktop web, mobile web, iOS, Android)
5. The four new features
6. The two required signature animations
7. Brand
8. Signature moments
9. Implementation notes

## Conventions used everywhere below

- **Units.** Lengths are logical px (1 CSS px = 1 Flutter logical pixel = 1 iOS pt). Letter spacing is in em; `design/build.mjs` multiplies it by the font size for Dart. Velocities are px/s. Times are ms.
- **Springs** are written `{ms, bounce}`, the format `stack-decision.md` §2.1 fixes. Stiffness `k` and damping `c` (mass 1) are listed beside each token, because the web emits physical springs (see §2.9.3 for why). Conversion: `k = (2π / d)²`, `c = 4π(1 − bounce) / d`, damping ratio `ζ = 1 − bounce`.
- **Curves** are written `{ms, bezier}` and are used for opacity and colour only. Anything that moves in space is a spring.
- **Platforms.** "Phone" means the iOS app, the Android app and mobile web below 768 px together; deltas are listed where they exist. "Tablet" is 768 to 1023 px. "Desktop" is web at 1024 px and wider; "wide" is 1440 px and wider.
- **Token names** are dotted (`glass.color.iris600`). CSS variables use dashes (`--mm-color-iris600`), Tailwind 4 `@theme` drops the skin prefix (`--color-iris600`), Flutter fields are camelCase on `GlassTokens` (`colorIris600`).
- **Contrast** ratios are WCAG 2.2 relative-luminance ratios, computed for this document, against `#000000` unless stated.
- **Inventory coverage** lines cite the row IDs of `inventory/web.md` (letters + numbers such as `LB15`) and `inventory/mobile.md` (screen IDs such as `S09`), so nothing on the checklist is dropped.

---

## 1. Manifesto

Meniscus is the thin curved skin of water that holds a drop together: it bulges, it stretches, it snaps back, and it never tears unless you push it past a line you can feel. That is the whole skin. Nothing on screen moves on a timer; everything moves because something pushed it, and it keeps the momentum it was given. A finger owns an object while it touches it, 1:1, with no lag and no easing; the moment the finger lifts, a spring takes over carrying the finger's exact velocity, projects where the motion *would* come to rest, and settles there. Every animation is a spring on a value that a second touch can catch in mid-flight, reverse, or throw somewhere else, so the interface never makes you wait for it to finish. Every edge is elastic: lists, sheets, zoom limits, the last page of a chapter and the first page of a series all give a little and pull back, and the further you pull the harder they resist. Every stepped value has detents you can feel: pages, voices, speeds, tabs and sheet heights tick under the thumb like a watch crown, and crossing a commit line gives one clear click so you know the action will happen before you let go, and a softer one if you back out. Heavy things move heavily and small things move quickly: a sheet has more mass than a chip, and its spring is slower because of it, not because someone typed a longer duration. Glass is the material that makes this physics visible: floating capsules of Liquid Glass over true AMOLED black, bending the colour of the covers and pages beneath them, swelling and brightening under the finger instead of dimming, stretching in the direction of travel, and thickening as they grow. Content is never glass; it is the water the glass floats on. When Reduce Motion is on, the elasticity goes away but the finger still owns what it touches; when Reduce Transparency is on, the same objects become solid slabs of the same shape and weight. If an interaction in this skin would feel the same with the physics removed, it has been designed wrong.

---

## 2. Tokens

### 2.1 Colour

#### 2.1.1 Canvas and the Graphite ramp

A near-neutral ramp with a faint violet cast (hue about 250°, chroma below 0.01 in OKLCH), so neutral surfaces sit in the same temperature as the Iris tint. The canvas is always `#000000`; the ramp exists for content-layer slabs, fills and text.

| Token | Hex | vs `#000000` | vs `surface1` `#131317` | Role |
|---|---|---|---|---|
| `g0` | `#000000` | 1.00 | 1.13 | Canvas, reader background, every screen edge |
| `g25` | `#060608` | 1.04 | 1.09 | Ambient field floor (where blobs fade to) |
| `g50` | `#0B0B0F` | 1.07 | 1.06 | Wide-reader side gutters |
| `g100` | `#131317` | 1.13 | 1.00 | `surface1`: grouped lists, cards that need a slab, input wells on black |
| `g150` | `#1A1A20` | 1.21 | 1.07 | `surface2`: rows inside `surface1`, skeleton base |
| `g200` | `#222229` | 1.33 | 1.17 | `surface3`: pressed row, segmented thumb at rest, skeleton highlight |
| `g300` | `#2D2D35` | 1.54 | 1.36 | Opaque separator, disabled track |
| `g400` | `#3C3C46` | 1.93 | 1.70 | Unfilled slider track on `surface1`, hairline icons on slabs |
| `g500` | `#56565F` | 2.89 | 2.55 | Disabled glyphs (exempt from contrast) |
| `g600` | `#76767F` | 4.67 | 4.12 | Meta text at 15 px and larger only |
| `g700` | `#9A9AA4` | 7.53 | 6.65 | Secondary text on slabs |
| `g800` | `#BDBDC6` | 11.26 | 9.93 | Icon default on black |
| `g900` | `#DCDCE3` | 15.39 | 13.58 | Emphasised secondary text |
| `g950` | `#ECECF1` | 17.83 | 15.74 | Novel ink on the Glass paper |
| `g1000` | `#F7F7FA` | 19.64 | 17.33 | Specular core, the brightest pixel the skin draws |

#### 2.1.2 Text and fill roles

Text on content (black or slabs) may use alpha for hierarchy. **Text on glass never does**: over a bright page, alpha text collapses, so hierarchy on glass is carried by weight and size, and every glyph on glass is `onGlass`.

| Token | Value | Composite on `#000` | Contrast on `#000` / `surface1` / `surface3` | Use |
|---|---|---|---|---|
| `label1` | `#F2F2F7` | `#F2F2F7` | 18.82 / 16.61 / 14.16 | Primary text, titles, values |
| `label2` | `rgba(235,235,245,0.64)` | `#96969D` | 7.15 / 6.88 / 6.32 | Secondary text, meta lines |
| `label3` | `rgba(235,235,245,0.52)` | `#7A7A7F` | 4.92 / 4.92 / 4.67 | Placeholders, timestamps, captions at 13 px and up |
| `label4` | `rgba(235,235,245,0.24)` | `#38383B` | 1.80 | Disabled text and decorative rules only |
| `onGlass` | `#F2F2F7` | n/a | ≥ 4.85 over a pure white page with the adaptive underlay (§2.1.7) | Every glyph and label drawn on glass |
| `onTint` | `#FFFFFF` | n/a | 5.58 on tinted glass over black, 4.61 over a white page | Labels on the one tinted action |
| `fill1` | `rgba(120,120,128,0.36)` | | | Slider track on black, toggle track off |
| `fill2` | `rgba(120,120,128,0.30)` | | | Chip at rest, stepper well |
| `fill3` | `rgba(118,118,128,0.22)` | | | Search well on black, segmented track |
| `fill4` | `rgba(118,118,128,0.16)` | | | Hover wash on rows |
| `separator` | `rgba(84,84,96,0.55)` | | | Hairlines on glass and slabs, drawn 0.5 px |
| `separatorOpaque` | `g300` `#2D2D35` | | | Hairlines on black |

#### 2.1.3 The one accent: Iris

One violet accent, used as a **tint** (on the single primary action per screen, on selection droplets, on progress fill) and as **accent text/iconography** on black. It is never a flat fill on large areas.

| Token | Hex | vs `#000` | White on it | Black on it | Role |
|---|---|---|---|---|---|
| `iris100` | `#E4DFFF` | 16.30 | 1.29 | 16.30 | Specular tip on tinted glass |
| `iris200` | `#D0C8FF` | 13.39 | 1.57 | 13.39 | Pressed accent text |
| `iris300` | `#BCB0FF` | 10.79 | 1.95 | 10.79 | Focus ring, accent text on glass |
| `iris400` | `#A99BFF` | 8.82 | 2.38 | 8.82 | Accent text and icons on black, links, "new" badges, active tab glyph |
| `iris500` | `#8F7EFF` | 6.60 | 3.18 | 6.60 | Progress fill, slider fill, selection ring |
| `iris600` | `#7563F2` | 4.82 | 4.35 | 4.82 | Tint colour of the tinted glass (applied at 86 % over the underlay) |
| `iris700` | `#5B4AD1` | 3.35 | 6.28 | 3.35 | Pressed tint, tint on bright backdrops |
| `iris800` | `#4336A3` | 2.30 | 9.15 | 2.30 | Ambient field default blob |
| `iris900` | `#2B2370` | 1.58 | 13.32 | 1.58 | Ambient field floor for the Default mood |

#### 2.1.4 Semantic roles

Each semantic colour is used three ways: as text/icon on black (the hex), as a badge fill (the hex at 18 % over black with the hex as text), and as a solid chip (the hex with black text). Every pairing passes 4.5:1.

| Token | Hex | vs `#000` | vs `surface1` | Black on it | Meaning |
|---|---|---|---|---|---|
| `success` | `#3DDC84` | 11.77 | 10.39 | 11.77 | Saved offline, completed, healthy, streak kept |
| `warning` | `#FFB547` | 11.95 | 10.55 | 11.95 | Stale copy, paused, storage nearly full, overdue check |
| `danger` | `#FF5C5C` | 6.94 | 6.12 | 6.94 | Destructive, failed, down |
| `info` | `#6CB8FF` | 9.94 | 8.77 | 9.94 | Neutral notices, "Library" search group |
| `mature` | `#FF5C93` | 7.20 | 6.36 | 7.20 | The 18+ badge, only where mature content is actually shown |
| `streak` | `#FF8A3D` | 8.95 | 7.90 | 8.95 | Streak flame body |
| `streakCore` | `#FFD166` | 14.56 | 12.85 | 14.56 | Streak flame core, milestone numerals |
| `bloom` | `#FF9ED8` | 11.13 | 9.83 | 11.13 | Social: reactions, "recommended to you", friend activity |
| `new` | `iris400` | 8.82 | | | Unread and "N new" |
| `offline` | `warning` | | | | Offline pill, stale catalogue chip |

Reading-status colours (series status pills): Reading `iris400`, Completed `success`, On hold `warning`, Plan to read `info`, Dropped `g700`, Unread `g800`. Status pills always carry the word; colour is never the only signal.

#### 2.1.5 Speaker palette (novel dialogue attribution)

`capabilities.md` §19.2 orders a book's cast by line count, so the two busiest speakers take the two most distinct hues. Ten hues, all ≥ 9.7:1 on black, spaced around the OKLCH hue circle at L ≈ 0.80. On the page each is used as a background band at 14 % alpha with a 1.5 px underline at 60 % alpha; on the cast sheet as a 12 px swatch.

| Order | Token | Hex | vs `#000` |
|---|---|---|---|
| 1 | `spk1` sky | `#7CC4FF` | 11.20 |
| 2 | `spk2` apricot | `#FFB27A` | 11.90 |
| 3 | `spk3` lime | `#9BE58A` | 13.97 |
| 4 | `spk4` lilac | `#D7A4FF` | 10.64 |
| 5 | `spk5` rose | `#FF8FA3` | 9.71 |
| 6 | `spk6` teal | `#6FE3D4` | 13.61 |
| 7 | `spk7` gold | `#FFD86B` | 15.29 |
| 8 | `spk8` periwinkle | `#A7B4FF` | 10.62 |
| 9 | `spk9` orchid | `#F59BD6` | 10.54 |
| 10 | `spk10` olive | `#C8D98A` | 13.75 |

An eleventh speaker and beyond reuse the list from the top with a dashed underline instead of a solid one, so identity never depends on hue alone.

#### 2.1.6 Mood refraction (the seven profile moods)

A profile's mood is the colour its ambient field falls back to when a screen has no art (Home before data, Library empty, Settings, You). It never touches the reader.

| Mood | Blob colour | vs `#000` | Blob opacity |
|---|---|---|---|
| Romantic | `#FF7AA8` | 8.60 | 20 % |
| Action | `#FF6B4A` | 7.45 | 20 % |
| Comedy | `#FFC94D` | 13.71 | 16 % |
| Horror | `#C0506F` | 4.62 | 26 % |
| Slice of Life | `#9FD98A` | 12.77 | 16 % |
| Fantasy | `#9B8CFF` | 7.59 | 22 % |
| Default | `iris800` `#4336A3` + `iris900` | 2.30 | 30 % |

#### 2.1.7 Scrims, dims and the legibility floor

| Token | Value | Use |
|---|---|---|
| `dimSheet` | `rgba(0,0,0,0.28)` | Behind partial-detent sheets |
| `dimModal` | `rgba(0,0,0,0.48)` | Behind alerts, the command palette and full-height sheets |
| `dimContext` | `rgba(0,0,0,0.55)` + backdrop blur 12 | Behind a lifted context preview |
| `dimClear` | `rgba(0,0,0,0.35)` | Under clear glass on bright media (hero spotlight, image viewer) |
| `edgeSoft` | `linear-gradient(to bottom, rgba(0,0,0,0.72), transparent)` over 72 px + safe-area inset, backdrop blur 6 | Under every floating bar group, one per edge |
| `edgeHard` | `rgba(0,0,0,0.92)` + 0.5 px `separator` | Under pinned section headers |
| `underlay` | `rgba(0,0,0,0.30)` | Inside every glass surface, beneath the glass fill |
| `underlayAdaptive` | `rgba(0,0,0, lerp(0.30, 0.66, smoothstep(0.25, 0.75, Lb)))` | Reader chrome only; `Lb` is the relative luminance of the page region under the chrome, from the page-tint sampler (§2.1.8) |

The legibility floor, verified for this document: a dock label (`onGlass`, 11 px, weight 600) over a **pure white** backdrop sits on `edgeSoft` (about 0.5 at the dock's position) + `underlay` 0.30 + glass fill 6 % white, a composite of `#646464`, for **5.30:1**. In the reader, where the edge scrim fades with the chrome, `underlayAdaptive` reaches 0.66 over a white page for a composite of `#616161`, for **5.55:1**, and the tinted action reaches **4.72:1**.

#### 2.1.8 Ambient field and colour extraction

Glass over pure `#000000` has nothing to bend. Meniscus therefore keeps colour under the chrome on every screen through an **ambient field** (z 0.5, behind content).

**The field.** Three soft blobs, circles of diameter 70 % of the viewport width, blurred 120 px (phone) or 180 px (desktop), placed at (18 %, 8 %), (78 %, 14 %) and (46 %, 36 %) of the viewport, opacity 18 to 28 % per the source. Everything below 60 % of the viewport height fades to `g25` and then `#000000`, so the lower screen stays true black for AMOLED. The blobs drift on the `drift` spring toward new random targets within ±6 % of their anchors every 14 s, so the field breathes without looping. Reduce Motion freezes them.

**Sources, by screen.**

| Screen | Field source | Blob opacity |
|---|---|---|
| Home | The focused hero spotlight's cover palette; cross-fades when the spotlight pages | 26 % |
| Series detail | That series' cover palette | 28 % |
| Library, Sources, Search, Updates, History, Bookmarks, Collections | The cover palette of the first visible item; a new palette is taken only when the list stops scrolling for 600 ms | 18 % |
| Profile picker | The focused profile's mood colour | 30 % |
| Settings, You, admin, auth | The active profile's mood colour (§2.1.6); auth uses the brand aurora `#8FD8FF`, `#A99BFF`, `#FF9ED8` | 20 % |
| Manga reader chrome | The current page's palette (page-tinted chrome, §5.4.4) | tint only, no blobs |
| Novel reader | None: the paper is the backdrop | none |

**Extraction.**

1. **Server first** (`stack-decision.md` §2.6: per-cover and per-page palettes are backend work). The backend quantises a 64 px thumbnail with Pillow `Image.quantize(colors=5, method=MEDIANCUT)` and ships `palette: [{hex, population}]` with every series payload and, for pages, with the chapter manifest (`pages[].palette`).
2. **Client fallback** when a payload lacks a palette (sources not yet processed, downloaded chapters): web decodes a 32 × 32 copy with `fast-average-color` 9.6.0 (`algorithm: 'dominant'`) and, for three coordinated blobs, `colorthief` 3.5.0 `getSwatches()` (Vibrant, Muted, DarkVibrant); Flutter decodes a 64 px `ResizeImage` and runs `QuantizerCelebi().quantize(pixels, 32)` then `Score.score()` from `material_color_utilities` 0.13.0 in `compute()`. Results are cached per image URL for the session.
3. **Clamping** (in OKLCH, so the field never glares or muddies): lightness clamped to 0.55 to 0.78, chroma clamped to 0.06 to 0.16, hue kept. Near-greys (chroma below 0.03 before clamping) are replaced by the profile's mood colour. The three blobs take the three highest-scoring swatches; if fewer than three exist, the first is reused at 60 % size.
4. **Transitions.** Field colours never jump: each blob cross-fades its colour over 900 ms `{bezier: [0.2, 0, 0, 1]}` (colour is timed, never sprung). The glass tint derived from the field (§2.5 materials) follows with the same curve.
5. **Page tint for the reader** is sampled from the page occupying the reading line (38 % down the viewport) every 600 ms while scrolling and once on settle, cached per page URL (§5.4.4).

### 2.2 Typography

#### 2.2.1 Families (all from Google Fonts, all SIL Open Font License 1.1)

| Role | Family | Axes used | Licence | Delivery |
|---|---|---|---|---|
| UI, display and body | **Google Sans Flex** | `wght` 300 to 800, `opsz` 6 to 144, `ROND` 0 to 100 (`GRAD`, `slnt` and `wdth` pinned to 0, 0 and 100) | OFL-1.1 | Web: `next/font/google` `Google_Sans_Flex({ subsets: ["latin"], axes: ["ROND", "opsz"], variable: "--font-glass-sans" })`. Flutter: bundled subset `GoogleSansFlexMM.ttf` (510,192 B, from `pyftsubset` + `fonttools varLib.instancer GRAD=0 slnt=0 wdth=100`, per `brand.md` §7) |
| Numerals that must not jitter, codes, keycaps | **Google Sans Code** | `wght` 300 to 800 | OFL-1.1 | Web `Google_Sans_Code`; Flutter bundled `GoogleSansCode.ttf` (126,224 B) |
| Novel reading face (default) | **Literata** | `opsz` 7 to 72, `wght` 200 to 900 | OFL-1.1 | Web `Literata({ axes: ["opsz"] })`; Flutter bundled `Literata.ttf` (955,132 B), loaded on first novel open |
| Novel alternative sans | Google Sans Flex at `ROND 0`, `opsz` = size | as above | OFL-1.1 | Already loaded |
| CJK titles | Noto Sans KR, Noto Sans JP, Noto Sans SC | `wght` | OFL-1.1 | Web `preload: false` in the font stack; Flutter uses the system CJK fallback (Apple SD Gothic Neo, PingFang, Noto CJK on Android) and bundles nothing |

`ROND` is Meniscus's typographic physics: rounded terminals read as surface tension. Titles are fully round (`ROND 100`), body is sharp (`ROND 0`) for reading, and weights in between interpolate. On press, a button label's `wght` rises by 40 over the `press` spring (Flutter animates `FontVariation('wght')`; web animates `font-variation-settings`), so a pressed word looks denser, as if compressed.

Every OFL `OFL.txt` ships with the app's licence list (Flutter `LicenseRegistry.addLicense`; web `/licenses` in About).

#### 2.2.2 Type scale per breakpoint

Size / line height in px, weight, `ROND`, tracking in em. `opsz` always equals the rendered size (CSS `font-optical-sizing: auto`; Flutter passes `FontVariation('opsz', size)` explicitly).

| Style | Phone (< 768) | Tablet (768–1023) | Desktop (1024–1439) | Wide (≥ 1440) | Weight | ROND | Tracking |
|---|---|---|---|---|---|---|---|
| `display` (splash wordmark, Wrapped numbers, hero titles) | 44/48 | 52/56 | 64/68 | 72/76 | 720 | 100 | −0.025 |
| `largeTitle` (tab roots, screen titles) | 34/40 | 36/42 | 40/46 | 44/50 | 700 | 100 | −0.020 |
| `title1` (series title on detail, Wrapped card titles) | 28/34 | 30/36 | 32/38 | 34/40 | 680 | 80 | −0.015 |
| `title2` (sheet titles, section headers H3) | 22/28 | 22/28 | 24/30 | 26/32 | 650 | 60 | −0.010 |
| `title3` (card titles, dialog titles) | 20/25 | 20/25 | 20/26 | 22/28 | 620 | 40 | −0.008 |
| `headline` (row titles, button labels L) | 17/22 | 17/22 | 16/22 | 16/22 | 600 | 20 | −0.005 |
| `body` (paragraphs, descriptions) | 17/24 | 17/24 | 16/24 | 16/24 | 420 | 0 | 0 |
| `callout` (inline notices, list secondary) | 16/22 | 16/22 | 15/22 | 15/22 | 420 | 0 | 0 |
| `subhead` (chips, segmented labels, meta) | 15/20 | 15/20 | 14/20 | 14/20 | 460 | 10 | 0.002 |
| `footnote` (captions under cards, helper text) | 13/18 | 13/18 | 13/18 | 13/18 | 460 | 10 | 0.005 |
| `caption1` (timestamps, badges) | 12/16 | 12/16 | 12/16 | 12/16 | 520 | 30 | 0.010 |
| `caption2` (micro labels, dock labels when minimised) | 11/13 | 11/13 | 11/14 | 11/14 | 560 | 30 | 0.020 |
| `tabLabel` (dock, sidebar collapsed tooltips) | 11/13 | 11/13 | n/a | n/a | 600 | 40 | 0.010 |
| `sidebarItem` | n/a | 15/20 | 14/20 | 14/20 | 520 | 20 | 0 |
| `mono` (page counters, timers, sizes, keycaps) | 13/18 | 13/18 | 13/18 | 13/18 | 500 (Code) | n/a | 0 |
| `monoLarge` (scrub lens page number, speed dial value) | 22/26 | 22/26 | 22/26 | 22/26 | 600 (Code) | n/a | −0.01 |
| `numeral` (stat values) | 40/44 | 44/48 | 48/52 | 56/60 | 720 | 100 | −0.02 |

Accessibility: Bold Text (iOS, Android 12+) adds +100 to every `wght`. Web `html { font-size: 100% }` and every size is authored in `rem` (17 px = 1.0625 rem), so browser text zoom is the web's Dynamic Type.

#### 2.2.3 Mobile text scale (Dynamic Type and Android font scale)

Flutter's iOS engine turns the Dynamic Type category into one linear factor based on Body (`size / 17`); Android 14+ supplies a non-linear `TextScaler` from the platform. Meniscus applies the scaler to every style and then **caps titles** so a large title never outgrows the screen: `size = min(base × scaler, cap[style])`. Line height scales with the same factor. Layout reflows: cards grow in height, rails lose a column, and the dock drops labels above the `xxxL` category (icons stay, labels move to long-press tooltips and semantics).

The factor column is the iOS factor. Android's font-scale steps (0.85, 0.9, 1.0, 1.15, 1.3, 1.5, 1.8, 2.0) are listed on the nearest row; on Android 14+ the platform's non-linear scaler grows small text faster than large text, so Android values land at or slightly above the row shown, and the same caps apply. `footnote` never renders below 11 px.

| iOS category | Android scale (nearest row) | Factor | `body` | `headline` | `footnote` | `title2` (cap 34) | `largeTitle` (cap 48) | `display` (cap 56) |
|---|---|---|---|---|---|---|---|---|
| xS | 0.85 | 0.82 | 14 | 14 | 11 (floor) | 18 | 28 | 36 |
| S | 0.9 | 0.88 | 15 | 15 | 11.5 | 19.4 | 30 | 38.7 |
| M | 0.95 | 0.94 | 16 | 16 | 12.2 | 20.7 | 32 | 41.4 |
| **L (default)** | **1.0** | **1.00** | **17** | **17** | **13** | **22** | **34** | **44** |
| xL | 1.15 | 1.12 | 19 | 19 | 14.6 | 24.6 | 38 | 49.3 |
| xxL | 1.3 | 1.24 | 21 | 21 | 16.1 | 27.3 | 42 | 54.6 |
| xxxL | 1.5 | 1.35 | 23 | 23 | 17.6 | 29.7 | 46 | 56 |
| AX1 | 1.8 | 1.65 | 28 | 28 | 21.5 | 34 | 48 | 56 |
| AX2 | 2.0 | 1.94 | 33 | 33 | 25.2 | 34 | 48 | 56 |
| AX3 | n/a | 2.35 | 40 | 40 | 30.6 | 34 | 48 | 56 |
| AX4 | n/a | 2.76 | 47 | 47 | 35.9 | 34 | 48 | 56 |
| AX5 | n/a | 3.12 | 53 | 53 | 40.6 | 34 | 48 | 56 |

Rules at large sizes: from AX1 up, list rows switch to a stacked layout (title on its own line, meta below, trailing controls move under the text); from AX2 up, poster grids drop to 2 columns and rails show 1.6 posters; the reader chrome keeps its own fixed sizes and moves secondary controls into the settings sheet so the capsule never wraps.

#### 2.2.4 Novel reader type

| Control | Range | Default phone / desktop | Step |
|---|---|---|---|
| Face | Literata (serif) · Google Sans Flex `ROND 0` (sans) | Literata | n/a |
| Size | 15 to 30 px | 19 / 20 | 1 px, one haptic detent per step |
| Line height | 1.40 to 2.10 | 1.75 | 0.05 |
| Measure | 48 to 88 ch | 68 | 2 ch |
| Paragraph spacing | 0 to 1.2 em | 0.6 em | 0.1 em |
| Character spacing | −0.02 to +0.10 em | 0 | 0.01 em |
| Justify + hyphenate | on / off (`hyphens: auto`, `text-wrap: pretty`) | off | n/a |
| Bold text | on / off (Literata `wght` 400 → 520) | off | n/a |

Literata runs `opsz` = size and `wght` 400; chapter titles in Literata `opsz` 36, `wght` 560 at 1.55 × body size; the drop cap is Literata `wght` 620 at 3.1 em, 3 lines deep, only when the first paragraph has at least 80 characters.

### 2.3 Spacing

A 4 px base grid. Spacing tokens are the only lengths used between elements; component internals (paddings, gaps) cite them.

| Token | px | Typical use |
|---|---|---|
| `s0` | 0 | Flush edges |
| `s1` | 2 | Badge inset, hairline gaps |
| `s2` | 4 | Icon-to-label inside chips, progress ring gap |
| `s3` | 6 | Menu inner padding, grouped-row inner gap |
| `s4` | 8 | Gap between glass siblings in one container, sheet inset |
| `s5` | 12 | Card padding, rail gap on phone, grid gutter on phone |
| `s6` | 16 | Screen margin on phone (≤ 413 px wide), list row horizontal padding |
| `s7` | 20 | Screen margin on phone (≥ 414 px wide), grid gutter on desktop |
| `s8` | 24 | Section gap on phone, screen margin on tablet |
| `s9` | 32 | Section gap on desktop, screen margin on desktop |
| `s10` | 40 | Screen margin on wide, gap above large titles |
| `s11` | 48 | Hero-to-first-rail gap |
| `s12` | 64 | Empty-state vertical padding |
| `s13` | 80 | Bottom content inset above the dock (dock 64 + inset 16) |
| `s14` | 96 | Chapter seam in the manga reader |

Fixed layout lengths:

| Token | px | Meaning |
|---|---|---|
| `touchMin` | 44 (iOS, web), 48 (Android) | Minimum hit target; visuals may be smaller, hit areas never |
| `dockInset` | 21 | Dock distance from the left, right and bottom safe edges |
| `dockHeight` | 64 (minimised 50) | Floating dock |
| `searchOrb` | 50 | Separate search circle at the dock's trailing end |
| `accessoryHeight` | 48 | Bottom accessory capsule |
| `accessoryGap` | 8 | Accessory above the dock |
| `navButton` | 44 | Floating glass nav buttons |
| `sheetInset` | 8 | Partial-detent sheet inset from the screen edges |
| `sidebarWidth` | 280 (collapsed 76) | Desktop inset glass sidebar |
| `sidebarInset` | 12 | Sidebar distance from the window edges |
| `readerStripMax` | `clamp(480px, 50vw, 900px)` | Desktop manga strip width |
| `measureMax` | 88 ch | Novel measure ceiling |
| `contentMax` | 1440 | Desktop content column ceiling beside the sidebar |

Scroll insets: every scroll view runs edge to edge under the floating chrome and uses content insets, never padding on the viewport, so glass always has content to bend. Top inset = safe area + 60 (floating nav row) on phone, 24 on desktop; bottom inset = safe area + `s13` (80), + 56 when the bottom accessory is visible. `scroll-padding-block` on web equals these insets so keyboard focus never lands under a bar (WCAG 2.4.11).

### 2.4 Radius and shape

Controls are **capsules**; containers are **concentric** (`r_inner = r_outer − padding`, floor 4 px); every non-capsule corner is a continuous **squircle** (Flutter `RoundedSuperellipseBorder` / `ClipRSuperellipse`; web `corner-shape: squircle` on Chromium 139+, plain `border-radius` elsewhere).

| Token | px | Use |
|---|---|---|
| `rCapsule` | 9999 | Buttons, chips, segmented controls, search fields, dock, accessory, toasts, badges, scrub rail |
| `rXs` | 6 | OCR highlight boxes, keycaps, tiny thumbnails |
| `rSm` | 10 | Chapter thumbnails, avatar squares, inline code |
| `rMd` | 14 | Posters and covers (media inside a 26/12 card), row highlights inside a 20 px list with 6 px padding |
| `rLg` | 20 | Grouped list containers, image tiles in grids |
| `rXl` | 26 | Cards, menus, popovers, alerts, the hero spotlight card, desktop sidebar |
| `r2xl` | 32 | Desktop panels and desktop "windows" (series detail on desktop) |
| `rSheet` | device corner radius − 8 on phones (for example 55 − 8 = 47 on iPhone 16 Pro), 36 when the device radius is unknown (Android, web) | Partial-detent sheets; the top corners of a full-height sheet stay at this value |
| `rIconTile` | 12 | Icon tiles in settings rows and empty states |

Shape rules:

1. A poster standalone in a rail or grid is `rMd` 14. A poster inside a card with 12 px padding uses the same 14, because the card is `rXl` 26 (26 − 12 = 14).
2. A capsule never gets `corner-shape`; its ends are already semicircles.
3. A sheet's inner scroll clip and its first grouped list follow concentricity: sheet 47 with 16 padding → list 31 → row highlight 31 − 4 = 27.
4. The profile orb is a circle, a person is always round; a series is never round.

### 2.5 Materials and elevation

#### 2.5.1 The layer stack

| z | Layer | What lives there | Treatment |
|---|---|---|---|
| 0 | Canvas | Page background | `#000000` |
| 0.5 | Ambient field | Cover-derived colour blobs | §2.1.8 |
| 1 | Content | Covers, posters, rows, cards, reader pages, prose | Black and `surface1` to `surface3` slabs, `materialThin` to `materialThick` for side panels. **Never Liquid Glass** |
| 2 | Scroll edge | Soft edge under each floating bar group; hard edge under pinned headers | `edgeSoft` / `edgeHard` |
| 3 | Controls | Floating nav buttons, title capsule, dock, search orb, bottom accessory, reader capsules, floating action capsules | `glassThin` (≤ 44 px), `glassRegular` (bars) |
| 4 | Overlays | Menus, popovers, partial sheets, the lifted context preview, the scrub lens | `glassThick`; full-height sheets `solid1` |
| 5 | Interruptions | Alerts, the command palette, confirm sheets | `glassThick` + `dimModal` |
| 6 | HUD | Toasts, the brightness and speed HUDs, the bookmark notice | `glassRegular` capsule |

Physics-first addition: **every material has a mass class**, and a surface's springs come from its class. Small glass (chips, nav buttons, the tab droplet) is light and quick; bars are medium; sheets, panels and pages are heavy. The spring table (§2.9.2) already encodes this: a sheet uses `sheet` (480 ms), a chip `snappy` (400 ms), a droplet `tab` (450 ms, more bounce because it is liquid). Nobody picks a duration by feel; they pick the object's class.

| Mass class | Objects | Press growth | Release spring | Move spring |
|---|---|---|---|---|
| Feather | Tab droplet, scrub thumb, toggle knob, lens | +17 px on the longest side, capped at 0.35 × the side | `press` | `track` then `tab` or `lens` |
| Light | Chips, icon buttons, nav buttons, badges, keycaps | +17 px capped at 0.35 × side | `press` | `snappy` |
| Medium | Buttons, dock, accessory, toasts, cards, posters | +12 px on the longest side (cards and posters: scale 1.04) | `press` | `morph` / `minimize` |
| Heavy | Sheets, menus, panels, alerts, the hero card | none (they lift, they do not swell) | n/a | `sheet`, `sheetSnap`, `morph` |
| Massive | Pages (routes), the reader strip, the whole app during a skin switch | none | n/a | `page`, `zoom`, `settle` |

#### 2.5.2 Glass variants

All glass is **regular** (adaptive, frosted) except over media, where **clear** is allowed. Variants never mix inside one container.

| Token | Fill | Underlay | Blur (CSS radius = Flutter sigma) | Saturate | Rim (0.5 px) | Specular | Shadow | Bezel / thickness (refraction) |
|---|---|---|---|---|---|---|---|---|
| `glassThin` (≤ 44 px controls) | `rgba(255,255,255,0.07)` | `underlay` 0.30 | 8 | 1.8 | `rgba(255,255,255,0.22)` | `rgba(255,255,255,0.42)` top-left | `0 6px 20px rgba(0,0,0,0.45)` | 10 / 20 |
| `glassRegular` (dock, accessory, reader capsules, toasts) | `rgba(255,255,255,0.06)` | `underlay` 0.30 (reader: `underlayAdaptive`) | 10 | 1.8 | `rgba(255,255,255,0.20)` | `rgba(255,255,255,0.40)` | `0 8px 24px rgba(0,0,0,0.50)` | 12 / 24 |
| `glassThick` (menus, partial sheets, alerts, lifted previews) | `rgba(28,28,34,0.52)` | none | 22 | 1.8 | `rgba(255,255,255,0.16)` | `rgba(255,255,255,0.30)` | `0 24px 64px rgba(0,0,0,0.60)` | 18 / 40 |
| `glassClear` (controls over the hero spotlight and image viewer) | `rgba(255,255,255,0.02)` | `dimClear` beneath the media region, not in the glass | 1 | 1.4 | `rgba(255,255,255,0.28)` | `rgba(255,255,255,0.50)` | none | 12 / 24 |
| `glassTinted` (the one primary action per screen) | `iris600` at 86 % | `underlay` 0.30 (reader: adaptive) | 8 | 1.6 | `rgba(255,255,255,0.30)` | `iris100` at 60 % | `0 8px 24px rgba(117,99,242,0.35)` | 10 / 20 |
| `solid1` (full-height sheets; Reduce Transparency everywhere) | `#1C1C22` | none | 0 | 1 | `rgba(255,255,255,0.10)` 1 px | none | as the variant it replaces | none |
| `solid2` (large solid surfaces under Reduce Transparency) | `#26262E` | none | 0 | 1 | `rgba(255,255,255,0.10)` 1 px | none | | none |
| `frosted` (renderer cannot refract) | as the variant it replaces | as it replaces | +6 over the variant | 1.8 | same | same | same | none |

Content-layer materials (never Liquid Glass, used for side panels and slabs over the ambient field):

| Token | Fill | Blur |
|---|---|---|
| `materialThin` | `rgba(19,19,23,0.40)` | 12 |
| `materialRegular` | `rgba(19,19,23,0.62)` | 24 |
| `materialThick` | `rgba(19,19,23,0.84)` | 36 |

Material behaviour (the physics of glass):

1. **Materialise, do not fade.** Glass enters by ramping its refraction (`lensing` 0 → 1) over 250 ms while its opacity goes 0 → 1 over the first 120 ms; it leaves by the reverse over 350 ms. A glass object never pops in at full refraction.
2. **Thickness follows size.** When glass grows (a button blooming into a menu, the accessory expanding into the full player), its bezel and blur interpolate from the small variant to `glassThick` along the same spring as its size, so it visibly thickens.
3. **Press lights from inside.** A radial glow (`rgba(255,255,255,0.16)`, radius 140 px) is centred on the touch point: 150 ms in, 60 ms out. Glass never dims on press.
4. **Stretch toward the drag.** While a pressed glass control is dragged, it stretches up to 6 % along the drag axis (`scale = 1 + 0.06 × clamp(dx / width, −1, 1)`) and compresses the other axis to `1 / √scale` so its area looks conserved, following the `track` spring.
5. **Light has a direction.** The specular rim is brightest at 135° (top-left). On phones it follows the gyroscope (`sensors_plus` 7.1.0, rotation rate integrated and clamped to ±25°) and on desktop the pointer position across the viewport (±25°). Reduce Motion pins it at 135°.
6. **Adaptive thickness over bright pages.** Reader glass reads the page luminance and raises its underlay (§2.1.7): the glass thickens over white pages, exactly where it needs to.
7. **No glass on glass.** Anything drawn on glass uses fills and `onGlass` text. Sibling glass objects share one container so they sample the same backdrop and can merge (the metaball join between the dock and the search orb during a drag, the accessory joining the minimised dock).

### 2.6 Blur

| Token | Radius | Use |
|---|---|---|
| `blurEdge` | 6 | Soft scroll edges |
| `blurThin` | 8 | `glassThin`, `glassTinted` |
| `blurRegular` | 10 | `glassRegular` |
| `blurContext` | 12 | `dimContext` backdrop behind a lifted preview |
| `blurThick` | 22 | `glassThick` |
| `blurRecede` | 8 | The page behind a sheet at the large detent (with scale 0.94) |
| `blurSwitch` | 40 | Skin-switch outgoing melt |
| `blurField` | 120 phone / 180 desktop | Ambient blobs |
| `blurReveal` | 12 → 0 | Heading letter reveal start blur |

Budget: at most **two stacked glass layers** anywhere (for example a menu over the dock). On Flutter every `BackdropFilter` on one screen joins one `BackdropGroup` (`BackdropFilter.grouped`) so they share a single backdrop read. Glass is never placed inside a scrolling list on Flutter at `GlassQuality.premium`; inside scrollables it runs at `standard` (`glass-language.md` §6.2).

### 2.7 Borders, rims and focus

| Token | Value | Use |
|---|---|---|
| `rim` | 0.5 px, gradient from `specular` at 135° to `rgba(255,255,255,0.06)` at 35 % to `rgba(255,255,255,0.02)` at 65 % to `rgba(255,255,255,0.20)` at 100 % | Every glass surface |
| `hairline` | 0.5 px `separator` | Row separators, inset 16 px from the leading edge (60 px when the row has a leading icon tile) |
| `slabBorder` | 1 px `rgba(255,255,255,0.06)` | Cards and grouped lists on black |
| `focusRing` | 2 px solid `iris300` at 2 px offset, plus a 6 px outer glow `rgba(188,176,255,0.28)` | Keyboard focus (`:focus-visible`; Flutter `FocusHighlightMode.traditional`) on every focusable element; follows the element's radius |
| `selectedRing` | 2 px `iris500` inset 0 | Selected poster, selected paper swatch, selected voice |
| `errorRing` | 1.5 px `danger` | Invalid input |
| `hcBorder` | 1 px `rgba(255,255,255,0.55)` | Increase Contrast: added to every glass and slab |

The focus ring contrast is 10.79:1 on black and stays above 3:1 on every slab and glass variant. Rails pad 8 px vertically so rings are never clipped.

### 2.8 Iconography

**Set: Phosphor** on both platforms (`@phosphor-icons/react` 2.1.10 and `phosphor_flutter` 2.1.0, MIT, 1,512 icons in 6 weights at exact parity).

| Context | Weight | Size (visual / hit) |
|---|---|---|
| Default on glass and black | **Regular** (1.5 px stroke at 24 px) | 22 / 44 |
| Active tab, selected state | **Duotone** at rest (secondary layer at 0.2), morphing to **Fill** on press | 22 / 44 |
| Inline in rows and chips | Regular | 20 / row height |
| Ornamental (empty states, onboarding, Wrapped) | **Light** | 48 to 64 |
| Dense meta (download marks, badges) | Bold | 14 to 16 |

Custom glyphs, drawn on Phosphor's 256 grid in Regular, Duotone and Fill, exported as flattened SVG (web components) and one small icon font built with `fantasticon` (Flutter `IconData`):

1. `mm-mark`: the MM column (two Ms joined by the gutter bar).
2. `strip-scroll`: a vertical strip with a down chevron (manhwa reader, cruise auto-scroll).
3. `panel-focus`: a panel inside corner brackets (guided panel view).
4. `bubble-search`: a speech bubble with a magnifier (dialogue search).
5. `age-gate`: a seal with "18" (18+ gate and badge).
6. `voice-31`: a speaking head with a stacked badge (voice picker).
7. `droplet`: a teardrop (pull-to-refresh idle state, splash).
8. `flywheel`: a disc with motion ticks (cruise speed).

Icon motion follows physics too, and every icon animation is interruptible:

| Icon event | Motion |
|---|---|
| Press | Scale with its button; Duotone → Fill morph over the `press` spring (web: cross-fade the two weights over 120 ms; Flutter: `AnimatedSwitcher` with the spring) |
| Bell with new chapters | A pendulum: rotate about the top pivot, initial angular velocity 6 rad/s on the `tick` spring (a swing out, then a small counter-swing from the 4.6 % overshoot) |
| Bookmark saved | The flag drops 4 px and springs back on `tick`, Regular → Fill |
| Download complete | The arrow falls into the tray (translateY 0 → 6 px on `snappy`) and the tray fills with `success` |
| Refresh | Rotation follows pull distance 1:1 (360° per 100 px), then spins at 1 turn per 800 ms while loading |
| Chevrons in disclosure rows | Rotate 0 → 90° on `snappy` when expanded |
| Heart, fire, reactions | Scale 0.6 → 1 on `celebrate` with a 6-particle burst (§5.3) |

### 2.9 Motion

#### 2.9.1 Laws

1. **Nothing moves without a cause.** Every animation starts from a touch, a key, a scroll, data arriving, or a route change. There are no idle loops except the ambient field drift and loading indicators.
2. **The finger owns position.** While touching, an object follows the finger 1:1 with no easing and no lag; the hand is never behind the glass.
3. **Springs own release.** On release, a spring takes over with the finger's exact velocity; timed curves are only for opacity and colour.
4. **Momentum is conserved across hand-offs.** When one motion becomes another (a lifted poster thrown up becomes the detail sheet; a scroll fling at the chapter end becomes the next-chapter card), the second starts with the first's velocity.
5. **Everything is catchable.** Any spring in flight can be grabbed: it stops where it is, its velocity passes to the finger tracker, and the new gesture continues from that exact state.
6. **Projection, not position, decides.** Where a thrown thing lands is decided by where it *would* stop (§2.9.4), so a short fast flick and a long slow drag both work.
7. **Every boundary is elastic.** Past a limit, displacement follows the rubber-band curve (§2.9.5), and the spring returns it.
8. **Thresholds are felt.** Crossing a commit line fires one haptic; crossing back fires a softer one. The user always knows before letting go.
9. **Mass decides speed.** Durations come from the object's mass class (§2.5.1), never from taste.
10. **No bounce on the way out.** Dismissals and exits use bounce 0; overshoot is only for arrivals and celebrations, and never above 0.35.

#### 2.9.2 Springs

Values are `{ms, bounce}` (Apple and Flutter `SpringDescription.withDurationAndBounce`) with the physical constants the web emits. Settle is the time to stay within 0.5 % of the target from rest; overshoot is the peak past the target, both computed for this document.

| Token | ms | bounce | k | c | ζ | Settle | Overshoot | Mass class and use |
|---|---|---|---|---|---|---|---|---|
| `track` | 150 | 0.14 | 1754.6 | 72.05 | 0.86 | 203 ms | 0.5 % | Anything that follows a finger with a hint of lag: the tab droplet during a drag, the scrub lens, the magnifier, the dragged poster's shadow |
| `press` | 220 | 0.20 | 815.7 | 45.70 | 0.80 | 297 ms | 1.5 % | Press growth and release on every control |
| `tick` | 260 | 0.30 | 584.0 | 33.83 | 0.70 | 337 ms | 4.6 % | Small discrete changes: toggle knob, checkbox mark, badge count pop, bell pendulum, bookmark flag |
| `snappy` | 400 | 0.15 | 246.7 | 26.70 | 0.85 | 429 ms | 0.6 % | Chips, segmented thumb, icon morphs, row expand, list entrances |
| `morph` | 380 | 0.25 | 273.4 | 24.80 | 0.75 | 485 ms | 2.8 % | A button blooming into a menu, popover or small sheet, and back |
| `tab` | 450 | 0.22 | 195.0 | 21.78 | 0.78 | 558 ms | 2.0 % | Tab droplet travel after release, content-mode droplet |
| `lens` | 420 | 0.30 | 223.8 | 20.94 | 0.70 | 528 ms | 4.6 % | Liquid lenses: the scrub magnifier appearing, the splash lens, the reaction bloom |
| `sheet` | 480 | 0.08 | 171.3 | 24.09 | 0.92 | 494 ms | 0.1 % | Sheet present and dismiss by button |
| `sheetSnap` | 420 | 0.12 | 223.8 | 26.33 | 0.88 | 399 ms | 0.3 % | Sheet settling on a detent after a drag |
| `page` | 520 | 0 | 146.0 | 24.17 | 1.00 | 621 ms | 0 % | Route push and pop, pager pages, the whole-screen skin melt |
| `zoom` | 560 | 0.06 | 125.9 | 21.09 | 0.94 | 591 ms | 0 % | Poster → detail zoom, chapter card → reader zoom, image viewer |
| `settle` | 350 | 0 | 322.3 | 35.90 | 1.00 | 444 ms | 0 % | Scroll snapping (rails, hero pager, voice orbit, sheet inner lists) |
| `minimize` | 400 | 0 | 246.7 | 31.42 | 1.00 | 497 ms | 0 % | Dock minimise and restore, reader capsule collapse |
| `dismiss` | 320 | 0 | 385.5 | 39.27 | 1.00 | 411 ms | 0 % | Anything leaving: toasts, dismissed rows, closed previews, thrown cards |
| `camera` | 450 | 0.10 | 195.0 | 25.13 | 0.90 | 445 ms | 0.1 % | Panel-by-panel camera, OCR hit jumps, zoom-to-point |
| `celebrate` | 600 | 0.35 | 109.7 | 13.61 | 0.65 | 723 ms | 6.8 % | Added to library, streak +1, reaction sent, goal met |
| `drift` | 900 | 0 | 48.7 | 13.96 | 1.00 | 1065 ms | 0 % | Ambient field blobs, hero parallax return, Wrapped background |

Reduce Motion replaces every spring above with a 150 to 200 ms opacity cross-fade (§2.9.10); the finger still tracks 1:1.

#### 2.9.3 Velocity hand-off

- **Web.** Springs are emitted as physical `{ type: "spring", stiffness: k, damping: c, mass: 1 }` for Motion 13.4.4, **not** as `visualDuration/bounce`. Motion's duration-based springs discard inherited velocity ("time-defined springs should ignore inherited velocity" in `motion-dom`), while physical springs keep it, which is law 4. Gesture velocity comes from Motion's `PanInfo.velocity` (drag) or `useVelocity(motionValue)`; animations start with `animate(value, target, { ...spring, velocity })`.
- **CSS-only elements** (hover lifts, focus glows that need no velocity) use the same springs pre-sampled to `linear()` easing by `build.mjs` at 60 samples over the settle time.
- **Flutter.** `controller.animateWith(SpringSimulation(spring, controller.value, target, velocityInUnits))`, where `velocityInUnits = pxPerSecond / travelPx` for normalised controllers. Drag velocity comes from `DragEndDetails.velocity.pixelsPerSecond` (the framework's `VelocityTracker`, least-squares over the last 100 ms).
- **Retarget.** When a spring's target changes mid-flight (a second tap on another tab, a sheet dragged then released toward another detent), the new spring starts from the current value **and** current velocity. On web this is automatic with physical springs; on Flutter, read `controller.velocity` before calling `animateWith`.
- **Catch.** `pointerdown` on a moving object calls `controller.stop()` (Flutter) or `value.stop()` (Motion) and seeds the gesture's start offset from the current value, so the object does not jump to the finger.

#### 2.9.4 Projection

Where a thrown object comes to rest is decided by projecting its motion with iOS's normal deceleration (`r = 0.998` per ms):

`projected = position + (velocity_px_per_s / 1000) × r / (1 − r)` = `position + 0.499 × velocity`

| Where | What is projected | Decision |
|---|---|---|
| Sheets | Sheet top edge | Nearest detent to the projected edge; below the lowest detent by more than 50 % of its height → dismiss |
| Tab droplet | Droplet centre | Nearest tab to the projected centre |
| Rails | Scroll offset | Rounded to a multiple of `posterWidth + gap` (rail snapping physics, §3.9) |
| Hero pager, voice orbit, Wrapped cards | Page offset | Nearest page, never more than one page per flick on the hero |
| Back swipe | Page x | Projected x past 50 % of the width → pop |
| Row swipe | Row x | Projected past 60 % of row width → commit the full-swipe action |
| Thrown poster (lifted) | Poster centre | Projected above the top 20 % of the screen → open detail; past a side edge → "Not interested" (AI cards only); onto a friend orb → recommend |
| Image viewer | Image y | Projected beyond ±180 px → dismiss |
| Reader scrub rail | Thumb y | Nearest page (the thumb snaps page by page) |

Projection is always capped at one screen length so a violent flick never skips content the user has not seen.

#### 2.9.5 Rubber-banding

`displayed = d × (1 − 1 / (x × c / d + 1))`, where `x` is the raw overshoot in px, `d` the dimension along the axis (viewport height for scroll views and sheets, the control's length for sliders), and `c = 0.55` (Apple's constant). The spring that returns the value is `settle`, starting with the release velocity.

| Boundary | d | Maximum visual stretch |
|---|---|---|
| Every scroll view top and bottom (Flutter `BouncingScrollPhysics` on both iOS and Android; web: native on iOS Safari, `overscroll-behavior-y: contain` plus the pull handler on Android Chrome for the pull-to-refresh views) | viewport height | unbounded, asymptotic |
| Sheets past the top detent | viewport height | 60 px, then the sheet stops |
| Sheets past the lowest detent while not dismissing | sheet height | follows finger until the dismiss projection is met |
| Sliders and dials past min or max | track length | 12 px |
| Zoom below 1× and above 3× (manga), below 1× and above 4× (image viewer) | scale range | ±0.18 scale |
| Dock droplet past the first or last tab | tab width | 18 px |
| Hero pager and Wrapped at the first and last card | page width | 25 % of the width |
| Chapter end and series start in the reader | viewport height | commits at 72 displayed px (§4.14) |

#### 2.9.6 Thresholds and timings

| Interaction | Threshold | Haptic at crossing |
|---|---|---|
| Drag start (touch) | 10 px (Flutter uses `kTouchSlop` 18 when inside a scroll view) | none |
| Drag start (mouse, pen) | 3 px | none |
| Tap | released before 450 ms without moving past the slop (the 150–450 ms growth is only a preview of the lift) | none |
| Press → lift preview | growth begins at 150 ms and reaches 1.06 at 450 ms | `soft` 0.4 at 150 ms |
| Lift → context menu bloom | 450 ms | `medium` |
| Double tap | second tap within 280 ms and 24 px (timestamp detector; single taps are never delayed) | `light` on zoom |
| Back swipe (iOS, full width; reader edge-only 20 px) | projected x > 50 % of width | `rigid` 0.5 when the projection crosses the line, `soft` 0.3 when it crosses back |
| Android predictive back | system progress ≥ 0.35 shows the commit preview | none (the OS owns it) |
| Sheet dismiss | projected top edge below the lowest detent by 50 % of sheet height, or downward velocity ≥ 1500 px/s at the lowest detent | `rigid` 0.6 at the line |
| Sheet detent | snap to the projected nearest detent | `selection` per detent passed during a drag, `soft` 0.5 on settle |
| Row full-swipe | projected > 60 % of width | `rigid` 0.6 across, `soft` 0.3 back |
| Pull to refresh | 100 raw px (60 displayed rest height) | `medium` at the trigger |
| Reader chapter-end pull | arms at 48 displayed px, commits at 72 displayed px | `soft` at arm, `rigid` 0.8 at commit |
| Image dismiss | projected |dy| > 180 px or |vy| ≥ 800 px/s | `soft` 0.5 at the line |
| Throw to open (lifted poster) | projected centre above 20 % of screen height or vy ≤ −1200 px/s | `rigid` 0.7 |
| Throw away (AI card, lifted) | projected centre beyond a side edge or |vx| ≥ 1200 px/s | `rigid` 0.7 |
| Magnet capture (friend orb, detents with magnets) | within 64 px of the target centre | `selection` on capture, `soft` on release into it |
| Hold to confirm (skin restart, destructive actions) | 1200 ms continuous hold | `swell` (a transient every 150 ms rising 0.2 → 0.8), `success` on completion |
| Chrome auto-hide (reader) | 24 px cumulative downward scroll hides; 56 px cumulative upward scroll shows; 3000 ms idle after a tap-open hides | none |

#### 2.9.7 Timed values (opacity and colour only)

| Token | Value | Use |
|---|---|---|
| `fadeIn` | 180 ms `cubic-bezier(0.2, 0, 0, 1)` | Content cross-fades, labels appearing |
| `fadeOut` | 120 ms `cubic-bezier(0.4, 0, 1, 1)` | Labels and glyphs leaving |
| `colorShift` | 240 ms `cubic-bezier(0.2, 0, 0, 1)` | Text colour on hover and state, tab label colour |
| `tintShift` | 900 ms `cubic-bezier(0.2, 0, 0, 1)` | Ambient field and page-tinted chrome |
| `glowIn` / `glowOut` | 150 ms / 60 ms linear | Press glow |
| `materialize` / `dematerialize` | 250 ms / 350 ms `cubic-bezier(0.2, 0, 0, 1)` | Glass lensing ramp |
| `shimmer` | 1400 ms linear loop | Skeleton sheen |
| `caretBlink` | 530 ms step | Typing-reveal caret |
| `reducedCrossfade` | 150 ms (in-page) / 200 ms (routes, sheets) linear | Every Reduce Motion replacement |

#### 2.9.8 Stagger: waves that radiate from the cause

Entrances are not index-ordered cascades; they ripple outward from whatever caused them, at a wave speed.

- **Delay rule.** `delay_i = min(distance_i / 1.6 px·ms⁻¹, 240 ms)`, where `distance_i` is the distance from the cause point to item `i`'s centre. The cause point is the touch point for tap-caused changes (filter chips, content-mode switch), the source element's centre for route arrivals (the tapped poster), and the top-left of the list for data arrivals (first load).
- **Each item** enters with opacity 0 → 1 over `fadeIn` and a spring translate of 12 px toward its rest position from the direction of the cause, plus scale 0.98 → 1, on `snappy`.
- **Cap.** Only items inside the viewport take part; anything that scrolls in later appears with no entrance at all. A wave never lasts more than 240 ms of delay plus one `snappy` settle (429 ms), so the last visible item is at rest within 670 ms.
- **Lists** (single column) use the same rule, which reduces to about 32 ms per 52 px row.
- **Heading letters** are not waves; they use the signature reveal (§6.1).
- **Exits** do not stagger: everything leaving goes together on `dismiss` or `fadeOut`.

#### 2.9.9 Interruptibility contract

Every animated value in the skin is in one of four states, and every component in §3 follows these transitions:

| State | Meaning | Allowed transitions |
|---|---|---|
| `rest` | At a target | → `tracking` on pointer down + slop; → `released` when data or a key changes the target |
| `tracking` | Owned by a finger 1:1 | → `released` on pointer up or cancel, carrying velocity |
| `released` | A spring in flight | → `rest` when settled; → `tracking` on catch; → `released` with a new target (retarget keeps velocity) |
| `committed` | Past a commit threshold; the outcome is decided | → `rest` at the outcome; can still be caught only for sheets, pages and the dock (the outcome is re-decided on the next release) |

Route transitions are springs on a controller, not timed tweens, so:

- A **back swipe during a push animation** grabs the incoming page where it is.
- A **second tab tap during a droplet flight** retargets the droplet with its current velocity.
- **Scrolling during a sheet's present animation** is impossible (the sheet is under the finger's control once touched), and **touching a sheet in flight** catches it.
- A **toast** can be flicked away while it is still arriving.
- A **zoom navigation** (poster → detail) can be caught and dragged back down to cancel, until the zoom has passed 80 % of its travel.

#### 2.9.10 Reduce Motion, Reduce Transparency, Increase Contrast

| Behaviour | Default | Reduce Motion (web `prefers-reduced-motion`; Flutter `MediaQuery.disableAnimationsOf` or iOS `accessibilityFeatures.reduceMotion`) |
|---|---|---|
| Finger tracking (drags, scrubs, back swipe, sheet drag, pinch) | 1:1 | 1:1 (direct manipulation is not decoration) |
| Release after a drag | Spring with velocity | 150 ms cross-fade to the projected outcome |
| Press | Growth + stretch + glow | Glow only |
| Route push/pop, zooms | `page` / `zoom` | 200 ms cross-fade |
| Sheets | `sheet` slide | Fade + 16 px translate, 150 ms, no background scale |
| Menus | `morph` bloom from the trigger | 150 ms fade in place |
| Tab droplet | `tab` travel with stretch | Jumps; droplet cross-fades 150 ms |
| Dock minimise | `minimize` morph | Instant swap |
| Rubber band | Elastic | Hard stop at the limit (content stops, no stretch) |
| Stagger waves | On | Off, everything fades together over 150 ms |
| Letter reveal and typing reveal | On | Full text immediately |
| Ambient drift, specular follow, hero tilt, flame sway | On | Frozen |
| Haptics | On | On (haptics are not motion) |

Reduce Transparency (iOS system setting read through the `mm/haptics` channel method `reduceTransparency`; web `prefers-reduced-transparency`; and the in-app **Solid glass** switch on every platform) swaps every glass variant for `solid1` / `solid2` with the same shape, the same springs and a 1 px 10 % rim, and swaps soft scroll edges for hard ones. Increase Contrast (`MediaQuery.highContrastOf`, web `prefers-contrast: more`) adds `hcBorder` to every surface, replaces `label2` with `label1`, and uses `iris300` instead of `iris400` for accent text.

### 2.10 Haptics vocabulary

Haptics are the other half of the physics: detents, thresholds, impacts and textures. Everything routes through one `GlassHaptics` service per client that honours the in-app **Haptics** switch (default on), rate-limits each family to one event per 40 ms, and never fires on plain navigation taps, on scrolling, on hover, on focus, or on a toast appearing. Every haptic is paired with a visible change (WCAG: never the only signal). Haptics stay on under Reduce Motion.

**Primitives** (the pattern names `design/tokens/glass.json` maps events to):

| Pattern | iOS (via `gaimon` 1.5.0 or UIKit) | Android API 34+ (via the `mm/haptics` channel) | Android API 30–33 | Android web (`navigator.vibrate`) |
|---|---|---|---|---|
| `selection` | `UISelectionFeedbackGenerator` | `SEGMENT_TICK` | `CLOCK_TICK` | none |
| `soft(i)` | Impact `.soft`, intensity i | `VIRTUAL_KEY` | `VIRTUAL_KEY` | none |
| `light` | Impact `.light` | `VIRTUAL_KEY` | `VIRTUAL_KEY` | `10` |
| `medium` | Impact `.medium` | `LONG_PRESS` | `LONG_PRESS` | `18` |
| `heavy` | Impact `.heavy` | `CONTEXT_CLICK` | `CONTEXT_CLICK` | `24` |
| `rigid(i)` | Impact `.rigid`, intensity i | `GESTURE_THRESHOLD_ACTIVATE` | `CONTEXT_CLICK` | `14` |
| `rigidBack` | Impact `.soft` 0.3 | `GESTURE_THRESHOLD_DEACTIVATE` | `VIRTUAL_KEY` | none |
| `toggleOn` / `toggleOff` | Impact `.rigid` 0.5 / `.soft` 0.4 | `TOGGLE_ON` / `TOGGLE_OFF` | `VIRTUAL_KEY` | `10` / none |
| `dragStart` | Impact `.light` | `DRAG_START` | `VIRTUAL_KEY` | none |
| `success` | Notification `.success` | `CONFIRM` | `CONFIRM` | `[12, 60, 12]` |
| `warning` | Notification `.warning` | `KEYBOARD_TAP` | `KEYBOARD_TAP` | none |
| `error` | Notification `.error` | `REJECT` | `REJECT` | `[24, 50, 24, 50, 24]` |
| `ahap:*` | Core Haptics pattern via `Gaimon.patternFromData(json)` | gaimon's waveform conversion of the same JSON | same | none |

**Velocity-scaled impacts.** Throws, flings past a threshold and catches scale their intensity with speed: `i = clamp(0.3 + |v| / 4000, 0.3, 1.0)`. A lazy flick taps; a hard throw thuds.

**Textures.** Continuous drags over stepped values tick once per step, but when steps pass faster than 25 per second the service thins them to every second or third step, so a fast scrub feels like a smooth grain rather than a buzz.

**Events** (the `HapticEvent` enum in `design/contract.json`):

| Event | Pattern | Where |
|---|---|---|
| `tabChange` | `selection` | Dock tab changes, sidebar section changes on touch devices |
| `tabDragCross` | `selection` | Droplet dragged across each tab |
| `tabReselect` | `soft(0.4)` | Tapping the active tab (pop to root or scroll to top) |
| `primaryActivate` | `soft(0.6)` | The tinted action activates (Read, Continue, Download) |
| `chipToggle` | `selection` | Filter and choice chips |
| `segmentChange` | `selection` | Segmented controls, including crossings during a thumb drag |
| `toggleOn` / `toggleOff` | `toggleOn` / `toggleOff` | Switches and checkboxes |
| `sliderStep` | `selection` (textured) | Stepped sliders and steppers, one per step |
| `sliderLimit` | `soft(0.5)` | A slider or stepper hits its end and starts rubber-banding |
| `pressLift` | `soft(0.4)` | Long-press growth begins (150 ms) |
| `contextBloom` | `medium` | Context menu blooms (450 ms) |
| `throwCommit` | `rigid(velocity-scaled)` | A lifted poster thrown to open, away, or into a friend orb |
| `magnetCapture` | `selection` | A dragged object enters a magnet radius |
| `magnetDrop` | `ahap:magnet` | Released into a magnet (recommend-to, drop into a collection) |
| `sheetDetentPass` | `selection` | Each detent passed during a sheet drag |
| `sheetSettle` | `soft(0.5)` | Sheet settles after a drag |
| `dismissLine` | `rigid(0.6)` / `rigidBack` | Sheet, image viewer or back swipe crosses (or re-crosses) its commit line |
| `rowSwipeLine` | `rigid(0.6)` / `rigidBack` | Row full-swipe threshold |
| `pullArmed` | `medium` | Pull-to-refresh trigger |
| `refreshDone` | `selection` | Refresh returned new data (nothing when nothing changed) |
| `chapterArm` | `soft(0.5)` | Reader chapter-end pull arms |
| `chapterCommit` | `rigid(0.8)` | Reader chapter-end pull commits, or the next-chapter card is thrown up |
| `chapterSeam` | `medium` | The continuous strip scrolls across a chapter seam |
| `scrubPage` | `selection` (textured) | Scrub rail passes a page |
| `scrubEdge` | `rigid(0.6)` | Scrub rail hits the first or last page, or a chapter boundary in read-all |
| `zoomToggle` | `light` | Double-tap zoom |
| `zoomLimit` | `soft(0.4)` | Pinch reaches 1× or 3× and starts rubber-banding |
| `pageTurnNovel` | `selection` | A paged novel page turn committed by swipe |
| `panelStep` | `soft(0.3)` | Guided view moves to the next panel |
| `cruiseStart` | `ahap:cruise` | Cruise auto-scroll spins up |
| `cruiseStep` | `selection` | Cruise speed passes a detent (0.25 ×) |
| `cruiseEnd` | `medium` | Cruise reaches the end of available pages |
| `bookmarkSaved` | `success` | Bookmark created |
| `followAdded` | `success` | Added to library / followed |
| `unfollowed` | `light` | Removed from library |
| `downloadQueued` | `selection` | Download button pressed |
| `downloadDone` | `success` | Chapter or batch finished (batch: once) |
| `downloadFailed` | `error` | Chapter failed after retries |
| `reactionBloom` | `medium` | Reaction picker opens |
| `reactionCross` | `selection` | Finger crosses a reaction |
| `reactionSent` | `ahap:pop` | Reaction released |
| `recommendSent` | `success` | Recommend-to delivered |
| `streakUp` | `ahap:ignite` | Streak +1 on the first chapter finished that day |
| `goalMet` | `success` then `ahap:shimmer` 180 ms later | Daily goal reached |
| `wrappedAdvance` | `selection` | Wrapped story card changes |
| `shareLift` | `medium` | A stat card lifts for sharing |
| `ttsPlay` / `ttsPause` | `soft(0.6)` / `soft(0.4)` | Narration play and pause |
| `voiceCentered` | `selection` | Voice orbit settles on a voice |
| `voiceChosen` | `success` | "Use this voice" |
| `speedDetent` | `selection` every 0.25 ×, `rigid(0.4)` at the 1.0 × magnet | Speed dial |
| `sleepSet` | `selection` | Sleep timer option |
| `profileSwitched` | `ahap:droplet` | The chosen profile orb merges into the dock |
| `matureUnlocked` | `ahap:unlock` | 18+ confirmed |
| `holdRamp` | `ahap:swell` | Hold-to-confirm in progress |
| `holdDone` | `success` | Hold-to-confirm completes |
| `skinSwitch` | `heavy` | Restart committed |
| `logoLand` / `logoSettle` | `ahap:droplet` / `ahap:splash` | Splash reveal |
| `errorShake` | `error` | Form or action error with the shake |
| `warn` | `warning` | Offline, storage nearly full, rate limited |

**AHAP signatures** (transients `T` and continuous events `C` only, because gaimon's Android conversion ignores attack and decay; I = intensity, S = sharpness, t in seconds):

| Name | Events | Feel |
|---|---|---|
| `droplet` | T@0.000 I0.55 S0.85; T@0.070 I0.25 S0.95 | A drop landing and its echo |
| `splash` | T@0.000 I0.70 S0.80; C@0.020 dur 0.100 I0.25 S0.95 | A lens settling with a short ring |
| `magnet` | T@0.000 I0.40 S0.90; T@0.050 I0.70 S0.80 | Pulled in, then clicked home |
| `unlock` | C@0.000 dur 0.120 I0.40 S0.85; T@0.120 I0.70 S0.90 | A latch sliding, then releasing |
| `shimmer` | T@0.00 I0.25, T@0.04 I0.30, T@0.08 I0.35, T@0.12 I0.40, T@0.16 I0.45, all S0.90 | Rising sparkle |
| `pop` | T@0.000 I0.50 S1.00 | A bubble bursting |
| `ignite` | C@0.000 dur 0.280 I0.35 S0.50; T@0.280 I0.90 S0.70 | A flame catching |
| `swell` | T every 0.150 s for 8 steps, I 0.20 → 0.80 and S 0.60 → 0.90 linearly (played step by step while the hold continues, so releasing stops it) | Pressure building |
| `cruise` | C@0.000 dur 0.180 I0.25 S0.30; T@0.180 I0.40 S0.60 | A flywheel spinning up |

### 2.11 UI sounds ("Meniscus", off by default)

A small tonal palette of struck-glass and water sounds, **off by default**, switched on in Settings → Sound & haptics. All synthesized, no samples, no licensing.

- **Scale:** A-major pentatonic: A5 880.00 · B5 987.77 · C♯6 1108.73 · E6 1318.51 · F♯6 1479.98 · A6 1760.00 Hz, so any sequence resolves.
- **Timbre:** "struck glass": a sine fundamental plus a partial at 2.76 × (the first overtone ratio of a free bar) at −14 dB, exponential decay; water events use a rising sine chirp (a bubble's resonance rises as it shrinks).
- **Physics:** pitch and level follow velocity. A throw's whoosh centre frequency is `1200 + min(|v|, 3000) × 0.6` Hz; scrub ticks rise up to +3 semitones with scrub speed; a catch is a damped, muted tick. Level peaks: ticks −30 dBFS, taps −26, confirmations −18, the logo −12. 5 ms fades on every file.

| `SoundEvent` | Recipe (sox) | Length |
|---|---|---|
| `tap` | sine 1760 Hz + 2.76 partial, decay 18 ms | 24 ms |
| `tick` | sine 2640 Hz, decay 6 ms | 8 ms |
| `toggleOn` / `toggleOff` | C♯6 → E6 / E6 → C♯6, 50 ms each | 110 ms |
| `sheetUp` / `sheetDown` | sine glide 520 → 1040 Hz / reverse, 110 ms | 120 ms |
| `droplet` | sine chirp 700 → 1400 Hz, 60 ms, fast decay | 80 ms |
| `throw` | band-passed pink noise, Q 1.4, centre frequency by velocity, 90 ms | 100 ms |
| `catch` | sine 440 Hz, decay 12 ms, low-passed 1.5 kHz | 20 ms |
| `add` | A5 + E6 struck-glass dyad | 400 ms |
| `downloadDone` | A5, C♯6, E6 arpeggio, 45 ms steps | 360 ms |
| `error` | E5 659.25 → C♯5 554.37, two soft taps 90 ms each | 200 ms |
| `unlock` | glide 880 → 1318.51 Hz with the 2.76 partial | 180 ms |
| `shimmer` | five A6 grains 40 ms apart, rising level | 260 ms |
| `pop` | chirp 900 → 1800 Hz, 30 ms | 40 ms |
| `chapterCommit` | A4 440 Hz struck glass, 2.76 partial, decay 300 ms | 320 ms |
| `logo` | A5, C♯6, E6, A6 at 24 ms steps + a 1.2 s filtered-noise air pad | 1.4 s |

Production: one `design/sounds/glass/build.sh` of `sox -n -r 48000 -b 16 -c 1 <name>.wav synth …` lines, WAV 48 kHz 16-bit mono, under 300 KB for the whole set. Playback: `flutter_soloud` 5.1.4 on mobile (low latency, loads WAV); the Web Audio API on web (decode once on the first user gesture into `AudioBuffer`s, play through `AudioBufferSourceNode` with `playbackRate` for velocity pitch). iOS: `.ambient` session category, so UI sounds follow the silent switch. Sounds are suppressed while narration or a soundscape (§5.4.2) plays, and never duck the user's music.

---

## 3. Component catalog

Every component below lists its visual spec, its motion (with the §2.9 spring tokens) and every state: default, hover (pointer devices only, `@media (hover: hover)`), pressed, focused, disabled, loading, selected, error. "Glass swells, content sinks" is the universal press rule: glass controls grow and light up when pressed; content (posters, cards, rows) sinks slightly, as if pressed into water.

### 3.1 Buttons

**Variants**

| Variant | Material | Heights (visual / hit) | Padding | Label | Icon |
|---|---|---|---|---|---|
| **Primary** (one per screen) | `glassTinted` | L 50 / 50, M 44 / 44, S 34 / 44 | L 0 24, M 0 20, S 0 14 | `headline` 17/600 `onTint` (S: `subhead` 15/620) | 20 px Regular, 8 px gap, leading |
| **Secondary** | `glassThin` (on black) or `glassRegular` (over media) | same | same | `headline` `onGlass` | same |
| **Plain** | none | 44 hit | 0 8 | `headline` `iris400` on black, `onGlass` on glass | optional |
| **Destructive (secondary)** | `glassThin` | same | same | `headline` `danger` | optional |
| **Destructive (confirm)** | solid `danger` `#FF5C5C` | L 50 | 0 24 | `headline` black (6.94:1) | optional |
| **Hold-to-confirm** | `glassThin` with a liquid fill | L 50 | 0 24 | `headline` `onGlass`, "Hold to restart" | leading glyph |
| **Split** | one glass container: primary segment (tinted) + trailing segment (`glassThin`), 0.5 px `separator` between | L 50 | primary 0 20, trailing 50 × 50 | as primary | trailing chevron-down |
| **Progress** (download) | `glassThin` capsule whose fill becomes a liquid progress | M 44 | 0 16 | `subhead` + `mono` count | cloud-arrow-down → spinner → check |

**Motion and states**

| State | Visual | Motion |
|---|---|---|
| Default | As above; rim, specular at the light angle | none |
| Hover | Inner glow at 8 % centred on the pointer; label `colorShift` to full white; secondary lifts −1 px with shadow `0 10px 28px rgba(0,0,0,0.5)` | `snappy` for the lift; glow follows the pointer with no lag |
| Pressed | Grows by +12 px on its longest side (`press`), inner glow at 16 % centred on the touch point, label `wght` +40, stretch up to 6 % toward a drag; tinted fill shifts to `iris700` at 86 % | `press` in and out; activation happens on release inside the target; dragging more than 1.5 × the hit area away cancels (the glow fades over 60 ms, no activation, no haptic) |
| Focused | `focusRing` (2 px `iris300` + 6 px glow) | Ring appears over 120 ms fade, no movement |
| Disabled | Fill at 40 %, label `label4`, no specular, no glow; tinted becomes `glassThin` at 40 % | No press growth, no haptic; `aria-disabled="true"` and a tooltip with the reason |
| Loading | Width locks; label fades out (`fadeOut`) and three 5 px `onGlass` dots appear, bobbing 3 px on `tick` with 80 ms phase offsets | Not activatable; `aria-busy="true"`; returns to the label with `fadeIn` |
| Selected (toggle buttons: "In library", "Following", "Favourited") | Stays a secondary (the screen keeps its single tinted object): a 22 % `iris600` wash inside the glass, icon Regular → Fill in `iris400`, label `iris300`, rim tinted `iris300` at 40 % | Icon morph on `tick`; the wash spreads from the touch point outward as a 200 ms radial wipe |
| Error | Label swaps to a short error ("Couldn't save") for 2 s in `danger` on the same glass; the button shakes: `x(t) = 8 × e^(−t / 90 ms) × sin(2π × 7 Hz × t)` for 420 ms | `errorShake` haptic; reduced motion: no shake, the error label only |

**Hold-to-confirm.** Pressing starts a liquid fill that rises left to right inside the capsule (`iris600` at 70 %, with a 3 px meniscus curve on its leading edge) over 1200 ms, with `holdRamp` haptics every 150 ms and the label changing to "Keep holding…". Releasing early drains the fill back on `dismiss` from its current position. Completion fires `holdDone`, flashes the capsule to `glassTinted`, and runs the action. It is used for: restarting into another skin, signing out everywhere, deleting a profile, deleting a collection, removing all downloads, resetting offline storage, staging a backup restore and deleting a member. **Alternative (WCAG 2.5.1):** a keyboard activation, a screen-reader double-tap, or a plain click opens an alert with an explicit confirm button, so holding is never the only way.

**Split button.** Used on series detail: "Continue · Ch 143" and a trailing chevron that blooms (`morph`) into a menu: Read from the start, Read all (one scroll), Pick a chapter, Download next 10. The two segments share one glass container: pressing either lights both, the pressed one more.

**Progress button.** "Download" (cloud-arrow-down) → on press, the label cross-fades to "Queued" and a liquid fill enters from the left at the queue's progress; while saving it shows `mono` "12/40" and the fill tracks progress with `snappy`; complete: the fill turns `success` at 24 % and the glyph morphs to a check (`tick`), label "Saved"; failed: `danger` label "Retry" with the shake.

### 3.2 Icon buttons

| Variant | Visual | Hit | Use |
|---|---|---|---|
| **Nav button** | `glassThin` circle 44, icon 22 Regular `onGlass` | 44 | Back, close, profile orb, bell, more (⋯) in floating top rows |
| **Glass group** | One `glassThin` capsule 44 tall holding 2 to 4 icons, 44 px apart, 8 px internal gap | 44 each | Reader top-right group, detail toolbar (share, bookmark, ⋯) |
| **Plain icon** | No background; icon 22 `g800` on black; hover `fill4` circle 40 | 44 | Inline row actions on desktop, sheet headers |
| **Row icon** | `fill3` circle 32, icon 18 | 44 | Pin, remove, download inside rows |
| **Toggle icon** | Any of the above; off = Regular `g800`, on = Fill in its colour (`iris400` for pin and follow, `streakCore` `#FFD166` for favourite, `success` for downloaded) | as above | Pin source, favourite, follow bell |
| **Badged icon** | Any; a count badge at the top-right (see §3.20) | as above | Bell with unread count |

States: default; **hover** inner glow 8 % (glass) or `fill4` circle (plain); **pressed** glass grows +17 px on the longest side capped at 0.35 × (so a 44 px button reaches about 1.35 × at most), glow 16 % from the touch point, Duotone → Fill morph; plain icons sink to 0.92 on `press`; **focused** `focusRing` concentric; **disabled** icon `g500`, no glow; **loading** icon replaced by a 16 px liquid ring spinner (§3.19); **selected** Fill glyph in its colour, with a `tick` pop 1 → 1.12 → 1; **error** the glyph swaps to warning-circle `danger` for 2 s with the shake. In a glass group, a pressed icon's glow spreads into its neighbours at 30 % (one container, one light).

Every icon-only button has an `aria-label` (web) or `Semantics(label:)`/`tooltip:` (Flutter), and a tooltip after the 600 ms "long" hover delay on desktop.

### 3.3 Inputs

Form fields are **content-layer wells**, not glass (they sit on black or on a glass sheet, and nothing goes on glass but fills).

| Field | Visual | Notes |
|---|---|---|
| Text | Height 50, radius 14 squircle, fill `fill3` on black or `fill2` on a sheet, padding 0 16, text `body` 17 `label1`, placeholder `label3`; label above in `footnote` 13/600 `label2` with 6 px gap; helper below in `footnote` `label3` | `autocomplete`, `autocapitalize="none"` for usernames and URLs |
| Password | Text field + trailing eye toggle (plain icon 22, hit 44, `aria-pressed`, labels "Show password" / "Hide password") | Toggle keeps caret position |
| Text area | Min 3 rows (≈ 96 px), grows with content up to 8 rows on `snappy`, then scrolls; counter `caption1` `label3` bottom-right when ≥ 80 % of the limit, `warning` at 95 % | Enter submits where the inventory says so (AI prompt), Shift+Enter newline |
| URL (setup, server) | Text field with leading globe glyph, `inputmode="url"`, trailing status: spinner while validating, check `success` when reachable | |
| Number / go-to | 96 wide, `mono` 13, `inputmode="decimal"`, centred | Enter jumps, Esc clears |
| Stepper | Two 36 px `fill2` circles with − and +, value in `mono` 15 between (min width 64); hit 44 each | Rubber-bands past the limit: the value text stretches 4 px toward the pressed side and springs back, `sliderLimit` haptic |
| Select (native) | Not used; every choice list is a menu (§3.23) or segmented control | |

States: **default**; **hover** well brightens to `fill2`; **focused** `focusRing` + caret `iris400` 2 px + well to `fill2`; **disabled** 40 %, not focusable; **loading** trailing 16 px spinner; **selected** (text selection) `iris600` at 40 %; **error** `errorRing` 1.5 px `danger`, message below in `footnote` `danger` with a warning-circle glyph, `aria-invalid="true"` and `aria-describedby` on the message; on submit the field shakes (the error shake, 6 px amplitude) and the first invalid field takes focus. Validation messages appear with `fadeIn` and push content down on `snappy`.

### 3.4 Search

- **Phone search orb.** A 50 px `glassThin` circle at the dock's trailing end with a magnifying-glass icon. Tap: the orb stretches along `morph` into a bottom search field (full width minus 21 px insets, 50 px tall, `glassRegular` capsule) that rides on top of the keyboard; the dock sinks away on `minimize`. Above the field: the scope segmented control (Library · Sources · Dialogue · Novel text; Dialogue hidden in Novels mode, Novel text hidden when novels are off) and the suggestion list (recent searches as rows closest to the thumb, then trending chips). Cancel: a plain "Cancel" button trailing the field; the field shrinks back into the orb on `morph` and the dock rises. Dragging down on the field dismisses the keyboard first, then collapses to the orb (projection past 80 px).
- **Desktop.** A 36 px `fill3` capsule at the top of the sidebar ("Search  ⌘K"). Click or `mod+k` morphs it into the command palette (§3.28). On the Search screen itself, the field is a 56 px `glassRegular` capsule centred at the top of the content.
- **In-page filter fields** (library, sources, collections, go-to-chapter): content wells (§3.3) at 44 px, leading magnifier, trailing clear (×, 44 hit) when non-empty.

States: idle (placeholder "Search series, sources and dialogue"); focused (ring, keyboard); typing (300 ms debounce, Enter searches at once); searching (the magnifier becomes a 16 px liquid ring spinner); results; no results; error; offline (a `warning` wifi-slash replaces the magnifier and the field shows "Offline: searching this device only" as helper, searching only downloaded titles).

### 3.5 Chips

| Chip | Visual | Behaviour |
|---|---|---|
| **Filter chip** (multi-select) | Height 32 (hit 44 via 6 px vertical padding), `rCapsule`, `fill2`, `subhead` 15/460 `label1`, 12 px horizontal padding; optional leading glyph 16 | Selected: becomes `glassThin` with a leading check that grows in on `tick`, label `wght` 600 |
| **Choice chip** (single-select group) | Same size; the selected one sits under a shared **droplet** (`glassThin` clear capsule) | The droplet slides between chips on `tab`, stretching with velocity like the dock droplet |
| **Count chip** | Filter chip + `mono` count in `label2` after a 6 px gap | "Pinned 4", "With results 12" |
| **Input chip** (removable) | Filter chip + trailing × (16 px, hit 32) | Recent searches; × removes with the chip shrinking on `dismiss` and siblings closing the gap on `snappy` |
| **Assist chip** | Height 32, `glassThin` outline style (fill 0, rim only), leading glyph | Helper actions: "Next 10", "All unread", "Whole book" |
| **Tag** (genre, status) | Height 24, `fill4`, `caption1` uppercase +0.08 em `label2`, 8 px padding | Non-interactive, or a link (hover `fill3`, focus ring) |

Chip rows scroll horizontally with momentum, rubber-band at both ends, mask their trailing 24 px with a gradient to hint at more, and never snap. States: default; hover `fill3`; pressed sinks to 0.96 on `press` (chips are content) while its glass (when selected) swells; focused ring; disabled 40 %; loading (a count chip's count becomes a 12 px spinner); selected as above; error (a chip whose filter failed turns its glyph into warning-circle `danger` and shows a tooltip).

### 3.6 Segmented control

- **Track:** `fill3` capsule, height 36 (compact 32 inside sheets), 2 px inner padding.
- **Thumb:** `surface3` capsule at rest with a 0.5 px rim; label `subhead` 15/620 `label1` on the thumb, `label2` elsewhere.
- **Physics:** tap a segment → the thumb travels on `tab`. Drag the thumb → it turns `glassThin` clear (the transient-glass exception: a content control becomes glass only while manipulated), follows on `track`, stretches `scaleX = 1 + min(|v| / 2000, 0.25)` along the travel, `segmentChange` ticks at each boundary; release → projected nearest segment → `tab`.
- **Segments:** 2 to 5; more than 5 becomes a menu. Equal widths by default; content-fit when labels differ by more than 40 %.
- **States:** default; hover (unselected segment `fill4`); pressed (the pressed segment's label sinks 0.96); focused (ring around the whole control; arrows move the selection; Home/End jump); disabled (40 %, thumb stays); loading (the selected label is replaced by a spinner while the new selection's data loads, the thumb stays at the new position); selected (the thumb); error (the thumb springs back to the previous segment with `tick` and a toast explains).
- **Web:** `role="radiogroup"` with `role="radio"` segments (or `tablist` when it switches panels).

### 3.7 Cards (content layer)

Cards are content: they sit on black or on the ambient field, never glass. Default slab: `surface1` with `slabBorder`, radius `rXl` 26, padding 12; media inside at radius 14.

| Card | Layout | Specifics |
|---|---|---|
| **Series card** (grids) | Poster 2:3 (§3.8) + 8 px + title `footnote` 13/600 2 lines + meta `caption1` `label3` 1 line | No slab; the poster is the card |
| **Continue stack** (Home, Library) | 280 × 132 on phone (desktop 320 × 148): cover 88 × 132 at left; behind the cover, the next page's thumbnail peeks 8 px to the right and 6 px down, rotated 2°, like a deck; right side: title `headline`, "Ch 142 · p. 18 of 40" `footnote` `label2`, progress ring (24 px, 3 px stroke `iris500` on `fill1`) around the chapter number, "Continue" plain button | Slab `surface1`; swiping the stack left reveals "Previously on" (§5.1.3) |
| **World title card** (AI and "for you") | 300 × 132: cover 80 × 120, title `headline` 2 lines, "Manhwa · Ongoing" `caption1`, "120 ch · ★ 8.4" `mono` 13, up to 3 tags, the `why` line in `footnote` italic `label2` | **Available** variant: a small "On MangaSource" source chip (and "+2") and the whole card opens the series. **Info-only** variant: dashed 1 px `slabBorder`, "Not on your sources" `caption1` `label3`, and two plain buttons "Search my sources" and "Read on {site}" (external) |
| **Result card** (search) | 112 wide × 208: poster 112 × 168 + title 2 lines `footnote` | Source glyph badge hidden inside source groups |
| **Stat card** | 2-up grid, slab 26/16: glyph 20 `iris400`, `numeral` value, label `footnote` `label2`, optional 7-point sparkline 24 px tall in `iris500` | |
| **Collection card** | 21:9 slab with a **fanned stack** of up to four member covers (each 72 × 108, rotated −8°, −3°, 3°, 8°, overlapping 40 %) left, name `title3` and "12 series" right | Tap fans the stack open (`celebrate`) during the zoom into the collection |
| **Notification card** | One per series: cover 44 × 66, series title `headline`, "3 new · Ch 141–143" `footnote` `iris400`, time `caption1` `label3`, chapter chips (each opens the reader) | Swipe actions (§3.34) |
| **Source row card** | Row 64 tall: 44 px source logo (radius 10), name `headline`, description `footnote` `label2` 1 line, 18+ tag when mature, pin toggle icon | |
| **History tile** | Poster with a 3 px progress line along its bottom edge, a floating `glassClear` 36 px play orb bottom-right ("p. 18" or "42 %"), title and "Ch 12 · 3 h ago" below | |

States (all cards): **default**; **hover** (desktop) lift −2 px on `snappy`, shadow `0 12px 32px rgba(0,0,0,0.5)`, posters tilt toward the pointer up to 6° with the specular highlight sweeping across the cover; **pressed** sinks to 0.97 on `press` (content sinks); **focused** ring + scale 1.03; **disabled** (unavailable source, pinned-but-hidden) 55 % opacity, not activatable, reason in `caption1`; **loading** skeleton of the same shape (§3.18); **selected** (select mode) 2 px `iris500` inset ring + a 24 px check orb top-right that pops on `tick`, media dims to 80 %; **error** (cover failed) `surface2` fill with a broken-image glyph 24 `g600` centred and the title still shown.

### 3.8 Posters

- **Geometry:** 2:3, radius 14 squircle, 1 px inner highlight `rgba(255,255,255,0.08)` along the top edge, no outer border. Widths: phone 124 (rail) / grid by columns; tablet 148; desktop 168; wide 184.
- **Image arrival:** placeholder is `surface2` with the ambient hue at 12 %; the image arrives with opacity 0 → 1 over `fadeIn` and scale 1.02 → 1 on `snappy` (it settles into the frame).
- **Overlays:** status tag top-left (§3.20), "N new" badge top-right (`iris400` capsule, black `caption1` 700, "99+"), downloaded droplet glyph bottom-left (`success`, 16 px, on a 22 px `rgba(0,0,0,0.55)` circle), 18+ capsule top-left when mature and the gate is open, progress: 3 px bar along the bottom inside the radius (`iris500` on `fill1`).
- **Hover (desktop):** pointer tilt up to 6° (`rotateX/rotateY` on `track`), specular highlight (a white radial gradient at 12 %) following the pointer, lift −2 px; after 600 ms of rest a `glassThin` peek capsule grows out of the poster's bottom edge on `morph` with "Continue Ch 12" or "Open", and a ⋯ button.
- **Press and lift (touch):** at 150 ms the poster starts growing toward 1.06 and its shadow deepens (`0 18px 40px rgba(0,0,0,0.55)`), `pressLift` haptic; at 450 ms the context preview blooms: the background takes `dimContext`, the poster rises to 1.12, and a `glassThick` menu blooms beneath it (§3.23). While lifted, the poster is a **physical object**: drag moves it 1:1; throw up opens detail (the zoom inherits the throw velocity); throw sideways on AI cards is "Not interested"; drag onto a friend orb (they appear along the top when social is on) recommends it; release anywhere else drops it back into place on `zoom`.
- **Keyboard:** focus scale 1.04 + ring; `.` or `shift+F10` opens the menu; Enter opens.
- **States:** as §3.7 cards.

### 3.9 Rails

- **Header:** `title2` (letter reveal on its first appearance per session, §6.1), optional subtitle `footnote` `label2` ("Because you read Solo Leveling"), trailing "See all" plain button; 12 px below, the scroller.
- **Scroller:** leading inset = screen margin, trailing inset = screen margin, gap 12 (phone) / 16 (desktop); posters peek at the trailing edge (3.2 posters visible at 390 px wide).
- **Physics:** free momentum scrolling; on release the ballistic simulation's end is projected and rounded to the nearest multiple of `posterWidth + gap`, and a `settle` spring carries the remaining velocity into that snap. Rubber-band at both ends (`c = 0.55`, `d` = rail width). Web: `overscroll-behavior-x: contain` so a trackpad flick at the start never navigates back; the same snap computed in a `scrollend` handler with Motion's `animate(scrollLeft)`. Flutter: a 20-line `ScrollPhysics` subclass overriding `createBallisticSimulation` returning `ScrollSpringSimulation(spring: settle, …)` with the projected snap target.
- **Desktop:** glass arrow buttons (44 `glassThin` circles) materialise at each end when the pointer is over the rail; each page scrolls by (visible count − 1) posters on `page`. Keys: `←`/`→` move focus within the rail, `↑`/`↓` move between rails keeping the column; each rail is one tab stop (roving `tabindex`).
- **States:** loading (4 to 8 skeleton posters with the header already in place); empty (the rail is omitted, except AI rails, which show their unavailable card); error (a 120 px tall inline card "Couldn't load this row" + "Retry" plain button); AI unavailable (an inline `surface1` card: sparkle-slash glyph, "Recommendations are resting", reason line from the server, and "Try again later"); partial (loaded posters, a trailing skeleton while tier-2 sources answer).

### 3.10 Sheets

- **Detents:** `peek` 96 px (only for the listen mini player expansion), `medium` 52 % of the screen height, `large` = screen height − safe-top − 10 px. Detents a given sheet uses are listed per screen.
- **Geometry:** inset 8 px at partial detents with radius `rSheet` on all corners (the bottom corners nest into the display corners); at `large` the inset lerps 8 → 0 over the last 20 % of travel, the bottom corners go to 0, and the material cross-fades `glassThick` → `solid1` (a tall sheet becomes opaque and attached).
- **Grabber:** 36 × 5 capsule `fill1`, 8 px from the top, 44 × 44 hit; tap cycles detents; with keyboard focus `↑`/`↓` change detent.
- **Header:** 56 tall: title `title2` leading (or centred for pickers), close button (`glassThin` 32 circle with ×, 44 hit) trailing; optional leading action.
- **Behind:** partial detents dim with `dimSheet`; at `large` the page behind recedes to scale 0.94, radius grows to 12, blur 8 and dims to 60 % (visionOS recession), all driven by sheet position (not by time).
- **Physics:** the sheet tracks the finger 1:1; above the top detent it rubber-bands (60 px max); release projects the top edge (§2.9.4) and picks a detent → `sheetSnap` with the release velocity; `sheetDetentPass` ticks as detents are passed during a drag; dismissal per §2.9.6. Scroll hand-off: an inner scroll view at its top hands a downward drag to the sheet; an upward drag at a partial detent expands the sheet before scrolling the content. Present by button: `sheet` (bounce 0.08) from the trigger's position when the trigger is at the bottom (the sheet grows out of the control, a `morph`), otherwise from the bottom edge. Dismiss by button: `dismiss`.
- **Stacking:** at most two sheets; the lower one at `large` scales to 0.9165 and moves up 2 %; a lower partial sheet drops to 70 % brightness. Only the lowest sheet blurs the page.
- **Desktop:** the same content renders as (a) a right-side **panel**, 440 wide, inset 12, radius 26, `glassThick`, entering from the right on `sheet`; or (b) a centred **window**, 560 wide, radius 32, blooming from its trigger on `morph`. Esc and a backdrop click close; each is a history entry (`?sheet=type-settings`) so browser back closes it.
- **States:** loading (skeleton rows inside, header live); error (an inline error block with retry); empty (the sheet's own empty copy); disabled actions greyed.

### 3.11 Dialogs and alerts

- **Visual:** `glassThick`, width 300 (phone) / 420 (desktop), radius 26, padding 20; title `title3` 20/700 left-aligned; body `callout` `label1` (secondary lines `label2` are allowed because alerts sit on `dimModal` over a slab, never over a bright page); a warning or danger box inside for risky content (`surface2` slab with a 3 px leading bar in the semantic colour).
- **Buttons:** stacked full-width capsules (L 50) when there are two with long labels, side-by-side M 44 otherwise; order: least destructive first on top of a stack, trailing when side by side; the destructive confirm uses the solid `danger` variant; initial focus goes to the least destructive action.
- **Motion:** blooms from the control that opened it when there is one (scale 0.9 from that point, `morph`, materialise), otherwise from centre (0.94 → 1, `morph`); `dimModal` fades in over 180 ms. Dismiss: `dismiss` shrink to 0.96 + dematerialise 350 ms.
- **Behaviour:** Esc and Android back cancel; focus trapped; focus returns to the trigger; `role="alertdialog"` with `aria-labelledby` / `aria-describedby`.
- **States:** default; pending (the confirm shows its loading state and the dialog can't be dismissed); error (an inline `danger` line above the buttons, the confirm shakes).

### 3.12 Toasts

- **Visual:** `glassRegular` capsule, height 44 (two-line variant 60 with radius 22), padding 0 16, max width 420; leading 20 px glyph in its semantic colour, text `callout` `onGlass`, optional plain action ("Undo", "View"), no close button (swipe or wait).
- **Position:** phone: top, safe-top + 8, centred; desktop: bottom-left, 24 px from the sidebar's edge and the window bottom.
- **Motion:** falls in from 60 px above on `snappy` (materialising as it lands); leaves upward on `dismiss`. A toast is catchable: flick up or sideways to dismiss (projection past 40 px); drag down to hold it (the timer pauses while touched).
- **Timing:** 4 s default, 5 s with Undo (the capsule's rim drains clockwise as a progress ring so the remaining time is visible); hover pauses; with a screen reader active, toasts stay until dismissed.
- **Stacking:** at most 2; a newer toast pushes the older down 8 px and scales it to 0.94 behind.
- **A11y:** `role="status"` (`aria-live="polite"`), errors `role="alert"`; Flutter `SemanticsService.sendAnnouncement` where supported.

### 3.13 In-page tabs and pagers

- **Tab strip:** a scrollable row of labels (`subhead` 15/600) over a **glass capsule indicator** (`glassThin` clear, 32 tall) that sits behind the selected label; unselected labels `label2`.
- **Pager:** the panels beneath swipe horizontally (Flutter `TabBarView` with `BouncingScrollPhysics`; web a CSS scroll-snap row `scroll-snap-type: x mandatory; scroll-snap-stop: always; overscroll-behavior-x: contain`). The indicator reads the pager's continuous position, so while the finger drags a panel the capsule slides and stretches between the two labels (width lerps between the two label widths, plus velocity stretch up to 25 %); release projects to the nearest panel and settles on `settle`, `segmentChange` haptic on settle.
- **Where:** Source catalogue browse modes, Downloads (Chapters | Storage | Queue), Library sections on phone (Shelf | Collections | History | Bookmarks | Downloads), Updates (All | Unread | Followed), Search scopes on desktop, Statistics ranges.
- **Back gesture rule:** full-width back swipe on iOS loses to the pager until the pager is on its first panel and the drag goes right.
- **Keys:** `[` and `]` previous/next tab; arrows inside the `tablist`; `role="tablist"`, `aria-selected`, roving `tabindex`.
- **States:** default, hover (`fill4` behind the label), pressed (label 0.96), focused (ring on the label), disabled (label `label4`, skipped by arrows), loading (the panel shows its skeleton; the tab keeps working), selected (capsule), error (panel error block).

### 3.14 Top bars

Meniscus has no top bar backgrounds on phone. A top area is a **floating nav row** of glass objects over a soft scroll edge:

- **Nav row:** 44 px tall at safe-top + 8; leading: a back nav button (on pushed screens) or the profile orb (on tab roots); centre: nothing, or a **title capsule** (`glassThin` capsule, 36 tall, `headline` 15/600 `onGlass`, max 60 % of the width, truncating) once the large title scrolls away; trailing: a glass group of up to three icons.
- **Large title:** `largeTitle` 34/40 in the content, 16 px below the nav row. It scrolls with the content; when its baseline passes under the nav row, the title capsule materialises in the centre (lensing 0 → 1 over `materialize`, scale 0.9 → 1 on `snappy`), and its text scales from the large title's position into the capsule (web: a shared `layoutId`; Flutter: a `SliverPersistentHeader` interpolates position and size from the scroll offset). Pulling down past the top stretches the large title (it grows up to 1.08 with the rubber band, anchored at its leading edge).
- **Edge:** `edgeSoft` under the nav row, always; `edgeHard` under pinned headers such as the Library filter row once it pins.
- **Desktop:** the sidebar holds navigation, so the content has a slim **toolbar row** (48 tall, transparent, `edgeSoft` 48 px) with the page title `title2` leading once the large title scrolls away, and trailing actions as a glass group that always ends with a keyboard-shortcuts button (opens the `?` sheet). Back on desktop is a plain chevron button before the title (history back), plus `Esc` for overlays.
- **States:** the nav buttons follow §3.2; the title capsule has only default and focused (it is a heading, focusable only as a skip target).

### 3.15 Dock, search orb and bottom accessory (phone apps and mobile web)

**Dock.** A floating `glassRegular` capsule, 64 tall, inset 21 px from the left, bottom (+ safe area) and right edges, leaving room for the 50 px search orb and an 8 px gap at the trailing end. Four tabs: **Home**, **Library**, **Sources**, **You**. Each tab: icon 22 (Regular; active: Duotone morphing to Fill on press) over a `tabLabel` 11/600; the active glyph and label are `iris400`.

- **Droplet:** the selection indicator is a `glassThin` clear droplet (capsule 56 × 52) under the active tab. Tap another tab → the droplet travels on `tab`, stretching along its path (`scaleX = 1 + min(|v| / 2000, 0.25)`, `scaleY = 1 / √scaleX`), `tabChange` haptic. **Drag across the dock** (press on the droplet or anywhere on the dock and slide): the droplet lifts (turns fully clear, grows 6 %), follows the finger on `track`, ticks `tabDragCross` over each tab, and on release projects to the nearest tab and settles on `tab`. The droplet can be caught mid-flight.
- **Minimise:** after 20 px of cumulative downward scroll, the dock morphs on `minimize` into a 50 px capsule showing only the active tab's icon; the search orb stays; after 12 px of upward scroll, at the top of a list, or on a tap on the minimised capsule, it restores. Minimising is interruptible: reversing scroll mid-morph reverses the morph with its current velocity.
- **Badges:** Home shows an 8 px `iris400` dot when there are unread updates; Library shows a count badge of active downloads (queued + downloading + failed) when non-zero.
- **Tap the active tab:** pop the tab's stack to its root; if already at the root, scroll to top on `page`; `tabReselect` haptic.
- **Long-press a tab** (450 ms): Home → a menu (Updates, Mark all read, Continue last read); Library → jump list (Shelf, Collections, History, Bookmarks, Downloads, and the first five collections); Sources → the pinned sources; You → the **profile switcher** (the profile orbs bloom from the tab, pick one to switch without visiting the picker).
- **Hidden** in both readers, on the profile picker, auth and setup, and while a full-height sheet is open.

**Search orb.** 50 px `glassThin` circle, trailing, same bottom line as the dock. Its behaviour is in §3.4. While the dock is being dragged, the orb and the dock are one glass container: if the droplet is dragged past the last tab toward the orb, the two surfaces merge with a metaball neck (the gap bridges when closer than 12 px) and releasing on the orb opens search.

**Bottom accessory.** A 48 px `glassRegular` capsule, 8 px above the dock, same insets as the dock (it spans the dock plus the orb). One of, in priority order:

1. **Now narrating:** voice avatar 32, "Chapter 12 · Aurora", play/pause 44, a 2 px progress line along its bottom edge; tap expands into the full player (§4.16) by growing along `morph` from the capsule into a sheet; swipe left or right on it changes chapter (projection past 30 % of its width).
2. **Downloading:** a liquid ring 24 with the overall progress, "Saving 3 chapters · 42 %" and a pause/resume button; tap opens Downloads.
3. **Continue:** a 32 px cover, "Continue Solo Leveling · Ch 143", a play glyph; appears on Home only after the hero spotlight has scrolled off-screen.

When the dock minimises, the accessory shrinks on the same `minimize` spring and moves **inline** between the minimised dock capsule and the search orb, showing only its glyph, title and play control. Swiping the accessory down (projection past 40 px) dismisses it for the session (narration pauses first with an Undo toast).

### 3.16 Desktop sidebar

- **Geometry:** an inset `glassRegular` panel, 280 wide, 12 px from the window's top, left and bottom edges, radius 26; content scrolls beneath it (the page's content column starts at 304 px). Collapsed: 76 wide (icons only), auto-collapsing below 1180 px; `mod+b` toggles; the width change runs on `snappy` and uses the frosted tier during the animation (refraction maps are rebuilt only at rest).
- **Order, top to bottom:** the wordmark (single-line fallback "ManhwaManiacs" with the two M's in `iris400`, 20 px) and the collapse chevron; the search capsule ("Search  ⌘K"); the content-mode segmented control (Manga | Novels) when novels are enabled; primary items **Home**, **Library** (expandable: Shelf, Collections, History, Bookmarks, Downloads), **Sources**, **Updates** (count badge), **Activity** (social, when enabled), **Stats**, **Dialogue search** (Manga mode only); pinned sources (up to 5, with favicons); footer: **Settings**, **Status** (admin only), and the profile orb + name capsule. Clicking the capsule blooms an account menu upward on `morph`: a header with the display name, "@username", the email when set and an "Administrator" tag for admins; the other profiles as 32 px orbs (click switches with the hand-off); "Manage profiles"; "Settings"; "Sign out" ("Signing out…" while pending). Esc or an outside click closes it. The window chrome shows no clock; connectivity is the "Offline" status capsule (§3.30).
- **Item:** 40 tall, radius 12 inside the 26 panel with 8 px padding (concentric 26 − 8 − 6 ≈ 12), icon 20 + `sidebarItem` 14/520; hover `fill4`; active: a glass droplet (`glassThin` clear) behind the item plus `iris400` glyph and label; the droplet travels between items on `tab` when the route changes. Exactly one item is active; nested Library items light only themselves.
- **Keyboard:** the sidebar is a `nav` landmark with a roving `tabindex` list; `g h` / `g l` / `g s` / `g u` / `g a` / `g t` jump to Home, Library, Sources, Updates, Activity and Stats.
- **States:** default, hover, pressed (item sinks 0.98), focused (ring inside the panel, concentric), disabled (Dialogue search in Novels mode is hidden, not disabled), loading (badges show a 10 px spinner), selected (droplet), error (a badge becomes a `warning` dot when its count failed to load).

### 3.17 Lists

- **Grouped list:** `surface1` container, radius 20, 16 px from the screen edges; rows 52 tall (64 with a subtitle); hairline separators inset to the text start; section header above in `footnote` 13/600 uppercase +0.04 em `label2` with 8 px bottom gap, section footer below in `footnote` `label3`.
- **Row anatomy:** optional leading icon tile (30 × 30, radius 8, glyph 18 white on a semantic colour or `surface3`), title `body` `label1`, optional subtitle `footnote` `label2`, trailing value `body` `label2`, trailing control (switch, chevron 14 `g600`, badge, or button).
- **Plain list** (feeds): no container; rows separated by hairlines; used for notifications, history on desktop, bookmarks, sessions.
- **Chapter row** (series pages): 56 tall (68 with a secondary title); leading: chapter number in `mono` 15 `label2` in a 44 column (tabular, "·" for null numbers, decimals shown "12.5"); title `body` (or "Chapter 12"); meta `caption1` `label3`: date ("Today", "Yesterday", "3 d ago", or "12 Sep"), "18/40" in `iris400` when in progress, "40 pages", "Read"; trailing download control (§3.29). Read rows drop to `label3` text; the in-progress row gets a 2 px `iris500` bar under its number.
- **Press:** rows sink to `surface3` fill and scale 0.99 on `press` (content sinks).
- **States:** default; hover `fill4`; pressed as above; focused ring inset 2 px, concentric; disabled (row text `label4`, not activatable); loading (skeleton row); selected (select mode: leading 24 px check circle springs in from the left on `snappy`, the row slides right 36 px; selected rows get `iris600` at 14 % fill); error (trailing warning glyph `danger` with an explanation tooltip or subtitle).

### 3.18 Skeletons ("wet glass")

Skeletons have one state (loading) and no interaction; they are `aria-hidden`, and the region they fill carries `aria-busy="true"`. Skeleton shapes match the content they stand for (per screen). Fill `surface2` (`g150`); a sheen band 40 % of the element's width, `linear-gradient(100deg, transparent, rgba(255,255,255,0.05), transparent)`, sweeps left to right every `shimmer` 1400 ms, phase-offset by 60 ms per row so the sheen travels down a list like light over wet glass. Radii match the real element. Skeletons appear only after 180 ms (fast responses never flash a skeleton), and the real content replaces them with the entrance wave from the top-left (§2.9.8). Reduce Motion: static `surface2`, no sheen.

### 3.19 Progress

| Kind | Visual | Motion |
|---|---|---|
| **Linear** | 4 px capsule track `fill1`, fill `iris500` (success variant `success`) with a 1 px `iris300` leading highlight | Width follows value on `snappy` (a large jump overshoots nothing; bounce 0.15 settles in 0.4 s) |
| **Hairline** (reader, novel running head) | 2 px, fill `iris500` at 80 % | Follows on `track` |
| **Ring** | 24 or 32 px, 3 px stroke, track `fill1`, arc `iris500`, round caps | Arc on `snappy` |
| **Liquid fill** (downloads meter, storage, hold-to-confirm, progress button) | Inside a capsule: the filled part is `iris600` at 60 % with a meniscus: the leading edge curves 3 px and wobbles when the value changes | The level follows on `lens` (bounce 0.3), so a jump sloshes once and settles |
| **Liquid ring spinner** (indeterminate) | A 16 or 24 px ring whose 90° arc stretches to 270° and back while rotating once per 900 ms | Loop; under Reduce Motion a static ring pulses opacity 0.4 ↔ 1 over 1.2 s |
| **Three dots** (button loading) | 5 px dots `onGlass`, 6 px apart | Each bobs 3 px on `tick`, 80 ms apart |
| **Segmented** (read-all scrub, storage breakdown) | A capsule divided into segments with 2 px gaps | Segment widths on `snappy` |

`role="progressbar"` with `aria-valuenow` / `aria-valuetext` ("12 of 40 pages saved").

States: default (determinate), loading (indeterminate: the liquid ring spinner, or a 30 % band sweeping a linear track every 1.2 s), complete (fill turns `success` and a check glyph springs in on `tick`), paused (fill `warning` at 60 %, the meniscus still), error (fill `danger`, a retry glyph at the end), disabled (track and fill at 40 %). Progress indicators have no hover, pressed or selected state; a focusable one (the scrubber) takes the slider's states.

### 3.20 Badges and markers

| Badge | Visual |
|---|---|
| **Count** | Min 18 × 18 capsule, `iris400` fill, black `caption1` 700 (8.82:1), "9+" above nine (dock and bell), "99+" on posters; pops on count change: scale 1 → 1.25 → 1 on `tick` |
| **Dot** | 8 px `iris400` circle with a 2 px black ring |
| **New** | "N NEW" capsule `iris400` / black text, top-right on posters |
| **Status tag** | 22 tall capsule, colour at 18 % over black with the colour as text, `caption1` 600 uppercase +0.06 em: READING, COMPLETED, ON HOLD, PLAN TO READ, DROPPED, UNREAD |
| **18+** | 20 tall capsule, `mature` at 22 % with `mature` text "18+", or the `age-gate` glyph 14 on posters |
| **Source** | 20 tall capsule `fill3`, 12 px favicon + source name `caption1` |
| **Downloaded** | `droplet` glyph 14 `success` |
| **Offline copy** | "Saved copy · 2 h" capsule `warning` at 18 % |
| **Admin / You / This device** | 20 tall capsule `fill2`, `caption1` 600 `label1` |
| **Friend** | 18 px friend orb with a `bloom` ring (social) |

Badges are never the only signal: every badge has a text alternative in the element's accessible name ("Solo Leveling, 3 new chapters, downloaded").

States: badges are not interactive, so hover, pressed, focused and selected belong to their host; they have default, loading (a 10 px spinner in place of a count), updated (the `tick` pop when the value changes), disabled (40 % with the host) and error (a `warning` dot replaces a count that failed to load).

### 3.21 Sliders, scrubbers and dials

- **Slider:** track 6 px capsule `fill1`, fill `iris500`; thumb 28 px white circle with `0 2px 8px rgba(0,0,0,0.4)`; while dragged the thumb turns `glassClear` (the transient-glass exception) and grows to 34 px on `press`, and the track thickens to 8 px. Stepped sliders tick `sliderStep` per step (textured) and magnetise: within 30 % of a step's spacing the thumb is pulled toward the step. Past min or max it rubber-bands 12 px (`sliderLimit` haptic). Value label in `mono` 13 trailing, or a glass value bubble above the thumb while dragging.
- **Fill slider (Control Centre style):** a tall 72 × 160 `glassRegular` capsule that fills from the bottom with `onGlass` at 90 %, glyph at the bottom (sun for brightness, speaker for volume); drag anywhere on it; the fill follows on `track`; used in the reader sheet for brightness and warmth.
- **Scrub rail (reader):** see §4.14.3; a 44 px hit strip on the trailing edge with a 3 px visible track, thumb 12 px, and a glass magnifier lens.
- **Speed dial (listen):** see §4.16; a vertical capsule where drag up/down changes speed in 0.05 steps with a magnet at 1.0 ×.
- **Keyboard:** arrows step, Page Up/Down step ×10, Home/End ends; `role="slider"` with `aria-valuetext`.
- **States:** default; hover (thumb grows to 30); pressed/dragging (as above); focused (ring around the thumb); disabled (track `g300`, thumb `g500`); loading (the value label shows a spinner, the thumb stays live); selected (n/a); error (the thumb springs back to the last saved value on `tick`, a toast explains).

### 3.22 Toggles, checkboxes and radios

- **Switch:** 51 × 31 track, off `fill1`, on `iris600`; knob 27 px white with a small shadow. Tap: knob travels on `tick` (4.6 % overshoot gives it a click), the track colour shifts over `colorShift`, `toggleOn`/`toggleOff` haptic. Drag the knob: it turns `glassClear` and stretches to 34 × 27 while held, follows the finger, and projects to on or off on release. States: default; hover (knob glow); pressed (knob stretches toward the travel direction to 34 px on `press`); focused (ring around the track); disabled (40 %); loading (knob shows a 12 px spinner, not toggleable); selected (on); error (the knob springs back to the previous side on `tick` with the shake and a toast).
- **Checkbox:** 24 px squircle, radius 7, off `fill1` border 1.5 px `g600`, on `iris600` fill with a white check that draws its stroke over 160 ms while the box pops 1 → 1.12 → 1 on `tick`. Indeterminate: a white bar. Hit 44.
- **Radio:** 24 px circle, off 1.5 px `g600` ring, on a 10 px white dot inside an `iris600` disc (the dot grows on `tick`). Radios in Meniscus appear only in lists (grouped rows with a trailing check glyph for the selected row, the iOS way), never as bare circles in forms.
- **Selection check (lists and select mode):** 24 px circle, `iris600` fill, white check; springs in from scale 0 on `tick`.

### 3.23 Menus and context menus

- **Menu (pull-down):** blooms out of its trigger along `morph`: the trigger's glass stretches into the menu body (shared glass on web via a common `layoutId`; Flutter `liquid_glass_widgets` morph), `glassThick`, radius 26, padding 6, min width 220, max 320; rows 44 tall, radius 20 (26 − 6), icon 20 trailing (iOS) or leading (Android and web), label `body`; destructive rows `danger`; separators 6 px gaps between groups; the content fades in over the last 40 % of the bloom. Dismissing reverses the path back into the trigger over `dematerialize`.
- **Slide to select:** press on the trigger and, without lifting, slide onto a row: rows highlight under the finger (`fill2`), `selection` haptic per row, release selects. A menu opened with a tap stays open.
- **Context menu (long press / right-click):** the pressed object lifts (§3.8), the background takes `dimContext`, and a `glassThick` menu blooms from the object's nearest edge. The preview (poster 1.12, row 1.02, image 1.0) stays interactive: drag it to throw (posters) or to reorder (rows in reorder-capable lists). Right-click on desktop opens the same menu at the pointer without the lift; `.` or `shift+F10` on a focused item opens it from the item.
- **Keyboard:** arrows move, Enter selects, Esc closes, type-ahead jumps to rows by first letter; `role="menu"`, `role="menuitem"`.
- **States:** row default, hover (`fill2`), pressed (row sinks 0.98), focused (ring inside the row, radius 20), disabled (`label4`, skipped), loading (a row's trailing spinner while its action runs; the menu stays open until done), selected (trailing check `iris400`), error (row label swaps to the error for 2 s, `danger`).

### 3.24 Empty, error and offline states

One component, three tones, all built as a floating **object lens**: a 96 px `glassThin` circle holding a 44 px Light glyph, which bobs slowly on the ambient drift (2 px amplitude, 6 s period, frozen under Reduce Motion) and tilts with the gyroscope, so the empty screen still has glass bending the ambient field. Below it: title `title3` `label1`, description `callout` `label2` (max 36 ch), and up to two buttons (primary tinted + secondary).

| Tone | Lens glyph colour | Field | Typical copy (per screen in §4) |
|---|---|---|---|
| Empty | `iris400` | Profile mood | "Your shelf is empty" |
| Error | `danger` | Mood at half opacity | "Couldn't load your library" + "Try again" |
| Offline | `warning` | Mood at half opacity | "You're offline" / "Chapters you downloaded still open with no connection." + "Try again" + "Open downloads" |

Offline states retry automatically when connectivity returns (web `online` event with a 3 s cooldown; Flutter `connectivity_plus` stream), and the lens does one `celebrate` hop when the retry succeeds. A `warning` "Offline" capsule (§3.30) also appears in the top nav row of every screen while offline.

### 3.25 The 18+ gate

Mature content is governed by absence (`capabilities.md` §1): with the gate closed, mature sources, series, notifications and statistics simply do not exist in any list, count or search, and the skin never draws a placeholder, blur or "hidden" count.

- **Where it is set:** Settings → Content (per profile) and the profile form. Both surfaces use the same flow, so the safeguard is identical.
- **Turning it on:** the switch does not flip on tap. Tapping it opens an alert blooming from the switch: `age-gate` glyph 32 `mature`, title "Show mature content?", body "Adult (18+) sources, search results and recommendations will appear for this profile. Only continue if you are of legal age where you live. You can turn this off at any time.", and a **hold-to-confirm** button "Hold: I am 18 or older" (1200 ms, `holdRamp`) plus "Cancel". Keyboard and screen-reader users get the explicit "I am 18 or older, enable" button in the same alert. On completion: `matureUnlocked` haptic, the switch knob travels on `celebrate`, the alert dematerialises, and every mature-gated query refetches (the lists gain their new rows with the entrance wave).
- **Turning it off:** immediate, no confirmation, `toggleOff`; mature rows leave with `dismiss` and siblings close up on `snappy`.
- **Marking:** where mature content is shown, it carries the 18+ badge (§3.20). Social surfaces never show another profile's mature activity to a profile whose gate is closed (§5.3).
- **States:** off, confirming (alert open, hold in progress), on, pending (switch shows a spinner while the PUT runs), error (the switch springs back with a toast "Couldn't change this setting"), blocked (no active profile: the row is disabled with "Choose a profile first" and a link).

### 3.26 Avatars and profile orbs

- **Profile orb:** a circle with the avatar preset's two-colour gradient and a white Light glyph; sizes 24 (chips), 32 (sidebar, activity rows), 44 (nav row), 96 (picker), 132 (picker focus); a 2 px ring in the profile's mood colour at 60 %; on glass surfaces the orb gets a glass bezel (0.5 px rim + specular).
- **Avatar presets** (12, gradient top-left → bottom-right, Phosphor glyph): Violet Spark `#8B5CF6 → #D946EF` sparkle; Cyan Rocket `#06B6D4 → #0EA5E9` rocket-launch; Rose Heart `#F43F5E → #EC4899` heart; Amber Coffee `#F59E0B → #F97316` coffee; Emerald Cat `#10B981 → #14B8A6` cat; Ember Flame `#EF4444 → #F59E0B` flame; Steel Blade `#94A3B8 → #475569` sword; Phantom `#6366F1 → #334155` ghost; Arcane Wand `#A855F7 → #6366F1` magic-wand; Lunar Moon `#0284C7 → #4338CA` moon; Starlight `#FACC15 → #F59E0B` star; Bookworm `#14B8A6 → #0891B2` book-open.
- **Idle physics:** on the picker only, orbs float with a slow drift (±3 px, 5 to 7 s periods, random phase), frozen under Reduce Motion.
- **Friend orb** (social): the same orb with a `bloom` ring; 18 px in activity rows, 56 px as drop targets.
- **States:** default, hover (scale 1.04 + specular sweep), pressed (grows +12 px), focused (ring outside the mood ring), disabled (40 %), loading (the glyph becomes a spinner), selected (mood ring becomes 3 px `iris300`), error (orb shows a warning glyph overlay).

### 3.27 Tooltips and keycaps

- **Tooltip:** `glassThick` capsule, `footnote` `onGlass`, padding 6 12, 8 px from the target; delays per visionOS levels: 0 ms (icon-only buttons on focus), 150 ms (dock and sidebar collapsed), 600 ms (everything else on hover); appears on `snappy` from 0.9 scale with materialise; follows its target if it moves.
- **Keycap:** `mono` 12/600 `label1` on `surface3`, radius 6, min width 20, height 20, 0.5 px rim; combos separated by 4 px; on macOS web show ⌘ ⌥ ⇧ ⌃ glyphs. Shortcut hints appear in tooltips and in menus trailing each row.

### 3.28 Command palette (desktop web; phones get Search instead)

- **Open:** `mod+k` from anywhere, or clicking the sidebar search capsule. The capsule morphs into the palette: a `glassThick` panel 640 wide, radius 26, at 12 vh from the top, over `dimModal`, blooming on `morph`.
- **Field:** 56 tall, leading magnifier, placeholder "Search series, sources, screens and actions", trailing Esc keycap.
- **Results:** grouped (Library, Sources, Go to, Actions, Skin), each group label `caption1` uppercase `label3`; rows 48 tall: leading visual 32 (cover, favicon, or glyph), title with matched characters in `iris400`, subtitle `footnote` `label2`, trailing Enter glyph on the active row; max 40 results. The active-row highlight is a glass droplet that travels between rows on `tab` as arrows move (a gentle travel instead of a jump), stretching with speed when a key is held.
- **Actions** include: Open settings, Switch profile, Toggle content mode, Continue reading (the most recent), Check for new chapters, Download next 10 of the current series (on series pages), Toggle solid glass, Sign out, and **Skin: Cinematic (restarts the app)** which opens the restart confirm sheet.
- **Keys:** `↑`/`↓` (wrap), Home/End, Enter, Esc, `mod+k` closes; focus returns to where it was.
- **States:** idle (recent items and suggested actions), typing, searching ("Searching…" live region), results, empty ("Nothing matches “{q}”."), error (a row "Library search failed · Retry" while other groups still show), offline (Library and Sources groups show only downloaded titles).

### 3.29 Download control (per chapter)

A 44 px hit area, 28 px visual, trailing each chapter row. Eight states, each with glyph, colour and label (accessible name):

| State | Visual | Accessible name |
|---|---|---|
| Not downloaded | cloud-arrow-down Regular `g800` | "Download chapter 12" |
| Queued | a dashed 22 px ring `g600` slowly rotating (one turn per 4 s) | "Queued to download" |
| Downloading | liquid ring 22 px with the page progress, `iris500` | "Downloading, page 18 of 40" |
| Saved | `droplet` glyph Fill `success` | "Downloaded, opens with no connection" |
| Incomplete | droplet with a warning notch `warning` | "Incomplete, some pages are missing" |
| Paused | pause-circle `warning` | "Paused, device is full" (or the pause reason) |
| Stale | arrows-clockwise `warning` | "The source changed these pages, download again" |
| Failed | warning-circle `danger` | "Download failed, retry" |

Tap cycles the natural action (download, cancel, retry, save again); on a saved chapter tap opens a small menu (Remove download, Extract text for dialogue search on phones, Save to Files on phones). Long-press on the row opens its context menu (Mark read, Mark unread, Download, Select), and "Select" enters multi-select with that row already picked, driving the bulk toolbar (§3.35). The ring's progress follows on `snappy`; completion morphs the ring into the droplet on `tick` with `downloadDone` (once per batch).

### 3.30 Banners and inline notices

- **Inline notice:** `surface1` slab radius 20, padding 12 16, leading 20 glyph in the semantic colour, text `callout`, optional plain action trailing; a 3 px leading bar in the semantic colour. Used for: overdue update checks, restore staged, "Downloads only run while the app is open" (phones), stale catalogue, AI budget used, mode-scope notes on Statistics.
- **Status capsule** (top nav row): `glassThin` 32 tall, glyph + `footnote` 600: "Offline" (`warning` wifi-slash), "Saved copy · 2 h" (`warning`), "Syncing" (spinner). Appears with materialise, leaves with dematerialise.
- **Global new-chapters capsule:** when new chapters arrive while the app is open (60 s poll), a `glassRegular` capsule drops in at the top (like a toast but persistent until acted on): cover stack of up to 3 covers, "5 new chapters in 3 series", "View" plain button; swipe up dismisses until a newer notification arrives. Hidden inside readers and on Updates.
- **App update capsule** (web service-worker update, Android APK): "A new version is ready" + "Reload" (web) or "Update" (Android, opens the update sheet). Bottom-centre above the dock (phone), bottom-left (desktop).

### 3.31 Image viewer

- **Open:** from a cover on series detail, a page thumbnail, an OCR result, or a shared stat card preview; the image zooms from its thumbnail on `zoom`; background `#000000` with the ambient field at 40 %.
- **Gestures:** pinch 1× to 4× with focal-point preservation and rubber-band beyond (§2.9.5); double-tap toggles 1× ↔ 2.5× at the tap point on `camera`; pan when zoomed with momentum and edge rubber-band; at 1× a vertical drag dismisses: the image scales `1 − min(|dy| / 1200, 0.15)`, its radius grows 0 → 28, the backdrop opacity follows `1 − min(|dy| / 320, 1)`, and release past the projection threshold (§2.9.6) flies it back into its thumbnail on `zoom` carrying the release velocity; otherwise it springs back on `settle`.
- **Chrome:** `glassClear` close button top-left (44); share (the system share sheet on phones and Web Share where supported) and, on desktop web, save, top-right; the chrome fades after 2 s idle.
- **Keys:** Esc closes, `+`/`-`/`0` zoom, arrows pan.
- **States:** loading (the thumbnail stays, upscaled with blur 8 until the full image arrives, then sharpens over `fadeIn`), error ("Couldn't load this image" + Retry on the glass), zoomed.

### 3.32 Scroll edges and scrollbars

- **Soft edge** (`edgeSoft`) under every floating top row and above every floating bottom group, one per edge; its opacity follows how much content is under it (0 at rest at the top of a list, 1 once content scrolls under), so the edge "appears" as content arrives beneath it.
- **Hard edge** (`edgeHard`) under pinned section headers.
- **Scrollbars:** web: a 6 px capsule thumb `rgba(255,255,255,0.28)` on a transparent track, widening to 10 px on hover (`scrollbar-width: thin` fallback in Firefox); shown only while scrolling and on hover of the scroll area. Flutter: `CupertinoScrollbar` styling on both platforms (thickness 3, pressed 8, radius 1.5 / 4), draggable when it is pressed for 200 ms. Long lists (chapter lists over 200 rows, the source catalogue) get a **fast-scroll thumb**: dragging the scrollbar shows a `glassThin` capsule bubble with the chapter number or the first letter at the thumb, `selection` tick per 10 chapters.

### 3.33 Pull to refresh

- **Where:** Home, Library, Sources, Source catalogue, Updates, History, Bookmarks, Collections, You (activity). Not Downloads (local data).
- **The droplet:** as the list is pulled down, a `glassThin` droplet hangs from the top edge on a meniscus neck: the droplet's radius grows from 0 to 16 px over the first 60 raw px, the neck stretches thinner as the pull continues (the neck width is `12 × (1 − progress)` px), and the `droplet` glyph inside rotates with the pull. At 100 raw px the neck **snaps**: the droplet pops free (`pullArmed` haptic, `droplet` sound when enabled), springs to the 60 px rest line on `lens`, and becomes a liquid ring spinner while loading. Released before the trigger: the droplet retracts into the edge on `settle`.
- **Done:** the spinner fills into a check (new data: `refreshDone` haptic, the list's new rows enter with the wave) or fades (no change), and the list returns to 0 on `settle`.
- **Physics:** Flutter `CupertinoSliverRefreshControl` (trigger 100, indicator extent 60) with a custom `builder` drawing the droplet; `BouncingScrollPhysics` on both platforms. Web: about 60 lines of pointer handling on the list container, touch only, only at `scrollTop === 0`, rubber-band displacement with `c = 0.55`, `overscroll-behavior-y: contain` so the browser's own pull-to-refresh never fires.
- **Alternatives:** a refresh item in the screen's ⋯ menu; `r` on desktop; `aria-live` announcement "Updated" or the error.

### 3.34 Swipe row actions

- **Where:** notifications (mark read), chapter rows (mark read/unread, download), downloads (remove), history (mark finished, open series), sessions (revoke), bookmarks (remove), recommendation cards (Not interested), queue rows (retry, remove).
- **Reveal:** rows drag horizontally 1:1 (after 10 px, direction-locked); actions behind the row are **separate glass pills** (44 tall, 88 wide slots) that inflate from scale 0.6 to 1.0 as they are revealed, their glyph and label in the action's semantic colour; releasing past half the reveal width opens the tray on `snappy`, otherwise it closes on `settle`.
- **Full swipe:** past 60 % of the row width (projected), the leading pill stretches to fill the gap and turns solid in its colour, `rowSwipeLine` haptic; crossing back re-shrinks it with `rigidBack`. Commit slides the row out on `dismiss` with the release velocity and collapses the gap on `snappy`; destructive actions show a 5 s Undo toast instead of a confirm.
- **Alternatives:** the row's ⋯ menu holds every swipe action; desktop shows the actions as hover icons and on keys (`m` mark read, `d` download, `x`/`Delete` remove with undo, `u` undo); VoiceOver/TalkBack custom actions (`Semantics(customSemanticsActions:)`, web menu button).
- **Web:** enabled only on `pointer: coarse`; `touch-action: pan-y` on the row; Motion `drag="x"` with `dragDirectionLock`, `dragElastic: 0.1`.

### 3.35 Drag to reorder and bulk selection

- **Reorder** (source pins, collections list, collection members, library manual order, download queue priority, profiles): press 450 ms on a row (or drag its handle immediately): the row lifts (scale 1.03, rim brightens, shadow `0 12px 28px rgba(0,0,0,0.55)`), `dragStart` haptic; neighbours part around the gap on `snappy`, `selection` tick each time the item passes a slot; drop settles on `snappy` with `soft(0.5)`. Edges auto-scroll at up to 1200 px/s proportionally to the distance into the 64 px edge zone. Keyboard: `alt+↑/↓` (grids also `alt+←/→`) moves one slot, `alt+shift+↑/↓` to top/bottom, announced in `aria-live="assertive"` ("Solo Leveling moved to position 3 of 12"). Menu items "Move up / Move down / Move to top / Move to bottom" exist on every platform (WCAG 2.5.7).
- **Bulk selection:** "Select" in the nav row or ⋯ menu, "Select" in any item's context menu (that item starts selected), or `x` on desktop enters select mode; each tap toggles; on touch, dragging across items after the first selection paints a range (the list auto-scrolls at its edges); desktop Shift-click selects ranges. A **floating glass toolbar** replaces the bottom accessory slot: `glassRegular` capsule 52 tall with "{n} selected" (`mono` count), and actions as glass icon buttons with labels on desktop: Favourite, Unfavourite, Mark read, Mark unread, Add to collection, Download, Remove (destructive, with Undo). While a batch runs, the toolbar shows a liquid progress fill with "{done} of {total}" and a Stop button; the result appears as a toast ("12 marked read · 1 failed" + "Retry failed"). Esc or "Done" exits.

### 3.36 Content-mode switch (Manga | Novels)

Exists only when the server enables novels. A two-segment control (§3.6) with glyphs `strip-scroll` and `book-open`: in the sidebar (desktop), in the nav row of every screen whose lists follow the mode (Home, Library and its sections, Sources, Search, Updates, Statistics, collection detail, You) as a compact 32 px capsule ("Manga" with a chevron) that expands on press into the two segments (a `morph`) with the line "One setting for the whole app", and in the long-press menu of the Library tab. Switching refilters every list (the lists run the entrance wave from the switch's position), `segmentChange` haptic, and the choice persists per profile.

---

## 4. Per-screen specs

Every screen lists: layout per platform (desktop web, mobile web, iOS, Android; "phone" when the three phone targets match), hierarchy, the signature moment, transitions in and out, gestures, all states, keyboard shortcuts on web (the same map is registered with Flutter `Shortcuts`/`Actions` for hardware keyboards on iPad and Android tablets), and inventory coverage.

### 4.0 Shell, navigation and routes

#### 4.0.1 Frames

| Frame | Where | Composition |
|---|---|---|
| **Bare** | Setup, splash, login, register, root error, offline fallback | Ambient aurora field, no navigation, content column max 420 (phone full width minus 32) |
| **Takeover** | Profile picker, onboarding, Wrapped | Full-bleed field in the focused mood or art, no dock, no sidebar; a close or back nav button only where it makes sense |
| **Phone app** | Every other screen below 768 px | Floating nav row (top), large title in content, dock + search orb + bottom accessory (bottom), soft edges at both ends; content runs edge to edge beneath |
| **Tablet app** | 768 to 1023 px (web and large Flutter windows) | Collapsed 76 px glass sidebar on the left instead of the dock, floating nav row on the right, accessory as a floating capsule bottom-centre of the content column |
| **Desktop app** | 1024 px and wider | 280 px inset glass sidebar, content column up to 1440 px, toolbar row, toasts bottom-left |
| **Manga reader** | Reader routes | Black canvas, floating reader capsules (§4.14), no dock or sidebar; desktop: the strip in the centre with material side panels |
| **Novel reader** | Novel routes | The paper edge to edge; floating capsules tinted to the paper; desktop: the page column centred with optional side panels |
| **Landscape phone reader** | Readers on a rotated phone | Chrome shrinks to two corner capsules (back + title top-left, settings + page top-right), the bottom capsule becomes a slim scrub rail |

#### 4.0.2 Information architecture

| Destination | Phone | Tablet and desktop |
|---|---|---|
| Home (AI home, continue, rails) | Dock tab 1 | Sidebar "Home" |
| Library (shelf, browse all, collections, history, bookmarks, downloads) | Dock tab 2; sections as in-page tabs | Sidebar "Library" with its five children |
| Sources (list, catalogues) | Dock tab 3 | Sidebar "Sources" + pinned sources |
| You (profile, stats, activity, settings, about, admin) | Dock tab 4 | Sidebar footer (profile capsule, Settings, Status) + "Activity" and "Stats" items |
| Search | Search orb | Sidebar search capsule → command palette; `/search` for the full screen |
| Updates | Bell nav button on Home (with count badge); Home tab dot; Home long-press menu | Sidebar "Updates" with count |
| Downloads | Library tab section; bottom accessory while downloading; Library tab badge | Sidebar Library → Downloads |
| Recommendations ("For you" and Ask) | Home rails + "Ask" in Search idle state + Home ⋯ menu | Home + command palette action |
| Statistics and Wrapped | You tab card; streak chip on Home greeting | Sidebar "Stats" |
| Activity (social) | You tab card + Home "Friends are reading" rail | Sidebar "Activity" |
| Dialogue search (OCR) | Search scope "Dialogue"; You → Library group | Sidebar item (Manga mode) and Search scope |
| Settings | You tab | Sidebar footer |
| System status (admin) | You → Administration | Sidebar footer "Status" |

#### 4.0.3 Routes

The Glass router registers every path in the shared `design/contract.json`, so a URL or deep link opens the same screen in either skin. Screen IDs are the contract's `ScreenId` values.

| ScreenId | Path(s) | Presented as (phone / desktop) |
|---|---|---|
| `setup` | `/setup` (Flutter only) | Bare page |
| `splash` | `/splash` (Flutter only; web renders the reveal inline) | Bare |
| `login` | `/login` | Bare |
| `register` | `/register` | Bare |
| `profilePicker` | `/profiles` | Takeover |
| `profileForm` | `/profiles/create`, `/profiles/edit/:id` | Large sheet over the picker / window |
| `profileManage` | `/profiles/manage` | Pushed page / page |
| `onboarding` | `/onboarding` | Takeover |
| `home` | `/home` (`/` redirects here) | Tab root |
| `library` | `/library` (shelf), `/library/browse` (browse all) | Tab root / page |
| `seriesDetail` | `/library/:followedId`, `/sources/:sourceId/series/:seriesId` | Sheet (medium → large) / window over the page; novel sources render `bookPage` |
| `bookPage` | `/sources/:sourceId/series/:seriesId` (novel sources) | Sheet / window |
| `collections` | `/library/collections` (Flutter alias `/collections`) | Library section / page |
| `collectionDetail` | `/library/collections/:id` (alias `/collections/:id`) | Pushed page |
| `history` | `/library/history` | Library section / page |
| `bookmarks` | `/library/bookmarks` | Library section / page |
| `downloads` | `/downloads` | Library section / page |
| `forYou` | `/library/recommendations` | Pushed page / page |
| `statistics` | `/library/statistics` | Pushed page / page |
| `wrapped` | `/wrapped/:year` | Takeover |
| `activity` | `/activity` | Pushed page / page |
| `friend` | `/activity/:profileId` | Sheet / window |
| `search` | `/search` (`?q=&scope=`) | Search orb expansion / page |
| `sources` | `/sources` | Tab root / page |
| `sourceCatalogue` | `/sources/:sourceId` (`?genre=&mode=`) | Pushed page / page |
| `mangaReader` | `/reader/:sourceId/:seriesKey/*chapterKey` (`?page=&at=`), Flutter aliases `/library/read/:s/:k/:c` and `/sources/:s/series/:id/chapters/:c/read` | Immersive |
| `readAll` | `/read-all/:sourceId/:seriesKey` (`?from=&page=&at=`), Flutter `?all=1` | Immersive |
| `readerLanding` | `/reader` | Bare page |
| `novelReader` | `/novels/:sourceId/:seriesKey/*chapterKey` (`?page=&para=&at=`), Flutter `/novels/read/...` | Immersive |
| `updates` | `/updates` | Pushed page / page |
| `ocrSearch` | `/ocr` (Flutter alias `/ocr/search`) | Pushed page / page |
| `you` | `/you` (`/more` redirects here) | Tab root / not a page on desktop (redirects to `/settings`) |
| `settings` | `/settings`, `/settings/:section` | Pushed page / page with a section list |
| `adminStatus` | `/admin/status` | Pushed page / page |
| `notFound`, `routeError`, `rootError`, `offlineFallback` | any unknown path; thrown routes; root failure; `/offline-fallback.html` | Bare |

Sheets that should close on back are URL state (`?sheet=chapters`, `?sheet=type`, `?sheet=voices`, `?sheet=recap`), so Android back, browser back and the iOS swipe close them.

#### 4.0.4 Transitions shared by every screen

| Navigation | Motion |
|---|---|
| Push (row, button, link) | Incoming page slides in from the trailing edge on `page` (100 % → 0); the outgoing page moves −30 % and dims under `rgba(0,0,0,0.3)`; the incoming large title runs the letter reveal once per session per screen; the nav row's title capsule cross-fades. Web: React `<ViewTransition>` with `transitionTypes={['nav-forward']}`, CSS keyframes eased by the `page` spring's `linear()` export |
| Pop | The reverse; driven by the back gesture when there is one |
| Poster → series detail | **Zoom**: the poster flies (shared element: web `ViewTransition name="cover-{id}"`, Flutter `heroine` 0.7.2) into the detail sheet's cover slot on `zoom`, carrying any throw velocity; the sheet body rises beneath it on `sheet`; the page behind recedes by sheet position |
| Chapter row → reader | **Dive**: the row's rectangle expands to full screen on `zoom` (clip reveal from the row's rect), the page behind scales to 0.94 and darkens to black; the reader's first page fades in over the last 40 % |
| Reader → back | Edge swipe drags the reader right (1:1), showing the detail sheet recessed beneath; release projects; `dismiss` or `settle` back |
| Tab switch | No slide: the destination appears with a 120 ms cross-fade and its content wave radiates from the tapped tab's position; each tab keeps its own stack and scroll offset |
| Sheet routes | §3.10 |
| Skin restart | §4.25.2 |

Reduce Motion: every row becomes a 200 ms cross-fade. Browser back and forward animate nothing (`default: "none"`), so the UA's own swipe animation never plays twice; any `popstate` handler checks `PopStateEvent.hasUAVisualTransition`.

#### 4.0.5 Back per platform

| Platform | Mechanism |
|---|---|
| iOS | `swipeable_page_route` 0.4.8 `SwipeablePage(canOnlySwipeFromEdge: false)` for **full-width** back swipes (iOS 26 parity) on every pushed page; the readers use an edge-only 20 px strip, disabled above 1× zoom and in paged mode. A horizontal pager or rail under the finger wins until it is at its leading edge. Haptic `dismissLine` when the projection crosses 50 % |
| Android | `MaterialPage` with `PredictiveBackPageTransitionsBuilder` (the page shrinks to 90 % and floats as a glass card, x shift `(screenWidth/20 − 8)`); `android:enableOnBackInvokedCallback="true"`; sheets shrink by back progress (a custom `PredictiveBackRoute` on the sheet route scales it 1 → 0.94 and lifts it 12 px). Tab roots: back goes to Home first, then leaves the app |
| Mobile web | History entries for every route and closable sheet; no custom edge swipe; `overscroll-behavior-y: none` on the root only (x stays free for the OS gesture) |
| Desktop web | A visible back chevron in the toolbar row, `Esc` closes the topmost layer; `alt+←` stays the browser's |

#### 4.0.6 Global keys (web; hardware keyboards on Flutter)

| Keys | Action |
|---|---|
| `mod+k` | Command palette |
| `mod+b` | Toggle the sidebar |
| `?` | Keyboard shortcuts sheet (only what works here) |
| `/` | Focus the current screen's search or filter |
| `g h` · `g l` · `g s` · `g u` · `g d` · `g a` · `g t` · `g p` · `g ,` | Go to Home, Library, Sources, Updates, Downloads, Activity, Stats, Profiles, Settings (1 s chord window) |
| `mod+enter` | Continue the most recent read |
| `r` | Refresh the current list |
| `[` / `]` | Previous / next in-page tab |
| arrows, `h j k l`, Home, End | Move within grids and rails (roving focus) |
| Enter, `o` | Open the focused item |
| `.`, `shift+F10` | Item menu |
| `x`, `shift+x` | Select, range select |
| `m`, `d`, `Delete` | Row actions: mark read, download, remove (with Undo) |
| `u` | Undo the last destructive action (while its toast is visible) |
| `alt+↑/↓/←/→`, `alt+shift+↑/↓` | Reorder the focused item |
| `Esc` | Close the topmost layer, clear selection, leave the reader |

Settings → Shortcuts has a **Single-key shortcuts** switch (default on). Off, every binding without a modifier is skipped (WCAG 2.1.4). No shortcut fires while typing in a field unless it is marked `allowInInput`.

#### 4.0.7 Platform rules applied to every screen

- **iOS:** status bar light; edge-to-edge; `CADisableMinimumFrameDurationOnPhone` true (120 Hz); haptics through gaimon; Dynamic Type through `MediaQuery.textScalerOf` with the caps in §2.2.3; Reduce Transparency read through the `mm/haptics` channel.
- **Android:** edge-to-edge with transparent status and navigation bars (light icons); the readers switch to `immersiveSticky`; predictive back; high refresh rate on launch; API 34 haptic constants through the channel with version guards (minSdk 24).
- **Mobile web (PWA):** `display: standalone`, `theme-color` `#000000`, `apple-mobile-web-app-status-bar-style: black-translucent`, black startup images; no haptics on iOS Safari, `navigator.vibrate` subset on Android Chrome.
- **Desktop web:** keyboard first; hover states on everything interactive; `:focus-visible` rings; right-click opens context menus; trackpad pinch in the readers.
- **Offline everywhere:** the "Offline" status capsule in the nav row; lists fall back to cached or downloaded data where the data layer supports it; server-only screens show the offline lens.

### 4.1 Setup (server address; iOS and Android only)

- **Layout (phone):** bare frame on the aurora field. Column max 420: a 72 px `mm-mark` glass lens, 24 px gap, `largeTitle` "Connect your server" (letter reveal), `body` `label2` "Enter the address of your ManhwaManiacs server. You can change it later in Settings.", 32 px gap, the URL field (label "Server address", placeholder `https://manhwamaniacs.example`), helper "https is required.", primary L "Connect" (full width), plain "Use the default address" beneath when a default is compiled in.
- **Hierarchy:** lens → title → field → Connect.
- **Signature moment:** on success the typed address "drains" into the lens: the field's text scales down and travels into the lens centre on `zoom` while the lens swells 1 → 1.2 on `lens` and flashes its specular rim; the lens then becomes the portal to Login (it expands to fill the screen on `zoom`, revealing Login behind it).
- **Transitions:** in from the splash handoff (the splash lens becomes this lens); out through the lens zoom.
- **Gestures:** none beyond the keyboard; drag down dismisses the keyboard.
- **States:** idle; typing; validating (button loading, the lens ring spins); error "Couldn't reach that address" / "That address isn't a ManhwaManiacs server" / "Use an https address" (shake + field error); success.
- **Keys:** Enter connects.
- **Coverage:** mobile S01 1–9, G7.

### 4.2 Splash and first paint

- **Native layer:** the neutral MM column in `#F3EEE6` on `#000000` (`flutter_native_splash` 2.4.8, Android 12 icon inside the 192 dp circle); identical for both skins.
- **Handoff:** the first Flutter frame redraws the neutral mark at the same size and position, then runs **Droplet** (§7.4): cold start 1,200 ms, warm start (resumed within 4 h) 400 ms. Tapping anywhere skips to the handoff.
- **Session probe:** while `GET /auth/me` resolves (3 s timeout on mobile), the lens holds and a liquid ring rotates around it; when auth resolves, the lens hands off: into the dock (signed in with a profile), into the picker orbs (signed in, no profile this session), or into the Login form's lens (signed out).
- **Web:** the root layout server-renders the neutral mark as inline SVG on black; the Droplet plays once per browser session after hydration (`sessionStorage['mm.skin.splash']`); on warm navigations it never plays.
- **States:** probing, signed in offline (the lens gets an "Offline" capsule and hands off to the app with cached data), probe failed with no cache (hands off to Login's unreachable state).
- **Coverage:** mobile S02 1–4, G2 (`AuthPending`), web L1, RG1.

### 4.3 Login

- **Layout, desktop web:** the aurora field fills the window; a centred `materialRegular` slab 440 wide, radius 32, padding 32: the 56 px `mm-mark` lens, heading, subtitle, the form, the footer. **Mobile web / iOS / Android:** the same column full width with 20 px margins, the lens at top, the slab replaced by plain content on the field; on mobile, a "Server: host" row with a copy icon (tap copies the full URL, toast "Copied https://…") and a plain "Change server" link to Setup.
- **Heading:** "Welcome back" with the **typing reveal** (50 ms per character, §6.2); subtitle `body` `label2` "Sign in to your library."
- **Form:** Username (autofocus, `autocomplete=username`), Password (reveal toggle), "Keep me signed in" switch (default on), error line, primary L "Sign in" (full width, disabled until both fields have text), footer "Need an account? **Create one**" (only when registration is open).
- **Signature moment:** on success, the slab condenses: its contents fade (`fadeOut`), the slab shrinks into a droplet at the lens position on `zoom`, the droplet falls into the lens with `logoLand`, and the lens splits into the profile orbs of the picker (each orb springs out to its slot on `celebrate`).
- **States:** resolving (the lens with its ring, no form); unreachable (lens with cloud-slash, "We couldn't reach the server", `danger` detail, "Try again" secondary, plus "Change server" on mobile); bootstrap (heading "Welcome to ManhwaManiacs", subtitle "This server has no accounts yet. Create the first one; it becomes the administrator.", primary "Create the first account" → Register); normal; pending (fields disabled, button loading); errors with shake: `invalid_credentials` "That username and password don't match.", `account_disabled` "This account is deactivated. Ask the server's owner.", `rate_limited` "Too many attempts. Try again in 42 s." (the button counts down in `mono` and re-enables itself), network "Couldn't reach the server."
- **Transitions:** in from the splash lens; out through the signature to the picker (or straight to Home when a profile is remembered and valid).
- **Keys:** Enter submits; Tab order username → password → reveal → switch → submit → footer.
- **Coverage:** web R1 L1–L9; mobile S03 1–13.

### 4.4 Register

- **Layout:** as Login (bare frame, slab on desktop, back nav button top-left on phone).
- **Variants:** **Closed** ("Registration is closed", "This server isn't accepting new accounts. Ask its owner for access.", secondary "Back to sign in"); **Bootstrap** ("Claim this server", "This first account becomes the administrator.", submit "Create the administrator account" with a shield-check glyph); **Open** ("Join ManhwaManiacs", "Create an account on this server.").
- **Fields:** Username (autofocus), Password (helper "At least 8 characters"), Confirm password (live "Passwords don't match." with `aria-invalid`), Invite code (only when the server requires one outside bootstrap; placeholder "Ask whoever invited you"), Display name (optional, "How your name appears"), Email (optional, `type=email`), "Keep me signed in" switch, error line, primary "Create account", footer "Already have an account? **Sign in**".
- **Signature moment:** the same condense-into-the-lens as Login, landing on the picker's empty state, where the "Create your first profile" orb is already waiting.
- **States:** resolving, unreachable, closed, bootstrap, open, pending, errors (`invite_code_required`, `invite_code_invalid`, `registration_disabled`, `username_taken` "That username is taken.", `invalid_username`, `weak_password`, `rate_limited` with countdown, `bootstrap_window_expired`, `bootstrap_already_claimed`), each with the shake on the first offending field.
- **Keys:** Enter submits.
- **Coverage:** web R2 RG1–RG5 and its 9 elements; mobile S04 1–17.

### 4.5 Profile picker ("Who's reading?")

- **Layout (all platforms):** takeover on the focused profile's mood field. Centred: `largeTitle` "Who's reading?" (letter reveal) and `callout` `label2` "Your library, progress and mood follow the profile you pick."; below, a centred wrap of profile orbs (96 phone, 128 desktop) with names in `headline` under each, 24 px (phone) / 40 px (desktop) apart, plus an **Add profile** orb (dashed 1.5 px `g600` ring, plus glyph) while fewer than 5 exist. Top-right nav button "Edit" (manage mode). Desktop: the orbs sit in one row; hover grows an orb to 1.08 and cross-fades the field to its mood (`tintShift`).
- **Idle physics:** orbs drift (§3.26); the focused orb's mood field breathes with the ambient drift.
- **Signature moment (selection):** tap an orb → it inflates to 1.35 on `celebrate` with `profileSwitched`; the other orbs are **repelled** outward (each gets a radial impulse of 900 px/s away from the chosen orb, decays on `dismiss`, fading to 0) like droplets pushed by a larger drop; the title fades; the chosen orb then flies to the dock's You tab (phone) or the sidebar's profile capsule (desktop) on `zoom`, leaving a short meniscus tail, and the app materialises around it (the dock forms from the orb as it lands). The whole hand-off is 900 ms and can be interrupted by tapping another orb before the flight starts (the choice changes, the repelled orbs are pulled back). If the chosen profile's skin is Cinematic, the restart runs inside this transition (no confirm, no undo), per `stack-decision.md` §2.4.
- **Manage mode:** "Edit" turns the orbs into editable objects: each gains a `glassThin` pencil badge and breathes slowly (scale 1 ↔ 1.02 over 2 s); tap opens the profile form; "Done" leaves. Long-press any orb in normal mode opens its context menu: Edit, Use without animation, Delete (hold-to-confirm alert).
- **Gestures:** tap, long-press, and dragging an orb (it follows the finger and springs home; pure delight, no action).
- **States:** loading (orb-shaped skeletons); empty ("Create your first profile" lens, "Profiles keep progress, follows and mood separate for each reader on this account.", primary "Add profile"); error with no cache ("Profiles are unavailable" + Retry); unreachable with a cached profile (a single orb "Continue as {name}" + Retry); at limit (no Add orb, footnote "Up to 5 profiles").
- **Transitions:** in from Login/Register's lens split, from the You tab's "Switch profile" (the current orb flies from the dock back to the centre and the others fade in around it), from the dock's long-press switcher (skips the picker entirely); out through the signature.
- **Keys:** arrows move focus between orbs, Enter picks, `e` edits the focused profile, `n` adds, Esc returns to the app when a profile is already active.
- **Coverage:** web R3 P1–P8, A10–A12, A16; mobile S05 1–15, G3.

### 4.6 Profile form and Manage profiles

**Profile form** (`/profiles/create`, `/profiles/edit/:id`): phone: a large sheet over the picker; desktop: a 560 px window blooming from the Add orb or the pencil badge.

- **Content:** a 96 px live orb preview (gradient cross-fades over `colorShift`, glyph morphs on `snappy`), Name field (max 30, "e.g. Late-night reads", autofocus), **Avatar** grid (6 × 2 orbs of 56 px; tapping one launches a copy of it along a short parabolic arc into the preview: gravity 3,000 px/s², 280 ms, landing with `tick` and `selection`), **Mood** choice chips with 12 px colour dots (the droplet slides; the sheet's field retints live), **Mature (18+)** switch with the §3.25 flow, error line, primary "Create profile" / "Save changes", and in edit mode a destructive **hold-to-confirm** "Delete profile" ("This removes {name} and its reading data from this account. It cannot be undone.").
- **States:** loading (edit), not found ("This profile may have been removed."), error, pending, saved (the sheet dismisses and the picker's orb for this profile does a `celebrate` hop).
- **Keys:** Enter saves, Esc closes.

**Manage profiles** (`/profiles/manage`, reached from You → Profiles on phone and the sidebar profile menu on desktop):

- **Layout:** large title "Profiles", grouped list: each row = 44 px orb, name `headline`, mood `footnote`, "Active" tag on the current one; trailing buttons "Use" (plain), edit (pencil icon), and the row's ⋯ menu (Edit, Use, Delete, Move up/down). Rows reorder by drag (the profile `sort_order`). Add button in the nav row, disabled at 5 with the footnote "Up to 5 profiles".
- **States:** loading, error, empty (dashed card "No profiles yet").
- **Keys:** arrows move between rows, Enter uses the focused profile, `e` edits, `n` adds, `Delete` deletes (opens the confirm), `alt+↑/↓` reorders.
- **Coverage:** web R4 PF1–PF8, PM1–PM8, A13–A15; mobile S06/S07 1–15.

### 4.7 Onboarding (a new profile's first visit)

Shown once, the first time a profile with no reading history opens Home. Every step can be skipped ("Skip" plain button in the nav row); progress is a row of five droplet dots at the top (the current dot is a stretched capsule that slides on `tab` as pages change).

1. **Welcome:** "Hi, {name}." with the **typing reveal**, then `body` "Let's set up what this profile likes. It takes a minute." Primary "Start".
2. **Look:** the two skins as mini previews (each skin ships a looping 6 s animated WebP of its Home, 360 × 780, under 900 KB, captured by the Playwright screenshot harness; web shows it in an `<img>`, Flutter in an `Image.asset`, both of which play animated WebP natively), Glass selected; choosing Cinematic marks the profile's skin and restarts into it at the end of onboarding (no hold-to-confirm here, because nothing is lost yet).
3. **Formats:** four large toggle cards (Manhwa, Manga, Manhua, Web novels; Web novels only when novels are enabled), multi-select, `chipToggle`.
4. **Genre field (signature):** 24 genre **bubbles** float in a 2-D physics field: circles (radius 36 to 52 by genre popularity) with soft collisions (position-based dynamics, 4 iterations per frame, restitution 0.4), a weak pull toward the centre (spring toward the field centre at `k = 4`), and the gyroscope tilting gravity up to 400 px/s² so the bubbles slosh when the phone tilts. Tap a bubble: it **inflates** to 1.35 × on `celebrate` (liked; fill `iris600` at 60 %, label `onTint`) and pushes its neighbours away; tap again: it **shrinks** to 0.8 × and dims (not for me, strike-through label); a third tap resets it. Drag flings a bubble through the field. Desktop: the same field in a 720 × 480 area; keyboard: arrows move focus between bubbles by proximity, Space cycles its state.
5. **Seed titles:** "Pick a few you've read or want to read": a grid of world recommendations filtered by the liked genres and formats (`GET /library/world/recommendations`), each available card with a follow toggle (`POST /library/follow`), plus a search field ("Search your sources") for titles not shown.
6. **Done:** "Your shelf is ready." The progress dots merge into one droplet that falls into the dock's Home tab; Home opens with its first rails built from the picks.

- **Storage:** formats, liked and avoided genres are saved per profile in scoped storage (`mm.taste` on web `scoped-storage`, the same key under the Flutter per-profile prefs) and sent as context with AI requests (§5.1).
- **States:** AI or world recommendations unavailable (step 5 shows the pinned and popular source catalogues instead), offline (onboarding is deferred: "Set up later" goes to Home's new-profile state), follow errors (per-card error on the toggle with a retry).
- **Keys:** Enter continues, Esc skips the step, `mod+enter` finishes.
- **Coverage:** new flow (no inventory row); fills the new-profile gap noted in the web first-run banner G38.

### 4.8 Home

The landing screen for every profile (`/` redirects here). Composed client-side from continue-reading, recently-updated, world recommendations, the AI suggestion availability, pins, social and statistics (§5.1 details the AI rails and states).

- **Layout, phone:**
  - Nav row: profile orb (leading; tap opens You, long-press opens the profile switcher), content-mode capsule and the **bell** (trailing; count badge; → Updates).
  - **Greeting** (`largeTitle`, typing reveal once per app session): "Good evening, Yash" (by local time: morning 05–12, afternoon 12–17, evening 17–22, night 22–05), with a subline `footnote` `label2`: "3 new chapters · 12-day streak" where the streak part is a `streak` chip (flame glyph) that opens Statistics.
  - **Hero spotlight:** a floating portrait card (cover 2:3, 62 % of the screen width, radius 26) in front of its own blurred enlargement (the ambient field turned up to 36 %); title `title1` (letter reveal), a meta line ("Ch 143 is new · Manhwa"), and actions: tinted primary "Continue Ch 143" (or "Start reading") and a `glassClear` "Details" secondary; below the card, droplet page dots. Five spotlights, in order: next up (the most recent continue item with new chapters), an AI "because you read" pick, a friend's recommendation (when social is on), the newest update in a followed series, and a "Previously on" candidate (a series paused 14+ days). The card **tilts** with the gyroscope up to ±6° (`track`), its specular rim follows, and it pages horizontally with projection (one card per flick, `settle`); tapping it opens detail with the zoom, and long-pressing lifts it like a poster, so it can be thrown up to open or dropped on a friend's orb.
  - **Rails:** Continue reading (continue stacks, §3.7), Updated for you (followed series with new chapters, "N new" badges), Because you read {title} (AI, one rail per seed, up to 3), For you (AI), Friends are reading (social), Your genres (a chip row from genre affinity, each chip opens a filtered Search), New in your pinned sources (source rows: for each pinned source a mini rail of its latest), Ready offline (downloaded series), Recently added to your library.
  - Bottom accessory: Continue (after the hero scrolls away), narration or downloads when active.
- **Layout, desktop:** content column beside the sidebar. The hero becomes a stage 440 px tall: the cover card (240 px wide) at left over the blurred enlargement that fills the stage width, the title (`display` 64), meta, the `why` line and actions at right, and a strip of the next four spotlight covers bottom-right (click or `←`/`→` to page; hover tilts the card toward the pointer). Rails show 7 (1440 px) to 9 (1920 px) posters with glass arrows on hover.
- **Tablet:** the desktop stage at 360 px height; rails 5 to 6 posters.
- **Hierarchy:** greeting → spotlight → continue → updates → AI rails → social → the rest.
- **Signature moment:** the greeting types in while the spotlight card drops into place on `lens` (a droplet landing on the field: it arrives from scale 0.9 and 24 px above, and the field ripples outward once from its centre as a 12 % brighter ring expanding to the screen edge over 600 ms).
- **Transitions:** in as a tab root (cross-fade + wave) or from the profile hand-off (the app materialises around the landing orb); out by zooms into details and dives into readers.
- **Gestures:** pull to refresh (droplet), spotlight paging and tilt, throw to open, long-press lift on any poster (context menu with Continue, Details, Add to collection, Mark read, Download next 10, Previously on, Recommend to…, Not interested on AI cards), swipe the continue stack left to reveal its recap.
- **States:** loading (greeting shows immediately; spotlight skeleton card; three rail skeletons); **new profile** (no history and no follows: onboarding runs first; if skipped: the spotlight becomes a "Start here" card, rails show "Popular on your pinned sources" and "For you" from world recommendations, and an empty lens "Nothing followed yet" + "Browse sources" sits below); **AI unavailable** (AI rails replaced by one inline "Recommendations are resting" card with the server's reason; everything else works); **offline** (greeting + an "Offline" capsule; the spotlight shows the most recent downloaded series; only "Ready offline" and "Continue reading" (downloaded only) rails remain); **error** (per-rail error cards; a full-screen error lens only if every source fails); **caught up** (Updated rail omitted; the spotlight's first card says "You're caught up" and offers "Previously on" or an AI pick).
- **Keys:** `mod+enter` continue; `←`/`→` page the spotlight when it has focus; `↑`/`↓` between rails; Enter opens; `.` item menu; `r` refresh; `g u` Updates.
- **Coverage:** replaces the landing role of web R5 (LS1–LS12) and mobile S08 (continue rail, followed grid moves to Library), G38, G39 (new chapters surface in the spotlight, the bell and the global capsule); new feature §5.1.

### 4.9 Search

- **Layout, phone:** the search orb expands into the bottom field (§3.4). The screen above it:
  - **Idle:** "Recent" rows (clock glyph, the query, a remove ×) up to 4, "Trending" chips (fantasy, romance, action, manhwa, manga, webtoon, horror, sci-fi), a "Browse sources" row, and the **Ask** card: a `surface1` slab "Describe what you want to read" that opens the AI prompt (§5.1.2) when AI is available.
  - **Results:** the scope segmented control (Library · Sources · Dialogue · Novel text) above the field; a **tier progress** capsule under the nav row: "18 results · searching 8 more sources" with a liquid fill for sources answered / queried; group filter chips (All · With results · Pinned); one section per source: header (28 px logo or the Library glyph in `info`, source name `headline`, count badge) and a horizontal rail of result posters (112 × 168 + 2-line title); failed sources show a note row "This source didn't answer" (`danger` cloud-slash) with a "Retry" plain button (retrying shows 4 poster skeletons in that row); quiet sources collapse into a "Show 12 sources with no matches" disclosure row; a **source index** strip on the trailing edge (one glass capsule 28 wide with source initials; drag to scrub between sections with `selection` ticks, like an index).
  - Dialogue scope: result cards per §4.23; Novel text scope: hits inside downloaded and fetched novel chapters (client-side over cached chapter text) with a snippet.
- **Layout, desktop:** a 56 px glass search field centred above the results (the palette handles quick jumps; this is the full screen); left filter column 220 px (scopes as a vertical segmented list, group filters, "Hide sources with no matches" switch); results as a grid per source section (6 to 8 posters per row).
- **Hierarchy:** field → scope → groups by relevance (Library first, then pinned, then by result count).
- **Signature moment:** tier-2 arrival: as slow sources answer, their sections **drop in** between existing ones with the wave (cause = the tier capsule), and the tier capsule's liquid fill sloshes forward on `lens` with each answer, ending in a check when all sources have answered.
- **Transitions:** in from the orb morph (phone) or the palette's "See all results" (desktop); out by zoom into series detail.
- **Gestures:** scroll, source index scrub, long-press lift on results, swipe down on the field to collapse (phone).
- **States:** idle; typing (300 ms debounce); tier-1 loading (3 section skeletons); tier-2 pending; results; partial failures; empty ("No results for “{q}”", "Try another spelling, or search the dialogue instead." + "Search dialogue" when manga mode); no sources in this filter ("No pinned sources answered" / "Pin a source on the Sources tab to keep it here", or "Switch back to All to see every source that answered"); error ("Search failed" + Try again); offline (searches downloaded titles only, with a notice); rate limited ("Sources are busy. Retrying in 12 s", auto-retry countdown).
- **Keys:** `/` focuses the field; `↓` from the field into results; `[`/`]` change scope; Enter searches at once; Esc clears, then leaves.
- **Coverage:** web R14 SE1–SE11, A51–A54; mobile S20 1–20; capabilities §18.

### 4.10 Sources

- **Layout, phone:** large title "Sources", content-mode capsule in the nav row; a filter well ("Filter sources") and chips All · Pinned (count) · 18+ (only when the gate is open) that pin under the nav row with a hard edge; section **Pinned** (drag handles visible; drag to reorder, which writes `PUT /sources/pins` in order), section **All sources**; source rows (§3.7).
- **Layout, desktop:** the pinned sources as a horizontal glass-free shelf of 180 × 96 cards (logo 48, name, latest update time) at the top, reorderable by drag; below, "All sources" as a two-column grid of source rows; the filter field and chips in the toolbar row.
- **Signature moment:** **pinning flies**: tapping a row's pin lifts the row (scale 1.03), it travels up into its new slot in Pinned on `zoom` while the list below closes the gap on `snappy`, `selection` when it lands; unpinning sends it back down to its alphabetical place.
- **Gestures:** pull to refresh; drag to reorder pins; swipe a row left for Pin/Unpin; long-press for Pin, Open, Copy source id.
- **States:** loading (10 row skeletons); error ("Couldn't load sources" + Retry); none installed ("No sources installed" / "No novel sources installed"); no match ("No sources match" / "Try a different name"; Pinned filter: "No pinned sources" / "Tap the pin on any source to keep it at the top"); pins failed to load ("Pinning is unavailable until your pins load" inline notice + Retry, pin toggles disabled); pin save failed (toast "Couldn't update your pins" and the row flies back); a pinned source no longer installed ("No longer installed" row at 55 % with an "Unpin" button). Pins that the 18+ gate hides are simply absent.
- **Keys:** `/` filter, arrows move between rows, Enter opens, `p` pins the focused source, `alt+↑/↓` reorders pins.
- **Coverage:** web R15 SL1–SL13, A55–A57; mobile S16 1–16; G4 (18+ filter and badge).

### 4.11 Source catalogue

- **Layout, phone:** nav row with back and a trailing glass group (refresh, ⋯); header: 48 px logo + source name `largeTitle` (letter reveal) + a count line ("412 series · Latest") + a **freshness capsule** ("Updated 12 min ago", or `warning` "Saved copy · 2 h" with an explanation popover when the catalogue is stale); the search well ("Search this source"); **browse modes** as in-page tabs with a swipeable pager (Popular, Latest, and whatever the source exposes; hidden while searching); a genre chip ("All genres" / the chosen genre) that blooms into a searchable menu; the grid: 3 columns on phone, posters 2:3 with 2-line titles; infinite scroll.
- **Layout, desktop:** the same with 5 (1024) to 8 (1920) columns; modes as tabs in the toolbar row; the genre menu as a popover with a filter field.
- **Top capsule (all platforms):** after 400 px of scroll a `glassThin` "Top" capsule with an up-arrow materialises bottom-right (above the dock on phones); tapping it scrolls to the top on `page` and dematerialises it.
- **Novel sources:** the grid becomes a book shelf: rows with a 48 × 68 plate, Literata title 17, "by Author · 120 chapters · Ongoing", a 2-line blurb, and genres in `caption1` uppercase.
- **Signature moment (opening a slow source):** the "Opening" lens: the source's logo sits in a 96 px glass lens at the top of the grid area while three covers from the profile's continue list orbit slowly behind it in the ambient field (radius 80 px, one revolution per 9 s, each on its own drift phase); after 3 s a line appears: "This source can take about 10 s"; when data arrives, the lens pops (`lens` shrink to 0 with a small ripple), and the grid enters with a wave from the lens position.
- **Transitions:** in by push from Sources or a genre tag (the tag's text flies into the genre chip); out by zoom into detail.
- **Gestures:** pull to refresh (refetch with `refresh=true`), pager swipes between modes, long-press lift on posters, "Top" capsule.
- **States:** opening (signature); loading more (a liquid ring at the grid's end); load-more failed ("Couldn't load more" + Retry, which refetches only that page); end ("End of results"); empty ("No series found" / "No results for “{q}” on this source"); error (lens "Couldn't load this catalogue" + message + Try again); stale (the warning capsule); rate limited (inline notice with the retry countdown).
- **Keys:** `/` search, `h j k l` and arrows through the grid, `[`/`]` modes, `r` refresh, Home/End.
- **Coverage:** web R16 SB1–SB15, A58–A61, A64; mobile S17 1–14; capabilities §16.2.

### 4.12 Series detail (manga, manhwa, manhua)

One screen for both identities (`/library/:followedId` resolves to the source identity and renders the same screen as `/sources/:s/series/:id`), so a series has one page whether or not it is followed.

- **Presentation:** phone: a **sheet** over the screen it came from, opening at `medium` (52 %) and dragging to `large`; desktop and tablet: a **window** 960 wide (tablet: full content width), radius 32, `materialThick`, over the recessed page (scale 0.97, blur 8, dim 50 %); a deep link without a parent renders the same layout as a full page.
- **Top band:** the cover's blurred enlargement (ambient field at 28 %) fills the top 280 px of the sheet, fading to black; the nav row inside the sheet: close (×) leading at `medium`, back chevron at `large`; trailing glass group: share (copies the series URL), bookmark list for this series, ⋯.
- **Header (medium detent):** cover 112 × 168 (radius 14) at left, overlapping the band; right of it: title `title1` (letter reveal), "by {author} · art by {artist}" `footnote` `label2`, tags (status tag, first four genres as links to the source catalogue with `?genre=`, 18+ badge when mature), and "412 chapters · Updated 2 d ago" `caption1`.
- **Actions:** the **split primary** "Continue · Ch 143" (or "Start reading", or disabled "All caught up") whose chevron menu holds Read from the start, **Read all** (one scroll; only with more than one chapter), Pick a chapter, Download next 10; then a row of glass secondary buttons: **In library / Add to library** (follow toggle; selected state per §3.1), **favourite** star (followed only), **notifications** bell toggle (followed only; `PATCH notify`), **Download** (progress button for the whole series), ⋯ (Reading status: Unread, Reading, Completed, On hold, Plan to read, Dropped; Add to collection; Tags… (a `medium` sheet listing the profile's tags as colour chips to toggle on this series, plus "New tag" with a name field and one of the ten speaker hues as its colour; `GET`/`POST /library/tags`, `POST`/`DELETE /library/series-tags`); Previously on; Recommend to…; Check for new chapters (`POST /updates/followed/{id}/check`); Content rating: Automatic, Always mature, Never mature (writes `mature_override`, followed series only, shown only when the profile's gate is open); Open source page in browser).
- **Below (large detent):** description (`body`, 3 lines with "More" that expands on `snappy`); a **download card** when anything is queued or saved ("24 of 412 chapters saved on this device" with a liquid bar, "Downloading now · page 18 of 40", "3 waiting · 1 failed", the pause reason, and on phones the note "Downloads run while the app is open"); **Previously on** entry (§5.1.3); **Friends** row (social: orbs of friends reading it, their latest reaction); **More like this** rail (§5.1.4); **Chapters** section.
- **Chapters section:** a header that pins with a hard edge: "Chapters" `title2`, "24 of 412 downloaded" `footnote` + Download trigger, "Dialogue indexed for 34 chapters" `caption1` (from `GET /ocr/coverage`, manga only, when any), the Newest/Oldest segmented control (persisted per series), "Select" plain button, and a go-to field (`/`) for long lists; then chapter rows (§3.17) with the download control; the in-progress row has its bar; read rows dim; fast-scroll thumb with a chapter-number bubble for lists over 200.
- **Select mode:** row checks spring in; helper assist chips "Next 10", "All unread (n)", "All (n)", "None"; the floating glass toolbar: "{n} selected · {k} already saved", "Download {n}", "Mark read", "Mark unread", "Done"; running: liquid progress "Downloading 3 of 12" + Stop; summary toast ("12 chapters downloaded", "10 of 12 downloaded, 1 with missing pages, 1 failed", "Out of room: only 380 MB free. Remove some downloads and try again." with "Manage downloads").
- **Signature moment:** **the cover lands**: the poster that was tapped or thrown flies into the cover slot on `zoom` carrying its velocity; if it was thrown hard, the sheet opens straight to `large` (the projection of the throw decides the detent). Dragging the sheet from `medium` to `large` shrinks the cover into the nav row's title capsule (the capsule shows a 24 px cover thumbnail + title), a collapsing header driven 1:1 by sheet position.
- **Transitions:** in by zoom (posters) or push (links without a poster); out by dragging the sheet down (the cover flies back to its origin if the origin is still on screen, otherwise the sheet slides down on `dismiss`); dive into the reader from a chapter row or Continue.
- **Gestures:** sheet drag and detents; pinch or tap on the cover opens the image viewer; chapter rows: swipe right = mark read/unread, swipe left = download/remove download, long-press = context menu; long-press the Continue button = the split menu.
- **States:** loading (skeleton: cover block, three title bars, two button capsules, 8 chapter rows); offline (from cache and downloads: an "Offline" capsule; chapters list shows only downloaded chapters in full colour and the rest dimmed with "Needs a connection"); error ("Couldn't load this series" / "The source didn't answer." + Try again + Back to source); chapters loading (8 row skeletons); chapters offline ("The chapter list needs a connection"); chapters error (+ Try again); chapters unavailable ("Chapters didn't come through" / "This source lists 412 chapters but returned none just now; that is usually the source, not you." + Try again); no chapters ("No chapters yet" + Back to source); caught up; not in library vs in library; follow pending ("Adding…" on the button); follow feedback toast ("Added Solo Leveling to your library. New chapters will notify you." with Undo; "Removed Solo Leveling from your library." with Undo); rate limited (inline notice).
- **Keys:** `c` Continue, `a` Read all, `f` add/remove from library, `*` favourite, `n` newest/oldest, `/` go to chapter, `x` select, `d` download next 10, Enter on a row opens it, `m` marks it read, Esc closes the sheet.
- **Coverage:** web R7 SD1–SD21, R17 SS1–SS18, §12.2 DP1–DP7, A28–A33, A37, A62–A63, A87–A88; mobile S10 1–21, S18 1–16, M1 (series actions), M2 (chapter selection bar); capabilities §7, §16.3, §20 (coverage), §21 (per-series check).

### 4.13 Book page (novel series)

The same sheet or window as §4.12, dressed as a book's front matter (Apple Books reference).

- **Header:** book plate 144 × 208 (desktop 180 × 260, radius 6, a 1 px paper-edge highlight on the right side and a 2 px spine shadow on the left), title in **Literata** 30/36 `opsz` 36 `wght` 560, byline Literata italic 17 "by {author}", a 56 px rule, facts row `mono` 13 "412 chapters · ≈ 1.2 M words · ≈ 80 h · Ongoing", the estimate note `caption1` "Length estimated from 12 chapters read so far", genre tags (up to 24, links), blurb Literata 17/30, max 62 ch.
- **Actions:** primary "Start reading" / "Continue reading · Ch 12" / "All caught up"; secondary "Add to library" / "In library"; "Download book" with the count of unsaved chapters in `mono`; **Audiobook** button with its live status ("Make audiobook", "Make audiobook · 12 done", "Narrating · 3 in progress, 5 waiting", "Waiting for the narration PC · 5", "Audiobook · 40 narrated") opening the Audiobook sheet (§4.16.5); the note "Narration of new chapters is not available right now" when rendering is off; ⋯ (Previously on, Recommend to…, Add to collection, Voices for this book, Check for new chapters).
- **Contents:** "Contents" Literata 22; the go-to field (`inputmode=decimal`, Enter jumps to the first match, Esc clears; matches list up to 12 with "and 38 more", "Type a chapter number.", "No chapter 900 in this book."); order segmented "First → last" / "Last → first" (default first → last); "Pick chapters" (select mode with helpers "Next 10", "All unread", "Whole book"); a windowed list of 400 chapters around the focus with "Show earlier chapters (212)" and "Show more chapters (400)" buttons; TOC rows: right-aligned Literata tabular ordinal in a 44 column ("·" when none), title Literata 16 (read rows at 45 %), meta `caption1` "3.4k words · 14 min", "42 %" in `iris400` when reading, a headphones badge when narrated ("Audio saved" when saved on the device), download control. The focused chapter (`?chapter=` or go-to) scrolls to centre on `camera` and pulses once (`iris600` at 14 % fill that fades over 900 ms).
- **Signature moment:** the plate **opens**: on "Start reading", the plate rotates open on its spine (rotateY 0 → −78° on `page`, perspective 900 px) while the novel reader's paper expands from the plate's rectangle to full screen (the dive), so the book literally opens into the reader.
- **States:** as §4.12, with novel copy ("This book needs a connection to load", "Couldn't load this book", "Contents didn't come through", "No chapters yet: this source hasn't published any chapters for this book.").
- **Keys:** as §4.12 plus `g` go to chapter.
- **Coverage:** web R17n NB1–NB19, A74–A75; mobile S18 17–30, N2 (contents sheet), N3 entry.

### 4.14 Manga reader (strip, paged, read-all)

#### 4.14.1 Canvas

- **Background:** `#000000` (reader background option "Graphite" `#0B0B0F` for readers who prefer a softer edge).
- **Strip (default, "continuous"):** a virtualised vertical column, pages seamless (page gap option: 0 or 8 px), full width on phone at 1×, `clamp(480px, 50vw, 900px)` centred on desktop with black gutters. Page boxes are sized from the manifest's width and height before images load (placeholder `#0B0B0F`, no spinner), so nothing jumps. Neighbouring chapters are stitched in (window of current ± 1, loaded when within 4 pages of an edge) with a **chapter seam**.
- **Chapter seam:** 96 px: a hairline, then "CHAPTER 144" in `caption1` +0.2 em (letter reveal as the seam enters the viewport), the chapter title `footnote` `label2`, a hairline; as the seam passes the top of the screen, a `glassThin` chip "Chapter 144" sticks under the nav row for 1.2 s and dematerialises. `chapterSeam` haptic when the seam crosses the reading line.
- **Paged:** single or double (double on tablet landscape and desktop), fit width / height / original, RTL mirrors spreads, 8 px spread gap; page turns per the Page transition setting: **Slide** (finger-tracked, projection decides, `page` spring, the incoming page slides over with an 8 px soft shadow), **Fade** (160 ms), or **None**.
- **Read-all:** the strip streams the whole series in order (chapter 1 or `?from=` first, the rest filling in by batch manifests); seams are slim (48 px) with no card, no pause.
- **Broken page:** inside its box, a 72 px glass lens with the image-broken glyph, "This page didn't load", and a "Retry" secondary (remounts only that image).

#### 4.14.2 Chrome

All reader chrome is `glassRegular` with `underlayAdaptive` and the **page tint** (§5.4.4), over soft edges that fade in and out with the chrome.

- **Top-left group:** back (44) + title capsule "Solo Leveling · Ch 143" (tap → series sheet; long-press → the in-reader chapter list sheet). Read-all adds `mono` "143 of 412".
- **Top-right group:** download control (compact progress button: Download → "18/40 · 45 %" with a cancel × → Saved check → tap for "Remove download?" inline confirm that reverts after 4 s; warn states "Save again" and "Resume 18/40"), bookmark (toggle; saved state Fill `iris400`), settings (sliders glyph).
- **Bottom capsule** (56 tall, inset 16 + safe area, max 520 wide): previous chapter (disabled at 30 % when none), page readout `mono` "18 / 40", cruise (auto-scroll) button (§5.4.1), next chapter (tooltip with the next chapter's label); a 2 px progress hairline inside the capsule's bottom edge.
- **Scrub rail:** a 44 px hit strip on the trailing edge between the two groups; visible 3 px track `rgba(255,255,255,0.28)`, fill `iris500`, 12 px thumb. Touch: the track widens to 6 px, a **magnifier lens** (`glassThick` 120 × 164, radius 20) grows out of the thumb on `lens` and follows it on `track`, showing the target page's thumbnail (the image proxy at `w=240`) and `monoLarge` "18"; `scrubPage` ticks (textured), `scrubEdge` at the first/last page and at chapter boundaries in read-all (where the rail is segmented by chapter with 2 px gaps); bookmarks show as 4 px droplets on the track. Release: jumps of up to 5 pages glide on `page`; longer jumps cut with a 120 ms cross-fade. Keyboard: the rail is `role="slider"` with `aria-valuetext="Page 18 of 40"`.
- **Auto-hide and minimise:** 24 px of cumulative downward scroll → the top groups dematerialise (lensing out, blur 8, scale 0.92) and the bottom capsule **morphs** on `minimize` into a 32 px pill showing only "18 / 40"; 56 px of upward scroll, a centre tap, the chapter end, or pointer movement into the top or bottom 72 px (desktop) restores them. Idle hide after 3000 ms only when a tap opened the chrome. The chrome never hides in the first 800 ms after a chapter opens, never while a sheet, menu or scrub is active, and never while a screen reader is on.
- **Cinema mode** (`c`, or the settings sheet): the pill hides too, after 3 s idle; a 2 px micro-progress line stays at the very bottom edge unless cinema's "Hide progress" is on.
- **Locked mode** (setting "Lock reader controls"): taps do nothing but scroll; five taps in the centre region within 2 s each unlock (a small lock glyph pulses at each tap; "Reader unlocked" toast, `medium`).

#### 4.14.3 Gestures and input

| Gesture | Behaviour |
|---|---|
| Vertical scroll | Native momentum; `BouncingScrollPhysics`; never scroll-jacked |
| Tap (strip) | Toggles chrome anywhere (default); opt-in "Tap to scroll": top third and left-middle scroll back 75 % of the viewport, bottom third and right-middle forward, centre toggles; the scroll glides on `settle` |
| Tap (paged) | Bands 30 / 40 / 30: left previous, centre chrome, right next; mirrored for RTL until the reader sets their own; each band configurable (Previous · Menu · Next) |
| Tap feedback | A soft radial light (120 px, 10 % white) blooms at the tap point and fades over 300 ms |
| Double tap | Zoom 1× ↔ 2× anchored at the tap point on `camera`; `zoomToggle` |
| Pinch | Strip: width zoom 1× to 3× keeping the focal point fixed (`offset' = (offset + focalY) × z'/z − focalY`), rubber-band beyond; paged: `InteractiveViewer` 1× to 4×; release springs with the scale velocity; `zoomLimit` at the ends |
| Pan (zoomed) | Horizontal pan enabled, edge back swipe disabled |
| Edge back swipe (iOS) | Leading 20 px strip, strip mode at 1× only; the reader slides right over the recessed series page |
| Left-edge vertical drag (12 % band) | Brightness −75 to 100 with a 6 × 140 glass HUD capsule (sun glyph; below 0 it reads "Night −40" and adds a black overlay up to 0.75); fades 600 ms after release |
| Trailing-edge drag | Scrub rail |
| Horizontal swipe (strip, opt-in "Swipe sideways to change chapter") | Direction-locked (|dx| > 2|dy|), stiffer rubber band (`c` = 0.35); the neighbour chapter's title card slides in from the side; projected past 96 px commits with `chapterCommit` |
| Pull past the end / top | §4.14.4 |
| Long-press a page (450 ms) | Page menu: Save page image (web: download; phones: share sheet), Bookmark this spot, Show dialogue (OCR text, §4.14.9), Guided view (§5.4.3), Report broken page (retries with a fresh fetch) |
| Android volume keys | Page up/down (setting, Android only) |
| Mouse wheel | Scroll; Ctrl/⌘ + wheel zooms around the pointer (a zoom chip shows the level for 1200 ms); paged mode: one page per wheel gesture with a 200 ms idle reset |
| Middle-click (desktop) | Autoscroll anchor: 12 px dead zone, 10 px/s per px of offset, max 4000 px/s |

#### 4.14.4 Chapter boundaries

- **Continuous (default):** neighbours are stitched with seams; there is no card between chapters. The next chapter's first 3 pages preload at 70 % of the current chapter; its manifest loads when within 4 pages of the end. A failed neighbour shows a seam card: "Chapter 144 didn't load" + "Try again" + "Open it on its own", retrying with back-off 2 s → 30 s.
- **One at a time** (setting): past the last page the strip **rubber-bands**; at 48 displayed px (`chapterArm`) a `glassThick` **next-chapter card** rises from the bottom like a partial sheet: the next chapter's first page as a thumbnail tilted 8° in depth (it follows the gyroscope ±4°), "Chapter 144", "42 pages · about 6 min", and a tinted "Read next"; at 72 displayed px the card locks (`chapterCommit`), and releasing **zooms** it to full screen into the next chapter. **Momentum carries through:** if the pull was a fling, the new chapter starts scrolling with the remaining velocity (the ballistic simulation continues on the new content). Pulling down past the first page does the same with the previous chapter from the top.
- **Caught up** (the last published chapter): the end card says "You're caught up" with "The source hasn't published chapter 145 yet." and, if the series is not in the library, "Add to library to hear about new chapters"; below it, the **reactions** row (§5.3.2) and **More like this** (§5.1.4).
- **Missing chapters:** when chapter numbers jump (143 → 145), the seam shows a `warning` row "Chapter 144 is missing from this source".
- **Auto next** (setting, default on): in one-at-a-time mode, reaching the end with the chrome hidden opens the next chapter after 900 ms unless the reader scrolls back.

#### 4.14.5 Reader settings sheet

Phone: sheet at `medium` (page stays visible above, changes apply live), draggable to `large`; desktop: the right side panel (§4.14.11). Sections (each setting shows its scope in `caption1`: "This series" or "All series"):

| Section | Controls |
|---|---|
| Layout | Segmented Strip · Single · Double (hidden in read-all); Direction segmented Left to right · Right to left; Fit segmented Width · Height · Original (Height and Original disabled in strip with the reason "Strip pages always fit the width"); Zoom stepper 50–300 % with a reset; Chapters segmented Continuous · One at a time; Page gap switch (strip) |
| Motion | Page transition segmented Slide · Fade · None (paged); Auto next switch; Swipe sideways to change chapter switch |
| Taps | A phone silhouette diagram with three bands; tap a band to cycle Previous · Menu · Next; "Tap to scroll" switch (strip); "Reset to automatic" plain button; a first-run overlay of the zones (three glass panes labelled Back · Menu · Next) shows for 1.5 s and fades over 1000 ms whenever the layout changes |
| Light | Brightness and Warmth as two Control-Centre fill sliders side by side (brightness −75 to 100, warmth 0 to 100 % as an `#FF8A00` overlay up to 36 % alpha); Colour segmented Normal · Sepia · Grey; Background segmented Black · Graphite (a stored "Dark" preference maps to Graphite, "AMOLED" and "Paper" to Black) |
| Ambient | Page-tinted chrome switch; Soundscape row (→ §5.4.2); Guided view row (→ §5.4.3); Cruise speed default |
| Screen | Cinema mode switch; Keep screen awake switch (phones); Refresh rate chips Auto · 30 · 60 · 90 · 120 (Android only); Volume keys turn pages switch (Android only); Lock reader controls switch; Fullscreen button (web) |
| Help | Keyboard shortcuts (web), Reset reader settings (hold-to-confirm) |

#### 4.14.6 States

- **Loading chapter:** three page-shaped skeletons (2:3, max 420 wide) with the sheen, and a `glassThin` capsule "Loading chapter 143"; after 3 s it adds "This source can be slow".
- **Error:** the object lens (`danger`) "Couldn't open this chapter" + the server message + "Try again" + "Go to series".
- **No pages:** lens "This chapter has no pages" + "Go to series".
- **Offline:** a downloaded chapter opens from the device with an "Offline" capsule in the top group; neighbours that are not downloaded show "Chapter 144 needs a connection" as the end card, with "Download next 10 when online" as a plain action that queues them.
- **Stale anchor:** toast "This chapter changed. Opened at page 17 instead of 19."
- **Rate limited:** a `warning` capsule "The source is rate-limiting; pages will keep loading" while prefetch paces itself.
- **Bookmark notices:** toast "Saved this spot · Add note" (`bookmarkSaved`; "Add note" opens a one-line note sheet that saves through the bookmark upsert), "Couldn't save that spot" (error).
- **Further ahead elsewhere:** when a progress save returns `advanced: false` (another device is further on), a toast "You're further ahead on another device: Ch 146, p. 12" with "Jump there".

#### 4.14.7 Keys (web and hardware keyboards)

`→`/`d` and `←`/`a` page by direction · `j`/`k` next/previous page · Space / Shift+Space one screen · Home/End first/last page · `h`/`l` previous/next chapter · Ctrl+Shift+←/→ chapter aliases · `g` go to page (the global `g` chords are off inside both readers) · `f` fullscreen · `c` cinema · `m` show/hide chrome · `p` cruise play/pause · `<` / `>` cruise slower/faster · `b` bookmark · `t` chapter list · `,` reader settings · `s` series page · `=`/`+`/`-`/`0` zoom · `w` strip, `v` single, `r` right-to-left paged · `o` show dialogue · `?` shortcuts · Esc closes the topmost overlay, then leaves fullscreen, then cinema, then the reader.

#### 4.14.8 Chapter list (inside the reader)

A sheet (`large` on phone; left side panel on desktop) listing the series' chapters with the current one centred and marked by a 2 px `iris500` bar, download marks, a go-to field at the top, and the Newest/Oldest control; tapping a chapter dives into it (the reader cross-fades pages; no route animation because the route stays the reader).

#### 4.14.9 Dialogue overlay

From the page menu or `o`: the page dims to 50 % and every recognised speech region (`GET /ocr/chapter` boxes) appears as a `glassThin` box (radius 6) holding its text in `callout`; tapping a box copies its text (toast "Copied"). When the reader was opened from a dialogue search result, the matched box glows with a 2 px `iris400` outline and a capsule at the bottom offers "Previous match · 2 of 5 · Next match" (`selection` per jump; the camera glides between matches on `camera`). Pages without OCR show "No dialogue has been extracted for this chapter" and, on phones with the chapter downloaded, "Extract text" (runs on-device OCR with per-page progress in the capsule).

#### 4.14.10 Reader landing (`/reader`)

A bare page: the object lens with `strip-scroll`, "Pick something to read", "Open a series from your library or a source to start reading.", primary "Go to library".

#### 4.14.11 Platform deltas

- **Desktop web:** the strip centred; a **left panel** (300 wide, `materialThick`, radius 26, inset 12) with the chapter list and page thumbnails (`t`), a **right panel** (360 wide) switching between Settings (`,`), Dialogue (`o`) and Reactions; panels slide in on `sheet` and push the strip's centre, never cover it. The bottom capsule floats at the bottom of the strip column. Hovering the scrub rail shows the magnifier at the pointer.
- **Tablet web and landscape tablets:** Double page by default in paged mode; panels overlay as sheets.
- **Mobile web:** as phone; pinch through `@use-gesture/react` 10.3.1 `usePinch` (`touch-action: pan-y` on the strip), no haptics on iOS Safari.
- **iOS:** edge swipe back; `wakelock_plus` keeps the screen on; 120 Hz.
- **Android:** predictive back scales the reader to 90 % as a glass card; volume keys; the refresh-rate pin resets on exit; `immersiveSticky`.
- **Landscape phone:** the chrome collapses to two corner capsules and a slim bottom scrub rail; the brightness band is disabled (edge swipes are the system's).
- **Coverage:** web R19, R20 RD1–RD42, A65–A73, A89; mobile S15/S19 1–41, §6a; capabilities §13, §25.

### 4.15 Novel reader

#### 4.15.1 Paper

Dark papers only (the owner's dark-only rule applies inside the book too). Text sits at 13 to 15:1, muted text at about 5.9:1.

| Paper | Background | Ink | Muted | Ink contrast | Muted contrast |
|---|---|---|---|---|---|
| **Void** (default) | `#000000` | `#D9D6D0` | `#8A877F` | 14.48 | 5.85 |
| Ink | `#0B0B0C` | `#E6E3DD` | `#8F8C86` | 15.36 | 5.87 |
| Night Paper (warm) | `#15110C` | `#E8D8BE` | `#9C8E78` | 13.42 | 5.87 |
| Dusk (cool) | `#0D1117` | `#D3DAE3` | `#8590A0` | 13.43 | 5.85 |
| Moss | `#0E130F` | `#D5DECF` | `#879384` | 13.57 | 5.84 |
| Rosewood | `#160E10` | `#EBD5D8` | `#A08A8E` | 13.62 | 5.90 |
| **Glass** | `#000000` with the book cover's ambient field at 10 % in the top 30 % of the screen | `#ECECF1` | `#8F8F99` | 17.83 | 6.56 |

A profile that stored a light paper earlier keeps its intent through the nearest dark paper: Paper, Sepia and Cream → Night Paper; Solarized light → Dusk; Soft grey → Ink; Dawn → Rosewood; Solarized dark → Dusk; Forest → Moss; Rosé Pine → Rosewood; True black → Void; Midnight → Dusk; "follow the app" → Glass.

#### 4.15.2 Layout

- **Column:** centred, width = measure (48 to 88 ch, default 68), side margins at least 20 px on phone; desktop centres the column in the content area with optional side panels.
- **Chapter header:** "CHAPTER 12" `caption1` +0.22 em in muted, title Literata at 1.55 × body `wght` 560, a 56 px rule, and "3.4k words · 14 min" in muted `mono` 12; when narration exists, a `glassThin` capsule "Listen · 14 min" (with "· saved" when the audio is on the device) sits under the rule and starts listen mode; when the audio cannot follow this text, a quiet line "Audio plays without follow-along for this chapter".
- **Body:** paragraphs per §2.2.4; first paragraph drop cap (3.1 em, 3 lines) when at least 80 characters; indents 1.3 em after the first; scene breaks centred "✦ ✦ ✦" in muted with 0.5 em tracking and 1.6 em vertical space.
- **Speaker tints:** attributed dialogue runs get their speaker's band (§2.1.5), only when the attribution's text fingerprint matches the text on screen.
- **End matter:** a 96 px rule, "END OF CHAPTER 12", the length line, a **Next** card (`surface1` on the paper, radius 20: "NEXT" `caption1`, "Chapter 13 · The Tower" Literata 20, chevron) or "You've reached the last chapter this source has published", then plain links "Previous chapter" and "Back to the book".
- **Seamless next:** pulling past the end rubber-bands; at 72 displayed px the Next card locks (`chapterCommit`) and releasing slides the next chapter up in place on `page` (the URL is replaced, the old chapter marked complete); `l` and the Next card do the same. With Auto next on, reaching the end opens the next chapter after 900 ms unless narration is playing or the reader scrolls back.
- **Further ahead elsewhere:** the same "Jump there" toast as the manga reader.

#### 4.15.3 Chrome

Tap the text column (outside a link or a tinted run) to toggle; chrome fades and blurs in and out over `materialize` (a novel reader's chrome is calmer than the manga reader's; no minimise pill).

- **Top-left:** back (to the book) + title capsule "Tower of God · Ch 12" (tap → Contents sheet).
- **Top-right glass group:** bookmark, **listen** (headphones; present only when audio exists or can be made), voices (the cast sheet), **Aa** (type and page sheet).
- **Bottom capsule:** previous chapter, "42 % · 6 min left" (`mono`; minutes from the profile's rolling reading pace, silent until two minutes of samples exist), next chapter.
- **Progress hairline:** 2 px at the very top of the screen in muted ink, always visible.
- **Offline indicator:** "Saved copy" capsule in the top-left group when reading a downloaded copy.

#### 4.15.4 Reading modes and page turns

- **Scroll** (default): one scrolling column with native momentum.
- **Paged:** CSS multi-column pagination on web (`column-width` = viewport, `column-gap` 0, the foliate-js approach) and a `PageView` over pre-laid-out pages on Flutter; tap bands 25 / 50 / 25 (plus "Both margins go forward" and a one-hand preset: left 20 % back, top 12 % menu, the rest forward).
- **Page turn physics:** **Slide** (default in paged): the page follows the finger 1:1; the turning page carries an 8 px soft shadow on its moving edge that grows with progress; release projects (past 50 % of the width → turn) and settles on `page` with the release velocity; `pageTurnNovel` on commit. **Curl** (option): a fragment shader (Flutter `FragmentProgram` `page_curl.frag`; web a WebGL canvas over a captured bitmap of the page) with curl radius `0.16 × width × (1 − p²)` where `p` is the turn progress, the back of the page in the paper colour at 92 % with the text mirrored at 6 %; the curl follows the finger's position including vertical offset (dragging from the bottom corner curls from the corner) and releases on `page`. **Fade:** 160 ms cross-fade.
- **Pinch** changes the text size one step per ×1.15 of pinch scale, `selection` per step, and reflows once on release (the text is never visually scaled).
- **Line guide** (option): frosted bands (blur 6, 55 % black) above and below the current line band; drag the band or tap above/below to move it.

#### 4.15.5 Type and page sheet (Aa)

`medium` sheet (≤ 50 % of the height, so the page updates live above it); desktop right panel.

- Face tiles "Literata" and "Sans", each set in its own face (selected: `glassThin` + ring).
- Steppers with detents: Size (15–30), Line height (1.40–2.10), Measure (48–88 ch), Paragraph spacing (0–1.2 em), Character spacing (−0.02 to +0.10 em); each step ticks and the page reflows live.
- Switches: Justify and hyphenate, Bold text, Line guide.
- Mode segmented Scroll · Paged; page turn segmented Slide · Curl · Fade (paged only).
- **Papers** as orbs (44 px circles in the paper colour with "Aa" in its ink and a specular highlight); selecting one ripples the new paper out from the orb across the whole page (a circular clip reveal on `page`, the only place a colour change is sprung, because the paper is an object being laid down).
- "Reset" plain button (per book typography back to defaults).
- Scope captions: typography "This book", paper "All books".

#### 4.15.6 Contents sheet

`large` sheet in the paper colours: "Contents" Literata 22, the go-to field (autofocus when opened from a search affordance), the list pre-scrolled to the current chapter (current row ink at 7 % fill, `wght` 600), windowed as on the book page; loading spinner; offline "The contents need a connection to load" (downloaded chapters stay listed).

#### 4.15.7 States

Loading (paper-coloured skeleton lines at varied widths with the sheen tinted to the ink at 5 %); offline (downloaded copy opens; otherwise the offline lens in the paper colours); error ("Couldn't load this chapter" + Back to the book); empty ("This chapter came through empty. The source answered with no text; the page may have been pulled or is still being published."); stale bookmark (toast "The text here changed. Opened at the nearest paragraph."); end of book; bookmark saved/failed toasts in the paper palette.

#### 4.15.8 Keys

`h`/`l` chapters · `j`/`k` or Space / Shift+Space page or screen · `=`/`+`/`-`/`0` text size · `t` type sheet · `c` contents · `b` bookmark paragraph · `p` play/pause narration · `[`/`]` previous/next sentence (narrating) · `v` voices · `?` shortcuts · Esc closes the sheet, then returns to the book.

- **Coverage:** web R21 NR1–NR19, NT1–NT7, A76–A81; mobile S26 1–23, N1, N2; capabilities §19.1–19.2.

### 4.16 Listen mode (narration with the 31 named voices)

#### 4.16.1 Mini player (bottom accessory)

In the novel reader the listen row sits 8 px above the bottom capsule; everywhere else it is the app's bottom accessory (§3.15). Content: the narrating voice's orb 32 (monogram in the voice's hue), "Ch 12 · Aurora" (`subhead`), a play/pause glass button 44, and a 2 px progress line along its bottom edge (buffered segment at 35 %). It lingers 5000 ms after the reader's chrome hides unless the user pins it (long-press → Pin). Swipe horizontally → previous/next chapter (projection past 30 % of its width, `chapterCommit`); tap → the full player; swipe down → stop narration (Undo toast).

#### 4.16.2 Full player

A sheet from the mini player (the capsule grows into the sheet on `morph`), detents `medium` (transport) and `large` (transport + sentence list):

- **Artwork:** the book plate on a glass card (radius 20) with parallax: the gyroscope tilts the art ±6 px against the card.
- **Titles:** chapter title `title2`, book title `footnote` `label2`, "Narrated by Aurora · Kade voices 3 characters" `caption1`.
- **Scrubber:** a 6 px track with the chapter's sentence boundaries as faint 1 px ticks; the thumb shows the time bubble while dragged; "5:12" and "−18:40" in `mono` at each end.
- **Transport:** back 15 s, previous sentence, **play/pause** (72 px, `glassTinted`, the screen's one tinted object), next sentence, forward 15 s.
- **Tiles** (three 72 px glass tiles): **Speed** ("1.25×"; opens the speed dial), **Voices** (the narrator's orb + "Cast of 6"; opens the cast sheet), **Sleep** ("Off" or the live countdown "12:40").
- **Save audio** (phones, in the player's ⋯ and as a trailing icon on the mini player): "Save audio to this device" → a liquid ring "Saving audio…" → "Audio saved" (tap for "Remove saved audio?" Keep / Remove) → failed "Couldn't save the audio · tap to retry" → unplayable "The saved audio can't play here · tap to save again".
- **Sentence list** (at `large`): lyrics-style, `title3` Literata, active sentence at 100 % inside a **glass lozenge** (`glassThin`, radius 12) that **morphs** from sentence to sentence (its bounds animate on `snappy`, stretching across line breaks like a droplet sliding down the text), others at 40 %; speaker tints as bands; tap a sentence to play from it. A manual scroll decouples: the list stops following and a "Back to the voice" `glassThin` capsule appears; it re-couples automatically after 4000 ms idle (in this list only).
- **Chapter boundary:** at the end, a post-play card "Next chapter in 5" with a draining ring (5 s), "Play now" (tinted) and "Cancel"; the setting "Continue to the next chapter" (default on) skips the card when off by stopping.

#### 4.16.3 Speed dial

Tap the Speed tile: a vertical glass capsule 64 × 240 rises out of the tile on `morph`. Drag up/down anywhere on it: 0.5× to 3.0× in 0.05 steps (6 px per step), labelled marks at 0.5, 1, 1.5, 2, 2.5, 3; `speedDetent` ticks every 0.25×; a **magnet at 1.0×** (values within ±0.08 are pulled to 1.0 with a `rigid(0.4)` click); past the ends it rubber-bands 12 px. The value previews live while dragging and commits on release; touch-and-hold (600 ms without moving) resets to 1.0×. Under the value, the words-per-minute equivalent in `caption1` ("≈ 190 wpm"). Preset chips beneath: 0.8 · 1 · 1.25 · 1.5 · 2. Pitch is preserved (`HTMLMediaElement.preservesPitch`; `just_audio.setSpeed`).

#### 4.16.4 Voices: the orbit and the cast

- **Voice orbit (picker):** the 31 voices as cards on a horizontal carousel with depth: the centred card at 1.0 scale, neighbours at 0.86 and 60 % opacity, receding along a gentle arc (each card's `rotateY` = 18° × its offset from centre, capped at 2 cards). Cards (160 × 220, `surface1` slab radius 26): a 72 px orb in the voice's hue with its initial, name `title3`, "Female · warm" `footnote`, a **pitch scale** (a 1-D track "deeper ↔ brighter" with a dot at the voice's `pitch_hz` position), an expressiveness meter (5 dots), "In use for Kade" tag when assigned, and the licence credit in `caption2`. Flick with momentum; the orbit snaps card by card with projection (`settle`); `voiceCentered` tick at each settle. **The centred voice auto-plays its introduction after 400 ms of rest** (`GET /novels/voices/sample`, m4a on iOS and Safari, ogg elsewhere) with its orb pulsing to the audio level; moving again stops it. A "Use this voice" tinted button under the orbit; a grid toggle switches to a searchable grid (2 columns phone, 4 desktop) with filter chips All · Female · Male · In use.
- **Cast sheet** (`large`): "Voices in this chapter", status copy ("Looking up who speaks here…", "Nobody has been identified in this chapter, so the narrator reads it all.", "Narrated by Kade: Kade's own lines use the narrator's voice because they are the same person."); the **Narrator** row pinned at top (orb, voice name or "Default voice", chevron); one row per character: speaker swatch (§2.1.5; dashed when unhued), name, assigned voice or "Automatic", share of lines ("31 %"), a lock glyph when set by hand; tap → the orbit filtered to that character's gender; owner-only ⋯ on a row: "Same character as…" (alias merge, `POST /novels/cast/alias`), "Reset to automatic". Non-owners see the rows read-only with "Voices are set by the server's owner".
- **States:** no voices installed ("No voices are installed on the server, so characters can't be cast here yet."), voice save failed (toast with the error), preview unavailable ("No preview available" on the card).

#### 4.16.5 Audiobook sheet (from the book page)

`large` sheet: "Audiobook"; segmented **Narrate · Save to device** (Save only on phones with a downloads scope); unavailable note "Narration of new chapters isn't available right now. Chapters that already have audio can still be saved."; assist chips "Next 10" (narrate), "All un-narrated (n)" / "All narrated (n)", "None"; one row per chapter with a checkbox and status ("Narrated · saved on this device", "Narrated", "Download the text first", "Not narrated yet"; save mode: "Saved on this device", "Saved copy can't play here · select to save again", "Saving…", "Couldn't be saved · select to retry"); an estimate caption ("About 45 minutes of rendering on the narration PC", 9 minutes per chapter) or "Saves while the app is open. The text is saved too, so the chapter plays and follows along offline."; primary "Make audiobook of 5 chapters" (owner; `POST /novels/audio/render`) / "Save audio of 5 chapters"; a **jobs** section with each job's progress bar (`GET /novels/audio/jobs`, polled every 5 s, 15 s while everything waits for the render PC, backing off to 60 s on failures) and an owner-only cancel ("Stops shortly"). Toasts: "Queued 5 chapters for narration. Skipped: 2 already narrated, 1 not on the server yet.", "Nothing to narrate.", "Saving the audio of 5 chapters to this device."

#### 4.16.6 Sleep timer

A menu blooming from the Sleep tile: Off · 5 · 10 · 15 · 30 · 45 · 60 min · End of chapter · End of next chapter · Custom (a minutes stepper). The volume fades over the last 8 s. **Shake to extend +5 min** on phones (accelerometer through `sensors_plus` 7.1.0; threshold 2.2 g over 300 ms; `selection` + toast "Sleep timer +5 min"), off by default with a switch in the menu.

#### 4.16.7 Highlight-as-read

The active sentence gets a band at 14 % of its speaker's tint (narration uses `iris500`), radius 6, padding 2 × 4; the band **slides** between sentences on `snappy` instead of cross-fading; the current word brightens to full ink with a 2 px underline in the tint (stepping, not animated). Follow keeps the active sentence at 38 % of the viewport height and scrolls on `settle` only when it leaves the 20–70 % band; it jumps (120 ms cross-fade) when more than two viewports away. A manual scroll decouples and shows "Back to the voice" (no automatic return on the page). When the timing map does not match the text on screen (`highlight_safe` false or a changed fingerprint), nothing is highlighted and a quiet capsule says "Highlight paused: the text changed".

#### 4.16.8 States

No audio (the listen button is hidden; owners on the book page see "Make audiobook"); preparing (`503 audio_preparing`: the play button shows a liquid ring and "Preparing audio", retrying every 3 s); failed ("Audio couldn't load" + Retry, `error`); offline with saved audio (plays, "Saved audio" tag); offline without (play disabled, reason "Needs a connection or saved audio"); narration unavailable on the server.

- **Keys:** `p` play/pause, `[`/`]` previous/next sentence, Shift+`[`/`]` back/forward 15 s, `<`/`>` speed −/+ 0.05, `v` voices, Esc collapses the player.
- **Coverage:** web NR9–NR15, A82–A86; mobile S26 3–4, 8, 15–16, N3, N4; capabilities §19.3–19.4; reader-ux §4.12.

### 4.17 Library (shelf and browse all)

- **Layout, phone:** tab root. Nav row: profile orb, content-mode capsule, trailing group: Select, ⋯ (Sort, Density, Show filters). Large title "Library" with the count line "142 series followed" (novels: "38 books on your shelf"). **In-page tabs** (a swipeable pager): **Shelf · Collections · History · Bookmarks · Downloads**. The Shelf panel: a "Continue" rail of continue stacks (up to 12), a toolbar that pins under the nav row (search well "Search your library", filter chips All · Reading · Not started · Completed · ★ Favourites, a "Filters" chip opening a sheet with Shelf status: Any, Unread, Reading, Completed, On hold, Plan to read, Dropped, **Tags** as multi-select colour chips, and "Clear filters"), then the grid. The ⋯ menu also holds "Manage tags" (a list of tags; swipe left or ⋯ → Delete opens an alert "Delete this tag? It is removed from every series." with a destructive confirm, `DELETE /library/tags/{id}`).
- **Grid:** Comfortable (3 columns on a 390 px phone), Compact (4 columns, title only), or List (rows with a 64 px square cover, title + status tag, meta, favourite and follow buttons). **Pinch the grid to change density** (2 ↔ 3 ↔ 4 ↔ 5 columns and List below 2): during the pinch the grid scales continuously around the focal point; on release it snaps to the nearest column count and reflows on `snappy` (items travel to their new cells from their scaled positions), `segmentChange` per step. The Density menu and a slider in the ⋯ menu are the non-gesture path.
- **Poster overlays:** status tag, "N new", favourite star (always visible when favourited; appears on hover or long-press otherwise), follow bell (hover on desktop, context menu on touch), downloaded mark.
- **Browse all** (`/library/browse`): the same panel with the toolbar expanded and filters written to the URL (`?search=&sort=&status=&reading_status=&is_favorite=`); a note "Showing the first 200 of 412. Narrow it with search or a filter." when capped. Sort menu: Recently updated, Recently added, Title, Manual order (drag to reorder, which writes `sort_order`).
- **Novels mode:** the grid becomes the book shelf (rows with book plates, Literata titles, byline, blurb, genres, note).
- **Layout, desktop:** the Library sidebar item expands to its five children; the Shelf page has the toolbar row (search, chips, sort menu, density segmented control Comfortable · Compact · List) and a 6 (1024) to 10 (1920) column grid; hovering a poster reveals the follow bell and favourite star as `glassThin` 32 px buttons at its top corners; Shift-click selects ranges.
- **Signature moment:** the density pinch (above); and when an update check finds chapters while the Library is open, the affected posters' "N new" badges pop (`tick`) in a wave from the top.
- **Select mode:** the bulk toolbar (§3.35) with Favourite, Unfavourite, Mark read, Mark unread, Add to collection, Download next 10, Remove from library (with Undo; no confirm, because Undo restores follows with their favourite, status, notify and override).
- **Transitions:** tab root cross-fade; zoom into detail; the pager slides between sections.
- **Gestures:** pull to refresh, pinch density, long-press lift (context menu: Continue, Details, Favourite, Mark read, Add to collection, Download next 10, Previously on, Recommend to…, Remove from library), select-mode painting.
- **States:** loading (count bar + 12 poster skeletons); offline (follows from the device cache with the "Offline" capsule; posters without downloaded chapters dim to 70 %); error ("Couldn't load your library" + Try again); empty ("Your shelf is empty" / "Follow series from Sources to build your shelf." + "Browse sources"; novels: "Add a book from a novel source to start your shelf"); empty search ("No results for “{q}”" + Clear search); empty filter ("No series match these filters" + Clear filters); bulk running and results (toolbar).
- **Keys:** `/` search, arrows and `h j k l` through the grid, Home/End, Enter opens, `x` select, `shift+x` range, `*` favourite, `m` mark read, `alt+arrows` reorder (manual order), `[`/`]` sections.
- **Coverage:** web R5 LS1–LS12 (shelf), R6 LB1–LB26, BA1–BA10, A25–A36; mobile S08 (followed grid, novel shelf, long-press M1 sheet → context menu), S09 1–21; capabilities §7–8.

### 4.18 Collections and collection detail

**Collections** (Library section / `/library/collections`):

- **Layout:** count line ("6 collections" or "Group your series by theme, mood or reading list."), nav row "+" (New collection), search well (when at least one exists), sort menu (Name A–Z, Most series, Recently created, Custom order with drag), then **collection cards** (§3.7: fanned stacks of the first four member covers), 1 column on phone, 2 to 3 on desktop. Shared collections (§5.3.3) carry a friend-orb badge and "Shared with Aarav".
- **New collection:** a `medium` sheet (desktop window) with Name ("My reading list"), Description (optional), "Share with friends" switch (only when social is on), error line, primary "Create". The new card drops into the list on `celebrate`.
- **Signature moment:** tapping a card **fans** its stack open (the four covers spread to 0°, ±12°, ±24° on `celebrate`) as the collection zooms open, and the fanned covers become the header of the detail page.
- **States:** loading (4 card skeletons); offline; error; empty ("No collections yet" + "Create your first collection"); no match ("No collections match your search").
- **Keys:** `/` search collections, `n` new collection, arrows and Enter through the cards, `alt+↑/↓` reorders in Custom order.
- **Coverage:** web R8 CO1–CO10, A44–A45; mobile S24 1–12.

**Collection detail** (`/library/collections/:id`):

- **Layout:** header band 220 px: the fanned covers enlarged over the collection's ambient field, name `largeTitle`, description `callout`, "12 series"; action row: "Add series" (secondary), Edit (icon), Share toggle (icon, social), ⋯ (Delete collection: hold-to-confirm "The series stay in your library."). Member grid (as Library; titles joined from the library payload); reorder by drag (the collection's member `sort_order`).
- **Add series:** a `large` sheet with a search well and the followed series not already in it (36 × 54 cover + title), tapping one adds it with a fly-into-the-header motion (the cover arcs into the fanned stack) and keeps the sheet open for more; "No series available"; "No series match your search".
- **Remove:** context menu "Remove from collection" or select mode, with Undo toast ("Removed from Weekend reads · Undo"); orphans (no longer followed) show "No longer in your library".
- **States:** loading (header skeleton + 6 posters); empty ("This collection is empty" + "Add series"); mode mismatch ("No novels in this collection" / "It holds titles from the other mode. Switch modes to see them."); error (+ Back to collections).
- **Keys:** `a` add series, `e` edit, arrows through the grid, `Delete` removes the focused member (with Undo).
- **Coverage:** web R9 CD1–CD12, A46–A50; mobile S25 1–13; M8.

### 4.19 History

- **Layout:** Library section (phone) / page (desktop): a segmented **By series · Timeline** (by series: `collapse=series`, one tile per book; timeline: `collapse=none`, one row per chapter read); day headers ("Today", "Yesterday", "This week", "Earlier") in `footnote` uppercase; a grid of **history tiles** (§3.7) with a 3 px progress line, the play orb ("p. 18" or "42 %"), and for finished chapters a "Next" orb that resolves the next chapter (fetching the chapter list, `aria-busy` while resolving; falls back to the series page). Titles fall back to "Unknown series" in `label3`. 50 per page with a "Load more" row (offset paging).
- **Gestures:** tap the tile → series detail (zoom); tap the orb → the reader at the saved spot (dive); long-press → Continue, Open series, Mark finished, Recommend to…; pull to refresh.
- **States:** loading (10 tile skeletons); offline ("Reading history needs a connection" with the device's recent reads from local progress listed below it); error; empty ("Nothing read yet" / "Open a chapter and it will appear here as you go." + "Go to library").
- **Keys:** arrows, Enter (series), `c` continue the focused item, `n` next chapter.
- **Coverage:** web R10 RH1–RH5, A38–A39; mobile S13 1–8.

### 4.20 Bookmarks

- **Layout:** plain list of bookmark rows: cover 44 × 66, series title `headline`, position line "Ch 12 · Page 7" (manga) or "Ch 3 · Paragraph 118 · 62 %" (novel) with a strip or book glyph, the novel snippet (Literata italic 15, 2 lines), the note when present, "Saved 28 Sep, 21:41" `caption1`, and a stale note in `warning` ("The text here changed; this opens at the nearest spot."). Content mode filters the list.
- **Gestures:** tap → dive into the reader at the anchor; swipe left → Remove (Undo re-creates the bookmark at the same anchor); long-press → Open, Add note, Remove, Copy link.
- **Offline:** phones read the local store and sync through the bookmark outbox; a pending sync shows a small "Syncing" capsule.
- **States:** loading (5 row skeletons); offline (local bookmarks listed; server-only ones noted); error; empty ("No bookmarks yet" / "Press B while reading, or use the bookmark button, to save the exact spot." + "Go to library").
- **Keys:** arrows, Enter, `Delete` (with Undo), `u` undo.
- **Coverage:** web R11 BM1–BM5, A104–A105; mobile S14 1–8; capabilities §15.

### 4.21 Updates

- **Layout:** pushed from the Home bell (phone) or the sidebar (desktop). Large title "Updates", line "5 unread · 142 followed"; nav row trailing: **Check now** (refresh glyph; while a run is in progress it becomes a liquid ring and the line reads "Checking 142 series…"), ⋯ (Mark all read, Mark all manga read, Mark all novels read, Update settings (admin)). Segmented **All · Unread · Followed**.
- **Summary row** (tap → Settings → Notifications for admins; an info popover for others): "Checking every 30 min · last check 12 min ago · notifications on".
- **Notifications:** one card per series (§3.7): cover, title, "3 new · Ch 141–143", time, chapter chips (each opens the reader and marks that notification read); unread cards carry an `iris400` dot and a 2 px leading bar; read cards at 70 %.
- **Followed** segment: rows with title, source capsule, "412 chapters" or "Not checked yet", a notify bell toggle, swipe left or ⋯ → Unfollow (with Undo), ⋯ → Check this series now.
- **Admin:** a "Recent checks" section: rows "Scheduled · completed · 142 series · 5 new" + start time, and failures with the error in a `mono` block.
- **Signature moment:** when a check finds chapters, new cards **drop in** from the top with the wave, the Home bell swings (§2.8), and the global capsule shows for other screens.
- **Gestures:** pull to refresh (runs Check now), swipe right on a card → Mark read, swipe left → Open series; long-press → Mark read, Open series, Turn off notifications for this series.
- **States:** loading (3 card skeletons); offline ("Updates need a connection to check"); error ("Couldn't load notifications" + Try again); check already running (toast "A check is already running"); empty ("No new chapters yet" / "Follow a series and this fills in the moment a new chapter is found." + "Browse sources"); all read ("You're caught up" lens with a small check droplet); rate limited.
- **Keys:** `r` check now, `m` mark the focused card read, `shift+m` mark all read, arrows, Enter.
- **Coverage:** web R22 UP1–UP8, A96–A103, A108; mobile S23 1–13; G39; capabilities §21.

### 4.22 Downloads

- **Layout, phone:** Library section and `/downloads`. Header "On this device" `caption1` + "Downloads" large title; in-page tabs **Chapters · Queue · Storage**. No pull to refresh (local data).
- **Storage meter** (top of Chapters): a **liquid capsule** 44 tall split into this profile's downloads (`iris600` at 60 %), other app data (frosted `fill2`), and free space (clear), with the cap as a vertical 1 px marker and a label "1.2 GB of 10 GB"; values slosh into place on `lens` when they change.
- **Chapters tab:** the OCR run banner (phones: "Extracting text · page 3 of 40" with a bar, paused "Text extraction pauses while the app is in the background", uploading, done "Text extracted: 2,140 words are now searchable", cancelled, failed; Cancel while busy); the "Where it lives" note (iOS: "Downloaded chapters live inside ManhwaManiacs. For a copy you can open elsewhere, use Save to Files."); then one **series card** per series, biggest first: title (links to the series), "40 chapters · 3 with audio · 1.2 GB" or "12 of 40 chapters saved · 800 MB", a pin toggle (pinned series are exempt from auto-delete), ⋯ (Save to Files…, Remove all downloads: hold-to-confirm), expand chevron; expanded: chapter rows with a status line in its tone ("40 pages · 24 MB", "Saving 18/40", "Incomplete · 38/40 pages", "Paused: device is full", "Pages changed on the server · save again", "Deletes in about 2 days", "Open now, kept"), a progress bar while saving, OCR button (manga, phones: "Extract text" / "Text extracted · redo"), Save to Files (phones), remove (swipe left; the toast "Removed from this device" offers "Download again", which re-queues it, because deleted files cannot be restored instantly).
- **Queue tab (phones):** the active panel: "Downloading" / "Waiting to start" / "Paused" with pause/resume and cancel-all (alert "Cancel all downloads? Everything queued, downloading or failed is dropped. Finished chapters stay." Keep them / Cancel all); the current chapter block (series, "Chapter 12 · page 18 of 40", a 6 px liquid bar, "2 more chapters downloading alongside", "12 of 40 saved in this series"); pause reasons with actions ("Paused by you" + Resume; "Paused while ManhwaManiacs was in the background", which clears itself on return; "Paused: this phone is almost full. Downloads stop before the last 1.5 GB." ; "Paused: downloads filled your 10 GB limit." + "Storage settings"); queue rows (queued / downloading / failed with the error), each with retry and remove, reorderable by drag (priority); the foreground note "Downloads run while ManhwaManiacs is open; leaving pauses them and coming back picks up where they stopped."
- **Storage tab (phones):** usage line; cap chips 2 GB · 5 GB · 10 GB · 20 GB · Unlimited; "Chapters at once" chips 1 · 2 · 3; "Delete after reading" chips Off · 24 h · 48 h · 7 days; platform note (iOS: "Browse, copy or delete downloads in the Files app: On My iPhone → ManhwaManiacs"; Android: "Downloads live in the app's private storage"); "By series" breakdown rows (pin glyph for pinned, "12 ch · 240 MB"); "Free up space" (removes read chapters past the retention; toast "Removed 8 chapters" or "Nothing to free up right now"); **Image cache** card (size, "Clear image cache") and **Metadata cache** card ("Clear metadata cache").
- **Web:** tabs Chapters · Storage; Storage shows the browser quota ("380 MB of 4.2 GB used by this site · 3.8 GB free" or "This browser doesn't report a storage quota"), the explainer ("Saving stops before the last 250 MB of the quota. When it gets close, finished chapters are removed oldest first; never one you haven't read, and never the one you have open."), **Protect storage** (success capsule "Storage protected" or secondary "Ask to protect storage" → `navigator.storage.persist()`), retention chips 2 days · 7 days · 30 days · Never, "Remove all downloads" (hold), "Reset offline storage" (hold; unregisters the service worker and clears caches) with its explainer; an "Offline: only saved chapters open" capsule when offline.
- **Save to Files (phones):** a `medium` sheet: "Page images" ("A numbered folder per chapter") or "CBZ file" ("One file per chapter, for comic reader apps"); a progress alert "Saving to Files…"; a result alert "Saved to Files · 12 chapters · 480 pages" with the selectable path and a skipped count; toasts "Nothing to save yet: these chapters are still downloading", "Couldn't save to Files. Check your free space."
- **Signature moment:** removing a series **drains** its segment out of the liquid meter (the fill level falls with a meniscus wobble on `lens`) while its card collapses on `dismiss`.
- **States:** no profile ("Downloads belong to a profile" + Choose a profile); unsupported (web without a service worker or on an insecure origin: "Downloads are unavailable here"); checking ("Checking what's stored…"); empty ("Nothing downloaded yet" / "No series downloaded yet" / "No books downloaded yet" + "Go to library"); error ("Couldn't read downloads").
- **Keys:** arrows, `Delete` (removes, with "Download again" in the toast), `p` pin series, `space` pause/resume the queue (Queue tab).
- **Coverage:** web R23 DL1–DL9, A90–A95; mobile S21 1–40, S32 1–4, M5, §6c; capabilities §24.

### 4.23 Dialogue search (OCR)

- **Layout:** large title "Dialogue search", subtitle "Search what characters said across the series you follow, and jump to the page."; the search field (autofocus, 350 ms debounce); results: cards with the series cover 44 × 66 and title (joined from the library), "Ch 12", the snippet with highlighted terms (`iris600` at 30 % behind `label1`), "212 words · Vision" `caption1`; "Showing the first 20 of 86 matches" + "Load more".
- **Signature moment:** opening a result **finds the page**: the reader dives in at the chapter, fetches the chapter's OCR pages, glides the strip on `camera` to the page containing the match, and the matched speech box glows (§4.14.9) with "Match 1 of 3" navigation.
- **Novels mode:** the object lens "Dialogue search is for manga" / "Switch to Manga to use it." + "Search novel text instead" (→ Search with the Novel text scope).
- **Phones:** a hint row "Only chapters with extracted text can be searched. Extract text from downloaded chapters in Downloads." with a link.
- **States:** idle lens (`bubble-search`: "Search the dialogue you remember" / "Type at least one word."); loading (3 card skeletons); error ("Search failed: check your connection"); empty ("No dialogue matches" / "Nothing found for “{q}” in the chapters you follow."); offline.
- **Keys:** `/` focus, `↓` into results, Enter opens.
- **Coverage:** web R24 OC1–OC8, A106; mobile S27 1–7; capabilities §20.

### 4.24 You (hub, phone) and About

- **Layout, phone:** tab root `/you` (`/more` redirects here). A profile block: orb 72, name `title1`, "@yash · Administrator" `footnote`, secondary "Switch profile" (the orb flies to the picker), content-mode switch. Cards: **Reading** (streak flame mini, "This week: 3 h 12 min · 14 chapters", a 7-day sparkline → Statistics), **Your {year} in chapters** (visible 1 December to 31 January and on demand from Statistics → Wrapped), **Activity** (the last three friend items → Activity; hidden when social is off for this profile). Grouped lists: **Library**: Updates (count), For you, Dialogue search (manga mode), Collections, History, Bookmarks, Downloads (count); **Settings**: Appearance and skin, Reader, Content (18+), Sound and haptics, Notifications (admin), Security, Storage, Backup (admin), Server (phones), Diagnostics, Shortcuts (web, tablets with keyboards); **Administration** (admin): System status, Members; **About**: What's New, version "ManhwaManiacs 3.5.0 (57)", update row (Android APK "Update available · 3.5.1" / "Up to date"; iOS "Managed by SideStore"), Licences; **Sign out** (destructive plain, alert "Sign out? You'll need to sign in again on this device.").
- **Desktop:** `/you` redirects to `/settings`; its cards live in the sidebar (Stats, Activity) and the profile menu.
- **Signature moment:** the profile orb here is the same object as the dock's You tab icon: arriving on the tab, the tab's orb lifts out of the dock and lands in the profile block on `zoom` (only the first time per session; afterwards a cross-fade).
- **States:** loading (profile block skeleton), offline (settings still open; server-backed rows show the offline capsule), error per card.
- **Coverage:** web R25 M1–M6; mobile S22 1–18, G8, G9.

### 4.25 Settings

- **Layout, phone:** pushed page "Settings" with a search well (a full-screen overlay filters about 40 indexed settings by label and keywords, tapping a result opens its section and flashes the row), then grouped lists per section, each opening a sub-page. **Desktop:** a 240 px section list at left (inside the content column, not the sidebar) and the section panel at right; `↑`/`↓` move between sections.
- Rows use §3.17 anatomy with 30 px icon tiles in the section's colour.
- **Quick links** (desktop, under the section list): Reading history, and System status for admins.
- **Keys:** `/` searches settings, `↑`/`↓` move between sections, Enter opens a section, Esc returns to the section list.
- **Footnote:** "Settings save as you change them. Switching skin restarts the app."
- Sections the server does not offer (the `capabilities` flags on `GET /settings`) are hidden, and profile-scoped sections show the notice "Choose a profile first" with a link and disabled controls when no profile is active.

#### 4.25.1 Appearance and skin

- **Skin:** two large preview cards side by side (phone: stacked), each playing its skin's looping animated WebP, name in `title2` ("Glass", "Cinematic"), a one-line character ("Liquid glass, springs and depth." / "Dark cinema, posters and title cards."), and a "Current" tag on the active one. Choosing the other card starts the switch flow (§4.25.2).
- **Solid glass:** switch (forces the Reduce Transparency look on every platform).
- **Reduce motion in this app:** switch (forces the Reduce Motion rules regardless of the OS).
- **Light follows the device:** switch (gyroscope specular and hero tilt; off freezes the light at 135°).
- **App icon follows the skin:** switch (phones; default on).

#### 4.25.2 The skin switch and restart flow

1. **Choose:** tapping the Cinematic card lifts it (`morph`) into a confirm sheet (`medium`): its preview large, "Restart into Cinematic?", "Everything changes: layout, navigation, type and motion. Your library, progress and downloads stay. The app restarts and comes back to this screen." plus, when downloads are queued, "Downloads resume after the restart."
2. **Confirm by holding:** a **hold-to-confirm** button "Hold to restart" (1200 ms, `holdRamp`), and a plain "Stay in Glass". Keyboard and screen readers get an explicit "Restart now" button.
3. **Persist:** `PATCH /profiles/{id} { skin: "cinematic" }` (queued in the offline outbox on phones), then the device mirror (web cookie `mm-skin`, `sessionStorage['mm.skin.return']` = current path; phones `mm.skin.active` and `mm.skin.return`), web posts `skin-changed` to the service worker.
4. **Outgoing (Glass's own exit, the "melt"):** `skinSwitch` haptic; every glass surface dematerialises at once (lensing out over 350 ms), the content blurs 0 → 40 px on `page`, and a single droplet contracts from the edges to the centre of the screen (a circular mask closing on `page`, 520 ms), leaving black.
5. **Restart:** web `location.replace(returnPath)`; phones `AppRestart.of(context).restart()`; budget under 1.5 s from the hold completing to the new skin's splash.
6. **Incoming:** the new skin's own splash and reveal, landing on the same route, and its 10 s "Switched to Cinematic · Undo" toast (drawn by that skin).
- **Arriving into Glass** (from the other skin): Glass plays the full Droplet reveal (§7.4), lands on the return route, and shows the Undo toast: "Switched to Glass · Undo" with the 10 s draining rim; Undo runs this same flow back without the confirm.
- **Profile switch into a profile whose skin differs:** steps 3 to 6 run inside the profile hand-off (§4.5) with no confirm and no Undo.

#### 4.25.3 Reader defaults

Direction (Left to right · Right to left · Vertical), Fit (Width · Height · Screen), Tap zones (the diagram from §4.14.5), Chapters (Continuous · One at a time), Page gap, Cinema mode by default, Keep screen awake (phones), Auto next chapter, Lock reader controls ("Tap the centre 5 times to unlock"), Volume keys turn pages (Android), Refresh rate (Android: Auto · 30 · 60 · 90 · 120, "Auto uses the highest rate your screen supports"), Cruise default speed, "Reset reader settings" (hold-to-confirm; toast "Reader settings reset").

#### 4.25.4 Content

The 18+ switch and flow (§3.25); the blocked state without a profile.

#### 4.25.5 Sound and haptics

Haptics switch (default on) with a "Feel it" row that plays `selection`, `soft`, `rigid` and `success` in sequence; UI sounds switch (default **off**) with a volume slider (−24 to 0 dB, default −6) and a "Hear it" row; Soundscape default (Off · Rain · Wind · Ocean · Hearth · Stream · Deep, §5.4.2) and its volume.

#### 4.25.6 Notifications (admin)

- A schedule strip: three cells "Last check 12 min ago", "Next check in 18 min" (`warning` "Overdue by 7 min" with "See System status"), "Every 30 min".
- Switches: "Check for new chapters automatically" ("Nothing is checked and nothing notifies while this is off."), "Check when the server starts", "Notify me about new chapters" ("The master switch. Turn one series off from its own page.").
- Interval slider 5 to 120 min in steps of 5 with detent ticks and a magnet at 30.
- "Source catalogue cache" stepper (5 to 1,440 min, default from the server; `source_cache_ttl_minutes`), with the helper "How long a browsed catalogue is reused before asking the source again."
- Draft then save: edits collect in a floating glass bar "Unsaved changes" with "Discard" and a tinted "Save"; saved → toast "Saved"; error inline.
- States: loading (5 row skeletons), error + Try again.

#### 4.25.7 Security

- **Change password:** Current, New ("At least 8 characters"), Confirm; errors ("Enter your current password", "Enter a new password", "At least 8 characters", "Password is too long", "The new passwords don't match", "Your new password must be different"); primary "Change password"; success toast "Password changed. Your other devices were signed out; this one stays signed in."
- **Where you're signed in:** refresh icon (spins while refreshing), rows: device glyph, label ("ManhwaManiacs app", "Safari on macOS", "Unknown device"), "This device" tag, "Last used 3 h ago · 10.0.0.2", "Signed in 12 Sep · expires 11 Dec"; swipe left or ⋯ → "Sign out this device" (alert); the current device → "Sign out" (alert).
- **Sign out everywhere:** a `danger` inline notice ("Every device, including this one, will have to sign in again. Downloaded chapters stay.") and a hold-to-confirm "Sign out everywhere"; the alert path has the acknowledgement switch "I understand this signs me out here too".
- States: sessions loading, error, empty ("No active sessions").

#### 4.25.8 Members (admin)

- **Phone:** rows per account: "@aarav", tags Admin · You · Deactivated, "Joined 27 Jul · last seen 2 h ago · 2 sessions" (or "Never signed in"), actions in ⋯ and as swipe: Deactivate / Reactivate, Delete (hold-to-confirm alert "Delete @aarav? This removes their profiles, library, progress, bookmarks and everything else they own. It can't be undone."); the owner's own row has actions disabled with "You can't deactivate or delete your own account".
- **Desktop:** a table (min 640 px, in its own horizontal-scroll container) with columns Member, Status, Joined, Last seen, Sessions, Actions; own row tinted `iris600` at 6 %.
- An explainer above the list: "Registration is open on this server. Deactivating keeps an account's data and signs it out everywhere; deleting removes the account and everything it owns."
- Footer "2 other accounts" + Refresh. States: loading (3 row skeletons), error, empty ("Only your account so far").

#### 4.25.9 Storage

Phones: opens the Downloads Storage tab (§4.22). Web: opens Downloads → Storage.

#### 4.25.10 Backup and restore (admin)

- **Nightly backup card:** "Last nightly backup: 03:10 · 42 MB · OK" (`success`) or "Unknown" (`warning`; unknown is never shown as healthy) from `GET /backup/status`, polled every 30 s.
- **Restore staged banner:** `warning` inline notice "A restore is staged and applies when the server restarts." + "Cancel staged restore".
- **Export:** explainer (the whole database, every account; keep it private), primary "Export backup" ("Preparing…"; web downloads the file, phones open the export in the browser), "Saved manhwamaniacs-2026-09-28.db" confirmation.
- **Restore:** a `danger`-barred section: explainer (replaces everything, applies on the next restart, nothing is kept), "Choose backup file" (`.db` only; errors "That isn't a .db file", "That file is empty"), the chosen file's name and size, and "Restore from this file…" which opens an alert with the four consequences as bullets, a field "Type RESTORE to confirm" (case-insensitive) and a destructive "Restore" (enabled once the phrase matches); success alert "Restore staged. Restart the server to finish."
- **Members** link (desktop places Members under this section too).

#### 4.25.11 Server (phones)

"API base URL" field, "Save" (toast "Server URL saved and applied", or the validation error: https required), "Reset to default" (toast "Reset to the default address"), loading and error states.

#### 4.25.12 Diagnostics

Rendering performance (FPS in `iris400`, Jank % coloured success < 5, warning < 15, danger above, Worst frame ms), frame rows (average frame, CPU build, GPU raster, samples; "Starting profiler…", "Scroll a screen to sample"), Display (Android: current refresh rate, capability, resolution; iOS: "Display modes are only switchable on Android"), Device (platform, CPU cores, screen, app version, build mode), Image cache (live, cached n / max, memory), and Glass: "Renderer: Impeller", "Glass quality: premium (chrome) · standard (in lists)", "Refraction: on" or "frosted".

#### 4.25.13 Shortcuts (web and hardware keyboards)

The live registry grouped (General, Navigation, Library, Search, Sources, Reader, Novel reader, Listen), each row a description and keycaps; the **Single-key shortcuts** switch; "No shortcuts are active on this screen" when empty.

#### 4.25.14 Account, language and about

- **Account:** orb, display name, "@username", Admin tag; "Password and security" row; "Profiles" row (→ Manage profiles); "Sign out" (alert).
- **App language:** English, Español, Français, Deutsch, 日本語, 한국어; saved per device; the interface text is English in every choice.
- **About:** app card ("ManhwaManiacs", "A self-hosted manga, manhwa and web-novel reader", version and build), updates (Android APK: "Up to date · 3.5.0" / "Update available · 3.5.0 → 3.5.1" + "Download update" → the install-steps alert; iOS: "Managed by SideStore" with the source URL, "Copy source URL", the 7-day signature note), What's New, open-source licences (a searchable list, not the stock page), "Reset reader settings".
- **Coverage (all of §4.25):** web R26 SG1–SG40, BK1–BK5, MB1–MB7, K1–K51, A5–A9, A17–A24, A107, A112–A118; mobile S28 1–27, S29–S34; the palette and preset pickers become the skin picker.

### 4.26 System status (admin)

- **Layout:** large title "System status" with the eyebrow "Administration"; nav row "Refresh" (spins while refreshing); a **summary banner** tinted by the worst state (ok `success`, warn `warning`, down `danger`, unknown `g600`) with its glyph, headline ("Everything is running", "2 problems need attention") and a bullet list of problems.
- **Cards:** Backend (state capsule Healthy · Warning · Down · Unknown with a live dot that pulses once on each successful 15 s poll: scale 1 → 1.3 → 1 on `tick`; name; version `mono`; "Probe GET /health"); Update checker (Check now secondary; last run + "12 min ago"; next run + "in 40 min"; interval; failed runs in `danger` when above 0; the server error in a `mono` block); Recent checks (up to 8 runs: status tag, trigger, "142 series · 5 new", time, errors); Source health (rows: state glyph, name, id `mono`, "demoted" `warning` tag, "last probe 3 min ago", message, last error in a `mono` block; 30 s poll); footer note "Everything here reads endpoints that already exist; nothing on this page changes the server except Check now."
- **Non-admin:** the object lens "Administrators only" / "System status is instance-wide. Ask the account owner to check it." + "Back home".
- **States:** loading (a bar while `/auth/me` resolves, then card skeletons), per-card errors, offline.
- **Keys:** `r` refresh all, `c` check now, arrows through the source-health rows.
- **Coverage:** web R27 AS1–AS10, A100, A108–A111.

### 4.27 For you, Statistics, Activity and Wrapped

These four screens are the new features and are specified in full in §5: For you and Ask (`/library/recommendations`) in §5.1.2, Statistics (`/library/statistics`) in §5.2.1, Wrapped (`/wrapped/:year`) in §5.2.3, Activity (`/activity`) in §5.3.1. Inventory coverage: web R12 RC1–RC11, R13 ST1–ST13, A40–A43; mobile S11 1–20, S12 1–17.

### 4.28 Status screens

- **404** (inside the app frame): the object lens with a question glyph drifting slowly, "Nothing here", "This page doesn't exist. It may have been renamed, or the series it pointed to may have left your library.", primary "Back home", secondary "Open library", and the hint "Press ⌘K to search everything" (desktop).
- **Route error:** two variants: "Something broke" / "This page failed while rendering. Nothing was lost; trying again usually works." and "Can't reach the server" / "The server didn't answer. It may be starting up, or the connection dropped. Your library is untouched."; "Reference {digest}" in a `mono` capsule; "Try again" (tinted) and "Back home". The lens drops in on `lens` with `errorShake` haptic once.
- **Root error** (replaces the document, no fonts, no providers): self-contained HTML and CSS: black background, `system-ui` font stack, a CSS-only droplet lens (a radial-gradient circle with a 1 px rim), "ManhwaManiacs failed to start", "Reloading usually clears it. If it doesn't, check the server or the running build.", buttons "Try again" and "Reload the app".
- **Offline fallback** (`/offline-fallback.html`, served by the service worker when a navigation fails offline): one static file carrying both skins' CSS; a four-line inline script reads the `mm-skin` cookie and sets `data-skin`, so Glass users see the Glass version: the inline SVG mark in a CSS glass lens, a live status capsule ("No connection" `warning` / "Back online" `success`, updated by `online`/`offline` events), "This page needs the server", "Chapters you downloaded are still on this device and open as normal.", buttons "Try again" and "Downloads", and the note "This page is served from your device."
- **Keys:** on every status screen Enter activates the primary action and `mod+k` still opens the palette (except the root error and the offline page, which have no app around them).
- **Coverage:** web S1–S5, E1–E4, G12 (skip link: "Skip to content" `glassThin` capsule that appears top-left on focus).

### 4.29 Global overlays

| Overlay | Glass treatment |
|---|---|
| Command palette | §3.28 |
| Keyboard shortcuts (`?`) | `glassThick` window 560 wide (phone with a keyboard: `large` sheet): "Keyboard shortcuts", intro "Only what works here is listed. Shortcuts pause while you type. Press ? to reopen, Esc to close.", groups with keycaps (secondary combos at 80 %), empty "No shortcuts are active on this screen" |
| New chapters | The global capsule (§3.30); tapping "View" opens Updates |
| App update (web service worker) | Capsule "A new version is ready" + "Reload" (posts `skip-waiting` then reloads) |
| App update (Android APK) | Capsule "Update available · 3.5.1" → a `medium` sheet: installed and available versions, "Download update", notes ("Downloading doesn't install automatically", "Updating from 1.2.x? Uninstall version 1.2 first"), then the install-steps alert with three numbered droplets |
| What's New | Shown once after an update (build number increased) and from About: a `large` sheet "What's new" / "Recent improvements", release cards (`surface1`, radius 20): version capsule in `iris400`, "Latest" tag, "28 Sep · build 57", bullets with droplet markers; loading spinner; "Release notes are unavailable" lens |
| First-run hint | Replaced by onboarding (§4.7) and Home's new-profile state |
| Bookmark notice | Toast (§3.12) |
| Skip link | "Skip to content", `glassThin` capsule top-left on focus |

Coverage: web G39–G42, CP1–CP12, the shortcuts dialog of web.md §2.9, G12; mobile G8, G9.

---

## 5. The four new features

All four are designed server-first (`stack-decision.md` §2.6): the backend computes AI results, statistics, streaks, the social feed with its per-profile and 18+ filtering, palettes and panel boxes; each client only renders. Endpoints marked **new** are the additions this concept needs; everything else exists (`capabilities.md`).

### 5.1 AI home, recommendations and "Previously on"

#### 5.1.1 AI rails on Home

| Rail | Source | Label and `why` |
|---|---|---|
| Because you read {title} (up to 3) | `GET /library/world/recommendations` `sections[]` | Title "Because you read Solo Leveling"; each card's `why` line ("Same regressor revenge arc, sharper art") |
| For you | the same endpoint's `for_you[]` | "Picked from what you read" |
| Your genres | `GET /library/recommendations` genre weights | Chips; each opens Search filtered by that genre |
| More like this (series detail) | **new** `GET /library/similar?source=&series=&limit=12` → `WorldItem[]` | "More like {title}" |
| Start here (new profiles) | world recommendations filtered by the onboarding taste | "Start here" |

- **Cards:** the world title card (§3.7) in its two variants: **available** (opens the series on one of the reader's sources; a source chip, and a source picker menu when several have it) and **info-only** (dashed border, "Not on your sources", actions "Search my sources" and "Read on {site}").
- **In-session re-rank:** opening a series pulls rails whose seed shares its top genre up by one position, animated on `snappy` (rails trade places, no layout jump under the finger: re-rank happens only for rails outside the viewport).
- **Not interested:** on AI cards only: throw the lifted card sideways (projection past a side edge or |vx| ≥ 1200 px/s), or ⋯ → "Not interested". The card flies off on `dismiss` with its velocity and spins up to 12° in the throw direction; the rail closes the gap; toast "We'll show fewer like this · Undo". **New** `POST /library/recs/feedback {anilist_id | (source_id, series_key), signal: "not_interested" | "undo"}`; the server drops the item from future sections for this profile.
- **Loading:** AI rails show their header immediately and 4 skeleton cards whose sheen moves at half speed (2800 ms), because a cold world-recommendations call makes many public-API requests.

#### 5.1.2 For you and Ask (`/library/recommendations`)

- **Entry points:** Home "See all" on AI rails, Search idle "Ask" card, You → For you, the command palette ("Ask for something to read"), the Home ⋯ menu.
- **Layout, phone:** large title "What do you feel like?" (letter reveal); the **Ask box**: a content-layer text area (3 rows, grows to 6, max 600 characters, placeholder "A revenge story with a competent lead, no harem"), three example chips beneath ("A murim regressor who comes back stronger", "Magic academy, but the lead is already strong", "Something slow and political, not a power fantasy"; tap fills and asks), the tinted **Ask** button, and a **quota meter**: a tiny liquid capsule "7 of 10 asks left today" (shown when 10 or fewer remain). Below: the ask's results, then "For you" and the "Because you read" sections as vertical card lists (phone) or 2 to 3 column grids (desktop).
- **Asking:** Enter (Shift+Enter for a newline) or the button → `POST /library/world/suggest {prompt}` (on-source only when the "Only my sources" switch under the box is on: `POST /library/suggest`). The button becomes a liquid ring; the results area shows 4 card skeletons with the slow sheen; after 10 s a line "Still thinking. Answers can take up to 40 seconds." and a "Cancel" plain button (aborts the request).
- **Signature moment:** results are **dealt**: each card flies out of the Ask button's position along a short arc into its slot (the wave's cause is the button), landing on `snappy` with 40 ms spacing, the `why` line typing in underneath at 12 ms per character (quick, not the 50 ms headline pace).
- **Onboarding taste as context:** the request prompt is prefixed on the client with the profile's liked and avoided genres and formats ("Likes: murim, regression. Avoids: harem.") unless the user turns "Use my taste" off under the box.
- **States:** available; **not configured** (the Ask box is replaced by a quiet notice "Asking isn't set up on this server. The picks below still work."); **budget exhausted** ("You've used today's asks. They reset at midnight UTC; the picks below still work.", the box disabled with the reset time); **thinking**; **results**; **no matches** (`ai_no_matches`: "Nothing matched that. Try describing it differently." + the prompt stays for editing); **rate limited** ("Too many asks at once. Try again in 20 s." with a countdown on the button); **error** ("That didn't work" + Try again); **unavailable reason** (a quiet line with the server's `unavailable_reason` above the world sections); **offline** (the box disabled, "Asking needs a connection"); **empty** ("Read or follow a few series first. Picks here start from what you read." + Browse sources).
- **Keys:** `/` focuses the box, Enter asks, Esc cancels a running ask, arrows through results.
- **Coverage:** web R12 RC1–RC11, A41–A43; mobile S11 1–20; capabilities §9.

#### 5.1.3 "Previously on" recaps

- **Entry points:** (1) swipe the Continue stack card left on Home or Library, revealing a "Previously on" pill that opens the recap; (2) the series detail ⋯ menu and a "Previously on" row above the chapters when the profile has progress; (3) the Home spotlight's "Previously on" candidate (a series paused 14 days or more); (4) **the return prompt**: opening a chapter of a series last read 14 or more days ago shows a `glassThin` capsule at the top of the reader "It's been 3 weeks. Previously on…?" for 6 s (tap opens the recap as a sheet over the reader; swipe it up to dismiss).
- **Recap sheet** (`medium` → `large`, desktop window 560): heading "Previously on Solo Leveling" (**typing reveal**), a chip "Up to chapter 142" (spoiler guard: "Nothing after where you are"), a length segmented control Short · Longer, a scope segmented control Series so far · This chapter; the body: 3 to 6 paragraphs in `body` 17/26 that arrive sentence by sentence (each sentence fades in over 180 ms, 90 ms apart); for novels, a **Characters** row of orbs (from the book's attribution cast: name + a one-line role from the recap) that open a small popover; the tinted "Continue · Ch 143" at the bottom; "Generated 2 d ago" `caption1` and a refresh icon (costs one ask).
- **Endpoint (new):** `POST /ai/recap {source_id, series_key, upto_chapter_key, scope: "series" | "chapter", length: "short" | "long"}` → `{status: "ready" | "preparing" | "unavailable", reason?, paragraphs: [str], characters: [{name, role}], upto_chapter_number, generated_at, remaining_today}`. The server builds the recap from novel paragraphs or manga OCR page text up to the given chapter, caches it per (series, upto, scope, length), and applies the 18+ gate when serving.
- **States:** **preparing** (a liquid ring and "Reading back through chapters 130 to 142…"; the sheet polls every 3 s up to 60 s); **ready**; **no source text** ("No recap yet: the dialogue in these chapters hasn't been extracted." and, on phones with downloads, "Extract text from downloaded chapters"; novels always have text); **AI unavailable** ("Recaps are resting right now." + the server's reason); **budget exhausted**; **rate limited**; **error**; **offline** (a cached recap opens with "Saved recap from 2 d ago"; otherwise "Recaps need a connection").
- **Keys:** Enter continues reading; `[`/`]` switch scope; Esc closes.

#### 5.1.4 More like this

A rail at the bottom of series detail and on the caught-up end card: `GET /library/similar` (new); loading skeletons; hidden when empty; unavailable card when AI is resting.

### 5.2 Reading stats, streaks and Wrapped

#### 5.2.1 Statistics (`/library/statistics`)

- **Entry points:** the streak chip in the Home greeting, the You tab's Reading card, the sidebar "Stats", the palette.
- **Layout, phone:** large title "Your reading"; range segmented **7 d · 30 d · 90 d · Year**; a mode note when novels are on ("Streak, totals and the clock count everything; the lists below are manga only").
  - **Hero:** the **streak flame** (§5.2.2) at 96 px with "12-day streak" `title1`, "Longest: 31 days" and "Read on 18 of the last 30 days" `footnote`, a 14-dot row of the last two weeks (filled `streak` = read, `fill3` = not, each dot's date and pages in its tooltip or accessible name), and "Last read 2 h ago"; around the flame, the **daily goal ring** (when a goal is set) filling with today's minutes; "Read today to keep it" hint when today is empty; an unlit wick and "Read today to start a streak" when the streak is 0.
  - **Totals:** four stat cards (Time read, Chapters, Pages, Series) with "all time" captions and 7-point sparklines.
  - **Chapters per day:** a bar chart (bars rise from the baseline on `snappy`, staggered by wave from the left); **drag across the chart to scrub days**: a glass readout capsule follows the finger ("Mon 1 Sep · 42 pages · 3 chapters · 25 min") with a `selection` tick per day; the best day marked with a small `streakCore` dot.
  - **Year heatmap** (Year range): 53 × 7 cells, 10 px squares with 2 px gaps, colour from `fill3` (0) through four steps of `iris800` → `iris400`; drag to scrub days as above; months labelled.
  - **When you read:** a 24-hour **clock** (a radial histogram: 24 bars around a 160 px circle, length by pages read, the peak hour labelled "You read most around 23:00").
  - **Genre radar:** 6 to 8 axes from the genre weights; the polygon springs out from the centre on `celebrate`.
  - **Where you read:** source rows with share bars; **Most read:** cover rows ("12 h 40 min · 88 chapters"); **Recent sessions:** rows linking to the reader; **Your library:** per-status bars.
  - **Footnotes:** "Days start at UTC+05:30", "Each session counts up to 30 min of idle time", "Recording since 27 Jul 2026".
  - **Share** (nav row): shares the current range as a card (§5.2.4).
- **Desktop:** a two-column dashboard: hero and totals across the top; charts in a 2 × 2 grid; lists in the right column.
- **Daily goal:** ⋯ → "Daily goal": Off · 10 · 20 · 30 · 45 · 60 min (a menu); stored per profile (new field `reading_profiles.daily_goal_minutes`, via `PATCH /profiles/{id}`).
- **States:** loading (hero, 4 cards, a chart block, two panels as skeletons); offline ("Statistics need a connection"); error; **empty** ("No reading recorded yet" + Browse sources); **followed but never read** ("Nothing read on this profile yet" + a "Your library" card); range with no activity ("Nothing read in the last 7 days" inside the chart).
- **Keys:** `[`/`]` change range, arrows scrub the focused chart day by day (the readout capsule follows focus), `s` share, `shift+g` sets the daily goal.
- **Data:** `GET /library/statistics?days={7|30|90|365}&tz_offset_minutes=`; the Year range uses **new** `from`/`to` query parameters for calendar-year boundaries (`from=2026-01-01&to=2026-12-31`), falling back to `days=365`.
- **Coverage:** web R13 ST1–ST13, A40; mobile S12 1–17; capabilities §10.

#### 5.2.2 The streak flame

- **Construction:** three nested teardrop paths: outer `streak` `#FF8A3D`, middle `#FFB547`, core `streakCore` `#FFD166`, each a cubic Bézier teardrop whose **tip is a physics point**: a spring (`drift`) pulls it to rest above the base, and it is pushed by (a) device tilt (the tip leans opposite to gravity's change, up to 18 % of the flame height) and (b) scroll acceleration on the containing view (the flame leans back when the page is flicked, like a candle carried quickly). A flicker offsets the tip by value noise (amplitude 2 % of the height, 5 Hz), frozen under Reduce Motion.
- **Sizes:** 16 (chip), 44 (You card), 96 (Statistics hero), 220 (Wrapped).
- **Streak +1** (the first chapter finished on a new day): the flame **flares**: scale 1 → 1.3 → 1 on `celebrate`, 8 ember particles rise from the tip with an upward acceleration of 300 px/s² and random lateral drift, fading over 900 ms; `streakUp` haptic (`ignite`); the chip on Home shows "+1" typing briefly. It fires wherever the chapter was finished (the reader shows a small flame toast "13-day streak").
- **Goal met:** the goal ring closes and fills solid for 600 ms; `goalMet` haptic.
- **Broken streak:** no drama: the next open shows the unlit wick and the longest streak line.

#### 5.2.3 Wrapped (`/wrapped/:year`)

- **Entry points:** You → "Your 2026 in chapters" (1 December to 31 January), Statistics Year range → "Play your year", a one-time Home spotlight card in December; past years remain in Statistics while data exists.
- **Format:** a takeover story of 10 full-screen cards; progress capsules along the top (one per card, filling over 6 s each); tap the right two-thirds → next, left third → previous; **hold** pauses (the capsule stops filling); **swipe down** closes (projection past 120 px; the story shrinks back into its entry card on `zoom`); horizontal swipes move between cards with a 3-D stack (the next card waits beneath at scale 0.94 and 60 % brightness, rising on `page` as the top card leaves along the swipe with its velocity); `wrappedAdvance` per card.
- **Cards:**
  1. **Cover:** "Your 2026 in chapters" (**typing reveal**) over the ambient field of the year's top covers; the profile orb.
  2. **Time:** "You read for 212 hours" (`display` numeral counting up on `drift` from 0, digits in Google Sans Code so they don't jitter), "That's 8 full days."
  3. **Volume:** chapters and pages, with a column of tiny page glyphs that pour down and pile up (each glyph a physics body falling with 2,400 px/s² gravity and settling with restitution 0.3; 200 glyphs max; Reduce Motion shows the pile at rest).
  4. **Top five series:** a podium: covers drop in from above with gravity and bounce into their places (1st last, with a `celebrate` land and `success`), titles beneath.
  5. **Genres:** the radar polygon expanding, the top genre named large.
  6. **When:** the 24-hour clock, "You're a night reader: most of it after 22:00."
  7. **Streak:** the 220 px flame with the longest streak; the flame flares once.
  8. **Top source:** its logo in a glass lens, "Most of it came from MangaSource."
  9. **Together** (only when social is on and friends shared): "You and Aarav both read Omniscient Reader."
  10. **Summary:** a compact card with the year's five numbers and top cover, and the **Share** button.
- **Sound:** when UI sounds are on, each card change plays `tick`, the podium plays `add`, the summary plays `shimmer`.
- **States:** loading (the cover card with a liquid ring), not enough data ("Not enough reading this year for a recap yet. Come back after a few chapters."), offline (the last generated Wrapped is cached per profile and plays offline), error.
- **Keys:** `←`/`→` cards, Space pause, Esc close, `s` share.

#### 5.2.4 Shareable stat cards (image export)

- **Formats:** Story 1080 × 1920 and Post 1080 × 1350 PNG; any Wrapped card, the Statistics range summary, the streak.
- **Design:** black, three soft colour blobs from the top covers (drawn as radial gradients, no blur filter), the big numeral in `display` Google Sans Flex, one line of context, the top cover when relevant (radius 28), the small single-line wordmark bottom-left, and an optional profile name (switch "Show my profile name", default off). **Mature series and covers are never drawn on a share card**, whatever the gate says.
- **Flow:** Share → the card **lifts** off the screen (`shareLift`: scale 1 → 0.86 with a deep shadow, `glassThick` sheet below with Story · Post segmented and the name switch) → "Share" renders and opens the system share sheet; "Save" on desktop downloads.
- **Rendering:** web draws the card on a `<canvas>` (fonts from `document.fonts` after `document.fonts.ready`; covers are same-origin through the API proxy, so the canvas is not tainted) → `canvas.toBlob("image/png")` → `navigator.share({ files: [file] })` when `navigator.canShare({ files })` is true, otherwise a download link. Flutter renders the card widget offstage inside a `RepaintBoundary` at 1080 logical px wide, `toImage(pixelRatio: 1)`, encodes PNG, and shares with `share_plus` 13.3.0 (`SharePlus.instance.share(ShareParams(files: [XFile.fromData(bytes, mimeType: "image/png", name: "manhwamaniacs-2026.png")]))`).
- **States:** rendering (the Share button's loading state), shared (toast "Shared"), cancelled (silent), failed (toast "Couldn't make the image").

### 5.3 Social for 2–3 users

**Model.** Social is **opt-in per profile** and off by default. A profile that turns it on becomes visible to every other opted-in profile on the server (with 2–3 accounts, "friends" means everyone else who opted in, including other profiles on the same account). New profile fields: `reading_profiles.social` (`"off"` | `"friends"`), `reading_profiles.share_mature` (default false) and `reading_profiles.share_streak` (default false). Isolation rules served by the backend:

- Only activity from opted-in profiles exists in any feed; turning social off removes the profile's activity from others' feeds.
- A profile's mature activity is shared only when its `share_mature` is on, **and** is served only to viewers whose 18+ gate is open. Viewers with the gate closed never see it and never see a gap (absence, not a lock).
- Bookmarks, searches, reading time and downloads are never shared; streaks are shared only when "Share my streak" is on.

**New endpoints:** `GET /social/friends` → `[{profile_id, username, name, avatar_key, mood, last_active_at}]`; `GET /social/feed?before=&limit=30` → `[{id, actor, kind: "started" | "finished_chapter" | "finished_series" | "followed" | "reacted" | "recommended" | "shared_collection" | "streak", series: {source_id, series_key, title, cover_url}, chapter?: {chapter_key, number}, reaction?, note?, created_at}]`; `GET /social/reactions?source=&series=&chapter=` → counts per kind with reactor profiles; `POST /social/reactions {source_id, series_key, chapter_key, kind}`; `DELETE /social/reactions/{id}`; `POST /social/recommendations {to_profile_id, source_id, series_key, note?}`; `GET /social/recommendations/inbox`; `PATCH /social/recommendations/{id} {status: "seen" | "added" | "dismissed"}`; `PATCH /library/collections/{id} {shared: bool}`; `GET /social/collections`.

#### 5.3.1 Activity (`/activity`)

- **Entry points:** the sidebar "Activity" item, the You tab's Activity card, the Home "Friends are reading" rail's "See all", a bloom dot on the You tab when a recommendation arrives.
- **Layout:** large title "Activity"; a **friends row** of 56 px orbs with names and "active 2 h ago" (tap → a friend sheet: their shared collections, what they're reading now, their recent reactions); segmented **All · Reactions · For you** (For you = recommendations received); the feed grouped by day: rows with the actor orb 32, a sentence ("Aarav finished chapter 142 of **Solo Leveling**", "Mira started **Omniscient Reader**", "Aarav reacted with fire to chapter 88", each reaction drawn with its Phosphor glyph, never an emoji), the cover 44 × 66, the time; tapping opens the series (zoom from the cover).
- **Recommendations received:** cards with the sender's orb, the series (world title card style), their note in Literata italic, and actions "Add to library" (secondary; the screen has no tinted object because every card would compete) and "Not now" (plain); status sync through `PATCH`.
- **Opt-in card** (shown when this profile's social is off): "Read together", "Share what this profile reads with the other readers on this server: what you start and finish, your reactions, and the collections you choose to share. Never your bookmarks, searches or downloads.", the switch, and "Also share mature (18+) activity" (only visible when the gate is on).
- **States:** off (opt-in card), nobody else sharing ("Nobody else is sharing yet. When another profile turns this on, their reading shows up here."), loading (6 row skeletons), empty feed, offline, error.
- **Keys:** arrows, Enter, `r` refresh, `[`/`]` segments.

#### 5.3.2 Reactions on chapters

- **Where:** the manga reader's end card and the novel reader's end matter (for the chapter just finished), the series detail header (for the latest chapter read), feed items.
- **Picker (signature):** tapping the reaction button sends a **heart** at once; **pressing and holding** (300 ms) blooms six glass bubbles in a 120° arc above the finger on `lens`: heart, fire, smiley (funny), smiley-x-eyes (shocked), smiley-sad, hand-clapping; `reactionBloom`. Sliding the finger across them magnifies the bubble under it to 1.4 × on `track` (`reactionCross` per bubble); releasing on a bubble sends it: the glyph **flies** in a ballistic arc (launch velocity toward the reaction strip, gravity 2,400 px/s²) and lands in the strip with a `pop` (`reactionSent`, the `pop` sound when enabled), its count ticking up on `tick`. Releasing outside cancels (the bubbles collapse back into the button on `dismiss`).
- **Strip:** reaction glyphs with counts; friends' orbs stacked (up to 3 + "+2") beside each; tap a glyph to see who; tap your own reaction to remove it (it shrinks away on `dismiss`).
- **Keys (desktop):** focus the reaction button, `Enter` hearts, `shift+Enter` opens the picker, arrows choose, Enter sends.
- **States:** sending (the flown glyph waits in the strip at 60 % until confirmed), failed (the glyph falls back to the button with a wobble and a toast "Couldn't send that reaction"), social off (the reaction button is hidden).

#### 5.3.3 Shared collections

- A collection's header gets a share toggle (people glyph): on → "Shared with your friends" and a friend-orb badge on its card.
- Friends' shared collections appear in Collections under **From friends** (cards carry the owner's orb), open read-only (no edit, no delete), and offer "Save a copy" (creates a collection with the same members via `POST /library/collections` and the member calls).
- Mature members of a shared collection are served only to viewers whose gate is open (the rest simply see fewer members).

#### 5.3.4 Recommend to a friend

- **Gesture (signature):** lift any poster (long-press). When social is on and friends exist, their orbs (56 px, `glassThin` bezel) **materialise along the top** of the screen at safe-top + 72, spaced 72 apart. Drag the lifted poster toward an orb: within 64 px the orb swells to 1.2 and the poster is **pulled** toward its centre (magnet: the poster's position eases toward the orb by 35 % of the remaining distance per frame while inside the radius), `magnetCapture`; releasing inside sends: the poster shrinks into the orb on `zoom`, the orb pulses (`celebrate`) and `magnetDrop` + `recommendSent` fire; a toast "Recommended to Aarav · Add a note · Undo" (Add a note opens a small sheet with a text field, max 140 characters).
- **Menu path:** every poster and series detail ⋯ has "Recommend to…" → a `medium` sheet with friend rows (orb, name), an optional note field, and "Send".
- **Recipient:** a card in Activity → For you, a bloom dot on the You tab, and a candidate for their Home spotlight ("Aarav thinks you'd like this").
- **18+:** a mature recommendation is stored but delivered only when and if the recipient's profile shows mature content; the sender is told nothing either way, so nobody learns another profile's gate.
- **States:** no friends (the orbs don't appear; the menu item reads "Recommend to… (no one is sharing yet)" and is disabled with that reason), sending, failed (the poster springs back out of the orb to its origin with a toast).

### 5.4 Ambient reader extras

#### 5.4.1 Cruise (auto-scroll with speed control)

- **Entry:** the cruise button in the reader's bottom capsule (`flywheel` glyph), `p`, or the reader settings default.
- **Start:** tap → the strip ramps from 0 to the saved speed over 400 ms (`cruiseStart` haptic, a flywheel spin-up), and the button becomes a **flywheel pill**: a 44 px tall capsule with a spinning disc glyph whose rotation speed matches the scroll speed and "1.0×" in `mono`.
- **Speed:** 0.25× to 4× of a 60 px/s base (15 to 240 px/s), logarithmic. **Drag vertically on the pill** to change it (up faster, 8 px per 0.05×), `cruiseStep` every 0.25×, a magnet at 1.0×; a glass HUD "1.5×" floats above while dragging. **Flick to cruise:** while cruise is on, a flick on the strip lets the strip coast; when its velocity decays into the cruise range, the flywheel **engages** and holds that speed (the pill's value updates to match, with a `selection`), so a gentle flick is the fastest way to set speed. Keyboard `<`/`>` step by 0.25×.
- **Pause and resume:** touching the strip stops it under the finger (catch); releasing resumes after 800 ms with the 400 ms ramp; any chrome interaction pauses; reaching the end of available pages stops it (`cruiseEnd`); in continuous mode it carries across chapter seams.
- **Right-edge swipe** while cruising (the scrub rail's strip) adjusts speed instead of scrubbing, with the HUD.
- **Persistence:** speed per series (`autoScrollSpeed` in the per-series reader preferences), default in Settings.
- **Reduce Motion:** cruise still works (the reader asked for this motion) but never starts on its own and uses no ramp.

#### 5.4.2 Soundscape

- **Entry:** reader settings → Ambient → Soundscape, the listen player's ⋯, Settings → Sound and haptics default.
- **Picker:** a row of six glass tiles (72 px) with Light glyphs: **Rain**, **Wind**, **Ocean**, **Hearth**, **Stream**, **Deep**; the playing tile shows 8 live level bars; a volume slider (−30 to 0 dB, default −12).
- **Sound (procedural, no files, identical on every platform):**

| Soundscape | Recipe |
|---|---|
| Rain | Pink noise → high-pass 400 Hz → low-pass 6 kHz; plus droplet ticks (sine 2 to 4 kHz, 4 ms, 8 to 20 per second, random pan) |
| Wind | Brown noise → band-pass 300 Hz, Q 0.7, centre modulated ±150 Hz by a 0.08 Hz LFO; gain LFO 0.05 Hz depth 0.4 |
| Ocean | Brown noise → low-pass 900 Hz; amplitude swell by a 0.1 Hz LFO, depth 0.7 |
| Hearth | Brown noise → low-pass 1.2 kHz at −18 dB; crackles: 3 to 8 ms noise bursts band-passed at 3 kHz, Poisson rate 6 per second |
| Stream | Pink noise → band-pass 1.8 kHz, Q 1.2; amplitude flutter 7 Hz depth 0.15 |
| Deep | Sines at 55 Hz and 82.41 Hz (A1 + E2) with a slow 0.03 Hz chorus, plus pink noise low-passed at 300 Hz |

  All normalised to −24 LUFS. **Web:** Web Audio graph (a 4 s noise `AudioBuffer` looped, `BiquadFilterNode`s, `OscillatorNode` LFOs into `AudioParam`s), started on the user's tap. **Phones:** the same recipe rendered in a Dart isolate to a 30 s mono 32 kHz buffer whose last 2 s are cross-faded into its first 2 s (a seamless loop), wrapped as WAV and loaded with `SoLoud.instance.loadMem`, played looping; the event parts (droplet ticks, crackles) are scheduled live on top so they never repeat audibly.
- **Mixing:** while narration plays, the soundscape ducks by 12 dB over 400 ms; it follows the sleep timer; it pauses when the reader is left and resumes on return; it never plays under the UI sound layer (UI sounds are suppressed while it plays).
- **States:** off, playing, paused, ducked, unavailable (the audio device refused: toast "Couldn't start the soundscape").

#### 5.4.3 Guided view (panel by panel)

- **Data:** new `GET /reader/panels?source=&series=&chapter=` → `{status: "ready" | "pending" | "unavailable", pages: [{index, width, height, panels: [{x, y, w, h, order}]}]}`, computed and cached by the server per page (panel detection is backend work in `stack-decision.md` §2.6).
- **Entry:** the page menu (long-press a page) → "Guided view", reader settings → Ambient → Guided view, or `shift+p`; a `panel-focus` glyph joins the top-right group while it is on.
- **Camera:** the viewport frames the current panel with 24 px padding (fit to width or height, up to 3×) on black; the next or previous panel is one swipe (horizontal, ≥ 50 px or ≥ 500 px/s, direction-locked) or one tap on the side bands; the camera **glides** between panels on `camera`, carrying the swipe's velocity into the glide, and crosses page boundaries continuously; `panelStep` per panel. Panels taller than the viewport are walked in steps of 80 % of the viewport height. Past the last panel the camera rubber-bands and then offers the next chapter like the strip.
- **Overview:** pinch out below 1× to see the whole page with panel outlines numbered in glass chips; tap a panel to fly to it; pinch in returns.
- **Exit:** swipe down (projected past 120 px) or the glyph → back to the strip at the same spot.
- **States:** pending ("Finding panels…" capsule; the view falls back to page-by-page framing meanwhile and switches when ready), unavailable ("Guided view isn't available for this chapter" + "Read as strip"), ready.
- **Reduce Motion:** cuts between panels with a 120 ms cross-fade.

#### 5.4.4 Page-tinted chrome

- **Sampling:** the page on the reading line (38 % down); its palette from the manifest (`pages[].palette`) or the client fallback (§2.1.8), sampled every 600 ms while scrolling and on settle, cached per page.
- **Tint:** the dominant swatch clamped in OKLCH to lightness 0.35 to 0.50 and chroma ≤ 0.12; applied as a tint layer inside every reader glass surface at 18 %, to the rims at 22 %, to the soft edges at 30 %, and to the micro-progress line; the tint cross-fades over `tintShift` (900 ms), so fast scrolling never flickers.
- **Luminance:** the same sample's relative luminance drives `underlayAdaptive` (§2.1.7) for legibility over white pages.
- **Switch:** reader settings → Ambient → Page-tinted chrome (default on). Off: neutral glass.
- **Desktop:** the side panels' rims take the same tint.

---

## 6. The two required signature animations

### 6.1 Heading reveal (each letter fades in, slides up and un-blurs, staggered)

**Glass version: every letter is a droplet settling.** Each grapheme is its own small spring, so letters overshoot a hair and settle like drops finding their level, and a single specular glint crosses the finished heading.

| Parameter | Value |
|---|---|
| Unit | Grapheme (`Intl.Segmenter` on web, `characters` in Dart), wrapped per word so lines break at spaces |
| Opacity | 0 → 1 over `fadeIn` (180 ms) |
| Translate | +0.40 em → 0 on the letter spring `{ms: 424, bounce: 0.12}` (k 220, c 26), so a 34 px title rises 13.6 px |
| Blur | 12 px → 0 on the same spring |
| Scale | 0.96 → 1 on the same spring |
| Stagger | 24 ms per grapheme; spaces take no time |
| Flourish | 120 ms after the last letter settles, a 30° linear gradient band (white at 18 %, 40 % of the heading's width) sweeps across the text left to right over 500 ms (`background-clip: text` overlay on web; a `ShaderMask` on Flutter), once |
| Colour on hover and state | `colorShift` 240 ms (for example, a rail header link brightening from `label1` to `iris300` on hover) |
| Size | Responsive per the type scale (§2.2.2) with tight tracking (`largeTitle` −0.020 em, `title2` −0.010 em, `display` −0.025 em) |
| Limit | Headings up to 60 graphemes; longer text reveals per word with the same parameters and 40 ms per word |

**Placement (exactly these):**

1. Tab-root large titles (Library, Sources, You) and pushed-screen large titles, **once per session per screen**.
2. Rail headers (H3, `title2`) on Home and Library, the first time each rail scrolls into view per session.
3. The hero spotlight title on Home, each time the spotlight pages (the outgoing title leaves together over `fadeOut` with blur 4 px).
4. The series detail title and the book page title when the sheet opens.
5. Chapter seams ("CHAPTER 144") in the manga strip as they enter the viewport.
6. Onboarding step titles, the For you title, Statistics hero line, Wrapped card titles.
7. The wordmark letters in the splash (§7.4).

**Interruptibility:** scrolling the heading off-screen, tapping it, or navigating completes it instantly (all letters jump to rest); new text replaces old text by letting the old letters leave together and starting the new wave.

**Accessibility:** the full text is in the accessibility tree from the first frame (web: an `sr-only` copy plus `aria-hidden` on the animated letters; Flutter: `Semantics(label: text)` over `ExcludeSemantics`); Reduce Motion shows the text at once with no glint.

**Web implementation** (RSC, zero client JS for the one-shot case):

```tsx
// skins/glass/primitives/LetterReveal.tsx
const seg = new Intl.Segmenter(undefined, { granularity: "grapheme" });
export function LetterReveal({ text, as: Tag = "h3" }: { text: string; as?: "h1" | "h2" | "h3" }) {
  let i = 0;
  return (
    <Tag className="letter-reveal">
      <span className="sr-only">{text}</span>
      <span aria-hidden>
        {text.split(" ").map((word, w) => (
          <span key={w} className="word">
            {Array.from(seg.segment(word), (s) => (
              <span key={i} style={{ "--i": i++ } as React.CSSProperties}>{s.segment}</span>
            ))}
            {" "}
          </span>
        ))}
      </span>
    </Tag>
  );
}
```

```css
.letter-reveal .word { display: inline-block; white-space: nowrap; }
.letter-reveal [aria-hidden] span span {
  display: inline-block;
  animation:
    lr-rise 560ms var(--mm-spring-letter) both,   /* linear() sampled from {424 ms, 0.12} by build.mjs */
    lr-fade 180ms cubic-bezier(0.2, 0, 0, 1) both;
  animation-delay: calc(var(--i) * 24ms);
}
@keyframes lr-rise { from { translate: 0 0.4em; scale: 0.96; filter: blur(12px); } }
@keyframes lr-fade { from { opacity: 0; } }
@media (prefers-reduced-motion: reduce) { .letter-reveal [aria-hidden] span span { animation: none; } }
```

The interruptible variant (hero spotlight, where text changes) is a client component using Motion 13.4.4 with `animate` per letter and `glassSpring.letter = { type: "spring", stiffness: 220, damping: 26, mass: 1 }`, so a new title can retarget letters mid-flight.

**Flutter implementation:**

```dart
// lib/skins/glass/primitives/letter_reveal.dart
class LetterReveal extends StatefulWidget {
  const LetterReveal(this.text, {super.key, required this.style});
  final String text; final TextStyle style;
  @override State<LetterReveal> createState() => _LetterRevealState();
}
class _LetterRevealState extends State<LetterReveal> with TickerProviderStateMixin {
  static final _spring = SpringDescription.withDurationAndBounce(
      duration: const Duration(milliseconds: 424), bounce: 0.12);
  late final List<AnimationController> _c;
  @override void initState() {
    super.initState();
    final n = widget.text.characters.length;
    _c = List.generate(n, (i) => AnimationController.unbounded(vsync: this));
    for (var i = 0; i < n; i++) {
      Future.delayed(Duration(milliseconds: 24 * i), () {
        if (mounted) _c[i].animateWith(SpringSimulation(_spring, 0, 1, 0));
      });
    }
  }
  @override void dispose() { for (final c in _c) { c.dispose(); } super.dispose(); }
  @override Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return Text(widget.text, style: widget.style);
    final chars = widget.text.characters.toList();
    return Semantics(label: widget.text, child: ExcludeSemantics(child: Wrap(children: [
      for (var i = 0; i < chars.length; i++)
        AnimatedBuilder(animation: _c[i], builder: (_, __) {
          final v = _c[i].value;                      // may pass 1.0 slightly: the droplet overshoot
          final blur = (1 - v).clamp(0.0, 1.0) * 12;
          return Opacity(opacity: v.clamp(0.0, 1.0),
            child: Transform.translate(offset: Offset(0, (1 - v) * 0.4 * widget.style.fontSize!),
              child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: Text(chars[i], style: widget.style))));
        }),
    ])));
  }
}
```

(Word-level wrapping and the glint `ShaderMask` wrap this in the real primitive; per-glyph `ImageFiltered` layers are limited to headings of 60 graphemes or fewer, per the flagship-only budget.)

### 6.2 Main headline typing reveal (one character every 50 ms)

**Glass version: each character lands.** The string is laid out in full from frame 0 with the untyped tail transparent (the line never reflows); every 50 ms the next grapheme becomes visible by fading in over 40 ms while scaling 0.8 → 1 on `tick` (a tiny droplet landing), and a 2 px `iris400` caret, as tall as the cap height, rides at the insertion point, moving on `track` so it glides rather than jumps. When typing ends the caret blinks (`caretBlink` 530 ms) three times and then fades over 180 ms.

**Placement (exactly these):**

1. The Home greeting ("Good evening, Yash"), once per app session.
2. The Login heading ("Welcome back").
3. Onboarding's first step ("Hi, Yash.").
4. The Wrapped cover ("Your 2026 in chapters").
5. The recap sheet heading ("Previously on Solo Leveling").

**Rules:** a 24-character greeting takes 1.2 s; tapping the headline or pressing any key completes it at once; navigating away completes it silently; screen readers get the whole string immediately (`aria-label` on web; `Semantics(label:)` on Flutter), and the typed spans are `aria-hidden`. No haptic per character (it would be noise); UI sound off by default, and even when on, typing plays no sound. Reduce Motion: the full text immediately, no caret.

**Web:**

```css
.typed [aria-hidden] span { opacity: 0; display: inline-block;
  animation: ty-land 340ms var(--mm-spring-tick) both; animation-delay: calc(var(--i) * 50ms); }
@keyframes ty-land { from { opacity: 0; scale: 0.8; } 40% { opacity: 1; } to { opacity: 1; scale: 1; } }
.typed .caret { width: 2px; height: 0.72em; background: var(--mm-color-iris400);
  translate: var(--caret-x) 0; transition: translate 150ms var(--mm-spring-track); }
```

The caret's `--caret-x` is updated by a 10-line client effect from `getBoundingClientRect` of the last visible span every 50 ms (skipped under reduced motion).

**Flutter:** a `Text.rich` whose first `n` graphemes are visible and whose tail is `Color(0x00000000)`, with `n` driven by a `Ticker` (`n = elapsed ~/ 50ms`), each newly visible grapheme wrapped in a `WidgetSpan` scale animation on the `tick` spring (it settles in 337 ms), and the caret positioned from `TextPainter.getOffsetForCaret`.

---

## 7. Brand

### 7.1 Wordmark

**"Stack", Glass rendition, with a meniscus.** "Manhwa" above "Maniacs", flush left, leading 0.84, so the two capital M's stack into the **MM column**; the lowercase in Google Sans Flex `ROND 100`, `wght 620`, tracking −0.020 em, in Frost `#F5F7FA`.

- **The MM column:** the two M's are joined by the gutter bar; in Glass the column is a glass capsule (corner radius 40 % of its width) with the M's engraved (inner shadow `rgba(0,0,0,0.45)` 2 px, specular edge `rgba(255,255,255,0.55)` along the top-left), and the **gutter bar is a meniscus**: a clear refractive seam that bows 2 px (at 64 px cap height) downward in the middle, as if a film of liquid held the two panels together. Geometry follows the 1024 master: box x 240–784, y 192–832; top M y 192–480; bar y 480–544; bottom M y 544–832; stroke 88 units.
- **Single-line fallback** (sidebar, tight headers): "ManhwaManiacs" in Google Sans Flex `ROND 100` `wght 640`, with the two M's in `iris400`.
- **Clear space:** twice the gutter bar's thickness on every side. **Minimum sizes:** stacked lockup 28 px tall; single line 12 px cap height; MM column alone 16 px (below 32 px it drops the engraving and becomes a flat Frost silhouette with the meniscus as a gap).
- **Never:** recolour the lowercase, add effects to the lowercase, set it on a busy image without the `dimClear` layer.

### 7.2 App icon

**"MM Column", Glass rendition.**

- **Field:** a vertical gradient `#0A0F1F` → `#000000`, with an aurora of three blobs, `#8FD8FF`, `#A99BFF` and `#FF9ED8`, at 45 % opacity and 180 px blur (on the 1024 canvas), concentrated in the lower-left third so the column's glass has colour to bend.
- **Mark:** the MM column in two glass layers (Icon Composer): back layer = bottom M + bar, front layer = top M; translucency 0.5, specular on, neutral shadow; the meniscus bar clear.
- **Deliverables:** iOS 1024 opaque master; iOS 18 dark (transparent background, the mark only) and tinted (grayscale mark); an iOS 26 `.icon` bundle (`icon.json` + `Assets/` layers) compiled on the CI runner with the PNG set as fallback; Android adaptive: foreground mark inside the 66 dp safe circle (a 160 × 188 px box at xxxhdpi), background the field, monochrome the silhouette; web `favicon.svg` (a single M on the bar below 32 px), `icon-192/512`, `apple-touch-icon` 180 opaque, `maskable-512` with the mark inside the 40 % safe circle; tools `flutter_launcher_icons` 0.14.4 and a `resvg` export script.
- **Per skin:** Glass and Cinematic ship both renditions; with "App icon follows the skin" on, the restart calls `flutter_dynamic_icon_plus` 1.4.1 (`setAlternateIconName` on iOS, which shows the system's icon-changed alert inside the restart moment; `activity-alias` on Android). The web swaps `<link rel="icon">` to the active skin's SVG at load.

### 7.3 Splash

- **Native:** one neutral mark for every skin: the MM column in `#F3EEE6` on `#000000` (`flutter_native_splash` 2.4.8: `color: "#000000"`, 1152 × 1152 image, Android 12 image inside the 192 dp circle). Web: black `appleWebApp.startupImage` images and an inline SVG in the server-rendered HTML.
- **Handoff:** the first frame redraws the neutral mark pixel-identically, then plays the Droplet reveal (§7.4); on a skin-switch restart the full reveal always plays.

### 7.4 Logo reveal motion: "Droplet" (physics version)

Cold start 1,200 ms; warm start (resumed within 4 h) 400 ms; tap anywhere skips to the handoff.

| t (ms) | Element | Motion |
|---|---|---|
| 0 | Neutral mark | The mark's ink drains into a 24 px glass droplet at 180 px above centre (opacity cross-fade 120 ms) |
| 0–200 | Droplet falls | Free fall under gravity 9,000 px/s² (the 180 px drop takes 200 ms and lands at 1,800 px/s) |
| 200 | Impact | The droplet squashes to scaleX 1.25 / scaleY 0.80 and recovers on `lens`; a ripple ring (1 px rim, radius 0 → 140 px, opacity 0.30 → 0 over 500 ms) spreads across the ambient field; `logoLand` haptic (`droplet`); the `droplet` sound when enabled |
| 200–700 | Lens grows | The droplet grows into a 128 px squircle lens (corner 28 %) on a spring (k 180, c 22); inside it the MM column is refracted into view: displacement 40 → 0 px, chromatic aberration 3 → 0 px |
| ~700 | Settle | The lens settles; `logoSettle` haptic (`splash`); the `logo` arpeggio when sounds are on |
| 500–1,000 | Wordmark | "Manhwa" / "Maniacs" letters rise from behind the lens with the heading reveal (24 ms stagger, k 220 / c 26, blur 16 → 0) |
| 1,000–1,200 | Handoff | The lens morphs into its destination on `zoom`: the dock capsule (signed in), the picker's central orb (choosing a profile), or Login's lens (signed out); the wordmark fades |

Warm start: the lens materialises (250 ms) and hands off (150 ms), no fall, no letters, no haptic. Reduce Motion: a 200 ms cross-fade from the neutral mark to the destination, one `light` haptic. Web: Motion springs and SVG `feDisplacementMap` refraction (Chromium; frosted elsewhere); Flutter: `SpringSimulation` for the fall and the lens, `liquid_glass_widgets` for the lens, per-glyph `ImageFiltered` for 13 letters.

### 7.5 Voice and screenshots

- **Voice:** calm and plain, no exclamation marks: "Continue", "Up next", "You're caught up", "Previously on", "It's been 3 weeks".
- **Showcase set ("Float")**, 5 frames at 1320 × 2868 (a 440 × 956 CSS viewport at DPR 3 through Playwright): Home ("Every source. One shelf."), manhwa reader ("Built for the long scroll."), novel + listen ("Novels, read aloud." / "31 named voices"), Wrapped ("Your year in chapters."), Activity ("Read together."). Each capture sits on a glass slab (radius 88, 1.5 px inner highlight, shadow `0 60px 120px rgba(0,0,0,0.6)`, tilted `rotateY(-8deg) rotateX(4deg)`) over the aurora field; captions in Google Sans Flex `ROND 100` `wght 660` 112 px Frost. Seeded demo profile only, no 18+ content, self-made placeholder covers.

---

## 8. Signature moments

Eighteen moments where the physics is the product. Each is specified where it lives; this list is the index and the essence.

1. **The Droplet** (§7.4): the app starts by a drop falling under gravity, splashing into the ambient field and swelling into a lens that becomes the dock.
2. **Throw to open** (§3.8, §4.12): lift a poster, flick it upward, and the series sheet opens with the flick's velocity; a hard throw lands straight at the large detent.
3. **The liquid dock** (§3.15): drag across the dock and the selection droplet follows, stretches with speed, ticks under each tab, and merges with the search orb like two drops touching.
4. **Minimise, don't vanish** (§3.15, §4.14.2): scrolling down shrinks the dock (and the reader's capsule) into a pill that carries the bottom accessory inline; scrolling up pours it back out, and reversing mid-morph reverses it with momentum.
5. **The meniscus refresh** (§3.33): pulling a list stretches a droplet on a thinning neck until it snaps free at the trigger.
6. **The scrub lens** (§4.14.2): the reader's edge rail grows a glass magnifier showing the target page, with a detent tick per page that thins into a grain at speed.
7. **Momentum through the chapter end** (§4.14.4): a fling at the end of a chapter rubber-bands, raises the next-chapter card, locks it with a click, and the next chapter begins already scrolling at the fling's remaining speed.
8. **Flick to cruise** (§5.4.1): a flick sets the auto-scroll speed; the flywheel engages when the coasting velocity falls into range and holds it.
9. **The panel camera** (§5.4.3): swipes glide the camera between panels with velocity carried into each glide, across page seams, rubber-banding at the end.
10. **Recommend by dropping** (§5.3.4): drag a lifted poster to a friend's orb; the orb swells and pulls it in like a magnet, then swallows it.
11. **The reaction arc** (§5.3.2): hold to bloom six bubbles, slide to choose, and the reaction flies in a ballistic arc into the chapter's strip.
12. **The voice orbit** (§4.16.4): 31 voices on a carousel with depth that snaps card by card and lets the voice that comes to rest introduce itself.
13. **The speed dial magnet** (§4.16.3): narration speed moves in fine detents but 1.0× pulls you in with a firm click.
14. **The streak flame** (§5.2.2): a flame whose tip leans against the phone's tilt and the page's acceleration, and flares with embers on +1.
15. **The genre field** (§4.7): onboarding genres as colliding bubbles that inflate when liked, shove their neighbours, and slosh when the phone tilts.
16. **Hold to restart** (§4.25.2): switching skins fills a liquid capsule under the thumb with a rising haptic swell, then the whole glass interface melts into a single closing droplet.
17. **The repelled picker** (§4.5): choosing a profile inflates its orb and pushes the others away like drops, then the orb flies into the dock and the app forms around it.
18. **Dealt answers** (§5.1.2): AI results fly out of the Ask button into their slots in a wave, each landing with a small settle.

---

## 9. Implementation notes (for `stack-decision.md`: Next.js 16 + Flutter 3.44.6, per-skin folders, one token source)

### 9.1 The token source: `design/tokens/glass.json`

Everything in §2 lives in one JSON file that `design/build.mjs` turns into CSS variables, TypeScript numbers and Dart constants. An excerpt of its shape:

```json
{
  "color": { "canvas": "#000000", "g100": "#131317", "label1": "#F2F2F7", "label2": "rgba(235,235,245,0.64)",
             "iris400": "#A99BFF", "iris600": "#7563F2", "success": "#3DDC84", "mature": "#FF5C93" },
  "speakers": ["#7CC4FF", "#FFB27A", "#9BE58A", "#D7A4FF", "#FF8FA3", "#6FE3D4", "#FFD86B", "#A7B4FF", "#F59BD6", "#C8D98A"],
  "type": { "largeTitle": { "phone": [34, 40], "tablet": [36, 42], "desktop": [40, 46], "wide": [44, 50],
                            "wght": 700, "ROND": 100, "trackingEm": -0.02, "capAt": 48 } },
  "space": { "s4": 8, "s5": 12, "s6": 16 },
  "radius": { "capsule": 9999, "md": 14, "xl": 26, "sheetFallback": 36 },
  "material": { "glassRegular": { "fill": "rgba(255,255,255,0.06)", "underlay": 0.30, "blur": 10, "saturate": 1.8,
                                  "rim": "rgba(255,255,255,0.20)", "bezel": 12, "thickness": 24 } },
  "spring": { "track": { "ms": 150, "bounce": 0.14 }, "press": { "ms": 220, "bounce": 0.2 },
              "sheet": { "ms": 480, "bounce": 0.08 }, "page": { "ms": 520, "bounce": 0 },
              "letter": { "ms": 424, "bounce": 0.12 } },
  "curve": { "fadeIn": { "ms": 180, "bezier": [0.2, 0, 0, 1] }, "tintShift": { "ms": 900, "bezier": [0.2, 0, 0, 1] } },
  "physics": { "decelerationRate": 0.998, "rubberBandC": 0.55, "magnetRadius": 64, "waveSpeedPxPerMs": 1.6,
               "waveMaxDelayMs": 240, "hapticMinIntervalMs": 40 },
  "threshold": { "backSwipeFraction": 0.5, "sheetDismissVelocity": 1500, "rowCommitFraction": 0.6,
                 "pullTriggerPx": 100, "chapterArmPx": 48, "chapterCommitPx": 72, "holdConfirmMs": 1200 },
  "haptics": { "tabChange": "selection", "chapterCommit": "rigid:0.8", "streakUp": "ahap:ignite" },
  "sounds": { "tap": "glass/tap.wav", "droplet": "glass/droplet.wav" }
}
```

Generator outputs for Glass:

- **CSS** (`frontend/src/skins/glass/tokens.generated.css`): `[data-skin="glass"] { --mm-color-iris400: #A99BFF; … --mm-spring-page: linear(0, 0.0112 …, 1); }`; every spring is also pre-sampled to a `linear()` easing (60 samples over its settle time) for CSS-only animations.
- **TypeScript** (`tokens.generated.ts`): springs as **physical** Motion transitions, `spring.page = { type: "spring", stiffness: 146.0, damping: 24.17, mass: 1 }`, never `visualDuration/bounce`, because physical springs keep inherited velocity (§2.9.3).
- **Dart** (`mobile/lib/skins/glass/tokens.g.dart`): `SpringToken(ms: 520, bounce: 0)` with a getter returning `SpringDescription.withDurationAndBounce(duration: Duration(milliseconds: ms), bounce: bounce)`; letter spacing converted from em to absolute per style.
- **Contract** (`design/contract.json`): the `ScreenId` list and paths of §4.0.3, the `HapticEvent` names of §2.10 and the `SoundEvent` names of §2.11.

### 9.2 Web (`frontend/src/skins/glass/`)

```
skins/glass/
├── tokens.generated.css / tokens.generated.ts
├── fonts.ts                 next/font/google: Google_Sans_Flex (axes ROND, opsz; preload only when Glass is the default), Google_Sans_Code, Literata (preload: false)
├── Shell.tsx                sidebar (≥ 1024), collapsed rail (768–1023), dock + orb + accessory (< 768), toasts, palette
├── Splash.tsx               Droplet reveal (§7.4)
├── motion.ts                MotionConfig reducedMotion="user"; the spring map from tokens
├── physics/
│   ├── project.ts           project(pos, v) = pos + v * 0.998 / (1 - 0.998) / 1000; nearest(detents, projected)
│   ├── rubberband.ts        rubberband(x, d, c = 0.55)
│   ├── tracker.ts           pointer tracking with a 100 ms velocity window; catch(): stop the running animation, seed the offset
│   ├── magnet.ts            magnet(target, radius): per-frame pull, capture/release events
│   └── physics.test.ts      the one runnable check (vitest): projection, rubber band, spring k/c conversion, rail snap target
├── glass/
│   ├── GlassSurface.tsx     tiers: A "liquid" (Chromium: SVG feDisplacementMap backdrop filter), B "frosted" (blur + saturate + rim), C "solid" (Reduce Transparency, Solid glass, Increase Contrast)
│   ├── liquid-map.ts        displacement map generator (squircle bezel profile, Snell n = 1.5), cached per (w, h, r), rebuilt at rest after a 100 ms ResizeObserver debounce
│   ├── useLightAngle.ts     pointer-driven specular angle ±25° (frozen under reduced motion)
│   └── AmbientField.tsx     three radial-gradient layers on one fixed element (no filter), colours from the palette hook
├── primitives/              Button, IconButton, HoldToConfirm, Chip, Segmented, Poster, Rail, Sheet, Menu, ContextMenu, Toast, Slider, Switch, Stepper, Dock, SearchOrb, Accessory, Sidebar, CommandPalette, LetterReveal, TypedHeadline, LiquidProgress, ObjectLens, SwipeRow, ScrubRail
├── screens/<cluster>/       one file per ScreenId (§4.0.3), satisfying Record<ScreenId, Screen>
├── haptics.ts               navigator.vibrate subset (Android Chrome only)
├── sounds.ts                Web Audio: decode on first gesture, playbackRate for velocity pitch
└── soundscape.ts            the procedural graphs of §5.4.2
```

- **Dependencies** (from `stack-decision.md` §3 and the research): `motion` 13.4.4 (replaces `framer-motion`), `@base-ui/react` 1.8.0 (Dialog, Menu, ContextMenu and Toast primitives for focus management, roles and dismissal; the Glass sheet drives position itself with Motion `drag="y"`, projection and `sheetSnap` instead of Base UI Drawer's CSS timing, about 150 lines), `@use-gesture/react` 10.3.1 (reader pinch only), `@phosphor-icons/react` 2.1.10 (add it to `optimizePackageImports`; use `@phosphor-icons/react/ssr` in server components), `fast-average-color` 9.6.0 and `colorthief` 3.5.0 (palette fallback), `sonner` 2.0.8 only as the queue behind the Glass `Toast` rendered through `toast.custom`. The Glass skin does not use `lenis` or `embla-carousel-react`: rails, the hero pager and the voice orbit are native scroll containers with the projection snap.
- **Routes:** thin `app/` route files render `skins.glass.screens[id]`; `<ViewTransition>` with `nav-forward`/`nav-back` types for pushes, `name="cover-{id}"` pairs for the poster zoom, `default: "none"` for browser navigation.
- **Readers:** the shared reader engine (strip, preload, scrub, progress) stays in `features/reader`; Glass supplies only chrome, gestures and overlays through the engine's chrome slot.

### 9.3 Flutter (`mobile/lib/skins/glass/`)

```
skins/glass/
├── tokens.g.dart
├── glass_skin.dart          implements Skin: theme (BouncingScrollPhysics everywhere, PageTransitionsTheme with PredictiveBackPageTransitionsBuilder), router, splash, haptics, sounds
├── router.dart              GoRouter from the shared Routes; StatefulShellRoute.indexedStack for Home/Library/Sources/You; SwipeablePage (iOS) / MaterialPage (Android) page builder; sheet routes for series detail and the ?sheet= family
├── shell.dart               GlassDock (liquid_glass_widgets GlassTabBar, barHeight 64, minimizedBarHeight 50, search 50) + accessory + collapsed rail for ≥ 768
├── skin_glass.dart          SkinGlass: the only wrapper around liquid_glass_widgets 1.7.2 (premium on static chrome, standard inside scrollables, GlassAccessibilityScope, BackdropGroup fallback)
├── physics/
│   ├── glass_physics.dart   project(), rubberband(), SnapPhysics (rails, orbit), CatchableSpring extension on AnimationController, Magnet
│   └── (test) test/skins/glass/glass_physics_test.dart
├── primitives/              the same list as the web
├── screens/<cluster>/
├── soundscape/generator.dart  isolate that renders the 30 s loops to WAV bytes for SoLoud.loadMem
└── wrapped/share_card.dart    RepaintBoundary → PNG → share_plus
```

- **Packages** (all resolve on Flutter 3.44.6): `liquid_glass_widgets` 1.7.2 (pinned exactly), `motor` 1.1.0, `heroine` 0.7.2, `swipeable_page_route` 0.4.8, `flutter_animate` 4.5.2, `gaimon` 1.5.0, `flutter_soloud` 5.1.4, `phosphor_flutter` 2.1.0, `material_color_utilities` ^0.13.0, `sensors_plus` 7.1.0 (gyroscope light, hero tilt, flame, shake-to-extend), `share_plus` 13.3.0 (share cards), `flutter_dynamic_icon_plus` 1.4.1; dev: `flutter_native_splash` 2.4.8, `flutter_launcher_icons` 0.14.4. Sheets use `liquid_glass_widgets`' `GlassModalSheet` with `peekSize: 96`, `halfSize: 0.52`, `horizontalMargin: 8`, `fullTopBorderRadius` from the device corner, `barrierColor: Color(0x47000000)`; `smooth_sheets` 1.2.0 replaces it only for the 1,000-row chapter list if scroll hand-off stutters on a device.
- **Native:** the `mm/haptics` method channel (iOS `AppDelegate.swift`: impact styles with intensity, `reduceTransparency`; Android `MainActivity.kt`: `performHapticFeedback` with `GESTURE_THRESHOLD_ACTIVATE/DEACTIVATE`, `SEGMENT_TICK`, `TOGGLE_ON/OFF`, `DRAG_START` behind `Build.VERSION.SDK_INT >= 34`, `CONFIRM`/`REJECT` behind 30); `android:enableOnBackInvokedCallback="true"`; `LiquidGlassWidgets.initialize()` before `runApp` to precompile shaders.
- **Fonts:** bundled `GoogleSansFlexMM.ttf` (subset), `GoogleSansCode.ttf`, `Literata.ttf`, each style passing `FontVariation('wght')`, `FontVariation('opsz', size)` and `FontVariation('ROND')`; `OFL.txt` files registered with `LicenseRegistry`.

### 9.4 Backend additions this concept relies on

| Addition | Purpose |
|---|---|
| `reading_profiles.skin` (from `stack-decision.md` §2.4) | The skin follows the profile |
| `reading_profiles.social` (`off` · `friends`), `.share_mature` (bool), `.share_streak` (bool) | Social opt-in and sharing scope (§5.3) |
| `reading_profiles.daily_goal_minutes` (nullable int) | Daily goal ring (§5.2.2) |
| `library_collections.shared` (bool) | Shared collections |
| `palette` on series payloads and `pages[].palette` on chapter manifests (Pillow median-cut, 5 colours) | Ambient field and page-tinted chrome |
| `GET /reader/panels` | Guided view |
| `POST /ai/recap` | Previously on |
| `GET /library/similar`, `POST /library/recs/feedback` | More like this, Not interested |
| `GET /library/statistics?from=&to=` | Calendar-year Wrapped |
| `/social/*` endpoints (§5.3) | Activity, reactions, recommendations, shared collections |
| First four member covers on `GET /library/collections` | Fanned collection stacks without N+1 calls |
| `tag_ids` on `FollowedSeries` list rows | The Library tag filter and tag dots on posters without a join per series |

Every shared cache applies the 18+ gate when serving, never when storing.

### 9.5 Performance budget (flagship-only, maximum effects)

- 120 Hz target on the owner's iPhone and Android flagship; profile with the Diagnostics screen's FPS and jank readouts.
- At most two stacked glass layers; all backdrop filters on a Flutter screen in one `BackdropGroup`; `GlassQuality.premium` only on static chrome, `standard` inside scroll views; web refraction maps rebuilt only at rest.
- The ambient field is three radial gradients (web: one fixed element; Flutter: one `CustomPaint` with `RadialGradient` shaders), not live blur filters; the blur tokens describe the look.
- Per-letter reveals capped at 60 graphemes; skeleton sheen is one gradient per element; physics simulations (genre field, Wrapped pile) cap their bodies (24 bubbles, 200 glyphs) and sleep when at rest.
- Sensors run only while a screen that uses them is visible (hero, detail, reader, flame, genre field), sampled at 30 Hz.
- The reader's image pipeline (decode budget, prefetch, extents) is the shared engine's and is never touched by the skin.

### 9.6 Checks

- **One runnable physics check per platform:** `physics.test.ts` (vitest) and `glass_physics_test.dart` assert: `project(0, 1000) ≈ 499`; `rubberband(100, 800, 0.55) ≈ 51.5`; `{ms: 520, bounce: 0}` → k 146.0, c 24.17; `{ms: 150, bounce: 0.14}` → k 1754.6, c 72.05; rail snap of offset 310 with velocity 900 and stride 136 lands on 816.
- **Completeness and boundary** tests from `stack-decision.md` §2.2–2.3 (every `ScreenId` has a Glass screen; Glass imports only the shared data layer and its own primitives).
- **Screenshots:** the Flutter screenshot harness and Playwright at 440 × 956 @3 for each cluster, both skins, side by side.
- **Device gate:** the `liquid_glass_widgets` tab bar + detented sheet over a scrolling rail at 120 Hz on the iPhone and the Android flagship in the foundation week; if it fails on the iPhone, `SkinGlass` switches to `BackdropFilter` frost with a painted rim, and only that one file changes.
- **Accessibility pass:** focus order and rings on every screen, labels on every icon button, the gesture alternatives of §3.34–3.35, Reduce Motion and Solid glass snapshots, VoiceOver and TalkBack custom actions on swipe rows.

### 9.7 Build order inside Glass

1. Tokens, physics helpers and their checks; `SkinGlass` and `GlassSurface`; the device gate.
2. Primitives (buttons, chips, segmented, sheet, menu, toast, sliders, switch) with their states.
3. Shell: dock, orb, accessory, sidebar, command palette, routes and transitions.
4. Home and Library, then series detail and the book page.
5. Reader chrome (manga, then novel), listen mode.
6. Search, Sources, Updates, Downloads, dialogue search, You, Settings (with the restart flow), admin, status screens.
7. The four new features in the order AI home, statistics and Wrapped, ambient extras, social (the last needs the most backend).
