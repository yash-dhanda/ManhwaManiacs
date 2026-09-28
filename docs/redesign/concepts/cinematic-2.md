# Cinematic, concept 2: "Final Cut"

Designer 2 of 3 for the Cinematic skin. Angle: **motion first**. The layout is a consequence of the choreography. Every screen is a shot, every navigation is an edit, and a camera rig with one set of physics moves everything the reader sees.

Binding inputs: `inventory/00-decisions.md` (owner decisions), `inventory/web.md`, `inventory/mobile.md`, `inventory/capabilities.md`, `research/*.md`, `stack-decision.md`. Dark only, AMOLED `#000000` base. The name "ManhwaManiacs" stays; every asset, token and element below is new.

Conventions in this document:

- **px** means logical pixels (1 CSS px = 1 Flutter logical pixel, per `stack-decision.md` §2.1). **pt** is used only for iOS system references.
- **f** is one film frame at 24 fps, 41.667 ms. Durations are authored in frames and stored as rounded integer milliseconds.
- Breakpoints: **phone** < 600 px, **tablet** 600–1023 px, **desktop** 1024–1439 px, **wide** ≥ 1440 px. The web switches from the phone frame to the desktop frame at 768 px (the tablet band 768–1023 uses the collapsed sidebar). "Mobile web" means the web client below 768 px; it mirrors the phone app screen for screen.
- Token names are written `color.ink`, `motion.spring.dolly`, `haptic.stamp`. They are the keys of `design/tokens/cinematic.json`.

---

## 1. Manifesto

ManhwaManiacs in Final Cut is edited, not laid out. The screen is a black theater and the series art is the only colour in the room. The interface is the crew: a camera that dollies, racks focus and cuts; an editor who times every change to a 24 fps beat; and a projectionist who marks each reel change with two quick cue dots in the corner. Nothing pops, bounces or wobbles. Everything that moves has mass, is critically damped, and can be caught mid-move by a finger without a jump. Titles arrive the way trailer cards do, letter by letter out of a blur. Headlines are typed at one character every 50 ms, like a slug line coming off a typewriter. The reader is the feature presentation: the house lights go down, the letterbox curtain opens, the chrome dissolves into the page's own colour, and when the chapter ends the credits roll and the next chapter waits under a countdown. Browsing is a trailer you scrub with your thumb, reading is the film, and the app gets out of the way the moment the story starts.

---

## 2. Tokens

### 2.1 Colour

#### 2.1.1 Neutral ramp ("projector ramp")

A warm projector white fading to true black. Every step is quoted with its contrast on `#000000` (WCAG relative luminance).

| Token | Hex | On #000 | Role |
|---|---|---|---|
| `color.n0` / `color.canvas` | `#000000` | — | Every screen background, bars, sidebar, sheets' stage. AMOLED pixels off. |
| `color.n1` / `color.pit` | `#080808` | — | Reader gutters beside a narrow page column, letterbox under art that has not loaded |
| `color.n2` / `color.raised` | `#0E0E0E` | — | Poster placeholders, slate skeletons, rows on press |
| `color.n3` / `color.stage` | `#141414` | — | Mini player, toast band, cards that must separate from black |
| `color.n4` / `color.overlay` | `#1A1A1A` | — | Sheets, dialogs, menus, preview slate body |
| `color.n5` / `color.well` | `#222222` | — | Inputs, segmented control track, toggle track off |
| `color.n6` / `color.rule` | `#2E2E2D` | 1.5:1 | Solid rules where a hairline alpha would muddy over art |
| `color.n7` | `#454543` | 2.2:1 | Scrubber track, inactive chapter-segment rails |
| `color.n8` / `color.ink4` | `#5F5F5C` | 3.3:1 | Disabled text and icons only, never information |
| `color.n9` / `color.ink3` | `#767674` | 4.6:1 | Metadata, captions, timecode, inactive nav labels |
| `color.n10` / `color.ink2` | `#9D9D9A` | 7.7:1 | Secondary text, synopsis, descriptions |
| `color.n11` | `#C9C9C5` | 12.7:1 | Body text in long reading contexts (settings help, recaps) |
| `color.n12` / `color.ink` | `#F5F5F1` | 19.3:1 | Primary text, primary button fill, focus ring. Never pure `#FFFFFF`. |

Alpha companions (for use over art): `color.hairline` `rgba(245,245,241,0.08)`, `color.hairlineStrong` `rgba(245,245,241,0.16)`, `color.inkA64` `rgba(245,245,241,0.64)`, `color.inkA48` `rgba(245,245,241,0.48)`, `color.inkA24` `rgba(245,245,241,0.24)`, `color.inkA12` `rgba(245,245,241,0.12)` (secondary button fill), `color.inkA06` `rgba(245,245,241,0.06)` (hover wash).

#### 2.1.2 Accents

| Token | Hex | On #000 | Text on it | Role |
|---|---|---|---|---|
| `color.lamp` | `#FFB547` | 11.9:1 | `#000000` 11.9:1 | The only brand hue. Progress fills, the active-nav bar, the NEW badge, caret, input focus underline, the lit gutter of the wordmark, the selected chip dot, the focus bar in rails. A mark, never a large surface. |
| `color.lampPressed` | `#E89A2C` | 9.1:1 | `#000000` | Pressed state of any lamp-filled mark |
| `color.lampGlow` | `rgba(255,181,71,0.35)` | — | — | Bloom behind the wordmark, streak flame halo, active tab halo |
| `color.ember` | `#FF6A3D` | 7.4:1 | `#000000` 7.4:1 | Heat: streak flame body, reactions, "reading now" live dot on friends' activity, auto-scroll "rolling" dot. Never interactive chrome. |
| `color.ember2` | `#8A1C0E` | 2.3:1 | — | Gradient foot of flame and icon stroke; never text |

Rule: black text on lamp or ember fills, never white.

#### 2.1.3 Semantic roles

| Token | Hex | On #000 | Use |
|---|---|---|---|
| `color.danger` (also `color.rating`) | `#FF4F6D` | 6.6:1 | Errors, destructive buttons, 18+ badge, rating card bar, failed downloads |
| `color.dangerDim` | `rgba(255,79,109,0.14)` | — | Danger zone panel wash, error row wash |
| `color.positive` | `#3DD68C` | 11.2:1 | Downloaded, synced, saved, healthy |
| `color.positiveDim` | `rgba(61,214,140,0.14)` | — | Success toast band edge, healthy status wash |
| `color.warning` | `#FFD166` | 14.6:1 | Overdue checks, storage near cap, paused queue, "offline" pill |
| `color.info` | `#7AB8FF` | 10.1:1 | Rare neutral notices (the "where downloads live" card icon, admin facts) |
| `color.focus` | `#F5F5F1` | 19.3:1 | Keyboard focus ring (2 px, offset 3 px). Focus is white light, not a hue. |
| `color.selection` | `rgba(255,181,71,0.28)` | — | Text selection, OCR `<mark>` highlight |

#### 2.1.4 Scrims (exact stops)

All long fades use the eased scrim curve so gradients do not band on OLED. Stops (position → alpha of the end colour):

`0% 0 · 1.8% .002 · 4.8% .008 · 9% .021 · 13.9% .042 · 19.8% .075 · 27% .126 · 35% .194 · 43.5% .278 · 53% .382 · 66% .541 · 81% .738 · 100% 1`

| Token | Geometry | Definition |
|---|---|---|
| `scrim.heroFoot` | Bottom 55 % of the hero (phone 70 %), top → bottom | eased stops, end colour `var(--amb-tint)` |
| `scrim.heroTitle` | Full hero at 77° (desktop, tablet) | `rgb(0 0 0/.82) 0%, rgb(0 0 0/.56) 24%, rgb(0 0 0/.22) 46%, rgb(0 0 0/0) 68%`. Flutter: `begin Alignment(-1, 0.23)`, `end Alignment(1, -0.23)` |
| `scrim.topChrome` | Top 128 px desktop, safe-area + 72 px phone | `rgb(0 0 0/.78) 0%, rgb(0 0 0/.40) 50%, rgb(0 0 0/0) 100%` |
| `scrim.bottomChrome` | Bottom 112 px + safe area (reader) | reverse of `topChrome` |
| `scrim.vignette` | Full frame radial | `radial-gradient(125% 95% at 50% 40%, rgb(0 0 0/0) 58%, rgb(0 0 0/.5) 100%)` |
| `scrim.posterCaption` | Bottom 60 % of a poster in focus or slate | `rgb(0 0 0/.9) 0%, rgb(0 0 0/.6) 30%, rgb(0 0 0/0) 60%` (to top) |
| `scrim.titleBacklight` | Behind a hero title block | `radial-gradient(60% 55% at 22% 70%, color-mix(in oklab, var(--amb-glow) 22%, transparent) 0%, transparent 70%)` |
| `scrim.pageSpill` | Page under the hero | `var(--amb-tint)` from 0 to hero height, eased to `#000` over the next 60 svh |
| `scrim.railEdge` | 48 px each rail end (desktop) | `#000 0% → rgb(0 0 0/0) 100%` |
| `scrim.modal` | Barrier behind sheets and dialogs | `rgba(0,0,0,0.72)`; the page behind also gets the depth-of-field treatment (§2.6) |
| `scrim.readerDim` | Reader brightness layer | `rgba(0,0,0,a)`, a = 0–0.85 |
| `scrim.readerWarm` | Reader warmth layer | `rgba(255,138,0,a)`, a = 0–0.36, blend `multiply` on web, `BlendMode.multiply` on Flutter |

Hero layer order, bottom to top: `pageSpill` → hero art (Ken Burns) → grain (overlay blend) → `vignette` → `heroTitle` → `heroFoot` → `titleBacklight` → content → `topChrome`.

#### 2.1.5 Ambient colour extraction

Three roles per series, computed once on the backend beside cover resizing (`backend/services/image_resize.py`, Pillow already installed, stdlib `colorsys`), cached with the cover and served as `ambient: {glow, tint, accent}` on series payloads:

| Role | Rule (HLS from the seed colour) | Used for |
|---|---|---|
| `amb.glow` | seed hue, L 0.22, S = min(S, 0.55) | Poster lift bloom, hero title backlight, reader bottom glow |
| `amb.tint` | seed hue, L 0.07, S = min(S, 0.35) | Hero foot scrim end colour, page spill, detail page background, reader chrome base |
| `amb.accent` | seed hue, L 0.70, S clamped 0.45–0.85, then L raised in 0.04 steps until contrast on #000 ≥ 4.5:1 | Detail page only: unread chapter dots, the "you are here" chapter row edge, genre separators. Never a button. |

Seed choice: quantise the cover to 8 colours (48×48, median cut), discard L < 0.08 or L > 0.94, score `count × (0.35 + S)`, take the best. Greyscale or missing cover: glow `#573E19`, tint `#18130C`, accent `#FFB547`.

Live page tint (reader, client side, because pages are client downloads):

- Web: draw the page crossing the reading line into a 16×16 `OffscreenCanvas`, take the most saturated pixel with 0.1 < L < 0.9, then derive glow and tint with the rules above.
- Flutter: `ColorScheme.fromImageProvider(provider: ResizeImage(img, width: 64), brightness: Brightness.dark)`; `primaryContainer` is the seed.
- Resample when the page crossing the reading line changes, at most every 600 ms. Dissolve over `motion.dur.dissolve` (750 ms) on `cine-in-out`. Web registers `@property --amb-glow` and `--amb-tint` as `<color>` so the browser interpolates; Flutter uses `TweenAnimationBuilder<Color?>`.
- Contrast guard: chrome text stays `color.ink` over any tint because tint lightness is capped at 0.07 and glow at 0.22.

### 2.2 Typography

#### 2.2.1 Families (all from Google Fonts, all SIL Open Font License 1.1)

| Role | Family | Axes used | Licence | Delivery |
|---|---|---|---|---|
| Display, title treatments, section headers | **Mona Sans** | `wdth` 75–100, `wght` 600–900 | OFL 1.1 | Web `next/font/google` `Mona_Sans({ axes: ["wdth"], display: "block", preload: true })`; Flutter bundled variable TTF `MonaSans[wdth,wght].ttf` with `FontVariation('wdth', …)`, `FontVariation('wght', …)` |
| UI and body text | **Geist** | `wght` 400–700 | OFL 1.1 | Web `Geist({ display: "swap" })`; Flutter bundled variable TTF |
| Timecode, numerals, metadata, keycaps | **Geist Mono** | `wght` 500–600, feature `tnum` | OFL 1.1 | Web `Geist_Mono`; Flutter bundled variable TTF |
| Editorial title cards ("Previously on", Wrapped, empty-state headlines, credits) | **Instrument Serif** | Regular, Italic | OFL 1.1 | Web `Instrument_Serif({ weight: "400", style: ["normal","italic"] })`; Flutter bundled static TTFs |
| Novel body (default serif) | **Newsreader** | `opsz` 6–72 (set = size), `wght` 380–600 | OFL 1.1 | Web `Newsreader({ axes: ["opsz"] })`; Flutter bundled variable TTF with `FontVariation('opsz', size)` |
| Novel body (sans option) | **Geist** | as above | OFL 1.1 | shared |
| CJK fallback for alternate titles | **Noto Sans KR / JP / SC** | `wght` 400–800 | OFL 1.1 | Web `preload: false` in the display and body stacks; Flutter uses the system CJK face (Apple SD Gothic Neo, Hiragino, Noto CJK), no bundle |

Why Mona Sans: its `wdth` axis is animatable, which the motion system uses twice (the wordmark track-out and the "tracking out" end credits). Fallback stacks: display `"Mona Sans", "Arial Narrow", system-ui, sans-serif`; body `Geist, system-ui, sans-serif`; mono `"Geist Mono", ui-monospace, monospace`; editorial `"Instrument Serif", Georgia, serif`; novel `Newsreader, Charter, Georgia, serif`. CJK titles drop uppercase and `wdth` (they cannot condense) and use weight 800.

Revealed headings set `font-kerning: none` (Flutter `FontFeature.disable('kern')`) so split and unsplit text measure identically and nothing jumps when the reveal ends. Tight tracking comes from `letter-spacing`.

#### 2.2.2 Scale per breakpoint

Size / line height in px. Tracking in em. Case: U = uppercase, S = sentence case.

| Token | Face · wght · wdth | Phone | Tablet | Desktop | Wide | Tracking | Case | Use |
|---|---|---|---|---|---|---|---|---|
| `type.heroTitle` | Mona 860 · 75 | 44/40 | 64/56 | 88/76 | clamp(96, 6.6vw, 128)/0.86 | −0.025 | U | Home hero series title, detail title, pre-roll wordmark |
| `type.slug` (typing headline) | Mona 780 · 80 | 28/30 | 36/38 | 44/46 | 52/54 | −0.015 | U | The typed Home headline and Previously-on subtitle (§6.2) |
| `type.display` | Mona 800 · 75 | 36/34 | 48/44 | 60/54 | 72/64 | −0.02 | U | Page titles: LIBRARY, SEARCH, UPDATES |
| `type.section` (H3) | Mona 760 · 85 | 21/22 | 24/25 | 26/27 | 30/31 | −0.01 | U | Rail and section headers, letter reveal (§6.1) |
| `type.cardTitle` | Geist 620 | 15/19 | 15/19 | 16/20 | 17/21 | −0.005 | S | Poster captions, list titles, slate titles |
| `type.editorialXL` | Instrument Serif 400 | 40/40 | 52/52 | 64/64 | 76/76 | −0.01 | S (italic allowed) | "Previously on", Wrapped headlines, credits "The End" |
| `type.editorial` | Instrument Serif 400 | 24/28 | 26/30 | 28/32 | 30/34 | 0 | S | Pull quotes, empty-state title cards, recap body lead |
| `type.eyebrow` | Geist 600 | 11/14 | 11/14 | 12/15 | 12/15 | +0.18 | U | "MANHWA · ONGOING · 2024", tab labels, filter labels |
| `type.bodyLg` | Geist 400 | 16/24 | 16/24 | 17/26 | 17/26 | 0 | S | Synopsis (max 62ch), recap text, settings intros |
| `type.body` | Geist 400 | 15/22 | 15/22 | 15/22 | 15/22 | 0 | S | Default text |
| `type.bodyStrong` | Geist 600 | 15/20 | 15/20 | 15/20 | 15/20 | 0 | S | Row primaries, emphasis, toast lines |
| `type.label` | Geist 600 | 15/16 | 15/16 | 14/16 | 14/16 | +0.01 | S | Buttons ("Read", "Continue Ch. 142") |
| `type.labelSm` | Geist 600 | 13/16 | 13/16 | 13/16 | 13/16 | +0.01 | S | Small buttons, chips |
| `type.caption` | Geist 400 | 13/18 | 13/18 | 13/18 | 13/18 | 0 | S | Metadata in ink3 |
| `type.timecode` | Geist Mono 560, tnum | 12/16 | 12/16 | 13/16 | 13/16 | +0.04 | U | "CH 142 · 64%", "12 MIN LEFT", "2H AGO", counters, clock |
| `type.micro` | Geist 700 | 10/12 | 10/12 | 11/13 | 11/13 | +0.08 | U | Badges, tab bar labels |
| `type.kbd` | Geist Mono 560 | 12/16 | 12/16 | 12/16 | 12/16 | 0 | as typed | Keycaps |
| `type.statHuge` | Mona 880 · 75, tnum | 72/64 | 96/84 | 120/104 | 144/124 | −0.03 | U | Stats numbers, Wrapped big numbers, streak count |

Title steps: a series title over 28 graphemes drops one size step (heroTitle → display sizes); over 48 graphemes it uses `type.section` sizes ×1.4 and wraps to three lines max with `text-wrap: balance` (Flutter: `TextWidthBasis.longestLine` inside a max-width box).

#### 2.2.3 Mobile text scale (iOS Dynamic Type, Android font scale)

The phone app reads `MediaQuery.textScalerOf(context)`; the web reads the root font size. Each role has a clamp so large text never breaks the choreography geometry.

| OS scale | 0.85 | 1.0 | 1.15 | 1.3 | 1.5 | 1.75 | 2.0 |
|---|---|---|---|---|---|---|---|
| `body`, `bodyLg`, `bodyStrong`, `caption`, novel text | ×0.85 | ×1 | ×1.15 | ×1.3 | ×1.5 | ×1.75 | ×2.0 |
| `label`, `labelSm`, `timecode`, `eyebrow`, `micro`, `kbd` | ×0.9 | ×1 | ×1.12 | ×1.25 | ×1.35 | ×1.45 | ×1.5 (cap) |
| `cardTitle` | ×0.9 | ×1 | ×1.12 | ×1.25 | ×1.35 | ×1.35 | ×1.35 (cap) |
| `section`, `display`, `slug`, `editorial` | ×1 | ×1 | ×1.08 | ×1.15 | ×1.2 | ×1.2 | ×1.2 (cap) |
| `heroTitle`, `editorialXL`, `statHuge` | ×1 | ×1 | ×1 | ×1.08 | ×1.1 | ×1.1 | ×1.1 (cap) |

Layout rules at ≥ 1.5: poster captions move from one line to two, the tab bar hides labels and shows a label pill on the active tab only, list rows grow to fit (no fixed heights), and rails switch from 3.3 visible posters to 2.3. Line heights keep their ratio. Flutter implements this with `TextScaler.clamp(maxScaleFactor: …)` per role inside `CineText` (§9.2).

### 2.3 Spacing

Base 4 px. Tokens: `space.0` 0 · `space.1` 2 · `space.2` 4 · `space.3` 8 · `space.4` 12 · `space.5` 16 · `space.6` 20 · `space.7` 24 · `space.8` 32 · `space.9` 40 · `space.10` 48 · `space.11` 64 · `space.12` 96 · `space.13` 128.

| Token | Value | Use |
|---|---|---|
| `layout.gutter` | `clamp(16px, 4.5vw, 72px)` | Horizontal title-safe inset on every screen |
| `layout.railGap` | 8 px (≥ 1920: 10 px) | Between posters |
| `layout.railStack` | phone 28 · tablet 32 · desktop 40 · ≥ 1920 48 | Between rails |
| `layout.headerToRail` | 12 px | Section header baseline to poster top |
| `layout.sectionStack` | phone 40 · desktop 64 | Between non-rail sections |
| `layout.readingColumn` | 800 px max (manga strip), 48–88 ch (novel) | Reader measure |
| `layout.sidebar` | 248 px expanded, 72 px collapsed | Desktop Reel Index |
| `layout.topBar` | 64 px desktop, 56 px + safe area phone | Top bars |
| `layout.tabBar` | 64 px + safe area bottom | Phone transport bar |
| `layout.touchMin` | 44 px | Minimum hit target everywhere (48 px Android where the row allows) |
| `layout.sheetMaxW` | 720 px | Sheets on tablet and desktop |
| `layout.dialogW` | 480 px (confirm), 640 px (content) | Dialogs |

### 2.4 Radius

Tight, film-frame radii. Pills exist only where a physical round object is implied.

| Token | Value | Use |
|---|---|---|
| `radius.none` | 0 | Full-bleed art, hero, reader pages, bars, sidebar |
| `radius.hair` | 2 px | Badges, progress ends, toast band, keycaps, rating bar |
| `radius.frame` | 6 px | Posters, cards, inputs, buttons, chips, menus, thumbnails |
| `radius.sheet` | 12 px | Top corners of sheets, dialog corners, preview slate |
| `radius.round` | 999 px | Round icon buttons, avatars, toggles, the leader sweep, cue dots |

### 2.5 Elevation (light, not shadow)

Shadows are invisible on `#000`, so depth is built from surface steps, edge light and bloom.

| Token | Surface | Edge | Glow | Use |
|---|---|---|---|---|
| `elev.0` | `canvas` | none | none | Page |
| `elev.1` | `raised` | inner 1 px `hairline` | none | Posters, rows, cards at rest |
| `elev.2` | `stage` | inner 1 px `hairline`, top edge 1 px `inkA12` | none | Mini player, toasts, bulk bar, download bar |
| `elev.3` | `overlay` | top edge 1 px `rgba(245,245,241,.10)` | none | Sheets, dialogs, menus, command palette |
| `elev.lift` | poster art | inner 1 px `hairlineStrong` | `0 16px 48px -8px var(--amb-glow)` at 70 % + over-art shadow `0 18px 40px rgba(0,0,0,.6)` | Hovered or focused poster, pressed card, dragged row |
| `elev.spot` | any | none | radial `lampGlow` 0→35 % | Wordmark, streak flame, active tab halo |

### 2.6 Blur

There are no translucent glass panes in this skin. Blur exists only as a camera effect.

| Token | Value | Use |
|---|---|---|
| `blur.letter` | 10 px → 0 | Letter reveal (§6.1) |
| `blur.focusPull` | 16 px → 0 with brightness 0.6 → 1 and scale 1.04 → 1 | Every image arriving (rack focus) |
| `blur.dof` | 3 px, brightness 0.45 | Page behind an open sheet, dialog, slate or palette (the camera racks focus to the foreground). Applied to the page layer, never to the sheet. |
| `blur.motion` | horizontal only, `min(6, |v| / 600)` px where v is px/s, threshold |v| > 2400 px/s | Rails and grids during a fast fling; released over 125 ms when velocity falls under the threshold |
| `blur.art` | 60 px, brightness 0.35 | Backdrop art (detail page backdrop, source hub tiles, listen mode, Wrapped) |
| `blur.recap` | 24 px | Next-chapter first panel behind the Up Next card |

### 2.7 Borders

| Token | Value | Use |
|---|---|---|
| `border.hair` | 1 px `hairline` | Dividers, poster inner edge, list separators |
| `border.strong` | 1 px `hairlineStrong` | Outline buttons, input rest edge on art |
| `border.focus` | 2 px `color.focus`, offset 3 px, radius follows the element + 3 px | Keyboard focus |
| `border.lampUnder` | 2 px `lamp`, drawn left → right | Input focus, active tab underline |
| `border.danger` | 1 px `danger` | Error inputs, danger zone panel |
| `border.dashed` | 1 px dashed `rgba(245,245,241,.24)`, dash 4 gap 4 | "Add profile" tile, drop targets |

### 2.8 Iconography

- **Set:** Phosphor on both clients: `@phosphor-icons/react` 2.1.10 (MIT; server components import from `@phosphor-icons/react/ssr`; add it to `experimental.optimizePackageImports`) and `phosphor_flutter` 2.1.0 (MIT). Identical names on both sides.
- **Weights:** rest = **Bold**; active or selected = **Fill**; ornamental ≥ 32 px = Bold.
- **Sizes:** 16 (inline with caption), 20 (buttons, rows), 24 (bars, tab bar), 28 (reader chrome), 40 (empty-state title cards). Stroke reads ≈ 2.25 px at 24.
- **Colour:** icons take their text colour. Only these icons may be lamp: active tab, active sidebar item, selected chip dot, the auto-scroll "rolling" indicator (ember).
- **Morph:** Bold → Fill swaps are a 125 ms crossfade with a 0.92 → 1 scale on the incoming glyph (cine-out).
- **Custom glyphs (6)** drawn on Phosphor's 256 grid in Bold and Fill, shipped as React components and one small TTF (`fantasticon`, build-time only) for Flutter: `mm-mark` (the MM column), `strip-scroll` (vertical strip with a down chevron), `panel-focus` (panel inside corner brackets), `bubble-search` (speech bubble with a magnifier), `age-gate` (seal with "18"), `voice-31` (user-sound with a stacked badge).
- **Name map for recurring actions:** Home `house`, Library `books`, Search `magnifying-glass`, Downloads `download-simple`, More `dots-three`, Sources `broadcast`, Updates `bell`, Collections `stack`, History `clock-counter-clockwise`, Bookmarks `bookmark-simple`, Stats `chart-bar`, Activity `users-three`, For you `sparkle`, Settings `gear-six`, Status `pulse`, Profiles `user-switch`, Read `play`, Follow `plus` / `check`, Favourite `star`, Download `download-simple`, Downloaded `check-circle`, Queued `circle-dashed`, Failed `warning-circle`, Bookmark `bookmark-simple`, Share `share-fat`, Voices `user-sound`, Listen `headphones`, Auto-scroll `strip-scroll`, Panel view `panel-focus`, Soundscape `waveform`, Type settings `text-aa`, Reader settings `sliders-horizontal`, Fullscreen `corners-out` / `corners-in`, Close `x`, Back `caret-left`, Next chapter `skip-forward`, Previous chapter `skip-back`, OCR `bubble-search`, 18+ `age-gate`, Offline `cloud-slash`, Retry `arrow-clockwise`, Pin `push-pin`, Streak `flame`, React `smiley`, Recommend `paper-plane-tilt`, Keyboard `keyboard`.

