# Cinematic concept 1: "Projection" (art-first)

Designer 1 of 3 for the Cinematic skin. Angle: **the artwork drives everything, the UI recedes, and every colour on screen comes from a cover or a page.**

Binding inputs: `inventory/00-decisions.md` (owner decisions), `inventory/web.md`, `inventory/mobile.md`, `inventory/capabilities.md`, `research/*.md`, `stack-decision.md`. Dark only, AMOLED `#000000` base, restart on skin switch, flagship-only effects with OS reduced-motion honoured.

Contents

1. Manifesto
2. Tokens
3. Component catalog
4. Per-screen specs
5. The four new features
6. The two required signature animations
7. Brand
8. Signature moments
9. Implementation notes

---

## 1. Manifesto

A reader opens ManhwaManiacs to look at pictures and read words that someone else made, so in Projection the app is the dark room and the series art is the only light in it. The canvas is true black and stays black. Nothing on screen carries its own colour: every tint, glow, accent and wash is *thrown* onto the black by the cover, page or profile that currently owns the frame, the way a projector lights a theatre's walls and front rows. The chrome is a set of house lights that the reader never has to think about. It is white text directly on black, hairlines instead of boxes and scrims instead of bars, and it dims to nothing while a series is on screen. The only fixed hue is a small tungsten mark for "you are here", and even that gives way to the series' own colour whenever a series is in the frame. Motion is camera work (dissolve, cut, push-in, dolly, rack focus), never objects bouncing. Type does the title design that manhwa covers lack, and the two signature reveals, per-letter un-blur and 50 ms typing, are the opening credits. If a screen would look the same with the art removed, it is designed wrong.

---

## 2. Tokens

All lengths are logical px (1 CSS px = 1 Flutter logical pixel). Letter spacing is in em. The generator in `design/build.mjs` converts em to absolute values for Dart. Colour values are sRGB hex unless noted.

### 2.1 Colour

#### 2.1.1 Base: the dark room

| Token | Value | Contrast of ink on it | Use |
|---|---|---|---|
| `void` | `#000000` | 19.3:1 | Every screen background, every reader background, the gaps between posters. AMOLED pixels off. |
| `n-050` | `#070707` | 18.8:1 | Placeholder frame for a poster whose key light is unknown |
| `n-100` | `#0E0E0E` | 18.0:1 | Skeleton frames, the preview slate body, image well behind a focus pull |
| `n-150` | `#141414` | 17.2:1 | Sheets, menus, dialogs, context menus, the command palette |
| `n-200` | `#1B1B1B` | 16.2:1 | Inputs, pressed rows, the toggle track (off) |
| `n-300` | `#262626` | 14.6:1 | Hover fill on list rows (desktop only), key caps |
| `n-400` | `#3A3A39` | n/a | Scrub-bar track, disabled fill |
| `n-500` | `#5C5C5A` | n/a | Placeholder glyphs (never text) |
| `n-600` | `#767674` | 4.6:1 on `void` | Lowest grey allowed for information text |
| `n-700` | `#9D9D9A` | 7.7:1 on `void` | Secondary text |
| `n-800` | `#C8C8C4` | 12.4:1 on `void` | Body text inside long lists |
| `n-900` | `#E6E6E2` | 16.6:1 on `void` | Emphasised body |
| `n-950` / `ink` | `#F5F5F1` | 19.3:1 on `void` | Primary text and the primary button fill. Warm projector white. `#FFFFFF` is never used. |

Alpha inks, used on top of art and scrims where a solid grey would look pasted on:

| Token | Value | Min contrast on `void` | Use |
|---|---|---|---|
| `ink-2` | `rgba(245,245,241,.66)` | 8.1:1 | Synopsis, secondary lines, inactive tab labels |
| `ink-3` | `rgba(245,245,241,.48)` | 4.6:1 | Metadata, timecodes, captions, inactive nav icons |
| `ink-4` | `rgba(245,245,241,.24)` | 2.0:1 | Disabled text and glyphs only. Never carries information. |
| `hair` | `rgba(245,245,241,.08)` | n/a | Hairlines, poster inner edge, dividers |
| `hair-strong` | `rgba(245,245,241,.16)` | n/a | Focused input underline at rest, outline badges, secondary button ring |
| `veil` | `rgba(245,245,241,.12)` | n/a | Secondary button fill |

#### 2.1.2 House light: the one fixed hue

| Token | Value | Contrast on `void` | Use |
|---|---|---|---|
| `house` | `#FFB547` (tungsten) | 11.9:1 | Fallback accent when no art owns the frame: active nav dot, caret, input focus underline, progress fill on non-series screens, NEW badge fill, streak flame core, the wordmark gutter bar |
| `house-pressed` | `#E89A2C` | 9.3:1 | Pressed tungsten marks |
| `house-glow` | `#573E19` | n/a | Bloom colour when no art owns the frame |
| `house-tint` | `#18130C` | n/a | Page spill when no art owns the frame |

Tungsten is a mark, never a surface. The largest tungsten area allowed anywhere is the 3 × 32 px title rule, the 4 px progress bar and the NEW badge (≤ 44 × 18 px).

#### 2.1.3 Semantic roles

| Role | Token | Value | On `void` | Rule |
|---|---|---|---|---|
| Danger, destructive, 18+ | `rating` | `#FF5C5C` | 6.9:1 | 18+ badges, the rating card bar, destructive button text, error lines. Never a large fill. |
| Success, downloaded, synced | `positive` | `#3DD68C` | 11.2:1 | Downloaded tick, "Saved", sync confirmations |
| Caution, storage floor, slow down | `caution` | `#FFD27A` | 14.1:1 | Rate-limit and storage-floor lines. Distinct from `house` by lightness. |
| Info | `info` | `#7AB8FF` | 9.4:1 | "Offline copy from 14:02" stale badges, AI "uses an external service" note |
| Focus ring | `focus` | `#F5F5F1` | 19.3:1 | 2 px ring, 3 px offset, on `:focus-visible` only |

Text on a `rating` or `positive` fill is `#000000`. Text on `house` is `#000000`.

#### 2.1.4 Key light: colour thrown by the art

Every screen has exactly one **key-light owner**: the artwork that decides the colour of the frame. The owner exposes five roles. Components never hard-code a hue; they read these roles.

| Role | Derivation (HLS from the seed colour) | Where it lands |
|---|---|---|
| `key.seed` | Dominant colour: quantise the art to 8 colours (median cut), skip swatches with L < 0.08 or L > 0.94, pick the one with the highest `count × (0.35 + S)` | Not drawn; input to the others |
| `key.tint` | seed hue, L 0.07, S min(S, 0.35) | Page spill under heroes, the colour hero scrims fade *into*, the "Key" novel paper background, sheet top edge wash |
| `key.wash` | seed hue, L 0.12, S min(S, 0.40) | Pressed row fill on series-scoped screens, the rail header underlight, the mini player fill |
| `key.glow` | seed hue, L 0.22, S min(S, 0.55) | Bloom behind focused posters, title backlight, reader chrome underglow, avatar spotlight |
| `key.accent` | seed hue, L 0.70, S clamp(S, 0.45, 0.85); raise L by 0.04 until contrast on `void` ≥ 4.5:1 and on `key.tint` ≥ 4.5:1 | Replaces `house` on series-scoped screens: progress fill, unread dots, the active chapter edge, focus underline, NEW badge fill, scrubber fill |
| `key.ink` | `ink` mixed 6 % toward `key.accent` in OKLab | Hero and detail titles only. Contrast is guaranteed ≥ 15:1. |

Greyscale or missing art (S < 0.08 on every swatch) falls back to the house roles: tint `#18130C`, wash `#231B11`, glow `#573E19`, accent `#FFB547`, ink `#F5F5F1`.

**Where each role is computed**

| Art | Computed by | When | Delivered as |
|---|---|---|---|
| Series cover | Backend, next to cover resizing (`backend/services/image_resize.py`), Pillow + stdlib `colorsys`, cached with the cover | Once per cover URL | `ambient: {seed, tint, wash, glow, accent}` on every series, follow, continue-reading, history, bookmark, notification-join, recommendation and activity payload |
| Reader page (manhwa, manga) | Client. Web: draw the decoded page into a 16 × 16 `OffscreenCanvas`, take the most saturated pixel with 0.1 < L < 0.9. Flutter: `ColorScheme.fromImageProvider(ResizeImage(provider, width: 64), brightness: Brightness.dark)`, use `.primaryContainer` as the seed | When the page under the reading line changes, throttled to one sample per 600 ms | Local state in the reader engine |
| Profile avatar | Static table (below), because avatars are drawn by the skin | At profile load | Constant |
| AniList cover (world recommendations) | Backend, same extractor, on the proxied cover | Once per `anilist_id` | `ambient` on `WorldItem` |

**Profile mood seeds** (used when a screen has no art in frame, such as Settings, and for the profile picker spotlight). Each mood is a seed; roles derive from it with the same rules.

| Mood | Seed | Resulting glow | Resulting accent |
|---|---|---|---|
| Default | tungsten `#FFB547` | `#573E19` | `#FFB547` |
| Romantic | `#E0527A` | `#5B1A2C` | `#F07C9C` |
| Action | `#E4572E` | `#5A2012` | `#F28A68` |
| Comedy | `#F2C94C` | `#57470F` | `#F4D46E` |
| Horror | `#6BA38C` | `#223A31` | `#84BFA7` |
| Slice of life | `#8FC46A` | `#2F4A1C` | `#A4D184` |
| Fantasy | `#8A6CF0` | `#2B1A63` | `#A895F5` |

**Key-light ownership per screen**

| Screen | Owner |
|---|---|
| Home | The hero series; the focused poster after a 450 ms dwell |
| Series detail | That series' cover |
| Reader | The page under the reading line (page-tinted chrome) |
| Novel reader | The series cover (the paper can adopt it via the "Key" paper) |
| Library, Collections, History, Bookmarks, Updates, Downloads | The row or poster under focus or hover; otherwise the most recent item's cover |
| Search | The top result |
| Sources list | The focused source's newest cover |
| Source catalogue | The focused poster |
| Stats, Wrapped | The top series of the period |
| Circle (social) | The newest activity item's cover |
| Profile picker | The focused profile's mood |
| Settings, Admin, auth, setup | The active profile's mood (auth and setup: Default) |

**Transitions between owners.** Roles are registered custom properties on web (`@property --key-tint { syntax: "<color>"; inherits: true; initial-value: #18130C; }` and the same for the others) and `ColorTween`s on Flutter. A change of owner dissolves every role over `dissolve` (800 ms, `cine-in-out`). A change caused by page tint in the reader dissolves over 1200 ms so the room never flickers during fast scrolls.

#### 2.1.5 Scrims

Every long fade uses the eased 13-stop scrim curve so black never bands:

| Stop | 0 % | 1.8 % | 4.8 % | 9 % | 13.9 % | 19.8 % | 27 % | 35 % | 43.5 % | 53 % | 66 % | 81 % | 100 % |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Alpha | 0 | .002 | .008 | .021 | .042 | .075 | .126 | .194 | .278 | .382 | .541 | .738 | 1 |

| Token | Geometry | End colour | Use |
|---|---|---|---|
| `scrim-hero-foot` | Bottom 55 % of the hero (phone 70 %), top → bottom | `key.tint` | Hero dissolves into the lit page |
| `scrim-hero-title` | Full hero at 77° (Flutter `Alignment(-1, .23)` → `Alignment(1, -.23)`) | `#000` at `.82 / .56 / .22 / 0` at `0 / 24 / 46 / 68 %` | Legibility behind the bottom-left title block on ≥ 768 px |
| `scrim-top` | Top 128 px desktop; safe-area + 72 px phone | `#000` at `.72 / .38 / 0` at `0 / 50 / 100 %` | Top bar legibility over art |
| `scrim-bottom` | Bottom 120 px + safe area | `#000`, eased curve | Bottom nav and reader bottom chrome |
| `scrim-reader-top` | Top 112 px + safe area | `#000` at `.80 / .45 / 0`, blended 24 % toward `key.tint` | Reader top chrome |
| `scrim-reader-bottom` | Bottom 140 px + safe area | eased curve to `#000`, blended 24 % toward `key.tint` | Reader bottom chrome |
| `scrim-poster-caption` | Bottom 60 % of a poster | `#000` at `.9 / .6 / 0` at `0 / 30 / 60 %` | Focus and preview state captions only |
| `scrim-rail-edge` | 4 vw at each rail end (desktop) | `#000` → transparent, linear | Behind rail paddles |
| `scrim-vignette` | Full frame radial `125 % 95 % at 50 % 40 %` | `rgba(0,0,0,0)` at 58 % → `rgba(0,0,0,.5)` at 100 % | Hero, detail backdrop, Wrapped, pre-roll |
| `scrim-modal` | Full screen | `rgba(0,0,0,.72)`, never blurred | Behind sheets, dialogs, palette |
| `scrim-lightbox` | Full screen | `#000` at `.94` | Behind the full-art lightbox |

Hero layer order, bottom to top: `key.tint` page spill → blurred fill copy of the art (60 px, brightness .5) → the art (Ken Burns) → grain (overlay) → `scrim-vignette` → `scrim-hero-title` → `scrim-hero-foot` → title backlight (`radial-gradient(60% 55% at 22% 70%, key.glow @ 20 %, transparent 70 %)`) → content → `scrim-top`.

### 2.2 Typography

#### 2.2.1 Families (all from Google Fonts, all SIL Open Font License 1.1)

| Role | Family | Axes used | Why |
|---|---|---|---|
| Display: titles, section heads, numerals | **Mona Sans** | `wdth` 75–100, `wght` 600–900 | Condensed grotesk caps give every series a title treatment even though covers have no logo. The width axis animates, which drives the "track-out" moments. |
| UI and body | **Geist** | `wght` 400–700 | Neutral, open at 12–13 px on black, so it disappears next to the art |
| Timecode and numbers | **Geist Mono** | `wght` 500–600, `tnum` | Chapter and time readouts ("CH 142 · 12 MIN") read like a projectionist's counter |
| Editorial title cards | **Instrument Serif** | Regular, Italic | "Previously on", Wrapped headlines, empty-state title cards, the novel chapter opener. Nowhere else. |
| Novel reading (default) | **Newsreader** | `opsz` 6–72 (= size), `wght` 380–600 | Designed for long reading on screens |
| Novel reading (options) | **Literata**, **Source Serif 4**, **Atkinson Hyperlegible Next**, **Geist** | `opsz` where available, `wght` | Two more serifs, one high-legibility sans and the UI sans |
| CJK fallback | **Noto Sans KR**, **Noto Sans JP**, **Noto Sans SC** | `wght` | Alternate titles. CJK titles drop uppercase and `wdth` and render at `wght` 800 one size down. |

Delivery: web uses `next/font/google` (`Mona_Sans` with `axes: ["wdth"]`, `Geist`, `Geist_Mono`, `Instrument_Serif`, `Newsreader` with `axes: ["opsz"]`, `Literata`, `Source_Serif_4`, `Atkinson_Hyperlegible_Next`, Noto families with `preload: false`). Mona Sans uses `display: "block"` and is preloaded, because a font swap mid-reveal breaks the per-letter animation. Every other face uses `display: "swap"`. Flutter bundles the variable TTFs from `github.com/google/fonts/tree/main/ofl/<family>` as assets and drives axes with `FontVariation` (the `google_fonts` package cannot reach `wdth` or `opsz`). Flutter sets `FontVariation('opsz', fontSize)` explicitly for Newsreader, Literata and Source Serif 4.

Kerning is disabled (`font-kerning: none`, `FontFeature.disable('kern')`) only on text that runs the per-letter reveal, so split and unsplit text are identical. Tabular figures (`tnum`) are on for every number that updates in place.

#### 2.2.2 Scale

Breakpoints: **D** desktop ≥ 1280 px, **T** tablet and small laptop 768–1279 px, **P** phone < 768 px (mobile web, iOS, Android). Sizes in px, line height as a ratio, tracking in em.

| Token | Family · weight · width | D | T | P | LH | Tracking | Case | Use |
|---|---|---|---|---|---|---|---|---|
| `display-hero` | Mona · 850 · 75 | clamp(64, 7vw, 120) | 64 | clamp(40, 11vw, 56) | 0.86 | −0.025 | UPPER | Hero series title, Wrapped scene numbers |
| `display-title` | Mona · 800 · 75 | clamp(48, 4.6vw, 80) | 48 | 36 | 0.90 | −0.02 | UPPER | Series detail title, pre-roll wordmark |
| `display-page` | Mona · 780 · 80 | 44 | 36 | 30 | 0.95 | −0.015 | UPPER | Page titles (LIBRARY, SOURCES) |
| `heading-section` | Mona · 760 · 85 | 26 | 23 | 20 | 1.00 | −0.01 | UPPER | H3 rail and section headers (per-letter reveal) |
| `heading-card` | Geist · 600 | 17 | 16 | 15 | 1.20 | −0.005 | Sentence | Preview slate title, list primary lines, sheet titles |
| `typed-headline` | Mona · 820 · 78 | 56 | 44 | 32 | 0.95 | −0.02 | UPPER | Home main headline (typing reveal) |
| `editorial-lg` | Instrument Serif 400 | 56 | 48 | 36 | 1.00 | −0.01 | Sentence, italic allowed | "Previously on", Wrapped headlines |
| `editorial-md` | Instrument Serif 400 | 30 | 28 | 24 | 1.10 | 0 | Sentence | Empty-state title cards, pull quotes, chapter openers |
| `eyebrow` | Geist · 600 | 12 | 12 | 11 | 1.20 | +0.18 | UPPER | "MANHWA · ONGOING · 2024", slate tab labels, filter text |
| `body-lg` | Geist · 400 | 17 | 17 | 16 | 1.55 | 0 | Sentence | Synopsis (ink-2), max 62 ch |
| `body` | Geist · 400 | 15 | 15 | 15 | 1.50 | 0 | Sentence | Default text |
| `body-strong` | Geist · 600 | 15 | 15 | 15 | 1.40 | 0 | Sentence | List primary, toast lines |
| `label` | Geist · 600 | 15 | 15 | 15 | 1.00 | +0.01 | Sentence | Button labels |
| `label-sm` | Geist · 600 | 13 | 13 | 13 | 1.00 | +0.02 | Sentence | Small buttons, chips |
| `caption` | Geist · 400 | 13 | 13 | 13 | 1.40 | 0 | Sentence | Metadata (ink-3) |
| `timecode` | Geist Mono · 600 | 13 | 13 | 12 | 1.20 | +0.04 | UPPER | "CH 142 · 64 %", "2H AGO", page counters |
| `micro` | Geist · 700 | 11 | 11 | 10 | 1.30 | +0.08 | UPPER | Badges, nav labels |
| `numeral-xl` | Mona · 900 · 75 | 160 | 128 | 96 | 0.80 | −0.03 | n/a | Top-10 outline numerals, Wrapped totals, streak count |

Title-length rules: a hero title over 28 characters steps down to `display-title`; over 48 characters it also clamps to 3 lines with `text-wrap: balance` (Flutter: `TextWidthBasis.longestLine` inside a `ConstrainedBox(maxWidth: 640)`).

**Title treatment recipe** (the logo substitute for every series, used by hero, detail and Wrapped):
1. Eyebrow: `FORMAT · STATUS · YEAR` in `eyebrow`, ink-2.
2. Title: `display-hero` or `display-title` in `key.ink`, uppercase, `wdth 75`.
3. Rule: a 3 × 32 px bar in `key.accent`, 16 px below the title baseline. It draws in left to right over 480 ms `cine-out` after the last letter lands.
4. Hook: one line of genres or the first sentence of the synopsis, `body-lg` ink-2.

#### 2.2.3 Mobile text scale

The OS text scale (iOS Dynamic Type, Android font scale, browser zoom on mobile web) is honoured with these caps, applied through a per-token `maxScale` in the token JSON:

| Token group | Scale applied | Cap |
|---|---|---|
| `display-*`, `typed-headline`, `numeral-xl`, `editorial-lg` | Scaled | 1.30 |
| `heading-section`, `heading-card`, `editorial-md` | Scaled | 1.60 |
| `body*`, `label*`, `caption` | Scaled | 2.00 |
| `eyebrow`, `timecode`, `micro` | Scaled | 1.40 |
| Bottom nav labels | Scaled | 1.20; above 1.20 the labels hide and icons grow to 28 px |
| Novel text | Not scaled by the OS; the reader has its own 14–32 px size control, and its default picks up the OS scale on first launch (19 px × scale, clamped 16–28) |

At a scale ≥ 1.6 the layout switches: poster rails show 2.3 posters instead of 3.3 on phones, list rows wrap their metadata onto a second line, and the reader's bottom chrome stacks the page counter above the scrubber.

### 2.3 Spacing

Base unit 4 px.

| Token | px | Typical use |
|---|---|---|
| `s-1` | 4 | Icon to label inside a chip |
| `s-2` | 8 | Poster gap (phone), stacked caption lines |
| `s-3` | 12 | Header to rail, poster gap (desktop) |
| `s-4` | 16 | Phone gutter minimum, list row horizontal padding |
| `s-5` | 20 | Sheet padding (phone) |
| `s-6` | 24 | Sheet padding (desktop), dialog padding |
| `s-8` | 32 | Rail stack (phone) |
| `s-10` | 40 | Rail stack (desktop) |
| `s-12` | 48 | Section break |
| `s-16` | 64 | Top of page title to content (desktop) |
| `s-24` | 96 | Chapter seam in the reader, credits block spacing |
| `gutter` | `clamp(16px, 4.5vw, 72px)` | Horizontal title-safe inset on every screen |
| `rail-overlap` | −96 desktop, −56 tablet, −40 phone | First rail pulled up into the hero scrim |
| `hit-min` | 44 | Minimum hit target on every platform, including inside chrome |

### 2.4 Radius

| Token | px | Where |
|---|---|---|
| `r-0` | 0 | Heroes, reader pages, full-bleed art, bottom nav, top bars, the reader |
| `r-hair` | 2 | Badges, progress bars (ends stay square), toasts, key caps |
| `r-frame` | 6 | Posters, 16:9 cards, buttons, inputs, thumbnails |
| `r-sheet` | 12 | Top corners of sheets, dialogs, menus, the preview slate |
| `r-round` | 9999 | Only: round icon buttons, avatars, the toggle, the leader sweep, the chip dot |

Cinematic never uses pill-shaped buttons, pill chips or pill progress bars.

### 2.5 Elevation is light

Shadows are invisible on `#000`, so depth is made of surface steps and bloom.

| Level | Surface | Edge | Light | Used by |
|---|---|---|---|---|
| E0 | `void` | none | none | Pages, lists, the reader |
| E1 | `void` | `hair` 1 px inner edge on art | none | Posters and cards at rest |
| E2 | `n-150` | top edge `hair`, top 24 px washed with `key.tint` → transparent | none | Sheets, menus, dialogs, context menus, palette |
| E3 | art | `hair-strong` inner edge | bloom `0 0 56px -12px key.glow` | Focused or hovered poster, preview slate |
| E4 | art | none | bloom `0 0 96px -8px key.glow` at 70 % + a 1.06 scale | Lightbox, the profile spotlight, the Wrapped hero card |

Bloom on the primary CTA when focused: `0 0 0 3px #000, 0 0 0 5px #F5F5F1, 0 0 32px rgba(245,245,241,.25)`.

### 2.6 Blur

Blur is applied **to art only, never to UI**. No `backdrop-filter` panes exist in this skin.

| Token | Value | Use |
|---|---|---|
| `blur-fill` | 60 px, brightness .5, saturate 1.2 | Filling bare areas around portrait art in wide frames |
| `blur-bloom` | 40 px, saturate 1.6, brightness 1.1, opacity .5, inset −8 % | Bloom copy behind hero art |
| `blur-focus-pull` | 16 px → 0 over 520 ms | Image load (rack focus) |
| `blur-letter` | 10 px → 0 over 500 ms | Per-letter reveal |
| `blur-slate` | 24 px | Preview slate backdrop, Up Next card backdrop |
| `blur-lightbox-under` | 0 | The page under the lightbox is dimmed, not blurred |

### 2.7 Borders

| Token | Value | Use |
|---|---|---|
| `line` | 1 px `hair` | Dividers, list separators (inset by `gutter`), sheet top edge |
| `line-strong` | 1 px `hair-strong` | Outline badges, secondary icon-button ring (1.5 px), empty poster frame |
| `line-focus` | 2 px `focus`, offset 3 px, radius follows the target + 3 px | Keyboard focus |
| `line-input` | 2 px underline, `key.accent` (or `house`) | Input focus, drawn from the left over 280 ms |
| `line-active` | 2 px `key.accent` | Active slate tab, active chapter row left edge |

### 2.8 Iconography

