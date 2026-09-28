# Glass concept 1: "Prism" (material-first)

Designer 1 of 3 for the Glass skin. Angle: **light, refraction, specular highlights and thickness define every surface.** Nothing in Prism is "a grey box with a blur". Every surface is a physical object with a thickness, sitting in one light, bending whatever is behind it.

Binding inputs: `inventory/00-decisions.md` (owner decisions), `inventory/web.md`, `inventory/mobile.md`, `inventory/capabilities.md`, `research/*.md` (especially `glass-language.md`, `brand.md`, `reader-ux.md`, `gestures-nav.md`, `discovery-ux.md`), `stack-decision.md` (keep Next.js 16 + Flutter 3.44.6, per-skin screen folders, one JSON token source). Dark only, AMOLED `#000000` base, restart on skin switch, flagship-only effects, OS accessibility settings honoured.

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

Conventions used everywhere below:

- Lengths are logical px (1 CSS px = 1 Flutter logical pixel = 1 pt on iOS). Letter spacing is in em; `design/build.mjs` multiplies it by the font size for Dart.
- Token names are dotted (`glass.color.frost950`). The web CSS variable is the same path with dashes (`--mm-color-frost950`), the Tailwind 4 `@theme` name drops the skin (`--color-frost950`), and the Flutter `GlassTokens` field is camelCase (`colorFrost950`).
- A spring is written `{ms, bounce}` as `stack-decision.md` §2.1 requires; the physical stiffness and damping (mass 1) are listed next to it because the web generator emits them (see §9.1).
- "Phone" means iOS app, Android app and mobile web (< 768 px) together; platform deltas are listed where they exist. "Desktop" means web ≥ 1024 px; "tablet" is web 768–1023 px and large Android/iPad windows.

---

## 1. Manifesto

Prism treats the screen as a black room with one window of light and a few pieces of glass floating in it. The black is real AMOLED black and it stays black; the only colour in the room is the light that comes off the art (a cover, a page, a profile's mood), pooled low and soft in the ambient field behind everything. Controls are not painted, they are *made*: each one has a thickness in millimetres of virtual glass, and that thickness decides how much it bends the art behind it, how wide its bright bezel is, how sharp its specular edge is, how deep its shadow falls and how rounded its letters are. A 44 px button is a thin pane that flips its light as it passes over a page; a menu is a thick block that refracts a whole panel into its rim; a sheet thickens as you drag it until, at full height, it turns solid. One key light hangs at the top left of the room and moves a few degrees with your hand (gyroscope) or your pointer, so every rim catches it the same way and the whole interface reads as one lit scene rather than a pile of widgets. Colour is rationed like light: exactly one object per screen is *lit* (glacier-tinted glass that throws a faint caustic onto the content below it), and everything else stays clear. Content (covers, pages, rows, prose) never becomes glass; it is the thing the glass exists to look through. Motion is physical: glass materialises by bending light in rather than fading in, presses swell toward the finger and glow from inside, springs keep their momentum when you interrupt them, and haptics feel like fingertips on a hard, smooth surface: many small crisp ticks, never a thud. When the owner turns on Reduce Transparency, the same objects become solid slabs of the same shape; when Reduce Motion is on, they stop flexing but still answer the finger. If a surface would look the same with its thickness set to zero, it is designed wrong.

---

## 2. Tokens

### 2.1 Colour

#### 2.1.1 Canvas and the Frost ramp

A cool neutral ramp (blue-grey, hue ≈ 215°) so neutral surfaces sit in the same colour temperature as the key light. Contrast is measured with the WCAG formula against `#000000` and against `surface1` (`#171B20`).

| Token | Hex | On `#000` | On `surface1` | Role |
|---|---|---|---|---|
| `color.canvas` | `#000000` | n/a | n/a | The room. Every screen's base, reader gutters, the bottom 40 % of every screen (AMOLED pixels off) |
| `color.frost25` | `#050608` | 1.04 | 1.17 | Sunken wells: reader side margins on desktop, the inside of the storage meter tube |
| `color.frost50` | `#0A0C0F` | 1.07 | 1.13 | Skeleton base, empty cover placeholder base |
| `color.frost100` | `#111418` | 1.14 | 1.07 | Grouped-list background on desktop settings, stats chart plot area |
| `color.frost150` = `color.surface1` | `#171B20` | 1.21 | 1.00 | Content slab: grouped list rows, cards that need a container, next-chapter card |
| `color.frost200` = `color.surface2` | `#1E232A` | 1.33 | 1.09 | Pressed content row, raised content inside `surface1` (stat tile inside a card) |
| `color.frost300` = `color.surface3` | `#2A3039` | 1.58 | 1.30 | Opaque separators, segmented thumb at rest, solid-tier large sheets |
| `color.frost400` | `#3B434E` | 2.10 | 1.73 | Disabled fills, slider track on solid tier |
| `color.frost500` | `#56606D` | 3.29 | 2.71 | Decorative only (chart gridlines, the 18+ marker's outline on solid tier). Never text |
| `color.frost600` | `#77818F` | 5.32 | 4.38 | `label4`: timestamps, counters, captions ≥ 12 px on black only |
| `color.frost700` | `#9AA3B0` | 8.24 | 6.79 | `label3`: tertiary text, placeholder text, inactive tab icons |
| `color.frost800` | `#BEC5CF` | 12.08 | 9.95 | `label2`: secondary text, descriptions, meta lines |
| `color.frost900` | `#DDE2E8` | 16.12 | 13.28 | Body prose on content slabs, reader chrome labels |
| `color.frost950` | `#F5F7FA` | 19.57 | 16.12 | `label`: primary text, titles, icons on glass |
| `color.white` | `#FFFFFF` | 21.00 | 17.30 | Specular light only (rims, glints, press glow). Never used for text, so text never halates on OLED |

#### 2.1.2 Vibrancy roles (text, fills and lines placed on glass or content)

Glass never carries opaque neutral fills (Apple's no-glass-on-glass rule): anything on glass uses these translucent roles so the material still shows through.

| Token | Value | Use |
|---|---|---|
| `color.label` | `#F5F7FA` | Primary text and glyphs everywhere |
| `color.label2` | `rgba(221,226,232,0.72)` | Secondary text on glass (≈ `#A3A8AE` over black glass; 7.9:1) |
| `color.label3` | `rgba(221,226,232,0.50)` | Tertiary text on glass, placeholders (5.1:1 over black glass) |
| `color.label4` | `rgba(221,226,232,0.34)` | Disabled labels on glass. Never informational |
| `color.fill1` | `rgba(154,163,176,0.32)` | Toggle track off, slider track, content-layer control fill on glass |
| `color.fill2` | `rgba(154,163,176,0.24)` | Input fields, chips at rest, B5 buttons |
| `color.fill3` | `rgba(154,163,176,0.16)` | Row hover, quiet chips, keycaps |
| `color.fill4` | `rgba(154,163,176,0.10)` | Pressed-row wash, skeleton bones on glass |
| `color.separator` | `rgba(154,163,176,0.22)` | 0.5 px hairlines inside glass and grouped lists |
| `color.separatorOpaque` | `#2A3039` | Hairlines on solid tier and on `canvas` |

#### 2.1.3 The spectrum: light-coloured accents

Prism has no "brand colour" painted on things. It has four colours of light, taken from what a prism does to white light, and each has exactly one job.

| Token | Hex | On `#000` | Job | Never |
|---|---|---|---|---|
| `color.glacier` | `#8FD8FF` | 13.43 | **The lit colour.** Tint of the one lit object per screen (primary action), progress fills, focus rings, selected tab glyph, active scrubber, links | As a large flat fill; as body text |
| `color.glacierDeep` | `#1F5A80` | 2.83 | The *body* of lit glass (82–90 % alpha under a glacier rim). White text on it is 7.41:1 over black and 5.27:1 over a white page at 86 % | As text |
| `color.iris` | `#A99BFF` | 8.82 | **Machine light.** Everything the external AI produced: AI rails' eyebrow, recap glyph, `why` lines' leading spark, the Ask field's rim when active | On anything a human made |
| `color.bloom` | `#FF9ED8` | 11.13 | **People light.** Friends (social): reactions, activity dots, shared-collection rims, "recommended by" chips | For status or warnings |
| `color.flare` | `#FFB05C` | 11.62 | **Warmth.** Streak flame core, reading-time highlights in Stats and Wrapped, the soundscape "on" glyph | For errors |

The aurora gradient used only by brand surfaces (icon, splash, Wrapped cover, share cards): `linear-gradient(135deg, #8FD8FF 0%, #A99BFF 52%, #FF9ED8 100%)`.

Chromatic dispersion fringes (thick glass rims only, §2.2.5): red fringe `rgba(255,106,136,0.35)`, blue fringe `rgba(106,184,255,0.35)`.

#### 2.1.4 Semantic roles

| Token | Hex | On `#000` | Use |
|---|---|---|---|
| `color.success` | `#6EF0B5` | 14.79 | Saved offline, completed, healthy source, password changed |
| `color.warning` | `#FFC872` | 13.76 | Stale catalogue, paused downloads, storage near cap, rate-limited, overdue checker |
| `color.danger` | `#FF7A85` | 8.37 | Errors, destructive labels, failed downloads, dead source |
| `color.info` | `#8FD8FF` | 13.43 | Same as glacier; informational notices |
| `color.mature` | `#FF5C93` | 7.20 | The 18+ marker (pill text `#000000` on it = 7.20:1) |
| `color.unread` | `#8FD8FF` | 13.43 | Unread dots and "N new" counts |
| `color.health.ok` / `failing` / `dead` / `unknown` | `#6EF0B5` / `#FFC872` / `#FF7A85` / `#9AA3B0` | as above | Source health dots; `demoted` adds a `#FFC872` 1 px ring around the dot |
| `color.status.reading` | `#8FD8FF` | 13.43 | Reading-status glyph dot + text |
| `color.status.completed` | `#6EF0B5` | 14.79 | |
| `color.status.onHold` | `#FFC872` | 13.76 | |
| `color.status.planToRead` | `#A99BFF` | 8.82 | |
| `color.status.dropped` | `#9AA3B0` | 8.24 | |
| `color.status.unread` | `#BEC5CF` | 12.08 | |
| `color.download.queued` / `saving` / `saved` / `incomplete` / `paused` / `stale` / `failed` | `#9AA3B0` / `#8FD8FF` / `#6EF0B5` / `#FFC872` / `#FFC872` / `#FFC872` / `#FF7A85` | | Download state glyph colours (§3.29) |

Semantic colours appear as **glyph colour or a 2 px rim**, never as a large fill. Notice capsules (§3.30) use `color.X` at 14 % alpha inside a regular glass capsule with a `color.X` 0.5 px rim.

#### 2.1.5 Speaker palette (novel dialogue tints)

`GET /novels/attribution` orders the cast by line count; speakers take these in order, so the two busiest speakers get the most distant hues. All ≥ 8.8:1 on black, used as a text-background band at 14 % alpha and a 1 px underline at 60 % alpha.

| # | Token | Hex | On `#000` |
|---|---|---|---|
| 1 | `color.speaker1` | `#8FD8FF` | 13.43 |
| 2 | `color.speaker2` | `#FFB05C` | 11.62 |
| 3 | `color.speaker3` | `#A99BFF` | 8.82 |
| 4 | `color.speaker4` | `#6EF0B5` | 14.79 |
| 5 | `color.speaker5` | `#FF9ED8` | 11.13 |
| 6 | `color.speaker6` | `#FFE07A` | 16.20 |
| 7 | `color.speaker7` | `#7FB2FF` | 9.71 |
| 8 | `color.speaker8` | `#FF8F6B` | 9.39 |
| 9 | `color.speaker9` | `#B8F27C` | 16.03 |
| 10 | `color.speaker10` | `#7FE6E0` | 14.30 |

Speakers beyond ten reuse the list with a dotted (instead of solid) underline. The narrator is never tinted.

#### 2.1.6 Mood refraction (the seven profile moods)

A profile's `mood` does not tint the UI. It is the **colour of the light in the room when no series owns the frame**: it seeds the ambient field (§2.1.8) on Home before covers load, on You, Settings, Search idle, Sources, and the profile picker. The reader never uses it.

| Mood | Field A1 | Field A2 | Field A3 | Rim tint (added to specular at 18 %) |
|---|---|---|---|---|
| `default` | `#2B4A66` | `#3A3470` | `#1E2F3A` | `#8FD8FF` |
| `romantic` | `#6E2F4E` | `#7A4A6A` | `#3A1E33` | `#FF9ED8` |
| `action` | `#7A3322` | `#6A4A1E` | `#3A1A14` | `#FFB05C` |
| `comedy` | `#6E5A1E` | `#3E6A3A` | `#3A331A` | `#FFE07A` |
| `horror` | `#3A1422` | `#22303A` | `#1A0E14` | `#FF7A85` |
| `slice_of_life` | `#3E5A3A` | `#5A5238` | `#22301E` | `#B8F27C` |
| `fantasy` | `#4A3A7A` | `#2E5A6E` | `#281E3E` | `#A99BFF` |

#### 2.1.7 Scrims, dims and the legibility floor

| Token | Value | Use |
|---|---|---|
| `color.dimSheet` | `rgba(0,0,0,0.25)` | Behind partial-detent sheets |
| `color.dimModal` | `rgba(0,0,0,0.40)` | Behind alerts, the 18+ confirm, restore confirm, command palette |
| `color.dimClear` | `rgba(0,0,0,0.35)` | Under clear glass over bright media (hero, image viewer) |
| `color.scrimHero` | `linear-gradient(180deg, rgba(0,0,0,0) 40%, rgba(0,0,0,0.55) 72%, #000 100%)` | Bottom of every hero and detail backdrop, so the art melts into canvas |
| `color.scrimEdgeTop` | `linear-gradient(180deg, rgba(0,0,0,0.72), rgba(0,0,0,0))` + 6 px blur, 72 px + safe area | Soft scroll edge under floating top controls |
| `color.scrimEdgeBottom` | mirrored, 96 px + safe area | Soft scroll edge behind the tab bar |
| `color.scrimEdgeHard` | `rgba(0,0,0,0.92)` + 0.5 px `separator` | Hard scroll edge under pinned headers (chapter list header, settings search) |

**Legibility floor (adaptive dim).** Glass shows what is behind it, so a label on glass over a white manhwa page would fail. Every glass surface carries an internal dim layer between the backdrop and its fill whose alpha follows the relative luminance `Lb` (0–1) of what is directly behind it:

`dim = clamp(0.22 + 0.42 × Lb, 0.22, 0.64)`

At `Lb = 1` (a white page) that gives 0.64, and `#F5F7FA` on the composite measures 5.29:1; over black it stays at 0.22 so the glass still reads as glass. `Lb` comes from data the app already has, never from reading pixels back on the GPU: the ambient palette's luminance for normal screens, the per-page palette's top-band and bottom-band luminance in the readers (§2.1.8), and a fixed `Lb = 0.5` for anything whose backdrop is unknown. The dim animates over 400 ms `ease.fade` when `Lb` changes, so chrome sliding from a dark panel onto a white one darkens smoothly.

#### 2.1.8 The ambient field and colour extraction

Glass over pure `#000` has nothing to bend, so every Prism screen paints an **ambient field** (z 0.5) under its content: two or three very soft light pools taken from the art that owns the screen.

**Extraction (server, once, cached).**
- **Covers:** on first request of a cover, the backend decodes the `w=96` variant with Pillow (already pinned, 12.3.0), `Image.quantize(colors=6, method=MEDIANCUT)`, converts the six colours to OKLCH, and discards any with `L < 0.12`, `L > 0.94` or `C < 0.025` (unless all six would go, in which case it keeps the two most populous). It ranks the rest by `population × (0.5 + C)` and stores the top three as `A1…A3` plus the cover's mean luminance `Lm`, in a `cover_palette` row keyed by `(source_id, series_identity)`, 30-day TTL. Payload shape everywhere a cover appears: `palette: {a: ["#rrggbb","#rrggbb","#rrggbb"], l: 0.41}`.
- **Pages (reader):** the image proxy already streams page bytes. While streaming it computes a 12 × 24 grid of mean colours from a 48 px downsample and keeps `{top: #rrggbb, mid: #rrggbb, bottom: #rrggbb, lTop, lBottom, accent: #rrggbb}` in an in-memory LRU (10,000 pages, ≈ 1.2 MB). `GET /reader/palette?source=&series=&chapter=` returns the entries for that chapter's pages (null for pages not proxied yet); the reader calls it once when a chapter loads and once more 5 s later. No page bytes are stored.
- **Web fallback** (downloaded chapters opened offline, or a null entry): `fast-average-color` 9.6.0 on a 32 × 32 draw of the already-decoded image (covers and pages are same-origin through the `/api` rewrite, so the canvas is not tainted). **Flutter fallback:** `material_color_utilities` ^0.13.0 `QuantizerCelebi` on a 64 px `ResizeImage` in `compute()`.

**Normalisation for light.** Extracted colours are art colours, not light colours. Before use each `Ai` is re-mapped in OKLCH to `L = 0.46–0.58` (A1 0.58, A2 0.52, A3 0.46), `C = clamp(C, 0.06, 0.15)`, hue unchanged. The glass rim tint takes A1 at `L 0.86, C ≤ 0.08`. A cover with no usable chroma (a black-and-white manga cover) produces the neutral field `#2B3039 / #1E232A / #111418` with a `#DDE2E8` rim tint, which reads as moonlight.

**Field geometry.**
- Phone: A1 pool is an ellipse 120 % × 55 % of the viewport, centred at (30 %, 8 %); A2 at (82 %, 22 %), 90 % × 45 %; A3 at (50 %, 38 %), 110 % × 40 %. Each is a radial gradient from the colour at 26 % opacity to transparent, then blurred 120 px. A black vertical mask fades the whole field to 0 by 60 % of the viewport height, so the bottom 40 % of the screen is pixels-off black.
- Desktop: the same three pools across the content area to the right of the sidebar, with the mask reaching 0 at 55 %. The sidebar's own glass samples the field.
- The field drifts: each pool's centre moves on a Lissajous path of ±3 % over a 40 s loop (`sin(t·2π/40)`, `cos(t·2π/32)`), so glass edges catch slowly changing light. Frozen under Reduce Motion.

**Which art owns the field.**

| Screen | Field source |
|---|---|
| Home | The spotlight's cover; cross-fades 900 ms `ease.fade` when the spotlight changes |
| Series, Book, Recap | That series' cover, at 34 % (brighter than elsewhere) |
| Manga reader | The current page's `top` / `mid` / `bottom` colours as a vertical triple behind the chrome only (not behind the page column); updated at most every 600 ms, cross-faded 900 ms |
| Novel reader | The paper colour (no field; paper is content) |
| Library, Collections, History, Bookmarks, Downloads, Updates | The most recently read followed series' cover at 18 % |
| Sources, Source catalogue | The source's icon colour (A1 from its icon at `w=96`), 18 % |
| Search, You, Settings, Profile picker, auth, onboarding | The active profile's mood (§2.1.6); auth and setup use `default` |
| Friends | Blend of the friends' avatars' base colours |
| Stats, Wrapped | The aurora triple `#2B4A66 / #3A3470 / #6E2F4E` |

The 18+ rule applies to the field too: a mature series can only own the field for a profile that can see it, because the field only ever uses art already on screen.

### 2.2 Materials (the heart of Prism)

#### 2.2.1 The light model

There is one **key light**, a soft area light at angle `glass.light.angle = 135°` (from the top-left, measured clockwise from the positive x-axis toward the viewer's upper left) and elevation 45°. Every glass object computes its highlights from it:

- **Specular rim:** a 1 px (0.5 px on DPR ≥ 2 screens drawn as 1 physical px) gradient border whose brightness follows the light: `linear-gradient(var(--mm-light-angle), rgba(255,255,255,S) 0%, rgba(255,255,255,0.06) 35%, rgba(255,255,255,0.02) 65%, rgba(255,255,255,S×0.55) 100%)`, where `S` is the thickness's specular value (§2.2.2). The far corner gets the weaker secondary glint because light passing through the slab exits there.
- **Inner light:** a 1 px inset line along the lit edge (`inset 1px 1px 0 rgba(255,255,255,S×0.35)`) and a 1 px inset shade along the far edge (`inset -1px -1px 0 rgba(0,0,0,0.35)`). This is what makes a pane look thick on black.
- **Rim tint:** the ambient field's rim colour (§2.1.8) mixed into the specular at 18 %, so glass over a warm cover has a warm edge.
- **Moving light:** on phones the angle follows the gyroscope (`sensors_plus` 7.1.0, device roll × 0.5, clamped to ±25°, smoothed by `spring.tilt`). On desktop it follows the pointer across the viewport (`angle = 135° + 25° × (pointerX / viewportWidth − 0.5) × 2`), updated in one `pointermove` listener on `window`, throttled to one write per animation frame. Mobile web without motion permission and every platform under Reduce Motion: fixed at 135°.

#### 2.2.2 Thickness scale

Size changes the material (Apple, WWDC25-219): a bigger object reads as thicker, with deeper shadow, stronger lensing and softer scatter. Prism makes that a scale. Every glass component names its thickness; a free-sized glass object (a context menu, a sheet) snaps by its shorter side: `< 36 px → T1`, `36–56 → T2`, `57–96 → T3`, `97–400 → T4`, `> 400 → T5`. Bars keep a fixed thickness whatever their length.

| Token | Name | Virtual thickness | Bezel (refraction band) | Max displacement | Backdrop blur | Saturate | Fill | Specular `S` | Drop shadow over content | Dispersion |
|---|---|---|---|---|---|---|---|---|---|---|
| `glass.t1` | Film | 12 px | 6 px | 6 px | 2 px | 1.4 | `rgba(255,255,255,0.03)` | 0.55 | `0 2px 8px rgba(0,0,0,0.35)` | none |
| `glass.t2` | Pane | 20 px | 10 px | 10 px | 6 px | 1.8 | `rgba(255,255,255,0.06)` | 0.42 | `0 6px 20px rgba(0,0,0,0.45)` | none |
| `glass.t3` | Slab | 28 px | 14 px | 14 px | 10 px | 1.8 | `rgba(255,255,255,0.07)` | 0.36 | `0 10px 30px rgba(0,0,0,0.50)` | none |
| `glass.t4` | Block | 40 px | 18 px | 18 px | 22 px | 1.8 | `rgba(24,28,34,0.46)` | 0.30 | `0 24px 64px rgba(0,0,0,0.60)` | 0.6 px |
| `glass.t5` | Monolith | 56 px | 24 px | 22 px | 32 px | 1.7 | `rgba(18,21,26,0.58)` | 0.26 | `0 40px 96px rgba(0,0,0,0.66)` | 1.2 px |

Refractive index for every thickness is `n = 1.5` on web (Snell calculation, §9.2) and `refractiveIndex 1.15` (the library default) in `liquid_glass_widgets`, whose model is not physical; the Flutter `thickness` field takes the virtual thickness above directly (library default 30), and both are calibration knobs to re-check side by side with the web on a checkerboard backdrop. The shadow is only drawn when content is under the glass; over empty canvas black a shadow is invisible, so separation there comes from the rim and inner light.

**Thickness in the component map** (full list in §3): T1 slider thumbs while dragged, chips while dragged, toggle knobs while dragged, OCR hit highlights, the scrubber magnifier stem. T2 icon orbs (44), toasts, the bottom accessory, reader capsules, page counter, search field, the "Back to voice" pill. T3 tab bar, sidebar, top title capsule, segmented thumbs while dragged, desktop reader toolbar. T4 menus, context menus, partial sheets, alerts, command palette, quick look, profile switcher. T5 the listen-mode window, the Wrapped story frame, the splash lens, the image viewer frame, the skin-switch confirmation.

#### 2.2.3 Variants

| Variant | What changes | Where |
|---|---|---|
| `regular` | The table above | Default for all glass |
| `clear` | Fill `rgba(255,255,255,0.02)`, blur 1 px, saturate 1.4, plus `color.dimClear` beneath when `Lb > 0.45` | Only over media: hero controls, image-viewer controls, the Wrapped share bar. **Never mixed with `regular` in one group** |
| `lit` | Body `glacierDeep` at 86 %, blur 10 px, saturate 1.6, rim `rgba(143,216,255,0.60)`, specular `S + 0.1`, inner glow `inset 0 0 18px rgba(143,216,255,0.22)`, label `#FFFFFF` weight 650 | The one primary action per screen (Read, Continue, Create account, Save, Download N). Casts a caustic (§2.2.5) |
| `coral` | Body `#5A1E26` at 86 %, rim `rgba(255,122,133,0.55)`, label `#FFFFFF` (8.9:1 over black) | Destructive confirmations only (Delete profile, Restore, Sign out everywhere). Never at rest on a screen, only inside an alert |
| `solid` (Reduce Transparency, in-app "Solid glass", no-blur renderer) | Fill `#1E232A` (T1–T3) / `#2A3039` (T4–T5), no blur, no refraction, rim `rgba(255,255,255,0.10)`, inner light kept, specular `S × 0.5` | Accessibility. Same shapes, same motion |
| `contrast` (Increase Contrast) | `solid` plus a 1 px `rgba(255,255,255,0.55)` border and `glacierHc #BEE9FF` instead of glacier | Accessibility |
| `frosted` (renderer cannot refract: Safari, Firefox, Flutter Skia) | Blur, saturate, fill, rim, inner light, caustic and glow all kept; displacement and dispersion off | Capability floor, not a design tier (§9.6) |

#### 2.2.4 Content-layer slabs

Content never uses glass. Where content needs a container it sits on an opaque or near-opaque slab:

| Token | Fill | Radius | Use |
|---|---|---|---|
| `slab.grouped` | `surface1` | 20 (grouped list), rows inside 0 | Settings groups, chapter lists on phone, downloads groups |
| `slab.card` | `surface1` | 26 | Next-chapter card, stat cards, recap card body, world title card |
| `slab.panel` | `rgba(23,27,32,0.86)` + 40 px blur (the thick standard material, not Liquid Glass) | 26 | Desktop reader side panels, desktop series side column |
| `slab.well` | `frost25` + `inset 0 1px 2px rgba(0,0,0,0.6)` | per host | Storage meter tube, progress tracks, code/pre blocks in System status |

#### 2.2.5 Light effects

- **Caustic.** A `lit` object throws light through itself onto the content beneath: an ellipse 120 % × 70 % of the object's size, offset 8 px along the light direction (down-right at 135°), filled with `glacier` at 14 % alpha, blurred 18 px, blend `screen`. It only exists when content (not black) is under the object, and it brightens to 22 % while the object is pressed. On Flutter it is a `CustomPaint` behind the button; on web a `::before` on the button's wrapper with `mix-blend-mode: screen`.
- **Specular sweep.** When glass materialises (enters) and when a lit object becomes enabled, a 40 px band of `rgba(255,255,255,0.18)` crosses it along the light angle from the lit corner to the far corner in 520 ms `ease.light`, masked to the shape. At most one sweep plays on screen at a time; later requests within 300 ms are dropped.
- **Dispersion.** T4 and T5 rims split the refracted backdrop into three channels offset 0 / 0.6 / 1.2 px (T4) or 0 / 1.2 / 2.4 px (T5) along the displacement vector, so the rim of a menu over a cover shows a thin red and blue fringe. Web: three `feDisplacementMap` passes at scale × 1.00 / 1.02 / 1.04 isolated by `feColorMatrix` and recombined with `feBlend mode="screen"` (tier A only). Flutter: `liquid_glass_widgets` 1.7.2 `LiquidGlassSettings.chromaticAberration` 0.35 (T4) and 0.5 (T5, the library default); 0 for T1–T3 (the library's default of 0.5 is too iridescent for small controls on black).
- **Press glow.** Every glass object "illuminates from within" under the finger: a radial gradient `rgba(255,255,255,0.16)` 140 px around the contact point, in over `glow.in` 150 ms, out over `glow.out` 60 ms. On lit glass the glow is glacier-tinted `rgba(191,234,255,0.22)`.
- **Lensing on arrival.** A glass object enters by animating its displacement scale 0 → 1 over `materialize` 250 ms while its opacity goes 0 → 1 over the first 120 ms: it bends light into place rather than fading in. Exits run the reverse over `dematerialize` 350 ms.

#### 2.2.6 Material rules

1. Glass is the control layer only: bars, buttons, capsules, menus, sheets, toasts, the listen window. Covers, pages, rows and text are content.
2. No glass on glass. Controls placed on a glass surface use `fill1–4` and vibrancy labels. A sheet's buttons are B5 fills, not glass buttons.
3. At most two stacked glass layers anywhere (for example tab bar under a partial sheet). A third layer forces the lower one to `solid` for the duration.
4. One `lit` object per screen. A sheet or alert may have its own lit button; while it is up, the screen's lit object drops to `regular` (its caustic fades over 180 ms).
5. Glass siblings in one bar share one sampling container (web: one `backdrop-filter` element with children cut out by `clip-path`; Flutter: one `LiquidGlassLayer` / `GlassContainer` group), so they morph into each other and never sample each other.
6. Glass never goes inside a scrolling list (the reader strip, a grid). Glass floats above scroll views. The only exception is Apple's transient-control rule: a chip, slider thumb or toggle knob becomes T1 glass *while it is being dragged*.

### 2.3 Typography

#### 2.3.1 Families (Google Fonts, all SIL Open Font License 1.1)

| Role | Family | Axes kept | License | Delivery |
|---|---|---|---|---|
| Every UI string, display and text | **Google Sans Flex** | `opsz 6–144`, `wght 1–1000`, `ROND 0–100`, `GRAD 0–100` (pin `wdth 100`, `slnt 0`) | OFL-1.1 (`google/fonts/ofl/googlesansflex/OFL.txt`) | Web: `next/font/google` `Google_Sans_Flex({ subsets: ['latin'], axes: ['ROND','GRAD','opsz'], variable: '--font-glass-sans', preload: false })`. Flutter: bundled subset `assets/fonts/GoogleSansFlexMM.ttf` (Latin + Latin Extended + punctuation, instanced with fonttools `varLib.instancer wdth=100 slnt=0`), budget ≤ 720 KB TTF; if the measured subset is over budget, pin `GRAD=0` too and drop the grade rule below |
| Numerals in keycaps, page counters, ids, sizes | **Google Sans Code** | `wght 300–800` | OFL-1.1 | Same two routes, family `GoogleSansCodeMM` |
| Novel reader (serif default) | **Literata** | `opsz 7–72`, `wght 200–900`, italic | OFL-1.1 | Same two routes, family `LiterataMM`, italic file included (bylines, emphasis) |
| Novel reader (sans option) | Google Sans Flex at text optical size | as above | as above | Shared file |
| CJK titles (Hangul, kana, Han) | System fallback on iOS/Android (Apple SD Gothic Neo, Noto CJK); web `Noto_Sans_KR`, `Noto_Sans_JP`, `Noto_Sans_SC` with `preload: false` appended to the stack | `wght` | OFL-1.1 | Never bundled on mobile |

Every OFL.txt ships with the app (`LicenseRegistry.addLicense` on Flutter, `/licenses` page on web). Web stack: `var(--font-glass-sans), "Noto Sans KR", "Noto Sans JP", "Noto Sans SC", system-ui, sans-serif`. `font-optical-sizing: auto` on web; Flutter passes `FontVariation('opsz', fontSize)` in every style. SF Pro is deliberately **not** used even on iOS: one family on all four platforms keeps the skin one object, and SF cannot ship on Android or the web.

#### 2.3.2 Material-aware axes

Type is part of the material, so two axes follow the glass:

- **ROND follows thickness.** Text set *on* glass uses `ROND = 20 × tier` (T1 20, T2 40, T3 60, T4 80, T5 100). A label on a thin pane is crisp; a title inside the listen window is fully rounded. Text on content uses the role's own ROND below.
- **GRAD follows the backdrop.** Labels on glass add `GRAD = round(40 × Lb)` using the same `Lb` as the legibility dim (§2.1.7). Grade thickens strokes without changing advance widths, so nothing reflows while a reader capsule slides from a black panel onto a white one; it animates with the dim over 400 ms.
- **Bold Text** (iOS/Android accessibility, `MediaQuery.boldTextOf`; web has no signal) adds `wght + 100` and `GRAD + 20` to every role.

#### 2.3.3 Scale per breakpoint

Size / line height in px; tracking in em. Weights are `wght` axis values (the nearest `FontWeight` is set too for fallback and semantics). Breakpoints: phone `< 600`, tablet `600–1023`, desktop `≥ 1024`, wide `≥ 1600`.

| Role | Phone | Tablet | Desktop | Wide | wght | ROND | Tracking | Used for |
|---|---|---|---|---|---|---|---|---|
| `type.display` | 40/44 | 48/52 | 64/68 | 76/80 | 700 | 100 | −0.030 | Home spotlight title, Wrapped headlines, the typed Home greeting on desktop |
| `type.largeTitle` | 34/40 | 38/44 | 44/50 | 48/54 | 680 | 100 | −0.022 | Screen titles (Library, Sources, Settings…), series title on phone, typed greeting on phone |
| `type.title1` | 28/34 | 30/36 | 32/38 | 34/40 | 660 | 80 | −0.018 | Series title on desktop side column, sheet titles at large detent, empty-state titles |
| `type.title2` | 22/28 | 24/30 | 26/32 | 26/32 | 640 | 60 | −0.012 | **H3 section headers** (rails, grouped sections) with the letter reveal |
| `type.title3` | 20/25 | 20/26 | 22/28 | 22/28 | 620 | 50 | −0.008 | Card titles in rows, alert titles, sheet titles at medium detent |
| `type.headline` | 17/22 | 17/22 | 16/22 | 16/22 | 600 | 30 | −0.004 | Row titles, button labels, poster titles (2 lines) |
| `type.body` | 17/24 | 17/24 | 16/24 | 16/24 | 420 | 0 | 0 | Descriptions, synopsis, settings explanations |
| `type.callout` | 16/21 | 16/22 | 15/21 | 15/21 | 440 | 0 | 0 | Inline notices, toasts, recap prose |
| `type.subhead` | 15/20 | 15/20 | 14/20 | 14/20 | 460 | 10 | +0.002 | Meta lines ("Ch 41 of 120 · 3 new"), list subtitles |
| `type.footnote` | 13/18 | 13/18 | 13/18 | 13/18 | 460 | 10 | +0.006 | Helper text, timestamps, footnotes |
| `type.caption1` | 12/16 | 12/16 | 12/16 | 12/16 | 500 | 30 | +0.010 | Poster meta, chart axes |
| `type.caption2` | 11/13 | 11/14 | 11/14 | 11/14 | 540 | 30 | +0.020 | Badges, tab labels on phone |
| `type.eyebrow` | 12/16 | 12/16 | 12/16 | 12/16 | 620 | 40 | +0.080, uppercase | "FOR YOU", "PREVIOUSLY ON", "CHAPTER 12" |
| `type.stat` | 48/48 | 56/56 | 72/72 | 80/80 | 640 | 100 | −0.030, `tnum` | Stats numbers, Wrapped figures, streak count |
| `type.mono` | 13/18 | 13/18 | 13/18 | 13/18 | 500 (Code) | n/a | 0, `tnum` | Keycaps, "12 / 64", sizes "412 MB", ids |
| `type.monoSmall` | 11/14 | 11/14 | 11/14 | 11/14 | 500 (Code) | n/a | +0.02 | Mono inside badges |

Heading colours: titles `label`; on hover or focus of an interactive heading (rail header with "See all"), the colour transitions `label2 → label` and the trailing chevron materialises, over 240 ms `ease.fade` (the owner's "smooth colour transition on hover/state"). Responsive sizes on web are written as `clamp()` between the phone and desktop values, e.g. `type.title2` = `clamp(1.375rem, 1.1rem + 0.8vw, 1.625rem)`, so browser text zoom still works (all sizes in `rem`).

#### 2.3.4 Mobile text scale

Flutter's iOS engine turns Dynamic Type into one linear factor `s` (xS 0.82 … AX5 3.12); Android's font scale runs 0.85–2.0. Body roles scale linearly. Title roles scale by `base × (1 + (s − 1) × 0.6)`, capped, so large text grows readable without the screen title eating the screen. No role ever renders below 11 px.

| Role | s 0.85 | 1.0 | 1.15 | 1.3 | 1.5 | 2.0 | 3.12 (AX5) |
|---|---|---|---|---|---|---|---|
| display (cap 64) | 36 | 40 | 44 | 47 | 52 | 64 | 64 |
| largeTitle (cap 56) | 31 | 34 | 37 | 40 | 44 | 54 | 56 |
| title1 (cap 48) | 25 | 28 | 31 | 33 | 36 | 45 | 48 |
| title2 (cap 40) | 20 | 22 | 24 | 26 | 29 | 35 | 40 |
| title3 (cap 36) | 18 | 20 | 22 | 24 | 26 | 32 | 36 |
| headline (linear, cap 40) | 14 | 17 | 20 | 22 | 26 | 34 | 40 |
| body (linear, cap 53) | 14 | 17 | 20 | 22 | 26 | 34 | 53 |
| callout | 14 | 16 | 18 | 21 | 24 | 32 | 50 |
| subhead | 13 | 15 | 17 | 20 | 22 | 30 | 47 |
| footnote | 11 | 13 | 15 | 17 | 20 | 26 | 41 |
| caption1 | 11 | 12 | 14 | 16 | 18 | 24 | 37 |
| caption2 | 11 | 11 | 13 | 14 | 16 | 22 | 34 |

Line heights keep their ratio. Layout rules by scale: at `s ≥ 1.3` poster titles go from 2 lines to 3, rails show 2.3 posters per phone width instead of 3.3, and the tab bar hides labels (a long-press on a tab shows the label in a T2 HUD capsule above the finger, iOS large-content-viewer style). At `s ≥ 1.5` every sheet opens at its large detent and grouped rows stack their trailing value under the title. The readers ignore the OS scale for the page itself (manhwa is images; novels have their own size control) but scale their chrome.

#### 2.3.5 Novel reader type

| Control | Range | Step | Default phone / desktop |
|---|---|---|---|
| Face | Literata (serif) / Google Sans Flex (sans) | — | Literata |
| Size | 14–30 px | 1 | 19 / 20 |
| Line height | 1.30–2.20 | 0.05 | 1.70 |
| Measure | 48–88 ch | 2 | phone: full width minus 24 px margins; desktop 66 ch |
| Paragraph spacing | 0–1.2 em | 0.1 | 0.4 em |
| Character spacing | −0.02 to +0.10 em | 0.01 | 0 |
| Word spacing | 0 to +0.30 em | 0.02 | 0 |
| Weight | Literata `wght` 380 (regular) / 520 (Bold Text on) | — | 380 |
| Justify + hyphenate | on / off (`hyphens: auto`, `text-wrap: pretty`) | — | off (ragged right) |

Literata's `opsz` follows the size; the chapter title uses `opsz 72, wght 560`.

### 2.4 Spacing

Base unit 4 px.

| Token | px | Token | px |
|---|---|---|---|
| `space.0` | 0 | `space.6` | 24 |
| `space.half` | 2 | `space.8` | 32 |
| `space.1` | 4 | `space.10` | 40 |
| `space.1h` | 6 | `space.12` | 48 |
| `space.2` | 8 | `space.16` | 64 |
| `space.3` | 12 | `space.20` | 80 |
| `space.4` | 16 | `space.24` | 96 |
| `space.5` | 20 | | |

| Layout token | Phone | Tablet | Desktop | Wide |
|---|---|---|---|---|
| `layout.margin` (screen side margin) | 16 (20 at width ≥ 390) | 28 | 40 from the sidebar's right edge | 56 |
| `layout.gutter` (grid gap) | 12 | 16 | 20 | 24 |
| `layout.section` (between rails / groups) | 32 | 40 | 48 | 56 |
| `layout.contentMax` | — | — | 1440 | 1680 |
| `layout.touchMin` | 44 | 44 | 44 (32 visual allowed with 44 hit area for pointer) | 44 |
| `layout.controlGap` | 8 | 8 | 16 between pointer targets | 16 |
| `layout.tabBarInset` | 21 (sides and bottom, above the safe area) | 21 | n/a | n/a |
| `layout.sheetInset` | 8 | 12 | n/a (desktop sheets are centred panels) | n/a |
| `layout.sidebarInset` | n/a | 12 | 12 | 16 |

### 2.5 Radius and shape

Controls are capsules. Containers are concentric: `r_inner = max(r_outer − padding, 4)`. Containers use continuous corners: `corner-shape: squircle` on web (Chromium 139+; Safari and Firefox fall back to circular arcs, accepted), `RoundedSuperellipseBorder` / `ClipRSuperellipse` in Flutter 3.44.

| Token | px | Use |
|---|---|---|
| `radius.capsule` | 9999 | Every button, chip, segmented control, search field, tab bar, toast, badge, capsule toolbar |
| `radius.xs` | 6 | Keycaps, OCR hit boxes, speaker tint bands |
| `radius.thumb` | 8 | Thumbnails ≤ 48 px (continue strip, list covers) |
| `radius.poster` | 14 | Posters and cover art everywhere (concentric with a 26 px card at 12 px padding) |
| `radius.md` | 20 | Grouped lists, inputs that are not capsules (textarea), menu rows (26 − 6) |
| `radius.lg` | 26 | Cards, menus, popovers, alerts, context previews |
| `radius.xl` | 34 | Desktop dialogs and side sheets, the desktop listen window |
| `radius.2xl` | 44 | Phone listen window, Wrapped frames, share cards (at 1080 px export: 132) |
| `radius.sheet` | device corner radius − `layout.sheetInset` | Partial sheets. iOS: the screen radius from `liquid_glass_widgets`' device table (fallback 47 → 39). Android 12+: `WindowInsets.getRoundedCorner(POSITION_BOTTOM_LEFT).radius` in dp − 8 (fallback 28 → 20). Web: 36 |
| `radius.sheetFull` | 36 top, 0 bottom | Sheets at the large detent (solid, attached) |
| `radius.sidebar` | 28 | Desktop sidebar (inset 12 → its rows are 28 − 8 = 20) |
| `radius.avatar` | 50 % | People are circles (profiles, friends, voices); things are squircles |

### 2.6 Elevation: the layer stack

Elevation in Prism is distance from the content plane plus thickness, not shadow depth alone.

| z | Layer | What lives here | Material |
|---|---|---|---|
| 0 | Canvas | `#000000` | none |
| 0.5 | Ambient field | Light pools from the art (§2.1.8) | none |
| 1 | Content | Covers, rails, rows, pages, prose, content slabs | `surface1–3`, `slab.*` |
| 2 | Scroll edges | Soft fades under top controls and above the tab bar; hard edges under pinned headers | `scrimEdge*` |
| 3 | Controls | Tab bar, sidebar, top orbs and title capsule, reader capsules, bottom accessory | T2–T3 |
| 4 | Overlays | Menus, context menus, partial sheets, popovers, command palette | T4 |
| 5 | Interruptions | Alerts, 18+ confirm, restore confirm, skin-switch confirm | T4–T5 + `dimModal` |
| 6 | HUD | Toasts, brightness and speed HUDs, drag previews | T2 |

When a layer ≥ 4 opens, the content plane **recedes**: scale 0.94 (phone) / 0.98 (desktop), `blur(8px)`, brightness 0.70, corner radius 0 → 20 on phone, on `spring.sheet`. Only the bottom-most open overlay makes the page recede; a second sheet on top dims the first to brightness 0.70 and scales it by 0.9165 with a 2 % upward shift (the iOS stacking numbers).

### 2.7 Blur

| Token | px (CSS blur radius = Flutter sigma) | Use |
|---|---|---|
| `blur.t1` … `blur.t5` | 2 / 6 / 10 / 22 / 32 | Glass backdrops by thickness (§2.2.2) |
| `blur.recede` | 8 | Content plane behind an overlay |
| `blur.edge` | 6 | Soft scroll edges |
| `blur.heroBackdrop` | 60 | Detail and recap backdrops (the cover at `w=720`, scaled 1.2×) |
| `blur.ambient` | 120 | Ambient field pools |
| `blur.letter` | 10 → 0 | Heading reveal per letter |
| `blur.restartOut` | 0 → 40 | Skin switch outgoing |
| `blur.lineGuide` | 6 | Novel line guide bands |

### 2.8 Borders, rims and focus

| Token | Value | Use |
|---|---|---|
| `border.rim` | 1 physical px, gradient per §2.2.1 | Every glass object |
| `border.hair` | 0.5 px `separator` | Inside grouped lists and glass |
| `border.content` | 1 px `rgba(255,255,255,0.06)` inset | Posters and cover art (stops dark covers dissolving into black) |
| `border.focus` | 2 px `glacier` outline, offset 3 px, plus `0 0 0 6px rgba(143,216,255,0.18)` | Keyboard focus everywhere; the ring's radius is the element's radius + 3 so it stays concentric |
| `border.error` | 1 px `danger` + `inset 0 0 0 1px rgba(255,122,133,0.25)` | Invalid inputs |
| `border.selected` | 2 px `glacier` inside the poster edge + 4 px `rgba(143,216,255,0.22)` outer glow | Selected posters and rows in select mode |

### 2.9 Iconography

**Phosphor** everywhere: `@phosphor-icons/react` 2.1.10 (MIT) on web (with `optimizePackageImports` added and `@phosphor-icons/react/ssr` in server components) and `phosphor_flutter` 2.1.0 (MIT) on mobile, at verified 1,512/1,512 parity.

| Context | Weight | Sizes |
|---|---|---|
| Default (glass and content) | Regular (≈ 1.5 px stroke at 24) | 20 in rows and buttons, 22 in orbs and tab bar, 16 inline with footnote text |
| Selected / active (tab, sidebar row, toggled favourite, active filter) | Duotone (secondary layer at 0.2), morphing to Fill for 120 ms on press | same |
| Large ornamental (empty states, onboarding, stats tiles) | Light (≈ 1.1 px) | 40 and 56 |

Icons on glass are **monochrome `label`** (Apple: symbols on glass stay monochrome). Colour comes only from state: `glacier` for the selected tab and links, semantic colours for status glyphs, `iris` for AI glyphs, `bloom` for social glyphs, `flare` for the streak.

Core glyph map (Phosphor names): Home `house-simple`, Library `books`, Sources `compass`, You = the profile avatar, Search `magnifying-glass`, Updates `bell-simple` / `bell-simple-ringing`, Downloads `cloud-arrow-down`, Collections `stack-simple`, History `clock-counter-clockwise`, Bookmarks `bookmark-simple`, For you `sparkle`, Stats `chart-line-up`, Streak `flame`, Friends `users-three`, Settings `gear-six`, Status `pulse`, Back `caret-left`, Close `x`, More `dots-three`, Play `play`, Pause `pause`, Previous chapter `skip-back`, Next chapter `skip-forward`, Settings in reader `sliders-horizontal`, Fullscreen `corners-out` / `corners-in`, Bookmark `bookmark-simple`, Favourite `star`, Follow `bell-simple` (Following: `bell-simple-ringing` Fill), Pin `push-pin` / `push-pin-slash`, Download `download-simple`, Saved `check-circle`, Retry `arrow-clockwise`, Lock `lock-simple`, Voice `user-sound`, Headphones `headphones`, Speed `gauge`, Sleep `moon-stars`, Type `text-aa`, Contents `list-numbers`, Brightness `sun`, Warmth `thermometer-hot`, Auto-scroll `arrows-down-up` plus the custom `strip-scroll`, Soundscape `waveform`, Share `share-network`, Reaction `smiley`, Recommend `paper-plane-tilt`, Filter `funnel-simple`, Sort `sort-ascending`, Grid `squares-four`, List `rows`, Select `check-square-offset`, Keyboard `keyboard`, Offline `cloud-slash`, Warning `warning`, Error `warning-octagon`.

Custom glyphs (drawn on Phosphor's 256 grid in Regular, Duotone and Fill; web React components from SVG; Flutter one TTF built with `fantasticon` at build time): `mm-mark` (the MM column), `strip-scroll` (vertical strip with a down chevron), `panel-focus` (a panel in corner brackets), `bubble-search` (speech bubble with a lens: Dialogue search), `age-gate` (a seal with "18"), `voice-31` (`user-sound` with a stacked badge: the voice gallery).

### 2.10 Motion

#### 2.10.1 Principles

1. **Springs for everything that moves**; timed curves only for opacity, colour and light (fades, sweeps, glows). Default bounce 0; bounce above 0.35 never ships.
2. **Materialise, don't fade.** Glass enters by bending light in (displacement 0 → 1) and leaves by un-bending.
3. **Everything is interruptible and keeps its velocity** (§2.10.6).
4. **Presses grow and light up; they never dim.**
5. **Light moves slowly, objects move quickly.** Ambient field and key-light changes take 400–900 ms; objects settle in 250–500 ms.

#### 2.10.2 Springs

`{ms, bounce}` is the token; stiffness and damping are the Apple conversion with mass 1 (`k = (2π/d)²`, `c = 4π(1 − bounce)/d`), which Flutter's `SpringDescription.withDurationAndBounce` implements exactly.

| Token | ms | bounce | stiffness | damping | Used for |
|---|---|---|---|---|---|
| `spring.interactive` | 150 | 0.14 | 1754.6 | 72.05 | Anything tracking a finger or pointer: drag followers, droplet while dragged, scrub thumb, flex stretch |
| `spring.press` | 250 | 0.15 | 631.7 | 42.73 | Press growth and release of every glass control |
| `spring.flex` | 220 | 0.20 | 815.7 | 45.70 | The jelly stretch of a pressed control along the drag axis |
| `spring.scrub` | 250 | 0.30 | 631.7 | 35.19 | Scrubber thumb stretch and the magnifier lens |
| `spring.snappy` | 500 | 0.15 | 157.9 | 21.36 | Toggles, segmented thumbs, chips, tab changes inside a page, poster lift |
| `spring.smooth` | 500 | 0 | 157.9 | 25.13 | Pushes, zoom transitions, route changes, the default |
| `spring.bouncy` | 500 | 0.30 | 157.9 | 17.59 | Celebrations only: add to library, reaction pop |
| `spring.celebrate` | 600 | 0.35 | 109.7 | 13.61 | Streak flame ignite, Wrapped number landing |
| `spring.morph` | 375 | 0.27 | 280.7 | 24.46 | Menu, context menu, sheet and search blooming out of their trigger |
| `spring.tab` | 450 | 0.20 | 195.0 | 22.34 | The tab droplet travelling between tabs; sidebar selection lozenge |
| `spring.sheet` | 350 | 0 | 322.3 | 35.90 | Sheet present and dismiss; page recede |
| `spring.sheetSnap` | 400 | 0.10 | 246.7 | 28.27 | Sheet settling on a detent after a fling |
| `spring.minimize` | 400 | 0 | 246.7 | 31.42 | Tab bar and reader toolbar minimise and restore |
| `spring.chrome` | 350 | 0.05 | 322.3 | 34.11 | Reader chrome capsules showing and hiding |
| `spring.page` | 420 | 0.08 | 223.8 | 27.53 | Paged manga and novel page settle after a swipe |
| `spring.panel` | 450 | 0.10 | 195.0 | 25.13 | Panel-by-panel camera moves |
| `spring.letter` | 420 | 0.12 | 223.8 | 26.33 | Each letter of the heading reveal |
| `spring.tilt` | 300 | 0 | 438.6 | 41.89 | Key-light angle and poster tilt following gyro or pointer |
| `spring.drop` | 320 | 0.25 | 385.5 | 29.45 | Splash droplet landing, pull-to-refresh droplet pop |
| `spring.lens` | 600 | 0.18 | 109.7 | 17.17 | Splash lens growing, Wrapped frame opening |
| `spring.meniscus` | 700 | 0.22 | 80.6 | 14.00 | Liquid fills settling: storage meter, download progress, streak ring |

#### 2.10.3 Timed values

| Token | Value | Use |
|---|---|---|
| `dur.fadeIn` / `dur.fadeOut` | 180 / 120 ms, `ease.fade` / `ease.exit` | Opacity-only changes (content swaps, labels) |
| `dur.glowIn` / `dur.glowOut` | 150 / 60 ms, linear | Press glow |
| `dur.materialize` / `dur.dematerialize` | 250 / 350 ms, `ease.fade` | Glass lensing in and out |
| `dur.sweep` | 520 ms, `ease.light` | Specular sweep |
| `dur.caustic` | 400 ms, `ease.fade` | Caustic appear, brighten, fade |
| `dur.field` | 900 ms, `ease.fade` | Ambient field cross-fade; page-tint cross-fade in the reader |
| `dur.dim` | 400 ms, `ease.fade` | Legibility dim and GRAD adapting to a new backdrop |
| `dur.coverIn` | 280 ms, `ease.fade` | Cover image fade-in on decode (scale 1.02 → 1 on `spring.smooth` alongside) |
| `dur.reduced` | 200 ms, `ease.fade` | The universal Reduce Motion cross-fade |
| `dur.typeChar` | 50 ms per character | Main headline typing reveal (owner) |
| `dur.letterStagger` | 22 ms | Heading reveal stagger (owner) |
| `dur.skeleton` | 1100 ms loop, `ease.light` alternate | Skeleton pulse |
| `dur.tooltip` | 0 / 150 / 600 ms | visionOS hover delays: none (highlight), short (tab-bar hints), long (tooltips) |
| `dur.chromeIdle` | 3000 ms | Reader chrome idle hide after a tap-open |
| `dur.toast` | 4000 ms (info) / 6000 ms (with action) / 10000 ms (skin undo) | Toast lifetime; paused while hovered or focused |
| `dur.hud` | 600 ms linger after release | Brightness, speed and zoom HUDs |
| `dur.fieldDrift` | 40 s loop | Ambient field drift |
| `ease.fade` | `cubic-bezier(0.2, 0, 0, 1)` | Opacity in |
| `ease.exit` | `cubic-bezier(0.4, 0, 1, 1)` | Opacity out |
| `ease.light` | `cubic-bezier(0.4, 0, 0.2, 1)` | Specular sweep, skeleton pulse |

#### 2.10.4 Material animations

| Name | Spec |
|---|---|
| **Materialize** | Displacement scale 0 → 1 over 250 ms; opacity 0 → 1 over the first 120 ms; blur radius from 0 to the tier value over 250 ms; one specular sweep starts at 80 ms |
| **Dematerialize** | The reverse over 350 ms; the object's content fades out over the first 150 ms |
| **Press** | Scale `1 + min(17, 0.35 × longest) / longest` (a 44 px orb reaches 1.35, a 56 px orb 1.30, a 132 px pill 1.13) on `spring.press`; glow in 150 ms; displacement × 1.25 (the glass "thickens" under the finger) |
| **Flex** | While pressed and dragged, stretch along the drag axis `scaleX = 1 + 0.06 × clamp(dx/w, −1, 1)` with the cross axis at `1/√scaleX`, on `spring.interactive`; released on `spring.flex` |
| **Droplet** | Selection indicators (tab bar, segmented, sidebar) are T1 clear glass droplets. Travel on `spring.tab`; while dragged they stretch `scaleX = 1 + clamp(|vx| / 2000, 0, 0.25)` and turn `clear` (lifted) |
| **Meniscus** | Liquid fills (storage meter, progress bars ≥ 6 px, streak ring) move their end on `spring.meniscus`; the fill's leading edge is a 4 px convex cap whose curvature grows with velocity and flattens at rest |
| **Recede** | Content plane behind overlays: scale 0.94, blur 8 px, brightness 0.70, radius 0 → 20 on `spring.sheet` |
| **Bloom** | A menu or sheet grows from its trigger's frame: shared glass boundary interpolates position and size on `spring.morph`; content fades in over the last 40 %; thickness snaps up a tier as it grows (§2.2.2) |

#### 2.10.5 Stagger rules

| Group | Step | Cap | Order |
|---|---|---|---|
| Letters (heading reveal) | 22 ms | 60 graphemes; longer headings reveal per word at 40 ms | reading order |
| Words (long headings, Wrapped lines) | 40 ms | 24 words | reading order |
| Grid items (first load) | 18 ms | the first 12 items; the rest appear with item 12 | row-major, then by distance from the top-left |
| Rail cards (first reveal of a rail) | 26 ms | 6 cards | left to right |
| List rows | 14 ms | 16 rows | top to bottom |
| Rails on Home | 60 ms between rails | 5 rails | top to bottom |
| Chips | 16 ms | 10 | left to right |

Staggers run only on the first reveal of a screen or a rail entering the viewport; refreshes, back navigation and pagination never re-stagger. Each staggered item animates opacity 0 → 1 (`dur.fadeIn`) and y 12 → 0 px on `spring.snappy`.

#### 2.10.6 Interruptibility

- Every spring retargets from its current value **with its current velocity** (web: physics springs, never `visualDuration`, see §9.1; Flutter: `animateWith(SpringSimulation(spring, value, target, velocity))`).
- A gesture can grab anything mid-flight: a sheet halfway to its detent follows the finger from where it is; a tab droplet in transit can be caught and dragged.
- Opacity fades reverse from their current value; they never restart from 0.
- A heading reveal interrupted by a data change jumps unrevealed letters to rest with a 120 ms fade.
- Navigation pushes queued faster than 120 ms apart collapse: the intermediate screen is skipped and the transition goes straight to the last target.
- Fling projection picks sheet detents and carousel stops: `target = position + (velocity_px_per_s / 1000) × r / (1 − r)` with Apple's deceleration rate `r = 0.998`, which is `position + 0.499 × velocity_px_per_s` (a 1,000 px/s fling projects 499 px further).

#### 2.10.7 Reduced motion, reduced transparency, increased contrast

| Behaviour | Default | Reduce Motion | Reduce Transparency / Solid glass | Increase Contrast |
|---|---|---|---|---|
| Press | Growth + glow + displacement | Glow only (150 / 60 ms) | Growth + glow | Growth + 1 px border brightens |
| Flex, droplet stretch, meniscus curvature | On | Off (straight edges, no stretch) | On | On |
| Materialize / dematerialize | Lensing + sweep | 200 ms opacity; no sweep | 200 ms opacity (no lensing to animate) | same as transparency |
| Bloom out of trigger | `spring.morph` along the path | 200 ms cross-fade in place | Bloom kept, solid fill | same |
| Sheets | Slide on `spring.sheet` + recede | 200 ms fade at the target detent + 16 px translate; no recede; the finger still drags | Solid sheets, recede kept without blur | same |
| Push / cover zoom | Shared-element zoom on `spring.smooth` | 200 ms cross-fade | Kept | Kept |
| Tab droplet | Travels | Jumps; cross-fades in 150 ms | Kept | Kept |
| Tab bar minimise | Morph | 150 ms cross-fade between the two states | Kept | Kept |
| Key light following gyro/pointer; field drift; poster tilt | On | Fixed 135°; frozen field; no tilt | On | Fixed light |
| Heading letter reveal / 50 ms typing | On | Whole line fades in over 200 ms; typed text appears at once | On | On |
| Novel page turn | Slide + curl option | 200 ms cross-fade | Kept | Kept |
| Auto-scroll, drag-scroll, pinch | User motion | Kept | Kept | Kept |
| Haptics, sounds | On if enabled | Kept | Kept | Kept |
| Ambient field | 26 % pools, 120 px blur | Kept, static | Field kept (it is content-layer light) | Field at 12 % so rims and borders dominate |
| Caustics, dispersion | On | Caustic static (no brighten); dispersion kept | Off | Off |

### 2.11 Haptics vocabulary

Glass haptics are **texture**: high sharpness (0.7–1.0), low to medium intensity (0.3–0.7), frequent small ticks, like a fingertip on hard glass. One dispatcher per platform (`skins/glass/haptics.dart`, `skins/glass/haptics.ts`) maps the shared `HapticEvent` names from `design/contract.json` to calls, honours the in-app Haptics toggle (default on), rate-limits to one event per 40 ms (ticks) and one per 120 ms (impacts), and stays on under Reduce Motion. iOS and Android use `gaimon` 1.5.0 for named impacts and the AHAP patterns (auto-converted to Android waveforms), `haptic_feedback` 0.6.5 for `selection`, and the `mm/haptics` method channel for Android 14 constants (API guards: `SEGMENT_TICK`, `TOGGLE_ON/OFF`, `GESTURE_THRESHOLD_ACTIVATE` need API 34; `CONFIRM`, `REJECT`, `GESTURE_END` need API 30; older devices use the listed fallback). Web: Android Chrome only, through `navigator.vibrate` for five events; iOS Safari and desktop get none.

| `HapticEvent` | Meaning | iOS | Android (API 34 / fallback) | Web (Android Chrome) |
|---|---|---|---|---|
| `tab.select` | A tab, sidebar row or segmented segment becomes selected | selection | `SEGMENT_TICK` / `CLOCK_TICK` | — |
| `tab.scrub` | Droplet dragged across a tab boundary | selection | `SEGMENT_TICK` / `CLOCK_TICK` | — |
| `detent.tick` | A slider, stepper, speed dial or scrubber passes a step; picker wheel row | selection | `SEGMENT_TICK` / `CLOCK_TICK` | — |
| `toggle.on` | Switch on | impact light, sharpness 0.9 (gaimon `light`) | `TOGGLE_ON` / `VIRTUAL_KEY` | `vibrate(10)` |
| `toggle.off` | Switch off | selection | `TOGGLE_OFF` / `CLOCK_TICK` | — |
| `press.lit` | The screen's lit action pressed | impact soft 0.7 | `VIRTUAL_KEY` | — |
| `press.icon` | An orb or chip pressed (touch down) | none (the glow is the feedback) | none | — |
| `menu.bloom` | Long-press preview or menu opens | impact medium | `LONG_PRESS` | `vibrate(18)` |
| `reorder.lift` / `reorder.pass` / `reorder.drop` | Drag-reorder pick up / pass a slot / drop | medium / selection / light | `DRAG_START` / `SEGMENT_TICK` / `VIRTUAL_KEY` | — |
| `sheet.detent` | Sheet settles on a partial detent | selection | `GESTURE_END` / none | — |
| `sheet.full` | Sheet reaches the large detent (turns solid) | impact soft 0.5 | `GESTURE_END` / none | — |
| `threshold.cross` | A drag crosses a commit line (dismiss, swipe action, pull-to-continue) | impact rigid 0.6 | `GESTURE_THRESHOLD_ACTIVATE` / `CONTEXT_CLICK` | — |
| `threshold.back` | The same drag crosses back | impact light 0.4 | `GESTURE_THRESHOLD_DEACTIVATE` / `VIRTUAL_KEY` | — |
| `refresh.armed` / `refresh.done` | Pull-to-refresh droplet pops / data arrived | impact rigid 0.5 / selection | `GESTURE_THRESHOLD_ACTIVATE` / `CLOCK_TICK` | — |
| `reader.page` | Scrubber passes a page; paged mode turns a page by tap or key | selection | `CLOCK_TICK` | — |
| `reader.tenth` | Scrubber passes a 10 % mark | impact light 0.5 | `VIRTUAL_KEY` | — |
| `reader.chapterEnd` | The next-chapter card locks in at the end of a chapter | AHAP `ripple` | converted waveform | — |
| `reader.chapterCommit` | Next or previous chapter committed | impact medium 0.8 | `CONFIRM` / `KEYBOARD_TAP` | — |
| `reader.zoom` | Double-tap zoom toggles; pinch crosses 1×, 2×, 3× | impact light 0.6 | `VIRTUAL_KEY` | — |
| `reader.unlock` | Locked reader unlocked by 5 taps | impact medium | `CONFIRM` / `KEYBOARD_TAP` | — |
| `panel.step` | Panel-by-panel view moves to the next panel | selection | `SEGMENT_TICK` / `CLOCK_TICK` | — |
| `autoscroll.step` | Auto-scroll speed changes one step | selection | `SEGMENT_TICK` / `CLOCK_TICK` | — |
| `autoscroll.end` | Auto-scroll reaches the end of the loaded strip | impact rigid 0.7 | `CONTEXT_CLICK` | — |
| `ocr.hit` | Next or previous dialogue hit | selection | `CLOCK_TICK` | — |
| `library.add` | Followed / added to library / added to a collection | success | `CONFIRM` / `VIRTUAL_KEY` | `vibrate([12,60,12])` |
| `library.remove` | Unfollowed / removed | impact light 0.5 | `VIRTUAL_KEY` | — |
| `download.start` | Download queued | selection | `CLOCK_TICK` | — |
| `download.done` | A chapter or a batch finished | AHAP `meniscus` | converted | — |
| `download.fail` | A download failed | error | `REJECT` / `LONG_PRESS` | `vibrate([24,50,24])` |
| `bookmark.saved` | Bookmark saved | success | `CONFIRM` / `VIRTUAL_KEY` | — |
| `streak.plus` | Today's reading extends the streak | success, then AHAP `shimmer` 120 ms later | converted | — |
| `streak.milestone` | 7, 30, 100, 365 days | AHAP `shimmer` × 2 (180 ms apart) | converted | — |
| `reaction.sent` | Reaction placed on a chapter | AHAP `pop` | converted | — |
| `recommend.sent` | "Recommend to" sent | success | `CONFIRM` | — |
| `gate.unlock` | 18+ enabled after the hold-to-confirm completes | AHAP `unlock` | converted | — |
| `gate.holdTick` | Each 25 % of the 18+ hold | selection | `SEGMENT_TICK` / `CLOCK_TICK` | — |
| `profile.switch` | A profile is chosen in the picker | impact medium 0.7 | `CONFIRM` / `KEYBOARD_TAP` | — |
| `skin.confirm` | "Restart into Cinematic" confirmed | impact heavy | `LONG_PRESS` | — |
| `tts.play` / `tts.pause` | Narration play / pause | impact soft 0.6 / selection | `VIRTUAL_KEY` / `CLOCK_TICK` | — |
| `voice.preview` | A voice starts its self-introduction | selection | `CLOCK_TICK` | — |
| `logo.land` / `logo.settle` | Splash droplet lands / lens settles | impact soft 0.6 / AHAP `refract` | converted | — |
| `notify.success` / `notify.warning` / `notify.error` | Task completed / needs attention / failed | success / warning / error | `CONFIRM` / `KEYBOARD_TAP` / `REJECT` | error only: `vibrate([24,50,24,50,24])` |

Never haptic: plain navigation taps, scrolling, reader chrome show/hide, hover, focus, toasts appearing, page turns inside the continuous strip.

**AHAP patterns** (transients `T` and continuous `C` only, so gaimon's Android converter matches; I = intensity, S = sharpness, times in s):

| Pattern | Events |
|---|---|
| `unlock` | C@0.000 dur 0.120 I0.40 S0.85; T@0.120 I0.70 S0.90 |
| `shimmer` | T@0.00 I0.25 S0.90; T@0.04 I0.30 S0.90; T@0.08 I0.35 S0.90; T@0.12 I0.40 S0.90; T@0.16 I0.45 S0.90 |
| `pop` | T@0.000 I0.50 S1.00 |
| `refract` | T@0.000 I0.35 S0.95; T@0.050 I0.60 S0.90 |
| `ripple` | C@0.000 dur 0.080 I0.30 S0.80; T@0.080 I0.70 S0.95 |
| `meniscus` | T@0.00 I0.40 S0.85; T@0.07 I0.55 S0.90; T@0.14 I0.70 S0.95 |

### 2.12 UI sounds: "Prism" (off by default)

A tonal set in E-major pentatonic (E5 659.25, F♯5 739.99, G♯5 830.61, B5 987.77, C♯6 1108.73, E6 1318.51 Hz), sine plus an FM bell (ratio 3.5, index 1.2), plate reverb 1.2 s at 18 % wet, so any sequence of sounds resolves. The toggle lives in Settings → Feedback ("Interface sounds", default **off**). Files are synthesised with a `sox -n synth` script (48 kHz, 16-bit mono WAV, 5 ms fades), each skin ≤ 350 KB. Playback: `flutter_soloud` 5.1.4 on mobile (`.ambient` session on iOS so the ring/silent switch mutes it), Web Audio API on web (decoded once on the first user gesture). UI sounds are suppressed while narration or the soundscape plays and never duck the user's music.

| File | Trigger (`SoundEvent`) | Recipe | Peak |
|---|---|---|---|
| `glass-tap.wav` | `tap` (lit action, orb press release) | 1.2 kHz sine, 14 ms | −28 dBFS |
| `glass-detent.wav` | `detent` (sheet detent, slider steps every 25 %) | 2.4 kHz click, 6 ms | −30 dBFS |
| `glass-toggle-on.wav` / `-off.wav` | `toggle.on` / `toggle.off` | G♯5 → B5 / B5 → G♯5, 60 ms each | −24 dBFS |
| `glass-sheet-up.wav` / `-down.wav` | `sheet.open` / `sheet.close` | sine glide 520 → 1040 Hz / reverse, 110 ms | −26 dBFS |
| `glass-add.wav` | `library.add` | E5 + B5 bell dyad, 250 ms | −18 dBFS |
| `glass-download-done.wav` | `download.done` | E5, G♯5, B5 arpeggio at 40 ms steps | −18 dBFS |
| `glass-error.wav` | `error` | B4 493.88 → G♯4 415.30 soft taps, 90 ms each | −20 dBFS |
| `glass-shimmer.wav` | `streak` | five E6 grains 40 ms apart, rising level | −20 dBFS |
| `glass-chapter.wav` | `chapter.end` (next-chapter card locks) | B5 → E6 bell, 180 ms | −22 dBFS |
| `glass-react.wav` | `reaction` | C♯6 FM bell 80 ms | −24 dBFS |
| `glass-send.wav` | `recommend` | F♯5 → C♯6 glide 140 ms | −22 dBFS |
| `glass-unlock.wav` | `gate.unlock` | E5, B5, E6 at 30 ms steps with 1.2 s air | −20 dBFS |
| `glass-logo.wav` | `logo` | E5, G♯5, B5, E6 at 22 ms steps (the letter stagger) + 1.2 s air pad | −12 dBFS |
| `glass-restart.wav` | `skin.out` | descending E6 → E5 glide, 400 ms, reverb 40 % | −18 dBFS |

---

## 3. Component catalog

Every component names its layer (content or glass), its thickness when glass, and a row for each state. States that cannot occur for a component say "n/a" with the reason. "Hover" exists only on pointer devices (`@media (hover: hover)`; Flutter `MouseRegion` on desktop-class input); on touch it is skipped. Focus rings are `border.focus` (§2.8) on every platform with a keyboard (web, iPad and Android with hardware keyboards). All touch targets are ≥ 44 × 44.

### 3.1 Buttons

**Anatomy shared by all buttons:** capsule; label `type.headline` (16/22 desktop, 17/22 phone) at `wght 620`; optional leading glyph 20 px with 8 px gap; horizontal padding 24 (L), 20 (M), 14 (S); heights L 50, M 44, S 36 (S keeps a 44 px hit area). Minimum width 88. Labels never wrap; they truncate with an ellipsis and expose the full text to assistive tech.

| ID | Variant | Layer / material | Where |
|---|---|---|---|
| B1 | **Lit** | Glass, T2 (M, S) / T3 (L), `lit` variant | The one primary action per screen: Read / Continue, Sign in, Create account, Save changes, Download N, Suggest, Check now |
| B2 | **Glass** | Glass, T2, `regular` | Secondary actions floating over content: Read all, Follow, Add to collection on the series hero; "Top" pill |
| B3 | **Plain** | Content, no container, label `glacier` | Tertiary text actions on content: See all, Mark read, Try again inline, Cancel in forms |
| B4 | **Fill** | Content-on-glass, `fill2` capsule, label `label` | Any button placed on glass (sheets, alerts, menus, the command palette), where glass-on-glass is forbidden |
| B5 | **Coral** | Glass T2, `coral` variant (inside alerts); or B3 with `danger` label on content | Destructive confirmation (Delete profile, Delete collection, Remove all downloads, Revoke) |
| B6 | **Hold** | Glass T3, `regular` with a liquid fill | Irreversible or gated actions: "I am 18 or older — Enable", "Sign out everywhere", "Restore from this file", "Delete {member}" |
| B7 | **Orb action** | Glass T2 circle, 56 px, glyph 24 | Floating creation on phone: New collection (Collections), Scroll to top (source catalogue, appears after 400 px) |

| State | B1 Lit | B2 Glass | B3 Plain | B4 Fill | B5 Coral | B6 Hold | B7 Orb |
|---|---|---|---|---|---|---|---|
| Default | `glacierDeep` 86 % body, glacier rim, white label, caustic 14 % beneath | Pane glass, `label` text | `glacier` text | `fill2`, `label` | Coral glass, white label; B3 danger text | Pane glass, label + 16 px `lock-simple` glyph leading | Pane orb, `label` glyph |
| Hover | Inner glow 0.08 at the pointer; caustic 18 %; key light swings toward the pointer | Glow 0.08 at pointer | Text underline 1 px at 3 px offset; colour `#BFEAFF` | `fill1` | Glow | Glow | Glow; lift −2 px |
| Pressed | Grows by 17 px on the longest side on `spring.press`; glacier glow at finger; caustic 22 %; haptic `press.lit`; sound `tap` | Grows; white glow; no haptic | Text `#BFEAFF` + scale 0.97 | `fill1` + scale 0.97 (content-on-glass does not grow) | Grows; coral glow | Starts the fill: a liquid band of `glacier` 24 % rises from left to right over 900 ms (`meniscus` edge), ticks `gate.holdTick` at 25/50/75 %; releasing early drains it back on `spring.meniscus`; completing fires the action + haptic | Grows to 1.30; glow |
| Focused | `border.focus` ring concentric (radius + 3) | Ring | Ring hugging the text box (radius 6) | Ring | Ring | Ring; Space or Enter held for 900 ms is the keyboard hold; a visible "Hold Space" caption2 appears under it while focused | Ring |
| Disabled | Body drops to `regular` glass (no lit colour, no caustic), label `label4`; `aria-disabled`, not in tab order | Label `label4`, no glow | `label4` | `fill4`, `label4` | n/a (a destructive action is either offered or hidden) | Label `label4`, fill disabled | Glyph `label4` |
| Loading | Label cross-fades to a 20 px ring spinner + the pending verb ("Signing in…") over 180 ms; width holds; not pressable | Same | Text swaps to the pending verb, ring 16 px leading | Same as B1 | Same | The fill stays full and pulses 0.18 ↔ 0.30 over 1100 ms while the request runs | Glyph swaps to ring |
| Selected | n/a (not a toggle) | When used as a toggle (Follow ↔ Following): glyph morphs `bell-simple` → `bell-simple-ringing` (Fill), label swaps, `spring.bouncy` pop 1 → 1.08 → 1 | n/a | n/a | n/a | n/a | n/a |
| Error | The failed action leaves the button as it was and shows a toast (§3.12) plus `notify.error`; forms show the error inline above the button | Same | Same | Same | Same | Drains with a 2 px `danger` rim flash (2 × 120 ms) | Same |
| Enter / exit | Materialize 250 ms + one specular sweep when it first becomes enabled | Materialize | Fade 180 ms | Fade | Materialize | Materialize | Materialize; exit dematerialize |

### 3.2 Icon buttons

| ID | Variant | Spec |
|---|---|---|
| IB1 | **Orb** | Glass T2 circle 44 px, glyph 22 Regular `label`. Top-bar actions, reader capsules, close in full-screen overlays |
| IB2 | **Orb group** | 2–3 orbs sharing one T2 capsule (44 tall, 44 per orb, no dividers, one sampling container). Top-right bar actions (bell + more; search + filter) |
| IB3 | **Content icon** | No container, 44 hit, glyph 20 `label2`. Row trailing actions (pin, remove, download, more) |
| IB4 | **Toggle icon** | IB1 or IB3 whose glyph morphs Regular → Fill and takes a state colour: bookmark (`glacier`), favourite star (`flare`), pin (`glacier`), follow bell (`glacier`), reaction (`bloom`) |
| IB5 | **Media orb** | `clear` glass circle 36 (44 hit) with `dimClear` under it when `Lb > 0.45`. On covers and hero art (favourite, select, quick-look) |
| IB6 | **Fill orb** | `fill2` circle 32 visual / 44 hit. Icon buttons on glass (sheet close, alert close, menu steppers) |

| State | IB1 / IB2 | IB3 | IB4 | IB5 | IB6 |
|---|---|---|---|---|---|
| Default | Pane orb | Glyph `label2` | Regular glyph, `label` / `label2` | Clear orb | `fill2` |
| Hover | Glow 0.08; tooltip after 600 ms (T2 capsule, caption1) | Glyph `label`, `fill3` circle appears 180 ms | as its host | Glow | `fill1` |
| Pressed | Grows to 1.35 (44 px); glow; for IB2 only the pressed orb grows and its neighbours shift 2 px away on `spring.flex` | `fill4` circle; scale 0.94 | as host + the morph | Grows 1.3 | scale 0.94 |
| Focused | Ring | Ring (circle) | Ring | Ring | Ring |
| Disabled | Glyph `label4`, not focusable | `label4` | `label4` | `label4` | `label4` |
| Loading | Glyph swaps to a 18 px ring spinner (`glacier`) | Same | Same | Same | Same |
| Selected | Glyph Duotone `glacier` (e.g. reader settings open, cinema on) | Glyph `glacier` | Fill glyph + state colour; `spring.bouncy` 1 → 1.18 → 1; for favourite a `flare` caustic flashes 400 ms; haptic per event (`bookmark.saved`, `library.add`) | Fill glyph | Glyph `glacier` |
| Error | Glyph `danger` for 1.2 s + toast | Same | Reverts the morph on `spring.snappy` + `notify.error` | Same | Same |

### 3.3 Inputs

All inputs are **content-layer fills** (a field sitting on glass must not be glass). Label above in `type.footnote` `label2`, 6 px gap; helper or error text below in `type.footnote`.

| ID | Input | Spec |
|---|---|---|
| IN1 | Text field | `fill2` capsule, 48 tall phone / 40 desktop, padding 16 (20 with a leading glyph 18 `label3`), text `type.body`, placeholder `label3`. Clear button IB6 appears when non-empty |
| IN2 | Password | IN1 + trailing IB3 `eye` / `eye-slash` ("Show password" / "Hide password"), excluded from tab order; caps-lock notice "Caps Lock is on" (footnote `warning`) on web |
| IN3 | Textarea (AI prompt, bookmark note, collection description) | `fill2`, radius 20, 3–6 rows auto-grow, `type.body`; counter `type.caption1` `label3` appears at 500/600 characters and turns `warning` at 580 |
| IN4 | Compact numeric (jump to page, go to chapter) | `fill2` capsule 36 × 72 (page) / 36 × 144 (chapter), `type.mono`, `inputMode="decimal"`; Enter commits, Esc clears |
| IN5 | Stepper | `fill2` capsule 36 tall: IB6 `minus`, value (`type.mono`, 56 wide, tap to reset), IB6 `plus`; ends disable at bounds; `detent.tick` per step; press-and-hold repeats every 80 ms after 400 ms |
| IN6 | Select | IN1 look with trailing `caret-up-down` glyph; opens a Menu (§3.23) blooming from the field; the selected row shows a `glacier` check |
| IN7 | Code / confirmation phrase ("Type RESTORE") | IN1 with `type.mono`, uppercase transform, live match glyph (`check` `success`) when the phrase matches |

| State | Visual | Motion |
|---|---|---|
| Default | `fill2`, text `label`, placeholder `label3` | — |
| Hover | `fill1` | 180 ms fade |
| Focused | `fill1` + 1 px `glacier` rim at 60 % + `border.focus` on keyboard focus only; the caret is a 2 px `glacier` capsule that blinks 530 ms on / 530 ms off | Rim fades in 180 ms |
| Filled | Text `label` | — |
| Disabled | `fill4`, text `label4` | — |
| Loading | Trailing 16 px ring (async validation, e.g. Setup's server check) | — |
| Error | `border.error`, helper text `danger` with a 16 px `warning-octagon` glyph; `aria-invalid="true"`, error announced | Field shakes ±4 px twice on `spring.flex` (off under Reduce Motion) + `notify.error` |
| Success | Trailing `check-circle` `success` (server reachable, passwords match) | Glyph pops on `spring.bouncy` |

### 3.4 Search

| ID | Surface | Spec |
|---|---|---|
| S1 | **Phone search orb → bottom field** | The Search tab is a separate T3 glass orb (64 px) at the trailing end of the tab bar. Tapping it blooms (`spring.morph`) into a T2 search capsule, 50 tall, anchored 8 px above the keyboard (or above the safe area when the keyboard is down), with the scope segmented control (Library · Sources · Dialogue · Ask) floating 8 px above it and suggestions as a list above that, closest to the thumb |
| S2 | **Desktop sidebar field → command palette** | A `fill2` capsule 36 tall inside the sidebar ("Search or jump to…", trailing keycap `⌘K` / `Ctrl K`). Focusing it or pressing `mod+k` blooms the command palette (§3.28) out of the field |
| S3 | **In-page filter field** | IN1 look, 40 tall, leading `magnifying-glass`; used for Library, Sources, Collections, a source catalogue, settings search. `/` focuses it |

| State | S1 | S2 | S3 |
|---|---|---|---|
| Default | Orb with `magnifying-glass` 22 | Field with placeholder `label3` | Field |
| Hover | n/a (touch) | `fill1` | `fill1` |
| Pressed | Orb grows; then blooms | — | — |
| Focused / active | Capsule rim `glacier` 60 %; keyboard up; tab bar dematerialises (350 ms) so the field owns the bottom | Palette open | Rim + focus ring |
| Typing | Results update after 300 ms debounce; a 2 px `glacier` light runs along the bottom rim (1100 ms loop) while any request is in flight | n/a | Same light run |
| Disabled | n/a | n/a | `fill4` (no profile) |
| Error | Scope row shows a `danger` dot on the failed scope; results area shows the error state | Palette row "Search failed · Retry" | Helper text `danger` |
| Close | Swipe down on the field, tap outside, or Esc: the capsule shrinks back into the orb on `spring.morph`, tab bar re-materialises | Esc | Esc clears then blurs |

### 3.5 Chips

Chips are content-layer controls. They become T1 glass only while being dragged (reorder in pinned sources, rail customise).

| ID | Chip | Spec |
|---|---|---|
| C1 | Filter chip (toggle, multi-select) | `fill2` capsule 32 tall, padding 14, `type.subhead` `label2`, optional leading glyph 16 and trailing count `type.monoSmall` |
| C2 | Choice chip (single select) | C1 look with radio semantics (`role="radio"`) |
| C3 | Suggestion chip (recent searches, trending, AI examples) | `fill3`, leading glyph 16 (`clock-counter-clockwise` `label3` for recents, `sparkle` `iris` for AI examples, `trend-up` for trending) |
| C4 | Tag chip (genres, links to a filtered catalogue) | `fill4`, `type.caption1` uppercase +0.06 em, 26 tall |
| C5 | Input chip (tri-state genre filter) | C1 with a trailing IB6 `x` (16); states include (`glacier` rim + `check` glyph), exclude (`danger` rim + label strike-through + `minus` glyph), ignore (plain) |

| State | Visual | Motion |
|---|---|---|
| Default | As above | — |
| Hover | `fill1`, label `label` | 180 ms |
| Pressed | scale 0.96 | `spring.press` |
| Focused | Ring (capsule + 3) | — |
| Selected | Becomes a **Pane glass capsule** (T2) with `label` text, Duotone glyph in `glacier`, and a 4 px `glacier` dot trailing | Materializes in place 250 ms; `tab.select` haptic |
| Disabled | `fill4`, `label4` | — |
| Loading | Count replaced by a 12 px ring | — |
| Error | n/a (chips filter local data; a failed server filter shows the screen error state) | — |
| Dragging (reorder) | T1 clear glass, lifted 1.08, shadow T2 | `spring.interactive`; `reorder.*` haptics |

### 3.6 Segmented control

Track `fill3` capsule 36 tall (32 compact, 44 when it is the page's main switch, e.g. the search scopes). Segments equal width, `type.subhead` `wght 600`. At rest the thumb is a `surface3` capsule inset 2 px; **while dragged** it lifts into a T1 clear droplet, stretches with velocity, and each segment boundary it crosses plays `tab.scrub`.

| State | Visual | Motion |
|---|---|---|
| Default | Thumb on the selected segment, label `label`; others `label2` | — |
| Hover | Hovered segment label `label` | 180 ms |
| Pressed | Thumb scales 0.96 under the finger | `spring.press` |
| Dragging | Thumb becomes clear glass, 1.08 tall, stretches `scaleX` up to 1.25 | `spring.interactive` |
| Selected change | Thumb travels | `spring.tab`; `tab.select` |
| Focused | Ring around the track; arrow keys move selection | — |
| Disabled | Track `fill4`, labels `label4` (a single disabled segment has `label4` and is skipped by arrows) | — |
| Loading | n/a (segments switch local views; the view below shows loading) | — |
| Error | n/a | — |

### 3.7 Cards (content layer)

| ID | Card | Visual | Key states |
|---|---|---|---|
| K1 | **Continue deck** | 296 × 132 phone (340 × 148 desktop). `slab.card` radius 26, padding 12. Left: poster 72 × 108 (radius 14). Right: title `type.headline` 2 lines, meta `type.subhead` `label2` "Ch 142 · page 12 of 40" (novels "42 % in"), a 28 px ring around the chapter number in `glacier` showing chapter progress, and badges ("3 new", "Almost done", "Paused 21 d", "Next: Ch 143"). Behind the card, offset 8 px up and scaled 0.94 at 50 % opacity, a second card shows the next chapter's first panel crop blurred 12 px: the deck | Hover: the back card fans out 12 px and un-blurs to 4 px (`spring.snappy`). Pressed: 0.97. Selected n/a. Loading: bone. Error: n/a (tap retries reader) |
| K2 | **Series row** (list density) | 76 tall, poster thumb 48 × 72 radius 8, title `type.headline`, meta `type.subhead` `label2`, status dot + label, trailing IB3 favourite / follow / more | Hover `fill3`; pressed `fill4`; selected (select mode) leading circle checkbox filled `glacier` + row `rgba(143,216,255,0.08)` |
| K3 | **World title card** | 320 × 164 phone rail (desktop 360 × 176). Poster 88 × 132; title `type.headline`; badge line "Manhwa · Ongoing" `type.caption1`; numbers "120 ch · ★ 8.4" `type.mono`; up to 3 C4 genre tags; `why` line `type.footnote` `label2` with a leading `sparkle` in `iris` when AI-produced. **Available** variant: footer "On MangaDex +2" with source monograms, whole card opens the series; a 2 px `glacier` light line along the card's top edge marks it as openable. **Info** variant: no top light; footer "Not on your sources" + B3 "Search" + B3 "Read on {site}" (external, `arrow-square-out`) | Hover lift −2; pressed 0.97; loading skeleton; image error → monogram cover |
| K4 | **Collection stack** | 3 member covers fanned (−6°, 0°, +6°, offsets −18/0/+18 px, back two at 70 % brightness) on a 21:9 `slab.card`; name `type.title3`, "{n} series" `type.subhead`; shared collections add a row of member avatars (24 px) with `bloom` rims | Hover: fan spreads to ±10° and 28 px on `spring.bouncy`; pressed 0.97; empty collection: a single dashed `separator` placeholder cover with `stack-simple` glyph |
| K5 | **Stat tile** | `surface1` radius 20, padding 16; value `type.stat` (or `type.title1` in compact grids) `label`, unit `type.subhead` `label2`, caption `type.caption1` `label3`; optional 44 px sparkline in `glacier` | Loading bone; zero values show "0" not a dash |
| K6 | **Recap card** | See §5.1.4 | |
| K7 | **Activity card** | See §5.3 | |
| K8 | **Update group** | One per series: poster 48 × 72, title, "3 new chapters" `glacier`, latest "Ch 143 · 2 h ago", chips for each new chapter (C1 look, tap opens the reader), trailing B3 "Mark read" | Read groups at 60 % opacity; swipe actions (§3.33) |
| K9 | **Source row** | 64 tall: 40 px source monogram/icon squircle (radius 10), name `type.headline`, description `type.subhead` `label2` 1 line, `18+` marker, health dot, trailing IB4 pin | Unavailable pinned source: 45 % opacity, subtitle "Unavailable on this profile", not tappable |
| K10 | **Bookmark card** | `slab.card`: series title, "Chapter 14 · 62 % in", novel snippet `Literata` italic 15/22 2 lines with a 2 px `glacier` left rule, note, saved date; stale note "Position approximate: the text changed" `warning` | Swipe to remove with undo |
| K11 | **Download group** | `slab.grouped`: header row (poster 40 × 60, title, "37 chapters · 412 MB · last read 2 d ago", IB4 pin, IB3 more), expandable chapter rows | See §4.22 |
| K12 | **Next-chapter card** (reader) | See §4.14.4 | |

### 3.8 Posters

Cover art 2:3, `radius.poster` 14, `border.content`, `object-fit: cover`; always sits on content, never on glass. Covers load `w=` from the cover endpoint's snapped widths: 160 (≤ 60 px wide at DPR 3 thumbnails use 96/160), 360 (rail and grid posters at DPR 3), 480 (desktop grid at DPR 2), 720 (hero, backdrops).

| Size | Phone | Tablet | Desktop | Wide |
|---|---|---|---|---|
| Rail poster | 112 × 168 | 132 × 198 | 152 × 228 | 168 × 252 |
| Grid poster | 3 columns (≈ 111 wide at 390) | `repeat(auto-fill, minmax(132px, 1fr))` | `minmax(152px, 1fr)` | `minmax(168px, 1fr)` |
| Hero poster (Home spotlight, series detail) | 220 × 330 | 260 × 390 | 300 × 450 | 330 × 495 |

Anatomy: title `type.headline` (15/20 in grids at phone width) 2 lines under the cover, meta `type.caption1` `label3` 1 line ("Ch 12 of 40", "Not started", "Caught up", "{n} chapters"). Overlays on the cover (all content-layer, not glass): top-left reading-status dot 8 px with a 1 px black ring; top-right "N new" badge (§3.20); bottom 3 px progress hairline in `glacier` over a `rgba(0,0,0,0.5)` track, inset 8 px from the sides; bottom-right download mark 18 px (§3.29); `18+` marker only when the profile can see it.

| State | Visual | Motion |
|---|---|---|
| Default | As above | Cover fades in 280 ms on decode, scale 1.02 → 1 |
| Hover (desktop) | Tilts toward the pointer, max 6°, on `spring.tilt`; a specular highlight (radial `rgba(255,255,255,0.12)`, 160 px) follows the pointer across the cover like light on a print under glass; lift −4 px; shadow `0 18px 40px rgba(0,0,0,0.55)`; after 600 ms a T2 tooltip capsule with the full title if it was truncated | Tilt out on `spring.smooth` |
| Pressed | Scale 0.97 (content presses down; glass grows up) | `spring.press` |
| Focused | Ring at radius 17 (14 + 3); focus also applies the hover tilt at 3° toward the centre | — |
| Disabled / unavailable | 45 % opacity, `label3` meta "Unavailable" | — |
| Loading | `frost50` bone 2:3 with the skeleton pulse | — |
| Selected (select mode) | `border.selected`; cover dims to 80 %; a T1 glass check orb 26 px top-right with a `glacier` fill and black check | Check pops on `spring.bouncy`; `tab.select` haptic |
| Error (cover failed) | `surface1` fill, the series' initials in `type.title2` `label3` centred, `image-broken` 16 px bottom-right `label4` | — |
| Long-press / right-click | Context menu with preview (§3.23) | Lift 1.08 → 1.15 at 800 ms |

### 3.9 Rails

Header: `type.title2` with the heading reveal (§6.1) the first time the rail enters the viewport, left-aligned at `layout.margin`; trailing B3 "See all" with a `caret-right` that materialises on header hover/focus; optional eyebrow above (`type.eyebrow`, e.g. "FOR YOU" in `iris` on AI rails). Body: horizontal scroller, `scroll-snap-type: x mandatory`, snap to card start with `scroll-padding-inline: layout.margin`, 12 px gap (16 desktop), the next card peeking ≥ 24 px. Desktop: two IB1 orbs (40 px) appear on hover at the rail's vertical centre, left and right edges, scrolling by one viewport width minus one card; hidden when at an end. Keyboard: the rail is one tab stop; `←/→` move inside, `↑/↓` move between rails keeping the column; the focused card scrolls in with `inline: 'nearest'`.

| State | Visual |
|---|---|
| Loading | Header bone (160 × 22) + 6 poster bones |
| Empty | The rail is omitted, except AI rails, which keep their header and show a one-line state row (§5.1.2) |
| Error | Header + a `surface1` row "Couldn't load this row" + B3 "Try again" |
| Offline | Rails that need the network are omitted; a single offline capsule (§3.30) appears under the first rail that remains |
| Hover / focus | As posters |

### 3.10 Sheets

| ID | Sheet | Spec |
|---|---|---|
| SH1 | **Partial sheet** (phone, tablet) | Glass T4, inset `layout.sheetInset` (8) from the sides and bottom, corner `radius.sheet` (device radius − 8), grabber 36 × 5 `fill1` 6 px from the top (44 × 24 hit, tap cycles detents), header: title `type.title3` left, IB6 close right. Detents: `peek` 96 px (only for the listen mini sheet and the Friends compose), `medium` 50 % of the viewport, `large` = full height − safe top − 10 px. Barrier `dimSheet`; the page recedes (§2.6) |
| SH2 | **Large detent** | Over the last 20 % of travel to `large`, the inset lerps 8 → 0, the corner radius lerps to 36 top / 0 bottom, and the material cross-fades T4 glass → `surface1` solid (Apple: opaque and attached at full height); `sheet.full` haptic on arrival |
| SH3 | **Desktop side sheet** | Glass T4, right side, 440 wide (480 at ≥ 1600), inset 12 top/right/bottom, radius 34, same header; used for filters, reader settings, chapter list, cast, voices, quick look. Barrier `dimSheet` over the content only; the sidebar stays live |
| SH4 | **Desktop form panel** | Glass T4 centred 560 wide, radius 34, max height 80 vh, blooms out of its trigger; used for profile form, collection form, add-to-collection, share card, recommend-to |

| State | Visual | Motion |
|---|---|---|
| Opening | From its trigger when there is one (bloom, `spring.morph`); otherwise slides up from below on `spring.sheet` with materialize | `sheet.open` sound |
| Dragging | Follows the finger 1:1; above `large` it rubber-bands with `c = 0.55`; below `medium` the barrier fades proportionally | `spring.interactive` |
| Release | Detent = nearest to the fling projection (§2.10.6) | `spring.sheetSnap`; `sheet.detent` haptic |
| Dismiss | Dragged below 50 % of its height from the lowest detent, or a downward fling ≥ 2 sheet heights/s | Dematerializes down on `spring.sheet`; `sheet.close` sound |
| Scroll handoff | A list inside the sheet scrolls only at `large`; at `medium`, dragging up expands the sheet first | — |
| Focused | Focus moves to the sheet title on open and is trapped; Esc closes; focus returns to the trigger | — |
| Loading | Content area skeleton; header live | — |
| Error | Inline error block inside the sheet with B4 "Try again" | — |
| Disabled / selected / hover | n/a for the container; see contents | — |
| Stacked | A second sheet stacks on top; the first scales 0.9165, moves up 2 %, brightness 0.70; max two | `spring.sheet` |

Web: `@base-ui/react` 1.8.0 `Drawer` with `snapPoints={['96px', 0.5, 1]}` and our springs (§9.2); every open sheet pushes `?sheet=<id>` so Android back and browser back close it. Flutter: `liquid_glass_widgets` `GlassModalSheet` (peek 96, half 0.5, horizontal and bottom margin 8, `fullTopBorderRadius` 36, barrier `0x40000000`, `morphFrom` the trigger), falling back to `smooth_sheets` 1.2.0 for sheets holding 1,000-row lists if scroll handoff stutters.

### 3.11 Dialogs and alerts

Glass T4 (T5 for the 18+ confirm, skin switch and restore), width 300 phone / 420 desktop, radius 26, padding 20; title `type.title3` bold, left-aligned; body `type.callout` `label2`; optional warning block (`surface1`-on-glass is forbidden, so it is a `fill3` rounded 14 block with a `warning` glyph); buttons stacked full width on phone (primary on top), right-aligned row on desktop (primary rightmost). Barrier `dimModal`.

| State | Visual | Motion |
|---|---|---|
| Open | Blooms from the triggering control when on screen, else scales 1.06 → 1 at centre with materialize | `spring.morph` |
| Default | As above | — |
| Focused | Focus on the least destructive button; trapped | — |
| Pressing a button | Button states (B1/B4/B5/B6) | — |
| Loading | Confirm button in loading state; Cancel stays enabled when the request can be abandoned | — |
| Error | Error line `danger` above the buttons, announced; buttons re-enable | Shake ±4 px twice |
| Disabled | Confirm disabled until its condition holds (acknowledgement switch, phrase typed, hold completed) | — |
| Close | Esc or Cancel; barrier tap closes only non-destructive dialogs | Dematerialize 350 ms |
| Hover / selected | per buttons / n/a | — |

Keyboard: Esc cancels; Enter confirms only non-destructive dialogs; destructive confirms need a click, tap or the B6 hold.

### 3.12 Toasts

Glass T2 capsule, 44 tall, max width 420, `type.callout`, leading glyph 18 in the state colour, optional B3 action ("Undo", "View", "Retry") in `glacier`, optional 16 px countdown ring around the action for undo. Position: top centre at `safe-top + 8` on phone and tablet; on desktop top centre of the content area, 16 px below the top. Max two visible: the older one sits 6 px behind at scale 0.94 and 70 % brightness.

| State | Visual | Motion |
|---|---|---|
| Enter | Drops from above: y −24 → 0 on `spring.snappy` + materialize | — |
| Default | Info `label` glyph; success `check-circle` `success`; warning `warning`; error `warning-octagon` `danger`; offline `cloud-slash` `warning` | — |
| Hover / focus | Timer pauses; glow 0.08 | — |
| Pressed | Grows (it is glass) | `spring.press` |
| Dismiss | Swipe up ≥ 24 px or 400 px/s; auto after `dur.toast` | Dematerialize upward |
| Loading | "Saving…" toasts show a 16 px ring and never auto-dismiss until resolved | — |
| Disabled / selected / error | n/a / n/a / the error variant above | — |

Screen readers: `role="status"` (`aria-live="polite"`) for info and success, `role="alert"` for errors; Flutter `SemanticsService.sendAnnouncement` guarded by `MediaQuery.supportsAnnounceOf`. Implementation: web `sonner` 2.0.8 with our own render; Flutter `liquid_glass_widgets` `GlassToast` restyled.

### 3.13 In-page tabs

Two kinds, both content-layer at rest:

- **TB1 Lens tabs** (2–4 fixed tabs, e.g. Library's Following · Collections · Downloads · History · Bookmarks on desktop, Downloads' Chapters · Storage, Stats' Week · Month · Year): the segmented control (§3.6) at 36 tall, full width on phone.
- **TB2 Strip tabs** (arbitrary server labels, e.g. a source's browse modes "Popular · Top Rated · Latest · A-Z"): a horizontally scrolling row of `type.subhead` labels, 36 tall, 20 px apart; the selected label sits on a `fill2` lozenge that slides between labels on `spring.tab`, lifting into a T1 clear droplet while the page is swiped between tabs (the lozenge tracks `scrollLeft / clientWidth`, Flutter `controller.animation`). Swiping the content horizontally on phone changes tabs (never on the bottom tab bar). `[` and `]` on keyboards.

| State | Visual |
|---|---|
| Default | Labels `label2`; selected `label` on the lozenge |
| Hover | Label `label` |
| Pressed | Label scale 0.96 |
| Focused | Ring around the label; arrow keys roam, Enter selects (roving tabindex) |
| Selected | Lozenge + `tab.select` haptic when the page settles |
| Disabled | `label4`, skipped |
| Loading | Tab content shows its skeleton; the strip stays live |
| Error | A failed tab label gets a 4 px `danger` dot; its page shows the error state |

### 3.14 Top bars

**Phone.** There is no bar background. Tab roots show a large title (`type.largeTitle`) at `layout.margin`, 12 px under the safe area, with an IB2 orb group at top-right (Home: Updates bell + profile avatar orb; Library: select + filter + sort; Sources: filter; You: settings). Pushed screens show an IB1 back orb (`caret-left`) at top-left and their own orb group top-right. As the content scrolls 0 → 52 px, the large title shrinks and fades (`opacity 1 → 0`, `scale 1 → 0.9`, anchored left), and a **T3 title capsule** (44 tall, `type.headline`, max width screen − 2 × 108) materialises centred between the orbs. The soft top scroll edge (`scrimEdgeTop`) sits under the orbs. Tap on the title capsule scrolls to top (`spring.smooth`).

**Desktop.** No bar either: the page header (large title + subtitle + actions) is part of the content. When scrolled past the header, a T3 title capsule (40 tall) materialises at top centre of the content area with the page title and the page's primary actions (as IB2 orbs), and a soft scroll edge appears under it. Browser-level back is the history; pushed screens also show an IB1 back orb at top-left of the content.

| State | Visual | Motion |
|---|---|---|
| Resting (top) | Large title, orbs | — |
| Condensed | Title capsule materialised, soft edge | Scroll-linked (not time-based) between 0 and 52 px; capsule materialize 250 ms once past 52 |
| Over bright content | The orbs' dim follows `Lb` of the art under them (hero covers) | `dur.dim` |
| Loading | Title shows a 120 × 28 bone; orbs live | — |
| Error / offline | Title unchanged; the offline capsule (§3.30) appears under the title | — |
| Hover / pressed / focused / disabled | Per IB1 / IB2 | — |

### 3.15 Tab bar, search orb and bottom accessory (phone, tablet portrait, mobile web)

**Tab bar.** Glass T3 capsule, 64 tall, inset 21 px from the left edge, 8 px from the search orb and 21 px (plus the safe area) from the bottom. Four tabs, equal width: **Home** (`house-simple`), **Library** (`books`), **Sources** (`compass`), **You** (the active profile's 26 px avatar orb). Each tab: glyph 22 over label `type.caption2` `wght 600`. The **Search orb** is a separate T3 circle, 64 px, at the trailing end (S1 in §3.4). Both share one glass container so the droplet can be dragged from a tab into the search orb.

| State | Visual | Motion |
|---|---|---|
| Default tab | Glyph Regular `label2`, label `label3` | — |
| Selected tab | A T1 clear **droplet** (56 × 52 capsule) sits behind it; glyph Duotone `glacier`, label `label` | Droplet travels on `spring.tab`; `tab.select` haptic |
| Pressed | The pressed tab's glyph scales 1.1; the droplet lifts toward the finger (clear, 1.08) | `spring.press` |
| Dragging across | The droplet follows the finger, stretches with velocity, `tab.scrub` at each boundary; release selects | `spring.interactive` |
| Focused (hardware keyboard) | Ring around the tab cell; `←/→` move | — |
| Badge | Library: active downloads count (glacier capsule badge, §3.20). You: a 8 px `bloom` dot when there is unseen friend activity; the Updates count is on Home's bell | Badge pops on `spring.bouncy` |
| Re-tap selected | Pops the tab's stack to its root; if already at root, scrolls to top; on Search, focuses the field | `spring.smooth` |
| Long-press | Home: "Updates · Mark all read"; Library: a jump list of collections, Downloads, History, Bookmarks; Sources: pinned sources; You: the profile switcher (other profiles as avatar rows + "Manage profiles"). Each is a Menu blooming from the tab | `menu.bloom` haptic |
| Minimised | After 20 px of downward scroll, the bar morphs into a 50 px capsule showing only the selected tab's glyph; the search orb shrinks to 50 px; after 12 px of upward scroll, a tap on the capsule, or reaching the top, it restores | `spring.minimize`; web uses the frosted tier during the morph, liquid when settled |
| Hidden | On pushed full-screen routes (readers, Wrapped, recap, onboarding, profile picker) | Dematerialize downward 350 ms |
| Disabled | n/a | — |
| Loading | n/a (tabs are always available offline) | — |
| Error | n/a | — |

**Bottom accessory.** A T2 capsule, 48 tall, spanning the tab bar's width, 8 px above it. It carries at most one thing, by priority: (1) the **narration mini-player** while a novel chapter is being narrated (voice avatar 28, "Chapter 12 · Mara", play/pause IB6, 2 px progress line along its bottom edge, tap opens the listen window); (2) **active downloads** ("Downloading 3 · Solo Leveling Ch 142", a 20 px progress ring, tap opens Downloads); (3) on Home only, the **Continue pill** ("Continue · Solo Leveling Ch 142", 20 px progress ring, tap resumes). When the tab bar minimises, the accessory slides **inline** between the minimised capsule and the search orb (`spring.minimize`), shrinking to its glyph + ring. Swipe left/right on the narration accessory skips chapters; swipe down dismisses downloads (they keep running).

### 3.16 Desktop sidebar

A floating glass **T3** panel, 272 wide (296 at ≥ 1600), inset 12 px from the top, left and bottom, radius 28; content scrolls underneath it and the ambient field shows through it. Sections top to bottom:

1. Wordmark lockup (single-line fallback, §7.1) 28 tall, 20 px from the top, left padding 20.
2. S2 search field ("Search or jump to…" + `⌘K` keycap).
3. Primary: Home, For you, Library (expands to Following, Collections, Downloads, History, Bookmarks as 32 px indented rows with a 1 px `separator` guide), Sources, Updates (count), Search results appear in the palette, not the sidebar.
4. "You" group: Stats (live `flame` glyph in `flare` when a streak is alive), Friends (`bloom` dot on unseen activity), Dialogue search (manga mode only), Settings.
5. Footer: content-mode switch (segmented Manga · Novels, only when `novels_enabled`), the profile chip (avatar 28 + name + `caret-up-down`, opens the profile switcher menu blooming upward), System status (admin only, `pulse` with a health dot), and two IB3 controls: `sidebar-simple` "Collapse sidebar · ⌘B" and `keyboard` "Keyboard shortcuts · ?".

Rows: 36 tall, radius 20 (28 − 8), glyph 20 + `type.subhead` `wght 560`, 12 px padding.

| State | Visual | Motion |
|---|---|---|
| Row default | Glyph `label2`, text `label2` | — |
| Row hover | `fill3` lozenge; text `label` | 180 ms fade |
| Row pressed | `fill2`; scale 0.98 | `spring.press` |
| Row focused | Ring (radius 23) | — |
| Row selected | A T1 clear droplet lozenge behind the row; glyph Duotone `glacier`, text `label`; only the most specific match is selected (`/library/collections` lights Collections, not Library) | Droplet travels between rows on `spring.tab` |
| Row disabled | Rows that do not apply are not rendered (Dialogue search in Novels mode, Status for non-admins) | — |
| Badge | Trailing capsule badge (§3.20) | Pops |
| Collapsed (1024–1279 px or `mod+b`) | 76 px wide capsule rail (radius 28), glyphs only, the wordmark becomes the 28 px MM mark, search becomes an IB1 orb; tooltips after 150 ms (short delay) | Width on `spring.minimize`; labels fade 120 ms before the width moves |
| Loading | Counts show 12 px rings | — |
| Offline | A `cloud-slash` `warning` glyph appears beside the profile chip with tooltip "Offline: showing what's on this device" | — |

Tablet (768–1023): the collapsed rail is the default and expands as an overlay on hover or focus (content does not reflow). Mobile web below 768 uses the phone tab bar.

### 3.17 Lists

- **L1 Grouped inset list** (Settings, series info rows, Storage, Security, Members): `slab.grouped` radius 20 at `layout.margin`, rows 52 min (44 on desktop), 16 px padding, separators `border.hair` inset to the text start, group title `type.footnote` uppercase +0.06 em `label3` 8 px above, group footer `type.footnote` `label3` 8 px below.
- **L2 Plain list** (chapter lists, notifications, history timeline, search results on desktop): rows on canvas, 60–76 tall, hairlines inset to the text start.
- Row anatomy: optional leading glyph 20 `label2` (or thumbnail), title `type.headline` / `type.body`, subtitle `type.subhead` `label2`, trailing value `type.body` `label3`, trailing control (switch, chevron `caret-right` 16 `label4`, IB3).

| State | Visual | Motion |
|---|---|---|
| Default | As above | — |
| Hover | `fill3` wash | 180 ms |
| Pressed | `fill4` wash + content scale 0.99 | `spring.press` |
| Focused | Ring inset 2 px (radius 18 inside a grouped list) | — |
| Selected | Trailing `check` 20 `glacier`; in select mode a leading 22 px circle checkbox | Check pops |
| Disabled | Text `label4`, controls disabled, reason as subtitle | — |
| Loading | Trailing 16 px ring, or the row as a bone | — |
| Error | Subtitle in `danger` with the reason; trailing B3 "Retry" | — |
| Read / done (chapters) | Title `label3`, a `check` 14 `success` before the date | — |

### 3.18 Skeletons ("frost bones")

Bones mirror the real layout exactly (same boxes, radii and positions). Fill `rgba(255,255,255,0.06)` pulsing to `0.11` and back over `dur.skeleton` 1100 ms; once every 2.2 s a single specular band (80 px, `rgba(255,255,255,0.05)`) sweeps across the whole skeleton group along the key-light angle, as if light moved over frosted glass. Text bones are capsules at 60 % of the line height with the last line at 60 % width. Web: CSS; Flutter: `skeletonizer` 3.0.0 with `SkeletonizerConfig(data: SkeletonizerConfigData(brightness: Brightness.dark, effect: PulseEffect(from: Color(0x0FFFFFFF), to: Color(0x1CFFFFFF), duration: Duration(milliseconds: 1100))))`. Reduced Motion: static at 0.08, no sweep. Screen readers hear "Loading {screen}" once (`aria-busy="true"` on the region).

### 3.19 Progress

| ID | Indicator | Spec | States |
|---|---|---|---|
| PR1 | **Liquid bar** | Track `slab.well` (4 px for reading progress, 6 px for downloads and storage), fill `glacier` with a meniscus leading edge; optional buffered layer `label4` | Determinate: value moves on `spring.meniscus`. Complete: fill turns `success` for downloads. Paused: fill `warning` with 2 px diagonal hatching. Error: fill `danger`, stops |
| PR2 | **Ring** | 2 px (16–20 px size), 2.5 px (28), 3 px (44) stroke; track `fill1`, arc `glacier`, round caps | Determinate: arc on `spring.meniscus`. Indeterminate: a 90° arc of light rotating once per 900 ms linear, its tail fading. Complete: arc fills and morphs into a `check` in `success` over 250 ms |
| PR3 | **Light run** (in-flight) | A 2 px band of `glacier` light 30 % of the host's width travelling along a capsule's bottom rim, 1100 ms loop `ease.light` | Search fields, the Check-now button, Home's AI rails while generating |
| PR4 | **Reading hairline** | 1 px track `rgba(255,255,255,0.10)` full width under the novel running head; fill `glacier` at 70 % | Width on `spring.meniscus` (150 ms equivalent: it follows scroll 1:1, settling with the spring) |
| PR5 | **Storage tube** | See §4.22 | |
| PR6 | **Pull-to-refresh droplet** | A 28 px T1 clear glass droplet hanging from the top edge whose neck stretches with the pull; at 100 px (the trigger) it detaches and pops into a PR2 indeterminate ring at 60 px rest height | `refresh.armed` at detach; `refresh.done` when data lands; reduced motion: the ring appears at rest height, no droplet |

### 3.20 Badges and markers

| ID | Badge | Spec |
|---|---|---|
| BD1 | Count | `glacier` capsule 18 tall, min width 18, padding 6, `type.monoSmall` `wght 700` `#000000` (13.4:1); "99+" above 99 (tabs "9+" above 9) |
| BD2 | "N new" on posters | Capsule 20 tall: `glacierDeep` at 90 % with a 0.5 px `glacier` rim, `type.caption2` `#FFFFFF`, "3 new" / "99+ new", top-right inset 6 px |
| BD3 | 18+ marker | `mature` capsule 18 tall, "18+" `type.caption2` `wght 760` `#000000` (7.2:1); on posters top-left under the status dot, on source rows after the name, on profile avatars as a 16 px circle at 4 o'clock |
| BD4 | Status tag | 8 px dot in the status colour + `type.caption1` label in the same colour ("Reading", "Completed", "On hold", "Plan to read", "Dropped", "Not started") |
| BD5 | Health dot | 8 px dot in `health.*`; `demoted` adds a 1 px `warning` ring; tooltip names the state and last error time |
| BD6 | Stale catalogue chip | Capsule `warning` 14 % fill + 0.5 px `warning` rim, `cloud-slash` 14 + "Saved copy · 3 h" `type.caption1` |
| BD7 | AI mark | `sparkle` 14 in `iris` + optional "AI" `type.caption2` `iris` |
| BD8 | Friend mark | 20 px avatar with a 1.5 px `bloom` ring; stacks overlap by 6 px, max 3 then "+1" |
| BD9 | Offline mark | `cloud-slash` 14 `warning` (novel running head when reading a downloaded copy, series pages rendered from the local store) |
| BD10 | "NEW" (updates) | `type.eyebrow` "NEW" in `glacier` with a 6 px `glacier` dot before it |

Badges appear with a `spring.bouncy` pop (0.6 → 1) and are always included in the host's accessible label ("Updates, 12 new").

### 3.21 Sliders, scrubbers and dials

| ID | Control | Spec |
|---|---|---|
| SL1 | **Liquid slider** | Track `fill1` capsule 4 px (hit 44), fill `glacier` from the start; thumb at rest a 28 px `#F5F7FA` circle with `0 2px 6px rgba(0,0,0,0.4)`; while dragged the thumb becomes a T1 clear glass lens 36 × 28 that magnifies the track under it (1.4×) and shows the value above in a T2 bubble (`type.mono`) |
| SL2 | **Tile slider** (brightness, warmth, soundscape volume) | Glass T2 capsule 72 × 160 (desktop 64 × 140), fills from the bottom with `rgba(245,247,250,0.85)` (brightness) / `flare` 70 % (warmth) / `glacier` 70 % (volume); glyph 22 at the bottom changes weight with the value (Light → Bold); drag anywhere on the tile, relative |
| SL3 | **Reader scrubber** | Inside the reader's bottom capsule: track 4 px `fill1`, fill `glacier`, bookmark ticks (2 × 8 px `label` marks), chapter segment gaps of 2 px in Read-all; thumb 14 px circle, stretching to 1.25× width with velocity; while dragged a **magnifier lens** (T2 glass, 96 × 128 phone / 120 × 160 desktop) floats 16 px above the thumb showing the page thumbnail (`w=160`) and "Page 18 / 64" in `type.mono` |
| SL4 | **Speed dial** (narration) | Tap the speed value to open a vertical T3 capsule 56 × 240 over the button; drag up/down through 0.50–3.00× in 0.05 steps, labelled marks at 0.5 / 1 / 1.5 / 2 / 2.5 / 3; touch-and-hold on the value resets to 1× |

| State | SL1 | SL2 | SL3 | SL4 |
|---|---|---|---|---|
| Default | As above | As above | As above | Shows "1.25×" |
| Hover | Thumb glow 0.08 | Glow | Track grows to 6 px; hovering the track shows the magnifier without dragging (desktop) | Glow |
| Pressed / dragging | Lens thumb, value bubble; `detent.tick` per step (per 1 % for continuous ranges only at 10 % marks) | Fill follows 1:1; `detent.tick` every 10 % | Magnifier; `reader.page` per page; `reader.tenth` at each 10 %; `threshold.cross` crossing a chapter segment | Dial follows; `detent.tick` every 0.05, `reader.tenth` at labelled marks |
| Focused | Ring on the thumb; arrows ±1 step, Page Up/Down ±10 %, Home/End | Ring; arrows | Ring; arrows ± 1 page, Home/End; `aria-valuetext="Page 12 of 40"` | Ring; ↑/↓ ± 0.05 |
| Disabled | Track `fill4`, thumb `label4` | Tile `solid`, glyph `label4` | Single-page chapters: the scrubber is replaced by "1 page" | n/a |
| Loading | n/a | n/a | Unloaded pages show dotted track segments | n/a |
| Selected | n/a | n/a | n/a | n/a |
| Error | n/a | n/a | n/a | n/a |

### 3.22 Toggles, checkboxes and radios

| ID | Control | Spec |
|---|---|---|
| TG1 | Switch | 51 × 31 capsule; track `fill1` off, `glacier` on (with a 0.5 px `#BFEAFF` rim); thumb 27 px `#F5F7FA` circle; **while dragged** the thumb stretches to a 38 × 27 T1 clear glass capsule refracting the track; label left, switch right, the whole row toggles |
| TG2 | Checkbox (select mode) | 22 px circle, 1.5 px `label3` ring; checked: `glacier` fill + 14 px `check` `#000000` |
| TG3 | Radio (inside menus and settings) | Selected row shows a trailing `check` `glacier`; unselected shows nothing (iOS style); the whole row is the target |

| State | TG1 | TG2 | TG3 |
|---|---|---|---|
| Default | Off / on | Unchecked / checked | Unselected / selected |
| Hover | Track brightens (`fill1` → `rgba(154,163,176,0.40)`; on `#A5DFFF`) | Ring `label2` | Row `fill3` |
| Pressed | Thumb widens to 33 px toward the travel direction | Scale 0.9 | `fill4` |
| Toggling | Thumb travels on `spring.snappy`; `toggle.on` / `toggle.off` haptic and sound | Check draws in 180 ms, pop on `spring.bouncy` | Check pops |
| Focused | Ring around the track | Ring | Ring |
| Disabled | 40 % opacity; the reason in the row's subtitle | 40 % | `label4` |
| Loading (server-backed switches: notify, 18+, auto-check) | Thumb shows a 14 px ring; the switch is inert until the server answers; on failure it springs back | — | — |
| Error | Springs back to the previous value + inline `danger` subtitle "Couldn't save. Try again." | — | — |

### 3.23 Menus and context menus

**Menu** (sort, select, overflow `⋯`, account, tab long-press): Glass T4, radius 26, padding 6, rows 44 (34 on desktop pointer, 44 hit) at radius 20, row content: leading glyph 20, title `type.body`, trailing check or keycap; group separators `border.hair` with 6 px margins; destructive rows `danger` text and glyph at the bottom after a separator. Opens by **blooming out of its trigger** (the trigger's glass stretches into the menu on `spring.morph`, contents fade in over the last 40 %); closes by shrinking back into it (`dematerialize` 350 ms). Max height 60 vh, scrolls inside.

**Context menu** (long-press on touch, right-click on desktop, `⋯` button, `.` or `shift+F10` on a focused item): on touch the pressed item **lifts** (scale 1 → 1.08 over 500 ms while held, to 1.15 at 800 ms when the menu opens), the rest of the screen recedes (§2.6) and the menu blooms beneath (or above when there is no room) the lifted preview. On desktop right-click opens the menu at the pointer without a preview. Poster context actions: Continue / Read, Open series, Add to library / Remove from library, Add to collection…, Mark read / Mark unread, Download next 5, Previously on… (when progress exists), Recommend to… (when Friends is on), Not interested (AI recommendations only), Remove from Continue.

| State | Visual | Motion |
|---|---|---|
| Opening | Bloom | `spring.morph`; `menu.bloom` haptic on touch |
| Row default | `label` | — |
| Row hover / keyboard highlight | `fill3` lozenge radius 20 | Lozenge slides between rows on `spring.snappy` (keyboard) |
| Row pressed | `fill2` | — |
| Row focused | Same as highlight + ring on keyboard | — |
| Row selected | Trailing `check` `glacier` | — |
| Row disabled | `label4`, skipped by arrows | — |
| Row loading | Trailing 16 px ring (e.g. "Download next 5" resolving) | — |
| Row error | The menu closes and a toast reports it | — |
| Submenu | Slides in from the right inside the same menu on `spring.snappy`, with a back row at the top | — |

Keyboard: arrows move, Enter activates, Esc closes, type-ahead jumps to the first row starting with the typed letters, `←` closes a submenu. Web: `@base-ui/react` `Menu` and `ContextMenu`; Flutter: `GlassMenu` / `CupertinoContextMenu.builder` (for the lift) restyled.

### 3.24 Empty, error and offline states: the "object lens"

Every such state is the same object: a 96 px glass **orb** (T3, 72 px on compact rows) floating over a small ambient pool (a 240 px radial of the state colour at 18 %, blur 60), holding a Light-weight 40 px glyph in `label`. Under it: title `type.title3` (phone) / `type.title2` (desktop), body `type.callout` `label2` max 36 ch centred, up to two buttons (B1 lit + B3 plain). The orb breathes: its specular sweep repeats every 6 s, and its displacement pulses 1 → 1.1 over 3 s (off under Reduce Motion).

| Variant | Pool colour | Glyph | Behaviour |
|---|---|---|---|
| Empty | `glacier` | Screen-specific (e.g. `books`, `bookmark-simple`, `cloud-arrow-down`) | Offers the next step |
| Error | `danger` | `warning-octagon` | "Try again" lit; secondary "Back to …"; the server's message in `type.footnote` `label3` under the body; reference id in `type.monoSmall` when the backend returns one |
| Offline | `warning` | `cloud-slash` | "Try again" + "Open Downloads"; retries automatically on the `online` event (3 s cooldown) and on app resume; the orb's pool dims to 8 % while retrying |
| Server unreachable | `warning` | `plugs` | "Can't reach the server" copy; retries every 10 s with a countdown in the button ("Try again · 8 s") |
| Rate limited | `warning` | `hourglass-medium` | "Slow down a moment" + a PR2 ring counting down `Retry-After`; retries by itself |
| No profile | `iris` | `user-circle` | "Choose a profile" lit |
| Unsupported (downloads without a service worker) | `label3` grey pool | `prohibit` | No button |
| Filtered to nothing | `glacier` | `funnel-simple` | "Clear filters" plain |
| Search no results | `glacier` | `magnifying-glass` | Suggests scopes: "Try Sources" / "Search dialogue" |

### 3.25 The 18+ gate

The gate is **absence, never a lock** (`capabilities.md` §1): a profile without mature content simply never receives mature rows, so Prism never draws a blurred tile, a lock, a "hidden: 18+" placeholder or a count that implies hidden items. The gate's UI is therefore only four things:

1. **The switch** (Settings → Content, the profile form, and onboarding's last step): TG1 row "Show mature (18+) content", subtitle "Adult sources, search results and recommendations appear for this profile." Turning it **off** applies at once (`toggle.off`, toast "Mature content hidden"). Turning it **on** never flips directly: the switch stays off and the confirm alert opens.
2. **The confirm alert** (T5, blooms from the switch): the `age-gate` glyph in a 56 px T3 orb, title "Enable mature content?", body "This shows adult (18+) sources, search results and recommendations for {profile}. Only continue if you are of legal age to view mature content where you live. You can turn this off at any time.", buttons B4 "Cancel" and **B6 hold** "I am 18 or older — Enable" (hold 900 ms; keyboard: hold Space or Enter). Completion: `gate.unlock` AHAP, `glass-unlock.wav` if sounds are on, the alert dematerialises, the switch flips on its spring, and every mature-gated query refetches (the screen behind shows its loading bones for that refetch). The profile form uses exactly the same flow, so the gate has one safeguard wherever it is switched.
3. **Markers** where mature items are shown: BD3 on posters, source rows, search groups and the profile avatar; the `mature` 0.5 px rim on the series hero poster. Never on Wrapped share cards or friend activity shown to a gated profile (they are filtered out server-side).
4. **Blocked**: with no active profile the switch is disabled with the subtitle "Choose a profile first. The setting belongs to a reading profile." and a B3 "Choose a profile".

### 3.26 Avatars (profile orbs)

People are circles; things are squircles. A profile avatar is a **glass sphere**: a circle filled with a radial gradient of its preset's two colours (lit from 135°), a 1 px specular rim, an etched Phosphor glyph in `rgba(255,255,255,0.88)` at 44 % of the diameter, and an outer 2 px ring in the profile's mood rim tint (§2.1.6). Sizes: 24 (chips), 28 (sidebar), 32 (menus), 44 (settings header), 72 (profile form preview, desktop picker hover), 112 (picker phone), 132 (picker desktop).

The twelve Glass presets (keyed by the existing `avatar_key` values, so profiles keep their choice across skins):

| `avatar_key` | Glass name | Gradient (inner → outer) | Glyph |
|---|---|---|---|
| `violet` | Iris Drop | `#C9BFFF → #5B4BD6` | `sparkle` |
| `cyan` | Glacier | `#CFF0FF → #2B7FB8` | `snowflake` |
| `rose` | Bloom | `#FFD1EA → #C2447F` | `flower-lotus` |
| `amber` | Honey Lens | `#FFE2A8 → #C27A1E` | `sun` |
| `emerald` | Sea Glass | `#C8F7E2 → #1F8A62` | `leaf` |
| `ember` | Flare | `#FFC9A3 → #C4461F` | `flame` |
| `blade` | Quartz | `#E6EAF0 → #5A6472` | `diamond` |
| `phantom` | Smoke | `#B8B4D6 → #2E2A45` | `ghost` |
| `arcane` | Prism | `#E3D1FF → #7A3FD6` | `triangle` |
| `lunar` | Moonstone | `#D6E2FF → #34488F` | `moon-stars` |
| `star` | Starlight | `#FFF3B8 → #B8961E` | `star-four` |
| `reader` | Page Light | `#D8FFF6 → #1E8A80` | `book-open-text` |

| State | Visual | Motion |
|---|---|---|
| Default | As above | — |
| Hover | Specular follows the pointer; sphere tilts 4° | `spring.tilt` |
| Pressed | Grows 1.06 | `spring.press` |
| Focused | Ring (circle + 3) | — |
| Selected (in the profile form's preset grid) | 2 px `glacier` ring at 3 px offset + check badge 18 px | Pop |
| Disabled | n/a | — |
| Loading | `frost50` circle bone | — |
| Error | n/a (presets are local) | — |
| Unknown key | Maps to Iris Drop | — |

### 3.27 Tooltips and keycaps

- **Tooltip:** T2 capsule, `type.caption1`, padding 6 × 10, appears after `dur.tooltip` long (600 ms) on hover or immediately on keyboard focus, 8 px from the target, never covers the pointer; includes the shortcut keycap when there is one ("Bookmark this spot · B").
- **Keycap:** `fill3` rounded rectangle radius 6, 20 tall, min width 20, `type.monoSmall` `label2`, 0.5 px `separator` rim; Mac shows ⌘ ⌥ ⇧ glyphs, others "Ctrl", "Alt", "Shift". Combos separated by 4 px.

### 3.28 Command palette (desktop web, `mod+k`; also opened from the sidebar search)

Glass T4 panel, 640 wide, max 64 vh, radius 26, placed at 14 vh from the top of the content area, **blooming out of the sidebar search field** (`spring.morph`). Barrier `dimModal`. Input row 56 tall (`type.title3` input text, leading `magnifying-glass` 20, trailing `Esc` keycap). Results grouped with `type.footnote` uppercase group labels: **Continue** (top 3 continue items), **Library** (`GET /library/search`, 220 ms debounce), **Sources**, **Go to** (every route), **Actions** (Check for updates, Toggle content mode, Toggle Solid glass, Sign out, Switch profile…, Open shortcuts), **Skin** ("Switch to Cinematic…" opens the restart confirm). Rows 44 tall: 32 px leading visual (poster thumb radius 6, source icon, glyph), title with matched characters in `glacier` `wght 640`, subtitle `label3`, trailing `CornerDownLeft`-style keycap `↵` on the highlighted row. Footer: `↑ ↓ navigate · ↵ open · esc close` keycaps and the result count. The highlight lozenge (`fill3`) slides on `spring.snappy`. Empty: "Nothing matches “{q}”." with the object lens at 72 px. Loading: PR3 light run on the input rim. Keys: `↑/↓` (wrap), `Home/End`, `Enter`, `mod+k` again closes, `Esc` closes and restores focus.

### 3.29 Download control (per chapter)

A 44 px IB3 target whose glyph shows the chapter's state, with a tooltip and an accessible label naming it:

| State | Glyph | Colour | Interaction |
|---|---|---|---|
| Not downloaded | `download-simple` 20 | `label2` | Tap queues it (`download.start`) |
| Queued | Dashed 20 px ring | `download.queued` | Tap removes from the queue |
| Downloading | PR2 ring 20 px with a 6 px stop square inside | `glacier` | Tap cancels; the row's subtitle shows "page 7 of 40" |
| Saved | `check-circle` Fill 20 | `success` | Tap opens a menu: Remove download, Save to Files (mobile), Extract text (manga, OCR available) |
| Incomplete | `warning` 20 | `warning` | Tap resumes |
| Paused (cap / free-space floor / background) | `pause-circle` 20 | `warning` | Tap opens Downloads with the reason |
| Stale (source changed pages) | `arrows-clockwise` 20 | `warning` | Tap saves again |
| Failed | `warning-octagon` 20 | `danger` | Tap retries; subtitle shows the error |
| Audio saved (novels) | `headphones` 16 beside the chapter glyph | `success` | — |
| OCR extracted (manga) | `bubble-search` 16 | `label3` | — |

State changes cross-fade the glyph in 180 ms; the ring fills on `spring.meniscus`; completion morphs the ring into the check (250 ms) with `download.done` (batched: one haptic per batch, not per chapter).

### 3.30 Banners and inline notices

All are T2 glass capsules or content-layer notices, never full-width bars.

| ID | Notice | Spec |
|---|---|---|
| N1 | **Offline capsule** | T2 capsule under the page title: `cloud-slash` `warning` + "Offline · showing what's on this device" `type.footnote`; appears whenever the network is unreachable on any screen; dematerialises when back online with a 2 s "Back online" `success` state first |
| N2 | **New chapters** | T2 capsule toast-like, bottom centre on desktop above the content's bottom edge (24 px), and on phone in the bottom accessory slot's position above the tab bar: `bell-simple-ringing` + "12 new chapters across 4 series" + B3 "View" + IB6 close. Dismissal stored per session (`mm.updates.banner.dismissedMaxId`); hidden on Updates and in readers |
| N3 | **App update ready** (web service worker) | T2 capsule bottom centre: `arrow-clockwise` + "A new version is ready" + B1 lit S "Reload" |
| N4 | **First-run hint** | Content-layer card on Home and Library when the profile follows nothing: covered by the empty states and onboarding (§4.7), so no separate banner exists in Glass |
| N5 | **Stale catalogue** | BD6 chip beside a source catalogue's title with a tooltip "The source didn't answer, so this is the copy saved at {time}." |
| N6 | **Rate limit** | T2 capsule "The source is busy · retrying in 12 s" with a PR2 countdown ring |
| N7 | **Inline notice** | Content block `fill3` radius 14 with a state glyph, `type.callout`, optional B3 action (pending restore, AI quota, novels-mode OCR block) |

### 3.31 Image viewer (lightbox)

Opened from a cover (long-press → "View cover"), an OCR result's page, a bookmark's page, a share-card preview. The image flies from its thumbnail (shared element on `spring.smooth`), the backdrop is `#000` with the image's blurred copy at 30 % behind, controls are `clear` glass orbs (close top-left, share/save top-right). Pinch 1–4×, double-tap 1× ↔ 2× at the tap point. Drag down at 1× to dismiss: the image scales `1 − min(|dy|/1200, 0.15)`, its corner radius grows 0 → 28, the backdrop blur falls 24 → 0 and opacity follows `1 − min(|dy|/320, 1)`; commit at `|dy| ≥ 120` or `≥ 800 px/s`, then it springs back to the thumbnail. Esc and Android back close it. Flutter: `extended_image` 10.1.0 `ExtendedImageSlidePage`; web: Motion `drag` with `dragSnapToOrigin`.

### 3.32 Scroll edges and scrollbars

- Soft top edge under floating top controls; soft bottom edge behind the tab bar (§2.1.7). One per edge.
- Hard edge under pinned headers (sticky chapter-list header, settings search, the Library chip row when pinned).
- Desktop scrollbars: 6 px `fill1` capsule thumb, 2 px inset, appears on scroll and on hover of the scroll area, fades 600 ms after scrolling stops; `scrollbar-width: thin; scrollbar-color: rgba(154,163,176,0.32) transparent`.

### 3.33 Swipe row actions

Rows with actions (notifications, chapter rows, downloads, history, sessions, AI recommendation cards) reveal **separate glass pills** behind the row as it slides: each pill is a T2 capsule 44 tall, 88 wide slot, inflating from scale 0.6 to 1 as it is revealed (`spring.snappy`), glyph + `type.caption1` label. A full swipe past 60 % of the row width or ≥ 1000 px/s commits the primary action (`threshold.cross` at the line, `threshold.back` on the way back). Destructive commits show an undo toast (6 s) instead of a confirm. Actions: notifications (leading "Read" `glacier`; trailing "Mark read"), chapter rows (leading "Read/Unread"; trailing "Download", "Bookmark"), downloads (trailing "Remove" `danger`), history (trailing "Remove"), sessions (trailing "Revoke" `danger`), AI cards (trailing "Not interested"). Every action is also in the row's `⋯` menu and in the accessibility actions (`customSemanticsActions` on Flutter). Web mobile: Motion `drag="x"` with `dragDirectionLock` and `touch-action: pan-y`; desktop shows the actions as IB3 on row hover/focus with keys `m` (mark read), `d` (download), `x`/`Delete` (remove, with undo), `u` (undo). Reduced Motion: committed rows fade out in 150 ms.

---

## 4. Per-screen specs

Every screen below is specified for **desktop web**, **phone** (iOS app, Android app and mobile web, which mirrors the phone app) and the deltas per platform. Every screen has loading, empty, error and offline states; where a state cannot happen the spec says why.

### 4.0 Shells, navigation and routes

#### 4.0.1 Frames

| Frame | Screens | Chrome |
|---|---|---|
| **Bare** | Setup, splash, login, register, root error, offline fallback page | No navigation. The wordmark sits top-left at `layout.margin`; the ambient field uses the `default` mood |
| **Takeover** | Profile picker, onboarding, Wrapped, recap, the skin-switch confirm | No tab bar or sidebar; one IB1 close or back orb |
| **App, phone** (< 768 px, iOS, Android, mobile web) | Every other screen | Tab bar + search orb + bottom accessory on tab roots; pushed screens keep the tab bar (Glass keeps navigation visible) except full-screen routes (readers, listen window, Wrapped) |
| **App, tablet** (768–1023 px web; Android/iPad windows ≥ 600 dp wide) | Every other screen | Collapsed 76 px glass rail (expands as an overlay on hover/focus); no tab bar |
| **App, desktop** (≥ 1024 px) | Every other screen | Floating 272 px glass sidebar (§3.16); collapsed to the rail at 1024–1279 or by `mod+b` |
| **Manga reader** | Reader, read-all | Reader capsules only (§4.14) |
| **Novel reader** | Novel reader, listen window | Running head and capsules painted over paper (§4.15) |

#### 4.0.2 Information architecture

Glass groups the app around **four places plus search**:

- **Home**: what to read now. Continue, the AI rails, new chapters, friends' activity, the spotlight. The Updates inbox opens from Home's bell.
- **Library**: what you own. Following (the followed shelf with every filter in one place), Collections, Downloads, History, Bookmarks, as lens tabs on desktop and as a hub row on phone.
- **Sources**: where titles come from. Sources list, source catalogues.
- **You**: who you are. Profile, Stats and Wrapped, Friends, Dialogue search, Settings, admin.
- **Search** (the orb): everything at once, with scopes.

#### 4.0.3 Routes (the shared `design/contract.json` paths the Glass router registers)

| ScreenId | Path | Place |
|---|---|---|
| `setup` | `/setup` (mobile only) | none |
| `splash` | `/splash` (mobile only; the web plays the reveal over the first route) | none |
| `login` / `register` | `/login`, `/register` | none |
| `profiles` | `/profiles` | takeover |
| `profileNew` / `profileEdit` | `/profiles/new`, `/profiles/:id/edit` | takeover (phone) / form panel (desktop) |
| `profilesManage` | `/profiles/manage` | You |
| `onboarding` | `/welcome` | takeover |
| `home` | `/home` (`/` redirects here) | Home |
| `updates` | `/updates` | Home |
| `forYou` | `/for-you` | Home |
| `recap` | `/recap/:sourceId/:seriesKey` (`?chapter=`) | takeover |
| `search` | `/search` (`?q=&scope=library|sources|dialogue|ask`) | Search |
| `sources` / `source` | `/sources`, `/sources/:sourceId` (`?mode=&genre=&q=`) | Sources |
| `series` | `/series/:sourceId/:seriesKey` (`?chapter=` focuses a chapter; one screen for manga and novels) | pushed |
| `libraryItem` | `/library/:followId` (resolves to `series`; kept for offline-capable deep links and the local store) | Library |
| `library` | `/library` (`?q=&sort=&status=&fav=&view=grid|list`) | Library |
| `collections` / `collection` | `/library/collections`, `/library/collections/:id` | Library |
| `history` / `bookmarks` | `/library/history`, `/library/bookmarks` | Library |
| `downloads` | `/downloads` (`?tab=chapters|storage`) | Library |
| `reader` | `/read/:sourceId/:seriesKey/:chapterKey` (`?page=&at=`) | full screen |
| `readAll` | `/read-all/:sourceId/:seriesKey` (`?from=&page=&at=`) | full screen |
| `readerLanding` | `/read` | full screen |
| `novel` | `/novel/:sourceId/:seriesKey/:chapterKey` (`?page=&para=&at=`) | full screen |
| `listen` | `/novel/:sourceId/:seriesKey/:chapterKey/listen` | full screen |
| `ocr` | `/ocr` (`?q=`) | You |
| `stats` / `wrapped` | `/stats` (`?range=7|30|90|365`), `/stats/wrapped/:year` | You / takeover |
| `friends` | `/friends` | You |
| `you` | `/you` | You |
| `settings` | `/settings` and `/settings/:section` (`skin`, `reading`, `feedback`, `content`, `downloads`, `storage`, `people`, `security`, `members`, `backup`, `notifications`, `server`, `diagnostics`, `shortcuts`, `about`) | You |
| `admin` | `/admin/status` | You |
| `notFound`, `routeError`, `rootError`, `offlineFallback` | n/a | n/a |

Deep links saved on devices and in bookmarks keep working through one-time redirects (web `next.config` redirects; mobile a `redirect:` table in the Glass router): `/library/browse` → `/library`, `/library/recommendations` → `/for-you`, `/library/statistics` → `/stats`, `/reader/:s/:k/:c…` → `/read/…`, `/novels/:s/:k/:c…` → `/novel/…`, `/more` → `/you`, `/sources/:s/series/:id` → `/series/:s/:id`, `/library/read/…` and `/sources/:s/series/:id/chapters/:c/read` → `/read/…`, `/ocr/search` → `/ocr`, `/collections…` → `/library/collections…`.

#### 4.0.4 Transitions shared by every screen

| Move | Spec |
|---|---|
| **Tab / sidebar place change** | No slide. Outgoing content fades out 120 ms; incoming fades in 180 ms with scale 0.985 → 1 on `spring.smooth`; the ambient field cross-fades 900 ms; the droplet travels (`spring.tab`). Each place keeps its own stack and scroll |
| **Push with art** (poster, continue deck, world card → series) | **Cover zoom**: the tapped cover flies to the hero poster on `spring.smooth` (web `<ViewTransition name={"cover-"+sourceId+"-"+seriesKey} share="morph">`; Flutter `heroine` 0.7.2 `Heroine(tag:, motion: spring.smooth)`), the blurred backdrop grows out of the poster's rect to full width over the same spring, the rest of the page fades in 180 ms after a 120 ms delay. The outgoing page recedes (scale 0.94, blur 8, brightness 0.70) rather than sliding away |
| **Push without art** (settings rows, lists) | **Parallax slide**: incoming x 100 % → 0, outgoing 0 → −30 % with brightness 1 → 0.70, both on `spring.smooth`; the title capsule cross-fades |
| **Back** | The reverse; if the origin cover is not on screen any more the zoom degrades to a 200 ms fade + scale 1 → 0.96 |
| **Into a reader** | **Lens dive** (§8, moment 4) |
| **Out of a reader** | The page column shrinks into the series hero poster or the continue deck it came from (shared element, `spring.smooth`); the reader's page tint fades back into the destination's field over 900 ms |
| **Sheets, menus, alerts** | Bloom from the trigger (§2.10.4) |
| **Profile switch / skin switch** | §4.5 and §4.25.1 |
| Reduced Motion | Every row above becomes a 200 ms cross-fade; finger-driven back swipes still track |

#### 4.0.5 Back and system behaviour per platform

| Platform | Back | System UI |
|---|---|---|
| iOS | Full-width swipe back from anywhere on the screen (`swipeable_page_route` 0.4.8, `canOnlySwipeFromEdge: false`); the underlying page moves 1/3 of the way (parallax) and brightens from 0.70 → 1; release on `spring.smooth`. Readers: edge-only 20 pt, vertical mode at 1× only. Pages whose first child is a horizontal pager pop only when the pager is at index 0 and the drag goes right | Status bar light; hidden in readers; `edgeToEdge`; home indicator auto-hides in readers |
| Android | Predictive back through `PredictiveBackPageTransitionsBuilder` (the page shrinks to 90 % and floats as a card, which matches glass); `android:enableOnBackInvokedCallback="true"`; open sheets and menus close first; on a place root, back goes to Home, then to the system | Edge-to-edge with transparent bars; `immersiveSticky` in readers; `BouncingScrollPhysics` on every scroll view (Glass is Apple-flavoured on both platforms) |
| Web desktop | Browser history; every sheet, menu and viewer that should close on back pushes `?sheet=` / `?view=`; Esc closes the topmost layer; in-app links animate with React `<ViewTransition>` and `transitionTypes={['nav-forward'|'nav-back']}`; browser back plays no extra animation | n/a |
| Mobile web (PWA) | Same as desktop; no JavaScript edge swipe; iOS standalone uses the system swipe | `theme-color #000000`, `viewport-fit=cover`, black `appleWebApp.startupImage` so launch never flashes white; iOS Safari is on the frosted tier (§9.6) |

#### 4.0.6 Global keys (web, every app-frame screen; the same map on Flutter hardware keyboards)

`mod+k` command palette · `mod+b` collapse or expand the sidebar · `?` shortcuts dialog · `/` focus the screen's search field, else open the palette · `g h` Home · `g u` Updates · `g f` For you · `g l` Library · `g c` Collections · `g d` Downloads · `g y` History · `g b` Bookmarks · `g s` Sources · `g t` Stats · `g r` Friends · `g o` Dialogue search · `g p` switch profile · `g ,` Settings · `mod+enter` continue the most recent series · `shift+m` switch Manga / Novels · `r` refresh the current list · `Esc` close the topmost layer. Grids and lists: arrows and `h j k l`, `Enter`/`o` open, `.` or `shift+F10` item menu, `x` select, `shift+x` range select, `Esc` clear selection. Rows: `m` mark read, `d` download, `x`/`Delete` remove (with undo), `u` undo. Reorder: `alt+↑/↓/←/→`, `alt+shift+↑/↓`. Tabs: `[` / `]`. The shortcuts dialog and Settings → Shortcuts list only what is active on the current screen.

#### 4.0.7 Platform rules applied to every screen

Unless a screen lists its own deltas, the phone spec applies identically on iOS, Android and mobile web, the desktop spec on web ≥ 1024 px, and every screen's entry and exit follow §4.0.4. These rules then apply per platform:

| Platform | Rules |
|---|---|
| **iOS app** | Full-width swipe back; haptics per §2.11 (gaimon + AHAP); pull to refresh through `CupertinoSliverRefreshControl` with the droplet; context menus lift with `CupertinoContextMenu.builder`; the keyboard pushes the lit action up so it stays 16 px above it; status bar light; glass on the premium shader; gyro-driven key light; Dynamic Type through the text-scale rule; VoiceOver labels from every component's accessible name |
| **Android app** | Predictive back; haptics per §2.11 (API 34 constants with fallbacks); `BouncingScrollPhysics` everywhere; edge-to-edge with transparent bars; the same glass shader as iOS; gyro key light; font scale through the text-scale rule; TalkBack custom actions for every swipe and long-press action |
| **Mobile web** | The phone layouts; bottom sheets and viewers are URL state (`?sheet=`, `?view=`) so browser back closes them; long-press menus through Base UI `ContextMenu`; pull to refresh by the 60-line pointer handler (touch only, `overscroll-behavior-y: contain`); glass tier A on Android Chrome, tier B on iOS Safari; haptics only on Android Chrome (five events); no gyro light (fixed 135°); installable PWA with black startup images |
| **Desktop web** | Sidebar navigation; hover states on every interactive element (§3); right-click opens the same context menus; side sheets (SH3) and form panels (SH4) instead of bottom sheets; the command palette; every screen's keys plus the global map (§4.0.6); focus rings on keyboard focus only (`:focus-visible`); pointer-following key light |

### 4.1 Setup (server address; iOS and Android only)

- **Phone layout:** Bare frame, `default` mood field. Centred column max 420: the MM mark at 56 px in a T3 glass orb (the brand lens), `type.largeTitle` "Connect to your server" (heading reveal), body "Enter the address of your ManhwaManiacs server. You can change it later in Settings." IN1 "Server address" (`globe-simple` leading, URL keyboard, placeholder = the build's default URL, submit on Enter), B1 lit L "Connect" full width.
- **Signature moment:** while the check runs, the lit button's light run circles its rim; on success the orb's MM mark refracts through a quick dispersion flash (0 → 2 px → 0 over 400 ms) and the screen hands off to login with the lens morphing into the login form's orb.
- **States:** pending (field disabled, button loading "Connecting…"); invalid URL (IN1 error "That isn't a web address. Include https://."); https required in release builds ("Use an https:// address."); unreachable (error "No ManhwaManiacs server answered at that address." + helper "Check the address and that the server is running."); success (check glyph, 400 ms, then transition). Offline: the button reads "Connect when online" and the field keeps its value; retries on connectivity.
- **Transitions:** in: materialize of the orb then the column fades up (list stagger 14 ms). Out: the orb flies into login (shared element) on `spring.smooth`.
- **Gestures:** none beyond typing. Keyboard: Enter submits.
- Web: not present (the web client is served by the server).

### 4.2 Splash and first paint

- **Mobile:** the native splash (neutral MM column in `#F5F7FA` on `#000`, §7.3) hands off to the first Flutter frame, which redraws the mark identically and plays the **Lens reveal** (§7.4, 1,200 ms cold, 400 ms warm) while `GET /auth/me` runs (3 s timeout). The router leaves the moment auth resolves *and* the reveal reaches its handoff; if auth resolves first the reveal is not cut short; if the reveal ends first, the lens holds with a PR3 light run circling it.
- **Web:** the server renders the neutral mark inline on `#000` in the root layout; after hydration the same reveal plays once per session (`sessionStorage['mm.skin.splash']`), then hands off to the sidebar's wordmark (desktop) or the tab bar (phone).
- **States:** resolving (above); offline with a cached user → proceeds signed-in-offline with the N1 offline capsule on the first screen; server unreachable with no cached user → login's unreachable state; tap anywhere skips to the handoff.
- **Reduced Motion:** 200 ms cross-fade from the neutral mark to the app, one `light` haptic.

### 4.3 Login

- **Desktop layout:** Bare frame. Left 55 %: the ambient field at full strength with a slowly drifting stack of three blurred cover-shaped light slabs (no real covers: pre-auth has no data; these are aurora-coloured rounded rectangles 240 × 360 at 20 % opacity, rotating ±4° on a 40 s loop). Right: a T4 glass panel 440 wide, radius 34, centred vertically, 40 px from the right edge: the brand lens (MM mark in a 56 px orb), `type.largeTitle` title, `type.callout` subtitle, the form, footer.
- **Phone layout:** the same content as a full-height column; the glass panel becomes the content itself (no panel; glass never carries a form on phone, the fields sit on the field-lit canvas), the lit button pinned 16 px above the keyboard.
- **Hierarchy:** title → fields → lit "Sign in" → secondary links.
- **Elements:** server row (mobile only): "Server: {host}" `type.footnote` `label3` with IB3 `copy` ("Copied {url}" toast); IN1 Username (`user` glyph, autocomplete username, no autocorrect, autofocus on desktop); IN2 Password; TG1 "Keep me signed in" (default on); inline error block (N7 in `danger`); B1 lit L "Sign in"; B3 "Create an account" (only when registration is open) → Register.
- **States:** L1 resolving: the brand lens with PR2 indeterminate ring, nothing else. L2 server unreachable: object lens (`plugs`) "Can't reach the server" / "The ManhwaManiacs server did not answer. It may still be starting." + B1 "Try again" (+ on mobile B3 "Change server" → Setup). L3 bootstrap (no accounts): title "Welcome to ManhwaManiacs", subtitle "This server has no accounts yet. Create the first one; it becomes the administrator.", and the Register form in bootstrap mode inline (desktop) or B1 lit "Create the first account" (phone). L4 normal: "Welcome back" / "Sign in to your library." Pending: fields disabled, button "Signing in…". Errors: `invalid_credentials` "That username and password don't match.", `account_disabled` "This account has been turned off by the administrator.", `rate_limited` "Too many attempts. Try again in {n} s." (with a countdown ring on the button), empty fields "Enter your username and password." Offline: "You're offline. Sign in needs the server." with auto-retry.
- **Signature moment:** a successful sign-in makes the panel's glass thicken and pull inward into the brand lens (T4 → T5, 350 ms), which then becomes the profile picker's backdrop light.
- **Transitions:** in: panel materializes (250 ms) after the field has faded in (180 ms). Out: as above, then the profile picker.
- **Gestures / keys:** Enter submits from any field; Tab order Username → Password → Keep signed in → Sign in → Create an account.

### 4.4 Register

- **Layout:** as Login (panel on desktop, column on phone), with an IB1 back orb top-left on phone.
- **Elements:** IN1 Username (autofocus), IN2 Password (helper "At least 8 characters"), IN2 Confirm password (live "Passwords don't match." error and `aria-invalid`), IN1 Invite code (only when the server requires one; placeholder "From whoever invited you"; `key` glyph), IN1 Display name (optional), IN1 Email (optional, email keyboard), TG1 Keep me signed in, error block, B1 lit L "Create account" / "Create the administrator account" (bootstrap, with `shield-check` glyph), B3 "I already have an account".
- **States:** RG1 resolving (brand lens + ring); RG2 unreachable (as Login L2); RG3 closed: object lens (`lock-simple`) "Registration is closed" / "This server isn't accepting new accounts. Ask the administrator to create one for you." + B1 "Back to sign in"; RG4 bootstrap: "Create the first account" / "This account becomes the administrator."; RG5 open: "Join ManhwaManiacs". Pending: all fields disabled, "Creating account…". Errors (client): "Choose a username and password.", "Password must be at least 8 characters.", "Passwords don't match.", "Enter the invite code for this server.", "Enter a valid email address, or leave it blank."; (server): `username_taken` "That username is taken.", `invalid_username` "Usernames use letters, numbers, dots and underscores.", `invite_code_invalid` "That invite code isn't valid.", `registration_disabled` (switches to RG3), `rate_limited` (countdown), `bootstrap_window_expired` "The setup window has closed. Restart the server to claim it.", `bootstrap_already_claimed` "Someone already claimed this server. Sign in instead." Offline as Login.
- **Signature moment:** as each field validates, a tiny `success` check pops at its trailing edge; when every required field is valid the lit button's specular sweep plays once (it "turns on").
- **Transitions:** Login ↔ Register cross-fade the panel contents inside the same glass panel (the panel resizes on `spring.smooth`, content fades 120/180 ms).

### 4.5 Profile picker ("Who's reading?")

- **Desktop layout:** Takeover. The ambient field is built from the **hovered or focused profile's** current reads (its continue-reading covers' palettes; `default` mood field for a profile with none) and cross-fades 900 ms as focus moves. Centre: `type.display` "Who's reading?" (heading reveal on entry) and `type.callout` `label2` "Each profile keeps its own library, progress and mood." Below, a row of profile orbs at 132 px with 40 px gaps, names `type.headline` under them, and an "Add profile" orb (dashed 1.5 px `label3` ring, `plus` glyph) while fewer than 5 exist. Top-right: B2 "Manage" (toggles manage mode) and, when the account has more than one sign-in on the device history, B3 "Switch account" (signs out to Login).
- **Phone layout:** the orbs in a centred wrap, 112 px, 2 per row (3 on large phones), title `type.largeTitle`.
- **Per-orb extras:** BD3 18+ circle at 4 o'clock when the profile has mature content on; a 2 px ring in the mood rim tint; under the name, when the profile has a live streak, `flame` 12 + "12" in `flare`.
- **Manage mode:** every orb shows an `pencil-simple` IB5 in its centre over a 35 % black veil; tapping opens the profile form (edit). Helper text becomes "Choose a profile to edit it." Done (B2) exits.
- **Signature moment ("Step into the light"):** tapping a profile: `profile.switch` haptic; the chosen orb grows to 1.18 on `spring.bouncy` while the others dematerialize (blur 0 → 16 px, opacity → 0, scale 0.9, 18 ms stagger outward from the chosen one); the chosen orb's colours pour into the ambient field (the field's pools animate their colour to that profile's mood/reads over 600 ms); the orb then travels to its destination (the You tab's avatar on phone, the sidebar profile chip on desktop) on `spring.smooth` while Home materializes beneath it. Total 1,100 ms; any tap during it skips to the end. If the profile's saved skin is Cinematic, the handoff is where the restart happens (§4.25.1 step 7): the field goes white-hot for 120 ms (brightness 1.6) and the app restarts into Cinematic's own profile entry.
- **States:** loading: 3 orb bones with name bones; error: object lens "Profiles didn't load" + B1 "Try again"; empty: object lens (`users-three`) "Create your first profile" / "Profiles keep progress, follows and mood separate for everyone who reads here." + B1 lit "Add profile"; unreachable with a cached profile: title, "Continue as {name}, or try again once the server is back.", the cached profile's orb (selectable) + B2 "Try again"; unreachable with nothing cached: object lens (`cloud-slash`) "Profiles are unavailable" + B1 "Try again"; profile limit reached: the Add orb is absent and a footnote reads "5 profiles is the most an account can have."
- **Gestures:** tap = choose (or edit in manage mode); long-press = edit (context menu with Edit, and Delete for non-active profiles); arrow keys move focus between orbs; Enter chooses; `e` edits the focused profile; `n` adds.
- **Transitions:** in from login: the brand lens widens into the field; in from the app (switch profile): the current screen recedes and the picker materializes over it. Out: the signature above.
- **Reduced Motion:** choosing cross-fades to Home in 200 ms; no travel.

### 4.6 Profile form (add, edit) and Manage profiles

**Form** (`/profiles/new`, `/profiles/:id/edit`): takeover sheet on phone (SH1 at `large`), SH4 form panel on desktop blooming from the Add orb or the edit control.

- Header: live avatar preview 72 px (it refracts the field behind it), title "Add profile" / "Edit profile".
- IN1 "Name" (max 30 characters, counter at 24+, placeholder "Late-night reads", autofocus).
- "Avatar": a 6-column (phone 4-column) grid of the 12 glass orbs at 56 px (§3.26), selected with the `glacier` ring; each shows its name as a tooltip / accessible label.
- "Mood": seven C2 chips, each with a 12 px orb of its field colour; selecting one re-lights the whole sheet's backdrop field live (the live preview of what the app will feel like). Helper "Colours the light around the app while this profile is active. The reader stays neutral."
- "Mature content": the TG1 18+ switch with the full gate flow (§3.25).
- Error block; B4 "Cancel"; B1 lit "Create profile" / "Save changes"; edit only: B3 danger "Delete profile" → alert "Delete {name}?" / "This removes the profile with its library, progress, bookmarks and collections. It can't be undone." + B4 Cancel + B5 coral "Delete".
- States: loading (edit: bones); not found (object lens `user-circle-dashed`… use `user-circle` "Profile not found" / "It may have been removed." + B1 "Back to profiles"); saving (lit loading "Saving…"); errors `invalid_profile_name` "Give this profile a name.", `profile_limit_reached` "This account already has 5 profiles.", `invalid_mood` (cannot happen from the UI; generic error), server errors verbatim; offline "Profiles can't be changed offline." with the Save button disabled.

**Manage profiles** (`/profiles/manage`, reached from You → Profiles and the sidebar profile menu → "Manage profiles"): L1 grouped list, one row per profile: 44 px orb, name `type.headline`, "{Mood} mood · 18+ on" subtitle, "Active" BD4-style `glacier` tag on the current one; trailing B3 "Use" on non-active rows (switches in place with the Step-into-the-light choreography shortened to 500 ms), IB3 `pencil-simple` (edit), IB3 `trash` (delete alert). Header action IB1 `plus` (disabled at 5, tooltip "5 profiles is the maximum"). Rows reorder by drag (`PATCH /profiles/{id} {sort_order}`) with the reorder haptics and keyboard `alt+↑/↓`. States: loading (3 row bones), error (object lens + Try again), empty (cannot happen while signed in with a profile; if the list comes back empty, redirect to the picker's empty state).

### 4.7 Onboarding (a new profile's first visit)

Shown once per new profile, right after its first selection, as a takeover of five steps; every step has B3 "Skip" top-right and a 5-dot page indicator (`glass-page-control`: dots 6 px, the current one a 18 × 6 T1 droplet travelling on `spring.tab`). Horizontal swipe or `←/→` moves between steps; B1 lit "Continue" at the bottom.

1. **Pick your skin.** Two live miniature previews side by side (phone: stacked), each a 9:16 frame (radius 26) running its skin's Home loop (recorded as a 6 s muted MP4 per skin, 360 × 640, ≤ 400 KB, in `public/skins/` and Flutter assets). Glass is marked current. Choosing Cinematic shows "The app will restart in Cinematic after the last step." and the restart happens at the end, not now.
2. **What do you read?** Four big tiles (2 × 2): Manhwa, Manga, Manhua, Novels (Novels only when `novels_enabled`); multi-select, each tile a `slab.card` with a Light 40 px glyph that turns Duotone `glacier` when chosen; the selected tile's rim glows.
3. **Genres as droplets.** 24 genre droplets float in a loose cluster (glass T2 circles 64–88 px with `type.subhead` labels, drifting ±4 px on 12 s loops). Tap once: the droplet grows to 1.25 and turns `lit` (like); tap twice: 1.5 with a `flare` caustic (love); long-press: it pops and dematerializes (not for me; `threshold.cross`). Neighbours shift to make room on `spring.snappy`. The weights (1, 2, −1) are the AI's taste seed.
4. **Art style.** Nine unlabeled panel crops in a 3 × 3 grid (`slab.card` radius 14): full-colour webtoon painting, crisp cel shading, black-and-white screentone, manhua 3D/CG, watercolour, sketchy indie, retro 90s, chibi comedy, dark realism (crops ship as app assets, drawn in-house for the demo set, not publisher art); tap to like (glacier ring + check).
5. **Seed titles.** A poster grid drawn from the choices above via `POST /library/taste/seed` (returns 24 candidates from the connected sources, 18+ filtered by the profile's gate). Tap to add to the library; each pick pulls up to three similar titles into the grid next to it (they materialize with a 26 ms stagger). A live counter "Your home has 7 titles to start with" in `type.headline`. B1 lit "Finish" (enabled at ≥ 1 pick; "Skip" still available).

States: step 5 loading (poster bones), AI unavailable (step 5 shows the connected sources' Popular lists instead, with an `iris` notice "Picks come from your sources' popular lists while suggestions are unavailable."), offline (steps 1–4 work and are saved locally; step 5 shows the offline lens and "Finish" completes without seeds). Out: "Finish" plays the Home greeting typing reveal as the takeover dissolves into Home. Backend: `PUT /profiles/{id}/taste {formats[], genres{name: weight}, styles[], seeds[]}` (new, §9.5).

### 4.8 Home

- **Desktop layout** (content area right of the sidebar, max 1440):
  1. **Greeting line** at the top-left: `type.display` typed at 50 ms per character (§6.2), e.g. "Good evening, Yash." with the time-of-day word (morning 05–12, afternoon 12–17, evening 17–22, night 22–05), plus `type.callout` `label2` context line: "3 new chapters · 12-day streak" (each fragment a link).
  2. **Spotlight** (height 460): a floating hero card, not a full bleed. The spotlight series' cover (`w=720`) as a 300 × 450 poster tilted in 3D toward the key light (rotateY −6°, rotateX 3°, following the pointer ±6° on `spring.tilt`), standing in front of its own enlarged blurred copy (`blur.heroBackdrop`, scale 1.2, `scrimHero`) that fills the top 460 px of the content area and drives the field. To its right: eyebrow (`type.eyebrow`, e.g. "CONTINUE", "NEW CHAPTER", "FOR YOU" in `iris`, "FROM ANNA" in `bloom`), the title in `type.display` with the heading reveal, meta ("Manhwa · Ongoing · Ch 142"), 2-line synopsis, and actions: B1 lit L "Continue Ch 142" / "Read Ch 1", B2 "Previously on" (when there is progress; opens the recap), IB1 `plus` add to library, IB1 `dots-three`. Up to 6 spotlights rotate every 9 s (paused on hover, focus, or when the tab is hidden); 6 dot page control under the actions; `←/→` when the spotlight has focus.
  3. **Rails** (each §3.9): Continue reading (K1 decks, up to 12); New chapters (followed series with `read_state.new_count > 0`, posters with BD2); For you (AI, §5.1); Because you read {title} (AI, one rail per seed, up to 3); Friends are reading (§5.3, only when Friends is on and there is activity); Updated this week (the update tracker); your Collections (K4 stacks, first 6); Popular on {pinned source} (one per pinned source, up to 2; the source's `popular` browse mode). Rails with no items are omitted.
- **Phone layout:** large title "Home" is replaced by the typed greeting in `type.largeTitle`; top-right IB2 group: Updates bell (BD1 count) + profile avatar orb (opens the profile switcher menu). Spotlight becomes a swipeable card carousel: a 220 × 330 poster card centred with the next spotlight peeking 24 px at each side at scale 0.88 and 60 % brightness, over the blurred backdrop; title, meta and actions under the card. Rails follow. The bottom accessory shows the Continue pill.
- **Hierarchy:** greeting → spotlight → Continue → new chapters → AI rails → friends → the rest.
- **Signature moment ("Light follows the story"):** swiping or rotating the spotlight re-lights the whole screen: the field's pools slide from the old cover's colours to the new one's over 900 ms, every glass object's rim tint follows, and the tab bar's droplet catches the new colour. It is the most visible proof that the glass is bending real light.
- **Transitions:** tap a poster → cover zoom into Series; tap "Continue" → lens dive into the reader; the bell → Updates (push); "Previously on" → recap takeover (the button blooms into it).
- **Gestures:** pull to refresh (droplet) re-fetches continue, updates and AI rails; horizontal swipe on the spotlight; long-press posters for the context menu; swipe the Continue deck up to remove it from Continue (undo toast).
- **States:** loading: greeting bone, spotlight bone (poster 220 × 330 + three text bones), 3 rail bones. New profile with nothing read: the greeting reads "Welcome, {name}."; the spotlight shows the first onboarding seed or, without seeds, an object lens "Your home fills in as you read" + B1 "Browse sources" + B2 "Start onboarding"; the For you rail shows its AI state row. Error: each rail fails independently (rail error row); if everything failed, object lens "Home didn't load" + Try again. Offline: the spotlight and Continue come from the local store (downloaded series only, BD9 on each), a N1 offline capsule under the greeting, other rails omitted. Rate-limited: N6 capsule.
- **Keys:** `←/→` spotlight (when focused), `enter` open, `space` pause rotation, `p` Previously on for the spotlight, plus the global map.

### 4.9 Search

- **Phone layout:** tapping the search orb blooms it into the bottom search capsule (§3.4 S1) over the current place. Above the field: the scope segmented control (44 tall): **Library · Sources · Dialogue · Ask** (Dialogue hidden in Novels mode and when OCR is not available; Ask hidden when AI is not configured). Idle (no query), above the scopes from bottom to top: recent searches (C3 chips, max 8 per profile, with "Clear" B3), Trending on your sources (C3), a **Browse** grid of genre tiles (2 columns, 96 tall `slab.card` tiles, each with a cover from the genre tilted 18° into the bottom-right corner, colour from its palette), and a row "Search what characters said" (Dialogue entry, `bubble-search`). Results replace the idle content.
- **Desktop layout:** `/search` is a full page (palette results link to it with "See all results for {q}"): a 56 px S3 field at top (autofocus), the scope segmented control beside it, results below in groups; left filter column 240 wide (Format: Manhwa/Manga/Manhua/Novel; Status; Source picker with pinned first; genres as C5 tri-state chips) for the Sources scope.
- **Filters (phone, Sources scope):** a C1 "Filters" chip at the start of the result area opens a SH1 medium sheet: Format (Manhwa, Manga, Manhua, Novel), Status (Ongoing, Completed, Hiatus), Sources (pinned first, multi-select), genres as C5 tri-state chips, B3 "Clear"; the chip shows the count of active filters (BD1).
- **Results, Sources scope:** tier 1 renders first (pinned and followed sources, < 2 s), then "Searching {n} more sources…" with PR3 on the field while tier 2 runs (≈ 12 s). Groups: header (source icon 28, name `type.headline`, BD1 count, health dot), a horizontal rail of posters (phone) / a 6-column grid capped at 2 rows with "Show all {n}" (desktop). Failed group: row "This source didn't answer." + B3 "Retry" (retrying shows 4 poster bones). Empty group: omitted by default; a B3 toggle at the bottom "Show {n} sources with no matches". A jump bar (desktop: sticky chips of group names at the top of results) scrolls to a group.
- **Library scope:** `GET /library/search` results as K2 rows with read state. **Dialogue scope:** the OCR results (§4.23 row design) inline. **Ask scope:** the prompt field grows to IN3 (3–6 rows) in the capsule; submitting shows the AI result card list (K3 world cards with `why` lines, §5.1.3); quota "12 asks left today" `type.footnote` `label3`; unavailable states per §5.1.
- **Signature moment:** the scope thumb is a glass droplet: dragging it between scopes stretches it and the result list cross-fades live beneath at each boundary (`tab.scrub`), so the user can scrub through the four worlds of search with one finger.
- **States:** idle (above); typing (debounce 300 ms, light run); loading (per group bones); no results (object lens "No results for “{q}”" + suggestions: "Try Sources" / "Search dialogue" / "Ask for something similar"); error (object lens + Try again); offline (Library scope still works against the local store: downloaded and cached followed series; other scopes show the offline lens); rate-limited (N6).
- **Transitions:** close by swiping the capsule down (it shrinks into the orb); results → Series via cover zoom.
- **Keys:** `/` focuses the field, `Enter` searches now, `↓` from the field enters the results, `[`/`]` switch scopes, `Esc` clears then closes.

### 4.10 Sources

- **Desktop layout:** header `type.largeTitle` "Sources" + subtitle "{n} sources · {k} healthy" (from `GET /system/source-health`, a health ring 20 px beside it). S3 filter field + C2 chips All · Pinned · 18+ (18+ only when the profile has mature content) · Unhealthy. Sections: **Pinned** (drag to reorder; K9 rows in a 2-column grid of `slab.grouped` cards), **All sources** (3-column grid of K9 rows at ≥ 1280, 2 below). A B2 "Manage pins" toggles reorder mode (rows show a drag handle `dots-six-vertical`).
- **Phone layout:** large title, the filter field pinned under the title with a hard scroll edge when pinned, chips under it, then Pinned and All as single-column K9 lists in `slab.grouped`.
- **Novels mode:** only `content_kind == "novel"` sources; the title reads "Novel sources".
- **Signature moment:** pinning a source lifts its row into a T1 glass lozenge that flies up into the Pinned section on `spring.smooth` while the list closes the gap (`library.add` haptic); unpinning reverses it.
- **States:** loading (10 row bones); error (object lens "Sources didn't load" + Try again); none installed (object lens `plugs` "No sources installed" / "No novel sources installed"); no match ("No sources match “{q}”"); pinned filter empty ("Nothing pinned yet" / "Pin a source to keep it at the top."); pins failed to load (N7 notice "Pinned sources didn't load, so pinning is off until they do." + B3 Try again, pin controls disabled); pin save failed (toast `danger` "Couldn't update your pins." and the row springs back); unavailable pinned source (K9 unavailable state); offline (pinned sources and all names from the cache with the N1 capsule; opening a source shows its offline state).
- **Gestures:** tap row → Source catalogue (push, the source icon flies into the catalogue header); long-press → menu (Pin/Unpin, Open health details); drag handle reorder in manage mode; pull to refresh.
- **Keys:** `/` filter, arrows through rows, `p` pin/unpin the focused source, `alt+↑/↓` reorder pinned.

### 4.11 Source catalogue

- **Desktop layout:** header: source icon 48 (radius 12) + name `type.largeTitle` + health dot + meta "{shown} of {total} series" + BD6 stale chip when the catalogue is a saved copy + IB1 refresh (`arrow-clockwise`, spins while refreshing, tooltip "Refresh from the source"). Controls row: TB2 strip tabs for browse modes (server labels, only when > 1 and not searching), S3 search field "Search {source}…" with a B2 "Search" when typed, a Genre select (IN6 menu with the source's genres; only when the source has any). Grid of posters (`minmax(152px, 1fr)`), infinite scroll (sentinel 600 px before the end).
- **Phone layout:** large title with the icon, search field pinned, strip tabs under it, 3-column poster grid, B7 "Top" orb appearing after 400 px of scroll (bottom-right above the tab bar).
- **Novel sources:** the **book shelf** replaces the poster grid: rows of 56 × 84 cover plates (radius 6, squarer than posters, `border.content`), title in Literata 18/24 `wght 560`, byline "by {author}" italic, meta "{n} chapters · {status}", 2-line blurb in Literata 15/22 `label2`, genres `type.caption1` uppercase; hairline between rows.
- **Signature moment ("Opening {source}"):** first load of a source: the source icon sits in a 72 px T3 orb at the centre while a light run circles it; "Opening {source}" `type.title3`; after 3 s "This source can take about 10 s." Behind the orb, three poster-shaped light slabs cross-fade covers from the profile's recent reads every 3.5 s (or bones when there are none), tinted by the source's colour. When data arrives, the orb dematerializes and the grid materializes outward from where the orb was (stagger by distance from the centre, 18 ms).
- **States:** loading (above, with 12 poster bones below the orb); load more ("Loading more…" row with PR2) and load-more failure (row "Couldn't load more." + B3 Retry, refetches only that page); end ("That's everything from {source}." `type.footnote` `label3`); empty ("No series found" / "No results for “{q}” on {source}." / "{source} returned nothing."); error (object lens "{source} didn't answer" + the message + Try again + B3 "Back to sources"); stale (BD6 + tooltip, grid still usable); offline (the last cached page with BD6 "Saved copy" or the offline lens when nothing is cached); rate-limited (N6).
- **Gestures:** pull to refresh (`refresh=true`); swipe between browse-mode tabs; tap poster → Series (cover zoom); long-press poster → context menu.
- **Keys:** `/` search, arrows + `h j k l` grid navigation, `[`/`]` browse modes, `r` refresh.

### 4.12 Series detail (manga, manhwa, manhua)

One screen for every series, whether followed or not (the followed-only controls appear when it is followed). Reached from everything with a cover; `/library/:followId` resolves here.

- **Desktop layout:** the series' cover (`w=720`) blurred 60 px and scaled 1.2 fills the top 520 px behind everything as the backdrop, melting into canvas through `scrimHero`; the field is at 34 %. Two columns:
  - **Left column (380 wide, sticky at 24 px from the top):** hero poster 300 × 450 with a thin `mature` rim when 18+; under it the actions stack: B1 lit L "Continue Ch 41 · p. 12" / "Read Ch 1" / disabled "You're caught up" (plus B3 "Notify me about new chapters" when caught up and not following), B2 "Read all" (`infinity` glyph; > 1 chapter; tooltip "Every chapter as one scroll"), B2 "Previously on" (when progress exists), then an IB2 group: Follow (`bell-simple` / `bell-simple-ringing`), Favourite (star, `flare`), Add to collection (`stack-simple`), Recommend to (`paper-plane-tilt`, when Friends is on), Download (`cloud-arrow-down`), More (`dots-three`: Check this series for updates, Open source page, Mark all read, Mature override: "Treat as 18+" / "Treat as not 18+" / "Use the source's rating", Move to another source (disabled until the repoint endpoint exists; hidden instead), Copy link).
  - **Right column:** title `type.display` (heading reveal), author and artist `type.headline` `label2` ("by X · art by Y"), meta row BD4 status + source chip (icon + name, links to the source) + chapter count + "Updated 2 d ago"; when followed: an L1 grouped mini-list with **Reading status** (IN6 select: Not started, Reading, Completed, On hold, Plan to read, Dropped), **New-chapter alerts** (TG1 `notify`), and **Follow since {date}**; genres as C4 tags (link to the source catalogue filtered by genre); synopsis `type.body` clamped to 5 lines with B3 "More"; **Friends' reactions** summary (when any: avatars + "Anna loved Ch 40"); then the **Chapters** section; then the **More like this** rail (AI, §5.1).
  - **Chapters section:** header `type.title2` "Chapters" + "{n}" `label3`, a TB1 segmented Newest · Oldest (persisted per series), IN4 "Go to chapter", B2 "Select" (enters download select mode) and the downloads summary "{k} of {n} saved" with PR1. Rows (L2, 64 tall): chapter number in `type.mono` `label3` (decimal and null numbers render as given; null prints the title only), title (or "Chapter N"), subtitle date ("Today", "Yesterday", "3 d ago", or the date) + "12/40 pages" in `glacier` when in progress + "40 pages", trailing download control (§3.29); read rows `label3` with a `check` 14 `success`; the in-progress row has a 3 px `glacier` bar under its title at its progress. Friends' reaction glyphs (≤ 3 avatars 16 px) on rows they reacted to.
- **Phone layout:** the backdrop fills the top 60 % of the first screen; the hero poster (220 × 330) centred at 72 px from the top with the cover zoom landing on it; title `type.largeTitle` centred under it, meta, then the B1 lit L full-width "Continue", then a row of B2 "Read all" + B2 "Previously on", then the IB2 group row (Follow, Favourite, Collection, Recommend, Download, More), then status/alerts grouped list (followed), genres, synopsis (3 lines + More), then Chapters. The Chapters header becomes sticky with a hard scroll edge when it reaches the top orbs. Top-left IB1 back; top-right IB2 (share link, more).
- **Download select mode:** rows gain TG2 checkboxes (saved rows disabled); the bottom accessory slot turns into a **T2 glass toolbar** (the tab bar dematerializes on phone): "{n} selected · {k} already saved", C3 helper chips "Next 10", "All unread ({n})", "All ({n})", "None", B3 "Done", B1 lit "Download {n}". Running: the toolbar shows "Downloading {i} of {n}" + PR1 + B3 "Stop". Summary toast: "{n} chapters saved." / "Nothing to download: those are already saved." / "{a} of {b} saved, {c} with missing pages, {d} failed." + "Manage downloads" / "Out of room: only {size} free. Remove some downloads and try again." (`warning`). No profile: the Select button is replaced by N7 "Downloads belong to a profile. Choose one to save chapters." Shift-click / `shift+x` selects a range on desktop.
- **Signature moment ("The cover becomes the room"):** the cover zoom lands the poster while its blurred copy grows into the backdrop and its palette becomes the field: the whole screen is lit by the book you opened. Pressing Follow fires `library.add`, the bell glyph pops and a `glacier` caustic ring spreads once from the button across the backdrop (600 ms).
- **States:** loading (poster bone 300 × 450, 3 title bones, 8 chapter row bones); error (object lens "This series didn't load" / "The source didn't answer." + Try again + B3 "Back"); chapter list states: loading bones, "No chapters yet" / "{source} hasn't published any chapters for this series.", "Chapters didn't come through" / "{source} lists {n} chapters but returned none just now. That's usually the source." + Try again, offline "The chapter list needs a connection." (downloaded chapters still listed from the local store with BD9); follow feedback toasts "Following {title}. New chapters will show in Updates." / "Unfollowed {title}." + Undo; `follow_limit_reached` toast "This profile follows 1,000 series, the most it can."; offline page (rendered from the local store when the series has downloads, else the offline lens).
- **Gestures:** swipe back (full width iOS); pull to refresh; long-press a chapter row → menu (Read, Mark read/unread, Download, Bookmark start); swipe a chapter row (§3.33); pinch nothing; tap the hero poster → image viewer.
- **Keys:** `enter` Continue, `a` Read all, `f` follow, `s` favourite (star), `c` add to collection, `p` Previously on, `/` go to chapter, `x` select mode, arrows through chapters, `o` open, `m` mark read, `d` download, `[`/`]` sort.

### 4.13 Book page (novel series)

- **Desktop layout:** no cover backdrop (books are text): the field is the cover's palette at 18 %. A centred 960 column. Left 60 %: eyebrow "NOVEL · {source}", title in **Literata** 44/50 `opsz 72 wght 520` (heading reveal), byline italic Literata 20 "by {author}", a 56 px hairline, facts row `type.subhead` `label2` "{n} chapters · ≈ {n}k words · ≈ {n} h · {status}" + estimate note "Length estimated from {n} chapters read so far." `type.footnote` `label3`, genre links `type.caption1` uppercase, blurb Literata 17/29 max 62 ch. Right 40 %: the cover plate 200 × 300 (radius 6) standing on a thin T1 glass shelf (a 2 px specular line under it), then actions: B1 lit L "Start reading" / "Continue · Ch 12, 42 %", B2 "Listen" (headphones; opens the listen window at the resume point when audio exists), IB2 group: Add to library, Favourite, Collection, Recommend, More.
  **Audiobook row** (when novels TTS is enabled): an L1 group "Audiobook": status line ("Audiobook · 12 of 80 narrated", "Making audiobook · 3 in progress, 5 waiting", "Waiting for the narration PC", "Narration of new chapters isn't available right now.") with PR1, B3 "Narrate chapters…" (owner) / "Save audio to this device…" → the Audiobook sheet.
  **Contents:** header "Contents" Literata 24 + IN4 "Go to chapter" + TB1 "First → last · Last → first" (default first → last) + B2 "Pick chapters" (download select). TOC rows 52 tall: ordinal in Literata tabular 40 wide right-aligned (`·` when none), title Literata 16, meta `type.footnote` `label3` "3.4k words · 12 min", right column "42 %" `glacier` / "Read" `label3`, `headphones` 14 when narrated, download control. Read rows at 45 %. Windowed list of 400 around the focus with B3 "Show earlier chapters ({n})" / B2 "Show more chapters ({n})". `?chapter=` focuses a row (tinted `rgba(143,216,255,0.07)`, scrolled to centre). Go-to matches: up to 12 buttons "{title} · row {n}" + "and {n} more"; "Type a chapter number."; "No chapter {n} in this book."
- **Phone layout:** single column: plate 120 × 180 top-right beside the title block, then facts, the lit button full width, Listen + icon row, audiobook row, blurb (4 lines + More), Contents with a sticky header; the Go-to field opens the Contents sheet in search mode.
- **Audiobook sheet** (SH1, medium → large): header "Audiobook" + IB6 close; TB1 "Narrate · Save to device" (Save only with a downloads scope); unavailable notice "Narration of new chapters isn't available. Chapters that already have audio can still be saved."; C3 helpers "Next 10" (narrate), "All un-narrated ({n})" / "All narrated ({n})", "None"; checkbox rows per chapter with subtitles (narrate: "Narrated · saved on this device", "Narrated", "Download the text first"; save: "Saved on this device", "Saved copy can't play here · select to save again", "Saving…", "Couldn't be saved · select to retry", "Narrated", "Not narrated yet"); estimate "About {n} minutes of rendering on the narration PC." (9 min per chapter) / "Saves while the app is open. The text is saved too, so it plays and follows along offline."; B1 lit "Narrate {n} chapters" / "Save audio of {n} chapters" / disabled "Select chapters". Results toasts: "Queued {n} chapters. Skipped: 2 already narrated, 1 not on the server yet." / "Nothing to narrate." / "Saving the audio of {n} chapters." Jobs poll every 5 s (15 s while all jobs wait for the render PC; back-off to 60 s on failures); a running job row shows PR1 with its progress and IB3 `x` cancel (owner; toast "Cancelling. It stops shortly.").
- **Signature moment:** the cover plate catches the key light: as the pointer or device tilts, a specular glint slides across the plate's glass shelf, and the lit "Continue" button's caustic falls onto the blurb beneath it.
- **States:** front matter loading (plate bone + text bones); contents loading (10 row bones); offline ("This book needs a connection." or rendered from downloads with BD9); error "This book didn't load" + Back to source; contents unavailable "Contents didn't come through" + Try again; empty "No chapters yet" / "{source} hasn't published any chapters for this book."; audiobook `narration_unavailable` notice; library toggle feedback toasts ("Added {title} to your library. New chapters will show in Updates." / "Removed {title}." + Undo).
- **Keys:** `enter` continue, `l` listen, `/` go to chapter, `x` pick chapters, `[`/`]` order.

### 4.14 Manga reader (strip, pages, read-all)

Routes `reader` and `readAll`; both run the shared reader engine (web `features/reader`, Flutter `features/reader/engine/`) with the Glass chrome in its `chromeBuilder` slot. Reading behaviour (thresholds, preload, progress, bookmarks, zones) is the engine's and identical in both skins; this section specifies the Glass look, motion and feel.

#### 4.14.1 Canvas

- **Strip (default):** pages edge to edge, seamless (no gap unless Page gap is on: 8 px of `#000`), on `#000`. Phone: full width. Desktop: the strip is `clamp(480px, 50vw, 900px)` wide and centred; the gutters on each side are `frost25` wells in which the current page's palette glows as two very soft pools (top colour at the top of the gutter, bottom colour at the bottom, 10 % opacity, blur 120 px), so the page's light spills into the room without touching the art.
- **Pages (Single / Double):** fit-to-stage pages on `#000`, 8 px spread gap, RTL mirrors display order. Mobile gets page snapping on its horizontal list (snap by page width, `spring.page` settle) so Pages feels like pages on every platform. Double is offered on desktop, tablet and landscape phones.
- **Read-all:** the strip for the whole series; the scrubber shows chapter segments; the title capsule adds "12 of 200".
- **Background option:** Black `#000000` (default) or Graphite `#0A0A0A` (for readers who find pure black harsh around bright pages). There is no light page background.
- **Dimmer and warmth:** a black overlay at `|brightness|/100` alpha when brightness is below 0 (range −75 … 100, 0 = system level), and a warm `#FF8A00` layer at `warmth × 0.36` alpha (warmth 0–1); both pointer-transparent, under the chrome. Colour mode Normal / Sepia / Grey applies a colour matrix to the page layer only.

#### 4.14.2 Chrome

Glass floats over the pages in four places; every piece takes its rim tint and legibility dim from the page under it (page-tinted chrome, §5.4.4).

| Piece | Spec |
|---|---|
| Back | IB1 orb `caret-left`, top-left at `safe-top + 8`, 16 px from the edge |
| Title capsule | T3, 44 tall, top centre: series title `type.subhead` `label2` + chapter `type.headline` ("Solo Leveling · Ch 142"); Read-all appends "12 of 200" in `type.mono`. Tap → series page (or pops back to it when it is directly beneath) |
| Top-right group | IB2: bookmark (IB4, `bookmark-simple` → Fill `glacier` when this spot is bookmarked), download state (the §3.29 glyph as a glass orb), more (`dots-three` menu: Chapter list, Previously on, Panel view, Auto-scroll, Soundscape, Show dialogue text (when OCR text exists for the chapter), Cinema mode, Fullscreen (web), Keyboard shortcuts (web)) |
| Bottom capsule toolbar | T3, 56 tall, inset 16 px + safe area, max 720 wide on desktop: IB `skip-back` (previous chapter), the SL3 scrubber (flex), page readout `type.mono` "12 / 64", IB `skip-forward` (next chapter), IB `sliders-horizontal` (reader settings). Disabled chapter buttons at `label4` |
| Auto-scroll accessory | When auto-scroll is on: a T2 capsule 40 tall above the toolbar's right end: `pause`/`play` + "1.5×" `type.mono`; drag it vertically to change speed (logarithmic 0.5–3×, `autoscroll.step` per step) |
| Minimised pill | When the chrome hides by scrolling, the bottom toolbar **morphs** into a 32 px T2 pill at bottom centre showing "12 / 64" (and the auto-scroll glyph when running); the top pieces dematerialize (blur 8 px, scale 0.92, fade). Tap the pill to restore everything |

**Show / hide rules (the engine's, restated):** hide when the cumulative downward scroll since the last direction change reaches 24 px; show after 56 px of upward scroll, at a chapter end, on a centre tap, on pointer movement into the top or bottom 72 px band (desktop), on any key, or when Tab moves focus into the chrome. After a tap opened the chrome it idles out after 3000 ms, paused while a sheet, menu or scrubber drag is open. Never hidden during the first 800 ms after a chapter loads. **Cinema mode** (`c`, the more menu, Settings) hides the minimised pill too after 3 s idle; a tap, pointer move or `c` brings everything back; Esc leaves cinema before leaving the reader. With a screen reader running, the chrome never auto-hides.

Motion: show/hide on `spring.chrome` (the toolbar morph on `spring.minimize`); reduced motion swaps it for a 120 ms opacity fade.

#### 4.14.3 Gestures and input

| Input | Behaviour |
|---|---|
| Tap (strip, default layout "Tap shows controls") | Anywhere toggles the chrome. A soft radial light (120 px, `rgba(255,255,255,0.10)`) blooms at the tap point and fades in 300 ms (visionOS tap highlight) |
| Tap (strip, layout "Tap to scroll") | L-shape: top third + left-middle scrolls back 75 % of the viewport, bottom third + right-middle forward (300 ms `cubic-bezier(0.5, 1, 0.89, 1)`), centre toggles chrome |
| Tap (Pages) | 30 / 40 / 30 columns: left = previous, centre = chrome, right = next (mirrored for RTL until the user sets their own); `reader.page` haptic on each turn |
| Custom zones | Settings → Tap zones: each of Left / Centre / Right chooses Previous · Menu · Next |
| First run and after any zone change | Three T2 glass panes paint the zones with labels ("Back", "Menu", "Next"), hold 1500 ms, fade out over 1000 ms |
| Double tap | Zoom 1× ↔ 2× anchored at the tap point on `spring.smooth` (250 ms feel); `reader.zoom` |
| Pinch | Width zoom 1–3× in the strip (focal point kept), 1–4× per page in Pages; releases past the limits rubber-band (`c = 0.55`) and settle with bounce 0.18; `reader.zoom` at 1×, 2×, 3×. Web: `@use-gesture/react` 10.3.1 `usePinch` with `touch-action: pan-y` on the strip |
| Horizontal swipe (strip, not from the edge) | ≥ 72 px drags the previous/next chapter's title pill in from that side with a rubber band; release past the line commits the chapter change (`threshold.cross`, then `reader.chapterCommit`) |
| Left-edge vertical swipe (12 % band) | Brightness; a T2 HUD capsule 6 × 140 with a `sun` glyph shows the level (below 0: "Night −40") and lingers 600 ms |
| Right-edge vertical swipe (while auto-scrolling) | Auto-scroll speed with a "1.5×" HUD |
| Long-press a page (450 ms) | Page menu blooming at the finger: Bookmark here, Panel view from here, Show dialogue text (OCR), Retry this page (broken pages), View page (image viewer) |
| Edge swipe back | iOS only, the leading 20 pt, vertical strip at 1×; disabled in Pages and when zoomed |
| Overscroll at the top | 90 px pull reveals a T2 pill "Chapter 141" that commits on release past the line |
| Lock mode (mobile setting) | Only the centre region (20–80 % × 15–85 %) counts; five taps each within 2 s unlock ("Reader unlocked" toast, `reader.unlock`) |
| Android volume keys (setting) | Page down / up (the engine's bridge) |
| Wheel | Scrolls natively (no smooth-scroll library); Ctrl/⌘ + wheel zooms around the cursor with a zoom HUD for 1200 ms; in Pages one page per wheel gesture with a 200 ms idle reset |
| Middle-click (desktop) | Autoscroll anchor: 12 px dead zone, 10 px/s per px of distance, max 4000 px/s |

#### 4.14.4 Chapter boundaries

- **Continuous chapters on (default):** the engine stitches the next chapter in; between them sits the **seam**: 200 px of `#000` holding the eyebrow "END OF CHAPTER 142" (`type.eyebrow` `label3`), the reactions row (§5.3.3; only when Friends is on), then a 1 px hairline and the next chapter's title "Chapter 143 · The Gate" in `type.title2` with the heading reveal as it scrolls into view. As the seam passes under the top of the screen, a T2 chip "Chapter 143" sticks under the title capsule for 1.2 s and then melts (blur 0 → 8 px + fade 350 ms). `reader.chapterCommit` fires when the new chapter's first page crosses the reading line. Read-all uses only the chip (48 px seam, no reactions row) so a whole series reads "without feeling it".
- **When the next chapter is not stitched in** (continuous chapters off, the next chapter failed, offline without it, or the end of what the source has published): past the last page the strip rubber-bands and the **next-chapter card** (K12) sits on the content layer: `slab.card` 420 max wide, radius 26, padding 16: the next chapter's first page as a 96 × 144 thumbnail tilted 8° toward the key light (following the gyro ±4°), "UP NEXT" eyebrow, "Chapter 143" `type.title2`, "42 pages · about 6 min" `type.subhead` `label2`, friends' reactions summary, B1 lit "Read next". Pulling up past the card: at 90 px of overscroll a T4 glass sheet carrying the next chapter's first page rises from the bottom (`reader.chapterEnd` AHAP `ripple` as it locks); releasing past the line expands it to full screen (shared element) into the next chapter (`reader.chapterCommit`). Failure: the card reads "Chapter 143 didn't load" + B1 "Try again" + B3 "Open it on its own". Offline: "The next chapter needs a connection" + B2 "Download it for later" when online returns. **Caught up:** the card becomes "You're caught up" + "{source} hasn't published more yet." + B2 "Turn on alerts" (when not notifying) + the **More like this** rail (AI) + the reactions row.
- **Auto next chapter** (setting, when continuous chapters are off): at the end the card's lit button fills with light over 900 ms, then opens the next chapter; a tap anywhere cancels.

#### 4.14.5 Reader settings sheet

SH1 at medium on phone (the pages stay visible and update live above it); SH3 side sheet 440 wide on desktop. Sections as L1 groups on the glass (content-on-glass fills):

| Group | Controls | Persistence |
|---|---|---|
| Layout | TB1 Strip · Single · Double (Double on tablet/desktop/landscape only; hidden in Read-all); TB1 Direction Left to right · Right to left (Pages only; helper "Right to left is for manga"); TB1 Fit Width · Height · Whole page (Height and Whole page disabled in Strip with the reason in a tooltip) | Per series |
| Zoom | IN5 stepper 50–300 % in 10 % steps with a reset IB6 (`arrow-counter-clockwise`); helper "Pinch, double-tap, or hold Ctrl while scrolling." | Per series |
| Light | Two SL2 tiles side by side: Brightness (−75 … 100) and Warmth (0–100 %); C2 Colour: Normal · Sepia · Grey; C2 Background: Black · Graphite | Per profile |
| Motion | TG1 Auto-scroll + SL1 speed (0.5, 0.75, 1, 1.5, 2, 3×; base 60 px/s; ramps in over 400 ms; resumes 800 ms after a touch); TG1 Continuous chapters; TG1 Auto next chapter (when continuous is off); C2 Page turn Slide · Fade · None (Pages) | Speed per series; the rest per profile |
| Taps | Layout C2 "Tap shows controls" · "Tap to scroll" (strip); three TB1 rows Left / Centre / Right: Previous · Menu · Next; B3 "Reset" | Per profile |
| Chrome | TG1 Cinema mode; TG1 Page-tinted chrome (default on); TG1 Page gap (strip) | Per profile |
| Device (mobile) | TG1 Keep screen awake; TG1 Lock controls ("Tap the centre 5 times to unlock"); TG1 Volume keys turn pages (Android); C2 Refresh rate Auto · 60 · 90 · 120 Hz (Android) | Per device |
| Ambient | Row "Soundscape" (current scene + TG1) → Soundscape sheet (§5.4.2); Row "Panel view" (enter now) | Per profile |
| Web only | B4 "Fullscreen" / "Exit fullscreen"; B4 "Keyboard shortcuts" | — |

#### 4.14.6 States

| State | Spec |
|---|---|
| Loading a chapter | Three page bones (strip width, 2:3, `frost50` pulse) + "Loading chapter…" `type.footnote` `label3` under a PR3 light run; the chrome is shown |
| Page placeholder | A `#000` box at the manifest's aspect (or 2:3 when unknown) until the image decodes; no spinner; the decode fades in 180 ms |
| Broken page | Inside the page box: `image-broken` 28 `label3`, "This page didn't load" `type.callout`, B2 "Retry" (re-requests that page only) |
| Error | Object lens "This chapter didn't load" + the message + B1 "Try again" + B3 "Back to the series"; Read-all list failure: "This series' chapter list didn't come through, so there's nothing to read through yet." |
| No pages | Object lens "This chapter has no pages." + B3 "Back to the series" |
| Offline | A saved chapter opens from the device; a T2 capsule "Reading the saved copy" (`cloud-slash` `warning`) shows for 2 s under the title capsule; no neighbours, so the end shows the offline next-chapter card |
| Rate-limited pages | Pages beyond the next two wait with their placeholders; N6 capsule "The source is busy · retrying in 8 s" |
| Stale bookmark | Toast "That page is gone from this chapter. Opened at the nearest one." (5.2 s) |
| Bookmark saved / failed | Toast `success` "Saved this spot · page 7, 42 %" / `danger` "Couldn't save that spot." |
| Further on another device | When a progress save returns `advanced: false`, a toast "You're further on another device: Ch 44, page 3" + B3 "Jump there" (6 s) |

#### 4.14.7 Keys (web and hardware keyboards)

`→`/`d` and `←`/`a` turn by reading direction · `j`/`k` next/previous page · `space`/`shift+space` one screen · `home`/`end` first/last page · `g` go to page (opens IN4 in the toolbar) · `h`/`l` previous/next chapter · `ctrl+shift+←/→` same · `s` series page · `b` bookmark · `=`/`+`/`-`/`0` zoom · `f` fullscreen · `c` cinema · `m` show/hide chrome · `p` auto-scroll play/pause · `shift+,`/`shift+.` auto-scroll slower/faster · `v` strip · `1` single · `2` double · `t` chapter list · `,` reader settings · `shift+p` panel view · `shift+s` soundscape · `shift+r` Previously on · `?` shortcuts · `Esc` closes the topmost overlay → leaves fullscreen → leaves cinema → back to the series.

#### 4.14.8 Chapter list (inside the reader)

`t` or the more menu opens a SH1 sheet (desktop SH3) listing the series' chapters (the Series chapter rows, compact 52 px), pre-scrolled to the current chapter (tinted `rgba(143,216,255,0.08)`), with IN4 "Go to chapter" at the top; tap opens that chapter in place.

#### 4.14.9 Dialogue text overlay

"Show dialogue text" (more menu, or long-press a page) opens a SH1 medium sheet (desktop SH3) listing the recognised lines of the page in view (`GET /ocr/chapter` `page_texts`), each row `type.callout`; tapping a row outlines its box on the page with the T1 hit lens (§4.23) and scrolls it into view; B3 "Search this line" opens Dialogue search with it. Only shown when the chapter's text has been extracted.

#### 4.14.10 Reader landing (`/read`)

Reached only by URL: the object lens (`strip-scroll`) "Pick something to read" / "Open a series from your library or continue where you left off." + the K1 Continue deck of the most recent read (when any) + B1 lit "Go to Library".

#### 4.14.11 Platform deltas

- **iOS:** status bar hidden; `immersiveSticky`-equivalent full screen; home indicator auto-hides after 3 s; edge back 20 pt.
- **Android:** `immersiveSticky`; predictive back leaves the reader (the page column shrinks as a card toward the series); volume keys optional; refresh-rate pin reset on exit.
- **Desktop web:** the wide canvas with page-lit gutters; hover over the bottom 72 px or top 72 px shows chrome; the scrubber magnifier appears on hover; fullscreen through the Fullscreen API.
- **Mobile web:** the phone layout; pinch via `usePinch`; no volume keys, no wakelock (the Screen Wake Lock API is used where the browser supports it: `navigator.wakeLock.request('screen')`).

### 4.15 Novel reader

Route `novel`. The page is **paper**, and paper is content: it is never glass. The glass chrome floats over it and takes its rim tint from the paper's ink at 18 %.

#### 4.15.1 Paper

Dark-only papers (all AAA; text contrast 13.4–15.4:1, muted ≥ 5.8:1):

| Paper id | Background | Text | Muted |
|---|---|---|---|
| `void` (default) | `#000000` | `#D9D6D0` | `#8A877F` |
| `ink` | `#0B0B0C` | `#E6E3DD` | `#8F8C86` |
| `nightPaper` | `#15110C` | `#E8D8BE` | `#9C8E78` |
| `dusk` | `#0D1117` | `#D3DAE3` | `#8590A0` |
| `moss` | `#0E130F` | `#D5DECF` | `#879384` |
| `rosewood` | `#160E10` | `#EBD5D8` | `#A08A8E` |

Stored values of `mm.novel-settings.palette` map once to the nearest dark paper: Paper, Sepia, Cream → `nightPaper`; Solarized light, Solarized dark, Midnight, Dusk → `dusk`; Soft grey → `ink`; Dawn, Rosé Pine → `rosewood`; True black, site/app theme → `void`; Forest → `moss`.

#### 4.15.2 Layout

- **Phone:** one column, 24 px side margins (the Margins control sets 12–48), text as §2.3.5. Chapter head: eyebrow "CHAPTER 12" (`type.eyebrow` in the paper's muted colour), title in Literata `opsz 72, wght 560` at 1.55 em, a 56 px hairline, "3.4k words · 14 min" `type.footnote` muted. A B-style content button on paper, "Listen · 14 min" (`headphones`; capsule in ink at 8 % with a 0.5 px ink rim at 30 %) when audio exists. First paragraph ≥ 80 characters gets a 3-line drop cap in Literata `wght 600`. Following paragraphs indent 1.3 em (flush after headings and breaks); scene breaks are a centred "⁂" in the muted colour with 1.6 em above and below.
- **Desktop:** the column at the chosen measure (default 66 ch) centred in the content area; the sidebar hides (the novel reader is full screen) and the paper fills the window. Optional side panels (`slab.panel`, the thick standard material, tinted with the paper's colour at 86 %; content, not glass) slide in from the right for Contents, Bookmarks in this book, and Voices, 360 wide, pushing the column left.

#### 4.15.3 Chrome

| Piece | Spec |
|---|---|
| Running head | IB1 back orb (to the book) top-left; T3 title capsule top centre "Book title · Ch 12" `type.subhead`; top-right IB2: contents (`list-numbers`), bookmark (IB4), voices (`user-sound`, when a cast or narrator exists), type & page (`text-aa`) |
| Progress | PR4 hairline across the top under the safe area (always visible, even with chrome hidden; hidden in cinema) + the percent in the toolbar |
| Bottom toolbar | T3 capsule 56 tall: IB `caret-left` previous chapter, "42 % · 12 min left" (`type.subhead`; the time is the profile's measured pace, shown only after 2 min of samples), IB `caret-right` next chapter, and IB `headphones` (listen) when audio exists; `label4` when unavailable |
| Offline mark | BD9 in the title capsule when reading a downloaded copy |

Chrome toggles on a centre tap (25 / 50 / 25 zones in Paged; the whole page in Scroll), hides on 24 px of downward scroll, shows on 56 px up, idles out after 3000 ms when a tap opened it. Materials over paper: the glass samples the paper, so its dim uses `Lb` = the paper's luminance (all dark → 0.22) and the rim tint is the ink colour.

#### 4.15.4 Reading modes and page turns

- **Scroll** (default): one continuous column; native momentum; `BouncingScrollPhysics`.
- **Paged:** Apple Books-style pages (web: CSS multi-column pagination of the chapter column; Flutter: the text laid out into page-sized `TextPainter` slices in a `PageView`). Tap zones 25 / 50 / 25, or "Both margins advance", or the one-hand preset (left 20 % back, top 12 % menu, the rest forward). Page turn options:
  - **Slide** (default): the page slides on `spring.page` with an 8 px soft shadow on its leading edge; finger-tracked, fling-projected.
  - **Lift** (Glass's own): the page lifts around its spine like a pane of glass: `rotateY` 0 → −100° with `perspective: 1600px`, a specular band crossing it as it turns, the next page beneath un-dimming 0.85 → 1; finger-tracked, settles on `spring.page`; pure transforms on both platforms (CSS 3D on web, `Transform` with `Matrix4.setEntry(3, 2, 0.0006)` on Flutter), no capture or shader.
  - **Fade:** 160 ms cross-fade.
  - Reduced Motion: Fade regardless of the choice.
- **Line guide** (setting): two frosted bands (`blur.lineGuide` 6 px, 55 % of the paper colour) above and below the current line band (2 lines tall); tap above/below to move it, or drag it.

#### 4.15.5 Type and page sheet

SH1 at medium (≤ 50 % of the height so the text reflows live above); desktop: a T4 popover 380 wide blooming from the `text-aa` orb (Esc or outside click closes). Contents: face tiles "Literata" / "Google Sans" each set in its own face (selected: `fill2` + ink rim); IN5 steppers Size (14–30), Line height (1.30–2.20), Measure (desktop, 48–88 ch) or Margins (phone, 12–48 px), Paragraph spacing (0–1.2 em); SL1 sliders Character spacing and Word spacing; TG1 Bold text; TG1 Justify and hyphenate; Paper: six **paper orbs** (40 px circles in each paper's background with "Aa" in its ink and a specular rim; the selected one has a 2 px `glacier` ring); TB1 Mode Scroll · Paged; TB1 Page turn Slide · Lift · Fade (Paged); TG1 Line guide; SL2 Brightness tile (−75 … 100); B3 "Reset to defaults". Typography persists per book, the paper and mode per profile. `detent.tick` on every stepper and slider step.

#### 4.15.6 Contents sheet

SH1 at large (85 % of the height) in the paper's colours (content inside a glass sheet uses fills, so rows are paper-toned `fill` rows): "CONTENTS" eyebrow, IN4 "Go to chapter" (autofocus when opened from the book's search), rows 52 tall (48 px tabular ordinal + title, current row at ink 7 % and `wght 600`), pre-scrolled to the current chapter; match list (max 30 + "and {n} more"), "Type a chapter number.", "No chapter {n} in this book."; loading ring; offline "The contents need a connection."

#### 4.15.7 Chapter end

After the last paragraph: a 96 px hairline, "END OF CHAPTER 12" eyebrow, "3.4k words · 14 min", the reactions row (Friends on), then the **next card** (paper-toned slab, radius 20: "NEXT" eyebrow, "Chapter 13 · The Tower" Literata 20, "3.2k words", `caret-right`) or "You've reached the last chapter {source} has published." + B2 "Turn on alerts"; B3 links "Previous chapter" and "Back to the book". **Seamless next:** an overscroll of ≥ 140 px at the bottom, `l`, or the card marks the chapter complete and swaps the next one in at the top (URL replaced); `reader.chapterCommit`. **Auto next** (setting): after 900 ms at the end, unless narration is playing.

#### 4.15.8 States

Loading: the paper colour with 12 text bones in the ink colour at 8 % (varied widths 100/94/97/88/60 %…), the running head live. Offline: the downloaded copy (BD9); no copy → object lens on paper "This chapter needs a connection." + B2 "Back to the book". Error: "This chapter didn't load" + Try again + Back to the book. Empty: "This chapter came through empty" / "The source answered with no text. The chapter may have been pulled or not finished yet." Text-changed bookmark: toast "The text here changed. Opened at the nearest paragraph." Bookmark toasts: "Saved this spot · 42 %" / "Couldn't save that spot."

#### 4.15.9 Gestures and keys

Tap zones as above; vertical scroll; pinch changes the **text size step** (one step per ×1.15 of scale, `detent.tick` per step, reflow when the pinch ends); left-edge vertical swipe = brightness HUD; long-press a paragraph (450 ms) → menu: Bookmark here, Listen from here, Copy paragraph, Show speaker (when attributed). Keys: `h`/`l` chapters · `↑`/`↓` scroll · `space`/`shift+space` page · `home`/`end` · `=`/`+`/`-`/`0` text size · `t` type & page · `i` contents · `b` bookmark · `g` go to % · `p` listen play/pause · `f` fullscreen · `c` cinema · `m` chrome · `?` · `Esc` closes the panel, then back to the book.

### 4.16 Listen mode (narration with the 31 named voices)

Narration is pre-rendered per chapter (`GET /novels/audio`), fetched on the first play, with a segment timing map for sentence and word highlighting, a cast of characters mapped to voices, and 31 named voices that each introduce themselves.

#### 4.16.1 Mini player

- **In the novel reader:** a T2 capsule 56 tall floating 8 px above the bottom toolbar: the narrator's voice orb 32, "Chapter 12 · Mara" `type.subhead` + "5:12 · −18:40" `type.mono` `label3`, IB6 `rewind` (−15 s), a B1-lit 40 px circular play/pause, IB6 `fast-forward` (+15 s); a 2 px progress line along its bottom edge (buffered at 35 %). It stays when the chrome hides for 5000 ms, then minimises into the pill with a 12 px playing waveform glyph; pinning (long-press → "Keep visible") keeps it. Swipe left/right = next/previous chapter.
- **Anywhere else in the app:** the tab bar's bottom accessory (§3.15), inline when the bar minimises.

#### 4.16.2 Listen window

Opened by tapping the mini player, the book's "Listen" button, or `/…/listen`. A **T5 monolith window**: phone full screen with 8 px insets and `radius.2xl` 44 corners floating over the receded reader; desktop 880 × 640 centred, radius 34.

- **Top:** grabber, IB6 collapse (`caret-down`), title capsule "Book · Chapter 12", IB6 more (Save audio to this device, Voices & cast, Sleep timer, Go to chapter text).
- **Art:** the cover on a 240 px (desktop 280) card, radius 26, with gyro/pointer parallax ±6 px and the key light moving across it; the field behind the window is the cover's palette at 34 %.
- **Lyrics view:** the chapter's sentences in Literata 20/30 on the glass: the active sentence at `label` on a brighter lozenge (`fill2`, radius 14, padding 4 × 8) that **morphs** from sentence to sentence on `spring.morph` (a shared layout animation, not a cross-fade); other sentences at 40 %; speaker-tinted sentences take their tint on the lozenge rim. The active sentence is kept at 38 % of the view's height; a user scroll decouples and shows the T2 pill "Back to voice" (`user-sound` + label); the view returns by itself after 4000 ms idle.
- **Transport:** SL1 scrubber with times; IB6 −15 s, previous sentence (`skip-back`), a B1 lit 72 px play/pause circle, next sentence (`skip-forward`), +15 s.
- **Three tiles** (`fill2` rounded 20, 64 tall): **Speed** "1.25×" (opens the SL4 dial; chips 0.8 / 1 / 1.25 / 1.5 / 2 under it; the words-per-minute equivalent in `type.footnote`), **Voices** (the narrator's orb + "Mara"; opens the gallery), **Sleep** ("Off" or the live countdown; menu: Off, 5, 10, 15, 30, 45, 60 min, End of chapter, End of next chapter, Custom…). The volume fades out over the last 8 s; on mobile, shaking the phone during the last minute extends by 5 min (`notify.success`).
- **Highlight in the page view (reader):** the active sentence gets a band at 14 % of its speaker's tint (narration: `glacier` at 12 %), radius 6, padded 2 × 4, cross-fading 120 ms between sentences; the spoken word brightens to 100 % with a 2 px underline in the tint, stepping without animation. Follow keeps the sentence at 38 % of the viewport, scrolling (400 ms ease-out) only when it leaves the 20–70 % band and jumping when it is more than 2 viewports away; a manual scroll decouples ("Back to voice" pill, no auto-return in the page view). If the text no longer matches the timing map (`highlight_safe` false or fingerprint mismatch), nothing is highlighted and a quiet line reads "Highlight paused: the text changed."
- **Chapter boundary:** a post-play card inside the window: "Next chapter in 5" with a PR2 ring counting down, B1 lit "Play now", B3 "Cancel"; the chrome shows during the countdown.
- **Signature moment ("The voice has a place in the room"):** the lozenge sliding from sentence to sentence refracts the words beneath it like a moving lens, and the voice orb's inner light pulses with the audio's amplitude (sampled at 30 Hz, orb scale 1 → 1.04, light 0.6 → 1.0).

#### 4.16.3 Voice gallery (31 voices)

Opened from Voices tiles, the cast sheet, or Settings → Reading → Voices. SH1 at large (desktop SH4 720 wide).

- **Orbit carousel (default view):** the voices on a horizontal carousel with depth: the centred card at scale 1.0, neighbours at 0.86 and 60 % brightness, further ones at 0.74 and 30 %. Each card: a 96 px **voice orb** (a glass sphere whose inner colour runs from `#34488F` for the deepest voice to `#FF9ED8` for the brightest, interpolated in OKLCH by `pitch_hz` across the pack's range), name `type.title3`, character line (e.g. "the weary knight") `type.subhead` `label2`, gender, a **pitch scale** (a 120 px capsule track with a dot placed by `pitch_hz`, labelled "deeper ↔ brighter"), an **expressiveness** meter (5 dots), and the licence/credit in `type.caption1` `label3`. B4 "Use" / "Chosen" (with a `glacier` check). The centred voice plays its self-introduction after 400 ms at rest **once the user has played any voice in this session** (never on first open); tapping the orb plays or stops it; while playing, a waveform ring (the clip's amplitude) circles the orb; `voice.preview`.
- **Grid view** (toggle top-right `squares-four` / `rows`): 2 columns phone, 4 desktop, the same cards at 160 tall.
- **Filters:** C2 All · Female · Male · In use; S3 search by name or character.
- **Ordering:** by gender, then deepest first (the server's order).
- **States:** loading (6 card bones); no voices installed: object lens (`voice-31`) "No voices are installed" / "The server has no voice pack, so characters can't be cast yet."; sample missing: "No preview available" in place of the play control; sample failed: toast "That preview didn't load."; saving a choice: B4 loading, then toast "Mara will narrate this book." / `danger` "That voice couldn't be saved. {reason}".

#### 4.16.4 Cast sheet

SH1 at medium (desktop SH3): "VOICES IN THIS CHAPTER" eyebrow; status line ("Looking up who speaks here…", "Nobody else was identified with enough confidence, so the narrator reads it all.", "Narrated by {name}: their own lines use the narrator's voice because they are the same person."); the **Narration** row pinned on top (narrator orb + voice name or "Default voice", `caret-right`); then one row per character, ordered by line count: speaker tint swatch 12 px (dashed when unhued), name `type.headline`, voice name or "Automatic" `type.subhead` `label2`, share of lines "18 %" `type.mono` `label3`, `lock-simple` 14 when hand-cast. Tap a row → the gallery filtered to the character's gender with "A voice for {name}" as its title and the helper "Tap a name to hear it introduce itself. Chapters already rendered keep their voice until they're rendered again." After a change the row reads "Re-voicing…" with a PR2 ring until the next render. Owner-only actions (other accounts see rows read-only): long-press a row → "Same character as…" (a menu of the other names; `POST /novels/cast/alias`, toast "{alias} now reads as {canonical} everywhere in this book"). Empty: "Nobody else was identified with enough confidence to be given a voice, so the narrator reads this chapter." No voice pack: "No voices are installed on the server, so characters can't be cast yet."

#### 4.16.5 Narration save and states

Save control (IB3 in the window's more menu and the mini player's long-press): "Save audio to this device" (`download-simple`) → PR2 "Saving audio…" → `check-circle` `success` "Audio saved on this device" (tap → alert "Remove saved audio?" / "The chapter stays on this device to read. You can save its audio again any time." + B4 Keep + B5 Remove) → failed `warning-octagon` "Couldn't save the audio · tap to try again" → unplayable `arrows-clockwise` `warning` "The saved audio can't play on this device · tap to save it again".

| State | Spec |
|---|---|
| No narration for the chapter | The Listen button and headphones orb are hidden; the reader shows nothing else |
| Preparing (`503 audio_preparing` on the first m4a request) | Play shows a PR2 ring and "Preparing audio…"; retries every 3 s for up to 60 s, then the failed state |
| Failed | Play shows `warning-octagon`, tooltip "Audio couldn't load"; tap retries |
| Offline | Saved audio plays and follows along; without it: "Narration needs a connection or a saved copy." |
| Audio-only (text mismatch) | A quiet line under the Listen button: "The audio doesn't match this text, so it plays without highlighting." |

Keys (window and reader): `p` / `space` (window) play/pause · `[` / `]` previous/next sentence · `shift+[` / `shift+]` −15/+15 s · `shift+,` / `shift+.` speed −/+ 0.05 · `v` voices · `z` sleep menu · `Esc` collapses the window. Mobile: lock-screen and headset controls through `just_audio` + `audio_session` (already in the app) plus `audio_service` for the media session (the newest 0.18.x release that resolves on Flutter 3.44.6, pinned exactly in the foundation session); the session stays `speech`.

### 4.17 Library (Following)

One screen holds the followed library with every filter, sort and density; the shelf and the full filterable list are the same place.

- **Phone layout:** large title "Library" + subtitle "{n} series followed" / "{n} novels on your shelf"; top-right IB2: select (`check-square-offset`), sort (menu: Recently updated, Recently read, Recently added, Title A–Z, Title Z–A, Manual order), view (grid `squares-four` / list `rows`). Under the title, the **places row**: four content tiles 150 × 72 (`slab.card` radius 20, horizontal scroll): Collections ("{n}"), Downloads ("{n} saved · 1.2 GB"; a PR2 ring when active), History ("Last: Solo Leveling"), Bookmarks ("{n}"). Then an "In progress" rail of K1 decks (up to 12, hidden while searching or filtering). Then the **Following** section: S3 field "Search your library" (pins under the top edge with a hard scroll edge), C1 chips: All · Reading · Not started · Completed · On hold · Plan to read · Dropped · ★ Favourites · Has new · Downloaded, then the grid (3 columns) or list (K2 rows). Novels mode: the book shelf (as §4.11) instead of posters.
- **Desktop layout:** header "Library" + TB1 lens tabs **Following · Collections · Downloads · History · Bookmarks** (each is its own route; the tab thumb travels on `spring.tab` and the content cross-fades); Following view: a toolbar row (S3 search, chips, sort IN6, density TB1 Comfortable · Compact · List, B2 "Select"), the In-progress rail, then the grid (`minmax(152px, 1fr)`; Compact `minmax(112px, 1fr)` with titles only; List = K2 rows in a 2-column layout at ≥ 1440).
- **Posters** carry the read state from `read_state`: meta "Ch 41 of 120", "3 new" (BD2), "Not started", "Caught up"; the bottom hairline shows `position/total`; favourites show a `flare` star 14 at bottom-left.
- **Select mode:** posters and rows show TG2 checks; Shift-click / `shift+x` range. The bulk toolbar replaces the accessory (phone; the tab bar dematerializes) or floats at the content's bottom centre (desktop): a T2 capsule "{n} selected" + B3 "Select all {visible}" + IB6 actions: Favourite, Unfavourite, Mark read, Mark unread, Add to collection, Download next 5, Unfollow (`danger`) + B3 "Done". Running: "{done} of {total} · {failed} failed" + PR1 + B3 "Stop" (concurrency 4). Unfollow commits with an undo toast (6 s) that re-follows and restores favourite, status, alerts, mature override and position. Results: toast "Stopped: {n} unfollowed, {m} failed, {k} skipped." / "Nothing changed: all {n} failed." / "{n} marked read."
- **Manual order:** in "Manual order" sort, long-press (touch) or the drag handle (desktop hover) reorders posters (`PATCH sort_order`), with the reorder haptics and `alt+arrows`.
- **Signature moment ("Grid to list"):** switching density morphs every visible cover from its grid cell to its list thumbnail (shared layout on `spring.smooth`, 12 ms stagger by index) while titles cross-fade; the light pools of the field stay put, so the shelf rearranges under the same light.
- **States:** loading (title bone + 12 poster bones or 8 row bones; novels 8 shelf rows); empty library: object lens `books` "Your library is empty" / "Follow series from your sources and they'll live here." + B1 lit "Browse sources" + B3 "Search"; novels: "Your shelf is empty" / "Add a book from a novel source to start your shelf."; search empty "Nothing called “{q}” in your library" + B3 "Search every source for “{q}”"; filter empty "No series match these filters" + B3 "Clear filters"; over 200: footnote "Showing the first 200 of {total}. Search or filter to narrow it."; offline: followed series from the device's follow cache (phone) with the N1 capsule, posters without downloads at 60 % and not openable offline ("Needs a connection" tooltip); error: object lens "Your library didn't load" + Try again; no profile: redirect to the picker.
- **Gestures:** pull to refresh; long-press poster → context menu (Open, Continue, Favourite, Add to collection, Mark read/unread, Download next 5, Previously on, Remove from library [with undo]); tap → Series (cover zoom).
- **Keys:** `/` search, arrows + `h j k l` grid, `enter` open, `x` select, `shift+x` range, `f` favourite, `m` mark read, `.` menu, `[`/`]` lens tabs (desktop), `v` switch density.

### 4.18 Collections and collection detail

**Collections** (`/library/collections`).
- **Layout:** phone: large title "Collections" + "{n} collections"; IB2 top-right: sort (Name A–Z, Most series, Recently created, Manual order); S3 "Search collections" (shown with ≥ 1 collection); a 2-column grid of **K4 collection stacks** (desktop 3–4 columns); B7 orb "New collection" (`plus`) bottom-right above the tab bar (desktop: B1 lit "New collection" in the header). Shared collections (§5.3.5) carry member avatars and a `bloom` rim.
- **New collection:** SH1 medium / SH4 desktop blooming from the orb: IN1 Name (placeholder "Rainy-day reads", max 80), IN3 Description (optional), error line, B4 Cancel, B1 lit "Create" / "Creating…" (disabled while empty).
- **Signature moment:** opening a stack fans its three covers apart (±10°) and then the fan flies into the detail's header (shared element), where it spreads into a 5-cover arc.
- **States:** loading (4 stack bones); empty: object lens `stack-simple` "No collections yet" / "Group series by mood, theme or reading plan." + B1 lit "Create your first collection"; no match "No collections match “{q}”"; error; offline (cached list with the N1 capsule; create disabled "Collections can't be changed offline").
- **Keys:** `n` new collection, `/` search, arrows through stacks, `alt+arrows` reorder in manual order.

**Collection detail** (`/library/collections/:id`).
- **Layout:** header: a 5-cover arc of the first members (the backdrop behind it is their blended palette), name `type.largeTitle` (heading reveal), description, "{n} series"; actions: B2 "Add series", IB2 group: Edit (`pencil-simple`), Select (remove mode), Share with friends (§5.3.5, when Friends is on), More (Delete collection). Member grid of posters (same as Library), each with a `⋯` / long-press "Remove from collection". Members are joined to library rows for titles and covers; a member no longer followed shows its key as the title with the subtitle "No longer in your library" and a B3 "Follow again".
- **Add series:** SH1 large / SH3: S3 "Search your library", list of followed series not in the collection (48 × 72 thumbs + title); tap adds with `library.add` and a check pop; the sheet stays open for more (Done closes); loading 4 row bones; "Everything in your library is already here." / "No series match “{q}”."
- **Edit:** the New-collection form prefilled, "Save" disabled until something changes.
- **Remove:** swipe a poster's row (list view) or select mode + B5 "Remove {n}" in the bulk toolbar; explainer in the toolbar "Removing takes series out of this collection only. They stay in your library." Undo toast.
- **Delete:** alert "Delete {name}?" / "The series in it stay in your library. This can't be undone." + B4 Cancel + B5 coral "Delete".
- **States:** loading (arc bone + 6 posters); empty: object lens "This collection is empty" + B1 lit "Add series"; mode mismatch: "No {novels/series} here" / "This collection holds titles from the other reading mode. Switch modes to see them." + B3 "Switch to {mode}"; error "This collection didn't load" + B3 "Back to collections"; offline (cached members, editing disabled).

### 4.19 History

- **Layout:** large title "History" + "What you've been reading, newest first."; TB1 **By series · Timeline**. By series (`collapse=series`): poster grid (3 columns phone, `minmax(152px,1fr)` desktop); each cover carries a 3 px progress hairline and a `clear` glass capsule at bottom-right (IB5-style, 28 tall) "▶ p. 12" (manga) / "▶ 42 %" (novels), or "▶ Next" when the last chapter was finished (it resolves the next chapter, `aria-busy` with a ring while resolving, falling back to the series page). Title 2 lines, subtitle "Ch 12 · finished · 3 h ago". Timeline (`collapse=none`): day headers (`type.footnote` uppercase "TODAY", "YESTERDAY", "MON 21 SEP"), rows: 40 × 60 thumb, "Chapter 12 · The Gate", series title `label2`, time `type.mono` `label3`, "12 min" read time; tap opens that spot.
- **Pagination:** 50 per page, infinite scroll (`offset`).
- **Signature moment:** in By series, pressing the resume capsule makes it grow and brighten (it is glass over art) while the cover behind it dims to 80 %, then the lens dive opens the reader at the exact page.
- **States:** loading (10 poster bones / 8 row bones); empty: object lens `clock-counter-clockwise` "Nothing read yet" / "Chapters you open show up here as you go." + B1 "Go to library"; unknown series title: "Untitled" in `label3`; error; offline (entries whose chapters are downloaded remain openable; the list is the last cached page with the N1 capsule).
- **Keys:** arrows, `enter` resume, `[`/`]` switch views.

### 4.20 Bookmarks

- **Layout:** large title "Bookmarks" + "Exact spots you saved."; C2 chips: All · each series with bookmarks (up to 12, then "More…" menu); K10 cards in one column (desktop 2 columns ≥ 1280). Card: series title, "Chapter 14 · page 7 · 62 %" (manga) / "Chapter 14 · paragraph 118 · 62 %" (novel), snippet (novels; Literata italic 15/22, 2-line clamp, `glacier` left rule), note (`type.callout`), saved date `type.footnote` `label3`, stale note `warning` "Position approximate: the text changed". Tap → reader at `?page=&at=` or novel at `?para=&at=`. Card actions (`⋯` / long-press / swipe): Edit note (SH1 with IN3; saved through the bookmark outbox `op: upsert`), Remove (undo toast 6 s: undo re-creates the bookmark with the same anchor).
- **Signature moment:** opening a bookmark from a novel snippet: the snippet's `glacier` rule stretches into the reading line at 38 % of the reader, landing the sentence exactly where the eye expects it.
- **Keys:** arrows through cards, `enter` open, `e` edit note, `x`/`Delete` remove (undo), `u` undo.
- **States:** loading (5 card bones 96 tall); empty: object lens `bookmark-simple` "No bookmarks yet" / "Press B while reading, or tap the bookmark in the reader, to save the exact spot." + B1 "Go to library"; error; offline (mobile reads the local store and syncs later: "Saved on this device · will sync" `type.footnote`); removing ("Removing…" on the card).

### 4.21 Updates

- **Entry:** Home's bell orb (BD1 count; `aria-live` announces changes), sidebar Updates, `g u`, the N2 notice, a long-press on the Home tab (Mark all read).
- **Layout:** large title "Updates" + "{n} unread · {m} followed"; IB2 top-right: Check now (`arrow-clockwise`; PR3 light run on the title capsule while a run is in progress), Mark all read (`checks`; per content mode: "Mark all manga read" / "Mark all novels read"). TB1 **New · Following**. A schedule line under the title: "Checking every 30 min · last check 12 min ago · next about 18 min" (`type.footnote` `label3`; `warning` "Overdue by 12 min" when the next run is late; admins can tap it → Settings → Notifications).
  - **New:** K8 update groups, one per followed series (notifications grouped by `followed_series_id` and joined to the library for title and cover), newest first. Chapter chips open the reader (manga) or novel reader at that chapter and mark it read. Swipe the group: leading "Read" (opens the newest), trailing "Mark read". Read groups fall to 60 % and move under a "Earlier" divider.
  - **Following:** the followed list as K2 rows with "Last checked 2 h ago" / "Not checked yet", TG1 new-chapter alerts per series (`PATCH notify`), IB3 `arrow-clockwise` "Check this series" (`POST /updates/followed/{id}/check`), and swipe/menu "Unfollow" (undo toast).
  - **Admin:** a "Recent checks" section at the end: up to 8 runs as rows "{trigger} · {status} · {n} series · {n} new" + time; status tag coloured (completed `success`, running `glacier`, failed `danger`).
- **Signature moment:** "Check now" sends a light run around the title capsule; each series that gains chapters during the poll (unread count polled at 3, 5 and 7 s) slides into the list from the top with a single `glacier` shimmer across its row.
- **States:** loading (3 group bones); empty New: object lens `bell-simple` "You're all caught up" / "New chapters appear here the moment they're found." + B2 "Check now"; empty Following: "You don't follow anything yet" + B1 "Browse sources"; check already running (toast "A check is already running."); error; offline (object lens + the cached list read-only).
- **Keys:** `r` check now, `shift+r` mark all read, arrows through groups, `enter` open newest, `m` mark read, `[`/`]` tabs.

### 4.22 Downloads and Storage

**Downloads** (`/downloads`; Library's Downloads tile and lens tab, the accessory, `g d`).

- **Layout:** large title "Downloads" + "On this device · {size}"; TB1 **Chapters · Storage**; content-mode chip filter when novels are enabled.
- **OCR banner** (mobile, while a text-extraction run exists): N7 notice by phase: "Extracting text · page 3 of 40" (`glacier`, PR1), "Paused while the app is in the background. Keep it open to continue." (`warning`), "Uploading the transcript…", "Text extracted: 1,240 words are now searchable." (`success`), "Cancelled", "Extraction failed: {reason}" (`danger`); B3 "Cancel" while busy.
- **Active queue card** (content `slab.card` whose rim glows `glacier` while running and `warning` when blocked): header "Downloading" / "Waiting to start" / "Paused" + IB3 pause/resume + IB3 `x` "Cancel all" (alert "Cancel all downloads?" / "Everything queued, downloading or failed is dropped. Finished chapters stay." + B4 "Keep them" + B5 "Cancel all"); current block: series, "Chapter 12 · page 7 of 40" (novels "Saving the text…", audio "Saving the audio…"), PR1 6 px, "2 more downloading alongside", "12 of 40 saved in this series"; pause reason with action: user ("Paused by you. Resuming carries on from the page it stopped at." + B1 "Resume"), free-space floor ("Paused because this device is almost full. Downloads stop before the last 1.5 GB." + B2 "Storage"), cap ("Paused: downloads reached your 10 GB limit." + B2 "Storage settings"), background ("Paused while ManhwaManiacs is in the background"); queue summary "{n} in the queue · {k} failed" + B3 "Show queue" expanding rows (glyph per state, "Solo Leveling · Ch 12", "Waiting" / "Downloading" / "Failed: {error}", IB3 retry, IB3 remove). Mobile note: "Downloads run while ManhwaManiacs is open. Leaving pauses them; coming back picks up where they stopped."
- **Where it lives** (N7 info): iOS "Stored inside ManhwaManiacs and read offline from here. For a copy you can open elsewhere, use Save to Files." / Android "Stored in the app's private storage." / web "Stored in this browser for this profile. Other browsers and profiles don't see them."
- **Saved library:** caption "On this device · biggest first"; K11 groups: header (cover 40 × 60, title, "40 chapters · 3 with audio · 1.2 GB" or "12 of 40 saved · 800 MB", "last read 2 d ago"), IB4 pin (`push-pin`: pinned series are never auto-deleted), IB3 more (Save to Files…, Remove all downloads [alert "Remove downloads?" / "Deletes every downloaded chapter of {series} from this device. Your progress is kept." + B4 Keep + B5 Remove]); expanded chapter rows: `headphones` for audio rows, "Chapter 12" / "Chapter 12 · audio", "Saved · 24.3 MB" / "Queued" / "Downloading…" / "Failed: {error}", IB3 OCR (`bubble-search`: "Extract text" / `success` "Text extracted · tap to redo"; manga, complete, OCR available), IB3 Save to Files (mobile, complete manga), IB3 remove (undo toast). Tap a saved chapter → reader (works offline). Web status lines also show "Deletes in about 2 days" / "within the hour" / "next time you open the app" / "Open now, kept" per retention.
- **Save to Files** (mobile): SH1 medium "Save to Files": rows "Page images" ("A numbered folder per chapter.") and "CBZ file" ("One file per chapter, for comic reader apps."); progress alert (non-dismissible) with PR2 "Saving to Files…"; result alert "Saved to Files" / "Nothing to save": "{n} chapters · {m} pages", the path in `type.mono` `glacier` selectable ("Files → On My iPhone → ManhwaManiacs → Exports → {series}" on iOS; the folder path on Android), skipped count, B1 "Done"; toasts "Nothing to save yet: these chapters are still downloading." / "Couldn't save to Files. Check your free space."
- **Empty:** object lens `cloud-arrow-down` "Nothing downloaded yet" / "Chapters you download read with no connection at all." + a rail of the profile's Continue series, each with B2 "Download next 5"; novels: "No books downloaded" / "Downloaded chapters read offline, text and all."
- **Other states:** no profile: object lens `user-circle` "No profile selected" + B1 "Choose a profile"; web unsupported (no service worker / insecure origin): object lens `prohibit` "Downloads aren't available here" / "This browser can't store chapters for offline reading."; web pending: "Checking what's stored…" with PR2; loading (mobile store read): 3 group bones; error "Couldn't read the downloads on this device." + Try again. There is no pull-to-refresh here (local data).
- **Keys:** arrows through groups and rows, `enter` expand/open, `x` remove (undo), `p` pin, `space` pause/resume the queue.

**Storage** (Downloads' Storage tab, and `/settings/storage`).

- **Storage tube (signature):** a horizontal `slab.well` tube 24 tall, radius capsule, full width, holding liquid segments that settle on `spring.meniscus` with visible meniscus edges: mobile **other apps** (`frost400` frosted), **ManhwaManiacs** (`glacier` liquid with a lit top edge), **free** (clear); web **this site** (`glacier`) and **free of the browser's quota** (clear). The cap is a 2 px `label` marker line through the tube with a tag "Cap 10 GB"; within 10 % of the cap the ManhwaManiacs segment's meniscus turns `warning`; at the cap it pulses `warning` once. Readout under it: "1.2 GB of 10 GB · 38 GB free on this device" (`type.headline` + `type.subhead`). Changing the cap slides the marker on `spring.snappy` and the liquid re-settles.
- **Controls (mobile):** C2 Storage cap 2 GB · 5 GB · 10 GB · 20 GB · Unlimited; C2 Chapters at once 1 · 2 · 3 (helper "More at once finishes sooner but uses more of the source's patience."); C2 Delete after reading Off · 24 h · 48 h · 7 days (helper "Finished chapters are removed after this, except pinned series and whatever is open."); platform note (iOS: "Browse or delete downloads in the Files app: On My iPhone → ManhwaManiacs." with `folder-open`; Android: "Files live in the app's private storage."); **By series** list (pin glyph for pinned, title, "{n} ch · 240 MB"); B2 "Free up space" (toast "Removed {n} chapters." / "Nothing to free up right now."); **Image cache** group (size, B3 "Clear image cache" → toast "Image cache cleared."); **Metadata cache** group (B3 "Clear metadata cache" → "Metadata cache cleared.").
- **Controls (web):** the tube from `navigator.storage.estimate()` ("This browser doesn't report a storage quota." when absent); protection row: `shield-check` `success` "Storage protected" or B2 "Ask to protect storage" (`navigator.storage.persist()`); C2 Delete finished chapters after 2 days · 7 days · 30 days · Never (service-worker `set-retention`); explainer "Saving stops 250 MB before the quota. When it gets close, finished chapters go first, oldest first: never one you haven't read, never the one that's open."; B5-plain danger "Remove all downloads" (alert with B6 hold); B3 "Reset offline storage" (alert: "This unregisters the offline worker and clears every saved chapter in this browser." + B6 hold).
- **States:** usage loading (bone 240 × 24), "Couldn't read storage usage" error line, by-series loading (3 row bones).

### 4.23 Dialogue search (OCR)

Manga only. Routes `/ocr` (You → Dialogue search, sidebar, `g o`) and the Search orb's Dialogue scope.

- **Layout:** large title "Dialogue search" + "Find the chapter where someone said it."; S3 field (autofocus, placeholder "What did they say? e.g. “I will protect you”", 300 ms debounce, trailing PR2 while fetching). Idle: object lens `bubble-search` "Search the dialogue you remember" / "Searches the text extracted from chapters of series you follow." + a tip row (mobile) "Extract text from downloaded chapters in Downloads" → Downloads.
- **Results:** rows (L2, 88 tall): the series cover thumb 48 × 72 and title (joined from the library; unknown series fall back to the key in `type.mono`), "Chapter {number}" (joined from the series' chapter list; else the chapter key), the snippet `type.callout` with matched terms in `glacier` `wght 640` on a `rgba(143,216,255,0.16)` band (radius 4), caption "{n} words · {engine}". "Showing {n} of {total}" + B3 "Load more" (offset paging).
- **Open at the page:** tapping a result fetches `GET /ocr/chapter` for that chapter, finds the first page whose text contains the query, and opens the reader at `?page={n}`; in the reader, every matched box on that page is outlined by a T1 glass **hit lens** (2 px `glacier` outline, radius 6, refracting the bubble slightly), and a T2 capsule "1 of 3 · ↑ ↓" steps between hits (`n` / `shift+n`, `ocr.hit` haptic). When no page matches (text changed) it opens at page 1 with a toast "Opened at the chapter start: the match moved."
- **Signature moment:** the hit lens slides from bubble to bubble on `spring.panel`, magnifying each line of dialogue for a beat (1.12× inside the lens) before settling.
- **States:** loading (3 row bones); no matches: object lens "No dialogue matches “{q}”" / "Only chapters with extracted text, in series you follow, are searched."; error "Search failed. Check your connection and try again."; offline (object lens offline); novels mode: object lens `bubble-search` "Dialogue search is for manga" / "Switch to Manga, or search the novels' text instead." + B1 "Switch to Manga" + B3 "Search novels"; device without an OCR engine (mobile): search still works for text extracted elsewhere; the Extract controls in Downloads are hidden.
- **Keys:** `/` focus, `enter` open the first result, arrows through results.

### 4.24 You (the hub)

- **Phone layout:** no large title; a **profile card** at the top: the profile orb 72, name `type.title2`, "@{username}" `label2` (+ "Administrator" tag), the streak (flame + "12 days" in `flare`, links to Stats), and B2 "Switch profile" (opens the profile switcher menu blooming from the button). Under it the reading-mode segmented control **Manga · Novels** (only when novels are enabled; switching re-filters every list app-wide with a 200 ms cross-fade and a toast "Showing novels", `tab.select`). Then L1 groups:
  - **Reading:** Stats (a 44 × 20 sparkline of the last 14 days), Wrapped {year} (from 1 December for the current year, and the previous year all year), Friends (`bloom` dot on unseen activity; hidden when Friends is off for the account), Dialogue search (manga mode, OCR available).
  - **App:** Settings, Storage, Backup & restore (admin), System status (admin, with the worst health dot), What's new.
  - **Update card** (Android APK channel, when `GET /app/version` is newer): a `slab.card` with an aurora 1 px rim: `arrow-circle-up` "Update available", "Installed 3.4.3 (build 56)" / "Available 3.5.0 (build 60)", B1 lit "Download update", notes "Downloading doesn't install by itself. Open the file when it finishes." and "Coming from 1.2.x? Uninstall the old app first."; after the download starts an alert "Install now" with three numbered steps (numbers in 24 px `glacier` orbs) + B1 "Got it". Toast "Couldn't open {url}" when the browser can't launch.
  - Footer: the MM mark 32 + "ManhwaManiacs 3.5.0 (build 60)" `type.footnote` `label3` → About.
- **Desktop:** `/you` renders the same hub as a two-column page (profile card left, groups right); the sidebar reaches every row directly.
- **What's new** (auto once after an update when the build number increased; also from the row): SH1 large / SH4: title "What's new", release cards (`slab.card`: version in a capsule with an aurora rim, "Latest" tag on the first, "Sep 28, 2026 · build 60", bullets with 6 px `glacier` dots); loading bones; unavailable: object lens `cloud-slash` "Release notes aren't available right now."
- **Keys (desktop):** arrows through rows, `enter` opens, `g p` opens the profile switcher.
- **States:** the hub itself is local; the profile card shows bones until `/auth/me` resolves; offline adds the N1 capsule.

### 4.25 Settings

- **Phone:** `/settings` root is an L1 grouped list: S3 "Search settings" pinned at the top (hard edge when pinned), then groups (each row pushes its section): **Appearance** (Skin "Glass", Solid glass, Motion), **Reading** (Manga reader, Novel reader, Voices), **Feedback** (Haptics, Interface sounds), **Content** (Mature content, Reading mode), **Downloads & storage**, **People** (Profiles, Friends & sharing, Members [admin]), **Security**, **Data** (Backup & restore [admin], Recent searches), **Server** (Updates & notifications [admin], Server address [mobile], System status [admin]), **Advanced** (Diagnostics [mobile]), **Keyboard shortcuts** (web), **About**. At the very bottom, isolated: B3 `danger` "Sign out" (alert "Sign out?" / "You'll need to sign in again on this device." + B4 Cancel + B1 lit "Sign out").
- **Desktop:** split view: a 320 px L1 list on the left (content slab), the selected section on the right; URL `/settings/:section`; `↑/↓` move in the list, `enter` opens.
- **Search:** every setting is indexed (label, section, keywords); results are rows "Label · Section"; tapping opens the section and pulses the row with a `glacier` wash (2 × 400 ms); "No settings match “{q}”"; Android-only rows are not indexed on iOS and web.
- **No profile:** sections that store per-profile values (Skin, Reading, Content, Friends) show N7 "No reading profile is active, so there's nowhere to save this yet." + B3 "Choose a profile", controls disabled.
- **Keys (desktop):** `/` focuses settings search, `↑`/`↓` move through the section list, `enter` opens a section, `Esc` returns to the list.
- **Language:** the app ships in English only, so no language picker is shown.
- **Saving:** every row saves on change (optimistic, with the switch's loading state for server-backed values and a springs-back + inline error on failure), except Updates & notifications (admin), which is draft-then-save. The footer note reads "Changes save as you make them. Switching skin restarts the app."

#### 4.25.1 Skin (the picker and the restart flow)

1. **Picker** (`/settings/skin`): header "Skin" + "Skins change everything: layout, type, motion and sound. Your library and progress stay the same." Two live preview frames side by side (phone stacked), 180 × 320 (desktop 240 × 427), radius 26, each playing its skin's 6 s Home loop (muted MP4), with the name `type.title3` and a line: **Cinematic** "Dark cinema: posters, title cards and film motion." / **Glass** "Light and depth: glass, springs and haptics." Glass shows a `glacier` "Current" tag and a 2 px `glacier` ring. Footnote: "The skin follows this profile on every device. Switching restarts the app." Offline: the other frame reads "Needs a connection to sync; switching still works on this device."
2. **Confirm:** tapping Cinematic blooms a **T5 alert** out of its frame: "Restart in Cinematic?" / "Everything about the app changes. Your library, progress and downloads stay exactly as they are, and you'll come back to this screen." + (queue not empty) N7 "Downloads pause for a moment and resume after the restart." + B4 "Stay in Glass" + B1 lit "Restart in Cinematic". The same alert opens from the command palette's "Switch to Cinematic…" and from onboarding step 1 (deferred to the end of onboarding).
3. **Persist:** `skin.confirm` haptic (heavy); `PATCH /profiles/{id} {skin: "cinematic"}` (queued in the outbox when offline); the device mirror (web cookie `mm-skin`, mobile `mm.skin.active`) and the return route (`/settings/skin`) are written.
4. **Outgoing ("Dissolve into light", 700 ms):** every glass object's displacement ramps to 2× and its blur to 40 px while its specular brightens to 1.0; the ambient field's pools grow to 60 % and drift to the centre; at 450 ms the frame's brightness rises to 1.4 and cross-fades to `#000` over 250 ms; `glass-restart.wav` if sounds are on. Reduced Motion: 200 ms fade to black.
5. **Restart:** web posts `{type: "skin-changed"}` to the service worker (it drops the pages cache and re-fetches saved chapters' documents) and calls `location.replace("/settings/skin")`; mobile calls `AppRestart.of(context).restart()`.
6. **Incoming:** the new skin's splash and its own Settings skin screen with its own 10 s undo toast. **Coming into Glass** from Cinematic: the Lens reveal (§7.4) plays, the app lands on `/settings/skin` with a T2 toast "Switched to Glass" + B3 "Undo" with a 10 s countdown ring; Undo runs steps 3–6 back to Cinematic with no confirm.
7. **Profile switch:** when the chosen profile's skin differs, steps 3–6 run inside the profile-entry transition with no confirm and no undo (§4.5).
8. **Budget:** under 1.5 s from confirm to the new splash's first frame.

#### 4.25.2 Appearance, Reading, Feedback, Content

- **Appearance:** Skin (above); TG1 **Solid glass** ("Replaces see-through glass with solid surfaces. Turns on by itself with the system's Reduce Transparency."); TG1 **Moving light** ("Glass highlights follow how you tilt the phone" / "…follow your pointer"; off under Reduce Motion, shown disabled with that reason); C2 **Motion**: Follow system · Reduced (an in-app override that applies the Reduce Motion column of §2.10.7).
- **Reading → Manga reader:** the reader defaults from §4.14.5 (layout, direction, fit, tap layout and zones, continuous chapters, auto next, page transition, cinema, page-tinted chrome, page gap; mobile: keep awake, lock controls, volume keys, refresh rate) + B5-plain "Reset reader settings" (alert "Reset reader settings?" / "Every reader preference goes back to its default." + B4 Cancel + B1 "Reset"; toast "Reader settings reset.").
- **Reading → Novel reader:** default paper (orbs), face, size, mode, page turn, line guide, auto next.
- **Reading → Voices:** the voice gallery in preview mode (no per-book choice here; narrator and cast are set per book from the reader).
- **Feedback:** TG1 **Haptics** (mobile; "Taps, ticks and bumps as you use the app"), TG1 **Interface sounds** (default off; "Small tones for taps, toggles and completions. Off while narration or a soundscape plays.") with a preview row of three IB6 buttons (tap, toggle, add); the **Soundscape** default (§5.4.2).
- **Content:** the **18+ gate** (§3.25) and the **Reading mode** segmented (Manga · Novels, when enabled).

#### 4.25.3 People

- **Profiles** → Manage profiles (§4.6).
- **Friends & sharing** → §5.3.1.
- **Members** (admin): phone: rows (username + tags "Admin", "You", "Deactivated" `danger`; subtitle "Joined Jul 27 · last seen 2 h ago · 2 sessions" / "Never signed in"); desktop: a table (min 720, horizontal scroll inside its own container) Member · Status · Joined · Last seen · Sessions · Actions. Actions: B4 "Deactivate" / "Reactivate" (toggle; deactivating ends their sessions at once: alert "Deactivate {name}?" / "They're signed out everywhere and can't sign in until you reactivate them."), B5 "Delete" → alert "Delete {name}?" / "This removes their profiles, library, progress, bookmarks and everything they own. It can't be undone." + B4 Cancel + **B6 hold** coral "Delete {name}". Own row: actions disabled with the guard line "You can't deactivate or delete your own account." Explainer at the top: "Registration is open: anyone with the address can make an account. Deactivate stops someone signing in; delete removes everything they own." Footer: "{n} other accounts" + IB3 refresh. States: 3 row bones; error block; `cannot_manage_self` handled by the guard; empty ("Only your account so far.").

#### 4.25.4 Security

- **Change password** group: IN2 Current, IN2 New ("At least 8 characters"), IN2 Confirm; inline results "Enter your current password.", "Enter a new password.", "Use at least 8 characters.", "That password is too long.", "The new passwords don't match.", "Your new password must be different."; B1 lit "Change password" / "Changing…"; helper "Changing it signs out every other device. This one stays signed in."; success toast "Password changed. Your other devices were signed out." `weak_password` "Pick a stronger password."
- **Where you're signed in:** rows: glyph (`device-mobile` app, `desktop-tower` / `globe` browsers), label ("ManhwaManiacs app on iPhone", "Chrome on Windows", "Unknown device"), "This device" `glacier` tag, "Last used 3 h ago · 10.0.0.2", "Signed in Sep 1 · expires Dec 1"; trailing B3 "Sign out" (this device) / B5-plain "Revoke" (others; also swipe action), revoke alert "Sign out {device}?" / "It will need to sign in again." ; IB3 refresh (spins); states: row bones, error + Try again, "No other sessions".
- **Sign out everywhere:** a `danger`-rimmed group with the explainer "Ends every session on the account, this one included. Downloaded chapters stay on this device." + B6 hold coral "Sign out everywhere" (the hold replaces an acknowledgement switch) → login.

#### 4.25.5 Data

- **Backup & restore** (admin): pending-restore N7 (`warning` "A restore is staged and applies when the server restarts." + B2 "Cancel staged restore" / "Cancelling…" → toast "Staged restore cancelled."); **Nightly** row "Last nightly backup: Sep 28, 03:00 · 412 MB" (`success`) or "No nightly backup recorded" (`warning`; `null` is never shown as healthy); **Export** group: explainer "A copy of the whole database: every account, profile and library. Keep it private.", TG1 "Include caches (bigger file)", B1 lit "Export backup" / "Preparing…" → "Saved {filename}" (web: a browser download; mobile: opens the export URL in the browser, toast "Couldn't start the download." on failure); **Restore** group (`danger` rim): explainer "Replaces everything on the server with the backup. It applies on the next server restart; the current database is kept aside.", B2 "Choose backup file" (file picker, `.db`), "{name} · {size}" or "No file chosen. Nothing uploads until you confirm.", validation ("{name} isn't a .db file", "{name} is empty"), B5 "Restore from this file…" → T5 alert "Restore from “{file}”?" with a `danger` block of four points (replaces every account; sign-ins come from the backup; applies on the next restart; nothing current is kept in use), IN7 "Type RESTORE to confirm", B4 Cancel + **B6 hold** coral "Restore" (enabled when the phrase matches, case-insensitive; "Uploading…") → success alert "Restore staged" / "Restart your ManhwaManiacs server to finish." + B1 "Got it".
- **Recent searches:** row "Clear recent searches" (per profile) → toast "Recent searches cleared."

#### 4.25.6 Server (admin and device)

- **Updates & notifications** (admin, instance-wide, draft-then-save): schedule strip of three K5 tiles (Last check, Next check [`warning` when overdue, "Not scheduled yet"], Interval) + overdue note "The next check was due {n} min ago. System status shows whether the scheduler is running." → link; TG1 "Check for new chapters automatically" ("Nothing is checked or announced while this is off."); TG1 "Check when the server starts"; SL1 "Check every" 5–120 min, step 5, value `type.mono` "30 min" (helper "The server never checks more often than every 5 minutes."); TG1 "Announce new chapters" ("The master switch. Turn one series off from its page."); B1 lit "Save" / "Saving…" → toast "Saved."; states: 5 row bones, error + Try again, 403 for non-admins never reached (the row is hidden).
- **Server address** (mobile): IN1 "Server address" (hint = default), B1 "Save address" (validation, https required in release; toast "Server address saved."), B3 "Reset to default" (toast "Back to the default address."), loading and error states.
- **System status** (admin) → §4.26.

#### 4.25.7 Advanced, shortcuts, about

- **Diagnostics** (mobile): K5 tiles FPS (`glacier`), Jank % (`success` < 5, `warning` < 15, else `danger`), Worst frame (ms); rows Average frame, UI thread, Raster thread, Samples ("Starting the profiler…", "Scroll a screen to collect frames."); **Glass renderer** rows (Glass-only): "Refraction: Impeller, premium" / "Frosted: this renderer can't refract", "Glass layers on screen now: 2"; **Display** (Android: current refresh rate, supported modes, resolution; iOS: "Switchable refresh rates are Android only."); **Device** (platform and OS, CPU cores, screen w × h @ DPR, app version, build mode); **Image cache** (live images, cached n / max, memory MB / MB).
- **Keyboard shortcuts** (web): the live registry grouped (General, Navigation, Library, Search, Sources, Reader, Novel reader, Listen) with keycaps; read-only; "No shortcuts are active on this screen."
- **About:** the brand lens (MM mark in a 56 px orb) + "ManhwaManiacs" + "Version 3.5.0 (build 60)" (bones while loading; "Couldn't read the app version"); **Updates:** Android APK card (up to date `success` "You're on the latest version · 3.5.0"; available "3.4.3 → 3.5.0" + B1 "Download update"; "Couldn't check for updates" / "Server unreachable" `warning`); iOS "Updates come through SideStore" + the source URL (`type.mono`, selectable) + B2 "Copy source URL" (toast "Source URL copied") + "SideStore re-signs the app every 7 days."; web "This is the latest version" or the N3 prompt; rows What's new, Open-source licences (a Glass-built licence list from `LicenseRegistry.licenses` on Flutter and a generated `/licenses` page on web, including every OFL font).

### 4.26 System status (admin)

- **Layout:** eyebrow "ADMINISTRATION", large title "System status", subtitle "Health of the server, the update checker and every source."; B2 "Refresh" (spins). A **summary banner** (`slab.card` with a rim in the worst state's colour and its glyph `check-circle` / `warning` / `warning-octagon` / `question`): headline ("Everything's running", "2 things need attention", "The server is down") + a bullet list of problems. Cards (desktop 2 columns, phone 1): **Server** (state tag Healthy / Warning / Down / Unknown, name, version `type.mono`, probe "GET /health"), **Update checker** (B2 "Check now" / "Starting…", last run + "12 min ago", next run estimate + "in 40 min", interval, failed recent runs [`danger` when > 0], the server error in a `slab.well` mono block, footnote about the estimate), **Recent checks** (up to 8 runs: status tag, trigger `type.caption1` uppercase, "{n} series · {n} new", time, error block), **Sources** (the `GET /system/source-health` ring "84 of 89 healthy" + C2 All · Problems + rows: health dot, name, `type.mono` id, "demoted" `warning` tag, "last probe 3 min ago", message, last error in a well), **Backups** (nightly result and size). Footnote: "Everything here comes from the server's own health endpoints." Polling: health every 15 s, source health every 30 s (paused when hidden).
- **Signature moment:** each health dot is a tiny glass bead lit from inside in its state colour; a failing source's bead flickers once when a new probe lands.
- **Keys:** `r` refresh all, `c` check now.
- **States:** loading (banner bone + 4 card bones); non-admin: object lens `shield-check` "Administrators only" / "Server health is for the account owner." + B1 "Go home"; each card has its own error line + Retry.

### 4.27 Status screens

| Screen | Spec |
|---|---|
| **404** (inside the app frame) | Object lens (`compass`) "Nothing here" / "This page doesn't exist. It may have moved, or the series it pointed to was removed from your library." + B1 lit "Go home" + B3 "Open library" + footnote "Press ⌘K to search everything." (Ctrl K elsewhere) |
| **Route error** | Object lens (`warning-octagon`) "Something broke" / "This page failed while drawing. Nothing was lost; trying again usually works." + B1 lit "Try again" + B3 "Go home" + a `type.monoSmall` chip "Reference {digest}"; server unreachable variant (`plugs`): "Can't reach the server" / "The server didn't answer. It may still be starting, or the connection dropped. Your library is safe." |
| **Root error** (replaces the document; no app fonts or providers) | Plain `#000` page, `system-ui` type, a CSS-only frosted card (`backdrop-filter: blur(24px)`, `rgba(255,255,255,0.06)`, 1 px `rgba(255,255,255,0.22)` rim, radius 26) holding an inline SVG MM mark, "ManhwaManiacs failed to start", "Reloading usually fixes it. If it doesn't, check the server or the running build.", buttons "Try again" and "Reload the app" (hard navigation to `/`) |
| **Offline fallback page** (static HTML from the service worker) | The worker caches `offline-fallback-glass.html` and `offline-fallback-cinematic.html` and serves the one matching the `mm-skin` cookie. Glass version: black page, inline CSS only, the MM mark in a CSS frosted orb, a status capsule with a live dot ("No connection" `#FFC872` / "Back online" `#6EF0B5`, from `navigator.onLine` events), "This page needs the server", "ManhwaManiacs can't reach your library right now. Chapters you downloaded still open.", buttons "Try again" (reload) and "Downloads", footnote "This page comes from your device." |
| **Reader landing** | §4.14.10 |

### 4.28 Global overlays and shared pieces

| Piece | Spec |
|---|---|
| Command palette | §3.28 |
| Keyboard shortcuts dialog (`?`, `shift+?`, the reader's settings, Settings → Shortcuts) | T4 panel 560 wide blooming at centre; title "Keyboard shortcuts"; intro "Only what works on this screen is listed. Shortcuts pause while you type in a field." ; one L1 group per scope with description + keycaps (secondary combos at 80 %); empty "No shortcuts are active on this screen."; Esc closes |
| New-chapters notice | N2 (§3.30) |
| App update prompt (web) | N3 |
| Offline indicator | N1 on every screen whose data needs the network |
| Profile switcher | A Menu (§3.23) blooming from its trigger (You tab long-press, the Home avatar orb, the sidebar profile chip, the You card's button, `g p`): an account header (display name `type.headline`, "@username" and the email when set in `type.footnote` `label3`, an "Administrator" tag with `shield-check` for admins), rows of the other profiles (32 px orbs, name, 18+ marker) → Step-into-the-light switch (§4.5, shortened to 700 ms); "Manage profiles"; "Switch account"; a `danger` "Sign out" row at the bottom ("Signing out…" while pending). Offline: other profiles listed but disabled with "Needs a connection" |
| Clock and connectivity | No clock is shown; connectivity is the N1 offline capsule, which appears only when the network is actually unreachable |
| Reading mode (Manga · Novels) | The segmented control in You, the sidebar footer and the Library header; on phone also a long-press on the Library tab's menu; switching re-filters every list with a 200 ms cross-fade + toast; hidden entirely when novels are off |
| Series actions | The poster context menu (§3.23) everywhere a followed series appears; "Remove from library" undo restores favourite, status, alerts, mature override and shelf position |
| Chapter selection and download toolbar | §4.12 |
| Bulk action toolbar | §4.17 |
| Collection form, add-series, remove, delete | §4.18 |
| Save to Files sheet and dialogs | §4.22 |
| What's new sheet | §4.24 |
| Confirmation alerts (all §3.11) | Delete profile, Sign out, Enable mature content (hold), Reset reader settings, Sign out a device, Sign out everywhere (hold), Deactivate member, Delete member (hold), Restore backup (phrase + hold), Restore staged, Cancel all downloads, Remove series downloads, Remove saved audio, Remove all downloads (hold, web), Reset offline storage (hold, web), Delete collection, Install update steps, Restart in {skin} |
| Toasts | Every transient confirmation or failure message is a §3.12 toast; destructive single actions (bookmark remove, unfollow, download remove, collection member remove) get Undo |

### 4.29 Coverage map

| Inventory item | Glass section |
|---|---|
| Web R0 `/` redirect | §4.0.3 (`/` → `/home`) |
| Web R1 Login · Mobile S03 | §4.3 |
| Web R2 Register · Mobile S04 | §4.4 |
| Web R3 Profile picker · Mobile S05 | §4.5 |
| Web R4 Manage profiles · Profile form dialog 4.2 · Mobile S06, S07 | §4.6 |
| Web R5 Library, R6 Browse all · Mobile S08, S09 | §4.17 (+ Home §4.8 for the landing role) |
| Web R7 Followed series detail · Mobile S10 | §4.12 (one Series screen; `/library/:followId` resolves to it) |
| Web R8, R9 Collections · Mobile S24, S25 | §4.18 |
| Web R10 History · Mobile S13 | §4.19 |
| Web R11 / §13 Bookmarks · Mobile S14 | §4.20 |
| Web R12 Recommendations · Mobile S11 | §5.1 (For you) |
| Web R13 Statistics · Mobile S12 | §5.2 |
| Web R14 Search · Mobile S20 | §4.9 |
| Web R15 Sources · Mobile S16 | §4.10 |
| Web R16 Source catalogue · Mobile S17 | §4.11 |
| Web R17 Source series (manga) · Mobile S18 manga body | §4.12 |
| Web R17n Book page · Mobile S18 novel body · N3 audiobook picker | §4.13 |
| Web R18 Reader landing | §4.14.10 |
| Web R19 Manga reader, R20 Read-all · Mobile S15, S19 · reader settings sheet M6 | §4.14 |
| Web R21 Novel reader · Mobile S26 · N1 type panel · N2 contents | §4.15 |
| Novel audio, voices, cast · Mobile N4 | §4.16 |
| Web R22 Updates · Mobile S23 | §4.21 |
| Web R23 Downloads · §12.2 picker · Mobile S21 · M5 Save to Files | §4.22, §4.12 |
| Web R24 OCR · Mobile S27 | §4.23 |
| Web R25 More · Mobile S22 · G8 What's New · G9 APK update | §4.24 |
| Web R26 Settings (all panels) · Mobile S28 (all tabs), S29 Security, S30 Members, S31 Theme gallery → Skin, S32 Storage, S33 Backup, S34 Diagnostics | §4.25, §4.22 (Storage) |
| Web R27 System status | §4.26 |
| Web E1 404, E2 route error, E3 root error, E4 offline fallback | §4.27 |
| Mobile S01 Setup, S02 Splash | §4.1, §4.2 |
| Web G2–G13 guards and shell · Mobile G1 bottom nav, G2 mood backdrop, G3 profile switcher, G5 reading mode, G6 auth, G7 first run, G10–G11 lifecycle and system UI | §4.0, §2.1.6, §4.28, §4.2 |
| Web G14–G29e sidebar, G30 topbar, G31 profile chip, G32–G37 tab bar, G38 first-run banner, G39 new chapters, G40 update prompt | §3.16, §3.14, §3.15, §3.30, §4.28 |
| Web §2.8 command palette, §2.9 keyboard layer and shortcuts dialog | §3.28, §4.0.6, §4.28 |
| Web C1–C19 shared components · Mobile G14 primitives | §3 |
| Web and mobile 18+ gate · Mobile G4 | §3.25 |
| Mobile G12 haptics | §2.11 |
| Mobile M1–M9 shared sheets and dialogs | §4.28 |
| Onboarding, Home, For you, Recap, Wrapped, Friends, ambient extras (new) | §4.7, §4.8, §5 |

---

## 5. The four new features

All four are designed server-first (`stack-decision.md` §2.6): the backend computes the AI rails and recaps, the stats aggregates, the social feed with its per-profile and 18+ filtering, the palettes and the panel boxes; each client only renders. The endpoints this concept needs are listed in §9.5. **Iris** light marks everything the AI produced; **bloom** light marks everything a person shared.

### 5.1 AI home, recommendations and "Previously on"

#### 5.1.1 What the AI touches

| Surface | Data | State set |
|---|---|---|
| Home rails "For you", "Because you read X" | `GET /library/world/recommendations` (existing) | loading, ready, empty (new profile), unavailable (catalogue unreachable, cached), not configured |
| Series page "More like this" rail; caught-up card | `GET /library/similar?source=&series=` (new) | loading, ready, empty, unavailable |
| For you screen: Ask box | `GET /library/suggest/availability`, `POST /library/world/suggest` (existing) | idle, thinking, ready, no matches, rate-limited, budget used, not configured, error |
| "Not interested" | `POST /library/recommendations/feedback` (new) | optimistic with undo |
| "Previously on" recap | `GET /recap`, `POST /recap` (new) | generating, ready, no source text, unavailable, error, offline-cached |
| Onboarding seeds | `POST /library/taste/seed` (new) | loading, ready, unavailable (falls back to Popular) |

#### 5.1.2 AI rails on Home and the Series page

- **Header:** `type.eyebrow` "FOR YOU" in `iris` with a 14 px `sparkle`, above the `type.title2` rail title ("For you", "Because you read Solo Leveling", "More like Omniscient Reader"); the heading reveal plays on first view.
- **Cards:** K3 world cards (Available variant opens the series on one of the reader's sources, a source picker menu when there are several; Info variant searches the reader's sources or opens the official site). Every card shows its `why` line with the `iris` spark. 18+ items appear only for profiles that can see them (`is_adult` filtered on serve).
- **Loading:** the header shows immediately; six card bones pulse with an `iris` tint (`rgba(169,155,255,0.06 → 0.11)`) and a PR3 light run in `iris` crosses the header. A cold page can take seconds (dozens of public-API calls), so after 4 s a quiet line appears: "Finding picks across the whole catalogue…".
- **Empty (new profile):** a one-line row in place of the cards: `sparkle` `iris` + "Read a few chapters and this row fills in." + B3 "Pick some favourites" (opens onboarding step 3–5).
- **Unavailable** (`unavailable_reason`): cached items stay, with a BD6-style `iris` chip "From earlier · the catalogue isn't answering".
- **Not configured:** the AI rails are omitted from Home; For you shows the non-AI sections only.
- **Not interested:** swipe the card up (phone) or the card's `⋯` → "Not interested": the card dematerializes, the rail closes the gap on `spring.snappy`, toast "We'll show fewer like this" + Undo.

#### 5.1.3 For you (`/for-you`)

- **Layout:** large title "For you" + a subtitle that follows the AI state ("Describe what you feel like reading. Picks are weighed against what you've read." / "Today's asks are used up. They reset at midnight UTC; the picks below still work." / "Picks from everywhere, based on what you read."). The **Ask box**: IN3 (3–6 rows, max 600, placeholder "a revenge story with a competent lead, no harem"), whose rim is `iris` at 60 % while focused; three C3 example chips with the `iris` spark ("A murim regressor who comes back stronger", "Magic academy, but the lead is already strong", "Something slow and political, not a power fantasy"; tapping fills and submits); B1 lit "Suggest" (`sparkle`; enabled at ≥ 3 characters); quota `type.footnote` `label3` "{n} asks left today" (shown at ≤ 10). Then **Your picks** (the Ask results: a grid of K3 cards, 1 column phone, 2–3 desktop), **Your genres** (C4 chips sized by affinity weight: font `type.subhead` for the top 3, `type.caption1` for the rest, each linking to Search filtered by genre), **For you** and **Because you read {title}** sections as grids.
- **Signature moment ("Thinking in light"):** while a suggestion is generating, the Ask box's `iris` rim carries a slow light run and the result grid's bones are lit from underneath by an `iris` pool that grows as the wait goes on; when the answer lands, the cards materialize one by one (26 ms stagger) and each `why` line types in at 50 ms per character, the one place the typing reveal is used for many lines, capped to the first 80 characters of each reason with the rest fading in.
- **States:** thinking (bones; after 8 s "Still thinking. This can take up to 40 seconds." + B3 "Cancel"); `ai_no_matches` object lens (`sparkle`, `iris` pool) "Nothing matched that" / "Try fewer conditions or different words."; `rate_limited` "Too many asks at once. Try again in {n} s." with a countdown ring on Suggest; budget used (Ask box disabled with the subtitle above); not configured (Ask box hidden; N7 "Suggestions aren't set up on this server."); error "Couldn't suggest anything. Try describing it differently." + Try again; sections loading (6 card bones each); nothing to go on: object lens `sparkle` "Nothing to go on yet" / "Read or follow a few series first. Picks start from what you read." + B1 "Browse sources"; offline: object lens offline (the Ask box needs the network).
- **Keys:** `/` focuses the Ask box, `mod+enter` submits (Enter submits, Shift+Enter is a newline), arrows through cards.

#### 5.1.4 "Previously on" recap

- **Entry points:** B2 "Previously on" on the Series page and the Home spotlight (when the profile has progress in the series); the Continue deck's context menu; the reader's more menu and `shift+r`; and an **automatic offer**: tapping Continue on a series last read ≥ 14 days ago opens a T4 sheet at medium, blooming from the lit button: "It's been 3 weeks" / "Want a quick recap of what happened?" + B1 lit "Show recap" + B3 "Just continue" + TG1 "Don't ask for this series" (per series, stored per profile).
- **Recap screen** (`/recap/:sourceId/:seriesKey?chapter=`, takeover): the series cover blurred as the backdrop (field at 34 %); eyebrow "PREVIOUSLY ON" in `iris`; the series title in `type.display` with the heading reveal; the recap headline (one sentence, ≤ 90 characters) typed at 50 ms per character in `type.title2`; then 3–6 **beats** as `slab.card`s (radius 26) stacked vertically with a 14 ms-stagger materialize: each has a chapter chip ("Ch 138", `type.mono` in a `fill2` capsule; tap opens that chapter), a panel thumbnail 96 × 144 on the right (manga: the OCR page the beat came from; novels: none), and 2–3 sentences in `type.body`; a **Who's who** row of C3 chips for the main characters (novels: from the attribution cast with their speaker tints; manga: names the recap produced) whose tap shows a one-line note in a tooltip; the **last line** "Last time:" in Literata italic 19/28 inside a `glacier`-ruled quote. Bottom, pinned (phone) or under the content (desktop): B1 lit L "Continue · Ch 142, p. 12" (lens dive into the reader) + B3 "Start from Ch 138 instead". Footnote `type.footnote` `label3`: "Written by {model} from the text of chapters 120–141. It never covers anything past where you stopped."
- **Generating:** the title and eyebrow appear, the headline area shows an `iris` light run, beats are three bones; "Writing your recap… usually 10–30 s." The user can leave: when it is ready a toast "Recap for {series} is ready" + "Open" appears anywhere in the app.
- **No source text** (manga without extracted dialogue for the previous chapters): object lens (`bubble-search`, `iris` pool) "No recap yet" / "Recaps are written from chapter text. Extract text from downloaded chapters, or just continue." + B1 lit "Continue" + B3 "How it works" (a sheet explaining OCR extraction in three steps).
- **AI unavailable / budget used:** object lens "Recaps are resting" / reason line + B1 lit "Continue".
- **Error:** "The recap didn't come through." + Try again + Continue.
- **Offline:** a recap generated before opens from the local cache; otherwise "Recaps need a connection." + Continue.
- **Spoilers and 18+:** recaps only use chapters at or before the profile's furthest read chapter; mature series' recaps are served only to profiles that can see them (gate applied when serving the shared cache).
- **Keys:** `enter` continue, `1`–`6` open a beat's chapter, `Esc` closes the recap.
- **Reduced Motion:** the headline appears at once; beats fade in together over 200 ms.

### 5.2 Reading stats, streaks and Wrapped

#### 5.2.1 The streak flame

A reusable component in five sizes (16 inline, 20 sidebar, 28 You card, 44 Home greeting, 96 Stats hero). It is **a glass teardrop with a light inside**: a T1 clear-glass teardrop shape (a circle 0.8 of the height topped by a point) whose interior holds a radial `flare` light (`#FFB05C` core → `#FF9ED8` edge at 70 %). The light's intensity says the streak's health: read today → full (the core flickers 0.9 ↔ 1.0 over 1.8 s on noise); not yet today → an ember at 35 % with a pulsing hint "Read today to keep your 12-day streak" wherever the flame is ≥ 44 px; broken → an empty glass drop with no light and "Start a new streak today". The day count sits beside it in `type.stat` (or `type.headline` at small sizes), `tnum`.

- **+1 (first reading of the day, detected when a session is recorded):** the flame swells to 1.25 on `spring.celebrate`, a `flare` caustic ring spreads 120 px and fades, the count rolls up one digit on `spring.snappy`; `streak.plus` haptic; `glass-shimmer.wav` if sounds are on. Shown once, on the next screen that has a flame (usually the reader's exit to Home).
- **Milestones** (7, 30, 100, 365 days): the light splits into the spectrum for 900 ms (the flame's interior becomes the aurora gradient with a 3 px dispersion fringe), then settles back to flare; a toast "30 days in a row" with the flame at 20 px; `streak.milestone`.
- Reduced Motion: no flicker, swell or split; the count changes and the toast appears.

#### 5.2.2 Stats (`/stats`)

- **Layout (desktop, 2 columns ≥ 1280):** header "Stats" + "What you've actually read on {profile}." + TB1 **Week · Month · Quarter · Year** (7 / 30 / 90 / 365 days) + B2 "Share" (`share-network`). A **hero band**: the 96 px streak flame, current streak `type.stat` "12 days", "Longest 41 · read on 23 of the last 30 days", and a dot row for the range (≤ 31 dots; each 8 px, `glacier` when read, `fill3` when not; hover or tap shows the day's totals in a T2 tooltip). **K5 tiles** (4 across; 2 × 2 on phone): Time read ("18 h 40 m", caption "212 h all time"), Chapters ("142", "1,204 finished all time"), Pages ("5,380"), Series ("23", "96 followed").
- **Activity chart:** a custom chart (SVG on web, `CustomPainter` on Flutter): bars = pages per day in `glacier` at 85 % (radius 3 top corners, max 16 px wide, 3 px gap), a line = minutes per day in `flare` with 4 px round markers; left axis pages, right axis minutes, 4–6 date labels (`type.caption1` `label3`), gridlines `frost500` at 40 %. The selected day (hover or tap) shows a glass lens (T1) over its bar and a T2 capsule "Mon 21 Sep · 42 pages · 3 chapters · 25 min". "Best day: Sat 19 Sep · 120 pages" beside the title. Year range swaps the bars for a **heatmap**: 53 × 7 squares of 11 px, radius 3, 2 px gaps, five `glacier` levels (0, 12, 30, 55, 85 % alpha), month labels above.
- **When you read:** a **glass clock** (220 px): a circular T1 glass ring divided into 24 segments whose inner light brightens with reading in that hour (`glacier` 0–85 %), the hand-free centre showing "Night owl · most at 23:00" (peak labels: 05–09 "Early reader", 09–17 "Daytime reader", 17–22 "Evening reader", 22–05 "Night owl").
- **Genre radar** (from `/library/recommendations` weights, top 6–8 genres): a radar polygon with `glacier` fill at 22 % and a 1.5 px `glacier` rim, axes `frost500`, labels `type.caption1`; hovering an axis shows the share.
- **Where you read:** source rows (icon 24, name, "{pages} pages · {time}", a PR1 bar with the share %).
- **Most read:** series rows (poster 44 × 66, title, "{pages} pages · {chapters} chapters · {time}", "last read 3 d ago"; tap → Series).
- **Recent sessions** (all time): rows "Chapter 12 · Solo Leveling", "40 pages · 12 min", started time; tap → reader at that chapter.
- **Your library:** "{n} followed · {n} favourites · {n} chapters finished" + per-status rows with PR1 bars in the status colours.
- **Footnote:** "Days start at UTC+05:30 · Reading time counts each session up to 30 min of idle · Recording since Jul 27, 2026."; scope note when novels are on: "The streak, totals and clock count everything; the lists below show manga only."
- **Wrapped entry:** a `slab.card` with an aurora 1 px rim: "Your 2026 in chapters" + B1 lit "Open" (from 1 December; the previous year's Wrapped all year; a year picker menu when several exist).
- **Data honesty:** time-left and pace figures appear only with ≥ 2 minutes of samples; zero shows as "0", never as a dash; every chart has a visually hidden data table (web) / `Semantics` summary (Flutter).
- **States:** loading (hero bone, 4 tile bones, a 320 px chart bone, 2 panel bones); nothing recorded: object lens `chart-line-up` "No reading recorded yet" + B1 "Continue reading" / B2 "Browse sources"; followed but never read: "Nothing read on this profile yet" + the Your library section; offline: object lens offline (stats are server-computed); error + Try again.
- **Keys:** `[`/`]` ranges, arrows move the selected day on the chart, `s` share.

#### 5.2.3 Wrapped (`/stats/wrapped/:year`)

A takeover **story** of up to ten slides inside a T5 monolith frame (inset 8 px, radius 44; desktop a 480 × 854 frame centred over the aurora field). Progress capsules at the top (one per slide, 3 px, the current one filling over 6 s); tap right / left (or `→`/`←`, swipe) to step; press and hold to pause; IB6 close top-right; B2 "Share this" on every slide. Data from `GET /library/statistics/year?year=` (new: calendar-year bounds, per-month totals, genre shares over time, first and last read, biggest day, longest session, top series with covers).

| # | Slide | Content and motion |
|---|---|---|
| 1 | Opening | The Lens reveal plays small at centre; "Your {year} in chapters" typed at 50 ms/char |
| 2 | Time | "You read for" + `type.stat` count-up to "212 hours" on `spring.celebrate` (the number rolls digit by digit); a line: "That's 8 days and 20 hours." |
| 3 | Chapters and pages | Two numbers count up; a flowing strip of tiny page shapes streams upward behind them at 20 px/s |
| 4 | Your top series | The top 5 posters fan in as a stacked deck; #1 is lit (a `glacier` caustic under it) with "{n} chapters"; covers of 18+ series appear only for profiles that can see them and never on the share card |
| 5 | Genres | The genre radar draws its polygon (stroke-dash from 0 on `spring.smooth`), top genre named in `type.display` with the heading reveal |
| 6 | When you read | The glass clock lights hour by hour (24 × 30 ms), then names the reader type ("Night owl") |
| 7 | Streak | The flame at 120 px lights up and splits into the spectrum once; "Longest streak: 41 days · Mar 3 – Apr 12" |
| 8 | Sources | The top 3 sources' icons in glass orbs, sized by share |
| 9 | Friends (only when Friends is on and both people shared) | "You and Anna both read Solo Leveling" with two avatar orbs meeting over the cover |
| 10 | Summary | The share-card layout itself (below), B1 lit "Share", B3 "Replay" |

States: building (the frame with the Lens and "Putting your year together…"); not enough data ("Read on at least 20 days this year to unlock Wrapped." + a PR1 "12 of 20 days"); offline (the last built Wrapped from cache, else offline lens); error. Haptics: `detent.tick` per slide change, `notify.success` on the summary. Reduced Motion: numbers appear at once, slides cross-fade in 200 ms, no auto-advance (the user taps).

#### 5.2.4 Shareable stat cards (image export)

- **Formats:** Story 1080 × 1920 and Square 1080 × 1350.
- **Design:** `#000` canvas with the aurora field (three pools at 40 %, blur 200 px), a centred glass slab (radius 132 at export size, 1.5 px specular rim `rgba(255,255,255,0.35)`, fill `rgba(255,255,255,0.06)`, shadow `0 60px 120px rgba(0,0,0,0.6)`), the stat in Google Sans Flex (`ROND 100, wght 700`, 220 px for the hero number), a label line, optional covers (max 5, 18+ never), the MM mark 64 px and "ManhwaManiacs" at the bottom in `ROND 100 wght 620`, and the year or range.
- **Card choices** (sheet SH1 medium / SH4): Year summary, Time read, Top series, Streak, Genre radar, When I read; TG1 "Show covers" (default on); TG1 "Show my profile name" (default off); a live preview (the card at 30 %).
- **Export:** Flutter renders the card widget offscreen in a `RepaintBoundary` at pixel ratio 1080 / width and calls `toImage` → PNG, then the system share sheet via `share_plus` (the newest release that resolves on Flutter 3.44.6, pinned exactly in the foundation session) with "Save image" and share targets. Web builds the card as an SVG (filters for the blur and glass; covers inlined as data URIs fetched same-origin), draws it into a 1080-wide `<canvas>` and `canvas.toBlob('image/png')`, then `navigator.share({ files: [file] })` where supported (mobile browsers) or an `<a download="manhwamaniacs-2026.png">` link (desktop).
- **States:** "Making the image…" (B1 loading), done (share sheet / download), error ("Couldn't make the image." + Try again).

### 5.3 Social for 2–3 people: "Friends"

#### 5.3.1 Model and privacy

- **Who:** every profile on this server whose owner turned sharing on. Friends are profiles, not accounts, so each profile's world stays isolated until it opts in.
- **Default: off.** Settings → People → Friends & sharing: TG1 **Share my reading with friends** (off by default); when on: TG1 "Share what I'm reading" (reading activity), TG1 "Share reactions", TG1 "Hide my 18+ reading" (default on; only for profiles with mature content), a "Keep these series private" list (add from any series' More menu: "Keep private from friends"). Turning sharing on shows a T4 alert: "Share your reading?" / "Other profiles on this server that share too will see what you read, react and recommend. Nothing from before today is shared." + B4 "Not now" + B1 lit "Share".
- **18+:** the server never serves a mature series, reaction or recommendation to a profile whose gate is closed, and counts are computed after that filter (absence, never a lock).
- **Isolation:** only the fields above leave the profile; progress, bookmarks, downloads and settings never do.

#### 5.3.2 Friends screen (`/friends`)

- **Layout:** large title "Friends"; a **friends row**: avatar orbs 56 with names, and under each a tiny 24 × 36 poster of what they are reading now (tap → that series); TB1 **Activity · For you · Shared**.
  - **Activity:** a feed grouped by day ("TODAY", "YESTERDAY", dates). K7 activity card (`slab.card` radius 20, padding 12): actor orb 32 with a `bloom` ring, text `type.callout` "**Anna** finished **Chapter 142** of **Solo Leveling**" (kinds: started, finished a chapter, finished a series, followed, reacted, recommended, added to a shared collection), time `type.footnote` `label3`, poster 48 × 72 at the right, a reactions summary row, actions B3 "Read it" / IB4 react / IB3 "Add to library". Consecutive chapter reads of one series by one friend collapse into "Anna read 6 chapters of Solo Leveling".
  - **For you:** recommendations sent to this profile: cards with "From Anna" (`bloom` chip), the note in Literata italic, B1 lit "Read", B3 "Not now" (hides it), B3 "Add to library". Unseen ones carry a `bloom` dot and clear when viewed.
  - **Shared:** shared collections (K4 with member avatars and the `bloom` rim).
- **Signature moment ("Someone's light in your room"):** when a friend is reading right now (a session in the last 10 minutes), their orb in the friends row glows with a soft `bloom` pulse (3 s), and on Home the "Friends are reading" rail's first card carries the same glow.
- **States:** sharing off (the default): object lens (`users-three`, `bloom` pool) "Friends is off for this profile" / "Share what you read with the other people on this server. Nothing is shared until you turn it on." + B1 lit "Turn on sharing"; on but nobody else shares: "No one else is sharing yet" / "When someone else here turns on sharing, their reading shows up here."; loading (friends row bones + 4 card bones); error; offline (cached feed with the N1 capsule; reacting and sending disabled).
- **Keys:** `[`/`]` tabs, arrows through cards, `r` react to the focused card (opens the reaction row), `enter` open.

#### 5.3.3 Reactions

Six reactions: **Love** (`heart`, `bloom`), **Fire** (`flame`, `flare`), **Laugh** (`smiley`, `#FFE07A`), **Cry** (`drop`, `glacier`), **Shock** (`lightning`, `iris`), **Clap** (`hands-clapping`, `success`).

- **Where:** the reactions row at every chapter end (the manga seam and next-chapter card, the novel end matter, the listen post-play card), on activity cards, and summarised on the Series page chapter rows (up to 3 friends' reaction glyphs at 14 px).
- **Row:** six `fill2` circles 44 with Light glyphs 22 in `label2`; beside each, the avatars (16 px, max 3) of friends who used it.
- **Reacting:** the tapped circle turns into a T1 glass orb lit with the reaction's colour on `spring.bouncy` (1 → 1.3 → 1), its glyph fills, a caustic ring in its colour ripples out 80 px, `reaction.sent` (AHAP `pop`), `glass-react.wav` if on. Tapping again removes it. Long-press shows who reacted (a menu of avatars and names).
- **States:** sharing off → the row is replaced by a single B3 "Share reactions with friends" (opens the privacy sheet) the first time, then hidden once dismissed; offline → the row is disabled with tooltip "Reactions need a connection"; failed → the orb springs back and a toast explains.

#### 5.3.4 Recommend to

- **Entry:** the Series page's `paper-plane-tilt` orb, the poster context menu "Recommend to…", Wrapped slide 4.
- **Sheet** (SH1 medium / SH4, blooming from the trigger): "Recommend {title}"; friends as 56 px orbs with TG2 checks (multi-select); friends who can't see the title (18+ series and their gate closed) are shown disabled with "Can't see 18+ titles"; IN3 note (optional, max 280, placeholder "Why they'll like it"); B1 lit "Send". Sent: the sheet dematerializes toward the friends row, toast "Sent to Anna", `recommend.sent`, `glass-send.wav` if on.
- **Receiving:** a `bloom` dot on the You tab and on Friends; the Home spotlight may pick it with the eyebrow "FROM ANNA" in `bloom`; the For you tab lists it.

#### 5.3.5 Shared collections

- **Share:** a collection's IB "Share with friends" → sheet: friend orbs with checks, "Everyone you add can add and remove series." + B1 lit "Share". Shared collections show member avatars in the header and a `bloom` 1 px rim on their stack.
- **Rules:** any member can add or remove series; each member sees only items their own gate allows (the count shown is theirs); the owner can remove members or stop sharing (alert "Stop sharing {name}?" / "It goes back to being only yours. Series friends added stay in it.") ; a member can leave ("Leave {name}?").
- **Activity:** "Anna added The Beginning After the End to Weekend binge" appears in the feed.

### 5.4 Ambient reader extras

#### 5.4.1 Auto-scroll with speed control

- **Manga strip:** base 60 px/s at 1×, steps 0.5, 0.75, 1, 1.5, 2, 3× (30–180 px/s); ramps in over 400 ms so it never lurches; a touch or manual scroll pauses it and it resumes 800 ms after release (unless the user scrolled more than a screen, which stops it); continues across stitched chapters; stops at the next-chapter card with `autoscroll.end`. Frame-delta based (clamping long frames to 1/60 s) as the engine does today.
- **Manga pages:** "Auto-advance" every 4–30 s (5 steps: 4, 6, 10, 15, 30 s) with a PR2 ring in the pill counting the interval.
- **Novels (scroll mode):** speed in words per minute (120–400 wpm in steps of 20), converted to px/s from the measured line height and words per line; the line guide, when on, rides the scroll.
- **Controls:** the auto-scroll accessory capsule (§4.14.2): tap = play/pause, vertical drag = speed (`autoscroll.step`), a HUD "1.5×" / "240 wpm" for 600 ms; the right-edge vertical swipe while running; the reader settings slider; keys `p`, `shift+,`, `shift+.`.
- **Signature:** while auto-scroll runs, the minimised pill shows a slow light moving down its rim at the scroll speed, so the speed is visible without reading a number.
- Reduced Motion: available (it is the user's motion), never auto-starts.

#### 5.4.2 Ambient soundscape

- **Scenes (8):** Rain on glass, Night city, Forest, Café, Fireplace, Ocean, Library hush, Deep space. Each is a 90 s seamless loop (AAC in M4A, 48 kHz, ~128 kbps, ≤ 1.5 MB), CC0-licensed field recordings, served by the backend's existing media route (`GET /app/media/soundscapes/{id}.m4a`) and cached on the device after the first play (web: Cache Storage; mobile: the app's cache directory).
- **Match the story** (default on when a soundscape is enabled): picks a scene from the series' genres: horror, thriller → Rain on glass; romance, slice of life, comedy → Café; fantasy, isekai → Forest; action, martial arts, sports → Night city; historical, drama → Fireplace; sci-fi → Deep space; mystery, school → Library hush; adventure → Ocean; anything else → Rain on glass.
- **Soundscape sheet** (reader settings → Ambient, `shift+s`; SH1 medium / SH3): eight **scene orbs** (64 px glass spheres, each with a slow animated light pattern: falling streaks refracting for rain, drifting points for city, dappled green for forest, warm flicker for fireplace, slow waves for ocean, still dust for library, star drift for space, steam curls for café), the active one lit; TG1 "Match the story"; SL2 volume tile (default 45 %); C2 timer Off · End of chapter · 30 min · 60 min; TG1 "Play in every reader" (profile-wide default) — scenes are per profile.
- **Audio rules:** loops cross-fade 2 s at the seam; the soundscape fades in over 3 s and out over 1.5 s; it ducks to 25 % while narration plays and returns over 1 s; it mixes with other apps' audio (iOS `playback` + `mixWithOthers`, Android no audio focus request), never ducks the user's music, and pauses when the reader leaves; UI sounds are suppressed while it plays. Playback: `flutter_soloud` 5.1.4 (looping with fades) on mobile, Web Audio (`AudioBufferSourceNode` with `loop` and a `GainNode`) on web.
- **Signature moment ("Rain on glass"):** with the rain scene on, 6–10 droplets slide down the reader's glass capsules and the minimised pill, refracting the page behind them (a fragment shader on the glass layer only: droplet radius 3–6 px, 4 s per run, random start positions; web: an SVG displacement map animated on the pill in tier A, a static droplet texture in tier B). Other scenes add nothing to the glass. Off under Reduce Motion.
- **States:** loading a scene (the orb's light runs until the file is ready); offline and not cached ("This scene needs a connection the first time."); failed ("That sound didn't load." toast); narration playing (the sheet shows "Quieter while narration plays").

#### 5.4.3 Panel-by-panel guided view

- **Data:** `GET /reader/panels?source=&series=&chapter=` (new) returns per page an ordered list of panel boxes `{x, y, w, h}` in page fractions plus a `confidence`; computed server-side from the proxied page bytes (gutter detection on a 512 px downsample: rows and columns of near-uniform colour split the page; for webtoon strips, horizontal whitespace bands split the strip into beats) and cached per chapter. Pages with confidence < 0.6 are one panel (the whole page).
- **Enter:** the reader's more menu "Panel view", long-press a page → "Panel view from here", `shift+p`, or settings → Ambient. The chrome dematerializes; everything outside the current panel dims to `#000` at 85 %; the current panel is framed by a **T2 glass lens** (radius 14, 2 px specular rim) and the camera (translate + scale of the page layer) fits the panel with 24 px padding on `spring.panel`.
- **Move:** tap the right 30 % / swipe left ≥ 50 px or ≥ 500 px/s → next panel (mirrored for RTL); left → previous; `→`/`←`, `j`/`k`, `space`. Between panels the lens slides and resizes on `spring.panel` while the dim follows; `panel.step` haptic. Across a page boundary the page slides like Pages mode. A T2 pill at the bottom: "Panel 4 of 38 · page 7" + IB6 `x`.
- **Exit:** pinch out, the pill's `x`, `Esc`, or double-tap; the camera returns to the strip at the current panel's position.
- **States:** finding panels ("Finding panels…" with a light run in the pill; the first page is shown as one panel meanwhile); not available ("Panel view isn't available for this chapter." toast + stays in the strip); offline (panels cached with a downloaded chapter; otherwise the whole page is one panel with a note "Panels need a connection").
- **Signature moment:** the lens moving between panels bends the dimmed art at its edge, so the next panel is visible as a refracted sliver before the camera arrives.
- Reduced Motion: the camera cuts from panel to panel (no travel), the lens appears at its new place with a 120 ms fade.

#### 5.4.4 Page-tinted chrome

- **Source:** the per-page palette (`GET /reader/palette`, §2.1.8), for the page under the reading line (38 % of the viewport height in the strip; the visible page in Pages mode).
- **What changes:** the reader glass's rim tint (the page's accent at `L 0.86, C ≤ 0.08`), the legibility dim (`Lb` = the page's top-band luminance for top chrome, bottom-band for bottom chrome), the text grade on the glass (GRAD), the desktop gutter pools, and the minimised pill's tint. Covers and pages are never tinted.
- **Timing:** sampled at most every 600 ms; each change cross-fades over 900 ms (`dur.field`); nothing changes during a fast fling (velocity > 3000 px/s) until it settles.
- **Novels:** the chrome takes the paper's ink as its tint; the listen window takes the cover's palette.
- **Setting:** TG1 "Page-tinted chrome" (default on; off leaves neutral glass). Reduce Transparency keeps the tint on the solid chrome's rim only.
- **Signature moment:** scrolling from a dark night panel into a sunlit one, the capsules warm and darken their dim together so the labels never flicker, and the gutters on desktop glow with the new colour: the room takes the page's light.

---

## 6. The two required signature animations

Both are owner-mandated. In Prism they keep exactly the mandated behaviour and add one material detail each (a converging chromatic split on the letters; a caret made of light), which Increase Contrast removes.

### 6.1 Heading reveal: "Condense"

**Behaviour (mandated):** each letter fades in, slides up and un-blurs, staggered. Responsive font size, tight tracking, a smooth colour transition on hover and state.

**Exact spec, per grapheme `i` (segmented with `Intl.Segmenter` on web and `characters` on Flutter, so emoji and Hangul stay whole):**

| Property | From | To | Timing |
|---|---|---|---|
| Opacity | 0 | 1 | 180 ms `ease.fade`, starting at `i × 22 ms` |
| Translate Y | 0.42 em | 0 | `spring.letter` (420 ms, bounce 0.12: stiffness 223.8, damping 26.33), starting at `i × 22 ms` |
| Blur | 10 px | 0 | 320 ms `ease.fade`, starting at `i × 22 ms` |
| Chromatic split (Prism's material detail) | `text-shadow: -1.5px 0 rgba(255,106,136,0.5), 1.5px 0 rgba(106,184,255,0.5)` | none | 240 ms `ease.fade`, starting at `i × 22 ms` (the letter condenses out of split light) |

- **Words:** the unit of wrapping is a word (letters sit inside `white-space: nowrap` word spans) so lines break only at spaces. Spaces take a stagger slot.
- **Length rule:** ≤ 60 graphemes reveal per letter; longer headings reveal per word at 40 ms (same properties, per word).
- **Concurrency:** at most two headings reveal at once; a third waits until one finishes (≤ 1.4 s).
- **Size and tracking:** the host role's responsive size and tracking (§2.3.3): H3 section headers use `type.title2` (`clamp(1.375rem, 1.1rem + 0.8vw, 1.625rem)`, tracking −0.012 em); hero banners use `type.display` (`clamp(2.5rem, 1.6rem + 3vw, 4.75rem)`, −0.030 em) or `type.largeTitle`.
- **Colour transition on hover and state:** interactive headings (rail headers with "See all", collection names, series titles that link) transition `label2 → label` over 240 ms `ease.fade` on hover or focus and materialise a `caret-right` 16 px in `glacier` 6 px after the text; a heading whose section becomes active (e.g. the Library lens tab's title) transitions to `label` and back the same way.

**Placement (exactly these, nowhere else):**

| Where | Heading | Trigger |
|---|---|---|
| Every rail header (H3): Home, For you, Series "More like this", Library "In progress", Friends sections, Stats sections, Search result groups | `type.title2` | First time the header is ≥ 60 % in the viewport during a screen visit |
| Home spotlight title (hero banner) | `type.display` | Screen entry and every spotlight change |
| Series title (hero banner), Book title (Literata, same timing) | `type.display` / Literata 44 | Screen entry, after the cover zoom lands (delay 180 ms) |
| Collection detail name | `type.largeTitle` | Screen entry |
| Recap series title, Wrapped slide headings and top-genre name | `type.display` | Slide or screen entry |
| Profile picker "Who's reading?" | `type.display` | Screen entry |
| Setup, login, register titles; onboarding step titles; the skin picker title | `type.largeTitle` | Screen entry |
| Manga reader seam chapter title ("Chapter 143 · The Gate") | `type.title2` | When the seam enters the viewport |
| Splash wordmark letters | Lens reveal §7.4 (same properties, 16 px blur) | Cold start |

Back navigation never replays a reveal on a screen it already played on (cached per route key for the session); refreshes do not replay; a changed heading (a new spotlight) replays.

**Accessibility:** the full string is exposed once (web: a visually hidden `<span>` with the text, letters `aria-hidden`; Flutter: `Semantics(label: text, child: ExcludeSemantics(...))`). **Reduce Motion:** the whole line fades in over 200 ms. **Increase Contrast:** no chromatic split.

**Web sketch** (server component, no client JS unless it must replay):

```tsx
// skins/glass/primitives/Condense.tsx
const seg = new Intl.Segmenter(undefined, { granularity: "grapheme" });
export function Condense({ text, as: Tag = "h3", className }: { text: string; as?: "h1" | "h2" | "h3"; className?: string }) {
  let i = 0;
  return (
    <Tag className={`condense ${className ?? ""}`}>
      <span className="sr-only">{text}</span>
      <span aria-hidden>
        {text.split(" ").map((w, wi) => (
          <span key={wi} className="condense-word">
            {Array.from(seg.segment(w + (wi < text.split(" ").length - 1 ? " " : "")), (s) => (
              <span key={i} style={{ "--i": i++ } as React.CSSProperties}>{s.segment}</span>
            ))}
          </span>
        ))}
      </span>
    </Tag>
  );
}
```

```css
.condense .condense-word { white-space: nowrap; }
.condense [aria-hidden] span span {
  display: inline-block;
  animation:
    condense-fade 180ms var(--mm-ease-fade) both,
    condense-rise var(--mm-spring-letter-ms) var(--mm-spring-letter-linear) both,
    condense-focus 320ms var(--mm-ease-fade) both,
    condense-split 240ms var(--mm-ease-fade) both;
  animation-delay: calc(var(--i) * 22ms);
}
@keyframes condense-fade  { from { opacity: 0; } }
@keyframes condense-rise  { from { translate: 0 0.42em; } }
@keyframes condense-focus { from { filter: blur(10px); } }
@keyframes condense-split { from { text-shadow: -1.5px 0 rgb(255 106 136 / .5), 1.5px 0 rgb(106 184 255 / .5); } }
@media (prefers-reduced-motion: reduce) { .condense [aria-hidden] span span { animation: condense-fade 200ms both; animation-delay: 0ms; } }
@media (prefers-contrast: more) { .condense [aria-hidden] span span { animation-name: condense-fade, condense-rise, condense-focus; } }
```

`--mm-spring-letter-linear` is the `linear()` easing the token generator samples from `spring.letter` (§9.1). A viewport-triggered variant adds `animation-play-state: paused` until an `IntersectionObserver` (threshold 0.6) sets `data-inview`.

**Flutter sketch** (`flutter_animate` 4.5.2):

```dart
// skins/glass/primitives/condense.dart
Widget build(BuildContext context) {
  if (MediaQuery.disableAnimationsOf(context)) {
    return Text(text, style: style).animate().fadeIn(duration: 200.ms);
  }
  var i = 0;
  final words = text.split(' ');
  return Semantics(label: text, child: ExcludeSemantics(child: Wrap(children: [
    for (final (wi, w) in words.indexed)
      Row(mainAxisSize: MainAxisSize.min, children: [
        for (final g in (wi < words.length - 1 ? '$w ' : w).characters)
          Text(g, style: style).animate(delay: (22 * i++).ms)
            .fadeIn(duration: 180.ms, curve: GlassCurves.fade)
            .blur(begin: const Offset(10, 10), end: Offset.zero, duration: 320.ms, curve: GlassCurves.fade)
            .custom(duration: 420.ms, builder: (_, t, child) =>   // spring.letter sampled once into a curve
              Transform.translate(offset: Offset(0, (1 - GlassSprings.letterCurve.transform(t)) * style.fontSize! * 0.42), child: child)),
      ]),
  ])));
}
```

The chromatic split on Flutter is two extra copies of the glyph tinted `#FF6A88` / `#6AB8FF` at 50 % offset ±1.5 px that fade out over 240 ms, only for `type.display` headings (smaller sizes skip it; the effect is invisible below 28 px).

### 6.2 Main headline typing reveal: "Light type"

**Behaviour (mandated):** one character every 50 ms.

**Exact spec:**

- The headline string is split into graphemes; character `n` (0-based, spaces included) becomes visible at `t = n × 50 ms`, instantly (opacity 0 → 1 in one step: `animation: type-in 1ms steps(1) both`, delay `n × 50ms`). A 30-character greeting therefore takes 1.5 s.
- **The caret:** a 2 px × 0.9 em capsule of `glacier` light with a 1 px white specular core and a 6 px `rgba(143,216,255,0.35)` glow, placed after the last visible character, moving with it. After the last character it blinks 530 ms on / 530 ms off three times, then dematerializes (blur 0 → 6 px, fade 350 ms).
- **Cap:** 48 characters (2.4 s). Longer headlines type their first line and the remainder fades in over 200 ms as the caret reaches the line end.
- **Skip:** any tap, click or key on the screen completes it at once (the caret still blinks and leaves).
- **Once:** it plays once per app session per profile per placement; later visits show the text immediately.

**Placement (exactly these):**

| Where | Headline | Size |
|---|---|---|
| **Home greeting** (the main headline) | "Good evening, {profile}." / "Welcome, {profile}." (new profile) | `type.display` desktop, `type.largeTitle` phone |
| Onboarding finish (the handoff into Home) | The same greeting, typed as the takeover dissolves | same |
| Recap headline | e.g. "Jin-woo walked out of the gate alone." | `type.title2` |
| Wrapped slides 1–9 headlines | e.g. "Your 2026 in chapters" | `type.title1` inside the frame |
| For you `why` lines as results land | first 80 characters of each reason | `type.footnote` |

**Accessibility:** the complete string is in the DOM or semantics from the first frame (web: `aria-label` on the heading and the typed spans `aria-hidden`; Flutter: `Semantics(label:)`); screen readers read it at once. **Reduce Motion:** the text appears at once with no caret.

**Web sketch:**

```tsx
// skins/glass/primitives/LightType.tsx (client component: it must skip on input)
export function LightType({ text, className }: { text: string; className?: string }) {
  const g = Array.from(new Intl.Segmenter(undefined, { granularity: "grapheme" }).segment(text), (s) => s.segment);
  return (
    <h1 className={`light-type ${className ?? ""}`} aria-label={text}>
      {g.map((c, n) => <span key={n} aria-hidden style={{ animationDelay: `${n * 50}ms` }}>{c}</span>)}
      <span className="light-caret" aria-hidden style={{ animationDelay: `${g.length * 50}ms` }} />
    </h1>
  );
}
```

```css
.light-type > span:not(.light-caret) { animation: type-in 1ms steps(1) both; }
@keyframes type-in { from { opacity: 0; } }
.light-caret { display: inline-block; width: 2px; height: .9em; margin-inline-start: 2px; border-radius: 9999px;
  background: #8FD8FF; box-shadow: inset 0 0 0 .5px #fff, 0 0 6px rgb(143 216 255 / .35);
  animation: caret-blink 1060ms steps(1) 3 both, caret-out 350ms var(--mm-ease-fade) forwards; }
```

**Flutter sketch:** a `Ticker`-driven `ValueNotifier<int>` that advances `visibleCount` every 50 ms (`Timer.periodic(const Duration(milliseconds: 50), …)`), rendering `Text.rich` with the invisible remainder kept in layout (`color: transparent`) so the line never reflows, and a positioned caret measured with `TextPainter.getOffsetForCaret`.

---

## 7. Brand

The name "ManhwaManiacs" is fixed; everything else is new. Prism uses the brand system's **"Stack"** lockup and **"MM column"** mark (`research/brand.md` W2 / I1), rendered as glass. The idea of the double M (two panels and the gutter between them) becomes, in Prism, **two panes of glass and the light between them**.

### 7.1 Wordmark

- **Stack lockup (primary):** "Manhwa" above "Maniacs", flush left, leading 0.84. The two capital M's form the **MM column**: a single vertical glass capsule (corner radius 40 % of its width) with both M's engraved into it (engraving: `inset 0 2px 2px rgba(0,0,0,0.45)` shadow plus a `rgba(255,255,255,0.55)` specular edge along the lit side), and between them the **gutter bar** as a refractive seam that shows what is behind the mark with a 2 px chromatic fringe. The lowercase letters are Google Sans Flex `ROND 100, wght 620, opsz 48`, tracking −0.02 em, in Frost `#F5F7FA`; the `i` tittles are round.
- **Single-line lockup** (the desktop sidebar, headers, the install page): "ManhwaManiacs" in Google Sans Flex `ROND 100, wght 640`, tracking −0.02 em, where only the two M's are glass (frosted fill `rgba(255,255,255,0.10)`, rim, specular) and the rest is Frost.
- **Mark:** the MM column alone (favicon, tab bar handoff, loaders, avatars' fallback).
- **Sizes and clearspace:** Stack ≥ 32 px tall; single line ≥ 20 px tall; mark ≥ 16 px (below 24 px the M's are solid Frost, no glass). Clearspace = 2 × the gutter bar's thickness on every side.
- **Monochrome:** solid Frost (or solid black on light print), no glass, no fringe.
- **Files:** `brand/glass/wordmark-stack.svg`, `brand/glass/wordmark-line.svg`, `brand/glass/mark.svg` (glass drawn with SVG gradients and filters so it renders anywhere), plus `brand/shared/mark-neutral.svg` for splash screens. Web renders the live wordmark as components so the glass samples the real field.

### 7.2 App icon ("MM column", Glass rendition)

- **Geometry** (1024 canvas, shared with the Cinematic rendition): MM column bounding box x 240–784, y 192–832; top M y 192–480; bar y 480–544 (x 208–816); bottom M y 544–832; stroke 88, miter joins, flat caps.
- **Glass rendition:** background a radial field from `#0A0F1F` (centre at 30 %, 25 %) to `#000000` at the corners, with an aurora pool (`#8FD8FF`, `#A99BFF`, `#FF9ED8` at 45 %, 180 px blur) upper-left; the MM column as glass in two layers: the **back layer** (bottom M + bar) and the **front layer** (top M), each with a white 12 % fill, a 6 px specular rim along the top-left edges, and a soft neutral shadow; the bar emits a 4 px `#8FD8FF` light line along its lower edge.
- **Platform deliverables:** iOS 1024 master PNG (opaque), iOS 18+ dark (transparent background, mark only) and tinted (grayscale) variants through `flutter_launcher_icons` 0.14.4; an **iOS 26 Icon Composer** `.icon` package (layers: background, back glass, front glass; translucency 0.5, specular on, neutral shadow) compiled on the CI runner after an `xcodebuild -version` check for Xcode ≥ 26, with the PNG set kept as the fallback; **Android adaptive** foreground (the column inside the 66 dp safe circle, ≈ 160 × 188 px at xxxhdpi) + background (the field PNG) + **monochrome** layer for Android 13 themed icons; **web** `favicon.svg` (full column at ≥ 32 px; a single M on the bar at 16 px, 1.5 px stroke), `icon-192.png`, `icon-512.png`, `maskable-512.png` (mark inside the 290 × 290 safe box), `apple-touch-icon.png` 180.
- **Per-skin icon:** switching skin sets the alternate icon (`flutter_dynamic_icon_plus` 1.4.1; iOS shows its own "You have changed the icon" alert, which lands inside the restart moment); the web swaps `<link rel="icon">` to the Glass SVG at load (the installed PWA icon cannot change at runtime).

### 7.3 Splash

- **Native (both platforms):** one neutral splash for both skins, because iOS's launch storyboard can't know the skin: the MM column in `#F5F7FA` on `#000000` (`flutter_native_splash` 2.4.8: `color: "#000000"`, `image: brand/splash/mm-neutral.png` 1152 × 1152, `android_12: {image: brand/splash/mm-neutral-a12.png, color: "#000000"}`; the mark inside Android 12's 192 dp visible circle).
- **Handoff:** the first Flutter frame (or the web's server-rendered inline SVG) draws the neutral mark at the identical size and position, then plays the Lens reveal. Installed iOS PWA: black `appleWebApp.startupImage` files so launch never flashes white.

### 7.4 Logo reveal: "Lens" (cold start 1,200 ms, warm start 400 ms)

| t (ms) | Element | Motion |
|---|---|---|
| 0–200 | Droplet | The neutral mark fades to 0 (120 ms) while a 24 px T1 clear-glass droplet falls from 40 px above centre to centre on `spring.drop` (stiffness 385.5, damping 29.45); `logo.land` haptic (soft 0.6) on landing |
| 200–700 | Lens | The droplet grows into a 168 px squircle lens (corner 28 %) on `spring.lens` (stiffness 109.7, damping 17.17). Inside it the MM column appears refracted: displacement 40 → 0 and dispersion 3 px → 0 as it settles, while the `default` mood field blooms out of the lens from 0 to 26 % |
| ≈ 700 | Settle | `logo.settle` (AHAP `refract`); `glass-logo.wav` if interface sounds are on |
| 500–1,000 | Wordmark | "Manhwa" / "Maniacs" letters condense out of the lens's edge (the heading reveal with 16 px blur, 22 ms stagger, `spring.letter`): to the right of the lens on desktop, under it on phones |
| 900–1,000 | Sweep | One specular sweep crosses the lens and the letters |
| 1,000–1,200 | Handoff | The lens morphs (`spring.morph`) into the tab bar's capsule (phone) or into the sidebar's wordmark (desktop); the letters travel into the sidebar lockup or fade on phones |

- **Warm start** (resumed within 4 h, or the web's second load in a session): the lens materializes over 250 ms and hands off in 150 ms; no droplet, letters or haptics.
- **Skin-switch arrival:** the full cold reveal plays (it is the moment where everything changes).
- **Skip:** a tap anywhere jumps to the handoff.
- **Reduced Motion:** a 200 ms cross-fade from the neutral mark to the app and one `light` haptic.

### 7.5 Showcase

The install page and the SideStore source take a Glass "Float" screenshot set (5 frames, 1320 × 2868, captured from the mobile web layout at a 440 × 956 viewport at DPR 3 with Playwright): the UI on a glass slab (radius 88, 1.5 px inner highlight `rgba(255,255,255,0.35)`, shadow `0 60px 120px rgba(0,0,0,0.6)`, tilted `rotateY(-8deg) rotateX(4deg)`) over the aurora field at 35 %; captions in Google Sans Flex `ROND 100, wght 660`, 112 px, Frost: "Every source. One shelf." / "Built for the long scroll." / "Novels, read aloud." (sub: "31 named voices") / "Your year in chapters." / "Read together." A seeded demo profile only; no 18+ content; placeholder covers drawn in-house in the hero frame.

---

## 8. Signature moments

| # | Moment | Where | Choreography | Feel | Reduced Motion |
|---|---|---|---|---|---|
| 1 | **Lens reveal** | Cold start, skin-switch arrival | §7.4 | `logo.land`, `logo.settle`, `glass-logo.wav` | Cross-fade |
| 2 | **Step into the light** | Profile picker | The chosen orb swells, others dissolve outward, its colours pour into the field, it flies into the You tab / sidebar chip while Home materializes (1,100 ms) | `profile.switch` | Cross-fade to Home |
| 3 | **Light follows the story** | Home spotlight | Changing the spotlight slides the field's pools to the new cover's colours (900 ms) and every glass rim, droplet and dim follows | none | Instant field change |
| 4 | **Lens dive** | Continue / Read into the reader | The lit button's glass grows (`spring.morph`) into a full-screen lens that refracts the cover (displacement 1 → 1.4), then clears (displacement → 0, blur 22 → 0, 250 ms) onto the first page at the saved position; 520 ms total | `press.lit` then nothing (reading is quiet) | 200 ms cross-fade |
| 5 | **The cover becomes the room** | Series page | The cover zoom lands the poster while its blurred copy grows into the backdrop and its palette lights the field; Follow sends a `glacier` caustic ring across the backdrop | `library.add` on follow | Cross-fade; no ring |
| 6 | **Page-tinted chrome** | Manga reader | The capsules take the light of the page under them, dims and grades adapting as panels change (§5.4.4) | none | Tint changes without cross-fade |
| 7 | **The rising glass** | Manga chapter end | 90 px of overscroll raises a glass sheet carrying the next chapter's first page; release expands it into the chapter | `reader.chapterEnd` (AHAP `ripple`), `reader.chapterCommit`, `glass-chapter.wav` | The card's button only; 200 ms cross-fade |
| 8 | **The moving lens** | Listen window | The sentence lozenge slides from sentence to sentence refracting the words, and the voice orb breathes with the audio | `tts.play` | Lozenge jumps; orb still |
| 9 | **Droplet tab bar** | Phone tab bar | Dragging across the bar lifts the selection droplet into clear glass that stretches with speed and ticks at each tab; it can be dropped into the search orb | `tab.scrub`, `tab.select` | Selection jumps |
| 10 | **Genre droplets** | Onboarding step 3 | Tap once to light a genre, twice to make it glow, hold to pop it; neighbours make room | `detent.tick`, `threshold.cross` | Size changes without spring |
| 11 | **Hold to confirm** | 18+ gate, Sign out everywhere, Restore, Delete member | Holding fills the capsule with liquid light over 900 ms, ticking every 25 %, draining if released | `gate.holdTick`, `gate.unlock` | Fill without meniscus |
| 12 | **The storage tube** | Downloads → Storage | Liquid segments settle with a meniscus; the cap marker slides; the level turns amber near the cap | `detent.tick` on cap change | Values jump |
| 13 | **Rain on glass** | Reader with the rain soundscape | Droplets run down the reader's glass capsules, refracting the page | none | Off |
| 14 | **Spectral streak** | Streak milestones | The flame's light splits into the spectrum for 900 ms, then settles | `streak.milestone`, `glass-shimmer.wav` | Toast only |
| 15 | **Dissolve into light** | Leaving Glass for Cinematic | Every glass object over-refracts and blurs while the field brightens to white-hot and cuts to black (700 ms) | `skin.confirm`, `glass-restart.wav` | 200 ms fade to black |
| 16 | **Hit lens** | Dialogue search into the reader | A glass lens slides from speech bubble to speech bubble, magnifying each matched line | `ocr.hit` | Outline appears without travel |
| 17 | **Thinking in light** | For you Ask box | An `iris` light runs the box's rim and pools under the waiting cards; results materialize and their reasons type in | none | Static iris rim |

---

## 9. Implementation notes (for the stack in `stack-decision.md`)

### 9.1 Token source

`design/tokens/glass.json` holds every value in §2 (colours, materials by tier, type roles per breakpoint, text-scale rule, spacing, radii, blur, springs as `{ms, bounce}`, timed values, stagger rules, the haptic map from `HapticEvent` to pattern names, the sound map from `SoundEvent` to file names); `design/contract.json` holds the ScreenIds and paths in §4.0.3 and the event names in §2.11 / §2.12. Excerpt:

```json
{
  "color": { "canvas": "#000000", "surface1": "#171B20", "label": "#F5F7FA", "glacier": "#8FD8FF", "glacierDeep": "#1F5A80", "iris": "#A99BFF", "bloom": "#FF9ED8", "flare": "#FFB05C" },
  "glass": {
    "t2": { "thickness": 20, "bezel": 10, "displacement": 10, "blur": 6, "saturate": 1.8, "fill": "rgba(255,255,255,0.06)", "specular": 0.42, "shadow": "0 6px 20px rgba(0,0,0,0.45)", "dispersion": 0 },
    "t4": { "thickness": 40, "bezel": 18, "displacement": 18, "blur": 22, "saturate": 1.8, "fill": "rgba(24,28,34,0.46)", "specular": 0.30, "shadow": "0 24px 64px rgba(0,0,0,0.60)", "dispersion": 0.6 }
  },
  "legibilityDim": { "base": 0.22, "slope": 0.42, "max": 0.64 },
  "spring": { "press": { "ms": 250, "bounce": 0.15 }, "smooth": { "ms": 500, "bounce": 0 }, "morph": { "ms": 375, "bounce": 0.27 }, "letter": { "ms": 420, "bounce": 0.12 } },
  "haptics": { "tab.select": "selection", "gate.unlock": "ahap:unlock", "download.done": "ahap:meniscus" },
  "sounds": { "tap": "glass-tap.wav", "logo": "glass-logo.wav" }
}
```

`design/build.mjs` (Node 22 stdlib) emits, per the stack decision:

- `frontend/src/skins/glass/tokens.generated.css`: `[data-skin="glass"] { --mm-color-glacier: #8FD8FF; --mm-glass-t2-blur: 6px; … }` plus, for every spring, `--mm-spring-{name}-ms` and `--mm-spring-{name}-linear: linear(…)` sampled at 64 points from the exact damped-spring solution (so CSS-only transitions and the heading reveal share the physics).
- `frontend/src/skins/glass/tokens.generated.ts`: numbers for Motion. **Springs are emitted as physical `{ type: "spring", stiffness, damping, mass: 1 }`** computed with Apple's conversion (`k = (2π/d)²`, `c = 4π(1 − bounce)/d`), not as `visualDuration`, because Motion's duration-based springs discard the inherited velocity on retarget (`motion-dom` spring source), and Prism requires velocity-preserving interruption (§2.10.6). The token format itself stays `{ms, bounce}` as the stack decision specifies.
- `mobile/lib/skins/glass/tokens.g.dart`: `const glassTokens = GlassTokens(colorGlacier: Color(0xFF8FD8FF), glassT2: GlassTier(thickness: 20, blur: 6, …), springPress: SpringToken(ms: 250, bounce: 0.15), …)`, with `SpringToken.description` returning `SpringDescription.withDurationAndBounce(duration: Duration(milliseconds: ms), bounce: bounce)`; letter spacing converted from em to absolute per style.
- `--check` in CI (`tests.yml`) regenerates in memory and fails on drift.

### 9.2 Web (`frontend/src/skins/glass/`)

| File | Role |
|---|---|
| `fonts.ts` | `next/font/google`: `Google_Sans_Flex({ subsets: ['latin'], axes: ['ROND','GRAD','opsz'], variable: '--font-glass-sans', preload: false })`, `Google_Sans_Code({ subsets: ['latin'], variable: '--font-glass-mono', preload: false })`, `Literata({ subsets: ['latin'], axes: ['opsz'], style: ['normal','italic'], variable: '--font-glass-book', preload: false })`; the splash covers the swap |
| `Shell.tsx` | Sidebar (≥ 1024), collapsed rail (768–1023), tab bar + search orb + accessory (< 768); the ambient field layer; the key-light provider |
| `primitives/GlassSurface.tsx` | The one glass component: props `tier`, `variant` (`regular`/`clear`/`lit`/`coral`), `backdropL` (for the dim). Renders tier A (liquid) on Chromium (`navigator.userAgentData?.brands` contains "Chromium") with `backdrop-filter: url(#lg-{w}x{h}-r{r}) blur() saturate()`, tier B (frosted) elsewhere, tier C (solid) under `prefers-reduced-transparency: reduce`, `prefers-contrast: more` or the in-app Solid glass setting. `::before` specular rim along `--mm-light-angle`, `::after` press glow at `--mx/--my` |
| `primitives/liquid-map.ts` | Our own displacement-map generator (convex-squircle bezel profile, Snell refraction at n = 1.5, 128 samples, R = x / G = y around neutral 128, `colorInterpolationFilters="sRGB"`, `scale = 2 × max`); one `<filter>` per (w, h, r) cached in a shared hidden `<svg>`; rebuilt on `ResizeObserver` with a 100 ms debounce; materialize animates only the filter's `scale` (0 → full); size-changing morphs (tab bar minimise, blooms) use tier B during the motion and return to tier A at rest. The kube.io article is the technique reference; its repository has no licence, so no code is copied |
| `primitives/useKeyLight.ts` | One `pointermove` listener on `window`, rAF-throttled, writing `--mm-light-angle` on `:root`; static under reduced motion; no gyro on web |
| `primitives/AmbientField.tsx` | One fixed layer with three radial-gradient divs, `filter: blur(120px)`, a mask to 0 at 60 %, drift by CSS `@keyframes` on `transform` (40 s); colours from the owning art's `palette` (CSS variables cross-faded with `@property`-registered colours over 900 ms) |
| `primitives/*` | Button (B1–B7), IconOrb, Field, Stepper, Search, Chip, Segmented (Motion `layoutId` thumb), Switch, Slider, Scrubber (magnifier), Sheet (`@base-ui/react` 1.8.0 `Drawer`, snap points `['96px', 0.5, 1]`, released with our springs via Motion), Menu / ContextMenu / Dialog (Base UI), Toast (`sonner` 2.0.8, our render), Poster, Rail (`embla-carousel-react` 8.6.0 for the spotlight and the voice orbit; native scroll-snap rails elsewhere), ObjectLens, Skeleton, StreakFlame, Condense (§6.1), LightType (§6.2) |
| `motion.ts` | `glassSpring` from the generated tokens; `<MotionConfig reducedMotion="user" transition={glassSpring.smooth}>` at the shell |
| `haptics.ts` | Android Chrome `navigator.vibrate` for `toggle.on` `[10]`, `menu.bloom` `[18]`, `library.add` `[12,60,12]`, `download.fail` `[24,50,24]`, `notify.error` `[24,50,24,50,24]`; no-op elsewhere |
| `sounds.ts` | Web Audio: decode the 16 WAVs on the first user gesture, play through one `GainNode`; suppressed while narration or a soundscape plays |
| `screens/*` | One file per ScreenId; `screens: {...} satisfies Record<ScreenId, Screen>` |

Dependencies (from the stack decision): `motion` 13.4.4 (replacing `framer-motion` 12), `@base-ui/react` 1.8.0, `embla-carousel-react` 8.6.0, `sonner` 2.0.8, plus `@use-gesture/react` 10.3.1 (reader pinch), `@phosphor-icons/react` 2.1.10, `fast-average-color` 9.6.0 (palette fallback). Lenis is not used by Glass. Route transitions use React `<ViewTransition>` with `transitionTypes`; in-page shared layout uses Motion `layoutId`. The ESLint boundary rule forbids imports from `@/components/**`, `@/features/*/components/**` and `skins/cinematic/**`.

### 9.3 Flutter (`mobile/lib/skins/glass/`)

| File | Role |
|---|---|
| `glass_skin.dart` | `GlassSkin implements Skin` (theme, router, splash, haptics, sounds) |
| `skin_glass.dart` | **The only file that touches `liquid_glass_widgets` 1.7.2 (pinned exactly).** Maps each tier to `LiquidGlassSettings` (`thickness` = the tier's virtual thickness, `blur`, `refractiveIndex` 1.15, `chromaticAberration` 0 / 0.35 / 0.5, `lightAngle` from the key light in radians, `lightIntensity` scaled by the specular value, `saturation`); `GlassQuality.premium` for static chrome and `standard` inside scroll views; wraps siblings in one glass group; honours `GlassAccessibilityScope(reduceTransparency:)`. **Fallback** (if the Glass gate in the foundation week fails on the owner's iPhone, or on Skia): `BackdropFilter` inside one `BackdropGroup` per screen + a `CustomPainter` rim, specular and glow; only this file changes |
| `shell.dart` | `StatefulShellRoute.indexedStack` with the Glass tab bar (`GlassTabBar`, `barHeight 64`, `minimizedBarHeight 50`, search variant, minimise at 20 / 12 pt), the bottom accessory, the ambient field (`CustomPaint` with three `RadialGradient`s under an `ImageFiltered` blur 120) |
| `router.dart` | Its own `GoRouter` from `contract.g.dart`; iOS pages are `SwipeablePage` (`swipeable_page_route` 0.4.8, full-width), Android pages `MaterialPage` with `PredictiveBackPageTransitionsBuilder`; cover zoom with `heroine` 0.7.2 (`Heroine(tag:, motion:)` on `spring.smooth`); parallax slide and lens dive as `CustomTransitionPage`s driven by `SpringSimulation` |
| `primitives/*` | Mirrors the web list; sheets via `GlassModalSheet` (peek 96, half 0.5, margins 8, `fullTopBorderRadius` 36, barrier `0x40000000`, `morphFrom`), with `smooth_sheets` 1.2.0 for sheets holding 1,000-row lists if the scroll handoff stutters; context menus `CupertinoContextMenu.builder`; pull to refresh `CupertinoSliverRefreshControl` with the droplet `builder`; skeletons `skeletonizer` 3.0.0; choreography and the heading reveal `flutter_animate` 4.5.2; image viewer `extended_image` 10.1.0 |
| `glass_springs.dart` | `SpringDescription.withDurationAndBounce` per token; retargets with `controller.animateWith(SpringSimulation(spring, value, target, velocity))`; fling projection `pos + v × 0.499` |
| `type.dart` | Bundled `GoogleSansFlexMM.ttf`, `GoogleSansCodeMM.ttf`, `LiterataMM[.ttf, -Italic.ttf]`; every style sets `fontWeight` and `fontVariations: [FontVariation('wght', w), FontVariation('opsz', size), FontVariation('ROND', r), FontVariation('GRAD', g)]`; the text-scale rule (§2.3.4) through a per-role `TextScaler.clamp` |
| `haptics.dart` | The Glass `HapticEvent` → pattern map over the shared `skin_haptics.dart` (`gaimon` 1.5.0 named impacts and AHAP JSON from §2.11, `haptic_feedback` 0.6.5 `selection`, the `mm/haptics` channel for Android 14 constants and the iOS `reduceTransparency` query); honours the Haptics toggle; 40 / 120 ms rate limits |
| `sounds.dart` | `flutter_soloud` 5.1.4: the 16 WAVs preloaded after the first frame; `.ambient` session on iOS; muted while `just_audio` narration or the soundscape plays |
| `light.dart` | Key light from `sensors_plus` 7.1.0 gyroscope (roll × 0.5, ±25°, `spring.tilt`), off under reduced motion |

Also: `material_color_utilities` ^0.13.0 for the offline palette fallback; `flutter_native_splash` 2.4.8, `flutter_launcher_icons` 0.14.4 and `flutter_dynamic_icon_plus` 1.4.1 for brand assets; `phosphor_flutter` 2.1.0 plus one `fantasticon`-built TTF for the six custom glyphs; `audio_service` for lock-screen narration controls (the newest release that resolves on 3.44.6, pinned exactly). The import-boundary test and the completeness test from the stack decision cover `skins/glass/**`.

### 9.4 Reader engine seam

The Glass reader chrome is a `chromeBuilder(context, ReaderEngineState)` (Flutter) / `renderChrome(state)` (web) over the shared engine. Glass needs these fields from the engine state in addition to the base set (page, total, chapter, prev/next, direction, mode, zoom, chrome visible, cinema, auto-scroll, lock): `currentPagePalette` (from `GET /reader/palette`, keyed by page), `scrollVelocity` (to freeze tint changes during flings), `seamProgress` (0–1 as a chapter seam crosses the viewport), `overscrollExtent` (for the rising glass and the previous-chapter pill), and `panelBoxes` (panel view). The engine keeps owning thresholds (24 / 56 px chrome, 3000 ms idle, 800 ms orientation hold), preload, progress and bookmarks, so a skin switch never changes what a zone or key does.

### 9.5 Backend additions this concept depends on

All are profile-scoped, apply the 18+ gate when serving (never when storing), and leave `backend/connectors/` untouched.

| Endpoint / change | Shape | Used by |
|---|---|---|
| `reading_profiles.skin` + `PATCH /profiles/{id} {skin}` | nullable `'cinematic' \| 'glass'` | Skin switch (stack decision §2.4) |
| Cover palette on series payloads | `palette: {a: [hex, hex, hex], l: 0–1}` on `SourceSeries`, `FollowedSeries`, continue-reading items and `WorldItem`; `cover_palette` table (Pillow `quantize(6, MEDIANCUT)` on `w=96`) | Ambient field, rim tints, share cards |
| `GET /reader/palette?source=&series=&chapter=` | `{pages: [{page_key, top, mid, bottom, accent, l_top, l_bottom} \| null]}` from the image proxy's in-memory LRU | Page-tinted chrome |
| `GET /reader/panels?source=&series=&chapter=` | `{pages: [{page_key, confidence, panels: [{x, y, w, h}]}]}`, cached per chapter | Panel view |
| `PUT /profiles/{id}/taste`, `POST /library/taste/seed` | `{formats[], genres{name: weight}, styles[], seeds[]}` → `{items: SourceSeries[]}` | Onboarding, AI seeding |
| `GET /library/similar?source=&series=&limit=` | `{items: WorldItem[], unavailable_reason}` | More like this, caught-up card |
| `POST /library/recommendations/feedback` | `{anilist_id? , source_id?, series_key?, verdict: "not_interested"}` | Not interested |
| `GET /recap?source=&series=&chapter=`, `POST /recap` | `{state: "ready"\|"generating"\|"no_source_text"\|"unavailable", headline, beats: [{chapter_key, chapter_number, text, page_key?}], characters: [{name, note}], last_line, model, covers_to_chapter}`; POST returns 202 and the client polls every 3 s | Previously on |
| `GET /library/statistics/year?year=` | calendar-year totals, `by_month`, `genres_by_month`, `top_series`, `biggest_day`, `longest_session`, `first_read`, `last_read` | Wrapped, Stats Year range |
| `GET /social/feed?cursor=`, `GET /social/friends`, `PUT /profiles/{id}/social`, `POST/DELETE /social/reactions`, `GET /social/reactions?source=&series=&chapter=`, `POST /social/recommendations`, `GET /social/inbox`, `POST /library/collections/{id}/share` | as §5.3 | Friends |
| `/app/media/soundscapes/{id}.m4a` (static files through the existing media route) | 8 loops | Soundscape |

### 9.6 Capability floor and performance guards

| Platform | Glass tier |
|---|---|
| Chrome / Edge desktop, Android Chrome | A: liquid refraction (SVG displacement), dispersion on T4–T5 |
| Safari (macOS, iOS, installed iOS PWA), Firefox | B: frosted (blur, saturate, rim, inner light, caustic, glow; no displacement) |
| Flutter iOS and Android (Impeller) | Premium shader on static chrome, standard shader inside scroll views |
| Flutter on Skia (`ImageFilter.isShaderFilterSupported == false`) | Frosted via `BackdropFilter` |
| Reduce Transparency (iOS/macOS system, in-app Solid glass everywhere), Increase Contrast | C: solid / contrast |

This is a renderer capability floor plus accessibility, not a low-end design tier: shapes, layout, motion and haptics are identical at every tier. Guards: at most two stacked glass layers; at most six live `backdrop-filter` surfaces per screen on web (tab bar, search orb, accessory, one orb group, one sheet, one toast); glass never inside scroll views; one ambient field layer per screen; per-letter reveals ≤ 60 graphemes and ≤ 2 at once; page palette updates ≤ 1 per 600 ms; displacement maps built only at rest. The target is 120 Hz (8.3 ms frames) on the owner's iPhone and Android flagship, checked with the Diagnostics screen's FPS and jank tiles and its "Glass layers on screen" row.

### 9.7 Verification

- **Contrast script** (`design/check-contrast.mjs`, run in `build.mjs --check`): asserts every text/background pair in the tokens is ≥ 4.5:1 (≥ 3:1 for ≥ 24 px), including labels on glass over a white page at the maximum legibility dim (`Lb = 1` → 0.64) and white on lit glass at 86 % over white (5.27:1).
- **Screenshots:** the Playwright harness and the Flutter screenshot test loop over both skins; Glass adds a checkerboard backdrop page to compare web tier A with Flutter premium side by side (the calibration knobs in §2.2.2).
- **Reduced motion / transparency / contrast:** one snapshot per screen per setting.
- **Tests:** the stack decision's completeness and boundary tests, plus one smoke test per cluster for Glass.