### 2.9 Motion

#### 2.9.1 Principles

1. **One camera.** All movement is camera movement: dolly (translate), push (scale), rack focus (blur), dissolve (opacity). Objects never rotate in 3D, tilt, wobble or overshoot.
2. **The beat is the frame.** Every duration is a whole number of 24 fps frames. Things that happen together land on the same frame.
3. **Mass, no bounce.** Every spring is critically damped (bounce 0). Heavier moves take longer; nothing oscillates.
4. **Interruptible or skippable.** Anything driven by input is a spring and retargets from its current position and velocity. One-shot choreography (reveals, dissolves, curtains) is skippable: a tap or key jumps it to its final frame in one `cut`.
5. **Decisive in, quiet out.** Entrances run on `cine-out` or a spring; exits run on `cine-in` at 0.75× the entrance duration.
6. **Slow things are very slow.** Ambient motion (Ken Burns, grain, glow drift) runs on periods of 8–24 s so it never pulls the eye.

#### 2.9.2 Durations (frames)

| Token | Frames | ms | Use |
|---|---|---|---|
| `dur.flash` | 1f | 42 | Cue-dot flash, the black hold inside a dip |
| `dur.tick` | 2f | 83 | Press-in, icon swap start |
| `dur.cut` | 3f | 125 | Icon morph, skip-to-end, focus ring in |
| `dur.beat` | 6f | 250 | Small state changes, toggles, chips, exits of small things |
| `dur.shot` | 9f | 375 | Chrome in, menus, toasts in |
| `dur.scene` | 12f | 500 | Page transitions, sheets, match cuts |
| `dur.dissolve` | 18f | 750 | Backdrop and ambient colour dissolves |
| `dur.reveal` | 24f | 1000 | Hero choreography, pre-roll segments |
| `dur.titles` | 36f | 1500 | Credits roll, Wrapped scene holds |
| `dur.ambient` | 576f | 24000 | Ken Burns period |

#### 2.9.3 Curves

| Token | Value | Use |
|---|---|---|
| `ease.cineOut` | `cubic-bezier(0.16, 1, 0.3, 1)` | Entrances, reveals, focus pulls |
| `ease.cineIn` | `cubic-bezier(0.7, 0, 0.84, 0)` | Exits |
| `ease.cineInOut` | `cubic-bezier(0.65, 0, 0.35, 1)` | Dissolves, match-cut geometry, letterbox bars |
| `ease.snap` | `cubic-bezier(0.2, 0, 0, 1)` | Press release, stamp |
| `ease.drift` | `cubic-bezier(0.37, 0, 0.63, 1)` | Ken Burns, grain, glow breathing |
| `ease.linear` | `linear` | Leader sweep, auto-scroll, countdown rings, typing clock |

#### 2.9.4 Springs (camera rig)

Token format is `{ "ms": d, "bounce": 0 }` (`stack-decision.md` §2.1). Web: Motion `{ type: "spring", visualDuration: d/1000, bounce: 0 }`. Flutter: `SpringDescription.withDurationAndBounce(duration: d ms, bounce: 0)`. Physical equivalents at mass 1 (critically damped: stiffness = (2π/d)², damping = 4π/d):

| Token | ms | Stiffness | Damping | Mass | Feel | Use |
|---|---|---|---|---|---|---|
| `spring.press` | 167 | 1421 | 75.4 | 1 | Shutter | Press scale-down and release |
| `spring.whip` | 250 | 632 | 50.3 | 1 | Whip pan | Active-nav bar, tab underline, toggle knob, segmented thumb, rail focus slide on keyboard |
| `spring.steadicam` | 375 | 281 | 33.5 | 1 | Handheld-smooth | Chrome show and hide, tab bar hide on scroll, scrub thumb catch-up, sidebar width |
| `spring.dolly` | 500 | 158 | 25.1 | 1 | Dolly track | Sheets, page push, poster → slate, drag release, panel-view camera |
| `spring.crane` | 750 | 70.2 | 16.8 | 1 | Crane | Hero pin into slug, profile spotlight, Wrapped scene moves |

Gesture hand-off: on release, pass the pointer velocity into the spring (Motion `animate(value, target, { ...spring, velocity })`; Flutter `SpringSimulation(desc, start, end, velocity)` or `motor` 1.1.0 `SpringMotion`). Retargeting mid-flight never resets velocity.

#### 2.9.5 Camera moves (named choreography)

| Move | Definition | Where |
|---|---|---|
| `move.dip` (dip to black) | out: opacity 1 → 0, `dur.cut` `cineIn`; hold black `dur.flash`; in: 0 → 1, `dur.beat` `cineOut` + content dolly 16 px up on `spring.dolly` | Tab and sidebar section switches |
| `move.reelChange` | `move.dip` plus two cue dots (§6.3) flashing top-right, 1f on, 1f off, 1f on, at t = −125 ms, before the cut | Section switches, content-mode switch, profile switch |
| `move.matchCut` | Shared element morphs rect → rect and radius 6 → 0 on `spring.dolly`; everything else dissolves `dur.shot` | Poster → detail hero, continue card → reader curtain, avatar → profile spotlight, search result → detail |
| `move.push` | Incoming page dollies from 100 % x to 0 on `spring.dolly`; outgoing moves to −30 %, dims to brightness 0.4 | Forward navigation inside a section on phone |
| `move.pull` | Reverse of push at 0.75× (spring 375 ms), follows the finger on edge swipe | Back |
| `move.fadeUp` | Barrier 0 → 0.72 over `dur.beat`; panel rises 24 px + fades in on `spring.dolly`; page behind racks to `blur.dof` over `dur.shot` | Sheets, dialogs, menus, palette |
| `move.curtain` | Letterbox bars close to black `dur.shot` (320 ms rounded to 375) `cineIn`, hold `dur.tick`, open onto the first page `dur.scene` `cineOut` | Detail → reader only |
| `move.dissolve` | Crossfade `dur.dissolve` `cineInOut`, old image holds under new | Hero rotation, backdrop swap, ambient colour |
| `move.rackFocus` | `blur.focusPull` over `dur.scene` `cineOut` | Image load, rail settle after fling |
| `move.kenBurns` | scale 1 → 1.10 + object-position 50 % 12 % → 50 % 42 % over `dur.ambient`, `drift`, alternate, corner seeded by `hash(seriesId) % 4` | Hero, detail backdrop, Wrapped scenes, listen-mode backdrop |
| `move.trackOut` | `wdth` 75 → 90 and letter-spacing +0.08 em over `dur.titles` `cineOut`, then dissolve | Pre-roll exit, end credits, skin switch |

#### 2.9.6 Stagger rules

| Group | Step | Cap | Order |
|---|---|---|---|
| Letters (§6.1) | 28 ms | total 600 ms (`step = min(28, 600/(n−1))`) | reading order |
| Typing (§6.2) | exactly 50 ms per grapheme | ≤ 60 graphemes | reading order |
| Rail posters entering | 42 ms (1f) | first 8 items; the rest appear at the 8th item's time | left → right |
| Grid tiles | `(row + col) × 42 ms` | 375 ms | diagonal from top-left |
| List rows | 28 ms | first 10 rows | top → bottom |
| Rails on a page | 83 ms (2f) between rail headers | 6 rails | top → bottom; each rail's posters follow its header by 125 ms |
| Recap / AI text | per word, 160 ms fade, 30 ms apart | none (streams) | reading order |
| Sidebar items on expand | 20 ms | 16 items | top → bottom |

Everything that entered once per session does not re-stagger when the user comes back: a module-level `Set` (web) or a `seenKeys` provider (Flutter) marks it seen, and the element renders at its final frame.

#### 2.9.7 Interruptibility contract

- Springs retarget from `(position, velocity)`. A reversed gesture reverses the same animation.
- A skippable one-shot jumps to its final frame in `dur.cut` on: tap, click, Enter, Space, Esc (which also dismisses), or any scroll input.
- Navigation during a transition cancels the running one and starts the new one from the current frame; there is never a queue of transitions.
- The typed headline is skippable, and the letter reveal completes instantly when its element scrolls out of view before it finishes.
- Auto-advancing timers (hero rotation 8 s, Up Next 5 s, Previously-on 12 s) pause while a pointer is over them, while a finger is down, while the app is backgrounded, and while any sheet is open.

#### 2.9.8 Reduced motion (OS setting)

`prefers-reduced-motion: reduce` on web and `MediaQuery.disableAnimationsOf(context)` on Flutter:

- Letter reveal → whole string fades in over 200 ms. Typing → full text at once, no caret.
- Every translate, scale, blur and match cut → a 200 ms opacity crossfade. Springs become `dur.beat` crossfades.
- Ken Burns, grain flicker, glow breathing, motion blur, parallax and velocity effects are off. Hero rotation stops (manual arrows only).
- Cue dots still flash once (they carry information: "the section changed") but without the repeat.
- Auto-scroll and Up Next countdowns never auto-start; they wait for an explicit play.
- Haptics are unaffected (they have their own toggle).

### 2.10 Haptics vocabulary

Implementation: `gaimon` 1.5.0 (named impacts and AHAP patterns on iOS, auto-converted to Android amplitude waveforms) plus `haptic_feedback` 0.6.5 for the system selection tick. All calls go through `mobile/lib/skins/skin_haptics.dart` (`HapticEvent` → pattern), gated by the Settings toggle "Haptic feedback" (default on). Web: `navigator.vibrate` on Android Chrome only, for the rows marked; iOS Safari gets nothing.

Principle: **weight, not texture**. Low sharpness, few events. Scrolling, chrome show/hide and sheet dismiss are silent.

| `HapticEvent` | Moment | iOS | Android | Web (Android) |
|---|---|---|---|---|
| `press.primary` | Primary button down | `rigid` | `rigid` (waveform 12 ms @ 200) | — |
| `press.card` | Poster or card press | `selection` | `CLOCK_TICK` | — |
| `longPress` | Long-press opens preview slate or context menu | `heavy` | `LONG_PRESS` | `[10]` |
| `toggle.on` / `toggle.off` | Switch | `medium` / `light` | `medium` / `light` | — |
| `tab` | Tab or sidebar section change | AHAP `cue` | converted | — |
| `segment` | Segmented control, chip, filter | `selection` | `CLOCK_TICK` | — |
| `slider.detent` | Slider or scrubber, every 10 % (reader scrub: every chapter boundary and every 10 pages) | `selection` | `CLOCK_TICK` | — |
| `sheet.detent` | Sheet reaches full height | `medium` | `medium` | — |
| `refresh.armed` | Pull-to-refresh passes 96 px | `medium` | `medium` | — |
| `follow` | Add to library, follow | AHAP `stamp` | converted | `[12]` |
| `unfollow` | Remove from library | `light` | `light` | — |
| `favourite` | Star on | `medium` | `medium` | — |
| `download.start` / `.done` / `.fail` | Download lifecycle | `light` / AHAP `reelLock` / `error` | converted | — / — / `[20,40,20]` |
| `bookmark` | Bookmark saved | AHAP `stamp` | converted | `[12]` |
| `chapter.next` | Chapter change committed (seam crossed, Up Next taken) | `heavy` | `heavy` | — |
| `chapter.endCard` | Up Next card appears | AHAP `curtain` | converted | — |
| `page.turn` | Paged mode turn, novel page turn | `selection` | `CLOCK_TICK` | — |
| `zoom.snap` | Double-tap zoom lands | `light` | `light` | — |
| `autoscroll.start` / `.step` / `.end` | Auto-scroll | AHAP `projector` / `rigid` / `heavy` | converted | — |
| `panel.next` | Panel view advances | `soft` | `light` | — |
| `gate.unlock` | 18+ enabled after confirm | AHAP `vault` | converted | — |
| `streak.extend` | Streak +1 (first chapter of the day completed) | AHAP `ignite` | converted | `[12,120,8]` |
| `reaction` | Reaction sent | `medium` | `medium` | `[8]` |
| `recommend` | "Recommend to" sent | `success` | `success` | `[8]` |
| `listen.play` / `.pause` | TTS play / pause | `rigid` / `light` | converted | — |
| `wrap.card` | Wrapped scene advance | `soft` | `light` | — |
| `share.saved` | Stat card image saved | `success` | `success` | — |
| `preroll.stamp` | Wordmark stamp at 820 ms | AHAP `stamp` | converted | — |
| `skin.confirm` | Skin switch confirmed | `heavy` | `heavy` | — |
| `error` | Any failed action | `error` | `error` | `[20,40,20]` |
| `unlock.reader` | Reader locked mode unlocked (five taps) | `medium` | `medium` | — |

AHAP patterns (T = transient, C = continuous; I = intensity, S = sharpness; seconds). Transients and continuous events only, so Android conversion matches:

| Name | Events |
|---|---|
| `stamp` | T@0.000 I1.0 S0.25 · T@0.060 I0.35 S0.10 |
| `cue` | T@0.000 I0.45 S0.30 · T@0.083 I0.45 S0.30 (two cue dots) |
| `reelLock` | T@0.000 I0.7 S0.35 · T@0.080 I0.9 S0.30 |
| `curtain` | C@0.000 dur 0.300 I0.35 S0.15 · T@0.300 I0.6 S0.20 |
| `vault` | T@0.000 I0.4 S0.3 · T@0.060 I0.6 S0.3 · T@0.120 I1.0 S0.25 |
| `ignite` | C@0.000 dur 0.400 I0.5 S0.2 · T@0.400 I1.0 S0.3 |
| `projector` | C@0.000 dur 0.250 I0.25 S0.10 · T@0.250 I0.5 S0.2 (motor spin-up) |

### 2.11 UI sounds (off by default)

Settings → Playback → "Interface sounds" (default **off**). All cues are original syntheses in D, warm, low-passed below 4 kHz, with a 0.4 s room. 48 kHz 16-bit mono WAV, peaks: ticks −28 dBFS, confirmations −18 dBFS. Web: Web Audio API, one decoded `AudioBuffer` per cue, one master `GainNode`, context resumed on the first gesture. Flutter: `flutter_soloud` 5.1.4 (MIT), preloaded. Sounds duck to −12 dB while TTS narration or a soundscape plays, and never play inside the reader except the listed reader cues.

| `SoundEvent` | Moment | Length | Character |
|---|---|---|---|
| `focus` | Rail focus moves (keyboard, dwell), throttle 1 per 60 ms | 18 ms | Soft filtered tock ≈ 2.8 kHz |
| `select` | Open detail, primary button | 90 ms | Two felt-piano notes, D5 → A5 |
| `back` | Back, close sheet | 70 ms | A5 → D5, quieter |
| `cue` | Reel change (section switch) | 110 ms | Two short projector-shutter clicks 83 ms apart |
| `swap` | Hero backdrop dissolve | 400 ms | Low 60 Hz swell with a short tail |
| `sting` | Pre-roll | 1600 ms | Projector motor rattle, 45 Hz sub hit at 820 ms, rising shimmer, Dmaj7 chord |
| `stamp` | Follow, bookmark | 140 ms | Rubber-stamp thud + paper tick |
| `reel` | Download complete | 220 ms | Reel latch: two metallic clicks, the second lower |
| `curtain` | Up Next card appears | 600 ms | Velvet sweep (filtered noise) into a soft D2 |
| `complete` | Chapter finished, streak +1 | 600 ms | Warm D major triad, soft attack |
| `rating` | Rating card shows | 900 ms | Low house-lights-down hum |
| `error` | Failed action | 180 ms | Muted low thud |
| `wrap` | Wrapped scene change | 300 ms | Film-gate advance clack |
| `toggle` | Switch | 40 ms | Relay click |

### 2.12 Token file shape (excerpt of `design/tokens/cinematic.json`)

```json
{
  "color": { "canvas": "#000000", "raised": "#0E0E0E", "stage": "#141414", "overlay": "#1A1A1A", "well": "#222222",
             "ink": "#F5F5F1", "ink2": "#9D9D9A", "ink3": "#767674", "ink4": "#5F5F5C",
             "lamp": "#FFB547", "lampPressed": "#E89A2C", "ember": "#FF6A3D", "danger": "#FF4F6D",
             "positive": "#3DD68C", "warning": "#FFD166", "info": "#7AB8FF" },
  "radius": { "hair": 2, "frame": 6, "sheet": 12, "round": 999 },
  "space": [0, 2, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64, 96, 128],
  "motion": {
    "dur": { "flash": 42, "tick": 83, "cut": 125, "beat": 250, "shot": 375, "scene": 500, "dissolve": 750, "reveal": 1000, "titles": 1500 },
    "curve": { "cineOut": { "ms": 500, "bezier": [0.16, 1, 0.3, 1] }, "cineIn": { "ms": 375, "bezier": [0.7, 0, 0.84, 0] },
               "cineInOut": { "ms": 750, "bezier": [0.65, 0, 0.35, 1] }, "snap": { "ms": 167, "bezier": [0.2, 0, 0, 1] } },
    "spring": { "press": { "ms": 167, "bounce": 0 }, "whip": { "ms": 250, "bounce": 0 }, "steadicam": { "ms": 375, "bounce": 0 },
                "dolly": { "ms": 500, "bounce": 0 }, "crane": { "ms": 750, "bounce": 0 } },
    "stagger": { "letter": 28, "letterCap": 600, "typing": 50, "rail": 42, "list": 28, "grid": 42, "gridCap": 375 }
  },
  "haptics": { "tab": "ahap:cue", "follow": "ahap:stamp", "download.done": "ahap:reelLock", "chapter.endCard": "ahap:curtain",
               "gate.unlock": "ahap:vault", "streak.extend": "ahap:ignite", "autoscroll.start": "ahap:projector", "segment": "selection" },
  "sounds": { "enabledByDefault": false, "files": { "cue": "cine/cue.wav", "sting": "cine/sting.wav", "stamp": "cine/stamp.wav" } }
}
```

---
## 3. Component catalog

Every primitive lives once per client: `frontend/src/skins/cinematic/primitives/*` and `mobile/lib/skins/cinematic/primitives/*`. State vocabulary used in every table: **default, hover** (pointer devices only), **pressed, focused** (keyboard focus-visible only), **disabled, loading, selected, error**. A state not listed for a component does not exist for it, and the table says so.

Common rules:

- Hover never exists on touch. Focus ring (`border.focus`) appears only for keyboard focus (`:focus-visible` on web, `FocusHighlightMode.traditional` on Flutter), drawn in `dur.cut` `cineOut`.
- Pressed = `spring.press` to the pressed scale; release = `spring.press` back. Press haptics per §2.10.
- Disabled = content at `ink4`, no hover, no press, `aria-disabled` / `Semantics(enabled: false)`, and a tooltip or helper line that says why.
- Loading inside a control = the leader sweep (§3.20) at 16 px replacing the leading icon; the label stays and changes to its progressive form ("Saving…"). Width is locked to the pre-loading width so nothing reflows.

### 3.1 Buttons

| Variant | Visual | Use |
|---|---|---|
| **Primary** | Fill `ink`, text `#000` `type.label`, radius `frame`, height 44 (lg 52, sm 36), padding x 20 (lg 28, sm 14), leading icon 20 Fill | The one main action per view: Read, Continue Ch. 142, Sign in, Save |
| **Primary · play** | As primary, height 52, leading `play` Fill 22, label "Read" / "Continue · Ch 142" with the chapter in `type.timecode` inline | Hero and detail CTA |
| **Secondary** | Fill `inkA12`, text `ink`, no border | Follow, Add to list, secondary actions |
| **Outline** | Transparent, 1 px `hairlineStrong`, text `ink` | Tertiary in dense rows (Retry in rows, Storage settings) |
| **Text** | No fill, text `ink2`, underline on hover 1 px offset 4 | Inline links, "Show queue", "Mark all read" |
| **Danger** | Fill `danger`, text `#000` | Final destructive confirmations only (Delete, Sign out everywhere, Restore) |
| **Danger · quiet** | Text `danger`, transparent, 1 px `rgba(255,79,109,.4)` | Destructive entry points that open a confirm (Remove series, Revoke) |
| **Round icon** | 44 px circle, 1.5 px `hairlineStrong` ring, icon 20 Bold `ink`; over art the ring is `inkA48` and a 40 % black disc sits under it | "+ My list", "i" info, share, close on art |

States (all variants):

| State | Visual | Motion |
|---|---|---|
| default | as above | — |
| hover | Primary: fill `#FFFFFF` at 92 % blend (`#F9F9F6`) + `elev.spot` 12 % glow; Secondary: fill `inkA24`; Outline: `inkA06` wash; Text: ink + underline; Danger: brightness 1.08; Round icon: ring → `ink` | `dur.beat` `cineOut` |
| pressed | scale 0.97; Primary fill `#DADAD5`; Danger fill `#E6435F` | `spring.press` |
| focused | `border.focus` ring | `dur.cut` |
| disabled | Primary fill `n6` text `ink4`; others content `ink4` | — |
| loading | leader sweep 16 px replaces the icon, label in progressive form, pointer events off | sweep 1 rev/s |
| selected | Toggle buttons only (Round icon "+ My list" → `check` Fill, ring → `lamp`, icon `lamp`); the icon cross-morphs `dur.cut` | haptic `follow` |
| error | Does not exist on buttons; the error shows in the toast or inline line nearby, and the button returns to default | — |

### 3.2 Icon buttons (bare)

- 44 × 44 hit area, 24 px glyph (28 in reader chrome), no ring, `ink` (bars) or `ink2` (rows).
- hover: glyph `ink`, 36 px circle wash `inkA06` fades in `dur.beat`; pressed: scale 0.9 `spring.press`; focused: ring on the 36 px circle; disabled: `ink4`; loading: glyph swaps for a 20 px leader sweep; selected (toggle icons such as bookmark, pin, favourite, auto-scroll): Bold → Fill morph, `lamp` for pin and favourite, `ink` for others; error: glyph flashes `danger` for 2f then returns (plus the `error` haptic).
- Tooltip on hover after 500 ms dwell: `stage` band, `type.caption`, radius `hair`, 8 px above, fades `dur.beat`, with the shortcut in a keycap when one exists ("Bookmark this spot  B").
- Badge slot top-right (see §3.21).

### 3.3 Inputs (text, password, number, textarea)

- Height 48 (textarea min 3 lines, 96 px), fill `well`, radius `frame`, padding x 14, text `type.body` `ink`, placeholder `ink3`, label above in `type.eyebrow` `ink3`, helper below in `type.caption` `ink3`.
- **Focus signature:** a 2 px `lamp` underline draws left → right across the bottom edge over `dur.shot` `cineOut`; the label turns `ink`. No glow ring. Keyboard focus adds no extra ring (the underline is the ring); the underline has 19:1 luminance contrast change so it passes as a focus indicator.
- hover: fill `#282828`; pressed: n/a; disabled: fill `raised`, text `ink4`; loading (async validation, e.g. server URL): trailing 16 px leader sweep; error: underline `danger` fixed, helper line becomes the error in `danger` with a `warning-circle` 16 px. The field never shakes; the error line dissolves in over `dur.beat` and the `error` haptic fires once.
- Password: trailing icon button `eye` / `eye-slash`, not in tab order, tooltip "Show password" / "Hide password".
- Number (jump to page, go to chapter): `type.timecode` text, centred, width by content (min 56).
- Textarea (AI prompt): character counter in `type.timecode` `ink3` bottom-right, turns `warning` at 560 / 600 and `danger` at 600.

### 3.4 Search field

- Height 56 (phone 48), fill `well`, radius `frame`, leading `magnifying-glass` 22 `ink3`, text `type.bodyLg`, trailing clear `x` (when non-empty) and on desktop a `/` keycap hint.
- Focus: lamp underline draws; the leading glyph turns `ink`; on phone the field dollies to the top of the screen (`spring.dolly`) and the tab bar hides so the keyboard has room.
- While searching: the underline becomes a 2 px indeterminate "projector sweep" (a 30 % wide lamp segment travelling left → right in 1000 ms `linear`, looping).
- States: default, hover (fill `#282828`), focused (underline), disabled (n/a), loading (sweep), error (underline `danger` + inline line under the field "Search failed, try again" with a Retry text button).

### 3.5 Chips and filters

Two families.

- **Filter chips** ("text slates"): `type.eyebrow` labels in a row separated by `·` (`ink4`). Default `ink3`. Selected `ink` with a 6 px `lamp` dot 6 px before the label that scales in from 0 on `spring.whip`. hover `ink2`. pressed `ink` + scale 0.96. focused ring around the label. disabled `ink4`. Counts render as `type.timecode` after the label ("PINNED 4"). Horizontal scroll on phone with a 24 px right fade.
- **Token chips** (removable, selectable pills for recent searches, genres, example prompts, retention choices): height 32, fill `inkA12`, radius `frame`, `type.labelSm`. hover `inkA24`; pressed scale 0.96; selected fill `ink` text `#000`; focused ring; disabled `ink4` on `raised`; removable chips show a 16 px `x` on the right (hover only on desktop, always on touch).
- Loading: token chips that trigger an action (example prompts) show the 16 px leader in place of the label's first word; error: n/a.

### 3.6 Segmented control

- Track `well`, height 40, radius `frame`, padding 3. Segments `type.labelSm` `ink2`. The selected thumb is `ink` fill with `#000` text and slides between segments on `spring.whip` (shared-layout animation: Motion `layoutId`, Flutter `AnimatedAlign` driven by the spring).
- hover: segment text `ink`; pressed: thumb scale 0.97; focused: ring around the whole control, arrow keys move; disabled segment: `ink4`, skipped by arrows; haptic `segment`.

### 3.7 Stepper

- `−` and `+` round icon buttons (36) with a centred value in `type.timecode` 15. Holding a button repeats every 125 ms after a 375 ms delay. Bounds disable the button. Used for zoom, novel text size, line spacing, line width.

### 3.8 Toggles, checkboxes, radios

- **Toggle** (the one sanctioned pill): track 44 × 24, `well` off, `lamp` on; knob 20 px `ink`, travel 20 px on `spring.whip`; the track colour dissolves in `dur.beat`. hover: track brightens 8 %; pressed: knob widens to 24 px (a "shutter" stretch) during press; focused: ring around the track; disabled: track `raised`, knob `ink4`; loading (server-backed toggles such as mature content): knob shows a 12 px leader sweep; error: knob returns to the previous side on `spring.whip` and the row shows the error line.
- **Checkbox** (select mode, chapter picker): 20 px square, radius `hair`, 1.5 px `ink3` border; checked = `ink` fill with a black `check` Bold 14 that draws its stroke in `dur.beat`; indeterminate = `ink` fill with a 10 × 2 black bar; disabled (already downloaded) = `check-circle` Fill in `positive` at 60 %.
- **Radio** (skin picker, sort menus): 20 px circle, 1.5 px `ink3`; selected = 8 px `lamp` dot scaling in on `spring.whip`.

