# Cinematic concept 3: "Programme" (editorial-first)

Designer 3 of 3 for the Cinematic skin. Angle: **typography, rhythm and the grid drive every layout, the way a film magazine or a festival programme is set.** The art is placed like stills in a spread; the words are set like a feature; the grid is visible, and at the one big moment (entering the reader) the grid itself becomes the shutter.

Binding inputs read for this concept: `inventory/00-decisions.md`, `inventory/web.md`, `inventory/mobile.md`, `inventory/capabilities.md`, `research/*.md`, `stack-decision.md`, `00-baseline.md`. Dark only on AMOLED `#000000`, restart on skin switch, flagship-only effects, OS reduced motion honoured, UI sounds off by default.

Conventions used throughout:

- **px** are logical pixels (1 CSS px = 1 Flutter logical pixel, `stack-decision.md` §2.1). Letter spacing is in em; the generator converts it for Dart.
- **Breakpoints.** `phone` < 600, `tablet` 600–1023, `desktop` 1024–1439, `wide` 1440–1919, `cinema` ≥ 1920. The web uses the phone frame below 768 px and the desktop frame from 768 px (768–1023 is the desktop frame with the collapsed sidebar, called the *spine*). The Flutter app uses the phone frame at every width; on tablets it lays out on the tablet grid.
- **Platforms.** "Phone" means iOS app, Android app and mobile web together; a *Platform deltas* line in each screen lists where they differ. "Desktop" means desktop web.
- Token names are written `color.spot`, `type.section`, `space.4`, `ease.settle`, `dur.line`, `spring.sheet` and haptic event names such as `follow.add`. They are the keys of `design/tokens/cinematic.json` (`stack-decision.md` §2.1); curves, durations and springs live under `motion` in that file (§9.1).
- Inventory IDs (web `LB14`, mobile `S21 #19`, keys `K40`) are cited so the contract can be ticked off against both inventories.

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

Programme treats ManhwaManiacs as the magazine you pick up in a cinema foyer on the way to your seat: black stock, bone-white ink, one spot colour, and pages set by an art director who trusts type. Every screen stands on a visible grid (4 columns on a phone, 8 on a tablet, 12 on a desktop) and a 4 px baseline, so headings, captions and covers all land on the same lines and the eye reads each screen like a spread. Hierarchy comes from contrast in the type rather than from boxes: a razor-sharp Didone (Bodoni Moda) for titles and numbers, a condensed grotesk (Archivo) for credits, kickers and controls, a reading serif (Newsreader) for everything longer than a line, and a mono (IBM Plex Mono) for folios, chapters and timecodes. Rules replace cards. Covers sit square-cornered on the grid or bleed off the page like film stills, never floating in rounded tiles. The only accent is Subtitle Yellow `#F4D03F`, the colour of cinema subtitles and of a magazine's second ink, used a few pixels at a time: a rule under the active tab, a folio, a highlighter stroke through the sentence being read aloud. Motion is typesetting and editing: section heads are set letter by letter out of a blur, the front-page headline is typed at 50 ms a character, screens cut and dissolve, covers match-cut into their feature, and the one time you walk into the reader the page's own columns close like a shutter and open on page one. Nothing springs, bounces, frosts or floats; that is the other skin. This one reads.

---

## 2. Tokens

All values below are the source for `design/tokens/cinematic.json`. §9.1 shows the file shape.

### 2.1 Colour

#### 2.1.1 Neutral ramp: paper and ink

Solid values only (no alpha on text), so every contrast figure is exact. Contrast is WCAG 2.x against `#000000`.

| Token | Hex | On #000 | Role |
|---|---|---|---|
| `color.paper.0` | `#000000` | n/a | The page. Every screen background, the reader canvas, sheets' barrier base. AMOLED off. |
| `color.paper.1` | `#0B0B0A` | n/a | Plates: poster placeholders, image wells, inset areas, the reader's *Ink* background |
| `color.paper.2` | `#121211` | n/a | Sheets, menus, popovers, the command palette, toasts' band |
| `color.paper.3` | `#1A1A18` | n/a | Dialogs, pressed rows, input wells when a filled field is needed, the reader's *Slate* background |
| `color.paper.4` | `#232220` | n/a | Hover fill on rows and menu items, selected row fill |
| `color.rule.1` | `#2B2A27` | 1.5:1 | Hairlines: row dividers, column rules, section rules |
| `color.rule.2` | `#3D3C38` | 2.0:1 | Strong rules: sheet top edge, slider tracks, unfocused input underline |
| `color.ink.30` | `#4D4B47` | 2.4:1 | Disabled text and glyphs only, never information |
| `color.ink.45` | `#7A7770` | 4.7:1 | Captions, metadata, inactive tabs and nav, placeholders in large type |
| `color.ink.60` | `#9A978F` | 7.2:1 | Secondary text, decks, synopsis on dense screens |
| `color.ink.80` | `#C9C6BE` | 12.3:1 | Long body passages on desktop (synopsis, recaps), pressed primary button fill |
| `color.ink.100` | `#F3F0E8` | 18.4:1 | Primary text, headlines, primary button fill, focus rings. "Bone": a warm projector white, never `#FFFFFF` |

#### 2.1.2 Accent: the spot ink

| Token | Value | On #000 | Text on it | Role |
|---|---|---|---|---|
| `color.spot` | `#F4D03F` "Subtitle Yellow" | 13.5:1 | `#000000` 13.5:1 | The only brand hue. Active tab and nav rule, progress fills, NEW badge, typing caret, input focus underline, selected-chip underline, streak flame, the lit intersection of the monogram, count badges. A mark, never a surface larger than a badge. |
| `color.spot.press` | `#D9B62C` | 10.7:1 | `#000000` | Pressed state of any spot-filled mark |
| `color.spot.wash` | `rgba(244,208,63,0.16)` | n/a | ink on top | Highlighter band: spoken sentence in Listen mode, matched words in dialogue search, the go-to target row in contents |
| `color.spot.glow` | `rgba(244,208,63,0.35)` | n/a | n/a | Bloom behind the masthead in the splash and the streak flame. Never behind UI chrome. |

Why yellow: subtitles are the most cinematic typography there is, and the colour has the highest luminance contrast of any hue on black (13.5:1), so it can work at 2 px. It is the classic second ink of film-magazine covers. Nothing in the reference apps owns it (Netflix red, Crunchyroll orange, Prime blue, HBO purple, PlayStation blue), and it stays clear of the error red below.

#### 2.1.3 Semantic roles

| Token | Value | On #000 | Use |
|---|---|---|---|
| `color.proof` | `#FF5B4A` "Proof red" | 6.9:1 | Errors, destructive actions, the 18+ certificate, failed downloads, dead sources. Named after the proofreader's pen: errors are shown as corrections, with a margin mark. |
| `color.proof.wash` | `rgba(255,91,74,0.12)` | n/a | Background of a destructive confirm area and of error rows |
| `color.set` | `#57D68D` | 11.4:1 | Success: downloaded, synced, saved, healthy source ("set" as in type that is set and approved) |
| `color.note` | `color.spot` + the kicker `NOTE` | 13.5:1 | Cautions (paused downloads, overdue checker, stale catalogue). Always carries a text kicker, so it never relies on hue alone. |
| `color.info` | `#9CC8FF` | 12.1:1 | Rare informational marks: "position approximate", demoted source |
| Health: ok / failing / dead / unknown / demoted | `set` / `spot` / `proof` / `ink.45` / `ink.60` + strike-through label | as above | 6 × 6 px square marks plus a label everywhere a health state appears |

Rule: text on a `spot` or `proof` fill is always `#000000`. Bone on spot is 1.4:1 and fails.

#### 2.1.4 Scrims (exact stops)

Long fades use the eased scrim curve (Andreas Larsen), 13 stops, running from transparent to the end colour:

| Stop | 0% | 1.8% | 4.8% | 9% | 13.9% | 19.8% | 27% | 35% | 43.5% | 53% | 66% | 81% | 100% |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Alpha | 0 | .002 | .008 | .021 | .042 | .075 | .126 | .194 | .278 | .382 | .541 | .738 | 1 |

| Token | Geometry | Stops | Where |
|---|---|---|---|
| `scrim.gutter` | Horizontal, across the 2 grid columns where art meets type in a spread | Eased stops, end `#000` at the text side | Tonight cover spread, series feature spread, Annual spreads (desktop) |
| `scrim.foot` | Bottom 60 % of a full-bleed phone hero, top → bottom | Eased stops, end colour `ambient.tint` | Tonight phone cover, series phone hero |
| `scrim.head` | Top 120 px (desktop) / safe area + 88 px (phone) | `#000` .86 at 0 %, .52 at 45 %, 0 at 100 % | Running head over art, reader top chrome |
| `scrim.sole` | Bottom 128 px + safe area, bottom → top | `#000` .90 at 0 %, .60 at 40 %, 0 at 100 % | Reader folio bar, Listen full player transport |
| `scrim.modal` | Full screen | `rgba(0,0,0,0.78)` flat | Barrier behind sheets and dialogs. No blur, ever. |
| `scrim.rail-end` | 48 px at each rail end (desktop) | `#000` 1 → 0 linear (short enough not to band) | Under rail paddles |
| `scrim.vignette` | Full frame, radial | `radial-gradient(120% 90% at 50% 40%, rgb(0 0 0/0) 60%, rgb(0 0 0/.45) 100%)` | Hero art, Annual pages, recap title card |

Flutter uses `LinearGradient(stops: _scrimStops, colors: [for (a in _scrimAlpha) end.withValues(alpha: a)])`; a 77° angle is never used in this skin (spreads are strictly horizontal, on the grid).

#### 2.1.5 Ambient colour: the "issue colour" of each series

Each series gets three colours computed once from its cover on the backend, next to cover resizing in `backend/services/image_resize.py`, cached with the cover and served as `ambient: {duo, tint, ink}` on every series payload (library rows, source series, world items when available, continue-reading rows). Nothing is computed on a phone.

Extraction rule (Pillow 12.3.0, already installed, plus stdlib `colorsys`):

1. Resize the cover to 48 × 48 (bilinear) and quantize to 8 colours with median cut.
2. For each swatch compute HLS. Ignore swatches with L < 0.08 or L > 0.94 (paper and ink). Score = `count × (0.35 + S)`. The highest score is the seed hue `h` and saturation `s`.
3. Derive:

| Role | Rule | Where it appears |
|---|---|---|
| `ambient.duo` | `h`, L 0.62, S = clamp(s, 0.45, 0.90) | The highlight colour of the **duotone** treatment (black → duo). Duotone is this skin's signature image treatment: series backdrops in spreads, collection plates, source hubs, Annual pages, recap title cards, Circle letters. Also the poster hover bloom. |
| `ambient.tint` | `h`, L 0.06, S ≤ 0.35 | Page spill: the colour a phone hero fades into and the 30 vh wash at the top of a feature page. Near black, so the room looks lit by the art. |
| `ambient.ink` | `h`, L 0.78, S = clamp(s, 0.35, 0.70); raise L by 0.03 until contrast on `#000` ≥ 7:1 | The series' **issue colour**: its kicker line and chapter folios on its own feature page only. Interactive marks (tabs, progress, focus) stay `spot` everywhere. |

Fallbacks (missing cover, greyscale cover): duo `#B8B2A4`, tint `#0E0D0B`, ink `#F3F0E8`.

Duotone implementation (one matrix, both clients): luminance `Y = 0.2126R + 0.7152G + 0.0722B`, output = `shadow + Y × (duo − shadow)` with shadow `#000000`. Web: an SVG `<filter>` with `feColorMatrix type="matrix"` whose R, G, B rows are `[dr·0.2126, dr·0.7152, dr·0.0722, 0, 0]` (dr = duo red / 255, likewise for green and blue), referenced as `filter: url(#duo-<id>)`, one filter per visible duo. Flutter: `ColorFiltered(colorFilter: ColorFilter.matrix([...same 20 numbers...]))`.

**Per-page tint (reader, new feature 4).** The image proxy computes one hex per page (16 × 16 downsample, most saturated pixel with L 0.1–0.9, else the mean) the first time it serves the page, caches it with the page's ETag, and the manifest gains `pages[].tint`. Downloaded chapters store their manifest, so the tint works offline with no client-side sampling. The reader dissolves chrome to it (§5.4.4).

**Animating colour.** Web registers `@property --amb-duo`, `--amb-tint`, `--amb-ink`, `--page-tint` (`syntax: "<color>"`) and transitions them 800 ms `motion.turn`. Flutter wraps the affected layers in `TweenAnimationBuilder<Color?>` with the same duration and curve.

#### 2.1.6 Special palettes

**Mood grades** (profile `mood`, the 7 values in capabilities §5). Cinematic-3 reads mood as a *colour grade* of the page head: a 30 vh gradient from the grade colour to `#000` at the top of Tonight, Library, Discover and Index. Readers, auth and the picker stay ungraded.

| Mood | Grade | Default soundscape (§5.4.2) |
|---|---|---|
| default | none | Projector room |
| romantic | `#1A0B10` | Rain on glass |
| action | `#1A0D08` | Low drone |
| comedy | `#17130A` | Café |
| horror | `#0F0A0D` | Night wind |
| slice_of_life | `#0F120C` | Afternoon park |
| fantasy | `#120C18` | Temple bells |

**Speaker tints** (novel dialogue attribution, capabilities §19.2). Ordered; the busiest speaker takes slot 1. Applied as a 2 px underline at 70 % plus a 12 % background under the quoted run; the text itself keeps the stock ink. Narration is never tinted.

| Slot | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| Hue | `#7CC4FF` sky | `#FF8A7A` coral | `#9BE08A` sage | `#D6A3FF` lilac | `#FFC266` marigold | `#6FE3D6` teal | `#FF9FCB` pink | `#C9B38A` sand | `#A6B4FF` periwinkle | `#E0E0A0` straw |

Slots 11+ reuse 1–10 with a dotted underline instead of a solid one.

**Paper stocks** (novel reader pages, dark only by decision). Contrast figures from `research/reader-ux.md` §4.8.

| Stock | Page | Ink | Contrast | Muted | Contrast | Maps stored K40 value |
|---|---|---|---|---|---|---|
| Nitrate (default) | `#000000` | `#D9D6D0` | 14.48:1 | `#8A877F` | 5.85:1 | `black`, `site`, `app`, null |
| Ink | `#0B0B0C` | `#E6E3DD` | 15.36:1 | `#8F8C86` | 5.87:1 | `paper`, `soft-grey` |
| Sepia Night | `#15110C` | `#E8D8BE` | 13.42:1 | `#9C8E78` | 5.87:1 | `sepia`, `cream`, `dusk` |
| Dusk | `#0D1117` | `#D3DAE3` | 13.43:1 | `#8590A0` | 5.85:1 | `midnight`, `solarized-dark`, `solarized-light` |
| Moss | `#0E130F` | `#D5DECF` | 13.57:1 | `#879384` | 5.84:1 | `forest` |
| Rosewood | `#160E10` | `#EBD5D8` | 13.62:1 | `#A08A8E` | 5.90:1 | `rose-pine`, `dawn` |

**Manga reader grounds** (the colour around and between pages): Black `#000000` (default), Ink `#0B0B0A`, Slate `#1A1A18`. Migration of mobile K11: `dark` → Ink, `black` → Black, `white` → Slate. Colour filters stay Normal / Sepia / Grey (K12).

**Chart palette** (The Numbers, The Annual): series 1 `ink.100`, series 2 `ink.45` (dotted line), highlight `spot`, grid `rule.1`, heat levels (4) `rgba(243,240,232, .10 / .28 / .52 / .86)`, today's cell outlined 1 px `spot`.

### 2.2 Typography

#### 2.2.1 Families (all from Google Fonts, all SIL Open Font License 1.1)

| Role | Family | Axes and styles used | Designer | Why |
|---|---|---|---|---|
| **Display**: covers, mastheads, headlines, section heads (H3), numerals, pull quotes, drop caps | **Bodoni Moda** | `opsz` 6–96 (set = size, capped at 96), `wght` 500–900, Roman + Italic | Owen Earl (indestructible type\*) | A Didone with an optical-size axis, so hairlines stay intact at 24 px and turn razor-thin at 120 px. High contrast on AMOLED is the "film magazine" look. The un-blur of the letter reveal shows its hairlines arriving last. |
| **Grotesk**: UI, buttons, labels, nav, kickers, credits | **Archivo** | `wdth` 62–125 (used 62–100), `wght` 100–900 (used 450–700), Roman | Omnibus-Type | One variable file covers credits (condensed caps at `wdth` 62–75) and legible UI text (`wdth` 100). |
| **Text**: decks, synopsis, recaps, notices, novel body (default face) | **Newsreader** | `opsz` 6–72 (set = size), `wght` 380–600, Roman + Italic | Production Type | Designed for long reading on screens; the italic carries pull quotes and captions. |
| **Folio**: chapter numbers, pages, timecodes, counts, sizes, keycaps | **IBM Plex Mono** | 400, 500, 600 (static) | Mike Abbink, Bold Monday | Tabular by nature; reads like a projectionist's counter or a page folio. |
| CJK fallback (alternate titles) | **Noto Serif KR / JP / SC** for display, **Noto Sans KR / JP / SC** for UI | `wght` | Google | Web only (`preload: false`); Flutter uses the system CJK faces. CJK display titles drop italic and tracking and render at `wght` 700 one size down. |

