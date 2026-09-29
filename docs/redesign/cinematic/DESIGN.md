# ManhwaManiacs Cinematic skin: "Programme" — design contract

**Status: final** (revised 2026-09-28 to close every high and medium gap, and the low ones, in `cinematic/critic.md`; amendments to the stack decision are collected in §15.10). This file is the single source of truth for every implementation session that builds the Cinematic skin on the web client (`frontend/`, Next.js 16 + React 19 + Tailwind 4 + Motion 13) and the mobile client (`mobile/`, Flutter 3.44.6). Where it disagrees with a concept file, this file wins. It is built on the judged winner, `concepts/cinematic-3.md` ("Programme"), with selected ideas grafted in from `concepts/cinematic-1.md` and `concepts/cinematic-2.md`; Appendix A lists every graft and the one place a graft was adapted rather than copied.

The angle: **typography, rhythm and the grid drive every layout, the way a film magazine or a festival programme is set.** The art is placed like stills in a spread; the words are set like a feature; the grid is visible, and at the one big moment (entering the reader from the front page or a series page) the grid itself becomes the shutter.

Binding inputs: `inventory/00-decisions.md` (owner decisions), `inventory/web.md`, `inventory/mobile.md`, `inventory/capabilities.md`, `research/*.md`, `stack-decision.md`, `00-baseline.md`. Dark only on AMOLED `#000000`, restart on skin switch, flagship-only effects, OS reduced motion honoured, UI sounds off by default, haptics rich and on by default.

Conventions used throughout:

- **px** are logical pixels (1 CSS px = 1 Flutter logical pixel, `stack-decision.md` §2.1). Letter spacing is in em; the generator converts it for Dart.
- **Breakpoints.** `phone` < 600, `tablet` 600–1023, `desktop` 1024–1439, `wide` 1440–1919, `cinema` ≥ 1920. The web uses the phone frame below 768 px and the desktop frame from 768 px (768–1279 uses the collapsed sidebar, the *spine*; 768–1023 also lays out on the 8-column grid). The Flutter app uses the phone frame at every width; on tablets it lays out on the tablet grid.
- **Platforms.** "Phone" means iOS app, Android app and mobile web together; a *Platform deltas* line in each screen lists where they differ. "Desktop" means desktop web. Every screen in §8 and §9 is specified for all four platforms: desktop web, mobile web, iOS and Android.
- **Token names** are written `color.spot`, `type.section`, `space.4`, `ease.settle`, `dur.line`, `spring.sheet`. They are the keys of `design/tokens/cinematic.json` (`stack-decision.md` §2.1). §2.8 and §3.5 map every key to its web CSS custom property, its Tailwind 4 `@theme` name and its Flutter `CineTokens` (ThemeExtension) field, with identical values. Haptic and sound event names such as `follow.add` live in `design/contract.json`.
- Inventory IDs (web `LB14`, mobile `S21 #19`, keys `web K40`, `mobile K40`) are cited so the contract can be ticked off against both inventories. Keys are always cited as `web K40` or `mobile K40`: the two inventories number their keys separately, so a bare `K30` would be ambiguous (web K30 is cinema, mobile K30 is the mature switch).
- "Section" numbers (`§4.5`) refer to this file unless a file name precedes them.
- "H3" in this contract is the design name of the `type.section` head (from `inventory/00-decisions.md`); its semantic level is 2 (web `h2`, Flutter `level: 2`).

Contents

1. Manifesto
2. Tokens (colour, spacing and grid, radius, elevation, blur, rules, iconography, the token name map)
3. Type scale
4. Motion (durations, curves, springs, the motion table, stagger, interruptibility, reduced motion)
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
- Appendix B. Coverage (every inventory screen and new-feature screen → the section that specifies it)

---

## 1. Manifesto

Programme treats ManhwaManiacs as the magazine you pick up in a cinema foyer on the way to your seat: black stock, bone-white ink, one spot colour, and pages set by an art director who trusts type. Every screen stands on a visible grid (4 columns on a phone, 8 on a tablet, 12 on a desktop) and a 4 px baseline, so headings, captions and covers all land on the same lines and the eye reads each screen like a spread. Hierarchy comes from contrast in the type rather than from boxes: a razor-sharp Didone (Bodoni Moda) for titles and numbers, a condensed grotesk (Archivo) for credits, kickers and controls, a reading serif (Newsreader) for everything longer than a line, and a mono (IBM Plex Mono) for folios, chapters and timecodes. Rules replace cards. Covers sit square-cornered on the grid or bleed off the page like film stills, never floating in rounded tiles. The only accent is Subtitle Yellow `#F4D03F`, the colour of cinema subtitles and of a magazine's second ink, used a few pixels at a time: a rule under the active tab, a folio, a highlighter stroke through the sentence being read aloud. Motion is typesetting and editing: section heads are set letter by letter out of a blur, the front-page headline is typed at 50 ms a character, screens cut and dissolve, covers match-cut into their feature, and when you sit down to read from the front page or a series page, the page's own columns close like a shutter and open on page one. Nothing springs, bounces, frosts or floats; that is the other skin. This one reads.

---

## 2. Tokens

All values below are the source for `design/tokens/cinematic.json`. §15.1 shows the file shape.

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
| `color.rule.1` | `#2B2A27` | 1.46:1 | Hairlines: row dividers, column rules, section rules |
| `color.rule.2` | `#3D3C38` | 1.9:1 | Strong rules: sheet top edge, slider tracks, unfocused input underline |
| `color.ink.30` | `#4D4B47` | 2.4:1 | Disabled text and glyphs only, never information |
| `color.ink.45` | `#7A7770` | 4.7:1 | Captions, metadata, inactive tabs and nav, placeholders in large type |
| `color.ink.60` | `#9A978F` | 7.2:1 | Secondary text, decks, synopsis on dense screens |
| `color.ink.80` | `#C9C6BE` | 12.3:1 | Long body passages on desktop (synopsis, recaps), pressed primary button fill |
| `color.ink.100` | `#F3F0E8` | 18.4:1 | Primary text, headlines, primary button fill, focus rings. "Bone": a warm projector white, never `#FFFFFF` |

**`ink.45` lives on black only.** Measured with the WCAG 2.x formula, `ink.45` is 4.70:1 on `paper.0` but 4.41 on `paper.1`, 4.20 on `paper.2`, 3.90 on `paper.3`, 3.56 on `paper.4` and 4.14–4.39 on the mood grades and `ambient.tint` fields. So every role this contract gives `ink.45` (kickers, captions, labels, placeholders, inactive tabs, menu shortcuts, title cards) renders in `ink.60` whenever its ground is anything other than `paper.0`: `paper.1`–`paper.4`, the top 30 vh mood grade, `ambient.tint` spills and spreads, and page-tint washes. Over art the §2.1.4 over-art rule applies instead, and `ink.45` is used there only on a solid ground (a badge's `#000000` fill, the rating card's `paper.0` box). `ink.60` measures 7.20 / 6.75 / 6.42 / 5.97 / 5.45:1 on `paper.0`–`paper.4` and ≥ 6.35:1 on every mood grade. Implementation, one structural rule per client: **every primitive that paints a ground other than `paper.0` applies the raised scope**. The web sets `[data-stock="raised"] { --mm-color-ink-45: var(--mm-color-ink-60); }` on its root; Flutter wraps it in `CineStock.raised(child)`, which re-provides `CineTokens` with `colorInk45: colorInk60` through `Theme(data: theme.copyWith(extensions: [cine.copyWith(colorInk45: cine.colorInk60)]))`, so `context.cine.colorInk45` resolves correctly inside. That covers every sheet, menu, popover, command palette, dialog, toast, plate, selected, pressed, own or tinted row, masthead grade band and spread, and explicitly also the manga reader canvas when its ground is Ink or Slate (chapter seam, read-all divider, top band), the select-mode bar, and `proof.wash` areas and error rows. **Inside any `spot.wash` band** the `ink.45` and `ink.60` roles render `ink.80` (9.41:1 on the wash over `#000`, 6.98:1 over `paper.3`): web `[data-stock="wash"]` sets both variables to `var(--mm-color-ink-80)`, Flutter `CineStock.wash(child)`. **Stock-painted panels** (the novel margins panel, the contents sheet, the mini player, the next card and a rating card drawn in stock colours) render `ink.45` roles in the stock's `muted` colour (≥ 5.84:1 on the six fixed stocks, ≥ 5.5:1 on the Issue stock, §2.1.6), which keeps spoiler-guard lines such as "reacted to Ch. 212" legible. The `tint` tests (§2.1.5) add a surface × ink loop: every text ink in §2.1.1–§2.1.3, after the scope remaps above, against `paper.0`–`paper.4`, the six mood grades, the ambient fallback tint, `ground.ink`, `ground.slate`, `spot.wash` over `paper.0`–`paper.3`, `proof.wash` over `paper.0`–`paper.3` and the six stock pages must be ≥ 4.5:1, with `ink.45` checked on `paper.0` only. The same loop checks `ink.100` on the twelve avatar fields (≥ 4.5:1, §7.25) and on the voice-monogram field endpoints (≥ 4.5:1, §8.16.5).

#### 2.1.2 Accent: the spot ink

| Token | Value | On #000 | Text on it | Role |
|---|---|---|---|---|
| `color.spot` | `#F4D03F` "Subtitle Yellow" | 13.9:1 | `#000000` 13.9:1 | The only brand hue. Active tab and nav rule, progress fills, NEW badge, typing caret, input focus underline, selected-chip underline, streak flame, the lit intersection of the monogram, count badges. A mark, never a surface larger than a badge. |
| `color.spot.press` | `#D9B62C` | 10.7:1 | `#000000` | Pressed state of any spot-filled mark |
| `color.spot.wash` | `rgba(244,208,63,0.16)` | n/a | ink on top | Highlighter band: spoken sentence in Listen mode, matched words in dialogue search, the go-to target row in contents |
| `color.spot.glow` | `rgba(244,208,63,0.35)` | n/a | n/a | Bloom behind the masthead in the splash and the streak flame. Never behind UI chrome. |

Why yellow: subtitles are the most cinematic typography there is, and the colour has the highest luminance contrast of any hue on black (13.9:1), so it can work at 2 px. It is the classic second ink of film-magazine covers. Nothing in the reference apps owns it (Netflix red, Crunchyroll orange, Prime blue, HBO purple, PlayStation blue), and it stays clear of the error red below.

#### 2.1.3 Semantic roles

| Token | Value | On #000 | Use |
|---|---|---|---|
| `color.proof` | `#FF5B4A` "Proof red" | 6.9:1 | Errors, destructive actions, the 18+ certificate, failed downloads, dead sources. Named after the proofreader's pen: errors are shown as corrections, with a margin mark. |
| `color.proof.wash` | `rgba(255,91,74,0.12)` | n/a | Background of a destructive confirm area and of error rows |
| `color.set` | `#57D68D` | 11.4:1 | Success: downloaded, synced, saved, healthy source ("set" as in type that is set and approved) |
| `color.note` | `color.spot` + the kicker `NOTE` | 13.9:1 | Cautions (paused downloads, overdue checker, stale catalogue). Always carries a text kicker, so it never relies on hue alone. |
| `color.info` | `#9CC8FF` | 12.1:1 | Rare informational marks: "position approximate", demoted source |
| Health: ok / failing / dead / unknown / demoted | `set` / `spot` / `proof` / `ink.45` / `ink.60` + strike-through label | as above | 6 × 6 px square marks plus a label everywhere a health state appears |

Rule: text on a `spot` or `proof` fill is always `#000000`. Bone on spot is 1.3:1 and fails.

#### 2.1.4 Scrims (exact stops)

Long fades use the eased scrim curve (Andreas Larsen), 13 stops, running from transparent to the end colour:

| Stop | 0% | 1.8% | 4.8% | 9% | 13.9% | 19.8% | 27% | 35% | 43.5% | 53% | 66% | 81% | 100% |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Alpha | 0 | .002 | .008 | .021 | .042 | .075 | .126 | .194 | .278 | .382 | .541 | .738 | 1 |

| Token | Geometry | Stops | Where |
|---|---|---|---|
| `scrim.gutter` | Horizontal, across the 2 grid columns where art meets type in a spread | Eased stops, end `#000` at the text side | Tonight cover spread, series feature spread, Annual spreads (desktop) |
| `scrim.foot` | Bottom of a full-bleed hero or tile, top → bottom; the ramp is placed per component so it reaches alpha 1 of its end colour 24 px above the top of the text block's first line box (each component measures its text block), and the whole text block sits on the solid end colour (`ink.60` ≥ 6.35:1) | Eased stops, end colour `ambient.tint` | Tonight phone cover, series phone hero, genre tiles, collection plates and the collection header, Sources tiles, Annual pages, the preview slate's backdrop (§7.8), onboarding format tiles (§8.7) |
| `scrim.foot.black` | The bottom 60 % of its band, top → bottom, reaching `#000000` at the band's bottom edge (no text sits on the band's bare art; the one control on the band, the recap's `Skip recap →`, is an `on-art` button that brings its own ground) | The same eased stops, end colour `#000000` | Art bands that end on a `#000` page: the "Previously on" cover band (§9.1.5) |
| `scrim.head` | Flat from the top edge to the running head's laid-out bottom edge (phone: min safe area + 44 px, 48 on Android, growing with the bar to the title line + 2 × 12 px at large text scales, §7.13; desktop: 56 px), then a fade over the next 44 px (phone) / 64 px (desktop): top 120 px desktop / bar + 44 px phone in all (min safe area + 88 px, 92 on Android). The flat part always follows the bar, so a grown title or an Android 48 px button never sits on the fade | `#000000` at .88 flat over the bar, then the 13 eased stops reversed from .88 to 0 over the fade. At .88 over `#FFFFFF`: `ink.60` 5.65:1, `spot` 10.94:1, `ink.100` 14.47:1 | Running head over art, reader top chrome |
| `scrim.sole` | Flat from the bottom edge through the bar's laid-out top edge (folio bar: min 64 px + bottom inset, growing by its second caption line at large text scales, §8.14.3), then a fade over the next 64 px: bar + 64 px in all (min 128 px + bottom inset), bottom → top. The flat part always follows the bar, so a grown second line never sits on the fade | `#000000` at .90 flat over the bar, then the 13 eased stops reversed from .90 to 0 over the fade | Reader folio bar, Listen full player transport |
| `scrim.modal` | Full screen | `rgba(0,0,0,0.78)` flat | Barrier behind sheets and dialogs. No blur, ever. |
| `scrim.rail-end` | 48 px at each rail end (desktop) | `#000` 1 → 0 linear (short enough not to band) | Under rail paddles |
| `scrim.vignette` | Full frame, radial | `radial-gradient(120% 90% at 50% 40%, rgb(0 0 0/0) 60%, rgb(0 0 0/.45) 100%)` | Hero art, Annual pages, recap title card |

Flutter uses `LinearGradient(stops: _scrimStops, colors: [for (a in _scrimAlpha) end.withValues(alpha: a)])`; a 77° angle is never used in this skin (spreads are strictly horizontal, on the grid).

**Text and icons over art (the over-art rule).** Every text run and icon drawn over art (covers, manga pages, duotone fields, blurred copies) sits on black whose alpha across its line box ± 8 px is at least the value below. Each value gives ≥ 4.5:1 composited over `#FFFFFF`. `ink.30` is never used over art, and `ink.45` only on a solid ground (below). The §9.4.4 page-tint mix (25 % of `page.tint`) still applies to the end colours of `scrim.head` and `scrim.sole` on the reader chrome, through `--scrim-base` (web) and the `tint` argument (Flutter) of §2.8.3.

| Ink | Minimum black alpha at the text line |
|---|---|
| `ink.100` | 0.60 |
| `ink.80` | 0.68 |
| `spot` | 0.66 |
| `set` | 0.70 |
| `ink.60` | 0.82 |
| `proof` | 0.84 |

Components that cannot meet it with a scrim get a solid ground: the rating card's text sits in a `paper.0` box with 8 × 12 px padding, and the Coming up card's text block sits on a `#000000` band at 0.84. Badges that can sit on art get a `#000000` fill inside their outline (§7.19), and that fill is a solid ground too. On a solid ground (alpha 1: a badge's fill, the rating card's `paper.0` box) the ± 8 px margin is the box's own padding, and `ink.45` is allowed there (4.70:1 on `#000000`, as on the `TEXT` poster badge). Controls where no scrim reaches use the `on-art` variants (§7.1, §7.2). Floating chips, HUD readouts, flags and captions that sit over art with no scrim (zoom chips, the brightness and auto-scroll HUD values, the new-chapter caption, the guided-view folio in its whole-page states, Lightbox captions and folios) sit on the folio-flag ground (§7.20: a `#000000` box, 1 px `ink.100` border, 4 × 8 px padding), and icon buttons over art are always `on-art`, never `bare`: their `color.onart` fill (black at 0.64) is the ground, above the 0.60 that `ink.100` needs (5.89:1 over `#FFFFFF`, 6.51:1 over `#F5F547`). That covers the "Previously on" `Skip recap →` at the top of the cover band (§9.1.5), where `scrim.foot.black` has not started, and The Annual's phone close `x` and focus-revealed page buttons on art that bleeds to every edge (§9.2.4). The `tint` tests (`tint.test.ts`, `tint_test.dart`, §2.1.5) carry an over-art table of (component, ink, ground alpha at the text line); each row is composited over `#FFFFFF` and over the worst-case duo `#F5F547` and must reach ≥ 4.5:1, or ≥ 3:1 for text ≥ 24 px regular, text ≥ 18.66 px at wght ≥ 700, and icons.

#### 2.1.5 Ambient colour: the "issue colour" of each series

Each series gets three colours computed once from its cover on the backend, next to cover resizing in `backend/services/image_resize.py`, cached with the cover and served as `ambient: {duo, tint, ink}` on every series payload, or null until the cover has been served once (library rows, source series, world items when available, continue-reading rows). Cover colours are never computed on a device; page colours are (below).

**When `ambient` exists.** It is computed in one place only: the cover proxy's resize path (`image_resize.py`), the first time a cover URL is served at any width, and cached with it. List, search and browse endpoints never fetch or decode a cover to fill it. Payloads carry `ambient: {duo, tint, ink} | null`, where null means "not computed yet"; clients paint `color.ambient.fallback.*` (the fallbacks below) for null, and when a later payload carries the value they dissolve to it over 800 ms `ease.turn` (the normal ambient transition, below). WorldItem `ambient` comes from a background fetch of the AniList cover through the same extractor, limited to 20 per minute, so the first recommendation payload may carry null.

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

Duotone implementation (one matrix, both clients): luminance `Y = 0.2126R + 0.7152G + 0.0722B`, output = `shadow + Y × (duo − shadow)` with shadow `#000000`. Web: an SVG `<filter>` with `feColorMatrix type="matrix"` whose R, G, B rows are `[dr·0.2126, dr·0.7152, dr·0.0722, 0, 0]` (dr = duo red / 255, likewise for green and blue), declared as `<filter id="duo-<id>" color-interpolation-filters="sRGB">` (SVG filters default to `linearRGB`, which would run the matrix on linearised values) and referenced as `filter: url(#duo-<id>)`, one filter per visible duo. The web, Flutter `ColorFilter.matrix` and the Canvas 2D share-card renderer then apply the one matrix to the same sRGB-encoded values. Flutter: `ColorFiltered(colorFilter: ColorFilter.matrix([...same 20 numbers...]))`.

**Where each colour is computed**

| Art | Computed by | When | Delivered as |
|---|---|---|---|
| Series cover | Backend, next to cover resizing in `backend/services/image_resize.py` (Pillow + `colorsys`), cached with the cover | Once per cover URL, the first time the proxy serves it at any width (null in payloads until then) | `ambient: {duo, tint, ink}` on every series, follow, continue-reading, history, bookmark, notification, recommendation, Circle activity and Circle member payload |
| AniList cover (world recommendations) | Backend, same extractor, on a background fetch of the AniList cover limited to 20 per minute | Once per `anilist_id` (null in payloads until then) | `ambient` on `WorldItem` |
| **Reader page (primary path: the client)** | Web: a Web Worker (`frontend/src/features/reader/page-tint.worker.ts`) receives the decoded page as an `ImageBitmap` (transferred, zero copy), draws it into a 16 × 16 `OffscreenCanvas` (`ctx.imageSmoothingQuality = "medium"`, then `drawImage(bitmap, 0, 0, 16, 16)`; the engine makes the bitmap once the page's `<img>` has decoded with `createImageBitmap(img, { resizeWidth: 16, resizeHeight: 16, resizeQuality: "medium" })`, so a 720 × 14,668 strip page is never copied as about 42 MB of bitmap; if the returned bitmap is not 16 × 16 (the options are unsupported), the worker downsamples it as above; either way the worker calls `bitmap.close()` after reading), reads the 256 pixels and picks the seed (rule below). Flutter: the reader engine (`mobile/lib/features/reader/engine/page_tint.dart`) resolves the page through `ResizeImage(provider, width: 16, height: 16, policy: ResizeImagePolicy.exact)`, reads `toByteData(format: ui.ImageByteFormat.rawRgba)` (256 pixels) and runs the same picker in a `compute()` isolate | When the page under the reading line changes, at most one sample every 600 ms | `pageTint` (a seed hex, or `null` for a greyscale page) in the reader engine state |
| Reader page (cache) | Backend stores what clients report; it never analyses page images | On chapter exit the client posts the tints it sampled: `POST /reader/page-tints {source_id, series_key, chapter_key, tints: [{page, hex}]}` → 204, unknown pages ignored (one request per chapter, fire and forget, skipped offline) | `pages[].tint` (optional) in the next manifest for any profile; downloaded chapters store the client's own samples in their local manifest copy |
| Profile avatar | Static table (§7.25) | At profile load | Constant |

**Why page tint is client-side** (an amendment to `stack-decision.md` §2.6 item 2, listed in §15.10): cover `ambient` stays server-side exactly as the stack says, but per-page tint is computed on the client, because the shared VPS image proxy must not decode and analyse every page, and the client already holds the decoded page (so even the first read of a chapter is tinted). The "logic that must agree" is kept single-sourced by data instead of by placement: `design/tint-vectors.json` holds 48 fixed 16 × 16 RGBA samples (colour pages, screentone greys, near-black splash pages, sepia scans) with their expected seed hex or `null`, and both `tint.test.ts` and `tint_test.dart` run the picker over them and must return identical results. A picker change that does not update the vectors fails both suites.

**The page seed picker** (one function per client, identical rules): convert each of the 256 pixels of the 16 × 16 sample (the same input on both clients) to HLS; keep pixels with 0.10 < L < 0.90; the seed is the pixel with the highest S. A page is **greyscale** when no kept pixel has S ≥ 0.08 (or no pixel was kept). The engine reads `pages[].tint` from the manifest first when present, so the chrome is tinted from frame 0 on a cached page; otherwise it samples the moment the page decodes, so the **first read of a new chapter is tinted too**. `ColorScheme.fromImageProvider` is deliberately not used for this: its scorer (`Score.score`) returns Google blue `#4285F4` when an image has no chromatic colour, which would paint black-and-white manga blue. Because both clients feed the picker the same 16 × 16 input, the vectors in `design/tint-vectors.json` match their real input; small differences between the browser's and Skia's downscale filters are accepted.

**Greyscale rules.** A greyscale page keeps the previous page's tint (black-and-white manga never flickers to grey). After **6 consecutive greyscale pages** the chrome dissolves to the series cover's `ambient` roles and stays there until a chromatic page arrives.

**Page-tint roles** (derived from the seed's hue `h` and saturation `s` by the Cinematic skin, `frontend/src/skins/cinematic/tint.ts` and `mobile/lib/skins/cinematic/tint.dart`):

| Role | Rule | Where |
|---|---|---|
| `page.tint` | `h`, L 0.06, S ≤ 0.35 | Scrim end colour mix (25 %), desktop gutters around the strip |
| `page.light` | `h`, L 0.75, S = clamp(s, 0.35, 0.70); raise L by 0.02 until contrast on `#000000` ≥ 4.5:1 | The ruler's played part, the micro progress rule, the setup sheet's top rule |

**The contrast check (one runnable test per implementation).** `frontend/src/skins/cinematic/tint.test.ts` (Vitest), `mobile/test/skins/cinematic/tint_test.dart` and `backend/tests/test_ambient.py` each loop hue 0–359 in 1° steps × saturation {0.08, 0.35, 0.60, 0.90} and assert the derivations that implementation owns: the backend test asserts `ambient.ink` ≥ 7:1 on `#000000`; the web and Flutter tests assert `page.light` ≥ 4.5:1 on `#000000` and, for the Issue stock (§2.1.6), ink ≥ 13:1 and muted ≥ 5.5:1 on the stock's page. Contrast uses the WCAG 2.x relative-luminance formula. The loop is 1,440 cases and runs in well under a second.

**Animating colour.** Web registers `@property --amb-duo`, `--amb-tint`, `--amb-ink`, `--page-tint`, `--page-light` (`syntax: "<color>"`, `inherits: true`) and transitions them 800 ms `ease.turn`. Custom-property transitions run on the main thread and restyle every descendant, so the values are written only where they paint: `--page-tint` and `--page-light` on the reader chrome's root (the overlay holding the running head, folio bar, ruler and scrims) and on the two desktop gutter elements, never on an ancestor of the strip (the setup sheet sets them on its own root when it opens); `--amb-*` on the hero or spread element that paints them, not on the page root. Flutter wraps the affected layers in `TweenAnimationBuilder<Color?>` with the same duration and curve. A new target retargets from the current colour.

#### 2.1.6 Special palettes

**Mood grades** (profile `mood`, the 7 values in capabilities §5). Cinematic-3 reads mood as a *colour grade* of the page head: a 30 vh gradient from the grade colour to `#000` at the top of Tonight, Library, Discover and Index. Readers, auth and the picker stay ungraded.

| Mood | Grade | Default soundscape (§9.4.2) |
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

| Stock | Page | Ink | Contrast | Muted | Contrast | Maps stored web K40 value |
|---|---|---|---|---|---|---|
| Nitrate (default) | `#000000` | `#D9D6D0` | 14.48:1 | `#8A877F` | 5.85:1 | `black`, `site`, `app`, null |
| Ink | `#0B0B0C` | `#E6E3DD` | 15.36:1 | `#8F8C86` | 5.87:1 | `paper`, `soft-grey` |
| Sepia Night | `#15110C` | `#E8D8BE` | 13.42:1 | `#9C8E78` | 5.87:1 | `sepia`, `cream`, `dusk` |
| Dusk | `#0D1117` | `#D3DAE3` | 13.43:1 | `#8590A0` | 5.85:1 | `midnight`, `solarized-dark`, `solarized-light` |
| Moss | `#0E130F` | `#D5DECF` | 13.57:1 | `#879384` | 5.84:1 | `forest` |
| Rosewood | `#160E10` | `#EBD5D8` | 13.62:1 | `#A08A8E` | 5.90:1 | `rose-pine`, `dawn` |
| Issue (the book's own colour) | the series' `ambient.tint` (L 0.06) | `ink.100` mixed 10 % toward `ambient.ink` in OKLab, then lightened in 0.01 L steps until ≥ 13:1 on the page | ≥ 13:1 | `ambient.ink` darkened in 0.01 L steps until 5.5:1 on the page | ≥ 5.5:1 | none (new); falls back to Nitrate when the series has no `ambient` |

The Issue stock is contrast-guarded by construction (the loop stops only when the target is met) and is covered by the same `tint` tests (§2.1.5), which add the two Issue assertions to the 1,440-case loop.

**Manga reader grounds** (the colour around and between pages): Black `#000000` (default), Ink `#0B0B0A`, Slate `#1A1A18`. Migration of mobile K11: `dark` → Ink, `black` → Black, `white` → Slate. Colour filters stay Normal / Sepia / Grey (mobile K12).

**Chart palette** (The Numbers, The Annual): series 1 `ink.100`, series 2 `ink.45` (dotted line), highlight `spot`, grid `rule.1`, heatmap levels drawn as `ink.100` squares of 3 / 5 / 7 / 10 px (size, not tone, §9.2.1), zero days a 1 px `rule.2` outline, today's cell outlined 1 px `spot`.

### 2.2 Spacing and the grid

#### 2.2.1 Units

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

#### 2.2.2 The grid

| Breakpoint | Columns | Margin | Gutter | Content max | Notes |
|---|---|---|---|---|---|
| phone (< 600) | 4 | 16 | 12 | full | Mobile web below 768 uses this grid up to 599 px |
| tablet (600–1023) | 8 | 32 | 16 | full | Web 600–767 still uses the phone frame on this grid |
| desktop (1024–1439) | 12 | 48 | 24 | full | Sidebar takes its own width; the grid lives in the remaining canvas |
| wide (1440–1919) | 12 | 72 | 24 | 1760 | |
| cinema (≥ 1920) | 12 | 96 | 32 | 1760, centred | Margins grow beyond 1760 |

Rules:
- **Everything else snaps to columns.** Rails start on the first content column and end at the grid margin; poster width and gap follow §7.8 and do not snap to column starts.
- **Spreads.** A spread is a 12-column composition: text on 5 columns, art on 7 columns bleeding off the right edge (desktop), with `scrim.gutter` over the 2 columns where they meet. On phones a spread becomes a stacked "cover + text" block.
- **Rhythm.** Vertical gaps are multiples of 8. A section is: 1 px `rule.1` section rule → 12 px → header row → 12 px → content → 64 px (desktop) / 40 px (phone) to the next section rule.
- **Measure.** Decks and synopsis max 62ch; recaps 58ch; notices 48ch; novel measure 48–88ch (reader setting).
- **Horizontal safe areas.** Landscape phones have side insets (a sensor housing is 47–62 pt), and the web sets `viewportFit: "cover"`. The side margin is max(grid margin, the side inset + 8 px): app `MediaQuery.viewPaddingOf(context).left` / `.right` + 8; web `max(var(--mm-margin), calc(env(safe-area-inset-left) + 8px))` and the same on the right. The running head, thumb index, toasts and select-mode bar inset their content by the same amounts while their `#000` grounds still bleed edge to edge. The readers centre the strip or column inside the safe rectangle, and no chrome control sits inside an inset. Full-bleed art (the Tonight cover and the feature hero) may bleed under the inset.
- **Debug overlays.** In development builds `mod+shift+g` (web) and a Diagnostics toggle (Flutter) draw the columns at 6 % spot and the baseline at 4 % bone. Designers review every screen with it on. Next to it, `mod+shift+m` (web development builds) and Diagnostics → "Show motion timings" (Flutter, any build) show the motion-timings overlay (§15.9).

### 2.3 Radius

| Token | Value | Use |
|---|---|---|
| `radius.0` | 0 | Everything: posters, covers, buttons, inputs, chips, cards, sheets, dialogs, menus, toasts, tiles, progress bars, toggles, the reader's pages |
| `radius.round` | 50 % (tokens store 9999 px) | Only: avatars and their reading-now ring, the Add-profile circle, voice monogram circles, radios (ring and dot), the Listen play button, the leader and countdown dials, the 30-day streak ring |

There is no third radius. A rounded rectangle anywhere in this skin is a bug.

### 2.4 Elevation: paper stock, not shadow

Shadows are invisible on `#000`, and Programme does not use glow for depth. Layers are paper stocks separated by rules.

| Level | Surface | Edge | Use |
|---|---|---|---|
| 0 | `paper.0` | none | The page |
| 1 | `paper.1` | none | Plates and wells inside the page |
| 2 | `paper.2` | 1 px `rule.2` on the edge that faces the page (top of a sheet, all four sides of a menu) | Sheets, menus, popovers, palette, toasts |
| 3 | `paper.3` | 1 px `ink.30` all round | Dialogs (always over `scrim.modal`) |
| Focus light | n/a | Double ring: 2 px `ink.100` outline at 2 px offset plus a black halo out to 6 px (web `box-shadow: 0 0 0 6px #000`, combined with any existing shadow; the halo is a solid `#000000` band from the control's edge out to 6 px with the ring painted over it from 2 to 4 px out; Flutter `CineFocusRing` paints the same geometry, §2.8.2). Invisible on black; over art it separates the ring at 18.44:1 | Keyboard focus on anything |
| Art light | n/a | `0 0 48px -16px ambient.duo` at 60 % | Poster hover and focus only: the art throws its own light. The only glow in the skin besides the splash bloom and the streak flame. The lightbox (§7.30) deliberately has none. |

**Stacking layers** (`z.*`; the same order on both clients, Flutter uses `Overlay` entries in this order above the router):

| Token | Value | Layer |
|---|---|---|
| `z.page` | 0 | Page content |
| `z.sticky` | 10 | Sticky contents tabs, select-mode bars, the now-showing strip |
| `z.chrome` | 20 | Running head, thumb index, sidebar, reader chrome |
| `z.panel` | 30 | Desktop column panels, reader side panels, preview slates |
| `z.sheet` | 40 | Sheets and their barrier |
| `z.dialog` | 50 | Dialogs, the certificate, the command palette |
| `z.toast` | 60 | Subtitles (toasts), the stop-press banner |
| `z.lightbox` | 70 | Lightbox |
| `z.shutter` | 80 | Column wipe blades, the Iris, Stop the press, the Cut-to-home flight layer |
| `z.debug` | 90 | Grid overlay and motion-timings overlay (development and Diagnostics only) |

### 2.5 Blur

No `backdrop-filter` anywhere. Blur is applied to images and to letters, transiently:

| Token | Value | Use |
|---|---|---|
| `blur.letter` | 8 px → 0 | Per-letter heading reveal (§10.1) |
| `blur.rack` | 14 px → 0 | Image rack-focus on first load |
| `blur.bleed` | 56 px, static | The cover copy that fills the art columns of a spread beside a portrait cover (covers are 720 px max, so a spread never shows an upscaled sharp cover) |
| `blur.card` | 24 px, static | Background of the next-chapter card and the Listen full player (on a duotone copy) |
| `blur.defocus` | 0 → 6 px | "Stop the press" skin-switch outgoing rack (§8.30.3) |

### 2.6 Borders and rules

| Token | Spec | Use |
|---|---|---|
| `rule.hair` | 1 px `rule.1` | Row dividers, section rules, column rules on desktop two-pane layouts |
| `rule.strong` | 1 px `rule.2` | Sheet top edge, unfocused input underline, slider track |
| `rule.ink` | 1 px `ink.100` | Secondary button outline, checkbox outline when checked |
| `rule.heavy` | 3 px `ink.100` | Above notices, above stat blocks, under the phone masthead |
| `rule.oxford` | 3 px `ink.100` + 2 px gap + 1 px `ink.100` | Under the Tonight masthead and page mastheads on desktop; under the wordmark. Every Oxford rule in this contract is this shape (3 + 2 + 1 px at DPR 1, scaled in that ratio in raster assets, §12.3, §12.6) |
| `rule.spot` | 2 px `spot` | Active tab and nav, input focus, selected chip, progress fill |
| `rule.proof` | 2 px `proof` | Input in error, destructive confirm area's left edge |
| Dot leaders | `·` at 0.5em intervals in `ink.30`, `type.folio` | Contents lists, cast lists, the Index page, settings rows with values |

### 2.7 Iconography

- **Set:** Phosphor on both platforms (`@phosphor-icons/react` 2.1.10, MIT; `phosphor_flutter` 2.1.0, MIT; 1,512 icons at parity, `research/brand.md` §8).
- **Weights for this skin:** **Light** (12/256 stroke, 1.125 px at 24 px) as the default at 24 px, because its hairline matches the Didone hairlines; **Regular** at 20 px and below (Light gets too thin); **Fill** for the active tab and nav item, selected toggles such as favourite, and the streak flame. Never Bold or Duotone (Duotone is Glass's voice).
- **Sizes:** 16 (inline in captions), 20 (buttons, rows), 24 (bars, tabs), 32 (notices, empty states; Light). Hit areas are always 44 × 44 (iOS, mobile web) or 48 × 48 (Android) through padding on coarse pointers, and at least 32 × 32 on desktop web's fine pointer (§14.6).
- **Words first.** Navigation always pairs icons with labels. Icon-only buttons appear only in reader chrome, row trailing actions and the running head, and always carry a tooltip (web `title` plus `aria-label`; Flutter `Tooltip` plus `Semantics`).
- **Core map** (Phosphor names): back `arrow-left`, close `x`, search `magnifying-glass`, Tonight `moon-stars`, Library `books`, Discover `compass`, Downloads `download-simple`, Index `list-numbers`, Updates `bell-simple`, Sources `globe-simple`, Collections `stack-simple`, History `clock-counter-clockwise`, Bookmarks `bookmark-simple`, The Numbers `chart-bar`, Circle `users-three`, Settings `gear-six`, Status `pulse`, Picks `sparkle`, reader settings `sliders-horizontal`, type `text-aa`, contents `list-numbers`, listen `headphones`, play `play`, pause `pause`, previous chapter `skip-back`, next chapter `skip-forward`, download `cloud-arrow-down`, downloaded `check-square`, pin `push-pin`, favourite `star`, follow `plus`, following `check`, notify `bell-ringing`, share `export`, recommend `paper-plane-tilt`, filter `funnel-simple`, sort `arrows-down-up`, grid `squares-four`, list `rows`, select `check-square-offset`, delete `trash-simple`, edit `pencil-simple-line`, overflow `dots-three`, fullscreen `corners-out` / `corners-in`, zoom `magnifying-glass-plus` / `-minus`, brightness `sun-dim`, warmth `thermometer-simple`, offline `wifi-slash`, refresh `arrow-clockwise`, external `arrow-square-out`, soundscape `waveform`, auto-scroll `play` with the `strip-scroll` custom glyph, flame `flame`.
- **Custom glyphs (10)**, drawn on Phosphor's 256 grid in Light, Regular and Fill: `mm-mark` (the monogram, §12.2), `flame-1` (a single-tongue flame, streaks of 1–6 days), `flame-3` (a three-tongue flame, 7 days and longer; §9.2.2), `strip-scroll` (a webtoon strip with a down chevron), `panel-focus` (a panel in corner brackets, guided view), `bubble-search` (speech bubble with a magnifier, dialogue search), `certificate-18` (a square seal with "18", the 18+ mark; the icon-slot form, for menu items and settings rows only; never drawn in place of the §7.19 badge), `voice-31` (`user-sound` with a stacked badge, the voice cast), `annual` (a folio "No." over a rule, The Annual), `highlighter` (a chisel marker, follow-along settings). Web: React components from the SVGs. Flutter: one TTF built with `fantasticon` 4.1.0 (npm, MIT, build-time only) plus a `const IconData` class.
- **Glyph masters.** The descriptions above are the brief; the construction is the SVG master. Each glyph is drawn on Phosphor's 256 grid with a 16-unit safe inset, stroke 12 (Light) and 16 (Regular) with round caps and joins to match Phosphor, Fill as closed shapes, and committed as `brand/cinematic/glyphs/{name}-{light,regular,fill}.svg` before the Tonight cluster starts. `mm-mark` reuses the monogram construction of §12.2 scaled to the 256 grid (bounding box x 58–198, y 68–188).

### 2.8 Token name map: web, Tailwind and Flutter side by side

`design/build.mjs` (`stack-decision.md` §2.1) emits every key below three ways, with identical values:

- **Web CSS custom property**: `--mm-` + the key with dots and underscores turned into hyphens, declared under `[data-skin="cinematic"]` in `frontend/src/skins/cinematic/tokens.generated.css`. Those declarations sit on `<html>`, and a `var()` inside a custom property is substituted there, so a value that reads a variable set on the painting element (`scrim.head`, `scrim.sole`, `scrim.foot`) gets no property and is emitted only as its `@utility` (§2.8.3).
- **Tailwind 4 `@theme` name**: emitted into `frontend/src/skins/theme.generated.css` as `@theme inline { --color-paper-2: var(--mm-color-paper-2); … }`, so the utility (`bg-paper-2`, `text-ink-100`, `ease-settle`, `blur-letter`, `rounded-0`) always resolves through the skin-scoped property. The rule "Tailwind name `X` maps to `var(--mm-X)`" is the same for both skins, so the union of both skins' `@theme` entries can never conflict; a Cinematic screen uses only the names in this table (checked by `design/lint-utilities.mjs`, about 40 lines of Node stdlib run in the same CI step as `design/build.mjs --check`, which greps `src/skins/cinematic/**` for utilities outside this list; kept out of `build.mjs` so the generator stays at the stack's ~150 lines). Durations have no `@theme` namespace in Tailwind 4 and are used as `duration-(--mm-dur-line)`.
- **Flutter field**: a field of `CineTokens extends ThemeExtension<CineTokens>` in `mobile/lib/skins/cinematic/tokens.g.dart` (camelCase of the full key), attached through `ThemeData(extensions: [cinematicTokens])` and read as `context.cine.colorSpot` (an extension getter on `BuildContext`). The same values are also emitted as `static const` members of `CineColors`, `CineSpace`, `CineDur`, `CineCurves` and `CineSprings` for `const` constructors.

**Lint scope.** `design/lint-utilities.mjs` checks only `bg-*`, `text-*` (colour and size), `border-*` colour, `outline-*` colour, `fill-*`, `stroke-*`, `font-*`, `tracking-*`, `leading-*`, `rounded-*`, `blur-*`, `ease-*`, `duration-*`, `z-*` and `animate-*`, and fails on names not in §2.8, §3.5 or the `@theme` block of `frontend/src/skins/cinematic/motion.css` (which registers `--animate-caret-out` with its `@keyframes`, §10.2.3), and on arbitrary colour values (`[#…]`, `[rgb…]`). Arbitrary `(--mm-*)` references are allowed (`duration-(--mm-dur-line)`, `bg-(--mm-scrim-modal)`). Tailwind's `/NN` opacity modifier is allowed on any §2.8 colour name, runtime colours included, and on an arbitrary `(--mm-*)` colour reference (`border-ink-100/40`, `bg-paper-0/84`, `bg-paper-2/90`, `bg-paper-2/92`, `bg-paper-0/50`, `bg-stock-page/90`, `border-stock-muted/30`); Flutter applies the same alpha with `.withValues(alpha: …)` on the `CineTokens` colour. No token exists per alpha. Layout, position and size utilities, including arbitrary em lengths, are out of scope.

#### 2.8.1 Colour

| Key | Value | Web CSS property | Tailwind 4 `@theme` (utility) | Flutter `CineTokens` field |
|---|---|---|---|---|
| `color.paper.0` | `#000000` | `--mm-color-paper-0` | `--color-paper-0` (`bg-paper-0`) | `colorPaper0` = `Color(0xFF000000)` |
| `color.paper.1` | `#0B0B0A` | `--mm-color-paper-1` | `--color-paper-1` (`bg-paper-1`) | `colorPaper1` = `Color(0xFF0B0B0A)` |
| `color.paper.2` | `#121211` | `--mm-color-paper-2` | `--color-paper-2` (`bg-paper-2`) | `colorPaper2` = `Color(0xFF121211)` |
| `color.paper.3` | `#1A1A18` | `--mm-color-paper-3` | `--color-paper-3` (`bg-paper-3`) | `colorPaper3` = `Color(0xFF1A1A18)` |
| `color.paper.4` | `#232220` | `--mm-color-paper-4` | `--color-paper-4` (`bg-paper-4`) | `colorPaper4` = `Color(0xFF232220)` |
| `color.rule.1` | `#2B2A27` | `--mm-color-rule-1` | `--color-rule-1` (`bg-rule-1`) | `colorRule1` = `Color(0xFF2B2A27)` |
| `color.rule.2` | `#3D3C38` | `--mm-color-rule-2` | `--color-rule-2` (`bg-rule-2`) | `colorRule2` = `Color(0xFF3D3C38)` |
| `color.ink.30` | `#4D4B47` | `--mm-color-ink-30` | `--color-ink-30` (`bg-ink-30`) | `colorInk30` = `Color(0xFF4D4B47)` |
| `color.ink.45` | `#7A7770` | `--mm-color-ink-45` | `--color-ink-45` (`bg-ink-45`) | `colorInk45` = `Color(0xFF7A7770)` |
| `color.ink.60` | `#9A978F` | `--mm-color-ink-60` | `--color-ink-60` (`bg-ink-60`) | `colorInk60` = `Color(0xFF9A978F)` |
| `color.ink.80` | `#C9C6BE` | `--mm-color-ink-80` | `--color-ink-80` (`bg-ink-80`) | `colorInk80` = `Color(0xFFC9C6BE)` |
| `color.ink.100` | `#F3F0E8` | `--mm-color-ink-100` | `--color-ink-100` (`bg-ink-100`) | `colorInk100` = `Color(0xFFF3F0E8)` |
| `color.spot` | `#F4D03F` | `--mm-color-spot` | `--color-spot` (`bg-spot`) | `colorSpot` = `Color(0xFFF4D03F)` |
| `color.spot.press` | `#D9B62C` | `--mm-color-spot-press` | `--color-spot-press` (`bg-spot-press`) | `colorSpotPress` = `Color(0xFFD9B62C)` |
| `color.spot.wash` | `rgba(244,208,63,0.16)` | `--mm-color-spot-wash` | `--color-spot-wash` (`bg-spot-wash`) | `colorSpotWash` = `Color(0x29F4D03F)` |
| `color.spot.glow` | `rgba(244,208,63,0.35)` | `--mm-color-spot-glow` | `--color-spot-glow` (`bg-spot-glow`) | `colorSpotGlow` = `Color(0x59F4D03F)` |
| `color.proof` | `#FF5B4A` | `--mm-color-proof` | `--color-proof` (`bg-proof`) | `colorProof` = `Color(0xFFFF5B4A)` |
| `color.proof.press` | `#E0483A` | `--mm-color-proof-press` | `--color-proof-press` (`bg-proof-press`) | `colorProofPress` = `Color(0xFFE0483A)` |
| `color.proof.wash` | `rgba(255,91,74,0.12)` | `--mm-color-proof-wash` | `--color-proof-wash` (`bg-proof-wash`) | `colorProofWash` = `Color(0x1FFF5B4A)` |
| `color.set` | `#57D68D` | `--mm-color-set` | `--color-set` (`bg-set`) | `colorSet` = `Color(0xFF57D68D)` |
| `color.info` | `#9CC8FF` | `--mm-color-info` | `--color-info` (`bg-info`) | `colorInfo` = `Color(0xFF9CC8FF)` |
| `color.note` | `#F4D03F` (alias of `color.spot`) | `--mm-color-note: var(--mm-color-spot)` | `--color-note` (`text-note`) | `colorNote` = `Color(0xFFF4D03F)` |
| `color.onart` | `rgba(0,0,0,0.64)` | `--mm-color-onart` | `--color-onart` (`bg-onart`) | `colorOnart` = `Color(0xA3000000)` |
| `color.hairline.art` | `rgba(243,240,232,0.08)` | `--mm-color-hairline-art` | `--color-hairline-art` (`border-hairline-art`) | `colorHairlineArt` = `Color(0x14F3F0E8)` |
| `color.galley` | `rgba(243,240,232,0.06)` | `--mm-color-galley` | `--color-galley` (`bg-galley`) | `colorGalley` = `Color(0x0FF3F0E8)` |
| `color.leader.sweep` | `rgba(243,240,232,0.22)` | `--mm-color-leader-sweep` | `--color-leader-sweep` (`fill-leader-sweep`) | `colorLeaderSweep` = `Color(0x38F3F0E8)` |
| `color.lightbox` | `rgba(0,0,0,0.96)` | `--mm-color-lightbox` | `--color-lightbox` (`bg-lightbox`) | `colorLightbox` = `Color(0xF5000000)` |
| `color.matte.guided` | `rgba(0,0,0,0.85)` | `--mm-color-matte-guided` | `--color-matte-guided` (`bg-matte-guided`) | `colorMatteGuided` = `Color(0xD9000000)` |
| `color.warmth` | `#FF8A00` | `--mm-color-warmth` | `--color-warmth` (`bg-warmth`) | `colorWarmth` = `Color(0xFFFF8A00)` |
| `color.ambient.fallback.duo` | `#B8B2A4` | `--mm-color-ambient-fallback-duo` | `--color-ambient-fallback-duo` (`bg-ambient-fallback-duo`) | `colorAmbientFallbackDuo` = `Color(0xFFB8B2A4)` |
| `color.ambient.fallback.tint` | `#0E0D0B` | `--mm-color-ambient-fallback-tint` | `--color-ambient-fallback-tint` (`bg-ambient-fallback-tint`) | `colorAmbientFallbackTint` = `Color(0xFF0E0D0B)` |
| `color.ambient.fallback.ink` | `#F3F0E8` | `--mm-color-ambient-fallback-ink` | `--color-ambient-fallback-ink` (`bg-ambient-fallback-ink`) | `colorAmbientFallbackInk` = `Color(0xFFF3F0E8)` |
| `color.mood.romantic` | `#1A0B10` | `--mm-color-mood-romantic` | `--color-mood-romantic` (`bg-mood-romantic`) | `colorMoodRomantic` = `Color(0xFF1A0B10)` |
| `color.mood.action` | `#1A0D08` | `--mm-color-mood-action` | `--color-mood-action` (`bg-mood-action`) | `colorMoodAction` = `Color(0xFF1A0D08)` |
| `color.mood.comedy` | `#17130A` | `--mm-color-mood-comedy` | `--color-mood-comedy` (`bg-mood-comedy`) | `colorMoodComedy` = `Color(0xFF17130A)` |
| `color.mood.horror` | `#0F0A0D` | `--mm-color-mood-horror` | `--color-mood-horror` (`bg-mood-horror`) | `colorMoodHorror` = `Color(0xFF0F0A0D)` |
| `color.mood.slice_of_life` | `#0F120C` | `--mm-color-mood-slice-of-life` | `--color-mood-slice-of-life` (`bg-mood-slice-of-life`) | `colorMoodSliceOfLife` = `Color(0xFF0F120C)` |
| `color.mood.fantasy` | `#120C18` | `--mm-color-mood-fantasy` | `--color-mood-fantasy` (`bg-mood-fantasy`) | `colorMoodFantasy` = `Color(0xFF120C18)` |
| `color.speaker.1` | `#7CC4FF` | `--mm-color-speaker-1` | `--color-speaker-1` (`bg-speaker-1`) | `colorSpeaker1` = `Color(0xFF7CC4FF)` |
| `color.speaker.2` | `#FF8A7A` | `--mm-color-speaker-2` | `--color-speaker-2` (`bg-speaker-2`) | `colorSpeaker2` = `Color(0xFFFF8A7A)` |
| `color.speaker.3` | `#9BE08A` | `--mm-color-speaker-3` | `--color-speaker-3` (`bg-speaker-3`) | `colorSpeaker3` = `Color(0xFF9BE08A)` |
| `color.speaker.4` | `#D6A3FF` | `--mm-color-speaker-4` | `--color-speaker-4` (`bg-speaker-4`) | `colorSpeaker4` = `Color(0xFFD6A3FF)` |
| `color.speaker.5` | `#FFC266` | `--mm-color-speaker-5` | `--color-speaker-5` (`bg-speaker-5`) | `colorSpeaker5` = `Color(0xFFFFC266)` |
| `color.speaker.6` | `#6FE3D6` | `--mm-color-speaker-6` | `--color-speaker-6` (`bg-speaker-6`) | `colorSpeaker6` = `Color(0xFF6FE3D6)` |
| `color.speaker.7` | `#FF9FCB` | `--mm-color-speaker-7` | `--color-speaker-7` (`bg-speaker-7`) | `colorSpeaker7` = `Color(0xFFFF9FCB)` |
| `color.speaker.8` | `#C9B38A` | `--mm-color-speaker-8` | `--color-speaker-8` (`bg-speaker-8`) | `colorSpeaker8` = `Color(0xFFC9B38A)` |
| `color.speaker.9` | `#A6B4FF` | `--mm-color-speaker-9` | `--color-speaker-9` (`bg-speaker-9`) | `colorSpeaker9` = `Color(0xFFA6B4FF)` |
| `color.speaker.10` | `#E0E0A0` | `--mm-color-speaker-10` | `--color-speaker-10` (`bg-speaker-10`) | `colorSpeaker10` = `Color(0xFFE0E0A0)` |
| `color.stock.nitrate.page` | `#000000` | `--mm-color-stock-nitrate-page` | `--color-stock-nitrate-page` (`bg-stock-nitrate-page`) | `colorStockNitratePage` = `Color(0xFF000000)` |
| `color.stock.nitrate.ink` | `#D9D6D0` | `--mm-color-stock-nitrate-ink` | `--color-stock-nitrate-ink` (`bg-stock-nitrate-ink`) | `colorStockNitrateInk` = `Color(0xFFD9D6D0)` |
| `color.stock.nitrate.muted` | `#8A877F` | `--mm-color-stock-nitrate-muted` | `--color-stock-nitrate-muted` (`bg-stock-nitrate-muted`) | `colorStockNitrateMuted` = `Color(0xFF8A877F)` |
| `color.stock.ink.page` | `#0B0B0C` | `--mm-color-stock-ink-page` | `--color-stock-ink-page` (`bg-stock-ink-page`) | `colorStockInkPage` = `Color(0xFF0B0B0C)` |
| `color.stock.ink.ink` | `#E6E3DD` | `--mm-color-stock-ink-ink` | `--color-stock-ink-ink` (`bg-stock-ink-ink`) | `colorStockInkInk` = `Color(0xFFE6E3DD)` |
| `color.stock.ink.muted` | `#8F8C86` | `--mm-color-stock-ink-muted` | `--color-stock-ink-muted` (`bg-stock-ink-muted`) | `colorStockInkMuted` = `Color(0xFF8F8C86)` |
| `color.stock.sepia_night.page` | `#15110C` | `--mm-color-stock-sepia-night-page` | `--color-stock-sepia-night-page` (`bg-stock-sepia-night-page`) | `colorStockSepiaNightPage` = `Color(0xFF15110C)` |
| `color.stock.sepia_night.ink` | `#E8D8BE` | `--mm-color-stock-sepia-night-ink` | `--color-stock-sepia-night-ink` (`bg-stock-sepia-night-ink`) | `colorStockSepiaNightInk` = `Color(0xFFE8D8BE)` |
| `color.stock.sepia_night.muted` | `#9C8E78` | `--mm-color-stock-sepia-night-muted` | `--color-stock-sepia-night-muted` (`bg-stock-sepia-night-muted`) | `colorStockSepiaNightMuted` = `Color(0xFF9C8E78)` |
| `color.stock.dusk.page` | `#0D1117` | `--mm-color-stock-dusk-page` | `--color-stock-dusk-page` (`bg-stock-dusk-page`) | `colorStockDuskPage` = `Color(0xFF0D1117)` |
| `color.stock.dusk.ink` | `#D3DAE3` | `--mm-color-stock-dusk-ink` | `--color-stock-dusk-ink` (`bg-stock-dusk-ink`) | `colorStockDuskInk` = `Color(0xFFD3DAE3)` |
| `color.stock.dusk.muted` | `#8590A0` | `--mm-color-stock-dusk-muted` | `--color-stock-dusk-muted` (`bg-stock-dusk-muted`) | `colorStockDuskMuted` = `Color(0xFF8590A0)` |
| `color.stock.moss.page` | `#0E130F` | `--mm-color-stock-moss-page` | `--color-stock-moss-page` (`bg-stock-moss-page`) | `colorStockMossPage` = `Color(0xFF0E130F)` |
| `color.stock.moss.ink` | `#D5DECF` | `--mm-color-stock-moss-ink` | `--color-stock-moss-ink` (`bg-stock-moss-ink`) | `colorStockMossInk` = `Color(0xFFD5DECF)` |
| `color.stock.moss.muted` | `#879384` | `--mm-color-stock-moss-muted` | `--color-stock-moss-muted` (`bg-stock-moss-muted`) | `colorStockMossMuted` = `Color(0xFF879384)` |
| `color.stock.rosewood.page` | `#160E10` | `--mm-color-stock-rosewood-page` | `--color-stock-rosewood-page` (`bg-stock-rosewood-page`) | `colorStockRosewoodPage` = `Color(0xFF160E10)` |
| `color.stock.rosewood.ink` | `#EBD5D8` | `--mm-color-stock-rosewood-ink` | `--color-stock-rosewood-ink` (`bg-stock-rosewood-ink`) | `colorStockRosewoodInk` = `Color(0xFFEBD5D8)` |
| `color.stock.rosewood.muted` | `#A08A8E` | `--mm-color-stock-rosewood-muted` | `--color-stock-rosewood-muted` (`bg-stock-rosewood-muted`) | `colorStockRosewoodMuted` = `Color(0xFFA08A8E)` |
| `color.ground.black` | `#000000` | `--mm-color-ground-black` | `--color-ground-black` (`bg-ground-black`) | `colorGroundBlack` = `Color(0xFF000000)` |
| `color.ground.ink` | `#0B0B0A` | `--mm-color-ground-ink` | `--color-ground-ink` (`bg-ground-ink`) | `colorGroundInk` = `Color(0xFF0B0B0A)` |
| `color.ground.slate` | `#1A1A18` | `--mm-color-ground-slate` | `--color-ground-slate` (`bg-ground-slate`) | `colorGroundSlate` = `Color(0xFF1A1A18)` |
| `color.avatar.violet` | `#6E56CF` | `--mm-color-avatar-violet` | `--color-avatar-violet` (`bg-avatar-violet`) | `colorAvatarViolet` = `Color(0xFF6E56CF)` |
| `color.avatar.cyan` | `#1A778C` | `--mm-color-avatar-cyan` | `--color-avatar-cyan` (`bg-avatar-cyan`) | `colorAvatarCyan` = `Color(0xFF1A778C)` |
| `color.avatar.rose` | `#B83A56` | `--mm-color-avatar-rose` | `--color-avatar-rose` (`bg-avatar-rose`) | `colorAvatarRose` = `Color(0xFFB83A56)` |
| `color.avatar.amber` | `#95630F` | `--mm-color-avatar-amber` | `--color-avatar-amber` (`bg-avatar-amber`) | `colorAvatarAmber` = `Color(0xFF95630F)` |
| `color.avatar.emerald` | `#1A7B54` | `--mm-color-avatar-emerald` | `--color-avatar-emerald` (`bg-avatar-emerald`) | `colorAvatarEmerald` = `Color(0xFF1A7B54)` |
| `color.avatar.ember` | `#BE4523` | `--mm-color-avatar-ember` | `--color-avatar-ember` (`bg-avatar-ember`) | `colorAvatarEmber` = `Color(0xFFBE4523)` |
| `color.avatar.blade` | `#5E6878` | `--mm-color-avatar-blade` | `--color-avatar-blade` (`bg-avatar-blade`) | `colorAvatarBlade` = `Color(0xFF5E6878)` |
| `color.avatar.phantom` | `#474B94` | `--mm-color-avatar-phantom` | `--color-avatar-phantom` (`bg-avatar-phantom`) | `colorAvatarPhantom` = `Color(0xFF474B94)` |
| `color.avatar.arcane` | `#7D45B8` | `--mm-color-avatar-arcane` | `--color-avatar-arcane` (`bg-avatar-arcane`) | `colorAvatarArcane` = `Color(0xFF7D45B8)` |
| `color.avatar.lunar` | `#2B5699` | `--mm-color-avatar-lunar` | `--color-avatar-lunar` (`bg-avatar-lunar`) | `colorAvatarLunar` = `Color(0xFF2B5699)` |
| `color.avatar.star` | `#85690C` | `--mm-color-avatar-star` | `--color-avatar-star` (`bg-avatar-star`) | `colorAvatarStar` = `Color(0xFF85690C)` |
| `color.avatar.reader` | `#177878` | `--mm-color-avatar-reader` | `--color-avatar-reader` (`bg-avatar-reader`) | `colorAvatarReader` = `Color(0xFF177878)` |

Runtime colours (not tokens; written by the ambient and page-tint code only on the elements that paint them (§2.1.5), registered with `@property` so they interpolate): `--amb-duo`, `--amb-tint`, `--amb-ink`, `--page-tint`, `--page-light` → Tailwind `@theme inline { --color-amb-duo: var(--amb-duo); … }` (`text-amb-ink`, `bg-page-tint`) → Flutter `CineAmbient.of(context).duo / .tint / .ink` and `ReaderEngineState.pageTint` mapped through `CineTint.light(seed)`. Initial values are the `color.ambient.fallback.*` tokens. The novel reader's active paper stock is a second runtime set: the novel reader root sets `--stock-page`, `--stock-ink` and `--stock-muted` from the chosen stock's `color.stock.<stock>.*` tokens (`var(--mm-color-stock-sepia-night-page)` …) or, for Issue, from the values `tint.ts` derives (§2.1.6), mapped by `@theme inline { --color-stock-page: var(--stock-page); --color-stock-ink: var(--stock-ink); --color-stock-muted: var(--stock-muted); }` (`bg-stock-page`, `text-stock-ink`, `border-stock-muted`; the Ink stock's own tokens keep their full names, `bg-stock-ink-page` …). These three are not registered with `@property`. Flutter reads the same three colours from the novel reader's resolved stock (the `colorStock*` fields of `CineTokens`, or the Issue derivation in `tint.dart`).

#### 2.8.2 Space, grid, breakpoints, radius, blur, rules, focus, layers

| Key | Value | Web CSS property | Tailwind 4 | Flutter `CineTokens` field |
|---|---|---|---|---|
| `space.0` | 0 px | `--mm-space-0: 0px` | `--spacing: 0.25rem` base, so `p-0`, `gap-0`, `m-0` = 0 px | `space0` = `0.0` |
| `space.1` | 4 px | `--mm-space-1: 4px` | `--spacing: 0.25rem` base, so `p-1`, `gap-1`, `m-1` = 4 px | `space1` = `4.0` |
| `space.2` | 8 px | `--mm-space-2: 8px` | `--spacing: 0.25rem` base, so `p-2`, `gap-2`, `m-2` = 8 px | `space2` = `8.0` |
| `space.3` | 12 px | `--mm-space-3: 12px` | `--spacing: 0.25rem` base, so `p-3`, `gap-3`, `m-3` = 12 px | `space3` = `12.0` |
| `space.4` | 16 px | `--mm-space-4: 16px` | `--spacing: 0.25rem` base, so `p-4`, `gap-4`, `m-4` = 16 px | `space4` = `16.0` |
| `space.5` | 20 px | `--mm-space-5: 20px` | `--spacing: 0.25rem` base, so `p-5`, `gap-5`, `m-5` = 20 px | `space5` = `20.0` |
| `space.6` | 24 px | `--mm-space-6: 24px` | `--spacing: 0.25rem` base, so `p-6`, `gap-6`, `m-6` = 24 px | `space6` = `24.0` |
| `space.8` | 32 px | `--mm-space-8: 32px` | `--spacing: 0.25rem` base, so `p-8`, `gap-8`, `m-8` = 32 px | `space8` = `32.0` |
| `space.10` | 40 px | `--mm-space-10: 40px` | `--spacing: 0.25rem` base, so `p-10`, `gap-10`, `m-10` = 40 px | `space10` = `40.0` |
| `space.12` | 48 px | `--mm-space-12: 48px` | `--spacing: 0.25rem` base, so `p-12`, `gap-12`, `m-12` = 48 px | `space12` = `48.0` |
| `space.16` | 64 px | `--mm-space-16: 64px` | `--spacing: 0.25rem` base, so `p-16`, `gap-16`, `m-16` = 64 px | `space16` = `64.0` |
| `space.20` | 80 px | `--mm-space-20: 80px` | `--spacing: 0.25rem` base, so `p-20`, `gap-20`, `m-20` = 80 px | `space20` = `80.0` |
| `space.24` | 96 px | `--mm-space-24: 96px` | `--spacing: 0.25rem` base, so `p-24`, `gap-24`, `m-24` = 96 px | `space24` = `96.0` |
| `space.32` | 128 px | `--mm-space-32: 128px` | `--spacing: 0.25rem` base, so `p-32`, `gap-32`, `m-32` = 128 px | `space32` = `128.0` |
| `grid.phone` | 4 columns · margin 16 · gutter 12 · max full | `--mm-grid-columns: 4; --mm-grid-margin: 16px; --mm-grid-gutter: 12px` (set inside the `phone` media query) | `grid-cols-(--mm-grid-template)` where `--mm-grid-template: repeat(4, minmax(0, 1fr))`; `px-(--mm-grid-margin)`, `gap-(--mm-grid-gutter)` | `gridPhone` = `GridSpec(columns: 4, margin: 16, gutter: 12, max: double.infinity)` |
| `grid.tablet` | 8 columns · margin 32 · gutter 16 · max full | `--mm-grid-columns: 8; --mm-grid-margin: 32px; --mm-grid-gutter: 16px` (set inside the `tablet` media query) | `grid-cols-(--mm-grid-template)` where `--mm-grid-template: repeat(8, minmax(0, 1fr))`; `px-(--mm-grid-margin)`, `gap-(--mm-grid-gutter)` | `gridTablet` = `GridSpec(columns: 8, margin: 32, gutter: 16, max: double.infinity)` |
| `grid.desktop` | 12 columns · margin 48 · gutter 24 · max full | `--mm-grid-columns: 12; --mm-grid-margin: 48px; --mm-grid-gutter: 24px` (set inside the `desktop` media query) | `grid-cols-(--mm-grid-template)` where `--mm-grid-template: repeat(12, minmax(0, 1fr))`; `px-(--mm-grid-margin)`, `gap-(--mm-grid-gutter)` | `gridDesktop` = `GridSpec(columns: 12, margin: 48, gutter: 24, max: double.infinity)` |
| `grid.wide` | 12 columns · margin 72 · gutter 24 · max 1760 | `--mm-grid-columns: 12; --mm-grid-margin: 72px; --mm-grid-gutter: 24px` (set inside the `wide` media query) | `grid-cols-(--mm-grid-template)` where `--mm-grid-template: repeat(12, minmax(0, 1fr))`; `px-(--mm-grid-margin)`, `gap-(--mm-grid-gutter)` | `gridWide` = `GridSpec(columns: 12, margin: 72, gutter: 24, max: 1760)` |
| `grid.cinema` | 12 columns · margin 96 · gutter 32 · max 1760 | `--mm-grid-columns: 12; --mm-grid-margin: 96px; --mm-grid-gutter: 32px` (set inside the `cinema` media query) | `grid-cols-(--mm-grid-template)` where `--mm-grid-template: repeat(12, minmax(0, 1fr))`; `px-(--mm-grid-margin)`, `gap-(--mm-grid-gutter)` | `gridCinema` = `GridSpec(columns: 12, margin: 96, gutter: 32, max: 1760)` |
| `bp.tablet` | 600 px | `--mm-bp-tablet: 600px` (documentation only; media queries use the literal) | `--breakpoint-tablet: 37.5rem` (variant `tablet:`) | `bpTablet` = `600.0` |
| `bp.frame` | 768 px | `--mm-bp-frame: 768px` (documentation only; media queries use the literal) | `--breakpoint-frame: 48rem` (variant `frame:`) | `bpFrame` = `768.0` |
| `bp.desktop` | 1024 px | `--mm-bp-desktop: 1024px` (documentation only; media queries use the literal) | `--breakpoint-desktop: 64rem` (variant `desktop:`) | `bpDesktop` = `1024.0` |
| `bp.wide` | 1440 px | `--mm-bp-wide: 1440px` (documentation only; media queries use the literal) | `--breakpoint-wide: 90rem` (variant `wide:`) | `bpWide` = `1440.0` |
| `bp.cinema` | 1920 px | `--mm-bp-cinema: 1920px` (documentation only; media queries use the literal) | `--breakpoint-cinema: 120rem` (variant `cinema:`) | `bpCinema` = `1920.0` |
| `radius.0` | 0 | `--mm-radius-0: 0px` | `--radius-0` (`rounded-0`) | `radius0` = `0.0` |
| `radius.round` | 50 % | `--mm-radius-round: 9999px` | `--radius-round` (`rounded-round`) | `radiusRound` = `9999.0` (use `BoxShape.circle`) |
| `blur.letter` | 8 px | `--mm-blur-letter: 8px` | `--blur-letter` (`blur-letter`) | `blurLetter` = `8.0` (σ for `ImageFilter.blur`) |
| `blur.rack` | 14 px | `--mm-blur-rack: 14px` | `--blur-rack` (`blur-rack`) | `blurRack` = `14.0` (σ for `ImageFilter.blur`) |
| `blur.bleed` | 56 px | `--mm-blur-bleed: 56px` | `--blur-bleed` (`blur-bleed`) | `blurBleed` = `56.0` (σ for `ImageFilter.blur`) |
| `blur.card` | 24 px | `--mm-blur-card: 24px` | `--blur-card` (`blur-card`) | `blurCard` = `24.0` (σ for `ImageFilter.blur`) |
| `blur.defocus` | 6 px | `--mm-blur-defocus: 6px` | `--blur-defocus` (`blur-defocus`) | `blurDefocus` = `6.0` (σ for `ImageFilter.blur`) |
| `rule.hair` | 1 px `color.rule.1` | `--mm-rule-hair-width` (the colour comes from the colour token) | `border border-rule-1` | `ruleHair` = `BorderSide(color: Color(0xFF2B2A27), width: 1)` |
| `rule.strong` | 1 px `color.rule.2` | `--mm-rule-strong-width` (the colour comes from the colour token) | `border border-rule-2` | `ruleStrong` = `BorderSide(color: Color(0xFF3D3C38), width: 1)` |
| `rule.ink` | 1 px `color.ink.100` | `--mm-rule-ink-width` (the colour comes from the colour token) | `border border-ink-100` | `ruleInk` = `BorderSide(color: Color(0xFFF3F0E8), width: 1)` |
| `rule.heavy` | 3 px `color.ink.100` | `--mm-rule-heavy-width` (the colour comes from the colour token) | `border-t-3 border-ink-100` | `ruleHeavy` = `BorderSide(color: Color(0xFFF3F0E8), width: 3)` |
| `rule.spot` | 2 px `color.spot` | `--mm-rule-spot-width` (the colour comes from the colour token) | `border-b-2 border-spot` | `ruleSpot` = `BorderSide(color: Color(0xFFF4D03F), width: 2)` |
| `rule.proof` | 2 px `color.proof` | `--mm-rule-proof-width` (the colour comes from the colour token) | `border-l-2 border-proof` | `ruleProof` = `BorderSide(color: Color(0xFFFF5B4A), width: 2)` |
| `rule.oxford` | 3 px `ink.100` + 2 px gap + 1 px `ink.100` | `--mm-rule-oxford-width` (the colour comes from the colour token) | the `OxfordRule` primitive (two stacked `div`s) | `ruleOxford` = `OxfordRule(thick: 3, gap: 2, thin: 1, color: Color(0xFFF3F0E8))` |
| `focus.width` / `focus.offset` / `focus.halo` | 2 px / 2 px, `color.ink.100`; halo 6 px `#000000` | `--mm-focus-width: 2px; --mm-focus-offset: 2px; --mm-focus-halo: 0 0 0 6px #000` | `outline-2 outline-offset-2 outline-ink-100 shadow-(--mm-focus-halo)` on `:focus-visible` | `focusWidth` = `2.0`, `focusOffset` = `2.0`, `focusHalo` = `6.0` (outer extent in px). `CineFocusRing` first paints the control's rect with `BorderSide(color: Color(0xFF000000), width: 6, strokeAlign: BorderSide.strokeAlignOutside)`, then the rect inflated by 2 px with `BorderSide(color: colorInk100, width: 2, strokeAlign: BorderSide.strokeAlignOutside)`: a black band from the edge out to 6 px with the bone ring over it from 2 to 4 px, as on the web |
| `hit.min` / `hit.android` / `hit.fine` | 44 / 48 / 32 px | `--mm-hit-min: 44px`, set to `32px` under `@media (pointer: fine)` (§14.6) | `min-h-(--mm-hit-min) min-w-(--mm-hit-min)` | `hitMin` = `44.0`, `hitAndroid` = `48.0` |
| `z.page` | 0 | `--mm-z-page: 0` | `z-(--mm-z-page)` | `zPage` = `0` (overlay order) |
| `z.sticky` | 10 | `--mm-z-sticky: 10` | `z-(--mm-z-sticky)` | `zSticky` = `10` (overlay order) |
| `z.chrome` | 20 | `--mm-z-chrome: 20` | `z-(--mm-z-chrome)` | `zChrome` = `20` (overlay order) |
| `z.panel` | 30 | `--mm-z-panel: 30` | `z-(--mm-z-panel)` | `zPanel` = `30` (overlay order) |
| `z.sheet` | 40 | `--mm-z-sheet: 40` | `z-(--mm-z-sheet)` | `zSheet` = `40` (overlay order) |
| `z.dialog` | 50 | `--mm-z-dialog: 50` | `z-(--mm-z-dialog)` | `zDialog` = `50` (overlay order) |
| `z.toast` | 60 | `--mm-z-toast: 60` | `z-(--mm-z-toast)` | `zToast` = `60` (overlay order) |
| `z.lightbox` | 70 | `--mm-z-lightbox: 70` | `z-(--mm-z-lightbox)` | `zLightbox` = `70` (overlay order) |
| `z.shutter` | 80 | `--mm-z-shutter: 80` | `z-(--mm-z-shutter)` | `zShutter` = `80` (overlay order) |
| `z.debug` | 90 | `--mm-z-debug: 90` | `z-(--mm-z-debug)` | `zDebug` = `90` (overlay order) |

#### 2.8.3 Scrims

| Key | Value | Web CSS property | Tailwind 4 | Flutter `CineTokens` field |
|---|---|---|---|---|
| `scrim.gutter` | horizontal, 13 eased stops (§2.1.4) to `#000000` on the text side | `--mm-scrim-gutter` (a complete `background-image` value) | `@utility scrim-gutter { background-image: var(--mm-scrim-gutter); }` (`scrim-gutter`) | `scrimGutter` = `LinearGradient(begin: Alignment.centerRight, end: Alignment.centerLeft, stops: kScrimStops, colors: [for (final a in kScrimAlpha) Color(0xFF000000).withValues(alpha: a)])` |
| `scrim.foot` | 13 eased stops to `ambient.tint`, from 40 % down the art to its solid point (the component's text-block top − 24 px), solid below | None in the `[data-skin]` block (a `var()` inside a custom property resolves on `<html>`, where `--scrim-solid-at` and the hero's `--amb-tint` do not exist). `build.mjs` writes the gradient into the utility instead, so both resolve on the element that paints it: the component sets `--scrim-solid-at` (px from that element's top edge) from its measured text block, and `--amb-tint` comes from the hero or tile (§2.1.5) | `@utility scrim-foot { background-image: linear-gradient(to bottom, <for i = 0 → 12: color-mix(in srgb, var(--amb-tint) (kScrimAlpha[i] × 100)%, transparent) calc(40% + kScrimStops[i] * (var(--scrim-solid-at, 100%) - 40%))>); }` (`scrim-foot`); the last stop's solid tint holds below the solid point | `scrimFoot(double solidAtPx, double height)` = `LinearGradient(begin: Alignment(0, -0.2), end: Alignment(0, 2 * solidAtPx / height - 1), tileMode: TileMode.clamp, stops: kScrimStops, colors: [for (final a in kScrimAlpha) ambient.tint.withValues(alpha: a)])` (built at runtime from `CineAmbient`), where `height` is the painted element's laid-out height and `solidAtPx` the same px from that element's top edge as the web's `--scrim-solid-at` (with no text block, `solidAtPx = height`); `Alignment` y runs −1..1, so y = 2 · px / h − 1 (−0.2 is 40 % down) |
| `scrim.foot.black` | bottom 60 % of its band, 13 eased stops to `#000000` | `--mm-scrim-foot-black` (a complete `background-image` value) | `@utility scrim-foot-black { background-image: var(--mm-scrim-foot-black); }` (`scrim-foot-black`) | `scrimFootBlack` = `LinearGradient(begin: Alignment(0, -0.2), end: Alignment.bottomCenter, stops: kScrimStops, colors: [for (final a in kScrimAlpha) Color(0xFF000000).withValues(alpha: a)])` |
| `scrim.head` | `#000` .88 flat over the bar's laid-out height (phone min safe area + 44 px, 48 on Android, growing at large text scales; desktop 56 px), then the 13 eased stops reversed from .88 to 0 over 44 px (phone) / 64 px (desktop); top 120 px desktop / bar + 44 px phone | None in the `[data-skin]` block (a `var()` inside a custom property resolves on `<html>`, where the bar's `--scrim-fade` does not exist, and the value would compute to invalid). `build.mjs` writes the gradient into the utility instead, so every `var()` resolves on the `::before` that paints it. The bar (positioned: `fixed`, `sticky` or `relative`) sets `isolation: isolate` (the scrim stays above the art and under the bar's content) and `--scrim-fade`: `44px` on the phone frame, `64px` from 768 px (`[--scrim-fade:44px] frame:[--scrim-fade:64px]`) | `@utility scrim-head { position: absolute; inset: 0 0 calc(-1 * var(--scrim-fade)) 0; z-index: -1; pointer-events: none; background-image: linear-gradient(to bottom, color-mix(in srgb, var(--scrim-base, #000000) 88%, transparent) 0, <for i = 12 → 0: color-mix(in srgb, var(--scrim-base, #000000) P%, transparent) calc(100% - kScrimStops[i] * var(--scrim-fade))>); }`, where `build.mjs` writes P = 88 × `kScrimAlpha[i]` as a literal; applied as `before:scrim-head` on the bar. `100%` is the `::before`'s own height (bar + fade), so the flat part ends at the bar's rendered bottom edge at every text scale with no measuring. `--scrim-base` is an unregistered local variable, black by fallback everywhere; only the reader chrome root, and only while page-tinted chrome is on (§9.4.4), sets `--scrim-base: color-mix(in srgb, var(--page-tint) 25%, #000000)`. It must stay unregistered: `--page-tint` is registered with an initial value (§2.8.1), so a `var(--page-tint, #000)` fallback would never apply and every other running head would pick up the ambient fallback tint. Because `--scrim-base` is re-substituted on the chrome root every frame, the 800 ms `--page-tint` transition still drives it | `scrimHead(bar, fade, {Color? tint})` built at runtime from the bar's laid-out height: the bar paints it behind its content as `Positioned(top: 0, left: 0, right: 0, bottom: -fade)` in a `Stack(clipBehavior: Clip.none)`, whose `LayoutBuilder` passes bar = `constraints.maxHeight − fade`, so the flat part follows the bar at every text scale; `LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0, b, for (i = 12 → 0) b + (1 − kScrimStops[i]) × f], colors: [base.withValues(alpha: 0.88), base.withValues(alpha: 0.88), for (i = 12 → 0) base.withValues(alpha: 0.88 × kScrimAlpha[i])])`, with b = bar / total, f = fade / total and `final base = tint == null ? const Color(0xFF000000) : Color.lerp(const Color(0xFF000000), tint, 0.25)!`. The reader chrome passes the `page.tint` role colour (§2.1.5) as `tint` only while page-tinted chrome is on (§9.4.4), animated by its existing `TweenAnimationBuilder<Color?>`; every other bar passes none |
| `scrim.sole` | `#000` .90 flat over the bar's laid-out height (folio bar min 64 px + bottom inset, growing at large text scales), then the 13 eased stops reversed from .90 to 0 over 64 px; bar + 64 px (min 128 px + bottom inset) | None in the `[data-skin]` block, for the reason given under `scrim.head`. The folio bar and the Listen transport set `isolation: isolate` and `--scrim-fade: 64px`. The bar is positioned so the `::before` sizes against the bar and not the page: the folio bar is `absolute` (or `fixed`) inside the reader chrome overlay; the Listen transport, which sits in normal flow under the transcript (§8.16.3), is `relative` | `@utility scrim-sole { position: absolute; inset: calc(-1 * var(--scrim-fade)) 0 0 0; z-index: -1; pointer-events: none; background-image: linear-gradient(to top, color-mix(in srgb, var(--scrim-base, #000000) 90%, transparent) 0, <for i = 12 → 0: color-mix(in srgb, var(--scrim-base, #000000) P%, transparent) calc(100% - kScrimStops[i] * var(--scrim-fade))>); }`, with P = 90 × `kScrimAlpha[i]` written as a literal; applied as `before:scrim-sole` on the bar. `--scrim-base` is the same unregistered variable as under `scrim.head` (tinted on the reader chrome root only) | `scrimSole(bar, fade, {Color? tint})` = the `scrimHead` construction flipped: painted as `Positioned(top: -fade, left: 0, right: 0, bottom: 0)`, with `begin: Alignment.bottomCenter, end: Alignment.topCenter` and `base.withValues(alpha: 0.90)` / `base.withValues(alpha: 0.90 × kScrimAlpha[i])`, `base` and `tint` as in `scrimHead` |
| `scrim.rail-end` | 48 px, `#000` 1 → 0 linear | `--mm-scrim-rail-end` (a complete `background-image` value) | `@utility scrim-rail-end { background-image: var(--mm-scrim-rail-end); }` (`scrim-rail-end`) | `scrimRailEnd` = `LinearGradient(colors: [Color(0xFF000000), Color(0x00000000)])` |
| `scrim.vignette` | `radial-gradient(120% 90% at 50% 40%, rgb(0 0 0/0) 60%, rgb(0 0 0/.45) 100%)` | `--mm-scrim-vignette` (a complete `background-image` value) | `@utility scrim-vignette { background-image: var(--mm-scrim-vignette); }` (`scrim-vignette`) | `scrimVignette` = `RadialGradient(center: Alignment(0, -0.2), radius: 1.0, stops: [.6, 1], colors: [Color(0x00000000), Color(0x73000000)], transform: const CssEllipse(rx: 1.2, ry: 0.9))` |
| `scrim.modal` | flat `rgba(0,0,0,0.78)` | `--mm-scrim-modal: rgba(0,0,0,0.78)` (a colour, used as `background-color`) | `bg-(--mm-scrim-modal)` | `scrimModal` = `Color(0xC7000000)` |

`kScrimStops` = `[0, .018, .048, .09, .139, .198, .27, .35, .435, .53, .66, .81, 1]` and `kScrimAlpha` = `[0, .002, .008, .021, .042, .075, .126, .194, .278, .382, .541, .738, 1]` (§2.1.4); the web emits the same 13 stops into each eased gradient string. `CssEllipse` is a `GradientTransform` whose `transform(bounds)` returns translate(0.5 w, 0.4 h) · scale(1.2 × w / s, 0.9 × h / s) · translate(−0.5 w, −0.4 h), with s = the shortest side; it reproduces the CSS 1.2 w × 0.9 h ellipse (a bare Flutter `RadialGradient` is a circle of radius × the shortest side).

#### 2.8.4 Motion

| Key | Value | Web CSS property | Tailwind 4 | Motion (TS) / Flutter `CineTokens` field |
|---|---|---|---|---|
| `dur.cut` | 0 ms | `--mm-dur-cut: 0ms` | `duration-(--mm-dur-cut)` | `dur.cut = 0` (s) / `durCut` = `Duration(milliseconds: 0)` |
| `dur.tick` | 80 ms | `--mm-dur-tick: 80ms` | `duration-(--mm-dur-tick)` | `dur.tick = 0.08` (s) / `durTick` = `Duration(milliseconds: 80)` |
| `dur.beat` | 160 ms | `--mm-dur-beat: 160ms` | `duration-(--mm-dur-beat)` | `dur.beat = 0.16` (s) / `durBeat` = `Duration(milliseconds: 160)` |
| `dur.line` | 240 ms | `--mm-dur-line: 240ms` | `duration-(--mm-dur-line)` | `dur.line = 0.24` (s) / `durLine` = `Duration(milliseconds: 240)` |
| `dur.column` | 320 ms | `--mm-dur-column: 320ms` | `duration-(--mm-dur-column)` | `dur.column = 0.32` (s) / `durColumn` = `Duration(milliseconds: 320)` |
| `dur.spread` | 480 ms | `--mm-dur-spread: 480ms` | `duration-(--mm-dur-spread)` | `dur.spread = 0.48` (s) / `durSpread` = `Duration(milliseconds: 480)` |
| `dur.wipe.close` | 200 ms | `--mm-dur-wipe-close: 200ms` | `duration-(--mm-dur-wipe-close)` | `dur.wipeClose = 0.2` (s) / `durWipeClose` = `Duration(milliseconds: 200)` |
| `dur.wipe.open` | 280 ms | `--mm-dur-wipe-open: 280ms` | `duration-(--mm-dur-wipe-open)` | `dur.wipeOpen = 0.28` (s) / `durWipeOpen` = `Duration(milliseconds: 280)` |
| `dur.dissolve` | 800 ms | `--mm-dur-dissolve: 800ms` | `duration-(--mm-dur-dissolve)` | `dur.dissolve = 0.8` (s) / `durDissolve` = `Duration(milliseconds: 800)` |
| `dur.reel` | 1400 ms | `--mm-dur-reel: 1400ms` | `duration-(--mm-dur-reel)` | `dur.reel = 1.4` (s) / `durReel` = `Duration(milliseconds: 1400)` |
| `dur.drift` | 26000 ms | `--mm-dur-drift: 26000ms` | `duration-(--mm-dur-drift)` | `dur.drift = 26` (s) / `durDrift` = `Duration(milliseconds: 26000)` |
| `dur.type` | 50 ms | `--mm-dur-type: 50ms` | `duration-(--mm-dur-type)` | `dur.type = 0.05` (s) / `durType` = `Duration(milliseconds: 50)` |
| `dur.caret` | 530 ms | `--mm-dur-caret: 530ms` | `duration-(--mm-dur-caret)` | `dur.caret = 0.53` (s) / `durCaret` = `Duration(milliseconds: 530)` |
| `dur.letter` | 640 ms | `--mm-dur-letter: 640ms` | `duration-(--mm-dur-letter)` | `dur.letter = 0.64` (s) / `durLetter` = `Duration(milliseconds: 640)` |
| `dur.letter.blur` | 440 ms | `--mm-dur-letter-blur: 440ms` | `duration-(--mm-dur-letter-blur)` | `dur.letterBlur = 0.44` (s) / `durLetterBlur` = `Duration(milliseconds: 440)` |
| `dur.hold.toast` | 3600 ms | `--mm-dur-hold-toast: 3600ms` | `duration-(--mm-dur-hold-toast)` | `dur.holdToast = 3.6` (s) / `durHoldToast` = `Duration(milliseconds: 3600)` |
| `dur.hold.toast.error` | 6000 ms | `--mm-dur-hold-toast-error: 6000ms` | `duration-(--mm-dur-hold-toast-error)` | `dur.holdToastError = 6` (s) / `durHoldToastError` = `Duration(milliseconds: 6000)` |
| `dur.hold.toast.action` | 8000 ms | `--mm-dur-hold-toast-action: 8000ms` | `duration-(--mm-dur-hold-toast-action)` | `dur.holdToastAction = 8` (s) / `durHoldToastAction` = `Duration(milliseconds: 8000)` |
| `dur.hold.toast.undo` | 10000 ms | `--mm-dur-hold-toast-undo: 10000ms` | `duration-(--mm-dur-hold-toast-undo)` | `dur.holdToastUndo = 10` (s) / `durHoldToastUndo` = `Duration(milliseconds: 10000)` |
| `dur.hold.rating` | 3000 ms | `--mm-dur-hold-rating: 3000ms` | `duration-(--mm-dur-hold-rating)` | `dur.holdRating = 3` (s) / `durHoldRating` = `Duration(milliseconds: 3000)` |
| `dur.dwell.preview` | 600 ms | `--mm-dur-dwell-preview: 600ms` | `duration-(--mm-dur-dwell-preview)` | `dur.dwellPreview = 0.6` (s) / `durDwellPreview` = `Duration(milliseconds: 600)` |
| `dur.dwell.backdrop` | 400 ms | `--mm-dur-dwell-backdrop: 400ms` | `duration-(--mm-dur-dwell-backdrop)` | `dur.dwellBackdrop = 0.4` (s) / `durDwellBackdrop` = `Duration(milliseconds: 400)` |
| `dur.flicker` | 1400 ms | `--mm-dur-flicker: 1400ms` | `duration-(--mm-dur-flicker)` | `dur.flicker = 1.4` (s) / `durFlicker` = `Duration(milliseconds: 1400)` |
| `dur.arm` | 1000 ms | `--mm-dur-arm: 1000ms` | `duration-(--mm-dur-arm)` | `dur.arm = 1` (s) / `durArm` = `Duration(milliseconds: 1000)` |
| `dur.countdown.recap` | 12000 ms | `--mm-dur-countdown-recap: 12000ms` | `duration-(--mm-dur-countdown-recap)` | `dur.countdownRecap = 12` (s) / `durCountdownRecap` = `Duration(milliseconds: 12000)` |
| `dur.countdown.next` | 5000 ms | `--mm-dur-countdown-next: 5000ms` | `duration-(--mm-dur-countdown-next)` | `dur.countdownNext = 5` (s) / `durCountdownNext` = `Duration(milliseconds: 5000)` |
| `dur.hold.panel.base` | 1200 ms | `--mm-dur-hold-panel-base: 1200ms` | `duration-(--mm-dur-hold-panel-base)` | `dur.holdPanelBase = 1.2` (s) / `durHoldPanelBase` = `Duration(milliseconds: 1200)` |
| `dur.hold.panel.word` | 250 ms | `--mm-dur-hold-panel-word: 250ms` | `duration-(--mm-dur-hold-panel-word)` | `dur.holdPanelWord = 0.25` (s) / `durHoldPanelWord` = `Duration(milliseconds: 250)` |
| `dur.hold.panel.cap` | 6000 ms | `--mm-dur-hold-panel-cap: 6000ms` | `duration-(--mm-dur-hold-panel-cap)` | `dur.holdPanelCap = 6` (s) / `durHoldPanelCap` = `Duration(milliseconds: 6000)` |
| `dur.sample.tint` | 600 ms | `--mm-dur-sample-tint: 600ms` | `duration-(--mm-dur-sample-tint)` | `dur.sampleTint = 0.6` (s) / `durSampleTint` = `Duration(milliseconds: 600)` |
| `dur.pageturn` | 280 ms | `--mm-dur-pageturn: 280ms` | `duration-(--mm-dur-pageturn)` | `dur.pageturn = 0.28` (s) / `durPageturn` = `Duration(milliseconds: 280)` |
| `dur.hold.dip` | 40 ms | `--mm-dur-hold-dip: 40ms` | `duration-(--mm-dur-hold-dip)` | `dur.holdDip = 0.04` (s) / `durHoldDip` = `Duration(milliseconds: 40)` |
| `dur.snap` | 120 ms | `--mm-dur-snap: 120ms` | `duration-(--mm-dur-snap)` | `dur.snap = 0.12` (s) / `durSnap` = `Duration(milliseconds: 120)` |
| `dur.reduced` | 150 ms | `--mm-dur-reduced: 150ms` | `duration-(--mm-dur-reduced)` | `dur.reduced = 0.15` (s) / `durReduced` = `Duration(milliseconds: 150)` |
| `dur.clip` | 200 ms | `--mm-dur-clip: 200ms` | `duration-(--mm-dur-clip)` | `dur.clip = 0.2` (s) / `durClip` = `Duration(milliseconds: 200)` |
| `dur.page.out` | 224 ms | `--mm-dur-page-out: 224ms` | `duration-(--mm-dur-page-out)` | `dur.pageOut = 0.224` (s) / `durPageOut` = `Duration(milliseconds: 224)` |
| `dur.dim` | 280 ms | `--mm-dur-dim: 280ms` | `duration-(--mm-dur-dim)` | `dur.dim = 0.28` (s) / `durDim` = `Duration(milliseconds: 280)` |
| `dur.tapscroll` | 300 ms | `--mm-dur-tapscroll: 300ms` | `duration-(--mm-dur-tapscroll)` | `dur.tapscroll = 0.3` (s) / `durTapscroll` = `Duration(milliseconds: 300)` |
| `dur.match.back` | 336 ms | `--mm-dur-match-back: 336ms` | `duration-(--mm-dur-match-back)` | `dur.matchBack = 0.336` (s) / `durMatchBack` = `Duration(milliseconds: 336)` |
| `dur.rise` | 360 ms | `--mm-dur-rise: 360ms` | `duration-(--mm-dur-rise)` | `dur.rise = 0.36` (s) / `durRise` = `Duration(milliseconds: 360)` |
| `dur.glide` | 400 ms | `--mm-dur-glide: 400ms` | `duration-(--mm-dur-glide)` | `dur.glide = 0.4` (s) / `durGlide` = `Duration(milliseconds: 400)` |
| `dur.stoppress` | 500 ms | `--mm-dur-stoppress: 500ms` | `duration-(--mm-dur-stoppress)` | `dur.stoppress = 0.5` (s) / `durStoppress` = `Duration(milliseconds: 500)` |
| `dur.rack` | 520 ms | `--mm-dur-rack: 520ms` | `duration-(--mm-dur-rack)` | `dur.rack = 0.52` (s) / `durRack` = `Duration(milliseconds: 520)` |
| `dur.iris.out` | 560 ms | `--mm-dur-iris-out: 560ms` | `duration-(--mm-dur-iris-out)` | `dur.irisOut = 0.56` (s) / `durIrisOut` = `Duration(milliseconds: 560)` |
| `dur.loop.rule` | 1200 ms | `--mm-dur-loop-rule: 1200ms` | `duration-(--mm-dur-loop-rule)` | `dur.loopRule = 1.2` (s) / `durLoopRule` = `Duration(milliseconds: 1200)` |
| `dur.hold.error` | 2000 ms | `--mm-dur-hold-error: 2000ms` | `duration-(--mm-dur-hold-error)` | `dur.holdError = 2` (s) / `durHoldError` = `Duration(milliseconds: 2000)` |
| `dur.flame.flicker` | 2000 ms | `--mm-dur-flame-flicker: 2000ms` | `duration-(--mm-dur-flame-flicker)` | `dur.flameFlicker = 2` (s) / `durFlameFlicker` = `Duration(milliseconds: 2000)` |
| `dur.flame.risk` | 800 ms | `--mm-dur-flame-risk: 800ms` | `duration-(--mm-dur-flame-risk)` | `dur.flameRisk = 0.8` (s) / `durFlameRisk` = `Duration(milliseconds: 800)` |
| `dur.flame.ring` | 24000 ms | `--mm-dur-flame-ring: 24000ms` | `duration-(--mm-dur-flame-ring)` | `dur.flameRing = 24` (s) / `durFlameRing` = `Duration(milliseconds: 24000)` |
| `dur.flame.spark` | 900 ms | `--mm-dur-flame-spark: 900ms` | `duration-(--mm-dur-flame-spark)` | `dur.flameSpark = 0.9` (s) / `durFlameSpark` = `Duration(milliseconds: 900)` |
| `dur.fade.first` | 100 ms | `--mm-dur-fade-first: 100ms` | `duration-(--mm-dur-fade-first)` | `dur.fadeFirst = 0.1` (s) / `durFadeFirst` = `Duration(milliseconds: 100)` |
| `dur.fade.cut` | 250 ms | `--mm-dur-fade-cut: 250ms` | `duration-(--mm-dur-fade-cut)` | `dur.fadeCut = 0.25` (s) / `durFadeCut` = `Duration(milliseconds: 250)` |
| `dur.fade.hint` | 1000 ms | `--mm-dur-fade-hint: 1000ms` | `duration-(--mm-dur-fade-hint)` | `dur.fadeHint = 1` (s) / `durFadeHint` = `Duration(milliseconds: 1000)` |
| `dur.hold.glance` | 1500 ms | `--mm-dur-hold-glance: 1500ms` | `duration-(--mm-dur-hold-glance)` | `dur.holdGlance = 1.5` (s) / `durHoldGlance` = `Duration(milliseconds: 1500)` |
| `dur.leader` | 1000 ms | `--mm-dur-leader: 1000ms` | `duration-(--mm-dur-leader)` | `dur.leader = 1` (s) / `durLeader` = `Duration(milliseconds: 1000)` |
| `dur.hold.success` | 1600 ms | `--mm-dur-hold-success: 1600ms` | `duration-(--mm-dur-hold-success)` | `dur.holdSuccess = 1.6` (s) / `durHoldSuccess` = `Duration(milliseconds: 1600)` |
| `dur.hold.connected` | 400 ms | `--mm-dur-hold-connected: 400ms` | `duration-(--mm-dur-hold-connected)` | `dur.holdConnected = 0.4` (s) / `durHoldConnected` = `Duration(milliseconds: 400)` |
| `dur.hold.chip` | 1200 ms | `--mm-dur-hold-chip: 1200ms` | `duration-(--mm-dur-hold-chip)` | `dur.holdChip = 1.2` (s) / `durHoldChip` = `Duration(milliseconds: 1200)` |
| `dur.hold.flash` | 1200 ms | `--mm-dur-hold-flash: 1200ms` | `duration-(--mm-dur-hold-flash)` | `dur.holdFlash = 1.2` (s) / `durHoldFlash` = `Duration(milliseconds: 1200)` |
| `dur.hold.brief` | 2000 ms | `--mm-dur-hold-brief: 2000ms` | `duration-(--mm-dur-hold-brief)` | `dur.holdBrief = 2` (s) / `durHoldBrief` = `Duration(milliseconds: 2000)` |
| `dur.hold.edition` | 4000 ms | `--mm-dur-hold-edition: 4000ms` | `duration-(--mm-dur-hold-edition)` | `dur.holdEdition = 4` (s) / `durHoldEdition` = `Duration(milliseconds: 4000)` |
| `dur.hold.annual.page` | 6000 ms | `--mm-dur-hold-annual-page: 6000ms` | `duration-(--mm-dur-hold-annual-page)` | `dur.holdAnnualPage = 6` (s) / `durHoldAnnualPage` = `Duration(milliseconds: 6000)` |
| `dur.hold.annual.list` | 8000 ms | `--mm-dur-hold-annual-list: 8000ms` | `duration-(--mm-dur-hold-annual-list)` | `dur.holdAnnualList = 8` (s) / `durHoldAnnualList` = `Duration(milliseconds: 8000)` |
| `dur.roll.colophon` | 10000 ms | `--mm-dur-roll-colophon: 10000ms` | `duration-(--mm-dur-roll-colophon)` | `dur.rollColophon = 10` (s) / `durRollColophon` = `Duration(milliseconds: 10000)` |
| `dur.loop.preview` | 12000 ms | `--mm-dur-loop-preview: 12000ms` | `duration-(--mm-dur-loop-preview)` | `dur.loopPreview = 12` (s) / `durLoopPreview` = `Duration(milliseconds: 12000)` (web only: the web edition preview's self-scroll; the field is generated like every key, but the app's preview is a bundled frame loop whose length its frames fix, §8.30.3) |
| `ease.settle` | `cubic-bezier(0.16, 1, 0.3, 1)` | `--mm-ease-settle: cubic-bezier(0.16, 1, 0.3, 1)` | `--ease-settle` (`ease-settle`) | `ease.settle = [0.16, 1, 0.3, 1]` / `easeSettle` = `Cubic(0.16, 1, 0.3, 1)` |
| `ease.lift` | `cubic-bezier(0.7, 0, 0.84, 0)` | `--mm-ease-lift: cubic-bezier(0.7, 0, 0.84, 0)` | `--ease-lift` (`ease-lift`) | `ease.lift = [0.7, 0, 0.84, 0]` / `easeLift` = `Cubic(0.7, 0, 0.84, 0)` |
| `ease.turn` | `cubic-bezier(0.65, 0, 0.35, 1)` | `--mm-ease-turn: cubic-bezier(0.65, 0, 0.35, 1)` | `--ease-turn` (`ease-turn`) | `ease.turn = [0.65, 0, 0.35, 1]` / `easeTurn` = `Cubic(0.65, 0, 0.35, 1)` |
| `ease.set` | `cubic-bezier(0.2, 0, 0, 1)` | `--mm-ease-set: cubic-bezier(0.2, 0, 0, 1)` | `--ease-set` (`ease-set`) | `ease.set = [0.2, 0, 0, 1]` / `easeSet` = `Cubic(0.2, 0, 0, 1)` |
| `ease.drift` | `cubic-bezier(0.37, 0, 0.63, 1)` | `--mm-ease-drift: cubic-bezier(0.37, 0, 0.63, 1)` | `--ease-drift` (`ease-drift`) | `ease.drift = [0.37, 0, 0.63, 1]` / `easeDrift` = `Cubic(0.37, 0, 0.63, 1)` |
| `ease.scroll` | `cubic-bezier(0.5, 1, 0.89, 1)` | `--mm-ease-scroll: cubic-bezier(0.5, 1, 0.89, 1)` | `--ease-scroll` (`ease-scroll`) | `ease.scroll = [0.5, 1, 0.89, 1]` / `easeScroll` = `Cubic(0.5, 1, 0.89, 1)` |
| `ease.linear` | `linear` | `--mm-ease-linear: linear` | `ease-linear` (built in) | `"linear"` / `easeLinear` = `Curves.linear` |
| `spring.release` | 420 ms, bounce 0 | `--mm-spring-release: linear(…)` generated by `design/build.mjs` (the stdlib port of Motion's spring, below; equal to `spring(0.42, 0)`), plus `--mm-spring-release-ms: 800ms` (the settle time, not the visual duration) | `--ease-spring-release` (`ease-spring-release` with `duration-(--mm-spring-release-ms)`) | `{ type: "spring", visualDuration: 0.42, bounce: 0 }` / `springRelease` = `SpringToken(ms: 420, bounce: 0)` → `SpringDescription.withDurationAndBounce(duration: Duration(milliseconds: 504), bounce: 0)` (420 × 1.2) |
| `spring.sheet` | 480 ms, bounce 0 | `--mm-spring-sheet: linear(…)` generated by `design/build.mjs` (the stdlib port of Motion's spring, below; equal to `spring(0.48, 0)`), plus `--mm-spring-sheet-ms: 850ms` (the settle time, not the visual duration) | `--ease-spring-sheet` (`ease-spring-sheet` with `duration-(--mm-spring-sheet-ms)`) | `{ type: "spring", visualDuration: 0.48, bounce: 0 }` / `springSheet` = `SpringToken(ms: 480, bounce: 0)` → `SpringDescription.withDurationAndBounce(duration: Duration(milliseconds: 576), bounce: 0)` (480 × 1.2) |
| `spring.scrub` | 240 ms, bounce 0 | `--mm-spring-scrub: linear(…)` generated by `design/build.mjs` (the stdlib port of Motion's spring, below; equal to `spring(0.24, 0)`), plus `--mm-spring-scrub-ms: 500ms` (the settle time, not the visual duration) | `--ease-spring-scrub` (`ease-spring-scrub` with `duration-(--mm-spring-scrub-ms)`) | `{ type: "spring", visualDuration: 0.24, bounce: 0 }` / `springScrub` = `SpringToken(ms: 240, bounce: 0)` → `SpringDescription.withDurationAndBounce(duration: Duration(milliseconds: 288), bounce: 0)` (240 × 1.2) |
| `scalar.stagger.grid` | { item: 32, row: 64, cap: 480 } (ms) | none (TypeScript only) | n/a | `scalar.staggerGrid = { item: 32, row: 64, cap: 480 }` / `scalarStaggerGrid` = `MotionStagger(item: 32, row: 64, cap: 480)` |
| `scalar.stagger.list` | { item: 24, cap: 360 } (ms) | none (TypeScript only) | n/a | `scalar.staggerList = { item: 24, cap: 360 }` / `scalarStaggerList` = `MotionStagger(item: 24, cap: 360)` |
| `scalar.stagger.letter` | { item: 24, cap: 560, startDelay: 120 } (ms) | none (TypeScript only) | n/a | `scalar.staggerLetter = { item: 24, cap: 560, startDelay: 120 }` / `scalarStaggerLetter` = `MotionStagger(item: 24, cap: 560, startDelay: 120)` |
| `scalar.stagger.word` | { item: 30, fade: 160 } (ms) | none (TypeScript only) | n/a | `scalar.staggerWord = { item: 30, fade: 160 }` / `scalarStaggerWord` = `MotionStagger(item: 30, fade: 160)` |
| `scalar.stagger.fly` | { item: 60 } (ms) | none (TypeScript only) | n/a | `scalar.staggerFly = { item: 60 }` / `scalarStaggerFly` = `MotionStagger(item: 60)` |
| `scalar.letter.rise` | 0.42 em | none (TypeScript only) | n/a | `scalar.letterRise = 0.42 (em)` / `scalarLetterRise` = `0.42` (multiplied by the font size in Dart, §10.1.6) |
| `scalar.rubber` | c = 0.35 (unitless) | none (TypeScript only) | n/a | `scalar.rubber = 0.35` / `scalarRubber` = `0.35` |
| `scalar.pace.top` / `.words` / `.min` / `.max` | 1.2 / 60 / 0.5 / 1.0 (unitless; §9.4.1 pace by dialogue) | none (TypeScript only) | n/a | `scalar.paceTop` … / `scalarPaceTop` = `1.2`, `scalarPaceWords` = `60`, `scalarPaceMin` = `0.5`, `scalarPaceMax` = `1.0` |

`scalar.*` is a token kind added to `stack-decision.md` §2.1 by this contract (§15.10): `{ "value": n, "unit": "ms" | "em" | "px" | "" }`, or an object of such values for a stagger. It carries numbers that are neither a spring nor a curve.

**Springs on each client** (§15.10 S13). A spring token `{ms, bounce}` means the same motion everywhere:
- *Motion (JS):* `{ type: "spring", visualDuration: ms / 1000, bounce }`, unchanged.
- *Flutter:* `SpringDescription.withDurationAndBounce(duration: Duration(milliseconds: (ms * 1.2).round()), bounce: bounce)`. Motion derives stiffness from ω = 2π / (1.2 · visualDuration) while Flutter uses ω = 2π / duration, so the × 1.2 makes stiffness match exactly, and damping matches for 0 ≤ bounce < 0.95. Today: `springRelease` 504 ms, `springSheet` 576 ms, `springScrub` 288 ms. The `static const` members of `CineSprings` (§2.8) are the `const SpringToken`s, named by the key without its `spring.` group (`CineSprings.release`, `.sheet`, `.scrub`, the same values as the `springRelease` / `springSheet` / `springScrub` fields); `SpringToken.description` is a getter that builds the `SpringDescription` above at run time, because `withDurationAndBounce` is a `factory` (Flutter 3.44.6 `spring_simulation.dart` l.70) and cannot initialise a `const`.
- *CSS:* the pair is **curve + settle time**. `design/build.mjs` ports Motion's spring generator with Node stdlib only (about 30 lines; it cannot import `motion`): stiffness k = (2π / (1.2 · ms / 1000))², damping ratio ζ = clamp(0.05, 1, 1 − bounce), mass 1; the critically damped branch x(t) = 1 − (1 + ωt)·e^(−ωt) plus the underdamped branch Glass needs; it steps t in 50 ms increments until |1 − x| ≤ 0.005 and |v| ≤ 0.01 (motion-dom's "granular" rest thresholds), which gives the settle time T; it emits `linear()` with round(T / 30) samples of x(i · T / (n − 1)), each rounded to 4 decimals (Motion's `generateLinearEasing` at its 30 ms `toString` resolution). `--mm-spring-{release,sheet,scrub}` is that curve and `--mm-spring-*-ms` is **T**: 800 ms, 850 ms and 500 ms for today's tokens. Motion JS and Flutter keep the visual duration.
- *Test:* a Vitest case in `frontend/src/skins/cinematic/tokens.test.ts` asserts that for each spring token `` `${T}ms ${curve}` `` equals `spring(ms / 1000, bounce).toString()` from the installed `motion` (today `"800ms linear(0, 0.0572, 0.1795, …)"` for release), so a Motion upgrade that changes the curve fails CI instead of drifting.

## 3. Type scale

### 3.1 Families (all from Google Fonts, all SIL Open Font License 1.1)

| Role | Family | Axes and styles used | Designer | Why |
|---|---|---|---|---|
| **Display**: covers, mastheads, headlines, section heads (H3), numerals, pull quotes, drop caps | **Bodoni Moda** | `opsz` 6–96 (set = size, capped at 96), `wght` 500–900, Roman + Italic | Owen Earl (indestructible type\*) | A Didone with an optical-size axis, so hairlines stay intact at 24 px and turn razor-thin at 120 px. High contrast on AMOLED is the "film magazine" look. The un-blur of the letter reveal shows its hairlines arriving last. |
| **Grotesk**: UI, buttons, labels, nav, kickers, credits | **Archivo** | `wdth` 62–125 (used 62–100), `wght` 100–900 (used 450–700), Roman | Omnibus-Type | One variable file covers credits (condensed caps at `wdth` 62–75) and legible UI text (`wdth` 100). |
| **Text**: decks, synopsis, recaps, notices, novel body (default of five reading faces, §3.4) | **Newsreader** | `opsz` 6–72 (set = size), `wght` 380–600, Roman + Italic | Production Type | Designed for long reading on screens; the italic carries pull quotes and captions. |
| **Folio**: chapter numbers, pages, timecodes, counts, sizes, keycaps | **IBM Plex Mono** | 400, 500, 600 (static) | Mike Abbink, Bold Monday | Tabular by nature; reads like a projectionist's counter or a page folio. |
| CJK fallback (alternate titles) | **Noto Serif KR / JP / SC** for display, **Noto Sans KR / JP / SC** for UI | `wght` | Google | Web only (`preload: false`); Flutter uses the system CJK faces. CJK display titles drop italic and tracking and render at `wght` 700 one size down. |

Delivery. Web: `next/font/google` (`Bodoni_Moda({ subsets: ["latin", "latin-ext"], axes: ["opsz"], style: ["normal", "italic"], display: "block", preload: true, variable: "--mm-font-display" })`, `Archivo({ subsets: ["latin", "latin-ext"], axes: ["wdth"], display: "swap", variable: "--mm-font-grotesk" })`, `Newsreader({ subsets: ["latin", "latin-ext"], axes: ["opsz"], style: ["normal", "italic"], display: "swap", variable: "--mm-font-newsreader" })`, `IBM_Plex_Mono({ subsets: ["latin", "latin-ext"], weight: ["400", "500", "600"], display: "swap", variable: "--mm-font-folio" })`, each face's class on `<html>`; the skin block maps the text roles' family `--mm-font-text: var(--mm-font-newsreader)`, which Hyperlegible text redefines (§3.4); `subsets` is required because `preload` defaults to `true`; the three extra reading faces are in §3.4 and, like the Noto fallbacks, are `preload: false` and need no subsets; all four are present in next 16.2.9's `font-data.json`). Bodoni Moda uses `display: "block"` because a swap in the middle of a letter reveal breaks it. Flutter: bundle the variable TTFs from `github.com/google/fonts/tree/main/ofl/{bodonimoda,archivo,newsreader,ibmplexmono}` as assets, set both `fontWeight` and `FontVariation('wght', …)`, and pass `FontVariation('opsz', min(size, 96))` for Bodoni Moda and Newsreader and `FontVariation('wdth', …)` for Archivo. Ship each `OFL.txt` through `LicenseRegistry.addLicense`.

Global type rules:
- Figures: `lnum` (lining) in headlines and numerals, `onum` (old-style) inside Newsreader running text, `tnum` on every number that updates in place (Plex Mono is already tabular).
- Revealed headings set `font-kerning: none` (Flutter `FontFeature.disable('kern')`) so split and unsplit text measure identically.
- Headlines and decks use `text-wrap: balance`; body uses `text-wrap: pretty` (web). Flutter uses `TextWidthBasis.longestLine` plus a column max width.
- Headline titles are **sentence case, never all caps**. Caps belong to kickers, credits, nav and badges (Archivo), so a screen always shows one serif voice and one caps voice.
- Long series titles in `cover`: > 24 graphemes step down one role (`masthead` size), > 40 graphemes step down two (`headline` size).
- **OS bold text** (app). Every role sets `FontVariation('wght', …)`, which decides the rendered weight, so Flutter's own `FontWeight.bold` merge would do nothing. When `MediaQuery.boldTextOf(context)` is true (iOS Bold Text, Android bold text), `CineType` adds 120 to every role's `wght` variation (the same step as the novel reader's Bold text switch, 400 → 520, §8.15.5), clamped to each face's axis maximum (Bodoni Moda, Archivo, Literata and Source Serif 4: 900; Newsreader and Atkinson Hyperlegible Next: 800), and sets `fontWeight` to the nearest hundred; IBM Plex Mono switches to its 600 static. The web has no equivalent media query and follows the browser.

### 3.2 Scale per breakpoint

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
| `type.credit` | Archivo, wdth 70; value wght 700 `ink.100` (`type.credit`), label wght 500 `ink.45` (`type.credit.label`) | 12/16 | 12/16 | 12/16 | 13/16 | +0.08em | UPPER |
| `type.nav` | Archivo, wdth 75, wght 600 | 10/12 (tab bar) | 12/16 | 13/16 | 13/16 | +0.12em | UPPER |
| `type.caption` | Archivo, wdth 90, wght 450 | 13/16 | 13/16 | 13/16 | 13/16 | +0.005em | Sentence |
| `type.folio` | IBM Plex Mono 500 | 12/16 | 12/16 | 12/16 | 13/16 | +0.02em | as data |
| `type.folio.lg` | IBM Plex Mono 500 | 15/20 | 15/20 | 15/20 | 16/20 | 0 | as data |
| `type.micro` (badges) | Archivo, wdth 62, wght 700 | 10/12 | 10/12 | 10/12 | 11/12 | +0.12em | UPPER |
| `type.dropcap` | Bodoni Moda Roman, wght 800, opsz = min(size, 96) | size = 3 × the line height of the paragraph it opens (e.g. 72 px on 24 px leading, 96 px on the recap's 32 px) | same | same (e.g. 84 px on 28 px) | same | −0.02em | n/a |

Web formulas for the fluid display roles (interpolating phone → wide between 375 px and 1600 px viewports): `cover: clamp(2.75rem, 1.296rem + 6.2vw, 7.5rem)`, `masthead: clamp(2.5rem, 1.582rem + 3.92vw, 5.5rem)`, `headline: clamp(2rem, 1.39rem + 2.61vw, 4rem)`, `section: clamp(1.5rem, 1.27rem + 0.98vw, 2.25rem)`, `numeral: clamp(3.5rem, 2.276rem + 5.22vw, 7.5rem)`. Flutter uses the table's per-breakpoint values; the web interpolates between the phone and wide values. Fluid roles keep their `clamp()` sizes; `--mm-type-<role>-lh` is a unitless ratio redefined in each breakpoint media query from the table:

| Role | phone | tablet | desktop | wide |
|---|---|---|---|---|
| cover | 1.0 | 0.9375 | 0.955 | 0.933 |
| masthead | 1.0 | 1.0 | 0.944 | 0.955 |
| headline | 1.125 | 1.091 | 1.0 | 1.0 |
| section | 1.167 | 1.143 | 1.125 | 1.111 |
| numeral | 1.0 | 1.0 | 0.917 | 0.933 |

Their blocks keep the 4 px rhythm through the `Measure` wrapper (§7.28), which rounds a display block's rendered height up to the next multiple of 4 px with a bottom margin, so the text after it lands back on the baseline.

All other sizes are authored in `rem` (px / 16) so the browser's font-size preference scales UI text.

### 3.3 Mobile text scale (iOS Dynamic Type, Android font scale)

Flutter reads `MediaQuery.textScalerOf(context)` (Dynamic Type on iOS; the non-linear font scale on Android 14+). Each role clamps it with `TextScaler.clamp(maxScaleFactor: cap)`. Wherever this contract compares "the scale" with a number (≥ 1.3, ≥ 1.5, ≥ 2.0), the scale factor is `MediaQuery.textScalerOf(context).scale(16) / 16`, which stays defined under Android 14's non-linear scaler:

| Role group | Cap | Example at 1.0 → 1.3 → 2.0 (system) |
|---|---|---|
| Display: `cover`, `masthead`, `headline`, `numeral` | 1.15 | cover 44 → 50.6 → 50.6 px |
| `section`, `subhead`, `pull`, `field` | 1.30 | section 24 → 31.2 → 31.2 px |
| Reading and UI: `deck`, `body`, `title`, `ui`, `label`, `caption`, `folio`, `folio.lg` | 2.00 | body 16 → 20.8 → 32 px; caption 13 → 16.9 → 26 px |
| Caps that label or carry content: `kicker`, `credit`, `credit.label` | 2.00 | kicker 11 → 14.3 → 22 px, so a form label (§7.3) keeps pace with its 32 px field text at 2.0; at ≥ 1.3 these switch from `wdth` 62–70 to `wdth` 100 so wide caps stay legible, and credits blocks are already single-column there |
| Caps in fixed cells: `nav`, `micro` | 1.50 | micro 10 → 13 → 15 px (poster badges, whose width the poster fixes and each of which has an accessible name; the tab bar); at ≥ 1.3 these switch from `wdth` 62–75 to `wdth` 100, except the fixed-cell labels below |

Layout reflow by scale factor (all platforms, web included via the root font size):
- ≥ 1.3: rails show 2.3 posters on phones instead of 3.2; poster captions allow 2 lines; credits blocks become a single column; list rows grow to their content height (min 56).
- ≥ 1.5: split buttons (§7.1) stack label over folio (label line + folio line + 2 × 8 px, min 64); the thumb index keeps its 24 px icons and its labels (capped at 1.3, below), so the bar stays 56 + bottom inset (icon 24 + gap 4 + label line 16 = 44); the reader folio bar moves the time-left caption to a second line and grows by that line's height.
- ≥ 2.0: sheets open at the full detent; two-column settings rows become one column.
- The novel body renders with `TextScaler.noScaling`; its Size is absolute, 14–40 px. A book with no stored size opens at `clamp(round(MediaQuery.textScalerOf(context).scale(d)), 14, 40)` for the face's default size `d` (§3.4, §8.15.5), so a user at system 2.0 starts at 36 px in Newsreader (34 px in Archivo), and the value is stored per book once changed (§8.15.5). The reader chrome follows the normal role caps.

**Labels in fixed cells.** The thumb-index labels (§7.14) and the feature page's labelled icon row (§8.17) are exceptions to the 1.3 switch to `wdth` 100: they keep `wdth` 62 at every scale, cap the scale at 1.3 (13/16 px), take tracking +0.06em at 1.3 and above, and render with `maxLines: 1` inside `FittedBox(fit: BoxFit.scaleDown)` as a guard, never below 10 px. "FAVOURITE" at 13 px `wdth` 62 is about 56 px, which fits the roughly 62 px cell of a 375 pt phone.

**Heights are minimums.** Every fixed height in §7–§9 is a minimum: a control's height is max(token, the scaled line height of its text + 2 × 12 px). The running head is min 44 (48 on Android) and grows to title line + 2 × 12; the folio bar is min 64 and grows by the height of its second caption line; a stacked split button is label line + folio line + 2 × 8 px, min 64.

**Literal sizes.** Any size in §7–§9 given as a literal face and size rather than a role (slug-line labels, superscript counts and badges, poster title cards, book-list titles and blurbs, novel contents rows, voice names, the Listen transcript, dialogue subtitles and transcripts, the onboarding paragraph, and the like) takes the cap of its face's role group, applied by `CineType.literal(face, size, line)`, so no new roles are needed:
- Bodoni Moda literals: 1.30, like `section`;
- Newsreader and the other reading-face literals: 2.0, like `body`;
- Archivo uppercase literals: 1.5, like `nav` and `micro` (`wdth` stays as written, except that slug labels switch to `wdth` 100 at 1.3 and above like the caps roles);
- Archivo sentence-case literals: 2.0;
- Plex Mono literals: 2.0, like `folio`.

Exceptions: superscript counts and count badges cap at 1.3, and the badge box grows from min 16 to the scaled line height; subtitles laid over dialogue stills (§8.24) cap at 1.3 and never exceed two lines.

Web desktop honours browser zoom; nothing uses `vw` for non-display text.

### 3.4 Novel reading faces and the hyperlegible option

The novel reader offers five faces (Apple Books and Kindle offer a comparable handful). Each is set in the Type sheet (§8.15.5) and stored per book (web K44 / mobile K25, widened from two values to five).

| Face (stored value) | Family | Axes used | Default size / leading | Character | Web delivery | Flutter asset |
|---|---|---|---|---|---|---|
| `newsreader` (default; migrates `serif`) | Newsreader | `opsz` = size (6–72), `wght` 380–600, Roman + Italic | 19 / 1.60 desktop, 18 / 1.60 phone | The skin's own text serif: screen-drawn, calm | already loaded (`var(--mm-font-newsreader)`, used directly and never through `--mm-font-text`, so Hyperlegible text never changes it) | `Newsreader[opsz,wght].ttf` + Italic |
| `literata` | Literata | `opsz` = size (7–72), `wght` 300–700, Roman + Italic | same | A book serif designed for e-readers (Google Play Books); slightly wider and warmer | `Literata({ axes: ["opsz"], style: ["normal","italic"], display: "swap", preload: false, variable: "--mm-font-literata" })` | `Literata[opsz,wght].ttf` + Italic |
| `source-serif` | Source Serif 4 | `opsz` = size (8–60), `wght` 300–700, Roman + Italic | same | A sturdier transitional serif; holds up at small sizes and with Bold text on | `Source_Serif_4({ axes: ["opsz"], style: ["normal","italic"], display: "swap", preload: false, variable: "--mm-font-source-serif" })` | `SourceSerif4[opsz,wght].ttf` + Italic |
| `atkinson` | Atkinson Hyperlegible Next | `wght` 200–800, Roman + Italic | 19 / 1.70 desktop, 18 / 1.70 phone | Designed by the Braille Institute for low-vision readers: distinct letterforms (I l 1, O 0) | `Atkinson_Hyperlegible_Next({ style: ["normal","italic"], display: "swap", preload: false, variable: "--mm-font-atkinson" })` | `AtkinsonHyperlegibleNext[wght].ttf` + Italic |
| `archivo` (migrates `sans`) | Archivo | `wdth` 100, `wght` 400 | 18 / 1.60 desktop, 17 / 1.60 phone | The skin's grotesk as a reading sans | already loaded (`--mm-font-grotesk`) | already bundled |

All four Google families are present in next 16.2.9's `font-data.json` (checked: Literata `opsz` 7–72, Source Serif 4 `opsz` 8–60, Atkinson Hyperlegible Next `wght` 200–800). The three extra web faces load only when the novel reader mounts (`preload: false`, and the reader's layout imports them), so no other screen pays for them. Flutter bundles all five (≈ 1.9 MB of TTFs added for Literata, Source Serif 4 and Atkinson) with their `OFL.txt` registered in `LicenseRegistry`. Bold text (§8.15.5) adds 120 to `wght` on every face.

**Hyperlegible option.** Settings → Appearance → "Hyperlegible text" (switch, default off, per profile). When on: `type.deck`, `type.body` and `type.body.italic` render in Atkinson Hyperlegible Next (wght 400, italic 400) at the same sizes with line height +4 px, everywhere in the app (decks, synopses, recaps, notices, dialogue-search transcripts); the novel reader's default face for books without their own choice becomes `atkinson`. Display (Bodoni Moda), grotesk (Archivo) and folio (Plex Mono) roles do not change, so the skin keeps its voice. Web: the switch sets `data-legible="on"` on `<html>`. The skin block emits `--mm-font-text: var(--mm-font-newsreader)`, and the generated CSS redefines only `--mm-font-text: var(--mm-font-atkinson)` under `html[data-legible="on"][data-skin="cinematic"]` (which outranks the skin block), together with the line heights per breakpoint media query (phone / tablet / desktop / wide): `--mm-type-deck-lh` 28 / 32 / 32 / 36 px, and `--mm-type-body-lh` and `--mm-type-body-italic-lh` 28 / 28 / 32 / 32 px (§3.5 +4). The novel reader's `newsreader` face and the Type sheet's `Newsreader` tile use `var(--mm-font-newsreader)` directly, so a book stored as `newsreader` stays in Newsreader. Atkinson then loads on every screen. The server cannot stamp it (at SSR it knows only the `mm-skin` cookie, never a profile), so it is stamped before first paint by `features/preferences/appearance-boot-source.ts` (the inline `<head>` script the stack keeps for reader preferences), from the remembered active profile's scoped `localStorage` entry `mm.boot.a11y` (`{legible, motion}`, rewritten whenever the profile loads or either setting changes). With no entry (a new device, cleared storage, or no profile chosen yet) the page paints with Hyperlegible off; when the profile arrives with it on, the attribute is set and the text faces swap in place (Atkinson loads with `display: swap`), with no animation and nothing re-played. Flutter: when `legibleTextProvider` is true, `CineType` swaps the family of `type.deck`, `type.body` and `type.body.italic` only and adds 4.0 to each `lines` entry of those three roles; the novel face `newsreader` always uses the `Newsreader` asset family.

### 3.5 Type-role name map: web, Tailwind and Flutter side by side

Each role is emitted three ways from `design/tokens/cinematic.json`. **Web CSS**: `--mm-type-<role>-size`, `--mm-type-<role>-lh` (both redefined per breakpoint media query; a fluid role's size is instead one `clamp()` and its line height a unitless ratio per breakpoint, §3.2) and `--mm-type-<role>-tracking`. **Tailwind 4**: `@theme inline { --text-<role>: var(--mm-type-<role>-size); --text-<role>--line-height: var(--mm-type-<role>-lh); --text-<role>--letter-spacing: <tracking>; --text-<role>--font-weight: <wght>; }` plus a generated `@utility type-<role>` that adds the family (`var(--mm-font-<face>)`), style, `font-variation-settings`, `text-transform` and `font-kerning`, so markup writes one class: `class="type-section"`. **Flutter**: the `CineTokens` field `type<Role>` is a `CineTextRole` holding the four breakpoint sizes, the line heights, tracking in em, the family, the `FontVariation`s and the scaler cap; `CineType.of(context).section` resolves it to a `TextStyle` for the current breakpoint with `TextScaler.clamp(maxScaleFactor: cap)` applied.

| Key | Face and settings | Phone · tablet · desktop · wide (px size/line) | Tracking | Web CSS | Tailwind 4 | Flutter `CineTokens` field |
|---|---|---|---|---|---|---|
| `type.cover` | BodoniModa, opsz 96, wght 700 | 44/44 · 64/60 · 88/84 · 120/112 | -0.040 em | `--mm-type-cover-size` = `clamp(2.75rem, 1.296rem + 6.2vw, 7.5rem)`, `--mm-type-cover-lh` (unitless, per breakpoint: 1.0 · 0.9375 · 0.955 · 0.933), `--mm-type-cover-tracking: -0.040em` | `--text-cover` + `type-cover` | `typeCover` = `CineTextRole(family: 'BodoniModa', italic: false, wght: 700, axes: {'opsz': 96}, sizes: [44, 64, 88, 120], lines: [44, 60, 84, 112], trackingEm: -0.04, cap: 1.15)` |
| `type.masthead` | BodoniModa, opsz 96, wght 800 | 40/40 · 56/56 · 72/68 · 88/84 | -0.035 em | `--mm-type-masthead-size` = `clamp(2.5rem, 1.582rem + 3.92vw, 5.5rem)`, `--mm-type-masthead-lh` (unitless, per breakpoint: 1.0 · 1.0 · 0.944 · 0.955), `--mm-type-masthead-tracking: -0.035em` | `--text-masthead` + `type-masthead` | `typeMasthead` = `CineTextRole(family: 'BodoniModa', italic: false, wght: 800, axes: {'opsz': 96}, sizes: [40, 56, 72, 88], lines: [40, 56, 68, 84], trackingEm: -0.035, cap: 1.15)` |
| `type.headline` | BodoniModa, opsz 72, wght 700 | 32/36 · 44/48 · 56/56 · 64/64 | -0.030 em | `--mm-type-headline-size` = `clamp(2rem, 1.39rem + 2.61vw, 4rem)`, `--mm-type-headline-lh` (unitless, per breakpoint: 1.125 · 1.091 · 1.0 · 1.0), `--mm-type-headline-tracking: -0.030em` | `--text-headline` + `type-headline` | `typeHeadline` = `CineTextRole(family: 'BodoniModa', italic: false, wght: 700, axes: {'opsz': 72}, sizes: [32, 44, 56, 64], lines: [36, 48, 56, 64], trackingEm: -0.03, cap: 1.15)` |
| `type.section` | BodoniModa Italic, opsz 48, wght 600 | 24/28 · 28/32 · 32/36 · 36/40 | -0.020 em | `--mm-type-section-size` = `clamp(1.5rem, 1.27rem + 0.98vw, 2.25rem)`, `--mm-type-section-lh` (unitless, per breakpoint: 1.167 · 1.143 · 1.125 · 1.111), `--mm-type-section-tracking: -0.020em` | `--text-section` + `type-section` | `typeSection` = `CineTextRole(family: 'BodoniModa', italic: true, wght: 600, axes: {'opsz': 48}, sizes: [24, 28, 32, 36], lines: [28, 32, 36, 40], trackingEm: -0.02, cap: 1.3)` |
| `type.subhead` | BodoniModa, opsz 28, wght 600 | 20/24 · 22/28 · 24/28 · 24/28 | -0.010 em | `--mm-type-subhead-size`, `--mm-type-subhead-lh`, `--mm-type-subhead-tracking: -0.010em` | `--text-subhead` + `type-subhead` | `typeSubhead` = `CineTextRole(family: 'BodoniModa', italic: false, wght: 600, axes: {'opsz': 28}, sizes: [20, 22, 24, 24], lines: [24, 28, 28, 28], trackingEm: -0.01, cap: 1.3)` |
| `type.numeral` | BodoniModa, opsz 96, wght 900 | 56/56 · 72/72 · 96/88 · 120/112 | -0.030 em | `--mm-type-numeral-size` = `clamp(3.5rem, 2.276rem + 5.22vw, 7.5rem)`, `--mm-type-numeral-lh` (unitless, per breakpoint: 1.0 · 1.0 · 0.917 · 0.933), `--mm-type-numeral-tracking: -0.030em` | `--text-numeral` + `type-numeral` | `typeNumeral` = `CineTextRole(family: 'BodoniModa', italic: false, wght: 900, axes: {'opsz': 96}, sizes: [56, 72, 96, 120], lines: [56, 72, 88, 112], trackingEm: -0.03, cap: 1.15)` |
| `type.pull` | BodoniModa Italic, opsz 72, wght 500 | 24/32 · 28/36 · 36/44 · 40/48 | -0.015 em | `--mm-type-pull-size`, `--mm-type-pull-lh`, `--mm-type-pull-tracking: -0.015em` | `--text-pull` + `type-pull` | `typePull` = `CineTextRole(family: 'BodoniModa', italic: true, wght: 500, axes: {'opsz': 72}, sizes: [24, 28, 36, 40], lines: [32, 36, 44, 48], trackingEm: -0.015, cap: 1.3)` |
| `type.field` | BodoniModa Italic, opsz 48, wght 500 | 28/36 · 32/40 · 36/44 · 40/48 | -0.015 em | `--mm-type-field-size`, `--mm-type-field-lh`, `--mm-type-field-tracking: -0.015em` | `--text-field` + `type-field` | `typeField` = `CineTextRole(family: 'BodoniModa', italic: true, wght: 500, axes: {'opsz': 48}, sizes: [28, 32, 36, 40], lines: [36, 40, 44, 48], trackingEm: -0.015, cap: 1.3)` |
| `type.deck` | Newsreader, opsz 20, wght 400 | 17/24 · 18/28 · 20/28 · 22/32 | 0 | `--mm-type-deck-size`, `--mm-type-deck-lh`, `--mm-type-deck-tracking: 0em` | `--text-deck` + `type-deck` | `typeDeck` = `CineTextRole(family: 'Newsreader', italic: false, wght: 400, axes: {'opsz': 20}, sizes: [17, 18, 20, 22], lines: [24, 28, 28, 32], trackingEm: 0, cap: 2.0)` |
| `type.body` | Newsreader, opsz 16, wght 400 | 16/24 · 16/24 · 17/28 · 17/28 | 0 | `--mm-type-body-size`, `--mm-type-body-lh`, `--mm-type-body-tracking: 0em` | `--text-body` + `type-body` | `typeBody` = `CineTextRole(family: 'Newsreader', italic: false, wght: 400, axes: {'opsz': 16}, sizes: [16, 16, 17, 17], lines: [24, 24, 28, 28], trackingEm: 0, cap: 2.0)` |
| `type.body.italic` | Newsreader Italic, opsz 16, wght 400 | 16/24 · 16/24 · 17/28 · 17/28 | 0 | `--mm-type-body-italic-size`, `--mm-type-body-italic-lh`, `--mm-type-body-italic-tracking: 0em` | `--text-body-italic` + `type-body-italic` | `typeBodyItalic` = `CineTextRole(family: 'Newsreader', italic: true, wght: 400, axes: {'opsz': 16}, sizes: [16, 16, 17, 17], lines: [24, 24, 28, 28], trackingEm: 0, cap: 2.0)` |
| `type.title` | Archivo, wdth 100, wght 600 | 15/20 · 15/20 · 16/20 · 16/20 | -0.005 em | `--mm-type-title-size`, `--mm-type-title-lh`, `--mm-type-title-tracking: -0.005em` | `--text-title` + `type-title` | `typeTitle` = `CineTextRole(family: 'Archivo', italic: false, wght: 600, axes: {'wdth': 100}, sizes: [15, 15, 16, 16], lines: [20, 20, 20, 20], trackingEm: -0.005, cap: 2.0)` |
| `type.ui` | Archivo, wdth 100, wght 500 | 15/20 · 15/20 · 14/20 · 14/20 | 0 | `--mm-type-ui-size`, `--mm-type-ui-lh`, `--mm-type-ui-tracking: 0em` | `--text-ui` + `type-ui` | `typeUi` = `CineTextRole(family: 'Archivo', italic: false, wght: 500, axes: {'wdth': 100}, sizes: [15, 15, 14, 14], lines: [20, 20, 20, 20], trackingEm: 0, cap: 2.0)` |
| `type.label` | Archivo, wdth 100, wght 650 | 15/20 · 15/20 · 14/20 · 15/20 | +0.005 em | `--mm-type-label-size`, `--mm-type-label-lh`, `--mm-type-label-tracking: 0.005em` | `--text-label` + `type-label` | `typeLabel` = `CineTextRole(family: 'Archivo', italic: false, wght: 650, axes: {'wdth': 100}, sizes: [15, 15, 14, 15], lines: [20, 20, 20, 20], trackingEm: 0.005, cap: 2.0)` |
| `type.kicker` | Archivo, wdth 62, wght 700, UPPER | 11/16 · 12/16 · 12/16 · 13/16 | +0.160 em | `--mm-type-kicker-size`, `--mm-type-kicker-lh`, `--mm-type-kicker-tracking: 0.160em` | `--text-kicker` + `type-kicker` | `typeKicker` = `CineTextRole(family: 'Archivo', italic: false, wght: 700, axes: {'wdth': 62}, sizes: [11, 12, 12, 13], lines: [16, 16, 16, 16], trackingEm: 0.16, cap: 2.0)` |
| `type.credit` | Archivo, wdth 70, wght 700, UPPER | 12/16 · 12/16 · 12/16 · 13/16 | +0.080 em | `--mm-type-credit-size`, `--mm-type-credit-lh`, `--mm-type-credit-tracking: 0.080em` | `--text-credit` + `type-credit` | `typeCredit` = `CineTextRole(family: 'Archivo', italic: false, wght: 700, axes: {'wdth': 70}, sizes: [12, 12, 12, 13], lines: [16, 16, 16, 16], trackingEm: 0.08, cap: 2.0)` |
| `type.credit.label` | Archivo, wdth 70, wght 500, UPPER | 12/16 · 12/16 · 12/16 · 13/16 | +0.080 em | `--mm-type-credit-label-size`, `--mm-type-credit-label-lh`, `--mm-type-credit-label-tracking: 0.080em` | `--text-credit-label` + `type-credit-label` | `typeCreditLabel` = `CineTextRole(family: 'Archivo', italic: false, wght: 500, axes: {'wdth': 70}, sizes: [12, 12, 12, 13], lines: [16, 16, 16, 16], trackingEm: 0.08, cap: 2.0)` |
| `type.nav` | Archivo, wdth 75, wght 600, UPPER | 10/12 · 12/16 · 13/16 · 13/16 | +0.120 em | `--mm-type-nav-size`, `--mm-type-nav-lh`, `--mm-type-nav-tracking: 0.120em` | `--text-nav` + `type-nav` | `typeNav` = `CineTextRole(family: 'Archivo', italic: false, wght: 600, axes: {'wdth': 75}, sizes: [10, 12, 13, 13], lines: [12, 16, 16, 16], trackingEm: 0.12, cap: 1.5)` |
| `type.caption` | Archivo, wdth 90, wght 450 | 13/16 · 13/16 · 13/16 · 13/16 | +0.005 em | `--mm-type-caption-size`, `--mm-type-caption-lh`, `--mm-type-caption-tracking: 0.005em` | `--text-caption` + `type-caption` | `typeCaption` = `CineTextRole(family: 'Archivo', italic: false, wght: 450, axes: {'wdth': 90}, sizes: [13, 13, 13, 13], lines: [16, 16, 16, 16], trackingEm: 0.005, cap: 2.0)` |
| `type.folio` | IBMPlexMono, static, wght 500 | 12/16 · 12/16 · 12/16 · 13/16 | +0.020 em | `--mm-type-folio-size`, `--mm-type-folio-lh`, `--mm-type-folio-tracking: 0.020em` | `--text-folio` + `type-folio` | `typeFolio` = `CineTextRole(family: 'IBMPlexMono', italic: false, wght: 500, axes: {}, sizes: [12, 12, 12, 13], lines: [16, 16, 16, 16], trackingEm: 0.02, cap: 2.0)` |
| `type.folio.lg` | IBMPlexMono, static, wght 500 | 15/20 · 15/20 · 15/20 · 16/20 | 0 | `--mm-type-folio-lg-size`, `--mm-type-folio-lg-lh`, `--mm-type-folio-lg-tracking: 0em` | `--text-folio-lg` + `type-folio-lg` | `typeFolioLg` = `CineTextRole(family: 'IBMPlexMono', italic: false, wght: 500, axes: {}, sizes: [15, 15, 15, 16], lines: [20, 20, 20, 20], trackingEm: 0, cap: 2.0)` |
| `type.micro` | Archivo, wdth 62, wght 700, UPPER | 10/12 · 10/12 · 10/12 · 11/12 | +0.120 em | `--mm-type-micro-size`, `--mm-type-micro-lh`, `--mm-type-micro-tracking: 0.120em` | `--text-micro` + `type-micro` | `typeMicro` = `CineTextRole(family: 'Archivo', italic: false, wght: 700, axes: {'wdth': 62}, sizes: [10, 10, 10, 11], lines: [12, 12, 12, 12], trackingEm: 0.12, cap: 1.5)` |
| `type.dropcap` | BodoniModa, wght 800, opsz = min(size, 96) | size = 3 × the line height of the paragraph it opens (the novel body is user-sized 14–40 px; the recap body 20/32 gives 96 px) | −0.02 em | `--mm-type-dropcap-size: calc(var(--para-lh) * 3)`, where the novel body, the recap and any other host set `--para-lh` on the paragraph | `type-dropcap` (`float: left; initial-letter: 3` where supported, else the computed size) | No fixed field: `CineType.dropcap(double paragraphLineHeightPx)` returns Bodoni Moda 800 at `3 × lh` with `FontVariation('opsz', math.min(3 * lh, 96))`, tracking −0.02 em (no `sizes` or `lines`) |

Font families: `--mm-font-display` (Bodoni Moda), `--mm-font-grotesk` (Archivo), `--mm-font-newsreader` (Newsreader), `--mm-font-folio` (IBM Plex Mono), and the reading faces `--mm-font-literata`, `--mm-font-source-serif`, `--mm-font-atkinson` (§3.4) are the `variable` names given to `next/font`; `--mm-font-text` is not a `next/font` variable but the text roles' family, set by the skin block to `var(--mm-font-newsreader)` and redefined by Hyperlegible text (§3.4); Tailwind maps `--font-display: var(--mm-font-display)` and so on (`font-display`, `font-grotesk`, `font-text`, `font-folio`). Flutter family names are the bundled asset families `BodoniModa`, `Archivo`, `Newsreader`, `IBMPlexMono`, `Literata`, `SourceSerif4`, `AtkinsonHyperlegibleNext` (`CineTokens.fontDisplay` and so on).

## 4. Motion

### 4.1 Principles

1. **Type moves; layout holds.** Letters are set, headlines are typed, rules are drawn. Grids, cards and rows do not slide around, grow or bounce. A hovered poster zooms its image *inside a fixed frame*; the frame never grows.
2. **Edit, don't animate.** Screens change with cuts, dissolves and match cuts. The one theatrical transition (the column wipe into the reader from the front page or a series page) uses the grid itself.
3. **Reading order.** Entrances run left to right, top to bottom, the way the eye scans a page.
4. **Decisive in, quiet out.** Entrances use `settle`. Exits use `lift` and are shorter than their entrances; each exit's duration is the one given in §4.5.
5. **No springs in timed motion.** Springs exist only to finish a finger's gesture, always critically damped (bounce 0).
6. **Scroll drives one move only.** The Tonight trailer scrub (§8.8) is the single scroll-linked animation in the skin: it follows the scroll position frame for frame in both directions and never plays on its own clock.

### 4.2 Durations

| Token | ms | Use |
|---|---|---|
| `dur.cut` | 0 | Same-context swaps: filter, sort, density, tab content |
| `dur.tick` | 80 | Pressed states, knob squash, folio digit roll step |
| `dur.beat` | 160 | Hover colour, chip underline, toast out, chrome out |
| `dur.line` | 240 | Chrome in, input underline draw, dip-to-black in, sheet barrier, toast in, rating card out |
| `dur.column` | 320 | Tab and nav rule slide, dialog insert, sidebar width, panel slide |
| `dur.spread` | 480 | Match cut, iris half, rule draws under mastheads, rating card in |
| `dur.wipe.close` / `dur.wipe.open` | 200 / 280 | One blade of the column wipe closing / opening (§8.14.2) |
| `dur.dissolve` | 800 | Ambient colour change, page-tint change, backdrop swaps |
| `dur.reel` | 1400 | Cold-start logo reveal, fastest total (1180 ms choreography + 220 ms hand-off, §12.4) |
| `dur.drift` | 26000 | Ken Burns on cover-story art (alternate, infinite) |
| `dur.type` | 50 per grapheme | Typing reveal (binding) |
| `dur.caret` | 530 | Caret blink half-period |
| `dur.letter` | 640 (blur 440) | Per-letter reveal of one grapheme |
| `dur.hold.toast` | 3600 | Default toast hold (errors 6000, with an action 8000, skin undo 10000) |
| `dur.hold.rating` | 3000 | 18+ rating card hold |
| `dur.dwell.preview` | 600 | Desktop poster preview slate |
| `dur.dwell.backdrop` | 400 | Desktop backdrop swap on dwell |
| `dur.flicker` | 1400 | Skeleton "projector flicker" half-period |
| `dur.arm` | 1000 | Arm delay of every ordinary destructive confirm (§7.10) |
| `dur.countdown.recap` | 12000 | "Previously on" auto-continue countdown after the recap has streamed (§9.1.5) |
| `dur.countdown.next` | 5000 | Listen post-play card and auto-advance countdown dial (§7.18) |
| `dur.hold.panel.base` / `.word` / `.cap` | 1200 / 250 per OCR word / 6000 | Guided view auto-advance hold per panel (§9.4.3) |
| `dur.sample.tint` | 600 | Minimum interval between page-tint samples (§2.1.5) |
| `dur.pageturn` | 280 | The `SLIDE` page turn in the manga and novel paged readers (§8.14.7, §8.15.4), `ease.settle` |
| `dur.hold.dip` | 40 | Hold on black in the Dip and between the Column wipe's close and open (§4.5, §8.14.2) |
| `dur.snap` | 120 | Row hover and selected fill, check and radio fill, menu exit fade, loading cross-fades, sidebar label fade, the Slate's 120 ms grace, a tap that skips the Column wipe to open |
| `dur.reduced` | 150 | Every 150 ms reduced-motion cross-fade and fade (§4.8) |
| `dur.clip` | 200 | Poster and card hover (image zoom, underline), Insert barrier, menu clip reveal, Slate collapse, one highlight band, the blades' reverse on a failed skin switch, every 200 ms reduced-motion cross-fade (§4.8) |
| `dur.page.out` | 224 | Page and Panel exit, and the pop of a pushed route (§8.0.4, §8.0.5) |
| `dur.dim` | 280 | Sibling dim on poster hover (§7.7) |
| `dur.tapscroll` | 300 | Tap-to-scroll in the strip with `ease.scroll` (§8.14.5); the splash's reduced-motion masthead fade-in (§8.2) |
| `dur.match.back` | 336 | A match cut reversed on back (§4.5, §8.0.4, §8.0.5) |
| `dur.rise` | 360 | Rise: a sheet's entrance (§7.9) |
| `dur.glide` | 400 | Ignite, scroll to top, the Listen transcript follow, group jump in search, settings search jump, the auto-scroll speed ramp (§9.4.1) |
| `dur.stoppress` | 500 | Stop the press, the outgoing skin-switch sequence (§8.30.3) |
| `dur.rack` | 520 | Rack focus, Develop, the guided-view Dolly (§9.4.3) |
| `dur.iris.out` | 560 | Iris out (§8.5), Paddle page (§7.8) |
| `dur.loop.rule` | 1200 | One pass of the indeterminate rule and of the button loading segment (§7.1, §7.18) |
| `dur.hold.error` | 2000 | The `proof` error outline or glyph on a button, icon button or switch (§7.1, §7.2, §7.21) |
| `dur.flame.flicker` | 2000 | Streak flame flicker period (§9.2.2) |
| `dur.flame.risk` | 800 | At-risk streak flame flicker (§9.2.2) |
| `dur.flame.ring` | 24000 | One turn of the 30+ day streak ring, `ease.linear` (§9.2.2) |
| `dur.flame.spark` | 900 | One 100+ day spark rising and fading (§9.2.2) |
| `dur.fade.first` | 100 | The app's first-frame monogram fade-in, `ease.settle` (§8.2) |
| `dur.fade.cut` | 250 | Pull to continue's fade through black into the next chapter (§8.14.6) |
| `dur.fade.hint` | 1000 | The first-use tap-zone bands fading out (§8.14.7) |
| `dur.hold.glance` | 1500 | The tap-zone bands' hold before they fade (§8.14.7); the guided view's whole-page glance on double tap (§9.4.3) |
| `dur.leader` | 1000 | One revolution of the leader dial's sweep, `ease.linear` (§7.18) |
| `dur.hold.success` | 1600 | An input's success `check` (§7.3) |
| `dur.hold.connected` | 400 | Setup's success `check` before the field's underline becomes the login Oxford rule; the screen leaves before `dur.hold.success` runs out (§8.1) |
| `dur.hold.chip` | 1200 | The zoom folio chip in the Lightbox and the manga reader (§7.30, §8.14.5) |
| `dur.hold.flash` | 1200 | The `spot.wash` flash on a row reached by the settings search (§4.8, §8.30.1) |
| `dur.hold.brief` | 2000 | The `BACK ONLINE` badge (§7.13), the pull-to-continue chapter caption (§8.14.6), the colophon's closing line (§9.2.4) |
| `dur.hold.edition` | 4000 | The `OFFLINE EDITION` micro badge before it collapses to its glyph (§7.13) |
| `dur.hold.annual.page` / `.list` | 6000 / 8000 | The Annual's auto-advance per page / per page with a list (§9.2.4) |
| `dur.roll.colophon` | 10000 | The Annual colophon's credits roll (§9.2.4) |
| `dur.loop.preview` | 12000 | Web only: one loop of the web edition preview's self-scroll, down 600 px and back (§8.30.3). The app's preview is a bundled frame loop (36 frames at 6 fps, 6 s) whose length its frames fix |

Every motion duration and every display hold in §4.5, §4.8 and §7–§9 is one of these keys and is written with it, so the web writes it as `duration-(--mm-dur-…)` (or reads the custom property in script, for holds) and Flutter reads the `CineTokens` field. Behaviour timings that are not motion stay literal: debounces (the 300 ms search debounce, the command palette's 220 ms library debounce); waits before something appears (the 400 ms before a leader dial, the 500 ms tooltip delay, the 1 s before the AI leader dial, the 3 s before a slow source's deck changes); idle waits before something hides or re-follows (the 3000 ms chrome idle hide, the brightness HUD's 600 ms after release, the Listen player's 5000 ms linger, the 4000 ms transcript re-follow); timeouts and retry back-offs (the 400 ms recap-availability timeout, the 3 s session probe); polling, sampling and rotation intervals; gesture thresholds and windows (long-press, double-tap, five taps within 2 s, the 1500 ms `g` sequence); the 900 ms auto-next delay; the 800 ms auto-scroll resume; the 4 s inline-confirm revert; user-set values (the guided view's fixed hold, 2–10 s); audio gain ramps (the soundscape's 2000 ms fade in and 600 ms fade out, the sleep timer's 8 s volume fade); and the app edition preview's frame rate (6 fps; its 6 s loop is fixed by the 36 bundled frames, §8.30.3). Stagger and emission spacings (`40 ms apart`; the streak sparks' one per second, then 3 s of rest) also stay literal.

### 4.3 Curves

| Token | Value | Flutter | Use |
|---|---|---|---|
| `ease.settle` | `cubic-bezier(0.16, 1, 0.3, 1)` | `Cubic(0.16, 1, 0.3, 1)` | Every entrance, column-wipe blades (close and open), iris out, Rule slide |
| `ease.lift` | `cubic-bezier(0.7, 0, 0.84, 0)` | `Cubic(0.7, 0, 0.84, 0)` | Every exit that is not a reversed match cut |
| `ease.turn` | `cubic-bezier(0.65, 0, 0.35, 1)` | `Cubic(0.65, 0, 0.35, 1)` | Dissolves, match cuts in both directions (including the Lightbox open and close), iris close, the Stop-the-press rack, colour changes |
| `ease.set` | `cubic-bezier(0.2, 0, 0, 1)` | `Cubic(0.2, 0, 0, 1)` | State changes inside a component (toggle knob, progress width, the 80 ms button impression) |
| `ease.drift` | `cubic-bezier(0.37, 0, 0.63, 1)` | `Cubic(0.37, 0, 0.63, 1)` (not `Curves.easeInOutSine`, which is `Cubic(0.445, 0.05, 0.55, 0.95)`) | Ken Burns, flicker, flame |
| `ease.scroll` | `cubic-bezier(0.5, 1, 0.89, 1)` | `Cubic(0.5, 1, 0.89, 1)` | Tap-to-scroll in the reader strip (75 % of the viewport in 300 ms) |
| `ease.linear` | `linear` | `Curves.linear` | Leader sweep, indeterminate rule, countdowns, the arm rule, the trailer scrub (mapped to scroll) |

### 4.4 Springs (gesture release only)

| Token | Motion (web) | Flutter | Use |
|---|---|---|---|
| `spring.release` | `{ type: "spring", visualDuration: 0.42, bounce: 0 }` | `SpringDescription.withDurationAndBounce(duration: 504ms, bounce: 0)` | Row swipe release, pager settle, Lightbox and page-turn finger releases (the iOS back swipe releases on its package curve, §8.0.5) |
| `spring.sheet` | `{ visualDuration: 0.48, bounce: 0 }` | `withDurationAndBounce(576ms, 0)` | Sheet drag release to a detent or dismiss |
| `spring.scrub` | `{ visualDuration: 0.24, bounce: 0 }` | `withDurationAndBounce(288ms, 0)` | Scrubber thumb and slider thumb release |
| Rubber band | `d·(1 − 1/(x·0.35/d + 1))` | same | Over-scroll past bounds on rails, sheets and the reader's chapter-end pull |

### 4.5 The motion table (named choreography)

Every named move is started through one helper per client (`play(name, …)` in `frontend/src/skins/cinematic/motion.ts`, `CineMotion.play` in `mobile/lib/skins/cinematic/motion.dart`), so the names below are also the labels the motion-timings overlay logs (§15.9).

| Name | Duration | Easing or spring | Spec | Where used |
|---|---|---|---|---|
| **Cut** | 0 ms | none | Instant swap; newly visible items run *Set* | Filters, sorts, density, tab switches inside a page, section change on phones |
| **Set** (content entrance) | 320 ms per item + stagger (§4.6) | `ease.settle` | Items fade 0 → 1 and rise 8 px → 0 in reading order | First paint of any list, grid or rail |
| **Folio flip** | 80 ms per digit, 40 ms apart | `ease.set` | The section number in the running head rolls: old digits translate −100 % and fade, new digits enter from +100 % | Every section change; steppers |
| **Page** (push) | in 320 ms / out 224 ms (`dur.page.out`) | in `ease.settle` / out `ease.lift` | Incoming: x +24 px → 0 and fade 0 → 1. Outgoing: x 0 → −24 px, fade to 0 | Drill-ins with no shared element (settings subpages, list → list) |
| **Match cut** | 480 ms (others dissolve 240 ms); reversed on back 336 ms (`dur.match.back`) | `ease.turn` (both directions) | A shared cover morphs from its rect to its destination rect; everything else dissolves | Poster → feature page, cutting → feature, plate → collection header, mini player → full player |
| **Dip** | out 160 ms, hold 40 ms (`dur.hold.dip`), in 240 ms (440 ms total) | out `ease.lift`, in `ease.settle` | Fade to `#000000`, hold, fade in | Section switches on desktop, auth → picker, leaving a reader, **entering a reader from History, Bookmarks, Updates, Downloads, Library cuttings, dialogue results, Circle, the command palette and deep links** |
| **Column wipe** | desktop 376 + 40 + 456 = 872 ms; tablet (8 blades) 312 + 40 + 392 = 744 ms; phone 248 + 40 + 328 = 616 ms; each 40 ms hold is `dur.hold.dip` | blades `ease.settle`, 16 ms stagger | §8.14.2: the grid's columns close top-down and open bottom-down | Entering either reader **from Tonight, a feature or book page, or a recap opened from them** only; never between chapters |
| **Iris** | close 480 ms, iris out 560 ms (`dur.iris.out`) | close `ease.turn`, out `ease.settle` | §8.5 | Profile selection only |
| **Insert** | in 320 ms (barrier 200 ms, `dur.clip`) / out 160 ms | in `ease.settle` / out `ease.lift` | Dialog clip-path `inset(0 0 100% 0)` → `inset(0)`; barrier 0 → .78; exit is a fade | Dialogs |
| **Rise** | in 360 ms (`dur.rise`; barrier 240 ms) / out 240 ms | in `ease.settle` / out `ease.lift`; drag release `spring.sheet` | Sheet translateY 24 px → 0 and fade | Sheets |
| **Dissolve** | 800 ms | `ease.turn` | Cross-fade; the old layer holds while the new fades over it | Backdrop swaps, ambient and page-tint changes, hero art changes, the Circle avatar relight |
| **Rack focus** | 520 ms (`dur.rack`) | `ease.settle` | Image from blur 14 px, brightness 0.6, scale 1.03 → sharp, 1.0, 1.0 on first decode (skipped when the image was cached synchronously) | Every cover and page image except inside the reader strip; at most 12 images rack at once per screen (the count is kept in `play("rack")` / `CineMotion.play`) |
| **Develop** | 520 ms (`dur.rack`) | `ease.settle` | Opacity 0 → 1, brightness 0.6 → 1, scale 1.03 → 1, no blur | An image that decodes while 12 are already racking on the screen (first loads of walls and results pages) |
| **Drift** | 26 s, alternate, infinite | `ease.drift` | Scale 1.00 → 1.06 and translate −1 %, −1.5 %; paused off screen | Tonight cover art, feature page art, Annual cover art |
| **Flicker** | 1400 ms half-period, alternate | `ease.drift` | Opacity 0.55 ↔ 1; each skeleton's phase offset by 60 ms in reading order | Skeletons |
| **Rule draw** | 480 ms | `ease.settle` | A rule's `scaleX` 0 → 1 from its left end | Oxford rule under mastheads, the heavy rule above notices, the section rule above a revealed H3 (drawn 120 ms, `scalar.stagger.letter.startDelay`, before the letters start) |
| **Letter set** | 640 ms per grapheme (blur 440 ms), 24 ms stagger capped at 560 ms | `ease.settle` | §10.1 | H3 heads, mastheads, hero and cover titles |
| **Type** | 50 ms per grapheme, caret 530 ms half-period | linear clock | §10.2 | Main headlines, notices, numerals |
| **Trailer scrub** | scroll-linked (no clock) | `ease.linear` against scroll progress | §8.8: the cover story compresses into the 64 px now-showing strip in the running head as the spread scrolls away; reverses frame for frame | Tonight only |
| **Cut to home** | 480 ms per poster, 60 ms stagger in pick order | `ease.turn` | §8.7: the onboarding picks fly from the wall into Tonight's first section while the rest of the wall fades out (240 ms `ease.lift`) | End of onboarding only |
| **Lightbox** | open 480 ms / close by button 320 ms / drag release | open `ease.turn`, close by button 320 ms `ease.turn` (a reverse match cut), drag release `spring.release` | §7.30: a match cut from the cover's frame to a contain fit on black | Feature and book page covers, Tonight cover-story art, reader "Open page image" |
| **Arm** | 1000 ms | `ease.linear` | §7.10: a 2 px `proof` rule fills under the destructive button while it is disabled | Every ordinary destructive confirm |
| **Countdown** | 12000 ms (recap), 5000 ms (Listen next) | `ease.linear` | A `spot` rule drains inside the split button (recap) or the dial sweeps (Listen) | §9.1.5, §8.16.7 |
| **Voice pulse** | follows the audio; attack 80 ms, release 240 ms | exponential smoothing | §8.16.5: the highlighter band behind a voice name tracks the sample's RMS | Voice picker `Hear` |
| **Ignite** | 400 ms (`dur.glide`) | `ease.settle` | §9.2.2: the flame's stroke fills and the bloom rises 0 → 0.35 | First chapter of the day |
| **Flame** | flicker 2 s (`dur.flame.flicker`), at-risk flicker 800 ms (`dur.flame.risk`), ring 24 s per turn (`dur.flame.ring`), sparks 900 ms (`dur.flame.spark`); all loops | `ease.drift`, except the ring's `ease.linear` | §9.2.2: the streak flame's tier and state loops, started once when the flame mounts and paused off screen | The streak flame everywhere it appears |
| **Dolly** | 520 ms (`dur.rack`) | `ease.turn` | §9.4.3: the guided-view camera translates and scales from one panel to the next | Panel-by-panel guided view |
| **Unseal** | 160 ms | `ease.settle` | A spoiler-guarded reaction's glyph fades in once the viewer finishes the chapter (§9.3.3) | Chapter-end credits, schedule rows, CIRCLE panel |
| **Credits roll** | 36 px/s, linear | `ease.linear` | The Annual's colophon lines roll upward (§9.2.4) | The Annual, page 10 |
| **Rule slide** | 320 ms | `ease.settle` | The active tab rule, the thumb notch and the segmented-control underline move and stretch to the new item | Contents tabs, thumb index, segmented controls, single-select slug lines |
| **Panel** | in 320 ms / out 224 ms (`dur.page.out`) | in `ease.settle` / out `ease.lift` | A column panel or reader side panel slides from its edge; the strip or content recentres in the same 320 ms (`ease.turn`) | Desktop column panels (§7.9), reader side panels (§8.14.12) |
| **Slate** | grow 320 ms / collapse 200 ms (`dur.clip`) after a 120 ms (`dur.snap`) grace | grow `ease.settle` / collapse `ease.lift` | The preview slate grows from the poster rect | Desktop rail dwell (§7.8) |
| **Paddle page** | 560 ms (`dur.iris.out`) | `ease.turn` | A rail scrolls by `visible − 1` posters | Desktop rail paddles (§7.8) |
| **Unfold** | 480 ms | `ease.settle` | A letter card is revealed by a clip from its top edge down | New Circle letters (§9.3.2) |
| **Leader draw** | 320 ms per row, 24 ms apart | `ease.settle` | Dot leaders clip-reveal left → right | Index, first open per session (§8.28) |
| **Highlight sweep** | 200 ms (`dur.clip`) per band, 60 ms apart | `ease.set` | A `spot.wash` band sweeps left → right behind text | Listen active sentence (§8.16.3), dialogue-search matches (§8.24), onboarding love (§8.7), settings search jump (§8.30.1) |
| **Stop the press** | 500 ms (`dur.stoppress`) | §8.30.3 | Rack out, blades close, masthead cuts in on black, restart | Skin switch outgoing |
| **Credits** | per §8.14.6 | per §8.14.6 | End title, credits, reactions, Coming up | End of a chapter |

### 4.6 Stagger rules

- **Grids and walls:** +32 ms per item within a row, +64 ms per new row, total capped at 480 ms. Items past the cap appear with the last batch.
- **Single-column lists:** +24 ms per row, cap 360 ms (15 rows).
- **Letters:** +24 ms per grapheme, total capped at 560 ms (`step = min(24, 560 / (n − 1))`, `n` = graphemes excluding spaces).
- **AI prose streaming:** each word fades in over 160 ms, 30 ms after the previous word.
- **Only on first data paint.** Refetches, pagination appends and pull-to-refresh results use one 160 ms fade for the whole appended block. Returning to a screen through back never replays a stagger.
- **After a skeleton.** If a skeleton was shown (a wait over 120 ms, §7.17), the data dissolves in over 160 ms and does not run Set. If data arrives within 120 ms (no skeleton), it runs Set.

### 4.7 Interruptibility

- Every property animation retargets from its current value (Motion's default; Flutter `AnimationController.animateTo` from `value`). No animation queues behind another.
- A back gesture during a forward route transition reverses it from its current progress.
- A letter reveal that leaves the viewport before it finishes jumps to its end state; it never replays in the same session.
- A typing reveal completes instantly on tap, click, Enter or Space inside its block.
- Data that arrives while a skeleton is flickering dissolves over 160 ms; no stagger waits for data and no data waits for a stagger.
- The column wipe and iris can be skipped with a tap; they jump to the open state in 120 ms.
- A sheet can be grabbed mid-rise; the finger takes over from the current offset.

### 4.8 Reduced motion (OS setting; web `prefers-reduced-motion`, Flutter `MediaQuery.disableAnimationsOf` or iOS `accessibilityFeatures.reduceMotion`)

| Element | Normal | Reduced |
|---|---|---|
| Per-letter reveal | staggered fade, rise, un-blur | whole string fades in over 200 ms (`dur.clip`) |
| Typing reveal | 50 ms per grapheme with caret | full text at once, no caret |
| Column wipe, iris, match cut, stop the press | as specified | 200 ms (`dur.clip`) cross-fade |
| Page, dip, rise, insert | slides and clips | 150 ms (`dur.reduced`) opacity cross-fade |
| Drift (Ken Burns) | 26 s loop | still frame at scale 1.03 |
| Rack focus | blur-to-sharp | 160 ms opacity fade |
| Develop | fade, brighten, settle | 160 ms opacity fade |
| Flicker skeletons | pulsing | static at 0.8 opacity |
| Rule draws | scaleX | rules present at rest |
| Folio flip | digit roll | instant |
| Poster hover zoom | image scale 1.04 | outline only, no scale |
| Auto-scroll | available | never auto-starts; manual start allowed |
| Guided view camera | dolly between panels | cut between panels |
| Streak flame flicker, 30-day ring rotation, 100-day sparks, at-risk flicker | loops | static flame, static ring, no sparks, no flicker |
| Trailer scrub (Tonight) | art compresses into the strip with the scroll | the spread scrolls away normally; the now-showing strip fades in over 150 ms (`dur.reduced`) once the spread's bottom passes the running head |
| Cut to home (onboarding) | picks fly into Tonight | 200 ms (`dur.clip`) cross-fade to Tonight |
| Lightbox | match cut open, drag-to-dismiss with a following barrier | 150 ms (`dur.reduced`) fade in and out; drag down still dismisses, finishing with a 150 ms (`dur.reduced`) fade |
| Arm rule (destructive confirms) | 2 px rule fills over 1000 ms | the delay stays; the rule appears full at 1000 ms with no fill |
| Recap countdown | rule drains over 12 s | no draining rule; the split button's folio segment `CH 143 · 12 S` updates once per second |
| Listen countdown dial (§7.18, §8.16.7) | `spot` sweep over 5 s | no sweep: the dial shows its ring with a `5 S` … `1 S` folio label updated once per second; the 5 s timing is unchanged |
| Voice pulse | highlighter follows the audio level | a static `color.spot` band at alpha 0.20 while the sample plays |
| Credits roll (The Annual colophon) | lines roll upward | the colophon is shown as a still, complete page |
| Circle avatar relight, page-tint and ambient dissolves | 800 ms dissolve | instant swap, at most once every 2 s for page tint |
| Gestures | finger-tracked, spring release | finger-tracked; release finishes with a 150 ms (`dur.reduced`) fade |
| Rule slide (tab rule, thumb notch, segmented and slug-line underlines) | 320 ms slide and stretch | the rule fades out under the old item and in under the new one, 150 ms (`dur.reduced`) |
| Sidebar collapse to the spine | width 320 ms, labels fade | width changes at once; labels fade 150 ms (`dur.reduced`) |
| Panel (column panels, reader side panels) | slide 320 ms, strip recentres | 150 ms (`dur.reduced`) fade in place; the strip recentres at once |
| Menu clip reveal | 200 ms (`dur.clip`) clip | 150 ms (`dur.reduced`) fade |
| Toast rise and stack push | 240 ms rise, 240 ms push | 150 ms (`dur.reduced`) fade; older toasts move at once |
| Reader chrome in / out (manga and novel) | manga: 8 px slide + fade (240 / 160 ms); novel: fade only (240 / 160 ms), no slide because its bars are solid | fade only, same durations |
| Preview slate | grows from the poster 320 ms | 150 ms (`dur.reduced`) fade at its final size |
| Unfold (new Circle letter) | 480 ms clip from the top | 150 ms (`dur.reduced`) fade |
| Leader draw (Index) | clip reveal, 24 ms stagger | leaders present at rest |
| Highlight sweep (Listen, dialogue search, onboarding love, settings jump) | 200 ms (`dur.clip`) sweep | the band is shown at its end state at once (the settings flash still holds 1200 ms, `dur.hold.flash`, then disappears without a fade) |
| Ignite (streak) | stroke → fill 400 ms (`dur.glide`), bloom rises | the filled glyph and bloom appear at once |
| Paddle page, rail focus scroll, scroll to top, transcript follow, tap to scroll, settings search jump, group jump | 560 / 320 / 400 / 400 / 300 / 400 / 400 ms smooth scrolls (`dur.iris.out`, `dur.column`, `dur.glide`, `dur.glide`, `dur.tapscroll`, `dur.glide`, `dur.glide`) | every programmatic scroll jumps (`behavior: "auto"`, `jumpTo`) |
| Poster and button press | poster scales 0.98; button 1 px impression | no scale; the poster shows its 2 px `ink.100` inside outline while pressed; the 1 px impression stays (it is not spatial motion) |
| Knob squash, chip underline draw, button hover rule | 80–240 ms | final state at once |
| Progress indicators: leader dial (§7.18; not the countdown dial), indeterminate rule and button loading segment (§7.1) | sweep, run and segment loops | unchanged: they keep running, because they are essential progress indicators (§14.1) |

## 5. Haptics

Character: **letterpress**. Low sharpness, firm, sparse. Most taps are silent; commits get a pressed "impression". All calls route through one class (`mobile/lib/skins/skin_haptics.dart`, stack-decision §2.3) behind the user's "Haptic feedback" toggle. Named impacts use `haptic_feedback` 0.6.5 (`Haptics.vibrate(HapticsType.x)`, iOS UIFeedbackGenerator, Android `Vibrator` effects). Signature patterns use `gaimon` 1.5.0 `Gaimon.patternFromData(ahapJson)` (Core Haptics AHAP on iOS, auto-converted to an amplitude waveform on Android; authored with transient and continuous events only, per brand research §9). Mobile web: Android Chrome gets `navigator.vibrate` for the five events marked *web* below (`longpress.open`, `follow.add` and `streak.milestone` vibrate `[12]`; `download.fail` and `error` vibrate `[20,40,20]`); iOS Safari gets nothing. On the web the same per-device "Haptic feedback" switch (§8.30.2 row 10, `localStorage['mm.haptics']`) gates every call. This is an amendment to `stack-decision.md` §2.1 ("the web maps them to nothing"), listed in §15.10: the web haptics file maps those five names to vibration patterns and every other name to nothing. Every haptic is paired with a visible change. **Scope:** the "Haptic feedback" switch is per device (mobile K13 today), because it describes the hardware in the hand.

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
| `longpress.open` | Quick-look sheet, context menu or lightbox (§7.30) opens | `heavy` | `heavy` | `[12]` web |
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
| `streak.milestone` | A 7, 30, 100 or 365-day milestone card appears (§9.2.2) | `ignite`, then `stamp` 520 ms later | same | `[12]` web |
| `recap.countdown.end` | The recap's 12 s countdown reaches zero and the reader opens | none (`reader.enter` fires only when the exit is a Column wipe) | none | — |
| `annual.page` | Annual story page advances by tap | `selection` | `selection` | — |
| `share.export` | Share card rendered | `pressrun` | `pressrun` | — |
| `reaction.send` | Reaction stamp pressed | `stamp` | `stamp` | — |
| `recommend.send` | Recommendation sent | `pass` | `pass` | — |
| `gate.confirm` | 18+ certificate confirmed | `stamp` | `stamp` | — |
| `splash.impress` | The cold-start lockup's impression (§12.4) | `impress` | `impress` | — |
| `profile.select` | Iris closes on the chosen profile | `heavy` | `heavy` | — |
| `skin.switch` | Stop the press, just before restart | `heavy` | `heavy` | — |
| `reader.unlock` | Fifth centre tap unlocks locked controls | `medium` | `medium` | — |
| `success` / `error` | Generic success / failure toast | `success` / `error` | same | — / `[20,40,20]` web |

Never haptic: scrolling (including the Tonight trailer scrub), chrome show and hide, hover, focus, typing reveal characters, letter reveals, toasts appearing, the destructive arm rule, countdown ticks, the voice-sample pulse, page-tint changes.

**"Feel it".** Settings → Feedback has a quiet `Feel it` button beside the Haptic feedback switch; it fires `follow.add` (the `stamp` pattern), the skin's most characteristic impression, so the owner can judge strength before deciding. It is disabled (with the caption "Turn haptics on to feel them.") while the switch is off, and absent on the web.

## 6. UI sounds ("Press Room", off by default)

Opt-in at Settings → Feedback → "UI sounds" (default **off**), with a volume slider (0–100 %, default 60 %). Both are **per profile** (web scoped `localStorage`, mobile SharedPreferences with the `.u{user}p{profile}` suffix), so one reader's sounds never switch on for another on a shared device. All cues are original syntheses (`sox -n … synth`), 48 kHz 16-bit mono WAV, 5 ms fades, total set ≤ 384 KB (13 files, one per cue below, `toggle.on` and `toggle.off` included: 3,740 ms × 96,000 B/s = 359,040 B plus 13 × 44-byte headers; the listed lengths include each cue's reverb tail). Key of G (warm, low-passed below 5 kHz, 0.3 s small-room reverb at 12 % wet). Peaks: ticks −30 dBFS, confirmations −20 dBFS, the logo sting −12 dBFS.

| Cue | Events | Length | Recipe |
|---|---|---|---|
| `tick` | `select`, `nav.change`, `refresh.arm`, `favorite`, `undo`, `scrub.boundary`, `autoscroll.toggle` | 10 ms | Felt key: noise burst band-passed at 2.2 kHz (Q 3) + 90 Hz sine 20 ms |
| `set` | `tap.primary`, `bookmark.add`, `voice.assign`, `share.export` | 60 ms | Type slug: two clicks 12 ms apart + 900 Hz body, 40 ms decay |
| `impress` | `follow.add`, `reaction.send`, `gate.confirm`, `skin.switch` | 140 ms | Letterpress: 70 Hz sine 90 ms exponential decay + felt click, synced to the haptic |
| `turn` | `page.turn`, `annual.page`, `chapter.next` | 160 ms | Paper swish: pink noise, band 800 Hz–5 kHz, 160 ms swell envelope |
| `wipe` | `reader.enter` | 420 ms | Air rush: noise low-passed sweeping 300 → 1800 Hz, landing on a 60 Hz thump at 300 ms |
| `done` | `download.done`, `chapter.complete` | 300 ms | Muted vibraphone G4 · B4 · D5, 60 ms steps |
| `bell` | `streak.extend`, `streak.milestone` | 450 ms | Small bell G6 (1568 Hz), FM ratio 3.5, index 1.0 |
| `pass` | `recommend.send` | 220 ms | Paper slide + soft G5 tick |
| `error` | `error`, `download.fail` | 180 ms | Two dull knocks G3 → F♯3, low-passed 700 Hz |
| `toggle.on` | `toggle.on`, `reader.unlock` | 40 ms | One click at 2.6 kHz |
| `toggle.off` | `toggle.off` | 40 ms | One click at 1.9 kHz |
| `sheet` | `sheet.open` (sound-only event: a sheet starts its Rise) | 120 ms | Low paper slide, −30 dBFS |
| `reel` | `splash.reveal` (sound-only event: the cold-start logo reveal) | ≤ 1600 ms | Projector motor (12 Hz AM noise, 900 ms) + G2/D3 pad swell low-passed 300 → 2400 Hz + the `impress` hit at 1180 ms |

**Every event, with its cue or `—` (silent).** This is the full sound map for `design/contract.json`; it covers every haptic event of §5 plus the two sound-only events.

| Event | Cue | Event | Cue | Event | Cue |
|---|---|---|---|---|---|
| `tap.primary` | `set` | `download.start` | — | `listen.toggle` | — (narration takes over) |
| `tap.secondary` | — | `download.done` | `done` | `voice.assign` | `set` |
| `toggle.on` / `toggle.off` | `toggle.on` / `toggle.off` | `download.fail` | `error` | `sleep.fade` | — |
| `select` | `tick` | `delete.confirm` | — | `streak.extend` | `bell` |
| `nav.change` | `tick` | `undo` | `tick` | `streak.milestone` | `bell` |
| `longpress.open` | — | `reader.enter` | `wipe` | `recap.countdown.end` | — (`wipe` plays only when the exit is a Column wipe) |
| `sheet.detent` | — | `page.turn` | `turn` | `annual.page` | `turn` |
| `sheet.dismiss` | — | `scrub.tick` | — | `share.export` | `set` |
| `refresh.arm` | `tick` | `scrub.boundary` | `tick` | `reaction.send` | `impress` |
| `refresh.fire` | — | `chapter.complete` | `done` | `recommend.send` | `pass` |
| `follow.add` | `impress` | `chapter.next` | `turn` | `gate.confirm` | `impress` |
| `follow.remove` | — | `autoscroll.toggle` | `tick` | `profile.select` | — |
| `favorite` | `tick` | `autoscroll.step` | — | `skin.switch` | `impress` |
| `bookmark.add` | `set` | `autoscroll.end` | — | `reader.unlock` | `toggle.on` |
| `zoom.snap` | — | `success` | — | `error` | `error` |
| `sheet.open` (sound only) | `sheet` | `splash.reveal` (sound only) | `reel` | `splash.impress` | — (the `reel` cue carries the hit) |

Playback: web through the Web Audio API (decode each WAV once into an `AudioBuffer` on the first user gesture; one master `GainNode`); mobile through `flutter_soloud` 4.1.7 (MIT). Rules: on iOS the one process-wide audio session (policy below) is `.ambient` with `mixWithOthers` whenever neither narration nor a voice sample is active (State A), so the ring/silent switch mutes cues; cues are suppressed while narration or a soundscape plays; UI cues never duck the user's music.

**Audio session and focus policy (app; the one rule for UI cues, voice samples, narration and the soundscape).** The iOS `AVAudioSession` is process-wide and `flutter_soloud` leaves it to the app (its miniaudio context sets no category and never activates the session), so only `mobile/lib/skins/skin_audio.dart` configures `AudioSession.instance` (`audio_session`):

| State | When | iOS session | Android focus | Behaviour |
|---|---|---|---|---|
| **A** | At launch; idle; UI cues only; soundscape only | `AudioSessionConfiguration(avAudioSessionCategory: AVAudioSessionCategory.ambient, avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers)` (mixes with other audio; the silent switch mutes; stops in the background) | None: the soundscape `just_audio` player is created with `handleAudioSessionActivation: false` and requests no focus | Cues or the soundscape play (cues stay suppressed while a soundscape plays); the user's music keeps playing at its own volume |
| **B** | Narration playing, or paused inside the reader | `AudioSessionConfiguration.speech()` (`.playback`, mode `.spokenAudio`) | `AUDIOFOCUS_GAIN`, usage media, content type speech | The soundscape continues at 30 % player volume, or pauses per "Pause the soundscape during narration", and is no longer muted by the silent switch; UI cues are suppressed |
| **Voice sample** | While a `Hear` sample plays (§8.16.5, §9.4.2 picker) | `.playback` with `.duckOthers` | `AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK` (through `AudioSession.setActive(true)` with that gain type) | The ring/silent switch never silences a sample; the user's music ducks for its length |

The app's startup call to `configureNovelAudioSession()` (today `AudioSessionConfiguration.speech()` app-wide, which would put cues and the soundscape in `.playback`) is replaced by State A. State B is configured through `AudioSession.instance.configure` when narration starts, and State A is restored when it stops; after a sample ends, the previous state returns. `flutter_soloud` is initialised after the first configuration; the iPhone device pass (§15.8) checks that `SoLoud.instance.init()` leaves the category unchanged, and if it does not, `skin_audio.dart` re-applies the configuration right after init.

---

## 7. Component catalog

Every primitive below is one component per client: `frontend/src/skins/cinematic/primitives/<Name>.tsx` and `mobile/lib/skins/cinematic/primitives/<name>.dart`. Unless a table says otherwise, these rules hold for all of them:

- **Hit area**, by input type (§14.6), grown with padding. Coarse pointer (phones, tablets, mobile web): ≥ 44 × 44 pt on iOS and mobile web, ≥ 48 × 48 dp on Android, ≥ 8 px between adjacent targets; every "44 hit" below means 44 (48 Android). Fine pointer (`@media (pointer: fine)`, desktop web): ≥ 32 × 32 px with ≥ 24 px target spacing (WCAG 2.2 2.5.8), so the desktop `sm` button (32), menu items (40), the segmented control (40) and filter tokens (hit box 32 px tall around the 28 px box) are valid there.
- **Heights** given in these tables are minimums: a control grows to max(token, the scaled line height of its text + 2 × 12 px) at large text scales (§3.3). Web uses `min-height`; Flutter `ConstrainedBox(constraints: BoxConstraints(minHeight: …))` with intrinsic growth, never a fixed `SizedBox` height. This covers badges (min 16, `padding-block: 2px`), buttons (44/48/56; the label may wrap to 2 lines at scale ≥ 1.5), inputs (48), menu items (40/48), the sheet header (56), Listen tiles (88), the mini player (56) and the folio bar (64 + inset, growing to two rows at scale ≥ 1.5 as §3.3 already moves its caption).
- **Focus** shows on keyboard focus only (web `:focus-visible`; Flutter `FocusHighlightMode.traditional`): the double ring of §2.4, a 2 px `ink.100` outline at 2 px offset plus the black halo out to 6 px (`outline: 2px solid var(--mm-color-ink-100); outline-offset: 2px; box-shadow: 0 0 0 6px #000`, combined with any existing shadow; Flutter `CineFocusRing`), square. It is never clipped: rails and grids pad 8 px vertically for it (which holds the 6 px halo), and sticky bars set `scroll-padding-block`.
- **Disabled** means `ink.30` text and glyphs, no hover, no pressed state, `aria-disabled` plus a tooltip that says why when the reason is not obvious.
- **Loading** never replaces a control's width: labels keep their box and a running rule or a 16 px leader dial shows progress; `aria-busy="true"`.
- **Error** states name what went wrong in words, in `proof`, next to the control that failed, with a margin mark `‸` in the left margin on desktop forms.
- Reduced-motion variants follow §4.8.
- **Cursors (web).** `pointer` on every clickable element that is not a native button (posters, cards, rows, tiles, breadcrumb segments); `default` on disabled controls; `text` in fields. Reader paged side zones: `pointer`; centre zone: `default`. Zoomed page and Lightbox: `grab`, and `grabbing` while dragging; drag handles the same. Ruler: `pointer` on the track, `grabbing` while scrubbing. In both readers the cursor hides (`cursor: none`) after 3000 ms without pointer movement while the chrome is hidden, and returns on the next move.
- **Semantics.** Every custom control exposes its role, state and name. The minimum contract, which each §7 component follows:

| Control | Web | Flutter | Name or value |
|---|---|---|---|
| Switch (§7.21) | Base UI Switch | `Semantics(toggled: v, label: <row label>)` | The row label |
| Checkbox (§7.21) | Base UI Checkbox | `Semantics(checked: v)`, tristate for indeterminate | The row label |
| Radio, single-select slug lines, segmented control (§7.5, §7.21) | `role="radiogroup"` / `role="radio"` + `aria-checked` | `Semantics(inMutuallyExclusiveGroup: true, checked: v)` | The option label |
| Multi-select slug lines, icon toggles (Follow, Favourite, Notify, Bookmark, Guided view, Auto-scroll) | `aria-pressed` | `Semantics(button: true, toggled: v)` | A fixed label ("Favourite", never "Unfavourite") |
| Tri-state genre filter (§7.5) | A button | `Semantics(button: true, value: …)` | "Romance: included" / "Romance: excluded" / "Romance: not filtered", plus a polite announcement on change |
| Contents tabs (§7.12) | Base UI Tabs | `Semantics(selected: v)` inside the `TabBar` | The tab label |
| Reaction stamps (§9.3.3) | Radio-like buttons (`role="radio"` in a `radiogroup`) | `Semantics(inMutuallyExclusiveGroup: true, checked: v)` | "Loved, 3 reactions, selected"; guarded: "2 reactions, hidden until you finish the chapter" |
| Download mark (§7.18) | A button | `Semantics(button: true)` | "Saved", "Queued", "Downloading, 30 percent", "Failed, tap to retry" |
| Storage meter (§8.23) | `role="meter"` + `aria-valuetext` | `Semantics(value: …)` | "4.1 of 10 gigabytes used" |
| Progress rules (§7.18) | `role="progressbar"` + `aria-valuenow` | `Semantics(value: …)` | "63 percent" |
| Streak flame (§9.2.2) | `role="img"` | `Semantics(image: true)` | "12-day streak, read today" / "12-day streak, at risk" |
| Week dots (§9.2.2) | One label on the group | One label on the group | "Read on Monday, Tuesday, Thursday" |

### 7.1 Buttons

| Variant | Visual (default) | Size | Where |
|---|---|---|---|
| `primary` | Fill `ink.100`, text `#000000` `type.label`, optional leading icon 20 Regular in `#000`, radius 0 | md 44 (desktop) / 48 (phone); lg 56 (hero); sm 32 visual height on every platform, hit area padded to 44 (iOS, web) / 48 (Android); for dense rows, slates, strips and banners | One per view: Read, Continue, Save, Create, Sign in |
| `split` ("folio button") | A `primary` whose right segment carries a folio: `Continue │ CH 143 · p.12`. The segments are divided by a 1 px `#000` rule; the folio segment uses `type.folio` in `#000` | lg 56 / md 44 (desktop), 48 (phone) / sm 32 (the now-showing strip), as primary; at text scale ≥ 1.5 the folio stacks under the label and the height is label line + folio line + 2 × 8 px, min 64 (§3.3) | Continue and Read CTAs on Tonight, feature pages, history, bookmarks |
| `secondary` | Transparent, 1 px `ink.100` outline, text `ink.100` | as primary | Second action: Read all, Previously on, Add series |
| `quiet` | Text only `type.label` `ink.60`, no outline; 1 px underline at 4 px offset appears on hover | 44 (iOS, web) / 48 (Android) hit | Third actions: Details, Cancel, Skip |
| `destructive` | Outline 1 px `proof`, text `proof`; the final confirm inside a dialog is filled `proof` with `#000` text | as primary | Delete, Remove, Sign out everywhere |
| `on-art` | Fill `color.onart`, 1 px `ink.100` 40 % outline, text `ink.100` | 44 / 48 | Buttons laid over covers and art with no scrim under them (phone hero, Annual pages, the recap's `Skip recap →`) |
| `play` | Circle (the only round button), fill `ink.100`, glyph `play`/`pause` Fill 28 `#000` (at 64 px) | 64 (Listen full player, desktop and tablet), 56 (full player, phones), 36 (mini player) | Listen mode only |
| `link` | Inline Newsreader text with 1 px underline at 3 px offset, `ink.100` | inline | Inside prose: "Turn on sharing in Settings" |

States (all variants; colours swap per variant as noted):

| State | Visual | Motion |
|---|---|---|
| Default | As above | — |
| Hover (pointer) | Primary and split: a 2 px `spot` rule draws under the button, 4 px below its bottom edge, full width. Secondary: fill `paper.4`. Quiet and link: underline appears. Destructive: fill `proof.wash`. | Rule `scaleX` 0 → 1 from the left, 240 ms `settle`; out 160 ms `lift` |
| Pressed | **Impression**: the whole button translates 1 px down; primary fill → `ink.80`; secondary fill → `paper.3`; destructive fill `proof` → `#E0483A`. Haptic `tap.primary` on commit for primary and split. | 80 ms `set` down, 160 ms `settle` up |
| Focused | Focus ring (2 px `ink.100`, 2 px offset); on primary the ring sits outside a 2 px `#000` gap so it separates from the fill | instant |
| Disabled | Primary: fill `paper.3`, text `ink.30`. Others: `ink.30` text and outline. Split: folio segment hidden. "All caught up" is a disabled primary with a `check` glyph. | — |
| Loading | Label stays; a 2 px `spot` segment 25 % wide runs along the button's inside bottom edge left → right (1200 ms `dur.loop.rule` linear loop). Label text changes to the present participle only when the wait passes 400 ms ("Signing in…"). | as described |
| Selected (toggle buttons such as "Following", "In your library") | Secondary becomes filled `ink.100` with `#000` text and a leading `check` | label cross-fade 160 ms |
| Error | Outline or fill turns `proof` for 2000 ms (`dur.hold.error`) and an error line appears beneath (`type.caption` `proof`, margin mark on desktop). No shake. | colour 160 ms |

### 7.2 Icon buttons

| Variant | Visual | Size |
|---|---|---|
| `bare` | Glyph 24 Light `ink.60` | 44 (48 Android) hit |
| `on-art` | 40 px square, fill `color.onart`, glyph 20 Regular `ink.100` | 44 (iOS, web) / 48 (Android) hit (`hitMin` / `hitAndroid`) |
| `ruled` | 36 px square outline 1 px `rule.2`, glyph 20 Regular | 44 (iOS, web) / 48 (Android) hit (`hitMin` / `hitAndroid`); steppers, zoom |
| `badged` | `bare` plus a count badge (§7.19) at the glyph's top-right | bell, downloads |

| State | Visual | Motion |
|---|---|---|
| Default | As above | — |
| Hover | Glyph `ink.100`; a 1 px `ink.30` square outline appears at the hit area's inner 36 px | 80 ms |
| Pressed | Glyph translates 1 px down; square fills `paper.3` | 80 ms down, 160 ms up |
| Focused | Focus ring on the 36 px square | instant |
| Disabled | Glyph `ink.30` | — |
| Loading | Glyph replaced by a 16 px leader dial (§7.18) | cross-fade 120 ms (`dur.snap`) |
| Selected | Glyph switches to Fill `ink.100` and a 2 px `spot` rule sits 4 px under the square (favourite, bookmark saved, notify on) | glyph swap 120 ms (`dur.snap`); rule draw 240 ms |
| Error | Glyph turns `proof` for 2000 ms (`dur.hold.error`); tooltip gives the reason | 160 ms |

Tooltips: `paper.2` band, 1 px `rule.2`, `type.caption` `ink.100`, 6 px × 8 px padding, appear after 500 ms hover (0 ms on keyboard focus), with the shortcut in a keycap when one exists ("Bookmark  B").

### 7.3 Inputs (text, password, number, textarea, select)

The editorial field has no box: a label above and a rule beneath.

| Part | Spec |
|---|---|
| Label | `type.kicker` `ink.45`, 8 px above the text line |
| Text | `type.ui` at 16 px (phone) / 15 px (desktop) `ink.100`; placeholder `ink.45` |
| Underline | 1 px `rule.2` |
| Height | 48 (text baseline 16 px above the rule) |
| Helper / error line | `type.caption`, 8 px below the rule |
| Password reveal | A `quiet` text button "Show" / "Hide" at the right end (words, not an eye). It stays in the tab order directly after its field and carries `aria-pressed` (fixed label "Show password", pressed while the password is visible) and `aria-controls` pointing at the field; Flutter `Semantics(button: true, toggled: visible, label: 'Show password')`. The same on Login, Register and Change password |
| Number | `type.folio.lg`, right-aligned, with a unit suffix in `ink.45` ("min", "GB") |
| Textarea | Faint ruled lines every line height (1 px `rule.1`), like a notepad; grows to 6 lines then scrolls |
| Select | Underline field with a trailing `caret-down` 16; opens a menu (§7.22) on desktop and a sheet on phones |

| State | Visual | Motion |
|---|---|---|
| Default | As above | — |
| Hover | Underline `ink.45` | 160 ms |
| Focused | Underline becomes 2 px `spot`, drawn from the left; label `ink.100`; caret `spot` 2 px wide | 240 ms `settle` |
| Filled | Label stays above; value `ink.100` | — |
| Disabled | Text `ink.30`; underline dotted 1 px `rule.2` | — |
| Loading (async validation, e.g. server URL) | A 16 px leader dial at the right end | fade 120 ms (`dur.snap`) |
| Error | Underline 2 px `proof`; error line in `proof` prefixed with `‸`; `aria-invalid` + `aria-describedby` | 160 ms |
| Success (validated) | A 16 px `check` in `set` at the right end for 1600 ms (`dur.hold.success`) | fade |

### 7.4 Search fields

| Variant | Spec | Where |
|---|---|---|
| `index` (big) | `type.field` (Bodoni Moda Italic) at 28–40 px; placeholder in `ink.45` (4.70:1 on `paper.0`; the raised scope renders it `ink.60`, 6.42:1, inside the command palette's `paper.2`) typed at 50 ms per character when empty and unfocused ("Search every source"); typed text switches to Bodoni Moda Roman; `spot` caret 3 px wide; 1 px underline, 2 px `spot` when focused; trailing `quiet` "Clear" once there is text | Discover, Dialogue, command palette, Picks ask field |
| `compact` | `type.ui` field, leading `magnifying-glass` 20 Regular, height 44, underline style | In-page filters: library, sources, collections, contents go-to |

**`index` accessibility.** Each instance has an accessible name (web `aria-label`; Flutter `Semantics(textField: true, label: …)`): Discover "Search every source", Dialogue "Search what a character said", command palette "Search or jump", the Picks ask field and the Discover `ASK` scope "Describe what you feel like reading". The typed placeholder is a visual layer only (`aria-hidden`, and not a `TypedHeadline`); the input's real `placeholder` / `hintText` holds the same full string, and while the field is focused and empty the full placeholder shows statically, so the field's purpose stays visible until the user types. The masthead kicker directly above the field (`No. 04 — DISCOVER`, `No. 09 — DIALOGUE`, `No. 12 — PICKS`) is the visible context; no second label is added.

States as §7.3. Keyboard: `/` focuses the page's search, `Esc` clears then blurs, `Enter` searches now (skips the 300 ms debounce), `↓` moves into results.

### 7.5 Chips and filters: "slug lines"

Filters are typographic toggles on one line separated by middle dots: `ALL · READING · NOT STARTED · DONE · ★ FAVOURITES`.

| Part | Spec |
|---|---|
| Label | Archivo `wdth` 75, `wght` 600, 12/16 uppercase, +0.10em |
| Count | Raised folio (Plex Mono 10, `ink.45`) after the label: `READING¹²`. Counts are ordinary digits styled smaller and raised (web `font-size: 0.72em; vertical-align: 0.5em`; Flutter a `WidgetSpan` with `Transform.translate(offset: Offset(0, -0.35 * fontSize))`); Unicode superscript characters are never used (the ¹² in this document is notation). Spoken "Reading, 12" through `folioLabel()` (§7.29). This drawing and spoken form apply to every superscript count in the document, not only chips (`CHAPTERS²⁰¹`, `Filters ⁽²⁾`, `FEMALE ¹⁸`, `PINNED⁶`, `Show queue ⁽⁸⁾`: "Filters, 2") |
| Separator | `·` in `ink.30`, 12 px spacing either side, growing as needed so adjacent hit boxes never overlap and keep the 8 px gap |
| Hit box | `max(label width + 24, 44)` wide × 44 (48 Android) tall, centred on the label (32 px tall on a fine pointer, §14.6) |
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

### 7.6 Cards

Programme has few cards; most groupings are rules and space. The card types that exist:

| Card | Anatomy | States |
|---|---|---|
| **Feature** | Image (3:2 crop on desktop, 4:5 on phone) → kicker (`type.kicker`, series `ambient.ink` or `ink.45`) → headline (`type.subhead`, 2 lines) → deck (`type.body.italic` `ink.60`, 2 lines). No frame. | Hover: image zoom 1.04 inside its frame + headline underline; pressed: 1 px impression; focus: ring around the whole card; loading: flicker plate + greeked lines; error: plate with title card |
| **Cutting** (continue reading) | 3:2 crop of the cover at `object-position: 50% 22%`, a 2 px `spot` progress rule flush on the image's bottom edge, then `type.title` 1 line and a folio caption `CH 142 · 63%` or `NEXT · CH 143`. Nudge badges on the image's top-left: `3 NEW`, `ALMOST DONE`, `PAUSED 21 D` | as Feature; long-press opens Quick look with Remove from row, Mark read (the one-chapter call, §8.17), Open series, Previously on (only when `recap.available`, §9.1.5) |
| **World** (AI recommendation) | Three variants. *Available*: full-colour poster 2:3 + title + kicker `MANHWA · ONGOING · ★ 8.4` + `why` line as a Newsreader italic pull quote with a 2 px `spot` left rule + credit `ON MANGADEX, ASURA +1`; the whole card opens the series. *Information only*: the poster in **duotone** (black → `ambient.duo`), credit `NOT ON YOUR SOURCES` in `ink.45`, and two quiet buttons `Search my sources` and `Read on {site} ↗`. Every variant: with the gate open, the 16 px certificate (§7.19, on its `#000000` fill) sits top-left on the poster when `is_adult` is true or any `available[]` source is mature (Shelf: when its source is mature, as the §7.7 poster badge). *Shelf* (the `kind: "source"` items of `/library/suggest`, Picks `FROM YOUR SOURCES`): a full-colour 2:3 poster from the relative `cover_url`, proxied at the snapped width; kicker `{SOURCE NAME}`, followed by ` · {chapter_count} CHAPTERS` only when `chapter_count` > 0 (`/library/suggest` returns 0 for every `kind: "source"` item today); byline "by {author}" when present; the `why` as the pull quote; the whole card opens `/sources/{source}/series/{series_id}`; no rating, no status, no information-only state | Hover: poster zoom; dismiss `x` (`on-art` icon button, §2.1.4) appears top-right on hover and is always in the long-press menu ("Not for me") |
| **Stat block** | 3 px `rule.heavy` on top → kicker → `type.numeral` value → caption. No frame. | Loading: numeral replaced by a greeked bar at the numeral's height; value changes cross-fade 160 ms |
| **Notice** | §7.23 | — |
| **Letter** (Circle recommendation) | Duotone cover strip 3:2 left, right side: kicker `FROM RIYA`, headline title, the note in Newsreader italic in quotes, actions `Read`, `Add`, `Keep`, `Dismiss` (§9.3.4) | New: a `spot` square dot before the kicker until opened. Hover and pressed: the Feature card states (image zoom 1.04 inside its frame + headline underline, 200 ms `dur.clip` `settle`; pressed a 1 px impression) |
| **Collection plate** | 16:9 mosaic of the first four member covers in duotone (the collection's own `ambient.duo` taken from the first member), name in `type.subhead` over a `scrim.foot`, credit `24 SERIES · SMART · SHARED`, shared-with avatars (20 px) bottom-right | Hover: mosaic zoom 1.03; selected (reorder mode): 2 px `spot` inset frame |

### 7.7 Posters

2:3, radius 0, `paper.1` placeholder, inner hairline `inset 0 0 0 1px` in `color.hairline.art`. Width is always derived from the grid (§7.8), requested from the cover proxy at the nearest snapped width ≥ rendered width × DPR (96, 160, 240, 360, 480, 720).

Caption modes:
- **Wall** (onboarding): no caption; the title appears in the hover slate and in `aria-label`.
- **Below** (Library, rails): `type.title` on 1 line (2 at text scale ≥ 1.3), then a folio caption in `ink.45`: `CH 142 · 3 NEW`, `NOT STARTED`, `CAUGHT UP`, `CH 12 OF 40`.
- **Ranked** (Top ten): a Bodoni Moda Roman numeral in `ink.45` (large text: 4.70:1 on `paper.0`, 4.41 on `paper.1`), 1.0 × poster height, sitting half behind the poster's left edge. The poster's accessible name carries the rank: "Number 3, Solo Leveling".

Badges sit top-left in a 4 px inset stack (§7.19): `NEW`/`3 NEW`, status, `18` certificate (only when the profile's gate is open and the series is mature), `SAVED`, `TEXT` (dialogue indexed).

Corners (Library posters, §8.9): badges top-left, select square top-right, hover icons bottom-right, drag handle bottom-left. Each control keeps its corner in every state.

| State | Visual | Motion |
|---|---|---|
| Default | As above | Rack focus on first image decode |
| Hover (desktop) | Image scales 1.04 **inside** the fixed frame; a 2 px `ink.100` inside outline; art light bloom `0 0 48px -16px ambient.duo` at 60 %; caption title underlines; siblings in the same rail or grid dim to `brightness(0.55) saturate(0.8)` (web `:has()`; Flutter an `InheritedNotifier` of the hovered index driving a `ColorFiltered`) | 200 ms `dur.clip` `settle`; sibling dim 280 ms `dur.dim` |
| Dwell 600 ms (desktop rails) | Preview slate (§7.8) | — |
| Pressed | Whole poster scales 0.98 | 80 ms `set`, back 160 ms `settle` |
| Focused | The double focus ring (§2.4: 2 px `ink.100` at 2 px offset plus the black halo, combined with the inset hairline as `box-shadow: inset 0 0 0 1px var(--mm-color-hairline-art), 0 0 0 6px #000`) + the hover treatment; the 8 px focus padding rails and grids reserve holds the halo | instant |
| Disabled (unavailable source) | 40 % opacity, caption `UNAVAILABLE` | — |
| Loading | `paper.1` plate with flicker; if the title is known, a **title card**: the title in Bodoni Moda Italic 14/16 `ink.45`, bottom-left, 8 px inset | Flicker |
| Select mode, unselected | Every poster shows a 24 px square at top-right, 4 px inset, with a 1 px `ink.100` outline on `color.onart`. Hover icons are hidden while select mode is on. | — |
| Hover icons (desktop Library, not in select mode) | Favourite (`star`) and notify (`bell-ringing`) `on-art` icon buttons at bottom-right, 4 px inset, with notify 8 px left of favourite. The same empty select square appears at top-right; clicking it enters select mode with that poster selected (inventory LB14). | With the hover, 200 ms `dur.clip` `settle` |
| Manual order (Library, `Manual order` sort) | A 40 px `on-art` `dots-six-vertical` handle at bottom-left on hover | With the hover |
| Favourited at rest | A 12 px `star` (Fill, `spot`) leads the caption folio (`★ CH 142 · 3 NEW`), and "Favourite" is appended to the poster's `aria-label` | — |
| Selected (select mode) | 24 px `ink.100` check square at top-right with a `#000` check; 2 px `spot` inset frame; image `brightness(0.7)` | Check box fills 120 ms (`dur.snap`) |
| Error (image failed) | `paper.1` plate with the title card and a 16 px `image-broken` Regular glyph `ink.45` (4.41:1 on `paper.1`) bottom-right, labelled "Cover didn't load"; long-press offers "Retry cover" | — |

Long-press (phone, 450 ms) or right-click (desktop) opens Quick look (§7.22).

### 7.8 Rails

| Part | Spec |
|---|---|
| Section rule | 1 px `rule.1` across the content columns, drawn (§4.5 Rule draw) 120 ms (`scalar.stagger.letter.startDelay`) before the heading letters start |
| Header row | Folio (`type.folio` `ink.45`, "04") → 12 px → H3 in `type.section` with the letter reveal (§10.1) → right-aligned `quiet` link "See all" with a 16 px `arrow-right` (desktop hover makes the H3 letters wipe to `spot`, §10.1.4) |
| Header → posters | 12 px |
| Visible posters | phone 3.2 · tablet 5.2 · desktop 6.25 · wide 7.25 · cinema 8.25 (text scale ≥ 1.3 on phones: 2.3) |
| Poster width | `(content width − (visible_floor × gap)) / visible` |
| Gap | phone 8 · tablet 12 · desktop 12 · wide 12 · cinema 16 |
| Scroll | Native horizontal scroll, `scroll-snap-type: x proximity`, snap to poster starts; `overscroll-behavior-x: contain`; Flutter `ListView` with `PageScrollPhysics`-free snapping (`ClampingScrollPhysics` + a snap-to-item `ScrollEndNotification` handler, 320 ms `settle`) |
| Paddles (desktop) | 48 px wide, full poster height, over `scrim.rail-end`; `arrow-right` / `arrow-left` 24 Light `ink.100`; appear on rail hover (160 ms); page by `visible − 1` posters over 560 ms `dur.iris.out` `turn`; hidden at the rail's ends |
| Preview slate (desktop, dwell 600 ms or `Space` on a focused poster) | A portal overlay, not a layout push, 2.1 × poster width, anchored over the poster: top half the duotone cover backdrop (`blur.card`) under a `scrim.foot` that is solid 24 px above the title's first line box (§2.1.4), with the title in `type.subhead` letter reveal on that solid end colour; bottom half `paper.2`: kicker (format · status · chapters), 2-line deck, `why` line if AI-picked, buttons `Read` (primary sm), `+ Library` (secondary sm), `Details` (quiet). Grows from the poster rect 320 ms `settle`; collapses 200 ms `dur.clip` `lift` after a 120 ms `dur.snap` grace on leave. `Esc` closes. The slate is centred on the poster, then clamped so it stays at least 24 px inside the content columns; at a rail's ends it grows from the poster's outer edge inward. Focus rules in the next row. |
| Slate focus | **Keyboard-opened** (`Space`): a non-modal `role="dialog"` with `aria-labelledby` pointing at its title; focus moves to `Read`, and `Tab` / `Shift+Tab` cycle `Read`, `+ Library` and `Details`; `Esc` or `Space` closes it and returns focus to the poster. The poster carries `aria-expanded` and `aria-controls` pointing at the slate. **Pointer-dwell** slates never take focus. Flutter (tablets and desktop with a hardware keyboard): the same behaviour with a `FocusScope` in the `OverlayEntry` |
| Keyboard | One Tab stop per rail (roving `tabindex`); `←`/`→` move; the focused poster scrolls into the first fully visible column (320 ms `settle`); `↑`/`↓` move to the neighbouring rail and the page scrolls so it sits at 30 % of the viewport; `Home`/`End` jump to the rail's ends; `Enter` opens; `Space` toggles the slate |

Rail states:
- **Loading:** header renders immediately (it is a static string) and plays its reveal; posters are flicker plates with title cards when titles are known.
- **Empty:** core rails (Continue, New this week) collapse to a one-line note in `type.body.italic` `ink.45` ("Nothing in progress. Start something below."); optional rails disappear entirely.
- **Error:** header stays; one line `This row didn't load.` in `proof` caption + `quiet` Retry.
- **AI unavailable:** header stays with a `NOTE` kicker line (in `spot`, as §9.1.8): the §9.1.8 copy for `ai.reason` followed by "Here is your shelf instead." (budget: "The picks desk is closed tonight. Asks reset at midnight UTC. Here is your shelf instead.") and a locally built rail replaces it (§9.1.6).
- **Stale:** a `SAVED COPY · 3 H` micro badge beside the header when the payload's `cache.stale` is true (a cached catalogue). AI rails whose picks are older than 24 h carry `PICKED 3 DAYS AGO` instead; AI thinking, unavailable, partial and stale states follow §9.1.8 exactly.

### 7.9 Sheets

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
| Opening | Rise: translateY 24 px → 0 + fade, 360 ms `dur.rise` `settle`; barrier 0 → .78 in 240 ms | Haptic none; sound `sheet` if on |
| Dragging | Follows the finger 1:1; past the top detent rubber-bands with c = 0.35 | — |
| Release | Settles to the nearest detent with `spring.sheet`; dismisses when dragged below 30 % of its height or flung down faster than 800 px/s | Haptic `sheet.detent` on settle |
| Closing | 240 ms `lift`, translateY +24 px + fade | — |
| Loading | Header renders; body shows a 24 px leader dial and the kicker "LOADING" after 400 ms | — |
| Error | A notice (§7.23) inside the body | — |
| Focus | Focus moves to the sheet's first control on open, returns to the trigger on close; `Tab` is trapped | — |

Android back and iOS swipe-down both close; on web, sheets that should close on browser back push a history entry (`?sheet=type`).

**Flutter: `CineSheetRoute`.** `showModalBottomSheet` cannot meet this table (its fling threshold of 700 px/s and 0.5 close threshold are private, its snapping moves at constant velocity, and it clamps at the top instead of rubber-banding), and `smooth_sheets` 1.2.0 misses it too (fixed spring, its own overdrag friction, fling dismissal as a ratio of the viewport), so `CineSheet` is pushed as `CineSheetRoute<T> extends PageRoute<T>` (`opaque: false`, `barrierColor: scrimModal`, `barrierDismissible: true`) in `primitives/sheet_route.dart`:
- one `AnimationController` in pixels of sheet offset, driven by a `VerticalDragGestureRecognizer` on the grabber and header and by the body's scroll overscroll at the top;
- detents: content height (capped at 0.92 of the screen), or `[0.5, 0.92]` for live-preview sheets;
- open: Rise (360 ms `dur.rise` `settle`); close: 240 ms `lift`;
- release: `controller.animateWith(SpringSimulation(CineSprings.sheet.description, offset, nearestDetent, velocity))`;
- dismiss when the sheet is below 30 % of its height, or on a downward fling faster than 800 px/s;
- above the top detent the offset is d · (1 − 1 / (x · 0.35 / d + 1)), with x the overdrag and d the sheet height (`scalar.rubber`);
- Android back and iOS swipe-down close it.

No package is added. Because the route is a `PageRoute`, a `Hero` can fly into it (Quick look, §7.22).

### 7.10 Dialogs

| Part | Spec |
|---|---|
| Surface | `paper.3`, 1 px `ink.30` border, radius 0, max width 560 (6 desktop columns); phones 88 % width, centred |
| Title | `type.subhead` (Bodoni Moda) |
| Body | `type.body` `ink.60`, max 48ch |
| Actions | Desktop: right-aligned row, `quiet` Cancel then the primary or destructive. Phones: stacked full-width buttons, the committing action on top, Cancel as `quiet` below. |
| Ordinary destructive confirms (the **arm delay**) | Every dialog, sheet or inline confirm whose committing action is `destructive` (delete profile, delete shelf, remove from shelf, remove downloads, remove saved audio, cancel all downloads, revoke a session, sign out, unfollow in bulk, clear shared activity, reset reader settings, reset offline storage, delete everything saved) opens with that button **disabled for `dur.arm` (1000 ms)**. A 2 px `proof` rule fills under the button from left to right over the second (`ease.linear`); while it fills the label is `ink.30` and `aria-disabled="true"`; when full, the label turns `proof` (or the fill turns `proof` for the final filled confirm) and a polite live region says "Ready". Enter, Space, a tap or a click during the arm does nothing, so a double tap that opened the dialog can never confirm it. Cancel is live from the first frame. Reduced motion keeps the delay and shows the rule full at 1000 ms. |
| Single unfollow | A single unfollow or remove from library never opens a dialog. It commits at once with the toast "Removed {title}." + `Undo`, held for `dur.hold.toast.action` (8000 ms). Only unfollow in bulk asks first. |
| Heavy confirmations | Typed phrase field ("Type RESTORE to confirm", case-insensitive), acknowledgement checkbox ("I understand this signs me out on this device too"), or typed username (member delete). The confirm button stays disabled until satisfied. The arm delay runs as well; the button enables only when both the second has passed and the condition is met. Used for: restore backup, sign out everywhere, delete member. |
| Motion | Insert (§4.5) in; fade 160 ms `lift` out |
| Focus | Initial focus on the least destructive action; `Esc` and the barrier cancel (except while a destructive request is running) |

States: default; arming (destructive only: first 1000 ms, rule filling); armed; pending (the committing button shows its loading state, Cancel disabled); error (an error line above the actions, in `proof`).

### 7.11 Toasts: "subtitles"

| Part | Spec |
|---|---|
| Position | Phones: bottom-centre, 16 px above the tab bar (or the safe area where there is no tab bar). Desktop: bottom-left of the content column, 24 px from the bottom. |
| Surface | `paper.2` band with a 1 px `rule.2` border (elevation level 2; its root carries `data-stock="raised"` / `CineStock.raised`, §2.1.1), a 2 px left edge rule (`spot` for info, `set` for success and completion, `proof` for errors) |
| Text | `type.ui` `ink.100`, never truncated: copy is written to fit 2 lines at text scale 1.0 and the toast grows with the text at larger scales; 12 × 16 px padding; max width 560 |
| Action | One `quiet` button in `ink.100` with underline ("Undo", "View", "Retry") |
| Hold | 3600 ms; errors 6000; with an action 8000; skin undo 10000; indefinite while hovered or focused |
| Motion | In: fade + 8 px rise 240 ms (`dur.line`) `ease.settle`. Out: fade 160 ms (`dur.beat`) `ease.lift`. A newer toast pushes the older one up by its height (240 ms `set`); max 2 visible. |
| Stacking with the stop-press banner | The stop-press banner (§8.33.3) shares the toast anchor and sits under the stack; it is not a sonner toast (sonner 2.0.8 orders by creation time and has no pinned slot). It renders in the toast host's fixed container at the §7.11 anchor. While it shows, the web host renders `<Toaster offset={{ bottom: anchorBottom + bannerHeight + 8 }} mobileOffset={{ bottom: anchorBottomPhone + bannerHeight + 8 }} visibleToasts={1} />`, otherwise `visibleToasts={2}` with the plain anchors (Flutter's toast overlay host applies the same offsets). A toast therefore always sits above the banner, and with the banner showing a second toast replaces the first. |
| Reader and Page frames | Toasts sit bottom-centre, max 560, 16 px above the highest bottom element that is showing (the folio bar or novel bottom bar, the Listen mini player, the auto-scroll chip). When the chrome is hidden they sit 24 px above the bottom edge. They never cover the ruler. In the novel reader they use the stock colours (§8.15.7). |
| Dismiss | Swipe down (phone), `Esc` (focused), or timeout |
| Accessibility | `role="status"` (polite); errors `role="alert"`; the hold never runs out while a screen reader is active and the toast has an action. Keyboard route: `Alt+T` ("Go to notifications") moves focus into the toast region; web keeps sonner 2.0.8's default region hotkey (`<Toaster hotkey={['altKey','KeyT']} />`), Flutter binds `Alt+T` through `Shortcuts` (hardware keyboard) to the newest toast's action. Focusing the region pauses every hold |

Web uses `sonner` 2.0.8 in unstyled mode rendering these subtitles; Flutter uses one `OverlayEntry` host in the shell (no package).

### 7.12 Tabs (in-page): "contents tabs"

| Part | Spec |
|---|---|
| Label | Folio + label: `01 CHAPTERS`, `02 DETAILS`, `03 MORE LIKE THIS`; `type.nav` desktop size; the folio in Plex Mono `ink.45` |
| Counts | Superscript folio after the label: `CHAPTERS²⁰¹` |
| Indicator | 2 px `spot` underline under the active label, sliding and stretching between tabs during a swipe (its x and width lerp with the pager position); tap-to-switch slides it 320 ms `settle` |
| Row | 48 px, 1 px `rule.1` under the whole row; scrolls horizontally on phones; sticky under the running head on long pages |
| Panels | Swipeable on phones (Flutter `TabBarView`; web scroll-snap pager); click, `[` and `]` on desktop |

States: default `ink.45`; hover `ink.100`; pressed 1 px impression; focus ring; selected `ink.100` + rule; disabled `ink.30` (e.g. `04 CIRCLE` when sharing is off, with a tooltip); loading (count `–`); error (count replaced by `!` in `proof`).

### 7.13 Top bars: the running head

**Phone** (iOS, Android, mobile web):

| Part | Spec |
|---|---|
| Height | Min 44 (iOS, mobile web) / 48 (Android) + status bar inset, so Android's 48 px targets fit; grows to the title line + 2 × 12 px at large text scales (§3.3) |
| Leading | Back (`arrow-left` 24 Light) on pushed screens; nothing on tab roots |
| Running title | Centre: `type.nav` `ink.60`, e.g. `LIBRARY · UPDATES`; hidden while the page masthead is visible, cross-fades in (160 ms) once the masthead scrolls under the bar |
| Trailing | Up to 2 bare icon buttons (screen-specific) |
| Surface | Transparent over the masthead or art; after 24 px of scroll it becomes `#000` with a 1 px `rule.1` bottom (160 ms) |
| Back online | The badge reads `BACK ONLINE` for 2 s (`dur.hold.brief`); when the progress and bookmark outboxes flush, a toast confirms "Synced 12 reads and 2 bookmarks." |
| Offline | When offline, a micro badge `OFFLINE EDITION` in a 1 px `ink.45` box sits under the running title for 4 s (`dur.hold.edition`) after the change, then collapses into a 16 px `wifi-slash` glyph at the trailing edge (tap it for the explanation sheet) |

**Desktop** (768+):

| Part | Spec |
|---|---|
| Height | 56, `#000`, 1 px `rule.1` bottom; transparent with `scrim.head` over spreads until 80 px of scroll (240 ms) |
| Left | Running head breadcrumb: folio + section + page, `No. 02 · LIBRARY / SOLO LEVELING` (`type.folio` + `type.nav`); each segment is a link with the §7.12 tab states (hover `ink.100`) plus a 1 px underline at 4 px offset (160 ms) |
| Right | Index search trigger (a 280 px `compact` field reading "Search or jump…" plus the platform `mod+k` keycap, `⌘K` on Mac and `Ctrl K` elsewhere (§7.26), that opens the command palette), Updates bell (`badged` icon button), profile chip (32 px avatar + name, `type.ui`, opens the account menu: display name, `@username`, `ADMINISTRATOR` credit for admins, Switch profile, Settings, Sign out), clock is not shown |
| Offline | `OFFLINE EDITION` micro badge beside the breadcrumb for as long as the device is offline |

### 7.14 Bottom navigation: the "thumb index" (phones)

| Part | Spec |
|---|---|
| Height | 56 + bottom safe area; `#000`; 1 px `rule.1` top |
| Tabs | 1 `TONIGHT` (`moon-stars`), 2 `LIBRARY` (`books`), 3 `DISCOVER` (`compass`), 4 `DOWNLOADS` (`download-simple`), 5 `INDEX` (`list-numbers`) |
| Cell | Icon 24 (Light; Fill when active) above the label (`type.nav` 10/12); the label keeps `wdth` 62 at every text scale and caps at 1.3 (§3.3 "Labels in fixed cells"), and the icons stay at every scale |
| Active | `ink.100` icon and label + the **thumb notch**: a 24 × 2 px `spot` bar on the cell's top edge. The notch slides between cells 320 ms `settle` |
| Inactive | `ink.60` icon and label (the 10 px condensed label needs more than `ink.45`'s 4.7:1; the active cell still differs by `ink.100`, the Fill icon and the notch) |
| Badges | Library: unread update count; Downloads: queued + downloading + failed count; Index: unread Circle letters. Spot square, `#000` Plex Mono 10 (text scale capped at 1.3), min 16 × 16 and growing to the scaled line height, at the icon's top-right; "99+" cap. Counts are computed after the 18+ gate, including the local download queue (§7.24). |
| Tap active tab | First tap scrolls to top (400 ms `dur.glide` `settle`); second tap pops the branch to its root; on Discover a third tap focuses the search field |
| Long-press | Library → Updates; Downloads → the queue; Index → Switch profile. Haptic `longpress.open`. |
| Visibility | Shown on every screen of the five branches, including second-level lists (Collections, History, Updates, Settings root). Hidden on feature pages (their spread needs the height), readers, auth, the picker, Annual and recap title cards. It never minimises. |
| Motion | Section change: haptic `nav.change`; the new branch appears by **Cut** with its content running **Set**; the running head plays the **Folio flip** |

### 7.15 Desktop sidebar: "Contents"

| Part | Spec |
|---|---|
| Width | 248 expanded; 72 collapsed (the *spine*). Auto-spine at 768–1279; expanded from 1280. `mod+b` toggles; width animates 320 ms `turn`, labels fade out first (120 ms, `dur.snap`) and back in last. |
| Head | Wordmark (Bodoni masthead at 20 px) with `rule.oxford` under it; in the spine, the `mm-mark` monogram |
| Content mode | `MANGA / NOVELS` typographic toggle (only when `novels_enabled`): the active word `ink.100` with a 2 px `spot` underline, the other `ink.45`; a slash between. In the spine: `M` / `N` stacked. |
| Section kicker | `IN THIS ISSUE` then `THE BACK PAGES` (`type.kicker` `ink.45`); hidden in the spine |
| Items | Folio (`type.folio` `ink.45`) + label (`type.ui` `ink.60`) + optional count (Plex Mono `ink.45`) at the right. In this issue: `01 Tonight`, `02 Library`, `03 Updates` (unread count), `04 Discover`, `05 Downloads` (queue count). Back pages: `06 Collections`, `07 History`, `08 Bookmarks`, `09 Dialogue` (manga mode only), `10 The Numbers`, `11 Circle`, `12 Picks`. Footer: `Profiles`, `Settings`, `Status` (admin), collapse toggle. |
| Below 1280 | `mod+b` or the toggle opens the 248 px sidebar as an overlay at `z.panel` over `scrim.modal`. It closes on `Esc`, an outside click or navigation, and the content does not reflow. At ≥ 1280 the sidebar pushes the content, and the choice is stored per device in `localStorage['mm.sidebar']` (`expanded` \| `spine`; not stored below 1280). |
| Collapse toggle | A `bare` icon button with `sidebar-simple` 24 Light. Its tooltip is `Collapse sidebar` or `Expand sidebar` plus the `mod+b` keycap (§7.26), and `aria-expanded` reflects the state. |
| Hover | Label `ink.100`, folio `spot`, 160 ms |
| Active | Label `ink.100`, folio `spot`, a 2 px `spot` bar on the item's left edge (full item height), `aria-current="page"`. Only the exact section lights up: `/library/collections` lights `06 Collections`, not `02 Library`. |
| Focus | Ring around the item |
| Spine | Folio numbers only (Plex Mono 14), labels as tooltips; counts as spot squares |
| Folio jump | `g` then a number jumps to that section (`g 1` … `g 12`; `g 0` Settings; timing and digit handling in §8.0.6), shown in each tooltip. Guarded by the "Single-key shortcuts" setting. |

**Which item lights and what the breadcrumb names** (§7.13):

| Route | Lights | Breadcrumb |
|---|---|---|
| `/` | `01 Tonight` | `No. 01 · TONIGHT` |
| `/library`, `/library/browse` | `02 Library` | `No. 02 · LIBRARY` |
| `/updates` | `03 Updates` | `No. 03 · UPDATES` |
| `/search`, `/sources`, `/sources/:id` | `04 Discover` | `No. 04 · DISCOVER` (`/ SOURCES`, `/ {source}`) |
| `/downloads` | `05 Downloads` | `No. 05 · DOWNLOADS` |
| `/library/collections`, `/library/collections/:id` | `06 Collections` | `No. 06 · COLLECTIONS` (`/ {shelf}`) |
| `/library/history` | `07 History` | `No. 07 · HISTORY` |
| `/library/bookmarks` | `08 Bookmarks` | `No. 08 · BOOKMARKS` |
| `/ocr` | `09 Dialogue` | `No. 09 · DIALOGUE` |
| `/library/statistics` | `10 The Numbers` | `No. 10 · THE NUMBERS` |
| `/circle`, `/circle/:profileId` | `11 Circle` | `No. 11 · CIRCLE` (`/ {member}`) |
| `/library/recommendations` | `12 Picks` | `No. 12 · PICKS` |
| `/profiles/manage`, `/profiles/new`, `/profiles/:id/edit` | footer `Profiles` | `PROFILES` |
| `/settings`, `/settings/:section` | footer `Settings` | `SETTINGS / {section}` |
| `/admin/status` | footer `Status` | `STATUS` |
| `/more` | none | `INDEX` |

Feature and book pages (`/sources/:s/series/:k`, `/library/:followedId`) and `/recap/…` keep the item that was lit before the navigation, held in the shell's state (the shell survives client navigation; a `<Link>` cannot carry `history.state`). On a cold load, `02 Library` lights when the series is followed and `04 Discover` otherwise. The breadcrumb follows the same rule (`No. 04 · DISCOVER / SOLO LEVELING`). The Annual is a Takeover and has no sidebar.

### 7.16 Lists and rows

| Row type | Anatomy | Height |
|---|---|---|
| Standard | Leading 20 Regular icon or 40 × 60 cover or 32 avatar → `type.title` + `type.caption` `ink.45` → trailing folio value or chevron | 56 (one line) / 72 (two lines) |
| Settings | Label `type.ui` + description `type.caption` `ink.45` → trailing control (switch, value with dot leaders, chevron) | min 56 |
| Chapter ("schedule row") | Left: chapter number in `type.folio.lg`, right-aligned in a 56 px column (`·` when the number is null, decimals printed as-is) → title (`type.title`, de-duplicated "Chapter 12" when the source title repeats the number) + caption (release date "TODAY", "YESTERDAY", "3 D AGO", "12 SEP 2026"; page count) → progress: `14/27` in `spot` Plex Mono when in progress, `READ` micro `ink.45` when complete (row text dims to `ink.45`), nothing when unread → download mark (§7.18) → reaction count folio (Circle on; its tooltip or long-press lists who reacted, and for a chapter the viewer has not finished it shows avatars and "reacted to Ch. 212" only, never the glyphs, §9.3.3) | 56 |
| Contents (novel TOC) | Ordinal `type.folio` right-aligned → title in Newsreader 16 → dot leaders → length `12 MIN` → state mark (`42%` in `spot`, `READ`, headphones glyph when narrated, download mark) | 48 |
| Credits (cast, index) | Label → dot leaders → value, all on one baseline | 40 |

| State | Visual | Motion |
|---|---|---|
| Default | 1 px `rule.1` dividers between rows | — |
| Hover | A 2 px `ink.100` bar on the row's left edge; text `ink.100` | 120 ms (`dur.snap`) |
| Pressed | Fill `paper.3` | 80 ms |
| Focused | Focus ring inset 2 px | — |
| Selected | Fill `paper.3` + 2 px `spot` left bar; in select mode a leading 20 px checkbox | 120 ms (`dur.snap`) |
| Disabled | `ink.30`, no hover | — |
| Loading | Greeked lines at the exact line heights | Flicker |
| Error (row-level, e.g. a failed download) | Caption turns `proof` with the reason; a trailing `quiet` Retry | — |
| Current (novel TOC current chapter, go-to target) | `spot.wash` band behind the row + 2 px `spot` left bar; `aria-current="location"` | Band fades in 240 ms |

Swipe actions (phones, coarse pointers): flat square slabs revealed under the row, 72 px each: `Mark read` (fill `ink.100`, `#000` label), `Remove` (fill `proof`, `#000` label). Release past 50 % commits with `spring.release`; the same actions live in the long-press menu and in a trailing `dots-three` button (the non-gesture alternative). Every swipe row has one action. Flutter uses `Dismissible(direction: DismissDirection.endToStart, dismissThresholds: {DismissDirection.endToStart: 0.5})` with the 72 px slab painted as its `background`; `Mark read` rows use `confirmDismiss: (_) async { markRead(); return false; }`, so the row springs back and dims instead of leaving. On the web, swipe rows set `touch-action: pan-y` (§11 precedence).

Drag to reorder (manual library order, pinned sources, collections, collection members, profiles; each also has the §7.22 Move items): a `dots-six-vertical` handle 20 Regular at the trailing edge; the lifted row rises 1 px and gains a 1 px `ink.100` outline (no shadow); siblings shift 240 ms `set`; drop haptic `select`. Keyboard: `Alt+↑/↓` moves the focused row; each move is announced. Web: Motion 13 `Reorder`; Flutter `ReorderableListView` / `flutter_reorderable_grid_view` 5.7.0 for poster grids.

### 7.17 Skeletons: "galley proofs"

| Element | Proof |
|---|---|
| Text line | A bar in `color.galley` at 50 % of the line height, vertically centred in the line box, widths from a seeded ragged list (92, 78, 96, 64, 88 %) |
| Headline | Bars at the headline's line height, 60 % and 35 % wide |
| Poster / image | `paper.1` plate with the inner hairline; a title card when the title is known |
| Numeral | One bar at 40 % of the numeral size |

All run **Flicker** with reading-order phase offsets. A skeleton matches the final layout box for box, so nothing shifts when data lands (the data dissolves over it in 160 ms). Never a shimmer gradient. A skeleton appears only after 120 ms of waiting; shorter waits show nothing.

### 7.18 Progress and loading

| Kind | Spec | Where |
|---|---|---|
| Rule (determinate) | 2 px, square ends, track `rule.1`, fill `spot`; width changes 240 ms `set` | Downloads, bulk runs, OCR scans, narration jobs, storage meter segments |
| Rule (indeterminate) | A 25 %-wide `spot` segment travelling left → right, 1200 ms (`dur.loop.rule`) linear loop | Checking for updates, AI suggest |
| Poster progress | 2 px `spot` rule flush on the cover's bottom edge | Cuttings, history, library posters in progress |
| Micro progress | 2 px `spot` at the very bottom of the reader while chrome is hidden (off in cinema mode) | Reader |
| Leader dial (replaces every spinner) | 32 px circle (24 inline, 16 in controls, 12 inside a switch knob): 1 px `ink.30` ring, 1 px crosshair, conic sweep `color.leader.sweep` at one revolution per 1000 ms (`dur.leader`) linear. Appears only after 400 ms of waiting. | Anywhere a spinner would be |
| Countdown dial | The leader dial at 40 px with a `spot` sweep over 5000 ms (`dur.countdown.next`), one pass; reduced motion shows no sweep, only a `5 S` … `1 S` folio label updated once per second (§4.8) | Next-chapter countdown in Listen mode, auto-advance |
| Folio counter | `07 / 40` in `type.folio.lg` | Reader, scans |
| Download mark (per chapter) | 16 px square outline 1 px: *not downloaded* `cloud-arrow-down` 16 Regular `ink.45`; *queued* dashed outline `ink.45`; *downloading* the square fills bottom-up in `spot` with progress; *saved* `check-square` Fill `set`; *failed* square outline `proof` with `!`; *paused* two 2 px bars `spot`; *stale* `cloud-arrow-down` in `spot` (download again). Each has a tooltip with the full wording from the inventories (DP7, mobile §6c). | Chapter rows, reader running head |
| Storage meter | 8 px bar in three segments: other apps `ink.60` (information, so never `ink.30`, §2.1.1), ManhwaManiacs `spot`, free `rule.1`; the cap is a 2 px `ink.100` tick above the bar; a `NOTE` kicker line when the cap or the 1.5 GB floor is reached | Downloads, Storage |

### 7.19 Badges

Square boxes, min height 16 (`padding-block: 2px`; the box grows with text scale, §7 intro), horizontal padding 4, `type.micro`. Stacked 4 px apart.

**Badges on art.** Every outlined badge that can sit on art (all poster badges, Cutting nudge badges, World card badges, and the running head's `OFFLINE EDITION` micro badge) gets a `#000000` fill inside its 1 px outline, so its text contrast equals the flat-black figures whatever the cover: `ink.100` 18.44, `spot` 13.94, `set` 11.41, `ink.60` 7.20, `proof` 6.85, `ink.45` 4.70. Sizes and the 4 px stack gap do not change.

| Badge | Visual |
|---|---|
| `NEW` / `3 NEW` / `99+ NEW` | Fill `spot`, text `#000` |
| Status `ONGOING`, `COMPLETED`, `HIATUS`, `CANCELLED`, `UPCOMING` | 1 px `ink.45` outline, text `ink.60` |
| Reading status `READING`, `ON HOLD`, `PLAN`, `DROPPED`, `DONE` | 1 px `ink.100` outline, text `ink.100` (only on the Library wall, never on discovery posters) |
| 18+ certificate | A square 16 × 16 (20 × 20 on feature pages) with a 1 px `proof` outline and `18` in `proof` Archivo `wdth` 62 `wght` 800; on art it is a `#000000` square with the same outline and numeral. Never shown when the gate is closed (the content is absent then). A World card (no source flag, no resolved rating) shows it, with the gate open, when `is_adult` is true or any `available[]` source is mature |
| `SAVED` | 1 px `set` outline, text `set` |
| `TEXT` (dialogue indexed) | 1 px `ink.45` outline, text `ink.45` |
| `SAVED COPY · 3 H` (stale catalogue) | 1 px `spot` outline, text `spot`, `NOTE` semantics |
| `PICKED` (AI) | 1 px `ink.100` outline, text `ink.100` |
| `PICKED 3 DAYS AGO` (stale AI result, §9.1.8) | 1 px `ink.45` outline, text `ink.45`; beside an H3 or a masthead deck, never on a poster |
| `SMART`, `SHARED` (collections) | 1 px `ink.45` outline |
| `NOW` (Circle: reading right now) | Fill `ink.100`, text `#000` |
| Count badge (icons, tabs) | Fill `spot`, text `#000` Plex Mono 10, min 16 × 16 |
| Admin, You, Deactivated (members) | `ADMIN` 1 px `ink.100`; `YOU` fill `ink.100` `#000` text; `DEACTIVATED` 1 px `proof` |

**Reading-status vocabulary.** One label per stored `reading_status` value (web K8 / mobile K36) everywhere (badges, slug lines, selects, menus, captions): `unread` → `NOT STARTED`, `reading` → `READING`, `on_hold` → `ON HOLD`, `plan_to_read` → `PLAN TO READ` (badges may shorten this one to `PLAN`), `completed` → `DONE`, `dropped` → `DROPPED`. `COMPLETED` is reserved for publication status.

### 7.20 Sliders and the scrubber

| Part | Spec |
|---|---|
| Track | 2 px `rule.2`, fill `ink.100` up to the value, step ticks 1 × 6 px `ink.30` under the track when steps ≤ 20 |
| Thumb | A 2 × 20 px vertical `ink.100` bar (a tick mark), 44 × 44 (48 × 48 Android) hit area |
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

The reader scrubber ("the ruler") is §8.14.4; the speed ruler (Listen) is §8.16.4.

### 7.21 Toggles, checkboxes, radios, steppers

| Control | Spec | Motion |
|---|---|---|
| Switch ("slug switch") | 44 × 24 rectangle, 1 px `ink.45` outline, 16 × 16 square knob inset 4 px. Off: knob left, fill `ink.45`, track transparent. On: track fills `spot`, knob right, fill `#000`. The row's label, not the switch, says what it does. | Knob slides 160 ms `set`; while pressed the knob widens to 20 px (a squash, not a bounce); haptic `toggle.on` / `toggle.off` |
| Switch states | Hover: outline `ink.100`. Focus: ring around the track. Disabled: outline `rule.1`, knob `ink.30`. Loading (server-backed switches such as 18+ or notify): knob replaced by a 12 px leader dial, `aria-busy`. Error: outline `proof` for 2000 ms (`dur.hold.error`) and the switch reverts, with an error line. | — |
| Checkbox | 20 × 20 square, 1 px `ink.45` outline; checked: fill `ink.100` with a `#000` check drawn as a 2 px square-capped path (not an icon glyph); indeterminate: fill `ink.100` with a 10 × 2 `#000` dash. Hover: outline `ink.100`. | Fill 120 ms (`dur.snap`); hover outline 80 ms |
| Radio | 20 px circle (round allowed), 1 px `ink.45`; selected: 10 px `ink.100` dot. Hover: outline `ink.100`. | 120 ms (`dur.snap`); hover outline 80 ms |
| Stepper | `−` value `+`: two 36 px `ruled` icon buttons around a `type.folio.lg` value, min width 64; bounds disable the button; hold to repeat every 120 ms after 400 ms | Value digits roll (Folio flip) |

### 7.22 Menus and context menus

| Part | Spec |
|---|---|
| Surface | `paper.2`, 1 px `rule.2` border, radius 0, min width 224, max height 60 vh |
| Item | 40 px (48 phone), leading 20 Regular icon (optional), `type.ui`, trailing shortcut keycap or submenu caret; separators `rule.hair`; destructive items `proof`; checked items a leading `check` |
| Hover / focus | Fill `paper.4` + 2 px `ink.100` left bar |
| Motion | Clip reveal from the anchored edge 200 ms `dur.clip` `settle`; exit fade 120 ms `dur.snap` |
| Keyboard | Arrows, `Home`/`End`, type-ahead, `Enter`, `Esc`, submenu with `→`/`←` |

**Context menu.** Desktop: right-click opens the menu at the pointer (Base UI `ContextMenu`). Phones: long-press 450 ms opens **Quick look**: the pressed poster dims to 70 % for 120 ms (`dur.snap`), then a sheet rises whose header match-cuts the poster into a 96 px cover beside the title, kicker and credits, followed by the action list (Open, Continue, Previously on, Add to collection, Favourite, Mark read, Download next 5, Recommend to…, Not for me, Remove from row, Unfollow). Haptic `longpress.open`. Flutter builds it on `onLongPress`, then pushes a `CineSheetRoute` (§7.9; no `super_context_menu`). It is a `PageRoute`, so the poster's `Hero` flies into the 96 px header over the Rise.

**Move items (the single-pointer reorder path).** Every reorderable row's and poster's menu (the trailing `dots-three`, Quick look and right-click) gains `Move up`, `Move down`, `Move to top` and `Move to bottom`, disabled at the ends. This applies to manual library order, pinned sources, collections, collection members and profiles. Each move animates with the existing 240 ms `set` sibling shift, writes `sort_order`, and is announced in a polite live region ("Solo Leveling moved to position 3 of 12"). Flutter's `ReorderableListView` also exposes the same four actions to screen readers.

### 7.23 Notices: empty, error and offline states

One component, five tones, set like a short article:

| Part | Spec |
|---|---|
| Rule | 3 px `rule.heavy` above, drawn on entrance |
| Kicker | `type.kicker`: `EMPTY SHELF`, `NOTHING HERE YET`, `CORRECTION` (error, in `proof`), `OFFLINE EDITION`, `NOTE` (caution, in `spot`), `SLOW DOWN` (rate limit) |
| Headline | `type.subhead` on phones, `type.headline` at 0.6 scale on desktop; **typed** at 50 ms per character (§10.2) |
| Deck | `type.deck` `ink.60`, max 48ch |
| Actions | Up to two: `primary` + `quiet` |
| Glyph | Optional 32 px Light glyph above the kicker, `ink.45` |
| Placement | Left-aligned on the grid: 6 columns desktop, 4 phone; vertical offset 15 vh when it is the whole screen |
| Rate limit | Deck includes a live countdown folio "Retrying in 12 s" from `Retry-After` |

The global offline case adds "Saved chapters still open." and a `Go to Downloads` action. `503 db_busy` is retried quietly with its `Retry-After`; only after three attempts does a toast say "The server is busy. Your progress is saved on this device and will sync." Nothing ever shows a count or a placeholder for 18+ content that the gate hides.

### 7.24 The 18+ gate: "the certificate"

- **Mark.** `certificate-18` at 16 px (poster badges, rows, the Sources table, Discover credits) and 20 px (feature credits, the rating card, the picker's avatar marker) is the §7.19 badge: a 1 px `proof` outline and "18" in `proof` Archivo `wdth` 62 `wght` 800 at 10 px (16 px box) or 12 px (20 px box). At 160 px (the certificate dialog only) it has a 2 px `proof` border and "18" in Bodoni Moda Roman `wght` 900 at 88 px.
- **Certificate dialog** (the only way to open the gate, from Settings → Content **and** from the profile form, so both places share one safeguard): full screen on phones, a 560 dialog on desktop. Layout: the 160 px certificate on the left (desktop) or top (phone); kicker `RESTRICTED · THIS PROFILE ONLY`; headline "Show mature content on {profile}?" (Bodoni Moda); body in Newsreader: "Adult (18+) sources, series, search results and recommendations will appear throughout ManhwaManiacs for this profile. Only continue if you are of legal age where you live. You can turn this off any time."; a checkbox "I am 18 or older"; buttons `Enable 18+` (primary, disabled until checked) and `Cancel` (quiet).
- **Confirm moment.** The certificate's square fills `proof` for 160 ms, the "18" knocks out to `#000`, then settles back to outline (a stamp). Haptic `gate.confirm`, sound `impress` if on. Every mature-gated query root is invalidated, and the next screen re-enters its skeleton.
- **Turning off** needs no confirmation; a toast confirms "18+ content hidden on {profile}".
- **Rating card** (feature page open and reader start for series whose resolved `rating` is `mature`): top-left under the running head, a 20 px certificate + `18+` in `type.kicker` + descriptors from genres in `type.caption` `ink.60` ("Violence · Sexual content"), all inside a `paper.0` box with 8 × 12 px padding so the text never sits on art (§2.1.4 over-art rule); fades in 480 ms (`dur.spread`) `ease.settle`, holds `dur.hold.rating`, fades out 240 ms (`dur.line`) `ease.lift`. Informational only.
- **Per-series override** (`mature_override`): feature page overflow → "Treat as 18+" / "Treat as not 18+" / "Use the source's rating" (radio menu).
- **Absence, never a lock.** Gated content is not drawn at all: no blurred tiles, no "hidden" counts, no locked rows.
- **Local copies follow the gate too** (both clients, filtered on the device, because local stores are not server-filtered). Every locally stored row that names a series carries `mature: bool` (the source's `mature` flag OR the series' resolved `rating == "mature"`, after `mature_override`), written when the row is stored and re-stamped whenever `mature_override` changes: mobile sqflite download rows (series and chapter), the offline bookmark store and outbox, the offline follow cache (`manhwamaniacs:followed-series`), the progress outbox, saved narration audio, the web service-worker download index and page-cache entries, and the cached payloads behind the offline editions of Tonight (§8.8 "Saved on this device"), Library and Downloads. Every local read goes through one filter per client (web `features/offline/mature-filter.ts`, mobile `features/downloads/utils/mature_filter.dart`) that drops `mature` rows unless the active profile's `mature_content_enabled` is on. Closing the gate keeps the files on disk (reopening it brings them back at once) but hides them everywhere: lists, search, continue rows, badges and the Downloads count. Queued or running downloads of a now-hidden series pause silently and resume when the gate reopens. Nothing says that files are hidden: no caption, no count, no "n hidden" line. The storage meter keeps the app's total bytes, because it is a device fact that names no series, and "Free up space" and retention sweeps still act on hidden files by their normal rules.

### 7.25 Avatars

Circles (sizes 20, 24, 28, 32, 44, 56, 96, 112, 144). Each preset is a field colour with a radial darkening to 60 % black at the rim and a Phosphor Fill glyph at 45 % of the diameter in `ink.100` (≥ 3:1 is required for a non-text glyph; every field reaches 4.5:1, 4.53:1 minimum on Usher; checked by the surface × ink loop, §2.1.1). The 12 existing `avatar_key` values map to a new set:

| Key | Name | Field | Glyph |
|---|---|---|---|
| violet | Matinee | `#6E56CF` | `film-slate` |
| cyan | Newsreel | `#1A778C` | `newspaper` |
| rose | Romance | `#B83A56` | `heart` |
| amber | Usher | `#95630F` | `flashlight` |
| emerald | Critic | `#1A7B54` | `pen-nib` |
| ember | Premiere | `#BE4523` | `fire` |
| blade | Swordplay | `#5E6878` | `sword` |
| phantom | Phantom | `#474B94` | `ghost` |
| arcane | Illusionist | `#7D45B8` | `magic-wand` |
| lunar | Late show | `#2B5699` | `moon-stars` |
| star | Marquee | `#85690C` | `star` |
| reader | Bookworm | `#177878` | `book-open-text` |

Selected (picker, form): a 2 px `spot` ring at 3 px offset. 18+ marker on the picker: a 20 px certificate (the §7.19 badge) at the avatar's bottom-right. Unknown keys fall back to Matinee.

**Reading-now ring** (Circle readers strip and member page, §9.3.2): when a member read in the last 15 minutes, their avatar gets a 2 px ring at 3 px offset in the `ambient.duo` of the series they have open, with the `NOW` badge beside the name. A change of series dissolves the ring colour over 800 ms (`ease.turn`); when they stop, the ring fades out over 800 ms. The ring appears only when the viewer is allowed to see that activity (the member shares activity, the series is not excluded, and for an 18+ series the member's own `Include 18+ titles in my activity` is on **and** the viewer's own gate is open; enforced server-side, `now` is `null` otherwise, §9.3.8); otherwise the member shows neither ring nor `NOW`. Hover (desktop) or long-press (phone) shows a tooltip "Reading Omniscient Reader · CH 212". Reduced motion: the colour swaps without a dissolve.

### 7.26 Keycaps

`type.folio` 12 in a 1 px `ink.30` square box, min 20 × 20, 4 px horizontal padding; Mac glyphs `⌘ ⌥ ⇧` where the platform is Mac. Secondary combos at 60 % opacity. Shortcuts named in running copy use the same platform rule: `⌘K` on Mac, `Ctrl K` elsewhere. This applies to the 404 deck and to the running head's "Search or jump…" trigger (§7.13).

### 7.27 Masthead block and section header

- **Masthead block** (top of every page): kicker (folio + section, e.g. `No. 02 — YOUR SHELF`) → `type.masthead` title with the letter reveal → deck (`type.deck` `ink.60`, one line of live facts: "212 series · 14 with new chapters") → `rule.oxford` on desktop / `rule.heavy` on phones, drawn after the letters land. Bottom margin 48 (desktop) / 32 (phone). A mood grade (§2.1.6) sits behind the top 30 vh.
- **Section header**: §7.8 header row, also used outside rails (settings sections, stats blocks).

### 7.28 Layout primitives

- `Grid`: resolves the breakpoint's columns, margin and gutter and exposes `span(n)` and `col(i)`; the debug overlay (§2.2.2) draws from it.
- `Measure`: caps a text block's width in `ch` and rounds display blocks to the 4 px baseline (§3.2).
- `Spread`: the 5 + 7 column composition with the art's bleed, `blur.bleed` fill, `scrim.gutter`, grain and drift.
- `Credits`: label/value pairs (labels in `type.credit.label`, values in `type.credit`), two columns on desktop, one on phones, a 1 px `rule.1` column rule between.

### 7.29 Other primitives

- **Content-mode switch**: sidebar version §7.15; on phones a chip `MANGA ▾` in the running head of Library, Discover, Downloads and Index opening a small sheet: kicker `READING MODE`, the typographic toggle, and "One setting for the whole app: library, sources, search, downloads and updates all follow it." Haptic `select`. Hidden entirely when novels are disabled.
- **Pull to refresh ("reprint")**: pulling past the top of a refreshable list reveals a 2 px `spot` rule that grows from the centre outwards with the pull (rubber band c = 0.35) and the caption `PULL TO REPRINT` → `RELEASE TO REPRINT` at the 96 px trigger (haptic `refresh.arm`); on release the rule becomes the indeterminate rule until done. Flutter: `custom_refresh_indicator` 4.0.2 with this builder; web: 60 lines of pointer-event code; desktop web: `r` key and a Refresh item in the page's overflow menu. Not on Downloads (local data).
- **Select-mode bar** (bulk actions): a bottom bar (phone) or a bar under the running head (desktop), `paper.2` with a 1 px `rule.2` top, showing `12 SELECTED` (folio), `Select all 40`, actions as `quiet` buttons with icons (Favourite, Unfavourite, Mark read, Mark unread, Add to collection, Download, Unfollow in `proof`) and `Done`. Running state: `4 OF 12 · 1 FAILED` + a determinate rule + `Stop`. Result line with `Dismiss` and, for destructive runs, `Undo` (re-follows with the saved status, favourite, notify, override and shelf position). Unfollow in bulk asks for a dialog confirmation first.
- **Banner strips** (under the running head): `paper.0` with a 2 px left rule; kicker + one line + actions. Used for: "Nothing followed yet" (first run), staged restore, update available (Android APK), overdue checker (admin).
- **Share card frame**: §9.2.5.
- **Spoken folios** (`folioLabel()`): folios and abbreviations are read in full. One helper per client (`frontend/src/skins/cinematic/a11y/folio.ts`, `mobile/lib/skins/cinematic/a11y/folio.dart`) returns the spoken form, applied as `aria-label` / `Semantics(label:)` with the visual text `aria-hidden` / `ExcludeSemantics`: `CH 142 · 63%` → "Chapter 142, 63 percent read"; `2 H` → "2 hours ago"; `PAUSED 21 D` → "Paused 21 days"; `READING¹²` → "Reading, 12"; `p. 12` → "page 12"; `12 MIN` → "12 minutes"; the 18+ certificate → "Mature, 18 plus". One small table test per client (`folio.test.ts`, `folio_test.dart`) asserts these conversions.

### 7.30 Lightbox (the whole cover)

A full-screen view of art that the layout crops: a series cover shown whole instead of cropped into a spread or a 4:5 hero.

| Part | Spec |
|---|---|
| Opens from | Long-press 450 ms (phones) or double-click (desktop) on: the feature page and book page cover (§8.17, §8.18), Tonight's cover-story art (§8.8), the Annual's cover art; the overflow item `View cover` on those screens (the non-gesture path, also reachable by keyboard: `v` on the feature page and Tonight); the reader's page action `Open page image` (§8.14.13) uses the same primitive with the page image |
| Surface | `color.lightbox` (`#000000` at 96 %) over everything (`z.lightbox`); square corners; **no bloom, no grain, no drift**; the art at `object-fit: contain`, centred, never larger than 1.5 × its natural pixels at rest (a 720 × 1080 cover shows at most 1080 × 1620 CSS px) |
| Chrome | Top-right: `x` `on-art` icon button (`Close`, 44 (48 Android) hit). Bottom-left: the series title in `type.caption` `ink.60` and a folio `COVER · 720 × 1080` (`PAGE 18 · 800 × 12400` for pages), both on the folio-flag ground (§2.1.4) because the zoomed art reaches under them. The `+` `−` `Fit` buttons (desktop, bottom-right) are `on-art` icon buttons. Chrome hides after 3000 ms idle and returns on tap or pointer move. |
| Open | Match cut from the art's frame to the contain rect, 480 ms `ease.turn`; the barrier fades 0 → 0.96 in 240 ms. Haptic `longpress.open`. |
| Zoom | Pinch 1–4×; double tap (double-click on desktop) toggles 1× ⇄ 2.5× at the tap point in 240 ms (`dur.line`) `ease.settle`; `Ctrl`/`⌘` + wheel zooms around the pointer; `=` `-` `0` keys; pan when zoomed; the zoom level shows as a folio chip `250%` (`type.folio` `ink.100` on the folio-flag ground, §2.1.4) top-centre for 1200 ms (`dur.hold.chip`) |
| Dismiss | Drag down (only at 1×): the art follows the finger and the barrier fades with distance (opacity 0.96 × (1 − dy / 400)); release past 120 px or faster than 800 px/s dismisses by a reverse match cut into the original frame on `spring.release`, otherwise it springs back on `spring.release`. `x`, `Esc`, Android back and browser back (a `?view=cover` history entry) close by button with a 320 ms `ease.turn` (a reverse match cut). |
| States | Loading the full-size image: the cached crop is shown scaled into place at once and the sharp image racks in (Rack focus) when it lands; failed: the cached crop stays with a caption "Couldn't load the full cover." in `proof`; offline: the cached copy only |
| Accessibility | `role="dialog"`, `aria-modal`, `aria-label="Cover of {title}"`; focus moves to Close and returns to the trigger; zoom buttons (`+`, `−`, `Fit`) appear for keyboard and switch users when focus is inside |
| Implementation | Web: a portal with `@use-gesture/react` 10.3.1 (`usePinch`, `useDrag`) and Motion `animate` for the match cut (FLIP from the source rect). Flutter: a `PageRouteBuilder` (opaque false) with `Hero` for the match cut and `InteractiveViewer` (min 1, max 4) plus a vertical drag handled while `TransformationController.value` is identity. |
| Reduced motion | 150 ms (`dur.reduced`) fade in and out; drag-to-dismiss still works and finishes with a 150 ms fade |
---

## 8. Per-screen specs

### 8.0 Frames, navigation, routes and platform rules

#### 8.0.1 Frames

| Frame | Where | Chrome |
|---|---|---|
| **Bare** | Setup, splash, login, register | No navigation. Masthead and content only. |
| **Takeover** | Profile picker, onboarding, recap title card, The Annual, the streak milestone title card (§9.2.2), certificate dialog on phones | Full screen, own close or back control |
| **Desktop** (web ≥ 768) | Every app screen | Contents sidebar (248; the 72 spine at 768–1279) + running head 56 + content on the 12-column grid (8 columns inside 768–1023) |
| **Phone** (iOS, Android, web < 768) | Every app screen | Running head 44 (48 Android) + content on the 4-column grid (tablet grid at 600+) + thumb index 56 |
| **Reader** | Manga reader, read-all | No app chrome; the reader's own running head and folio bar; desktop keeps optional side panels |
| **Page** | Novel reader, Listen full player | No app chrome; everything painted in the paper stock |

Sidebar hidden in the readers. Outside the readers the desktop frame keeps at least the 72 px spine at any height. Below 500 px of viewport height the spine's section list scrolls inside it (`overflow-y: auto`) and its footer items fold into a `dots-three` menu at its bottom.

#### 8.0.2 Navigation map

- **Phone thumb index:** Tonight · Library · Discover · Downloads · Index.
  - *Library* is a hub with contents tabs `SHELF · UPDATES · COLLECTIONS · HISTORY · BOOKMARKS`, each its own route. The unread badge sits on the Library tab (the bell's count is never hidden two levels deep).
  - *Discover* holds search, sources, source catalogues, Picks and dialogue search.
  - *Index* holds the profile, Circle, The Numbers, settings, admin and about.
- **Desktop Contents sidebar:** the same destinations flattened into numbered sections (§7.15).
- **Series pages** are one screen with two renderings (manga *Feature*, novel *Book*), reached by both the follow id route and the source route, so there is exactly one series page per series.

#### 8.0.3 Route contract (`design/contract.json`, both clients)

| ScreenId | Path | Notes |
|---|---|---|
| `setup` | `/setup` | App only. So that one `SCREEN_IDS` list stays complete on both clients (`screens satisfies Record<ScreenId, Screen>`), the web registers `setup` as a server redirect to `/login` (a three-line screen: `redirect("/login")`) |
| `login` / `register` | `/login`, `/register` | |
| `profiles` / `profileNew` / `profileEdit` / `profilesManage` | `/profiles`, `/profiles/new`, `/profiles/:id/edit`, `/profiles/manage` | Mobile `/profiles/create` and `/profiles/edit/:id` kept as aliases |
| `onboarding` | `/welcome?step=1..5` | New profile only; while `glass_available` is false step 1 is never shown, the route runs `step=2..5` and the folio reads `1 / 4` … `4 / 4` (§8.0.7) |
| `tonight` | `/` | Home. Web: `frontend/src/app/(app)/page.tsx` (inside the `(app)` route group, because the app has two root layouts and no top-level one, §8.30.3) is a thin route that renders `skins[await getSkin()].screens.tonight`. Until the Cinematic flip, `next.config.ts` keeps the `/` → `/library` 307 for `legacy` (it has no Tonight) with `missing: [{ type: "cookie", key: "mm-skin", value: "(cinematic\|glass)" }, { type: "cookie", key: "mm-skin-debug", value: "(cinematic\|glass)" }]`; Next skips the redirect when either cookie matches, so both a Cinematic profile and the pre-flip debug row (§8.0.7) reach Tonight. The flip release deletes `redirects()` |
| `library` | `/library` (`?status&sort&fav&view&q&select`) | `/library/browse` renders the same screen with the toolbar open; on phones, where the toolbar is collapsed, it opens the Filters sheet once on mount |
| `feature` | `/sources/:sourceId/series/:seriesKey` | Manga Feature or novel Book by `content_kind` |
| `featureByFollow` | `/library/:followedId` | Resolves the follow row, renders `feature` in place (no redirect flash) |
| `updates` | `/updates` (`?tab=following`) | Library hub tab |
| `collections` / `collection` | `/library/collections`, `/library/collections/:id` | Mobile `/collections…` aliases |
| `history` / `bookmarks` | `/library/history`, `/library/bookmarks` | Library hub tabs |
| `picks` | `/library/recommendations` | §9.1 |
| `numbers` / `annual` | `/library/statistics`, `/library/statistics/annual/:year` | §9.2 |
| `recap` | `/recap/:sourceId/:seriesKey?to=:chapterKey` | §9.1.5 |
| `circle` / `circleMember` | `/circle`, `/circle/:profileId` | §9.3 |
| `discover` | `/search` (`?q&scope=all\|library\|sources\|dialogue\|ask`) | |
| `sources` / `source` | `/sources`, `/sources/:sourceId` (`?mode&genre&q`) | |
| `reader` | `/reader/:sourceId/:seriesKey/:chapterKey` (`?page&at&all`) | Mobile `/library/read/…` and `/sources/…/chapters/:chapterId/read` kept as aliases |
| `readAll` | `/read-all/:sourceId/:seriesKey` (`?from&page&at`) | |
| `novel` | `/novels/:sourceId/:seriesKey/:chapterKey` (`?page&para&at&listen=1`) | Mobile `/novels/read/…` alias |
| `downloads` | `/downloads` (`?tab=storage`) | |
| `dialogue` | `/ocr` (`?q`) | Mobile `/ocr/search` alias |
| `index` | `/more` | |
| `settings` | `/settings`, `/settings/:section` | Sections in §8.30 |
| `status` | `/admin/status` | Admin |
| `readerLanding` | `/reader` | Web only in practice; the app registers it as a redirect to `/library`, for the same completeness reason as `setup` |

**Shell branches (app, `StatefulShellRoute.indexedStack`).** Every route belongs to exactly one branch or to the root navigator:

| Branch | Routes |
|---|---|
| 0 Tonight | `/` |
| 1 Library | A nested `StatefulShellRoute.indexedStack` whose five hub tabs are the branch roots `/library` (with `/library/browse` rendering in the same SHELF tab), `/updates`, `/library/collections`, `/library/history`, `/library/bookmarks`. Switching hub tabs replaces the route, and none of the five shows a back arrow. Android back from a tab other than SHELF goes to SHELF, then to Tonight. `/library/collections/:id` is pushed inside branch 1 and has a back arrow |
| 2 Discover | `/search`, `/sources`, `/sources/:sourceId`, `/ocr`, `/library/recommendations` |
| 3 Downloads | `/downloads` |
| 4 Index | `/more`, `/settings…`, `/admin/status`, `/library/statistics`, `/circle`, `/circle/:profileId`, `/profiles/manage` |
| Root navigator (thumb index hidden, §7.14) | `setup`, `login`, `register`, `feature`, `featureByFollow`, `reader`, `readAll`, `novel`, `recap`, `annual`, `onboarding`, the other `profiles*` routes, the Lightbox, the milestone title card (§9.2.2: an overlay route with no path, `opaque: false`, like the Lightbox; on the web a `?view=milestone` history entry like the Lightbox's `?view=cover`, so browser back and Android back close it with its Dip out) |

- Inside a branch, drill-ins use `push`, so they get a back arrow.
- Cross-branch links use `go` into the owning branch, and the notch moves; they never push a duplicate. For example, Index → Updates is `go('/updates')`.
- Every static `/library/...` path is declared before `/library/:followedId`: go_router matches in declaration order, and `featureByFollow` would otherwise capture `/library/history`.
- **Encoded route builders.** `design/build.mjs` emits typed route builders into `contract.generated.ts` and `contract.g.dart` that percent-encode each path segment (`encodeURIComponent` / `Uri.encodeComponent`), because `routes.dart`, which encodes today, is deleted at the flip and series keys can hold `/`, `%` or spaces. Screens never build paths by string concatenation, and routers decode exactly once. Follow state by `series_identity` stays in the kept data layer (`followed-index.ts` `followedIdFor`, `series_identity.dart`).

#### 8.0.4 Transitions every screen inherits

| Navigation | Transition |
|---|---|
| Section change (tab bar, sidebar) | Phone: **Cut** + **Set** + **Folio flip**. Desktop: **Dip** (160 / 40 / 240) + Folio flip. |
| Drill-in from a poster or cutting | **Match cut** (cover → cover) |
| Drill-in without a shared element | **Page** (x 24 px + fade) |
| Back | The forward move's exit as given in §4.5 (Page 224 ms, `dur.page.out`); a reversed match cut runs 336 ms `dur.match.back` `turn` into the originating poster if it is still in the tree, otherwise Page |
| Into either reader from Tonight, a feature or book page, or a recap opened from them | **Column wipe** (§8.14.2) |
| Into either reader from anywhere else (History, Bookmarks, Updates, Downloads, Library cuttings, dialogue results, Circle, the command palette, a deep link) | **Dip** (440 ms), so frequent re-entries stay fast |
| Between chapters inside a reader | Never a wipe: the seam, the pull-to-continue fade through black, or Dip for a chapter picked in Contents |
| Out of a reader | **Dip** |
| Sheets / dialogs | **Rise** / **Insert** |
| Takeovers (Annual, recap, onboarding, milestone title card) | **Dip** in, **Dip** out |

Web (`transitionTypes` belongs to the navigation, not to `<ViewTransition>`):
- **Links and pushes carry the type:** `<Link href={…} transitionTypes={["nav-forward"]}>`, and `router.push(href, { transitionTypes: ["nav-back"] })` for in-app back links.
- **The page wrapper maps types to classes:** `<ViewTransition default="none" enter={{ "nav-forward": "mm-page-in", "nav-back": "mm-page-back-in", default: "none" }} exit={{ "nav-forward": "mm-page-out", "nav-back": "mm-page-back-out", default: "none" }}>`.
- **Shared covers:** `<ViewTransition name={coverTransitionName(sourceId, seriesKey)} share="mm-match-cut">`, where the name is `cover-` + the 8-hex-digit 32-bit FNV-1a of `sourceId + "\u0000" + seriesKey` (always a valid `view-transition-name`, since raw keys can hold `/`, `%` or spaces). It is synchronous (about 6 lines in `features/`; `crypto.subtle` is async and cannot run during render) and computed once per card. Flutter `Hero` tags take the `(sourceId, seriesKey)` tuple itself.
- **Browser back** (popstate) carries no type, so it gets `default: "none"` and a browser or OS back animation never plays twice.

#### 8.0.5 Platform rules

| Topic | iOS | Android | Mobile web | Desktop web |
|---|---|---|---|---|
| Back | Edge swipe (20 pt strip, `swipeable_page_route` 0.4.8 `SwipeablePage` with `canOnlySwipeFromEdge: true`, `backGestureDetectionWidth: 20`); the finger-tracked slide runs on a linear curve: the top page's x follows the finger while the page beneath goes from −30 % to 0 under a `#000` dim that falls from 0.6 to 0; release: the package's own `Curves.fastLinearToSlowEaseIn` (0.4.8 hard-codes it in `dragEnd`), which is the iOS system back curve, with no fork; commit past 50 % or ≥ 1 width/s. Button and programmatic pops play Page (see "Route transitions in the app" below) | Predictive back via `CinePageTransitionsBuilder` (§15.3; a full-screen fade-through reads as a film cut); `android:enableOnBackInvokedCallback="true"`; branch roots return to Tonight, then the system takes over; the back order for modal states is below the table | Browser history; sheets are history entries; no JS edge swipe | Back link in the running head breadcrumb; `Esc` closes the top layer |
| System bars | Status bar light content. Reader enter: `SystemUiMode.manual` with `overlays: []` (status bar hidden, home indicator auto-hidden). Chrome shown: `SystemUiMode.manual` with `overlays: [SystemUiOverlay.top]`, in step with the 240 ms chrome-in; hidden again with the 160 ms chrome-out | Status and navigation bars transparent, light icons, edge-to-edge. Reader enter: `SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky)`. Chrome shown: `SystemUiMode.manual` with `overlays: [SystemUiOverlay.top]` with the 240 ms chrome-in, hidden with the 160 ms chrome-out. Both OSes, reader exit: `SystemUiMode.edgeToEdge` with `SystemUiOverlayStyle.light`, `statusBarColor` and `systemNavigationBarColor` `Color(0x00000000)`, `systemNavigationBarContrastEnforced: false`. The strip and the novel column ignore system insets and stay edge to edge, so toggling the bars never reflows pages; the running head is 44 (48 on Android) + `MediaQuery.viewPaddingOf(context).top` | `theme-color` `#000000`; PWA `display: standalone`, black startup images for the installed iOS PWA | n/a |
| Scroll physics | `ClampingScrollPhysics` + stretch overscroll (the skin's physics on both OSes) | same | native | native; Lenis 1.3.26 smooth wheel only on Tonight and The Annual, never in readers, lists or under reduced motion |
| Haptics | §5 | §5 | Android `navigator.vibrate` subset | none |
| Share | `share_plus` 12.0.2 share sheet | same | Web Share API level 2 with files, else download | Download + copy link |
| Hardware keys | iPad keyboard: the web key map through `Shortcuts`/`Actions` | Volume keys page in the reader (opt-in); keyboard map as iOS | external keyboard: web map | full map |
| Text scale | Dynamic Type (§3.3) | font scale (§3.3) | root font size | browser zoom |
| Long-press on images | n/a | n/a | Posters, covers, cuttings and reader pages set `-webkit-touch-callout: none; user-select: none; -webkit-user-drag: none`, so iOS Safari's image callout never fights Quick look, the Lightbox or page actions, and so does every element with a long-press action: thumb-index tabs, rows with row menus, source rows, profile avatars, the Listen mini player and the auto-scroll chip. For those elements only, the phone frame also calls `preventDefault()` on `contextmenu` | n/a |
| Edge swipes | As mobile web, with the edge width max(24 px, `MediaQuery.systemGestureInsetsOf(context).left` / `.right`), which also clears iOS's 20 pt back strip | As iOS | In-reader horizontal gestures (chapter swipe, paged swipe) ignore touches that start within 24 px of either screen edge, leaving the edge to iOS Safari's back swipe and Android's gesture navigation. The strip chapter swipe is live only at zoom ≤ 1.0 and for drags within 30° of horizontal; above 1.0× a horizontal drag pans the page. Precedence between rows, pagers and the reader is in §11 | n/a |

**Route transitions in the app (programmatic push and pop, both OSes).** Every push and every button or programmatic pop plays **Page**: the incoming page goes x +24 → 0 px and opacity 0 → 1 over 320 ms `ease.settle`, while the outgoing page (driven by `secondaryAnimation`) goes x 0 → −24 px and opacity 1 → 0 over 224 ms `dur.page.out` `ease.lift`; a pop reverses both over 224 ms. Match-cut routes set `transitionDuration` 480 ms and `reverseTransitionDuration` 336 ms (`durMatchBack`); their covers are `Hero`s with `transitionOnUserGestures: defaultTargetPlatform == TargetPlatform.iOS`, so iOS reverses the match cut with the finger (§8.11, §8.17) and Android's predictive back fades through instead.

- **iOS.** Every pushed route is a `SwipeablePage` (`swipeable_page_route` 0.4.8) with `canOnlySwipeFromEdge: true`, `backGestureDetectionWidth: 20`, `transitionDuration` 320 ms (480 ms for match cuts), `reverseTransitionDuration` 224 ms (`durPageOut`; 336 ms `durMatchBack` for match cuts) and a `transitionBuilder` of the 0.4.8 `SwipeableTransitionBuilder` shape `(context, animation, secondaryAnimation, isSwipeGesture, child)`, where `isSwipeGesture` is `route.popGestureInProgress`. When `isSwipeGesture` is false it paints Page; when true it paints the finger-tracked slide of the Back row on a linear curve. The page beneath cannot use its own `isSwipeGesture` (it is false there) and reads `Navigator.of(context).userGestureInProgress` instead. Release uses the package's own `Curves.fastLinearToSlowEaseIn` (hard-coded in 0.4.8's `dragEnd`; the iOS system back curve), not `spring.release`; the package is not forked.
- **Android.** `CinePageTransitionsBuilder` (`mobile/lib/skins/cinematic/transitions.dart`) is registered with `PageTransitionsTheme(builders: {TargetPlatform.android: CinePageTransitionsBuilder()})`. It overrides `transitionDuration` (320 ms) and `reverseTransitionDuration` (224 ms, `durPageOut`), which `MaterialPageRoute` reads directly, so no route subclass is needed. Its widget is a `WidgetsBindingObserver` that copies Flutter's private `_PredictiveBackGestureDetector`: `handleStartBackGesture` returns false for `isButtonEvent` or when `!(route.isCurrent && route.popGestureEnabled)`, and otherwise calls `route.handleStartBackGesture(progress: 1 − event.progress)`; `handleUpdateBackGestureProgress`, `handleCommitBackGesture` and `handleCancelBackGesture` forward the same way. When `route.popGestureInProgress` is false it paints Page. When true it paints the full-screen fade-through: the outgoing page's scale goes 1.00 → 0.95 and its opacity 1 → 0 over progress 0–0.6, the incoming page's opacity goes 0 → 1 over progress 0.4–1.0, a commit finishes in 240 ms `ease.settle` and a cancel returns in 160 ms `ease.settle`. Match-cut routes use `CineMatchCutPage`, a `Page` whose `PageRoute` uses 480 / 336 ms (`durSpread` / `durMatchBack`) with the same builder. `ZoomPageTransitionsBuilder` and `PredictiveBackFullscreenPageTransitionsBuilder` never ship (the latter falls back to Zoom's 300 ms for every non-gesture navigation, which would make Page and the 480 ms match cut impossible).
- **Readers** use their own route (§8.14.2).

**Back inside modal states (app).** Sheets close on Android back and iOS swipe-down (§7.9). Otherwise Android back takes the first of these that applies:

1. exit select or reorder mode (Library, Collections, collection Reorder, Downloads), like `Done`; the selection is discarded;
2. collapse the Listen full player to the mini player;
3. close the settings search;
4. in onboarding, go from step n to step n − 1 with the pager's 320 ms `ease.settle` (the pager swipes backward only; forward needs `Next`); from the first shown step, back returns to the picker;
5. on a picker opened by Switch profile, pop to the previous screen with the previous profile still active.

Switch profile opens the picker as a pushed takeover without clearing the active profile; the active profile is replaced only when another is picked. On the sign-in picker, back is left to the system. On iOS, states 1–4 wrap their route in `PopScope(canPop: false)`, which disables the edge swipe (a swipe cannot be redirected); their visible `Done`, collapse, close and `Back` controls are the way out. The Switch-profile picker keeps its edge swipe.

#### 8.0.6 Global web keys (app frame)

| Key | Action |
|---|---|
| `mod+k` | Command palette ("Index", §8.33.1) |
| `mod+b` | Toggle the sidebar spine |
| `?` | Keyboard sheet (§8.33.2) |
| `/` | Focus the page's search field |
| `Alt+T` | Go to notifications: focus the toast region, pausing every hold (§7.11) |
| `g` then `1`…`12` / `0` | Jump to a numbered section / Settings (single-key setting) |
| `Esc` | Close the top layer; in readers, the escape order in §8.14.9 |
| `mod+shift+g` | Grid overlay (development builds) |
| `mod+shift+m` | Motion-timings overlay (development builds, §15.9) |

Inside the reader frames (manga, read-all, novel, Listen) the global `g`-then-number sequence is disabled, so `g` means only "go to page" (manga) or "go to %" (novel).

**The `g` sequence.** `g` arms a sequence for 1500 ms. `g 2`…`g 9` and `g 0` jump at once. `g 1` waits 600 ms for a second digit (`0`, `1` or `2`, giving 10, 11 or 12) and otherwise jumps to `01`; `Enter` jumps to `01` at once. Any other key, `Esc` or the timeout cancels the sequence. While armed, a keycap chip `G 1_` shows at the toast anchor (§7.11) and fades 160 ms after the sequence ends. Keys consumed by the sequence are never delivered to page bindings (Library `1`–`7`, Discover `1`–`5`, feature `1`–`4`, The Numbers `1`–`4`, Circle `1`–`5`).

**`Delete`.** `Delete` in any screen's key list means `Delete` or `Backspace` with no modifier, ignored while typing in a field. The keycap renders `⌫` on Mac and `Del` elsewhere (§7.26).

#### 8.0.7 Before Glass ships: the `glass_available` flag

The build order is Cinematic, then the new features on Cinematic, then Glass (`stack-decision.md` §4 #12), so Cinematic ships for a while with nothing to switch to. `design/contract.json` carries `"flags": { "glass_available": false }`, generated into `FLAGS.glassAvailable` (`contract.generated.ts`) and `Flags.glassAvailable` (`contract.g.dart`); it turns `true` in the release that ships Glass. While it is `false`:

| Surface | Behaviour |
|---|---|
| Onboarding (§8.7) | Step 1 (Edition) is skipped: `/welcome?step=2..5` (Formats, Genres, Art style, Seeds), folio `1 / 4`, four progress rules |
| Profile form (§8.6) | The `Skin` row is not rendered |
| Command palette (§8.33.1) | No `EDITION` group |
| Settings → Appearance → Edition (§8.30.3) | The Cinematic card as specified, badged `THIS EDITION`. The Glass card is a disabled plate at the same 3:4 size: `paper.1`, 1 px `rule.1` frame, no iframe and no PNG loop, kicker `NEXT ISSUE` (`type.kicker`, `ink.60` per §2.1.1), "Glass" in Bodoni Moda Italic `type.subhead` `ink.60`, caption "In preparation. It arrives in a later update." No button; `aria-disabled="true"`. The caption under both cards is omitted. |
| Settings footer (§8.30.1) | "Settings save as you change them." (the restart sentence is dropped) |
| Picker iris step 4, the boot check, the undo toast | Cannot trigger: a profile whose stored `skin` is `glass` (written by a later build or through the API) renders in Cinematic, the device mirror is left alone and the stored value is kept for when Glass ships |
| App icon | No alternate icon is registered or switched (§12.3) |

**The pre-flip debug row.** Until the release that flips the default from `legacy` to Cinematic (`stack-decision.md` §3 "Release model"), Cinematic is reached only through a debug row: in the app, Settings → Diagnostics → `Edition (debug)` with the segmented control `LEGACY │ CINEMATIC` (`│ GLASS` added once Glass's completeness tests pass); on the web, `/settings/diagnostics?debug=1` shows the same row (the web has no Diagnostics section otherwise; the query flag lives in `sessionStorage['mm.debug']` for the tab). The row writes a device override (cookie `mm-skin-debug`, SharedPreferences `mm.skin.debug`) that the boot resolution reads before comparing the profile's skin with the mirror (the "one more key read before step 2" that `stack-decision.md` §2.4 reserves for a per-device override), then restarts with a 200 ms (`dur.clip`) fade to black, not Stop the press. It never writes `reading_profiles.skin`. The row, the override key and `legacy` are deleted together at the flip.

#### 8.0.8 Content mode (Manga / Novels) on every screen

The reading mode (mobile G5, web content mode) is one setting per profile, shown only when `novels_enabled`. What follows it:

| Follows the mode (shows only that mode's series) | Mode-agnostic (both kinds together) | Not applicable |
|---|---|---|
| Tonight (the cover story and every section; `GET /home?content_kind=manga\|novel`), Library, Updates, Collections, History, Bookmarks, Discover results, Sources, Downloads, the lists on The Numbers (the totals cover both, §9.2.1) | Picks (World items carry a `format`; novels are labelled `NOVEL`), Circle and member pages, The Annual, share cards, onboarding, the command palette's `LIBRARY` group | Readers, series pages, recaps (they follow their series), dialogue search (manga only; novels mode shows its notice, §8.24), Settings |

**A novel as Tonight's cover story.** The spread becomes the book's title page (§8.18): columns 1–5 carry the kicker, the typed headline in `type.cover` ("Tonight: chapter 213 of The Beginning After the End."), the byline "by {author}" in Newsreader Italic 22, a 56 px rule, the deck and credits (`CHAPTERS`, `≈ WORDS`, `SOURCE`, `STATUS`); columns 6–12 hold the 168 × 248 cover plate centred on a field of the same cover at `blur.bleed`, duotoned to `ambient.duo`, with `scrim.gutter`, grain and Drift on the field only. Actions: `Continue │ CH 213 · 42%`, `Listen` (secondary, when narrated) and `Previously on…`. Phone: the 4:5 hero is the blurred duotone field with the 120 × 176 plate centred in its upper half, the typed headline and deck below it under `scrim.foot`. Without a cover, the plate is the Bodoni initial on `paper.1` (§8.9.1).

#### 8.0.9 Tablet and landscape layouts

The app uses the phone frame (running head + thumb index) at every width and lays out on the 8-column tablet grid from 600 px; the web uses the phone frame on the same grid at 600–767 px and the desktop frame with the spine (768–1279; 8 columns at 768–1023, where it follows each screen's desktop layout on 8 columns). Sheets are max 720 px wide and centred on tablets (§7.9). Screens not listed keep their phone layout, centred at max 720 px.

| Screen | Tablet (8 columns, 600–1023) |
|---|---|
| Setup, Login, Register | Form in columns 2–7; Login shows all three cover lines above the form |
| Profile picker | One centred row of 112 px avatars up to four, then a second row; ≥ 900 px the desktop row of 144 px |
| Profile form, Manage profiles | Columns 2–7 |
| Onboarding | Content in columns 1–8; step 1 previews side by side; step 3 paragraph at 26 px; step 5 wall 5 per row |
| Tonight, Library, reader, source catalogue | As already specified in their sections (§8.8, §8.9, §8.14.1, §8.22) |
| Updates | One column across 8; from 900 px the NEW list takes columns 1–5 and the admin aside columns 6–8 |
| Collections / detail | Plates 2 per row (3:1 at ≥ 900); detail header 3:1, member wall 5 per row |
| History, Bookmarks | Log across 8 with a 56 px time margin; Bookmarks in two columns from 900 px |
| Feature page | The desktop spread on 8 columns (text 4, art 4); tabs below; At a glance at the top of DETAILS; thumb index hidden as on phones |
| Book page | Front matter in columns 1–5, the 168 × 248 plate in columns 6–8; contents full width |
| Discover | Index field across 8; genre tiles 3 per row; results rails at 5.2 posters; group jump as a sheet button |
| Sources | The desktop table without the `LANGUAGE` column |
| Downloads | Phone order; saved library in two columns from 900 px; the storage meter full width |
| Dialogue search | The desktop two-column block (still 4, transcript 4) |
| Picks | Ask block across 8; World grid 2 per row (3 from 900 px); the aside under the ask block |
| The Numbers | Stat blocks 4 across; charts across 8; clock and radar side by side (4 + 4) |
| The Annual | A centred 9:16 column at full height on `#000`, the rest of the screen black; tap thirds apply to the column; segments above the column |
| Circle, member page | Activity across 8, letters as a tab; from 900 px activity 5 columns and letters 3 |
| Index | Two columns with a column rule from 900 px |
| Settings | Phone structure below 900 px; from 900 px two panes: table of contents in columns 1–3 and the section in 4–8 |
| System status | Sections stacked; tables stay tables inside their own horizontal scroll |
| Recap | Recap text in columns 1–6, cast list in 7–8 (below it under 900 px) |

**Landscape phones** (height < 500 px): every screen honours the horizontal safe areas of §2.2.2 (the 32 px tablet margin becomes max(32, side inset + 8)); the readers follow §8.14.1 and §8.15.1; every other screen uses its tablet row when the width is ≥ 600 px, except The Annual (a centred 9:16 column) and takeovers with a typed headline, which keep the phone layout scrolled.

#### 8.0.10 Content that is no longer available

A deep link, notification, bookmark, history row, letter, cached link or restored tab can point at something the server now refuses: `series_not_found`, `source_not_found` (a connector removed under the "remove dead sources" rule), or a series or source that the active profile's 18+ gate hides (the server answers these the same way). Every such answer, on the feature and book pages, both readers, recaps, member pages and the source catalogue, shows one notice instead of the generic error: kicker `NOT IN THIS ISSUE`, headline typed "This series isn't available here any more." (catalogue: "This source isn't available here any more."), deck "It may have been removed from its source.", primary `Back to Tonight`, quiet `Search for it` (Discover with the title prefilled when the title is known). The wording is identical for removed and gated content, so the notice never reveals 18+. `source_not_browsable` is different: the catalogue shows "This source can only be searched, not browsed." with `Search it` (Discover scoped to that source).

---

### 8.1 Setup (server URL, iOS and Android only) · mobile S01 · G7

**Hierarchy.** Masthead → question → field → action.

**Phone layout.** Bare frame, 4-column grid. Top 20 vh: the wordmark (masthead lockup, 28 px) with its Oxford rule. Then kicker `FIRST, THE ADDRESS`, headline typed at 50 ms per character: "Where is your library?" (`type.headline`). Deck: "Type the address of your ManhwaManiacs server. It is checked before anything is saved." Field `Server address` (URL keyboard, `type.folio.lg` for the value, placeholder the default URL, submit on enter). Primary `Connect` full width, 48 px. Caption below: "HTTPS is required in release builds."

**Platform deltas.** iOS: `keyboardType: TextInputType.url`, autocorrect off. Android: same, IME action `go`. Web: screen does not exist (the web is served by its own server).

**Signature moment.** On success, the field's underline turns into the Oxford rule of the next screen: the underline thickens to 3 px and slides up to the masthead position (480 ms `turn`) as the login masthead fades in.

**Transitions.** In: from the native splash (§8.2), no animation beyond the typing. Out: the rule move above, then **Dip** to login.

**Gestures.** None beyond the keyboard.

**States.** Default; validating (`Connect` loading, field shows a leader dial, disabled field); error (field error line with the server's message, e.g. "No ManhwaManiacs server answered at this address."); success (the §7.3 `check` in `set`, held 400 ms (`dur.hold.connected`), then the signature move; the screen leaves before §7.3's `dur.hold.success` runs out). Error lines by cause: device offline (`connectivity_plus` reports none) "This phone is offline. Connect, then try again."; something answered `GET /health` but without `name: "ManhwaManiacs"` "That address isn't a ManhwaManiacs server."; TLS or certificate failure "The server's certificate isn't valid, so the connection was refused."; an `http://` address in a release build "Use an https:// address. Plain http isn't allowed in release builds."; timeout (8 s) "The server took too long to answer."

---

### 8.2 Splash and pre-roll · mobile S02 · web G2 (AuthPending) · brand §12.4

**Native layer.** A plain `#000000` frame with no mark, owned by neither skin, so it can never disagree with whichever skin (and icon) the app restarts into. `flutter_native_splash` 2.4.8 with `color: "#000000"` and no `image`; iOS `LaunchScreen.storyboard` is a black view; Android 12+ sets `windowSplashScreenBackground` and `windowSplashScreenIconBackgroundColor` to `#000000` and `windowSplashScreenAnimatedIcon` to `@drawable/splash_blank` (a transparent 1 × 1 vector), so the system splash does not draw the launcher icon, which the alternate-icon alias would otherwise swap. The Glass contract inherits this frame. The web knows the skin from the `mm-skin` cookie before paint, so it server-renders Cinematic's own monogram as inline SVG centred on `#000`.

**Pre-roll ("Press start").** The first Flutter frame fades the monogram in on the black (100 ms `dur.fade.first` `settle`; the web's first frame already shows it), then plays the logo reveal in §12.4. The session probe (`GET /auth/me`, 3 s timeout) runs underneath; the reveal and hand-off follow §12.4's duration rule; if the probe is still pending at 1180 ms the masthead holds, and after 2400 ms a 24 px leader dial appears under the Oxford rule with the caption `CONNECTING`. Tap anywhere skips to the hold.

**Warm start** (resumed within 4 h, or any web navigation after the first in a session, except a skin change): the masthead fades in and out over 200 ms each (`dur.clip`); no letters, no haptic.

**Outcomes.** Signed in with a remembered profile → Tonight (Dip). Signed in without a profile this session → Profile picker. Signed out → Login. Offline with a cached user → Tonight in the offline edition (banner §7.13). Server unreachable and no cache → Login's unreachable state. Remembered profile whose saved skin differs from the device mirror (`stack-decision.md` §2.4 step 4; only once `glass_available` is true), with no outbox `PATCH /profiles/{id}` carrying `skin` queued (a queued one wins and the restart is skipped, §8.30.3) → the reveal is cut at its current frame, 200 ms (`dur.clip`) of `#000000`, then the restart, and the other skin's splash plays; no confirm, no undo.

**Reduced motion.** Masthead fades in 300 ms (`dur.tapscroll`), holds until ready, fades out 200 ms (`dur.clip`).

---

### 8.3 Login · web R1 L1–L9 · mobile S03

**Hierarchy.** Cover lines (who and what) → form → secondary path.

**Desktop layout.** Bare frame on the 12-column grid, split like a magazine cover:
- Columns 1–7: a typographic **cover**. Top: the date line in `type.folio` (`TUESDAY 29 SEPTEMBER 2026 · No. 1`). Middle: the wordmark at masthead size with its Oxford rule. Below it three cover lines in `type.pull`, each revealed by letters in sequence 400 ms apart: "Every source, one shelf." / "Novels, read aloud by thirty-one voices." / "Your year in chapters." No cover images (covers need a session).
- Column rule (1 px `rule.1`) between 7 and 8.
- Columns 8–12: the form, vertically centred. Kicker `SIGN IN`; headline typed: "Welcome back." Server line for context (`type.caption` `ink.45`, "Server: manhwamaniacs.xyz"). Fields `Username` (autofocus) and `Password` (with Show/Hide). Switch row "Keep me signed in" (default on). Primary `Sign in` full width of the column. Error line under the button. Footer: "Need an account? **Create one**" (`link`, only when registration is open).

**Phone layout.** Masthead (28 px) + date line at the top; the three cover lines collapse to one (the first); the form fills the rest; the footer link sits above the keyboard.

**Variants.**
- *Bootstrap* (no accounts): kicker `FIRST ISSUE`, headline "Claim this server.", deck "Create the first account. It becomes the administrator." and the register form inline (§8.4, bootstrap variant).
- *Unreachable*: a `CORRECTION` notice: "We couldn't reach the server." + the API message + `Try again` (refetches bootstrap status) + on phones `Change server address` (quiet, to Setup).

**Platform deltas.** Mobile: tapping the server line copies the full base URL (toast "Copied https://…"). iOS: username field `textContentType.username`, password `.password` (keychain autofill). Android: autofill hints. Web: `autocomplete="username"` / `current-password`.

**Signature moment.** The cover lines setting one after another while the headline types; on a successful sign-in the form column dips while the cover's Oxford rule extends across the whole width (480 ms `settle`), handing off to the picker.

**Transitions.** In: from splash, Dip. Out: to the picker, rule extension then Dip; to Register, Page.

**Gestures.** None. **Keys (web).** `Enter` submits from either field; `Tab` order username → password → Show → switch → Sign in → Create one.

**States.** Signed out mid-session (any 401 except `invalid_credentials`, which the global handler ignores and leaves to the calling form, e.g. Change password, §8.30.4): the app dips to this screen with the toast "You've been signed out. Sign in to carry on."; resolving (masthead only, leader after 400 ms); normal; pending (`Sign in` loading, fields disabled); invalid credentials ("That username and password don't match." `proof`); account disabled ("This account has been turned off by the owner."); rate limited (`SLOW DOWN` line with countdown); unreachable; already signed in (redirect before paint). Bootstrap variant errors: `bootstrap_window_expired` "The window to claim this server has closed. Whoever runs the server has to create the first account."; `bootstrap_already_claimed` "Someone has already claimed this server. Sign in instead." (the form switches to Sign in).

---

### 8.4 Register · web R2 RG1–RG5 · mobile S04

**Layout.** Same cover + form split as Login (desktop), same phone stack. Kicker and headline by variant:
- *Open*: `JOIN` / "Join this library." Footer: "Already have an account? **Sign in**".
- *Bootstrap*: `FIRST ISSUE` / "Claim this server." Button `Create the administrator account`.
- *Invite required*: as Open plus the `Invite code` field ("Ask whoever invited you").
- *Closed*: a notice: kicker `REGISTRATION CLOSED`, headline "This library isn't taking new readers.", deck "Ask the owner to create an account for you, then sign in.", primary `Back to sign in`.

**Fields.** Username (autofocus; helper "3–64 letters, digits, dots, dashes or underscores, starting with a letter or digit.", the backend's `^[A-Za-z0-9][A-Za-z0-9_.\-]{2,63}$`, checked live so the error appears before submit), Password (helper "At least 8 characters"), Confirm password (live "Passwords don't match." once both have content), Invite code (conditional), Display name (optional, "How your name appears"), Email (optional, validated), switch "Keep me signed in". Primary `Create account`. Server-code errors mapped to copy: `username_taken` "That username is taken.", `invalid_username` (the helper line turns `proof`), `invite_code_invalid` "That invite code isn't valid.", `invite_code_required`, `registration_disabled`, `weak_password`, `bootstrap_window_expired` and `bootstrap_already_claimed` (as §8.3), `rate_limited` (countdown).

**Platform deltas.** Mobile shows a back arrow in the running head (to Login); web uses the footer link. Password managers get `new-password`.

**Transitions.** In from Login: Page. Out on success: to the picker (Dip), and the new account lands on "Create your first profile" (§8.5 empty state).

**States.** Resolving, unreachable (`CORRECTION` notice + Try again), each variant, pending, field errors, server errors.

---

### 8.5 Profile picker: "Who's reading tonight?" · web R3 P1–P8 · mobile S05 · G3

**Hierarchy.** Question → cast (profiles) → add → manage → switch account.

**Desktop layout.** Takeover on `#000`. Top: the wordmark small (20 px) left, `Manage` (quiet) and `Switch account` (quiet, signs out after a dialog) right. Centre: headline typed at 50 ms per character, `type.masthead`: "Who's reading tonight?" (time-aware: "this morning" 05:00–11:59, "this afternoon" 12:00–17:59). Below, the cast: up to five 144 px avatars in a centred row, 48 px apart, each with the profile name in `type.subhead` italic and a credit line in `type.caption` `ink.45` that shows only "NEW" for a profile with no sessions and is empty otherwise (no last-read time: the picker is seen before any profile is chosen, so it never publishes a profile's reading activity, which is shared only through Circle's opt-in `Share what I'm reading`). An 18+ profile shows the 20 px certificate (the §7.19 badge) at its avatar's bottom-right. "Add profile" is a 144 px circle outlined 1 px `ink.45` with a `plus` 32 Light, label "New profile" (hidden at 5 profiles).

**Phone layout.** Headline 40 px on two lines; profiles in a 2-column grid of 112 px avatars, 32 px row gap; Add as the last cell; Manage in the running head, followed by a `dots-three` overflow with `Switch account…` (the same sign-out dialog as desktop: "Switch account? You'll be signed out on this device; saved chapters stay.").

**Signature moment: the Iris.** Tapping a profile:
1. Its avatar's ring draws a 2 px `spot` circle clockwise (320 ms `set`); other profiles fade to 20 % and blur 4 px (320 ms).
2. A black **iris** closes on the chosen avatar: `clip-path: circle()` on the whole takeover shrinks from the viewport's diagonal to the avatar's radius (480 ms `turn`); haptic `profile.select` as it lands.
3. The next screen (Tonight, or onboarding for a brand-new profile) opens with an **iris out** from the same point (circle 0 → covering, 560 ms `dur.iris.out` `settle`) while its headline starts typing.
4. If the profile's saved skin is Glass, the restart happens inside the black at step 2's end (stack-decision §2.4), with no confirm and no undo, and Glass's splash plays instead of step 3. (Only once `glass_available` is true, §8.0.7. A profile pick never changes the app icon, §12.3.)
Tap during the iris skips to step 3. Reduced motion: 200 ms (`dur.clip`) cross-fade.

**Profile-scope recovery.** Any `profile_required` or `profile_not_found` answer clears the active profile and lands here with the toast "That profile isn't available any more. Choose another."; switching profiles drops every profile-scoped cache, so the next screen re-enters its skeleton.

**Manage mode.** `Manage` toggles: every avatar gets a `pencil-simple-line` 24 overlay on a 50 % black disc; tapping opens Edit. Long-press (phone) or right-click (desktop) on any profile also opens Edit.

**Transitions.** In: from login (Dip), from the profile chip or Index (Dip). Out: Iris.

**Gestures.** Tap select; long-press edit. **Keys (web).** `←`/`→` between profiles, `Enter` selects, `e` edits the focused profile, `n` new profile, `m` toggles manage.

**Never auto-skipped.** The picker shows whenever no profile is active on this device (after sign-in, after `Switch profile`, after a `profile_required` or `profile_not_found` answer), **even when the account has only one profile**, because it is also the skin gate: the chosen profile's saved edition is resolved here and a restart into Glass happens inside the iris (step 4). A single profile renders as one centred 144 px avatar plus the New profile circle; `Enter` picks it. The only way past the picker is a profile already remembered on this device (web K48, mobile K27), whose edition is checked against the profile payload at boot instead (`stack-decision.md` §2.4).

**States.** Loading (five flicker circles); one profile (as above, never skipped); empty ("Create your first profile." notice: kicker `EMPTY HOUSE`, deck "Profiles keep follows, progress and moods apart for everyone on this account.", primary `New profile`); error with no cached profile (`CORRECTION` notice + Retry); unreachable with a cached profile (headline, deck "The server isn't answering. Continue as {name}, or retry.", a single avatar to continue offline, `Retry`); limit reached (Add hidden; tooltip on Manage "5 profiles is the limit").

---

### 8.6 Profile form and Manage profiles · web PF1–PF8, PM1–PM8 · mobile S06, S07

**Profile form** (new and edit; route `/profiles/new`, `/profiles/:id/edit`; a column panel on desktop, a full page on phones).

- Masthead: kicker `CASTING`, title "New profile" / "Edit {name}".
- Live preview: the 96 px avatar with the chosen mood grade glowing behind it (the grade fills the top 30 vh live).
- `Name`: a big `type.field` input (Bodoni Moda Italic 28–36), max 30 characters with a folio counter `12/30`.
- `Avatar`: a 6 × 2 grid (4 × 3 on phones) of the 12 avatars at 56 px; selected gets the spot ring; each has its name as a tooltip and `aria-label`.
- `Mood`: 7 slug-line chips each preceded by a 10 × 10 square of the grade colour with each sRGB channel × 3 for visibility: romantic `#4E2130`, action `#4E2718`, comedy `#45391E`, horror `#2D1E27`, slice_of_life `#2D3624`, fantasy `#362448` (`default` shows no square); helper "Grades the top of the app while this profile is active. Never the reader."
- `Mature content (18+)`: a switch; turning it on opens the certificate (§7.24) exactly like Settings does. When the name field is still empty, the certificate's headline reads "Show mature content on this profile?".
- `Edition`: the segmented control (§7.5) `CINEMATIC │ GLASS`, labelled with the kicker `EDITION`, caption "The look of the whole app for this profile." (writes `reading_profiles.skin`). Hidden while `glass_available` is false (§8.0.7). On a new profile, or when the edited profile is not the active one, the change is saved with the form and applies the next time the profile is picked (inside the iris, §8.5 step 4). When the edited profile **is** the active one and the edition changed, `Save changes` saves every other field first, then opens the §8.30.3 confirm ("Restart in Glass?"); confirming runs Stop the press, and `Stay in Cinematic` keeps the other saved fields and leaves the edition as it was.
- Actions: `Create profile` / `Save changes` (primary), `Cancel` (quiet). Edit adds a `destructive` `Delete profile` at the bottom, confirmed by a dialog ("Delete {name}? Its library, progress, bookmarks and collections go with it. This can't be undone."). Deleting the active profile clears it on this device and lands on the picker (Dip) with the toast "Deleted {name}."; deleting another profile returns to the previous screen.
- States: loading (edit), not found (notice "This profile no longer exists." + Back), save pending, name empty error, `profile_limit_reached`, `invalid_profile_name`, server error.

**Manage profiles** (`/profiles/manage`; reachable from the picker's Manage, Index → Profiles and Settings → Profile & account, so it is reachable on every platform).

- Masthead `Profiles`, deck "Up to five reading profiles on this account."
- List of rows: 44 px avatar, name (`type.title`), caption "{Mood} mood · 18+ on/off", `CURRENT` badge on the active one; trailing `Use` (quiet, instant switch without the iris), edit, delete; drag handle to reorder (`sort_order`).
- `New profile` primary (disabled at 5).
- States: loading (5 greeked rows), error notice, empty notice.

**Transitions.** Page in/out; after saving, back to the previous screen with a toast "Saved {name}".

**Keys (web).** `Enter` saves; `Esc` cancels; in the manage list `Alt+↑/↓` reorders.

---

### 8.7 Onboarding: the first issue (new profile) · new

Shown once per new profile after the iris, skippable at every step (`Skip` quiet in the running head; skipping all lands on Tonight's new-profile state). Route `/welcome?step=n`. A takeover with a folio progress line at the top: `1 / 5` in Plex Mono plus five 24 × 2 rules (filled `spot` for done steps). While `glass_available` is false the Edition step is skipped: the route runs `step=2..5` and only the visible folio renumbers, `1 / 4` … `4 / 4` with four rules (§8.0.7). The five-step numbering (1 Edition, 2 Formats, 3 Genres, 4 Art style, 5 Seeds) is canonical for the route, the backend `step` and `onboarding_step`.

**The 18+ gate here.** New profiles start with the gate closed, and every list in onboarding comes from gated server data, `GET /onboarding/catalog` (see **Backend** below), never from pins or `for_you` (a new profile has neither): the format mosaics, the genre paragraph (the union of every browsable source's genre labels, with mature sources' genres excluded for a gated profile) and the seed wall. So mature genres such as Smut or Ecchi are simply absent unless the profile form opened the gate first, in which case they are included like any other. The paragraph always sets 30–40 of whatever remains, ordered by popularity (all of them when fewer than 30 remain), and re-flows as a justified paragraph at any count.

**Resume.** Every `Next` saves the step and the answers so far with `PUT /profiles/{id}/taste {step, …}` (partial saves allowed). If the app is killed or the tab closed mid-way, the next time this profile is picked the iris opens `/welcome?step=n` at the saved step with its answers restored; `Skip` or `Print my first issue` sets `step: "done"`, after which onboarding never shows again for the profile.

| Step | Kicker / headline (typed) | Content | Data |
|---|---|---|---|
| 1 Edition | `YOUR EDITION` / "Pick how the app looks." | Two live previews side by side (desktop) or stacked (phone): Cinematic's Tonight and Glass's home, each the edition preview of §8.30.3 (web: the `/skin-preview/{skin}` iframe; app: the bundled 36-frame PNG loop); the current one marked `THIS EDITION`. Choosing Glass here defers the restart to the end of onboarding. | `reading_profiles.skin` |
| 2 Formats | `FORMATS` / "What do you read?" | Four tall typographic tiles `Manhwa`, `Manga`, `Manhua`, `Novels` (novels only when enabled), each a 2:3 plate with a duotone mosaic of 3 trending covers for that format and the word in Bodoni Moda Italic 32 on the solid end colour of the tile's `scrim.foot` (§2.1.4); multi-select with the spot inset frame | catalog `formats[].covers`; taste `formats[]` |
| 3 Genres | `GENRES` / "Tap once to like, twice to love, hold to skip." | **The genre paragraph**: 30–40 genre names set as one justified paragraph of Bodoni Moda Italic 28 (22 on phones), separated by thin spaces. Tap once: `ink.100` + 2 px `spot` underline (like). Tap twice: a `spot.wash` highlighter sweeps behind the word (love). Hold 450 ms: 1 px `proof` strike-through + `ink.45` (skip), with the state in the accessible name ("Romance, skipped"). Each state is also reachable by a small menu on right-click/long-press for screen readers ("Like, Love, Skip, Clear"). | taste `genres{name: 1\|2\|-1}` |
| 4 Art style | `ART STYLE` / "Which of these do you like the look of?" | 9 unlabelled panel crops (3 × 3 grid, square) from bundled sample art: full-colour painted webtoon, crisp cel, black-and-white screentone, manhua 3D, sketchy indie, retro 90s, soft pastel, high-contrast noir, chibi. Multi-select with the spot inset frame; each crop has an `aria-label` describing the style. Files: `mobile/assets/onboarding/styles/01-painted.webp` … `09-chibi.webp` and the same names under `frontend/public/onboarding/styles/`, 600 × 600 WebP at quality 80, ≤ 60 KB each. Source: original panels drawn for ManhwaManiacs (commissioned as work for hire and released by the artist under CC0 1.0; no crop from any source or publisher is ever bundled), each file's artist, date and licence recorded in `LICENSE.md` beside the files and listed in About → Licenses. Until the nine files exist, the step ships as typographic plates: each style's name set in Bodoni Moda Italic 24 on `paper.1` with a one-line description in `type.caption`, and the same `styles[]` values. | taste `styles[]` |
| 5 Seeds | `YOUR FIRST ISSUE` / "Choose three or more to start." | A poster wall seeded from steps 2–4 (catalog `seeds`, 24 titles). Each pick inserts 3 similar posters right after it (`GET /ai/similar?anilist_id=`, Set stagger); a folio counter `3 / 3 PICKED` turns `set` at three. Primary `Print my first issue` enables at 3 picks. | follows for picked available titles; `taste.seeds[]` |

**Finish: "Cut to home".** `Print my first issue` follows every picked available title (`POST /library/follow`, 4 at a time), saves the taste, and types "Printing issue No. 1…" in `type.masthead` over a running indeterminate rule while the wall stays visible beneath at 30 % brightness. When the follows are done and `GET /home` has answered:

1. The wall's unpicked posters and the typed line fade to black (240 ms `ease.lift`).
2. Tonight mounts underneath at rest, its first section `01 Your first picks` (the followed seeds, `NOT STARTED` captions) with empty slots.
3. The picked posters **fly** from their wall rects into their slots in that rail: each a match cut of 480 ms `ease.turn`, staggered 60 ms in the order they were picked (flight layer `z.shutter`). A poster whose slot is off screen flies to the rail's right edge and fades on arrival.
4. After the last poster lands, the masthead kicker sets, the cover story racks into focus and its headline types ("Tonight: start Omniscient Reader.", §9.1.2 case 4b), handing over to the normal Front page moment (§8.8).

If Glass was chosen in step 1, the restart is deferred to the end: steps 2–5 run in Cinematic, `Print my first issue` saves the taste and the follows as above, and then, instead of the flight, Stop the press runs (§8.30.3, no confirm, because step 1 was the choice) and the app restarts into Glass's home. Failures: a follow that fails is dropped from the flight and a toast says "Followed 4 of 5. One couldn't be added."; if `/home` fails, Tonight's error state appears after a Dip. Reduced motion: a 200 ms (`dur.clip`) cross-fade into Tonight. Web: FLIP with Motion `animate` on cloned poster nodes in a fixed overlay (source rects read before the route swap, target rects after Tonight's first layout). Flutter: an `OverlayEntry` flight of `RawImage` copies driven by one `AnimationController` (duration 480 + 60 × (n − 1) ms) with per-poster `Interval`s; target rects from `GlobalKey`s on the rail's slots.

**Platform deltas.** Phones use a horizontal pager between steps with swipe (the step is committed on Next, not on swipe alone); desktop uses `Next` / `Back` buttons and `→` / `←`.

**States.** Loading: step 2 shows four 2:3 galley plates (flicker) with the format words already set; step 3 shows a greeked paragraph (six justified lines of bars at the paragraph's line height); step 5 shows twelve flicker plates in the wall, replaced by posters with a 160 ms dissolve as they arrive. Catalog unreachable at steps 2 and 5 (`GET /onboarding/catalog` fails): tiles show typographic plates without covers and step 5 becomes "Follow series later from Discover." with `Finish`. AI unavailable: the taste is saved, the wall still comes from the catalog, and a pick inserts no similar posters. Fully offline (no network at all): the Edition step works when it is shown (its previews are bundled); every catalog step (2–5) shows a notice, kicker `OFFLINE EDITION`, "Finish when you're back online." with `Skip for now` (to Tonight's offline edition); the saved step is kept, so the next online pick of the profile resumes at the saved step, or at step 2 if none was saved (this overrides the `NULL` rule under Backend, because the Edition step was already shown).

**Backend.** `PUT /profiles/{id}/taste {step, formats, genres, styles, seeds}` (new; partial bodies merge; `step` is `1`–`5` or `"done"`; used by the home feed, §9.1.7). `formats[]` and `genres {name: 1 | 2 | -1}` are as in the table; `seeds: [{anilist_id} | {source_id, series_key}]`; `styles: ["painted" | "cel" | "screentone" | "manhua-3d" | "sketch" | "retro" | "pastel" | "noir" | "chibi"]`, the nine crops of step 4 by file name. `GET /profiles` rows gain `onboarding_step` so the picker knows where to resume. When the column is added, the migration sets it to `"done"` for every existing profile; new profiles default to `NULL`, which means the first shown step (1, or 2 while `glass_available` is false).
- `GET /onboarding/catalog?formats=&genres=&styles=` (new) returns `formats: [{format, covers: [cover_url × 3]}]` (AniList trending per format); `genres: [{name, weight}]`, 30–40 entries, the union of every browsable source's `GET /sources/{id}/genres` labels, de-duplicated case-insensitively, with mature sources' genres excluded for a gated profile; and `seeds: WorldItem[]`, 24 items from AniList trending filtered by the liked and loved genres, `available` items first, `is_adult` excluded unless the gate is open. Cached 24 h per (gate, formats, genres). Step 3's paragraph and step 5's wall read from it.
- `GET /ai/similar` also accepts `anilist_id` and returns the §9.1.7 envelope with 3 WorldItems in `items` for step 5's "insert 3 similar" (budget-free, cached 7 days).

---

### 8.8 Tonight (home) · new AI home · the landing screen · covers LS4–LS5, recently-updated, world recs, stats teaser

Full AI behaviour, recap and states are in §9.1; this is the layout contract.

**Hierarchy.** The cover story (one series, one decision) → Also in this issue (three features) → numbered sections (rails) → the numbers teaser.

**Desktop layout** (12 columns):
1. **Running head** transparent over the spread.
2. **Cover story spread** — height `clamp(560px, 72vh, 820px)`.
   - Columns 1–5 (text): kicker `TONIGHT · No. 184` (the issue number is days since the profile's first recorded session, +1); the **main headline**, typed at 50 ms per character with the spot caret (§10.2), `type.cover` (e.g. "Tonight: chapter 143 of Omniscient Reader."); deck (`type.deck` `ink.60`, the AI one-liner or the synopsis's first sentence); `Credits` (STORY, ART, SOURCE with health mark, STATUS, NEW CHAPTERS); actions: `split` primary `Continue │ CH 143 · p.1`, `secondary` `Previously on…` (only when `cover.recap.available`, §9.1.5), `quiet` `Details`.
   - Columns 6–12 (art): the series cover at full spread height, placed against the right edge; the space to its left is the same cover at `blur.bleed`, duotoned to `ambient.duo`; `scrim.gutter` over columns 6–7; grain at 0.06 (overlay blend; web recipe in §15.2) on the art only; `scrim.vignette`; **Drift** on the cover. Clicking the art opens the feature page (match cut); double-clicking it opens the Lightbox (§7.30).
   - A 2 px `spot` progress rule runs along the bottom of the art for the chapter in progress.
3. **Also in this issue** (below the spread, 64 px gap): three **Feature** cards across 4 columns each, e.g. "3 new chapters of *Tower of God*", "Because you finished *Solo Leveling*", "Riya recommends *Lookism*". Kicker per card names the reason (`NEW THIS WEEK`, `BECAUSE YOU READ`, `FROM THE CIRCLE`, `ALMOST THERE`). **Selection** (composed by `GET /home` as `also: [{kind, source_id, series_key, headline, deck, ambient}]`, and by the same rules locally when the feed is unavailable): walk this priority list and take the first candidate of each kind, then fill any remaining slots from the list in order, never repeating a series and never using the cover story's series: (1) `new_chapters`: the followed series with the most unread new chapters; (2) `because`: the top `Because you read` pick (AI or world recs); (3) `letter`: the newest unopened letter; (4) `almost_there`: the followed series with the fewest chapters left. Three cards: 4 + 4 + 4 columns. Two: 6 + 6 (phone pager of two). One or none: the row is not rendered (its candidate still appears in its own section).
4. **Numbered sections**, each a rail with the folio + H3 letter reveal, in this order. A section with nothing to show is not rendered, and folios are assigned to the rendered sections in order, so the numbering never has a gap (the section keys below are the `GET /home` section `type`s, §9.1.7):

| Section (key) | Contents | Shape |
|---|---|---|
| `Continue reading` (`continue`) | Chapters in progress, most recent first, up to 12; never a finished Completed series (§8.14.6 The end) | Cuttings (§7.6) with nudge badges `3 NEW`, `ALMOST DONE`, `PAUSED 21 D` |
| `New this week` (`new_this_week`) | Followed series updated in the last 7 days | Posters with `NEW` badges |
| `Almost there` (`almost_there`) | Followed series with reading status Reading and 3 or fewer chapters left to the latest | Posters; caption folio `2 LEFT` in `spot`; up to 12, fewest left first |
| `Where were we?` (`where_were_we`) | Series with reading status Reading, last read 21–120 days ago, not finished | Posters; caption folio `3 WEEKS AGO · CH 87`; long-press offers `Previously on` first (only when that item's `recap.available`, §9.1.5); up to 12, most recent first |
| `Sent to you` (`sent_to_you`) | Unopened and kept recommendation letters (§9.3.4), newest first | Posters with the sender's 20 px avatar at bottom-left; under the H3, the newest letter's note **typed** at 50 ms per character in `type.body.italic` `ink.60` ("Riya: you'll love the tower arc."), max 140 characters |
| `Picked for you` (`picked`) | AI picks for this profile | Posters; `why` lines in the hover slate and Quick look |
| `Because you read {title}` (`because`) | One rail per seed, 1–3 rails | World cards in poster form |
| `From the Circle` (`circle`) | What sharing members are reading (§9.3) | Posters with an avatar stack |
| `Most read in the circle` (`circle_top`) | Ranked this week across sharing profiles, 18+ gated per viewer | Ranked posters |
| `Sources` (`sources`) | Pinned source hubs | 16:9 duotone tiles, source name in `type.subhead`, three newest covers as a strip; hover and pressed as the §7.6 Feature card (image zoom 1.04 inside the frame + name underline, 200 ms `dur.clip` `settle`; pressed a 1 px impression) |
| `Your genres` (`genres`) | Genre weights from `/library/recommendations` | Slug line of genre links weighted by size |
| `This week in numbers` (`numbers`) | Streak flame (tiered, §9.2.2) + days, chapters this week, time read, `Open The Numbers →` | Stat strip |

5. Footer: a 1 px rule and `type.caption` "Issue No. 184 · compiled 21:04 · Refresh `r`".

**Scrub the trailer (the cover story compresses into the running head).** As the spread scrolls away, the last 240 px of its travel (from the moment its bottom edge is 240 px below the running head's bottom edge until it reaches it) drive a scroll-linked compression, `p` = 0 → 1, frame for frame in both directions and never on a clock:
- The sharp cover's rect interpolates (FLIP transform, `ease.linear` against `p`) from its place in columns 6–12 to a 32 × 48 thumbnail slot in the running head; the `blur.bleed` field, grain and Drift fade out by `p` = 0.3 and pause.
- The text column rises 12 px and fades out by `p` = 0.55.
- The running head grows from 56 to 64 px (phone: 44 to 64 px, Android 48 to 64 px, plus the status inset) and turns `#000000` with its 1 px `rule.1` bottom.
- From `p` = 0.6 to 1 the **now-showing strip** fades in inside the running head, between the breadcrumb and the search trigger (phone: after the thumbnail, replacing the running title): the thumbnail, kicker `NOW SHOWING` (`type.kicker` `ink.45`), the series title (`type.title`, one line), and on the right a `split` primary at size sm (32 px) `Continue │ CH 143` (Column wipe, as the cover story's button) plus `Previously on` (`quiet`) when `cover.recap.available` (§9.1.5). The progress rule becomes a 2 px `spot` rule along the strip's bottom edge.
- At `p` = 1 the strip is pinned (`z.sticky` inside the running head) for as long as Tonight is scrolled below the spread; scrolling back up un-compresses it exactly.
- The desktop breadcrumb fades out as the strip fades in and stays hidden while the strip is pinned (the strip names the page).
- Below 1440 the search trigger also collapses to a 44 px `bare` `magnifying-glass` button (tooltip "Search or jump" + the platform `mod+k` keycap, §7.26), `Previously on` moves into a `dots-three` overflow at the strip's right end, and the title truncates with an ellipsis at a 120 px minimum.
- Phone frame: the thumbnail, then the title (one line, min 96 px, no kicker), then a `split` sm reading `▸ CH 143` (44 (48 Android) hit), then `dots-three` holding `Previously on`.
- **Focus during the scrub.** At `p` ≥ 0.55 the spread's text column becomes inert (web `inert`; Flutter `ExcludeFocus` + `ExcludeSemantics`). The strip's controls join the tab order at `p` ≥ 0.8, where their opacity is ≥ 0.5. If focus was inside the column when it went inert, it moves to the strip's `Continue` once `p` ≥ 0.8, and before that to Tonight's `main` region (`tabIndex={-1}`). Scrolling back below `p` = 0.55 reverses all of this. Under reduced motion the switch happens when the strip fades in.

Web: Motion ``useScroll({ target: spreadRef, offset: [`end ${headBottom + 240}px`, `end ${headBottom}px`] })``, where `headBottom` is the running head's resting bottom edge (56 px on desktop; 44 px plus `env(safe-area-inset-top)` in the phone frame) with `useTransform` on `scrollYProgress`; the source and target rects are measured once per layout (ResizeObserver) and applied as a transform so nothing reflows. Flutter: the spread is a pinned `SliverPersistentHeader` (maxExtent = spread height, minExtent = 64 + top inset); the delegate maps `shrinkOffset` to `p = clamp((shrinkOffset − (maxExtent − minExtent − 240)) / 240, 0, 1)` and lays the spread and the strip out at `p`. The strip's controls enter the tab order at `p` ≥ 0.8 and the text column goes inert at `p` ≥ 0.55 (`ExcludeFocus` + `ExcludeSemantics`), as in "Focus during the scrub" above. Reduced motion: no compression; the strip fades in over 150 ms (`dur.reduced`) once the spread has scrolled under the running head.

**Tablet (768–1023 web, 600–1023 app).** The spread uses 8 columns (text 4, art 4); Also in this issue becomes 2 + 1.

**Phone layout.**
1. Cover: full-bleed cover art 4:5 (max 70 svh) with `scrim.foot` into `ambient.tint`, Drift, grain. Over its lower third: kicker, typed headline in `type.cover` (44/44, up to 3 lines), deck (2 lines).
2. Actions under the art: `split` primary full width; then a row of `secondary` `Previously on` (only when `cover.recap.available`) and `quiet` `Details`.
3. Also in this issue: a horizontal pager of three Feature cards, each 86 % of the viewport width, centred, 12 px apart, so about 21 px of each neighbour shows at 390 px. Flutter: `PageView(controller: PageController(viewportFraction: 0.86))` (default `padEnds`), each page with 6 px horizontal padding. Web: Embla `align: "center"` with its viewport spanning the full screen width (outside the grid margins, like the PageView), slides `flex: 0 0 86%` with `padding-inline: 6px`.
4. The numbered sections as rails (3.2 posters), 40 px apart; `Sent to you` sets its typed note in two lines under the H3.
5. Pull to reprint.
6. The trailer scrub as above: the 4:5 cover compresses into the thumbnail of a 64 px now-showing strip under the status bar.

**Platform deltas.** iOS/Android: the running head is transparent until the cover scrolls away; the status bar stays light. Mobile web: identical, pull to reprint implemented in pointer events. Desktop: dwell on a rail poster for 400 ms swaps the spread's backdrop and ambient colour to that series (**Dissolve**, while the spread is ≥ 30 % in view) without changing the headline.

**Signature moment.** "Front page": the Oxford rule draws under the running head, the cover racks into focus, and the headline types itself with the spot caret while the credits set in reading order. It plays once per day per profile; later visits the same day show everything at rest.

**Transitions.** In: Iris (from picker), Cut (tab), Dip (desktop sidebar), Dip from readers. Out: match cut to feature pages, Column wipe on `Continue`.

**Gestures.** Pull to reprint; long-press posters and cuttings for Quick look; long-press the cover art for the Lightbox (§7.30); horizontal pager; tap the headline to skip typing; the scroll itself drives the trailer scrub.

**States.**
- *Loading*: galley proof of the whole page (headline bars at `type.cover` height, the art plate flickering, rail plates with titles as cards when known). The masthead kicker is live from the start.
- *New profile, nothing read*: headline "Your first issue starts here."; deck "Follow three series and this page fills itself in."; primary `Find something` (to Discover); sections become `Popular on your sources` (source browse "popular" of pinned sources), `Sources`, `Genres`. **With 0 pins** (every new profile, since pins are per profile) the feed uses the 3 healthiest non-18+ sources of the current content kind (`health.status == "ok"`, fewest `consecutive_failures`): `popular` and cover-story case 5 take their `popular` browse mode, first 12 titles; `sources` shows these 3 as hubs captioned `SUGGESTED SOURCES`; `genres` uses the taste genres from onboarding (loved first) and is not rendered when there are none.
- *Just onboarded (follows, nothing read)*: the cover story is the first pick with `Start │ CH 1` and the headline "Tonight: start Omniscient Reader." (§9.1.2 case 4b); section 01 is `Your first picks` (the followed seeds, captions `NOT STARTED`), then `Popular on your sources`, `Sources`, `Genres`. This is the page the onboarding picks fly into (§8.7).
- *Streak at risk* (after 20:00 local time, a streak of 2 days or more, nothing read today, i.e. `streak.last_active_date` is before local today, §9.2.2): the headline becomes the at-risk line, typed in sentence case: "Twelve days and counting. One chapter keeps it alive." (the count opens the sentence, so it is spelled out: "Two", "Twelve", "Thirty-one"; this is the one exception to the numerals rule in §12.5). When the spelled line would exceed 60 graphemes (every count ≥ 101 spelled with "and"), the headline becomes "Your {n}-day streak ends at midnight." with the count as a numeral, since it no longer opens the sentence ("Your 123-day streak ends at midnight.", 37 graphemes); deck "Open any chapter before midnight to keep your streak."; a 16 px at-risk flame (§9.2.2) in `spot` sits before the kicker; the cover story stays the series chosen by §9.1.2 so its `Continue` keeps the streak. In-app only: no push notification exists for it.
- *Caught up everywhere*: headline "Tonight: you're caught up."; deck "Nothing new on your shelf. Here's something else."; the cover story is the top AI pick with `Start │ CH 1`.
- *AI unavailable / not configured / over budget*: the cover story is chosen locally (§9.1.6), the deck is the synopsis, Picked for you becomes `From your shelf` with a `NOTE` line.
- *Offline*: headline "Offline edition."; deck "Only what's saved on this device is here."; sections `Saved on this device` and `Continue (saved chapters)`, both filtered by the 18+ gate on the device (§7.24); everything else hidden.
- *Novels mode*: every section and the cover story come from novels only (§8.0.8); a novel cover story uses the typographic title-page spread of §8.0.8.
- *Error*: `CORRECTION` notice with Retry; rails that loaded stay.
- *Stale*: rails whose payload is stale show the `SAVED COPY` badge.

**Keys (web).** `r` reprint; `↓`/`↑` move between sections; rails as §7.8; `c` continues the cover story (Column wipe; also from the now-showing strip); `p` opens Previously on; `v` opens the cover in the Lightbox; `Enter` on the headline skips typing.

---

### 8.9 Library: the shelf · web R5, R6 (LS1–LS12, LB1–LB26, BA1–BA10) · mobile S08, S09 · M1

One screen holds the shelf and the full browse toolbar, so filtering the library is always one tap away on every platform.

**Hierarchy.** Masthead → hub tabs → toolbar → Continue cuttings → the wall.

**Desktop layout.**
- Masthead: kicker `No. 02 — YOUR SHELF`, title "Library", deck "212 series · 14 with new chapters · 3 favourites" (novels: "38 books on your shelf").
- Hub tabs (sticky): `01 SHELF · 02 UPDATES ³ · 03 COLLECTIONS · 04 HISTORY · 05 BOOKMARKS` (each its own route).
- Toolbar (one line, wraps at 1024): status slug line `ALL · READING · NOT STARTED · DONE · ON HOLD · PLAN TO READ · DROPPED` (the §7.19 vocabulary) + `★ FAVOURITES` toggle + `NEW ONLY` toggle + `TAGS ▾` (a menu of the profile's own tags as a multi-select checklist, matching series that carry any selected tag; the active tags then show as removable tokens after the slug line; the menu's footer item `Manage tags…` opens the tag sheet below; hidden when the profile has no tags); right side: compact search ("Search your shelf", `/`), Sort menu (`Recently updated`, `Recently added`, `Recently read`, `Title A–Z`, `Most unread`, `Manual order`), density segmented (`WALL │ COMPACT │ LIST`, manga only), `Select` (quiet with icon). Every sort and filter runs on the server over the whole library, never client-side over the 200-row page: `Recently read` = `sort=-last_read_at`, `Most unread` = `sort=-new_count`, `NEW ONLY` = `new_only=true`, tags = `tag_ids=1,4` (additions to `GET /library/series`, §15.5). A `quiet` `Clear filters` appears at the end of the status slug line whenever a status other than `ALL`, `★ FAVOURITES`, `NEW ONLY`, a tag or a search is active. `Esc` in the search field clears only the search.
- **Tag sheet** (`Manage tags…`, also the feature page overflow `Tags…` → its `Manage` link): a sheet (column panel on desktop), kicker `TAGS`, one row per tag: the name as an inline-editable field (Enter saves through `PATCH /library/tags/{id}`, new in §15.5), and a trailing `trash-simple` that asks "Delete the tag {name}? It comes off every series." (arm delay, §7.10; `DELETE /library/tags/{id}`); `New tag` (quiet) at the bottom. Tag `color` is kept as stored but not drawn: in this skin tags are typographic slug tokens. States: loading (greeked rows), empty ("No tags yet. Add one from a series page."), error line per row.
- **Continue reading** (only with no filter or search): a §7.8 rail of up to 12 cuttings (3:2; the existing `GET /library/continue-reading?limit=12`, whose rows gain `recap`, §9.1.5, so a cutting's Quick look and `Continue` follow the Previously on setting): 4 visible at desktop, 5 at wide, paddles on hover.
- **The wall**: posters with captions below; wall 6 per row at desktop (8 at wide), compact 8 (12), list rows 72 px with 48 × 72 covers and columns for title, status badge, progress `CH 12 OF 40`, new count, last read, favourite star, notify bell.
- Manual order: in `Manual order` sort, posters show a drag handle at bottom-left on hover (§7.7) and can be reordered (writes `sort_order`); `Alt+arrows` moves the focused poster.
- Novels mode: the wall becomes the **book list** (§8.9.1).
- Mobile's cover-size slider (mobile K15) migrates to density: values below 0.85 become `COMPACT`, the rest `WALL`.
- Overflow note when > 200: a caption line "Showing the first 200 of 212 — narrow it with search or a filter."

**Phone layout.** Masthead (40 px) with the content-mode chip in the running head; hub tabs as a horizontally scrolling contents row (swipeable panels); toolbar collapses to: status slug line (scrolling) + a `Filters` quiet button opening a sheet (favourites, new only, sort, density, reading status with the slug line's labels, and a `TAGS` section: a multi-select checklist of the profile's tags, hidden when there are none, whose last row `Manage tags…` opens the tag sheet) + search icon (expands a compact field) + `Select`. Active tags show as removable tokens after the status slug line, and the `Filters` button shows the number of active filters as a superscript folio (`Filters ⁽²⁾`). Continue: a pager of cuttings at 86 % (the same geometry as Tonight's Also in this issue pager, §8.8). Wall: 3 columns (tablet 5), captions below. Pull to reprint.
- Density on phones: WALL 3 per row, COMPACT 4 per row (web 600–767 and app tablets: WALL 5, COMPACT 7).
- LIST rows on phones are 72 px: a 48 × 72 cover, then the title (`type.title`, 2 lines) over the folio caption `CH 12 OF 40 · 3 NEW`, then the reading-status badge at the trailing edge. The favourite, notify and last-read columns are desktop-only (Favourite and Notify stay in Quick look).
- COMPACT at every width has no caption below. The title is in `aria-label` and, on desktop, in a tooltip after 500 ms. There are no hover icons, and only the `NEW` badge shows.

**Card behaviour (all).** Poster tap → feature page (match cut). Hover (desktop) reveals favourite star and notify bell as `on-art` icon buttons at the bottom-right, and the empty select square at the top-right (the corners and select-mode states of §7.7). Long-press/right-click → Quick look with Open, Continue, Favourite, Status ▸, Notify, Add to collection, Download next 5, Recommend to…, Remove from library ("Your reading progress is kept", toast with Undo that restores favourite, status, notify, override and position).

**Select mode** (LB14, LB18, BA*): `Select` or `x` enters it; tap toggles; Shift-click selects a range; `mod+a` selects visible. The select-mode bar (§7.29) offers Favourite, Unfavourite, Mark read, Mark unread (every chapter in each selected series' `known_chapters`, through the §8.17 calls), Set status ▸, Add to collection, Download next 5, Unfollow (dialog first). Runs with concurrency 4, shows progress and a result line with Undo.

**Signature moment.** Filter changes are **Cuts**: the wall swaps instantly and the new posters run **Set** in reading order, so filtering feels like flipping to another page of the same magazine.

**Transitions.** In: Cut/Dip. Out: match cut to feature; Dip into the reader from cuttings.

**Keys (web).** `/` search; `h j k l` and arrows move in the wall; `Enter` open; `x` select mode; `Space` toggles the focused poster in select mode; `f` favourite focused; `1`–`7` status filters (in slug-line order: `ALL`, `READING`, `NOT STARTED`, `DONE`, `ON HOLD`, `PLAN TO READ`, `DROPPED`); `s` cycles sort; `v` cycles density.

**States.** Loading (masthead live, 12/24/8 flicker plates by density); empty (`EMPTY SHELF`: "Nothing on your shelf yet." / "Follow a series from Discover and it lands here." + `Find something`); filtered empty (`NOTHING MATCHES`: "No series match these filters." + `Clear filters`); search empty; offline (the offline edition shows saved series only with a banner); error (`CORRECTION` + Retry); page-load error after data (a caption line above the wall with Retry).

#### 8.9.1 The book list (novels mode, used everywhere novels are listed)

Rows 112 px on desktop in two columns with a 1 px column rule; one column on phones. Each row: a 56 × 84 plate (square-cornered, 1 px `rule.2` border; a Bodoni Moda initial on `paper.1` when there is no cover) → title in Bodoni Moda Italic 20 → byline "by {author}" (`type.body.italic` `ink.60`) → credits `412 CHAPTERS · ONGOING · NOVELARCHIVE` → blurb (Newsreader 15, 2 lines, `ink.60`) → note (`42% · CH 212` in `spot` folio, or the reading status). Select mode adds a leading checkbox. States as §7.16. Covers NS1–NS6.

---

### 8.10 Updates · web R22 UP1–UP8 · mobile S23 · G39

**Hierarchy.** Masthead → the check → new chapters by series → following list (tab).

**Layout (desktop and phone share the order; desktop uses 8 of 12 columns plus a 4-column aside).**
- Hub tab `02 UPDATES` active. Masthead kicker `No. 03 — STOP PRESS`, title "Updates", deck "14 new chapters across 6 series · last checked 12 min ago · checking every 30 min" (the deck is the settings summary; tapping it opens Settings → Notifications for admins, or shows a sheet with the schedule for others).
- Actions: primary `Check now` (loading state shows "Checking 212 series…"; for admins the run is polled through `GET /updates/runs/{id}` and the deck updates live "Checked 180 of 212 · 3 new"; for others the unread count is re-polled at 3, 5 and 7 s); secondary `Mark all read` (becomes `Mark all manga read` / `Mark all novels read` by content mode; disabled with nothing unread).
- Contents tabs: `NEW ¹⁴ · FOLLOWING ²¹²`, with a `SOURCE ▾` compact select at the row's right end (`All sources` plus `GET /updates/sources`, filtering both tabs client-side; hidden when only one source has follows).
- **NEW**: notifications grouped by day (date rule `TODAY`, `YESTERDAY`, `MONDAY 28 SEPTEMBER`), then by series: a 48 × 72 cover, series title (`type.title`), `NEW` count badge, the new chapter folios as a slug line (`CH 141 · CH 142 · CH 143`, each a link), source credit and time. Row actions: `Read from 141` (split, Dip into the reader), `Mark read` (quiet). Read rows fade to `ink.45`. Swipe left on phones: Mark read.
- **FOLLOWING**: the followed series as rows: cover, title, source, "Checked 12 min ago" / "Not checked yet", notify bell toggle, `Check this series` (per-series `POST /updates/followed/{id}/check`) in the overflow, `Unfollow` (quiet `proof`, toast with Undo).
- Aside (desktop, admin): "Recent checks" as a credits list: trigger · status · series · new · started; empty "No check runs yet." Non-admins have no aside. The lists keep columns 1–8 at every role, so the row measure does not change, and columns 9–12 stay empty. The schedule is already in the masthead deck.
- A reserved **push prompt** (ships only with push support): a banner strip "Get a notice the moment a chapter lands?" with `Turn on` and `Not now`.

**Phone.** One column; the admin aside moves to Settings → Notifications; a group row swipes left to `Mark read` (flat `ink.100` slab); pull to reprint reloads the list (it does not start a server check; `Check now` does). **Platform deltas.** iOS and Android: haptic `tap.primary` on Check now and `success` when the check finds chapters; mobile web the same without haptics; desktop adds the keys below and the aside.

**Signature moment.** New chapter folios type themselves in (50 ms per character) the first time a fresh notification appears after a check.

**Transitions.** In: hub tab Cut. From the stop-press banner (§8.33.3), `Read updates` is `go('/updates')` into branch 1 (§8.0.3), never a push: from another branch it plays the section change of §8.0.4 (phone Cut + Set + Folio flip with the notch moving to Library; desktop Dip + Folio flip), from inside branch 1 the hub tab Cut, and from the novel reader the Dip out of a reader. Out: Dip into the reader; match cut to the feature page from covers.

**Keys (web).** `r` reloads the list (reprint, as §11); `c` runs `Check now` (as System status, §8.31); `j`/`k` move between series groups; `Enter` reads the focused group; `m` marks it read; `shift+m` marks all read.

**States.** Loading (3 greeked groups); empty (`NOTHING NEW`: "No new chapters yet." / "Follow a series and this fills in the moment a chapter lands." + `Find something`); FOLLOWING empty (`NOTHING FOLLOWED YET`: "Nothing followed yet." + `Find something`); notifications switched off for this profile (§8.30.2 row 11: a `NOTE` line "New-chapter notices are off for this profile." + `Turn on`); check already running (`409`: caption "A check is already running."); offline ("Updates need a connection to check." notice, cached list shown read-only); error; rate limited.

---

### 8.11 Collections and collection detail · web R8, R9 (CO1–CO10, CD1–CD12) · mobile S24, S25

**Collections (`/library/collections`).**
- Hub tab `03 COLLECTIONS`. Masthead kicker `No. 06 — SHELVES`, title "Collections", deck "9 shelves · 2 shared".
- Toolbar: compact search ("Search shelves"), sort menu (`Name A–Z`, `Most series`, `Recently created`, `Custom order`), primary `New shelf`.
- Grid of **collection plates** (§7.6): 3 per row desktop (4 at wide), 1 per row on phones (16:9 full width). `SMART` and `SHARED` badges; shared plates show member avatars.
- `SHARED WITH YOU` (only when `shared_with_me` is not empty, §9.3.5, §9.3.8): a second group under a `type.kicker` `ink.45` slug over a `rule.hair`, the same plates with the owner's 20 px avatar and a `CAN ADD` or `VIEW ONLY` caption; not in `Custom order` (owner shelves only) and not counted in the deck's shelf count, which reads "9 shelves · 2 shared · 1 shared with you" when there are any.
- Custom order: drag plates (writes `sort_order`).
- **New shelf** dialog: `Name` (big field), `Description`, a switch `Smart shelf` which reveals rule chips (client-side rules over library rows: *status is* ▸, *favourite*, *new chapters ≥* n, *format* ▸, *unfinished novels*, combined with AND), and `Share with the circle` (§9.3.5). Actions `Create` / `Cancel`.
- States: loading (4 plates), empty (`NO SHELVES YET`: "Group series by theme, mood or reading plan." + `New shelf`), no search match, offline, error.

**Collection detail (`/library/collections/:id`).**
- Header spread: the duotone mosaic across the full width at 3:1 (desktop) / 16:9 (phone) with `scrim.foot`; kicker `SHELF · 24 SERIES`, name in `type.masthead`, description deck, credits (`SMART RULES: READING · 3+ NEW`, `SHARED WITH: RIYA, ARJUN`).
- Actions: `Add series` (secondary; a sheet/panel listing followed series not in the shelf with search, 48 × 72 covers, tap adds with a stamp haptic; "No series available." when all are in), `Edit` (dialog: name, description, smart rules), `Share` (Circle), `Reorder` (toggle), overflow `Delete shelf` (dialog "The series stay in your library.").
- Member wall: posters with captions; in select mode or via long-press, `Remove from shelf` (dialog with the explainer "It stays in your library."). On the owner's own unshared shelves, members are joined to library rows for titles and covers; orphans (no longer followed) show a title card and the caption `NO LONGER FOLLOWED`. A shared shelf, for its owner and members alike, renders each row from the shelf's own `title`, `cover_url` and `ambient` (§9.3.5, §9.3.8), never from the viewer's library, and never shows `NO LONGER FOLLOWED`.
- Smart shelves have no Add/Remove; their rules are edited instead, and the wall updates live (Cut + Set). **The rules are stored on the server**, so every device shows the same smart shelf: collections carry `rules: null | {all: [{field: "reading_status" | "is_favorite" | "new_count" | "format" | "content_kind", op: "eq" | "gte" | "in" | "ne", value}]}` on `POST`, `PATCH` and both `GET`s, and `smart` is `rules != null`. "Unfinished novels" is `content_kind eq "novel"` AND `reading_status ne "completed"`. A smart shelf's members are still computed from the owner's own library (`/library/series`) on the device, so smart shelves cannot be shared (`Share` disabled with the tooltip "Smart shelves follow your own library, so they can't be shared.").
- **Who can do what on a shared shelf** (enforced by the server from the share `mode`, §9.3.8; the client hides what the viewer cannot do rather than disabling it):

| Action | Owner | `CAN ADD` member | `VIEW ONLY` member |
|---|---|---|---|
| Open, read from it | yes | yes | yes |
| `Add series` | yes | yes (from their own library) | — |
| `Remove from shelf` | any member series | only series they added (`added_by_profile_id`, §9.3.8) | — |
| `Edit` (name, description), `Reorder`, `Share` (members and modes), `Delete shelf` | yes | — | — |
| `Leave shelf` (overflow) | — | yes | yes |

- **Leaving and sharing.** `Leave shelf` asks "Leave {shelf}? It disappears from your Collections. The series stay in your library." with `Leave shelf` (destructive, arm delay, §7.10). When the owner's profile shares nothing (Circle sharing off, §9.3.6), `Share` is removed from the action row and the overflow keeps a disabled `Share…` item captioned "Turn on sharing in Settings → Circle & privacy to share shelves." When sharing is on but no one has `Let others add me to shared shelves` on, the share sheet reads "Nobody can be added to shelves right now." with `Done`.
- States: loading (spread plate + 6 posters), empty ("This shelf is empty." + `Add series`), smart shelf matching nothing (`NOTHING MATCHES`: "Nothing matches these rules." + `Edit rules`), mode mismatch ("Everything on this shelf is a novel. Switch to Novels to see it." + `Switch`), error (+ `Back to collections`), not found (the §8.0.10 notice with `Back to collections`). A plate with zero members shows the shelf name in `type.subhead` over `paper.1` inside a 1 px `rule.2` frame, with no mosaic.

**Phone.** Plates run full width at 16:9, 16 px apart; the toolbar collapses to a search icon (expands a compact field) and a `Sort` sheet; `New shelf` sits under the masthead as a full-width secondary. Detail header 16:9; member wall 3 columns; `Reorder` uses long-press drag (`flutter_reorderable_grid_view` 5.7.0 on Flutter, Motion `Reorder` on web). **Gestures.** Pull to reprint (§11) on Collections and the collection detail refetches their payloads. **Platform deltas.** Android predictive back from detail uses the full-screen fade-through instead of the reverse match cut; iOS edge swipe reverses the match cut with the finger.

**Transitions.** Plate → detail: match cut of the mosaic into the header. **Keys (web).** `n` new shelf; `/` search; grid keys; `e` edit; `a` add series; `Delete` removes the focused member (dialog).

---

### 8.12 History · web R10 (RH1–RH5) · mobile S13

- Hub tab `04 HISTORY`. Masthead kicker `No. 07 — THE LOG`, title "History", deck "What you've been reading, most recent first."
- Contents tabs: `BY SERIES · BY CHAPTER` (`collapse=series` / `none`).
- **By series**: a log grouped by day with date rules; each row: time in the left margin (`type.folio` `ink.45`, "21:04") → 40 × 60 cover → title → caption `CH 142 · p.12 OF 40` (novels `42% IN`) → 2 px progress rule under the caption → trailing `Continue` (split sm, `p.12`) or `Next │ CH 143` for finished chapters (resolves the next chapter from the chapter list, busy state on the button, falls back to the feature page).
- **By chapter**: the same log, one row per chapter read.
- Desktop: the log spans 8 columns; a 4-column aside shows "This week" (chapters, time) from statistics.
- Pagination: `Load earlier` quiet button (offset + 50) at the end; no infinite scroll (a log reads better with an explicit end).
- **States.** Loading (8 greeked rows), empty (`NOTHING READ YET`: "Open a chapter and it shows up here." + `Go to library`), offline (notice), error.
- **Phone.** The log runs full width with a 40 px time margin; the aside is dropped; `Continue` becomes an icon-plus-folio button (`play` + `p.12`) at the row's end; pull to reprint. **Platform deltas.** None beyond the shared rules (§8.0.5); desktop adds keys.
- **Transitions.** Cut in; Dip into the reader on Continue; match cut on the cover.
- **Keys (web).** `j`/`k` rows, `Enter` continue, `o` open series, `t` toggles the view.

---

### 8.13 Bookmarks: marked passages · web R11 (BM1–BM5) · mobile S14

- Hub tab `05 BOOKMARKS`. Masthead kicker `No. 08 — MARKED PASSAGES`, title "Bookmarks", deck "Exact places you marked, in both readers."
- Filter: a compact select "All series ▾" (series with bookmarks) and the content mode.
- Grouped by series (a subhead per series with its cover at 32 × 48): each bookmark is a **marginal note**: folio `CH 14 · 62% IN` (manga: `CH 14 · PAGE 7`), for novels the snippet as a pull quote in Newsreader italic with a 2 px `spot` left rule, the user's note in `type.body` (or a quiet `Add a note`), saved date caption, the stale note in `info` ("The text here changed. This opens at the nearest spot.").
- Actions per bookmark: tap → the right reader at `?page=&at=` or `?para=&at=` (Dip); `Edit note` (inline textarea, ruled; saved on blur or `mod+Enter` through `POST /reader/bookmarks/batch` as a one-item upsert carrying `note`, on both clients: mobile through its bookmark outbox, the web directly; `bookmark_deleted` (409) answers with the toast "That bookmark was removed on another device."); `Remove` (quiet; toast "Bookmark removed" with Undo, 8 s).
- Mobile flushes the bookmark outbox before loading; a caption "Synced 3 bookmarks" appears after a flush.
- **States.** Loading (5 greeked notes), empty (`NO MARKS YET`: "Press B while reading, or tap the bookmark in the reader." + `Go to library`), offline (local store shown, caption "Changes sync when you're back online"), error.
- **Phone.** Groups full width; a note swipes left to `Remove` (with Undo); long-press opens Edit note / Remove / Open series. **Platform deltas.** Mobile reads from the offline store first and syncs through the bookmark outbox; web reads the server list. Desktop shows notes in two columns with a column rule at wide widths.
- **Keys (web).** `j`/`k`, `Enter` open, `e` edit note, `Delete` remove.
---

### 8.14 Manga reader: webtoon strip, paged, double, read-all · web R19, R20 (RD1–RD42) · mobile S15, S19 · §6a

The reader is the part of the app where Programme gets out of the way: no grid is visible, no serif is on screen while reading, and the chrome is two thin bands of type over scrims. The reader engine (feed, restore, extents, prefetch, progress, auto-scroll, taps) is shared per client (`features/reader/engine/`, stack-decision §2.3); everything below is the Cinematic chrome built on its `chromeBuilder` slot.

#### 8.14.1 Frame and layout

| Platform | Layout |
|---|---|
| Desktop web | Canvas `#000` (or the chosen ground). The strip column is `clamp(480px, 46vw, 860px)` wide and centred; page images are requested at the snapped width ≥ column × DPR (800 px sources pass through). Two optional **side panels** (§8.14.12), each 3 columns (min 320 px), toggled with `[` and `]`, remembered per profile. With both open the strip takes the remaining width, never less than 480 px (§8.14.12). |
| Tablet (web 768–1023, app 600+) | Strip column 100 % up to 720 px, centred; side panels open as column panels over the page |
| Phone (iOS, Android, mobile web) | Strip edge to edge; side margin preset 0 / 5 / 10 / 15 / 20 / 25 % (default 0) |
| Landscape phone | Strip column 70 % of the width, centred inside the safe rectangle (no chrome control sits inside a horizontal inset, §2.2.2); the running head and folio bar are both hidden at rest and shown together on a centre tap, under the normal auto-hide rules. The running head keeps its portrait height (44 on iOS, 48 on Android, plus the top inset) and its back button plus four trailing buttons |

Mood gutters: the area outside the strip on desktop takes the page tint (§9.4.4) when page-tinted chrome is on, else the ground colour; the profile's mood grade never reaches the reader.

#### 8.14.2 Entry: the Column wipe

Entering either reader **from Tonight** (the cover story's `Continue`, a cutting, a rail's Quick look `Continue`) **or from a feature or book page** (`Read`, `Continue`, `Read all`, a chapter row, `Listen`), including a recap takeover opened from those two places, plays the grid as a shutter. The wipe is the event of sitting down to read, so it never plays between chapters and never on the quick re-entries from History, Bookmarks, Updates, Downloads, Library cuttings, dialogue results, Circle, the command palette or a deep link: those use **Dip** (160 / 40 / 240 ms), which reaches the first page 432 ms sooner on desktop, 304 ms sooner on tablets and 176 ms sooner on phones. The prefetch-on-press below applies to both entries.

1. **Close.** The viewport is divided into the current grid's columns including gutters and margins (4 blades on phones, 8 on tablets, 12 on desktop; blade edges land on column edges). Each blade is a `#000` strip that scales `scaleY 0 → 1` from the **top** edge, 200 ms `settle`, staggered 16 ms left → right. Desktop: 200 + 11 × 16 = 376 ms; tablet: 200 + 7 × 16 = 312 ms; phone: 200 + 3 × 16 = 248 ms.
2. **Hold** on black 40 ms (`dur.hold.dip`). The route swaps underneath. The manifest and the first two pages were prefetched on hover or focus (after a 150 ms dwell, P3 in the sources limiter, §15.6) or on press of the entry control, so the first page is usually decoded here. Haptic `reader.enter` as the last blade lands; sound `wipe` if on.
3. **Open.** Blades retract `scaleY 1 → 0` toward the **bottom** edge, 280 ms `settle`, staggered 16 ms left → right, revealing page one (or the saved page). Desktop 456 ms; tablet 392 ms; phone 328 ms.
4. The running head and folio bar are visible for the first 800 ms (orientation), then follow the auto-hide rules. For an 18+ series the rating card (§7.24) appears.

Tap during the wipe jumps to open in 120 ms (`dur.snap`). If the first page is not decoded after the hold, the blades still open and the page shows its galley plate (§8.14.11). Reduced motion: a 200 ms (`dur.clip`) cross-fade through black. Web: a fixed overlay of N `<div>` blades animated with Motion (`transform` only). Flutter: both readers use one `SwipeablePage` (`swipeable_page_route` 0.4.8, no extra route code). The entry kind travels in `GoRouterState.extra` as `{entry: 'wipe' | 'dip'}`. `transitionDuration` is the wipe's total for `wipe`, (200 + (c − 1) × 16) + 40 + (280 + (c − 1) × 16) ms for c blades: 616 (4, phones), 744 (8, tablets and web 600–1023), 872 (12, desktop), the same totals as the web; it is 440 ms for `dip`. `reverseTransitionDuration` is 440 ms. The `transitionBuilder` paints N `Transform(scaleY)` blades from `Interval`s of the route animation while `animation.status == AnimationStatus.forward` and the entry is `wipe`; the Dip in (160 ms to `#000` `ease.lift`, 40 ms `dur.hold.dip` hold, 240 ms in `ease.settle`) for a `dip` entry; the Dip while the status is `reverse` and `!isSwipeGesture` (so a pop never replays the blades); and the §8.0.5 finger-tracked slide while `isSwipeGesture` is true.

Exit (back, `Esc` at the end of the escape order, `s`): **Dip** (160 / 40 / 240, 440 ms), never a wipe, so leaving is quiet.

- **Back target (both readers, both OSes, the button and the system back).** When `context.canPop()`, it pops. Otherwise it calls `go('/sources/:sourceId/series/:seriesKey')` (the manga Feature or the novel Book) and the series page enters by Dip. On Android this is wired through `PopScope(canPop: context.canPop(), onPopInvokedWithResult: …)`.
- **iOS edge swipe** (20 pt, `canOnlySwipeFromEdge: true`). The reader keeps `context.getSwipeablePageRoute()!.canSwipe` (a mutable field in 0.4.8) true only while the device runs iOS, the layout is strip or novel scroll, zoom ≤ 1.0 and guided view is off. A committed swipe pops without a Dip. When nothing lies beneath, the route is first and the swipe is off, and the back button is the way out.
- **Android.** `canSwipe` is false and the reader has no predictive preview on purpose; a committed back gesture or the back button plays the Dip.

#### 8.14.3 Chrome: running head and folio bar

**Running head** (top, over `scrim.head`; 56 px desktop; phones min 44 (48 on Android) + `MediaQuery.viewPaddingOf(context).top`, growing to the title line + 2 × 12 px at large text scales, §7.13):
- Leading: back (`arrow-left` 24 Light).
- Title: series title in `type.nav` `ink.60` + ` · ` + `CH 142` in `type.folio` `spot` followed by a 12 px `caret-down` (read-all adds `· 12 OF 201`). The two parts are separate targets: the series title opens the feature page; the chapter folio (its own hit area, 44 (iOS, web) / 48 (Android), `hitMin` / `hitAndroid`; tooltip "Contents") opens **Contents**: on phones a `[0.5, 0.92]` sheet with the chapter list as schedule rows (§7.16), the current chapter on a `spot.wash` band and pre-scrolled to centre, the `NEWEST │ OLDEST` toggle and a go-to field, a tap on a chapter jumping by Dip (in read-all it scrolls); on tablets and desktop the left side panel (§8.14.12). While a soundscape plays, a 16 px `waveform` glyph follows the chapter folio's `caret-down` inside the title group (its own 44 (iOS, web) / 48 (Android) hit, not one of the four trailing buttons); a tap opens Reading setup at `AMBIENT` (§9.4.2).
- Trailing: download mark for this chapter (§7.18; tap cycles Download → saving `12/40 · 30%` with cancel → `SAVED`; tap again asks "Remove from this device?" inline and reverts after 4 s; warn states `Save again` (stale) and `Resume 12/40` (incomplete)); bookmark (`bookmark-simple`; Fill + spot rule when this page is bookmarked); guided view (`panel-focus`, only once the current page has panels, from the manifest's `pages[].panels` or from on-device analysis, §9.4.3; Fill + spot rule while guided view is on); on tablets and desktop the panel toggles `sidebar-simple` and `note-pencil` (tablets have no `[` `]` keys, so the buttons are their only trigger there); settings (`sliders-horizontal`). At most four trailing buttons show on phones: download, bookmark, guided view when ready, settings.
- An `OFFLINE EDITION` micro badge beside the title when the chapter is read from disk.

**Folio bar** (bottom, over `scrim.sole`; min 64 px + bottom inset, growing by the height of its second caption line at large text scales):
- Left: previous chapter (`skip-back` + `141` folio; disabled at the first chapter; in the strip it scrolls to the loaded previous chapter instead of navigating).
- Centre: **the ruler** (§8.14.4), full width between the chapter buttons.
- Under the ruler (one line): `07 / 40` (`type.folio.lg`) · `6 MIN LEFT` (`type.caption` `ink.60`, shown only after 2 minutes of pace samples) · chapter title in `type.caption` (desktop).
- Right: next chapter (`143` + `skip-forward`), auto-scroll (`play` with the strip glyph, strip only; filled + spot rule when running, with its speed folio `1.0×`), and on desktop fullscreen (`corners-out`).

**Auto-hide** (shared engine thresholds):
- Hide after a cumulative downward scroll ≥ 24 px since the last direction change; show after a cumulative upward scroll ≥ 56 px, at chapter end, on a centre tap, on pointer movement into the top 72 px or bottom 96 px (desktop), on `g`, `,`, `[`, `]` or `?` (keys that open something in or beside the chrome), or on focus entering the chrome (`Tab` / `Shift+Tab`).
- Every other reader key never reveals the chrome, and only the scroll rules apply to it. That covers page and scroll keys (`j` `k` `Space` `Shift+Space` `←` `→` `a` `d` `Home` `End` `PageUp` `PageDown`), chapter keys (`h` `l` `Ctrl+Shift+←/→`), zoom (`=` `+` `-` `0`), auto-scroll (`p` `<` `>`), and `b`, `u`, `w`, `v`, `r`, `f`, `s`. `m` and `c` keep their own rules.
- While focus is inside the chrome (web `:focus-within` on the chrome container; Flutter `hasFocus` on the chrome's `FocusScopeNode`), auto-hide is suspended: no scroll hide and no 3000 ms idle hide. When `m`, `c` or a click on the page hides the chrome while it holds focus, focus moves to the reading surface first.
- After a tap or hover opened the chrome, hide after 3000 ms idle (paused while a sheet, menu or the ruler is in use).
- Never hide during the first 800 ms of a chapter.
- Motion: in 240 ms `settle` (fade + 8 px slide from its edge); out 160 ms `lift`. Hidden chrome is `visibility: hidden` / `Offstage` so it leaves the tab order. In the app the status bar shows and hides with the chrome (§8.0.5 System bars); the strip ignores system insets, so this never reflows the page.
- **Micro progress**: a 2 px `spot` rule at the very bottom of the screen shows chapter progress while the chrome is hidden.

**Cinema mode** (`c`, or the settings sheet): the chrome hides after 3000 ms idle (never while focus is inside it, as above) and the micro progress disappears; tap, pointer move or `c` brings chrome back; `Esc` leaves cinema before leaving the reader.

**Lock mode** (setting "Lock reader controls"): the reader opens locked; taps only register in the centre (20–80 % × 15–85 %); five taps within 2 s each unlock (toast "Controls unlocked", haptic `reader.unlock`).

**Page tint** (§9.4.4): when on, the scrims' end colour mixes 25 % of the current page tint (web `--scrim-base` on the chrome root, Flutter the `tint` argument of `scrimHead` / `scrimSole`, §2.8.3) and the ruler fill takes the tint's light variant.

#### 8.14.4 The ruler (scrubber)

- Track: 2 px `rule.2`, full width between the chapter buttons; the played part is `ink.100`.
- Page ticks: 1 × 4 px `ink.30` under the track per page (dropped when there are more than 120 pages).
- Read-all: chapter boundaries are 2 px gaps in the track, with the chapter folio shown on hover.
- Bookmarks: 2 × 8 px `spot` marks standing above the track at their positions.
- Thumb: a 2 × 16 px `ink.100` vertical tick; grows to 3 × 24 while dragging; a folio flag above it reads `p. 18`; desktop hover shows a 120 px-wide page preview above the pointer from the cached page image, captioned `p. 18 / 40`.
- Touch: the hit area is 44 px tall (48 dp on Android); dragging seeks live (RTL mirrors the direction); release settles with `spring.scrub`.
- Haptics: `scrub.tick` per page, `scrub.boundary` at chapter boundaries (read-all).
- Accessibility: a native range underneath (`aria-valuetext="Page 18 of 40"`), arrow keys step one page, `Shift+arrow` ten; disabled for single-page chapters.
- Jump to page: clicking the `07 / 40` folio turns it into a number field (Enter jumps, Esc cancels); `g` opens it from the keyboard.

#### 8.14.5 Strip mode (webtoon, default)

- Pages seamless, no gap (setting "Gap between pages" adds 8 px of ground colour), no radius, no shadow.
- Each page reserves its exact box from manifest `width/height` before the image lands (fallback 2:3 until decoded); the engine corrects heights with scroll compensation so the page under the reader never jumps.
- **Chapter seam** (continuous feed): a quiet 96 px band of ground: 1 px `rule.1` rules either side of `CH 143 · THE RETURN` in `type.kicker` `ink.45`. Crossing it gives haptic `scrub.boundary`.
- **Read-all divider**: a 48 px band with `142 → 143` in `type.folio` between hairlines; no card, no pause ("without feeling it").
- Top of the strip (a previous chapter exists): a slim band `↑ CH 141 · keep scrolling up`, loading state `Loading CH 141…` with a 16 px leader dial; over-scrolling up 140 px loads it.
- **Zoom**: the Reading setup Zoom stepper sets the series' resting zoom (§8.14.8). Pinch clamps to 0.5–3.0× and snaps to 0.1 steps on release (Flutter `ScaleGestureRecognizer` driving the engine's zoom; web `@use-gesture/react` 10.3.1 `usePinch` with `touch-action: pan-y`); double tap goes from the resting zoom to min(2 × resting, 3.0)× at the tap point, and from any other zoom back to the resting zoom, in 240 ms (`dur.line`) `settle` (haptic `zoom.snap`); paged modes stay at 1–3× with double tap 1× ⇄ 2×. The chapter swipe and the iOS edge swipe count as "not zoomed" at zoom ≤ 1.0; `Ctrl`/`⌘` + wheel zooms around the pointer, `=` / `-` / `0` keys. The zoom level shows as a folio chip `200%` (`type.folio` `ink.100` on the folio-flag ground, §2.1.4) top-centre for 1200 ms (`dur.hold.chip`). Plain wheel always scrolls.
- Tap behaviour: the whole screen toggles chrome (default). Opt-in "Tap to scroll": top third plus left-middle scroll back, bottom third plus right-middle scroll forward 75 % of the viewport in 300 ms `dur.tapscroll` `ease.scroll` (`cubic-bezier(0.5, 1, 0.89, 1)`), centre toggles chrome.
- Desktop strip: the chrome-toggle click commits after 250 ms unless a second click lands within 250 ms and 24 px, which zooms instead. Paged side zones turn on the first click, and a double-click on a side zone turns two pages and never zooms.
- Horizontal swipe ≥ 72 px (phones, on by default in strip mode) changes chapter: the page follows the finger with a rubber band and a `CH 143 →` folio slides in from the edge; release past the threshold commits (haptic `chapter.next`, Dip to the neighbour). It is live only at zoom ≤ 1.0, for touches that start at least max(24 px, `MediaQuery.systemGestureInsetsOf(context).left` / `.right`) from both edges and drags within 30° of horizontal (§11 precedence); above 1.0× a horizontal drag pans the page.
- Brightness HUD: a vertical swipe along the left 12 % edge changes brightness (−75 to 0, a dimmer below the system minimum; §8.14.8); a 6 × 140 px HUD (its glyph and folio value on the folio-flag ground, §2.1.4; 1 px `ink.100` outline, `ink.100` fill from the bottom, `sun-dim` glyph, folio value; below 0 it reads `NIGHT −40`) fades 600 ms after release.
- Auto-scroll speed HUD: while auto-scroll runs, the right 12 % edge adjusts speed with the same HUD reading `1.5×`.

#### 8.14.6 Chapter end: the credits

When the last page of a chapter scrolls up past 60 % of the viewport, the **credits** follow (haptic `chapter.complete`, sound `done`; the engine marks the chapter complete):

1. 96 px of ground.
2. `End of chapter 142` in `type.section` (Bodoni Moda Italic) with the letter reveal, then a credits block: `SERIES  Omniscient Reader · SOURCE  MangaDex · READ IN  11 MIN · PAGES  40`.
3. **Reactions** (§9.3.3): five square stamps in a row, each with its count and the reacting readers' 20 px avatars. The credits appear only once the engine has marked this chapter complete for the viewer, so the spoiler guard lifts here: any reactions that were shown guarded elsewhere (avatar plus "reacted to Ch. 142") **unseal** as the credits set, each glyph fading in over 160 ms (`ease.settle`) 40 ms after the previous one. If the viewer reaches the credits by dragging the ruler to the end, the chapter is still marked complete (the engine's rule), so the same unseal plays.
4. **Coming up** card (when a next chapter exists and the strip is not already continuing seamlessly): a 16:9 panel of the next chapter's first page blurred 24 px and duotoned to `ambient.duo`, with the sharp page as an inset 3:4 thumbnail on the left; the text block sits on a `#000000` band at 0.84 (§2.1.4 over-art rule); kicker `COMING UP`; headline `Chapter 143` (`type.headline`); deck = chapter title; folio `38 PAGES · ~6 MIN`; primary `Read chapter 143` (48 px).
5. **Pull to continue**: below the card, a 150 px (phone) / 300 px (desktop) region with a 2 px `spot` rule that fills from the left as the reader pulls; at full it commits (haptic `chapter.next`), a 250 ms (`dur.fade.cut`) fade through black follows, and the new chapter's title is typed at 50 ms per character as a caption top-left (`CH 143 — The Return`, on the folio-flag ground, §2.1.4, because it sits over the first page), fading after 2 s (`dur.hold.brief`).

Continuous strip (default): the next chapter is already stitched below, so step 4–5 are replaced by the chapter seam and the credits are compact (the end title on one line + reactions), and reading simply continues. With **Auto next chapter** off, the credits end the feed and `Read chapter 143` is required.

End states:
- **Caught up**: a notice: kicker `CAUGHT UP`, headline "That's everything so far.", deck "MangaDex has published 142 chapters. You'll get a notice when 143 lands." + `Notify me` switch (follow bell) + `More like this` rail + `Back to the series`.
- **The end** (the series `status` is Completed, case-insensitive, and its last chapter completes): the caught-up notice becomes kicker `THE END`, headline "You finished {title}.", deck "{n} chapters, {h} hours." (hours from the feature page's `YOUR TIME HERE` source); an `Up next` rail follows (Similar, §9.1.4, else Because you read, else From your shelf); a quiet `Mark as done` sends `PATCH /library/series/{id} {reading_status: "completed"}` and is hidden when the status is already completed. The `Notify me` switch and the "You'll get a notice…" deck are never shown for a Completed series.
- **Next failed**: `CORRECTION` notice "Chapter 143 didn't load." + `Try again` + `Open it on its own →`. Automatic retries back off from 2 s to 30 s meanwhile.
- **Further on another device** (progress `advanced: false`): a toast "You're further ahead on another device (CH 145, p.3). Jump there?" with `Jump`.

#### 8.14.7 Paged modes: single and double

- Stage: the page fits by the chosen fit (Width, Height, Original) within the viewport minus 24 px; ground colour around.
- **Double**: two pages side by side with an 8 px ground gutter and a 1 px `rule.1` centre line (the magazine's gutter); RTL mirrors display order; a wide page (landscape spread) occupies both slots alone.
- **Page turn**: `Cut` (0 ms, default, a film cut), `Slide` (the incoming page pushes in from its reading side, 280 ms `ease.settle` (`dur.pageturn`); finger releases use `spring.release`), or `Fade` (160 ms). Haptic `page.turn`. Sound `turn` if on.
- **Tap zones**: 30 / 40 / 30; default previous / chrome / next, mirrored for RTL until the user sets their own. The first time a layout is used, the zones are painted as three labelled bands (`BACK · MENU · NEXT`, 1 px `ink.30` outlines, labels in `type.kicker`) that fade out over 1000 ms (`dur.fade.hint`) after 1500 ms (`dur.hold.glance`); they reappear whenever the zone layout changes.
- Wheel: one page per wheel gesture with a 200 ms idle reset.
- Swipe: horizontal swipe turns pages (reading direction aware), with the page tracking the finger.
- Zoom: `InteractiveViewer` (Flutter) / `usePinch` (web), 1–3×; while zoomed, swipes pan and the edge-swipe back is disabled.
- Preload: 3 pages ahead.
- Chapter end in paged mode: after the last page, one more "page" holds the credits (§8.14.6) centred on the stage.

#### 8.14.8 Reading setup (the reader settings sheet)

A `[0.5, 0.92]` sheet on phones (the page stays live above at the half detent), and on desktop the right side panel (§8.14.12: 3 columns, min 320 px, `paper.0`, 1 px `rule.1` inner edge), which hides Margins while it is open. Kicker `READING SETUP`, title = the series title. Contents tabs `LAYOUT · IMAGE · CONTROLS · AMBIENT`. Every control states where it is saved:

- **per series**: this profile + this series (web: the profile-scoped `mm.reader-preferences[{source}:{series}]`; mobile: a new profile-scoped map `mm.reader-prefs.u{user}p{profile}` keyed `source:series`). A series with no value uses the profile default from Settings → Reading: manga (§8.30.2).
- **per profile**: this profile on every series (web scoped localStorage; mobile SharedPreferences with the `.u{user}p{profile}` suffix).
- **per device**: this device for every profile (screen-bound or hardware-bound settings).
- **session**: forgotten when the reader closes.

| Tab | Control | Options and range | Default | Saved | Inventory key (migration) |
|---|---|---|---|---|---|
| `LAYOUT` | Layout | `STRIP │ SINGLE │ DOUBLE │ GUIDED` (hidden in read-all) | `STRIP` | per series | web K35; mobile K01 `vertical` → `STRIP` |
| `LAYOUT` | Direction | `LEFT TO RIGHT │ RIGHT TO LEFT`, captions "Webtoons and western comics" / "Manga" | `LEFT TO RIGHT` | per series | web K37; mobile K01 `leftToRight` / `rightToLeft` are continuous horizontal strips today, which this skin does not have: they migrate to Layout `SINGLE` with the matching direction, and the first reader open after the migration shows the toast "Sideways strips are now pages. Change it in Reading setup." once per device |
| `LAYOUT` | Fit | `WIDTH │ HEIGHT │ ORIGINAL` (Height and Original disabled in strip, with tooltips) | `WIDTH` | per series | web K36; mobile K02 (`screen` → `HEIGHT`) |
| `LAYOUT` | Side margin (phones) | `0 · 5 · 10 · 15 · 20 · 25 %` | `0 %` | per profile | new |
| `LAYOUT` | Strip width (desktop, tablets) | slider 480–860 px, step 20 | `clamp(480px, 46vw, 860px)` until set | per device | new |
| `LAYOUT` | Zoom | stepper 50–300 %, step 10, with `Reset`; sets the series' resting zoom (strip pinch 0.5–3.0×, double tap to min(2 × resting, 3.0)×, §8.14.5) | 100 % | per series | web K38; mobile session zoom |
| `LAYOUT` | Gap between pages | switch (strip only), 8 px of ground | off | per profile | web K29 |
| `LAYOUT` | Page turn | `CUT │ SLIDE │ FADE` (paged only) | `CUT` | per profile | web K33 (`false` → `CUT`, `true` → `SLIDE`) |
| `IMAGE` | Brightness | slider −75 … 0, step 1, caption "Dims below your screen's lowest setting." (a `#000000` overlay over the pages at alpha `\|v\|/100`, pointer-transparent, the same on both clients; there are no positive values: neither the web nor the app drives screen brightness) | 0 | per profile | web K31 dimmer (`v = −round(min(dimmer, 0.75) × 100)`), mobile K09 (`v = −round((1 − K09) / 0.8 × 75)`) |
| `IMAGE` | Warmth | 0–100, step 1 (a `color.warmth` layer over the pages at alpha `v/100 × 0.36`, blended `multiply` so blacks stay black: web `mix-blend-mode: multiply` on a pointer-transparent fixed layer; Flutter `ColorFiltered(colorFilter: ColorFilter.mode(context.cine.colorWarmth.withValues(alpha: v / 100 * 0.36), BlendMode.multiply))` around the page layer) | 0 | per profile | web K32 (`v = round(warmth / 0.7 × 100)`), mobile K10 (`v = round(K10 × 100)`) |
| `IMAGE` | Colour | `NORMAL │ SEPIA │ GREY` | `NORMAL` | per profile | mobile K12 |
| `IMAGE` | Ground | `BLACK │ INK │ SLATE` | `BLACK` | per profile | mobile K11 (mapped §2.1.6) |
| `CONTROLS` | Tap zones | three segmented rows `LEFT / CENTRE / RIGHT` × `PREVIOUS │ MENU │ NEXT`, `Reset`, `Show zones` | automatic: paged previous / menu / next (mirrored for RTL), strip menu everywhere | per profile | web K34, mobile K03 |
| `CONTROLS` | Strip taps | `MENU │ TAP TO SCROLL` | `MENU` | per profile | new |
| `CONTROLS` | Swipe sideways to change chapter | switch | on (phones), absent on desktop | per profile | new |
| `CONTROLS` | Cinema mode | switch | off | per profile | web K30 |
| `CONTROLS` | Fullscreen (web) | switch; renders whenever `document.fullscreenEnabled` is true, at every width (the desktop folio bar's `corners-out` button does the same) | off | session | RD27, RD41 |
| `CONTROLS` | Keep screen awake (app) | switch | off | per device | mobile K05 |
| `CONTROLS` | Auto next chapter | switch | on | per profile | mobile K06 |
| `CONTROLS` | Lock controls (app) | switch (the reader opens locked) | off | per device | mobile K07 |
| `CONTROLS` | Volume keys turn pages (Android) | switch | off | per device | mobile K08 |
| `CONTROLS` | Refresh rate (Android) | `AUTO │ 30 │ 60 │ 90 │ 120` | `AUTO` | per device | mobile K04 |
| `AMBIENT` | Auto-scroll | play / pause | stopped | session | — |
| `AMBIENT` | Auto-scroll speed | speed ruler 0.50–3.00× in 0.05 steps (1.00× = 60 px/s at a 1080 px viewport, §9.4.1) | 1.00× | per series | web K39 (a level 1–10): `px = 20 + (level − 1) × 200 / 9`, then `speed = clamp(px / 60, 0.50, 3.00)` rounded to 0.05 (level 1 → 0.50×, 5 → 1.80×, 10 → 3.00×). Mobile speed is session-only today (`mobile.md` A069), so nothing migrates on mobile |
| `AMBIENT` | Resume after I let go | switch (resumes 800 ms after release) | on | per profile | new |
| `AMBIENT` | Pace by dialogue (manga with dialogue text) | switch (§9.4.1) | off | per profile | new |
| `AMBIENT` | Soundscape | `OFF · MATCH THE MOOD ·` eight loops (§9.4.2) | `OFF` | per profile | new |
| `AMBIENT` | Soundscape volume | 0–100 % | 40 % | per device | new |
| `AMBIENT` | Page-tinted chrome | switch (§9.4.4) | on | per profile | new |
| `AMBIENT` | Guided view auto-advance | switch, then `PACE BY WORDS │ FIXED` and a fixed hold stepper 2–10 s (§9.4.3) | off; `PACE BY WORDS`; 3.5 s | per profile | new |

Keys mobile K01–K12 are device-wide today. On the first launch of this skin, the values of mobile K01–K03, K06 and K09–K12 are copied into every profile on the device as that profile's defaults (per-series controls get them as the profile default, not as per-series values), then the rules above apply. Mobile K04, K05, K07 and K08 stay device keys, unchanged.

Footer: `Shortcuts` (desktop, opens the keyboard sheet), `Reset reader settings` (quiet; dialog "Restore every reader setting to its default?"). Changes apply live; closing the sheet also hides the chrome.

#### 8.14.9 Keys (web and hardware keyboards)

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

#### 8.14.10 Gestures by platform

| Gesture | iOS | Android | Mobile web | Desktop web |
|---|---|---|---|---|
| Scroll | Native, clamping + stretch | same | native, `overscroll-behavior-y: contain` | wheel, trackpad; no smooth-scroll library |
| Tap | Chrome toggle / zones | same | same | click zones |
| Double tap | Strip: resting zoom ⇄ min(2 × resting, 3.0)×; paged: 1 ⇄ 2× | same | 300 ms / 24 px detector | double-click (strip: 250 ms / 24 px click rule; paged side zones turn two pages and never zoom; §8.14.5) |
| Pinch | Strip 0.5–3.0× (0.1 snap on release); paged 1–3× | same | `usePinch` | `Ctrl`+wheel, Safari `GestureEvent` |
| Long-press 450 ms on a page | Page actions sheet (§8.14.13) | same | same | right-click menu |
| Horizontal swipe (strip) | Chapter change | same | same | — (`h`/`l`) |
| Left-edge vertical swipe | Brightness HUD | same | same | — (setup sheet) |
| Right-edge vertical swipe | Auto-scroll speed while running | same | same | — (`<` `>`) |
| Back | 20 pt edge swipe, live only in strip at zoom ≤ 1.0 with guided view off; pops without a Dip; off when the reader is the first route (§8.14.2) | No predictive preview; back gesture or button plays the Dip; pops, or goes to the series page when nothing is beneath (§8.14.2) | browser back | `Esc` order |
| Volume keys | — | Page turn (opt-in) | — | — |

#### 8.14.11 States

| State | Presentation |
|---|---|
| Loading chapter | Three galley page plates at the manifest's (or 2:3) aspect in the strip column, the running head visible with `LOADING CH 142`, a 24 px leader dial after 400 ms |
| Page placeholder | The page's reserved box in the ground colour, no spinner |
| Next chapter loading (strip) | Below the seam, a 96 px band of ground reads `CH 143 IS ON ITS WAY` in `type.kicker` `ink.45`, with a 16 px leader dial after 400 ms. After 8 s it adds "This source can take a while." (`type.caption`). The band keeps 128 px of bottom padding so the folio bar never covers it. Auto-scroll pauses at the band and resumes when the pages land. |
| Broken page | Inside the page box: kicker `PAGE 18 DIDN'T LOAD`, `quiet` `Retry` (refetches that image only), and the reason in `type.caption` when known |
| No pages | Notice: "This chapter has no pages." + `Back to the series` |
| Error | `CORRECTION` notice with the API message + `Try again` + `Go to the series`; read-all list failure: "This series' chapter list didn't come through, so there's nothing to read through." |
| Offline | Reads from disk silently; `OFFLINE EDITION` badge; no neighbour loading (seam shows "Next chapter isn't saved on this device" with `Back to Downloads`) |
| Rate limited | A band at the top of the unloaded pages: `SLOW DOWN — the source asked us to wait. Retrying in 12 s.` with a live folio countdown |
| Stale bookmark | Toast "That page moved. Opened at the nearest one." (`dur.hold.toast`, 3600 ms) |
| Bookmark saved / failed | Toast "Marked page 7 — 42% of the chapter." / "Couldn't save that spot." (`proof`) |
| Further on another device | §8.14.6 toast |
| 18+ series | Rating card at start |
| Series, source or chapter no longer available (removed, dead source, or hidden by the gate) | The §8.0.10 `NOT IN THIS ISSUE` notice, identical for every cause |

**Saving the next chapter (auto-queue; an existing engine duty, extended here, §15.4).** When a downloads scope exists and `client_downloads` is on, opening a manga chapter whose next chapter is not saved queues that one chapter, once per open. It is skipped when mobile K20 ("Download on Wi-Fi only") is on and the device is not on Wi-Fi, or when the storage cap or the 1.5 GB floor has been reached. There is no toast and no haptic: the Downloads badge counts it, and the Coming up card's folio shows `SAVED` once it finishes. Settings → Downloads & storage has a per-profile switch "Save the next chapter while I read", default on (§8.23 STORAGE tab, §8.30.2 row 07).

#### 8.14.12 Side panels (desktop web; column panels on tablets)

- **Left, "Contents"** (`[`): the chapter list as schedule rows (§7.16) with the current chapter marked (`spot.wash` band), newest/oldest toggle, go-to field, read state and download marks; clicking a chapter jumps (in read-all it scrolls; otherwise Dip).
- **Right, "Margins"** (`]`), contents tabs:
  - `NOTES`: this chapter's bookmarks with their notes, `Add a note to this page`.
  - `DIALOGUE`: when the chapter has OCR text (`GET /ocr/chapter`), the transcript as subtitle lines per page (`p. 12` folio + lines in `type.body`); hovering a line outlines its bubble on the page with a 2 px `spot` frame; clicking scrolls there and pulses the frame twice (480 ms each). When there is no text: "Dialogue isn't indexed for this chapter." + (app only, for a downloaded chapter) `Scan it on your phone` hint.
  - `CIRCLE`: who in the circle read this chapter (`GET /circle/series`, §9.3.8), their reactions, and `Recommend this series…`. **Spoiler guard**: while the viewer has not finished the open chapter, a reaction on it (or on any later chapter) shows only the member's 20 px avatar and the line "reacted to Ch. 142" in `type.caption` `ink.45`, never the glyph or its name; reactions on chapters the viewer has finished show in full. The moment the chapter completes, the panel's guarded rows unseal (glyph fades in, 160 ms). Members who read further than the viewer are listed as "Riya is on Ch. 150" without detail.
- Panels are `paper.0` with a 1 px `rule.1` inner edge, slide 320 ms `settle`, and never overlap the strip on desktop (the strip recentres in the remaining columns, 320 ms `turn`).
- **Narrow desktops.** If `viewport − 2 × grid margin − open panels` would leave the strip under 480 px, opening a panel closes the one on the other side (last opened wins, 320 ms `settle`). Reading setup (§8.14.8) takes the right slot: opening it hides Margins, and closing it restores Margins if Margins was open. `[` / `]` state is still remembered per profile, but where both panels cannot fit, only the most recently opened one is restored.

#### 8.14.13 Page actions (long-press or right-click on a page)

A `[0.5, 0.92]` sheet (phone) or menu (desktop): `Bookmark this spot` (+ note field after saving), `Show dialogue on this page` (overlays OCR boxes as 1 px `spot` outlines with the recognised text on tap), `React to this chapter` (the five stamps), `Retry this page`, `Open page image` (the Lightbox, §7.30, with this page: pinch to 4×, drag down to dismiss back into its box), `Scan this chapter's dialogue` (app only, downloaded chapters; starts the on-device OCR run with its progress in Downloads, §8.23).

---

### 8.15 Novel reader: "The page" · web R21 (NR1–NR19, NT1–NT7) · mobile S26, N1, N2, N4

The novel page is painted entirely in the chosen paper stock (§2.1.6); app chrome never appears. Newsreader is the default face, so reading uses the same text serif as the rest of the skin.

#### 8.15.1 Layout

| Platform | Layout |
|---|---|
| Desktop | A single text column at the chosen measure (default 64ch, range 48–88ch) centred in the viewport; a running head *inside* the page at the top (series title and chapter kicker left, `42%` folio right) that fades as you scroll; margins take the stock colour to the window edges |
| Phone | The column fills the width minus 24 px margins (a Margin setting widens them to 48 px); running head as on desktop |
| Landscape phone / tablet | Measure-limited column centred inside the safe rectangle; no chrome control sits inside a horizontal inset (§2.2.2) |

#### 8.15.2 The chapter: opener, body, end matter

- **Opener**: kicker `CHAPTER 12` in `type.kicker` (stock muted), title in Bodoni Moda Roman at 1.9 × the body size (stock ink), a 48 px rule (1 px stock muted), and a line of facts in `type.folio` (`3.4K WORDS · 14 MIN`). When audio exists: `Listen │ 14 MIN` as a `split` secondary in stock ink with `headphones` (a small "audio saved" check when downloaded).
- **Body**: the chosen face (§3.4; Newsreader by default) at the chosen size and leading; first paragraph with a Bodoni Moda **drop cap** 3 lines tall (only when the paragraph is ≥ 80 characters); following paragraphs indented 1.3em (flush after scene breaks); scene breaks (a paragraph of ≤ 12 ornament characters) render as a centred 32 px rule with 24 px space above and below; `hyphens: auto` and justification only when Justify is on.
- **Speaker tints**: attributed dialogue runs get their speaker's slot colour (§2.1.6) as a 2 px underline at 70 % and a 12 % background, only when the attribution's `text_fingerprint` matches the text on screen. The tint is never the only signal (§14.3): on the web a tinted run shows the speaker's name on hover (a 500 ms tooltip in the §7.2 style, `KIM DOKJA` in `type.kicker`); on the phones a long-press on a tinted run shows the same name as a small popover (long-press is otherwise unassigned in the novel body, §8.15.8); screen readers hear the name inline before the run (a visually hidden "Kim Dokja:" span on the web; `TextSpan(semanticsLabel: 'Kim Dokja: …')` in Flutter).
- **Voices line**: under the text, right-aligned, `VOICES IN THIS CHAPTER (5)` in `type.kicker` → opens the cast sheet (§8.16.5).
- **End matter**: 96 px space, a 96 px rule, `End of chapter 12` in `type.section` with the letter reveal, facts (`READ IN 14 MIN`), reactions (§9.3.3), then the **next** card in stock colours: kicker `NEXT`, `Chapter 13` in Bodoni Moda, the chapter title, `→`; or "You've reached the last chapter this source has published." (for a Completed book whose last chapter completes, the §8.14.6 **The end** block instead, in stock colours: `THE END`, "You finished {title}.", the `Up next` rail and `Mark as done`). Links `Previous chapter` and `Back to the book`.
- **Seamless next**: over-scrolling 140 px at the bottom, `l`, or the next card marks the chapter complete and swaps the next chapter in at the top (URL replaced). With "Auto next chapter" on (app), reaching the end advances after 900 ms unless narration is playing.

#### 8.15.3 Chrome (tap anywhere toggles; fades in 240 ms `settle`, out 160 ms `lift`; no slide, because the bars are solid)

Solid stock-coloured bars with a 1 px rule in the stock's muted colour at 30 %:
- **Top** (52 px): back (`arrow-left`), running title (`type.nav` stock muted), offline mark (`wifi-slash`) when reading a saved copy, the soundscape indicator (`waveform` 16, only while a soundscape plays; tap opens the Type sheet at its `AMBIENT` group), then contents (`list-numbers`), bookmark (`bookmark-simple`; Fill when saved), voices (`voice-31`), on desktop fullscreen (`corners-out`, `corners-in` while fullscreen; `f`), type (`text-aa`); on desktop a margins toggle (`note-pencil`, `m`).
- **Bottom** (52 px + inset): previous chapter, the progress folio `42% · 6 MIN LEFT` (tap to cycle: chapter %, book %, time left; `g` or a long-press turns it into a number field `42 %` where Enter jumps to that paragraph bucket and Esc cancels), auto-scroll (`play` with the `strip-scroll` glyph, scroll mode only; Fill + spot rule and the speed folio `1.00×` while running; absent in paged mode), next chapter; a 1 px progress hairline along the top edge of the bar in the stock ink.
- **Auto-scroll chip**: while it runs, the §9.4.1 chip sits bottom-right above the bottom bar, painted in the stock (page colour at 90 %, a 1 px rule in the stock's muted colour, text in the stock ink).
- **Margins panel** (desktop, `m`): the manga reader's right panel (§8.14.12) in the stock colours, with contents tabs `NOTES · CIRCLE · VOICES`: this chapter's bookmarks and notes, the Circle panel with the spoiler guard, and the cast list (§8.16.5). The text column recentres in the remaining width (320 ms `turn`).
- The Listen mini player sits above the bottom bar when audio exists (§8.16.2).
- Chrome hides on downward scroll ≥ 24 px, shows on upward ≥ 56 px, at chapter end, or on tap.
- Desktop chrome also shows on pointer movement into the top 72 px or bottom 96 px. A click toggles the chrome only if, after `mouseup`, the selection is collapsed and the pointer moved ≤ 4 px since `mousedown`.
- System UI (app): the status bar shows and hides with the chrome, and the top bar is 52 px + `MediaQuery.viewPaddingOf(context).top` (§8.0.5 System bars). The column ignores system insets, so toggling the bars never reflows the text.

#### 8.15.4 Reading modes and page turns

- **Scroll** (default): one continuous column with seamless next.
- **Paged** (Type sheet → Layout): columns paginated to the viewport (web: CSS multi-column in a fixed-height container; Flutter: a paginator that splits paragraphs by measured line boxes). Page turns: `CUT` (default, 0 ms), `SLIDE` (280 ms `ease.settle` (`dur.pageturn`), finger-tracked; finger releases `spring.release`), `FADE` (160 ms). No curl in this skin. Tap zones 25 / 50 / 25 (back / menu / forward); presets "Both margins advance" and "One hand" (left 25 % back, top 12 % menu across the full width, rest forward). Page folio at the bottom centre (`p. 7 of 22` in this chapter).
- Progress is always saved as the paragraph bucket (1–100) at the reading line (38 % from the top in scroll mode, the first paragraph on the page in paged mode).

#### 8.15.5 Type sheet ("Text and page")

A `[0.5, 0.92]` sheet on phones, a 352 px popover under the `text-aa` button on desktop (max height `min(640px, 100vh − 52px − 24px)`, scrolling inside, with the `TEXT AND PAGE` kicker row sticky), painted in the current stock so the preview is honest. Kicker `TEXT AND PAGE`.

| Control | Range | Default | Scope |
|---|---|---|---|
| Face | Five tiles, each label set in its own face: `Newsreader`, `Literata`, `Source Serif`, `Atkinson Hyperlegible`, `Archivo` (§3.4; the `Newsreader` tile uses `var(--mm-font-newsreader)` / the `Newsreader` asset family, so Hyperlegible text never changes it); a caption under Atkinson reads "Designed for low vision" | Newsreader (Atkinson when Hyperlegible text is on) | per book (web K44 / mobile K25; `serif` → Newsreader, `sans` → Archivo) |
| Size | 14–40 px, stepper step 1 (`=`, `-`); absolute: the app renders the body with `TextScaler.noScaling`, so the value is the rendered size | The face's default in §3.4: 19 desktop / 18 phone (Newsreader, Literata, Source Serif, Atkinson); 18 / 17 (Archivo). In the app, a book with no stored size opens at `clamp(round(MediaQuery.textScalerOf(context).scale(d)), 14, 40)` for the face default `d`, so a user at system 2.0 starts at 36 px (34 px in Archivo); the value is stored per book once changed | per book (web K41) |
| Line spacing | 1.30–2.10 step 0.05 | The face's default in §3.4: 1.60 (Newsreader, Literata, Source Serif, Archivo); 1.70 (Atkinson) | per book (web K42) |
| Measure | 48–88ch step 2 | 64 | per book (web K43) |
| Margins (phone) | `NARROW · STANDARD · WIDE` (16 / 24 / 48 px) | Standard | per profile |
| Paragraph spacing | 0–1.2em step 0.1 | 0 (indents) | per book |
| Character spacing | −0.02 to +0.08em step 0.01 | 0 | per book |
| Bold text | switch (wght 400 → 520) | off | per profile |
| Justify and hyphenate | switch | off (ragged) | per profile |
| Layout | `SCROLL │ PAGED` | Scroll | per profile |
| Page turn | `CUT │ SLIDE │ FADE` (paged only) | Cut | per profile |
| Fullscreen (web) | switch; renders whenever `document.fullscreenEnabled` is true, at every width | off | session |
| Stock | Seven swatches (48 × 48 squares, each showing "Aa" in its own ink on its page, the chosen one with a 2 px `spot` frame): Nitrate, Ink, Sepia Night, Dusk, Moss, Rosewood, Issue (drawn in this book's own `ambient` colours; hidden when the series has no `ambient`) | Nitrate | per profile (web K40 / mobile K26 migrated §2.1.6); Issue resolves per book at render time |
| **`AMBIENT` group** (a kicker row, then its controls) | | | |
| Auto-scroll | play / pause (scroll layout only; in paged layout the row reads "Auto-scroll needs the scroll layout.") | stopped | session |
| Auto-scroll speed | speed ruler 0.50–3.00× in 0.05 steps, 1.00× = the profile's measured reading pace (default 250 wpm, §9.4.1); the WPM equivalent under the value | 1.00× | per book |
| Resume after I let go | switch (resumes 800 ms after release) | on | per profile |
| Soundscape | `OFF · MATCH THE MOOD ·` the eight loops (§9.4.2), each with `Hear` | `OFF` | per profile |
| Soundscape volume | 0–100 % | 40 % | per device |
| Reset | quiet `Reset text and page` | — | — |

Auto-scroll and Listen never run together: starting narration pauses auto-scroll (its chip shows `PAUSED FOR LISTEN`), and starting auto-scroll while narration plays pauses the narration. The soundscape ducks under narration as §9.4.2.

Every change applies live under the sheet. Steppers roll their digits (Folio flip).

#### 8.15.6 Contents sheet (`list-numbers`, `t` on web opens Type; `o` opens Contents)

Inside the novel reader: a `[0.5, 0.92]` sheet (phone), pre-scrolled to the current chapter, or the left column panel (desktop) in the stock colours, matching the manga Contents sheet (§8.14.3). Opened from the book page (§8.18), which has no stock, it is a standard §7.9 sheet: `paper.2`, a `rule.2` top edge and a `spot.wash` current row. Kicker `CONTENTS`, a compact go-to field ("Chapter number", decimal keyboard; Enter jumps to the first match; typing shows up to 30 matches "and 12 more"; "No chapter 480 in this book."), then contents rows (§7.16 novel TOC variant) pre-scrolled to the current chapter (`spot.wash` band). Rows show narrated (headphones) and saved marks. Loading, offline ("The contents need a connection to load.") and error states as notices.

#### 8.15.7 Bookmarks and notices

`b` or the bookmark icon saves the paragraph at the reading line plus its fraction and a 180-character snippet, with no dialog (haptic `bookmark.add`); the toast offers `Add a note`. Stale anchors open at the nearest paragraph with the toast "The text here changed. Opened at the nearest paragraph." Toasts in this frame use the stock's page colour for the band and its ink for the text.

#### 8.15.8 Keys and gestures

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
| `a` | Auto-scroll play / pause (scroll layout) |
| `<` / `>` | Auto-scroll slower / faster by 0.25× (as the manga reader) while auto-scroll runs; otherwise Listen speed ±0.05× (§8.16.4) |
| `m` | Margins panel (desktop) |
| `[` / `]` | Previous / next sentence (Listen) |
| `Shift+[` / `Shift+]` | Back / forward 15 s (Listen) |
| `,` | Type sheet (alias) |
| `g` | Go to %: turns the bottom bar's folio into a number field |
| `f` | Fullscreen |
| `Esc` | Close sheet → collapse full player → back to the book |

Gestures: tap toggles chrome (scroll mode) or zones (paged); long-press on a speaker-tinted run shows the speaker's name in a small popover (§8.15.2; hover on the web); horizontal swipe turns pages (paged) or changes chapter (scroll, ≥ 72 px, opt-in); left-edge vertical swipe changes brightness (a black overlay, −75 … 0, for night reading below the system minimum); iOS edge back (20 pt, live only in scroll layout with guided view off; pops without a Dip); Android back plays the Dip with no predictive preview. Both OSes, button and system back: pop when `context.canPop()`, otherwise `go('/sources/:sourceId/series/:seriesKey')` to the book page, which enters by Dip (§8.14.2).

#### 8.15.9 States

Loading: the page in the stock colour with 12 greeked lines at the body's line height (flicker at half strength). Offline: reads the saved copy; running head `wifi-slash`; at the end of the last saved chapter the end matter reads "End of the downloaded copy." with `Back to Downloads` in place of the next card. Error: notice "Couldn't load this chapter." + `Back to the book`. Not available (removed source or series, or hidden by the gate): the §8.0.10 notice in the stock colours. 18+ book: the rating card (§7.24) at the top-left of the page for its 3 s hold, in the stock colours. Empty: "This chapter came through empty — usually a page that was pulled or is still being published." Stale text: speaker tints and follow-along are withheld. Rate limited: `SLOW DOWN` band with countdown. Further on another device (a novel progress save returns `advanced: false`): the toast, in stock colours, "You're further ahead on another device (CH 214, 38%). Jump there?" with `Jump`. Saved copy (the chapter's `cache.stale` is true): a `SAVED COPY · 3 H` micro badge in the running head (1 px stock-muted outline, stock-muted text) with the tooltip "The source is down; this is the last copy we saved."

---

### 8.16 Listen mode: "The reading" (31 named voices) · web NR9–NR15 · mobile S26 #15–16, N3, N4

Audio is pre-rendered per chapter with measured segment timings; the player follows the text sentence by sentence and never guesses.

#### 8.16.1 Entry points

The opener's `Listen │ 14 MIN` button; `p` in the novel reader; the mini player's play; the book page's `Listen` button (starts at the resume point); the Downloads row for saved audio; a lock-screen or notification control (app). Headphone marks on the book's contents show which chapters are narrated (`GET /novels/audio/series`).

#### 8.16.2 Mini player

A 56 px bar above the novel reader's bottom bar, in the stock colours with a 1 px top rule:
- 36 px round `play` button (stock ink fill, glyph in the page colour); states play, pause, preparing (16 px leader dial), failed (`!` in `proof`, tap retries).
- Centre: `CHAPTER 12 · READ BY IRIS` (`type.kicker`) over a 2 px progress rule (buffered part at 35 %).
- Right: `−18:40` folio; on desktop `−15 s` and `+15 s` buttons and the speed folio `1.00×`.
- Tap the centre → full player. Swipe the bar left or right → next or previous chapter (phones).
- It rides with the chrome and lingers 5000 ms after the chrome hides, unless pinned (long-press → `Keep player visible`).

**Following along on the page.** While narration plays with the mini player (the novel page stays in view):
- the active sentence gets a `spot.wash` band (`rgba(244,208,63,0.16)`) that sweeps in left → right over 200 ms `dur.clip` `set`, as in §8.16.3, on every stock;
- the spoken word gets a 2 px underline in the stock ink that steps without animation;
- speaker tints keep their underline but drop their 12 % background under the band;
- the spoken paragraph is held at the reading line (38 % of the viewport, §8.15.4) by a 400 ms `dur.glide` `ease.settle` scroll that runs only when it leaves the 20–70 % band;
- a manual scroll decouples it and shows a `quiet` `Back to the voice ↓` in the stock colours above the mini player; it re-follows after 4000 ms idle;
- under reduced motion the band appears at once and the scrolls jump.

#### 8.16.3 Full player: "The reading room"

A takeover (Rise from the mini player; the cover match-cuts from the mini player's cover square into place).

| Area | Desktop | Phone |
|---|---|---|
| Background | The series cover duotoned to `ambient.duo`, `blur.card`, at **15 %** over `#000`, with `scrim.vignette` and grain 0.05 (art only). The low opacity is what keeps the transcript legible (§2.1.4 over-art rule; the full player is a row in the over-art table) | same |
| Head | Kicker `NOW READING ALOUD` in `ink.60`, series title in `type.headline`, chapter title as the deck; close `Done` | same, sizes per phone |
| **Transcript** ("lyrics") | Centre 6 columns: sentences in Newsreader 22/32. The active sentence is `ink.100` on a **highlighter** band (`spot.wash`) that *sweeps* across it left → right in 200 ms `dur.clip` `set` when it becomes active; the spoken word gets a 2 px underline that steps without animation; other sentences in `ink.60` at full opacity (5.34:1 on the brightest 15 % field, 7.20:1 on black; the active sentence is 9.21:1 in the worst case); dialogue sentences carry a small kicker above them with the speaker's name in their tint colour (`IRIS`, `DOKJA`; ≥ 6.80:1 on the brightest 15 % field, ≥ 9.17:1 on black). The active sentence is held at 38 % of the panel height; the view scrolls 400 ms `dur.glide` `settle` only when it leaves the 20–70 % band and jumps if it is 2 panels away. | Full width, Newsreader 20/30 |
| Decouple | A manual scroll stops following and shows a `Back to the voice ↓` secondary pinned at the bottom of the transcript; in this view it re-follows automatically after 4000 ms idle | same |
| Transport | Under the transcript: a chapter ruler (time), `0:00` and `−18:40` folios; buttons: previous chapter, `−15 s`, the 64 px round `play`, `+15 s`, next chapter | same, 56 px play |
| Tiles | Three square outlined tiles (1 px `rule.2`, 88 px tall): `SPEED 1.00×` (with `≈ 182 WPM`), `VOICES IRIS + 4`, `SLEEP END OF CH.` | Three tiles in a row |

"Highlight paused: the text changed." appears as a caption under the head when timings no longer match (`highlight_safe` false or fingerprint mismatch): audio keeps playing, the transcript shows unhighlighted.

#### 8.16.4 Speed ruler

Tapping `SPEED` opens a `[0.5]` sheet: a horizontal tick ruler 0.50–3.00× in 0.05 steps, labelled at 0.5, 1, 1.5, 2, 2.5, 3 (`type.folio`); the value previews while dragging (folio flag) and commits on release; preset slugs `0.8 · 1 · 1.25 · 1.5 · 2`; touch-and-hold anywhere on the ruler resets to 1.00×; the WPM equivalent under the value. Pitch is preserved (web `preservesPitch`; `just_audio.setSpeed`). Haptic `select` per 0.25× on phones. Keys: `<` / `>` ±0.05×.

#### 8.16.5 Voices and the cast

**Cast sheet** (`VOICES IN THIS CHAPTER`, or the `VOICES` tile): a credits list with dot leaders:
`Narrator ........................ Iris` (pinned first; tap to choose the narration voice)
`Kim Dokja ■ .................... Arlo · 34 %` (a 10 px square of the speaker tint, the voice, the share of lines; a lock mark when set by hand)
Rows ordered by line count. Status lines above the list: "Looking up who speaks here…", "Nobody else was identified with enough confidence, so the narrator reads every line.", "Narrated by {name}: their own lines use the narrator's voice." Owner-only actions in each row's overflow: `Same character as…` (alias merge), `Set gender`. Non-owners see the list read-only (voice names, no pickers).

**Voice picker: "the cast list of 31"** (opens from a row, filtered to the character's gender; also from Settings → Listen → Voices):
- Masthead in the sheet: kicker `A VOICE FOR KIM DOKJA`, filters `ALL · FEMALE ¹⁸ · MALE ¹³ · IN USE`, a compact search by name.
- Two columns on desktop (`MALE`, `FEMALE`, each ordered deepest first, as the server serves them), one column on phones with the gender as section heads.
- Each voice row (64 px): a 40 px monogram circle in a hue derived from pitch (deep voices cool, bright voices warm: field HLS L 0.28, S 0.45, hue linear from 220° at 80 Hz to 30° at 300 Hz, clamped; the letter in `ink.100`, worst case 5.13:1 at 60°), the name in Bodoni Moda Italic 20, the character descriptor in `type.caption`, a **pitch scale**: a 80–300 Hz ruler with a `spot` tick at the voice's `pitch_hz`, an **expressiveness meter**: five 6 × 6 squares filled `ink.100` by `expressiveness`, and actions `Hear` (secondary sm; plays `GET /novels/voices/sample`, the voice introducing itself, under the §6 Voice sample session state (`.playback` with `.duckOthers`; Android `AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK`), so the silent switch never mutes it; the button shows a leader dial while fetching and reads `Stop` while playing) and `Cast` / `CAST` (selected state, filled). **The sample pulses with the voice**: while it plays, a highlighter band in `color.spot` at alpha = 0.08 + 0.24 × RMS (RMS 0–1; attack 80 ms, release 240 ms) sits behind the voice's name, and a 2 px `spot` rule under the row runs left to right with the sample's progress. No bloom and no glow: the highlighter is the skin's way of marking a voice. Web: the sample plays through an `<audio>` element routed into a Web Audio `AnalyserNode` (`fftSize` 256), RMS computed each animation frame from `getFloatTimeDomainData`. Flutter: the sample plays through `flutter_soloud` 4.1.7 with visualisation on (`SoLoud.instance.setVisualizationEnabled(true)`), RMS computed each `Ticker` frame from `AudioData(GetSamplesKind.wave)` (256 samples) with `updateSamples()` and `getAudioData()`. The app always requests `GET /novels/voices/sample?voice={id}&format=ogg`, on iOS too. The pack is Ogg Opus, which SoLoud 4.1.7 decodes itself; it has no AAC decoder, so an `m4a` sample would not play. Reduced motion: a static `color.spot` band at alpha 0.20 while the sample plays. **Caption**: while a sample plays, the voice's `transcript` (from `GET /novels/voices`) appears under its row in `type.caption` `ink.60`, in a polite live region (`aria-live="polite"`; Flutter `Semantics(liveRegion: true)`), and collapses when the sample stops.
- Top row: `Automatic` ("Assigned by gender and speaking order") and, for the narrator picker, `Book default`.
- Footer caption: "Chapters already rendered keep the voice they were made with until they're rendered again." License and attribution per voice under `Details` in the row's overflow.
- Casting posts `POST /novels/cast` or `POST /novels/narrator`; the row shows `RE-VOICING` until those re-renders finish; after any cast or narrator change the cast sheet footer shows the owner a quiet `Re-narrate 38 chapters`, which opens the Audiobook sheet (§8.16.8) with `RE-VOICE` selected (nothing re-renders until it is sent); haptic `voice.assign`; error toast "That voice couldn't be saved." with the reason.
- Empty: "No voices are installed on the server, so characters can't be cast from here yet."

#### 8.16.6 Sleep timer

`SLEEP` opens a list sheet: `Off · 5 · 10 · 15 · 30 · 45 · 60 min · End of chapter · End of next chapter · Custom…` (custom is a minutes stepper). The tile and the mini player show the live countdown folio. The last 8 s fade the volume out (haptic `sleep.fade`). Phones: shaking the device during the fade or in the last minute extends by 5 minutes (setting "Shake to extend", default on; toast "Sleep timer +5 min"). The app reads `sensors_plus` 7.1.0 `userAccelerometerEventStream()` only during that last minute (a shake is two peaks above 25 m/s² within 600 ms); mobile web has no shake.

#### 8.16.7 Chapter boundary

At the end of a chapter's audio: a **post-play card** at the bottom of the transcript: kicker `NEXT`, `Chapter 13` typed at 50 ms per character, a 40 px countdown dial (§7.18) running 5 s, `Play now` (primary) and `Cancel` (quiet). When the countdown completes, playback continues into chapter 13 and the reader swaps the text in place. With the sleep timer at "End of chapter" the card is skipped and playback stops.

#### 8.16.8 Audiobook: narrate and save (book page, owner)

Only the owner (admin) sees the `Audiobook` button; for everyone else it is not rendered (narration is an owner action on the narration PC), and they save existing audio per chapter from the opener or the mini player (§8.16.9). The book page's `Audiobook` button opens a sheet: kicker `AUDIOBOOK`, segmented `NARRATE │ SAVE TO THIS DEVICE` (Save only when a downloads scope exists), quick picks slug line `NEXT 10 · ALL UN-NARRATED ⁽³⁸⁾ · RE-VOICE ⁽ⁿ⁾ · NONE` (or `ALL NARRATED`; `RE-VOICE` selects the narrated chapters whose `rendered_at` is older than the book's `cast_changed_at`, and is absent when there are none), then a checklist of chapters with status captions (narrate: `ALREADY NARRATED · SAVED`, `ALREADY NARRATED`, `DOWNLOAD THE TEXT FIRST`; save: `SAVED`, `SAVED COPY CAN'T PLAY ON THIS PHONE`, `SAVING…`, `COULDN'T BE SAVED`, `NARRATED`, `NOT NARRATED YET`), an estimate caption ("About 9 minutes of rendering per chapter on the narration PC." / "Saves while the app is open; the text is saved too."), and the primary `Narrate 12 chapters` / `Save audio of 12 chapters`. In NARRATE, already-narrated chapters are selectable and captioned `ALREADY NARRATED · WILL BE RE-VOICED` when selected; the sheet sends `force: true` for those keys and `priority: 0` for the whole request (the opener's `Narrate this chapter` sends `priority: 9`, because the render queue runs highest priority first, `novel_render_queue.py:188`, so the chapter being read jumps the queue). `GET /novels/audio/series` gains `chapters[].rendered_at` and `cast_changed_at` (the latest `POST /novels/cast`, `/novels/cast/alias` or `/novels/narrator` for the book). Below, when jobs exist: a job list with determinate rules per job (queued, planning, rendering with progress, done, failed with the error, cancelled) and `Cancel` per job ("It stops shortly."). A global indicator appears in Index and Downloads: `NARRATING 3 CHAPTERS` with a mini rule. `narration_unavailable`: caption "Narration of new chapters isn't available right now. Chapters that already have audio can still be saved." Poll cadence as the inventory (5 s; ×3 while waiting for the render PC; back-off to 60 s on failures).

#### 8.16.9 Saved audio on the device

The mini player's overflow and the opener show the audio save state: `Save audio to this device` → saving (leader dial) → `Audio saved` (check) → tap asks "Remove saved audio? The chapter stays on this device to read." / failed "Couldn't save the audio. Tap to try again." / unplayable "The saved audio can't play on this device. Tap to save it again." iOS requests `m4a`; a first request answered `503 audio_preparing` shows "Preparing the audio…" with a leader dial and retries after the server's `Retry-After`.

#### 8.16.10 Lock screen and background (app)

Narration keeps playing with the screen locked and the app in the background, with lock-screen and notification controls (title, chapter, cover, play/pause, ±15 s, next chapter) through `audio_service` 0.18.19 (MIT) wrapping the existing `just_audio` player; the `audio_session` configuration is State B, `speech()` with Android `AUDIOFOCUS_GAIN`, while narration is active (§6 audio session and focus policy). This is a new native dependency in its own commit (§15.3). Its Android notification uses the small icon `ic_stat_mm` and the accent `#F4D03F`: `AudioServiceConfig(androidNotificationIcon: 'drawable/ic_stat_mm', notificationColor: Color(0xFFF4D03F), androidNotificationChannelName: 'Listen')` (§12.2).

**Native wiring and a single init** (§15.10 S14):
- **`MainActivity.kt`:** `class MainActivity : AudioServiceActivity()` (from `com.ryanheise.audioservice.AudioServiceActivity`, which extends `FlutterActivity`). The existing `configureFlutterEngine` (native channel and `OcrChannel`), `onCreate`, `onResume` and key handling stay as they are.
- **`AndroidManifest.xml`:** `<service android:name="com.ryanheise.audioservice.AudioService" android:foregroundServiceType="mediaPlayback" android:exported="true">` with the `android.media.browse.MediaBrowserService` intent filter; `<receiver android:name="com.ryanheise.audioservice.MediaButtonReceiver" android:exported="true">` with `android.intent.action.MEDIA_BUTTON`; `<uses-permission>` for `android.permission.FOREGROUND_SERVICE` and `android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK`.
- **iOS:** already has `UIBackgroundModes: audio` (`Info.plist`).
- **Init:** `AudioService.init(builder: () => NarrationAudioHandler(player), config: AudioServiceConfig(…as above…))` runs once in `main()`, before `runApp(AppRestart(…))`, because it asserts it runs only once per engine and a skin switch restarts inside the same engine. The handler reaches the tree as `audioHandlerProvider.overrideWithValue(handler)` in the root `ProviderScope` (§8.30.3), so a skin switch never calls `init` again.
- This lands in the isolated native-plugin commit (§15.3); any other `MainActivity` channel added by this contract goes into the same class.

Mobile and desktop web both use the Media Session API (`navigator.mediaSession.metadata` with title, chapter, cover artwork at 256 and 512 px, and the `play`, `pause`, `seekbackward`, `seekforward` (15 s), `previoustrack`, `nexttrack` handlers) with no dependency, so keyboard media keys and the OS media overlay drive narration on desktop too.

#### 8.16.11 States

Preparing (`503 audio_preparing`), playing, paused, buffering (leader in the play button), failed ("Audio couldn't be loaded." + Retry), no audio for this chapter (Listen button absent; opener shows `NOT NARRATED` for the owner with `Narrate this chapter`, sent with `priority: 9`, §8.16.8), highlight paused (text changed), offline with saved audio (works), offline without saved audio ("This chapter's audio isn't saved on this device."), voices unavailable (empty cast list).

#### 8.16.12 Keys and gestures

Keys as §8.15.8 (`p`, `[`, `]`, `Shift+[`, `Shift+]`, `<`, `>`, `Esc` collapses the full player). Gestures: swipe down on the full player collapses it to the mini player (finger-tracked, `spring.sheet`); swipe the mini player sideways to change chapter; tap a transcript sentence to play from it (haptic `select`).
---

### 8.17 Series page, manga: "The feature" · web R7, R17 (SD1–SD21, SS1–SS18) · mobile S10, S18 (manga body)

One screen for `/sources/:sourceId/series/:seriesKey` and `/library/:followedId`. Data: source series + chapters + progress (`GET /reader/progress/series`) + the follow row when followed (favourite, status, notify, override), + `ambient`.

**Hierarchy.** Title treatment → the one action (Read or Continue) → credits → chapters → everything else.

**Desktop layout.**
1. **Spread** (`clamp(520px, 64vh, 760px)`), like Tonight's cover story but for this series:
   - Columns 1–5: kicker in `ambient.ink` (`MANHWA · ONGOING · 201 CHAPTERS`); title in `type.headline` (length rules §3.1) with the letter reveal after the match cut lands; deck = the synopsis's first sentence in `type.deck` italic; **credits** (`STORY` author, `ART` artist, `SOURCE` name with its health mark, `STATUS`, `UPDATED 2 D AGO`, rating certificate when mature and visible); actions row: `split` primary (`Read │ CH 1`, `Continue │ CH 143 · p.12`, or disabled `All caught up`), `secondary` `Read all` (strip glyph; manga with > 1 chapter; tooltip "Every chapter in one continuous scroll"), `secondary` `Previously on…` (only when `GET /ai/recap/availability` answers `available`, §9.1.5), then bare icon buttons: Follow (`plus` → `check` "Following"; stamp haptic; toast "Following {title}. New chapters will notify you."), Favourite (`star`), Notify (`bell-ringing`, only when followed), Download (opens §8.19), Recommend (`paper-plane-tilt`, Circle on), overflow.
   - Columns 6–12: the cover at full spread height against the right edge, `blur.bleed` duotone fill, `scrim.gutter`, grain, Drift; the reading progress rule along its bottom.
   - Page spill: the 30 vh under the spread fades from `ambient.tint` to `#000`.
2. **Contents tabs** (sticky under the running head): `01 CHAPTERS²⁰¹ · 02 DETAILS · 03 MORE LIKE THIS · 04 CIRCLE`.
3. **CHAPTERS** (columns 1–8) + **At a glance** aside (columns 9–12) from 1024 px, `position: sticky; top: calc(56px + 48px + 16px)` (running head + contents tabs + 16). Below 1024 the tablet rule applies (At a glance at the top of DETAILS, §8.0.9):
   - Toolbar: `NEWEST │ OLDEST` segmented (persisted per series, web K45), compact go-to field ("Chapter number"), `Select` (quiet), download summary `12 OF 201 SAVED` + `Download` (secondary sm).
   - Schedule rows (§7.16): chapter folio, title, date, pages, progress, `READ`, download mark, reaction count; the current chapter has a `spot.wash` band and a `READING` badge. Rows prefetch the manifest after a 150 ms hover or focus dwell (and the first 2 on load), as P3 requests of the sources limiter (§15.6). Windowed list (virtualised) for long series.
   - Series download card (when anything is saved or queued; §8.19).
   - Aside: a numeral `142 / 201` with the caption `CHAPTERS READ`; reading status as a slug-line select (`READING · PLAN TO READ · ON HOLD · DONE · DROPPED · NOT STARTED`); `YOUR TIME HERE 11 H 20 M`; tags (own tags as removable tokens + `Add tag`; when the AI desk is available, a `SUGGESTED` kicker line follows with up to 5 suggested tags from `GET /ai/tags?source&series` as dashed-outline tokens, each with `+` to accept (it becomes an own tag, haptic `select`) and `x` to reject (`POST /ai/feedback {signal: "tag_rejected", source_id, series_key, tag}`); the line is absent when the desk is closed or nothing is suggested); shelves containing it (+ `Add to shelf`); OCR coverage "Dialogue indexed for 34 of 201 chapters" with a determinate rule.
4. **DETAILS**: the full synopsis in `type.body` 17/28 at 62ch with a Bodoni drop cap; alternate titles (CJK in the Noto fallbacks); genres as a slug line of links (each opens the source catalogue filtered to that genre, `?genre=`); enriched metadata as credits (`FORMAT`, `ANILIST ★ 8.4`, official platforms as `Read on {site} ↗` links) from `GET /series/enrichment?source&series` (new, §15.5: the series matched to AniList server-side by title and alternate titles, cached 30 days, `null` when no confident match); the credits are simply absent while it loads or when it is `null`; source credit and `Open on {source}`.
5. **MORE LIKE THIS**: a `Similar` rail (§9.1.4) and `Because you read {title}` rail; AI unavailable fallback: series from the same genres on your sources.
6. **CIRCLE** (§9.3): who follows or read it (`GET /circle/series`, §9.3.8: "Riya is on Ch. 150"), their reactions per chapter, `Recommend to…`. Disabled with a tooltip when the profile shares nothing.

Overflow menu: View cover (Lightbox, §7.30), Add to shelf, Set reading status ▸, Tags…, Treat as 18+ / not 18+ / use the source rating (radio), Check for new chapters (per-series check), Open the source's page ↗, Find it on another source (search prefilled with the title), Move to another source… (followed series only), Share link (web: copy), Unfollow (proof).

**Move to another source** (the repoint flow; shown first, under a `NOTE` banner "This source is down. Move the series to another source to keep reading.", when the source's health is `dead`). A sheet (phone) or column panel (desktop), kicker `MOVE TO ANOTHER SOURCE`:
1. *Candidates*: the title searched across every other visible source (tier order, same status line as Discover); each candidate row shows the source logo 24, the source's title, `CHAPTERS 150 · LATEST 3 D AGO`, the health mark, and the cover at 40 × 60. States: searching (3 greeked rows), none ("No other source has this series."), a source that didn't answer (`CORRECTION` caption with `Retry` for that source).
2. *Mapping*: after a candidate is picked: "Your place moves by chapter number. You're on chapter 142; Asura has chapters 1–150, so chapter 142 there becomes your place." When numbers do not line up: "Chapter numbers don't line up, so you'll start at chapter 1 on Asura." A checkbox "Keep following it on MangaDex too" (off). Actions `Move` (primary) and `Back` (quiet).
3. *Moving*: `Move` loading; `POST /library/series/{followed_id}/repoint {source_id, series_key, keep_old}` (new, in the existing `/library/series/{followed_id}` family) → `{followed: FollowedSeries, mapped_chapter_key, mapped_chapter_number | null}`. `keep_old` is the "Keep following it on MangaDex too" checkbox: `true` keeps the old follow row and creates a new one; `false` repoints the row and fills the existing `migrated_from_source`, `migrated_from_series_key`, `migrated_at` columns. Progress is mapped by chapter number server-side either way. Done: the page match-cuts to the new source's feature page and a toast says "Moved to Asura. You're on chapter 142." Error: "Couldn't move this series." + `Try again`; offline: the item is disabled with the tooltip "Moving needs a connection." Keys: `m` opens it on the web.

**Phone layout.** No thumb index on this screen. Running head transparent with back and overflow. The cover full-bleed 4:5 with `scrim.foot` into `ambient.tint`, Drift; the title block overlaps its lower quarter (kicker, `type.headline` 32/36, deck 2 lines); then the actions: `split` primary full width, a row of `Read all` and `Previously on` (secondary, half width each), then a row of the icon buttons with labels under them (`FOLLOW · FAVOURITE · NOTIFY · DOWNLOAD · SEND`; the labels keep `wdth` 62 and cap at text scale 1.3, §3.3 "Labels in fixed cells"); credits single column; then the contents tabs, sticky under the running head; the At a glance block sits at the top of DETAILS.

**Platform deltas.** iOS: edge swipe back reverses the match cut with the finger. Android: predictive back fades through. Mobile web: identical to the app; long-press on chapter rows opens the row menu. Desktop: hover reveals row actions (download, mark read) at the row's right end.

**Signature moment.** The match cut lands the poster on the spread, the letters of the title set, the credits appear in reading order, and the ambient colour washes the page top over 800 ms: the series gets its own issue colour.

**Transitions.** In: match cut from any poster or cutting; Page from lists without a cover. Out: Column wipe to the reader; reverse match cut on back.

**Gestures.** Swipe between contents tabs (phones); long-press the cover → Lightbox (§7.30); long-press a chapter → Mark read / Mark read up to here / Mark unread / Download / Bookmark start; swipe a chapter row left → Mark read.

**Mark read and Mark unread** (the calls behind these controls here, on the book page (§8.18), in the Cutting Quick look (§7.6) and in Library select mode (§8.9)):
- `Mark read` (one chapter: swipe-left, desktop hover, the long-press menu, the Cutting Quick look) sends `POST /reader/progress/batch` with one row `{source_id, series_key, chapter_key, chapter_number, last_page: max(page_count, 1), page_count: max(page_count, 1), scroll_offset_px: 0, is_completed: true, time_spent_seconds: 0, manual: true}`.
- `Mark read up to here` (long-press menu) sends the same rows for every chapter numbered at or below the tapped one that is not completed yet, in chunks of 200.
- `Mark unread` (one chapter) sends `DELETE /reader/progress {source_id, series_key, chapter_keys[] (≤ 200)}` (profile-scoped, 204); continue-reading then resolves to the furthest remaining row.
- A `manual: true` row is saved without a `ReadingSession`, so marking never moves statistics or streaks (§9.2).
- Toasts: "Marked 42 chapters read." with `Undo`, which deletes only the keys that were not completed before; "Marked chapter 142 unread." with `Undo`, which re-posts the deleted rows (the client keeps them until the toast closes).
- Offline: all four controls (both Mark reads, Mark unread, the select-mode pair) are disabled with the tooltip "Needs a connection."

**Keys (web).** `Enter` or `c` continue (Column wipe); `a` read all; `p` previously on; `v` view cover (Lightbox); `f` favourite; `n` notify; `+` follow / unfollow toggle (asks nothing, toast with Undo); `d` download panel; `1`–`4` tabs; `j`/`k` chapters; `x` select; `/` go-to field; `o` newest/oldest.

**States.** Loading (galley spread: title bars, credit lines, cover plate; 8 greeked chapter rows); chapters offline ("The chapter list needs a connection."); chapters unavailable ("MangaDex lists 201 chapters but returned none just now — usually the source, not you." + `Try again`); no chapters ("No chapters yet. The source hasn't published any." + `Back to the source`); series error (`CORRECTION` "Couldn't load this series. The source did not answer." + `Try again` + `Back to the source`); offline with saved chapters (page renders from the local store with `OFFLINE EDITION`; only saved chapters are enabled); follow limit reached ("You're following 1,000 series, the limit for a profile."); stale catalogue (`SAVED COPY` badge); not available (`series_not_found`, `source_not_found`, or hidden by the gate: the §8.0.10 notice instead of the series error).

---

### 8.18 Series page, novel: "The book" · web R17n (NB1–NB19) · mobile S18 (novel body), N2, N3

Front matter set like a book's title page, then the contents.

**Desktop layout.** No spread art; the book is typographic.
- Columns 1–7: kicker `NOVEL · ONGOING · NOVELARCHIVE`; title in Bodoni Moda Roman `type.masthead`; byline "by {author}" in Newsreader Italic 22; a 56 px rule; facts as credits: `CHAPTERS 1,204 · ≈ 2.1M WORDS · ≈ 140 H · ONGOING`; the estimate note "Length estimated from 12 chapters read so far." (`type.caption`); the blurb in `type.body` 17/28 with a Bodoni drop cap, max 62ch; genres as a slug line of links.
- Actions: `split` primary `Start reading │ CH 1` / `Continue │ CH 212 · 42%` / disabled `All caught up`; `secondary` `Listen` (when narrated chapters exist; starts Listen at the resume point); `secondary` `Previously on…` (only when the recap availability answers `available`, §9.1.5); icon buttons Add to library (`plus` / `check` "In your library"; toast "Added {title}. New chapters will notify you."), Download book (with the unsaved count folio), Audiobook (§8.16.8, owner only), Recommend, overflow. The overflow matches the feature page's (§8.17), including **Move to another source…** for followed books: the same repoint flow and `POST /library/series/{followed_id}/repoint` (with `keep_old`, §8.17), mapping the place by chapter number, shown first under the `NOTE` banner when the source is `dead`.
- Columns 9–12: the cover plate 168 × 248 (square-cornered, 1 px `rule.2`), a duotone copy of the cover filling columns 9–12 behind the plate (cover fit), at `blur.bleed` (56 px), duotoned to `ambient.duo`, as the novel cover story's field (§8.0.8), and under it "In the circle" avatars when others read it.
- **Contents** (full 12 columns under a section rule): toolbar `FIRST → LAST │ LAST → FIRST` (default first → last), go-to field (matches list up to 12 buttons "and n more"), `Pick chapters` (select mode for downloads), `Narrated only` toggle. Contents rows (§7.16) windowed around the focus (400 at a time) with `Show earlier chapters (n)` above and `Show more chapters (n)` below; the focused chapter (`?chapter=` or go-to) scrolls to centre with the `spot.wash` band.

**Phone layout.** Plate 96 × 144 floats right of the title block; facts wrap into two lines; blurb collapses to 5 lines with `More`; actions stack as on the feature page; contents full width; go-to via a search icon that opens the contents sheet in search mode (N2).

**Signature moment.** The title-page set: title letters, byline, the rule drawing, and the drop cap of the blurb setting last.

**Transitions.** In: match cut from a book-list plate (plate → plate). Out: Column wipe to the novel reader; Rise to the audiobook sheet.

**Gestures.** Long-press (phones) or double-click (desktop) the cover plate → Lightbox (§7.30); long-press a contents row → Mark read / Mark read up to here / Mark unread / Download / Bookmark start (the §8.17 calls); swipe a contents row left → Mark read.

**Keys (web).** `Enter`/`c` start or continue; `l` listen; `p` previously on; `v` view cover; `+` library toggle; `d` download book; `/` go-to; `o` order.

**States.** Front matter loading (galley), offline ("This book needs a connection to load."), error (+ `Back to the source`), not available (the §8.0.10 notice); contents loading (10 greeked rows), offline, error, unavailable ("Contents didn't come through."), empty ("No chapters yet."); narration unavailable caption; prefetch of the first three chapters happens silently (P3 in the sources limiter, §15.6).

---

### 8.19 Chapter selection and downloads on series pages · web DP1–DP7, SD14–SD17, SS13–SS16, NB12–NB18 · mobile S10 #8–17, M2

- **Trigger**: `Download` (manga) or `Pick chapters` (novels) enters select mode on the chapter list. Rows gain a leading checkbox; saved chapters are disabled (checked and dimmed); Shift-click selects a range; long-press starts selection on phones.
- **Selection bar** (bottom on phones, under the running head on desktop): `12 SELECTED · 3 ALREADY SAVED`; quick picks as a slug line with counts `NEXT 10 · ALL UNREAD ⁴² · WHOLE BOOK` (novels) `· ALL ²⁰¹ · NONE`; `Done` (quiet) and `Download 12` (primary).
- **Running**: `DOWNLOADING 4 OF 12` + determinate rule + `Stop`; per-row download marks animate as the queue works (§7.18).
- **Summary line**: "12 chapters saved." / "Nothing to download — those are already saved." / "10 of 12 saved, 1 with missing pages, 1 failed." / "Out of room: only 380 MB free. Remove some downloads and run it again." (with `Manage downloads`) / "Stopped: 4 saved." + `Dismiss`. Problems use the `NOTE` tone.
- **Series download card** (feature page, when anything is saved or queued): kicker `ON THIS DEVICE`, `12 OF 201 CHAPTERS SAVED` with a determinate rule (`set` when complete), `DOWNLOADING NOW · PAGE 7 OF 40`, `3 WAITING · 1 FAILED`, the pause reason line when blocked (`NOTE`: "Paused: this phone is almost full." / "Paused: your 10 GB limit is full." with `Storage settings`), and in the app (iOS and Android) the foreground note "Downloads run while the app is open; leaving pauses them and coming back picks up where they stopped."
- **No profile**: "Downloads belong to a reading profile. Choose one to save chapters." + `Choose a profile`.
- **Novels**: "Whole book" pages through `POST /novels/chapters` 20 at a time; the bar shows `SAVING THE TEXT…`.
- Haptics: `download.start` when the queue accepts; `download.done` once when the batch finishes.

---

### 8.20 Discover: search · web R14 (SE1–SE11) · mobile S20 · new scopes

**Hierarchy.** The index field → scopes → results by source (or the idle page).

**Desktop layout.**
- Masthead: kicker `No. 04 — DISCOVER`, then instead of a title the **index field** (§7.4) spanning 8 columns, placeholder typed "Search every source". A visually hidden h1 is the route focus target (§14.4): web `<h1 className="sr-only" tabIndex={-1}>Discover</h1>`; Flutter `Semantics(header: true, headingLevel: 1, label: 'Discover')` on a zero-size box holding the route `FocusNode`.
- Scope tabs under it: `ALL · LIBRARY · SOURCES · DIALOGUE · ASK` (ASK only when AI is available; DIALOGUE only in manga mode with OCR enabled).
- **Idle page** (no query), in 12 columns:
  - `RECENT` slug line of the last 4 searches (per profile, min 2 characters) with `Clear`.
  - `ASK THE EDITORS` (when AI available): a Feature-sized block with the typed example ("A murim regressor who comes back stronger") and `Ask` → Picks (§9.1.3).
  - `01 Browse by genre`: a grid of genre tiles (16:9, a representative cover duotoned to its own `ambient.duo`, tilted 0° — covers never tilt in this skin — with the genre in `type.subhead` italic over `scrim.foot`; hover and pressed as the §7.6 Feature card: the image zooms 1.04 inside the frame and the genre underlines, 200 ms `dur.clip` `settle`, pressed a 1 px impression); genres from the profile's histogram first. There is no cross-source genre endpoint, so the tiles are the union of the pinned sources' genre lists (the existing per-source genres call, cached 24 h per source, gated on serve), matched case-insensitively and ordered by the profile's genre weights; the cover is the first series of that genre on the first pinned source that has it. A tile opens a sheet (column panel on desktop), kicker `GENRE`, title "Romance", listing the pinned sources that expose that genre as rows (logo, name, health mark) that open each catalogue with `?genre=`; when only one source has it, the tile opens that catalogue directly. No pinned sources: the section is not rendered.
  - `02 Sources`: pinned sources as a credits list (logo 24, name, health mark, `18` certificate when visible) + `All 89 sources →`.
  - `03 Search what they said`: an entry block for dialogue search with the `bubble-search` glyph.
  - `04 Trending on your sources`: a slug line of series titles taken from each pinned source's `popular` browse mode (the first two titles per source, at most ten, de-duplicated by title), each a link to its feature page. Built from existing browse data, never from other profiles' searches (which would break per-profile isolation). Absent when no pinned source has a popular mode.
- **Results** (after 300 ms debounce, or immediately on Enter):
  - Status line (`type.caption`): "Searching your library and 12 pinned sources…" → "48 results · 12 sources" → "48 results so far · searching 77 more sources…" with an indeterminate rule while tier 2 runs; failures: "3 sources didn't answer." (`NOTE`).
  - Group jump bar (desktop, sticky): source names with counts as a slug line; clicking scrolls to the group (400 ms `dur.glide` `settle`).
  - `IN YOUR LIBRARY` group first (from `/library/search`), then source groups in tier order, then `IN DIALOGUE` (top 3 OCR hits with `See all`).
  - Each group: a subhead row (24 px source logo or the Library mark, source name in `type.title`, count badge, health mark) and a rail of posters with captions (title 2 lines, `CHAPTERS 120`); failed groups show `CORRECTION` caption "This source didn't answer." + `Retry` (retries only that source, with two flicker plates while it runs); empty groups collapse into `Show 31 sources with no matches` (quiet toggle).
  - Filter slugs above the groups: `ALL · WITH RESULTS · PINNED`.
- **ASK scope**: the field becomes a prompt ("Describe what you feel like reading"); submitting runs the world suggest (§9.1.3) and shows its results here; keyword search is one tap away.

**Phone layout.** The index field at 28 px in the masthead area (the running head shows `DISCOVER` once it scrolls away); scopes as a scrolling contents row; idle sections stack; genre tiles 2 per row; results as rails (3.2 posters); failed/empty groups as above; the group jump bar becomes a `Jump to source` sheet button.

**Platform deltas.** iOS/Android: the keyboard opens on the third tap of the Discover tab and on `/` with a hardware keyboard; search submits on the keyboard's search key. Mobile web: `enterkeyhint="search"`. Desktop: `/` focuses; `↓` moves into results; group jump with `[`/`]`; the scope tabs switch with `1`–`5` (here, unlike other contents tabs, `[` / `]` belong to the result groups).

**Signature moment.** Typing in the index field in Bodoni Italic that turns to Roman as it becomes a query; results then **Set** group by group as tiers arrive.

**Transitions.** In: Cut (tab) or Dip; `?q=` prefilled from Picks' `Search my sources`. Out: match cut to feature pages; Page to Sources.

**States.** Idle; searching (tier 1 skeleton: 3 groups of 4 flicker plates); partial (tier 2 running); results; no results (`NOTHING FOUND`: "No series match "{q}" in your library or sources." + `Ask the editors` when AI available); offline ("Search needs a connection to reach your library and sources."); error; rate limited.

---

### 8.21 Sources · web R15 (SL1–SL13) · mobile S16 · G4

**Desktop layout.**
- Masthead: kicker `No. 04 — DISCOVER / SOURCES`, title "Sources", deck "89 sources · 84 healthy · 6 pinned" (from `/system/source-health`, gated counts).
- Toolbar: compact filter field ("Filter sources", matches name or id), slug line `ALL · PINNED⁶ · 18+` (18+ only when the gate is open) and the content mode.
- **Pinned** section: a table (a list with columns) of pinned sources in pin order, each row draggable (≤ 50, `PUT /sources/pins`).
- **All sources** section: a directory table: logo 32 (favicon, or a Bodoni initial on `paper.1` as fallback), name (`type.title`) + description (`type.caption`, 1 line), `LANGUAGE`, `KIND` (Manga / Novel), health (mark + "OK · last checked 4 min ago", "FAILING · 3 errors", "DEAD since 12 Sep", "DEMOTED" with strike), `18` certificate, and a pin toggle (`push-pin`; Fill + spot rule when pinned; `aria-pressed`, "Pin {name}").
- Pins that no longer resolve (a mature source under a closed gate, a removed connector, the novels flag off) are omitted by the server from `GET /sources/pins` and come back when the source does; the client never shows or filters them.
- Row click → source catalogue (Page).
- Pin feedback: toast "{name} pinned" / "{name} unpinned"; failures "Couldn't update your pinned sources." (`proof`); if pins fail to load: a `NOTE` banner "Pinned sources couldn't be loaded, so pinning is off until they are." + `Try again`.

**Phone layout.** Rows 64 px: logo 32, name + description, health mark and `18` at the right, pin button (48 hit); pinned section first with drag handles; toolbar as a scrolling slug line + filter field.

**Gestures.** Pull to reprint (§11) refetches `GET /sources` and `GET /sources/pins` (A073). **Platform deltas.** Phones: long-press a row for `Pin` / `Unpin` / `Open` / `Health details` (a sheet with the last error and last OK time), and on pinned rows `Move up` / `Move down` / `Move to top` / `Move to bottom` (§7.22); pinned rows reorder by their handle; haptic `select` on pin. Desktop: hovering the health mark shows the last error in a tooltip. Mobile web: as phones, without haptics.

**Transitions.** In: Page from Discover, Cut from the sidebar. Out: Page to the catalogue.

**Signature moment.** The health column reads like a festival listing: each row's mark and status text line up on one column rule, and dead sources are set with a strike-through, so the directory is scannable at a glance.

**Keys (web).** `/` filter; `j`/`k` rows; `Enter` open; `p` pin toggle; `Alt+↑/↓` reorder pinned.

**States.** Loading (10 greeked rows); error (`CORRECTION` + Retry); offline (notice `OFFLINE EDITION` "The source list needs a connection." with the pinned rows below it from the last cached list, read-only); none installed ("No sources installed on this server."); no match ("No sources match "{q}"."); pinned empty ("No pinned sources. Tap the pin on any source to keep it at the top."). The directory looks complete at both 89 and about 33 rows (gated profile): no gaps, counts computed after the gate.

---

### 8.22 Source catalogue · web R16 (SB1–SB15) · mobile S17

**Desktop layout.**
- Masthead: the source's logo (48) beside its name in `type.masthead`; deck: "Catalogue · 1,240 series" (+ ` · "{q}"` when searching); freshness credit `UPDATED 12 MIN AGO` or the `SAVED COPY · 3 H` badge (tooltip: "The source is down; this is the last copy we saved."), ticking every 30 s; `Refresh` (quiet with `arrow-clockwise`, spins as a leader while refreshing; `refresh=true`).
- Toolbar: browse modes as contents tabs with the server's labels (scrollable, any string; hidden while searching), a `Genre` select (single-select menu of the source's genres, "All genres"; only when the source has genres), and a compact search field ("Search this source", 300 ms debounce, `/`).
- **Grid**: a poster wall in caption mode **Below** (§7.7), with the title on 2 lines (`type.title`) and no folio line, 6 per row desktop / 8 wide / 3 phone / 5 tablet; novel sources show the book list (§8.9.1).
- Infinite scroll with a sentinel 600 px before the end; `LOADING MORE` caption with a leader dial; load-more failure: "Couldn't load more." + `Retry` (refetches only that page); end: a 1 px rule and `END OF CATALOGUE` kicker centred.
- **Opening state** (first load): the source name sets itself with the letter reveal in the masthead, a 32 px leader dial beside the deck, and under it the grid's flicker plates; after 3 s the deck changes to "This source can take about 10 s." and a line of tips types itself in rotation every 3.5 s ("Press / to search this source.", "Pick a browse mode to change the order.", "Tap a genre on any series to browse it here.", "Your progress syncs across devices."); a background wash with hue = the 32-bit FNV-1a of the UTF-8 source id (the hash of §8.0.4) mod 360, S 0.35, L 0.06, fades in after 3 s. Data arrival dissolves the plates into posters (160 ms).
- A floating `TOP` square button (40 px, `paper.2`, 1 px `rule.2`, `arrow-up`) appears after 400 px of scroll (phones, bottom-right above the thumb index; desktop, bottom-right of the content).

**Phone layout.** Running head: back + logo 24 + name; the search field under it; browse-mode tabs; the wall 3 columns; pull to reprint (refresh from the source).

**Platform deltas.** iOS and Android: haptic `select` once when the first page of results lands; the `TOP` button sits above the thumb index. Mobile web: the same without haptics. Desktop: the wall is keyboard navigable and hover slates are off here (a catalogue is scanned, not browsed poster by poster).

**Transitions.** In: Page from Sources, Cut when opened from a genre link. Out: match cut to feature pages.

**Keys (web).** `/` search; grid keys (`h j k l`, arrows, `Home`/`End`); `Enter` open; `[`/`]` browse modes; `r` refresh.

**States.** Opening; loaded; empty ("No series found." / `No results for "{q}" on this source.`); full error (`CORRECTION` "Couldn't load the catalogue." + message + `Try again`); stale; offline (the saved copy if one exists, else notice); rate limited (countdown in the deck); not available or not browsable (§8.0.10).

---

### 8.23 Downloads and storage: "The offline edition" · web R23 (DL1–DL9) · mobile S21, S32, M5 · G10

**Hierarchy.** What's stored and how full → what's running → the saved library.

**Phone layout (iOS, Android).**
- Masthead: kicker `No. 05 — ON THIS DEVICE`, title "Downloads", deck "Saved for {profile} · reads with no connection". Content-mode chip in the running head.
- Contents tabs: `SAVED · STORAGE`.
- **SAVED tab**:
  - **Storage meter** (§7.18) with the folio line `4.1 GB OF 10 GB · 21 GB FREE ON THIS PHONE` and the cap tick; tapping it opens the STORAGE tab.
  - **Activity** (only while something runs, pinned at the top): kicker `DOWNLOADING` / `WAITING TO START` / `PAUSED`; the current chapter (series, `CH 12 · PAGE 7 OF 40`, novels `SAVING THE TEXT…`, audio `SAVING THE AUDIO…`) with a determinate rule; "2 more chapters downloading alongside"; "12 of 40 saved in this series"; pause reason as a `NOTE` line (user: "Paused by you. Nothing was lost; resuming carries on from the same page." + `Resume`; floor: "Paused: this phone is almost full. Downloads stop before the last 1.5 GB." ; cap: "Paused: your 10 GB limit is full." + `Storage settings`; background (app): "Paused while the app is in the background."); controls: `Pause all` / `Resume all`, `Cancel all` (dialog "Cancel all downloads? Everything queued, downloading or failed is dropped. Finished chapters stay."); `Show queue ⁽⁸⁾` expands queue rows (`clock` / `!`; "Waiting", "Downloading", "Failed — {error}"; `Retry`, `Remove from queue`); the app foreground note (iOS and Android, §8.19 wording).
  - **Dialogue scan** (only while an OCR run exists): kicker `READING THE DIALOGUE`, "Page 3 of 40" with a rule; paused ("Text extraction pauses in the background; keep the app open."), uploading, done ("214 words are now searchable." + `Search dialogue`), cancelled, failed; `Cancel` while busy.
  - **Narration** (when narration jobs exist): `NARRATING 3 CHAPTERS` with per-book rules → the book's audiobook sheet.
  - **Saved library**: kicker `ON THIS PHONE — BIGGEST FIRST`; one block per series: cover 48 × 72, title, `40 CHAPTERS · 3 WITH AUDIO · 1.2 GB` or `12 OF 40 SAVED · 800 MB`, pin (`push-pin`, "Pinned series are never auto-deleted"), overflow (`Save to Files…`, `Remove all downloads` → dialog "Remove every saved chapter of {series}? Your reading progress is kept."), and an expand chevron revealing chapter rows: `CH 12` (+ `· AUDIO` rows with a headphones glyph), status caption (`SAVED · 24.3 MB`, `QUEUED`, `DOWNLOADING`, `FAILED — …`), `Scan dialogue` (`bubble-search`; `TEXT` when done, spins while scanning; manga, saved, OCR available), `Save to Files` (`export`), `Remove` (swipe left or trash; toast with Undo for 8 s). Tap a saved chapter → its reader (Dip).
  - **Where it lives** note (`type.caption`): "Saved chapters live inside ManhwaManiacs and open from here. For a copy you can open elsewhere, use Save to Files."
- **STORAGE tab** (also `/settings/storage`): `STORAGE CAP` slug line `2 GB · 5 GB · 10 GB · 20 GB · UNLIMITED` (mobile K17); `CHAPTERS AT ONCE` `1 · 2 · 3` with the explainer (mobile K18); `DELETE AFTER READING` `OFF · 24 H · 48 H · 7 D` (mobile K19; "Finished chapters older than this are removed; pinned series and the chapter you're reading never are."); `Download on Wi-Fi only` switch (mobile K20: gates the auto-queue of the next chapter); `Save the next chapter while I read` switch (new, default on, per profile; the auto-queue of §8.14.11); `Download new chapters of followed series automatically` switch (new, default off, per profile; downloads run only in the foreground (G10), so this is not a background job: on app open and on every resume, right after the unread-notifications poll, the app queues the new chapters named by unread notifications of followed series whose per-series `notify` is on, skipping chapters already saved, respecting Wi-Fi only (mobile K20), the storage cap and the 1.5 GB floor, and never more than 20 chapters per pass; a toast says "Queued 6 new chapters." when it queues anything); `BY SERIES` rows (pin mark, title, `12 CH · 240 MB`); `Free up space` (secondary; toast "Removed 14 chapters." / "Nothing to free up right now."); image cache card (size + `Clear image cache`); metadata cache card (`Clear metadata cache`); platform note (iOS: "Browse, copy or delete saved chapters in the Files app: On My iPhone › ManhwaManiacs." with `Open Files`; Android: "Files live in the app's private storage.").
- **Save to Files sheet** (M5): kicker `SAVE TO FILES`, two options as rows: `Page images` ("A numbered folder per chapter.") and `CBZ file` ("One file per chapter, for comic reader apps."); then a non-dismissible progress dialog ("Saving to Files…" + leader) and a result dialog ("Saved 12 chapters · 480 pages" + the path in `type.folio` selectable: "Files › On My iPhone › ManhwaManiacs › Exports › {series}" on iOS, "Files › Downloads › ManhwaManiacs › Exports › {series}" on Android 10+ + skipped count + `Done`; on Android 7–9 the result offers `Share` (`share_plus`) instead of a path); **Android destinations**: on API 29 and up the export writes through MediaStore `Downloads` with `RELATIVE_PATH = "Download/ManhwaManiacs/Exports/{series}/"`, needing no permission, through the same `mm/media` method channel as share cards (§9.2.5) with a second method `saveDownload(relativePath, name, mime, path)`; on API 24–28 it keeps the app-documents export (`getApplicationDocumentsDirectory()`), which no file manager can see, hence `Share`; the STORAGE tab needs no folder picker; errors as toasts ("Nothing to save yet — these chapters are still downloading.", "Couldn't save to Files. Check your free space.").

**Mobile web layout (< 768 px).** The phone layout above (same masthead, `SAVED · STORAGE` tabs and order), filled with the web's data: the web meter copy below, the web chapter statuses, retention `DELETE FINISHED CHAPTERS AFTER` `2 DAYS · 7 DAYS · 30 DAYS · NEVER`, and `Protect storage`, which (with the rest of the desktop aside) stacks under the meter in the STORAGE tab. What the web cannot do is absent, not disabled: Save to Files, `Scan dialogue`, saved narration audio, the chapters-at-once and Wi-Fi-only controls.

**Web activity and removal (mobile web and desktop web).** On the web the Activity block lists the saves reported by the worker's `mm-offline/state` broadcast (series, `CH 12 · 7/40 PAGES`, a determinate rule), plus the in-page bulk run's tally (`12 of 40 saved in this series`). Each save has `Stop` (`mm-offline/cancel-save`), and there is `Stop all` (a `cancel-save` for each save, plus cancelling the bulk run). The web has no Pause, Resume or queue rows, and `p` is not bound there. Web chapter `Remove` defers the `mm-offline/remove-chapter` message until its 8000 ms Undo toast expires. Meanwhile the row reads `REMOVING…` in `ink.45` (a state, so never `ink.30`, §2.1.1). Undo drops the pending message, and `pagehide` flushes any pending removals.

**Desktop web layout.** The same order in 12 columns: meter and activity in columns 1–8, the retention and protection controls in an aside (columns 9–12); the saved library as series blocks in two columns at wide widths.
- Web meter: "2.3 GB in 84 chapters · 2.3 GB of 60 GB used by this site · 57 GB free" (`navigator.storage.estimate`), or "This browser doesn't report a storage quota."; explainer "Saving stops before the last 250 MB of the quota; finished chapters go oldest-first, never one you haven't read and never the one you have open."
- `Protect storage`: `STORAGE PROTECTED` (`set` badge) or `Ask to protect storage` (secondary; `navigator.storage.persist()`).
- `DELETE FINISHED CHAPTERS AFTER` `2 DAYS · 7 DAYS · 30 DAYS · NEVER` (web K50).
- Web chapter statuses as the inventory: "Saving 12/40", "Incomplete — 38/40 pages", "Paused — this browser is out of room", "Pages changed on the server — save again", with retention hints " · deletes in about 3 days" / " · open now, kept".
- Footer: `Remove all downloads` (inline confirm "Delete everything saved?") and `Reset offline storage` (quiet `proof`; dialog; unregisters the worker and clears caches) with its explainer.

**Signature moment.** The storage meter is set as a single typographic line with a live rule under it; when a chapter finishes, its row's mark fills with `set` and the meter's spot segment grows by exactly its size (240 ms `set`), so the edition visibly gets thicker.

**Transitions.** In: Cut (tab). Out: Dip into saved chapters.

**Gestures.** Swipe rows to remove; long-press a series block for Pin / Save to Files / Remove all; no pull to refresh (local data).

**Keys (web).** `j`/`k` series; `Enter` expand; `Delete` remove focused chapter (dialog for a series); `p` pause/resume all (app hardware keyboards only; not bound on the web, which has no pause).

**States.** Every list, count and badge here passes through the device-side 18+ filter (§7.24). No profile ("Choose a profile to see its downloads." + `Choose a profile`); unsupported (web without a service worker: "Downloads aren't available in this browser or on this connection."); checking ("Checking what's stored…" with a leader); empty (`NOTHING SAVED YET`: "Chapters you save open with no connection." + a rail of Continue reading series with `Download next 5` on each); offline (a banner: "You're offline. Only saved chapters open."); error ("Couldn't read downloads.").

---

### 8.24 Dialogue search (OCR): "What they said" · web R24 (OC1–OC8) · mobile S27

**Desktop layout.**
- Masthead: kicker `No. 09 — DIALOGUE`, a visually hidden h1 "Dialogue search" as the route focus target (as §8.20), the index field with the typed placeholder "Search what a character said", deck "Across chapters whose dialogue has been read, in series you follow."
- Results as **subtitled stills**: each hit is a block in two columns (desktop, 8 of 12 columns wide):
  - Left (4 columns, 16:9, square corners): a **crop of the page around the speech bubble** at `brightness(0.8)`, with the matched line laid over its lower third as a **subtitle**: Newsreader 18/24 `ink.100` centred on a `color.onart` band (`#000000` at 64 %), 8 × 12 px padding, max two lines, the matched terms under the `spot.wash` highlighter. The crop is centred on the match's box (`box` from the search result) and scaled so the box fills 60 % of the crop's width, clamped to the page; with no box it shows the top 16:9 of the page; with no known page it is absent and the block is text only. Crops load lazily as blocks scroll into view (web: IntersectionObserver with a 400 px root margin; Flutter: requested when `ListView.builder` builds the item): the chapter manifest (cached) gives the page URL, the image is requested from the existing proxy at 480 px width (both as P3 requests of the sources limiter, §15.6), and the crop is done in layout (`object-position` + `transform: scale()` on web, `FittedBox` + `Alignment` in Flutter). No image work runs on the server. Downloaded chapters crop from the local copy.
  - Right (4 columns): the transcript block: the full snippet in Newsreader 18/28 with the matched terms under the `spot.wash` highlighter and `ink.100`, then a credit line `TOWER OF GOD · CH 88 · PAGE 12 · 214 WORDS · VISION` (series title joined from the library; the engine name shown, `VISION` or `ML KIT`), and the series cover at 40 × 60.
- Block states: hover adds a 2 px `ink.100` left bar and zooms the still to 1.04 inside its crop (200 ms `dur.clip` `settle`); pressed fills `paper.3`.
- Click (either column) → the reader opens at that chapter by **Dip**, then (after the chapter's OCR text is fetched) scrolls to the first page containing the match and pulses a 2 px `spot` frame around the bubble twice (480 ms each), with the toast "Found on page 12." When the page cannot be matched: toast "Opened at the chapter start. The line is in this chapter."
- Overflow note: "Showing the first 20 of 134 matches. Narrow the search." + `Show more` (offset).
- Novels mode: a notice "Dialogue search is for manga. Switch to Manga, or search the novels' text." + `Search novels` (Discover).

**Phone layout.** One column; the field at 28 px; each block is the 16:9 subtitled still at full width, then the transcript and credit line under it; the cover at 32 × 48.

**Platform deltas.** Mobile adds the entry point for scanning: a caption line under the deck "Scan more chapters from Downloads" linking to Downloads; the OCR engine runs on-device (Apple Vision, ML Kit). Web shows only search.

**Signature moment.** "What they said": each still racks into focus (Rack focus, 520 ms `dur.rack`) with its subtitle already set, then the highlighter strokes sweep across the matched words in both the subtitle and the transcript (200 ms `dur.clip` each, left → right, 60 ms apart); opening one lands on the page and pulses the bubble frame twice.

**Keys (web).** `/` field; `j`/`k`; `Enter` open.

**States.** Idle ("Type a line you remember."), loading (3 greeked blocks: a flickering 16:9 plate plus greeked lines), crop loading (a `paper.1` plate with the subtitle already set over it), crop failed or page not found (the plate stays, subtitle intact, a 16 px `image-broken` glyph in `ink.45` (4.41:1 on `paper.1`) at its corner, labelled "Page didn't load"), no matches ("Nothing found for "{q}". Only chapters whose dialogue was scanned, in series you follow, can be searched."), offline, error, OCR unavailable on this device (mobile: the Index entry is hidden).

---

### 8.25 Picks (recommendations) · web R12 (RC1–RC11) · mobile S11

Specified in full in §9.1.3 (the AI feature owns this screen). Route `/library/recommendations`; Contents sidebar `12 Picks`; phone entry from Discover (`ASK THE EDITORS`), Tonight rails' `See all`, and Index.

### 8.26 The Numbers (statistics) and The Annual · web R13 (ST1–ST13) · mobile S12

Specified in full in §9.2. Route `/library/statistics` and `/library/statistics/annual/:year`; entries from the sidebar `10 The Numbers`, Index, Tonight's `This week in numbers` section.

### 8.27 Circle · new

Specified in full in §9.3. Route `/circle`; sidebar `11 Circle`; Index; Tonight's `From the Circle` and `Sent to you` sections.

---

### 8.28 Index (More) · web R25 (M1–M6) · mobile S22 · G9

The phone hub, set as a magazine index: entries with folios and dot leaders.

**Phone layout.**
- Masthead: kicker `THE INDEX`, title "Index".
- **Profile block**: 44 px avatar, name in `type.subhead` italic, `@username` + `ADMIN` credit, mood; actions `Switch profile` (secondary sm), `Profiles` (quiet, to Manage) and `Switch account…` (quiet, the §8.5 sign-out dialog).
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

**Transitions.** Cut in. Destinations in the Index branch (branch 4, §8.0.3: The Numbers, Circle, Profiles, Settings, Backup & restore, Members, System status, Licenses) are pushed with Page and get a back arrow. Destinations in another branch use `go` and never push a duplicate: Updates, Collections, History and Bookmarks (branch 1), Picks and Dialogue search (branch 2) and Storage (`/downloads?tab=storage`, branch 3) play the phone section change of §8.0.4 (Cut + Set + Folio flip) and move the notch. The Annual opens on the root navigator as a takeover (Dip in, Dip out); Switch profile pushes the picker as a takeover by Dip (§8.5, §8.0.5); What's new rises as a sheet (§8.29) and Switch account inserts its dialog (§8.5).

**States.** Loading (values show `–`); unread count failure (value hidden); offline (values from cache, `OFFLINE EDITION` badge).

### 8.29 What's new and app updates · mobile G8, G9 · web G40 · S28 #22–23

- **What's new** (shown once after an update, and from Index → What's new): a `[0.92]` sheet / desktop dialog set as **errata and additions**: kicker `WHAT'S NEW`, title "Release notes"; entries per version: version folio in Plex Mono 15 (`3.5.0 · BUILD 57 · 28 SEP 2026`), a `LATEST` badge on the first, highlights as a list with `—` dashes in Newsreader 16. Loading (leader), unavailable ("Release notes aren't available right now."). Data `GET /app/changelog`.
- **Android APK update**: Index banner (§8.28) and Settings → About card (up to date `UP TO DATE — 3.5.0` in `set`; available `3.5.0 → 3.5.1` + `Download update`; unreachable "Couldn't check for updates."). Re-checked on every resume.
- **iOS SideStore**: Settings → About card "Managed by SideStore" + explanation + the source URL in `type.folio` (selectable) + `Copy source URL` (toast "Source URL copied") + caption on the 7-day signature.
- **Web service-worker update**: a subtitle toast that does not time out: "A new edition is ready." + `Reload` (posts `skip-waiting`, reloads).

---

### 8.30 Settings · web R26 (SG1–SG40) · mobile S28–S34 · web K1–K51 · mobile K01–K40

#### 8.30.1 Structure

**Desktop.** Two panes: a left **table of contents** (3 columns) with numbered sections and a settings search at its top ("Search settings", matches labels and keywords, results jump to the row (it scrolls 400 ms `dur.glide` `settle`) and flash it with a `spot.wash` band for 1200 ms, `dur.hold.flash`); the right pane (9 columns, max 720 px of controls) shows one section at a time (route `/settings/:section`). Rows are §7.16 settings rows; each section starts with a section header (§7.27) and ends with a section rule. A footer line: "Settings save as you change them. Changing the edition restarts the app." (the second sentence only once `glass_available` is true, §8.0.7). **Keys (web):** `/` focuses the settings search, `j` / `k` move to the next / previous section in the table of contents, `Enter` opens it, `Esc` returns focus to the table of contents.

**Section slugs** (`/settings/:section`, both clients, in `design/contract.json`): `profile`, `appearance`, `reading-manga`, `reading-novels`, `listen`, `ambient`, `storage`, `content`, `circle`, `feedback`, `notifications`, `keyboard`, `server` (app), `admin`, `diagnostics` (app; web only with `?debug=1`, §8.0.7), `about`, and the pushed pages `security`, `members`, `backup`. Mobile's existing `/settings/storage`, `/settings/backup` and `/settings/diagnostics` keep their paths.

**Pushed pages on desktop.** `security`, `members` and `backup` render in the right pane under a `quiet` `← {Parent section}` link above their section header, and the parent stays lit in the table of contents.

**Folios.** Folios are assigned to the sections this client renders, in order, with no gaps (web: 01 Profile & account … 14 About, since Server and Diagnostics are app-only). The slugs, not the numbers, are the stable identifiers; the numbers in §8.30.2 are the app's.

**Phone.** `/settings` is the table of contents (a credits list with folios and current values after dot leaders); each section is a pushed page (Page transition). Search is a running-head action opening a full-screen search list.

**No-profile guard**: sections that store per-profile values show a `NOTE` banner "No reading profile is active, so there's nowhere to save this yet." + `Choose a profile`, and their controls are disabled.

**Server-backed sections** (Content 18+, Notifications, Circle & privacy, Password & security, Members, Backup & restore, the account block, and the Edition row) have three more states: *loading*: the section header renders and its rows are greeked at their exact heights (flicker), with controls absent until data lands; *error*: a `CORRECTION` line under the section header with the API message and a `quiet` `Retry` for that section only, other sections unaffected; *offline*: the rows show their last known values with controls disabled and the caption "Needs a connection." (tooltip on each control). On mobile, the one change that goes through the offline outbox (the profile's `skin` `PATCH`, `stack-decision.md` §2.5) stays enabled offline and shows the caption "Saves when you're back online." until the outbox flushes; while it is queued, boot resolution keeps the queued skin over the server's (§8.30.3). On the web the Edition row is disabled offline like the rest, because the switch awaits the `PATCH` before it restarts (§8.30.3). Every other server-backed control waits for the connection.

**Capabilities.** `GET /settings` returns `capabilities {online_sources, client_downloads, ocr, collections, bookmarks, continue_reading, reading_progress}`. A section, row or Index entry whose feature the server does not offer is not rendered: `client_downloads` false hides Downloads & storage and every download control; `ocr` false hides dialogue search entries and `Scan dialogue`; `collections` and `bookmarks` false hide those hub tabs and their Settings rows.

**Admin deep links.** A non-admin who opens `/settings/members`, `/settings/backup` or `/settings/notifications`' admin block by URL sees the §8.31 notice (`ADMINISTRATORS ONLY`, with the section's own name) and `Back to Settings`; the section never renders its controls.

#### 8.30.2 Sections and every control

| # | Section | Controls (inventory keys) |
|---|---|---|
| 01 | **Profile & account** | Profile block (avatar, name, mood; `Switch profile`, `Manage profiles`); shortcuts `Reading history →` and (admin) `System status →`; account (display name, `@username`, `ADMINISTRATOR` credit); `Password & security` (→ §8.30.4); `Members` (admin → §8.30.5); `Sign out` (dialog "Sign out on this device?") |
| 02 | **Appearance** | **Edition** (the skin picker, §8.30.3); Reduce motion in the app (`SYSTEM · ON`; `ON` forces the reduced variants regardless of the OS); Hyperlegible text (switch, default off, per profile; §3.4); Reading mode (Manga / Novels, when enabled) |
| 03 | **Reading: manga** | Defaults for new series: layout, direction (mobile K01 / web K37), fit (mobile K02 / web K36), tap zones (mobile K03 / web K34), strip taps, swipe sideways for chapters, cinema (web K30), gap between pages (web K29), keep screen awake (mobile K05), auto next chapter (mobile K06), lock controls (mobile K07), volume keys (mobile K08, Android), refresh rate (mobile K04, Android), ground (mobile K11), colour (mobile K12), brightness and warmth defaults (mobile K09 / web K31, mobile K10 / web K32); **Previously on** (one setting for manga and novels, also shown in 04): `ALWAYS · AFTER N DAYS AWAY · NEVER` with an N stepper 3–60 days (default `AFTER 14 DAYS AWAY`), caption "Plays a short recap before you continue a series you haven't opened for a while."; "Continue automatically after a recap" `ON · OFF` (per profile, default `ON`; with `OFF` the recap's 12 s countdown never runs, §9.1.5; one setting for manga and novels, also shown in 04); `Reset reader settings` (dialog with the arm delay) |
| 04 | **Reading: novels** | Default face (five, §3.4), size, line spacing, measure (web K41–K44 defaults for new books), layout (scroll / paged), page turn, stock (web K40, seven stocks), bold text, justify, "Auto next chapter", **Previously on** and "Continue automatically after a recap" (the same settings as 03, shown here too) |
| 05 | **Listen** | Voices (→ the 31-voice cast list, §8.16.5), default speed, sleep timer default, shake to extend, auto-play the next chapter (the 5 s countdown on/off), keep the player visible |
| 06 | **Ambient** | Soundscape default (`OFF`, `MATCH THE MOOD` or a named loop) and volume; "Pause the soundscape during narration" (switch, default off: the soundscape ducks to 30 % instead, §9.4.2); page-tinted chrome; auto-scroll default speed (manga, and novels relative to the measured pace); resume after I let go; pace by dialogue (default off); guided view auto-advance (`PACE BY WORDS │ FIXED`, fixed hold 2–10 s) |
| 07 | **Downloads & storage** | The STORAGE tab controls (§8.23) + Save to Files info + caches |
| 08 | **Content** | Show mature content (18+) switch → certificate (§7.24) (web K1 / mobile K30); sources shortcut (`Manage pinned sources →`) |
| 09 | **Circle & privacy** | §9.3.6 (sharing switches per profile) |
| 10 | **Feedback** | Haptic feedback (mobile K13; app, and web when `'vibrate' in navigator` and `matchMedia('(pointer: coarse)').matches`; default on; **per device**: on the web stored in `localStorage['mm.haptics']` (`on` by default, or `off`), and `haptics.ts` checks it before calling `navigator.vibrate`; the row is not rendered on iOS Safari or desktop) with `Feel it` (app only; quiet; fires `follow.add`, the `stamp` pattern; disabled with "Turn haptics on to feel them." when off; §5); UI sounds (default **off**) + volume (**per profile**, §6); `Play a sample` (quiet, plays `set`) |
| 11 | **Notifications** | Per-profile: "Notify me about new chapters" master (stored as `reading_profiles.notify_enabled`, new in §15.5, default on; when off the server creates no new-chapter notifications for this profile, so the Library badge, Updates' NEW tab and the stop-press banner stay empty, and per-series bells keep their values for when it is turned back on); admin (instance-wide, web K19–K22 / mobile K40): schedule strip (`LAST CHECK 21:04 · NEXT ≈ 21:34 · EVERY 30 MIN`, overdue in `NOTE` tone "Expected 12 min ago. See System status."), "Check automatically" switch, "Check on startup" switch, interval slider 5–120 step 5 (`30 MIN` folio; "The server enforces a 5-minute floor."), "Notify about new chapters" master; draft-then-`Save` with "Saved." / error; the recent-checks list; source cache TTL (≥ 5 min, admin) |
| 12 | **Keyboard** (web; app on tablets, `MediaQuery.sizeOf(context).shortestSide ≥ 600`, iPad and Android) | The live shortcut registry as credits rows with keycaps, grouped as General, Navigation, then one group per screen that binds keys, named by its masthead title in sidebar order (§7.15 Items; Sources and Catalogue sit under Discover, where they light in the §7.15 route table: Tonight, Library, Updates, Discover, Sources, Catalogue, Downloads, Collections, History, Bookmarks, Dialogue, The Numbers, Circle, Picks, Profiles, Settings, System status), then Series page, Reader, Novel reader, Listen, Recap, The Annual. Each screen registers its keys under its own group; the General group always includes `Alt+T` "Go to notifications" (§7.11); "Single-key shortcuts" switch (default on) |
| 13 | **Server** (app) | "API base URL" field (validated as §8.1, HTTPS in release), `Save`, `Reset to default`. Saving a different server first asks "Switch servers? You'll be signed out. Saved chapters stay on this phone but open only when you're signed in to the server they came from." (`Switch servers`, arm delay); confirming signs out, drops every profile-scoped cache and the image cache, keeps downloads under the old server's scope (they reappear if that server is set again), and lands on Login with the toast "Signed out: new server." |
| 14 | **Admin** | `Backup & restore` (→ §8.30.6), `Members` (→ §8.30.5), `System status` (→ §8.31) |
| 15 | **Diagnostics** (app) | → §8.30.7 |
| 16 | **About** | Version and build, What's new, update card (Android) or SideStore card (iOS), Licenses (Flutter `LicensePage` restyled: Bodoni masthead, Newsreader text, package names in Plex Mono) |

Not part of this skin, by decision: palette and preset pickers (web K24, K25, mobile K22, K23, S31; the app is dark only with no accent picker, and the edition covers the rest) and a language picker (mobile K14; it arrives with localisation).

#### 8.30.3 The edition picker and the restart ("Stop the press")

**Picker (Appearance → Edition).** Kicker `EDITION`, subhead "Two versions of the same app." Two cards side by side (stacked on phones), each 3:4 (while `glass_available` is false the Glass card is the disabled `NEXT ISSUE` plate of §8.0.7 and nothing below about switching applies):
- A **live preview** of that skin's home at 9:16, framed by a 1 px `rule.2` border, `aria-hidden` with the card's text as its accessible name:
  - *Web*: an `<iframe src="/skin-preview/{skin}">` rendered at 390 × 844 CSS px and scaled into the card with `transform: scale(cardWidth / 390)`, with `inert`, `tabindex="-1"`, `pointer-events: none`, `loading="lazy"` and `sandbox="allow-scripts allow-same-origin"`. The route `frontend/src/app/(preview)/skin-preview/[skin]/page.tsx` is a thin route file (allowed to import both skins, like every route file) that renders `skins[skin].screens.tonight` with the static fixture `design/previews/demo-feed.json` (six public-domain demo covers, no 18+ content, no profile data; the covers are `design/previews/covers/01.webp`–`06.webp`, 720 × 1080, cut from Wikimedia Commons scans marked PD-old of Katsushika Hokusai's *Hokusai Manga* (1814–1878 volumes), Winsor McCay's *Little Nemo in Slumberland* (1905–1911) and Rakuten Kitazawa's *Tokyo Puck* covers (1905–1912), each file's Commons page URL and licence tag recorded in `design/previews/covers/SOURCES.md` and listed in About → Licenses) and scrolls itself slowly (a 12 s loop, `dur.loop.preview`, down 600 px and back) so the preview moves. Because the other skin runs in its own document with its own CSS and chunks, the skin import boundary (`stack-decision.md` §2.2) is untouched; no Glass component is ever rendered inside a Cinematic page. How the route is built:
    - **Separate root layouts.** Today's root moves into a route group, `app/(app)/layout.tsx` (URLs unchanged), and there is no top-level `app/layout.tsx` any more, so every page needs a root layout of its own group (§15.10 S17):
      - *Pages move.* Every existing route folder (`admin/`, `downloads/`, `library/`, `login/`, `more/`, `novels/`, `ocr/`, `profiles/`, `read-all/`, `reader/`, `register/`, `search/`, `settings/`, `sources/`, `updates/`, and every new one this contract adds) moves under `app/(app)/` with `error.tsx` and `not-found.tsx`; URLs are unchanged. Home is `app/(app)/page.tsx` (§8.0.3), because Next 16 requires `/` inside a route group when there is no top-level layout.
      - *Root files stay.* `global-error.tsx` (it renders its own `<html>`), `manifest.ts`, `favicon.ico`, `globals.css`, `presets.css` and the generated CSS stay at `app/`; both root layouts import `app/globals.css` (`../globals.css` from `app/(app)/layout.tsx`, `../../../globals.css` from the preview layout). `providers.tsx` is only imported, so it stays where it is.
      - *404.* A `not-found.tsx` no longer catches unmatched URLs once there are two root layouts, and Next's answer for that case, `experimental.globalNotFound` with `app/global-not-found.tsx`, bypasses every layout, while §8.32 puts the 404 inside the frame. So unmatched URLs reach it through a catch-all, `app/(app)/[...missing]/page.tsx`, whose only line calls `notFound()` from `next/navigation`; that renders `app/(app)/not-found.tsx` inside the `(app)` layout and Shell. Static and more specific routes (`skin-preview/[skin]`, `manifest.ts`, `/public` files) still win over it, and the `/api/:path*` rewrite is the array form (`afterFiles`), which Next applies before dynamic routes, so the catch-all never swallows the backend proxy.
      - *Preview layout.* `app/(preview)/skin-preview/[skin]/layout.tsx` is a second root layout that renders `<html data-skin={skin}>` with that skin's `fonts.ts` classes and no Shell (`const { skin } = await params`, Next 16), so the preview never inherits the viewer's `mm-skin` stamp or Shell. It imports the same global stylesheet as `(app)` (`import "../../../globals.css"`: Tailwind, `theme.generated.css`, and through it `tokens.generated.css` and `motion.css`, §15.2), because a stylesheet imported by one root layout never reaches routes under another. It also mounts `duotone.tsx` (§15.2), because Tonight's cover-story spread, Sources tiles and Letter cards paint through `filter: url(#duo-<id>)` and would show full-colour art without the filter defs. It mounts no `Providers` (their auth and profile handlers do not belong in a fixture page). It is a full page load, which the iframe is anyway; the route file therefore lives at `frontend/src/app/(preview)/skin-preview/[skin]/page.tsx`.
    - **Fixture.** `page.tsx` seeds React Query (`@tanstack/react-query` 5, already installed) from the fixture with `<HydrationBoundary state={dehydratedFixture}>`, using the same query keys `useHomeFeed()` uses, inside `preview-query.tsx` in the same folder (`"use client"`, a `QueryClientProvider` around a fresh `QueryClient` with `staleTime: Infinity` and `retry: false`; the fixture holds every query Tonight reads, so nothing is refetched and the preview never shows the viewer's own data), so the skin's real Tonight renders unchanged.
    - **Build context.** `design/build.mjs` copies `design/previews/demo-feed.json` to `frontend/src/skins/preview-feed.generated.json` and `design/previews/covers/*.webp` to `frontend/public/skin-preview/covers/`. Both are committed and checked by `--check`, because the Docker build context is `./frontend`.
  - *App*: a bundled PNG loop per skin: 36 frames at 6 fps (6 s; the frames fix this length, so the app does not read the web-only `dur.loop.preview`, and the 6 fps rate is one of §4.2's literal exceptions), 360 × 640 px each, about 1.1 MB per skin, at `mobile/assets/skin_previews/{cinematic,glass}/000.png…035.png`, captured by the screenshot harness (`test/screenshots/`) scrolling each skin's Tonight with the same fixture. A `Ticker` swaps precached `Image.asset` frames with `gaplessPlayback: true`; no video package is added. The frames are regenerated whenever either skin's Tonight changes (a step of the release checklist).
  - Reduced motion: the web iframe does not scroll and the app shows frame 000 only.
- Under it: the edition name in `type.subhead` (Cinematic in Bodoni Moda; Glass's name set in Glass's own display face so the card previews its type), a one-line description ("Cinematic: black stock, film titles, a magazine's rhythm." / "Glass: layered glass, springs and depth."), and either the badge `THIS EDITION` or the secondary `Switch to Glass`.
- Caption under both: "Switching restarts the app. You'll come back to this page. Your edition follows this profile to every device."

**Confirm** (dialog on desktop, sheet on phones): title "Restart in Glass?"; body "The app closes and reopens in the Glass edition, on this page."; when the download queue is not empty, an extra line "Downloads resume after the restart."; on Android an extra line "The app icon changes after you next close the app from Recents. Shortcuts on your home screen may need adding again." (the activity-alias swap, §12.3); actions `Restart in Glass` (primary) and `Stay in Cinematic` (quiet).

**Outgoing sequence** (500 ms, `dur.stoppress`, the stack's outgoing budget in `stack-decision.md` §2.5 step 4, leaving 1,000 ms of the 1.5 s confirm-to-splash budget for the restart itself):

| t (ms) | Motion |
|---|---|
| 0 | The profile `PATCH /profiles/{id} {skin}` is sent (an ordinary `fetch` on the web; the outbox on mobile) and the start timestamp (`mm.skin.t0`, for the `SKIN RESTART` measurement below) is written. The cookie / SharedPreferences mirror and the return route are **not** written yet |
| 0–160 | The whole screen racks out of focus: `blur.defocus` 0 → 6 px and brightness 1 → 0.3, `turn` |
| 80–456 | Column blades close top-down (§8.14.2 close: 200 ms per blade, 16 ms stagger, 12 blades on desktop; tablets: blades close 80–392; phones 248 ms from 80) |
| 456 | On black, the masthead wordmark and its Oxford rule cut in at the centre (no reveal: the incoming skin's splash is the reveal); haptic `skin.switch`; sound `impress` if on |
| 500, web | Await the `PATCH` for at most 1,000 ms more (an `AbortController` timeout) while the black frame with the masthead holds. On a 2xx: write the `mm-skin` cookie and `sessionStorage['mm.skin.return']`, post `{ type: "skin-changed", skin }` to the service worker, then `location.replace(returnPath)`. On an error or a timeout: see below |
| 500, app | Write `mm.skin.active` and `mm.skin.return`, then `AppRestart.of(context).restart()`; the `PATCH` stays in the outbox |

**The switch waits for the server** (§15.10 S12). On the web, a `PATCH` that errors or times out is aborted; the blades reverse (200 ms `dur.clip` `ease.set`), the screen racks back into focus, and the error toast "Couldn't switch editions. Try again." shows. The mirror is left unchanged, `mm.skin.t0` is removed from `sessionStorage` (so the next splash cannot log a false entry), and no `SKIN RESTART` entry is logged. The web Edition row stays disabled offline, like the other server-backed rows (§8.30.1). On mobile, boot resolution (`stack-decision.md` §2.4 step 2) lets a queued outbox `PATCH /profiles/{id}` that carries `skin` win over the server's `profile.skin`: while such an entry is queued, the mismatch restart is skipped, and when the connection returns the outbox flushes before the next comparison. So neither client can restart back into the old edition because the server had not yet seen the new one.

**Budget and misses.** The motion-timings overlay (§15.9) logs a `SKIN RESTART` entry measured from the confirm tap (`mm.skin.t0`) to the first frame of the incoming skin's splash, which reads the timestamp and logs it; budget 1,500 ms. A miss changes nothing for the reader (the black with the masthead simply holds until the new splash paints), but the entry turns `proof` in the overlay and the web also writes `console.warn("SKIN RESTART 1712 ms > 1500 ms")`, so a slow restart is caught on the device pass (§15.8).

**The restart re-reads the boot state** (§15.10 S15). A `UniqueKey` swap alone rebuilds the same child with the old overrides and never re-runs `main`, so:
- `mobile/lib/app/app_restart.dart`: `AppRestart({required Widget Function() builder})`; `AppRestart.of(context).restart()` swaps the `UniqueKey` **and** calls `builder()` again.
- `main.dart` keeps its existing overrides:

  ```dart
  runApp(AppRestart(builder: () {
    final boot = SkinBoot.read(prefs);
    return ProviderScope(
      overrides: [
        apiBaseUrlProvider.overrideWith((ref) => apiUrl),
        sharedPrefsProvider.overrideWithValue(prefs),
        audioHandlerProvider.overrideWithValue(handler),
        skinIdProvider.overrideWithValue(boot.skin),
        returnRouteProvider.overrideWithValue(boot.returnRoute),
      ],
      child: const SkinApp(),
    );
  }));
  ```

- `SkinBoot.read(prefs)` is synchronous, on the already-loaded `SharedPreferences`: the skin is `mm.skin.debug` (the pre-flip override, S5), else `mm.skin.active`, else the default; it reads `mm.skin.return` and then removes it.
- Each skin's `buildRouter` passes `initialLocation: ref.read(returnRouteProvider) ?? Routes.tonight`.

The Glass skin's splash follows (its own responsibility). Coming the other way, when Glass restarts into Cinematic, Programme's cold-start reveal plays and then a 10 s (`dur.hold.toast.undo`) subtitle toast: "Now in the Cinematic edition." + `Undo` (restarts back with the same outgoing sequence, no confirm). Reduced motion: 200 ms (`dur.clip`) fade to black with the masthead cutting in at 160 ms, restart at 200 ms (on the web, after the same `PATCH` wait).

#### 8.30.4 Password & security (web SG29–SG39, mobile S29)

- **Change password**: fields Current, New ("At least 8 characters"), Confirm; each with Show/Hide; validation lines (empty, too short, too long, mismatch, same as current); `Change password` primary; caption "Changing it signs out every other device. This one stays signed in."; success toast "Password changed. Every other device has been signed out." Server answers: `invalid_credentials` (401) → a field error under Current, "That isn't your current password." (`proof`), with focus back in the field (it never signs the user out, §8.3); `weak_password` (422) → the server's `message` under New ("Password must be at least 8 characters." or "Password is too long."); `rate_limited` (5/min + 20/h) → a `SLOW DOWN` line with the `Retry-After` countdown, `Change password` disabled until it reaches 0.
- **Where you're signed in**: rows per session: device label (parsed user agent: "ManhwaManiacs app on iPhone", "Firefox on Linux", "Unknown device"), `THIS DEVICE` badge (row with `spot` left bar), `LAST USED 3 H AGO · 10.0.0.2`, `SIGNED IN 12 SEP · EXPIRES 19 SEP`; actions: current row `Sign out` (secondary), others `Revoke` (quiet `proof`, dialog "Sign out {device}? It will have to sign in again."). `Refresh` (quiet, spins). States: loading, error, "No active sessions."
- **Sign out everywhere**: a destructive area (`proof.wash` background, `rule.proof` left edge) with the explainer "Revokes every session, this device included. Saved chapters stay on this device." and `Sign out everywhere` → dialog with the acknowledgement checkbox "I understand this signs me out here too".

#### 8.30.5 Members (admin; web MB1–MB7, mobile S30)

- Desktop: a table (min 640 px, horizontal scroll inside its own container) with columns `MEMBER` (username + `ADMIN` / `YOU`), `STATUS` (`ACTIVE` in `set` / `DEACTIVATED` in `proof`), `JOINED`, `LAST SEEN`, `SESSIONS`, actions `Deactivate` / `Reactivate` (secondary sm) and `Delete` (quiet `proof`). Own row tinted `paper.4`, actions disabled with the tooltip "You can't deactivate or delete your own account."
- Phone: one block per member with the same facts as credits and the actions below.
- Explainer: "Registration is open. Deactivating signs a member out everywhere and blocks sign-in; deleting removes everything they own."
- Delete dialog: "Delete @{user}? Their profiles, library, progress, bookmarks and everything else they own are removed. This can't be undone." + a field "Type {username} to confirm".
- Footer: "{n} other accounts." + `Refresh`. States: loading, error, empty ("Only your account so far.").

#### 8.30.6 Backup & restore (admin; web BK1–BK5, mobile S33)

- **Staged restore banner** (when `restore_pending`): `NOTE` banner "A restore is staged. It applies the next time the server starts; the current database is kept." + `Cancel staged restore`.
- **Nightly backup** card: `LAST NIGHTLY · OK · 28 SEP 03:00 · 412 MB` (or `UNKNOWN`, never shown as healthy); when `nightly.ok == false`, `LAST NIGHTLY · FAILED AT {PHASE} · 28 SEP 03:00` in `proof`.
- **Export**: explainer (the whole database, every account; keep it private), switch "Include caches (larger, warmer restore)", `Export backup` (primary; web downloads the file and shows "Saved {filename}"; mobile downloads with its own `dio` client, which carries the Bearer token (the external browser has none, and `/backup/export` needs an admin session), through `dio.download` streaming to a temp file `manhwamaniacs-backup-{yyyyMMdd-HHmm}.db` with a determinate rule showing bytes, then opens the share sheet (`share_plus` 12.0.2, §15.11) so the file can be saved, Save to Files on iOS; error toast "Couldn't download the backup.") and errors.
- **Restore**: a destructive area: explainer (replaces everything at the next restart), `Choose backup file` (secondary; `.db` only; "{name} · 412 MB" or "No file chosen. Nothing is uploaded until you confirm."), validation ("That isn't a .db file.", "That file is empty."), `Restore from this file…` (destructive) → dialog with four bullets (replaces every account; sign-ins come from the backup; applies on restart; nothing of the current state is kept) and "Type RESTORE to confirm"; then "Restore staged. Restart the server to finish." dialog.

#### 8.30.7 Diagnostics (app; mobile S34)

Sections with kickers `RENDERING`, `DISPLAY`, `DEVICE`, `IMAGE CACHE`: three big numerals (Bodoni) `FPS 119`, `JANK 1.2 %` (`set` < 5, `spot` < 15, `proof` above), `WORST 14 MS`; rows for average frame time, build and raster times, samples ("Collecting frames… scroll a screen to sample."); display (Android: current refresh rate, capability, resolution; switch "Use the highest refresh rate everywhere" (mobile K21); iOS: "Display modes can only be switched on Android."); device (OS, cores, screen, app version, build mode); image cache (live, cached n / max, memory). Plus two developer switches: "Show the layout grid" (§2.2.2) and **"Show motion timings"** (§15.9): an overlay that logs every named move of §4.5 with its start and end frame, planned and actual duration and dropped frames, so a move that misses its budget is visible on the device. Both switches are per device and reset on restart.

---

### 8.31 System status (admin) · web R27 (AS1–AS10)

- Masthead: kicker `ADMINISTRATION`, title "System status", deck "Backend health, the update checker, per-source failures and update runs." + `Refresh all` (quiet, spins); a live folio `LIVE · 15 S`.
- **Summary**: a banner strip tinted by the worst state (a left rule in `set` / `spot` / `proof` / `ink.45`), the headline typed ("Everything is running." / "2 things need attention."), and a list of problems.
- **Backend**: credits `STATE HEALTHY`, `NAME`, `VERSION 3.5.0` (Plex), `PROBE GET /health`.
- **Update checker**: `LAST RUN 21:04 · 12 MIN AGO`, `NEXT ≈ 21:34 · IN 18 MIN`, `INTERVAL 30 MIN`, `FAILED RUNS (RECENT) 0` (proof when > 0), server error block in Plex Mono on `paper.1`, `Check now` (secondary).
- **Recent checks**: up to 8 rows: status badge (`FINISHED` set / `RUNNING` spot / `FAILED` proof), trigger, `212 SERIES · 3 NEW`, time, error text.
- **Source health**: a table sorted worst-first: mark, name, id (Plex), `DEMOTED` badge, `LAST PROBE 4 MIN AGO`, message, last error (collapsible Plex block).
- Footer note in `type.caption`.
- Phone: sections stacked; tables become blocks.
- Non-admin: notice `ADMINISTRATORS ONLY`: "System status is instance-wide. Ask the owner to check it." + `Back to Tonight`.
- States: resolving (masthead only), each card's loading and error.
- **Keys (web).** `r` refreshes every card (`Refresh all`); `c` runs `Check now`; `j` / `k` move through the source-health rows; `Enter` expands the focused row's last error.

---

### 8.32 Status screens · web S1–S5, E1–E4

| Screen | Presentation |
|---|---|
| **404** (inside the frame; `app/(app)/not-found.tsx`, which unmatched URLs reach through the `app/(app)/[...missing]` catch-all, §8.30.3) | A folio numeral `p. 404` in Bodoni Moda Roman at `type.numeral` × 1.5 in `ink.30`, decorative (`aria-hidden`, `ExcludeSemantics`) because the headline carries the message; kicker `NOT IN THIS ISSUE`; headline typed "This page doesn't exist."; deck "It may have been renamed, or the series it pointed to left your library. Press ⌘K to search everything." (`Ctrl K` off Mac, §7.26; in the phone frame the sentence becomes "Search everything from Discover.", with `Discover` as a `link`); `Back to Tonight` (primary), `Open library` (quiet) |
| **Route error** | `CORRECTION` notice: "Something broke on this page." / "Nothing was lost; trying again usually fixes it." + `Try again` + `Back to Tonight` + a `REF 7F3A…` keycap (the digest). Backend unreachable variant: kicker `OFFLINE EDITION`, "The server didn't answer." / "It may still be starting, or the connection dropped. Your library is untouched." |
| **Root error** (own document, no fonts loaded) | Pure HTML on `#000`: the wordmark as inline SVG, "ManhwaManiacs failed to start." in a system serif, the explainer, `Try again` and `Reload the app` buttons styled inline (square, bone fill) |
| **Offline fallback page** (`/offline-fallback.html`, served by the service worker) | Standalone HTML with inline styles in this skin (and a Glass version; the worker serves `offline-fallback-{skin}.html` by the skin the page last posted to it, or `offline-fallback-cinematic.html` when nothing is stored, because a service worker cannot read the `mm-skin` cookie): the `mm-mark` SVG 72 px, a live status badge `NO CONNECTION` / `BACK ONLINE`, headline "This page needs the server.", deck "Chapters you saved still open on this device.", note "Served from your device by the app.", `Try again` and `Downloads` |
| **Reader landing** (`/reader`) | Notice: kicker `READER`, "Open a series to start reading." + `Go to library` |
| **Not available** | §8.0.10: kicker `NOT IN THIS ISSUE`, "This series isn't available here any more." |

**In the app (Flutter).** The same screens exist, rendered by one `CineErrorScreen` in `mobile/lib/skins/cinematic/screens/system/`:
- *Unknown route*: go_router's `errorBuilder` renders the 404 above inside the phone frame (running head with back, thumb index hidden), with `Back to Tonight`.
- *A widget that throws in release*: `ErrorWidget.builder` returns a `paper.1` box at the failed widget's size (min 48 px tall) with a 2 px `proof` left rule and the line `CORRECTION · This part of the page broke.` in `type.caption` (`ink.60`), so one broken section never blanks the screen; debug builds keep Flutter's red screen. The error is sent to the existing diagnostics log.
- *Uncaught async error or a crash in the root*: `runZonedGuarded` + `PlatformDispatcher.instance.onError` show the route-error notice with `Try again` (rebuilds the route) and `Restart the app` (`AppRestart.of(context).restart()`).
- *Backend unreachable mid-session*: a network failure on any request while signed in puts the app in the **offline edition**: the running head shows `OFFLINE EDITION` (§7.13), screens render cached data or their own offline notice, and the app retries `GET /health` every 15 s (backing off to 60 s); when it answers, the badge reads `BACK ONLINE`, the outboxes flush and the current screen refetches. No full-screen error is shown for this case.

---

### 8.33 Global overlays

#### 8.33.1 Command palette: "Index" (web `mod+k`)

- Scrim `scrim.modal`; panel `paper.2`, 1 px `rule.2`, max width 720, max height 70 vh, placed 12 vh from the top; Insert motion.
- The index field (§7.4, `type.field`) with the placeholder "Search or jump…" and an `Esc` keycap.
- Results grouped by kicker, in rank order: `LIBRARY` (series from `/library/search`, 220 ms debounce, 40 × 60 covers), `SOURCES` (logos), `GO TO` (every route with its folio: "02 Library", "10 The Numbers"), `ACTIONS` (Continue {series}, Check for updates, Open settings, Toggle reading mode, Sign out), `EDITION` ("Switch to the Glass edition…" → the restart confirm; absent while `glass_available` is false, §8.0.7), `SETTINGS` (every setting row by name). Max 40 results, fuzzy matched with matched characters in `spot`.
- Row: leading visual, title, subtitle (`type.caption`), the `↵` glyph on the active row; hover moves the highlight (`paper.4` + ink bar).
- Footer keycaps: `↑ ↓` navigate · `↵` open · result count.
- Live region: "Searching…" / "12 results". Empty: "Nothing matches "{q}"."
- Keys: `Esc`, `↑/↓` (wraps), `Home`/`End`, `Enter`, `mod+k` closes.

#### 8.33.2 Keyboard sheet (`?`)

A dialog (max 720) titled "Keyboard" with the intro "Only what works on this screen is listed. Shortcuts pause while you type in a field." and groups (the registry groups of §8.30.2 row 12) as two-column credits lists (description → dot leaders → keycaps). Empty: "No shortcuts on this screen." The General group always lists `Alt+T` "Go to notifications" (§7.11). Also reachable from the reader's setup sheet and Settings → Keyboard.

#### 8.33.3 Stop-press banner (new chapters)

When unread notifications arrive (60 s poll) and the user is not on Updates or in the manga reader: a subtitle-style strip bottom-left of the content column, 24 px from the bottom (desktop, max 560, the toast anchor of §7.11) or above the thumb index (phone), sharing the toast anchor and sitting under the toast stack, outside sonner, so toasts rise above it (§7.11 offsets): kicker `STOP PRESS`, "4 new chapters across 3 series." + `Read updates` (→ Updates) + `x` (dismiss; hidden until a newer notification, `sessionStorage` on web). In the novel reader it appears in the stock colours at the top edge instead of the bottom, never over the text column's current line.

#### 8.33.4 First-run note

When the profile follows nothing, a banner strip under the running head on every app-frame screen except Tonight, Library (its own `EMPTY SHELF` notice already says it), `/search`, `/sources`, `/sources/:id`, feature and book pages, the readers and takeovers: kicker `NOTHING FOLLOWED YET`, "Follow a series from Discover to start your shelf." + `Discover`. Not dismissible (it disappears with the first follow).

#### 8.33.5 Toasts, rating card, offline badge

Toasts §7.11; rating card §7.24; offline badge §7.13.

---

### 8.34 Public install page (`GET /`, backend-served)

A static page in this skin's language (it is the brand's public face; content from `_SHOWCASE`): the masthead wordmark with its Oxford rule; cover lines ("Every source. One shelf." / "Novels, read aloud." / "Your year in chapters." / "Read together."); install instructions as numbered steps with folios (`01 Android: download the APK`, `02 iPhone: add the SideStore source`); the "Front pages" screenshot set (§12.6); the changelog as release notes (§8.29). Inline CSS, fonts self-hosted through `GET /app/fonts/{file}.woff2` (an allowlist of the Bodoni Moda and Archivo subsets, §15.5), no JavaScript.
---

## 9. The four new features

All four are designed server-first (stack-decision §2.6): each client only renders. Every payload below is filtered by the active profile and applies the 18+ gate when serving, never when storing.

### 9.1 AI home, recommendations and "Previously on"

The AI is the magazine's **editorial desk**: it picks tonight's cover story, writes the decks and the "why" lines, and recaps what happened before you continue. It is an external AI API only (the existing DeepSeek-backed suggest path), with a daily budget and a visible "desk closed" state.

#### 9.1.1 Surfaces and entry points

| Surface | Entry points |
|---|---|
| Tonight's cover story and deck (§8.8) | Home tab, sidebar `01`, after the iris |
| Picked for you, Because you read X (Tonight rails) | Tonight; each rail's `See all` → Picks |
| Picks screen (§9.1.3) | Sidebar `12 Picks`, Index, Discover `ASK THE EDITORS`, Discover `ASK` scope, Tonight `See all` |
| More like this (§9.1.4) | Feature page tab `03`, chapter-end credits when caught up, Quick look `More like this` |
| Previously on (§9.1.5) | Tonight `Previously on…`, feature/book page button, Quick look on cuttings, the reader's first-page chip after an absence, the **Previously on** setting (`ALWAYS · AFTER N DAYS AWAY · NEVER`, default after 14 days, §9.1.5). Every entry renders only when the recap availability says `available` (§9.1.5) |
| Not for me | Every AI card: hover `x`, long-press menu, keyboard `Delete` |

#### 9.1.2 Tonight's cover story: selection and headline

The home feed (`GET /home`, §9.1.7) returns sections in order; section 0 is the cover story. Selection, in priority order (the backend composes, the client falls back to the same rules locally when the feed is unavailable):

1. A followed series in progress with **new chapters since the last read** (most recent `last_read_at` first).
2. A chapter **in progress** (unfinished, read within 21 days).
3. A followed series **paused 7–60 days** whose `recap.available` is true (§9.1.5; "pick it up again").
4. The top **AI pick** for this profile (world recs `for_you[0]` with `available` sources).
5. A popular series on a pinned source (new profiles; with 0 pins, the 3 healthiest non-18+ sources of §8.8's new-profile state).

Headline composition (≤ 60 graphemes, sentence case, one full stop; the time word follows the local hour: "This morning" 05–11, "This afternoon" 12–17, "Tonight" otherwise):

| Case | Headline | Deck |
|---|---|---|
| 1 | "Tonight: chapter 143 of Omniscient Reader." (if > 60, "Tonight: chapter 143." and the title moves to the kicker) | AI one-liner: "Dokja finally meets the author. You stopped two chapters before it." |
| 2 | "Tonight: finish chapter 142. Twelve pages left." | "You were on page 28 of 40 two days ago." |
| 3 | "Tonight: back to Tower of God." | "You paused 23 days ago at chapter 87. Previously on is ready." |
| 4 | "Tonight: start Lookism." | the `why` line |
| 4b (just onboarded: follows, nothing read) | "Tonight: start Omniscient Reader." (the first pick) | "Chapter 1 is waiting. The rest of your picks are below." |
| 5 | "Your first issue starts here." | "Follow three series and this page fills itself in." |
| caught up | "Tonight: you're caught up." | "Nothing new on your shelf. Here's something else." |
| streak at risk (overrides the headline and deck of cases 1–4b, keeps their cover series) | "Twelve days and counting. One chapter keeps it alive." (after 20:00 local, streak ≥ 2 days, nothing read today; the count is spelled out because it opens the sentence); above 60 graphemes (counts ≥ 101), "Your {n}-day streak ends at midnight." with a numeral | "Open any chapter before midnight to keep your streak." |

Numbers under ten are spelled out in headlines; chapter numbers are always numerals. The at-risk headline is set in the same `type.cover` role and typed like every main headline; its flame (16 px, at-risk tier) is in `spot` before the kicker, and nothing else about it is coloured: sentence case, no red, no extra glow. It is re-evaluated on every visit to Tonight, so it appears after 20:00 even when the page already typed its normal headline earlier that day (it types once more): the client recomputes `at_risk` from the `/home` streak's `current_days` and `last_active_date` and the device clock (after 20:00 local, `current_days ≥ 2`, `last_active_date` before today), and the local value overrides the cached flag and swaps the headline and deck to the at-risk lines.

#### 9.1.3 Picks screen (`/library/recommendations`)

**Desktop layout.**
- Masthead: kicker `No. 12 — PICKS`, title "Picks", deck by state: "Describe it in your own words. Suggestions are weighed against what you already read." / "The picks desk is closed tonight. Asks reset at midnight UTC. The picks below still work." (the §9.1.8 budget line plus this surface's non-AI path) / "Titles from everywhere, picked from what you read."
- **Ask block** (columns 1–8): the index field in prompt mode, placeholder typed and cycling every 6 s through examples ("A murim regressor who comes back stronger", "Magic academy, but the lead is already strong", "Something slow and political, not a power fantasy"); textarea behaviour (Enter submits, Shift+Enter newline, 3–600 characters with a `12 / 600` folio); the three examples also as a slug line of quiet buttons that fill and submit; `Ask the editors` (primary, with `sparkle`); the quota folio `8 ASKS LEFT TODAY` (shown at ≤ 10). Source toggle: `FROM YOUR SOURCES │ FROM EVERYWHERE` (maps to `/library/suggest` vs `/library/world/suggest`).
- **Results** (after an ask): kicker `THE EDITORS SUGGEST`, then result cards as **mini reviews** in two columns: World cards (§7.6) with the `why` as the pull quote (`FROM YOUR SOURCES` results use the World card's *Shelf* variant, because `/library/suggest` items carry no format, status or rating). The answer streams: a line "Reading your shelf…" types itself, a leader dial appears after 1 s, and each card fades in 160 ms as it arrives (30 ms apart). After 40 s with nothing back, the timeout copy replaces the thinking line: "The editors took too long. Try a shorter description." + `Try again` (the ask field keeps its text).
- **For you** (a section with folio `01`): a grid of World cards (3 per row desktop).
- **Because you read {title}** (`02`, `03`, … one per seed): rails of World cards.
- Aside (columns 9–12, ≥ 1440): "Your genres" as a weighted slug line (size from `/library/recommendations`), each a link into Discover genres. At 1024–1439 the ask block spans columns 1–12, and the aside renders under it as a full-width `Your genres` slug line (the tablet rule, §8.0.9).

**Phone layout.** Ask block full width with the field at 28 px; results one column; For you as a two-column grid; Because-you-read as rails; aside moves under the ask block. **Gestures.** Pull to reprint (§11) refetches `GET /library/world/recommendations` and `GET /library/suggest/availability` (A047) and never re-asks the AI.

**World card behaviour.** Available → opens the series (a source picker sheet when several sources have it: logos, names, health marks, `Open`). Information-only → `Search my sources` (Discover with `?q=`) and `Read on {site} ↗` (external, "Couldn't open {url}" toast on failure). `Not for me` hides the card (a 240 ms fade and the grid closes the gap by Cut) and sends `POST /ai/feedback {anilist_id | source/series, signal: "not_interested"}`. `More like this` is its positive twin: a `thumbs-up` `on-art` icon button beside the dismiss `x` (hover on desktop, always in the long-press menu; tooltip "More like this"), which fills (Fill + spot rule), fires haptic `select`, sends `signal: "liked_pick"` and shows the toast "Noted. Picks will lean this way."; pressing it again clears it locally.

**States.**

| State | Presentation |
|---|---|
| Loading world recs | Masthead live; `01 For you` header with 6 flicker plates |
| AI thinking | "Reading your shelf…" typed, leader after 1 s, cards stream |
| AI not configured (`reason: not_configured`, or an ask answering `ai_not_configured` 503) | Ask block replaced by a `NOTE` line with the §9.1.8 `not_configured` copy. World recs still show. |
| Budget exhausted (`budget_exhausted`, or an ask answering `ai_budget_exhausted` 429) | Ask field disabled; the quota folio reads `0 ASKS LEFT TODAY`; caption: the §9.1.8 budget copy |
| Shelf too thin (`suggest_shelf_empty` 409) | Notice `NOTHING TO PICK FROM YET`: "There isn't enough in the catalogue cache yet. Browse a few sources, then ask again." + `Browse sources`, plus a quiet `Ask everywhere instead` that switches the toggle to `FROM EVERYWHERE` |
| Ask failed (`ai_failed` 502) | The §9.1.8 `ai_failed` copy with `Try again`; the ask field keeps its text |
| No matches (`ai_no_matches`) | Notice in the results slot: "Nothing fit that description. Try describing it differently." |
| Rate limited (`rate_limited` 429 with `Retry-After`) | `SLOW DOWN` line with the §9.1.8 copy and the `Retry-After` countdown |
| World catalogue unreachable (`unavailable_reason`) | A quiet caption under the masthead with the server's reason; cached recs shown |
| Partial (some sections failed) | Loaded sections render; a failed AI section is omitted and the grid shows "Some picks didn't come through." (§9.1.8) |
| Stale (world recs older than 24 h) | `PICKED 3 DAYS AGO` micro badge beside the masthead deck (§9.1.8) |
| Empty (new profile) | Notice `NOTHING TO GO ON YET`: "Read or follow a few series first. Picks start from what you read." + `Find something` |
| Offline / error | Notices with Retry |

The client branches on the error `code`, never on the HTTP status (429 is both `ai_budget_exhausted` and `rate_limited`).

**Keys (web).** `/` focuses the ask field; `Enter` asks; `j`/`k` move through cards; `Delete` = Not for me on the focused card.

#### 9.1.4 More like this and Because you read

- **Similar** (`GET /ai/similar?source&series`, §9.1.7): a rail on the feature page's `03 MORE LIKE THIS` tab and in the caught-up end state; World cards with `why` lines ("Same regression premise, darker art."). Fallback when AI is unavailable: series sharing ≥ 2 genres on the profile's sources, captioned `SAME GENRES` instead of a `why`.
- **Because you read X**: rails on Tonight and Picks with the seed's title in the H3 (the title in italic inside the italic head is set in Roman for contrast: "Because you read *Solo Leveling*").
- **In-session re-ranking**: after the reader opens a series from a rail, the next visit to Tonight moves rails that share its top genre up by one position (client-side, per session).

#### 9.1.5 "Previously on" (`/recap/:sourceId/:seriesKey?to=:chapterKey`)

A takeover set as a **title card**, the editorial moment before the feature resumes.

**Layout (all platforms).**
- Background `#000` with the series cover as a duotone band across the top 28 % (phone 34 %), `scrim.foot.black` over the band's lower edge, grain 0.05.
- Kicker `PREVIOUSLY ON` with the letter reveal, then the series title in `type.headline` italic; deck: "Chapters 131–142, as a recap." (the covered range).
- **The recap**: 3–5 short paragraphs in Newsreader 20/32 (phone 18/28) at 58ch, streamed word by word (160 ms fade, 30 ms apart), with a Bodoni drop cap on the first paragraph. Character names in italic.
- **Cast list** (novels, from attribution `cast`; manga when the recap names characters): a credits list `Kim Dokja ........ the reader` with dot leaders; "Characters in this story" kicker.
- Footnote in `type.caption`: "Recap written from the dialogue of chapters 131–142." (manga, OCR-sourced) or "…from the text of chapters 131–142." (novels) + "AI-written; it can be wrong."
- **Skip recap** (visible from t = 0, like a streaming service's skip button): an `on-art` button `Skip recap →` (§7.1; it sits on the cover band above the part `scrim.foot.black` covers, so it carries its own `color.onart` ground, §2.1.4) at the top-right of the takeover (desktop: aligned to column 12 under the running-head height; phones: top-right under the safe area, 44 (48 Android) hit), goes straight to the reader by the recap's way into the reader (Entry behaviours below: Column wipe when the recap was opened from Tonight or a series page, Dip from anywhere else, and a Dip back to the open page when it was opened from the reader's chip). It never waits for the stream.
- Actions (sticky at the bottom on phones): `split` primary `Continue │ CH 143` (into the reader by the recap's way into the reader (Entry behaviours below: Column wipe when the recap was opened from Tonight or a series page, Dip from anywhere else, and a Dip back to the open page when it was opened from the reader's chip); usable from t = 0), `quiet` `Skip recaps for this series` (per-series preference), `quiet` `Close` (back to where the recap was opened).
- **Auto-continue countdown.** When the recap has finished streaming, `Continue` starts a **12 s countdown** (`dur.countdown.recap`): a 2 px `spot` rule inside the split button's bottom edge drains from full to empty (`ease.linear`) and the folio segment reads `CH 143 · 12 S`, counting down each second. At zero the reader opens by the recap's way into the reader (Entry behaviours below: Column wipe when the recap was opened from Tonight or a series page, Dip from anywhere else, and a Dip back to the open page when it was opened from the reader's chip). The countdown **pauses** while the pointer is over the `Continue` button, the recap text or the cast list, while any finger touches the screen, while keyboard focus is inside the recap text or cast list, while the page is hidden (`visibilitychange` / `AppLifecycleState.paused`), and whenever a screen reader is running (then it never starts; `Continue` waits for the user). On the web, where a virtual cursor does not move focus and no screen reader can be detected, it also pauses on any `keydown` other than `Space`, `Enter`, `s` and `Esc` (which keep their own actions: `Space` pauses or resumes, `Enter` continues, `s` skips the recap, `Esc` closes), on `pointerdown`, on a text selection inside the recap and on `focusin` anywhere in the takeover. When it first starts, a polite live region says "Continuing to chapter 143 in 12 seconds. Press Space to pause." (`Space` is the existing pause key). With Settings → Reading → "Continue automatically after a recap" `OFF` (per profile, default `ON`), no countdown runs and `Continue` waits. Scrolling back up in the recap resets it to 12 s. Reduced motion: no draining rule; the folio label updates once per second.
- Desktop: the recap column spans columns 3–9; the cast list sits in columns 10–12.

**Availability and range.** `GET /ai/recap/availability?source&series&to` (§9.1.7) answers `{available, reason: "ok" | "no_dialogue" | "first_chapter" | "not_configured" | "budget_exhausted", range: {from_key, to_key, from_number, to_number}, est_seconds, cached}`. `GET /home` carries the same object as `recap` on `cover` and on each `continue` and `where_were_we` item, and `GET /library/continue-reading` carries it on each row (so Library's Continue rail, its cuttings' Quick look and their `Continue` follow the setting below); the feature page, the book page and the reader call the endpoint directly, once on load (the reader: once on its first page). Any other Quick look (a poster whose item carries no `recap`) calls the endpoint when it opens and adds its `Previously on` row only on an `available` answer, never holding the other rows. Any other `Continue` whose item carries no `recap` calls the endpoint on press when the setting could auto-open a recap, and goes straight to the reader if the call fails or takes longer than 400 ms.
- **Range**: the chapters this profile completed before `to`, newest first, at most 12; the walk stops at the first gap of more than 60 days between consecutive `last_read_at` values.
- **Available when**: manga, `GET /ocr/coverage` indexes at least 50 % of the range's chapters; novels, always, except on the first chapter; both, the AI desk is configured and the budget allows it (a `cached` recap is always available).
- **Rendering**: every `Previously on…` button (Tonight's cover story and now-showing strip, `Where were we?` long-press, the feature and book pages, Quick look) and the reader chip render only when `available`. Cover-story case 3 (§9.1.2) uses `available` too.
- **Budget**: a recap counts as one ask against the caller's daily ceiling (60 for the owner, 10 for other accounts; the same ledger as `/library/suggest`), and only on a cache miss.

**Entry behaviours.** The setting **Previously on** (Settings → Reading, §8.30.2) has three values: `ALWAYS` (every Continue on a series whose last read was a different day opens the recap first), `AFTER N DAYS AWAY` (default N = 14; the recap opens first when the gap is ≥ N days), and `NEVER` (recaps open only from the explicit `Previously on…` buttons). A series with "Skip recaps for this series" set behaves as `NEVER`. `ALWAYS` and `AFTER N DAYS AWAY` auto-open the recap only when `available`; otherwise `Continue` goes straight to the reader with no slate. When the recap opens first, `Continue` and the countdown proceed into the reader. The way into the reader follows §8.14.2: from a recap opened on Tonight or a series page, the Column wipe; from a recap opened anywhere else (a Library cutting's Quick look, for example), a Dip; from the reader's own chip, `Continue`, `Skip recap` and the countdown close the takeover with a Dip back to the open page. In the reader: a slim chip on the first page, `PREVIOUSLY ON · {ceil(est_seconds / 60)} MIN` (quiet button, e.g. `PREVIOUSLY ON · 2 MIN`), when the last read of this series was ≥ N days ago (14 when the setting is `ALWAYS` or `NEVER`) and `available` is true.

**States.**

| State | Presentation |
|---|---|
| Loading | The title card with kicker and title set; "Writing the recap…" typed; leader after 1 s |
| Streaming | Words fade in; `Continue` and `Skip recap` are usable at any time |
| Done | The countdown runs (paused per the rules above) |
| No recap (only after an explicit tap on a button whose availability went stale, e.g. the answer is `no_dialogue`, as JSON or as a stream `error`) | Kicker `NO RECAP FOR THIS ONE`; "The dialogue in these chapters hasn't been read yet, so there's nothing to recap." + `Continue │ CH 143` (app: `Scan saved chapters` when some are downloaded) |
| AI unavailable / not configured / budget spent / rate limited | A static slate: kicker `RECAP UNAVAILABLE` in `ink.45`; "Pick up where you left off: chapter 143." + `Continue`. Rate limited adds the §9.1.8 `SLOW DOWN` line with the `Retry-After` countdown. Never error red: an absent recap is not an error. |
| First chapter (nothing to recap) | The button never appears; a stale `first_chapter` answer goes straight to the reader with no slate |
| Offline | The slate as AI unavailable, with `OFFLINE EDITION` |
| Error | `CORRECTION` line + `Try again` + `Continue` |

**Keys (web).** `Enter` continue; `s` skip recap (straight to the reader); `Esc` close; `Space` skips the streaming (shows all text) and, once the recap is complete, pauses or resumes the countdown.

#### 9.1.6 When the AI desk is closed (fallbacks)

The app never looks broken without AI:
- Tonight's cover story uses the local priority rules (§9.1.2 cases 1–3, else the most recently updated followed series) and the synopsis as the deck.
- `Picked for you` becomes `From your shelf` (favourites and plan-to-read, same position), headed by a `NOTE` line with the §9.1.8 copy for `ai.reason`. `Almost there`, `Where were we?` and `Sent to you` are not AI-dependent and stay.
- Because-you-read rails come from world recs when that catalogue is reachable (not AI-dependent); otherwise they are omitted.
- Picks shows world recs without the ask block; recaps show the static slate; Similar uses the genre fallback.

#### 9.1.7 Backend contract (new endpoints; the AI calls stay server-side)

| Endpoint | Returns | Notes |
|---|---|---|
| `GET /home?content_kind=manga\|novel&tz_offset_minutes=` | `{issue_no, headline, deck, streak: {current_days, longest_days, at_risk, last_active_date, milestones_seen}, cover: {source_id, series_key, chapter_key, reason, ambient, content_kind, recap}, also: [{kind, source_id, series_key, headline, deck, ambient}], sections: [{type, title, seed?, note?, items, why?, state, generated_at}], ai: {available, reason}}` (`recap` on `cover` and on each `continue` and `where_were_we` item is the §9.1.5 availability object; `content_kind` follows the reading mode, §8.0.8; `also` follows §8.8's selection rules) | Section `type`s in order: `first_picks`, `continue`, `new_this_week`, `almost_there` (reading, ≤ 3 chapters left), `where_were_we` (reading, last read 21–120 days ago), `sent_to_you` (letters; `note` is the newest letter's note), `picked`, `because`, `circle`, `circle_top`, `sources`, `genres`, `numbers`, plus `popular` for new profiles. `state` is `ready · empty · unavailable · stale` (§9.1.8); `generated_at` drives the stale stamp. Composed from continue, recently-updated, world recs, taste, letters and circle; cached 10 min per (profile_id, mature_content_enabled, content_kind, tz_offset_minutes, local hour), so a gate change reads a different entry and composes afresh with its own cover story (no purge hook); 18+ gated on serve. `tz_offset_minutes` is required (−720..840): web sends `-new Date().getTimezoneOffset()`, Flutter `DateTime.now().timeZoneOffset.inMinutes`; the headline's time word and `at_risk` use it |
| `GET /ai/similar?source&series` or `?anilist_id=` | `{items: WorldItem[] (each with why), available, reason: "ok" \| "not_configured" \| "budget_exhausted" \| "rate_limited", generated_at}` (3 items for `anilist_id`, onboarding step 5) | Seeded similarity; budget-free cache 7 days |
| `GET /ai/recap/availability?source&series&to` | `{available, reason: "ok" \| "no_dialogue" \| "first_chapter" \| "not_configured" \| "budget_exhausted", range: {from_key, to_key, from_number, to_number}, est_seconds, cached}` | Range and availability rules in §9.1.5; no AI call, no budget cost |
| `GET /ai/recap?source&series&to` | SSE: `event: meta` first, data `{range, cast, sourced_from: "ocr" \| "text"}`; then `event: delta`, data `{text}`; then `event: done`; or `event: error`, data `{code, message}` | Built from OCR `page_texts` (manga) or paragraphs (novels); cached per (series, range); one ask against the daily budget, on a cache miss only. Web reads it with `fetch` and a `ReadableStream` reader (not `EventSource`, which cannot send `X-Profile-Id`); Flutter uses the installed `dio` 5 with `ResponseType.stream` and a `LineSplitter`, no new package. **No stream:** when no recap can be written at request time (availability can change after the availability check), it answers plain JSON 200 before any stream, `{"available": false, "reason": "not_configured" \| "budget_exhausted" \| "rate_limited" \| "no_dialogue" \| "first_chapter"}`, and the clients map `reason` onto the §9.1.5 states exactly as they would a stream `error` with that code: `no_dialogue` → `NO RECAP FOR THIS ONE`; `not_configured` and `budget_exhausted` → the `RECAP UNAVAILABLE` slate; `rate_limited` → the `RECAP UNAVAILABLE` slate with the §9.1.8 `SLOW DOWN` line and its `Retry-After` countdown (the JSON answer carries `Retry-After` for this reason); `first_chapter` → straight to the reader with no slate. **Stream headers:** `Content-Type: text/event-stream`, `Cache-Control: no-cache, no-transform`, `X-Accel-Buffering: no`; `no-transform` stops the Next server's compression middleware from buffering the `/api` rewrite |
| `POST /ai/feedback {signal: "not_interested" \| "liked_pick" \| "tag_rejected", anilist_id?, source_id?, series_key?, tag?}` | 204 | `tag` is required for `tag_rejected` (it names the suggested tag being rejected, §8.17) |
| `PUT /profiles/{id}/taste` | taste | Onboarding (§8.7) |
| `GET /ai/tags?source&series` | `{tags: [string ≤ 5], available, reason}` | Suggested tags on the feature page aside (§8.17); cached 30 days per series; `tag_rejected` feedback removes a tag for this profile |

**`GET /home` section items** (the `items[]` shape per section `type`):

| Section `type` | `items[]` |
|---|---|
| `continue` | continue-reading rows (which carry `recap`, §9.1.5) + `ambient`, `nudge: "new" \| "almost_done" \| "paused" \| null`, `new_count`, `paused_days` (the §8.8 badges `3 NEW`, `ALMOST DONE`, `PAUSED 21 D`) |
| `new_this_week` | FollowedSeries list rows + `ambient` |
| `where_were_we` | FollowedSeries list rows + `ambient`, `recap` (the §9.1.5 availability object, for the long-press `Previously on`) |
| `almost_there` | FollowedSeries list rows + `ambient`, `chapters_left` |
| `sent_to_you` | Letter (the `GET /circle/letters` shape, §9.3.8) |
| `picked`, `because`, `first_picks`, `popular` | `{kind: "world", item: WorldItem}` or `{kind: "source", item: SourceSeries}`, each with `why` |
| `circle`, `circle_top` | `{member: {profile_id, name, avatar_key}, series: {source_id, series_key, title, cover_url, ambient}, rank?}` |
| `sources` | pin rows + `latest_covers: [cover_url × 3]` |
| `genres` | `[{genre, weight}]` |
| `numbers` | `{streak, chapters_week, seconds_week}`, where `streak` is the same object as the top-level `streak` of this response (`{current_days, longest_days, at_risk, last_active_date, milestones_seen}`), so the teaser's flame (§9.2.2) has every tier's input |

---

#### 9.1.8 AI state vocabulary (the shared contract for rails, Picks, recaps and Similar)

Every AI-backed surface is in exactly one of these states, and each state looks the same everywhere:

| State | Visual | Copy |
|---|---|---|
| **thinking** | A typed line ("Reading your shelf…", "Writing the recap…") with a leader dial after 1 s, then word-by-word streaming (160 ms fade, 30 ms apart) or cards fading in as they arrive (160 ms, 30 ms apart). Never a spinner, never a skeleton that pretends content exists. | The typed line only |
| **unavailable** | A static slate or a `NOTE` kicker in `spot` (`color.note`) with the reason in `type.caption` `ink.60`; never `proof`, never an error rule. The recap slate's `RECAP UNAVAILABLE` kicker stays `ink.45` (it is not a `NOTE`). The non-AI path is always offered beside it (the local rail, world recs, `Continue`). | A plain reason keyed by `ai.reason` or the error `code`, from the copy table below |
| **partial** | What loaded renders; missing AI rails are omitted (the folios renumber, §8.8), a Picks results grid shows the cards that arrived with the caption "Some picks didn't come through." | None beyond that caption |
| **stale** | The content renders with the micro badge `PICKED 3 DAYS AGO` (1 px `ink.45` outline, `type.micro`) beside the H3, the Picks masthead deck or the recap's footnote, when `generated_at` is older than 24 h; the recap footnote reads "Recap written 3 days ago." | The badge only |

**Unavailable copy** (the only copy for these states; §7.8, §9.1.3 and §9.1.6 reference it, and a surface may only append its non-AI path, e.g. §7.8's "Here is your shelf instead."):

| Key | Copy |
|---|---|
| `budget_exhausted` / `ai_budget_exhausted` | "The picks desk is closed tonight. Asks reset at midnight UTC." |
| `not_configured` / `ai_not_configured` | "The editors' desk isn't set up on this server." |
| `rate_limited` | `SLOW DOWN`: "Too many asks at once. Try again in {n} s.", with the live `Retry-After` countdown |
| `ai_failed` | "The editors couldn't answer that one. Try describing it differently." |

This table is the only place these states are designed: Tonight's `Picked for you` and `Because you read` rails (§8.8), the Picks screen (§9.1.3), "Previously on" (§9.1.5), Similar (§9.1.4) and suggested tags (§8.17) all use it.

### 9.2 Reading stats, streaks and The Annual

Statistics are the magazine's **back-of-book numbers**: set in Bodoni numerals, with rules instead of chart chrome.

#### 9.2.1 The Numbers (`/library/statistics`)

**Desktop layout.**
- Masthead: kicker `No. 10 — THE NUMBERS`, title "The Numbers", deck "What you've actually read on this profile."; at the masthead's right, `Share` (secondary sm with `export`, keyboard `s`) opens the press-run sheet (§9.2.5) on the current range: the same templates filled with the range's figures, the card kicker reading `THE NUMBERS · 30 DAYS` instead of `THE ANNUAL 2026`. Hidden with no reading recorded.
- Range contents tabs: `7 DAYS · 30 DAYS · 90 DAYS · YEAR` (default 30; YEAR = `days=365`); remembered per profile.
- A banner strip when The Annual is available (§9.2.4): `THE ANNUAL 2026 IS OUT` + `Open` (from 1 December, or any time with ≥ 30 days of data as "Your year so far"). When earlier Annuals exist (`GET /library/annual` returns `available_years`), the banner ends with a year slug line `2026 · 2025 · 2024`, each opening that year's issue; the current year is `ink.100`, the others `ink.60`.
- **Lead**: the streak block (§9.2.2) in columns 1–4; four stat blocks (§7.6) in columns 5–12: `CHAPTERS 184` ("1,240 all time"), `TIME 31 H` ("412 h all time"), `PAGES 6,812` ("48,221 all time"), `SERIES 23` ("212 followed").
- **Chapters per day** (columns 1–8): bars of 1-day width with 2 px gaps in `ink.100`, the selected or hovered day in `spot`; time per day as a dotted `ink.45` line with square 4 px markers; left axis chapters, right axis time (`type.folio`), 4–6 date labels; a readout line above the chart ("Mon 21 Sep · 12 chapters · 1 h 40 m"); "Best day 14 Sep · 31 chapters" aside. On YEAR range, a **heatmap** replaces it: 53 × 7 cells (10 px, 2 px gaps). Levels are encoded by size, not tone (four tone levels plus black cannot all be 3:1 apart): each cell draws an `ink.100` square of 3, 5, 7 or 10 px for levels 1–4, centred in the cell (18.44:1 against black); a zero day is a 10 px square with a 1 px `rule.2` outline; today keeps its 1 px `spot` outline. A legend under the heatmap shows the five cell forms with their chapter ranges: `0 · 1–2 · 3–5 · 6–10 · 11+`. Month labels in `type.folio`.
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

#### 9.2.2 The streak flame

The flame is always `spot` yellow and never gains more glow than the one `spot.glow` bloom below. Its **shape** grows with the streak, and its **state** says whether today is done.

**Read today** means `streak.last_active_date == local today` (from statistics, or `/home` called with `tz_offset_minutes`, §9.1.7). The streak counts any day with a reading session, a few pages included, not only a finished chapter.

**Tiers** (by the current streak, `streak.current_days` in the profile's time zone):

| Streak | Mark | Motion |
|---|---|---|
| 0 (none or broken) | **Ember dot**: a 6 × 6 px square in `ink.45`, centred where the flame would stand | none |
| 1–6 days | `flame-1` glyph (one tongue) | 2 s (`dur.flame.flicker`) flicker when alive today: opacity 0.85 ↔ 1, scaleY 0.98 ↔ 1.02, `ease.drift` |
| 7–29 days | `flame-3` glyph (three tongues) | the same flicker, tongues offset 300 ms from each other |
| 30–99 days | `flame-3` inside a 1 px `spot` **ring** (a circle 1.5 × the glyph size) with a 4 px gap that turns once every 24 s (`dur.flame.ring`, `ease.linear`) | flicker + ring |
| 100+ days | as 30–99, plus **sparks**: three 2 × 2 px `spot` squares rising 12 px and fading out over 900 ms (`dur.flame.spark`), one every second, then 3 s of rest | flicker + ring + sparks |

**States** (apply to every tier from 1 day up):

| State | Presentation |
|---|---|
| Alive, read today | The tier's glyph in Fill `spot` with the `spot.glow` bloom (the one glow in the UI); the numeral in `type.numeral` beside it; caption `DAYS IN A ROW · LONGEST 31` |
| Alive, not yet today (before 20:00 local) | The glyph outlined (Light, `ink.100`), no bloom, no flicker; caption "Read today to keep your 12-day streak." |
| **At risk** (after 20:00 local, not yet today) | The glyph outlined in `spot` (Light), no bloom, flickering 0.7 ↔ 1 over 800 ms (`dur.flame.risk`, `ease.drift`); caption "Twelve days and counting. One chapter keeps it alive."; Tonight's headline switches to the at-risk line (§9.1.2). No push notification. |
| Broken / none | The ember dot; caption "Longest: 31 days. Start a new one today." |
| Just extended (a refetch after leaving a reader shows `last_active_date` flip to today; seen on that visit to Tonight or The Numbers) | The flame **ignites**: stroke → fill over 400 ms `dur.glide` `ease.settle` with the bloom rising 0 → 0.35; when the new count crosses a tier boundary (1, 7, 30, 100) the glyph swaps to the new tier during the ignite; the numeral types its new value; haptic `streak.extend`; sound `bell` if on |
| Week dots | Under the numeral: 7 squares (Mon–Sun, 8 px, 4 px gaps), `spot` for days read, `rule.2` outline otherwise, weekday initials in `type.micro` |

**Milestone title cards** (7, 30, 100 and 365 days). The first visit to Tonight or The Numbers after the chapter that reached a milestone opens a takeover title card (Dip in, Dip out; never inside a reader):
- `#000000` stock, the tier's flame at 96 px in `spot` with its bloom, the kicker `STREAK` (letter reveal), the numeral typed in `type.numeral` × 1.5 (`30`), the headline set with the letter reveal in sentence case: "Seven days in a row." / "Thirty days in a row." / "One hundred days in a row." / "A whole year, every day." and a deck in `type.deck` `ink.60`: "Your longest yet." (or "Your longest is 41.").
- Actions: `Share` (primary; opens the press run with the **Streak** card template, §9.2.5, prefilled with the milestone) and `Close` (quiet). Tap outside, swipe down, `Esc`, Android back and browser back close it (a routed overlay: `?view=milestone` on the web, §8.0.3).
- Haptic `streak.milestone`; sound `bell` if on. Each milestone shows once per profile (stored server-side as `streak.milestones_seen`, which `GET /home` and `GET /library/statistics` both return, so Tonight and The Numbers agree and it does not repeat on another device; the card opens when `current_days` has reached a milestone missing from that list, and opening it posts `POST /library/statistics/milestones/{days}/seen`). Reduced motion: the card fades in 200 ms (`dur.clip`) with the text at rest.

The same flame (24 px, same tier and state) sits in Tonight's `This week in numbers` section and in the Index row; a 16 px at-risk flame precedes Tonight's kicker while at risk.

#### 9.2.3 Chart rules

No gridlines except `rule.1` baselines; numbers in Plex Mono; every chart has a text summary above it (for screen readers and at-a-glance reading) and each data mark has an accessible label ("21 September, 12 chapters, 1 hour 40 minutes"). Charts are drawn with SVG on web and `CustomPainter` in Flutter; no chart library.

#### 9.2.4 The Annual (`/library/statistics/annual/:year`)

A **Wrapped-style year recap set as a special issue**: eleven pages (nine story pages, the colophon, the press run), each a spread on desktop and a full-screen story page with a 9:16 safe box on phones.

**Frame.**
- Phone: full-screen takeover. The page fills the screen (phones are about 9:19.5): art bleeds to every edge, and text and figures sit in a centred 9:16 safe box. A row of 2 px segments sits at `viewPadding.top + 8` with 16 px side margins, one per page shown (eleven, or ten when the circle page is skipped) (current segment fills `spot` over the page's hold time); close `x`, the `on-art` icon button (§7.2: a 40 px `color.onart` square, glyph `ink.100`, because no scrim covers the top edge; 44 (48 Android) hit), sits 8 px under the segments at the right margin; the tap thirds ignore the top `viewPadding.top + 64` px and the bottom `viewPadding.bottom + 48` px; tap right third → next, left third → previous, horizontal swipe left → next and right → previous (finger-tracked, `spring.release`), press and hold → pause (segments freeze), swipe down → close. Auto-advance 6 s per page (`dur.hold.annual.page`; 8 s, `dur.hold.annual.list`, for pages with lists; 12 s for the colophon: its 10 s roll, `dur.roll.colophon`, plus the 2 s hold, `dur.hold.brief`). Haptic `annual.page` on tap or swipe advance.
- **Screen readers and keyboards.** The story is a group, not a gesture surface: web `role="group"` with `aria-roledescription="story"` and `aria-label="The Annual 2026, page 3 of 11"`, containing visually hidden `Previous page`, `Pause` / `Play` and `Next page` buttons first in the tab order (they become visible on focus, bottom-centre, as `on-art` buttons (§7.1: fill `color.onart`, text `ink.100`, which meets the 0.60 over-art minimum)); Flutter `Semantics(customSemanticsActions: {CustomSemanticsAction(label: 'Next page'): next, CustomSemanticsAction(label: 'Previous page'): previous, CustomSemanticsAction(label: 'Pause'): pause})` on the page, and whenever a screen reader is running the same three buttons are drawn visibly at the bottom (auto-advance is off then, §14.5). On each page change focus moves to the page title and a polite live region announces "Page 3 of 11: Chapters".
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
| 10 Colophon ("End credits") | The magazine's colophon set as film end credits, rolling upward at 36 px/s (`ease.linear`) over 10 s (`dur.roll.colophon`) on a `#000000` page with the top series' duotone art as a faint band behind (grain 0.06). Credits lines, each a `type.credit` label with a Bodoni Moda Italic value, centred: `STARRING` the top 5 series by time; `SHOT ON` the top sources ("Shot on MangaDex, Asura"); `NARRATED BY` the voices used most in Listen, up to 3 (`top_voices` from `GET /library/annual`, recorded by `POST /novels/listen-sessions`, §9.2.7; "Narrated by Arden"; the line is omitted when `top_voices` is empty); `WITH` circle members who shared at least one series with this profile (only with Circle sharing on for both); `SET IN` Bodoni Moda, Archivo, Newsreader and IBM Plex Mono; `PRINTED ON` ManhwaManiacs (the product name only, never the server address). The roll ends on "See you in 2027." in `type.headline` italic with the letter reveal, held 2 s (`dur.hold.brief`). Tap or `→` skips to the press run; hold pauses the roll. Reduced motion: the colophon is a still page with every line visible. 18+ series never appear in the credits for a gated profile, and never on the press-run cards. |
| 11 Press run | The share page: the six card templates (§9.2.5) as thumbnails, `Share` (primary), `Save image` (secondary), `Read the numbers` (quiet → The Numbers) |

Calendar year: The Annual covers 1 January to 31 December in the profile's local time (`GET /library/annual?year=&tz_offset_minutes=`, §9.2.7). The current year's cover reads "Your year so far" until 31 December.

**States.** Not enough data (< 7 days recorded): a single page "Your Annual needs a few more weeks of reading. 5 days recorded so far." + `Close`; loading ("Setting the pages…" typed, leader); offline (cached pages if previously opened, else notice); error.

#### 9.2.5 Share cards ("press run")

**Templates** (six): Time, Chapters, No. 1, Genres, Streak (with the milestone number and tier flame when opened from a milestone card, §9.2.2), Clock. Formats: **Story** 1080 × 1920 and **Post** 1080 × 1350, chosen in the share sheet.

**The press-run sheet** (from The Annual's page 11, a milestone card's `Share`, or The Numbers' `Share`): a `[0.92]` sheet on phones, a 720 px dialog on desktop. Kicker `PRESS RUN`; a 240 px tall live preview of the rendered card (the actual PNG at scale, square corners, 1 px `rule.2` frame); a template slug line `TIME · CHAPTERS · NO. 1 · GENRES · STREAK · CLOCK` (templates without data are omitted); the format segmented control `STORY │ POST`; actions `Share` (primary) and `Save image` (secondary; on desktop `Download PNG` is the primary and there is no `Share`, since desktop browsers rarely share files). States: *rendering* (the preview keeps the previous card at 40 % with a 24 px leader dial over it, `Share` in its loading state; a render takes ≤ 400 ms, so the dial appears only on a slow device); *render failed* (`toBlob` or `toImage` failed: the toast "Couldn't make the card. Try again." and the preview keeps the last good card); *share cancelled* (`navigator.share` rejects with `AbortError`, or the native sheet is dismissed: silent, the sheet stays open); *share failed* (any other rejection, or `canShare` false: the card downloads instead with the toast "Saved the card instead."); *saved* (toast "Card saved."). Web downloads name the file `manhwamaniacs-{template}-{format}.png`.

**Card anatomy.** `#000` stock; a 64 px margin; top: kicker `THE ANNUAL 2026` and the profile name; centre: the key figure in Bodoni Moda Roman with its caption in Newsreader Italic; a duotone art band (the relevant cover) across the lower third with grain; bottom: the wordmark at 40 px with its Oxford rule and `manhwamaniacs` in Plex Mono 24. Story: key figure 360 px, caption 48 px. Post: key figure 252 px, caption 32 px (Story × 1350 / 1920 ≈ 0.70, rounded to the 4 px baseline). The 64 px margin, the 40 px wordmark with its Oxford rule and Plex Mono 24 are the same in both. All text is drawn, never screenshot from the UI.

**Export pipeline.**
- Web: a zero-dependency Canvas 2D renderer (`renderShareCard(kind, format, data): Promise<Blob>`), which awaits `document.fonts.load()` for the four faces, draws the duotone art through an offscreen canvas and the same colour matrix (§2.1.5), and exports PNG with `canvas.toBlob`. Sharing: `navigator.share({ files: [file] })` when `navigator.canShare({ files })` is true, else a download via an object URL.
- Flutter: the card is a widget rendered offscreen in a `RepaintBoundary`, captured with `toImage(pixelRatio: 1080 / logicalWidth)` and `toByteData(format: png)`; shared through `share_plus` 12.0.2 (`SharePlus.instance.share(ShareParams(files: [XFile.fromData(bytes, mimeType: 'image/png', name: 'manhwamaniacs-{template}-{format}.png')]))`). `Save image` by platform:
  - **iOS.** It opens the share sheet, whose Save Image writes to Photos. In the native-plugin commit, `mobile/ios/Runner/Info.plist` gains `NSPhotoLibraryAddUsageDescription` = "ManhwaManiacs saves share cards to Photos only when you choose Save image. It never reads your library." (without it iOS terminates the app when Save Image is chosen). No photos permission plugin.
  - **Android API 29 and above.** It inserts the PNG into `MediaStore.Images.Media` with `RELATIVE_PATH` `Pictures/ManhwaManiacs`, named `manhwamaniacs-{template}-{format}.png`, through a small `mm/media` method channel in `MainActivity.kt` (its second method, `saveDownload`, serves Android exports, §8.23). It needs no permission. Toast: "Card saved to Pictures › ManhwaManiacs."
  - **Android API 24–28** (minSdk 24). The button is hidden, and `Share` is the only action.
- Haptic `share.export` on render; the `set` cue plays if UI sounds are on.

**Privacy rules.** 18+ series never appear on a card, whatever the gate, and neither do their covers or genres weighted by mature reading: every card draws only on the server's `shareable` block (§9.2.7), computed from series that are not mature. The Genres card uses `shareable.genre_weights`; the No. 1 card and every art band (the "relevant cover") use `shareable.top_series` / `shareable.art_series`; a template whose shareable data is empty is omitted, as templates without data already are. The Annual's own pages keep the full, gated data. Only the profile name (not the username or server) is printed. No template names another member of the circle (there is no Circle card; The Annual's circle page and the colophon's `WITH` line stay inside the app).

#### 9.2.6 Entry points

The Numbers banner strip; Tonight's `This week in numbers` section (`Open The Numbers →`, and in December `The Annual is out →`); Index `The Annual`; a one-time toast on the first app open in December ("The Annual 2026 is out." + `Open`).

#### 9.2.7 Backend

`GET /library/statistics` (existing, `days` up to 365) covers the numbers. New: `GET /library/annual?year=&tz_offset_minutes=` (the offset is required, −720..840, as for `/home`) returning the eleven pages' aggregates (time, chapters per month, top series, genre weights over the window, clock, longest streak with its month, top sources, circle overlaps, and for the colophon the top 5 series by time and the top 3 narration voices by listening time) so both clients render identical figures, plus `available_years` (years with ≥ 7 days recorded, newest first, for the year slug line) and `top_voices: [{voice_id, name, seconds}]`; cached per day under the key `(profile_id, mature_content_enabled, year, tz_offset_minutes)` (The Annual is mode-agnostic, §8.0.8, so `content_kind` is not part of it), so a gate change, another year or another offset reads a different entry and composes afresh (no purge hook). It and the range payload behind The Numbers' `Share` also return `shareable: {genre_weights, top_series, art_series}`, computed server-side only from series that are not mature (source not mature, and resolved rating not mature after `mature_override`), for the share cards (§9.2.5). Circle figures (`circle`, the colophon's `WITH`) are computed from each member's shareable activity set (§9.3.1).

**Listening is recorded** so the colophon can credit voices: `POST /novels/listen-sessions` (new) takes an array (≤ 200) of `{source_id, series_key, chapter_key, seconds, voice_ids[≤ 3], started_at}`. Both clients batch on pause, at chapter end and when the app goes to the background, send only sessions with `seconds ≥ 10`, and queue offline in the progress outbox. The response, by field name (`GET /library/annual?year=2026&tz_offset_minutes=330`):

```
{
  year, partial, since, until, recorded_days, seconds_read, chapters_read,
  chapters_by_month: [12 ints],
  top_series: [{source_id, series_key, title, cover_url, ambient, seconds_read, chapters_read}] (≤ 5),
  genres: [{genre, weight}] (≤ 8),
  by_hour: [24 × {hour, seconds_read}],
  longest_streak: {days, month},
  top_sources: [{source_id, name, share}] (≤ 3),
  circle: [{profile_id, name, avatar_key, finished_together: [title]}] | null,
  top_voices: [{voice_id, name, seconds}] (≤ 3),
  available_years: [int],
  shareable: {genre_weights: [{genre, weight}] (≤ 8), top_series: [{source_id, series_key, title, cover_url, ambient, seconds_read, chapters_read}] (≤ 5), art_series: [{source_id, series_key, cover_url, ambient}]}
}
```

`partial` is true for the current year and drives the "Your year so far" line (§9.2.4). 18+ series are filtered on serve for a gated profile.

---

### 9.3 Circle: social for two or three readers

The **letters page** of the magazine: what the other readers on this server are reading, reactions on chapters, shared shelves and recommendations passed by hand. Private by default, per profile, and blind to 18+ for anyone whose gate is closed.

#### 9.3.1 Model and privacy

- **Opt-in per profile.** Nothing is visible to anyone until a profile turns sharing on (Settings → Circle & privacy). The default state of the whole feature is "nothing shared yet".
- **Granular switches per profile**: `Share what I'm reading` (activity), `Show my reactions`, `Let others add me to shared shelves`, `Receive recommendations`, and `Include 18+ titles in my activity` (off by default; even when on, 18+ items are only served to viewer profiles whose own gate is open).
- **Isolation.** A viewer sees *profiles*, not accounts; the circle lists sharing profiles across all accounts on the server. A profile never sees another profile's library, history or bookmarks beyond the shared activity items.
- **Gate on serve.** Activity, reactions, shared shelf members and letters about 18+ series are filtered out for gated viewers; counts are computed after filtering.
- **The shareable activity set** S(member, viewer): the activity events recorded while the member's `Share what I'm reading` was on (reading done before sharing was turned on never counts), for series not in the member's `Hide this series from my activity` list; a mature series counts only when the member's `Include 18+ titles in my activity` is on **and** the viewer's gate is open. Every Circle-derived figure is computed from S only, server-side, at serve time: The Annual's overlaps and its colophon `WITH` line, the `circle` and `circle_top` rails and their counts, member-page rails and deck counts ("Reading 4 series"), reaction lists, and `now` on `GET /circle/members`.

#### 9.3.2 Circle screen (`/circle`)

**Desktop layout.**
- Masthead: kicker `No. 11 — THE CIRCLE`, title "The Circle", deck "What the other readers on this server are reading."
- **Readers strip**: sharing profiles as 44 px avatars with names; when two profiles on different accounts share a name ("Yash" twice), each carries its account's `@username` as a `type.caption` line under the name, everywhere a member is named (strip, dispatches, letters, pickers); a `NOW` badge on anyone who read in the last 15 minutes; click → member page. **The Circle lights up**: a member who is reading right now wears the reading-now ring (§7.25): 2 px at 3 px offset in the `ambient.duo` of the series they have open, so the strip is literally coloured by what everyone is reading. The ring dissolves to a new colour over 800 ms when they switch series and fades out 15 minutes after their last page. Hover or long-press: "Reading Omniscient Reader · CH 212" (the chapter folio is withheld as "reading Omniscient Reader" when the viewer has not reached that chapter, per the spoiler guard in §9.3.3). Gated or excluded series show no ring and no `NOW` for that viewer.
- Contents tabs: `ALL · READING · REACTIONS · LETTERS ² · SHELVES`.
- **Activity column** (columns 1–8): dispatches grouped by day (date rules). Each dispatch: 32 px avatar → sentence in Newsreader 16 with the series title in italic ("*Riya* finished chapter 88 of *Tower of God*.", "*Arjun* started *Lookism*.", "*Riya* reacted ♥ to chapter 142 of *Omniscient Reader*."; a reaction on a chapter the viewer has not finished reads "*Riya* reacted to chapter 142 of *Omniscient Reader*." with no glyph, §9.3.3) → time folio `2 H` → a 40 × 60 cover at the right (click → feature page) → a quiet `Read it too` for series the viewer doesn't follow. Hover and pressed: the §7.16 row states (a 2 px `ink.100` left bar, text `ink.100`, 120 ms `dur.snap`).
- **Letters** (aside, columns 9–12): unread recommendation letters (§7.6 Letter card) stacked, newest first.
- **Shelves** tab: shared collection plates.

**Phone layout.** Readers strip scrolls horizontally; tabs scroll; dispatches full width with the cover at the right; letters are a tab, with a count badge.

**Signature moment.** A new letter **unfolds**: its card is revealed by a clip from the top edge down (like opening a folded note, 480 ms `settle`), the sender's kicker types itself, and the `spot` new-dot fades once it is read.

**States.**

| State | Presentation |
|---|---|
| Nothing shared yet (default) | Notice `THE CIRCLE IS QUIET`: "Nobody has shared their reading yet. Turn on sharing to be the first." + `Sharing settings` |
| This profile doesn't share | A `NOTE` banner "You're reading privately. Others can't see your activity." + `Share` (still shows others' activity: seeing is not conditional on sharing. This reciprocity rule is the current design and is listed as an owner call in §15.10) |
| Only me | "You're the only reader sharing so far." |
| Tab empty: READING | "Nobody is reading right now." |
| Tab empty: REACTIONS | "No reactions yet. They appear here when someone stamps a chapter." |
| Tab empty: LETTERS | "No letters yet. When someone passes a series to you, it lands here." |
| Tab empty: SHELVES | "No shared shelves yet." + `New shelf` |
| Loading | 6 greeked dispatches |
| Offline | The last cached feed shows read-only with the `OFFLINE EDITION` badge; letter actions are disabled with the tooltip "Needs a connection."; reactions keep their queued behaviour (§9.3.3) |
| Error | `CORRECTION` "The circle didn't load." + `Try again` |

Tab empties use the notice tone (§7.23) at subhead size, left-aligned in the activity column. New letters are signalled on phones by the Index tab's count badge (§7.14) and the Index `Circle` row folio (`2 NEW`); on desktop by the sidebar's `11 Circle` count.

**Keys (web).** `j`/`k` dispatches; `Enter` open; `1`–`5` tabs; `l` letters.

#### 9.3.3 Reactions on chapters

- **Where**: the chapter-end credits (manga and novels), the feature page's schedule rows (count folio), the reader's `CIRCLE` panel.
- **The five stamps** (square 44 × 44 outlined 1 px `rule.2`, glyph 20 + count folio): `♥` Loved (`heart`), `!!` Shook (`lightning`), `HA` Laughed (`smiley`), `…` Tears (`drop`), `✦` Chef's kiss (`sparkle`). Under each, the avatars (20 px) of circle members who pressed it.
- **Pressing**: the stamp fills `ink.100` with a `#000` glyph, translates 1 px down (impression) and its count types the new value; haptic `reaction.send`, sound `impress`; one reaction per chapter per profile (pressing another moves it; pressing the same one removes it).
- Reactions from gated or non-sharing profiles are not shown. Offline: queued and sent on reconnect, drawn immediately.
- **Spoiler guard.** A reaction is a verdict on what happens in a chapter, so on any chapter the viewer has **not finished** (no `completed` progress for this profile), reactions show only the reacting member's 20 px avatar and the line "reacted to Ch. 212" (`type.caption` `ink.45`), never the glyph, its name or the per-stamp counts; the stamps row itself shows the total only ("2 reactions"). This applies in every place reactions appear: the chapter-end credits of a chapter being read out of order, the feature page's schedule rows (tooltip and long-press list), the reader's `CIRCLE` panel (§8.14.12), Circle dispatches and the member page's "Their reactions" rail. When the viewer finishes the chapter, the guarded reactions **unseal**: the glyphs fade in (160 ms `ease.settle`, 40 ms apart), in the chapter-end credits and anywhere else visible at that moment. The viewer's own reaction is never guarded. The rule is applied by the client from the viewer's own progress (the server returns full reactions to anyone allowed to see them), so it also works offline.

#### 9.3.4 Recommend to ("Pass it on") and letters

- **Entry**: feature/book page `paper-plane-tilt`, Quick look `Recommend to…`, the reader's `CIRCLE` panel, the chapter-end credits (`Pass it on`).
- **Sheet**: kicker `PASS IT ON`, the series cover 48 × 72 + title; recipients as avatar toggles (only profiles with `Receive recommendations` on; for an 18+ series, only recipients whose gate is open **and** whose own `Include 18+ titles in my activity` is on are listed, so only profiles that chose to disclose 18+ appear; eligible recipients are listed without explanation, and nothing says that anyone is left out, §7.24); a note field in Newsreader Italic ("Add a line…", 140 characters, `12 / 140`); `Send` (primary). Haptic `recommend.send`; toast "Sent to Riya." With no eligible recipient (nobody has `Receive recommendations` on, or none can see and shares 18+ titles for this 18+ series), the recipients row is replaced by the line "Nobody is taking recommendations right now." and `Send` is disabled; `Done` closes. Offline: `Send` is disabled, captioned "Sending needs a connection." Failure: the toast "Couldn't send to Riya. Try again."; the sheet stays open and the note is kept.
- **Receiving**: a Letter card in Circle and a count on the Index row, the Index tab and the Circle sidebar item; Tonight's Also-in-this-issue may carry "Riya recommends Lookism". Actions `Read` (opens the series), `Add to library` (stamp), `Keep` (bookmark-simple; marks it read but keeps it in Tonight's `Sent to you` until dismissed; the state `kept` through `PATCH /circle/letters/{id} {state: "kept"}`), `Dismiss`. Reading a letter marks it read. A letter action that fails shows the toast "Couldn't update the letter." and the card restores.

#### 9.3.5 Shared shelves

- A collection's `Share` action (owner) opens a sheet: members as avatar toggles, a mode `CAN ADD │ VIEW ONLY`. A save that fails shows an inline `CORRECTION` "Couldn't update who can see this shelf." with `Try again`.
- Shared plates show `SHARED` and the members' avatars; the detail header lists "Shared with Riya, Arjun"; each member poster shows the adder's 20 px avatar at the bottom-left when others added it (from `added_by_profile_id`, §9.3.8).
- Members of a shared shelf see it in their own Collections under a `SHARED WITH YOU` section (`shared_with_me`, §9.3.8); its detail renders from the shelf's own `title`, `cover_url` and `ambient` per row, never from the member's library.
- 18+ members of a shared shelf are hidden from gated viewers (the count reflects what they can see).
- Leaving: `Leave shelf` in the overflow for non-owners.

#### 9.3.6 Settings → Circle & privacy

Rows: `Share what I'm reading` (master), `Show my reactions`, `Let others add me to shared shelves`, `Receive recommendations`, `Include 18+ titles in my activity` (only visible when this profile's gate is open), `Hide this series from my activity` list (series-level exclusions with add/remove), and `Clear my shared activity` (destructive; dialog "Clear everything you've shared? Others stop seeing your past activity. Your library isn't touched.", `Clear` destructive with the 1000 ms arm, §15.7; failure toast "Couldn't clear your activity."). A preview line types what others will see: "Others see: *Yash* finished chapter 142 of *Omniscient Reader*."

#### 9.3.7 Member page (`/circle/:profileId`)

Masthead with the member's 96 px avatar and name in `type.masthead` italic; deck "Reading 4 series · shares activity and reactions"; rails `Now reading`, `Recently finished`, `Their reactions`; shared shelves; `Recommend something to Riya` (secondary, opens a series search then the Pass-it-on sheet). Only what the member shares is shown. States: not sharing any more ("Riya isn't sharing right now."), loading, error, offline (notice `OFFLINE EDITION`, "The circle needs a connection.").

#### 9.3.8 Backend

Every Circle-derived figure below, and The Annual's `circle` overlaps, is computed at serve time from the shareable activity set S(member, viewer) of §9.3.1 only. New tables and endpoints (all `X-Profile-Id` scoped, gate on serve): `GET /circle/members` (each member carries `now` (the object in "Response shapes" below) or `null`; it is set when they read in the last 15 minutes and the viewer may see that series; for an 18+ series `now` is `null` unless the member's `Include 18+ titles in my activity` is on **and** the viewer's gate is open, enforced server-side, and the same rule applies to `GET /circle/series` readers), `GET /circle/feed?cursor`, `POST /circle/reactions {source_id, series_key, chapter_key, kind}` / `DELETE`, `GET /circle/reactions?source&series` (per-chapter counts and who), `POST /circle/letters {to_profile_ids, source_id, series_key, note}`, `GET /circle/letters`, `PATCH /circle/letters/{id}`, `PATCH /profiles/{id}/sharing {…switches, excluded_series}`, `POST /library/collections/{id}/share {profile_ids, mode}`, `DELETE /library/collections/{id}/share/{profile_id}`.

The screens also need:
- `GET /circle/members/{profile_id}` → `{profile, shares: {activity, reactions, shelves, recommendations}, now (the `GET /circle/members` shape, or `null`), reading: [series], finished: [series], reactions: [...], shelves: [...]}` for the member page (§9.3.7); `404 circle_member_not_sharing` renders "Riya isn't sharing right now."
- `GET /circle/feed?cursor&profile_id=&kind=reading|reaction` (member and tab filters). The filter maps onto the item `kind`s below: `reading` = `started | finished_chapter | finished_series`, `reaction` = `reacted`. Letters are not feed items; the `LETTERS` tab reads `GET /circle/letters`.
- `DELETE /circle/activity` → 204, which implements `Clear my shared activity` (§9.3.6).
- `GET /circle/series?source&series` → `{followers: [profile], readers: [{profile, chapter_key, chapter_number, last_read_at}]}`, applying each member's sharing switches, exclusions and Include-18+ switch and the viewer's gate. It feeds the feature page `CIRCLE` tab and the reader `CIRCLE` panel ("Riya is on Ch. 150").
- `DELETE /circle/reactions` takes the body `{source_id, series_key, chapter_key}`.
- Shared shelves: `GET /library/collections` rows gain `shared: {owner_profile_id, mode, member_profile_ids} | null` and the response gains `shared_with_me: [...]` (the `SHARED WITH YOU` section); `GET /library/collections/{id}` answers members too, and its `series` rows carry `title`, `cover_url` and `ambient`, because a member's library cannot join the owner's series; `POST /library/collections/{id}/series` is allowed for `can_add` members (`403 forbidden` otherwise); `DELETE /library/collections/{id}/share/me` implements `Leave shelf`.
- **Response shapes** (both clients render from these):
  - `GET /circle/members` → `[{profile_id, name, avatar_key, username, shares: {activity, reactions, shelves, recommendations}, now: {source_id, series_key, chapter_key, chapter_number, title, ambient, since} | null}]`.
  - `GET /circle/feed?cursor&limit=50` (plus the filters above) → `{items: [{id, kind: "started" | "finished_chapter" | "finished_series" | "reacted", actor: {profile_id, name, avatar_key, username}, source_id, series_key, title, cover_url, ambient, chapter_key?, chapter_number?, reaction?, created_at}], next_cursor}`.
  - `GET /circle/reactions?source&series` → `{chapters: [{chapter_key, counts: {loved, shook, laughed, tears, chefs_kiss}, by: [{profile_id, avatar_key, kind}]}]}`. The spoiler guard stays on the client (§9.3.3).
  - `GET /circle/letters` → `[{id, from: {profile_id, name, avatar_key, username}, source_id, series_key, title, cover_url, ambient, note, state: "new" | "read" | "kept" | "dismissed", created_at}]`.
  - `GET /profiles/{id}/sharing` → `{activity, reactions, shelves, recommendations, include_mature, excluded_series: [{source_id, series_key, title}]}`. It feeds the §9.3.6 rows; `PATCH /profiles/{id}/sharing` takes the same shape.
- **Adders.** `GET /library/collections/{id}` member rows gain `added_by_profile_id`, which draws the 20 px adder avatar of §9.3.5. `DELETE /library/collections/{id}/series/{…}` is authorised by role: the owner removes any series, a `can_add` member only the rows where `added_by_profile_id` is their own, and anyone else gets `403 forbidden` (the §8.11 permission table).
- **Polling.** `GET /circle/members` is polled every 60 s while Circle, Tonight's circle sections, a member page or a reader `CIRCLE` panel is visible, and paused in the background. The reading-now ring colour updates on each poll.
- **Race.** `POST /circle/letters` answers `409 recipient_unavailable` when a recipient turned `Receive recommendations` off after the sheet opened: the toast reads "Riya isn't taking recommendations any more." and that recipient is deselected.

---

### 9.4 Ambient reader extras

#### 9.4.1 Auto-scroll ("projection speed")

- **Where**: manga strip mode and novel scroll mode.
- **Start**: manga: the folio bar's auto-scroll button, `p`, the setup sheet's AMBIENT tab. Novels: the bottom bar's auto-scroll button, `a` (`p` is Listen there), the Type sheet's `AMBIENT` group (§8.15.5). In the novel reader auto-scroll and Listen are mutually exclusive (§8.15.5).
- **While running**: a floating square chip bottom-right (40 px tall, `paper.2` at 90 %, 1 px `rule.2`): `▸ 1.25×` with a 2 px `spot` rule along its bottom showing chapter progress; tap → pause / play; long-press → the speed ruler sheet.
- **Speed**: 0.50–3.00× in 0.05 steps. Manga: 1.00× = 60 px/s **at a 1080 px tall viewport**, scaled by `viewportHeight / 1080` so a screenful passes in the same time on a phone and a monitor (a 844 px phone at 1.00× scrolls 46.9 px/s). Novels: 1.00× = the profile's measured reading pace in words per minute (default 250 wpm). **Pace**: the median, over this profile's last 10 completed novel chapters, of `word_count / (time_spent_seconds / 60)`; only chapters with 60 ≤ `time_spent_seconds` ≤ 7200 and a pace of 80–900 wpm count, and the pace stays at 250 wpm until 3 samples exist. It is stored per profile on the client (web scoped `localStorage` `mm.novel-pace`; Flutter `mm.novel-pace.u{user}p{profile}`) and recomputed on each chapter completion. **Scroll speed**: `px/s = (pace_wpm × speed / 60) × lineHeightPx / avgWordsPerLine`, where `avgWordsPerLine` = the laid-out chapter's word count ÷ its rendered line count, recomputed after any Type sheet change. The speed ramps in over 400 ms (`dur.glide`) and never lurches; integration is elapsed-time based (web `requestAnimationFrame` delta, Flutter `Ticker` elapsed), so dropped frames never change the pace.
- **Pace by dialogue** (option, manga with dialogue text for this chapter from `GET /ocr/chapter`; setup sheet AMBIENT and Settings → Ambient, default off): the effective speed is `speed × clamp(1.2 − wordsOnScreen / 60, 0.5, 1.0)`, where `wordsOnScreen` counts the words of OCR boxes whose centres are inside the viewport, recomputed every 250 ms and eased to the new speed over 400 ms (`dur.glide`). So a screen with 12 words or fewer runs at full speed, one with 42 words at 0.5×, and a wordless splash page at full speed. The chip shows `▸ 1.25× · PACED` while it applies. Chapters without dialogue text run at the plain speed, and the option's caption says "Needs this chapter's dialogue. Scan it from Downloads." 
- **Interruption**: a touch pauses; release resumes after 800 ms when "Resume after I let go" is on; any manual scroll pauses; the chrome stays hidden.
- **Adjust on the fly**: right-edge vertical swipe with the HUD (phones); `<` / `>` (keyboard); the chip's long-press ruler.
- **Chapter boundaries**: in continuous mode auto-scroll rolls straight through seams and read-all dividers, pausing only at a next chapter that has not loaded yet (the §8.14.11 `Next chapter loading (strip)` band) and resuming when its pages land; at the series' end it stops with haptic `autoscroll.end` and the chrome returns.
- **Reduced motion**: never auto-starts; the user can start it manually.
- **Haptics**: `autoscroll.toggle` on play/pause, `autoscroll.step` per 0.25×.

#### 9.4.2 Soundscape ("house sound")

- **Loops** (8): Projector room (a soft hum with distant reel ticks), Rain on glass, Night city, Café, Night wind, Low drone, Afternoon park, Temple bells. Each a 90 s seamless loop, 48 kHz, OGG Vorbis 96 kbps (m4a/AAC on iOS), about 1 MB each, fetched on first use from `GET /app/soundscapes/{id}.{ogg|m4a}` (§15.5) and cached (web Cache Storage; app file cache). Sources, decided per loop: *Projector room*, *Low drone* and *Night wind* are synthesised with `sox` (brown noise through band-pass and slow tremolo; the projector's reel ticks are 4 ms clicks at 24 per second, low-passed at 2 kHz), so they carry no third-party licence; *Rain on glass*, *Night city*, *Café*, *Afternoon park* and *Temple bells* are cut from freesound.org recordings published under CC0 1.0 only (no CC-BY, no sampling-plus). Each file's origin (the freesound sound id and author, or the `sox` command line), edits and licence is recorded in `backend/media/soundscapes/SOURCES.md` when the file is added, and the About → Licenses page lists that file.
- **Picker** (the manga setup sheet's AMBIENT tab, the novel Type sheet's `AMBIENT` group, and Settings → Ambient): a list of the eight as rows (name in `type.title`, a one-line description in `type.caption`, a `Hear` button playing 5 s), plus `MATCH THE MOOD` (plays the loop of the first of the series' genres that the table below lists, falling back to the profile mood's default in §2.1.6) and `OFF`. Volume slider 0–100 % (default 40 %).
- **`MATCH THE MOOD`**: matching is case-insensitive; take the series' genres in order and use the first one that appears in this table.

  | Genres | Loop |
  |---|---|
  | Romance, Josei, Shoujo | Rain on glass |
  | Action, Martial Arts, Murim, Sports | Low drone |
  | Comedy, Slice of Life, School | Café |
  | Horror, Thriller, Mystery, Psychological | Night wind |
  | Fantasy, Isekai, Regression, Cultivation, Historical | Temple bells |
  | Drama, Crime, Sci-Fi | Night city |
  | Adventure, Seinen | Afternoon park |
  | No match | The profile mood's default (§2.1.6; `default` → Projector room) |

- **Picker descriptions** (`type.caption`, one line each):

  | Loop | Description |
  |---|---|
  | Projector room | "A soft hum with distant reel ticks." |
  | Rain on glass | "Steady rain on a window." |
  | Night city | "Distant traffic after dark." |
  | Café | "Low voices and cups." |
  | Night wind | "Wind across an empty street." |
  | Low drone | "A deep, even hum." |
  | Afternoon park | "Birds and far-off voices." |
  | Temple bells | "Slow bells over a quiet courtyard." |
- **Playback**: fades in over 2000 ms when a reader opens with a soundscape set, out over 600 ms on leaving the reader or pausing the app. Ducks to 30 % while Listen narration plays (or pauses if the user prefers: switch "Pause the soundscape during narration"). UI sounds are suppressed while it plays. Web: Web Audio `AudioBufferSourceNode` with `loop = true` through a `GainNode`; Flutter: a second `just_audio` player (`LoopMode.one`, already installed, `handleAudioSessionActivation: false`) under the audio session and focus policy of §6; it mixes with other audio at its own volume, never ducking or stopping it (a focus-less ambient player receives no interruption to stop on).
- **Formats**: on the web a soundscape is requested as `.ogg` when `new Audio().canPlayType('audio/ogg; codecs="vorbis"')` is non-empty, otherwise `.m4a` (the loops are Ogg Vorbis, and `decodeAudioData` needs a decodable file). Narration and voice samples on the web keep the existing Ogg Opus probe, `pickNovelAudioFormat` in `frontend/src/features/novels/audio-url.ts`. The app requests `m4a` for iOS narration and the iOS soundscape (`just_audio`), and always `ogg` for SoLoud voice samples (§8.16.5).
- **Audio session**: the soundscape runs in State A when no narration is active and under State B while it is (§6 audio session and focus policy).
- **Indicator**: a 16 px `waveform` glyph while a soundscape plays. Manga running head (§8.14.3): it follows the chapter folio's `caret-down` inside the title group, with its own 44 (iOS, web) / 48 (Android) hit, and is not one of the four trailing buttons; a tap opens Reading setup at `AMBIENT`. Novel top bar (§8.15.3): in its title area; a tap opens the Type sheet's `AMBIENT` group.

#### 9.4.3 Panel-by-panel guided view

- **What**: the camera moves from panel to panel, like a guided comic view, for readers who want one beat at a time.
- **Detection (on the client; sign-off S11, §15.10).** A reader-engine duty beside page tint (§15.4), so the shared VPS image proxy never decodes or analyses pages, and downloaded chapters get guided view offline. Web: the page-tint Web Worker also receives the page's `ImageBitmap` scaled to 360 px wide on an `OffscreenCanvas`. Flutter: a `compute()` isolate on `ResizeImage(provider, width: 360)` raw RGBA. Analysis runs one page ahead of the reading position. Panels are `{x, y, w, h}` in page fractions, in reading order.
- **Rule** (identical on both clients): (1) compute luminance per pixel; (2) a row or column is a **gutter line** when at least 98 % of its pixels have L > 0.92, or at least 98 % have L < 0.06; (3) a **gutter** is a run of at least 12 gutter lines (at 360 px width); (4) split the page into horizontal bands at the gutters, then split each band once at vertical gutters; (5) drop rects under 48 px on either side; (6) pages with height/width > 2 (webtoon strip images) split on horizontal gutters only; (7) reading order is top to bottom, then left to right, or right to left when the series direction is RTL.
- **Parity.** 24 small greyscale PNG fixtures in `design/panel-vectors/` with their expected rects in `design/panel-vectors.json`, run by `panels.test.ts` and `panels_test.dart`; a rule change that does not update the vectors fails both suites.
- **Cache.** On chapter exit the client posts `POST /reader/panels {source_id, series_key, chapter_key, pages: [{page, panels}]}` (fire and forget, skipped offline), stored per page ETag; later manifests carry `pages[].panels`, which the engine uses before analysing. The proxy does no image work. Downloaded chapters store their panels in the local manifest copy.
- **Entry**: setup sheet `LAYOUT → GUIDED`, the `u` key, a `panel-focus` button in the running head once the current page has panels (from the manifest or from analysis).
- **Presentation**: the viewport shows one panel scaled to fit within 24 px margins, the rest of the page dimmed to 15 % (a `color.matte.guided` matte, black at 85 %); the panel folio `PANEL 3 / 7 · PAGE 18` at the bottom-left in `type.folio`; the running head and folio bar behave as in paged mode.
- **Moving**: tap the right 30 % / swipe left / `→` / `j` → next panel; the left 30 % → previous; the centre 40 % toggles the chrome (mirrored for RTL); the camera **dollies** (translate + scale) between panels over 520 ms `dur.rack` `turn` (§4.5 Dolly); at a page's last panel, next cuts to the next page's first panel (Cut, `page.turn` haptic); double tap shows the whole page for 1.5 s (`dur.hold.glance`; a 320 ms `dur.column` zoom out) then returns; pinch overrides the camera until released.
- **Auto-advance** (option "Guided view auto-advance", default off; also on whenever auto-scroll is started in guided view): each panel holds, then the camera moves on. With `PACE BY WORDS` (default when the chapter has dialogue text) the hold is **1.2 s + 0.25 s per OCR word in the panel, capped at 6 s** (`dur.hold.panel.*`; words = boxes whose centres fall inside the panel rect): a wordless panel holds 1.2 s, a 10-word panel 3.7 s, a 20-word panel 6 s. With `FIXED`, or when the chapter has no dialogue text, every panel holds the fixed time (2–10 s, default 3.5 s). A 2 px `spot` hold rule under the `PANEL 3 / 7` folio fills over the hold (`ease.linear`). A touch, a key or a manual move pauses auto-advance; `p` or the chip resumes it.
- **Webtoon strips**: panels are detected along the strip's horizontal gutters; tall panels scroll inside the camera at the auto-scroll speed when auto-scroll is on.
- **States**: analysing the current page (the page shows whole with the folio `PAGE 18 · FINDING PANELS` on the folio-flag ground, §2.1.4); no panels found or analysis failed on a page (the page shows whole with the folio `PAGE 18 · WHOLE PAGE` on the folio-flag ground, §2.1.4, and next moves to the next page); offline (works from the saved copy, analysing local blobs when no panels were stored); reduced motion (cuts instead of dollies).
- Haptic `page.turn` per panel.

#### 9.4.4 Page-tinted chrome

- **Source**: the client samples the page itself (the primary path, §2.1.5: a 16 × 16 `OffscreenCanvas` in a Web Worker on the web, a 16 × 16 `ResizeImage` decode through the same picker on Flutter); a manifest `pages[].tint` from an earlier read is used first when present. Greyscale pages keep the previous colour; after 6 greyscale pages in a row the chrome dissolves to the series cover's `ambient` colours.
- **Sampling**: the page under the reading line, 38 % from the top of the viewport (paged and guided view: the current page), at most one sample per `dur.sample.tint` (600 ms).
- **Applied to**: the end colour of `scrim.head` and `scrim.sole` (mix 25 % tint into `#000`; web `--scrim-base` on the reader chrome root, Flutter the `tint` argument of `scrimHead` / `scrimSole`, §2.8.3), the ruler's played part (the tint lifted to L 0.75, ≥ 4.5:1 on black), the micro progress rule, the desktop gutters around the strip (tint at L 0.06), and the setup sheet's top rule.
- **Motion**: every change dissolves over 800 ms `turn` via the registered CSS properties or `TweenAnimationBuilder`; reduced motion swaps at most once every 2 s without a fade.
- **Toggle**: setup sheet AMBIENT tab and Settings → Ambient (default on). Interactive marks elsewhere keep `spot`.

#### 9.4.5 Entry points and states summary

| Extra | Entry | Off / unavailable state |
|---|---|---|
| Auto-scroll | manga: folio bar button, `p`, setup sheet; novels: bottom bar button, `a`, Type sheet `AMBIENT` group | paged modes: the button is absent (tooltip in the sheet: "Auto-scroll needs the strip." / "Auto-scroll needs the scroll layout."); novels while Listen plays: paused, chip `PAUSED FOR LISTEN` |
| Soundscape | manga setup sheet, novel Type sheet, Settings → Ambient, `waveform` indicator in both readers | not downloaded yet: `Hear` shows a leader while fetching; offline and not cached: "Available when you're online." |
| Guided view | setup sheet, `u`, running-head button | finding panels / whole page as above |
| Page tint | setup sheet, Settings → Ambient | first view of a new page: sampled on decode, so the chrome tints within one sample (≤ 600 ms); greyscale page: previous colour kept; six greyscale pages: the cover's `ambient` colours; sampling failed (image not decodable in the worker): the cover's colours |

---

## 10. The two required signature animations

### 10.1 Heading reveal: per letter, fade + slide up + un-blur, staggered

#### 10.1.1 Spec

| Property | Value |
|---|---|
| Split | Graphemes (web `Intl.Segmenter(undefined, { granularity: "grapheme" })`; Flutter `String.characters`); words grouped `white-space: nowrap` so lines break only between words |
| From | opacity 0, translateY +0.42em, blur 8 px |
| To | opacity 1, translateY 0, blur 0 |
| Duration | 640 ms for opacity and y; **440 ms** for blur, so each letter is sharp before it settles (the Didone hairlines arrive last) |
| Easing | `ease.settle` `cubic-bezier(0.16, 1, 0.3, 1)` |
| Stagger | 24 ms per grapheme, total stagger capped at 560 ms: `step = min(24, 560 / (n − 1))`, `n` = graphemes excluding spaces. "Library" (7) ends at 784 ms; a 40-grapheme title at 1200 ms. |
| Rule | The section rule above an H3 draws 120 ms before the first letter (Rule draw, 480 ms) |
| Trigger | The `trigger` prop on `SetHeading`. `"inView"` (H3 section heads): when 50 % in view, once per session per heading key (a module-level `Set` on web; a Riverpod `StateProvider<Set<String>>` in Flutter). `"mount"` (page mastheads): on first mount, once per session, same seen set. `"signal"` (cover, feature, book, recap and other takeover titles): every mount, never reading or writing the seen set, starting when `play` turns true. Web: `play` turns true 480 ms (`dur.spread`, the match cut) after the route commits when the navigation carried a match cut, otherwise 160 ms after first paint (`useTitleSignal`). Flutter: the heading listens to `ModalRoute.of(context)!.animation` and plays on `AnimationStatus.completed`, or 160 ms after the first frame when there is no route animation. A heading that leaves the viewport mid-reveal jumps to its end state. The reveal is per letter at every length: there is no letter cap (the stagger is already capped at 560 ms and blur layers drop below 0.05 σ). |
| Responsive size | The heading roles' fluid sizes (§3.2: `clamp()` on web, the breakpoint table in Flutter) |
| Text scale | Flutter passes `textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: cap)` (the role's §3.3 cap) to the whole `Text` and to every letter `Text`, and the rise is `0.42 × scaler.scale(fontSize)`; the web scales with the root font size |
| Long words | Each word sits in a non-wrapping box, so before revealing, the longest word is measured at the resolved size (Flutter `TextPainter` inside a `LayoutBuilder`; web a hidden span measured once and re-checked on a `ResizeObserver` on the container). If it is wider than the available width, the plain whole string renders instead of the letter reveal, with normal wrapping (`overflow-wrap: anywhere`; `softWrap: true`) and the reduced-motion 200 ms fade. Test: "Transmigration" in `type.cover` at text scale 2.0 in a 358 px column (390 − 2 × 16 gutters) must not overflow |
| Tracking | Tight: section −0.020em, masthead −0.035em, cover −0.040em, headline −0.030em |
| Kerning | Off on revealed text (`font-kerning: none`, `FontFeature.disable('kern')`), so split and unsplit text are identical and nothing shifts at the end |
| Accessibility | The container carries the full text (`aria-label`, `Semantics(label:)`); letter spans are `aria-hidden` / `excludeSemantics`. It is a heading in every branch: web `h1`–`h3` through `as`; Flutter `Semantics(header: true, headingLevel: level)` with `level` 1 (masthead), 2 (`type.section` head) or 3 (subsection) |
| Reduced motion | The whole string fades in over 200 ms; no y, no blur, no stagger |

#### 10.1.2 Where it plays (exhaustive)

- **H3 section heads**: every rail and section header (every Tonight section, Library's Continue, Picks, The Numbers blocks, Circle tabs' section heads, feature page sections, Discover idle sections, Settings section headers on desktop).
- **Mastheads**: every page title (Library, Updates, Collections, History, Bookmarks, Discover's kicker line, Sources, source catalogue name, Downloads, Dialogue, Picks, The Numbers, Circle, Index, Settings, System status).
- **Hero and cover titles**: Tonight's cover series title in the credits kicker line, feature page and book page titles, Annual page titles and the colophon's closing "See you in 2027.", `PREVIOUSLY ON` and the recap's series title, `End of chapter 142` in the credits, the Listen full player's series title, the streak milestone card's kicker and headline ("Thirty days in a row.").
- **Brand**: the masthead in the logo reveal (§12.4). (Stop the press cuts the masthead in without a reveal, §8.30.3, because the incoming splash is the reveal.)

#### 10.1.3 Not used on

Body text, captions, buttons, list rows, toasts, anything inside the manga strip or the novel page body, anything repeated in a list.

#### 10.1.4 Smooth colour on hover and state

- **Hover** (linked headings: an H3 with `See all`, a series title that links to its feature page, sidebar-linked mastheads): letters wipe from `ink.100` to `spot` left → right: each letter's `color` transitions 200 ms `set` with `transition-delay: calc(var(--i) * 10ms)`. On leave, all letters return together in 160 ms (no delay). Flutter: a `MouseRegion` drives one `AnimationController` of `200 + 10 × (n − 1)` ms; letter `i` lerps `ink.100` → `spot` over `Interval(10i / total, (10i + 200) / total, curve: CineCurves.set)`; on exit all letters return together over 160 ms (a second 160 ms controller scales every letter's lerp to 0), §10.1.6.
- **State**: when keyboard focus is inside a rail, its H3 is `ink.100` and its folio turns `spot` (160 ms); when a section is empty, its H3 renders in `ink.45`.
- **Colour transitions never re-run the reveal.**

#### 10.1.5 Web implementation (Motion 13.4.4)

```tsx
"use client";
import { useEffect, useLayoutEffect, useRef, useState } from "react";
import { motion, stagger, useInView, useReducedMotion, type Variants } from "motion/react";

const seg = new Intl.Segmenter(undefined, { granularity: "grapheme" });
const graphemes = (s: string) => Array.from(seg.segment(s), (x) => x.segment);
const settle = [0.16, 1, 0.3, 1] as const;
const seen = new Set<string>();
// §10.1.1: "inView" H3s, "mount" mastheads, "signal" cover, feature, book and takeover titles
export type SetTrigger = "inView" | "mount" | "signal";

const parent: Variants = {
  hidden: {},
  show: (n: number) => ({ transition: { delayChildren: stagger(Math.min(0.024, 0.56 / Math.max(1, n - 1)), { startDelay: 0.12 }) } }),
};
const letter: Variants = {
  hidden: { opacity: 0, y: "0.42em", filter: "blur(8px)" },
  show: { opacity: 1, y: 0, filter: "blur(0px)",
          transition: { duration: 0.64, ease: settle, filter: { duration: 0.44, ease: settle } } },
};

// `play` for trigger "signal": true 480 ms (`dur.spread`, the match cut) after the route commits
// when the navigation carried a match cut, otherwise 160 ms after first paint.
export function useTitleSignal(matchCut: boolean) {
  const [play, setPlay] = useState(false);
  useEffect(() => {
    const t = setTimeout(() => setPlay(true), matchCut ? 480 : 160);
    return () => clearTimeout(t);
  }, [matchCut]);
  return play;
}

// §10.1.1 Long words: false when any word is wider than the heading's container at the resolved size.
// Measured with a hidden span, re-checked on a ResizeObserver (fluid sizes change with the viewport).
// `ref.current` is read on every check, never captured: SetHeading renders plain <Tag> at "done", so React
// replaces the heading node after each reveal, and a captured node would be detached (offsetWidth 0, fits true).
function useWordsFit(ref: React.RefObject<HTMLElement | null>, text: string) {
  const [fits, setFits] = useState(true);
  useLayoutEffect(() => {
    const box = ref.current?.parentElement; // the parent survives the node swap; it is what the observer watches
    if (!box) return;
    const probe = document.createElement("span");
    probe.setAttribute("aria-hidden", "true");
    probe.style.cssText = "position:absolute;visibility:hidden;white-space:nowrap;font:inherit;letter-spacing:inherit";
    const check = () => {
      const el = ref.current;
      if (!el) return;
      el.appendChild(probe);
      const widest = Math.max(...text.split(" ").map((w) => { probe.textContent = w; return probe.offsetWidth; }));
      probe.remove();
      setFits(widest <= box.clientWidth);
    };
    check();
    const ro = new ResizeObserver(check);
    ro.observe(box);
    return () => ro.disconnect();
  }, [ref, text]);
  return fits;
}

export function SetHeading({ text, id, as: Tag = "h2", className, trigger = "inView", play = false }:
  { text: string; id: string; as?: "h1" | "h2" | "h3"; className?: string; trigger?: SetTrigger; play?: boolean }) {
  const reduce = useReducedMotion();
  const ref = useRef<HTMLHeadingElement>(null);
  const signal = trigger === "signal";
  const [once] = useState(() => !signal && seen.has(id)); // read once at mount; "signal" never reads or writes `seen`
  const [phase, setPhase] = useState<"idle" | "run" | "done">(once ? "done" : "idle");
  const half = useInView(ref, { amount: 0.5 });
  const any = useInView(ref);
  const fits = useWordsFit(ref, text);
  const wasIn = useRef(false);
  const go = trigger === "inView" ? half : trigger === "mount" || play;
  useEffect(() => {
    if (any) wasIn.current = true;
    if (go && phase === "idle") setPhase("run");
    else if (phase === "run" && wasIn.current && !any) setPhase("done"); // left the viewport mid-reveal: jump to the end (§4.7)
  }, [go, any, phase]);
  useEffect(() => { if (phase === "done" && !signal) seen.add(id); }, [phase, signal, id]);
  const M = motion[Tag];
  const words = text.split(" ");
  const n = graphemes(text.replaceAll(" ", "")).length; // spaces excluded: the same n as Flutter (§10.1.1)
  let i = 0;
  // Letter spans in every state, so the hover wipe (§10.1.4) also works on a revealed or reduced-motion heading.
  const spans = (animated: boolean) => words.map((w, wi) => (
    <span key={wi} aria-hidden className="inline-block whitespace-nowrap">
      {graphemes(w).map((c) => {
        const k = i++;
        return animated
          ? <motion.span key={k} variants={letter} className="set-letter inline-block" style={{ ["--i" as string]: k }}>{c}</motion.span>
          : <span key={k} className="set-letter inline-block" style={{ ["--i" as string]: k }}>{c}</span>;
      })}
      {wi < words.length - 1 && " "}
    </span>
  ));
  if (!fits) return <M ref={ref} aria-label={text} className={className} style={{ overflowWrap: "anywhere" }} initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.2 }}>{text}</M>; // §10.1.1 Long words
  if (reduce) return <M ref={ref} aria-label={text} className={className} initial={{ opacity: 0 }} whileInView={{ opacity: 1 }} viewport={{ once: true }} transition={{ duration: 0.2 }}>{spans(false)}</M>;
  if (phase === "done") return <Tag ref={ref} aria-label={text} className={className} style={{ fontKerning: "none" }}>{spans(false)}</Tag>;
  return (
    <M ref={ref} aria-label={text} className={className} style={{ fontKerning: "none" }}
       initial="hidden" animate={phase === "run" ? "show" : "hidden"}
       onAnimationComplete={(def) => def === "show" && setPhase("done")}
       variants={parent} custom={n}>
      {spans(true)}
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

#### 10.1.6 Flutter implementation (no package: one `AnimationController` per heading)

Five rules the code must keep: the "seen" set is **read once at mount** and written only when the reveal **finishes** (writing it during build would rebuild the widget into its static branch one frame later and cancel the reveal), and it is never read or written for `SetTrigger.signal` (cover, feature, book and takeover titles, so they reveal on every mount, §10.1.1); the start follows the **trigger**: `inView` starts **when half the heading is on screen**, not when a sliver builds it (slivers build up to `cacheExtent` ahead of the viewport), `mount` after the first frame, and `signal` when the route's animation completes (or 160 ms after the first frame without one), and every trigger jumps to its end if the heading leaves the viewport mid-reveal; the reveal is **per letter at every length** (no cap, no word fallback) with `n` = graphemes excluding spaces on both clients; and the rise is **0.42 em in pixels** (`0.42 × scaler.scale(fontSize)`), not a fraction of the glyph box. Every branch (seen, reduced, animating) is wrapped in `Semantics(header: true, headingLevel: level)`, every `Text` (the whole string and each letter) takes the role's clamped `textScaler`, and a word wider than the line falls back to the plain wrapping string (§10.1.1 Long words). The web component (§10.1.5) keeps the same rules: `"signal"` skips `seen`, an `idle → run → done` phase driven by the trigger and two `useInView` observers (fully out of view mid-run, after having been in view, jumps to the static end state), and the same count (`graphemes(text.replaceAll(" ", "")).length`). Linked headings (`linked: true` in Flutter; a link ancestor on the web) keep their letters split after the reveal so the hover wipe of §10.1.4 works.

```dart
enum SetTrigger { inView, mount, signal } // §10.1.1: H3s, mastheads, cover/feature/book/takeover titles

class SetHeading extends ConsumerStatefulWidget {
  const SetHeading(this.text, {super.key, required this.id, required this.style, required this.cap,
      required this.level, this.trigger = SetTrigger.inView, this.linked = false});
  final String text; final String id; final TextStyle style;
  final double cap; // the role's §3.3 text-scale cap (`CineTextRole.cap`)
  final int level; // 1 masthead, 2 `type.section` head, 3 subsection (§14.5)
  final SetTrigger trigger; // signal: `seenHeadingsProvider` is neither read nor written
  final bool linked; // hover wipe ink.100 → spot (§10.1.4)
  @override
  ConsumerState<SetHeading> createState() => _SetHeadingState();
}

class _SetHeadingState extends ConsumerState<SetHeading> with TickerProviderStateMixin {
  late final bool _signal = widget.trigger == SetTrigger.signal;
  late final bool _seenAtMount = !_signal && ref.read(seenHeadingsProvider).contains(widget.id);
  late final int _n = widget.text.characters.where((c) => c != ' ').length; // spaces excluded, as on the web
  late final double _step = _n < 2 ? 0 : math.min(24.0, 560 / (_n - 1));
  late final AnimationController _c = AnimationController(vsync: this,
      duration: Duration(milliseconds: (120 + _step * math.max(0, _n - 1) + 640).round()));
  late final AnimationController _hover = AnimationController(vsync: this,
      duration: Duration(milliseconds: 200 + 10 * math.max(0, _n - 1)));
  late final AnimationController _out = AnimationController(vsync: this, duration: const Duration(milliseconds: 160));
  ScrollPosition? _pos;
  Animation<double>? _route;
  bool _armed = false;
  double _screenH = 0;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    _out.addStatusListener((s) { if (s == AnimationStatus.completed) { _hover.value = 0; _out.value = 0; } });
    if (_seenAtMount) { _c.value = 1; return; }
    _c.addStatusListener((s) {
      if (s != AnimationStatus.completed) return;
      _pos?.removeListener(_check);
      if (!_signal) ref.read(seenHeadingsProvider.notifier).update((set) => {...set, widget.id});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.trigger == SetTrigger.mount) _c.forward(); else _check();
    });
  }

  void _onRoute(AnimationStatus s) { if (s == AnimationStatus.completed && mounted) _c.forward(); }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenH = MediaQuery.sizeOf(context).height;
    _reduced = CineMotion.reduced(context);
    if (_reduced && !_c.isAnimating) _c.duration = const Duration(milliseconds: 200);
    if (_seenAtMount) return;
    if (_signal && !_armed) { // plays when the route's push (the match cut) completes, else 160 ms after the first frame
      _armed = true;
      final r = ModalRoute.of(context)?.animation;
      if (r == null || r.isCompleted) {
        WidgetsBinding.instance.addPostFrameCallback((_) =>
            Future.delayed(const Duration(milliseconds: 160), () { if (mounted) _c.forward(); }));
      } else {
        (_route = r).addStatusListener(_onRoute);
      }
    }
    _pos?.removeListener(_check);
    _pos = Scrollable.maybeOf(context)?.position;
    _pos?.addListener(_check);
  }

  void _check() {
    if (!mounted || _c.isCompleted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return;
    final top = box.localToGlobal(Offset.zero).dy, h = box.size.height;
    final visible = (math.min(top + h, _screenH) - math.max(top, 0.0)).clamp(0.0, h);
    if (widget.trigger == SetTrigger.inView && !_c.isAnimating && visible >= h * 0.5) _c.forward();
    if (_c.isAnimating && visible == 0) _c.value = 1; // left the viewport mid-reveal: jump to the end (§4.7)
  }

  @override
  void dispose() {
    _pos?.removeListener(_check); _route?.removeStatusListener(_onRoute);
    _c.dispose(); _hover.dispose(); _out.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.style.copyWith(fontFeatures: const [FontFeature.disable('kern')]);
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: widget.cap); // §3.3 role cap, letters included
    Widget head(Widget child) => Semantics(header: true, headingLevel: widget.level,
        label: widget.text, excludeSemantics: true, child: child); // every branch is a heading (§14.5)
    final plain = Text(widget.text, style: s, textScaler: scaler, softWrap: true);
    final whole = head(plain);
    if (!widget.linked && _seenAtMount) return whole;
    if (_reduced) return FadeTransition(opacity: _c, child: whole);
    final total = _c.duration!.inMilliseconds.toDouble(), wipeTotal = _hover.duration!.inMilliseconds.toDouble();
    final rise = 0.42 * scaler.scale(s.fontSize!);
    final ink = s.color ?? DefaultTextStyle.of(context).style.color!;
    var i = 0;
    Widget letter(String ch) {
      final k = i++, start = 120.0 + _step * k;
      final main = Interval(start / total, math.min(1, (start + 640) / total), curve: CineCurves.settle);
      final sharp = Interval(start / total, math.min(1, (start + 440) / total), curve: CineCurves.settle);
      final wipe = Interval(10 * k / wipeTotal, math.min(1, (10 * k + 200) / wipeTotal), curve: CineCurves.set);
      return AnimatedBuilder(animation: Listenable.merge([_c, _hover, _out]), builder: (_, __) {
        final t = main.transform(_c.value), b = 8 * (1 - sharp.transform(_c.value));
        final child = Text(ch, textScaler: scaler, style: s.copyWith(
            color: Color.lerp(ink, CineColors.spot, wipe.transform(_hover.value) * (1 - _out.value))));
        return Opacity(opacity: t, child: Transform.translate(offset: Offset(0, rise * (1 - t)),
          child: b < 0.05 ? child : ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: b, sigmaY: b), child: child)));
      });
    }
    final words = widget.text.split(' ');
    final dir = Directionality.of(context);
    final body = head(LayoutBuilder(builder: (context, box) {
      // Long words (§10.1.1): a word wider than the line cannot break inside its nowrap Row, so the
      // plain string wraps normally and fades in over 200 ms instead of revealing per letter.
      final widest = words.map((w) => _width(w, s, scaler, dir)).fold(0.0, math.max);
      if (widest > box.maxWidth) {
        // drive(), not a CurvedAnimation: that would add an undisposed status listener to _c on every build
        return FadeTransition(opacity: _c.drive(CurveTween(curve: Interval(0, math.min(1, 200 / total)))), child: plain);
      }
      i = 0;
      return Wrap(children: [
        for (var w = 0; w < words.length; w++)
          Row(mainAxisSize: MainAxisSize.min, children: [
            for (final ch in words[w].characters) letter(ch),
            if (w < words.length - 1) Text(' ', style: s, textScaler: scaler),
          ]),
      ]);
    }));
    if (!widget.linked) return body;
    return MouseRegion( // enter: letters wipe left → right; exit: all return together over 160 ms
      onEnter: (_) { _out.value = 0; _hover.forward(from: 0); },
      onExit: (_) => _out.forward(from: 0),
      child: body);
  }

  static double _width(String word, TextStyle s, TextScaler scaler, TextDirection dir) {
    final p = TextPainter(text: TextSpan(text: word, style: s), textScaler: scaler, textDirection: dir, maxLines: 1)..layout();
    final w = p.width;
    p.dispose();
    return w;
  }
}
```

Each letter's blur is one `ImageFiltered` layer for at most 1.2 s, dropped once it is under 0.05 σ; acceptable under the flagship-only rule. `CineCurves.settle` is generated into `tokens.g.dart`; `seenHeadingsProvider` is the `StateProvider<Set<String>>` of §10.1.1. **Test** (`mobile/test/skins/cinematic/set_heading_test.dart`): pump "Library" at the top of a `ListView`, advance 200 ms and assert the first letter's `Opacity.opacity` is strictly between 0 and 1 and the last letter's is 0; advance to 1,300 ms and assert every letter is at 1 and `seenHeadingsProvider` contains the id; rebuild and assert the static `Text` path. A second case places the heading 3,000 px down the list and asserts nothing starts until it is scrolled half into view. A third pushes a route holding a `SetTrigger.signal` heading and asserts every letter is at 0 until the push animation completes. A fourth asserts the heading semantics in every branch (animating, reduced, seen): `expect(tester.getSemantics(find.byType(SetHeading)), containsSemantics(isHeader: true, label: 'Library'))` (`containsSemantics`, not `matchesSemantics`, because the strict matcher fails on the other flags present). A fifth pumps "Transmigration" in `type.cover` at text scale 2.0 in a 358 px column (390 − 2 × 16 gutters) and asserts no overflow (`tester.takeException()` is null); it does not assert which path rendered, because whether the word fits at 358 px depends on the loaded font. A sixth pumps the same heading in a 160 px column, which no face can fit it in, and asserts the plain-string fallback rendered (`find.byType(Wrap)` finds nothing, `find.text('Transmigration')` finds one) with no overflow.

### 10.2 Main headline typing reveal: one character every 50 ms

#### 10.2.1 Spec

| Property | Value |
|---|---|
| Rate | Exactly one grapheme per 50 ms, spaces included, no pauses at punctuation |
| Clock | Timestamp-based (`floor(elapsed / 50)`), so dropped frames never slow it |
| Layout | The full string is laid out from frame 0; unrevealed graphemes are `transparent`, so lines never reflow |
| Caret | A `spot` bar 0.12em wide × 0.86em tall (a text cursor, square ends), zero layout width, sitting after the last revealed grapheme; solid while typing; when done it blinks off, on, off, on, off, on in 530 ms halves (3180 ms), then fades 1 → 0 over 160 ms, so the fade is always visible |
| Skip | Tap, click, `Enter` or `Space` on the headline completes it instantly |
| Length | Headlines only, ≤ 60 graphemes (≤ 3 s). Longer AI prose streams by word (§4.6) |
| Accessibility | The full text is in the accessibility tree from the start; the visual layer is hidden from it. The element is a heading only where the typed line is the page's only title (`as` on the web, `level` in Flutter; §10.2.3) |
| Reduced motion | Full text at once, no caret |
| Sound | None per character (no typewriter clacks) |

#### 10.2.2 Where it plays (exhaustive)

- **The main headline**: Tonight's cover story headline (once per day per profile; later visits show it at rest), including its streak-at-risk variant ("Twelve days and counting. One chapter keeps it alive."), which types once more when it first applies after 20:00.
- Profile picker question ("Who's reading tonight?").
- Login and Register headlines; Setup's "Where is your library?".
- Onboarding step headlines and "Printing issue No. 1…".
- Notice headlines (every empty, error, offline and caution state).
- The next-chapter caption in the manga reader after a pull commit, and the Listen post-play card's chapter title.
- `Previously on`'s loading line ("Writing the recap…") and the Picks thinking line ("Reading your shelf…").
- The Numbers' and The Annual's key numerals; the clock chart's summary line.
- Source catalogue loading tips.
- The index field placeholders (Discover, Dialogue, Picks examples) while empty and unfocused, as an `aria-hidden` visual layer driven by `useTyped` / the same `Ticker`, never a `TypedHeadline` (§7.4).
- New chapter folios on Updates after a check.
- Tonight's `Sent to you` note under its H3 ("Riya: you'll love the tower arc.").
- The streak milestone card's numeral (`30`).
- The Circle letter's sender kicker when it unfolds (§9.3.2, §13 moment 15).
- The Circle & privacy preview line (§9.3.6).
- A reaction stamp's count when it changes (§9.3.3).
- The recap countdown's folio is **not** typed (it counts).
- The 404 headline; System status's summary headline.

#### 10.2.3 Web implementation

Skipping must stop the clock, not just jump the count: `skip()` sets a `skipped` ref that the frame loop checks and cancels the pending `requestAnimationFrame`, otherwise the next tick would set the count back to `floor(elapsed / 50)` and the headline would keep typing after one complete frame.

```tsx
export function useTyped(text: string, ms = 50) {
  const chars = useMemo(() => graphemes(text), [text]);
  const reduce = useReducedMotion();
  const [n, setN] = useState(reduce ? chars.length : 0);
  const raf = useRef(0);
  const skipped = useRef(false);
  useEffect(() => {
    skipped.current = false;
    if (reduce) { setN(chars.length); return; }
    setN(0);
    const t0 = performance.now();
    const tick = (t: number) => {
      if (skipped.current) return;
      const k = Math.min(chars.length, Math.floor((t - t0) / ms));
      setN(k); if (k < chars.length) raf.current = requestAnimationFrame(tick);
    };
    raf.current = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf.current);
  }, [chars, ms, reduce]);
  const skip = useCallback(() => {
    skipped.current = true; cancelAnimationFrame(raf.current); setN(chars.length);
  }, [chars]);
  return { shown: chars.slice(0, n).join(""), rest: chars.slice(n).join(""), done: n === chars.length, skip };
}

export function TypedHeadline({ text, className, skipRef, as: Tag = "p" }:
  { text: string; className?: string; skipRef?: React.MutableRefObject<(() => void) | null>;
    as?: "h1" | "h2" | "h3" | "p" | "span" }) {
  const { shown, rest, done, skip } = useTyped(text);
  useEffect(() => { if (skipRef) skipRef.current = done ? null : skip; }, [done, skip, skipRef]);
  return (
    <Tag className={className} onClick={skip} tabIndex={done ? -1 : 0}
        onKeyDown={(e) => { if (!done && (e.key === "Enter" || e.key === " ")) { e.preventDefault(); skip(); } }}>
      <span className="sr-only">{text}</span>
      <span aria-hidden>{shown}</span>
      <span aria-hidden className="relative inline-block w-0 align-baseline">
        <span className={`absolute bottom-[0.06em] left-[0.04em] h-[0.86em] w-[0.12em] bg-spot ${done ? "animate-caret-out" : ""}`} />
      </span>
      <span aria-hidden className="text-transparent">{rest}</span>
    </Tag>
  );
}
```

The headline is a tab stop only while it types (`tabIndex={0}`, back to `-1` once done, so it keeps receiving focus on route change, §14.4), so Tab reaches it and `Enter` or `Space` completes it. Tonight also registers `Enter` in the key registry (§8.8 keys) to call the cover headline's `skipRef.current` while it is non-null, so the skip works without focusing the headline.

**Heading level** (`as`, default `"p"`; the full text reaches assistive tech through the `sr-only` span, which works on every element, where `aria-label` on a `p` or `span` would be ignored). `h1` only where the typed line is the page's only title: Tonight's cover headline, the picker question, the Login, Register and Setup headlines, onboarding step headlines, the 404 headline, and a §8.0.10 notice that replaces a whole page. Other notice headlines are `h2`, including System status's summary headline (its masthead "System status" is the h1). Numerals, folios, tips, captions, loading lines and next-chapter captions are `span` or `p`. Discover and Dialogue have no typed title, so each renders a visually hidden h1 as the route focus target (§8.20, §8.24).

When done, the caret blinks off, on, off, on, off, on in 530 ms halves (3180 ms), then fades 1 → 0 over 160 ms. `animate-caret-out` is registered in `frontend/src/skins/cinematic/motion.css` as a Tailwind 4 `@theme` entry with its keyframes inside the block (3340 ms, `steps(1)`, `forwards`). The per-keyframe `linear` on the last on-step is required; otherwise the animation-level `steps(1)` would step the fade:

```css
/* frontend/src/skins/cinematic/motion.css */
@theme {
  --animate-caret-out: caret-out 3340ms steps(1) forwards;
  @keyframes caret-out {
    0% { opacity: 0; }
    15.87% { opacity: 1; }
    31.74% { opacity: 0; }
    47.60% { opacity: 1; }
    63.47% { opacity: 0; }
    79.34% { opacity: 1; }
    95.21% { opacity: 1; animation-timing-function: linear; }
    100% { opacity: 0; }
  }
}
```

#### 10.2.4 Flutter implementation

A `StatefulWidget` with a `Ticker` computing `n = min(len, elapsed.inMilliseconds ~/ 50)`, rendering `Text.rich` of the revealed graphemes, a `WidgetSpan` caret (`SizedBox(width: 0)` + `OverflowBox` holding a `Container(width: .12 * size, height: .86 * size, color: CineColors.spot)`), and the rest in a transparent `TextSpan`; a `GestureDetector` completes on tap; `Semantics(header: level != null, headingLevel: level, label: text, excludeSemantics: true)` on every branch, where `level` (1–3, or `null` for a non-heading) follows the web `as` rule above; `disableAnimations` → full text. The caret's blink is one `AnimationController(duration: 3340.ms)` (`_blink`): `final ms = _blink.value * 3340; final o = ms < 3180 ? ((ms ~/ 530).isOdd ? 1.0 : 0.0) : 1 - (ms - 3180) / 160;` driving `Opacity(opacity: o)`: off, on, off, on, off, on in 530 ms halves, then a linear 160 ms fade from 1 to 0.

---

## 11. Gesture matrix

One row per gesture and screen group. "Same" means identical behaviour to the column on its left. Thresholds are shared by both clients: tap slop 8 px, double tap ≤ 300 ms and ≤ 24 px apart, long-press 450 ms, horizontal swipe commits at 72 px or 600 px/s, drag-to-dismiss at 30 % of the sheet height (120 px for the lightbox) or 800 px/s. Every gesture has the non-gesture alternative in the last column, so nothing is gesture-only (§14.8).

**Precedence between horizontal gestures (phones and tablets, both clients).**
- **Rows win.** A horizontal drag that starts on a row with swipe actions belongs to the row. In Flutter this is the gesture arena's default: the innermost horizontal recognizer (the row's `Dismissible`) accepts first, so pagers keep their normal physics and receive only drags that start outside rows (the masthead, the tab row, the toolbar or gaps). On the web, swipe rows set `touch-action: pan-y`, so the scroll-snap pager never takes a drag that starts on a row.
- **Nested contents tabs** inside a hub panel (Updates `NEW · FOLLOWING`, History `BY SERIES · BY CHAPTER`) switch by tap only; the hub pager owns every horizontal drag there.
- **The strip chapter swipe** is live only at zoom ≤ 1.0, for touches that start at least max(24 px, the system gesture inset) from both edges (which also clears iOS's 20 pt back strip), and for drags within 30° of horizontal. Above 1.0× a horizontal drag pans the page.

| Gesture | Screens | iOS app | Android app | Mobile web | Desktop web (equivalent) | Feedback | Non-gesture alternative |
|---|---|---|---|---|---|---|---|
| Tap | Everywhere | Activate | Same | Same | Click | `tap.primary` on primary commits only | Enter / Space |
| Tap (manga strip) | Reader, strip | Toggle chrome; with "Tap to scroll": top third + left-middle back, bottom third + right-middle forward 75 % of the viewport (300 ms `ease.scroll`), centre chrome | Same | Same | Click zones, same map | none | `m`, `Space` / `Shift+Space` |
| Tap zones (paged) | Manga paged, novel paged, guided view | 30 / 40 / 30 (manga paged and guided view), 25 / 50 / 25 (novel): back / menu / next, mirrored for RTL | Same | Same | Click zones, same | `page.turn` | `←` `→`, `j` `k` |
| Tap (typed headline, streaming text) | Tonight, notices, recap | Completes the typing / streaming at once | Same | Same | Click | none | Enter, Space |
| Tap thirds (story pages) | The Annual (phones) | Right third next, left third previous | Same | Same | `←` `→`, Space pauses | `annual.page` | Arrow keys; the story's `Previous page` / `Next page` buttons and screen-reader actions (§9.2.4) |
| Horizontal swipe | The Annual (phones) | Swipe left next, right previous | Same | Same | `←` `→` | `annual.page` | As above |
| Double tap | Reader (strip and paged) | Strip: from the series' resting zoom (the Reading setup stepper) to min(2 × resting, 3.0)× at the point, and from any other zoom back to the resting zoom. Paged: 1× ⇄ 2× at the point. 240 ms `ease.settle` | Same | 300 ms / 24 px detector | Double-click (a double-click on a paged side zone turns two pages and never zooms, §8.14.5) | `zoom.snap` | `=` `-` `0` |
| Double tap | Lightbox | 1× ⇄ 2.5× at the point | Same | Same | Double-click | `zoom.snap` | `=` `-` `0`, zoom buttons |
| Double tap | Guided view | Whole page for 1.5 s, then back to the panel | Same | Same | Double-click | none | `u` exits guided view |
| Double-click | Feature and book page covers, Tonight cover art | n/a | n/a | n/a | Opens the Lightbox (§7.30) | none | `v`, overflow `View cover` |
| Long-press 450 ms | Posters, cuttings, library rows, search results, World cards | Quick look sheet (§7.22) | Same | Same (touch); `contextmenu` event | Right-click menu | `longpress.open` | Overflow `dots-three` button, `Shift+F10` / context-menu key |
| Long-press 450 ms | Feature page cover, book page cover plate, Tonight cover art, Annual cover | Lightbox (§7.30) | Same | Same | Double-click | `longpress.open` | `v`, overflow `View cover` |
| Long-press 450 ms | Reader page | Page actions sheet (§8.14.13) | Same | Same | Right-click menu | `longpress.open` | Running-head overflow, `b` |
| Long-press 450 ms | Chapter rows, contents rows, Updates groups, bookmarks, Downloads series blocks, source rows | Row menu | Same | Same | Right-click menu, hover row actions | `longpress.open` | Trailing `dots-three` |
| Long-press 450 ms | Thumb index: Library, Downloads, Index | Updates, the queue, Switch profile | Same | Same | n/a (sidebar items) | `longpress.open` | The destinations' own entries |
| Long-press 450 ms | Profile avatars (picker) | Edit profile | Same | Same | Right-click, `e` | `longpress.open` | `Manage` |
| Long-press 450 ms | Circle reader avatars | Reading-now tooltip | Same | Same | Hover | none | Member page |
| Long-press 450 ms | Onboarding genre words | Skip (strike-through) | Same | Same | Right-click menu | `select` | Menu "Like, Love, Skip, Clear" |
| Long-press 450 ms | Listen mini player; auto-scroll chip | Keep player visible; speed ruler sheet | Same | Same | Hover shows controls | `longpress.open` | Overflow items |
| Press and hold | The Annual; Listen speed ruler | Pause the page; reset to 1.00× | Same | Same | Space; double-click the ruler | none | Space; `1.00` preset |
| Pinch | Reader (strip, paged) | Strip: 0.5–3.0× around the focal point, snapping to 0.1 steps on release. Paged: 1–3× | Same | `@use-gesture` `usePinch`, `touch-action: pan-y` | `Ctrl`/`⌘` + wheel; Safari `GestureEvent` | `zoom.snap` at 1× and 2× | `=` `-` `0`, setup sheet zoom stepper |
| Pinch | Lightbox | 1–4× | Same | Same | `Ctrl`/`⌘` + wheel | none | Zoom buttons |
| Horizontal swipe | Contents tabs (Library hub, feature page, Numbers ranges, Circle, Downloads, Settings sections on phones) | Pager; the tab rule follows the finger. Nested contents tabs inside a hub panel (Updates `NEW · FOLLOWING`, History `BY SERIES · BY CHAPTER`) switch by tap only (`TabBarView` with `NeverScrollableScrollPhysics()`), so the hub pager owns every horizontal drag there | Same | Scroll-snap pager; nested contents tabs swap the panel with no scroll-snap | n/a | `select` on commit | Tap the tab; `[` `]`, `1`–`n` |
| Horizontal swipe | Tonight "Also in this issue", onboarding steps (commit on Next only), Library continue pager | Pager | Same | Embla pager | Buttons, arrow keys | none | Buttons |
| Horizontal swipe ≥ 72 px | Manga strip | Change chapter (rubber band, `CH 143 →` folio); live only at zoom ≤ 1.0, for touches that start at least max(24 px, `MediaQuery.systemGestureInsetsOf(context).left` / `.right`) from both edges and drags within 30° of horizontal; above 1.0× a horizontal drag pans the page | Same | Same | n/a | `chapter.next` | `h` `l`, folio bar buttons |
| Horizontal swipe | Manga paged, novel paged, guided view | Turn page / panel, finger-tracked, `spring.release` | Same | Same | Wheel (one page per gesture), arrow keys | `page.turn` | Tap zones, keys |
| Horizontal swipe ≥ 72 px | Novel scroll mode (opt-in) | Change chapter | Same | Same | n/a | `chapter.next` | `h` `l`, bottom bar |
| Horizontal swipe | Listen mini player | Previous / next chapter | Same | Same | n/a | `chapter.next` | Transport buttons |
| Swipe row left | Updates groups, bookmarks, Downloads chapter rows, feature schedule rows, book contents rows | Reveals 72 px slabs (`Mark read` bone, `Remove` proof); release past 50 % commits with `spring.release` | Same (`Dismissible`, one action per row, §7.16) | Pointer-event swipe | Hover row actions | `select`; `delete.confirm` for Remove | Trailing `dots-three` menu |
| Vertical scroll | Every list | Clamping + stretch overscroll | Same | Native | Wheel, trackpad; Lenis on Tonight and The Annual only | none | Keys, scrollbar |
| Vertical scroll (scroll-linked) | Tonight | Drives the trailer scrub (§8.8) | Same | Same | Same | none | The now-showing strip is also reachable by `c` |
| Pull down past the top (96 px) | Tonight, Library, Updates (reloads the list), History, Bookmarks, The Numbers, Circle, source catalogue, Sources (`GET /sources` and `GET /sources/pins`), Collections and collection detail (their payloads), Picks (`GET /library/world/recommendations` and `GET /library/suggest/availability`; never re-asks the AI) | Pull to reprint | Same | Pointer events | `r`, overflow `Refresh` | `refresh.arm` | `r` |
| Over-scroll 140 px | Manga strip top; novel scroll bottom | Load the previous chapter; open the next chapter | Same | Same | Scroll past, `h` `l` | `scrub.boundary` | Buttons, keys |
| Pull past chapter end | Manga strip (not continuous) | Fill the 150 px rule to continue | Same | Same | 300 px region, wheel | `chapter.next` | `Read chapter 143` button |
| Swipe down | Sheets | Dismiss past 30 % or 800 px/s (`spring.sheet`) | Same | Same | n/a (column panels close on `Esc`) | `sheet.detent` on settle | `Done`, `Esc`, back |
| Swipe down | Lightbox, Listen full player, The Annual, milestone card, toasts | Dismiss / collapse (finger-tracked) | Same | Same | `Esc` | none | Close buttons |
| Drag handle / long-press then drag | Manual library order, pinned sources, collections, collection members, profiles | Reorder; the lifted row gains a 1 px bone outline | Same | Same | Drag the handle | `select` on drop | `Move up` / `Move down` / `Move to top` / `Move to bottom` in the row's or poster's menu (§7.22, the single-pointer path), and `Alt+↑/↓` (both announced) |
| Drag (scrub) | Reader ruler, sliders, speed rulers, Listen chapter ruler | Seek live, `spring.scrub` on release | Same | Same | Drag, click, arrow keys | `scrub.tick` per page, `scrub.boundary` per chapter, `select` per step | Arrow keys, `g` go to page |
| Vertical swipe, left 12 % edge | Manga reader, novel reader | Brightness HUD (−75 … 0, a dimmer) | Same | Same | n/a | none | Setup sheet Brightness |
| Vertical swipe, right 12 % edge | Manga strip while auto-scroll runs | Auto-scroll speed HUD | Same | Same | n/a | `autoscroll.step` per 0.25× | `<` `>`, chip long-press |
| Edge swipe back | Every pushed screen | 20 pt left edge (`swipeable_page_route`). In the readers it is live only in strip or novel scroll at zoom ≤ 1.0 with guided view off, and a committed swipe pops without a Dip (§8.14.2); disabled in paged readers, inside the Lightbox and in the modal states of §8.0.5 (`PopScope(canPop: false)`) | Predictive back (full-screen fade-through, `CinePageTransitionsBuilder`); the readers have no predictive preview and play the Dip; modal states follow the back order of §8.0.5 | Browser back (sheets, Lightbox and `?sheet=` states are history entries) | Breadcrumb, `Esc` | none | Back button |
| Five centre taps within 2 s | Locked reader (app) | Unlock controls | Same | n/a | n/a | `reader.unlock` | Settings → turn lock off |
| Shake | Listen (last minute of the sleep timer or its fade) | +5 min | Same | n/a | n/a | `select` | Sleep sheet |
| Volume keys | Manga reader (opt-in) | n/a | Page turn | n/a | n/a | `page.turn` | Tap zones |
| Hover / dwell | Posters, rails, rows, linked headings, Tonight backdrop | n/a | n/a | n/a | Zoom inside frame; preview slate at 600 ms; backdrop swap at 400 ms; heading letter wipe | none | `Space` opens the slate on a focused poster |
| Middle-click | Manga reader | n/a | n/a | n/a | Autoscroll anchor (12 px dead zone, 10 px/s per px, max 4000 px/s) | none | `p` auto-scroll |

---

## 12. Brand assets

### 12.1 Idea: the masthead

The app is a periodical you read every night, so the brand is a **masthead**: the name set as the title of a film magazine, with the second M turned to italic, the way a page turns. Its monogram is two M's, one upright and one leaning, overlapping; where they overlap, the light comes through in Subtitle Yellow. It reads as MM, as two panels with a gutter of light, and as a page caught mid-turn.

### 12.2 Wordmark and monogram

- **Wordmark (masthead lockup).** "ManhwaManiacs" on one line: `Manhwa` in Bodoni Moda Roman (opsz 96, wght 800) and `Maniacs` in Bodoni Moda Italic (opsz 96, wght 800); no space: the change of posture marks the word joint. Tracking −0.035em; the italic M's first stroke is kerned to touch the `a` of Manhwa at its terminal. Under it, the Oxford rule (3 px + 2 px gap + 1 px, scaled with the size) in bone, with its first 12 % in `spot` ("the spot"). Aspect ratio about 5.4:1 with the rule. The wordmark is redrawn as outlines (not live text) for the brand assets, from the font instance, with the joint touched up.
- **Stacked lockup** (square spaces, the splash end frame): `Manhwa` over `Maniacs`, flush left, leading 0.86, the Oxford rule under both.
- **Monogram (`mm-mark`)**: an upright Didone M and an italic Didone M, the italic one overlapping the upright one's right stem by 22 % of its width. Both glyphs in bone `#F3F0E8`; their **intersection** is knocked out and filled `spot` `#F4D03F`. Built on a 1024 canvas: bounding box x 232–792, y 272–752; stroke contrast from the font instance (thick stems ≈ 96 units, hairlines ≈ 14 units at this size, thickened to 24 for icon use below 64 px).
- **Single-colour versions**: bone on black (intersection as a hairline outline), black on bone, and the monochrome shape (both M's united) for Android themed icons and iOS tinted icons.
- **Android notification small icon (`ic_stat_mm`)**: the united monochrome monogram, `#FFFFFF` on transparent (Android tints it), on a 24 × 24 dp canvas with 2 dp padding (a 20 dp live area), hairlines thickened to 2 dp so it survives at status-bar size; exported to `mobile/android/app/src/main/res/drawable-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_stat_mm.png` at 24, 36, 48, 72 and 96 px. Accent colour `#F4D03F`. Used by the Listen notification (§8.16.10) and any future notification.
- **Minimum sizes**: wordmark 96 px wide; monogram 16 px (favicon uses a simplified pair with hairlines at 1.5 px).

### 12.3 App icon

- **Cinematic icon**: `#000` field; the monogram centred at 64 % of the icon width; the spot intersection with a faint 12 px bloom at 30 %; monochrome grain at 2 % over the field only; a bone Oxford rule of 24 + 16 + 8 px on the 1024 master (the 3 : 2 : 1 ratio of `rule.oxford`), 18 % below the monogram, 40 % wide, centred (small but it survives at 60 pt).
- **iOS**: 1024 master (opaque); iOS 18 dark (transparent background, same mark) and tinted (the monochrome shape) through `flutter_launcher_icons` 0.14.4 (`image_path_ios_dark_transparent`, `image_path_ios_tinted_grayscale`).
- **Android**: adaptive foreground (the mark inside the 66 dp safe circle: a 160 × 160 px box at xxxhdpi), background `#000000`, monochrome layer (Android 13 themed icons).
- **Per-skin icon**: both skins ship an icon; `flutter_dynamic_icon_plus` 1.4.1 switches it only when the edition is chosen explicitly on this device (Settings → Appearance, the profile form for the active profile, or onboarding step 1), never on a profile pick or the boot-time mismatch restart, so a device shared by a Cinematic and a Glass profile does not flip its icon on every profile switch: the icon shows the edition last chosen on this device. iOS shows its own system alert ("You have changed the icon for ManhwaManiacs.") over the black of Stop the press, and that is expected. On Android the switch is an `activity-alias` swap applied by the package when the app's task is next closed: Stop the press calls the package's `setAlternateIconName` before the restart with empty `blacklistBrands`, `blacklistManufactures` and `blacklistModels`, so its force-restart path is never taken; its `FlutterDynamicIconPlusService` (`android:stopWithTask="false"`) applies the alias on task removal, and no custom `setComponentEnabledSetting` code is added (the restart itself is an in-process `AppRestart.of(context).restart()`, so the task is not replaced). Pinned home-screen shortcuts of the old alias stop working, which the confirm warns about (§8.30.3). While `glass_available` is false no alternate icon is registered.
- **Display name**: the product name stays "ManhwaManiacs" everywhere it is shown in full (About, the store-like SideStore listing, the web title, the PWA `name`). The home-screen label, which iOS truncates after about 12 characters, is `Maniacs` (`CFBundleDisplayName`, Android `android:label` of the launcher activity and aliases, PWA `short_name`). An owner call: setting it back to "ManhwaManiacs" is one line per platform and accepts the truncated "ManhwaMania…" (§15.10).
- **Web**: `favicon.svg` (simplified monogram) with a `favicon.ico` fallback (16 and 32 px), PWA `icon-192/512`, `maskable-512` (mark inside the 40 % radius circle), `apple-touch-icon` 180; the `<link rel="icon">` swaps to the active skin's SVG on load. The web app manifest (`src/app/manifest.ts`, §15.2; no `orientation` key): `name` "ManhwaManiacs", `short_name` "Maniacs", `id` "/", `start_url` "/" (Tonight; it was `/library` before this redesign, web R0), `scope` "/", `display` "standalone", `background_color` and `theme_color` `#000000`, `icons` (192, 512, maskable 512). iOS PWA startup images are plain `#000000` PNGs (the neutral launch frame, §8.2) at 1290 × 2796, 1179 × 2556, 1170 × 2532 and 2048 × 2732, each with its `media` query.
- **SideStore source** `tintColor`: `#F4D03F`; `iconURL` → the new icon; `subtitle` "Every source, one shelf."; `localizedDescription` the four cover lines of §8.34 as one paragraph; `screenshotURLs` the five "Front pages" frames of §12.6 (1320 × 2868).

### 12.4 Splash and logo reveal ("Press start")

Native layer: a plain `#000000` frame with no mark, owned by neither skin (§8.2). The Flutter first frame fades the monogram in on it (the web's server-rendered first frame already shows the monogram), then:

| t (ms) | Element | Motion |
|---|---|---|
| 0–100 | Monogram (bone, no spot) | Fades in 0 → 1, `settle` (web: already present, holds) |
| 100–420 | The intersection | Lights up: fill `#000` → `spot` with a bloom 0 → 0.35 (`spot.glow`), `settle` |
| 252–572 | Monogram | Fades out and scales 1.00 → 0.96 (`lift`) as the letters start, while the wordmark takes its place |
| 252–1180 | Wordmark letters | **Letter set** (§10.1) at its standard timings: 640 ms per grapheme (blur 440), `scalar.stagger.letter` 24 ms, 13 graphemes, so the last letter starts at 540 and lands at 1180; the timeline start replaces `startDelay`. The upright "Manhwa", then the italic "Maniacs" |
| 700–1180 | Oxford rule | Draws left → right under the wordmark: **Rule draw** (480 ms `settle`), its first 12 % in `spot` |
| 1180 | The impression | The whole lockup translates 1 px down and back (80 ms); haptic `splash.impress` (§5); sound `reel` lands its hit if on |
| 1180–1400 | Hand-off | Desktop: the lockup shrinks and flies to the sidebar head (shared element, 220 ms `turn`). Phone: the lockup dissolves over 220 ms as Tonight's headline starts typing |

Duration rule: the choreography runs 0–1180 ms regardless of the network. The 220 ms hand-off starts at `max(probeDone, 1180 ms)`, so the fastest cold start ends at 1400 ms (`dur.reel`); the reveal is never stretched. If the probe is still pending at 1180 ms the lockup holds after the impression, and after 2400 ms the 24 px leader dial and `CONNECTING` appear (§8.2). Tap skips to the hand-off. Warm start: 200 ms fade in and out. Reduced motion: the lockup fades in 300 ms, holds, fades out 200 ms. The skin-switch restart plays the full reveal (it is the moment "everything changes"). Web: the splash plays the full reveal when `sessionStorage['mm.skin.splash']` is missing or differs from the current skin, then writes the current skin to it; otherwise it plays the warm fade (`stack-decision.md` §2.5 web step 6). Web: an inline SVG monogram in the server-rendered root, the wordmark as live text in Bodoni Moda (`display: block`, preloaded) animated by `SetHeading`; the Oxford rule is a `<div>` with `scaleX`.

### 12.5 Voice

Short, dry, confident; title-card and magazine phrasing; no exclamation marks. Kickers name the department (`TONIGHT`, `CORRECTION`, `OFFLINE EDITION`, `STOP PRESS`, `PREVIOUSLY ON`, `COMING UP`, `THE CIRCLE`). Headlines are full sentences with a full stop. Numbers under ten are spelled out in headlines, numerals everywhere else. Errors say what happened and what still works ("The server didn't answer. Your library is untouched.").

### 12.6 Screenshot set ("Front pages")

Five frames at 1320 × 2868 (a 440 × 956 CSS viewport at DPR 3 with Playwright, `research/brand.md` §11), a seeded demo profile, no 18+ content, placeholder covers in the hero frame. Each frame: a 640 px black top band with the caption set as a magazine cover line (Bodoni Moda Italic 120 px, bone, one keyword in `spot` via a highlighter band), a folio line above it (`No. 1 · TONIGHT`), and the UI capture below it, square-cornered, bleeding off the bottom edge, with a bone Oxford rule at the capture's DPR 3 (9 + 6 + 3 px, `rule.oxford`) between band and capture. Captions: "Every source. One shelf." · "Built for the long scroll." · "Novels, read aloud." (sub "Thirty-one voices") · "Your year in chapters." · "Read together." Desktop set 2880 × 1800 uses the spread layout. **OG image** (1200 × 630, `frontend/public/og.png`, also served by the install page): `#000000`; on a 12-column grid with 48 px margins, the wordmark lockup at 72 px cap height with its Oxford rule in columns 1–5, vertically centred, the cover line "Every source. One shelf." in Bodoni Moda Italic 40 under it; columns 6–12 hold the "Front pages" Tonight capture, square-cornered and bleeding off the right and bottom edges under `scrim.gutter`; no 18+ content and no real profile names.

### 12.7 Asset pipeline

Masters as SVG in `brand/cinematic/` (monogram, wordmark lockups, icon layers, favicon, the notification small icon `ic_stat_mm`, the custom glyphs in `glyphs/`); one export script (`@resvg/resvg-js` 2.6.2, run with `npx`) renders PNGs (including the five `ic_stat_mm` densities and the four black PWA startup images); `flutter_launcher_icons` 0.14.4 and `flutter_native_splash` 2.4.8 consume them; a check script asserts sizes, no alpha on the iOS master, and the safe-circle fit. Fonts' `OFL.txt` files ship with the app's licenses.

---

## 13. Signature moments

1. **Press start** (cold launch): the monogram rises out of the black launch frame and its intersection lights yellow, the masthead sets letter by letter, the Oxford rule draws, and the whole lockup makes one 1 px impression with a letterpress haptic.
2. **The front page** (Tonight): the cover racks into focus, the art bleeds off the spread under a duotone, and the headline types itself at 50 ms per character behind a yellow cursor: "Tonight: chapter 143 of Omniscient Reader."
3. **The Iris** (profile picker): the chosen avatar's ring draws in yellow, a black iris closes on it, and the profile's issue opens with an iris out from the same point; a Glass profile restarts inside the black.
4. **The Column wipe** (sitting down to read from the front page or a series page, never between chapters): the page's own grid columns close as black blades, top-down in reading order, and open bottom-down onto page one, with the `wipe` haptic as the shutter lands.
5. **Section heads being set**: every rail header's rule draws and its Bodoni italic letters arrive out of a blur, hairlines last; hovering a linked head wipes it to yellow letter by letter.
6. **Folio flip**: changing section rolls the running head's section number like a page counter.
7. **The credits** (end of a chapter): "End of chapter 142" is set, the credits list the source and reading time, the circle's reaction stamps sit underneath, and the Coming up card waits with the next chapter's first page in duotone; a pull fills a yellow rule and cuts through black into chapter 143, whose title types itself.
8. **The highlighter** (Listen mode): as each sentence is spoken, a yellow highlighter stroke sweeps across it, the speaker's name sits above in their tint, and the page holds the line at the reading height.
9. **Previously on**: a title card, the kicker set, the recap arriving word by word under a Bodoni drop cap, and a cast list with dot leaders.
10. **The certificate** (18+): the square seal stamps: it fills red, the 18 knocks out, and it settles back to an outline under a stamp haptic.
11. **The genre paragraph** (onboarding): taste is set as a justified paragraph of italic genres that you underline, highlight or strike out like proof marks.
12. **Stop the press** (skin switch): in half a second the page racks out of focus, the columns close, the masthead cuts in on black, and the app restarts into the other edition.
13. **The Annual**: a special issue of eleven spreads whose numbers type themselves, closing on end credits ("Shot on MangaDex, Asura. Narrated by Arden. See you in 2027.") and a press run of share cards that print with a three-hit `pressrun` haptic.
14. **The flame catches**: the day's first finished chapter turns the outlined streak flame into a yellow fill with its bloom, while the streak numeral types its new value.
15. **A letter arrives** (Circle): a recommendation unfolds from its top edge, the sender's kicker types itself, and the yellow dot goes out when it is read.
16. **What they said** (dialogue search): each result is a still of the panel around the speech bubble with the line laid over it as a subtitle; yellow highlighter strokes sweep across the matched words; choosing one opens the chapter at the right page and pulses a yellow frame twice around the bubble.
17. **Scrub the trailer** (Tonight): as the cover story scrolls away, the cover compresses frame by frame into a 64 px now-showing strip in the running head, with `Continue │ CH 143` riding along; scroll back and it unfolds.
18. **Cut to home** (end of onboarding): the posters you picked fly out of the wall, 60 ms apart, straight into Tonight's first section, and the front page types its first headline.
19. **The Circle lights up**: every member reading right now wears a ring in the colour of the series in their hands.
20. **The whole cover** (Lightbox): a long-press lifts the cover out of its crop to fill the screen, square and unlit; drag it down and it falls back into the page.
21. **The casting call** (voice picker): as a voice introduces itself, a yellow highlighter pulses behind its name with the sound of the voice.
22. **Milestone title card** (7, 30, 100, 365 days): the flame takes its new shape, the numeral types, "Thirty days in a row." is set, and a share card is one tap away.
23. **End credits** (The Annual): the year rolls up as a film's credits, "Shot on MangaDex, Asura. Narrated by Arden.", and closes on "See you in 2027." before the press run.

---

## 14. Accessibility and reduced-motion rules

These rules bind every screen in §8 and §9. The per-cluster checks that prove them are in §15.7.

### 14.1 Reduced motion

- **Which setting.** Reduced motion is on when the OS asks for it (web `prefers-reduced-motion: reduce`; Flutter `MediaQuery.disableAnimationsOf(context)`, which reflects iOS Reduce Motion and Android "Remove animations") **or** when Settings → Appearance → "Reduce motion in the app" is `ON` (per profile). One check per client decides it: web `html[data-motion="reduced"]` plus `<MotionConfig reducedMotion="always">`; Flutter `CineMotion.reduced(context)`. On the web the attribute is stamped before first paint by `appearance-boot-source.ts` from the OS query and the remembered profile's `mm.boot.a11y` entry (§3.4); the server cannot stamp it because it has no profile at SSR. With no entry, the page follows the OS setting only until the profile loads, then the attribute is applied for everything that starts afterwards (a move already running finishes). The splash and Login always run before any profile is known and follow the OS setting alone.
- **The table in §4.8 is authoritative** for every named move. The general rule behind it: spatial motion (slides, wipes, irises, match cuts, zooms, parallax, the trailer scrub, flights) becomes an opacity change of 150–200 ms; loops stop (Drift, flicker, flame flicker, the streak ring and sparks, the scrolling edition preview); scroll never drives animation; countdowns become labels that update once per second; nothing that moves starts by itself (auto-scroll never auto-starts, the Annual does not auto-advance, guided view auto-advance cuts between panels).
- **What does not change.** Haptics, sounds (when on), timings that protect the user (the 1000 ms destructive arm delay), essential progress indicators (the leader dial §7.18, the indeterminate rule and the button loading segment §7.1 keep running unchanged; "loops stop" never applies to them), and every piece of information: reduced motion removes movement, never content or state.
- **Rule of thumb for anything not in the table**: a slide becomes a 150 ms opacity change, a sweep or draw shows its end state, a programmatic scroll jumps.

### 14.2 Contrast

- `ink.45` text (4.70:1) appears only on `paper.0` `#000000`. On every other ground (`paper.1` 4.41, `paper.2` 4.20, `paper.3` 3.90, `paper.4` 3.56, mood grades 4.14–4.39, `ambient.tint` and page-tint fields) the same roles render `ink.60` (≥ 5.45:1 on all of them) through the raised-stock scope of §2.1.1. `ink.30` (2.4:1) never carries information. Text on `spot` or `proof` fills is `#000000` (13.9:1 and 6.9:1). Inside a `spot.wash` band the `ink.45` and `ink.60` roles render `ink.80`, and inside stock-painted panels `ink.45` roles render the stock's `muted` colour (§2.1.1).
- **Over art.** Every text run and icon over art (covers, manga pages, duotone fields, blurred copies) sits on a black ground of at least the per-ink alpha in the §2.1.4 over-art table (`ink.100` 0.60, `ink.80` 0.68, `spot` 0.66, `set` 0.70, `ink.60` 0.82, `proof` 0.84), which gives ≥ 4.5:1 composited over `#FFFFFF`; `ink.30` is never used over art, and `ink.45` only on a solid ground. Badges that can sit on art have a `#000000` fill (§7.19), which counts as a solid ground: as in the rating card's `paper.0` box, the ± 8 px margin is the box's own padding, and `ink.45` is allowed on it (4.70:1). Controls where no scrim reaches (the recap's `Skip recap →`, The Annual's phone close `x` and page buttons) are `on-art` variants, whose `color.onart` fill (0.64) is their ground (`ink.100` 5.89:1 over `#FFFFFF`).
- Derived colours are guarded by construction and tested (§2.1.5): `ambient.ink` ≥ 7:1, `page.light` ≥ 4.5:1, the Issue stock ≥ 13:1 ink and ≥ 5.5:1 muted.
- Non-text marks that identify a control or its state are ≥ 3:1: focus ring `ink.100` (18.4:1, with its black halo over art, §2.4), switch and checkbox outlines `ink.45`, selected rules `spot`, slider thumbs and fills `ink.100`. Hairlines (`rule.1`, `rule.2`) are decorative separators; no control relies on them alone (inputs are identified by their visible kicker label).
- Paper stocks: the six fixed stocks: ink ≥ 13.4:1, muted ≥ 5.8:1; the Issue stock: ink ≥ 13:1, muted ≥ 5.5:1 (§2.1.6).

### 14.3 Colour is never the only signal

Health states carry a label and a square mark; cautions carry the `NOTE` kicker; errors carry the `CORRECTION` kicker and a `‸` margin mark; download states have distinct shapes (§7.18); reactions have a glyph and a name; the spoiler guard uses words ("reacted to Ch. 212"); charts have a text summary above them and a label on every mark (§9.2.3); speaker tints are backed by the speaker's name on hover or long-press, and above the sentence in Listen mode (§8.15.2).

### 14.4 Keyboard and focus

- The focus ring is a double ring (2 px `ink.100` at 2 px offset plus a black halo out to 6 px: web `outline: 2px solid var(--mm-color-ink-100); outline-offset: 2px; box-shadow: 0 0 0 6px #000`, combined with any existing shadow; Flutter `CineFocusRing` paints the bone stroke over a `#000000` band from the edge out to 6 px, §2.8.2), square, shows on keyboard focus only and is never clipped (§2.4, §7). On black the halo is invisible; over art it separates the ring at 18.44:1.
- Desktop web has a **Skip to content** link as the first focusable element (visible on focus, top-left, `paper.2` band, `type.ui`), which moves focus to the page's `h1`.
- **Route changes move focus.** After every in-app navigation, focus moves to the new page's `h1` (rendered with `tabIndex={-1}`; in Flutter a `FocusNode` on the masthead's `Semantics(header: true, headingLevel: 1)`; Discover and Dialogue, which have no visible title, render a visually hidden h1, §8.20 and §8.24), so screen readers announce the new page, and `document.title` becomes `{Page} · ManhwaManiacs`. A filter, sort or in-page tab change does not move focus; a reader route focuses the reading surface (web `tabIndex={-1}`, `role="region"`, `aria-label="Chapter 143, page 1 of 40"`; Flutter a `FocusNode` on the strip with the same `Semantics` label), and a polite live region (`aria-live="polite"`; Flutter `Semantics(liveRegion: true)`) announces "Chapter 143, The Return · Solo Leveling" on entry and on every chapter change (chapter number, chapter title, series title; when the chapter has no title the middle part is dropped: "Chapter 143 · Solo Leveling"). This is the only chapter announcement string; §14.5 refers to it; a typing headline takes focus as a tab stop (§10.2.3).
- **Forced colours and more contrast** (web). Under `@media (forced-colors: active)` every rule, hairline, notch, focus ring and control outline uses `CanvasText`, `spot` fills become `Highlight` with `HighlightText`, and duotone, grain, scrims and blur are dropped (covers and pages keep `forced-color-adjust: none`). Under `@media (prefers-contrast: more)` the `ink.45` role renders `ink.80` and `rule.1` renders `rule.2`. On the phones, when `MediaQuery.highContrastOf(context)` is true (iOS Increase Contrast, Android high-contrast text), the skin root applies the same remap through `CineTokens.copyWith(colorInk45: colorInk80, colorRule1: colorRule2)`.
- Every screen is fully usable from the keyboard on the web and with a hardware keyboard on iPad and Android tablets (`Shortcuts` / `Actions`); the keys are listed per screen in §8 and in the `?` sheet. Single-key shortcuts can be turned off (Settings → Keyboard).
- Focus order follows the grid's reading order. Sheets, dialogs, the command palette and the Lightbox trap focus and return it to the trigger. Rails are one tab stop with roving focus.
- Hidden chrome leaves the tab order (`visibility: hidden` / `Offstage`). Chrome never auto-hides (idle or scroll) while focus is inside it (§14.5, §8.14.3); if it hides by a user command (`m`, `c`, a click on the page) while it holds focus, focus first moves to the reader canvas (the `tabIndex={-1}` reading region; Flutter the strip's `Focus`), never to the body. On Tonight the spread's text column goes inert at trailer progress p ≥ 0.55 and the strip's controls enter the tab order at p ≥ 0.8, where their opacity is ≥ 0.5 (§8.8).

### 14.5 Screen readers

- Semantics: each page has one `h1` (its masthead); section heads (design role `type.section`) are `h2` (the `SetHeading` component is given `as="h2"`); subsections `h3`. In Flutter `SetHeading` and `TypedHeadline` take `level` (1–3) and wrap every branch in `Semantics(header: true, headingLevel: level)` (§10.1.6, §10.2.4). `TypedHeadline` is `h1` only where the typed line is the page's only title (§10.2.3). Landmarks: `nav` (sidebar, thumb index), `main`, `aside` (reader side panels, desktop asides), `dialog`.
- Custom controls expose their role, state and name per the §7 semantics contract (switches, checkboxes, radios, toggles, tri-state filters, tabs, reaction stamps, download marks, meters, progress, the streak flame, week dots).
- Folios and abbreviations are read in full through `folioLabel()` (§7.29): "CH 142 · 63%" is read "Chapter 142, 63 percent read", "2 H" is "2 hours ago", the certificate is "Mature, 18 plus".
- The letter and typing reveals expose the full text from the first frame (§10.1.1, §10.2.1); streamed AI text is announced once when complete, not word by word.
- Toasts are `role="status"`; errors are `role="alert"`; search result counts and "Ready" (destructive arm) are polite live regions.
- **Timers wait while focus is inside.** On both clients and for every user, a timer pauses while keyboard focus is inside the element it times (web `:focus-within`; Flutter any of its `FocusNode`s has focus): toast holds, the chrome idle hides (§8.14.3 including cinema mode, §8.15.3, §7.30) and the §8.16.2 mini-player linger.
- **Timers wait for screen-reader users.** When a screen reader is running (web: no reliable detection, so the web relies on the focus rule above and on the recap's extra pause triggers, §9.1.5; iOS `MediaQuery.accessibleNavigationOf`, Android TalkBack via the same flag): toast holds never run out while the toast has an action; the reader's chrome auto-hide is disabled; the recap countdown never starts; The Annual does not auto-advance; guided view does not auto-advance; the Listen post-play countdown waits.
- The reader announces chapter changes through the §14.4 live region, with the §14.4 string ("Chapter 143, The Return · Solo Leveling"), but not page changes; the ruler is a native range with `aria-valuetext="Page 18 of 40"`.
- Images: covers carry the series title as their label; decorative art (duotone fields, bleeds, grain) is hidden from the tree; the Lightbox is labelled "Cover of {title}".
- Manga pages: each page image is labelled "Page 18 of 40"; when the chapter has OCR text (`GET /ocr/chapter`, fetched once per chapter only while a screen reader is running), that page's recognised lines in reading order become its description (web `aria-describedby` pointing at a visually hidden block; Flutter `Semantics(label: 'Page 18 of 40', hint: pageText)`).
- The Annual pages as a story group with Previous, Pause and Next reachable as buttons and screen-reader actions (§9.2.4).

### 14.6 Touch targets

By input type, grown with padding (§7):

- **Coarse pointer** (phones, tablets, mobile web): at least 44 × 44 pt on iOS and mobile web and 48 × 48 dp on Android, with ≥ 8 px between adjacent targets. Every "44 hit" in §7–§9 means 44 (48 Android).
- **Fine pointer** (`@media (pointer: fine)`, desktop web): at least 32 × 32 px with ≥ 24 px target spacing (WCAG 2.2 2.5.8), which makes the desktop `sm` button (32), menu items (40), the segmented control (40) and filter tokens (hit box 32 px tall around the 28 px box) valid.

The reader's tap zones are at least 25 % of the screen width; a full-width band is at least 12 % of the screen height.

### 14.7 Text size and legibility

Dynamic Type and Android font scale are honoured with per-role caps and reflow rules (§3.3); the web honours browser zoom to 200 % without horizontal scrolling (except tables, which scroll inside their own container). The novel reader has its own absolute size range, 14–40 px: the body renders with `TextScaler.noScaling`, and a book with no stored size opens at the system-scaled default, clamped to 14–40 (§3.3, §8.15.5). The **Hyperlegible text** option (§3.4) switches all long text to Atkinson Hyperlegible Next. Every height in §7 is a minimum, so nothing clips at large text (§7 intro). On the phones OS **Bold Text** (`MediaQuery.boldTextOf(context)`) gets designed weights: `CineType` adds 120 to every role's `wght` variation (the novel reader's Bold text step) and sets the matching `fontWeight`, clamped to each face's axis maximum (§3.1). OS increased contrast remaps `ink.45` → `ink.80` and `rule.1` → `rule.2` on both clients (§14.4).

### 14.8 Every gesture has an alternative

The last column of the gesture matrix (§11) names the button, menu item or key for every gesture. Long-press menus are always mirrored by a visible `dots-three` button; the Lightbox by `View cover`; swipe actions by row menus; edge swipes by setup-sheet controls.

### 14.9 Haptics and sound

Haptics always accompany a visible change and never carry information alone; they can be turned off (Settings → Feedback). UI sounds are off by default, respect the iOS silent switch (`.ambient` outside narration and voice samples, §6), never duck the user's music, and are silent while narration or a soundscape plays.

### 14.10 Flashing and motion sickness

Nothing flashes more than three times a second: the caret blinks at 0.94 Hz, skeletons flicker at 0.36 Hz, sparks rise once a second, the 18+ stamp fills once. There is no parallax except the trailer scrub, which is scroll-linked and stops under reduced motion. The reader never animates the page itself except for zoom and the guided-view camera (which cuts under reduced motion).

### 14.11 Content safety

18+ content the gate hides is absent, never blurred or counted (§7.24), including everything stored on the device, which is filtered locally; links to it land on the same not-available notice as removed content (§8.0.10); the rating card informs without blocking; share cards draw only on the server's non-mature `shareable` block, so neither 18+ series, their covers nor genres weighted by mature reading appear (§9.2.5); every Circle-derived figure, including activity, reactions, letters, shelves, counts and the Annual's overlaps, is computed from the member's shareable activity set and filtered for the viewer's own gate (§9.3.1).

---

## 15. Implementation notes

### 15.1 Token source (`design/tokens/cinematic.json`, excerpt)

The file uses exactly the key space of §2.8 and §3.5: dotted keys become nested objects (`dur.wipe.close` → `"dur": { "wipe": { "close": … } }`). Every value has one of six kinds, so `design/build.mjs` needs one rule per kind: a **colour** (hex or `rgba()`), a **length** (a number in logical px), an **integer** (a unitless number: `z.*`, emitted as `--mm-z-page: 0` and a Dart `int`), a **curve** (`{ "bezier": [x1, y1, x2, y2] }`, or the literal `"linear"`, emitted as `linear` / `Curves.linear` as §2.8.4 already shows; the stack's `{ms, bezier}` form is still accepted, but this skin keeps durations in `dur.*`), a **spring** (`{ "ms", "bounce" }`, as the stack), and a **scalar** (`{ "value", "unit" }`, or an object of scalars for a stagger), the kind this contract adds to `stack-decision.md` §2.1 (§15.10). `font`, `type`, `grid`, `bp`, `rule`, `scrim`, `focus`, `haptics`, `sounds` and `soundEvents` are structured groups, each emitted by its own rule with the shapes shown in §2.8.2, §2.8.3, §3.5, §5 and §6. Haptics map an event to a pattern name, or to a **sequence** `[first, { "after": ms, "then": pattern }]` for compound patterns.

```json
{
  "color": {
    "paper": { "0": "#000000", "1": "#0B0B0A", "2": "#121211", "3": "#1A1A18", "4": "#232220" },
    "rule": { "1": "#2B2A27", "2": "#3D3C38" },
    "ink": { "30": "#4D4B47", "45": "#7A7770", "60": "#9A978F", "80": "#C9C6BE", "100": "#F3F0E8" },
    "spot": { "_": "#F4D03F", "press": "#D9B62C", "wash": "rgba(244,208,63,0.16)", "glow": "rgba(244,208,63,0.35)" },
    "proof": { "_": "#FF5B4A", "press": "#E0483A", "wash": "rgba(255,91,74,0.12)" },
    "set": "#57D68D", "info": "#9CC8FF", "note": "#F4D03F",
    "onart": "rgba(0,0,0,0.64)", "hairline": { "art": "rgba(243,240,232,0.08)" }, "galley": "rgba(243,240,232,0.06)",
    "leader": { "sweep": "rgba(243,240,232,0.22)" }, "lightbox": "rgba(0,0,0,0.96)", "matte": { "guided": "rgba(0,0,0,0.85)" }, "warmth": "#FF8A00",
    "ambient": { "fallback": { "duo": "#B8B2A4", "tint": "#0E0D0B", "ink": "#F3F0E8" } }
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
                "size": { "phone": [11, 16], "tablet": [12, 16], "desktop": [12, 16], "wide": [13, 16] }, "scaleCap": 2.0 }
  },
  "space": { "0": 0, "1": 4, "2": 8, "3": 12, "4": 16, "5": 20, "6": 24, "8": 32, "10": 40, "12": 48, "16": 64, "20": 80, "24": 96, "32": 128 },
  "grid": { "phone": [4, 16, 12], "tablet": [8, 32, 16], "desktop": [12, 48, 24], "wide": [12, 72, 24, 1760], "cinema": [12, 96, 32, 1760] },
  "bp": { "tablet": 600, "frame": 768, "desktop": 1024, "wide": 1440, "cinema": 1920 },
  "radius": { "0": 0, "round": 9999 },
  "blur": { "letter": 8, "rack": 14, "bleed": 56, "card": 24, "defocus": 6 },
  "z": { "page": 0, "sticky": 10, "chrome": 20, "panel": 30, "sheet": 40, "dialog": 50, "toast": 60, "lightbox": 70, "shutter": 80, "debug": 90 },
  "dur": {
    "cut": { "value": 0, "unit": "ms" }, "tick": { "value": 80, "unit": "ms" }, "beat": { "value": 160, "unit": "ms" },
    "line": { "value": 240, "unit": "ms" }, "column": { "value": 320, "unit": "ms" }, "spread": { "value": 480, "unit": "ms" },
    "wipe": { "close": { "value": 200, "unit": "ms" }, "open": { "value": 280, "unit": "ms" } },
    "dissolve": { "value": 800, "unit": "ms" }, "reel": { "value": 1400, "unit": "ms" }, "drift": { "value": 26000, "unit": "ms" },
    "type": { "value": 50, "unit": "ms" }, "caret": { "value": 530, "unit": "ms" },
    "letter": { "_": { "value": 640, "unit": "ms" }, "blur": { "value": 440, "unit": "ms" } },
    "hold": { "toast": { "_": { "value": 3600, "unit": "ms" }, "error": { "value": 6000, "unit": "ms" },
                         "action": { "value": 8000, "unit": "ms" }, "undo": { "value": 10000, "unit": "ms" } },
              "rating": { "value": 3000, "unit": "ms" },
              "panel": { "base": { "value": 1200, "unit": "ms" }, "word": { "value": 250, "unit": "ms" }, "cap": { "value": 6000, "unit": "ms" } },
              "dip": { "value": 40, "unit": "ms" }, "error": { "value": 2000, "unit": "ms" },
              "success": { "value": 1600, "unit": "ms" }, "connected": { "value": 400, "unit": "ms" }, "chip": { "value": 1200, "unit": "ms" }, "flash": { "value": 1200, "unit": "ms" },
              "glance": { "value": 1500, "unit": "ms" }, "brief": { "value": 2000, "unit": "ms" }, "edition": { "value": 4000, "unit": "ms" },
              "annual": { "page": { "value": 6000, "unit": "ms" }, "list": { "value": 8000, "unit": "ms" } } },
    "dwell": { "preview": { "value": 600, "unit": "ms" }, "backdrop": { "value": 400, "unit": "ms" } },
    "flicker": { "value": 1400, "unit": "ms" }, "arm": { "value": 1000, "unit": "ms" },
    "countdown": { "recap": { "value": 12000, "unit": "ms" }, "next": { "value": 5000, "unit": "ms" } },
    "sample": { "tint": { "value": 600, "unit": "ms" } },
    "pageturn": { "value": 280, "unit": "ms" },
    "snap": { "value": 120, "unit": "ms" }, "reduced": { "value": 150, "unit": "ms" }, "clip": { "value": 200, "unit": "ms" },
    "page": { "out": { "value": 224, "unit": "ms" } }, "dim": { "value": 280, "unit": "ms" }, "tapscroll": { "value": 300, "unit": "ms" },
    "match": { "back": { "value": 336, "unit": "ms" } }, "rise": { "value": 360, "unit": "ms" }, "glide": { "value": 400, "unit": "ms" },
    "stoppress": { "value": 500, "unit": "ms" }, "rack": { "value": 520, "unit": "ms" }, "iris": { "out": { "value": 560, "unit": "ms" } },
    "loop": { "rule": { "value": 1200, "unit": "ms" }, "preview": { "value": 12000, "unit": "ms" } },
    "fade": { "first": { "value": 100, "unit": "ms" }, "cut": { "value": 250, "unit": "ms" }, "hint": { "value": 1000, "unit": "ms" } },
    "leader": { "value": 1000, "unit": "ms" }, "roll": { "colophon": { "value": 10000, "unit": "ms" } },
    "flame": { "flicker": { "value": 2000, "unit": "ms" }, "risk": { "value": 800, "unit": "ms" },
               "ring": { "value": 24000, "unit": "ms" }, "spark": { "value": 900, "unit": "ms" } }
  },
  "ease": {
    "settle": { "bezier": [0.16, 1, 0.3, 1] }, "lift": { "bezier": [0.7, 0, 0.84, 0] },
    "turn": { "bezier": [0.65, 0, 0.35, 1] }, "set": { "bezier": [0.2, 0, 0, 1] },
    "drift": { "bezier": [0.37, 0, 0.63, 1] }, "scroll": { "bezier": [0.5, 1, 0.89, 1] }, "linear": "linear"
  },
  "spring": { "release": { "ms": 420, "bounce": 0 }, "sheet": { "ms": 480, "bounce": 0 }, "scrub": { "ms": 240, "bounce": 0 } },
  "scalar": {
    "stagger": {
      "grid": { "item": { "value": 32, "unit": "ms" }, "row": { "value": 64, "unit": "ms" }, "cap": { "value": 480, "unit": "ms" } },
      "list": { "item": { "value": 24, "unit": "ms" }, "cap": { "value": 360, "unit": "ms" } },
      "letter": { "item": { "value": 24, "unit": "ms" }, "cap": { "value": 560, "unit": "ms" }, "startDelay": { "value": 120, "unit": "ms" } },
      "word": { "item": { "value": 30, "unit": "ms" }, "fade": { "value": 160, "unit": "ms" } },
      "fly": { "item": { "value": 60, "unit": "ms" } }
    },
    "letter": { "rise": { "value": 0.42, "unit": "em" } },
    "rubber": { "value": 0.35, "unit": "" },
    "pace": { "top": { "value": 1.2, "unit": "" }, "words": { "value": 60, "unit": "" },
              "min": { "value": 0.5, "unit": "" }, "max": { "value": 1.0, "unit": "" } }
  },
  "haptics": {
    "tap.primary": "ahap:impress", "follow.add": "ahap:stamp", "bookmark.add": "ahap:impress", "voice.assign": "ahap:impress",
    "reader.enter": "ahap:wipe", "streak.extend": "ahap:ignite", "share.export": "ahap:pressrun", "recommend.send": "ahap:pass",
    "reaction.send": "ahap:stamp", "gate.confirm": "ahap:stamp", "splash.impress": "ahap:impress",
    "toggle.on": "medium", "toggle.off": "light", "nav.change": "rigid", "select": "selection", "page.turn": "selection",
    "longpress.open": "heavy", "chapter.next": "heavy", "profile.select": "heavy", "skin.switch": "heavy",
    "chapter.complete": ["medium", { "after": 120, "then": "light" }],
    "streak.milestone": ["ahap:ignite", { "after": 520, "then": "ahap:stamp" }],
    "error": "error", "success": "success"
  },
  "sounds": {
    "tick": "press/tick.wav", "set": "press/set.wav", "impress": "press/impress.wav", "turn": "press/turn.wav",
    "wipe": "press/wipe.wav", "done": "press/done.wav", "bell": "press/bell.wav", "pass": "press/pass.wav",
    "error": "press/error.wav", "toggle.on": "press/toggle-on.wav", "toggle.off": "press/toggle-off.wav",
    "sheet": "press/sheet.wav", "reel": "press/reel.wav"
  },
  "soundEvents": { "$ref": "§6 event map: every event → one cue above, or null for silent" }
}
```

`"_"` names the value of a key that also has children (`color.spot` and `color.spot.press`). The `haptics` object in the full file lists every event of §5 (the excerpt shows each shape once); `soundEvents` is the full §6 map (event → cue or `null`). `design/build.mjs` emits `frontend/src/skins/cinematic/tokens.generated.{css,ts}` and `mobile/lib/skins/cinematic/tokens.g.dart` from it (stack-decision §2.1). Letter spacing in em is multiplied by the size for Dart; springs map to Motion `{visualDuration, bounce}`, to `SpringDescription.withDurationAndBounce` with the duration `ms × 1.2` (so stiffness matches Motion's), and to a CSS `linear()` curve plus its settle time from the stdlib spring port (§2.8.4); curves to `cubic-bezier` and `Cubic`; `dur` scalars to CSS `ms` custom properties, Motion seconds and Dart `Duration`s; other scalars to plain numbers (em scalars stay em for CSS and are multiplied by the font size in Dart); a haptic sequence to a `HapticStep` list that `skin_haptics.dart` plays with a `Timer`; the type roles become Tailwind `@theme` `--text-*` entries, `@utility type-*` classes and a Dart `CineType` class that applies `FontVariation`s and `TextScaler.clamp` per role. The full name mapping is §2.8 and §3.5; `node design/build.mjs --check` fails CI when a generated file differs from the JSON.

### 15.2 Web (`frontend/src/skins/cinematic/`)

| File | Content |
|---|---|
| `tokens.generated.css` / `.ts` | `[data-skin="cinematic"] { --mm-color-spot: #F4D03F; … }` (every property in §2.8 and §3.5), `@property` registrations for `--amb-duo`, `--amb-tint`, `--amb-ink`, `--page-tint`, `--page-light`; the skin block's `--mm-font-text: var(--mm-font-newsreader)`; and the `html[data-legible="on"][data-skin="cinematic"]` override of `--mm-font-text` and of the deck, body and body-italic `-lh` per breakpoint (§3.4) |
| `../theme.generated.css` | The shared `@theme inline { … }` and `@utility type-* / scrim-*` block (§2.8), imported once by `app/globals.css`, which then `@import`s `skins/cinematic/tokens.generated.css` and `skins/cinematic/motion.css` after it, so every `[data-skin]` value and motion rule arrives with the one global stylesheet |
| `fonts.ts` | `next/font/google`: `Bodoni_Moda({ subsets: ["latin", "latin-ext"], axes: ["opsz"], style: ["normal", "italic"], display: "block", preload: true, variable: "--mm-font-display" })`, `Archivo({ subsets: ["latin", "latin-ext"], axes: ["wdth"], display: "swap", variable: "--mm-font-grotesk" })`, `Newsreader({ subsets: ["latin", "latin-ext"], axes: ["opsz"], style: ["normal", "italic"], display: "swap", variable: "--mm-font-newsreader" })`, `IBM_Plex_Mono({ subsets: ["latin", "latin-ext"], weight: ["400", "500", "600"], display: "swap", variable: "--mm-font-folio" })`; the three reading faces of §3.4 in `reading-fonts.ts`, imported only by the novel reader's layout (and by the shell when Hyperlegible text is on); Noto KR/JP/SC with `preload: false` in the fallback stacks |
| `Shell.tsx` | Contents sidebar, running head, thumb index (< 768), toast host, stop-press banner, first-run note, command palette mount |
| `Splash.tsx` | §12.4 |
| `motion.ts`, `motion.css` | `play(name, …)` (every named move of §4.5 starts here and reports to the timings overlay), `SetHeading`, `TypedHeadline`, `ColumnWipe` (fixed overlay of N blades from `Grid`, Motion `animate` with `stagger`), `Iris` (`clip-path: circle()`), `RackImage`, `Drift`, `Flicker`, `RuleDraw`, `FlyToSlots` (Cut to home, §8.7), `useTrailerScrub` (§8.8), `caret-out` keyframes, reduced-motion overrides |
| `tint.ts`, `tint.test.ts` | Page-tint and Issue-stock role derivations and the 1,440-case contrast test (§2.1.5) |
| `primitives/Lightbox.tsx` | §7.30 |
| `motion-timings.tsx` | The development overlay of §15.9 (`mod+shift+m`), tree-shaken out of production builds |
| `primitives/*` | §7 components; Base UI (`@base-ui/react` 1.8.0) supplies Dialog, Drawer (sheets and column panels), Menu, ContextMenu, Popover, Tabs, Switch, Slider, Checkbox, Radio, ToggleGroup, all unstyled and dressed with these tokens |
| `screens/*` | One file per ScreenId (`satisfies Record<ScreenId, Screen>`) |
| `haptics.ts` | The five `navigator.vibrate` events (§5), each skipped when `localStorage['mm.haptics']` is `off` (§8.30.2 row 10); everything else no-ops |
| `sounds.ts` | Web Audio loader and player for the Press Room set; suppressed while narration or a soundscape plays |
| `share-card.ts` | Canvas 2D renderer (§9.2.5) |
| `duotone.tsx` | One SVG `<filter>` per ambient duo, keyed by colour, mounted in the shell and in the edition preview layout (§8.30.3), because a `filter: url(#duo-<id>)` that points at a missing filter is ignored and the art paints full colour |
| `assets/grain.png`, `Grain.tsx` | The web grain (Flutter uses `shaders/grain.frag`): a 256 × 256 tiling PNG of 8-bit greyscale luminance noise (Gaussian, mean 128, σ 0.5 × 128 clipped to 0–255, generated once by `design/make-grain.mjs`), ≈ 60 KB. Laid over art only as `background: url(grain.png) repeat; mix-blend-mode: overlay; opacity: 0.06` (0.05 where §8 says so), animated by a `background-position` jitter of `steps(4)` over 333 ms through four fixed offsets ((0,0), (−64,32), (48,−96), (−128,−16) px), which is 12 fps; static under reduced motion and paused off screen with the rest of the art (§15.6) |

Outside the skin folder (shared data layer, so both skins may use them): `frontend/src/features/reader/page-tint.worker.ts` (the 16 × 16 `OffscreenCanvas` sampler, created with `new Worker(new URL("./page-tint.worker.ts", import.meta.url))`, fed `ImageBitmap`s by the engine) and `frontend/src/app/(preview)/skin-preview/[skin]/{layout,page,preview-query}.tsx` (the edition preview route with its own root layout and query client, §8.30.3; both root layouts import `app/globals.css`; today's root moves to `app/(app)/layout.tsx`, every existing route folder with `error.tsx` and `not-found.tsx` moves under `app/(app)/`, Home is `app/(app)/page.tsx`, unmatched URLs reach the in-frame 404 through `app/(app)/[...missing]/page.tsx` calling `notFound()`, and `global-error.tsx`, `manifest.ts`, `favicon.ico` and the CSS files stay at `app/`, §15.10 S17) with its fixture copied by `design/build.mjs` to `frontend/src/skins/preview-feed.generated.json` and the covers to `frontend/public/skin-preview/covers/`, both committed, because the Docker build context is `./frontend`.

Packages (stack-decision §3, plus the two this contract adds; every package and its status is in the ledger, §15.11): `motion` 13.4.4 (reveals, springs, `Reorder`, layout), `@base-ui/react` 1.8.0, `embla-carousel-react` 8.6.0 (phone pagers only: Also in this issue, Library Continue, onboarding steps, The Annual; rails use native scroll-snap), `sonner` 2.0.8 (toast queue, unstyled), `lenis` 1.3.26 (desktop Tonight and Annual only), `@use-gesture/react` 10.3.1 (reader and Lightbox pinch), `@phosphor-icons/react` 2.1.10 (add it to `optimizePackageImports`; use `@phosphor-icons/react/ssr` in server components). No chart library, no carousel for rails, no cmdk.

View transitions (§8.0.4): `next.config.ts` adds `experimental: { viewTransition: true }` next to `proxyTimeout`, because Next 16.2.9 wires React `<ViewTransition>` and `<Link transitionTypes>` only with it (off by default). `transitionTypes` rides on `<Link>` and `router.push` (`["nav-forward"]` / `["nav-back"]`), never on `<ViewTransition>`; the page wrapper is `<ViewTransition default="none" enter={{…}} exit={{…}}>` mapping each type to its `mm-page-*` class; shared covers are `<ViewTransition name={coverTransitionName(sourceId, seriesKey)} share="mm-match-cut">`; popstate carries no type and gets `none`. The Column wipe and Iris are overlays that `await` their close before `router.push`, because they are not state-to-state morphs.

Home route (§8.0.3 `tonight`): `frontend/src/app/(app)/page.tsx` (Next 16 requires `/` inside a route group when there is no top-level `app/layout.tsx`) renders `skins[await getSkin()].screens.tonight`; until the flip the `next.config.ts` `/` → `/library` redirect stays for `legacy` only, skipped by a `missing` list that matches either the `mm-skin` or the `mm-skin-debug` cookie with the value `(cinematic|glass)`. This two-cookie condition replaces any single-cookie gate on that redirect; the flip release deletes `redirects()`.

Web app manifest (§12.3): the values go into `frontend/src/app/manifest.ts`; there is no static `manifest.webmanifest`. Set `start_url: "/"`, `id: "/"`, `short_name: "Maniacs"`, and `#000000` for `background_color` and `theme_color`. Delete `orientation: "portrait-primary"`, which would lock the installed Android PWA out of the landscape layouts of §8.0.9 and §8.14.1.

Service worker: the page posts `{ type: "skin", skin }` to `navigator.serviceWorker.controller` on every boot and `{ type: "skin-changed", skin }` on a switch (stack-decision §2.5 step 3, now with the skin). A worker has no `document.cookie` and cannot read `Cookie` from a navigation request, so it stores the value as the response of a `/__skin` request in a `mm-sw-meta` Cache Storage entry (a worker can be stopped at any time). On an offline navigation it serves `offline-fallback-{skin}.html`, chosen by the skin the page last posted to the worker, or `offline-fallback-cinematic.html` when nothing is stored.

### 15.3 Flutter (`mobile/lib/skins/cinematic/`)

| Path | Content |
|---|---|
| `tokens.g.dart` | Generated `cinematicTokens` (colours, `CineType` roles, curves such as `CineCurves.settle`, springs, grid) |
| `cinematic_skin.dart` | The `Skin` implementation: `ThemeData` built from the tokens (only for Material widgets the skin still uses), `buildRouter`, `splash`, `haptics`, `sounds` |
| `router.dart` | go_router routes for every ScreenId (and the mobile aliases), page builders: `SwipeablePage` (iOS, edge-only 20 pt, `transitionBuilder` painting Page or the finger-tracked slide by `isSwipeGesture`, 320 / 224 ms, 480 / 336 ms for match cuts) or `MaterialPage` under `CinePageTransitionsBuilder` (Android; `transitions.dart`, Page for button and programmatic navigation, the fade-through for predictive back) and `CineMatchCutPage` (Android match cuts, 480 / 336 ms) (§8.0.5); both readers use one `SwipeablePage` whose `transitionBuilder` paints the Column wipe, Dip or finger-tracked slide by the entry kind in `GoRouterState.extra` (§8.14.2); the branch table of §8.0.3 (`StatefulShellRoute.indexedStack` with a nested one for the Library hub); a custom route for the Iris (picker → shell) |
| `transitions.dart` | `CinePageTransitionsBuilder` and `CineMatchCutPage` (§8.0.5); `ZoomPageTransitionsBuilder` and `PredictiveBackFullscreenPageTransitionsBuilder` never ship |
| `shell.dart` | Thumb index, running head, toast overlay host, stop-press banner |
| `primitives/` | §7 components (`CineButton`, `SetHeading`, `TypedHeadline`, `CinePoster`, `CineRail`, `CineSheet`, pushed as `CineSheetRoute<T> extends PageRoute<T>` (`opaque: false`, `barrierColor: scrimModal`, `barrierDismissible: true`) in `primitives/sheet_route.dart` (§7.9), `CineDialog` over a custom `RawDialogRoute` with the Insert clip, …) |
| `screens/<cluster>/` | Screens by cluster: auth, profiles, tonight, library, feature, reader, novel, listen, discover, downloads, numbers, circle, settings, admin |
| `shaders/grain.frag` | The grain shader (`research/cinematic-language.md` §7.1), declared under `flutter: shaders:`; overlay blend on art only |
| `duotone.dart` | `ColorFilter.matrix` builder from `ambient.duo` |
| `tint.dart` (+ `test/skins/cinematic/tint_test.dart`) | Page-tint and Issue-stock derivations and the contrast test (§2.1.5) |
| `primitives/lightbox.dart` | §7.30 (`Hero` + `InteractiveViewer`) |
| `motion.dart`, `motion_timings.dart` | `CineMotion.play` and the Diagnostics overlay of §15.9 |

Outside the skin folder: `mobile/lib/features/reader/engine/page_tint.dart` (the 16 × 16 sampler run in `compute()`, exposing `pageTint` in `ReaderEngineState`); `mobile/assets/skin_previews/{cinematic,glass}/000–035.png` (the edition preview loops, §8.30.3), declared under `flutter: assets:`; `mobile/lib/app/app_restart.dart` and `main.dart` (the restart builder and `SkinBoot.read`, §8.30.3); `android/app/src/main/kotlin/…/MainActivity.kt` and `AndroidManifest.xml` (the `audio_service` wiring, §8.16.10). Fonts: the five reading faces of §3.4 are added to `pubspec.yaml` `fonts:` with their `OFL.txt` files.

Packages: `flutter_animate` 4.5.2 (rack focus, flicker, flame), `swipeable_page_route` 0.4.8, `custom_refresh_indicator` 4.0.2 (reprint), `flutter_reorderable_grid_view` 5.7.0 (manual order walls), `haptic_feedback` 0.6.5 + `gaimon` 1.5.0 (§5), `phosphor_flutter` 2.1.0, `flutter_soloud` 4.1.7 (UI sounds and voice samples: the sample's bytes are fetched with the app's authenticated HTTP client and loaded with `SoLoud.instance.loadMem`, so no header plumbing is needed), `share_plus` 12.0.2 (share cards), `audio_service` 0.18.19 (Listen lock screen), `sensors_plus` 7.1.0 (shake to extend the sleep timer, §8.16.6), `flutter_dynamic_icon_plus` 1.4.1, `flutter_launcher_icons` 0.14.4 and `flutter_native_splash` 2.4.8 (dev). Every package beyond the stack's pinned list is in the ledger (§15.11) with its resolution check. Cinematic uses the built-in `Hero`, `SpringSimulation` and `PageRoute` (for `CineSheetRoute`, §7.9); it does not use `heroine`, `motor`, `smooth_sheets`, `stupid_simple_sheet` or `liquid_glass_widgets` (those are Glass's). Native plugins (`gaimon`, `haptic_feedback`, `flutter_soloud`, `share_plus`, `audio_service`, `sensors_plus`, `flutter_dynamic_icon_plus`) land in one isolated commit with a CI iOS dry run and a CI `flutter build apk --release` (§15.11; stack-decision risk 9).

Scroll physics: `ClampingScrollPhysics` with `StretchingOverscrollIndicator` on both OSes, set once in the skin's `ScrollBehavior`.

### 15.4 Reader engine seam

The Cinematic reader chrome is a `chromeBuilder(context, ReaderEngineState)` returning the running head, folio bar, ruler, micro progress, auto-scroll chip, HUDs, credits and side panels. The engine exposes what the chrome needs: current page and chapter, page count, progress fraction, loaded neighbours, `nextState` (loading / ready / failed / none), bookmarks for the ruler, zoom, auto-scroll state and speed, `pageTint`, `panels` (guided view), and commands (seek, next, previous, toggle auto-scroll, set speed, zoom, bookmark). The engine also owns the next-chapter auto-queue (§8.14.11), so the strip and read-all entries share it. Web mirrors it with a `useReaderEngine()` hook in `features/reader/`. The engine already enforces the shared thresholds (hide 24 / show 56, 800 ms orientation, 3000 ms idle, preload at 70 %). This contract adds five engine duties, all skin-neutral so Glass can use them: **page tint** (reads `pages[].tint` from the manifest, otherwise samples the decoded page per §2.1.5 at most every 600 ms, applies the greyscale rules, exposes `pageTint` as a seed hex or null, and posts the chapter's samples on exit); **words on screen** (from `GET /ocr/chapter` boxes when the chapter has dialogue text, recomputed every 250 ms, for pace by dialogue, §9.4.1); **panel detection** (reads `pages[].panels` from the manifest or the local manifest copy, otherwise runs the §9.4.3 gutter rule one page ahead in the page-tint worker or a `compute()` isolate, exposes `panels`, and posts the chapter's rects on exit); **words per panel** (for the guided-view hold, §9.4.3); and **completion events** (`chapterCompleted`, which the skin uses to unseal guarded reactions, §9.3.3). The Cinematic skin only maps these values to chrome.

### 15.5 Backend additions this contract depends on

| Addition | For |
|---|---|
| `ambient: {duo, tint, ink} \| null` on every series payload, or null until the cover has been served once: computed only in the cover proxy's resize path (Pillow + colorsys next to cover resizing), the first time a cover URL is served at any width, and cached with it; list, search and browse endpoints never fetch a cover to fill it; WorldItem `ambient` from a background fetch of the AniList cover through the same extractor, limited to 20 per minute (§2.1.5) | Spreads, duotones, issue colours |
| `pages[].tint` (optional) in manifests, filled only from client reports: `POST /reader/page-tints {source_id, series_key, chapter_key, tints: [{page, hex}]}` → 204 (unknown pages are ignored), stored per page ETag; the image proxy does no image analysis | Page-tinted chrome cache (§2.1.5) |
| `backend/tests/test_ambient.py` | The `ambient.ink` ≥ 7:1 check over 360 hues (§2.1.5) |
| `POST /reader/progress/batch` items accept `manual: true` (saved without `record_session`, so no `ReadingSession`); `DELETE /reader/progress {source_id, series_key, chapter_keys[] ≤ 200}` → 204, profile-scoped | Mark read / Mark read up to here / Mark unread (§8.17) |
| `pages[].panels` (optional) in manifests, filled only from client reports: `POST /reader/panels {source_id, series_key, chapter_key, pages: [{page, panels}]}`, stored per page ETag; the image proxy does no image analysis (S11) | Guided view (§9.4.3) |
| `GET /home` (with the section types and `generated_at` of §9.1.7, the required `tz_offset_minutes` and `streak {current_days, longest_days, at_risk, last_active_date, milestones_seen}`, the `GET /library/statistics` streak object plus `at_risk`, reused by the `numbers` section item), `GET /ai/similar`, `GET /ai/recap/availability` (+ `recap` on `/home` `cover`, `continue` and `where_were_we` items and on `GET /library/continue-reading` rows), `GET /ai/recap` (SSE, framing in §9.1.7), `GET /ai/tags`, `POST /ai/feedback`, `PUT /profiles/{id}/taste` | §9.1, §8.17 |
| Streak milestones seen (`milestones_seen: [7, 30]` on the one streak object that `GET /library/statistics` and `GET /home` share, set by `POST /library/statistics/milestones/{days}/seen` → 204) | §9.2.2 milestone cards show once per profile |
| `/ocr/search` items gain `page` and `box {x, y, w, h}` (page fractions) of the first matching OCR box, or null | Subtitled stills in dialogue search (§8.24) |
| `POST /library/series/{followed_id}/repoint {source_id, series_key, keep_old: bool}` → `{followed: FollowedSeries, mapped_chapter_key, mapped_chapter_number \| null}` (`keep_old: true` keeps the old follow row and creates a new one; `false` repoints the row and fills the existing `migrated_from_*` columns; progress mapped by chapter number) | Move to another source (§8.17) |
| `GET /library/annual?year=&tz_offset_minutes=` (including the colophon's top series and top narration voices) | §9.2 |
| `shareable: {genre_weights, top_series, art_series}` on `GET /library/annual` and on the range payload behind The Numbers' `Share`, computed server-side only from series that are not mature (source not mature, and resolved rating not mature after `mature_override`) | Share cards never print a mature title, cover or genre (§9.2.5) |
| Per-profile composed caches: `/home` keyed by `(profile_id, mature_content_enabled, content_kind, …)`; `/library/annual` by `(profile_id, mature_content_enabled, year, tz_offset_minutes)` (mode-agnostic, §8.0.8); per-series caches (`/ai/similar`, `/ai/tags`, `/series/enrichment`) keep gating on serve | A gate change composes afresh with a valid cover story (§9.1.7, §9.2.7) |
| Every Circle-derived figure (Annual overlaps and `WITH`, `circle` and `circle_top` rails and counts, member-page rails and deck counts, reaction lists, `now`) computed at serve time from the member's shareable activity set S(member, viewer) | Circle privacy (§9.3.1) |
| Circle tables and endpoints (§9.3.8), with `now` (the §9.3.8 response shape) on `GET /circle/members` (18+ only when the member includes 18+ and the viewer's gate is open), plus `GET /circle/members/{profile_id}`, `GET /circle/feed` filters (`reading`, `reaction`), `GET /profiles/{id}/sharing`, `DELETE /circle/activity`, `GET /circle/series`, the `DELETE /circle/reactions` body, `409 recipient_unavailable`, and the shared-shelf fields and calls (`shared`, `shared_with_me`, member-readable detail rows with `title`/`cover_url`/`ambient`, `can_add` series adds, `DELETE …/share/me`, `added_by_profile_id` on shelf rows with the role-based series `DELETE`) | §9.3 |
| `reading_profiles.skin` (stack-decision §2.4) | Edition per profile |
| Collections gain `rules: null \| {all: [{field: "reading_status" \| "is_favorite" \| "new_count" \| "format" \| "content_kind", op: "eq" \| "gte" \| "in" \| "ne", value}]}` on `POST`, `PATCH` and both `GET`s (`smart` is `rules != null`); the server only stores them, membership is computed on the device | Smart shelves the same on every device (§8.11) |
| `GET /library/collections` list rows gain `preview_covers: [cover_url] (≤ 4)` (the first four member covers) and `preview_ambient_duo` | Collection plates without N detail calls |
| `tags` on `FollowedSeries` list rows; `GET /library/series` gains `tag_ids=` (any-of); `PATCH /library/tags/{id} {name?, color?}` | Tag filter and tag sheet on the shelf (§8.9) |
| `GET /library/series` gains `sort=last_read_at` / `-last_read_at`, `sort=-new_count` and `new_only=true`, evaluated server-side over the whole library | Library sorts `Recently read`, `Most unread` and the `NEW ONLY` filter beyond the 200-row page (§8.9) |
| `reading_profiles.notify_enabled` (bool, default true; `PATCH /profiles/{id}`); when false the update checker creates no notifications for that profile | Settings → Notifications per-profile master (§8.30.2 row 11) |
| `GET /series/enrichment?source&series` → `{anilist_id, format, score, official: [{site, url}]} \| null` (AniList match by title and alternate titles, cached 30 days, 18+ gated on serve) | Feature page DETAILS credits (§8.17) |
| `GET /home?content_kind=` and `also[]` (§9.1.7) | Tonight in novels mode (§8.0.8) and Also in this issue (§8.8) |
| `PUT /profiles/{id}/taste` accepts `step`; `GET /profiles` rows carry `onboarding_step` (migration sets `"done"` on existing profiles; new ones `NULL`) | Onboarding resume (§8.7) |
| `GET /onboarding/catalog?formats=&genres=&styles=` and `GET /ai/similar?anilist_id=`; `GET /home` falls back to the 3 healthiest non-18+ sources for a profile with 0 pins | Onboarding steps 2, 3, 5 and the new-profile Tonight (§8.7, §8.8) |
| `GET /library/annual` returns `available_years` | Previous Annuals (§9.2.1) |
| `POST /novels/listen-sessions` (array ≤ 200 of `{source_id, series_key, chapter_key, seconds, voice_ids[≤ 3], started_at}`) and `top_voices: [{voice_id, name, seconds}]` on `GET /library/annual` | The colophon's `NARRATED BY` (§9.2.4, §9.2.7) |
| `GET /novels/audio/series` gains `chapters[].rendered_at` and `cast_changed_at` (latest `POST /novels/cast`, `/novels/cast/alias` or `/novels/narrator` for the book); narrate requests accept `force` for narrated keys | Re-narration: `RE-VOICE` quick pick and `RE-VOICING` (§8.16.5, §8.16.8) |
| `PATCH /circle/letters/{id} {state: "read" \| "kept" \| "dismissed"}` | Letter `Keep` (§9.3.4) |
| `GET /app/soundscapes/{id}.{ext}` (public under `/app/*`): `id` one of `projector-room, rain-on-glass, night-city, cafe, night-wind, low-drone, afternoon-park, temple-bells`, `ext` `ogg` or `m4a`, read from `backend/media/soundscapes/` (env `MM_SOUNDSCAPES_DIR`, with `SOURCES.md`) through `FileResponse` (Range supported by Starlette 1.6.0), `Cache-Control: public, max-age=31536000, immutable`, anything else 404. The existing `/app/media/{name}` route serves screenshots only (one path segment, image suffixes) | §9.4.2 |
| `GET /app/fonts/{file}.woff2`: an allowlist of the Bodoni Moda and Archivo subsets from `backend/media/fonts/`, same caching, anything else 404 | Install page (§8.34) |

All gate 18+ on serve and scope by profile; none touches `backend/connectors/`.

### 15.6 Performance guards (flagship-only, still bounded)

- Grain and Drift run only on the one visible hero or spread art; both pause off screen (IntersectionObserver; `TickerMode`).
- At most one animated blur layer per screen outside letter reveals and Rack focus; Rack focus runs on at most 12 images at once (the rest Develop, §4.5); letter reveals are per letter at every length (no cap): their stagger is capped at 560 ms, so a heading's blur layers all finish within 1.2 s, and each drops once it is under 0.05 σ (§10.1).
- Duotone filters are cached per colour; spreads request covers at 720 px and never upscale sharp art (`blur.bleed` covers the rest).
- The reader never runs grain, blur, drift or backdrop effects over pages; its chrome is gradients and text only.
- Page-tint sampling at most every 600 ms, off the main thread (a Web Worker with a transferred `ImageBitmap` on the web, a `compute()` isolate on a 16 × 16 decode in Flutter), so the shared VPS image proxy does no colour work; panel detection (§9.4.3) shares that worker or isolate at 360 px wide, one page ahead, so the proxy does no panel work either; ambient colour transitions are CSS registered properties, which transition on the main thread, so they are set only on the few elements that paint them (§2.1.5), or single `TweenAnimationBuilder`s.
- The trailer scrub animates `transform` and `opacity` only (web) or relayouts one pinned sliver header (Flutter); on the web the running head's height change is a `scaleY` on its background, not a layout change.
- Edition preview iframes mount only while Settings → Appearance or onboarding step 1 is on screen, and unmount on leave.
- The Lightbox decodes the full cover only on open; Cut to home flies at most 12 posters (picks beyond 12 appear with the rail's normal Set).
- **One request limiter for the sources bucket** (the server allows 60 requests/min per IP across `/sources/*`, covers and page images included). One limiter per client in the shared data layer (`frontend/src/features/sources/`, `mobile/lib/core/network/`), so Glass inherits it. A sliding window of 50 request starts per 60 s (a log of start times; each slot frees 60 s after the request that took it), floor 0; a "token" below means a free slot in that window. (A refilling bucket of capacity 50 would admit up to 99 starts in one 60 s window and trip the server's 60/minute limit.) Priorities: **P0** the visible reader page and the next one; **P1** user-initiated lists (browse, search, series, chapters); **P2** covers in view; **P3** prefetch (hover or focus manifests and pages, first rows, the next chapter's manifest, novel chapters, dialogue crops, preview slates). Rules: P0 and P1 never wait on the local bucket, they only consume from it (the server enforces the real limit, and prefetch is what must yield); P2 waits for a token; P3 runs only while at least 20 tokens remain, with at most 2 requests in flight; hover prefetch starts after a 150 ms dwell; on the web, gated images get their `src` assigned only when a token is granted; responses served from a local cache (HTTP cache, Cache Storage, image cache, sqflite) cost nothing; on any 429, P2 and P3 pause for `Retry-After` and P0 retries after it.
- Rails virtualise beyond 30 items; walls use `@tanstack/react-virtual` (installed) / `SliverGrid`.

### 15.7 Accessibility checks per cluster

- Contrast: `ink.45` text only on `paper.0`; on `paper.1`–`paper.4`, mood grades and tinted fields the raised-stock scope renders it `ink.60` (§2.1.1, §14.2), checked by the surface × ink loop in the `tint` tests and by inspecting every sheet, menu, dialog and plate; `ink.30` never carries information.
- Over art: the over-art table in the `tint` tests (§2.1.4) lists every (component, ink, ground alpha at the text line) and composites each row over `#FFFFFF` and `#F5F547` (≥ 4.5:1; ≥ 3:1 for large text and icons). The table includes the World card's dismiss and More-like-this buttons, the Lightbox close, caption, folio, zoom chip and `+` `−` `Fit` buttons, the reader zoom chip, the brightness and auto-scroll HUD values, the new-chapter caption and the guided-view whole-page folios (all on the folio-flag ground or `on-art`, §2.1.4). Rows: running head and folio bar over `scrim.head` / `scrim.sole` (`ink.60`, `spot`, `ink.100`; each at text scale 1.0 and at the largest scale, with the 44 px iOS and 48 px Android running head, so a grown bar is checked on its flat part), the same running head and folio bar with page-tinted chrome on at the most saturated `page.tint` (S 0.35, L 0.06, §2.1.5), every `scrim.foot` text block on its solid end colour (`scrim.foot.black` carries no text), poster and World card badges on their `#000000` fill, the rating card on `paper.0`, the Coming up band at 0.84, the Listen full player on its 15 % duotone field, and the `on-art` controls on their `color.onart` fill (`ink.100` at 0.64: the recap's `Skip recap →` on the cover band, The Annual's phone close `x` and page buttons). Also check each on a white page and a white cover with the focus ring on an on-art control (the black halo must show). On the web the Playwright screen tests also assert that the computed `background-image` of the running head's and folio bar's `::before`, the Listen transport's `::before` and every `scrim-foot` element is not `none` (an unresolved `var()` in a scrim fails silently, §2.8).
- 18+ badges: with the gate open, a World card shows the 16 px certificate when `is_adult` is true or any `available[]` source is mature; with it closed, the item is absent (§7.6).
- 18+ on the device: with a profile that has downloads, bookmarks and offline follows of a mature series, close the gate and check that Downloads, Library (offline), Tonight's offline edition, Bookmarks, search and every badge show none of it and say nothing about it; reopen the gate and check it all returns.
- Focus order follows the grid's reading order; every screen reachable by keyboard on web and with a hardware keyboard on iPad.
- Every icon-only control has a label and a tooltip; every gesture has a visible alternative (§8.14.10, §7.16).
- Screen readers: letter and typing reveals expose the full text; the reader announces chapter changes but not page changes; auto-hide timers, toast timeouts, the recap countdown and every auto-advance stop while a screen reader is active (§14.5).
- Reduced motion: every item in §4.8 verified by toggling the OS setting.
- Text scale: every screen checked at 1.0, 1.3 and 2.0 (§3.3) on both phones, and with Hyperlegible text on, OS Bold Text on and Increase Contrast on (§14.4, §14.7); nothing clips or truncates (every §7 height is a minimum).
- Destructive confirms: each one checked for the 1000 ms arm (a double tap on its trigger must not confirm).
- Spoiler guard: reactions checked on an unread, a half-read and a finished chapter.

### 15.8 Verification

Per cluster, on both clients: the completeness test (`ScreenId` coverage), the import-boundary test and lint rule, one smoke test per screen, Playwright screenshots of the web phone and desktop layouts with the grid overlay on and off, the Flutter screenshot harness at phone and tablet sizes, and a device pass on the owner's iPhone (SideStore) and the Android flagship for the Column wipe, the Iris, the trailer scrub, Cut to home, the Lightbox, the reader at 120 Hz with page tint on, the Listen highlighter, and a desktop Library wall and a Discover results page at first load (the Rack focus cap); on the iPhone, the pass also logs `AVAudioSession.sharedInstance().category` right after `SoLoud.instance.init()` and after a `Hear` sample ends, and both must read `.ambient` (State A, §6); if they do not, `skin_audio.dart` re-applies State A after init (§6). Each move is checked with the motion-timings overlay on (no move may show dropped frames or run more than one frame over its planned duration). The `tint` tests (web, Flutter, backend) run in the normal test suites, including the shared `design/tint-vectors.json` parity cases (§2.1.5) and the `design/panel-vectors.json` guided-view cases (`panels.test.ts`, `panels_test.dart`, §9.4.3), and `set_heading_test.dart` (§10.1.6) runs with the Flutter suite. The device pass also switches editions in both directions (once Glass exists) with the overlay on: the `SKIN RESTART` entry must stay under 1,500 ms. The edition preview frames are regenerated by the screenshot harness whenever either skin's Tonight changes. `next build` before any push, one heavy command at a time on the dev box.

### 15.9 Motion-timings overlay

A diagnostic that makes every named move measurable on the device, next to the layout-grid overlay (§2.2.2).

- **Where**: Flutter: Settings → Diagnostics → "Show motion timings" (any build, per device, off after restart). Web: `mod+shift+m` in development builds only.
- **What it logs**: every call to `play(name, …)` / `CineMotion.play` (all names in §4.5) records the name, planned duration, start timestamp and frame, end timestamp and frame, frames rendered and dropped frames (web: `requestAnimationFrame` deltas over 1.5 × the display's frame interval, measured with `performance.now()`; Flutter: `SchedulerBinding.addTimingsCallback` `FrameTiming`s whose build + raster time exceeds the frame budget at the current refresh rate).
- **What it shows**: a 320 px wide panel pinned bottom-left at `z.debug`, `paper.2` at 92 % with a 1 px `rule.2` border, the last 20 moves as rows in IBM Plex Mono 11/16: `COLUMN WIPE   872 → 880 MS   53/53 F   0 DROP`. A row turns `proof` when the actual duration exceeds the planned one by more than one frame or any frame dropped, and `set` when on time. Scroll-linked moves (the trailer scrub) log frames and drops per gesture instead of a duration. `Clear` and `Copy log` (JSON to the clipboard) sit in its header.
- **`SKIN RESTART`**: the one entry that spans a restart. Stop the press writes the confirm timestamp (`mm.skin.t0`: `sessionStorage` on the web, SharedPreferences in the app) before restarting; the incoming skin's splash reads and clears it on its first frame and logs `SKIN RESTART  confirm → first splash frame  1,212 MS` against a 1,500 ms budget (`proof` above it). Because the overlay does not survive the restart, the incoming skin's recorder logs the entry even when the overlay is off (it costs one read), and shows it when the overlay is next opened.
- **Also**: each entry is mirrored to the console (web `console.table`, once per move) and to `debugPrint` (Flutter), so a remote session can read it from `flutter logs` or the browser console.
- **Cost**: the recorder is a ring buffer of 200 entries; when the overlay is off, `play` skips recording entirely.

### 15.10 Amendments to `stack-decision.md` and owner calls

Where this contract departs from, or fills a hole in, the stack decision, it says so here, so neither document is silently wrong. Amendments marked **sign-off** wait for the owner before the cluster that needs them; the rest are clarifications that conform to the stack as written.

| # | Stack section | What this contract does | Status |
|---|---|---|---|
| S1 | §2.6 item 2 ("per-cover and per-page dynamic palettes" on the backend) | Cover `ambient` stays on the backend. Per-page tint runs on the client (§2.1.5), because the VPS image proxy must not analyse pages and the client already has the decoded page; parity between the two clients is enforced by the shared `design/tint-vectors.json` cases run by both test suites; the backend only caches client reports | **sign-off** before the reader cluster |
| S2 | §2.1 token format | Adds the `scalar` kind (`{value, unit}`), allows a curve without `ms` (durations live in `dur.*`), and adds haptic sequences `[first, {after, then}]` (§15.1). The utility-name check lives in `design/lint-utilities.mjs`, so `build.mjs` stays at about 150 lines | amendment; generator change only |
| S3 | §2.1 "the web maps them to nothing" | The web haptics file maps five events to `navigator.vibrate` on Android Chrome (§5) and every other name to nothing | amendment |
| S4 | §2.5 step 4 (Cinematic outgoing: 500 ms) | Stop the press is 500 ms (§8.30.3), with a `SKIN RESTART` measurement against the 1.5 s budget (§15.9) | conforms |
| S5 | §2.4 (per-device override "one more key read before step 2") | The pre-flip debug row uses that hook (`mm-skin-debug` / `mm.skin.debug`) and is deleted at the flip (§8.0.7) | conforms |
| S6 | §2.4 (the `mm-skin` cookie holds no profile data) | `data-legible` and `data-motion` are not server-stamped; `appearance-boot-source.ts` stamps them before paint from scoped `localStorage` (§3.4, §14.1). No second cookie | conforms |
| S7 | §2.2 (`screens satisfies Record<ScreenId, Screen>`) | App-only `setup` and web-only `readerLanding` are registered as redirects on the other client, so one `SCREEN_IDS` list stays complete (§8.0.3) | conforms |
| S8 | §2.1 `contract.json` | Gains `flags.glass_available` (§8.0.7) and the sound-only events `sheet.open` and `splash.reveal` (§6) | addition |
| S9 | §3 "Dependency changes" | Adds the packages marked *added here* in §15.11, each gated by the resolution check there | addition |
| S10 | §4 #12 (Cinematic, then new features, then Glass) | Specifies what every edition surface does before Glass exists (§8.0.7) | conforms |
| S11 | §2.6 item 2 ("panel boxes for the guided view" on the backend) | Panel detection runs on the client (§9.4.3), for the same reason as S1: the shared VPS image proxy must not decode and analyse every page; it also gives downloaded chapters guided view offline. Parity between the two clients is enforced by `design/panel-vectors.json` run by both test suites; the backend only caches client reports (`POST /reader/panels`, `pages[].panels`) | **sign-off** before the reader cluster |
| S12 | §2.4, §2.5 | The skin `PATCH` is awaited on the web before the restart (1,000 ms timeout, then the switch is undone with an error toast), and a queued outbox `PATCH` wins over the server's `profile.skin` at boot on mobile (§8.30.3) | amendment |
| S13 | §2.1 motion-token mapping | Flutter springs use `ms × 1.2` so they match Motion's `visualDuration`; the CSS spring pair is a `linear()` curve plus its settle time, generated by a stdlib port of Motion's spring and tested against the installed `motion` (§2.8.4) | amendment; generator change only |
| S14 | §3 "native channels kept in place" | `MainActivity` now extends `AudioServiceActivity`; the manifest gains the `AudioService` service, the `MediaButtonReceiver` and the two foreground-service permissions; `AudioService.init` runs once in `main()` (§8.16.10) | amendment |
| S15 | §2.3, §2.5 step 5 | `AppRestart` rebuilds its child from a builder that re-reads `SkinBoot` and feeds the return route into `initialLocation`, because a key swap does not re-run `main` (§8.30.3) | amendment |
| S16 | §2.1 outputs, §2.3 tokens | The generator also writes `frontend/src/skins/theme.generated.css` (the shared `@theme inline` and `@utility` block); the Dart output per skin is a `ThemeExtension` (`CineTokens`, and `GlassTokens` later) plus the `static const` classes of §2.8, and the stack's shared `SkinTokens` type is not used | amendment; generator change only |
| S17 | §2.2 web folder layout (`app/` thin route files) | The thin route files sit under two root layouts, `app/(app)/` (every existing route, Home at `app/(app)/page.tsx`, `error.tsx`, `not-found.tsx`) and `app/(preview)/` (the edition preview), with no top-level `app/layout.tsx`, and both import `app/globals.css`; unmatched URLs reach the in-frame 404 through `app/(app)/[...missing]/page.tsx` calling `notFound()`, not through `experimental.globalNotFound`, which bypasses layouts (§8.30.3, §8.32) | conforms |

**Owner calls** (decided here so nothing blocks, reversible in one line each):
- *Circle reciprocity*: a profile that shares nothing can still see what sharing profiles share (§9.3.2). The alternative, "see only if you share", is one server check in `GET /circle/feed` and `GET /circle/members`.
- *Home-screen label*: `Maniacs` under the icon (§12.3); "ManhwaManiacs" everywhere the full name fits.
- *Per-page tint placement*: S1 above. *Panel detection placement*: S11 above.

### 15.11 Dependency ledger

Every package the Cinematic skin uses beyond what the clients already have. **Status**: *stack* = in `stack-decision.md` §3's pinned list; *added here* = this contract adds it. **Resolution check**: before the first cluster that needs an *added here* Flutter package, the isolated dependency commit must pass CI's `flutter pub get` and `flutter analyze` on Flutter 3.44.6 with `go_router` ≤ 17.5 (the stack's constraint) plus the iOS dry-run build and an Android build: a `flutter build apk --release` job in `.github/workflows/tests.yml` (a GitHub runner, never the dev box; with no `key.properties` it builds unsigned, which is enough for the check), run in the isolated native-plugin commit and after any change to `pubspec.yaml` or `android/`. Today an APK is built only by `ops/vps/push.sh` at release time, so an NDK or manifest break in `flutter_soloud`, `audio_service` or `flutter_dynamic_icon_plus` would otherwise first show up there. Web packages must pass `npm ci` and `next build` in CI. A package that fails is replaced by the fallback in its row, never force-resolved.

| Package | Version | Licence | Kind | Why | Status | Fallback if it fails |
|---|---|---|---|---|---|---|
| `motion` | 13.4.4 | MIT | pure JS | Reveals, springs, `Reorder`, view-transition glue | stack | — |
| `@base-ui/react` | 1.8.0 | MIT | pure JS | Unstyled Dialog, Drawer, Menu, ContextMenu, Popover, Tabs, Switch, Slider, Checkbox, Radio, ToggleGroup | stack | — |
| `embla-carousel-react` | 8.6.0 | MIT | pure JS | Phone pagers: Also in this issue, Library Continue, onboarding steps, The Annual | stack | — |
| `sonner` | 2.0.8 | MIT | pure JS | Toast queue (unstyled) | stack | — |
| `lenis` | 1.3.26 | MIT | pure JS | Smooth wheel on desktop Tonight and The Annual | stack | Native scrolling |
| `@use-gesture/react` | 10.3.1 | MIT | pure JS | Pinch and drag in the reader and the Lightbox | added here | Pointer-event code in `features/reader` (about 120 lines) |
| `@phosphor-icons/react` | 2.1.10 | MIT | pure JS | The icon set (§2.7) | added here | The Phosphor SVGs copied into `skins/cinematic/icons/` |
| `@tanstack/react-virtual` | installed | MIT | pure JS | Walls and long lists | already installed | — |
| `flutter_animate` | 4.5.2 | BSD-3-Clause | pure Dart | Rack focus, flicker, flame (not the heading reveal, §10.1.6) | stack | Plain `AnimationController`s |
| `swipeable_page_route` | 0.4.8 | MIT | pure Dart | iOS edge-only back swipe | stack | `CupertinoPageRoute` |
| `haptic_feedback` | 0.6.5 | BSD-3-Clause | native | Named impacts (§5) | stack | `HapticFeedback` from `services` |
| `gaimon` | 1.5.0 | MIT | native | AHAP signature patterns (§5) | stack | Named impacts only |
| `phosphor_flutter` | 2.1.0 | MIT | pure Dart (font asset) | The icon set (§2.7) | added here | The Phosphor TTF bundled with a generated `IconData` class |
| `flutter_soloud` | 4.1.7 | MIT | native (C++ FFI) | UI sounds and voice-sample RMS (§6, §8.16.5). 5.x needs `native_toolchain_c ^0.19.4`, which needs `meta ^1.19.0`, and Flutter 3.44.6 pins `meta` 1.18.0. 5.0 also removed `AudioData`. Revisit with the Flutter upgrade (stack risk 10) | added here | `just_audio` (installed) for cues; the voice pulse becomes the static band |
| `audio_service` | 0.18.19 | MIT | native | Listen lock screen and notification (§8.16.10) | added here | Foreground-only narration (today's behaviour) |
| `share_plus` | 12.0.2 | BSD-3-Clause | native | Share cards (§9.2.5). 13.x needs `win32 ^6`. `package_info_plus` 8.x, `file_picker` 8.x and `flutter_secure_storage` 9.x pin `win32 ^5`, so move to 13.x only together with their win32-6 majors | added here | Save to the app's documents folder with a toast |
| `sensors_plus` | 7.1.0 | BSD-3-Clause | native | Shake to extend the sleep timer (§8.16.6) | added here | Drop shake to extend (the sleep sheet stays) |
| `flutter_dynamic_icon_plus` | 1.4.1 | MIT | native | Per-skin app icon (§12.3) | added here | One icon for both skins |
| `custom_refresh_indicator` | 4.0.2 | MIT | pure Dart | Pull to reprint (§7.29) | added here | `RefreshIndicator` with a custom painter |
| `flutter_reorderable_grid_view` | 5.7.0 | BSD-3-Clause | pure Dart | Manual order in poster walls (§7.16) | added here | List-mode reordering only |
| `flutter_launcher_icons` | 0.14.4 | MIT | dev only | Icon generation (§12.3) | added here | Hand-exported icon sets |
| `flutter_native_splash` | 2.4.8 | MIT | dev only | The black native launch frame (§8.2) | added here | Hand-edited `LaunchScreen.storyboard` and `styles.xml` |
| `fantasticon` (npm) | 4.1.0 | MIT | dev only (needs Node ≥ 22, which this box has; run with `npx` from `brand/` scripts) | Custom glyph TTF for Flutter (§2.7) | added here | The ten glyphs as `CustomPainter`s drawn from their SVG paths |
| `@resvg/resvg-js` (npm) | 2.6.2 | MPL-2.0 | dev only (run with `npx` from `brand/` scripts) | SVG → PNG exports of the brand masters (§12.7) | added here | Hand-exported PNGs |
| `sox` (system tool) | 14.4.2 | GPL-2.0 (tool only; its outputs are committed, nothing links it) | authoring only | Synthesised soundscape loops (§9.4.2) and UI cues (§6) | added here | None needed at runtime (the committed files stay); a regenerated file may come from any synthesiser, with its command line recorded in `SOURCES.md` |

---

## Appendix A. Graft ledger

The contract is `concepts/cinematic-3.md` ("Programme") plus these grafts. Every graft is written into the sections named; this table is for traceability only.

| Graft | From | Written into |
|---|---|---|
| Client-side page tint as the primary path (16 × 16 `OffscreenCanvas` in a worker; 16 × 16 decode in Flutter; 600 ms throttle; previous colour kept on greyscale pages; cover colours after 6 grey pages); server `pages[].tint` kept as a cache filled from client reports | cinematic-1 §2.1.4, §5.4.4, §9.2 | §2.1.5, §9.4.4, §9.4.5, §15.2, §15.3, §15.5, §15.6 |
| The runnable contrast check (≥ 4.5:1 on `#000` across 360 hues), applied to `page.light`, `ambient.ink` (≥ 7:1) and the Issue stock | cinematic-1 §9.2 (`page-tint.test.ts`) | §2.1.5, §2.1.6, §15.8 |
| Reaction spoiler guard ("reacted to Ch. 212" until the chapter is finished), with the unseal on completion | cinematic-1 §5.3.3 | §9.3.3, §8.14.6, §8.14.12, §9.3.2, §7.16 (schedule rows) |
| Five novel faces (Newsreader, Literata, Source Serif 4, Atkinson Hyperlegible Next, Archivo as the sans), Atkinson as the Hyperlegible text option, and the cover-tinted seventh stock (named **Issue** here; cinematic-1's "Key") | cinematic-1 §4.16 | §3.4, §2.1.6, §8.15.5, §8.30.2 |
| Lightbox for covers and cover-story art (long-press or double-click, contain fit, pinch to 4×, drag down to dismiss), square and without bloom; also used for reader pages | cinematic-1 §3.29 | §7.30, §8.8, §8.14.13, §8.17, §8.18 |
| Column wipe only when entering from Tonight or a feature or book page; Dip from History, Bookmarks, Updates, Downloads, dialogue results and everywhere else | cinematic-1 §8 moment 4 | §8.0.4, §8.14.2, §4.5, §13 (moment 4) |
| "Cut to home": the onboarding picks fly into Tonight's first section, 60 ms apart | cinematic-1 §4.7 scene 3 | §8.7, §8.8, §4.5 |
| Voice sample pulses with the audio RMS, drawn as a highlighter band (no bloom) | cinematic-1 §4.17.4 | §8.16.5, §4.5 |
| "The Circle lights up": the reading-now ring in the series' `ambient.duo` | cinematic-1 §5.3.2, §8 #17 | §7.25, §9.3.2, §15.5 |
| Never auto-skip the profile picker, even with one profile (it is the skin gate) | cinematic-1 §4.5 | §8.5 |
| X-Ray subtitle stills merged into dialogue-search transcript blocks (highlighter kept) | cinematic-1 §4.24 | §8.24, §15.5 |
| "Scrub the trailer": the cover story compresses into a 64 px now-showing strip with the split `Continue │ CH 143` | cinematic-2 §4.8 | §8.8, §4.1, §4.5 |
| Pace by dialogue (`speed × clamp(1.2 − words/60, 0.5, 1)`, speed normalised to a 1080 px viewport) and the panel hold (1.2 s + 0.25 s per word, cap 6 s) | cinematic-2 §5.4.1, §5.4.3 | §9.4.1, §9.4.3, §8.14.8 |
| "Previously on": Skip recap from t = 0, a 12 s countdown after streaming (paused on touch, hover and focus), and the three-way setting | cinematic-2 §5.1.3 | §9.1.5, §8.30.2 |
| Streak tiers (ember dot, one tongue, three tongues, ring at 30, sparks at 100), milestone title cards at 7/30/100/365 with share, the at-risk Home headline after 20:00 (no push) | cinematic-2 §5.2.2 | §9.2.2, §9.1.2, §8.8, §2.7 (glyphs) |
| The Annual's end credits as a colophon page before the press run | cinematic-2 §5.2.3 scene 10 | §9.2.4, §9.2.7 |
| Tonight sections `Almost there`, `Where were we?` and `Sent to you` (typed note) | cinematic-2 §5.1.2 | §8.8, §9.1.7 |
| 1000 ms arm delay with a filling `proof` rule on every ordinary destructive confirm | cinematic-2 §3.15 | §7.10, §4.5, §14.1 |
| Live edition previews: web `/skin-preview/{skin}` iframe, app PNG loop, respecting the import boundary (cinematic-1 §4.26's in-process render of the other skin was not taken) | cinematic-2 §4.28.2 | §8.30.3, §8.7, §15.2, §15.3 |
| "Show motion timings" overlay | cinematic-2 §9.6 | §15.9, §8.30.7, §2.2.2 |
| "Feel it" haptic sample | cinematic-2 §4.28.4 | §5, §8.30.2 |
| Per-control scope column in reading setup | cinematic-2 §4.13 | §8.14.8 |
| AI state vocabulary (thinking, unavailable, partial, stale with `PICKED 3 DAYS AGO`) as the shared contract | cinematic-2 §5.1.5 | §9.1.8, §7.19 |

**Adapted, not copied.** Flutter page sampling reads the 16 × 16 `ResizeImage` decode's raw pixels through the same picker as the web instead of calling `ColorScheme.fromImageProvider`. In Flutter 3.44.6 that API scores colours with `Score.score`, which returns Google blue `#4285F4` for an image with no chromatic colour, so black-and-white manga pages would tint the chrome blue. The sample is 16 × 16 on both clients (not the graft's 64 px, so `design/tint-vectors.json` matches both clients' real input, §2.1.5); the 600 ms throttle and the client-side placement are as grafted.

---

## Appendix B. Coverage

One row per screen of `inventory/web.md` (32 screens: R1–R27, R17n, E1–E4) and `inventory/mobile.md` (34 screens: S01–S34), then the new-feature screens and the surfaces this contract adds. "Specified in" is the section that owns the screen's layout, states and keys; the tablet and landscape rules for every screen are in §8.0.9, the content-mode rule in §8.0.8, the not-available state in §8.0.10, and the 18+ device-side filter in §7.24.

**Web inventory**

| Inventory screen | ID | ScreenId / route | Specified in |
|---|---|---|---|
| Login | R1 | `login` `/login` | §8.3 |
| Register | R2 | `register` `/register` | §8.4 |
| Profile picker | R3 | `profiles` `/profiles` | §8.5 |
| Manage profiles (and the profile form dialog) | R4 | `profilesManage`, `profileNew`, `profileEdit` | §8.6 |
| Library (followed shelf; its home role passes to Tonight) | R5 | `library` `/library` | §8.9 (home: §8.8) |
| Browse all | R6 | `library` `/library/browse` (toolbar open) | §8.9 |
| Followed series detail | R7 | `featureByFollow` `/library/:followedId` | §8.17 (manga), §8.18 (novel), §8.19 |
| Collections | R8 | `collections` | §8.11, §9.3.5 |
| Collection detail | R9 | `collection` | §8.11, §9.3.5 |
| Reading history | R10 | `history` | §8.12 |
| Bookmarks | R11 | `bookmarks` | §8.13 |
| Find something to read | R12 | `picks` `/library/recommendations` | §9.1.3 (§8.25) |
| Reading statistics | R13 | `numbers` `/library/statistics` | §9.2.1, §9.2.2 (§8.26) |
| Global search | R14 | `discover` `/search` | §8.20 |
| Sources | R15 | `sources` | §8.21 |
| Source catalogue | R16 | `source` `/sources/:sourceId` | §8.22 |
| Source series detail (manga) | R17 | `feature` | §8.17, §8.19 |
| Book page (novel series) | R17n | `feature` (novel `content_kind`) | §8.18, §8.19, §8.16.8 |
| Reader landing | R18 | `readerLanding` `/reader` | §8.32 |
| Manga reader | R19 | `reader` | §8.14 (all subsections), §9.4 |
| Read-all reader | R20 | `readAll` | §8.14 (read-all divider §8.14.5, ruler §8.14.4) |
| Novel reader (with Listen) | R21 | `novel` | §8.15, §8.16, §9.4 |
| Updates | R22 | `updates` | §8.10 |
| Downloads | R23 | `downloads` | §8.23 (desktop and mobile web layouts) |
| OCR search | R24 | `dialogue` `/ocr` | §8.24 |
| More hub | R25 | `index` `/more` | §8.28 |
| Settings (every panel) | R26 | `settings` `/settings/:section` | §8.30.1–§8.30.7 |
| System status | R27 | `status` `/admin/status` | §8.31 |
| 404 | E1 | — | §8.32 |
| Route error | E2 | — | §8.32 |
| Root error | E3 | — | §8.32 |
| Offline fallback page | E4 | `/offline-fallback.html` | §8.32 |
| Global overlays: command palette, shortcuts dialog, new-chapters banner, app-update prompt, first-run banner, reader bookmark notice | §2.6–§2.8 | — | §8.33.1, §8.33.2, §8.33.3, §8.29, §8.33.4, §8.14.11 / §8.15.7 |

**Mobile inventory**

| Inventory screen | ID | ScreenId / route | Specified in |
|---|---|---|---|
| Setup | S01 | `setup` `/setup` | §8.1 |
| Splash | S02 | — (boot) | §8.2, §12.4 |
| Login | S03 | `login` | §8.3 |
| Register | S04 | `register` | §8.4 |
| Profile picker | S05 | `profiles` | §8.5 |
| Add profile | S06 | `profileNew` (alias `/profiles/create`) | §8.6 |
| Edit profile | S07 | `profileEdit` (alias `/profiles/edit/:id`) | §8.6 |
| Library home (its home role passes to Tonight) | S08 | `library` | §8.9 (home: §8.8) |
| Library browse | S09 | `library` `/library/browse` | §8.9 |
| Series detail (library) | S10 | `featureByFollow` | §8.17, §8.18, §8.19 |
| Recommendations | S11 | `picks` | §9.1.3 |
| Statistics | S12 | `numbers` | §9.2.1, §9.2.2 |
| Reading history | S13 | `history` | §8.12 |
| Bookmarks | S14 | `bookmarks` | §8.13 |
| Manga reader | S15 | `reader` (alias `/library/read/…`) | §8.14, §9.4 |
| Sources | S16 | `sources` | §8.21 |
| Source browser | S17 | `source` | §8.22 |
| Source series detail (manga and novel bodies) | S18 | `feature` | §8.17, §8.18, §8.19 |
| Source reader | S19 | `reader` (alias `/sources/…/chapters/:chapterId/read`) | §8.14 |
| Search | S20 | `discover` | §8.20 |
| Downloads | S21 | `downloads` | §8.23 |
| More | S22 | `index` | §8.28 |
| Updates | S23 | `updates` | §8.10 |
| Collections | S24 | `collections` (alias `/collections`) | §8.11 |
| Collection detail | S25 | `collection` (alias `/collections/:id`) | §8.11 |
| Novel reader, with sheets N1 Type, N2 Contents, N3 Audiobook, N4 Voices | S26 | `novel` (alias `/novels/read/…`) | §8.15 (N1 §8.15.5, N2 §8.15.6), §8.16 (N3 §8.16.8, N4 §8.16.5) |
| Dialogue search | S27 | `dialogue` (alias `/ocr/search`) | §8.24 |
| Settings | S28 | `settings` | §8.30.1, §8.30.2 |
| Password & security | S29 | `settings` `/settings/security` | §8.30.4 |
| Members | S30 | `settings` `/settings/members` | §8.30.5 |
| Theme gallery | S31 | — | Removed by decision (dark only, no palettes): §8.30.2 note; its place is the edition picker, §8.30.3 |
| Storage | S32 | `downloads` `?tab=storage` and `/settings/storage` | §8.23 (STORAGE tab), §8.30.2 row 07 |
| Backup & restore | S33 | `settings` `/settings/backup` | §8.30.6 |
| Diagnostics | S34 | `settings` `/settings/diagnostics` | §8.30.7, §15.9, §8.0.7 (debug edition row) |
| Shared sheets: M1 series actions, M3 reading mode, M4 What's new, M5 Save to Files, M8 collection dialogs, M9 confirmations; G9 app update | §3 G13, G9 | — | §7.22 (Quick look), §7.29, §8.29, §8.23, §8.11, §7.10, §8.28 / §8.29 |

**New-feature screens and surfaces added by this contract**

| Screen or surface | Feature | ScreenId / route | Specified in |
|---|---|---|---|
| Onboarding: the first issue | AI home (taste) | `onboarding` `/welcome?step=1..5` (`2..5` while `glass_available` is false) | §8.7, §8.0.7 |
| Tonight (home) | AI home | `tonight` `/` | §8.8, §9.1.2, §9.1.6, §8.0.8 (novel cover story) |
| Picks (ask, For you, Because you read) | AI recommendations | `picks` | §9.1.3, §9.1.8 |
| More like this / Because you read rails | AI recommendations | feature tab `03` | §9.1.4 |
| Previously on (recap takeover) | AI recap | `recap` `/recap/:sourceId/:seriesKey` | §9.1.5 |
| Suggested tags | AI | feature aside | §8.17, §9.1.8 |
| The Numbers | Stats | `numbers` | §9.2.1 |
| Streak flame and milestone title card | Streaks | title card: root-navigator overlay route (web `?view=milestone`) | §9.2.2, §8.0.3 |
| The Annual | Wrapped recap | `annual` `/library/statistics/annual/:year` | §9.2.4 |
| Press-run sheet (share cards) | Stat cards | sheet / dialog | §9.2.5 |
| Circle | Social | `circle` | §9.3.2 |
| Member page | Social | `circleMember` `/circle/:profileId` | §9.3.7 |
| Reactions (credits, schedule rows, CIRCLE panel) | Social | — | §9.3.3, §8.14.6, §8.14.12 |
| Pass it on sheet and letters | Social | sheet | §9.3.4, §7.6 (Letter) |
| Shared shelves (share sheet, permissions) | Social | sheet | §9.3.5, §8.11 |
| Settings → Circle & privacy | Social | `/settings/circle` | §9.3.6 |
| Auto-scroll (manga and novel) | Ambient extras | reader chrome | §9.4.1, §8.14.8, §8.15.5 |
| Soundscape | Ambient extras | reader sheets | §9.4.2 |
| Guided view | Ambient extras | reader layout `GUIDED` | §9.4.3 |
| Page-tinted chrome | Ambient extras | reader chrome | §9.4.4, §2.1.5 |
| Edition picker and Stop the press | Skins | `/settings/appearance` | §8.30.3, §8.0.7 |
| Lightbox | — | overlay | §7.30 |
| Move to another source | — | sheet / panel | §8.17, §8.18 |
| Tag sheet | — | sheet / panel | §8.9 |
| Genre sheet (Discover) | — | sheet / panel | §8.20 |
| Not available notice | — | any route | §8.0.10 |
| Public install page | — | `GET /` (backend) | §8.34 |