### 3.9 Sliders and the scrubber

- **Slider:** track 3 px `n7`, fill `lamp`, thumb 14 px `ink` circle. On press the track grows to 6 px and the thumb to 20 px on `spring.steadicam`; a value bubble (`stage`, `type.timecode`) appears 12 px above the thumb. Detent haptic every 10 %. Keyboard: arrows step, PageUp/PageDown step ×10, Home/End. Disabled: track `raised`, no thumb.
- **Reader scrubber** (the "timeline"): full-bleed 3 px rail at the bottom of the reader chrome, `n7` track, `lamp` fill; in Read-all mode the track is segmented per chapter with 2 px gaps. On touch or hover it grows to 6 px and the thumb appears at 12 → 20 px. Desktop hover shows a 120 px page-thumbnail preview above the pointer with "PAGE 18 / 64" in `type.timecode`; phone drag shows the same preview centred above the thumb. RTL mirrors. Release commits the jump with a `move.dissolve` of 250 ms on the page (no scroll animation across hundreds of pages).

### 3.10 Posters

The 2:3 cover is the atom of the skin.

- **Geometry:** 2:3, radius `frame`, `elev.1` inner hairline, `raised` placeholder, cover `object-fit: cover`, `object-position: 50% 20%`.
- **Captions:** discovery walls (Home rails, source catalogue, For you) have no captions at rest; library and continue contexts show `type.cardTitle` (1 line, 2 at text scale ≥ 1.5) + `type.timecode` `ink3` ("CH 142 · NEW").
- **Overlays:** NEW badge top-left (§3.21), 18+ badge top-right when the series is adult and visible, downloaded mark bottom-right (`check-circle` Fill 16 `positive` on a 20 px black disc), progress hairline 2 px `lamp` flush at the bottom edge for started series, and a friend avatar stack (up to 2 × 18 px) bottom-left when friends are reading it.
- **States:**

| State | Visual | Motion |
|---|---|---|
| default | as above | image arrives with `move.rackFocus` |
| hover (desktop) | scale 1.06, brightness 1.08, `elev.lift` with the series `amb.glow`; siblings dim to brightness 0.55, saturate 0.8 | `spring.dolly`; siblings `dur.shot` |
| dwell 450 ms (Home) | the hero backdrop and ambient colour dissolve to this series | `move.dissolve` |
| dwell 700 ms / Space | the **preview slate** opens (§3.11) | `move.matchCut` from the poster rect |
| pressed | scale 0.97 | `spring.press`, haptic `press.card` |
| long-press 450 ms (touch) | lifts to 1.04 then the preview slate opens as a sheet | haptic `longPress` |
| focused (keyboard) | ring 2 px `ink` offset 3 + stage-1 lift + sibling dim; a 3 px × 24 px `lamp` "focus bar" slides under the poster on `spring.whip` | — |
| selected (select mode) | 2 px `ink` ring, cover brightness 0.7, checkbox top-right filled | `spring.whip` |
| disabled | "Unavailable on this profile": cover grayscale 100 %, brightness 0.4, caption `ink4` | — |
| loading | slate skeleton (§3.19) with the title card if the title is known | projector flicker |
| error (image failed) | `raised` frame, `type.cardTitle` title set bottom-left in `ink2`, `image-broken` 20 `ink4` top-right | — |

### 3.11 Preview slate

- A portal overlay, never a layout push. Desktop: 2.1 × poster width, grows from the poster rect on `spring.dolly` (the match cut); top half is a 2:1 backdrop (the cover, `blur.art`, grain, `move.kenBurns` at 2× speed) with the title in `type.section` doing the letter reveal; bottom half `overlay` with eyebrow (format · status · year · source), 2-line hook `type.body` `ink2`, and a button row: Primary · play "Read" / "Continue · Ch 142", Round icon "+" (follow), Round icon `share-fat` (recommend to), Round icon `info` (open detail).
- Phone and mobile web: a bottom sheet (§3.13) at 62 % height with the same content; the poster match-cuts into the sheet header.
- Closes on pointer leave after 250 ms grace (desktop), Esc, scroll, or tap outside. Exit is the reverse match cut at 0.75×.

### 3.12 Rails

