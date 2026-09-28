# ManhwaManiacs Glass skin: "Meniscus" — design contract

**Status: final** (revised 2026-09-28 to close every high and medium gap, and the low ones, in `glass/critic.md`; deviations from the stack decision are collected in §15.10, the dependency ledger is §15.11, and Appendix B maps every inventory screen to its section). This file is the single source of truth for every implementation session that builds the Glass skin on the web client (`frontend/`, Next.js 16 + React 19 + Tailwind 4 + Motion 13) and the mobile client (`mobile/`, Flutter 3.44.6, iOS and Android). Where it disagrees with a concept file, this file wins. It is built on the judged winner, `concepts/glass-3.md` ("Meniscus", physics-first), with ideas grafted in from `concepts/glass-1.md` ("Prism", material-first) and `concepts/glass-2.md` ("Strata", spatial-first). Appendix A lists every graft, where it was written, and the places where a graft was adapted rather than copied.

The angle: **springs, gestures, interruptible motion and haptics define the feel.** Every surface has mass, every boundary has elasticity, every threshold has a detent you can feel, and every moving thing can be caught mid-flight by a finger. The look (Apple Liquid Glass and visionOS depth on an AMOLED `#000000` canvas) exists to make that physics legible, and the light that passes through the glass always comes from the art: covers, pages and the reader's own profile.

Binding inputs: `inventory/00-decisions.md` (owner decisions), `inventory/web.md`, `inventory/mobile.md`, `inventory/capabilities.md`, `research/*.md` (chiefly `glass-language.md`, `gestures-nav.md`, `reader-ux.md`, `brand.md`, `discovery-ux.md`, `flutter-motion-libs.md`, `web-motion-libs.md`), `stack-decision.md` (keep Next.js 16 + Flutter 3.44.6, per-skin screen folders on the shared data layer, one JSON token source in `design/tokens/glass.json`, one contract in `design/contract.json`, restart on skin switch) and `00-baseline.md`. The shared contract (`design/contract.json`: screen ids, route paths, haptic and sound event names) and the shared backend endpoints are the ones `cinematic/DESIGN.md` already fixed; this file uses them and lists every Glass addition in §15.6. Dark only on AMOLED `#000000`, restart on skin switch, flagship-only effects, OS accessibility settings honoured, UI sounds off by default, haptics rich and on by default.

## Contents

1. Manifesto
2. Tokens (colour, spacing, radius, materials and the thickness scale, blur, borders and focus, iconography, the token name map)
3. Type scale (families, scale, text scale, novel type, material-aware axes, Legible text, the type-role name map)
4. Motion (laws, springs, hand-off, projection, rubber-banding, thresholds, timed values, stagger, interruptibility, the motion table, reduced motion, transparency and contrast)
5. Haptics
6. UI sounds
7. Component catalog
8. Per-screen specs
9. The four new features
10. The two required signature animations
11. Gesture matrix
12. Brand assets
13. Signature moments
14. Accessibility and reduced-motion rules
15. Implementation notes (including §15.10 amendments to `stack-decision.md` and §15.11 the dependency ledger)
- Appendix A. Graft ledger
- Appendix B. Coverage (every inventory screen and every new-feature screen, and the section that specifies it)

## Conventions used everywhere below

- **Units.** Lengths are logical px (1 CSS px = 1 Flutter logical pixel = 1 iOS pt). Letter spacing is in em; `design/build.mjs` multiplies it by the font size for Dart. Velocities are px/s. Times are ms.
- **Springs** are written `{ms, bounce}`, the format `stack-decision.md` §2.1 fixes. Stiffness `k` and damping `c` (mass 1) are listed beside each token, because the web emits physical springs (§4.3 says why). Conversion: `k = (2π / d)²`, `c = 4π(1 − bounce) / d` with `d` in seconds, damping ratio `ζ = 1 − bounce`.
- **Curves** are written `{ms, bezier}` and are used for opacity and colour only. Anything that moves in space is a spring.
- **Breakpoints.** "Phone" means the iOS app, the Android app and mobile web below 768 px together; deltas are listed where they exist. "Tablet" is 768 to 1023 px (web and large Flutter windows). "Desktop" is web at 1024 px and wider, and a Flutter window whose shorter side is at least 600 px and whose width is at least 1024 px (iPad landscape, Android tablets); "wide" is 1440 px and wider. Flutter picks the frame by the shorter side first (§8.0.1), so a phone in landscape is never a tablet. The web uses the shared Tailwind variants `frame:` (≥ 768), `desktop:` (≥ 1024) and `wide:` (≥ 1440); Glass never uses Cinematic's `tablet:` (600) or `cinema:` (1920) variants (§2.8).
- **Token names** are dotted (`color.iris600`) and are the keys of `design/tokens/glass.json`. CSS variables use dashes (`--mm-color-iris600`, declared under `[data-skin="glass"]`), the Tailwind 4 `@theme` name drops the `mm` prefix (`--color-iris600`, mapped to `var(--mm-color-iris600)` in the shared `frontend/src/skins/theme.generated.css`), and Flutter fields are camelCase on `GlassTokens extends ThemeExtension<GlassTokens>` (`colorIris600`). §2.8 and §3.7 list every key with identical values in all three.
- **Event names** (haptics and sounds) are the dotted names of `design/contract.json` (`toggle.on`, `sheet.detent`, `download.done`, `streak.milestone`, `autoscroll.step`). The enum is the union of both skins' events; §5 maps every name to a Glass pattern (or to none) and §6 maps the ones that sound.
- **Contrast** ratios are WCAG 2.x relative-luminance ratios, computed for this document, against `#000000` unless stated. `design/check-contrast.mjs` re-checks every pair in CI (§15.8).
- **Inventory coverage** lines cite the row IDs of `inventory/web.md` (letters and numbers such as `LB15`) and `inventory/mobile.md` (screen IDs such as `S09`), so nothing on the checklist is dropped. Coverage lines cite inventory sections (for example `mobile §6a`, `web §12.2`) by their own numbering; every other `§` refers to this file unless a file name precedes it.

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
| `onGlass` | `#F2F2F7` | n/a | ≥ 5.14 over a pure white page with the legibility dim (§2.1.7) | Every glyph and label drawn on glass |
| `onTint` | `#FFFFFF` | n/a | 5.58 on tinted glass over black, 4.61 over a white page | Labels on the one tinted action |
| `fill1` | `rgba(120,120,128,0.36)` | | | Slider track on black, toggle track off |
| `fill2` | `rgba(120,120,128,0.30)` | | | Chip at rest, stepper well |
| `fill3` | `rgba(118,118,128,0.22)` | | | Search well on black, segmented track |
| `fill4` | `rgba(118,118,128,0.16)` | | | Hover wash on rows |
| `separator` | `rgba(84,84,96,0.55)` | | | Hairlines on glass and slabs, drawn 0.5 px |
| `separatorOpaque` | `g300` `#2D2D35` | | | Hairlines on black |

#### 2.1.3 The one accent: Iris

One violet accent, used as a **tint** (on the single primary action per screen, on selection droplets, on progress fill) and as **accent text/iconography** on black. It is never a flat fill on large areas. Iris is the **action light** (§2.1.9): AI output uses the machine light and people use bloom.

| Token | Hex | vs `#000` | White on it | Black on it | Role |
|---|---|---|---|---|---|
| `iris100` | `#E4DFFF` | 16.30 | 1.29 | 16.30 | Specular tip on tinted glass |
| `iris200` | `#D0C8FF` | 13.39 | 1.57 | 13.39 | Pressed accent text |
| `iris300` | `#BCB0FF` | 10.79 | 1.95 | 10.79 | Focus ring, accent text on glass |
| `iris400` | `#A99BFF` | 8.82 | 2.38 | 8.82 | Accent text and icons on black, links, "new" badges, active tab glyph |
| `iris500` | `#8F7EFF` | 6.60 | 3.18 | 6.60 | Progress fill, slider fill, selection ring |
| `iris600` | `#7563F2` | 4.82 | 4.35 | 4.82 | Tint colour of the tinted glass (applied at 86 % over the legibility dim) |
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
| `bloom` | `#FF9ED8` | 11.13 | 9.83 | 11.13 | People light: reactions, letters, friends' activity and presence (§2.1.9) |
| `machine` | `#5CE1E6` | 13.37 | 11.80 | 13.37 | Machine light: everything the external AI produced (§2.1.9) |
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
| `dimModal` | `rgba(0,0,0,0.48)` | Behind alerts, the command palette, the stack overview and full-height sheets |
| `dimContext` | `rgba(0,0,0,0.55)` + backdrop blur 12 | Behind a lifted context preview |
| `dimClear` | `rgba(0,0,0,0.35)` | Under clear glass on bright media (hero spotlight, image viewer), added only when the media's `Lb > 0.45` |
| `edgeSoft` | A **plateau and a fade**: `rgba(0,0,0,0.72)` from the screen edge to the far edge of the bar group (top: safe-top + 52 for the nav row, extended to safe-top + 104 while a toast shows; bottom: safe-bottom + 85 for the dock and orb, + 56 while the accessory shows), then a 24 px linear fade to transparent; backdrop blur 6 | Under every floating bar group, one per edge, so every label on a bar sits over the 0.72 plateau |
| `edgeHard` | `rgba(0,0,0,0.92)` + 0.5 px `separator` | Under pinned section headers |
| `dimLegibility` | `rgba(0,0,0, clamp(0.22 + 0.42 × Lb, 0.22, 0.64))` | Inside **every** glass surface, between the backdrop sample and the glass fill (all tiers, all variants except `solid*`) |

**The legibility floor (adaptive dim).** Glass shows what is behind it, so a label on glass over a white manhwa page would fail. Every glass surface carries the `dimLegibility` layer whose alpha follows `Lb`, the relative luminance (0 to 1) of what is directly behind that surface:

`dim = clamp(0.22 + 0.42 × Lb, 0.22, 0.64)`

- At `Lb = 1` (a pure white page) the dim is 0.64; a dock label (`onGlass` `#F2F2F7`, 11 px, weight 600, `GRAD` 40) over white composites to about `#666666` under the T3 fill (6 % white) and measures **5.14:1**; with the `edgeSoft` scrim under a bar group the composite darkens further. Over black (`Lb` ≈ 0) the dim stays at 0.22, so glass still reads as glass.
- The tinted action (`glassTinted`, `iris600` at 86 %) over a white page at dim 0.64 composites to `#7262DD`, and white on it measures **4.66:1**; over black it measures **5.58:1**.
- **Where `Lb` comes from** (never a GPU read-back; always data the app already has):

| Surface | `Lb` source |
|---|---|
| Dock, search orb, accessory, nav row, toasts and the catalogue "Top" capsule on ordinary screens (bars over scrolling content) | A real backdrop estimate: `max(field term, lItems)`, where the field term is the owning cover palette's `l` (§2.1.8) × the field opacity + 0.02, and `lItems` is the largest `palette.l` among the list items whose rects currently intersect the bar's rect (the list knows its item rects; covers carry `palette.l`), recomputed on scroll at most every 100 ms and held during flings faster than 3000 px/s. The edge plateau under the bar (`edgeSoft`, above) is what guarantees the floor; the estimate only thickens the glass further over bright covers |
| Sidebar, menus, sheets on ordinary screens | The field term alone (nothing scrolls under the sidebar, whose content column starts at 304 px; menus and sheets sit over their own dim) |
| Home hero controls (`glassClear` over the spotlight card and its enlargement) | The spotlight cover palette's `l` |
| Series detail band (nav row inside the sheet, the glass group over the band) | The series cover palette's `l` |
| Image viewer chrome | The viewed image's palette `l` (cover palette, or the page sample for page images) |
| Manga reader top chrome | The current page sample's `lTop` (§2.1.8) |
| Manga reader bottom capsule, minimised pill, accessory | The current page sample's `lBottom` |
| Novel reader chrome | The paper's own luminance (fixed per paper, §8.15.1) |
| Anything whose backdrop is unknown (first frame, a palette not yet loaded) | `Lb = 0.5` |

- **Motion.** When `Lb` changes, the dim animates over `dimShift` (400 ms `{bezier [0.2, 0, 0, 1]}`), together with the label grade (§3.5), so chrome sliding from a dark panel onto a white one darkens smoothly and the labels thicken without reflow. During a reader fling faster than 3000 px/s the reader's `Lb` updates are held until the strip slows (the engine's `scrollVelocity`, §15.4).
- **Solid tiers** (`solid1`, `solid2`, Reduce Transparency, Solid glass) have no dim: they are opaque.

- **Bars over scrolling content (worked case).** A white cover (`#FFFFFF`) under a dock label, with the backdrop estimate at its lowest (dim 0.22): the `edgeSoft` plateau takes white to `#474747`, the dim to `#373737`, the T3 fill to `#444444`, and `onGlass` measures **8.8:1**. With the estimate working (a white cover's `palette.l` ≈ 0.9, dim 0.60) the composite is `#2A2A2A` and the label measures **12.8:1**. Without the plateau the same label at dim 0.22 would measure about 1.5:1, which is why the plateau, not the estimate, is the floor.

`design/check-contrast.mjs` (§15.8) asserts the three worst cases above on every build: `onGlass` on T3 over `#FFFFFF` at dim 0.64 ≥ 4.5:1 (the reader's case); `onGlass` on T3 over `#FFFFFF` under the 0.72 `edgeSoft` plateau at the minimum dim 0.22 ≥ 4.5:1 (the dock's case on any list); and `onTint` on `glassTinted` over `#FFFFFF` at dim 0.64 ≥ 4.5:1.

#### 2.1.8 Ambient field and colour extraction

Glass over pure `#000000` has nothing to bend. Meniscus therefore keeps colour under the chrome on every screen through an **ambient field** (z 0.5, behind content).

**The field.** Three soft blobs, circles of diameter 70 % of the viewport width, blurred 120 px (phone) or 180 px (desktop), placed at (18 %, 8 %), (78 %, 14 %) and (46 %, 36 %) of the viewport, opacity 18 to 28 % per the source. Everything below 60 % of the viewport height fades to `g25` and then `#000000`, so the lower screen stays true black for AMOLED. The blobs drift on the `drift` spring toward new random targets within ±6 % of their anchors every 14 s, so the field breathes without looping. Reduce Motion freezes them. Implementation: three radial gradients on one fixed element (web) or one `CustomPaint` with `RadialGradient` shaders (Flutter); the blur token describes the look, no live blur filter runs.

**Sources, by screen.**

| Screen | Field source | Blob opacity |
|---|---|---|
| Home | The focused hero spotlight's cover palette; changing the spotlight runs **Light follows the story** (below) | 26 % |
| Series detail, book page, recap deck | That series' cover palette | 28 % |
| Library, Sources, Search, Updates, History, Bookmarks, Collections, Downloads | The cover palette of the first visible item; a new palette is taken only when the list stops scrolling for 600 ms | 18 % |
| Profile picker | The focused profile's mood colour, then the chosen profile's colours during **Step into the light** (§8.5) | 30 % |
| Settings, You, admin, auth, onboarding | The active profile's mood colour (§2.1.6); auth, setup and onboarding use the brand aurora `#8FD8FF`, `#A99BFF`, `#FF9ED8` | 20 % |
| Circle | The bloom aurora: `#FF9ED8` plus the two most recent friends' mood colours | 20 % |
| Statistics, Wrapped | The year's top three covers' palettes (Wrapped: each card's own hero cover) | 24 % |
| Manga reader chrome | The current page sample (page-tinted chrome, §9.4.4) | tint only, no blobs |
| Manga reader desktop gutters | The current page sample's top and bottom colours as page-lit pools (§8.14.11) | 10 % |
| Novel reader, Glass paper | The book's cover palette, in the top 30 % of the screen only (§8.15.1) | 10 % |
| Novel reader, the other six papers | None: the paper is the backdrop | none |

A mature series can own the field only for a profile whose 18+ gate is open, because the field only ever uses art already on screen.

**Light follows the story.** Whenever the art that owns the field changes (the Home spotlight pages, a hover on a picker orb, a new series sheet), the three blobs slide their colours to the new palette over `tintShift` (900 ms `{bezier [0.2, 0, 0, 1]}`), and every glass rim on screen follows with the same curve: the rim tint (the palette's first colour at OKLCH L 0.86, C ≤ 0.08) is mixed into the specular gradient at 18 %, and the dock's selection droplet takes the same tint at 12 %. Reduce Motion: the colours swap in one 200 ms cross-fade.

**Extraction.**

1. **Cover palettes: server first** (`stack-decision.md` §2.6). In the same Pillow pass that computes Cinematic's `ambient {duo, tint, ink}` next to cover resizing, the backend decodes the `w=96` cover, runs `Image.quantize(colors=6, method=Image.Quantize.MEDIANCUT)`, converts the six colours to OKLCH, discards any with `L < 0.12`, `L > 0.94` or `C < 0.025` (unless all six would go, in which case it keeps the two most populous), ranks the rest by `population × (0.5 + C)`, and ships the top three plus the cover's mean relative luminance as `palette: {a: ["#rrggbb", "#rrggbb", "#rrggbb"], l: 0.41}` on `SourceSeries`, `FollowedSeries`, continue-reading items, `GET /home` items and `WorldItem`. It is stored in a `cover_palette` row keyed by `(source_id, series_identity)` with a 30-day TTL (§15.5).
2. **Cover fallback on the client** (a payload without `palette`, for example a downloaded series opened offline before its first sync): web decodes a 32 × 32 copy with `fast-average-color` 9.6.0 (`algorithm: "dominant"`) for `a[0]` and derives `a[1]`, `a[2]` by rotating the hue ±30° at the same L and C; Flutter decodes a 64 px `ResizeImage` and runs `QuantizerCelebi().quantize(pixels, 16)` from `material_color_utilities` (declared `any`, so pub takes the version the Flutter SDK itself pins, §15.11) in `compute()`, then applies the same discard-and-rank rule itself (it never calls `Score.score`, whose fallback returns Google blue `#4285F4` for a colourless image). `fast-average-color` is the only colour library on the web; `colorthief` is not used. Results are cached per image URL for the session.
3. **Page samples (reader): client side**, because pages are often offline downloads and the server cannot compute them at manifest time. The reader engine owns one shared sampler per client (it is skin-neutral and also feeds Cinematic's page tint): web `frontend/src/features/reader/page-tint.worker.ts` draws each decoded page into a 16 × 16 `OffscreenCanvas` inside a Web Worker (the engine transfers an `ImageBitmap`); Flutter `mobile/lib/features/reader/engine/page_tint.dart` decodes a 64 px `ResizeImage` and runs `QuantizerCelebi` in `compute()`. Both return one `PageSample`:

   `{ tint: "#rrggbb" | null, top: "#rrggbb", bottom: "#rrggbb", lTop: 0–1, lMid: 0–1, lBottom: 0–1 }`

   where `tint` is the highest-population colour with OKLCH `L ≥ 0.18` and `C ≥ 0.035` (null for a greyscale page), `top` and `bottom` are the mean colours of the top and bottom quarter of the page, and `l*` are the relative luminances of the top quarter, the middle half and the bottom quarter. Samples are cached per page URL (LRU of 500 entries), taken for the page on the reading line (38 % down the viewport in the strip; the visible page in paged modes) at most every 600 ms while scrolling and once on settle. A greyscale page keeps the previous `tint`; after 6 greyscale pages in a row the tint falls back to the series cover palette's `a[0]`. When the manifest already carries `pages[].tint` from an earlier read (the shared cache Cinematic defined, filled by `POST /reader/page-tints`), it is used for the first paint and replaced by the local sample on decode; the engine posts its samples on chapter exit through the same endpoint.
4. **Clamping** (in OKLCH, so the field never glares or muddies): field blobs L 0.55 to 0.78, C 0.06 to 0.16, hue kept. Near-greys (C < 0.03 before clamping) are replaced by the profile's mood colour. The three blobs take `a[0]`, `a[1]`, `a[2]`; with fewer than three, the first is reused at 60 % size.
5. **Transitions.** Field colours never jump: each blob cross-fades its colour over `tintShift`. Page-tinted chrome uses the same curve (§9.4.4).

#### 2.1.9 One light per meaning

Colour in Meniscus is light, and each colour of light has exactly one job. A reader who learns the four lights can tell at a glance who or what made a thing.

| Light | Token | Hex | vs `#000` | Its one job | Never |
|---|---|---|---|---|---|
| **Action light** | `iris400` (text, glyphs), `iris600` (tint) | `#A99BFF` / `#7563F2` | 8.82 / 4.82 | The one tinted action per screen, selection droplets, progress, focus, links, unread | On AI-written text or on people |
| **Machine light** | `machine` | `#5CE1E6` | 13.37 | Everything the external AI produced: the sparkle glyph before an AI rail title and before every `why` line, the Ask box rim while active or thinking, the thinking orbit (§7.38), the recap deck's card rims and eyebrow (§9.1.3), the "Previously · 20 s" pill glyph, the recap footnote glyph | On a human-made thing, on an action button (the Ask button stays the iris action), for status |
| **People light** | `bloom` | `#FF9ED8` | 11.13 | Everything a person in the Circle did: friend orb rings, the presence arc's live rings, reactions (your chosen reaction in Fill `bloom`), letters ("From Aarav"), shared-collection rims, the Circle ambient field | For status, warnings or AI |
| **Warmth** | `streak` / `streakCore` | `#FF8A3D` / `#FFD166` | 8.95 / 14.56 | The streak flame, milestone numerals, the goal ring, record sparks | For errors |

- `machineWash` `rgba(92,225,230,0.14)` is the machine light's only fill (behind the sparkle badge and the thinking orbit's ellipse); `machineRim` `rgba(92,225,230,0.45)` is its 0.5 px rim on AI cards and recap cards. `label1` on `machineWash` over black measures 15.2:1.
- `bloomWash` `rgba(255,158,216,0.14)` and `bloomRim` `rgba(255,158,216,0.45)` do the same for people.
- An AI card that shows a series recommended by a friend carries both: the friend's bloom chip ("From Aarav") and the machine sparkle only on the AI-written `why` line.
- Semantic colours (§2.1.4) are not lights: they mark states (saved, stale, failed, 18+) and appear as glyph colour, a 2 px rim or an 18 % badge fill.

### 2.2 Spacing

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
| `s13` | 85 | Bottom content inset above the dock (dock 64 + `dockInset` 21), so the last row clears the dock exactly |
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

Scroll insets: every scroll view runs edge to edge under the floating chrome and uses content insets, never padding on the viewport, so glass always has content to bend. Top inset = safe area + 60 (floating nav row) on phone, 24 on desktop; bottom inset = safe area + `s13` (85), + 56 when the bottom accessory is visible. `scroll-padding-block` on web equals these insets so keyboard focus never lands under a bar (WCAG 2.4.11).

### 2.3 Radius and shape

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

### 2.4 Materials and elevation

#### 2.4.1 The layer stack and mass classes

| z | Layer | What lives there | Treatment |
|---|---|---|---|
| 0 | Canvas | Page background | `#000000` |
| 0.5 | Ambient field | Cover-derived colour blobs | §2.1.8 |
| 1 | Content | Covers, posters, rows, cards, reader pages, prose | Black and `surface1` to `surface3` slabs, `materialThin` to `materialThick` for side panels. **Never Liquid Glass** |
| 2 | Scroll edge | Soft edge under each floating bar group; hard edge under pinned headers | `edgeSoft` / `edgeHard` |
| 3 | Controls | Floating nav buttons, title capsule, dock, search orb, bottom accessory, reader capsules, floating action capsules | T2 (`glassThin`, ≤ 56 px controls) and T3 (`glassRegular`, bars) |
| 4 | Overlays | Menus, popovers, partial sheets, the lifted context preview, the scrub lens, the stack overview | T4 (`glassThick`); full-height sheets `solid1` |
| 5 | Interruptions | Alerts, the command palette, confirm sheets | T4 + `dimModal` |
| 6 | HUD | Toasts, the brightness and speed HUDs, the bookmark notice | T2 capsule |

**Every material has a mass class, and a surface's springs and glass tier come from its class.** Small glass (chips, nav buttons, the tab droplet) is light and quick; bars are medium; sheets, panels and pages are heavy. The spring table (§4.2) encodes this: a sheet uses `sheet` (480 ms), a chip `snappy` (400 ms), a droplet `tab` (450 ms, more bounce because it is liquid). Nobody picks a duration or a thickness by feel; they pick the object's class.

| Mass class | Objects | Glass tier (§2.4.3) | Press growth | Release spring | Move spring |
|---|---|---|---|---|---|
| Feather | Tab droplet, scrub thumb, toggle knob, slider thumb, chips and segmented thumbs **while dragged**, the OCR hit lens, the scrub magnifier stem | T1 Film | +17 px on the longest side, capped at 0.35 × the side | `press` | `track`, then `tab` or `lens` |
| Light | Chips at rest (content fills, not glass), icon buttons, nav buttons, badges, keycaps, toasts, the search orb, HUDs | T2 Pane | +17 px capped at 0.35 × side | `press` | `snappy` |
| Medium | Buttons, dock, accessory, reader capsules, the desktop sidebar, the minimised pill, cards and posters (content: scale 1.04, no glass) | T3 Slab | +12 px on the longest side (cards and posters: scale 1.04) | `press` | `morph` / `minimize` |
| Heavy | Sheets, menus, panels, alerts, the command palette, the hero card, the scrub magnifier lens, the stack overview cards | T4 Block | none (they lift, they do not swell) | n/a | `sheet`, `sheetSnap`, `morph`, `smooth` |
| Massive | The listen full player, the Wrapped frame, the image viewer frame, the splash lens, the skin-switch melt; pages (routes) and the reader strip (content, no glass) | T5 Monolith | none | n/a | `page`, `zoom`, `settle`, `smooth` |

**Glass stays out of scrolling content** (`stack-decision.md` §4 risk 5). Three rules decide where real glass (a live backdrop read, refraction) may be drawn:

1. **Never glass: anything repeated per item, and anything inside the reading surface.** Tiles, posters, rows, cards, chips inside a scrolling chip row, row action pills, per-item buttons (a poster's follow bell, a tile's play orb), chart readouts and marks, health beads, and anything inside the manga strip or the novel column use the component's **content twin**: the same shape and size, the tier's rim (0.5 px, `rgba(255,255,255,0.22)`) and inner light, over a fill of `rgba(19,19,23,0.62)` (the `materialRegular` colour with no blur) or `fill2` for chips, and no backdrop read, no displacement, no dim. Dialogue boxes, the hit lens and the guided-view lens are not inside the strip: they are drawn in **one overlay layer above the strip**, positioned from the engine's page coordinates (§8.14.9, §15.4).
2. **Allowed in scrolling page content: at most two single page-level controls per screen** that belong to the page rather than to an item: the screen's lit action and one secondary group (for example series detail's split "Continue" and its row of secondary buttons; Login's "Sign in"; the Ask button). They count toward the budget below and run at `GlassQuality.standard` on Flutter, because their backdrop moves every frame. The one other exception is **transient glass**: a slider thumb, switch knob or segmented thumb turns to glass only while a finger drags it (scrolling is frozen by the drag, and only one exists at a time), and returns to its content look on release.
3. **Chrome is glass:** floating bars, pinned toolbars, sheets, menus, popovers, alerts, HUDs, reader capsules, overlays and the full-screen state lens of §7.24 (it sits in a non-scrolling state layer over the ambient field even when the list behind it can still be pulled).

**Budget per screen** (checked live by the Diagnostics row "Glass layers on screen", §8.25.12): the web keeps at most **six** live `backdrop-filter` surfaces; each floating bar group (the nav row's leading button, title capsule and trailing group; the dock with its search orb; a reader capsule group) is **one** element whose backdrop is masked to its shapes with an SVG `mask-image`, so a bar group counts once. Flutter keeps every glass surface of a screen in one `BackdropGroup` and at most **eight** members. The per-frame counts are in §15.7. These are budget rules applied identically on every device, never a device tier (the owner ruled out low-end fallbacks).

#### 2.4.2 Glass variants

All glass is **regular** (adaptive, frosted, with the legibility dim) except over media, where **clear** is allowed. Variants never mix inside one container. The named variants below are the tier recipes of §2.4.3 plus a finish; every component in §7 names its variant.

| Token | Tier | Fill | Dim | Blur (CSS radius = Flutter sigma) | Saturate | Rim (0.5 px) | Specular `S` | Shadow | Bezel / thickness |
|---|---|---|---|---|---|---|---|---|---|
| `glassFilm` (transient Feather glass) | T1 | `rgba(255,255,255,0.03)` | `dimLegibility` | 2 | 1.4 | `rgba(255,255,255,0.26)` | 0.55 | `0 2px 8px rgba(0,0,0,0.35)` | 6 / 12 |
| `glassThin` (controls ≤ 56 px) | T2 | `rgba(255,255,255,0.07)` | `dimLegibility` | 8 | 1.8 | `rgba(255,255,255,0.22)` | 0.42 | `0 6px 20px rgba(0,0,0,0.45)` | 10 / 20 |
| `glassRegular` (dock, accessory, reader capsules, sidebar, minimised pill) | T3 | `rgba(255,255,255,0.06)` | `dimLegibility` | 10 | 1.8 | `rgba(255,255,255,0.20)` | 0.40 | `0 8px 24px rgba(0,0,0,0.50)` | 12 / 24 |
| `glassThick` (menus, partial sheets, alerts, lifted previews, palette, scrub lens) | T4 | `rgba(28,28,34,0.52)` | `dimLegibility` | 22 | 1.8 | `rgba(255,255,255,0.16)` | 0.30 | `0 24px 64px rgba(0,0,0,0.60)` | 18 / 40 |
| `glassMonolith` (listen full player, Wrapped frame, image viewer frame, splash lens) | T5 | `rgba(22,22,28,0.60)` | `dimLegibility` | 32 | 1.7 | `rgba(255,255,255,0.14)` | 0.26 | `0 40px 96px rgba(0,0,0,0.66)` | 24 / 56 |
| `glassClear` (controls over the hero spotlight, the series band and the image viewer) | the host tier | `rgba(255,255,255,0.02)` | `dimClear` beneath the media region when the media's `Lb > 0.45`, never inside the glass | 1 | 1.4 | `rgba(255,255,255,0.28)` | 0.50 | none | the host tier's |
| `glassTinted` (the one primary action per screen; "lit") | the host tier (T2 or T3) | `iris600` at 86 % | `dimLegibility` | 8 | 1.6 | `rgba(255,255,255,0.30)` | `iris100` at 60 % | `0 8px 24px rgba(117,99,242,0.35)` + the caustic (§2.4.4) | 10 / 20 |
| `solid1` (full-height sheets; Reduce Transparency everywhere) | any | `#1C1C22` | none | 0 | 1 | `rgba(255,255,255,0.10)` 1 px | none | as the variant it replaces | none |
| `solid2` (large solid surfaces under Reduce Transparency) | any | `#26262E` | none | 0 | 1 | `rgba(255,255,255,0.10)` 1 px | none | as the variant it replaces | none |
| `frosted` (a renderer-capability rule: Safari and Firefox cannot run SVG displacement inside `backdrop-filter`, on every device) | any | as the variant it replaces | as it replaces | +6 over the variant | 1.8 | same | same | same | none (no displacement, no dispersion) |

Content-layer materials (never Liquid Glass; used for side panels and slabs over the ambient field):

| Token | Fill | Blur |
|---|---|---|
| `materialThin` | `rgba(19,19,23,0.40)` | 12 |
| `materialRegular` | `rgba(19,19,23,0.62)` | 24 |
| `materialThick` | `rgba(19,19,23,0.84)` | 36 |

Material behaviour (the physics of glass):

1. **Materialise, do not fade.** Glass enters by ramping its refraction (`lensing` 0 → 1) over `materialize` (250 ms) while its opacity goes 0 → 1 over the first 120 ms; it leaves by the reverse over `dematerialize` (350 ms). A glass object never pops in at full refraction.
2. **Thickness follows size.** A free-sized glass object takes the tier of its shorter side (§2.4.3). When glass grows (a button blooming into a menu, the accessory expanding into the full player, the Speed tile growing into the speed dial), every tier parameter (bezel, displacement, blur, fill, specular, shadow, dispersion) interpolates from the start tier to the end tier along the same spring as its size, so it visibly thickens; text on it changes `ROND` with the tier (§3.5).
3. **Press lights from inside.** A radial glow (`rgba(255,255,255,0.16)`, radius 140 px) is centred on the touch point: `glowIn` 150 ms, `glowOut` 60 ms. On `glassTinted` the glow is `rgba(188,176,255,0.22)` and the caustic brightens (§2.4.4). Glass never dims on press.
4. **Stretch toward the drag.** While a pressed glass control is dragged, it stretches up to 6 % along the drag axis (`scale = 1 + 0.06 × clamp(dx / width, −1, 1)`) and compresses the other axis to `1 / √scale` so its area looks conserved, following the `track` spring.
5. **Light has a direction.** The specular rim is brightest at 135° (top-left). On phones it follows the gyroscope (`sensors_plus` 7.1.0, rotation rate integrated and clamped to ±25°) and on desktop the pointer position across the viewport (`angle = 135° + 25° × (pointerX / viewportWidth − 0.5) × 2`, one `pointermove` listener on `window`, one write per animation frame). Reduce Motion and the "Light follows the device" switch (off) pin it at 135°.
6. **Adaptive thickness over bright art.** Every glass surface reads the luminance of what is behind it and raises its `dimLegibility` (§2.1.7): the glass thickens exactly where it needs to, on the reader over white pages, on the Home hero over a pale cover, on the series band and in the image viewer.
7. **No glass on glass.** Anything drawn on glass uses fills and `onGlass` text. Sibling glass objects share one container so they sample the same backdrop and can merge (the metaball join between the dock and the search orb during a drag, the accessory joining the minimised dock). A third stacked glass layer forces the lowest one to `solid1` for as long as the stack lasts.
8. **One lit object per screen.** Exactly one `glassTinted` object is visible per screen; a sheet or alert may carry its own, and while it is up the screen's lit object drops to `glassThin` and its caustic fades over 180 ms.

#### 2.4.3 The thickness scale (T1 to T5)

Size changes the material: a bigger object reads as thicker, with deeper shadow, stronger lensing and softer scatter. Meniscus makes "thickness follows size" (§2.4.2 rule 2) a numeric scale tied to the mass classes. Every glass component names its tier. A free-sized glass object (a context menu, a sheet, a popover, a window) **snaps by its shorter side**: `< 36 px → T1`, `36–56 → T2`, `57–96 → T3`, `97–400 → T4`, `> 400 → T5`. Bars keep a fixed tier whatever their length (the dock, the accessory, the reader capsules and the desktop sidebar are T3; toasts are T2).

| Token | Name | Mass class | Virtual thickness | Bezel (refraction band) | Max displacement | Backdrop blur | Saturate | Fill | Specular `S` | Drop shadow over content | Dispersion | `ROND` for text on it |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `glass.t1` | Film | Feather | 12 px | 6 px | 6 px | 2 px | 1.4 | `rgba(255,255,255,0.03)` | 0.55 | `0 2px 8px rgba(0,0,0,0.35)` | none | 20 |
| `glass.t2` | Pane | Light | 20 px | 10 px | 10 px | 8 px | 1.8 | `rgba(255,255,255,0.07)` | 0.42 | `0 6px 20px rgba(0,0,0,0.45)` | none | 40 |
| `glass.t3` | Slab | Medium | 24 px | 12 px | 12 px | 10 px | 1.8 | `rgba(255,255,255,0.06)` | 0.40 | `0 8px 24px rgba(0,0,0,0.50)` | none | 60 |
| `glass.t4` | Block | Heavy | 40 px | 18 px | 18 px | 22 px | 1.8 | `rgba(28,28,34,0.52)` | 0.30 | `0 24px 64px rgba(0,0,0,0.60)` | 0.6 px | 80 |
| `glass.t5` | Monolith | Massive | 56 px | 24 px | 22 px | 32 px | 1.7 | `rgba(22,22,28,0.60)` | 0.26 | `0 40px 96px rgba(0,0,0,0.66)` | 1.2 px | 100 |

- **Specular rim** (every tier): `linear-gradient(var(--mm-light-angle), rgba(255,255,255,S) 0%, rgba(255,255,255,0.06) 35%, rgba(255,255,255,0.02) 65%, rgba(255,255,255,S × 0.55) 100%)`, drawn 0.5 px (1 physical px on DPR ≥ 2), with the field's rim tint mixed in at 18 % (§2.1.8).
- **Inner light** (T2 and up): a 1 px inset line along the lit edge `inset 1px 1px 0 rgba(255,255,255,S × 0.35)` and a 1 px inset shade along the far edge `inset -1px -1px 0 rgba(0,0,0,0.35)`, which is what makes a pane look thick on black.
- **Dispersion** (T4 and T5 only): the refracted backdrop splits into three channels offset 0 / 0.6 / 1.2 px (T4) or 0 / 1.2 / 2.4 px (T5) along the displacement vector, so a menu's rim over a cover shows a thin red and blue fringe (`rgba(255,106,136,0.35)`, `rgba(106,184,255,0.35)`).
- **Shadow** is drawn only when content is under the glass; over empty `#000000` a shadow is invisible, so separation there comes from the rim and the inner light.
- **Web mapping** (tier A "liquid", Chromium): the SVG `feDisplacementMap` scale is the max displacement, the displacement map's bezel band is the bezel width (squircle profile, Snell refraction with `n = 1.5`, §15.2), `backdrop-filter: url(#lens-{w}x{h}) blur(Bpx) saturate(S)`; dispersion is three displacement passes at scale × 1.00 / 1.02 / 1.04 isolated by `feColorMatrix` and recombined with `feBlend mode="screen"`. Tier B "frosted" (Safari, Firefox) keeps blur, saturate, fill, dim, rim, inner light, caustic and glow and drops displacement and dispersion.
- **Flutter mapping** (`liquid_glass_widgets` 1.7.2 through `SkinGlass`): `LiquidGlassSettings(thickness: <virtual thickness>, blur: <blur>, saturation: <saturate>, glassColor: <fill>, lightIntensity: S, refractiveIndex: 1.2 (the 1.7.2 default), chromaticAberration: 0 for T1–T3, 0.35 for T4, 0.5 for T5, lightAngle: <live angle in radians>)`; `GlassQuality.premium` on chrome; `standard` only for the two page-level controls allowed in scrolling content and for transient glass (a dragged thumb or knob) inside a scroll view (§2.4.1). This is a budget rule applied identically on every device, not a device tier.
- **Calibration knobs.** Web `n` (1.5) and Flutter `refractiveIndex` (1.2) and `thickness` are not the same physical model; they are tuned side by side on the checkerboard calibration page (§15.8) until a 44 px T2 button and a 240 px T4 menu bend the checkerboard by the same number of squares on both clients. The table values are the starting point; a calibration change edits `design/tokens/glass.json` only.

#### 2.4.4 Light effects

- **Caustic (the lit action).** The one `glassTinted` object per screen throws light through itself onto the content beneath: an ellipse 120 % × 70 % of the object's size, offset 8 px along the light direction (down and right at 135°), filled with `iris500` `#8F7EFF` at 14 % alpha, blurred 18 px, blend `screen`. It exists only when content (a cover, a page, a card) is under the object, never over empty black, and it brightens to 22 % while the object is pressed (`glowIn` 150 ms, `glowOut` 60 ms). Web: a `::before` on the button's wrapper with `mix-blend-mode: screen`, placed below the glass; Flutter: a `CustomPaint` behind the button with `BlendMode.screen`. It follows the live light angle. Reduce Transparency and Solid glass: no caustic.
- **Follow ring.** Adding a series to the library from its detail sheet sends a caustic ring across the series band: a ring centred on the "Add to library" button, radius from 0 to the band's far corner, stroke 2 px growing to 24 px, `iris300` at 30 % fading to 0, blurred 6 px, blend `screen`, over 700 ms `{bezier [0.2, 0, 0, 1]}`, clipped to the band. It plays with `follow.add`. Reduce Motion: no ring (the button's selected state is the feedback).
- **Specular sweep.** When a glass object materialises and when the lit action becomes enabled, a 40 px band of `rgba(255,255,255,0.18)` crosses it along the light angle from the lit corner to the far corner in 520 ms `{bezier [0.2, 0, 0, 1]}`, masked to the shape. At most one sweep plays on screen at a time; later requests within 300 ms are dropped. Reduce Motion: none.
- **Press glow**: §2.4.2 rule 3.
- **Lensing on arrival**: §2.4.2 rule 1.
- **Rain on glass** (only with the Rain soundscape playing, §9.4.2): 6 to 10 droplets run down the reader's glass capsules and the minimised pill, refracting the page behind them.

### 2.5 Blur

| Token | Radius | Use |
|---|---|---|
| `blurFilm` | 2 | `glassFilm` (T1) |
| `blurEdge` | 6 | Soft scroll edges |
| `blurThin` | 8 | `glassThin`, `glassTinted` |
| `blurRegular` | 10 | `glassRegular` |
| `blurContext` | 12 | `dimContext` backdrop behind a lifted preview |
| `blurThick` | 22 | `glassThick` (T4) |
| `blurMonolith` | 32 | `glassMonolith` (T5) |
| `blurRecede` | 8 | The page behind a sheet at the large detent (with scale 0.94) |
| `blurSwitch` | 40 | Skin-switch outgoing melt |
| `blurField` | 120 phone / 180 desktop | Ambient blobs |
| `blurReveal` | 12 → 0 | Heading letter reveal start blur |

Budget: at most **two stacked glass layers** anywhere (for example a menu over the dock). On Flutter every `BackdropFilter` on one screen joins one `BackdropGroup` (`BackdropFilter.grouped`) so they share a single backdrop read. Glass is never placed on items inside a scrolling list (§2.4.1 rule 1); the two page-level controls a scrolling page may carry run at `standard` (`glass-language.md` §6.2). Both are budget rules, the same on every device.

### 2.6 Borders, rims and focus

| Token | Value | Use |
|---|---|---|
| `rim` | 0.5 px, gradient from `specular` at 135° to `rgba(255,255,255,0.06)` at 35 % to `rgba(255,255,255,0.02)` at 65 % to `rgba(255,255,255,0.20)` at 100 % | Every glass surface |
| `hairline` | 0.5 px `separator` | Row separators, inset 16 px from the leading edge (60 px when the row has a leading icon tile) |
| `slabBorder` | 1 px `rgba(255,255,255,0.06)` | Cards and grouped lists on black |
| `focusRing` | Two-tone: a 2 px `#000000` inner ring directly around the element, then a 2 px solid `iris300` ring outside it (4 px total), plus a 6 px outer glow `rgba(188,176,255,0.28)` | Keyboard focus (`:focus-visible`; Flutter `FocusHighlightMode.traditional`) on every focusable element; follows the element's radius |
| `selectedRing` | 2 px `iris500` inset 0 | Selected poster, selected paper swatch, selected voice |
| `errorRing` | 1.5 px `danger` | Invalid input |
| `hcBorder` | 1 px `rgba(255,255,255,0.55)` | Increase Contrast: added to every glass and slab |

The focus ring is two-tone because it is drawn on whatever is behind the control, including a white manga page under reader chrome, a pale cover under the hero controls and the image viewer: `iris300` alone measures 1.95:1 on `#FFFFFF`. With the black inner ring, one of the two rings always clears 3:1 against its surroundings: `iris300` is 10.79:1 against black and the black ring is 21:1 against white. Web: `outline: 2px solid var(--mm-color-iris300); outline-offset: 2px; box-shadow: 0 0 0 2px #000, 0 0 0 6px rgba(188,176,255,0.28)` (the black shadow fills the offset gap). Flutter: `FocusRingSpec` paints both strokes. Rails pad 8 px vertically so rings are never clipped.

### 2.7 Iconography

**Set: Phosphor** on both platforms (`@phosphor-icons/react` 2.1.10 and `phosphor_flutter` 2.1.0, MIT, 1,512 icons in 6 weights at exact parity).

| Context | Weight | Size (visual / hit) |
|---|---|---|
| Default on glass and black | **Regular** (1.5 px stroke at 24 px) | 22 / 44 (48 on Android) |
| Active tab, selected state | **Duotone** at rest (secondary layer at 0.2), morphing to **Fill** on press | 22 / 44 |
| Inline in rows and chips | Regular | 20 / row height |
| Ornamental (empty states, onboarding, Wrapped) | **Light** | 48 to 64 |
| Dense meta (download marks, badges) | Bold | 14 to 16 |
| Reactions (§9.3.2) | **Fill**, in `bloom` when it is your reaction, `label2` otherwise | 24 in the strip, 36 in the picker bubbles |

**Core map** (Phosphor names): Home `house-simple`, Library `books`, Sources `globe-hemisphere-west`, You (the profile orb, never a glyph), search `magnifying-glass`, Updates `bell-simple`, Circle `users-three`, Stats `chart-bar`, For you `sparkle` (in `machine`), Dialogue search `bubble-search` (custom), Settings `gear-six`, Status `pulse`, back `caret-left` (the `strata` glyph when the depth indicator shows, §7.37), close `x`, more `dots-three`, share `export`, recommend `paper-plane-tilt`, bookmark `bookmark-simple`, favourite `star`, follow `plus` / following `check`, notify `bell-ringing`, download `cloud-arrow-down`, downloaded `droplet` (custom), pin `push-pin`, filter `funnel-simple`, sort `arrows-down-up`, select `check-circle`, delete `trash-simple`, edit `pencil-simple`, reader settings `sliders-horizontal`, type `text-aa`, contents `list-numbers`, listen `headphones`, play `play`, pause `pause`, previous chapter `skip-back`, next chapter `skip-forward`, cruise `flywheel` (custom), soundscape `waveform`, guided view `panel-focus` (custom), brightness `sun`, warmth `thermometer-simple`, offline `wifi-slash`, refresh `arrow-clockwise`, external `arrow-square-out`, flame `flame` (the streak flame itself is drawn, §9.2.2), AI unavailable `sparkle` with a slash (custom `sparkle-slash`), 18+ `age-gate` (custom).

**Custom glyphs**, drawn on Phosphor's 256 grid in Regular (16-unit stroke, round caps and joins), Duotone and Fill, exported as flattened SVG (web components under `frontend/src/skins/glass/icons/`) and one icon font built with `fantasticon` (npm, MIT, build-time only) as `GlassGlyphs` `IconData` for Flutter:

| Glyph | Geometry on the 256 grid | Use |
|---|---|---|
| `mm-mark` | The MM column: top M in the box x 72–184, y 32–120; gutter bar x 64–192, y 120–136; bottom M x 72–184, y 136–224; M strokes 22 units | Brand at icon sizes |
| `strip-scroll` | A 96 × 176 rounded rectangle (radius 16) at x 80, y 24 with two horizontal panel lines at y 80 and y 136, and a chevron-down (x 104–152, y 212–232) | Manga reader, strip mode |
| `panel-focus` | A 112 × 80 rectangle at x 72, y 88, inside four 32-unit corner brackets at x 40 / 216 and y 56 / 200 | Guided view |
| `bubble-search` | A speech bubble (ellipse rx 80 ry 60 centred 112, 104, tail to 72, 176) and a magnifier (circle r 28 at 176, 168; handle to 224, 216) | Dialogue search |
| `age-gate` | A 12-point seal (outer r 104, inner r 88) with "18" set in the glyph's stroke (numerals 72 units tall) | 18+ gate and badge |
| `voice-31` | Phosphor `user-sound` with a 64 × 64 stacked-card badge at x 168, y 168 | Voice picker |
| `droplet` | A teardrop: circle r 64 centred 128, 152, tangent lines meeting at a point 128, 32 | Pull to refresh, downloaded mark, splash |
| `flywheel` | A disc r 80 centred 128, 128 with a hub r 16 and six motion ticks (24 units long) around the rim at 60° steps | Cruise (auto-scroll) |
| `strata` | Four horizontal capsules 160 × 20 at y 56, 100, 144, 188, each 12 units narrower than the one below; lit bars are Fill, unlit bars Regular outline | Depth indicator on back buttons (§7.37) |
| `sparkle-slash` | Phosphor `sparkle` with a 16-unit diagonal slash from 48, 48 to 208, 208 | AI unavailable |

Icon motion follows physics too, and every icon animation is interruptible:

| Icon event | Motion |
|---|---|
| Press | Scale with its button; Duotone → Fill morph over the `press` spring (web: cross-fade the two weights over 120 ms; Flutter: `AnimatedSwitcher` with the spring) |
| Bell with new chapters | A pendulum: rotate about the top pivot, initial angular velocity 6 rad/s on the `tick` spring (a swing out, then a small counter-swing from the 4.6 % overshoot) |
| Bookmark saved | The flag drops 4 px and springs back on `tick`, Regular → Fill |
| Download complete | The arrow falls into the tray (translateY 0 → 6 px on `snappy`) and the tray fills with `success` |
| Refresh | Rotation follows pull distance 1:1 (360° per 100 px), then spins at 1 turn per 800 ms while loading |
| Chevrons in disclosure rows | Rotate 0 → 90° on `snappy` when expanded |
| Depth bars (`strata`) | Newly lit bars fill from left to right, 40 ms apart, on `tick` |
| Reactions | Scale 0.6 → 1 on `celebrate` with a 6-particle burst in `bloom` (§9.3.2) |

Reduce Motion: every icon event above is replaced by the end state with a 150 ms cross-fade.

### 2.8 Token name map: web, Tailwind and Flutter side by side

`design/build.mjs` (`stack-decision.md` §2.1) emits every key below three ways, with identical values:

- **Web CSS custom property**: `--mm-` + the key with dots turned into hyphens and camelCase into kebab-case, declared under `[data-skin="glass"]` in `frontend/src/skins/glass/tokens.generated.css`. Runtime values (the live light angle, each surface's dim and grade, the ambient colours `--amb-a1/2/3`, the page sample `--page-tint`, `--page-top`, `--page-bottom`) are registered with `@property` so they interpolate.
- **Tailwind 4 `@theme` name**: emitted into the shared `frontend/src/skins/theme.generated.css` as `@theme inline { --color-iris600: var(--mm-color-iris600); … }`. The rule "Tailwind name `X` maps to `var(--mm-X)`" is the same for both skins, so the union of both skins' `@theme` entries never conflicts; a Glass screen uses only the names in this table (checked by `build.mjs --check`, which greps `src/skins/glass/**` for utilities outside this list). Breakpoints are compile-time and therefore shared literally: Glass uses Cinematic's `frame:` (768), `desktop:` (1024) and `wide:` (1440) variants and never defines a `--breakpoint-*` of its own. Spacing uses the shared `--spacing: 0.25rem` base, so every Glass spacing value is a multiplier utility. Durations have no `@theme` namespace in Tailwind 4 and are used as `duration-(--mm-dur-…)`.
- **Short names in the prose** map to keys directly: `g100` → `color.g100`, `label2` → `color.label2`, `s5` → `space.s5`, `rMd` → `radius.md` (`r2xl` → `radius.xxl`, `rSheet` → `radius.sheet`, `rIconTile` → `radius.iconTile`), `blurThin` → `blur.thin`, `glassFilm` / `glassThin` / `glassRegular` / `glassThick` / `glassMonolith` → `glass.t1` … `glass.t5`, `glassClear` / `glassTinted` → `glass.clear` / `glass.tinted` on the host tier, `dimLegibility` → `dim.legibility`, a spring name (`page`) → `spring.page`, a curve name (`fadeIn`) → `curve.fadeIn`.
- **Flutter field**: a field of `GlassTokens extends ThemeExtension<GlassTokens>` in `mobile/lib/skins/glass/tokens.g.dart` (camelCase of the full key), attached through `ThemeData(extensions: [glassTokens])` and read as `context.glass.colorIris600`. The same values are also emitted as `static const` members of `GlassColors`, `GlassSpace`, `GlassRadius`, `GlassSprings`, `GlassCurves` and `GlassPhysics` for `const` constructors. `SpringToken.description` returns `SpringDescription.withDurationAndBounce(duration: Duration(milliseconds: ms), bounce: bounce)`.

#### 2.8.1 Colour

| Key | Value | Web CSS property | Tailwind 4 `@theme` (utility) | Flutter `GlassTokens` field |
|---|---|---|---|---|
| `color.g0` | `#000000` | `--mm-color-g0: #000000` | `--color-g0` (`bg-g0`, `text-g0`) | `colorG0` = `Color(0xFF000000)` |
| `color.g25` | `#060608` | `--mm-color-g25: #060608` | `--color-g25` (`bg-g25`, `text-g25`) | `colorG25` = `Color(0xFF060608)` |
| `color.g50` | `#0B0B0F` | `--mm-color-g50: #0B0B0F` | `--color-g50` (`bg-g50`, `text-g50`) | `colorG50` = `Color(0xFF0B0B0F)` |
| `color.g100` | `#131317` | `--mm-color-g100: #131317` | `--color-g100` (`bg-g100`, `text-g100`) | `colorG100` = `Color(0xFF131317)` |
| `color.g150` | `#1A1A20` | `--mm-color-g150: #1A1A20` | `--color-g150` (`bg-g150`, `text-g150`) | `colorG150` = `Color(0xFF1A1A20)` |
| `color.g200` | `#222229` | `--mm-color-g200: #222229` | `--color-g200` (`bg-g200`, `text-g200`) | `colorG200` = `Color(0xFF222229)` |
| `color.g300` | `#2D2D35` | `--mm-color-g300: #2D2D35` | `--color-g300` (`bg-g300`, `text-g300`) | `colorG300` = `Color(0xFF2D2D35)` |
| `color.g400` | `#3C3C46` | `--mm-color-g400: #3C3C46` | `--color-g400` (`bg-g400`, `text-g400`) | `colorG400` = `Color(0xFF3C3C46)` |
| `color.g500` | `#56565F` | `--mm-color-g500: #56565F` | `--color-g500` (`bg-g500`, `text-g500`) | `colorG500` = `Color(0xFF56565F)` |
| `color.g600` | `#76767F` | `--mm-color-g600: #76767F` | `--color-g600` (`bg-g600`, `text-g600`) | `colorG600` = `Color(0xFF76767F)` |
| `color.g700` | `#9A9AA4` | `--mm-color-g700: #9A9AA4` | `--color-g700` (`bg-g700`, `text-g700`) | `colorG700` = `Color(0xFF9A9AA4)` |
| `color.g800` | `#BDBDC6` | `--mm-color-g800: #BDBDC6` | `--color-g800` (`bg-g800`, `text-g800`) | `colorG800` = `Color(0xFFBDBDC6)` |
| `color.g900` | `#DCDCE3` | `--mm-color-g900: #DCDCE3` | `--color-g900` (`bg-g900`, `text-g900`) | `colorG900` = `Color(0xFFDCDCE3)` |
| `color.g950` | `#ECECF1` | `--mm-color-g950: #ECECF1` | `--color-g950` (`bg-g950`, `text-g950`) | `colorG950` = `Color(0xFFECECF1)` |
| `color.g1000` | `#F7F7FA` | `--mm-color-g1000: #F7F7FA` | `--color-g1000` (`bg-g1000`, `text-g1000`) | `colorG1000` = `Color(0xFFF7F7FA)` |
| `color.surface1` | `#131317` | `--mm-color-surface1: #131317` | `--color-surface1` (`bg-surface1`, `text-surface1`) | `colorSurface1` = `Color(0xFF131317)` |
| `color.surface2` | `#1A1A20` | `--mm-color-surface2: #1A1A20` | `--color-surface2` (`bg-surface2`, `text-surface2`) | `colorSurface2` = `Color(0xFF1A1A20)` |
| `color.surface3` | `#222229` | `--mm-color-surface3: #222229` | `--color-surface3` (`bg-surface3`, `text-surface3`) | `colorSurface3` = `Color(0xFF222229)` |
| `color.label1` | `#F2F2F7` | `--mm-color-label1: #F2F2F7` | `--color-label1` (`bg-label1`, `text-label1`) | `colorLabel1` = `Color(0xFFF2F2F7)` |
| `color.label2` | `rgba(235,235,245,0.64)` | `--mm-color-label2: rgba(235,235,245,0.64)` | `--color-label2` (`bg-label2`, `text-label2`) | `colorLabel2` = `Color(0xA3EBEBF5)` |
| `color.label3` | `rgba(235,235,245,0.52)` | `--mm-color-label3: rgba(235,235,245,0.52)` | `--color-label3` (`bg-label3`, `text-label3`) | `colorLabel3` = `Color(0x85EBEBF5)` |
| `color.label4` | `rgba(235,235,245,0.24)` | `--mm-color-label4: rgba(235,235,245,0.24)` | `--color-label4` (`bg-label4`, `text-label4`) | `colorLabel4` = `Color(0x3DEBEBF5)` |
| `color.onGlass` | `#F2F2F7` | `--mm-color-on-glass: #F2F2F7` | `--color-on-glass` (`bg-on-glass`, `text-on-glass`) | `colorOnGlass` = `Color(0xFFF2F2F7)` |
| `color.onTint` | `#FFFFFF` | `--mm-color-on-tint: #FFFFFF` | `--color-on-tint` (`bg-on-tint`, `text-on-tint`) | `colorOnTint` = `Color(0xFFFFFFFF)` |
| `color.fill1` | `rgba(120,120,128,0.36)` | `--mm-color-fill1: rgba(120,120,128,0.36)` | `--color-fill1` (`bg-fill1`, `text-fill1`) | `colorFill1` = `Color(0x5C787880)` |
| `color.fill2` | `rgba(120,120,128,0.30)` | `--mm-color-fill2: rgba(120,120,128,0.30)` | `--color-fill2` (`bg-fill2`, `text-fill2`) | `colorFill2` = `Color(0x4C787880)` |
| `color.fill3` | `rgba(118,118,128,0.22)` | `--mm-color-fill3: rgba(118,118,128,0.22)` | `--color-fill3` (`bg-fill3`, `text-fill3`) | `colorFill3` = `Color(0x38767680)` |
| `color.fill4` | `rgba(118,118,128,0.16)` | `--mm-color-fill4: rgba(118,118,128,0.16)` | `--color-fill4` (`bg-fill4`, `text-fill4`) | `colorFill4` = `Color(0x29767680)` |
| `color.separator` | `rgba(84,84,96,0.55)` | `--mm-color-separator: rgba(84,84,96,0.55)` | `--color-separator` (`bg-separator`, `text-separator`) | `colorSeparator` = `Color(0x8C545460)` |
| `color.separatorOpaque` | `#2D2D35` | `--mm-color-separator-opaque: #2D2D35` | `--color-separator-opaque` (`bg-separator-opaque`, `text-separator-opaque`) | `colorSeparatorOpaque` = `Color(0xFF2D2D35)` |
| `color.iris100` | `#E4DFFF` | `--mm-color-iris100: #E4DFFF` | `--color-iris100` (`bg-iris100`, `text-iris100`) | `colorIris100` = `Color(0xFFE4DFFF)` |
| `color.iris200` | `#D0C8FF` | `--mm-color-iris200: #D0C8FF` | `--color-iris200` (`bg-iris200`, `text-iris200`) | `colorIris200` = `Color(0xFFD0C8FF)` |
| `color.iris300` | `#BCB0FF` | `--mm-color-iris300: #BCB0FF` | `--color-iris300` (`bg-iris300`, `text-iris300`) | `colorIris300` = `Color(0xFFBCB0FF)` |
| `color.iris400` | `#A99BFF` | `--mm-color-iris400: #A99BFF` | `--color-iris400` (`bg-iris400`, `text-iris400`) | `colorIris400` = `Color(0xFFA99BFF)` |
| `color.iris500` | `#8F7EFF` | `--mm-color-iris500: #8F7EFF` | `--color-iris500` (`bg-iris500`, `text-iris500`) | `colorIris500` = `Color(0xFF8F7EFF)` |
| `color.iris600` | `#7563F2` | `--mm-color-iris600: #7563F2` | `--color-iris600` (`bg-iris600`, `text-iris600`) | `colorIris600` = `Color(0xFF7563F2)` |
| `color.iris700` | `#5B4AD1` | `--mm-color-iris700: #5B4AD1` | `--color-iris700` (`bg-iris700`, `text-iris700`) | `colorIris700` = `Color(0xFF5B4AD1)` |
| `color.iris800` | `#4336A3` | `--mm-color-iris800: #4336A3` | `--color-iris800` (`bg-iris800`, `text-iris800`) | `colorIris800` = `Color(0xFF4336A3)` |
| `color.iris900` | `#2B2370` | `--mm-color-iris900: #2B2370` | `--color-iris900` (`bg-iris900`, `text-iris900`) | `colorIris900` = `Color(0xFF2B2370)` |
| `color.success` | `#3DDC84` | `--mm-color-success: #3DDC84` | `--color-success` (`bg-success`, `text-success`) | `colorSuccess` = `Color(0xFF3DDC84)` |
| `color.warning` | `#FFB547` | `--mm-color-warning: #FFB547` | `--color-warning` (`bg-warning`, `text-warning`) | `colorWarning` = `Color(0xFFFFB547)` |
| `color.danger` | `#FF5C5C` | `--mm-color-danger: #FF5C5C` | `--color-danger` (`bg-danger`, `text-danger`) | `colorDanger` = `Color(0xFFFF5C5C)` |
| `color.info` | `#6CB8FF` | `--mm-color-info: #6CB8FF` | `--color-info` (`bg-info`, `text-info`) | `colorInfo` = `Color(0xFF6CB8FF)` |
| `color.mature` | `#FF5C93` | `--mm-color-mature: #FF5C93` | `--color-mature` (`bg-mature`, `text-mature`) | `colorMature` = `Color(0xFFFF5C93)` |
| `color.streak` | `#FF8A3D` | `--mm-color-streak: #FF8A3D` | `--color-streak` (`bg-streak`, `text-streak`) | `colorStreak` = `Color(0xFFFF8A3D)` |
| `color.streakCore` | `#FFD166` | `--mm-color-streak-core: #FFD166` | `--color-streak-core` (`bg-streak-core`, `text-streak-core`) | `colorStreakCore` = `Color(0xFFFFD166)` |
| `color.bloom` | `#FF9ED8` | `--mm-color-bloom: #FF9ED8` | `--color-bloom` (`bg-bloom`, `text-bloom`) | `colorBloom` = `Color(0xFFFF9ED8)` |
| `color.bloomWash` | `rgba(255,158,216,0.14)` | `--mm-color-bloom-wash: rgba(255,158,216,0.14)` | `--color-bloom-wash` (`bg-bloom-wash`, `text-bloom-wash`) | `colorBloomWash` = `Color(0x24FF9ED8)` |
| `color.bloomRim` | `rgba(255,158,216,0.45)` | `--mm-color-bloom-rim: rgba(255,158,216,0.45)` | `--color-bloom-rim` (`bg-bloom-rim`, `text-bloom-rim`) | `colorBloomRim` = `Color(0x73FF9ED8)` |
| `color.machine` | `#5CE1E6` | `--mm-color-machine: #5CE1E6` | `--color-machine` (`bg-machine`, `text-machine`) | `colorMachine` = `Color(0xFF5CE1E6)` |
| `color.machineWash` | `rgba(92,225,230,0.14)` | `--mm-color-machine-wash: rgba(92,225,230,0.14)` | `--color-machine-wash` (`bg-machine-wash`, `text-machine-wash`) | `colorMachineWash` = `Color(0x245CE1E6)` |
| `color.machineRim` | `rgba(92,225,230,0.45)` | `--mm-color-machine-rim: rgba(92,225,230,0.45)` | `--color-machine-rim` (`bg-machine-rim`, `text-machine-rim`) | `colorMachineRim` = `Color(0x735CE1E6)` |
| `color.readerWarmth` | `#FF8A00` | `--mm-color-reader-warmth: #FF8A00` | `--color-reader-warmth` (`bg-reader-warmth`) | `colorReaderWarmth` = `Color(0xFFFF8A00)` (the reader's warmth overlay only; not the "Warmth" light of §2.1.9) |
| `color.brandFrost` | `#F5F7FA` | `--mm-color-brand-frost: #F5F7FA` | `--color-brand-frost` (`bg-brand-frost`, `text-brand-frost`) | `colorBrandFrost` = `Color(0xFFF5F7FA)` |
| `color.spk1` | `#7CC4FF` | `--mm-color-spk1: #7CC4FF` | `--color-spk1` (`bg-spk1`, `text-spk1`) | `colorSpk1` = `Color(0xFF7CC4FF)` |
| `color.spk2` | `#FFB27A` | `--mm-color-spk2: #FFB27A` | `--color-spk2` (`bg-spk2`, `text-spk2`) | `colorSpk2` = `Color(0xFFFFB27A)` |
| `color.spk3` | `#9BE58A` | `--mm-color-spk3: #9BE58A` | `--color-spk3` (`bg-spk3`, `text-spk3`) | `colorSpk3` = `Color(0xFF9BE58A)` |
| `color.spk4` | `#D7A4FF` | `--mm-color-spk4: #D7A4FF` | `--color-spk4` (`bg-spk4`, `text-spk4`) | `colorSpk4` = `Color(0xFFD7A4FF)` |
| `color.spk5` | `#FF8FA3` | `--mm-color-spk5: #FF8FA3` | `--color-spk5` (`bg-spk5`, `text-spk5`) | `colorSpk5` = `Color(0xFFFF8FA3)` |
| `color.spk6` | `#6FE3D4` | `--mm-color-spk6: #6FE3D4` | `--color-spk6` (`bg-spk6`, `text-spk6`) | `colorSpk6` = `Color(0xFF6FE3D4)` |
| `color.spk7` | `#FFD86B` | `--mm-color-spk7: #FFD86B` | `--color-spk7` (`bg-spk7`, `text-spk7`) | `colorSpk7` = `Color(0xFFFFD86B)` |
| `color.spk8` | `#A7B4FF` | `--mm-color-spk8: #A7B4FF` | `--color-spk8` (`bg-spk8`, `text-spk8`) | `colorSpk8` = `Color(0xFFA7B4FF)` |
| `color.spk9` | `#F59BD6` | `--mm-color-spk9: #F59BD6` | `--color-spk9` (`bg-spk9`, `text-spk9`) | `colorSpk9` = `Color(0xFFF59BD6)` |
| `color.spk10` | `#C8D98A` | `--mm-color-spk10: #C8D98A` | `--color-spk10` (`bg-spk10`, `text-spk10`) | `colorSpk10` = `Color(0xFFC8D98A)` |
| `color.mood.romantic` | `#FF7AA8` | `--mm-color-mood-romantic: #FF7AA8` | `--color-mood-romantic` (`bg-mood-romantic`, `text-mood-romantic`) | `colorMoodRomantic` = `Color(0xFFFF7AA8)` |
| `color.mood.action` | `#FF6B4A` | `--mm-color-mood-action: #FF6B4A` | `--color-mood-action` (`bg-mood-action`, `text-mood-action`) | `colorMoodAction` = `Color(0xFFFF6B4A)` |
| `color.mood.comedy` | `#FFC94D` | `--mm-color-mood-comedy: #FFC94D` | `--color-mood-comedy` (`bg-mood-comedy`, `text-mood-comedy`) | `colorMoodComedy` = `Color(0xFFFFC94D)` |
| `color.mood.horror` | `#C0506F` | `--mm-color-mood-horror: #C0506F` | `--color-mood-horror` (`bg-mood-horror`, `text-mood-horror`) | `colorMoodHorror` = `Color(0xFFC0506F)` |
| `color.mood.sliceOfLife` | `#9FD98A` | `--mm-color-mood-slice-of-life: #9FD98A` | `--color-mood-slice-of-life` (`bg-mood-slice-of-life`, `text-mood-slice-of-life`) | `colorMoodSliceOfLife` = `Color(0xFF9FD98A)` |
| `color.mood.fantasy` | `#9B8CFF` | `--mm-color-mood-fantasy: #9B8CFF` | `--color-mood-fantasy` (`bg-mood-fantasy`, `text-mood-fantasy`) | `colorMoodFantasy` = `Color(0xFF9B8CFF)` |
| `color.mood.default` | `#4336A3` | `--mm-color-mood-default: #4336A3` | `--color-mood-default` (`bg-mood-default`, `text-mood-default`) | `colorMoodDefault` = `Color(0xFF4336A3)` |
| `color.aurora1` | `#8FD8FF` | `--mm-color-aurora1: #8FD8FF` | `--color-aurora1` (`bg-aurora1`, `text-aurora1`) | `colorAurora1` = `Color(0xFF8FD8FF)` |
| `color.aurora2` | `#A99BFF` | `--mm-color-aurora2: #A99BFF` | `--color-aurora2` (`bg-aurora2`, `text-aurora2`) | `colorAurora2` = `Color(0xFFA99BFF)` |
| `color.aurora3` | `#FF9ED8` | `--mm-color-aurora3: #FF9ED8` | `--color-aurora3` (`bg-aurora3`, `text-aurora3`) | `colorAurora3` = `Color(0xFFFF9ED8)` |
| `color.heat0` | `rgba(118,118,128,0.22)` | `--mm-color-heat0: rgba(118,118,128,0.22)` | `--color-heat0` (`bg-heat0`, `text-heat0`) | `colorHeat0` = `Color(0x38767680)` |
| `color.heat1` | `#4336A3` | `--mm-color-heat1: #4336A3` | `--color-heat1` (`bg-heat1`, `text-heat1`) | `colorHeat1` = `Color(0xFF4336A3)` |
| `color.heat2` | `#5B4AD1` | `--mm-color-heat2: #5B4AD1` | `--color-heat2` (`bg-heat2`, `text-heat2`) | `colorHeat2` = `Color(0xFF5B4AD1)` |
| `color.heat3` | `#7563F2` | `--mm-color-heat3: #7563F2` | `--color-heat3` (`bg-heat3`, `text-heat3`) | `colorHeat3` = `Color(0xFF7563F2)` |
| `color.heat4` | `#A99BFF` | `--mm-color-heat4: #A99BFF` | `--color-heat4` (`bg-heat4`, `text-heat4`) | `colorHeat4` = `Color(0xFFA99BFF)` |
| `color.dimSheet` | `rgba(0,0,0,0.28)` | `--mm-color-dim-sheet: rgba(0,0,0,0.28)` | `--color-dim-sheet` (`bg-dim-sheet`, `text-dim-sheet`) | `colorDimSheet` = `Color(0x47000000)` |
| `color.dimModal` | `rgba(0,0,0,0.48)` | `--mm-color-dim-modal: rgba(0,0,0,0.48)` | `--color-dim-modal` (`bg-dim-modal`, `text-dim-modal`) | `colorDimModal` = `Color(0x7A000000)` |
| `color.dimContext` | `rgba(0,0,0,0.55)` | `--mm-color-dim-context: rgba(0,0,0,0.55)` | `--color-dim-context` (`bg-dim-context`, `text-dim-context`) | `colorDimContext` = `Color(0x8C000000)` |
| `color.dimClear` | `rgba(0,0,0,0.35)` | `--mm-color-dim-clear: rgba(0,0,0,0.35)` | `--color-dim-clear` (`bg-dim-clear`, `text-dim-clear`) | `colorDimClear` = `Color(0x59000000)` |
| `color.edgeHard` | `rgba(0,0,0,0.92)` | `--mm-color-edge-hard: rgba(0,0,0,0.92)` | `--color-edge-hard` (`bg-edge-hard`, `text-edge-hard`) | `colorEdgeHard` = `Color(0xEB000000)` |
| `color.paper.void.page` | `#000000` | `--mm-color-paper-void-page: #000000` | `--color-paper-void-page` (`bg-paper-void-page`, `text-paper-void-page`) | `colorPaperVoidPage` = `Color(0xFF000000)` |
| `color.paper.void.ink` | `#D9D6D0` | `--mm-color-paper-void-ink: #D9D6D0` | `--color-paper-void-ink` (`bg-paper-void-ink`, `text-paper-void-ink`) | `colorPaperVoidInk` = `Color(0xFFD9D6D0)` |
| `color.paper.void.muted` | `#8A877F` | `--mm-color-paper-void-muted: #8A877F` | `--color-paper-void-muted` (`bg-paper-void-muted`, `text-paper-void-muted`) | `colorPaperVoidMuted` = `Color(0xFF8A877F)` |
| `color.paper.ink.page` | `#0B0B0C` | `--mm-color-paper-ink-page: #0B0B0C` | `--color-paper-ink-page` (`bg-paper-ink-page`, `text-paper-ink-page`) | `colorPaperInkPage` = `Color(0xFF0B0B0C)` |
| `color.paper.ink.ink` | `#E6E3DD` | `--mm-color-paper-ink-ink: #E6E3DD` | `--color-paper-ink-ink` (`bg-paper-ink-ink`, `text-paper-ink-ink`) | `colorPaperInkInk` = `Color(0xFFE6E3DD)` |
| `color.paper.ink.muted` | `#8F8C86` | `--mm-color-paper-ink-muted: #8F8C86` | `--color-paper-ink-muted` (`bg-paper-ink-muted`, `text-paper-ink-muted`) | `colorPaperInkMuted` = `Color(0xFF8F8C86)` |
| `color.paper.nightPaper.page` | `#15110C` | `--mm-color-paper-night-paper-page: #15110C` | `--color-paper-night-paper-page` (`bg-paper-night-paper-page`, `text-paper-night-paper-page`) | `colorPaperNightPaperPage` = `Color(0xFF15110C)` |
| `color.paper.nightPaper.ink` | `#E8D8BE` | `--mm-color-paper-night-paper-ink: #E8D8BE` | `--color-paper-night-paper-ink` (`bg-paper-night-paper-ink`, `text-paper-night-paper-ink`) | `colorPaperNightPaperInk` = `Color(0xFFE8D8BE)` |
| `color.paper.nightPaper.muted` | `#9C8E78` | `--mm-color-paper-night-paper-muted: #9C8E78` | `--color-paper-night-paper-muted` (`bg-paper-night-paper-muted`, `text-paper-night-paper-muted`) | `colorPaperNightPaperMuted` = `Color(0xFF9C8E78)` |
| `color.paper.dusk.page` | `#0D1117` | `--mm-color-paper-dusk-page: #0D1117` | `--color-paper-dusk-page` (`bg-paper-dusk-page`, `text-paper-dusk-page`) | `colorPaperDuskPage` = `Color(0xFF0D1117)` |
| `color.paper.dusk.ink` | `#D3DAE3` | `--mm-color-paper-dusk-ink: #D3DAE3` | `--color-paper-dusk-ink` (`bg-paper-dusk-ink`, `text-paper-dusk-ink`) | `colorPaperDuskInk` = `Color(0xFFD3DAE3)` |
| `color.paper.dusk.muted` | `#8590A0` | `--mm-color-paper-dusk-muted: #8590A0` | `--color-paper-dusk-muted` (`bg-paper-dusk-muted`, `text-paper-dusk-muted`) | `colorPaperDuskMuted` = `Color(0xFF8590A0)` |
| `color.paper.moss.page` | `#0E130F` | `--mm-color-paper-moss-page: #0E130F` | `--color-paper-moss-page` (`bg-paper-moss-page`, `text-paper-moss-page`) | `colorPaperMossPage` = `Color(0xFF0E130F)` |
| `color.paper.moss.ink` | `#D5DECF` | `--mm-color-paper-moss-ink: #D5DECF` | `--color-paper-moss-ink` (`bg-paper-moss-ink`, `text-paper-moss-ink`) | `colorPaperMossInk` = `Color(0xFFD5DECF)` |
| `color.paper.moss.muted` | `#879384` | `--mm-color-paper-moss-muted: #879384` | `--color-paper-moss-muted` (`bg-paper-moss-muted`, `text-paper-moss-muted`) | `colorPaperMossMuted` = `Color(0xFF879384)` |
| `color.paper.rosewood.page` | `#160E10` | `--mm-color-paper-rosewood-page: #160E10` | `--color-paper-rosewood-page` (`bg-paper-rosewood-page`, `text-paper-rosewood-page`) | `colorPaperRosewoodPage` = `Color(0xFF160E10)` |
| `color.paper.rosewood.ink` | `#EBD5D8` | `--mm-color-paper-rosewood-ink: #EBD5D8` | `--color-paper-rosewood-ink` (`bg-paper-rosewood-ink`, `text-paper-rosewood-ink`) | `colorPaperRosewoodInk` = `Color(0xFFEBD5D8)` |
| `color.paper.rosewood.muted` | `#A08A8E` | `--mm-color-paper-rosewood-muted: #A08A8E` | `--color-paper-rosewood-muted` (`bg-paper-rosewood-muted`, `text-paper-rosewood-muted`) | `colorPaperRosewoodMuted` = `Color(0xFFA08A8E)` |
| `color.paper.glass.page` | `#000000` | `--mm-color-paper-glass-page: #000000` | `--color-paper-glass-page` (`bg-paper-glass-page`, `text-paper-glass-page`) | `colorPaperGlassPage` = `Color(0xFF000000)` |
| `color.paper.glass.ink` | `#ECECF1` | `--mm-color-paper-glass-ink: #ECECF1` | `--color-paper-glass-ink` (`bg-paper-glass-ink`, `text-paper-glass-ink`) | `colorPaperGlassInk` = `Color(0xFFECECF1)` |
| `color.paper.glass.muted` | `#8F8F99` | `--mm-color-paper-glass-muted: #8F8F99` | `--color-paper-glass-muted` (`bg-paper-glass-muted`, `text-paper-glass-muted`) | `colorPaperGlassMuted` = `Color(0xFF8F8F99)` |
| `color.avatar.violetSpark.from` | `#8B5CF6` | `--mm-color-avatar-violet-spark-from: #8B5CF6` | `--color-avatar-violet-spark-from` (`bg-avatar-violet-spark-from`, `text-avatar-violet-spark-from`) | `colorAvatarVioletSparkFrom` = `Color(0xFF8B5CF6)` |
| `color.avatar.violetSpark.to` | `#D946EF` | `--mm-color-avatar-violet-spark-to: #D946EF` | `--color-avatar-violet-spark-to` (`bg-avatar-violet-spark-to`, `text-avatar-violet-spark-to`) | `colorAvatarVioletSparkTo` = `Color(0xFFD946EF)` |
| `color.avatar.cyanRocket.from` | `#06B6D4` | `--mm-color-avatar-cyan-rocket-from: #06B6D4` | `--color-avatar-cyan-rocket-from` (`bg-avatar-cyan-rocket-from`, `text-avatar-cyan-rocket-from`) | `colorAvatarCyanRocketFrom` = `Color(0xFF06B6D4)` |
| `color.avatar.cyanRocket.to` | `#0EA5E9` | `--mm-color-avatar-cyan-rocket-to: #0EA5E9` | `--color-avatar-cyan-rocket-to` (`bg-avatar-cyan-rocket-to`, `text-avatar-cyan-rocket-to`) | `colorAvatarCyanRocketTo` = `Color(0xFF0EA5E9)` |
| `color.avatar.roseHeart.from` | `#F43F5E` | `--mm-color-avatar-rose-heart-from: #F43F5E` | `--color-avatar-rose-heart-from` (`bg-avatar-rose-heart-from`, `text-avatar-rose-heart-from`) | `colorAvatarRoseHeartFrom` = `Color(0xFFF43F5E)` |
| `color.avatar.roseHeart.to` | `#EC4899` | `--mm-color-avatar-rose-heart-to: #EC4899` | `--color-avatar-rose-heart-to` (`bg-avatar-rose-heart-to`, `text-avatar-rose-heart-to`) | `colorAvatarRoseHeartTo` = `Color(0xFFEC4899)` |
| `color.avatar.amberCoffee.from` | `#F59E0B` | `--mm-color-avatar-amber-coffee-from: #F59E0B` | `--color-avatar-amber-coffee-from` (`bg-avatar-amber-coffee-from`, `text-avatar-amber-coffee-from`) | `colorAvatarAmberCoffeeFrom` = `Color(0xFFF59E0B)` |
| `color.avatar.amberCoffee.to` | `#F97316` | `--mm-color-avatar-amber-coffee-to: #F97316` | `--color-avatar-amber-coffee-to` (`bg-avatar-amber-coffee-to`, `text-avatar-amber-coffee-to`) | `colorAvatarAmberCoffeeTo` = `Color(0xFFF97316)` |
| `color.avatar.emeraldCat.from` | `#10B981` | `--mm-color-avatar-emerald-cat-from: #10B981` | `--color-avatar-emerald-cat-from` (`bg-avatar-emerald-cat-from`, `text-avatar-emerald-cat-from`) | `colorAvatarEmeraldCatFrom` = `Color(0xFF10B981)` |
| `color.avatar.emeraldCat.to` | `#14B8A6` | `--mm-color-avatar-emerald-cat-to: #14B8A6` | `--color-avatar-emerald-cat-to` (`bg-avatar-emerald-cat-to`, `text-avatar-emerald-cat-to`) | `colorAvatarEmeraldCatTo` = `Color(0xFF14B8A6)` |
| `color.avatar.emberFlame.from` | `#EF4444` | `--mm-color-avatar-ember-flame-from: #EF4444` | `--color-avatar-ember-flame-from` (`bg-avatar-ember-flame-from`, `text-avatar-ember-flame-from`) | `colorAvatarEmberFlameFrom` = `Color(0xFFEF4444)` |
| `color.avatar.emberFlame.to` | `#F59E0B` | `--mm-color-avatar-ember-flame-to: #F59E0B` | `--color-avatar-ember-flame-to` (`bg-avatar-ember-flame-to`, `text-avatar-ember-flame-to`) | `colorAvatarEmberFlameTo` = `Color(0xFFF59E0B)` |
| `color.avatar.steelBlade.from` | `#94A3B8` | `--mm-color-avatar-steel-blade-from: #94A3B8` | `--color-avatar-steel-blade-from` (`bg-avatar-steel-blade-from`, `text-avatar-steel-blade-from`) | `colorAvatarSteelBladeFrom` = `Color(0xFF94A3B8)` |
| `color.avatar.steelBlade.to` | `#475569` | `--mm-color-avatar-steel-blade-to: #475569` | `--color-avatar-steel-blade-to` (`bg-avatar-steel-blade-to`, `text-avatar-steel-blade-to`) | `colorAvatarSteelBladeTo` = `Color(0xFF475569)` |
| `color.avatar.phantom.from` | `#6366F1` | `--mm-color-avatar-phantom-from: #6366F1` | `--color-avatar-phantom-from` (`bg-avatar-phantom-from`, `text-avatar-phantom-from`) | `colorAvatarPhantomFrom` = `Color(0xFF6366F1)` |
| `color.avatar.phantom.to` | `#334155` | `--mm-color-avatar-phantom-to: #334155` | `--color-avatar-phantom-to` (`bg-avatar-phantom-to`, `text-avatar-phantom-to`) | `colorAvatarPhantomTo` = `Color(0xFF334155)` |
| `color.avatar.arcaneWand.from` | `#A855F7` | `--mm-color-avatar-arcane-wand-from: #A855F7` | `--color-avatar-arcane-wand-from` (`bg-avatar-arcane-wand-from`, `text-avatar-arcane-wand-from`) | `colorAvatarArcaneWandFrom` = `Color(0xFFA855F7)` |
| `color.avatar.arcaneWand.to` | `#6366F1` | `--mm-color-avatar-arcane-wand-to: #6366F1` | `--color-avatar-arcane-wand-to` (`bg-avatar-arcane-wand-to`, `text-avatar-arcane-wand-to`) | `colorAvatarArcaneWandTo` = `Color(0xFF6366F1)` |
| `color.avatar.lunarMoon.from` | `#0284C7` | `--mm-color-avatar-lunar-moon-from: #0284C7` | `--color-avatar-lunar-moon-from` (`bg-avatar-lunar-moon-from`, `text-avatar-lunar-moon-from`) | `colorAvatarLunarMoonFrom` = `Color(0xFF0284C7)` |
| `color.avatar.lunarMoon.to` | `#4338CA` | `--mm-color-avatar-lunar-moon-to: #4338CA` | `--color-avatar-lunar-moon-to` (`bg-avatar-lunar-moon-to`, `text-avatar-lunar-moon-to`) | `colorAvatarLunarMoonTo` = `Color(0xFF4338CA)` |
| `color.avatar.starlight.from` | `#FACC15` | `--mm-color-avatar-starlight-from: #FACC15` | `--color-avatar-starlight-from` (`bg-avatar-starlight-from`, `text-avatar-starlight-from`) | `colorAvatarStarlightFrom` = `Color(0xFFFACC15)` |
| `color.avatar.starlight.to` | `#F59E0B` | `--mm-color-avatar-starlight-to: #F59E0B` | `--color-avatar-starlight-to` (`bg-avatar-starlight-to`, `text-avatar-starlight-to`) | `colorAvatarStarlightTo` = `Color(0xFFF59E0B)` |
| `color.avatar.bookworm.from` | `#14B8A6` | `--mm-color-avatar-bookworm-from: #14B8A6` | `--color-avatar-bookworm-from` (`bg-avatar-bookworm-from`, `text-avatar-bookworm-from`) | `colorAvatarBookwormFrom` = `Color(0xFF14B8A6)` |
| `color.avatar.bookworm.to` | `#0891B2` | `--mm-color-avatar-bookworm-to: #0891B2` | `--color-avatar-bookworm-to` (`bg-avatar-bookworm-to`, `text-avatar-bookworm-to`) | `colorAvatarBookwormTo` = `Color(0xFF0891B2)` |

#### 2.8.2 Space and fixed layout lengths

| Key | Value | Web CSS property | Tailwind 4 `@theme` (utility) | Flutter `GlassTokens` field |
|---|---|---|---|---|
| `space.s0` | 0 px | `--mm-space-s0: 0px` | shared `--spacing: 0.25rem`, so `p-0`, `gap-0`, `m-0` = 0 px | `spaceS0` = `0.0` |
| `space.s1` | 2 px | `--mm-space-s1: 2px` | shared `--spacing: 0.25rem`, so `p-0.5`, `gap-0.5`, `m-0.5` = 2 px | `spaceS1` = `2.0` |
| `space.s2` | 4 px | `--mm-space-s2: 4px` | shared `--spacing: 0.25rem`, so `p-1`, `gap-1`, `m-1` = 4 px | `spaceS2` = `4.0` |
| `space.s3` | 6 px | `--mm-space-s3: 6px` | shared `--spacing: 0.25rem`, so `p-1.5`, `gap-1.5`, `m-1.5` = 6 px | `spaceS3` = `6.0` |
| `space.s4` | 8 px | `--mm-space-s4: 8px` | shared `--spacing: 0.25rem`, so `p-2`, `gap-2`, `m-2` = 8 px | `spaceS4` = `8.0` |
| `space.s5` | 12 px | `--mm-space-s5: 12px` | shared `--spacing: 0.25rem`, so `p-3`, `gap-3`, `m-3` = 12 px | `spaceS5` = `12.0` |
| `space.s6` | 16 px | `--mm-space-s6: 16px` | shared `--spacing: 0.25rem`, so `p-4`, `gap-4`, `m-4` = 16 px | `spaceS6` = `16.0` |
| `space.s7` | 20 px | `--mm-space-s7: 20px` | shared `--spacing: 0.25rem`, so `p-5`, `gap-5`, `m-5` = 20 px | `spaceS7` = `20.0` |
| `space.s8` | 24 px | `--mm-space-s8: 24px` | shared `--spacing: 0.25rem`, so `p-6`, `gap-6`, `m-6` = 24 px | `spaceS8` = `24.0` |
| `space.s9` | 32 px | `--mm-space-s9: 32px` | shared `--spacing: 0.25rem`, so `p-8`, `gap-8`, `m-8` = 32 px | `spaceS9` = `32.0` |
| `space.s10` | 40 px | `--mm-space-s10: 40px` | shared `--spacing: 0.25rem`, so `p-10`, `gap-10`, `m-10` = 40 px | `spaceS10` = `40.0` |
| `space.s11` | 48 px | `--mm-space-s11: 48px` | shared `--spacing: 0.25rem`, so `p-12`, `gap-12`, `m-12` = 48 px | `spaceS11` = `48.0` |
| `space.s12` | 64 px | `--mm-space-s12: 64px` | shared `--spacing: 0.25rem`, so `p-16`, `gap-16`, `m-16` = 64 px | `spaceS12` = `64.0` |
| `space.s13` | 85 px | `--mm-space-s13: 85px` | not on the 4 px multiplier grid, so the arbitrary utility `pb-(--mm-space-s13)` | `spaceS13` = `85.0` |
| `space.s14` | 96 px | `--mm-space-s14: 96px` | shared `--spacing: 0.25rem`, so `p-24`, `gap-24`, `m-24` = 96 px | `spaceS14` = `96.0` |
| `layout.touchMin` | 44 px (Android 48 px) | `--mm-layout-touch-min: 44px` | `--spacing-touch-min` (`min-h-touch-min`, `min-w-touch-min`) | `layoutTouchMin` = `44.0` (`layoutTouchMinAndroid` = `48.0`) |
| `layout.dockInset` | 21 px | `--mm-layout-dock-inset: 21px` | `--spacing-dock-inset` (`inset-x-dock-inset`, `bottom-dock-inset`) | `layoutDockInset` = `21.0` |
| `layout.dockHeight` | 64 px | `--mm-layout-dock-height: 64px` | `--spacing-dock-height` (`h-dock-height`) | `layoutDockHeight` = `64.0` |
| `layout.dockMinimized` | 50 px | `--mm-layout-dock-minimized: 50px` | `--spacing-dock-minimized` (`h-dock-minimized`) | `layoutDockMinimized` = `50.0` |
| `layout.searchOrb` | 50 px | `--mm-layout-search-orb: 50px` | `--spacing-search-orb` (`size-search-orb`) | `layoutSearchOrb` = `50.0` |
| `layout.accessoryHeight` | 48 px | `--mm-layout-accessory-height: 48px` | `--spacing-accessory-height` (`h-accessory-height`) | `layoutAccessoryHeight` = `48.0` |
| `layout.accessoryGap` | 8 px | `--mm-layout-accessory-gap: 8px` | `--spacing-accessory-gap` (`mb-accessory-gap`) | `layoutAccessoryGap` = `8.0` |
| `layout.navButton` | 44 px | `--mm-layout-nav-button: 44px` | `--spacing-nav-button` (`size-nav-button`) | `layoutNavButton` = `44.0` |
| `layout.sheetInset` | 8 px | `--mm-layout-sheet-inset: 8px` | `--spacing-sheet-inset` (`inset-sheet-inset`) | `layoutSheetInset` = `8.0` |
| `layout.sidebarWidth` | 280 px | `--mm-layout-sidebar-width: 280px` | `--spacing-sidebar-width` (`w-sidebar-width`) | `layoutSidebarWidth` = `280.0` |
| `layout.sidebarCollapsed` | 76 px | `--mm-layout-sidebar-collapsed: 76px` | `--spacing-sidebar-collapsed` (`w-sidebar-collapsed`) | `layoutSidebarCollapsed` = `76.0` |
| `layout.sidebarInset` | 12 px | `--mm-layout-sidebar-inset: 12px` | `--spacing-sidebar-inset` (`inset-sidebar-inset`) | `layoutSidebarInset` = `12.0` |
| `layout.readerStripMax` | clamp(480px, 50vw, 900px) | `--mm-layout-reader-strip-max: clamp(480px, 50vw, 900px)` | `--spacing-reader-strip` (`w-reader-strip`) | `layoutReaderStripMin` = `480.0`, `layoutReaderStripFraction` = `0.5`, `layoutReaderStripMax` = `900.0` |
| `layout.readerPanelLeft` | 300 px | `--mm-layout-reader-panel-left: 300px` | `--spacing-reader-panel-left` (`w-reader-panel-left`) | `layoutReaderPanelLeft` = `300.0` |
| `layout.readerPanelRight` | 360 px | `--mm-layout-reader-panel-right: 360px` | `--spacing-reader-panel-right` (`w-reader-panel-right`) | `layoutReaderPanelRight` = `360.0` |
| `layout.measureMax` | 88 ch | `--mm-layout-measure-max: 88ch` | `--spacing-measure-max` (`max-w-measure-max`) | `layoutMeasureMaxCh` = `88` |
| `layout.contentMax` | 1440 px | `--mm-layout-content-max: 1440px` | `--spacing-content-max` (`max-w-content-max`) | `layoutContentMax` = `1440.0` |
| `layout.detailWindow` | 960 px | `--mm-layout-detail-window: 960px` | `--spacing-detail-window` (`w-detail-window`) | `layoutDetailWindow` = `960.0` |
| `layout.sidePanel` | 440 px | `--mm-layout-side-panel: 440px` | `--spacing-side-panel` (`w-side-panel`) | `layoutSidePanel` = `440.0` |
| `layout.window` | 560 px | `--mm-layout-window: 560px` | `--spacing-window` (`w-window`) | `layoutWindow` = `560.0` |
| `layout.palette` | 640 px | `--mm-layout-palette: 640px` | `--spacing-palette` (`w-palette`) | `layoutPalette` = `640.0` |
| `bp.frame` | 768 px | `--mm-bp-frame: 768px` (documentation only; media queries use the literal) | shared `--breakpoint-frame: 48rem` (variant `frame:`) | `bpFrame` = `768.0` |
| `bp.desktop` | 1024 px | `--mm-bp-desktop: 1024px` (documentation only; media queries use the literal) | shared `--breakpoint-desktop: 64rem` (variant `desktop:`) | `bpDesktop` = `1024.0` |
| `bp.wide` | 1440 px | `--mm-bp-wide: 1440px` (documentation only; media queries use the literal) | shared `--breakpoint-wide: 90rem` (variant `wide:`) | `bpWide` = `1440.0` |

#### 2.8.3 Radius, blur, borders, light, z layers

| Key | Value | Web CSS property | Tailwind 4 `@theme` (utility) | Flutter `GlassTokens` field |
|---|---|---|---|---|
| `radius.capsule` | 9999 px | `--mm-radius-capsule: 9999px` | `--radius-capsule` (`rounded-capsule`) | `radiusCapsule` = `9999.0` |
| `radius.xs` | 6 px | `--mm-radius-xs: 6px` | `--radius-xs` (`rounded-xs`) | `radiusXs` = `6.0` |
| `radius.sm` | 10 px | `--mm-radius-sm: 10px` | `--radius-sm` (`rounded-sm`) | `radiusSm` = `10.0` |
| `radius.md` | 14 px | `--mm-radius-md: 14px` | `--radius-md` (`rounded-md`) | `radiusMd` = `14.0` |
| `radius.lg` | 20 px | `--mm-radius-lg: 20px` | `--radius-lg` (`rounded-lg`) | `radiusLg` = `20.0` |
| `radius.xl` | 26 px | `--mm-radius-xl: 26px` | `--radius-xl` (`rounded-xl`) | `radiusXl` = `26.0` |
| `radius.xxl` | 32 px | `--mm-radius-xxl: 32px` | `--radius-xxl` (`rounded-xxl`) | `radiusXxl` = `32.0` |
| `radius.sheet` | 36 px (runtime: device corner radius − 8 on phones) | `--mm-radius-sheet: 36px` | `--radius-sheet` (`rounded-sheet`) | `radiusSheet` = `36.0` |
| `radius.iconTile` | 12 px | `--mm-radius-icon-tile: 12px` | `--radius-icon-tile` (`rounded-icon-tile`) | `radiusIconTile` = `12.0` |
| `blur.film` | 2 px | `--mm-blur-film: 2px` | `--blur-film` (`blur-film`, `backdrop-blur-film`) | `blurFilm` = `2.0` (σ for `ImageFilter.blur`) |
| `blur.edge` | 6 px | `--mm-blur-edge: 6px` | `--blur-edge` (`blur-edge`, `backdrop-blur-edge`) | `blurEdge` = `6.0` (σ for `ImageFilter.blur`) |
| `blur.thin` | 8 px | `--mm-blur-thin: 8px` | `--blur-thin` (`blur-thin`, `backdrop-blur-thin`) | `blurThin` = `8.0` (σ for `ImageFilter.blur`) |
| `blur.regular` | 10 px | `--mm-blur-regular: 10px` | `--blur-regular` (`blur-regular`, `backdrop-blur-regular`) | `blurRegular` = `10.0` (σ for `ImageFilter.blur`) |
| `blur.context` | 12 px | `--mm-blur-context: 12px` | `--blur-context` (`blur-context`, `backdrop-blur-context`) | `blurContext` = `12.0` (σ for `ImageFilter.blur`) |
| `blur.thick` | 22 px | `--mm-blur-thick: 22px` | `--blur-thick` (`blur-thick`, `backdrop-blur-thick`) | `blurThick` = `22.0` (σ for `ImageFilter.blur`) |
| `blur.monolith` | 32 px | `--mm-blur-monolith: 32px` | `--blur-monolith` (`blur-monolith`, `backdrop-blur-monolith`) | `blurMonolith` = `32.0` (σ for `ImageFilter.blur`) |
| `blur.recede` | 8 px | `--mm-blur-recede: 8px` | `--blur-recede` (`blur-recede`, `backdrop-blur-recede`) | `blurRecede` = `8.0` (σ for `ImageFilter.blur`) |
| `blur.switch` | 40 px | `--mm-blur-switch: 40px` | `--blur-switch` (`blur-switch`, `backdrop-blur-switch`) | `blurSwitch` = `40.0` (σ for `ImageFilter.blur`) |
| `blur.fieldPhone` | 120 px | `--mm-blur-field-phone: 120px` | `--blur-field-phone` (`blur-field-phone`, `backdrop-blur-field-phone`) | `blurFieldPhone` = `120.0` (σ for `ImageFilter.blur`) |
| `blur.fieldDesktop` | 180 px | `--mm-blur-field-desktop: 180px` | `--blur-field-desktop` (`blur-field-desktop`, `backdrop-blur-field-desktop`) | `blurFieldDesktop` = `180.0` (σ for `ImageFilter.blur`) |
| `blur.reveal` | 12 px | `--mm-blur-reveal: 12px` | `--blur-reveal` (`blur-reveal`, `backdrop-blur-reveal`) | `blurReveal` = `12.0` (σ for `ImageFilter.blur`) |
| `border.hairline` | 0.5 px `color.separator` | `--mm-border-hairline: 0.5px solid var(--mm-color-separator)` | `border-[0.5px] border-separator` | `borderHairline` = `BorderSide(color: Color(0x8C545460), width: 0.5)` |
| `border.slab` | 1 px `rgba(255,255,255,0.06)` | `--mm-border-slab: 1px solid rgba(255,255,255,0.06)` | `border border-(--mm-border-slab-color)` | `borderSlab` = `BorderSide(color: Color(0x0FFFFFFF), width: 1)` |
| `border.focusRing` | 2 px `#000000` inner ring, then 2 px `iris300` at offset 2 px, outer glow 6 px `rgba(188,176,255,0.28)` | `--mm-border-focus-ring: 2px solid var(--mm-color-iris300)`; `--mm-focus-offset: 2px`; `--mm-focus-glow: 0 0 0 2px #000, 0 0 0 6px rgba(188,176,255,0.28)` | `focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-iris300 focus-visible:shadow-(--mm-focus-glow)` | `borderFocusRing` = `FocusRingSpec(width: 2, offset: 2, color: Color(0xFFBCB0FF), innerColor: Color(0xFF000000), innerWidth: 2, glow: 6, glowColor: Color(0x47BCB0FF))` |
| `border.selectedRing` | 2 px `iris500` inset | `--mm-border-selected-ring: inset 0 0 0 2px var(--mm-color-iris500)` | `ring-2 ring-inset ring-iris500` | `borderSelectedRing` = `BorderSide(color: Color(0xFF8F7EFF), width: 2)` |
| `border.errorRing` | 1.5 px `danger` | `--mm-border-error-ring: 1.5px solid var(--mm-color-danger)` | `border-[1.5px] border-danger` | `borderErrorRing` = `BorderSide(color: Color(0xFFFF5C5C), width: 1.5)` |
| `border.hc` | 1 px `rgba(255,255,255,0.55)` (Increase Contrast) | `--mm-border-hc: 1px solid rgba(255,255,255,0.55)` | `contrast-more:border contrast-more:border-white/55` | `borderHc` = `BorderSide(color: Color(0x8CFFFFFF), width: 1)` |
| `light.angle` | 135° (live ±25°) | `--mm-light-angle: 135deg` (runtime-updated, `@property <angle>`) | n/a (read by `GlassSurface`) | `lightAngle` = `135.0`, `lightRange` = `25.0` |
| `z.canvas` | `0` | `--mm-z-canvas: 0` | `z-(--mm-z-canvas)` | `zCanvas` = `0` (overlay order) |
| `z.field` | `1` | `--mm-z-field: 1` | `z-(--mm-z-field)` | `zField` = `1` (overlay order) |
| `z.content` | `2` | `--mm-z-content: 2` | `z-(--mm-z-content)` | `zContent` = `2` (overlay order) |
| `z.edge` | `3` | `--mm-z-edge: 3` | `z-(--mm-z-edge)` | `zEdge` = `3` (overlay order) |
| `z.controls` | `10` | `--mm-z-controls: 10` | `z-(--mm-z-controls)` | `zControls` = `10` (overlay order) |
| `z.overlays` | `20` | `--mm-z-overlays: 20` | `z-(--mm-z-overlays)` | `zOverlays` = `20` (overlay order) |
| `z.interruptions` | `30` | `--mm-z-interruptions: 30` | `z-(--mm-z-interruptions)` | `zInterruptions` = `30` (overlay order) |
| `z.hud` | `40` | `--mm-z-hud: 40` | `z-(--mm-z-hud)` | `zHud` = `40` (overlay order) |
| `z.takeover` | `50` | `--mm-z-takeover: 50` | `z-(--mm-z-takeover)` | `zTakeover` = `50` (overlay order) |
| `z.debug` | `90` | `--mm-z-debug: 90` | `z-(--mm-z-debug)` | `zDebug` = `90` (overlay order) |

#### 2.8.4 Materials: tiers, variants, dim, caustic

| Key | Value | Web CSS property | Tailwind 4 `@theme` (utility) | Flutter `GlassTokens` field |
|---|---|---|---|---|
| `glass.t1` | Film (thickness 12 · bezel 6 · displacement 6 · blur 2 · saturate 1.4 · fill `rgba(255,255,255,0.03)` · specular 0.55 · shadow `0 2px 8px rgba(0,0,0,0.35)` · dispersion 0 px · ROND 20) | `--mm-glass-t1-thickness: 12; -bezel: 6px; -displacement: 6; -blur: 2px; -saturate: 1.4; -fill: rgba(255,255,255,0.03); -specular: 0.55; -shadow: 0 2px 8px rgba(0,0,0,0.35); -dispersion: 0px; -rond: 20` | n/a (read by `GlassSurface` through `data-tier="t1"`) | `glassT1` = `GlassTier(thickness: 12, bezel: 6, displacement: 6, blur: 2, saturate: 1.4, fill: Color(0x08FFFFFF), specular: 0.55, shadow: BoxShadow(offset: Offset(0, 2), blurRadius: 8, color: Color(0x59000000)), dispersion: 0, rond: 20)` |
| `glass.t2` | Pane (thickness 20 · bezel 10 · displacement 10 · blur 8 · saturate 1.8 · fill `rgba(255,255,255,0.07)` · specular 0.42 · shadow `0 6px 20px rgba(0,0,0,0.45)` · dispersion 0 px · ROND 40) | `--mm-glass-t2-thickness: 20; -bezel: 10px; -displacement: 10; -blur: 8px; -saturate: 1.8; -fill: rgba(255,255,255,0.07); -specular: 0.42; -shadow: 0 6px 20px rgba(0,0,0,0.45); -dispersion: 0px; -rond: 40` | n/a (read by `GlassSurface` through `data-tier="t2"`) | `glassT2` = `GlassTier(thickness: 20, bezel: 10, displacement: 10, blur: 8, saturate: 1.8, fill: Color(0x12FFFFFF), specular: 0.42, shadow: BoxShadow(offset: Offset(0, 6), blurRadius: 20, color: Color(0x73000000)), dispersion: 0, rond: 40)` |
| `glass.t3` | Slab (thickness 24 · bezel 12 · displacement 12 · blur 10 · saturate 1.8 · fill `rgba(255,255,255,0.06)` · specular 0.40 · shadow `0 8px 24px rgba(0,0,0,0.50)` · dispersion 0 px · ROND 60) | `--mm-glass-t3-thickness: 24; -bezel: 12px; -displacement: 12; -blur: 10px; -saturate: 1.8; -fill: rgba(255,255,255,0.06); -specular: 0.40; -shadow: 0 8px 24px rgba(0,0,0,0.50); -dispersion: 0px; -rond: 60` | n/a (read by `GlassSurface` through `data-tier="t3"`) | `glassT3` = `GlassTier(thickness: 24, bezel: 12, displacement: 12, blur: 10, saturate: 1.8, fill: Color(0x0FFFFFFF), specular: 0.40, shadow: BoxShadow(offset: Offset(0, 8), blurRadius: 24, color: Color(0x80000000)), dispersion: 0, rond: 60)` |
| `glass.t4` | Block (thickness 40 · bezel 18 · displacement 18 · blur 22 · saturate 1.8 · fill `rgba(28,28,34,0.52)` · specular 0.30 · shadow `0 24px 64px rgba(0,0,0,0.60)` · dispersion 0.6 px · ROND 80) | `--mm-glass-t4-thickness: 40; -bezel: 18px; -displacement: 18; -blur: 22px; -saturate: 1.8; -fill: rgba(28,28,34,0.52); -specular: 0.30; -shadow: 0 24px 64px rgba(0,0,0,0.60); -dispersion: 0.6px; -rond: 80` | n/a (read by `GlassSurface` through `data-tier="t4"`) | `glassT4` = `GlassTier(thickness: 40, bezel: 18, displacement: 18, blur: 22, saturate: 1.8, fill: Color(0x851C1C22), specular: 0.30, shadow: BoxShadow(offset: Offset(0, 24), blurRadius: 64, color: Color(0x99000000)), dispersion: 0.6, rond: 80)` |
| `glass.t5` | Monolith (thickness 56 · bezel 24 · displacement 22 · blur 32 · saturate 1.7 · fill `rgba(22,22,28,0.60)` · specular 0.26 · shadow `0 40px 96px rgba(0,0,0,0.66)` · dispersion 1.2 px · ROND 100) | `--mm-glass-t5-thickness: 56; -bezel: 24px; -displacement: 22; -blur: 32px; -saturate: 1.7; -fill: rgba(22,22,28,0.60); -specular: 0.26; -shadow: 0 40px 96px rgba(0,0,0,0.66); -dispersion: 1.2px; -rond: 100` | n/a (read by `GlassSurface` through `data-tier="t5"`) | `glassT5` = `GlassTier(thickness: 56, bezel: 24, displacement: 22, blur: 32, saturate: 1.7, fill: Color(0x9916161C), specular: 0.26, shadow: BoxShadow(offset: Offset(0, 40), blurRadius: 96, color: Color(0xA8000000)), dispersion: 1.2, rond: 100)` |
| `glass.clear` | fill `rgba(255,255,255,0.02)` · blur 1 · saturate 1.4 · rim `rgba(255,255,255,0.28)` · specular 0.50 · no shadow | `--mm-glass-clear-fill: rgba(255,255,255,0.02); -blur: 1px; -saturate: 1.4; -rim: rgba(255,255,255,0.28); -specular: 0.50` | n/a (read by `GlassSurface` through `data-finish="clear"`) | `glassClear` = `GlassFinish(fill: Color(0x05FFFFFF), blur: 1, saturate: 1.4, rim: Color(0x47FFFFFF), specular: 0.50)` |
| `glass.tinted` | fill `rgba(117,99,242,0.86)` · blur 8 · saturate 1.6 · rim `rgba(255,255,255,0.30)` · specular `iris100` at 60 % · shadow `0 8px 24px rgba(117,99,242,0.35)` · pressed fill `rgba(91,74,209,0.86)` | `--mm-glass-tinted-fill: rgba(117,99,242,0.86); -fill-pressed: rgba(91,74,209,0.86); -blur: 8px; -saturate: 1.6; -rim: rgba(255,255,255,0.30); -specular: rgba(228,223,255,0.60); -shadow: 0 8px 24px rgba(117,99,242,0.35)` | n/a (read by `GlassSurface` through `data-finish="tinted"`) | `glassTinted` = `GlassFinish(fill: Color(0xDB7563F2), fillPressed: Color(0xDB5B4AD1), blur: 8, saturate: 1.6, rim: Color(0x4DFFFFFF), specularColor: Color(0x99E4DFFF), shadow: BoxShadow(offset: Offset(0, 8), blurRadius: 24, color: Color(0x597563F2)))` |
| `glass.solid1` | `#1C1C22`, 1 px rim `rgba(255,255,255,0.10)` | `--mm-glass-solid1: #1C1C22` | `bg-(--mm-glass-solid1)` | `glassSolid1` = `Color(0xFF1C1C22)` |
| `glass.solid2` | `#26262E`, 1 px rim `rgba(255,255,255,0.10)` | `--mm-glass-solid2: #26262E` | `bg-(--mm-glass-solid2)` | `glassSolid2` = `Color(0xFF26262E)` |
| `glass.materialThin` | `rgba(19,19,23,0.40)` + blur 12 | `--mm-glass-material-thin: rgba(19,19,23,0.40); --mm-glass-material-thin-blur: 12px` | `bg-(--mm-glass-material-thin) backdrop-blur-(--mm-glass-material-thin-blur)` | `glassMaterialThin` = `MaterialSpec(fill: Color(0x66131317), blur: 12)` |
| `glass.materialRegular` | `rgba(19,19,23,0.62)` + blur 24 | `--mm-glass-material-regular: rgba(19,19,23,0.62); --mm-glass-material-regular-blur: 24px` | `bg-(--mm-glass-material-regular) backdrop-blur-(--mm-glass-material-regular-blur)` | `glassMaterialRegular` = `MaterialSpec(fill: Color(0x9E131317), blur: 24)` |
| `glass.materialThick` | `rgba(19,19,23,0.84)` + blur 36 | `--mm-glass-material-thick: rgba(19,19,23,0.84); --mm-glass-material-thick-blur: 36px` | `bg-(--mm-glass-material-thick) backdrop-blur-(--mm-glass-material-thick-blur)` | `glassMaterialThick` = `MaterialSpec(fill: Color(0xD6131317), blur: 36)` |
| `dim.legibility` | `clamp(0.22 + 0.42 × Lb, 0.22, 0.64)` | `--mm-dim-min: 0.22; --mm-dim-slope: 0.42; --mm-dim-max: 0.64` (runtime `--glass-dim` per surface, `@property <number>`) | n/a (read by `GlassSurface`) | `dimMin` = `0.22`, `dimSlope` = `0.42`, `dimMax` = `0.64` |
| `dim.grad` | `round(40 × Lb)` on glass (+20 with Bold Text) | `--mm-grad-slope: 40` (runtime `--glass-grad`) | n/a | `gradSlope` = `40` |
| `caustic` | `iris500` at 14 % (pressed 22 %), ellipse 1.2 × 0.7 of the object, offset 8 px at the light angle, blur 18 px, `screen` | `--mm-caustic-alpha: 0.14; --mm-caustic-alpha-pressed: 0.22; --mm-caustic-blur: 18px; --mm-caustic-offset: 8px` | n/a (the `Caustic` primitive) | `causticAlpha` = `0.14`, `causticAlphaPressed` = `0.22`, `causticBlur` = `18.0`, `causticOffset` = `8.0` |

#### 2.8.5 Motion: springs, curves, physics and thresholds

| Key | Value | Web CSS property | Tailwind 4 `@theme` (utility) | Flutter `GlassTokens` field |
|---|---|---|---|---|
| `spring.track` | 150 ms, bounce 0.14 (k 1754.6, c 72.05) | `--mm-spring-track: linear(…)` (60 samples over the settle time, emitted by `build.mjs`) and `--mm-spring-track-ms: 203ms` | `--ease-spring-track` (`ease-spring-track` with `duration-(--mm-spring-track-ms)`) | Motion `{ type: "spring", stiffness: 1754.6, damping: 72.05, mass: 1 }` / `springTrack` = `SpringToken(ms: 150, bounce: 0.14)` |
| `spring.press` | 220 ms, bounce 0.2 (k 815.7, c 45.70) | `--mm-spring-press: linear(…)` (60 samples over the settle time, emitted by `build.mjs`) and `--mm-spring-press-ms: 297ms` | `--ease-spring-press` (`ease-spring-press` with `duration-(--mm-spring-press-ms)`) | Motion `{ type: "spring", stiffness: 815.7, damping: 45.70, mass: 1 }` / `springPress` = `SpringToken(ms: 220, bounce: 0.2)` |
| `spring.tick` | 260 ms, bounce 0.3 (k 584.0, c 33.83) | `--mm-spring-tick: linear(…)` (60 samples over the settle time, emitted by `build.mjs`) and `--mm-spring-tick-ms: 337ms` | `--ease-spring-tick` (`ease-spring-tick` with `duration-(--mm-spring-tick-ms)`) | Motion `{ type: "spring", stiffness: 584.0, damping: 33.83, mass: 1 }` / `springTick` = `SpringToken(ms: 260, bounce: 0.3)` |
| `spring.snappy` | 400 ms, bounce 0.15 (k 246.7, c 26.70) | `--mm-spring-snappy: linear(…)` (60 samples over the settle time, emitted by `build.mjs`) and `--mm-spring-snappy-ms: 429ms` | `--ease-spring-snappy` (`ease-spring-snappy` with `duration-(--mm-spring-snappy-ms)`) | Motion `{ type: "spring", stiffness: 246.7, damping: 26.70, mass: 1 }` / `springSnappy` = `SpringToken(ms: 400, bounce: 0.15)` |
| `spring.morph` | 380 ms, bounce 0.25 (k 273.4, c 24.80) | `--mm-spring-morph: linear(…)` (60 samples over the settle time, emitted by `build.mjs`) and `--mm-spring-morph-ms: 485ms` | `--ease-spring-morph` (`ease-spring-morph` with `duration-(--mm-spring-morph-ms)`) | Motion `{ type: "spring", stiffness: 273.4, damping: 24.80, mass: 1 }` / `springMorph` = `SpringToken(ms: 380, bounce: 0.25)` |
| `spring.tab` | 450 ms, bounce 0.22 (k 195.0, c 21.78) | `--mm-spring-tab: linear(…)` (60 samples over the settle time, emitted by `build.mjs`) and `--mm-spring-tab-ms: 558ms` | `--ease-spring-tab` (`ease-spring-tab` with `duration-(--mm-spring-tab-ms)`) | Motion `{ type: "spring", stiffness: 195.0, damping: 21.78, mass: 1 }` / `springTab` = `SpringToken(ms: 450, bounce: 0.22)` |
| `spring.lens` | 420 ms, bounce 0.3 (k 223.8, c 20.94) | `--mm-spring-lens: linear(…)` (60 samples over the settle time, emitted by `build.mjs`) and `--mm-spring-lens-ms: 528ms` | `--ease-spring-lens` (`ease-spring-lens` with `duration-(--mm-spring-lens-ms)`) | Motion `{ type: "spring", stiffness: 223.8, damping: 20.94, mass: 1 }` / `springLens` = `SpringToken(ms: 420, bounce: 0.3)` |
| `spring.sheet` | 480 ms, bounce 0.08 (k 171.3, c 24.09) | `--mm-spring-sheet: linear(…)` (60 samples over the settle time, emitted by `build.mjs`) and `--mm-spring-sheet-ms: 494ms` | `--ease-spring-sheet` (`ease-spring-sheet` with `duration-(--mm-spring-sheet-ms)`) | Motion `{ type: "spring", stiffness: 171.3, damping: 24.09, mass: 1 }` / `springSheet` = `SpringToken(ms: 480, bounce: 0.08)` |
| `spring.sheetSnap` | 420 ms, bounce 0.12 (k 223.8, c 26.33) | `--mm-spring-sheet-snap: linear(…)` (60 samples over the settle time, emitted by `build.mjs`) and `--mm-spring-sheet-snap-ms: 399ms` | `--ease-spring-sheet-snap` (`ease-spring-sheet-snap` with `duration-(--mm-spring-sheet-snap-ms)`) | Motion `{ type: "spring", stiffness: 223.8, damping: 26.33, mass: 1 }` / `springSheetSnap` = `SpringToken(ms: 420, bounce: 0.12)` |
| `spring.page` | 520 ms, bounce 0 (k 146.0, c 24.17) | `--mm-spring-page: linear(…)` (60 samples over the settle time, emitted by `build.mjs`) and `--mm-spring-page-ms: 621ms` | `--ease-spring-page` (`ease-spring-page` with `duration-(--mm-spring-page-ms)`) | Motion `{ type: "spring", stiffness: 146.0, damping: 24.17, mass: 1 }` / `springPage` = `SpringToken(ms: 520, bounce: 0)` |
| `spring.zoom` | 560 ms, bounce 0.06 (k 125.9, c 21.09) | `--mm-spring-zoom: linear(…)` (60 samples over the settle time, emitted by `build.mjs`) and `--mm-spring-zoom-ms: 591ms` | `--ease-spring-zoom` (`ease-spring-zoom` with `duration-(--mm-spring-zoom-ms)`) | Motion `{ type: "spring", stiffness: 125.9, damping: 21.09, mass: 1 }` / `springZoom` = `SpringToken(ms: 560, bounce: 0.06)` |
| `spring.settle` | 350 ms, bounce 0 (k 322.3, c 35.90) | `--mm-spring-settle: linear(…)` (60 samples over the settle time, emitted by `build.mjs`) and `--mm-spring-settle-ms: 444ms` | `--ease-spring-settle` (`ease-spring-settle` with `duration-(--mm-spring-settle-ms)`) | Motion `{ type: "spring", stiffness: 322.3, damping: 35.90, mass: 1 }` / `springSettle` = `SpringToken(ms: 350, bounce: 0)` |
| `spring.minimize` | 400 ms, bounce 0 (k 246.7, c 31.42) | `--mm-spring-minimize: linear(…)` (60 samples over the settle time, emitted by `build.mjs`) and `--mm-spring-minimize-ms: 497ms` | `--ease-spring-minimize` (`ease-spring-minimize` with `duration-(--mm-spring-minimize-ms)`) | Motion `{ type: "spring", stiffness: 246.7, damping: 31.42, mass: 1 }` / `springMinimize` = `SpringToken(ms: 400, bounce: 0)` |
| `spring.dismiss` | 320 ms, bounce 0 (k 385.5, c 39.27) | `--mm-spring-dismiss: linear(…)` (60 samples over the settle time, emitted by `build.mjs`) and `--mm-spring-dismiss-ms: 411ms` | `--ease-spring-dismiss` (`ease-spring-dismiss` with `duration-(--mm-spring-dismiss-ms)`) | Motion `{ type: "spring", stiffness: 385.5, damping: 39.27, mass: 1 }` / `springDismiss` = `SpringToken(ms: 320, bounce: 0)` |
| `spring.camera` | 450 ms, bounce 0.1 (k 195.0, c 25.13) | `--mm-spring-camera: linear(…)` (60 samples over the settle time, emitted by `build.mjs`) and `--mm-spring-camera-ms: 445ms` | `--ease-spring-camera` (`ease-spring-camera` with `duration-(--mm-spring-camera-ms)`) | Motion `{ type: "spring", stiffness: 195.0, damping: 25.13, mass: 1 }` / `springCamera` = `SpringToken(ms: 450, bounce: 0.1)` |
| `spring.celebrate` | 600 ms, bounce 0.35 (k 109.7, c 13.61) | `--mm-spring-celebrate: linear(…)` (60 samples over the settle time, emitted by `build.mjs`) and `--mm-spring-celebrate-ms: 723ms` | `--ease-spring-celebrate` (`ease-spring-celebrate` with `duration-(--mm-spring-celebrate-ms)`) | Motion `{ type: "spring", stiffness: 109.7, damping: 13.61, mass: 1 }` / `springCelebrate` = `SpringToken(ms: 600, bounce: 0.35)` |
| `spring.drift` | 900 ms, bounce 0 (k 48.7, c 13.96) | `--mm-spring-drift: linear(…)` (60 samples over the settle time, emitted by `build.mjs`) and `--mm-spring-drift-ms: 1065ms` | `--ease-spring-drift` (`ease-spring-drift` with `duration-(--mm-spring-drift-ms)`) | Motion `{ type: "spring", stiffness: 48.7, damping: 13.96, mass: 1 }` / `springDrift` = `SpringToken(ms: 900, bounce: 0)` |
| `spring.letter` | 424 ms, bounce 0.12 (k 219.6, c 26.08) | `--mm-spring-letter: linear(…)` (60 samples over the settle time, emitted by `build.mjs`) and `--mm-spring-letter-ms: 402ms` | `--ease-spring-letter` (`ease-spring-letter` with `duration-(--mm-spring-letter-ms)`) | Motion `{ type: "spring", stiffness: 219.6, damping: 26.08, mass: 1 }` / `springLetter` = `SpringToken(ms: 424, bounce: 0.12)` |
| `spring.smooth` | 500 ms, bounce 0.1 (k 157.9, c 22.62) | `--mm-spring-smooth: linear(…)` (60 samples over the settle time, emitted by `build.mjs`) and `--mm-spring-smooth-ms: 490ms` | `--ease-spring-smooth` (`ease-spring-smooth` with `duration-(--mm-spring-smooth-ms)`) | Motion `{ type: "spring", stiffness: 157.9, damping: 22.62, mass: 1 }` / `springSmooth` = `SpringToken(ms: 500, bounce: 0.1)` |
| `curve.fadeIn` | 180 ms `cubic-bezier(0.2, 0, 0, 1)` | `--mm-ease-fade-in: cubic-bezier(0.2, 0, 0, 1); --mm-dur-fade-in: 180ms` | `--ease-fade-in` (`ease-fade-in duration-(--mm-dur-fade-in)`) | `curveFadeIn` = `CurveToken(ms: 180, curve: Cubic(0.2, 0, 0, 1))` |
| `curve.fadeOut` | 120 ms `cubic-bezier(0.4, 0, 1, 1)` | `--mm-ease-fade-out: cubic-bezier(0.4, 0, 1, 1); --mm-dur-fade-out: 120ms` | `--ease-fade-out` (`ease-fade-out duration-(--mm-dur-fade-out)`) | `curveFadeOut` = `CurveToken(ms: 120, curve: Cubic(0.4, 0, 1, 1))` |
| `curve.colorShift` | 240 ms `cubic-bezier(0.2, 0, 0, 1)` | `--mm-ease-color-shift: cubic-bezier(0.2, 0, 0, 1); --mm-dur-color-shift: 240ms` | `--ease-color-shift` (`ease-color-shift duration-(--mm-dur-color-shift)`) | `curveColorShift` = `CurveToken(ms: 240, curve: Cubic(0.2, 0, 0, 1))` |
| `curve.tintShift` | 900 ms `cubic-bezier(0.2, 0, 0, 1)` | `--mm-ease-tint-shift: cubic-bezier(0.2, 0, 0, 1); --mm-dur-tint-shift: 900ms` | `--ease-tint-shift` (`ease-tint-shift duration-(--mm-dur-tint-shift)`) | `curveTintShift` = `CurveToken(ms: 900, curve: Cubic(0.2, 0, 0, 1))` |
| `curve.dimShift` | 400 ms `cubic-bezier(0.2, 0, 0, 1)` | `--mm-ease-dim-shift: cubic-bezier(0.2, 0, 0, 1); --mm-dur-dim-shift: 400ms` | `--ease-dim-shift` (`ease-dim-shift duration-(--mm-dur-dim-shift)`) | `curveDimShift` = `CurveToken(ms: 400, curve: Cubic(0.2, 0, 0, 1))` |
| `curve.materialize` | 250 ms `cubic-bezier(0.2, 0, 0, 1)` | `--mm-ease-materialize: cubic-bezier(0.2, 0, 0, 1); --mm-dur-materialize: 250ms` | `--ease-materialize` (`ease-materialize duration-(--mm-dur-materialize)`) | `curveMaterialize` = `CurveToken(ms: 250, curve: Cubic(0.2, 0, 0, 1))` |
| `curve.dematerialize` | 350 ms `cubic-bezier(0.2, 0, 0, 1)` | `--mm-ease-dematerialize: cubic-bezier(0.2, 0, 0, 1); --mm-dur-dematerialize: 350ms` | `--ease-dematerialize` (`ease-dematerialize duration-(--mm-dur-dematerialize)`) | `curveDematerialize` = `CurveToken(ms: 350, curve: Cubic(0.2, 0, 0, 1))` |
| `curve.sweep` | 520 ms `cubic-bezier(0.2, 0, 0, 1)` | `--mm-ease-sweep: cubic-bezier(0.2, 0, 0, 1); --mm-dur-sweep: 520ms` | `--ease-sweep` (`ease-sweep duration-(--mm-dur-sweep)`) | `curveSweep` = `CurveToken(ms: 520, curve: Cubic(0.2, 0, 0, 1))` |
| `curve.followRing` | 700 ms `cubic-bezier(0.2, 0, 0, 1)` | `--mm-ease-follow-ring: cubic-bezier(0.2, 0, 0, 1); --mm-dur-follow-ring: 700ms` | `--ease-follow-ring` (`ease-follow-ring duration-(--mm-dur-follow-ring)`) | `curveFollowRing` = `CurveToken(ms: 700, curve: Cubic(0.2, 0, 0, 1))` |
| `curve.glowIn` | 150 ms linear | `--mm-dur-glow-in: 150ms` | `ease-linear duration-(--mm-dur-glow-in)` | `curveGlowIn` = `CurveToken(ms: 150, curve: Curves.linear)` |
| `curve.glowOut` | 60 ms linear | `--mm-dur-glow-out: 60ms` | `ease-linear duration-(--mm-dur-glow-out)` | `curveGlowOut` = `CurveToken(ms: 60, curve: Curves.linear)` |
| `curve.shimmer` | 1400 ms linear | `--mm-dur-shimmer: 1400ms` | `ease-linear duration-(--mm-dur-shimmer)` | `curveShimmer` = `CurveToken(ms: 1400, curve: Curves.linear)` |
| `curve.reducedCrossfade` | 150 ms linear | `--mm-dur-reduced-crossfade: 150ms` | `ease-linear duration-(--mm-dur-reduced-crossfade)` | `curveReducedCrossfade` = `CurveToken(ms: 150, curve: Curves.linear)` |
| `curve.reducedRoute` | 200 ms linear | `--mm-dur-reduced-route: 200ms` | `ease-linear duration-(--mm-dur-reduced-route)` | `curveReducedRoute` = `CurveToken(ms: 200, curve: Curves.linear)` |
| `curve.caretBlink` | 530 ms per phase, `steps(1)`, 3 blinks | `--mm-dur-caret-blink: 530ms` | `duration-(--mm-dur-caret-blink)` | `curveCaretBlink` = `CurveToken(ms: 530, curve: Threshold(0.5))` |
| `curve.typeStep` | 50 ms per grapheme | `--mm-dur-type-step: 50ms` | n/a | `curveTypeStep` = `Duration(milliseconds: 50)` |
| `curve.letterStagger` | 24 ms per grapheme (40 ms per word above 60 graphemes) | `--mm-dur-letter-stagger: 24ms` | n/a | `curveLetterStagger` = `Duration(milliseconds: 24)` |
| `physics.decelerationRate` | 0.998 per ms | `--mm-physics-deceleration-rate: 0.998` (TypeScript constant) | n/a | `physicsDecelerationRate` = `0.998` |
| `physics.rubberBandC` | `0.55` | `--mm-physics-rubber-band-c: 0.55` (TypeScript constant) | n/a | `physicsRubberBandC` = `0.55` |
| `physics.magnetRadius` | 64 px | `--mm-physics-magnet-radius: 64` (TypeScript constant) | n/a | `physicsMagnetRadius` = `64` |
| `physics.magnetPull` | 0.35 of the remaining distance per frame | `--mm-physics-magnet-pull: 0.35` (TypeScript constant) | n/a | `physicsMagnetPull` = `0.35` |
| `physics.waveSpeed` | 1.6 px/ms | `--mm-physics-wave-speed: 1.6` (TypeScript constant) | n/a | `physicsWaveSpeed` = `1.6` |
| `physics.waveMaxDelay` | 240 ms | `--mm-physics-wave-max-delay: 240` (TypeScript constant) | n/a | `physicsWaveMaxDelay` = `240` |
| `physics.hapticMinInterval` | 40 ms | `--mm-physics-haptic-min-interval: 40` (TypeScript constant) | n/a | `physicsHapticMinInterval` = `40` |
| `physics.impactVelocityDivisor` | 4000 px/s | `--mm-physics-impact-velocity-divisor: 4000` (TypeScript constant) | n/a | `physicsImpactVelocityDivisor` = `4000` |
| `physics.depthIntensityBase` | `0.30` | `--mm-physics-depth-intensity-base: 0.30` (TypeScript constant) | n/a | `physicsDepthIntensityBase` = `0.30` |
| `physics.depthIntensityStep` | 0.08 per level | `--mm-physics-depth-intensity-step: 0.08` (TypeScript constant) | n/a | `physicsDepthIntensityStep` = `0.08` |
| `physics.projectionCap` | 1 viewport length | `--mm-physics-projection-cap: 1.0` (TypeScript constant) | n/a | `physicsProjectionCap` = `1.0` |
| `threshold.dragSlopTouch` | 10 px (18 px inside Flutter scroll views) | `--mm-threshold-drag-slop-touch: 10` (TypeScript constant) | n/a | `thresholdDragSlopTouch` = `10` |
| `threshold.dragSlopMouse` | 3 px | `--mm-threshold-drag-slop-mouse: 3` (TypeScript constant) | n/a | `thresholdDragSlopMouse` = `3` |
| `threshold.tapMax` | 450 ms | `--mm-threshold-tap-max: 450` (TypeScript constant) | n/a | `thresholdTapMax` = `450` |
| `threshold.liftStart` | 150 ms | `--mm-threshold-lift-start: 150` (TypeScript constant) | n/a | `thresholdLiftStart` = `150` |
| `threshold.liftMenu` | 450 ms | `--mm-threshold-lift-menu: 450` (TypeScript constant) | n/a | `thresholdLiftMenu` = `450` |
| `threshold.doubleTapWindow` | 280 ms / 24 px | `--mm-threshold-double-tap-window: 280` (TypeScript constant) | n/a | `thresholdDoubleTapWindow` = `280` |
| `threshold.backSwipeFraction` | 0.5 of the width | `--mm-threshold-back-swipe-fraction: 0.5` (TypeScript constant) | n/a | `thresholdBackSwipeFraction` = `0.5` |
| `threshold.sheetDismissVelocity` | 1500 px/s | `--mm-threshold-sheet-dismiss-velocity: 1500` (TypeScript constant) | n/a | `thresholdSheetDismissVelocity` = `1500` |
| `threshold.rowCommitFraction` | 0.6 of the row | `--mm-threshold-row-commit-fraction: 0.6` (TypeScript constant) | n/a | `thresholdRowCommitFraction` = `0.6` |
| `threshold.pullTrigger` | 100 raw px (rest 60) | `--mm-threshold-pull-trigger: 100` (TypeScript constant) | n/a | `thresholdPullTrigger` = `100` |
| `threshold.chapterArm` | 48 displayed px | `--mm-threshold-chapter-arm: 48` (TypeScript constant) | n/a | `thresholdChapterArm` = `48` |
| `threshold.chapterCommit` | 72 displayed px | `--mm-threshold-chapter-commit: 72` (TypeScript constant) | n/a | `thresholdChapterCommit` = `72` |
| `threshold.imageDismiss` | 180 px or 800 px/s | `--mm-threshold-image-dismiss: 180` (TypeScript constant) | n/a | `thresholdImageDismiss` = `180` |
| `threshold.throwVelocity` | 1200 px/s | `--mm-threshold-throw-velocity: 1200` (TypeScript constant) | n/a | `thresholdThrowVelocity` = `1200` |
| `threshold.holdConfirm` | 1200 ms | `--mm-threshold-hold-confirm: 1200` (TypeScript constant) | n/a | `thresholdHoldConfirm` = `1200` |
| `threshold.chromeHide` | 24 px down | `--mm-threshold-chrome-hide: 24` (TypeScript constant) | n/a | `thresholdChromeHide` = `24` |
| `threshold.chromeShow` | 56 px up | `--mm-threshold-chrome-show: 56` (TypeScript constant) | n/a | `thresholdChromeShow` = `56` |
| `threshold.chromeIdle` | 3000 ms | `--mm-threshold-chrome-idle: 3000` (TypeScript constant) | n/a | `thresholdChromeIdle` = `3000` |
| `threshold.stackLongPress` | 450 ms (web touch 500 ms) | `--mm-threshold-stack-long-press: 450` (TypeScript constant) | n/a | `thresholdStackLongPress` = `450` |
| `threshold.recapSeriesDays` | 7 days | `--mm-threshold-recap-series-days: 7` (TypeScript constant) | n/a | `thresholdRecapSeriesDays` = `7` |
| `threshold.recapChapterDays` | 3 days | `--mm-threshold-recap-chapter-days: 3` (TypeScript constant) | n/a | `thresholdRecapChapterDays` = `3` |
| `threshold.streakAtRiskHour` | 20:00 local | `--mm-threshold-streak-at-risk-hour: 20` (TypeScript constant) | n/a | `thresholdStreakAtRiskHour` = `20` |

Runtime colours (not tokens): `--amb-a1`, `--amb-a2`, `--amb-a3` (ambient blobs), `--amb-rim` (rim tint), `--page-tint`, `--page-top`, `--page-bottom`, `--glass-dim`, `--glass-grad`, `--glass-rond`, `--mm-light-angle` → Tailwind `@theme inline { --color-amb-a1: var(--amb-a1); … }` (`bg-amb-a1`, `text-page-tint`) → Flutter `GlassAmbient.of(context).a1 / .a2 / .a3 / .rim` and `ReaderEngineState.currentPageSample` (§15.4). Initial values: the profile mood colour (§2.1.6) and `Lb = 0.5`.

---

## 3. Type scale

### 3.1 Families (all from Google Fonts, all SIL Open Font License 1.1)

| Role | Family | Axes used | Licence | Delivery |
|---|---|---|---|---|
| UI, display and body | **Google Sans Flex** | `wght` 300 to 800, `opsz` 6 to 144, `ROND` 0 to 100, `GRAD` 0 to 100 (`slnt` and `wdth` pinned to 0 and 100) | OFL-1.1 | Web: `next/font/google` `Google_Sans_Flex({ subsets: ["latin"], axes: ["ROND", "GRAD", "opsz"], display: "swap", preload: true, variable: "--mm-font-sans" })`. Flutter: bundled subset `assets/fonts/GoogleSansFlexMM.ttf` (Latin + Latin Extended-A + punctuation, instanced with `fonttools varLib.instancer slnt=0 wdth=100`, keeping `wght`, `opsz`, `ROND`, `GRAD`), budget ≤ 720 KB; the font build script fails if the subset is larger and then drops Latin Extended-A, never an axis |
| Numerals that must not jitter, codes, keycaps | **Google Sans Code** | `wght` 300 to 800 | OFL-1.1 | Web `Google_Sans_Code({ variable: "--mm-font-mono", display: "swap" })`; Flutter bundled `GoogleSansCode.ttf` (126,224 B), family `GoogleSansCodeMM` |
| Novel reading face (default) | **Literata** | `opsz` 7 to 72, `wght` 200 to 900, italic | OFL-1.1 | Web `Literata({ axes: ["opsz"], style: ["normal", "italic"], preload: false, variable: "--mm-font-serif" })`, loaded when a novel route or a book page mounts; Flutter bundled `Literata.ttf` + italic (955,132 B upright), family `LiterataMM` |
| Novel alternative sans | Google Sans Flex at `ROND 0`, `opsz` = size | as above | OFL-1.1 | Already loaded |
| **Legible text** (the app-wide accessibility face, §3.6, and the third novel face) | **Atkinson Hyperlegible Next** | `wght` 200 to 800, italic | OFL-1.1 | Web `Atkinson_Hyperlegible_Next({ subsets: ["latin"], preload: false, display: "swap", variable: "--mm-font-legible" })`, never preloaded (the server cannot know the profile's setting), fetched as soon as the boot script stamps `data-legible="on"` and swapped in with `display: swap`; Flutter bundled `AtkinsonHyperlegibleNext.ttf` (the same asset Cinematic ships; one copy in `pubspec.yaml` `fonts:`), family `AtkinsonHyperlegibleNext` |
| CJK titles | Noto Sans KR, Noto Sans JP, Noto Sans SC | `wght` | OFL-1.1 | Web `preload: false` in the font stack (`var(--mm-font-sans), "Noto Sans KR", "Noto Sans JP", "Noto Sans SC", system-ui, sans-serif`); Flutter uses the system CJK fallback (Apple SD Gothic Neo, PingFang, Noto CJK on Android) and bundles nothing |

`ROND` is Meniscus's typographic physics: rounded terminals read as surface tension. Titles on content are fully round (`ROND 100`), body is sharp (`ROND 0`) for reading, weights in between interpolate, and text set **on glass** takes its roundness from the glass tier instead (§3.5). On press, a button label's `wght` rises by 40 over the `press` spring (Flutter animates `FontVariation('wght')`; web animates `font-variation-settings`), so a pressed word looks denser, as if compressed.

Every OFL `OFL.txt` ships with the app's licence list (Flutter `LicenseRegistry.addLicense`; web the build-time `licenses.json`; both shown in the licences sheet, `/settings/about?sheet=licenses`, §8.25.14). SF Pro and Roboto are deliberately not used: one family on all four platforms keeps the skin one object.

### 3.2 Type scale per breakpoint

Size / line height in px, weight, `ROND`, tracking in em. `opsz` always equals the rendered size (CSS `font-optical-sizing: auto`; Flutter passes `FontVariation('opsz', size)` explicitly). Text on glass takes `ROND` from its glass tier and `GRAD` from its backdrop (§3.5); the table's `ROND` applies to text on content.

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

### 3.3 Mobile text scale (Dynamic Type and Android font scale)

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

### 3.4 Novel reader type

| Control | Range | Default phone / desktop | Step |
|---|---|---|---|
| Face | Literata (serif) · Google Sans Flex `ROND 0` (sans) · Atkinson Hyperlegible Next (Legible) | Literata | n/a |
| Size | 15 to 30 px | 19 / 20 | 1 px, one haptic detent per step |
| Line height | 1.40 to 2.10 | 1.75 | 0.05 |
| Measure | 48 to 88 ch | 68 | 2 ch |
| Paragraph spacing | 0 to 1.2 em | 0.6 em | 0.1 em |
| Character spacing | −0.02 to +0.10 em | 0 | 0.01 em |
| Justify + hyphenate | on / off (`hyphens: auto`, `text-wrap: pretty`) | off | n/a |
| Bold text | on / off (Literata `wght` 400 → 520) | off | n/a |

Literata runs `opsz` = size and `wght` 400; chapter titles in Literata `opsz` 36, `wght` 560 at 1.55 × body size; the drop cap is Literata `wght` 620 at 3.1 em, 3 lines deep, only when the first paragraph has at least 80 characters.

### 3.5 Material-aware axes (text on glass)

Type is part of the material, so two axes follow the glass under it:

- **`ROND` follows thickness.** Text set on glass uses `ROND = 20 × tier` (T1 20, T2 40, T3 60, T4 80, T5 100), overriding the role's own `ROND`. A label on a thin nav button is crisp; the chapter title inside the listen full player is fully rounded. When glass grows between tiers (§2.4.2 rule 2), `ROND` interpolates with it. Text on content (black, slabs, pages) keeps the role's `ROND` from §3.2.
- **`GRAD` follows the backdrop.** Labels on glass add `GRAD = round(40 × Lb)`, using the same `Lb` as the legibility dim (§2.1.7). Grade thickens strokes without changing advance widths, so nothing reflows while a reader capsule slides from a black panel onto a white one; it animates with the dim over `dimShift` (400 ms). Text on content uses `GRAD 0`.
- **Bold Text** (iOS and Android accessibility, `MediaQuery.boldTextOf`; the web has no signal) adds `wght + 100` to every role and `GRAD + 20` to text on glass.
- **Implementation.** Web: glass surfaces set `--glass-rond` and `--glass-grad` custom properties (registered with `@property` as `<number>` so they interpolate), and `.on-glass { font-variation-settings: "ROND" var(--glass-rond), "GRAD" var(--glass-grad), "opsz" auto; }`. Flutter: `SkinGlass` provides a `GlassTextAxes` inherited widget (`rond`, `grad`) and every Glass text style resolves `FontVariation('ROND', rond)` and `FontVariation('GRAD', grad)` from it.

### 3.6 Legible text (Atkinson Hyperlegible Next, app-wide)

Settings → Appearance → **Legible text** (per profile, default off) swaps every UI role's family from Google Sans Flex to Atkinson Hyperlegible Next.

- **What changes.** Family only, plus tracking: every role gains +0.01 em (Atkinson's letterforms are wider and need no tightening). Sizes, line heights and weights stay (Atkinson's `wght` axis takes the same values). `ROND`, `GRAD` and `opsz` do not exist on Atkinson and are ignored, so text on glass keeps legibility through the dim alone (§2.1.7). Numerals in `mono` roles stay in Google Sans Code. The novel reader is unaffected unless the reader picks Atkinson as the reading face in the Type sheet (§8.15.5), where it is always offered.
- **Web.** The profile setting lives in the profile's scoped `mm.boot.a11y` entry (`legible: true`, see §8.0.8), so `appearance-boot-source.ts` stamps `<html data-legible="on">` before the first paint and the text faces swap to Atkinson as soon as it loads, with no animation; `[data-skin="glass"][data-legible="on"] { --mm-font-sans: var(--mm-font-legible); --mm-tracking-legible: 0.01em; }`.
- **Flutter.** `GlassTokens.legible` switches the `fontFamily` of every generated `GlassType` style to `AtkinsonHyperlegibleNext` and adds 0.01 em × size to `letterSpacing`; toggling it rebuilds the theme without a restart.
- **Where it shows the choice.** The Appearance row previews the sentence "Read the next chapter" in both faces; the command palette has "Legible text: on / off".

### 3.7 Type-role name map: web, Tailwind and Flutter side by side

Every role is one key `type.<role>` in `design/tokens/glass.json`. The web emits `--mm-type-<role>-size`, `-lh`, `-wght`, `-rond`, `-track` under `[data-skin="glass"]`, redefined inside the `frame`, `desktop` and `wide` media queries; the shared theme maps `--text-<role>: var(--mm-type-<role>-size)` with `--text-<role>--line-height: var(--mm-type-<role>-lh)` and an `@utility type-<role>` whose declarations are all `var()`s (`font-size`, `line-height`, `letter-spacing`, `font-variation-settings: "wght" var(--mm-type-<role>-wght), "ROND" var(--glass-rond, var(--mm-type-<role>-rond)), "GRAD" var(--glass-grad, 0)`), so the same utility name resolves per skin and never conflicts with Cinematic's roles. Families: `font-sans` → `var(--mm-font-sans)` (Google Sans Flex, or Atkinson with Legible text), `font-mono` → `var(--mm-font-mono)` (the `mono` and `monoLarge` roles), `font-serif` → `var(--mm-font-serif)` (novel reader). Flutter: `GlassTypeRole` fields on `GlassTokens` and a `GlassType` class that builds a `TextStyle` per role with `FontVariation`s, `letterSpacing = trackingEm × size`, and `TextScaler.clamp(maxScaleFactor: cap / size)` where a cap exists (§3.3).

| Key | Phone | Tablet | Desktop | Wide | wght | ROND | Tracking (em) | Scale cap | Web | Tailwind | Flutter field |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `type.display` | 44/48 | 52/56 | 64/68 | 72/76 | 720 | 100 | -0.025 | 56 px | `--mm-type-display-*` | `text-display`, `type-display` | `typeDisplay` = `GlassTypeRole(phone: (44, 48), tablet: (52, 56), desktop: (64, 68), wide: (72, 76), wght: 720, rond: 100, trackingEm: -0.025, capAt: 56)` |
| `type.largeTitle` | 34/40 | 36/42 | 40/46 | 44/50 | 700 | 100 | -0.02 | 48 px | `--mm-type-large-title-*` | `text-large-title`, `type-large-title` | `typeLargeTitle` = `GlassTypeRole(phone: (34, 40), tablet: (36, 42), desktop: (40, 46), wide: (44, 50), wght: 700, rond: 100, trackingEm: -0.02, capAt: 48)` |
| `type.title1` | 28/34 | 30/36 | 32/38 | 34/40 | 680 | 80 | -0.015 | 40 px | `--mm-type-title1-*` | `text-title1`, `type-title1` | `typeTitle1` = `GlassTypeRole(phone: (28, 34), tablet: (30, 36), desktop: (32, 38), wide: (34, 40), wght: 680, rond: 80, trackingEm: -0.015, capAt: 40)` |
| `type.title2` | 22/28 | 22/28 | 24/30 | 26/32 | 650 | 60 | -0.01 | 34 px | `--mm-type-title2-*` | `text-title2`, `type-title2` | `typeTitle2` = `GlassTypeRole(phone: (22, 28), tablet: (22, 28), desktop: (24, 30), wide: (26, 32), wght: 650, rond: 60, trackingEm: -0.01, capAt: 34)` |
| `type.title3` | 20/25 | 20/25 | 20/26 | 22/28 | 620 | 40 | -0.008 | none | `--mm-type-title3-*` | `text-title3`, `type-title3` | `typeTitle3` = `GlassTypeRole(phone: (20, 25), tablet: (20, 25), desktop: (20, 26), wide: (22, 28), wght: 620, rond: 40, trackingEm: -0.008)` |
| `type.headline` | 17/22 | 17/22 | 16/22 | 16/22 | 600 | 20 | -0.005 | none | `--mm-type-headline-*` | `text-headline`, `type-headline` | `typeHeadline` = `GlassTypeRole(phone: (17, 22), tablet: (17, 22), desktop: (16, 22), wide: (16, 22), wght: 600, rond: 20, trackingEm: -0.005)` |
| `type.body` | 17/24 | 17/24 | 16/24 | 16/24 | 420 | 0 | 0 | none | `--mm-type-body-*` | `text-body`, `type-body` | `typeBody` = `GlassTypeRole(phone: (17, 24), tablet: (17, 24), desktop: (16, 24), wide: (16, 24), wght: 420, rond: 0, trackingEm: 0)` |
| `type.callout` | 16/22 | 16/22 | 15/22 | 15/22 | 420 | 0 | 0 | none | `--mm-type-callout-*` | `text-callout`, `type-callout` | `typeCallout` = `GlassTypeRole(phone: (16, 22), tablet: (16, 22), desktop: (15, 22), wide: (15, 22), wght: 420, rond: 0, trackingEm: 0)` |
| `type.subhead` | 15/20 | 15/20 | 14/20 | 14/20 | 460 | 10 | 0.002 | none | `--mm-type-subhead-*` | `text-subhead`, `type-subhead` | `typeSubhead` = `GlassTypeRole(phone: (15, 20), tablet: (15, 20), desktop: (14, 20), wide: (14, 20), wght: 460, rond: 10, trackingEm: 0.002)` |
| `type.footnote` | 13/18 | 13/18 | 13/18 | 13/18 | 460 | 10 | 0.005 | none | `--mm-type-footnote-*` | `text-footnote`, `type-footnote` | `typeFootnote` = `GlassTypeRole(phone: (13, 18), tablet: (13, 18), desktop: (13, 18), wide: (13, 18), wght: 460, rond: 10, trackingEm: 0.005)` |
| `type.caption1` | 12/16 | 12/16 | 12/16 | 12/16 | 520 | 30 | 0.01 | none | `--mm-type-caption1-*` | `text-caption1`, `type-caption1` | `typeCaption1` = `GlassTypeRole(phone: (12, 16), tablet: (12, 16), desktop: (12, 16), wide: (12, 16), wght: 520, rond: 30, trackingEm: 0.01)` |
| `type.caption2` | 11/13 | 11/13 | 11/14 | 11/14 | 560 | 30 | 0.02 | none | `--mm-type-caption2-*` | `text-caption2`, `type-caption2` | `typeCaption2` = `GlassTypeRole(phone: (11, 13), tablet: (11, 13), desktop: (11, 14), wide: (11, 14), wght: 560, rond: 30, trackingEm: 0.02)` |
| `type.tabLabel` | 11/13 | 11/13 | n/a | n/a | 600 | 40 | 0.01 | none | `--mm-type-tab-label-*` | `text-tab-label`, `type-tab-label` | `typeTabLabel` = `GlassTypeRole(phone: (11, 13), tablet: (11, 13), desktop: null, wide: null, wght: 600, rond: 40, trackingEm: 0.01)` |
| `type.sidebarItem` | n/a | 15/20 | 14/20 | 14/20 | 520 | 20 | 0 | none | `--mm-type-sidebar-item-*` | `text-sidebar-item`, `type-sidebar-item` | `typeSidebarItem` = `GlassTypeRole(phone: null, tablet: (15, 20), desktop: (14, 20), wide: (14, 20), wght: 520, rond: 20, trackingEm: 0)` |
| `type.mono` | 13/18 | 13/18 | 13/18 | 13/18 | 500 | n/a (Code) | 0 | none | `--mm-type-mono-*` | `text-mono`, `type-mono` | `typeMono` = `GlassTypeRole(phone: (13, 18), tablet: (13, 18), desktop: (13, 18), wide: (13, 18), wght: 500, rond: null, trackingEm: 0)` |
| `type.monoLarge` | 22/26 | 22/26 | 22/26 | 22/26 | 600 | n/a (Code) | -0.01 | none | `--mm-type-mono-large-*` | `text-mono-large`, `type-mono-large` | `typeMonoLarge` = `GlassTypeRole(phone: (22, 26), tablet: (22, 26), desktop: (22, 26), wide: (22, 26), wght: 600, rond: null, trackingEm: -0.01)` |
| `type.numeral` | 40/44 | 44/48 | 48/52 | 56/60 | 720 | 100 | -0.02 | none | `--mm-type-numeral-*` | `text-numeral`, `type-numeral` | `typeNumeral` = `GlassTypeRole(phone: (40, 44), tablet: (44, 48), desktop: (48, 52), wide: (56, 60), wght: 720, rond: 100, trackingEm: -0.02)` |
| `type.wrappedNumeral` | 88/88 | 88/88 | 88/88 | 88/88 (in the 360 × 640 Wrapped frame, which scales as a whole, §9.2.3) | 720 | 100 | -0.03 | none (the frame scales, not the text) | `--mm-type-wrapped-numeral-*` | `text-wrapped-numeral`, `type-wrapped-numeral` | `typeWrappedNumeral` = `GlassTypeRole(phone: (88, 88), tablet: (88, 88), desktop: (88, 88), wide: (88, 88), wght: 720, rond: 100, trackingEm: -0.03)` |

`footnote` never renders below 11 px at any text scale. Font families: `font.sans` = Google Sans Flex (`--mm-font-sans`, Flutter `GoogleSansFlexMM`), `font.mono` = Google Sans Code (`--mm-font-mono`, `GoogleSansCodeMM`), `font.serif` = Literata (`--mm-font-serif`, `LiterataMM`), `font.legible` = Atkinson Hyperlegible Next (`--mm-font-legible`, `AtkinsonHyperlegibleNext`).

---

## 4. Motion

### 4.1 Laws

1. **Nothing moves without a cause.** Every animation starts from a touch, a key, a scroll, data arriving, or a route change. There are no idle loops except the ambient field drift and loading indicators.
2. **The finger owns position.** While touching, an object follows the finger 1:1 with no easing and no lag; the hand is never behind the glass.
3. **Springs own release.** On release, a spring takes over with the finger's exact velocity; timed curves are only for opacity and colour.
4. **Momentum is conserved across hand-offs.** When one motion becomes another (a lifted poster thrown up becomes the detail sheet; a scroll fling at the chapter end becomes the next-chapter card), the second starts with the first's velocity.
5. **Everything is catchable.** Any spring in flight can be grabbed: it stops where it is, its velocity passes to the finger tracker, and the new gesture continues from that exact state.
6. **Projection, not position, decides.** Where a thrown thing lands is decided by where it *would* stop (§4.4), so a short fast flick and a long slow drag both work.
7. **Every boundary is elastic.** Past a limit, displacement follows the rubber-band curve (§4.5), and the spring returns it.
8. **Thresholds are felt.** Crossing a commit line fires one haptic; crossing back fires a softer one. The user always knows before letting go.
9. **Mass decides speed.** Durations come from the object's mass class (§2.4.1), never from taste.
10. **No bounce on the way out.** Dismissals and exits use bounce 0; overshoot is only for arrivals and celebrations, and never above 0.35.

### 4.2 Springs

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
| `drift` | 900 | 0 | 48.7 | 13.96 | 1.00 | 1065 ms | 0 % | Ambient field blobs, hero parallax return, Wrapped background, presence drift |
| `letter` | 424 | 0.12 | 219.6 | 26.08 | 0.88 | 402 ms | 0.3 % | The heading letter reveal (§10.1) |
| `smooth` | 500 | 0.10 | 157.9 | 22.62 | 0.90 | 490 ms | 0.2 % | Large objects rotating or lifting in place: the stack fan, the Wrapped and stat-card flip, the recap deck lift-off, the skin-melt blur |

Reduce Motion replaces every spring above with a 150 to 200 ms opacity cross-fade (§4.11); the finger still tracks 1:1.

### 4.3 Velocity hand-off

- **Web.** Springs are emitted as physical `{ type: "spring", stiffness: k, damping: c, mass: 1 }` for Motion 13.4.4, **not** as `visualDuration/bounce`. Motion's duration-based springs discard inherited velocity ("time-defined springs should ignore inherited velocity" in `motion-dom`), while physical springs keep it, which is law 4. Gesture velocity comes from Motion's `PanInfo.velocity` (drag) or `useVelocity(motionValue)`; animations start with `animate(value, target, { ...spring, velocity })`.
- **CSS-only elements** (hover lifts, focus glows that need no velocity) use the same springs pre-sampled to `linear()` easing by `build.mjs` at 60 samples over the settle time.
- **Flutter.** `controller.animateWith(SpringSimulation(spring, controller.value, target, velocityInUnits))`, where `velocityInUnits = pxPerSecond / travelPx` for normalised controllers. Drag velocity comes from `DragEndDetails.velocity.pixelsPerSecond` (the framework's `VelocityTracker`, least-squares over the last 100 ms).
- **Retarget.** When a spring's target changes mid-flight (a second tap on another tab, a sheet dragged then released toward another detent), the new spring starts from the current value **and** current velocity. On web this is automatic with physical springs; on Flutter, read `controller.velocity` before calling `animateWith`.
- **Catch.** `pointerdown` on a moving object calls `controller.stop()` (Flutter) or `value.stop()` (Motion) and seeds the gesture's start offset from the current value, so the object does not jump to the finger.

### 4.4 Projection

Where a thrown object comes to rest is decided by projecting its motion with iOS's normal deceleration (`r = 0.998` per ms):

`projected = position + (velocity_px_per_s / 1000) × r / (1 − r)` = `position + 0.499 × velocity`

| Where | What is projected | Decision |
|---|---|---|
| Sheets | Sheet top edge | Nearest detent to the projected edge; below the lowest detent by more than 50 % of its height → dismiss |
| Tab droplet | Droplet centre | Nearest tab to the projected centre |
| Rails | Scroll offset | Rounded to a multiple of `posterWidth + gap` (rail snapping physics, §7.9) |
| Hero pager, voice orbit, Wrapped cards | Page offset | Nearest page, never more than one page per flick on the hero |
| Back swipe | Page x | Projected x past 50 % of the width → pop |
| Row swipe | Row x | Projected past 60 % of row width → commit the full-swipe action |
| Thrown poster (lifted) | Poster centre | Projected above the top 20 % of the screen → open detail; past a side edge → "Not interested" (AI cards only); onto a friend orb → recommend |
| Image viewer | Image y | Projected beyond ±180 px → dismiss |
| Reader scrub rail | Thumb y | Nearest page (the thumb snaps page by page) |

Projection is always capped at one screen length so a violent flick never skips content the user has not seen.

### 4.5 Rubber-banding

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
| Chapter end and series start in the reader | viewport height | commits at 72 displayed px (§8.14) |

### 4.6 Thresholds and timings

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
| Image dismiss | projected abs(dy) > 180 px or abs(vy) ≥ 800 px/s | `soft` 0.5 at the line |
| Throw to open (lifted poster) | projected centre above 20 % of screen height or vy ≤ −1200 px/s | `rigid` 0.7 |
| Throw away (AI card, lifted) | projected centre beyond a side edge or abs(vx) ≥ 1200 px/s | `rigid` 0.7 |
| Magnet capture (friend orb, detents with magnets) | within 64 px of the target centre | `selection` on capture, `soft` on release into it |
| Hold to confirm (the 18+ gate and destructive actions) | 1200 ms continuous hold | `hold.ramp` (`ahap:swell`, a transient every 150 ms rising 0.2 → 0.8), `hold.done` on completion |
| Long-press Back → stack overview or back menu | 450 ms (web touch 500 ms) | `stack.open` |
| Chrome auto-hide (reader) | 24 px cumulative downward scroll hides; 56 px cumulative upward scroll shows; 3000 ms idle after a tap-open hides | none |

### 4.7 Timed values (opacity and colour only)

| Token | Value | Use |
|---|---|---|
| `fadeIn` | 180 ms `cubic-bezier(0.2, 0, 0, 1)` | Content cross-fades, labels appearing |
| `fadeOut` | 120 ms `cubic-bezier(0.4, 0, 1, 1)` | Labels and glyphs leaving |
| `colorShift` | 240 ms `cubic-bezier(0.2, 0, 0, 1)` | Text colour on hover and state, tab label colour |
| `tintShift` | 900 ms `cubic-bezier(0.2, 0, 0, 1)` | Ambient field, rim tints (Light follows the story) and page-tinted chrome |
| `dimShift` | 400 ms `cubic-bezier(0.2, 0, 0, 1)` | The legibility dim and the label grade (§2.1.7, §3.5) |
| `sweep` | 520 ms `cubic-bezier(0.2, 0, 0, 1)` | The specular sweep (§2.4.4) |
| `followRing` | 700 ms `cubic-bezier(0.2, 0, 0, 1)` | The follow ring (§2.4.4) |
| `glowIn` / `glowOut` | 150 ms / 60 ms linear | Press glow |
| `materialize` / `dematerialize` | 250 ms / 350 ms `cubic-bezier(0.2, 0, 0, 1)` | Glass lensing ramp |
| `shimmer` | 1400 ms linear loop | Skeleton sheen |
| `caretBlink` | 530 ms step | Typing-reveal caret |
| `reducedCrossfade` | 150 ms (in-page) / 200 ms (routes, sheets) linear | Every Reduce Motion replacement |

### 4.8 Stagger: waves that radiate from the cause

Entrances are not index-ordered cascades; they ripple outward from whatever caused them, at a wave speed.

- **Delay rule.** `delay_i = min(distance_i / 1.6 px·ms⁻¹, 240 ms)`, where `distance_i` is the distance from the cause point to item `i`'s centre. The cause point is the touch point for tap-caused changes (filter chips, content-mode switch), the source element's centre for route arrivals (the tapped poster), and the top-left of the list for data arrivals (first load).
- **Each item** enters with opacity 0 → 1 over `fadeIn` and a spring translate of 12 px toward its rest position from the direction of the cause, plus scale 0.98 → 1, on `snappy`.
- **Cap.** Only items inside the viewport take part; anything that scrolls in later appears with no entrance at all. A wave never lasts more than 240 ms of delay plus one `snappy` settle (429 ms), so the last visible item is at rest within 670 ms.
- **Lists** (single column) use the same rule, which reduces to about 32 ms per 52 px row.
- **Heading letters** are not waves; they use the signature reveal (§10.1).
- **Exits** do not stagger: everything leaving goes together on `dismiss` or `fadeOut`.

### 4.9 Interruptibility contract

Every animated value in the skin is in one of four states, and every component in §7 follows these transitions:

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

### 4.10 The motion table (named choreography)

Every named move below is started through one helper per client (`play(name, …)` in `frontend/src/skins/glass/motion.ts`, `GlassMotion.play` in `mobile/lib/skins/glass/motion.dart`), so the names are also the labels the motion-timings overlay logs (§15.8). The last column is the move under Reduce Motion; §4.11 lists the rules that apply to everything. This table is exhaustive: a move that is not here does not exist in the skin. In development builds `play()` throws on a name that is not in this table (`GlassMotion.play` asserts), and the generated name union (`MotionName` in `motion.ts`, an enum in `motion.dart`) makes an unknown name a type error, so the table and the code cannot drift.

| Name | Duration | Spring or curve | Spec | Where used | Reduce Motion |
|---|---|---|---|---|---|
| **Materialise** | 250 ms lensing, opacity over the first 120 ms | `materialize` | Refraction 0 → 1, opacity 0 → 1 (§2.4.2 rule 1) | Every glass entrance | 150 ms opacity fade, full refraction from frame 0 |
| **Dematerialise** | 350 ms | `dematerialize` | The reverse | Every glass exit | 120 ms fade |
| **Press swell** | settle 297 ms | `press` | Glass grows +12 px (Medium) or +17 px (Feather, Light; capped at 0.35 × side), inner glow `glowIn` 150 / `glowOut` 60 ms, label `wght` +40 | Every glass control | Glow only |
| **Content sink** | settle 297 ms | `press` | Cards and posters 0.97, rows 0.99, chips 0.96, plain icons 0.92 | Every content press | Colour wash only (`fill2`) |
| **Stretch** | follows the finger | `track` | Up to 6 % along the drag axis, area conserved | Dragged glass (droplets, thumbs, knobs) | None (1:1 position kept) |
| **Bloom** | settle 485 ms | `morph` | The trigger's glass stretches into the menu, popover, small sheet or offer; content fades in over the last 40 %; tier interpolates (§2.4.2 rule 2) | Menus, split button, speed dial, sleep menu, recap offer, alerts opened from a control, the command palette from the sidebar capsule | 150 ms fade in place |
| **Push** | settle 621 ms | `page` | Incoming page 100 % → 0 from the trailing edge; outgoing moves −30 % and dims under `rgba(0,0,0,0.3)`; `nav.push` haptic at depth intensity | Every push | 200 ms cross-fade |
| **Pop** | settle 621 ms, or finger-driven | `page` (back gesture: 1:1, then `settle` or `dismiss` with the release velocity) | The reverse | Every pop | 200 ms cross-fade; the back swipe still tracks 1:1 |
| **Stack fan** | settle 490 ms | `smooth` | Snapshots of the current tab's levels fan in 3D: `rotateX(14°)` about the bottom edge, scale 0.62, 28 % vertical spacing, deepest at the top; picking one brings it forward on `zoom` while the levels above drop away front to back 40 ms apart | Flutter stack overview (§7.37) | A flat list of titles (the web menu), 200 ms fade |
| **Zoom** | settle 591 ms | `zoom` | Shared-element flight of a cover into its destination slot, carrying any throw velocity | Poster → series detail, collection card → collection, cover → image viewer, next-chapter card → chapter | 200 ms cross-fade |
| **Dive** | settle 591 ms | `zoom` | The row's or button's rectangle clip-reveals to full screen; the page behind scales to 0.94 and darkens to black; the first page fades in over the last 40 %; `reader.enter` haptic | Chapter row, Continue, history orb, bookmark row, dialogue result → reader | 200 ms cross-fade |
| **Book open** | settle 621 ms | `page` | The plate rotates open on its spine (`rotateY` 0 → −78°, perspective 900 px) while the paper expands from the plate's rectangle | Book page "Start reading" / "Continue" | 200 ms cross-fade |
| **Surface** | finger-driven, then `settle` or `dismiss` | `settle` / `dismiss` | The reader slides right over the recessed series sheet | Leaving a reader by the back swipe | Swipe tracks 1:1; release completes with a 150 ms fade |
| **Tab droplet** | settle 558 ms | `tab` | The selection droplet travels, stretching `scaleX = 1 + min(abs(v) / 2000, 0.25)`, `scaleY = 1 / √scaleX` | Dock, sidebar, choice chips, segmented thumbs, palette rows, in-page tab indicator | Droplet cross-fades 150 ms at the new place |
| **Tab switch** | 120 ms | `fadeIn` | Destination cross-fades in, its content wave radiates from the tapped tab | Dock and sidebar section changes | 120 ms fade, no wave |
| **Minimise** | settle 497 ms | `minimize` | Dock → 50 px capsule; reader bottom capsule → 32 px pill; accessory moves inline | Scrolling down 20 px (dock) or 24 px (reader) | Instant swap |
| **Sheet present** | settle 494 ms | `sheet` | From the trigger when it sits at the bottom (a Bloom), else from the bottom edge; the page behind recedes by sheet position | Every sheet | Fade + 16 px translate, 150 ms, no recession |
| **Sheet snap** | settle 399 ms | `sheetSnap` | Settles on the projected detent with the release velocity | Sheet drag release | 150 ms fade to the projected detent |
| **Recede** | driven by sheet position | none (1:1 to position) | Page behind a large-detent sheet: scale 0.94, radius 12, blur 8, 60 % brightness | Large sheets, series detail on phone | Dim only, no scale or blur |
| **Toast fall** | in settle 429 ms, out settle 411 ms | `snappy` / `dismiss` | Falls from 60 px above while materialising; leaves upward | Toasts, the global new-chapters capsule | 150 ms fade |
| **Wave** | per item `min(distance / 1.6, 240)` ms delay + settle 429 ms | `snappy` + `fadeIn` | 12 px translate from the cause, scale 0.98 → 1 (§4.8) | First data paint of every list, grid and rail | Everything fades together over 150 ms |
| **Surface from depth** | settle 429 ms | `snappy` | A group arrives from behind the page: scale 0.94 → 1, brightness 0.4 → 1, appended at the end (never reorders what is on screen) | Search tier-2 source groups, late AI rails | 150 ms fade |
| **Deal** | 40 ms spacing, settle 429 ms each | `snappy` | Result cards fly out of the Ask button along a short arc into their slots; the `why` line types in at 12 ms per character | For you answers | Cards fade in together; `why` lines shown whole |
| **Letter reveal** | 24 ms stagger, settle 402 ms per letter, glint 500 ms | `letter` + `fadeIn` | §10.1 | Headings listed in §10.1 | Full text immediately, no glint |
| **Typing reveal** | 50 ms per grapheme; caret on `track`; 3 blinks of 530 ms; caret out 350 ms | step clock + `tick` + `track` | §10.2 | Main headlines listed in §10.2 | Full text immediately, no caret |
| **Word stream** | 120 ms fade per word as it arrives | `fadeIn` | Opacity 0 → 1, no movement | Recap deck text (§9.1.3) | Words appear without the fade |
| **Light follows the story** | 900 ms | `tintShift` | Ambient blobs, every glass rim tint and the dock droplet tint slide to the new cover's colours | Home spotlight paging, picker orb focus, series sheet opening | 200 ms cross-fade |
| **Dim shift** | 400 ms | `dimShift` | `dimLegibility` and label `GRAD` follow a new `Lb` | Every glass surface over art | Instant change |
| **Step into the light** | 1,100 ms total | `celebrate` (inflate), `dismiss` (repel impulses), `tintShift` (colour pour, 600 ms), `zoom` (flight) | §8.5 | Profile picker | 200 ms cross-fade to the destination |
| **Throw** | projected, settle 591 ms | `zoom` with the release velocity | §4.4 projection decides the outcome | Lifted posters, the hero card, AI cards (away) | The outcome happens with a 150 ms fade |
| **Catch** | immediate | none | The running spring stops where it is; its velocity seeds the finger tracker | Any spring in flight (sheets, droplet, toasts, pages, zooms before 80 %) | Same (catching is not motion) |
| **Rubber band** | while stretched; return settle 444 ms | `settle` | `d × (1 − 1 / (x × 0.55 / d + 1))` (§4.5) | Every boundary | Hard stop at the limit |
| **Meniscus refresh** | pull-driven, snap settle 528 ms | `lens` | The droplet hangs on a thinning neck, snaps free at 100 raw px, springs to the 60 px rest line | Pull to refresh | A static spinner at the rest line once triggered |
| **Scrub lens** | grow settle 528 ms, follow 1:1 with `track` lag | `lens` / `track` | A T4 magnifier grows out of the thumb and follows it | Reader scrub rail | Lens appears in place (150 ms fade), follows 1:1 |
| **Chapter card rise** | position-driven; commit then settle 591 ms | none, then `zoom` with the carried velocity | Rises with the pull; locks at 72 displayed px; zooms into the chapter, which starts scrolling with the fling's remaining velocity | Manga chapter end (one at a time), novel end | Card appears at the lock, 200 ms cross-fade into the chapter, no carried momentum |
| **Seam chip** | materialise, hold 1,200 ms, dematerialise | `materialize` / `dematerialize` | "Chapter 144" chip under the nav row as the seam passes the top | Continuous strip | 150 ms fade in and out |
| **Cruise ramp** | 400 ms | linear speed ramp | Speed 0 → target (and on resume after 800 ms) | Cruise | No ramp; starts at speed |
| **Panel camera** | settle 445 ms | `camera` with the swipe velocity | The page layer translates and scales to frame the next panel; the lens edge bends the dimmed art so the next panel shows as a refracted sliver before the camera arrives | Guided view | Cut with a 120 ms cross-fade; no sliver |
| **Hit lens** | travel settle 445 ms; magnify settle 528 ms | `camera` / `lens` | A T1 lens slides bubble to bubble and magnifies the matched line 1.0 → 1.12 | Dialogue overlay match navigation | The lens appears at the new bubble with a 120 ms fade; magnification without growth |
| **Page slide** | settle 621 ms or finger-driven | `page` | The page follows the finger 1:1, 8 px soft shadow on its moving edge, projection decides | Paged manga and novel page turns (Slide) | 160 ms cross-fade |
| **Page lift** | settle 621 ms or finger-driven | `page` | `rotateY` 0 → −100° around the spine at perspective 1600 px, a specular band crossing the turning page, the page beneath un-dims 0.85 → 1 | Novel paged mode, Lift turn | 160 ms cross-fade |
| **Paper ripple** | settle 621 ms | `page` | The new paper spreads from the chosen orb as a circular clip reveal | Novel paper change | 200 ms cross-fade |
| **Liquid fill** | settle 528 ms | `lens` | A level with a 3 px meniscus sloshes once to its new value | Downloads meter, storage, liquid progress, quota meter, tier progress | Values jump; no meniscus wobble |
| **Hold fill** | 1,200 ms linear; drains on `dismiss` | linear / `dismiss` | Liquid rises left to right in the capsule | Hold-to-confirm (§7.1) | The fill steps in 4 visible increments with no meniscus |
| **Skin melt** | 620 ms (the three parts run together) | `dematerialize` (350 ms), `smooth` (blur 0 → 40 px, settle 490 ms), `page` (circular mask closing, settle 621 ms) | §8.25.2 step 4 | Leaving Glass | 200 ms fade to black |
| **Droplet reveal** | 1,200 ms cold, 400 ms warm | gravity 9,000 px/s², `lens`, spring k 180 / c 22, `letter`, `zoom` | §12.4 | Splash, skin-switch arrival | 200 ms cross-fade from the neutral mark |
| **Card flip** | settle 490 ms | `smooth` | `rotateY` 0 → 180° to the share side (perspective 1200 px); back the same way | Wrapped and stat-card Export (§9.2.4) | Cross-fade 200 ms between the two sides |
| **Deck lift-off** | settle 490 ms | `smooth` | The front card lifts toward the viewer (scale 1 → 1.06, translateY −40 px) and away upward, revealing the next card rising from 0.94 | Recap deck cards | 150 ms cross-fade between cards |
| **Story stack** | settle 621 ms | `page` with the swipe velocity | The next card waits beneath at scale 0.94 and 60 % brightness and rises as the top card leaves | Wrapped | 200 ms cross-fade |
| **Thinking orbit** | 1,400 ms per revolution, loop | linear | Three dots on a tilted ellipse (§7.38) | Every AI loading state | The three dots pulse in sequence in place (opacity 0.4 ↔ 1, 1.2 s) |
| **Caustic press** | in 150 ms, out 60 ms | `glowIn` / `glowOut` | Caustic alpha 14 → 22 % | The lit action | None |
| **Follow ring** | 700 ms | `followRing` | §2.4.4 | Add to library on series detail | None |
| **Specular sweep** | 520 ms | `sweep` | §2.4.4 | Glass entrances, the lit action becoming enabled | None |
| **Streak flare** | settle 723 ms; embers 900 ms | `celebrate` | Flame 1 → 1.3 → 1; 8 embers rise with 300 px/s² upward acceleration | Streak +1 | The count changes; the toast appears |
| **Record sparks** | 900 ms | linear rise, `fadeOut` | 6 `streakCore` sparks rise 40 px from the flame tip | New longest streak | None |
| **Goal ring close** | ring on `snappy`, solid fill 600 ms | `snappy` / `fadeIn` | The goal ring closes and fills solid, then returns to a stroke | Daily goal met | Ring jumps to full |
| **Reaction bloom and arc** | bloom settle 528 ms; flight by gravity 2,400 px/s²; land settle 337 ms | `lens` / ballistic / `tick` | §9.3.2 | Reactions | Bubbles appear in place; the chosen glyph appears in the strip with a 150 ms fade |
| **Presence drift** | settle 1,065 ms | `drift` | Orbs move forward (reading now) or back (older activity) along the arc | Circle presence arc | Orbs placed without travel |
| **Live ring breathe** | 2,400 ms loop | sine | `bloom` ring opacity 0.5 ↔ 1 | Reading-now orbs | Static ring at 1 |
| **Rain on glass** | 4 s per droplet run | linear gravity path with a 15 % lateral wobble | 6 to 10 droplets (radius 3 to 6 px) run down the reader capsules and pill, refracting the page | Reader with the Rain soundscape | Off |
| **Bead flicker** | 120 ms | linear | Opacity 1 → 0.3 → 1 once | A failing source's bead when a new probe lands | Colour change only |
| **Bead pulse** | settle 337 ms | `tick` | 1 → 1.3 → 1 | Healthy backend bead on each 15 s poll | None |
| **Genre field** | continuous | position-based dynamics (4 iterations/frame), restitution 0.4, centre pull k 4 | §8.7 step 4 | Onboarding | Bubbles at rest in a grid; taps change size without spring |
| **Density reflow** | settle 429 ms | `snappy` | Grid items travel to their new cells from their pinched positions | Library pinch density | Instant reflow |
| **Pin fly** | settle 591 ms | `zoom` | The pinned row travels into its slot in Pinned; the list closes the gap on `snappy` | Sources | Instant move |
| **Fan open** | settle 723 ms | `celebrate` | The four stacked covers spread to 0°, ±12°, ±24° | Collection card → detail | None |
| **Drain** | settle 528 ms | `lens` | A removed series' segment drains out of the liquid meter | Downloads | Value jumps |
| **Ambient drift** | settle 1,065 ms every 14 s | `drift` | Blobs move within ±6 % of their anchors | Ambient field | Frozen |
| **Light follow** | per frame | `track` | Specular angle follows gyroscope or pointer (±25°) | Every glass rim | Pinned at 135° |
| **Hero tilt** | per frame | `track` | ±6° toward the pointer or with the gyroscope | Home hero card, poster hover on desktop | Off |
| **Orb idle drift** | 5 to 7 s loops | sine | ±3 px, random phase | Profile picker orbs | Frozen |
| **Lens bob** | 6 s loop | sine | 2 px vertical | Empty, error and offline object lenses | Frozen |
| **Error shake** | 420 ms | damped sine | `x(t) = 8 × e^(−t / 90 ms) × sin(2π × 7 Hz × t)` (6 px for fields) | Buttons, fields, the reaction that failed | No shake; the error text only |
| **Skeleton shimmer** | 1,400 ms loop (2,800 ms for AI) | linear | Sheen band 40 % wide, phase-offset 60 ms per row | Skeletons | Static `surface2` |
| **Title capsule** | settle 429 ms | `materialize` + `snappy` | Large title scales into the nav-row capsule; capsule scales 0.9 → 1 | Every scrolled large title | 150 ms cross-fade |
| **Dock merge** | follows the drag | `track` | Metaball neck between the dock and the search orb when closer than 12 px | Dock drag toward search | No merge; release on the orb still opens search |
| **Address drain** | settle 591 ms | `zoom` (text), `lens` (lens swell) | The field's text scales to 0.2 and travels into the lens centre while the lens swells 1 → 1.2 and flashes its rim; then the lens expands to fill the screen on `zoom`, revealing Login | Setup success (§8.1) | 200 ms cross-fade to Login |
| **Slab condense** | settle 591 ms | `fadeOut` (contents), `zoom` (slab), gravity 3,000 px/s² (droplet fall) | Contents fade; the slab shrinks into a 24 px droplet at the lens position; the droplet falls into the lens with `logo.land` | Login and Register success (§8.3, §8.4) | 200 ms cross-fade to the picker |
| **Lens split** | settle 723 ms per orb, 40 ms apart | `celebrate` | The lens divides into the profile orbs, each springing out to its slot along a straight path | Login → picker (§8.3) | Orbs fade in at their slots |
| **Field ripple** | 600 ms | `fadeIn` curve on radius and opacity | A ring 12 % brighter than the field expands from the spotlight card's centre to the farthest screen corner and fades to 0 | Home first paint (§8.8) | None |
| **Orbiting covers** | 9 s per revolution, loop | linear angle, each cover on its own `drift` phase | Three continue covers orbit the source lens at radius 80 px behind it in the ambient field | Source catalogue "Opening" lens (§8.11) | Covers static at 0°, 120°, 240° |
| **Orb lift** | settle 591 ms | `zoom` | The dock's You orb lifts out of the dock and lands in the profile block (first arrival per session) | You tab (§8.24) | 200 ms cross-fade |
| **Dots merge** | settle 429 ms (merge), then a 400 ms fall | `snappy`, then gravity 3,000 px/s² and `tick` on landing | The seven progress dots slide together into one droplet, which falls into the dock's Home tab or the sidebar's Home item | Onboarding step 7 (§8.7) | 200 ms cross-fade to Home |
| **Cover arc** | 420 ms flight, settle 337 ms landing | parabolic arc (gravity 3,000 px/s²), then `tick` | A 36 × 54 copy of the tapped cover arcs from its row into the header's fanned stack; the stack makes room on `snappy` | Collection detail "Add series" (§8.18), onboarding avatar pick (§8.6) | The stack gains the cover with a 150 ms fade |
| **Orbs fly out** | settle 591 ms, 40 ms apart | `zoom` | The selected friend orbs leave the recommend sheet along a curve toward the top edge and dematerialise | Recommend sheet send (§9.3.4) | Sheet closes with a 150 ms fade |
| **Tag flight** | settle 591 ms | `zoom` | A tapped genre tag's text travels from the series sheet into the catalogue's genre chip during the push | Genre tag → catalogue (§8.11) | 200 ms cross-fade |
| **Plus one** | settle 723 ms in, 1,200 ms hold, `fadeOut` | `celebrate` | A "+1" `caption1` 700 chip in `streakCore` rises 12 px from the streak chip and fades | Home streak chip on Streak +1 (§9.2.2) | The count changes with a 150 ms fade |
| **Row pulse** | 900 ms | `fadeOut` curve on the fill | The focused row's `iris600` fill at 14 % fades to 0 once | Book page TOC focus (§8.13), settings search hit (§8.25) | Fill shown for 900 ms, then removed with no fade |
| **Skin preview** | 6 s loop | the animated WebP's own frames | The skin's looping preview of Home | Onboarding step 2 (§8.7), Settings → Appearance (§8.25.1) | The still first frame (`skin-{id}-still.png`) with a "Play preview" button |

### 4.11 Reduce Motion, Reduce Transparency, Increase Contrast

**Sources of each setting** (any one source turns it on):

| Setting | OS signal | In-app override (Settings → Appearance) | Web first paint |
|---|---|---|---|
| Reduce Motion | Web `prefers-reduced-motion: reduce`; Flutter `MediaQuery.disableAnimationsOf(context)` (iOS Reduce Motion, Android "Remove animations") | **Reduce motion in this app** (per profile) | `data-motion="reduced"` stamped before paint by `appearance-boot-source.ts` from the OS query and the profile's scoped `mm.boot.a11y` entry (§8.0.8); Motion `<MotionConfig reducedMotion="user">` plus the attribute. Flutter reads both sources through one `glassMotionPrefsProvider` (`reduced = disableAnimationsOf(context) \|\| inAppReduce`) |
| Reduce Transparency | Web `prefers-reduced-transparency: reduce`; iOS `UIAccessibility.isReduceTransparencyEnabled` read through the `mm/platform` channel method `reduceTransparency`; Android has no system signal | **Solid glass** (per profile) | `data-solid="on"` from the same `mm.boot.a11y` entry |
| Increase Contrast | Web `prefers-contrast: more`; Flutter `MediaQuery.highContrastOf(context)` (iOS only: Android has no public high-contrast signal for apps) | **Increase contrast** (per profile, next to Solid glass; the only source on Android) | CSS media query, or `data-contrast="more"` from `mm.boot.a11y` |
| Forced colours | Web `forced-colors: active` (Windows High Contrast) | none | CSS media query only |

**Reduce Motion rules** (the per-move replacements are the last column of the motion table, §4.10; these rules apply everywhere):

| Behaviour | Default | Reduce Motion |
|---|---|---|
| Finger tracking (drags, scrubs, back swipe, sheet drag, pinch, reorder) | 1:1 | 1:1 (direct manipulation is not decoration) |
| Release after a drag | Spring with velocity | 150 ms cross-fade to the projected outcome (projection still decides where it lands) |
| Press | Growth + stretch + glow | Glow only |
| Route push and pop, zooms, dives, book open, stack fan | `page` / `zoom` / `smooth` | 200 ms cross-fade |
| Sheets | `sheet` slide with recession | Fade + 16 px translate, 150 ms, no background scale or blur |
| Menus, blooms | `morph` from the trigger | 150 ms fade in place |
| Tab droplet | `tab` travel with stretch | Jumps; droplet cross-fades 150 ms |
| Dock and reader capsule minimise | `minimize` morph | Instant swap |
| Rubber band | Elastic | Hard stop at the limit (content stops, no stretch) |
| Stagger waves, surface from depth, deal | On | Off; everything fades together over 150 ms |
| Letter reveal and typing reveal | On | Full text immediately, no glint, no caret |
| Ambient drift, light follow, hero tilt, orb drift, lens bob, flame flicker, live ring breathe, rain on glass | On | Frozen (static at their rest values) |
| Colour transitions (ambient, page tint, dim) | 400 to 900 ms curves | 200 ms cross-fade (ambient, tint); the dim changes instantly |
| Celebrations (streak flare, record sparks, reaction burst, collection fan, podium drop in Wrapped) | On | Off; the end state appears with a 150 ms fade |
| Physics simulations (genre field, Wrapped page pile) | Live | At rest from the first frame |
| Looping previews (the skin previews in onboarding and Appearance) | Animated WebP, 6 s loop | The still first frame with a "Play preview" button; Solid glass does not affect them |
| Auto-advance (Wrapped cards, recap "Previously" pill timer) | On | On (it is timing, not motion); the recap pill still leaves after 6 s |
| Cruise auto-scroll | Starts from the reader's command, ramps over 400 ms | Never starts on its own; starts when asked, with no ramp |
| Haptics | On | On (haptics are not motion) |
| UI sounds | Per setting | Per setting |

**Reduce Transparency and Solid glass** swap every glass variant for `solid1` (T1 to T3) or `solid2` (T4 and T5) with the same shape, the same springs, a 1 px `rgba(255,255,255,0.10)` rim and the inner light kept at `S × 0.5`; soft scroll edges become hard ones; the caustic, dispersion, specular sweep, rain on glass and the ambient blobs behind chrome are removed (the ambient field stays behind content at half opacity); `dimLegibility` is unused because the surfaces are opaque; page-tinted chrome keeps the tint on the solid chrome's rim only.

**Increase Contrast** adds `hcBorder` (1 px `rgba(255,255,255,0.55)`) to every glass surface and slab, replaces `label2` with `label1` and `label3` with `label2`, uses `iris300` instead of `iris400` for accent text, raises `dimLegibility`'s floor from 0.22 to 0.40 and its ceiling from 0.64 to 0.72, and draws focus rings at 3 px.

**Forced colours** (web only): glass surfaces become `Canvas` with a 1 px `CanvasText` border, the tinted action becomes `ButtonText` on `ButtonFace` with a 2 px `Highlight` border, focus rings use `Highlight`, and decorative layers (ambient field, caustic, glints) are removed with `forced-color-adjust: auto`; icons keep `currentColor`.

---

## 5. Haptics

Haptics are the other half of the physics: detents, thresholds, impacts and textures. Character: **fingertip on wet glass**: high sharpness (0.7 to 1.0), low to medium intensity (0.3 to 0.7), many small crisp ticks, and weight that scales with speed and depth. Everything routes through one `GlassHaptics` service per client (`mobile/lib/skins/glass/haptics.dart` over the shared `mobile/lib/skins/skin_haptics.dart`; `frontend/src/skins/glass/haptics.ts`) that honours the **Haptics** switch (Settings → Sound & haptics, per device, default on), rate-limits ticks to one per 40 ms and impacts to one per 120 ms (a burst keeps the strongest), and never fires on plain navigation taps inside a screen, on scrolling, on hover, on focus or on a toast appearing. Every haptic is paired with a visible change (WCAG: never the only signal). Haptics stay on under Reduce Motion.

**Libraries** (`stack-decision.md` §3): iOS through `gaimon` 1.5.0 (named impacts with intensity, and AHAP patterns via `Gaimon.patternFromData(json)`) and `haptic_feedback` 0.6.5 (`selection`); Android through the `mm/platform` method channel for the API 34 constants (with API guards), `gaimon`'s waveform conversion of the same AHAP JSON, and `haptic_feedback` for `selection` on older APIs. Web: Android Chrome only, through `navigator.vibrate` for the seven events marked below (the same deliberate exception to `stack-decision.md` §2.1's "the web maps them to nothing" that `cinematic/DESIGN.md` §5 makes); iOS Safari and desktop get none.

### 5.1 Primitives

The pattern names `design/tokens/glass.json` maps events to:

| Pattern | iOS | Android API 34+ (via `mm/platform`) | Android API 24–33 |
|---|---|---|---|
| `selection` | `UISelectionFeedbackGenerator` | `SEGMENT_TICK` | `CLOCK_TICK` |
| `soft(i)` | Impact `.soft`, intensity i | `VIRTUAL_KEY` | `VIRTUAL_KEY` |
| `light` | Impact `.light` | `VIRTUAL_KEY` | `VIRTUAL_KEY` |
| `medium` | Impact `.medium` | `LONG_PRESS` | `LONG_PRESS` |
| `heavy` | Impact `.heavy` | `CONTEXT_CLICK` | `CONTEXT_CLICK` |
| `rigid(i)` | Impact `.rigid`, intensity i | `GESTURE_THRESHOLD_ACTIVATE` | `CONTEXT_CLICK` |
| `rigidBack` | Impact `.soft` 0.3 | `GESTURE_THRESHOLD_DEACTIVATE` | `VIRTUAL_KEY` |
| `toggleOn` / `toggleOff` | Impact `.rigid` 0.5 / `.soft` 0.4 | `TOGGLE_ON` / `TOGGLE_OFF` | `VIRTUAL_KEY` / none |
| `dragStart` | Impact `.light` | `DRAG_START` | `VIRTUAL_KEY` |
| `success` | Notification `.success` | `CONFIRM` (API 30+) | `VIRTUAL_KEY` |
| `warning` | Notification `.warning` | `KEYBOARD_TAP` | `KEYBOARD_TAP` |
| `error` | Notification `.error` | `REJECT` (API 30+) | `LONG_PRESS` |
| `ahap:*` | Core Haptics pattern via `gaimon` | gaimon's waveform conversion of the same JSON | same |

**Velocity-scaled impacts.** Throws, flings past a threshold and catches of an object in flight scale their intensity with speed: `i = clamp(0.3 + |v| / 4000, 0.3, 1.0)`. A lazy flick taps; a hard throw thuds. **On Android** the API 34 constants carry no intensity, so every velocity- or depth-scaled event (`rigid(i)`, `soft(i)`, `throw.commit`, `motion.catch`, `nav.push`) plays a one-shot gaimon waveform instead of the constant: a single 12 ms pulse at amplitude `round(i × 255)` (`VibrationEffect.createOneShot(12, amp)` underneath). The constants are used only for the fixed-strength patterns, and on API < 26 (no amplitude control) the table's API 24–33 column applies unscaled.

**Depth-scaled navigation.** Arriving at a deeper level weighs more: a push to depth `d` (1 to 4; the tab root is depth 0 and the reader counts as one level) fires `nav.push` at `I = 0.30 + 0.08 × d` (0.38, 0.46, 0.54, 0.62). A push that was itself a throw (a lifted poster thrown up into its series) takes `max(0.30 + 0.08 × d, 0.3 + |v| / 4000)`, so depth and velocity feed the same impact.

**Textures.** Continuous drags over stepped values tick once per step, but when steps pass faster than 25 per second the service thins them to every second or third step, so a fast scrub feels like a smooth grain rather than a buzz.

### 5.2 Events

The `HapticEvent` enum in `design/contract.json` is the union of both skins' events. Glass maps every name; "none" means Glass never fires it (the other skin may).

| Event | When it fires in Glass | Pattern | Android web |
|---|---|---|---|
| `nav.change` | Dock tab or sidebar section changes (touch devices) | `selection` | — |
| `nav.scrub` | The dock droplet is dragged across a tab | `selection` (textured) | — |
| `nav.reselect` | Tapping the active tab (pop to root or scroll to top) | `soft(0.4)` | — |
| `nav.push` | A screen is pushed (arriving at depth d) | `ahap:rise{d}` at `0.30 + 0.08 × d` | — |
| `nav.pop` | A screen is popped by a button, a key or a completed back swipe | `soft(0.5)` | — |
| `nav.root` | Pop to root (tab reselect, stack overview "Home of this tab") | `selection` × n levels, 40 ms apart (max 4) | — |
| `stack.open` | The stack overview (Flutter) or the back menu (web) opens | `ahap:fan` | `[18]` |
| `stack.pick` | A level is chosen in the stack overview | `medium` | — |
| `reader.enter` | A dive into either reader lands | `ahap:dive` | — |
| `tap.primary` | The tinted action activates (Read, Continue, Download, Ask, Save) | `soft(0.6)` | — |
| `tap.secondary` | Secondary, plain and icon buttons | none | — |
| `select` | Chips, segmented controls (including each boundary crossed during a thumb drag), choice rows, menu rows under a sliding finger, sleep-timer options | `selection` | — |
| `toggle.on` / `toggle.off` | Switches and checkboxes | `toggleOn` / `toggleOff` | `[10]` / — |
| `detent.tick` | Stepped sliders, steppers, dials, the speed dial and the interval slider, one per step | `selection` (textured) | — |
| `detent.magnet` | A value snaps into a magnet (speed 1.0×, cruise 1.0×, the 30-minute check interval) | `rigid(0.4)` | — |
| `detent.limit` | A slider or stepper hits its end and starts rubber-banding | `soft(0.5)` | — |
| `press.lift` | Long-press growth begins (150 ms) | `soft(0.4)` | — |
| `longpress.open` | A context menu or lifted preview blooms (450 ms) | `medium` | `[18]` |
| `throw.commit` | A lifted poster is thrown to open, away ("Not interested") or into a friend orb | `rigid` (velocity-scaled) | — |
| `motion.catch` | A finger catches an object in flight (sheet, droplet, toast, a zoom before 80 %) | `soft` (velocity-scaled, capped at 0.5) | — |
| `magnet.capture` | A dragged object enters a magnet radius (friend orb, collection target) | `selection` | — |
| `magnet.drop` | Released into a magnet | `ahap:magnet` | — |
| `reorder.lift` / `reorder.pass` / `reorder.drop` | Drag to reorder: pick up / pass a slot / drop | `dragStart` / `selection` / `soft(0.5)` | — |
| `sheet.pass` | Each detent passed during a sheet drag | `selection` | — |
| `sheet.detent` | A sheet settles after a drag | `soft(0.5)` | — |
| `sheet.dismiss` | A sheet is dismissed | none (`threshold.cross` already fired at the line) | — |
| `threshold.cross` | A drag crosses a commit line: sheet dismiss, image dismiss, back swipe, row full swipe | `rigid(0.6)` | — |
| `threshold.back` | The same drag crosses back | `rigidBack` | — |
| `refresh.arm` | The pull-to-refresh neck snaps | `medium` | — |
| `refresh.fire` | Release starts the refresh | none | — |
| `refresh.done` | A refresh returned new data (nothing when nothing changed) | `selection` | — |
| `undo` | Undo pressed in a toast | `light` | — |
| `delete.confirm` | A destructive confirm pressed in an alert | `warning` | — |
| `hold.ramp` | Hold-to-confirm in progress | `ahap:swell` (step by step) | — |
| `hold.done` | Hold-to-confirm completes | `success` | — |
| `chapter.arm` | The chapter-end pull arms (48 displayed px) | `soft(0.5)` | — |
| `chapter.next` | The pull commits (72 px), the next-chapter card is thrown up, a sideways chapter swipe commits, or a chapter is picked from the mini player swipe | `rigid(0.8)` | — |
| `chapter.seam` | The continuous strip carries a chapter seam across the reading line | `medium` | — |
| `chapter.complete` | The last page of a chapter is reached | none (reading stays quiet until the pull) | — |
| `scrub.tick` | The scrub rail passes a page | `selection` (textured) | — |
| `scrub.boundary` | The scrub rail hits the first or last page, or a chapter boundary in read-all | `rigid(0.6)` | — |
| `zoom.snap` | Double-tap zoom | `light` | — |
| `zoom.limit` | Pinch reaches 1× or the maximum and starts rubber-banding | `soft(0.4)` | — |
| `page.turn` | A paged page turn committed by swipe, tap or key (manga paged and novel paged) | `selection` | — |
| `panel.step` | Guided view moves one panel | `soft(0.3)` | — |
| `ocr.hit` | The hit lens jumps to the next or previous dialogue match | `selection` | — |
| `reader.unlock` | Five centre taps unlock locked controls | `medium` | — |
| `autoscroll.start` | Cruise spins up | `ahap:cruise` | — |
| `autoscroll.toggle` | Cruise paused or resumed by the reader | `soft(0.4)` | — |
| `autoscroll.step` | Cruise speed passes a 0.25× detent | `selection` | — |
| `autoscroll.end` | Cruise reaches the end of available pages | `medium` | — |
| `follow.add` | Added to the library, or a series added to a collection | `success` | `[12, 60, 12]` |
| `follow.remove` | Removed from the library | `light` | — |
| `favorite` | Star on or off | `light` | — |
| `bookmark.add` | Bookmark saved | `success` | — |
| `download.start` | A download queued | `selection` | — |
| `download.done` | A chapter or a batch finished (a batch fires once) | `success` | — |
| `download.fail` | A chapter failed after its retries | `error` | `[24, 50, 24]` |
| `listen.toggle` | Narration play or pause | `soft(0.6)` | — |
| `voice.center` | The voice orbit settles on a voice | `selection` | — |
| `voice.assign` | "Use this voice" | `success` | — |
| `sleep.fade` | The sleep timer starts its 8 s fade | `soft(0.3)` | — |
| `recap.ready` | A recap finished while the reader was elsewhere (the "Recap ready" toast) | `success` | — |
| `recap.countdown.end` | (Cinematic's recap countdown) | none | — |
| `streak.extend` | Streak +1 (the first chapter finished on a new day) | `ahap:ignite` | — |
| `streak.milestone` | 7, 30, 100 or 365 days | `ahap:shimmer` twice, 180 ms apart | `[12]` |
| `goal.met` | Daily goal reached | `success`, then `ahap:shimmer` 180 ms later | — |
| `annual.page` | A Wrapped card changes | `selection` | — |
| `share.lift` | A stat card lifts for sharing | `medium` | — |
| `share.flip` | The card flips to its share side | `rigid(0.5)` | — |
| `share.export` | The share image was rendered | `success` | — |
| `reaction.bloom` | The reaction picker blooms (hold 300 ms) | `medium` | — |
| `reaction.cross` | The finger crosses a reaction bubble | `selection` | — |
| `reaction.send` | A reaction is released onto a chapter | `ahap:pop` | — |
| `recommend.send` | A letter (recommend-to) is delivered | `success` | — |
| `profile.select` | The chosen profile orb lands in the dock or sidebar | `ahap:droplet` | — |
| `gate.confirm` | 18+ confirmed | `ahap:unlock` | — |
| `skin.switch` | The restart into another skin is confirmed | `heavy` | — |
| `logo.land` / `logo.settle` | Splash droplet lands / lens settles | `ahap:droplet` / `ahap:splash` | — |
| `success` | Generic success toast | `success` | — |
| `warning` | Offline, storage nearly full, rate-limited | `warning` | — |
| `error` | A form or action error with the shake | `error` | `[24, 50, 24, 50, 24]` |

Never haptic in Glass: scrolling (including cruise), reader chrome show and hide, hover, focus, toasts appearing, the typing and letter reveals, page-tint and ambient changes, the ambient drift, countdown ticks, the voice sample's pulse.

### 5.3 AHAP signatures

Transients `T` and continuous events `C` only, because gaimon's Android conversion ignores attack and decay; `I` = intensity, `S` = sharpness, `t` in seconds. The patterns ship as JSON assets in `mobile/assets/haptics/glass/*.ahap.json`, generated by `design/build.mjs` from `design/tokens/glass.json`.

| Name | Events | Feel |
|---|---|---|
| `droplet` | T@0.000 I0.55 S0.85; T@0.070 I0.25 S0.95 | A drop landing and its echo |
| `splash` | T@0.000 I0.70 S0.80; C@0.020 dur 0.100 I0.25 S0.95 | A lens settling with a short ring |
| `magnet` | T@0.000 I0.40 S0.90; T@0.050 I0.70 S0.80 | Pulled in, then clicked home |
| `unlock` | C@0.000 dur 0.120 I0.40 S0.85; T@0.120 I0.70 S0.90 | A latch sliding, then releasing |
| `shimmer` | T@0.00 I0.25, T@0.04 I0.30, T@0.08 I0.35, T@0.12 I0.40, T@0.16 I0.45, all S0.90 | Rising sparkle |
| `pop` | T@0.000 I0.50 S1.00; T@0.050 I0.25 S1.00 | A bubble bursting |
| `ignite` | C@0.000 dur 0.280 I0.35 S0.50; T@0.280 I0.90 S0.70 | A flame catching |
| `swell` | T every 0.150 s for 8 steps, I 0.20 → 0.80 and S 0.60 → 0.90 linearly (played step by step while the hold continues, so releasing stops it) | Pressure building |
| `cruise` | C@0.000 dur 0.180 I0.25 S0.30; T@0.180 I0.40 S0.60 | A flywheel spinning up |
| `rise1` … `rise4` | C@0.000 dur 0.120 I(0.5 × I_d) S0.70; T@0.120 I(I_d) S0.85, with `I_d = 0.30 + 0.08 × d` (four generated files) | Surfacing one level deeper, heavier each level |
| `fan` | T@0.00 I0.30 S0.90; T@0.05 I0.38 S0.90; T@0.10 I0.46 S0.90; T@0.15 I0.54 S0.85 | Cards fanning out one by one |
| `dive` | C@0.000 dur 0.300 I0.35 S0.30; T@0.300 I0.55 S0.60 | Sinking into the page, then landing |

**"Feel it."** Settings → Sound & haptics has a "Feel it" row beside the Haptics switch that plays `selection`, `soft(0.5)`, `rigid(0.6)`, `ahap:droplet` and `success` 400 ms apart, so the owner can judge strength. It is disabled with the caption "Turn haptics on to feel them." while the switch is off, and absent on the web.

---

## 6. UI sounds ("Meniscus", off by default)

A small tonal palette of struck-glass and water sounds, **off by default**, switched on in Settings → Sound & haptics → "UI sounds" (per device), with a volume slider (−24 to 0 dB, default −6 dB) and a "Hear it" row that plays `tap`, `push-1` … `push-4`, `back` and `add` in sequence. All synthesized, no samples, no licensing.

- **Scale:** A-major pentatonic: A5 880.00 · B5 987.77 · C♯6 1108.73 · E6 1318.51 · F♯6 1479.98 · A6 1760.00 Hz, so any sequence resolves.
- **Timbre:** "struck glass": a sine fundamental plus a partial at 2.76 × (the first overtone ratio of a free bar) at −14 dB, exponential decay; water events use a rising sine chirp (a bubble's resonance rises as it shrinks).
- **Physics:** pitch and level follow velocity and depth. A throw's whoosh centre frequency is `1200 + min(|v|, 3000) × 0.6` Hz (played through `playbackRate`); scrub ticks rise up to +3 semitones with scrub speed; a catch is a damped, muted tick. **Pitch rises with navigation depth**: pushing to depth 1, 2, 3 and 4 plays `push-1` … `push-4`, each landing one scale step higher (B5, C♯6, E6, F♯6), and popping plays `back`, the reverse glide from the current depth, so push-push-pop is a small rising and falling phrase.
- **Levels:** ticks −30 dBFS, taps −26, navigation −26, confirmations −18, the logo −12. 5 ms fades on every file.

Sounds fire on the same contract event names as haptics (`design/contract.json` `SoundEvent` is the set of event names that sound in either skin); each skin's token file maps an event to its own cue file.

| Cue (`glass/*.wav`) | Events | Recipe (sox) | Length | Peak |
|---|---|---|---|---|
| `tap` | `tap.primary` | sine 1760 Hz + the 2.76 partial, decay 18 ms | 24 ms | −26 dBFS |
| `tick` | `select`, `detent.tick`, `sheet.pass`, `scrub.tick` (rate-pitched), `nav.scrub`, `annual.page`, `page.turn` | sine 2640 Hz, decay 6 ms | 8 ms | −30 dBFS |
| `toggle-on` / `toggle-off` | `toggle.on` / `toggle.off` | C♯6 → E6 / E6 → C♯6, 50 ms each | 110 ms | −24 dBFS |
| `sheet-up` / `sheet-down` | `sheet.open` / `sheet.close` (sound-only events, fired when any sheet presents or closes) | sine glide 520 → 1040 Hz / reverse, 110 ms | 120 ms | −28 dBFS |
| `push-1` … `push-4` | `nav.push` at depth 1 to 4 | sine glide from one scale step below to B5 / C♯6 / E6 / F♯6, 90 ms, struck-glass attack | 100 ms | −26 dBFS |
| `back` | `nav.pop` | the reverse glide of the current depth, 80 ms, 3 dB quieter | 90 ms | −29 dBFS |
| `root` | `nav.root` | descending run E6 → C♯6 → A5, 40 ms steps | 140 ms | −26 dBFS |
| `fan` | `stack.open` | four grains A5, C♯6, E6, A6, 30 ms apart | 140 ms | −26 dBFS |
| `dive` | `reader.enter` | A4 440 Hz sine swell, 280 ms, low-pass sweeping 3 kHz → 600 Hz (the only downward sound: sinking into the page) | 300 ms | −22 dBFS |
| `droplet` | `refresh.arm`, `logo.land` | sine chirp 700 → 1400 Hz, 60 ms, fast decay | 80 ms | −24 dBFS |
| `throw` | `throw.commit` (centre frequency by velocity) | band-passed pink noise, Q 1.4, 90 ms | 100 ms | −24 dBFS |
| `catch` | `motion.catch`, `magnet.capture` | sine 440 Hz, decay 12 ms, low-passed 1.5 kHz | 20 ms | −30 dBFS |
| `add` | `follow.add`, `bookmark.add`, `voice.assign`, `recap.ready`, `magnet.drop` | A5 + E6 struck-glass dyad | 400 ms | −18 dBFS |
| `download-done` | `download.done`, `share.export`, `hold.done` | A5, C♯6, E6 arpeggio, 45 ms steps | 360 ms | −18 dBFS |
| `error` | `error`, `download.fail` | E5 659.25 → C♯5 554.37, two soft taps 90 ms each | 200 ms | −20 dBFS |
| `unlock` | `gate.confirm`, `reader.unlock` | glide 880 → 1318.51 Hz with the 2.76 partial | 180 ms | −20 dBFS |
| `shimmer` | `streak.extend`, `streak.milestone`, `goal.met`, the Wrapped summary card | five A6 grains 40 ms apart, rising level | 260 ms | −20 dBFS |
| `pop` | `reaction.send` | chirp 900 → 1800 Hz, 30 ms | 40 ms | −24 dBFS |
| `chapter` | `chapter.next` | A4 440 Hz struck glass, 2.76 partial, decay 300 ms | 320 ms | −22 dBFS |
| `flip` | `share.flip` | two struck-glass taps E6, A6, 60 ms apart | 140 ms | −24 dBFS |
| `send` | `recommend.send` | glide F♯6 → A6 over 140 ms with a 60 ms tail | 200 ms | −22 dBFS |
| `melt` | `skin.switch` | descending glide A6 → A5, 400 ms, plate reverb 40 % wet | 420 ms | −18 dBFS |
| `logo` | `logo.settle` | A5, C♯6, E6, A6 at 24 ms steps + a 1.2 s filtered-noise air pad | 1.4 s | −12 dBFS |

Events with no Glass sound: everything not listed above (for example `warning`, `hold.ramp`, `chapter.seam`, `autoscroll.*`, `listen.toggle`).

**Production.** One `design/sounds/glass/build.sh` of `sox -n -r 48000 -b 16 -c 1 <name>.wav synth …` lines, WAV 48 kHz 16-bit mono, under 320 KB for the whole set, for example `sox -n -r 48000 -b 16 -c 1 tap.wav synth 0.024 sine 1760 sine 4857.6 remix - fade 0.005 0.024 0.005 gain -26`. Web copies to `frontend/public/sounds/glass/`, Flutter to `mobile/assets/sounds/glass/`.

**Playback.** `flutter_soloud` 5.1.4 on mobile (low latency, loads WAV; the same engine plays the soundscape, §9.4.2); the Web Audio API on the web (decode once on the first user gesture into `AudioBuffer`s, play through `AudioBufferSourceNode` with `playbackRate` for velocity pitch, one master `GainNode`). Sounds are suppressed while narration or a soundscape plays, never duck the user's music, and never play for the typing or letter reveals.

**One audio session, one owner.** An app process has one `AVAudioSession` category and one Android audio-focus request at a time, so a single state machine (`mobile/lib/skins/glass/soundscape/mixer.dart` over the shared `audio_session` 0.1.25; web `frontend/src/skins/glass/soundscape.ts`) owns it; narration, the soundscape and UI sounds ask it for a state and never set the category themselves.

| State | Entered when | iOS category and options | Android focus | Web | UI sounds |
|---|---|---|---|---|---|
| `idle` | App start; leaving a reader with nothing playing | `.ambient` (follows the silent switch, mixes with others) | none requested | `navigator.audioSession.type = "ambient"` where supported (Safari 16.4+), so Web Audio also follows the silent switch | Play (when switched on) |
| `soundscape` | A scene starts | `.playback` + `.mixWithOthers` (the reader's own music is never interrupted or ducked) | none requested (`AUDIOFOCUS_NONE`; mixing is by design) | `"playback"` | Suppressed |
| `narration` | Narration starts (with or without a soundscape) | `.playback` + `.duckOthers`, mode `.spokenAudio` (the category narration uses today through `audio_session`) | `AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK`, usage `USAGE_MEDIA`, content `CONTENT_TYPE_SPEECH` | `"playback"` | Suppressed |

Transitions: `idle → soundscape → narration` changes the category once; the soundscape keeps playing and ducks itself by 12 dB inside the app over 400 ms (or pauses, with "Lower under narration" off, §9.4.2); `narration → soundscape` when narration stops restores `.playback + .mixWithOthers`; leaving the reader with neither playing returns to `idle` after the 1.5 s soundscape fade-out; losing focus to a call or another app pauses narration and the soundscape and returns to `idle`; a system interruption end resumes neither on its own (a toast offers "Resume"). The web has no categories: `navigator.audioSession.type` is set where supported, and otherwise Web Audio simply plays.

---

## 7. Component catalog

Every component below lists its visual spec, its motion (with the §4 spring tokens) and every state: default, hover (pointer devices only, `@media (hover: hover)`), pressed, focused, disabled, loading, selected, error. "Glass swells, content sinks" is the universal press rule: glass controls grow and light up when pressed; content (posters, cards, rows) sinks slightly, as if pressed into water.

### 7.1 Buttons

**Variants**

| Variant | Material | Heights (visual / hit) | Padding | Label | Icon |
|---|---|---|---|---|---|
| **Primary** (one per screen) | `glassTinted` | L 50 / 50, M 44 / 44, S 34 / 44 | L 0 24, M 0 20, S 0 14 | `headline` 17/600 `onTint` (S: `subhead` 15/620) | 20 px Regular, 8 px gap, leading |
| **Secondary** | `glassThin` (on black) or `glassRegular` (over media) | same | same | `headline` `onGlass` | same |
| **Plain** | none | 44 hit | 0 8 | `headline` `iris400` on black, `onGlass` on glass | optional |
| **Destructive (secondary)** | `glassThin` | same | same | `headline` `danger` | optional |
| **Destructive (confirm)** | solid `danger` `#FF5C5C` | L 50 | 0 24 | `headline` black (6.94:1) | optional |
| **Hold-to-confirm** | `glassThin` with a liquid fill | L 50 | 0 24 | `headline` `onGlass`, "Hold to delete" | leading glyph |
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
| Error | Label swaps to a short error ("Couldn't save") for 2 s in `danger` on the same glass; the button shakes: `x(t) = 8 × e^(−t / 90 ms) × sin(2π × 7 Hz × t)` for 420 ms | `error` haptic; reduced motion: no shake, the error label only |

**Hold-to-confirm.** Pressing starts a liquid fill that rises left to right inside the capsule (`iris600` at 70 %, with a 3 px meniscus curve on its leading edge) over 1200 ms, with `hold.ramp` haptics every 150 ms and the label changing to "Keep holding…". Releasing early drains the fill back on `dismiss` from its current position. Completion fires `hold.done`, flashes the capsule to `glassTinted`, and runs the action. It is used for: turning on the 18+ gate, signing out everywhere, deleting a profile, deleting a collection, removing all downloads, resetting offline storage, staging a backup restore and deleting a member. **Alternative (WCAG 2.5.1):** a keyboard activation, a screen-reader double-tap, or a plain click opens an alert with an explicit confirm button, so holding is never the only way.

**Split button.** Used on series detail: "Continue · Ch 143" and a trailing chevron that blooms (`morph`) into a menu: Read from the start, Read all (one scroll), Pick a chapter, Download next 10. The two segments share one glass container: pressing either lights both, the pressed one more.

**Progress button.** "Download" (cloud-arrow-down) → on press, the label cross-fades to "Queued" and a liquid fill enters from the left at the queue's progress; while saving it shows `mono` "12/40" and the fill tracks progress with `snappy`; complete: the fill turns `success` at 24 % and the glyph morphs to a check (`tick`), label "Saved"; failed: `danger` label "Retry" with the shake.

### 7.2 Icon buttons

| Variant | Visual | Hit | Use |
|---|---|---|---|
| **Nav button** | `glassThin` circle 44, icon 22 Regular `onGlass` | 44 | Back, close, profile orb, bell, more (⋯) in floating top rows; a long-press on Back opens the stack overview or back menu (§7.37) |
| **Glass group** | One `glassThin` capsule 44 tall holding 2 to 4 icons, 44 px apart, 8 px internal gap | 44 each | Reader top-right group, detail toolbar (share, bookmark, ⋯) |
| **Plain icon** | No background; icon 22 `g800` on black; hover `fill4` circle 40 | 44 | Inline row actions on desktop, sheet headers |
| **Row icon** | `fill3` circle 32, icon 18 | 44 | Pin, remove, download inside rows |
| **Toggle icon** | Any of the above; off = Regular `g800`, on = Fill in its colour (`iris400` for pin and follow, `streakCore` `#FFD166` for favourite, `success` for downloaded) | as above | Pin source, favourite, follow bell |
| **Badged icon** | Any; a count badge at the top-right (see §7.20) | as above | Bell with unread count |

States: default; **hover** inner glow 8 % (glass) or `fill4` circle (plain); **pressed** glass grows +17 px on the longest side capped at 0.35 × (so a 44 px button reaches about 1.35 × at most), glow 16 % from the touch point, Duotone → Fill morph; plain icons sink to 0.92 on `press`; **focused** `focusRing` concentric; **disabled** icon `g500`, no glow; **loading** icon replaced by a 16 px liquid ring spinner (§7.19); **selected** Fill glyph in its colour, with a `tick` pop 1 → 1.12 → 1; **error** the glyph swaps to warning-circle `danger` for 2 s with the shake. In a glass group, a pressed icon's glow spreads into its neighbours at 30 % (one container, one light).

Every icon-only button has an `aria-label` (web) or `Semantics(label:)`/`tooltip:` (Flutter), and a tooltip after the 600 ms "long" hover delay on desktop.

### 7.3 Inputs

Form fields are **content-layer wells**, not glass (they sit on black or on a glass sheet, and nothing goes on glass but fills).

| Field | Visual | Notes |
|---|---|---|
| Text | Height 50, radius 14 squircle, fill `fill3` on black or `fill2` on a sheet, padding 0 16, text `body` 17 `label1`, placeholder `label3`; label above in `footnote` 13/600 `label2` with 6 px gap; helper below in `footnote` `label3` | `autocomplete`, `autocapitalize="none"` for usernames and URLs |
| Password | Text field + trailing eye toggle (plain icon 22, hit 44, `aria-pressed`, labels "Show password" / "Hide password") | Toggle keeps caret position |
| Text area | Min 3 rows (≈ 96 px), grows with content up to 8 rows on `snappy`, then scrolls; counter `caption1` `label3` bottom-right when ≥ 80 % of the limit, `warning` at 95 % | Enter submits where the inventory says so (AI prompt), Shift+Enter newline |
| URL (setup, server) | Text field with leading globe glyph, `inputmode="url"`, trailing status: spinner while validating, check `success` when reachable | |
| Number / go-to | 96 wide, `mono` 13, `inputmode="decimal"`, centred | Enter jumps, Esc clears |
| Stepper | Two 36 px `fill2` circles with − and +, value in `mono` 15 between (min width 64); hit 44 each | Rubber-bands past the limit: the value text stretches 4 px toward the pressed side and springs back, `detent.limit` haptic |
| Select (native) | Not used; every choice list is a menu (§7.23) or segmented control | |

States: **default**; **hover** well brightens to `fill2`; **focused** `focusRing` + caret `iris400` 2 px + well to `fill2`; **disabled** 40 %, not focusable; **loading** trailing 16 px spinner; **selected** (text selection) `iris600` at 40 %; **error** `errorRing` 1.5 px `danger`, message below in `footnote` `danger` with a warning-circle glyph, `aria-invalid="true"` and `aria-describedby` on the message; on submit the field shakes (the error shake, 6 px amplitude) and the first invalid field takes focus. Validation messages appear with `fadeIn` and push content down on `snappy`.

### 7.4 Search

- **Phone search orb.** A 50 px `glassThin` circle at the dock's trailing end with a magnifying-glass icon. Tap: the orb stretches along `morph` into a bottom search field (full width minus 21 px insets, 50 px tall, `glassRegular` capsule) that rides on top of the keyboard; the dock sinks away on `minimize`. Above the field: the scope segmented control (Library · Sources · Dialogue · Novel text; Dialogue hidden in Novels mode, Novel text hidden when novels are off) and the suggestion list (recent searches as rows closest to the thumb, then trending chips). Cancel: a plain "Cancel" button trailing the field; the field shrinks back into the orb on `morph` and the dock rises. Dragging down on the field dismisses the keyboard first, then collapses to the orb (projection past 80 px). **Mobile web:** iOS Safari does not move fixed elements with the keyboard, so the field is positioned from the visual viewport: `bottom: calc(100lvh - var(--vv-h) - var(--vv-top))`, where `--vv-h` and `--vv-top` are `visualViewport.height` and `visualViewport.offsetTop` written by one `visualViewport` `resize` + `scroll` listener (one write per animation frame) while the field is focused; Chrome on Android gets `<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover, interactive-widget=resizes-content">`, so the layout viewport shrinks and the same rule yields `bottom: 0` above the keyboard.
- **Desktop.** A 36 px `fill3` capsule at the top of the sidebar ("Search  ⌘K"). Click or `mod+k` morphs it into the command palette (§7.28). On the Search screen itself, the field is a 56 px `glassRegular` capsule centred at the top of the content.
- **In-page filter fields** (library, sources, collections, go-to-chapter): content wells (§7.3) at 44 px, leading magnifier, trailing clear (×, 44 hit) when non-empty.

States: idle (placeholder "Search series, sources and dialogue"); focused (ring, keyboard); typing (300 ms debounce, Enter searches at once); searching (the magnifier becomes a 16 px liquid ring spinner); results; no results; error; offline (a `warning` wifi-slash replaces the magnifier and the field shows "Offline: searching this device only" as helper, searching only downloaded titles).

### 7.5 Chips

| Chip | Visual | Behaviour |
|---|---|---|
| **Filter chip** (multi-select) | Height 32 (hit 44 via 6 px vertical padding), `rCapsule`, `fill2`, `subhead` 15/460 `label1`, 12 px horizontal padding; optional leading glyph 16 | Selected: becomes `glassThin` with a leading check that grows in on `tick`, label `wght` 600 |
| **Choice chip** (single-select group) | Same size; the selected one sits under a shared **droplet** (`glassThin` clear capsule) | The droplet slides between chips on `tab`, stretching with velocity like the dock droplet |
| **Count chip** | Filter chip + `mono` count in `label2` after a 6 px gap | "Pinned 4", "With results 12" |
| **Input chip** (removable) | Filter chip + trailing × (16 px, hit 32) | Recent searches; × removes with the chip shrinking on `dismiss` and siblings closing the gap on `snappy` |
| **Assist chip** | Height 32, `glassThin` outline style (fill 0, rim only), leading glyph | Helper actions: "Next 10", "All unread", "Whole book" |
| **Tag** (genre, status) | Height 24, `fill4`, `caption1` uppercase +0.08 em `label2`, 8 px padding | Non-interactive, or a link (hover `fill3`, focus ring) |

Chip rows scroll horizontally with momentum, rubber-band at both ends, mask their trailing 24 px with a gradient to hint at more, and never snap. Because chips live in scrolling rows, the selected filter chip's glass and the choice-chip droplet are drawn as content twins (§2.4.1): the same capsule, rim and inner light, sliding and stretching exactly as described, with no backdrop read. States: default; hover `fill3`; pressed sinks to 0.96 on `press` (chips are content) while its glass (when selected) swells; focused ring; disabled 40 %; loading (a count chip's count becomes a 12 px spinner); selected as above; error (a chip whose filter failed turns its glyph into warning-circle `danger` and shows a tooltip).

### 7.6 Segmented control

- **Track:** `fill3` capsule, height 36 (compact 32 inside sheets), 2 px inner padding.
- **Thumb:** `surface3` capsule at rest with a 0.5 px rim; label `subhead` 15/620 `label1` on the thumb, `label2` elsewhere.
- **Physics:** tap a segment → the thumb travels on `tab`. Drag the thumb → it turns `glassThin` clear (the transient-glass exception: a content control becomes glass only while manipulated), follows on `track`, stretches `scaleX = 1 + min(|v| / 2000, 0.25)` along the travel, `select` ticks at each boundary; release → projected nearest segment → `tab`.
- **Segments:** 2 to 5; more than 5 becomes a menu. Equal widths by default; content-fit when labels differ by more than 40 %.
- **States:** default; hover (unselected segment `fill4`); pressed (the pressed segment's label sinks 0.96); focused (ring around the whole control; arrows move the selection; Home/End jump); disabled (40 %, thumb stays); loading (the selected label is replaced by a spinner while the new selection's data loads, the thumb stays at the new position); selected (the thumb); error (the thumb springs back to the previous segment with `tick` and a toast explains).
- **Web:** `role="radiogroup"` with `role="radio"` segments (or `tablist` when it switches panels).

### 7.7 Cards (content layer)

Cards are content: they sit on black or on the ambient field, never glass. Default slab: `surface1` with `slabBorder`, radius `rXl` 26, padding 12; media inside at radius 14.

| Card | Layout | Specifics |
|---|---|---|
| **Series card** (grids) | Poster 2:3 (§7.8) + 8 px + title `footnote` 13/600 2 lines + meta `caption1` `label3` 1 line | No slab; the poster is the card |
| **Continue stack** (Home, Library) | 280 × 132 on phone (desktop 320 × 148): cover 88 × 132 at left; behind the cover, the next page's thumbnail peeks 8 px to the right and 6 px down, rotated 2°, like a deck; right side: title `headline`, "Ch 142 · p. 18 of 40" `footnote` `label2`, progress ring (24 px, 3 px stroke `iris500` on `fill1`) around the chapter number, "Continue" plain button | Slab `surface1`; swiping the stack left reveals "Previously on" (§9.1.3) |
| **World title card** (AI and "for you") | 300 × 132: cover 80 × 120, title `headline` 2 lines, "Manhwa · Ongoing" `caption1`, "120 ch · ★ 8.4" `mono` 13, up to 3 tags, the `why` line in `footnote` italic `label2` after the machine sparkle (§7.38) | **Available** variant: a small "On MangaSource" source chip (and "+2") and the whole card opens the series. **Info-only** variant: dashed 1 px `slabBorder`, "Not on your sources" `caption1` `label3`, and two plain buttons "Search my sources" and "Read on {site}" (external) |
| **Result card** (search) | 112 wide × 208: poster 112 × 168 + title 2 lines `footnote` | Source glyph badge hidden inside source groups |
| **Stat card** | 2-up grid, slab 26/16: glyph 20 `iris400`, `numeral` value, label `footnote` `label2`, optional 7-point sparkline 24 px tall in `iris500` | |
| **Collection card** | 21:9 slab with a **fanned stack** of up to four member covers (each 72 × 108, rotated −8°, −3°, 3°, 8°, overlapping 40 %) left, name `title3` and "12 series" right | Tap fans the stack open (`celebrate`) during the zoom into the collection |
| **Notification card** | One per series: cover 44 × 66, series title `headline`, "3 new · Ch 141–143" `footnote` `iris400`, time `caption1` `label3`, chapter chips (each opens the reader) | Swipe actions (§7.34) |
| **Source row card** | Row 64 tall: 44 px source logo (radius 10), name `headline`, description `footnote` `label2` 1 line, 18+ tag when mature, pin toggle icon | **Logo fallback** (sources without `icon_url`, or a logo that fails to load): a monogram tile, the source name's first letter in `headline` 600 `label1` on `surface3`, radius 10, tinted by a hash of the source id into the speaker palette (§2.1.5) at 24 %; the same tile at 12 px in the Source badge (§7.20) |
| **History tile** | Poster with a 3 px progress line along its bottom edge, a 36 px play orb bottom-right ("p. 18" or "42 %") drawn as a content twin (§2.4.1: `rgba(19,19,23,0.62)` disc, 0.5 px `rgba(255,255,255,0.22)` rim, inner light, no backdrop read), title and "Ch 12 · 3 h ago" below | |

States (all cards): **default**; **hover** (desktop) lift −2 px on `snappy`, shadow `0 12px 32px rgba(0,0,0,0.5)`, posters tilt toward the pointer up to 6° with the specular highlight sweeping across the cover; **pressed** sinks to 0.97 on `press` (content sinks); **focused** ring + scale 1.03; **disabled** (unavailable source, pinned-but-hidden) 55 % opacity, not activatable, reason in `caption1`; **loading** skeleton of the same shape (§7.18); **selected** (select mode) 2 px `iris500` inset ring + a 24 px check orb top-right that pops on `tick`, media dims to 80 %; **error** (cover failed) `surface2` fill with a broken-image glyph 24 `g600` centred and the title still shown.

### 7.8 Posters

- **Geometry:** 2:3, radius 14 squircle, 1 px inner highlight `rgba(255,255,255,0.08)` along the top edge, no outer border. Widths: phone 124 (rail) / grid by columns; tablet 148; desktop 168; wide 184.
- **Image arrival:** placeholder is `surface2` with the ambient hue at 12 %; the image arrives with opacity 0 → 1 over `fadeIn` and scale 1.02 → 1 on `snappy` (it settles into the frame).
- **Overlays:** status tag top-left (§7.20), "N new" badge top-right (`iris400` capsule, black `caption1` 700, "99+"), downloaded droplet glyph bottom-left (`success`, 16 px, on a 22 px `rgba(0,0,0,0.55)` circle), 18+ capsule top-left when mature and the gate is open, progress: 3 px bar along the bottom inside the radius (`iris500` on `fill1`).
- **Hover (desktop):** pointer tilt up to 6° (`rotateX/rotateY` on `track`), specular highlight (a white radial gradient at 12 %) following the pointer, lift −2 px; after 600 ms of rest a peek capsule (the content twin of `glassThin`, §2.4.1, because posters live in rails and grids) grows out of the poster's bottom edge on `morph` with "Continue Ch 12" or "Open", and a ⋯ button.
- **Press and lift (touch):** at 150 ms the poster starts growing toward 1.06 and its shadow deepens (`0 18px 40px rgba(0,0,0,0.55)`), `press.lift` haptic; at 450 ms the context preview blooms: the background takes `dimContext`, the poster rises to 1.12, and a `glassThick` menu blooms beneath it (§7.23). While lifted, the poster is a **physical object**: drag moves it 1:1; throw up opens detail (the zoom inherits the throw velocity); throw sideways on AI cards is "Not interested"; drag onto a friend orb (they appear along the top when social is on) recommends it; release anywhere else drops it back into place on `zoom`.
- **Keyboard:** focus scale 1.04 + ring; `.` or `shift+F10` opens the menu; Enter opens.
- **States:** as §7.7 cards.

### 7.9 Rails

- **Header:** `title2` (letter reveal on its first appearance per session, §10.1), optional subtitle `footnote` `label2` ("Because you read Solo Leveling"), trailing "See all" plain button; 12 px below, the scroller.
- **Scroller:** leading inset = screen margin, trailing inset = screen margin, gap 12 (phone) / 16 (desktop); posters peek at the trailing edge (3.2 posters visible at 390 px wide).
- **Physics:** free momentum scrolling; on release the ballistic simulation's end is projected and rounded to the nearest multiple of `posterWidth + gap`, and a `settle` spring carries the remaining velocity into that snap. Rubber-band at both ends (`c = 0.55`, `d` = rail width). Web: `overscroll-behavior-x: contain` so a trackpad flick at the start never navigates back; the same snap computed in a `scrollend` handler with Motion's `animate(scrollLeft)`. Flutter: a 20-line `ScrollPhysics` subclass overriding `createBallisticSimulation` returning `ScrollSpringSimulation(spring: settle, …)` with the projected snap target.
- **Desktop:** glass arrow buttons (44 `glassThin` circles) materialise at each end when the pointer is over the rail; each page scrolls by (visible count − 1) posters on `page`. Keys: `←`/`→` move focus within the rail, `↑`/`↓` move between rails keeping the column; each rail is one tab stop (roving `tabindex`).
- **States:** loading (4 to 8 skeleton posters with the header already in place); empty (the rail is omitted, except AI rails, which show their unavailable card); error (a 120 px tall inline card "Couldn't load this row" + "Retry" plain button); AI unavailable (the AI notice of §7.38 with the reason's short line from §9.1.5); partial (loaded posters, a trailing skeleton while tier-2 sources answer).

### 7.10 Sheets

- **Detents:** `peek` 96 px (only for the listen mini player expansion), `medium` 52 % of the screen height, `large` = screen height − safe-top − 10 px. Detents a given sheet uses are listed per screen.
- **Geometry:** inset 8 px at partial detents with radius `rSheet` on all corners (the bottom corners nest into the display corners); at `large` the inset lerps 8 → 0 over the last 20 % of travel, the bottom corners go to 0, and the material cross-fades `glassThick` → `solid1` (a tall sheet becomes opaque and attached).
- **Grabber:** 36 × 5 capsule `fill1`, 8 px from the top, 44 × 44 hit; tap cycles detents; with keyboard focus `↑`/`↓` change detent.
- **Header:** 56 tall: title `title2` leading (or centred for pickers), close button (`glassThin` 32 circle with ×, 44 hit) trailing; optional leading action.
- **Behind:** partial detents dim with `dimSheet`; at `large` the page behind recedes to scale 0.94, radius grows to 12, blur 8 and dims to 60 % (visionOS recession), all driven by sheet position (not by time).
- **Physics:** the sheet tracks the finger 1:1; above the top detent it rubber-bands (60 px max); release projects the top edge (§4.4) and picks a detent → `sheetSnap` with the release velocity; `sheet.pass` ticks as detents are passed during a drag; dismissal per §4.6. Scroll hand-off: an inner scroll view at its top hands a downward drag to the sheet; an upward drag at a partial detent expands the sheet before scrolling the content. Present by button: `sheet` (bounce 0.08) from the trigger's position when the trigger is at the bottom (the sheet grows out of the control, a `morph`), otherwise from the bottom edge. Dismiss by button: `dismiss`.
- **Stacking:** at most two sheets; the lower one at `large` scales to 0.9165 and moves up 2 %; a lower partial sheet drops to 70 % brightness. Only the lowest sheet blurs the page.
- **Desktop:** the same content renders as (a) a right-side **panel**, 440 wide, inset 12, radius 26, `glassThick`, entering from the right on `sheet`; or (b) a centred **window**, 560 wide, radius 32, blooming from its trigger on `morph`. Esc and a backdrop click close; each is a history entry (`?sheet={id}`, the rule and the id list of §8.0.3) so browser back closes it.
- **States:** loading (skeleton rows inside, header live); error (an inline error block with retry); empty (the sheet's own empty copy); disabled actions greyed.

### 7.11 Dialogs and alerts

- **Visual:** `glassThick`, width 300 (phone) / 420 (desktop), radius 26, padding 20; title `title3` 20/700 left-aligned; body `callout` `label1` (secondary lines `label2` are allowed because alerts sit on `dimModal` over a slab, never over a bright page); a warning or danger box inside for risky content (`surface2` slab with a 3 px leading bar in the semantic colour).
- **Buttons:** stacked full-width capsules (L 50) when there are two with long labels, side-by-side M 44 otherwise; order: least destructive first on top of a stack, trailing when side by side; the destructive confirm uses the solid `danger` variant; initial focus goes to the least destructive action.
- **Motion:** blooms from the control that opened it when there is one (scale 0.9 from that point, `morph`, materialise), otherwise from centre (0.94 → 1, `morph`); `dimModal` fades in over 180 ms. Dismiss: `dismiss` shrink to 0.96 + dematerialise 350 ms.
- **Behaviour:** Esc and Android back cancel; focus trapped; focus returns to the trigger; `role="alertdialog"` with `aria-labelledby` / `aria-describedby`.
- **States:** default; pending (the confirm shows its loading state and the dialog can't be dismissed); error (an inline `danger` line above the buttons, the confirm shakes).

### 7.12 Toasts

- **Visual:** `glassRegular` capsule, height 44 (two-line variant 60 with radius 22), padding 0 16, max width 420; leading 20 px glyph in its semantic colour, text `callout` `onGlass`, optional plain action ("Undo", "View"), no close button (swipe or wait).
- **Position:** phone: top, safe-top + 60 (under the nav row, which stays usable), centred; the top `edgeSoft` plateau extends under it while it shows (§2.1.7); desktop: bottom-left, 24 px from the sidebar's edge and the window bottom.
- **Top-band priority** (one slot under the nav row on phones): alert > toast > global new-chapters capsule > app-update capsule. A toast also waits while a menu or context menu is open (the glass budget of §15.7), and appears when it closes. A lower item waits (and the new-chapters capsule re-appears) when a higher one leaves; the "Offline" and "Syncing" status capsules are not in this queue because they replace the title capsule inside the nav row (§7.14).
- **Motion:** falls in from 60 px above on `snappy` (materialising as it lands); leaves upward on `dismiss`. A toast is catchable: flick up or sideways to dismiss (projection past 40 px); drag down to hold it (the timer pauses while touched).
- **Timing:** 4 s default, 5 s with Undo (the capsule's rim drains clockwise as a progress ring so the remaining time is visible); hover pauses; with a screen reader active, toasts stay until dismissed.
- **Stacking:** at most 2; a newer toast pushes the older down 8 px and scales it to 0.94 behind.
- **A11y:** `role="status"` (`aria-live="polite"`), errors `role="alert"`; Flutter `SemanticsService.sendAnnouncement` where supported.

### 7.13 In-page tabs and pagers

- **Tab strip:** a scrollable row of labels (`subhead` 15/600) over a **glass capsule indicator** (`glassThin` clear, 32 tall) that sits behind the selected label; unselected labels `label2`.
- **Pager:** the panels beneath swipe horizontally (Flutter `TabBarView` with `BouncingScrollPhysics`; web a CSS scroll-snap row `scroll-snap-type: x mandatory; scroll-snap-stop: always; overscroll-behavior-x: contain`). The indicator reads the pager's continuous position, so while the finger drags a panel the capsule slides and stretches between the two labels (width lerps between the two label widths, plus velocity stretch up to 25 %); release projects to the nearest panel and settles on `settle`, `select` haptic on settle.
- **Where:** Source catalogue browse modes, Downloads (Chapters | Storage | Queue), Library sections on phone (Shelf | Collections | History | Bookmarks | Downloads), Updates (All | Unread | Followed), Search scopes on desktop, Statistics ranges.
- **Back gesture rule:** full-width back swipe on iOS loses to the pager until the pager is on its first panel and the drag goes right.
- **Keys:** `[` and `]` previous/next tab; arrows inside the `tablist`; `role="tablist"`, `aria-selected`, roving `tabindex`.
- **States:** default, hover (`fill4` behind the label), pressed (label 0.96), focused (ring on the label), disabled (label `label4`, skipped by arrows), loading (the panel shows its skeleton; the tab keeps working), selected (capsule), error (panel error block).

### 7.14 Top bars

Meniscus has no top bar backgrounds on phone. A top area is a **floating nav row** of glass objects over a soft scroll edge:

- **Nav row:** 44 px tall at safe-top + 8; leading: a back nav button (on pushed screens; a long-press shows the stack, §7.37) or the profile orb (on tab roots); centre: nothing, or a **title capsule** (`glassThin` capsule, 36 tall, `subhead` 15/20 at `wght` 600 `onGlass`, max 60 % of the width, truncating) once the large title scrolls away; while offline or syncing, the "Offline" or "Syncing" status capsule (§7.30) takes the title capsule's place (the title returns when it leaves); trailing: a glass group of up to three icons.
- **Large title:** `largeTitle` 34/40 in the content, 16 px below the nav row. It scrolls with the content; when its baseline passes under the nav row, the title capsule materialises in the centre (lensing 0 → 1 over `materialize`, scale 0.9 → 1 on `snappy`), and its text scales from the large title's position into the capsule (web: a shared `layoutId`; Flutter: a `SliverPersistentHeader` interpolates position and size from the scroll offset). Pulling down past the top stretches the large title (it grows up to 1.08 with the rubber band, anchored at its leading edge).
- **Edge:** `edgeSoft` under the nav row, always; `edgeHard` under pinned headers such as the Library filter row once it pins.
- **Desktop:** the sidebar holds navigation, so the content has a slim **toolbar row** (48 tall, transparent, `edgeSoft` 48 px) with the page title `title2` leading once the large title scrolls away, and trailing actions as a glass group that always ends with a keyboard-shortcuts button (opens the `?` sheet). Back on desktop is a plain chevron button before the title (history back), plus `Esc` for overlays.
- **States:** the nav buttons follow §7.2; the title capsule has only default and focused (it is a heading, focusable only as a skip target).

### 7.15 Dock, search orb and bottom accessory (phone apps and mobile web)

**Dock.** A floating `glassRegular` capsule, 64 tall, inset 21 px from the left, bottom (+ safe area) and right edges, leaving room for the 50 px search orb and an 8 px gap at the trailing end. Four tabs: **Home**, **Library**, **Sources**, **You**. Each tab: icon 22 (Regular; active: Duotone morphing to Fill on press) over a `tabLabel` 11/600; the active glyph and label are `iris400`.

- **Droplet:** the selection indicator is a `glassThin` clear droplet (capsule 56 × 52) under the active tab. Tap another tab → the droplet travels on `tab`, stretching along its path (`scaleX = 1 + min(|v| / 2000, 0.25)`, `scaleY = 1 / √scaleX`), `nav.change` haptic. **Drag across the dock** (press on the droplet or anywhere on the dock and slide): the droplet lifts (turns fully clear, grows 6 %), follows the finger on `track`, ticks `nav.scrub` over each tab, and on release projects to the nearest tab and settles on `tab`. The droplet can be caught mid-flight.
- **Minimise:** after 20 px of cumulative downward scroll, the dock morphs on `minimize` into a 50 px capsule showing only the active tab's icon; the search orb stays; after 12 px of upward scroll, at the top of a list, or on a tap on the minimised capsule, it restores. Minimising is interruptible: reversing scroll mid-morph reverses the morph with its current velocity.
- **Badges:** Home shows an 8 px `iris400` dot when there are unread updates; Library shows a count badge of active downloads (queued + downloading + failed) when non-zero; You shows a `bloom` dot when a letter arrives and wears the daily goal ring (§9.2.2).
- **Tap the active tab:** pop the tab's stack to its root; if already at the root, scroll to top on `page`; `nav.reselect` haptic (and `nav.root`, one tick per level popped).
- **Long-press a tab** (450 ms): Home → a menu (Updates, Mark all read, Continue last read); Library → jump list (Shelf, Collections, History, Bookmarks, Downloads, and the first five collections); Sources → the pinned sources; You → the **profile switcher** (the profile orbs bloom from the tab, pick one to switch without visiting the picker).
- **Hidden** in both readers, on the profile picker, auth and setup, and while a full-height sheet is open.
- **Semantics:** the dock stays a tab list whatever the finger does: web `role="tablist"` with four `role="tab"` buttons (`aria-selected`, roving `tabindex`, arrows move, Enter/Space select) inside a `nav` landmark labelled "Main"; Flutter `Semantics(container: true, explicitChildNodes: true)` with each tab `Semantics(selected:, button: true, label: "Library, tab 2 of 4")`. The droplet drag is a pointer-only enhancement: screen readers and keyboards never see it, and a drag that ends on a tab announces the new tab exactly like a tap. The search orb is a separate button "Search".

**Search orb.** 50 px `glassThin` circle, trailing, same bottom line as the dock. Its behaviour is in §7.4. While the dock is being dragged, the orb and the dock are one glass container: if the droplet is dragged past the last tab toward the orb, the two surfaces merge with a metaball neck (the gap bridges when closer than 12 px) and releasing on the orb opens search.

**Bottom accessory.** A 48 px `glassRegular` capsule, 8 px above the dock, same insets as the dock (it spans the dock plus the orb). One of, in priority order:

1. **Now narrating:** voice avatar 32, "Chapter 12 · Aurora", play/pause 44, a 2 px progress line along its bottom edge; tap expands into the full player (§8.16) by growing along `morph` from the capsule into a sheet; swipe left or right on it changes chapter (projection past 30 % of its width).
2. **Downloading:** a liquid ring 24 with the overall progress, "Saving 3 chapters · 42 %" and a pause/resume button; tap opens Downloads.
3. **Continue:** a 32 px cover, "Continue Solo Leveling · Ch 143", a play glyph; appears on Home only after the hero spotlight has scrolled off-screen.

When the dock minimises, the accessory shrinks on the same `minimize` spring and moves **inline** between the minimised dock capsule and the search orb, showing only its glyph, title and play control. Swiping the accessory down (projection past 40 px) dismisses it for the session (narration pauses first with an Undo toast).

### 7.16 Desktop sidebar

- **Geometry:** an inset `glassRegular` panel, 280 wide, 12 px from the window's top, left and bottom edges, radius 26; content scrolls beneath it (the page's content column starts at 304 px). Collapsed: 76 wide (icons only), auto-collapsing below 1180 px; `mod+b` toggles; the width change runs on `snappy` and uses the frosted tier during the animation (refraction maps are rebuilt only at rest).
- **Order, top to bottom:** the wordmark (single-line fallback "ManhwaManiacs" with the two M's in `iris400`, 20 px) and the collapse chevron; the search capsule ("Search  ⌘K"); the content-mode segmented control (Manga | Novels) when novels are enabled; primary items **Home** (with **For you** as its child), **Library** (expandable: Shelf, Collections, History, Bookmarks, Downloads), **Sources**, **Updates** (count badge), **Circle** (social, when enabled; a `bloom` dot when a letter arrives), **Stats**, **Dialogue search** (Manga mode only); pinned sources (up to 5, with favicons); footer: **Settings**, **Status** (admin only), and the profile orb + name capsule. Clicking the capsule blooms an account menu upward on `morph`: a header with the display name, "@username", the email when set and an "Administrator" tag for admins; the other profiles as 32 px orbs (click switches with the hand-off); "Manage profiles"; "Settings"; "Switch account" (signs out and opens Login with the username empty); "Sign out" ("Signing out…" while pending). Esc or an outside click closes it. The window chrome shows no clock; connectivity is the "Offline" status capsule (§7.30).
- **Desktop accessory** (the sidebar's answer to the phone's bottom accessory, §7.15): a 56 px capsule docked at the bottom of the sidebar, above the profile capsule, 8 px inset, drawn with a `fill2` fill, the sidebar's rim tint and `onGlass` text (it sits on the sidebar's glass, and nothing on glass is glass, §2.4.2 rule 7), holding in the same priority order **Now narrating** (voice orb 32, "Ch 12 · Aurora", play/pause, a 2 px progress line; click opens the full player as a 560 px window, §8.16.2), **Downloading** (liquid ring 24, "Saving 3 chapters · 42 %", pause) or nothing. Collapsed sidebar: the capsule shrinks to a 56 px orb with the ring or the voice orb. While narration jobs run (`GET /novels/audio/jobs/active`, polled with the jobs list), Library → Downloads carries a plain `fill2` chip "Narrating 3" (no machine light: narration is the narration PC's TTS, not the external AI) that opens the book's Audiobook sheet (§8.16.5); on phones the same chip sits on the You tab's Library → Downloads row.
- **Item:** 40 tall, radius 12 inside the 26 panel with 8 px padding (concentric 26 − 8 − 6 ≈ 12), icon 20 + `sidebarItem` 14/520; hover `fill4`; active: a glass droplet (`glassThin` clear) behind the item plus `iris400` glyph and label; the droplet travels between items on `tab` when the route changes. Exactly one item is active; nested Library items light only themselves.
- **Keyboard:** the sidebar is a `nav` landmark with a roving `tabindex` list; `g h` / `g l` / `g s` / `g u` / `g c` / `g t` jump to Home, Library, Sources, Updates, Circle and Stats.
- **States:** default, hover, pressed (item sinks 0.98), focused (ring inside the panel, concentric), disabled (Dialogue search in Novels mode is hidden, not disabled), loading (badges show a 10 px spinner), selected (droplet), error (a badge becomes a `warning` dot when its count failed to load).

### 7.17 Lists

- **Grouped list:** `surface1` container, radius 20, 16 px from the screen edges; rows 52 tall (64 with a subtitle); hairline separators inset to the text start; section header above in `footnote` 13/600 uppercase +0.04 em `label2` with 8 px bottom gap, section footer below in `footnote` `label3`.
- **Row anatomy:** optional leading icon tile (30 × 30, radius 8, glyph 18 white on a semantic colour or `surface3`), title `body` `label1`, optional subtitle `footnote` `label2`, trailing value `body` `label2`, trailing control (switch, chevron 14 `g600`, badge, or button).
- **Plain list** (feeds): no container; rows separated by hairlines; used for notifications, history on desktop, bookmarks, sessions.
- **Chapter row** (series pages): 56 tall (68 with a secondary title); leading: chapter number in `mono` 15 `label2` in a 44 column (tabular, "·" for null numbers, decimals shown "12.5"); title `body` (or "Chapter 12"); meta `caption1` `label3`: date ("Today", "Yesterday", "3 d ago", or "12 Sep"), "18/40" in `iris400` when in progress, "40 pages", "Read"; trailing download control (§7.29). Read rows drop to `label3` text; the in-progress row gets a 2 px `iris500` bar under its number.
- **Press:** rows sink to `surface3` fill and scale 0.99 on `press` (content sinks).
- **States:** default; hover `fill4`; pressed as above; focused ring inset 2 px, concentric; disabled (row text `label4`, not activatable); loading (skeleton row); selected (select mode: leading 24 px check circle springs in from the left on `snappy`, the row slides right 36 px; selected rows get `iris600` at 14 % fill); error (trailing warning glyph `danger` with an explanation tooltip or subtitle).

### 7.18 Skeletons ("wet glass")

Skeletons have one state (loading) and no interaction; they are `aria-hidden`, and the region they fill carries `aria-busy="true"`. Skeleton shapes match the content they stand for (per screen). Fill `surface2` (`g150`); a sheen band 40 % of the element's width, `linear-gradient(100deg, transparent, rgba(255,255,255,0.05), transparent)`, sweeps left to right every `shimmer` 1400 ms, phase-offset by 60 ms per row so the sheen travels down a list like light over wet glass. Radii match the real element. Skeletons appear only after 180 ms (fast responses never flash a skeleton), and the real content replaces them with the entrance wave from the top-left (§4.8). Reduce Motion: static `surface2`, no sheen.

### 7.19 Progress

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

### 7.20 Badges and markers

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

### 7.21 Sliders, scrubbers and dials

- **Slider:** track 6 px capsule `fill1`, fill `iris500`; thumb 28 px white circle with `0 2px 8px rgba(0,0,0,0.4)`; while dragged the thumb turns `glassClear` (the transient-glass exception) and grows to 34 px on `press`, and the track thickens to 8 px. Stepped sliders tick `detent.tick` per step (textured) and magnetise: within 30 % of a step's spacing the thumb is pulled toward the step. Past min or max it rubber-bands 12 px (`detent.limit` haptic). Value label in `mono` 13 trailing, or a glass value bubble above the thumb while dragging.
- **Fill slider (Control Centre style):** a tall 72 × 160 `glassRegular` capsule that fills from the bottom with `onGlass` at 90 %, glyph at the bottom (sun for brightness, speaker for volume); drag anywhere on it; the fill follows on `track`; used in the reader sheet for brightness and warmth.
- **Scrub rail (reader):** see §8.14.3; a 44 px hit strip on the trailing edge with a 3 px visible track, thumb 12 px, and a glass magnifier lens.
- **Speed dial (listen):** see §8.16; a vertical capsule where drag up/down changes speed in 0.05 steps with a magnet at 1.0 ×.
- **Keyboard:** arrows step, Page Up/Down step ×10, Home/End ends; `role="slider"` with `aria-valuetext`.
- **States:** default; hover (thumb grows to 30); pressed/dragging (as above); focused (ring around the thumb); disabled (track `g300`, thumb `g500`); loading (the value label shows a spinner, the thumb stays live); selected (n/a); error (the thumb springs back to the last saved value on `tick`, a toast explains).

### 7.22 Toggles, checkboxes and radios

- **Switch:** 51 × 31 track, off `fill1`, on `iris600`; knob 27 px white with a small shadow. Tap: knob travels on `tick` (4.6 % overshoot gives it a click), the track colour shifts over `colorShift`, `toggle.on`/`toggle.off` haptic. Drag the knob: it turns `glassClear` and stretches to 34 × 27 while held, follows the finger, and projects to on or off on release. States: default; hover (knob glow); pressed (knob stretches toward the travel direction to 34 px on `press`); focused (ring around the track); disabled (40 %); loading (knob shows a 12 px spinner, not toggleable); selected (on); error (the knob springs back to the previous side on `tick` with the shake and a toast).
- **Checkbox:** 24 px squircle, radius 7, off `fill1` border 1.5 px `g600`, on `iris600` fill with a white check that draws its stroke over 160 ms while the box pops 1 → 1.12 → 1 on `tick`. Indeterminate: a white bar. Hit 44.
- **Radio:** 24 px circle, off 1.5 px `g600` ring, on a 10 px white dot inside an `iris600` disc (the dot grows on `tick`). Radios in Meniscus appear only in lists (grouped rows with a trailing check glyph for the selected row, the iOS way), never as bare circles in forms.
- **Selection check (lists and select mode):** 24 px circle, `iris600` fill, white check; springs in from scale 0 on `tick`.

### 7.23 Menus and context menus

- **Menu (pull-down):** blooms out of its trigger along `morph`: the trigger's glass stretches into the menu body (shared glass on web via a common `layoutId`; Flutter `liquid_glass_widgets` morph), `glassThick`, radius 26, padding 6, min width 220, max 320; rows 44 tall, radius 20 (26 − 6), icon 20 trailing (iOS) or leading (Android and web), label `body`; destructive rows `danger`; separators 6 px gaps between groups; the content fades in over the last 40 % of the bloom. Dismissing reverses the path back into the trigger over `dematerialize`.
- **Slide to select:** press on the trigger and, without lifting, slide onto a row: rows highlight under the finger (`fill2`), `selection` haptic per row, release selects. A menu opened with a tap stays open.
- **Context menu (long press / right-click):** the pressed object lifts (§7.8), the background takes `dimContext`, and a `glassThick` menu blooms from the object's nearest edge. The preview (poster 1.12, row 1.02, image 1.0) stays interactive: drag it to throw (posters) or to reorder (rows in reorder-capable lists). Right-click on desktop opens the same menu at the pointer without the lift; `.` or `shift+F10` on a focused item opens it from the item.
- **Keyboard:** arrows move, Enter selects, Esc closes, type-ahead jumps to rows by first letter; `role="menu"`, `role="menuitem"`.
- **States:** row default, hover (`fill2`), pressed (row sinks 0.98), focused (ring inside the row, radius 20), disabled (`label4`, skipped), loading (a row's trailing spinner while its action runs; the menu stays open until done), selected (trailing check `iris400`), error (row label swaps to the error for 2 s, `danger`).

### 7.24 Empty, error and offline states

One component, three tones, all built as a floating **object lens**: a 96 px `glassThin` circle holding a 44 px Light glyph, which bobs slowly on the ambient drift (2 px amplitude, 6 s period, frozen under Reduce Motion) and tilts with the gyroscope, so the empty screen still has glass bending the ambient field. Below it: title `title3` `label1`, description `callout` `label2` (max 36 ch), and up to two buttons (primary tinted + secondary).

| Tone | Lens glyph colour | Field | Typical copy (per screen in §8) |
|---|---|---|---|
| Empty | `iris400` | Profile mood | "Your shelf is empty" |
| Error | `danger` | Mood at half opacity | "Couldn't load your library" + "Try again" |
| Offline | `warning` | Mood at half opacity | "You're offline" / "Chapters you downloaded still open with no connection." + "Try again" + "Open downloads" |

Offline states retry automatically when connectivity returns (web `online` event with a 3 s cooldown; Flutter `connectivity_plus` stream), and the lens does one `celebrate` hop when the retry succeeds. A `warning` "Offline" capsule (§7.30) also appears in the top nav row of every screen while offline.

The full-screen state lens is chrome (§2.4.1 rule 3); a lens inside a scrolling region (a per-rail error card, a seam card, a list's inline empty row) is drawn as its content twin.

**Lens glyphs** (Phosphor Light 44, one per situation, so no screen invents its own):

| Situation | Glyph |
|---|---|
| Empty library, shelf, collection, bookmarks, history | `books` / `stack` / `bookmark-simple` / `clock-counter-clockwise` |
| Nothing found (search, filters, dialogue, catalogue) | `magnifying-glass` |
| Dialogue search idle, no recap source text | `bubble-search` (custom) |
| No updates, caught up | `bell-simple` (caught up: `check-circle`) |
| Nothing downloaded | `cloud-arrow-down` |
| Offline (any) | `wifi-slash` |
| Couldn't load (any error) | `warning-circle` |
| Server unreachable | `cloud-slash` |
| Unavailable content (§8.0.8), 18+ absent on this profile | `eye-slash` |
| Circle quiet, only you | `users-three` |
| Administrators only | `shield` |
| Not found (404) | `question` |
| AI unavailable | `sparkle-slash` (custom), in `label2` |
| Reader landing | `strip-scroll` (custom) |
| Profiles unavailable, no profile | `user-circle` |

### 7.25 The 18+ gate

Mature content is governed by absence (`capabilities.md` §1): with the gate closed, mature sources, series, notifications and statistics simply do not exist in any list, count or search, and the skin never draws a placeholder, blur or "hidden" count.

- **Where it is set:** Settings → Content (per profile) and the profile form. Both surfaces use the same flow, so the safeguard is identical.
- **Turning it on:** the switch does not flip on tap. Tapping it opens an alert blooming from the switch: `age-gate` glyph 32 `mature`, title "Show mature content?", body "Adult (18+) sources, search results and recommendations will appear for this profile. Only continue if you are of legal age where you live. You can turn this off at any time.", and a **hold-to-confirm** button "Hold: I am 18 or older" (1200 ms, `hold.ramp`) plus "Cancel". Keyboard and screen-reader users get the explicit "I am 18 or older, enable" button in the same alert. On completion: `gate.confirm` haptic, the switch knob travels on `celebrate`, the alert dematerialises, and every mature-gated query refetches (the lists gain their new rows with the entrance wave).
- **Turning it off:** immediate, no confirmation, `toggle.off`; mature rows leave with `dismiss` and siblings close up on `snappy`; local copies (downloads, caches) are filtered on read (§8.0.8).
- **Marking:** where mature content is shown, it carries the 18+ badge (§7.20). Social surfaces never show another profile's mature activity to a profile whose gate is closed (§9.3).
- **States:** off, confirming (alert open, hold in progress), on, pending (switch shows a spinner while the PUT runs), error (the switch springs back with a toast "Couldn't change this setting"), blocked (no active profile: the row is disabled with "Choose a profile first" and a link).

### 7.26 Avatars and profile orbs

- **Profile orb:** a circle with the avatar preset's two-colour gradient and a white Light glyph; sizes 24 (chips), 32 (sidebar, activity rows), 44 (nav row), 96 (picker), 132 (picker focus); a 2 px ring in the profile's mood colour at 60 %; on glass surfaces the orb gets a glass bezel (0.5 px rim + specular).
- **Avatar presets** (12, gradient top-left → bottom-right, Phosphor glyph): Violet Spark `#8B5CF6 → #D946EF` sparkle; Cyan Rocket `#06B6D4 → #0EA5E9` rocket-launch; Rose Heart `#F43F5E → #EC4899` heart; Amber Coffee `#F59E0B → #F97316` coffee; Emerald Cat `#10B981 → #14B8A6` cat; Ember Flame `#EF4444 → #F59E0B` flame; Steel Blade `#94A3B8 → #475569` sword; Phantom `#6366F1 → #334155` ghost; Arcane Wand `#A855F7 → #6366F1` magic-wand; Lunar Moon `#0284C7 → #4338CA` moon; Starlight `#FACC15 → #F59E0B` star; Bookworm `#14B8A6 → #0891B2` book-open.
- **Idle physics:** on the picker only, orbs float with a slow drift (±3 px, 5 to 7 s periods, random phase), frozen under Reduce Motion.
- **Friend orb** (social): the same orb with a `bloom` ring; 18 px in activity rows, 56 px as drop targets and in the presence arc.
- **Names:** a profile name under or beside an orb, and in chips, is one line truncated with an ellipsis at its container width; the accessible name always carries the full name. New and edited names are capped at 30 characters (§8.6); an older name up to the server's 255 characters displays truncated and is kept unchanged unless the name field is edited.
- **Goal ring:** with a daily goal set, the active profile's orb in the nav row, the dock and the sidebar wears the goal ring of §9.2.2.
- **States:** default, hover (scale 1.04 + specular sweep), pressed (grows +12 px), focused (ring outside the mood ring), disabled (40 %), loading (the glyph becomes a spinner), selected (mood ring becomes 3 px `iris300`), error (orb shows a warning glyph overlay).

### 7.27 Tooltips and keycaps

- **Tooltip:** `glassThick` capsule, `footnote` `onGlass`, padding 6 12, 8 px from the target; delays per visionOS levels: 0 ms (icon-only buttons on focus), 150 ms (dock and sidebar collapsed), 600 ms (everything else on hover); appears on `snappy` from 0.9 scale with materialise; follows its target if it moves.
- **Keycap:** `mono` 12/600 `label1` on `surface3`, radius 6, min width 20, height 20, 0.5 px rim; combos separated by 4 px; on macOS web show ⌘ ⌥ ⇧ ⌃ glyphs. Shortcut hints appear in tooltips and in menus trailing each row.

### 7.28 Command palette (desktop web; phones get Search instead)

- **Open:** `mod+k` from anywhere, or clicking the sidebar search capsule. The capsule morphs into the palette: a `glassThick` panel 640 wide, radius 26, at 12 vh from the top, over `dimModal`, blooming on `morph`.
- **Field:** 56 tall, leading magnifier, placeholder "Search series, sources, screens and actions", trailing Esc keycap.
- **Footer:** a 32 px strip under the results in `caption1` `label3` with keycaps: "↑↓ move · ↵ open · Esc close" (web CP8).
- **Go to** lists every destination, including "Browse all" (`/library/browse`, `g b`).
- **Results:** grouped (Library, Sources, Go to, Actions, Skin), each group label `caption1` uppercase `label3`; rows 48 tall: leading visual 32 (cover, favicon, or glyph), title with matched characters in `iris400`, subtitle `footnote` `label2`, trailing Enter glyph on the active row; max 40 results. The active-row highlight is a glass droplet that travels between rows on `tab` as arrows move (a gentle travel instead of a jump), stretching with speed when a key is held.
- **Actions** include: Open settings, Switch profile, Toggle content mode, Continue reading (the most recent), Check for new chapters, Download next 10 of the current series (on series pages), Toggle solid glass, Legible text on / off, Sign out, and **Skin: Cinematic (restarts the app)**, which opens the restart alert (§8.25.2).
- **Keys:** `↑`/`↓` (wrap), Home/End, Enter, Esc, `mod+k` closes; focus returns to where it was.
- **States:** idle (recent items and suggested actions), typing, searching ("Searching…" live region), results, empty ("Nothing matches “{q}”."), error (a row "Library search failed · Retry" while other groups still show), offline (Library and Sources groups show only downloaded titles).

### 7.29 Download control (per chapter)

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

Tap cycles the natural action (download, cancel, retry, save again); on a saved chapter tap opens a small menu (Remove download, Extract text for dialogue search on phones, Save to Files on phones). Long-press on the row opens its context menu (Mark read, Mark unread, Download, Select), and "Select" enters multi-select with that row already picked, driving the bulk toolbar (§7.35). The ring's progress follows on `snappy`; completion morphs the ring into the droplet on `tick` with `download.done` (once per batch).

### 7.30 Banners and inline notices

- **Inline notice:** `surface1` slab radius 20, padding 12 16, leading 20 glyph in the semantic colour, text `callout`, optional plain action trailing; a 3 px leading bar in the semantic colour. Used for: overdue update checks, restore staged, "Downloads only run while the app is open" (phones), stale catalogue, AI budget used, mode-scope notes on Statistics.
- **Status capsule** (top nav row): `glassThin` 32 tall, glyph + `footnote` 600: "Offline" (`warning` wifi-slash), "Saved copy · 2 h" (`warning`), "Syncing" (spinner). Appears with materialise, leaves with dematerialise.
- **Global new-chapters capsule:** when new chapters arrive while the app is open (60 s poll), a `glassRegular` capsule drops in at the top (like a toast but persistent until acted on): cover stack of up to 3 covers, "5 new chapters in 3 series", "View" plain button; swipe up dismisses until a newer notification arrives. Hidden inside readers and on Updates.
- **App update capsule** (web service-worker update, Android APK): "A new version is ready" + "Reload" (web) or "Update" (Android, opens the update sheet). Bottom-centre above the dock (phone) and bottom-centre of the content column (desktop), so it never shares the bottom-left corner with toasts.

### 7.31 Image viewer

- **Open:** from a cover on series detail, a page thumbnail, an OCR result, or a shared stat card preview; the image zooms from its thumbnail on `zoom`; background `#000000` with the ambient field at 40 %.
- **Gestures:** pinch 1× to 4× with focal-point preservation and rubber-band beyond (§4.5); double-tap toggles 1× ↔ 2.5× at the tap point on `camera`; pan when zoomed with momentum and edge rubber-band; at 1× a vertical drag dismisses: the image scales `1 − min(|dy| / 1200, 0.15)`, its radius grows 0 → 28, the backdrop opacity follows `1 − min(|dy| / 320, 1)`, and release past the projection threshold (§4.6) flies it back into its thumbnail on `zoom` carrying the release velocity; otherwise it springs back on `settle`.
- **Chrome:** `glassClear` close button top-left (44); share (the system share sheet on phones and Web Share where supported) and, on desktop web, save, top-right; the chrome fades after 2 s idle.
- **Keys:** Esc closes, `+`/`-`/`0` zoom, arrows pan.
- **States:** loading (the thumbnail stays, upscaled with blur 8 until the full image arrives, then sharpens over `fadeIn`), error ("Couldn't load this image" + Retry on the glass), zoomed.

### 7.32 Scroll edges and scrollbars

- **Soft edge** (`edgeSoft`) under every floating top row and above every floating bottom group, one per edge; its opacity follows how much content is under it (0 at rest at the top of a list, 1 once content scrolls under), so the edge "appears" as content arrives beneath it.
- **Hard edge** (`edgeHard`) under pinned section headers.
- **Scrollbars:** web: a 6 px capsule thumb `rgba(255,255,255,0.28)` on a transparent track, widening to 10 px on hover (`scrollbar-width: thin` fallback in Firefox); shown only while scrolling and on hover of the scroll area. Flutter: `CupertinoScrollbar` styling on both platforms (thickness 3, pressed 8, radius 1.5 / 4), draggable when it is pressed for 200 ms. Long lists (chapter lists over 200 rows, the source catalogue) get a **fast-scroll thumb**: dragging the scrollbar shows a `glassThin` capsule bubble with the chapter number or the first letter at the thumb, `selection` tick per 10 chapters.

### 7.33 Pull to refresh

- **Where:** Home, Library, Sources, Source catalogue, Updates, History, Bookmarks, Collections, You (activity). Not Downloads (local data).
- **The droplet:** as the list is pulled down, a `glassThin` droplet hangs from the top edge on a meniscus neck: the droplet's radius grows from 0 to 16 px over the first 60 raw px, the neck stretches thinner as the pull continues (the neck width is `12 × (1 − progress)` px), and the `droplet` glyph inside rotates with the pull. At 100 raw px the neck **snaps**: the droplet pops free (`refresh.arm` haptic, `droplet` sound when enabled), springs to the 60 px rest line on `lens`, and becomes a liquid ring spinner while loading. Released before the trigger: the droplet retracts into the edge on `settle`.
- **Done:** the spinner fills into a check (new data: `refresh.done` haptic, the list's new rows enter with the wave) or fades (no change), and the list returns to 0 on `settle`.
- **Physics:** Flutter `CupertinoSliverRefreshControl` (trigger 100, indicator extent 60) with a custom `builder` drawing the droplet; `BouncingScrollPhysics` on both platforms. Web: about 60 lines of pointer handling on the list container, touch only, only at `scrollTop === 0`, rubber-band displacement with `c = 0.55`, `overscroll-behavior-y: contain` so the browser's own pull-to-refresh never fires.
- **Alternatives:** a refresh item in the screen's ⋯ menu; `r` on desktop; `aria-live` announcement "Updated" or the error.

### 7.34 Swipe row actions

- **Where:** notifications (mark read), chapter rows (mark read/unread, download), downloads (remove), history (mark finished, open series), sessions (revoke), bookmarks (remove), recommendation cards (Not interested), queue rows (retry, remove).
- **Reveal:** rows drag horizontally 1:1 (after 10 px, direction-locked); actions behind the row are **separate pills** (44 tall, 88 wide slots) drawn as content twins (§2.4.1: `rgba(19,19,23,0.62)` fill, 0.5 px rim, inner light, no backdrop read, because they live inside a scrolling list) that inflate from scale 0.6 to 1.0 as they are revealed, their glyph and label in the action's semantic colour; releasing past half the reveal width opens the tray on `snappy`, otherwise it closes on `settle`.
- **Full swipe:** past 60 % of the row width (projected), the leading pill stretches to fill the gap and turns solid in its colour, `threshold.cross` haptic; crossing back re-shrinks it with `rigidBack`. Commit slides the row out on `dismiss` with the release velocity and collapses the gap on `snappy`; destructive actions show a 5 s Undo toast instead of a confirm.
- **Alternatives:** the row's ⋯ menu holds every swipe action; desktop shows the actions as hover icons and on keys (`m` mark read, `d` download, `x`/`Delete` remove with undo, `u` undo); VoiceOver/TalkBack custom actions (`Semantics(customSemanticsActions:)`, web menu button).
- **Web:** enabled only on `pointer: coarse`; `touch-action: pan-y` on the row; Motion `drag="x"` with `dragDirectionLock`, `dragElastic: 0.1`.

### 7.35 Drag to reorder and bulk selection

- **Reorder** (source pins, collections list, collection members, library manual order, download queue priority, profiles): press 450 ms on a row (or drag its handle immediately): the row lifts (scale 1.03, rim brightens, shadow `0 12px 28px rgba(0,0,0,0.55)`), `reorder.lift` haptic; neighbours part around the gap on `snappy`, `selection` tick each time the item passes a slot; drop settles on `snappy` with `soft(0.5)`. Edges auto-scroll at up to 1200 px/s proportionally to the distance into the 64 px edge zone. Keyboard: `alt+↑/↓` (grids also `alt+←/→`) moves one slot, `alt+shift+↑/↓` to top/bottom, announced in `aria-live="assertive"` ("Solo Leveling moved to position 3 of 12"). Menu items "Move up / Move down / Move to top / Move to bottom" exist on every platform (WCAG 2.5.7).
- **Bulk selection:** "Select" in the nav row or ⋯ menu, "Select" in any item's context menu (that item starts selected), or `x` on desktop enters select mode; each tap toggles; on touch, dragging across items after the first selection paints a range (the list auto-scrolls at its edges); desktop Shift-click selects ranges. In select mode two assist chips sit above the grid or list: **"Select all ({n} visible)"** (selects every item the current filters show, up to the loaded page of 200, and says so: "Selected 200 of 412 shown") and **"None"**; `mod+a` selects all and `Esc` clears before it exits. A **floating glass toolbar** replaces the bottom accessory slot: `glassRegular` capsule 52 tall with "{n} selected" (`mono` count), and actions as glass icon buttons with labels on desktop: Favourite, Unfavourite, Mark read, Mark unread, Add to collection, Download, Remove (destructive, with Undo). While a batch runs, the toolbar shows a liquid progress fill with "{done} of {total}" and a Stop button; the result appears as a toast ("12 marked read · 1 failed" + "Retry failed"). Esc or "Done" exits.

### 7.36 Content-mode switch (Manga | Novels)

Exists only when the server enables novels. A two-segment control (§7.6) with glyphs `strip-scroll` and `book-open`: in the sidebar (desktop), in the nav row of every screen whose lists follow the mode (Home, Library and its sections, Sources, Search, Updates, Statistics, collection detail, You) as a compact 32 px capsule ("Manga" with a chevron) that expands on press into the two segments (a `morph`) with the line "One setting for the whole app", and in the long-press menu of the Library tab. Switching refilters every list (the lists run the entrance wave from the switch's position), `select` haptic, and the choice persists per profile.

### 7.37 Depth: the stack overview, the back menu and the depth indicator

Meniscus keeps the ordinary push model (§8.0.4). On top of it, long-pressing Back reveals the stack you are standing on.

**Depth.** Each dock tab (phone) or sidebar section (tablet, desktop) keeps its own stack. Depth is the number of screens pushed above the tab's root (the root is depth 0; a sheet route counts as a level; the reader counts as one level). Depth drives the `nav.push` haptic intensity (§5.1), the `push-1` … `push-4` sounds (§6) and the depth indicator. Depth beyond 4 plays and weighs as 4.

**Stack overview (iOS and Android, Flutter).**

- **Open:** long-press (450 ms) on any Back button (the nav-row back button, the reader's back button, a full-height sheet's back button), or `mod+\` on a hardware keyboard. `stack.open` haptic (`ahap:fan`), `fan` sound.
- **Snapshots, not live routes:** when a route is covered by a push, the router captures it once with `RepaintBoundary.toImage(pixelRatio: 0.5)` and keeps the `ui.Image` with the route (released when the route pops or memory pressure fires `didHaveMemoryPressure`, in which case that card shows its title over the level's ambient colour instead; a memory rule applied the same on every device). Each snapshot records whether its route shows mature content, so the 18+ purge (§8.0.8) can drop it. The overview never rebuilds covered routes.
- **Layout:** the current tab's levels (up to 8; older ones compress into a "+N earlier" card at the top) fan out in 3D on `smooth`: each card is its snapshot at scale 0.62, `rotateX(14°)` about its bottom edge, radius 26, spaced vertically by 28 % of its scaled height, deepest at the top, the current screen at the bottom; each card has a 0.5 px **strata rim** along its top edge in that level's ambient colour (§2.1.8 rim tint) and, beneath it, its title in `subhead` 15/600 `label1` and its depth number in `mono` `label3` ("2"). Everything else takes `dimModal`.
- **Tap a card:** it comes forward to full screen on `zoom` while every level above it drops away front to back (40 ms stagger, `dismiss`), which is a `popUntil` to that route; `stack.pick` haptic, `root` sound when the pick is the tab root.
- **Swipe a card sideways** (projected past 40 % of its width): removes that level and every level above it (same animation), `threshold.cross` at the line.
- **Keys:** `↑`/`↓` move between cards, Enter picks, `Delete` removes, Esc closes.
- **Accessibility:** VoiceOver and TalkBack read the list as "Back to {title}, level {n} of {total}" rows; the back button's semantics hint says "Double-tap and hold for all levels"; with Reduce Motion or a screen reader active the overview opens as the flat back menu below instead of the fan.

**Back menu (mobile web and desktop web).** The App Router cannot keep covered pages mounted, so the web never fans live screens (no plane stack). Instead:

- **Open:** long-press (500 ms) on the Back button (touch), right-click on it (pointer), or `mod+\`.
- **Content:** a `glassThick` menu blooming from the Back button (§7.23 anatomy): one row per level of the current tab's stack, newest first, each with its 24 px leading visual (the series cover for series and reader levels, else the screen's glyph), its title, and its depth number trailing in `mono`; the tab root last, labelled "{Tab} home".
- **Source:** the Glass shell records a per-browser-tab stack in `sessionStorage['mm.glass.stack']` (an array of `{path, title, depth, tab, mature}` appended on each push, trimmed on pop and on `popstate`), so the menu survives reloads; `mature` marks levels whose series is 18+, for the purge of §8.0.8. Cover thumbnails are not stored: the menu draws them from the image cache at open time. Choosing a row calls `history.go(−n)`, where `n` is the number of levels above it.
- **Keys and states:** arrows, Enter, Esc; with a single level the long-press does nothing and the menu is not offered.

**Depth indicator.** Where the soft scroll edges and the large title are hidden (the readers and full-height sheets), the Back button shows the `strata` glyph instead of `caret-left`: 1 to 4 bars, the lit ones (Fill) counting the levels you came through, each lit bar tinted with that level's ambient rim colour; newly lit bars fill left to right 40 ms apart on `tick`. Its accessible name is "Back to {previous title}, {n} levels deep".

### 7.38 AI surfaces: machine light, the thinking orbit and the AI notice

Every surface that shows AI output uses these three pieces, so the external AI always looks and speaks the same.

- **Machine-light badge.** A `sparkle` glyph (Regular 14, Fill when the text is final) in `machine` `#5CE1E6` leads every AI-written line: rail subtitles ("Because you read …"), every card's `why` line, the recap deck's eyebrow, the For you answers. AI cards carry a 0.5 px `machineRim` rim instead of the `slabBorder`. Accessible name suffix: ", suggested by AI".
- **Thinking orbit.** A 28 px (inline, next to a rail title or inside a button) or 64 px (a screen's loading area) glyph: three dots (4 / 3 / 2 px at 28 px; 8 / 6 / 4 px at 64 px) on a tilted ellipse (rx 24, ry 9 at 64 px, tilt 12°, drawn as a 0.5 px `machineRim` stroke over a `machineWash` fill), one revolution per 1,400 ms; the near dot is at full brightness and 1.2 scale, the far dot at 0.4 and 0.8, all in `machine`. Reduce Motion: the three dots pulse in sequence in place (opacity 0.4 ↔ 1, 1.2 s). Beside the 64 px orbit, an **honest phase line** in `callout` `label2` steps through what the server reports on its SSE `phase` field, or on timers when it reports nothing:

  | Phase | Line | Timer fallback |
  |---|---|---|
  | `reading_library` | "Reading your library" | 0 s |
  | `asking` | "Asking for ideas" | 1.5 s |
  | `checking_sources` | "Checking which of your sources have them" | 4 s |
  | `slow` | "Still working. This can take up to a minute." | 15 s |
  | recaps (`writing`) | "Writing your recap" | 0 s |

  After 40 s the request is abandoned: "That took too long. Try again." with a Try again button (and for recaps, Continue).
- **AI notice.** When AI is unavailable, the surface shows one quiet inline notice: a `surface1` slab, radius 20, the `sparkle-slash` glyph 20 in `label2` (never `danger`: an absent AI answer is not an error), the short or long line from §9.1.5 for the reason, and the non-AI path beside it (the local rail, world picks, Continue). Rails use the short line; For you, recaps and More like this use the long line.
- **States:** thinking (orbit + phase line), ready, stale (a `caption1` `label3` stamp "Picked 3 days ago" beside the rail title or footnote when `generated_at` is older than 24 h), partial (what arrived renders; a rail that failed is omitted; an answer list shows "Some picks didn't come through."), unavailable (the AI notice).

### 7.39 Charts

Used by Statistics, the You card sparkline and Wrapped. Drawn with SVG on the web and `CustomPainter` in Flutter; no chart library.

- **Marks:** bars `iris500` with 3 px rounded tops, width `min(16, available / n − 3)` px, empty days as 2 px `fill2` stubs; lines `aurora1` `#8FD8FF` 1.5 px (the only second-axis colour) with 4 px round markers; heatmap cells 10 px squares, 2 px gaps, levels `heat0` … `heat4` (§2.8.1); radar polygon `iris500` fill at 24 % with a 1.5 px `iris400` outline and 4 px vertex dots; the 24-hour clock as 24 radial bars from 40 to 80 px radius in `iris500` at opacity by value. Axes and labels `caption2` `label3`; values `mono`; a baseline and quarter lines at `rgba(255,255,255,0.06)`, no other gridlines. Status breakdowns use the status colours of §2.1.4.
- **Readout.** Tapping, dragging across or hovering the chart shows a readout capsule above the chart ("Mon 21 Sep · 42 pages · 3 chapters · 25 min") with a small lens ring over the selected mark, both drawn as content twins (§2.4.1), because charts scroll with their page; dragging scrubs day by day with `select` ticks.
- **Keyboard:** each chart is one tab stop; arrows move the selected bar or cell (heatmap: `←`/`→` by day, `↑`/`↓` by week), Home/End jump to the ends, and the readout is an `aria-live="polite"` region that speaks the same line. Flutter: the chart is a `Semantics` node with `onIncrease`/`onDecrease` actions stepping the selection and a live `value`.
- **Show as table.** Every chart has a plain "Show as table" button (keyboard `t` when the chart has focus) that swaps the chart for an accessible data table with the same numbers (web `<table>` with `<caption>` and `scope` headers; Flutter a `Table` inside `Semantics(container: true)`), and "Show as chart" to swap back; the choice persists per chart per profile in scoped storage (`mm.glass.prefs.chartTables`, §15.5).
- **Summary.** Above every chart, one sentence in `footnote` `label2` states the main fact ("Most on Saturday 19 September: 120 pages."), so the chart is never the only carrier.
- **Data honesty:** zero shows as "0", never a dash or an empty mark; pace and time-left figures appear only after 2 minutes of samples; a range with no data shows "Nothing read in the last 7 days" inside the chart area; partial days (today) are drawn at 60 % opacity with "so far" in the readout.
- **Motion:** bars rise from the baseline on `snappy` in a wave from the left; the radar springs out from the centre on `celebrate`; switching ranges re-runs the rise. Reduce Motion: marks appear with a 150 ms fade.

---

## 8. Per-screen specs

Every screen lists: layout per platform (desktop web, mobile web, iOS, Android; "phone" when the three phone targets match), hierarchy, the signature moment, transitions in and out, gestures, all states, keyboard shortcuts on web (the same map is registered with Flutter `Shortcuts`/`Actions` for hardware keyboards on iPad and Android tablets), and inventory coverage.

### 8.0 Shell, navigation and routes

#### 8.0.1 Frames

| Frame | Where | Composition |
|---|---|---|
| **Bare** | Setup, splash, login, register, root error, offline fallback | Ambient aurora field, no navigation, content column max 420 (phone full width minus 32) |
| **Takeover** | Profile picker, onboarding, Wrapped | Full-bleed field in the focused mood or art, no dock, no sidebar; a close or back nav button only where it makes sense |
| **Phone app** | Every other screen below 768 px on the web (and a coarse-pointer web viewport under 500 px tall, i.e. a landscape phone); on Flutter every window whose shorter side is under 600 px, in both orientations | Floating nav row (top), large title in content, dock + search orb + bottom accessory (bottom), soft edges at both ends; content runs edge to edge beneath |
| **Tablet app** | 768 to 1023 px on the web; on Flutter a shorter side of 600 px or more with a width under 1024 px (iPad portrait, Android tablets portrait) | Collapsed 76 px glass sidebar on the left instead of the dock, floating nav row on the right, accessory as a floating capsule bottom-centre of the content column |
| **Desktop app** | 1024 px and wider on the web; on Flutter a shorter side of 600 px or more with a width of 1024 px or more (iPad landscape at 1180–1366 px, Android tablets landscape) | 280 px inset glass sidebar, content column up to 1440 px, toolbar row, toasts bottom-left, the desktop accessory at the sidebar's foot (§7.16) |
| **Manga reader** | Reader routes | Black canvas, floating reader capsules (§8.14), no dock or sidebar; desktop: the strip in the centre with material side panels |
| **Novel reader** | Novel routes | The paper edge to edge; floating capsules tinted to the paper; desktop: the page column centred with optional side panels |
| **Landscape phone reader** | Readers on a rotated phone | Chrome shrinks to two corner capsules (back + title top-left, settings + page top-right), the bottom capsule becomes a slim scrub rail |

**Orientation.** Phones (Flutter shorter side under 600 px) are locked to portrait everywhere except inside the two readers: `SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])` is set by the shell and widened to all four orientations by the readers' routes on enter and restored on exit. Tablets rotate freely and change frame with their width. The web cannot lock orientation, so a landscape phone browser gets the phone frame by the rule above.

#### 8.0.2 Information architecture

| Destination | Phone | Tablet and desktop |
|---|---|---|
| Home (AI home, continue, rails) | Dock tab 1 | Sidebar "Home" |
| Library (shelf, browse all, collections, history, bookmarks, downloads) | Dock tab 2; sections as in-page tabs; "Browse all" as the Shelf toolbar's trailing plain button and in the Library tab's long-press jump list | Sidebar "Library" with its five children; "Browse all" in the Shelf toolbar, the palette's Go to group and `g b` |
| Sources (list, catalogues) | Dock tab 3 | Sidebar "Sources" + pinned sources |
| You (profile, stats, Circle, settings, about, admin) | Dock tab 4 | Sidebar footer (profile capsule, Settings, Status) + "Circle" and "Stats" items |
| Search | Search orb | Sidebar search capsule → command palette; `/search` for the full screen |
| Updates | Bell nav button on Home (with count badge); Home tab dot; Home long-press menu | Sidebar "Updates" with count |
| Downloads | Library tab section; bottom accessory while downloading; Library tab badge | Sidebar Library → Downloads |
| Recommendations ("For you" and Ask) | Home rails + "Ask" in Search idle state + Home ⋯ menu | Sidebar "For you" (under Home) + command palette action |
| Statistics and Wrapped | You tab card; streak chip on Home greeting | Sidebar "Stats" |
| Circle (social) | You tab card + Home "From your Circle" rail + friend orbs | Sidebar "Circle" |
| Dialogue search (OCR) | Search scope "Dialogue"; You → Library group | Sidebar item (Manga mode) and Search scope |
| Settings | You tab | Sidebar footer |
| System status (admin) | You → Administration | Sidebar footer "Status" |

#### 8.0.3 Routes (the shared `design/contract.json` route contract)

The Glass router registers every `ScreenId` and path of the shared contract (the same table `cinematic/DESIGN.md` §8.0.3 uses), so a URL or deep link opens the same screen in either skin; only the presentation differs. The web `screens` map `satisfies Record<ScreenId, Screen>` and Flutter's completeness test covers every id.

| ScreenId | Path(s) | Glass name | Presented as (phone / tablet and desktop) | Spec |
|---|---|---|---|---|
| `setup` | `/setup` | Connect your server | Bare page (apps). The web's `setup` screen is a server redirect to `/login`, so the record stays complete | §8.1 |
| `login` / `register` | `/login`, `/register` | Sign in / Create account | Bare | §8.3, §8.4 |
| `profiles` | `/profiles` | Who's reading? | Takeover | §8.5 |
| `profileNew` / `profileEdit` | `/profiles/new`, `/profiles/:id/edit` (mobile aliases `/profiles/create`, `/profiles/edit/:id`) | Add profile / Edit profile | Large sheet over the picker / 560 px window | §8.6 |
| `profilesManage` | `/profiles/manage` | Profiles | Pushed page / page | §8.6 |
| `onboarding` | `/welcome?step=1..7` | First visit | Takeover | §8.7 |
| `tonight` | `/` | Home | Tab root | §8.8 |
| `library` | `/library` (`?q&status&sort&fav&view&select`, the contract's names, plus Glass's query-state extras `tab`, `reading_status` and `tags`), `/library/browse` (same screen, toolbar expanded) | Library | Tab root / page | §8.17 |
| `feature` | `/sources/:sourceId/series/:seriesKey` | Series detail (manga) or Book page (novel), by `content_kind` | Sheet (medium → large) / 960 px window over the recessed page; a deep link without a parent renders it as a full page | §8.12, §8.13 |
| `featureByFollow` | `/library/:followedId` | Series detail | Resolves the follow row and renders `feature` in place (no redirect flash) | §8.12 |
| `updates` | `/updates` (`?tab=unread\|followed`) | Updates | Pushed page / page | §8.21 |
| `collections` / `collection` | `/library/collections`, `/library/collections/:id` (mobile aliases `/collections…`) | Collections / collection | Library section / page; detail is a pushed page | §8.18 |
| `history` / `bookmarks` | `/library/history`, `/library/bookmarks` (`?source&series`: a dismissible filter chip naming the series) | History / Bookmarks | Library sections / pages | §8.19, §8.20 |
| `picks` | `/library/recommendations` (`?genre=`: the For you sections filtered to one genre, with a dismissible genre chip) | For you | Pushed page / page | §9.1.2 |
| `numbers` | `/library/statistics` (`?range=7\|30\|90\|year&year=`; `year` is the calendar year the screen's Wrapped card opens, default the current year; the Year range itself is the rolling 365 days, §9.2.1) | Your reading | Pushed page / page | §9.2.1 |
| `annual` | `/library/statistics/annual/:year` | Wrapped | Takeover | §9.2.3 |
| `recap` | `/recap/:sourceId/:seriesKey?to=:chapterKey` (`&scope=chapter` for a chapter recap) | Previously on | Sheet over the series detail (a deep link opens the series sheet first, then the recap sheet over it) / window | §9.1.3 |
| `circle` / `circleMember` | `/circle` (`?tab=activity\|letters\|shelves`), `/circle/:profileId` | Circle / a friend | Pushed page / page; a friend is a sheet / window | §9.3.1, §9.3.5 |
| `discover` | `/search` (`?q&scope=all\|library\|sources\|dialogue\|text\|ask`) | Search | Search orb expansion / page (`text` is Glass's novel-text scope; Cinematic treats it as `all`) | §8.9 |
| `sources` / `source` | `/sources`, `/sources/:sourceId` (`?mode&genre&q`) | Sources / source catalogue | Tab root / page; pushed page | §8.10, §8.11 |
| `reader` | `/reader/:sourceId/:seriesKey/:chapterKey` (`?page&at&all`; mobile aliases `/library/read/:s/:k/:c` and `/sources/:s/series/:id/chapters/:c/read`) | Manga reader | Immersive | §8.14 |
| `readAll` | `/read-all/:sourceId/:seriesKey` (`?from&page&at`) | Read all | Immersive | §8.14 |
| `novel` | `/novels/:sourceId/:seriesKey/:chapterKey` (`?page&para&at&listen=1`; mobile alias `/novels/read/…`) | Novel reader | Immersive | §8.15, §8.16 |
| `downloads` | `/downloads` (`?tab=chapters\|queue\|storage`) | Downloads | Library section / page | §8.22 |
| `dialogue` | `/ocr` (`?q`; mobile alias `/ocr/search`) | Dialogue search | Pushed page / page | §8.23 |
| `index` | `/more` | You | Tab root (phone); on desktop `/more` redirects to `/settings` | §8.24 |
| `settings` | `/settings`, `/settings/:section` (the shared slugs below) | Settings | Pushed page / page with a section list | §8.25 |
| `status` | `/admin/status` | System status | Pushed page / page | §8.26 |
| `readerLanding` | `/reader` | Pick something to read | Bare page on the web; on Flutter a redirect to `/library` (as Cinematic registers it, `cinematic/DESIGN.md` §15.10 S7), so the completeness test covers it | §8.14.10 |

**Library query names.** The contract's names are canonical for both skins: `q` (search), `status` (the progress chips: `reading`, `unread` for "Not started", `completed`), `fav=1`, `sort`, `view`, `select=1`; Glass adds `tab` (the Library section), `reading_status` (the Filters sheet's shelf status: `unread`, `reading`, `completed`, `on_hold`, `plan_to_read`, `dropped`) and `tags` (comma-separated tag ids). The shared `useLibraryQuery()` / `libraryQueryProvider` maps them onto `GET /library/series` (`search`, `reading_status`, `is_favorite`, `tag_ids`) and also reads the web's older names `search` and `is_favorite` as aliases, so existing bookmarks of `/library/browse?search=…` keep working.

**Settings section slugs** (the shared `/settings/:section` list of `cinematic/DESIGN.md` §8.30.1, in `design/contract.json`): Glass maps its sections onto them and adds one. `profile` → Account (§8.25.14); `appearance` → Appearance and skin (§8.25.1); `reading-manga` → Reader defaults (§8.25.3); `reading-novels` → Reader defaults, scrolled to its Novels group; `listen` → Reader defaults, scrolled to its Listen group; `ambient` → Reader defaults, scrolled to its Ambient group; `storage` → Storage (§8.25.9); `content` → Content (§8.25.4); `circle` → Circle and privacy (§8.25.15); `feedback` → Sound and haptics (§8.25.5); `notifications` → Notifications (§8.25.6); `keyboard` → Shortcuts (§8.25.13); `server` → Server (§8.25.11, apps); `admin` → the Administration list (System status, Members, Backup); `diagnostics` → Diagnostics (§8.25.12); `about` → About (§8.25.14, with the licences at `?sheet=licenses`); pushed pages `security`, `members`, `backup`. **Glass addition:** `ai` → AI and recaps (§8.25.16); Cinematic renders `/settings/ai` as `reading-manga`, where its Previously on setting lives. Mobile's existing `/settings/storage`, `/settings/backup` and `/settings/diagnostics` keep their paths. Deep links from other screens use these slugs (Updates summary → `/settings/notifications`; a Downloads pause reason → `/settings/storage`; Statistics' daily goal → the goal menu on Statistics itself).

The splash is not a route: it is the skin's `splash` (the `Skin` interface of `stack-decision.md` §2.3), played by the Glass shell before the first route paints (§8.2). Status screens (`not found`, route error, root error, offline fallback) are the router's error handlers, not screen ids (§8.28).

**URL state for sheets (a rule, not a list of favourites).** Every sheet, desktop panel and desktop window is URL state on the route it covers, `?sheet={id}` in kebab-case, so Android back, browser back and the iOS swipe close it; the only exceptions are pickers anchored to a control (menus, context menus, the speed dial, the sleep menu, popovers such as the go-to-page popover), which close on Esc, back or an outside tap without a history entry. A sheet that needs a parameter adds it beside the id (`?sheet=recommend&series=…`). The ids, once each:

| Screen | Ids |
|---|---|
| Readers | `chapters` (manga chapter list), `settings` (reader settings), `contents` (novel), `type` (novel Aa), `voices` (the orbit), `cast`, `player` (listen full player), `soundscape`, `note` (bookmark note) |
| Series and book | `tags`, `recommend`, `audiobook`, `save-files` (Save to Files), `how-it-works` (OCR explainer), `offer` (the recap offer), `image` (image viewer) |
| Library and collections | `filters`, `manage-tags`, `collection-new`, `collection-edit`, `collection-share`, `add-series` |
| Downloads | `save-files`, `run` (update-run detail, §8.21) |
| Global | `whats-new`, `app-update` (Android update sheet), `shortcuts` (the `?` sheet), `licenses` (on `/settings/about`) |
| Circle | `letter-note` (recommend note) |

The recap itself is a route (`recap`) presented as a sheet, and so is a friend (`circleMember`).

#### 8.0.4 Transitions shared by every screen

| Navigation | Motion |
|---|---|
| Push (row, button, link) | Incoming page slides in from the trailing edge on `page` (100 % → 0); the outgoing page moves −30 % and dims under `rgba(0,0,0,0.3)`; the incoming large title runs the letter reveal once per session per screen; the nav row's title capsule cross-fades; `nav.push` fires at the new depth's intensity (§5.1) and `push-{d}` plays when UI sounds are on (§6). Web: React `<ViewTransition>` with `transitionTypes={['nav-forward']}`, CSS keyframes eased by the `page` spring's `linear()` export |
| Pop | The reverse; driven by the back gesture when there is one; `nav.pop` and the `back` sound |
| Long-press Back | The stack overview (Flutter) or the back menu (web), §7.37 |
| Poster → series detail | **Zoom**: the poster flies (shared element: web `ViewTransition name="cover-{sourceId}-{seriesKey}"`, the same name Cinematic uses; Flutter `heroine` 0.7.2) into the detail sheet's cover slot on `zoom`, carrying any throw velocity; the sheet body rises beneath it on `sheet`; the page behind recedes by sheet position |
| Chapter row → reader | **Dive**: the row's rectangle expands to full screen on `zoom` (clip reveal from the row's rect), the page behind scales to 0.94 and darkens to black; the reader's first page fades in over the last 40 %; `reader.enter` (`ahap:dive`) and the `dive` sound |
| Reader → back | Edge swipe drags the reader right (1:1), showing the detail sheet recessed beneath; release projects; `dismiss` or `settle` back |
| Tab switch | No slide: the destination appears with a 120 ms cross-fade and its content wave radiates from the tapped tab's position; each tab keeps its own stack and scroll offset |
| Sheet routes | §7.10 |
| Skin restart | §8.25.2 |

Reduce Motion: every row becomes a 200 ms cross-fade. Browser back and forward animate nothing (`default: "none"`), so the UA's own swipe animation never plays twice; any `popstate` handler checks `PopStateEvent.hasUAVisualTransition`.

#### 8.0.5 Back per platform

| Platform | Mechanism |
|---|---|
| iOS | `swipeable_page_route` 0.4.8 `SwipeablePage(canOnlySwipeFromEdge: false)` for **full-width** back swipes (iOS 26 parity) on every pushed page; the readers use an edge-only 20 px strip, disabled above 1× zoom and in paged mode. A horizontal pager or rail under the finger wins until it is at its leading edge. Haptic `threshold.cross` when the projection crosses 50 %; a long-press on the back button opens the stack overview (§7.37) |
| Android | `MaterialPage` with `PredictiveBackPageTransitionsBuilder` (the page shrinks to 90 % and floats as a glass card, x shift `(screenWidth/20 − 8)`); `android:enableOnBackInvokedCallback="true"`; sheets shrink by back progress (a custom `PredictiveBackRoute` on the sheet route scales it 1 → 0.94 and lifts it 12 px). Tab roots: back goes to Home first, then leaves the app |
| Mobile web | History entries for every route and closable sheet; no custom edge swipe in a browser tab; `overscroll-behavior-y: none` on the root only (x stays free for the OS gesture); a long-press on the back button opens the back menu (§7.37). **Installed PWA on iOS** (`display: standalone`, detected by `matchMedia("(display-mode: standalone)")`) has no system back swipe, so Glass adds its own: a leading 24 px edge strip that drags the page 1:1 exactly like the iOS app's back swipe (projection past 50 % pops through `history.back()`), active only in standalone mode and never in the readers (they keep their own 20 px rule) |
| Desktop web | A visible back chevron in the toolbar row, `Esc` closes the topmost layer; `alt+←` stays the browser's; right-click the chevron or `mod+\` for the back menu |

**Who owns a horizontal drag.** A component that owns horizontal drags wins inside its own bounds: pagers and rails (until they are at their leading edge and the drag goes right), swipe rows (Updates "swipe right → Mark read", the Hidden-from-Circle rows, every §7.34 row), the Statistics chart scrub, the spotlight, the voice orbit and the dock. Inside such a component the iOS back swipe starts only in the leading 24 px (like the reader's strip), so a rightward row swipe on a pushed page never pops the page. **Wrapped and onboarding** are `NoTransitionPage` takeovers with no back swipe at all; Wrapped closes by swipe down or its close button, onboarding by "Skip". **Android gesture navigation** treats both screen edges as system back, so the readers call `setSystemGestureExclusionRects` (through the `mm/platform` channel, refreshed on layout): the scrub rail excludes a 200 dp tall band centred on the thumb (the OS caps exclusion at 200 dp per edge), and the brightness band excludes the middle 200 dp of the leading edge; the rest of both edges stays system back. **iOS**: the reader's brightness band starts at x ≥ 24 px, so it never overlaps the 20 px back strip.

#### 8.0.6 Global keys (web; hardware keyboards on Flutter)

| Keys | Action |
|---|---|
| `mod+k` | Command palette |
| `mod+b` | Toggle the sidebar |
| `?` | Keyboard shortcuts sheet (only what works here) |
| `/` | Focus the current screen's search or filter |
| `g h` · `g l` · `g b` · `g s` · `g u` · `g d` · `g c` · `g t` · `g f` · `g p` · `g ,` | Go to Home, Library, Browse all, Sources, Updates, Downloads, Circle, Stats, For you, Profiles, Settings (1 s chord window) |
| `shift+r` | Recommend the focused series to someone (the recommend sheet, §9.3.4) |
| `mod+\` | The back menu of the current stack (§7.37) |
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

#### 8.0.7 Platform rules applied to every screen

- **iOS:** status bar light; edge-to-edge; `CADisableMinimumFrameDurationOnPhone` true (120 Hz); haptics through gaimon; Dynamic Type through `MediaQuery.textScalerOf` with the caps in §3.3; Reduce Transparency read through the `mm/platform` channel.
- **Android:** edge-to-edge with transparent status and navigation bars (light icons); the readers switch to `immersiveSticky`; predictive back; high refresh rate on launch; API 34 haptic constants through the channel with version guards (minSdk 24).
- **Mobile web (PWA):** `display: standalone`, `theme-color` `#000000`, `apple-mobile-web-app-status-bar-style: black-translucent`; the startup images are the shared plain `#000000` PNGs of `cinematic/DESIGN.md` §12.3 (1290 × 2796, 1179 × 2556, 1170 × 2532 and 2048 × 2732, each with its `media` query), because a black frame is skin-neutral; no haptics on iOS Safari, `navigator.vibrate` subset on Android Chrome.
- **Dark everywhere, including browser defaults:** `:root { color-scheme: dark; }` in the Glass CSS and `<meta name="color-scheme" content="dark">` in the root layout, so native scrollbars, date inputs, `<select>` fallbacks and form controls render dark on a light OS; Chrome's autofill is overridden on every well (`input:-webkit-autofill { -webkit-text-fill-color: var(--mm-color-label1); box-shadow: 0 0 0 50px var(--mm-color-fill3) inset; caret-color: var(--mm-color-iris400); }`); Flutter builds `ThemeData(brightness: Brightness.dark, colorScheme: ColorScheme.dark(surface: Color(0xFF000000)))` so every stock widget, the keyboard appearance and the system dialogs are dark.
- **Desktop web:** keyboard first; hover states on everything interactive; `:focus-visible` rings; right-click opens context menus; trackpad pinch in the readers.
- **Offline everywhere:** the "Offline" status capsule in the nav row; lists fall back to cached or downloaded data where the data layer supports it; server-only screens show the offline lens.

#### 8.0.8 Cross-cutting rules every screen follows

- **Glass before it ships.** Glass is built after Cinematic has flipped (`stack-decision.md` §3 release model). Until both clients pass Glass's completeness and boundary tests, Glass is reachable only through the Settings → Diagnostics debug row "Preview Glass skin"; the skin picker, onboarding step 2, the profile form's skin row and the command palette's skin action show Glass only once `flags.glass_available` in the shared `design/contract.json` is `true` (the one availability flag both skins read, `cinematic/DESIGN.md` §8.0.7; generated into `FLAGS.glassAvailable` and `Flags.glassAvailable`). It turns `true` in the release that ships Glass, and CI refuses a build with the flag `true` while either client's Glass completeness or boundary test fails.
- **First-paint attributes (web).** One mechanism for both skins, no second cookie (`cinematic/DESIGN.md` §15.10 S6): the server stamps only `data-skin` from `mm-skin`; the Glass settings that change the first paint are stamped before paint by `features/preferences/appearance-boot-source.ts` (the inline `<head>` script the stack keeps) from the remembered active profile's scoped `localStorage` entry `mm.boot.a11y` = `{legible, motion, solid, contrast}` (Glass reads all four; Cinematic reads `legible` and `motion`), rewritten whenever the profile loads or one of the settings changes. It sets `data-motion="reduced"` (also when the OS asks), `data-solid="on"`, `data-legible="on"` and `data-contrast="more"`. With no entry (a new device, cleared storage, or no profile yet) the page paints from the OS media queries alone and applies the profile's values when it arrives; a move already running finishes. Flutter reads the same four values from SharedPreferences `mm.boot.a11y.u{user}p{profile}` before `runApp`.
- **The 18+ gate closing with local copies.** When a profile's gate closes, or a profile with a closed gate becomes active, every holder of mature material on the device is cleared in this order, before the next frame paints (the purge is one function, `purgeMatureLocal()` / `purgeMatureLocal(ref)`, run by the shared data layer and by the Glass shell for the holders only Glass creates):
  1. **Stop what is playing.** If the open series is mature: narration, cruise and the soundscape stop, and the listen accessory leaves. A pending "Recap ready" toast and any in-flight recap request for a mature series are cancelled.
  2. **Pop covered screens.** Every tab stack whose top route shows mature content pops to its root (Flutter branches, the web's per-tab stacks); an open mature reader or series sheet closes without animation.
  3. **Drop Glass's own holders.** Stack-overview snapshots whose route was mature (§7.37) are disposed; `sessionStorage['mm.glass.stack']` entries with `mature: true` are removed; recent searches (web K27, mobile per-profile list) are stored with the gate state they were typed under (`{q, gateOpen}`), and every entry typed while the gate was open is removed, because a query string can itself be mature.
  4. **Clear image memory.** Flutter: `PaintingBinding.instance.imageCache.clear()` and `clearLiveImages()`, plus `cached_network_image` eviction of mature covers and pages; web: every object URL made from a mature image is revoked, and Cache Storage entries tagged `mature=1` are deleted.
  5. **Purge, do not refetch, cached payloads.** Cached `GET /home`, statistics, Wrapped, recap and Circle payloads are deleted outright (a refetch that fails offline would otherwise leave the old copy playing); they are fetched fresh when the network allows, and offline the screens show their offline state.
  6. **Filter downloads on read, never delete them.** Downloads carry a `mature` flag in their local record (set from the series payload at download time); every downloads list, count, meter breakdown, search over downloads and Continue item drops them, and the download queue skips mature items without cancelling them.
  A deep link, bookmark, history row or notification that points at mature content on a gated profile opens the object lens "This isn't available on this profile" with "Back home", with no title or cover. §14.11 lists this as the checklist the accessibility pass verifies.
- **Unavailable content.** A series whose source was removed (`source_not_found`), a series the source no longer returns (`series_not_found`), or a source that cannot be browsed (`source_not_browsable`) opens the object lens with the specific line ("This source was removed from the server." / "The source doesn't have this series any more." / "This source can't be browsed; open its series from search or your library.") plus "Back" and, for followed series, "Remove from library" (with Undo). Downloaded chapters of such a series still open offline.
- **Content mode (Manga | Novels) on the new screens.** Home, Library, Sources, Search, Updates, History, Bookmarks, Downloads, Collections and Statistics lists follow the mode (as today, mobile G5). Statistics' streak, totals and clock count both modes (a note says so). Wrapped counts both. The Circle shows both modes, each item with a `strip-scroll` or `book-open` glyph. Recaps follow the series. For you follows the mode: in Novels mode the Ask uses `POST /library/suggest` limited to novel sources and the worldwide sections are replaced by the note "Worldwide picks cover manga, manhwa and manhua."
- **Status screens on Flutter.** go_router's `errorBuilder` renders the "Nothing here" lens (§8.28); `ErrorWidget.builder` in release builds renders the route-error lens inside the shell; a backend that stops answering mid-session shows the "Offline" capsule and, after 3 failed requests in 10 s, a top inline notice "Can't reach the server. Your downloads still open." with Try again.
- **Server capabilities.** Sections and entry points the server does not offer (the `capabilities` flags on `GET /settings`: `online_sources`, `client_downloads`, `ocr`, `collections`, `bookmarks`, `continue_reading`, `reading_progress`) are hidden everywhere: dock menus, sidebar items, palette actions, Settings rows and the rails that depend on them.
- **Mobile web gesture hygiene.** Posters, pages and orbs set `-webkit-touch-callout: none; user-select: none` so iOS Safari's image callout never fights the long-press lift; the root keeps `overscroll-behavior-y: none` and every custom horizontal drag (rows, rails, the dock) stays at least 24 px from the left screen edge on iOS Safari so the browser's back swipe is never stolen.
- **Tablets (768 to 1023 px, web and large Flutter windows).** Every screen uses its desktop layout inside the tablet frame (the collapsed 76 px sidebar, §8.0.1): grids take as many columns as fit at a 148 px minimum poster width, two-column dashboards (Statistics, Circle) collapse to one column below 900 px, desktop windows (series detail, profile form) fill the content width, and side panels (reader, settings) open as sheets. Screens with their own tablet line (Home, the readers) override this.
- **Focus on navigation.** After a route change, focus moves to the new screen's `h1` (the large title, or the sheet title for sheet routes) with `preventScroll: true`; after a pop, focus returns to the element that pushed. Flutter requests focus on the title's `Semantics(header: true)` node. Focus arriving on a heading never completes its typing or letter reveal (§10.1, §10.2): the heading carries the full text in its accessible name from the first frame, so the reveal is decoration the screen reader never waits for.

#### 8.0.9 Losing the session, losing the profile, switching profile mid-use

**Signed out from elsewhere.** Any request that returns `401 not_authenticated` after the app had a session (a "Sign out everywhere" or a password change on another device, a session revoked in Security, an expired session), or `account_disabled`, runs one flow, once, however many requests fail together:

1. Narration, cruise and the soundscape stop; the download queue pauses with reason "Signed out" (queued items stay for the next sign-in of the same account on this server); in-flight recaps are dropped; any open reader closes without animation.
2. A `glassThick` alert blooms from centre over `dimModal`: title "You were signed out on this device", body by cause: "Your session ended on another device or expired." (401) / "This account was deactivated. Ask the server's owner." (`account_disabled`); one tinted button "Sign in" (for `account_disabled`: "OK"); the `warning` haptic fires once.
3. "Sign in" opens Login with the username already filled in and focus on the password (the cached username, never the password); a remembered profile stays remembered, so a successful sign-in lands back on the last route through the normal hand-off.

Downloads on the device stay (they belong to the account's profile scopes) and reappear after signing in again. The alert and Login are pre-profile surfaces, so they paint in the device mirror's skin.

**Profile gone.** `400 profile_required` or `404 profile_not_found` on any profile-scoped request (the profile was deleted on another device, or the remembered id is stale) shows the toast "That profile is no longer available" (`warning`), stops playback as in step 1, and cross-fades to the picker over 200 ms (no Step into the light, no Droplet). The picker then behaves as on a fresh session.

**Switching profile mid-use** (the dock's long-press switcher, the sidebar's account menu, the picker): before the hand-off plays, narration, cruise and the soundscape stop (no Undo toast: the switch is the undo); the download queue pauses and the new profile's own queue (downloads are profile-scoped) resumes after the hand-off; in-flight recaps are cancelled and their "Recap ready" toast never shows; every tab stack pops to its root and the new profile lands on Home; a gate-closed destination profile runs the purge of §8.0.8 first. A switch into a profile whose skin differs runs the restart inside the hand-off (§8.25.2).

#### 8.0.10 Server error codes: copy and recovery

Every `code` in the server's error envelope (`capabilities.md` §1) has one entry in `frontend/src/skins/glass/copy/errors.ts` and `mobile/lib/skins/glass/copy/errors.dart`, keyed by `code`, so no screen invents its own wording. Codes whose copy lives with their screen are listed with a pointer. Surfaces: **toast** (§7.12), **inline** (the field or form error line, §7.3), **lens** (the object lens, §7.24), **alert** (§7.11), **capsule** (the `warning` status capsule with a countdown).

| Code | Surface | Copy | Recovery | Haptic |
|---|---|---|---|---|
| `invalid_credentials`, `account_disabled` (at login), `weak_password`, `username_taken`, `invalid_username`, `registration_disabled`, `invite_code_required`, `invite_code_invalid`, `bootstrap_window_expired`, `bootstrap_already_claimed` | inline | §8.3, §8.4 | §8.3, §8.4 | `error` + shake |
| `account_disabled` (mid-session), `not_authenticated` (mid-session) | alert | §8.0.9 | §8.0.9 | `warning` |
| `profile_required`, `profile_not_found` | toast, then the picker | "That profile is no longer available" | §8.0.9 | `warning` |
| `profile_limit_reached` | inline on the profile form | "This account already has 5 profiles, the most it can have. Delete one to add another." | "Manage profiles" | `error` |
| `invalid_profile_name` | inline on the Name field | "Use 1 to 30 characters for the name." | Focus the field | `error` + shake |
| `invalid_mood` | inline on the Mood chips | "Pick one of the moods." | The chips stay open | `error` |
| `cannot_manage_self` | inline on the Members row | "You can't deactivate or delete your own account." | none | `error` |
| `forbidden` | lens | "You don't have access to this" / "It's for the server's administrators or its owner." | "Back" | none |
| `not_found` | lens | "This isn't here any more" / "It may have been removed on another device." | "Back" | none |
| `follow_limit_reached` | toast | "You follow 1,000 series, the most a profile can. Remove some to add more." | "Open library" | `error` |
| `series_not_found`, `source_not_found`, `source_not_browsable` | lens | §8.0.8 "Unavailable content" | §8.0.8 | none |
| `invalid_reading_status` | toast | "Couldn't set that reading status. Try again." | the menu reopens | `error` |
| `bookmark_deleted` (409 during a sync) | toast | "That bookmark was removed on another device" | the row leaves; nothing to undo | none |
| `batch_too_large` | toast | "That's too many at once. Select fewer and try again." (the bulk toolbar then splits the batch itself on the next try) | the selection stays | `error` |
| `db_busy` (503 + `Retry-After`) | capsule | "The server is busy. Trying again in {n} s" | automatic retry after `Retry-After`, then the normal error | none |
| `rate_limited` (429 + `Retry-After`) | capsule, or the button countdown on auth forms | "Slow down a little. Trying again in {n} s" (sources: "The source is busy; retrying in {n} s") | automatic retry after `Retry-After` | `warning` once |
| `check_already_running` | toast | "A check is already running" | none | none |
| `narration_unavailable`, `audio_preparing` | inline in the player | §8.16.8 | §8.16.8 | none |
| `audio_convert_failed` | inline in the player | "This chapter's audio couldn't be prepared." | "Try again" (owners: "Render again", §8.16.5) | `error` |
| `suggest_shelf_empty`, `ai_no_matches` | inline in For you | §9.1.2 | §9.1.2 | none |
| an external link that fails to open ("Read on {site}", the SideStore source) | toast | "Couldn't open {site}" | none | `error` |
| any other code, or none (network) | toast | "Something went wrong. Try again." (network: "Couldn't reach the server.") | "Try again" where the action is repeatable | `error` |

### 8.1 Setup (server address; iOS and Android only)

- **Layout (phone):** bare frame on the aurora field. Column max 420: a 72 px `mm-mark` glass lens, 24 px gap, `largeTitle` "Connect your server" (letter reveal), `body` `label2` "Enter the address of your ManhwaManiacs server. You can change it later in Settings.", 32 px gap, the URL field (label "Server address", placeholder `https://manhwamaniacs.example`), helper "https is required.", primary L "Connect" (full width), plain "Use the default address" beneath when a default is compiled in.
- **Hierarchy:** lens → title → field → Connect.
- **Signature moment (the Address drain move, §4.10):** on success the typed address "drains" into the lens: the field's text scales down and travels into the lens centre on `zoom` while the lens swells 1 → 1.2 on `lens` and flashes its specular rim; the lens then becomes the portal to Login (it expands to fill the screen on `zoom`, revealing Login behind it).
- **Transitions:** in from the splash handoff (the splash lens becomes this lens); out through the lens zoom.
- **Gestures:** none beyond the keyboard; drag down dismisses the keyboard.
- **States:** idle; typing; validating (button loading, the lens ring spins); errors with the shake and a field error: "Couldn't reach that address" (no answer), "That address isn't a ManhwaManiacs server" (`/health` answered without the server's name), "Use an https address", "The server's certificate isn't trusted. Check the address or the server's HTTPS setup." (TLS failure); device offline ("You're offline. Connect to a network to reach your server.", Connect disabled, retried automatically when connectivity returns); success.
- **Keys:** Enter connects.
- **Coverage:** mobile S01 1–9, G7.

### 8.2 Splash and first paint

- **Native layer:** a plain `#000000` frame with no mark, shared by both skins (§12.3).
- **Handoff:** the first Flutter frame fades in Glass's neutral mark (the flat MM column in Frost `#F5F7FA`, 96 px tall, over 120 ms), then runs **Droplet** (§12.4): cold start 1,200 ms, warm start (resumed within 4 h) 400 ms. Tapping anywhere skips to the handoff.
- **Session probe:** while `GET /auth/me` resolves (3 s timeout on mobile), the lens holds and a liquid ring rotates around it; when auth resolves, the lens hands off: into the dock (signed in with a profile), into the picker orbs (signed in, no profile this session), or into the Login form's lens (signed out).
- **Boot-time skin mismatch:** when the remembered profile's saved skin differs from the device mirror, the Droplet plays to the lens and the restart into the other skin runs from the lens with no confirm (`stack-decision.md` §2.4 step 4).
- **Web:** the root layout server-renders the neutral mark as inline SVG on black; the Droplet plays once per browser session after hydration, keyed per skin (`sessionStorage['mm.skin.splash.glass']`), so a tab that already played Cinematic's splash still plays the Droplet after a switch into Glass; the outgoing skin also removes its own flag before `location.replace` (§8.25.2 step 2). On warm navigations it never plays.
- **States:** probing, signed in offline (the lens gets an "Offline" capsule and hands off to the app with cached data), probe failed with no cache (hands off to Login's unreachable state).
- **Coverage:** mobile S02 1–4, G2 (`AuthPending`), web L1, RG1.

### 8.3 Login

- **Layout, desktop web:** the aurora field fills the window; a centred `materialRegular` slab 440 wide, radius 32, padding 32: the 56 px `mm-mark` lens, heading, subtitle, the form, the footer. **Mobile web / iOS / Android:** the same column full width with 20 px margins, the lens at top, the slab replaced by plain content on the field; on mobile, a "Server: host" row with a copy icon (tap copies the full URL, toast "Copied https://…") and a plain "Change server" link to Setup.
- **Heading:** "Welcome back" with the **typing reveal** (50 ms per character, §10.2); subtitle `body` `label2` "Sign in to your library."
- **Form:** Username (autofocus, `autocomplete=username`), Password (reveal toggle), "Keep me signed in" switch (default on), error line, primary L "Sign in" (full width, disabled until both fields have text), footer "Need an account? **Create one**" (only when registration is open).
- **Signature moment (the Slab condense and Lens split moves, §4.10):** on success, the slab condenses: its contents fade (`fadeOut`), the slab shrinks into a droplet at the lens position on `zoom`, the droplet falls into the lens with `logo.land`, and the lens splits into the profile orbs of the picker (each orb springs out to its slot on `celebrate`). On success the username is added to `mm.known-accounts` (device storage, usernames only, most recent first, at most 5), which the picker's "Switch account" reads (§8.5).
- **States:** resolving (the lens with its ring, no form); unreachable (lens with cloud-slash, "We couldn't reach the server", `danger` detail, "Try again" secondary, plus "Change server" on mobile); bootstrap (heading "Welcome to ManhwaManiacs", subtitle "This server has no accounts yet. Create the first one; it becomes the administrator.", primary "Create the first account" → Register); normal; pending (fields disabled, button loading); errors with shake: `invalid_credentials` "That username and password don't match.", `account_disabled` "This account is deactivated. Ask the server's owner.", `rate_limited` "Too many attempts. Try again in 42 s." (the button counts down in `mono` and re-enables itself), network "Couldn't reach the server."
- **Transitions:** in from the splash lens; out through the signature to the picker (or straight to Home when a profile is remembered and valid).
- **Keys:** Enter submits; Tab order username → password → reveal → switch → submit → footer.
- **Coverage:** web R1 L1–L9; mobile S03 1–13.

### 8.4 Register

- **Layout:** as Login (bare frame, slab on desktop, back nav button top-left on phone).
- **Variants:** **Closed** ("Registration is closed", "This server isn't accepting new accounts. Ask its owner for access.", secondary "Back to sign in"); **Bootstrap** ("Claim this server", "This first account becomes the administrator.", submit "Create the administrator account" with a shield-check glyph); **Open** ("Join ManhwaManiacs", "Create an account on this server.").
- **Fields:** Username (autofocus), Password (helper "At least 8 characters"), Confirm password (live "Passwords don't match." with `aria-invalid`), Invite code (only when the server requires one outside bootstrap; placeholder "Ask whoever invited you"), Display name (optional, "How your name appears"), Email (optional, `type=email`), "Keep me signed in" switch, error line, primary "Create account", footer "Already have an account? **Sign in**".
- **Signature moment:** the same condense-into-the-lens as Login, landing on the picker's empty state, where the "Create your first profile" orb is already waiting.
- **States:** resolving, unreachable, closed, bootstrap, open, pending, errors (`invite_code_required`, `invite_code_invalid`, `registration_disabled`, `username_taken` "That username is taken.", `invalid_username`, `weak_password`, `rate_limited` with countdown, `bootstrap_window_expired`, `bootstrap_already_claimed`), each with the shake on the first offending field.
- **Keys:** Enter submits.
- **Coverage:** web R2 RG1–RG5 and its 9 elements; mobile S04 1–17.

### 8.5 Profile picker ("Who's reading?")

- **Layout (all platforms):** takeover on the focused profile's mood field. Centred: `largeTitle` "Who's reading?" (letter reveal) and `callout` `label2` "Your library, progress and mood follow the profile you pick."; below, a centred wrap of profile orbs (96 phone, 128 desktop) with names in `headline` under each, 24 px (phone) / 40 px (desktop) apart, plus an **Add profile** orb (dashed 1.5 px `g600` ring, plus glyph) while fewer than 5 exist. Top-right nav buttons "Edit" (manage mode) and, when `mm.known-accounts` holds more than one username (this device has signed in to more than one account, §8.3), "Switch account" (signs out to Login, where the known usernames are offered as chips above the Username field). Desktop: the orbs sit in one row; hover grows an orb to 1.08 and cross-fades the field to its mood (`tintShift`).
- **Idle physics:** orbs drift (§7.26); the focused orb's mood field breathes with the ambient drift.
- **Signature moment (Step into the light):** tap an orb → it inflates to 1.35 on `celebrate`; the other orbs are **repelled** outward (each gets a radial impulse of 900 px/s away from the chosen orb, decays on `dismiss`, fading to 0) like droplets pushed by a larger drop; the title fades; over the next 600 ms the chosen profile's colours **pour into the ambient field** (the three blobs slide to the profile's mood colour at full field opacity and its two avatar-preset colours, §7.26, and every glass rim follows; once Home's feed loads, its spotlight palette takes over with Light follows the story); at 450 ms the chosen orb flies to the dock's You tab (phone) or the sidebar's profile capsule (desktop) on `zoom`, leaving a short meniscus tail, and the app materialises around it (the dock forms from the orb as it lands; `profile.select`). The whole hand-off is 1,100 ms and can be interrupted by tapping another orb before the flight starts (the choice changes, the repelled orbs are pulled back, the field re-pours). If the chosen profile's skin is Cinematic, the restart runs inside this transition (no confirm, no undo), per `stack-decision.md` §2.4.
- **Manage mode:** "Edit" turns the orbs into editable objects: each gains a `glassThin` pencil badge and breathes slowly (scale 1 ↔ 1.02 over 2 s); tap opens the profile form; "Done" leaves. Long-press any orb in normal mode opens its context menu: Edit, Use without animation, Delete (hold-to-confirm alert).
- **Gestures:** tap, long-press, and dragging an orb (it follows the finger and springs home; pure delight, no action).
- **States:** loading (orb-shaped skeletons); empty ("Create your first profile" lens, "Profiles keep progress, follows and mood separate for each reader on this account.", primary "Add profile"); error with no cache ("Profiles are unavailable" + Retry); unreachable with a cached profile (a single orb "Continue as {name}" + Retry); at limit (no Add orb, footnote "Up to 5 profiles").
- **Transitions:** in from Login/Register's lens split, from the You tab's "Switch profile" (the current orb flies from the dock back to the centre and the others fade in around it), from the dock's long-press switcher (skips the picker entirely); out through the signature. What stops and what continues across a switch is §8.0.9.
- **Keys:** arrows move focus between orbs, Enter picks, `e` edits the focused profile, `n` adds, Esc returns to the app when a profile is already active.
- **Coverage:** web R3 P1–P8, A10–A12, A16; mobile S05 1–15, G3.

### 8.6 Profile form and Manage profiles

**Profile form** (`/profiles/new`, `/profiles/:id/edit`): phone: a large sheet over the picker; desktop: a 560 px window blooming from the Add orb or the pencil badge.

- **Content:** a 96 px live orb preview (gradient cross-fades over `colorShift`, glyph morphs on `snappy`), Name field (max 30, "e.g. Late-night reads", autofocus), **Avatar** grid (6 × 2 orbs of 56 px; tapping one launches a copy of it along a short parabolic arc into the preview: gravity 3,000 px/s², 280 ms, landing with `tick` and `selection`), **Mood** choice chips with 12 px colour dots (the droplet slides; the sheet's field retints live), **Mature (18+)** switch with the §7.25 flow, error line, primary "Create profile" / "Save changes", and in edit mode a destructive **hold-to-confirm** "Delete profile" ("This removes {name} and its reading data from this account. It cannot be undone."). Deleting the active profile returns to the picker once the sheet dismisses.
- **States:** loading (edit), not found ("This profile may have been removed."), error, pending, saved (the sheet dismisses and the picker's orb for this profile does a `celebrate` hop), server refusals `profile_limit_reached`, `invalid_profile_name` and `invalid_mood` with the copy of §8.0.10, and **offline**: the fields stay editable (nothing typed is lost), the primary button is disabled with the reason line "Profiles need a connection to save" under it, and it enables itself when connectivity returns (profile writes are not queued in the outbox, because a queued create could collide with the 5-profile limit on another device).
- **Keys:** Enter saves, Esc closes.

**Manage profiles** (`/profiles/manage`, reached from You → Profiles on phone and the sidebar profile menu on desktop):

- **Layout:** large title "Profiles", grouped list: each row = 44 px orb, name `headline`, mood `footnote`, "Active" tag on the current one; trailing buttons "Use" (plain), edit (pencil icon), and the row's ⋯ menu (Edit, Use, Delete, Move up/down). Rows reorder by drag (the profile `sort_order`). Add button in the nav row, disabled at 5 with the footnote "Up to 5 profiles".
- **States:** loading, error, empty (dashed card "No profiles yet"), offline (the cached profile list read-only, with the "Offline" capsule in the nav row; Add, edit, delete and reorder are disabled with the tooltip "Needs a connection"; "Use" still works for cached profiles).
- **Keys:** arrows move between rows, Enter uses the focused profile, `e` edits, `n` adds, `Delete` deletes (opens the confirm), `alt+↑/↓` reorders.
- **Coverage:** web R4 PF1–PF8, PM1–PM8, A13–A15; mobile S06/S07 1–15.

### 8.7 Onboarding (a new profile's first visit, `/welcome?step=1..7`)

Shown once, the first time a profile with no reading history and no follows opens Home. Takeover frame on the aurora field. Every step can be skipped ("Skip" plain button in the nav row); progress is a row of seven droplet dots at the top (the current dot is a stretched capsule that slides on `tab` as pages change). Horizontal swipe or `←`/`→` moves between steps; the tinted "Continue" sits at the bottom (full width on phone, 320 px centred on desktop).

1. **Welcome:** "Hi, {name}." with the **typing reveal** (§10.2), then `body` "Let's set up what this profile likes. It takes a minute." Primary "Start".
2. **Look:** the two skins as mini previews side by side (phone: stacked), each playing its skin's looping 6 s animated WebP of Home (360 × 780, under 900 KB, captured by the Playwright screenshot harness from the seeded demo profile with self-made placeholder covers and no 18+ content; web `<img>`, Flutter `Image.asset`, both play animated WebP natively; under Reduce Motion each card shows its still first frame `skin-{id}-still.png` with a plain "Play preview" button that plays the loop once), Glass selected. Choosing Cinematic shows "The app will restart in Cinematic after the last step." and marks the profile's skin; the restart happens after step 7 (nothing is lost yet, so there is no confirm). Hidden until Glass is available (§8.0.8) when the profile started in Cinematic.
3. **Formats:** four large toggle cards (Manhwa, Manga, Manhua, Web novels; Web novels only when the server enables novels), multi-select, `select` haptic; each card a `surface1` slab with a Light 40 px glyph that turns Duotone `iris400` when chosen.
4. **Genre field (signature):** 24 genre **bubbles** float in a 2-D physics field: circles (radius 36 to 52 by genre popularity: a fixed ranked list of 24 genres in `copy/genres.ts` / `copy/genres.dart`, first place 52 px, last place 36 px, linear between; a new profile has no genre weights of its own, so the ranking is the project's, not the server's) with soft collisions (position-based dynamics, 4 iterations per frame, restitution 0.4), a weak pull toward the field centre (spring `k = 4`), and the gyroscope tilting gravity up to 400 px/s² so the bubbles slosh when the phone tilts. **Weights:** tap once → the bubble inflates to 1.25 × on `celebrate` and turns liked (fill `iris600` at 60 %, label `onTint`; weight 1); tap twice → 1.5 × with a caustic under it (loved; weight 2); a third tap resets it (weight 0); **long-press** (450 ms) → it shrinks to 0.8 ×, dims to 50 % with a struck-through label (not for me; weight −1; `threshold.cross` haptic). Neighbours are pushed away by growth. Drag flings a bubble through the field. Desktop: the same field in a 720 × 480 area with no tilt; gravity instead follows the pointer's offset from the field's centre (`g = 200 px/s² × offset / half-size`, capped at 200 px/s²), and returns to zero when the pointer leaves; mobile web uses the gyroscope only after the motion permission of §8.25.1, otherwise it behaves like desktop without a pointer (no gravity). Keyboard: arrows move focus between bubbles by proximity, Space cycles 0 → 1 → 2 → 0, `x` sets −1. **Semantics:** the field is a `role="group"` labelled "Genres you like"; each bubble is a `role="button"` whose accessible name carries its state ("Fantasy, loved", "Horror, not for me", "Romance, not chosen") and whose hint says "Double-tap to change; actions: Like, Love, Not for me, Clear" (Flutter `Semantics(customSemanticsActions:)`, web the same four items in a context menu), so the physics never has to be operated. Mature genres (Adult, Ecchi, Hentai, Mature, Smut) exist in the field only when this profile's 18+ gate is open.
5. **Art style:** nine unlabelled panel crops in a 3 × 3 grid (each 1:1, radius 14, `surface1`), accessible names in order: full-colour webtoon painting, crisp cel shading, black-and-white screentone, manhua 3D/CG, watercolour, sketchy indie, retro 1990s, chibi comedy, dark realism. Tap to like (a 2 px `iris500` selected ring and a 24 px check orb pop on `tick`). The crops are bundled assets drawn in-house for the demo set (never publisher art), 320 × 320 WebP each, in `brand/onboarding/styles/` (licence: the project's own, listed in About → Licences as "Onboarding art © ManhwaManiacs contributors, CC0"); the brief for each crop is in §12.7.
6. **Seed titles:** "Pick a few you've read or want to read": a poster grid drawn from the choices above by `POST /library/taste/seed` (24 candidates from the connected sources, 18+ filtered by the profile's gate); tap to follow (`POST /library/follow`, `follow.add`); each pick pulls up to three similar titles into the grid next to it (they surface from depth with a 26 ms stagger); a live counter "Your home has 7 titles to start with" in `headline`; a search field ("Search your sources") for titles not shown. "Finish" is enabled at one pick; "Skip" stays available.
7. **Done:** "Your shelf is ready." The progress dots merge into one droplet (the Dots merge move, §4.10) that falls into the dock's Home tab (phone) or the sidebar's Home item (desktop); Home opens with its first rails built from the picks and types its greeting. If step 2 chose Cinematic, the restart into Cinematic runs here instead.

- **Storage (server, follows the profile to every device):** after each step (debounced 800 ms) the client sends `PUT /profiles/{id}/taste {formats: [...], genres: {name: weight}, styles: [...], seeds: [...], onboarding_step: n}` (the endpoint `cinematic/DESIGN.md` §9.1.7 also uses; Glass adds `styles`, `seeds` and `onboarding_step`). AI requests read taste on the server; the client never prefixes prompts itself.
- **Resume:** if the app is closed mid-onboarding, the next Home visit re-enters `/welcome?step={onboarding_step}` with the saved choices.
- **States:** step 6 loading (12 poster skeletons); AI or seed endpoint unavailable (step 6 shows the pinned and popular source catalogues' Popular lists with the AI notice "Picks come from your sources' popular lists while suggestions are unavailable."); offline (steps 1 to 5 work and are saved locally, then sent on reconnect; step 6 shows the offline lens and "Finish" completes without seeds); follow errors (a per-card error on the toggle with a retry); a profile that already has history (onboarding never shows).
- **Keys:** Enter continues, Esc skips the step, `mod+enter` finishes.
- **Coverage:** new flow (no inventory row); fills the new-profile gap noted by the web first-run banner G38.

### 8.8 Home

The landing screen for every profile (`/`). Composed from the shared home feed `GET /home` (§9.1.6: ordered, typed sections with a `state` each, cached 10 min per profile, 18+ gated on serve); when that endpoint fails, the shared `useHomeFeed()` / `homeFeedProvider` composes the same sections from continue-reading, recently-updated, world recommendations and the Circle feed. §9.1 details the AI rails and their states.

- **Layout, phone:**
  - Nav row: profile orb (leading; its 2 px ring shows today's reading against the daily goal, §9.2.2; tap opens You, long-press opens the profile switcher), content-mode capsule, and the **bell** (trailing; count badge; → Updates).
  - **Greeting** (`largeTitle`, typing reveal once per app session): "Good evening, Yash" (by local time: morning 05–12, afternoon 12–17, evening 17–22, night 22–05), with a subline `footnote` `label2`: "3 new chapters · 12-day streak", where the streak part is a `streak` chip (flame glyph) that opens Statistics. **At risk** (after 20:00 local, streak ≥ 2 days, nothing read today): the subline becomes "Read one chapter to keep your 12-day streak" with the at-risk flame (§9.2.2); no red, no push notification.
  - **Hero spotlight:** a floating portrait card (cover 2:3, 62 % of the screen width, radius 26) in front of its own blurred enlargement (the ambient field turned up to 36 %); title `title1` (letter reveal), a meta line ("Ch 143 is new · Manhwa"), a `why` line with the machine sparkle when the pick is AI's, and actions: the tinted primary "Continue Ch 143" (or "Start reading"; the screen's one lit object, casting its caustic onto the card) and a `glassClear` "Details" secondary; below the card, droplet page dots. Up to six spotlights, in order: next up (the most recent continue item with new chapters), an AI "because you read" pick, a letter from a friend ("Aarav thinks you'd like this", bloom chip), the newest update in a followed series, a "Previously on" candidate (a series paused 7 days or more, with "Previously on" as its secondary action), and in December the Wrapped card. The card **tilts** with the gyroscope up to ±6° (`track`), its specular rim follows, and it pages horizontally with projection (one card per flick, `settle`); paging runs **Light follows the story** (§2.1.8): the field, every glass rim and the dock droplet take the new cover's colours over 900 ms. Tapping the card opens detail with the zoom; long-pressing lifts it like a poster, so it can be thrown up to open or dropped on a friend's orb. **Semantics:** the spotlight is a carousel for assistive technology: web `role="region" aria-roledescription="carousel" aria-label="Spotlight"`, each card `role="group" aria-roledescription="slide" aria-label="2 of 6: Solo Leveling"`, with the page change announced politely; Flutter `Semantics(onIncrease:, onDecrease:, value: "2 of 6")` so VoiceOver and TalkBack page it with swipe up/down; the droplet dots are real 44 px buttons ("Show spotlight 3 of 6") on every platform.
  - **Rails** (in `GET /home` section order): Continue reading (continue stacks, §7.7), Updated for you (followed series with new chapters, "N new" badges), Because you read {title} (AI, one rail per seed, up to 3), For you (AI), Almost there (reading, 3 chapters or fewer left), From your Circle (letters received and friends' reads; bloom chips), Your genres (a chip row from genre affinity, each chip opens For you filtered to that genre, `/library/recommendations?genre=`, §9.1.2), New in your pinned sources (for each pinned source a mini rail of its latest), Ready offline (downloaded series), Recently added to your library, and a small "This week" stats card (minutes, chapters, the flame) linking to Statistics. Rails with no items are omitted; AI rails in the unavailable state show their AI notice (§7.38) instead of disappearing.
  - Bottom accessory: Continue (after the hero scrolls away), narration or downloads when active.
- **Layout, desktop:** content column beside the sidebar. The hero becomes a stage 440 px tall: the cover card (240 px wide) at left over the blurred enlargement that fills the stage width, the title (`display`), meta, the `why` line and actions at right, and a strip of the next four spotlight covers bottom-right (click or `←`/`→` to page; hover tilts the card toward the pointer; the stage never auto-rotates). Rails show 7 (1440 px) to 9 (1920 px) posters with glass arrows on hover.
- **Tablet:** the desktop stage at 360 px height; rails show 5 to 6 posters.
- **Hierarchy:** greeting → spotlight → continue → updates → AI rails → Circle → the rest.
- **Signature moment:** the greeting types in while the spotlight card drops into place on `lens` (a droplet landing on the field: it arrives from scale 0.9 and 24 px above, and the field ripples outward once from its centre, the Field ripple move of §4.10); every later page of the spotlight re-lights the whole screen (Light follows the story).
- **Transitions:** in as a tab root (cross-fade + wave) or from the profile hand-off (the app materialises around the landing orb); out by zooms into details and dives into readers; Continue with a series last read 7 days or more ago (recap setting Ask) first blooms the recap offer (§9.1.3).
- **Gestures:** pull to refresh (droplet; refetches `GET /home` with `?refresh=1`), spotlight paging and tilt, throw to open, long-press lift on any poster (context menu with Continue, Details, Add to collection, Mark read, Download next 10, Previously on, Recommend to…, Not interested on AI cards), swipe the continue stack left to reveal its "Previously on" pill.
- **States:** loading (greeting shows immediately; spotlight skeleton card; three rail skeletons); **new profile** (no history and no follows: onboarding runs first; if skipped, the spotlight becomes a "Start here" card, rails show "Popular on your pinned sources" and "For you" from world recommendations, and an empty lens "Nothing followed yet" + "Browse sources" sits below); **AI unavailable** (AI rails show the AI notice with the reason's short line; everything else works); **offline** (greeting + an "Offline" capsule; the spotlight shows the most recent downloaded series; only "Ready offline" and "Continue reading" (downloaded only) rails remain); **error** (per-rail error cards; a full-screen error lens only if every section fails); **caught up** (Updated rail omitted; the spotlight's first card says "You're caught up" and offers "Previously on" or an AI pick); **rate limited** (a `warning` capsule "Sources are busy. Retrying in 12 s").
- **Keys:** `mod+enter` continue; `←`/`→` page the spotlight when it has focus; `↑`/`↓` between rails; Enter opens; `.` item menu; `p` Previously on for the spotlight; `r` refresh; `g u` Updates.
- **Coverage:** replaces the landing role of web R5 (LS1–LS12) and mobile S08 (continue rail; the followed grid moves to Library), G38, G39 (new chapters surface in the spotlight, the bell and the global capsule); new feature §9.1.

### 8.9 Search

- **Layout, phone:** the search orb expands into the bottom field (§7.4). The screen above it:
  - **Idle:** "Recent" rows (clock glyph, the query, a remove ×) up to 4, "Trending" chips (fantasy, romance, action, manhwa, manga, webtoon, horror, sci-fi), a "Browse sources" row, and the **Ask** card: a `surface1` slab "Describe what you want to read" that opens the AI prompt (§9.1.2) when AI is available; `scope=ask` in the URL opens For you with the query in the Ask box.
  - **Results:** the scope segmented control (Library · Sources · Dialogue · Novel text) above the field; a **tier progress** capsule under the nav row: "18 results · searching 8 more sources" with a liquid fill for sources answered / queried; group filter chips (All · With results · Pinned); one section per source: header (28 px logo or the Library glyph in `info`, source name `headline`, count badge) and a horizontal rail of result posters (112 × 168 + 2-line title); failed sources show a note row "This source didn't answer" (`danger` cloud-slash) with a "Retry" plain button (retrying shows 4 poster skeletons in that row); quiet sources collapse into a "Show 12 sources with no matches" disclosure row; a vertical **jump bar** on the trailing edge (phones, when more than 6 source groups exist: one `glassThin` capsule 28 px wide with the groups' initials stacked; drag to jump between groups with a `select` tick per group, like an index; desktop lists the groups in the filter column instead).
  - Dialogue scope: result cards per §8.23.
  - **Novel text scope** (Glass only; Cinematic treats `scope=text` as `all`): searches the text of **downloaded** novel chapters only, on the device, in this profile's downloads scope. **Index:** built when a chapter's text is saved and dropped when its download is removed. Web: IndexedDB database `mm-novel-text` with two stores, `paras` (`{key: "source:series:chapter:n", text}`) and `terms` (`{term, keys[]}`; terms are lower-cased, diacritics folded with `normalize("NFKD")`, split on `\p{L}\p{N}` runs, minimum 2 characters); Flutter: a SQLite **FTS4** virtual table `novel_text(source, series, chapter, para, text)` inside the existing `sqflite` chapter store (FTS4 rather than FTS5 because Android's framework SQLite does not guarantee FTS5; iOS has both). **Query:** every word must match (AND), in any order; web intersects the term lists, Flutter uses `MATCH`. **Ranking:** series the profile is reading first, then more matched words per paragraph, then the most recently read chapter. **Limits:** 50 hits, one row per paragraph, a snippet of ±60 characters around the first match with the terms highlighted as in §8.23, and "Showing the first 50 matches" when capped. **Row:** book plate 36 × 52, title, "Ch 12 · paragraph 118", the snippet in Literata italic 15; opening a hit dives into the novel reader at `?para=` with the paragraph flashed by the Row pulse move (§4.10). **States:** no downloaded novels ("Download a book to search its text here." + "Go to library"), indexing ("Preparing 3 chapters for search…" with a liquid ring, results from what is ready), no matches ("No downloaded chapter says “{q}”"), and never offline (it is all on the device).
- **Layout, desktop:** a 56 px glass search field centred above the results (the palette handles quick jumps; this is the full screen); left filter column 220 px (scopes as a vertical segmented list, group filters, "Hide sources with no matches" switch); results as a grid per source section (6 to 8 posters per row).
- **Hierarchy:** field → scope → tier-1 groups by relevance (Library first, then pinned, then by result count) → tier-2 groups in the order they answer.
- **Signature moment (results surface from depth):** as slow sources answer, their sections **surface from depth** in the order the sources answer (scale 0.94 → 1, brightness 0.4 → 1 on `snappy`), always **appended** after the groups already on screen, which never reorder; the tier capsule's liquid fill sloshes forward on `lens` with each answer, ending in a check when all sources have answered.
- **Transitions:** in from the orb morph (phone) or the palette's "See all results" (desktop); out by zoom into series detail.
- **Gestures:** scroll, jump-bar scrub, long-press lift on results, swipe down on the field to collapse (phone).
- **States:** idle; typing (300 ms debounce); tier-1 loading (3 section skeletons); tier-2 pending; results; partial failures; empty ("No results for “{q}”", "Try another spelling, or search the dialogue instead." + "Search dialogue" when manga mode); no sources in this filter ("No pinned sources answered" / "Pin a source on the Sources tab to keep it here", or "Switch back to All to see every source that answered"); error ("Search failed" + Try again); offline (searches downloaded titles only, with a notice); rate limited ("Sources are busy. Retrying in 12 s", auto-retry countdown).
- **Keys:** `/` focuses the field; `↓` from the field into results; `[`/`]` change scope; `j`/`k` next / previous source group; Enter searches at once; Esc clears, then leaves.
- **Coverage:** web R14 SE1–SE11, A51–A54; mobile S20 1–20; capabilities §18.

### 8.10 Sources

- **Layout, phone:** large title "Sources", content-mode capsule in the nav row; a filter well ("Filter sources") and chips All · Pinned (count) · 18+ (only when the gate is open) that pin under the nav row with a hard edge; section **Pinned** (drag handles visible; drag to reorder, which writes `PUT /sources/pins` in order), section **All sources**; source rows (§7.7).
- **Layout, desktop:** the pinned sources as a horizontal glass-free shelf of 180 × 96 cards (logo 48, name, latest update time) at the top, reorderable by drag; below, "All sources" as a two-column grid of source rows; the filter field and chips in the toolbar row.
- **Signature moment:** **pinning flies**: tapping a row's pin lifts the row (scale 1.03), it travels up into its new slot in Pinned on `zoom` while the list below closes the gap on `snappy`, `selection` when it lands; unpinning sends it back down to its alphabetical place.
- **Gestures:** pull to refresh; drag to reorder pins; swipe a row left for Pin/Unpin; long-press for Pin, Open, Copy source id.
- **States:** loading (10 row skeletons); error ("Couldn't load sources" + Retry); none installed ("No sources installed" / "No novel sources installed"); no match ("No sources match" / "Try a different name"; Pinned filter: "No pinned sources" / "Tap the pin on any source to keep it at the top"); pins failed to load ("Pinning is unavailable until your pins load" inline notice + Retry, pin toggles disabled); pin save failed (toast "Couldn't update your pins" and the row flies back); a pinned source no longer installed ("No longer installed" row at 55 % with an "Unpin" button); **offline** (the cached list, from the web's cached `GET /sources` response and mobile's `manhwamaniacs:source-pins` plus the follow cache, with the "Offline" capsule; rows dim to 70 % and tapping one opens the catalogue's offline lens; pin toggles and reordering are disabled with "Needs a connection"; with no cache at all, the offline lens "Sources need a connection" + "Open downloads"); **rate limited** (the shared `warning` capsule "Sources are busy. Retrying in {n} s" with its countdown, §8.0.10). Pins that the 18+ gate hides are simply absent.
- **Keys:** `/` filter, arrows move between rows, Enter opens, `p` pins the focused source, `alt+↑/↓` reorders pins.
- **Coverage:** web R15 SL1–SL13, A55–A57; mobile S16 1–16; G4 (18+ filter and badge).

### 8.11 Source catalogue

- **Layout, phone:** nav row with back and a trailing glass group (refresh, ⋯); header: 48 px logo + source name `largeTitle` (letter reveal) + a count line ("412 series · Latest") + a **freshness capsule** ("Updated 12 min ago", or `warning` "Saved copy · 2 h" with an explanation popover when the catalogue is stale); the search well ("Search this source"); **browse modes** as in-page tabs with a swipeable pager (Popular, Latest, and whatever the source exposes; hidden while searching); a genre chip ("All genres" / the chosen genre) that blooms into a searchable menu; the grid: 3 columns on phone, posters 2:3 with 2-line titles; infinite scroll.
- **Layout, desktop:** the same with 5 (1024) to 8 (1920) columns; modes as tabs in the toolbar row; the genre menu as a popover with a filter field.
- **Top capsule (all platforms):** after 400 px of scroll a `glassThin` "Top" capsule with an up-arrow materialises bottom-right (above the dock on phones); tapping it scrolls to the top on `page` and dematerialises it.
- **Novel sources:** the grid becomes a book shelf: rows with a 48 × 68 plate, Literata title 17, "by Author · 120 chapters · Ongoing", a 2-line blurb, and genres in `caption1` uppercase.
- **Signature moment (opening a slow source):** the "Opening" lens: the source's logo sits in a 96 px glass lens at the top of the grid area while three covers from the profile's continue list orbit slowly behind it in the ambient field (radius 80 px, one revolution per 9 s, each on its own drift phase); after 3 s a line appears: "This source can take about 10 s"; when data arrives, the lens pops (`lens` shrink to 0 with a small ripple), and the grid enters with a wave from the lens position.
- **Transitions:** in by push from Sources or a genre tag (the tag's text flies into the genre chip, the Tag flight move of §4.10); out by zoom into detail. The "Opening" lens's orbit is the Orbiting covers move (§4.10).
- **Gestures:** pull to refresh (refetch with `refresh=true`), pager swipes between modes, long-press lift on posters, "Top" capsule.
- **States:** opening (signature); loading more (a liquid ring at the grid's end); load-more failed ("Couldn't load more" + Retry, which refetches only that page); end ("End of results"); empty ("No series found" / "No results for “{q}” on this source"); error (lens "Couldn't load this catalogue" + message + Try again); stale (the warning capsule); offline with a cached page (the stale capsule reads "Offline · saved copy from 2 h ago", infinite scroll stops at the cached end with "More needs a connection"); **offline and never loaded** (the offline lens "This catalogue needs a connection" + "Open downloads"); rate limited (the shared `warning` capsule "The source is busy. Retrying in {n} s" with its countdown; loaded posters stay).
- **Keys:** `/` search, `h j k l` and arrows through the grid, `[`/`]` modes, `r` refresh, Home/End.
- **Coverage:** web R16 SB1–SB15, A58–A61, A64; mobile S17 1–14; capabilities §16.2.

### 8.12 Series detail (manga, manhwa, manhua)

One screen for both identities (`/library/:followedId` resolves to the source identity and renders the same screen as `/sources/:s/series/:id`), so a series has one page whether or not it is followed.

- **Presentation:** phone: a **sheet** over the screen it came from, opening at `medium` (52 %) and dragging to `large`; desktop and tablet: a **window** 960 wide (tablet: full content width), radius 32, `materialThick`, over the recessed page (scale 0.97, blur 8, dim 50 %); a deep link without a parent renders the same layout as a full page.
- **Desktop window layout (≥ 1024 px):** the band is 240 px tall across the full window width; below it, **two columns** with 32 px padding and a 32 px gutter: the **left column, 320 px**, is sticky (it stays while the right column scrolls, `position: sticky; top: 24px`) and holds the cover 240 × 360 (radius 14, overlapping the band by 120 px), the title block, the split primary and the secondary buttons stacked full-width (44 px each, 8 px apart), then the facts ("412 chapters · Updated 2 d ago", status, source chip, tags); the **right column** (the remaining ≈ 544 px) scrolls: description, the download card, Previously on, Circle, More like this, then the Chapters section with its pinned header. The nav row sits inside the band (close × leading, trailing glass group). **Tablet** (768–1023) uses the phone's one-column anatomy at full content width with the band at 280 px.
- **Top band:** the cover's blurred enlargement (ambient field at 28 %) fills the top 280 px of the sheet, fading to black; the nav row inside the sheet: close (×) leading at `medium`, back chevron at `large`; trailing glass group: share (copies the series URL), bookmark list for this series (opens `/library/bookmarks?source=&series=`, whose filter chip names the series and clears with its ×), ⋯.
- **Header (medium detent):** cover 112 × 168 (radius 14) at left, overlapping the band; right of it: title `title1` (letter reveal), "by {author} · art by {artist}" `footnote` `label2`, tags (status tag, first four genres as links to the source catalogue with `?genre=`, 18+ badge when mature), and "412 chapters · Updated 2 d ago" `caption1`.
- **Actions:** the **split primary** "Continue · Ch 143" (or "Start reading", or disabled "All caught up") whose chevron menu holds Read from the start, **Read all** (one scroll; only with more than one chapter), Pick a chapter, Download next 10; then a row of glass secondary buttons: **In library / Add to library** (follow toggle; selected state per §7.1), **favourite** star (followed only), **notifications** bell toggle (followed only; `PATCH notify`), **Download** (progress button for the whole series), ⋯ (Reading status: Unread, Reading, Completed, On hold, Plan to read, Dropped; Add to collection; Tags… (the `?sheet=tags` `medium` sheet listing the profile's tags as chips to toggle on this series, plus "New tag" with a name field (max 24 characters, counter from 20) and one of the ten speaker hues as its colour; `GET`/`POST /library/tags`, `POST`/`DELETE /library/series-tags`. **Colour is never the only signal:** every tag chip shows its name, with the colour as a 10 px dot before it and a check glyph when the tag is on. **States:** loading (4 chip skeletons), error ("Couldn't load your tags" + Try again), empty ("No tags yet" + the New tag field focused), offline ("Tags need a connection", chips disabled), toggle failed (the chip springs back with `tick` and the toast "Couldn't update tags"), create failed (inline under the field: "Couldn't create that tag"), a duplicate name (inline "You already have a tag called {name}")); Previously on; Recommend to…; Hide from my Circle (when this profile shares); Check for new chapters (`POST /updates/followed/{id}/check`); Content rating: Automatic, Always mature, Never mature (writes `mature_override`, followed series only, shown only when the profile's gate is open); Open source page in browser).
- **Below (large detent):** description (`body`, 3 lines with "More" that expands on `snappy`); a **download card** when anything is queued or saved ("24 of 412 chapters saved on this device" with a liquid bar, "Downloading now · page 18 of 40", "3 waiting · 1 failed", the pause reason, and on phones the note "Downloads run while the app is open"); **Previously on** entry (§9.1.3); **Circle** row (people light: the orbs of Circle members reading it with `bloom` rings, and their latest reactions, spoiler-guarded, §9.3); **More like this** rail (§9.1.4); **Chapters** section.
- **Chapters section:** a header that pins with a hard edge: "Chapters" `title2`, "24 of 412 downloaded" `footnote` + Download trigger, "Dialogue indexed for 34 chapters" `caption1` (from `GET /ocr/coverage`, manga only, when any), the Newest/Oldest segmented control (persisted per series), "Select" plain button, and a go-to field (`/`) for long lists; then chapter rows (§7.17) with the download control; the in-progress row has its bar; read rows dim; fast-scroll thumb with a chapter-number bubble for lists over 200.
- **Select mode:** row checks spring in; helper assist chips "Next 10", "All unread (n)", "All (n)", "None"; the floating glass toolbar: "{n} selected · {k} already saved", "Download {n}", "Mark read", "Mark unread", "Done"; running: liquid progress "Downloading 3 of 12" + Stop; summary toast ("12 chapters downloaded", "10 of 12 downloaded, 1 with missing pages, 1 failed", "Out of room: only 380 MB free. Remove some downloads and try again." with "Manage downloads").
- **Signature moment:** **the cover lands**: the poster that was tapped or thrown flies into the cover slot on `zoom` carrying its velocity; if it was thrown hard, the sheet opens straight to `large` (the projection of the throw decides the detent). Dragging the sheet from `medium` to `large` shrinks the cover into the nav row's title capsule (the capsule shows a 24 px cover thumbnail + title), a collapsing header driven 1:1 by sheet position. **Following lights the band:** "Add to library" sends the caustic follow ring across the band (§2.4.4) with `follow.add`.
- **Transitions:** in by zoom (posters) or push (links without a poster); out by dragging the sheet down (the cover flies back to its origin if the origin is still on screen, otherwise the sheet slides down on `dismiss`); dive into the reader from a chapter row or Continue.
- **Gestures:** sheet drag and detents; pinch or tap on the cover opens the image viewer; chapter rows: swipe right = mark read/unread, swipe left = download/remove download, long-press = context menu; long-press the Continue button = the split menu.
- **States:** loading (skeleton: cover block, three title bars, two button capsules, 8 chapter rows); offline (from cache and downloads: an "Offline" capsule; chapters list shows only downloaded chapters in full colour and the rest dimmed with "Needs a connection"); error ("Couldn't load this series" / "The source didn't answer." + Try again + Back to source); chapters loading (8 row skeletons); chapters offline ("The chapter list needs a connection"); chapters error (+ Try again); chapters unavailable ("Chapters didn't come through" / "This source lists 412 chapters but returned none just now; that is usually the source, not you." + Try again); no chapters ("No chapters yet" + Back to source); caught up; not in library vs in library; follow pending ("Adding…" on the button); follow feedback toast ("Added Solo Leveling to your library. New chapters will notify you." with Undo; "Removed Solo Leveling from your library." with Undo); rate limited (inline notice).
- **Keys:** `c` Continue, `a` Read all, `f` add/remove from library, `*` favourite, `n` newest/oldest, `/` go to chapter, `x` select, `d` download next 10, Enter on a row opens it, `m` marks it read, `p` Previously on, `shift+t` Tags…, `shift+r` Recommend to…, `shift+s` copy the share link, Esc closes the sheet.
- **Owner-only affordances** (Narrate, cancel a narration job, alias merge and cast edits, §8.16.4, §8.16.5): "owner" means `is_admin` on `GET /auth/me`, the only role the server exposes; the server still answers `forbidden` for anything it refuses, with the §8.0.10 copy.
- **Coverage:** web R7 SD1–SD21, R17 SS1–SS18, §12.2 DP1–DP7, A28–A33, A37, A62–A63, A87–A88; mobile S10 1–21, S18 1–16, M1 (series actions), M2 (chapter selection bar); capabilities §7, §16.3, §20 (coverage), §21 (per-series check).

### 8.13 Book page (novel series)

The same sheet or window as §8.12, dressed as a book's front matter (Apple Books reference). On desktop it uses §8.12's two-column window: the plate (180 × 260), title, byline, facts and actions in the sticky 320 px left column; the blurb, Previously on, Circle, More like this and Contents in the right column.

- **Header:** book plate 144 × 208 (desktop 180 × 260, radius 6, a 1 px paper-edge highlight on the right side and a 2 px spine shadow on the left), title in **Literata** 30/36 `opsz` 36 `wght` 560, byline Literata italic 17 "by {author}", a 56 px rule, facts row `mono` 13 "412 chapters · ≈ 1.2 M words · ≈ 80 h · Ongoing", the estimate note `caption1` "Length estimated from 12 chapters read so far", genre tags (up to 24, links), blurb Literata 17/30, max 62 ch.
- **Actions:** primary "Start reading" / "Continue reading · Ch 12" / "All caught up"; secondary "Add to library" / "In library"; "Download book" with the count of unsaved chapters in `mono`; **Audiobook** button with its live status ("Make audiobook", "Make audiobook · 12 done", "Narrating · 3 in progress, 5 waiting", "Waiting for the narration PC · 5", "Audiobook · 40 narrated") opening the Audiobook sheet (§8.16.5); the note "Narration of new chapters is not available right now" when rendering is off; ⋯ (Previously on, Recommend to…, Hide from my Circle, Add to collection, Voices for this book, Check for new chapters).
- **Contents:** "Contents" Literata 22; the go-to field (`inputmode=decimal`, Enter jumps to the first match, Esc clears; matches list up to 12 with "and 38 more", "Type a chapter number.", "No chapter 900 in this book."); order segmented "First → last" / "Last → first" (default first → last); "Pick chapters" (select mode with helpers "Next 10", "All unread", "Whole book"); a windowed list of 400 chapters around the focus with "Show earlier chapters (212)" and "Show more chapters (400)" buttons; TOC rows: right-aligned Literata tabular ordinal in a 44 column ("·" when none), title Literata 16 (read rows at 45 %), meta `caption1` "3.4k words · 14 min", "42 %" in `iris400` when reading, a headphones badge when narrated ("Audio saved" when saved on the device), download control. The focused chapter (`?chapter=` or go-to) scrolls to centre on `camera` and pulses once (the Row pulse move, §4.10: `iris600` at 14 % fill that fades over 900 ms).
- **Signature moment:** the plate **opens**: on "Start reading", the plate rotates open on its spine (rotateY 0 → −78° on `page`, perspective 900 px) while the novel reader's paper expands from the plate's rectangle to full screen (the dive), so the book literally opens into the reader.
- **States:** as §8.12, with novel copy ("This book needs a connection to load", "Couldn't load this book", "Contents didn't come through", "No chapters yet: this source hasn't published any chapters for this book.").
- **Keys:** as §8.12 plus `g` go to chapter.
- **Coverage:** web R17n NB1–NB19, A74–A75; mobile S18 17–30, N2 (contents sheet), N3 entry.

### 8.14 Manga reader (strip, paged, read-all)

#### 8.14.1 Canvas

- **Background:** `#000000` (reader background option "Graphite" `#0B0B0F` for readers who prefer a softer edge).
- **Brightness and warmth** (the stored `reader_brightness` 0.2 to 1.0 and warmth 0 to 1): a black overlay of alpha `(1 − brightness) × 0.9` (0.72 at 20 %) and a warmth layer `readerWarmth` `#FF8A00` at `warmth × 0.36` alpha in `multiply`, both pointer-transparent, above the pages and below the chrome. Colour modes Normal · Sepia · Grey apply a colour matrix to the page layer only.
- **Stored directions from the current app** (mobile K01): `vertical` opens the strip; `leftToRight` and `rightToLeft` (continuous horizontal strips today) open Single paged in that direction.
- **Strip (default, "continuous"):** a virtualised vertical column, pages seamless (page gap option: 0 or 8 px), full width on phone at 1×, `clamp(480px, 50vw, 900px)` centred on desktop with black gutters. Page boxes are sized from the manifest's width and height before images load (placeholder `#0B0B0F`, no spinner), so nothing jumps. Neighbouring chapters are stitched in (window of current ± 1, loaded when within 4 pages of an edge) with a **chapter seam**.
- **Chapter seam:** 96 px: a hairline, then "CHAPTER 144" in `caption1` +0.2 em (letter reveal as the seam enters the viewport), the chapter title `footnote` `label2`, a hairline; as the seam passes the top of the screen, a `glassThin` chip "Chapter 144" sticks under the nav row for 1.2 s and dematerialises. `chapter.seam` haptic when the seam crosses the reading line.
- **Paged:** single or double (double on tablet landscape and desktop), fit width / height / original, RTL mirrors spreads, 8 px spread gap; page turns per the Page transition setting: **Slide** (finger-tracked, projection decides, `page` spring, the incoming page slides over with an 8 px soft shadow), **Fade** (160 ms), or **None**.
- **Read-all:** the strip streams the whole series in order (chapter 1 or `?from=` first, the rest filling in by batch manifests); seams are slim (48 px) with no card, no pause.
- **Broken page:** inside its box, a 72 px lens drawn as a content twin (§2.4.1: the strip never holds glass) with the image-broken glyph, "This page didn't load", and a "Retry" button in the same content style (remounts only that image).
- **Neighbour still loading:** in continuous mode, when the reader reaches the tail before the next chapter's manifest has arrived, the tail seam shows a 16 px liquid ring spinner and "Chapter 144 is on its way" (`footnote` `label2`); the head seam does the same for the previous chapter. The seam turns into the failed-neighbour card of §8.14.4 if the load fails.

#### 8.14.2 Chrome

All reader chrome is `glassRegular` with `dimLegibility` and the **page tint** (§9.4.4), over soft edges that fade in and out with the chrome.

- **Top-left group:** back (44; it shows the depth indicator and a long-press opens the stack overview or back menu, §7.37) + title capsule "Solo Leveling · Ch 143" (tap → series sheet; long-press → the in-reader chapter list sheet). Read-all adds `mono` "143 of 412".
- **Top-right group:** download control (compact progress button: Download → "18/40 · 45 %" with a cancel × → Saved check → tap for "Remove download?" inline confirm that reverts after 4 s; warn states "Save again" and "Resume 18/40"), bookmark (toggle; saved state Fill `iris400`), settings (sliders glyph).
- **Bottom capsule** (56 tall, inset 16 + safe area, max 520 wide): previous chapter (disabled at 30 % when none), page readout `mono` "18 / 40", cruise (auto-scroll) button (§9.4.1), next chapter (tooltip with the next chapter's label); a 2 px progress hairline inside the capsule's bottom edge.
- **Go to page** (the touch path to a page, web RD22): the page readout is a button ("Page 18 of 40, go to page"). Tapping it blooms (`morph`) a `glassThick` popover above the capsule, 280 wide: a number well (96 wide, `mono` 15, `inputmode="numeric"`, the current page as placeholder, "/ 40" after it; Enter jumps, Esc closes) and a page slider 1 to N with `detent.tick` per page (textured) and the target page's thumbnail (`w=240`) in a 64 × 96 box beside the value while dragging; "Go" (tinted inside the popover) jumps. Jumps of up to 5 pages glide on `page`; longer ones cut with a 120 ms cross-fade. The novel reader uses the same popover for "Go to a percentage" (§8.15.4). It is an anchored picker, so it has no `?sheet=` entry. `g` opens it from the keyboard.
- **Scrub rail:** a 44 px hit strip on the trailing edge between the two groups; visible 3 px track `rgba(255,255,255,0.28)`, fill `iris500`, 12 px thumb. Touch: the track widens to 6 px, a **magnifier lens** (`glassThick` 120 × 164, radius 20) grows out of the thumb on `lens` and follows it on `track`, showing the target page's thumbnail (the image proxy at `w=240`) and `monoLarge` "18"; `scrub.tick` ticks (textured), `scrub.boundary` at the first/last page and at chapter boundaries in read-all (where the rail is segmented by chapter with 2 px gaps); bookmarks show as 4 px droplets on the track. Release: jumps of up to 5 pages glide on `page`; longer jumps cut with a 120 ms cross-fade. Keyboard: the rail is `role="slider"` with `aria-valuetext="Page 18 of 40"`. A one-page chapter (`pageCount == 1`) has no rail. On Android gesture navigation the rail's thumb band is excluded from system back (§8.0.5).
- **Auto-hide and minimise:** 24 px of cumulative downward scroll → the top groups dematerialise (lensing out, blur 8, scale 0.92) and the bottom capsule **morphs** on `minimize` into a 32 px pill showing only "18 / 40"; 56 px of upward scroll, a centre tap, the chapter end, or pointer movement into the top or bottom 72 px (desktop) restores them. Idle hide after 3000 ms only when a tap opened the chrome. The chrome never hides in the first 800 ms after a chapter opens, never while a sheet, menu or scrub is active, and never while a screen reader is on. **Hidden chrome is inert** (web `inert` on the chrome groups; Flutter `ExcludeFocus` + `ExcludeSemantics`), so Tab never lands on an invisible control; any key that is not a reader binding, a Tab press, or pointer movement into the chrome's region restores it first, and the restored chrome takes the focus on its first control.
- **Cinema mode** (`c`, or the settings sheet): the pill hides too, after 3 s idle; a 2 px micro-progress line stays at the very bottom edge unless cinema's "Hide progress" is on.
- **Locked mode** (setting "Lock reader controls"): taps do nothing but scroll; five taps in the centre region within 2 s each unlock (a small lock glyph pulses at each tap; "Reader unlocked" toast, `reader.unlock`). With a screen reader running or a hardware keyboard attached, locked mode also offers an "Unlock controls" custom action on the page (VoiceOver rotor, TalkBack actions, a visually hidden button on the web that appears on focus) and the `u` key; both unlock at once.
- **"Previously" pill:** after 3 or more days away from this series (and less than the series recap threshold, or when the series recap was declined), the "Previously · 20 s" pill of §9.1.3 sits top-centre for 6 s; tap opens the compact recap sheet.

#### 8.14.3 Gestures and input

| Gesture | Behaviour |
|---|---|
| Vertical scroll | Native momentum; `BouncingScrollPhysics`; never scroll-jacked |
| Tap (strip) | Toggles chrome anywhere (default); opt-in "Tap to scroll": top third and left-middle scroll back 75 % of the viewport, bottom third and right-middle forward, centre toggles; the scroll glides on `settle` |
| Tap (paged) | Bands 30 / 40 / 30: left previous, centre chrome, right next; mirrored for RTL until the reader sets their own; each band configurable (Previous · Menu · Next) |
| Tap feedback | A soft radial light (120 px, 10 % white) blooms at the tap point and fades over 300 ms |
| Double tap | Zoom 1× ↔ 2× anchored at the tap point on `camera`; `zoom.snap` |
| Pinch | Strip: width zoom 1× to 3× keeping the focal point fixed (`offset' = (offset + focalY) × z'/z − focalY`), rubber-band beyond; paged: `InteractiveViewer` 1× to 4×; release springs with the scale velocity; `zoom.limit` at the ends |
| Pan (zoomed) | Horizontal pan enabled, edge back swipe disabled |
| Edge back swipe (iOS) | Leading 20 px strip, strip mode at 1× only; the reader slides right over the recessed series page |
| Left-edge vertical drag (12 % band, portrait phones) | Brightness 20 to 100 % (§8.14.1) with a 6 × 140 glass HUD capsule (sun glyph and the value); fades 600 ms after release. The band starts at x ≥ 24 px on iOS (clear of the 20 px back strip) and is excluded from Android's system back over its middle 200 dp only (§8.0.5) |
| Trailing-edge drag | Scrub rail |
| Horizontal swipe (strip, opt-in "Swipe sideways to change chapter") | Direction-locked (abs(dx) > 2 × abs(dy)), stiffer rubber band (`c` = 0.35); the neighbour chapter's title card slides in from the side; projected past 96 px commits with `chapter.next` |
| Pull past the end / top | §8.14.4 |
| Long-press a page (450 ms) | Page menu: Save page image (web: download; phones: share sheet), Bookmark this spot, Show dialogue (OCR text, §8.14.9), Guided view (§9.4.3), React to this chapter (§9.3.2), Recommend to… (§9.3.4), Report broken page (retries with a fresh fetch) |
| Android volume keys | Page up/down (setting, Android only) |
| Mouse wheel | Scroll; Ctrl/⌘ + wheel zooms around the pointer (a zoom chip shows the level for 1200 ms); paged mode: one page per wheel gesture with a 200 ms idle reset. At a chapter end in one-at-a-time mode, wheel delta past the end accumulates (reset after 400 ms without wheel input): 140 px arms the next-chapter card (`chapter.arm`), 210 px commits it (`chapter.next`); the same rule runs at the top for the previous chapter |
| Middle-click (desktop) | Autoscroll anchor: 12 px dead zone, 10 px/s per px of offset, max 4000 px/s |

#### 8.14.4 Chapter boundaries

- **Continuous (default):** neighbours are stitched with seams; there is no card between chapters. The next chapter's first 3 pages preload at 70 % of the current chapter; its manifest loads when within 4 pages of the end. A failed neighbour shows a seam card: "Chapter 144 didn't load" + "Try again" + "Open it on its own", retrying with back-off 2 s → 30 s.
- **One at a time** (setting): past the last page the strip **rubber-bands**; at 48 displayed px (`chapter.arm`) a `glassThick` **next-chapter card** rises from the bottom like a partial sheet: the next chapter's first page as a thumbnail tilted 8° in depth (it follows the gyroscope ±4°), "Chapter 144", "42 pages · about 6 min", and a tinted "Read next"; at 72 displayed px the card locks (`chapter.next`), and releasing **zooms** it to full screen into the next chapter. **Momentum carries through:** if the pull was a fling, the new chapter starts scrolling with the remaining velocity (the ballistic simulation continues on the new content). Pulling down past the first page does the same with the previous chapter from the top.
- **Caught up** (the last published chapter): the end card says "You're caught up" with "The source hasn't published chapter 145 yet." and, if the series is not in the library, "Add to library to hear about new chapters"; below it, the **reactions** row (§9.3.2) and **More like this** (§9.1.4).
- **Missing chapters:** when chapter numbers jump (143 → 145), the seam shows a `warning` row "Chapter 144 is missing from this source".
- **Auto next** (setting, default on): in one-at-a-time mode, reaching the end with the chrome hidden opens the next chapter after 900 ms unless the reader scrolls back.

#### 8.14.5 Reader settings sheet

Phone: sheet at `medium` (page stays visible above, changes apply live), draggable to `large`; desktop: the right side panel (§8.14.11). Sections (each setting shows its scope in `caption1`: "This series" or "All series"). **Scopes are the same on both clients:** Layout, Direction, Fit, Zoom and the cruise speed are **per series** (web's existing `mm.reader-preferences[{source}:{series}]`, K35–K39; Flutter's new per-series map, §15.5, seeded from the device values K01–K02 on first open); the soundscape is per series only when "Remember for this series" is on (§9.4.2); everything else is **per profile, all series** (a series with no stored value uses the profile default from Settings → Reader defaults). Migration of the stored values is §8.25.3.

| Section | Controls |
|---|---|
| Layout | Segmented Strip · Single · Double (hidden in read-all); Direction segmented Left to right · Right to left; Fit segmented Width · Height · Original (Height and Original disabled in strip with the reason "Strip pages always fit the width"); Zoom stepper 50–300 % with a reset; Chapters segmented Continuous · One at a time; Page gap switch (strip) |
| Motion | Page transition segmented Slide · Fade · None (paged); Auto next switch; Swipe sideways to change chapter switch |
| Taps | A phone silhouette diagram with three bands; tap a band to cycle Previous · Menu · Next; "Tap to scroll" switch (strip); "Reset to automatic" plain button; a first-run overlay of the zones (three glass panes labelled Back · Menu · Next) shows for 1.5 s and fades over 1000 ms whenever the layout changes |
| Light | Brightness and Warmth as two Control-Centre fill sliders side by side (brightness 20 to 100 %, warmth 0 to 100 % as a `readerWarmth` `#FF8A00` overlay up to 36 % alpha); Colour segmented Normal · Sepia · Grey; Background segmented Black · Graphite (a stored "Dark" preference maps to Graphite, "AMOLED" and "Paper" to Black) |
| Ambient | Page-tinted chrome switch; Soundscape row (→ §9.4.2); Guided view row (→ §9.4.3); Cruise speed default |
| Screen | Cinema mode switch; Keep screen awake switch (phones); Refresh rate chips Auto · 30 · 60 · 90 · 120 (Android only); Volume keys turn pages switch (Android only); Lock reader controls switch; Fullscreen button (web) |
| Help | Keyboard shortcuts (web), Reset reader settings (hold-to-confirm) |

#### 8.14.6 States

- **Loading chapter:** three page-shaped skeletons (2:3, max 420 wide) with the sheen, and a `glassThin` capsule "Loading chapter 143"; after 3 s it adds "This source can be slow".
- **Error:** the object lens (`danger`) "Couldn't open this chapter" + the server message + "Try again" + "Go to series".
- **No pages:** lens "This chapter has no pages" + "Go to series".
- **Offline:** a downloaded chapter opens from the device with an "Offline" capsule in the top group; neighbours that are not downloaded show "Chapter 144 needs a connection" as the end card, with "Download next 10 when online" as a plain action that queues them.
- **Stale anchor:** toast "This chapter changed. Opened at page 17 instead of 19."
- **Rate limited:** a `warning` capsule "The source is rate-limiting; pages will keep loading" while prefetch paces itself.
- **Bookmark notices:** toast "Saved this spot · Add note" (`bookmark.add`; "Add note" opens a one-line note sheet that saves through the bookmark upsert), "Couldn't save that spot" (error).
- **Further ahead elsewhere:** when a progress save returns `advanced: false` (another device is further on), a toast "You're further ahead on another device: Ch 146, p. 12" with "Jump there".

#### 8.14.7 Keys (web and hardware keyboards)

`→`/`d` and `←`/`a` page by direction · `j`/`k` next/previous page · Space / Shift+Space one screen · Home/End first/last page · `h`/`l` previous/next chapter · Ctrl+Shift+←/→ chapter aliases · `g` go to page (the popover of §8.14.2; the global `g` chords are off inside both readers) · `u` unlock locked controls · `f` fullscreen · `c` cinema · `m` show/hide chrome · `p` cruise play/pause · `<` / `>` cruise slower/faster · `b` bookmark · `t` chapter list · `,` reader settings · `s` series page · `=`/`+`/`-`/`0` zoom · `w` strip, `v` single, `r` right-to-left paged · `o` show dialogue · `?` shortcuts · `shift+p` guided view · `shift+s` soundscape · `shift+c` Circle panel (desktop) · `n` / `shift+n` next / previous dialogue match · `mod+\` back menu · Esc closes the topmost overlay, then leaves fullscreen, then cinema, then the reader.

#### 8.14.8 Chapter list (inside the reader)

A sheet (`large` on phone; left side panel on desktop) listing the series' chapters with the current one centred and marked by a 2 px `iris500` bar, download marks, a go-to field at the top, and the Newest/Oldest control; tapping a chapter dives into it (the reader cross-fades pages; no route animation because the route stays the reader). In read-all, the list is the same, the current chapter is the one under the reading line, and tapping a row scrolls the strip to that chapter's seam on `camera` instead of opening a new route.

- **Long lists:** the list is windowed to 400 rows around the current chapter, with "Show earlier chapters (212)" and "Show more chapters (400)" rows at the ends (as the book page does), and the fast-scroll thumb with a chapter-number bubble (§7.32) above 200 rows.
- **States** (the §8.12 chapter-section states, in the reader's palette): loading (8 row skeletons under the live header), error ("Couldn't load the chapter list" + Try again), unavailable ("Chapters didn't come through" + Try again), **offline** (downloaded chapters at full strength; every other row at 40 % with the reason "Needs a connection" and not activatable; the header reads "Offline · 24 downloaded"), rate limited (the shared `warning` capsule with its countdown).

#### 8.14.9 Dialogue overlay and the hit lens

From the page menu or `o`: the page dims to 50 % and every recognised speech region (`GET /ocr/chapter` boxes) appears as a box (radius 6) holding its text in `callout` `label1`. **One overlay, not per-box glass:** the boxes are drawn in a single overlay layer above the strip (web: one absolutely positioned layer over the reader viewport; Flutter: one `CustomPaint` in an `Overlay` entry), positioned from the engine's page coordinates (`pageToViewport(page, x, y)`, §15.4) and re-laid out on scroll; each box is a content-twin fill (`rgba(19,19,23,0.82)`, 0.5 px `rgba(255,255,255,0.22)` rim, no backdrop read), so 20 boxes cost nothing. Tapping a box copies its text (toast "Copied"). Pages without OCR show "No dialogue has been extracted for this chapter" and, on phones with the chapter downloaded, "Extract text" (runs on-device OCR with per-page progress in the capsule). The OCR text also becomes each page's accessible description when it exists (§14.5).

**The hit lens (match navigation).** When the reader was opened from a dialogue search result (`?q=` carried from §8.23), the reader fetches the chapter's OCR pages, opens at the first page whose text contains the query, and every matched box on that page is outlined 2 px `iris400`. A **T1 hit lens** (`glassFilm`, radius 6, a 2 px specular rim) sits over the current match and magnifies the matched line 1.12 × inside the lens (the engine's `pageLayerTransform` scales the page layer around the box centre, clipped to the lens rect, §15.4), refracting the bubble's edge. The lens is the one glass surface of the overlay layer above the strip, never an element inside it. A `glassRegular` capsule at the bottom reads "Match 1 of 3" with previous and next buttons; `n` / `shift+n`, the buttons or a swipe on the capsule step between matches. Each step slides the lens from bubble to bubble on `camera` (crossing pages continuously, the strip gliding on `camera` when the next match is off screen) and re-magnifies on `lens`; `ocr.hit` haptic. When no page matches (the text changed), the reader opens at page 1 with the toast "Opened at the chapter start: the match moved." Esc or the capsule's × removes the lens and outlines. Reduce Motion: the lens appears at the new bubble with a 120 ms fade.

#### 8.14.10 Reader landing (`/reader`)

A bare page: the object lens with `strip-scroll`, "Pick something to read", "Open a series from your library or a source to start reading.", primary "Go to library".

#### 8.14.11 Platform deltas

- **Desktop web (≥ 1024 px):** the strip is centred at `clamp(480px, 50vw, 900px)`. Two **side panels**, content-layer surfaces (`materialThick`, radius 26, inset 12, never Liquid Glass):
  - **Left panel** (300 wide, `t`): the chapter list with a 48 × 72 **first-page thumbnail** per row (the image proxy at `w=96`), chapter number in `mono`, title, date, the download control, the current chapter marked by a 2 px `iris500` bar and scrolled to centre; "Read all" and the Newest/Oldest control at the top, a go-to field (`/`).
  - **Right panel** (360 wide): tabs **Settings · Dialogue · Circle** (`,`, `o` and `shift+c` open them): the reader settings of §8.14.5 inline in a scrolling column (changes apply live), the dialogue overlay's text list for the current page, and this chapter's reactions and friends' orbs (§9.3.2).
  - Opening or closing a panel **re-centres the strip on a spring**: the strip's centre travels to the middle of the remaining width on `sheet` while the panel slides in from its edge on `sheet`; panels push the strip, never cover it. Both panels hide with the chrome in cinema mode and return with it.
  - **Page-lit gutters** (whenever both side panels are closed): the gutters on each side of the strip are `g25` `#060608` wells in which the current page's light glows as two soft pools: the page sample's `top` colour in the top half and its `bottom` colour in the bottom half of each gutter, at 10 % opacity, blurred 120 px, cross-fading over `tintShift` as pages change, never touching the art. Page-tinted chrome off or Reduce Transparency: plain `#000000` gutters.
  - The bottom capsule floats at the bottom of the strip column. Hovering the scrub rail shows the magnifier at the pointer.
- **Tablet web and landscape tablets:** Double page by default in paged mode; the panels open as sheets (the chapter list at `large`, settings at `medium`) from the title capsule and the settings button, because tablets have no panel keys. (A Flutter tablet in landscape at 1024 px or wider gets the desktop panels, by the frame rule of §8.0.1.)
- **Mobile web:** as phone; pinch through `@use-gesture/react` 10.3.1 `usePinch` (`touch-action: pan-y` on the strip); no haptics on iOS Safari; the chapter list is the `?sheet=chapters` sheet.
- **iOS:** edge swipe back (20 px strip, strip mode at 1× only); `wakelock_plus` keeps the screen on; 120 Hz.
- **Android:** predictive back scales the reader to 90 % as a glass card; volume keys page (setting); the refresh-rate pin resets on exit; `immersiveSticky`.
- **Landscape phone:** the chrome collapses to two corner capsules (back + title top-left, settings + page top-right) and a slim bottom scrub rail; the brightness band is disabled (edge swipes belong to the system).
- **Coverage:** web R19, R20 RD1–RD42, A65–A73, A89; mobile S15/S19 1–41, §6a; capabilities §13, §25.

### 8.15 Novel reader

#### 8.15.1 Paper

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

#### 8.15.2 Layout

- **Column:** centred, width = measure (48 to 88 ch, default 68), side margins at least 20 px on phone; desktop centres the column in the content area with two optional side panels.
- **Desktop panels** (≥ 1024 px; content-layer `materialThick` in the paper's colour mixed 70/30 with `#131317`, radius 26, inset 12, never Liquid Glass, as the manga reader's): **left panel, 300 wide, Contents** (`t`): the contents list of §8.15.6 with the current chapter centred; **right panel, 360 wide**, with tabs **Aa · Voices · Listen** (`,` and `v` open the first two; the Listen tab opens from the listen button or when narration starts, and `p` keeps meaning play/pause): the Type and page settings of §8.15.5 inline, the cast of §8.16.4, and the full player of §8.16.2 laid out as a column (artwork 200 px, speaking orb, scrubber, transport, tiles, sentence list). Opening a panel re-centres the column on `sheet`, as in §8.14.11; panels hide with the chrome and never cover the text. Tablets open the same content as sheets.
- **Chapter header:** "CHAPTER 12" `caption1` +0.22 em in muted, title Literata at 1.55 × body `wght` 560, a 56 px rule, and "3.4k words · 14 min" in muted `mono` 12; when narration exists, a `glassThin` capsule "Listen · 14 min" (with "· saved" when the audio is on the device) sits under the rule and starts listen mode; when the audio cannot follow this text, a quiet line "Audio plays without follow-along for this chapter".
- **Body:** paragraphs per §3.4; first paragraph drop cap (3.1 em, 3 lines) when at least 80 characters; indents 1.3 em after the first; scene breaks centred "✦ ✦ ✦" in muted with 0.5 em tracking and 1.6 em vertical space.
- **Speaker tints:** attributed dialogue runs get their speaker's band (§2.1.5), only when the attribution's text fingerprint matches the text on screen.
- **End matter:** a 96 px rule, "END OF CHAPTER 12", the length line, a **Next** card (`surface1` on the paper, radius 20: "NEXT" `caption1`, "Chapter 13 · The Tower" Literata 20, chevron) or "You've reached the last chapter this source has published", then plain links "Previous chapter" and "Back to the book".
- **Seamless next:** pulling past the end rubber-bands; at 72 displayed px the Next card locks (`chapter.next`) and releasing slides the next chapter up in place on `page` (the URL is replaced, the old chapter marked complete); `l` and the Next card do the same. On desktop, wheel delta past the end accumulates like the manga reader's (140 px arms, 210 px commits, reset after 400 ms without wheel input, §8.14.3). With Auto next on, reaching the end opens the next chapter after 900 ms unless narration is playing or the reader scrolls back.
- **Further ahead elsewhere:** the same "Jump there" toast as the manga reader.

#### 8.15.3 Chrome

Tap the text column (outside a link or a tinted run) to toggle; chrome fades and blurs in and out over `materialize` (a novel reader's chrome is calmer than the manga reader's; no minimise pill). Hidden chrome is inert, as in §8.14.2.

**Touching the text.**
- **Long-press** (450 ms) on a word starts native text selection (the platform's handles and magnifier; web `user-select: text` on the column only) and blooms a `glassThick` menu above the selection with: **Copy**, **Bookmark this paragraph** (the paragraph under the press; `bookmark.add`), **Play from here** (when narration exists: starts listen mode at the first sentence of that paragraph), **React to this chapter** (§9.3.2), **Recommend to…** (§9.3.4). Dragging the handles keeps the menu attached; tapping outside clears the selection. `press.lift` fires at 150 ms, `longpress.open` at 450 ms.
- **Tap a speaker-tinted run:** a `glassThin` chip "Mira · voiced by Ada" (or "Mira" when no voice is assigned) materialises 8 px above the run for 2 s and dematerialises; it does not toggle the chrome. The chip's text is also the run's accessible hint.
- **Double-tap** does nothing in the novel reader (text size is a pinch or the Aa sheet), so single taps are never delayed.
- **Keyboard:** `b` bookmarks the paragraph at the reading line; Shift + arrows select text as usual on the web; the menu opens with `shift+F10` on a selection.

- **Top-left:** back (to the book) + title capsule "Tower of God · Ch 12" (tap → Contents sheet, `t`).
- **Top-right glass group:** bookmark, **listen** (headphones; present only when audio exists or can be made), voices (the cast sheet), **Aa** (type and page sheet).
- **Bottom capsule:** previous chapter, "42 % · 6 min left" (`mono`; minutes from the profile's rolling reading pace, silent until two minutes of samples exist; tap opens Go to a percentage, §8.15.4), the cruise button (scroll mode only, §9.4.1), next chapter; a `waveform` glyph joins the top-right group while a soundscape plays (tap opens the soundscape sheet).
- **Progress hairline:** 2 px at the very top of the screen in muted ink, always visible.
- **Offline indicator:** "Saved copy" capsule in the top-left group when reading a downloaded copy.
- **"Previously" pill:** the chapter-recap pill of §9.1.3, top-centre for 6 s after 3 or more days away.
- **Back:** the top-left back button shows the depth indicator; a long-press opens the stack overview or back menu (§7.37).

#### 8.15.4 Reading modes and page turns

- **Scroll** (default): one scrolling column with native momentum. Cruise (§9.4.1) works here too: 1.0× is the profile's measured reading pace in words per minute (default 250 wpm until 2 minutes of samples exist), converted to px/s from the column's line height and words per line.
- **Paged:** CSS multi-column pagination on web (`column-width` = viewport, `column-gap` 0, the foliate-js approach) and a `PageView` over pre-laid-out `TextPainter` pages on Flutter; tap bands 25 / 50 / 25 (plus "Both margins go forward" and a one-hand preset: left 20 % back, top 12 % menu, the rest forward). Page turn options:
  - **Slide** (default): the page follows the finger 1:1; the turning page carries an 8 px soft shadow on its moving edge that grows with progress; release projects (past 50 % of the width → turn) and settles on `page` with the release velocity; `page.turn` on commit.
  - **Lift** (Glass's own): the page lifts around its spine like a pane of glass: `rotateY` 0 → −100° with `perspective: 1600px`, a specular band (a 40 px `rgba(255,255,255,0.18)` gradient) crossing the turning page as it rotates, and the page beneath un-dimming from 0.85 to 1 brightness; the turn follows the finger (progress = drag distance / page width, including release velocity), releases on `page`, and is pure transforms on both clients: CSS 3D (`transform-style: preserve-3d; backface-visibility: hidden`) on the web, `Transform` with `Matrix4.identity()..setEntry(3, 2, 1 / 1600)..rotateY(angle)` on Flutter. No bitmap capture, no shader. The back of the lifted page shows the paper colour at 92 %.
  - **Fade:** 160 ms cross-fade.
  - Reduce Motion: Fade regardless of the choice.
- **Pinch** changes the text size one step per ×1.15 of pinch scale, `detent.tick` per step, and reflows once on release (the text is never visually scaled).
- **Line guide** (option): frosted bands (blur 6, 55 % of the paper colour) above and below the current line band (2 lines tall); drag the band or tap above or below it to move it.
- **Go to a percentage:** the progress readout in the bottom capsule is a button; it blooms the go-to popover of §8.14.2 with a slider 0 to 100 % (`detent.tick` every 5 %) and a number field (`inputmode="decimal"`, "%" after it), Enter jumps (`g` opens it from the keyboard). In paged mode the slider steps by page and the field takes a page number.
- **Narration in paged mode:** while narrating, the reader turns the page with the chosen transition (Slide, Lift or Fade; Fade under Reduce Motion) the moment the active sentence's first line lies past the current page's last line, so the spoken sentence is always on screen; a manual turn decouples as in scroll mode ("Back to the voice"). Paragraph bookmarks in paged mode anchor to the first paragraph that starts on the page (its `para` and `at = 0`); the progress bucket is `round(pageIndex / pageCount × 100)`, clamped 1 to 100, which both clients compute the same way. Flutter's paged mode is new engine work (§15.4, novel pagination).

#### 8.15.5 Type and page sheet (Aa)

`medium` sheet (≤ 50 % of the height, so the page updates live above it); desktop right panel.

- Face tiles "Literata", "Sans" and "Atkinson" (Legible), each set in its own face (selected: `glassThin` + ring).
- Steppers with detents: Size (15–30), Line height (1.40–2.10), Measure (48–88 ch), Paragraph spacing (0–1.2 em), Character spacing (−0.02 to +0.10 em); each step ticks and the page reflows live.
- Switches: Justify and hyphenate, Bold text, Line guide.
- Mode segmented Scroll · Paged; page turn segmented Slide · Lift · Fade (paged only).
- **Ambient:** Soundscape row (→ §9.4.2), cruise default speed (scroll mode), Page-tinted chrome switch.
- **Papers** as orbs (44 px circles in the paper colour with "Aa" in its ink and a specular highlight); selecting one ripples the new paper out from the orb across the whole page (a circular clip reveal on `page`, the only place a colour change is sprung, because the paper is an object being laid down).
- "Reset" plain button (per book typography back to defaults).
- Scope captions: typography "This book", paper "All books".

#### 8.15.6 Contents sheet

`large` sheet in the paper colours: "Contents" Literata 22, the go-to field (autofocus when opened from a search affordance), the list pre-scrolled to the current chapter (current row ink at 7 % fill, `wght` 600), windowed as on the book page; loading spinner; offline "The contents need a connection to load" (downloaded chapters stay listed).

#### 8.15.7 States

Loading (paper-coloured skeleton lines at varied widths with the sheen tinted to the ink at 5 %); offline (downloaded copy opens; otherwise the offline lens in the paper colours); error ("Couldn't load this chapter" + Back to the book); empty ("This chapter came through empty. The source answered with no text; the page may have been pulled or is still being published."); stale bookmark (toast "The text here changed. Opened at the nearest paragraph."); end of book; end of the downloaded copy (offline with the next chapter not downloaded: "End of the downloaded copy" + "Download next 10 when online"); bookmark saved/failed toasts in the paper palette; **rate limited** (`GET /novels/chapter` shares the 60/min sources bucket: the `warning` capsule "The source is busy; the next chapter will load in {n} s" with its countdown, top-centre in the paper palette, while the current chapter stays readable).

#### 8.15.8 Keys

`h`/`l` chapters · `j`/`k` or Space / Shift+Space page or screen · `=`/`+`/`-`/`0` text size · `,` type sheet (Aa) · `t` contents (the same letters as the manga reader's settings and chapter list; `c` does nothing here, because cinema is manga-only) · `b` bookmark paragraph · `p` play/pause narration · `[`/`]` previous/next sentence (narrating) · `v` voices · `a` cruise play/pause (scroll mode) · `<`/`>` narration speed while narrating, else cruise speed · `g` go to a percentage · `shift+s` soundscape · `?` shortcuts · Esc closes the sheet, then returns to the book.

- **Coverage:** web R21 NR1–NR19, NT1–NT7, A76–A81; mobile S26 1–23, N1, N2; capabilities §19.1–19.2.

### 8.16 Listen mode (narration with the 31 named voices)

#### 8.16.1 Mini player (bottom accessory)

In the novel reader the listen row sits 8 px above the bottom capsule; everywhere else it is the app's bottom accessory (§7.15). Content: the narrating voice's orb 32 (monogram in the voice's hue), "Ch 12 · Aurora" (`subhead`), a play/pause glass button 44, and a 2 px progress line along its bottom edge (buffered segment at 35 %). It lingers 5000 ms after the reader's chrome hides unless the user pins it (long-press → Pin). Swipe horizontally → previous/next chapter (projection past 30 % of its width, `chapter.next`); tap → the full player; swipe down → stop narration (Undo toast). **Desktop:** outside the reader, narration lives in the desktop accessory at the foot of the sidebar (§7.16); inside the novel reader, in the right panel's Listen tab (§8.15.2).

#### 8.16.2 Full player

A sheet from the mini player (the capsule grows into the sheet on `morph`), detents `medium` (transport) and `large` (transport + sentence list); on desktop outside the reader, a 560 px window (T5 `glassMonolith`) blooming from the desktop accessory with the same content in one column and the sentence list below the tiles, max height 88 vh:

- **Artwork:** the book plate on a glass card (radius 20) with parallax: the gyroscope tilts the art ±6 px against the card.
- **Titles:** chapter title `title2`, book title `footnote` `label2`, "Narrated by Aurora · Kade voices 3 characters" `caption1`.
- **The speaking orb:** under the artwork, a 72 px voice orb (a T2 glass sphere) in the narrator's hue, pulsing with the audio level at 30 fps; when a character speaks, that speaker's hue (§2.1.5) flows into the orb over 300 ms (a timed colour cross-fade, never sprung) and returns to the narrator's hue after the line; a `glassThin` chip under it names who is speaking, "Narrator · Aurora" or "Mira · voiced by Ada" (`caption1` 600).
- **Scrubber:** a 6 px track with the chapter's sentence boundaries as faint 1 px ticks; the thumb shows the time bubble while dragged; "5:12" and "−18:40" in `mono` at each end.
- **Transport:** back 15 s, previous sentence, **play/pause** (72 px, `glassTinted`, the screen's one tinted object), next sentence, forward 15 s.
- **Tiles** (three 72 px glass tiles): **Speed** ("1.25×"; opens the speed dial), **Voices** (the narrator's orb + "Cast of 6"; opens the cast sheet), **Sleep** ("Off" or the live countdown "12:40").
- **Save audio** (phones, in the player's ⋯ and as a trailing icon on the mini player): "Save audio to this device" → a liquid ring "Saving audio…" → "Audio saved" (tap for "Remove saved audio?" Keep / Remove) → failed "Couldn't save the audio · tap to retry" → unplayable "The saved audio can't play here · tap to save again".
- **Sentence list** (at `large`): lyrics-style, `title3` Literata, active sentence at 100 % inside a **lozenge** (radius 12, drawn as the content twin of `glassThin` because it lives in a scrolling list, §2.4.1) that **morphs** from sentence to sentence (its bounds animate on `snappy`, stretching across line breaks like a droplet sliding down the text), others at 40 %; speaker tints as bands; tap a sentence to play from it. A manual scroll decouples: the list stops following and a "Back to the voice" `glassThin` capsule appears; it re-couples automatically after 4000 ms idle (in this list only).
- **Chapter boundary:** at the end, a post-play card "Next chapter in 5" with a draining ring (5 s), "Play now" (tinted) and "Cancel"; the setting "Continue to the next chapter" (default on) skips the card when off by stopping.
- **System media controls:** the lock screen, notification and headset controls through `audio_service` 0.18.19 on phones (title, book, cover artwork, play, pause, seek ±15 s, previous and next chapter), and `navigator.mediaSession` on mobile and desktop web with the same metadata and actions.

#### 8.16.3 Speed dial

Tap the Speed tile: a vertical glass capsule 64 × 240 rises out of the tile on `morph`. Drag up/down anywhere on it: 0.5× to 3.0× in 0.05 steps (6 px per step), labelled marks at 0.5, 1, 1.5, 2, 2.5, 3; `detent.tick` ticks every 0.25×; a **magnet at 1.0×** (values within ±0.08 are pulled to 1.0 with a `detent.magnet` click); past the ends it rubber-bands 12 px. The value previews live while dragging and commits on release; touch-and-hold (600 ms without moving) resets to 1.0×. Under the value, the words-per-minute equivalent in `caption1` ("≈ 190 wpm"). Preset chips beneath: 0.8 · 1 · 1.25 · 1.5 · 2. Pitch is preserved (`HTMLMediaElement.preservesPitch`; `just_audio.setSpeed`). **Semantics:** the dial is a vertical slider: web `role="slider" aria-orientation="vertical" aria-valuemin="0.5" aria-valuemax="3" aria-valuenow="1.25" aria-valuetext="1.25 times, about 190 words a minute"`, arrows step 0.05, Page Up/Down 0.25, Home/End the ends; Flutter `Semantics(slider: true, value: "1.25 times", onIncrease:, onDecrease:)` stepping 0.05.

#### 8.16.4 Voices: the orbit and the cast

- **Voice orbit (picker):** the 31 voices as cards on a horizontal carousel with depth: the centred card at 1.0 scale, neighbours at 0.86 and 60 % opacity, receding along a gentle arc (each card's `rotateY` = 18° × its offset from centre, capped at 2 cards). Cards (160 × 220, `surface1` slab radius 26): a 72 px orb in the voice's hue with its initial, name `title3`, "Female · warm" `footnote`, a **pitch scale** (a 1-D track "deeper ↔ brighter" with a dot at the voice's `pitch_hz` position), an expressiveness meter (5 dots), "In use for Kade" tag when assigned, and the licence credit in `caption2`. Flick with momentum; the orbit snaps card by card with projection (`settle`); `voice.center` tick at each settle. **The centred voice auto-plays its introduction after 400 ms of rest** (`GET /novels/voices/sample`, m4a on iOS and Safari, ogg elsewhere) with its orb pulsing to the audio level; moving again stops it. Auto-play runs only when **no screen reader is on** (VoiceOver, TalkBack; on the web it is off whenever the orbit was reached by keyboard) and the orbit's ⋯ switch **"Auto-play previews"** is on (default on, per profile); otherwise each card has a play button and plays only when asked. The playing card always shows a visible stop button (a 44 px `pause` icon button on the card), and a card whose clip is longer than 3 s shows its duration ("0:07") under the name, per WCAG 1.4.2. A preview never plays over narration: narration pauses for it and resumes when it ends. A "Use this voice" tinted button under the orbit; a grid toggle switches to a searchable grid (2 columns phone, 4 desktop) with filter chips All · Female · Male · In use.
- **Cast sheet** (`large`): "Voices in this chapter", status copy ("Looking up who speaks here…", "Nobody has been identified in this chapter, so the narrator reads it all.", "Narrated by Kade: Kade's own lines use the narrator's voice because they are the same person."); the **Narrator** row pinned at top (orb, voice name or "Default voice", chevron); one row per character: speaker swatch (§2.1.5; dashed when unhued), name, assigned voice or "Automatic", share of lines ("31 %"), a lock glyph when set by hand; tap → the orbit filtered to that character's gender; owner-only ⋯ on a row: "Same character as…" (alias merge, `POST /novels/cast/alias`), "Reset to automatic". Non-owners see the rows read-only with "Voices are set by the server's owner".
- **States:** loading (the orbit shows 5 card skeletons; the cast sheet 1 narrator row + 5 character row skeletons, with "Looking up who speaks here…"), voices failed to load ("Couldn't load the voices" + Try again), cast failed to load ("Couldn't load who speaks here" + Try again; the narrator row still works), offline ("Voices need a connection"; a book with saved audio still plays with its saved voices, and the rows are read-only), no voices installed ("No voices are installed on the server, so characters can't be cast here yet."), voice save failed (toast with the error), preview unavailable ("No preview available" on the card).

#### 8.16.5 Audiobook sheet (from the book page)

`large` sheet: "Audiobook"; segmented **Narrate · Save to device** (Save only on phones with a downloads scope); unavailable note "Narration of new chapters isn't available right now. Chapters that already have audio can still be saved."; assist chips "Next 10" (narrate), "All un-narrated (n)" / "All narrated (n)", "None"; one row per chapter with a checkbox and status ("Narrated · saved on this device", "Narrated", "Download the text first", "Not narrated yet"; save mode: "Saved on this device", "Saved copy can't play here · select to save again", "Saving…", "Couldn't be saved · select to retry"); an estimate caption ("About 45 minutes of rendering on the narration PC", 9 minutes per chapter) or "Saves while the app is open. The text is saved too, so the chapter plays and follows along offline."; primary "Make audiobook of 5 chapters" (owner; `POST /novels/audio/render`) / "Save audio of 5 chapters"; a **jobs** section with each job's progress bar (`GET /novels/audio/jobs`, polled every 5 s, 15 s while everything waits for the render PC, backing off to 60 s on failures) and an owner-only cancel ("Stops shortly"). **Job rows** by status: Queued ("Waiting for the narration PC", `g700` clock glyph) · Planning ("Working out who speaks", a liquid ring) · Rendering ("Rendering · 42 %", the liquid bar) · Done ("Narrated", `success` droplet) · Failed ("Rendering failed: {reason}", `danger`, where `{reason}` is the short line for its `error_code`, and "Render again" for the owner; `audio_convert_failed` reads "Rendering failed: the audio couldn't be converted") · Cancelled ("Cancelled", `label3`, removable). **States:** loading (4 row skeletons under the live header), error ("Couldn't load the audiobook status" + Try again), offline ("The audiobook needs a connection. Saved audio still plays."; Narrate hidden, Save to device lists only chapters whose text is downloaded), jobs failed to load (the section shows "Couldn't load narration jobs" + Try again while the chapter list still works). Non-owners see the Audiobook button as status only ("Audiobook · 40 narrated"), with Save to device available and Narrate hidden. Toasts: "Queued 5 chapters for narration. Skipped: 2 already narrated, 1 not on the server yet.", "Nothing to narrate.", "Saving the audio of 5 chapters to this device."

#### 8.16.6 Sleep timer

A menu blooming from the Sleep tile: Off · 5 · 10 · 15 · 30 · 45 · 60 min · End of chapter · End of next chapter · Custom (a minutes stepper). The volume fades over the last 8 s. **Shake to extend +5 min** on phones (accelerometer through `sensors_plus` 7.1.0; threshold 2.2 g over 300 ms; `selection` + toast "Sleep timer +5 min"), off by default with a switch in the menu.

#### 8.16.7 Highlight-as-read

The active sentence gets a band at 14 % of its speaker's tint (narration uses `iris500`), radius 6, padding 2 × 4; the band **slides** between sentences on `snappy` instead of cross-fading; the current word brightens to full ink with a 2 px underline in the tint (stepping, not animated). Follow keeps the active sentence at 38 % of the viewport height and scrolls on `settle` only when it leaves the 20–70 % band; it jumps (120 ms cross-fade) when more than two viewports away. A manual scroll decouples and shows "Back to the voice" (no automatic return on the page). When the timing map does not match the text on screen (`highlight_safe` false or a changed fingerprint), nothing is highlighted and a quiet capsule says "Highlight paused: the text changed".

#### 8.16.8 States

No audio (the listen button is hidden; owners on the book page see "Make audiobook"); preparing (`503 audio_preparing`: the play button shows a liquid ring and "Preparing audio", retrying every 3 s); failed ("Audio couldn't load" + Retry, `error`); offline with saved audio (plays, "Saved audio" tag); offline without (play disabled, reason "Needs a connection or saved audio"); narration unavailable on the server; conversion failed (`audio_convert_failed`: "This chapter's audio couldn't be prepared." + Try again, §8.0.10). **Anywhere in the app,** while narration jobs are active (`GET /novels/audio/jobs/active`), the "Narrating 3" chip of §7.16 shows on Library → Downloads (sidebar and the You tab), opening the book's Audiobook sheet.

- **Keys:** `p` play/pause, `[`/`]` previous/next sentence, Shift+`[`/`]` back/forward 15 s, `<`/`>` speed −/+ 0.05, `v` voices, Esc collapses the player.
- **Coverage:** web NR9–NR15, A82–A86; mobile S26 3–4, 8, 15–16, N3, N4; capabilities §19.3–19.4; reader-ux §4.12.

### 8.17 Library (shelf and browse all)

- **Layout, phone:** tab root. Nav row: profile orb, content-mode capsule, trailing group: Select, ⋯ (Sort, Density, Show filters). Large title "Library" with the count line "142 series followed" (novels: "38 books on your shelf"). **In-page tabs** (a swipeable pager): **Shelf · Collections · History · Bookmarks · Downloads**. The Shelf panel: a "Continue" rail of continue stacks (up to 12), a toolbar that pins under the nav row (search well "Search your library", filter chips All · Reading · Not started · Completed · ★ Favourites, a "Filters" chip opening a sheet with Shelf status: Any, Unread, Reading, Completed, On hold, Plan to read, Dropped, **Tags** as multi-select chips (name + 10 px colour dot, §8.12), and "Clear filters", and at the toolbar's trailing end the plain button **"Browse all"** → `/library/browse`), then the grid. The ⋯ menu also holds "Manage tags" (`?sheet=manage-tags`: a list of tags, each row the colour dot, the name and "12 series"; tap renames inline (max 24 characters); swipe left or ⋯ → Delete opens an alert "Delete this tag? It is removed from every series." with a destructive confirm, `DELETE /library/tags/{id}`; states: loading (5 row skeletons), error ("Couldn't load your tags" + Try again), empty ("No tags yet" / "Add tags from a series' ⋯ menu."), offline ("Tags need a connection", read-only), delete failed (toast "Couldn't delete that tag" and the row returns), rename failed (inline "Couldn't rename that tag")).
- **Grid:** Comfortable (3 columns on a 390 px phone), Compact (4 columns, title only), or List (rows with a 64 px square cover, title + status tag, meta, favourite and follow buttons). **Pinch the grid to change density** (2 ↔ 3 ↔ 4 ↔ 5 columns and List below 2): during the pinch the grid scales continuously around the focal point; on release it snaps to the nearest column count and reflows on `snappy` (items travel to their new cells from their scaled positions), `select` per step. The Density menu and a slider in the ⋯ menu are the non-gesture path.
- **Poster overlays:** status tag, "N new", favourite star (always visible when favourited; appears on hover or long-press otherwise), follow bell (hover on desktop, context menu on touch), downloaded mark.
- **Browse all** (`/library/browse`, reached from the Shelf toolbar's "Browse all", the Library tab's long-press jump list, the palette's Go to group and `g b`): the same panel with the toolbar expanded and filters written to the URL with the contract's names (`?q=&status=&sort=&fav=&reading_status=&tags=`, §8.0.3; the web's older `search` and `is_favorite` are read as aliases); a note "Showing the first 200 of 412. Narrow it with search or a filter." when capped. Sort menu: Recently updated, Recently added, Title, Manual order (drag to reorder, which writes `sort_order`).
- **Novels mode:** the grid becomes the book shelf (rows with book plates, Literata titles, byline, blurb, genres, note).
- **Layout, desktop:** the Library sidebar item expands to its five children; the Shelf page has the toolbar row (search, chips, sort menu, density segmented control Comfortable · Compact · List) and a 6 (1024) to 10 (1920) column grid; hovering a poster reveals the follow bell and favourite star as 32 px content-twin buttons (§2.4.1: `rgba(19,19,23,0.62)` disc, rim and inner light, no backdrop read, because they repeat on every poster) at its top corners; Shift-click selects ranges.
- **Signature moment:** the density pinch (above); and when an update check finds chapters while the Library is open, the affected posters' "N new" badges pop (`tick`) in a wave from the top.
- **Select mode:** the "Select all ({n} visible)" and "None" assist chips above the grid and `mod+a` (§7.35), and the bulk toolbar with Favourite, Unfavourite, Mark read, Mark unread, Add to collection, Download next 10, Remove from library (with Undo; no confirm, because Undo restores follows with their favourite, status, notify and override).
- **Transitions:** tab root cross-fade; zoom into detail; the pager slides between sections.
- **Gestures:** pull to refresh, pinch density, long-press lift (context menu: Continue, Details, Favourite, Mark read, Add to collection, Download next 10, Previously on, Recommend to…, Remove from library), select-mode painting.
- **States:** loading (count bar + 12 poster skeletons); offline (follows from the device cache with the "Offline" capsule; posters without downloaded chapters dim to 70 %); error ("Couldn't load your library" + Try again); empty ("Your shelf is empty" / "Follow series from Sources to build your shelf." + "Browse sources"; novels: "Add a book from a novel source to start your shelf"); empty search ("No results for “{q}”" + Clear search); empty filter ("No series match these filters" + Clear filters); bulk running and results (toolbar).
- **Keys:** `/` search, arrows and `h j k l` through the grid, Home/End, Enter opens, `x` select, `shift+x` range, `*` favourite, `m` mark read, `alt+arrows` reorder (manual order), `[`/`]` sections.
- **Coverage:** web R5 LS1–LS12 (shelf), R6 LB1–LB26, BA1–BA10, A25–A36; mobile S08 (followed grid, novel shelf, long-press M1 sheet → context menu), S09 1–21; capabilities §7–8.

### 8.18 Collections and collection detail

**Collections** (Library section / `/library/collections`):

- **Layout:** count line ("6 collections" or "Group your series by theme, mood or reading list."), nav row "+" (New collection), search well (when at least one exists), sort menu (Name A–Z, Most series, Recently created, Custom order with drag), then **collection cards** (§7.7: fanned stacks of the first four member covers), 1 column on phone, 2 to 3 on desktop. Shared collections (§9.3.3) carry a friend-orb badge and "Shared with Aarav".
- **New collection:** a `medium` sheet (desktop window) with Name ("My reading list"), Description (optional), a "Share with your Circle" row (only when this profile shares; it opens the share sheet of §9.3.3 after creation), error line, primary "Create". The new card drops into the list on `celebrate`.
- **Signature moment:** tapping a card **fans** its stack open (the four covers spread to 0°, ±12°, ±24° on `celebrate`) as the collection zooms open, and the fanned covers become the header of the detail page.
- **States:** loading (4 card skeletons); offline; error; empty ("No collections yet" + "Create your first collection"); no match ("No collections match your search").
- **Keys:** `/` search collections, `n` new collection, arrows and Enter through the cards, `alt+↑/↓` reorders in Custom order.
- **Coverage:** web R8 CO1–CO10, A44–A45; mobile S24 1–12.

**Collection detail** (`/library/collections/:id`):

- **Layout:** header band 220 px: the fanned covers enlarged over the collection's ambient field, name `largeTitle`, description `callout`, "12 series"; action row: "Add series" (secondary), Edit (icon), Share toggle (icon, social), ⋯ (Delete collection: hold-to-confirm "The series stay in your library."). Member grid (as Library; titles joined from the library payload); reorder by drag (the collection's member `sort_order`).
- **Add series:** a `large` sheet with a search well and the followed series not already in it (36 × 54 cover + title), tapping one adds it with a fly-into-the-header motion (the Cover arc move, §4.10) and keeps the sheet open for more; "No series available"; "No series match your search".
- **Edit** (`?sheet=collection-edit`, desktop a 560 px window): the same fields as New collection (Name, Description), prefilled; the primary "Save" is disabled until a field changes (web CD4) and while the name is empty; error line under the fields ("Couldn't save the collection"); Esc or the close button discards with no confirm when nothing changed, and with the alert "Discard your changes?" when something did.
- **Remove:** context menu "Remove from collection" or select mode, with Undo toast ("Removed from Weekend reads · Undo"); orphans (no longer followed) show "No longer in your library".
- **States:** loading (header skeleton + 6 posters); empty ("This collection is empty" + "Add series"); mode mismatch ("No novels in this collection" / "It holds titles from the other mode. Switch modes to see them."); error (+ Back to collections); **offline** (the last loaded members from the library cache, with the "Offline" capsule; Add series, Edit, Share, reorder and remove are disabled with "Needs a connection"; with nothing cached, the offline lens "This collection needs a connection" + "Open downloads").
- **Keys:** `a` add series, `e` edit, arrows through the grid, `Delete` removes the focused member (with Undo).
- **Coverage:** web R9 CD1–CD12, A46–A50; mobile S25 1–13; M8.

### 8.19 History

- **Layout:** Library section (phone) / page (desktop): a segmented **By series · Timeline** (by series: `collapse=series`, one tile per book; timeline: `collapse=none`, one row per chapter read); day headers ("Today", "Yesterday", "This week", "Earlier") in `footnote` uppercase; a grid of **history tiles** (§7.7) with a 3 px progress line, the play orb ("p. 18" or "42 %"), and for finished chapters a "Next" orb that resolves the next chapter (fetching the chapter list, `aria-busy` while resolving; falls back to the series page). Titles fall back to "Unknown series" in `label3`. 50 per page with a "Load more" row (offset paging).
- **Desktop:** the tiles follow the Library grid's column rule (6 columns at 1024 px to 10 at 1920 px, §8.17), and the Timeline view is a plain list at most 880 px wide, centred.
- **Gestures:** tap the tile → series detail (zoom); tap the orb → the reader at the saved spot (dive); long-press → Continue, Open series, Mark finished, Recommend to…; pull to refresh.
- **States:** loading (10 tile skeletons); offline ("Reading history needs a connection" with the device's recent reads from local progress listed below it); error; empty ("Nothing read yet" / "Open a chapter and it will appear here as you go." + "Go to library").
- **Keys:** arrows, Enter (series), `c` continue the focused item, `n` next chapter.
- **Coverage:** web R10 RH1–RH5, A38–A39; mobile S13 1–8.

### 8.20 Bookmarks

- **Layout:** plain list of bookmark rows: cover 44 × 66, series title `headline`, position line "Ch 12 · Page 7" (manga) or "Ch 3 · Paragraph 118 · 62 %" (novel) with a strip or book glyph, the novel snippet (Literata italic 15, 2 lines), the note when present, "Saved 28 Sep, 21:41" `caption1`, and a stale note in `warning` ("The text here changed; this opens at the nearest spot."). Content mode filters the list.
- **Gestures:** tap → dive into the reader at the anchor; swipe left → Remove (Undo re-creates the bookmark at the same anchor); long-press → Open, Add note, Remove, Copy link.
- **Offline:** phones read the local store and sync through the bookmark outbox; a pending sync shows a small "Syncing" capsule. A `409 bookmark_deleted` during a sync (a note added to a bookmark another device removed) drops the row on `dismiss` with the toast "That bookmark was removed on another device" (no Undo).
- **Filter:** `?source=&series=` (from series detail) shows a dismissible chip "Solo Leveling ×" above the list, and only that series' bookmarks.
- **Desktop:** the list is at most 880 px wide, centred in the content column.
- **States:** loading (5 row skeletons); offline (local bookmarks listed; server-only ones noted); error; empty ("No bookmarks yet" / "Press B while reading, or use the bookmark button, to save the exact spot." + "Go to library").
- **Keys:** arrows, Enter, `Delete` (with Undo), `u` undo.
- **Coverage:** web R11 BM1–BM5, A104–A105; mobile S14 1–8; capabilities §15.

### 8.21 Updates

- **Layout:** pushed from the Home bell (phone) or the sidebar (desktop). Large title "Updates", line "5 unread · 142 followed"; nav row trailing: **Check now** (refresh glyph; while a run is in progress it becomes a liquid ring and the line reads "Checking 142 series…"), ⋯ (Mark all read, Mark all manga read, Mark all novels read, Update settings (admin)). Segmented **All · Unread · Followed**, and a source filter chip ("All sources", a menu from `GET /updates/sources`).
- **Summary row** (tap → `/settings/notifications` for admins; an info popover for others): "Checking every 30 min · last check 12 min ago · notifications on".
- **Desktop:** one column, at most 880 px wide, centred; the segmented control and the source filter sit in the toolbar row.
- **Notifications:** one card per series (§7.7): cover, title, "3 new · Ch 141–143", time, chapter chips (each opens the reader and marks that notification read); unread cards carry an `iris400` dot and a 2 px leading bar; read cards at 70 %.
- **Followed** segment: rows with title, source capsule, "412 chapters" or "Not checked yet", a notify bell toggle, swipe left or ⋯ → Unfollow (with Undo), ⋯ → Check this series now.
- **Admin:** a "Recent checks" section: rows "Scheduled · completed · 142 series · 5 new" + start time, and failures with the error in a `mono` block. Tapping a run opens its detail (`GET /updates/runs/{id}`) as the `?sheet=run` `medium` sheet (desktop: a 560 px window): trigger, status tag, started and finished times, duration, series checked, new chapters, the per-series failures as rows (cover 36 × 54, title, the error line), and the whole error in a `mono` block with a "Copy" plain button; states: loading (6 row skeletons), error ("Couldn't load this check" + Try again), offline.
- **Signature moment:** when a check finds chapters, new cards **drop in** from the top with the wave, the Home bell swings (§2.7), and the global capsule shows for other screens.
- **Gestures:** pull to refresh (runs Check now), swipe right on a card → Mark read, swipe left → Open series; long-press → Mark read, Open series, Turn off notifications for this series.
- **States:** loading (3 card skeletons); offline ("Updates need a connection to check"); error ("Couldn't load notifications" + Try again); check already running (toast "A check is already running"); empty ("No new chapters yet" / "Follow a series and this fills in the moment a new chapter is found." + "Browse sources"); all read ("You're caught up" lens with a small check droplet); Followed segment empty ("You don't follow anything yet" + "Browse sources"); rate limited.
- **Keys:** `r` check now, `m` mark the focused card read, `shift+m` mark all read, arrows, Enter.
- **Coverage:** web R22 UP1–UP8, A96–A103, A108; mobile S23 1–13; G39; capabilities §21.

### 8.22 Downloads

- **Layout, phone:** Library section and `/downloads`. Header "On this device" `caption1` + "Downloads" large title; in-page tabs **Chapters · Queue · Storage**. No pull to refresh (local data).
- **Storage meter** (top of Chapters): a **liquid capsule** 44 tall split into this profile's downloads (`iris600` at 60 %), other app data (frosted `fill2`), and free space (clear), with the cap as a vertical 1 px marker and a label "1.2 GB of 10 GB"; values slosh into place on `lens` when they change.
- **Chapters tab:** the OCR run banner (phones: "Extracting text · page 3 of 40" with a bar, paused "Text extraction pauses while the app is in the background", uploading, done "Text extracted: 2,140 words are now searchable", cancelled, failed; Cancel while busy); the "Where it lives" note (iOS: "Downloaded chapters live inside ManhwaManiacs. For a copy you can open elsewhere, use Save to Files."); then one **series card** per series, biggest first: title (links to the series), "40 chapters · 3 with audio · 1.2 GB" (a book: "12 chapters of text · 3 with audio · 14 MB") or "12 of 40 chapters saved · 800 MB", a pin toggle (pinned series are exempt from auto-delete), ⋯ (Save to Files…, Remove all downloads: hold-to-confirm), expand chevron; expanded: chapter rows with a status line in its tone ("40 pages · 24 MB", "Saving 18/40", "Incomplete · 38/40 pages", "Paused: device is full", "Pages changed on the server · save again", "Deletes in about 2 days", "Open now, kept"; novel text: "Text · 3.4k words · 40 KB", "Fetching the text…", "Saving the text…"; narration audio: "Chapter 12 · audio · 18 MB", "Fetching the audio…", "Saving the audio…", "The saved audio can't play here · save again", with the row's ⋯ holding "Remove saved audio" beside "Remove download"), a progress bar while saving, OCR button (manga, phones: "Extract text" / "Text extracted · redo"), Save to Files (phones), remove (swipe left; the toast "Removed from this device" offers "Download again", which re-queues it, because deleted files cannot be restored instantly).
- **Queue tab (phones):** the active panel: "Downloading" / "Waiting to start" / "Paused" with pause/resume and cancel-all (alert "Cancel all downloads? Everything queued, downloading or failed is dropped. Finished chapters stay." Keep them / Cancel all); the current chapter block (series, "Chapter 12 · page 18 of 40", a 6 px liquid bar, "2 more chapters downloading alongside", "12 of 40 saved in this series"); pause reasons with actions ("Paused by you" + Resume; "Paused while ManhwaManiacs was in the background", which clears itself on return; "Paused: this phone is almost full. Downloads stop before the last 1.5 GB." ; "Paused: downloads filled your 10 GB limit." + "Storage settings" → `/settings/storage`; "Waiting {n} s: the server is pacing downloads" with a live countdown, when the bulk bucket (6 requests a minute for manifests) refused a request and the queue sits out its 30 s cool-down, clearing itself; "Signed out" (§8.0.9), clearing itself on the next sign-in); queue rows (queued / downloading "page 18 of 40" or, for books, "Fetching the text…" / "Fetching the audio…" / failed with the error), each with retry and remove, reorderable by drag (priority); the foreground note "Downloads run while ManhwaManiacs is open; leaving pauses them and coming back picks up where they stopped."
- **Storage tab (phones):** usage line; cap chips 2 GB · 5 GB · 10 GB · 20 GB · Unlimited; "Chapters at once" chips 1 · 2 · 3; "Delete after reading" chips Off · 24 h · 48 h · 7 days; platform note (iOS: "Browse, copy or delete downloads in the Files app: On My iPhone → ManhwaManiacs"; Android: "Downloads live in the app's private storage"); "By series" breakdown rows (pin glyph for pinned, "12 ch · 240 MB"); "Free up space" (removes read chapters past the retention; toast "Removed 8 chapters" or "Nothing to free up right now"); **Image cache** card (size, "Clear image cache") and **Metadata cache** card ("Clear metadata cache").
- **Web:** tabs Chapters · Storage; Storage shows the browser quota ("380 MB of 4.2 GB used by this site · 3.8 GB free" or "This browser doesn't report a storage quota"), the explainer ("Saving stops before the last 250 MB of the quota. When it gets close, finished chapters are removed oldest first; never one you haven't read, and never the one you have open."), **Protect storage** (success capsule "Storage protected" or secondary "Ask to protect storage" → `navigator.storage.persist()`; when the browser answers `false`, the inline notice "Your browser didn't allow it. Browsers usually grant this to sites you use often or have installed; the downloads still work, but the browser may clear them when space runs low."), retention chips 2 days · 7 days · 30 days · Never, "Remove all downloads" (hold), "Reset offline storage" (hold; unregisters the service worker and clears caches) with its explainer; an "Offline: only saved chapters open" capsule when offline.
- **Save to Files (phones):** a `medium` sheet: "Page images" ("A numbered folder per chapter") or "CBZ file" ("One file per chapter, for comic reader apps"); a progress alert "Saving to Files…"; a result alert "Saved to Files · 12 chapters · 480 pages" with the selectable path and a skipped count; toasts "Nothing to save yet: these chapters are still downloading", "Couldn't save to Files. Check your free space." **Destinations:** iOS writes into the app's Documents folder (`ManhwaManiacs/{series}/`), which the Files app shows under On My iPhone → ManhwaManiacs; Android writes through `MediaStore.Downloads` (`RELATIVE_PATH = "Download/ManhwaManiacs/{series}"`, no storage permission on API 29+) and the result alert shows that path ("Saved to Download/ManhwaManiacs/Solo Leveling"), because no folder picker is built. On Android the sheet's title reads "Save to Downloads".
- **Signature moment:** removing a series **drains** its segment out of the liquid meter (the fill level falls with a meniscus wobble on `lens`) while its card collapses on `dismiss`.
- **States:** no profile ("Downloads belong to a profile" + Choose a profile); unsupported (web without a service worker or on an insecure origin: "Downloads are unavailable here"); checking ("Checking what's stored…"); empty ("Nothing downloaded yet" / "No series downloaded yet" / "No books downloaded yet" + "Go to library"); error ("Couldn't read downloads").
- **Desktop:** one column, at most 880 px wide, centred, with the storage meter full width at its top.
- **Keys:** arrows, `Delete` (removes, with "Download again" in the toast), `p` pins the focused series (Chapters tab) or pauses and resumes the queue (Queue tab); Space keeps its normal meaning (scroll, or activate the focused button).
- **Coverage:** web R23 DL1–DL9, A90–A95; mobile S21 1–40, S32 1–4, M5, §6c; capabilities §24.

### 8.23 Dialogue search (OCR)

- **Layout:** large title "Dialogue search", subtitle "Search what characters said across the series you follow, and jump to the page."; the search field (autofocus, 350 ms debounce); results: cards with the series cover 44 × 66 and title (joined from the library), "Ch 12", the snippet with highlighted terms (`iris600` at 30 % behind `label1`), "212 words · Vision" `caption1`; "Showing the first 20 of 86 matches" + "Load more".
- **Signature moment:** opening a result **finds the page**: the reader dives in at the chapter, fetches the chapter's OCR pages, glides the strip on `camera` to the page containing the match, and the **hit lens** settles over the matched speech bubble, magnifying the line 1.12 × (§8.14.9), with "Match 1 of 3" navigation that slides the lens from bubble to bubble.
- **Novels mode:** the object lens "Dialogue search is for manga" / "Switch to Manga to use it." + "Search novel text instead" (→ Search with the Novel text scope).
- **Phones:** a hint row "Only chapters with extracted text can be searched. Extract text from downloaded chapters in Downloads." with a link.
- **Desktop:** one column, at most 880 px wide, centred.
- **States:** idle lens (`bubble-search`: "Search the dialogue you remember" / "Type at least one word."); loading (3 card skeletons); error ("Search failed: check your connection"); empty ("No dialogue matches" / "Nothing found for “{q}” in the chapters you follow."); offline.
- **Keys:** `/` focus, `↓` into results, Enter opens.
- **Coverage:** web R24 OC1–OC8, A106; mobile S27 1–7; capabilities §20.

### 8.24 You (hub, phone) and About

- **Layout, phone:** tab root `/more` (the contract's `index` screen). A profile block: orb 72 (with the daily goal ring, §9.2.2), name `title1`, "@yash · Administrator" `footnote`, secondary "Switch profile" (the orb flies to the picker), content-mode switch. Cards: **Reading** (streak flame mini, "This week: 3 h 12 min · 14 chapters", a 7-day sparkline → Statistics), **Your {year} in chapters** (visible 1 December to 31 January and on demand from Statistics → Wrapped), **Circle** (the presence orbs and the last three items → Circle; for a profile that doesn't share, the "Read together" opt-in line). Grouped lists: **Library**: Updates (count), For you, Dialogue search (manga mode), Collections, History, Bookmarks, Downloads (count); **Settings**: Appearance and skin, Reader, Content (18+), Circle and privacy, AI and recaps, Sound and haptics, Notifications (admin), Security, Storage, Backup (admin), Server (phones), Diagnostics, Shortcuts (web, tablets with keyboards); **Administration** (admin): System status, Members; **About**: What's New, version "ManhwaManiacs 3.5.0 (57)", update row (Android APK "Update available · 3.5.1" / "Up to date" / "Checking…" / `warning` "Couldn't check for updates" with a Retry plain button / "Server unreachable" when the APK channel's server does not answer; iOS "Managed by SideStore"), Licences; **Switch account** (signs out and opens Login with the username empty); **Sign out** (destructive plain, alert "Sign out? You'll need to sign in again on this device.").
- **Desktop:** `/more` redirects to `/settings`; its cards live in the sidebar (Stats, Circle) and the profile menu.
- **Signature moment:** the profile orb here is the same object as the dock's You tab icon: arriving on the tab, the tab's orb lifts out of the dock and lands in the profile block on `zoom` (the Orb lift move, §4.10; only the first time per session; afterwards a cross-fade).
- **States:** loading (profile block skeleton), offline (settings still open; server-backed rows show the offline capsule), error per card.
- **Coverage:** web R25 M1–M6; mobile S22 1–18, G8, G9.

### 8.25 Settings

- **Layout, phone:** pushed page "Settings" with a search well (a full-screen overlay filters the indexed settings by label and keywords, tapping a result opens its section and flashes the row with the Row pulse move, §4.10), then grouped lists per section, each opening a sub-page. The index is one file per client, `frontend/src/skins/glass/copy/settings-index.ts` and `mobile/lib/skins/glass/copy/settings_index.dart`: one entry per row of §8.25.1 to §8.25.16 (`{id, label, keywords[], section, platforms, admin}`), generated into both from the same list so they never differ; rows hidden on this platform, for this role or by the server's capabilities are left out of the results. States: "No settings match “{q}”". **Desktop:** a 240 px section list at left (inside the content column, not the sidebar) and the section panel at right; `↑`/`↓` move between sections.
- Rows use §7.17 anatomy with 30 px icon tiles in the section's colour.
- **Quick links** (desktop, under the section list): Reading history, and System status for admins.
- **Keys:** `/` searches settings, `↑`/`↓` move between sections, Enter opens a section, Esc returns to the section list.
- **Footnote:** "Settings save as you change them. Switching skin restarts the app."
- Sections the server does not offer (the `capabilities` flags on `GET /settings`) are hidden, and profile-scoped sections show the notice "Choose a profile first" with a link and disabled controls when no profile is active.
- Server-backed sections (Content, Circle and privacy, AI and recaps, Notifications, Security, Members, Backup) each show row skeletons while loading, an inline error block with Try again when the load fails, and, offline, the notice "These settings need a connection" with their controls disabled; device settings (Haptics, UI sounds, Server, Diagnostics, Shortcuts) always work.

#### 8.25.1 Appearance and skin

- **Skin:** two large preview cards side by side (phone: stacked), each playing its skin's looping animated WebP (under Reduce Motion the still first frame with "Play preview", §4.10), name in `title2` ("Glass", "Cinematic"), a one-line character ("Liquid glass, springs and depth." / "Dark cinema, posters and title cards."), and a "Current" tag on the active one. Choosing the other card starts the switch flow (§8.25.2).
- **Solid glass:** switch (forces the Reduce Transparency look on every platform).
- **Increase contrast:** switch (forces the Increase Contrast rules of §4.11; the only source on Android, which exposes no high-contrast signal to apps).
- **Legible text:** switch (Atkinson Hyperlegible Next across the whole interface, §3.6), with the preview sentence "Read the next chapter" in both faces.
- **Reduce motion in this app:** switch (forces the Reduce Motion rules regardless of the OS). Solid glass, Increase contrast, Legible text and Reduce motion are per profile, stored in the profile's scoped `mm.boot.a11y` entry that the boot script reads before the first paint (§8.0.8).
- **Light follows the device:** switch (per profile, `mm.glass.prefs`; gyroscope specular and hero tilt; off freezes the light at 135°). Default on in the apps and on Android Chrome; **off by default in iOS Safari**, where motion needs permission: turning it on calls `DeviceOrientationEvent.requestPermission()` from that tap, with the switch's caption "Allow motion so the glass follows your phone"; a refusal flips the switch back with the caption "Motion access was declined. You can allow it in Safari's settings for this site."
- **App icon follows the skin:** switch (phones; **default off**). When on, the icon changes only when the skin is chosen explicitly on this device (this row's skin cards, onboarding step 2, the profile form of the active profile), never on a profile switch or a boot-time mismatch restart, so a device shared by a Glass profile and a Cinematic profile does not flip its icon (and show iOS's icon alert) on every switch; the icon shows the skin last chosen on this device (§12.2). Stored per device (`mm.icon.follow`).

#### 8.25.2 The skin switch and restart flow

1. **Choose:** tapping the Cinematic card (or "Skin: Cinematic" in the command palette) opens a plain **alert** (§7.11) blooming from the card: its live preview small at the top, title "Restart in Cinematic?", body "Everything about the app changes: layout, navigation, type and motion. Your library, progress and downloads stay exactly as they are, and you'll come back to this screen." plus, when downloads are queued, an inline notice "Downloads pause for a moment and resume after the restart." Buttons: **"Stay in Glass"** (secondary, first, initial focus) and **"Restart in Cinematic"** (the alert's tinted action). No hold: nothing is lost on a switch and the 10 s Undo exists.
2. **Persist:** `skin.switch` haptic (`heavy`); `PATCH /profiles/{id} { skin: "cinematic" }` (queued in the offline outbox on phones); the device mirror (web cookie `mm-skin`, `sessionStorage['mm.skin.return']` = the current path, and `sessionStorage['mm.skin.splash.glass']` removed so a later switch back into Glass in this tab plays the Droplet again; phones `mm.skin.active` and `mm.skin.return`); the web posts `{ type: "skin-changed" }` to the service worker (it drops the pages cache and re-fetches saved chapters' documents).
3. **Outgoing (Glass's own exit, the "melt", 620 ms):** every glass surface dematerialises at once (lensing out over 350 ms), the content blurs 0 → 40 px on `smooth`, and a single droplet contracts from the edges to the centre of the screen (a circular mask closing on `page`), leaving black; the `melt` sound when sounds are on. Reduce Motion: a 200 ms fade to black.
4. **Restart:** web `location.replace(returnPath)`; phones `AppRestart.of(context).restart()`. With "App icon follows the skin" on and the skin chosen explicitly here, `flutter_dynamic_icon_plus` 1.4.1 switches the icon: on iOS inside this moment (the system's one-line alert lands over the black); on Android the `activity-alias` swap is **queued** and applied when the app next goes to the background (`AppLifecycleState.paused`), never during the restart, because toggling components can end the task (§12.2). Budget: under 1.5 s from the confirm to the new skin's splash.
5. **Incoming:** the new skin's own splash and reveal, landing on the same route, and its 10 s "Switched to Cinematic · Undo" toast (drawn by that skin).

- **Arriving into Glass** (from Cinematic): Glass plays the full Droplet reveal (§12.4), lands on the return route, and shows the toast "Switched to Glass" + "Undo" with a 10 s draining rim; Undo runs this flow back without the alert.
- **Profile switch into a profile whose skin differs:** steps 2 to 5 run inside the profile hand-off (§8.5) with no alert and no Undo, per `stack-decision.md` §2.4.
- **Offline:** the switch still works on this device (the PATCH waits in the outbox); the alert adds "This profile will switch on your other devices once you're back online."

#### 8.25.3 Reader defaults

Direction (Left to right · Right to left · Vertical; a stored horizontal-strip direction from the current app opens Single paged in that direction, §8.14.1), Brightness default (20 to 100 %), Warmth default, Fit (Width · Height · Screen), Tap zones (the diagram from §8.14.5), Chapters (Continuous · One at a time), Page gap, Cinema mode by default, Keep screen awake (phones), Auto next chapter, Lock reader controls ("Tap the centre 5 times to unlock"), Volume keys turn pages (Android), Refresh rate (Android: Auto · 30 · 60 · 90 · 120, "Auto uses the highest rate your screen supports"), "Reset reader settings" (hold-to-confirm; toast "Reader settings reset"). Three more groups on the same page, each a deep-link target (§8.0.3): **Novels** (default face, size, line height, measure, paper, Scroll · Paged, page turn; the Aa sheet's values for books that have none of their own), **Listen** (default speed, "Continue to the next chapter", sleep timer default, "Shake to extend"), **Ambient** (Page-tinted chrome, Cruise default speed, Guided view on by default for chapters with panels, and a row to Sound and haptics for soundscape defaults).

**Migrating stored values** (run once per profile on first Glass launch, by the shared data layer; old keys are read, never rewritten or reinterpreted, and new values go under new keys so a return to the other skin loses nothing):

| Setting | Stored today | Glass value | Rule |
|---|---|---|---|
| Brightness | web `mm.reader-settings.dimmer` 0–0.92 (K31); mobile `reader_brightness` 0.2–1.0 (K09) | `brightness` 0.2–1.0 | web: `brightness = 1 − dimmer / 0.92 × 0.8` (0 → 1.0, 0.92 → 0.2); mobile: kept |
| Warmth | web 0–0.7 (K32); mobile 0–1 (K10) | `warmth` 0–1 | web: `warmth = old / 0.7`; mobile: kept |
| Cruise speed | web `autoScrollSpeed` integer 1–10 = 20–220 px/s (K39, per series); mobile 30 / 60 / 120 px/s (session only) | `cruiseSpeed` multiplier 0.25–4 of 60 px/s, a **new key** beside the old one | web: `(20 + (v − 1) × 22.2) / 60`, rounded to 0.05 (5 → 1.80); mobile: nothing stored, default 1.0 |
| Page transition | web `pageTransition` boolean (K33) | Slide · Fade · None | true → Fade, false → None; Slide only by the reader's own choice |
| Library density | mobile cover scale 0.7–1.6 (K15); web density (K26) | Comfortable · Compact · List and the pinch column count | mobile: < 0.85 → Compact (4 columns), 0.85–1.25 → Comfortable (3), > 1.25 → 2 columns; web: kept |
| Direction, fit, zoom | web per series (K35–K38); mobile per device (K01–K02) | per series on both (§8.14.5) | web: kept; mobile: the device values seed each series' entry on its first open; `leftToRight` / `rightToLeft` open Single paged (§8.14.1) |
| Reader background | mobile Dark / AMOLED / Paper (K11) | Black · Graphite | Dark → Graphite; AMOLED and Paper → Black |
| Novel paper | web K40, mobile K26 | the seven dark papers | the mapping of §8.15.1 |

#### 8.25.4 Content

The 18+ switch and flow (§7.25); the blocked state without a profile.

#### 8.25.5 Sound and haptics

Haptics switch (per device, default on) with the "Feel it" row of §5.3; UI sounds switch (per device, default **off**) with a volume slider (−24 to 0 dB, default −6) and a "Hear it" row (§6); Soundscape defaults (per profile): the scene (Off · Rain · Wind · Ocean · Hearth · Stream · Deep, §9.4.2), Match the story, the Bed · Detail · Tone mix, the volume and Lower under narration.

#### 8.25.6 Notifications (admin)

- A schedule strip: three cells "Last check 12 min ago", "Next check in 18 min" (`warning` "Overdue by 7 min" with "See System status"), "Every 30 min".
- Switches: "Check for new chapters automatically" ("Nothing is checked and nothing notifies while this is off."), "Check when the server starts", "Notify me about new chapters" ("The master switch. Turn one series off from its own page.").
- Interval slider 5 to 120 min in steps of 5 with `detent.tick` ticks and a magnet at 30 (`detent.magnet`).
- "Source catalogue cache" stepper (5 to 1,440 min, default from the server; `source_cache_ttl_minutes`), with the helper "How long a browsed catalogue is reused before asking the source again."
- Draft then save: edits collect in a floating glass bar "Unsaved changes" with "Discard" and a tinted "Save"; saved → toast "Saved"; error inline.
- States: loading (5 row skeletons), error + Try again.

#### 8.25.7 Security

- **Change password:** Current, New ("At least 8 characters"), Confirm; errors ("Enter your current password", "Enter a new password", "At least 8 characters", "Password is too long", "The new passwords don't match", "Your new password must be different"); primary "Change password"; success toast "Password changed. Your other devices were signed out; this one stays signed in."
- **Where you're signed in:** refresh icon (spins while refreshing), rows: device glyph, label ("ManhwaManiacs app", "Safari on macOS", "Unknown device"), "This device" tag, "Last used 3 h ago · 10.0.0.2", "Signed in 12 Sep · expires 11 Dec"; swipe left or ⋯ → "Sign out this device" (alert); the current device → "Sign out" (alert).
- **Sign out everywhere:** a `danger` inline notice ("Every device, including this one, will have to sign in again. Downloaded chapters stay.") and a hold-to-confirm "Sign out everywhere"; the alert path has the acknowledgement switch "I understand this signs me out here too".
- States: sessions loading, error, empty ("No active sessions").

#### 8.25.8 Members (admin)

- **Phone:** rows per account: "@aarav", tags Admin · You · Deactivated, "Joined 27 Jul · last seen 2 h ago · 2 sessions" (or "Never signed in"), actions in ⋯ and as swipe: Deactivate / Reactivate, Delete (hold-to-confirm alert "Delete @aarav? This removes their profiles, library, progress, bookmarks and everything else they own. It can't be undone."); the owner's own row has actions disabled with "You can't deactivate or delete your own account".
- **Desktop:** a table (min 640 px, in its own horizontal-scroll container) with columns Member, Status, Joined, Last seen, Sessions, Actions; own row tinted `iris600` at 6 %. A refused action shows `cannot_manage_self` or `forbidden` with the copy of §8.0.10.
- An explainer above the list: "Registration is open on this server. Deactivating keeps an account's data and signs it out everywhere; deleting removes the account and everything it owns."
- Footer "2 other accounts" + Refresh. States: loading (3 row skeletons), error, empty ("Only your account so far").

#### 8.25.9 Storage

Phones: opens the Downloads Storage tab (§8.22). Web: opens Downloads → Storage.

#### 8.25.10 Backup and restore (admin)

- **Nightly backup card:** "Last nightly backup: 03:10 · 42 MB · OK" (`success`) or "Unknown" (`warning`; unknown is never shown as healthy) from `GET /backup/status`, polled every 30 s.
- **Restore staged banner:** `warning` inline notice "A restore is staged and applies when the server restarts." + "Cancel staged restore".
- **Export:** explainer (the whole database, every account; keep it private), primary "Export backup" ("Preparing…"; web downloads the file, phones open the export in the browser), "Saved manhwamaniacs-2026-09-28.db" confirmation.
- **Restore:** a `danger`-barred section: explainer (replaces everything, applies on the next restart, nothing is kept), "Choose backup file" (`.db` only; errors "That isn't a .db file", "That file is empty"), the chosen file's name and size, and "Restore from this file…" which opens an alert with the four consequences as bullets, a field "Type RESTORE to confirm" (case-insensitive) and a destructive "Restore" (enabled once the phrase matches); success alert "Restore staged. Restart the server to finish."
- **Members** link (desktop places Members under this section too).

#### 8.25.11 Server (phones)

"API base URL" field, "Save" (toast "Server URL saved and applied", or the validation error: https required), "Reset to default" (toast "Reset to the default address"), loading and error states.

#### 8.25.12 Diagnostics

Rendering performance (FPS in `iris400`, Jank % coloured success < 5, warning < 15, danger above, Worst frame ms), frame rows (average frame, CPU build, GPU raster, samples; "Starting profiler…", "Scroll a screen to sample"), Display (Android: current refresh rate, capability, resolution; iOS: "Display modes are only switchable on Android"), Device (platform, CPU cores, screen, app version, build mode), Image cache (live, cached n / max, memory), and Glass: "Renderer: Impeller", "Glass quality: premium (chrome) · standard (page controls in scroll views)", "Refraction: on" or "frosted", and "Glass layers on screen" (a live count of `backdrop-filter` elements on the web and `BackdropGroup` members on Flutter, `warning` above 6 and 8, §15.7). Development rows: "Preview Glass skin" (the debug entry until Glass is available, §8.0.8), "Glass calibration" (the checkerboard page, §15.8) and "Show motion timings" (§15.8).

#### 8.25.13 Shortcuts (web and hardware keyboards)

The live registry grouped (General, Navigation, Library, Search, Sources, Reader, Novel reader, Listen), each row a description and keycaps; the **Single-key shortcuts** switch; "No shortcuts are active on this screen" when empty.

#### 8.25.14 Account, language and about

- **Account:** orb, display name, "@username", Admin tag; "Password and security" row; "Profiles" row (→ Manage profiles); "Sign out" (alert).
- **App language:** not shown. The stored `settings_language` (mobile K14) is kept untouched, and the row arrives with localisation (as in `cinematic/DESIGN.md` §8.30.2), because a language choice that changes nothing is a broken control.
- **About:** app card ("ManhwaManiacs", "A self-hosted manga, manhwa and web-novel reader", version and build), updates (Android APK: "Up to date · 3.5.0" / "Update available · 3.5.0 → 3.5.1" + "Download update" → the install-steps alert / "Checking…" / `warning` "Couldn't check for updates" + Retry / "Server unreachable"; iOS: "Managed by SideStore" with the source URL, "Copy source URL", the 7-day signature note), What's New, **Open-source licences**, "Reset reader settings". An external link that fails to open ("Read on {site}", the SideStore source) shows the toast "Couldn't open {site}".
- **Open-source licences** (`/settings/about?sheet=licenses`; a `large` sheet on phones, a 560 px window on desktop; not the stock page): a search well "Search packages" at the top; rows 52 tall grouped by kind (Fonts, App packages, Web packages, Artwork and sounds): the package name in `mono` 13 `label1`, its version in `caption1` `label3`, and a licence tag capsule (MIT, BSD-3-Clause, Apache-2.0, OFL-1.1, CC0); tapping a row pushes the licence text inside the sheet in `mono` 13/20, `label2`, with the package name as the title and "Copy" in the header. Sources: Flutter `LicenseRegistry.licenses` (which carries the `OFL.txt` files and every package), the web's build-time `licenses.json` (generated from `npm ls --json` plus the fonts' OFL texts), and the art and sound entries of §9.4.2 and §8.7. States: loading (8 row skeletons), no match ("No package matches “{q}”"), error ("Couldn't load the licences" + Try again). Keys: `/` search, arrows, Enter opens, Esc back.
- **Coverage (all of §8.25):** web R26 SG1–SG40, BK1–BK5, MB1–MB7, K1–K51, A5–A9, A17–A24, A107, A112–A118; mobile S28 1–27, S29–S34; the palette and preset pickers become the skin picker.

#### 8.25.15 Circle and privacy (per profile)

The sharing model of §9.3, as grouped rows with plain explanations under each:

- **Share what I'm reading** (master, default off): "Other readers on this server see what this profile starts and finishes. Never your bookmarks, searches, reading time or downloads."
- **Show my reactions** (default on once sharing is on).
- **Accept recommendations** (default on): "Friends can send you series. Off: you won't appear in their Recommend list."
- **Show me in presence** (default off): "Your orb moves to the front of the Circle while you're reading."
- **Let others add me to shared shelves** (default on).
- **Share my streak** (default off).
- **Include 18+ titles in my activity** (only visible when this profile's gate is open; default off): "Even when on, 18+ titles are shown only to readers whose own 18+ setting is on."
- **Hidden from my Circle:** a list of series excluded from everything shared (each row: 36 × 54 cover, title, "Unhide"); series are added from a series' ⋯ menu → "Hide from my Circle"; empty state "Nothing hidden. Hide a series from its ⋯ menu."
- **Clear my activity:** destructive plain button → alert "Remove everything you've shared so far? Your reading stays; your Circle just won't see past activity." + "Keep it" / destructive "Clear" (`DELETE /circle/activity`; toast "Your shared activity was cleared").
- **Preview line** (`footnote` `label2`, typed once at 12 ms per character when a switch changes): "Others see: Yash finished chapter 142 of Omniscient Reader."
- States: loading (6 row skeletons), error (+ Try again), offline ("Sharing settings need a connection"; switches disabled), no profile (the "Choose a profile first" notice).

#### 8.25.16 AI and recaps (per profile)

- **Previously on:** a three-segment control **Off · Ask · Always** (default Ask) with the explainer "Ask: when you come back to a series after a week, we offer a quick recap. Always: the recap opens first. Chapter recaps are offered after 3 days away." (§9.1.3). Stored on the device, per profile, in the shared key `mm.recap` = `{mode: "off" | "ask" | "always", seriesDays: 7, chapterDays: 3, skipSeries: ["source:series", …]}` (web profile-scoped `localStorage`; mobile SharedPreferences `mm.recap.u{user}p{profile}`), the same key Cinematic reads (§15.6). The server stores no UI preferences, so this setting does not follow the profile to other devices, and the caption says so: "Saved on this device."
- **Series you asked not to recap:** a list (the `skipSeries` entries, each shown with its cover and title from the library cache) with "Ask again" per row; empty "You haven't turned recaps off for any series."
- **Clear "Not interested":** "Series you dismissed from AI picks can appear again." → `POST /ai/feedback {signal: "clear"}`, toast "Your AI picks start fresh".
- **AI status line:** the server's availability in one line from `GET /library/suggest/availability` ("AI picks are on · 7 of 10 asks left today", or the reason's long line from §9.1.5).

### 8.26 System status (admin)

- **Layout:** large title "System status" with the eyebrow "Administration"; nav row "Refresh" (spins while refreshing); a **summary banner** tinted by the worst state (ok `success`, warn `warning`, down `danger`, unknown `g600`) with its glyph, headline ("Everything is running", "2 problems need attention") and a bullet list of problems.
- **Cards:** Backend (state capsule Healthy · Warning · Down · Unknown with a live dot that pulses once on each successful 15 s poll: scale 1 → 1.3 → 1 on `tick`; name; version `mono`; "Probe GET /health"); Update checker (Check now secondary; last run + "12 min ago"; next run + "in 40 min"; interval; failed runs in `danger` when above 0; the server error in a `mono` block); Recent checks (up to 8 runs: status tag, trigger, "142 series · 5 new", time, errors); Source health (rows: state glyph, name, id `mono`, "demoted" `warning` tag, "last probe 3 min ago", message, last error in a `mono` block; 30 s poll); footer note "Everything here reads endpoints that already exist; nothing on this page changes the server except Check now."
- **Desktop:** the cards sit in a two-column grid at 1280 px and wider (Backend and Update checker in the first row, Recent checks and Source health below, Source health spanning both columns when it has more than 8 rows), one column below 1280 px, at most 1200 px wide.
- **Health beads (signature):** every health dot on this screen (the backend's live dot and each source's state) is a tiny painted bead (a content twin, §2.4.1: a radial gradient, no backdrop read, because the beads repeat inside scrolling cards): a 10 px sphere lit from inside in its state colour (`success`, `warning`, `danger`, `g600` for unknown) with a 1 px specular highlight at the light angle; the healthy backend bead pulses once per successful poll (scale 1 → 1.3 → 1 on `tick`); a failing or dead source's bead flickers once (opacity 1 → 0.3 → 1 over 120 ms) when a new probe for it lands; a demoted source's bead gets a 1 px `warning` ring. Reduce Motion: colour changes only.
- **Non-admin:** the object lens "Administrators only" / "System status is instance-wide. Ask the account owner to check it." + "Back home".
- **States:** loading (a bar while `/auth/me` resolves, then card skeletons), per-card errors, offline.
- **Keys:** `r` refresh all, `c` check now, arrows through the source-health rows.
- **Coverage:** web R27 AS1–AS10, A100, A108–A111.

### 8.27 For you, Statistics, Circle and Wrapped

These four screens are the new features and are specified in full in §9: For you and Ask (`/library/recommendations`) in §9.1.2, Statistics (`/library/statistics`) in §9.2.1, Wrapped (`/library/statistics/annual/:year`) in §9.2.3, Circle (`/circle`) in §9.3.1, "Previously on" in §9.1.3. Inventory coverage: web R12 RC1–RC11, R13 ST1–ST13, A40–A43; mobile S11 1–20, S12 1–17.

### 8.28 Status screens

- **404** (inside the app frame): the object lens with a question glyph drifting slowly, "Nothing here", "This page doesn't exist. It may have been renamed, or the series it pointed to may have left your library.", primary "Back home", secondary "Open library", and the hint "Press ⌘K to search everything" (desktop).
- **Route error:** two variants: "Something broke" / "This page failed while rendering. Nothing was lost; trying again usually works." and "Can't reach the server" / "The server didn't answer. It may be starting up, or the connection dropped. Your library is untouched."; "Reference {digest}" in a `mono` capsule; "Try again" (tinted) and "Back home". The lens drops in on `lens` with `error` haptic once.
- **Root error** (replaces the document, no fonts, no providers): self-contained HTML and CSS: black background, `system-ui` font stack, a CSS-only droplet lens (a radial-gradient circle with a 1 px rim), "ManhwaManiacs failed to start", "Reloading usually clears it. If it doesn't, check the server or the running build.", buttons "Try again" and "Reload the app".
- **Offline fallback** (`/offline-fallback.html`, served by the service worker when a navigation fails offline): one static file carrying both skins' CSS; a four-line inline script reads the `mm-skin` cookie and sets `data-skin`, so Glass users see the Glass version: the inline SVG mark in a CSS glass lens, a live status capsule ("No connection" `warning` / "Back online" `success`, updated by `online`/`offline` events), "This page needs the server", "Chapters you downloaded are still on this device and open as normal.", buttons "Try again" and "Downloads", and the note "This page is served from your device."
- **Keys:** on every status screen Enter activates the primary action and `mod+k` still opens the palette (except the root error and the offline page, which have no app around them).
- **Coverage:** web S1–S5, E1–E4, G12 (skip link: "Skip to content" `glassThin` capsule that appears top-left on focus).

### 8.29 Global overlays

| Overlay | Glass treatment |
|---|---|
| Command palette | §7.28 |
| Keyboard shortcuts (`?`) | `glassThick` window 560 wide (phone with a keyboard: `large` sheet): "Keyboard shortcuts", intro "Only what works here is listed. Shortcuts pause while you type. Press ? to reopen, Esc to close.", groups with keycaps (secondary combos at 80 %), empty "No shortcuts are active on this screen" |
| New chapters | The global capsule (§7.30); tapping "View" opens Updates |
| App update (web service worker) | Capsule "A new version is ready" + "Reload" (posts `skip-waiting` then reloads) |
| App update (Android APK) | Capsule "Update available · 3.5.1" → a `medium` sheet: installed and available versions, "Download update", notes ("Downloading doesn't install automatically", "Updating from 1.2.x? Uninstall version 1.2 first"), then the install-steps alert with three numbered droplets |
| What's New | Shown once after an update (build number increased) and from About: a `large` sheet "What's new" / "Recent improvements", release cards (`surface1`, radius 20): version capsule in `iris400`, "Latest" tag, "28 Sep · build 57", bullets with droplet markers; loading spinner; "Release notes are unavailable" lens |
| First-run hint | Replaced by onboarding (§8.7) and Home's new-profile state |
| Session ended elsewhere, profile gone | §8.0.9 |
| Open-source licences | §8.25.14 (`?sheet=licenses`) |
| "How it works" (dialogue text extraction) | §9.1.3 (`?sheet=how-it-works`) |
| Bookmark notice | Toast (§7.12) |
| Skip link | "Skip to content", `glassThin` capsule top-left on focus |

Coverage: web G39–G42, CP1–CP12, the shortcuts dialog of web.md §2.9, G12; mobile G8, G9.

---

## 9. The four new features

All four are designed server-first (`stack-decision.md` §2.6): the backend computes AI results, recaps, statistics, streaks, the Circle feed with its per-profile and 18+ filtering, cover palettes and panel boxes; each client only renders. The endpoints are the shared ones `cinematic/DESIGN.md` §9 and §15.5 already define (one backend serves both skins); where Glass needs more, the addition is an extra field or parameter on the same endpoint, listed in §15.5. Every payload is filtered by the active profile and applies the 18+ gate when serving, never when storing. AI is an external API called by the server only; the clients never talk to it, and every AI surface uses the machine light, the thinking orbit and the AI notice of §7.38.

### 9.1 AI home, recommendations and "Previously on"

#### 9.1.1 AI rails on Home

| Rail | Source (`GET /home` section `type`) | Label and `why` |
|---|---|---|
| Because you read {title} (up to 3) | `because` (seeded by recent favourites and completions) | Title "Because you read Solo Leveling" with the machine sparkle; each card's `why` line ("Same regressor revenge arc, sharper art") |
| For you | `picked` | "Picked from what you read" |
| Almost there | `almost_there` (not AI) | "2 chapters left" per card |
| From your Circle | `sent_to_you` + `circle` (not AI; bloom chips) | "Aarav thinks you'd like this" |
| Your genres | `genres` (genre weights from `GET /library/recommendations`) | Chips; each opens For you filtered to that genre (`/library/recommendations?genre=`, §9.1.2) |
| More like this (series detail, caught-up end card) | `GET /ai/similar?source&series` | "More like {title}" |
| Start here (new profiles) | `first_picks` / `popular` | "Start here" |

- **Cards:** the world title card (§7.7) in its two variants: **available** (opens the series on one of the reader's sources; a source chip, and a source picker menu when several have it) and **info-only** (dashed border, "Not on your sources", actions "Search my sources" and "Read on {site}"). AI cards carry the `machineRim` and the sparkle before the `why`.
- **In-session re-rank:** after the reader opens a series from a rail, the next visit to Home moves rails whose seed shares its top genre up by one position (client-side, per session), animated on `snappy` only for rails outside the viewport, so nothing moves under the finger.
- **Not interested:** on AI cards only: throw the lifted card sideways (projection past a side edge or |vx| ≥ 1200 px/s), or ⋯ → "Not interested", or `Delete` on a focused card. The card flies off on `dismiss` with its velocity and spins up to 12° in the throw direction; the rail closes the gap on `snappy`; toast "We'll show fewer like this · Undo". `POST /ai/feedback {anilist_id | source_id + series_key, signal: "not_interested"}` (Undo sends `signal: "undo"`); the server drops the item from future sections for this profile. Settings → AI and recaps → "Clear 'Not interested'" resets it (§8.25.16).
- **Liked pick:** the ⋯ menu of an AI card has "More like this one" (sends `signal: "liked_pick"` and opens More like this for it).
- **Loading:** AI rails show their header with a 28 px thinking orbit beside the title and 4 skeleton cards whose sheen moves at half speed (2,800 ms), because a cold world-recommendations call makes many public-API requests; they never block the rest of Home.
- **States:** ready, stale ("Picked 3 days ago" stamp), partial (a failed AI rail is omitted), unavailable (the AI notice with the short line and the non-AI rail beside it), offline (AI rails omitted).

#### 9.1.2 For you and Ask (`/library/recommendations`)

- **Entry points:** Home "See all" on AI rails, the Search idle "Ask" card and the `ask` scope, You → For you, the sidebar (under Home as "For you"), the command palette ("Ask for something to read"), the Home ⋯ menu.
- **Layout, phone:** large title "What do you feel like?" (letter reveal); the **Ask box**: a content-layer text area (3 rows, grows to 6, 3 to 600 characters, placeholder "A revenge story with a competent lead, no harem"), whose 0.5 px rim turns `machineRim` while focused or thinking; three example chips beneath ("A murim regressor who comes back stronger", "Magic academy, but the lead is already strong", "Something slow and political, not a power fantasy"; tap fills and asks); the tinted **Ask** button (the screen's lit action, iris); an "Only my sources" switch (on: `POST /library/suggest`; off: `POST /library/world/suggest`); a **quota meter**: a tiny liquid capsule "7 of 10 asks left today" (shown when 10 or fewer remain, `warning` at 3 or fewer). Below: the ask's answers, then "For you" and the "Because you read" sections as vertical card lists (phone) or 2 to 3 column grids (desktop, answers in a two-column list, the box max 720 px wide).
- **Asking:** Enter (Shift+Enter for a newline) or the button. The button shows its loading dots; under the box the 64 px **thinking orbit** appears with its honest phase lines (§7.38: "Reading your library" → "Asking for ideas" → "Checking which of your sources have them" → "Still working. This can take up to a minute."), and a "Cancel" plain button (aborts the request). The rest of the screen stays usable.
- **Signature moment:** results are **dealt**: each answer card flies out of the Ask button's position along a short arc into its slot (the wave's cause is the button), landing on `snappy` with 40 ms spacing, the `why` line typing in underneath at 12 ms per character (quick, not the 50 ms headline pace). Answer cards are wide (poster 96 × 144 left; right: title, meta, the `why` in `callout` with the sparkle, the availability chip, actions Open / Search my sources / Read on {site}); "Show as grid" switches to posters; "Ask again" (secondary) under the list.
- **Taste as context:** the server reads the profile's taste (§8.7) with each ask unless the "Use my taste" switch under the box is off (sent as `use_taste: false`).
- **Filtered to a genre** (`?genre=`, from a Home genre chip or a Statistics radar label): a dismissible chip "Fantasy ×" sits under the large title; the For you and Because you read sections come from `GET /library/world/recommendations?genre=` (the parameter Glass adds, §15.5), the Ask box stays as it is, and clearing the chip drops the parameter. Empty: "No picks in Fantasy yet" + "Clear the filter".
- **States:** available idle; thinking; results (up to 12); **no matches** (`ai_no_matches`: "Nothing matched that. Try describing it differently." with the prompt kept for editing); **empty shelf** (`suggest_shelf_empty`: "Read or follow a few series first. Picks here start from what you read." + Browse sources); **not configured**, **budget exhausted**, **rate limited**, **offline**, **upstream error** (the Ask box is replaced by the AI notice with the reason's long line, §9.1.5; budget exhausted adds the reset time and a live countdown; rate limited counts down on the button; the sections below still work); **world catalogue unreachable** (`unavailable_reason`: "The worldwide catalogue isn't reachable, so these picks come from a saved copy."); **timeout** after 40 s ("That took too long. Try again."); loading sections (6 skeleton cards).
- **Keys:** `/` focuses the box, Enter asks, Esc cancels a running ask, `alt+1` to `alt+3` fill an example, `j`/`k` or arrows through answers, `Delete` = Not interested on a focused AI card.
- **Coverage:** web R12 RC1–RC11, A41–A43; mobile S11 1–20; capabilities §9.

#### 9.1.3 "Previously on" recaps

**The setting** (Settings → AI and recaps, per profile, §8.25.16): **Off · Ask (default) · Always**.

- **Series recap threshold: 7 days.** With **Ask**, tapping Continue (anywhere: Home, the continue stack, series detail, the bottom accessory) on a series last read 7 or more days ago blooms (`morph`) a T4 **offer sheet** out of the Continue button, at the `medium` detent on phones and as a 420 px popover on desktop: "It's been 3 weeks" (the gap in words: days under 14, weeks under 9, months after) / "Want a quick recap of what happened?" + the tinted "Show recap" + plain "Just continue" + a switch **"Don't ask for this series"** (stored per profile on the device in `mm.recap.skipSeries`, §8.25.16). With **Always**, Continue opens the recap first. With **Off**, recaps open only from the explicit entries below.
- **Chapter recap threshold: 3 days.** Opening the next chapter after 3 or more days away (and less than the series threshold, or when the series recap was declined) shows a `glassThin` pill at the top-centre of the reader, **"Previously · 20 s"** (machine sparkle, `caption1` 600), for 6 s; tapping it opens the compact recap sheet; swiping it up dismisses it. Off under the Off setting.
- **Explicit entries:** swipe the Continue stack left on Home or Library to reveal a "Previously on" pill; series detail ⋯ and the "Previously on" row above the chapters when the profile has progress; the Home spotlight's "Previously on" candidate (paused 7 days or more); long-press any Continue button → "Recap first"; `p` on a focused series; the reader's ⋯ → "Previously on".

**The recap deck** (route `recap`, a sheet `medium` → `large` over the series detail; desktop a 560 px window; the field takes the series palette):

- **Header:** the eyebrow "PREVIOUSLY ON" in `caption1` +0.18 em `machine`, and the heading "Previously on Solo Leveling" with the **typing reveal** (§10.2).
- **The deck:** four cards stacked in depth (the front card 88 % of the sheet width, radius 26, `surface1` with a 0.5 px `machineRim`; the next two visible above it, each 8 px higher, at scale 0.94 and 0.89 and 60 % / 40 % brightness), one section each:
  1. **Where you left off** (chapter and page, 2 to 3 sentences),
  2. **What happened** (4 to 6 short sentences, each a bullet with a `droplet` marker),
  3. **Who's who** (up to 6 characters as rows: an orb in the character's speaker hue from the book's cast for novels (§2.1.5), or `g700` for manga names the recap produced, name `headline`, a one-line note),
  4. **Open threads** (2 to 3 questions the story has raised).
  A row of four progress capsules sits above the deck. **Swipe up** (or tap the right half, `→`, Space) lifts the front card toward you and away (Deck lift-off on `smooth`), revealing the next; **swipe down** (or the left half, `←`) brings it back. With a screen reader, the four cards are one scrolling list with headings.
- **Streaming:** the text streams from the server (`GET /ai/recap` SSE, §9.1.6); section titles arrive first and the deck appears with skeleton lines that fill from the top; words fade in over 120 ms each as they arrive (no movement). The 50 ms typing is reserved for the heading.
- **Footer (the spoiler guard):** `footnote` `label3` with the machine sparkle: "Written by {model} from chapters 120–141. Covers up to chapter 141. Nothing after where you stopped." (`model`, `range` and `covered_through` from the stream's trailer).
- **Actions** (sticky at the bottom on phones): the tinted "Continue · Ch 142, p. 12" (dives into the reader), the secondary "Start from Ch 138 instead" (the first chapter of the covered range's last third), and a refresh icon in the header ("Write it again", costs one ask; disabled with the reason when the budget is spent).
- **Compact recap sheet** (the chapter recap from the reader pill): `medium`, one card "Last time" (3 to 4 sentences) + "Continue"; same footer.
- **Leaving during generation:** closing the sheet while the recap is being written keeps the request alive for up to 60 s; when it lands, a toast appears anywhere in the app: "Recap for Solo Leveling is ready" + "Open" (`recap.ready` haptic, `add` sound).
- **States:** **writing** (the deck with skeleton lines + the 64 px thinking orbit + "Writing your recap"); **ready** (cached: instant, with "Written 2 d ago" in the footer); **no source text** (manga without extracted dialogue for the covered chapters: the object lens `bubble-search` with a machine-light pool, "No recap yet" / "Recaps are written from chapter text. Extract text from downloaded chapters, or just continue." + tinted "Continue" + plain "How it works" (the How it works sheet below; on phones with downloads also "Extract text")); **not enough read** ("Read a couple of chapters first; there's nothing to recap yet." + Continue); **AI unavailable** (the AI notice with the long line + Continue; the recap is skipped); **offline** (a cached recap opens with "Saved recap from 2 d ago"; otherwise "Recaps need a connection." + Continue); **error** ("Couldn't write a recap." + Try again + Continue); **first chapter** (no recap entry is shown).
- **Keys:** Space / `→` next card, `←` previous, Enter continue reading, `s` skip to the reader, `r` write it again, Esc closes.
- **Reduce Motion:** the heading appears at once; cards cross-fade instead of lifting; words appear without the fade.
- **How it works** (`?sheet=how-it-works`, a `medium` sheet; desktop a 560 px window; also linked from Dialogue search's hint row, §8.23): title "How recaps and dialogue search read manga", three rows, each a 30 px icon tile (§7.17) and two lines: (1) `cloud-arrow-down` "Download the chapter" / "Text is read from pages saved on this phone."; (2) `bubble-search` "Extract text" / "Your phone reads the speech bubbles and sends only the words to your server. On the web, extraction isn't available." (web variant: "Extract text on the phone app"); (3) `sparkle` in `machine` "Recaps and dialogue search use it" / "Recaps are written from these words, and you can search what characters said." Under the rows: the primary "Open downloads" (phones) and a plain "Close". No states: it is static copy.

#### 9.1.4 More like this

A rail at the bottom of series detail and the book page, and on the caught-up end card: up to 10 world cards from `GET /ai/similar?source&series`, each with a `why` line. Loading: rail skeleton with the 28 px orbit. Empty: the rail is omitted. AI unavailable: the rail falls back to series sharing two or more genres, computed on the server by `GET /ai/similar?source&series&fallback=genres` from the genres it already caches for series (`SourceSeries.genres` from catalogue pages and series fetches, and the library's followed series), restricted to the profile's sources and 18+ gated on serve; the items carry `why: null` and `basis: "genres"`, and the rail is captioned "Same genres" instead of a `why`, without the sparkle. With fewer than 3 such series the rail is omitted.

#### 9.1.5 AI states and one voice for "unavailable"

Every AI surface (rails, For you, recaps, More like this, onboarding step 6) is in one of the states of §7.38 and, when unavailable, says exactly one of these lines (short for rails and badges, long for For you, recaps and More like this):

| Reason | Short | Long |
|---|---|---|
| `not_configured` | "AI picks are off on this server" | "AI isn't set up on this server. Everything else works as usual." (admins also see "Add an AI API key on the server to turn it on.") |
| `budget_exhausted` | "Today's AI asks are used up" | "You've used today's AI asks. They reset at midnight UTC." |
| `rate_limited` | "AI is busy, retrying in {n} s" | "Too many requests in a row. Trying again in {n} s." |
| offline | "AI picks need a connection" | "You're offline. AI picks come back when you reconnect." |
| upstream error | "AI picks didn't load" | "The AI service didn't answer. Try again in a moment." |

The copy lives once in `frontend/src/skins/glass/copy/ai.ts` and `mobile/lib/skins/glass/copy/ai.dart`, keyed by the server's `reason`.

#### 9.1.6 Backend used (shared with Cinematic)

| Endpoint | Glass use |
|---|---|
| `GET /home` | Home sections (§8.8); Glass reads the same section types and adds nothing |
| `GET /ai/similar?source&series` | More like this; Glass adds `fallback=genres` (§9.1.4) |
| `GET /ai/recap?source&series&to` (SSE) | Recaps. Glass adds `shape=deck` and `scope=series\|chapter` (default `shape=prose`, Cinematic's): with `shape=deck` the stream sends `event: section` `{kind: "left_off" \| "happened" \| "cast" \| "threads" \| "last_time", title}`, then `event: delta` `{kind, text}` chunks, then `event: done` `{range: [from, to], covered_through, cast: [{name, note}], sourced_from: "ocr" \| "text", model, generated_at, available, reason}`; `event: phase` `{phase: "writing"}` may arrive first. Cached per (series, range, shape, scope); 18+ gated on serve |
| `POST /ai/feedback` | `not_interested`, `undo`, `liked_pick`, and Glass's `clear` (reset every "Not interested" for the profile) |
| `PUT /profiles/{id}/taste`, `POST /library/taste/seed` | Onboarding (§8.7) |
| `POST /library/world/suggest`, `POST /library/suggest`, `GET /library/suggest/availability`, `GET /library/world/recommendations` (Glass adds `genre=`, §9.1.2), `GET /library/recommendations` | For you and Ask (existing). These return plain JSON, so the Ask's phase lines run on the timers of §7.38; only `GET /ai/recap` reports phases |

### 9.2 Reading stats, streaks and Wrapped

#### 9.2.1 Statistics ("Your reading", `/library/statistics`)

- **Entry points:** the streak chip in the Home greeting, the Home "This week" card, the You tab's Reading card, the sidebar "Stats", `g t`, the palette.
- **Layout, phone:** large title "Your reading"; range segmented **7 d · 30 d · 90 d · Year** (remembered per profile on the device in `mm.stats.range`; Year is the last 365 days, `days=365`); a mode note when novels are on ("Streak, totals and the clock count everything; the lists below follow Manga or Novels").
  - **Hero:** the **streak flame** (§9.2.2) at 96 px with "12-day streak" `title1`, "Longest: 31 days" and "Read on 18 of the last 30 days" `footnote`, a 14-dot row of the last two weeks (filled `streak` = read, `fill3` = not; each dot's date and pages in its tooltip and accessible name), "Last read 2 h ago", and around the flame the **daily goal ring** (when a goal is set) filling with today's minutes ("8 of 10 min today"); "Read today to keep it" when today is empty; the unlit wick and "Read today to start a streak" when the streak is 0.
  - **Totals:** four stat cards (Time read, Chapters, Pages, Series) with "all time" captions, the delta against the previous window ("+2 h 10 m"), and 7-point sparklines.
  - **Chapters per day:** a bar chart (§7.39) with minutes as the second-axis line; **drag across the chart to scrub days**: the readout capsule (a content twin, §7.39) follows the finger ("Mon 1 Sep · 42 pages · 3 chapters · 25 min") with a `select` tick per day; the best day marked with a small `streakCore` dot and named beside the title ("Best day: Sat 19 Sep · 120 pages").
  - **Year heatmap** (Year range): 53 × 7 cells, 10 px squares with 2 px gaps, `heat0` … `heat4` by pages read; today outlined 1 px `aurora1`; months labelled; drag or arrows scrub days as above.
  - **When you read:** a 24-hour **clock** (a radial histogram: 24 bars around a 160 px circle, length by pages read) with the peak labelled ("You read most around 23:00") and a word for the band ("Night owl" 22–05, "Early reader" 05–09, "Daytime reader" 09–17, "Evening reader" 17–22).
  - **Genre radar:** 6 to 8 axes from the genre weights; the polygon springs out from the centre on `celebrate`; tapping a label opens For you filtered to that genre (`/library/recommendations?genre=`, §9.1.2).
  - **Where you read:** source rows with share bars; **Most read:** cover rows ("12 h 40 min · 88 chapters"); **Recent sessions:** rows linking to the reader at that chapter; **Your library:** per-status bars in the status colours.
  - **Wrapped entry:** from 1 December (and "Your year so far" after 30 days of history, any time): a tall `surface1` card with the year in `display` and a fanned preview of three Wrapped cards; tap → Wrapped; a year menu on the card lists earlier years that have data.
  - **Footnotes:** "Days start at UTC+05:30 · Each session counts up to 30 min of idle · Recording since 27 Jul 2026".
  - **Share** (nav row): shares the current range as a card (§9.2.4).
- **Every chart** follows §7.39: a one-sentence summary above it, **"Show as table"**, keyboard focus per bar or cell with a live readout, zero shown as "0", pace figures only after 2 minutes of samples.
- **Desktop:** a two-column dashboard: hero and totals across the top; chapters per day (8 columns) + the clock (4); the heatmap full width; the radar (4) + most read (8); sources + sessions (6 + 6); the library card; the Wrapped card.
- **Daily goal:** ⋯ → "Daily goal": Off · 5 · 10 · 15 · 20 · 30 · 45 · 60 min (a menu, default Off); stored per profile (`reading_profiles.daily_goal_minutes`, via `PATCH /profiles/{id}`).
- **States:** loading (hero, 4 cards, a chart block, two panels as skeletons); offline (the last cached statistics, dimmed, with "Last updated 2 h ago"); error (+ Try again); **empty** ("No reading recorded yet" + Browse sources); **followed but never read** ("Nothing read on this profile yet" + the Your library card); a range with no activity ("Nothing read in the last 7 days" inside the chart).
- **Keys:** `[`/`]` change range, arrows scrub the focused chart, `t` toggles the focused chart's table, `s` share, `shift+g` sets the daily goal, `w` opens Wrapped.
- **Data:** `GET /library/statistics?days={7|30|90|365}&tz_offset_minutes=` (existing); the streak object carries `current_days`, `longest_days`, `at_risk` and `milestones_seen` (§15.5). The Year range's heatmap shows the rolling 365 days; the `?year=` query picks the calendar year the Wrapped card on this screen opens (default the current year; the card's year menu writes it).
- **Coverage:** web R13 ST1–ST13, A40; mobile S12 1–17; capabilities §10.

#### 9.2.2 The streak flame

- **Construction:** three nested teardrop paths: outer `streak` `#FF8A3D`, middle `#FFB547`, core `streakCore` `#FFD166`, each a cubic Bézier teardrop whose **tip is a physics point**: a spring (`drift`) pulls it to rest above the base, and it is pushed by (a) device tilt (the tip leans opposite to gravity's change, up to 18 % of the flame height) and (b) scroll acceleration on the containing view (the flame leans back when the page is flicked, like a candle carried quickly): the lean is `0.004 × a` px, where `a` is the scroll acceleration in px/s² (sampled per frame from the scroll position), opposite to the acceleration, and the two pushes together are capped at 18 % of the flame height. A flicker offsets the tip by value noise (amplitude 2 % of the height, 5 Hz), frozen under Reduce Motion.
- **Sizes:** 16 (chip, profile orb badge), 44 (You card), 96 (Statistics hero), 220 (Wrapped).
- **States:**

| State | Presentation |
|---|---|
| Alive, read today | Full colour, flicker on; the count beside it in `numeral` or `headline` |
| Alive, not yet today (before 20:00 local) | Colours at 55 %, no core, a slower flicker; "Read today to keep your 12-day streak" wherever the flame is 44 px or larger |
| **At risk** (after 20:00 local, streak ≥ 2 days, nothing read today) | The flame shrinks to 0.8 × and loses its core; the line "Read one chapter to keep your 12-day streak" (in `label1`, never red); Home's greeting subline switches to it (§8.8); no push notification |
| Broken or none | An unlit wick (a 2 px `g500` stroke) and "Longest: 31 days. Start a new one today." |

- **Streak +1** (the first chapter finished on a new day): the flame **flares**: scale 1 → 1.3 → 1 on `celebrate`, 8 ember particles rise from the tip with an upward acceleration of 300 px/s² and random lateral drift, fading over 900 ms; `streak.extend` haptic (`ignite`), `shimmer` sound; the Home chip shows "+1" briefly (the Plus one move, §4.10). It fires wherever the chapter was finished (the reader shows a small flame toast "13-day streak").
- **What triggers it (no local inference).** The client never guesses the streak. `POST /reader/progress` answers with `streak {current_days, extended_today}` and `today_seconds` (Glass's addition, §15.5). The flare fires once, on the first response in which `extended_today` turns from `false` to `true` (the client remembers the last value per profile per local day, so a second device that also reports the chapter sees `extended_today` already `true` and stays quiet); the goal ring refreshes from `today_seconds` after every progress save, and `goal.met` fires once on the save that carries `today_seconds` across the goal. Offline saves queue in the outbox; their flare and ring update happen when the queued save is answered, never before.
- **New record** (the current streak passes the longest): on the +1 that sets it, 6 **record sparks** in `streakCore` rise 40 px from the tip over 900 ms after the flare, and the caption reads "New longest streak: 32 days".
- **Milestones** (7, 30, 100 and 365 days): after the flare, a toast "30 days in a row" with the 20 px flame and a "Share" action (opens the share card with the Streak template, §9.2.4); `streak.milestone` haptic (`shimmer` twice). Each milestone shows once per profile across devices (`POST /library/statistics/milestones/{days}/seen`, the endpoint Cinematic defined).
- **Daily goal ring on the profile orb:** when a goal is set, the profile orb in the nav row, the dock's You tab and the sidebar's profile capsule carry a 2 px ring (at 3 px from the orb) that fills clockwise from 12 o'clock with today's minutes toward the goal, in `streak` at 80 %; it closes and fills solid for 600 ms when the goal is met (`goal.met`: `success`, then `shimmer`), then stays closed in `streakCore` for the rest of the day. The ring's accessible name: "Today: 8 of 10 minutes".
- Reduce Motion: no flicker, lean, flare, embers or sparks; counts change and toasts appear.

#### 9.2.3 Wrapped (`/library/statistics/annual/:year`)

- **Entry points:** You → "Your 2026 in chapters" (1 December to 31 January), Statistics Year range → "Play your year" and the Wrapped card, a one-time Home spotlight card in December; past years remain reachable from the Wrapped card's year menu on Statistics while data exists.
- **Data:** `GET /library/annual?year=` (the endpoint Cinematic defined; Glass also reads its `busiest_day` and `firsts_lasts` fields, §15.5). It aggregates the **calendar year** (1 January to 31 December in the profile's timezone offset); the current year is the year so far, and its cover reads "Your {year} so far" until 1 December, then "Your {year} in chapters".
- **Format:** a takeover story (a `NoTransitionPage` on Flutter and a route with no view transition on the web: there is no back swipe, it closes by swipe down, its close button or Esc) of up to 12 full-screen 9:16 cards in a `glassMonolith` frame (phone: the screen minus 16 px margins; desktop: a 432 × 768 card centred on the year's ambient field); progress capsules along the top (one per card, filling over 6 s each); tap the right two-thirds → next, the left third → previous; **hold** pauses (the capsule stops filling); **swipe down** closes (projection past 120 px; the story shrinks back into its entry card on `zoom`); horizontal swipes move between cards with the **story stack** (the next card waits beneath at scale 0.94 and 60 % brightness, rising on `page` as the top card leaves along the swipe with its velocity); `annual.page` per card. Each card has its own ambient field from its hero cover palette.
- **Cards:**
  1. **Cover:** "Your 2026 in chapters" (**typing reveal**) over the field of the year's top covers; the profile orb.
  2. **Time:** "You read for 212 hours" (the `display` numeral counting up on `drift` from 0, digits in Google Sans Code so they don't jitter), "That's 8 full days."
  3. **Volume:** chapters and pages, with a column of tiny page glyphs that pour down and pile up (each glyph a physics body falling with 2,400 px/s² gravity and settling with restitution 0.3; 200 glyphs max; Reduce Motion shows the pile at rest), and a 12-bar chapters-per-month strip.
  4. **Top five series:** a podium: covers drop in from above with gravity and bounce into their places (1st last, with a `celebrate` land and `success`), titles beneath.
  5. **Genres:** the radar polygon expanding, the top genre named large ("Mostly murim and regression").
  6. **When:** the 24-hour clock, "You're a night reader: most of it after 22:00."
  7. **Streak:** the 220 px flame with the longest streak and its dates; the flame flares once.
  8. **Busiest day:** the date large, "42 chapters in one day", and that day's series as small covers fanned beneath.
  9. **Firsts and lasts:** the first series of the year and the most recent one, side by side: "From *Tower of God* in January to *Lookism* now."
  10. **Top source:** its logo in a glass lens, "Most of it came from MangaSource."
  11. **Together** (only when this profile shares with the Circle and a friend shared a series with it): "You and Aarav both read Omniscient Reader," both orbs with bloom rings.
  12. **Summary:** a composed poster: top 3 covers, totals, streak, genre words, and the **Export** button.
- **Card layout.** Every card is laid out in one **360 × 640 logical frame** (9:16), scaled uniformly to the frame on screen (phone: the screen minus 16 px margins; desktop: 432 × 768, ×1.2) and to the share canvas (Story: ×3, §9.2.4), so a card and its share side are the same composition. Fixed slots in the frame: progress capsules y 12–16 (x 16–344); the accessibility buttons row y 24–68 (only with a screen reader or keyboard); **safe area** x 24–336; **eyebrow** at y 72–88 (`caption1` uppercase +0.18 em, `label2`); **headline** y 96–200 (`title1` 28/34, at most 3 lines); **figure** y 216–520 (312 × 304); **footnote** y 528–552 (`footnote` `label2`, at most 2 lines); **Export** capsule x 232–336, y 576–620. Big numbers use `type.wrappedNumeral` (88/88, Google Sans Flex `wght` 720, `ROND` 100, tracking −0.03 em; digits in Google Sans Code inside the count-up so they don't jitter).

  | Card | Eyebrow | Headline | Figure (y 216–520) | Footnote |
  |---|---|---|---|---|
  | 1 Cover | "2026" | "Your 2026 in chapters" (`display` 44/48, typing reveal; the headline slot runs to y 240 on this card) | the year's top 3 covers 112 × 168, fanned −6° / 0° / 6° with 30 % overlap, centred at y 272–440; the profile orb 56 centred at y 492 | the profile name |
  | 2 Time | "TIME" | "You read for" (`title2`) | the numeral "212" centred at y 236–324, "hours" `title2` at y 332–360, "That's 8 full days." `title3` at y 400–425 | "Counted while a chapter was open." |
  | 3 Volume | "VOLUME" | "1,204 chapters · 38,410 pages" | the 12-bar chapters-per-month strip at y 216–296 (bars 20 wide, 6 gap, `iris500`); the page-glyph pile in y 320–520 | "Busiest month: March" |
  | 4 Top five | "YOUR TOP FIVE" | the #1 title | podium: #1 104 × 156 at x 128–232, y 236–392 on a 16 px `surface2` step; #2 and #3 88 × 132 at x 28–116 and x 244–332, y 260–392 on 8 px steps; #4 and #5 as two 44 px rows (32 × 48 cover + title `footnote`) at y 424–520 | "{hours} with {#1}" |
  | 5 Genres | "GENRES" | "Mostly murim and regression" | the radar, 280 × 280, centred at y 228–508 | the top three genres with their share |
  | 6 When | "WHEN" | "You're a night reader" | the 24-hour clock, 240 px, centred at y 248–488 | "Most of it after 22:00." |
  | 7 Streak | "STREAK" | "31 days in a row" | the 220 px flame centred at y 258–478 | "From 3 Aug to 2 Sep" |
  | 8 Busiest day | "BUSIEST DAY" | "Saturday 14 March" | the numeral "42" at y 224–312, "chapters in one day" `title3` at y 320–345, that day's series fanned (up to 5, 64 × 96, −12° to 12°) at y 392–488 | none |
  | 9 Firsts and lasts | "FIRSTS AND LASTS" | "From *Tower of God* to *Lookism*" | two covers 128 × 192 at x 40–168 and x 192–320, y 236–428, with "January" and "Now" `caption1` under them at y 440 | none |
  | 10 Top source | "WHERE IT CAME FROM" | "Most of it came from MangaSource" | the source logo 64 px in a 96 px T2 lens centred at y 264–360 (a takeover card does not scroll, so this one lens is glass; on the share side it is flattened); the top three sources as share bars at y 408–516 | none |
  | 11 Together | "TOGETHER" | "You and Aarav both read *Omniscient Reader*" | both orbs 72 px with bloom rings, overlapping 16 px, centred at y 248–320; the shared cover 96 × 144 centred at y 352–496 | none |
  | 12 Summary | "2026" | "Your year" | top 3 covers 88 × 132 in a row at y 216–348 (12 px gaps); a 2 × 2 grid of totals (hours, chapters, pages, longest streak: values `title1` 28, labels `caption1`) at y 364–484; the genre words `footnote` at y 496–520 | the Export capsule reads "Share your year" |

- Every card has an **Export** button (a `glassThin` capsule, bottom-right) that flips it to its share side (§9.2.4).
- **Sound:** when UI sounds are on, each card change plays `tick`, the podium plays `add`, the summary plays `shimmer`.
- **Accessibility:** each card is a region with a heading and its whole text readable at once; visible previous, pause and next buttons (44 px `glassThin`) appear under the progress capsules whenever a screen reader or a keyboard is in use, and auto-advance stops while a screen reader is on.
- **States:** loading (the cover card with the 64 px liquid ring spinner and "Putting your year together"), not enough data ("Not enough reading this year for a recap yet. Come back after a few chapters." and "5 days recorded so far"), offline (the last generated Wrapped is cached per profile and plays offline; otherwise "Wrapped needs a connection"), error (+ Try again).
- **Keys:** `←`/`→` cards, Space pause, `e` export (flip), `1` / `2` Story or Post on the share side, Esc flips back, then closes.

#### 9.2.4 Share cards (image export)

- **Formats:** **Story** 1080 × 1920 and **Post** 1080 × 1350 PNG. Sources: any Wrapped card, the Statistics range summary, the streak (and a milestone), a single stat card.
- **Flow (lift and flip):** Export (Wrapped) or Share (Statistics) → the card **lifts** (`share.lift`: scale 1 → 0.92 with a deep shadow `0 40px 96px rgba(0,0,0,0.66)`) and **flips** (`rotateY` 0 → 180° on `smooth`, perspective 1200 px; `share.flip` haptic, `flip` sound) to its **share side**: the same card composed for export with no UI chrome. Under it, a `glassThick` strip holds **Story · Post** tabs (the card's aspect morphs between 9:16 and 4:5 on `smooth`), a "Show my profile name" switch (default off), and the buttons **Share** (tinted), **Save image** (phones, through the share sheet's own Save), **Download** (web), and **Copy image** (web, `navigator.clipboard.write([new ClipboardItem({ "image/png": blobPromise })])`, toast "Image copied"; hidden when `ClipboardItem` is unsupported). The close glyph, tapping the card or Esc flips it back.
- **Design (the share side):** black, three soft colour blobs from the top covers (drawn as radial gradients, no blur filter), the big numeral in `display` Google Sans Flex, one line of context, the top cover when relevant (radius 28), the single-line wordmark and "ManhwaManiacs · 2026" in `mono` 24 at the foot, and the optional profile name.
- **Coordinates.** **Story (1080 × 1920)** is the card's 360 × 640 frame (§9.2.3) at ×3, minus the progress capsules, the buttons and the Export capsule: margins 72 px; eyebrow y 216–264 (36 px caps); headline y 288–600; figure y 648–1560 (a stat or streak share puts its numeral box at y 648–968, 264 px type, and its one context line at y 1000–1066, 56 px); a cover, when the card has one, is 360 × 540 at x 360, y 1000–1540 (radius 28); footnote y 1584–1656; **foot**: the single-line wordmark (48 px cap height, Frost `#F5F7FA`) centred with its baseline at y 1760, "ManhwaManiacs · 2026" in `mono` 24 `label2` centred at baseline y 1816, and the optional profile name in `caption1` at 36 px, baseline y 1864. **Post (1080 × 1350)** uses a 360 × 450 frame at ×3: margins 72 px; eyebrow y 144–192; headline y 208–480 (2 lines at most); figure y 512–1080, with the card's figure scaled uniformly to fit that box and centred (a cover becomes 320 × 480 at x 380, y 560–1040); foot: wordmark baseline y 1176, `mono` line baseline y 1224, profile name baseline y 1268. Statistics, streak, milestone and single-stat shares use card 2's layout (eyebrow, numeral, context line, figure). **Mature series and covers are never drawn on a share card**, whatever the gate says; the next eligible series takes the place.
- **Rendering:** web draws the card on a `<canvas>` (fonts awaited with `document.fonts.load('600 64px "Google Sans Flex"')` after `document.fonts.ready`; covers are same-origin through the API proxy, so the canvas is not tainted) → `canvas.toBlob("image/png")` → `navigator.share({ files: [file] })` when `navigator.canShare({ files })` is true, otherwise a download through an object URL. Flutter renders the share side offstage inside a `RepaintBoundary` at 360 logical px wide, `toImage(pixelRatio: 3)` (1080 × 1920 or 1080 × 1350), encodes PNG, and shares with `share_plus` 13.3.0 (`SharePlus.instance.share(ShareParams(files: [XFile.fromData(bytes, mimeType: "image/png", name: "manhwamaniacs-2026.png")]))`); `share.export` haptic on render.
- **States:** rendering (the Share button's loading dots), shared (toast "Shared"), saved ("Saved to Photos" / "Image downloaded"), copied, cancelled (silent), failed (toast "Couldn't make the image. Try again."), copy denied (the clipboard write was refused: toast "Your browser didn't allow copying the image. Use Download instead.").
- **Reduce Motion:** the two sides cross-fade over 200 ms instead of flipping.

### 9.3 Social for 2–3 users: the Circle

**Model and privacy.** The Circle is everyone else on this server who shares: the other accounts' profiles and the other profiles on the same account. Each profile is a separate person in it ("Aarav · Night reads"). Sharing is **opt-in per profile and off by default**, and nothing is shared retroactively: sharing starts the moment a switch turns on. The switches (Settings → Circle and privacy, §8.25.15) are stored with `PATCH /profiles/{id}/sharing` (the endpoint Cinematic defined, with Glass's two extra switches):

| Switch | Default | Effect |
|---|---|---|
| Share what I'm reading (`share_activity`, the master) | off | Starts, finishes, follows, reactions and shared collections appear in others' feeds |
| Show my reactions (`show_reactions`) | on | Reactions appear on chapters for others |
| Accept recommendations (`accept_recommendations`) | on | Others can send this profile letters; off hides it from the Recommend list |
| Show me in presence (`show_presence`, Glass addition, enforced by the server for both skins) | off | This profile's orb moves forward in others' presence arc while reading. **The server** sends this member's `now` on `GET /circle/members` as `null` unless the switch is on, so no skin can show a "reading now" the member did not allow (Cinematic's `now` follows the same rule, §15.6) |
| Let others add me to shared shelves (`allow_shelf_invites`) | on | Others can share collections with this profile |
| Share my streak (`share_streak`, Glass addition) | off | The flame and count appear on this profile's orb in others' Circle |
| Include 18+ titles in my activity (`share_mature`) | off, offered only when this profile's gate is open | Mature items are shared, and even then served only to viewers whose own gate is open |
| Hidden from my Circle (`excluded_series`) | empty | Series excluded from everything shared (added from a series' ⋯ → "Hide from my Circle"; the list with "Unhide" lives in Settings) |

Isolation rules, served by the backend: only activity from sharing profiles exists in any feed; turning sharing off removes the profile's activity from others' feeds; a mature item is shown only when the sharer allowed 18+ sharing **and** the viewing profile's gate is open, otherwise it is absent (no placeholder, no count, no "hidden" row); bookmarks, searches, reading time and downloads are never shared. "Clear my activity" (`DELETE /circle/activity`) removes everything this profile shared so far. **Spoiler guard:** on a chapter the viewer has not finished, other people's reactions show only the reactor's orb and "reacted to Ch 212" (never the glyph or the per-kind counts); when the viewer finishes the chapter they unseal (the glyphs fade in 160 ms, 40 ms apart). The rule is applied by the client from the viewer's own progress, so it also works offline; the viewer's own reaction is never guarded.

#### 9.3.1 Circle (`/circle`)

- **Entry points:** the sidebar "Circle" item, the You tab's Circle card, `g c`, the Home "From your Circle" rail's "See all", friend orbs anywhere, and a bloom dot on the You tab when a letter arrives.
- **Layout, phone:** large title "Circle" over the bloom ambient field. Top: the **presence arc**: each member's 56 px orb on a shallow arc (the arc's chord spans the screen width minus 40 px, 24 px sagitta), nearer to the viewer (larger, up to 64 px, brighter, lower on the arc) the more recently active: **reading now** (read within 15 minutes and `show_presence` on) → the orb drifts forward to the front of the arc on `drift` and wears a breathing `bloom` ring (2 px at 3 px offset, opacity 0.5 ↔ 1 over 2.4 s) with "Reading *Omniscient Reader*" under the name (the chapter withheld by the spoiler guard); **active today** → a static `bloom` ring at 40 %; **away** → no ring, drifting back into the arc. With `share_streak`, a 16 px flame and count sit at the orb's lower right. **Semantics:** the arc is a list read front to back (reading now first, then active today, then away, each group newest first); each orb is a button whose accessible name carries the state: "Aarav, reading Omniscient Reader now", "Mira, active today", "Kai, away, 12-day streak"; activating it opens the friend sheet; the breathing ring is decoration. Under the arc: segmented **Activity · Letters · Shelves** (Letters shows a count badge).
  - **Activity:** activity rows grouped by day (sticky day headers): the actor orb 32 with a bloom ring, a sentence ("Aarav finished chapter 142 of **Solo Leveling**", "Mira started **Omniscient Reader**", "Aarav reacted *Hype* to chapter 88"), each reaction drawn with its Phosphor Fill glyph in `bloom` (never an emoji), a `strip-scroll` or `book-open` mode glyph, the cover 44 × 66, the time; consecutive chapter reads collapse into one row ("Aarav read chapters 140–152 of **Solo Leveling**"); tapping the series opens it (zoom from the cover), tapping the orb opens the friend sheet; a "Read it too" plain button on series the viewer doesn't follow.
  - **Letters:** recommendations received: cards with the sender's orb, the series (world title card style, bloom rim), the note in Literata italic, and actions "Add to library" (secondary; the screen has no tinted object because every card would compete) and "Not now" (plain); a "Sent" filter chip shows what this profile recommended and whether it was added. Status sync through `PATCH /circle/letters/{id}`.
  - **Shelves:** shared collections from others (fanned stacks with the owner's orb) and this profile's shared ones.
- **Layout, desktop:** the presence arc across the top of the content column; Activity as the main column; Letters and Shelves as a right column at ≥ 1280 px.
- **Signature moment:** **presence has depth**: people reading right now drift forward to the front of the arc and breathe with a live bloom ring; as their activity ages they drift back. Opening a friend makes their orb fly to the friend sheet's header on `zoom`.
- **States:** **this profile doesn't share** (a card at the top, "Read together": "Share what this profile reads with the other readers on this server: what you start and finish, your reactions, and the collections you choose to share. Never your bookmarks, searches or downloads." + the master switch; others' activity still shows below); **nobody else sharing** (the object lens `users-three`, "Your Circle is quiet" / "When people on this server share their reading, it shows up here."); **only you on the server** ("There's nobody else on this server yet."); per-tab empties ("No activity yet", "No letters yet. When someone recommends a series, it lands here.", "No shared shelves yet"); loading (orb skeletons + 6 row skeletons); offline ("The Circle needs a connection"); error (+ Try again).
- **Keys:** `[`/`]` tabs, `j`/`k` rows, Enter opens, `r` refresh, `l` Letters, `e` react to the focused row's chapter, `f` opens the friend sheet of the focused row's person (or the focused orb in the arc; arrows move along the arc).

#### 9.3.2 Reactions on chapters

- **Six named reactions**, Phosphor **Fill** glyphs: **Hype** `fire`, **Love** `heart`, **Wrecked** `smiley-melting`, **Tears** `drop`, **Twist** `lightning`, **Masterpiece** `hands-clapping`. Your chosen reaction is drawn in `bloom` on a `bloomWash` disc; others in `label2`. Stored kinds are shared with Cinematic (§15.6): Love = `loved`, Tears = `tears`, Twist = `shook`, Masterpiece = `chefs_kiss`, Hype = `hype`, Wrecked = `wrecked`; a reaction another skin stored as `laughed` renders in Glass as "Laughed" with `smiley` Fill.
- **Where:** the manga reader's end card and the novel reader's end matter (for the chapter just finished), the desktop reader's right panel (Circle tab), the series detail header (for the latest chapter read), chapter rows (a summary glyph + count), activity rows, the page menu "React to this chapter".
- **Picker (signature: hold to bloom, throw to send):** tapping the reaction button sends **Love** at once. **Pressing and holding** (300 ms) blooms six glass bubbles (T2, 52 px, each holding its 36 px glyph and its name in `caption2` beneath) in a 120° arc above the finger on `lens`; `reaction.bloom`. Sliding the finger across them magnifies the bubble under it to 1.4 × on `track` (`reaction.cross` per bubble). Releasing on a bubble sends it: the glyph **flies** in a ballistic arc (launch velocity toward the reaction strip, gravity 2,400 px/s²) and lands in the strip with a pop and a 6-particle `bloom` burst (`reaction.send`, the `pop` sound), its count ticking up on `tick`. Releasing outside cancels (the bubbles collapse back into the button on `dismiss`). One reaction per profile per chapter; sending another moves it; tapping your own removes it (it shrinks away on `dismiss`).
- **Strip:** the six glyphs with counts; friends' orbs stacked beside each (up to 3 + "+2"); long-press a glyph for a popover of who reacted with it.
- **Keys (desktop):** focus the reaction button, Enter sends Love, `shift+Enter` opens the picker, arrows choose, Enter sends; `1` to `6` send a reaction directly while the strip has focus.
- **States:** sending (the flown glyph waits in the strip at 60 % with a thin ring until confirmed), failed (the glyph falls back to the button with the error shake and a toast "Couldn't send your reaction"), offline (queued and sent on reconnect, drawn immediately), sharing off (the strip still works for this profile, with the helper "Only you see this. Turn on Circle sharing to show others."), `show_reactions` off (as sharing off).

#### 9.3.3 Shared collections

- A collection's ⋯ → **Share** (owner) opens the `?sheet=collection-share` `medium` sheet: Circle members as orb toggles (only those with `allow_shelf_invites`; 18+ collections list only members whose gate is open), a mode **Can add · View only**, and "Share" (`POST /library/collections/{id}/share {profile_ids, mode}`). Shared cards carry a bloom rim and the members' orbs; "Shared with Aarav" under the name. **States:** loading members (3 orb skeletons); nobody accepts shelves ("Nobody on this server accepts shared shelves yet." and Share disabled); an 18+ collection with no eligible member ("Nobody who accepts shared shelves can see 18+ titles." and Share disabled); this profile doesn't share (the master switch line of §9.3.1 with "Turn on sharing"); sharing ("Share" shows its loading dots); failed (inline "Couldn't share this shelf" above the button, the toggles kept); offline ("Sharing needs a connection", toggles disabled); success (the sheet closes and the card's bloom rim draws in over `tintShift`).
- **Members' view:** others' shared collections appear in Collections under **From your Circle**, with the owner's orb. **View only:** no Add, Edit, Reorder, Remove or Delete; the ⋯ offers "Save a copy" (creates a collection with the same members through `POST /library/collections` and the member calls) and "Leave shelf". **Can add:** "Add series" is available; posters added by someone else carry a 20 px orb of who added them at the bottom-left; removing someone else's addition asks "Remove {title}? Aarav added it."; Edit, Reorder and Delete stay the owner's.
- **Leaving:** ⋯ → "Leave shelf" → alert "Leave Weekend reads? It disappears from your Collections; Aarav keeps it." (`DELETE /library/collections/{id}/share/{profile_id}`).
- Mature members of a shared collection are served only to viewers whose gate is open (the rest see fewer members, and the count reflects what they can see).

#### 9.3.4 Recommend to a friend (letters)

- **Gesture (signature):** lift any poster (long-press). When sharing is on and at least one member accepts recommendations, their orbs (56 px, `glassThin` bezel, bloom ring) **materialise along the top** of the screen at safe-top + 72, spaced 72 apart. Drag the lifted poster toward an orb: within 64 px the orb swells to 1.2 and the poster is **pulled** toward its centre (magnet: the poster eases toward the orb by 35 % of the remaining distance per frame while inside the radius), `magnet.capture`; releasing inside sends: the poster shrinks into the orb on `zoom`, the orb pulses (`celebrate`), `magnet.drop` + `recommend.send` fire; a toast "Recommended to Aarav · Add a note · Undo" ("Add a note" opens a small sheet with a text field, max 140 characters).
- **Menu path:** every poster, series detail, the reader's page menu and Wrapped card 4 have "Recommend to…" → a `medium` sheet titled "Recommend *{title}*": Circle orbs as multi-select toggles (a member whose profile would not be allowed to see this series is disabled with "Not available to {name}"; a member with Accept recommendations off is disabled with "{name} isn't taking recommendations"), a note field (140 characters, "Why they'll like it"), and "Send" (`POST /circle/letters {to_profile_ids, source_id, series_key, note}`). On send the selected orbs fly out of the sheet along a curve toward the top edge (the Orbs fly out move, §4.10).
- **Recipient:** a card in Circle → Letters, a bloom dot on the You tab and the sidebar's Circle item, the Home "From your Circle" rail, and a candidate for their Home spotlight.
- **18+:** a mature recommendation can only be addressed to members whose gate is open; the sender never learns another profile's gate beyond the disabled row.
- **States:** no one accepting (the orbs don't appear; the menu item reads "Recommend to… (no one is taking recommendations yet)" and is disabled with that reason), sending, sent, failed (the poster springs back out of the orb to its origin with a toast "Couldn't send that").

#### 9.3.5 A friend (`/circle/:profileId`)

A sheet (phone, `large`) or window (desktop, 560 px): the friend's orb (112 px, their mood ring and bloom ring), name, account ("Aarav · @aarav"), "Reading now: *{title}*" when shared; sections **Reading** (their shared continue list as posters with their progress lines in `bloom`), **Shelves** (their shared collections), **Recent** (their activity), **Their reactions** (spoiler-guarded). Actions: "Recommend something to Aarav" (opens a series search, then the recommend sheet with them preselected), per poster "Add to library". States: not sharing any more ("Aarav isn't sharing right now."), loading, offline, error.

#### 9.3.6 Settings

Circle and privacy: §8.25.15.

#### 9.3.7 Backend used (shared with Cinematic)

`GET /circle/members` (each member with `now: {source_id, series_key, chapter_key, since} | null`, where the server sends `null` unless the member's `show_presence` is on, for both skins, and `last_active_at`; Glass adds `streak {current, alive_today}` when the member shares it), `GET /circle/feed?cursor`, `POST /circle/reactions {source_id, series_key, chapter_key, kind}` / `DELETE /circle/reactions/{id}`, `GET /circle/reactions?source&series` (per-chapter counts and who), `POST /circle/letters`, `GET /circle/letters`, `PATCH /circle/letters/{id}`, `PATCH /profiles/{id}/sharing {share_activity, show_reactions, accept_recommendations, allow_shelf_invites, share_mature, show_presence, share_streak, excluded_series}`, `DELETE /circle/activity` (Glass addition), `POST /library/collections/{id}/share {profile_ids, mode}`, `DELETE /library/collections/{id}/share/{profile_id}`. All `X-Profile-Id` scoped and gated on serve.

### 9.4 Ambient reader extras

#### 9.4.1 Cruise (auto-scroll with speed control)

- **Entry:** the cruise button in the manga reader's bottom capsule (`flywheel` glyph), `p` (manga) or `a` (novel scroll mode, where 1.0× is the reading pace, §8.15.4), or the reader settings default.
- **Start:** tap → the strip ramps from 0 to the saved speed over 400 ms (`autoscroll.start` haptic, a flywheel spin-up), and the button becomes a **flywheel pill**: a 44 px tall capsule with a spinning disc glyph whose rotation speed matches the scroll speed and "1.0×" in `mono`.
- **Speed:** 0.25× to 4× of a 60 px/s base (15 to 240 px/s), logarithmic. **Drag vertically on the pill** to change it (up faster, 8 px per 0.05×), `autoscroll.step` every 0.25×, a magnet at 1.0× (`detent.magnet`); a glass HUD "1.5×" floats above while dragging. **Flick to cruise:** while cruise is on, a flick on the strip lets the strip coast; when its velocity decays into the cruise range, the flywheel **engages** and holds that speed (the pill's value updates to match, with a `selection`), so a gentle flick is the fastest way to set speed. Keyboard `<`/`>` step by 0.25×.
- **Pause and resume:** touching the strip stops it under the finger (catch); releasing resumes after 800 ms with the 400 ms ramp; any chrome interaction pauses; reaching the end of available pages stops it (`autoscroll.end`); in continuous mode it carries across chapter seams.
- **Right-edge swipe** while cruising (the scrub rail's strip) adjusts speed instead of scrubbing, with the HUD.
- **Persistence:** speed per series as the multiplier `cruiseSpeed` (a new key; the old `autoScrollSpeed` integer is read once for migration, §8.25.3, and never reinterpreted) in the per-series reader preferences (web `mm.reader-preferences[{source}:{series}]`, Flutter `mm.reader-prefs.u{user}p{profile}`, §15.5); the default in Settings → Reader defaults → Ambient.
- **Reduce Motion:** cruise still works (the reader asked for this motion) but never starts on its own and uses no ramp.

#### 9.4.2 Soundscape

- **Entry:** reader settings → Ambient → Soundscape (manga and novel readers), `shift+s` in either reader, the listen player's ⋯, Settings → Sound & haptics (defaults). The `?sheet=soundscape` sheet (phone `medium`; desktop the right panel's Settings tab).
- **Six scenes, each three layers mixed live** (**Bed**, **Detail**, **Tone**):

| Scene | Bed | Detail | Tone | Procedural fallback (always available, no files) |
|---|---|---|---|---|
| **Rain** | steady rain on a roof | drips on a window pane | low room tone | Pink noise → high-pass 400 Hz → low-pass 6 kHz; droplet ticks (sine 2 to 4 kHz, 4 ms, 8 to 20 per second, random pan); room tone = brown noise low-passed 200 Hz at −24 dB |
| **Wind** | wind through trees | leaves and a creaking branch | far drone | Brown noise → band-pass 300 Hz, Q 0.7, centre modulated ±150 Hz by a 0.08 Hz LFO; gain LFO 0.05 Hz depth 0.4; detail = filtered noise bursts 40 to 120 ms, 1 per 2 s |
| **Ocean** | waves on sand | shingle drawback | distant gulls | Brown noise → low-pass 900 Hz; amplitude swell by a 0.1 Hz LFO, depth 0.7; detail = high-passed noise swells following the wave envelope |
| **Hearth** | fire bed | crackles and embers | night wind | Brown noise → low-pass 1.2 kHz at −18 dB; crackles: 3 to 8 ms noise bursts band-passed at 3 kHz, Poisson rate 6 per second |
| **Stream** | running water | pebbles and a small fall | birds far off | Pink noise → band-pass 1.8 kHz, Q 1.2; amplitude flutter 7 Hz depth 0.15 |
| **Deep** | synthesized drone in A | slow shimmer | soft pulses | Sines at 55 Hz and 82.41 Hz (A1 + E2) with a slow 0.03 Hz chorus, plus pink noise low-passed at 300 Hz |

- **Recorded layers (primary when available).** Each layer is a 90 s seamless loop, Opus 96 kb/s in `.ogg` (web, Android) and AAC-LC 96 kb/s in `.m4a` (iOS and Safari), about 1.1 MB each (18 files, ≈ 20 MB), CC0 field recordings from freesound.org only (Deep's layers synthesized with sox), each file's origin listed in About → Licences. Served by the backend's static media route as `/app/media/soundscapes/glass/{scene}-{bed|detail|tone}.{ogg|m4a}` next to Cinematic's loops, fetched on first play and cached (web: Cache Storage `mm-soundscapes-v1`; apps: the app support directory).
- **Starting:** the procedural version of the scene starts **at once** (0 ms, file-free, identical on every platform); when the recorded layers are cached and decoded, each cross-fades in over 2 s over its procedural counterpart, which then stops. Offline with nothing cached, or a file that fails to load: the procedural layers keep playing (the scene orb shows a small `cloud-slash` in its corner with the tooltip "Playing the built-in version").
- **Picker:** six glass scene orbs (T2, 64 px) in a row (phone: a 3 × 2 grid), each a slow Light glyph pattern drawn inside the orb, clipped to it, in `label2` (frozen under Reduce Motion): Rain, 12 streaks 1 × 8 px falling at 0.6 px/frame at 10° from vertical; Wind, 6 leaves 3 × 2 px drifting left to right at 0.4 px/frame on a ±4 px sine; Ocean, 3 wave lines 2 px thick scrolling at 0.3 px/frame; Hearth, 8 embers 2 px rising at 0.5 px/frame with a 30 % flicker; Stream, 4 ripple rings 1 px expanding from 2 to 20 px radius in 2 s; Deep, 14 stars 2 px drifting at 0.3 px/frame with a 5 s twinkle; the playing orb shows 8 live level bars (the three layers' levels); **Off**. Under the orbs: the **mixer**, three sliders **Bed · Detail · Tone** (0 to 100 %, defaults 80 / 50 / 30, `detent.tick` every 10 %), the master volume (−30 to 0 dB, default −12 dB), and switches **Match the story** (default on), **Remember for this series** (default off), **Lower under narration** (default on).
- **Match the story:** when a soundscape is on and this series has no remembered scene, the scene follows the series' first matching genre: horror, thriller, mystery, psychological → **Rain**; romance, slice of life, comedy, drama, historical → **Hearth**; fantasy, isekai, school, supernatural → **Stream**; adventure, sports → **Ocean**; action, martial arts, murim, military → **Wind**; sci-fi, mecha, cyberpunk, space → **Deep**; anything else → **Rain**. The scene orb shows "Matched: Hearth" under it.
- **Remember for this series:** stores `{scene, mix}` in the per-series reader preferences (`soundscape` key, the same per-series store as `cruiseSpeed`, §15.5); a remembered scene wins over Match the story. The soundscape defaults (scene, Match the story, mix, volume, Lower under narration) are per profile on the device (`mm.soundscape.defaults`, §15.5).
- **Your own music:** when another app's audio is playing as the reader opens a scene (iOS `AVAudioSession.secondaryAudioShouldBeSilencedHint` through `audio_session`; Android `AudioManager.isMusicActive` through the `mm/platform` channel; the web cannot know and skips this), the soundscape **starts muted** with a toast "Your music is playing. Tap to mix the soundscape in." (the action unmutes over 1 s). The audio session is the `soundscape` state of §6 (`playback` with `mixWithOthers`), so the reader's music is never interrupted or ducked.
- **Mixing rules:** fades in over 3 s, out over 1.5 s; while narration plays it ducks by 12 dB over 400 ms (or pauses, with Lower under narration off); it follows the sleep timer; it pauses when the reader is left and resumes on return; UI sounds are suppressed while it plays.
- **Rain on glass (signature):** while the **Rain** scene plays, 6 to 10 droplets (radius 3 to 6 px) run down the reader's glass capsules and the minimised pill, refracting the page behind them: each run lasts 4 s along a gravity path with a 15 % lateral wobble, starting at random positions, one new droplet every 0.6 s up to the cap. Each droplet displaces the backdrop by at most 3 px at its centre, falling off to 0 at its rim (a hemispherical lens profile), with a 1 px `rgba(255,255,255,0.35)` specular dot at the light angle. Flutter: a fragment shader `shaders/rain_on_glass.frag` on the capsules' glass layer only (inputs: time, droplet positions, the capsule size); web tier A: an animated SVG displacement map on the pill and capsules; web tier B: a static droplet texture (`frontend/public/glass/droplets.webp`, 6 drops) at 60 % opacity. Off under Reduce Motion, Reduce Transparency and Solid glass. Other scenes add nothing to the glass.
- **Playback engines:** web: one `AudioContext`; the procedural graphs (a 4 s noise `AudioBuffer` looped, `BiquadFilterNode`s, `OscillatorNode` LFOs into `AudioParam`s) and the recorded layers (`AudioBufferSourceNode`s with `loop = true`) each into a per-layer `GainNode`, into one master `GainNode`; started on the user's tap. Phones: `flutter_soloud` 5.1.4: the procedural recipe is rendered in a Dart isolate to a 30 s mono 32 kHz buffer per layer whose last 2 s are cross-faded into its first 2 s (a seamless loop), loaded with `SoLoud.instance.loadMem`, while the event parts (droplet ticks, crackles) are scheduled live on top so they never repeat audibly; cached recordings load with `loadFile`; per-layer volumes through `setVolume` with fades.
- **States:** off, starting (procedural), playing (recorded), playing (built-in), paused, muted (music playing), ducked (narration), unavailable (the audio device refused: toast "Couldn't start the soundscape").

#### 9.4.3 Guided view (panel by panel)

- **Data:** `GET /reader/panels?source&series&chapter` (shared with Cinematic) returns `pages: [{number, panels: [{x, y, w, h}]}]` in page fractions and reading order, computed server-side from the page proxy (a whitespace and blackspace gutter projection in Pillow) and cached per page ETag; the manifest carries `panels_ready: bool`. The engine exposes the current page's boxes as `panelBoxes` (§15.4). Downloaded chapters store their panel data with the pages.
- **Entry:** the page menu (long-press a page) → "Guided view", reader settings → Ambient → Guided view, `shift+p`, or the `panel-focus` button that joins the top-right glass group when `panels_ready` (hidden otherwise).
- **Camera:** the viewport frames the current panel with 24 px padding (fit to width or height, up to 3×) on black; everything outside the panel is dimmed to `#000000` at 85 %; the panel is framed by a **T2 glass lens** (radius 14, 2 px specular rim), the one glass surface of the reader's overlay layer above the strip (§2.4.1, §8.14.9), moved by the engine's `setCamera` (§15.4). The next or previous panel is one swipe (horizontal, ≥ 50 px or ≥ 500 px/s, direction-locked; mirrored for right-to-left), one tap on the side bands (right 30 % next, left 30 % previous), or `→`/`←`, `j`/`k`, Space; the camera **glides** between panels on `camera`, carrying the swipe's velocity into the glide, and crosses page boundaries continuously; `panel.step` per panel. Panels taller than the viewport are walked in steps of 80 % of the viewport height. Past the last panel the camera rubber-bands and then offers the next chapter like the strip.
- **The refracted sliver (signature):** as the lens moves, its leading edge bends the dimmed art at its rim (the T2 bezel's displacement applied to the dim layer), so the next panel shows as a refracted sliver of colour in the lens's edge before the camera arrives.
- **Counter:** a `glassRegular` pill at the bottom, "Panel 4 of 38 · Page 7" + a close ×; double-tap shows the whole page for 1.5 s (a zoom out on `camera`), then returns.
- **Overview:** pinch out below 1× to see the whole page with panel outlines numbered in glass chips; tap a panel to fly to it; pinch in returns.
- **Exit:** swipe down (projected past 120 px), the pill's ×, Esc, or the glyph → back to the strip at the current panel's position.
- **States:** finding panels (the view falls back to page-by-page framing with "Finding panels…" in the pill and switches when ready); not ready ("Guided view isn't ready for this chapter yet." + "Read as strip"; the button appears when the backend finishes); a page without panels (framed whole, the counter reads "Page 7 · whole page"); offline without cached panel data ("Guided view needs a connection for this chapter" + Read as strip).
- **Reduce Motion:** cuts between panels with a 120 ms cross-fade; no sliver.

#### 9.4.4 Page-tinted chrome

- **Source:** the reader engine's `currentPageSample` (§2.1.8 step 3): the client-side sample of the page under the reading line (38 % down in the strip; the visible page in paged modes; the current page in guided view), at most every 600 ms, cached per page URL. The manifest's `pages[].tint` (when an earlier read reported it) paints first.
- **Tint:** the sample's `tint` clamped in OKLCH to lightness 0.35 to 0.50 and chroma ≤ 0.12, applied as a tint layer inside every reader glass surface at 18 %, to the rims at 22 % (the rim tint at L 0.86, C ≤ 0.08), to the soft edges at 30 %, to the minimised pill's inner glow at 30 %, and to the micro-progress line; every change cross-fades over `tintShift` (900 ms) and applies only when the new tint differs from the current one by ΔE (OKLab) > 0.04, so fast scrolling never flickers; nothing changes during a fling faster than 3000 px/s until it settles (`scrollVelocity`).
- **Legibility:** the same sample's `lTop` and `lBottom` drive `dimLegibility` and the label `GRAD` of the top chrome and the bottom capsule separately (§2.1.7, §3.5), so a capsule over a white panel darkens and thickens its labels while the other stays clear.
- **Gutters (desktop):** the page-lit gutters of §8.14.11 use the sample's `top` and `bottom`.
- **Greyscale pages** keep the previous tint; after 6 greyscale pages the chrome eases to the series cover palette's `a[0]`.
- **Novel reader:** the chrome takes the paper's ink at 12 % as its tint; the listen full player takes the narrating voice's hue.
- **Switch:** reader settings → Ambient → Page-tinted chrome (default on). Off: neutral glass (the dim still adapts). Reduce Transparency: the tint stays on the solid chrome's rim only.
- **Desktop:** the side panels' rims take the same tint.

---

## 10. The two required signature animations

### 10.1 Heading reveal (each letter fades in, slides up and un-blurs, staggered)

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
| Size | Responsive per the type scale (§3.2) with tight tracking (`largeTitle` −0.020 em, `title2` −0.010 em, `display` −0.025 em) |
| Limit | Headings up to 60 graphemes; longer text reveals per word with the same parameters and 40 ms per word |

**Placement (exactly these):**

1. Tab-root large titles (Library, Sources, You) and pushed-screen large titles, **once per session per screen**.
2. Rail headers (H3, `title2`) on Home and Library, the first time each rail scrolls into view per session.
3. The hero spotlight title on Home, each time the spotlight pages (the outgoing title leaves together over `fadeOut` with blur 4 px).
4. The series detail title and the book page title when the sheet opens.
5. Chapter seams ("CHAPTER 144") in the manga strip as they enter the viewport.
6. Onboarding step titles, the For you title, Statistics hero line, Wrapped card titles.
7. The wordmark letters in the splash (§12.4).

**Interruptibility:** scrolling the heading off-screen, tapping it, or navigating completes it instantly (all letters jump to rest); new text replaces old text by letting the old letters leave together and starting the new wave. Keyboard focus arriving on the heading (the route focus of §8.0.8) does **not** complete it.

**When it starts:** every placement starts on its **first visibility**, when at least 25 % of the heading is inside the viewport (web `IntersectionObserver` with `threshold: 0.25`; Flutter the `revealWhenVisible` helper below), never on mount, so a rail header or seam below the fold reveals when it is seen, not while it is off-screen.

**Once per session:** a placement plays at most once per app session per profile; the record is a set of placement keys (`"{profileId}:{screenId}:{headingKey}"`) in `sessionStorage["mm.glass.revealed"]` on the web and an in-memory `Set` held by a `revealedHeadingsProvider` (`Provider<Set<String>>`, never watched for rebuilds: the widget reads it once in `initState`, decides, and adds its key when the reveal starts) on Flutter, so recording a reveal never rebuilds or cancels it. Placements 3 and 5 (the hero title and chapter seams) are exempt: they play whenever their text changes or they enter the viewport.

**Accessibility:** the full text is in the accessibility tree from the first frame (web: an `sr-only` copy plus `aria-hidden` on the animated letters; Flutter: `Semantics(label: text)` over `ExcludeSemantics`); Reduce Motion (the OS setting or the in-app switch) shows the text at once with no glint.

**Web implementation.** One client component for every placement (a server component cannot read `sessionStorage` or see the viewport). The server renders the letters in their **waiting** state (`data-reveal="wait"`: letters transparent, layout final, so nothing reflows); on mount the component decides: already revealed this session, or reduced motion → `data-reveal="done"` (shown at once); otherwise it observes the heading and sets `data-reveal="run"` on the first 25 % hit, recording the key. A CSS fail-safe shows waiting letters after 1,500 ms if hydration never happens. Headings over 60 graphemes animate per word (`--i` counts words, 40 ms stagger).

```tsx
// skins/glass/primitives/LetterReveal.tsx
"use client";
import { useEffect, useRef, useState } from "react";
const seg = new Intl.Segmenter(undefined, { granularity: "grapheme" });
const KEY = "mm.glass.revealed";
const reduced = () =>
  matchMedia("(prefers-reduced-motion: reduce)").matches || document.documentElement.dataset.motion === "reduced";

export function LetterReveal({ text, revealKey, as: Tag = "h3" }:
  { text: string; revealKey?: string; as?: "h1" | "h2" | "h3" }) {
  const ref = useRef<HTMLHeadingElement>(null);
  const [state, setState] = useState<"wait" | "run" | "done">("wait");
  const perWord = Array.from(seg.segment(text)).length > 60;
  useEffect(() => {
    const seen: string[] = JSON.parse(sessionStorage.getItem(KEY) ?? "[]");
    if (reduced() || (revealKey && seen.includes(revealKey))) { setState("done"); return; }
    const io = new IntersectionObserver(([e]) => {
      if (!e.isIntersecting) return;
      io.disconnect(); setState("run");
      if (revealKey) sessionStorage.setItem(KEY, JSON.stringify([...seen, revealKey]));
    }, { threshold: 0.25 });
    io.observe(ref.current!);
    return () => io.disconnect();
  }, [text, revealKey]);
  let i = 0;
  return (
    <Tag ref={ref} className="letter-reveal" data-reveal={state}>
      <span className="sr-only">{text}</span>
      <span aria-hidden>
        {text.split(" ").map((word, w) => (
          <span key={w} className="word" style={perWord ? ({ "--i": i++ } as React.CSSProperties) : undefined}>
            {perWord ? word : Array.from(seg.segment(word), (s) => (
              <span key={i} className="g" style={{ "--i": i++ } as React.CSSProperties}>{s.segment}</span>
            ))}
            {" "}
          </span>
        ))}
        <span className="glint" style={{ "--n": i } as React.CSSProperties}>{text}</span>
      </span>
    </Tag>
  );
}
```

```css
.letter-reveal { position: relative; }
.letter-reveal .word { display: inline-block; white-space: nowrap; }
.letter-reveal .g, .letter-reveal .word[style] { display: inline-block; }
.letter-reveal[data-reveal="wait"] :is(.g, .word[style]) { opacity: 0; animation: lr-failsafe 0s 1500ms forwards; }
.letter-reveal[data-reveal="run"] :is(.g, .word[style]) {
  animation:
    lr-rise var(--mm-spring-letter-ms) var(--mm-spring-letter) both,   /* linear() sampled from {424 ms, 0.12} by build.mjs */
    lr-fade 180ms cubic-bezier(0.2, 0, 0, 1) both;
  animation-delay: calc(var(--i) * 24ms);
}
.letter-reveal[data-reveal="run"] .word[style] { animation-delay: calc(var(--i) * 40ms); }
@keyframes lr-rise { from { translate: 0 0.4em; scale: 0.96; filter: blur(12px); } }
@keyframes lr-fade { from { opacity: 0; } }
@keyframes lr-failsafe { to { opacity: 1; } }
/* the glint: a 40 %-wide white band clipped to the text, once, 120 ms after the last letter settles */
.letter-reveal .glint { position: absolute; inset: 0; color: transparent; pointer-events: none; opacity: 0;
  background: linear-gradient(120deg, transparent 30%, rgb(255 255 255 / 0.18) 50%, transparent 70%) no-repeat;
  background-size: 40% 100%; background-position: -40% 0; -webkit-background-clip: text; background-clip: text; }
.letter-reveal[data-reveal="run"] .glint {
  animation: lr-glint 500ms linear calc(var(--n) * 24ms + 402ms + 120ms) forwards; }
@keyframes lr-glint { 0% { opacity: 1; background-position: -40% 0; } 100% { opacity: 1; background-position: 140% 0; } }
.letter-reveal[data-reveal="done"] .glint { display: none; }
@media (prefers-reduced-motion: reduce) { .letter-reveal :is(.g, .word[style]) { animation: none !important; opacity: 1 !important; } .letter-reveal .glint { display: none; } }
[data-motion="reduced"] .letter-reveal :is(.g, .word[style]) { animation: none !important; opacity: 1 !important; }
[data-motion="reduced"] .letter-reveal .glint { display: none; }
```

The interruptible variant (hero spotlight, where text changes) uses Motion 13.4.4 with `animate` per letter and `glassSpring.letter = { type: "spring", stiffness: 220, damping: 26, mass: 1 }`, so a new title can retarget letters mid-flight; it shares the visibility and reduced-motion decisions above.

**Flutter implementation:**

```dart
// lib/skins/glass/primitives/letter_reveal.dart
class LetterReveal extends ConsumerStatefulWidget {
  const LetterReveal(this.text, {super.key, required this.style, this.revealKey});
  final String text; final TextStyle style; final String? revealKey;
  @override ConsumerState<LetterReveal> createState() => _LetterRevealState();
}
class _LetterRevealState extends ConsumerState<LetterReveal> with TickerProviderStateMixin {
  static final _spring = SpringDescription.withDurationAndBounce(
      duration: const Duration(milliseconds: 424), bounce: 0.12);
  late final List<AnimationController> _move;   // position, blur, scale: the letter spring
  late final List<AnimationController> _fade;   // opacity: the 180 ms fadeIn curve, never the spring
  bool _done = false;
  @override void initState() {
    super.initState();
    final n = widget.text.characters.length;
    _move = List.generate(n, (_) => AnimationController.unbounded(vsync: this));
    _fade = List.generate(n, (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 180)));
    final seen = ref.read(revealedHeadingsProvider);            // read once, never watched
    if (widget.revealKey != null && seen.contains(widget.revealKey)) _done = true;
  }
  void _start() {                                              // called by revealWhenVisible at 25 % visibility
    if (_done || ref.read(glassMotionPrefsProvider).reduced) { setState(() => _done = true); return; }
    if (widget.revealKey != null) ref.read(revealedHeadingsProvider).add(widget.revealKey!);
    for (var i = 0; i < _move.length; i++) {
      Future.delayed(Duration(milliseconds: 24 * i), () {
        if (!mounted) return;
        _move[i].animateWith(SpringSimulation(_spring, 0, 1, 0));
        _fade[i].animateTo(1, curve: const Cubic(0.2, 0, 0, 1));
      });
    }
  }
  @override void dispose() { for (final c in [..._move, ..._fade]) { c.dispose(); } super.dispose(); }
  @override Widget build(BuildContext context) {
    if (_done || ref.watch(glassMotionPrefsProvider).reduced) return Text(widget.text, style: widget.style);
    final chars = widget.text.characters.toList();
    return revealWhenVisible(onVisible: _start, child: Semantics(label: widget.text,
      child: ExcludeSemantics(child: Wrap(children: [
        for (var i = 0; i < chars.length; i++)
          AnimatedBuilder(animation: Listenable.merge([_move[i], _fade[i]]), builder: (_, __) {
            final v = _move[i].value;                    // may pass 1.0 slightly: the droplet overshoot
            final blur = (1 - v).clamp(0.0, 1.0) * 12;
            return Opacity(opacity: _fade[i].value,
              child: Transform.translate(offset: Offset(0, (1 - v) * 0.4 * widget.style.fontSize!),
                child: Transform.scale(scale: 0.96 + 0.04 * v,
                  child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                    child: Text(chars[i], style: widget.style)))));
          }),
      ]))));
  }
}
```

`glassMotionPrefsProvider` merges the two sources once (`reduced = MediaQuery.disableAnimationsOf(context) || inAppReduceMotion`, §4.11), so every Glass primitive asks one question. `revealWhenVisible(onVisible:, child:)` is a 30-line helper in the same file: it listens to the nearest `Scrollable`'s position (`Scrollable.maybeOf(context)?.position`) and, after each frame, compares the child's `RenderBox` rect with the viewport's; the first time at least 25 % of it is inside, it calls `onVisible` once and stops listening (a heading outside any scroll view calls it after the first frame). No package is added for it. Word-level wrapping above 60 graphemes (40 ms per word) and the glint (a `ShaderMask` with a `LinearGradient` band, 40 % of the width, white at 18 %, sliding once over 500 ms, 120 ms after the last letter settles) wrap this in the real primitive; per-glyph `ImageFiltered` layers are limited to headings of 60 graphemes or fewer, per the flagship-only budget.

### 10.2 Main headline typing reveal (one character every 50 ms)

**Glass version: each character lands, and the caret is a capsule of light.** The string is laid out in full from frame 0 with the untyped tail transparent (the line never reflows). Every 50 ms the next grapheme becomes visible by fading in over 40 ms while scaling 0.8 → 1 on `tick` (a tiny droplet landing). The **caret** is a capsule of light: 2 px wide, as tall as the cap height (0.72 em), fully rounded, filled with the action tint `iris400` `#A99BFF`, with a 1 px white specular core (`inset 0 0 0 0.5px #FFFFFF` on the web; a 1 px white centre line on Flutter) and a soft glow `0 0 6px rgba(169,155,255,0.45)`; it rides at the insertion point, moving on `track` so it glides rather than jumps. When typing ends the caret blinks three times (530 ms on, 530 ms off) and then **dematerialises** (blur 0 → 6 px and opacity 1 → 0 over 350 ms `dematerialize`).

| Parameter | Value |
|---|---|
| Unit | Grapheme (`Intl.Segmenter` on web, `characters` in Dart); spaces take a step |
| Step | 50 ms per grapheme (a 24-character greeting takes 1.2 s) |
| Each grapheme | Opacity 0 → 1 over 40 ms, scale 0.8 → 1 on `tick` (settles in 337 ms) |
| Caret | 2 × 0.72 em capsule, `iris400` with a 1 px white core and a 6 px glow; follows on `track`; 3 blinks of 530 ms; dematerialises over 350 ms |
| Cap | 48 graphemes; a longer headline keeps every grapheme in the DOM (and in layout from frame 0), types the first 48, and fades the tail in as one span over 200 ms when the caret reaches grapheme 48 |
| Skip | A `pointerdown` on the headline, a key press while focus is on the headline or on `document.body` (so a global shortcut pressed elsewhere does not end it), or navigating away completes it at once (the caret still blinks and leaves). **Focus arriving on the headline does not skip it:** the route focus of §8.0.8 lands on this very heading on every navigation, and its `aria-label` already carries the full text |
| Once | Once per app session per profile per placement: the key `"{profileId}:{placement}"` is recorded in `sessionStorage['mm.glass.typed']` (Flutter: the `revealedHeadingsProvider` set) **when typing starts**; later visits show the text immediately |

**Placement (exactly these):**

1. The Home greeting ("Good evening, Yash"), the main headline, once per app session.
2. The Login heading ("Welcome back").
3. Onboarding's first step ("Hi, Yash.").
4. The Wrapped cover ("Your 2026 in chapters").
5. The recap deck heading ("Previously on Solo Leveling").

**Rules:** screen readers get the whole string immediately (`aria-label` on the heading with the typed spans `aria-hidden` on the web; `Semantics(label:)` over `ExcludeSemantics` on Flutter). No haptic per character; even with UI sounds on, typing plays no sound. Navigating away completes it silently. Reduce Motion: the full text immediately, no caret.

**Web** (`frontend/src/skins/glass/primitives/TypedHeadline.tsx`, a client component because it must skip on input):

```tsx
"use client";
import { useEffect, useRef, useState } from "react";
const seg = new Intl.Segmenter(undefined, { granularity: "grapheme" });
const CAP = 48, KEY = "mm.glass.typed";
const reduced = () =>
  matchMedia("(prefers-reduced-motion: reduce)").matches || document.documentElement.dataset.motion === "reduced";

export function TypedHeadline({ text, typedKey, as: Tag = "h1", className }:
  { text: string; typedKey: string; as?: "h1" | "h2"; className?: string }) {
  const all = Array.from(seg.segment(text), (s) => s.segment);
  const g = all.slice(0, CAP), tail = all.slice(CAP).join("");   // every grapheme stays in the DOM
  const [done, setDone] = useState(false);
  const ref = useRef<HTMLHeadingElement>(null);
  const caretRef = useRef<HTMLSpanElement>(null);
  useEffect(() => {
    const el = ref.current, caret = caretRef.current;
    if (!el || !caret) return;
    const seen: string[] = JSON.parse(sessionStorage.getItem(KEY) ?? "[]");
    if (reduced() || seen.includes(typedKey)) { setDone(true); return; }
    sessionStorage.setItem(KEY, JSON.stringify([...seen, typedKey]));   // recorded when typing starts
    const spans = Array.from(el.querySelectorAll<HTMLSpanElement>("[data-g]"));
    const place = (i: number) => {               // put the caret right after grapheme i
      const s = spans[Math.min(i, spans.length - 1)];
      caret.style.translate = `${s.offsetLeft + s.offsetWidth}px ${s.offsetTop}px`;
    };
    let i = 0;
    place(0);
    const id = window.setInterval(() => { i += 1; if (i >= spans.length) window.clearInterval(id); else place(i); }, 50);
    const skip = () => { window.clearInterval(id); place(spans.length - 1); setDone(true); cleanup(); };
    const onKey = () => {                         // only keys aimed at the page or the headline itself
      const a = document.activeElement;
      if (a === document.body || a === el) skip();
    };
    const cleanup = () => { window.removeEventListener("keydown", onKey); el.removeEventListener("pointerdown", skip); };
    window.addEventListener("keydown", onKey);
    el.addEventListener("pointerdown", skip, { once: true });
    return () => { window.clearInterval(id); cleanup(); };
  }, [text, typedKey]);
  return (
    <Tag ref={ref} tabIndex={-1} aria-label={text}                        // focus never skips (§8.0.8)
         className={`typed ${done ? "is-done" : ""} ${className ?? ""}`}>
      {g.map((c, i) => <span key={i} data-g aria-hidden style={{ "--i": i } as React.CSSProperties}>{c}</span>)}
      {tail && <span className="tail" aria-hidden style={{ "--n": g.length } as React.CSSProperties}>{tail}</span>}
      <span ref={caretRef} className="caret" aria-hidden style={{ "--n": g.length } as React.CSSProperties} />
    </Tag>
  );
}
```

```css
.typed { position: relative; }
.typed > [data-g] { display: inline-block; opacity: 0;
  animation: ty-land var(--mm-spring-tick-ms) var(--mm-spring-tick) both; animation-delay: calc(var(--i) * 50ms); }
@keyframes ty-land { from { opacity: 0; scale: 0.8; } 12% { opacity: 1; } to { opacity: 1; scale: 1; } }
.typed .caret { position: absolute; left: 0; top: 0.14em; width: 2px; height: 0.72em; border-radius: 9999px;
  background: var(--mm-color-iris400); box-shadow: inset 0 0 0 0.5px #fff, 0 0 6px rgb(169 155 255 / 0.45);
  transition: translate var(--mm-spring-track-ms) var(--mm-spring-track);
  animation: caret-blink 1060ms steps(1) calc(var(--n) * 50ms) 3 both,
             caret-out 350ms var(--mm-ease-dematerialize) calc(var(--n) * 50ms + 3180ms) forwards; }
@keyframes caret-blink { 50% { opacity: 0; } }
@keyframes caret-out { to { opacity: 0; filter: blur(6px); } }
.typed > .tail { opacity: 0; animation: ty-tail 200ms cubic-bezier(0.2, 0, 0, 1) calc(var(--n) * 50ms) forwards; }
@keyframes ty-tail { to { opacity: 1; } }
.typed.is-done > :is([data-g], .tail) { animation: none; opacity: 1; }
@media (prefers-reduced-motion: reduce) { .typed > :is([data-g], .tail) { animation: none; opacity: 1; } .typed .caret { display: none; } }
[data-motion="reduced"] .typed > :is([data-g], .tail) { animation: none; opacity: 1; }
[data-motion="reduced"] .typed .caret { display: none; }
```

A Playwright check guards the placement that matters most: 200 ms after navigating to `/`, the greeting's 10th grapheme still has computed `opacity` below 0.1 (typing is running, route focus did not skip it), and after 3 s every grapheme is at 1.

The caret is absolutely positioned and moved by `translate` to the right edge of the latest visible grapheme every 50 ms (it glides there on the `track` spring's `linear()` easing), so it works across line breaks and never touches React's child order. Skipping clears the interval, parks the caret after the last grapheme and adds `is-done`, which stops the per-letter animations and shows every grapheme at once; the caret's own blink-and-leave animation is untouched (it keeps its original timing), so nothing restarts and no loop is left running.

**Flutter** (`mobile/lib/skins/glass/primitives/typed_headline.dart`): a `StatefulWidget` with a `Ticker` that sets `visible = min(n, elapsed ~/ 50ms)` and stops itself at `n`; the text is one `Text.rich` whose first `visible` graphemes use the style's colour and whose tail uses `Color(0x00000000)` (layout never changes); each newly visible grapheme is a `WidgetSpan` whose scale animates on the `tick` spring; the caret is a `CustomPaint` capsule positioned from `TextPainter.getOffsetForCaret(TextPosition(offset: visibleCodeUnits), Rect.zero)` and animated on `track`, then three `AnimationController` blinks and a 350 ms blur-out. A `GestureDetector` on the headline (`onTapDown`) and a `Focus` `onKeyEvent` on the headline complete it by setting `visible = n` and disposing the ticker; the headline gaining focus does **not** complete it (`Focus(onFocusChange:)` is not used for skipping). Graphemes past 48 are one tail span that fades in over 200 ms when the ticker reaches 48. The placement key is added to `revealedHeadingsProvider` when the ticker starts; `glassMotionPrefsProvider.reduced` (OS or in-app) renders the plain `Text` at once.

---

## 11. Gesture matrix

Every gesture, where it works, what it does on each platform, and the non-gesture path that does the same thing (WCAG 2.5.1 and 2.5.7: every path-based or multi-point gesture has a single-pointer alternative). Thresholds are in §4.6. "Same" means the iOS behaviour. Desktop web uses the pointer equivalents listed.

| Gesture | Screen(s) | iOS | Android | Mobile web | Desktop web | Alternative |
|---|---|---|---|---|---|---|
| Tap | Everywhere | Activates on release inside the target | Same | Same | Click | Enter / Space |
| Press and hold (150 ms growth, 450 ms bloom) | Posters, rows, cards, orbs, the hero card | Lift preview, then the context menu (§7.23) | Same | Same (`-webkit-touch-callout: none`) | Right-click opens the menu at the pointer (no lift) | `.` or `shift+F10` on the focused item; every row's ⋯ |
| Throw a lifted poster up | Posters, hero card, AI cards | Opens series detail with the throw's velocity; a hard throw lands at `large` | Same | Same | n/a | Tap the poster |
| Throw a lifted AI card sideways | Home and For you AI cards | Not interested (Undo toast) | Same | Same | n/a | ⋯ → Not interested; `Delete` on focus |
| Drag a lifted poster onto a friend orb | Any poster with the Circle on | Recommend to that friend (magnet) | Same | Same | n/a | ⋯ → Recommend to… (sheet) |
| Back swipe | Every pushed page (not Wrapped or onboarding, §8.0.5) | Full-width swipe (readers: leading 20 px edge, strip at 1×; inside a component that owns horizontal drags: leading 24 px only), `threshold.cross` at 50 % | Predictive back (system gesture), the page shrinks to 90 % | Browser/OS swipe in a tab; in an installed iOS PWA, Glass's own leading 24 px edge swipe (§8.0.5) | `alt+←` (browser), the toolbar back chevron | The back button; Esc on desktop |
| Long-press Back | Every pushed page, readers, full-height sheets | Stack overview fan (§7.37) | Same | The back menu (500 ms) | Right-click Back or `mod+\` → the back menu | `mod+\`; the screen-reader custom action "All levels" on every back button |
| Swipe on the dock | Phone dock | Drag the droplet across tabs, ticks per tab; release selects; drag past the last tab merges with the search orb | Same | Same | n/a | Tap a tab |
| Tap the active tab | Dock, sidebar | Pop to root, then scroll to top | Same | Same | Click the active sidebar item | `g` + the section key |
| Long-press a tab | Dock | Home: Updates, Mark all read, Continue; Library: section jump list; Sources: pinned; You: profile switcher | Same | Same | n/a | The same items in each screen's ⋯ and the sidebar |
| Scroll down / up | Every list | Dock minimises after 20 px down, restores after 12 px up | Same | Same | n/a (the sidebar is fixed) | None needed |
| Pull down at the top | Home, Library, Sources, catalogue, Updates, History, Bookmarks, Collections, Circle | Meniscus refresh at 100 raw px | Same | Same (touch only, `overscroll-behavior-y: contain`) | n/a | ⋯ → Refresh; `r` |
| Swipe a row left or right | Notifications, chapter rows, downloads, history, sessions, bookmarks, queue rows, AI cards, Hidden-from-Circle rows | Reveals glass action pills; full swipe past 60 % commits | Same | Same (`pointer: coarse` only) | Hover icons on the row | The row's ⋯; keys `m`, `d`, `Delete`, `u`; VoiceOver/TalkBack custom actions |
| Drag to reorder (450 ms press or the handle) | Source pins, collections, collection members, manual library order, the download queue, profiles | Lift, neighbours part, ticks per slot | Same | Same | Drag the handle with the mouse | `alt+↑/↓`, `alt+shift+↑/↓`; ⋯ → Move up / down / to top / to bottom |
| Drag across items after the first selection | Library grid, chapter lists, downloads (select mode) | Paints a range | Same | Same | Shift-click | `shift+x`; the select-mode assist chips ("Next 10", "All unread") |
| Pinch the grid | Library shelf | Density 2 ↔ 3 ↔ 4 ↔ 5 columns and List | Same | Same | Ctrl/⌘ + wheel over the grid | The Density menu and slider |
| Sheet drag | Every sheet | 1:1, detents by projection, rubber band above the top | Same | Same | n/a (sheets are panels or windows) | The grabber tap cycles detents; `↑`/`↓` with focus; the close button; Esc |
| Swipe down on a sheet | Every sheet | Dismiss past the projection line | Same (predictive back also shrinks it) | Same | n/a | Close button; Esc; browser back |
| Horizontal swipe | In-page pagers (Library sections, Downloads tabs, Updates, catalogue modes, Statistics ranges) | Pages between panels; the indicator slides and stretches | Same | Same (scroll-snap) | Trackpad horizontal scroll | Tap the tab; `[` / `]` |
| Horizontal swipe | Home spotlight | One card per flick, projection | Same | Same | Trackpad horizontal scroll | The spotlight strip, `←`/`→` with focus |
| Tilt the device | Home hero, series band, empty-state lenses, the streak flame, the genre field, the listen artwork | Specular and tilt follow the gyroscope (±25° light, ±6° tilt); the genre field sloshes | Same | Android Chrome: same; iOS Safari: only after "Light follows the device" is turned on, which asks for motion permission from that tap (§8.25.1); otherwise none | Pointer position drives the light; the genre field's gravity follows the pointer | "Light follows the device" off pins everything |
| Vertical scroll | Manga strip | Native momentum, `BouncingScrollPhysics`; chrome hides after 24 px, shows after 56 px | Same | Same | Wheel, trackpad, Space | `j`/`k`, Page Down |
| Tap | Manga strip | Toggles chrome (or tap-to-scroll bands when enabled) | Same | Same | Click | `m` |
| Tap bands | Manga paged, novel paged, guided view | Previous · Menu · Next (30 / 40 / 30; novels 25 / 50 / 25), mirrored for RTL | Same | Same | Click the bands | `←`/`→`, `j`/`k`, Space |
| Double tap | Manga reader, image viewer | Zoom 1× ↔ 2× (viewer 2.5×) at the point | Same | Same | Double-click | `=` / `-` / `0` |
| Pinch | Manga reader (strip 1× to 3×; paged 1× to 4×), image viewer (1× to 4×) | Focal-point zoom with rubber band | Same | Same (`@use-gesture/react` `usePinch`) | Trackpad pinch; Ctrl/⌘ + wheel | `=` / `-` / `0` |
| Pinch | Novel reader | One text-size step per ×1.15 | Same | Same | Trackpad pinch | `=` / `-` / `0`; the Aa sheet |
| Pinch out | Guided view | Page overview with numbered panels | Same | Same | Trackpad pinch out | The counter pill's overview button |
| Drag the trailing edge | Manga reader | Scrub rail with the magnifier lens; while cruising it changes speed | Same (the rail's thumb band is excluded from system back) | Same | Hover the rail, drag with the mouse | Tap the page readout for the go-to popover (§8.14.2); `g` |
| Long-press text | Novel reader | Native selection plus the Copy · Bookmark · Play from here · React · Recommend menu (§8.15.3) | Same | Same | Select with the mouse; right-click or `shift+F10` opens the menu | `b` bookmarks the paragraph at the reading line; the chapter's ⋯ |
| Drag the left edge (12 % band) | Manga reader, portrait phones | Brightness 20 to 100 % with a HUD (the band starts at x ≥ 24 px) | Same (only its middle 200 dp is excluded from system back) | n/a (web has no edge band) | n/a | The reader settings' brightness slider |
| Pull past the chapter end or start | Manga reader (one at a time), novel reader | Rubber band; arms at 48 px, commits at 72 px; momentum carries into the next chapter | Same | Same | Wheel past the end shows the card; click "Read next" | `l` / `h`; the Next card; the bottom capsule's next button |
| Swipe sideways | Manga strip (opt-in) | Changes chapter past 96 px, stiffer rubber band | Same | Same | n/a | `h` / `l` |
| Swipe horizontally | Guided view | Next or previous panel with velocity into the camera | Same | Same | n/a | `→`/`←`, `j`/`k`, Space, the side bands |
| Swipe down | Guided view, image viewer, Wrapped | Exit guided view / dismiss the viewer / close Wrapped | Same | Same | n/a | The close button; Esc |
| Drag the page | Novel paged (Slide or Lift) | The turn follows the finger; projection decides | Same | Same | Click the bands | `←`/`→`, Space |
| Vertical drag on the cruise pill | Manga reader, novel scroll mode | Speed up/down, 8 px per 0.05×, magnet at 1.0× | Same | Same | Drag with the mouse | `<` / `>` |
| Flick while cruising | Manga strip | The coasting velocity sets the cruise speed when it falls into range | Same | Same | n/a | `<` / `>` |
| Touch the strip while cruising | Manga strip | Stops under the finger; resumes 800 ms after release | Same | Same | Mouse down on the strip | `p` |
| Middle-click | Manga reader | n/a | n/a | n/a | Autoscroll anchor (12 px dead zone, 10 px/s per px) | Cruise |
| Swipe the mini player | Listen mini player (bottom accessory) | Left/right: previous/next chapter; down: stop narration (Undo) | Same | Same | n/a | The player's buttons; `h`/`l`; `p` |
| Vertical drag on the speed dial | Listen full player | 0.5× to 3.0× in 0.05 steps, magnet at 1.0×, hold resets | Same | Same | Drag with the mouse; wheel over the dial | `<` / `>`; the preset chips |
| Flick the voice orbit | Voice picker | Card by card with projection; the centred voice introduces itself | Same | Same | Trackpad horizontal scroll | `←`/`→`; the grid view |
| Shake the phone | Listen with the sleep timer running and "Shake to extend" on | +5 min | Same | n/a | n/a | The sleep menu |
| Hold 300 ms and slide | Reaction button | Blooms six bubbles; slide to choose; release sends in an arc | Same | Same | n/a (click opens the picker) | `shift+Enter`, arrows, Enter; `1`–`6` |
| Swipe the Continue stack left | Home, Library | Reveals the "Previously on" pill | Same | Same | n/a | ⋯ → Previously on; `p` |
| Swipe up / down on the recap deck | Recap | Next card / previous card | Same | Same | n/a | Tap the halves; `→`/`←`, Space |
| Tap thirds, hold, swipe | Wrapped | Right two-thirds next, left third previous, hold pauses, horizontal swipe moves, down closes | Same | Same | Click the thirds | `←`/`→`, Space, Esc; the visible buttons with a screen reader or keyboard |
| Drag across a chart | Statistics | Scrubs days with a readout and ticks | Same | Same | Hover | Arrows with focus; Show as table |
| Tap, drag, long-press on genre bubbles | Onboarding step 4 | Like / love / reset; long-press = not for me; drag flings | Same | Same | Click; right-click = not for me | Arrows, Space, `x` |
| Drag a profile orb | Profile picker | Follows the finger and springs home (delight only) | Same | Same | Drag with the mouse | none needed |
| Swipe a card sideways | Stack overview | Removes that level and all above | Same | n/a (web uses the menu) | n/a | `Delete` on the focused card |
| Drag the toast | Toasts | Flick up or sideways dismisses; drag down holds it | Same | Same | Hover pauses | Toast action buttons; the toast stays while a screen reader is on |
| Volume keys | Manga reader (setting) | n/a | Page up/down | n/a | n/a | Tap bands |

---

## 12. Brand assets

### 12.1 Wordmark

**"Stack", Glass rendition, with a meniscus.** "Manhwa" above "Maniacs", flush left, leading 0.84, so the two capital M's stack into the **MM column**; the lowercase in Google Sans Flex `ROND 100`, `wght 620`, tracking −0.020 em, in Frost `#F5F7FA`.

- **The MM column:** the two M's are joined by the gutter bar; in Glass the column is a glass capsule (corner radius 40 % of its width) with the M's engraved (inner shadow `rgba(0,0,0,0.45)` 2 px, specular edge `rgba(255,255,255,0.55)` along the top-left), and the **gutter bar is a meniscus**: a clear refractive seam that bows 2 px (at 64 px cap height) downward in the middle, as if a film of liquid held the two panels together. Geometry follows the 1024 master: box x 240–784, y 192–832; top M y 192–480; bar y 480–544; bottom M y 544–832; stroke 88 units.
- **Single-line fallback** (sidebar, tight headers): "ManhwaManiacs" in Google Sans Flex `ROND 100` `wght 640`, with the two M's in `iris400`.
- **Clear space:** twice the gutter bar's thickness on every side. **Minimum sizes:** stacked lockup 28 px tall; single line 12 px cap height; MM column alone 16 px (below 32 px it drops the engraving and becomes a flat Frost silhouette with the meniscus as a gap).
- **Never:** recolour the lowercase, add effects to the lowercase, set it on a busy image without the `dimClear` layer.

### 12.2 App icon

**"MM Column", Glass rendition.**

- **Field:** a vertical gradient `#0A0F1F` → `#000000`, with an aurora of three blobs, `#8FD8FF`, `#A99BFF` and `#FF9ED8`, at 45 % opacity and 180 px blur (on the 1024 canvas), concentrated in the lower-left third so the column's glass has colour to bend. Blob centres and radii on the 1024 master (origin top-left): `#8FD8FF` at (240, 700), r 260; `#A99BFF` at (420, 860), r 300; `#FF9ED8` at (160, 940), r 220; each a radial gradient from its colour at the centre to transparent at r, before the 180 px blur.
- **Mark:** the MM column (§12.1 geometry) built as **three separate glass slabs**, so system lighting acts on each: the **bottom M** (deepest), the **gutter bar** (the middle layer, kept as Meniscus's meniscus: a clear refractive seam that bows 2 px at 64 px cap height, 16 units on the 1024 master, downward in the middle), and the **top M** (nearest, with a specular edge `rgba(255,255,255,0.55)` along its top-left). Each slab has a 0.5 px rim and refracts the aurora behind it.
- **iOS 26 (Icon Composer):** an `.icon` bundle (`icon.json` + `Assets/`) with a background layer (the field) and **three foreground layers** in this order: `bottom-m.svg`, `gutter-bar.svg`, `top-m.svg`; each layer has Liquid Glass on, translucency 0.5, specular on, and a neutral shadow; the bar layer is set to clear so its meniscus bends the field. Default, dark, clear and tinted appearances come from the layers (tinted: the three layers as a grayscale silhouette). Compiled on the CI runner with `actool`; the PNG set is the fallback for iOS 18 and earlier: 1024 opaque master, iOS 18 dark (transparent background, the mark only) and tinted (grayscale mark) through `flutter_launcher_icons` 0.14.4 (`image_path_ios_dark_transparent`, `image_path_ios_tinted_grayscale`).
- **Android:** adaptive icon on a 108 dp canvas: background = the field, foreground = the three slabs flattened inside the 66 dp safe circle (a 160 × 188 px box at xxxhdpi), monochrome layer = the column silhouette for Android 13 themed icons.
- **Web:** `favicon.svg` (the column silhouette in Frost `#F5F7FA`; below 32 px a single M on the bar), `favicon.ico` 32/16, `apple-touch-icon.png` 180 opaque on the field, PWA `icon-192.png` / `icon-512.png` and `maskable-512.png` with the mark inside the 40 % radius safe circle.
- **Per skin:** Glass and Cinematic both ship an icon. "App icon follows the skin" is **off by default** (§8.25.1), and when on, the icon changes only when the skin is chosen explicitly on this device, never on a profile switch or the boot-time mismatch restart (as `cinematic/DESIGN.md` §12.3 does), so a device shared by profiles of both skins does not show iOS's icon alert on every switch. `flutter_dynamic_icon_plus` 1.4.1: iOS `setAlternateIconName("GlassIcon")` inside the restart moment (the system's one-line alert lands over the black); Android toggles `activity-alias` components (`.GlassIcon` enabled, `.CinematicIcon` disabled, `PackageManager.DONT_KILL_APP`) **queued until the app next goes to the background**, never inside the 1.5 s restart, because a component toggle can end the task; the switch's caption warns "Home-screen shortcuts to the old icon stop working." The web swaps `<link rel="icon">` to the active skin's SVG (the server knows `mm-skin` when it renders `<head>`), but the **PWA manifest and its icons are shared and skin-neutral** (`cinematic/DESIGN.md` §12.3): the browser fetches the manifest without cookies unless it is linked with `crossorigin="use-credentials"`, and an installed PWA never re-reads its icons, so a per-skin manifest could not work.

### 12.3 Splash

- **Native layer (shared by both skins, owned by the skin engine):** it runs before Flutter can read which skin is active, so it shows **no mark**: a plain `#000000` frame (`flutter_native_splash` 2.4.8: `color: "#000000"` with no `image`; iOS LaunchScreen storyboard black; Android 12+ `android_12: { color: "#000000", icon_background_color: "#000000", image: "brand/splash/transparent-288.png" }`, a fully transparent 288 × 288 PNG, so the system splash shows no icon). This replaces any single-skin mark in the native layer, because a native frame showing one skin's mark would flash the wrong brand for the other skin's users (§15.6). The web needs no neutral frame: the server knows the skin from the `mm-skin` cookie and server-renders Glass's mark as inline SVG on black.
- **Handoff:** the first Flutter frame (or the hydrated web root) draws Glass's **neutral mark**, the MM column flat in Frost `#F5F7FA` at 96 px tall, centred, fading in over 120 ms from the black native frame, then plays the Droplet reveal (§12.4). On a skin-switch restart the full reveal always plays.

### 12.4 Logo reveal motion: "Droplet" (physics version)

Cold start 1,200 ms; warm start (resumed within 4 h) 400 ms; tap anywhere skips to the handoff.

| t (ms) | Element | Motion |
|---|---|---|
| 0 | Neutral mark | The mark's ink drains into a 24 px glass droplet at 180 px above centre (opacity cross-fade 120 ms) |
| 0–200 | Droplet falls | Free fall under gravity 9,000 px/s² (the 180 px drop takes 200 ms and lands at 1,800 px/s) |
| 200 | Impact | The droplet squashes to scaleX 1.25 / scaleY 0.80 and recovers on `lens`; a ripple ring (1 px rim, radius 0 → 140 px, opacity 0.30 → 0 over 500 ms) spreads across the ambient field; `logo.land` haptic (`droplet`); the `droplet` sound when enabled |
| 200–700 | Lens grows | The droplet grows into a 128 px squircle lens (corner 28 %) on a spring (k 180, c 22); inside it the MM column is refracted into view: displacement 40 → 0 px, chromatic aberration 3 → 0 px |
| ~700 | Settle | The lens settles; `logo.settle` haptic (`splash`); the `logo` arpeggio when sounds are on |
| 500–1,000 | Wordmark | "Manhwa" / "Maniacs" letters rise from behind the lens with the heading reveal (24 ms stagger, k 220 / c 26, blur 16 → 0) |
| 1,000–1,200 | Handoff | The lens morphs into its destination on `zoom`: the dock capsule (signed in), the picker's central orb (choosing a profile), or Login's lens (signed out); the wordmark fades |

Warm start: the lens materialises (250 ms) and hands off (150 ms), no fall, no letters, no haptic. Reduce Motion: a 200 ms cross-fade from the neutral mark to the destination, one `light` haptic. Web: Motion springs and SVG `feDisplacementMap` refraction (Chromium; frosted elsewhere); Flutter: `SpringSimulation` for the fall and the lens, `liquid_glass_widgets` for the lens, per-glyph `ImageFiltered` for 13 letters.

### 12.5 Voice and screenshots

- **Voice:** calm and plain, no exclamation marks: "Continue", "Up next", "You're caught up", "Previously on", "It's been 3 weeks".
- **Showcase set ("Float")**, 5 frames at 1320 × 2868 (a 440 × 956 CSS viewport at DPR 3 through Playwright): Home ("Every source. One shelf."), manhwa reader ("Built for the long scroll."), novel + listen ("Novels, read aloud." / "31 named voices"), Wrapped ("Your year in chapters."), Circle ("Read together."). Each capture sits on a glass slab (radius 88, 1.5 px inner highlight, shadow `0 60px 120px rgba(0,0,0,0.6)`, tilted `rotateY(-8deg) rotateX(4deg)`) over the aurora field; captions in Google Sans Flex `ROND 100` `wght 660` 112 px Frost. Seeded demo profile only, no 18+ content, self-made placeholder covers.

### 12.6 Other brand assets and the asset pipeline

- **App display name** and the SideStore listing are shared by both skins (one app bundle); Glass changes only the icon and, on Android, the notification colour.
- **Android notification small icon** (narration lock-screen and download notifications through `audio_service` 0.18.19): `ic_stat_mm` (the column silhouette, white on transparent, 24 dp, `res/drawable-{mdpi…xxxhdpi}/ic_stat_mm.png`), shared with Cinematic; the accent colour is set at runtime from the active skin (Glass: `iris600` `#7563F2`).
- **Web Open Graph image:** Glass ships none. Link-preview crawlers send no cookies, so a Glass-only `/og-glass.png` chosen by `mm-skin` would never be seen; the one static OG image is the shared `frontend/public/og.png` (`cinematic/DESIGN.md` §12.6), which the public install page also serves.
- **Public install page** (`GET /` on the app subdomain: install steps, screenshots, changelog; `capabilities.md` §23) is skin-neutral and owned by `cinematic/DESIGN.md` §8.34, because it is served by the backend before any skin or profile exists. Glass adds nothing to it; its Glass screenshots (§12.5) may be added to that page's gallery once `flags.glass_available` is true.
- **Screenshot set:** §12.5.
- **Custom glyphs:** the geometry of every custom glyph is in §2.7.
- **Pipeline.** Masters as SVG in `brand/glass/` (the three icon layers, the field, the wordmark lockups, the neutral mark, the favicon, the custom glyphs, the droplet texture); one export script `brand/glass/export.mjs` (Node 22, `@resvg/resvg-js` 2.6.2) renders every PNG size; `flutter_launcher_icons` 0.14.4 and `flutter_native_splash` 2.4.8 consume them; the Icon Composer `.icon` bundle lives in `mobile/ios/Runner/AppIcon-Glass.icon/`; a check script (`brand/check.mjs`) asserts sizes, no alpha on the iOS 1024 master, the mark inside the Android 66 dp and PWA 40 % safe circles, and that every glyph in §2.7 exists in all three weights.

### 12.7 Asset brief (art someone has to make)

Nothing here may be publisher art, a real series' cover or a real series' name; everything is CC0 or the project's own, credited in About → Licences.

| Asset | Count and size | Brief | Produced by | Needed by (§15.9) |
|---|---|---|---|---|
| **Art-style crops** (§8.7 step 5) | 9, 320 × 320 WebP, sRGB, under 40 KB each, in `brand/onboarding/styles/` | One panel crop each, all showing the same subject (a young swordsman looking over his shoulder at a city at dusk) so only the style differs: (1) full-colour webtoon painting: soft cel base, painted light, saturated teal-orange palette, no line art on the background; (2) crisp cel shading: 2-tone shadows, 3 px black line, flat bright colours; (3) black-and-white screentone: 2 px ink line, dot tone at 20 % and 40 %, pure white paper; (4) manhua 3D/CG: rendered figure, rim light, depth-of-field background; (5) watercolour: wet edges, paper texture, muted blues and ochres, 1 px pencil line; (6) sketchy indie: loose 1–3 px graphite line, 2 flat spot colours; (7) retro 1990s: thick 4 px line, airbrushed gradients, pastel sky; (8) chibi comedy: 3-head-tall proportions, 3 px round line, candy palette, a sweat-drop symbol; (9) dark realism: heavy blacks, 1 px hatching, desaturated reds | The owner draws them or commissions them; a generated draft may be used only if its licence allows CC0 release and nothing in it imitates a named artist | Step 7 (onboarding ships with the new features) |
| **Demo covers** (showcase, screenshots, skin previews, onboarding seed fallback) | 24, 2:3 at 720 × 1080 WebP, in `brand/demo/covers/` | Invented titles only (for example "The Ninth Regression", "Salt and Iron", "Moonlit Bakery"); title set on the cover in any display face with a 64 px margin, 2 to 4 words, never a real series' name or look; a spread of palettes (6 warm, 6 cool, 4 dark, 4 pale, 4 greyscale) so the ambient field, the legibility dim and the page tint are exercised; 2 of the 24 are pure white-dominant covers (the §2.1.7 worst case); no nudity or gore | The owner, or the same source as the style crops | Step 4 (the Home and Library screenshots need them) |
| **Demo pages** (the reader screenshots and the checkerboard-adjacent reader tests) | 40 webtoon pages, 800 px wide, 1,200 to 3,000 px tall, in `brand/demo/pages/` | One invented 2-chapter story drawn in the style of crop 1, with at least 6 speech bubbles per chapter (for dialogue overlay and hit-lens captures), 2 all-white panels and 2 near-black splash pages (for the dim and the page tint) | As above | Step 5 |
| **Skin previews** (§8.7, §8.25.1) | 2 animated WebP, 360 × 780, under 900 KB, 6 s loop, plus 2 stills `skin-{id}-still.png` | Captured by the screenshot harness from the seeded demo profile with the demo covers | CI (the Playwright harness) | Step 6 (Settings) |
| **Soundscape recordings** (§9.4.2) | 18 files | CC0 field recordings from freesound.org with each file's URL and licence in `SOURCES.md` | The owner picks, the pipeline trims and loops | Step 7 |

---

## 13. Signature moments

Twenty-eight moments where the physics and the light are the product. Each is specified where it lives; this list is the index and the essence, with the feel (haptic, sound) and the Reduce Motion version.

| # | Moment | Where | Essence | Feel | Reduce Motion |
|---|---|---|---|---|---|
| 1 | **The Droplet** | §12.4 | The app starts with a drop falling under gravity, splashing into the ambient field and swelling into a lens that becomes the dock | `logo.land`, `logo.settle`; `droplet`, `logo` | 200 ms cross-fade |
| 2 | **Step into the light** | §8.5 | Choosing a profile inflates its orb and repels the others like drops; its colours pour into the field; the orb flies into the dock and the app forms around it | `profile.select` | Cross-fade to Home |
| 3 | **Light follows the story** | §8.8, §2.1.8 | Paging the Home spotlight slides the field, every glass rim and the dock droplet to the new cover's colours over 900 ms | none | 200 ms cross-fade |
| 4 | **Throw to open** | §7.8, §8.12 | Lift a poster, flick it upward, and the series sheet opens with the flick's velocity; a hard throw lands at the large detent | `throw.commit`; `throw` | Tap opens with a fade |
| 5 | **The cover becomes the room** | §8.12, §2.4.4 | The thrown cover lands in the sheet while its palette lights the field; following sends a caustic ring across the band | `follow.add`; `add` | No ring |
| 6 | **The liquid dock** | §7.15 | Drag across the dock and the selection droplet follows, stretches with speed, ticks under each tab, and merges with the search orb like two drops touching | `nav.scrub`, `nav.change` | Selection jumps |
| 7 | **Minimise, don't vanish** | §7.15, §8.14.2 | Scrolling down shrinks the dock (and the reader's capsule) into a pill that carries the accessory inline; reversing mid-morph reverses it with momentum | none | Instant swap |
| 8 | **Deeper sounds higher** | §7.37, §5.1, §6 | Every push lands a scale step higher and a little heavier (`I = 0.30 + 0.08 × depth`); a pop glides back down | `nav.push`, `nav.pop`; `push-1`…`push-4`, `back` | Same (sound and haptics are not motion) |
| 9 | **The stack you stand on** | §7.37 | Long-press Back and the levels you came through fan out in 3D (the web lists them); tap one to fall back to it | `stack.open`, `stack.pick`; `fan` | A flat list |
| 10 | **The meniscus refresh** | §7.33 | Pulling a list stretches a droplet on a thinning neck until it snaps free at the trigger | `refresh.arm`; `droplet` | Static spinner |
| 11 | **The lit action** | §2.4.4 | The one tinted action per screen throws a caustic of light onto the art beneath it, brightening under the finger | `tap.primary`; `tap` | No caustic change |
| 12 | **Surface from depth** | §8.9 | Slow sources' results rise from behind the page in the order they answer; nothing already on screen moves | none | Fade |
| 13 | **The scrub lens** | §8.14.2 | The reader's edge rail grows a glass magnifier showing the target page, with a tick per page that thins into a grain at speed | `scrub.tick`, `scrub.boundary` | Lens without growth |
| 14 | **Momentum through the chapter end** | §8.14.4 | A fling at the end of a chapter rubber-bands, raises the next-chapter card, locks it with a click, and the next chapter begins already scrolling at the fling's remaining speed | `chapter.arm`, `chapter.next`; `chapter` | Card at the lock, fade, no momentum |
| 15 | **The room takes the page's light** | §9.4.4, §8.14.11 | The capsules take the colour of the page under them, darken and thicken their labels over white panels, and on desktop the gutters glow with the page's top and bottom colours | none | 200 ms cross-fade (§4.11) |
| 16 | **Rain on glass** | §9.4.2 | With the Rain scene on, droplets run down the reader's glass capsules and the minimised pill, refracting the page | none | Off |
| 17 | **Flick to cruise** | §9.4.1 | A flick sets the auto-scroll speed; the flywheel engages when the coasting velocity falls into range and holds it | `autoscroll.start`, `autoscroll.step` | Manual start, no ramp |
| 18 | **The panel camera** | §9.4.3 | Swipes glide the camera between panels with velocity carried into each glide, and the lens edge shows the next panel as a refracted sliver before it arrives | `panel.step` | Cut with a fade |
| 19 | **The hit lens** | §8.14.9 | A small glass lens slides from speech bubble to speech bubble, magnifying each matched line | `ocr.hit` | Lens appears in place |
| 20 | **The book opens** | §8.13 | The plate rotates open on its spine while the paper expands into the reader; paged turns lift like panes of glass | `reader.enter`, `page.turn`; `dive` | Cross-fade |
| 21 | **The voice orbit and the speaking orb** | §8.16 | 31 voices on a carousel with depth introduce themselves when they come to rest; while narrating, each speaker's colour flows into the voice orb | `voice.center`, `voice.assign` | Orb colour swaps |
| 22 | **The speed dial magnet** | §8.16.3 | Narration speed moves in fine detents, and 1.0× pulls you in with a firm click | `detent.tick`, `detent.magnet` | Same |
| 23 | **Recommend by dropping** | §9.3.4 | Drag a lifted poster to a friend's orb; the orb swells and pulls it in like a magnet, then swallows it | `magnet.capture`, `magnet.drop`, `recommend.send`; `send` | Menu path |
| 24 | **The reaction arc** | §9.3.2 | Hold to bloom six named reactions, slide to choose, and the reaction flies in a ballistic arc into the chapter's strip | `reaction.bloom`, `reaction.cross`, `reaction.send`; `pop` | Appears in the strip |
| 25 | **Presence has depth** | §9.3.1 | The people reading right now drift to the front of the Circle's arc with a breathing bloom ring | none | Placed without drift |
| 26 | **The recap deck** | §9.1.3 | "Previously on" as four cards in depth that you lift off one by one while the words stream in, under the machine light | `recap.ready` | Cross-fade between cards |
| 27 | **The streak flame and the goal ring** | §9.2.2 | A flame whose tip leans against the phone's tilt and the page's acceleration, flares with embers on +1, sparks on a record, and a ring around your orb that closes when today's goal is met | `streak.extend`, `streak.milestone`, `goal.met`; `shimmer` | Counts and toasts only |
| 28 | **The card flips to share** | §9.2.4 | Export lifts the Wrapped card and flips it to its share side, composed for Story or Post | `share.lift`, `share.flip`, `share.export`; `flip` | Cross-fade |

The genre field (§8.7 step 4), dealt answers (§9.1.2), the droplet melt on leaving Glass (§8.25.2) and the fanned collection (§8.18) are smaller moments of the same family.

---

## 14. Accessibility and reduced-motion rules

These rules bind every screen; the per-screen specs assume them.

### 14.1 Reduced motion

- The OS setting and the in-app "Reduce motion in this app" switch both apply (§4.11). The last column of the motion table (§4.10) is the replacement for every named move; §4.11 lists the rules that apply everywhere. The finger still owns what it touches: drags, scrubs, back swipes, sheet drags, pinches and reorders track 1:1.
- Nothing loops under Reduce Motion except progress indicators (as static pulses) and user-started cruise.
- Auto-advancing content (Wrapped cards, the recap pill's 6 s, toasts) keeps its timing, stops while touched, hovered or focused, and stops completely while a screen reader is on.

### 14.2 Contrast

- Text on black and slabs uses `label1` (≥ 14:1), `label2` (≥ 6.3:1) and `label3` (≥ 4.6:1 at 13 px and larger); `label4` and `g500` are never informational. `g600` meta text is used only at 15 px and larger (4.12:1 on `surface1`).
- Text on glass is always `onGlass` or `onTint`, never alpha text; the legibility dim and the label grade keep it at ≥ 5.14:1 over a pure white page and white on the tinted action at ≥ 4.66:1, and the `edgeSoft` plateau keeps bar labels over scrolling content at ≥ 8.8:1 over pure white (§2.1.7).
- Every semantic colour passes 4.5:1 as text on black and as black text on its solid chip (§2.1.4); speaker tints are ≥ 9.7:1 (§2.1.5); the four lights are ≥ 8.8:1 (§2.1.9).
- `design/check-contrast.mjs` recomputes every text/background pair of `design/tokens/glass.json` on every build (§15.8) and fails CI below 4.5:1 (3:1 for text 24 px and larger, and for focus rings and non-text UI).

### 14.3 Colour is never the only signal

- Status pills carry their word; download states carry a glyph and an accessible name (§7.29); unread carries a dot **and** a bar; the 18+ badge carries "18+"; speaker tints carry an underline style (solid or dashed); reactions carry their names in the picker and in the accessible names; the machine light always comes with the sparkle glyph and "suggested by AI" in the accessible name; people light always comes with an orb or a name.
- Charts carry a summary sentence and "Show as table" (§7.39).

### 14.4 Keyboard and focus

- Every interactive element is reachable by keyboard on the web and with a hardware keyboard on iPad and Android tablets (the same key map through Flutter `Shortcuts` and `Actions`). Focus order follows reading order; rails and grids are roving-tabindex groups; the sidebar is a `nav` landmark.
- The focus ring (`focusRing`: a 2 px black inner ring, then 2 px `iris300` at 2 px offset, with a 6 px glow; 3 px `iris300` under Increase Contrast) keeps 3:1 over black, slabs, glass and white pages alike (§2.6), follows each element's radius and is never clipped (rails pad 8 px vertically; `scroll-padding-block` equals the floating chrome insets so focus never lands under a bar, WCAG 2.4.11).
- After a route change focus moves to the new `h1`; after a pop it returns to the element that pushed; sheets, menus, alerts and the palette trap focus and return it on close (§8.0.8).
- Single-key shortcuts can be turned off (Settings → Shortcuts, WCAG 2.1.4); no shortcut fires while typing unless marked `allowInInput`.
- A "Skip to content" `glassThin` capsule appears top-left on the first Tab.

### 14.5 Screen readers

- Letter and typing reveals expose the full text from the first frame (§10.1, §10.2); animated spans are hidden from the tree.
- Toasts are `role="status"` (errors `role="alert"`) and stay until dismissed while a screen reader is on; Flutter uses `SemanticsService.sendAnnouncement`.
- The reader announces chapter changes ("Chapter 144") but not page changes; chrome never auto-hides while a screen reader is on; the scrub rail is a slider with `aria-valuetext="Page 18 of 40"`.
- **Manga pages** have a text alternative when the chapter has OCR text: each page's accessible description is its recognised dialogue in reading order ("Page 18. Dialogue: …"); without OCR the description is "Page 18 of 40".
- **Voice samples:** when a voice introduces itself, its transcript (from `GET /novels/voices` `transcript`) shows under the card as a caption in `footnote` `label2` and is read by the screen reader.
- Swipe rows, reorderable rows and reaction strips expose custom actions (VoiceOver rotor / TalkBack actions via `Semantics(customSemanticsActions:)`; the web offers the same actions in the row's ⋯ menu).
- The stack overview reads as a list of levels; Wrapped exposes previous, pause and next buttons and each card as a region; the recap deck reads as one list with four headings.
- Custom widgets keep standard roles: the dock is a tab list (§7.15), the Home spotlight a carousel (§8.8), the genre bubbles buttons with state in their names and custom actions (§8.7), the presence arc a list read front to back (§9.3.1), the speed dial a vertical slider (§8.16.3).
- Hidden reader chrome is inert, and locked mode has an "Unlock controls" custom action and the `u` key (§8.14.2).

### 14.6 Touch targets

- Every hit area is at least 44 × 44 px (iOS and web) and 48 × 48 dp (Android), whatever the visual size: chips (32 visual) pad to 44, row icons (32 visual) to 44, the scrub thumb's hit strip is 44 wide, the download control 44.
- Adjacent targets keep at least 8 px between hit areas, or merge into one glass group with separate 44 px cells.

### 14.7 Text size and legibility

- iOS Dynamic Type and Android font scale apply to every role with the caps of §3.3; from AX1 up list rows stack, from AX2 up grids drop to 2 columns and rails show 1.6 posters; the reader chrome keeps fixed sizes and moves secondary controls into the settings sheet so capsules never wrap. The web uses `rem` everywhere, so browser zoom and text size scale the whole interface up to 200 % without horizontal scrolling (except the members table, in its own scroll container).
- Bold Text adds `wght + 100` (and `GRAD + 20` on glass).
- **Legible text** swaps the UI to Atkinson Hyperlegible Next (§3.6); the novel reader offers it as a reading face.
- Screens are checked at text scales 1.0, 1.3 and 2.0 on both phones, and with Legible text on.

### 14.8 Every gesture has an alternative

The gesture matrix (§11) lists a single-pointer or keyboard alternative for every gesture: throws, magnets, pinches, swipes, holds, tilts, shakes, long-presses and drags. Hold-to-confirm (§7.1) always has an explicit confirm button for keyboard and screen-reader users.

### 14.9 Haptics and sound

- Every haptic is paired with a visible change; haptics can be turned off (per device); they stay on under Reduce Motion.
- UI sounds are off by default, never carry information alone, follow the iOS silent switch (the `idle` audio state, §6), never play during narration or a soundscape, and never duck the user's music.
- Voice previews never auto-play while a screen reader is on (§8.16.4), and no clip longer than 3 s plays without a visible stop control.

### 14.10 Flashing and motion sickness

- Nothing flashes more than three times in any one second; the only flicker is the source-health bead's single 120 ms dip and the streak flame's 5 Hz tip noise of 2 % amplitude (below any flash threshold).
- Parallax and tilt are at most ±6° (cards) and ±25° (light), and stop under Reduce Motion or with "Light follows the device" off.
- Cruise never starts on its own under Reduce Motion; the camera in guided view cuts instead of gliding.

### 14.11 Content safety (18+)

- Mature content is governed by absence (§7.25): with the gate closed it does not exist in any list, count, search, feed, recap, ambient field, share card or notification, including local copies (§8.0.8).
- Turning the gate on always requires the explicit confirmation (hold, or the explicit button for keyboard and screen-reader users).
- Share cards never draw mature covers or titles, whatever the gate.
- **Gate-close checklist** (the accessibility pass runs it per cluster on both clients, with a profile that has downloads, bookmarks, history, recent searches, a narration in progress, a cruise, a soundscape, a pending recap and a mature series open in a second tab's stack; then closes the gate, and separately switches to a gate-closed profile): (1) narration, cruise and the soundscape stop and the accessory leaves; (2) the pending "Recap ready" toast never appears; (3) every tab whose top route was mature is at its root; (4) the Flutter stack overview and the web back menu show no mature level; (5) recent searches typed with the gate open are gone; (6) no mature cover appears anywhere, including the image viewer's cache and the ambient field; (7) Home, Statistics, Wrapped, the recap and the Circle, opened offline, show their offline states, not the old copies; (8) Downloads, its counts and the storage meter show none of it and say nothing about it; (9) reopening the gate brings all downloads back untouched.

---

## 15. Implementation notes

For `stack-decision.md`: Next.js 16 + React 19 + Tailwind 4 + Motion 13 on the web, Flutter 3.44.6 on iOS and Android, per-skin screen folders on the shared data layer, one token source, restart on skin switch.

### 15.1 The token source: `design/tokens/glass.json`

Everything in §2 to §6 lives in one JSON file that `design/build.mjs` turns into CSS variables, TypeScript numbers and Dart constants (the name rules are §2.8 and §3.7). One schema: every key of §2.8 is a path in this file. An excerpt of its shape:

```json
{
  "color": { "g0": "#000000", "g100": "#131317", "label1": "#F2F2F7", "label2": "rgba(235,235,245,0.64)",
             "iris400": "#A99BFF", "iris600": "#7563F2", "machine": "#5CE1E6", "bloom": "#FF9ED8",
             "success": "#3DDC84", "mature": "#FF5C93",
             "mood": { "romantic": "#FF7AA8", "default": "#4336A3" },
             "paper": { "void": { "page": "#000000", "ink": "#D9D6D0", "muted": "#8A877F" } } },
  "space": { "s0": 0, "s4": 8, "s5": 12, "s6": 16 },
  "layout": { "dockHeight": 64, "dockMinimized": 50, "sidebarWidth": 280, "readerPanelLeft": 300 },
  "radius": { "capsule": 9999, "md": 14, "xl": 26, "sheet": 36 },
  "glass": {
    "t2": { "thickness": 20, "bezel": 10, "displacement": 10, "blur": 8, "saturate": 1.8, "fill": "rgba(255,255,255,0.07)",
            "specular": 0.42, "shadow": "0 6px 20px rgba(0,0,0,0.45)", "dispersion": 0, "rond": 40 },
    "t4": { "thickness": 40, "bezel": 18, "displacement": 18, "blur": 22, "saturate": 1.8, "fill": "rgba(28,28,34,0.52)",
            "specular": 0.30, "shadow": "0 24px 64px rgba(0,0,0,0.60)", "dispersion": 0.6, "rond": 80 },
    "tinted": { "fill": "rgba(117,99,242,0.86)", "fillPressed": "rgba(91,74,209,0.86)", "rim": "rgba(255,255,255,0.30)" },
    "snap": [36, 57, 97, 401]
  },
  "dim": { "legibility": { "min": 0.22, "slope": 0.42, "max": 0.64 }, "grad": { "slope": 40 },
           "edgePlateau": 0.72, "edgeFade": 24 },
  "spring": { "format": "physical",
              "track": { "ms": 150, "bounce": 0.14 }, "press": { "ms": 220, "bounce": 0.2 },
              "sheet": { "ms": 480, "bounce": 0.08 }, "page": { "ms": 520, "bounce": 0 },
              "letter": { "ms": 424, "bounce": 0.12 }, "smooth": { "ms": 500, "bounce": 0.1 } },
  "curve": { "fadeIn": { "ms": 180, "bezier": [0.2, 0, 0, 1] }, "tintShift": { "ms": 900, "bezier": [0.2, 0, 0, 1] },
             "dimShift": { "ms": 400, "bezier": [0.2, 0, 0, 1] } },
  "physics": { "decelerationRate": 0.998, "rubberBandC": 0.55, "magnetRadius": 64, "waveSpeed": 1.6,
               "waveMaxDelay": 240, "hapticMinInterval": 40, "impactVelocityDivisor": 4000,
               "depthIntensityBase": 0.30, "depthIntensityStep": 0.08 },
  "threshold": { "backSwipeFraction": 0.5, "sheetDismissVelocity": 1500, "rowCommitFraction": 0.6, "pullTrigger": 100,
                 "chapterArm": 48, "chapterCommit": 72, "holdConfirm": 1200, "recapSeriesDays": 7, "recapChapterDays": 3 },
  "type": { "largeTitle": { "phone": [34, 40], "tablet": [36, 42], "desktop": [40, 46], "wide": [44, 50],
                            "wght": 700, "rond": 100, "tracking": -0.02, "capAt": 48 } },
  "haptics": { "nav.change": "selection", "nav.push": "ahap:rise", "chapter.next": "rigid:0.8", "streak.extend": "ahap:ignite",
               "toggle.on": "toggleOn", "tap.secondary": "none", "recap.countdown.end": "none" },
  "sounds": { "tap.primary": "glass/tap.wav", "nav.push": ["glass/push-1.wav", "glass/push-2.wav", "glass/push-3.wav", "glass/push-4.wav"],
              "nav.pop": "glass/back.wav", "reaction.send": "glass/pop.wav" }
}
```

Generator outputs for Glass (the deviations from the stack's generator are registered in §15.10):

- **CSS** (`frontend/src/skins/glass/tokens.generated.css`): `[data-skin="glass"] { --mm-color-iris400: #A99BFF; … --mm-spring-page: linear(0, 0.0112 …, 1); --mm-spring-page-ms: 621ms; }`; every spring is also pre-sampled to a `linear()` easing (60 samples over its settle time) for CSS-only animations; `@property` registrations for the runtime values of §2.8; the `[data-legible="on"]`, `[data-solid="on"]`, `[data-contrast="more"]` and `[data-motion="reduced"]` overrides.
- **Shared theme** (`frontend/src/skins/theme.generated.css`): the union of both skins' `@theme inline` entries and `@utility type-*` blocks (§2.8, §3.7).
- **TypeScript** (`tokens.generated.ts`): springs as **physical** Motion transitions, `spring.page = { type: "spring", stiffness: 146.0, damping: 24.17, mass: 1 }`, never `visualDuration/bounce`, because physical springs keep inherited velocity (§4.3). The generator does this only because `glass.json` sets `"spring": { "format": "physical", … }`; without the switch it emits the stack's `{visualDuration, bounce}` (Cinematic's tokens are unaffected).
- **Dart** (`mobile/lib/skins/glass/tokens.g.dart`): `GlassTokens` (ThemeExtension) and the `static const` classes; `SpringToken(ms: 520, bounce: 0)` with `.description`; letter spacing converted from em to absolute per style.
- **Haptics** (`mobile/assets/haptics/glass/*.ahap.json`) from the patterns of §5.3, written by a separate `design/build-haptics.mjs` that `build.mjs --check` calls, so `build.mjs` keeps to its ~150 lines; the Tailwind utility-name check is Cinematic's `design/lint-utilities.mjs` (`cinematic/DESIGN.md` §15.10 S2), extended to `src/skins/glass/**`, not a second grep inside `build.mjs`.
- **Motion names** (`MotionName` union in `motion.generated.ts`, `enum MotionName` in `motion_names.g.dart`) from the names of §4.10, so `play()` rejects an unknown name at compile time.
- **Contract** (`design/contract.json`, shared): Glass adds no screen ids or paths; it adds event names to the shared `HapticEvent` and `SoundEvent` unions (§15.6).
- `node design/build.mjs --check` regenerates everything in memory and fails CI if a committed output differs, then runs `design/check-contrast.mjs` (§15.8).

### 15.2 Web (`frontend/src/skins/glass/`)

```
skins/glass/
├── tokens.generated.css / tokens.generated.ts
├── fonts.ts                 next/font/google: Google_Sans_Flex (axes ROND, GRAD, opsz), Google_Sans_Code, Literata (preload: false), Atkinson_Hyperlegible_Next (preload only with legible=1)
├── index.ts                 the Skin object: tokens, fonts, Shell, screens (satisfies Record<ScreenId, Screen>), haptics, sounds, Splash
├── Shell.tsx                sidebar (≥ 1024), collapsed rail (768–1023), dock + orb + accessory (< 768), toasts, palette, back menu, depth stack recorder
├── Splash.tsx               the Droplet reveal (§12.4)
├── motion.ts                play(name, …) for every move of §4.10; <MotionConfig reducedMotion="user">; the spring map from tokens
├── motion-timings.tsx       development overlay (mod+shift+m), tree-shaken from production
├── physics/
│   ├── project.ts           project(pos, v) = pos + v * 0.998 / (1 - 0.998) / 1000; nearest(detents, projected)
│   ├── rubberband.ts        rubberband(x, d, c = 0.55)
│   ├── tracker.ts           pointer tracking with a 100 ms velocity window; catch(): stop the running animation, seed the offset
│   ├── magnet.ts            magnet(target, radius): per-frame pull, capture and release events
│   └── physics.test.ts      vitest: projection, rubber band, spring k/c conversion, rail snap target, tier snap, dim formula, depth intensity
├── glass/
│   ├── GlassSurface.tsx     tier (T1–T5) + finish (regular, clear, tinted); rendering tiers A "liquid" (Chromium: SVG feDisplacementMap backdrop filter),
│   │                        B "frosted" (blur + saturate + dim + rim), C "solid" (Reduce Transparency, Solid glass, Increase Contrast); sets --glass-dim/--glass-grad/--glass-rond from Lb
│   ├── liquid-map.ts        displacement map generator (squircle bezel profile, Snell n = 1.5), cached per (w, h, r, tier), rebuilt at rest after a 100 ms ResizeObserver debounce
│   ├── Caustic.tsx          the lit action's caustic and the follow ring (§2.4.4)
│   ├── useLightAngle.ts     pointer-driven specular angle ±25° (frozen under reduced motion)
│   ├── useLb.ts             Lb from the ambient palette, the series palette or the reader page sample
│   ├── AmbientField.tsx     three radial-gradient layers on one fixed element (no filter), colours from the palette hook, Light follows the story
│   └── rain.ts              Rain on glass: animated displacement map (tier A) / static droplet texture (tier B)
├── icons/                   the custom glyphs of §2.7 as React components
├── copy/                    ai.ts (§9.1.5), errors.ts (§8.0.10), settings-index.ts (§8.25), genres.ts (§8.7)
├── primitives/              Button, IconButton, HoldToConfirm, Chip, Segmented, Poster, Rail, Sheet, Menu, ContextMenu, Toast, Slider, Switch, Stepper,
│                            Dock, SearchOrb, Accessory, Sidebar, CommandPalette, BackMenu, DepthGlyph, LetterReveal, TypedHeadline, LiquidProgress,
│                            ObjectLens, SwipeRow, ScrubRail, ThinkingOrbit, AiNotice, Chart (bars, heatmap, radar, clock, sparkline, table view), ReactionPicker
├── screens/<cluster>/       one file per ScreenId (§8.0.3)
├── haptics.ts               the seven navigator.vibrate events on Android Chrome; everything else no-ops
├── sounds.ts                Web Audio: decode on first gesture, playbackRate for velocity pitch, depth cues
├── soundscape.ts            procedural graphs + recorded layers + mixer (§9.4.2) + the audio-session state machine (§6)
└── share-card.ts            Canvas 2D share-side renderer (§9.2.4)
```

- **Document defaults:** `:root { color-scheme: dark; }`, `<meta name="color-scheme" content="dark">`, the viewport meta with `viewport-fit=cover, interactive-widget=resizes-content`, and the autofill override of §8.0.7.
- **Dependencies** (the full ledger with versions, licences and fallbacks is §15.11; `stack-decision.md` §3): `motion` 13.4.4 (replaces `framer-motion`), `@base-ui/react` 1.8.0 (Dialog, Menu, ContextMenu, Popover and Toast primitives for focus management, roles and dismissal; the Glass sheet drives its own position with Motion `drag="y"`, projection and `sheetSnap`, about 150 lines, instead of Base UI Drawer's CSS timing), `sonner` 2.0.8 (only as the queue behind the Glass `Toast`, rendered through `toast.custom`), `@use-gesture/react` 10.3.1 (reader pinch only), `@phosphor-icons/react` 2.1.10 (add it to `optimizePackageImports`; use `@phosphor-icons/react/ssr` in server components), `fast-average-color` 9.6.0 (the one cover-palette fallback). Glass does not use `lenis`, `embla-carousel-react` or `colorthief`: rails, the hero pager, the voice orbit and Wrapped are native scroll containers with the projection snap.
- **Routes:** thin `app/` route files render `skins.glass.screens[id]` when `getSkin()` returns `glass`; `<ViewTransition>` with `nav-forward` / `nav-back` types for pushes, `name="cover-{sourceId}-{seriesKey}"` pairs for the poster zoom (the same name Cinematic uses), `default: "none"` for browser navigation; any `popstate` handler checks `PopStateEvent.hasUAVisualTransition`.
- **Readers:** the shared reader engine (strip, preload, scrub, progress, the page sampler worker) stays in `features/reader`; Glass supplies only chrome, gesture bindings and overlays through the engine's chrome slot (`renderChrome(state)`), and asks the engine for everything that moves pages through the commands of §15.4.
- **Service worker:** the `skin-changed` message (`stack-decision.md` §2.5); the Glass variant of `offline-fallback.html` chosen by the `mm-skin` cookie (§8.28); the `mm-soundscapes-v1` media cache.
- **Lint:** `no-restricted-imports` on `src/skins/glass/**` bans `@/components/**`, `@/features/*/components/**` and `@/skins/cinematic/**`.

### 15.3 Flutter (`mobile/lib/skins/glass/`)

```
skins/glass/
├── tokens.g.dart
├── glass_skin.dart          implements Skin: theme (ThemeData(brightness: Brightness.dark), BouncingScrollPhysics everywhere, PageTransitionsTheme with PredictiveBackPageTransitionsBuilder), router, splash, haptics, sounds
├── router.dart              GoRouter from the shared Routes; StatefulShellRoute.indexedStack for Home/Library/Sources/You; SwipeablePage (iOS, canOnlySwipeFromEdge: false)
│                            / MaterialPage (Android) page builder; sheet routes for series detail, recap, friend and the ?sheet= family; a NavigatorObserver
│                            that tracks depth per branch and captures route snapshots for the stack overview
├── shell.dart               GlassDock (liquid_glass_widgets GlassTabBar, barHeight 64, minimizedBarHeight 50, search 50) + accessory + collapsed rail for ≥ 768
├── skin_glass.dart          SkinGlass: the only wrapper around liquid_glass_widgets 1.7.2 (tier → LiquidGlassSettings, premium on chrome, standard for the two
│                            page-level controls and transient glass in scroll views, the content twin for in-list items (§2.4.1), GlassAccessibilityScope,
│                            the BackdropFilter + BackdropGroup frosted fallback, GlassTextAxes for ROND/GRAD)
├── motion.dart              GlassMotion.play(name, …) and the motion-timings overlay (Settings → Diagnostics)
├── haptics.dart             HapticEvent → pattern map over skins/skin_haptics.dart
├── physics/
│   ├── glass_physics.dart   project(), rubberband(), SnapPhysics (rails, orbit), CatchableSpring extension on AnimationController, Magnet, tierFor(shortSide), dimFor(lb)
│   └── (test) test/skins/glass/glass_physics_test.dart
├── primitives/              the same list as the web (GlassButton, HoldToConfirm, StackOverview, DepthGlyph, ThinkingOrbit, GlassChart, ReactionPicker, …)
├── screens/<cluster>/       auth, profiles, home, library, series, reader, novel, listen, search, sources, downloads, stats, circle, settings, admin
├── shaders/rain_on_glass.frag   Rain on glass (declared under flutter: shaders:)
├── soundscape/
│   ├── generator.dart       isolate that renders the procedural 30 s loops to WAV bytes for SoLoud.loadMem
│   └── mixer.dart           three layers per scene, recorded-layer cross-fade, ducking, music detection
├── copy/                    ai.dart, errors.dart, settings_index.dart, genres.dart
└── wrapped/share_card.dart  RepaintBoundary → PNG → share_plus
```

- **Packages** (resolution is proved in CI, not asserted: see the ledger and its resolution gate in §15.11): `liquid_glass_widgets` 1.7.2 (pinned exactly), `motor` 1.1.0 (spring-driven values with velocity), `heroine` 0.7.2 (the poster zoom), `swipeable_page_route` 0.4.8, `flutter_animate` 4.5.2 (one-shot entrances), `haptic_feedback` 0.6.5 and `gaimon` 1.5.0, `flutter_soloud` 5.1.4 (UI sounds and the soundscape), `phosphor_flutter` 2.1.0, `material_color_utilities: any` (the version the Flutter SDK pins; never a direct version constraint), `sensors_plus` 7.1.0 (gyroscope light, hero tilt, flame, genre field, shake-to-extend; sampled at 30 Hz only while a screen that uses them is visible), `share_plus` 13.3.0, `flutter_dynamic_icon_plus` 1.4.1, `audio_service` 0.18.19 (the listen lock screen, shared with Cinematic); dev: `flutter_native_splash` 2.4.8, `flutter_launcher_icons` 0.14.4. Already present and reused: `just_audio` ^0.9.40 and `audio_session` ^0.1.25 (narration), `wakelock_plus` ^1.2.8. Sheets use `liquid_glass_widgets`' `GlassModalSheet` with `peekSize: 96`, `halfSize: 0.52`, `horizontalMargin: 8`, `fullTopBorderRadius` from the device corner, `barrierColor: Color(0x47000000)`; `smooth_sheets` 1.2.0 replaces it only for the 1,000-row chapter list if scroll hand-off stutters on a device. Native plugins (`gaimon`, `haptic_feedback`, `flutter_soloud`, `sensors_plus`, `share_plus`, `audio_service`, `flutter_dynamic_icon_plus`) land in one isolated commit with a CI iOS dry run (`stack-decision.md` risk 9); those Cinematic already added are reused, not added twice.
- **Native:** one `mm/platform` method channel (named for what it carries, which is more than haptics), with methods grouped by prefix: `haptics.*` (iOS `AppDelegate.swift`: impact styles with intensity; Android `MainActivity.kt`: `performHapticFeedback` with `GESTURE_THRESHOLD_ACTIVATE/DEACTIVATE`, `SEGMENT_TICK`, `TOGGLE_ON/OFF`, `DRAG_START` behind `Build.VERSION.SDK_INT >= 34`, `CONFIRM`/`REJECT` behind 30, and the one-shot amplitude pulse of §5.1 behind 26), `a11y.reduceTransparency` (iOS), `audio.isMusicActive` (Android), `gestures.setExclusionRects` (Android: `View.setSystemGestureExclusionRects` for the reader's scrub rail and brightness band, §8.0.5); `android:enableOnBackInvokedCallback="true"`; `LiquidGlassWidgets.initialize()` before `runApp` to precompile shaders.
- **Fonts:** bundled `GoogleSansFlexMM.ttf` (subset with `ROND` and `GRAD`), `GoogleSansCode.ttf`, `Literata.ttf` + italic, `AtkinsonHyperlegibleNext.ttf` (shared with Cinematic), each style passing `FontVariation('wght')`, `FontVariation('opsz', size)`, `FontVariation('ROND')` and, on glass, `FontVariation('GRAD')`; `OFL.txt` files registered with `LicenseRegistry`.
- **Boundary and completeness:** `test/skins/import_boundary_test.dart` and `test/skins/completeness_test.dart` (`stack-decision.md` §2.3) cover `lib/skins/glass/**`.

### 15.4 Reader engine seam

The Glass reader chrome is a `chromeBuilder(context, ReaderEngineState)` (Flutter) / `renderChrome(state)` (web, through `useReaderEngine()` in `features/reader/`) over the shared engine. The engine keeps owning thresholds (24 / 56 px chrome, 3000 ms idle, 800 ms orientation hold, preload at 70 %), progress, bookmarks and prefetch, so a skin switch never changes what a zone or a key does. Glass needs these fields from the engine state in addition to the base set Cinematic's §15.4 lists (current page and chapter, page count, progress fraction, neighbours, `nextState`, bookmarks, zoom, auto-scroll state and speed, `pageTint`, `panels`, the commands):

| Field | Type | Used for |
|---|---|---|
| `currentPageSample` | `PageSample` (§2.1.8 step 3) or null | Page-tinted chrome, the legibility dim and grade per chrome group (`lTop`, `lBottom`), the desktop page-lit gutters |
| `scrollVelocity` | px/s, signed | Holding tint and dim changes during flings > 3000 px/s; flick to cruise; momentum carried into the next chapter |
| `seamProgress` | 0 to 1 while a chapter seam crosses the viewport, else null | The seam chip, `chapter.seam` at the reading line, the seam letter reveal |
| `overscrollExtent` | displayed px past the end (positive) or the start (negative) | The next-chapter card rise, arm and commit, the previous-chapter card |
| `panelBoxes` | the current page's `[{x, y, w, h}]` in page fractions, or null | Guided view's camera, lens and counter |

All five are skin-neutral engine duties (Cinematic may ignore them). The engine also posts the chapter's page samples on exit (`POST /reader/page-tints`), as Cinematic's contract already requires.

**Commands and capabilities.** State fields are not enough: Glass's chrome asks the engine to move pages in ways it cannot today (mobile.md §6a: "no page-by-page PageView… no pinch gesture"; web.md §9: no swipe or pinch handlers). The skin never moves the page layer itself; it calls these commands, and each one is engine work, skin-neutral, tested once for both skins.

| Command or capability | What it does | Web today | Flutter today | Needed by | Cinematic also needs it |
|---|---|---|---|---|---|
| `setLayout(strip \| single \| double, {direction: ltr \| rtl})` | Paged layouts with spreads (8 px gap), RTL mirroring, and the page-turn transition hook (`slide \| fade \| none`, finger-driven for Slide) | exists (`PagedView` single / double, RTL spreads, fade); finger-driven Slide is new | **new**: no `PageView` exists; LTR/RTL are continuous horizontal strips | §8.14.1, §8.14.3 | yes (its Layout setting) |
| `pinchZoom(focal, scale, velocity)`, `zoomAt(point, scale, spring)` | Focal-point pinch in the strip (width zoom 1× to 3×, keeping the focal row fixed) and in paged mode (1× to 4×), rubber-band past the limits, release with the scale velocity; double-tap zoom anchored at the tap point | **new** (Ctrl + wheel zoom only) | **new** (zoom scales the list width; double tap toggles 1× ↔ 2× unanchored) | §8.14.3, §4.5 | yes (pinch in the reader and the Lightbox) |
| `overscrollExtent`, `armNeighbour()`, `commitNeighbour({velocity})`, `continueFling(velocity)` | One-at-a-time chapter ends: report the displayed overscroll, arm at 48 px, commit at 72 px, and start the new chapter's ballistic scroll with the fling's remaining velocity | partial (140 px wheel over-scroll at the head) | partial (edge prompts, auto-next after 900 ms) | §8.14.4, §13 (14) | no |
| `swipeNeighbour(direction, dx)` | The opt-in horizontal chapter swipe with the stiffer rubber band (`c` 0.35) | **new** | **new** | §8.14.3 | no |
| `setCamera(rect, spring, velocity)`, `cameraRect` | Guided view: translate and scale the page layer to frame a panel, crossing page boundaries | **new** | **new** | §9.4.3 | yes (its guided view) |
| `pageLayerTransform(matrix, clipRect)` | Magnify the page layer inside a clip (the hit lens, 1.12 ×) without re-laying out the strip | **new** | **new** | §8.14.9 | no |
| `pageToViewport(page, x, y)`, `viewportToPage(x, y)` | Map page fractions (OCR boxes, panels) to viewport coordinates and back, updated every frame while scrolling | **new** | **new** | §8.14.9 (the single overlay layer), §9.4.3 | yes (dialogue stills) |
| `autoScroll.start(pxPerSecond)`, `setSpeed()`, `engageFromVelocity(v)` | Cruise: constant-speed scroll with the 400 ms ramp; engage when a coasting fling decays into the cruise range | exists (20–220 px/s); `engageFromVelocity` new | exists (30 / 60 / 120 px/s); `engageFromVelocity` new | §9.4.1 | yes (auto-scroll) without the engage |
| `paginateNovel(measure, type)`, `pageIndex`, `pageCount` | Paged novels: web CSS multi-column pagination; Flutter `TextPainter` pages in a `PageView` | **new** | **new** (scroll only today) | §8.15.4, §8.16.7 | yes (its paged novel layout) |
| `jumpToPage(n, {glide})` | Scrub and go-to jumps (glide up to 5 pages, cut beyond) | exists | exists | §8.14.2 | yes |

**Commit order.** (0) The pixel-free engine extraction of `stack-decision.md` §2.3 and §4 risk 6, gated by the existing reader tests. (1) The five state fields above. (2) `setLayout` paged on Flutter, `pinchZoom` and `zoomAt` on both clients (these land with Cinematic's reader cluster, which needs them first). (3) `overscrollExtent`, `commitNeighbour`, `continueFling`, `swipeNeighbour`. (4) `pageToViewport`, `pageLayerTransform`, `setCamera`. (5) `engageFromVelocity`. (6) `paginateNovel`. Each step lands before any Glass chrome that uses it, and each is gated by the existing reader tests plus the stack's device check (a 120-page, 2,880 px webtoon scrolled end to end at 120 Hz with no dropped frames in the motion-timings overlay) on both clients.

### 15.5 Backend additions this contract relies on

Everything is profile-scoped, applies the 18+ gate when serving (never when storing), and leaves `backend/connectors/` untouched. Endpoints already defined by `cinematic/DESIGN.md` §15.5 are reused as they are; this table lists them only where Glass adds a field or a parameter, plus the Glass-only additions.

| Addition | Purpose |
|---|---|
| `reading_profiles.skin` (`stack-decision.md` §2.4) | The skin follows the profile |
| `palette: {a: [hex, hex, hex], l}` on `SourceSeries`, `FollowedSeries`, continue items, `GET /home` items and `WorldItem`; `cover_palette` table (Pillow median cut on `w=96`, 30-day TTL), computed in the same pass as Cinematic's `ambient` | Ambient field, rim tints, the legibility `Lb`, share cards |
| `pages[].tint` + `POST /reader/page-tints` (Cinematic's) | First-paint page tint; Glass posts its samples too |
| `GET /reader/panels` + `panels_ready` (Cinematic's) | Guided view |
| `GET /home` (Cinematic's) | Home sections |
| `GET /ai/similar`, `POST /ai/feedback` (Cinematic's) + the `clear` signal | More like this, Not interested, liked pick, reset |
| `GET /ai/recap` (Cinematic's) + `shape=deck`, `scope=series\|chapter`, the `section`, `delta`, `phase` and `done` events with `model` and `covered_through` | The recap deck and the chapter recap |
| `PUT /profiles/{id}/taste` (Cinematic's) + `styles`, `seeds`, `onboarding_step`; new `POST /library/taste/seed {formats, genres, styles}` → `{items: SourceSeries[24]}` (18+ filtered) | Onboarding |
| `reading_profiles.daily_goal_minutes` (nullable int) via `PATCH /profiles/{id}` | The daily goal ring |
| Statistics streak object: `current_days`, `longest_days`, `at_risk`, `milestones_seen` + `POST /library/statistics/milestones/{days}/seen` (Cinematic's) | Flame states, record sparks, milestones once per profile |
| `GET /library/annual?year=` (Cinematic's) + `busiest_day {date, chapters, series: [...]}` and `firsts_lasts {first: {series, read_at}, last: {series, read_at}}` | Wrapped cards 8 and 9 |
| Circle endpoints (Cinematic's §9.3.8) + `show_presence` and `share_streak` in `PATCH /profiles/{id}/sharing`; `GET /circle/members` sends `now: null` unless the member's `show_presence` is on (enforced for both skins, §15.6) and adds `streak` when shared; `DELETE /circle/activity` | Presence arc, shared streaks, Clear my activity |
| Reaction `kind` values `hype` and `wrecked` added to Cinematic's `loved`, `shook`, `laughed`, `tears`, `chefs_kiss` | The six named reactions (§9.3.2) |
| Soundscape layers `/app/media/soundscapes/glass/{scene}-{bed\|detail\|tone}.{ogg\|m4a}` (18 files) next to Cinematic's loops | Recorded soundscape layers |
| First four member covers on `GET /library/collections`; `tag_ids` on `FollowedSeries` list rows (both Cinematic's) | Fanned collection stacks; the Library tag filter |
| `POST /reader/progress` (existing) answers with `streak {current_days, extended_today}` and `today_seconds` (seconds read today in the profile's timezone offset) beside its current `advanced` field | The streak flare and the goal ring without local inference (§9.2.2) |
| `GET /ai/similar?…&fallback=genres` → items with `why: null, basis: "genres"`, computed from the genres the server already caches for series, restricted to the profile's sources, 18+ gated on serve | More like this when AI is unavailable (§9.1.4) |
| `GET /library/world/recommendations?genre=` (a filter on the existing endpoint) | For you filtered to a genre (§9.1.2) |

**Nothing else is stored on the server for Glass.** `PUT /settings` accepts only `mature_content_enabled` from profile users and the server keeps no UI preferences, so every Glass preference that is not listed above lives on the device, per profile, exactly like Cinematic's (web: the existing profile-scoped `localStorage` of `scoped-storage.ts`; Flutter: SharedPreferences with the `.u{user}p{profile}` suffix), and the copy never claims it follows the profile to other devices. The keys (both skins read the shared ones):

| Key | Shape | Scope | Read by |
|---|---|---|---|
| `mm.boot.a11y` | `{legible, motion, solid, contrast}` | per profile, read before paint (§8.0.8) | both skins (Cinematic reads `legible`, `motion`) |
| `mm.recap` | `{mode, seriesDays, chapterDays, skipSeries[]}` | per profile | both skins (§15.6) |
| `mm.reader-preferences[{source}:{series}]` (web, existing K35–K39) / `mm.reader-prefs.u{user}p{profile}` map `"source:series" → {…}` (Flutter, new, the key Cinematic also names) | `{layout, direction, fit, zoom, cruiseSpeed, soundscape: {scene, mix}}` | per profile, per series | both skins (Glass adds `cruiseSpeed` and `soundscape`) |
| `mm.soundscape.defaults` | `{scene, matchStory, mix: {bed, detail, tone}, volumeDb, lowerUnderNarration}` | per profile | Glass |
| `mm.glass.prefs` | `{lightFollowsDevice, autoPlayPreviews, chartTables: {chartId: bool}}` (absorbs the earlier `mm.glass.chartTables`) | per profile | Glass |
| `mm.stats.range` | `7 \| 30 \| 90 \| 365` | per profile | both skins |
| `mm.known-accounts` | usernames, most recent first, at most 5 | per device | both skins (§8.3) |
| `mm.icon.follow` | bool | per device | both skins (§12.2) |
| `mm.glass.revealed`, `mm.glass.typed`, `mm.glass.stack`, `mm.skin.splash.glass` | session records (§10, §7.37, §8.2) | per browser tab (`sessionStorage`) | Glass |

The daily goal (`reading_profiles.daily_goal_minutes`), taste, sharing switches and the skin are the only per-profile values on the server, because other people or other devices need them.

### 15.6 Cross-skin contract alignment

Both skins run on one data layer, one backend and one `design/contract.json`, so these values are shared. The register below is the single statement of each shared value; where `cinematic/DESIGN.md` still says otherwise, this register is the resolution both skins build to, and the Cinematic file takes the matching one-line edit in its next revision (the right-hand column names it).

- **Routes and screen ids:** Glass uses the contract of `cinematic/DESIGN.md` §8.0.3 unchanged (§8.0.3 here); it adds only query state: the `text` search scope, the `?sheet=` ids, the Library extras (`tab`, `reading_status`, `tags`), `?genre=` on `picks`, `?source&series` on `bookmarks`, and one settings slug, `ai`.
- **Haptic and sound events:** `HapticEvent` is the union of both skins' names. Glass adds: `nav.scrub`, `nav.reselect`, `nav.push`, `nav.pop`, `nav.root`, `stack.open`, `stack.pick`, `detent.tick`, `detent.magnet`, `detent.limit`, `press.lift`, `throw.commit`, `motion.catch`, `magnet.capture`, `magnet.drop`, `reorder.lift`, `reorder.pass`, `reorder.drop`, `sheet.pass`, `threshold.cross`, `threshold.back`, `refresh.done`, `hold.ramp`, `hold.done`, `chapter.arm`, `chapter.seam`, `zoom.limit`, `panel.step`, `ocr.hit`, `autoscroll.start`, `voice.center`, `recap.ready`, `goal.met`, `share.lift`, `share.flip`, `reaction.bloom`, `reaction.cross`, `logo.land`, `logo.settle`, `warning`. Cinematic maps these to none unless its contract says otherwise. `SoundEvent` is the set of names that sound in either skin; Glass adds the sound-only `sheet.open` and `sheet.close`.

| Shared value | Resolution (binding for both skins) | Cinematic today |
|---|---|---|
| **Reaction kinds** | One enum of seven: `loved`, `shook`, `laughed`, `tears`, `chefs_kiss`, `hype`, `wrecked`. Glass offers six (Love `loved`, Tears `tears`, Twist `shook`, Masterpiece `chefs_kiss`, Hype `hype`, Wrecked `wrecked`) and renders a stored `laughed` as "Laughed" with `smiley` Fill; Cinematic offers its five and renders `hype` and `wrecked` as two more stamps in its own stamp style ("HYPE", "WRECKED") | lists five kinds; needs the two stamps |
| **Presence** | The server enforces the privacy switch for both skins: `GET /circle/members` sends a member's `now` as `null` unless that member's `show_presence` is on (default off), so no skin can show "reading now" for someone who did not allow it; `last_active_at` still drives "active today" | sends `now` for any sharer who read in the last 15 minutes; its presence dots follow the server and change nothing else |
| **Sharing switches** | `PATCH /profiles/{id}/sharing` carries `show_presence` and `share_streak` beside Cinematic's switches; a skin that has no UI for one leaves it untouched | has no `show_presence` or `share_streak` rows (Glass's Settings sets them) |
| **The recap setting** | One key per profile on the device, `mm.recap` = `{mode: off \| ask \| always, seriesDays (7), chapterDays (3), skipSeries[]}` (§15.5), not a server value. Cinematic's `NEVER` is `off`, `ALWAYS` is `always`, and `AFTER N DAYS AWAY` is `ask` with `seriesDays = N` | stores its setting without naming the key; reads `mm.recap` |
| **Recap stream** | `GET /ai/recap` gains `shape=deck` and `scope=series\|chapter`; the default `shape=prose` is Cinematic's and unchanged | unaffected |
| **Statistics and Wrapped fields** | `busiest_day` and `firsts_lasts` on `GET /library/annual`; `streak {current_days, extended_today}` and `today_seconds` on `POST /reader/progress` responses | ignores them |
| **Activity** | `DELETE /circle/activity` (Clear my activity) exists for both skins; Cinematic may leave it without UI | not listed |
| **Availability flag** | One flag, `flags.glass_available` in `design/contract.json` (§8.0.8); no build flag | the same flag (S8) |
| **First-paint accessibility** | One mechanism, no second cookie: `appearance-boot-source.ts` stamps `data-motion="reduced"`, `data-legible`, and Glass's `data-solid` and `data-contrast`, from the profile's scoped `mm.boot.a11y` (§8.0.8) | the same mechanism (S6); ignores `solid` and `contrast` |
| **Legible text** | One key, `mm.boot.a11y.legible`, one Settings meaning ("easier-to-read text"), per-skin effect written down: Glass swaps every UI role to Atkinson Hyperlegible Next (§3.6); Cinematic swaps its deck and body roles only (its §3.4) | "Hyperlegible text", the same key |
| **Native splash** | One shared native frame, plain `#000000` with no mark (§12.3); each skin draws its own mark in its first frame | the same black frame (its §8.2); conforms |
| **App icon** | Switched only on an explicit skin choice on this device, never on a profile switch; Glass's switch defaults to off (§12.2) | the same rule |
| **PWA manifest, startup images, OG image, install page** | Shared and skin-neutral, owned by Cinematic (§12.2, §12.6 here) | owns them |
| **Taste** | One `PUT /profiles/{id}/taste` payload; Glass's `styles`, `seeds` and `onboarding_step` are optional fields Cinematic ignores | conforms |
| **Breakpoint variants and the Tailwind theme** | Shared, as §2.8 describes | conforms |

### 15.7 Performance budget (flagship-only, maximum effects)

- 120 Hz target (8.3 ms frames) on the owner's iPhone and Android flagship; profile with the Diagnostics screen's FPS and jank readouts and its "Glass layers on screen" row.
- At most two stacked glass layers (a third forces the lowest to `solid1`); all backdrop filters on a Flutter screen in one `BackdropGroup`; `GlassQuality.premium` on chrome, `standard` only for the two page-level controls a scrolling page may carry and for transient glass in scroll views; no glass on list items or inside the reader strip (§2.4.1); at most six live `backdrop-filter` elements per web screen and eight `BackdropGroup` members per Flutter screen (the table below); web displacement maps rebuilt only at rest.
- The ambient field is three radial gradients (web: one fixed element; Flutter: one `CustomPaint`), not live blur filters.
- Per-letter reveals capped at 60 graphemes and at most two at once; skeleton sheen is one gradient per element; physics simulations cap their bodies (24 bubbles, 200 glyphs) and sleep at rest; the rain shader runs only while the Rain scene plays and the chrome is visible.
- Page samples at most every 600 ms, off the main thread (a Web Worker with a transferred `ImageBitmap`; a `compute()` isolate on a 64 px decode); ambient and tint transitions are registered CSS properties or single `TweenAnimationBuilder`s.
- Stack-overview snapshots are captured once per covered route at 0.5 × pixel ratio and dropped on memory pressure.
- Sensors run only while a screen that uses them is visible, at 30 Hz.
- The reader's image pipeline (decode budget, prefetch, extents) belongs to the shared engine and is never touched by the skin.
- **None of these is a device tier.** The frosted tier is a renderer-capability rule (Safari and Firefox cannot refract, on every device); `GlassQuality.standard` for the two page-level controls in scrolling content, the six-surface web budget, snapshot release on memory pressure and the content twins are budget rules applied identically on every device. The owner's rule stands: no degraded fallbacks for low-end devices.
- **Live glass surfaces per frame** (the most a frame can show at once; web counts `backdrop-filter` elements, where a bar group is one masked element, §2.4.1; Flutter counts `BackdropGroup` members, each glass object separately). The Diagnostics row "Glass layers on screen" shows the live count and turns `warning` above the limit (web 6, Flutter 8).

  | Frame and moment | Web elements | Flutter members |
  |---|---|---|
  | Phone tab root or pushed page, with a sheet open and a toast or a menu (a toast waits while a menu is open, on every platform) | nav row group 1, dock + orb 1, accessory 1, sheet 1, toast or menu 1 = **5** | leading button, title capsule, trailing group, dock, orb, accessory, sheet, toast or menu = **8** |
  | Phone search open | nav row group 1, search field 1, toast 1 = **3** | 3 |
  | Manga reader, scrubbing, with the hit lens and a pill | top chrome (both groups, one masked element) 1, bottom capsule 1, scrub lens 1, "Previously" pill or seam chip 1, hit lens or guided-view lens 1, reader sheet 1 = **6** | top-left group, top-right group, bottom capsule, scrub lens, pill or chip, overlay lens, sheet = **7** |
  | Novel reader | top chrome 1, bottom capsule 1, listen row 1, tinted-run chip or go-to popover 1, sheet 1 = **5** | 6 |
  | Desktop | sidebar 1, toolbar group 1, toast 1, app-update capsule 1, palette or window or panel 1, menu 1 = **6** | n/a (Flutter desktop frame: the same objects, 6) |
  | Takeovers (picker, onboarding, Wrapped) | the close or back button 1, the frame (Wrapped `glassMonolith`) 1, a card's lens 1 = **3** | 3 |

### 15.8 Checks

- **Physics (one runnable check per platform):** `physics.test.ts` (vitest) and `glass_physics_test.dart` assert `project(0, 1000) ≈ 499`; `rubberband(100, 800, 0.55) ≈ 51.5`; `{ms: 520, bounce: 0}` → k 146.0, c 24.17; `{ms: 150, bounce: 0.14}` → k 1754.6, c 72.05; a rail snap of offset 310 with velocity 900 and stride 136 lands on 816; `tierFor(44) == T2`, `tierFor(240) == T4`, `tierFor(401) == T5`; `dimFor(1.0) == 0.64`, `dimFor(0) == 0.22`; the depth intensity at depth 3 is 0.54.
- **Contrast gate:** `design/check-contrast.mjs`, run inside `build.mjs --check`, computes WCAG ratios for every text/background pair declared in `design/tokens/glass.json` (labels on black and on `surface1` to `surface3`, semantic text and chips, the lights, speaker tints on each paper, paper ink and muted), and composites the three worst glass cases of §2.1.7: `onGlass` on T3 over `#FFFFFF` at the maximum dim (0.64) must be ≥ 4.5:1 (the reader); `onGlass` on T3 over `#FFFFFF` under the 0.72 `edgeSoft` plateau at the minimum dim 0.22 must be ≥ 4.5:1 (a dock label over any list; computed 8.8:1); and `onTint` on `glassTinted` over `#FFFFFF` at dim 0.64 must be ≥ 4.5:1. It also checks the two-tone focus ring (`iris300` against `#000000` and the black inner ring against `#FFFFFF`, both ≥ 3:1). It fails CI below 4.5:1 (3:1 for large text, focus rings and non-text UI).
- **Checkerboard calibration page:** a development-only route (`/dev/glass-calibration` on the web, Settings → Diagnostics → "Glass calibration" on Flutter) draws a 16 px black-and-white checkerboard with a T2 44 px button, a T3 dock and a T4 240 px menu over it; screenshots of web tier A and Flutter premium are compared side by side and the refraction knobs (§2.4.3) are tuned until both bend the same number of squares.
- **Completeness and boundary** tests from `stack-decision.md` §2.2–2.3 (every `ScreenId` has a Glass screen; Glass imports only the shared data layer and its own primitives).
- **Screenshots:** the Flutter screenshot harness and Playwright (1440 × 900, 390 × 844 and 440 × 956 @3) for each cluster, both skins side by side, plus one snapshot per screen with Reduce Motion, Solid glass and Increase Contrast.
- **Motion-timings overlay:** every `play(name, …)` / `GlassMotion.play` call logs its name, planned settle time, frames rendered and dropped frames (web `requestAnimationFrame` deltas; Flutter `SchedulerBinding.addTimingsCallback`); a 320 px panel bottom-left (web `mod+shift+m` in development, Flutter Settings → Diagnostics → "Show motion timings") lists the last 20 moves, a row turning `danger` when a move drops frames or overruns its settle time by more than one frame.
- **Accessibility pass per cluster:** focus order and rings, labels on every icon button, the gesture alternatives of §11, VoiceOver and TalkBack custom actions, text scale 1.0 / 1.3 / 2.0 and Legible text, the reveals read in full, and the gate-close checklist of §14.11.
- **Signature animations actually play:** a Playwright check per client build: 200 ms after navigating to `/`, the greeting's 10th grapheme is still transparent (route focus did not skip the typing, §10.2); a rail header below the fold is still in its waiting state until it is scrolled 25 % into view, then animates (§10.1); a second visit in the same session shows both at once. Flutter: widget tests of `TypedHeadline` and `LetterReveal` with focus requested on the heading assert the same.
- **Motion names:** the generated `MotionName` union and enum match §4.10 row for row (`build.mjs --check`), and a development build of each client throws on an unknown `play()` name.
- **Device gate** (foundation week, `stack-decision.md` §1): the `liquid_glass_widgets` tab bar + a detented sheet over a scrolling rail at 120 Hz on the iPhone and the Android flagship; if it fails on the iPhone, `SkinGlass` switches to `BackdropFilter` frost with a painted rim and only that file changes.

### 15.9 Build order inside Glass

0. **Before any Glass code:** the dependency commit of §15.11 passes its resolution gate; the reader-engine commands of §15.4 that Cinematic needs (paged layout on Flutter, pinch and anchored zoom) have landed with Cinematic's reader cluster; the §15.10 sign-offs are given.
1. Tokens (`glass.json`, the generator outputs, the contrast gate), physics helpers and their checks; `SkinGlass` and `GlassSurface` with the thickness scale, the content twin and the legibility dim; the checkerboard page; the device gate.
2. Primitives (buttons, chips, segmented, sheet, menu, toast, sliders, switch, hold-to-confirm, charts, AI surfaces) with every state; `copy/errors` (§8.0.10).
3. Shell: dock, orb, accessory, sidebar, command palette, routes, transitions, depth (the stack overview on Flutter, the back menu on the web), the session and profile flows of §8.0.9, the 18+ purge of §8.0.8, haptics, sounds and the audio-session state machine (§6).
4. Home and Library, then series detail and the book page. Needs the 24 demo covers of §12.7 for its screenshots.
5. The remaining engine commands of §15.4 (steps 3 to 6 of its commit order), then reader chrome (manga, then novel) with the seam fields, then listen mode. Needs the demo pages of §12.7.
6. Search, Sources, Updates, Downloads, dialogue search, You, Settings (with the restart flow, the migration of §8.25.3 and the skin previews of §12.7), admin, status screens.
7. The four new features in the order AI home and recaps, statistics and Wrapped, ambient extras (cruise, soundscape, guided view, page tint), Circle (the last needs the most backend). Onboarding ships here with the art-style crops of §12.7; the soundscape with its recordings.


### 15.10 Amendments to `stack-decision.md` and owner calls

Where this contract departs from, or fills a hole in, the stack decision, it says so here, so neither document is silently wrong. Rows marked **sign-off** wait for the owner before the cluster that needs them; **amendment** rows change a generator or a rule in a way the stack did not foresee; **conforms** rows are clarifications. Where Cinematic already registered the same deviation, the row reuses its number (`cinematic/DESIGN.md` §15.10).

| # | Stack section | What this contract does | Status |
|---|---|---|---|
| G1 | §2.1 token format (springs map to Motion `{visualDuration, bounce}`) | Glass's `tokens.generated.ts` emits **physical** springs `{stiffness, damping, mass}`, because duration-based springs drop inherited velocity (§4.3). Switched per skin by `"spring": {"format": "physical"}` in `glass.json`; Cinematic's output is unchanged and the JSON format (`{ms, bounce}`) is the stack's | amendment; generator change only |
| G2 | §2.1 (`build.mjs` writes six files, ~150 lines) | The AHAP JSON is written by `design/build-haptics.mjs` and the motion-name unions by the same small script, both called from `build.mjs --check`; the utility-name check is Cinematic's `design/lint-utilities.mjs` (S2), extended to Glass; the shared `theme.generated.css` is Cinematic's addition, used as is | amendment; generator change only |
| G3 | §2.1 "the web maps them to nothing" | Seven events map to `navigator.vibrate` on Android Chrome (§5.2); everything else maps to nothing. Same exception as Cinematic's S3 | amendment |
| G4 | §2.4 (the mirror holds only the skin, no profile data) | No second cookie: first-paint accessibility comes from the profile's scoped `mm.boot.a11y` through `appearance-boot-source.ts` (§8.0.8), exactly Cinematic's S6, with Glass's two extra keys | conforms |
| G5 | §2.5 step 6 (`mm.skin.splash` sessionStorage flag) | The flag is keyed per skin (`mm.skin.splash.glass`), and the outgoing skin removes its own, so a switch always plays the arriving skin's reveal (§8.2) | amendment (one key name) |
| G6 | §2.6 item 2 (per-cover and per-page palettes on the backend) | Cover palettes stay on the backend (`palette {a, l}` in the same Pillow pass as Cinematic's `ambient`); per-page samples run on the client in the shared sampler (§2.1.8), the backend caching client reports. Cinematic's S1; its sign-off covers both skins | **sign-off** before the reader cluster |
| G7 | §2.2 completeness (`screens satisfies Record<ScreenId, Screen>`) | `readerLanding` is a redirect to `/library` on Flutter and `setup` a redirect to `/login` on the web (Cinematic's S7) | conforms |
| G8 | §2.1 `contract.json` | Glass uses `flags.glass_available` (Cinematic's S8) instead of a build flag, adds its haptic event names and the sound-only `sheet.close`, and one settings slug, `ai` (§8.0.3) | addition |
| G9 | §3 "Dependency changes" | Adds the packages marked *added here* in §15.11, each behind the resolution gate there | addition |
| G10 | §4 risk 5 ("Glass on chrome only, never inside the strip"; `premium` on static chrome only) | §2.4.1 makes it exact: no glass on list items or in the strip (content twins instead), at most two page-level controls in scrolling content at `standard`, per-frame budgets of 6 web elements and 8 Flutter members (§15.7) | conforms (tightens) |
| G11 | §4 risk 6 (engine extraction first, no pixel changes) | §15.4 adds the engine commands Glass and Cinematic need, landing after the extraction and before any chrome that uses them, each gated by the reader tests and the 120-page, 2,880 px device check | conforms (extends) |
| G12 | §2.6 (logic that must agree runs on the backend) | The streak moment is driven by fields on `POST /reader/progress` (§9.2.2), presence privacy is enforced by `GET /circle/members` (§15.6), the More-like-this fallback is `fallback=genres` on the server (§9.1.4): no client inference | conforms |
| G13 | §2.4 ("a per-device override is left out on purpose") | "App icon follows the skin" is a per-device switch for the icon only; it never overrides the profile's skin | conforms |

**Owner calls** (decided here so nothing blocks; each is reversible in one line):
- *Where UI preferences live:* on the device, per profile (§15.5), like Cinematic's; the recap setting and the soundscape defaults therefore do not follow a profile to other devices, and the Settings captions say "Saved on this device." The alternative is one server column (`reading_profiles.preferences` JSON with `PATCH /profiles/{id}/preferences`) that both skins would read; it changes no screen.
- *Presence:* the server hides `now` unless the member turned "Show me in presence" on, for both skins (§15.6). The alternative ("presence for every sharer") is the same one server check removed.
- *App icon follows the skin:* off by default (§8.25.1).

### 15.11 Dependency ledger

Every package the Glass skin uses beyond what the clients already have. **Status:** *stack* = in `stack-decision.md` §3's pinned list; *reused* = Cinematic adds it first (its §15.11), Glass adds nothing; *added here* = Glass adds it. **Resolution gate:** before the first Glass cluster that needs an *added here* package, one isolated dependency commit must pass, **in CI and never on the dev box** (its RAM is shared with production): Flutter `flutter pub get` with the resolved versions recorded (`flutter pub deps --style=compact` in the job log), `flutter analyze` on Flutter 3.44.6 with `go_router` ≤ 17.5, and the iOS dry-run build; web `npm ci`, `npm ls --all` (no invalid or missing peers) and `next build`. A package that fails is replaced by the fallback in its row, never forced (no `dependency_overrides`, no `--legacy-peer-deps`).

| Package | Version | Licence | Kind | Why | Status | Fallback if it fails |
|---|---|---|---|---|---|---|
| `motion` | 13.4.4 | MIT | pure JS | Springs with velocity, drag, `ViewTransition` glue | stack | — |
| `@base-ui/react` | 1.8.0 | MIT | pure JS | Dialog, Menu, ContextMenu, Popover and Toast primitives | stack | — |
| `sonner` | 2.0.8 | MIT | pure JS | The queue behind the Glass toast | stack | A 40-line queue in `primitives/Toast.tsx` |
| `@use-gesture/react` | 10.3.1 | MIT | pure JS | Reader pinch on the web | reused | Pointer-event pinch in `features/reader` (about 120 lines) |
| `@phosphor-icons/react` | 2.1.10 | MIT | pure JS | The icon set (§2.7) | reused | The Phosphor SVGs copied into `skins/glass/icons/` |
| `fast-average-color` | 9.6.0 | MIT | pure JS | Offline cover-palette fallback (§2.1.8) | added here | The mean of a 32 × 32 canvas decode, hue-rotated ±30° (about 20 lines) |
| `fantasticon` (npm) | pinned in the lockfile | MIT | build time | `GlassGlyphs` icon font for Flutter | reused | The custom glyphs as `CustomPainter`s from their SVG paths |
| `@resvg/resvg-js` | 2.6.2 | MPL-2.0 | build time (prebuilt Node addon) | Brand PNG export (§12.6) | added here (build only) | `rsvg-convert` in the CI image |
| `sox` | 14.4.2 (CI image) | GPL-2.0 (tool only; its output WAVs are the project's own and ship, the tool never does) | CI tool | Regenerating the UI sounds (§6) | added here (CI only) | A Node script that writes the same sine, chirp and noise recipes as WAV |
| `liquid_glass_widgets` | 1.7.2 (exact) | MIT | pure Dart + shaders | All glass, through `SkinGlass` | stack | `BackdropFilter` frost with a painted rim (stack risk 4) |
| `motor` | 1.1.0 | MIT | pure Dart | Spring-driven values with velocity | stack | `AnimationController` + `SpringSimulation` |
| `heroine` | 0.7.2 | MIT | pure Dart | The poster zoom | stack | `Hero` with a spring `flightShuttleBuilder` |
| `swipeable_page_route` | 0.4.8 | MIT | pure Dart | Full-width iOS back swipe | stack | `CupertinoPageRoute` (edge only) |
| `smooth_sheets` | 1.2.0 | MIT | pure Dart | Only for the 1,000-row chapter list if scroll hand-off stutters | stack | `GlassModalSheet` as for every other sheet |
| `flutter_animate` | 4.5.2 | BSD-3-Clause | pure Dart | One-shot entrances | stack | Plain controllers |
| `haptic_feedback`, `gaimon` | 0.6.5, 1.5.0 | BSD-3-Clause, MIT | native | Haptics (§5) | stack | `HapticFeedback` from `services` |
| `flutter_soloud` | 5.1.4 | MIT | native (C++ FFI) | UI sounds and the soundscape mixer | reused | `just_audio` (installed) for cues and recorded loops; the procedural layers are then rendered to WAV once and looped |
| `phosphor_flutter` | 2.1.0 | MIT | pure Dart (font) | The icon set | reused | The Phosphor TTF with a generated `IconData` class |
| `sensors_plus` | 7.1.0 | BSD-3-Clause | native | Gyroscope light, hero tilt, flame, genre field, shake to extend | reused | Light pinned at 135°, no tilt, no shake (the switches stay) |
| `share_plus` | 13.3.0 | BSD-3-Clause | native | Share cards | reused | Save to the app's documents folder with a toast |
| `flutter_dynamic_icon_plus` | 1.4.1 | MIT | native | Per-skin icon (off by default) | reused | One icon for both skins |
| `audio_service` | 0.18.19 | MIT | native | Lock-screen narration controls | reused | Foreground-only narration (today's behaviour) |
| `material_color_utilities` | `any` (the version the Flutter SDK pins) | Apache-2.0 | pure Dart | `QuantizerCelebi` for the offline cover fallback and page samples | added here (already a transitive dependency of `flutter`; declared only to import it) | Vendor `QuantizerCelebi` and its two helpers (Apache-2.0, about 150 lines) into `features/reader/engine/` |
| `flutter_native_splash`, `flutter_launcher_icons` | 2.4.8, 0.14.4 | MIT | dev only | The black native frame and icon sets | reused | Hand-edited native files |
| `just_audio`, `audio_session`, `wakelock_plus`, `connectivity_plus`, `sqflite` | as installed | MIT / BSD | native | Narration, the audio session, keep-awake, offline, the novel-text FTS4 index | already present | — |
---

## Appendix A. Graft ledger

The contract is `concepts/glass-3.md` ("Meniscus") plus these grafts. Every graft is written into the sections named; this table is for traceability only.

| Graft | From | Written into |
|---|---|---|
| Stack overview: long-press Back fans the current tab's levels in 3D, tap to jump, swipe to drop, with the strata rim on each card (Flutter) | glass-2 §3.31, §2.2.2 | §7.37, §11, §13 (9) |
| The same overview reduced to a back menu listing the stack's titles (web, and the reduced-motion and screen-reader form everywhere); no web plane stack | glass-2 §3.31 (reduced), not §9.2 | §7.37, §11 |
| Depth indicator: the `strata` glyph with lit bars on the reader and full-height sheet back buttons | glass-2 §3.31, §4.14.2 | §7.37, §2.7, §8.14.2 |
| UI-sound pitch rises with depth (`push-1` … `push-4`, `back`, `root`, `fan`) and navigation haptic intensity `I = 0.30 + 0.08 × depth`, combined with velocity scaling | glass-2 §2.10, §2.11 | §5.1, §5.2, §6, §13 (8) |
| "Previously on" as a four-card deck (Where you left off, What happened, Who's who, Open threads), words streamed as they arrive, the Off · Ask · Always setting with 7-day series and 3-day chapter thresholds, the "Previously · 20 s" pill, the `covered_through` footer | glass-2 §5.1.5 | §9.1.3, §8.25.16, §15.6 |
| The automatic "It's been 3 weeks" offer blooming from Continue with "Don't ask for this series", the footnote naming the model and the chapter range, the "Recap ready" toast when the reader leaves during generation | glass-1 §5.1.4 | §9.1.3 |
| The thinking orbit with honest phase lines and the single-voice AI-unavailable copy table used by every AI surface | glass-2 §5.1.6, §5.1.7 | §7.38, §9.1.2, §9.1.5 |
| Wrapped Export flips the card (`rotateY` 180° on `smooth`) to its share side with Story and Post tabs and Copy image on the web; the Busiest day and Firsts and lasts cards | glass-2 §5.2.4 | §9.2.3, §9.2.4, §4.10 |
| Streak "at risk" after 20:00 local, "new record" sparks, the daily-goal ring on the profile orb | glass-2 §5.2.3 | §9.2.2, §8.8 |
| The Circle presence arc (reading-now orbs drift forward with a live ring) and the six named reactions (Hype, Love, Wrecked, Tears, Twist, Masterpiece) in Phosphor Fill inside Meniscus's hold-to-bloom ballistic picker | glass-2 §5.3.2, §5.3.4 | §9.3.1, §9.3.2, §13 (24, 25) |
| "Accept recommendations", "Show me in presence", per-series "Hide from my Circle" with an unhide list, "Clear my activity" | glass-2 §5.3.1, §5.3.7 | §9.3, §8.25.15, §15.5 |
| The three-layer soundscape mixer (Bed, Detail, Tone) with CC0 recordings, "Remember for this series", starting muted with a toast when the reader's music plays | glass-2 §5.4.2 | §9.4.2 |
| "Match the story" genre-to-scene mapping and "Rain on glass" droplets on the reader capsules | glass-1 §5.4.2 | §9.4.2, §2.4.4, §13 (16) |
| Desktop reader side panels: the left chapter list with first-page thumbnails, the right inline settings, the strip re-centring on a spring | glass-2 §4.14.2 | §8.14.11 |
| Desktop page-lit gutters (the page's top and bottom colours as 10 % pools in `g25` wells, blurred 120 px) whenever the panels are closed | glass-1 §4.14.1 | §8.14.11, §9.4.4 |
| Atkinson Hyperlegible Next as an app-wide "Legible text" option | glass-2 §2.3.1 | §3.1, §3.6, §8.25.1 |
| "Show as table" on every chart, keyboard focus per bar or cell with a live readout, and the data-honesty rules (zero shows as "0", pace after 2 minutes) | glass-2 §5.2.1, glass-1 §5.2.2 | §7.39, §9.2.1 |
| The iOS 26 Icon Composer icon as three layers (bottom M, gutter bar, top M), keeping Meniscus's bowed meniscus bar as the middle layer | glass-2 §7.2 | §12.2 |
| Search results surface from depth in the order sources answer (appended, never reordered) and the vertical jump bar of source initials on phones | glass-2 §4.9 | §8.9, §4.10 |
| In the listen player the current speaker's hue flows into the voice orb (300 ms) with a "Mira · voiced by Ada" chip | glass-2 §4.16.2 | §8.16.2 |
| The legibility dim `clamp(0.22 + 0.42 × Lb, 0.22, 0.64)` on every glass surface over art (generalising reader-only `underlayAdaptive`), from palette luminance, animated over 400 ms; GRAD tracking the backdrop | glass-1 §2.1.7, §2.3.2 | §2.1.7, §3.5, §4.10 |
| The T1–T5 thickness scale with free-sized glass snapping by its shorter side, mapped onto the mass classes; `ROND = 20 × tier` for text on glass | glass-1 §2.2.2, §2.3.2 | §2.4.1, §2.4.2, §2.4.3, §3.5 |
| The lit action's caustic (brightening on press) and the caustic ring Follow sends across the series band | glass-1 §2.2.3, §2.2.5 | §2.4.4, §8.12 |
| One light per meaning: a dedicated machine light for AI output (`machine` `#5CE1E6`, because iris is Meniscus's action tint) and bloom for people | glass-1 §2.1.3 | §2.1.9, §7.38 |
| "Light follows the story": the Home spotlight slides the field and every rim tint to the new cover over 900 ms | glass-1 §4.8, §8 (3) | §2.1.8, §8.8 |
| "Step into the light": the chosen profile's colours pour into the field before the orb flies, combined with the repelled-droplet picker | glass-1 §4.5 | §8.5 |
| The OCR hit lens (a T1 lens magnifying the matched line 1.12 ×) in match navigation | glass-1 §4.23 | §8.14.9, §8.23 |
| The guided-view lens bending the dimmed art so the next panel shows as a refracted sliver | glass-1 §5.4.3 | §9.4.3 |
| Onboarding "Art style" 3 × 3 panel-crop picker, taste stored on the server (`PUT /profiles/{id}/taste`, `POST /library/taste/seed`) with genre weights 1, 2 and −1 | glass-1 §4.7, §9.5 | §8.7, §15.5 |
| `design/check-contrast.mjs` inside `build.mjs --check`, and the checkerboard calibration page | glass-1 §9.7 | §15.8, §2.4.3 |
| The typing caret as a capsule of light that dematerialises after three blinks | glass-1 §6.2 | §10.2 |
| System status health dots as glass beads lit from inside, flickering once on a new failing probe | glass-1 §4.26 | §8.26 |
| The client-side page sampler (16 × 16 `OffscreenCanvas` worker; 64 px `ResizeImage` + `QuantizerCelebi` in `compute()`; cached per page URL) replacing `pages[].palette`; server cover palettes kept; `colorthief` dropped | glass-2 §2.1.9 | §2.1.8, §9.4.4, §15.4 |
| The "Lift" page turn replacing Curl | glass-1 §4.15.4 | §8.15.4, §4.10 |
| Reader-engine seam fields `currentPagePalette` (here `currentPageSample`), `scrollVelocity`, `seamProgress`, `overscrollExtent`, `panelBoxes` | glass-1 §9.4 | §15.4 |
| Dotted `HapticEvent` names matching the shared contract, keeping Meniscus's patterns | glass-1 §2.11 | §5, §15.6 |
| The skin-switch confirm as a plain alert ("Restart in {skin}" / "Stay in Glass") replacing the 1,200 ms hold | glass-1 §4.25.1 | §8.25.2 |

**Adapted, not copied.**

1. **The stack overview.** One graft asked for glass-2's live 3D fan on Flutter; another asked to skip the live fan for a title menu. Both are kept: Flutter fans **snapshots captured when each route was covered** (never live rebuilt routes, so nothing heavy happens on long-press), and the title menu is the web's form and the reduced-motion and screen-reader form everywhere. glass-2's web plane stack is not used.
2. **Record sparks** are `streakCore` gold, not glass-2's bloom, so bloom stays the people light (one light per meaning).
3. **The presence ring** is bloom, not glass-2's Glacier live dot, for the same reason.
4. **Recorded and procedural soundscapes together.** glass-2's CC0 layers are primary; glass-3's procedural recipes start instantly, cover offline and missing files, and the recordings cross-fade in over them, which keeps Meniscus's file-free audio as the guaranteed path.
5. **The page sampler is the shared one.** `cinematic/DESIGN.md` already placed a client page sampler in the shared data layer (`features/reader/page-tint.worker.ts`, `features/reader/engine/page_tint.dart`); Glass extends its output (`top`, `bottom`, `lTop`, `lMid`, `lBottom`) instead of adding a second sampler, and never calls `Score.score` (whose fallback is Google blue for greyscale pages).
6. **Routes and endpoints aligned with the shared contract.** glass-3's own paths (`/home`, `/you`, `/activity`, `/wrapped/:year`, `/onboarding`, `/profiles/create`) and endpoints (`/social/*`, `/library/similar`, `/library/recs/feedback`, `POST /ai/recap`, statistics `from`/`to`) are replaced by the ones `cinematic/DESIGN.md` fixed for both skins (`/`, `/more`, `/circle`, `/library/statistics/annual/:year`, `/welcome`, `/profiles/new`; `/circle/*`, `/ai/similar`, `/ai/feedback`, `GET /ai/recap`, `/library/annual`), with Glass's extra fields listed in §15.5.
7. **The legibility floor** keeps Meniscus's worst-case verification (a dock label over a pure white page) and replaces the fixed 0.30 underlay with the adaptive dim, which lowers the dim over black (0.22) and raises it over white (0.64): measured 5.14:1 for labels and 4.66:1 for the tinted action over white.

---

## Appendix B. Coverage

One row per screen of `inventory/web.md` (its 32 screens, R1 to R27, R17n and E1 to E4, plus the R0 landing role) and `inventory/mobile.md` (its 34 screens, S01 to S34), the global overlays and shared sheets both inventories list, and every screen the four new features add. Rows where the two inventories describe the same screen are merged. The last column is the section of this file that specifies the Glass version; the per-screen specs carry the element-level coverage lines (inventory row IDs).

| Screen | Web inventory | Mobile inventory | Route, ScreenId or surface | Glass section |
|---|---|---|---|---|
| Setup (server address) | none (web `setup` redirects to `/login`) | S01 | `setup` `/setup` | §8.1 |
| Splash and first paint | L1 (auth resolving), root layout | S02 | the skin's `splash`, not a route | §8.2, §12.3, §12.4 |
| Login | R1 (L1–L9) | S03 | `login` `/login` | §8.3 |
| Register | R2 (RG1–RG5) | S04 | `register` `/register` | §8.4 |
| Profile picker | R3 (P1–P8) | S05 | `profiles` `/profiles` | §8.5 |
| Add profile / Edit profile (the profile form) | web §4.2 (PF1–PF8) | S06, S07 | `profileNew` `/profiles/new`, `profileEdit` `/profiles/:id/edit` | §8.6 |
| Manage profiles | R4 (PM1–PM8) | none (reached from You → Profiles) | `profilesManage` `/profiles/manage` | §8.6 |
| Home (landing, AI home) | R0 redirect and R5's landing role (LS1–LS12) | S08 (continue rail) | `tonight` `/` | §8.8, §9.1.1 |
| Library shelf | R5 (LS1–LS12) | S08 (followed grid, novel shelf) | `library` `/library` | §8.17 |
| Browse all | R6 (LB1–LB26, BA1–BA10) | S09 | `library` `/library/browse` | §8.17 |
| Followed series detail | R7 (SD1–SD21) | S10 | `featureByFollow` `/library/:followedId` | §8.12 |
| Collections | R8 (CO1–CO10) | S24 | `collections` `/library/collections` | §8.18 |
| Collection detail | R9 (CD1–CD12) | S25 | `collection` `/library/collections/:id` | §8.18, §9.3.3 |
| Reading history | R10 (RH1–RH5) | S13 | `history` `/library/history` | §8.19 |
| Bookmarks | R11 (BM1–BM5) | S14 | `bookmarks` `/library/bookmarks` | §8.20 |
| Find something to read / For you and Ask | R12 (RC1–RC11) | S11 | `picks` `/library/recommendations` | §9.1.2 |
| Reading statistics | R13 (ST1–ST13) | S12 | `numbers` `/library/statistics` | §9.2.1 |
| Global search (and the novel-text scope) | R14 (SE1–SE11) | S20 | `discover` `/search` | §8.9 |
| Sources | R15 (SL1–SL13) | S16 | `sources` `/sources` | §8.10 |
| Source catalogue | R16 (SB1–SB15) | S17 | `source` `/sources/:sourceId` | §8.11 |
| Source series detail (manga) | R17 (SS1–SS18), web §12.2 (DP1–DP7) | S18 (manga body) | `feature` `/sources/:sourceId/series/:seriesKey` | §8.12 |
| Book page (novel series) | R17n (NB1–NB19) | S18 (novel body), N2, N3 entry | `feature` (by `content_kind`) | §8.13 |
| Reader landing | R18 | none (Flutter redirects `/reader` to `/library`) | `readerLanding` `/reader` | §8.14.10 |
| Manga reader | R19 (RD1–RD42) | S15, S19 (§6a) | `reader` `/reader/:sourceId/:seriesKey/:chapterKey` | §8.14 |
| Read-all reader | R20 | S15 / S19 with `?all=1` | `readAll` `/read-all/:sourceId/:seriesKey` | §8.14 |
| Reader settings sheet | web §9.5 | S15 reader sheet (K01–K12) | `?sheet=settings` | §8.14.5, §8.25.3 |
| Novel reader (with the Type and Contents sheets) | R21 (NR1–NR19, NT1–NT7) | S26, N1, N2 (§6b) | `novel` `/novels/:sourceId/:seriesKey/:chapterKey` | §8.15 |
| Listen mode: mini player, full player, speed, sleep, voices, cast, audiobook | R21 (NR9–NR15) | S26, N3, N4 | `novel` `?listen=1`, `?sheet=player`, `voices`, `cast`, `audiobook` | §8.16 |
| Updates (with update-run detail) | R22 (UP1–UP8) | S23 | `updates` `/updates`, `?sheet=run` | §8.21 |
| Downloads (Chapters, Queue, Storage) | R23 (DL1–DL9), web §12.2 | S21 (§6c), S32 | `downloads` `/downloads` | §8.22 |
| Dialogue search (OCR) | R24 (OC1–OC8) | S27 | `dialogue` `/ocr` | §8.23 |
| More / You | R25 (M1–M6) | S22 | `index` `/more` | §8.24 |
| Settings (every section) | R26 (SG1–SG40) | S28 | `settings` `/settings/:section` | §8.25 |
| Password and security | R26 (SG29–SG39) | S29 | `/settings/security` | §8.25.7 |
| Members (admin) | web §17 (MB1–MB7) | S30 | `/settings/members` | §8.25.8 |
| Theme gallery and design presets | R26 Design panel (K24, K25) | S31 | none: replaced by the skin picker | §8.25.1 |
| Storage | R23 Storage tab | S32 | `/settings/storage` | §8.25.9, §8.22 |
| Backup and restore (admin) | web §16 (BK1–BK5) | S33 | `/settings/backup` | §8.25.10 |
| Diagnostics | none (development rows only) | S34 | `/settings/diagnostics` | §8.25.12 |
| System status (admin) | R27 (AS1–AS10) | none (You → Administration) | `status` `/admin/status` | §8.26 |
| 404 | E1 | go_router `errorBuilder` | router error handler | §8.28 |
| Route error | E2 | `ErrorWidget.builder` | router error handler | §8.28 |
| Root error | E3 | none | root layout | §8.28 |
| Offline fallback page | E4 | none | `/offline-fallback.html` | §8.28 |
| Command palette | web §2.8 (CP1–CP12) | none (phones use Search) | overlay | §7.28 |
| Keyboard shortcuts | web §2.9, R26 Shortcuts panel | hardware keyboards | `?sheet=shortcuts`, `/settings/keyboard` | §8.29, §8.25.13 |
| New-chapters banner | G39 | none (new) | global capsule | §7.30 |
| App update | web SW update prompt | G9 (APK channel) | capsule, `?sheet=app-update` | §8.29 |
| What's New | none | G8 | `?sheet=whats-new` | §8.29 |
| First-run hint | web §2.6 (G38) | G7 | replaced | §8.7, §8.8 |
| Profile switcher | web §2.4 chip, account menu | G3 | dock long-press, sidebar menu | §7.15, §7.16, §8.0.9 |
| 18+ gate | R26 Content panel (K1) | G4, K30, K34 | `/settings/content` | §7.25, §8.25.4, §8.0.8, §14.11 |
| Content mode (Manga · Novels) | K28 | G5, K24 | control | §7.36 |
| Bookmark notice | RD16 | reader snackbars | toast | §8.14.6 |
| Save to Files | none | S21 (Save to Files sheet) | `?sheet=save-files` | §8.22 |
| Open-source licences | none | S28 stock licence page | `/settings/about?sheet=licenses` | §8.25.14 |
| Session ended elsewhere, profile gone | G5, G6 (auth guards) | G3.5, G6 | alert, toast | §8.0.9 |
| Onboarding (new) | new | new | `onboarding` `/welcome?step=1..7` | §8.7 |
| AI rails on Home (new) | new | new | `tonight` sections | §9.1.1 |
| "Previously on": offer, recap deck, chapter pill, compact recap, How it works (new) | new | new | `recap` `/recap/:sourceId/:seriesKey`, `?sheet=offer`, `?sheet=how-it-works` | §9.1.3 |
| More like this (new) | new | new | rail on series detail and end cards | §9.1.4 |
| Streak flame and daily goal ring (new) | new | new | Home, Statistics, You, the orb | §9.2.2 |
| Wrapped (new) | new | new | `annual` `/library/statistics/annual/:year` | §9.2.3 |
| Share cards (new) | new | new | the share side of a card | §9.2.4 |
| Circle (new) | new | new | `circle` `/circle` | §9.3.1 |
| A friend (new) | new | new | `circleMember` `/circle/:profileId` | §9.3.5 |
| Reactions on chapters (new) | new | new | picker and strip | §9.3.2 |
| Shared collections and the Share sheet (new) | new | new | `?sheet=collection-share` | §9.3.3 |
| Recommend to a friend and Letters (new) | new | new | `?sheet=recommend`, `/circle?tab=letters` | §9.3.4 |
| Circle and privacy settings (new) | new | new | `/settings/circle` | §8.25.15 |
| AI and recaps settings (new) | new | new | `/settings/ai` | §8.25.16 |
| Cruise (auto-scroll with speed control) (new) | new (extends RD26) | new (extends the 30/60/120 auto-scroll) | reader control | §9.4.1 |
| Soundscape (new) | new | new | `?sheet=soundscape` | §9.4.2 |
| Guided view (new) | new | new | reader mode | §9.4.3 |
| Page-tinted chrome (new) | new | new | reader chrome | §9.4.4 |
| Stack overview and back menu (new) | new | new | overlay | §7.37 |
| Public install page | capabilities §23 (`GET /`) | none | backend-served, skin-neutral | `cinematic/DESIGN.md` §8.34 (§12.6 here) |