- **Set:** Phosphor (`@phosphor-icons/react` 2.1.10 on web, `phosphor_flutter` 2.1.0 on Flutter, both MIT, 1:1 glyph parity). **Bold** weight for resting icons, **Fill** weight for the active or on state of the same glyph. Square line caps read like film-slate crispness.
- **Sizes:** 16 (inline with caption), 20 (buttons, list rows), 24 (top bars, nav, reader chrome), 28 (bottom nav at large text scale), 32 (empty and error title cards).
- **Colour:** icons inherit text colour: ink at rest in chrome, ink-3 for inactive nav, `key.accent` for on states that mean progress (bookmark saved, downloaded uses `positive`).
- **Custom glyphs** (drawn on Phosphor's 256 grid, 16 px stroke to match Bold, shipped as SVG on web and as a small icon font `MMGlyphs.ttf` on Flutter):

| Glyph | Meaning | Drawing |
|---|---|---|
| `mm-strip` | Webtoon (vertical) mode | Three stacked rounded panels with 8-unit gutters |
| `mm-spread` | Double-page mode | Two panels side by side with a spine line |
| `mm-autoscroll` | Auto-scroll | A strip with a downward chevron inside |
| `mm-panel` | Panel-by-panel view | A panel with four corner brackets (a camera frame) |
| `mm-voices` | Voices and cast | Two overlapping speech tails |
| `mm-xray` | Dialogue search (OCR) | A speech bubble with a scan line |
| `mm-flame` | Streak | A three-tongue flame |
| `mm-circle` | Circle (social) | Three offset rings |
| `mm-previously` | Recap | A rewind double chevron over a panel |
| `mm-soundscape` | Ambient sound | A wave inside a panel frame |

- **Phosphor glyphs used** (Bold / Fill pairs): House, Books, Compass, MagnifyingGlass, Bell, DownloadSimple, UserCircle, Play, Pause, Plus, Check, Info, X, CaretLeft, CaretRight, CaretDown, ArrowLeft, BookmarkSimple, Heart, Star, SlidersHorizontal, TextAa, ListBullets, SpeakerHigh, SpeakerSlash, Moon, Sun, Timer, Gauge, ArrowsOut, ArrowsIn, MagnifyingGlassPlus, MagnifyingGlassMinus, Trash, PushPin, WifiSlash, ArrowClockwise, Warning, ShieldCheck, Key, SignOut, Gear, Keyboard, Command, Share, Export, Sparkle, ChartBar, ClockCounterClockwise, Folder, Stack, Globe, FunnelSimple, SortAscending, DotsThree, DotsSixVertical, Eye, EyeSlash, Lock, UsersThree, PaperPlaneTilt, Smiley, Fire, Crown, Headphones, Waveform, Rewind, FastForward, SkipBack, SkipForward, HardDrives, Pulse, CloudArrowUp, CloudArrowDown, Copy.

### 2.9 Motion

#### 2.9.1 Principles

1. **Camera, not objects.** Layers translate, scale and dissolve like a camera. Nothing rotates in 3D, wobbles or overshoots.
2. **Decisive in, quiet out.** Entrances use `cine-out`. Exits use `cine-in` and run at 0.75× the entrance duration.
3. **Cuts are allowed.** A 0 ms change is correct when the scene does not change (filter, sort, tab inside a page).
4. **Ambient motion is very slow.** Ken Burns, grain and glow run on 8–24 s periods so they never pull the eye away from the art.

#### 2.9.2 Durations

| Token | ms | Use |
|---|---|---|
| `tick` | 90 | Press scale down, caret step |
| `quick` | 160 | Toggle knob, press release, icon swap, toast in |
| `base` | 280 | Hover lift, sibling dim, focus underline draw, chrome in |
| `scene` | 480 | Match cut, title rule draw, slate open |
| `curtain` | 600 | Letterbox open, pre-roll sections |
| `dissolve` | 800 | Key-light change, hero rotation, backdrop swap |
| `hold-title` | 1200 | Title card holds ("PREVIOUSLY ON", chapter end) |
| `drift` | 24000 | Ken Burns cycle |

#### 2.9.3 Easing curves

| Token | Value | Use |
|---|---|---|
| `cine-out` | `cubic-bezier(0.16, 1, 0.3, 1)` | Every entrance |
| `cine-in` | `cubic-bezier(0.7, 0, 0.84, 0)` | Every exit |
| `cine-in-out` | `cubic-bezier(0.65, 0, 0.35, 1)` | Dissolves, match cuts, dolly moves |
| `drift` | `cubic-bezier(0.37, 0, 0.63, 1)` | Ken Burns, flicker, breathing glows |
| `linear` | `linear` | Leader sweep, auto-scroll, progress |

#### 2.9.4 Springs (gesture releases only, all critically damped)

Springs exist only where a finger hands off velocity. They never overshoot.

| Token | Spec (`{ms, bounce}`) | Flutter `SpringDescription` | Motion (web) | Use |
|---|---|---|---|---|
| `rig` | `{ms: 300, bounce: 0}` | mass 1, stiffness 439, damping 41.9 | `{type: "spring", visualDuration: .3, bounce: 0}` | Sheet release to a detent, scrubber thumb settle, rail fling snap |
| `dolly` | `{ms: 520, bounce: 0}` | mass 1, stiffness 146, damping 24.2 | `{type: "spring", visualDuration: .52, bounce: 0}` | Panel-by-panel camera between panels when driven by a swipe, lightbox dismiss drag release |
| `slate` | `{ms: 360, bounce: 0}` | mass 1, stiffness 305, damping 34.9 | `{type: "spring", visualDuration: .36, bounce: 0}` | Swipe-to-dismiss on toasts and rows |

#### 2.9.5 Stagger rules

| Context | Step | Cap | Order |
|---|---|---|---|
| Per-letter reveal | `min(28, 600 / (n − 1))` ms | 600 ms total | Reading order |
| Rail posters entering (first paint only) | 40 ms | first 6 posters (200 ms); the rest appear with the sixth | Left to right |
| Grid posters (library, catalogue) | 24 ms per cell in reading order | 12 cells (264 ms) | Row by row |
| List rows | 24 ms | 8 rows | Top to bottom |
| Skeleton flicker phase offset | 60 ms | n/a | Left to right |
| Per-word AI text fade | 30 ms apart, 160 ms each | none (it streams) | Reading order |

Staggers play once per mount. Returning to a screen through back shows content at rest (no replay).

#### 2.9.6 Interruptibility

- Every animation starts from the current presented value, never from its nominal start (Motion's default; Flutter drives controllers with `animateTo` from `value`).
- A reverse gesture (back swipe, Esc, tapping outside) during an entrance reverses the same timeline from the current progress at 0.75× speed.
- Route transitions are cancelable until 60 % progress; after that, a back action queues and plays after the landing.
- Key-light dissolves retarget: a new owner mid-dissolve starts a new 800 ms dissolve from the currently displayed colour.
- The typing reveal and per-letter reveal complete instantly on any tap, click, Enter or Space inside them.
- Ken Burns never restarts on re-render; it restarts only when the hero series changes, under the dissolve.

#### 2.9.7 Reduced motion (OS setting)

| Effect | Reduced variant |
|---|---|
| Per-letter reveal | Whole string fades in over 200 ms |
| Typing reveal | Full text at once, no caret |
| Ken Burns, parallax, grain animation | Static frame at scale 1.04, focal point 50 % 25 %; grain static |
| Match cut, push-in, letterbox curtain, dip to black | 200 ms crossfade |
| Key-light dissolve | 200 ms crossfade |
| Hover lift, preview slate grow | Instant state change, no scale |
| Hero auto-advance | Off |
| Panel-by-panel camera | Cuts between panels |
| Auto-scroll | Still available (user-started) |

### 2.10 Haptics vocabulary

Cinematic haptics are **weight**: low sharpness, few events, silence as the default. Taps on ordinary buttons, icon buttons, chips, scrolling and chrome show/hide produce nothing. All events route through one `SkinHaptics` class behind the Settings toggle "Haptic feedback" (default on). iOS uses `gaimon` 1.5.0 AHAP patterns and named impacts; Android uses `gaimon`'s waveform conversion of the same AHAP; the web maps a small subset to `navigator.vibrate` on Android Chrome and nothing elsewhere.

| Event name (contract) | Moment | Pattern | iOS | Android | Web (Android Chrome) |
|---|---|---|---|---|---|
| `press.primary` | Primary button pressed | `rigid` | `Gaimon.rigid()` | `rigid` waveform | none |
| `toggle.on` | Toggle switched on | `medium` | `Gaimon.medium()` | graded medium | none |
| `toggle.off` | Toggle switched off | `light` | `Gaimon.light()` | graded light | none |
| `nav.tab` | Bottom-nav tab changed | `rigid` | `Gaimon.rigid()` | rigid | none |
| `poster.longpress` | Long press opens the preview sheet or lightbox | `heavy` | `Gaimon.heavy()` | graded heavy | `[18]` |
| `sheet.detent` | Sheet snaps to a detent | `medium` | `Gaimon.medium()` | medium | none |
| `sheet.dismiss` | Sheet or overlay dismissed by drag | `light` | `Gaimon.light()` | light | none |
| `refresh.armed` | Pull-to-refresh crosses its threshold | `medium` | `Gaimon.medium()` | medium | none |
| `library.add` | Follow / add to library | AHAP `stamp` | pattern | converted waveform | `[12]` |
| `library.remove` | Unfollow | `light` | `Gaimon.light()` | light | none |
| `download.start` | Download queued | `light` | light | light | none |
| `download.done` | Download completed (foreground) | AHAP `reel-lock` | pattern | waveform | none |
| `download.fail` | Download failed | `error` | `Gaimon.error()` | error | `[20, 60, 20]` |
| `chapter.endcard` | Up Next card enters | AHAP `curtain` | pattern | waveform | none |
| `chapter.commit` | Next or previous chapter opened | `heavy` | heavy | heavy | none |
| `page.turn` | Paged-mode page turn, novel page turn | `selection` | `Gaimon.selection()` | selection | none |
| `scrub.step` | Scrubber crosses 10 % or a chapter segment | `selection` | selection | selection | none |
| `autoscroll.step` | Auto-scroll speed step | `rigid` | rigid | rigid | none |
| `autoscroll.end` | Auto-scroll reaches the end card | `heavy` | heavy | heavy | none |
| `bookmark.save` | Bookmark saved | AHAP `clap` | pattern | waveform | `[10]` |
| `gate.unlock` | 18+ enabled on a profile | AHAP `vault` | pattern | waveform | none |
| `streak.extend` | Streak +1 (first chapter of the day completed) | AHAP `ignite` | pattern | waveform | `[12, 120, 8]` |
| `reaction.send` | Reaction placed on a chapter | `medium` | medium | medium | none |
| `recommend.send` | "Recommend to" sent | `success` | `Gaimon.success()` | success | `[8]` |
| `tts.toggle` | Narration play or pause | `rigid` | rigid | rigid | none |
| `panel.next` | Panel-by-panel advances | `selection` | selection | selection | none |
| `brand.stamp` | Logo reveal stamp at 820 ms | AHAP `stamp` | pattern | waveform | none |
| `skin.confirm` | Skin switch confirmed, before the restart | `heavy` | heavy | heavy | none |
| `profile.pick` | Profile chosen on the picker | AHAP `spotlight` | pattern | waveform | none |
| `error` | Any failed action | `error` | error | error | `[20, 60, 20]` |
| `unlock.reader` | Reader unlocked (five taps) | `medium` | medium | medium | none |

AHAP signatures (T = transient, C = continuous, I = intensity, S = sharpness, times in s). Only transients and continuous events are used so the Android conversion matches.

| Name | Events |
|---|---|
| `stamp` | T@0.000 I1.0 S0.25; T@0.060 I0.35 S0.10 |
| `reel-lock` | T@0.000 I0.7 S0.35; T@0.080 I0.9 S0.30 |
| `curtain` | C@0.000 dur 0.300 I0.35 S0.15; T@0.300 I0.6 S0.20 |
| `vault` | T@0.000 I0.4 S0.3; T@0.060 I0.6 S0.3; T@0.120 I1.0 S0.25 |
| `ignite` | C@0.000 dur 0.400 I0.5 S0.2; T@0.400 I1.0 S0.3 |
| `clap` | T@0.000 I0.8 S0.45 (a single slate clap) |
| `spotlight` | C@0.000 dur 0.420 I0.25 S0.10; T@0.420 I0.7 S0.25 |

### 2.11 UI sounds ("Projector", off by default)

Settings → Sound → "Interface sounds" (default **off**) and "Sound volume" (0–100 %, default 60 %). Sounds follow the iOS ring/silent switch (`.ambient` category), never duck the user's music, and are suppressed while narration or a soundscape plays. All files are synthesised (sox `synth` scripts), 48 kHz 16-bit mono WAV, 5 ms fade in and out, the whole set under 300 KB. Key of D, low-passed below 4 kHz, short 0.4 s room.

| Event name | Moment | Length | Recipe | Peak |
|---|---|---|---|---|
| `ui.focus` | Keyboard or dwell focus moves along a rail | 18 ms | Band-passed noise tock at 2.8 kHz (Q 2) | −30 dBFS |
| `ui.select` | Open detail, press a primary button | 90 ms | Felt-piano rising fifth D5 → A5 | −18 dBFS |
| `ui.back` | Back, close a sheet | 70 ms | Falling fifth A4 → D4, softer | −22 dBFS |
| `ui.toggle-on` / `ui.toggle-off` | Toggles | 40 / 20 ms | Two mechanical clicks 18 ms apart / one click | −24 dBFS |
| `ui.page` | Rail paddle page, hero swipe | 140 ms | Air whoosh, band-passed noise 1–6 kHz | −26 dBFS |
| `ui.swap` | Key-light dissolve on hero change | 400 ms | 60 Hz sine swell with a short tail | −28 dBFS |
| `ui.stamp` | Add to library | 160 ms | 55 Hz sine, 120 ms exponential decay, plus a felt click | −16 dBFS |
| `ui.reel-lock` | Download done | 420 ms | Two clicks 80 ms apart, then saw D3 (146.83 Hz) swell with a 400 → 1600 Hz low-pass sweep | −18 dBFS |
| `ui.curtain` | Up Next card | 600 ms | Filtered noise riser, high-pass 200 Hz → 2 kHz | −22 dBFS |
| `ui.ignite` | Streak +1 | 450 ms | 250 ms whoosh plus a D3 + A3 fifth | −16 dBFS |
| `ui.rating` | 18+ rating card | 900 ms | Low filtered hum, like house lights going down | −26 dBFS |
| `ui.error` | Failed action | 180 ms | D3 → C♯3 saw, low-pass 900 Hz | −20 dBFS |
| `ui.sting` | Logo reveal | 1800 ms | D2 + A2 saw pad, low-pass sweep 300 → 2400 Hz over 700 ms, transient at 820 ms with the stamp, 1.4 s tail | −12 dBFS |

Playback: web uses the Web Audio API (decode each WAV once into an `AudioBuffer` after the first user gesture, one master `GainNode`); Flutter uses `flutter_soloud` 5.1.4 with every file preloaded at startup when the toggle is on.

---
## 3. Component catalog

Conventions for every table below:
- **Hover** exists only on devices with `(hover: hover) and (pointer: fine)`. Touch devices skip it.
- **Focused** is `:focus-visible` on web and hardware-keyboard focus (`FocusNode` with `highlightMode == traditional`) on Flutter. It always draws `line-focus` unless the row says otherwise.
- **Pressed** on touch starts on pointer down and releases on pointer up or cancel.
- `accent` below means `key.accent` when a series owns the frame, otherwise `house`.
- Every interactive element has a 44 × 44 px minimum hit area even when drawn smaller.

### 3.1 Buttons

Four families. No button is ever filled with a hue: the primary is projector white, everything else is quieter.

**Sizes**

| Size | Height | Horizontal padding | Label | Icon | Radius |
|---|---|---|---|---|---|
| `lg` | 52 | 28 | `label` 16 px | 22 | `r-frame` |
| `md` | 44 | 20 | `label` 15 px | 20 | `r-frame` |
| `sm` | 36 (hit area 44) | 14 | `label-sm` | 16 | `r-frame` |

**B1 Primary** ("Read", "Continue Ch. 142", "Sign in", "Save")

| State | Visual | Motion |
|---|---|---|
| Default | Fill `ink` `#F5F5F1`, label `#000000` weight 600, leading solid Play glyph (Fill) for read actions | none |
| Hover | Fill `#FFFFFF` at 92 % mixed over ink (`#F9F9F6`), bloom `0 0 32px rgba(245,245,241,.18)` | `base` 280 ms `cine-out` |
| Pressed | Scale 0.97, fill `#E4E4E0` | down `tick` 90 ms, release `quick` 160 ms `cine-out`; haptic `press.primary`; sound `ui.select` |
| Focused | `line-focus` plus the CTA focus bloom from §2.5 | ring appears instantly |
| Disabled | Fill `n-200`, label `ink-4`, no glyph colour | none |
| Loading | Label replaced by a 20 px leader sweep in `#000` on the ink fill, width locked to the resting width | label crossfade `quick` |
| Selected | n/a (primary buttons do not toggle) | n/a |
| Error | Returns to Default; the error line appears below the form, and the button shakes nothing | none |

**B2 Secondary** ("Details", "Add to library", "Cancel")

| State | Visual | Motion |
|---|---|---|
| Default | Fill `veil` `rgba(245,245,241,.12)`, label `ink` | none |
| Hover | Fill `rgba(245,245,241,.20)` | `base` |
| Pressed | Scale 0.97, fill `rgba(245,245,241,.26)` | `tick` / `quick` |
| Focused | `line-focus` | instant |
| Disabled | Fill `rgba(245,245,241,.06)`, label `ink-4` | none |
| Loading | 20 px leader sweep in ink | crossfade `quick` |
| Selected (toggle secondary, such as "In library") | Leading Check glyph (Fill) in accent, label "In library" | glyph swap `quick`; haptic `library.add` and a 3 × 32 px accent rule draws under the button over `scene` |
| Error | Label swaps to "Try again" in `rating` for 4 s | `quick` |

**B3 Text** (inline actions, "See all", "Reset", "Undo")

| State | Visual | Motion |
|---|---|---|
| Default | No fill, label ink-2, 36 px tall | none |
| Hover | Label ink, 1 px underline at 3 px offset | `base` |
| Pressed | Label ink at 80 % | `tick` |
| Focused | `line-focus` around the text box | instant |
| Disabled | Label `ink-4` | none |
| Loading | Label followed by a 14 px leader sweep | none |
| Selected | Label accent with a 4 px accent dot before it | `quick` |
| Error | Label `rating` | none |

**B4 Destructive** ("Delete profile", "Remove downloads", "Sign out everywhere")

| State | Visual | Motion |
|---|---|---|
| Default | No fill, 1.5 px ring `rating` at 60 %, label `rating` | none |
| Hover | Ring `rating` 100 %, fill `rgba(255,92,92,.10)` | `base` |
| Pressed | Fill `rgba(255,92,92,.18)`, scale 0.97 | `tick` / `quick`; haptic `press.primary` |
| Focused | `line-focus` | instant |
| Disabled | Ring `ink-4`, label `ink-4` | none |
| Loading | 20 px leader sweep in `rating` | crossfade |
| Selected | n/a | n/a |
| Error | Label "Couldn't delete — try again" | none |

Destructive actions that cannot be undone need a confirming dialog (§3.12) whose confirm button is a **solid** destructive variant: fill `rating`, label `#000`.

### 3.2 Icon buttons

**IB1 Round ring** (the "+", "i", bookmark and share buttons beside the primary CTA): 44 px circle, 1.5 px ring `hair-strong`, glyph 20 px ink.

| State | Visual | Motion |
|---|---|---|
| Default | Ring `rgba(245,245,241,.40)`, no fill | none |
| Hover | Ring ink, fill `rgba(245,245,241,.10)` | `base` |
| Pressed | Scale 0.94, fill `rgba(245,245,241,.18)` | `tick` / `quick` |
| Focused | `line-focus` (circle) | instant |
| Disabled | Ring and glyph `ink-4` | none |
| Loading | Glyph replaced by a 20 px leader sweep | crossfade `quick` |
| Selected (in library, bookmarked, favourite) | Glyph switches to its Fill weight in accent, ring accent at 60 % | glyph swap: old scales to 0.6 and fades 90 ms, new scales from 1.2 to 1.0 over `quick` `cine-out` (a projector "flash"), no bounce |
| Error | Ring `rating` for 2 s | `quick` |

**IB2 Bare** (top bars, reader chrome, list trailing actions): 44 px hit area, 24 px glyph, no ring, no fill.

| State | Visual | Motion |
|---|---|---|
| Default | Glyph ink (chrome) or ink-2 (in lists) | none |
| Hover | Glyph ink plus a 36 px circle fill `rgba(245,245,241,.08)` | `base` |
| Pressed | Circle fill `rgba(245,245,241,.16)`, glyph scale 0.92 | `tick` / `quick` |
| Focused | `line-focus` as a 40 px circle | instant |
| Disabled | Glyph `ink-4` | none |
| Loading | 20 px leader sweep | crossfade |
| Selected | Fill-weight glyph in accent | swap as IB1 |
| Error | Glyph `rating` for 2 s | none |

**IB3 Play disc** (listen mode, Wrapped, auto-scroll): 64 px circle filled `ink`, glyph `#000` 28 px (Play / Pause Fill). Pressed scale 0.95; hover bloom `0 0 40px rgba(245,245,241,.25)`; loading swaps to a black leader sweep; disabled fill `n-300`, glyph `ink-4`; error shows a Warning glyph in `#000` for 2 s.

### 3.3 Inputs

**IN1 Text field** (username, display name, collection name, server URL, invite code)

Geometry: 52 px tall, fill `n-200`, `r-frame` top corners only, no border; a 2 px bottom line `hair-strong`; label above in `eyebrow` ink-3, 8 px gap; helper below in `caption` ink-3.

| State | Visual | Motion |
|---|---|---|
| Default | As above; placeholder ink-3 | none |
| Hover | Bottom line ink-3 | `base` |
| Pressed | n/a (focuses) | n/a |
| Focused | Bottom line becomes 2 px accent, drawn from the left; caret `house` or accent, 2 px wide, blinking 530 ms on / 530 ms off; label turns ink | underline `base` `cine-out` |
| Disabled | Fill `rgba(27,27,27,.5)`, text `ink-4`, label `ink-4` | none |
| Loading (async validation, such as the server URL check) | Trailing 16 px leader sweep inside the field; helper reads "Checking…" | none |
| Selected (text selection) | Selection colour: accent at 32 % | n/a |
| Error | Bottom line `rating`; helper line replaced by the error message in `rating` with a Warning glyph 16 px; label keeps ink | line colour `quick`; haptic `error` on submit |
| Success (URL verified) | Trailing Check glyph `positive` | glyph fade `quick` |

**IN2 Password field**: IN1 plus a trailing IB2 Eye / EyeSlash toggle (not in the tab order; `aria-pressed`). Caps-lock on shows a caption "Caps Lock is on" in `caution`.

**IN3 Text area** (AI prompt, bookmark note, collection description): IN1 with auto-growing height from 3 to 8 lines, character counter bottom-right in `timecode` ink-3 ("212 / 600"), turning `caution` at 90 % and `rating` at 100 %.

**IN4 Stepper** (novel text size, line spacing, line width, sleep custom minutes): a row of IB1 "−" · value in `timecode` 17 px ink, 64 px wide, tabular · IB1 "+". Holding a button repeats every 120 ms after a 400 ms delay. At a limit the corresponding button goes Disabled. Each step: haptic `page.turn` (selection).

### 3.4 Search field

**SF1 Global search**: 56 px tall (desktop 64), fill `void`, no box. A leading MagnifyingGlass 24 px in ink-3, the query in `heading-card` 20 px ink (desktop 24 px), a 1 px `hair` line under the whole field that becomes a 2 px accent line when focused. Trailing: an IB2 X "Clear" when the field has text, and on desktop a key cap showing `/`.

| State | Visual | Motion |
|---|---|---|
| Default (empty) | Placeholder "Search every source and your library" ink-3 | none |
| Hover | Line ink-3 | `base` |
| Focused | Line 2 px accent drawn from the left; caret a tungsten **block** caret (the typing-reveal caret, 0.5 em × 1 em) blinking at 1 Hz | `base` |
| Typing | Results update 220 ms after the last keystroke; the leading glyph becomes a 20 px leader sweep while a request is in flight | glyph crossfade `quick` |
| Disabled (offline with no library cache) | Placeholder "Search needs a connection" ink-4 | none |
| Error | Line `rating`; the results area shows the error state | `quick` |

**SF2 Inline filter** (inside Library, Source catalogue, Downloads, Settings search): 44 px, fill `n-200`, `r-frame`, leading MagnifyingGlass 20 px, placeholder `body` ink-3. Same states as IN1.

### 3.5 Chips and filters

Chips are **text toggles**, never pills. A filter row is a single line of `eyebrow` labels separated by a `·` in ink-4, scrolling horizontally on phones with a 24 px right fade.

| State | Visual | Motion |
|---|---|---|
| Default | Label ink-3 | none |
| Hover | Label ink-2 | `base` |
| Pressed | Label ink, scale 0.97 | `tick` |
| Focused | `line-focus` around the label box (4 px padding) | instant |
| Disabled | Label `ink-4` | none |
| Loading (a count still computing) | Label followed by a 12 px leader sweep | none |
| Selected | Label ink with a 5 px accent dot 6 px before it; count in `timecode` ink-3 after it ("ONGOING 42") | dot scales 0 → 1 over `quick`; the list below **cuts** (0 ms) and its items focus-pull in |
| Error | n/a | n/a |

**Removable filter tag** (active filters summary, AI prompt suggestions): `label-sm` ink on `n-200`, `r-hair`, 28 px tall, trailing X 14 px. Removing it collapses its width over `quick` `cine-in`.

**Genre token** (series detail, world cards): plain `caption` ink-2 text separated by `/` in `key.accent`. Hover ink with underline; pressed navigates to the catalogue filtered by that genre.

### 3.6 Posters

The poster is the atom of the skin. 2:3, `r-frame` 6 px, a 1 px inner `hair` edge (inset box-shadow, so it never shifts layout), no caption on discovery surfaces.

| State | Visual | Motion |
|---|---|---|
| Default | Cover image, `key.tint` of that series behind it while loading | none |
| Loading | `n-100` frame (or the series' `key.tint` when the payload has `ambient`) with the title set as a **title card**: `heading-card` 13 px ink-3 bottom-left, 10 px inset, 3 lines max; opacity flicker .6 ↔ 1.0 every 1400 ms `drift`, phase offset 60 ms per index | flicker; on image load the **focus pull**: blur 16 → 0, brightness .6 → 1, scale 1.04 → 1.00 over 520 ms `cine-out` |
| Hover (desktop) | Scale 1.06 with origin at the poster centre (first visible: left centre; last visible: right centre), brightness 1.08, bloom `0 0 56px -12px key.glow`, inner edge `hair-strong`; siblings dim to `brightness(.55) saturate(.8)` | `base` 280 ms `cine-out`; siblings `base`; after a 450 ms dwell the frame's key light moves to this series (`dissolve`); after 700 ms the preview slate opens (§3.8) |
| Pressed | Scale 0.97 | `tick` / `quick`; no haptic |
| Focused (keyboard) | Same as hover plus `line-focus` with 8 px radius | rail slides under fixed-left focus (§3.9) |
| Disabled | n/a (unavailable items are not rendered) | n/a |
| Selected (multi-select mode) | Dim to brightness .45, a 28 px ink circle top-right with a black Check, a 2 px ink inner frame | circle scales 0 → 1 over `quick` `cine-out` |
| Error (cover failed) | `n-100` frame, the title card at full ink-2 opacity, no broken-image glyph | none |
| Long press (touch) | At 450 ms: scale 1.03, bloom, then opens the Quick Look sheet (§3.10) with a match cut from the poster rect | haptic `poster.longpress` |

**Poster badges** (top-left, 8 px inset, stacked 4 px apart, max two): see §3.19.

**Poster variants**

| Variant | Where | Difference |
|---|---|---|
| Wall | Home discovery rails, source catalogue, search results, world recommendations | No caption |
| Captioned | Library shelf, collections, history, bookmarks | Caption below: `heading-card` 13 px 1 line + `timecode` ink-3 ("CH 41 / 120 · 3 NEW"); a 3 px accent progress bar flush along the poster's bottom edge, width = `position / total` |
| Ranked | Top-10 rail | `numeral-xl` outline numeral (fill `#000`, stroke 2 px `rgba(245,245,241,.48)`), 1.1× poster height, sitting half behind the poster's left edge |
| Continue | Continue rail | 16:9 card, cover cropped at 50 % 20 %; see §3.7 |
| Book | Novel series in Novels mode (library, sources, search, Home) | The same 2:3 poster read as a jacket: a 3 px spine highlight on the left edge (`rgba(245,245,241,.10)` → transparent over 3 px), a 1 px darker fore-edge on the right, and the caption's timecode in chapters and percent ("CH 212 · 42 %") |
| World info | Recommendations with empty `available` | Poster at 72 % brightness, a 1 px `hair-strong` dashed frame, and a small "NOT ON YOUR SOURCES" `micro` label bottom-left |

### 3.7 Cards

Cards in Projection have **no card background**. A "card" is art plus text sitting on the black.

**C1 Continue card** (16:9): cover cropped at 50 % 20 %, `r-frame`; bottom scrim `scrim-poster-caption`; inside the scrim, bottom-left, 12 px inset: title `heading-card` ink, then `timecode` "CH 142 · 64 %" ink-2; a 4 px accent bar flush with the bottom edge. A 44 px IB3-style mini play disc (36 px, ink fill) sits bottom-right and appears on hover or focus. States follow the poster (hover scale 1.04, not 1.06, because cards are wider). When the chapter is finished and the next exists, the timecode reads "NEXT · CH 143". Loading: `n-100` 16:9 frame with the title card.

**C2 Info card** (Settings summaries, admin health, storage): no fill; a 1 px `hair` rule above; eyebrow label, a `display-page`-size value in Mona Sans ("4.1 GB"), a caption. Hover: nothing (not interactive) unless it links, in which case a trailing CaretRight appears and the value turns accent.

**C3 Source hub tile** (16:9): the source's newest cover filling the frame with `blur-fill`, `key.tint` wash at 40 %, the source name in `display-page` ink, bottom-left, count in `timecode`. States as C1. An 18+ source carries the 18+ badge top-left.

**C4 Collection tile** (16:9): three member covers fanned: back two rotated −4° and +4° (a flat 2D rotation, no 3D), offset 18 px, at brightness .5, the front one upright; name in `heading-section` 20 px bottom-left; `timecode` "12 SERIES". A shared collection adds the Circle glyph and the owners' avatars (20 px) in the top-right. States as C1. Smart collections show a Sparkle glyph and "AUTO" `micro` label.

**C5 World recommendation card** (For you, Ask results): a Wall poster plus, below it, `heading-card` 13 px title, `caption` ink-3 `FORMAT · RATING 8.4`, and the `why` line in `caption` ink-2 italic (Instrument Serif at 14 px). Available state: primary tap opens the series; a source picker menu appears when several sources carry it. Info state: the World info poster variant; tap opens an info sheet with official platforms and a "Search my sources" secondary button.

**C6 Activity card** (Circle): a 40 px avatar (profile colourway), a sentence "**Mira** finished **Omniscient Reader** Ch. 212", `timecode` "2H AGO", then a 16:9 crop of that chapter's first page at 64 % brightness, `r-frame`. Reactions row below (§5.3). Hover: art brightness to 100 %, key light moves to that series.

**C7 Stat tile** (Stats): no fill; Mona Sans `numeral-xl` value (phone 64 px), `eyebrow` label, a 3 × 32 px accent rule between them. Loading: the numeral counts up from 0 over 900 ms `cine-out` once data lands (reduced motion: final value at once).

**C8 Up Next card**: see the reader (§4.12).

### 3.8 Preview slate (desktop hover and keyboard Space)

A portal overlay, never a layout push. Width 2.1× the poster width (min 320 px), anchored to the poster's rect and clamped inside the gutter. Top half: 2:1 frame of the cover with `blur-slate` behind a sharp centre crop, grain and vignette, and the title per-letter revealed in `heading-section` `key.ink`. Bottom half on `n-150`: eyebrow, 2-line hook `body` ink-2, then B1 `sm` "Read" / "Continue Ch. N", IB1 "+" (library), IB1 "i" (details), and, when the social feature has activity, 20 px avatars of Circle members who read it.

| State | Visual | Motion |
|---|---|---|
| Opening | Grows from the poster rect | 320 ms `cine-out`; title reveal starts 120 ms in |
| Open | Bloom `0 0 64px -8px key.glow` | Ken Burns off (too small) |
| Leaving | 120 ms grace, then collapses to the poster rect | 200 ms `cine-in` |
| Keyboard | Space opens, Esc closes, Tab moves inside, Enter on the art opens detail | as above |
| Loading (hook not yet known) | Hook area shows two `n-200` bars 12 px tall flickering | flicker |
| Error | Hook area reads "Details unavailable" ink-3; buttons still work | none |

### 3.9 Rails

**Geometry**

| Breakpoint | Posters visible | Poster width | Gap | Rail stack (spacing between rails) |
|---|---|---|---|---|
| < 768 (phone) | 3.3 | `(100vw − 16 − 3 × 8) / 3.3` ≈ 106 px at 375 | 8 | 32 |
| 768–1023 | 5.3 | computed the same way | 8 | 36 |
| 1024–1439 | 6.25 | `(100vw − 2 × gutter − 5 × 12) / 6.25` | 12 | 44 |
| 1440–1919 | 7.25 | `/ 7.25` | 12 | 44 |
| ≥ 1920 | 8.25 | `/ 8.25` | 14 | 52 |

Rails start at the gutter and bleed off the right edge. The header sits 12 px above the posters.

**Rail header**: `heading-section` ink with the per-letter reveal, once per session per rail key, when 60 % in view. A 1 px × 40 % width `key.wash` underlight fades in beneath it for rails tied to one series ("BECAUSE YOU READ SOLO LEVELING"). Trailing on desktop: a text button "See all" that appears on header hover or rail focus; on phones a CaretRight 20 px ink-3 after the title makes the whole header tappable. Header hover: the letters wipe from ink to accent left to right (color 240 ms, 12 ms delay per letter), reversing on leave with no delay.

**States**

| State | Visual | Motion |
|---|---|---|
| Loading | Header renders immediately (static strings); posters are loading frames | flicker |
| Content | Posters | first-paint stagger 40 ms × 6 |
| Empty | The rail is omitted entirely (no "nothing here" rails on Home). On pages where the rail is the only content, the screen's empty state shows instead. | none |
| Error | The rail collapses to a single line in its place: `caption` ink-3 "Couldn't load this row." + B3 "Retry" | none |
| Offline | Rails that need the network are omitted; the downloaded rail moves to the top | none |

**Desktop pointer**: paddles are 48 px wide full-height zones over `scrim-rail-edge`, a 28 px CaretLeft / CaretRight in ink, visible on rail hover; they page by `visible − 1` posters over 560 ms `cine-in-out`, sound `ui.page`.

**Keyboard**: fixed-left focus. Focus stays in the first fully visible slot and the rail slides under it (`translateX` over 360 ms `cine-out`). ← / → move within a rail, ↑ / ↓ move between rails and scroll the focused rail to 30 % of the viewport height, Home / End jump to the ends, Enter opens detail (match cut), Space opens the preview slate, Esc closes it. One Tab stop per rail (roving `tabindex`).

**Touch**: free horizontal scroll with snap to poster starts (`scroll-snap-type: x mandatory` on web; `PageScrollPhysics`-style snapping with the `rig` spring on Flutter). Press and long-press as in §3.6.

### 3.10 Sheets

Sheets rise from black. There is no backdrop blur and no bounce.

**Geometry**: `n-150`, `r-sheet` 12 px top corners, top 24 px washed from `key.tint` to transparent, a 36 × 4 px drag handle `ink-4` centred 8 px from the top, padding `s-5` (phone) / `s-6` (desktop). Barrier `scrim-modal`. On desktop ≥ 1024 px, sheets become **side panels**: 440 px wide, full height, docked right, no corner radius on the right edge, entering from the right edge by 24 px + fade.

**Detents** (phone): `peek` 40 % (reader settings, reaction picker), `half` 60 % (Quick Look, filters), `full` 94 % (voice picker, contents, filters with many fields). Drag between detents; release settles on the `rig` spring; haptic `sheet.detent` per snap.

| State | Visual | Motion |
|---|---|---|
| Opening | Barrier 0 → .72; sheet rises 24 px and fades in | barrier 240 ms linear; sheet 360 ms `cine-out` |
| Open | As geometry | none |
| Dragging | Follows the finger 1:1; the barrier alpha tracks the sheet position | none |
| Dismissing (drag past 30 % of its height or a fling > 900 px/s downward, tap barrier, Esc, system back) | Sheet falls 24 px + fades | 240 ms `cine-in`; haptic `sheet.dismiss` on drag dismissal only; sound `ui.back` |
| Loading | Content area shows skeleton rows (§3.17) | flicker |
| Error | Inline error state (§3.20) inside the sheet | none |
| Nested sheet | The lower sheet dims to brightness .6; the new sheet rises over it; back closes only the top one | as opening |

**Quick Look sheet** (poster long-press on touch, `half` detent): the poster match-cuts into a 2:1 header with `blur-slate`, title reveal, eyebrow, hook, then B1 "Read" / "Continue", IB1 "+", IB1 "Download", IB1 "Share to Circle", IB1 "i".

### 3.11 Dialogs

Centered, max width 480 px (phone: gutter-inset, bottom-aligned 24 px above the safe area, full width minus 2 × 16 px), `n-150`, `r-sheet` all corners, padding 24, barrier `scrim-modal`. Title in `editorial-md` (Instrument Serif) ink; body `body` ink-2; buttons right-aligned on desktop (B2 cancel, then B1 or solid destructive), stacked full-width on phones with the confirming action on top.

| State | Visual | Motion |
|---|---|---|
| Opening | Fade up 16 px | 320 ms `cine-out`; barrier 240 ms |
| Open | Focus moves to the least destructive action | none |
| Closing | Fade down 12 px | 220 ms `cine-in` |
| Loading (confirm in progress) | Confirm button in Loading; Esc and barrier disabled | none |
| Error | An inline `rating` line above the buttons | `quick` |

Dialog inventory: Delete profile, Sign out, Enable mature content (the 18+ gate, §3.23), Reset reader settings, Sign out this device, Sign out everywhere, Delete member, Restore backup, Apply staged restore, Cancel all downloads, Remove downloads, Remove saved audio, Delete collection, Remove series from collection, Install update (Android APK), Leave shared collection, Stop sharing activity.

### 3.12 Toasts ("subtitles")

Toasts read like film subtitles: bottom-left on desktop (gutter inset, 32 px above the bottom), bottom-centre on phones (above the bottom nav or reader bottom chrome, 12 px gap). A `#000` band at 88 % opacity, `r-hair`, padding 10 × 14, max width 520 px; the line in `body-strong` ink with `text-shadow: 0 0 4px #000`; an optional action as B3 in accent ("Undo", "View"). Built on `sonner` 2.0.8 (web) with a custom renderer and on a single `OverlayEntry` queue (Flutter).

| State | Visual | Motion |
|---|---|---|
| Enter | Fade in, 6 px rise | `quick` 160 ms `cine-out` |
| Hold | 3200 ms (with an action: 6000 ms; skin switch undo: 10 000 ms with a 2 px accent countdown line along the bottom edge) | linear countdown |
| Exit | Fade out | 240 ms `cine-in` |
| Swipe | Horizontal swipe dismisses on the `slate` spring | follows finger |
| Stack | New toasts replace the current one (subtitles never stack) | crossfade `quick` |
| Error variant | A 2 px `rating` bar on the left edge of the band | as enter |
| Success variant | A 2 px `positive` bar on the left edge | as enter |

### 3.13 Tabs ("slates")

Slate tabs are uppercase `eyebrow` labels with a 2 px accent bar 8 px under the active one. Never pills, never boxed.

| State | Visual | Motion |
|---|---|---|
| Default | Label ink-3 | none |
| Hover | Label ink-2 | `base` |
| Pressed | Label ink | `tick` |
| Focused | `line-focus` around the label | instant |
| Disabled | Label `ink-4` | none |
| Selected | Label ink; 2 px accent bar the width of the label | the bar **cuts** to the new tab (0 ms) and the content below dips to black: out 120 ms, hold 40 ms, in 240 ms |
| Loading | Selected tab label followed by a 12 px leader sweep | none |
| With count | `timecode` ink-3 after the label ("UPDATES 12") | none |

Swipe between tabs on phones is supported where tabs hold whole lists (Library, Downloads, Updates): horizontal swipe changes tab with a 1:1 follow and settles on `rig`.

**Content-mode switch** ("MANGA · NOVELS"): a two-slate tab pair in the top bar or page header. Switching dips the whole page to black (dip to black), then every list refetches with its loading state. Haptic `nav.tab`. Rendered only when the server reports `novels_enabled`.

### 3.14 Top bars

**TB1 Floating top bar (over art)**: height 64 px + safe area (desktop 72), no fill, `scrim-top` behind it. Left: back (IB2 ArrowLeft) on pushed routes, or the MM mark 28 px on tab roots. Centre: empty (the art is the title). Right: IB2 actions. After 80 px of scroll (web) or when the hero is 75 % scrolled away (Flutter), a `#000` fill fades in behind it over 280 ms and the screen title appears centred in `heading-card` ink (fading in 200 ms). Scrolling down 24 px on phones hides the bar (slides up 72 px, 220 ms `cine-in`); scrolling up 12 px shows it (280 ms `cine-out`).

**TB2 Page top bar (no art)**: a `display-page` title in the page, left-aligned at the gutter, 32 px below the safe area; there is no bar at all until the title scrolls out, then TB1's solid state appears with the title centred.

**TB3 Desktop top strip**: 72 px, transparent over art with `scrim-top`; left: content-mode slates; right: search field collapsed to an IB2 MagnifyingGlass that expands to a 320 px SF2 on click or `/` (width 200 ms `cine-out`), the Updates IB2 Bell with a badge, the streak flame (§5.2) when a streak ≥ 2 days, and the profile avatar (32 px) opening the account menu.

All top-bar states: icon buttons follow IB2; the bar itself has no hover state; when offline, a 1 px `caution` line runs along the bar's bottom edge and a WifiSlash glyph appears beside the right-side actions.

### 3.15 Bottom navigation (phone, mobile web)

No container. Five destinations over `scrim-bottom`, 56 px + safe area, laid out edge to edge in equal columns.

| Destination | Glyph (Bold / Fill) | Route |
|---|---|---|
| Home | House | `/home` |
| Sources | Compass | `/sources` |
| Search | MagnifyingGlass | `/search` |
| Library | Books | `/library` (badge: downloads in progress or failed) |
| You | UserCircle, replaced by the profile's 24 px avatar | `/you` |

| State | Visual | Motion |
|---|---|---|
| Default | Bold glyph 24 px ink-3; no label | none |
| Pressed | Glyph scale 0.92 | `tick` / `quick` |
| Focused | `line-focus` circle 40 px | instant |
| Selected | Fill glyph ink; `micro` label under it in ink; a 4 px accent dot 4 px under the label | label fades and dot scales in `quick`; the screen **dips to black** (out 120 ms, hold 40 ms, in 240 ms); haptic `nav.tab` |
| Re-tap selected | Scrolls to top over 480 ms `cine-in-out`; on Home also resets the hero to the first spotlight | none |
| Badge | A 16 px `house` disc with `micro` `#000` count ("9+" above 9) at the glyph's top-right | scales in `quick` |
| Disabled | n/a | n/a |
| Hidden | On every pushed route and in readers | slides down 72 px, 220 ms `cine-in` |

Scroll down 24 px hides the nav (slide down); scroll up 12 px reveals it. At text scale > 1.2 labels disappear and glyphs are 28 px.

### 3.16 Desktop sidebar ("house-lights rail")

A 72 px rail on the left edge, `void`, **no divider**, over which nothing else is drawn. It stays quiet (ink-3 glyphs) so the art owns the width.

- Top: the MM mark 32 px (the brand's stacked M column), 20 px from the top.
- Primary group: Home, Library, Sources, Search, Updates (badge), Downloads (badge).
- Secondary group after 24 px: For you (Sparkle), Circle (`mm-circle`), Stats (`mm-flame` when a streak is live, ChartBar otherwise), Collections (Stack), History (ClockCounterClockwise), Bookmarks (BookmarkSimple), Dialogue search (`mm-xray`, manga mode only).
- Footer: profile avatar 32 px (switch profile), Settings (Gear), Status (Pulse, admin only).

| State | Visual | Motion |
|---|---|---|
| Collapsed default | 24 px Bold glyphs ink-3, 52 px row pitch | none |
| Hover on a glyph (dwell 300 ms) or keyboard focus inside the rail | The rail **expands** to 264 px as an overlay (content does not reflow); the overlay is `#000` at 96 % with a `scrim-rail-edge`-style 48 px fade on its right edge; labels in `body-strong` ink-2 appear beside the glyphs | width 280 ms `cine-out`; labels fade in with a 20 ms stagger |
| Pinned (`mod+b` or the pin button at the bottom of the expanded rail) | Expanded and pushing content (content reflows once, 280 ms) | as above |
| Row hover | Label ink; glyph ink | `base` |
| Row pressed | Label ink at 80 % | `tick` |
| Row focused | `line-focus` around the row | instant |
| Row selected | Fill glyph ink; a 4 × 20 px accent bar on the rail's left edge; label ink | bar slides between rows over 280 ms `cine-in-out` |
| Row disabled | Hidden instead (Dialogue search in novels mode is not rendered) | none |
| Badges | 16 px `house` disc as in the bottom nav | none |
| Collapsing | 180 ms `cine-in` after the pointer leaves for 200 ms | none |

In readers the rail hides entirely; in Settings it stays.

### 3.17 Lists

**L1 List row** (history, bookmarks, updates, downloads, settings, members, sources): min height 64 px (settings rows 56 px), no fill, padding 12 × gutter, separators as a `hair` line inset to the text start.

| State | Visual | Motion |
|---|---|---|
| Default | Leading 40 × 60 px poster thumb (`r-hair` 2 px) or 40 px icon disc; primary `body-strong` ink; secondary `caption` ink-3; trailing `timecode` or IB2 | none |
| Hover (desktop) | Fill `n-300` at 60 %; the row's series takes the key light after 450 ms | `base` |
| Pressed | Fill `key.wash` | `tick` |
| Focused | `line-focus` inset 2 px | instant |
| Disabled | Primary and secondary `ink-4`; no press | none |
| Loading (row-level action pending, such as removing) | Trailing slot shows a 20 px leader sweep; the row is at 60 % opacity | `quick` |
| Selected (select mode) | Leading checkbox (§3.22) checked; fill `key.wash` | `quick` |
| Error (row action failed) | Secondary line replaced by the error in `rating` for 4 s | `quick` |
| Swipe (phone) | Swipe left reveals one trailing action (Remove / Mark read / Delete) on a `rating` or `n-300` field with its glyph; release past 40 % commits; the `slate` spring settles | follows finger |

**L2 Chapter row** (series detail): 56 px; leading chapter number in `timecode` 15 px ink-2, 64 px wide, tabular; title `body` ink (finished chapters ink-3 at 70 %); trailing: relative date `timecode` ink-3, then the download control (§3.18). An in-progress chapter shows "14 / 27" in `timecode` accent and a 2 px accent line along its left edge. The current chapter (the continue target) has a `key.wash` fill. Hover: fill `n-300` at 60 %; press: `key.wash`; select mode adds the checkbox at the leading edge and the number shifts right by 36 px (200 ms `cine-out`).

**L3 Settings row**: 56 px, label `body` ink, value `body` ink-2 right-aligned with CaretRight, or a trailing toggle; a section header above groups in `eyebrow` ink-3, 32 px top margin.

### 3.18 Download control (series pages, downloads)

A 44 px hit area with a 24 px drawing:

| State | Drawing |
|---|---|
| Not downloaded | DownloadSimple Bold ink-3 |
| Queued | A 24 px ring `hair-strong` with a 6 px ink dot centre, pulsing .6 ↔ 1 (1400 ms `drift`) |
| Downloading | Ring progress: 2 px accent arc clockwise from 12 o'clock, Geist Mono 9 px percentage inside |
| Paused (backgrounded, storage floor) | Ring frozen, Pause glyph 12 px inside in `caution` |
| Downloaded | Check Fill in `positive` inside a 24 px disc `rgba(61,214,140,.14)` |
| Failed | Warning Fill in `rating`; tap retries |
| Stale (saved copy cannot play or the chapter changed) | ArrowClockwise in `caution` |
| Pinned (never evicted) | Downloaded plus a PushPin 10 px accent at the bottom-right |

Transitions between states crossfade over `quick`; Downloaded plays haptic `download.done` and sound `ui.reel-lock` only when the app is in the foreground and the chapter was requested in this session.

### 3.19 Badges

`micro` 10–11 px uppercase, `r-hair` 2 px, 18 px tall, 6 px horizontal padding.

| Badge | Style | Where |
|---|---|---|
| NEW / `3 NEW` | Fill accent, text `#000` | Posters, rows with unread chapters |
| UP | Fill ink, text `#000` | Updated this week |
| 18+ | 1 px `rating` outline, text `rating` | Mature sources and series (only visible to profiles whose gate is open) |
| DOWNLOADED | 1 px `positive` outline, text `positive` | Posters and rows fully downloaded |
| ONGOING / COMPLETED / HIATUS | 1 px `hair-strong` outline, text ink-3 | Detail eyebrow line |
| OFFLINE COPY | 1 px `info` outline, text `info`, with "· 14:02" | Stale browse pages |
| ADMIN | 1 px ink outline, text ink | Account menu, members list |
| TOP 10 | Fill ink, text `#000` | Ranked rail posters on phones where the numeral does not fit |
| AUTO | 1 px accent outline | Smart collections |
| Count badge | 16 px circle, `house` fill, `#000` text | Nav glyphs |

Badges do not animate except the count badge (scale in `quick`).

### 3.20 Progress and loading

| Component | Spec |
|---|---|
| **Bar** | 4 px (lists 3 px, reader micro progress 2 px), square ends, track `n-400` at 60 %, fill accent. Width changes animate 480 ms `cine-out`. Indeterminate: a 30 % wide fill segment sweeping left → right in 1400 ms `cine-in-out`, repeating. |
| **Segmented bar** | Read-all and storage: segments separated by 2 px gaps. Storage uses three segments: other apps `ink-4`, ManhwaManiacs accent, free `n-400`. |
| **Ring** | 2 px stroke, 24 px (download) or 40 px (post-play countdown) diameter, accent arc on a `hair-strong` track. |
| **Leader sweep** | The only spinner shape: a 40 px circle (inline 20 or 24 px), 1 px crosshair and ring at `rgba(245,245,241,.30)`, a conic sweep fill `rgba(245,245,241,.22)` at one revolution per 1000 ms, linear. Shown only for waits over 1 s; shorter waits show nothing. The same sweep with a 5 s period and accent fill is the auto-advance countdown. |
| **Skeletons ("slate")** | Shapes match the final layout: posters as loading frames with title cards, list rows as a 40 × 60 `n-100` thumb plus two `n-200` bars (primary 55 % width × 12 px, secondary 30 % × 10 px), text blocks as `n-200` bars 10 px tall with 8 px gaps. All flicker opacity .6 ↔ 1 over 1400 ms `drift` with a 60 ms left-to-right phase offset. Never a shimmer gradient. |
| **Focus pull** | Every image fades in via rack focus (§3.6). |
| **Pull to refresh** (phone) | Pulling reveals the leader sweep 40 px under the top bar, filling clockwise with the pull distance; at 96 px it locks (haptic `refresh.armed`) and spins at 1 rev / s; release triggers the refresh; completion fades it out 240 ms. Built on `custom_refresh_indicator` 4.0.2 (Flutter) and a 60-line pointer handler (web). |

### 3.21 Sliders and scrubbers

**S1 Slider** (brightness, warmth, volume, auto-scroll speed, soundscape mix): track 2 px `n-400`, fill 2 px accent, thumb 14 px ink circle; on touch or drag the track grows to 4 px and the thumb to 20 px (`quick`). Value label appears above the thumb while dragging in `timecode` inside a `#000` `r-hair` box. Step haptic `scrub.step` every 10 % (or every step when there are ≤ 10 steps). Hover (desktop): thumb 16 px. Focused: `line-focus` circle around the thumb; ← → change by one step, Page Up / Page Down by 10 %. Disabled: track `n-300`, thumb `n-500`. Loading: n/a. Error: n/a.

**S2 Reader scrubber**: see the reader (§4.12). It is a full-bleed timeline, not a slider.

**S3 Speed ruler** (narration speed 0.5–3.0×): a horizontal tick ruler, ticks every 0.05 (1 px ink-4, 8 px tall), labelled ticks at 0.5 / 1 / 1.5 / 2 / 2.5 / 3 (`timecode` ink-3, tick 14 px ink-3), the value centred above in Mona Sans 40 px ink with "1.25×" and the words-per-minute equivalent in `caption` ink-3 below. Drag scrolls the ruler under a fixed accent needle; release settles to the nearest 0.05 on `rig`; haptic `scrub.step` per 0.25; touch-and-hold for 600 ms resets to 1.0×.

### 3.22 Toggles, checkboxes, radios, segmented controls

**T1 Toggle** (the one sanctioned pill): track 40 × 22 px, knob 18 px ink.

| State | Visual | Motion |
|---|---|---|
| Off | Track `n-200`, knob ink at left | none |
| On | Track accent, knob `#000` at right, so the knob reads as a hole in the light | knob slides 160 ms `cine-out`, track colour crossfades 160 ms; haptic `toggle.on` / `toggle.off`; sound `ui.toggle-on` / `ui.toggle-off` |
| Hover | Track brightens by 8 % | `base` |
| Pressed | Knob widens to 22 px toward its travel direction | `tick` |
| Focused | `line-focus` around the track | instant |
| Disabled | Track `n-200` at 50 %, knob `n-500` | none |
| Loading (server-backed toggles such as 18+, notify) | Knob replaced by an 18 px leader sweep; the toggle holds its new position optimistically | none |
| Error | Knob slides back; the row's secondary line shows the error in `rating` for 4 s; haptic `error` | 160 ms `cine-in` |


**T2 Checkbox**: 20 px square, `r-hair`, 1.5 px `hair-strong` ring; checked: fill ink, Check Bold 14 px `#000`, drawn by a 160 ms stroke-dash reveal; indeterminate: a 10 × 2 px `#000` bar on ink; hover ring ink-2; focused `line-focus`; disabled ring `ink-4`; error ring `rating`.

**T3 Radio**: 20 px circle, 1.5 px ring; selected: 10 px ink inner dot scaling in over `quick`. Same states as T2.

**T4 Segmented control** (reading direction, fit mode, page background, face): a row of `label-sm` options separated by 1 px `hair` dividers inside a 40 px tall `n-200` `r-frame` box; the selected option gets an ink fill with `#000` label; selection **cuts** (0 ms). Hover ink-2 label; focus ring on the option; disabled options `ink-4`.

### 3.23 The 18+ gate

The gate is an absence, never a lock: gated content is never rendered, blurred or counted for a profile whose gate is closed. The gate components are:

1. **Enable dialog** ("rating card" dialog), opened from Profile edit or Settings → Content: the dialog shows a 3 × 56 px `rating` bar left of the title "18+ content" in `display-page` Mona Sans; body "This profile will see mature sources and series. Other profiles are not affected." A checkbox "I am 18 or older" must be checked before the solid confirm button "Enable 18+" becomes active. Confirm plays haptic `gate.unlock` and sound `ui.rating`. Cancel is the default focus.
2. **Profile form toggle** "18+ content" with the same confirm dialog when turning on; turning off needs no confirm.
3. **Rating card** (informational, never blocking): when a mature series' detail opens and when its reader starts, a card appears top-left under the chrome: 3 × 44 px `rating` bar, "18+" in `display-page`, descriptors from tags in `caption` ink-2 ("Violence · Sexual content"). Fade in 400 ms, hold 4000 ms, fade out 600 ms. Once per series per session.
4. **Badges**: 18+ outline badge on mature sources and series (§3.19).
5. **Source list filter** "18+" (a chip, only rendered when the profile's gate is open).
6. **Series override** in the detail overflow menu: "Treat as 18+" / "Treat as not 18+" / "Use source rating" (radio group in a sheet).

States: loading (the enable button shows the leader sweep while `PUT /settings` runs), error ("Couldn't change this — try again", `rating` line in the dialog), disabled (the Enable button until the checkbox is checked).

### 3.24 Menus and context menus

**M1 Menu** (sort menus, overflow "⋯", account menu, select-like fields): `n-150`, `r-sheet`, min width 220 px, 6 px vertical padding; items 44 px, `body` ink, leading 20 px glyph ink-2, trailing check (selected) in accent or a shortcut hint in `timecode` ink-3; separators `hair`. Opens from its trigger with a 6 px drop + fade 200 ms `cine-out`; closes 140 ms `cine-in`. Item states: hover `n-300`; pressed `key.wash`; focused (arrow keys) `n-300` plus a 2 px accent bar on the left edge; disabled `ink-4`; destructive item label `rating`. Built on `@base-ui/react` 1.8.0 `Menu` (web) and a custom `PopupRoute` (Flutter). On phones, menus with more than 6 items become a `half` sheet.

**M2 Context menu** (right-click on desktop, long-press on touch lists): the M1 visual, preceded on posters by a mini preview (the poster at 120 px wide, title, timecode). Items for a series: Read / Continue, Details, Add to library / Remove, Favourite, Add to collection, Download next 10, Recommend to…, Previously on…, Share card, Treat as 18+ (gate open only). Right-click opens at the pointer; keyboard `Shift+F10` or the context-menu key opens at the focused item. Long-press on phones uses the Quick Look sheet instead (posters) or M2 as a sheet (rows).

**M3 Tooltip** (desktop only): `#000` band, `r-hair`, `caption` ink, 6 × 8 padding, after 500 ms hover, 120 ms fade; shows the action plus its shortcut ("Bookmark · B").

### 3.25 Empty, error and offline states ("title cards")

Every state is set as a film title card: centred in the available area, no icon disc, no illustration.

| State | Composition | Actions |
|---|---|---|
| Empty | `editorial-md` Instrument Serif line in ink (typing reveal, 50 ms / char, ≤ 60 chars), `body` ink-2 sentence below, 24 px gap | One B1 or B2 |
| Error | Eyebrow "SOMETHING BROKE" in `rating`, `editorial-md` ink line, `body` ink-2 detail, `timecode` ink-3 reference id | B1 "Try again", B3 "Go home" |
| Offline | Eyebrow "NO SIGNAL" in `caution`, `editorial-md` line "You're offline.", body "Chapters you downloaded still open with no connection." | B1 "Open downloads", B3 "Try again" (auto-retries on the `online` event with a 3 s cooldown) |
| Rate limited | Eyebrow "SLOW DOWN" in `caution`, body "The source asked us to wait. Retrying in 12 s." with a live countdown in `timecode` | none; retries itself |
| Stale | An `OFFLINE COPY · 14:02` badge above the content; content renders | none |
| AI unavailable | See §5.1 (never red) | varies |

Entrance: the title card fades in 480 ms `cine-out`; the typing reveal starts 200 ms in.

### 3.26 Avatars

Profile avatars are **colourways**, not illustrations: a 1:1 square with `r-frame` 6 px (the picker) or a circle (chrome), filled with a radial gradient from the mood's `key.glow` (centre 30 % 25 %) to `#000`, a Mona Sans `wght 900 wdth 75` initial in the mood's `key.accent`, and 2 % grain. Twelve avatar keys map to twelve colourways (seed hues): `violet` 270°, `cyan` 190°, `rose` 345°, `amber` 38°, `emerald` 150°, `ember` 12°, `blade` 210° desaturated, `phantom` 0° grey, `arcane` 290°, `tide` 200°, `moss` 100°, `dusk` 25° desaturated. Unknown keys fall back to `amber`. Sizes: 24 (nav), 32 (chrome), 40 (activity), 96 (phone picker), 144 (desktop picker).

States: hover (desktop picker) scale 1.06 + 3 px ink ring; pressed scale 0.97; focused `line-focus`; selected (active profile in lists) 2 px accent ring; disabled (profile limit reached, "Add" tile) `ink-4` ring dashed.

### 3.27 Key caps and shortcut chips

`Kbd`: `n-300` fill, `r-hair`, `timecode` 12 px ink-2, min width 22 px, 22 px tall, 1 px `hair` bottom edge. On macOS the glyphs ⌘ ⌥ ⇧ render; elsewhere "Ctrl", "Alt", "Shift".

### 3.28 Command palette (desktop web, `mod+k`)

A top-anchored overlay at 12 vh, 680 px wide, max 70 vh tall, `n-150`, `r-sheet`, barrier `scrim-modal`. The input is SF1 at 56 px with a `Esc` key cap. Results are grouped under `eyebrow` ink-3 headers in rank order: Library, Sources, Actions, Go to, Circle, Settings. Rows are 48 px: a 32 px leading visual (poster thumb, source mark or glyph), title with matched characters in accent, subtitle ink-3, and a CornerDownLeft glyph on the active row. The active row has a `n-300` fill and the key light moves to its series (so the palette itself is lit by the result under focus). Actions include "Switch skin to Glass", "Switch profile", "Toggle content mode", "Open settings", "Sign out", "Start auto-scroll", "Open Wrapped". Opens with a 12 px drop + fade 240 ms `cine-out`; closes 160 ms `cine-in`. Keys: ↑ ↓ (wrap), Home / End, Enter, Esc, `mod+k` toggles.

### 3.29 Lightbox (full art view)

Opened by long-pressing a hero or detail backdrop, double-clicking a detail cover on desktop, or `v` on a focused poster: the cover leaves its frame by a match cut and fills the screen at `contain` on `scrim-lightbox`, bloom E4 behind it, no chrome except an IB2 X top-right and a `timecode` caption with the title bottom-left. Pinch zoom up to 4×, pan, double-tap toggles 1× / 2.5×. Drag down to dismiss (follows the finger, the barrier fades with distance; release past 120 px or 800 px/s dismisses on `dolly`; otherwise returns on `rig`). Esc closes on web. Haptic `poster.longpress` on open.

### 3.30 Banners

**New-chapters banner** (desktop and phone, when unread notifications exceed what the user has seen this session): a subtitle-style band anchored bottom-centre, max 680 px: "**4 new chapters** across 3 series." + B3 "View" in accent + IB2 X. Hidden on Updates and in readers. Enter/exit as toasts; persists until dismissed or viewed.

**App update banner** (Android APK and web service worker): a subtitle band "A new version is ready." + B1 `sm` "Restart" (web) / "Install" (Android). iOS shows "A new build is on SideStore" with B3 "How to update".

**First-run banner** (profiles with nothing followed): on Home only, replaced by the onboarding flow (§4.7); no banner elsewhere.

---

## 4. Per-screen specs

### 4.0 Shells, routes and platform rules

#### 4.0.1 Frames

| Frame | Where | Chrome |
|---|---|---|
| **Bare** | Setup, splash, login, register, root error, offline fallback | None. Black stage, wordmark top-left at the gutter. |
| **Takeover** | Profile picker, profile form, onboarding, Wrapped, skin-switch outgoing | None except a close or back IB2. |
| **App, desktop (≥ 1024 px)** | Every other screen | House-lights rail (§3.16) + TB3 top strip. Content spans from x = 72 to the right edge. |
| **App, tablet (768–1023 px)** | Every other screen | Rail stays 72 px; top strip collapses the search field to an icon. |
| **App, phone (< 768 px, iOS, Android, mobile web)** | Every other screen | TB1 or TB2 + bottom nav (§3.15) on tab roots; TB1 back only on pushed routes. |
| **Reader** | Manga reader, read-all, novel reader, listen player | Reader chrome only (§4.14, §4.16). Rail and nav hidden. |

Mobile web mirrors the phone app exactly: the same frames, bottom nav, sheets as bottom sheets, and gestures where the browser allows them.

#### 4.0.2 Route map (the `contract.json` paths the Cinematic router registers)

| Screen id | Path | Tab or parent |
|---|---|---|
| `setup` | `/setup` (mobile only) | none |
| `splash` | `/splash` (mobile only; web plays it over the first route) | none |
| `login` | `/login` | none |
| `register` | `/register` | none |
| `profiles` | `/profiles` | none |
| `profileNew` | `/profiles/new` | profiles |
| `profileEdit` | `/profiles/:id/edit` | profiles |
| `profilesManage` | `/profiles/manage` | you |
| `onboarding` | `/welcome` | none |
| `home` | `/home` (and `/` redirects here) | Home |
| `forYou` | `/for-you` | Home |
| `recap` | `/recap/:sourceId/:seriesKey` (`?chapter=`) | pushed |
| `search` | `/search` (`?q=`) | Search |
| `sources` | `/sources` | Sources |
| `source` | `/sources/:sourceId` (`?genre=&mode=`) | Sources |
| `series` | `/series/:sourceId/:seriesKey` | pushed from any tab |
| `libraryItem` | `/library/:followId` (redirects to `series` after resolving; kept for offline-capable deep links) | Library |
| `reader` | `/read/:sourceId/:seriesKey/:chapterKey` (`?page=&at=&all=`) | root |
| `readAll` | `/read-all/:sourceId/:seriesKey` (`?from=&page=&at=`) | root |
| `readerLanding` | `/read` | root |
| `novel` | `/novel/:sourceId/:seriesKey/:chapterKey` (`?page=&para=&at=`) | root |
| `listen` | `/novel/:sourceId/:seriesKey/:chapterKey/listen` | root |
| `library` | `/library` (`?tab=shelf|downloads|collections|history|bookmarks`) | Library |
| `libraryAll` | `/library/all` | Library |
| `collection` | `/library/collections/:id` | Library |
| `updates` | `/updates` | Home (bell) |
| `downloads` | `/library?tab=downloads` (alias `/downloads`) | Library |
| `storage` | `/settings/storage` | You |
| `ocr` | `/xray` | You |
| `stats` | `/stats` | You |
| `wrapped` | `/stats/wrapped/:year` | takeover |
| `circle` | `/circle` | You |
| `you` | `/you` | You |
| `settings` | `/settings` (`?panel=`) | You |
| `admin` | `/admin/status` | You |
| `notFound`, `routeError`, `rootError`, `offlineFallback` | n/a | n/a |

#### 4.0.3 Transitions shared by every screen

| Move | Spec |
|---|---|
| Tab or rail section change | **Dip to black**: outgoing opacity 1 → 0 over 120 ms `cine-in`, hold `#000` for 40 ms, incoming 0 → 1 over 240 ms `cine-out`. Scroll position of each tab root is kept. |
| Push to a detail (poster, row, card) | **Match cut**: the tapped art morphs into the destination's hero frame over 480 ms `cine-in-out`, radius 6 → 0; everything else fades 280 ms. Web: `document.startViewTransition` with `view-transition-name: art-<sourceId>-<seriesKey>`; Flutter: `Hero(tag: 'art-$sourceId-$seriesKey')` with a `flightShuttleBuilder` that lerps `BorderRadius` 6 → 0 and a `MaterialRectCenterArcTween`. |
| Push without shared art (settings rows, lists without thumbs) | Fade up 16 px, 360 ms `cine-out`; outgoing fades 200 ms. |
| Back | The reverse of the forward move at 0.75× duration. |
| Into a reader from a detail | **Push-in + letterbox curtain** (§8, moment 4). |
| Between chapters | A cut through black: 250 ms fade out, 0 hold, next chapter's first page fades in 250 ms; the chapter title types in at 50 ms per character in the top chrome. |
| Leaving a reader | The reader dissolves to black over 220 ms, the detail fades in over 280 ms; the art match-cuts back if the detail's hero is on screen. |

#### 4.0.4 Back and system behaviour per platform

| Platform | Back | System UI |
|---|---|---|
| iOS | Edge swipe from the leading 20 px edge (`swipeable_page_route` 0.4.8, edge-only in this skin). The outgoing screen translates with the finger and darkens to `#000` at 60 % (no parallax shadow). | Status bar light content; hidden in readers; `edgeToEdge`. Home indicator auto-hides in readers after 3 s. |
| Android | Predictive back via `PredictiveBackFullscreenPageTransitionsBuilder` (the outgoing screen scales to 0.9 and fades while the gesture previews); `android:enableOnBackInvokedCallback="true"`. | Edge-to-edge, transparent system bars with light icons; readers use `immersiveSticky`. |
| Web desktop | Browser back and `Alt+←` go through history; every sheet and overlay pushes a history entry so back closes it first. In-app links animate; browser back does not re-animate. | n/a |
| Mobile web (installed PWA) | Same as desktop web; the iOS PWA's own edge swipe is left to the browser. `appleWebApp.startupImage` set to black images so launch never flashes white. | `theme-color` `#000000`, `viewport-fit=cover`. |

#### 4.0.5 Global web keys (every app-frame screen)

`mod+k` palette · `mod+b` pin or unpin the rail · `?` shortcuts overlay · `/` focus the screen's search field (or open Search) · `g h` Home · `g l` Library · `g s` Sources · `g u` Updates · `g d` Downloads · `g f` For you · `g c` Circle · `g t` Stats · `m` toggle content mode · `Esc` closes the topmost overlay. Grids and rails use the arrow keys plus `h j k l`.

---

### 4.1 Setup (server URL, iOS and Android only)

**Layout (phone).** Bare frame. Top-left at the gutter: the stacked wordmark 28 px tall. Vertically centred block, max width 480 px: `typed-headline` "POINT ME AT YOUR SERVER." (typing reveal, 23 characters, 1150 ms), then IN1 "Server address" prefilled with `https://`, helper "The address you use for ManhwaManiacs in a browser.", then B1 `lg` full width "Connect". Behind everything, a single slow `house-glow` radial bloom at 12 % opacity breathing .8 ↔ 1 over 8 s `drift` (the projector warming up).

**Hierarchy.** Headline → field → button. Nothing else.

**Signature moment.** On a successful `GET /health` the field's trailing Check appears in `positive`, the bloom swells to 30 % over 480 ms, and the screen cuts to the pre-roll.

**Transitions.** In: from the native black splash, fade 400 ms. Out: dip to black into the pre-roll (§4.2).

**Gestures.** None beyond typing. Android back exits the app.

**States.** Default; typing; checking (button Loading, field Loading "Checking…"); invalid URL ("That isn't a web address."); unreachable ("No ManhwaManiacs server answered at that address."); http in a release build ("Use an https:// address."); success.

**Web.** Not rendered (the web client is served by the server).

### 4.2 Splash and pre-roll

**Layout.** Bare frame, `#000`. The neutral native splash (MM column in `#F3EEE6`, 192 dp circle on Android 12+, centred on iOS) is redrawn by the first Flutter or web frame at the same size and position, then the pre-roll (§7.4) plays: grain flicker, per-letter wordmark reveal, the gutter bar light sweep, bloom, stamp, track-out, cut to the destination.

**Session probe.** While the pre-roll plays, the app resolves the session (`GET /auth/me`, 3 s timeout). The pre-roll lasts `max(dataReady, 900 ms)`, capped at 1600 ms. If data is still missing at 1600 ms, it holds on the wordmark and bloom; after 2400 ms the leader sweep appears under the wordmark with `caption` ink-3 "Reaching your server…"; after 8 s, B3 "Change server" (mobile) appears under it.

**Transitions.** Out: to Login (fade up from black 400 ms), to the profile picker (the wordmark tracks out into the picker's typed headline), or straight to Home when a profile is remembered and the session is valid (fade up from black 400 ms, hero Ken Burns starts).

**Gestures.** Tap anywhere skips to the handoff.

**States.** Cold start (full pre-roll); warm start (app resumed within 4 h: mark fades in 200 ms, handoff 250 ms, no letters, no haptic); offline with a cached session (pre-roll, then Home in offline state); reduced motion (wordmark fades in 300 ms, holds until data is ready, fades out 200 ms).

**Web.** The root layout server-renders the neutral mark as inline SVG, then the same reveal plays after hydration, once per browser session (`sessionStorage['mm.skin.splash']`, read in try/catch).

### 4.3 Login

**Layout, desktop.** A split stage. Left 58 %: a slow **poster wall**: 5 columns of posters from a public showcase set of 15 cover images, `wall-01.jpg` to `wall-15.jpg`, served by the existing public `GET /app/media/{name}` route and exported from the demo profile (no account or profile data is shown before sign-in; when the files are missing, the wall is replaced by a single `house-glow` bloom breathing over 8 s), drifting upward at 12 px/s, each column at a different speed (12, 9, 14, 10, 13 px/s), dimmed to brightness .35, with `scrim-vignette` and a right-edge eased scrim to `#000`. Right 42 %, vertically centred, max width 400 px, left edge at 48 px: wordmark 36 px tall, 40 px gap, `display-page` "SIGN IN", 32 px gap, IN1 "Username", IN2 "Password", T2 "Keep me signed in" (checked by default), B1 `lg` full width "Sign in", 24 px gap, `body` ink-2 "New here? " + B3 "Create an account". Footer at the bottom-right: `timecode` ink-3 server host ("manhwamaniacs.xyz · v4.0.0").

**Layout, phone (mobile web, iOS, Android).** The poster wall fills the top 46 % of the screen (3 columns), fading into `#000` with `scrim-hero-foot`; the form sits below at the gutter, the wordmark overlapping the wall's scrim by 24 px.

**Hierarchy.** Wordmark → "SIGN IN" → fields → primary → register link.

**Signature moment.** On success, the button's label is replaced by the leader sweep; then every column of the poster wall accelerates upward (ease `cine-in`, 420 ms) while the form fades out 200 ms, and the screen cuts to the profile picker, whose "Who's reading?" headline starts typing on the first frame.

**Transitions.** In from pre-roll: fade up from black 400 ms, the wall starts drifting. From Register: the form area crossfades 280 ms (the wall stays). Out: as above.

**Gestures.** None special. Enter submits from any field.

**States.** Default; typing; submitting (button Loading, fields disabled); `invalid_credentials` ("That username and password don't match."); `account_disabled` ("This account is turned off. Ask the owner."); `rate_limited` (subtitle toast "Too many tries. Wait 40 s." with a countdown; button Disabled until the countdown ends); offline ("You're offline. Sign in needs the server."); **bootstrap** (no users exist): the form is replaced by `editorial-md` "This server has no owner yet." + B1 "Claim this server" → Register in bootstrap mode; server unreachable (title card error with B1 "Try again" and, on mobile, B3 "Change server").

**Keys (web).** Tab order: username, password, keep signed in, sign in, create account. `Enter` submits.

### 4.4 Register

Same stage as Login. Variants from `GET /auth/bootstrap-status`:

| Variant | Form |
|---|---|
| **Open** | `display-page` "CREATE ACCOUNT"; IN1 Username (helper "3–32 letters, numbers, dots, dashes or underscores."), IN1 Display name (optional), IN2 Password (helper "At least 8 characters." plus a strength bar: 3 px segmented bar in 4 segments, fill `rating` → `caution` → `positive` as it strengthens), IN2 Confirm; B1 "Create account"; B3 "I already have an account". |
| **Invite** | Adds IN1 "Invite code" first, monospaced (Geist Mono 17 px, tracking +0.12 em). |
| **Bootstrap** | Headline "CLAIM THIS SERVER"; body "The first account becomes the owner." plus a `caution` line with the window countdown ("Claim within 14:52"). |
| **Closed** | Title card: `editorial-md` "Sign-ups are closed on this server." + B2 "Back to sign in". |

**Signature moment.** After success, the new username types into the "Who's reading?" headline slot on the profile picker as "WELCOME, MIRA." before the headline retypes as "WHO'S READING?".

**States.** Field errors inline (`username_taken`, `invalid_username`, `weak_password`, passwords differ, `invite_code_required`, `invite_code_invalid`, `bootstrap_window_expired`, `bootstrap_already_claimed`, `registration_disabled`); submitting; rate limited; offline.

**Keys (web).** As Login.

### 4.5 Profile picker ("Who's reading?")

**Layout, desktop.** Takeover, `#000`. Centred: `typed-headline` "WHO'S READING?" at 56 px (typing reveal 50 ms per character, 14 characters, 700 ms), 56 px gap, a row of profile tiles: 144 px square avatar colourways (§3.26), 16 px gap, name in `heading-card` ink-2 below each, centred. After the profiles, an "Add profile" tile: a 144 px square with a 1.5 px dashed `hair-strong` frame and a Plus 32 px ink-3 (hidden at 5 profiles). Below the row, 48 px gap, B2 `sm` "Manage profiles". Bottom-left: the stacked wordmark 24 px; bottom-right: B3 "Sign out".

**Layout, phone.** Headline at 32 px, 40 px below the safe area. Tiles in a 2-column grid of 120 px squares (96 px when 5 profiles and the screen is < 360 px wide), centred, 24 px gaps. "Manage profiles" as B3 at the bottom above the safe area.

**Key light.** The focused or hovered tile's mood seed lights the room: a radial `key.glow` bloom at 40 % behind the tiles, dissolving 800 ms between profiles.

**Signature moment ("Spotlight").** On pick: every other tile and the headline fade to black over 420 ms `cine-in`; the chosen avatar scales to 1.25× with bloom E4; haptic `profile.pick`; then the avatar travels (shared element, 480 ms `cine-in-out`) to its slot (top-right avatar on desktop, the You tab glyph on phones) while Home fades up under it. If this profile's saved skin differs from the running one, the black frame after the fade is where the app restarts into the other skin (no confirm, no undo).

**Transitions.** In from login: the headline types on the first frame; tiles fade up 16 px with a 60 ms stagger. From the account menu or You → Switch profile: the current screen dips to black and the picker fades up. Out: Spotlight.

**Gestures.** Tap to pick. Long-press a tile (phone) or right-click (desktop) → M2 menu "Edit profile" / "Delete profile". Manage mode: tiles show a Pencil badge; tap edits.

**States.** Loading (tile frames flickering); content; one profile (still shown, never auto-skipped, because the picker is also the skin gate); no profiles (title card "Nobody reads here yet." + B1 "Create a profile"); offline with a cached profile (a `caution` line "Offline — continue as Mira" + B1 "Continue"); error (title card with Retry and "Continue as last profile" when cached).

**Keys (web).** ← → move between tiles, Enter picks, `e` edits the focused profile, `n` adds, `Esc` returns to the previous screen when a profile is already active.

### 4.6 Profile form (create, edit) and Manage profiles

**Layout.** Takeover on phones, a centred 560 px column on desktop. Top: a 144 px live avatar preview (it re-renders as choices change) with the mood's key light blooming behind it. Fields: IN1 "Name" (1–32 characters shown, 255 allowed by the server); **Colourway**: a 6 × 2 grid of 56 px avatar swatches (selected: 2 px ink ring + scale 1.06); **Mood**: a slate-tab row of the seven moods, each label preceded by a 10 px dot of its accent, and choosing one dissolves the page's key light to that mood over 800 ms; T1 "18+ content" (turning on opens the gate dialog, §3.23); **Skin** for this profile: a T4 segmented control "Cinematic · Glass" with helper "Switching to Glass restarts the app into Glass for this profile."; B1 "Save" / "Create profile"; B4 "Delete profile" (edit only, bottom).

**Manage profiles** (`/profiles/manage`, desktop and You → Profiles): a list of L1 rows (avatar 40 px, name, mood, "18+" badge when open, "Cinematic" or "Glass" in `timecode`), drag handles (DotsSixVertical) to reorder (`PATCH sort_order`), each row opening the form; B2 "Add profile" at the end, disabled with helper "Five profiles is the limit." at 5.

**Signature moment.** Changing the mood re-lights the whole takeover: the avatar preview's bloom and the page spill dissolve to the new mood while the name retypes in the mood's accent.

**Transitions.** In: fade up 16 px 360 ms. Out on save: the preview avatar match-cuts back into its tile on the picker.

**States.** Validation (`invalid_profile_name`: "Use 1 to 32 characters."), saving, `profile_limit_reached`, delete confirm dialog ("Delete Mira? Her library, progress, bookmarks and collections are deleted with her."), error, offline (fields disabled, `caution` line "Profile changes need a connection").

**Keys (web).** `mod+Enter` saves, `Esc` cancels.

### 4.7 Onboarding (a new profile's first visit)

Shown once per profile when it follows nothing, at `/welcome`, before Home.

**Scene 1 — "Opening titles".** Takeover. Black; `typed-headline` "LET'S FILL YOUR SCREEN." then `body-lg` ink-2 "Pick a few series you already love. We'll build your home around them." B3 "Skip" top-right.

**Scene 2 — "Poster wall".** A dense wall of Wall posters from the enabled sources' popular pages (`GET /sources/{id}/browse?mode=popular`, first page of each, interleaved, 18+ gated by the profile), 3 columns on phones, 6–8 on desktop, infinite scroll. Tapping a poster selects it (Selected state, haptic `library.add` on each pick) and dissolves the page's key light toward that cover, so the room's colour becomes a blend of the picks. A bottom bar over `scrim-bottom`: `timecode` "3 PICKED", B1 "Continue" (enabled at ≥ 1). A slate-tab row at the top filters by format: ALL · MANHWA · MANGA · MANHUA · NOVELS (novels only when enabled).

**Scene 3 — "Cut to home".** Continue follows every pick (`POST /library/follow` each), then the wall's selected posters fly (match cut, 60 ms stagger) into the first Home rail while the rest fade to black, and Home's headline types.

**States.** Loading wall (flickering frames), source errors (the failing source's posters are simply absent; if every source fails: title card "Sources aren't answering." + B1 "Try again" + B3 "Skip for now"), following in progress (Continue Loading), partial failure (toast "Followed 4 of 5. One couldn't be added."), offline (Scene 2 replaced by "Onboarding needs a connection." + B3 "Skip").

**Keys (web).** Arrow keys move over the wall, Space selects, Enter continues, `Esc` skips.

### 4.8 Home

Home is the AI home (§5.1 holds the AI states in full). This section covers the layout every profile sees.

**Layout, desktop.**
1. **Hero spotlight** full-bleed from x = 0 (under the rail's transparent region) to the right edge, height `clamp(560px, 41.84vw, 88svh)` (2.39:1 scope) on ≥ 1280 px, `max(420px, 56.25vw)` on 768–1279 px. The art is the spotlight series' cover, tilted down inside the scope frame by Ken Burns (`object-position` 50 % 12 % → 50 % 42 %, scale 1 → 1.1, 24 s `drift`, alternating, direction seeded from `hash(seriesId) % 4`), with `blur-fill` behind it and the full hero layer order from §2.1.5. Grain 0.07 overlay at 12 fps.
2. **Main headline** above the title block, at the gutter, 26 % of the hero height up from the bottom: `typed-headline` (typing reveal, 50 ms per character, ≤ 60 characters), for example "TONIGHT: CHAPTER 143 OF OMNISCIENT READER" or "3 NEW CHAPTERS SINCE YESTERDAY". The copy comes from the home feed's `headline` string, falling back to "TONIGHT'S LINEUP".
3. **Title block**, bottom-left, max width `min(40vw, 640px)`: the title treatment recipe (eyebrow, `display-hero` title with the per-letter reveal, accent rule, hook), then the actions row: B1 `lg` "Continue Ch. 143" or "Read Ch. 1", B2 `lg` "Previously on" (only when a recap applies, §5.1), IB1 "+", IB1 "i". Four seconds after the hero's motion starts, the hook and eyebrow fade out 600 ms (the title and actions stay), as on a billboard.
4. **Spotlight index**: bottom-right at the gutter, five 24 × 2 px segments (ink-4, the active one ink filling left → right over the 8 s dwell). Arrow keys or a click on a segment change the spotlight.
5. **Rails** start `rail-overlap` −96 px into the hero scrim, stacked by `rail stack` spacing, in this order (each omitted when empty): Continue reading (C1 cards), Previously on (recap cards, §5.1), New for you (Wall posters with NEW badges from `recently-updated`), Your circle is reading (§5.3), For you (AI, §5.1), Because you read X (one rail per seed, up to 3), Top 10 on your shelf this week (Ranked), Your downloads (only when offline or when downloads exist and the profile read one in 7 days), Sources (C3 hub tiles), and one rail per pinned source ("Latest on Asura").
6. **Footer**: `timecode` ink-3 "Last checked for new chapters 12 min ago" + B3 "Check now".

**Layout, phone (mobile web, iOS, Android).**
1. **Hero** full-bleed at 4:5, max 78 svh, under the transparent status bar; the cover fills it top-anchored with Ken Burns; the title block sits at the bottom inside `scrim-hero-foot` (70 %) with `display-hero` at clamp(40, 11vw, 56), the accent rule, and two actions side by side: B1 "Continue" (flex 1) and B2 "Previously on" or "Details" (flex 1), plus IB1 "+" at the end. The typed headline sits above the eyebrow at 24 px.
2. A 2 px segmented story strip at the very top under the status bar (five segments) shows auto-advance progress; the hero auto-advances every 8000 ms with a dissolve, pauses while touched, and swipes horizontally between spotlights (haptic none, sound `ui.page`).
3. TB1 floating bar: MM mark left; right: streak flame (when ≥ 2), IB2 Bell with badge, and the content-mode slates below the bar as `eyebrow` "MANGA · NOVELS" centred.
4. Rails as desktop with phone geometry; the first overlaps the hero by −40 px.
5. Pull to refresh (leader sweep) re-runs the feed and an update check.

**Hierarchy.** Art → title → continue action → the rest.

**Signature moments.** (a) The **key-light handoff**: dwelling 450 ms on any poster (hover or keyboard focus) dissolves the hero art and every key-light role on the page to that series while the hero is ≥ 30 % in view; the headline does not retype. (b) The typed headline on the first visit of the session.

**Transitions.** In from the picker (Spotlight) or pre-roll (fade up from black 400 ms). Tab re-entry: dip to black, hero at rest (no retype, Ken Burns resumes). Out to detail: match cut from the poster or from the hero art itself (the hero frame becomes the detail backdrop with no morph, only a 280 ms fade of the Home rails).

**Gestures.** Phone: horizontal swipe on the hero changes spotlight; long-press any poster opens Quick Look; pull to refresh; long-press the hero art opens the lightbox.

**States.**
- Loading (first paint): the hero shows the continue item's cached cover if known, otherwise a black stage with the headline typing "TONIGHT'S LINEUP" and a centred leader sweep after 1 s; rail headers render, posters are loading frames.
- Content.
- New profile with nothing read: routed to onboarding once; afterwards an empty Home shows the hero from the top popular series on the profile's pinned or first source with the headline "START SOMETHING NEW", and rails for "Popular on {source}".
- AI unavailable: AI rails are omitted; the rest renders; see §5.1.
- Offline: the hero shows the most recent downloaded series with B1 "Continue offline"; rails show only Your downloads and Continue reading entries that are downloaded; a `caution` line under the top bar "Offline — showing what's on this device".
- Error (feed failed, nothing cached): title card error.
- Rate limited: affected rails show the rail error line with "The source asked us to wait. Retrying in 12 s."

**Keys (web).** `←` / `→` on the hero change spotlight (when focus is on the hero), `Enter` continue, `p` open Previously on, `i` details, `+` add to library; rails as §3.9; `r` refreshes (update check).

### 4.9 Search

**Layout, desktop.** A page, not an overlay: SF1 at 64 px spans the content width at the top (48 px below the top strip), autofocused. Under it a slate-tab row of scopes: ALL · MY LIBRARY · one tab per enabled source ("ASURA 24", counts appear as results land). Results area:
- **Empty query**: "RECENT" (a row of removable filter tags for the last 12 queries, `x` removes one, B3 "Clear all") and "TRENDING ON YOUR SOURCES" (a Wall rail) and "BROWSE BY GENRE" (a grid of 16:9 genre tiles, each a blurred cover of that genre's top series with the genre in `heading-section`).
- **With a query**: the top result as a **mini hero** (a 2.39:1 band 280 px tall with the art, title treatment at `display-title` 48 px, B1 Read, IB1 +), then one Wall rail per scope group in rank order ("IN YOUR LIBRARY", then each source by result quality), each rail header followed by the count.

**Layout, phone.** SF1 pinned under the safe area; scopes as a horizontally scrolling slate row; results as a 3-column poster grid per group with the group header above each (sticky while its grid scrolls); the mini hero becomes a 16:9 card.

**Key light.** The top result owns the frame; focusing another result moves the light to it after 450 ms.

**Signature moment.** As results stream in per source, each group's posters rack-focus in and the page's key light dissolves to the top result, so the page visibly "develops" like a photograph.

**Transitions.** In: dip to black; the field focuses and its accent line draws. Out: match cut from the poster.

**Gestures.** Swipe between scope tabs (phone); long-press Quick Look; pull down dismisses the keyboard.

**States.** Idle (recents and trending); typing (220 ms debounce, per-group leader sweeps); partial (some sources still searching: their tabs show a 12 px leader sweep); no results ("Nothing called “grave” on your sources." + B3 "Ask for something like it" → For you with the query prefilled); source failed (that group's rail error line); offline (searches "MY LIBRARY" and downloads only, with a `caution` note "Only your library and downloads while offline"); rate limited (per group).

**Keys (web).** `/` focuses the field, `Enter` searches immediately, `↓` moves into results, `mod+1…9` switch scope tabs, rails as §3.9.

### 4.10 Sources

**Layout, desktop.** TB2 title "SOURCES". A strip of C3 hub tiles for pinned sources first (16:9, 4 per row at 1440 px), then "ALL SOURCES" as L1 rows: 40 px source mark (favicon on a `key.tint` square, or the source's initial in Mona Sans), name `body-strong`, `caption` ink-3 "Manhwa · English · 2,430 series", a health dot (8 px: `positive` healthy, `caution` slow, `rating` down) with its label on hover, badges (18+), and trailing IB2 PushPin (pin / unpin). Filters above the list as text chips: ALL · PINNED · MANHWA · MANGA · MANHUA · NOVELS · 18+ (only when the gate is open) · DOWN.

**Layout, phone.** Pinned hubs as a horizontal rail of 16:9 tiles (1.2 visible), then the filter row, then the list.

**Key light.** The focused or hovered source's newest cover.

**Signature moment.** Pinning a source lifts its row into the hub strip: the row's mark scales up and the new C3 tile rack-focuses in at the end of the strip (480 ms), haptic `library.add`.

**Transitions.** Tab entry: dip to black. Into a source: the hub tile or row mark match-cuts into the catalogue's header.

**Gestures.** Swipe a row left to pin or unpin (phone); long-press a hub tile → M2 (Unpin, Open, Check health).

**States.** Loading (row skeletons + hub frames); content; empty filter ("No down sources. Everything is answering."); pinned source unavailable on this profile (the pin is simply not listed, per the gate rule); source down (row at 60 % with the `rating` dot and "Not answering since 09:14"); offline (list from cache, health dots hidden, a `caution` line); error.

**Keys (web).** `j` / `k` move through rows, `Enter` opens, `p` pins, `/` filters.

### 4.11 Source catalogue

**Layout, desktop.** A header band 240 px tall: the source's newest cover with `blur-fill` and `key.tint` wash, the source name in `display-page`, `caption` ink-3 counts, and B2 "Pin"; below it a sticky control row (TB1 solid state on scroll): slate tabs for browse modes (POPULAR · LATEST · plus any source-specific modes), a genre selector (M1 menu showing "GENRE: ALL", multi-select on sources that allow it), SF2 search within the source (`/`). Then a Wall poster grid (6–8 columns by width, 12 px gaps), infinite scroll with a leader sweep row at the end, and a staleness badge ("OFFLINE COPY · 14:02") above the grid when served stale.

**Layout, phone.** Header 180 px; controls as a sticky row; 3-column grid.

**Key light.** The focused poster after 450 ms; otherwise the first result.

**Signature moment.** Changing the browse mode is a **cut**: the grid swaps instantly and every visible poster rack-focuses in with a 24 ms stagger.

**Gestures.** Long-press Quick Look; pull to refresh; swipe between browse-mode tabs (phone).

**States.** Loading; content; end of catalogue ("That's everything on this page of Asura."); search no results; `source_not_browsable` (title card "This source can only be searched." + SF2 focused); source down with a stale copy (badge) or without (title card error); rate limited; offline (stale copy if cached, otherwise offline title card).

**Keys (web).** Grid arrows / `h j k l`, `Enter` opens, `Space` preview slate, `/` search, `1`–`4` switch modes, `g` opens the genre menu.

### 4.12 Series detail (manga, manhwa, manhua)

One screen for both entry routes (a followed series and a source series). The followed-only controls (favourite, status, notify, 18+ override, collections) appear when the series is in the library.

**Layout, desktop.**
1. **Backdrop**: the cover fills the top 88 svh (2.39:1 on ≥ 1280 px) with Ken Burns, grain, vignette, parallax factor 0.35 as it scrolls out, and `scrim-hero-foot` ending in `key.tint`. The page background below is `key.tint` fading to `#000` over 60 svh (page spill). The whole page is lit by this series.
2. **Title block** bottom-left: eyebrow ("MANHWA · ONGOING · 2021 · ASURA"), `display-title` title in `key.ink` with the per-letter reveal after the match cut lands, the accent rule, alt titles in `caption` ink-3 (one line, CJK in Noto), author in `body` ink-2.
3. **Action row**: B1 `lg` "Continue Ch. 41 · p. 12" / "Read Ch. 1" / "Read again"; B2 `lg` "Previously on" (when a recap applies); IB1 "+" (library, Selected when followed); IB1 Download (opens the download picker); IB1 `mm-autoscroll` "Read all" (continuous series scroll); IB2 DotsThree overflow → M1: Recommend to…, Add to collection, Share card, Check for new chapters, Notify me (toggle), Favourite (toggle), Status (submenu: Reading, Plan to read, On hold, Completed, Dropped, Unread), Treat as 18+ (gate open only), Open on the web (the source's page URL), Remove from library.
4. **Meta line** under actions: `timecode` ink-2 "120 CHAPTERS · 3 NEW · UPDATED 2H AGO", a `caption` genre line with `/` separators in `key.accent`, and Circle avatars ("Mira and Theo read this").
5. **Synopsis** `body-lg` ink-2, 62 ch max, clamped to 4 lines with B3 "More".
6. **Slate tabs** (sticky under the top strip on scroll): CHAPTERS · MORE LIKE THIS · DETAILS.
   - **Chapters**: a toolbar (sort newest / oldest as a T4 segmented control, SF2 "Go to chapter", B3 "Select" to enter select mode, a `timecode` "41 / 120 READ" summary) and the L2 chapter rows. In select mode a bottom action bar rises (Download, Mark read, Mark unread, Add bookmark to latest; helpers "Next 10", "All unread", "All" as text chips), 200 ms `cine-out`.
   - **More like this**: Wall posters from similar-series AI results (§5.1) with the `why` line under each.
   - **Details**: a two-column fact list (Source, Status, Format, Chapters known, Last checked, Added, Rating from AniList when mapped, Official platforms as B3 links) and the Circle's reactions to recent chapters.
7. **Right column** (≥ 1440 px): a 320 px sticky column beside the tabs with the Continue C1 card, the reading progress bar for the series (`timecode` "34 %"), and the next-chapter preview (the first page of the next unread chapter, cropped 16:9 at brightness .6).

**Layout, phone.** The backdrop is a 4:5 hero with the title block at its foot; the action row becomes B1 full width, then a row of four IB1 buttons with `micro` labels under them (MY LIST, DOWNLOAD, READ ALL, SHARE); the synopsis follows; slate tabs stick under TB1 (which turns solid with the title after the hero scrolls away). Chapter rows at 56 px. Overscroll down on the hero stretch-zooms the art up to 1.15× at 120 px pull.

**Download picker** (IB1 Download, `d`): a `full` sheet (phone) or 440 px side panel (desktop): `eyebrow` "DOWNLOAD", helper text chips NEXT 10 · ALL UNREAD · ALL · NONE, the chapter list with T2 checkboxes and each row's download control and size estimate ("≈ 24 MB"), a `timecode` summary "12 CHAPTERS · ≈ 290 MB · 21 GB FREE", T1 "Keep (never delete automatically)", and B1 "Download 12 chapters". States: nothing selected (B1 Disabled "Select chapters"), over the storage cap (`caution` line "This goes over your 10 GB cap. Older read chapters will be removed first."), under the free-space floor (B1 Disabled, `caution` "Not enough free space on this device."), offline (B1 Disabled "Downloads need a connection"), queued (toast "Queued 12 chapters." + "View").

**Hierarchy.** Art → title → Continue → chapters.

**Signature moment.** The **match cut** from the tapped poster into the backdrop, then the title's per-letter reveal and the accent rule drawing in, while the page spill dissolves from black to this series' `key.tint`: the room takes the colour of the book the reader just picked up. For 18+ series the rating card appears after the title lands (§3.23).

**Transitions.** In: match cut (480 ms). Out: back reverses the match cut to the originating poster if it is still mounted, otherwise dip to black. Into the reader: push-in + letterbox curtain.

**Gestures.** Long-press backdrop → lightbox; swipe between slate tabs (phone); swipe a chapter row left → Mark read / unread; long-press a chapter row → M2 sheet (Read, Download, Mark read, Mark all above as read, Bookmark start); pull to refresh re-checks the series (`POST /updates/followed/{id}/check`).

**States.**
- Loading: the backdrop from the poster that was tapped (it is already decoded, thanks to the match cut), title block renders from list data, chapters as row skeletons.
- Content.
- Not in library: IB1 "+" default; follow → Selected, haptic `library.add`, sound `ui.stamp`, toast "Added to your library."; `follow_limit_reached` → toast "Your library is full (1,000 series)."
- Offline, downloaded: the page renders from the local store, chapter rows show which are on the device, non-downloaded rows at 50 % opacity with "Needs a connection" on tap; a `caution` line under the meta.
- Offline, not downloaded: title card offline.
- `series_not_found`: title card "This series is gone from its source." + B1 "Search other sources" (prefilled search) + B3 "Remove from library".
- Source down with cached data: badge "OFFLINE COPY · 14:02", read actions still try the reader.
- No chapters: the Chapters tab shows `editorial-md` "No chapters yet." + B3 "Check now".
- Rate limited: rows and chapters show the slow-down line.

**Keys (web).** `Enter` continue, `r` read from start, `a` read all, `+` library, `d` download picker, `p` previously on, `1` / `2` / `3` switch tabs, `/` go to chapter, `j` / `k` move through chapter rows, `x` toggle select on the focused row, `Esc` back.

### 4.13 Series detail (novel): "The book"

Same frame as 4.12, re-dressed as front matter.

**Layout.** The backdrop is the cover rendered as a **book jacket**: on desktop the full cover stands at 2:3, 420 px tall, left of the title block on a `blur-fill` stage (the only place a cover is shown whole rather than cropped, because prose readers identify books by their jackets); on phones the jacket sits centred at 60 % width above the title. Title block in `display-title`, but the hook line is set in Instrument Serif italic 22 px. Action row: B1 "Continue Chapter 212 · 42 %" / "Start reading"; B2 "Listen" (Headphones, when narration exists); IB1 "+"; IB1 Download ("Download the book" sheet); IB1 `mm-voices` Audiobook (opens the audiobook sheet, §4.17.5). Tabs: CONTENTS · MORE LIKE THIS · DETAILS. Contents rows show the ordinal in `timecode`, title, word count ("3.4K WORDS"), a Headphones 16 px glyph when narrated, and the download control. The contents toolbar has SF2 "Go to chapter" (Enter jumps to the first match, digits match chapter numbers).

**Signature moment.** The jacket drops into its place with the match cut, then a single Instrument Serif line (the first sentence of chapter 1, when the text is cached) types beneath the title at 50 ms per character, as an epigraph.

**States.** As 4.12, plus: narration unavailable (Listen hidden; the audiobook sheet explains), "Download the text first" hints on un-downloaded chapters when saving audio.

**Keys (web).** As 4.12, plus `l` listen.

### 4.14 Manga reader

One reader engine, three presentations: **Strip** (webtoon vertical, the default for manhwa and manhua), **Paged** (single page, the default for manga, left-to-right or right-to-left), and **Spread** (two pages side by side on landscape screens ≥ 1024 px wide). **Read all** is Strip across every chapter.

#### 4.14.1 Canvas

- Background `#000` always (the reader's page background option offers Black `#000000`, Dim `#0A0A0A`, and Paper `#F5F1E8` for scanned pages with white gutters; Paper is a page setting, not a UI theme).
- **Strip**: pages flush, no gaps, width = viewport width on phones and `min(100vw − 2 × side panels, 900 px)` on desktop (user width option: 640 / 760 / 900 / 1100 / full). The areas left and right of the strip are `#000` with a **page-light spill**: a vertical band 240 px wide on each side, a horizontal radial gradient from `key.glow` (the current page's glow) at 22 % next to the strip edge to transparent, dissolving over 1200 ms as pages change. The strip itself is never tinted.
- **Paged / Spread**: the page fits the chosen mode (fit width, fit height, fit screen), centred, with the same page-light spill in the letterbox.
- **Chapter seam** (between chapters in continuous scroll and read all): 96 px of black, then the next chapter's number in `heading-section` with the per-letter reveal (running as it scrolls into view), `caption` ink-3 title, 96 px of black.
- **Broken page**: the page's reserved box (exact height from the manifest's `width/height`) filled `n-100` with `caption` ink-3 "Page 7 didn't load." and B3 "Retry".
- **Colour filters** (reader settings): None, Sepia, Grey; brightness overlay `#000` up to 72 %; warmth overlay `#FF8A00` up to 36 % (multiply), both pointer-transparent.

#### 4.14.2 Chrome ("house lights")

Chrome auto-hides after 2500 ms of no interaction, hides immediately on scroll start, and returns on a tap in the centre zone, pointer movement (desktop), or any key. In 220 ms `cine-out` (opacity + 8 px translate), out 160 ms `cine-in`.

- **Top** over `scrim-reader-top`: IB2 ArrowLeft (Back); the series title in `heading-card` ink with the chapter below it in `timecode` `key.accent` ("CH 124 · THE SILENT KING"), the whole block a button to the series page; right: IB2 BookmarkSimple, IB2 `mm-panel` (panel view, when panel data exists), IB2 SlidersHorizontal (reader settings).
- **Bottom** over `scrim-reader-bottom`: the **timeline scrubber** full-bleed (gutter-inset on desktop): a 3 px track `rgba(245,245,241,.20)` with the accent fill up to the current position; in read all, chapters are segments separated by 2 px gaps (the current chapter segment brighter). Touching or hovering grows the track to 6 px and shows a 12 px ink thumb (20 px while dragging). Desktop hover shows a **page thumbnail preview** 120 px wide above the pointer with "PAGE 18 / 64" in `timecode`. To the right of the scrubber: `timecode` ink-2 "7 MIN LEFT" (from the page count remaining and this profile's median seconds per page). Under the scrubber: IB2 SkipBack (previous chapter), `timecode` "PAGE 18 / 64", IB2 `mm-autoscroll` (auto-scroll play), IB2 `mm-soundscape`, IB2 SkipForward (next chapter).
- **Page-tinted chrome**: both scrims blend 24 % toward the current page's `key.tint`, the scrubber fill and chapter label use the page's `key.accent`, and a 1 px `key.glow` underglow runs under the bottom bar. All dissolve over 1200 ms when the page under the reading line changes. This is the "reader chrome tinted by dynamic colour" feature (§5.4.4).
- **Micro progress**: when the chrome is hidden, a 2 px line in the page's `key.accent` stays at the very bottom above the safe area. Cinema mode (`c`) hides it too.
- **Desktop side panels** (≥ 1280 px, both optional, toggled from the top bar or keys): left **Chapters** (320 px, the series' chapter list with read state, current chapter highlighted, thumbnails of the first page, the Circle's reactions count per chapter) and right **X-Ray** (360 px, dialogue search inside this series, §4.24). Panels are `#000` with the page-light spill continuing under them; they push the strip, never overlay it.

#### 4.14.3 Gestures and input

| Input | Strip | Paged / Spread |
|---|---|---|
| Tap centre zone (middle 40 % of width) | Toggle chrome | Toggle chrome |
| Tap left / right zones | Scroll one screen up / down (opt-in; default: toggle chrome) | Previous / next page (mirrored for RTL) |
| Double tap | Zoom 1× ⇄ 2× around the tap point (280 ms `cine-out`) | Same |
| Pinch | Zoom 1×–3× | Zoom 1×–4× |
| Long-press a page | Page menu sheet: Save page to photos / Files, Share page to Circle, Search this page's text (OCR), Report broken page and reload | Same |
| Left-edge vertical swipe (phone) | **Brightness HUD**: a 6 × 140 px capsule HUD on the left with a Sun glyph; below 0 it becomes "NIGHT −40" | Same |
| Right-edge vertical swipe while auto-scroll runs | **Speed HUD** "1.5×" | n/a |
| Horizontal swipe | n/a | Page turn: slide, 300 ms `cine-out`, with the `rig` spring on release |
| Five taps in the centre when locked | Unlock (toast "Reader unlocked", haptic `unlock.reader`) | Same |
| iOS leading-edge swipe | Leave the reader | Leave (from page 1 only in LTR; otherwise it turns pages) |
| Android predictive back | Leave the reader | Leave |
| Volume keys (Android, opt-in) | Scroll one screen | Turn page |
| Wheel (desktop) | Native scroll; `ctrl` + wheel zooms | One page per gesture with a 200 ms idle reset |
| Middle click (desktop) | Autoscroll anchor (12 px dead zone, 10 px/s per px of offset, max 4000 px/s) | n/a |

#### 4.14.4 Chapter end: "credits" and Up Next

After the last page of a chapter (Strip and Paged both):
1. 96 px of black.
2. "END OF CHAPTER 124" in `heading-section` with the per-letter reveal, centred, and the chapter title in `caption` ink-3.
3. **Reactions row** (§5.3): five reaction glyphs as IB1 buttons, and the avatars of Circle members who reacted (reactions only; there is no comment field).
4. **Up Next card**: 16:9, max 720 px wide, `r-frame`: the next chapter's first page cropped and blurred 24 px behind a sharp inset thumbnail (2:3, 120 px) on the left; right side: `eyebrow` "UP NEXT", `heading-section` "CHAPTER 125", title `body` ink-2, `timecode` ink-3 "42 PAGES · ~6 MIN"; B1 "Read next" (48 px). Enters with a fade up 24 px over 480 ms `cine-out`, haptic `chapter.endcard`, sound `ui.curtain`.
5. **Pull to continue**: past the card, a 150 px (phone) / 300 px (desktop) region fills a 3 px accent track left → right with the overscroll distance; crossing it fires haptic `chapter.commit` and a 250 ms fade-through-black cut into the next chapter, whose chapter label types in the top chrome at 50 ms per character.
6. **Auto-advance**: only while auto-scroll is on, a 5 s leader-sweep countdown (accent fill) around the Read next button advances automatically; tap or `Enter` goes now; scrolling up or `Esc` cancels.
7. **Last chapter known**: the card becomes "YOU'RE CAUGHT UP" in `editorial-md`, `caption` "We'll tell you when Chapter 125 lands.", T1 "Notify me" (the per-series notify flag), and a "MORE LIKE THIS" rail below.
8. **Next chapter missing on this device while offline**: "CHAPTER 125 ISN'T DOWNLOADED" + B2 "Back to the series".

In **Read all**, the credits block is replaced by the chapter seam (§4.14.1) and progress is written per chapter.

#### 4.14.5 States

| State | Visual |
|---|---|
| Opening (manifest loading) | The letterbox curtain is closed on black; the chapter number types in `heading-section` in the centre; after 1 s the leader sweep appears below it |
| Page loading | The page's exact reserved box in `#000`; on decode the page fades in 160 ms (no focus pull in the reader, to keep reading calm) |
| Page failed | Broken page tile (§4.14.1) |
| Chapter empty | Title card "This chapter has no pages." + B1 "Next chapter" + B3 "Back to the series" |
| Error (manifest failed) | Title card error with B1 "Try again", B3 "Back to the series" |
| Offline, downloaded | Reads from the device; a CloudSlash 16 px `timecode` badge "ON DEVICE" in the top chrome; neighbours show only if downloaded |
| Offline, not downloaded | Title card offline with B1 "Open downloads" |
| Stale bookmark anchor | Toast "This chapter changed — opened at page 9 instead of 12." |
| Another device is further ahead (`advanced: false`) | Toast "You're further on another device — Chapter 131, page 4." + action "Jump" |
| Locked | A 16 px Lock glyph appears top-right for 1 s when a tap is ignored |
| Rate limited | Pages pause fetching; a subtitle toast "The source asked us to wait — resuming in 8 s." |
| 18+ series | Rating card on start (once per session) |

#### 4.14.6 Keys (web)

`→` / `d` turn page right, `←` / `a` turn left (reading direction aware), `j` / `k` next / previous page, `Space` / `Shift+Space` one screen forward / back, `Home` / `End` first / last page, `h` / `l` previous / next chapter (also `Ctrl+Shift+←/→`), `g` go to page, `f` fullscreen, `c` cinema (hide all chrome), `m` show / hide chrome, `p` auto-scroll play / pause, `<` / `>` auto-scroll slower / faster, `v` panel-by-panel view, `b` bookmark, `s` series page, `t` chapters panel, `x` X-Ray panel, `,` reader settings, `=` / `+` zoom in, `-` zoom out, `0` reset zoom, `w` Strip, `r` Paged RTL, `e` Paged LTR, `2` Spread, `Esc` close overlay → leave fullscreen → exit reader, `?` shortcuts.

#### 4.14.7 Reader landing (`/read`)

A direct-URL placeholder: title card `editorial-md` "Pick something to read." + B1 "Continue {last series}" (when known) + B2 "Open library".

### 4.15 Reader settings

Opened by the SlidersHorizontal button, `,`, or a long-press on the scrubber. Phone: a sheet at the `peek` detent (40 %) that can rise to `full`, drawn over the page with the page still visible above it (a live preview). Desktop: a 440 px right side panel pushing the strip.

Sections (each headed by an `eyebrow`):
1. **MODE**: T4 "Strip · Paged · Spread"; for Paged, T4 "Left to right · Right to left".
2. **FIT**: T4 "Width · Height · Screen"; Strip width T4 "640 · 760 · 900 · 1100 · Full" (desktop only).
3. **LIGHT**: S1 Brightness (20–100 %), S1 Warmth (0–100 %), T4 "Colour · Sepia · Grey", T4 page background "Black · Dim · Paper".
4. **AMBIENT**: T1 "Tint the chrome from the page" (default on), T1 "Page-light spill" (default on), soundscape row → opens the soundscape sheet (§5.4.2).
5. **AUTO-SCROLL**: T1 "Auto-scroll", S1 Speed 0.25×–4× (1× = 60 px/s, step 0.25, haptic `autoscroll.step` per step), T1 "Pause at chapter end" (default on).
6. **TAPS**: a diagram of the page with three zones (left, centre, right); tapping a zone cycles Previous · Menu · Next; B3 "Reset"; helper "Mirrors for right-to-left until you change it."
7. **ZOOM**: IB1 "−", `timecode` "100 %" (tap resets), IB1 "+" (50–300 %, step 10).
8. **DISPLAY** (Android): T4 refresh rate "Auto · 60 · 90 · 120"; T1 "Keep screen on"; T1 "Volume keys turn pages".
9. B3 "Reset reader settings" (confirm dialog).

States: every control applies live (no save button); settings persist per profile; a toggle whose save fails reverts with a toast.

### 4.16 Novel reader

**Canvas.** The page is a **paper**: one of seven dark papers (no light paper exists).

| Paper | Background | Text | Muted | Contrast (text / muted) |
|---|---|---|---|---|
| Void | `#000000` | `#D9D6D0` | `#8A877F` | 14.5:1 / 5.9:1 |
| Ink | `#0B0B0C` | `#E6E3DD` | `#8F8C86` | 15.4:1 / 5.9:1 |
| Night paper | `#15110C` | `#E8D8BE` | `#9C8E78` | 13.4:1 / 5.9:1 |
| Dusk | `#0D1117` | `#D3DAE3` | `#8590A0` | 13.4:1 / 5.9:1 |
| Moss | `#0E130F` | `#D5DECF` | `#879384` | 13.6:1 / 5.8:1 |
| Rosewood | `#160E10` | `#EBD5D8` | `#A08A8E` | 13.6:1 / 5.9:1 |
| **Key** (default) | the series' `key.tint` | `ink` mixed 10 % toward `key.accent`, lightened until ≥ 13:1 | `key.accent` darkened until 5.5:1 | ≥ 13:1 / ≥ 5.5:1 |

"Key" is the art-first paper: every book reads on a black faintly lit by its own cover.

**Typography controls** (per series, with a per-profile default): face (Newsreader, Literata, Source Serif 4, Atkinson Hyperlegible Next, Geist), size 14–32 px (default 19), line height 1.40–2.10 (default 1.70), measure 48–88 ch (default 66), paragraph spacing 0–1.2 em (default 0.6 em with first-line indent 1.4 em, or 1 em with no indent when the "Block paragraphs" toggle is on), justification (left / justified with hyphenation), margins derived from the measure.

**Layout.** Strip-like vertical scroll by default (**Scroll**), or **Pages** (paginated columns). The column is centred. Chapter opener: `eyebrow` "CHAPTER 212" in muted, the title in Instrument Serif at 1.9× body size in text colour, a 48 px hairline, `timecode` "3.4K WORDS · 14 MIN"; the first paragraph has a 3-line drop cap in Instrument Serif. Scene breaks: a centred `✦` at 0.9× in muted with 1.6 em padding.

**Page turns (Pages mode).** Default **Slide**: the outgoing page slides 100 % while the incoming slides in with a 12 px parallax, 300 ms `cubic-bezier(0.2, 0, 0, 1)`, finger-tracked with `rig` release. Option **Cut**: a 140 ms crossfade. No curl in this skin. Haptic `page.turn`.

**Chrome.** Tap the centre toggles (fade 180 ms). Top: IB2 ArrowLeft, the chapter title in `heading-card` (text colour), a `timecode` ON DEVICE badge when offline, IB2 ListBullets (Contents), IB2 BookmarkSimple, IB2 `mm-voices` (Voices), IB2 TextAa (Text and page). Bottom: IB2 CaretLeft (previous chapter), a thin 2 px progress bar across the middle with `timecode` "42 %" and "11 MIN LEFT IN CHAPTER", IB2 CaretRight. When the chapter has narration, a **mini player** rides above the bottom chrome (§4.17.1). Chrome backgrounds are the paper colour at 92 % with a `hair` rule; there are no scrims, because the paper is not art.

**Text and page sheet** (`t`): phone `peek` sheet in the paper colour with a live preview paragraph above the controls; desktop 440 px side panel. Face as five tiles each set in its own face; steppers (IN4) for size, line height, measure; paper swatches (7 squares 44 px, each drawn in its own background with an "Aa" in its text colour, selected: 2 px ink ring); T4 "Scroll · Pages"; T4 "Slide · Cut" (Pages only); T1 "Justify"; T1 "Block paragraphs"; T1 "Auto-next chapter" (default on: opens the next chapter 900 ms after the end when narration is not playing).

**Contents sheet**: `full` detent; `eyebrow` "CONTENTS", SF2 "Go to chapter" (digits match numbers; "No chapter 400 in this book."), rows (ordinal `timecode`, title, current row `key.wash` fill and weight 600, Headphones glyph when narrated), pre-scrolled to the current chapter; states: loading, "The contents need a connection to load." offline.

**Signature moment.** On opening a chapter, the chapter title writes itself in Instrument Serif by the per-letter reveal, then the drop cap rack-focuses in (blur 16 → 0, 520 ms) as the first paragraph fades in.

**Transitions.** In from the book page: the jacket push-in + curtain (§8 moment 4), landing on the paper colour instead of black. Chapter to chapter: 250 ms fade through the paper colour; the new chapter opener reveals.

**Gestures.** Tap zones (Pages: left / right turn pages; Scroll: centre toggles chrome); swipe (Pages); long-press a paragraph → a menu sheet: Bookmark this paragraph, Copy, Share quote card (a 9:16 image in Instrument Serif over the series' key light, §5.2.5), Listen from here; pinch changes text size (± 1 px per 8 % scale, haptic `page.turn` per step).

**States.** Loading (paper colour with the chapter number typing in muted); content; error / no text (title card in the paper's colours); offline downloaded (ON DEVICE badge); end of downloaded copy ("END OF THE DOWNLOADED COPY" + B2 "Back to the book"); end of the book ("END OF THE BOOK, FOR NOW." + T1 Notify me); stale anchor toast ("This chapter changed — opened at paragraph 12 instead of 14."); bookmark saved toast ("Bookmarked at 42 % of this chapter").

**Keys (web).** `←` / `→`, `j` / `k`, `Space` / `Shift+Space` page, `Home` / `End`, `h` / `l` chapter, `t` text and page, `c` cinema, `m` chrome, `b` bookmark, `=` / `-` / `0` text size, `f` fullscreen, `o` contents, `v` voices, `p` play / pause narration, `Esc` back to the book.

### 4.17 Listen mode

Narration uses pre-rendered audio with dialogue attribution and 31 named voices. Listen mode has four surfaces.

#### 4.17.1 Mini player (inside the novel reader)

A 64 px bar above the bottom chrome, full width minus 2 × gutter on phones and 560 px centred on desktop, fill `key.wash` at 96 %, `r-frame`, with a 2 px `key.accent` progress line along its top edge (buffered portion `ink-4`). Left: 40 × 60 px cover thumb; centre: chapter title `body-strong` and `timecode` "5:12 · −18:40"; right: IB2 Rewind (−15 s), IB3 play disc at 44 px, IB2 FastForward (+15 s). It stays visible for 5000 ms after the chrome hides, then slides down 80 px (220 ms `cine-in`); a PushPin in its overflow keeps it pinned. Tapping the bar opens the full player. Horizontal swipe skips to the previous or next chapter (haptic `chapter.commit`).

States: loading audio (play disc Loading), preparing (`audio_preparing`: "Preparing narration…" with an indeterminate top line), failed (Warning in the disc, tap retries; "Audio could not be loaded"), offline and saved (plays from the device), offline and not saved (disc Disabled, "Audio needs a connection").

**Highlight while narrating.** The spoken sentence gets a background band of the speaker's tint at 14 % (narrator: `key.accent` at 12 %), `r-hair`, padded 2 × 4 px, crossfading 120 ms between sentences; the spoken word brightens to 100 % text colour with a 2 px underline in the tint (no animation). The reading line is at 38 % of the viewport; the view scrolls (400 ms `cine-out`) only when the sentence leaves the 20–70 % band and jumps instantly when it is more than 2 viewports away. A manual scroll decouples following and shows a "Back to voice" chip (a `#000` band with a Headphones glyph and label, bottom-centre above the mini player). If the text and timing no longer match, nothing is highlighted and a one-line `caption` note says "Highlight paused: text changed".

#### 4.17.2 Full player: "Now showing"

Route `/novel/…/listen`, full screen (phone) or a 480 px right panel over the reading column (desktop, with a "Theatre" toggle making it full screen).

- **Backdrop**: the cover full-bleed with `blur-fill` (40 px), a 60 % black scrim, `key.glow` bloom at the top third, grain 0.05, Ken Burns at 32 s.
- **Top**: IB2 CaretDown (collapse), `eyebrow` "NOW SHOWING", IB2 DotsThree (Save audio, Sleep, Voices, Go to book).
- **Subtitle stage** (centre, 60 % of the height): a lyrics-style list of sentences in Geist 22 px (phone) / 28 px (desktop), line height 1.35, the active sentence at 100 % ink with the speaker's name above it in `micro` in the speaker's tint (for dialogue), the others at 35 % ink; the list auto-centres the active sentence (480 ms `cine-in-out`). Scrolling decouples it and shows a "Play from here" row on the sentence under the reading line; it re-couples after 4000 ms idle.
- **Transport**: a full-bleed scrubber (3 px, 6 px on touch) with chapter time `timecode` at both ends, then IB2 SkipBack (previous chapter), IB2 Rewind 15, IB3 play disc 72 px, IB2 FastForward 15, IB2 SkipForward.
- **Tiles row**: three text tiles (no boxes), each an `eyebrow` label over a value in Mona Sans 28 px: SPEED "1.25×", VOICES "4 CAST", SLEEP "22:10" (live countdown) or "OFF". Each opens its sheet.

States as the mini player, plus: "Nobody has been identified in this chapter yet, so the narrator reads it all." (cast empty), and the chapter-boundary post-play card: "NEXT CHAPTER IN 5" with a 40 px ring countdown in `key.accent`, the next title typing, B1 "Play now", B3 "Cancel"; chrome stays visible during it; haptic `chapter.endcard`.

#### 4.17.3 Speed, sleep and audio sheets

- **Speed**: S3 speed ruler 0.5–3.0× with preset text chips 0.8 · 1 · 1.25 · 1.5 · 2 and the WPM line. Pitch is preserved (`just_audio.setSpeed`, `HTMLMediaElement.preservesPitch`).
- **Sleep**: T3 radios: Off, 5, 10, 15, 30, 45, 60 min, End of chapter, End of next chapter, Custom (IN4 stepper 1–180 min). The volume fades out over the last 8 s. Mobile: shake to add 5 min (toast "Sleep timer +5 min").
- **Save audio**: the narration save control from the chapter (states: not saved, saving with progress ring, saved (Check `positive`, tap → "Remove saved audio?" dialog), failed, "The saved audio can't play on this device — tap to save again").

#### 4.17.4 Voices: the casting board

Opened from the Voices tile, the reader's `mm-voices` button or `v`.

- **Cast list ("credits")**: rows set like end credits, centred: character name in `body` ink-2 right-aligned, a dotted leader in ink-4, the voice name in `body-strong` ink left-aligned, and the share of lines in `timecode` ink-3 ("31 %"). The Narrator row is pinned on top. Status lines: "Looking up who speaks here…", "Narrated by Aria — her own lines are read in the narrator's voice." Tapping a row opens the board filtered to that character's gender. After a change: the row shows "Re-voicing…" with a leader sweep until the next render is ready. Note under the list: "Chapters already rendered keep the voice they were made with."
- **Casting board (voice picker)**: a `full` sheet (phone) or a 720 px dialog-sized panel (desktop). Top: SF2 "Search voices", text chips ALL · FEMALE · MALE · IN USE. Then the **31 voices as headshot cards**: 3:4 cards, 3 per row on phones (horizontal rails per group: FEMALE, MALE) and a 6-column grid on desktop. Each card: a monogram of the voice's first letter in Mona Sans 64 px over a radial gradient in the voice's own hue (31 hues spaced 360 / 31 ≈ 11.6° apart, L 0.22 glow → `#000`), the name in `heading-card`, a timbre tag in `caption` ink-3 ("warm · low"), and an IB1 Play "Hear intro" that plays the voice introducing itself (`GET /novels/voices/sample`). While a sample plays, the card's bloom pulses with the audio level (RMS mapped to bloom opacity .2–.6) and a 2 px accent progress line runs along the card's bottom. The currently chosen voice has a 2 px ink ring and a Check. Rows "Default voice" and "Automatic voice" sit above the grid as B2 buttons. B1 "Use Aria for Lady Seren" appears in a bottom bar once a different voice is focused.
- States: loading (card frames with names as title cards), no voices installed ("No voices are installed on the server, so characters can't be cast yet."), sample unavailable ("No preview"), saving (bottom bar B1 Loading), save failed (toast "That voice couldn't be saved.").

#### 4.17.5 Audiobook sheet (from the book page)

`full` sheet: header "AUDIOBOOK" + B3 "Close"; T4 "Narrate · Save to device" (the second only when rendering and downloads are possible); an unavailable note when narration of new chapters is off; text chips NEXT 10 · ALL UN-NARRATED (N) · NONE; chapter rows with T2 checkboxes and subtitles ("Already narrated · saved on this device", "Download the text first", "Not narrated yet"); an estimate `caption` ("About 36 minutes of rendering on the PC."); B1 "Make audiobook of 4 chapters" / "Save audio of 4 chapters"; job status polled with a row-level leader sweep; toasts ("Queued 4 chapters for narration. Skipped 2 already narrated.").

### 4.18 Library

The Library tab holds everything the profile owns, in slate tabs: SHELF · DOWNLOADS · COLLECTIONS · HISTORY · BOOKMARKS. The tab is remembered per profile.

**Shelf, desktop.** TB2 title "LIBRARY" with the content-mode slates beside it. A **featured strip** at the top: the most recently read series as a 2.39:1 band 320 px tall (art, title treatment at `display-title` 48 px, B1 Continue); then the toolbar: status text chips (ALL · READING · PLAN TO READ · ON HOLD · COMPLETED · DROPPED · FAVOURITES · NEW), SF2 "Search your library" (`/`), sort M1 ("RECENTLY READ", "RECENTLY UPDATED", "TITLE", "RECENTLY ADDED", "MY ORDER"), B3 "Select". Then a **Captioned** poster grid (6–8 columns). In "MY ORDER" sort, posters can be dragged to reorder (Motion `Reorder` grid on web; `flutter_reorderable_grid_view` 5.7.0), with a keyboard alternative (`Alt+↑/↓/←/→` moves the focused poster) and a menu alternative ("Move to start" / "Move to end").

**Shelf, phone.** The featured strip becomes a 16:9 card; chips scroll horizontally; 3-column captioned grid; select mode via long-press on a poster (haptic `poster.longpress` once, then taps toggle; a bottom bar rises with Favourite, Status, Add to collection, Download next 10, Remove).

**Browse all** (`/library/all`, desktop rail "Library" long form, phone via "See all" on the shelf): the same grid without the featured strip, with advanced filters in a side panel (desktop) or `half` sheet (phone): source (multi), format, status, favourites only, has new chapters, downloaded, 18+ (gate open only).

**Key light.** The poster under focus or hover after 450 ms; otherwise the featured series.

**Signature moment.** Removing a series is **cut out of the film**: the poster desaturates to grey and drops to 0 opacity over 280 ms `cine-in` while its neighbours close the gap (a 360 ms `cine-out` layout move); the toast "Removed Solo Leveling from your library." offers Undo (restores follow, favourite, status, notify, override and the shelf position).

**Transitions.** Tab entry: dip to black. Slate tab change: dip to black within the page. Poster → detail: match cut.

**States.** Loading (captioned frames); content; empty library ("Your shelf is empty." + B1 "Browse sources" + B3 "Ask for something to read"); empty filter ("Nothing is on hold."); search no match; offline (the shelf from cache with non-downloaded posters at 60 % and a `caution` line; tapping one shows the toast "Needs a connection"); error; bulk action partial failure ("Removed 11 of 12. One couldn't be removed.").

**Keys (web).** `/` search, grid arrows and `h j k l`, `Enter` open, `Space` preview, `x` select the focused poster, `mod+a` select all in select mode, `Delete` remove selected (confirm), `f` favourite, `1`–`5` switch slate tabs.

### 4.19 Collections and collection detail

**Collections tab.** A grid of C4 collection tiles (16:9, 3 per row at 1440 px, 1 per row on phones at full width minus gutters). The first tile is "NEW COLLECTION" (a 16:9 frame with a dashed `hair-strong` edge and a Plus). Smart collections (§5.3 and the AUTO badge) and shared collections (Circle glyph) sit in the same grid, sorted by the user's order (drag to reorder, with keyboard and menu alternatives). Sort M1: My order, Name, Recently changed.

**New / edit collection**: a dialog with IN1 "Name", IN3 "Description" (optional), T4 "Manual · Smart"; Smart reveals rule rows (M1 selectors: "Status is Reading", "Favourite", "Has new chapters", "Format is Manhwa", "Unfinished", "Source is Asura"), joined by "all of" / "any of"; T1 "Share with your Circle" (§5.3). B1 "Create" / "Save".

**Collection detail.** A header band: the three member covers fanned as in C4 but 2.39:1 wide across the page top with `blur-fill` behind, the collection name in `display-title`, description in `body-lg` ink-2, `timecode` "12 SERIES · 4 WITH NEW CHAPTERS", owner avatars when shared, and actions B2 "Add series", IB2 Pencil, IB2 DotsThree (Delete collection, Leave shared collection, Stop sharing). Below: a Captioned grid of members (drag to reorder in manual collections; removing uses the swipe on phones or the context menu). "Add series" opens a `full` sheet: SF2 over the library, a captioned grid with checkboxes, B1 "Add 3".

**Signature moment.** Adding a series to a collection from anywhere sends its poster on a short arc into a 16 px collection glyph in the toast ("Added to Rainy day reads."), 420 ms `cine-in-out`, so the move is seen.

**States.** Loading, content, empty collections ("No collections yet." + B1 "New collection"), empty collection ("This collection is empty." + B1 "Add series"), smart collection with no matches ("Nothing matches these rules yet."), delete confirm, remove-from-collection confirm (manual collections), offline (read-only, edit controls disabled), error.

**Keys (web).** Grid navigation, `n` new collection, `e` edit, `a` add series, `Delete` remove selected member.

### 4.20 History

**Layout.** Grouped by day (TODAY, YESTERDAY, then "MON 22 SEP") with `eyebrow` headers; each entry an L1 row with a 40 × 60 thumb, series title, `timecode` "CH 142 · PAGE 18 / 64" or "CH 212 · 42 %" for novels, relative time, and a trailing IB2 Play (resume). A T4 at the top switches **"By series · By chapter"** (`collapse=series` or `none`). Desktop adds a right-hand **key-light column**: the hovered row's cover as a 2:3 panel 360 px tall with the title treatment, so hovering down the list re-lights the page one book at a time.

**Signature moment.** Scrolling back through history dissolves the page's key light from one cover to the next as each day header passes the 30 % line, like flipping through a reel.

**Gestures.** Swipe left removes an entry from history on phones (this hides the row client-side; progress is kept); tap resumes; long-press → M2 sheet (Resume, Go to series, Download chapter).

**States.** Loading, content, empty ("You haven't read anything yet." + B1 "Go home"), offline (from cache, rows needing the network at 60 %), error, end of history ("That's everything.").

**Keys (web).** `j` / `k` move, `Enter` resume, `s` open series, `1` / `2` switch grouping.

### 4.21 Bookmarks

**Layout.** Grouped by series (a series header row with a 40 × 60 thumb and the title in `heading-card`), each bookmark an L1 row: for manga a 16:9 crop of the bookmarked page at 72 % brightness (`r-hair`), `timecode` "CH 14 · PAGE 9 · 62 %", the note in Instrument Serif italic 15 px ink-2 when present, relative time; for novels the 180-character snippet in Instrument Serif 16 px ink-2 inside quotation marks, `timecode` "CH 212 · 42 %". Filter text chips: ALL · MANGA · NOVELS (in the matching content mode only the current kind shows). Trailing IB2 Pencil (edit note) and IB2 Trash.

**Signature moment.** Opening a bookmark performs a **jump cut**: the page crop scales to fill the screen (match cut into the reader's page at the exact anchor), with no curtain, landing on the bookmarked spot.

**Gestures.** Swipe left to delete (with Undo); tap opens at the anchor; long-press → edit note.

**States.** Loading, content, empty ("No bookmarks yet. Press B while reading." on desktop, "Tap the bookmark while reading." on phones), stale anchor (the row shows a `caution` `timecode` "CHAPTER CHANGED"; opening shows the stale-anchor toast), offline (opens downloaded ones; others at 60 %), sync pending (a CloudArrowUp 14 px `caution` glyph on rows waiting in the outbox), error, `bookmark_deleted` conflict (toast "That bookmark was deleted on another device.").

**Keys (web).** `j` / `k`, `Enter` open, `e` edit note, `Delete` delete.

### 4.22 Updates

**Layout, desktop.** TB2 title "UPDATES" with `timecode` "LAST CHECKED 12 MIN AGO" and B2 "Check now" (Loading while a run is active; `check_already_running` shows "Already checking…"). Slate tabs: NEW · ALL. Text chips for source filter. The list groups notifications by series: a **series band** per series with 3 or more new chapters (a 2.39:1 strip 160 px tall with the cover cropped, title treatment at `heading-section`, `timecode` "3 NEW · CH 141–143", B1 `sm` "Read Ch. 141", B3 "Mark read"), and compact L1 rows for single chapters ("New Ch 142 of Omniscient Reader", thumb, relative time, unread 6 px accent dot). B3 "Mark all read" at the top (scoped to the content mode). Admin sees a collapsible "RUNS" section at the bottom with the last 20 runs (status, series checked, new chapters found, duration, error line).

**Layout, phone.** TB2 title; tabs; bands at 16:9; rows; pull to refresh runs a check.

**Signature moment.** When a check finds new chapters while the screen is open, new rows **roll in like a credit crawl**: they slide up from 24 px below the list's top edge with a 60 ms stagger, and the page's key light dissolves to the newest series.

**Gestures.** Swipe a row left to mark read, right to mark unread; long-press → M2 (Read, Go to series, Mark read, Turn off notifications for this series).

**States.** Loading, content, caught up ("You're caught up." in `editorial-md` + `caption` "We checked 214 series 12 minutes ago."), checking (a 2 px indeterminate accent bar under the header), check failed ("The last check failed at 09:14." `rating` line with Retry), offline (cached notifications, Check now disabled), rate limited, error.

**Keys (web).** `j` / `k`, `Enter` read, `e` mark read, `u` mark unread, `shift+e` mark all read, `r` check now, `1` / `2` tabs.

### 4.23 Downloads and Storage

**Downloads tab (Library → DOWNLOADS, alias `/downloads`).**
1. **Now downloading** (only while a queue exists): a band per active series with the cover thumb, `timecode` "CH 41 · 18 / 64 PAGES", an accent progress bar, IB2 Pause / Play, IB2 X (cancel); the queue summary "4 QUEUED · 1 FAILED" with B3 "Retry failed" and B3 "Cancel all" (confirm dialog). A `caution` line when paused: "Paused — the device is under the 1.5 GB free-space floor." or on iOS "Keep the app open — downloads pause in the background."
2. **On this device**: series groups (a Captioned poster at 72 px wide, title, `timecode` "12 CHAPTERS · 318 MB", a PushPin toggle "Keep" (never evicted), and a CaretDown to expand its chapters as L2 rows with sizes and the download control). Sort M1: Recently read, Size, Title.
3. **Sticky storage footer**: a 4 px segmented bar (other `ink-4`, ours accent, free `n-400`) and `timecode` "4.1 GB OF 10 GB CAP · 21 GB FREE", B3 "Manage storage".
4. Select mode (B3 "Select" or long-press): checkboxes on chapter and series rows, bottom bar with "Remove" (confirm), "Keep", "Mark read".
5. Per chapter on phones: IB2 `mm-xray` "Extract text" when OCR is available (runs on-device OCR for that chapter, with a ring progress, then uploads; states: extracting, uploaded ✓, failed).

**Save to Files** (iOS and Android, from a downloaded series' overflow "Save to Files"): a `half` sheet choosing chapters (T2) and format T4 "Images · CBZ", then the system file picker; a progress sheet with a 4 px bar and `timecode` "CH 12 · 18 / 64"; result dialog "Saved 12 chapters to Files." or "Couldn't save 2 chapters." with B3 "Show which".

**Storage** (`/settings/storage`): C2 info cards for "USED 4.1 GB", "CAP 10 GB", "FREE ON DEVICE 21 GB"; T4 cap "2 GB · 5 GB · 10 GB · 20 GB · Unlimited"; T4 "Delete read chapters after 24 h · 48 h · 7 days · Never"; a per-series breakdown list with sizes and a Trash; B2 "Free up space" (removes read, unpinned chapters; shows "Freed 1.2 GB" toast); "Manage in Files" (iOS) or "Choose folder" (Android) as B3; the free-space floor explained in `caption` ink-3.

**Web.** Downloads are service-worker saves: the same screen minus OCR and the folder picker; the storage card shows the browser's estimate ("Browser storage: 2.3 GB of 12 GB available to this site").

**Signature moment.** When a chapter finishes, its row's ring closes and the Check lands with the **reel-lock** haptic and a 480 ms `positive` underglow that fades along the row.

**States.** Nothing downloaded ("Nothing on this device yet." + `body` "Download chapters from any series page to read them offline." + B2 "Open library"); queue running; paused (backgrounded / storage floor / offline); failed items; offline (the whole tab works); error reading the store (title card "Couldn't read this device's downloads." + Retry).

**Keys (web).** `j` / `k`, `Enter` open or expand, `Space` pause / resume the focused item, `Delete` remove (confirm), `x` select.

### 4.24 Dialogue search (OCR) and X-Ray

**Screen (`/xray`, manga mode only, only when the server and device support OCR).** TB2 title "X-RAY" with `caption` ink-3 "Search the words inside chapters you've extracted." SF1 at the top (350 ms debounce, Enter searches). Results render as **subtitle lines**: each hit is a 16:9 crop of the page region around the bubble (from the stored page and the match's box when present, otherwise the page top) at 80 % brightness with the matched line laid over its lower third as a subtitle (`body-strong` ink with a 4 px black text shadow, matched words in `key.accent`), then `timecode` ink-3 "OMNISCIENT READER · CH 88 · PAGE 14". Tapping opens the reader at that chapter and page; when a panel box is known, the reader pulses a 2 px accent frame around the bubble twice (480 ms each).

**X-Ray panel (desktop reader).** The same search scoped to the series, as the right side panel (§4.14.2), with results for the current chapter first.

**States.** Idle ("Search chapter dialogue." title card + body "Finds words inside chapters whose text has been extracted, across the series you follow."), searching, no matches ("No matches." + `caption` "Only chapters with extracted text can be searched. Extract text from Downloads."), error ("Search failed — check your connection."), unavailable (the screen and panel are not rendered at all).

**Keys (web).** `/` focus, `j` / `k` move, `Enter` open.

### 4.25 You (the hub)

**Layout, phone (tab 5).** A header: the profile's 96 px avatar colourway with its mood bloom, the profile name in `display-page`, `timecode` "@yeahiamyash · ADMIN" (the account), and B2 `sm` "Switch profile". Then a **streak strip** (§5.2: flame, current and longest, a 14-day dot row) linking to Stats. Then grouped L3 rows:
- READING: Updates (unread badge), For you, Circle (new activity badge), Stats, Collections, History, Bookmarks, X-Ray (manga mode, when available).
- DEVICE: Downloads (queue badge), Storage.
- APP: Settings, What's new, Keyboard shortcuts (hardware keyboard attached only), About.
- ADMIN (admins only): System status, Members, Backup and restore.
- A footer: B3 "Sign out" and `timecode` "V4.0.0 (BUILD 61) · CINEMATIC".
- On Android, when `GET /app/version` reports a newer build, an update band sits at the top: "Version 4.0.1 is ready." + B1 `sm` "Install" (confirm dialog explaining the Android installer prompt). On iOS the band reads "A new build is on SideStore." + B3 "How to update".

**Desktop.** There is no You tab; the rail's footer and the account menu (avatar in the top strip: name, @username, ADMIN badge, Switch profile, Manage profiles, Settings, Sign out) cover it. `/you` on desktop renders the same page as a centred 720 px column for deep links.

**Signature moment.** The header's avatar bloom breathes with the streak: when today's chapter is done, the bloom is tungsten-warm; when the streak is at risk (after 20:00 with no reading today), it cools to `ink-3` and the flame in the strip flickers at 0.5 Hz.

**States.** Loading (header renders from the cached profile; badges appear when counts arrive), offline (network rows at 60 %, Downloads highlighted), error on counts (badges absent).

### 4.26 Settings

**Layout, desktop.** Two panes: a 280 px category column (L3 rows with glyphs; the selected row has the rail's accent bar) and the panel on the right, max 720 px. A SF2 "Search settings" at the top of the category column filters rows across all panels (matched labels highlighted in accent; Enter jumps to the first hit and pulses its row's `key.wash` twice). **Phone:** a category list with full-bleed `eyebrow` section headers; each category pushes its panel.

Categories and every control:

1. **Account**: display name (IN1), username (read-only), B2 "Change password" → a panel with IN2 Current, New (strength bar), Confirm, B1 "Change password"; **Sessions**: L1 rows per session (device, browser or app, last seen, "This device" tag), IB2 SignOut per row ("Sign out this device" confirm), B4 "Sign out everywhere" (confirm); B3 "Sign out".
2. **Profiles**: Manage profiles (§4.6), the active profile row, B2 "Switch profile".
3. **Appearance**:
   - **Skin**: two live preview tiles side by side (desktop 320 × 200, phone full width stacked 16:10): each is a real miniature of that skin's Home (a scaled-down render of the actual Home screen components at 0.25 scale with live Ken Burns for Cinematic and the other skin's own motion for Glass), labelled `heading-section` "CINEMATIC" / "GLASS" with a one-line description ("Dark theatre. Art and titles." / "Layered glass. Depth and springs."). The current one has a 2 px ink ring and "IN USE". Tapping the other opens the **confirm sheet** (§4.26.1).
   - **Motion**: read-only line "Follows your system's reduced-motion setting." with a status (On / Off).
   - **Ambient colour**: T1 "Light the page from the art" (default on; off keeps `house` roles everywhere, for readers who want the UI perfectly neutral).
   - **Hero**: T1 "Auto-advance the spotlight" (default on), T1 "Film grain" (default on).
4. **Reading**: defaults for new series: manga mode, direction, fit, strip width, tap zones; novel defaults: face, size, line height, measure, paper, page mode, turn style; T1 "Auto-next chapter"; T1 "Keep screen on while reading"; T1 "Volume keys turn pages" (Android); T4 refresh rate (Android); B3 "Reset reader settings" (confirm).
5. **Listening**: default narration speed (S3 compact), default sleep timer, T1 "Lock-screen controls", T1 "Pause when headphones disconnect".
6. **Content**: T1 "18+ content" for this profile (gate dialog), content mode default (T4 "Manga · Novels", when novels are enabled), per-source hidden list (L1 rows with toggles).
7. **Notifications**: per-profile "Notify for new chapters" default; admin-only instance section: T1 "Check for updates automatically", IN4 interval (5–1440 min), T1 "Check on server start", T1 "Notify", `timecode` "LAST RUN 09:14", B2 "Run now".
8. **Feedback**: T1 "Haptic feedback" (default on, mobile only), T1 "Interface sounds" (default off), S1 "Sound volume" (visible when on), B3 "Play a sample" (plays `ui.select` then `ui.stamp`).
9. **Social**: T1 "Share my activity with my Circle" (default off per profile), T1 "Share what I react to", L1 list of who can see this profile's activity (accounts on this server, each with a T1), B3 "Clear my shared activity" (confirm). See §5.3.
10. **AI**: `caption` "Recommendations and recaps use an external AI service." status line ("Available · 42 asks left today" or "Not configured on this server"), T1 "Show 'Previously on' recaps", T1 "Personalised home rails".
11. **Storage**: → §4.23.
12. **Shortcuts** (web, and mobile with a hardware keyboard): the live shortcut registry grouped (General, Navigation, Library, Search, Sources, Reader, Novel reader, Listen) with key caps; `caption` "Only what works right here is listed. Shortcuts pause while you type."
13. **Server** (mobile): the server URL (IN1, validated) with B2 "Change server" (signs out after confirm).
14. **Admin** (admins only): Members (§4.26.2), Backup and restore (§4.26.3), System status (→ §4.27).
15. **Diagnostics** (mobile, behind 7 taps on the version line in About): FPS meter, jank counter, display modes, device info, image cache size with B3 "Clear".
16. **Reading palette**: there is no colour-theme or accent picker in this skin; the novel paper choice lives in the novel reader and in Reading defaults.
17. **About**: the stacked wordmark, version and build, B2 "What's new" (the What's New sheet), open-source licences (a full list page styled with L1 rows, not the stock licence page), the SideStore card (iOS) or APK update card (Android).

Every row: states from L3 and the control's own states. Server-backed toggles are optimistic and revert on failure with a toast.

#### 4.26.1 Skin switch flow

1. Tap the Glass preview. The **confirm sheet** rises (`half`): title `editorial-md` "Restart into Glass?", body "Everything changes: layout, motion, navigation and the look of every screen. Your library, progress and downloads stay exactly as they are." When the download queue is not empty, a `caution` line: "Downloads will resume after the restart." Buttons: B1 "Restart into Glass", B2 "Stay in Cinematic".
2. Confirm: haptic `skin.confirm`; the sheet falls; **"House lights down"**: every element on screen dims to black in reading order over 500 ms `cine-in` (a 12 ms per-element stagger down the page), the stacked wordmark fades up in the centre, holds 300 ms, and its gutter bar light goes out.
3. Persist: `PATCH /profiles/{id} {skin: "glass"}` (queued in the outbox if offline), then the device mirror (`mm-skin` cookie on web; SharedPreferences `mm.skin.active` on mobile), then the return route (`mm.skin.return`).
4. Restart: web `location.replace(returnPath)`; mobile `AppRestart.restart()`.
5. Glass's own splash and reveal play, landing on Settings → Appearance in Glass, where Glass shows its 10 s undo toast.
Budget from confirm to the Glass splash: under 1.5 s. Reduced motion: a 200 ms fade to black replaces step 2.

The incoming direction (Glass → Cinematic) lands on Settings → Appearance in this skin with the subtitle toast "Switched to Cinematic." + action "Undo" and a 10 s accent countdown line; Undo runs the same flow back.

#### 4.26.2 Members (admin)

L1 rows per account: avatar initial, username, display name, role badge (ADMIN), status (Active / Disabled), last seen, profile count; actions in M1: Reset password (shows a one-time password in Geist Mono with a Copy button), Disable / Enable, Make admin / Remove admin, Delete (confirm: "Delete @theo? Their profiles, library and progress are deleted."). `cannot_manage_self` rows have their menu disabled with a tooltip "You can't change your own account here." Registration mode summary line ("Sign-ups: open") as `caption`. States: loading, content, error, action failures as toasts.

#### 4.26.3 Backup and restore (admin)

C2 cards: "LAST NIGHTLY BACKUP · 03:12 · OK · 184 MB" (`positive` dot) or "UNKNOWN" (`caution`, never shown as healthy) or "FAILED at phase 'copy'" (`rating`). B2 "Download backup" (T2 "Include caches" beside it); B2 "Restore from file" → file picker → confirm dialog ("Stage this restore? It applies on the next server start. The current database is kept as a copy.") → staged state banner ("A restore is staged. Restart the server to apply it." + B4 "Cancel staged restore"). States: uploading (progress bar), staged, cancel confirm, errors.

### 4.27 System status (admin)

**Layout.** TB2 title "SYSTEM". A top band of C2 cards: BACKEND ("Online · v4.0.0"), UPDATE CHECKER ("Every 60 min · last run 09:14"), BACKUP (as above), SOURCES ("22 healthy · 2 slow · 1 down"). Then "RECENT RUNS" (L1 rows with status dot, trigger, series checked, new chapters, duration; tap expands the error text in Geist Mono) and "SOURCE HEALTH" (L1 rows sorted worst first: source mark, name, health dot, last success, failure count, error sample in Geist Mono `caption`). B2 "Run check now".

**Signature moment.** The SOURCES card's three numbers count up on load, and a down source's row carries a slow 2 s `rating` underglow pulse.

**States.** Loading, content, backend unreachable (title card), `forbidden` for non-admins (the route is absent from navigation; a direct URL shows the 404 title card).

**Keys (web).** `r` refresh, `j` / `k` move.

### 4.28 Status screens

| Screen | Composition | Actions |
|---|---|---|
| **404** (inside the app frame) | A black stage; `numeral-xl` "404" as an outline numeral (stroke 2 px `ink-4`); under it `editorial-md` "Nothing here." (typing reveal); `body` ink-2 "This page doesn't exist. It may have been renamed, or its series removed from your library."; `caption` ink-3 "Press Ctrl K to search everything." (desktop) | B1 "Go home", B2 "Open library" |
| **Route error** | Eyebrow "SOMETHING BROKE" in `rating`; `editorial-md` "This screen failed to render."; body "Nothing was lost. Trying again usually works."; a `timecode` reference chip | B1 "Try again", B3 "Go home" |
| **Server unreachable** (route error with no response) | Eyebrow "NO SIGNAL" in `caution`; `editorial-md` "Can't reach the server."; body "It may still be starting, or the connection dropped. Your library is untouched." | B1 "Try again", B2 "Open downloads" |
| **Root error** (own document, system fonts only) | `#000` page, the stacked wordmark as inline SVG, "ManhwaManiacs failed to start." in 28 px system serif, body in system sans | "Try again", "Reload the app" |
| **Offline fallback** (static HTML served by the service worker) | Inline-styled standalone page in this skin: wordmark SVG, a status line with a dot ("NO CONNECTION" `caution` / "BACK ONLINE" `positive`, live via the `online` event), `editorial-md` "This page needs the server.", body "Chapters you saved for offline reading are still on this device and open as normal." | "Try again", "Open downloads" |
| **Reader landing** | §4.14.7 | |

The offline fallback page and the root error are the only screens that cannot use the skin's CSS bundle, so their styles are inlined (≈ 3 KB) and generated from the same token JSON by `design/build.mjs`.

### 4.29 Global overlays

- **Command palette**: §3.28.
- **Keyboard shortcuts overlay** (`?`): a dialog 640 px wide, `editorial-md` title "Keyboard shortcuts", intro `caption` "Only what works right here is listed. Shortcuts pause while you type. Press ? anywhere to reopen this.", then groups in `eyebrow` headers with rows (description + key caps; secondary combos at 80 %). Empty: "No shortcuts are active on this screen."
- **Account menu** (desktop avatar): M1 with a header (avatar 40 px, display name, @username, email, ADMIN badge), items Switch profile, Manage profiles, Settings, What's new, Sign out ("Signing out…" while pending).
- **What's new sheet**: shown once after an update and from About. `full` sheet (phone) or 640 px dialog (desktop): `editorial-lg` "What's new", then release entries: version in Mona Sans `display-page` ("4.0.0"), "LATEST" `micro` badge on the first, `timecode` date and build, highlights as a list with 6 px accent squares as bullets. States: loading, "Release notes unavailable." (offline or error).
- **Content-mode sheet** (phones, from a top-bar slate long-press): `peek` sheet explaining "One setting for the whole app. Your library, sources, search, downloads and updates all show what you pick." with T4 "Manga · Novels".
- **Profile switcher** (desktop top strip avatar long-press or `mod+shift+p`): a compact M1 listing profiles with their avatars; picking one runs the Spotlight exit and loads the profile (and restarts into its skin when it differs).

---

## 5. The four new features

All four are server-first so both skins and both clients render the same data (stack decision §2.6). Every payload below is scoped to `(user_id, profile_id)` through `X-Profile-Id`, and every list applies the 18+ gate when serving.

### 5.1 AI home, recommendations and "Previously on"

#### 5.1.1 Data the design needs

| Endpoint | Status | Returns |
|---|---|---|
| `GET /home?content_kind=` | New | `{headline, spotlight: [SeriesRef ×5], sections: [{id, kind: continue|recap|new|circle|for_you|because|top10|downloads|source|popular, title, reason, seed?, items, state: ready|loading|empty|unavailable}]}`. The server composes continue-reading, recently-updated, world recommendations, pins and statistics; AI-dependent sections carry `state: unavailable` instead of failing the page. |
| `GET /library/world/recommendations` | Built | For you + Because you read X |
| `GET /library/similar?source_id=&series_key=` | New | Similar series for a seed series (AI-ranked from AniList relations and genres), each with `why` |
| `POST /library/recommendations/feedback` | New | `{source_id, series_key | anilist_id, verdict: not_interested|more_like_this}` |
| `GET /library/suggest/availability`, `POST /library/suggest`, `POST /library/world/suggest` | Built | The Ask box |
| `GET /recap?source_id=&series_key=&upto_chapter_key=` | New | `{state: ready|generating|unavailable, reason?, title, chapters_covered: "1–141", paragraphs: [str], characters: [{name, line}], last_scene: {chapter_key, page_url?}, generated_at}`; built from OCR text of chapters the profile has read (manga) or the chapter text (novels), never past the profile's furthest read chapter |

#### 5.1.2 Home AI rails

On Home (§4.8), AI sections render as rails:
- **FOR YOU** (Wall posters with the `why` line revealed in the preview slate and Quick Look), titled with the per-letter reveal.
- **BECAUSE YOU READ SOLO LEVELING**: the header's series name is set in `key.accent` of that seed series, and a 1 px `key.wash` underlight runs under the header. The rail's first slot is the seed's own poster at 70 % brightness with a small "BECAUSE" `micro` badge, so the reason is visible, not only written.
- **MORE LIKE THIS** on series detail (§4.12, tab 2).
- **Headline**: the home feed's `headline` string typed at 50 ms per character. When AI is available, the server may phrase it ("TONIGHT: THE FINAL ARC OF NANO MACHINE"); otherwise it falls back to data-only phrasing ("3 NEW CHAPTERS SINCE YESTERDAY").

Each AI poster's context menu adds "More like this" and "Not interested"; Not interested removes the poster with the cut-out animation and posts feedback; toast "We'll show fewer like this." + Undo.

**States (per rail).**

| State | Visual |
|---|---|
| Loading | Header renders and reveals; posters are loading frames; after 1 s the header gets a trailing 16 px leader sweep |
| Ready | Posters |
| Empty (new profile, no seeds) | The rail is omitted; Home shows popular rails instead |
| Unavailable: not configured | Omitted from Home; For you shows the title card below |
| Unavailable: budget exhausted | Omitted from Home; For you shows "Asks are used up for today." |
| World catalogue unreachable, cache served | Rail renders with an `OFFLINE COPY · YESTERDAY` badge after the header |
| Rate limited | Rail error line "The recommendation service asked us to wait. Retrying in 30 s." |

#### 5.1.3 For you (`/for-you`)

Entry points: Home hero overflow "Ask for something", the rail "See all" on FOR YOU, the desktop rail's Sparkle, You → For you, Search's no-results "Ask for something like it", `g f`.

**Layout, desktop.** A takeover-like page on black with the key light of the top result.
1. **The ask**: centred at the top, `typed-headline` "WHAT DO YOU FEEL LIKE READING?" (typing reveal), then an IN3 prompt area styled as SF1 (no box, a 2 px accent underline when focused, Geist 24 px), 3–600 characters, with the counter; below it `caption` ink-3 "42 asks left today · uses an external AI service" and a T4 "From my sources · From everywhere" (`/library/suggest` vs `/library/world/suggest`). Suggested prompts as removable-style tags underneath ("Short and finished", "Revenge, no romance", "Like Omniscient Reader but a novel"). Enter submits; Shift+Enter adds a line.
2. **Answers**: results appear as a grid of C5 world cards (available: opens the series; info: opens an info sheet with "Search my sources"), each with its `why` line in Instrument Serif italic. The first result is promoted to a **mini hero** band (2.39:1, 320 px) with the title treatment and the `why` line typed at 50 ms per character.
3. **For you** and **Because you read** rails below the answers (the same as Home, full length).
4. **Your genres**: a text-chip row of genre affinities from `/library/recommendations`, each linking to a filtered source catalogue.

**Layout, phone.** The same order in one column; the prompt area pinned under TB1 while typing; results in a 2-column grid.

**Signature moment.** While the answer is being generated, the prompt text lifts 24 px and dims to ink-3, a single `house` caret blinks where the answer will start, and results arrive one by one, each rack-focusing in while the page's key light dissolves to the newest arrival.

**States.**

| State | Visual and copy |
|---|---|
| Idle | The ask and the rails |
| Submitting | Prompt dims; leader sweep after 1 s; "Thinking about 2,400 series on your sources…" in `caption` (world mode: "Checking the wider catalogue…") |
| Results | Grid |
| No matches (`ai_no_matches`) | Title card "Nothing fits that yet." + body "Try naming a series you liked, or loosen one detail." |
| Some dropped (`dropped > 0`) | `caption` ink-3 under the grid "2 suggestions weren't on your sources and were left out." |
| Budget exhausted | The ask is replaced by a title card "Asks are used up for today." + `caption` "They refresh at midnight. Recommendations below still work." |
| Not configured | Title card "AI isn't set up on this server." + `caption` "Rails based on your reading still work." (never red) |
| Library empty (`suggest_shelf_empty`) | Title card "Follow a few series first, so we know your taste." + B1 "Browse sources" |
| Rate limited | Toast "Too many asks at once. Try again in 20 s." with the submit button Disabled and counting down |
| Offline | The ask is Disabled with "Asking needs a connection."; cached rails show with the OFFLINE COPY badge |

**Keys (web).** `/` focus the ask, `Enter` submit, `mod+Enter` submit in world mode, grid navigation, `n` / `m` on a focused card: Not interested / More like this.

#### 5.1.4 "Previously on" recap

**Entry points.**
- Home hero B2 "Previously on" when the spotlight series was last read ≥ 7 days ago.
- A **PREVIOUSLY ON** rail on Home: 16:9 recap cards for series paused 7–90 days (the card shows the last-read page cropped at 60 % brightness with "PREVIOUSLY ON" `eyebrow` and the title in `heading-section`).
- Series detail B2 "Previously on".
- **Reader resume card**: when the reader opens a chapter of a series last read ≥ 7 days ago, before the first page, a slate offers "PREVIOUSLY ON {TITLE}" with B1 "Watch the recap" (20 s read) and B3 "Skip" (auto-dismiss after 6 s; it never blocks). Settings → AI can turn this off.
- Context menu on any followed series.

**Recap screen** (`/recap/:sourceId/:seriesKey`, a takeover): 
1. **Title card** (the film-opening): black; `eyebrow` "PREVIOUSLY ON" with the per-letter reveal; the series title in `editorial-lg` Instrument Serif below it; `timecode` ink-3 "CHAPTERS 1–141 · 2 MIN READ". Holds `hold-title` 1200 ms.
2. **The recap**: the cover takes the whole backdrop at 2.39:1 on desktop (4:5 on phones) with Ken Burns and a heavy scrim; paragraphs stream in over it with per-word fades (160 ms each, 30 ms apart), `body-lg` 19 px ink on the scrim, max 62 ch, left column. Character lines render as a list: name in `heading-card` `key.accent`, one line each in `body` ink-2.
3. **Last scene**: "WHERE YOU LEFT OFF" `eyebrow`, then the last-read page crop (16:9, `r-frame`) with `timecode` "CH 141 · PAGE 38".
4. **Actions** pinned at the bottom over `scrim-bottom`: B1 "Continue Ch. 142" (push-in into the reader), B3 "Back".
5. **Spoiler rule** shown as `caption` ink-3 at the end: "Only covers what you've read."

**States.**

| State | Visual |
|---|---|
| Loading | The title card holds; after 1 s the leader sweep appears under the title; the paragraphs stream as soon as tokens arrive |
| Generating (first request for this series and chapter) | The title card plus `caption` "Writing your recap… about 10 seconds." |
| Ready | As above |
| Unavailable (not configured, budget exhausted, no text: nothing extracted for these manga chapters) | A static slate: "RECAP UNAVAILABLE" in `heading-section` ink-3; body "Pick up where you left off — Chapter 142."; for manga with no extracted text also `caption` "Recaps need text from chapters you read. Extract text from Downloads."; B1 "Continue". Never red. |
| Offline | The cached recap if one exists (`OFFLINE COPY` badge), otherwise the unavailable slate |
| Error | The unavailable slate with B3 "Try again" |
| 18+ | Recaps of mature series exist only for profiles whose gate is open; otherwise the series is not reachable at all |

**Keys (web).** `Space` or `Enter` completes the streaming text instantly, `c` continue, `Esc` back.

### 5.2 Reading stats, streaks and Wrapped

#### 5.2.1 Data

`GET /library/statistics?days=&tz_offset_minutes=` (built) provides totals, the window, streak, daily, by-hour, by-source, by-series and recent sessions. Additions: `GET /library/statistics/genres?days=` (new; genre shares for the radar, from series genres weighted by seconds read) and `GET /library/statistics/wrapped?year=` (new; calendar-year boundaries plus firsts: first series of the year, longest session, biggest day, most re-read chapter, top genre shift from H1 to H2).

#### 5.2.2 Streak flame (a component used on Home, You, Stats and the desktop top strip)

- Drawing: the custom `mm-flame` glyph, 20 px in the top strip and 48 px on Stats, painted with a vertical gradient from `house` (core) to `#FF7A1A` (tips) and a bloom `0 0 18px rgba(255,181,71,.45)`; the count in Mona Sans `wght 900 wdth 75` beside it ("12").
- Idle: the flame flickers: scaleY 1 ↔ 1.04 and bloom opacity .4 ↔ .55 over 1800 ms `drift`, alternating.
- At risk (no reading today after 20:00 local): the flame desaturates to ink-3 and flickers at 0.5 Hz; tooltip / label "Read today to keep your 12-day streak."
- Extended (first chapter completed today): **Ignite**: the flame grows from 0.6 to 1.0 scale over 400 ms `cine-out` while the count rolls up by one (the old number slides up and out, the new slides up in, 280 ms), the bloom peaks at 90 % and settles; haptic `streak.extend`, sound `ui.ignite`. Shown as a toast-sized overlay at the top-centre if it happens inside the reader ("DAY 13") without interrupting reading.
- Broken: the flame is drawn as an ink-4 outline with the longest streak in `caption` ("Longest: 31 days").
- Hidden when the current streak is < 2 days (except on Stats).

#### 5.2.3 Stats screen (`/stats`)

Entry: You → Stats, the desktop rail, the streak flame anywhere, `g t`.

**Layout, desktop.**
1. **Header**: the key light of the period's top series; `display-page` "YOUR READING"; range slates 7 DAYS · 30 DAYS · 90 DAYS · 1 YEAR; B2 "Your {year} Wrapped" (visible all year; the Wrapped for the current year updates live; December adds a NEW badge).
2. **Streak band**: the 48 px flame, current and longest streaks in `numeral-xl` (current) and `display-page` (longest), and a 14-day dot row (8 px squares, `r-hair`: read = accent, not read = `n-300`, today outlined).
3. **Tiles row** (C7): TIME READ ("41 H"), CHAPTERS ("312"), PAGES ("18,420"), SERIES ("27"), SESSIONS ("190"), each counting up on first view.
4. **Chapters per day**: a 365-cell contribution heatmap for the 1-year range (7 rows × 53 columns of 12 px squares, 3 px gaps) or a bar chart for shorter ranges (bars 3 px wide square-ended in accent, day labels in `timecode`), with values on hover or focus ("MON 22 SEP · 7 CHAPTERS · 1 H 12 MIN"). Colour ramp for the heatmap: `n-300` (0), then accent at 25 / 50 / 75 / 100 % mixed into `#000`.
5. **Clock**: a 24-hour radial chart (24 wedges from the centre, length = seconds read, accent), the peak hour labelled ("YOU READ AT 23:00"), with the caption "Night reader" / "Morning reader" / "Lunch-break reader" chosen from the peak.
6. **Genre radar**: an 8-axis radar of the top 8 genres, 1 px `hair` rings at 25 / 50 / 75 / 100 %, the shape filled `key.accent` at 18 % with a 2 px `key.accent` edge; axis labels in `eyebrow` ink-2. Hover or focus on an axis shows the share ("ACTION · 34 %").
7. **Top series**: a Ranked poster rail (outline numerals) with `timecode` hours under each.
8. **Top sources**: L1 rows with a 3 px bar per source.
9. **Library shape**: a single segmented bar across the page by reading status (Reading, Completed, On hold, Dropped, Plan to read) with labels and counts.
10. **Recent sessions**: L1 rows (thumb, "CH 142 · 18 PAGES · 14 MIN", time), tapping resumes.
11. **Share** buttons (IB1 Share) on the streak band, tiles row, radar and top series: each exports that block as a stat card (§5.2.5).

**Layout, phone.** One column in the same order; the heatmap scrolls horizontally with the current week pinned at the right; the clock and radar at full width (320 px).

**Signature moment.** Switching the range is a cut: numbers roll to their new values (a vertical digit roll, 480 ms `cine-out`) and the heatmap re-fills column by column from left to right (8 ms per column).

**States.** Loading (tiles as `n-200` bars flickering, charts as `hair` outlines), content, not enough data (< 3 sessions: "Read a few chapters and your stats start here." + the streak band), offline (the last cached stats with the OFFLINE COPY badge), error.

**Keys (web).** `1`–`4` ranges, `w` Wrapped, `s` share the focused block, arrow keys over the heatmap and charts (each cell and wedge is focusable and announced).

#### 5.2.4 Wrapped (`/stats/wrapped/:year`)

A takeover in **scenes**, each inside a 2.39:1 matte on desktop (letterbox bars top and bottom) and full-bleed 9:16 on phones. Scenes advance on tap (right 70 % of the screen), `→` or `Space`; back with the left 30 % or `←`; hold to pause; a 2 px segmented progress strip at the top (one segment per scene, 7 s each, auto-advancing). Every scene's key light is its subject's cover; scene transitions are dissolves (800 ms) or, between chapters of the story, a dip to black.

| # | Scene | Composition |
|---|---|---|
| 1 | Title | `eyebrow` "MIRA'S" / `display-hero` "2026" with the per-letter reveal / `editorial-md` "A year in pictures and pages." / grain peaks 0.12 then settles |
| 2 | Time | `numeral-xl` "412" counting up + "HOURS" `heading-section`; line typed at 50 ms/char: "That's 17 days of reading." |
| 3 | Chapters | "6,204 CHAPTERS" with a fast vertical scroll of the year's chapter thumbnails behind it (a blurred reel at brightness .3) |
| 4 | Top series | The #1 cover full-bleed with Ken Burns, title treatment, "132 HOURS" `timecode`; then #2–#5 as a Ranked rail sliding in |
| 5 | Genre radar | The radar drawing its edge clockwise over 1200 ms; the top genre named in `display-title` |
| 6 | Clock | The 24-hour chart; "YOU'RE A NIGHT READER" typed |
| 7 | Streak | The flame igniting, "LONGEST STREAK · 31 DAYS", the day it began |
| 8 | Firsts | Three quick cards: first series of the year, biggest day ("14 CHAPTERS ON 3 MARCH"), most re-read chapter |
| 9 | Circle (only if sharing is on for both sides) | "YOU AND THEO BOTH READ 9 SERIES" with the overlapping covers |
| 10 | Share | A grid of the six stat cards as thumbnails; tap one to open the share sheet; B1 "Share all" (exports six PNGs) and B2 "Done" |

Sound (when on): a soft `ui.swap` swell on each scene change; no music. Haptic `streak.extend` on scene 7 only. Reduced motion: scenes crossfade 200 ms; counts show final values.

States: generating (scene 1 holds with the leader sweep and "Rolling the credits…"), not enough data ("Your year starts with your first chapter." + B2 "Back"), offline (built from the cached year totals if present; otherwise the offline title card), error.

#### 5.2.5 Shareable stat cards (image export)

- Format: 1080 × 1920 PNG (9:16), plus 1080 × 1080 for the tile and radar blocks.
- Composition: `#000` ground; the subject's cover as a full-bleed blurred backdrop (`blur-fill`) with the vignette; the stat in Mona Sans (`numeral-xl` scaled to the card), a one-line caption in Geist, the profile's display name and avatar colourway, and the stacked wordmark 48 px tall bottom-left with its tungsten gutter bar. No usernames, server URL or 18+ covers appear on a card for which the profile's gate is closed; mature covers are replaced by the `key.tint` ground when the card would include them and the user has not ticked "Include 18+ covers" in the share sheet.
- Quote cards (from the novel reader): the quote in Instrument Serif 64 px, the book title and chapter in `timecode`, the cover's key light.
- Rendering: Flutter paints the card widget offscreen inside a `RepaintBoundary` at 1080 logical px width and calls `toImage(pixelRatio: 1)`; web draws the same layout with Canvas 2D on an `OffscreenCanvas` after `document.fonts.ready` (no DOM screenshot library).
- Sharing: iOS and Android via `share_plus` 10.1.4 (share sheet with the PNG file); web via `navigator.share({ files })` when supported, otherwise the PNG opens in a new tab for saving.
- Share sheet (in-app, `half`): the card preview at 40 % scale, T1 "Include 18+ covers" (only when relevant and the gate is open), B1 "Share", B2 "Save to photos" (mobile) / "Save image" (web), B3 "Send to Circle" (posts the card to the activity feed).
- States: rendering (preview frame with the leader sweep), ready, share cancelled (no toast), failed ("Couldn't make the image.").

### 5.3 Social for 2–3 users: "Circle"

#### 5.3.1 Model and privacy

- The Circle is **the other accounts on this server**. Sharing is **opt-in per profile**: Settings → Social → "Share my activity with my Circle" (default off). A profile that does not share never appears in anyone's feed and cannot receive recommendations or see reactions.
- A viewer sees an item only if (a) the sharing profile shares with the viewer's account, and (b) the item passes the **viewer's** active profile 18+ gate. A mature series read by Theo is simply absent for Mira's non-18+ profile; counts are computed after the gate.
- Profiles within the same account are separate people for the Circle: Theo's "Kid" profile and Theo's main profile are two Circle members, each with its own opt-in.
- Backend (new): `GET /circle/members`, `GET /circle/activity?before=&limit=`, `POST /circle/reactions {source_id, series_key, chapter_key, kind}`, `DELETE /circle/reactions/{id}`, `GET /circle/reactions?source_id=&series_key=&chapter_key=`, `POST /circle/recommendations {to_profile_id, source_id, series_key, note?}`, `GET /circle/recommendations/inbox`, `PATCH /circle/recommendations/{id} {state: seen|saved|dismissed}`, `POST /library/collections/{id}/share {profile_ids}`, `DELETE /library/collections/{id}/share/{profile_id}`, `GET /circle/settings`, `PUT /circle/settings`. Activity kinds: started, finished chapter (batched per series per day), finished series, followed, reacted, shared card, recommended.

#### 5.3.2 Circle feed (`/circle`)

Entry: You → Circle (badge for unseen items), desktop rail `mm-circle`, Home rail "YOUR CIRCLE IS READING", `g c`.

**Layout, desktop.** TB2 title "CIRCLE" with the members as 40 px avatars in a row beside it (each with a green `positive` dot when active in the last 15 minutes and, on hover, "Reading Omniscient Reader · Ch 212"). Slate tabs: ACTIVITY · FOR ME · SHARED. A two-column layout at ≥ 1280 px: the feed (720 px) and a right column with "READING NOW" (C1 continue-style cards for members currently mid-chapter).
- **Activity**: C6 activity cards in reverse time order, grouped by day. Batching: "Theo read 6 chapters of Nano Machine" is one card with a horizontal strip of the six chapter thumbnails.
- **For me** (the recommendation inbox): cards "**Mira** thinks you'll like **The Greatest Estate Developer**" with her optional note in Instrument Serif italic, the poster, B1 "Read Ch. 1", B2 "Add to library", B3 "Not for me". Seen / saved / dismissed states.
- **Shared**: C4 tiles for collections shared with this profile and by this profile.

**Layout, phone.** One column; members as a horizontal avatar row under the title; tabs; cards full width.

**Signature moment.** A member's avatar in the row **lights up** when they are reading right now: its bloom takes the key light of the series they have open, so the Circle row is literally lit by what everyone is reading.

**States.** Loading; content; nobody shares yet ("Your Circle is quiet." + body "When the others on this server share their reading, it shows up here." + B2 "Share mine" → Settings → Social); this profile does not share (a top band "You're not sharing. Others can't see your reading." + B3 "Share mine"); single-user server ("You're the only reader here." with no actions); offline (cached feed with OFFLINE COPY); error.

**Keys (web).** `1`–`3` tabs, `j` / `k` cards, `Enter` open, `r` react on the focused card, `s` save a recommendation.

#### 5.3.3 Reactions

- Five reactions, drawn as custom 24 px glyphs in the Phosphor Bold style with their names: **Wow** (a star burst), **Laugh** (Smiley), **Heart** (Heart), **Chills** (a snowflake), **Cliffhanger** (a falling arrow over an edge). One reaction per profile per chapter; tapping another replaces it; tapping the same removes it.
- **Where**: the reader's end-of-chapter credits (§4.14.4) as a row of IB1 buttons; the novel reader's chapter foot; the chapter row's context menu; activity cards.
- **Display**: next to a chapter in the series' chapter list, a stack of up to three 16 px avatars with the reaction glyph of the most recent; in the credits, "Mira ❘ Chills · Theo ❘ Wow" as avatar + glyph pairs.
- **Motion**: sending plays a 1.2× flash of the glyph (scale 1.2 → 1.0 over 160 ms `cine-out`) and a 480 ms bloom in `key.accent`; haptic `reaction.send`.
- **Spoiler guard**: a reaction on a chapter the viewer has not read yet shows only the avatar and "reacted to Ch. 212" without the glyph, until the viewer finishes that chapter.
- States: sending (glyph at 60 %), failed (reverts, toast "Reaction didn't send."), offline (queued in the outbox, glyph shows a 10 px CloudArrowUp).

#### 5.3.4 Recommend to

- Entry: series context menu "Recommend to…", series detail overflow, the credits' "Recommend this series" B3, Quick Look.
- Sheet (`half`): `editorial-md` "Recommend Omniscient Reader", the Circle members as 72 px avatar tiles (only those who share and whose gate admits this series; an 18+ series lists only members with the gate open), multi-select, an optional IN3 note (max 280 characters), B1 "Send".
- Sent: haptic `recommend.send`, toast "Sent to Theo."; the recipient sees a badge on Circle and a Home rail "FROM YOUR CIRCLE".
- States: no eligible members ("Nobody in your Circle can see this series."), sending, sent, failed, offline (queued).

#### 5.3.5 Shared collections

- In the collection form, T1 "Share with your Circle" reveals member tiles to pick. Shared members can view and add series (T4 per member "Can view · Can add"). The owner can rename, reorder and remove.
- A shared collection shows owner and member avatars on its tile and header; each series tile shows the avatar of who added it.
- 18+ rule: a mature series in a shared collection is invisible to members whose gate is closed, and the collection's count reflects what that member can see.
- States: invitation (the For me tab shows "Mira shared 'Rainy day reads' with you." + B1 "Open" + B3 "Hide"), left (the member can "Leave collection"; confirm), owner deleted it (the tile disappears; a toast on next open "Rainy day reads is no longer shared.").

### 5.4 Ambient reader extras

#### 5.4.1 Auto-scroll with speed control

- **Start**: the bottom chrome's `mm-autoscroll` button, `p`, or the reader settings toggle. Strip mode only (in Paged mode the same button becomes **auto-turn**: a page turn every N seconds, 4–30 s, with the same controls).
- **Speed**: 0.25× to 4×, step 0.25, where 1× = 60 px/s at 1× zoom; a per-series memory of the last speed. Linear motion (constant velocity, frame-time based so dropped frames never slow it).
- **HUD while running**: a floating chip bottom-right (above the micro progress): a 6 px `key.accent` dot pulsing at the scroll's cadence, "1.5×" in `timecode`, IB2 Pause. On desktop, hovering the chip shows a compact S1 speed slider; `<` / `>` change speed. On phones, a right-edge vertical swipe changes speed with a centred HUD "1.5×" in Mona Sans 56 px that fades after 700 ms; haptic `autoscroll.step` per step.
- **Pausing**: touching the page pauses (resumes 1.2 s after release unless the user scrolled), opening any sheet pauses, the chrome showing does not pause.
- **End**: at the chapter end, when "Pause at chapter end" is on, auto-scroll stops at the Up Next card with haptic `autoscroll.end`; when off, the card's 5 s leader-sweep countdown advances and auto-scroll continues in the next chapter.
- States: running, paused (chip shows Play), stopped, blocked by a failed page (auto-scroll pauses at the broken tile with a toast "Paused at a page that didn't load.").

#### 5.4.2 Ambient soundscape

- **Entry**: the reader's `mm-soundscape` button (both readers), reader settings → AMBIENT, and the listen player's overflow.
- **Library**: eight loops, each 60–90 s seamless, 48 kHz stereo Opus (web) / M4A (iOS, Android), ≈ 1 MB each, downloaded on first use and cached: **Rain on glass**, **Night city**, **Forest dawn**, **Hearth**, **Tavern**, **Ocean**, **High wind**, **Low hum** (a warm drone). Produced from CC0 field recordings and synthesis; licences recorded in `design/sounds/SOURCES.md`.
- **Sheet** (`peek`): `eyebrow` "SOUNDSCAPE"; eight 16:9 tiles in a 2-column grid (4 on desktop), each a slow abstract loop visual (a blurred colour field in the loop's hue drifting over 12 s) with the name in `heading-card`; the playing tile has a 2 px ink ring and a live 3-bar level meter; T1 "Match the series" (auto-picks by genre: romance → Rain on glass, action → High wind, horror → Low hum, fantasy → Forest dawn, slice of life → Hearth, isekai and adventure → Tavern, sci-fi → Night city, drama → Ocean); S1 "Volume" (default 35 %); S1 "Under narration" (default 25 % of the volume); T4 "Sleep with the reader · Keep playing" (whether it stops when leaving the reader).
- **Behaviour**: fades in over 2 s and out over 600 ms; crossfades 1.5 s between loops; pauses when the app backgrounds unless narration is playing; ducks to the "Under narration" level while TTS plays; UI sounds stay suppressed while it plays.
- **Playback**: web uses the Web Audio API (`AudioBufferSourceNode` with `loop = true` into a `GainNode`); Flutter uses `flutter_soloud` 5.1.4 (seamless looping, independent voice from `just_audio` narration).
- States: off, downloading a loop (tile ring progress), playing, failed to load ("Couldn't load Tavern."), offline and not cached (tile Disabled "Needs a connection once").

#### 5.4.3 Panel-by-panel guided view

- **Data**: `GET /reader/panels?source_id=&series_key=&chapter_key=` (new; server-first per the stack decision) returns `{state: ready|processing|unavailable, pages: [{number, panels: [{x, y, w, h, order}]}]}` in page-relative fractions. For webtoon strips the server finds panels by scanning for full-width gutter rows (runs of ≥ 12 px near-uniform rows) and splitting oversized panels at speech-bubble-free rows; for paged manga it detects panel borders and orders them by the series' reading direction.
- **Entry**: the reader's `mm-panel` button (visible only when `state: ready`), `v`, or a two-finger double tap. The first time per profile, a one-line coach toast: "Tap or press → to move panel by panel."
- **Presentation ("the camera")**: the page area goes to `#000`; the current panel is framed at the largest size that fits the viewport with a 24 px (phone) / 64 px (desktop) margin; neighbouring content is hidden by a black mask with a 24 px feathered edge (not blurred). Moving to the next panel is a **dolly**: the camera translates and scales from panel to panel over 520 ms `cine-in-out` (keyboard, tap) or on the `dolly` spring (swipe release). Between pages, the dolly pulls back to show 20 % of the next page for 200 ms, then pushes into its first panel. The page-light spill takes the colour of the current panel.
- **Controls**: tap right 70 % or `→` / `Space` next panel, left 30 % or `←` previous; swipe left / right; pinch out returns to the full page (exiting the view); a panel counter "PANEL 4 / 11 · PAGE 18" in `timecode` in the bottom chrome; IB2 X exits. Auto-play: when auto-scroll is started in this view, panels advance every 3.5 s (adjustable 2–10 s via the speed chip). Haptic `panel.next` per panel.
- **States**: processing ("Finding panels… available in a moment." toast; the button shows a leader sweep), unavailable (the button is hidden), a page with no detected panels (the whole page is framed as one panel), exit (the camera pulls back to the full page at the same scroll position over 480 ms).
- Reduced motion: panel changes are cuts.

#### 5.4.4 Page-tinted chrome ("the room takes the page's colour")

- **Sampling**: the page under the reading line (Strip: the page covering 38 % of the viewport height; Paged: the current page; panel view: the current panel crop) is sampled on page change, throttled to 600 ms, per §2.1.4 (client-side, 16 × 16 on web, `ColorScheme.fromImageProvider` on Flutter). Sampling happens off the main thread on web (`OffscreenCanvas` in a worker) and at a 64 px decode on Flutter.
- **Where the colour lands**: the top and bottom reader scrims (24 % blend toward `key.tint`), the scrubber fill, the chapter label and micro progress (`key.accent`), a 1 px `key.glow` underglow under the bottom chrome, the page-light spill beside the strip on wide screens, the auto-scroll chip dot, and the mini player fill in the novel reader (the novel reader uses the cover, not pages).
- **Guards**: accent contrast ≥ 4.5:1 on `#000` is enforced by the derivation; greyscale pages (S < 0.08) keep the previous colour rather than dropping to grey, so black-and-white manga does not flicker; if six consecutive pages are greyscale the chrome dissolves to the series cover's roles.
- **Timing**: 1200 ms `cine-in-out` dissolve; retargets from the current colour.
- **Settings**: Reader settings → AMBIENT → "Tint the chrome from the page" (default on) and "Page-light spill" (default on).
- States: on, off (cover roles, fixed per chapter), sampling failed (keeps the cover roles).

---

## 6. The two required signature animations

### 6.1 Heading reveal: per letter, fade + slide up + un-blur, staggered

**Spec**

| Property | Value |
|---|---|
| Split | Graphemes (web `Intl.Segmenter(undefined, {granularity: "grapheme"})`, Flutter `String.characters`). Words are grouped in `nowrap` spans so lines break only between words. |
| From → to (each letter) | opacity 0 → 1; translateY +0.45 em → 0; blur 10 px → 0 |
| Duration | 700 ms for opacity and translate; 500 ms for blur (sharp before it settles) |
| Easing | `cine-out` `cubic-bezier(0.16, 1, 0.3, 1)` |
| Stagger | `min(28 ms, 600 ms / (n − 1))` per letter; the whole string's start spread never exceeds 600 ms (a 13-letter heading finishes at ≈ 1036 ms, a 40-letter title at 1300 ms) |
| Responsive size | The heading's own token: `heading-section` 26 / 23 / 20 px, `display-hero` clamp(64, 7vw, 120) / 64 / clamp(40, 11vw, 56), `display-title` clamp(48, 4.6vw, 80) / 48 / 36 |
| Tracking | Tight: −0.01 em (section), −0.02 em (title), −0.025 em (hero); kerning off on revealed text so split and unsplit text match |
| Colour on hover and state | A linked heading (rail header with "See all", Wrapped scene link, detail title → lightbox) wipes from ink to `key.accent` left to right: each letter transitions `color` over 240 ms with a delay of `index × 12 ms`; leaving reverses with no delay. A heading whose state changes (for example the chapter seam becoming the current chapter) crossfades its colour over 280 ms. |
| Trigger | Section and rail headers: when 60 % in view, once per session per header key. Hero titles: on every hero change, starting 200 ms into the 800 ms dissolve. Detail title: when the match cut lands. Chapter seams: when 60 % in view. |
| Accessibility | The container carries the full text (`aria-label` / `Semantics(label:)`); letter spans are hidden from assistive tech. |
| Reduced motion | Whole string fades in over 200 ms; no translate, no blur, no stagger. |

**Placement, exactly**

| Where | Text | Token |
|---|---|---|
| Home rails (every rail header) | "CONTINUE READING", "BECAUSE YOU READ …" | `heading-section` |
| Home hero title | The spotlight series title | `display-hero` |
| Home typed headline | not this animation (typing, §6.2) | |
| Series detail title | The series title | `display-title` |
| Series detail tabs' section heads | "MORE LIKE THIS" rail header inside the tab | `heading-section` |
| Search result group headers | "IN YOUR LIBRARY", "ASURA" | `heading-section` |
| Search mini hero | Top result title | `display-title` at 48 px |
| For you rails and the answers mini hero | rail headers and title | `heading-section`, `display-title` |
| Page titles on first visit of the session | "LIBRARY", "SOURCES", "UPDATES", "CIRCLE", "YOUR READING", "SETTINGS" | `display-page` |
| Preview slate and Quick Look | series title | `heading-section` |
| Reader chapter seam | "CHAPTER 125" | `heading-section` |
| Reader credits | "END OF CHAPTER 124" | `heading-section` |
| Reader resume slate and recap title card | "PREVIOUSLY ON" | `eyebrow` scaled to 14 px |
| Novel chapter opener | chapter title (Instrument Serif) | 1.9× body |
| Stats section heads | "CLOCK", "GENRES", "TOP SERIES" | `heading-section` |
| Wrapped | every scene title and "2026" | `display-hero` / `heading-section` |
| Pre-roll and logo reveal | the wordmark letters | `display-title` geometry (§7.4) |
| Sources hub tiles on focus | source name | `display-page` |

**Web implementation** (`frontend/src/skins/cinematic/primitives/LetterReveal.tsx`, `motion` 13.4.4):

```tsx
"use client";
import { motion, stagger, useReducedMotion, type Variants } from "motion/react";

const seg = new Intl.Segmenter(undefined, { granularity: "grapheme" });
const graphemes = (s: string) => Array.from(seg.segment(s), (x) => x.segment);
const cineOut = [0.16, 1, 0.3, 1] as const;
const seen = new Set<string>(); // once per session per header key

const parent: Variants = {
  hidden: {},
  show: (n: number) => ({ transition: { delayChildren: stagger(Math.min(0.028, 0.6 / Math.max(1, n - 1))) } }),
};
const letter: Variants = {
  hidden: { opacity: 0, y: "0.45em", filter: "blur(10px)" },
  show: { opacity: 1, y: 0, filter: "blur(0px)",
          transition: { duration: 0.7, ease: cineOut, filter: { duration: 0.5, ease: cineOut } } },
};

export function LetterReveal({ text, as: Tag = "h3", revealKey, className }:
  { text: string; as?: "h1" | "h2" | "h3"; revealKey?: string; className?: string }) {
  const reduce = useReducedMotion();
  const M = motion[Tag];
  const replay = !revealKey || !seen.has(revealKey);
  if (reduce) return <M className={className} initial={{ opacity: 0 }} whileInView={{ opacity: 1 }} viewport={{ once: true }} transition={{ duration: 0.2 }}>{text}</M>;
  let i = 0;
  return (
    <M aria-label={text} className={`reveal ${className ?? ""}`} style={{ fontKerning: "none" }}
       initial={replay ? "hidden" : false} whileInView="show" viewport={{ once: true, amount: 0.6 }}
       onAnimationComplete={() => revealKey && seen.add(revealKey)} variants={parent} custom={graphemes(text).length}>
      {text.split(" ").map((w, wi, all) => (
        <span key={wi} aria-hidden className="inline-block whitespace-nowrap">
          {graphemes(w).map((c) => <motion.span key={i} variants={letter} className="inline-block" style={{ ["--i" as string]: i++ }}>{c}</motion.span>)}
          {wi < all.length - 1 && " "}
        </span>
      ))}
    </M>
  );
}
```

```css
/* hover wipe, in skins/cinematic/motion.css */
.reveal span > span { transition: color 240ms ease; }
a:hover > .reveal span > span, .reveal[data-state="active"] span > span { color: var(--key-accent); transition-delay: calc(var(--i) * 12ms); }
```

**Flutter implementation** (`mobile/lib/skins/cinematic/primitives/letter_reveal.dart`, `flutter_animate` 4.5.2):

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
              .fadeIn(duration: 700.ms, curve: CineCurves.out)
              .slideY(begin: .45, end: 0, duration: 700.ms, curve: CineCurves.out)
              .blurXY(begin: 10, end: 0, duration: 500.ms, curve: CineCurves.out),
        ]),
    ]));
  }
}
```

The hover colour wipe does not apply on touch; on Flutter, a focused (hardware keyboard) linked heading uses a `TweenAnimationBuilder<double>` from 0 to n with per-letter colour lerp at the same 12 ms spacing.

### 6.2 Main headline typing reveal: one character every 50 ms

**Spec**

| Property | Value |
|---|---|
| Rate | Exactly one grapheme per 50 ms, spaces included, no punctuation pauses |
| Clock | Timestamp based (`floor(elapsed / 50)`), so a dropped frame never slows the text |
| Layout | The full string is laid out from frame 0; unrevealed graphemes are transparent, so lines never reflow |
| Caret | A `house` (or `key.accent` when a series owns the frame) block 0.5 em × 0.9 em with zero layout width, after the last revealed grapheme; solid while typing; after completion it blinks 530 ms on / 530 ms off three times (3180 ms) and disappears |
| Length | Headlines only, ≤ 60 graphemes (≤ 3 s). Longer AI text streams with per-word fades instead (160 ms each, 30 ms apart). |
| Skip | Tap, click, Enter or Space on the headline completes it at once |
| Accessibility | The full text is in the accessibility tree from the start; the visual layer is hidden from it |
| Reduced motion | Full text at once, no caret |
| Replay | Once per session per headline key (the Home headline replays when its text changes, for example after the content mode switches) |

**Placement, exactly**

| Where | Text example | Token |
|---|---|---|
| **Home main headline** (the primary use) | "TONIGHT: CHAPTER 143 OF OMNISCIENT READER" | `typed-headline` |
| Profile picker | "WHO'S READING?" | `typed-headline` |
| Register → picker welcome | "WELCOME, MIRA." | `typed-headline` |
| Setup | "POINT ME AT YOUR SERVER." | `typed-headline` |
| Onboarding scene 1 | "LET'S FILL YOUR SCREEN." | `typed-headline` |
| For you | "WHAT DO YOU FEEL LIKE READING?" | `typed-headline` |
| For you mini hero | the top answer's `why` (≤ 60 chars; longer ones stream per word) | Instrument Serif italic 22 px |
| Empty-state title cards | "Your shelf is empty." | `editorial-md` |
| 404 | "Nothing here." | `editorial-md` |
| Reader, after a chapter change | "CH 125 · THE SILENT KING" in the top chrome | `timecode` |
| Up Next post-play (listen) | next chapter title | `heading-card` |
| Wrapped | scene lines ("That's 17 days of reading.") | `editorial-md` |
| Novel book page | the first sentence epigraph (≤ 60 chars, else the first clause) | Instrument Serif italic 18 px |

**Web implementation** (`frontend/src/skins/cinematic/primitives/TypedHeadline.tsx`):

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

export function TypedHeadline({ text, className }: { text: string; className?: string }) {
  const { shown, rest, done, skip } = useTyped(text);
  return (
    <h1 aria-label={text} onClick={skip} className={className}>
      <span aria-hidden>{shown}</span>
      <span aria-hidden className="relative inline-block w-0 align-baseline">
        <span className={`absolute bottom-[0.08em] left-0 h-[0.9em] w-[0.5em] bg-[var(--key-accent)] ${done ? "animate-caret-out" : ""}`} />
      </span>
      <span aria-hidden className="text-transparent">{rest}</span>
    </h1>
  );
}
```

`animate-caret-out` is `caret-out 3.18s steps(1) forwards` with `@keyframes caret-out { 0%, 33.33%, 66.67% { opacity: 1 } 16.67%, 50%, 83.33%, 100% { opacity: 0 } }`.

**Flutter implementation** (`mobile/lib/skins/cinematic/primitives/typed_headline.dart`): a `StatefulWidget` with a `Ticker` computing `min(length, elapsed.inMilliseconds ~/ 50)`, rendering `Text.rich` with the revealed span, a zero-width `WidgetSpan` holding the caret (`OverflowBox` + `Container(width: .5 * size, height: .9 * size, color: accent)`), and the rest in a transparent `TextSpan`; a `GestureDetector` completes on tap; when done, a single forward `AnimationController(duration: 3180.ms)` drives the caret's opacity as `(value * 6).floor().isEven ? 1 : 0`, then removes it. The ticker does not start when `accessibilityFeatures.disableAnimations` is set.

---

## 7. Brand

### 7.1 Idea

Two M's, one gutter. *Manhwa* and *Maniacs*: two panels with the strip of light between them. In Projection the gutter is the projector's beam: a tungsten line, the only colour in the brand.

### 7.2 Wordmark ("Stack")

- **Construction**: two lines, left-aligned: "MANHWA" over "MANIACS", drawn from Mona Sans `wdth 75`, `wght 850` and then hand-adjusted: cap height = 1 unit, line gap = 0.18 units, tracking −0.01 em. The two leading M's sit exactly above each other, forming the **MM column**. Between the lines, under the top M only, a **gutter bar** 0.06 units tall and exactly the width of the M, in `house` `#FFB547` with a bloom (`0 0 18px rgba(255,181,71,.45)`, `0 0 2px rgba(255,181,71,.6)`).
- **Colour**: letters `#F5F5F1` on `#000000`; single-colour versions in `#F5F5F1` (gutter bar included, no bloom) and in `#000000` on white for print.
- **Horizontal lockup** (for bars shorter than 40 px): "MANHWA" and "MANIACS" on one line separated by a vertical gutter bar 0.06 units wide and 1 unit tall.
- **Monogram**: the MM column alone (two M's stacked with the gutter bar between them). Used in the rail, the top bar, favicons and the loader.
- **Clear space**: 0.5 units on all sides. **Minimum sizes**: stack 28 px tall, horizontal 12 px cap height, monogram 16 px (favicon uses a single M on the gutter bar below 24 px).
- **Never**: outline the letters, colour the letters, put the wordmark on art without `scrim-top`, animate the bar in any colour but tungsten.

### 7.3 App icon ("Projector column")

- **Field**: `#000000`, with a radial tungsten light `#573E19` at 38 % opacity centred at 50 % 42 % with a radius of 70 % of the canvas (the beam falling on the screen), plus monochrome grain at 2.5 %.
- **Mark**: the MM column centred vertically, the M's in `#F5F5F1`, the gutter bar in `#FFB547` with a 24 px bloom at 45 %, and a thin anamorphic streak through the bar: 2 px tall, `#FFB547` at 25 %, fading over 70 % of the width to both sides.
- **Deliverables** (via `flutter_launcher_icons` 0.14.4 and a small SVG export script):

| Target | Spec |
|---|---|
| iOS master | 1024 × 1024 PNG, opaque |
| iOS 18+ dark | Transparent background, mark only |
| iOS 18+ tinted | Greyscale mark |
| Android adaptive | 108 dp canvas (432 px at xxxhdpi); the MM column's bounding box 160 × 188 px inside the 66 dp safe circle; background layer = the field; foreground = the mark |
| Android 13+ themed | Monochrome mark, same geometry |
| Web | `favicon.svg` (single M on the bar below 24 px, full column at 32 px and up), `icon-192.png`, `icon-512.png`, `maskable-512.png` (mark inside the 40 % radius safe circle), `apple-touch-icon` 180 × 180 opaque |
| Per skin | The Cinematic icon ships alongside Glass's; the skin switch sets the alternate icon (`flutter_dynamic_icon_plus` 1.4.1 on iOS and Android's `activity-alias`) inside the restart; web swaps `<link rel="icon">` to the active skin's SVG on load |
| SideStore source | `iconURL` → the 1024 PNG, `tintColor` → `#FFB547` |

### 7.4 Splash and logo reveal ("Projector")

- **Native layer** (neutral, shared by both skins because iOS's launch storyboard cannot know the skin): the MM column in `#F3EEE6` on `#000000` (`flutter_native_splash` 2.4.8; Android 12 icon inside the 192 dp circle; iOS centred). Web: the same mark as inline SVG, server-rendered.
- **Handoff**: the first Flutter or web frame draws the neutral mark at identical size and position, then the reveal plays.

**Cold start timeline (1400 ms; the pre-roll wraps it up to 1600 ms)**

| t (ms) | Element | Motion | Feedback |
|---|---|---|---|
| 0–120 | Frame | Black, grain 0.12 flickering at 12 fps (the projector warming) | Sound `ui.sting` begins (if on) |
| 120–520 | Beam | A 24 px tungsten band blurred 40 px sweeps left → right across the MM column as a mask, `cine-in-out`; the neutral mark's colour warms from `#F3EEE6` to `#F5F5F1` | |
| 300–1000 | Wordmark letters | The full stacked wordmark grows out of the column: the letters "ANHWA" and "ANIACS" run the per-letter reveal (opacity, +0.45 em, blur 10 → 0; 700 / 500 ms; 28 ms stagger) | |
| 700–900 | Gutter bar | Draws left → right under the top M in tungsten, 200 ms `cine-out` | |
| 820 | Stamp | The MM column scales 1.06 → 1.00 over 160 ms `cubic-bezier(0.2, 0, 0, 1)` | Haptic `brand.stamp`; the sting's transient |
| 900–1300 | Bloom | A radial tungsten glow behind the mark rises 0 → 35 % and settles at 18 %; grain settles to 0.07 | |
| 1300–1400 | Track-out | The wordmark's `wdth` animates 75 → 82 (letters widen slightly, like end titles tracking out) while it dissolves | |
| 1400 | Handoff | The MM column flies to its slot (rail top on desktop, TB1 left on phones) as a shared element over 380 ms `cine-in-out`; the destination fades up from black under it | |

- **Warm start** (resumed within 4 h): the mark fades in 200 ms, then the 250 ms handoff; no beam, letters, haptic or sound.
- **Skin-switch arrival**: the full cold-start reveal always plays (it is the moment the skin announces itself).
- **Skip**: a tap anywhere jumps to the handoff.
- **Reduced motion**: the wordmark fades in 300 ms, holds until data is ready, fades out 200 ms; one `light` haptic.

---

## 8. Signature moments

| # | Name | Where | What happens |
|---|---|---|---|
| 1 | **Projector pre-roll** | Cold start, skin-switch arrival | Grain flicker, beam sweep, wordmark per-letter reveal, tungsten gutter bar, stamp haptic at 820 ms, bloom, track-out, handoff of the MM column to the chrome (§7.4) |
| 2 | **Spotlight** | Profile picker | Everything but the chosen avatar fades to black in 420 ms; the avatar scales to 1.25× under an E4 bloom in its mood colour and flies to the chrome while Home fades up; a skin restart hides inside the black frame when the profile uses the other skin |
| 3 | **Key-light handoff** | Home, Library, History, Search, Circle | Dwelling 450 ms on a poster dissolves the hero art and every key-light role on the page to that series over 800 ms: the room is re-lit by whatever the reader looks at |
| 4 | **Push-in and letterbox curtain** | Series detail → reader | The detail scales 1 → 1.04 and fades to black (320 ms `cine-in`) while two `#000` letterbox bars close from the top and bottom edges (`scaleY` 0 → 1, 320 ms); hold 80 ms; the bars open onto the first page over 600 ms `cine-out`, and the chapter label types in the top chrome. Novels open onto the paper colour. Only on entry from the detail or Home, never between chapters. |
| 5 | **Match cut** | Any poster → detail | The poster morphs into the detail backdrop (480 ms `cine-in-out`, radius 6 → 0), the title letters reveal, the accent rule draws, and the page spill dissolves from black to the series' `key.tint` |
| 6 | **The room takes the page's colour** | Manga reader | Scrims, scrubber, chapter label and the side page-light spill dissolve (1200 ms) to the colour of the page being read |
| 7 | **Credits and Up Next** | End of every chapter | 96 px of black, "END OF CHAPTER 124" letter reveal, the Circle's reactions, the Up Next card with the curtain haptic, and pull-to-continue filling an accent track into a cut through black |
| 8 | **Previously on** | Recap entry points | A black title card "PREVIOUSLY ON" with the series in Instrument Serif, then the recap streaming word by word over the cover's Ken Burns, ending on the last page the reader saw |
| 9 | **Ignite** | First chapter of the day completed | The streak flame grows and blooms while the day count rolls up, with the ignite haptic; inside the reader it appears as a small "DAY 13" card that never interrupts reading |
| 10 | **Wrapped in scope** | `/stats/wrapped/:year` | The year told in 2.39:1 scenes (desktop) or 9:16 (phones), each lit by its subject's cover, ending on shareable stat cards |
| 11 | **House lights down** | Skin switch confirm | Every element dims to black down the page with a 12 ms stagger, the wordmark fades up, its gutter bar goes out, and the app restarts into the other skin |
| 12 | **Lightbox** | Long-press any hero or detail backdrop | The cover leaves its crop and fills the screen whole on 94 % black with a big bloom; drag down to let it fall back into place |
| 13 | **Now showing** | Listen full player | The book's cover becomes a blurred cinema backdrop and the narration plays as subtitles, the speaking character's name above each line in their tint |
| 14 | **The camera** | Panel-by-panel view | The camera dollies from panel to panel with feathered black masks, pulling back briefly at page turns, the page-light following each panel's colour |
| 15 | **X-Ray subtitles** | Dialogue search | Search hits appear as subtitle lines laid over the panel they came from; opening one pulses a tungsten frame around the bubble in the reader |
| 16 | **Rating card** | Opening an 18+ series (profiles with the gate open) | A red 3 × 44 px bar and "18+" with descriptors fade in top-left for 4 s, with the low house-lights hum (if sound is on), then leave without blocking |
| 17 | **The Circle lights up** | Circle members row | An avatar blooms in the colour of the series its member is reading right now |
| 18 | **Cut out of the film** | Removing a series | The poster desaturates and drops out while neighbours close the gap; Undo restores it in place |

---

## 9. Implementation notes (for the stack in `stack-decision.md`)

### 9.1 Token source

`design/tokens/cinematic.json` holds every value in §2. Excerpt of the shape (the generator emits CSS custom properties under `[data-skin="cinematic"]`, a TS object for Motion and `tokens.g.dart` for Flutter):

```json
{
  "color": {
    "void": "#000000", "n150": "#141414", "n200": "#1B1B1B", "ink": "#F5F5F1",
    "ink2": "rgba(245,245,241,.66)", "ink3": "rgba(245,245,241,.48)", "ink4": "rgba(245,245,241,.24)",
    "hair": "rgba(245,245,241,.08)", "house": "#FFB547", "rating": "#FF5C5C", "positive": "#3DD68C",
    "caution": "#FFD27A", "info": "#7AB8FF",
    "keyFallback": { "tint": "#18130C", "wash": "#231B11", "glow": "#573E19", "accent": "#FFB547" },
    "moods": { "default": "#FFB547", "romantic": "#E0527A", "action": "#E4572E", "comedy": "#F2C94C",
               "horror": "#6BA38C", "slice_of_life": "#8FC46A", "fantasy": "#8A6CF0" }
  },
  "radius": { "hair": 2, "frame": 6, "sheet": 12 },
  "motion": {
    "tick": { "ms": 90, "bezier": [0.16, 1, 0.3, 1] },
    "scene": { "ms": 480, "bezier": [0.65, 0, 0.35, 1] },
    "dissolve": { "ms": 800, "bezier": [0.65, 0, 0.35, 1] },
    "rig": { "ms": 300, "bounce": 0 }, "dolly": { "ms": 520, "bounce": 0 }, "slate": { "ms": 360, "bounce": 0 }
  },
  "type": {
    "headingSection": { "family": "Mona Sans", "wght": 760, "wdth": 85, "size": { "d": 26, "t": 23, "p": 20 },
                        "lh": 1.0, "tracking": -0.01, "case": "upper", "maxScale": 1.6 }
  },
  "haptics": { "library.add": "ahap:stamp", "chapter.endcard": "ahap:curtain", "toggle.on": "medium", "page.turn": "selection" },
  "sounds": { "library.add": "ui.stamp", "download.done": "ui.reel-lock" }
}
```

Key-light roles are **not** tokens (they are runtime values); the token file holds only their fallbacks and the derivation constants (L and S clamps), which both clients use when a payload lacks `ambient`.

### 9.2 Web (`frontend/src/skins/cinematic/`)

| File | Contents |
|---|---|
| `tokens.generated.css`, `tokens.generated.ts` | From `design/build.mjs` |
| `fonts.ts` | `next/font/google`: `Mona_Sans` (`axes: ["wdth"]`, `display: "block"`, preload), `Geist`, `Geist_Mono`, `Instrument_Serif`, `Newsreader` (`axes: ["opsz"]`), `Literata`, `Source_Serif_4`, `Atkinson_Hyperlegible_Next`; Noto CJK with `preload: false` |
| `key-light.tsx` | `KeyLightProvider`: holds the current owner, writes `--key-tint`, `--key-wash`, `--key-glow`, `--key-accent`, `--key-ink` on the provider element; the five properties are registered with `@property` so they interpolate over 800 ms; exposes `useKeyLight(owner, {dwellMs})` |
| `page-tint.worker.ts` | `OffscreenCanvas` 16 × 16 sampler for the reader, posting seed colours; the derivation function is shared with the fallback path (≈ 40 lines, one runnable check in `page-tint.test.ts` asserting accent contrast ≥ 4.5:1 across 360 hues) |
| `Shell.tsx` | Rail, top strip, bottom nav, route `AnimatePresence mode="wait"` for dip to black |
| `Splash.tsx` | Projector reveal |
| `primitives/` | Button, IconButton, TextField, SearchField, FilterChips, Poster, Rail, PreviewSlate, Sheet (on `@base-ui/react` 1.8.0 `Drawer` / `Dialog`), Dialog, SubtitleToast (on `sonner` 2.0.8), SlateTabs, Toggle, Checkbox, Radio, Segmented, Slider, SpeedRuler, Progress, LeaderSweep, Skeleton, Badge, Menu and ContextMenu (`@base-ui/react`), Avatar, Kbd, TitleCard, LetterReveal, TypedHeadline, StreakFlame, RatingCard, Lightbox, Scrims |
| `screens/` | One file per `ScreenId` (§4.0.2) |
| `motion.ts`, `motion.css` | Curves, springs as Motion transitions and CSS `linear()`, Ken Burns, grain, caret and flicker keyframes |
| `haptics.ts`, `sounds.ts` | `navigator.vibrate` subset; Web Audio buffers |

Libraries: `motion` 13.4.4 (replacing `framer-motion` 12; import from `motion/react`), `@base-ui/react` 1.8.0, `embla-carousel-react` 8.6.0 (rails' touch drag on mobile web and the hero swipe; keyboard fixed-left focus is custom), `sonner` 2.0.8, `lenis` 1.3.26 (desktop wheel smoothing on Home, detail and Stats only; never in readers or inside scrollable panels), `@phosphor-icons/react` 2.1.10, `@use-gesture/react` 10.3.1 (reader pinch). Rails' sibling dim is pure CSS (`.rail:has(.poster:hover) .poster:not(:hover)`). The match cut uses `document.startViewTransition` with per-series `view-transition-name`s; `::view-transition-group(*)` gets `animation-duration: 480ms; animation-timing-function: cubic-bezier(.65,0,.35,1)`. The letterbox curtain is two fixed `div`s animating `transform: scaleY()`.

Grain: the SVG `feTurbulence` data-URI pseudo-element with `mix-blend-mode: overlay` at 0.07, animated with `steps(1)` over 0.66 s; paused off-screen with IntersectionObserver.

### 9.3 Flutter (`mobile/lib/skins/cinematic/`)

| File | Contents |
|---|---|
| `tokens.g.dart` | Generated `SkinTokens` constants |
| `cinematic_skin.dart` | `Skin` implementation: `ThemeData` (dark, `scaffoldBackgroundColor: Color(0xFF000000)`, `PageTransitionsTheme` with `PredictiveBackFullscreenPageTransitionsBuilder` on Android and `swipeable_page_route` 0.4.8 edge-only on iOS), router, splash, haptics, sounds |
| `key_light.dart` | `KeyLight` `InheritedNotifier` + `KeyLightScope` widget animating the five roles with `TweenAnimationBuilder<Color?>` over 800 ms `CineCurves.inOut` |
| `page_tint.dart` | `ColorScheme.fromImageProvider(provider: ResizeImage(provider, width: 64), brightness: Brightness.dark)` → seed → roles; throttled to 600 ms; runs in the reader engine's `chromeBuilder` |
| `shell.dart` | Bottom nav with `StatefulShellRoute.indexedStack`, dip-to-black `CustomTransitionPage` (a 400 ms controller with `Interval(0, .3)` out and `Interval(.4, 1)` in) |
| `primitives/` | The same list as web; `LetterReveal` and `TypedHeadline` as §6; posters with `Image.frameBuilder` focus pull (`cached_network_image` fade set to zero); `LeaderSweep` as a `CustomPainter`; `Hero` match cuts with `heroine` 0.7.2 for the radius lerp and the drag-to-dismiss lightbox; sheets on `smooth_sheets` 1.2.0 (`peek` / `half` / `full` detents with `rig` snapping) |
| `shaders/grain.frag` | The grain `FragmentProgram` with `BlendMode.overlay`, `uTime` quantised to 1/12 s |
| `screens/<cluster>/` | One widget per `ScreenId` |

Libraries: `flutter_animate` 4.5.2, `swipeable_page_route` 0.4.8, `smooth_sheets` 1.2.0, `heroine` 0.7.2, `gaimon` 1.5.0 (AHAP and named impacts on both platforms; `haptic_feedback` 0.6.5 is not needed in this skin), `flutter_soloud` 5.1.4 (UI sounds and soundscape loops), `phosphor_flutter` 2.1.0, `custom_refresh_indicator` 4.0.2, `flutter_reorderable_grid_view` 5.7.0, `extended_image` 10.1.0 (lightbox pinch and paged zoom), `share_plus` 10.1.4 (stat cards), `flutter_dynamic_icon_plus` 1.4.1 (per-skin icon), `flutter_native_splash` 2.4.8 and `flutter_launcher_icons` 0.14.4 (build-time). Native additions (`flutter_soloud`, `gaimon`, `share_plus`, `flutter_dynamic_icon_plus`) land together in one isolated commit with a CI iOS dry run. Fonts are bundled TTFs with `FontVariation`; `google_fonts` is not used.

### 9.4 Reader engine seam

The Cinematic reader chrome plugs into `ReaderEngine.chromeBuilder: (context, ReaderEngineState) → Widget` (Flutter) and the equivalent render prop on web. It reads `currentPage`, `pageImageProvider`, `chapterBoundary`, `autoScroll`, `panelData` and `progress` from the engine and never touches strip layout, prefetch, restore or progress writes. Auto-scroll speed is stored in the engine as px/s; the skin maps 0.25×–4× to 15–240 px/s. Panel-by-panel mode is an engine view mode that exposes `panelIndex` and a `cameraRect`; the skin draws the masks and the dolly.

### 9.5 Backend additions this concept depends on

1. `ambient` (`seed`, `tint`, `wash`, `glow`, `accent`) on every series-bearing payload, computed with Pillow + `colorsys` next to cover resizing and cached with the cover.
2. `reading_profiles.skin` (per the stack decision).
3. `GET /home`, `GET /library/similar`, `POST /library/recommendations/feedback`, `GET /recap` (§5.1).
4. `GET /library/statistics/genres`, `GET /library/statistics/wrapped` (§5.2).
5. The `/circle/*` endpoints and collection sharing (§5.3), with the 18+ gate applied at serve time for the viewer's active profile.
6. `GET /reader/panels` (§5.4.3).
7. Fifteen public showcase covers under `/app/media/wall-*.jpg` for the sign-in wall.

`backend/connectors/` is not touched by any of these.

### 9.6 Performance guards (flagship-only, still bounded)

- At most one Ken Burns layer and one grain layer animate per screen; both pause off-screen (IntersectionObserver / `TickerMode`).
- Per-letter blur on Flutter costs one `ImageFiltered` layer per glyph for about 1 s; headings over 48 graphemes reveal per word instead (same timing per word).
- Key-light colour transitions animate custom properties on one element (web) and one `InheritedNotifier` (Flutter); components read them, so a dissolve repaints only coloured surfaces.
- Page tint sampling never runs more than once per 600 ms and never on the UI thread on web.
- The reader strip never receives filters, blur, grain or blend modes; everything ambient lives in the chrome and the letterbox.

### 9.7 Verification per cluster

- Web: Playwright screenshots of every `ScreenId` at 1440 × 900 and 390 × 844 in each state (loading, content, empty, error, offline), plus a reduced-motion pass; `LetterReveal` and `TypedHeadline` have one Vitest each (a 50 ms clock test with fake timers; grapheme split on "Solo Leveling 나 혼자만 레벨업").
- Flutter: the completeness and import-boundary tests from the stack decision, one smoke test per cluster, and the screenshot harness looped over the skin; one widget test for `TypedHeadline` timing with `tester.pump(const Duration(milliseconds: 50))` steps.
- Device checks: Android flagship at 120 Hz first, then the owner's iPhone via the CI IPA and SideStore, per cluster.