- Header row: `type.section` H3 with the letter reveal (§6.1), optional `type.timecode` count, optional text button "See all" right-aligned with a `caret-right` that dollies 4 px on hover.
- Geometry per breakpoint: phone 3.3 visible posters (≈ 106 px wide at 375), tablet 5.3, desktop 6.25, wide 7.25, ≥ 1920 8.25. Gap `layout.railGap`. Rails start at the gutter and bleed off the right edge.
- **Motion signature, "the dolly track":** rails scroll on a critically damped spring snap (Embla `embla-carousel-react` 8.6.0 with `dragFree: true`, `skipSnaps: false`, snap duration mapped to `spring.dolly` via its `duration: 25` physics; Flutter `PageView`-less `ListView` with a custom `ScrollPhysics` whose `createBallisticSimulation` returns a `SpringSimulation(spring.dolly)` to the nearest poster edge). While velocity exceeds 2400 px/s posters get `blur.motion`; on settle the visible posters get a 250 ms `move.rackFocus` (a small one: 6 px, brightness 0.8 → 1).
- Desktop paddles: 48 px zones over `scrim.railEdge`, `caret-left` / `caret-right` 28 `ink`, visible on rail hover; click pages by (visible − 1) posters on `spring.dolly`; the sound `focus` plays once per page.
- Keyboard: fixed-left focus. Focus stays in the first full slot and the rail slides beneath it on `spring.whip`; ←/→ move, ↑/↓ change rail (the page scrolls so the focused rail sits at 30 % of the viewport, `spring.dolly`), Enter opens detail, Space opens the slate, Home/End jump; one Tab stop per rail (roving tabindex).
- Special rail shapes: **Continue** (16:9 cards, see §3.14), **Top 10 on this server** (outline numerals `type.statHuge` stroke 2 px `inkA48`, black fill, sitting half behind each poster's left edge), **Networks** (16:9 source hub tiles), **Previously on** (2:1 banner, §5.1.3).
- States: loading = header renders immediately (static string) + 7 slate posters; empty = the rail is not rendered at all (no empty rails on Home); error = a single-line row in place of posters: `cloud-slash` 16 `ink3` "This row didn't load." + text button "Retry"; offline = rails that need the network are replaced by one "Offline · showing what's on this device" row at the top of the page.

### 3.13 Sheets

- `overlay` surface, top radius `sheet`, `elev.3`, drag handle 36 × 4 `ink4` centred 8 px from the top, max width `layout.sheetMaxW` centred on tablet and desktop, safe-area bottom padding.
- Open: `move.fadeUp` (barrier 0 → 0.72, sheet rises from below on `spring.dolly`, page behind racks to `blur.dof`). The stage does not shrink. Close: reverse on `spring.steadicam`.
- Detents: `content` (fits content up to 62 %), `full` (100 % minus the top safe area + 8 px). Flutter `smooth_sheets` 1.2.0 (`SheetOffset` detents, spring physics set to `spring.dolly`); web Base UI `Dialog` (`@base-ui/react` 1.8.0) positioned as a sheet, drag handled with Motion `drag="y"` and `dragConstraints`, release velocity into `spring.dolly`. Snap to full plays haptic `sheet.detent`.
- Dismiss: drag down past 30 % of its height or a flick > 800 px/s, barrier tap, Esc, system back.
- States: default; loading (content area shows its own skeleton, the sheet height locks at 62 %); error (inline error block inside the sheet, §3.24); the sheet itself has no hover, pressed or disabled states.
- On desktop ≥ 1024 the reader settings, type settings and cast sheets become **side panels** (§3.15) instead of bottom sheets.

### 3.14 Cards

| Card | Visual | Motion and states |
|---|---|---|
| **Continue card** | 16:9, radius `frame`, cover cropped `50% 20%`, `scrim.posterCaption`, title `type.cardTitle`, timecode "CH 142 · PAGE 18 / 64" or "CH 88 · 42 %", 3 px `lamp` progress flush at the bottom, `play` Fill 28 in a 44 px black disc centred on hover | hover: push-in scale 1.04 on the image only (the frame stays), disc fades in `dur.beat`; pressed: 0.97; focused: ring; loading: slate; error: title card fallback |
| **Hero continue card** (desktop Library) | 2.39:1, 420 px min height, full cover `blur.art` backdrop + sharp 2:3 poster left, title `type.display`, CTA Primary · play | enters with a 3-beat choreography (backdrop dissolve, title letter reveal, CTA dolly 16 px) |
| **World card** (AI and world recommendations) | Two visibly different states. **Available**: poster 2:3 + title + "ON {SOURCE}" eyebrow in `ink` + Primary sm "Read". **Info only**: poster at brightness 0.75 with a dashed 1 px `inkA24` frame, eyebrow "NOT ON YOUR SOURCES" in `ink3`, rating "★ 8.4" in `type.timecode`, official platform links as text buttons, Secondary sm "Search my sources" | available cards lift like posters; info cards do not lift, only brighten 1.0 → 1.08 |
| **Source hub tile** ("network") | 16:9, the source's latest cover `blur.art` tinted with its ambient tint, source name `type.display` sm (36/32), favicon 28 px top-left, health dot top-right (positive / warning / danger), 18+ badge when adult | hover: backdrop Ken Burns starts and the name tracks out +0.02 em; pressed 0.97 |
| **Stat card** | `stage`, radius `frame`, eyebrow label, `type.statHuge` value that **counts up** over `dur.reveal` `cineOut` on first view (tabular, so width never changes), caption `ink3` | counts up once per session per card |
| **Collection banner** | 21:9, radius `frame`; a 4-poster "contact sheet" collage (posters 2:3, overlapping by 24 %, each rotated 0°), name `type.display` sm, count `type.timecode`, shared badge (§5.3) | hover: the four posters fan 8 px apart on `spring.dolly` |
| **Activity card** (social) | row, see §5.3 | — |
| **Notification card** | row, see Updates §4.19 | — |

### 3.15 Dialogs and side panels

- **Dialog:** `overlay`, radius `sheet`, width 480 (confirm) / 640 (content), max height `100dvh − 64`, padding 24, title `type.section` (no letter reveal inside dialogs: dialogs must read instantly), body `type.body` `ink2`, actions right-aligned (phone: stacked full width, primary on top). Open `move.fadeUp` centred (rise 16 px); close `dur.beat` `cineIn`. Esc closes, focus trap, focus restore, `role="dialog" aria-modal`. Flutter: `showGeneralDialog` with the same curve pair.
- **Confirm pattern for destructive actions:** the danger button is disabled for 1000 ms after the dialog opens (a thin `danger` bar fills under it over that second) so a double tap cannot confirm by accident.
- **Typed confirmation** (Restore backup): input "Type RESTORE to continue"; the danger button enables only on an exact match.
- **Side panel** (desktop reader and settings): 380 px wide, full height, `overlay`, left hairline, slides in from the right on `spring.dolly` while the reading column dollies left by half the panel width so the page stays centred in the remaining space. No barrier; Esc closes.

### 3.16 Toasts ("subtitles")

- Bottom-left (phone: bottom centre above the tab bar, 16 px margin), `stage` band, radius `hair`, padding 10 × 14, `type.bodyStrong` `ink`, optional leading icon 16 and one text action ("Undo", "View").
- Enter: fade 0 → 1 `dur.beat` + rise 8 px `cineOut`. Hold 3.2 s (6 s with an action). Exit fade `dur.beat` `cineIn`. Stack max 3, newest at the bottom, older ones dolly up on `spring.steadicam`. Swipe left or down to dismiss.
- Tones: neutral (ink), success (4 px `positive` left edge), error (4 px `danger` left edge + `error` haptic), offline (4 px `warning` left edge).
- Web: `sonner` 2.0.8 with `unstyled` and the skin's classes; Flutter: an `OverlayEntry` stack in `cinematic/primitives/subtitle_toast.dart` (no Material SnackBar).
- Reader toasts (bookmark saved, stale anchor) appear top-centre 80 px below the safe area so they do not cover the reading line.

### 3.17 Tabs (in-page)

- "Slate tabs": `type.eyebrow` labels, `ink3`; active `ink` with a 2 px `lamp` underline 6 px below that **stretches** between tabs (the leading edge leads on `spring.whip`, the trailing edge follows 42 ms later, so the bar elongates in flight and settles to the label width).
- hover `ink2`; pressed `ink`; focused ring around the label; disabled `ink4`; tab content transitions are **cuts** (0 ms) followed by a 250 ms `move.rackFocus` on images.
- Swipe between tab pages on phone: horizontal `PageView` with the underline tracking the drag position.

### 3.18 Bars: top bar, transport bar (phone), Reel Index (desktop sidebar)

**Top bar (all non-reader screens)**

- Desktop: 64 px, transparent over heroes with `scrim.topChrome`, becomes `#000` with a bottom `hairline` after 80 px of scroll (`dur.shot`). Left: page slug (`type.eyebrow` path such as "LIBRARY / COLLECTIONS") that fades in only once the page title scrolls under the bar. Right: search pill (desktop only: 280 px mini search field that opens the command palette), `bell` icon button with badge, clock `type.timecode` "21:40" (ticks every 30 s), profile avatar 32 px.
- Phone: 56 px + safe area. Left: page title in `type.display` at rest; on scroll it **pins and shrinks** into a 17 px `type.section` title on the bar (`spring.crane` scrubbed by scroll position, not time). Right: up to 3 icon buttons.
- States: default, scrolled (black + hairline), hidden (reader), offline (a 20 px `warning` "OFFLINE" micro badge appears left of the bell).

**Transport bar (phone app and mobile web, below 768 px)**

- `#000`, 64 px + safe area, top `hairline`. Five destinations: Home `house`, Library `books`, Search `magnifying-glass`, Downloads `download-simple`, More `dots-three`. Icons 24 Bold `ink3`; the active icon becomes Fill `ink` with its `type.micro` label under it; a 2 px × 24 px `lamp` bar at the top edge whips to the active tab on `spring.whip`.
- Hides on downward scroll past 48 px (translate 100 % on `spring.steadicam`) on feeds only (Home, Library grids, source catalogue, search results); returns on upward scroll of 16 px or at the top. A 2 px `lamp` line at the very bottom edge shows while hidden only when a download or narration is running (the "tally light").
- Badges: Downloads shows queued + downloading + failed as a count badge; More shows the unread-updates dot.
- Tap on the active tab scrolls to top on `spring.crane`; a second tap focuses the search field (Search tab) or opens the profile switcher (Home tab long-press).
- Tab change: `move.reelChange` + haptic `tab`. Each tab keeps its own stack and scroll offset.

**Reel Index (desktop sidebar, web ≥ 768)**

- `#000`, right `hairline`. Expanded 248 px (≥ 1280 by default), collapsed 72 px (768–1279 by default, and by `mod+b`). Width animates on `spring.steadicam`; labels fade `dur.beat`, items stagger 20 ms on expand.
- Top: MM column mark 28 px + wordmark (expanded). Then the content-mode switch (`MANGA · NOVELS` text slate; collapsed: two stacked 40 px icon buttons `books` / `book-open-text`).
- Groups (eyebrow headers, hidden when collapsed): **WATCH** Home, Library, For you; **FIND** Search, Sources, Updates (badge); **KEEP** Downloads (badge), Collections, Bookmarks, History; **YOU** Activity (dot), Stats, Dialogue search (manga mode only).
- Footer: profile row (avatar 28 + name + `caret-up-down`, opens the profile switcher menu), Settings, Status (admin only), collapse toggle.
- Item: 40 px, icon 22 + `type.bodyStrong`. States: default `ink3`; hover `ink2` + `inkA06` wash; active `ink` + icon Fill + a 2 × 20 px `lamp` bar on the left edge that whips between items on `spring.whip`; focused ring inset 2 px; collapsed: tooltip right with the label and shortcut ("Library  G L").
- Section change plays `move.reelChange` on the content area only (the sidebar never animates away).

### 3.19 Skeletons ("slates")

- No shimmer anywhere. Placeholders are `raised` frames with an inner hairline; a projector flicker pulses opacity 0.6 → 1 over 1400 ms `drift` alternate, phase offset 60 ms left to right.
- When the title is known before the image, the placeholder is a **title card**: `type.cardTitle` in `ink3` bottom-left, 10 px inset.
- Text skeletons: bars of `raised` 10 px tall, radius `hair`, widths 92 / 78 / 64 % cycling.
- Each screen specifies its slate shape in §4.

### 3.20 Progress and loading

- **Bar:** 3 px, square ends, `n7` track, `lamp` fill, width animates on `spring.steadicam`. Indeterminate: the projector sweep (30 % segment, 1000 ms `linear`).
- **Leader sweep** (replaces every spinner): a circle drawn like an SMPTE leader, 40 px (24 inline, 16 in buttons): conic sweep one revolution per 1000 ms `linear`, 1 px crosshair and 1 px ring `rgba(245,245,241,.3)`, sweep fill `rgba(245,245,241,.22)`. Shown only after 400 ms of waiting (earlier waits show nothing).
- **Countdown ring:** the same leader drawn with a `lamp` sweep over 5000 ms, used for Up Next and auto-advance.
- **Download ring:** 20 px, 2 px `lamp` arc for saving, `positive` full ring + `check` for saved, `warning` arc for incomplete, `danger` ring + `warning-circle` for failed, dashed `ink3` ring for queued.
- **Reel meter** (Downloads storage): a horizontal strip of 40 "film frames" (6 × 10 px each, 2 px gaps) that fill left to right with `lamp` as usage grows; frames above the cap outline in `warning`.

### 3.21 Badges

Radius `hair`, height 18, padding x 6, `type.micro`.

| Badge | Visual |
|---|---|
| NEW / "3 NEW" / "99+ NEW" | `lamp` fill, `#000` text |
| 18+ | 1 px `danger` outline, `danger` text |
| DOWNLOADED | 1 px `positive` outline, `positive` text |
| ONGOING / COMPLETED / HIATUS | 1 px `inkA24` outline, `ink3` text |
| Reading status (READING, ON HOLD, PLAN TO READ, DROPPED, COMPLETED, UNREAD) | `ink3` outline; READING uses `lamp` outline + `lamp` text |
| ADMIN / YOU / DEACTIVATED | `ink3` outline / `ink` outline / `danger` outline |
| LIVE (friend reading now) | `ember` 6 px dot that breathes 0.6 → 1 opacity over 1400 ms `drift` + "READING" `ember` text |
| Count dot (tab and icon) | 16 px min, `lamp` fill, `#000` `type.micro`, "9+" above 9; pops in with scale 0 → 1 on `spring.whip` (no overshoot) |

### 3.22 Lists and rows

- Row min height 56 (dense 44, two-line 72), padding x = gutter on phone and 16 inside panels, `type.bodyStrong` primary + `type.caption` `ink3` secondary, leading 40 px thumbnail (2:3 cover 32 × 48, icon tile 40, avatar 40), trailing control or `caret-right` 18 `ink4`. Separators `border.hair` inset from the leading content.
- hover `inkA06` wash `dur.beat`; pressed `raised` + scale 0.99; focused ring inset; selected `lamp` 2 px left edge + `inkA06`; disabled `ink4`; loading: slate rows; error rows: `dangerDim` wash with inline retry.
- **Swipe actions (phone):** flat colour slabs revealed from the trailing edge, 88 px each, labels `type.labelSm` under a 20 px icon; commit threshold 60 % with haptic `segment`; slab colours `n5` (neutral), `danger` (remove), `lamp` (mark read, text black). Release retracts on `spring.dolly`.
- **Drag to reorder** (collections, pins): long-press 450 ms lifts the row (scale 1.03, `elev.lift`), others dolly apart on `spring.dolly`; drop `medium` haptic.
- **Chapter row:** ordinal `type.timecode` 40 px column (`amb.accent` dot at left when unread), title `type.body` (read rows `ink3`), subline `type.caption` ("Today · 42 pages" / "18 / 42" in `lamp` / "Read"), trailing download ring; the "you are here" row has a 2 px `amb.accent` left edge.

### 3.23 Menus and context menus

- **Menu** (popover): `overlay`, radius `frame`, `elev.3`, min width 200, item 40 px `type.body`, leading icon 18, trailing shortcut keycap or check. Opens from its trigger with a 6 px drop + fade on `spring.steadicam` (origin at the trigger), closes `dur.beat`. Keyboard: arrows, Home/End, typeahead, Enter, Esc. hover/focus: `inkA06` wash + `ink`; disabled `ink4`; selected `check` 16 `lamp`; destructive items `danger`.
- **Context menu:** desktop right-click on posters, rows and chapters opens the same menu at the pointer. Phone long-press opens the **preview slate sheet** (§3.11) with the actions list below the preview: Open, Read / Continue, Follow / Unfollow, Favourite, Add to collection, Recommend to…, Download next 10, Mark read / unread, Share card.
- Web: Base UI `Menu` and `ContextMenu`. Flutter: `MenuAnchor` restyled, anchored at the long-press position for rows; the slate sheet for posters.

### 3.24 Empty, error and offline states ("title cards")

One component, `TitleCard`, with three tones. Layout: centred column, max width 440, a 40 px icon in `ink3` (tone colour for error and offline), headline in `type.editorial` (Instrument Serif) typed at 50 ms per character (§6.2), body `type.body` `ink2`, up to two actions (primary + text).

| Tone | Icon colour | Headline example | Actions |
|---|---|---|---|
| empty | `ink3` | "Nothing on this shelf yet." | primary "Browse sources" |
| error | `danger` | "This scene didn't load." | primary "Try again", text "Go home" |
| offline | `warning` | "You're offline." | primary "Try again", text "Open downloads" |

- Offline auto-retries when connectivity returns (3 s cooldown); the headline types again as "Back online." for 1.5 s before the content cuts in.
- A reference chip (`type.timecode` in a `raised` hair-radius box) shows a digest id under route errors.

### 3.25 The 18+ gate

Three surfaces, one visual language (the film rating card).

1. **Gate dialog** ("Enable mature content?"): a full-screen black takeover on phone, a 640 px dialog on desktop. Top-left a 3 × 44 px `danger` bar beside "18+" in `type.display` and the descriptor line "Adult sources, search results and recommendations" in `type.caption` `ink2`. Body text: "This shows adult (18+) sources, search results and recommendations for this profile. Only continue if you are of legal age to view mature content where you live. You can turn it off at any time." Actions: text "Cancel", Danger "I am 18 or older, enable". The danger button has the 1000 ms arm delay. Success plays AHAP `vault`, sound `rating`, and the rating bar sweeps full width once (`dur.scene` `cineOut`) before the dialog dissolves.
2. **Rating card** (informational, never blocking): when an 18+ series opens (detail) and at reader start, top-left under the chrome: `danger` bar 3 × 44, "18+" `type.display` sm, descriptors from tags ("Violence · Sexual content") `type.caption` `ink2`. Fade in `dur.shot`, hold 4000 ms, fade out `dur.scene`.
3. **Hidden content**: sources, series, recommendations and social activity that the active profile cannot see are not rendered at all. A pinned source the profile cannot see renders as the disabled poster/row "Unavailable on this profile". A friend's activity on an adult series shows to a non-mature profile as "Reading something not shown on this profile" with no cover and no title.

### 3.26 Other primitives

- **Avatar:** circle, sizes 24 / 32 / 40 / 64 / 120 / 160. Profile avatars are one of 12 "film stock" gradients (two-stop linear at 135°) with a Phosphor glyph in `ink`: Tungsten `#FFB547→#8A4B00` `sun`, Ember `#FF6A3D→#7A1406` `flame`, Neon `#FF4FD8→#4A0B6B` `lightning`, Teal `#3DD6C8→#063D3A` `waves`, Cobalt `#4F7BFF→#0B1A5C` `planet`, Moss `#8BD65A→#1E3D0A` `leaf`, Rose `#FF8FA3→#5C0B1E` `heart`, Violet `#A98BFF→#27115C` `moon-stars`, Sand `#E6C79A→#4D3719` `book-open`, Steel `#B8C4CC→#26313A` `sword`, Crimson `#FF4F6D→#4A0613` `skull`, Night `#5F5F5C→#0E0E0E` `ghost`. Focus/selected: 2 px `ink` ring offset 3.
- **Keycap:** `raised`, 1 px `hairlineStrong`, radius `hair`, `type.kbd`, min width 20, height 20; Mac glyphs ⌘ ⌥ ⇧.
- **Pull to refresh:** pulling down reveals a leader sweep whose sweep angle tracks the pull (0 → 360° at 96 px); passing 96 px arms it (haptic `refresh.armed`, sweep turns `lamp`); release spins at 1 rev/s until done; content dollies back on `spring.dolly`.
- **Banner (inline notice):** full-width row inside the page, `stage`, 4 px left edge in the tone colour, icon 20, `type.body`, optional action; enters with a height reveal on `spring.steadicam`.
- **Bulk action bar:** `stage` `elev.2` bar docked to the bottom (above the tab bar on phone), radius `frame`, max width 896; count in `type.timecode`, actions as icon + label buttons; rises on `spring.dolly` when the first item is selected; running state shows the progress bar and "12 of 40 · 1 failed" with Stop.
- **Download bar** (chapter picker): same shell as the bulk bar with helper token chips "Next 10", "All unread", "Whole book" and Primary "Download 12".
- **Content-mode switch:** `MANGA · NOVELS` filter-chip slate; switching plays `move.reelChange` over the whole content area.
- **Command palette ("Slate"):** see §4.2.
- **Tooltip:** `stage`, radius `hair`, `type.caption`, after 500 ms dwell, `dur.beat` fade, keycaps inline.

---
## 4. Screens

### 4.0 Frames, navigation map and platform rules

**Frames.** (a) *Boot* (pre-roll, setup): no chrome. (b) *Auth* (login, register): no chrome, full-bleed poster wall. (c) *Casting* (profile picker, profile form): no chrome. (d) *App frame desktop* (web ≥ 768): Reel Index sidebar + top bar. (e) *App frame phone* (app, mobile web < 768): top bar + transport bar. (f) *Feature presentation* (manga reader): no app chrome, reader chrome only. (g) *Page* (novel reader): no app chrome, painted in the reading stock. (h) *Landscape phone reader*: no bars at all until summoned.

**Route map** (paths go into `design/contract.json`; new routes marked ✚):

| Screen | Path | Phone entry | Desktop entry |
|---|---|---|---|
| Home ✚ | `/` (web), `/home` (app) | Tab 1 | Reel Index · Home |
| Library | `/library` | Tab 2 | Reel Index · Library |
| Browse all | `/library/browse` | Library · "All titles" | Library · "All titles" |
| Title page (followed) | `/library/:seriesId` | poster tap | poster click |
| Title page (source) | `/sources/:sourceId/series/:seriesId` | poster tap | poster click |
| Book page (novel) | same path as source title page | book row tap | book row click |
| Manga reader | `/reader/:sourceId/:seriesKey/:chapterKey` (web), `/library/read/…` and `/sources/…/read` (app) | Read / Continue | Read / Continue |
| Read-all | `/read-all/:sourceId/:seriesKey` (web), `?all=1` (app) | title page · "Read all" | same |
| Novel reader | `/novels/:sourceId/:seriesKey/:chapterKey` | Start / Continue | same |
| For you | `/library/recommendations` | Home · "For you" rail header, More | Reel Index · For you |
| Stats | `/library/statistics` | More · Stats, streak chip | Reel Index · Stats |
| Wrapped ✚ | `/library/statistics/wrapped/:year` | Stats · "Your year" | same |
| Activity ✚ | `/activity` | Home · friends rail header, More | Reel Index · Activity |
| Search | `/search` | Tab 3 | Reel Index · Search, `mod+k` then Enter |
| Sources | `/sources` | Search tab · "Networks", More | Reel Index · Sources |
| Source catalogue | `/sources/:sourceId` | network tile | network tile |
| Updates | `/updates` | bell, More | bell, Reel Index |
| Downloads | `/downloads` | Tab 4 | Reel Index |
| Collections | `/library/collections` (web), `/collections` (app) | Library · Collections tab | Reel Index |
| Collection detail | `…/:collectionId` | banner tap | banner click |
| History | `/library/history` | Library · History tab | Reel Index |
| Bookmarks | `/library/bookmarks` | Library · Bookmarks tab | Reel Index |
| Dialogue search | `/ocr` (web), `/ocr/search` (app) | More | Reel Index (manga mode) |
| More | `/more` | Tab 5 | URL only |
| Settings | `/settings` (+ `/settings/:section` ✚ on web) | More | Reel Index footer |
| Storage / Backup / Diagnostics | `/settings/storage`, `/settings/backup`, `/settings/diagnostics` | Settings rows | Settings sections |
| System status | `/admin/status` | Settings · Admin | Reel Index footer (admin) |
| Profiles | `/profiles`, `/profiles/create`, `/profiles/edit/:id`, `/profiles/manage` | gate, avatar | gate, profile menu |
| Auth | `/login`, `/register`, `/setup` (app) | router | router |

**Platform rules applied to every screen below** (each screen lists only its exceptions):

- *Desktop web:* hover states, keyboard-first, `mod+k` palette, `?` shortcuts, `g` then a letter jumps sections (`g h` Home, `g l` Library, `g s` Search, `g o` Sources, `g u` Updates, `g d` Downloads, `g c` Collections, `g t` Stats, `g a` Activity, `g ,` Settings). Scroll is Lenis 1.3.26 (`lerp: 0.12`, `wheelMultiplier: 1`, `smoothTouch: false`) on non-reader pages so scroll-scrubbed choreography reads smoothly.
- *Mobile web:* identical layout to the phone app; no haptics except Android `navigator.vibrate` rows; back is the browser back with `move.pull` played by the View Transitions API; safe-area insets respected; standalone PWA hides the browser bar.
- *iOS:* full-width edge back swipe on every pushed screen (`swipeable_page_route` 0.4.8 with the `move.pull` spring), status bar light, home indicator auto-hides in readers, haptics via gaimon AHAP.
- *Android:* predictive back (the outgoing page scales to 0.94 and dims as the gesture progresses, commit on release plays `move.pull`), edge-to-edge with transparent system bars, 120 Hz requested, haptics via converted waveforms.
- *Transitions:* section changes use `move.reelChange`; forward inside a section uses `move.matchCut` when a shared element exists, otherwise `move.push` (phone) or `move.dip` (desktop); back is the reverse at 0.75×.
- *States:* every data screen resolves to loading / offline / error / empty / content; the §3.24 title card handles the last four unless a screen says otherwise.

### 4.1 Native splash and pre-roll (boot)

- **Native layer:** iOS launch storyboard and Android 12 SplashScreen both show the neutral MM column mark (`#F5F5F1` on `#000000`, 192 dp visible circle). `flutter_native_splash` 2.4.8 generates both. Web: the root layout server-renders the same SVG centred on black.
- **Pre-roll ("Projector Roll"), cold start, ≤ 1600 ms, once per app session:** the full sequence is in §7.4. It plays over the router's auth probe; its length is `max(dataReady, 900 ms)` capped at 1600 ms.
- **Slow boot:** if auth has not resolved at 1600 ms, the wordmark holds on black with the lamp bloom breathing (0.18 ↔ 0.30 over 1400 ms `drift`); after 2400 ms a 24 px leader sweep appears 32 px under the wordmark with the typed line "Connecting to {host}".
- **Offline boot with a cached session:** the pre-roll finishes normally, then Home opens with the offline banner.
- **Server unreachable, no cached session:** the typed line becomes "Can't reach {host}." with Primary "Try again" and text "Change server" (app) under it.
- **Warm start** (resumed within 4 h, or web after the first navigation): the mark fades in over 200 ms and flies to its nav slot (250 ms), no letters, no haptic.
- **Tap anywhere** skips to the handoff.
- **Reduced motion:** 200 ms crossfade of the static lockup, then a 200 ms crossfade to Home.

### 4.2 Global overlays (web): command palette "Slate" and shortcuts sheet

**Slate (`mod+k`)**

- Desktop: 640 px wide, top at 14 vh, `overlay`, radius `sheet`, `move.fadeUp` (the page racks to `blur.dof`). Phone web: full-screen sheet.
- Input 56 px (§3.4) placeholder "Search titles, sources, pages and actions". Results list max 60 vh, grouped under eyebrow headers in this order: **Continue** (top 3 continue items), **Library** (debounced 220 ms `GET /library/search`), **Sources**, **Go to** (every route), **Actions** (Open settings, Switch profile, Toggle Manga/Novels, Check for updates now, Sign out, Switch skin to Glass…), **Recent**.
- Row 48 px: 32 px visual (2:3 cover, favicon, or icon tile), title with matched graphemes in `lamp`, subtitle `ink3`, `↵` keycap on the active row. The active row has a `lamp` 2 px left edge that whips between rows on `spring.whip`.
- Footer keycaps: `↑ ↓` move · `↵` open · `⇥` switch group · `esc` close; result count `type.timecode`.
- States: empty query shows Continue + Recent; searching shows the projector sweep under the input; no results types "Nothing matches “{q}”." in `type.editorial`; offline limits results to Go to and Actions with an "Offline" micro badge.
- Choosing a series result plays `move.matchCut` from the row thumbnail to the title page hero.

**Shortcuts sheet (`?`)**

- Right side panel 380 px (§3.15), title "Keyboard", intro "Only what works on this screen is listed. Shortcuts pause while you type." Groups (General, Navigation, this screen) with rows of description + keycaps. Empty: "No shortcuts on this screen."
- The same live registry renders in Settings → Keyboard.

### 4.3 Setup (app only, first run)

- **Layout (phone):** black; the MM column mark 56 px top-left at the gutter; headline typed at 50 ms: "WHERE'S YOUR SERVER?" in `type.slug`; body "ManhwaManiacs connects to your own server. Enter its address." `type.body` `ink2`; field "Server address" (URL keyboard, leading `hard-drives` 20) prefilled with the build default; Primary lg "Connect" full width, pinned above the keyboard.
- **Tablet (iPad, Android tablet):** the same column, 440 px wide, centred, with a slow Ken Burns of a neutral film-grain plate behind (no series art is available before setup).
- **Signature moment:** on success the field's lamp underline races to 100 % width, the headline tracks out, and the pre-roll plays in full as the first "screening".
- **States:** pending (field disabled, button "Connecting…" with the leader), error (field error line: "That address didn't answer. Check it and try again." or the server's message; https required in release builds: "Use an https:// address."), success (as above).
- **Gestures:** none beyond the keyboard. Enter submits.

### 4.4 Login

- **Layout, desktop web:** a full-bleed **poster wall**: 6 slow columns of public-safe placeholder posters (the brand's own abstract film-stock gradients, never series art, since nothing is authenticated yet) scrolling vertically at 12 px/s alternating up/down, dimmed to brightness 0.25 with `scrim.vignette`. A left column (max 440, at 12 % from the left) holds: wordmark lockup 40 px tall, typed headline "WELCOME BACK." (`type.slug`), body "Sign in to your ManhwaManiacs server.", server host line `type.timecode` `ink3` "SERVER · manhwamaniacs.xyz" with a copy icon button, Username field, Password field (reveal toggle), "Keep me signed in" toggle row (default on), Primary lg "Sign in", text "Create an account" (when registration is open).
- **Phone and mobile web:** the wall shrinks to 3 columns behind the top 40 % of the screen, fading into black with `scrim.heroFoot`; the form sits below in a single column; the Sign in button stays pinned above the keyboard.
- **Bootstrap variant** (no accounts exist): headline "FIRST SCREENING." body "This server has no accounts yet. The first account becomes the administrator." and one Primary "Create the first account".
- **Signature moment:** on success the wall columns accelerate (12 → 600 px/s over 500 ms `cineIn`, with `blur.motion`) and cut to black, then the profile picker opens with its casting spotlight. The feeling is a reel spinning up.
- **States:** pending (fields disabled, "Signing in…"), error (inline block under the password: "Wrong username or password." / "Enter your username and password." / server message, `danger` edge), offline ("You're offline. Signing in needs the server." with Retry), 401 mid-session lands here with a toast "You were signed out."
- **Keys (web):** Enter submits from any field; `mod+enter` too. Tab order: username, password, keep me signed in, sign in, create account.
- **iOS/Android:** autofill hints (`username`, `password`), Android credential manager and iOS Passwords appear natively.

### 4.5 Register

- Same frame as Login. Headline variants: "CLAIM THIS SERVER." (bootstrap), "JOIN THE CREW." (open or invite), "REGISTRATION CLOSED." (closed).
- Fields: Username; Password (helper "At least 8 characters"); Confirm password; Invite code (only when required and not bootstrap, leading `key`); Display name (optional); Email (optional). Primary lg "Create account" / "Create the administrator account". Text "I already have an account".
- Closed variant: body "This server isn't taking new accounts. Ask the administrator." + Primary "Back to sign in".
- Validation lines (inline, per field, on blur and on submit): "Choose a username.", "Password must be at least 8 characters.", "Passwords don't match.", "Enter the invite code.", "Enter a valid email address or leave it empty."
- Signature and success: same reel spin-up into the picker (a fresh account lands on the empty picker state).
- Back: phone back returns to Login with `move.pull`.

### 4.6 Profile picker, "Casting call"

- **Layout:** black stage, a single overhead spotlight: a soft radial `rgba(245,245,241,0.08)` ellipse (70 % × 45 % of the viewport) centred behind the row of profiles. Headline `type.display` letter reveal "WHO'S READING TONIGHT?", sub `type.bodyLg` `ink2` "Pick a profile." Profiles in a centred row (wrap to 2 rows on phone): avatar 120 px (phone 96) + name `type.bodyStrong` + `type.timecode` `ink3` last-read line ("CH 142 · OMNISCIENT READER"). An "Add profile" tile (dashed circle, `plus` 32) while fewer than 5 profiles exist. Text button "Manage" top-right.
- **Desktop web:** avatars 160 px, keyboard ←/→ between tiles with fixed spotlight that **slides to the focused tile** on `spring.crane`; Enter picks; `e` edits the focused profile; `n` adds.
- **Entrance choreography:** the spotlight fades up (`dur.dissolve`), the headline reveals, tiles dolly up 24 px with a 42 ms stagger.
- **Signature moment, "spotlight pick":** on tap the other tiles fall back into darkness (brightness 0.2, scale 0.94, `dur.shot`), the spotlight narrows onto the chosen avatar (`spring.crane`), the avatar match-cuts to the top-bar avatar slot of Home while the black stage dissolves into Home's hero. Total 900 ms, skippable. Haptic `stamp` on the pick. If the profile's skin differs from the device mirror, the skin restart runs inside this transition (§4.28.2).
- **Manage mode:** tiles show a `pencil-simple` 24 px in a black disc over the avatar and gently breathe (brightness 0.9 ↔ 1, 1400 ms); tap opens the profile form; the Manage button reads "Done".
- **Gestures:** tap = pick; long-press = edit (haptic `longPress`).
- **States:** loading (3 slate circles), empty ("Create your first profile." typed, body "Each profile keeps its own library, progress, downloads and 18+ setting.", Primary "Add profile"), error with no cached profile ("Profiles didn't load." + Retry), offline with a cached profile ("You're offline. Continue as {name}, or retry." with the single cached tile and Retry).

### 4.7 Profile form (add, edit) and Manage profiles

- **Phone:** full-screen page, top bar title "New profile" / "Edit profile", back. **Desktop web:** a 640 px dialog over the picker or over Manage profiles.
- **Content:** a live preview at the top (avatar 120 with the name typed below it as you type, lit by the chosen stock's glow); Name field (max 40 visible, 255 stored, counter); **Avatar** grid of the 12 film-stock avatars (§3.26), 56 px, selected ring `ink`; **Ambience** (the profile's mood tint for the shell, 7 options as token chips with a 10 px colour dot: Romance `#FF8FA3`, Action `#FF6A3D`, Comedy `#FFD166`, Horror `#8A1C0E`, Slice of life `#8BD65A`, Fantasy `#A98BFF`, None `#767674`); **Mature content (18+)** toggle with helper "Show 18+ sources and series on this profile" (turning it on opens the gate dialog §3.25); **Share my reading with friends** toggle (social, §5.3, default off) with helper "Other accounts on this server can see what this profile reads. 18+ titles are never shared."; Primary "Create profile" / "Save changes"; Danger · quiet "Delete profile" (edit only) → confirm dialog "Delete {name}? Its library, progress, bookmarks and downloads on this device are removed. This can't be undone."
- **Manage profiles (web `/profiles/manage`, desktop):** the picker layout at 120 px tiles with every tile in manage mode, plus a "Use" text button under each; no spotlight animation beyond the entrance.
- **States:** loading (edit), not found ("That profile is gone." + Back), error inline under the name, pending (button leader).
- **Motion:** selecting an ambience dissolves the whole backdrop glow to that colour over `dur.dissolve`.

### 4.8 Home (discovery), "Tonight"

The landing screen. AI rails, recaps and states are specified in §5.1; this section defines the frame and choreography.

- **Hierarchy:** (1) the hero spotlight with the typed headline, (2) Continue, (3) Previously on (when due), (4) AI and library rails, (5) friends, (6) networks.
- **Desktop web layout:** hero 2.39:1 (`clamp(560px, 41.84vw, 88svh)`), full-bleed under the transparent top bar. Hero content bottom-left at the gutter, max width `min(40vw, 640px)`: eyebrow ("MANHWA · ONGOING · MANGADEX"), the series title (`type.heroTitle`, letter reveal), the lamp 3 × 32 px rule that draws after the letters, a one-line hook `type.bodyLg` `ink2`, the button row (Primary · play "Continue · Ch 142" or "Read", Secondary "+ My list" or Round icon, Round icon `info`). Above the hero title, top-left under the bar: the **typed headline** (§6.2) in `type.slug`, e.g. "TONIGHT: CHAPTER 143 OF OMNISCIENT READER". Hero rotation dots bottom-right: 5 × 24 px bars, the active one fills with `lamp` over the 8 s dwell. Rails overlap the hero by −96 px into the foot scrim.
- **Tablet:** hero 16:9 (min 420), title `type.heroTitle` tablet size.
- **Phone and mobile web:** hero 4:5 full-bleed to the top edge behind the status bar (max 78 svh); the typed headline sits in the top bar area over `scrim.topChrome`; title, buttons centred bottom; hero auto-advances every 8 s with a 2 px segmented story strip at the top (under the safe area). Rails overlap −40 px.
- **Signature moment, "scrub the trailer":** Home is choreographed against scroll. As the user scrolls, the hero art parallaxes at 0.3, the title block rises −12 % and fades by 55 % progress, and the hero **pins and compresses** into a 64 px "now showing" strip at the top (poster thumbnail 32 × 48 + title `type.cardTitle` + Continue icon button) driven by scroll position on the `spring.crane` curve. Scrolling back up un-pins it frame for frame. Fast flings blur rails horizontally; settling racks them into focus.
- **Rail choreography on entry:** rail headers reveal letter by letter as they cross 60 % visibility, once per session; posters dolly in 24 px with the 42 ms stagger 125 ms after their header.
- **Backdrop swap on dwell (desktop):** hovering or focusing any poster for 450 ms while the hero is ≥ 30 % in view dissolves the hero backdrop and ambient colour to that series (800 ms, sound `swap`). Leaving all rails for 2 s dissolves back to the hero's own series.
- **Transition in:** from the pre-roll, fade up from black 400 ms and Ken Burns begins; from other sections, `move.reelChange`. **Out:** poster → title page `move.matchCut`; Continue → reader `move.curtain` via the title page's curtain logic (the Continue card match-cuts into the letterbox directly).
- **Gestures (phone):** vertical scroll; horizontal swipe on the hero changes spotlight (dissolve, sound `page`); long-press any poster → preview slate sheet; pull to refresh (leader) refetches every rail.
- **States:** loading (hero slate: black 4:5/2.39:1 frame with the typed headline "LOADING TONIGHT'S LINEUP" and rails as slates), empty library and no history (hero becomes a title card "Your first screening." with Primary "Browse sources" and the Networks rail below), offline (hero shows the most recent downloaded series, rails limited to "On this device" and "Continue (downloaded)", banner "Offline · showing what's on this device"), error (hero title card "Tonight's lineup didn't load." + Retry; rails that did load still show).
- **Keys (web):** `←`/`→` on the hero changes spotlight, `Enter` on the hero continues, `r` reads the spotlight series, `+` follows it, rail keys per §3.12, `p` pauses the hero rotation.

### 4.9 Library

- **Hierarchy:** page title, the in-page slate tabs **Shelf · All titles · Collections · History · Bookmarks** (phone; desktop has Collections, History and Bookmarks in the Reel Index and shows only Shelf and All titles here), the Continue hero card, then the followed wall.
- **Desktop web:** title "LIBRARY" `type.display` letter reveal + `type.timecode` "86 SERIES FOLLOWED". Continue section: the 2.39:1 hero continue card (§3.14) + a rail of up to 11 more 16:9 continue cards. Then "ON YOUR SHELF" section header and the poster wall: 2:3 posters with captions, columns 6 (desktop), 7 (wide), 8 (≥ 1920), gap 12, rows 40. "NEW EPISODES" rail between Continue and the wall when any followed series has unread chapters.
- **Phone and mobile web:** title pins into the top bar on scroll; Continue as a 16:9 rail (1.15 visible cards); wall at 3 columns (2 at text scale ≥ 1.5).
- **Novels mode:** the wall becomes **the stacks**, rows of book plates: 48 × 68 plate + title in Newsreader 18/24 + meta `type.caption` + 2-line blurb, hairlines between rows. The book plates cast a thin `amb.glow` edge on hover.
- **Signature moment:** the wall enters with the diagonal grid stagger, and new-episode badges "stamp" onto posters 250 ms after the image racks into focus (scale 1.2 → 1 on `spring.press`, haptic none, sound none).
- **Transitions:** poster → title page `move.matchCut`; tab changes inside Library are cuts with rack focus.
- **Gestures:** long-press poster → preview slate sheet with library actions (Open, Continue, Favourite, Status, Add to collection, Recommend to, Download next 10, Unfollow); pull to refresh.
- **States:** loading (title bar + 12 slate posters), empty ("Your shelf is empty." typed + "Follow a series from a source and it shows up here." + Primary "Browse sources"; novels: "No books yet."), offline (shows followed series cached on the device with a banner; posters of series with nothing downloaded dim to 0.5), error title card.
- **Keys (web):** `/` focuses the filter in All titles, `h j k l` and arrows move in the wall, `Enter` opens, `c` continues the focused series, `f` favourites, `s` toggles select mode.

### 4.10 All titles (browse the followed library)

- **Toolbar (sticky under the top bar on scroll, `#000` with hairline):** search field 44 (`/`), filter slate `ALL · READING · NOT STARTED · COMPLETED · ★ FAVOURITES`, a "Status" menu button (Any, Unread, Reading, Completed, On hold, Plan to read, Dropped), sort menu (Recently updated, Recently added, Title, Manual order), density segmented (desktop, manga only: Posters, Compact, List), Select toggle (`check-square`).
- **Content:** Posters density = §4.9 wall; Compact = 2:3 posters at 60 % size without captions, 10 columns desktop; List = rows (§3.22) with cover 32 × 48, title + status badge, meta, and trailing follow (`bell` / `bell-ringing` Fill) and favourite (`star`) icon buttons.
- **Select mode:** posters and rows become checkboxes; Shift-click ranges (web); the bulk bar rises: count, Select all {n}, Favourite, Unfavourite, Mark read, Mark unread, Add to collection, Unfollow (danger · quiet → confirm dialog "Unfollow 12 series? Progress is kept."). Running: progress bar "8 of 12 · 1 failed" + Stop; result line in the bar with Dismiss.
- **Overflow note** at the end: "Showing the first 200 of 312. Narrow it with search or a filter." `type.caption`.
- **Signature moment:** changing a filter is a **cut**: the wall swaps instantly and every visible poster racks into focus from 6 px in 250 ms; items that stay in the result keep their place (FLIP-free because it is a cut, which is the point).
- **States:** loading (24 slates), empty library, empty search ("Nothing matches “{q}”." + Clear), empty filter ("No series with these filters." + Clear filters), offline, error.
- **Keys:** `/`, arrows / `h j k l`, `Space` toggles selection in select mode, `mod+a` selects all visible, `Esc` leaves select mode, `x` toggles select mode.

### 4.11 Title page (series detail, manga and manhwa)

One design for both the followed-series and source-series routes. The body differs only in which data is present.

- **Hierarchy:** backdrop and title treatment, CTA row, facts, synopsis, slate tabs **Chapters · More like this · Details**, chapter list.
- **Desktop web layout:** full-bleed backdrop 2.39:1 (the cover at `blur.art` for the top 40 %, then the sharp cover cropped `50% 20%` at 60 % opacity under `scrim.heroTitle`), `pageSpill` in `amb.tint` below. Left column at the gutter (max 640): eyebrow ("MANHWA · ONGOING · 2021 · MANGADEX"), title `type.heroTitle` (letter reveal after the match cut lands), lamp rule, author line "by Sing Shong · art by Sleepy-C" `type.body` `ink2`, CTA row (Primary · play "Read" / "Continue · Ch 142" / disabled "All caught up"; Secondary "Read all" for manga with more than one chapter; Round icon `plus`/`check` follow; Round icon `star` favourite; Round icon `paper-plane-tilt` recommend to; Round icon `download-simple` download), status menu (Unread, Reading, Completed, On hold, Plan to read, Dropped) as a text menu button showing the current status, notifications toggle (`bell` / `bell-slash` icon button, followed only). Right: the 2:3 poster 280 px, sticky while the chapter list scrolls. Rating card (§3.25) for 18+ series.
- **Chapters tab:** header "142 CHAPTERS" `type.timecode`, sort text slate `NEWEST · OLDEST` (saved per series), "Select" text button (download picker), download summary "12 of 142 downloaded" `type.caption`. Chapter rows (§3.22) with read state, progress "18 / 42" in `lamp`, date, download ring; the "you are here" row edge in `amb.accent`; list is virtualised (TanStack Virtual on web, `SliverList` on Flutter).
- **More like this tab:** rail of similar series from world recommendations for this seed (§5.1) + "Because you read {title}" when available.
- **Details tab:** synopsis `type.bodyLg` (max 62ch), genres as eyebrow links separated by `·` (each → source catalogue `?genre=`), alternate titles (CJK allowed), status, source, chapter count, official platforms (from world data), "Following since" date, OCR status ("Text extracted for 12 chapters").
- **Phone and mobile web:** backdrop 4:5 with the poster itself as the art (no separate sticky poster); title centred under it; CTA row full width (Read as Primary lg, the rest as a row of 4 round icon buttons with `type.micro` labels under them); tabs pin under the top bar on scroll.
- **Download picker (select mode):** chapter rows get checkboxes (downloaded rows disabled with the `positive` mark), Shift-click ranges on web, the download bar rises with helper chips "Next 10", "All unread" and Primary "Download 12"; running: "Downloading 3 of 12" with the bar and Stop; summary line after.
- **Signature moment, "match cut and rack":** from any poster the poster morphs into the backdrop frame (radius 6 → 0), the page spill dissolves to the series tint, the title reveals letter by letter, then the chapter list dollies up 24 px. Opening the reader from here plays `move.curtain`.
- **Gestures:** swipe between tabs (phone); long-press a chapter → menu (Read, Mark read / unread up to here, Download, Remove download, Bookmark start); pull to refresh; overscroll down on the phone backdrop stretches it (scale up to 1.15 at 120 px).
- **States:** loading (backdrop slate with the title as a title card if known, 8 slate chapter rows), error title card "This series didn't load." + Retry + Back, offline (downloaded chapters listed, others dimmed with `cloud-slash`; CTA works when the next chapter is downloaded), no chapters ("This source hasn't listed any chapters yet."), source down (banner "{Source} isn't answering. Downloaded chapters still open." with Retry).
- **Keys (web):** `r` read/continue, `a` read all, `+` follow, `f` favourite, `d` download picker, `1 2 3` switch tabs, `j`/`k` move in the chapter list, `Enter` opens the chapter, `n` newest/oldest toggle, `Backspace` back.

### 4.12 Book page (novel series)

- **Hierarchy:** front matter (plate, title, byline, facts, blurb, actions), then Contents.
- **Desktop web:** a two-column "title card" on black: left column max 620 at the gutter: eyebrow "NOVEL · ONGOING · 1,204 CHAPTERS", title in `type.editorialXL` (Instrument Serif, letter reveal), byline italic "by {author}", 56 px lamp rule, facts `type.timecode` "≈ 2.3M WORDS · ≈ 160 H", estimate note `type.caption` `ink3` "Length estimated from 12 chapters read", blurb in Newsreader 18/30 `ink2` (max 62ch), genre eyebrow links, actions (Primary · play "Start reading" / "Continue · Ch 88" / disabled "All caught up", Secondary "Add to library" / "In your library", Secondary `headphones` "Audiobook", Round icon download, Round icon recommend). Right: the book plate 240 × 360, `elev.lift` in `amb.glow`, with a slow 24 s Ken Burns inside the plate.
- **Contents:** header "CONTENTS" `type.section`, "Go to chapter" number field (Enter jumps and centres the match; match list of 12 with "and 40 more"), order slate `FIRST → LAST · LAST → FIRST`, "Pick chapters" text button. Rows: ordinal Newsreader tabular 40 px column, title Newsreader 16, meta `type.caption` ("3.4k words · 42 % in · audio saved"), `headphones` 14 when audio exists, download ring. Windowed 400 around the focus with "Show earlier chapters (380)" and "Show more chapters (420)".
- **Audiobook sheet** (from the Audiobook button): segmented `NARRATE · SAVE TO THIS DEVICE`, helper chips "Next 10", "All un-narrated (n)" / "All narrated (n)", "None", checklist of chapters with states ("Already narrated", "Already narrated · saved here", "Download the text first"), estimate "About 90 minutes of rendering." or "Saves while the app is open.", Primary "Narrate 10 chapters" / "Save audio of 10 chapters"; unavailable note "Narration isn't available right now. Chapters that already have audio can still be saved."; job list with progress bars and Cancel ("Stops shortly.").
- **Phone:** single column, plate 120 × 180 floated right of the title, contents below.
- **Signature moment:** the title writes itself (letter reveal in the serif), then the lamp rule draws, then the blurb fades in line by line (28 ms per line).
- **States:** as §4.11 plus "The contents need a connection." offline when nothing is cached.
- **Keys:** `r`, `+`, `g` focuses Go to chapter, `l` listens (opens the audiobook sheet), `j`/`k`, `Enter`.

### 4.13 Manga reader, "Feature presentation" (webtoon strip, paged, read-all)

The reader is where the skin gets out of the way. Chrome is scrim and type, never a bar; the page's own colour lights the room.

**Entry.** From the title page or a Continue card: `move.curtain` (letterbox bars close to black, hold 2f, open onto the first page). From anywhere else (history, bookmarks, notifications, downloads, OCR results, deep links): `move.dip`. If the series is 18+, the rating card shows for 4 s after the curtain opens. If a recap is due, "Previously on" (§5.1.3) plays before the curtain.

**Reading surface**

- **Strip (default for manhwa, manhua, webtoons):** a virtualised vertical column, seamless pages (no gap unless "Page gap" is on: 8 px `pit`). Column width: phone full width; tablet and desktop 800 px default, choices 600 / 800 / 1000 / Fit window (`w` cycles), centred. The gutters beside the column are `pit` lit by the **page tint** (§5.4.4): a vertical glow of `amb.glow` at 18 % that follows the page crossing the reading line.
- **Paged (Single, Double):** fit-to-stage pages on `canvas`, spread gap 8 px, RTL mirrors display order, fit Width / Height / Original, zoom 50–300 %. Page turns: **Dolly** (default: the page follows the finger or wheel and releases on `spring.dolly` with the fling velocity; tap-turns animate the same spring from rest), **Cut** (125 ms crossfade with 12 px parallax in the turn direction), **Instant**.
- **Read-all:** the whole series as one strip. The scrubber is segmented per chapter and the chrome shows "CH 3 OF 142".
- **Chapter seam (strip):** a 160 px black band between chapters: "END OF CHAPTER 142" `type.eyebrow` `ink3` letter-revealed as it enters, the reactions row (§5.3.3), a hairline, then "CHAPTER 143" in `type.section` (letter reveal) + the chapter title `type.caption`. Crossing the seam commits progress and plays haptic `chapter.next`. No card, no pause.
- **Head of feed:** at the top when a previous chapter exists: a 72 px band "↑ CHAPTER 141 · KEEP SCROLLING UP" in `type.eyebrow`; over-scrolling up 140 px loads it (the band's hairline fills with `lamp` as the overscroll progresses, like a pull to refresh). Loading: "LOADING CHAPTER 141" with a 24 px leader.
- **End of feed, "Credits and Up Next":** after the last page of the newest loaded chapter when there is no seamless next (last published chapter, or the next chapter failed): 96 px of black, "END OF CHAPTER 142" in `type.section` with the letter reveal, the reactions row, then the **Up Next card**: 16:9, the next chapter's first panel at `blur.recap` behind a sharp inset thumbnail, title "CHAPTER 143" `type.display` sm, "42 pages · ~6 min" `type.timecode`, Primary · play "Play now" and text "Back to series". When auto-scroll is on, a 5 s lamp countdown ring runs on the Play now button and auto-advances; a scroll up or Esc cancels. When it is the last published chapter: the credits read "THAT'S EVERYTHING SO FAR." in `type.editorial`, typed, with "You'll get a notification when chapter 143 lands." and buttons "Back to series" / "Recommend to a friend".
- **Micro progress:** a 2 px `lamp` line at the very bottom edge while the chrome is hidden (hidden in cinema mode).

**Chrome ("scrim chrome")**

- **Top:** `scrim.topChrome` tinted 24 % with the page tint. Back (`caret-left` 28), series title in `type.cardTitle` Mona Sans 700 wdth 85 (tap → title page), chapter `type.timecode` `lamp` "CH 142", and right-side icon buttons: bookmark, download state (ring + label "Download" / "18 / 42" / "Saved"), X-Ray (desktop, manga with OCR text), settings `sliders-horizontal`.
- **Bottom:** `scrim.bottomChrome` with the page-tint glow under the scrubber. Row 1: the timeline scrubber (§3.9) full-bleed. Row 2: previous chapter, "PAGE 18 / 64 · 12 MIN LEFT" `type.timecode` (tap → jump-to-page field), auto-scroll chip ("▶ 1.4×" in `type.timecode`, `ember` rolling dot when running), panel view `panel-focus`, soundscape `waveform`, fullscreen (web), next chapter.
- **Show / hide:** in on `spring.steadicam` (fade + 8 px dolly from its edge), out `dur.beat` `cineIn`. Hides when the user scrolls down more than 24 px, after 3 s idle in cinema mode; returns on a centre tap, upward scroll of 16 px, pointer entering the top 80 px or bottom 120 px band, or any key. Chrome visibility is silent (no haptic).
- **Cinema mode** (`c`, settings): everything hides after 3 s idle including the micro progress; Esc leaves cinema before leaving the reader.
- **Locked mode** (phone, from settings): gestures except scroll are ignored; five quick centre taps unlock (toast "Reader unlocked", haptic `unlock.reader`).

**Desktop wide layout (≥ 1280):** two optional side panels. Left **Episodes** panel (`e` toggles): 320 px chapter list with the current chapter highlighted and download rings. Right panel (settings, X-Ray, voices): §3.15 behaviour; the column dollies to stay centred.

**Settings (phone: sheet at `content` detent; desktop: right side panel)**, grouped under eyebrow headers:

| Group | Control | Options | Saved |
|---|---|---|---|
| LAYOUT | Mode segmented | Strip · Single · Double (hidden in Read-all) | per series |
| | Direction segmented | Left to right · Right to left · Vertical | per series |
| | Fit segmented | Width · Height · Original (Height and Original disabled in Strip, with the reason in a tooltip) | per series |
| | Zoom stepper | 50–300 %, step 10, reset | per series |
| | Column width (tablet, desktop, Strip) | 600 · 800 · 1000 · Fit | per profile |
| | Page gap toggle (Strip) | off / on | per profile |
| MOTION | Page turn (paged) | Dolly · Cut · Instant | per profile |
| | Cinema mode toggle | off / on | per profile |
| | Auto-scroll toggle + speed slider | steps 1–10 (20–220 px/s, §5.4.1), shown as a multiplier where step 5 = 1.0× = 100 px/s | per series |
| LIGHT | Brightness slider | 100–15 % (dim layer 0–0.85) | per profile |
| | Warmth slider | 0–100 % (warm layer 0–0.36) | per profile |
| | Page tint toggle | "Tint the reader with the page's colour" on / off | per profile |
| | Background | Black · Pit · Tinted | per profile |
| | Colour | Normal · Sepia · Grayscale | per profile |
| CONTROLS | Tap zones | Left / Centre / Right each: Previous · Next · Menu · Nothing; Reset (mirrors automatically for RTL until customised) | per profile |
| | Volume keys turn pages (Android) | off / on | per device |
| | Keep screen on | on / off (default on) | per device |
| | Refresh rate (Android) | Auto · 60 · 90 · 120 | per device |
| | Lock reader (phone) | action button | session |
| EXTRAS | Panel view, Soundscape | open their controls (§5.4) | — |
| | Save bookmark, Fullscreen, Shortcuts | actions | — |

**Gestures**

| Gesture | Action |
|---|---|
| Vertical scroll / fling | Read (native physics; auto-scroll pauses on touch) |
| Tap left 28 % / centre / right 28 % | Per tap-zone settings (paged default: previous / menu / next; strip default: menu / menu / menu) |
| Double tap | Zoom 1 × ↔ 2 × around the tap on `spring.steadicam`, haptic `zoom.snap` |
| Pinch | Zoom 1–3 ×, release settles on `spring.steadicam` with no bounce |
| Horizontal swipe (paged) | Dolly page turn following the finger |
| Left-edge vertical swipe (phone) | Brightness HUD: a 6 × 140 px capsule with `sun` glyph and "70 %" `type.timecode`, fades 700 ms after release |
| Right-edge vertical swipe (phone, auto-scroll running) | Speed HUD "1.4×", one speed step per 48 px of travel with haptic `autoscroll.step` |
| Long-press a page | Page menu: Bookmark here, Save page image, Search dialogue on this page (manga with OCR text), Retry page |
| Over-scroll up 140 px at the head | Load previous chapter |
| iOS left-edge horizontal swipe | Leave the reader (`move.pull`), strip mode only |
| Android predictive back | Scales the page to 0.94 as the gesture progresses, commit leaves |
| Five centre taps (locked) | Unlock |

**States**

- Loading chapter: black stage, "CH 142" `type.display` sm title card centred with a 24 px leader after 400 ms; pages appear as `raised` boxes at their manifest aspect ratio (800 × 1200 when unknown) and rack into focus as they decode.
- Broken page: inside the page box, `image-broken` 28 `ink3`, "This page didn't load." `type.body`, Outline "Retry page".
- No pages: title card "This chapter has no pages." + "Back to series".
- Error: title card "This chapter didn't load." + Primary "Try again" + text "Back to series".
- Offline, chapter downloaded: reads normally; a `cloud-slash` 16 sits beside the chapter timecode.
- Offline, not downloaded: title card "This chapter isn't on this device." + "Open downloads" / "Back to series".
- Stale bookmark: toast "That page moved. Opened at the nearest spot."
- Bookmark saved: toast "Saved this spot · page 18, 42 %" with haptic `bookmark`, sound `stamp`.

**Keys (web).** `→`/`d` turn right, `←`/`a` turn left, `j` next page, `k` previous page, `space` / `shift+space` screen down / up, `home` / `end`, `f` fullscreen, `c` cinema, `p` auto-scroll play/pause, `[` / `]` auto-scroll slower / faster, `v` panel view, `m` soundscape, `x` X-Ray panel, `e` episodes panel, `w` column width, `h` / `l` previous / next chapter, `s` series page, `b` bookmark, `=` / `+` / `-` / `0` zoom, `t` toggle page tint, `,` reader settings, `esc` closes the top overlay, then leaves fullscreen, then leaves cinema, then goes to the series page. Ctrl/⌘ + wheel zooms.

**Platforms.** iOS and Android: immersive (status and navigation bars hidden, swipe to peek), wakelock on, 120 Hz. Landscape phone: the column fits the height and chrome appears only on a centre tap. Web: Fullscreen API; wheel zoom only with Ctrl/⌘.

### 4.14 Novel reader, "The page"

- **Stocks (dark only; the page background is a separate axis from the skin):**

| Stock | Background | Text | Contrast | Muted |
|---|---|---|---|---|
| Void | `#000000` | `#D9D6D0` | 14.5:1 | `#8A877F` |
| Ink (default) | `#0B0B0C` | `#E6E3DD` | 15.4:1 | `#8F8C86` |
| Night paper | `#15110C` | `#E8D8BE` | 13.4:1 | `#9C8E78` |
| Dusk | `#0D1117` | `#D3DAE3` | 13.4:1 | `#8590A0` |
| Moss | `#0E130F` | `#D5DECF` | 13.6:1 | `#879384` |
| Rosewood | `#160E10` | `#EBD5D8` | 13.6:1 | `#A08A8E` |
| Tinted | the series `amb.tint` | `#D9D6D0` | ≥ 12:1 (tint L capped at 0.07) | `#8A877F` |

- **Typography:** face Newsreader (default) or Geist; size 15–26 px (default 19); line height 1.40–2.10 (1.75); measure 48–88 ch (68); alignment Left · Justified (hyphenation on with justified); paragraph indent 1.4 em (flush after headings and breaks). Saved per book; stock saved per profile.
- **Flow:** **Scroll** (default: continuous column) or **Pages** (CSS multi-column pagination on web, `PageView` of laid-out columns on Flutter). Page turns in Pages: **Dolly** (default, follows the finger, `spring.dolly`) or **Cut** (140 ms crossfade + 12 px parallax). No page curl in this skin.
- **Chapter header:** eyebrow "CHAPTER 12" (0.69 em, +0.22 em), title Newsreader 1.55 em 500, 56 px lamp rule that draws when the header enters, "3.4K WORDS · 14 MIN" `type.timecode` in the muted colour. First paragraph ≥ 80 characters gets a 3-line drop cap. Scene breaks: three 4 px muted dots, 1.6 em vertical padding.
- **Dialogue tints** (when attribution exists): each speaker's runs get a background band at 12 % of the speaker's voice hue and a 1 px underline at 50 %; the narrator is untinted.
- **Running head (top chrome):** painted in the stock with a hairline: back, running title "OMNISCIENT READER · CHAPTER 12" `type.eyebrow` (truncated), percent `type.timecode`, and icon buttons Contents, Bookmark, Voices (when a cast or narrator exists), Listen (`headphones`, when audio exists), Type `text-aa`. A 1 px progress hairline under it fills with the muted colour.
- **Bottom chrome:** previous chapter, "42 % · 9 MIN LEFT IN CHAPTER" `type.timecode`, next chapter. Offline copies show `cloud-slash` 16 by the percent.
- **Show / hide:** a centre tap (phone) or a pointer in the top 64 px (desktop) toggles; fade `dur.beat`; the chrome never auto-hides while a panel is open.
- **End matter ("credits"):** 96 px rule, "END OF CHAPTER 12" eyebrow with the letter reveal, the chapter's cast as a credits list ("Kim Dokja ........ Arden" in `type.caption`, dotted leaders) when attributed, the reactions row, then the Next card ("NEXT" eyebrow + "Chapter 13" Newsreader 1.3 em + `caret-right`). Seamless next: over-scroll 140 px, `l`, or the card; the next chapter swaps in at the top (URL replaced) with a `move.dip` limited to the text column. Auto-next (setting, default on): after 900 ms at the very end when narration is not playing. Last published chapter: "You've reached the latest chapter." typed + "Back to the book".
- **Type panel (phone sheet, desktop right side panel):** a live preview paragraph at the top rendered in the current settings, then Face tiles (each in its own face), steppers Size / Line spacing / Line width, Alignment segmented, Flow segmented (Scroll · Pages), Page turn segmented (Dolly · Cut), Stock swatches (40 px tiles painted in their own background with "Aa" in their text colour; selected ring 2 px text colour).
- **Contents sheet (phone) / Episodes panel (desktop):** "CONTENTS" + Go to chapter field; rows ordinal + title, current row filled with 7 % text colour; pre-scrolled to the current chapter; match list for typed numbers ("No chapter 1300 in this book.").
- **Signature moment, "the page opens":** entering from the book page, the book plate match-cuts to the centre of the screen, grows to fill it while its colour dissolves into the chosen stock, and the chapter header writes itself (letter reveal) as the plate vanishes. 750 ms, skippable.
- **Gestures:** tap centre toggles chrome; tap left / right thirds turn pages in Pages flow; swipe in Pages flow; long-press a paragraph → menu (Bookmark here, Copy, Play from here when audio exists, Search this phrase); pinch changes text size in 1 px steps (haptic `segment` per step); iOS edge swipe and Android predictive back leave to the book.
- **States:** loading (the stock colour with 12 muted text bars at 92/78/64 % widths), error ("This chapter didn't load." + Retry + Back to the book), empty text ("This chapter came through empty."), offline not downloaded ("This chapter needs a connection."), stale bookmark toast ("The text changed. Opened at the nearest paragraph."), bookmark toast in the stock colours.
- **Keys (web):** `h` / `l` chapters, `j` / `k` scroll a line (Scroll) or page (Pages), `space` / `shift+space` screen, `=` `+` `-` text size, `t` type panel, `o` contents, `b` bookmark, `v` voices, `a` listen (opens listen mode, starts playback), `esc` closes panels then returns to the book.

### 4.15 Listen mode, "Now showing" (TTS with 31 voices)

**Mini player (inside the novel reader and, while narration plays, above the transport bar app-wide):**

- 64 px `stage` band, `elev.2`, radius `frame` (phone inset 8 px from the edges), cover 32 × 48, chapter title `type.bodyStrong`, "5:12 · −18:40" `type.timecode` `ink3`, icon buttons back 15 s, play / pause (Fill), forward 15 s; a 2 px `lamp` progress line along the bottom edge (buffered segment at 35 % ink).
- Rides with the chrome and lingers 5 s after the chrome hides unless pinned (pin icon in the full player). Swipe horizontally on it to go to the previous / next chapter; tap to open the full player; swipe down to dismiss (stops playback after a 3 s undo toast).

**Full player (phone full-screen sheet; desktop 480 px right panel over the reader, or full-screen with `f`):**

- Backdrop: the cover full-bleed at `blur.art`, Ken Burns, the series glow rising from the bottom, `scrim.vignette`.
- Top: collapse `caret-down`, "NOW SHOWING" eyebrow, "Chapter 12 · Omniscient Reader" `type.cardTitle`, overflow menu (Save audio to this device, Narrate more chapters, Report wrong speaker).
- Centre, **"subtitles":** the chapter as a list of sentences in Geist 20/28 (phone) 24/32 (desktop). The spoken sentence is `ink` at 100 %, the others 35 %; dialogue sentences carry a `type.micro` speaker label in the speaker's hue above them ("KIM DOKJA"). The active sentence holds at 38 % of the panel height and the list glides on `spring.steadicam`. A user scroll decouples it and shows a "Back to the voice" chip; it re-couples after 4 s idle. Word-level: the current word brightens to full ink with a 2 px underline in the speaker hue, stepping without animation.
- Transport: back 15 s, previous sentence, **play** (72 px `ink` disc with a black `play`/`pause` Fill 32), next sentence, forward 15 s; previous / next chapter as text buttons under it; a scrubber (§3.9) with chapter-relative time "5:12 / 23:52".
- Tiles row (4 × 72 px `stage` tiles, icon + value): **Speed** ("1.25×"), **Voices** ("Narrator · Arden"), **Sleep** ("Off" or the live countdown), **Soundscape** ("Rain · 30 %").
- **Speed sheet:** a tick ruler 0.5–3.0 × step 0.05 with labelled marks at 0.5 / 1 / 1.5 / 2 / 2.5 / 3; chips 0.8 · 1 · 1.25 · 1.5 · 2; touch-and-hold anywhere on the ruler resets to 1 ×; the words-per-minute equivalent under the value ("≈ 210 WPM"); pitch preserved (`preservesPitch` on web, just_audio `setPitch(1)` on Flutter).
- **Sleep sheet:** Off, 5, 10, 15, 30, 45, 60 min, End of chapter, End of next chapter, Custom (a minute stepper). The volume fades over the last 8 s. Phone: shake to add 5 min (toast "Sleep timer +5 min").
- **Casting board (Voices sheet or panel):** section "CAST" as credits rows: Narrator pinned on top, then each character: name, a 12 px hue swatch, dotted leader, voice name, share of lines ("18 %"), `lock-simple` 14 when set by hand. Tapping a row opens the **voice board**: a rail (phone) or 4-column grid (desktop) of 3:4 headshot cards for the 31 voices: a monogram on a two-stop gradient in the voice's own hue, name `type.bodyStrong`, gender + timbre tag `type.caption` ("female · bright"), a pitch bar "deeper ↔ brighter" from `pitch_hz`, expressiveness as 5 dots, and a play-intro round icon button that plays the voice introducing itself (a 5-bar live level meter replaces the glyph while it plays). Filters `ALL · FEMALE · MALE · IN USE`, a search field. Selected voice: 2 px `ink` ring + `check`. Owner-only actions (assign voice, set narrator, "Same character as…" alias merge) are shown to the server owner; others see the board read-only with the note "Only the server owner can recast voices." After a change the row reads "Re-voicing from the next sentence…".
- **Chapter boundary:** a post-play card: "UP NEXT" eyebrow, "Chapter 13" typed at 50 ms, a 5 s `lamp` countdown ring on "Play now", and "Cancel". The chrome stays visible during the countdown.
- **Signature moment, "house lights down":** opening the full player dims the reading page to black over `dur.dissolve` while the cover rises behind the subtitles; closing brings the page back exactly at the spoken paragraph.
- **States:** preparing (`503 audio_preparing`): play shows the leader and "Preparing audio…", retried every 3 s up to 60 s, then "Audio isn't ready yet. Try again in a minute."; no narration for this chapter: the Listen button is hidden, and the book page offers Narrate (owner, `can_render`); narration unavailable server-wide: "Narration isn't available right now." note; failed: play shows `warning-circle` and "Playback failed" with Retry; highlight unsafe: no highlight, a one-line note "Highlight paused: the text changed."; offline with saved audio: plays; offline without: "Audio needs a connection."
- **System integration:** iOS and Android lock screen, notification and headset controls (play/pause, ±15 s, next chapter) with the cover and titles, through `audio_service` added in the listen-mode commit at the newest release that resolves against Flutter 3.44.6 (the lockfile pins it); the audio session category is speech (`audio_session` 0.1.25, installed). Web: Media Session API with the same actions.
- **Keys (web):** `space` or `k` play/pause, `←` / `→` ±15 s, `shift+←` / `shift+→` previous / next sentence, `[` / `]` speed −/+ 0.05, `\` reset speed, `v` voices, `z` sleep timer, `esc` collapses the player.

### 4.16 Search

- **Hierarchy:** the field, then (idle) recent + trending + networks, or (query) results grouped by source.
- **Desktop web:** title "SEARCH" `type.display` letter reveal; field 56 px, 720 px wide at the gutter; under it the idle panel in three rows: "RECENT" token chips (max 8, removable), "TRENDING" filter-slate words (fantasy · romance · action · regression · murim · horror · sci-fi · slice of life), and the **Networks** rail (source hub tiles, §3.14) as the way into Sources. With a query: a status line in `type.timecode` ("SEARCHING 14 SOURCES…" → "212 RESULTS · 14 SOURCES · 1 DIDN'T ANSWER"), group filter slate `ALL · WITH RESULTS · PINNED`, then one rail per source: header = favicon 28 + source name `type.section` (letter reveal) + count badge; posters with captions; "Your library" group first with a `books` tile. Sources that answer late slide their rail in at their rank on `spring.dolly` (rails below dolly down to make room). Sources with no matches collapse into a single line "8 sources had no matches" with a disclosure.
- **Phone and mobile web:** the field sits in the top bar; focusing it dollies it to the top and hides the transport bar. Results rails at 3.3 posters.
- **Signature moment, "wire room":** results arrive source by source like wires on a news desk: each new rail's header types its source name at 50 ms per character while its posters rack into focus.
- **Per-source states:** answering (4 slate posters + leader in the header), failed ("{Source} didn't answer." + Retry text button, `cloud-slash` in `danger`), no matches (collapsed), retrying (slates).
- **Page states:** idle; loading (3 slate rails); no results anywhere ("Nothing matches “{q}”." typed + "Try another spelling or search your sources one by one." + a button per pinned source); offline ("Search needs a connection. Your library is still here." + "Search my downloads" which filters downloaded titles locally); error title card.
- **Gestures:** pull to refresh re-runs the query; long-press a result → preview slate sheet.
- **Keys:** `/` focus, `Enter` search now, `↓` from the field into the first rail, rail keys, `Esc` clears then blurs.

### 4.17 Sources ("Networks")

- **Desktop web:** title "SOURCES" + content-mode slate; a filter field "Filter sources" + slate `ALL · PINNED 4 · 18+` (18+ appears only for mature profiles). **Pinned** section as a row of 16:9 network tiles (§3.14), then **All sources** as a grid of network tiles (4 columns desktop, 5 wide, 2 phone) in pinned-first, then alphabetical order. Each tile: name, favicon, health dot (positive / warning "slow" / danger "down"), `type.timecode` "1,204 SERIES · MANHWA", pin icon button (top-right on hover; always visible on touch), 18+ badge.
- **Unavailable pinned source:** the disabled tile "Unavailable on this profile", not tappable.
- **Signature moment:** hovering a tile starts its Ken Burns and ambient backdrop, and the whole page's `pageSpill` dissolves toward that source's tint (the room takes the network's colour).
- **Pin / unpin:** the pin icon morphs Bold → Fill `lamp`; the tile dollies into (or out of) the Pinned row on `spring.dolly` using a shared layout animation; toast "{Source} pinned".
- **Drag to reorder pinned** (desktop drag, phone long-press) with the lift spec in §3.22.
- **States:** loading (8 slate tiles), none installed ("No sources installed." / "No novel sources installed."), no pinned ("Pin a source to keep it on top."), no filter match, error, offline ("Sources need a connection.").
- **Keys:** `/` filter, arrows / `h j k l` in the grid, `Enter` opens, `p` pins the focused tile.

### 4.18 Source catalogue

- **Desktop web:** a network header: 2.39:1 banner (latest cover `blur.art` + source tint), source name `type.display` letter reveal, favicon 40, health line `type.timecode`, search field "Search {Source}". Browse modes as slate tabs (`POPULAR · LATEST · …` exactly as the connector returns them) + a genre menu button when genres exist (`?genre=` shows a removable genre token chip). Then a poster wall with no captions at rest (title on focus), 7 columns desktop, 8 wide, 3 phone, infinite scroll (loads 600 px before the end; the next page's posters stagger in).
- **Novel sources:** the stacks (book plate rows) instead of posters.
- **"Top" control:** after 400 px of scroll a Round icon `arrow-up` appears bottom-right (above the transport bar on phone); tap scrolls to top on `spring.crane`.
- **Opening state:** "OPENING {SOURCE}" `type.section` letter reveal with the favicon 72 px and the leader; transitions to content with a `move.dip`.
- **States:** empty ("{Source} returned nothing here."), empty search ("No results for “{q}” on {Source}."), error ("{Source} didn't answer." + Retry), offline, end of catalogue ("That's the whole catalogue." `type.caption`).
- **Keys:** `/`, grid keys, `1`–`9` browse modes, `g` genre menu.

### 4.19 Updates

- **Hierarchy:** page title with the unread count, actions, the notification feed, then followed series status.
- **Desktop web:** title "UPDATES" + `type.timecode` "14 NEW · 86 FOLLOWED"; action row: Primary "Check now" (leader while running, then "Checked 12:04"), text "Mark all read" (mode-aware: "Mark all manga read"); a settings summary row (`gear-six` + "Checking every 30 min · notifications on · last check 12:04" + `caret-right` → Settings → Updates). **Feed grouped by day** ("TODAY", "YESTERDAY", "SEP 26"): each notification is a row with the 2:3 cover 40 × 60, series title `type.bodyStrong`, chapter `type.body`, source + time `type.timecode` `ink3`, NEW badge when unread, trailing Primary sm "Read" and a text "Mark read". Several new chapters of one series stack into one row "3 new chapters · 141–143" that expands on tap.
- **Followed series** section (collapsed by default on desktop, a tab on phone: `NEW · FOLLOWED`): rows with source badge, "142 chapters" / "Not checked yet", and a danger · quiet "Unfollow" that opens a confirm.
- **Admin "Recent checks"** (admin only): rows "{trigger} · {status} · {n} series · {n} new" + time.
- **Signature moment:** after "Check now", new notifications drop in at the top one by one on `spring.dolly` with a 83 ms stagger and the NEW badges stamp on; the bell badge count rolls up (tabular digits scroll vertically, `spring.whip`).
- **Swipe (phone):** swipe left on a notification → "Mark read" slab (`lamp`), full swipe commits.
- **States:** loading (6 slate rows), empty ("No new chapters yet." typed + "Follow a series and it lands here the moment a chapter drops."), offline, error.
- **Keys:** `u` check now, `shift+r` mark all read, `j`/`k`, `Enter` reads, `m` marks the focused one read.

### 4.20 Downloads

- **Hierarchy:** storage meter, the active queue, then saved titles biggest first; a second tab for storage policy.
- **Tabs:** `ON THIS DEVICE · STORAGE`.
- **On this device (desktop web and phone share one layout, columns differ):**
  - Header: eyebrow "ON THIS DEVICE", title "DOWNLOADS", the **reel meter** (§3.20) with "3.4 GB of 10 GB · 128 chapters" `type.timecode`; web adds "Storage protected" / Secondary "Protect storage" (`navigator.storage.persist()`).
  - **Now saving** panel (`stage`, hidden when idle): current chapter "Omniscient Reader · Ch 142 · page 7 of 40" with the progress bar, queue summary "6 in the queue · 1 failed" (`danger` count), Pause / Resume icon button, Cancel all (confirm "Cancel all downloads? Finished chapters stay."), "Show queue" disclosure listing queued rows with retry and remove. Pause reasons as a banner: "Paused by you. Resuming carries on from the page it stopped at.", "Paused: the storage cap is reached." + "Storage settings", "Paused: low free space on this device.", "Waiting for a connection.", "Paused while the app is in the background." (app).
  - **OCR run** banner (app, manga): "Extracting text · page 3 of 40" with a thin progress bar and Pause.
  - Saved titles: one card per series (cover 48 × 72, title, "40 chapters · 3 with audio · 1.2 GB", pin icon button (exempt from auto-delete), overflow menu: Save to Files… (app), Remove all downloads (confirm)). Expanding a card lists chapter rows with the download ring state, size, `headphones` for audio rows, OCR icon button (app: extract text / redo), Save to Files (app), Remove (no confirm; toast with Undo).
  - Info card (app): "Downloads live inside ManhwaManiacs and open with no connection. On iPhone you can also find them in Files → On My iPhone → ManhwaManiacs." / Android: "Downloads live in the app's private storage."
- **Storage tab:** Storage cap chips (2 GB · 5 GB · 10 GB · 20 GB · Unlimited), Chapters at once (1 · 2 · 3), Delete finished chapters after (Off · 24 hours · 48 hours · 7 days on the app; 2 days · 7 days · 30 days · Never on web), "By series" breakdown rows, Outline "Free up space", web: Danger · quiet "Reset offline storage" (confirm) and "Remove all downloads" (confirm "Delete everything saved?").
- **Signature moment, "reel lock":** when a chapter finishes, its ring closes, flashes `positive` for 2f, and the row's size rolls up in the header meter as a new frame lights in the reel meter; haptic `reelLock`, sound `reel`.
- **Save to Files (app):** sheet with "Page images" (a folder per chapter) and "One file per chapter" options; progress dialog "Saving to Files…" (non-dismissible); result dialog with the path in `lamp` monospace ("Files → On My iPhone → ManhwaManiacs → Exports → Omniscient Reader").
- **States:** no profile ("Downloads belong to a profile." + Choose a profile), unsupported (web without service worker: "Downloads don't work in this browser."), checking ("Checking what's stored…" + leader), empty ("Nothing saved yet." typed + "Download chapters from any series page and read them anywhere."), offline pill "You're offline · only saved chapters open".
- **Keys:** `p` pause/resume, `/` filter saved titles, `j`/`k`, `Enter` opens, `Delete` removes the focused chapter (toast with Undo).

### 4.21 Collections and collection detail

- **Collections (desktop web):** title "COLLECTIONS" + count; Primary "New collection"; filter field + sort menu (Name A–Z, Most series, Recently created); **Shared with me** section (§5.3.4) above **Yours**; collection banners (§3.14 contact-sheet collage) in 2 columns desktop, 3 wide, 1 phone. Smart collections ("Reading · 3+ new", "Unfinished novels", "Favourite manhwa") show a `sparkle` 14 badge and their rule as `type.caption`.
- **New / edit collection dialog:** Name, Description (optional), **Type** segmented `MANUAL · SMART` (smart shows rule chips: status is …, has new chapters ≥ n, favourite, format is …, mode is …), **Share** toggle with a friend picker (§5.3.4). Cancel / "Create" / "Save".
- **Collection detail:** header 21:9 backdrop made of the first member's cover at `blur.art` with the contact-sheet collage on the right, name `type.display` letter reveal, description `type.bodyLg`, count, owner avatars when shared, actions: Round icon `pencil-simple` edit, Secondary "Add series" (dialog with a search field and a list of followed series not in it; tap adds with a stamp), text "Remove series" (select mode on the grid, then "Remove 3"; the series stay in the library), Danger · quiet "Delete collection" (confirm "Delete {name}? The series stay in your library."). Member wall = library posters. Drag to reorder in manual collections.
- **Signature moment:** opening a collection, the collage fans apart and its four posters dolly into the first four slots of the wall below (shared elements), then the rest of the wall staggers in.
- **States:** loading (4 slate banners / slate header + 6 posters), empty list ("No collections yet." + "Create one"), empty collection ("This collection is empty." + Add series), mode mismatch ("Everything here is a novel. Switch to Novels to see it."), no filter match, offline, error.
- **Keys:** `n` new collection, `/` filter, grid keys, `e` edit, `a` add series.

### 4.22 History

- **Desktop web:** title "HISTORY"; a **timeline**: a vertical 1 px `n7` rail at the left gutter with day markers ("TODAY", "YESTERDAY", "SEP 24") as `type.timecode` on the rail; entries are 16:9 continue cards (§3.14) in rows of 4 (desktop), 5 (wide), 1.15-visible rails per day (phone). Each card: timecode "CH 142 · P. 18" or "CH 12 · 42 %"; the "Continue" play disc; completed chapters show "Next" (resolves the next chapter, `aria-busy` leader, falls back to the title page).
- **Signature moment:** scrolling the timeline scrubs a **playhead**: a `lamp` 2 × 24 px marker travels down the rail with the scroll position, and the day marker it passes brightens (`ink3 → ink`).
- **Pagination:** loads 50 at a time with "Load older" at the end (and on scroll near the end).
- **Swipe (phone):** swipe left → "Remove from history" slab (danger), undo toast.
- **States:** loading (3 day groups of slates), empty ("Nothing read yet." typed + "Start a chapter and it shows up here."), offline, error.
- **Keys:** `j`/`k`, `Enter` continues, `n` opens next, `Delete` removes.

### 4.23 Bookmarks

- **Desktop web:** title "BOOKMARKS"; rows grouped by series (cover 48 × 72 + series title as the group header), each bookmark a row: "CH 142 · PAGE 18 · 42 %" `type.timecode` (novels: "CH 12 · PARAGRAPH 118"), the novel snippet in Newsreader italic 2 lines, a stale note "The text changed. Opens at the nearest spot." in `warning`, a note line if any, trailing text "Remove".
- **Phone:** same rows; swipe left to remove with Undo (6 s) instead of a confirm.
- **Signature moment:** opening a bookmark match-cuts the thumbnail into the reader and the reader lands on the exact spot with a 2 px `lamp` frame that pulses once around the bookmarked page or paragraph (`dur.scene`).
- **States:** loading (5 slate rows), empty ("No bookmarks yet." typed + "Press B while reading, or use the bookmark button."), offline (bookmarks are synced locally; shows cached ones with a banner), error.
- **Keys:** `j`/`k`, `Enter` opens, `Delete` removes (Undo toast), `/` filter.

### 4.24 For you (AI recommendations)

Fully specified in §5.1.4.

### 4.25 Stats, streaks and Wrapped

Fully specified in §5.2.

### 4.26 Dialogue search (OCR) and the reader X-Ray panel

- **Dialogue search page:** title "DIALOGUE SEARCH" + intro "Search the words inside chapters whose text has been extracted." Field 56 px placeholder "Search a line you remember, like “I will protect you”". Results are **subtitle cards**: a black band 16:9 with the matched line centred in `type.bodyLg` `ink` with a `text-shadow: 0 0 4px #000` and the match highlighted `selection`, and under it "OMNISCIENT READER · CH 88 · PAGE 14" `type.timecode`, "12 words · ML Kit" `ink3`. Tapping opens the reader **at the matching page** (not the chapter start) with the page framed by a 2 px `lamp` pulse.
- **X-Ray panel (desktop reader, `x`):** right side panel "X-RAY" with a search field scoped to this series and a "On this page" list of extracted lines for the page at the reading line, as subtitle lines; selecting a hit scrolls the strip to its page on `spring.crane` and pulses the frame.
- **Phone reader:** long-press a page → "Search dialogue on this page" opens a sheet with that page's lines.
- **Signature moment:** results type in line by line at 50 ms per character for the first three cards, like subtitles being cued.
- **States:** idle ("Search the dialogue you remember." + "Only chapters with extracted text, in series you follow, are searched."), loading (3 slate cards), no matches ("No line matches “{q}”."), overflow note ("Showing 20 of 212. Add a word to narrow it."), offline, error, novels mode block ("Dialogue search is for manga." + "Switch to Manga" + "Search novels instead").
- **Keys:** `/`, `j`/`k`, `Enter`.

### 4.27 More (phone app and mobile web)

- Title "MORE" pins on scroll; content-mode slate under it.
- Groups (eyebrow headers) with 56 px rows (§3.22), icon 24 Bold + label + one-line description + trailing count or `caret-right`:
  - **WATCH:** For you, Activity (dot for unseen), Updates (count badge), Stats (the streak shows as a `flame` Fill `ember` 16 + "12 days").
  - **FIND:** Sources, Dialogue search (manga mode, OCR available).
  - **KEEP:** Collections, History, Bookmarks, Storage.
  - **YOU:** Switch profile, Settings, Backup & restore (admin), System status (admin).
  - **APP:** What's new, About (version "3.5.0 (412)").
- **Update available banner** (Android APK channel): a `stage` banner with an `ember` left edge, "Update available · 3.5.1", "Installed 3.5.0 (412)", Primary "Download update"; after launching the download, a dialog "Install it" with three numbered steps (Open the download, Allow this source once, Install).
- **App info tile** at the bottom: the MM column mark 40, "ManhwaManiacs", version `type.timecode`.
- **Signature moment:** rows enter with the 28 ms list stagger once per session; the streak row's flame breathes.
- **States:** the page is static; the unread and version fetches show leaders inline.

### 4.28 Settings

#### 4.28.1 Structure

- **Desktop web:** a left settings index (240 px, inside the content area, sticky) and a right content column (max 720). URL `/settings/:section`. Sections: **Skin**, **Reader**, **Novels & listening**, **Playback** (haptics, sounds, soundscape defaults), **Content (18+)**, **Social**, **Updates** (admin: instance-wide), **Downloads & storage**, **Account & security**, **Keyboard**, **Server** (app only), **Backup & restore** (admin), **Members** (admin), **Admin** (status link), **About**, **Diagnostics** (app debug).
- **Phone:** a list of those sections as rows; each opens a pushed page. A search icon in the top bar opens "Search settings" (every setting indexed by label and keywords, results jump and pulse the setting row with a `lamp` frame).
- **Section header:** title `type.display` sm letter reveal + intro `type.body` `ink2`.
- **No-profile block** (Reader, Content, Social, Skin when no profile is active): banner "Pick a profile first. These settings belong to a profile." + "Choose a profile"; controls disabled.
- Every setting saves immediately and says so ("Saved" `type.timecode` `positive` fades in beside the control for 1.5 s), except the admin Updates section (draft + Save) and the skin (restart flow).

#### 4.28.2 Skin picker and the restart flow

- **Picker:** two large **trailer cards** side by side (stacked on phone), 16:9: **Cinematic** and **Glass**. Each card plays a 6 s looping live miniature of the skin: a real render of Home in that skin at 25 % scale (web: an `<iframe src="/skin-preview/{skin}">` rendered with the other skin's CSS entry and `pointer-events: none`; app: a bundled 36-frame PNG sequence per skin at 6 fps, 720 × 405, about 1.2 MB each, swapped by a Ticker-driven `Image`, so no video package is added). Under each: name `type.section`, one line ("Dark cinema. Posters, light and film cuts." / "Depth, glass and springs."), a radio. The active skin has the `lamp` radio and "IN USE" badge.
- **Confirm sheet** (after choosing the other skin): title "Switch to Glass?", body "ManhwaManiacs restarts in the new skin. Everything changes: layout, motion and navigation. Your library, progress and downloads stay exactly as they are." When downloads are running: "Downloads pause and resume after the restart." Buttons: text "Not now", Primary "Restart in Glass". Haptic `skin.confirm` on confirm.
- **Outgoing animation, "final cut" (Cinematic side):** 0–250 ms: the current screen desaturates to grayscale and dims to 0.5; 250–625 ms: a film-burn: a radial `lamp` → `ember` → white hot spot blooms from the confirm button and burns the frame to white-hot at 70 % opacity, then 625–875 ms the frame cuts to black; 875–1000 ms: the wordmark flashes once (2f) and the app restarts. Reduced motion: 200 ms fade to black.
- **Restart:** per `stack-decision.md` §2.5 (PATCH the profile's `skin`, write the device mirror and the return route, service-worker `skin-changed`, `location.replace` on web, `AppRestart` on the app). The incoming skin plays its own splash and lands on the return route (Settings → Skin). A 10 s toast in the new skin offers "Undo" (switches back with the same flow).
- **Budget:** under 1.5 s from confirm to the new splash.

#### 4.28.3 Reader, Novels & listening

- Reader defaults (apply to series without their own setting): Mode, Direction, Fit, Page turn, Page gap, Column width, Cinema mode, Auto-scroll speed, Tap zones (with Reset), Background, Colour, Page tint, Keep screen on, Volume keys (Android), Refresh rate (Android), Haptic on page turn. Reset card: "Restore reader defaults" + Outline "Reset" (confirm).
- Novels: default face, size, line spacing, line width, alignment, flow, page turn, stock (with swatches), auto-next toggle, show dialogue tints toggle.
- Listening: default speed, sleep timer default, follow text toggle, lock-screen controls toggle (app), "Recaps before continuing" (Always · After 7 days away · Never, §5.1.3).

#### 4.28.4 Playback (haptics, sounds, ambience)

- Haptic feedback toggle (app; default on) with a "Feel it" text button that plays `stamp`.
- Interface sounds toggle (default **off**) with a volume slider and a "Hear it" button that plays `select`.
- Soundscape defaults: default loop (Off, Rain, Night city, Wind, Hearth, Temple, Deep space), volume, fade in over 4 s.
- Reduce motion note: "ManhwaManiacs follows your system's Reduce Motion setting." (no in-app override; the OS setting rules).

#### 4.28.5 Content (18+), Social

- Content: "Show mature content (18+)" toggle with the gate dialog (§3.25); errors inline ("Couldn't update this setting." + Retry).
- Social (§5.3): Share my reading toggle (per profile), Show reactions in the reader toggle, Who can recommend to me (Everyone on this server · Nobody), Hide a title from my activity (list with remove).

#### 4.28.6 Updates (admin, instance-wide)

- Schedule strip: three `stage` cells "LAST CHECK 12:04", "NEXT CHECK 12:34" (`warning` when overdue with the note "The next check was due 14 minutes ago. See System status."), "EVERY 30 MIN".
- Toggles: Check automatically, Check on server start, Notify about new chapters (master switch; per-series bells on title pages). Interval slider 5–120 min step 5 ("The server enforces a five-minute floor."). Save button + "Saved." / error.

#### 4.28.7 Account & security

- Account card: avatar initial, display name, "@username", ADMIN badge, Secondary "Sign out" (confirm "Sign out of this device?").
- Change password: current, new ("At least 8 characters"), confirm; validation lines; Primary "Change password" with helper "Other devices get signed out. This one stays signed in." Success toast "Password changed. Other devices were signed out."
- Sessions: rows with device label ("ManhwaManiacs app on iPhone", "Firefox on Linux"), THIS DEVICE badge, "Last used Sep 28 · 10.0.0.4", "Signed in Sep 1 · expires Oct 1"; this device: Outline "Sign out"; others: Danger · quiet "Revoke" (confirm "Sign out {device}?"); refresh icon button.
- Danger zone panel (`dangerDim`, `border.danger`): "Sign out everywhere" → dialog with an acknowledgement toggle "I understand this signs me out here too" that enables the Danger button.

#### 4.28.8 Keyboard (web)

- The live registry grouped (General, Navigation, this screen's groups), read-only. Each row: description + keycaps.

#### 4.28.9 Server (app)

- "Server address" field with the current URL, Primary "Save" (validates with `GET /health`; https required in release), Outline "Reset to default"; toasts "Server saved and applied." / "Reset to the default server."; the server host line with copy.

#### 4.28.10 Downloads & storage (app `/settings/storage`)

- The Storage tab content of §4.20 plus: Image cache card ("Covers and pages kept for speed" + size `type.timecode` + Outline "Clear image cache" → toast "Image cache cleared (240 MB)."), Metadata cache card (Outline "Clear metadata cache").

#### 4.28.11 Backup & restore (admin)

- Pending restore banner (`warning`): "A restore is staged. It applies the next time the server restarts." + Outline "Cancel staged restore".
- Export: explainer ("A copy of the whole server database: every account, profile, library and bookmark.") + Primary "Export backup" (leader "Preparing…") + "Saved manhwamaniacs-2026-09-28.db".
- Restore (`dangerDim` panel): explainer + Outline "Choose backup file" → "{file} · 42 MB" + Danger "Restore from this file…" → typed confirmation dialog ("Type RESTORE") listing: it replaces every account; sign-ins come from the backup; it applies on the next server restart; nothing current is kept. Success dialog "Restore staged. Restart the server to finish."

#### 4.28.12 Members (admin)

- Member rows: "@username", badges ADMIN / YOU / DEACTIVATED, "joined Jul 27 · last seen today · 2 sessions", Outline "Deactivate" / "Reactivate", Danger · quiet "Delete" (confirm "Delete @user? Their profiles, library, progress and bookmarks are removed. This can't be undone."). Pull to refresh. Empty "No other accounts yet."

#### 4.28.13 About

- The MM column 64 + wordmark, version and build `type.timecode`, "Self-hosted reader for manga, manhwa, manhua and web novels."
- Updates card: Android APK channel ("Up to date · 3.5.0", "Update available · 3.5.1" + Download, "Couldn't check for updates" + Retry, "Server unreachable"); iOS SideStore card ("Updates come from SideStore." + source URL `type.timecode` + Outline "Copy source URL"); web: "The web app updates itself." and the service-worker update prompt (§4.31).
- What's new (opens the sheet, §4.31), Open-source licences (the platform licence page restyled: `overlay` rows).

#### 4.28.14 Diagnostics (app)

- Big numbers `type.statHuge` sm (48 px): FPS (lamp), JANK % (positive < 5, warning < 15, danger), WORST MS; rows: average frame time, build and raster times; Display (Android): current refresh rate, capability, resolution; Device: platform, CPU cores, screen, app version, build mode; Image cache: live, cached n / max, memory MB. A live 120-frame bar sparkline of frame times (`lamp` bars, `danger` above 16.7 ms).

#### 4.28.15 Settings signature moment and keys

- Toggling any setting that changes the look (page tint, cinema default, stock) plays a 2 s live preview strip at the top of the section: a miniature reader frame showing the effect.
- Keys (web): `j`/`k` move between settings rows, `Space` toggles, `←`/`→` changes segmented values, `/` searches settings, `g ,` from anywhere opens Settings.

### 4.29 System status (admin)

- **Desktop web:** eyebrow "ADMINISTRATION", title "SYSTEM STATUS", Secondary "Refresh" (leader "Refreshing…"). A **summary slate** tinted by the worst state (positive / warning / danger / `ink3` unknown wash) with a state icon, a headline ("Everything is running." / "2 problems need a look.") and a bullet list of problems.
- Cards (2-column grid, 1 on phone): **Server** (state badge Healthy · Warning · Down · Unknown, version `type.timecode`, probe line, polled every 15 s with a heartbeat: a 6 px dot that pulses on each successful poll); **Update checker** (last run with relative time, next run with "in 40 min", interval, failed runs count in `danger`, Secondary "Check now"); **Recent checks** (up to 8 rows with status badges and error `<pre>` blocks in `raised` Geist Mono 12); **Source health** (per-source rows: state icon, name, id `type.timecode`, "demoted" `warning` badge, last probe time, message, last error `<pre>`; polled every 30 s).
- **Signature moment:** the health dots run like an EKG: each poll draws a short blip on a 120 px sparkline per source (`positive` flat line, `warning` jitter, `danger` flat red).
- **Non-admin:** title card "Administrators only." + "Ask the server owner to check this." + Back home.
- **States:** loading (4 slate cards), each card error inline with Retry, offline.

### 4.30 Status screens

| Screen | Title card | Actions |
|---|---|---|
| 404 (inside the shell) | Huge outline "404" in `type.statHuge` stroked `inkA24` behind the card; headline typed "Nothing here." body "This page doesn't exist, or the series it pointed at is gone. Press ⌘K to search everything." | Primary "Go home", text "Open library" |
| Route error | "500" outline; "This scene didn't load." / backend unreachable: "···" outline, "Can't reach the server." body "It may still be starting up, or the connection dropped. Your library is safe." + the reference chip | Primary "Try again", text "Go home" |
| Root error (no fonts, no providers; system fonts, inline CSS) | Black page, "ManhwaManiacs didn't start." in system-ui 32/36 700, body "Reloading usually fixes it. If it doesn't, check the server." | "Try again", "Reload the app" |
| Offline fallback (static HTML served by the service worker) | Inline CSS and inline SVG only: the MM column 72 px, a status pill "No connection" / "Back online" (live, `warning` / `positive` dot), headline "This page needs the server.", body "Chapters you saved still open.", note "Served from this device." | "Try again", "Open downloads" |
| Reader landing (`/reader`) | Title card "Pick something to read." | Primary "Go to library" |

Motion on all of them: the outline numerals do a slow `move.trackOut` (24 s, alternate) behind the card; the headline types.

### 4.31 Shared sheets and system prompts

- **What's new** (auto once after an update, and from More / About): a full-screen sheet styled as a trailer: version `type.statHuge` sm letter reveal ("3.5"), then each change as a numbered scene: `type.timecode` "01", headline `type.section`, one line `type.body`, an optional 16:9 still. Primary "Got it".
- **App update (web service worker):** a toast with action: "A new version is ready." + "Reload".
- **App update (Android APK):** More banner + About card (§4.27, §4.28.13).
- **Content mode sheet (phone):** "Reading mode" title, two large rows "Manga · manhwa · manhua" and "Novels" with the radio, body "One setting for the whole app. Library, sources, search, downloads and updates follow it." Choosing plays `move.reelChange`.
- **Series actions sheet:** the preview slate sheet (§3.11, §3.23).
- **Confirmation dialogs** (every destructive or irreversible action): Delete profile, Sign out, Sign out this device, Sign out everywhere, Enable mature content, Reset reader settings, Delete member, Delete collection, Remove series downloads, Remove all downloads, Cancel all downloads, Reset offline storage, Unfollow (bulk), Restore backup, Switch skin. All follow §3.15 with the 1000 ms arm delay on the danger button.
- **Notification permission** (reserved for push): a sheet "Get told when chapters land?" with Primary "Allow notifications" / text "Not now", shown once, after the first follow.

---
## 5. The four new features

All four are designed server-first (`stack-decision.md` §2.6): the backend computes AI rails, recaps, stats aggregates, social filtering, ambient palettes and panel boxes, and both clients only render. Every item below respects per-profile isolation and applies the 18+ gate when serving.

### 5.1 AI home, recommendations and "Previously on"

#### 5.1.1 Data and composition

- **Now:** Home is composed client-side from `GET /library/continue-reading`, `GET /library/recently-updated`, `GET /library/world/recommendations`, `GET /library/suggest/availability`, `GET /library/statistics?days=30`, `GET /library/recommendations` (genre weights) and the social feed (§5.3).
- **Reserved:** a `GET /home` endpoint returning ordered sections `{type, title, reason, items[], state}` so the server can reorder rails. The client renders whatever order it receives, using the rail types below; until it exists, the client uses the default order.
- Every rail has `state: loading | ready | empty | unavailable`. Empty and unavailable rails are not rendered; the page never shows an empty rail.

#### 5.1.2 Home rails (default order)

| # | Rail | Source | Shape | Header (typed "why" line under the H3 where noted) |
|---|---|---|---|---|
| 0 | Hero spotlight | top of: continue with new chapters, then "because you read" best pick, then recently updated | hero | typed headline (§6.2): "TONIGHT: CHAPTER 143 OF OMNISCIENT READER" / "NEW: 3 CHAPTERS OF SOLO LEVELING: RAGNAROK" / "PICKED FOR YOU: THE GREATEST ESTATE DEVELOPER" |
| 1 | Continue reading | continue-reading (limit 12) | 16:9 continue cards | "CONTINUE" |
| 2 | Previously on | continue items last read ≥ 7 days ago | 2:1 recap banner (max 1 per visit) | "PREVIOUSLY ON" |
| 3 | New episodes | followed series with unread chapters | posters + NEW badges | "NEW EPISODES" |
| 4 | Sent to you | social inbox (§5.3.5) | posters with sender avatar | "SENT TO YOU" + typed note of the newest ("Mara: you'll love the tower arc") |
| 5 | Because you read {title} | world recs `sections[]`, one rail per seed (max 3 on Home) | world cards (poster form) | "BECAUSE YOU READ {TITLE}" letter reveal |
| 6 | For you | world recs `for_you` | posters | "FOR YOU" + typed "Picked from what this profile reads." |
| 7 | Finish soon | followed, reading, ≤ 3 chapters left | posters + "2 LEFT" timecode | "ALMOST THERE" |
| 8 | Picked back up | reading status reading, last read 21–120 days ago | posters + "3 WEEKS AGO" | "WHERE WERE WE?" |
| 9 | Top 10 on this server | most-read across sharing profiles this week (18+ filtered per viewer) | Top-10 numerals | "TOP 10 THIS WEEK" |
| 10 | Friends are reading | social feed, distinct series | posters + avatar stack | "YOUR CREW IS READING" |
| 11 | Your genres | genre weights | filter-slate words linking to Search `?q=` | "YOUR GENRES" |
| 12 | Networks | pinned sources, then all | 16:9 source hubs | "NETWORKS" |

Novels mode swaps posters for book plates in rails 1, 3, 5–10 (a book-plate rail: 2:3 plates 120 px with the title in Newsreader under each).

#### 5.1.3 "Previously on" (recap before continuing)

- **Trigger:** Continue on a series last read ≥ 7 days ago (Settings → Listening → "Recaps before continuing": Always · After 7 days away (default) · Never), or the Previously-on banner on Home, or "Recap" in a title page's overflow menu.
- **Backend (new):** `POST /library/recap {source_id, series_key, up_to_chapter_key}` → `{status: "ok"|"not_configured"|"budget_exhausted"|"no_text"|"rate_limited", bullets: [string ≤ 5], last_scene: string, characters: [{name, note}], cover_still_url, model}`, streamed as server-sent events for the bullets. Built from OCR page texts (manga) or chapter text (novels) through the external AI API; cached per (profile, series, chapter).
- **Screen, "cold open" (full-screen, both form factors):** black, letterbox bars at 2.00:1. 0–500 ms: "PREVIOUSLY ON" `type.eyebrow` letter reveal centred; 250–1000 ms: the series title in `type.editorialXL` letter reveal under it; 1000 ms: the subtitle types at 50 ms per character: "CHAPTER 141 · 12 DAYS AGO"; the backdrop (the last-read page, or the cover, at `blur.art` with Ken Burns) dissolves in behind. Then the recap bullets stream word by word (160 ms fade, 30 ms apart) as numbered lines in `type.bodyLg` `n11`, each with a `type.timecode` chapter reference ("CH 138"). A "LAST TIME" block shows `last_scene` in Newsreader italic. Characters appear as a single row of name chips with their one-line note on hover or tap.
- **Controls:** Primary · play "Continue · Ch 142" (always visible from t = 0), text "Skip recap" (top-right, Netflix-style, visible from t = 0), a 12 s `lamp` countdown ring on Continue that starts when the stream completes (pauses on touch or hover). Enter continues, Esc skips.
- **Exit:** Continue → `move.curtain` into the reader (the letterbox bars are already in place, so they close from 2.00:1 to black and open on the page).
- **States:** loading (the title card choreography plays; a 24 px leader appears under the subtitle after 1 s), streaming, done (countdown), **unavailable** (never an error colour: a static slate "RECAP UNAVAILABLE" `type.section` `ink3` + body "Pick up where you left off: Chapter 142." + Continue; the reason line in `type.caption` `ink3`: "AI isn't set up on this server." / "Today's AI budget is used up." / "There's no text to summarise for these chapters yet." / "Too many requests. Try again in a minute."), offline (the recap is skipped silently and the reader opens directly, unless a cached recap exists, which then plays).
- **Reduced motion:** the text appears at once; the countdown still runs visually as a static "Continuing in 12 s" label that updates each second.

#### 5.1.4 For you (`/library/recommendations`)

- **Hierarchy:** the prompt ("Describe what you feel like reading"), then the For you wall, then "Because you read" rails, then Your genres.
- **Prompt block (desktop):** a black stage with the typed headline "WHAT ARE YOU IN THE MOOD FOR?" (`type.slug`), a textarea (3 lines, 600 max, counter), example token chips ("A murim regressor who comes back stronger", "Magic academy where the lead is already strong", "Slow and political, not a power fantasy"), a quota meter "8 ASKS LEFT TODAY" in `type.timecode` (a 10-frame mini reel meter when ≤ 10), Primary `sparkle` "Suggest", segmented `MY SOURCES · EVERYWHERE` (maps to `POST /library/suggest` vs `POST /library/world/suggest`).
- **Results:** a wall of world cards (§3.14) with their `why` line typed at 50 ms per character under each card title (only for the first 6 visible; the rest render instantly). Available cards open the title page (source picker sheet when there are several sources); info cards offer "Search my sources" (opens Search with `?q=`).
- **Signature moment, "the pitch":** while the AI thinks, the stage shows a **leader countdown** (the SMPTE sweep at 80 px counting 3 · 2 · 1 in `type.statHuge`, looping) behind the prompt; when results land, the countdown flashes (2f) and the cards dolly in with the grid stagger.
- **States:** AI loading (countdown + 6 slate cards), AI results, AI no matches ("Nothing fits that description. Try it another way."), AI error ("That didn't work. Try again."), not configured (the prompt block is replaced by a quiet line "AI suggestions aren't set up on this server." and the page starts at the For you wall), budget exhausted ("You've used today's suggestions. More tomorrow."; textarea disabled), rate limited ("Too many asks at once. Wait a minute."), world catalogue unreachable (`unavailable_reason` shown as a banner "The worldwide catalogue isn't answering. Showing saved picks."), page loading (the For you header + 12 slates), empty ("Nothing to go on yet." + "Read or follow a few series and picks start here."), offline.
- **Keys:** `/` focuses the prompt, `mod+enter` or Enter submits (Shift+Enter newline), `1`–`3` fill an example, grid keys.

#### 5.1.5 AI state vocabulary (used on Home, For you, recaps)

| State | Visual | Copy tone |
|---|---|---|
| thinking | leader countdown or per-word streaming | none (no "thinking…" spinners) |
| unavailable | static slate in `ink3`, never `danger` | plain reason + the non-AI path forward |
| partial | the rails that loaded render; missing AI rails are omitted | none |
| stale | a `type.timecode` "PICKED 3 DAYS AGO" under the rail header | none |

### 5.2 Reading stats, streaks and Wrapped

#### 5.2.1 Stats screen, "Box office" (`/library/statistics`)

- **Range slate:** `7 DAYS · 30 DAYS · 90 DAYS · YEAR` (365) + content-mode note ("Totals include manga and novels; lists follow the Manga / Novels switch.").
- **Top row (desktop 4 stat cards, phone 2 × 2):** Chapters, Time read ("42 H 10 M"), Pages / Words (mode), Series. `type.statHuge` numbers count up (§3.14) with an all-time caption.
- **Streak card (full width):** the **flame** (§5.2.2) at 96 px left, current streak `type.statHuge` "12" + "DAYS" eyebrow, "Longest 31 · Last read today" `type.timecode`, and a 14-day strip of 14 × 10 px frames (lamp = read, `raised` = not; today outlined).
- **Heatmap ("the reel"):** 53 weeks × 7 days of 12 px squares with 3 px gaps (desktop), 26 weeks on phone (horizontal scroll to go back); 5 intensity steps from `raised` to `lamp` (0, 1–2, 3–5, 6–10, 11+ chapters); hover or tap shows "SEP 24 · 7 CHAPTERS · 1 H 12 M".
- **Chapters per day:** bars (`lamp` 85 %) with a time-read line (`ink2` 1.5 px, square markers), left axis chapters, right axis time; x labels every 7 days in `type.timecode`.
- **When you read (clock):** a 24-segment radial clock (inner radius 40 %, segments scaled by pages) with the peak range labelled ("YOU READ AT NIGHT · 22–01").
- **Genre radar:** 6 axes (the top 6 genres by weight), a filled polygon in `lamp` at 24 % with a 1.5 px `lamp` edge on a hairline web; tap an axis → Search that genre.
- **Top series:** ranked rows with covers and the Top-10 outline numerals, "412 pages · 38 chapters · 6 h".
- **Top sources:** rows with share bars.
- **Recent sessions:** rows "Omniscient Reader · Ch 142 · 18 pages · 14 min · 21:40".
- **Your library:** "86 followed · 12 favourites · 1,204 chapters finished" + per-status bars.
- **Footnote:** "Days start at UTC+05:30. Sessions count up to 30 minutes each. Recording since Jul 27."
- **Your year** card at the top from December 1 (and any time as "Your year so far"): a 21:9 banner "YOUR 2026 IN REELS" `type.display` + Primary "Play" → Wrapped.
- **Share:** each card has a Round icon `share-fat` that exports a 9:16 stat card (§5.2.4).
- **Signature moment:** charts **draw like a projector warming up**: bars rise from the baseline on `spring.dolly` with a 42 ms stagger, the heatmap lights week by week left to right in 750 ms, the radar polygon grows from the centre on `spring.crane`.
- **States:** loading (4 slate cards, slate strip, 320 px slate chart), empty ("No reading recorded yet." + "Read a chapter and it starts counting."), offline, error.
- **Keys:** `1`–`4` ranges, `w` opens Wrapped, `s` shares the focused card.

#### 5.2.2 Streaks

- **Definition:** the backend's `streak.current_days` (a day with at least one recorded session, in the profile's time zone).
- **Flame states** (a custom-painted flame, not an icon: 3 layered bezier tongues in `ember2 → ember → lamp` with a `lampGlow` halo; the tongues sway on `drift` 1.6–2.4 s periods):

| Streak | Flame | Motion |
|---|---|---|
| 0 | a grey ember dot `ink4` | none |
| 1–6 | small flame, 1 tongue | slow sway |
| 7–29 | full flame, 3 tongues | sway + halo breathing |
| 30–99 | flame + a thin `lamp` ring | sway + ring rotating 1 rev / 24 s |
| 100+ | flame + ring + 12 px sparks rising every 3 s | as above |
| at risk (no session today and it is after 20:00 local) | flame desaturated 50 % | flicker (opacity 0.7 ↔ 1, 800 ms) |

- **Where it shows:** Home top bar chip (flame 20 + count, only when ≥ 2), Stats streak card, More row, the end-of-chapter credits when a chapter extends the streak.
- **Ignite (streak +1):** when the first chapter of the day completes, the credits band shows the flame growing from the ember dot to its new state over 750 ms with the count rolling up, haptic `ignite`, sound `complete`. Milestones (7, 30, 100, 365) add a title card "30 DAYS." `type.editorialXL` with the letter reveal and a share button.
- **At-risk nudge:** after 20:00 local with no session, Home's typed headline becomes "12 DAYS AND COUNTING. ONE CHAPTER KEEPS IT ALIVE." (no push notifications; in-app only).

#### 5.2.3 Wrapped, "Your year in reels" (`/library/statistics/wrapped/:year`)

- **Frame:** full-screen story format. Phone: full-bleed 9:16. Desktop: a 9:16 stage (height 88 vh) centred on black with the scene's backdrop at `blur.art` filling the sides, and a 2.39:1 letterbox matte on scenes that use art.
- **Controls:** tap right third / `→` next, tap left third / `←` back, press and hold / `space` pause, swipe down / `esc` close; segmented progress bars at the top (one per scene, `lamp` fill over each scene's duration). Haptic `wrap.card`, sound `wrap` per scene.
- **Scenes** (each 6 s unless noted; every headline uses the letter reveal, every stat line the 50 ms typing):
  1. **Cold open** (4 s): black, "2026" `type.statHuge` tracks out, then "YOUR YEAR IN REELS" letter reveal.
  2. **The runtime:** time read "212 HOURS" counting up; sub typed "That's 88 feature films."
  3. **The count:** chapters "4,812" and pages / words; a film strip of 40 tiny covers scrolls horizontally behind at 60 px/s.
  4. **Top billing:** the #1 series: its cover match-cuts from small to full-bleed with Ken Burns, "YOUR MOST-READ SERIES", the title, "612 CHAPTERS".
  5. **The ensemble:** top 5 series as posters with Top-10 outline numerals, dollying in one by one.
  6. **Genre radar:** the radar grows; headline "YOU'RE A {TOP GENRE} READER."
  7. **Night owl or early bird:** the 24 h clock lights; headline from the peak hour ("MIDNIGHT SHOWINGS" 22–03, "MATINEE" 12–17, "FIRST LIGHT" 05–09).
  8. **The streak:** the flame at 160 px, longest streak "31 DAYS", best month.
  9. **Your crew** (only when social is on and others share): "YOU AND MARA BOTH READ 4 SERIES" with the shared posters.
  10. **Credits** (8 s): end credits roll (`move.trackOut` on each line) listing top series, sources ("SHOT ON MANGADEX, ASURA"), voices used in listening ("NARRATED BY ARDEN"), then "SEE YOU IN 2027." and buttons "Share my year" / "Replay".
- **Share:** "Share my year" exports scenes 2, 4, 6, 8 and 10 as five 9:16 cards; each scene has its own share icon button too.
- **18+:** adult series never appear on share cards unless the profile is mature and the user turns on "Include 18+ titles" in the share sheet (default off); in the playback itself they appear only for mature profiles.
- **States:** loading (cold open holds on "2026" with the leader), not enough data (< 10 sessions: "Not enough reading for a recap yet. Come back after a few more chapters."), offline, error.

#### 5.2.4 Shareable stat cards (image export)

- **Format:** 1080 × 1920 PNG, black, grain at 0.05, the MM column mark 48 px and "MANHWAMANIACS" `type.micro` at the bottom, the profile avatar and name (optional toggle "Show my profile name"), the stat as the scene lays it out.
- **Card types:** streak ("12 DAYS"), month ("SEPTEMBER · 312 CHAPTERS"), finished series ("FINISHED · OMNISCIENT READER · 551 CHAPTERS"), top series, genre radar, year scenes.
- **Share sheet:** a preview of the card at 40 % scale, toggles "Show my profile name", "Include 18+ titles" (mature profiles only), and Primary "Save image" plus (web, when `navigator.canShare({files})`) Secondary "Share…".
- **Web:** each card is an SVG template filled with the stats and cover images converted to data URLs, drawn into a 1080 × 1920 `<canvas>` via `Image` + `drawImage`, exported with `canvas.toBlob("image/png")`; Save uses a download link; Share uses the Web Share API with the file.
- **App:** the card widget renders offstage inside a `RepaintBoundary` at 360 × 640 and exports with `toImage(pixelRatio: 3)` → PNG bytes, saved through the existing Save to Files export folder ("Files → On My iPhone → ManhwaManiacs → Exports → Cards", Android: the app's exports folder) with the result dialog showing the path; toast "Card saved", haptic `share.saved`.
- **Backend (new):** `GET /library/statistics/year?year=2026&tz_offset_minutes=` returns the year-bounded aggregates plus genre weights over the year, so every client renders the same numbers.

### 5.3 Social for 2–3 users

#### 5.3.1 Model and privacy

- **Opt-in per profile:** Settings → Social → "Share my reading" (default off). Only profiles that opted in appear anywhere in social surfaces, and only to other profiles (on any account on this server) that also opted in. A profile never sees its own account's other profiles' activity unless both opted in.
- **18+ gate on serve:** an activity, reaction, recommendation or shared-collection item about an adult series is served only to viewer profiles with mature content on, and only if the sharing profile turned on "Include 18+ titles in my activity" (default off). A non-mature viewer sees nothing at all about it (not even a placeholder in the feed).
- **Hide a title:** any series can be hidden from one's activity (title page overflow → "Hide from my activity").
- **Backend (new):** `GET /social/feed?cursor=`, `GET /social/now` (profiles active in the last 10 minutes), `POST /social/reactions {source_id, series_key, chapter_key, kind}`, `DELETE /social/reactions/{id}`, `GET /social/reactions?source_id&series_key&chapter_key`, `POST /social/recommend {to_profile_ids[], source_id, series_key, note}`, `GET /social/inbox`, `PATCH /social/inbox/{id} {seen}`, `POST /library/collections/{id}/share {profile_ids[]}`, `DELETE /library/collections/{id}/share/{profile_id}`. Every query is filtered by the viewer's `(user_id, profile_id)`, the opt-in and the 18+ rule on the server.

#### 5.3.2 Activity screen, "The screening room" (`/activity`)

- **Tabs:** `FEED · SENT TO YOU · SHARED`.
- **Now reading strip** (top of Feed, only when someone is active): avatars 40 with the `ember` LIVE badge and the series cover peeking behind each avatar ("Mara · Solo Leveling · CH 88"); tap opens the title page.
- **Feed items** (rows with the avatar 40, a verb line, a 2:3 cover 48 × 72 on the right, timecode):
  - started: "Mara started **The Greatest Estate Developer**"
  - read: "Mara read 12 chapters of **Omniscient Reader**" (consecutive reads collapse by series per day)
  - finished: "Mara finished **Tower of God** · 591 chapters" (with a small `flag-checkered`)
  - followed: "Arjun followed **Nano Machine**"
  - reacted: "Mara reacted `flame` to **Omniscient Reader** · Ch 142"
  - collection: "Arjun shared **Murim nights** with you"
  - milestone: "Mara hit a 30-day streak" (flame 16)
- Each item: quick actions on hover (desktop) or swipe (phone): "Read it too" (opens the title page), "+ My list", react (`smiley`, opens the reaction picker for that chapter).
- **Sent to you tab:** recommendation cards: sender avatar, the typed note in `type.editorial` ("you'll love the tower arc"), the poster, Primary "Read" / Secondary "+ My list" / text "Dismiss"; unseen ones have a `lamp` dot.
- **Shared tab:** shared collections (banners with member avatars).
- **Signature moment:** new feed items arrive like **dailies being threaded**: they slide in from the top on `spring.dolly` while a thin `lamp` film-perforation strip (6 × 4 px holes every 12 px) runs down the left edge of the list and ticks forward by one hole per new item.
- **States:** not opted in (title card "Share your reading?" + body "Other accounts on this server see what this profile reads. 18+ titles are never shared unless you choose to." + Primary "Turn on sharing" + text "Not now"), nobody else sharing ("Nobody else is sharing yet." typed), loading (6 slate rows), offline, error.

#### 5.3.3 Reactions

- **Set (6):** Fire `flame`, Tears `drop`, Shock `lightning`, Laugh `smiley`, Love `heart`, Chills `snowflake`, Phosphor Bold at rest, Fill `ember` when yours.
- **Where:** the chapter seam and end credits in both readers (a row of six 44 px round icon buttons with counts in `type.timecode` and up to 3 friend avatars 18 px next to each reaction friends chose), chapter rows on the title page (a 14 px icon + count of the top reaction), feed items.
- **Motion:** pressing a reaction stamps it (scale 1.25 → 1 on `spring.press`), the count rolls up, and a single `ember` spark (6 px dot) rises 24 px and fades over `dur.scene`; haptic `reaction`. Removing: the Fill dissolves back to Bold.
- **Privacy:** reactions are social activity and follow §5.3.1; if the profile has not opted in, the reaction row shows only the profile's own private reactions (kept for its own history) and a text button "Share reactions with friends".

#### 5.3.4 Shared collections

- **Share:** in the collection dialog, the Share toggle opens a friend picker (opted-in profiles, avatars 40 as toggles); saving sends an invitation that appears in the recipient's Activity → Shared tab with Accept / Decline.
- **Detail:** member avatars in the header; each poster shows "Added by Mara" `type.caption` on focus or long-press; any member can add or remove series; only the owner can rename, unshare or delete; a member can "Leave collection" (confirm).
- **18+:** adult members of a shared collection are hidden per viewer; the count reads "12 series (2 hidden on this profile)".
- **States:** invitation pending (banner "Waiting for Mara to accept"), declined (toast to the owner), member removed (toast).

#### 5.3.5 Recommend to

- **Entry points:** title page round icon `paper-plane-tilt`, preview slate, end-of-series credits ("Recommend to a friend"), Wrapped credits.
- **Sheet:** "Recommend {title}" `type.section`, the poster 80 px, friend avatars (opted-in profiles) as toggles with names, a note field (140 max, placeholder "Why they'll like it"), Primary "Send" (disabled until one friend is chosen). Sent: the avatars fly toward the top-right corner on `spring.dolly` and the sheet closes; toast "Sent to Mara"; haptic `recommend`.
- **Recipient surfaces:** Home "Sent to you" rail, Activity → Sent to you, the More → Activity dot, the Reel Index Activity dot.
- **States:** no friends ("Nobody else is sharing yet, so there's nobody to send to."), 18+ title with a non-mature recipient (that avatar is disabled with the tooltip "Not available on their profile"), offline (queued in the outbox with the toast "Will send when you're back online").

### 5.4 Ambient reader extras

#### 5.4.1 Auto-scroll ("projector")

- **Controls:** the bottom-chrome chip "▶ 1.4×" (tap play/pause, long-press or `,` opens the speed control), `p` / `space` on web, the right-edge swipe HUD on phones.
- **Speed:** steps 1–10 map to 20, 40, 60, 80, 100, 120, 140, 160, 190 and 220 px/s at a 1080 px viewport, scaled by viewport height / 1080 so the pace feels the same on every screen; shown as a multiplier where 5 = 1.0 × (100 px/s): 0.2 ×, 0.4 ×, 0.6 ×, 0.8 ×, 1 ×, 1.2 ×, 1.4 ×, 1.6 ×, 1.9 ×, 2.2 ×. Remembered per series.
- **Pace by dialogue** (toggle, manga with OCR text): the speed scales by `clamp(1.2 − words_on_screen / 60, 0.5, 1)` so wordy panels slow the projector.
- **Motion:** starts with a 500 ms ease-in ramp (`cineIn` on velocity) and haptic `projector`; the rolling dot on the chip is `ember` and breathes; stops with a 250 ms ramp down. Frame-accurate scrolling via `requestAnimationFrame` (web) and a `Ticker` driving `ScrollController.jumpTo` (Flutter) with elapsed-time integration so dropped frames never change the pace.
- **Pauses on:** touch, manual scroll, tap, key, opening any panel, app background; resumes only on explicit play.
- **End:** at a seam it continues into the next chapter; at the end of the feed the Up Next card runs its 5 s countdown and advances (auto-scroll keeps rolling after the curtain).
- **Reduced motion:** never auto-starts; available on explicit play.

#### 5.4.2 Ambient soundscape

- **Loops (6 + auto):** Rain, Night city, Wind, Hearth, Temple, Deep space; "Match the series" picks by genre (horror → Wind, romance → Rain, murim and martial arts → Temple, sci-fi → Deep space, fantasy → Hearth, modern and action → Night city). Each loop is an original 60 s seamless recording, 96 kbps (OGG on web and Android, M4A on iOS), about 720 KB.
- **Controls:** the `waveform` button in reader chrome opens a sheet (desktop: a menu) with the loops as tiles (each tile shows a 6-bar live level meter while playing), a volume slider (default 30 %), and "Stop with the reader" toggle (default on).
- **Mix:** fades in over 4 s, crossfades between loops over 3 s, ducks by −12 dB under TTS narration and UI sounds, fades out over 2 s on leaving the reader.
- **Delivery:** web lazy-loads from `/public/sounds/cine/*.ogg`, plays through Web Audio `AudioBufferSourceNode` with `loop = true`; app bundles the loops (4.3 MB) and plays them on a second `just_audio` player (installed) with `LoopMode.one`, mixed with the narration player through `audio_session`'s ambient category.
- **States:** off, loading (leader on the tile), playing, paused (with the reader chrome), error ("That sound didn't load." toast).

#### 5.4.3 Panel-by-panel guided view ("camera")

- **Backend (new):** `GET /reader/panels?source&series&chapter` → `{pages: [{index, panels: [{x, y, w, h}], order}]}` with normalised boxes, computed on first request (gutter detection on the server's page copies), cached per chapter; `status: "ready" | "pending" | "unavailable"`.
- **Entry:** `panel-focus` in the reader chrome, `v` on web, or long-press → "Panel view".
- **View:** the page layer is transformed by a **camera** (translate + scale) so the current panel fills the stage with 24 px margins; the area outside the panel dims to 25 % through a mask whose rect animates with the camera. Moving between panels is a true dolly: `spring.dolly` on the camera transform, with the next panel's rect as the target, so a finger or key press mid-move retargets smoothly. Panels taller than 1.6 × the stage are split into stage-height shots with 20 % overlap.
- **Controls:** tap right / swipe left / `→` / `space`: next; tap left / swipe right / `←`: previous; `esc` or the chip "PANEL 14 / 212" exits back to the strip at the same spot; haptic `panel.next` per panel. With auto-scroll on, each panel holds 1.2 s + 0.25 s per OCR word (cap 6 s) with a thin `lamp` hold bar under the chip.
- **States:** "Framing panels…" (leader, the strip stays usable underneath), ready, partial (pages without boxes are one full-fit shot each), unavailable (toast "Panel view isn't available for this chapter." and the strip stays).
- **Reduced motion:** panels cut instead of dollying.

#### 5.4.4 Page-tinted chrome

- **What gets tinted:** the top scrim (24 % of `amb.tint` derived from the page), the glow under the scrubber (`amb.glow` at 30 %), the strip gutters (vertical `amb.glow` at 18 %), the mini player's left edge, and the end-credits band.
- **Sampling:** §2.1.5 (page crossing the reading line, max every 600 ms, 750 ms dissolve). Dark or greyscale pages keep the previous tint rather than snapping to grey.
- **Toggle:** `t` or Settings → Reader → Page tint (default on).
- **Reduced motion:** the tint changes with a 200 ms crossfade.

---
## 6. The two required signature animations (plus the reel-change cue)

### 6.1 Heading reveal, "Title card": each letter fades in, slides up and un-blurs, staggered

| Property | Value |
|---|---|
| Split | Grapheme clusters (web `Intl.Segmenter(undefined, { granularity: "grapheme" })`, Flutter `String.characters`); words wrapped in `nowrap` groups so lines break only between words |
| Per letter from → to | opacity 0 → 1, y +0.45 em → 0, blur 10 px → 0 |
| Durations | opacity and y 700 ms; blur 500 ms (sharp before it settles) |
| Easing | `ease.cineOut` `cubic-bezier(0.16, 1, 0.3, 1)` |
| Stagger | `step = min(28 ms, 600 ms / (n − 1))`: a 13-letter wordmark ends at ≈ 1036 ms, a 40-letter title at 1300 ms |
| Responsive size | uses the element's `type.*` token, which is fluid per breakpoint (§2.2.2, e.g. `type.section` 21 → 30 px, `type.heroTitle` 44 → `clamp(96px, 6.6vw, 128px)`) and clamped per mobile text scale (§2.2.3) |
| Tracking | tight: −0.01 em (section) to −0.025 em (hero); `font-kerning: none` so split and unsplit text match |
| Colour on hover / state | linked headings (rail headers with "See all", section titles that navigate) wipe from `ink` to `lamp` left to right: each letter transitions `color` over 240 ms with `transition-delay: calc(var(--i) * 12ms)`; leaving reverses with no delay. Focus-visible triggers the same wipe. Disabled headings sit at `ink3` and never wipe. |
| Trigger | rail and section headers: 60 % in view, once per session per header key; hero titles: every spotlight change, starting 200 ms into the dissolve; title page: after the match cut lands; dialogs: never |
| Interrupt | scrolled out before finishing → completes instantly; tap or key → completes instantly |
| Accessibility | container `aria-label={text}` / `Semantics(label:)`; letters `aria-hidden` / `excludeSemantics` |
| Reduced motion | whole string fades in over 200 ms, no y, no blur, no stagger |

**Placement (every use):** all H3 rail headers on Home, For you, Search result groups and title-page "More like this"; page titles (LIBRARY, SEARCH, SOURCES, UPDATES, DOWNLOADS, COLLECTIONS, HISTORY, BOOKMARKS, STATS, ACTIVITY, SETTINGS section titles, SYSTEM STATUS, DIALOGUE SEARCH, MORE); the Home hero title; the title page title; the book page title (serif); the source catalogue title; the pre-roll wordmark; "PREVIOUSLY ON" and the recap series title; chapter seams ("END OF CHAPTER 142", "CHAPTER 143"); novel chapter headers' eyebrow; Wrapped scene headlines; streak milestone cards; the profile picker headline; "What's new" version number; the Up Next title in listen mode uses typing instead (§6.2).

**Web** (Motion 13.4.4, `motion/react`): a `LetterReveal` client component with parent variants `delayChildren: stagger(step)`, child variants `{ opacity: 0, y: "0.45em", filter: "blur(10px)" } → { opacity: 1, y: 0, filter: "blur(0px)", transition: { duration: 0.7, ease: [0.16,1,0.3,1], filter: { duration: 0.5 } } }`, `whileInView` with `viewport={{ once: true, amount: 0.6 }}`, and a module-level `Set<string>` of seen keys that renders `initial={false}`. The hover wipe is CSS: `.reveal-letter { transition: color 240ms ease; transition-delay: calc(var(--i) * 12ms) } a:hover .reveal-letter, a:focus-visible .reveal-letter { color: var(--mm-color-lamp) }`.

**Flutter** (`flutter_animate` 4.5.2): a `LetterReveal` widget that builds one `Text` per grapheme inside a `Wrap` of word `Row`s, each `.animate(delay: step * i).fadeIn(700.ms, curve: cineOut).slideY(begin: .45, end: 0, duration: 700.ms, curve: cineOut).blurXY(begin: 10, end: 0, duration: 500.ms, curve: cineOut)`; the in-view trigger comes from the enclosing scrollable: a `ScrollNotification` listener computes when the header is 60 % inside the viewport and starts the controller; seen keys live in `seenRevealKeysProvider`. Hover wipe (web-only concern) is not needed on touch; on Flutter desktop-class pointers (iPad with a trackpad) a `MouseRegion` drives a `TweenAnimationBuilder<double>` per letter with the 12 ms delay.

### 6.2 Main headline typing reveal, "Slug line": one character every 50 ms

| Property | Value |
|---|---|
| Rate | exactly one grapheme per 50 ms, spaces included, no punctuation pauses |
| Clock | timestamp-based (`floor(elapsed / 50)`), so dropped frames never slow it |
| Layout | the full string is laid out from frame 0; unrevealed text is transparent, so lines never reflow |
| Caret | `lamp` block 0.5 em × 0.9 em, zero layout width (overflows), after the last revealed grapheme; solid while typing; when done it blinks 530 ms on / 530 ms off three times (3180 ms) and disappears |
| Length | ≤ 60 graphemes (≤ 3 s); longer AI text streams per word instead (§2.9.6) |
| Skip | tap, click, Enter or Space completes instantly |
| Face | `type.slug` (Mona Sans 780 wdth 80, uppercase) for the main headline; `type.editorial` for title-card headlines |
| Accessibility | full text in the accessibility tree from the start; the visual layer is hidden from it |
| Reduced motion | full text at once, no caret |
| Sound | none (a typewriter sound would be a gimmick) |

**Placement (every use):** the **Home main headline** over the hero (the primary placement, re-typed whenever the spotlight changes, e.g. "TONIGHT: CHAPTER 143 OF OMNISCIENT READER"); the "Previously on" subtitle ("CHAPTER 141 · 12 DAYS AGO"); the For you headline ("WHAT ARE YOU IN THE MOOD FOR?") and each AI `why` line (first 6 cards); the "Sent to you" note; Setup, Login and Register headlines; every empty / error / offline title-card headline (§3.24); Search's source names as rails arrive; the Up Next titles in both readers and listen mode; Wrapped stat lines; the at-risk streak headline; the Dialogue search first three results.

**Web:** a `useTyped(text, 50)` hook with `requestAnimationFrame` and `performance.now()`, rendering `shown` + a zero-width caret span + `rest` in `color: transparent`; the caret blink is a CSS animation `caret-out 3.18s steps(1) forwards` over six 530 ms halves.
**Flutter:** a `TypedHeadline` `StatefulWidget` with a `Ticker` computing `elapsed.inMilliseconds ~/ 50`, a `Text.rich` of revealed text + a `WidgetSpan` caret in a zero-width `OverflowBox` + the transparent remainder; the caret blink is one `AnimationController(duration: 3180 ms)` whose value × 6 floors to on/off.

### 6.3 Reel-change cue (this concept's own signature, reused everywhere a section changes)

- Two 10 px `ink` circles 6 px apart, 24 px from the top-right corner of the content area (below the safe area on phones), each with a 1 px `inkA24` ring: flash on for 1f, off for 1f, on for 1f, starting 125 ms before the cut of `move.dip`. They are the projectionist's cue marks: the audience learns that the reel just changed.
- Paired with haptic `cue` (two light ticks 83 ms apart, iOS and Android) and sound `cue` when sounds are on.
- Used on: tab changes, sidebar section changes, content-mode switch, profile switch, skin restart (the last thing the old skin shows).
- Reduced motion: one 2f flash, no repeat.

---

## 7. Brand

### 7.1 Wordmark, "Stack"

- **Lockup:** "MANHWA" above "MANIACS", flush left, uppercase, Mona Sans redrawn at `wdth 75`, `wght 860`, tracking −0.02 em, leading 0.84 so the lines nearly touch; aspect ≈ 2.3 : 1.
- **The two M's** are joined into one shape, the **MM column**: the top M stands on a horizontal **gutter bar** and the bottom M hangs from its underside; the bar overhangs each M by 6 % of the M width. Stems vertical, the inner V 60 % deep, miter joins, flat caps. On a 1024 canvas the column spans x 240–784, y 192–832: top M y 192–480, bar y 480–544 (x 208–816), bottom M y 544–832, stroke 88 units.
- **Colour:** letters `#F5F5F1`; the MM column in `#F5F5F1` with the gutter bar **lit**: `lamp` `#FFB547` with a 12 px bloom at 45 %. The gutter is the white strip between webtoon panels and the gap between one chapter and the next; in this skin it is a strip of projector light.
- **Single-line fallback** (tight headers, collapsed Reel Index tooltip): "MANHWAMANIACS" on one line with only the gutter bar under the two M's lit.
- **Minimum sizes:** lockup 20 px cap height; single line 12 px cap height; the MM column alone 16 px (favicon: a single M on the bar at 16 px, the full column from 32 px).
- **Clear space:** the height of the gutter bar × 4 on all sides.

### 7.2 App icon, "MM column"

- **Cinematic rendition:** a `#000000` squircle field; the MM column in a vertical gradient `#F5F5F1` (top) → `#9D9D9A` (bottom); the gutter bar `#FFB547` with a 24 px bloom at 45 %; a tungsten rim light (radial gradient at 30 % centred at 20 %, 15 %); monochrome grain at 2.5 %; a thin horizontal anamorphic streak (1 px, `#FFB547` at 30 %, 60 % of the width) through the bar.
- **Deliverables:** iOS 1024 × 1024 opaque master, iOS 18 dark (transparent background, mark only) and tinted (grayscale) variants through `flutter_launcher_icons` 0.14.4; Android adaptive (108 dp canvas, the mark inside the 66 dp safe circle, ≈ 160 × 188 px at xxxhdpi), Android 13 themed monochrome layer; web `favicon.svg`, `icon-192.png`, `icon-512.png`, `maskable-512.png` (mark inside the 40 %-radius safe zone), `apple-touch-icon` 180 × 180 opaque; the SideStore source `iconURL` and `tintColor` `#FFB547` in `backend/routes/app_distribution.py`.
- **Per-skin icon:** the skin restart swaps the alternate icon (`flutter_dynamic_icon_plus` 1.4.1); the web swaps `<link rel="icon">` to the skin's SVG at load.

### 7.3 Splash

- Native: neutral MM column `#F5F5F1` on `#000000` on both platforms (the launch screen cannot know the skin), `flutter_native_splash` 2.4.8 with the Android 12 icon inside the 192 dp circle and black background. iOS PWA: black `appleWebApp.startupImage` images for every device size so there is never a white flash.
- The first Flutter frame (and the web's server-rendered SVG) redraws the mark pixel-identically, then the logo reveal plays.

### 7.4 Logo reveal, "Projector roll" (cold start 1600 ms; warm start 450 ms)

| t (ms) | Picture | Motion | Sound (if on) | Haptic |
|---|---|---|---|---|
| 0–125 | the neutral mark, black | the mark's grey gradient cross-fades to its Cinematic colours; grain at 0.12 flickers at 12 fps (projector warming) | `sting` starts (motor rattle) | — |
| 125–500 | film gate | two letterbox bars at 2.39:1 slide in from top and bottom (`dur.shot`, `cineOut`); a 24 px `lamp` light band blurred 40 px sweeps the MM column left to right as a gradient mask (`cineInOut`) | | |
| 300–1336 | wordmark letters | the "MANHWA / MANIACS" letters do the §6.1 reveal (13 graphemes, 28 ms stagger, 700 ms each) beside the column | sting body | |
| 820 | the stamp | the MM column scales 1.06 → 1.00 over 167 ms on `ease.snap`; the gutter bar strikes (0 → 100 % lamp in 2f) | 45 Hz sub hit | `stamp` |
| 900–1300 | bloom | a radial `lampGlow` behind the mark rises 0 → 35 %, settles at 18 %; grain settles to 0.07 | shimmer | |
| 1300–1500 | track out | the letters `move.trackOut` (`wdth` 75 → 90, +0.08 em) while fading to 0; the two cue dots flash top-right (§6.3) | Dmaj7 chord | `cue` |
| 1500–1600 | handoff | the MM column flies to its nav slot (Reel Index top-left or the Home top bar) as a shared element (`heroine` 0.7.2 on Flutter; Motion `layoutId` on web) on `spring.dolly`; the letterbox bars open and Home fades up from black | | |

- Warm start (resumed within 4 h, or web after the first navigation in a session): the mark fades in over 200 ms and flies to its slot over 250 ms; no letters, no sound, no haptic.
- Skin restart into Cinematic: the full reveal plays, because that is the moment everything changes.
- Tap anywhere: jumps to the handoff. Reduced motion: 200 ms crossfade of the static lockup, then 200 ms into Home.

---

## 8. Signature moments

1. **Projector roll** (§7.4): the cold start as a studio ident, letterbox, stamp and track-out, handing the mark to the nav.
2. **Reel change** (§6.3): every section switch cues two dots in the corner, dips to black for one frame and cuts; the app feels edited.
3. **Scrub the trailer** (§4.8): Home's hero pins, compresses and parallaxes against the scroll position; scrolling back un-cuts it frame for frame.
4. **Backdrop on dwell** (§4.8, §3.10): resting on any poster for 450 ms dissolves the whole room to that series' art and colour.
5. **Match cut to the title page** (§4.11): the poster becomes the backdrop, the title writes itself, the chapter list dollies up.
6. **The curtain** (§4.13): letterbox bars close to black and open on the first page; the house lights are down.
7. **Previously on** (§5.1.3): a cold open with the title card, the typed "CHAPTER 141 · 12 DAYS AGO", streamed recap lines and a Skip button, then straight through the curtain.
8. **Credits and Up Next** (§4.13): "END OF CHAPTER 142" writes itself, reactions from your crew, and the next chapter waits under a lamp countdown.
9. **Page-tinted room** (§5.4.4): the chrome, gutters and scrubber glow take on the colour of the page you are reading, dissolving as scenes change.
10. **Camera dolly panel view** (§5.4.3): a real camera move between panels that can be caught mid-flight by a finger.
11. **Motion blur and rack focus** (§3.12): fling a rail and the posters smear; let go and they rack into focus.
12. **Spotlight pick** (§4.6): the overhead light narrows onto the chosen profile and carries its avatar into Home.
13. **House lights down** (§4.15): opening listen mode dims the page to black and brings up subtitles over the cover; closing returns exactly to the spoken paragraph.
14. **Ignite** (§5.2.2): the first chapter of the day grows the flame and rolls the streak count, with a weighted haptic.
15. **Your year in reels** (§5.2.3): Wrapped as a trailer with end credits you can share as cards.
16. **Reel lock** (§4.20): a finished download closes its ring, lights a frame in the reel meter and clicks home.
17. **Final cut** (§4.28.2): switching skins burns the frame to white-hot and cuts to black before the restart.
18. **The pitch** (§5.1.4): the AI thinks under an SMPTE countdown and the answers land on "1".
19. **Rating card** (§3.25): 18+ content opens with a film rating card, and enabling it sweeps the red bar across the screen.

---

## 9. Implementation notes (for `stack-decision.md`)

### 9.1 Web (Next.js 16.2.9, React 19.2.4, Tailwind 4, Motion)

- **Folder:** `frontend/src/skins/cinematic/` with `tokens.generated.{css,ts}`, `fonts.ts`, `Shell.tsx` (Reel Index + top bar + transport bar + toast host + palette host), `Splash.tsx` (Projector roll), `motion.ts`, `haptics.ts` (Android `navigator.vibrate` subset), `sounds.ts` (Web Audio), `primitives/*`, `screens/*` keyed by `ScreenId` (`satisfies Record<ScreenId, Screen>`).
- **Dependencies** (from `stack-decision.md`): `motion` 13.4.4 (replaces `framer-motion`; import from `motion/react`), `@base-ui/react` 1.8.0 (Dialog, Menu, ContextMenu, Popover, Tabs, Slider, Switch, primitives restyled), `embla-carousel-react` 8.6.0 (rails), `sonner` 2.0.8 (toasts, unstyled), `lenis` 1.3.26 (Cinematic page scroll only, never inside readers), `@phosphor-icons/react` 2.1.10 (add to `optimizePackageImports`). No other package.
- **Tokens:** `tokens.generated.css` stamps `[data-skin="cinematic"] { --mm-color-canvas: #000000; … --mm-ease-cine-out: cubic-bezier(.16,1,.3,1); --mm-spring-dolly: linear(…); }` with springs pre-sampled into `linear()`; the Tailwind `@theme inline` block maps them to utilities (`bg-canvas`, `text-ink-3`, `ease-cine-out`, `duration-shot`, `rounded-frame`).
- **Fonts:** `next/font/google` for Mona Sans (`axes: ["wdth"]`, `display: "block"`, preload), Geist, Geist Mono, Instrument Serif, Newsreader (`axes: ["opsz"]`), Noto Sans KR / JP / SC (`preload: false`). Only the active skin's `fonts.ts` is imported by its Shell, so Glass fonts never load in Cinematic.
- **Route transitions:** React `<ViewTransition>` with Next `Link transitionTypes` for `reel-change` (dip + cue), `match-cut` (`view-transition-name: poster-<id>` on the poster and the hero), `push`, `pull`, `curtain`. CSS `::view-transition-old/new` animations use the tokens. Readers opt out of the root cross-fade.
- **Scroll-scrubbed Home:** Motion `useScroll({ target: heroRef, offset: ["start start", "end start"] })` + `useTransform` for parallax (0.3), title rise and the pin-and-compress strip; `useVelocity(scrollX)` on rails for `blur.motion` through an SVG `feGaussianBlur stdDeviation="x 0"` filter referenced by `filter: url(#mblur)` (x from velocity).
- **Ambient colour:** `@property --amb-glow / --amb-tint` registered as `<color>`; the series payload's `ambient` sets them on the page root; reader page tint from a 16 × 16 `OffscreenCanvas` sample in a `requestIdleCallback`.
- **Grain:** a 256 × 256 noise PNG tiled at `mix-blend-mode: overlay`, `opacity: 0.07`, stepped through 4 offsets at 12 fps with `steps(4)` so true black stays black.
- **Keyboard:** the existing registry (`lib/keyboard/`) gains the `g`-prefix chords and the new reader keys; the Slate palette is the skin's own screen of the palette registry.
- **Service worker:** the `skin-changed` message and pages-cache purge per `stack-decision.md` §2.5; the offline fallback page is a static HTML file with the §4.30 design inlined.

### 9.2 Flutter (3.44.6, Riverpod, go_router)

- **Folder:** `mobile/lib/skins/cinematic/` with `tokens.g.dart`, `cinematic_skin.dart`, `shell.dart` (transport bar, top bar, toast overlay), `router.dart` (`GoRouter` with `CustomTransitionPage`s for dip, push, pull, match cut, curtain), `primitives/`, `screens/<cluster>/`.
- **Dependencies** (from `stack-decision.md`): `flutter_animate` 4.5.2 (reveals, stagger, focus pull), `motor` 1.1.0 (spring motions with velocity hand-off for sheets, rails, camera), `heroine` 0.7.2 (match cuts with spring flights), `smooth_sheets` 1.2.0 (sheets and detents), `swipeable_page_route` 0.4.8 (full-width back on iOS), `gaimon` 1.5.0 + `haptic_feedback` 0.6.5 (haptics), plus `phosphor_flutter` 2.1.0, `flutter_soloud` 5.1.4 (UI sounds), `flutter_native_splash` 2.4.8, `flutter_launcher_icons` 0.14.4, `flutter_dynamic_icon_plus` 1.4.1, and `audio_service` for listen-mode system controls (§4.15). `stupid_simple_sheet` and `liquid_glass_widgets` belong to Glass and are not imported here. Native plugins land in one isolated commit with a CI iOS dry run.
- **Text:** `CineText` wraps `Text` and applies the role's `FontVariation`s (`wdth`, `wght`, `opsz` for Newsreader), `FontFeature.tabularFigures()` for timecode, `FontFeature.disable('kern')` for revealed headings, and the per-role `TextScaler.clamp` from §2.2.3.
- **Springs:** `SpringDescription.withDurationAndBounce(duration: Duration(milliseconds: t.ms), bounce: 0)` generated per token; gestures hand velocity to `SpringSimulation`. Rails use a custom `ScrollPhysics` whose ballistic simulation is a `SpringSimulation(spring.dolly)` to the nearest poster edge.
- **Motion blur and focus pull:** `ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: v, sigmaY: 0))` on rails while the scroll velocity is over threshold; `Image.frameBuilder` returns the child with `.animate().blurXY(begin: 16, end: 0, duration: 500.ms, curve: cineOut).scaleXY(begin: 1.04, end: 1)` on first frame.
- **Grain and vignette:** one `FragmentProgram` (`shaders/cine_grain.frag`, a hash noise at 12 fps with overlay blend math) painted only on heroes, detail backdrops, the pre-roll, Wrapped and listen mode, never in readers or lists.
- **Ambient:** series payload colours via `TweenAnimationBuilder<Color?>`; reader page tint through `ColorScheme.fromImageProvider(ResizeImage(img, width: 64))` off the UI thread's critical path (triggered after the page settles, at most every 600 ms).
- **Reader engine:** the extracted `features/reader/engine/` (`stack-decision.md` §2.3) supplies state; Cinematic provides `chromeBuilder` (scrim chrome, scrubber, HUDs, credits, Up Next), the panel camera (a `Transform` on the page layer driven by `motor`), and the auto-scroll ticker.
- **Letterbox, curtain and cue dots:** one `CineOverlay` in the shell above the router's `Navigator`, driven by a `cineOverlayProvider`, so any transition can close and open the bars or flash the cue.
- **System UI:** `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)` at rest and `immersiveSticky` in readers; `SystemUiOverlayStyle.light` everywhere; `wakelock_plus` (installed) in readers; `flutter_displaymode` (installed) for refresh rate.
- **Stat card export:** `RepaintBoundary.toImage(pixelRatio: 3)` → PNG → the existing Save to Files export path.

### 9.3 Shared contract additions (`design/contract.json`)

- `ScreenId` additions: `home`, `activity`, `wrapped`, `settingsSkin`, `settingsSocial`, `settingsPlayback`.
- `HapticEvent` names: every row of §2.10. `SoundEvent` names: every row of §2.11.
- Routes: §4.0 table.

### 9.4 Backend additions this concept needs (never `backend/connectors/`)

`reading_profiles.skin` (from `stack-decision.md`); `ambient` on series payloads (Pillow + `colorsys`); `POST /library/recap` (SSE) for "Previously on"; `GET /library/statistics/year`; `GET /reader/panels`; the `/social/*` endpoints and collection sharing in §5.3.1 with opt-in and 18+ filtering applied when serving; optional `GET /home` for server-ordered rails.

### 9.5 Performance budgets (flagship-only, maximum effects, still measured)

- 120 Hz on the owner's devices: no frame over 8.3 ms during rail flings, hero dissolves, the curtain and the panel camera on the Android flagship (checked with the Diagnostics screen) and during Home scroll on desktop Chrome (Performance panel).
- At most one full-screen blur at a time (`blur.dof` or `blur.art`), never stacked.
- Per-letter blur is capped by the 600 ms stagger cap; titles longer than 48 graphemes reveal per word instead of per letter.
- Grain is off in readers and lists; Ken Burns pauses when off-screen (IntersectionObserver / `TickerMode`).

### 9.6 Verification

- Completeness: the `ScreenId` type check (web) and `completeness_test.dart` (Flutter) for every screen in §4 and §5.
- Visual: the Flutter screenshot harness and Playwright screenshots per screen per state (loading, empty, error, offline, content) at 375 × 812, 1024 × 768 and 1920 × 1080, reviewed side by side.
- Motion: a debug overlay (Settings → Diagnostics → "Show motion timings") that logs each named move's start and end frame, so a transition that misses its frame budget is visible.
- Reduced motion: every screen captured with the OS setting on.

---

## Appendix: coverage index

Every inventory element maps to a section of this document.

| Inventory area | Covered in |
|---|---|
| Web chrome G1–G42, shell variants (a)–(g), skip link, mood tint, route cross-fade | §4.0, §3.18, §4.7 (ambience), §2.9.5 |
| Command palette CP1–CP12, keyboard layer and 34 bindings | §4.2, §4.8–§4.29 keys, §4.13, §4.14 |
| Status screens S1–S5, shared states C1–C17 | §4.30, §3.24, §3.1–§3.26, §6.1 |
| Auth, profiles, More, Settings (SG1–SG40), mobile S01–S07, S22, S28–S34 | §4.3–§4.7, §4.27, §4.28 |
| Library LS, LB, BA, SD, CO, CD, RH, RC, ST, SE; mobile S08–S14, S20, S23–S25 | §4.9–§4.12, §4.16, §4.19, §4.21–§4.23, §5.1.4, §5.2 |
| Sources and search; mobile S16–S18 | §4.16–§4.18, §4.11, §4.12 |
| Manga reader RD1–RD42; mobile S15, S19, reader internals 6a | §4.13, §5.4 |
| Novels NS, NB, NR, NT; mobile S26, N1–N4, internals 6b | §4.12, §4.14, §4.15 |
| Updates, downloads DL / DP, bookmarks BM, OCR OC, admin AS, backup BK, members; mobile S21, S27, download states 6c | §4.19, §4.20, §4.23, §4.26, §4.28.10–§4.28.12, §4.29 |
| Mobile global G1–G14 (bottom nav, mood, switcher, 18+ gate, reading mode, auth, setup, What's New, app update, lifecycle, system UI, haptics, shared sheets M1–M9, primitives) | §3.18, §4.7, §4.6, §3.25, §4.31, §4.1, §4.3, §4.20, §4.13, §2.10, §3 |
| Capabilities §8–§26 (home strips, AI, stats, collections, tags, reader, history, bookmarks, sources, search, novels and TTS, OCR, updates, backup, distribution, downloads, reader flows, not built) | §5, §4 |
| Owner decisions: two skins and restart, dark AMOLED, new brand, 4 new features, 2 signature animations, haptics, sounds off by default, full desktop web, flagship-only with reduced motion | §4.28.2, §2.1, §7, §5, §6, §2.10, §2.11, §4.0, §2.9.8, §9.5 |
