---
version: alpha
name: ManhwaManiacs-Cinematic-visual-language
description: |
  The "Cinematic" skin of ManhwaManiacs. The app is a dark theater, the chrome is the house lights and the series art is the film. Full-bleed covers sit under eased black scrims. Ambient color from the artwork spills onto the AMOLED-black page. A condensed variable display face builds film-title treatments, since manhwa have no logo art. A humanist sans carries everything you read. Motion follows film grammar: cuts, dissolves, dips to black, match cuts, Ken Burns drift and letterbox mattes. It never springs or bounces, because springs belong to the Glass skin. Film grain, vignette and bloom texture the art and never the text. Loading is staged as a pre-roll, not a spinner. The UI is monochrome projector white on black. The one brand color is Tungsten amber (#FFB547), which appears in small marks only. Depth comes from light and camera movement, never from frosted panes or tilting objects.

colors:
  canvas: "#000000"
  raised: "#0E0E0E"
  overlay: "#161616"
  well: "#1E1E1E"
  hairline: "rgba(255,255,255,0.08)"
  hairline-strong: "rgba(255,255,255,0.16)"
  ink: "#F5F5F1"
  ink-2: "rgba(245,245,241,0.64)"
  ink-3: "rgba(245,245,241,0.48)"
  ink-4: "rgba(245,245,241,0.24)"
  tungsten: "#FFB547"
  tungsten-pressed: "#E89A2C"
  tungsten-glow: "rgba(255,181,71,0.45)"
  on-tungsten: "#000000"
  rating: "#FF5C5C"
  positive: "#3DD68C"
  info: "#7AB8FF"
  scrim-modal: "rgba(0,0,0,0.72)"
  ambient-glow-fallback: "#573E19"
  ambient-tint-fallback: "#18130C"
  ambient-accent-fallback: "#FFB547"

typography:
  display-hero:
    fontFamily: Mona Sans
    fontSize: clamp(44px, 7vw, 120px)
    fontWeight: 850
    fontWidth: 75
    lineHeight: 0.86
    letterSpacing: -0.025em
    textTransform: uppercase
  display-lg:
    fontFamily: Mona Sans
    fontSize: clamp(36px, 4.6vw, 76px)
    fontWeight: 800
    fontWidth: 75
    lineHeight: 0.9
    letterSpacing: -0.02em
    textTransform: uppercase
  display-md:
    fontFamily: Mona Sans
    fontSize: 40px (mobile 32px)
    fontWeight: 780
    fontWidth: 80
    lineHeight: 0.95
    letterSpacing: -0.015em
    textTransform: uppercase
  heading-section:
    fontFamily: Mona Sans
    fontSize: 26px (mobile 21px)
    fontWeight: 760
    fontWidth: 85
    lineHeight: 1.0
    letterSpacing: -0.01em
    textTransform: uppercase
  heading-card:
    fontFamily: Mona Sans
    fontSize: 17px
    fontWeight: 700
    fontWidth: 90
    lineHeight: 1.15
    letterSpacing: -0.005em
  editorial-lg:
    fontFamily: Instrument Serif
    fontSize: 56px (mobile 40px)
    fontWeight: 400
    lineHeight: 1.0
    letterSpacing: -0.01em
  editorial-md:
    fontFamily: Instrument Serif
    fontSize: 28px
    fontWeight: 400
    lineHeight: 1.1
    letterSpacing: 0
  eyebrow:
    fontFamily: Source Sans 3
    fontSize: 12px
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: 0.18em
    textTransform: uppercase
  body-lg:
    fontFamily: Source Sans 3
    fontSize: 17px
    fontWeight: 400
    lineHeight: 1.55
    letterSpacing: 0
  body:
    fontFamily: Source Sans 3
    fontSize: 15px
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: 0
  body-strong:
    fontFamily: Source Sans 3
    fontSize: 15px
    fontWeight: 600
    lineHeight: 1.4
    letterSpacing: 0
  label:
    fontFamily: Source Sans 3
    fontSize: 15px
    fontWeight: 600
    lineHeight: 1.0
    letterSpacing: 0.01em
  caption:
    fontFamily: Source Sans 3
    fontSize: 13px
    fontWeight: 400
    lineHeight: 1.4
    letterSpacing: 0
    fontVariantNumeric: tabular-nums
  timecode:
    fontFamily: Source Sans 3
    fontSize: 13px
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: 0.04em
    fontVariantNumeric: tabular-nums
  micro:
    fontFamily: Source Sans 3
    fontSize: 11px
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: 0.08em
    textTransform: uppercase

rounded:
  none: 0px
  hair: 2px
  frame: 6px
  sheet: 12px
  full: 9999px

spacing:
  2xs: 4px
  xs: 8px
  sm: 12px
  md: 16px
  lg: 24px
  xl: 32px
  2xl: 48px
  3xl: 64px
  4xl: 96px
  gutter: clamp(16px, 4.5vw, 72px)
  rail-gap: 8px
  rail-stack: 40px (mobile 28px)

motion:
  easing:
    cine-out: cubic-bezier(0.16, 1, 0.3, 1)
    cine-in: cubic-bezier(0.7, 0, 0.84, 0)
    cine-in-out: cubic-bezier(0.65, 0, 0.35, 1)
    drift: cubic-bezier(0.37, 0, 0.63, 1)
    sweep: linear
  duration:
    cut: 0ms
    tick: 90ms
    quick: 160ms
    base: 280ms
    scene: 480ms
    dissolve: 800ms
    letter: 700ms
    letter-blur: 500ms
    letter-stagger: 28ms (total stagger capped at 600ms)
    type-char: 50ms
    caret-blink: 530ms
    kenburns: 24000ms
    preroll: 1600ms
    hero-rotate: 8000ms
    dwell-backdrop: 450ms
    dwell-preview: 700ms
    rating-hold: 4000ms
    endcard-countdown: 5000ms
  springs: none

components:
  button-primary:
    backgroundColor: "{colors.ink}"
    textColor: "#000000"
    typography: "{typography.label}"
    rounded: "{rounded.frame}"
    height: 44px (mobile 48px)
    padding: 0 22px 0 18px
    icon: 20px leading, 8px gap
  button-primary-pressed:
    backgroundColor: "#D6D6D2"
    transform: scale(0.97)
  button-secondary:
    backgroundColor: "rgba(255,255,255,0.14)"
    backgroundColorHover: "rgba(255,255,255,0.22)"
    textColor: "{colors.ink}"
    typography: "{typography.label}"
    rounded: "{rounded.frame}"
    height: 44px (mobile 48px)
  button-icon-round:
    size: 40px (mobile 44px)
    backgroundColor: "rgba(0,0,0,0.4)"
    border: 1.5px solid rgba(245,245,241,0.4)
    borderHover: 1.5px solid "{colors.ink}"
    rounded: "{rounded.full}"
  button-text:
    textColor: "{colors.ink-2}"
    textColorHover: "{colors.ink}"
    typography: "{typography.label}"
  focus-ring:
    outline: 2px solid "{colors.ink}"
    outlineOffset: 3px
  poster:
    aspectRatio: 2 / 3
    rounded: "{rounded.frame}"
    backgroundColor: "{colors.raised}"
    innerHairline: inset 0 0 0 1px rgba(255,255,255,0.06)
  poster-hover:
    transform: scale(1.06)
    filter: brightness(1.08)
    shadow: 0 0 56px -12px "{ambient.glow}"
  rail-sibling-dim:
    filter: brightness(0.55) saturate(0.8)
  badge-new:
    backgroundColor: "{colors.tungsten}"
    textColor: "{colors.on-tungsten}"
    typography: "{typography.micro}"
    rounded: "{rounded.hair}"
    padding: 3px 6px
  badge-rating:
    backgroundColor: transparent
    border: 1px solid "{colors.rating}"
    textColor: "{colors.rating}"
    typography: "{typography.micro}"
    rounded: "{rounded.hair}"
    padding: 2px 5px
  progress:
    height: 3px
    track: "rgba(255,255,255,0.2)"
    fill: "{colors.tungsten}"
    rounded: "{rounded.none}"
  tab-slate:
    typography: "{typography.eyebrow}"
    textColor: "{colors.ink-3}"
    textColorActive: "{colors.ink}"
    indicator: 2px "{colors.tungsten}" bar under the active label, animates x/width over 280ms cine-out
  nav-top-desktop:
    height: 68px
    backgroundColor: transparent over hero, "{colors.canvas}" after 80px scroll (280ms)
    scrim: "{scrims.top-chrome}"
  nav-bottom-mobile:
    height: 56px + safe area
    backgroundColor: "{colors.canvas}"
    borderTop: 1px "{colors.hairline}"
    label: "{typography.micro}"
    active: "{colors.ink}" icon + label, 4px "{colors.tungsten}" dot above the icon
    inactive: "{colors.ink-3}"
  sheet:
    backgroundColor: "{colors.overlay}"
    rounded: "{rounded.sheet} {rounded.sheet} 0 0"
    barrier: "{colors.scrim-modal}"
    blur: none
  input:
    backgroundColor: "{colors.well}"
    textColor: "{colors.ink}"
    placeholder: "{colors.ink-3}"
    rounded: "{rounded.frame}"
    height: 48px
    focus: border-bottom 2px "{colors.tungsten}" (underline, not a glow)
  toast:
    backgroundColor: "{colors.ink}"
    textColor: "#000000"
    rounded: "{rounded.hair}"
    placement: bottom-left desktop, bottom mobile, like a subtitle line
---

# Cinematic: the dark cinematic visual language

This document defines one of the two ManhwaManiacs skins. It takes from Netflix, Apple TV+ (Apple TV since 2025), Crunchyroll, HBO Max, Prime Video, A24, film title design and the PS5 UI. It is not a clone of any of them. Every token is mapped to the web client (Next.js 16.2.9, React 19.2.4, Tailwind 4, `framer-motion` 12.42.2) and to the Flutter client (3.22+, Riverpod, go_router). Binding owner decisions are in `inventory/00-decisions.md`: AMOLED `#000000` base, dark only, two required signature animations, flagship-only effects that still honor reduced motion, and a sound layer that is off by default.

Confidence markers used in tables: **V** means verified in a source this session, **O** means observed or widely reproduced from DevTools but not re-verified live, and **D** means our own derivation.

## 1. Overview

**Thesis.** The screen is a theater. The series art is the film. The UI is the house lights: dimmed, warm and mostly off. Everything cinematic here comes from four instruments:

1. **The frame.** Art is full-bleed, cropped to film proportions (2.39:1 scope, 16:9, 2:3 one-sheet). It is never a card floating in padding.
2. **The light.** Black scrims carve legibility out of the art. Ambient color spills from the art onto the black page, like a screen lighting a dark room. Bloom marks focus. Shadows are useless on `#000`, so depth is made of light.
3. **The camera.** Motion is camera motion: Ken Burns drift, parallax between layers, push-in, and dissolves and cuts between scenes. Objects never tilt, wobble or bounce.
4. **The titles.** Manhwa rarely have logo art, so typography is the title treatment. A condensed variable display face with tight tracking is revealed letter by letter like a trailer card.

**How this differs from Glass.** No translucency or backdrop blur panes. No springs. Radii are tight (2/6/12 px, pills only for round icon buttons and avatars). Transitions are cuts and dissolves, not physical sheets that rubber-band. Haptics are sparse and weighty: a few thuds, no constant ticking. If a component could be mistaken for its Glass twin, it is wrong.

**Key characteristics**
- Pure `#000000` canvas everywhere. Film grain uses `overlay` blend, which leaves true black untouched, so AMOLED pixels stay off.
- The UI is monochrome projector white `#F5F5F1`. Tungsten `#FFB547` is the only brand hue, and it is reserved for small marks: progress, NEW, streak flame, the active nav dot, the caret and input focus.
- Per-series ambient color (glow, tint and accent) is computed once on the backend and dissolves over 800 ms when the hero changes.
- Mona Sans, variable and condensed at `wdth 75`, sets uppercase title treatments. Source Sans 3 sets all reading text. Instrument Serif appears only on editorial "title card" moments.
- Two signature reveals: a per-letter fade, slide-up and un-blur, and a 50 ms/char typing reveal with a tungsten block caret.
- Poster rails: siblings dim when one poster has focus, focus stays fixed-left under keyboard control, the backdrop swaps on dwell, and a preview slate opens after 700 ms.
- Loading is a pre-roll: wordmark reveal, tungsten bloom, then a cut to Home. Images "focus-pull" in from blur. There are no grey shimmer bars.

## 2. Reference teardown: what to take and what to leave

| Reference | Take | Leave | Conf. |
|---|---|---|---|
| **Netflix** (web) | Near-black theater (`#141414` there; ours is `#000`). Billboard hero with a left 77° title vignette plus a bottom fade into the page. White primary "Play" button with 4 px radius and black text. Rails that overlap the billboard bottom. Hover card that expands to about 1.5× with an info panel and neighbors pushed or overlaid. Maturity-rating overlay at playback start. Post-play "next episode" countdown. 4 vw page gutter. | Netflix Red `#E50914`, the Top-10 red badge, autoplaying trailers with sound, and the "tudum" sonic logo (a brand asset, never imitate it). | O (tokens via oh-my-design.kr extraction; 1.5× hover scale and 4 vw gutter reproduced in clones) |
| **Apple TV / TV+** | Monochrome chrome that lets art carry color. tvOS 26 switched to **portrait poster art** for more density and a more cinematic look. That validates 2:3 manhwa covers as first-class. Focused item enlarges (about 1.05–1.1×). Background art changes with focus. | Liquid Glass, parallax tilt and specular sheen. Those belong to the Glass skin. | V (tvOS 26 portrait posters: Apple Newsroom and 9to5Mac); O (focus scale) |
| **Crunchyroll** | Fan-energy freshness: new-episode and simulcast recency, shown prominently with relative times. Series logo over key art on the hero. Watchlist as a verb. 2024 rebrand: orange, black, white and taupe with the custom "Crunchyroll Atyp" typeface, built for readability. | The orange (`#F47521` legacy) and taupe. Our accent is tungsten. | V (rebrand facts: DesignRush and Campaign; legacy orange: brand-color sites) |
| **HBO Max** | Prestige through restraint: black, few colors, editorial title art. **Brand hubs** (network or studio tiles). Our sources (MangaDex and the others) become "networks" in a hub row. The static-plus-choir intro shows that a sonic ident can be texture rather than melody. | Blue or purple gradients and the HBO static sound. | O |
| **Prime Video** | **X-Ray**, contextual info laid over playback. This maps onto OCR dialogue search as a side panel in the wide reader, styled like subtitles. Detail-page tabs (Episodes / Related / Details) map to Chapters / More like this / Details. | Dense promo stacking, store badges and the `#00A8E1` blue. | O |
| **A24 + trailers** | Title cards: white type centered on black between shots, 1.2 s holds and 600 ms fades. Wide negative space. Editorial serif moments. "Tracking out" end titles, where letter-spacing slowly widens. | Minimalism so extreme that navigation disappears. We are an app, not a one-sheet. | D |
| **Film title design** | *Stranger Things* (Imaginary Forces, 2016): letters converge slowly under a neon glow. That is our per-letter reveal plus bloom. *Se7en* (Kyle Cooper, 1995): jitter and hand-made texture, which becomes grain and flicker at the micro level only. Saul Bass: graphic cut shapes, which suit the Wrapped recap cards. SMPTE leader countdown becomes the loading sweep. | Pastiche. Nothing literally copies a title sequence. | D |
| **PS5 UI** | Horizontal-first navigation. The focused tile grows and its label appears. The **full-screen background swaps to the focused game's art**. White focus outline. Per-title ambient music fades in after dwell. Soft, musical UI clicks. Load times are treated as immersion-breakers (Sony's stated design goal). | PlayStation Blue, the rounded-square tile grid and the Control Center card stack. | V (horizontal navigation, background art enlarged for the focused icon, rounded tiles: whatbrentsay, Android Headlines, Frontline interview); O (sounds, focus ring) |