Delivery. Web: `next/font/google` (`Bodoni_Moda({ axes: ["opsz"], style: ["normal","italic"], display: "block", preload: true })`, `Archivo({ axes: ["wdth"], display: "swap" })`, `Newsreader({ axes: ["opsz"], style: ["normal","italic"], display: "swap" })`, `IBM_Plex_Mono({ weight: ["400","500","600"], display: "swap" })`; all four are present in next 16.2.9's `font-data.json`). Bodoni Moda uses `display: "block"` because a swap in the middle of a letter reveal breaks it. Flutter: bundle the variable TTFs from `github.com/google/fonts/tree/main/ofl/{bodonimoda,archivo,newsreader,ibmplexmono}` as assets, set both `fontWeight` and `FontVariation('wght', …)`, and pass `FontVariation('opsz', min(size, 96))` for Bodoni Moda and Newsreader and `FontVariation('wdth', …)` for Archivo. Ship each `OFL.txt` through `LicenseRegistry.addLicense`.

Global type rules:
- Figures: `lnum` (lining) in headlines and numerals, `onum` (old-style) inside Newsreader running text, `tnum` on every number that updates in place (Plex Mono is already tabular).
- Revealed headings set `font-kerning: none` (Flutter `FontFeature.disable('kern')`) so split and unsplit text measure identically.
- Headlines and decks use `text-wrap: balance`; body uses `text-wrap: pretty` (web). Flutter uses `TextWidthBasis.longestLine` plus a column max width.
- Headline titles are **sentence case, never all caps**. Caps belong to kickers, credits, nav and badges (Archivo), so a screen always shows one serif voice and one caps voice.
- Long series titles in `cover`: > 24 graphemes step down one role (`masthead` size), > 40 graphemes step down two (`headline` size).

#### 2.2.2 Scale per breakpoint

Sizes are px size / line height. Every line height is a multiple of the 4 px baseline.

| Role | Face and settings | Phone | Tablet | Desktop | Wide / cinema | Tracking | Case |
|---|---|---|---|---|---|---|---|
| `type.cover` | Bodoni Moda Roman, opsz 96, wght 700 | 44/44 | 64/60 | 88/84 | 120/112 | −0.040em | Sentence |
| `type.masthead` | Bodoni Moda Roman, opsz 96, wght 800 | 40/40 | 56/56 | 72/68 | 88/84 | −0.035em | Sentence |
| `type.headline` | Bodoni Moda Roman, opsz 72, wght 700 | 32/36 | 44/48 | 56/56 | 64/64 | −0.030em | Sentence |
| `type.section` (H3, letter reveal) | Bodoni Moda Italic, opsz 48, wght 600 | 24/28 | 28/32 | 32/36 | 36/40 | −0.020em | Sentence |
| `type.subhead` | Bodoni Moda Roman, opsz 28, wght 600 | 20/24 | 22/28 | 24/28 | 24/28 | −0.010em | Sentence |
| `type.numeral` | Bodoni Moda Roman, opsz 96, wght 900, `lnum` | 56/56 | 72/72 | 96/88 | 120/112 | −0.030em | n/a |
| `type.pull` | Bodoni Moda Italic, opsz 72, wght 500 | 24/32 | 28/36 | 36/44 | 40/48 | −0.015em | Sentence |
| `type.field` (search, ask, big inputs) | Bodoni Moda Italic, opsz 48, wght 500 | 28/36 | 32/40 | 36/44 | 40/48 | −0.015em | Sentence |
| `type.deck` | Newsreader, opsz 20, wght 400 | 17/24 | 18/28 | 20/28 | 22/32 | 0 | Sentence |
| `type.body` | Newsreader, opsz 16, wght 400 | 16/24 | 16/24 | 17/28 | 17/28 | 0 | Sentence |
| `type.body.italic` | Newsreader Italic, as body | 16/24 | 16/24 | 17/28 | 17/28 | 0 | Sentence |
| `type.title` (card and row titles) | Archivo, wdth 100, wght 600 | 15/20 | 15/20 | 16/20 | 16/20 | −0.005em | Sentence |
| `type.ui` | Archivo, wdth 100, wght 500 | 15/20 | 15/20 | 14/20 | 14/20 | 0 | Sentence |
| `type.label` (buttons) | Archivo, wdth 100, wght 650 | 15/20 | 15/20 | 14/20 | 15/20 | +0.005em | Sentence |
| `type.kicker` | Archivo, wdth 62, wght 700 | 11/16 | 12/16 | 12/16 | 13/16 | +0.16em | UPPER |
| `type.credit` | Archivo, wdth 70; label wght 500 `ink.45`, value wght 700 `ink.100` | 12/16 | 12/16 | 12/16 | 13/16 | +0.08em | UPPER |
| `type.nav` | Archivo, wdth 75, wght 600 | 10/12 (tab bar) | 12/16 | 13/16 | 13/16 | +0.12em | UPPER |
| `type.caption` | Archivo, wdth 90, wght 450 | 13/16 | 13/16 | 13/16 | 13/16 | +0.005em | Sentence |
| `type.folio` | IBM Plex Mono 500 | 12/16 | 12/16 | 12/16 | 13/16 | +0.02em | as data |
| `type.folio.lg` | IBM Plex Mono 500 | 15/20 | 15/20 | 15/20 | 16/20 | 0 | as data |
| `type.micro` (badges) | Archivo, wdth 62, wght 700 | 10/12 | 10/12 | 10/12 | 11/12 | +0.12em | UPPER |
| `type.dropcap` | Bodoni Moda Roman, opsz 96, wght 800 | 3 lines of the body it opens (72 px on 24 px leading) | same | 3 lines (84 px on 28 px) | same | −0.02em | n/a |

Web formulas for the fluid display roles (interpolating phone → wide between 375 px and 1600 px viewports): `cover: clamp(2.75rem, 1.296rem + 6.2vw, 7.5rem)`, `masthead: clamp(2.5rem, 1.582rem + 3.92vw, 5.5rem)`, `headline: clamp(2rem, 1.39rem + 2.61vw, 4rem)`, `section: clamp(1.5rem, 1.27rem + 0.98vw, 2.25rem)`, `numeral: clamp(3.5rem, 2.276rem + 5.22vw, 7.5rem)`. Flutter uses the table's per-breakpoint values; the web interpolates between the phone and wide values. Line heights for fluid roles are unitless (cover 0.93, the others 1.0). Their blocks keep the 4 px rhythm through the `Measure` wrapper (§3.28), which rounds a display block's rendered height up to the next multiple of 4 px with a bottom margin, so the text after it lands back on the baseline.

All other sizes are authored in `rem` (px / 16) so the browser's font-size preference scales UI text.

#### 2.2.3 Mobile text scale (iOS Dynamic Type, Android font scale)

Flutter reads `MediaQuery.textScalerOf(context)` (Dynamic Type on iOS; the non-linear font scale on Android 14+). Each role clamps it with `TextScaler.clamp(maxScaleFactor: cap)`:

| Role group | Cap | Example at 1.0 → 1.3 → 2.0 (system) |
|---|---|---|
| Display: `cover`, `masthead`, `headline`, `numeral` | 1.15 | cover 44 → 50.6 → 50.6 px |
| `section`, `subhead`, `pull`, `field` | 1.30 | section 24 → 31.2 → 31.2 px |
| Reading and UI: `deck`, `body`, `title`, `ui`, `label`, `caption`, `folio`, `folio.lg` | 2.00 | body 16 → 20.8 → 32 px; caption 13 → 16.9 → 26 px |
| Caps: `kicker`, `credit`, `nav`, `micro` | 1.50 | kicker 11 → 14.3 → 16.5 px; at ≥ 1.3 these switch from `wdth` 62–75 to `wdth` 100 so wide caps stay legible |

Layout reflow by scale factor (all platforms, web included via the root font size):
- ≥ 1.3: rails show 2.3 posters on phones instead of 3.2; poster captions allow 2 lines; credits blocks become a single column; list rows grow to their content height (min 56).
- ≥ 1.5: split buttons (§3.1) stack label over folio; the tab bar keeps its labels at the 1.5 cap and drops the icons; the reader folio bar moves the time-left caption to a second line.
- ≥ 2.0: sheets open at the full detent; two-column settings rows become one column; the novel reader's type steps allow up to 40 px body text independent of this cap (its own setting).

Web desktop honours browser zoom; nothing uses `vw` for non-display text.

### 2.3 Spacing and the grid

#### 2.3.1 Units

4 px base unit, 4 px baseline.

| Token | px | Typical use |
|---|---|---|
| `space.0` | 0 | Posters in a poster wall touch their gap only |
| `space.1` | 4 | Badge padding, folio to label |
| `space.2` | 8 | Icon to label, stacked captions |
| `space.3` | 12 | Rail header to posters, row inner padding (phone) |
| `space.4` | 16 | Phone margin, row inner padding (desktop), control gaps |
| `space.5` | 20 | Button horizontal padding |
| `space.6` | 24 | Paragraph gap in notices, card internal rhythm |
| `space.8` | 32 | Block gap inside a section, masthead bottom margin (phone) |
| `space.10` | 40 | Section gap (phone) |
| `space.12` | 48 | Desktop margin, masthead bottom margin (desktop) |
| `space.16` | 64 | Section gap (desktop) |
| `space.20` | 80 | Spread internal padding (desktop) |
| `space.24` | 96 | Chapter-end credits padding |
| `space.32` | 128 | Wide-screen masthead top padding |

#### 2.3.2 The grid

| Breakpoint | Columns | Margin | Gutter | Content max | Notes |
|---|---|---|---|---|---|
| phone (< 600) | 4 | 16 | 12 | full | Mobile web below 768 uses this grid up to 599 px |
| tablet (600–1023) | 8 | 32 | 16 | full | Web 600–767 still uses the phone frame on this grid |
| desktop (1024–1439) | 12 | 48 | 24 | full | Sidebar takes its own width; the grid lives in the remaining canvas |
| wide (1440–1919) | 12 | 72 | 24 | 1760 | |
| cinema (≥ 1920) | 12 | 96 | 32 | 1760, centred | Margins grow beyond 1760 |

Rules:
- **Everything snaps to columns.** A poster rail's visible count is chosen so posters align with column starts at rest (phone 3.2 posters: 3 posters span the 4 columns with the 4th peeking; desktop 6.25).
- **Spreads.** A spread is a 12-column composition: text on 5 columns, art on 7 columns bleeding off the right edge (desktop), with `scrim.gutter` over the 2 columns where they meet. On phones a spread becomes a stacked "cover + text" block.
- **Rhythm.** Vertical gaps are multiples of 8. A section is: 1 px `rule.1` section rule → 12 px → header row → 12 px → content → 64 px (desktop) / 40 px (phone) to the next section rule.
- **Measure.** Decks and synopsis max 62ch; recaps 58ch; notices 48ch; novel measure 48–88ch (reader setting).
- **Debug overlay.** In development builds `mod+shift+g` (web) and a Diagnostics toggle (Flutter) draw the columns at 6 % spot and the baseline at 4 % bone. Designers review every screen with it on.

### 2.4 Radius

| Token | Value | Use |
|---|---|---|
| `radius.0` | 0 | Everything: posters, covers, buttons, inputs, chips, cards, sheets, dialogs, menus, toasts, tiles, progress bars, toggles, the reader's pages |
| `radius.round` | 50 % | Only: avatars, radio dots, the Listen play button, the leader-sweep dial, the scroll-to-top dot on phones |

There is no third radius. A rounded rectangle anywhere in this skin is a bug.

### 2.5 Elevation: paper stock, not shadow

Shadows are invisible on `#000`, and Programme does not use glow for depth. Layers are paper stocks separated by rules.

| Level | Surface | Edge | Use |
|---|---|---|---|
| 0 | `paper.0` | none | The page |
| 1 | `paper.1` | none | Plates and wells inside the page |
| 2 | `paper.2` | 1 px `rule.2` on the edge that faces the page (top of a sheet, all four sides of a menu) | Sheets, menus, popovers, palette, toasts |
| 3 | `paper.3` | 1 px `ink.30` all round | Dialogs (always over `scrim.modal`) |
| Focus light | n/a | 2 px `ink.100` outline, 2 px offset | Keyboard focus on anything |
| Art light | n/a | `0 0 48px -16px ambient.duo` at 60 % | Poster hover and focus only: the art throws its own light. The only glow in the skin besides the splash bloom and the streak flame. |

### 2.6 Blur

No `backdrop-filter` anywhere. Blur is applied to images and to letters, transiently:

| Token | Value | Use |
|---|---|---|
| `blur.letter` | 8 px → 0 | Per-letter heading reveal (§6.1) |
| `blur.rack` | 14 px → 0 | Image rack-focus on first load |
| `blur.bleed` | 56 px, static | The cover copy that fills the art columns of a spread beside a portrait cover (covers are 720 px max, so a spread never shows an upscaled sharp cover) |
| `blur.card` | 24 px, static | Background of the next-chapter card and the Listen full player (on a duotone copy) |
| `blur.defocus` | 0 → 6 px | "Stop the press" skin-switch outgoing rack (§4.30.3) |

### 2.7 Borders and rules

| Token | Spec | Use |
|---|---|---|
| `rule.hair` | 1 px `rule.1` | Row dividers, section rules, column rules on desktop two-pane layouts |
| `rule.strong` | 1 px `rule.2` | Sheet top edge, unfocused input underline, slider track |
| `rule.ink` | 1 px `ink.100` | Secondary button outline, checkbox outline when checked |
| `rule.heavy` | 3 px `ink.100` | Above notices, above stat blocks, under the phone masthead |
| `rule.oxford` | 3 px `ink.100` + 2 px gap + 1 px `ink.100` | Under the Tonight masthead and page mastheads on desktop; under the wordmark |
| `rule.spot` | 2 px `spot` | Active tab and nav, input focus, selected chip, progress fill |
| `rule.proof` | 2 px `proof` | Input in error, destructive confirm area's left edge |
| Dot leaders | `·` at 0.5em intervals in `ink.30`, `type.folio` | Contents lists, cast lists, the Index page, settings rows with values |

### 2.8 Iconography

- **Set:** Phosphor on both platforms (`@phosphor-icons/react` 2.1.10, MIT; `phosphor_flutter` 2.1.0, MIT; 1,512 icons at parity, `research/brand.md` §8).
- **Weights for this skin:** **Light** (12/256 stroke, 1.125 px at 24 px) as the default at 24 px, because its hairline matches the Didone hairlines; **Regular** at 20 px and below (Light gets too thin); **Fill** for the active tab and nav item, selected toggles such as favourite, and the streak flame. Never Bold or Duotone (Duotone is Glass's voice).
- **Sizes:** 16 (inline in captions), 20 (buttons, rows), 24 (bars, tabs), 32 (notices, empty states; Light). Hit areas are always 44 × 44 (iOS, web) or 48 × 48 (Android) through padding.
- **Words first.** Navigation always pairs icons with labels. Icon-only buttons appear only in reader chrome, row trailing actions and the running head, and always carry a tooltip (web `title` plus `aria-label`; Flutter `Tooltip` plus `Semantics`).
- **Core map** (Phosphor names): back `arrow-left`, close `x`, search `magnifying-glass`, Tonight `moon-stars`, Library `books`, Discover `compass`, Downloads `download-simple`, Index `list-numbers`, Updates `bell-simple`, Sources `globe-simple`, Collections `stack-simple`, History `clock-counter-clockwise`, Bookmarks `bookmark-simple`, The Numbers `chart-bar`, Circle `users-three`, Settings `gear-six`, Status `pulse`, Picks `sparkle`, reader settings `sliders-horizontal`, type `text-aa`, contents `list-numbers`, listen `headphones`, play `play`, pause `pause`, previous chapter `skip-back`, next chapter `skip-forward`, download `cloud-arrow-down`, downloaded `check-square`, pin `push-pin`, favourite `star`, follow `plus`, following `check`, notify `bell-ringing`, share `export`, recommend `paper-plane-tilt`, filter `funnel-simple`, sort `arrows-down-up`, grid `squares-four`, list `rows`, select `check-square-offset`, delete `trash-simple`, edit `pencil-simple-line`, overflow `dots-three`, fullscreen `corners-out` / `corners-in`, zoom `magnifying-glass-plus` / `-minus`, brightness `sun-dim`, warmth `thermometer-simple`, offline `wifi-slash`, refresh `arrow-clockwise`, external `arrow-square-out`, soundscape `waveform`, auto-scroll `play` with the `strip-scroll` custom glyph, flame `flame`.
- **Custom glyphs (8)**, drawn on Phosphor's 256 grid in Light, Regular and Fill: `mm-mark` (the monogram, §7.2), `strip-scroll` (a webtoon strip with a down chevron), `panel-focus` (a panel in corner brackets, guided view), `bubble-search` (speech bubble with a magnifier, dialogue search), `certificate-18` (a square seal with "18", the 18+ mark), `voice-31` (`user-sound` with a stacked badge, the voice cast), `annual` (a folio "No." over a rule, The Annual), `highlighter` (a chisel marker, follow-along settings). Web: React components from the SVGs. Flutter: one TTF built with `fantasticon` (npm, MIT, build-time only) plus a `const IconData` class.

### 2.9 Motion

#### 2.9.1 Principles

1. **Type moves; layout holds.** Letters are set, headlines are typed, rules are drawn. Grids, cards and rows do not slide around, grow or bounce. A hovered poster zooms its image *inside a fixed frame*; the frame never grows.
2. **Edit, don't animate.** Screens change with cuts, dissolves and match cuts. The one theatrical transition (the column wipe into the reader) uses the grid itself.
3. **Reading order.** Entrances run left to right, top to bottom, the way the eye scans a page.
4. **Decisive in, quiet out.** Entrances use `settle`. Exits use `lift` at 0.7 × the entrance duration.
5. **No springs in timed motion.** Springs exist only to finish a finger's gesture, always critically damped (bounce 0).

#### 2.9.2 Durations

| Token | ms | Use |
|---|---|---|
| `dur.cut` | 0 | Same-context swaps: filter, sort, density, tab content |
| `dur.tick` | 80 | Pressed states, knob squash, folio digit roll step |
| `dur.beat` | 160 | Hover colour, chip underline, toast in, chrome out |
| `dur.line` | 240 | Chrome in, input underline draw, dip-to-black in, sheet barrier |
| `dur.column` | 320 | Tab and nav rule slide, dialog insert, sidebar width, panel slide |
| `dur.spread` | 480 | Match cut, iris half, rule draws under mastheads |
| `dur.wipe.blade` | 200 close / 280 open | One blade of the column wipe (§4.14.2) |
| `dur.dissolve` | 800 | Ambient colour change, page-tint change, backdrop swaps |
| `dur.reel` | 1400 | Cold-start logo reveal cap |
| `dur.drift` | 26000 | Ken Burns on cover-story art (alternate, infinite) |
| `dur.type` | 50 per grapheme | Typing reveal (binding) |
| `dur.caret` | 530 | Caret blink half-period |
| `dur.letter` | 640 (blur 440) | Per-letter reveal of one grapheme |
| `dur.hold.toast` | 3600 | Default toast hold (errors 6000, with an action 8000, skin undo 10000) |
| `dur.hold.rating` | 3000 | 18+ rating card hold |
| `dur.dwell.preview` | 600 | Desktop poster preview slate |
| `dur.dwell.backdrop` | 400 | Desktop backdrop swap on dwell |
| `dur.flicker` | 1400 | Skeleton "projector flicker" half-period |

#### 2.9.3 Curves

| Token | Value | Flutter | Use |
|---|---|---|---|
| `ease.settle` | `cubic-bezier(0.16, 1, 0.3, 1)` | `Cubic(0.16, 1, 0.3, 1)` | Every entrance |
| `ease.lift` | `cubic-bezier(0.7, 0, 0.84, 0)` | `Cubic(0.7, 0, 0.84, 0)` | Every exit |
| `ease.turn` | `cubic-bezier(0.65, 0, 0.35, 1)` | `Cubic(0.65, 0, 0.35, 1)` | Dissolves, match cuts, wipes, iris, colour changes |
| `ease.set` | `cubic-bezier(0.2, 0, 0, 1)` | `Cubic(0.2, 0, 0, 1)` | State changes inside a component (toggle knob, rule slide, progress width) |
| `ease.drift` | `cubic-bezier(0.37, 0, 0.63, 1)` | `Curves.easeInOutSine` | Ken Burns, flicker, flame |
| `ease.linear` | `linear` | `Curves.linear` | Leader sweep, indeterminate rule, countdowns |

#### 2.9.4 Springs (gesture release only)

| Token | Motion (web) | Flutter | Use |
|---|---|---|---|
| `spring.release` | `{ type: "spring", visualDuration: 0.42, bounce: 0 }` | `SpringDescription.withDurationAndBounce(duration: 420ms, bounce: 0)` | Back swipe release, row swipe release, pager settle |
| `spring.sheet` | `{ visualDuration: 0.48, bounce: 0 }` | `withDurationAndBounce(480ms, 0)` | Sheet drag release to a detent or dismiss |
| `spring.scrub` | `{ visualDuration: 0.24, bounce: 0 }` | `withDurationAndBounce(240ms, 0)` | Scrubber thumb and slider thumb release |
| Rubber band | `d·(1 − 1/(x·0.35/d + 1))` | same | Over-scroll past bounds on rails, sheets and the reader's chapter-end pull |

#### 2.9.5 Named choreography

| Name | Spec | Where |
|---|---|---|
| **Cut** | 0 ms swap; newly visible items run *Set* | Filters, sorts, density, tab switches inside a page |
| **Set** (content entrance) | Items fade 0 → 1 and rise 8 px → 0, 320 ms `settle`, reading-order stagger (§2.9.6) | First paint of any list, grid or rail |
| **Folio flip** | The section number in the running head rolls: old digits translate −100 % and fade, new digits enter from +100 %, 80 ms per digit, 40 ms apart | Every section (tab or sidebar) change |
| **Page** (push) | Incoming: x +24 px → 0 and fade 0 → 1, 320 ms `settle`. Outgoing: x 0 → −24 px, fade to 0, 224 ms `lift` | Drill-ins with no shared element (settings subpages, lists → list) |
| **Match cut** | Shared cover morphs from its rect to its destination rect, 480 ms `turn`; everything else dissolves 240 ms | Poster → feature page, continue cutting → feature, bookmark cover → reader curtain |
| **Dip** | Out: fade to `#000` 160 ms `lift`; hold 40 ms; in: fade from `#000` 240 ms `settle` | Section switches on desktop, leaving the reader, auth → picker |
| **Column wipe** | §4.14.2 | Entering either reader from anywhere |
| **Iris** | §4.5 | Profile selection only |
| **Insert** | Dialog clip-path `inset(0 0 100% 0)` → `inset(0)`, 320 ms `settle`; barrier 0 → .78, 200 ms. Exit: fade 160 ms `lift` | Dialogs |
| **Rise** | Sheet translateY 24 px → 0 and fade, 360 ms `settle`; barrier 240 ms. Exit 240 ms `lift` | Sheets |
| **Dissolve** | Cross-fade 800 ms `turn`, old layer holds while the new fades over it | Backdrop swaps, ambient changes, hero art changes |
| **Rack focus** | Image from blur 14 px, brightness 0.6, scale 1.03 → sharp, 1.0, 1.0 over 520 ms `settle` on its first decode (skipped when the image was cached synchronously) | Every cover and page image except inside the reader strip |
| **Drift** | Scale 1.00 → 1.06 and translate −1 %, −1.5 %, 26 s `drift`, alternate, infinite; paused off screen | Tonight cover art, feature page art, Annual cover art |
| **Flicker** | Opacity 0.55 ↔ 1, 1400 ms `drift` alternate; each skeleton's phase offset by 60 ms in reading order | Skeletons |
| **Rule draw** | A rule's `scaleX` 0 → 1 from its left end, 480 ms `settle` | Oxford rule under mastheads, the heavy rule above notices, the section rule above a revealed H3 (drawn 120 ms before the letters start) |
| **Stop the press** | §4.30.3 | Skin switch outgoing |
| **Credits** | §4.14.6 | End of a chapter |

#### 2.9.6 Stagger rules

- **Grids and walls:** +32 ms per item within a row, +64 ms per new row, total capped at 480 ms. Items past the cap appear with the last batch.
- **Single-column lists:** +24 ms per row, cap 360 ms (15 rows).
- **Letters:** +24 ms per grapheme, total capped at 560 ms (`step = min(24, 560 / (n − 1))`).
- **AI prose streaming:** each word fades in over 160 ms, 30 ms after the previous word.
- **Only on first data paint.** Refetches, pagination appends and pull-to-refresh results use one 160 ms fade for the whole appended block. Returning to a screen through back never replays a stagger.

#### 2.9.7 Interruptibility

- Every property animation retargets from its current value (Motion's default; Flutter `AnimationController.animateTo` from `value`). No animation queues behind another.
- A back gesture during a forward route transition reverses it from its current progress.
- A letter reveal that leaves the viewport before it finishes jumps to its end state; it never replays in the same session.
- A typing reveal completes instantly on tap, click, Enter or Space inside its block.
- Data that arrives while a skeleton is flickering dissolves over 160 ms; no stagger waits for data and no data waits for a stagger.
- The column wipe and iris can be skipped with a tap; they jump to the open state in 120 ms.
- A sheet can be grabbed mid-rise; the finger takes over from the current offset.

#### 2.9.8 Reduced motion (OS setting; web `prefers-reduced-motion`, Flutter `MediaQuery.disableAnimationsOf` or iOS `accessibilityFeatures.reduceMotion`)

| Element | Normal | Reduced |
|---|---|---|
| Per-letter reveal | staggered fade, rise, un-blur | whole string fades in over 200 ms |
| Typing reveal | 50 ms per grapheme with caret | full text at once, no caret |
| Column wipe, iris, match cut, stop the press | as specified | 200 ms cross-fade |
| Page, dip, rise, insert | slides and clips | 150 ms opacity cross-fade |
| Drift (Ken Burns) | 26 s loop | still frame at scale 1.03 |
| Rack focus | blur-to-sharp | 160 ms opacity fade |
| Flicker skeletons | pulsing | static at 0.8 opacity |
| Rule draws | scaleX | rules present at rest |
| Folio flip | digit roll | instant |
| Poster hover zoom | image scale 1.04 | outline only, no scale |
| Auto-scroll | available | never auto-starts; manual start allowed |
| Guided view camera | dolly between panels | cut between panels |
| Streak flame flicker | 2 s loop | static fill |
| Gestures | finger-tracked, spring release | finger-tracked; release finishes with a 150 ms fade |

### 2.10 Haptics vocabulary

Character: **letterpress**. Low sharpness, firm, sparse. Most taps are silent; commits get a pressed "impression". All calls route through one class (`mobile/lib/skins/skin_haptics.dart`, stack-decision §2.3) behind the user's "Haptic feedback" toggle. Named impacts use `haptic_feedback` 0.6.5 (`Haptics.vibrate(HapticsType.x)`, iOS UIFeedbackGenerator, Android `Vibrator` effects). Signature patterns use `gaimon` 1.5.0 `Gaimon.patternFromData(ahapJson)` (Core Haptics AHAP on iOS, auto-converted to an amplitude waveform on Android; authored with transient and continuous events only, per brand research §9). Mobile web: Android Chrome gets `navigator.vibrate` for the five events marked *web* below; iOS Safari gets nothing. Every haptic is paired with a visible change.

**Signature AHAP patterns** (T = HapticTransient, C = HapticContinuous; I = intensity, S = sharpness; seconds):

| Pattern | Events | Feel |
|---|---|---|
| `impress` | T@0.000 I0.90 S0.20; T@0.045 I0.30 S0.10 | A type block kissing paper |
| `stamp` | T@0.000 I0.50 S0.30; T@0.070 I1.00 S0.20 | Rubber stamp: set down, then pressed |
| `wipe` | C@0.000 dur 0.300 I0.30 S0.15; T@0.300 I0.70 S0.25 | Blades closing, then the shutter landing |
| `ignite` | C@0.000 dur 0.400 I0.50 S0.20; T@0.400 I1.00 S0.30 | Streak flame catching |
| `pressrun` | T@0.000 I0.40 S0.30; T@0.060 I0.60 S0.30; T@0.120 I0.90 S0.25 | Printing press: share-card export |
| `pass` | T@0.000 I0.60 S0.40; T@0.100 I0.30 S0.60 | A note handed over: recommendation sent |

**Event table** (event names go into `design/contract.json`; the Glass skin maps the same names to its own patterns):

| Event | When | iOS | Android | Web |
|---|---|---|---|---|
| `tap.primary` | Primary button commits (Read, Continue, Save, Create) | `impress` | `impress` (converted) | — |
| `tap.secondary` | Secondary, text and icon buttons | none | none | — |
| `toggle.on` / `toggle.off` | Switch changes | `medium` / `light` | `medium` / `light` | — |
| `select` | Chip, segment, radio, checkbox, tab inside a page | `selection` | `selection` | — |
| `nav.change` | Tab bar or sidebar section change | `rigid` | `rigid` | — |
| `longpress.open` | Quick-look sheet or context menu opens | `heavy` | `heavy` | `[12]` web |
| `sheet.detent` | Sheet settles on a detent | `light` | `light` | — |
| `sheet.dismiss` | Sheet or dialog dismissed by drag | none | none | — |
| `refresh.arm` / `refresh.fire` | Pull passes the trigger / release fires | `medium` / none | `medium` / none | — |
| `follow.add` | Follow, add to library, add to collection | `stamp` | `stamp` | `[12]` web |
| `follow.remove` | Unfollow, remove | `light` | `light` | — |
| `favorite` | Star on / off | `light` | `light` | — |
| `bookmark.add` | Bookmark saved | `impress` | `impress` | — |
| `download.start` / `download.done` / `download.fail` | Queue accepts / chapter saved / chapter failed | `light` / `success` / `error` | same | — / — / `[20,40,20]` web |
| `delete.confirm` | Destructive confirm pressed | `warning` | `warning` | — |
| `undo` | Undo pressed in a toast | `light` | `light` | — |
| `reader.enter` | Column wipe blades land | `wipe` | `wipe` | — |
| `page.turn` | Paged mode page change, guided view panel change | `selection` | `selection` | — |
| `scrub.tick` / `scrub.boundary` | Scrubber crosses a page / a chapter boundary | `selection` / `medium` | same | — |
| `chapter.complete` | Last page of a chapter reached | `medium` then `light` 120 ms later | same | — |
| `chapter.next` | Next chapter committed (pull or button) | `heavy` | `heavy` | — |
| `autoscroll.toggle` / `autoscroll.step` / `autoscroll.end` | Play or pause / speed step / end of series | `rigid` / `selection` / `heavy` | same | — |
| `zoom.snap` | Double-tap zoom lands | `light` | `light` | — |
| `listen.toggle` | Play or pause narration | `rigid` | `rigid` | — |
| `voice.assign` | A voice cast to a character or narrator | `impress` | `impress` | — |
| `sleep.fade` | Sleep timer starts its 8 s fade | `soft` | `soft` | — |
| `streak.extend` | Streak increases today | `ignite` | `ignite` | — |
| `annual.page` | Annual story page advances by tap | `selection` | `selection` | — |
| `share.export` | Share card rendered | `pressrun` | `pressrun` | — |
| `reaction.send` | Reaction stamp pressed | `stamp` | `stamp` | — |
| `recommend.send` | Recommendation sent | `pass` | `pass` | — |
| `gate.confirm` | 18+ certificate confirmed | `stamp` | `stamp` | — |
| `profile.select` | Iris closes on the chosen profile | `heavy` | `heavy` | — |
| `skin.switch` | Stop the press, just before restart | `heavy` | `heavy` | — |
| `reader.unlock` | Fifth centre tap unlocks locked controls | `medium` | `medium` | — |
| `success` / `error` | Generic success / failure toast | `success` / `error` | same | — / `[20,40,20]` web |

Never haptic: scrolling, chrome show and hide, hover, focus, typing reveal characters, letter reveals, toasts appearing.

### 2.11 UI sounds ("Press Room", off by default)

Opt-in at Settings → Feedback → "UI sounds" (default **off**), with a volume slider (0–100 %, default 60 %). All cues are original syntheses (`sox -n … synth`), 48 kHz 16-bit mono WAV, 5 ms fades, total set ≤ 260 KB. Key of G (warm, low-passed below 5 kHz, 0.3 s small-room reverb at 12 % wet). Peaks: ticks −30 dBFS, confirmations −20 dBFS, the logo sting −12 dBFS.

| Cue | Events | Length | Recipe |
|---|---|---|---|
| `tick` | `select`, `nav.change` | 10 ms | Felt key: noise burst band-passed at 2.2 kHz (Q 3) + 90 Hz sine 20 ms |
| `set` | `tap.primary`, `bookmark.add`, `voice.assign` | 60 ms | Type slug: two clicks 12 ms apart + 900 Hz body, 40 ms decay |
| `impress` | `follow.add`, `reaction.send`, `gate.confirm` | 140 ms | Letterpress: 70 Hz sine 90 ms exponential decay + felt click, synced to the haptic |
| `turn` | `page.turn`, `annual.page` | 160 ms | Paper swish: pink noise, band 800 Hz–5 kHz, 160 ms swell envelope |
| `wipe` | `reader.enter` | 420 ms | Air rush: noise low-passed sweeping 300 → 1800 Hz, landing on a 60 Hz thump at 300 ms |
| `done` | `download.done`, `chapter.complete` | 300 ms | Muted vibraphone G4 · B4 · D5, 60 ms steps |
| `bell` | `streak.extend` | 450 ms | Small bell G6 (1568 Hz), FM ratio 3.5, index 1.0 |
| `pass` | `recommend.send` | 220 ms | Paper slide + soft G5 tick |
| `error` | `error`, `download.fail` | 180 ms | Two dull knocks G3 → F♯3, low-passed 700 Hz |
| `toggle` | `toggle.on` / `toggle.off` | 40 ms | One click (on: 2.6 kHz, off: 1.9 kHz) |
| `sheet` | sheets rising | 120 ms | Low paper slide, −30 dBFS |
| `reel` | cold-start logo reveal | ≤ 1600 ms | Projector motor (12 Hz AM noise, 900 ms) + G2/D3 pad swell low-passed 300 → 2400 Hz + the `impress` hit at 1180 ms |

Playback: web through the Web Audio API (decode each WAV once into an `AudioBuffer` on the first user gesture; one master `GainNode`); mobile through `flutter_soloud` 5.1.4 (MIT). Rules: iOS uses the `.ambient` session category so the ring/silent switch mutes cues; cues are suppressed while narration or a soundscape plays; the user's music is never ducked.

---

## 3. Component catalog

Every primitive below is one component per client: `frontend/src/skins/cinematic/primitives/<Name>.tsx` and `mobile/lib/skins/cinematic/primitives/<name>.dart`. Unless a table says otherwise, these rules hold for all of them:

- **Hit area** ≥ 44 × 44 (iOS, web) and ≥ 48 × 48 (Android), grown with padding; ≥ 8 px between adjacent targets.
- **Focus** shows on keyboard focus only (web `:focus-visible`; Flutter `FocusHighlightMode.traditional`): a 2 px `ink.100` outline at 2 px offset, square. It is never clipped: rails and grids pad 8 px vertically for it, and sticky bars set `scroll-padding-block`.
- **Disabled** means `ink.30` text and glyphs, no hover, no pressed state, `aria-disabled` plus a tooltip that says why when the reason is not obvious.
- **Loading** never replaces a control's width: labels keep their box and a running rule or a 16 px leader dial shows progress; `aria-busy="true"`.
- **Error** states name what went wrong in words, in `proof`, next to the control that failed, with a margin mark `‸` in the left margin on desktop forms.
- Reduced-motion variants follow §2.9.8.

### 3.1 Buttons

| Variant | Visual (default) | Size | Where |
|---|---|---|---|
| `primary` | Fill `ink.100`, text `#000000` `type.label`, optional leading icon 20 Regular in `#000`, radius 0 | md 44 (desktop) / 48 (phone); lg 56 (hero); sm 32 (desktop dense rows only) | One per view: Read, Continue, Save, Create, Sign in |
| `split` ("folio button") | A `primary` whose right segment carries a folio: `Continue │ CH 143 · p.12`. The segments are divided by a 1 px `#000` rule; the folio segment uses `type.folio` in `#000` | lg 56 / md 48 | Continue and Read CTAs on Tonight, feature pages, history, bookmarks |
| `secondary` | Transparent, 1 px `ink.100` outline, text `ink.100` | as primary | Second action: Read all, Previously on, Add series |
| `quiet` | Text only `type.label` `ink.60`, no outline; 1 px underline at 4 px offset appears on hover | 44 hit | Third actions: Details, Cancel, Skip |
| `destructive` | Outline 1 px `proof`, text `proof`; the final confirm inside a dialog is filled `proof` with `#000` text | as primary | Delete, Remove, Sign out everywhere |
| `on-art` | Fill `rgba(0,0,0,0.64)`, 1 px `ink.100` 40 % outline, text `ink.100` | 44 / 48 | Buttons laid over covers (phone hero, Annual pages) |
| `play` | Circle 64 px (the only round button), fill `ink.100`, glyph `play`/`pause` Fill 28 `#000` | 64 (Listen full player), 36 (mini player) | Listen mode only |
| `link` | Inline Newsreader text with 1 px underline at 3 px offset, `ink.100` | inline | Inside prose: "Turn on sharing in Settings" |

States (all variants; colours swap per variant as noted):

| State | Visual | Motion |
|---|---|---|
| Default | As above | — |
| Hover (pointer) | Primary and split: a 2 px `spot` rule draws under the button, 4 px below its bottom edge, full width. Secondary: fill `paper.4`. Quiet and link: underline appears. Destructive: fill `proof.wash`. | Rule `scaleX` 0 → 1 from the left, 240 ms `settle`; out 160 ms `lift` |
| Pressed | **Impression**: the whole button translates 1 px down; primary fill → `ink.80`; secondary fill → `paper.3`; destructive fill `proof` → `#E0483A`. Haptic `tap.primary` on commit for primary and split. | 80 ms `set` down, 160 ms `settle` up |
| Focused | Focus ring (2 px `ink.100`, 2 px offset); on primary the ring sits outside a 2 px `#000` gap so it separates from the fill | instant |
| Disabled | Primary: fill `paper.3`, text `ink.30`. Others: `ink.30` text and outline. Split: folio segment hidden. "All caught up" is a disabled primary with a `check` glyph. | — |
| Loading | Label stays; a 2 px `spot` segment 25 % wide runs along the button's inside bottom edge left → right (1200 ms linear loop). Label text changes to the present participle only when the wait passes 400 ms ("Signing in…"). | as described |
| Selected (toggle buttons such as "Following", "In your library") | Secondary becomes filled `ink.100` with `#000` text and a leading `check` | label cross-fade 160 ms |
| Error | Outline or fill turns `proof` for 2000 ms and an error line appears beneath (`type.caption` `proof`, margin mark on desktop). No shake. | colour 160 ms |

### 3.2 Icon buttons

| Variant | Visual | Size |
|---|---|---|
| `bare` | Glyph 24 Light `ink.60` | 44 (48 Android) hit |
| `on-art` | 40 px square, fill `rgba(0,0,0,0.64)`, glyph 20 Regular `ink.100` | 44 hit |
| `ruled` | 36 px square outline 1 px `rule.2`, glyph 20 Regular | 44 hit; steppers, zoom |
| `badged` | `bare` plus a count badge (§3.19) at the glyph's top-right | bell, downloads |

| State | Visual | Motion |
|---|---|---|
| Default | As above | — |
| Hover | Glyph `ink.100`; a 1 px `ink.30` square outline appears at the hit area's inner 36 px | 80 ms |
| Pressed | Glyph translates 1 px down; square fills `paper.3` | 80 ms down, 160 ms up |
| Focused | Focus ring on the 36 px square | instant |
| Disabled | Glyph `ink.30` | — |
| Loading | Glyph replaced by a 16 px leader dial (§3.18) | cross-fade 120 ms |
| Selected | Glyph switches to Fill `ink.100` and a 2 px `spot` rule sits 4 px under the square (favourite, bookmark saved, notify on) | glyph swap 120 ms; rule draw 240 ms |
| Error | Glyph turns `proof` for 2000 ms; tooltip gives the reason | 160 ms |

Tooltips: `paper.2` band, 1 px `rule.2`, `type.caption` `ink.100`, 6 px × 8 px padding, appear after 500 ms hover (0 ms on keyboard focus), with the shortcut in a keycap when one exists ("Bookmark  B").

### 3.3 Inputs (text, password, number, textarea, select)

The editorial field has no box: a label above and a rule beneath.

| Part | Spec |
|---|---|
| Label | `type.kicker` `ink.45`, 8 px above the text line |
| Text | `type.ui` at 16 px (phone) / 15 px (desktop) `ink.100`; placeholder `ink.45` |
| Underline | 1 px `rule.2` |
| Height | 48 (text baseline 16 px above the rule) |
| Helper / error line | `type.caption`, 8 px below the rule |
| Password reveal | A `quiet` text button "Show" / "Hide" at the right end (words, not an eye); excluded from the tab order |
| Number | `type.folio.lg`, right-aligned, with a unit suffix in `ink.45` ("min", "GB") |
| Textarea | Faint ruled lines every line height (1 px `rule.1`), like a notepad; grows to 6 lines then scrolls |
| Select | Underline field with a trailing `caret-down` 16; opens a menu (§3.22) on desktop and a sheet on phones |

| State | Visual | Motion |
|---|---|---|
| Default | As above | — |
| Hover | Underline `ink.45` | 160 ms |
| Focused | Underline becomes 2 px `spot`, drawn from the left; label `ink.100`; caret `spot` 2 px wide | 240 ms `settle` |
| Filled | Label stays above; value `ink.100` | — |
| Disabled | Text `ink.30`; underline dotted 1 px `rule.2` | — |
| Loading (async validation, e.g. server URL) | A 16 px leader dial at the right end | fade 120 ms |
| Error | Underline 2 px `proof`; error line in `proof` prefixed with `‸`; `aria-invalid` + `aria-describedby` | 160 ms |
| Success (validated) | A 16 px `check` in `set` at the right end for 1600 ms | fade |

### 3.4 Search fields

| Variant | Spec | Where |
|---|---|---|
| `index` (big) | `type.field` (Bodoni Moda Italic) at 28–40 px; placeholder in `ink.30` typed at 50 ms per character when empty and unfocused ("Search every source"); typed text switches to Bodoni Moda Roman; `spot` caret 3 px wide; 1 px underline, 2 px `spot` when focused; trailing `quiet` "Clear" once there is text | Discover, Dialogue, command palette, Picks ask field |
| `compact` | `type.ui` field, leading `magnifying-glass` 20 Regular, height 44, underline style | In-page filters: library, sources, collections, contents go-to |

States as §3.3. Keyboard: `/` focuses the page's search, `Esc` clears then blurs, `Enter` searches now (skips the 300 ms debounce), `↓` moves into results.

### 3.5 Chips and filters: "slug lines"

Filters are typographic toggles on one line separated by middle dots: `ALL · READING · UNREAD · COMPLETED · ★ FAVOURITES`.

| Part | Spec |
|---|---|
| Label | Archivo `wdth` 75, `wght` 600, 12/16 uppercase, +0.10em |
| Count | Superscript folio (Plex Mono 10, `ink.45`) after the label: `READING¹²` |
| Separator | `·` in `ink.30`, 12 px spacing either side |
| Removable (active filter token) | Label + `x` 12 inside a 1 px `rule.2` square box, height 28 |
| Row | Scrolls horizontally on phones with a 24 px fade at the trailing edge; wraps on desktop |

| State | Visual | Motion |
|---|---|---|
| Default | `ink.45` | — |
| Hover | `ink.100` | 160 ms |
| Pressed | Translate 1 px down | 80 ms |
| Focused | Focus ring around the label | — |
| Selected | `ink.100` plus a 2 px `spot` underline 4 px below the baseline, label width | Underline slides between chips 320 ms `settle` (single-select) or draws 240 ms (multi-select) |
| Disabled | `ink.30` | — |
| Loading (counts pending) | Count shows `–` | — |
| Error | n/a (filters are local) | — |

**Segmented control** (`Layout: STRIP │ SINGLE │ DOUBLE`): the same labels divided by 1 px vertical `rule.2` rules inside a 1 px `rule.2` frame, 40 px tall; the active segment shows `ink.100` and a 2 px `spot` underline that slides 320 ms `settle`. Disabled segments are `ink.30` with a tooltip ("Height fit needs a paged layout").

**Tri-state genre filter** (source genres, onboarding): tap cycles *neutral* (`ink.45`) → *include* (`ink.100` + spot underline) → *exclude* (`ink.45` with a 1 px strike-through in `proof`) → neutral; long-press or right-click jumps straight to exclude.

### 3.6 Cards

Programme has few cards; most groupings are rules and space. The card types that exist:

| Card | Anatomy | States |
|---|---|---|
| **Feature** | Image (3:2 crop on desktop, 4:5 on phone) → kicker (`type.kicker`, series `ambient.ink` or `ink.45`) → headline (`type.subhead`, 2 lines) → deck (`type.body.italic` `ink.60`, 2 lines). No frame. | Hover: image zoom 1.04 inside its frame + headline underline; pressed: 1 px impression; focus: ring around the whole card; loading: flicker plate + greeked lines; error: plate with title card |
| **Cutting** (continue reading) | 3:2 crop of the cover at `object-position: 50% 22%`, a 2 px `spot` progress rule flush on the image's bottom edge, then `type.title` 1 line and a folio caption `CH 142 · 63%` or `NEXT · CH 143`. Nudge badges on the image's top-left: `3 NEW`, `ALMOST DONE`, `PAUSED 21 D` | as Feature; long-press opens Quick look with Remove from row, Mark read, Open series, Previously on |
| **World** (AI recommendation) | Two visibly different variants. *Available*: full-colour poster 2:3 + title + kicker `MANHWA · ONGOING · ★ 8.4` + `why` line as a Newsreader italic pull quote with a 2 px `spot` left rule + credit `ON MANGADEX, ASURA +1`; the whole card opens the series. *Information only*: the poster in **duotone** (black → `ambient.duo`), credit `NOT ON YOUR SOURCES` in `ink.45`, and two quiet buttons `Search my sources` and `Read on {site} ↗` | Hover: poster zoom; dismiss `x` (bare icon button) appears top-right on hover and is always in the long-press menu ("Not for me") |
| **Stat block** | 3 px `rule.heavy` on top → kicker → `type.numeral` value → caption. No frame. | Loading: numeral replaced by a greeked bar at the numeral's height; value changes cross-fade 160 ms |
| **Notice** | §3.23 | — |
| **Letter** (Circle recommendation) | Duotone cover strip 3:2 left, right side: kicker `FROM RIYA`, headline title, the note in Newsreader italic in quotes, actions `Read`, `Add`, `Dismiss` | New: a `spot` square dot before the kicker until opened |
| **Collection plate** | 16:9 mosaic of the first four member covers in duotone (the collection's own `ambient.duo` taken from the first member), name in `type.subhead` over a `scrim.foot`, credit `24 SERIES · SMART · SHARED`, shared-with avatars (20 px) bottom-right | Hover: mosaic zoom 1.03; selected (reorder mode): 2 px `spot` inset frame |

### 3.7 Posters

2:3, radius 0, `paper.1` placeholder, inner hairline `inset 0 0 0 1px rgba(243,240,232,0.08)`. Width is always derived from the grid (§3.8), requested from the cover proxy at the nearest snapped width ≥ rendered width × DPR (96, 160, 240, 360, 480, 720).

Caption modes:
- **Wall** (Discover genres, source catalogue on desktop, onboarding): no caption; the title appears in the hover slate and in `aria-label`.
- **Below** (Library, rails): `type.title` 14/20 on 1 line (2 at text scale ≥ 1.3), then a folio caption in `ink.45`: `CH 142 · 3 NEW`, `NOT STARTED`, `CAUGHT UP`, `CH 12 OF 40`.
- **Ranked** (Top ten): a Bodoni Moda Roman numeral in `ink.30`, 1.0 × poster height, sitting half behind the poster's left edge.

Badges sit top-left in a 4 px inset stack (§3.19): `NEW`/`3 NEW`, status, `18` certificate (only when the profile's gate is open and the series is mature), `SAVED`, `TEXT` (dialogue indexed).

| State | Visual | Motion |
|---|---|---|
| Default | As above | Rack focus on first image decode |
| Hover (desktop) | Image scales 1.04 **inside** the fixed frame; a 2 px `ink.100` inside outline; art light bloom `0 0 48px -16px ambient.duo` at 60 %; caption title underlines; siblings in the same rail or grid dim to `brightness(0.55) saturate(0.8)` (web `:has()`; Flutter an `InheritedNotifier` of the hovered index driving a `ColorFiltered`) | 200 ms `settle`; sibling dim 280 ms |
| Dwell 600 ms (desktop rails) | Preview slate (§3.8) | — |
| Pressed | Whole poster scales 0.98 | 80 ms `set`, back 160 ms `settle` |
| Focused | Focus ring 2 px `ink.100` at 2 px offset + the hover treatment | instant |
| Disabled (unavailable source, pinned source missing) | 40 % opacity, caption `UNAVAILABLE` | — |
| Loading | `paper.1` plate with flicker; if the title is known, a **title card**: the title in Bodoni Moda Italic 14/16 `ink.45`, bottom-left, 8 px inset | Flicker |
| Selected (select mode) | 24 px `ink.100` check square at top-right with a `#000` check; 2 px `spot` inset frame; image `brightness(0.7)` | Check box fills 120 ms |
| Error (image failed) | `paper.1` plate with the title card and a 16 px `image-broken` Regular glyph `ink.30` bottom-right; long-press offers "Retry cover" | — |

Long-press (phone, 450 ms) or right-click (desktop) opens Quick look (§3.22).

### 3.8 Rails

| Part | Spec |
|---|---|
| Section rule | 1 px `rule.1` across the content columns, drawn (§2.9.5 Rule draw) 120 ms before the heading letters start |
| Header row | Folio (`type.folio` `ink.45`, "04") → 12 px → H3 in `type.section` with the letter reveal (§6.1) → right-aligned `quiet` link "See all" with a 16 px `arrow-right` (desktop hover makes the H3 letters wipe to `spot`, §6.1.4) |
| Header → posters | 12 px |
| Visible posters | phone 3.2 · tablet 5.2 · desktop 6.25 · wide 7.25 · cinema 8.25 (text scale ≥ 1.3 on phones: 2.3) |
| Poster width | `(content width − (visible_floor × gap)) / visible` |
| Gap | phone 8 · tablet 12 · desktop 12 · wide 12 · cinema 16 |
| Scroll | Native horizontal scroll, `scroll-snap-type: x proximity`, snap to poster starts; `overscroll-behavior-x: contain`; Flutter `ListView` with `PageScrollPhysics`-free snapping (`ClampingScrollPhysics` + a snap-to-item `ScrollEndNotification` handler, 320 ms `settle`) |
| Paddles (desktop) | 48 px wide, full poster height, over `scrim.rail-end`; `arrow-right` / `arrow-left` 24 Light `ink.100`; appear on rail hover (160 ms); page by `visible − 1` posters over 560 ms `turn`; hidden at the rail's ends |
| Preview slate (desktop, dwell 600 ms or `Space` on a focused poster) | A portal overlay, not a layout push, 2.1 × poster width, anchored over the poster: top half the duotone cover backdrop (`blur.card`) with the title in `type.subhead` letter reveal; bottom half `paper.2`: kicker (format · status · chapters), 2-line deck, `why` line if AI-picked, buttons `Read` (primary sm), `+ Library` (secondary sm), `Details` (quiet). Grows from the poster rect 320 ms `settle`; collapses 200 ms `lift` after a 120 ms grace on leave. `Esc` closes. |
| Keyboard | One Tab stop per rail (roving `tabindex`); `←`/`→` move; the focused poster scrolls into the first fully visible column (320 ms `settle`); `↑`/`↓` move to the neighbouring rail and the page scrolls so it sits at 30 % of the viewport; `Home`/`End` jump to the rail's ends; `Enter` opens; `Space` toggles the slate |

Rail states:
- **Loading:** header renders immediately (it is a static string) and plays its reveal; posters are flicker plates with title cards when titles are known.
- **Empty:** core rails (Continue, New this week) collapse to a one-line note in `type.body.italic` `ink.45` ("Nothing in progress. Start something below."); optional rails disappear entirely.
- **Error:** header stays; one line `This row didn't load.` in `proof` caption + `quiet` Retry.
- **AI unavailable:** header stays with a `NOTE` kicker line: "The picks desk is closed tonight. Here is your shelf instead." and a locally built rail replaces it (§5.1.6).
- **Stale:** a `SAVED COPY · 3 H` micro badge beside the header when the payload's `cache.stale` is true.

### 3.9 Sheets

| Part | Spec |
|---|---|
| Surface | `paper.2`, radius 0, full width on phones (max 720 centred on tablets), 1 px `rule.2` top edge |
| Grabber | 32 × 3 `ink.30` bar centred 8 px below the top edge |
| Header | 56 px: kicker (`type.kicker`) over title (`type.subhead`) on the left; `quiet` "Done" on the right (never an `x` in sheets) |
| Detents | Content-fit up to 0.92 of the screen by default. Live-preview sheets (reader settings, novel type, reader page actions) use `[0.5, 0.92]` so the page stays visible above them. |
| Barrier | `scrim.modal`, tap closes |
| Desktop | Sheets become **column panels**: 4 columns wide (min 400 px) sliding in from the right edge, `paper.2`, 1 px `rule.2` left edge, full height under the running head; `Esc` closes. Confirmations become dialogs instead. |

| State | Visual | Motion |
|---|---|---|
| Opening | Rise: translateY 24 px → 0 + fade, 360 ms `settle`; barrier 0 → .78 in 240 ms | Haptic none; sound `sheet` if on |
| Dragging | Follows the finger 1:1; past the top detent rubber-bands with c = 0.35 | — |
| Release | Settles to the nearest detent with `spring.sheet`; dismisses when dragged below 30 % of its height or flung down faster than 800 px/s | Haptic `sheet.detent` on settle |
| Closing | 240 ms `lift`, translateY +24 px + fade | — |
| Loading | Header renders; body shows a 24 px leader dial and the kicker "LOADING" after 400 ms | — |
| Error | A notice (§3.23) inside the body | — |
| Focus | Focus moves to the sheet's first control on open, returns to the trigger on close; `Tab` is trapped | — |

Android back and iOS swipe-down both close; on web, sheets that should close on browser back push a history entry (`?sheet=type`).

### 3.10 Dialogs

| Part | Spec |
|---|---|
| Surface | `paper.3`, 1 px `ink.30` border, radius 0, max width 560 (6 desktop columns); phones 88 % width, centred |
| Title | `type.subhead` (Bodoni Moda) 24/28 |
| Body | `type.body` `ink.60`, max 48ch |
| Actions | Desktop: right-aligned row, `quiet` Cancel then the primary or destructive. Phones: stacked full-width buttons, the committing action on top, Cancel as `quiet` below. |
| Heavy confirmations | Typed phrase field ("Type RESTORE to confirm", case-insensitive), acknowledgement checkbox ("I understand this signs me out on this device too"), or typed username (member delete). The confirm button stays disabled until satisfied. |
| Motion | Insert (§2.9.5) in; fade 160 ms `lift` out |
| Focus | Initial focus on the least destructive action; `Esc` and the barrier cancel (except while a destructive request is running) |

States: default; pending (the committing button shows its loading state, Cancel disabled); error (an error line above the actions, in `proof`).

### 3.11 Toasts: "subtitles"

| Part | Spec |
|---|---|
| Position | Phones: bottom-centre, 16 px above the tab bar (or the safe area where there is no tab bar). Desktop: bottom-left of the content column, 24 px from the bottom. |
| Surface | `paper.0` band with a 1 px `rule.2` border, a 2 px left edge rule (`spot` for info and success, `proof` for errors, `set` for completion) |
| Text | `type.ui` 15 `ink.100`, 2 lines max, 12 × 16 px padding; max width 560 |
| Action | One `quiet` button in `ink.100` with underline ("Undo", "View", "Retry") |
| Hold | 3600 ms; errors 6000; with an action 8000; skin undo 10000; indefinite while hovered or focused |
| Motion | In: fade + 8 px rise 160 ms `settle`. Out: fade 240 ms `lift`. A newer toast pushes the older one up by its height (240 ms `set`); max 2 visible. |
| Dismiss | Swipe down (phone), `Esc` (focused), or timeout |
| Accessibility | `role="status"` (polite); errors `role="alert"`; the hold never runs out while a screen reader is active and the toast has an action |

Web uses `sonner` 2.0.8 in unstyled mode rendering these subtitles; Flutter uses one `OverlayEntry` host in the shell (no package).

### 3.12 Tabs (in-page): "contents tabs"

| Part | Spec |
|---|---|
| Label | Folio + label: `01 CHAPTERS`, `02 DETAILS`, `03 MORE LIKE THIS`; `type.nav` desktop size; the folio in Plex Mono `ink.45` |
| Counts | Superscript folio after the label: `CHAPTERS²⁰¹` |
| Indicator | 2 px `spot` underline under the active label, sliding and stretching between tabs during a swipe (its x and width lerp with the pager position); tap-to-switch slides it 320 ms `settle` |
| Row | 48 px, 1 px `rule.1` under the whole row; scrolls horizontally on phones; sticky under the running head on long pages |
| Panels | Swipeable on phones (Flutter `TabBarView`; web scroll-snap pager); click, `[` and `]` on desktop |

States: default `ink.45`; hover `ink.100`; pressed 1 px impression; focus ring; selected `ink.100` + rule; disabled `ink.30` (e.g. `04 CIRCLE` when sharing is off, with a tooltip); loading (count `–`); error (count replaced by `!` in `proof`).

### 3.13 Top bars: the running head

**Phone** (iOS, Android, mobile web):

| Part | Spec |
|---|---|
| Height | 44 + status bar inset |
| Leading | Back (`arrow-left` 24 Light) on pushed screens; nothing on tab roots |
| Running title | Centre: `type.nav` `ink.60`, e.g. `LIBRARY · UPDATES`; hidden while the page masthead is visible, cross-fades in (160 ms) once the masthead scrolls under the bar |
| Trailing | Up to 2 bare icon buttons (screen-specific) |
| Surface | Transparent over the masthead or art; after 24 px of scroll it becomes `#000` with a 1 px `rule.1` bottom (160 ms) |
| Back online | The badge reads `BACK ONLINE` for 2 s; when the progress and bookmark outboxes flush, a toast confirms "Synced 12 reads and 2 bookmarks." |
| Offline | When offline, a micro badge `OFFLINE EDITION` in a 1 px `ink.45` box sits under the running title for 4 s after the change, then collapses into a 16 px `wifi-slash` glyph at the trailing edge (tap it for the explanation sheet) |

**Desktop** (768+):

| Part | Spec |
|---|---|
| Height | 56, `#000`, 1 px `rule.1` bottom; transparent with `scrim.head` over spreads until 80 px of scroll (240 ms) |
| Left | Running head breadcrumb: folio + section + page, `No. 02 · LIBRARY / SOLO LEVELING` (`type.folio` + `type.nav`); each segment is a link |
| Right | Index search trigger (a 280 px `compact` field reading "Search or jump…  ⌘K" that opens the command palette), Updates bell (`badged` icon button), profile chip (28 px avatar + name, `type.ui`, opens the account menu: display name, `@username`, `ADMINISTRATOR` credit for admins, Switch profile, Settings, Sign out), clock is not shown |
| Offline | `OFFLINE EDITION` micro badge beside the breadcrumb for as long as the device is offline |

### 3.14 Bottom navigation: the "thumb index" (phones)

| Part | Spec |
|---|---|
| Height | 56 + bottom safe area; `#000`; 1 px `rule.1` top |
| Tabs | 1 `TONIGHT` (`moon-stars`), 2 `LIBRARY` (`books`), 3 `DISCOVER` (`compass`), 4 `DOWNLOADS` (`download-simple`), 5 `INDEX` (`list-numbers`) |
| Cell | Icon 22 (Light; Fill when active) above the label (`type.nav` 10/12) |
| Active | `ink.100` icon and label + the **thumb notch**: a 24 × 2 px `spot` bar on the cell's top edge. The notch slides between cells 320 ms `settle` |
| Inactive | `ink.45` |
| Badges | Library: unread update count; Downloads: queued + downloading + failed count. Spot square, `#000` Plex Mono 10, min 16 × 16, at the icon's top-right; "99+" cap |
| Tap active tab | First tap scrolls to top (400 ms `settle`); second tap pops the branch to its root; on Discover a third tap focuses the search field |
| Long-press | Library → Updates; Downloads → the queue; Index → Switch profile. Haptic `longpress.open`. |
| Visibility | Shown on every screen of the five branches, including second-level lists (Collections, History, Updates, Settings root). Hidden on feature pages (their spread needs the height), readers, auth, the picker, Annual and recap title cards. It never minimises. |
| Motion | Section change: haptic `nav.change`; the new branch appears by **Cut** with its content running **Set**; the running head plays the **Folio flip** |

### 3.15 Desktop sidebar: "Contents"

| Part | Spec |
|---|---|
| Width | 248 expanded; 72 collapsed (the *spine*). Auto-spine at 768–1279. `mod+b` toggles; width animates 320 ms `turn`, labels fade out first (120 ms) and back in last. |
| Head | Wordmark (Bodoni masthead at 20 px) with a 1 px Oxford rule under it; in the spine, the `mm-mark` monogram |
| Content mode | `MANGA / NOVELS` typographic toggle (only when `novels_enabled`): the active word `ink.100` with a 2 px `spot` underline, the other `ink.45`; a slash between. In the spine: `M` / `N` stacked. |
| Section kicker | `IN THIS ISSUE` then `THE BACK PAGES` (`type.kicker` `ink.45`); hidden in the spine |
| Items | Folio (`type.folio` `ink.45`) + label (`type.ui` 15 `ink.60`) + optional count (Plex Mono `ink.45`) at the right. In this issue: `01 Tonight`, `02 Library`, `03 Updates` (unread count), `04 Discover`, `05 Downloads` (queue count). Back pages: `06 Collections`, `07 History`, `08 Bookmarks`, `09 Dialogue` (manga mode only), `10 The Numbers`, `11 Circle`, `12 Picks`. Footer: `Profiles`, `Settings`, `Status` (admin), collapse toggle. |
| Hover | Label `ink.100`, folio `spot`, 160 ms |
| Active | Label `ink.100`, folio `spot`, a 2 px `spot` bar on the item's left edge (full item height), `aria-current="page"`. Only the exact section lights up: `/library/collections` lights `06 Collections`, not `02 Library`. |
| Focus | Ring around the item |
| Spine | Folio numbers only (Plex Mono 14), labels as tooltips; counts as spot squares |
| Folio jump | `g` then a number jumps to that section (`g 1` … `g 12`; `g 0` Settings), shown in each tooltip. Guarded by the "Single-key shortcuts" setting. |

### 3.16 Lists and rows

| Row type | Anatomy | Height |
|---|---|---|
| Standard | Leading 20 Regular icon or 40 × 60 cover or 32 avatar → `type.title` + `type.caption` `ink.45` → trailing folio value or chevron | 56 (one line) / 72 (two lines) |
| Settings | Label `type.ui` + description `type.caption` `ink.45` → trailing control (switch, value with dot leaders, chevron) | min 56 |
| Chapter ("schedule row") | Left: chapter number in `type.folio.lg`, right-aligned in a 56 px column (`·` when the number is null, decimals printed as-is) → title (`type.title`, de-duplicated "Chapter 12" when the source title repeats the number) + caption (release date "TODAY", "YESTERDAY", "3 D AGO", "12 SEP 2026"; page count) → progress: `14/27` in `spot` Plex Mono when in progress, `READ` micro `ink.45` when complete (row text dims to `ink.45`), nothing when unread → download mark (§3.18) → reaction count folio (Circle on) | 56 |
| Contents (novel TOC) | Ordinal `type.folio` right-aligned → title in Newsreader 16 → dot leaders → length `12 MIN` → state mark (`42%` in `spot`, `READ`, headphones glyph when narrated, download mark) | 48 |
| Credits (cast, index) | Label → dot leaders → value, all on one baseline | 40 |

| State | Visual | Motion |
|---|---|---|
| Default | 1 px `rule.1` dividers between rows | — |
| Hover | A 2 px `ink.100` bar on the row's left edge; text `ink.100` | 120 ms |
| Pressed | Fill `paper.3` | 80 ms |
| Focused | Focus ring inset 2 px | — |
| Selected | Fill `paper.3` + 2 px `spot` left bar; in select mode a leading 20 px checkbox | 120 ms |
| Disabled | `ink.30`, no hover | — |
| Loading | Greeked lines at the exact line heights | Flicker |
| Error (row-level, e.g. a failed download) | Caption turns `proof` with the reason; a trailing `quiet` Retry | — |
| Current (novel TOC current chapter, go-to target) | `spot.wash` band behind the row + 2 px `spot` left bar; `aria-current="location"` | Band fades in 240 ms |

Swipe actions (phones, coarse pointers): flat square slabs revealed under the row, 72 px each: `Mark read` (fill `ink.100`, `#000` label), `Remove` (fill `proof`, `#000` label). Release past 50 % commits with `spring.release`; the same actions live in the long-press menu and in a trailing `dots-three` button (the non-gesture alternative). Flutter uses `Dismissible` for one action and `flutter_slidable` 4.0.3 only where a row needs two (Downloads chapter rows).

Drag to reorder (manual library order, pinned sources, collections, profiles): a `dots-six-vertical` handle 20 Regular at the trailing edge; the lifted row rises 1 px and gains a 1 px `ink.100` outline (no shadow); siblings shift 240 ms `set`; drop haptic `select`. Keyboard: `Alt+↑/↓` moves the focused row; each move is announced. Web: Motion 13 `Reorder`; Flutter `ReorderableListView` / `flutter_reorderable_grid_view` 5.7.0 for poster grids.

### 3.17 Skeletons: "galley proofs"

| Element | Proof |
|---|---|
| Text line | A bar `rgba(243,240,232,0.06)` at 50 % of the line height, vertically centred in the line box, widths from a seeded ragged list (92, 78, 96, 64, 88 %) |
| Headline | Bars at the headline's line height, 60 % and 35 % wide |
| Poster / image | `paper.1` plate with the inner hairline; a title card when the title is known |
| Numeral | One bar at 40 % of the numeral size |

All run **Flicker** with reading-order phase offsets. A skeleton matches the final layout box for box, so nothing shifts when data lands (the data dissolves over it in 160 ms). Never a shimmer gradient. A skeleton appears only after 120 ms of waiting; shorter waits show nothing.

### 3.18 Progress and loading

| Kind | Spec | Where |
|---|---|---|
| Rule (determinate) | 2 px, square ends, track `rule.1`, fill `spot`; width changes 240 ms `set` | Downloads, bulk runs, OCR scans, narration jobs, storage meter segments |
| Rule (indeterminate) | A 25 %-wide `spot` segment travelling left → right, 1200 ms linear loop | Checking for updates, AI suggest |
| Poster progress | 2 px `spot` rule flush on the cover's bottom edge | Cuttings, history, library posters in progress |
| Micro progress | 2 px `spot` at the very bottom of the reader while chrome is hidden (off in cinema mode) | Reader |
| Leader dial (replaces every spinner) | 32 px circle (24 inline, 16 in controls): 1 px `ink.30` ring, 1 px crosshair, conic sweep `rgba(243,240,232,0.22)` at one revolution per 1000 ms linear. Appears only after 400 ms of waiting. | Anywhere a spinner would be |
| Countdown dial | The leader dial at 40 px with a `spot` sweep over 5000 ms, one pass | Next-chapter countdown in Listen mode, auto-advance |
| Folio counter | `07 / 40` in `type.folio.lg` | Reader, scans |
| Download mark (per chapter) | 16 px square outline 1 px: *not downloaded* `cloud-arrow-down` 16 Regular `ink.45`; *queued* dashed outline `ink.45`; *downloading* the square fills bottom-up in `spot` with progress; *saved* `check-square` Fill `set`; *failed* square outline `proof` with `!`; *paused* two 2 px bars `spot`; *stale* `cloud-arrow-down` in `spot` (download again). Each has a tooltip with the full wording from the inventories (DP7, mobile §6c). | Chapter rows, reader running head |
| Storage meter | 8 px bar in three segments: other apps `ink.30`, ManhwaManiacs `spot`, free `rule.1`; the cap is a 2 px `ink.100` tick above the bar; a `NOTE` kicker line when the cap or the 1.5 GB floor is reached | Downloads, Storage |

### 3.19 Badges

Square boxes, height 16, horizontal padding 4, `type.micro`. Stacked 4 px apart.

| Badge | Visual |
|---|---|
| `NEW` / `3 NEW` / `99+ NEW` | Fill `spot`, text `#000` |
| Status `ONGOING`, `COMPLETED`, `HIATUS`, `CANCELLED`, `UPCOMING` | 1 px `ink.45` outline, text `ink.60` |
| Reading status `READING`, `ON HOLD`, `PLAN`, `DROPPED`, `DONE` | 1 px `ink.100` outline, text `ink.100` (only on the Library wall, never on discovery posters) |
| 18+ certificate | A square 16 × 16 (20 × 20 on feature pages) with a 1 px `proof` outline and `18` in `proof` Archivo `wdth` 62 `wght` 800; never shown when the gate is closed (the content is absent then) |
| `SAVED` | 1 px `set` outline, text `set` |
| `TEXT` (dialogue indexed) | 1 px `ink.45` outline, text `ink.45` |
| `SAVED COPY · 3 H` (stale catalogue) | 1 px `spot` outline, text `spot`, `NOTE` semantics |
| `PICKED` (AI) | 1 px `ink.100` outline, text `ink.100` |
| `SMART`, `SHARED` (collections) | 1 px `ink.45` outline |
| `NOW` (Circle: reading right now) | Fill `ink.100`, text `#000` |
| Count badge (icons, tabs) | Fill `spot`, text `#000` Plex Mono 10, min 16 × 16 |
| Admin, You, Deactivated (members) | `ADMIN` 1 px `ink.100`; `YOU` fill `ink.100` `#000` text; `DEACTIVATED` 1 px `proof` |

### 3.20 Sliders and the scrubber

| Part | Spec |
|---|---|
| Track | 2 px `rule.2`, fill `ink.100` up to the value, step ticks 1 × 6 px `ink.30` under the track when steps ≤ 20 |
| Thumb | A 2 × 20 px vertical `ink.100` bar (a tick mark), 44 × 44 hit area |
| Value | While dragging, a folio flag above the thumb: `#000` box, 1 px `ink.100` border, `type.folio` ("1.25×", "19 px", "−40") |
| Labels | Min and max captions at the ends in `ink.45` where meaningful |

| State | Visual | Motion |
|---|---|---|
| Default | As above | — |
| Hover | Thumb 2 × 24 | 80 ms |
| Pressed / dragging | Thumb 3 × 28, value flag shown; haptic `select` per step (mobile) | Release with `spring.scrub` |
| Focused | Ring around the thumb's hit square; arrow keys step, `Shift+arrow` ×10, `Home`/`End` | — |
| Disabled | Track `rule.1`, thumb `ink.30` | — |
| Loading | n/a | — |
| Error | n/a | — |

The reader scrubber ("the ruler") is §4.14.4; the speed ruler (Listen) is §4.16.4.

### 3.21 Toggles, checkboxes, radios, steppers

| Control | Spec | Motion |
|---|---|---|
| Switch ("slug switch") | 44 × 24 rectangle, 1 px `ink.45` outline, 16 × 16 square knob inset 4 px. Off: knob left, fill `ink.45`, track transparent. On: track fills `spot`, knob right, fill `#000`. The row's label, not the switch, says what it does. | Knob slides 160 ms `set`; while pressed the knob widens to 20 px (a squash, not a bounce); haptic `toggle.on` / `toggle.off` |
| Switch states | Hover: outline `ink.100`. Focus: ring around the track. Disabled: outline `rule.1`, knob `ink.30`. Loading (server-backed switches such as 18+ or notify): knob replaced by a 12 px leader dial, `aria-busy`. Error: outline `proof` for 2000 ms and the switch reverts, with an error line. | — |
| Checkbox | 20 × 20 square, 1 px `ink.45` outline; checked: fill `ink.100` with a `#000` check drawn as a 2 px square-capped path (not an icon glyph); indeterminate: fill `ink.100` with a 10 × 2 `#000` dash | Fill 120 ms |
| Radio | 20 px circle (round allowed), 1 px `ink.45`; selected: 10 px `ink.100` dot | 120 ms |
| Stepper | `−` value `+`: two 36 px `ruled` icon buttons around a `type.folio.lg` value, min width 64; bounds disable the button; hold to repeat every 120 ms after 400 ms | Value digits roll (Folio flip) |

### 3.22 Menus and context menus

| Part | Spec |
|---|---|
| Surface | `paper.2`, 1 px `rule.2` border, radius 0, min width 224, max height 60 vh |
| Item | 40 px (48 phone), leading 20 Regular icon (optional), `type.ui`, trailing shortcut keycap or submenu caret; separators `rule.hair`; destructive items `proof`; checked items a leading `check` |
| Hover / focus | Fill `paper.4` + 2 px `ink.100` left bar |
| Motion | Clip reveal from the anchored edge 200 ms `settle`; exit fade 120 ms |
| Keyboard | Arrows, `Home`/`End`, type-ahead, `Enter`, `Esc`, submenu with `→`/`←` |

**Context menu.** Desktop: right-click opens the menu at the pointer (Base UI `ContextMenu`). Phones: long-press 450 ms opens **Quick look**: the pressed poster dims to 70 % for 120 ms, then a sheet rises whose header match-cuts the poster into a 96 px cover beside the title, kicker and credits, followed by the action list (Open, Continue, Previously on, Add to collection, Favourite, Mark read, Download next 5, Recommend to…, Not for me, Remove from row, Unfollow). Haptic `longpress.open`. Flutter builds it on `onLongPress` + `showModalBottomSheet` (no `super_context_menu`).

### 3.23 Notices: empty, error and offline states

One component, five tones, set like a short article:

| Part | Spec |
|---|---|
| Rule | 3 px `rule.heavy` above, drawn on entrance |
| Kicker | `type.kicker`: `EMPTY SHELF`, `NOTHING HERE YET`, `CORRECTION` (error, in `proof`), `OFFLINE EDITION`, `NOTE` (caution, in `spot`), `SLOW DOWN` (rate limit) |
| Headline | `type.subhead` on phones, `type.headline` at 0.6 scale on desktop; **typed** at 50 ms per character (§6.2) |
| Deck | `type.deck` `ink.60`, max 48ch |
| Actions | Up to two: `primary` + `quiet` |
| Glyph | Optional 32 px Light glyph above the kicker, `ink.45` |
| Placement | Left-aligned on the grid: 6 columns desktop, 4 phone; vertical offset 15 vh when it is the whole screen |
| Rate limit | Deck includes a live countdown folio "Retrying in 12 s" from `Retry-After` |

The global offline case adds "Saved chapters still open." and a `Go to Downloads` action. `503 db_busy` is retried quietly with its `Retry-After`; only after three attempts does a toast say "The server is busy. Your progress is saved on this device and will sync." Nothing ever shows a count or a placeholder for 18+ content that the gate hides.

### 3.24 The 18+ gate: "the certificate"

- **Mark.** `certificate-18`: a square with a 2 px `proof` border and "18" set in Bodoni Moda Roman `wght` 900 in `proof`. Sizes 16 (badges), 20 (feature credits), 160 (the dialog).
- **Certificate dialog** (the only way to open the gate, from Settings → Content **and** from the profile form, so both places share one safeguard): full screen on phones, a 560 dialog on desktop. Layout: the 160 px certificate on the left (desktop) or top (phone); kicker `RESTRICTED · THIS PROFILE ONLY`; headline "Show mature content on {profile}?" (Bodoni Moda); body in Newsreader: "Adult (18+) sources, series, search results and recommendations will appear throughout ManhwaManiacs for this profile. Only continue if you are of legal age where you live. You can turn this off any time."; a checkbox "I am 18 or older"; buttons `Enable 18+` (primary, disabled until checked) and `Cancel` (quiet).
- **Confirm moment.** The certificate's square fills `proof` for 160 ms, the "18" knocks out to `#000`, then settles back to outline (a stamp). Haptic `gate.confirm`, sound `impress` if on. Every mature-gated query root is invalidated, and the next screen re-enters its skeleton.
- **Turning off** needs no confirmation; a toast confirms "18+ content hidden on {profile}".
- **Rating card** (feature page open and reader start for series whose resolved `rating` is `mature`): top-left under the running head, a 20 px certificate + `18+` in `type.kicker` + descriptors from genres in `type.caption` `ink.60` ("Violence · Sexual content"); fades in 400 ms, holds `dur.hold.rating`, fades out 600 ms. Informational only.
- **Per-series override** (`mature_override`): feature page overflow → "Treat as 18+" / "Treat as not 18+" / "Use the source's rating" (radio menu).
- **Absence, never a lock.** Gated content is not drawn at all: no blurred tiles, no "hidden" counts, no locked rows.

### 3.25 Avatars

Circles (sizes 20, 24, 32, 44, 96, 144). Each preset is a field colour with a radial darkening to 60 % black at the rim and a Phosphor Fill glyph at 45 % of the diameter in `ink.100` (≥ 4.5:1 on every field). The 12 existing `avatar_key` values map to a new set:

| Key | Name | Field | Glyph |
|---|---|---|---|
| violet | Matinee | `#6E56CF` | `film-slate` |
| cyan | Newsreel | `#1F8FA8` | `newspaper` |
| rose | Romance | `#B83A56` | `heart` |
| amber | Usher | `#B87A12` | `flashlight` |
| emerald | Critic | `#1E8C60` | `pen-nib` |
| ember | Premiere | `#C24724` | `fire` |
| blade | Swordplay | `#5E6878` | `sword` |
| phantom | Phantom | `#474B94` | `ghost` |
| arcane | Illusionist | `#7D45B8` | `magic-wand` |
| lunar | Late show | `#2B5699` | `moon-stars` |
| star | Marquee | `#A8850F` | `star` |
| reader | Bookworm | `#187C7C` | `book-open-text` |

Selected (picker, form): a 2 px `spot` ring at 3 px offset. 18+ marker on the picker: a 20 px certificate at the avatar's bottom-right. Unknown keys fall back to Matinee.

### 3.26 Keycaps

`type.folio` 12 in a 1 px `ink.30` square box, min 20 × 20, 4 px horizontal padding; Mac glyphs `⌘ ⌥ ⇧` where the platform is Mac. Secondary combos at 60 % opacity.

### 3.27 Masthead block and section header

- **Masthead block** (top of every page): kicker (folio + section, e.g. `No. 02 — YOUR SHELF`) → `type.masthead` title with the letter reveal → deck (`type.deck` `ink.60`, one line of live facts: "212 series · 14 with new chapters") → `rule.oxford` on desktop / `rule.heavy` on phones, drawn after the letters land. Bottom margin 48 (desktop) / 32 (phone). A mood grade (§2.1.6) sits behind the top 30 vh.
- **Section header**: §3.8 header row, also used outside rails (settings sections, stats blocks).

### 3.28 Layout primitives

- `Grid`: resolves the breakpoint's columns, margin and gutter and exposes `span(n)` and `col(i)`; the debug overlay (§2.3.2) draws from it.
- `Measure`: caps a text block's width in `ch` and rounds display blocks to the 4 px baseline (§2.2.2).
- `Spread`: the 5 + 7 column composition with the art's bleed, `blur.bleed` fill, `scrim.gutter`, grain and drift.
- `Credits`: label/value pairs in `type.credit`, two columns on desktop, one on phones, a 1 px `rule.1` column rule between.

### 3.29 Other primitives

- **Content-mode switch**: sidebar version §3.15; on phones a chip `MANGA ▾` in the running head of Library, Discover, Downloads and Index opening a small sheet: kicker `READING MODE`, the typographic toggle, and "One setting for the whole app: library, sources, search, downloads and updates all follow it." Haptic `select`. Hidden entirely when novels are disabled.
- **Pull to refresh ("reprint")**: pulling past the top of a refreshable list reveals a 2 px `spot` rule that grows from the centre outwards with the pull (rubber band c = 0.35) and the caption `PULL TO REPRINT` → `RELEASE TO REPRINT` at the 96 px trigger (haptic `refresh.arm`); on release the rule becomes the indeterminate rule until done. Flutter: `custom_refresh_indicator` 4.0.2 with this builder; web: 60 lines of pointer-event code; desktop web: `r` key and a Refresh item in the page's overflow menu. Not on Downloads (local data).
- **Select-mode bar** (bulk actions): a bottom bar (phone) or a bar under the running head (desktop), `paper.2` with a 1 px `rule.2` top, showing `12 SELECTED` (folio), `Select all 40`, actions as `quiet` buttons with icons (Favourite, Unfavourite, Mark read, Mark unread, Add to collection, Download, Unfollow in `proof`) and `Done`. Running state: `4 OF 12 · 1 FAILED` + a determinate rule + `Stop`. Result line with `Dismiss` and, for destructive runs, `Undo` (re-follows with the saved status, favourite, notify, override and shelf position). Unfollow in bulk asks for a dialog confirmation first.
- **Banner strips** (under the running head): `paper.0` with a 2 px left rule; kicker + one line + actions. Used for: "Nothing followed yet" (first run), staged restore, update available (Android APK), overdue checker (admin).
- **Share card frame**: §5.2.5.
---

## 4. Per-screen specs

### 4.0 Frames, navigation, routes and platform rules

#### 4.0.1 Frames

| Frame | Where | Chrome |
|---|---|---|
| **Bare** | Setup, splash, login, register | No navigation. Masthead and content only. |
| **Takeover** | Profile picker, onboarding, recap title card, The Annual, certificate dialog on phones | Full screen, own close or back control |
| **Desktop** (web ≥ 768) | Every app screen | Contents sidebar (248 / 72 spine) + running head 56 + content on the 12-column grid (8 columns inside 768–1023) |
| **Phone** (iOS, Android, web < 768) | Every app screen | Running head 44 + content on the 4-column grid (tablet grid at 600+) + thumb index 56 |
| **Reader** | Manga reader, read-all | No app chrome; the reader's own running head and folio bar; desktop keeps optional side panels |
| **Page** | Novel reader, Listen full player | No app chrome; everything painted in the paper stock |

Sidebar hidden in the readers; below 500 px viewport height the desktop frame hides the sidebar everywhere.

#### 4.0.2 Navigation map

- **Phone thumb index:** Tonight · Library · Discover · Downloads · Index.
  - *Library* is a hub with contents tabs `SHELF · UPDATES · COLLECTIONS · HISTORY · BOOKMARKS`, each its own route. The unread badge sits on the Library tab (the bell's count is never hidden two levels deep).
  - *Discover* holds search, sources, source catalogues, Picks and dialogue search.
  - *Index* holds the profile, Circle, The Numbers, settings, admin and about.
- **Desktop Contents sidebar:** the same destinations flattened into numbered sections (§3.15).
- **Series pages** are one screen with two renderings (manga *Feature*, novel *Book*), reached by both the follow id route and the source route, so there is exactly one series page per series.

#### 4.0.3 Route contract (`design/contract.json`, both clients)

| ScreenId | Path | Notes |
|---|---|---|
| `setup` | `/setup` | App only |
| `login` / `register` | `/login`, `/register` | |
| `profiles` / `profileNew` / `profileEdit` / `profilesManage` | `/profiles`, `/profiles/new`, `/profiles/:id/edit`, `/profiles/manage` | Mobile `/profiles/create` and `/profiles/edit/:id` kept as aliases |
| `onboarding` | `/welcome?step=1..5` | New profile only |
| `tonight` | `/` | Home |
| `library` | `/library` (`?status&sort&fav&view&q&select`) | `/library/browse` renders the same screen with the toolbar open |
| `feature` | `/sources/:sourceId/series/:seriesKey` | Manga Feature or novel Book by `content_kind` |
| `featureByFollow` | `/library/:followedId` | Resolves the follow row, renders `feature` in place (no redirect flash) |
| `updates` | `/updates` (`?tab=following`) | Library hub tab |
| `collections` / `collection` | `/library/collections`, `/library/collections/:id` | Mobile `/collections…` aliases |
| `history` / `bookmarks` | `/library/history`, `/library/bookmarks` | Library hub tabs |
| `picks` | `/library/recommendations` | §5.1 |
| `numbers` / `annual` | `/library/statistics`, `/library/statistics/annual/:year` | §5.2 |
| `recap` | `/recap/:sourceId/:seriesKey?to=:chapterKey` | §5.1.5 |
| `circle` / `circleMember` | `/circle`, `/circle/:profileId` | §5.3 |
| `discover` | `/search` (`?q&scope=all|library|sources|dialogue|ask`) | |
| `sources` / `source` | `/sources`, `/sources/:sourceId` (`?mode&genre&q`) | |
| `reader` | `/reader/:sourceId/:seriesKey/:chapterKey` (`?page&at&all`) | Mobile `/library/read/…` and `/sources/…/chapters/:chapterId/read` kept as aliases |
| `readAll` | `/read-all/:sourceId/:seriesKey` (`?from&page&at`) | |
| `novel` | `/novels/:sourceId/:seriesKey/:chapterKey` (`?page&para&at&listen=1`) | Mobile `/novels/read/…` alias |
| `downloads` | `/downloads` (`?tab=storage`) | |
| `dialogue` | `/ocr` (`?q`) | Mobile `/ocr/search` alias |
| `index` | `/more` | |
| `settings` | `/settings`, `/settings/:section` | Sections in §4.30 |
| `status` | `/admin/status` | Admin |
| `readerLanding` | `/reader` | |

#### 4.0.4 Transitions every screen inherits

| Navigation | Transition |
|---|---|
| Section change (tab bar, sidebar) | Phone: **Cut** + **Set** + **Folio flip**. Desktop: **Dip** (160 / 40 / 240) + Folio flip. |
| Drill-in from a poster or cutting | **Match cut** (cover → cover) |
| Drill-in without a shared element | **Page** (x 24 px + fade) |
| Back | The reverse of the forward move at 0.7 × duration; match cuts reverse into the originating poster if it is still in the tree, otherwise Page |
| Into either reader | **Column wipe** (§4.14.2) |
| Out of a reader | **Dip** |
| Sheets / dialogs | **Rise** / **Insert** |
| Takeovers (Annual, recap, onboarding) | **Dip** in, **Dip** out |

Web: in-app links use React `<ViewTransition>` with `transitionTypes={['nav-forward' | 'nav-back']}` and `default: "none"`, so a browser or OS back animation never plays twice. The match cut uses `view-transition-name: cover-<sourceId>-<seriesKey>`.

#### 4.0.5 Platform rules

| Topic | iOS | Android | Mobile web | Desktop web |
|---|---|---|---|---|
| Back | Edge swipe (20 pt strip, `swipeable_page_route` 0.4.8 `canOnlySwipeFromEdge: true`); incoming page slides from the edge while the outgoing page drifts 30 % left and dims under `#000` to 0.6; release `spring.release`; commit past 50 % or ≥ 1 width/s | Predictive back via `PredictiveBackFullscreenPageTransitionsBuilder` (a full-screen fade-through reads as a film cut); `android:enableOnBackInvokedCallback="true"`; branch roots return to Tonight, then the system takes over | Browser history; sheets are history entries; no JS edge swipe | Back link in the running head breadcrumb; `Esc` closes the top layer |
| System bars | Status bar light content; home indicator auto-hidden in readers | Status and navigation bars transparent, light icons, edge-to-edge; readers use `immersiveSticky` | `theme-color` `#000000`; PWA `display: standalone`, black startup images for the installed iOS PWA | n/a |
| Scroll physics | `ClampingScrollPhysics` + stretch overscroll (the skin's physics on both OSes) | same | native | native; Lenis 1.3.26 smooth wheel only on Tonight and The Annual, never in readers, lists or under reduced motion |
| Haptics | §2.10 | §2.10 | Android `navigator.vibrate` subset | none |
| Share | `share_plus` 13.3.0 share sheet | same | Web Share API level 2 with files, else download | Download + copy link |
| Hardware keys | iPad keyboard: the web key map through `Shortcuts`/`Actions` | Volume keys page in the reader (opt-in); keyboard map as iOS | external keyboard: web map | full map |
| Text scale | Dynamic Type (§2.2.3) | font scale (§2.2.3) | root font size | browser zoom |

#### 4.0.6 Global web keys (app frame)

| Key | Action |
|---|---|
| `mod+k` | Command palette ("Index", §4.33.1) |
| `mod+b` | Toggle the sidebar spine |
| `?` | Keyboard sheet (§4.33.2) |
| `/` | Focus the page's search field |
| `g` then `1`…`12` / `0` | Jump to a numbered section / Settings (single-key setting) |
| `Esc` | Close the top layer; in readers, the escape order in §4.14.9 |
| `mod+shift+g` | Grid overlay (development builds) |

---

### 4.1 Setup (server URL, iOS and Android only) · mobile S01 · G7

**Hierarchy.** Masthead → question → field → action.

**Phone layout.** Bare frame, 4-column grid. Top 20 vh: the wordmark (masthead lockup, 28 px) with its Oxford rule. Then kicker `FIRST, THE ADDRESS`, headline typed at 50 ms per character: "Where is your library?" (`type.headline`). Deck: "Type the address of your ManhwaManiacs server. It is checked before anything is saved." Field `Server address` (URL keyboard, `type.folio.lg` for the value, placeholder the default URL, submit on enter). Primary `Connect` full width, 48 px. Caption below: "HTTPS is required in release builds."

**Platform deltas.** iOS: `keyboardType: TextInputType.url`, autocorrect off. Android: same, IME action `go`. Web: screen does not exist (the web is served by its own server).

**Signature moment.** On success, the field's underline turns into the Oxford rule of the next screen: the underline thickens to 3 px and slides up to the masthead position (480 ms `turn`) as the login masthead fades in.

**Transitions.** In: from the native splash (§4.2), no animation beyond the typing. Out: the rule move above, then **Dip** to login.

**Gestures.** None beyond the keyboard.

**States.** Default; validating (`Connect` loading, field shows a leader dial, disabled field); error (field error line with the server's message, e.g. "No ManhwaManiacs server answered at this address."); success (check in `set`, 400 ms hold).

---

### 4.2 Splash and pre-roll · mobile S02 · web G2 (AuthPending) · brand §7.4

**Native layer.** Neutral `mm-mark` monogram in `#F3F0E8` on `#000000`, shared with the Glass skin (`flutter_native_splash` 2.4.8; iOS storyboard; Android 12 splash with the mark inside the 192 dp circle). Web server-renders the same mark as inline SVG centred on `#000`.

**Pre-roll ("Press start").** The first Flutter or web frame redraws the neutral mark at the same size and position, then plays the logo reveal in §7.4. The session probe (`GET /auth/me`, 3 s timeout) runs underneath; the reveal lasts `max(probe, 900 ms)` capped at 1400 ms. If the probe is still pending at 1400 ms the masthead holds, and after 2400 ms a 24 px leader dial appears under the Oxford rule with the caption `CONNECTING`. Tap anywhere skips to the hold.

**Warm start** (resumed within 4 h, or any web navigation after the first in a session): the masthead fades in 200 ms and out 200 ms; no letters, no haptic.

**Outcomes.** Signed in with a remembered profile → Tonight (Dip). Signed in without a profile this session → Profile picker. Signed out → Login. Offline with a cached user → Tonight in the offline edition (banner §3.13). Server unreachable and no cache → Login's unreachable state.

**Reduced motion.** Masthead fades in 300 ms, holds until ready, fades out 200 ms.

---

### 4.3 Login · web R1 L1–L9 · mobile S03

**Hierarchy.** Cover lines (who and what) → form → secondary path.

**Desktop layout.** Bare frame on the 12-column grid, split like a magazine cover:
- Columns 1–7: a typographic **cover**. Top: the date line in `type.folio` (`TUESDAY 29 SEPTEMBER 2026 · No. 1`). Middle: the wordmark at masthead size with its Oxford rule. Below it three cover lines in `type.pull`, each revealed by letters in sequence 400 ms apart: "Every source, one shelf." / "Novels, read aloud by thirty-one voices." / "Your year in chapters." No cover images (covers need a session).
- Column rule (1 px `rule.1`) between 7 and 8.
- Columns 8–12: the form, vertically centred. Kicker `SIGN IN`; headline typed: "Welcome back." Server line for context (`type.caption` `ink.45`, "Server: manhwamaniacs.xyz"). Fields `Username` (autofocus) and `Password` (with Show/Hide). Switch row "Keep me signed in" (default on). Primary `Sign in` full width of the column. Error line under the button. Footer: "Need an account? **Create one**" (`link`, only when registration is open).

**Phone layout.** Masthead (28 px) + date line at the top; the three cover lines collapse to one (the first); the form fills the rest; the footer link sits above the keyboard.

**Variants.**
- *Bootstrap* (no accounts): kicker `FIRST ISSUE`, headline "Claim this server.", deck "Create the first account. It becomes the administrator." and the register form inline (§4.4, bootstrap variant).
- *Unreachable*: a `CORRECTION` notice: "We couldn't reach the server." + the API message + `Try again` (refetches bootstrap status) + on phones `Change server address` (quiet, to Setup).

**Platform deltas.** Mobile: tapping the server line copies the full base URL (toast "Copied https://…"). iOS: username field `textContentType.username`, password `.password` (keychain autofill). Android: autofill hints. Web: `autocomplete="username"` / `current-password`.

**Signature moment.** The cover lines setting one after another while the headline types; on a successful sign-in the form column dips while the cover's Oxford rule extends across the whole width (480 ms `settle`), handing off to the picker.

**Transitions.** In: from splash, Dip. Out: to the picker, rule extension then Dip; to Register, Page.

**Gestures.** None. **Keys (web).** `Enter` submits from either field; `Tab` order username → password → Show → switch → Sign in → Create one.

**States.** Signed out mid-session (any 401): the app dips to this screen with the toast "You've been signed out. Sign in to carry on."; resolving (masthead only, leader after 400 ms); normal; pending (`Sign in` loading, fields disabled); invalid credentials ("That username and password don't match." `proof`); account disabled ("This account has been turned off by the owner."); rate limited (`SLOW DOWN` line with countdown); unreachable; already signed in (redirect before paint).

---

### 4.4 Register · web R2 RG1–RG5 · mobile S04

**Layout.** Same cover + form split as Login (desktop), same phone stack. Kicker and headline by variant:
- *Open*: `JOIN` / "Join this library." Footer: "Already have an account? **Sign in**".
- *Bootstrap*: `FIRST ISSUE` / "Claim this server." Button `Create the administrator account`.
- *Invite required*: as Open plus the `Invite code` field ("Ask whoever invited you").
- *Closed*: a notice: kicker `REGISTRATION CLOSED`, headline "This library isn't taking new readers.", deck "Ask the owner to create an account for you, then sign in.", primary `Back to sign in`.

**Fields.** Username (autofocus), Password (helper "At least 8 characters"), Confirm password (live "Passwords don't match." once both have content), Invite code (conditional), Display name (optional, "How your name appears"), Email (optional, validated), switch "Keep me signed in". Primary `Create account`. Server-code errors mapped to copy: `username_taken` "That username is taken.", `invite_code_invalid` "That invite code isn't valid.", `invite_code_required`, `registration_disabled`, `weak_password`, `rate_limited` (countdown).

**Platform deltas.** Mobile shows a back arrow in the running head (to Login); web uses the footer link. Password managers get `new-password`.

**Transitions.** In from Login: Page. Out on success: to the picker (Dip), and the new account lands on "Create your first profile" (§4.5 empty state).

**States.** Resolving, unreachable (`CORRECTION` notice + Try again), each variant, pending, field errors, server errors.

---

### 4.5 Profile picker: "Who's reading tonight?" · web R3 P1–P8 · mobile S05 · G3

**Hierarchy.** Question → cast (profiles) → add → manage → switch account.

**Desktop layout.** Takeover on `#000`. Top: the wordmark small (20 px) left, `Manage` (quiet) and `Switch account` (quiet, signs out after a dialog) right. Centre: headline typed at 50 ms per character, `type.masthead`: "Who's reading tonight?" (time-aware: "this morning" 05:00–11:59, "this afternoon" 12:00–17:59). Below, the cast: up to five 144 px avatars in a centred row, 48 px apart, each with the profile name in `type.subhead` italic and a credit line in `type.caption` `ink.45` ("LAST READ 2 H AGO", or "NEW" for a profile with no sessions). An 18+ profile shows the 20 px certificate at its avatar's bottom-right. "Add profile" is a 144 px circle outlined 1 px `ink.45` with a `plus` 32 Light, label "New profile" (hidden at 5 profiles).

**Phone layout.** Headline 40 px on two lines; profiles in a 2-column grid of 112 px avatars, 32 px row gap; Add as the last cell; Manage in the running head.

**Signature moment: the Iris.** Tapping a profile:
1. Its avatar's ring draws a 2 px `spot` circle clockwise (320 ms `set`); other profiles fade to 20 % and blur 4 px (320 ms).
2. A black **iris** closes on the chosen avatar: `clip-path: circle()` on the whole takeover shrinks from the viewport's diagonal to the avatar's radius (480 ms `turn`); haptic `profile.select` as it lands.
3. The next screen (Tonight, or onboarding for a brand-new profile) opens with an **iris out** from the same point (circle 0 → covering, 560 ms `settle`) while its headline starts typing.
4. If the profile's saved skin is Glass, the restart happens inside the black at step 2's end (stack-decision §2.4), with no confirm and no undo, and Glass's splash plays instead of step 3.
Tap during the iris skips to step 3. Reduced motion: 200 ms cross-fade.

**Profile-scope recovery.** Any `profile_required` or `profile_not_found` answer clears the active profile and lands here with the toast "That profile isn't available any more. Choose another."; switching profiles drops every profile-scoped cache, so the next screen re-enters its skeleton.

**Manage mode.** `Manage` toggles: every avatar gets a `pencil-simple-line` 24 overlay on a 50 % black disc; tapping opens Edit. Long-press (phone) or right-click (desktop) on any profile also opens Edit.

**Transitions.** In: from login (Dip), from the profile chip or Index (Dip). Out: Iris.

**Gestures.** Tap select; long-press edit. **Keys (web).** `←`/`→` between profiles, `Enter` selects, `e` edits the focused profile, `n` new profile, `m` toggles manage.

**States.** Loading (five flicker circles); empty ("Create your first profile." notice: kicker `EMPTY HOUSE`, deck "Profiles keep follows, progress and moods apart for everyone on this account.", primary `New profile`); error with no cached profile (`CORRECTION` notice + Retry); unreachable with a cached profile (headline, deck "The server isn't answering. Continue as {name}, or retry.", a single avatar to continue offline, `Retry`); limit reached (Add hidden; tooltip on Manage "5 profiles is the limit").

---

### 4.6 Profile form and Manage profiles · web PF1–PF8, PM1–PM8 · mobile S06, S07

**Profile form** (new and edit; route `/profiles/new`, `/profiles/:id/edit`; a column panel on desktop, a full page on phones).

- Masthead: kicker `CASTING`, title "New profile" / "Edit {name}".
- Live preview: the 96 px avatar with the chosen mood grade glowing behind it (the grade fills the top 30 vh live).
- `Name`: a big `type.field` input (Bodoni Moda Italic 28–36), max 30 characters with a folio counter `12/30`.
- `Avatar`: a 6 × 2 grid (4 × 3 on phones) of the 12 avatars at 56 px; selected gets the spot ring; each has its name as a tooltip and `aria-label`.
- `Mood`: 7 slug-line chips each preceded by a 10 × 10 square of the grade colour (brightened 3× for visibility); helper "Grades the top of the app while this profile is active. Never the reader."
- `Mature content (18+)`: a switch; turning it on opens the certificate (§3.24) exactly like Settings does.
- `Skin`: a two-option row "Cinematic / Glass" with the caption "Changing it restarts the app when this profile is chosen." (writes `reading_profiles.skin`).
- Actions: `Create profile` / `Save changes` (primary), `Cancel` (quiet). Edit adds a `destructive` `Delete profile` at the bottom, confirmed by a dialog ("Delete {name}? Its library, progress, bookmarks and collections go with it. This can't be undone.").
- States: loading (edit), not found (notice "This profile no longer exists." + Back), save pending, name empty error, `profile_limit_reached`, `invalid_profile_name`, server error.

**Manage profiles** (`/profiles/manage`; reachable from the picker's Manage, Index → Profiles and Settings → Profile & account, so it is reachable on every platform).

- Masthead `Profiles`, deck "Up to five reading profiles on this account."
- List of rows: 44 px avatar, name (`type.title`), caption "{Mood} mood · 18+ on/off", `CURRENT` badge on the active one; trailing `Use` (quiet, instant switch without the iris), edit, delete; drag handle to reorder (`sort_order`).
- `New profile` primary (disabled at 5).
- States: loading (5 greeked rows), error notice, empty notice.

**Transitions.** Page in/out; after saving, back to the previous screen with a toast "Saved {name}".

**Keys (web).** `Enter` saves; `Esc` cancels; in the manage list `Alt+↑/↓` reorders.

---

### 4.7 Onboarding: the first issue (new profile) · new

Shown once per new profile after the iris, skippable at every step (`Skip` quiet in the running head; skipping all lands on Tonight's new-profile state). Route `/welcome?step=n`. A takeover with a folio progress line at the top: `1 / 5` in Plex Mono plus five 24 × 2 rules (filled `spot` for done steps).

| Step | Kicker / headline (typed) | Content | Data |
|---|---|---|---|
| 1 Edition | `YOUR EDITION` / "Pick how the app looks." | Two stills side by side (desktop) or stacked (phone): Cinematic's Tonight and Glass's home, each a looping 26 s drift over a pre-rendered WebP; the current one marked `THIS EDITION`. Choosing Glass here defers the restart to the end of onboarding. | `reading_profiles.skin` |
| 2 Formats | `FORMATS` / "What do you read?" | Four tall typographic tiles `Manhwa`, `Manga`, `Manhua`, `Novels` (novels only when enabled), each a 2:3 plate with a duotone mosaic of 3 popular covers from the sources and the word in Bodoni Moda Italic 32; multi-select with the spot inset frame | taste `formats[]` |
| 3 Genres | `GENRES` / "Tap once to like, twice to love, hold to skip." | **The genre paragraph**: 30–40 genre names set as one justified paragraph of Bodoni Moda Italic 28 (22 on phones), separated by thin spaces. Tap once: `ink.100` + 2 px `spot` underline (like). Tap twice: a `spot.wash` highlighter sweeps behind the word (love). Hold 450 ms: 1 px `proof` strike-through + `ink.30` (skip). Each state is also reachable by a small menu on right-click/long-press for screen readers ("Like, Love, Skip, Clear"). | taste `genres{name: 1|2|-1}` |
| 4 Art style | `ART STYLE` / "Which of these do you like the look of?" | 9 unlabelled panel crops (3 × 3 grid, square) from bundled sample art: full-colour painted webtoon, crisp cel, black-and-white screentone, manhua 3D, sketchy indie, retro 90s, soft pastel, high-contrast noir, chibi. Multi-select with the spot inset frame; each crop has an `aria-label` describing the style. | taste `styles[]` |
| 5 Seeds | `YOUR FIRST ISSUE` / "Choose three or more to start." | A poster wall seeded from steps 2–4 (world recommendations by genre). Each pick inserts 3 similar posters right after it (Set stagger); a folio counter `3 / 3 PICKED` turns `set` at three. Primary `Print my first issue` enables at 3 picks. | follows for picked available titles; `taste.seeds[]` |

**Finish.** `Print my first issue` shows a takeover line typed in `type.masthead`: "Printing issue No. 1…" over a running indeterminate rule while the home feed is fetched; then Dip into Tonight (or the restart into Glass if chosen in step 1).

**Platform deltas.** Phones use a horizontal pager between steps with swipe (the step is committed on Next, not on swipe alone); desktop uses `Next` / `Back` buttons and `→` / `←`.

**States.** Sources unreachable at steps 2 and 5: tiles show typographic plates without covers and step 5 becomes "Follow series later from Discover." with `Finish`. AI unavailable: the taste is saved for later and seeds come from source popularity.

**Backend.** `PUT /profiles/{id}/taste {formats, genres, styles, seeds}` (new; used by the home feed, §5.1.7).

---

### 4.8 Tonight (home) · new AI home · the landing screen · covers LS4–LS5, recently-updated, world recs, stats teaser

Full AI behaviour, recap and states are in §5.1; this is the layout contract.

**Hierarchy.** The cover story (one series, one decision) → Also in this issue (three features) → numbered sections (rails) → the numbers teaser.

**Desktop layout** (12 columns):
1. **Running head** transparent over the spread.
2. **Cover story spread** — height `clamp(560px, 72vh, 820px)`.
   - Columns 1–5 (text): kicker `TONIGHT · No. 184` (the issue number is days since the profile's first recorded session, +1); the **main headline**, typed at 50 ms per character with the spot caret (§6.2), `type.cover` (e.g. "Tonight: chapter 143 of Omniscient Reader."); deck (`type.deck` `ink.60`, the AI one-liner or the synopsis's first sentence); `Credits` (STORY, ART, SOURCE with health mark, STATUS, NEW CHAPTERS); actions: `split` primary `Continue │ CH 143 · p.1`, `secondary` `Previously on…` (only when a recap is possible), `quiet` `Details`.
   - Columns 6–12 (art): the series cover at full spread height, placed against the right edge; the space to its left is the same cover at `blur.bleed`, duotoned to `ambient.duo`; `scrim.gutter` over columns 6–7; grain at 0.06 (overlay blend) on the art only; `scrim.vignette`; **Drift** on the cover. Clicking the art opens the feature page (match cut).
   - A 2 px `spot` progress rule runs along the bottom of the art for the chapter in progress.
3. **Also in this issue** (below the spread, 64 px gap): three **Feature** cards across 4 columns each, e.g. "3 new chapters of *Tower of God*", "Because you finished *Solo Leveling*", "Riya recommends *Lookism*". Kicker per card names the reason (`NEW THIS WEEK`, `BECAUSE YOU READ`, `FROM THE CIRCLE`).
4. **Numbered sections**, each a rail with the folio + H3 letter reveal:
   `01 Continue reading` (cuttings) · `02 New this week` (followed series updated in the last 7 days, NEW badges) · `03 Picked for you` (AI, `why` captions on hover slate) · `04 Because you read {title}` (1–3 rails) · `05 From the Circle` (§5.3) · `06 Most read in the circle` (ranked posters, 18+ gated per viewer) · `07 Sources` (source hubs: 16:9 duotone tiles, source name in `type.subhead`, three newest covers as a strip) · `08 Your genres` (slug line of genre links, weighted by size from `/library/recommendations`) · `09 This week in numbers` (a stat strip: streak flame + days, chapters this week, time read, and `Open The Numbers →`).
5. Footer: a 1 px rule and `type.caption` "Issue No. 184 · compiled 21:04 · Refresh `r`".

**Tablet (768–1023 web, 600–1023 app).** The spread uses 8 columns (text 4, art 4); Also in this issue becomes 2 + 1.

**Phone layout.**
1. Cover: full-bleed cover art 4:5 (max 70 svh) with `scrim.foot` into `ambient.tint`, Drift, grain. Over its lower third: kicker, typed headline in `type.cover` (44/44, up to 3 lines), deck (2 lines).
2. Actions under the art: `split` primary full width; then a row of `secondary` `Previously on` and `quiet` `Details`.
3. Also in this issue: a horizontal pager of three Feature cards at 86 % width with 12 px peek (Embla on web, `PageView` with `viewportFraction: 0.86` in Flutter).
4. Sections 01–09 as rails (3.2 posters), 40 px apart.
5. Pull to reprint.

**Platform deltas.** iOS/Android: the running head is transparent until the cover scrolls away; the status bar stays light. Mobile web: identical, pull to reprint implemented in pointer events. Desktop: dwell on a rail poster for 400 ms swaps the spread's backdrop and ambient colour to that series (**Dissolve**, while the spread is ≥ 30 % in view) without changing the headline.

**Signature moment.** "Front page": the Oxford rule draws under the running head, the cover racks into focus, and the headline types itself with the spot caret while the credits set in reading order. It plays once per day per profile; later visits the same day show everything at rest.

**Transitions.** In: Iris (from picker), Cut (tab), Dip (desktop sidebar), Dip from readers. Out: match cut to feature pages, Column wipe on `Continue`.

**Gestures.** Pull to reprint; long-press posters and cuttings for Quick look; horizontal pager; tap the headline to skip typing.

**States.**
- *Loading*: galley proof of the whole page (headline bars at `type.cover` height, the art plate flickering, rail plates with titles as cards when known). The masthead kicker is live from the start.
- *New profile, nothing read*: headline "Your first issue starts here."; deck "Follow three series and this page fills itself in."; primary `Find something` (to Discover); sections become `Popular on your sources` (source browse "popular" of pinned sources), `Sources`, `Genres`.
- *Caught up everywhere*: headline "Tonight: you're caught up."; deck "Nothing new on your shelf. Here's something else."; the cover story is the top AI pick with `Start │ CH 1`.
- *AI unavailable / not configured / over budget*: the cover story is chosen locally (§5.1.6), the deck is the synopsis, Picked for you becomes `From your shelf` with a `NOTE` line.
- *Offline*: headline "Offline edition."; deck "Only what's saved on this device is here."; sections `Saved on this device` and `Continue (saved chapters)`; everything else hidden.
- *Error*: `CORRECTION` notice with Retry; rails that loaded stay.
- *Stale*: rails whose payload is stale show the `SAVED COPY` badge.

**Keys (web).** `r` reprint; `↓`/`↑` move between sections; rails as §3.8; `c` continues the cover story (Column wipe); `p` opens Previously on; `Enter` on the headline skips typing.

---

### 4.9 Library: the shelf · web R5, R6 (LS1–LS12, LB1–LB26, BA1–BA10) · mobile S08, S09 · M1

One screen holds the shelf and the full browse toolbar, so filtering the library is always one tap away on every platform.

**Hierarchy.** Masthead → hub tabs → toolbar → Continue cuttings → the wall.

**Desktop layout.**
- Masthead: kicker `No. 02 — YOUR SHELF`, title "Library", deck "212 series · 14 with new chapters · 3 favourites" (novels: "38 books on your shelf").
- Hub tabs (sticky): `01 SHELF · 02 UPDATES ³ · 03 COLLECTIONS · 04 HISTORY · 05 BOOKMARKS` (each its own route).
- Toolbar (one line, wraps at 1024): status slug line `ALL · READING · NOT STARTED · COMPLETED · ON HOLD · PLAN TO READ · DROPPED` + `★ FAVOURITES` toggle + `NEW ONLY` toggle; right side: compact search ("Search your shelf", `/`), Sort menu (`Recently updated`, `Recently added`, `Recently read`, `Title A–Z`, `Most unread`, `Manual order`), density segmented (`WALL │ COMPACT │ LIST`, manga only), `Select` (quiet with icon).
- **Continue reading** (only with no filter or search): a row of cuttings (3:2), 4 across on desktop.
- **The wall**: posters with captions below; wall 6 per row at desktop (8 at wide), compact 8 (12), list rows 72 px with 48 × 72 covers and columns for title, status badge, progress `CH 12 OF 40`, new count, last read, favourite star, notify bell.
- Manual order: in `Manual order` sort, posters show a drag handle on hover and can be reordered (writes `sort_order`); `Alt+arrows` moves the focused poster.
- Novels mode: the wall becomes the **book list** (§4.9.1).
- Mobile's cover-size slider (K15) migrates to density: values below 0.85 become `COMPACT`, the rest `WALL`.
- Overflow note when > 200: a caption line "Showing the first 200 of 212 — narrow it with search or a filter."

**Phone layout.** Masthead (40 px) with the content-mode chip in the running head; hub tabs as a horizontally scrolling contents row (swipeable panels); toolbar collapses to: status slug line (scrolling) + a `Filters` quiet button opening a sheet (favourites, new only, sort, density, reading status) + search icon (expands a compact field) + `Select`. Continue: a pager of cuttings at 86 %. Wall: 3 columns (tablet 5), captions below. Pull to reprint.

**Card behaviour (all).** Poster tap → feature page (match cut). Hover (desktop) reveals favourite star and notify bell as `on-art` icon buttons at the top-right. Long-press/right-click → Quick look with Open, Continue, Favourite, Status ▸, Notify, Add to collection, Download next 5, Recommend to…, Remove from library ("Your reading progress is kept", toast with Undo that restores favourite, status, notify, override and position).

**Select mode** (LB14, LB18, BA*): `Select` or `x` enters it; tap toggles; Shift-click selects a range; `mod+a` selects visible. The select-mode bar (§3.29) offers Favourite, Unfavourite, Mark read, Mark unread, Set status ▸, Add to collection, Download next 5, Unfollow (dialog first). Runs with concurrency 4, shows progress and a result line with Undo.

**Signature moment.** Filter changes are **Cuts**: the wall swaps instantly and the new posters run **Set** in reading order, so filtering feels like flipping to another page of the same magazine.

**Transitions.** In: Cut/Dip. Out: match cut to feature; Column wipe from cuttings.

**Keys (web).** `/` search; `h j k l` and arrows move in the wall; `Enter` open; `x` select mode; `Space` toggles the focused poster in select mode; `f` favourite focused; `1`–`7` status filters; `s` cycles sort; `v` cycles density.

**States.** Loading (masthead live, 12/24/8 flicker plates by density); empty (`EMPTY SHELF`: "Nothing on your shelf yet." / "Follow a series from Discover and it lands here." + `Find something`); filtered empty (`NOTHING MATCHES`: "No series match these filters." + `Clear filters`); search empty; offline (the offline edition shows saved series only with a banner); error (`CORRECTION` + Retry); page-load error after data (a caption line above the wall with Retry).

#### 4.9.1 The book list (novels mode, used everywhere novels are listed)

Rows 112 px on desktop in two columns with a 1 px column rule; one column on phones. Each row: a 56 × 84 plate (square-cornered, 1 px `rule.2` border; a Bodoni Moda initial on `paper.1` when there is no cover) → title in Bodoni Moda Italic 20 → byline "by {author}" (`type.body.italic` `ink.60`) → credits `412 CHAPTERS · ONGOING · NOVELARCHIVE` → blurb (Newsreader 15, 2 lines, `ink.60`) → note (`42% · CH 212` in `spot` folio, or the reading status). Select mode adds a leading checkbox. States as §3.16. Covers NS1–NS6.

---

### 4.10 Updates · web R22 UP1–UP8 · mobile S23 · G39

**Hierarchy.** Masthead → the check → new chapters by series → following list (tab).

**Layout (desktop and phone share the order; desktop uses 8 of 12 columns plus a 4-column aside).**
- Hub tab `02 UPDATES` active. Masthead kicker `No. 03 — STOP PRESS`, title "Updates", deck "14 new chapters across 6 series · last checked 12 min ago · checking every 30 min" (the deck is the settings summary; tapping it opens Settings → Notifications for admins, or shows a sheet with the schedule for others).
- Actions: primary `Check now` (loading state shows "Checking 212 series…"; for admins the run is polled through `GET /updates/runs/{id}` and the deck updates live "Checked 180 of 212 · 3 new"; for others the unread count is re-polled at 3, 5 and 7 s); secondary `Mark all read` (becomes `Mark all manga read` / `Mark all novels read` by content mode; disabled with nothing unread).
- Contents tabs: `NEW ¹⁴ · FOLLOWING ²¹²`.
- **NEW**: notifications grouped by day (date rule `TODAY`, `YESTERDAY`, `MONDAY 28 SEPTEMBER`), then by series: a 48 × 72 cover, series title (`type.title`), `NEW` count badge, the new chapter folios as a slug line (`CH 141 · CH 142 · CH 143`, each a link), source credit and time. Row actions: `Read from 141` (split, column wipe), `Mark read` (quiet). Read rows fade to `ink.45`. Swipe left on phones: Mark read.
- **FOLLOWING**: the followed series as rows: cover, title, source, "Checked 12 min ago" / "Not checked yet", notify bell toggle, `Check this series` (per-series `POST /updates/followed/{id}/check`) in the overflow, `Unfollow` (quiet `proof`, toast with Undo).
- Aside (desktop, admin): "Recent checks" as a credits list: trigger · status · series · new · started; empty "No check runs yet."
- A reserved **push prompt** (ships only with push support): a banner strip "Get a notice the moment a chapter lands?" with `Turn on` and `Not now`.

**Phone.** One column; the admin aside moves to Settings → Notifications; a group row swipes left to `Mark read` (flat `ink.100` slab); pull to reprint reloads the list (it does not start a server check; `Check now` does). **Platform deltas.** iOS and Android: haptic `tap.primary` on Check now and `success` when the check finds chapters; mobile web the same without haptics; desktop adds the keys below and the aside.

**Signature moment.** New chapter folios type themselves in (50 ms per character) the first time a fresh notification appears after a check.

**Transitions.** In: hub tab Cut; from the stop-press banner (§4.33.3), Page. Out: Column wipe to the reader; match cut to the feature page from covers.

**Keys (web).** `r` check now; `j`/`k` move between series groups; `Enter` reads the focused group; `m` marks it read; `shift+m` marks all read.

**States.** Loading (3 greeked groups); empty (`NOTHING NEW`: "No new chapters yet." / "Follow a series and this fills in the moment a chapter lands." + `Find something`); check already running (`409`: caption "A check is already running."); offline ("Updates need a connection to check." notice, cached list shown read-only); error; rate limited.

---

### 4.11 Collections and collection detail · web R8, R9 (CO1–CO10, CD1–CD12) · mobile S24, S25

**Collections (`/library/collections`).**
- Hub tab `03 COLLECTIONS`. Masthead kicker `No. 06 — SHELVES`, title "Collections", deck "9 shelves · 2 shared".
- Toolbar: compact search ("Search shelves"), sort menu (`Name A–Z`, `Most series`, `Recently created`, `Custom order`), primary `New shelf`.
- Grid of **collection plates** (§3.6): 3 per row desktop (4 at wide), 1 per row on phones (16:9 full width). `SMART` and `SHARED` badges; shared plates show member avatars.
- Custom order: drag plates (writes `sort_order`).
- **New shelf** dialog: `Name` (big field), `Description`, a switch `Smart shelf` which reveals rule chips (client-side rules over library rows: *status is* ▸, *favourite*, *new chapters ≥* n, *format* ▸, *unfinished novels*, combined with AND), and `Share with the circle` (§5.3.5). Actions `Create` / `Cancel`.
- States: loading (4 plates), empty (`NO SHELVES YET`: "Group series by theme, mood or reading plan." + `New shelf`), no search match, offline, error.

**Collection detail (`/library/collections/:id`).**
- Header spread: the duotone mosaic across the full width at 3:1 (desktop) / 16:9 (phone) with `scrim.foot`; kicker `SHELF · 24 SERIES`, name in `type.masthead`, description deck, credits (`SMART RULES: READING · 3+ NEW`, `SHARED WITH: RIYA, ARJUN`).
- Actions: `Add series` (secondary; a sheet/panel listing followed series not in the shelf with search, 48 × 72 covers, tap adds with a stamp haptic; "No series available." when all are in), `Edit` (dialog: name, description, smart rules), `Share` (Circle), `Reorder` (toggle), overflow `Delete shelf` (dialog "The series stay in your library.").
- Member wall: posters with captions; in select mode or via long-press, `Remove from shelf` (dialog with the explainer "It stays in your library."). Members are joined to library rows for titles and covers; orphans (no longer followed) show a title card and the caption `NO LONGER FOLLOWED`.
- Smart shelves have no Add/Remove; their rules are edited instead, and the wall updates live (Cut + Set).
- States: loading (spread plate + 6 posters), empty ("This shelf is empty." + `Add series`), mode mismatch ("Everything on this shelf is a novel. Switch to Novels to see it." + `Switch`), error (+ `Back to collections`), not found.

**Phone.** Plates run full width at 16:9, 16 px apart; the toolbar collapses to a search icon (expands a compact field) and a `Sort` sheet; `New shelf` sits under the masthead as a full-width secondary. Detail header 16:9; member wall 3 columns; `Reorder` uses long-press drag (`flutter_reorderable_grid_view` 5.7.0 on Flutter, Motion `Reorder` on web). **Platform deltas.** Android predictive back from detail uses the full-screen fade-through instead of the reverse match cut; iOS edge swipe reverses the match cut with the finger.

**Transitions.** Plate → detail: match cut of the mosaic into the header. **Keys (web).** `n` new shelf; `/` search; grid keys; `e` edit; `a` add series; `Delete` removes the focused member (dialog).

---

### 4.12 History · web R10 (RH1–RH5) · mobile S13

- Hub tab `04 HISTORY`. Masthead kicker `No. 07 — THE LOG`, title "History", deck "What you've been reading, most recent first."
- Contents tabs: `BY SERIES · BY CHAPTER` (`collapse=series` / `none`).
- **By series**: a log grouped by day with date rules; each row: time in the left margin (`type.folio` `ink.45`, "21:04") → 40 × 60 cover → title → caption `CH 142 · p.12 OF 40` (novels `42% IN`) → 2 px progress rule under the caption → trailing `Continue` (split sm, `p.12`) or `Next │ CH 143` for finished chapters (resolves the next chapter from the chapter list, busy state on the button, falls back to the feature page).
- **By chapter**: the same log, one row per chapter read.
- Desktop: the log spans 8 columns; a 4-column aside shows "This week" (chapters, time) from statistics.
- Pagination: `Load earlier` quiet button (offset + 50) at the end; no infinite scroll (a log reads better with an explicit end).
- **States.** Loading (8 greeked rows), empty (`NOTHING READ YET`: "Open a chapter and it shows up here." + `Go to library`), offline (notice), error.
- **Phone.** The log runs full width with a 40 px time margin; the aside is dropped; `Continue` becomes an icon-plus-folio button (`play` + `p.12`) at the row's end; pull to reprint. **Platform deltas.** None beyond the shared rules (§4.0.5); desktop adds keys.
- **Transitions.** Cut in; Column wipe on Continue; match cut on the cover.
- **Keys (web).** `j`/`k` rows, `Enter` continue, `o` open series, `t` toggles the view.

---

### 4.13 Bookmarks: marked passages · web R11 (BM1–BM5) · mobile S14

- Hub tab `05 BOOKMARKS`. Masthead kicker `No. 08 — MARKED PASSAGES`, title "Bookmarks", deck "Exact places you marked, in both readers."
- Filter: a compact select "All series ▾" (series with bookmarks) and the content mode.
- Grouped by series (a subhead per series with its cover at 32 × 48): each bookmark is a **marginal note**: folio `CH 14 · 62% IN` (manga: `CH 14 · PAGE 7`), for novels the snippet as a pull quote in Newsreader italic with a 2 px `spot` left rule, the user's note in `type.body` (or a quiet `Add a note`), saved date caption, the stale note in `info` ("The text here changed. This opens at the nearest spot.").
- Actions per bookmark: tap → the right reader at `?page=&at=` or `?para=&at=` (Column wipe); `Edit note` (inline textarea, ruled); `Remove` (quiet; toast "Bookmark removed" with Undo, 8 s).
- Mobile flushes the bookmark outbox before loading; a caption "Synced 3 bookmarks" appears after a flush.
- **States.** Loading (5 greeked notes), empty (`NO MARKS YET`: "Press B while reading, or tap the bookmark in the reader." + `Go to library`), offline (local store shown, caption "Changes sync when you're back online"), error.
- **Phone.** Groups full width; a note swipes left to `Remove` (with Undo); long-press opens Edit note / Remove / Open series. **Platform deltas.** Mobile reads from the offline store first and syncs through the bookmark outbox; web reads the server list. Desktop shows notes in two columns with a column rule at wide widths.
- **Keys (web).** `j`/`k`, `Enter` open, `e` edit note, `Delete` remove.
---

### 4.14 Manga reader: webtoon strip, paged, double, read-all · web R19, R20 (RD1–RD42) · mobile S15, S19 · §6a

The reader is the part of the app where Programme gets out of the way: no grid is visible, no serif is on screen while reading, and the chrome is two thin bands of type over scrims. The reader engine (feed, restore, extents, prefetch, progress, auto-scroll, taps) is shared per client (`features/reader/engine/`, stack-decision §2.3); everything below is the Cinematic chrome built on its `chromeBuilder` slot.

#### 4.14.1 Frame and layout

| Platform | Layout |
|---|---|
| Desktop web | Canvas `#000` (or the chosen ground). The strip column is `clamp(480px, 46vw, 860px)` wide and centred; page images are requested at the snapped width ≥ column × DPR (800 px sources pass through). Two optional **side panels** (§4.14.12), each 3 columns (min 320 px), toggled with `[` and `]`, remembered per profile. With both open the strip keeps the middle 6 columns. |
| Tablet (web 768–1023, app 600+) | Strip column 100 % up to 720 px, centred; side panels open as column panels over the page |
| Phone (iOS, Android, mobile web) | Strip edge to edge; side margin preset 0 / 5 / 10 / 15 / 20 / 25 % (default 0) |
| Landscape phone | Strip column 70 % of the width, centred; running head hidden, folio bar only on tap |

Mood gutters: the area outside the strip on desktop takes the page tint (§5.4.4) when page-tinted chrome is on, else the ground colour; the profile's mood grade never reaches the reader.

#### 4.14.2 Entry: the Column wipe

Entering either reader from anywhere (Continue, a chapter row, a bookmark, history, Updates, dialogue results, Downloads) plays the grid as a shutter:

1. **Close.** The viewport is divided into the current grid's columns including gutters and margins (4 blades on phones, 8 on tablets, 12 on desktop; blade edges land on column edges). Each blade is a `#000` strip that scales `scaleY 0 → 1` from the **top** edge, 200 ms `settle`, staggered 16 ms left → right. Desktop: 200 + 11 × 16 = 376 ms; phone: 200 + 3 × 16 = 248 ms.
2. **Hold** on black 40 ms. The route swaps underneath. The manifest and the first two pages were prefetched on hover, focus or press of the entry control, so the first page is usually decoded here. Haptic `reader.enter` as the last blade lands; sound `wipe` if on.
3. **Open.** Blades retract `scaleY 1 → 0` toward the **bottom** edge, 280 ms `settle`, staggered 16 ms left → right, revealing page one (or the saved page). Desktop 456 ms; phone 328 ms.
4. The running head and folio bar are visible for the first 800 ms (orientation), then follow the auto-hide rules. For an 18+ series the rating card (§3.24) appears.

Tap during the wipe jumps to open in 120 ms. If the first page is not decoded after the hold, the blades still open and the page shows its galley plate (§4.14.11). Reduced motion: a 200 ms cross-fade through black. Web: a fixed overlay of N `<div>` blades animated with Motion (`transform` only); Flutter: a custom `PageRouteBuilder` whose `transitionsBuilder` paints N `Transform(scaleY)` blades from `Interval`s of the route animation (route duration 900 ms desktop-equivalent, 620 ms phone).

Exit (back, `Esc` at the end of the escape order, `s`): **Dip** (160 / 40 / 240), never a wipe, so leaving is quiet.

#### 4.14.3 Chrome: running head and folio bar

**Running head** (top, over `scrim.head`; 56 px desktop, 44 + status inset phone):
- Leading: back (`arrow-left` 24 Light).
- Title: series title in `type.nav` `ink.60` + ` · ` + `CH 142` in `type.folio` `spot` (read-all adds `· 12 OF 201`). Tapping or clicking the title opens the feature page.
- Trailing: download mark for this chapter (§3.18; tap cycles Download → saving `12/40 · 30%` with cancel → `SAVED`; tap again asks "Remove from this device?" inline and reverts after 4 s; warn states `Save again` (stale) and `Resume 12/40` (incomplete)); bookmark (`bookmark-simple`; Fill + spot rule when this page is bookmarked); on desktop the panel toggles `sidebar-simple` and `note-pencil`; settings (`sliders-horizontal`).
- An `OFFLINE EDITION` micro badge beside the title when the chapter is read from disk.

**Folio bar** (bottom, over `scrim.sole`; 64 px + bottom inset):
- Left: previous chapter (`skip-back` + `141` folio; disabled at the first chapter; in the strip it scrolls to the loaded previous chapter instead of navigating).
- Centre: **the ruler** (§4.14.4), full width between the chapter buttons.
- Under the ruler (one line): `07 / 40` (`type.folio.lg`) · `6 MIN LEFT` (`type.caption` `ink.45`, shown only after 2 minutes of pace samples) · chapter title in `type.caption` (desktop).
- Right: next chapter (`143` + `skip-forward`), auto-scroll (`play` with the strip glyph, strip only; filled + spot rule when running, with its speed folio `1.0×`), and on desktop fullscreen (`corners-out`).

**Auto-hide** (shared engine thresholds):
- Hide after a cumulative downward scroll ≥ 24 px since the last direction change; show after a cumulative upward scroll ≥ 56 px, at chapter end, on a centre tap, on pointer movement into the top 72 px or bottom 96 px (desktop), on any key, or on focus entering the chrome.
- After a tap or hover opened the chrome, hide after 3000 ms idle (paused while a sheet, menu or the ruler is in use).
- Never hide during the first 800 ms of a chapter.
- Motion: in 240 ms `settle` (fade + 8 px slide from its edge); out 160 ms `lift`. Hidden chrome is `visibility: hidden` / `Offstage` so it leaves the tab order.
- **Micro progress**: a 2 px `spot` rule at the very bottom of the screen shows chapter progress while the chrome is hidden.

**Cinema mode** (`c`, or the settings sheet): the chrome hides after 3000 ms idle and the micro progress disappears; tap, pointer move or `c` brings chrome back; `Esc` leaves cinema before leaving the reader.

**Lock mode** (setting "Lock reader controls"): the reader opens locked; taps only register in the centre (20–80 % × 15–85 %); five taps within 2 s each unlock (toast "Controls unlocked", haptic `reader.unlock`).

**Page tint** (§5.4.4): when on, the scrims' end colour mixes 25 % of the current page tint and the ruler fill takes the tint's light variant.

#### 4.14.4 The ruler (scrubber)

- Track: 2 px `rule.2`, full width between the chapter buttons; the played part is `ink.100`.
- Page ticks: 1 × 4 px `ink.30` under the track per page (dropped when there are more than 120 pages).
- Read-all: chapter boundaries are 2 px gaps in the track, with the chapter folio shown on hover.
- Bookmarks: 2 × 8 px `spot` marks standing above the track at their positions.
- Thumb: a 2 × 16 px `ink.100` vertical tick; grows to 3 × 24 while dragging; a folio flag above it reads `p. 18`; desktop hover shows a 120 px-wide page preview above the pointer from the cached page image, captioned `p. 18 / 40`.
- Touch: the hit area is 44 px tall; dragging seeks live (RTL mirrors the direction); release settles with `spring.scrub`.
- Haptics: `scrub.tick` per page, `scrub.boundary` at chapter boundaries (read-all).
- Accessibility: a native range underneath (`aria-valuetext="Page 18 of 40"`), arrow keys step one page, `Shift+arrow` ten; disabled for single-page chapters.
- Jump to page: clicking the `07 / 40` folio turns it into a number field (Enter jumps, Esc cancels); `g` opens it from the keyboard.

#### 4.14.5 Strip mode (webtoon, default)

- Pages seamless, no gap (setting "Gap between pages" adds 8 px of ground colour), no radius, no shadow.
- Each page reserves its exact box from manifest `width/height` before the image lands (fallback 2:3 until decoded); the engine corrects heights with scroll compensation so the page under the reader never jumps.
- **Chapter seam** (continuous feed): a quiet 96 px band of ground: 1 px `rule.1` rules either side of `CH 143 · THE RETURN` in `type.kicker` `ink.45`. Crossing it gives haptic `scrub.boundary`.
- **Read-all divider**: a 48 px band with `142 → 143` in `type.folio` between hairlines; no card, no pause ("without feeling it").
- Top of the strip (a previous chapter exists): a slim band `↑ CH 141 · keep scrolling up`, loading state `Loading CH 141…` with a 16 px leader dial; over-scrolling up 140 px loads it.
- **Zoom**: pinch 1–3× (Flutter `ScaleGestureRecognizer` driving the engine's zoom; web `@use-gesture/react` 10.3.1 `usePinch` with `touch-action: pan-y`), double tap toggles 1× ⇄ 2× at the tap point in 240 ms `settle` (haptic `zoom.snap`), `Ctrl`/`⌘` + wheel zooms around the pointer, `=` / `-` / `0` keys. The zoom level shows as a folio chip `200%` top-centre for 1200 ms. Plain wheel always scrolls.
- Tap behaviour: the whole screen toggles chrome (default). Opt-in "Tap to scroll": top third plus left-middle scroll back, bottom third plus right-middle scroll forward 75 % of the viewport in 300 ms `cubic-bezier(0.5, 1, 0.89, 1)`, centre toggles chrome.
- Horizontal swipe ≥ 72 px (phones, on by default in strip mode) changes chapter: the page follows the finger with a rubber band and a `CH 143 →` folio slides in from the edge; release past the threshold commits (haptic `chapter.next`, Dip to the neighbour).
- Brightness HUD: a vertical swipe along the left 12 % edge changes brightness (−75 to 100); a 6 × 140 px HUD (1 px `ink.100` outline, `ink.100` fill from the bottom, `sun-dim` glyph, folio value; below 0 it reads `NIGHT −40`) fades 600 ms after release.
- Auto-scroll speed HUD: while auto-scroll runs, the right 12 % edge adjusts speed with the same HUD reading `1.5×`.

#### 4.14.6 Chapter end: the credits

When the last page of a chapter scrolls up past 60 % of the viewport, the **credits** follow (haptic `chapter.complete`, sound `done`; the engine marks the chapter complete):

1. 96 px of ground.
2. `End of chapter 142` in `type.section` (Bodoni Moda Italic) with the letter reveal, then a credits block: `SERIES  Omniscient Reader · SOURCE  MangaDex · READ IN  11 MIN · PAGES  40`.
3. **Reactions** (§5.3.3): five square stamps in a row, each with its count and the reacting readers' 20 px avatars.
4. **Coming up** card (when a next chapter exists and the strip is not already continuing seamlessly): a 16:9 panel of the next chapter's first page blurred 24 px and duotoned to `ambient.duo`, with the sharp page as an inset 3:4 thumbnail on the left; kicker `COMING UP`; headline `Chapter 143` (`type.headline`); deck = chapter title; folio `38 PAGES · ~6 MIN`; primary `Read chapter 143` (48 px).
5. **Pull to continue**: below the card, a 150 px (phone) / 300 px (desktop) region with a 2 px `spot` rule that fills from the left as the reader pulls; at full it commits (haptic `chapter.next`), a 250 ms fade through black follows, and the new chapter's title is typed at 50 ms per character as a caption top-left (`CH 143 — The Return`), fading after 2 s.

Continuous strip (default): the next chapter is already stitched below, so step 4–5 are replaced by the chapter seam and the credits are compact (the end title on one line + reactions), and reading simply continues. With **Auto next chapter** off, the credits end the feed and `Read chapter 143` is required.

End states:
- **Caught up**: a notice: kicker `CAUGHT UP`, headline "That's everything so far.", deck "MangaDex has published 142 chapters. You'll get a notice when 143 lands." + `Notify me` switch (follow bell) + `More like this` rail + `Back to the series`.
- **Next failed**: `CORRECTION` notice "Chapter 143 didn't load." + `Try again` + `Open it on its own →`. Automatic retries back off from 2 s to 30 s meanwhile.
- **Further on another device** (progress `advanced: false`): a toast "You're further ahead on another device (CH 145, p.3). Jump there?" with `Jump`.

#### 4.14.7 Paged modes: single and double

- Stage: the page fits by the chosen fit (Width, Height, Original) within the viewport minus 24 px; ground colour around.
- **Double**: two pages side by side with an 8 px ground gutter and a 1 px `rule.1` centre line (the magazine's gutter); RTL mirrors display order; a wide page (landscape spread) occupies both slots alone.
- **Page turn**: `Cut` (0 ms, default, a film cut), `Slide` (the incoming page pushes in from its reading side, 280 ms `settle`; finger releases use `spring.release`), or `Fade` (160 ms). Haptic `page.turn`. Sound `turn` if on.
- **Tap zones**: 30 / 40 / 30; default previous / chrome / next, mirrored for RTL until the user sets their own. The first time a layout is used, the zones are painted as three labelled bands (`BACK · MENU · NEXT`, 1 px `ink.30` outlines, labels in `type.kicker`) that fade out over 1000 ms after 1500 ms; they reappear whenever the zone layout changes.
- Wheel: one page per wheel gesture with a 200 ms idle reset.
- Swipe: horizontal swipe turns pages (reading direction aware), with the page tracking the finger.
- Zoom: `InteractiveViewer` (Flutter) / `usePinch` (web), 1–3×; while zoomed, swipes pan and the edge-swipe back is disabled.
- Preload: 3 pages ahead.
- Chapter end in paged mode: after the last page, one more "page" holds the credits (§4.14.6) centred on the stage.

#### 4.14.8 Reading setup (the reader settings sheet)

A `[0.5, 0.92]` sheet on phones (the page stays live above at the half detent) and a right column panel on desktop. Kicker `READING SETUP`, title = the series title. Contents tabs:

| Tab | Controls (key, range, default, scope) |
|---|---|
| `LAYOUT` | Layout segmented `STRIP │ SINGLE │ DOUBLE │ GUIDED` (K35, per series, default strip; hidden in read-all); Direction `LEFT TO RIGHT │ RIGHT TO LEFT` with captions "Webtoons and western comics" / "Manga" (K37, per series); Fit `WIDTH │ HEIGHT │ ORIGINAL` (K36; Height and Original disabled in strip with tooltips); Side margin presets `0 · 5 · 10 · 15 · 20 · 25 %` (phones) or strip width slider 480–860 px (desktop); Zoom stepper 50–300 % step 10 with reset (K38); Gap between pages switch (K29, strip only); Page turn `CUT │ SLIDE │ FADE` (paged only, replaces K33) |
| `IMAGE` | Brightness slider −75 … 100 (negative values draw a black overlay at `|v|/100`; migrates K31 dimmer and mobile K09); Warmth 0–100 (K32 / K10); Colour `NORMAL │ SEPIA │ GREY` (K12); Ground `BLACK │ INK │ SLATE` (K11 mapped §2.1.6) |
| `CONTROLS` | Tap zones: three segmented rows `LEFT / CENTRE / RIGHT` × `PREVIOUS │ MENU │ NEXT` + `Reset` + `Show zones` (K34 / K03); Strip taps `MENU │ TAP TO SCROLL`; Swipe sideways to change chapter (switch); Cinema mode (K30); Keep screen awake (K05, app); Auto next chapter (K06); Lock controls (K07, app); Volume keys turn pages (K08, Android); Refresh rate `AUTO │ 30 │ 60 │ 90 │ 120` (K04, Android) |
| `AMBIENT` | Auto-scroll: play/pause + speed ruler 0.5–3.0× in 0.05 steps (60 px/s at 1×, per series K39 migrated from 1–10 → 0.5–3.0); "Resume after I let go" switch (800 ms); Soundscape picker + volume (§5.4.2); Page-tinted chrome switch (§5.4.4); Guided view options (§5.4.3) |

Footer: `Shortcuts` (desktop, opens the keyboard sheet), `Reset reader settings` (quiet; dialog "Restore every reader setting to its default?"). Changes apply live; closing the sheet also hides the chrome.

#### 4.14.9 Keys (web and hardware keyboards)

| Key | Action |
|---|---|
| `→` / `d`, `←` / `a` | Turn page by reading direction |
| `j` / `k` | Next / previous page |
| `Space` / `Shift+Space` | Forward / back one screen |
| `Home` / `End` | First / last page |
| `h` / `l`, `Ctrl+Shift+←/→` | Previous / next chapter |
| `g` | Go to page (opens the folio field) |
| `f` | Fullscreen (web) |
| `c` | Cinema mode |
| `m` | Show or hide chrome |
| `p` | Auto-scroll play / pause (strip) |
| `<` / `>` | Auto-scroll slower / faster by 0.25× |
| `b` | Bookmark this spot |
| `s` | Series page |
| `,` | Reading setup |
| `[` / `]` | Toggle the left / right side panel |
| `=` `+` / `-` / `0` | Zoom in / out / reset |
| `w` / `v` / `r` | Strip / single / right-to-left paged (Komga letters kept) |
| `u` | Guided view on / off |
| `?` | Keyboard sheet |
| `Esc` | Close sheet or panel → leave fullscreen → leave cinema → exit to the series page |
| Middle-click | Autoscroll anchor (12 px dead zone, 10 px/s per px, max 4000 px/s) |

A "Single-key shortcuts" setting (Settings → Keyboard, default on) disables every binding without a modifier.

#### 4.14.10 Gestures by platform

| Gesture | iOS | Android | Mobile web | Desktop web |
|---|---|---|---|---|
| Scroll | Native, clamping + stretch | same | native, `overscroll-behavior-y: contain` | wheel, trackpad; no smooth-scroll library |
| Tap | Chrome toggle / zones | same | same | click zones |
| Double tap | Zoom 1 ⇄ 2× | same | 300 ms / 24 px detector | double-click |
| Pinch | 1–3× | same | `usePinch` | `Ctrl`+wheel, Safari `GestureEvent` |
| Long-press 450 ms on a page | Page actions sheet (§4.14.13) | same | same | right-click menu |
| Horizontal swipe (strip) | Chapter change | same | same | — (`h`/`l`) |
| Left-edge vertical swipe | Brightness HUD | same | same | — (setup sheet) |
| Right-edge vertical swipe | Auto-scroll speed while running | same | same | — (`<` `>`) |
| Back | 20 pt edge swipe (disabled when zoomed or in paged mode) | Predictive back (Dip) | browser back | `Esc` order |
| Volume keys | — | Page turn (opt-in) | — | — |

#### 4.14.11 States

| State | Presentation |
|---|---|
| Loading chapter | Three galley page plates at the manifest's (or 2:3) aspect in the strip column, the running head visible with `LOADING CH 142`, a 24 px leader dial after 400 ms |
| Page placeholder | The page's reserved box in the ground colour, no spinner |
| Broken page | Inside the page box: kicker `PAGE 18 DIDN'T LOAD`, `quiet` `Retry` (refetches that image only), and the reason in `type.caption` when known |
| No pages | Notice: "This chapter has no pages." + `Back to the series` |
| Error | `CORRECTION` notice with the API message + `Try again` + `Go to the series`; read-all list failure: "This series' chapter list didn't come through, so there's nothing to read through." |
| Offline | Reads from disk silently; `OFFLINE EDITION` badge; no neighbour loading (seam shows "Next chapter isn't saved on this device" with `Back to Downloads`) |
| Rate limited | A band at the top of the unloaded pages: `SLOW DOWN — the source asked us to wait. Retrying in 12 s.` with a live folio countdown |
| Stale bookmark | Toast "That page moved. Opened at the nearest one." (5200 ms) |
| Bookmark saved / failed | Toast "Marked page 7 — 42% of the chapter." / "Couldn't save that spot." (`proof`) |
| Further on another device | §4.14.6 toast |
| 18+ series | Rating card at start |

#### 4.14.12 Side panels (desktop web; column panels on tablets)

- **Left, "Contents"** (`[`): the chapter list as schedule rows (§3.16) with the current chapter marked (`spot.wash` band), newest/oldest toggle, go-to field, read state and download marks; clicking a chapter jumps (in read-all it scrolls; otherwise Dip).
- **Right, "Margins"** (`]`), contents tabs:
  - `NOTES`: this chapter's bookmarks with their notes, `Add a note to this page`.
  - `DIALOGUE`: when the chapter has OCR text (`GET /ocr/chapter`), the transcript as subtitle lines per page (`p. 12` folio + lines in `type.body`); hovering a line outlines its bubble on the page with a 2 px `spot` frame; clicking scrolls there and pulses the frame twice (480 ms each). When there is no text: "Dialogue isn't indexed for this chapter." + (app only, for a downloaded chapter) `Scan it on your phone` hint.
  - `CIRCLE`: who in the circle read this chapter, their reactions, and `Recommend this series…`.
- Panels are `paper.0` with a 1 px `rule.1` inner edge, slide 320 ms `settle`, and never overlap the strip on desktop (the strip recentres in the remaining columns, 320 ms `turn`).

#### 4.14.13 Page actions (long-press or right-click on a page)

A `[0.5]` sheet (phone) or menu (desktop): `Bookmark this spot` (+ note field after saving), `Show dialogue on this page` (overlays OCR boxes as 1 px `spot` outlines with the recognised text on tap), `React to this chapter` (the five stamps), `Retry this page`, `Open page image` (full-screen viewer with pinch; swipe down to dismiss: no scale, the backdrop fades and the page returns to its box), `Scan this chapter's dialogue` (app only, downloaded chapters; starts the on-device OCR run with its progress in Downloads, §4.23).

---

### 4.15 Novel reader: "The page" · web R21 (NR1–NR19, NT1–NT7) · mobile S26, N1, N2, N4

The novel page is painted entirely in the chosen paper stock (§2.1.6); app chrome never appears. Newsreader is the default face, so reading uses the same text serif as the rest of the skin.

#### 4.15.1 Layout

| Platform | Layout |
|---|---|
| Desktop | A single text column at the chosen measure (default 64ch, range 48–88ch) centred in the viewport; a running head *inside* the page at the top (series title and chapter kicker left, `42%` folio right) that fades as you scroll; margins take the stock colour to the window edges |
| Phone | The column fills the width minus 24 px margins (a Margin setting widens them to 48 px); running head as on desktop |
| Landscape phone / tablet | Measure-limited column centred |

#### 4.15.2 The chapter: opener, body, end matter

- **Opener**: kicker `CHAPTER 12` in `type.kicker` (stock muted), title in Bodoni Moda Roman at 1.9 × the body size (stock ink), a 48 px rule (1 px stock muted), and a line of facts in `type.folio` (`3.4K WORDS · 14 MIN`). When audio exists: `Listen │ 14 MIN` as a `split` secondary in stock ink with `headphones` (a small "audio saved" check when downloaded).
- **Body**: Newsreader (or Archivo when Sans is chosen) at the chosen size and leading; first paragraph with a Bodoni Moda **drop cap** 3 lines tall (only when the paragraph is ≥ 80 characters); following paragraphs indented 1.3em (flush after scene breaks); scene breaks (a paragraph of ≤ 12 ornament characters) render as a centred 32 px rule with 24 px space above and below; `hyphens: auto` and justification only when Justify is on.
- **Speaker tints**: attributed dialogue runs get their speaker's slot colour (§2.1.6) as a 2 px underline at 70 % and a 12 % background, only when the attribution's `text_fingerprint` matches the text on screen.
- **Voices line**: under the text, right-aligned, `VOICES IN THIS CHAPTER (5)` in `type.kicker` → opens the cast sheet (§4.16.5).
- **End matter**: 96 px space, a 96 px rule, `End of chapter 12` in `type.section` with the letter reveal, facts (`READ IN 14 MIN`), reactions (§5.3.3), then the **next** card in stock colours: kicker `NEXT`, `Chapter 13` in Bodoni Moda, the chapter title, `→`; or "You've reached the last chapter this source has published." Links `Previous chapter` and `Back to the book`.
- **Seamless next**: over-scrolling 140 px at the bottom, `l`, or the next card marks the chapter complete and swaps the next chapter in at the top (URL replaced). With "Auto next chapter" on (app), reaching the end advances after 900 ms unless narration is playing.

#### 4.15.3 Chrome (tap anywhere toggles; fades 180 ms)

Solid stock-coloured bars with a 1 px rule in the stock's muted colour at 30 %:
- **Top** (52 px): back (`arrow-left`), running title (`type.nav` stock muted), offline mark (`wifi-slash`) when reading a saved copy, then contents (`list-numbers`), bookmark (`bookmark-simple`; Fill when saved), voices (`voice-31`), type (`text-aa`).
- **Bottom** (52 px + inset): previous chapter, the progress folio `42% · 6 MIN LEFT` (tap to cycle: chapter %, book %, time left), next chapter; a 1 px progress hairline along the top edge of the bar in the stock ink.
- The Listen mini player sits above the bottom bar when audio exists (§4.16.2).
- Chrome hides on downward scroll ≥ 24 px, shows on upward ≥ 56 px, at chapter end, or on tap.

#### 4.15.4 Reading modes and page turns

- **Scroll** (default): one continuous column with seamless next.
- **Paged** (Type sheet → Layout): columns paginated to the viewport (web: CSS multi-column in a fixed-height container; Flutter: a paginator that splits paragraphs by measured line boxes). Page turns: `CUT` (default, 0 ms), `SLIDE` (300 ms `set`, finger-tracked with `spring.release`), `FADE` (160 ms). No curl in this skin. Tap zones 25 / 50 / 25 (back / menu / forward); presets "Both margins advance" and "One hand" (left 20 % back, top 12 % menu, rest forward). Page folio at the bottom centre (`p. 7 of 22` in this chapter).
- Progress is always saved as the paragraph bucket (1–100) at the reading line (38 % from the top in scroll mode, the first paragraph on the page in paged mode).

#### 4.15.5 Type sheet ("Text and page")

A `[0.5, 0.92]` sheet on phones, a 352 px popover under the `text-aa` button on desktop, painted in the current stock so the preview is honest. Kicker `TEXT AND PAGE`.

| Control | Range | Default | Scope |
|---|---|---|---|
| Face | `SERIF` (Newsreader) / `SANS` (Archivo), each label set in its own face | Serif | per book (K44 / mobile K25) |
| Size | 14–40 px, stepper step 1 (`=`, `-`) | 19 desktop / 18 phone | per book (K41) |
| Line spacing | 1.30–2.10 step 0.05 | 1.60 | per book (K42) |
| Measure | 48–88ch step 2 | 64 | per book (K43) |
| Margins (phone) | `NARROW · STANDARD · WIDE` (16 / 24 / 48 px) | Standard | per profile |
| Paragraph spacing | 0–1.2em step 0.1 | 0 (indents) | per book |
| Character spacing | −0.02 to +0.08em step 0.01 | 0 | per book |
| Bold text | switch (wght 400 → 520) | off | per profile |
| Justify and hyphenate | switch | off (ragged) | per profile |
| Layout | `SCROLL │ PAGED` | Scroll | per profile |
| Page turn | `CUT │ SLIDE │ FADE` (paged only) | Cut | per profile |
| Stock | Six swatches (48 × 48 squares, each showing "Aa" in its own ink on its page, the chosen one with a 2 px `spot` frame): Nitrate, Ink, Sepia Night, Dusk, Moss, Rosewood | Nitrate | per profile (K40 / K26 migrated §2.1.6) |
| Reset | quiet `Reset text and page` | — | — |

Every change applies live under the sheet. Steppers roll their digits (Folio flip).

#### 4.15.6 Contents sheet (`list-numbers`, `t` on web opens Type; `o` opens Contents)

An 85 % sheet (phone) or the left column panel (desktop) in the stock colours. Kicker `CONTENTS`, a compact go-to field ("Chapter number", decimal keyboard; Enter jumps to the first match; typing shows up to 30 matches "and 12 more"; "No chapter 480 in this book."), then contents rows (§3.16 novel TOC variant) pre-scrolled to the current chapter (`spot.wash` band). Rows show narrated (headphones) and saved marks. Loading, offline ("The contents need a connection to load.") and error states as notices.

#### 4.15.7 Bookmarks and notices

`b` or the bookmark icon saves the paragraph at the reading line plus its fraction and a 180-character snippet, with no dialog (haptic `bookmark.add`); the toast offers `Add a note`. Stale anchors open at the nearest paragraph with the toast "The text here changed. Opened at the nearest paragraph." Toasts in this frame use the stock's page colour for the band and its ink for the text.

#### 4.15.8 Keys and gestures

| Key | Action |
|---|---|
| `h` / `l` | Previous / next chapter |
| `j` / `k`, `Space` / `Shift+Space` | Scroll or page forward / back |
| `Home` / `End` | Chapter start / end |
| `=` `+` / `-` / `0` | Text size up / down / reset |
| `t` | Type sheet |
| `o` | Contents |
| `b` | Bookmark |
| `p` | Listen play / pause |
| `[` / `]` | Previous / next sentence (Listen) |
| `Shift+[` / `Shift+]` | Back / forward 15 s (Listen) |
| `,` | Type sheet (alias) |
| `g` | Go to % |
| `f` | Fullscreen |
| `Esc` | Close sheet → collapse full player → back to the book |

Gestures: tap toggles chrome (scroll mode) or zones (paged); horizontal swipe turns pages (paged) or changes chapter (scroll, ≥ 72 px, opt-in); left-edge vertical swipe changes brightness (a black overlay, −75 … 0, for night reading below the system minimum); iOS edge back; Android predictive back (leaves to the book page when nothing is beneath).

#### 4.15.9 States

Loading: the page in the stock colour with 12 greeked lines at the body's line height (flicker at half strength). Offline: reads the saved copy; running head `wifi-slash`. Error: notice "Couldn't load this chapter." + `Back to the book`. Empty: "This chapter came through empty — usually a page that was pulled or is still being published." Stale text: speaker tints and follow-along are withheld. Rate limited: `SLOW DOWN` band with countdown.

---

### 4.16 Listen mode: "The reading" (31 named voices) · web NR9–NR15 · mobile S26 #15–16, N3, N4

Audio is pre-rendered per chapter with measured segment timings; the player follows the text sentence by sentence and never guesses.

#### 4.16.1 Entry points

The opener's `Listen │ 14 MIN` button; `p` in the novel reader; the mini player's play; the book page's `Listen` button (starts at the resume point); the Downloads row for saved audio; a lock-screen or notification control (app). Headphone marks on the book's contents show which chapters are narrated (`GET /novels/audio/series`).

#### 4.16.2 Mini player

A 56 px bar above the novel reader's bottom bar, in the stock colours with a 1 px top rule:
- 36 px round `play` button (stock ink fill, glyph in the page colour); states play, pause, preparing (16 px leader dial), failed (`!` in `proof`, tap retries).
- Centre: `CHAPTER 12 · READ BY IRIS` (`type.kicker`) over a 2 px progress rule (buffered part at 35 %).
- Right: `−18:40` folio; on desktop `−15 s` and `+15 s` buttons and the speed folio `1.00×`.
- Tap the centre → full player. Swipe the bar left or right → next or previous chapter (phones).
- It rides with the chrome and lingers 5000 ms after the chrome hides, unless pinned (long-press → `Keep player visible`).

#### 4.16.3 Full player: "The reading room"

A takeover (Rise from the mini player; the cover match-cuts from the mini player's cover square into place).

| Area | Desktop | Phone |
|---|---|---|
| Background | The series cover duotoned to `ambient.duo`, `blur.card`, at 50 % over `#000`, with `scrim.vignette` and grain 0.05 (art only) | same |
| Head | Kicker `NOW READING ALOUD`, series title in `type.headline`, chapter title as the deck; close `Done` | same, sizes per phone |
| **Transcript** ("lyrics") | Centre 6 columns: sentences in Newsreader 22/32. The active sentence is `ink.100` on a **highlighter** band (`spot.wash`) that *sweeps* across it left → right in 200 ms `set` when it becomes active; the spoken word gets a 2 px underline that steps without animation; other sentences at 35 %; dialogue sentences carry a small kicker above them with the speaker's name in their tint colour (`IRIS`, `DOKJA`). The active sentence is held at 38 % of the panel height; the view scrolls 400 ms `settle` only when it leaves the 20–70 % band and jumps if it is 2 panels away. | Full width, Newsreader 20/30 |
| Decouple | A manual scroll stops following and shows a `Back to the voice ↓` secondary pinned at the bottom of the transcript; in this view it re-follows automatically after 4000 ms idle | same |
| Transport | Under the transcript: a chapter ruler (time), `0:00` and `−18:40` folios; buttons: previous chapter, `−15 s`, the 64 px round `play`, `+15 s`, next chapter | same, 56 px play |
| Tiles | Three square outlined tiles (1 px `rule.2`, 88 px tall): `SPEED 1.00×` (with `≈ 182 WPM`), `VOICES IRIS + 4`, `SLEEP END OF CH.` | Three tiles in a row |

"Highlight paused: the text changed." appears as a caption under the head when timings no longer match (`highlight_safe` false or fingerprint mismatch): audio keeps playing, the transcript shows unhighlighted.

#### 4.16.4 Speed ruler

Tapping `SPEED` opens a `[0.5]` sheet: a horizontal tick ruler 0.50–3.00× in 0.05 steps, labelled at 0.5, 1, 1.5, 2, 2.5, 3 (`type.folio`); the value previews while dragging (folio flag) and commits on release; preset slugs `0.8 · 1 · 1.25 · 1.5 · 2`; touch-and-hold anywhere on the ruler resets to 1.00×; the WPM equivalent under the value. Pitch is preserved (web `preservesPitch`; `just_audio.setSpeed`). Haptic `select` per 0.25× on phones. Keys: `<` / `>` ±0.05×.

#### 4.16.5 Voices and the cast

**Cast sheet** (`VOICES IN THIS CHAPTER`, or the `VOICES` tile): a credits list with dot leaders:
`Narrator ........................ Iris` (pinned first; tap to choose the narration voice)
`Kim Dokja ■ .................... Arlo · 34 %` (a 10 px square of the speaker tint, the voice, the share of lines; a lock mark when set by hand)
Rows ordered by line count. Status lines above the list: "Looking up who speaks here…", "Nobody else was identified with enough confidence, so the narrator reads every line.", "Narrated by {name}: their own lines use the narrator's voice." Owner-only actions in each row's overflow: `Same character as…` (alias merge), `Set gender`. Non-owners see the list read-only (voice names, no pickers).

**Voice picker: "the cast list of 31"** (opens from a row, filtered to the character's gender; also from Settings → Listen → Voices):
- Masthead in the sheet: kicker `A VOICE FOR KIM DOKJA`, filters `ALL · FEMALE ¹⁸ · MALE ¹³ · IN USE`, a compact search by name.
- Two columns on desktop (`MALE`, `FEMALE`, each ordered deepest first, as the server serves them), one column on phones with the gender as section heads.
- Each voice row (64 px): a 40 px monogram circle in a hue derived from pitch (deep voices cool, bright voices warm), the name in Bodoni Moda Italic 20, the character descriptor in `type.caption`, a **pitch scale**: a 80–300 Hz ruler with a `spot` tick at the voice's `pitch_hz`, an **expressiveness meter**: five 6 × 6 squares filled `ink.100` by `expressiveness`, and actions `Hear` (secondary sm; plays `GET /novels/voices/sample`, the button shows a 3-bar level meter while playing and a leader dial while fetching) and `Cast` / `CAST` (selected state, filled).
- Top row: `Automatic` ("Assigned by gender and speaking order") and, for the narrator picker, `Book default`.
- Footer caption: "Chapters already rendered keep the voice they were made with until they're rendered again." License and attribution per voice under `Details` in the row's overflow.
- Casting posts `POST /novels/cast` or `POST /novels/narrator`; the row shows `RE-VOICING` until the next render; haptic `voice.assign`; error toast "That voice couldn't be saved." with the reason.
- Empty: "No voices are installed on the server, so characters can't be cast from here yet."

#### 4.16.6 Sleep timer

`SLEEP` opens a list sheet: `Off · 5 · 10 · 15 · 30 · 45 · 60 min · End of chapter · End of next chapter · Custom…` (custom is a minutes stepper). The tile and the mini player show the live countdown folio. The last 8 s fade the volume out (haptic `sleep.fade`). Phones: shaking the device during the fade or in the last minute extends by 5 minutes (setting "Shake to extend", default on; toast "Sleep timer +5 min").

#### 4.16.7 Chapter boundary

At the end of a chapter's audio: a **post-play card** at the bottom of the transcript: kicker `NEXT`, `Chapter 13` typed at 50 ms per character, a 40 px countdown dial (§3.18) running 5 s, `Play now` (primary) and `Cancel` (quiet). When the countdown completes, playback continues into chapter 13 and the reader swaps the text in place. With the sleep timer at "End of chapter" the card is skipped and playback stops.

#### 4.16.8 Audiobook: narrate and save (book page, owner)

The book page's `Audiobook` button opens a sheet: kicker `AUDIOBOOK`, segmented `NARRATE │ SAVE TO THIS DEVICE` (Save only when a downloads scope exists), quick picks slug line `NEXT 10 · ALL UN-NARRATED ⁽³⁸⁾ · NONE` (or `ALL NARRATED`), then a checklist of chapters with status captions (narrate: `ALREADY NARRATED · SAVED`, `ALREADY NARRATED`, `DOWNLOAD THE TEXT FIRST`; save: `SAVED`, `SAVED COPY CAN'T PLAY ON THIS PHONE`, `SAVING…`, `COULDN'T BE SAVED`, `NARRATED`, `NOT NARRATED YET`), an estimate caption ("About 9 minutes of rendering per chapter on the narration PC." / "Saves while the app is open; the text is saved too."), and the primary `Narrate 12 chapters` / `Save audio of 12 chapters`. Below, when jobs exist: a job list with determinate rules per job (queued, planning, rendering with progress, done, failed with the error, cancelled) and `Cancel` per job ("It stops shortly."). A global indicator appears in Index and Downloads: `NARRATING 3 CHAPTERS` with a mini rule. `narration_unavailable`: caption "Narration of new chapters isn't available right now. Chapters that already have audio can still be saved." Poll cadence as the inventory (5 s; ×3 while waiting for the render PC; back-off to 60 s on failures).

#### 4.16.9 Saved audio on the device

The mini player's overflow and the opener show the audio save state: `Save audio to this device` → saving (leader dial) → `Audio saved` (check) → tap asks "Remove saved audio? The chapter stays on this device to read." / failed "Couldn't save the audio. Tap to try again." / unplayable "The saved audio can't play on this device. Tap to save it again." iOS requests `m4a`; a first request answered `503 audio_preparing` shows "Preparing the audio…" with a leader dial and retries after the server's `Retry-After`.

#### 4.16.10 Lock screen and background (app)

Narration keeps playing with the screen locked and the app in the background, with lock-screen and notification controls (title, chapter, cover, play/pause, ±15 s, next chapter) through `audio_service` 0.18.19 (MIT) wrapping the existing `just_audio` player; the `audio_session` category stays speech. This is a new native dependency in its own commit (§9.3). Mobile web uses the Media Session API (`navigator.mediaSession.metadata` and action handlers) with no dependency.

#### 4.16.11 States

Preparing (`503 audio_preparing`), playing, paused, buffering (leader in the play button), failed ("Audio couldn't be loaded." + Retry), no audio for this chapter (Listen button absent; opener shows `NOT NARRATED` for the owner with `Narrate this chapter`), highlight paused (text changed), offline with saved audio (works), offline without saved audio ("This chapter's audio isn't saved on this device."), voices unavailable (empty cast list).

#### 4.16.12 Keys and gestures

Keys as §4.15.8 (`p`, `[`, `]`, `Shift+[`, `Shift+]`, `<`, `>`, `Esc` collapses the full player). Gestures: swipe down on the full player collapses it to the mini player (finger-tracked, `spring.sheet`); swipe the mini player sideways to change chapter; tap a transcript sentence to play from it (haptic `select`).
---

### 4.17 Series page, manga: "The feature" · web R7, R17 (SD1–SD21, SS1–SS18) · mobile S10, S18 (manga body)

One screen for `/sources/:sourceId/series/:seriesKey` and `/library/:followedId`. Data: source series + chapters + progress (`GET /reader/progress/series`) + the follow row when followed (favourite, status, notify, override), + `ambient`.

**Hierarchy.** Title treatment → the one action (Read or Continue) → credits → chapters → everything else.

**Desktop layout.**
1. **Spread** (`clamp(520px, 64vh, 760px)`), like Tonight's cover story but for this series:
   - Columns 1–5: kicker in `ambient.ink` (`MANHWA · ONGOING · 201 CHAPTERS`); title in `type.headline` (length rules §2.2.1) with the letter reveal after the match cut lands; deck = the synopsis's first sentence in `type.deck` italic; **credits** (`STORY` author, `ART` artist, `SOURCE` name with its health mark, `STATUS`, `UPDATED 2 D AGO`, rating certificate when mature and visible); actions row: `split` primary (`Read │ CH 1`, `Continue │ CH 143 · p.12`, or disabled `All caught up`), `secondary` `Read all` (strip glyph; manga with > 1 chapter; tooltip "Every chapter in one continuous scroll"), `secondary` `Previously on…` (when a recap is possible, §5.1.5), then bare icon buttons: Follow (`plus` → `check` "Following"; stamp haptic; toast "Following {title}. New chapters will notify you."), Favourite (`star`), Notify (`bell-ringing`, only when followed), Download (opens §4.19), Recommend (`paper-plane-tilt`, Circle on), overflow.
   - Columns 6–12: the cover at full spread height against the right edge, `blur.bleed` duotone fill, `scrim.gutter`, grain, Drift; the reading progress rule along its bottom.
   - Page spill: the 30 vh under the spread fades from `ambient.tint` to `#000`.
2. **Contents tabs** (sticky under the running head): `01 CHAPTERS²⁰¹ · 02 DETAILS · 03 MORE LIKE THIS · 04 CIRCLE`.
3. **CHAPTERS** (8 columns) + **At a glance** aside (4 columns, ≥ 1440; below the list on smaller screens):
   - Toolbar: `NEWEST │ OLDEST` segmented (persisted per series, K45), compact go-to field ("Chapter number"), `Select` (quiet), download summary `12 OF 201 SAVED` + `Download` (secondary sm).
   - Schedule rows (§3.16): chapter folio, title, date, pages, progress, `READ`, download mark, reaction count; the current chapter has a `spot.wash` band and a `READING` badge. Rows prefetch the manifest on hover or focus (and the first five on load). Windowed list (virtualised) for long series.
   - Series download card (when anything is saved or queued; §4.19).
   - Aside: a numeral `142 / 201` with the caption `CHAPTERS READ`; reading status as a slug-line select (`READING · PLAN · ON HOLD · DONE · DROPPED · UNREAD`); `YOUR TIME HERE 11 H 20 M`; tags (own tags as removable tokens + `Add tag`); shelves containing it (+ `Add to shelf`); OCR coverage "Dialogue indexed for 34 of 201 chapters" with a determinate rule.
4. **DETAILS**: the full synopsis in `type.body` 17/28 at 62ch with a Bodoni drop cap; alternate titles (CJK in the Noto fallbacks); genres as a slug line of links (each opens the source catalogue filtered to that genre, `?genre=`); enriched metadata when available (format, AniList rating, official platforms as `Read on {site} ↗` links); source credit and `Open on {source}`.
5. **MORE LIKE THIS**: a `Similar` rail (§5.1.4) and `Because you read {title}` rail; AI unavailable fallback: series from the same genres on your sources.
6. **CIRCLE** (§5.3): who follows or read it, their reactions per chapter, `Recommend to…`. Disabled with a tooltip when the profile shares nothing.

Overflow menu: Add to shelf, Set reading status ▸, Tags…, Treat as 18+ / not 18+ / use the source rating (radio), Check for new chapters (per-series check), Open the source's page ↗, Find it on another source (search prefilled with the title; shown with a `NOTE` banner when the source's health is `dead`: "This source is down. Find the series on another source."), Share link (web: copy), Unfollow (proof).

**Phone layout.** No thumb index on this screen. Running head transparent with back and overflow. The cover full-bleed 4:5 with `scrim.foot` into `ambient.tint`, Drift; the title block overlaps its lower quarter (kicker, `type.headline` 32/36, deck 2 lines); then the actions: `split` primary full width, a row of `Read all` and `Previously on` (secondary, half width each), then a row of the icon buttons with labels under them (`FOLLOW · FAVOURITE · NOTIFY · DOWNLOAD · SEND`); credits single column; then the contents tabs, sticky under the running head; the At a glance block sits at the top of DETAILS.

**Platform deltas.** iOS: edge swipe back reverses the match cut with the finger. Android: predictive back fades through. Mobile web: identical to the app; long-press on chapter rows opens the row menu. Desktop: hover reveals row actions (download, mark read) at the row's right end.

**Signature moment.** The match cut lands the poster on the spread, the letters of the title set, the credits appear in reading order, and the ambient colour washes the page top over 800 ms: the series gets its own issue colour.

**Transitions.** In: match cut from any poster or cutting; Page from lists without a cover. Out: Column wipe to the reader; reverse match cut on back.

**Gestures.** Swipe between contents tabs (phones); long-press a chapter → Mark read / Mark unread up to here / Download / Bookmark start; swipe a chapter row left → Mark read.

**Keys (web).** `Enter` or `c` continue (Column wipe); `a` read all; `p` previously on; `f` favourite; `n` notify; `+` follow / unfollow toggle (asks nothing, toast with Undo); `d` download panel; `1`–`4` tabs; `j`/`k` chapters; `x` select; `/` go-to field; `o` newest/oldest.

**States.** Loading (galley spread: title bars, credit lines, cover plate; 8 greeked chapter rows); chapters offline ("The chapter list needs a connection."); chapters unavailable ("MangaDex lists 201 chapters but returned none just now — usually the source, not you." + `Try again`); no chapters ("No chapters yet. The source hasn't published any." + `Back to the source`); series error (`CORRECTION` "Couldn't load this series. The source did not answer." + `Try again` + `Back to the source`); offline with saved chapters (page renders from the local store with `OFFLINE EDITION`; only saved chapters are enabled); follow limit reached ("You're following 1,000 series, the limit for a profile."); stale catalogue (`SAVED COPY` badge).

---

### 4.18 Series page, novel: "The book" · web R17n (NB1–NB19) · mobile S18 (novel body), N2, N3

Front matter set like a book's title page, then the contents.

**Desktop layout.** No spread art; the book is typographic.
- Columns 1–7: kicker `NOVEL · ONGOING · NOVELARCHIVE`; title in Bodoni Moda Roman `type.masthead`; byline "by {author}" in Newsreader Italic 22; a 56 px rule; facts as credits: `CHAPTERS 1,204 · ≈ 2.1M WORDS · ≈ 140 H · ONGOING`; the estimate note "Length estimated from 12 chapters read so far." (`type.caption`); the blurb in `type.body` 17/28 with a Bodoni drop cap, max 62ch; genres as a slug line of links.
- Actions: `split` primary `Start reading │ CH 1` / `Continue │ CH 212 · 42%` / disabled `All caught up`; `secondary` `Listen` (when narrated chapters exist; starts Listen at the resume point); `secondary` `Previously on…`; icon buttons Add to library (`plus` / `check` "In your library"; toast "Added {title}. New chapters will notify you."), Download book (with the unsaved count folio), Audiobook (§4.16.8), Recommend, overflow.
- Columns 9–12: the cover plate 168 × 248 (square-cornered, 1 px `rule.2`), a duotone copy at 3× blurred behind it as a soft field, and under it "In the circle" avatars when others read it.
- **Contents** (full 12 columns under a section rule): toolbar `FIRST → LAST │ LAST → FIRST` (default first → last), go-to field (matches list up to 12 buttons "and n more"), `Pick chapters` (select mode for downloads), `Narrated only` toggle. Contents rows (§3.16) windowed around the focus (400 at a time) with `Show earlier chapters (n)` above and `Show more chapters (n)` below; the focused chapter (`?chapter=` or go-to) scrolls to centre with the `spot.wash` band.

**Phone layout.** Plate 96 × 144 floats right of the title block; facts wrap into two lines; blurb collapses to 5 lines with `More`; actions stack as on the feature page; contents full width; go-to via a search icon that opens the contents sheet in search mode (N2).

**Signature moment.** The title-page set: title letters, byline, the rule drawing, and the drop cap of the blurb setting last.

**Transitions.** In: match cut from a book-list plate (plate → plate). Out: Column wipe to the novel reader; Rise to the audiobook sheet.

**Keys (web).** `Enter`/`c` start or continue; `l` listen; `p` previously on; `+` library toggle; `d` download book; `/` go-to; `o` order.

**States.** Front matter loading (galley), offline ("This book needs a connection to load."), error (+ `Back to the source`); contents loading (10 greeked rows), offline, error, unavailable ("Contents didn't come through."), empty ("No chapters yet."); narration unavailable caption; prefetch of the first three chapters happens silently.

---

### 4.19 Chapter selection and downloads on series pages · web DP1–DP7, SD14–SD17, SS13–SS16, NB12–NB18 · mobile S10 #8–17, M2

- **Trigger**: `Download` (manga) or `Pick chapters` (novels) enters select mode on the chapter list. Rows gain a leading checkbox; saved chapters are disabled (checked and dimmed); Shift-click selects a range; long-press starts selection on phones.
- **Selection bar** (bottom on phones, under the running head on desktop): `12 SELECTED · 3 ALREADY SAVED`; quick picks as a slug line with counts `NEXT 10 · ALL UNREAD ⁴² · WHOLE BOOK` (novels) `· ALL ²⁰¹ · NONE`; `Done` (quiet) and `Download 12` (primary).
- **Running**: `DOWNLOADING 4 OF 12` + determinate rule + `Stop`; per-row download marks animate as the queue works (§3.18).
- **Summary line**: "12 chapters saved." / "Nothing to download — those are already saved." / "10 of 12 saved, 1 with missing pages, 1 failed." / "Out of room: only 380 MB free. Remove some downloads and run it again." (with `Manage downloads`) / "Stopped: 4 saved." + `Dismiss`. Problems use the `NOTE` tone.
- **Series download card** (feature page, when anything is saved or queued): kicker `ON THIS DEVICE`, `12 OF 201 CHAPTERS SAVED` with a determinate rule (`set` when complete), `DOWNLOADING NOW · PAGE 7 OF 40`, `3 WAITING · 1 FAILED`, the pause reason line when blocked (`NOTE`: "Paused: this phone is almost full." / "Paused: your 10 GB limit is full." with `Storage settings`), and on iOS the foreground note "Downloads run while the app is open; leaving pauses them and coming back picks up where they stopped."
- **No profile**: "Downloads belong to a reading profile. Choose one to save chapters." + `Choose a profile`.
- **Novels**: "Whole book" pages through `POST /novels/chapters` 20 at a time; the bar shows `SAVING THE TEXT…`.
- Haptics: `download.start` when the queue accepts; `download.done` once when the batch finishes.

---

### 4.20 Discover: search · web R14 (SE1–SE11) · mobile S20 · new scopes

**Hierarchy.** The index field → scopes → results by source (or the idle page).

**Desktop layout.**
- Masthead: kicker `No. 04 — DISCOVER`, then instead of a title the **index field** (§3.4) spanning 8 columns, placeholder typed "Search every source".
- Scope tabs under it: `ALL · LIBRARY · SOURCES · DIALOGUE · ASK` (ASK only when AI is available; DIALOGUE only in manga mode with OCR enabled).
- **Idle page** (no query), in 12 columns:
  - `RECENT` slug line of the last 4 searches (per profile, min 2 characters) with `Clear`.
  - `ASK THE EDITORS` (when AI available): a Feature-sized block with the typed example ("A murim regressor who comes back stronger") and `Ask` → Picks (§5.1.3).
  - `01 Browse by genre`: a grid of genre tiles (16:9, a representative cover duotoned to its own `ambient.duo`, tilted 0° — covers never tilt in this skin — with the genre in `type.subhead` italic over `scrim.foot`); genres from the profile's histogram first.
  - `02 Sources`: pinned sources as a credits list (logo 24, name, health mark, `18` certificate when visible) + `All 89 sources →`.
  - `03 Search what they said`: an entry block for dialogue search with the `bubble-search` glyph.
  - `04 Trending on your sources`: a slug line of terms.
- **Results** (after 300 ms debounce, or immediately on Enter):
  - Status line (`type.caption`): "Searching your library and 12 pinned sources…" → "48 results · 12 sources" → "48 results so far · searching 77 more sources…" with an indeterminate rule while tier 2 runs; failures: "3 sources didn't answer." (`NOTE`).
  - Group jump bar (desktop, sticky): source names with counts as a slug line; clicking scrolls to the group.
  - `IN YOUR LIBRARY` group first (from `/library/search`), then source groups in tier order, then `IN DIALOGUE` (top 3 OCR hits with `See all`).
  - Each group: a subhead row (24 px source logo or the Library mark, source name in `type.title`, count badge, health mark) and a rail of posters with captions (title 2 lines, `CHAPTERS 120`); failed groups show `CORRECTION` caption "This source didn't answer." + `Retry` (retries only that source, with two flicker plates while it runs); empty groups collapse into `Show 31 sources with no matches` (quiet toggle).
  - Filter slugs above the groups: `ALL · WITH RESULTS · PINNED`.
- **ASK scope**: the field becomes a prompt ("Describe what you feel like reading"); submitting runs the world suggest (§5.1.3) and shows its results here; keyword search is one tap away.

**Phone layout.** The index field at 28 px in the masthead area (the running head shows `DISCOVER` once it scrolls away); scopes as a scrolling contents row; idle sections stack; genre tiles 2 per row; results as rails (3.2 posters); failed/empty groups as above; the group jump bar becomes a `Jump to source` sheet button.

**Platform deltas.** iOS/Android: the keyboard opens on the third tap of the Discover tab and on `/` with a hardware keyboard; search submits on the keyboard's search key. Mobile web: `enterkeyhint="search"`. Desktop: `/` focuses; `↓` moves into results; group jump with `[`/`]`.

**Signature moment.** Typing in the index field in Bodoni Italic that turns to Roman as it becomes a query; results then **Set** group by group as tiers arrive.

**Transitions.** In: Cut (tab) or Dip; `?q=` prefilled from Picks' `Search my sources`. Out: match cut to feature pages; Page to Sources.

**States.** Idle; searching (tier 1 skeleton: 3 groups of 4 flicker plates); partial (tier 2 running); results; no results (`NOTHING FOUND`: "No series match "{q}" in your library or sources." + `Ask the editors` when AI available); offline ("Search needs a connection to reach your library and sources."); error; rate limited.

---

### 4.21 Sources · web R15 (SL1–SL13) · mobile S16 · G4

**Desktop layout.**
- Masthead: kicker `No. 04 — DISCOVER / SOURCES`, title "Sources", deck "89 sources · 84 healthy · 6 pinned" (from `/system/source-health`, gated counts).
- Toolbar: compact filter field ("Filter sources", matches name or id), slug line `ALL · PINNED⁶ · 18+` (18+ only when the gate is open) and the content mode.
- **Pinned** section: a table (a list with columns) of pinned sources in pin order, each row draggable (≤ 50, `PUT /sources/pins`).
- **All sources** section: a directory table: logo 32 (favicon, or a Bodoni initial on `paper.1` as fallback), name (`type.title`) + description (`type.caption`, 1 line), `LANGUAGE`, `KIND` (Manga / Novel), health (mark + "OK · last checked 4 min ago", "FAILING · 3 errors", "DEAD since 12 Sep", "DEMOTED" with strike), `18` certificate, and a pin toggle (`push-pin`; Fill + spot rule when pinned; `aria-pressed`, "Pin {name}"). Unavailable pinned sources (pinned but no longer visible on this profile) show at 40 % with `UNAVAILABLE ON THIS PROFILE` and cannot be opened.
- Row click → source catalogue (Page).
- Pin feedback: toast "{name} pinned" / "{name} unpinned"; failures "Couldn't update your pinned sources." (`proof`); if pins fail to load: a `NOTE` banner "Pinned sources couldn't be loaded, so pinning is off until they are." + `Try again`.

**Phone layout.** Rows 64 px: logo 32, name + description, health mark and `18` at the right, pin button (48 hit); pinned section first with drag handles; toolbar as a scrolling slug line + filter field.

**Platform deltas.** Phones: long-press a row for `Pin` / `Unpin` / `Open` / `Health details` (a sheet with the last error and last OK time); pinned rows reorder by their handle; haptic `select` on pin. Desktop: hovering the health mark shows the last error in a tooltip. Mobile web: as phones, without haptics.

**Transitions.** In: Page from Discover, Cut from the sidebar. Out: Page to the catalogue.

**Signature moment.** The health column reads like a festival listing: each row's mark and status text line up on one column rule, and dead sources are set with a strike-through, so the directory is scannable at a glance.

**Keys (web).** `/` filter; `j`/`k` rows; `Enter` open; `p` pin toggle; `Alt+↑/↓` reorder pinned.

**States.** Loading (10 greeked rows); error (`CORRECTION` + Retry); none installed ("No sources installed on this server."); no match ("No sources match "{q}"."); pinned empty ("No pinned sources. Tap the pin on any source to keep it at the top."). The directory looks complete at both 89 and about 33 rows (gated profile): no gaps, counts computed after the gate.

---

### 4.22 Source catalogue · web R16 (SB1–SB15) · mobile S17

**Desktop layout.**
- Masthead: the source's logo (48) beside its name in `type.masthead`; deck: "Catalogue · 1,240 series" (+ ` · "{q}"` when searching); freshness credit `UPDATED 12 MIN AGO` or the `SAVED COPY · 3 H` badge (tooltip: "The source is down; this is the last copy we saved."), ticking every 30 s; `Refresh` (quiet with `arrow-clockwise`, spins as a leader while refreshing; `refresh=true`).
- Toolbar: browse modes as contents tabs with the server's labels (scrollable, any string; hidden while searching), a `Genre` select (single-select menu of the source's genres, "All genres"; only when the source has genres), and a compact search field ("Search this source", 300 ms debounce, `/`).
- **Grid**: a poster wall with captions below (title 2 lines), 6 per row desktop / 8 wide / 3 phone / 5 tablet; novel sources show the book list (§4.9.1).
- Infinite scroll with a sentinel 600 px before the end; `LOADING MORE` caption with a leader dial; load-more failure: "Couldn't load more." + `Retry` (refetches only that page); end: a 1 px rule and `END OF CATALOGUE` kicker centred.
- **Opening state** (first load): the source name sets itself with the letter reveal in the masthead, a 32 px leader dial beside the deck, and under it the grid's flicker plates; after 3 s the deck changes to "This source can take about 10 s." and a line of tips types itself in rotation every 3.5 s ("Press / to search this source.", "Pick a browse mode to change the order.", "Tap a genre on any series to browse it here.", "Your progress syncs across devices."); a background wash in the source's hue (hashed from its id, `L 0.06`) fades in after 3 s. Data arrival dissolves the plates into posters (160 ms) and the grid runs **Set**.
- A floating `TOP` square button (40 px, `paper.2`, 1 px `rule.2`, `arrow-up`) appears after 400 px of scroll (phones, bottom-right above the thumb index; desktop, bottom-right of the content).

**Phone layout.** Running head: back + logo 24 + name; the search field under it; browse-mode tabs; the wall 3 columns; pull to reprint (refresh from the source).

**Platform deltas.** iOS and Android: haptic `select` once when the first page of results lands; the `TOP` button sits above the thumb index. Mobile web: the same without haptics. Desktop: the wall is keyboard navigable and hover slates are off here (a catalogue is scanned, not browsed poster by poster).

**Transitions.** In: Page from Sources, Cut when opened from a genre link. Out: match cut to feature pages.

**Keys (web).** `/` search; grid keys (`h j k l`, arrows, `Home`/`End`); `Enter` open; `[`/`]` browse modes; `r` refresh.

**States.** Opening; loaded; empty ("No series found." / `No results for "{q}" on this source.`); full error (`CORRECTION` "Couldn't load the catalogue." + message + `Try again`); stale; offline (the saved copy if one exists, else notice); rate limited (countdown in the deck).

---

### 4.23 Downloads and storage: "The offline edition" · web R23 (DL1–DL9) · mobile S21, S32, M5 · G10

**Hierarchy.** What's stored and how full → what's running → the saved library.

**Phone layout (iOS, Android).**
- Masthead: kicker `No. 05 — ON THIS DEVICE`, title "Downloads", deck "Saved for {profile} · reads with no connection". Content-mode chip in the running head.
- Contents tabs: `SAVED · STORAGE`.
- **SAVED tab**:
  - **Storage meter** (§3.18) with the folio line `4.1 GB OF 10 GB · 21 GB FREE ON THIS PHONE` and the cap tick; tapping it opens the STORAGE tab.
  - **Activity** (only while something runs, pinned at the top): kicker `DOWNLOADING` / `WAITING TO START` / `PAUSED`; the current chapter (series, `CH 12 · PAGE 7 OF 40`, novels `SAVING THE TEXT…`, audio `SAVING THE AUDIO…`) with a determinate rule; "2 more chapters downloading alongside"; "12 of 40 saved in this series"; pause reason as a `NOTE` line (user: "Paused by you. Nothing was lost; resuming carries on from the same page." + `Resume`; floor: "Paused: this phone is almost full. Downloads stop before the last 1.5 GB." ; cap: "Paused: your 10 GB limit is full." + `Storage settings`; background (iOS): "Paused while the app is in the background."); controls: `Pause all` / `Resume all`, `Cancel all` (dialog "Cancel all downloads? Everything queued, downloading or failed is dropped. Finished chapters stay."); `Show queue ⁽⁸⁾` expands queue rows (`clock` / `!`; "Waiting", "Downloading", "Failed — {error}"; `Retry`, `Remove from queue`); the iOS foreground note.
  - **Dialogue scan** (only while an OCR run exists): kicker `READING THE DIALOGUE`, "Page 3 of 40" with a rule; paused ("Text extraction pauses in the background; keep the app open."), uploading, done ("214 words are now searchable." + `Search dialogue`), cancelled, failed; `Cancel` while busy.
  - **Narration** (when narration jobs exist): `NARRATING 3 CHAPTERS` with per-book rules → the book's audiobook sheet.
  - **Saved library**: kicker `ON THIS PHONE — BIGGEST FIRST`; one block per series: cover 48 × 72, title, `40 CHAPTERS · 3 WITH AUDIO · 1.2 GB` or `12 OF 40 SAVED · 800 MB`, pin (`push-pin`, "Pinned series are never auto-deleted"), overflow (`Save to Files…`, `Remove all downloads` → dialog "Remove every saved chapter of {series}? Your reading progress is kept."), and an expand chevron revealing chapter rows: `CH 12` (+ `· AUDIO` rows with a headphones glyph), status caption (`SAVED · 24.3 MB`, `QUEUED`, `DOWNLOADING`, `FAILED — …`), `Scan dialogue` (`bubble-search`; `TEXT` when done, spins while scanning; manga, saved, OCR available), `Save to Files` (`export`), `Remove` (swipe left or trash; toast with Undo for 8 s). Tap a saved chapter → its reader (Column wipe).
  - **Where it lives** note (`type.caption`): "Saved chapters live inside ManhwaManiacs and open from here. For a copy you can open elsewhere, use Save to Files."
- **STORAGE tab** (also `/settings/storage`): `STORAGE CAP` slug line `2 GB · 5 GB · 10 GB · 20 GB · UNLIMITED` (K17); `CHAPTERS AT ONCE` `1 · 2 · 3` with the explainer (K18); `DELETE AFTER READING` `OFF · 24 H · 48 H · 7 D` (K19; "Finished chapters older than this are removed; pinned series and the chapter you're reading never are."); `Download on Wi-Fi only` switch (K20: gates the auto-queue of the next chapter); `Download new chapters of followed series automatically` switch (new, update-tracker driven); `BY SERIES` rows (pin mark, title, `12 CH · 240 MB`); `Free up space` (secondary; toast "Removed 14 chapters." / "Nothing to free up right now."); image cache card (size + `Clear image cache`); metadata cache card (`Clear metadata cache`); platform note (iOS: "Browse, copy or delete saved chapters in the Files app: On My iPhone › ManhwaManiacs." with `Open Files`; Android: "Files live in the app's private storage.").
- **Save to Files sheet** (M5): kicker `SAVE TO FILES`, two options as rows: `Page images` ("A numbered folder per chapter.") and `CBZ file` ("One file per chapter, for comic reader apps."); then a non-dismissible progress dialog ("Saving to Files…" + leader) and a result dialog ("Saved 12 chapters · 480 pages" + the path in `type.folio` selectable: "Files › On My iPhone › ManhwaManiacs › Exports › {series}" on iOS, the directory on Android + skipped count + `Done`); errors as toasts ("Nothing to save yet — these chapters are still downloading.", "Couldn't save to Files. Check your free space.").

**Desktop and mobile web layout.** The same order in 12 columns: meter and activity in columns 1–8, the retention and protection controls in an aside (columns 9–12); the saved library as series blocks in two columns at wide widths.
- Web meter: "2.3 GB in 84 chapters · 2.3 GB of 60 GB used by this site · 57 GB free" (`navigator.storage.estimate`), or "This browser doesn't report a storage quota."; explainer "Saving stops before the last 250 MB of the quota; finished chapters go oldest-first, never one you haven't read and never the one you have open."
- `Protect storage`: `STORAGE PROTECTED` (`set` badge) or `Ask to protect storage` (secondary; `navigator.storage.persist()`).
- `DELETE FINISHED CHAPTERS AFTER` `2 DAYS · 7 DAYS · 30 DAYS · NEVER` (K50).
- Web chapter statuses as the inventory: "Saving 12/40", "Incomplete — 38/40 pages", "Paused — this browser is out of room", "Pages changed on the server — save again", with retention hints " · deletes in about 3 days" / " · open now, kept".
- Footer: `Remove all downloads` (inline confirm "Delete everything saved?") and `Reset offline storage` (quiet `proof`; dialog; unregisters the worker and clears caches) with its explainer.

**Signature moment.** The storage meter is set as a single typographic line with a live rule under it; when a chapter finishes, its row's mark fills with `set` and the meter's spot segment grows by exactly its size (240 ms `set`), so the edition visibly gets thicker.

**Transitions.** In: Cut (tab). Out: Column wipe into saved chapters.

**Gestures.** Swipe rows to remove; long-press a series block for Pin / Save to Files / Remove all; no pull to refresh (local data).

**Keys (web).** `j`/`k` series; `Enter` expand; `Delete` remove focused chapter (dialog for a series); `p` pause/resume all.

**States.** No profile ("Choose a profile to see its downloads." + `Choose a profile`); unsupported (web without a service worker: "Downloads aren't available in this browser or on this connection."); checking ("Checking what's stored…" with a leader); empty (`NOTHING SAVED YET`: "Chapters you save open with no connection." + a rail of Continue reading series with `Download next 5` on each); offline (a banner: "You're offline. Only saved chapters open."); error ("Couldn't read downloads.").

---

### 4.24 Dialogue search (OCR): "What they said" · web R24 (OC1–OC8) · mobile S27

**Desktop layout.**
- Masthead: kicker `No. 09 — DIALOGUE`, the index field with the typed placeholder "Search what a character said", deck "Across chapters whose dialogue has been read, in series you follow."
- Results as **transcript lines**: each hit is a block: the snippet in Newsreader 18/28 with matched terms under a `spot.wash` highlighter and `ink.100`, then a credit line `TOWER OF GOD · CH 88 · 214 WORDS · VISION` (series title joined from the library; the cover at 40 × 60 at the left). The engine name is shown (`VISION`, `ML KIT`).
- Click → the reader opens at that chapter, then (after the chapter's OCR text is fetched) scrolls to the first page containing the match and pulses a 2 px `spot` frame around the bubble twice (480 ms each), with the toast "Found on page 12." When the page cannot be matched: toast "Opened at the chapter start. The line is in this chapter."
- Overflow note: "Showing the first 20 of 134 matches. Narrow the search." + `Show more` (offset).
- Novels mode: a notice "Dialogue search is for manga. Switch to Manga, or search the novels' text." + `Search novels` (Discover).

**Phone layout.** The same, one column; the field at 28 px; the cover at 32 × 48.

**Platform deltas.** Mobile adds the entry point for scanning: a caption line under the deck "Scan more chapters from Downloads" linking to Downloads; the OCR engine runs on-device (Apple Vision, ML Kit). Web shows only search.

**Signature moment.** The highlighter strokes sweep across the matched words (200 ms each, left → right, 60 ms apart) as results land.

**Keys (web).** `/` field; `j`/`k`; `Enter` open.

**States.** Idle ("Type a line you remember."), loading (3 greeked blocks), no matches ("Nothing found for "{q}". Only chapters whose dialogue was scanned, in series you follow, can be searched."), offline, error, OCR unavailable on this device (mobile: the Index entry is hidden).

---

### 4.25 Picks (recommendations) · web R12 (RC1–RC11) · mobile S11

Specified in full in §5.1.3 (the AI feature owns this screen). Route `/library/recommendations`; Contents sidebar `12 Picks`; phone entry from Discover (`ASK THE EDITORS`), Tonight rails' `See all`, and Index.

### 4.26 The Numbers (statistics) and The Annual · web R13 (ST1–ST13) · mobile S12

Specified in full in §5.2. Route `/library/statistics` and `/library/statistics/annual/:year`; entries from the sidebar `10 The Numbers`, Index, Tonight's section 09.

### 4.27 Circle · new

Specified in full in §5.3. Route `/circle`; sidebar `11 Circle`; Index; Tonight's section 05.

---

### 4.28 Index (More) · web R25 (M1–M6) · mobile S22 · G9

The phone hub, set as a magazine index: entries with folios and dot leaders.

**Phone layout.**
- Masthead: kicker `THE INDEX`, title "Index".
- **Profile block**: 44 px avatar, name in `type.subhead` italic, `@username` + `ADMIN` credit, mood; actions `Switch profile` (secondary sm) and `Profiles` (quiet, to Manage).
- Content mode toggle (when novels are enabled).
- Sections as credits lists (row 48 px: label `type.ui` → dot leaders → a folio or value → chevron):
  - `YOU`: The Numbers ...... `12-DAY STREAK`; The Annual ...... `2026`; Circle ...... `2 NEW`; Picks ...... `8 ASKS LEFT`.
  - `READING`: Updates ...... `14` (also in Library); Collections ...... `9`; History; Bookmarks ...... `23`; Dialogue search (manga + OCR available).
  - `THE HOUSE`: Settings; Storage ...... `4.1 GB`; Backup & restore (admin); Members (admin); System status (admin) ...... `84/89 OK`.
  - `ABOUT`: What's new ...... `3.5.0`; App update (Android APK) ...... `AVAILABLE`; Version ...... `3.5.0 (57)`; Licenses.
- **Update banner** (Android APK channel, when newer): a banner strip `UPDATE AVAILABLE · 3.5.1 (58)` with `Installed 3.5.0 (57)`, `Download update` (primary sm) and the two notes ("Downloading doesn't install it automatically." / "Updating from 1.2.x? Uninstall the old app first."); after the download starts, the "Install now" dialog with three numbered steps (folios `01 02 03`).
- Narration indicator row when jobs run.

**Desktop.** `/more` renders the same index in two columns with a column rule (reachable by URL; the sidebar covers these destinations).

**Signature moment.** The dot leaders draw themselves (a clip reveal left → right, 320 ms, rows staggered 24 ms) the first time the index opens in a session.

**Transitions.** Cut in; Page to each destination.

**States.** Loading (values show `–`); unread count failure (value hidden); offline (values from cache, `OFFLINE EDITION` badge).

### 4.29 What's new and app updates · mobile G8, G9 · web G40 · S28 #22–23

- **What's new** (shown once after an update, and from Index → What's new): a `[0.92]` sheet / desktop dialog set as **errata and additions**: kicker `WHAT'S NEW`, title "Release notes"; entries per version: version folio in Plex Mono 15 (`3.5.0 · BUILD 57 · 28 SEP 2026`), a `LATEST` badge on the first, highlights as a list with `—` dashes in Newsreader 16. Loading (leader), unavailable ("Release notes aren't available right now."). Data `GET /app/changelog`.
- **Android APK update**: Index banner (§4.28) and Settings → About card (up to date `UP TO DATE — 3.5.0` in `set`; available `3.5.0 → 3.5.1` + `Download update`; unreachable "Couldn't check for updates."). Re-checked on every resume.
- **iOS SideStore**: Settings → About card "Managed by SideStore" + explanation + the source URL in `type.folio` (selectable) + `Copy source URL` (toast "Source URL copied") + caption on the 7-day signature.
- **Web service-worker update**: a subtitle toast that does not time out: "A new edition is ready." + `Reload` (posts `skip-waiting`, reloads).

---

### 4.30 Settings · web R26 (SG1–SG40) · mobile S28–S34 · K01–K51

#### 4.30.1 Structure

**Desktop.** Two panes: a left **table of contents** (3 columns) with numbered sections and a settings search at its top ("Search settings", matches labels and keywords, results jump to the row and flash it with a `spot.wash` band for 1200 ms); the right pane (9 columns, max 720 px of controls) shows one section at a time (route `/settings/:section`). Rows are §3.16 settings rows; each section starts with a section header (§3.27) and ends with a section rule. A footer line: "Settings save as you change them. Changing the edition restarts the app."

**Phone.** `/settings` is the table of contents (a credits list with folios and current values after dot leaders); each section is a pushed page (Page transition). Search is a running-head action opening a full-screen search list.

**No-profile guard**: sections that store per-profile values show a `NOTE` banner "No reading profile is active, so there's nowhere to save this yet." + `Choose a profile`, and their controls are disabled.

#### 4.30.2 Sections and every control

| # | Section | Controls (inventory keys) |
|---|---|---|
| 01 | **Profile & account** | Profile block (avatar, name, mood; `Switch profile`, `Manage profiles`); shortcuts `Reading history →` and (admin) `System status →`; account (display name, `@username`, `ADMINISTRATOR` credit); `Password & security` (→ §4.30.4); `Members` (admin → §4.30.5); `Sign out` (dialog "Sign out on this device?") |
| 02 | **Appearance** | **Edition** (the skin picker, §4.30.3); Reduce motion in the app (`SYSTEM · ON`; `ON` forces the reduced variants regardless of the OS); Reading mode (Manga / Novels, when enabled) |
| 03 | **Reading: manga** | Defaults for new series: layout, direction (K01/K37), fit (K02/K36), tap zones (K03/K34), strip taps, swipe sideways for chapters, cinema (K30), gap between pages (K29), keep screen awake (K05), auto next chapter (K06), lock controls (K07), volume keys (K08, Android), refresh rate (K04, Android), ground (K11), colour (K12), brightness and warmth defaults (K09/K31, K10/K32); `Reset reader settings` (dialog) |
| 04 | **Reading: novels** | Default face, size, line spacing, measure (K41–K44 defaults for new books), layout (scroll / paged), page turn, stock (K40), bold text, justify, "Auto next chapter" |
| 05 | **Listen** | Voices (→ the 31-voice cast list, §4.16.5), default speed, sleep timer default, shake to extend, auto-play the next chapter (the 5 s countdown on/off), keep the player visible |
| 06 | **Ambient** | Soundscape default (`MATCH THE MOOD` or a named loop) and volume; page-tinted chrome; auto-scroll default speed; resume after I let go |
| 07 | **Downloads & storage** | The STORAGE tab controls (§4.23) + Save to Files info + caches |
| 08 | **Content** | Show mature content (18+) switch → certificate (§3.24) (K1/K30); sources shortcut (`Manage pinned sources →`) |
| 09 | **Circle & privacy** | §5.3.6 (sharing switches per profile) |
| 10 | **Feedback** | Haptic feedback (K13, app; default on); UI sounds (default **off**) + volume; "Play a sample" (quiet, plays `set`) |
| 11 | **Notifications** | Per-profile: "Notify me about new chapters" master; admin (instance-wide, K19–K22): schedule strip (`LAST CHECK 21:04 · NEXT ≈ 21:34 · EVERY 30 MIN`, overdue in `NOTE` tone "Expected 12 min ago. See System status."), "Check automatically" switch, "Check on startup" switch, interval slider 5–120 step 5 (`30 MIN` folio; "The server enforces a 5-minute floor."), "Notify about new chapters" master; draft-then-`Save` with "Saved." / error; the recent-checks list; source cache TTL (≥ 5 min, admin) |
| 12 | **Keyboard** (web, iPad) | The live shortcut registry grouped (General, Navigation, Library, Search, Sources, Reader, Novel reader, Listen) as credits rows with keycaps; "Single-key shortcuts" switch (default on) |
| 13 | **Server** (app) | "API base URL" field (validated, HTTPS in release), `Save` (toast "Server address saved and applied."), `Reset to default` |
| 14 | **Admin** | `Backup & restore` (→ §4.30.6), `Members` (→ §4.30.5), `System status` (→ §4.31) |
| 15 | **Diagnostics** (app) | → §4.30.7 |
| 16 | **About** | Version and build, What's new, update card (Android) or SideStore card (iOS), Licenses (Flutter `LicensePage` restyled: Bodoni masthead, Newsreader text, package names in Plex Mono) |

Not part of this skin, by decision: palette and preset pickers (K24, K25, mobile K22, K23, S31; the app is dark only with no accent picker, and the edition covers the rest) and a language picker (mobile K14; it arrives with localisation).

#### 4.30.3 The edition picker and the restart ("Stop the press")

**Picker (Appearance → Edition).** Kicker `EDITION`, subhead "Two versions of the same app." Two cards side by side (stacked on phones), each 3:4:
- A still of that skin's home at 9:16 (a pre-rendered WebP from the screenshot harness, `design/previews/{skin}.webp`) running a slow Drift, framed by a 1 px `rule.2` border.
- Under it: the edition name in `type.subhead` (Cinematic in Bodoni Moda; Glass's name set in Glass's own display face so the card previews its type), a one-line description ("Cinematic: black stock, film titles, a magazine's rhythm." / "Glass: layered glass, springs and depth."), and either the badge `THIS EDITION` or the secondary `Switch to Glass`.
- Caption under both: "Switching restarts the app. You'll come back to this page. Your edition follows this profile to every device."

**Confirm** (dialog on desktop, sheet on phones): title "Restart in Glass?"; body "The app closes and reopens in the Glass edition, on this page."; when the download queue is not empty, an extra line "Downloads resume after the restart."; actions `Restart in Glass` (primary) and `Stay in Cinematic` (quiet).

**Outgoing sequence** (≤ 1.2 s, inside the 1.5 s budget from confirm to the new splash):

| t (ms) | Motion |
|---|---|
| 0–240 | The whole screen racks out of focus: `blur.defocus` 0 → 6 px and brightness 1 → 0.3, `turn` |
| 120–496 | Column blades close top-down (§4.14.2 close, 16 ms stagger) |
| 496–896 | On black, the masthead wordmark sets in the centre (letter reveal compressed to 400 ms, 16 ms stagger) with the Oxford rule drawing under it |
| 896 | Haptic `skin.switch`; sound `impress` if on |
| 896–1096 | Hold; the profile `PATCH` has already been sent at t = 0; the cookie / SharedPreferences mirror and the return route are written |
| ~1100 | Restart: web `location.replace(returnPath)` (after the `skin-changed` service-worker message); Flutter `AppRestart.restart()` |

The Glass skin's splash follows (its own responsibility). Coming the other way, when Glass restarts into Cinematic, Programme's cold-start reveal plays and then a 10 s subtitle toast: "Now in the Cinematic edition." + `Undo` (restarts back with the same outgoing sequence, no confirm). Reduced motion: 200 ms fade to black, the masthead fades in 200 ms, restart.

#### 4.30.4 Password & security (web SG29–SG39, mobile S29)

- **Change password**: fields Current, New ("At least 8 characters"), Confirm; each with Show/Hide; validation lines (empty, too short, too long, mismatch, same as current); `Change password` primary; caption "Changing it signs out every other device. This one stays signed in."; success toast "Password changed. Every other device has been signed out."
- **Where you're signed in**: rows per session: device label (parsed user agent: "ManhwaManiacs app on iPhone", "Firefox on Linux", "Unknown device"), `THIS DEVICE` badge (row with `spot` left bar), `LAST USED 3 H AGO · 10.0.0.2`, `SIGNED IN 12 SEP · EXPIRES 19 SEP`; actions: current row `Sign out` (secondary), others `Revoke` (quiet `proof`, dialog "Sign out {device}? It will have to sign in again."). `Refresh` (quiet, spins). States: loading, error, "No active sessions."
- **Sign out everywhere**: a destructive area (`proof.wash` background, `rule.proof` left edge) with the explainer "Revokes every session, this device included. Saved chapters stay on this device." and `Sign out everywhere` → dialog with the acknowledgement checkbox "I understand this signs me out here too".

#### 4.30.5 Members (admin; web MB1–MB7, mobile S30)

- Desktop: a table (min 640 px, horizontal scroll inside its own container) with columns `MEMBER` (username + `ADMIN` / `YOU`), `STATUS` (`ACTIVE` in `set` / `DEACTIVATED` in `proof`), `JOINED`, `LAST SEEN`, `SESSIONS`, actions `Deactivate` / `Reactivate` (secondary sm) and `Delete` (quiet `proof`). Own row tinted `paper.4`, actions disabled with the tooltip "You can't deactivate or delete your own account."
- Phone: one block per member with the same facts as credits and the actions below.
- Explainer: "Registration is open. Deactivating signs a member out everywhere and blocks sign-in; deleting removes everything they own."
- Delete dialog: "Delete @{user}? Their profiles, library, progress, bookmarks and everything else they own are removed. This can't be undone." + a field "Type {username} to confirm".
- Footer: "{n} other accounts." + `Refresh`. States: loading, error, empty ("Only your account so far.").

#### 4.30.6 Backup & restore (admin; web BK1–BK5, mobile S33)

- **Staged restore banner** (when `restore_pending`): `NOTE` banner "A restore is staged. It applies the next time the server starts; the current database is kept." + `Cancel staged restore`.
- **Nightly backup** card: `LAST NIGHTLY · OK · 28 SEP 03:00 · 412 MB` (or `UNKNOWN`, never shown as healthy).
- **Export**: explainer (the whole database, every account; keep it private), switch "Include caches (larger, warmer restore)", `Export backup` (primary; web downloads the file and shows "Saved {filename}"; mobile opens the download in the browser) and errors.
- **Restore**: a destructive area: explainer (replaces everything at the next restart), `Choose backup file` (secondary; `.db` only; "{name} · 412 MB" or "No file chosen. Nothing is uploaded until you confirm."), validation ("That isn't a .db file.", "That file is empty."), `Restore from this file…` (destructive) → dialog with four bullets (replaces every account; sign-ins come from the backup; applies on restart; nothing of the current state is kept) and "Type RESTORE to confirm"; then "Restore staged. Restart the server to finish." dialog.

#### 4.30.7 Diagnostics (app; mobile S34)

Sections with kickers `RENDERING`, `DISPLAY`, `DEVICE`, `IMAGE CACHE`: three big numerals (Bodoni) `FPS 119`, `JANK 1.2 %` (`set` < 5, `spot` < 15, `proof` above), `WORST 14 MS`; rows for average frame time, build and raster times, samples ("Collecting frames… scroll a screen to sample."); display (Android: current refresh rate, capability, resolution; switch "Use the highest refresh rate everywhere" (K21); iOS: "Display modes can only be switched on Android."); device (OS, cores, screen, app version, build mode); image cache (live, cached n / max, memory). Plus a developer switch "Show the layout grid".

---

### 4.31 System status (admin) · web R27 (AS1–AS10)

- Masthead: kicker `ADMINISTRATION`, title "System status", deck "Backend health, the update checker, per-source failures and update runs." + `Refresh all` (quiet, spins); a live folio `LIVE · 15 S`.
- **Summary**: a banner strip tinted by the worst state (a left rule in `set` / `spot` / `proof` / `ink.45`), the headline typed ("Everything is running." / "2 things need attention."), and a list of problems.
- **Backend**: credits `STATE HEALTHY`, `NAME`, `VERSION 3.5.0` (Plex), `PROBE GET /health`.
- **Update checker**: `LAST RUN 21:04 · 12 MIN AGO`, `NEXT ≈ 21:34 · IN 18 MIN`, `INTERVAL 30 MIN`, `FAILED RUNS (RECENT) 0` (proof when > 0), server error block in Plex Mono on `paper.1`, `Check now` (secondary).
- **Recent checks**: up to 8 rows: status badge (`COMPLETED` set / `RUNNING` spot / `FAILED` proof), trigger, `212 SERIES · 3 NEW`, time, error text.
- **Source health**: a table sorted worst-first: mark, name, id (Plex), `DEMOTED` badge, `LAST PROBE 4 MIN AGO`, message, last error (collapsible Plex block).
- Footer note in `type.caption`.
- Phone: sections stacked; tables become blocks.
- Non-admin: notice `ADMINISTRATORS ONLY`: "System status is instance-wide. Ask the owner to check it." + `Back to Tonight`.
- States: resolving (masthead only), each card's loading and error.

---

### 4.32 Status screens · web S1–S5, E1–E4

| Screen | Presentation |
|---|---|
| **404** (inside the frame) | A folio numeral `p. 404` in Bodoni Moda Roman at `type.numeral` × 1.5 in `ink.30`; kicker `NOT IN THIS ISSUE`; headline typed "This page doesn't exist."; deck "It may have been renamed, or the series it pointed to left your library. Press ⌘K to search everything."; `Back to Tonight` (primary), `Open library` (quiet) |
| **Route error** | `CORRECTION` notice: "Something broke on this page." / "Nothing was lost; trying again usually fixes it." + `Try again` + `Back to Tonight` + a `REF 7F3A…` keycap (the digest). Backend unreachable variant: kicker `OFFLINE EDITION`, "The server didn't answer." / "It may still be starting, or the connection dropped. Your library is untouched." |
| **Root error** (own document, no fonts loaded) | Pure HTML on `#000`: the wordmark as inline SVG, "ManhwaManiacs failed to start." in a system serif, the explainer, `Try again` and `Reload the app` buttons styled inline (square, bone fill) |
| **Offline fallback page** (`/offline-fallback.html`, served by the service worker) | Standalone HTML with inline styles in this skin (and a Glass version chosen by the `mm-skin` cookie at fetch time by the worker): the `mm-mark` SVG 72 px, a live status badge `NO CONNECTION` / `BACK ONLINE`, headline "This page needs the server.", deck "Chapters you saved still open on this device.", note "Served from your device by the app.", `Try again` and `Downloads` |
| **Reader landing** (`/reader`) | Notice: kicker `READER`, "Open a series to start reading." + `Go to library` |

---

### 4.33 Global overlays

#### 4.33.1 Command palette: "Index" (web `mod+k`)

- Scrim `scrim.modal`; panel `paper.2`, 1 px `rule.2`, max width 720, max height 70 vh, placed 12 vh from the top; Insert motion.
- The index field (Bodoni Italic 28) with the placeholder "Search or jump…" and an `Esc` keycap.
- Results grouped by kicker, in rank order: `LIBRARY` (series from `/library/search`, 220 ms debounce, 40 × 60 covers), `SOURCES` (logos), `GO TO` (every route with its folio: "02 Library", "10 The Numbers"), `ACTIONS` (Continue {series}, Check for updates, Open settings, Toggle reading mode, Sign out), `EDITION` ("Switch to the Glass edition…" → the restart confirm), `SETTINGS` (every setting row by name). Max 40 results, fuzzy matched with matched characters in `spot`.
- Row: leading visual, title, subtitle (`type.caption`), the `↵` glyph on the active row; hover moves the highlight (`paper.4` + ink bar).
- Footer keycaps: `↑ ↓` navigate · `↵` open · result count.
- Live region: "Searching…" / "12 results". Empty: "Nothing matches "{q}"."
- Keys: `Esc`, `↑/↓` (wraps), `Home`/`End`, `Enter`, `mod+k` closes.

#### 4.33.2 Keyboard sheet (`?`)

A dialog (max 720) titled "Keyboard" with the intro "Only what works on this screen is listed. Shortcuts pause while you type in a field." and groups as two-column credits lists (description → dot leaders → keycaps). Empty: "No shortcuts on this screen." Also reachable from the reader's setup sheet and Settings → Keyboard.

#### 4.33.3 Stop-press banner (new chapters)

When unread notifications arrive (60 s poll) and the user is not on Updates or in a reader: a subtitle-style strip bottom-centre (desktop, max 672) or above the thumb index (phone): kicker `STOP PRESS`, "4 new chapters across 3 series." + `Read updates` (→ Updates) + `x` (dismiss; hidden until a newer notification, `sessionStorage` on web). In the novel reader it appears in the stock colours at the top edge instead of the bottom, never over the text column's current line.

#### 4.33.4 First-run note

When the profile follows nothing, a banner strip under the running head on every screen except Tonight, Discover and the readers: kicker `NOTHING FOLLOWED YET`, "Follow a series from Discover to start your shelf." + `Discover`. Not dismissible (it disappears with the first follow).

#### 4.33.5 Toasts, rating card, offline badge

Toasts §3.11; rating card §3.24; offline badge §3.13.

---

### 4.34 Public install page (`GET /`, backend-served)

A static page in this skin's language (it is the brand's public face; content from `_SHOWCASE`): the masthead wordmark with its Oxford rule; cover lines ("Every source. One shelf." / "Novels, read aloud." / "Your year in chapters." / "Read together."); install instructions as numbered steps with folios (`01 Android: download the APK`, `02 iPhone: add the SideStore source`); the "Poster" screenshot set (§7.6); the changelog as release notes (§4.29). Inline CSS, fonts self-hosted from the backend's static folder (Bodoni Moda, Archivo subsets), no JavaScript.
---

## 5. The four new features

All four are designed server-first (stack-decision §2.6): each client only renders. Every payload below is filtered by the active profile and applies the 18+ gate when serving, never when storing.

### 5.1 AI home, recommendations and "Previously on"

The AI is the magazine's **editorial desk**: it picks tonight's cover story, writes the decks and the "why" lines, and recaps what happened before you continue. It is an external AI API only (the existing DeepSeek-backed suggest path), with a daily budget and a visible "desk closed" state.

#### 5.1.1 Surfaces and entry points

| Surface | Entry points |
|---|---|
| Tonight's cover story and deck (§4.8) | Home tab, sidebar `01`, after the iris |
| Picked for you, Because you read X (Tonight rails) | Tonight; each rail's `See all` → Picks |
| Picks screen (§5.1.3) | Sidebar `12 Picks`, Index, Discover `ASK THE EDITORS`, Discover `ASK` scope, Tonight `See all` |
| More like this (§5.1.4) | Feature page tab `03`, chapter-end credits when caught up, Quick look `More like this` |
| Previously on (§5.1.5) | Tonight `Previously on…`, feature/book page button, Quick look on cuttings, the reader's first-page chip after an absence, the setting "Recap before continuing after 14 days away" |
| Not for me | Every AI card: hover `x`, long-press menu, keyboard `Delete` |

#### 5.1.2 Tonight's cover story: selection and headline

The home feed (`GET /home`, §5.1.7) returns sections in order; section 0 is the cover story. Selection, in priority order (the backend composes, the client falls back to the same rules locally when the feed is unavailable):

1. A followed series in progress with **new chapters since the last read** (most recent `last_read_at` first).
2. A chapter **in progress** (unfinished, read within 21 days).
3. A followed series **paused 7–60 days** with a recap available ("pick it up again").
4. The top **AI pick** for this profile (world recs `for_you[0]` with `available` sources).
5. A popular series on a pinned source (new profiles).

Headline composition (≤ 60 graphemes, sentence case, one full stop; the time word follows the local hour: "This morning" 05–11, "This afternoon" 12–17, "Tonight" otherwise):

| Case | Headline | Deck |
|---|---|---|
| 1 | "Tonight: chapter 143 of Omniscient Reader." (if > 60, "Tonight: chapter 143." and the title moves to the kicker) | AI one-liner: "Dokja finally meets the author. You stopped two chapters before it." |
| 2 | "Tonight: finish chapter 142. Twelve pages left." | "You were on page 28 of 40 two days ago." |
| 3 | "Tonight: back to Tower of God." | "You paused 23 days ago at chapter 87. Previously on is ready." |
| 4 | "Tonight: start Lookism." | the `why` line |
| 5 | "Your first issue starts here." | "Follow three series and this page fills itself in." |
| caught up | "Tonight: you're caught up." | "Nothing new on your shelf. Here's something else." |

Numbers under ten are spelled out in headlines; chapter numbers are always numerals.

#### 5.1.3 Picks screen (`/library/recommendations`)

**Desktop layout.**
- Masthead: kicker `No. 12 — PICKS`, title "Picks", deck by state: "Describe it in your own words. Suggestions are weighed against what you already read." / "You've used today's asks. They reset at midnight UTC. The picks below still work." / "Titles from everywhere, picked from what you read."
- **Ask block** (columns 1–8): the index field in prompt mode, placeholder typed and cycling every 6 s through examples ("A murim regressor who comes back stronger", "Magic academy, but the lead is already strong", "Something slow and political, not a power fantasy"); textarea behaviour (Enter submits, Shift+Enter newline, 3–600 characters with a `12 / 600` folio); the three examples also as a slug line of quiet buttons that fill and submit; `Ask the editors` (primary, with `sparkle`); the quota folio `8 ASKS LEFT TODAY` (shown at ≤ 10). Source toggle: `FROM YOUR SOURCES │ FROM EVERYWHERE` (maps to `/library/suggest` vs `/library/world/suggest`).
- **Results** (after an ask): kicker `THE EDITORS SUGGEST`, then result cards as **mini reviews** in two columns: World cards (§3.6) with the `why` as the pull quote. The answer streams: a line "Reading your shelf…" types itself, a leader dial appears after 1 s, and each card fades in 160 ms as it arrives (30 ms apart). Up to 40 s before the timeout copy.
- **For you** (a section with folio `01`): a grid of World cards (3 per row desktop).
- **Because you read {title}** (`02`, `03`, … one per seed): rails of World cards.
- Aside (columns 9–12, ≥ 1440): "Your genres" as a weighted slug line (size from `/library/recommendations`), each a link into Discover genres.

**Phone layout.** Ask block full width with the field at 28 px; results one column; For you as a two-column grid; Because-you-read as rails; aside moves under the ask block.

**World card behaviour.** Available → opens the series (a source picker sheet when several sources have it: logos, names, health marks, `Open`). Information-only → `Search my sources` (Discover with `?q=`) and `Read on {site} ↗` (external, "Couldn't open {url}" toast on failure). `Not for me` hides the card (a 240 ms fade and the grid closes the gap by Cut) and sends `POST /ai/feedback {anilist_id | source/series, signal: "not_interested"}`.

**States.**

| State | Presentation |
|---|---|
| Loading world recs | Masthead live; `01 For you` header with 6 flicker plates |
| AI thinking | "Reading your shelf…" typed, leader after 1 s, cards stream |
| AI not configured (`reason: not_configured`) | Ask block replaced by a `NOTE` line: "The editors' desk isn't set up on this server." World recs still show. |
| Budget exhausted | Ask field disabled, caption "Today's asks are used up. They reset at midnight UTC." |
| No matches (`ai_no_matches`) | Notice in the results slot: "Nothing fit that description. Try describing it differently." |
| Rate limited | `SLOW DOWN` line with the `Retry-After` countdown |
| World catalogue unreachable (`unavailable_reason`) | A quiet caption under the masthead with the server's reason; cached recs shown |
| Empty (new profile) | Notice `NOTHING TO GO ON YET`: "Read or follow a few series first. Picks start from what you read." + `Find something` |
| Offline / error | Notices with Retry |

**Keys (web).** `/` focuses the ask field; `Enter` asks; `j`/`k` move through cards; `Delete` = Not for me on the focused card.

#### 5.1.4 More like this and Because you read

- **Similar** (`GET /ai/similar?source&series`, §5.1.7): a rail on the feature page's `03 MORE LIKE THIS` tab and in the caught-up end state; World cards with `why` lines ("Same regression premise, darker art."). Fallback when AI is unavailable: series sharing ≥ 2 genres on the profile's sources, captioned `SAME GENRES` instead of a `why`.
- **Because you read X**: rails on Tonight and Picks with the seed's title in the H3 (the title in italic inside the italic head is set in Roman for contrast: "Because you read *Solo Leveling*").
- **In-session re-ranking**: after the reader opens a series from a rail, the next visit to Tonight moves rails that share its top genre up by one position (client-side, per session).

#### 5.1.5 "Previously on" (`/recap/:sourceId/:seriesKey?to=:chapterKey`)

A takeover set as a **title card**, the editorial moment before the feature resumes.

**Layout (all platforms).**
- Background `#000` with the series cover as a duotone band across the top 28 % (phone 34 %), `scrim.foot` into black, grain 0.05.
- Kicker `PREVIOUSLY ON` with the letter reveal, then the series title in `type.headline` italic; deck: "Chapters 131–142, as a recap." (the covered range).
- **The recap**: 3–5 short paragraphs in Newsreader 20/32 (phone 18/28) at 58ch, streamed word by word (160 ms fade, 30 ms apart), with a Bodoni drop cap on the first paragraph. Character names in italic.
- **Cast list** (novels, from attribution `cast`; manga when the recap names characters): a credits list `Kim Dokja ........ the reader` with dot leaders; "Characters in this story" kicker.
- Footnote in `type.caption`: "Recap written from the dialogue of chapters 131–142." (manga, OCR-sourced) or "…from the text of chapters 131–142." (novels) + "AI-written; it can be wrong."
- Actions (sticky at the bottom on phones): `split` primary `Continue │ CH 143` (Column wipe into the reader), `quiet` `Skip recaps for this series` (per-series preference), `quiet` `Close`.
- Desktop: the recap column spans columns 3–9; the cast list sits in columns 10–12.

**Entry behaviours.** From a Continue button: only when the user chose `Previously on…` or when the setting "Recap before continuing after 14 days away" is on and the gap is ≥ 14 days (then the recap opens first and `Continue` proceeds). In the reader: a slim chip on the first page, `PREVIOUSLY ON · 2 MIN` (quiet button), when the last read of this series was ≥ 14 days ago and a recap is available.

**States.**

| State | Presentation |
|---|---|
| Loading | The title card with kicker and title set; "Writing the recap…" typed; leader after 1 s |
| Streaming | Words fade in; `Continue` is usable at any time |
| No recap (manga with no indexed dialogue in the range) | Kicker `NO RECAP FOR THIS ONE`; "The dialogue in these chapters hasn't been read yet, so there's nothing to recap." + `Continue │ CH 143` (app: `Scan saved chapters` when some are downloaded) |
| AI unavailable / not configured / budget spent | A static slate: kicker `RECAP UNAVAILABLE` in `ink.45`; "Pick up where you left off: chapter 143." + `Continue`. Never error red: an absent recap is not an error. |
| First chapter (nothing to recap) | The button never appears |
| Offline | The slate as AI unavailable, with `OFFLINE EDITION` |
| Error | `CORRECTION` line + `Try again` + `Continue` |

**Keys (web).** `Enter` continue; `Esc` close; `Space` skips the streaming (shows all text).

#### 5.1.6 When the AI desk is closed (fallbacks)

The app never looks broken without AI:
- Tonight's cover story uses the local priority rules (§5.1.2 cases 1–3, else the most recently updated followed series) and the synopsis as the deck.
- `03 Picked for you` becomes `03 From your shelf` (favourites and plan-to-read), headed by a `NOTE` line "The picks desk is closed tonight."
- Because-you-read rails come from world recs when that catalogue is reachable (not AI-dependent); otherwise they are omitted.
- Picks shows world recs without the ask block; recaps show the static slate; Similar uses the genre fallback.

#### 5.1.7 Backend contract (new endpoints; the AI calls stay server-side)

| Endpoint | Returns | Notes |
|---|---|---|
| `GET /home` | `{issue_no, headline, deck, cover: {source_id, series_key, chapter_key, reason, ambient}, sections: [{type, title, seed?, items, why?}], ai: {available, reason}}` | Composed from continue, recently-updated, world recs, taste and circle; cached 10 min per profile; 18+ gated on serve |
| `GET /ai/similar?source&series` | World items with `why` | Seeded similarity; budget-free cache 7 days |
| `GET /ai/recap?source&series&to` | Streamed text (SSE) + `{range, cast, sourced_from: "ocr" | "text", available, reason}` | Built from OCR `page_texts` (manga) or paragraphs (novels); cached per (series, range) |
| `POST /ai/feedback` | 204 | `not_interested`, `liked_pick` |
| `PUT /profiles/{id}/taste` | taste | Onboarding (§4.7) |

---

### 5.2 Reading stats, streaks and The Annual

Statistics are the magazine's **back-of-book numbers**: set in Bodoni numerals, with rules instead of chart chrome.

#### 5.2.1 The Numbers (`/library/statistics`)

**Desktop layout.**
- Masthead: kicker `No. 10 — THE NUMBERS`, title "The Numbers", deck "What you've actually read on this profile."
- Range contents tabs: `7 DAYS · 30 DAYS · 90 DAYS · YEAR` (default 30; YEAR = `days=365`); remembered per profile.
- A banner strip when The Annual is available (§5.2.4): `THE ANNUAL 2026 IS OUT` + `Open` (from 1 December, or any time with ≥ 30 days of data as "Your year so far").
- **Lead**: the streak block (§5.2.2) in columns 1–4; four stat blocks (§3.6) in columns 5–12: `CHAPTERS 184` ("1,240 all time"), `TIME 31 H` ("412 h all time"), `PAGES 6,812` ("48,221 all time"), `SERIES 23` ("212 followed").
- **Chapters per day** (columns 1–8): bars of 1-day width with 2 px gaps in `ink.100`, the selected or hovered day in `spot`; time per day as a dotted `ink.45` line with square 4 px markers; left axis chapters, right axis time (`type.folio`), 4–6 date labels; a readout line above the chart ("Mon 21 Sep · 12 chapters · 1 h 40 m"); "Best day 14 Sep · 31 chapters" aside. On YEAR range, a **heatmap** replaces it: 53 × 7 squares (10 px, 2 px gaps), 4 heat levels (§2.1.6), today outlined in `spot`, month labels in `type.folio`.
- **When you read** (columns 9–12): a 24-hour clock chart as 24 radial bars (a 160 px circle, bars from 40 to 80 px radius, `ink.100` at opacity by value) with hour labels at 0, 6, 12, 18 and the headline typed under it ("A night reader: most of it after 22:00.").
- **Genre radar** (columns 1–4): the top 6–8 genres from `/library/recommendations` as a radar: 1 px `rule.1` rings at 25/50/75/100 %, the profile polygon in 1 px `ink.100` with 4 px `spot` square vertices, genre labels in `type.kicker` at the spokes.
- **Where you read** (columns 5–8): sources ranked with a 2 px determinate rule for share, "MangaDex · 812 pages · 9 h · 41 %".
- **Most read** (columns 9–12): ranked list with Bodoni numerals `1`–`5`, 40 × 60 covers, "412 pages · 38 chapters · 6 h", last read.
- **Recent sessions** (full width): log rows (time, series, chapter link, pages, duration).
- **Your library** (columns 1–6): `212 FOLLOWED · 3 FAVOURITES · 1,904 CHAPTERS FINISHED` and per-status rows with rules.
- **Footnotes** (magazine style, superscript numbers referenced from the stat blocks): "¹ Days start at UTC+05:30. ² Each session counts up to 30 minutes of reading time. ³ Recording since 27 July 2026. Totals cover manga and novels; the lists below follow the reading mode."

**Phone layout.** Range tabs scroll; streak block full width; stat blocks 2 × 2; charts full width (chapters per day 160 px tall; tap a bar to read it; tap again clears); clock and radar at 240 px; lists stacked. Pull to reprint.

**Signature moment.** Numerals are **typed** (50 ms per character) rather than counted up, so each figure appears like a line being set on a press, while rules under them draw in reading order.

**States.** Loading (galley: 4 numeral bars, chart plate, list bars); no reading yet (`NOTHING RECORDED YET`: "Read a chapter and your numbers start here." + `Go to library`); followed but never read (the library block only); offline (cached figures with `OFFLINE EDITION`); error (+ Retry).

**Keys (web).** `1`–`4` ranges; `←`/`→` move the selected day in the chart; `a` opens The Annual.

#### 5.2.2 The streak flame

| State | Presentation |
|---|---|
| Alive, read today | `flame` Fill 32 px in `spot` with a `spot.glow` bloom (the one glow in the UI), a 2 s flicker (opacity 0.85 ↔ 1, scaleY 0.98 ↔ 1.02, `drift`); the numeral `12` in `type.numeral` beside it; caption `DAYS IN A ROW · LONGEST 31` |
| Alive, not yet today | Flame outlined (Light, `ink.100`), no bloom; caption "Read today to keep your 12-day streak." |
| Broken / none | Flame Light `ink.45`; caption "Longest: 31 days. Start a new one today." |
| Just extended (first completed chapter of the day, seen on the next visit to Tonight or The Numbers) | The flame **ignites**: stroke → fill over 400 ms `settle` with the bloom rising 0 → 0.35, the numeral types its new value; haptic `streak.extend`; sound `bell` if on |
| Week dots | Under the numeral: 7 squares (Mon–Sun, 8 px, 4 px gaps), `spot` for days read, `rule.2` outline otherwise, weekday initials in `type.micro` |

The same flame (24 px) sits in Tonight's section 09 and in the Index row.

#### 5.2.3 Chart rules

No gridlines except `rule.1` baselines; numbers in Plex Mono; every chart has a text summary above it (for screen readers and at-a-glance reading) and each data mark has an accessible label ("21 September, 12 chapters, 1 hour 40 minutes"). Charts are drawn with SVG on web and `CustomPainter` in Flutter; no chart library.

#### 5.2.4 The Annual (`/library/statistics/annual/:year`)

A **Wrapped-style year recap set as a special issue**: ten pages, each a spread on desktop and a 9:16 story page on phones.

**Frame.**
- Phone: full-screen takeover; a row of ten 2 px segments at the top (current segment fills `spot` over the page's hold time); close `x` top-right; tap right third → next, left third → previous, press and hold → pause (segments freeze), swipe down → close. Auto-advance 6 s per page (8 s for pages with lists). Haptic `annual.page` on tap advance.
- Desktop: a 2.39:1 matte centred in the viewport (black bars above and below) holding a spread: left page (text) and right page (art); `←`/`→`, `Space` pause, `Esc` close; auto-advance off by default (a `PLAY` toggle turns it on).
- Every page: duotone art in the profile's top series' `ambient.duo`, grain 0.06, the page title with the letter reveal, the key figure typed.

| Page | Content |
|---|---|
| 1 Cover | Masthead `The Annual` in Bodoni Moda Italic `type.cover`, `2026` numeral, "An issue about {profile}'s year in reading", issue line `No. 1 · 29 SEPTEMBER 2026`; art = a mosaic of the year's top 9 covers in duotone |
| 2 Time | "You read for 212 hours." (numeral typed), deck "That's nine days, cover to cover."; art: the top series' cover |
| 3 Chapters | "4,812 chapters." + a chapters-per-month bar strip (12 bars) |
| 4 Your No. 1 | "Your most-read: Omniscient Reader." + cover full-bleed + 38 chapters / 12 h; then No. 2–5 as a ranked list |
| 5 Genres | The genre radar at page size + "A fantasy reader, with a streak of romance." |
| 6 The clock | The 24-hour clock + "A night owl: 71 % after 22:00." |
| 7 The streak | The flame + "Longest streak: 31 days, in March." |
| 8 Sources | "MangaDex did the heavy lifting." + the top 3 sources with shares |
| 9 The circle (only with Circle sharing on for this profile and at least one other sharing member) | "You and Riya both finished Solo Leveling." + both avatars; otherwise the page is skipped |
| 10 Press run | The share page: the six card templates (§5.2.5) as thumbnails, `Share` (primary), `Save image` (secondary), `Read the numbers` (quiet → The Numbers) |

Rolling windows: the backend statistics window is rolling 365 days; until a calendar-year aggregate exists, the cover reads "Your last twelve months" and the URL year is the current year.

**States.** Not enough data (< 7 days recorded): a single page "Your Annual needs a few more weeks of reading. 5 days recorded so far." + `Close`; loading ("Setting the pages…" typed, leader); offline (cached pages if previously opened, else notice); error.

#### 5.2.5 Share cards ("press run")

**Templates** (six): Time, Chapters, No. 1, Genres, Streak, Clock. Formats: **Story** 1080 × 1920 and **Post** 1080 × 1350, chosen in the share sheet.

**Card anatomy.** `#000` stock; a 64 px margin; top: kicker `THE ANNUAL 2026` and the profile name; centre: the key figure in Bodoni Moda Roman at 360 px (Story) with its caption in Newsreader Italic 48; a duotone art band (the relevant cover) across the lower third with grain; bottom: the wordmark at 40 px with its Oxford rule and `manhwamaniacs` in Plex Mono 24. All text is drawn, never screenshot from the UI.

**Export pipeline.**
- Web: a zero-dependency Canvas 2D renderer (`renderShareCard(kind, format, data): Promise<Blob>`), which awaits `document.fonts.load()` for the four faces, draws the duotone art through an offscreen canvas and the same colour matrix (§2.1.5), and exports PNG with `canvas.toBlob`. Sharing: `navigator.share({ files: [file] })` when `navigator.canShare({ files })` is true, else a download via an object URL.
- Flutter: the card is a widget rendered offscreen in a `RepaintBoundary`, captured with `toImage(pixelRatio: 1080 / logicalWidth)` and `toByteData(format: png)`; shared through `share_plus` 13.3.0 (`SharePlus.instance.share(ShareParams(files: [XFile.fromData(...)]))`); "Save image" writes to the photo library through the share sheet's own Save option (no photos permission plugin).
- Haptic `share.export` on render; the `set` cue plays if UI sounds are on.

**Privacy rules.** 18+ series never appear on a card, whatever the gate. Only the profile name (not the username or server) is printed. Circle cards name another member only when both profiles share with the circle.

#### 5.2.6 Entry points

The Numbers banner strip; Tonight section 09 (`Open The Numbers →`, and in December `The Annual is out →`); Index `The Annual`; a one-time toast on the first app open in December ("The Annual 2026 is out." + `Open`).

#### 5.2.7 Backend

`GET /library/statistics` (existing, `days` up to 365) covers the numbers. New: `GET /library/annual?year=` returning the ten pages' aggregates (time, chapters per month, top series, genre weights over the window, clock, longest streak with its month, top sources, circle overlaps) so both clients render identical figures; cached per profile per day.

---

### 5.3 Circle: social for two or three readers

The **letters page** of the magazine: what the other readers on this server are reading, reactions on chapters, shared shelves and recommendations passed by hand. Private by default, per profile, and blind to 18+ for anyone whose gate is closed.

#### 5.3.1 Model and privacy

- **Opt-in per profile.** Nothing is visible to anyone until a profile turns sharing on (Settings → Circle & privacy). The default state of the whole feature is "nothing shared yet".
- **Granular switches per profile**: `Share what I'm reading` (activity), `Show my reactions`, `Let others add me to shared shelves`, `Receive recommendations`, and `Include 18+ titles in my activity` (off by default; even when on, 18+ items are only served to viewer profiles whose own gate is open).
- **Isolation.** A viewer sees *profiles*, not accounts; the circle lists sharing profiles across all accounts on the server. A profile never sees another profile's library, history or bookmarks beyond the shared activity items.
- **Gate on serve.** Activity, reactions, shared shelf members and letters about 18+ series are filtered out for gated viewers; counts are computed after filtering.

#### 5.3.2 Circle screen (`/circle`)

**Desktop layout.**
- Masthead: kicker `No. 11 — THE CIRCLE`, title "The Circle", deck "What the other readers on this server are reading."
- **Readers strip**: sharing profiles as 44 px avatars with names; a `NOW` badge on anyone who read in the last 15 minutes; click → member page.
- Contents tabs: `ALL · READING · REACTIONS · LETTERS ² · SHELVES`.
- **Activity column** (columns 1–8): dispatches grouped by day (date rules). Each dispatch: 32 px avatar → sentence in Newsreader 16 with the series title in italic ("*Riya* finished chapter 88 of *Tower of God*.", "*Arjun* started *Lookism*.", "*Riya* reacted ♥ to chapter 142 of *Omniscient Reader*.") → time folio `2 H` → a 40 × 60 cover at the right (click → feature page) → a quiet `Read it too` for series the viewer doesn't follow.
- **Letters** (aside, columns 9–12): unread recommendation letters (§3.6 Letter card) stacked, newest first.
- **Shelves** tab: shared collection plates.

**Phone layout.** Readers strip scrolls horizontally; tabs scroll; dispatches full width with the cover at the right; letters are a tab, with a count badge.

**Signature moment.** A new letter **unfolds**: its card is revealed by a clip from the top edge down (like opening a folded note, 480 ms `settle`), the sender's kicker types itself, and the `spot` new-dot fades once it is read.

**States.**

| State | Presentation |
|---|---|
| Nothing shared yet (default) | Notice `THE CIRCLE IS QUIET`: "Nobody has shared their reading yet. Turn on sharing to be the first." + `Sharing settings` |
| This profile doesn't share | A `NOTE` banner "You're reading privately. Others can't see your activity." + `Share` (still shows others' activity) |
| Only me | "You're the only reader sharing so far." |
| Loading | 6 greeked dispatches |
| Offline / error | Notices |

**Keys (web).** `j`/`k` dispatches; `Enter` open; `1`–`5` tabs; `l` letters.

#### 5.3.3 Reactions on chapters

- **Where**: the chapter-end credits (manga and novels), the feature page's schedule rows (count folio), the reader's `CIRCLE` panel.
- **The five stamps** (square 44 × 44 outlined 1 px `rule.2`, glyph 20 + count folio): `♥` Loved (`heart`), `!!` Shook (`lightning`), `HA` Laughed (`smiley`), `…` Tears (`drop`), `✦` Chef's kiss (`sparkle`). Under each, the avatars (20 px) of circle members who pressed it.
- **Pressing**: the stamp fills `ink.100` with a `#000` glyph, translates 1 px down (impression) and its count types the new value; haptic `reaction.send`, sound `impress`; one reaction per chapter per profile (pressing another moves it; pressing the same one removes it).
- Reactions from gated or non-sharing profiles are not shown. Offline: queued and sent on reconnect, drawn immediately.

#### 5.3.4 Recommend to ("Pass it on") and letters

- **Entry**: feature/book page `paper-plane-tilt`, Quick look `Recommend to…`, the reader's `CIRCLE` panel, the chapter-end credits (`Pass it on`).
- **Sheet**: kicker `PASS IT ON`, the series cover 48 × 72 + title; recipients as avatar toggles (only profiles with `Receive recommendations` on; for an 18+ series, only recipients whose gate is open are listed, with the caption "Only readers who can see 18+ titles are listed."); a note field in Newsreader Italic ("Add a line…", 140 characters, `12 / 140`); `Send` (primary). Haptic `recommend.send`; toast "Sent to Riya."
- **Receiving**: a Letter card in Circle and a count on the Index row and the Circle sidebar item; Tonight's Also-in-this-issue may carry "Riya recommends Lookism". Actions `Read` (opens the series), `Add to library` (stamp), `Dismiss`. Reading a letter marks it read.

#### 5.3.5 Shared shelves

- A collection's `Share` action (owner) opens a sheet: members as avatar toggles, a mode `CAN ADD │ VIEW ONLY`.
- Shared plates show `SHARED` and the members' avatars; the detail header lists "Shared with Riya, Arjun"; each member poster shows the adder's 20 px avatar at the bottom-left when others added it.
- Members of a shared shelf see it in their own Collections under a `SHARED WITH YOU` section.
- 18+ members of a shared shelf are hidden from gated viewers (the count reflects what they can see).
- Leaving: `Leave shelf` in the overflow for non-owners.

#### 5.3.6 Settings → Circle & privacy

Rows: `Share what I'm reading` (master), `Show my reactions`, `Let others add me to shared shelves`, `Receive recommendations`, `Include 18+ titles in my activity` (only visible when this profile's gate is open), `Hide this series from my activity` list (series-level exclusions with add/remove), and `Clear my shared activity` (destructive, dialog). A preview line types what others will see: "Others see: *Yash* finished chapter 142 of *Omniscient Reader*."

#### 5.3.7 Member page (`/circle/:profileId`)

Masthead with the member's 96 px avatar and name in `type.masthead` italic; deck "Reading 4 series · shares activity and reactions"; rails `Now reading`, `Recently finished`, `Their reactions`; shared shelves; `Recommend something to Riya` (secondary, opens a series search then the Pass-it-on sheet). Only what the member shares is shown. States: not sharing any more ("Riya isn't sharing right now."), loading, error.

#### 5.3.8 Backend

New tables and endpoints (all `X-Profile-Id` scoped, gate on serve): `GET /circle/members`, `GET /circle/feed?cursor`, `POST /circle/reactions {source_id, series_key, chapter_key, kind}` / `DELETE`, `GET /circle/reactions?source&series` (per-chapter counts and who), `POST /circle/letters {to_profile_ids, source_id, series_key, note}`, `GET /circle/letters`, `PATCH /circle/letters/{id}`, `PATCH /profiles/{id}/sharing {…switches, excluded_series}`, `POST /library/collections/{id}/share {profile_ids, mode}`, `DELETE /library/collections/{id}/share/{profile_id}`.

---

### 5.4 Ambient reader extras

#### 5.4.1 Auto-scroll ("projection speed")

- **Where**: manga strip mode and novel scroll mode.
- **Start**: the folio bar's auto-scroll button, `p`, the setup sheet's AMBIENT tab.
- **While running**: a floating square chip bottom-right (40 px tall, `paper.2` at 90 %, 1 px `rule.2`): `▸ 1.25×` with a 2 px `spot` rule along its bottom showing chapter progress; tap → pause / play; long-press → the speed ruler sheet.
- **Speed**: 0.50–3.00× in 0.05 steps; 1.00× = 60 px/s (manga) or the profile's measured reading pace in words per minute (novels, default 250 wpm); the speed ramps in over 400 ms and never lurches.
- **Interruption**: a touch pauses; release resumes after 800 ms when "Resume after I let go" is on; any manual scroll pauses; the chrome stays hidden.
- **Adjust on the fly**: right-edge vertical swipe with the HUD (phones); `<` / `>` (keyboard); the chip's long-press ruler.
- **Chapter boundaries**: in continuous mode auto-scroll rolls straight through seams and read-all dividers; at the series' end it stops with haptic `autoscroll.end` and the chrome returns.
- **Reduced motion**: never auto-starts; the user can start it manually.
- **Haptics**: `autoscroll.toggle` on play/pause, `autoscroll.step` per 0.25×.

#### 5.4.2 Soundscape ("house sound")

- **Loops** (8): Projector room (a soft hum with distant reel ticks), Rain on glass, Night city, Café, Night wind, Low drone, Afternoon park, Temple bells. Each a 90 s seamless loop, 48 kHz, OGG Vorbis 96 kbps (m4a/AAC on iOS), about 1 MB each, fetched on first use from the backend's static folder (`/app/media/soundscapes/{id}.{ogg|m4a}`) and cached (web Cache Storage; app file cache). Sources: CC0 field recordings (freesound.org CC0 only) or synthesis; every file's origin and licence is listed in the About → Licenses page.
- **Picker** (setup sheet AMBIENT tab and Settings → Ambient): a list of the eight as rows (name in `type.title`, a one-line description in `type.caption`, a `Hear` button playing 5 s), plus `MATCH THE MOOD` (chooses by the series' first genre, falling back to the profile mood's default in §2.1.6) and `OFF`. Volume slider 0–100 % (default 40 %).
- **Playback**: fades in over 2000 ms when a reader opens with a soundscape set, out over 600 ms on leaving the reader or pausing the app. Ducks to 30 % while Listen narration plays (or pauses if the user prefers: switch "Pause the soundscape during narration"). UI sounds are suppressed while it plays. Web: Web Audio `AudioBufferSourceNode` with `loop = true` through a `GainNode`; Flutter: a second `just_audio` player (`LoopMode.one`, already installed) under the same `audio_session` (ambient category on iOS so the silent switch mutes it; it never ducks the user's music, and it stops when other audio starts).
- **Indicator**: a 16 px `waveform` glyph in the reader's running head while a soundscape plays; tap → the AMBIENT tab.

#### 5.4.3 Panel-by-panel guided view

- **What**: the camera moves from panel to panel, like a guided comic view, for readers who want one beat at a time.
- **Data**: `GET /reader/panels?source&series&chapter` returns `pages: [{number, panels: [{x, y, w, h}]}]` in page fractions and reading order (computed server-side from the page proxy with a whitespace/blackspace gutter projection in Pillow; cached per page ETag). The manifest carries `panels_ready: bool`.
- **Entry**: setup sheet `LAYOUT → GUIDED`, the `u` key, a `panel-focus` button in the running head when `panels_ready`.
- **Presentation**: the viewport shows one panel scaled to fit within 24 px margins, the rest of the page dimmed to 15 % (a black matte at 85 %); the panel folio `PANEL 3 / 7 · PAGE 18` at the bottom-left in `type.folio`; the running head and folio bar behave as in paged mode.
- **Moving**: tap the right 30 % / swipe left / `→` / `j` → next panel; left side → previous; the camera **dollies** (translate + scale) between panels over 520 ms `turn`; at a page's last panel, next cuts to the next page's first panel (Cut, `page.turn` haptic); double tap shows the whole page for 1.5 s (a 320 ms zoom out) then returns; pinch overrides the camera until released.
- **Webtoon strips**: panels are detected along the strip's horizontal gutters; tall panels scroll inside the camera at the auto-scroll speed when auto-scroll is on.
- **States**: not ready ("Guided view isn't ready for this chapter yet." + `Read the strip`; the backend computes it in the background and the button appears when done); failed detection on a page (that page shows whole, with the folio `PAGE 18 · WHOLE PAGE`); reduced motion (cuts instead of dollies).
- Haptic `page.turn` per panel.

#### 5.4.4 Page-tinted chrome

- **Source**: `pages[].tint` from the manifest (§2.1.5).
- **Sampling**: the page occupying ≥ 50 % of the viewport, evaluated at most every 600 ms while scrolling.
- **Applied to**: the end colour of `scrim.head` and `scrim.sole` (mix 25 % tint into `#000`), the ruler's played part (the tint lifted to L 0.75, ≥ 4.5:1 on black), the micro progress rule, the desktop gutters around the strip (tint at L 0.06), and the setup sheet's top rule.
- **Motion**: every change dissolves over 800 ms `turn` via the registered CSS properties or `TweenAnimationBuilder`; reduced motion swaps at most once every 2 s without a fade.
- **Toggle**: setup sheet AMBIENT tab and Settings → Ambient (default on). Interactive marks elsewhere keep `spot`.

#### 5.4.5 Entry points and states summary

| Extra | Entry | Off / unavailable state |
|---|---|---|
| Auto-scroll | folio bar button, `p`, setup sheet | paged modes: the button is absent (tooltip in the sheet: "Auto-scroll needs the strip.") |
| Soundscape | setup sheet, Settings → Ambient, `waveform` indicator | not downloaded yet: `Hear` shows a leader while fetching; offline and not cached: "Available when you're online." |
| Guided view | setup sheet, `u`, running-head button | not ready / failed page as above |
| Page tint | setup sheet, Settings → Ambient | page has no tint yet (first view of a new page): the chrome stays neutral until the tint arrives with the next manifest fetch |

---

## 6. The two required signature animations

### 6.1 Heading reveal: per letter, fade + slide up + un-blur, staggered

#### 6.1.1 Spec

| Property | Value |
|---|---|
| Split | Graphemes (web `Intl.Segmenter(undefined, { granularity: "grapheme" })`; Flutter `String.characters`); words grouped `white-space: nowrap` so lines break only between words |
| From | opacity 0, translateY +0.42em, blur 8 px |
| To | opacity 1, translateY 0, blur 0 |
| Duration | 640 ms for opacity and y; **440 ms** for blur, so each letter is sharp before it settles (the Didone hairlines arrive last) |
| Easing | `ease.settle` `cubic-bezier(0.16, 1, 0.3, 1)` |
| Stagger | 24 ms per grapheme, total stagger capped at 560 ms: `step = min(24, 560 / (n − 1))`. "Library" (7) ends at 784 ms; a 40-grapheme title at 1200 ms. |
| Rule | The section rule above an H3 draws 120 ms before the first letter (Rule draw, 480 ms) |
| Trigger | H3 section heads: when 50 % in view, once per session per heading key (a module-level `Set` on web; a Riverpod `StateProvider<Set<String>>` in Flutter). Page mastheads: on first mount per session. Cover and feature titles: every mount, starting after the match cut lands (or 160 ms after first paint without one). |
| Responsive size | The heading roles' fluid sizes (§2.2.2: `clamp()` on web, the breakpoint table in Flutter) |
| Tracking | Tight: section −0.020em, masthead −0.035em, cover −0.040em, headline −0.030em |
| Kerning | Off on revealed text (`font-kerning: none`, `FontFeature.disable('kern')`), so split and unsplit text are identical and nothing shifts at the end |
| Accessibility | The container carries the full text (`aria-label`, `Semantics(label:)`); letter spans are `aria-hidden` / `excludeSemantics` |
| Reduced motion | The whole string fades in over 200 ms; no y, no blur, no stagger |

#### 6.1.2 Where it plays (exhaustive)

- **H3 section heads**: every rail and section header (Tonight 01–09, Library's Continue, Picks, The Numbers blocks, Circle tabs' section heads, feature page sections, Discover idle sections, Settings section headers on desktop).
- **Mastheads**: every page title (Library, Updates, Collections, History, Bookmarks, Discover's kicker line, Sources, source catalogue name, Downloads, Dialogue, Picks, The Numbers, Circle, Index, Settings, System status).
- **Hero and cover titles**: Tonight's cover series title in the credits kicker line, feature page and book page titles, Annual page titles, `PREVIOUSLY ON` and the recap's series title, `End of chapter 142` in the credits, the Listen full player's series title.
- **Brand**: the masthead in the logo reveal (§7.4) and in Stop the press (§4.30.3).

#### 6.1.3 Not used on

Body text, captions, buttons, list rows, toasts, anything inside the manga strip or the novel page body, anything repeated in a list.

#### 6.1.4 Smooth colour on hover and state

- **Hover** (linked headings: an H3 with `See all`, a series title that links to its feature page, sidebar-linked mastheads): letters wipe from `ink.100` to `spot` left → right: each letter's `color` transitions 200 ms `set` with `transition-delay: calc(var(--i) * 10ms)`. On leave, all letters return together in 160 ms (no delay). Flutter: an `AnimatedDefaultTextStyle` per letter with a delay derived from its index, driven by a `MouseRegion`.
- **State**: when keyboard focus is inside a rail, its H3 is `ink.100` and its folio turns `spot` (160 ms); when a section is empty, its H3 renders in `ink.45`.
- **Colour transitions never re-run the reveal.**

#### 6.1.5 Web implementation (Motion 13.4.4)

```tsx
"use client";
import { motion, stagger, useReducedMotion, type Variants } from "motion/react";

const seg = new Intl.Segmenter(undefined, { granularity: "grapheme" });
const graphemes = (s: string) => Array.from(seg.segment(s), (x) => x.segment);
const settle = [0.16, 1, 0.3, 1] as const;
const seen = new Set<string>();

const parent: Variants = {
  hidden: {},
  show: (n: number) => ({ transition: { delayChildren: stagger(Math.min(0.024, 0.56 / Math.max(1, n - 1)), { startDelay: 0.12 }) } }),
};
const letter: Variants = {
  hidden: { opacity: 0, y: "0.42em", filter: "blur(8px)" },
  show: { opacity: 1, y: 0, filter: "blur(0px)",
          transition: { duration: 0.64, ease: settle, filter: { duration: 0.44, ease: settle } } },
};

export function SetHeading({ text, id, as: Tag = "h3", className }:
  { text: string; id: string; as?: "h1" | "h2" | "h3"; className?: string }) {
  const reduce = useReducedMotion();
  const once = seen.has(id);
  const M = motion[Tag];
  if (reduce) return <M className={className} initial={{ opacity: 0 }} whileInView={{ opacity: 1 }} viewport={{ once: true }} transition={{ duration: 0.2 }}>{text}</M>;
  let i = 0;
  return (
    <M aria-label={text} className={className} style={{ fontKerning: "none" }}
       initial={once ? false : "hidden"} whileInView="show" viewport={{ once: true, amount: 0.5 }}
       onAnimationComplete={() => seen.add(id)} variants={parent} custom={graphemes(text).length}>
      {text.split(" ").map((w, wi, all) => (
        <span key={wi} aria-hidden className="inline-block whitespace-nowrap">
          {graphemes(w).map((c) => (
            <motion.span key={i} variants={letter} className="set-letter inline-block" style={{ ["--i" as string]: i++ }}>{c}</motion.span>
          ))}
          {wi < all.length - 1 && " "}
        </span>
      ))}
    </M>
  );
}
```

```css
/* frontend/src/skins/cinematic/motion.css */
a:hover .set-letter, .set-heading-link:hover .set-letter {
  color: var(--mm-color-spot);
  transition: color 200ms var(--mm-ease-set) calc(var(--i) * 10ms);
}
.set-letter { transition: color 160ms var(--mm-ease-set); }
```

#### 6.1.6 Flutter implementation (flutter_animate 4.5.2)

```dart
class SetHeading extends ConsumerWidget {
  const SetHeading(this.text, {super.key, required this.id, required this.style});
  final String text; final String id; final TextStyle style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = style.copyWith(fontFeatures: const [FontFeature.disable('kern')]);
    final seen = ref.watch(seenHeadingsProvider);
    if (MediaQuery.disableAnimationsOf(context)) {
      return Text(text, style: s).animate().fadeIn(duration: 200.ms);
    }
    if (seen.contains(id)) return Semantics(label: text, excludeSemantics: true, child: Text(text, style: s));
    final n = text.characters.length;
    final step = n < 2 ? 0 : math.min(24, 560 ~/ (n - 1));
    var i = 0;
    Future.microtask(() => ref.read(seenHeadingsProvider.notifier).update((set) => {...set, id}));
    return Semantics(label: text, excludeSemantics: true, child: Wrap(children: [
      for (final word in text.split(' '))
        Row(mainAxisSize: MainAxisSize.min, children: [
          for (final ch in '$word '.characters)
            Text(ch, style: s).animate(delay: (120 + step * i++).ms)
              .fadeIn(duration: 640.ms, curve: CineCurves.settle)
              .slideY(begin: .42, end: 0, duration: 640.ms, curve: CineCurves.settle)
              .blurXY(begin: 8, end: 0, duration: 440.ms, curve: CineCurves.settle),
        ]),
    ]));
  }
}
```

Each letter's blur is one `ImageFiltered` layer for at most 1.2 s; acceptable under the flagship-only rule. In slivers, building is the in-view trigger. `CineCurves.settle` is generated into `tokens.g.dart`.

### 6.2 Main headline typing reveal: one character every 50 ms

#### 6.2.1 Spec

| Property | Value |
|---|---|
| Rate | Exactly one grapheme per 50 ms, spaces included, no pauses at punctuation |
| Clock | Timestamp-based (`floor(elapsed / 50)`), so dropped frames never slow it |
| Layout | The full string is laid out from frame 0; unrevealed graphemes are `transparent`, so lines never reflow |
| Caret | A `spot` bar 0.12em wide × 0.86em tall (a text cursor, square ends), zero layout width, sitting after the last revealed grapheme; solid while typing; when done it blinks 530 ms on / 530 ms off three times (3180 ms) and fades out over 160 ms |
| Skip | Tap, click, `Enter` or `Space` on the headline completes it instantly |
| Length | Headlines only, ≤ 60 graphemes (≤ 3 s). Longer AI prose streams by word (§2.9.6) |
| Accessibility | The full text is in the accessibility tree from the start; the visual layer is hidden from it |
| Reduced motion | Full text at once, no caret |
| Sound | None per character (no typewriter clacks) |

#### 6.2.2 Where it plays (exhaustive)

- **The main headline**: Tonight's cover story headline (once per day per profile; later visits show it at rest).
- Profile picker question ("Who's reading tonight?").
- Login and Register headlines; Setup's "Where is your library?".
- Onboarding step headlines and "Printing issue No. 1…".
- Notice headlines (every empty, error, offline and caution state).
- The next-chapter caption in the manga reader after a pull commit, and the Listen post-play card's chapter title.
- `Previously on`'s loading line ("Writing the recap…") and the Picks thinking line ("Reading your shelf…").
- The Numbers' and The Annual's key numerals; the clock chart's summary line.
- Source catalogue loading tips.
- The index field placeholders (Discover, Dialogue, Picks examples) while empty and unfocused.
- New chapter folios on Updates after a check.
- The 404 headline; System status's summary headline.

#### 6.2.3 Web implementation

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
    <h1 aria-label={text} className={className} onClick={skip}
        onKeyDown={(e) => (e.key === "Enter" || e.key === " ") && skip()} tabIndex={-1}>
      <span aria-hidden>{shown}</span>
      <span aria-hidden className="relative inline-block w-0 align-baseline">
        <span className={`absolute bottom-[0.06em] left-[0.04em] h-[0.86em] w-[0.12em] bg-spot ${done ? "animate-caret-out" : ""}`} />
      </span>
      <span aria-hidden className="text-transparent">{rest}</span>
    </h1>
  );
}
```

`caret-out` is a 3340 ms `steps(1)` keyframe: six 530 ms halves (on, off, on, off, on, off) followed by a 160 ms opacity fade.

#### 6.2.4 Flutter implementation

A `StatefulWidget` with a `Ticker` computing `n = min(len, elapsed.inMilliseconds ~/ 50)`, rendering `Text.rich` of the revealed graphemes, a `WidgetSpan` caret (`SizedBox(width: 0)` + `OverflowBox` holding a `Container(width: .12 * size, height: .86 * size, color: CineColors.spot)`), and the rest in a transparent `TextSpan`; a `GestureDetector` completes on tap; `Semantics(label: text, excludeSemantics: true)`; `disableAnimations` → full text. The caret's blink is one `AnimationController(duration: 3340.ms)` driving `Opacity((v * 6).floor().isEven ? 1 : 0)` for the first 3180 ms and a linear fade for the last 160 ms.

---

## 7. Brand

### 7.1 Idea: the masthead

The app is a periodical you read every night, so the brand is a **masthead**: the name set as the title of a film magazine, with the second M turned to italic, the way a page turns. Its monogram is two M's, one upright and one leaning, overlapping; where they overlap, the light comes through in Subtitle Yellow. It reads as MM, as two panels with a gutter of light, and as a page caught mid-turn.

### 7.2 Wordmark and monogram

- **Wordmark (masthead lockup).** "ManhwaManiacs" on one line: `Manhwa` in Bodoni Moda Roman (opsz 96, wght 800) and `Maniacs` in Bodoni Moda Italic (opsz 96, wght 800); no space: the change of posture marks the word joint. Tracking −0.035em; the italic M's first stroke is kerned to touch the `a` of Manhwa at its terminal. Under it, the Oxford rule (3 px + 2 px gap + 1 px, scaled with the size) in bone, with its first 12 % in `spot` ("the spot"). Aspect ratio about 5.4:1 with the rule. The wordmark is redrawn as outlines (not live text) for the brand assets, from the font instance, with the joint touched up.
- **Stacked lockup** (square spaces, the splash end frame): `Manhwa` over `Maniacs`, flush left, leading 0.86, the Oxford rule under both.
- **Monogram (`mm-mark`)**: an upright Didone M and an italic Didone M, the italic one overlapping the upright one's right stem by 22 % of its width. Both glyphs in bone `#F3F0E8`; their **intersection** is knocked out and filled `spot` `#F4D03F`. Built on a 1024 canvas: bounding box x 232–792, y 272–752; stroke contrast from the font instance (thick stems ≈ 96 units, hairlines ≈ 14 units at this size, thickened to 24 for icon use below 64 px).
- **Single-colour versions**: bone on black (intersection as a hairline outline), black on bone, and the monochrome shape (both M's united) for Android themed icons and iOS tinted icons.
- **Minimum sizes**: wordmark 96 px wide; monogram 16 px (favicon uses a simplified pair with hairlines at 1.5 px).

### 7.3 App icon

- **Cinematic icon**: `#000` field; the monogram centred at 64 % of the icon width; the spot intersection with a faint 12 px bloom at 30 %; monochrome grain at 2 % over the field only; a 1 px bone Oxford rule 18 % below the monogram, 40 % wide, centred (small but it survives at 60 pt).
- **iOS**: 1024 master (opaque); iOS 18 dark (transparent background, same mark) and tinted (the monochrome shape) through `flutter_launcher_icons` 0.14.4 (`image_path_ios_dark_transparent`, `image_path_ios_tinted_grayscale`).
- **Android**: adaptive foreground (the mark inside the 66 dp safe circle: a 160 × 160 px box at xxxhdpi), background `#000000`, monochrome layer (Android 13 themed icons).
- **Per-skin icon**: both skins ship an icon; the skin restart calls `flutter_dynamic_icon_plus` 1.4.1 to switch (iOS shows its own one-line system alert, which lands inside the restart moment).
- **Web**: `favicon.svg` (simplified monogram), PWA `icon-192/512`, `maskable-512` (mark inside the 40 % radius circle), `apple-touch-icon` 180; the `<link rel="icon">` swaps to the active skin's SVG on load.
- **SideStore source** `tintColor`: `#F4D03F`; `iconURL` → the new icon.

### 7.4 Splash and logo reveal ("Press start")

Native layer: the neutral monogram (bone, no spot) on `#000`, shared with Glass (§4.2). The Flutter or web first frame redraws it identically, then:

| t (ms) | Element | Motion |
|---|---|---|
| 0–100 | Neutral monogram | Hold (matches the native frame) |
| 100–420 | The intersection | Lights up: fill `#000` → `spot` with a bloom 0 → 0.35 (`spot.glow`), `settle` |
| 300–620 | Monogram | Fades out and scales 1.00 → 0.96 (`lift`) while the wordmark takes its place |
| 380–1100 | Wordmark letters | Per-letter reveal (§6.1) with a 20 ms stagger (13 graphemes, 640 ms each): the upright "Manhwa", then the italic "Maniacs" |
| 820–1180 | Oxford rule | Draws left → right under the wordmark, 360 ms `settle`, its first 12 % in `spot` |
| 1180 | The impression | The whole lockup translates 1 px down and back (80 ms); haptic `impress`; sound `reel` lands its hit if on |
| 1180–1400 | Hand-off | Desktop: the lockup shrinks and flies to the sidebar head (shared element, 320 ms `turn`). Phone: the lockup dissolves (240 ms) as Tonight's headline starts typing |

Duration rule: `max(dataReady, 900 ms)`, capped at 1400 ms; beyond that, the lockup holds with a leader dial after 2400 ms (§4.2). Tap skips to the hand-off. Warm start: 200 ms fade in and out. Reduced motion: the lockup fades in 300 ms, holds, fades out 200 ms. The skin-switch restart plays the full reveal (it is the moment "everything changes"). Web: an inline SVG monogram in the server-rendered root, the wordmark as live text in Bodoni Moda (`display: block`, preloaded) animated by `SetHeading`; the Oxford rule is a `<div>` with `scaleX`.

### 7.5 Voice

Short, dry, confident; title-card and magazine phrasing; no exclamation marks. Kickers name the department (`TONIGHT`, `CORRECTION`, `OFFLINE EDITION`, `STOP PRESS`, `PREVIOUSLY ON`, `COMING UP`, `THE CIRCLE`). Headlines are full sentences with a full stop. Numbers under ten are spelled out in headlines, numerals everywhere else. Errors say what happened and what still works ("The server didn't answer. Your library is untouched.").

### 7.6 Screenshot set ("Front pages")

Five frames at 1320 × 2868 (a 440 × 956 CSS viewport at DPR 3 with Playwright, `research/brand.md` §11), a seeded demo profile, no 18+ content, placeholder covers in the hero frame. Each frame: a 640 px black top band with the caption set as a magazine cover line (Bodoni Moda Italic 120 px, bone, one keyword in `spot` via a highlighter band), a folio line above it (`No. 1 · TONIGHT`), and the UI capture below it, square-cornered, bleeding off the bottom edge, with a 1 px bone Oxford rule between band and capture. Captions: "Every source. One shelf." · "Built for the long scroll." · "Novels, read aloud." (sub "Thirty-one voices") · "Your year in chapters." · "Read together." Desktop set 2880 × 1800 and OG image 1200 × 630 use the spread layout.

### 7.7 Asset pipeline

Masters as SVG in `brand/cinematic/` (monogram, wordmark lockups, icon layers, favicon, custom glyphs); one export script (`resvg`) renders PNGs; `flutter_launcher_icons` 0.14.4 and `flutter_native_splash` 2.4.8 consume them; a check script asserts sizes, no alpha on the iOS master, and the safe-circle fit. Fonts' `OFL.txt` files ship with the app's licenses.

---

## 8. Signature moments

1. **Press start** (cold launch): the neutral monogram's intersection lights yellow, the masthead sets letter by letter, the Oxford rule draws, and the whole lockup makes one 1 px impression with a letterpress haptic.
2. **The front page** (Tonight): the cover racks into focus, the art bleeds off the spread under a duotone, and the headline types itself at 50 ms per character behind a yellow cursor: "Tonight: chapter 143 of Omniscient Reader."
3. **The Iris** (profile picker): the chosen avatar's ring draws in yellow, a black iris closes on it, and the profile's issue opens with an iris out from the same point; a Glass profile restarts inside the black.
4. **The Column wipe** (entering any reader): the page's own grid columns close as black blades, top-down in reading order, and open bottom-down onto page one, with the `wipe` haptic as the shutter lands.
5. **Section heads being set**: every rail header's rule draws and its Bodoni italic letters arrive out of a blur, hairlines last; hovering a linked head wipes it to yellow letter by letter.
6. **Folio flip**: changing section rolls the running head's section number like a page counter.
7. **The credits** (end of a chapter): "End of chapter 142" is set, the credits list the source and reading time, the circle's reaction stamps sit underneath, and the Coming up card waits with the next chapter's first page in duotone; a pull fills a yellow rule and cuts through black into chapter 143, whose title types itself.
8. **The highlighter** (Listen mode): as each sentence is spoken, a yellow highlighter stroke sweeps across it, the speaker's name sits above in their tint, and the page holds the line at the reading height.
9. **Previously on**: a title card, the kicker set, the recap arriving word by word under a Bodoni drop cap, and a cast list with dot leaders.
10. **The certificate** (18+): the square seal stamps: it fills red, the 18 knocks out, and it settles back to an outline under a stamp haptic.
11. **The genre paragraph** (onboarding): taste is set as a justified paragraph of italic genres that you underline, highlight or strike out like proof marks.
12. **Stop the press** (skin switch): the page racks out of focus, the columns close, the masthead is set once more on black, and the app restarts into the other edition.
13. **The Annual**: a special issue of ten spreads whose numbers type themselves, ending on a press run of share cards that print with a three-hit `pressrun` haptic.
14. **The flame catches**: the day's first finished chapter turns the outlined streak flame into a yellow fill with its bloom, while the streak numeral types its new value.
15. **A letter arrives** (Circle): a recommendation unfolds from its top edge, the sender's kicker types itself, and the yellow dot goes out when it is read.
16. **What they said** (dialogue search): results arrive with yellow highlighter strokes across the matched words; choosing one opens the chapter at the right page and pulses a yellow frame twice around the speech bubble.

---

## 9. Implementation notes (for `stack-decision.md`)

### 9.1 Token source (`design/tokens/cinematic.json`, excerpt)

```json
{
  "color": {
    "paper": { "0": "#000000", "1": "#0B0B0A", "2": "#121211", "3": "#1A1A18", "4": "#232220" },
    "rule": { "1": "#2B2A27", "2": "#3D3C38" },
    "ink": { "30": "#4D4B47", "45": "#7A7770", "60": "#9A978F", "80": "#C9C6BE", "100": "#F3F0E8" },
    "spot": "#F4D03F", "spotPress": "#D9B62C", "spotWash": "rgba(244,208,63,0.16)", "spotGlow": "rgba(244,208,63,0.35)",
    "proof": "#FF5B4A", "proofWash": "rgba(255,91,74,0.12)", "set": "#57D68D", "info": "#9CC8FF",
    "scrimModal": "rgba(0,0,0,0.78)"
  },
  "font": {
    "display": { "family": "Bodoni Moda", "axes": ["opsz", "wght"], "italic": true },
    "grotesk": { "family": "Archivo", "axes": ["wdth", "wght"] },
    "text": { "family": "Newsreader", "axes": ["opsz", "wght"], "italic": true },
    "folio": { "family": "IBM Plex Mono", "weights": [400, 500, 600] }
  },
  "type": {
    "section": { "font": "display", "italic": true, "opsz": 48, "wght": 600, "tracking": -0.02,
                 "size": { "phone": [24, 28], "tablet": [28, 32], "desktop": [32, 36], "wide": [36, 40] }, "scaleCap": 1.3 },
    "kicker": { "font": "grotesk", "wdth": 62, "wght": 700, "tracking": 0.16, "upper": true,
                "size": { "phone": [11, 16], "tablet": [12, 16], "desktop": [12, 16], "wide": [13, 16] }, "scaleCap": 1.5 }
  },
  "space": { "1": 4, "2": 8, "3": 12, "4": 16, "5": 20, "6": 24, "8": 32, "10": 40, "12": 48, "16": 64, "20": 80, "24": 96, "32": 128 },
  "grid": { "phone": [4, 16, 12], "tablet": [8, 32, 16], "desktop": [12, 48, 24], "wide": [12, 72, 24], "cinema": [12, 96, 32] },
  "radius": { "0": 0, "round": 9999 },
  "motion": {
    "settle": { "ms": 320, "bezier": [0.16, 1, 0.3, 1] },
    "lift": { "ms": 224, "bezier": [0.7, 0, 0.84, 0] },
    "turn": { "ms": 800, "bezier": [0.65, 0, 0.35, 1] },
    "set": { "ms": 240, "bezier": [0.2, 0, 0, 1] },
    "release": { "ms": 420, "bounce": 0 }, "sheet": { "ms": 480, "bounce": 0 }, "scrub": { "ms": 240, "bounce": 0 },
    "letter": { "ms": 640, "blurMs": 440, "stagger": 24, "staggerCap": 560 }, "type": { "msPerGrapheme": 50 }
  },
  "haptics": { "tap.primary": "ahap:impress", "follow.add": "ahap:stamp", "reader.enter": "ahap:wipe", "streak.extend": "ahap:ignite",
               "share.export": "ahap:pressrun", "recommend.send": "ahap:pass", "toggle.on": "medium", "toggle.off": "light",
               "nav.change": "rigid", "select": "selection", "error": "error", "success": "success" },
  "sounds": { "set": "press/set.wav", "impress": "press/impress.wav", "turn": "press/turn.wav", "reel": "press/reel.wav" }
}
```

`design/build.mjs` emits `frontend/src/skins/cinematic/tokens.generated.{css,ts}` and `mobile/lib/skins/cinematic/tokens.g.dart` from it (stack-decision §2.1). Letter spacing in em is multiplied by the size for Dart; springs map to Motion `{visualDuration, bounce}` and `SpringDescription.withDurationAndBounce`; curves to `cubic-bezier` and `Cubic`; the type roles become Tailwind `@theme` `--text-*` entries and a Dart `CineType` class that applies `FontVariation`s and `TextScaler.clamp` per role.

### 9.2 Web (`frontend/src/skins/cinematic/`)

| File | Content |
|---|---|
| `tokens.generated.css` / `.ts` | `[data-skin="cinematic"] { --mm-color-spot: #F4D03F; … }`, `@property` registrations for `--amb-duo`, `--amb-tint`, `--amb-ink`, `--page-tint` |
| `fonts.ts` | `next/font/google`: `Bodoni_Moda({ subsets: ["latin"], axes: ["opsz"], style: ["normal","italic"], display: "block", preload: true, variable: "--font-display" })`, `Archivo({ axes: ["wdth"], display: "swap", variable: "--font-grotesk" })`, `Newsreader({ axes: ["opsz"], style: ["normal","italic"], display: "swap", variable: "--font-text" })`, `IBM_Plex_Mono({ weight: ["400","500","600"], display: "swap", variable: "--font-folio" })`; Noto KR/JP/SC with `preload: false` in the fallback stacks |
| `Shell.tsx` | Contents sidebar, running head, thumb index (< 768), toast host, stop-press banner, first-run note, command palette mount |
| `Splash.tsx` | §7.4 |
| `motion.ts`, `motion.css` | `SetHeading`, `TypedHeadline`, `ColumnWipe` (fixed overlay of N blades from `Grid`, Motion `animate` with `stagger`), `Iris` (`clip-path: circle()`), `RackImage`, `Drift`, `Flicker`, `RuleDraw`, `caret-out` keyframes, reduced-motion overrides |
| `primitives/*` | §3 components; Base UI (`@base-ui/react` 1.8.0) supplies Dialog, Drawer (sheets and column panels), Menu, ContextMenu, Popover, Tabs, Switch, Slider, Checkbox, Radio, ToggleGroup, all unstyled and dressed with these tokens |
| `screens/*` | One file per ScreenId (`satisfies Record<ScreenId, Screen>`) |
| `haptics.ts` | The five `navigator.vibrate` events; everything else no-ops |
| `sounds.ts` | Web Audio loader and player for the Press Room set; suppressed while narration or a soundscape plays |
| `share-card.ts` | Canvas 2D renderer (§5.2.5) |
| `duotone.tsx` | One SVG `<filter>` per ambient duo, keyed by colour, mounted in the shell |

Packages (stack-decision §3): `motion` 13.4.4 (reveals, springs, `Reorder`, layout), `@base-ui/react` 1.8.0, `embla-carousel-react` 8.6.0 (the phone Also-in-this-issue pager and the Annual story pager only; rails use native scroll-snap), `sonner` 2.0.8 (toast queue, unstyled), `lenis` 1.3.26 (desktop Tonight and Annual only), `@use-gesture/react` 10.3.1 (reader pinch), `@phosphor-icons/react` 2.1.10 (add it to `optimizePackageImports`; use `@phosphor-icons/react/ssr` in server components). No chart library, no carousel for rails, no cmdk.

View transitions: `<ViewTransition>` with `transitionTypes` for Page and Dip, `view-transition-name` for match cuts; the Column wipe and Iris are overlays that `await` their close before `router.push`, because they are not state-to-state morphs.

Service worker: the `skin-changed` message (stack-decision §2.5) plus the Cinematic `offline-fallback.html` variant chosen by the `mm-skin` cookie.

### 9.3 Flutter (`mobile/lib/skins/cinematic/`)

| Path | Content |
|---|---|
| `tokens.g.dart` | Generated `cinematicTokens` (colours, `CineType` roles, curves such as `CineCurves.settle`, springs, grid) |
| `cinematic_skin.dart` | The `Skin` implementation: `ThemeData` built from the tokens (only for Material widgets the skin still uses), `buildRouter`, `splash`, `haptics`, `sounds` |
| `router.dart` | go_router routes for every ScreenId (and the mobile aliases), page builders: `SwipeablePage` (iOS, edge-only 20 pt) or `MaterialPage` with `PredictiveBackFullscreenPageTransitionsBuilder` (Android); custom routes for the Column wipe (reader, novel) and the Iris (picker → shell) |
| `shell.dart` | Thumb index, running head, toast overlay host, stop-press banner |
| `primitives/` | §3 components (`CineButton`, `SetHeading`, `TypedHeadline`, `CinePoster`, `CineRail`, `CineSheet` over `showModalBottomSheet` + `DraggableScrollableSheet(snap: true, snapSizes: [0.5, 0.92])`, `CineDialog` over a custom `RawDialogRoute` with the Insert clip, …) |
| `screens/<cluster>/` | Screens by cluster: auth, profiles, tonight, library, feature, reader, novel, listen, discover, downloads, numbers, circle, settings, admin |
| `shaders/grain.frag` | The grain shader (`research/cinematic-language.md` §7.1), declared under `flutter: shaders:`; overlay blend on art only |
| `duotone.dart` | `ColorFilter.matrix` builder from `ambient.duo` |

Packages: `flutter_animate` 4.5.2 (reveals, rack focus, flicker, flame), `swipeable_page_route` 0.4.8, `custom_refresh_indicator` 4.0.2 (reprint), `flutter_reorderable_grid_view` 5.7.0 (manual order walls), `flutter_slidable` 4.0.3 (two-action rows in Downloads), `haptic_feedback` 0.6.5 + `gaimon` 1.5.0 (§2.10), `phosphor_flutter` 2.1.0, `flutter_soloud` 5.1.4 (UI sounds), `share_plus` 13.3.0 (share cards), `audio_service` 0.18.19 (Listen lock screen), `flutter_dynamic_icon_plus` 1.4.1, `flutter_launcher_icons` 0.14.4 and `flutter_native_splash` 2.4.8 (dev). Cinematic uses the built-in `Hero`, `SpringSimulation` and sheets; it does not use `heroine`, `motor`, `smooth_sheets`, `stupid_simple_sheet` or `liquid_glass_widgets` (those are Glass's). Native plugins (`gaimon`, `haptic_feedback`, `flutter_soloud`, `share_plus`, `audio_service`, `flutter_dynamic_icon_plus`) land in one isolated commit with a CI iOS dry run (stack-decision risk 9).

Scroll physics: `ClampingScrollPhysics` with `StretchingOverscrollIndicator` on both OSes, set once in the skin's `ScrollBehavior`.

### 9.4 Reader engine seam

The Cinematic reader chrome is a `chromeBuilder(context, ReaderEngineState)` returning the running head, folio bar, ruler, micro progress, auto-scroll chip, HUDs, credits and side panels. The engine exposes what the chrome needs: current page and chapter, page count, progress fraction, loaded neighbours, `nextState` (loading / ready / failed / none), bookmarks for the ruler, zoom, auto-scroll state and speed, `pageTint`, `panels` (guided view), and commands (seek, next, previous, toggle auto-scroll, set speed, zoom, bookmark). Web mirrors it with a `useReaderEngine()` hook in `features/reader/`. The engine already enforces the shared thresholds (hide 24 / show 56, 800 ms orientation, 3000 ms idle, preload at 70 %).

### 9.5 Backend additions this concept depends on

| Addition | For |
|---|---|
| `ambient {duo, tint, ink}` on series payloads (Pillow + colorsys next to cover resizing) | Spreads, duotones, issue colours |
| `pages[].tint` in manifests (image proxy, 16 × 16) | Page-tinted chrome |
| `GET /reader/panels` + `panels_ready` in manifests | Guided view |
| `GET /home`, `GET /ai/similar`, `GET /ai/recap` (SSE), `POST /ai/feedback`, `PUT /profiles/{id}/taste` | §5.1 |
| `GET /library/annual?year=` | §5.2 |
| Circle tables and endpoints (§5.3.8) | §5.3 |
| `reading_profiles.skin` (stack-decision §2.4) | Edition per profile |
| First four member covers on `GET /library/collections` | Collection plates without N detail calls |
| `tags` on `FollowedSeries` list rows | Tag filter on the shelf |
| Soundscape files under `/app/media/soundscapes/` | §5.4.2 |

All gate 18+ on serve and scope by profile; none touches `backend/connectors/`.

### 9.6 Performance guards (flagship-only, still bounded)

- Grain and Drift run only on the one visible hero or spread art; both pause off screen (IntersectionObserver; `TickerMode`).
- At most one animated blur layer per screen outside letter reveals; letter reveals cap at 60 graphemes per heading (longer titles fall back to a word-level reveal with the same timings).
- Duotone filters are cached per colour; spreads request covers at 720 px and never upscale sharp art (`blur.bleed` covers the rest).
- The reader never runs grain, blur, drift or backdrop effects over pages; its chrome is gradients and text only.
- Page-tint sampling at most every 600 ms; ambient colour transitions are CSS registered properties (compositor-friendly) or single `TweenAnimationBuilder`s.
- Rails virtualise beyond 30 items; walls use `@tanstack/react-virtual` (installed) / `SliverGrid`.

### 9.7 Accessibility checks per cluster

- Contrast: text roles use only `ink.45` and above on `#000`/`paper.1–2` (≥ 4.5:1); `ink.30` never carries information.
- Focus order follows the grid's reading order; every screen reachable by keyboard on web and with a hardware keyboard on iPad.
- Every icon-only control has a label and a tooltip; every gesture has a visible alternative (§4.14.10, §3.16).
- Screen readers: letter and typing reveals expose the full text; the reader announces chapter changes but not page changes; auto-hide timers and toast timeouts stop while a screen reader is active.
- Reduced motion: every item in §2.9.8 verified by toggling the OS setting.
- Text scale: every screen checked at 1.0, 1.3 and 2.0 (§2.2.3) on both phones.

### 9.8 Verification

Per cluster, on both clients: the completeness test (`ScreenId` coverage), the import-boundary test and lint rule, one smoke test per screen, Playwright screenshots of the web phone and desktop layouts with the grid overlay on and off, the Flutter screenshot harness at phone and tablet sizes, and a device pass on the owner's iPhone (SideStore) and the Android flagship for the Column wipe, the Iris, the reader at 120 Hz and the Listen highlighter. `next build` before any push, one heavy command at a time on the dev box.