## 3. Color

### 3.1 Base palette

| Token | Value | Contrast on #000 | Use |
|---|---|---|---|
| `canvas` | `#000000` | n/a | Every screen background. AMOLED off. |
| `raised` | `#0E0E0E` | n/a | Poster placeholder, slate skeletons |
| `overlay` | `#161616` | n/a | Sheets, menus, preview slate body |
| `well` | `#1E1E1E` | n/a | Inputs, pressed rows |
| `hairline` | `rgba(255,255,255,.08)` | n/a | Dividers, poster inner edge |
| `ink` | `#F5F5F1` | 19.3:1 | Primary text, white buttons. Slightly warm "projector white", never `#FFF`. |
| `ink-2` | `rgba(245,245,241,.64)` ≈ `#9D9D9A` | 7.7:1 | Synopsis, secondary text |
| `ink-3` | `rgba(245,245,241,.48)` ≈ `#767674` | 4.6:1 | Metadata, captions, inactive nav. The lowest alpha that still passes AA. |
| `ink-4` | `rgba(245,245,241,.24)` | 2.0:1 | Disabled only, never information |
| `tungsten` | `#FFB547` | 11.9:1 | Brand marks: progress fill, NEW badge, streak flame, active-nav dot, caret, input focus underline, wordmark bloom |
| `tungsten-pressed` | `#E89A2C` | n/a | Pressed tungsten surfaces |
| `rating` | `#FF5C5C` | 6.9:1 | 18+ badge and rating card bar, errors, destructive actions |
| `positive` | `#3DD68C` | high | Downloaded, synced, success |
| `info` | `#7AB8FF` | high | Rare informational notes |
| `scrim-modal` | `rgba(0,0,0,.72)` | n/a | Barrier behind sheets and dialogs. **No blur.** |

Why tungsten: it is the color of projector bulbs, marquee lights and 3200 K film light. It is unclaimed by the references (Netflix red, Crunchyroll orange, Prime blue, PS blue, HBO purple), and it passes AAA as text on black and as a fill under black text.

### 3.2 Ambient color, extracted from artwork

Three roles are derived per series from its cover:

| Role | Rule (HLS) | Where it appears |
|---|---|---|
| `ambient.glow` | Seed hue, L = 0.22, S = min(S, 0.55) | Poster hover bloom shadow, back-light behind the hero title block (radial, 20 % opacity), reader chrome tint |
| `ambient.tint` | Seed hue, L = 0.07, S = min(S, 0.35) | The color the hero scrim fades *into*, and the page-top light spill below the hero. It is near black, but the room is lit by the screen. |
| `ambient.accent` | Seed hue, L = 0.70, S = clamp(S, 0.45, 0.85); raise L in 0.04 steps until contrast on #000 is ≥ 4.5:1 | Detail page only: unread-chapter dots, the active chapter row edge, genre separators. Never the primary CTA, which stays `ink`. |

**Pipeline (one extraction, both clients).** Compute ambient color on the backend, next to cover resizing in `backend/services/image_resize.py`, and cache it with the cover in `SourceCacheService.get_series_cover`. Serve it as `ambient: {glow, tint, accent}` in series payloads. This needs Pillow 12.3.0, which is already a dependency, plus stdlib `colorsys`, and no new package. Both clients then read three hex strings. Nothing is computed on the phone, and web never has to read canvas pixels from a cookie-gated cover route.

```python
import colorsys
from PIL import Image

def ambient(img: Image.Image) -> dict[str, str]:
    # ponytail: HLS, not OKLCH. Perceptual unevenness across hues is tolerable at these
    # clamped lightnesses. Switch to OKLCH if blues read darker than yellows side by side.
    pal = img.convert("RGB").resize((48, 48), Image.Resampling.BILINEAR).quantize(8, method=Image.Quantize.MEDIANCUT)
    rgb = pal.getpalette()[:24]
    best, hs = -1.0, (0.1, 0.0)                     # fallback: tungsten hue, no saturation
    for count, i in pal.getcolors():
        h, l, s = colorsys.rgb_to_hls(*(v / 255 for v in rgb[i * 3:i * 3 + 3]))
        if 0.08 < l < 0.94 and count * (0.35 + s) > best:
            best, hs = count * (0.35 + s), (h, s)
    h, s = hs
    hx = lambda l, s: "#%02x%02x%02x" % tuple(round(c * 255) for c in colorsys.hls_to_rgb(h, l, s))
    return {"glow": hx(0.22, min(s, 0.55)), "tint": hx(0.07, min(s, 0.35)), "accent": hx(0.70, min(max(s, 0.45), 0.85))}
```

Fallbacks when a cover is missing or pure greyscale: glow `#573E19`, tint `#18130C` and accent `#FFB547` (tungsten at the same lightnesses).

**Live reader tint.** The "reader chrome tinted by the current page" feature cannot use the backend, because pages are client-side downloads.
- Web: draw the current page into a 16×16 `OffscreenCanvas`, then take the most saturated of the 256 pixels that has L between 0.1 and 0.9. Blob URLs from the client store are same-origin, so there is no canvas taint.
- Flutter: use `ColorScheme.fromImageProvider(provider: ResizeImage(FileImage(f), width: 64), brightness: Brightness.dark)`. This is in Flutter core and uses material_color_utilities (Celebi quantizer plus scoring). Take `.primaryContainer` for the chrome tint.
- Recompute only when the page changes, and dissolve over 800 ms.

**Do not add `palette_generator`.** The Flutter team discontinued it (announced Feb 2025, flutter/flutter#162963). The third-party `palette_generator_master` is an unvetted rewrite, and nothing here needs it.

**Animating the color itself.**
- Web: register the variables so the browser interpolates them (Chrome 85+, Safari 16.4+, Firefox 128+):
  ```css
  @property --amb-glow { syntax: "<color>"; inherits: true; initial-value: #573E19; }
  @property --amb-tint { syntax: "<color>"; inherits: true; initial-value: #18130C; }
  :root { transition: --amb-glow 800ms var(--ease-cine-in-out), --amb-tint 800ms var(--ease-cine-in-out); }
  ```
- Flutter: `TweenAnimationBuilder<Color?>(tween: ColorTween(end: ambient.tint), duration: 800.ms, curve: cineInOut, ...)` wrapped around the page background and the scrim builder.

## 4. Scrims and gradients (exact stops)

Linear black-to-transparent gradients band and show a visible "edge". Every long fade uses Andreas Larsen's eased **scrim** curve (CSS-Tricks, "Easing Linear Gradients"), reversed so it runs from transparent to opaque:

| Stop | 0% | 1.8% | 4.8% | 9% | 13.9% | 19.8% | 27% | 35% | 43.5% | 53% | 66% | 81% | 100% |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Alpha | 0 | .002 | .008 | .021 | .042 | .075 | .126 | .194 | .278 | .382 | .541 | .738 | 1 |

| Scrim | Geometry | Stops |
|---|---|---|
| **hero-bottom** | Bottom 55 % of the hero (mobile: bottom 70 %), top → bottom | Eased scrim above, end color `var(--amb-tint)` (not pure black), so the hero dissolves into the lit page |
| **hero-title** (desktop and tablet only) | Full hero, 77° (the Netflix billboard angle) | `rgb(0 0 0/.82) 0%, rgb(0 0 0/.56) 24%, rgb(0 0 0/.22) 46%, rgb(0 0 0/0) 68%` |
| **top-chrome** | Top 128 px desktop / safe-area + 64 px mobile | `rgb(0 0 0/.72) 0%, rgb(0 0 0/.38) 50%, rgb(0 0 0/0) 100%` |
| **vignette** | Full frame, radial | `radial-gradient(125% 95% at 50% 40%, rgb(0 0 0/0) 58%, rgb(0 0 0/.5) 100%)` |
| **poster-caption** | Bottom of a poster, only in the preview slate or focus state | `linear-gradient(to top, rgb(0 0 0/.9) 0%, rgb(0 0 0/.6) 30%, rgb(0 0 0/0) 60%)` |
| **title-backlight** | Behind the hero title block | `radial-gradient(60% 55% at 22% 70%, color-mix(in oklab, var(--amb-glow) 20%, transparent) 0%, transparent 70%)` |
| **page-spill** | Page background under the hero | `linear-gradient(to bottom, var(--amb-tint) 0, var(--amb-tint) var(--hero-h), #000 calc(var(--hero-h) + 60svh))` |
| **rail-edge** (desktop) | 4 vw at each rail end, over the paddles | `linear-gradient(to right, #000 0%, rgb(0 0 0/0) 100%)` (short enough that it does not band) |

Hero layer order, from bottom to top: page-spill → hero art (Ken Burns) → grain (overlay blend) → vignette → hero-title → hero-bottom → title-backlight → content → top-chrome.

**Flutter.** The 77° CSS angle becomes `begin: Alignment(-1, 0.23)`, `end: Alignment(1, -0.23)`, because tan 13° = 0.23.

```dart
const _scrimStops = [0.0, .018, .048, .09, .139, .198, .27, .35, .435, .53, .66, .81, 1.0];
const _scrimAlpha = [0.0, .002, .008, .021, .042, .075, .126, .194, .278, .382, .541, .738, 1.0];

LinearGradient cineScrim(Color end, {Alignment begin = Alignment.topCenter, Alignment finish = Alignment.bottomCenter}) =>
    LinearGradient(begin: begin, end: finish, stops: _scrimStops,
        colors: [for (final a in _scrimAlpha) Color.fromRGBO(end.red, end.green, end.blue, a)]);
```

## 5. Frame: letterbox proportions and safe areas

| Ratio | Name | Where |
|---|---|---|
| **2.39:1** | Scope | Desktop hero (≥1280 px): `height: clamp(560px, 41.84vw, 88svh)`. Letterbox-bar transitions. Reader "curtain". |
| **16:9** | HD | Tablet hero (768–1279: `56.25vw`, min 420 px). Continue-reading cards. Source "network" hub tiles. |
| **2.00:1** | Univisium (common on streaming originals) | "Previously on…" recap banner. Preview slate backdrop. |
| **4:5** | Portrait hero | Mobile hero (`aspect-ratio: 4/5; max-height: 78svh`), full-bleed edge to edge |
| **2:3** | One-sheet poster (27×40 in ≈ 0.675) | Every cover and poster, everywhere |
| **9:16** | Story | Shareable stat cards (Wrapped, streaks) |

**Portrait art in a scope frame.** Sources give portrait covers, not banners. In a 2.39:1 frame a 2:3 cover shows about 28 % of its height, so the hero *tilts down* the cover instead of cropping it statically: `object-position` goes from `50% 12%` to `50% 42%` over the 24 s Ken Burns cycle. Faces sit in the upper third of most covers, so they get the first beat. The same cover, blurred 60 px at 0.5 brightness, fills any area the crop leaves bare.

**Title safe.** SMPTE uses 90 % action-safe and 80 % title-safe. We use the gutter `clamp(16px, 4.5vw, 72px)` as the horizontal title-safe inset. It lands near Netflix's 4 vw. Hero title blocks are bottom-left, `max-width: min(40vw, 640px)`, with their baseline at 26 % of hero height from the bottom. The first rail overlaps the hero by `-96px` (mobile `-40px`) into the scrim.

**Letterbox bars as a motif.** Two `#000` bars (top and bottom) with height `max(0px, (100svh - 100vw / 2.39) / 2)`.
- Web: animate `transform: scaleY(0 → 1)` from their outer edges. The compositor handles it and layout never moves.
- Flutter: flutter_animate `.scaleY(alignment: Alignment.topCenter)`.

The bars are used in exactly three places:
1. **Reader curtain.** Detail → reader: the bars close to black in 320 ms with `cine-in`, hold for 80 ms, then open onto the first page in 600 ms with `cine-out`. This happens only on entry from detail, never between chapters.
2. **Pre-roll.** Section 11.
3. **Wrapped recap.** Each stat "scene" plays inside a 2.39:1 matte on desktop.

## 6. Typography

### 6.1 Families

All three are self-hosted and bundled; there is no runtime fetch, matching the app's existing rule. All are OFL-1.1.

| Role | Family | Axes used | Source | Why |
|---|---|---|---|---|
| Display / title treatments | **Mona Sans** v2 (GitHub) | `wdth` 75–125, `wght` 200–900 (we use `wdth` 75–90, `wght` 700–900) | github.com/github/mona-sans | A condensed grotesk at `wdth 75` has the energy of Netflix Sans and trailer type. The width axis is *animatable*, which enables the trailer "track-out" end title. |
| Body / UI (humanist) | **Source Sans 3** (Adobe) | `wght` 200–900 | github.com/adobe-fonts/source-sans | A humanist sans that stays open at 11–13 px on black. Real tabular figures for timecode and counts. Wide Latin coverage including Vietnamese. |
| Editorial title cards | **Instrument Serif** (Instrument) | Regular + Italic | github.com/Instrument/instrument-serif | An A24-style condensed display serif for "Previously on…", Wrapped, novel covers and empty-state title cards. Nowhere else. |

**Hangul, kana and Han** (alternate titles): fall back to system faces (Apple SD Gothic Neo / Hiragino on iOS, Noto Sans CJK on Android and web). They cannot be condensed, so CJK title treatments drop `uppercase` and use `wdth`-free heavy weight. This is a known gap (section 16).

**Web loading.** Load fonts with `next/font/local` using variable woff2 files. The display face uses `display: "block"` and is preloaded, because a FOUT mid-reveal would wreck the signature animation. Body uses `"swap"`. Set width with `font-variation-settings: "wdth" 75` in a small `@utility` so it stays animatable.

**Flutter.** Bundle variable TTFs the way the current app already does. Use `fontVariations: [FontVariation('wght', 850), FontVariation('wdth', 75)]`.

### 6.2 Scale

| Token | Size (desktop / mobile) | Weight · wdth | LH | Tracking | Case | Use |
|---|---|---|---|---|---|---|
| display-hero | clamp(44, 7vw, 120) px | 850 · 75 | 0.86 | -0.025em | UPPER | Hero series title, pre-roll wordmark |
| display-lg | clamp(36, 4.6vw, 76) px | 800 · 75 | 0.90 | -0.02em | UPPER | Detail page title |
| display-md | 40 / 32 px | 780 · 80 | 0.95 | -0.015em | UPPER | Page titles (Library, Sources) |
| heading-section | 26 / 21 px | 760 · 85 | 1.0 | -0.01em | UPPER | **H3 rail and section headers (per-letter reveal)** |
| heading-card | 17 px | 700 · 90 | 1.15 | -0.005em | Sentence | Preview slate title, list titles |
| editorial-lg | 56 / 40 px | 400 | 1.0 | -0.01em | Sentence, italic allowed | "Previously on", Wrapped headlines |
| editorial-md | 28 px | 400 | 1.1 | 0 | Sentence | Pull-quotes, empty states |
| eyebrow | 12 px | 600 | 1.2 | +0.18em | UPPER | "MANHWA · ONGOING · 2024" over titles, tab labels |
| body-lg | 17 px | 400 | 1.55 | 0 | Sentence | Synopsis (ink-2), max 62ch |
| body | 15 px | 400 | 1.5 | 0 | Sentence | Default text |
| body-strong | 15 px | 600 | 1.4 | 0 | Sentence | Emphasis, list primary |
| label | 15 px | 600 | 1.0 | +0.01em | Sentence | Buttons: "Read", "Continue Ch. 142" |
| caption | 13 px | 400 | 1.4 | 0 | Sentence | Metadata (ink-3), tabular-nums |
| timecode | 13 px | 600 | 1.2 | +0.04em | n/a | "CH 142 · 12 MIN LEFT", "2H AGO", tabular-nums |
| micro | 11 px | 600 | 1.3 | +0.08em | UPPER | Badges, bottom-nav labels |

**Title treatment recipe.** This is the logo substitute for a series.
1. Eyebrow line: format · status · year, in ink-2.
2. Title in display-hero, uppercase, `wdth 75`, lines balanced with `text-wrap: balance` (Flutter: `TextWidthBasis.longestLine` plus a max width).
3. Tungsten 3 px × 32 px rule under the title. It draws in left to right over 480 ms `cine-out` after the letters land.
4. A one-line hook or genres in body-lg ink-2.

Titles over 28 characters step down one size. Titles over 48 characters use display-lg.

## 7. Texture and light

### 7.1 Film grain

- **Where:** hero, detail backdrop, pre-roll, Wrapped and the preview slate backdrop. **Never** in the reader, on text surfaces or on lists.
- **Intensity:** 0.07 (pre-roll peaks at 0.12 while "warming up").
- **Rate:** 12 fps. Cinema grain changes every frame at 24 fps. 12 fps reads as grain and halves the work.
- **Blend: `overlay`.** Overlay leaves `#000` at `#000` (2·base·blend = 0), so grain textures only the midtones of the art. AMOLED blacks stay off, and it vanishes over black UI for free.

Web (zero assets, composited):
```css
.grain { position: relative; isolation: isolate; overflow: hidden; }
.grain::after {
  content: ""; position: absolute; inset: -100%; pointer-events: none;
  opacity: .07; mix-blend-mode: overlay;
  background: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='256' height='256'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.85' numOctaves='3' stitchTiles='stitch'/%3E%3CfeColorMatrix type='saturate' values='0'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");
  animation: grain .66s steps(1) infinite;
}
@keyframes grain {
  0% { transform: translate(0,0) }        12.5% { transform: translate(-7%,4%) }
  25% { transform: translate(5%,-9%) }    37.5% { transform: translate(-3%,8%) }
  50% { transform: translate(9%,2%) }     62.5% { transform: translate(-8%,-5%) }
  75% { transform: translate(3%,7%) }     87.5% { transform: translate(-5%,-2%) }
}
```

Flutter uses a native `FragmentProgram` with no package. Declare it in `pubspec.yaml` under `flutter: shaders: - shaders/grain.frag`, then paint it as the `foregroundPainter` of the hero art with `Paint()..shader = s..blendMode = BlendMode.overlay`. Drive `uTime` from a `Ticker`, quantized to 1/12 s.
```glsl
#version 460 core
#include <flutter/runtime_effect.glsl>
uniform vec2 uSize;
uniform float uTime;       // seconds, quantized to 1/12
uniform float uIntensity;  // 0.07
out vec4 fragColor;
float hash(vec2 p) { p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
void main() {
  vec2 px = floor(FlutterFragCoord().xy / 1.5);            // ~1.5 px grain
  float n = hash(px + floor(uTime * 12.0) * vec2(17.0, 59.0));
  fragColor = vec4(vec3(n), 1.0) * uIntensity;              // premultiplied; overlay keeps black black
}
```
`flutter_shaders` 0.1.3 (BSD-3) is not needed. Its `AnimatedSampler` is for sampling child pixels, and grain is generative.

### 7.2 Vignette

This is the radial scrim from section 4, always on hero and detail art. It deepens to `.62` at the edges during the reader curtain and the pre-roll.

### 7.3 Bloom

Bloom is how focus is marked. It stands in for shadow, which is invisible on `#000`.

| Target | Web | Flutter |
|---|---|---|
| Poster hover and focus | `box-shadow: 0 0 56px -12px var(--amb-glow)` using that poster's own glow, 280 ms `cine-out` | `BoxShadow(color: glow.withOpacity(.9), blurRadius: 56, spreadRadius: -12)` animated with `AnimatedContainer` |
| Hero art | A duplicate `<img aria-hidden>` behind the art, `filter: blur(40px) saturate(1.6) brightness(1.1)`, `opacity: .5`, `inset: -8%` | `ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40))` over the 96 px cover, `Opacity(.5)` |
| Wordmark and tungsten rule | `text-shadow: 0 0 18px rgb(255 181 71/.45), 0 0 2px rgb(255 181 71/.6)` | `Shadow(color: Color(0x73FFB547), blurRadius: 18)` + `Shadow(color: Color(0x99FFB547), blurRadius: 2)` |
| Primary CTA focus | `box-shadow: 0 0 0 3px #000, 0 0 0 5px #F5F5F1, 0 0 32px rgb(245 245 241/.25)` | Same composed as a `BoxShadow` list |

## 8. Motion: film grammar

**Principles**
1. **Camera, not objects.** Layers translate and scale like a camera moving. Nothing rotates in 3D, wobbles or overshoots.
2. **Decisive in, quiet out.** Entrances use `cine-out`, a long exponential settle. Exits use `cine-in` and run 0.75× as long as their entrance.
3. **Cuts are allowed.** A 0 ms change is a legitimate transition when the context doesn't change.
4. **Slow things are very slow.** Ambient motion (Ken Burns, grain, glow) runs at 8–24 s periods so it never pulls the eye.

**Tokens**

| Token | Value | Web (Tailwind 4 / CSS) | Flutter |
|---|---|---|---|
| cine-out | `cubic-bezier(0.16, 1, 0.3, 1)` | `--ease-cine-out` → `ease-cine-out` | `const cineOut = Cubic(0.16, 1, 0.3, 1);` |
| cine-in | `cubic-bezier(0.7, 0, 0.84, 0)` | `--ease-cine-in` | `Cubic(0.7, 0, 0.84, 0)` |
| cine-in-out | `cubic-bezier(0.65, 0, 0.35, 1)` | `--ease-cine-in-out` | `Cubic(0.65, 0, 0.35, 1)` |
| drift | `cubic-bezier(0.37, 0, 0.63, 1)` (sine) | `--ease-drift` | `Curves.easeInOutSine` |
| durations | tick 90 · quick 160 · base 280 · scene 480 · dissolve 800 ms | `--duration-*` / `duration-[280ms]` | `Duration(milliseconds: …)` or flutter_animate `280.ms` |

### 8.1 Transitions

| Film term | App moment | Spec | Web | Flutter |
|---|---|---|---|---|
| **Cut** | Library filter change, sort change, tab within the same page | 0 ms. The content swaps, then items get the image focus-pull (section 11). | Plain render | Plain rebuild |
| **Dip to black** | Section switch (bottom nav or sidebar) | Out: opacity 1→0, 120 ms `cine-in`. Hold `#000` 40 ms. In: 0→1, 240 ms `cine-out`. | Route layout wrapper with `AnimatePresence mode="wait"` | go_router `CustomTransitionPage` with a `FadeTransition` pair on `Interval(0, .33)` / `Interval(.4, 1)` of a 400 ms controller |
| **Match cut** | Poster → detail hero; cover → reader-curtain | Shared poster morphs to the hero frame, 480 ms `cine-in-out`, radius 6→0. Everything else fades 280 ms. | View Transitions API: `view-transition-name: poster-<id>` with `document.startViewTransition(() => router.push(href))`. Next 16's `experimental.viewTransition` with React `<ViewTransition>` is still experimental in 19.2, so the manual call is the safe path. | `Hero(tag: 'poster-$id')` with a `flightShuttleBuilder` that lerps `BorderRadius` 6→0 and uses `createRectTween: (a, b) => MaterialRectCenterArcTween(begin: a, end: b)` |
| **Dissolve** | Hero rotation, backdrop swap on dwell, ambient color change | Crossfade 800 ms `cine-in-out`. The old image holds while the new one fades over it. | Two stacked `<img>` with opacity transition | `AnimatedSwitcher(duration: 800.ms, switchInCurve: cineInOut)` |
| **Push-in** | Opening the reader from detail | Scale 1→1.04 plus fade to black, 320 ms `cine-in`, then the letterbox curtain opens (section 5) | Motion `animate` on the page wrapper | flutter_animate `.scale().fadeOut()` |
| **Fade up from black** | Sheets, dialogs, preview slate | Barrier 0→.72 over 240 ms. Sheet rises 24 px + fades in, 360 ms `cine-out`. Dismiss 240 ms `cine-in`. No blur, no bounce. | Motion `initial={{ y: 24, opacity: 0 }}` | `showModalBottomSheet(sheetAnimationStyle: AnimationStyle(duration: 360.ms, reverseDuration: 240.ms))`. If the curve must be `cine-out` exactly, use a custom `PopupRoute`. |
| **End card** | Reaching the end of a chapter | "NEXT — CH 143" slate. **Only when auto-scroll is on**, a 5 s leader-sweep countdown auto-advances. Tap or Enter goes now. Esc or a scroll up cancels. | Section 11 sweep | Section 11 sweep |
| **Back** | Any reverse navigation | The reverse of the forward move at 0.75× duration | Same | Same |

### 8.2 Ken Burns

- **Where:** hero, detail backdrop, Wrapped scenes. Never on posters in rails.
- **Move:** scale 1.00 → 1.10 over **24 000 ms**, `drift`, `alternate`, infinite. Combine it with the portrait tilt-down (`object-position` 50% 12% → 50% 42%).
- **Direction:** one of 4 push-in corners, seeded from `hash(series_id) % 4`, so a series always moves the same way. Continuity matters.
- **Lifecycle:** pause when off-screen (IntersectionObserver on web; Flutter's `TickerMode` pauses covered routes). Restart from frame 0 on hero change, *under* the dissolve.

```css
/* Tailwind 4 @theme (see section 14) */
--animate-kenburns: kenburns 24s var(--ease-drift) infinite alternate;
@keyframes kenburns {
  from { transform: scale(1);   object-position: 50% 12%; }
  to   { transform: scale(1.1) translate3d(-1.5%, -2%, 0); object-position: 50% 42%; }
}
```
```dart
Image(image: cover, fit: BoxFit.cover, alignment: Alignment.topCenter)
  .animate(onPlay: (c) => c.repeat(reverse: true))
  .custom(duration: 24.s, curve: Curves.easeInOutSine, builder: (_, t, child) =>
      Transform.scale(scale: 1 + .1 * t, child: Align(alignment: Alignment(0, -.76 + .6 * t), child: child)));
```
The Flutter `Alignment` y range from -0.76 to -0.16 is the same as `object-position` 12 % → 42 %.

### 8.3 Parallax

| Layer | Rule |
|---|---|
| Hero art | `translateY` 0 → 30 % of hero height as the hero scrolls out (factor 0.3) |
| Hero title block | `translateY` 0 → -12 %. Opacity 1 → 0 by 55 % scroll progress. |
| Detail backdrop | Factor 0.35 |
| Mobile overscroll (pull down on hero) | Stretch-zoom up to scale 1.15 at 120 px pull |
| Rails, posters, text | **None.** Parallax on small objects causes nausea and adds nothing. |

Web: `const { scrollYProgress } = useScroll({ target: heroRef, offset: ["start start", "end start"] }); const y = useTransform(scrollYProgress, [0, 1], ["0%", "30%"]);`

Flutter (native, no package): the hero is a `SliverAppBar(expandedHeight: …, stretch: true, flexibleSpace: FlexibleSpaceBar(collapseMode: CollapseMode.parallax, stretchModes: [StretchMode.zoomBackground, StretchMode.fadeTitle]))`. The built-in parallax factor is fixed. If it must be exactly 0.3, swap to a `LayoutBuilder` on `FlexibleSpaceBarSettings` (about 10 lines).

## 9. Signature animations (required)

### 9.1 Per-letter reveal: fade + slide-up + un-blur

**Spec**

| Property | Value |
|---|---|
| Split | Graphemes. Web: `Intl.Segmenter(undefined, { granularity: "grapheme" })`. Flutter: `String.characters`. Words are grouped `nowrap` so lines only break between words. |
| Per letter, from | `opacity 0`, `y +0.45em`, `blur 10px` |
| Per letter, to | `opacity 1`, `y 0`, `blur 0` |
| Duration | 700 ms opacity and y. **500 ms blur**, so the letter is sharp before it finishes settling. |
| Easing | `cine-out` `cubic-bezier(0.16, 1, 0.3, 1)` |
| Stagger | 28 ms per letter, capped at 600 ms total: `step = min(28, 600 / (n - 1))`. A 13-letter wordmark finishes at about 1036 ms; a 40-letter title at 1300 ms. |
| Trigger | Rail and section headers: when 60 % in view, **once per session per header**. Hero titles: on every hero change, starting 200 ms into the dissolve. Detail title: after the match cut lands. |
| Color on hover or state | Linked headings wipe from ink to tungsten left-to-right: `transition: color 240ms ease; transition-delay: calc(var(--i) * 12ms)` per letter. Reverse on leave with no delay. |
| Kerning | `font-kerning: none` / `FontFeature.disable('kern')` on revealed headings. Split and unsplit text are then identical, and nothing jumps when the animation ends. Tight tracking comes from `letter-spacing`. |
| Accessibility | The container carries `aria-label={text}` / `Semantics(label:)`. Letters are `aria-hidden` / `excludeSemantics`. |
| Reduced motion | The whole string fades in over 200 ms. No y, no blur, no stagger. |
| Used on | H3 rail and section headers, hero title, detail title, pre-roll wordmark, Wrapped scene titles, "PREVIOUSLY ON" |

**Web** (Motion 12, already installed as `framer-motion` 12.42.2. `delayChildren: stagger()` needs ≥ 12.23.11, per the Motion changelog):
```tsx
"use client";
import { motion, stagger, useReducedMotion, type Variants } from "framer-motion";

const seg = new Intl.Segmenter(undefined, { granularity: "grapheme" });
const graphemes = (s: string) => Array.from(seg.segment(s), (x) => x.segment);
const cineOut = [0.16, 1, 0.3, 1] as const;

const parent: Variants = {
  hidden: {},
  show: (n: number) => ({ transition: { delayChildren: stagger(Math.min(0.028, 0.6 / Math.max(1, n - 1))) } }),
};
const letter: Variants = {
  hidden: { opacity: 0, y: "0.45em", filter: "blur(10px)" },
  show: { opacity: 1, y: 0, filter: "blur(0px)",
          transition: { duration: 0.7, ease: cineOut, filter: { duration: 0.5, ease: cineOut } } },
};

export function LetterReveal({ text, className }: { text: string; className?: string }) {
  const reduce = useReducedMotion();
  const words = text.split(" ");
  const n = graphemes(text).length;
  let i = 0;
  if (reduce) return <motion.h3 className={className} initial={{ opacity: 0 }} whileInView={{ opacity: 1 }} viewport={{ once: true }} transition={{ duration: 0.2 }}>{text}</motion.h3>;
  return (
    <motion.h3 aria-label={text} className={className} style={{ fontKerning: "none" }}
      initial="hidden" whileInView="show" viewport={{ once: true, amount: 0.6 }} variants={parent} custom={n}>
      {words.map((w, wi) => (
        <span key={wi} aria-hidden className="inline-block whitespace-nowrap">
          {graphemes(w).map((c) => (
            <motion.span key={i} variants={letter} className="reveal-letter inline-block" style={{ ["--i" as string]: i++ }}>{c}</motion.span>
          ))}
          {wi < words.length - 1 && " "}
        </span>
      ))}
    </motion.h3>
  );
}
```
"Once per session" means a module-level `Set<string>` of header keys. If the key has been seen, render `initial={false}`.

**Flutter** (`flutter_animate` 4.5.2, BSD-3-Clause, pure Dart, no native build input):
```dart
class LetterReveal extends StatelessWidget {
  const LetterReveal(this.text, {super.key, required this.style, this.delay = Duration.zero});
  final String text; final TextStyle style; final Duration delay;

  @override
  Widget build(BuildContext context) {
    final s = style.copyWith(fontFeatures: const [FontFeature.disable('kern')]);
    if (MediaQuery.disableAnimationsOf(context)) {
      return Text(text, style: s).animate(delay: delay).fadeIn(duration: 200.ms);
    }
    final n = text.characters.length;
    final step = n < 2 ? 0 : math.min(28, 600 ~/ (n - 1));
    var i = 0;
    return Semantics(label: text, excludeSemantics: true, child: Wrap(children: [
      for (final word in text.split(' '))
        Row(mainAxisSize: MainAxisSize.min, children: [
          for (final ch in '$word '.characters)
            Text(ch, style: s).animate(delay: delay + (step * i++).ms)
              .fadeIn(duration: 700.ms, curve: cineOut)
              .slideY(begin: .45, end: 0, duration: 700.ms, curve: cineOut)
              .blurXY(begin: 10, end: 0, duration: 500.ms, curve: cineOut),
        ]),
    ]));
  }
}
```
Each letter's blur is one `ImageFiltered` saveLayer for about 1 s. That is acceptable under the flagship-only rule. `slideY(.45)` is 45 % of the glyph box height, which is close to 0.45em for the 0.86–1.0 line heights used here. For the in-view trigger, use the list's own visibility. A `SliverList` builds headers lazily, so building is the trigger.

### 9.2 Typing reveal: 50 ms per character

**Spec**

| Property | Value |
|---|---|
| Rate | **Exactly one grapheme per 50 ms**, spaces included. Uniform, with no punctuation pauses. The spec is the rhythm. |
| Clock | Timestamp-based (`elapsed ~/ 50`), so dropped frames never slow the text down. |
| Layout | The full string is laid out from frame 0. Unrevealed text is `transparent`, so line breaks never jump. |
| Caret | A tungsten block 0.5em × 1em, zero layout width (it overflows), sitting after the last revealed grapheme. It is solid while typing. When done, it blinks 530 ms on / 530 ms off three times (3180 ms) and then stays hidden. |
| Skip | Tap, click, Enter or Space completes the text instantly. |
| Length | Headlines only, ≤ 60 characters (≤ 3 s). Longer AI text (recaps) streams with a 160 ms per-word fade instead, because 50 ms/char on 600 characters would take 30 s. |
| Accessibility | The full text is in the accessibility tree from the start (`aria-label` / `Semantics`), and the visual layer is hidden from it. |
| Reduced motion | Full text at once, no caret. |
| Used on | The **Home main headline** (for example "Tonight: Chapter 143 of Omniscient Reader"), "Previously on <Series>" subtitle, AI one-liners ("Because you read Solo Leveling"), empty-state headlines, Wrapped stat lines |

**Web**
```tsx
export function useTyped(text: string, ms = 50) {
  const chars = useMemo(() => graphemes(text), [text]);
  const reduce = useReducedMotion();
  const [n, setN] = useState(reduce ? chars.length : 0);
  useEffect(() => {
    if (reduce) { setN(chars.length); return; }
    let raf = 0; const t0 = performance.now();
    const tick = (t: number) => {
      const k = Math.min(chars.length, Math.floor((t - t0) / ms));
      setN(k); if (k < chars.length) raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [chars, ms, reduce]);
  return { shown: chars.slice(0, n).join(""), rest: chars.slice(n).join(""), done: n === chars.length, skip: () => setN(chars.length) };
}

export function TypedHeadline({ text }: { text: string }) {
  const { shown, rest, done, skip } = useTyped(text);
  return (
    <h1 aria-label={text} onClick={skip} className="font-display text-hero uppercase">
      <span aria-hidden>{shown}</span>
      <span aria-hidden className="relative inline-block w-0 align-baseline">
        <span className={`absolute bottom-[0.08em] left-0 h-[0.9em] w-[0.5em] bg-tungsten ${done ? "animate-caret-out" : ""}`} />
      </span>
      <span aria-hidden className="text-transparent">{rest}</span>
    </h1>
  );
}
```
`caret-out` (section 14.1) runs 3.18 s with `steps(1)` segments, which gives six 530 ms halves: on, off, on, off, on, off.

**Flutter**
```dart
class TypedHeadline extends StatefulWidget {
  const TypedHeadline(this.text, {super.key, required this.style});
  final String text; final TextStyle style;
  @override State<TypedHeadline> createState() => _TypedHeadlineState();
}
class _TypedHeadlineState extends State<TypedHeadline> with SingleTickerProviderStateMixin {
  late final List<String> _c = widget.text.characters.toList();
  late final Ticker _t = createTicker((e) {
    final n = math.min(_c.length, e.inMilliseconds ~/ 50);
    if (n != _n) setState(() => _n = n);
    if (n == _c.length) _t.stop();
  });
  int _n = 0;
  @override void initState() { super.initState(); if (!WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations) _t.start(); else _n = _c.length; }
  @override void dispose() { _t.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () { _t.stop(); setState(() => _n = _c.length); },
    child: Semantics(label: widget.text, excludeSemantics: true, child: Text.rich(TextSpan(style: widget.style, children: [
      TextSpan(text: _c.take(_n).join()),
      WidgetSpan(alignment: PlaceholderAlignment.baseline, baseline: TextBaseline.alphabetic,
        child: SizedBox(width: 0, child: OverflowBox(maxWidth: 40, alignment: Alignment.centerLeft,
          child: _Caret(done: _n == _c.length, size: widget.style.fontSize!)))),
      TextSpan(text: _c.skip(_n).join(), style: const TextStyle(color: Color(0x00000000))),
    ]))),
  );
}
```
`_Caret` is a `Container(width: .5*size, height: .9*size, color: tungsten)`. When `done`, it blinks three times: a single forward run of `AnimationController(duration: 3180.ms)` drives `Opacity(opacity: (c.value * 6).floor().isEven ? 1 : 0)`, and the caret is removed when the controller completes. That is the same six 530 ms halves as the web keyframes, with no `repeat(count:)` version dependency.

## 10. Poster rails: geometry, hover and focus

### 10.1 Geometry

| Breakpoint | Visible posters | Poster width | Gap | Rail stack |
|---|---|---|---|---|
| < 768 (phone, mobile web) | 3.3 (a peek invites the swipe) | `calc((100vw - 16px - 3*8px) / 3.3)` ≈ 106 px at 375 | 8 px | 28 px |
| 768–1023 | 5.3 | computed the same way | 8 px | 32 px |
| 1024–1439 | 6 + 0.25 peek | `calc((100vw - 2*gutter - 5*8px) / 6.25)` | 8 px | 40 px |
| 1440–1919 | 7 + 0.25 peek | `/7.25` | 8 px | 40 px |
| ≥ 1920 | 8 + 0.25 peek | `/8.25` | 10 px | 48 px |

- Rails start at the gutter and bleed off the right edge. Header to posters is 12 px.
- Posters are 2:3 with `frame` 6 px radius, an inner hairline, and a `raised` placeholder.
- **Captions:** discovery rails (Home, Source browse) are a *poster wall* with no captions; the title appears in the focus and preview state. Library and Continue rails show a caption below (heading-card 13 px / 1 line, plus timecode in ink-3, for example "CH 142 · NEW").
- **Continue reading:** 16:9 cards (cover cropped at `50% 20%`), a 3 px tungsten progress bar flush at the bottom edge, and timecode "CH 142 · 64%".
- **Top 10 / most-read** (across the 2–3 accounts, 18+ gated per profile): an outline numeral at 1.1× poster height, Mona Sans `wght 900 wdth 75`, `color: #000; -webkit-text-stroke: 2px rgba(245,245,241,.48)`, sitting half behind the poster's left edge. Flutter paints it twice: `Paint()..style = PaintingStyle.stroke..strokeWidth = 2` with `foreground`, then a fill.
- **Source hubs** (from HBO Max): 16:9 tiles showing the source name in display-md, set over that source's latest cover blurred at 60 px with the ambient tint.

### 10.2 Desktop pointer

| Stage | Trigger | Effect |
|---|---|---|
| 1. Lift | `:hover` immediately | Scale 1.06, brightness 1.08, glow bloom. 200 ms `cine-out`, origin center (first visible: `left center`, last visible: `right center`). |
| Sibling dim | Any poster hovered | Siblings get `brightness(.55) saturate(.8)` over 280 ms, in pure CSS: `.rail:has(.poster:hover) .poster:not(:hover) { filter: brightness(.55) saturate(.8) }` |
| Backdrop swap | Dwell 450 ms (Home) | The hero backdrop and ambient color dissolve to the hovered series (800 ms) while the hero is ≥ 30 % in view. Otherwise only the page-spill tint changes. This is the PS5 and Apple TV pattern. |
| 2. Preview slate | Dwell 700 ms | A portal overlay, **not** a layout push. It is 2.1× poster width and 2:1 on top: blurred cover backdrop with grain plus the title per-letter reveal. Below that on `overlay` `#161616`: eyebrow, 2-line hook, [Read] [+ List] [ⓘ] buttons. Grows from the poster rect over 320 ms `cine-out`. Collapses after 120 ms grace on leave, 200 ms `cine-in`. |
| Paddles | Rail hover | 48 × full-height edge zones over the rail-edge scrim, chevron in ink. They page by `visible - 1` posters over 560 ms `cine-in-out`. |

### 10.3 Keyboard (desktop web is keyboard-first)

- **Fixed-left focus** (the TV pattern): focus stays in the first full slot and the rail slides beneath it (`translateX`, 360 ms `cine-out`). The eye never has to chase focus.
- The focus ring is 2 px ink with a 3 px offset, 8 px radius, plus stage-1 lift and sibling dim. There is no ring on mouse hover (`:focus-visible` only).
- ←/→ move within a rail and ↑/↓ move between rails, with the page scrolling so the focused rail sits at 30 % of viewport height. Enter opens detail (match cut). Space opens the preview slate. Esc closes it. Home and End jump to rail ends. Roving `tabindex` puts one Tab stop per rail.
- Backdrop swap on keyboard focus uses the same 450 ms dwell.

### 10.4 Touch (phone and mobile web)

- **Press:** scale 0.97 over 90 ms, release back over 160 ms `cine-out`. Haptic `selectionClick`.
- **Long-press, 450 ms:** opens the preview sheet (fade up from black). The poster match-cuts into the sheet header. Haptic `mediumImpact`.
- No hover stages and no sibling dim. The mobile hero auto-advances every 8000 ms with a dissolve (paused while touched), and a 2 px segmented progress strip at the top works like stories.

## 11. Loading as pre-roll

A cinema never shows a spinner. It shows the studio ident, the rating card and the leader countdown.

### 11.1 Cold-start pre-roll (≤ 1600 ms, skippable, once per session)

| t (ms) | Picture | Sound (if on) | Haptic |
|---|---|---|---|
| 0 | The native splash already showed pure `#000` (Android 12 SplashScreen and the iOS launch storyboard, both black). Flutter takes over black. | n/a | n/a |
| 0–120 | Black. Grain at 0.12 flickers (projector warming). | "Projector start" sting begins | n/a |
| 120–1156 | The wordmark does the per-letter reveal (13 graphemes, 28 ms stagger, 700 ms). | Sting body | n/a |
| 700–1300 | A tungsten bloom swells behind the wordmark (radial glow 0 → .5 opacity) and grain settles to 0.07. | Sub swell | `heavyImpact` at 1000 ms (bloom peak) |
| 1300–1600 | The wordmark tracks out (letter-spacing +0.08em via `wdth` 75 → 82) and dissolves. | Tail | n/a |
| 1600 | Cut to Home, fading up from black over 400 ms. The hero Ken Burns starts. | n/a | n/a |

Rules:
- The duration is `max(dataReady, 900ms)`, capped at 1600 ms.
- If data is not ready at 1600 ms, hold on black plus bloom (the "slate"). After 2400 ms, show the leader sweep (section 11.4) under the wordmark.
- Warm resumes skip the pre-roll entirely. So does web after the first navigation (`sessionStorage` flag in try/catch).
- A tap anywhere skips.

### 11.2 Slate skeletons (replace grey shimmer)

- Poster placeholders are `raised` `#0E0E0E` frames with an inner hairline. A "projector flicker" pulses opacity .6 → 1 over 1400 ms `drift` alternate, with each item's phase offset by 60 ms left to right.
- If the title is known before the image (list payloads usually are), the placeholder shows it as a **title card**: heading-card in ink-3, bottom-left, 10 px inset.
- Rail headers are static strings, so they render immediately and do their per-letter reveal as usual.
- There is never a shimmer gradient. Shimmer is generic, and this skin is not.

### 11.3 Image "focus pull" (rack focus)

On `onLoad`, animate from `filter: blur(16px) brightness(.6)` and scale 1.04 to sharp and 1.0 over 520 ms `cine-out`. The background under the image is the series `ambient.tint` if known, otherwise `raised`.

Flutter: `Image.frameBuilder`. If `wasSynchronouslyLoaded`, return the child as-is. Otherwise, when the first `frame != null`, return `child.animate().blurXY(begin: 16, end: 0, duration: 520.ms, curve: cineOut).scaleXY(begin: 1.04, end: 1).custom(builder: brightness)`. `cached_network_image`'s built-in `fadeInDuration` gets set to `Duration.zero` so the two effects don't stack.

### 11.4 Leader sweep (for waits over 1 s)

This replaces every spinner. It is a 40 px circle (24 px inline) drawn like an SMPTE universal leader:
- A conic sweep at 1 revolution per 1000 ms, linear
- A 1 px crosshair and a 1 px ring in `rgba(245,245,241,.3)`
- Sweep fill `rgba(245,245,241,.22)`

Web:
```css
@property --sweep { syntax: "<angle>"; inherits: false; initial-value: 0deg; }
.leader { width: 40px; aspect-ratio: 1; border-radius: 50%;
  background: linear-gradient(rgb(245 245 241/.3),rgb(245 245 241/.3)) center/1px 100% no-repeat,
              linear-gradient(rgb(245 245 241/.3),rgb(245 245 241/.3)) center/100% 1px no-repeat,
              conic-gradient(rgb(245 245 241/.22) var(--sweep), transparent 0);
  box-shadow: inset 0 0 0 1px rgb(245 245 241/.3);
  animation: sweep 1s linear infinite; }
@keyframes sweep { to { --sweep: 360deg; } }
```
Flutter: a `CustomPainter` with `canvas.drawArc(rect, -pi / 2, t * 2 * pi, true, fill)` plus two lines and a ring, repainting from an `AnimationController(duration: 1.s)..repeat()`.

The same sweep, drawn with a 5 s period and a tungsten fill, is the end-card countdown.

### 11.5 Rating card (18+ gate made cinematic)

When an 18+ series opens (detail, after the gate) and again at reader start, a Netflix-style rating card appears top-left under the chrome:
- A 3 px × 44 px `rating` bar
- "18+" in display-md
- Descriptors from the series tags ("Violence · Sexual content") in caption ink-2

It fades in over 400 ms, holds for 4000 ms and fades out over 600 ms. It is informational only and never blocks. The gate itself is a separate, earlier screen.

### 11.6 AI states ("Previously on…", recommendations)

- **Loading:** a black title card with "PREVIOUSLY ON" (eyebrow and per-letter reveal) and the series title in editorial-lg below it. The leader sweep appears after 1 s. The recap streams in with per-word fades (160 ms each, 30 ms apart).
- **Unavailable:** a static slate. "RECAP UNAVAILABLE" in heading-section ink-3, a body line "Pick up where you left off — Chapter 142.", and one primary button "Continue". It never shows an error red, because an unavailable AI is not an error in the story.

## 12. Sound design cues and paired haptics

Sound is **off by default**, behind an opt-in toggle in Settings. All cues are original syntheses (a DAW, or `ffmpeg -f lavfi aevalsrc`). Never sample Netflix, HBO or PlayStation sounds, because sonic logos are brand assets. The format is 48 kHz 16-bit mono WAV: no encoder padding, so clicks start on time, and the whole set stays under 300 KB. UI cues peak at −18 to −12 dBFS and the sting at −6 dBFS. Master UI gain defaults to 0.6.

| Cue | Moment | Length | Character | Haptic (Flutter `HapticFeedback`) | Web vibrate (Android only) |
|---|---|---|---|---|---|
| `focus` | Rail focus moves (keyboard or dwell) | 18 ms | A soft filtered "tock" around 2.8 kHz, −30 dBFS, like a PS5 menu click | `selectionClick` (throttle 1 per 60 ms) | none |
| `select` | Open detail, press a primary button | 90 ms | Two felt-piano notes a rising fifth (E5 → B5) | `lightImpact` | `8` |
| `back` | Back, close sheet | 70 ms | Falling fifth, quieter | none | none |
| `page` | Rail paddle, hero swipe | 140 ms | An air whoosh: band-passed noise 1–6 kHz | none | none |
| `swap` | Hero backdrop dissolve | 400 ms | A low swell: 60 Hz sine plus short reverb tail, −28 dBFS | none | none |
| `sting` | Pre-roll | ≤ 1800 ms | "Projector start": motor rattle (10 Hz AM noise), a 45 Hz sub boom at 1000 ms, a rising shimmer and one warm major-seventh chord | `heavyImpact` at the boom | `[0, 1000, 30]` |
| `rating` | Rating card | 900 ms | A low filtered hum, like a theater's house lights going down | `mediumImpact` | none |
| `complete` | Chapter finished, streak extended | 600 ms | A warm triad, tungsten-bright, soft attack | `mediumImpact`, then `lightImpact` 120 ms later | `[12, 120, 8]` |
| `error` | Failed action | 180 ms | A muted low thud | `heavyImpact` | `[20, 60, 20]` |

**Dwell ambience** (from PS5 game hubs): if sound is on, dwelling on a detail page for 1.5 s fades in (2 s) a 20 s genre ambience loop at −30 dBFS (rain for drama, low drones for action). It fades out over 600 ms on leave. The ambient reader soundscape feature reuses the same engine.

**Implementation**
- **Web:** the native Web Audio API, no library. Decode every WAV once into an `AudioBuffer`. Play through `new AudioBufferSourceNode(ctx, { buffer })` into one master `GainNode`. Resume the `AudioContext` on the first pointer or key gesture (autoplay policy). Mute while the novel TTS player is active.
- **Flutter:** `flutter_soloud` 5.1.4 (MIT; SoLoud C++ engine; Android, iOS and web; low-latency multi-voice). Preload with `SoLoud.instance.loadAsset(...)` and fire with `play(source, volume: …)`. `just_audio` (already installed) stays for TTS narration. It is a streaming media player, and its start latency is wrong for 18 ms clicks. Adding a native audio engine is a real new pod or AAR, so it lands in its own change, following the repo's existing just_audio precedent.
- **Haptics** use Flutter's built-in `HapticFeedback` (no package). The full cross-skin haptic vocabulary belongs to the haptics doc. The rows above are the Cinematic tuning: sparse and weighty, with no haptic on scroll or dismiss.

## 13. Component notes (Cinematic variants)

- **Buttons.** There are 4 kinds: primary (projector white), secondary (white 14 %), round icon (1.5 px ring, Netflix-style "+" and "i"), and text. There is no tungsten button, because tungsten is a mark, not a surface. Labels are sentence case, weight 600. The primary icon sits at the leading side, 20 px (a solid ▶ glyph for "Read" / "Continue"). Press is scale 0.97 over 90 ms. Disabled is `ink-4` text on `well`.
- **Tabs** are "slates": uppercase eyebrow labels with a 2 px tungsten bar under the active tab. They are never pills.
- **Chips and filters** are text toggles in eyebrow style, separated by a `·`. Active is ink with a tungsten dot; inactive is ink-3.
- **Badges** use the `hair` 2 px radius and micro text: NEW (tungsten fill), 18+ (rating outline), DOWNLOADED (positive outline), and ONGOING / COMPLETED (ink-3 outline).
- **Desktop top nav** is 68 px: wordmark left and sections as label text (ink-3, active ink with a 2 px tungsten underline 6 px below). It is transparent over the hero with the top-chrome scrim, and turns to `#000` after 80 px of scroll (280 ms).
- **Desktop sidebar** (reader and settings pages): `#000` with a hairline right edge. There is no card background.
- **Mobile bottom nav** is described in the front matter. The icon set is 1.75 px stroke, square-capped (film-slate crispness), at 24 px.
- **Sheets and dialogs** use `overlay` `#161616`, a 12 px top radius and a 0.72 black barrier. The drag handle is a 36 × 4 px ink-4 bar. **No backdrop blur** anywhere in this skin.
- **Toasts** look like subtitles: bottom-left, an ink "subtitle line" at body-strong on a `#000` band with 2 px radius. They hold for 3.2 s. Fade in 160 ms, fade out 240 ms.
- **OCR dialogue search** (Prime X-Ray mapping): in the wide reader, a right panel titled "X-RAY". Each hit renders as a subtitle line (body-strong ink, `text-shadow: 0 0 4px #000`) followed by timecode-style "CH 88 · PANEL 14". Selecting a hit match-cuts to the panel and pulses a 2 px tungsten frame around the bubble, twice at 480 ms.
- **Progress** is 3 px, square-ended, with a tungsten fill. It never has a rounded pill.
- **Inputs** are `well` with a 6 px radius. Focus is a 2 px tungsten underline drawn from the left over 280 ms. There is no glow ring.
- **Toggles** are the one sanctioned pill: a 40 × 22 px track, `well` off and tungsten on, with an ink 18 px knob that slides 160 ms `cine-out`. No bounce.

## 14. Platform mapping

### 14.1 Web: Tailwind 4 `@theme` (Cinematic entry)

Each skin gets its own CSS entry, chosen at the root layout from the skin cookie. The app restarts on a skin change, so there is no runtime theme juggling.
```css
@import "tailwindcss";
@theme {
  --color-canvas: #000000; --color-raised: #0e0e0e; --color-overlay: #161616; --color-well: #1e1e1e;
  --color-ink: #f5f5f1; --color-ink-2: rgb(245 245 241 / .64); --color-ink-3: rgb(245 245 241 / .48); --color-ink-4: rgb(245 245 241 / .24);
  --color-hairline: rgb(255 255 255 / .08); --color-tungsten: #ffb547; --color-tungsten-pressed: #e89a2c;
  --color-rating: #ff5c5c; --color-positive: #3dd68c; --color-info: #7ab8ff;

  --font-display: "Mona Sans", "Arial Narrow", sans-serif;
  --font-sans: "Source Sans 3", ui-sans-serif, system-ui, sans-serif;
  --font-editorial: "Instrument Serif", Georgia, serif;

  --text-hero: clamp(2.75rem, 7vw, 7.5rem); --text-hero--line-height: .86; --text-hero--letter-spacing: -.025em; --text-hero--font-weight: 850;
  --text-display: clamp(2.25rem, 4.6vw, 4.75rem); --text-display--line-height: .9; --text-display--letter-spacing: -.02em; --text-display--font-weight: 800;
  --text-section: 1.625rem; --text-section--line-height: 1; --text-section--letter-spacing: -.01em; --text-section--font-weight: 760;
  --text-eyebrow: .75rem; --text-eyebrow--line-height: 1.2; --text-eyebrow--letter-spacing: .18em; --text-eyebrow--font-weight: 600;

  --radius-hair: 2px; --radius-frame: 6px; --radius-sheet: 12px;

  --ease-cine-out: cubic-bezier(.16, 1, .3, 1); --ease-cine-in: cubic-bezier(.7, 0, .84, 0);
  --ease-cine-in-out: cubic-bezier(.65, 0, .35, 1); --ease-drift: cubic-bezier(.37, 0, .63, 1);

  --animate-kenburns: kenburns 24s var(--ease-drift) infinite alternate;
  --animate-flicker: flicker 1.4s var(--ease-drift) infinite alternate;
  --animate-caret-out: caret-out 3.18s steps(1) forwards;
  @keyframes kenburns { from { transform: scale(1); object-position: 50% 12% } to { transform: scale(1.1) translate3d(-1.5%, -2%, 0); object-position: 50% 42% } }
  @keyframes flicker { from { opacity: .6 } to { opacity: 1 } }
  @keyframes caret-out { 0%, 33.33%, 66.67% { opacity: 1 } 16.67%, 50%, 83.33%, 100% { opacity: 0 } }
}
@utility font-condensed { font-variation-settings: "wdth" 75; }
@media (prefers-reduced-motion: reduce) {
  .animate-kenburns, .grain::after, .animate-flicker { animation: none; }
}
```

### 14.2 Effect → implementation → package

| Effect | Web | Flutter | Package (version, license) |
|---|---|---|---|
| Tokens | Tailwind 4 `@theme` | `ThemeExtension<CineTokens>` with const colors and curves | tailwindcss 4 (MIT), already installed |
| Per-letter reveal | Motion variants + `stagger()` | flutter_animate `fadeIn/slideY/blurXY` per grapheme | framer-motion 12.42.2 (MIT, installed); **flutter_animate 4.5.2 (BSD-3-Clause, new, pure Dart)** |
| Typing reveal | rAF hook, timestamp clock | `Ticker` + `Text.rich` | none new |
| Scrims | CSS gradients (section 4) | `LinearGradient` with the stops list | none |
| Ambient color | Backend hex, `@property` transitions | Backend hex, `TweenAnimationBuilder<Color>` | Pillow 12.3.0 (installed) + stdlib `colorsys` |
| Live page tint (reader) | `OffscreenCanvas` 16×16 | `ColorScheme.fromImageProvider` (Flutter core) | none. **Not** `palette_generator` (discontinued Feb 2025) |
| Grain | SVG `feTurbulence` data URI, `overlay` | `FragmentProgram` shader, `BlendMode.overlay` | none (`flutter_shaders` 0.1.3 unnecessary) |
| Bloom | `box-shadow` / blurred duplicate | `BoxShadow` / `ImageFiltered` | none |
| Ken Burns | CSS keyframes | flutter_animate `.custom` repeat | flutter_animate |
| Parallax | Motion `useScroll` + `useTransform` | `SliverAppBar` + `FlexibleSpaceBar(collapseMode: parallax)` | none new |
| Match cut | View Transitions API | `Hero` + `flightShuttleBuilder` | none |
| Dip to black and route transitions | `AnimatePresence mode="wait"` | go_router `CustomTransitionPage` | go_router ^14 (installed) |
| Sibling dim | CSS `:has()` | `InheritedNotifier` of the focused index, `ColorFiltered` brightness matrix | none |
| Leader sweep | `@property --sweep` + `conic-gradient` | `CustomPainter.drawArc` | none |
| Sound | Web Audio API | flutter_soloud | **flutter_soloud 5.1.4 (MIT, new, native)** |
| Haptics | `navigator.vibrate` (Android Chrome only) | `HapticFeedback` (core) | none |
| Fonts | `next/font/local` variable woff2 | Bundled variable TTF + `FontVariation` | Mona Sans, Source Sans 3, Instrument Serif (all OFL-1.1) |

### 14.3 Reduced motion (OS setting honored everywhere)

| Effect | Reduced variant |
|---|---|
| Per-letter reveal | Whole string fades in over 200 ms |
| Typing reveal | Full text immediately, no caret |
| Ken Burns and parallax | Static frame at scale 1.04, focal point 50% 25% |
| Grain | Static (no animation), same intensity |
| Pre-roll | Wordmark fades in over 300 ms, holds until data is ready, fades out over 200 ms |
| Match cut, push-in, letterbox curtain | 200 ms crossfade |
| Hover lift and preview slate | Instant state change, no scale |
| Hero auto-advance | Off (manual only) |

## 15. Do's and Don'ts

**Do**
- Keep every background `#000000`. Let the art and the ambient spill be the only color fields.
- Fade art into black with the eased scrim stops, not two-stop linear gradients.
- Use tungsten only as a mark, a few pixels at a time.
- Set titles as treatments: eyebrow, condensed uppercase title, tungsten rule, hook.
- Move the camera (drift, parallax, push-in), and cut or dissolve between scenes.
- Put grain and vignette on art only, blended with `overlay`.
- Let loading feel like pre-roll: black, light and a reveal.

**Don't**
- Use backdrop blur, frosted panes, springs, overshoot, 3D tilt or specular sheen. Those belong to Glass.
- Use drop shadows for elevation. Use light (bloom) or surface steps.
- Use pill buttons, rounded-full chips or rounded progress bars.
- Use grey shimmer skeletons or circular spinners.
- Put grain over reader pages, text surfaces or the novel reader.
- Autoplay sound. Sound is opt-in, and even then UI cues stay under −12 dBFS.
- Use pure `#FFFFFF` text. Projector white is `#F5F5F1`.
- Imitate any studio's sonic logo, wordmark or red.

## 16. Known gaps and open questions

1. **No landscape art.** Sources publish portrait covers. The scope hero relies on tilt-down cropping plus a blurred fill. If a series has no strong upper-third subject, the hero reads weak. An option (not recommended now) is AniList `bannerImage` when a mapping exists.
2. **CJK titles** cannot use the condensed uppercase treatment. The fallback is heavy-weight system CJK at display-md size. This needs a visual check with real Korean alt-titles.
3. **Kerning is disabled** on revealed headings so the split and unsplit text match. Mona Sans's spacing at `wdth 75` holds up without it, but pairs like "AV" and "TA" in huge hero sizes should be proofed.
4. **Web match cut** uses `document.startViewTransition` manually. Revisit once React `<ViewTransition>` is stable in Next.
5. **flutter_soloud** is a native addition: a new iOS pod and Android library. It goes in its own change, consistent with the repo's CocoaPods-only, pinned-graph policy.
6. **Ambient extraction** in HLS is a deliberate simplification (`ponytail:` note in the snippet). Upgrade to OKLCH if accents look uneven across hues.
7. **Wordmark and icon** design is out of scope here. This doc only defines how the wordmark *behaves* (pre-roll reveal, bloom, track-out) and suggests it is set in Mona Sans `wdth 75 wght 900`.

## Sources

- Netflix tokens (extracted): https://oh-my-design.kr/design-systems/netflix
- Netflix-style hover expand and neighbor push: https://css-tricks.com/how-to-re-create-a-nifty-netflix-animation-in-css/
- Eased scrim gradients (Andreas Larsen): https://css-tricks.com/easing-linear-gradients/
- Motion `stagger()` and `delayChildren: stagger()` (≥ 12.23.11): https://motion.dev/docs/stagger, https://github.com/motiondivision/motion/blob/main/CHANGELOG.md
- flutter_animate 4.5.2 (BSD-3-Clause): https://pub.dev/packages/flutter_animate
- flutter_soloud 5.1.4 (MIT): https://pub.dev/packages/flutter_soloud
- flutter_shaders 0.1.3 (BSD-3-Clause): https://pub.dev/packages/flutter_shaders
- palette_generator discontinued: https://github.com/flutter/flutter/issues/162963, https://pub.dev/packages/palette_generator_master
- tvOS 26 / Apple TV portrait posters: https://www.apple.com/newsroom/2025/06/apple-tv-brings-a-beautiful-redesign-and-enhanced-home-entertainment-experience/, https://9to5mac.com/2025/07/16/apples-tv-app-gets-fresh-design-in-ios-26-and-tvos-26-heres-whats-new/
- tvOS focus effects: https://devsign.co/notes/custom-focus-effects-in-tvos, https://www.brightec.co.uk/blog/tvos-focus-engine
- Crunchyroll 2024 rebrand: https://news.designrush.com/crunchyroll-to-relaunch-brand-at-san-diego-comic-con, https://www.campaignasia.com/article/fresh-colours-new-fonts-inside-crunchyrolls-rebrand/497281; legacy orange: https://www.brandcolorcode.com/crunchyroll
- PS5 UI: https://old.whatbrentsay.com/2020/10/21/playstation-5-ui-reveal-observations-from-a-designer/, https://www.androidheadlines.com/sony-ps5-ui-design-playstation-5.html, https://www.frontlinejp.net/2020/11/12/playstation-5-sony-discusses-the-ui-design-and-hardware/
- Mona Sans (OFL-1.1, wdth 75–125, wght 200–900): https://github.com/github/mona-sans
- Token-format references: `~/.claude/skills/design-md/design-md/{playstation,spotify,wired}/DESIGN.md`
