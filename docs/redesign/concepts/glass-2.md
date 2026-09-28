# Glass concept 2: "Strata" (spatial-first)

Designer 2 of 3 for the Glass skin. Angle: **depth, layering, stacked planes and z-order define navigation.** In Strata the question "where am I?" is answered by *how deep* you are, and the answer is always on screen.

Binding inputs: `inventory/00-decisions.md` (owner decisions), `inventory/web.md`, `inventory/mobile.md`, `inventory/capabilities.md`, `research/*.md` (mainly `glass-language.md`, `brand.md`, `reader-ux.md`, `gestures-nav.md`, `discovery-ux.md`, `flutter-motion-libs.md`, `web-motion-libs.md`), and `stack-decision.md` (keep Next.js 16 + Flutter 3.44.6, per-skin screen folders, one JSON token source under `design/`). Dark only on AMOLED `#000000`, restart on skin switch, flagship-only effects, OS accessibility settings honoured.

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
- Token paths are dotted (`glass.depth.deck1.scale`). The web CSS variable is the same path with dashes (`--mm-depth-deck1-scale`), the Tailwind 4 `@theme` name drops the skin (`--depth-deck1-scale`) and the Flutter field is camelCase (`depthDeck1Scale`).
- A spring is written `{ms, bounce}` as `stack-decision.md` §2.1 requires. The physical stiffness and damping (mass 1, Apple's conversion `k = (2π/d)²`, `c = 4π(1 − bounce)/d`) are listed beside it because Motion on the web must be driven by stiffness and damping to keep inherited velocity (see §9.2).
- Breakpoints: **phone** < 768 px (iOS app, Android app, mobile web), **tablet** 768–1023 px, **desktop** 1024–1439 px, **wide** ≥ 1440 px. "Phone" covers all three phone targets and platform deltas are called out where they exist.
- "Plane" is a screen-sized content slab that can be pushed and popped. "Deck" is the set of planes behind the front one. "Bay" is one dock destination with its own plane stack. These three words are the whole navigation model.

---

## 1. Manifesto

Strata treats ManhwaManiacs as a place you move through, not a set of pages you flip between. The screen is a window into a deep black space and every destination sits at a depth in it. Where you came from never vanishes: it steps back, dims, shrinks a little and waits right behind what you are looking at, so the path you took is always visible as a thin stack of lit edges above the current screen on a phone, or a row of narrow spines at the left of the content on a desktop. Going deeper brings a new plane up and toward you; going back lets the front plane fall away while the one behind comes forward on the same spring, carrying the momentum of your finger. Depth is the breadcrumb and z-order is the map, and a long press on Back lifts the whole stack into a fanned overview so any layer is one tap away. Content (covers, pages, prose) sits on dark solid planes; glass is only ever the nearest layer, a few floating controls that catch the colour of whatever is behind them: the cover you opened, the page you are reading, the mood of the profile you are reading as. One ladder of nine depth levels governs everything, and each level carries its own blur, brightness, parallax, haptic weight and pitch, so a single rule tells anyone how deep a thing sits, how it moves, how it sounds and how it feels. The reader is the deepest room: entering it pushes the whole app back into the dark until only the page and three drifting glass controls remain, and leaving it lets the app surface again exactly as you left it. Nothing slides sideways without a reason, nothing fades through black, and nothing appears from nowhere; everything arrives from a place in the space and returns to it.

---

## 2. Tokens

### 2.1 Colour

#### 2.1.1 Canvas and the Slate ramp

The base is AMOLED black. The neutral ramp is **Slate**, a cool blue-grey (hue ≈ 225°, very low chroma) chosen so that neutral surfaces share the temperature of the glass rims and the Glacier accent. Contrast is the WCAG ratio against `#000000` (measured for this document).

| Token | Hex | On `#000` | Role |
|---|---|---|---|
| `color.abyss` | `#000000` | n/a | Canvas, level L0, every root plane background, reader canvas, the far end of every depth fade |
| `color.slate50` | `#0A0B0F` | 1.07:1 | Desktop pane body (the front pane is lifted off black by 1 step), wide-screen peek pane |
| `color.slate100` | `#111318` | 1.13:1 | `slab.1`: content cards, poster placeholders, grouped-list wells |
| `color.slate150` | `#171A20` | 1.21:1 | `slab.2`: list rows, chapter rows, settings rows |
| `color.slate200` | `#1E2129` | 1.30:1 | `slab.3`: input fills, chip fills at rest, segmented tracks |
| `color.slate300` | `#2A2E38` | 1.55:1 | Pressed fill for slab rows, skeleton base, solid-glass large fallback |
| `color.slate400` | `#3B404C` | 2.02:1 | Skeleton highlight, disabled track, slider track |
| `color.slate500` | `#555B69` | 3.09:1 | Disabled glyphs, decorative strokes only (never text) |
| `color.slate600` | `#737A89` | 4.87:1 | Placeholder text on `#000` only |
| `color.slate700` | `#959CAA` | 7.61:1 | Tertiary text |
| `color.slate800` | `#B9BFCB` | 11.38:1 | Secondary text on dark slabs |
| `color.slate900` | `#DCE0E8` | 15.87:1 | Body text inside the novel "Slate" paper and long prose |
| `color.slate950` | `#F2F4F8` | 19.07:1 | `label.1` ("Frost"): titles, primary text, glyphs on glass |

#### 2.1.2 Text, fill and line roles

Solid values are used on content planes; the alpha values are used on glass so the colour behind shows through (vibrancy).

| Token | On planes (solid) | On glass (alpha) | Contrast (solid on `#000` / on `slab.1`) | Use |
|---|---|---|---|---|
| `label.1` | `#F2F4F8` | `rgba(255,255,255,0.96)` | 19.07 / 16.87 | Titles, body, selected labels |
| `label.2` | `#A9AFBC` | `rgba(235,240,255,0.66)` | 9.55 / 8.45 | Secondary text, meta, inactive tab labels |
| `label.3` | `#767D8B` | `rgba(235,240,255,0.42)` | 5.08 / 4.49 | Tertiary text on `#000` and `slab.1` only; on `slab.2`/`slab.3` use `label.2` |
| `label.4` | `#4A505C` | `rgba(235,240,255,0.22)` | 2.59 / 2.29 | Disabled text and glyphs (paired with a non-colour cue); never on glass thinner than `glass.lift` |
| `fill.1` | `#2A2E38` | `rgba(255,255,255,0.16)` | n/a | Pressed chip, pressed row, filled stepper button |
| `fill.2` | `#1E2129` | `rgba(255,255,255,0.10)` | n/a | Chip at rest, input on glass, segmented track on glass |
| `fill.3` | `#171A20` | `rgba(255,255,255,0.06)` | n/a | Hover wash on rows, quiet wells |
| `line.hair` | `#23262E` | `rgba(235,240,255,0.10)` | n/a | 0.5 px separators (1 px at DPR 1) |
| `line.strong` | `#343844` | `rgba(235,240,255,0.18)` | n/a | Outlined inputs at rest, section rules |

#### 2.1.3 Accents: Iris, Glacier, Bloom

Colour is rationed. Each accent has one job and never takes another's.

| Token | Hex | On `#000` | Job | Never |
|---|---|---|---|---|
| `color.iris` | `#A99BFF` | 8.82:1 | **The one primary action per plane** (tinted glass: Continue, Read, Suggest, Save), reading-progress fills, the selected dock droplet's inner glow, the streak ring when complete | More than one tinted control visible per plane |
| `color.irisInk` | `#0C0A1A` | 8.21:1 on Iris | Text and glyphs on Iris fills | White text on Iris (fails at 2.1:1) |
| `color.irisDeep` | `#7A68F0` | 5.07:1 | Pressed Iris, progress track gradient foot, chart bars | Text colour |
| `color.glacier` | `#8FD8FF` | 13.43:1 | **Focus and "live" state**: keyboard focus ring, the TTS "now speaking" lozenge, sync-in-progress glints, the scrubber lens rim, links inside prose | Buttons, fills larger than 24 px |
| `color.glacierInk` | `#04121C` | 12.12:1 on Glacier | Text on the rare Glacier capsule (the "Back to voice" pill) | |
| `color.bloom` | `#FF9ED8` | 11.13:1 | **People**: social presence rings, reactions, "recommended by" chips, friend activity dots | Anything not about another person |
| `color.bloomInk` | `#1A0612` | 10.32:1 on Bloom | Text on Bloom chips | |

#### 2.1.4 Semantic roles

Every semantic colour has a foreground (text, glyph) and a tint (16 % alpha fill behind it). Semantic colour is always paired with a glyph or a word so it never carries meaning alone.

| Token | Foreground | On `#000` | Tint | Glyph (Phosphor) | Use |
|---|---|---|---|---|---|
| `color.success` | `#5BE49B` | 13.02:1 | `rgba(91,228,155,0.16)` | `CheckCircle` | Saved offline, completed, healthy, followed |
| `color.warning` | `#FFC069` | 13.00:1 | `rgba(255,192,105,0.16)` | `WarningCircle` | Stale copy, paused downloads, overdue checker, storage near cap |
| `color.danger` | `#FF6B7A` | 7.64:1 | `rgba(255,107,122,0.16)` | `XCircle` | Errors, failed downloads, destructive confirms (text on a filled danger capsule is `#000000`, 7.64:1) |
| `color.info` | `#8FD8FF` (Glacier) | 13.43:1 | `rgba(143,216,255,0.14)` | `Info` | Neutral notices, "live" states |
| `color.mature` | `#FF5C8A` | 7.15:1 | `rgba(255,92,138,0.16)` | text "18+" | The 18+ badge on sources and series that are shown; the hold-to-confirm fill |
| `color.flameA` / `color.flameB` | `#FFB35C` → `#FF6B4A` | 11.85 / 7.45:1 | n/a | `Flame` | Streak flame gradient (top to bottom), only on streak surfaces |
| `status.reading` | Iris `#A99BFF` | 8.82:1 | Iris 16 % | `BookOpen` | Library status chip |
| `status.completed` | `#5BE49B` | 13.02:1 | success tint | `CheckCircle` | |
| `status.onHold` | `#FFC069` | 13.00:1 | warning tint | `PauseCircle` | |
| `status.planToRead` | `#8FD8FF` | 13.43:1 | info tint | `BookmarkSimple` | |
| `status.dropped` | `#A9AFBC` | 9.55:1 | `fill.2` | `MinusCircle` | |
| `status.unread` | `#767D8B` | 5.08:1 | `fill.3` | `Circle` | |

#### 2.1.5 Depth dims, veils and scrims

Depth is shown by **brightness**, never by colour. A plane that steps back multiplies its own brightness; it does not get a grey overlay, so its colours stay true and simply darken toward the abyss.

| Token | Value | Use |
|---|---|---|
| `depth.deck1.brightness` | 0.56 | The plane directly behind the front plane |
| `depth.deck2.brightness` | 0.36 | Two levels back |
| `depth.deck3.brightness` | 0.22 | Three levels back (the last painted level) |
| `depth.dive.brightness` | 0.12 | The whole stack while the reader is open (then hidden) |
| `veil.sheet` | `rgba(0,0,0,0.30)` | Behind partial sheets (L6) |
| `veil.modal` | `rgba(0,0,0,0.52)` | Behind alerts, action sheets and the 18+ confirm (L7) |
| `veil.focus` | `rgba(0,0,0,0.72)` | Everything outside the focused panel in the guided view, and outside the stack overview's lifted planes |
| `veil.media` | `rgba(0,0,0,0.35)` | Under clear glass over bright media (Apple's dimming layer), applied only when the sampled media luminance is above 0.55 |
| `scrim.heroFoot` | `linear-gradient(to top, #000 0%, rgba(0,0,0,0.86) 22%, rgba(0,0,0,0.38) 52%, rgba(0,0,0,0) 78%)` | Bottom of the Home stage and the series header so the plane below joins seamlessly |
| `scrim.edgeTop` | `linear-gradient(to bottom, rgba(0,0,0,0.78), rgba(0,0,0,0))` over 72 px + safe top, with blur 8 | Soft scroll edge under floating top controls |
| `scrim.edgeBottom` | the same, mirrored, 96 px + safe bottom | Soft scroll edge behind the dock |

#### 2.1.6 Moods: the horizon hue

Each profile's mood becomes the colour of the **horizon**, the faint glow at the far back of the space (level L1). It never tints text, controls or the reader. Values are the hue stops of a two-blob radial field; opacity is set by the field rules in §2.1.9.

| Mood | Horizon A | Horizon B | Character |
|---|---|---|---|
| `default` | none | none | The field uses only cover colour; with no cover, pure black |
| `romantic` | `#FF7FA8` | `#B45CFF` | Rose to violet dusk |
| `action` | `#FF7A4D` | `#FFC069` | Ember and brass |
| `comedy` | `#FFD166` | `#7FE0C4` | Sun and mint |
| `horror` | `#C2334D` | `#3A1A4A` | Arterial red into bruise (kept at the lowest field opacity) |
| `slice_of_life` | `#8FE3B0` | `#FFE3A8` | Leaf and linen |
| `fantasy` | `#B48CFF` | `#6FD3E0` | Arcane violet and teal |

#### 2.1.7 Speaker palette (novel dialogue tints and cast swatches)

Ten hues at matched lightness (OKLCH L ≈ 0.80, C ≈ 0.12) so no speaker looks more important than another. The attribution `cast` order assigns them in sequence; the two busiest speakers get `speaker1` and `speaker6`, which are the furthest apart. Use as a 14 % background band plus a 1.5 px underline at 55 %.

| Token | Hex | On `#000` |
|---|---|---|
| `speaker1` | `#FF9E9E` | 10.64:1 |
| `speaker2` | `#FFB77A` | 12.31:1 |
| `speaker3` | `#E8D26B` | 13.86:1 |
| `speaker4` | `#9EE08A` | 13.48:1 |
| `speaker5` | `#6FE0C4` | 13.14:1 |
| `speaker6` | `#7FD3FF` | 12.66:1 |
| `speaker7` | `#9DB0FF` | 10.09:1 |
| `speaker8` | `#C7A0FF` | 9.90:1 |
| `speaker9` | `#FF94C8` | 10.32:1 |
| `speaker10` | `#D9C8A8` | 12.78:1 |

Assignment order for cast index 0…9: 1, 6, 3, 8, 5, 10, 2, 7, 4, 9. The narrator never gets a hue; narration highlight uses Glacier.

#### 2.1.8 Paper themes (novel reader)

All papers are dark (owner decision: dark only). Text is off-white, never `#FFFFFF`, to avoid halation on OLED. Contrasts are text on paper.

| Paper | Background | Text | Contrast | Muted | Contrast | Note |
|---|---|---|---|---|---|---|
| Abyss (default) | `#000000` | `#D9D6D0` | 14.48:1 | `#8A877F` | 5.85:1 | Pure AMOLED |
| Slate | `#0A0B0F` | `#DCE0E8` | 14.86:1 | `#8A909E` | 6.15:1 | Matches the skin |
| Ink | `#0B0B0C` | `#E6E3DD` | 15.36:1 | `#8F8C86` | 5.87:1 | Neutral |
| Night paper | `#15110C` | `#E8D8BE` | 13.42:1 | `#9C8E78` | 5.87:1 | Warm sepia |
| Dusk | `#0D1117` | `#D3DAE3` | 13.43:1 | `#8590A0` | 5.85:1 | Cool |
| Moss | `#0E130F` | `#D5DECF` | 13.57:1 | `#879384` | 5.84:1 | Green-tinted |
| Rosewood | `#160E10` | `#EBD5D8` | 13.62:1 | `#A08A8E` | 5.90:1 | Red-tinted |

#### 2.1.9 Ambient colour extraction (the horizon field)

The horizon field is two soft radial blobs painted at L1, behind every plane. It exists because glass over pure black has nothing to bend; it is also the colour memory of where you are.

**Sources, in priority order:**

1. The focused object's palette: the series on a series plane, the spotlighted series on Home, the current page in the reader (for page-tinted chrome, §5.4.4), the current collection's first cover.
2. The active profile's mood (§2.1.6).
3. Nothing: pure black.

**Palette data.** Cover palettes come from the backend (stack-decision §2.6: per-cover palettes are computed server-side with Pillow median cut on a 64 px thumbnail and shipped as `palette: {dominant, vibrant, muted, darkVibrant}` on series payloads). Reader page tints are computed on the client because pages may be offline downloads: web draws the page into a 16 × 16 `OffscreenCanvas` inside a worker; Flutter decodes a 64 px `ResizeImage` and runs `QuantizerCelebi` + `Score` from `material_color_utilities` 0.13.0 in `compute()`. Results are cached per page URL.

**Selection rule.** Convert candidates to OKLCH. Discard any with L < 0.18 or C < 0.035 (too dark or too grey to read as colour). Pick the highest-population survivor as `A` and the survivor with the largest hue distance from `A` (at least 40°) as `B`; if there is no second survivor, `B` = `A` rotated +30°.

**Clamps per use:**

| Use | L | C | Opacity | Blur |
|---|---|---|---|---|
| Horizon field blobs (L1) | 0.42–0.58 | ≤ 0.13 | A 0.26, B 0.18 (horror mood × 0.7) | 140 px |
| Glass tint (L5 controls, page-tinted chrome) | 0.62–0.74 | ≤ 0.10 | mixed 18 % into `glass.float` fill | n/a |
| Plane top rim (the strata edge colour) | 0.70–0.80 | ≤ 0.12 | 0.60 | n/a |
| Stat and share cards | 0.50–0.66 | ≤ 0.16 | gradient stops | n/a |

**Geometry.** Blob A is centred at (20 % width, −10 % height) with radius 70 % of the longer side; blob B at (85 %, 20 %) with radius 55 %. Both fade to fully transparent by 62 % of the screen height, so the bottom 38 % is always true black (AMOLED power and dock legibility).

**Motion.** Blobs drift on a 40 s loop (A traces an ellipse 6 % × 4 % of the screen, B the reverse direction at 0.8× speed) and shift with depth parallax (§2.2.3). A palette change interpolates in OKLab over 600 ms (`ease.standard`). Under Reduce Motion the drift stops and palette changes cross-fade in 200 ms.

---

### 2.2 The depth ladder and materials

This is the core of Strata. Every visible thing sits on exactly one of nine levels. The level decides material, blur, brightness, parallax, haptic weight and sound pitch.

#### 2.2.1 The nine levels

| Level | Name | What lives here | Material | Parallax factor | Haptic weight | Pitch (UI sound) |
|---|---|---|---|---|---|---|
| L0 | **Abyss** | The black canvas | `#000000` | 0 | n/a | n/a |
| L1 | **Horizon** | Ambient field (mood + cover colour) | 2 radial blobs, blur 140 | 1.00 | n/a | n/a |
| L2 | **Deck** | Planes behind the front plane (up to 3 painted) | the plane's own material × `depth.deckN.brightness` | 0.55 | n/a | n/a |
| L3 | **Plane** | The front screen: covers, rows, text, pages | `plane` (content layer, **never Liquid Glass**) | 0.20 | light | E5 |
| L4 | **Edge** | Scroll edge effects, sticky headers | gradient + blur 8 | 0 | n/a | n/a |
| L5 | **Float** | Dock, search orb, top control clusters, bottom accessory, reader chrome | `glass.float` | 0 (specular moves ±25°) | soft | G♯5 |
| L6 | **Lift** | Menus, popovers, context menus, partial sheets, the stack overview | `glass.lift` | −0.10 (moves slightly against the pointer, so it feels nearer) | medium | B5 |
| L7 | **Veil** | Alerts, action sheets, the 18+ confirm, the skin-restart confirm | `glass.lift` + `veil.modal` | 0 | rigid | C♯6 |
| L8 | **HUD** | Toasts, scrub lens, brightness and zoom HUDs, undo bar | `glass.float` compact | 0 | selection | E6 |

Rules:

- **Glass lives only on L5–L8.** Planes (L3) are solid content slabs. A transient control on a plane (a slider thumb being dragged, a chip being dragged to reorder) becomes glass only while it is held (Apple's transient-control exception) and returns to solid on release.
- **No glass on glass.** Anything placed on L5–L8 uses fills (`fill.*`) and vibrancy labels, never another glass surface. Sibling glass controls on one level share one sampling container so they can morph into each other.
- **At most two glass layers overlap at any pixel** (performance rule from stack-decision risk 5). If a Lift surface opens over Float controls, the Float controls under the Lift footprint switch to their solid fallback for the duration.
- **Depth order equals tab order.** Keyboard and screen-reader focus always starts at the highest open level and cannot reach lower levels while a Veil is up.

#### 2.2.2 Deck geometry (how planes stack)

**Phone (iOS, Android, mobile web).** Planes are anchored top-centre. The front plane's top edge sits 10 px under the safe area so the deck is visible above it; root planes (the four bay roots) are full-bleed until something is pushed over them.

| Token | Front (k = 0) | Deck 1 | Deck 2 | Deck 3 | Deck 4+ |
|---|---|---|---|---|---|
| `depth.phone.top` (px from the top of the screen) | `safeTop + 10` (root: 0) | `safeTop − 2` | `safeTop − 10` | `safeTop − 18` | not painted |
| `depth.phone.scale` | 1.00 | 0.94 | 0.89 | 0.84 | n/a |
| `depth.phone.brightness` | 1.00 | 0.56 | 0.36 | 0.22 | n/a |
| `depth.phone.blur` (px) | 0 | 0 | 4 | 8 | n/a |
| `depth.phone.radiusTop` (px) | 28 (root: 0) | 28 | 28 | 28 | n/a |
| Visible band above the next plane | n/a | 12 px | 8 px | 8 px | n/a |

Each deck plane shows a 0.5 px **strata rim** along its top edge in its own ambient colour (§2.1.9, L 0.70–0.80, opacity 0.60), so the three bands above the front plane read as three lit edges in the colours of the places you came from. On devices with a small status bar (Android, 24–32 dp), deck 3 may sit partly off-screen; it is clipped, never repositioned.

**Tablet (768–1023 px, web and large Android windows).** Same stack as the phone, but the front plane is inset 24 px left and right and 16 px at the bottom with a 32 px radius on all four corners, so the deck shows on three sides.

**Desktop and wide web.** Planes become **panes** that stack left to right inside the content region (the area right of the sidebar):

| Token | Value |
|---|---|
| `depth.desk.gutter` | 12 px between the sidebar, spines and front pane, and around the whole region |
| `depth.desk.spine` | 64 px: the width each deck pane keeps visible at the left |
| `depth.desk.maxSpines` | 3 (the root pane plus two intermediate panes); deeper panes merge into the leftmost spine, which then shows a count badge ("+2") |
| `depth.desk.paneRadius` | 24 px, continuous corners |
| `depth.desk.front.fill` | `slate50` `#0A0B0F`, rim 0.5 px `rgba(255,255,255,0.10)`, shadow `-24px 0 64px rgba(0,0,0,0.70)` |
| `depth.desk.spine.brightness` | deck 1: 0.62, deck 2: 0.42, deck 3: 0.28 |
| `depth.wide.frontMax` | 1120 px: at ≥ 1440 px the front pane caps here |
| `depth.wide.peek` | when space is left over, deck 1 shows up to 420 px of its live content (not just a spine) at brightness 0.62 and scale 0.97 around its right edge |

A spine shows, top to bottom: the pane's icon (20 px, `label.2`), its title set vertically (rotated −90°, `caption.1` w600, `label.2`, truncated with an ellipsis at the pane height minus 96 px), and a 2 px ambient-colour line down its right edge. Hover: brightness +0.14 over 150 ms, cursor pointer, tooltip "Back to {title}" with the key hint `⌘[`. Click pops every pane above it.

#### 2.2.3 Depth parallax

Every level moves by `offset × parallaxFactor` where `offset` comes from:

- **Phone:** the device gyroscope (`sensors_plus` 7.1.0 on Flutter; `DeviceOrientationEvent` on mobile web after the permission prompt on iOS Safari, otherwise none), low-passed with the `drift` spring, clamped to ±12 px on x and ±8 px on y.
- **Desktop:** the pointer position relative to the viewport centre, mapped to ±12 px / ±8 px, low-passed with the `drift` spring. Parallax is suspended while any button is pressed or text is selected.

L1 moves the most (1.0), the deck 0.55, the front plane 0.20, Float controls do not translate but their specular angle rotates within ±25°, and Lift surfaces move −0.10 (against the pointer, so they read as nearer than the page). Under Reduce Motion all parallax is 0 and the light angle is fixed at 135°.

#### 2.2.4 Material recipes

| Token | Where | Fill | Blur / saturate | Rim | Specular | Shadow | Refraction (liquid tier) |
|---|---|---|---|---|---|---|---|
| `glass.float` | L5, L8 | `rgba(255,255,255,0.07)` + 18 % ambient tint when the plane has a palette | 10 px / 1.7 | 0.5 px `rgba(255,255,255,0.24)` | 135° linear, `rgba(255,255,255,0.42)` → 0.04 at 35 % → 0.02 at 65 % → 0.20 | `0 8px 24px rgba(0,0,0,0.50)` | bezel 12, thickness 24, n 1.5 |
| `glass.float` legibility floor | L5 over bright pages | adds `rgba(0,0,0,0.24)` under the fill when the sampled backdrop luminance > 0.55 | same | same | same | `0 8px 24px rgba(0,0,0,0.62)` | same |
| `glass.lift` | L6, L7 | `rgba(20,22,28,0.58)` | 24 px / 1.8 | 0.5 px `rgba(255,255,255,0.18)` | 135°, peak 0.30 | `0 28px 72px rgba(0,0,0,0.66)` | bezel 18, thickness 40 |
| `glass.clear` | Only over hero media and cover art | `rgba(255,255,255,0.02)` | 2 px / 1.4 | 0.5 px `rgba(255,255,255,0.30)` | peak 0.50 | none | bezel 12, thickness 24 + `veil.media` underneath when bright |
| `glass.tint` | The one primary action per plane | Iris `#A99BFF` at 84 % | 8 px / 1.6 | 0.5 px `rgba(255,255,255,0.36)` | peak 0.50 | `0 6px 24px rgba(169,155,255,0.34)` | bezel 10, thickness 20 |
| `plane` (phone, tablet) | L3 pushed planes | `#000000` | none | 0.5 px top rim in the ambient colour (§2.2.2) + `rgba(255,255,255,0.10)` along the rounded top corners | none | `0 -16px 48px rgba(0,0,0,0.80)` (cast upward onto the deck) | none |
| `plane.root` | L3 bay roots | `#000000`, full-bleed | none | none | none | none | none |
| `slab.1` | Cards, wells | `#111318` | none | none | none | none | none |
| `slab.2` | Rows | `#171A20` | none | none | none | none | none |
| `slab.3` | Inputs, chips | `#1E2129` | none | 0.5 px `line.strong` for inputs | none | none | none |
| `solid.float` | Reduce Transparency, capability floor | `#1A1D24` | none | 0.5 px `rgba(255,255,255,0.10)` | none | `0 8px 24px rgba(0,0,0,0.5)` | none |
| `solid.lift` | Reduce Transparency | `#20242C` | none | 0.5 px `rgba(255,255,255,0.12)` | none | `0 28px 72px rgba(0,0,0,0.66)` | none |
| `contrast.*` | Increase Contrast | `#000000` for float, `#111318` for lift | none | 1 px `rgba(255,255,255,0.60)` | none | none | none |

Tiers (following `glass-language.md` §5.2 and §9, not a low-end tier): **liquid** (SVG displacement refraction, Chromium and Impeller) → **frosted** (blur + saturate + rim + glow, used when the renderer cannot refract: Safari, Firefox, Skia) → **solid** (Reduce Transparency, the in-app "Solid glass" switch, Increase Contrast). Shapes, motion and layout are identical in all three.

---

### 2.3 Typography

#### 2.3.1 Families (all from Google Fonts, all SIL Open Font License 1.1)

| Family | Role | Axes used | Delivery |
|---|---|---|---|
| **Google Sans Flex** | All UI and display text | `wght` 300–800, `opsz` 6–144 (set to the font size), `ROND` 0–100 (roundness tracks the role), `GRAD` pinned 0, `slnt` pinned 0, `wdth` pinned 100 | Web: `next/font/google` `Google_Sans_Flex({ subsets: ['latin'], axes: ['ROND','opsz'] })`. Flutter: a bundled Latin subset instanced with fonttools (`GRAD=0 slnt=0 wdth=100`, keep `opsz`, `wght`, `ROND`), 510,192 B TTF, family `GoogleSansFlexMM` |
| **Google Sans Code** | Numerals, timestamps, sizes, chapter numbers, keycaps, stat figures | `wght` 300–800 | Web `next/font`; Flutter bundled variable TTF (126,224 B), family `GoogleSansCodeMM` |
| **Literata** | Novel reader default serif, the Book page title | `opsz` 7–72 (set to size), `wght` 200–900 | Web `next/font` (`preload: false`, loaded when a novel route mounts); Flutter bundled variable TTF (955,132 B) |
| **Newsreader** | Novel reader alternative serif | `opsz` 6–72, `wght` 200–800 | Same as Literata |
| **Atkinson Hyperlegible Next** | Novel reader accessibility face, and the whole UI when "Legible text" is on in Settings → Reading | `wght` 200–800 | Same as Literata |
| **Noto Sans KR / JP / SC** | CJK fallback for titles (web only) | `wght` | `next/font` with `preload: false` appended to the family stack. Flutter uses the OS CJK fallback |

Why one sans: Strata's hierarchy is carried by depth, not by contrasting faces. One superfamily with optical sizes keeps every level in the same voice, and `ROND` lets the nearest, most touchable things (dock labels, buttons, large titles) read softer than dense body text.

`ROND` by role: large title and display 100, titles 60, headline and buttons 50, captions and tab labels 40, body and callout 0. `opsz` always equals the rendered size in px (CSS `font-optical-sizing: auto`; Flutter `FontVariation('opsz', size)` per style, generated by `design/build.mjs`). Numerals in running UI use `font-variant-numeric: tabular-nums` / `FontFeature.tabularFigures()`.

#### 2.3.2 Type scale per breakpoint

Size / line height in px, weight, tracking in em. Phone values are the iOS "Large" and Android 1.0 defaults.

| Role | Phone | Tablet | Desktop | Wide | Weight | Tracking | ROND |
|---|---|---|---|---|---|---|---|
| `display` (Home headline, Wrapped titles) | 40 / 44 | 52 / 56 | 64 / 68 | 80 / 84 | 700 | −0.028 | 100 |
| `largeTitle` (plane titles) | 34 / 40 | 40 / 46 | 44 / 50 | 52 / 58 | 680 | −0.022 | 100 |
| `title1` | 28 / 34 | 30 / 36 | 32 / 38 | 36 / 42 | 660 | −0.018 | 60 |
| `title2` (section headers, letter reveal) | 22 / 28 | 24 / 30 | 26 / 32 | 28 / 34 | 640 | −0.014 | 60 |
| `title3` | 20 / 25 | 20 / 26 | 20 / 26 | 22 / 28 | 620 | −0.010 | 60 |
| `headline` | 17 / 22 | 17 / 22 | 15 / 20 | 16 / 22 | 600 | −0.008 | 50 |
| `body` | 17 / 24 | 17 / 24 | 15 / 22 | 16 / 24 | 420 | −0.006 | 0 |
| `callout` | 16 / 22 | 16 / 22 | 14 / 20 | 15 / 22 | 420 | −0.004 | 0 |
| `subhead` | 15 / 20 | 15 / 20 | 13 / 18 | 14 / 20 | 460 | −0.002 | 0 |
| `footnote` | 13 / 18 | 13 / 18 | 12 / 16 | 13 / 18 | 460 | 0 | 0 |
| `caption1` | 12 / 16 | 12 / 16 | 11 / 14 | 12 / 16 | 520 | +0.004 | 40 |
| `caption2` | 11 / 13 | 11 / 13 | 10 / 12 | 11 / 13 | 560 | +0.010 | 40 |
| `tabLabel` | 10 / 12 | 11 / 13 | n/a | n/a | 600 | +0.020 | 40 |
| `button` | 17 / 22 | 17 / 22 | 15 / 20 | 15 / 20 | 600 | −0.006 | 50 |
| `mono.meta` (Google Sans Code) | 12 / 16 | 12 / 16 | 12 / 16 | 13 / 18 | 500 | +0.010 | n/a |
| `mono.figure` (stat numbers) | 44 / 48 | 52 / 56 | 56 / 60 | 64 / 68 | 600 | −0.030 | n/a |
| `mono.key` (keycaps) | n/a | 11 / 14 | 11 / 14 | 12 / 16 | 560 | +0.020 | n/a |

Web sizes are authored in `rem` (`html { font-size: 100% }`), so browser text zoom behaves as Dynamic Type does on phones.

#### 2.3.3 Mobile text scale

Flutter reports one linear text-scale factor (`MediaQuery.textScalerOf`). Strata applies it per role:

- **Body roles** (`body`, `callout`, `subhead`, `footnote`, `caption*`, `mono.meta`, `button`) scale linearly.
- **Title roles** (`display`, `largeTitle`, `title1–3`, `mono.figure`) scale by `1 + (f − 1) × 0.5` and are capped.
- **Dock labels** (`tabLabel`) scale to a maximum of 1.3× and then hide; the icon stays, and a long press shows a HUD label.

| iOS size / Android scale | f | body | headline | title2 | largeTitle | caption2 |
|---|---|---|---|---|---|---|
| xSmall | 0.82 | 14 | 14 | 20 | 31 | 11 (floor) |
| Small | 0.88 | 15 | 15 | 21 | 32 | 11 |
| Medium / Android 0.85 | 0.94 | 16 | 16 | 21 | 33 | 11 |
| **Large / Android 1.0** | 1.00 | 17 | 17 | 22 | 34 | 11 |
| xLarge / Android 1.15 | 1.12 | 19 | 19 | 23 | 36 | 12 |
| xxLarge / Android 1.3 | 1.24 | 21 | 21 | 25 | 38 | 14 |
| xxxLarge / Android 1.5 | 1.35 | 23 | 23 | 26 | 40 | 15 |
| AX1 / Android 1.8 | 1.65 | 28 | 28 | 29 | 45 | 18 |
| AX2 / Android 2.0 | 1.94 | 33 | 33 | 32 | 50 | 21 |
| AX3 | 2.35 | 40 | 40 | 37 | 57 | 26 |
| AX4 | 2.76 | 47 | 47 | 41 | 60 (cap) | 30 |
| AX5 | 3.12 | 53 (cap) | 53 (cap) | 46 | 60 (cap) | 34 |

Layout changes at large sizes (all phone targets, and web at 200 % zoom):

- f ≥ 1.35: horizontal rails become two-row grids with a "See all" plane; dock labels hide.
- f ≥ 1.65: poster grids go to 2 columns; list rows stack title above meta; the reader chrome's page line moves into the scrubber lens only.
- f ≥ 2.35: series header puts the poster above the title at full width; chips wrap instead of scrolling; the stack overview lists planes as rows instead of fanned cards.

#### 2.3.4 Novel reader type

| Control | Range | Default phone / desktop | Step |
|---|---|---|---|
| Face | Literata, Newsreader, Google Sans Flex, Atkinson Hyperlegible Next | Literata | n/a |
| Size | 14–30 px | 19 / 20 | 1 |
| Line height | 1.40–2.20 | 1.70 | 0.05 |
| Measure | 44–88 ch | 64 / 68 | 2 |
| Paragraph spacing | 0–1.2 em | 0.6 em | 0.1 |
| Character spacing | −0.02 to +0.10 em | 0 | 0.01 |
| Word spacing | 0 to +0.30 em | 0 | 0.02 |
| Weight | Regular 400 / Bold text 560 | 400 | toggle |
| Justify + hyphenate | on / off | off | toggle |

Chapter heading: eyebrow `CHAPTER 142` in Google Sans Flex `caption1` w600 +0.18 em `label.2`; title in the reading face at 1.55× body, w600, `opsz` = size; a 48 px hairline in `line.strong`. Drop cap on the first paragraph when it is ≥ 80 characters: 3 lines tall, reading face w600, `opsz` 72.

#### 2.3.5 Numerals, CJK and truncation

- Chapter numbers print `chapter_number` with no trailing zeros ("142", "142.5"); a null number prints the title ("Prologue").
- Titles truncate at 2 lines on posters and 1 line in rows, with the full title in the tooltip (web) and in the accessibility label.
- CJK titles use the fallback stack at the same size; tracking is forced to 0 for CJK runs.

---

### 2.4 Spacing

A 4 px grid with a 2 px half-step for hairline alignment.

| Token | px | Typical use |
|---|---|---|
| `space.0` | 0 | |
| `space.1` | 2 | Badge inner offset |
| `space.2` | 4 | Icon-to-label inside chips |
| `space.3` | 6 | Menu row inset inside the menu padding |
| `space.4` | 8 | Gap between grouped glass buttons, dock inner padding |
| `space.5` | 12 | Rail item gap (phone), card padding (small) |
| `space.6` | 16 | Screen margin (phone), card padding, rail item gap (desktop) |
| `space.7` | 20 | Screen margin on phones ≥ 428 px wide, dock side inset |
| `space.8` | 24 | Section inner gap, tablet margin |
| `space.9` | 32 | Section gap (phone), desktop content margin |
| `space.10` | 40 | Wide content margin |
| `space.11` | 48 | Section gap (desktop) |
| `space.12` | 64 | Hero bottom spacing, desktop spine width |
| `space.13` | 80 | Space reserved under content for dock + accessory on phone |
| `space.14` | 96 | Wrapped card inner top margin |

Fixed layout values:

| Token | Value |
|---|---|
| `layout.dock.inset` | 20 px from the sides and from the bottom safe area |
| `layout.dock.height` | 62 px (minimized 50 px) |
| `layout.accessory.gap` | 10 px above the dock |
| `layout.contentBottom` | `safeBottom + 20 + 62 + 16` = content inset so the last row clears the dock; `+ 62` more when the accessory is showing |
| `layout.sidebar.width` | 264 px expanded, 76 px rail; inset 12 px |
| `layout.touch.min` | 44 × 44 pt on iOS and web touch, 48 × 48 dp on Android (the hit area grows by padding; visuals may be smaller) |
| `layout.target.gap` | 8 px minimum between hit areas |

---

### 2.5 Radius and shape

All rectangles use continuous (superellipse) corners: `corner-shape: squircle` on Chromium web (plain `border-radius` elsewhere), `RoundedSuperellipseBorder` / `ClipRSuperellipse` in Flutter. Controls are capsules. Nested shapes are concentric: `r_inner = max(r_outer − padding, 4)`.

| Token | px | Use |
|---|---|---|
| `radius.capsule` | height ÷ 2 | Every button, chip, field, segmented control, toast, dock, accessory, title capsule |
| `radius.xs` | 6 | Badges, OCR hit boxes, keycaps |
| `radius.sm` | 10 | Cover thumbnails in rows (44–64 px) |
| `radius.md` | 14 | Posters (concentric inside a 26 px card with 12 px padding) |
| `radius.lg` | 20 | Cards on planes, grouped list wells, rails' hero card |
| `radius.xl` | 28 | Menus, popovers, the phone plane's top corners, desktop dialogs |
| `radius.2xl` | 36 | Partial sheets when the device radius is unknown |
| `radius.sheet` | `deviceRadius − 8` (the sheet inset) | Partial sheets on devices that report a corner radius |
| `radius.pane` | 24 | Desktop panes |
| `radius.orb` | 50 % | Avatars, the search orb, voice orbs, the You orb |

---

### 2.6 Blur

CSS `blur()` radius equals Flutter `ImageFilter.blur` sigma, so values carry across unchanged.

| Token | px | Use |
|---|---|---|
| `blur.float` | 10 | Float glass |
| `blur.lift` | 24 | Lift and Veil glass |
| `blur.clear` | 2 | Clear glass over media |
| `blur.edge` | 8 | Scroll edges |
| `blur.deck2` / `blur.deck3` | 4 / 8 | Deck levels 2 and 3 |
| `blur.horizon` | 140 | Ambient blobs |
| `blur.focusVeil` | 18 | Panels outside focus in the guided view |
| `blur.dive` | 16 | The stack while the reader is entered |
| `blur.recedeOut` | 40 | The whole app during the outgoing skin switch |
| `blur.letter` | 12 → 0 | Heading letter reveal start value |

---

### 2.7 Borders, rims and focus

| Token | Value | Use |
|---|---|---|
| `rim.float` | 0.5 px `rgba(255,255,255,0.24)` inset | Float glass |
| `rim.lift` | 0.5 px `rgba(255,255,255,0.18)` inset | Lift glass |
| `rim.strata` | 0.5 px, ambient colour at 0.60 | Top edge of every deck plane |
| `line.hair` | 0.5 px (1 px at DPR 1) `#23262E` | Row separators, inset 16 px from the leading edge |
| `border.input` | 1 px `line.strong` at rest, 1.5 px Glacier when focused, 1.5 px danger on error | Text fields |
| `focus.ring` | 2 px solid Glacier `#8FD8FF`, offset 2 px, plus `0 0 0 6px rgba(143,216,255,0.24)` | Every focusable element on `:focus-visible` / Flutter traditional highlight mode. Follows the element's radius |
| `select.ring` | 2 px Iris, offset 3 px | Selected poster in select mode, chosen voice, chosen paper |
| `danger.ring` | 1.5 px `#FF6B7A` | Invalid fields |

Focus never relies on the ring colour alone: a focused poster also lifts to L3 + 4 px (§3.8).

---

### 2.8 Iconography

- **Set:** Phosphor Icons, MIT: `@phosphor-icons/react` 2.1.10 (web) and `phosphor_flutter` 2.1.0 (Flutter); the two are at parity for all 1,512 icons in all six weights.
- **Weights:** Regular (1.5 px stroke at 24 px) everywhere by default; **Fill** for the selected dock bay and toggled-on icon buttons (bookmark saved, favourite on); **Duotone** (secondary layer at 24 % opacity) only for the large objects in empty, error and offline states.
- **Sizes:** 16 (inline with caption), 20 (rows, chips, sidebar), 24 (glass buttons, dock), 28 (reader chrome), 32 (sheet headers), 64 and 96 (state objects).
- **Colour:** glyphs on glass use `label.1` alpha; on planes `label.1` or `label.2`; on Iris `irisInk`. Glyphs are never tinted with accents except the semantic glyphs in §2.1.4 and the live Glacier state.

Core mapping:

| Concept | Phosphor | Concept | Phosphor |
|---|---|---|---|
| Home | `HouseSimple` | Library | `Books` |
| Sources | `Compass` | Updates | `BellSimple` |
| Search | `MagnifyingGlass` | Downloads | `ArrowCircleDown` |
| Back | `CaretLeft` | Close | `X` |
| More | `DotsThree` | Settings | `GearSix` |
| Bookmark | `BookmarkSimple` | Favourite | `Star` |
| Follow | `Plus` → `Check` | Notify per series | `BellRinging` / `BellSlash` |
| Pin | `PushPin` / `PushPinSlash` | Filter | `FunnelSimple` |
| Sort | `ArrowsDownUp` | Select | `CheckCircle` |
| Reader settings | `SlidersHorizontal` | Type and page | `TextAa` |
| Contents | `ListNumbers` | Listen | `Headphones` |
| Voices / cast | `UserSound` | Brightness | `Sun` |
| Warmth | `ThermometerSimple` | Auto-scroll | `ArrowFatLinesDown` |
| Soundscape | `Waveform` | Stats | `ChartBar` |
| Streak | `Flame` | Circle (social) | `UsersThree` |
| Recommend to | `PaperPlaneTilt` | AI | `Sparkle` |
| Dialogue search | `ChatTeardropText` | Collections | `Stack` |
| History | `ClockCounterClockwise` | Offline | `CloudSlash` |
| Storage | `HardDrives` | Security | `ShieldCheck` |
| Members | `UsersFour` | Backup | `Database` |
| Diagnostics | `Gauge` | System status | `Pulse` |
| Skin | `Swatches` | Haptics | `Vibrate` |
| Sounds | `SpeakerSimpleHigh` | Keyboard | `Keyboard` |
| Novels mode | `BookOpenText` | Error | `WarningCircle` |

**Custom glyphs** (24 px grid, 1.5 px stroke, round caps and joins, 2 px padding, drawn to match Phosphor Regular; exported as SVG for web and as an `IconData` font `StrataGlyphs` for Flutter):

1. `strata`: three stacked rounded rectangles offset 3 px upward and 2 px narrower each; the stack overview and the depth indicator.
2. `strip`: a tall rounded rectangle with two horizontal gutter lines; Manga mode, webtoon layout.
3. `spread`: two facing pages; double-page layout.
4. `panelFocus`: a rectangle with one corner panel outlined in a 2 px stroke and the rest dashed; the guided view.
5. `recap`: an open book with a counter-clockwise arrow over the spine; "Previously on".
6. `mmColumn`: the brand MM column (§7.1); splash, favicon, loaders.
7. `orbit`: a small circle on a tilted ellipse; the AI-thinking and loading indicator base glyph.

---

### 2.9 Motion

#### 2.9.1 Principles

1. **Z is the axis of meaning.** Forward in the app is toward you (a plane rises, scales from 0.96 to 1, un-blurs). Back is away from you (the plane drops and the deck comes forward). Lateral motion is used only between sibling bays and between pages of a book.
2. **Two planes, one progress value.** Every navigation animates the incoming plane and every deck level from one progress value `p` driven by one spring, so they can never drift apart and a gesture can grab all of them at once.
3. **Springs for everything that moves; curves only for opacity, colour and blur companions.** Default bounce is 0; bounce above 0.3 only in celebration moments.
4. **Back-to-front assembly, front-to-back dismissal.** When a plane arrives, its far layers settle first and its nearest controls last. When it leaves, the controls go first.
5. **Nothing fades through black.** A plane leaving is always visible until something else covers it.

#### 2.9.2 Springs

| Token | `{ms, bounce}` | Stiffness | Damping | Use |
|---|---|---|---|---|
| `spring.track` | {150, 0.14} | 1754.6 | 72.05 | Finger-following retargets (drag, droplet under the finger, scrub lens) |
| `spring.press` | {250, 0.15} | 631.7 | 42.73 | Press growth and release on glass |
| `spring.tick` | {200, 0.20} | 986.96 | 50.27 | Toggles, checkboxes, badges, segmented thumb nudges |
| `spring.detent` | {400, 0.10} | 246.7 | 28.27 | Sheet snaps to a detent, dock minimize |
| `spring.lift` | {550, 0.08} | 130.5 | 21.02 | **Push**: a plane rising to the front; the deck receding uses the same spring on the same `p` |
| `spring.drop` | {420, 0} | 223.8 | 29.92 | **Pop**: the front plane falling away |
| `spring.morph` | {375, 0.27} | 280.7 | 24.46 | Menu, popover and sheet blooming out of their trigger |
| `spring.tab` | {450, 0.20} | 194.96 | 22.34 | Dock droplet travel, segmented thumb travel |
| `spring.smooth` | {500, 0} | 157.9 | 25.13 | Shared-element cover flights, scroll-to, layout changes |
| `spring.letter` | {450, 0.10} | 194.96 | 25.13 | Per-letter rise and settle in the heading reveal (§6.1) |
| `spring.bouncy` | {500, 0.30} | 157.9 | 17.59 | Celebrations only: streak ignition, reaction burst, add-to-library pop |
| `spring.dive` | {700, 0} | 80.57 | 17.95 | Entering and leaving the reader |
| `spring.surface` | {800, 0.05} | 61.69 | 14.92 | Profile arrival, skin-switch recede, stack overview open |
| `spring.drift` | {1200, 0} | 27.42 | 10.47 | Parallax and gyro following, horizon palette easing |

All springs use mass 1. Flutter: `SpringDescription.withDurationAndBounce(duration:, bounce:)` (exact Apple math in SDK 3.44.6). Web: Motion 13.4.4 `{ type: "spring", stiffness, damping, mass: 1 }`; CSS-only transitions use the `linear()` easings that `design/build.mjs` pre-samples from these springs (64 samples each).

#### 2.9.3 Timed values

| Token | Value | Use |
|---|---|---|
| `dur.flash` | 90 ms | Glow-out on release |
| `dur.quick` | 150 ms | Glow-in, hover highlight, tooltip short delay |
| `dur.brisk` | 200 ms | Reduced-motion cross-fade, chip colour change |
| `dur.materialize` | 250 ms | Glass lensing 0 → 1 as it appears |
| `dur.dematerialize` | 350 ms | Glass lensing 1 → 0 as it leaves |
| `dur.paletteShift` | 600 ms | Horizon and page-tint colour changes |
| `dur.chromeIdle` | 3000 ms | Reader chrome auto-hide after a tap opened it |
| `dur.tooltipLong` | 600 ms | Tooltips on desktop (visionOS "long" delay) |
| `ease.standard` | `cubic-bezier(0.2, 0, 0, 1)` | Opacity and colour companions |
| `ease.out` | `cubic-bezier(0.16, 1, 0.3, 1)` | Blur and brightness companions of arriving planes |
| `ease.in` | `cubic-bezier(0.4, 0, 1, 1)` | Opacity of leaving elements |
| `ease.linear` | `linear` | Progress bars, typing reveal cadence |

#### 2.9.4 The depth transition (push, pop, dive)

With `p` the push progress (0 → 1) driven by `spring.lift` on push and by `spring.drop` in reverse on pop:

| Property | Incoming front plane | Plane at deck level n before the push (becomes n + 1) |
|---|---|---|
| translateY | `(1 − p) × viewportHeight × 0.92` (it rises from below) | interpolates `top(n)` → `top(n+1)` from §2.2.2 |
| scale | `0.96 + 0.04p` | `scale(n)` → `scale(n+1)` |
| brightness | 1 | `brightness(n)` → `brightness(n+1)` |
| blur | `8(1 − p)` px | `blur(n)` → `blur(n+1)` |
| top radius | 28 | `n = 0` root: 0 → 28 |
| shadow | fades in with `p` | n/a |

Desktop panes use the same `p` on x instead of y: the incoming pane enters from `translateX(48px)` at opacity 0 → 1 (`ease.out`, 250 ms companion) while the previous front pane collapses from its width to `depth.desk.spine` on the lift spring.

**Tab switch (bay to bay, same depth).** The whole bay stack pans 24 px sideways (direction = dock order) and cross-fades over `spring.tab`; nothing scales, because siblings sit at the same depth. The horizon palette eases to the new bay's colour over `dur.paletteShift`.

**Dive (into a reader).** The entire bay stack (front plane and deck together) moves to depth "d + 1.2": scale × 0.86, brightness 0.12, blur 16, on `spring.dive`; at `p = 0.45` the reader canvas (black) cross-fades in over 250 ms and the first page scales 0.92 → 1. The stack is then removed from paint. **Surfacing** (leaving the reader) runs the same curve in reverse on `spring.drop` for the page and `spring.dive` for the stack, so the stack arrives slightly after the page has gone: the app "comes up" under your finger.

**Pop to root** (tapping the active dock bay, or the root spine): planes fall in sequence front to back, 40 ms apart, each on `spring.drop`.

**Stack overview** (§3.31): all planes of the current bay rotate `rotateX(14°)` around their bottom edge and spread vertically with 28 % of their height between them, on `spring.surface`.

#### 2.9.5 Stagger rules

| Situation | Rule | Cap |
|---|---|---|
| Plane arrival (back-to-front assembly) | Horizon at 0 ms, plane content at +40 ms, headings at +60 ms (letter reveal starts here), Float controls at +90 ms (materialize) | n/a |
| Plane dismissal | Float controls dematerialize first (0 ms), then the plane drops at +30 ms | n/a |
| Rails (horizontal) | 30 ms per item for the first 6 items that are visible, then all remaining items together | 180 ms |
| Grids | Diagonal wave: `delay = 24 ms × (row + column)` | 240 ms |
| Lists | 20 ms per row for the first 8 visible rows | 160 ms |
| Menus | Rows appear with the materialize at 40 % of the morph; 18 ms per row | 108 ms |
| Letter reveal | 22 ms per letter (see §6.1) | 700 ms total; longer strings stagger by word |
| Items entering after data loads | Only the items that were skeletons animate; items already visible never re-animate | n/a |

#### 2.9.6 Interruptibility

- Every spring retargets from its current value **and velocity**. A pop during a push reverses from where the plane is, carrying its speed.
- A drag can grab any moving plane: touching a rising plane stops it under the finger (`spring.track`) and the release decides by projection.
- Release projection (Apple, r = 0.998): `projected = position + velocity_px_per_s × 0.499`. A plane drag dismisses when `projected > 0.35 × viewportHeight` or velocity > 900 px/s downward. A sheet snaps to the detent nearest to `projected`.
- Two navigations in quick succession coalesce: a push issued while a push is running starts from the current `p` of the running one; the deck shifts one more level with continuous velocity.
- Taps on a plane that is still arriving are delivered (no input lock) once `p > 0.6`.

#### 2.9.7 Reduced motion, reduced transparency, increased contrast

| Behaviour | Default | Reduce Motion (OS) |
|---|---|---|
| Push / pop | rise / drop with deck recede | 200 ms cross-fade; the deck still dims and shrinks, but instantly, so the strata edges remain as a static breadcrumb |
| Dive | stack recedes, page scales in | 200 ms cross-fade to the reader |
| Tab switch | 24 px pan + fade | 150 ms cross-fade |
| Press growth, stretch, droplet stretch | on | off; the inner glow alone answers the press |
| Menu / sheet morph | from trigger | 200 ms fade at the final position |
| Parallax, gyro specular, horizon drift | on | off (light fixed at 135°) |
| Letter reveal and typing reveal | on | whole line fades in over 200 ms |
| Stack overview | 3D fan | flat vertical list of plane cards, 200 ms fade |
| Guided view camera | spring dolly between panels | cut between panels with a 120 ms fade |
| Novel page turn | lift-and-slide | 160 ms cross-fade |
| Auto-scroll, drag scrolling | kept | kept (user-initiated) |

Reduce Transparency and the in-app **Solid glass** switch swap every glass token for its `solid.*` fallback and turn soft scroll edges hard (`rgba(0,0,0,0.92)` + `line.hair`). Increase Contrast adds 1 px 60 % white borders to glass and planes, raises `label.2` to `#C9CEDA`, and switches deck brightness to 0.40 / 0.26 / 0.16 so layered planes still separate by edge rather than by blur.

---

### 2.10 Haptics vocabulary

All haptics go through one `StrataHaptics` class that honours the in-app **Haptics** switch (default on), rate-limits to one call per 50 ms (a burst keeps the strongest), and stays on under Reduce Motion (haptics are not motion). iOS calls go through `gaimon` 1.5.0 (named impacts plus AHAP patterns); Android uses `gaimon` waveforms or the `mm/haptics` channel for API-34 constants with version guards; Android web uses `navigator.vibrate` for four events only; iOS web and desktop have none.

Depth weighting: a navigation haptic's intensity grows with the depth you arrive at: `I = 0.30 + 0.08 × depth` (depth 1–4).

| Event | iOS | Android (API 34 / older) | Android web |
|---|---|---|---|
| Push a plane (arrive at depth d) | AHAP `rise` (intensity by depth) | `GESTURE_THRESHOLD_ACTIVATE` / `VIRTUAL_KEY` | none |
| Pop a plane by button | impact `soft` 0.5 | `GESTURE_END` / `VIRTUAL_KEY` | none |
| Plane dragged past the dismiss threshold (arm) / back under it (disarm) | impact `rigid` 0.6 / selection | `GESTURE_THRESHOLD_ACTIVATE` / `CLOCK_TICK` | none |
| Pop to root (per plane passed) | selection ×n, 40 ms apart | `CLOCK_TICK` ×n | none |
| Stack overview opens / a plane is chosen in it | AHAP `fan` / impact `medium` | `LONG_PRESS` / `CONFIRM` | `vibrate(18)` |
| Dive into the reader / surface from it | AHAP `dive` / impact `soft` 0.6 | `CONFIRM` / `VIRTUAL_KEY` | none |
| Dock bay change, droplet crossing a bay while dragged | selection | `SEGMENT_TICK` / `CLOCK_TICK` | none |
| Dock minimize / expand | impact `soft` 0.3 | none | none |
| Primary tinted action (Continue, Read, Suggest) | impact `soft` 0.7 | `VIRTUAL_KEY` | none |
| Secondary glass button, icon button, chip | selection | `CLOCK_TICK` | none |
| Toggle on / off | impact `light` / selection | `TOGGLE_ON` / `TOGGLE_OFF` (`VIRTUAL_KEY`) | `vibrate(10)` |
| Segmented control, stepper, slider step, scrubber page step | selection per step | `SEGMENT_TICK` / `CLOCK_TICK` | none |
| Scrubber crosses a chapter boundary | impact `rigid` 0.7 | `GESTURE_THRESHOLD_ACTIVATE` / `CONTEXT_CLICK` | none |
| Long press → context menu lifts | impact `medium` | `LONG_PRESS` | `vibrate(18)` |
| Sheet snaps to a detent / reaches full height | selection / impact `soft` 0.6 | `SEGMENT_TICK` / `GESTURE_END` | none |
| Pull to refresh armed / refresh done | impact `rigid` 0.5 / selection | `GESTURE_THRESHOLD_ACTIVATE` / `CLOCK_TICK` | none |
| Reader: next-chapter plane locks in | AHAP `surfaceLock` | `CONTEXT_CLICK` | none |
| Reader: guided view moves to the next panel | selection | `SEGMENT_TICK` / `CLOCK_TICK` | none |
| Reader: auto-scroll speed step | selection | `SEGMENT_TICK` | none |
| Novel page turn | selection | `CLOCK_TICK` | none |
| Bookmark saved, followed, download finished, recap ready | notification `success` | `CONFIRM` (API 30) | `vibrate([12,60,12])` |
| Offline, storage nearly full, rate-limited | notification `warning` | `KEYBOARD_TAP` (API 30) | none |
| Error, download failed, action rejected | notification `error` | `REJECT` (API 30) | `vibrate([24,50,24,50,24])` |
| Profile arrives (picker commit) | AHAP `arrive` | `CONFIRM` | none |
| 18+ hold-to-confirm completes | AHAP `unlock` | `CONFIRM` + `CONTEXT_CLICK` | none |
| Streak +1 / goal met | AHAP `ignite` | waveform from `ignite` | none |
| Reaction sent | AHAP `pop` | `CONFIRM` | none |
| Recommend-to sent | AHAP `thread` | `CONFIRM` | none |
| Wrapped card flipped to its share side | impact `rigid` 0.5 | `CONTEXT_CLICK` | none |
| Skin switch confirmed | impact `heavy` | `LONG_PRESS` | none |

Never: scrolling, hover, focus, plain navigation taps inside a plane, toasts appearing, reader chrome show/hide.

**AHAP patterns** (T = transient, C = continuous, I = intensity, S = sharpness, times in s; only transients and continuous events so gaimon's Android conversion matches):

- `rise`: C@0.000 dur 0.120 I(0.20 → 0.30+0.08d) S0.70; T@0.120 I(0.30+0.08d) S0.85
- `fan`: T@0.00 I0.30 S0.9; T@0.05 I0.38 S0.9; T@0.10 I0.46 S0.9; T@0.15 I0.54 S0.85
- `dive`: C@0.000 dur 0.300 I0.35 S0.30; T@0.300 I0.55 S0.60
- `surfaceLock`: T@0.000 I0.45 S0.6; T@0.080 I0.75 S0.8
- `arrive`: C@0.000 dur 0.400 I0.25 S0.5; T@0.400 I0.70 S0.7
- `unlock`: C@0.000 dur 0.120 I0.40 S0.85; T@0.120 I0.70 S0.90
- `ignite`: C@0.000 dur 0.350 I0.30 S0.40; T@0.350 I0.85 S0.60; T@0.420 I0.40 S0.90
- `pop`: T@0.000 I0.50 S1.00; T@0.050 I0.25 S1.00
- `thread`: T@0.00 I0.30 S0.9; T@0.06 I0.40 S0.9; T@0.18 I0.60 S0.7

The patterns live as JSON assets in `mobile/assets/haptics/*.ahap.json`, generated from `design/tokens/glass.json`.

---

### 2.11 UI sounds: "Strata" (off by default)

A tonal layer in **E-major pentatonic** where pitch follows depth: the deeper you go, the higher the note, so a push-push-pop sequence is a small rising and falling phrase. The layer is **off by default**; Settings → Feedback → "Interface sounds" turns it on. Levels: ticks −30 dBFS, confirmations −18 dBFS, the logo −12 dBFS. Every file has 5 ms fade-in and fade-out. 48 kHz, 16-bit mono WAV, all synthesized with `sox -n` (the tool's output carries no licence), under 320 KB for the whole set.

Scale: E5 659.25 Hz · F♯5 739.99 · G♯5 830.61 · B5 987.77 · C♯6 1108.73 · E6 1318.51. Timbre: sine plus an FM bell (ratio 3.5, index 1.2) and a 1.0 s plate reverb at 16 % wet.

| Sound | Trigger | Recipe |
|---|---|---|
| `push-1` … `push-4` | Push arriving at depth 1–4 | sine glide from one step below to F♯5 / G♯5 / B5 / C♯6, 90 ms, bell attack |
| `pop` | Any pop | the reverse glide of the current depth, 80 ms, −3 dB |
| `root` | Pop to root | descending 3-note run ending on E5, 40 ms steps |
| `fan` | Stack overview opens | 4 grains E5 G♯5 B5 E6, 30 ms apart |
| `tap` | Glass button press | 1.2 kHz sine, 14 ms |
| `detent` | Sheet detent, slider step | 2.4 kHz click, 6 ms, −30 dBFS |
| `toggle-on` / `toggle-off` | Switches | G♯5 → B5 / B5 → G♯5, 60 ms each |
| `sheet-up` / `sheet-down` | Sheets | sine glide 520 → 1040 Hz / reverse, 110 ms |
| `success` | Follow, bookmark, download done | E5 + B5 bell dyad, 250 ms |
| `error` | Errors | B4 493.88 → G♯4 415.30, 90 ms each, soft |
| `dive` | Enter the reader | low E4 329.63 sine swell 280 ms with a low-pass sweep 3 kHz → 600 Hz (the only downward sound: diving into the dark) |
| `ignite` | Streak | 5 E6 grains 40 ms apart, rising level |
| `react` | Reaction sent | C♯6 pluck, 70 ms |
| `logo` | Logo reveal | E5, G♯5, B5, E6 at 24 ms steps plus a 1.2 s air pad |

Example: `sox -n -r 48000 -b 16 -c 1 strata-tap.wav synth 0.014 sine 1200 fade 0.005 0.014 0.005 gain -30`.

Rules: iOS UI sounds use the `.ambient` session category and obey the silent switch. No UI sound plays while narration or a soundscape is playing (the app's audio session is SPEECH during narration and is never switched mid-play). Sounds never duck the user's music. Playback: `flutter_soloud` 5.1.4 on mobile (low latency, the one audio dependency the Glass skin adds); the Web Audio API on the web (buffers decoded on the first user gesture, played with `AudioBufferSourceNode`).

---
## 3. Component catalog

Every component names its depth level. State columns use the same eight states everywhere: **default, hover** (pointer devices only, `@media (hover: hover)`), **pressed, focused** (`:focus-visible` / keyboard highlight mode), **disabled, loading, selected, error**. "n/a" means the state cannot occur for that component, never that it was forgotten.

Shared press behaviour for all glass (L5–L8) controls, called **glass press** below: on pointer-down the control grows by `min(17 px, 0.35 × longest side)` on its longest side (proportional on the other) on `spring.press`, an inner radial glow (`rgba(255,255,255,0.16)`, 140 px radius, centred on the touch point) fades in over `dur.quick`, and while held the control stretches up to 6 % along the drag direction (`scaleX = 1 + 0.06 × clamp(dx / width)`, the cross axis at `1/√scaleX`). Release returns on `spring.press` and the glow fades in `dur.flash`. Opacity never drops on press. Reduced motion keeps only the glow.

Shared press behaviour for plane (L3) controls, called **slab press**: fill steps to `fill.1` in 60 ms and the content scales to 0.98 on `spring.press`; release returns in 150 ms.

Shared hover for glass: the glow layer at 0.08 opacity, following the pointer, no delay; the specular angle leans ±8° toward the pointer. Shared hover for slabs: `fill.3` wash in `dur.quick`.

### 3.1 Buttons

Five variants, three sizes. Labels are `button` style, sentence case, never uppercase.

| Size | Height | Horizontal padding | Icon | Hit area |
|---|---|---|---|---|
| L | 52 | 26 | 22 | 52 |
| M | 44 | 20 | 20 | 44 (48 on Android) |
| S | 32 | 14 | 16 | 44 (padding grows the hit area) |

**Primary (`glass.tint`, L5).** Iris glass capsule, `irisInk` label and glyph. Exactly one per plane; it is the plane's answer to "what now?" (Continue, Read, Start reading, Suggest, Save, Create profile).

| State | Visual |
|---|---|
| default | `glass.tint`, shadow `0 6px 24px rgba(169,155,255,0.34)` |
| hover | glow 0.08 + shadow opacity 0.46, specular leans to the pointer |
| pressed | glass press; fill brightens to Iris 92 %; haptic `soft` 0.7 |
| focused | `focus.ring` (Glacier) outside the capsule, offset 2 px |
| disabled | fill `rgba(169,155,255,0.24)`, label `rgba(12,10,26,0.55)`, no shadow, no press; reason shown in the tooltip or in the helper line below |
| loading | label cross-fades to an `orbit` spinner (16 px) plus the progressive verb ("Saving"), width locked to the widest label so the capsule does not jump; pointer events off |
| selected | n/a |
| error | a 240 ms horizontal shake (±6 px, 3 cycles, `spring.tick`), haptic `error`, then the error text appears under the button; the button stays enabled |

**Secondary (`glass.float`, L5).** Clear-glass capsule with a `label.1` label. Used for the second action (Follow, Read all, Download, Add to collection).

| State | Visual |
|---|---|
| default | `glass.float` |
| hover | glass hover |
| pressed | glass press, haptic selection |
| focused | `focus.ring` |
| disabled | fill `rgba(255,255,255,0.03)`, label `label.4` |
| loading | as primary |
| selected | used as a toggle (Following): fill `rgba(255,255,255,0.14)`, leading `Check` glyph, label changes ("Following") |
| error | as primary |

**Plain (L3, on planes).** Text-only button in `label.1` (or Iris for the inline "See all"). No fill at rest; slab press. Used in rows and section headers.

**Destructive.** On glass surfaces (menus, sheets): a row or capsule whose label and glyph are `color.danger`. In the Veil confirm that performs the destruction: a filled capsule `#FF6B7A` with a `#000000` label (7.64:1). Destructive actions that remove user data always offer an Undo toast (§3.12) unless the server makes undo impossible (account deletion, restore), in which case the confirm uses a typed phrase or a hold (§3.11).

**On-media (`glass.clear`).** Over the Home stage and series header art only: clear glass capsule with a `label.1` label and `veil.media` beneath when the art under it is bright. States as secondary.

**Split Continue.** The series plane's primary action: a primary capsule with a 1 px `rgba(12,10,26,0.25)` divider 12 px from the right edge and a 36 px `CaretDown` segment. The main segment continues reading; the caret opens the chapter menu (morphs from the segment). Both segments are separate hit areas with separate focus stops.

**Motion.** Appearance: glass buttons materialize (lensing 0 → 1 over 250 ms, opacity 0 → 1 over the first 150 ms) as part of back-to-front assembly. A button that changes label animates width on `spring.smooth` and cross-fades labels over 150 ms.

### 3.2 Icon buttons

| Variant | Size | Level | Use |
|---|---|---|---|
| Float circle | 44 (glyph 22) | L5 `glass.float` | Back, close, top-right actions on planes, reader chrome |
| Float cluster | 44 tall capsule holding 2–4 glyphs, 44 wide each, 0 gap, dividers `line.hair` at 50 % height | L5 | Top-right action groups (Filter · Sort · Select) |
| Plain | 44 hit, glyph 20–24, no fill | L3 | Row trailing actions (pin, remove), card overlays |
| Small | 32 visual, 44 hit | L3 | Chapter download control, bookmark remove |
| Toggle | any of the above | | Bookmark, favourite, pin, notify: Regular glyph when off, Fill glyph when on, a 150 ms cross-fade plus a `spring.bouncy` scale 1 → 1.18 → 1 on turning on |

| State | Float circle / cluster | Plain / small |
|---|---|---|
| default | `glass.float`, glyph `label.1` | glyph `label.2` |
| hover | glass hover | `fill.3` circle behind the glyph, glyph `label.1` |
| pressed | glass press; haptic selection | slab press on a `fill.1` circle |
| focused | `focus.ring` circle | `focus.ring` circle |
| disabled | glyph `label.4`, no glow | glyph `label.4` |
| loading | glyph replaced by `orbit` spinner 18 px | same |
| selected (toggle on) | glyph Fill weight; for bookmark and favourite the glyph turns Iris | glyph Fill, Iris |
| error | glyph turns `danger` for 1.2 s with a single shake, tooltip carries the message | same |

**Badge on an icon button:** a count capsule 18 px tall, `caption2` w700, Iris fill with `irisInk` text, anchored top-right at (−4, −4); "99+" above 99; a dot variant (8 px) when the count is unknown. It pops in on `spring.bouncy` from scale 0.4.

Every icon button has an accessible label and, on desktop, a tooltip after `dur.tooltipLong` showing the label and its key hint.

### 3.3 Text inputs

**Field.** 52 px tall (48 on desktop), radius 16 (a rounded rectangle, not a capsule, so multi-field forms align), `slab.3` fill, 1 px `line.strong` border, 16 px inner padding, optional 20 px leading glyph in `label.2`. The label sits above the field (`subhead` w560 `label.2`), 6 px gap. Helper text below in `footnote` `label.3`.

| State | Visual |
|---|---|
| default | as above; placeholder `slate600` |
| hover | border `rgba(235,240,255,0.26)` |
| pressed | n/a (focus follows) |
| focused | border 1.5 px Glacier, a 4 px outer glow `rgba(143,216,255,0.18)`, caret Glacier; the field lifts 1 px (L3 + 1) on `spring.tick` |
| disabled | fill `slab.2`, text `label.4`, border `line.hair` |
| loading | trailing `orbit` spinner 16 px (used by server-URL validation and invite-code checks) |
| selected | n/a |
| error | border 1.5 px danger, trailing `WarningCircle` in danger, message below in `footnote` danger, `aria-invalid`; the field shakes once (±4 px) on submit |

**Password.** Field plus a trailing plain icon button `Eye` / `EyeSlash` ("Show password" / "Hide password"), not in the tab order on web (reachable with `alt+v` while the field is focused).

**Textarea (AI prompt, bookmark note).** Same material, radius 20, min 3 lines, max 8 before scrolling, character counter bottom-right in `mono.meta` `label.3` (turns warning at 90 % of the limit, danger at the limit). `Enter` submits and `Shift+Enter` inserts a newline where the field is a prompt.

**Stepper.** A capsule `slab.3` 44 px: `−` and `+` 44 px circles (`fill.2`, glyph `label.1`) around a value in `mono.meta` 15 px. Buttons disable at bounds. Holding a button repeats after 400 ms at 8 steps per second. Haptic selection per step.

**Numeric go-to field.** A 96 px capsule field with the placeholder showing the current value ("142") and a trailing "/ 380" in `label.3`; `Enter` jumps, `Esc` clears. Used for page and chapter jumps.

**Typed confirm.** Field whose submit button stays disabled until the typed text matches the phrase case-insensitively; the matched characters turn from `label.2` to `label.1` as they are typed.

### 3.4 Search

**Search orb (phone, L5).** A 56 px glass circle sitting 10 px to the right of the dock, `MagnifyingGlass` 24 px. Tap: the orb morphs (`spring.morph`) into a full-width search field at the bottom (height 52, capsule, `glass.float`, inset 20 px), the keyboard rises, and the Search plane rises behind the field. The dock dematerializes during the morph and returns when search is dismissed.

**Search field (the expanded orb, and the Search plane's field).** Capsule 52 px, `glass.float`, leading glyph, trailing clear `X` when non-empty. There is no voice input. While a query runs, the leading glyph becomes an `orbit` spinner.

**Desktop search.** The sidebar holds a 40 px capsule field "Search  ⌘K". Clicking it (or `⌘K`/`Ctrl K`, or `/` on screens without their own field) morphs the field into the command palette (§3.28).

**Scope control.** A segmented control (§3.6) under the field: All · Library · Sources · Dialogue (Dialogue appears in Manga mode only). The thumb is glass while it moves.

**Suggestions.** While typing on a phone, suggestions stack **above** the field (nearest to the thumb) as Lift-level rows (`glass.lift` panel, radius 28, rows 48 px): recent queries (`ClockCounterClockwise`), library matches (cover 28 × 42), and "Search every source for '{q}'" as the last row.

| State | Orb | Field |
|---|---|---|
| default | glass, glyph `label.1` | glass, placeholder `label.2` |
| hover | glass hover | glass hover |
| pressed | glass press | caret placement, no press effect |
| focused | `focus.ring` | Glacier 1.5 px inner border + glow |
| disabled | n/a | n/a |
| loading | n/a | orbit spinner in place of the glyph |
| selected | the orb gets an Iris inner glow while the Search bay is active | n/a |
| error | n/a | trailing `WarningCircle` danger + inline message row under the field |

### 3.5 Chips

All chips are capsules on planes (L3, content layer) and become glass only while being dragged.

| Variant | Height | Visual at rest | Selected | Use |
|---|---|---|---|---|
| Filter chip | 34 | `fill.2`, label `subhead` w560 `label.1`, optional count in `mono.meta` `label.2` | `rgba(255,255,255,0.92)` fill, `#000` label, leading `Check` 14 px | Status filters, source filters, search group filters |
| Choice chip | 34 | same | same; only one selected in its group | Retention period, storage cap, speed presets |
| Input chip | 32 | `fill.2` with a trailing 16 px `X` (hit 32) | n/a | Recent searches (remove), active filter summary |
| Genre tag | 28 | `line.strong` 1 px outline, no fill, `caption1` w600 +0.04 em, sentence case | n/a | Series genres (tap filters the source) |
| Suggestion chip | 36 | `slab.3` with a leading `Sparkle` 14 px Iris | n/a | AI example prompts |
| Status chip | 26 | status tint fill + status glyph 12 px + status label `caption1` w600 in the status colour | n/a | Reading status on cards and rows |
| Person chip | 32 | `rgba(255,158,216,0.16)` fill, 20 px avatar orb, Bloom label | n/a | "From Aya", "Aya is reading" |

| State | Visual |
|---|---|
| hover | `fill.1` |
| pressed | slab press; haptic selection |
| focused | `focus.ring` |
| disabled | `fill.3`, label `label.4` |
| loading | the count is replaced by a 12 px orbit spinner |
| error | outline 1 px danger for 1.2 s |

Selection change animates fill and label colour over `dur.brisk` and the check glyph grows in on `spring.tick`. Chip rails scroll horizontally with 16 px edge fades (mask) and 8 px gaps.

### 3.6 Segmented control

A capsule track 36 px (32 in compact reader sheets), `fill.2` on planes or `rgba(255,255,255,0.10)` on glass; segments share the width equally; label `subhead` w600. The **thumb** is a capsule inset 2 px: `slab.3` + `rim.float` at rest, and it becomes `glass.clear` (lensing the labels under it) while travelling or being dragged, then settles back to solid.

| State | Visual |
|---|---|
| default | unselected labels `label.2`, selected label `label.1` |
| hover | hovered segment label `label.1` |
| pressed | thumb stretches toward the pressed segment by up to 12 % before travelling |
| focused | `focus.ring` around the whole track; arrow keys move selection |
| disabled | track `fill.3`, labels `label.4`; a disabled single segment shows its label at `label.4` and refuses the thumb |
| loading | n/a |
| selected | thumb under the segment |
| error | n/a |

Motion: thumb travel on `spring.tab`; while dragged it follows on `spring.track` and stretches `scaleX = 1 + clamp(|v| / 2000, 0, 0.25)`; each segment boundary crossed plays selection haptic. Reduced motion: thumb jumps, 150 ms cross-fade.

### 3.7 Cards

Cards are content (L3): solid slabs, never glass.

**Continue card ("deck card").** 280 × 132 on phone rails (320 × 148 desktop), `slab.1`, radius 20, padding 12. Left: a stack of two images, the cover (72 × 108, radius 14) in front and, peeking 10 px above and 8 px to its right behind it, a crop of the next page to read (the chapter's current page thumbnail) at brightness 0.56; the two read as a tiny deck. Right: title `headline` 2 lines, chapter line `mono.meta` `label.2` ("CH 142 · p. 12 / 40"), a progress ring 28 px (2.5 px stroke Iris on `fill.2`) with the percent inside in `caption2`. Nudge line when relevant (`caption1` `label.2`): "3 new since you caught up", "2 chapters left", "Paused 21 days". Tap resumes at the exact page (with a "Previously on" recap first when it applies, §5.1.5).

**World card (recommendation).** Two visibly different variants:
- *Available* (on one of your sources): 160 × 300 portrait card, cover 160 × 240 radius 14, title `headline`, meta `caption1` ("Manhwa · Ongoing · 142 ch"), rating in `mono.meta` with `Star` 12 px, availability person-style chip in Iris tint "On Asura +2". Tap opens the series plane (a source picker menu first when there are several).
- *Info only* (not on your sources): the same card with the cover at brightness 0.72, a 1 px dashed `line.strong` outline around the whole card, and two plain buttons under it: "Search my sources" and "Read on {site}" (`ArrowSquareOut`). The dashed outline is the "not here yet" signal, repeated in the accessibility label.
- Optional `why` line (AI reason) under either variant: `footnote` `label.2`, 2 lines, leading `Sparkle` 12 px Iris.

**Notification card (Updates).** Row-shaped card `slab.1` radius 20: cover 44 × 66, series title `headline`, "3 new chapters" `subhead` Iris, chapter list collapsed to the newest 3 as `mono.meta` lines ("CH 143 · 2 h ago"), trailing plain button "Read". Unread cards carry a 6 px Iris dot left of the title.

**Bookmark card.** `slab.1` radius 20, 16 padding: series title `headline`, position `mono.meta` ("CH 14 · 62 %" / "CH 3 · ¶ 118"), novel snippet in the reading serif italic `callout` 3 lines, note in `subhead` `label.1`, saved date `caption1` `label.3`, stale note in warning with `WarningCircle` ("The text changed here; this opens at the nearest spot").

**History tile.** A poster (§3.8, size M) with a 3 px progress line along its bottom edge (Iris on `rgba(255,255,255,0.18)`), and under it title 2 lines + `mono.meta` "CH 12 · 3 h ago" (or "CH 12 · done"). A 36 px glass circle on the cover's bottom-right carries `Play` ("Continue") or `SkipForward` ("Next").

**Activity card (Circle).** 100 % width `slab.1` radius 20: 32 px friend orb with a Bloom ring, sentence in `callout` ("Aya finished **Omniscient Reader** chapter 212"), relative time `caption1` `label.3`, trailing cover 40 × 60; reactions row (up to 3 reaction glyphs with counts) under the sentence.

**Stat tile.** `slab.1` radius 20, 16 padding: glyph 20 px `label.2`, value in `mono.figure` (scaled to 36 px in tiles), label `caption1` `label.2`, delta line ("+12 % vs last month") in success or `label.3`.

**Collection stack.** A card showing up to 4 member covers fanned in depth: covers 96 × 144 at x offsets 0 / 18 / 36 / 54 px, each one step deeper scaled 0.94 and at brightness 0.8 / 0.65 / 0.5, over `slab.1` radius 20; name `headline`, count `mono.meta`, a "Shared" person chip when the collection is shared (§5.3). Hover (desktop) or press-and-hold (phone): the fan spreads to 28 px offsets on `spring.bouncy`.

**Source row card.** `slab.2` row, radius 20 in a grouped well: 44 px source logo (radius 12; letter monogram on a hue hashed from the source id when there is no icon), name `headline`, description `subhead` `label.2` 1 line, "18+" badge when mature, trailing pin icon button, and a freshness dot (success fresh, warning stale, danger failing health).

**Recap card, voice card, Wrapped card:** specified with their features (§5.1.5, §4.16.3, §5.2.4).

Card states (all variants):

| State | Visual |
|---|---|
| default | as specified |
| hover | lifts to L3 + 4 px: `translateY(-2px)`, shadow `0 14px 36px rgba(0,0,0,0.55)`, cover brightness 1.06, on `spring.smooth`; text never gets depth |
| pressed | slab press (scale 0.98) |
| focused | `focus.ring` + the hover lift |
| disabled | 0.45 opacity with the reason in the meta line ("Unavailable on this profile") |
| loading | skeleton of the same shape (§3.18) |
| selected | `select.ring` + a 24 px Iris check disc top-right |
| error | cover replaced by the monogram placeholder; a quiet `WarningCircle` 14 px in the meta line with the reason |

### 3.8 Posters

2:3 covers, radius 14, `slab.1` placeholder with the series monogram (first letter, `title2` `label.3`) and a vertical gradient from the palette's `darkVibrant` at 40 % when a palette is known.

| Size | Phone | Desktop | Use |
|---|---|---|---|
| S | 88 × 132 | 104 × 156 | Dense grids, search shelves, source catalogue |
| M | 112 × 168 | 136 × 204 | Library grid, rails |
| L | 148 × 222 | 176 × 264 | Featured rails ("Because you read") |
| XL | 200 × 300 | 240 × 360 | Series header |
| Hero | full-bleed stage | 560 × 840 max | Home stage |

Overlays (all on the cover, all L3 unless noted):
- Top-left: status chip (library views) or the "18+" badge (never both; 18+ wins).
- Top-right: new-chapters badge "3 NEW" (`caption2` w700, Iris fill, irisInk), or the select check disc in select mode.
- Bottom edge: 3 px progress line when started.
- Bottom-right: downloaded mark (a 20 px `slab.1` circle with `CheckCircle` 14 px success) when fully saved offline, a 20 px download ring when saving.
- Title under the cover: `subhead` w600 `label.1` 2 lines; meta `caption1` `label.2` 1 line ("CH 12 of 40", "Not started", "Caught up").

| State | Visual |
|---|---|
| default | as above; the image fades in over 250 ms and settles from scale 1.02 to 1 on `spring.smooth` |
| hover (desktop) | L3 + 4 px lift, cover brightness 1.06, and a 3° tilt toward the pointer with the specular sheen `radial-gradient(160px at pointer, rgba(255,255,255,0.10), transparent 60%)`; quick-action capsule (Follow · Favourite · ⋯) materializes on the cover's bottom edge after 150 ms |
| pressed | scale 0.97 on `spring.press`; long press (500 ms) lifts it into the context menu (§3.23) |
| focused | `focus.ring` + lift; arrow keys move focus through the grid |
| disabled | brightness 0.4 + "Unavailable" meta |
| loading | skeleton poster (§3.18) |
| selected | `select.ring`, cover brightness 0.8, Iris check disc top-right, a `spring.tick` pop |
| error | monogram placeholder with `ImageBroken` 20 px `label.3`; tapping still opens the series |

**Cover flight.** A poster tapped anywhere is the shared element of the plane it opens: it lifts to L5 during the flight (shadow grows, rim appears) and lands as the XL header poster on `spring.smooth` (§8, moment 3).

### 3.9 Rails

Horizontal lists on planes. Header row: section title in `title2` (with the letter reveal, §6.1) + an optional subline in `subhead` `label.2` + trailing plain button "See all" (`CaretRight` 14 px) that pushes a grid plane. Items snap to the leading edge (`scroll-snap-align: start`, Flutter `PageScrollPhysics`-style snapping on item boundaries with `spring.smooth` settle). Leading inset equals the screen margin; trailing padding 32 px. Edge fades: 16 px mask on the trailing edge only while more content exists.

- Desktop: glass float circles (36 px) with `CaretLeft`/`CaretRight` appear at the rail's ends on hover and page by 80 % of the visible width. Each rail is one tab stop; arrow keys move within it, `↑`/`↓` move between rails keeping the column.
- AI rails carry a 14 px `Sparkle` before the title and their `why` in the subline.
- States: loading = 5 skeleton posters with the header skeleton; empty = the rail is omitted (never an empty rail); error = a single-line row "Couldn't load {rail}. Retry" with a plain Retry button in the rail's place; offline = the rail shows only items available offline, or is omitted.

### 3.10 Sheets

Sheets are Lift (L6) surfaces. They **do not** push the deck back (they are not navigation); they sit over the current plane with `veil.sheet` behind them.

| Detent | Height | Shape | Material |
|---|---|---|---|
| peek | 96 px + safe bottom | inset 8 px from sides and bottom, radius `deviceRadius − 8` (36 when unknown) | `glass.lift` |
| medium | 50 % of the viewport | inset 8 | `glass.lift` |
| large | viewport − safeTop − 10 | attached to sides and bottom, top radius 28 | `glass.lift` fading to `solid.lift` over the last 20 % of travel (Apple: opaque at full height) |

Anatomy: grabber 36 × 5 capsule `rgba(255,255,255,0.32)` 8 px from the top; header row 56 px (title `headline` centred, leading/trailing plain buttons such as "Cancel"/"Done" or a 32 px close circle `fill.2`); content with 16 px margins; a sticky footer for primary actions (primary capsule L, full width minus 32).

Motion: sheets **morph out of their trigger** when there is one (`spring.morph`, the trigger's glass becomes the sheet's glass), otherwise rise from the bottom on `spring.lift`. Dragging follows the finger on `spring.track`; release snaps to the detent nearest the projected position on `spring.detent` with a selection haptic; dragging below peek by 35 % of the sheet or at > 900 px/s dismisses on `spring.drop`. The inset lerps 8 → 0 as the sheet approaches large. Content scrolling hands off to the sheet drag at the top of the scroll. Two sheets can stack: the lower one scales to 0.94 and dims to 0.7 (it recedes one step, the same deck rule in miniature); a third sheet replaces the second.

Desktop: sheets become **floating panels** anchored to their trigger (width 400–560 px, radius 28, `glass.lift`), morphing from the trigger; a centred modal panel (560 px) when there is no trigger. `Esc` closes. Focus is trapped inside and returns to the trigger.

| State | Visual |
|---|---|
| default | as above |
| hover | grabber brightens to 0.5 |
| pressed | grabber held: the sheet follows the finger |
| focused | focus moves to the first control; the grabber is focusable and resizes with `↑`/`↓` |
| disabled | n/a |
| loading | content skeletons inside; header stays live |
| selected | n/a |
| error | an inline banner (§3.30) at the top of the sheet content |

### 3.11 Dialogs and alerts

Veil (L7) surfaces with `veil.modal` behind.

**Alert.** 320 px wide on phone (min(420, 90 vw) on desktop), radius 28, `glass.lift`, 24 px padding. Title `title3` w660 left-aligned, body `callout` `label.2` left-aligned, actions stacked full-width capsules M (phone) or right-aligned side by side (desktop): the safe action first on phone (top), last on desktop (rightmost is the confirm). Springs out of the control that triggered it on `spring.morph`; otherwise scales 0.92 → 1 at centre on `spring.morph`.

**Destructive confirm.** Alert whose confirm is the filled danger capsule. Undoable actions skip the dialog and use an Undo toast instead: unfollow, remove bookmark, remove download, remove from collection, bulk actions.

**Hold-to-confirm.** For the 18+ gate and "Sign out everywhere": the confirm capsule fills from left to right over 1200 ms while held (Rose for 18+, danger for sign-out), with a selection tick every 300 ms and the completion AHAP; releasing early drains the fill on `spring.drop`. Keyboard: hold `Enter` or `Space` for the same 1200 ms; screen readers get a normal double-tap button with the same label (holding is not required under VoiceOver/TalkBack, per the pointer-cancellation rule).

**Typed-phrase confirm.** For Restore backup: a typed confirm field (§3.3) inside the alert; the danger capsule enables when "RESTORE" matches.

| State | Visual |
|---|---|
| default / focused | focus lands on the safe action; `Tab` cycles within; `Esc` = safe action |
| pressed | glass press on actions |
| loading | the confirm shows its progressive verb and spinner; other actions disable |
| error | inline danger line above the actions; the alert stays open |
| hover, disabled, selected | per button rules |

### 3.12 Toasts (HUD, L8)

Capsule 48 px tall, `glass.float` compact (blur 10, fill `rgba(20,22,28,0.64)`), max width 520 px, anchored top-centre at `safeTop + 8` on phone (it drops from above, the direction of the HUD level) and bottom-centre 24 px above the viewport edge on desktop. Leading glyph 20 px in the semantic colour, message `subhead` `label.1` 1–2 lines, optional trailing plain action ("Undo", "View", "Retry") in Iris.

- Enter: materialize + drop 16 px on `spring.detent`. Exit: dematerialize + rise 12 px.
- Duration: 4000 ms; 8000 ms with an action; 10000 ms for the skin-switch Undo; indefinite for progress toasts (downloads, restore).
- Stack: max 2 visible; the older one recedes (scale 0.94, brightness 0.7, 8 px up) behind the newer.
- Swipe up (phone) or click the `X` that appears on hover (desktop) dismisses.
- Progress toast: a 2 px Iris progress line along the bottom inner edge.
- Screen readers: `role="status"` (`aria-live="polite"`); errors `role="alert"`.
- States: hover pauses the timer; focused shows the `X`; pressed on the action = glass press.

### 3.13 In-page tabs

Used inside planes for sibling views (Downloads: Chapters · Storage; Stats: Overview · Year; Circle: Activity · Collections · Recommendations). A segmented control (§3.6) sits under the large title; on phones the tab content also swipes horizontally with `scroll-snap-type: x mandatory` (web) / `PageView` (Flutter), and the thumb tracks the swipe progress continuously. `[` and `]` switch tabs on desktop.

### 3.14 Top controls (planes have no bars)

Strata has no full-width top bars. Each plane carries:

- **Back circle** (L5, 44 px) at the top-left, `CaretLeft`. Long press (phone) / hover 600 ms or right-click (desktop) opens the stack overview (§3.31). On a root plane the slot shows the **You orb** instead (§4.24).
- **Action cluster** (L5) at the top-right: one float circle or a cluster capsule.
- **Large title** in the content at the top of the scroll (`largeTitle`, with the letter reveal on first arrival), 12 px below the controls row.
- **Title capsule** (L5): when the large title scrolls under the controls, a compact capsule (36 px, `glass.float`, title in `headline`, max 60 % width) materializes centred between the back circle and the cluster, on `spring.detent`, with the large title shrinking into it (a shared element: font size interpolates 34 → 17, y follows the scroll). It dematerializes in reverse when scrolling back up.
- **Scroll edge** (L4) under the controls (§3.32).

Desktop panes: the back circle becomes a 36 px circle inside the pane's top-left (only when the pane is not the root); the cluster sits top-right of the pane; the title capsule does not exist (the pane header is sticky: `title2` with `line.hair` under it once scrolled).

States: back circle and cluster follow §3.2. The title capsule is not interactive except that tapping it scrolls the plane to the top (`spring.smooth`).

### 3.15 Dock, search orb and bottom accessory (phone, tablet portrait, mobile web)

**Dock.** A floating glass capsule (L5, `glass.float` liquid tier), 62 px tall, inset `layout.dock.inset` (20 px) from the left and from the bottom safe area, ending 10 px before the 56 px search orb, which sits at the right inset. Four **bays**, each an equal share of the width: Home (`HouseSimple`), Library (`Books`), Sources (`Compass`), Updates (`BellSimple`). Icon 24 px over a `tabLabel` label, both `label.2`; the selected bay shows its Fill icon and `label.1` label inside the **droplet**.

- **Droplet**: a capsule 48 px tall inset 7 px, width = bay width − 8, `glass.clear` with an Iris inner glow `inset 0 0 12px rgba(169,155,255,0.30)`. It travels between bays on `spring.tab`. Dragging along the dock moves it under the finger (`spring.track`), stretching `scaleX = 1 + clamp(|v| / 2000, 0, 0.25)`; each bay crossed plays selection; release selects the bay under it.
- **Badges**: Updates shows the unread count; Library shows the active download count when downloads run (a ring badge around the count). Counts are in the accessibility label ("Updates, 12 new").
- **Minimize**: after 24 px of cumulative downward scroll in the bay's plane, the dock shrinks to a 50 px circle holding only the selected bay's icon (left-aligned at the inset) on `spring.detent`; after 12 px of upward scroll, a tap on the circle, or reaching the top, it expands again. The search orb shrinks to 50 px with it.
- **Tap the selected bay**: if planes are pushed, pop to root (§2.9.4); otherwise scroll to top on `spring.smooth`.
- **Long press a bay**: a context menu blooms from the bay: Home → "Continue {last series}", "Surprise me"; Library → the five most recent collections plus "All collections"; Sources → pinned sources; Updates → "Mark all read", "Check now".
- Hidden in readers, the picker, auth, setup and full-height sheets; materializes back with back-to-front assembly.

**Bottom accessory.** A 52 px glass capsule 10 px above the dock, same inset as the dock + orb width. One slot, filled by priority: (1) **narration mini player** (voice orb 32 px pulsing with the audio level, chapter title `subhead`, "18 min left" `caption1`, play/pause 36 px, a 2 px progress line along the bottom inner edge); (2) **download queue** ("Saving 3 chapters · 42 %", ring 24 px, tap opens Downloads); (3) **Continue pill** on Home only, once the Continue hero has scrolled away ("Continue *Solo Leveling* · CH 142", Play glyph). When the dock minimizes, the accessory shrinks to 50 px and moves **inline** between the minimized dock circle and the orb, keeping its glyph and a truncated title. Swipe the accessory left/right: previous/next chapter (narration) with a selection haptic.

| State | Dock bay | Orb | Accessory |
|---|---|---|---|
| default | icon Regular, label `label.2` | glass | glass |
| hover (tablet web) | glyph `label.1` | glass hover | glass hover |
| pressed | the droplet pre-stretches toward the pressed bay; selection haptic on change | glass press | glass press |
| focused | `focus.ring` around the bay | ring | ring |
| disabled | n/a | n/a | n/a |
| loading | n/a | n/a | narration "Preparing audio" with an orbit spinner in the play slot |
| selected | Fill icon, `label.1`, droplet | Iris inner glow when the Search plane is open | n/a |
| error | n/a | n/a | glyph `WarningCircle` danger + "Audio couldn't load. Tap to retry" |

### 3.16 Desktop sidebar (desktop and wide web; tablet as a rail)

A floating glass pane (L5, `glass.float` with `blur.lift` because it is large; Apple: large glass does not flip light/dark), 264 px wide, inset 12 px from the window's top, left and bottom, radius 28; content planes extend under it (the pane refracts the horizon and the root plane behind it).

Top to bottom:
1. Wordmark single-line (§7.1) 28 px tall, 20 px from the top, clickable to Home.
2. Search capsule "Search  ⌘K" (40 px, `fill.2`).
3. Mode switch (§3.34) full width, when novels are enabled.
4. Primary group: Home, Library, Sources, Updates (with count), Search, Downloads (with active count).
5. Group label "Your reading" (`caption1` w600 `label.3`, sentence case): For you, Collections, History, Bookmarks, Stats, Circle, Dialogue search (Manga mode only).
6. Spacer.
7. Footer: You row (32 px avatar orb with the streak ring, profile name `headline`, account `@username` `caption1`), Settings, System status (admin).

Rows: 40 px, radius 20 (concentric with the 28 px pane at 8 px padding), glyph 20 + label `callout` w520.

| State | Row |
|---|---|
| default | glyph and label `label.2` |
| hover | `rgba(255,255,255,0.06)` capsule, `label.1` |
| pressed | `rgba(255,255,255,0.12)`, scale 0.98 |
| focused | `focus.ring` |
| disabled | n/a |
| loading | a count shows an orbit spinner while it refreshes |
| selected | a glass-clear droplet capsule (same as the dock droplet) behind the row, Fill glyph, `label.1`; the droplet travels between rows on `spring.tab`. Only the exact destination lights: Library does not light when Collections is selected |
| error | n/a |

Collapse: `⌘B`/`Ctrl B` or the chevron button at the top-right corner collapses to a 76 px rail (icons only, tooltips after 150 ms); width animates on `spring.detent` and the wordmark morphs into the MM column mark. Below 1024 px the rail is the default; below 768 px the dock replaces the sidebar.

### 3.17 Lists and rows

**Grouped list** (settings, detail facts, You hub). Wells `slab.1`, radius 20, 16 px margins; rows 52 px (44 compact) with 16 px padding, `line.hair` separators inset 52 px when a leading glyph exists; leading glyph 20 px in a 30 px `fill.2` rounded square (radius 8); title `body`; value or detail `body` `label.2` trailing; accessory `CaretRight` 14 px `label.3`, a switch, or a check. Section header above a well: `footnote` w600 `label.2`, 8 px gap; section footer: `footnote` `label.3`.

**Plain row.** Full-width on the plane, no well; separators `line.hair`.

**Chapter row.** 64 px (72 with a title line). Leading number column 56 px: chapter number in `mono.meta` 15 px w600 (`label.1` unread, `label.3` read). Title `callout` 1 line ("Chapter 142" or its title), secondary line `caption1` `label.2`: upload date ("Today", "Yesterday", "5 d ago", then "12 Sep 2026") · pages ("12 / 40" in Iris when in progress, "40 pages") · reaction summary when the circle reacted. Trailing: download control (§3.29) and a `CaretRight` on hover. Read rows show text at `label.3`; the in-progress row has a 3 px Iris bar along its bottom edge at the progress fraction and a "Reading" status chip.

**Swipe actions (phone).** Rows reveal glass-free action tiles (72 px wide, full row height, `slab.3`, glyph + `caption1`): leading swipe = the positive action (Mark read, Pin, Download), trailing = the removal (Remove, Unfollow, Delete) in danger. Past 55 % of the row width the action commits with `rigid` haptic; dragging back cancels with selection haptic. Every swipe action also exists in the row's context menu.

**Reorder.** Long press 500 ms lifts the row to L6 (glass while held, `spring.press` scale 1.03, shadow `0 18px 40px rgba(0,0,0,0.6)`), siblings shift on `spring.smooth`, drop settles on `spring.tick` with light haptic. Keyboard: `Alt+↑/↓` moves the focused row. Used for pinned sources, collection order, the manual library order, and the Home rail order.

Row states: hover `fill.3`; pressed `fill.1` + slab press; focused ring inset 2 px; disabled `label.4` with reason; loading skeleton row; selected leading 22 px Iris check disc (select mode) and `rgba(169,155,255,0.08)` fill; error trailing `WarningCircle` + detail line in danger.

### 3.18 Skeletons: "depth shimmer"

Skeleton blocks take the exact shape of what will load (posters, rows, text lines at 60–90 % widths) in `slate300` with radius matching the real element. The shimmer is a **light passing through depth**: a band of `slate400` (width 40 % of the block, soft edges) sweeps diagonally at 20° across each block over 1400 ms, and blocks that sit nearer (Float before Plane content, rail headers before rail items) start 60 ms earlier, so the wave travels back-to-front. Loops with a 400 ms rest. Reduced motion: a static `slate300` block that pulses opacity 0.7 ↔ 1 over 1600 ms. When data arrives, each skeleton cross-fades to its content over 200 ms; content never jumps because skeleton sizes equal final sizes.

### 3.19 Progress

| Component | Spec | States |
|---|---|---|
| Linear bar | 4 px (6 px in cards), radius 2, track `rgba(255,255,255,0.12)`, fill Iris with a 1 px lighter top edge; value changes on `spring.smooth` | determinate; indeterminate (a 30 % segment travelling 1200 ms `ease.standard`); paused (fill turns warning, striped at 45° 6 px); error (fill danger, "Retry" nearby); complete (fill success for 600 ms then the bar collapses on `spring.detent`) |
| Ring | 16 / 24 / 28 / 44 px, stroke 2 / 2.5 / 2.5 / 3.5, track `fill.2`, Iris arc with a round cap, starts at 12 o'clock | same state set; in the download control the centre shows a `Stop` square on hover |
| Orbit spinner | the `orbit` glyph: a 3 px dot circling a tilted ellipse (rx 7, ry 3 at 16 px size) with a 2-dot trail at 50 % and 25 %, 900 ms per orbit, linear; the dot scales 1.2 at the near side and 0.8 at the far side (depth) | indeterminate only; reduced motion: dot fades in place |
| Storage meter | a 20 px capsule "liquid" meter: segments this profile (Iris), other app data (`slate600`), free (`fill.2`); the meniscus between used and free settles on `spring.bouncy` when values change | normal; near cap (> 90 %: warning outline); full (danger outline + text) |
| Reading hairline | 2 px line at the very top edge of the reader and novel planes, Iris at 70 %, width = chapter progress, `spring.track` | |
| Page counter | capsule HUD `mono.meta` "12 / 40" (§4.14) | |

### 3.20 Badges and markers

| Badge | Spec |
|---|---|
| Count | 18 px capsule, `caption2` w700, min width 18, Iris + irisInk; "99+" |
| Dot | 8 px Iris (unread), 8 px Bloom (friend activity), 8 px success / warning / danger (source health) |
| New | "3 NEW" capsule on posters (above) |
| 18+ | 20 px capsule, 1 px `color.mature` outline, "18+" `caption2` w800 in `color.mature`, no fill; appears only on content that is being shown; never a placeholder |
| Source | 20 px capsule `fill.2`: 14 px source logo + source name `caption2` w600 `label.2`; the local library uses `Books` + "Library" |
| Offline | `CloudSlash` 14 px + "Offline copy" `caption1` warning, used on stale catalogue grids, saved reads and the global offline indicator |
| AI | `Sparkle` 12 px Iris before AI-produced text |
| Live | a 6 px Glacier dot with a 1.6 s pulse ring (narration playing, sync running) |

Badges pop in on `spring.bouncy` from scale 0.4 and update numbers with a vertical roll (old number slides up 8 px and fades, new one rises in) over `spring.tick`.

### 3.21 Sliders, scrubbers and dials

**Slider.** Track 6 px capsule `fill.2`, Iris fill from the start; thumb 28 px white circle (`#F2F4F8`) with `0 2px 8px rgba(0,0,0,0.5)` at rest, which becomes a 34 px `glass.clear` lens while dragged (Apple's transient-glass exception) and magnifies the track under it. Value label above the thumb while dragging (`mono.meta` in a HUD capsule). Steps tick with selection haptic; continuous sliders tick every 10 %. Keyboard: arrows ±1 step, `Page Up/Down` ±10 %, `Home/End`. States: hover thumb grows to 30; focused ring; disabled track `fill.3`, thumb `slate500`; error n/a.

**Reader scrubber.** Specified in §4.14.4: a 44 px glass capsule with a lens that shows the page thumbnail and number while dragging, bookmark ticks on the track, chapter boundary notches (rigid haptic).

**Fill slider (Control-Center style).** 72 × 160 glass-free `slab.3` tile, radius 24, the fill rising from the bottom in `rgba(255,255,255,0.86)` with a glyph (`Sun`) that turns dark when covered; drag anywhere on the tile. Used for reader brightness (including the below-minimum dim range) and the soundscape master volume.

**Speed dial.** A vertical capsule 64 × 220 (`glass.lift`) that opens from the speed button: a tick ruler from 0.5× to 3.0× at 0.05 steps, labelled marks at 0.5 / 1 / 1.5 / 2 / 2.5 / 3; drag up/down to change, selection haptic every 0.05 and a rigid haptic on each labelled mark; touch-and-hold on the button resets to 1×. Under the value, the equivalent words per minute (`caption1` `label.2`). Used for narration speed and auto-scroll speed.

### 3.22 Toggles, checkboxes and radios

**Switch.** 51 × 31 capsule. Off: track `fill.1`, thumb 27 px `#F2F4F8`. On: track Iris, thumb white. While dragged or pressed the thumb becomes a 34 × 27 `glass.clear` capsule (stretched toward travel), then settles. Flip on `spring.tick`; haptic light (on) / selection (off). Focus ring around the track. Disabled: track `fill.3`, thumb `slate500`. Loading (server-backed switches such as 18+ or per-series notify): the thumb shows a 12 px orbit spinner and the track colour waits for the server; on error the thumb springs back and a toast explains.

**Checkbox.** 22 px rounded square (radius 7), 1.5 px `label.3` stroke, checked = Iris fill with an `irisInk` check that draws in over 180 ms (stroke-dashoffset); indeterminate = Iris with a 10 px dash. Used in select modes and download pickers (the select check disc on posters is the same component, circular).

**Radio.** 22 px circle, 1.5 px `label.3` stroke; selected = Iris ring 1.5 px + 10 px Iris dot that scales in on `spring.tick`. In grouped lists, single-choice settings use a trailing `Check` (Iris) instead of radios.

### 3.23 Menus and context menus

**Menu (pull-down).** `glass.lift` (L6), radius 28, 6 px padding, min width 220 (max 320), rows 44 px with radius 22 (concentric), glyph 20 + label `body` + optional trailing value or key hint (`mono.key` `label.3`); separators `line.hair` with 6 px vertical margin; section titles `caption1` w600 `label.3`. Destructive rows in danger. Checkable rows show a leading `Check` in Iris.

- Opens by **blooming out of its trigger**: the trigger's glass stretches and becomes the menu on `spring.morph`; rows materialize at 40 % of the morph with an 18 ms stagger. Closing reverses into the trigger over `dur.dematerialize`.
- Keyboard: `↑/↓` move, `Enter` activates, type-ahead jumps, `Esc` closes, `→` opens a submenu. Submenus bloom to the side on desktop and replace the menu content with a back row on phones.

**Context menu.** Long press (500 ms) on any poster, card, row or chapter: the item **lifts** out of the plane to L6 (scale 1.06 → 1.10 by 800 ms, shadow `0 24px 60px rgba(0,0,0,0.7)`, the plane behind receives `veil.sheet` + 6 px blur), haptic medium, and a menu blooms beside it (below on phones when there is room, otherwise above; to the right on desktop). Right-click opens the same menu at the pointer without the lift. Standard series menu: Open, Continue reading, Follow / Unfollow, Favourite, Add to collection, Recommend to…, Download…, Mark read / unread, Share link (web only: copies the URL), Not interested (AI rails only).

| State | Row |
|---|---|
| default | label `label.1` |
| hover / keyboard-active | `rgba(255,255,255,0.10)` capsule |
| pressed | `rgba(255,255,255,0.16)` + selection haptic |
| focused | same as hover (the active row is the focus) |
| disabled | `label.4`, reason as a second line |
| loading | trailing orbit spinner; the menu stays open until done for actions with an instant result (Follow), or closes and hands off to a toast |
| selected | leading Iris `Check` |
| error | the row shakes and shows a danger second line |

### 3.24 Empty, error and offline states: "the floating object"

A state is one object floating in the space of the plane: a 96 px Duotone Phosphor glyph (or custom glyph) drawn on a 128 px `glass.clear` disc at L5 (the only place a content screen shows glass in its body, because the state replaces content), bobbing ±4 px on a 4 s sine loop, with its own horizon tint (empty: Iris 10 %; error: danger 10 %; offline: warning 10 %). Below it: title `title3` `label.1`, body `callout` `label.2` max 36 ch, and up to two actions (primary tinted only when the action is the plane's main path, otherwise secondary glass). The object sits in the vertical centre of the visible area above the dock. Reduced motion: no bob.

Standard copy (Glass voice: calm and plain):

| Kind | Glyph | Title | Body | Actions |
|---|---|---|---|---|
| Empty (library) | `Books` | "Nothing followed yet" | "Browse a source and follow a series. It will live here." | Browse sources |
| Empty (search idle) | `MagnifyingGlass` | "Search everything" | "Your library, every source, and the dialogue you've scanned." | none |
| No results | `MagnifyingGlassMinus` | "No results for '{q}'" | "Try another spelling, or search a single source." | Clear |
| Error (generic) | `WarningCircle` | "That didn't load" | "{server message}" | Try again · Go back |
| Server unreachable | `PlugsConnected` | "Can't reach your server" | "It may be starting up, or the connection dropped. Your library is safe." | Try again · Open downloads |
| Offline | `CloudSlash` | "You're offline" | "Chapters you downloaded still open." | Open downloads (+ Try again when a retry makes sense) |
| Rate limited | `Hourglass` | "Taking a breather" | "The source asked us to slow down. Retrying in {n} s." | Retry now (disabled until the countdown ends) |
| Database busy | `Hourglass` | "Server is busy" | "Retrying in {n} s." | none (auto-retry) |
| No profile | `UserCircleDashed` | "Pick a profile first" | "Downloads, progress and settings belong to a profile." | Choose profile |

Offline also shows a global indicator: a 28 px HUD capsule "Offline" with `CloudSlash` that docks under the top controls of every plane while the network is gone, and dematerializes 2 s after it returns with a toast "Back online".

### 3.25 The 18+ gate

The gate is **absence**, never a lock: when a profile's gate is closed, mature items are not drawn and no count implies them. The UI therefore has only three gate surfaces:

1. **The switch** in Settings → Content (per profile) and in the profile editor. Both use the same flow (no path skips confirmation).
2. **The confirm (L7 Veil).** Alert titled "Show mature content for {profile}?" with the body "Adult (18+) sources, series, search results and recommendations will appear for this profile. Only continue if you are of legal age where you live. You can turn it off any time." and a **hold-to-confirm** capsule "Hold to confirm I'm 18 or older" in `color.mature` (§3.11), plus "Cancel". Completion plays `unlock`, dismisses the veil and toasts "Mature content is on for {profile}".
3. **The badge** "18+" on mature sources and series when they are shown (§3.20), and the "18+" filter chip on Sources.

Turning the gate off applies immediately with a toast "Mature content hidden for {profile}" and every gated view refetches (skeletons, no flash of mature items). States: loading (switch spinner while `PUT /settings` runs), error (switch reverts, toast "Couldn't change this setting"), no profile (the switch is disabled with the helper "Choose a profile to change this").

### 3.26 Avatars: profile orbs

A profile avatar is a glass sphere: a circle filled with a two-stop radial gradient (lighter stop at 30 %/25 %, darker at 100 %), a white Phosphor Fill glyph at 44 % of the diameter, a specular crescent `rgba(255,255,255,0.35)` at the top-left, and a 0.5 px rim. Sizes 24 / 32 / 44 / 72 / 112 / 144. The mood hue appears as a thin outer ring (2 px at ≥ 72 px) only on the picker and editor.

The twelve presets (the stored `avatar_key` values stay the same; the visuals are new):

| Key | Name | Gradient | Glyph |
|---|---|---|---|
| `violet` | Nebula | `#C9BEFF` → `#5B3FD9` | `Sparkle` |
| `cyan` | Tide | `#BDEBFF` → `#2A8BD8` | `Waves` |
| `rose` | Petal | `#FFC7E6` → `#D93F8A` | `Flower` |
| `amber` | Lantern | `#FFE0A8` → `#E08A2A` | `Lamp` |
| `emerald` | Moss | `#B8F5D6` → `#1F9E6B` | `Leaf` |
| `ember` | Flare | `#FFD0A0` → `#E0452A` | `Fire` |
| `blade` | Steel | `#E3E8F0` → `#5A6477` | `Sword` |
| `phantom` | Veil | `#D6D3FF` → `#3A3470` | `Ghost` |
| `arcane` | Rune | `#E6C9FF` → `#6E3FD0` | `MagicWand` |
| `lunar` | Moonrise | `#C6DBFF` → `#2F4FB0` | `MoonStars` |
| `star` | Nova | `#FFF0B8` → `#E0A21F` | `Star` |
| `reader` | Folio | `#C4F2EB` → `#1E8C85` | `BookOpen` |

Any unknown key renders Nebula. States: hover (desktop) lifts 2 px and the specular follows the pointer; pressed scale 0.96; focused ring; selected (picker, editor) Iris `select.ring`; loading a 1 px orbit on the rim.

### 3.27 Tooltips and keycaps

**Tooltip.** `glass.float` compact capsule 28 px, `footnote` `label.1`, 8 px padding, max width 280; appears after 600 ms hover (150 ms when another tooltip was shown in the last 800 ms), below the target (above if no room), 8 px offset; materializes on `spring.tick`. Includes the key hint as keycaps. Never on touch (long press shows the label in a HUD instead where the button has no text).

**Keycap.** `mono.key` in a 20 px tall rounded rectangle (radius 6), `fill.2`, 1 px `line.strong` bottom border (a 1 px "depth" edge), min width 20; platform glyphs ⌘ ⌥ ⇧ ⌃ on macOS, words ("Ctrl", "Alt", "Shift") elsewhere.

### 3.28 Command palette (web, all widths with a keyboard)

Opened by `⌘K`/`Ctrl K` anywhere, by clicking the sidebar search capsule (it morphs into the palette), or by `/` on screens without their own search. A Lift panel (`glass.lift`, radius 28) 640 px wide, top at 14 vh, max height 64 vh, with `veil.sheet` behind; on phones with a keyboard it is a large sheet.

- Field 56 px (`title3` input, leading `MagnifyingGlass`, trailing `Esc` keycap).
- Groups in rank order: **Continue** (the three most recent reads, with covers), **Library** (library search, debounced 220 ms), **Sources**, **Go to** (every plane with its `g` chord shown), **Actions** (Check for updates, New collection, Toggle mode, Toggle sidebar, Sign out, Switch profile…), **Skin** ("Switch to Cinematic", which opens the restart confirm).
- Rows 48 px: 32 px leading visual (cover, source logo, glyph), title with matched characters in `label.1` w700 (others `label.2`), subtitle `caption1`, trailing `CornerDownLeft` on the active row. Max 40 results.
- `↑/↓` move (wrap), `Home/End`, `Enter` runs, `⌘Enter` opens in a new pane (on desktop the result opens as a pushed pane instead of replacing), `Esc` or `⌘K` closes. Live region announces "N results".
- States: idle (Continue + Go to), loading (orbit in the field), empty ("Nothing matches '{q}'" + "Search every source for '{q}'"), offline (Library and Sources groups show only cached results with an "Offline" badge).

### 3.29 Download control (per chapter)

A 32 px visual / 44 px hit control on chapter rows, the reader chrome and series pages. It is one component with seven states:

| State | Visual | Action |
|---|---|---|
| Not downloaded | `ArrowCircleDown` 22 px `label.2` | tap: queue; long press: menu (Download this, Download next 10, Download all unread) |
| Queued | `ClockCountdown` 20 px `label.2` inside a dashed 24 px ring | tap: remove from queue |
| Downloading | 24 px ring filling Iris (pages done / total), centre `Stop` square on hover or focus | tap: cancel |
| Saved | `CheckCircle` Fill 22 px success | long press: Remove download (Undo toast) |
| Incomplete | `WarningCircle` 20 px warning | tap: resume |
| Stale (pages changed) | `ArrowClockwise` 20 px warning | tap: save again |
| Failed | `XCircle` 20 px danger | tap: retry; tooltip / long-press label carries the error |
| Paused (device full, cap, backgrounded, by user) | `PauseCircle` 20 px warning | tap: opens Downloads with the pause reason |

Transitions between states cross-fade glyphs over 150 ms with a `spring.tick` scale pop; the finished state plays success haptic only when the user is on the same plane.

### 3.30 Banners and inline notices

A notice is a `slab.1` card (radius 20, 12 × 16 padding) with a leading semantic glyph and a 3 px left bar in the semantic colour, title `subhead` w600, body `footnote` `label.2`, optional trailing plain action. Used for: stale catalogue ("Showing a saved copy from 2 h ago. Refresh"), restore pending, source unavailable, AI unavailable, pinned-sources load failure, update-checker overdue, "Downloads only run while the app is open". Dismissible notices have a trailing `X` (32 px); dismissal collapses the notice on `spring.detent`.

The **app-update banner** (Android APK channel and the web service-worker update) is a Float capsule (L5) above the dock: `ArrowCircleUp` + "A new version is ready" + "Update" (plain Iris); on desktop it sits bottom-centre.

### 3.31 Strata edges, depth indicator and stack overview (signature navigation)

**Strata edges (phone).** The visible top bands of deck planes (§2.2.2), each with its ambient-coloured rim. They are one tap target together (the full width, from the status bar to the front plane's top, min 44 px): tap pops one level; long press opens the stack overview. VoiceOver/TalkBack label: "Back to {previous title}. {n} levels deep. Double-tap and hold for all levels."

**Depth indicator (reader and full-height sheets, where the edges are hidden).** The back circle shows the `strata` glyph with 1–4 lit bars (the current depth) instead of `CaretLeft` on long-press affordance; the bars use the ambient colours of the deck planes.

**Stack overview.** Opened by long press on Back or the strata edges, a two-finger pinch-in on a plane (phone), `⌘\` / `Ctrl \` or right-click on Back (desktop).

- The current bay's planes (up to 8; older ones compress into a "+N earlier" card) fan out in 3D on `spring.surface`: each plane `rotateX(14°)` around its bottom edge, scaled to 0.62 (phone) / 0.44 (desktop), spaced vertically by 28 % of their scaled height, deepest at the top. Everything else takes `veil.focus`. Haptic `fan`.
- Each card shows its live content snapshot, its title under it (`subhead` w600) and its depth number (`mono.meta`).
- Tap a card: it comes forward to the front on `spring.lift`, and every plane that was above it drops away front-to-back (40 ms stagger). Haptic medium.
- Swipe a card sideways (phone) or press `Delete` on it (desktop): removes that plane and every plane above it, same animation.
- `↑/↓` move between cards, `Enter` chooses, `Esc` closes. Scroll when more than 4 cards.
- Reduce Motion: a flat list of cards (no rotation), 200 ms fade.

### 3.32 Scroll edges and scrollbars

One soft edge per plane edge that has floating controls: top (`scrim.edgeTop` + `blur.edge`) under the top controls, bottom (`scrim.edgeBottom`) behind the dock. Sticky section headers use the **hard** edge: `rgba(0,0,0,0.92)` + `line.hair`. Edges are not decorative and never darken content that is not under a control.

Scrollbars: overlay style only. Web: a 6 px capsule thumb `rgba(255,255,255,0.28)` that appears while scrolling and fades 800 ms after, widening to 10 px on hover. Flutter: `RawScrollbar` with the same values; in long lists (chapters, contents) the thumb becomes a draggable 44 px handle showing the chapter number in a HUD capsule while dragged.

### 3.33 Pull to refresh (phone)

Pulling a plane's content down stretches the top of the plane (rubber band `d × (1 − 1/(x × 0.55/d + 1))`); a 32 px orbit glyph descends from under the top controls with its dot travelling as the pull deepens; at 72 px the orbit snaps into a closed ring (haptic rigid 0.5, "armed"); release starts the orbit spinning, and the plane settles back to 56 px until the refresh finishes, then springs to 0 on `spring.detent` with a selection haptic. Desktop: a Refresh action in the plane's cluster and `⌘R` is left to the browser; the plane-level refresh is `r` where the plane has one.

### 3.34 Mode switch (Manga | Novels)

Appears only when the server has novels enabled. A segmented control (§3.6) with glyph + label: `strip` "Manga" / `BookOpenText` "Novels", 36 px. Placements: Home and Library top clusters (phone, as a 2-glyph compact capsule, labels on long press), the sidebar (desktop, full width), and the You hub. Switching re-filters every list; the change animates as a **depth swap**: current plane content recedes one step (scale 0.97, brightness 0.6, 150 ms) and the re-filtered content rises back (`spring.detent`), so the mode feels like switching layers of the same place. Haptic selection. Persisted per profile.

### 3.35 Image viewer

Tapping the header cover on a series plane opens it as a lightbox at L6: the poster flies to fit the screen on `spring.smooth`, the plane takes `veil.focus`, pinch-zoom 1–4×, double-tap 2×, drag down to dismiss (the image shrinks back to its origin as it follows the finger; release past 120 px or 800 px/s dismisses). Close circle top-left. Desktop: click outside or `Esc`.

---
## 4. Per-screen specs

Every screen below is a Glass implementation in `frontend/src/skins/glass/screens/*` and `mobile/lib/skins/glass/screens/*`. Each spec gives the layout per platform, the hierarchy, the signature moment, transitions, gestures, all states and the web keys. "Phone" covers the iOS app, the Android app and mobile web (< 768 px); platform deltas follow each spec.

### 4.0 Shell, navigation model and routes

#### 4.0.1 Frames

| Frame | Where | What is drawn |
|---|---|---|
| **Bare** | Setup, splash, login, register | Abyss + horizon (brand hues Glacier/Iris at the lowest opacity) + one centred Lift panel. No dock, no sidebar |
| **Picker** | Profile picker, onboarding | Abyss + a live horizon made of every profile's mood; no chrome |
| **Bay (phone)** | Every root and pushed plane | Horizon, deck, front plane, top controls, dock + orb + accessory. The dock stays visible on every plane of a bay; it hides only in rooms, at the full-height sheet detent and while the keyboard is up |
| **Pane (desktop)** | Every root and pushed plane | Horizon, sidebar pane, spines, front pane |
| **Room** | Manga reader, novel reader, listen stage, guided view | Reader canvas only, three Float controls, no dock, no sidebar |

The dock stays visible on pushed planes because in Strata the bay is still "where you are"; the strata edges above tell you how deep.

#### 4.0.2 Information architecture

**Bays (phone dock, the first four sidebar rows):**

1. **Home**: the discovery stage: Continue, AI rails, new episodes, Circle presence, spotlight.
2. **Library**: everything this profile follows (shelf, browse, filters, bulk actions), with Collections, History, Bookmarks and On this device (Downloads) as shelves reachable from its header.
3. **Sources**: installed connectors, pins, catalogues, and the series planes opened from them.
4. **Updates**: new chapters, the checker, and the Circle's activity for things you follow.

**Search** is the orb (phone) or the sidebar search + palette (desktop): a plane that rises over whichever bay is active.

**You** is the profile orb at the top-left of every bay root (phone) and the footer row (desktop): a sheet that launches the secondary destinations (Stats, Wrapped, Circle, Collections, History, Bookmarks, Downloads, Dialogue search, For you, Settings, System status, What's new, About) and the profile switcher.

**Planes** push onto the active bay's stack. Opening a series from Home stays in the Home bay; the same series opened from Sources stacks in the Sources bay. Each bay keeps its stack when you switch bays.

**Rooms** (readers) are entered from any plane and sit outside the bays; leaving a room returns to the exact plane you dove from.

#### 4.0.3 Glass screen ids and routes

The route paths are the shared `design/contract.json` paths (both skins register the same paths). Glass adds the screen ids marked new; aliases keep existing deep links resolving.

| Screen id | Path | Frame | Section |
|---|---|---|---|
| `setup` | `/setup` (mobile only) | Bare | 4.1 |
| `splash` | `/splash` (mobile), server-rendered first paint (web) | Bare | 4.2 |
| `login` | `/login` | Bare | 4.3 |
| `register` | `/register` | Bare | 4.4 |
| `profiles` | `/profiles` | Picker | 4.5 |
| `profileNew` / `profileEdit` / `profilesManage` | `/profiles/new`, `/profiles/:id/edit`, `/profiles/manage` | sheet over the picker, or plane from You | 4.6 |
| `onboarding` (new) | `/welcome` | Picker | 4.7 |
| `home` (new root) | `/` and `/home` | Bay: Home | 4.8 |
| `search` | `/search?q=&scope=` | plane over the active bay | 4.9 |
| `sources` | `/sources` | Bay: Sources | 4.10 |
| `sourceCatalogue` | `/sources/:sourceId?genre=&mode=&q=` | plane | 4.11 |
| `series` | `/sources/:sourceId/series/:seriesId` (canonical) and `/library/:followedId` (resolves to the canonical series, same screen) | plane | 4.12 |
| `book` | the `series` path when the source is a novel source | plane | 4.13 |
| `readerManga` | `/read/:sourceId/:seriesKey/:chapterKey?page=&at=&all=` (aliases: `/reader/...`, `/read-all/...`, `/library/read/...`, `/sources/.../chapters/.../read`) | Room | 4.14 |
| `readerLanding` | `/read` | plane | 4.14.10 |
| `readerNovel` | `/novels/:sourceId/:seriesKey/:chapterKey?page=&para=&at=` (alias `/novels/read/...`) | Room | 4.15 |
| `listen` (new) | `?listen=1` on the novel route (a room layer) | Room | 4.16 |
| `library` | `/library?q=&sort=&status=&fav=&density=` (alias `/library/browse` → the same screen) | Bay: Library | 4.17 |
| `collections` / `collection` | `/library/collections`, `/library/collections/:id` (aliases `/collections...`) | plane | 4.18 |
| `history` | `/library/history` | plane | 4.19 |
| `bookmarks` | `/library/bookmarks` | plane | 4.20 |
| `updates` | `/updates` | Bay: Updates | 4.21 |
| `downloads` | `/downloads?tab=chapters|storage` (alias `/settings/storage` → `tab=storage`) | plane | 4.22 |
| `ocr` | `/ocr?q=` (alias `/ocr/search`) | plane | 4.23 |
| `you` (new) | `/you` (phone: the You sheet at large detent; desktop: redirect to `/settings`) | sheet | 4.24 |
| `settings` | `/settings/:section?` | plane | 4.25 |
| `adminStatus` | `/admin/status` | plane | 4.26 |
| `forYou` (new) | `/for-you` (alias `/library/recommendations`) | plane | 5.1 |
| `stats` | `/stats?range=` (alias `/library/statistics`) | plane | 5.2 |
| `wrapped` (new) | `/stats/wrapped/:year` | Room | 5.2 |
| `circle` (new) | `/circle?tab=` | plane | 5.3 |
| `friend` (new) | `/circle/:accountId/:profileId` | plane | 5.3 |
| `notFound`, `routeError`, `rootError`, `offlineFallback` | any | per section | 4.27 |

#### 4.0.4 Transitions shared by every screen

| Navigation | Animation (§2.9.4) | Haptic | Sound |
|---|---|---|---|
| Push a plane | rise + deck recede on `spring.lift` | `rise` by depth | `push-d` |
| Pop (back button, strata tap, `Esc`, browser back on desktop) | drop + deck forward on `spring.drop` | soft 0.5 | `pop` |
| Pop by drag (phone): drag the plane's top area or anywhere with a vertical-down fling when scrolled to the top; also the edge swipe | the plane follows the finger 1:1 (translateY and the deck interpolates); release by projection | rigid on arming, soft on commit | `pop` |
| Pop to root | sequential drops, 40 ms apart | selection per plane | `root` |
| Switch bay | 24 px lateral pan + fade on `spring.tab` | selection | none |
| Dive into a room / surface | §2.9.4 dive | `dive` / soft | `dive` / `pop` |
| Sheet | morph from trigger or rise | selection on detents | `sheet-up` / `sheet-down` |
| Replace (tab-internal, e.g. Library shelf ↔ all) | cross-fade 200 ms + content re-assembly | none | none |

**Back per platform.**

- **iOS app:** full-width interactive swipe from the left edge (`swipeable_page_route` 0.4.8 on each plane route): the plane slides right while also dropping 6 % in scale, and the deck comes forward with the finger. Plus the vertical drag-to-drop on the plane's top 120 px. Both end in the same pop.
- **Android app:** predictive back (`android:enableOnBackInvokedCallback="true"`, `PredictiveBackPageTransitionsBuilder` wrapped by the Strata route): during the back gesture the front plane shrinks toward 0.90 and drops 8 % with the gesture progress while the deck comes forward; committing completes on `spring.drop`. The system back from a bay root with nothing pushed leaves the app.
- **Mobile web:** browser swipe-back navigates without an app animation (the browser draws its own); the in-app back circle and drag-to-drop animate. Every sheet and overlay pushes a history entry so browser back closes it.
- **Desktop web:** browser back/forward animate like the in-app back (panes), `⌘[`/`Alt ←` pop, `⌘]`/`Alt →` forward, `Esc` pops the front pane when no overlay is open.

#### 4.0.5 Global keys (web; the same map is registered with Flutter `Shortcuts` for hardware keyboards)

| Keys | Action |
|---|---|
| `⌘K` / `Ctrl K` | Command palette |
| `/` | Focus the plane's search field, or open the palette |
| `?` | Shortcuts sheet (lists only what works on the current plane) |
| `⌘B` / `Ctrl B` | Collapse / expand the sidebar |
| `g h` · `g l` · `g s` · `g u` · `g d` · `g c` · `g t` · `g f` · `g y` · `g ,` | Go to Home · Library · Sources · Updates · Downloads · Circle · Stats · For you · You (profile switcher) · Settings |
| `1` `2` `3` `4` | Switch bay (when focus is not in a field) |
| `⌘[` / `Alt ←`, `⌘]` / `Alt →` | Pop / forward one plane |
| `⌘\` / `Ctrl \` | Stack overview |
| `Esc` | Close the top overlay, else pop the front plane |
| `⌘Enter` / `Ctrl Enter` | Continue reading the most recent series |
| `m` | Toggle Manga / Novels |
| Grids and lists | `←↑→↓` and `h j k l` move, `Enter`/`o` open, `.` or `Shift F10` item menu, `x` select, `Shift x` range, `Esc` clear selection |
| Rails | `←`/`→` within, `↑`/`↓` between rails keeping the column |
| Plane tabs | `[` / `]` |

A Settings → Keyboard switch "Single-key shortcuts" (default on) disables every binding without a modifier (WCAG 2.1.4). Bay keys (`1`–`4`) and `g` chords are inactive inside rooms, where the reader keys of §4.14.8 and §4.15.8 take over.

#### 4.0.6 Rules applied to every screen

- **Content runs under the chrome.** Every plane scrolls edge to edge under the top controls and the dock with content insets, so the glass always has something to bend.
- **Focus after navigation** moves to the plane's large title (`tabindex=-1` / `Semantics(focused)`); focus after an overlay closes returns to its trigger.
- **Loading always has shape:** a plane never shows a lone spinner; it assembles its skeleton at the right depth first.
- **The 18+ gate is absence** (§3.25): no screen reserves space for hidden items.
- **Profile switch** reloads every plane's data behind a profile-arrival transition (§4.5); no stale content from the previous profile is ever painted.
- **Server-busy and rate-limit** states (§3.24) are available to every data plane.
- **Offline**: planes render what is on the device, badge it, and show the global offline HUD (§3.24).
- **Platform rule for every screen that lists no deltas.** The phone layout is identical on the iOS app, the Android app and mobile web; the differences are only the back mechanics (§4.0.4), haptics (none on the web except the four Android-web vibrations), gyro parallax (apps only, or mobile web after permission), and system bars (iOS status bar hidden in rooms, Android immersive-sticky in rooms). Tablet uses the phone layout with 24 px margins, grids widened to 4–6 columns and two-column lists at ≥ 900 px. Desktop renders the plane as a front pane (max 1120 px, 32 px inner margins) with the same content order; lists become two columns at ≥ 1280 px and poster grids use 6–8 columns.

---

### 4.1 Setup (server address; iOS and Android apps only)

**Purpose.** First run: connect to the ManhwaManiacs server before anything else. Forced by the router until a server has been validated.

**Layout (phone).** Bare frame. The horizon shows the brand hues (Glacier at 0.12, Iris at 0.10). Centred vertically, 420 px max width:

1. The MM column mark (§7.1) 64 px, glass rendition, 32 px above the heading.
2. `largeTitle` "Connect to your server" with the letter reveal (§6.1).
3. `callout` `label.2`: "ManhwaManiacs reads from a server you or a friend runs. Enter its address."
4. A Lift panel (`glass.lift`, radius 28, 20 px padding) holding the field "Server address" (`Globe` glyph, URL keyboard, placeholder = the default URL, `https://` enforced in release builds) and, under it, a status line.
5. Primary capsule L "Connect" (the plane's one tint), full width inside the panel.

**Tablet.** Same, the panel is 480 px.

**Hierarchy.** Mark → title → explanation → field → Connect.

**Signature moment.** On success the panel's glass **condenses into the MM column mark** (the panel shrinks and rounds into the mark's capsule on `spring.morph`), which then plays the logo reveal (§7.4) before login rises. The server becomes part of the brand moment.

**Transitions.** In: logo reveal hand-off (§7.4). Out: the mark hand-off into the login panel.

**Gestures.** Keyboard `Go` submits. Long press the mark: shows the app version HUD.

**States.**

| State | UI |
|---|---|
| Idle | as above; Connect disabled until the field is non-empty |
| Validating | field trailing orbit spinner, Connect shows "Connecting", field disabled |
| Invalid URL | field error "That doesn't look like an address. Include https://" |
| Unreachable | field error "Couldn't reach {host}. Check the address and that the server is running." + plain "Try again" |
| Not a ManhwaManiacs server | field error "{host} answered, but it isn't a ManhwaManiacs server." |
| Success | the condense moment |

**Platform deltas.** Android: the field sits above the IME with `adjustResize`; iOS: the panel slides up with the keyboard on `spring.detent`. Web never shows this screen (the server is the origin).

### 4.2 Boot: splash, session check, first paint

**Purpose.** Cover the token probe on cold start and paint the skin before anything else.

**Layout.** Native splash (neutral MM column in `#F3EEE6` on `#000`, §7.3) → the first Flutter frame / server-rendered HTML redraws the neutral mark at the identical position → the Glass logo reveal "Strata assembly" (§7.4, 1,200 ms cold, 400 ms warm) → the session resolves → hand-off to the destination (profile picker, Home, login).

- **Session still resolving after the reveal** (slow server): the mark stays centred and an orbit circles it 24 px outside its bounds; after 3 s a `footnote` `label.3` line appears: "Waking the server". After 10 s: "Still waiting on {host}" + plain buttons "Keep waiting" and "Use offline" (offline starts the app on the cached session, §4.0.6).
- **Server unreachable with no cached session:** the mark dims to 0.5 and the Lift panel from Setup appears with "Can't reach {host}" and "Try again" / "Change server" (phone) or "Try again" (web).

**Hand-off.** The mark's glass becomes the destination's first Float element: the picker's first orb, or the dock (Home), or the login panel (morph on `spring.morph`).

**Web.** The root layout server-renders an inline SVG of the neutral mark on `#000` with `data-skin="glass"`; the reveal plays after hydration only once per browser session (`sessionStorage['mm.skin.splash']`); later navigations skip it. The installed iOS PWA uses black `apple-touch-startup-image`s.

**Reduced motion.** 200 ms cross-fade from the mark to the destination.

### 4.3 Login

**Purpose.** Sign in; doubles as the "first account" prompt when the server has none.

**Layout (phone and desktop).** Bare frame; a single Lift panel 400 px wide (full width minus 32 on phone), radius 28, 24 px padding, vertically centred (on phones it anchors 12 % from the top so the keyboard never covers the button).

1. MM column mark 44 px + "ManhwaManiacs" single-line wordmark 20 px.
2. `title1` "Welcome back" (letter reveal) + `callout` `label.2` "Sign in to your library."
3. Server row (phone only): `caption1` `label.3` "Server: {host}" with a `Copy` glyph; tap copies and toasts "Copied".
4. Field "Username" (`User`), field "Password" (`LockSimple`, reveal toggle).
5. Switch row "Keep me signed in" (on by default; 90-day session).
6. Error notice slot (danger banner inside the panel).
7. Primary capsule L "Sign in" (disabled until both fields are filled).
8. Footer plain button "Create an account" (only when registration is open).

**Bootstrap variant** (no accounts exist): the panel shows `title1` "Set up ManhwaManiacs", body "This server has no accounts yet. The first account you create becomes the administrator.", and a primary "Create the first account" that morphs the panel into the register form.

**Signature moment.** A wrong password makes the whole panel **recoil in depth** (scale 0.97 and back on `spring.bouncy`, 2 px blur pulse) instead of a sideways shake; the error banner slides out from under the fields.

**Transitions.** In: from the splash hand-off, or the register panel morphing back. Out on success: the panel dematerializes into the MM mark, which flies to where the picker's orbs will appear, and the picker assembles around it (§4.5).

**States.**

| State | UI |
|---|---|
| Resolving bootstrap | panel skeleton (title bar + two field blocks) |
| Server unreachable | danger banner "Couldn't reach the server" + "Try again"; fields disabled |
| Pending | button "Signing in" + orbit; fields disabled |
| Invalid credentials | recoil + banner "That username and password don't match." |
| Account disabled | banner "This account is disabled. Ask the server owner." |
| Rate limited | banner "Too many attempts. Try again in {n} s." with a live countdown |
| Registration closed | footer link hidden |

**Keys (web).** `Enter` submits from either field; `Alt V` toggles password visibility.

**Platform deltas.** iOS: `autofillHints: username / password` so the keychain offers credentials. Android: autofill hints for Credential Manager. Web: `autocomplete="username"` / `"current-password"`.

### 4.4 Register

**Purpose.** Create an account; the bootstrap variant claims the server as administrator.

**Layout.** The login panel morphs taller (height interpolates on `spring.morph`) into:

1. `title1` by variant: "Create your account" (open), "Create the administrator account" (bootstrap), "Registration is closed" (closed).
2. Fields: Username; Password (helper "At least 8 characters"); Confirm password (live mismatch error); Invite code (`Key`, only when the server requires one; placeholder "From whoever invited you"); Display name (optional); Email (optional).
3. Switch "Keep me signed in".
4. Error banner slot.
5. Primary L "Create account" / "Create administrator".
6. Footer "I already have an account" (morphs back to login).

**Closed variant.** Only the title, "This server isn't accepting new accounts. Ask its owner to create one for you.", and a secondary "Back to sign in".

**Signature moment.** The panel grows downward field by field: each field materializes 30 ms after the previous as the panel height springs, so the form assembles in depth rather than appearing at once.

**States.** Resolving (skeleton), unreachable (banner + retry), pending ("Creating account"), field errors inline (`invalid_username`, `weak_password`, `username_taken`, `invite_code_required`, `invite_code_invalid`, `registration_disabled`, `bootstrap_window_expired`, `bootstrap_already_claimed`, `rate_limited`), each mapped to a plain sentence under the relevant field or in the banner.

**Keys (web).** `Enter` advances to the next field and submits from the last.

**Platform deltas.** Android back and the iOS swipe morph the panel back to login instead of leaving the app.

### 4.5 Profile picker ("Who's reading?")

**Purpose.** Choose the reading profile after sign-in (once per app session on phones), from the You orb, or when a profile error sends the user back.

**Layout (phone).** Picker frame. The horizon is a slow blend of every profile's mood hue (each profile contributes one blob, positioned where its orb sits). Top: `largeTitle` "Who's reading?" (letter reveal) at `safeTop + 56`, centred; `callout` `label.2` "Your progress, library and settings follow the profile you pick." Below it, the **orbit field**: profile orbs (112 px) arranged on a gently tilted ellipse (rx 34 % width, ry 12 % height, tilted 8°) at different depths. Orbs nearer the bottom of the ellipse are nearer the viewer (scale 1.0, brightness 1); orbs at the back scale 0.82 and dim to 0.7. Each orb carries its name under it (`headline`) and its mood as a 2 px ring. An "Add profile" orb (dashed 1.5 px `label.3` ring, `Plus` glyph) joins the orbit while fewer than 5 profiles exist. A plain button "Edit profiles" sits at the bottom centre above the safe area.

The orbit slowly rotates (one revolution per 90 s, pausing while touched). Dragging horizontally spins it with momentum (`spring.smooth` deceleration); the orb that reaches the front snaps there with a selection haptic.

**Layout (desktop).** The orbit becomes a horizontal arc across the centre (orbs 144 px, spaced 56 px), the nearest orb is the hovered or focused one; the arc does not rotate on its own. `←/→` move focus around the arc (the focused orb comes forward), `Enter` picks, `e` edits the focused profile, `n` adds.

**Hierarchy.** Title → the front orb → the other orbs → Edit.

**Signature moment: arrival.** Tapping an orb: it comes forward to the centre and grows to 160 px on `spring.surface` while the other orbs recede into the horizon (scale 0.6, blur 12, fade), the title dematerializes, and the chosen profile's mood horizon floods the whole space. The orb then **becomes the You orb**: it shrinks and flies to the top-left of Home while Home's planes assemble back-to-front around it. Haptic `arrive`. Total 900 ms; tapping during it skips to the end. If this profile's saved skin is Cinematic, the skin-restart hand-off (§4.25.1) runs inside this same transition instead of arriving in Home.

**Manage mode.** "Edit profiles" (or long press an orb) tilts every orb 6° toward the viewer and overlays a `PencilSimple` glass badge (L5, 32 px) on each; tapping an orb opens the profile editor sheet (§4.6). "Done" returns.

**States.**

| State | UI |
|---|---|
| Loading | 3 skeleton orbs on the ellipse with the depth shimmer |
| Empty (no profiles) | a single "Add profile" orb at the front, title "Create your first profile", body "Profiles keep progress, follows and settings separate for everyone who shares this account." |
| Unreachable, no cached profile | the floating-object state "Profiles are unavailable" + "Try again" |
| Unreachable, cached last profile | the last profile's orb at the front with "Continue as {name}" (primary) and "Try again" (secondary) |
| 5 profiles | no Add orb; the editor explains the limit |

**Transitions.** In: from login (the MM mark arrives as the first orb), from the You sheet (the You orb flies back into the orbit and the current Home recedes to deck 3 behind the picker), from a profile error (the stack recedes with a toast "That profile isn't available any more").

**Gestures.** Tap = pick; long press = manage; horizontal drag = spin; pinch-out on an orb = pick (flagship delight, same as tap).

**Keys (web).** `←/→`, `Enter`, `e`, `n`, `Esc` (from the You orb path only: return to where you were).

**Platform deltas.** Android: the gyroscope tilts the ellipse ±4° (parallax L3 factor). Mobile web: no gyroscope unless permission is granted; the ellipse is static.

### 4.6 Profile editor and Manage profiles

**Purpose.** Create, edit and delete profiles (name, avatar, mood, 18+ switch), and reorder them.

**Profile editor.** A sheet (medium detent, expands to large) morphing out of the orb or the Add orb (phone), a 520 px floating panel (desktop).

1. Header: "New profile" / "Edit profile", "Cancel" and "Save" (Save is the tinted primary in the sticky footer; the header keeps Cancel only).
2. Live orb preview 112 px, centred, with its mood ring; it re-renders as choices change, and the sheet's own horizon (a small field behind the preview) shows the chosen mood.
3. Field "Name" (1–30 characters shown; server accepts up to 255), placeholder "Late-night reads".
4. "Avatar": a 4 × 3 grid of the twelve orbs (56 px) with their names on long press/tooltip; selection `select.ring` and a `spring.tick` pop.
5. "Mood": seven choice chips with a 12 px hue dot (Default, Romantic, Action, Comedy, Horror, Slice of life, Fantasy); helper "Colours the space behind this profile's library. Never the reader."
6. Switch row "Mature content (18+)" → the 18+ confirm (§3.25) when turned on.
7. Destructive row (edit only): "Delete profile" in danger → Veil confirm "Delete {name}? Their library, progress, bookmarks and collections are removed. This can't be undone." with a danger "Delete".
8. Error banner slot.

**Manage profiles (plane).** Reachable from the You sheet ("Profiles") and Settings → Profiles. `largeTitle` "Profiles", a grouped list: each row = 44 px orb, name, mood + "18+ on" meta, "Active" status chip on the current profile, trailing `DotsThree` menu (Use, Edit, Delete). Reorder by long press (writes `sort_order`). Footer primary "Add profile" (disabled at 5 with helper "Profiles are limited to five per account.").

**Signature moment.** Changing the mood chip in the editor re-tints the horizon behind the sheet in real time (600 ms OKLab shift), and on Save the preview orb flies back to its slot in the orbit or the list.

**States.** Loading (skeleton list or preview), not found ("This profile was removed" + Close), saving ("Saving" + orbit), validation ("Give this profile a name."), server errors (`profile_limit_reached`, `invalid_profile_name`, `invalid_mood`) inline.

**Keys (web).** `Enter` saves from the name field, `Esc` cancels, arrow keys move through the avatar grid.

### 4.7 Onboarding (a new profile's first visit)

**Purpose.** Give a brand-new profile something to start from: mode, taste seeds and a first follow, in under a minute. Shown once per profile when it has no follows and no reading history; skippable at every step.

**Layout.** Picker frame, a horizontal pager of four cards in depth: the current card at the front (Lift panel, 88 % width, radius 36), the next card visible behind it (deck 1 geometry) so the path is visible. A 4-dot page indicator under the cards; "Skip" plain button top-right.

1. **Welcome.** `display` headline typed with the 50 ms typing reveal (§6.2): "Hi, {profile}." Body: "Three quick choices and your space is ready." Primary "Start".
2. **What do you read?** Two big choice cards (Manga & manhwa with the `strip` glyph / Novels with `BookOpenText`), multi-select (only when the server has novels enabled; otherwise this card is omitted). Sets the default mode.
3. **Pick a few you like.** A genre wall: 24 genre chips (the union of the sources' genres, ordered by the server's popularity) plus "Surprise me". At least 3 or skip. These seed the AI home (§5.1) until real history exists.
4. **Follow something.** A rail of 12 world cards seeded by step 3 (only *available* ones), each with a Follow toggle. Primary "Finish" enables after one follow (or "Finish without following").

**Signature moment.** Each "Next" pushes the front card **back** into the deck while the next card rises from behind it (reversed depth: the path is ahead, not behind), and "Finish" makes all four cards fall together into Home's first rail as posters.

**States.** Loading genres (chip skeletons), world cards loading (rail skeleton), world unavailable ("Recommendations need the internet catalogue, which isn't reachable. You can follow from Sources instead." + "Open Sources"), follow errors (toast).

**Desktop.** The four cards are 560 × 640 Lift panels centred in the window, the next card visible behind and above; the genre wall is a 6-column chip grid; the follow rail shows 6 cards.

**Keys (web).** `→`/`Enter` next, `←` previous, `Esc` skip.

### 4.8 Home (discovery)

**Purpose.** The landing bay: what to read now, what's new, what the AI and the Circle suggest. AI parts are specified in §5.1, Circle parts in §5.3.

**Layout (phone).** Root plane (full-bleed black). Top controls: the You orb (44, with the streak ring) top-left; top-right: the compact mode switch (search lives in the orb, so it is not repeated here). Scroll content:

1. **Greeting headline** at `safeTop + 64`: `display` 40 px, typed at 50 ms per character (§6.2): "Good evening, {profile}" (morning 05–12, afternoon 12–18, evening 18–05, localised to the device time). Under it `subhead` `label.2`: the day's line ("12-day streak · 3 new chapters").
2. **The Stage** (spotlight). A depth-parallax hero: 1.1 × width tall on phones. Layers: L1 horizon from the spotlit series' palette; a blurred, enlarged cover at brightness 0.5 behind (parallax 0.55); the cover itself as a floating poster (220 × 330, radius 20) at L3 with parallax 0.20 and a 4° gyro tilt with a moving specular sheen; on the lower third, clear-glass title block: series title `title1`, meta (`caption1`: "Manhwa · Ongoing · CH 142"), the `why` line ("Because you finished *Omniscient Reader*"), and two buttons: primary "Read" / "Continue" and on-media secondary "Details". `scrim.heroFoot` joins it into the plane. The stage holds up to 5 spotlights; swipe horizontally to move between them: the current poster slides back into depth (scale 0.86, brightness 0.4) while the next rises from the side; 5 small dots under the block. Auto-advance every 9 s while idle and in view (never under Reduce Motion).
3. **Continue** rail of deck cards (§3.7), up to 10, ordered by `last_read_at`.
4. **New episodes**: posters with "N NEW" badges from followed series updated since the last visit.
5. **AI rails** (§5.1.2): "For you", "Because you read {title}" (up to 3), "Almost done", "More like {current}".
6. **From your circle** (§5.3): friend presence orbs row + "Aya is reading" posters + recommendations sent to you.
7. **Your genres**: a chip row from the genre affinity; tapping a chip opens a For you plane filtered to it.
8. **Pinned sources**: a row of 64 px source tiles (logo + name) to jump into catalogues.
9. Footer spacer `layout.contentBottom`.

In Novels mode, rails show books: the Stage uses a book plate (Literata title over the cover), Continue shows "42 % in · 18 min left", and "New episodes" becomes "New chapters".

**Layout (tablet).** Stage 0.6 × width tall with the poster to the left and the title block to the right; rails as on phone with L posters.

**Layout (desktop and wide).** Root pane under the sidebar. The greeting sits top-left of the pane (`display` 64). The Stage is a 16:7 panel (max 1280 × 560) with the poster (240 × 360) floating at left and the title block to its right; pointer parallax replaces the gyro. Rails show 6–9 posters with paging arrows on hover. A right column at wide widths (≥ 1600 px): "Today" card (streak, time read today, next chapter due) and the Circle activity mini-feed.

**Hierarchy.** Greeting → Stage (one tinted button: Read/Continue) → Continue → New → AI → Circle → genres → sources.

**Signature moment.** The **Stage in depth**: as you tilt the phone or move the pointer, the blurred backdrop, the poster and the glass title block move at their own parallax factors, and the specular sheen slides across the poster; pressing "Read" makes the poster itself dive toward you and become the first page of the reader (§8, moment 4).

**Transitions.** In: profile arrival (the You orb lands, then the greeting types, the Stage assembles back-to-front, rails cascade in with the rail stagger). Bay switch: lateral pan. Out: pushing a series from a poster (cover flight) or diving into a reader from Continue.

**Gestures.** Swipe the Stage; long press any poster or card (context menu); pull to refresh (re-fetches every rail); scroll minimizes the dock; long press the Home bay (dock menu).

**States.**

| State | UI |
|---|---|
| Loading (first) | greeting types immediately (it needs only the profile name); Stage skeleton (poster block + 3 text lines) with the depth shimmer; 3 rail skeletons |
| New profile, no history | Stage shows "Start here" spotlights from onboarding seeds or popular series on pinned sources; Continue is omitted; an inline card "Your Home fills in as you read." |
| AI unavailable | AI rails are replaced by non-AI rails ("Popular on your sources", "Recently updated"); one quiet notice under the greeting: "AI picks are off: {reason}" (§5.1.7) |
| Offline | the Stage shows the most recent downloaded series; Continue shows only downloaded chapters with offline badges; other rails are omitted; the offline HUD is shown |
| Error (partial) | failing rails show their inline retry row; the rest renders |
| Error (all) | floating-object error + "Try again" |
| Profile has 18+ off | mature series never appear in any rail (server-side gate) |

**Keys (web).** Global keys; `Enter` on the Stage reads; `←/→` on the focused Stage moves spotlights; `c` continues the first Continue card.

**Platform deltas.** iOS/Android: gyro parallax via `sensors_plus`; mobile web: pointer-free, so parallax only follows scroll (the poster moves at 0.8× scroll speed).

### 4.9 Search

**Purpose.** One place to search the library, every source, and scanned dialogue.

**Layout (phone).** The orb morphs into the bottom field (§3.4); the Search plane rises behind it (depth 1 in the active bay). Top: `largeTitle` "Search" with scope segmented control (All · Library · Sources · Dialogue) under it. The field stays at the bottom, above the keyboard (thumb zone).

- **Idle:** "Recent" input chips (up to 8 per profile, removable), "Trending in your genres" suggestion chips, "Browse by source" row of pinned source tiles, and the floating-object idle state below when the history is empty.
- **Results (All scope):** grouped families in order: **In your library** (a row of M posters), **Sources** (one group per source: header with 24 px logo, name, count badge and "See all" → the source catalogue with the query; body = a horizontal shelf of S posters), **In dialogue** (up to 3 dialogue hit rows linking to the OCR plane with the query). Two-phase progress: after tier 1 returns, a live line under the scope control reads "{n} results · searching {k} more sources" with an orbit; tier 2 groups slide in at the end of the list on `spring.smooth` (they never reorder groups already on screen). Sources with no matches collapse into a single "No matches in {k} sources" disclosure row. Failed sources show a row "{source} didn't answer" + Retry (retry shows 2 skeleton posters in its shelf).
- **Library / Sources / Dialogue scopes** show only that family, as a grid (library, sources) or a list (dialogue).
- A **jump bar** appears on the right edge (phone) when more than 6 source groups exist: source initials stacked vertically; drag to jump between groups with a selection haptic per group.

**Layout (desktop).** Search opens from the palette's "Search every source" row or `g /` as a front pane: field at the top of the pane (56 px), scopes beside it, group shelves as grids of 6–8 per row, the jump list as a sticky left column inside the pane at ≥ 1440 px.

**Hierarchy.** Field → scope → library hits → source groups by result count (pinned sources first) → dialogue.

**Signature moment.** **Results surface from depth**: each source group arrives from behind the plane (scale 0.94 → 1, brightness 0.4 → 1) in the order the sources answer, so slow sources visibly "surface" later instead of the list jumping.

**Transitions.** In: orb morph. Out: dropping the plane returns the field into the orb (reverse morph).

**Gestures.** Pull down on the plane dismisses search (drop); swipe between scopes horizontally; long press results for the context menu.

**States.** Idle, typing (debounce 300 ms; suggestions above the field), searching (skeleton shelves under group headers as they are known), partial (tier 2 running), results, empty ("No results for '{q}'" with "Search dialogue instead" when the query looks like a sentence), offline (only the library family from the device cache + offline badge), error ("Search failed" + Retry), rate-limited (§3.24).

**Keys (web).** `/` focus field, `Enter` search now, `Tab` into results, `[` / `]` previous / next scope, `j`/`k` next/previous source group, `Esc` clears then pops.

**Platform deltas.** iOS: the field is part of the keyboard's accessory area and follows it on `spring.detent`. Android: `imePadding`.

### 4.10 Sources

**Purpose.** Every installed connector, pins, the 18+ filter, and health at a glance.

**Layout (phone).** Bay root. Top controls: You orb; cluster: mode switch. Content: `largeTitle` "Sources" + `subhead` `label.2` "{n} sources · {m} pinned". A search field "Filter sources" (capsule 44 px, on the plane, `slab.3`) with chips under it: All · Pinned ({n}) · 18+ (the 18+ chip only when the profile's gate is open). Then:

1. **Pinned** (a grouped well, reorderable by long press; order is saved) of source row cards.
2. **All sources** (grouped well), alphabetical, with a sticky alphabet index on the right edge (hard scroll edge on the sticky section headers).

A pinned source that this profile cannot see renders at 0.45 opacity with "Not available on this profile" and no link.

**Layout (desktop).** A two-column grid of source cards (logo 48, name, description 2 lines, health dot, pin toggle, "18+" badge) inside the root pane; pinned first with drag-to-reorder (grid reorder, `Alt+arrows` for keyboard).

**Hierarchy.** Title → filter → Pinned → All.

**Signature moment.** **Pinning lifts a row into the Pinned stratum**: the row rises to L6 on the pin tap, travels up into the Pinned well on `spring.smooth` (siblings part to receive it) and settles with a light haptic; unpinning sinks it back to its alphabetical place.

**Transitions.** In: bay switch. Out: push a catalogue (the row's logo flies to the catalogue header).

**Gestures.** Tap row: open. Pin icon: pin/unpin. Swipe row leading: pin; trailing: none. Long press: context menu (Open, Pin, Health details). Pull to refresh (sources + pins).

**States.** Loading (10 row skeletons), none installed ("No sources installed" floating object; for Novels mode "No novel sources installed"), no match ("No sources match '{q}'"), Pinned filter empty ("Nothing pinned. Tap the pin on a source to keep it here."), pins failed to load (notice "Pins couldn't load, so pinning is off until they do." + Retry), pin save failed (row returns to its place with a shake + toast), offline (cached list with offline badge; catalogues of sources show only downloaded series).

**Keys (web).** `/` filter, `↑/↓` rows, `Enter` open, `p` pin/unpin the focused source, `Alt ↑/↓` reorder pinned.

### 4.11 Source catalogue

**Purpose.** Browse or search one source: modes (Popular, Latest), genres, infinite scroll, freshness.

**Layout (phone).** Plane (depth ≥ 1 in the Sources bay, or Home/Search when opened from there). Top controls: back circle; cluster: `ArrowClockwise` (refresh from source) and `FunnelSimple` (genre sheet). Content:

1. Header: 56 px source logo (it flew in from the row), `largeTitle` source name, meta line `subhead` `label.2` "{shown} of {total} series" and the freshness badge ("Updated 12 min ago", or the warning "Saved copy · 3 h" with a tooltip explaining the source is down).
2. Search field "Search {source}" (on the plane).
3. Browse-mode segmented control (only when the source exposes more than one mode and no search is active).
4. Active genre as an input chip ("Genre: Murim ×").
5. Grid of S posters, 3 columns (phone) with titles 2 lines; infinite scroll loads the next page 600 px before the end.
6. Novel sources: a list of book rows instead (plate 52 × 76, Literata title, author, chapter count, status, 2-line blurb).

**Layout (desktop).** Front pane: header row (logo, name, meta, freshness, refresh) → toolbar (search, modes, genre menu button) → grid 5–8 columns.

**Signature moment.** **Opening a source** is a descent: while the first page loads, the logo sits in a glass lens at the centre of the plane and the continue-reading covers of the profile drift past behind it in depth (3 covers at a time, travelling from far to near over 3.5 s each, crossfading); after 3 s the line "This source can take about 10 seconds" appears. When data arrives, the lens flies into the header and the grid assembles in the diagonal wave.

**Gestures.** Pull to refresh (normal refresh; the cluster button forces a refresh from the source). Long press poster: context menu. Swipe between browse modes.

**States.**

| State | UI |
|---|---|
| Opening | the descent moment above + 12 skeleton posters under it |
| Loading more | a row of 3 skeleton posters at the end + orbit |
| Load-more failed | row "Couldn't load more." + Retry (retries only that page) |
| End | `caption1` `label.3` "That's everything {source} lists." |
| Empty | "No series found" (browse) / "No results for '{q}' on {source}" (search) |
| Stale | the warning freshness badge + notice "Showing a saved copy from {time}. {source} isn't answering." |
| Error | floating-object error "Couldn't open {source}" + "Try again" + "Back to sources" |
| Rate limited | §3.24 |
| Offline | only series with downloads, with offline badge; otherwise the offline object |

**Keys (web).** `/` search, `m` next browse mode, `g` genre menu, grid navigation keys, `r` refresh from source.

### 4.12 Series detail (manga, manhwa, manhua)

**Purpose.** The one series page, whichever route opened it: read, continue, read all, follow, favourite, status, notifications, chapters, downloads, collections, recap, similar series, Circle reactions.

**Layout (phone).** Plane. Horizon from the series palette. Top controls: back circle; cluster: `DotsThree` (menu: Add to collection, Recommend to…, Share link, Not interested, Open on source site) and `BellRinging`/`BellSlash` (per-series notifications, when followed).

1. **Header in depth.** The blurred enlarged cover fills the top 380 px at brightness 0.45 (parallax 0.55) and fades into black via `scrim.heroFoot`. The XL poster (200 × 300) floats centred over it at L3 (the landing spot of the cover flight), with a 3° gyro tilt.
2. Title `title1` centred, 3 lines max; author / artist `subhead` `label.2`; meta row `mono.meta`: "CH 1–142 · Ongoing · Manhwa"; genre tags (tap → catalogue filtered by genre).
3. **Action row:** the split Continue primary (L, full width minus 32): "Read" (not started), "Continue · CH 142 p. 12" (in progress), "Up to date" disabled (caught up, with the helper "New chapters show up in Updates."). Under it, three secondary glass capsules M evenly spaced: Follow/Following (`Plus`/`Check`), Read all (`strip`, only with more than 1 chapter), Download (`ArrowCircleDown`, opens the picker).
4. **Status row** (when followed): a reading-status menu button (status chip + `CaretDown`; morphs into a menu of the six statuses) and a favourite toggle (`Star`).
5. **Previously on** card when a recap applies (§5.1.5): a compact glass-free `slab.1` card "Previously on · Tap for a 30-second recap" with the `recap` glyph.
6. **Description** `callout` `label.2`, 4 lines with "More" (expands on `spring.smooth`).
7. **Circle strip** (§5.3): friend orbs of Circle members who follow this series, plus the reaction summary of the latest chapter.
8. **Chapters** section header: "Chapters · 142" `title2`, trailing plain buttons: sort menu (Newest first / Oldest first, remembered per series) and `MagnifyingGlass` (go-to chapter field). Dialogue coverage line when OCR exists: "Dialogue indexed for 34 of 142 chapters" `caption1` `label.3`.
9. **Chapter rows** (§3.17) with download controls; the next unread chapter carries an Iris 6 px dot; an in-progress row shows its bar.
10. **More like this** rail (§5.1.4).
11. Footer spacer.

**Download picker (select mode).** Tapping Download switches the list into select mode: rows get leading checkboxes (saved rows are disabled with their saved glyph), and a **selection accessory** replaces the dock accessory: "{n} selected · {k} saved" + helper chips "Next 10", "All unread", "All" + primary "Download {n}". Running: the accessory shows "Downloading {i} of {n}" with a progress line and "Stop". Summary: a toast with the result ("12 chapters saved", "10 saved, 2 failed · Retry", "Out of room: {free} free · Manage downloads").

**Layout (tablet).** Header becomes two columns: poster left (240 × 360), title and actions right; chapters below full width.

**Layout (desktop).** Front pane (max 1120 px). Left column 320 px sticky: poster (240 × 360), primary Continue, secondary row, status + favourite, facts list (Source, Status, Chapters, Last update, Following since), Circle strip. Right column: title block, description, Previously-on card, chapter list (virtualised; rows 56 px) and More like this. On wide screens the library or catalogue it came from stays visible as the 420 px peek to the left.

**Hierarchy.** Poster → title → Continue (the one tint) → follow/read all/download → status → recap → about → chapters → similar.

**Signature moment.** **The cover flight into depth**: the tapped poster leaves its rail, grows and flies to the header while the rest of the rail recedes with the deck; the blurred backdrop blooms out behind it from the poster's position (radius grows from the poster rect to full width on `spring.smooth`), so the series "opens up" around its cover.

**Transitions.** In: cover flight (from any poster), or a plain rise when opened by link (notification, palette). Out: drop (the header poster flies back to its origin poster if that rail is still in the deck); Continue dives into the reader from the Continue button (the poster becomes the first page).

**Gestures.** Pull down past the top: drops the plane (dismiss). Long press a chapter row: context menu (Read, Mark read/unread, Mark all previous read, Download, Remove download, Bookmark first page, React). Swipe chapter rows: leading "Mark read", trailing "Download" / "Remove". Pinch the poster: image viewer.

**States.**

| State | UI |
|---|---|
| Loading | header skeleton (poster block + 3 lines + button row), 8 chapter-row skeletons; if the cover is known from the flight it is shown immediately |
| Chapters loading separately | header live, chapter skeleton rows |
| Chapters unavailable | notice "Chapters didn't come through. {source} lists {n} but returned none just now." + Retry |
| No chapters | "No chapters yet. {source} hasn't published any." |
| Caught up | Continue disabled "Up to date" |
| Offline | cached header + downloaded chapters only, each marked; notice "Showing what's on this device." |
| Error | floating-object "Couldn't load this series" + "Try again" + "Back" |
| Follow pending / error | Follow capsule loading; error toast "Couldn't follow. Try again." |
| Following | toast "Following. New chapters will show up in Updates." with "Undo" |
| Source dead (health) | notice (warning) "{source} isn't working right now. Your progress is safe." |

**Keys (web).** `Enter` / `c` continue, `r` read from the start, `a` read all, `f` follow, `s` favourite, `d` download mode, `o` toggle sort, `/` go to chapter, `↑/↓` chapters, `Enter` open chapter, `x` select chapter in download mode, `Esc` leave select mode, then pop.

**Platform deltas.** iOS: the header tilt uses the gyro; Android: same; web phone: scroll parallax only. Android back in select mode leaves select mode first.

### 4.13 Book page (novel series)

**Purpose.** The novel counterpart of the series page: front matter, contents, listen/narration, download book.

**Layout (phone).** Plane with the book's palette horizon at 0.7 of the usual opacity (books read calmer). Top controls: back; cluster: `DotsThree` (Add to collection, Recommend to…, Share link) and the notify bell when in the library.

1. **Front matter**, left-aligned like a title page: the book plate (120 × 180, radius 10, a 1 px rim, a subtle spine shadow on its left edge) floats at the right; to its left: `title1` title in **Literata** 30/36 w500 (`opsz` 30), byline in Literata italic `callout` "by {author}", a 48 px hairline, facts in `mono.meta`: "380 chapters · ≈ 1.2 M words · ≈ 80 h · Ongoing", and the estimate note `caption1` `label.3` "Length estimated from 12 chapters".
2. Primary (L) "Start reading" / "Continue · CH 42 · 18 min left" / "Up to date". Secondary capsules: "In your library" / "Add to library", "Listen" (`Headphones`, when narration exists or can be rendered), "Download".
3. **Narration strip** (when the server can narrate): "Audiobook · 120 of 380 chapters narrated" with a thin progress bar and a plain "Manage" (opens the audiobook picker).
4. Blurb in Literata `body` 17/28, max 62 ch.
5. Genre tags.
6. **Contents**: header "Contents" in Literata `title2` + trailing: order toggle (First → last / Last → first; default first → last), `MagnifyingGlass` "Go to chapter", "Pick chapters" (download picker). Rows: right-aligned ordinal (Literata tabular 15, 44 px column; "·" when there is none), title (Literata `callout`, 2 lines, read rows at `label.3`), trailing meta: "42 %" Iris (reading) / "Read" / "12 min", a `Headphones` 14 px glyph when narrated, and the download control. The list is windowed around the focus (400 rows), with "Show earlier" / "Show later" plain buttons at the window ends. The focused chapter (from the reader's Contents button or go-to) centres and carries a 7 % Iris wash.

**Go-to chapter.** The field morphs out of the search button: numeric input "Chapter number"; matches list below (up to 12 rows "Chapter {n} · {title}"), "and {n} more", "No chapter {n} in this book."

**Audiobook picker (sheet, medium → large).** Segmented "Narrate" / "Save audio to this device" (the second only when downloads are possible). Helper chips: Next 10 · All un-narrated ({n}) · None. A checklist of chapters with subtitles ("Narrated · saved on this device", "Narrated", "Download the text first", "Saving", "Couldn't be saved. Select to retry", "Not narrated yet"). Estimate caption: "About {n} minutes of rendering on the narration PC." Primary "Narrate {n} chapters" / "Save audio of {n} chapters". Job progress: per-chapter rings (queued, planning, rendering with progress, done, failed, cancelled). Unavailable: notice "Narration isn't available right now. Chapters that already have audio can still be saved."

**Layout (desktop).** Front pane like a book spread: left page 44 % (front matter, actions, blurb, narration), right page 56 % (contents, sticky header). A 1 px vertical gutter line between them in `line.hair` with a soft 24 px inner shadow, the only place Strata draws a "page" metaphor outside the reader.

**Signature moment.** **The book opens toward you**: the plate flies from the shelf row into the front matter, and on "Start reading" the plate swings open (the cover rotates `rotateY(−100°)` around its left edge on `spring.dive`, revealing the paper colour) as the novel room rises behind it.

**Gestures.** As the series page; swipe a contents row leading "Mark read", trailing "Download".

**States.** Front-matter skeleton, contents skeleton (10 rows), offline (downloaded chapters only), error ("Couldn't load this book" + Back), contents unavailable (notice + Retry), no chapters ("No chapters yet."), narration job errors inline per row, `narration_unavailable` notice, `audio_preparing` ("Preparing audio" with an orbit on the Listen button).

**Keys (web).** `Enter`/`c` continue, `l` listen, `f` add to library, `/` go to chapter, `o` order, `d` pick chapters, `↑/↓`/`Enter` contents.

---
### 4.14 Manga reader (strip, single, double, read all)

**Purpose.** Read images: the webtoon strip (default), single and double pages, and Read all (a whole series as one scroll). One Room implementation serves every reader route (library triple, source chapter id, read-all). Reference: the Webtoon app's vertical reading with auto-hiding chrome and a next-chapter card, re-built as a deep room.

#### 4.14.1 Canvas

- Background `#000000` (Abyss) by default; "Graphite" `#0E0E10` as the only alternative page background (dark only). Colour modes: Normal, Sepia (a 3 × 3 colour matrix: `0.393 0.769 0.189 / 0.349 0.686 0.168 / 0.272 0.534 0.131`), Gray (luminance matrix).
- **Strip:** pages seamless (no gap, no radius) in a centred column: phone full width; tablet `min(100%, 768px)`; desktop `clamp(480px, 50vw, 900px)` with the rest of the width for side panels (§4.14.6). Page gap option: 8 px of `#000` between pages. Each page reserves its box from the manifest's width and height (or 2:3 until known), so nothing jumps.
- **Single / Double:** fit-to-stage pages (Fit width, height, screen, original), 8 px spread gap, RTL mirrors spread order; pages sit on the canvas with a 0.5 px `rgba(255,255,255,0.06)` rim and radius 4 so the page edge is visible on black.
- **Read all:** always strip; chapters stitched in order with the seam (§4.14.5).
- **Night dim and warmth:** brightness range −75 … 100: values below 0 draw black over the pages at `|v| / 100` alpha (true night mode on AMOLED); warmth draws `#FF8A3D` in multiply at up to 0.35. Both sit above the pages and below the chrome.
- **Page tint:** the current page's tint (§2.1.9) feeds the chrome (§5.4.4) and the bottom 64 px under the toolbar, never the page.

#### 4.14.2 Chrome: three floating controls

The Room has no bars. When visible:

- **Top-left:** back circle 44 px with the `strata` depth glyph (lit bars = how deep the plane you dove from is). Tap surfaces to that plane; long press opens the stack overview of the bay behind the room.
- **Top-centre:** title capsule (44 px, `glass.float`, max 70 % width): series title `caption1` `label.2` over the chapter label `headline` ("Chapter 142"); in Read all, a trailing `mono.meta` "142 / 380". Tap opens the chapter list sheet (§4.14.9).
- **Top-right:** cluster of three: bookmark toggle (`BookmarkSimple`, Fill + Iris when this spot is saved), download control (§3.29) for this chapter, and reader settings (`SlidersHorizontal`).
- **Bottom:** the **toolbar capsule**, 56 px, inset 16 px from the sides and 12 px from the safe bottom, `glass.float` with the page tint: `SkipBack` previous chapter (44), the liquid scrubber (flexible, §4.14.4), `SkipForward` next chapter (44). Above it, the room's accessory slot (10 px gap): the auto-scroll control when auto-scroll runs, else the soundscape capsule when a soundscape plays (§5.4).
- **Page line** (inside the scrubber lens only while dragging; otherwise a `mono.meta` line right-aligned above the toolbar): "12 / 40 · 30 %".
- **Reading hairline:** the 2 px progress line at the very top edge of the screen, always visible except in cinema.

**Show and hide (same thresholds on every platform).** Hide when the cumulative downward scroll since the last direction change reaches 24 px; show after 56 px of cumulative upward scroll, at chapter end, on a centre tap, on pointer movement into the top or bottom 72 px (desktop), on any key, and on keyboard focus entering the chrome. After a tap opened the chrome it hides after 3000 ms idle (timer paused while a sheet, scrubber drag or menu is open). Never hidden during the first 800 ms after a chapter loads. Hiding is **minimising, not vanishing**: the top controls dematerialize upward 12 px with blur 8 and scale 0.92; the toolbar capsule morphs into a **pill** (32 px tall, 72 px wide, centred) that shows only "12 / 40" and stays at the bottom; tapping the pill restores the chrome. **Cinema mode** hides the pill too (all chrome gone after 3000 ms idle; `c` toggles).

**Desktop side panels (≥ 1024 px).** Left panel (280 px, `slab.1` at 0.92 over the canvas, radius 24, inset 12): the chapter list with 48 × 72 first-page thumbnails, the current chapter highlighted, download marks, "Read all" at the top. Right panel (340 px): reader settings inline (the sheet's controls in a scrolling column). Panels are content-level surfaces (not glass) and each toggles with `t` (chapters) and `,` (settings); the strip shifts on `spring.smooth` so it stays centred in the remaining width. Both panels auto-hide with the chrome in cinema mode.

#### 4.14.3 Gestures and input

| Input | Strip | Single / Double |
|---|---|---|
| Tap | whole surface toggles the chrome (default); opt-in "Tap to scroll": top third + left-middle scroll back 75 % of the viewport, bottom third + right-middle forward, centre toggles (300 ms `cubic-bezier(0.5, 1, 0.89, 1)`) | zones 30 / 40 / 30: previous / menu / next, mirrored for RTL; user-configurable per zone |
| First run of a layout | the zones paint once as three glass panes with labels "Back", "Menu", "Next" at 0.6 opacity; fade out over 1000 ms after 1500 ms | same |
| Double tap | zoom 2× at the point in 250 ms; again returns to 1× | same |
| Pinch | 1–3×; in strip also out to 0.6× ("overview", several pages visible) | 1–4× |
| Drag while zoomed | pans; fling decelerates over 400 ms | same |
| Long press 450 ms on a page | page menu (L6, blooms from the finger): Bookmark this spot, React to this chapter, Show dialogue text, Guided view from here, Save page image, Copy page link (web) | same |
| Horizontal swipe (not from the edge) | chapter change: a 72 px threshold with rubber band before commit; the next chapter plane peeks from the side as you drag | page turn with the finger; release decides by projection; `spring.smooth` settle |
| Vertical swipe on the left 12 % band | brightness: a fill-slider HUD (L8) appears at the left edge and fades 600 ms after release | same |
| Edge swipe from the leading 20 px (iOS) / predictive back (Android) | surfaces to the plane you came from; the page shrinks toward the back circle as you drag | same |
| Two-finger pinch-in below 0.6× in strip | opens the stack overview of the bay behind (the room is shown as the top card) | n/a |
| Five centre taps within 2 s each (when "Lock controls" is on) | unlock; HUD "Controls unlocked", medium haptic | same |
| Volume keys (Android, opt-in) | scroll 85 % forward / back | next / previous page |
| Mouse wheel | native scroll; `Ctrl`/`⌘` + wheel zooms around the pointer | one page per wheel gesture (200 ms idle reset) |
| Middle click (desktop) | autoscroll anchor: 12 px dead zone, 10 px/s per px of offset, max 4000 px/s | n/a |

A tap pauses auto-scroll; auto-scroll resumes 800 ms after the finger lifts if it was running.

#### 4.14.4 The liquid scrubber

A glass capsule track inside the toolbar: 4 px rail `rgba(255,255,255,0.18)`, Iris fill to the current page, notches for chapter boundaries (Read all) and 6 px bookmark ticks in Glacier. The thumb is a 20 px white circle at rest. While dragged:

- the thumb becomes a 36 px `glass.clear` lens that stretches along the drag (width up to 1.25× at speed, `spring.track`);
- a **lens preview** (L8) rises 16 px above the thumb: a 72 × 108 thumbnail of the target page (from the manifest URLs at `?w=144`) in a `glass.float` frame with the page number `mono.meta` under it;
- each page step plays a selection haptic; crossing a chapter notch plays rigid 0.7 and the lens shows the chapter title;
- releasing jumps (strip: scrolls to the page's top; paged: turns) and the lens sinks back into the thumb on `spring.detent`.

Keyboard: the rail is a native range underneath (`role="slider"`, `aria-valuetext="Page 12 of 40"`), RTL-aware. Disabled for one-page chapters.

#### 4.14.5 Chapter boundaries

Setting "Between chapters": **Seamless** (default) or **Card**. Read all is always seamless.

- **Seamless.** The next chapter is prefetched from 70 % of the current chapter (first 3 pages), fully when the boundary comes within 150 % of the viewport. Chapters are stitched with a 96 px seam of black holding a hairline, the chapter number `mono.meta` and title `caption1`. As the seam scrolls under the top edge, a glass chip "Chapter 143" (L5, 32 px) materializes at the top-centre, sticks for 1.2 s, then melts away (blur 8 + fade). Scrolling past the seam marks the previous chapter complete (medium haptic at the crossing). Scrolling up from the first page of a chapter stitches the previous chapter above it the same way.
- **Card.** At the end of the chapter the strip rubber-bands (bouncing physics, constant 0.55). At 90 px of overscroll the **next-chapter plane** rises from the bottom as a medium-detent card: the next chapter's first page as a 3D thumbnail tilted 8° (gyro ±4°), "Chapter 143 · {title}", "12 pages · 4 min", the Circle reaction summary of the chapter you finished with the reaction bar (§5.3.4), and a primary "Continue". Releasing past 140 px or pressing Continue **locks in** (haptic `surfaceLock`) and the card expands to full screen and becomes the new chapter (a dive at depth 0, `spring.dive`).
- **Caught up.** The end card reads "You're caught up" with the next expected date when the source publishes a schedule, a switch "Notify me about new chapters" (follows if needed), the reaction bar, the "More like this" rail (§5.1.4) and "Back to series".
- **Missing chapters** between two chapter numbers (for example 141 → 143) insert a warning row in the seam or on the card: "Chapter 142 is missing on {source}".
- **Next chapter failed to load:** the seam or card shows "Chapter 143 didn't load" + "Try again" + "Open it on its own"; retries back off 2 → 30 s automatically.
- **End of series (source has nothing more):** "That's everything {source} has published so far."

#### 4.14.6 Reader settings sheet

`SlidersHorizontal` opens a sheet at the medium detent (the strip stays live above it, per the Kindle rule), large on drag. On desktop the same controls live in the right side panel. Sections (grouped lists inside the sheet):

| Section | Control | Options / range | Stored |
|---|---|---|---|
| Layout | Segmented | Strip · Single · Double (hidden in Read all) | per series |
| | Direction (paged) | Left to right · Right to left | per series |
| | Fit | Width · Height · Screen · Original (Height/Original disabled in Strip with a helper) | per series |
| | Zoom | stepper 50–300 % step 10, reset | per series |
| | Page gap | switch (Strip) | profile |
| | Between chapters | Seamless · Card | profile |
| | Page turn (paged) | Slide · Fade · None | profile |
| Light | Brightness | fill slider −75 … 100 (below 0 shows "Night dim") | profile |
| | Warmth | slider 0–100 % | profile |
| | Colour | Normal · Sepia · Gray | profile |
| | Page background | Abyss · Graphite | profile |
| | Page-tinted controls | switch (default on) | profile |
| Motion | Auto-scroll | switch + speed button (opens the speed dial 0.5×–3.0× of 60 px/s) | per series (speed) |
| | Cinema mode | switch | profile |
| | Guided view | "Start guided view" (manga pages with panel data) | n/a |
| Taps | Tap zones | three rows Left / Centre / Right, each Previous · Menu · Next, "Reset", and "Tap to scroll" (Strip) | profile |
| Device | Keep screen awake | switch | device |
| | Auto next chapter | switch | device |
| | Lock controls | switch ("Tap the centre five times to unlock") | device |
| | Volume keys turn pages | switch (Android) | device |
| | Refresh rate | Auto · 60 · 90 · 120 Hz chips (Android) | device |
| Ambient | Soundscape | row → soundscape sheet (§5.4.2) | profile |
| Actions | Save bookmark · Go to series · Fullscreen (web) · Keyboard shortcuts (web) | rows | n/a |

#### 4.14.7 States

| State | UI |
|---|---|
| Loading chapter | the room is black; three skeleton pages (2:3, max 420 wide, radius 8) with the depth shimmer and `caption1` `label.3` "Loading chapter 142"; the chrome is shown |
| Page placeholder | an empty box at the page's aspect ratio in `#050506`, no spinner |
| Broken page | inside the page box: `ImageBroken` 28 px `label.3`, "This page didn't load" and a secondary "Retry" (reloads that image only) |
| Chapter error | floating object "Couldn't open chapter 142" + "Try again" + "Go to series" |
| No pages | "This chapter has no pages." + "Next chapter" / "Go to series" |
| Read-all list failure | "This series' chapter list didn't come through, so there's nothing to read through." + Retry |
| Offline | reads from the device without a sound; an "Offline copy" HUD shows for 2 s; neighbours not on the device show the seam/card "Not downloaded" with a download button |
| Stale bookmark | toast "This page moved. Opened at the nearest one." |
| Further on another device | toast "You're further on another device: CH 145 p. 3" + "Jump" |
| Rate limited | prefetch pauses silently; if the visible page is blocked, the page box shows "Slowing down for {source}: {n} s" |
| Bookmark saved / failed | toast "Saved this spot" (success) / "Couldn't save that spot" (error) |

#### 4.14.8 Keys (web and hardware keyboards)

| Keys | Action |
|---|---|
| `→` / `d`, `←` / `a` | Turn page in the reading direction (paged) / scroll one screen (strip) |
| `j` / `k` | Next / previous page |
| `Space` / `Shift Space` | Forward / back one screen |
| `Home` / `End` | First / last page |
| `h` / `l` (also `Ctrl Shift ←/→`) | Previous / next chapter |
| `g` | Go to page (focuses the numeric field in the lens) |
| `f` | Fullscreen |
| `c` | Cinema mode |
| `v` | Show / hide chrome |
| `p` | Auto-scroll play / pause; `<` / `>` slower / faster |
| `b` | Bookmark |
| `s` | Go to series |
| `t` | Chapter list (panel or sheet) |
| `,` | Reader settings |
| `=` `+` / `-` / `0` | Zoom in / out / reset |
| `w` / `1` / `2` | Strip / single / double layout |
| `r` | Toggle reading direction (paged) |
| `x` | Guided view on / off |
| `Esc` | Close overlay → leave fullscreen → leave cinema → surface to the series |
| `?` | Shortcuts sheet |

#### 4.14.9 Chapter list sheet

From the title capsule: a large-detent sheet listing chapters (newest first, current chapter scrolled into view with an Iris wash), rows with the first-page thumbnail (40 × 60), download marks and read state; a search field "Go to chapter"; "Read all from here" as a trailing swipe action. Tapping a chapter drops the sheet and cross-dives into that chapter.

#### 4.14.10 Reader landing (`/read`)

A plane with the floating object `strip` glyph, "Pick something to read", body "Open a series from your library or Home.", actions "Continue {last series}" (primary, when there is one) and "Open library".

#### 4.14.11 Dialogue text overlay

From the page menu "Show dialogue text" (when that chapter has been scanned): the page dims to 0.6 and each recognised text box gets a 1.5 px Glacier outline (radius 6) at its position; tapping a box shows its text in a HUD capsule with "Copy" and "Search this line" (opens the OCR plane with the text). `Esc` or a tap outside the boxes closes the overlay. When the chapter has no scan: "No dialogue text for this chapter. Scan it from Downloads." (mobile) / "No dialogue text for this chapter." (web).

#### 4.14.12 Signature moment and transitions

**The dive** (§2.9.4): pressing Continue or a chapter row pushes the whole app into the dark while the first page comes up to meet you. **Surfacing**: leaving the room brings the app back up under your finger to the exact plane, scroll position and focus you left.

Platform deltas: iOS keeps the status bar hidden in the room and restores it on surfacing; Android uses immersive-sticky and pins the refresh rate while in the room; mobile web requests fullscreen only on the `f` button (no automatic fullscreen); desktop web uses the side panels.

### 4.15 Novel reader

**Purpose.** Read web novels like a book: dark papers, typography controls, page turns or scrolling, bookmarks, and the entry to listen mode. Reference: Apple Books / Kindle.

#### 4.15.1 Paper and layout

- The page is painted in the chosen paper (§2.1.8, default Abyss). The whole room takes the paper colour; there is no app chrome colour.
- **Reading mode** (per profile): **Pages** (default) or **Scroll**.
  - Pages: CSS multi-column pagination on the web (the column width is the measure, the gap 2 × margin), a paginated `PageView` over pre-laid text on Flutter. Margins: phone 24 px, desktop measure-driven with a minimum 64 px margin. Desktop at ≥ 1280 px shows a **two-page spread** (two columns side by side with a 1 px `line.hair` gutter shadow).
  - Scroll: one column at the measure, centred.
- Header of each chapter per §2.3.4; paragraphs with first-line indent 1.3 em (flush after headings and scene breaks), scene breaks as three centred 4 px dots in `muted` at 0.5 em spacing.
- **Speaker tints** (when attribution matches the text): attributed dialogue gets its speaker's 14 % band and a 1.5 px underline at 55 % (§2.1.7); a switch in the type sheet turns them off.
- **Line guide** (optional, type sheet): everything outside a 3-line band is covered by the paper colour at 0.55 with a 6 px blur; drag the band or tap above/below to move it.

#### 4.15.2 Page turn: "lift"

Strata's page turn is spatial: the current page **lifts toward you** (scale 1 → 1.04, shadow `0 24px 48px rgba(0,0,0,0.6)`) and slides away in the reading direction on `spring.smooth` while the next page is revealed underneath, already in place (it rises from brightness 0.8 to 1). Finger-driven: the page follows the drag 1:1 (translate and a slight 3° rotation around its spine edge), release by projection (threshold 30 % of the width or 700 px/s). Tap turns use the same spring. Options in the type sheet: **Lift** (default), **Slide** (plain horizontal on `spring.smooth`), **Fade** (160 ms cross-fade). Reduced motion: Fade. Haptic selection per turn.

#### 4.15.3 Chrome

Tap the centre (Pages: middle 50 % of the width; Scroll: anywhere) to show; it hides on turn/scroll and after 3000 ms idle.

- **Top-left:** back circle (depth glyph) → surfaces to the book page.
- **Top-centre:** title capsule: book title `caption1` over "Chapter 12" `headline`; tap opens Contents.
- **Top-right cluster:** Contents (`ListNumbers`), Bookmark (`BookmarkSimple`), Type and page (`TextAa`).
- **Bottom capsule** (56 px): `CaretLeft` previous chapter, a centred progress block (`mono.meta` "42 % · 12 min left in chapter", and in Pages mode "p. 7 of 18"), `CaretRight` next chapter, and a separate 56 px glass circle to its right: **Listen** (`Headphones`), which morphs into the mini player when narration starts.
- All chrome glass takes a paper-aware tint: on light-ink dark papers the float fill mixes 12 % of the paper's text colour so the controls belong to the page.
- An "Offline" `CloudSlash` 14 px glyph appears in the title capsule when reading a downloaded copy.

#### 4.15.4 Type and page sheet

Medium detent only (≤ 50 % height) so the page reflows live above it; Lift material tinted by the paper.

1. Face: four tiles, each set in its own face ("Aa" 28 px): Literata, Newsreader, Google Sans Flex, Atkinson Hyperlegible Next.
2. Size: stepper 14–30 (and `-`/`=` keys), shown as "19 px".
3. Line height, measure, paragraph spacing, character spacing, word spacing: steppers or sliders with ticks (selection haptic per step).
4. Bold text switch, Justify switch, Speaker colours switch, Line guide switch.
5. Paper: seven orbs (40 px circles filled with the paper, "Aa" in its ink, a specular crescent); the chosen one gets `select.ring`. Changing paper recolours the room over 400 ms.
6. Page turn: Lift · Slide · Fade; Reading mode: Pages · Scroll.
7. "Reset to defaults" plain button.

Typography is saved per book; paper, page turn and reading mode per profile.

#### 4.15.5 Contents sheet

Large detent, painted in the paper: "Contents" (reading face `title2`), a "Go to chapter" field, chapter rows (ordinal, title, "42 %" or "Read", `Headphones` glyph when narrated, download mark), current chapter centred with a 7 % Iris wash. Tapping a row turns to that chapter with a Lift transition of the whole spread.

#### 4.15.6 Chapter end

- **Pages:** the last page carries the end matter: a 96 px hairline, "End of chapter 12" (`caption1` +0.18 em), the chapter length, the reaction bar (§5.3.4), and the **next-chapter card** (a `slab.1` card in the paper's tint: "Next · Chapter 13 · {title} · 14 min" + `CaretRight`). Turning past the last page continues seamlessly into chapter 13 (marks 12 complete). At the book's last published chapter: "You've reached the last chapter {source} has published." + notify switch.
- **Scroll:** the same end matter; overscrolling 140 px at the bottom continues into the next chapter in place (URL replaced, no navigation), with the seam chip "Chapter 13" as in the manga strip.
- Auto-next (setting) waits 900 ms at the end, unless narration is playing.

#### 4.15.7 States

Loading (12 text-line skeletons at varied widths in the paper's muted colour), offline (downloaded text; "Offline" glyph), not downloaded while offline (floating object "This chapter isn't on this device" + "Open downloads"), error ("Couldn't load this chapter" + Retry + "Back to the book"), empty ("This chapter came through empty. The source may have pulled it or still be publishing it."), stale bookmark ("The text changed here. Opened at the nearest paragraph."), bookmark saved/failed toasts, "further on another device" toast.

#### 4.15.8 Gestures and keys

Gestures: tap zones in Pages mode 25 / 50 / 25 (previous / menu / next; "Both margins advance" option), swipe to turn (Lift follows the finger), long press a paragraph (menu: Bookmark here, Copy, Listen from here, Search dialogue), pinch changes text size in steps (selection haptic), left-edge vertical swipe for brightness, edge swipe back surfaces.

Keys: `→`/`d`/`j`/`Space` next page, `←`/`a`/`k`/`Shift Space` previous page, `Home`/`End` chapter start/end, `h`/`l` chapters, `=`/`-`/`0` text size, `t` type sheet, `o` contents, `b` bookmark, `p` listen play/pause, `g` go to %, `f` fullscreen, `c` hide chrome, `Esc` close sheet → surface to the book, `?` shortcuts.

**Signature moment.** The **lift page turn**: the page you finish rises toward you and slides off like a sheet of glass lifted from a stack, with the next page already waiting beneath it.

### 4.16 Listen mode (narration with the 31 named voices)

Narration is pre-rendered per chapter on the server; the room plays it and follows the text.

#### 4.16.1 Mini player

When narration plays, the Listen circle morphs into the mini player in the room's accessory slot (and, when you leave the room, in the dock accessory of every bay): a 52 px glass capsule with the **voice orb** (32 px, the narrator voice's hue, its glass pulsing with the audio level at 30 fps), chapter title `subhead` + "18 min left" `caption1`, a 15 s back button, play/pause (40 px), a 2 px progress line along the bottom inner edge (buffered at 35 %). It lingers 5000 ms after the room's chrome hides. Tap opens the Listen stage; swipe it left/right for previous/next chapter.

#### 4.16.2 The listen stage

A room layer, opened from the mini player, the Listen button or `?listen=1`:

- **Depth move:** the page recedes to deck 1 (scale 0.94, brightness 0.56) and the listen stage rises in front as a Lift-glass panel that fills the screen minus 8 px insets (phone) or a 560 × 760 floating window (desktop), on `spring.lift`.
- **Top:** close circle (returns the page forward), the book and chapter (`caption1` / `headline`), and a `DotsThree` menu (Save audio to this device, Voices, Report a bad line).
- **The voice orb** (144 px) at the upper third: a glass sphere in the narrator's hue with the current speaker's hue flowing into it when a character speaks (a 300 ms colour cross-fade), pulsing with the level, and a "now speaking" person chip under it ("Narrator" or "Mira · voiced by Ada").
- **Sentence list** (lyrics style) below: the chapter's sentences on the glass, `body` in the reading face at 60 % `label.2`; the active sentence sits on a Glacier-tinted lozenge (`rgba(143,216,255,0.16)`, radius 12, padded 4 × 8) that **morphs** from sentence to sentence (shared layout, `spring.smooth`); the active word brightens to `label.1` with a 2 px Glacier underline, stepping without animation. The active sentence is kept at 38 % of the list height; scrolling manually decouples it and shows a Glacier "Back to voice" pill (L5) at the bottom of the list; auto-return after 4000 ms idle in this view. Tapping a sentence seeks there ("Play from here").
- **Transport:** scrubber (as §4.14.4 but with time labels `mono.meta` "5:12" and "−18:40"; chapter segments ticks), then 15 s back, play/pause (72 px glass circle, the stage's single tint: Iris), 15 s forward, previous/next chapter at the ends.
- **Tiles row** (four 72 px tiles, `fill.2`): **Speed** ("1.25×"; tap opens the speed dial, hold resets to 1×), **Voices** (opens the cast sheet), **Sleep** (menu: Off, 5, 10, 15, 30, 45, 60 min, End of chapter, End of next chapter; the tile shows the live countdown; the last 8 s fade the volume out; shaking the phone during the last minute extends by 5 min with a HUD "+5 min"), **Soundscape** (§5.4.2; narration ducks a playing soundscape to 30 %).
- **Highlight refusal:** when the text on screen no longer matches the timing map (`highlight_safe` false or fingerprint mismatch), the lozenge hides and a quiet line reads "Highlight paused: the text changed." Audio continues.
- **Chapter boundary:** a post-play card rises over the sentence list: "Next: Chapter 13" with a 5 s countdown ring (Iris) around "Play now"; tapping anywhere else cancels.

**Signature moment.** The **stage takes the stage**: the page steps back and the voice orb comes forward and breathes with the narrator; when a character speaks, their colour flows into the orb and the lozenge slides to their line.

#### 4.16.3 Voice gallery (31 voices)

Opened from the cast sheet ("Choose a voice for {name}" / "Narrator voice"). A large sheet (desktop: 880 × 640 panel).

- **Orbit carousel (default view).** The voices sit on a horizontal ring in depth: the centre card at scale 1.0 (L6 glass card 200 × 260), neighbours at 0.86 and 0.6 opacity, the ring curving away to the back. Swipe or `←/→` to rotate (selection haptic per voice); the centred voice **plays its self-introduction after 400 ms at rest** (stops when moved). Card content: voice orb (96 px, the voice's own hue from a 31-step hue wheel, deepest voices at the violet end), name `title2`, gender + character `subhead` ("Female · the calm mentor"), a pitch scale "Deeper ←●→ Brighter" from `pitch_hz`, an expressiveness meter (5 bars), duration of the intro, and the licence credit `caption2` `label.3`. Buttons: play/pause intro (secondary), "Use" (primary) / "In use" (disabled with `Check`).
- **Grid view** (toggle `SquaresFour`): 2 columns phone / 4 desktop of compact voice cards; search field "Find a voice"; filter chips All · Female · Male · In use.
- Voices are ordered deepest first within each gender (the server's order).
- **States:** loading (skeleton ring), no voices installed ("No voices are installed on the server, so characters can't be cast yet."), sample loading (orbit on the play button), sample error ("No preview for {name}"), saving ("Saving"), error ("That voice couldn't be saved. {reason}"), not the owner (Use buttons hidden; "Only the server owner can change voices." notice), re-render note (`caption1`): "Chapters already narrated keep their voice until they're narrated again."

#### 4.16.4 Cast sheet

Medium → large sheet from the Voices tile or the reader's `DotsThree`. Title "Voices in this chapter". Status line: "Looking up who speaks here" (loading) / "Nobody else was identified with enough confidence, so the narrator reads everything." (empty) / "Narrated by {name}: their own lines use the narrator's voice." (narrator is a character).

Rows: the **Narration** row pinned on top (voice orb 32, "Narration", voice name, `CaretRight`); then one row per character in cast order: speaker swatch 12 px (their tint), name `headline`, voice name or "Automatic" `subhead` `label.2`, share of lines as a small bar + "18 %", a `Lock` glyph when hand-assigned. Tap → voice gallery filtered by the character's gender. Owner-only row menu: "Same person as…" (alias merge: pick another character; toast "{alias} now counts as {canonical} in every chapter").

#### 4.16.5 Saving narration and audio states

In the mini player menu and the book's audiobook picker. Per chapter: not saved (`ArrowCircleDown`), saving (ring), saved ("Audio saved on this device"), failed ("Couldn't save the audio. Tap to retry."), unplayable ("The saved audio can't play on this device. Tap to save it again."); remove saved audio → Undo toast "Audio removed. The chapter text stays." Player states: preparing (`audio_preparing`: "Preparing audio" with an orbit in place of play; retries every 3 s), not narrated (the Listen button reads "Narrate this chapter" for the owner, or is hidden for others), narration unavailable (hidden, notice on the book page), error ("Audio couldn't load. Retry"), offline without saved audio ("Audio needs a connection").

**System media controls.** Web: `navigator.mediaSession` metadata (title, book, cover artwork) and actions (play, pause, seekbackward, seekforward, previoustrack, nexttrack). Flutter: `audio_service` for the lock screen, notification and headset controls (the one new dependency listen mode needs; pinned to the newest release that resolves on Flutter 3.44.6 at implementation time and verified with `flutter pub get` in CI); the session stays `AVAudioSessionCategoryPlayback` / speech on Android as the app already configures it.

**Keys (web).** `p` / `Space` (in the stage) play/pause, `[` / `]` previous/next sentence, `Shift [` / `Shift ]` back/forward 15 s, `<` / `>` speed −/+ 0.05×, `h`/`l` chapters, `v` voices, `Esc` close the stage.

---
### 4.17 Library (the Library bay)

**Purpose.** Everything this profile follows: the shelf, full browse with search, filters, sort, density, manual order, multi-select with bulk actions, and the doors to Collections, History, Bookmarks and On this device.

**Layout (phone).** Bay root. Top controls: You orb; cluster: compact mode switch and `DotsThree` (Select, Density, Manual order editing). Content:

1. `largeTitle` "Library" + `subhead` `label.2` "{n} series followed" (Novels mode: "{n} books on your shelf").
2. **Shelf doors**: a horizontal row of four 148 × 76 `slab.1` tiles (radius 20): Collections (`Stack`, count), History (`ClockCounterClockwise`, "Last: 2 h ago"), Bookmarks (`BookmarkSimple`, count), On this device (`ArrowCircleDown`, size "3.4 GB"). Each pushes its plane; the tile's glyph flies into the new plane's header.
3. **Toolbar** (sticky under the top controls with the hard edge once it pins): search field "Search your library" (44 px), then a chip rail: All · Reading · Not started · Completed · On hold · Plan to read · Dropped · ★ Favourites; and a sort button (`ArrowsDownUp` + current sort label) that blooms into a menu: Recently updated (default), Recently added, Title A–Z, Title Z–A, Manual order.
4. **Continue** rail (deck cards), only when no search or filter is active.
5. **The grid** in the chosen density:
   - *Comfortable*: M posters, 3 columns (phone), titles and read state under each.
   - *Compact*: S posters, 4 columns, title only.
   - *List*: rows 76 px: 48 × 72 cover, title `headline`, status chip + read state `caption1`, trailing favourite star and follow bell (plain icon buttons).
   - Novels mode replaces the grid with the **book shelf**: rows of 52 × 76 plates, Literata titles `headline`-size, "{author} · {n} chapters · {status}", 2-line blurb, genre line `caption2` +0.12 em, read note.
6. Overflow note when more than 200: "Showing the first 200 of {total}. Search or filter to narrow it."

**Manual order.** With sort = Manual order, long press lifts a poster and drag reorders (grid reorder); order is saved to the series' `sort_order`. Keyboard: `Alt+arrows`.

**Select mode and bulk actions.** `DotsThree` → Select (or long press → Select in the context menu, or `x` on desktop). Posters get check discs; the dock accessory slot turns into the **bulk bar** (L5 capsule, full width): "{n} selected" + "Select all" and five glass icon buttons with labels on long press: Favourite, Mark read, Add to collection, Download…, and a `DotsThree` (Unfavourite, Mark unread, Unfollow). Running: the bar shows "{done} of {total}" with a progress line and "Stop" (concurrency 4). Result toast: "12 series marked read" / "10 unfollowed, 2 failed · Retry" with **Undo** for unfollow and status changes.

**Layout (desktop).** Root pane: title row with the count, shelf doors as a row of four tiles on the right of the title, sticky toolbar (search, chips, sort menu, density segmented `SquaresFour` / `GridNine` / `Rows`), grid 6–10 columns. Shift-click selects ranges. Hovering a poster shows the quick-action capsule (Follow bell, Favourite, ⋯).

**Hierarchy.** Title → doors → toolbar → Continue → grid.

**Signature moment.** **Unfollow sinks into the abyss**: bulk or single unfollow makes the affected posters drop out of the grid into depth (scale 0.8, brightness → 0, blur 12, on `spring.drop`), the grid closes the gaps on `spring.smooth`, and Undo raises them back from the dark to their old places.

**Transitions.** Bay switch in; pushes: series (cover flight), doors (glyph flight); filter changes cross-fade the grid (150 ms) and re-assemble with the diagonal wave only for new items.

**Gestures.** Long press poster (context menu), swipe list rows (leading Favourite, trailing Unfollow), pull to refresh, pinch on the grid switches density (pinch-in: denser; selection haptic at each density).

**States.**

| State | UI |
|---|---|
| Loading | title live; door tiles with skeleton counts; 12 poster skeletons (by density) |
| Empty library | floating object "Nothing followed yet" + "Browse sources" (primary) + "Get recommendations" |
| Empty shelf (Novels) | "Your shelf is empty" + "Browse novel sources" |
| No search result | "No series match '{q}'" + Clear |
| No filter result | "No series match these filters" + "Clear filters" |
| Offline | cached library with offline badges; items with downloads first; notice "Showing what's on this device" |
| Error | floating-object error + Try again |
| Inline page error after data | notice at the grid's end "Couldn't load more" + Retry |

**Keys (web).** `/` search, grid keys, `x` select, `Shift x` range, `Ctrl A` / `⌘A` select all (in select mode), `f` favourite focused, `u` unfollow focused (Undo toast), `o` sort menu, `v` cycles density, `Esc` leaves select mode.

### 4.18 Collections and collection detail

**Collections plane.** `largeTitle` "Collections" + count; cluster: sort menu (Name A–Z, Most series, Recently created, Custom order) and `MagnifyingGlass` (search field slides down). Sections: **Yours** and **Shared with you** (Circle collections, §5.3.5; the section exists only when something is shared). Content: a grid of collection stacks (§3.7): 2 columns (phone), 4–5 (desktop). Primary tinted "New collection" as the plane's action in the top cluster (phone: a `Plus` glass circle; desktop: a primary S capsule).

- **New / edit collection sheet** (medium): Name (placeholder "Late-night murim"), Description (optional), switch "Share with your circle" (§5.3.5) with a follow-up choice "Friends can add series" (collaborative), primary "Create" / "Save".
- **Custom order**: long press lifts a stack; drag reorders; saved to `sort_order`.
- States: loading (4 stack skeletons), empty ("No collections yet. Group series by mood, genre or anything you like." + "Create your first collection"), no search match, offline (cached), error.

**Collection detail plane.**

1. Header: the collection's four lead covers fanned in depth at large size (160 × 240, offsets 36 px), each on its own parallax factor (0.20, 0.30, 0.40, 0.50) so tilting the phone fans them; name `largeTitle`; description `callout` `label.2`; "{n} series" `mono.meta`; owner person chip when shared by someone else ("From Aya").
2. Cluster: `Plus` (Add series) and `DotsThree` (Edit, Share settings, Reorder, Select, Delete).
3. Grid of member posters (resolved to titles and covers from the library; a member no longer followed shows its cover if known, title "Not in your library" and a Follow quick action; an unresolvable member shows the monogram and "{source} · {key}").
4. **Add series sheet** (large): search field over the followed library excluding current members, a checklist of rows (cover 36 × 54, title), "Add {n}" primary. States: loading, "Everything you follow is already here", "No series match '{q}'".
5. **Remove**: context menu "Remove from collection", swipe on list density, or select mode "Remove {n}" → Undo toast "Removed from {collection}. The series stay in your library."
6. **Delete**: Veil confirm "Delete {name}? The series in it stay in your library." (danger "Delete").

States: loading (header skeleton + 6 posters), empty ("This collection is empty" + "Add series"), mode mismatch ("This collection holds novels. Switch to Novels to see them." + "Switch"), error (+ "Back to collections"), offline (cached).

**Signature moment.** **Adding drops into the fan**: when a series is added (from anywhere, including a poster's context menu "Add to collection"), its poster flies into the collection's fan and settles as the front card on `spring.bouncy`; the others shift back one depth.

**Keys (web).** `n` new collection, `a` add series, `/` search, `Delete` remove focused member (Undo), grid keys.

### 4.19 History

**Purpose.** Resume anything read, most recent first.

**Layout.** Plane `largeTitle` "History"; segmented "By series" / "Timeline".

- **By series**: grid of history tiles (§3.7): progress line, "CH 12 · 3 h ago" or "CH 12 · done", the Continue / Next glass circle on the cover. Next resolves the following chapter (fetching the chapter list; a spinner in the circle while resolving) and dives into the right reader; if there is no next chapter it pushes the series.
- **Timeline**: rows grouped by day (sticky day headers "Today", "Yesterday", "Mon 21 Sep"): cover 40 × 60, "Chapter 12 of {title}", pages or percent, reading time `mono.meta`. A right-edge date rail (phone) lets you scrub through days with selection haptics.
- Paging: loads 50 at a time; "Loading earlier" row at the end.
- Desktop: grid 6–8 columns; timeline in two columns (day list left, day detail right) at ≥ 1440.

**Signature moment.** The timeline's older days **recede** as you scroll down: each day section's header dims one step per week of age (brightness 1.0 → 0.7, floor 0.7), so time reads as distance.

**States.** Loading (10 tile skeletons), empty ("Nothing read yet. Open a chapter and it shows up here." + "Go to Home"), offline (cached + badge), error.

**Keys.** `[`/`]` switch view, grid keys, `Enter` continue focused, `n` next chapter of focused.

### 4.20 Bookmarks

**Layout.** Plane `largeTitle` "Bookmarks"; chips All · Manga · Novels and a series filter menu; bookmark cards (§3.7) grouped by series (series header rows with cover and count). Tap → dives into the reader at the exact spot; in the reader a Glacier chip "Back to where you were" (L5) appears for 6 s after a bookmark jump when you had an unfinished position elsewhere in that chapter.

**Actions.** Swipe trailing "Remove" (Undo toast); long press menu: Open, Edit note, Remove; **Edit note** opens a sheet with a textarea (200 characters), primary "Save".

**Desktop.** A front pane with the series filter as a sticky left column (series list with counts) and the cards in a two-column grid at ≥ 1280 px.

**Signature moment.** Bookmarks sit as **tabs sticking out of the page**: each card has a 6 × 24 px Iris ribbon notch on its right edge that lifts 2 px on hover/press, the one place a card has a physical tab.

**States.** Loading (5 card skeletons), empty ("No bookmarks yet. Press B while reading, or the bookmark button, to save the exact spot." + "Go to Home"), offline (local store, synced later; a `CloudArrowUp` badge on unsynced cards), error, stale anchor note per card.

**Keys.** `Enter` open, `e` edit note, `Delete` remove (Undo), `[` / `]` cycle the filter.

### 4.21 Updates (the Updates bay)

**Purpose.** New chapters for followed series, the checker, the follow list with per-series notifications, and Circle activity on things you follow.

**Layout (phone).** Bay root. Top: You orb; cluster: `ArrowClockwise` (Check now) and `DotsThree` (Mark all read, Mark all manga read / novels read, Update settings for admins). Content:

1. `largeTitle` "Updates" + line `subhead` `label.2`: "{n} unread · checked 12 min ago · every 60 min" (the schedule part from the checker settings).
2. Segmented control: **New** · **Following** · **Circle**.
3. **New**: notification cards (§3.7), one per series, grouped in day sections (Today, Yesterday, This week, Earlier). Unread cards carry the Iris dot; read cards sit at 0.7 brightness. Tapping a chapter line dives into the reader at that chapter and marks it read. Swipe leading "Mark read", trailing "Mute series".
4. **Following**: every followed series as rows: cover 40 × 60, title, source badge, "142 chapters · checked 2 h ago", a notify bell toggle (per-series notifications) and a `DotsThree` (Check this series now, Unfollow with Undo). Search field at the top.
5. **Circle**: activity on series you follow from Circle members (§5.3.2), newest first.
6. Admin only, at the bottom of New: **Recent checks** well (8 runs: trigger, status chip, "{n} series · {k} new", time) and a row "System status" → §4.26.

**Layout (desktop).** Root pane with the segmented control in the header; New shows cards in a 2-column masonry at ≥ 1280 px.

**Signature moment.** **Chapters surface**: when a check (manual or scheduled while the plane is open) finds new chapters, their cards rise from below the list's top edge into place (scale 0.94 → 1, brightness 0.4 → 1), older cards shift down on `spring.smooth`, the dock badge rolls to the new count and a success haptic plays. "Mark all read" sinks every unread dot in a 20 ms cascade.

**Check now.** The button's glyph becomes an orbit; the header line reads "Checking {n} series"; the result is a toast ("3 new chapters found" / "Nothing new") and the unread count refreshes at 3, 5 and 7 s. `check_already_running`: toast "A check is already running."

**States.** Loading (3 card skeletons), empty New ("No new chapters yet. Follow a series and this fills in when a chapter drops." + "Browse sources"), empty Following ("You aren't following anything yet."), empty Circle (§5.3.8), offline ("Updates need a connection." with the cached last list shown dimmed), error.

**Keys.** `r` check now, `Shift R` mark all read, `[`/`]` segments, `↑/↓` cards, `Enter` read newest chapter of the focused card, `m` mark read.

### 4.22 On this device (Downloads and Storage)

**Purpose.** Offline chapters and audio, the queue, storage policy, and (mobile) text scanning for dialogue search.

**Layout.** Plane (pushed from the Library door, the You sheet, the sidebar, the download accessory, or offline states). `largeTitle` "On this device" + `subhead` "Downloads belong to {profile} and open with no connection." Segmented **Chapters** · **Storage**. When no profile is active: floating object "Pick a profile first" (§3.24).

**Chapters tab.**

1. **Scan banner** (mobile, while an OCR run exists): notice card with a phase line: "Extracting text · page 3 of 40" (progress line), "Paused while the app is in the background", "Uploading the transcript", "Text extracted: 1,240 words are now searchable" (success), "Scan cancelled", "Scan failed" (danger) + "Cancel" while busy.
2. **Queue card** (`slab.1`, radius 20; hidden when idle): header "Downloading" / "Waiting to start" / "Paused" with pause/resume and "Cancel all" (Veil confirm "Cancel all downloads? Finished chapters stay on this device." → "Keep them" / "Cancel all"); the current chapter block (series, "Chapter 12 · page 7 of 40", or "Fetching the text" / "Saving the audio", a 6 px progress bar, "2 more downloading alongside", "12 of 40 saved in this series"); pause reason notice with its action: user ("Paused by you. Resuming picks up exactly where it stopped." + Resume), device full ("Paused: this device is almost full. Downloads stop before the last 1.5 GB." + Storage), cap ("Paused: downloads filled your 10 GB limit." + Storage), backgrounded ("Downloads only run while the app is open."); queue summary "4 in the queue · 1 failed" + "Show queue" disclosure listing queued rows (status, Retry for failed, Remove).
3. **Series on this device**, biggest first: expandable cards (cover 48 × 72, title, "40 chapters · 3 with audio · 1.2 GB" or "12 of 40 saved · 800 MB", a pin toggle "Keep" (exempt from auto-delete) and a `DotsThree`: Save to Files… (mobile), Remove all downloads (Veil confirm "Remove {n} chapters of {series}? Your reading progress is kept.")). Expanded rows: "Chapter 12" / "Chapter 12 · audio", status line ("Saved · 24 MB", "Deletes in about 3 days", "Open now, kept", "Incomplete: 38 of 40 pages", "Pages changed on the server: save again"), trailing actions: scan text (mobile manga; `TextT` → `CheckCircle` when scanned, orbit while scanning), Save to Files (mobile), remove (Undo).
4. Info notice: "Downloads live inside ManhwaManiacs and read offline from here. To keep a copy elsewhere, use Save to Files." (mobile) / "Downloads are stored in this browser for {profile}." (web).

**Storage tab.**

- The storage meter (§3.19) with "1.2 GB of 10 GB" (mobile cap) or "{usage} of {quota} used by this site · {free} free" (web).
- Mobile: chips **Storage limit** 2 GB · 5 GB · 10 GB · 20 GB · Unlimited; **Chapters at once** 1 · 2 · 3; **Delete after reading** Off · 24 hours · 48 hours · 7 days; **Wi-Fi only for automatic next-chapter downloads** switch; platform note (iOS "Browse, copy or delete downloads in Files: On My iPhone → ManhwaManiacs." / Android "Files live in the app's private storage."); **By series** breakdown rows; "Free up space" (secondary; toast "Removed 6 chapters" / "Nothing to free up right now"); **Image cache** card (size, "Clear image cache"); **Metadata cache** card ("Clear metadata cache").
- Web: **Delete finished chapters after** 2 days · 7 days · 30 days · Never; "Protect storage" (asks the browser for persistent storage; success chip "Storage protected"); explainer "Saving stops before the last 250 MB of the quota. When space runs low, finished chapters go first, oldest first, never one you haven't read or the one that's open."; "Remove all downloads" (Veil confirm) and "Reset offline storage" (Veil confirm: "This removes every download and restarts offline support.").

**Save to Files (mobile).** A medium sheet: "Save to Files" + explainer; rows "Page images" (`Images`, "A numbered folder per chapter") and "CBZ file" (`FileZip`, "One file per chapter, for comic reader apps"). Progress: a HUD toast "Saving to Files" with a progress line. Result sheet: "Saved to Files" / "Nothing to save", "{n} chapters · {m} pages", the path in `mono.meta` (selectable), skipped note, "Done".

**Desktop.** A front pane with the segmented control in the header; Chapters shows the queue card and the series cards in one 880 px column; Storage shows the meter full width and the policy and cleanup cards in two columns.

**Signature moment.** **Settling onto the device**: when a queued chapter finishes, its row drops out of the queue card and falls into its series card below (a short flight on `spring.smooth`), which briefly glows success at its rim; the storage meter's meniscus rises with a small bounce.

**States.** Pending ("Checking what's stored" with skeleton series cards), empty ("Nothing downloaded yet. Download chapters from any series and they open offline." + "Go to Library"; Novels: "No books downloaded yet"), unsupported (web without service worker or on an insecure origin: "Downloads aren't available in this browser."), error ("Couldn't read downloads").

**Keys (web).** `[`/`]` tabs, `Delete` remove focused chapter (Undo), `Enter` open focused chapter.

### 4.23 Dialogue search (OCR)

**Purpose.** Find a line of dialogue across scanned chapters of followed manga, and jump to the page.

**Layout.** Plane. `largeTitle` "Dialogue" + `subhead` "Search what characters said in chapters you've scanned." Field (autofocus) with placeholder "Search dialogue, like “I'll surpass you”". A coverage line `caption1` `label.3`: "Scanned chapters only. Scan downloaded chapters from On this device." (mobile) / "Chapters scanned on your phone are searchable here." (web).

Results: cards `slab.1` radius 20: series title (joined from the library; fallback "{source} · {key}"), "Chapter 142" `mono.meta`, the snippet in `callout` with matched terms in `label.1` w650 and a 2 px Glacier underline, meta `caption1` "{words} words · {engine}". Tapping looks up the chapter's page texts (`GET /ocr/chapter`) to find the page containing the terms and **dives into the reader at that page**, where the dialogue overlay (§4.14.11) opens with the matching box outlined.

Overflow: "Showing the first {n} of {total}. Add words to narrow it." with "Load more".

**Desktop.** A front pane with the field across the top (max 720 px) and result cards in a single 720 px column; the reader opens as a room over the pane stack.

**Novels mode.** Floating object `BookOpenText` "Dialogue search is for manga" + "Switch to Manga" (primary) + "Search novels instead" (secondary, opens Search).

**Signature moment.** The matching line **lifts out of the page**: on arrival in the reader, the page dims to 0.6 and the matching speech-box outline rises to L5 with a Glacier glow for 1.6 s before the overlay settles.

**States.** Idle (floating object `ChatTeardropText` "Search the dialogue you remember"), searching (3 card skeletons), empty ("No dialogue matches '{q}'. Only scanned chapters of series you follow are searchable."), offline ("Dialogue search needs a connection"), error, rate limited.

**Keys.** `/` field, `↑/↓` results, `Enter` open.

### 4.24 You (the hub)

**Purpose.** The profile, the streak, and every destination that is not a bay.

**Phone.** The You orb opens a sheet (medium → large):

- **Header**: profile orb 72 px with the mood ring, name `title2`, `caption1` "@{username} · {n} profiles", secondary S "Switch" (opens the picker, §4.5). Admin chip when the account is the administrator.
- **Streak card**: the flame (§5.2.3) at 48 px with "12-day streak" `headline` and today's ring (minutes read against the daily goal) + "Best: 31 days".
- **Update banner** (Android APK channel, when a newer build exists): Float notice "Update available · v{new} (build {n})" + "Download" (§4.28).
- **Quick tiles** (4 × 76 px `slab.1`): Stats, Circle, On this device, Collections.
- **List** (large detent): For you, History, Bookmarks, Dialogue search (Manga mode), Wrapped {year} (from 1 December, and on demand "Your year so far"), Settings, System status (admin), What's new, About ManhwaManiacs (v{version} ({build})), Sign out (danger, Veil confirm "Sign out on this device?").
- **Mode switch** full width at the bottom when novels are enabled.

Tapping a destination dematerializes the sheet while the destination plane rises in the current bay (one continuous depth move).

**Profile quick switch.** Long press the You orb: a menu blooms with the other profiles' orbs (44 px, names) and "Manage profiles"; picking one runs the arrival transition (§4.5).

**Desktop.** The sidebar footer row opens the same content as a Lift popover (360 px) anchored to the row; destinations open as panes. `g y` opens it.

**Signature moment.** The **You orb carries your streak**: its ring fills with the flame gradient as today's reading goal is met; completing the goal ignites it (§5.2.3), visible from every bay root.

**States.** Loading (header skeleton), offline (profile from cache; server-only rows disabled with "Needs a connection"), no profile (sheet shows only Switch profile and Sign out).

### 4.25 Settings

**Layout (phone).** Plane `largeTitle` "Settings" with a search field at the top ("Search settings"; results list matching rows with their section; choosing one pushes that section and pulses the row with a Glacier ring). Grouped sections, each a row that pushes a sub-plane:

1. **Skin**: "Glass" (§4.25.1)
2. **Reading**: manga and novel defaults
3. **Feedback**: haptics, interface sounds, solid glass
4. **Content and privacy**: mature content, Circle sharing, AI features
5. **Profiles** (§4.6)
6. **Account and security**
7. **Notifications and checks** (admin editable, others read-only)
8. **Members** (admin)
9. **Backup and restore** (admin)
10. **Server** (mobile)
11. **Storage** (opens On this device → Storage)
12. **Keyboard** (web)
13. **Diagnostics**
14. **About**

Footer `footnote` `label.3`: "Most settings apply right away. Changing the skin restarts the app."

**Layout (desktop).** A front pane split: a 260 px section list (rows with glyphs; the droplet marks the selected one) and the section content (max 720 px) to the right; the search field sits above the list; `↑/↓` move sections, `Tab` enters the content.

#### 4.25.1 Skin: the picker and the restart flow

**Picker (sub-plane).** `largeTitle` "Skin" + `callout` `label.2` "Two complete designs. Switching restarts the app and changes everything: layout, motion, navigation and sound."

Two **live preview cards in depth** (phone: stacked, the current skin in front and the other one behind it at deck-1 geometry, its name visible above; desktop: side by side, the current one lifted 8 px):

- Each preview is a 240 × 520 miniature phone frame (radius 36, 1 px rim) playing a 6 s looping capture of that skin's Home (WebM/AV1 on the web, MP4/H.264 on mobile, recorded by the screenshot harness; about 400 KB each), muted, paused under Reduce Motion (poster frame instead).
- Under each: the name (`title2`: "Glass", "Cinematic"), its character line (`subhead`: Glass "Depth, light and glass. Calm, spatial, Apple-like." / Cinematic "Dark, bold, cinematic. Posters and title cards."), and a chip "In use" on Glass.
- Tapping the Cinematic card (or swiping it forward on phones) brings it to the front on `spring.lift` and raises the confirm.

**Confirm (Veil).** Title "Restart in Cinematic?" Body "The whole app changes. You'll come back to this screen." plus, when downloads are queued, "Downloads pause for a moment and resume after the restart." Actions: primary "Restart in Cinematic" (haptic heavy), secondary "Stay in Glass".

**Outgoing animation (leaving Glass).** "Recede into the abyss": every layer (horizon, deck, planes, glass) scales toward 0.82 around the screen centre, blurs to 40 px and dims to 0 on `spring.surface` (800 ms), while the neutral MM column mark (§7.3) materializes at the centre at full brightness, the last thing on screen. Then: `PATCH /profiles/{id} {skin}` (queued through the offline outbox on mobile), the device mirror is written (cookie `mm-skin` / SharedPreferences `mm.skin.active`), the return route is saved, the service worker is told `skin-changed` (web), and the app restarts (`location.replace` / `AppRestart.restart()`), into Cinematic's own splash. Budget: under 1.5 s from confirm to the next splash.

**Incoming animation (arriving in Glass from Cinematic).** The neutral mark on black is picked up by the Glass "Strata assembly" reveal (§7.4, full cold-start length even on a warm restart, because this is the moment where everything changes), then the app lands on the saved return route (Settings → Skin, with Glass now "In use") and a toast "Switched to Glass" + "Undo" stays for 10 s. Undo runs the same flow back without a confirm.

**Other entry points.** The command palette "Switch to Cinematic" (same confirm). A profile whose saved skin differs from the device mirror switches inside the profile-arrival transition with no confirm and no undo (§4.5).

**States.** Saving ("Restarting" + orbit on the confirm), offline (the switch applies on this device now; the profile update syncs later; a note in the confirm: "You're offline. This profile will switch on your other devices when you're back online."), error before restart ("Couldn't switch skins. Try again." toast; nothing changes).

#### 4.25.2 Reading

Grouped lists:

- **Manga and manhwa**: Layout (Strip · Single · Double), Direction (Left to right · Right to left), Fit (Width · Height · Screen · Original), Between chapters (Seamless · Card), Page gap, Cinema mode, Tap zones (the same three-row control as the reader, with Reset and "Tap to scroll"), Keep screen awake, Auto next chapter, Lock controls, Volume keys turn pages (Android), Refresh rate (Android: Auto · 60 · 90 · 120 Hz; "Auto uses the highest rate your screen supports"), Page-tinted controls, "Reset reader settings" (Veil confirm "Reset reader settings? Every reader preference goes back to its default." → toast "Reader settings reset").
- **Novels**: Reading mode (Pages · Scroll), Page turn (Lift · Slide · Fade), Default paper (seven orbs), Default face, Speaker colours.
- **Text**: Legible text (switch: Atkinson Hyperlegible Next for the whole UI), App language (English, Español, Français, Deutsch, 日本語, 한국어; it sets date, time and number formats through `Intl`).

#### 4.25.3 Feedback

Haptics switch ("Taps and ticks you can feel", iOS and Android only; hidden on web desktop; on Android web: "Vibration on supported browsers"); Interface sounds switch (off by default) + a volume slider + a "Play sample" button that plays the push-pop phrase; Solid glass switch ("Makes glass surfaces solid. Also follows your system's Reduce Transparency."); a read-only row "Motion: follows your system's Reduce Motion setting" with a link to the OS setting on mobile.

#### 4.25.4 Content and privacy

- **Mature content (18+)** switch for the active profile with the hold-to-confirm flow (§3.25). Load error: notice "Couldn't load this setting" + Retry. No profile: disabled with the helper.
- **Circle**: the sharing controls (§5.3.7).
- **AI**: "AI picks on Home" switch; "Previously on recaps": Off · Ask · Always (after a break of 7 days or more); "Clear 'Not interested'" (restores dismissed recommendations); a read-only line with today's remaining AI asks ("18 of 60 left today").

#### 4.25.5 Account and security

- Account header: 44 px initial disc, display name, "@username", Administrator chip.
- **Change password**: three password fields (current, new "At least 8 characters", confirm), inline validation ("Enter your current password", "Use at least 8 characters", "Passwords don't match", "Choose a password different from your current one"), primary "Change password"; success toast "Password changed. Your other devices were signed out."
- **Where you're signed in**: rows per session (device glyph `DeviceMobile`/`Laptop`/`Desktop`, parsed name "Chrome on macOS" / "ManhwaManiacs app", "This device" chip, "Last used 3 h ago · 10.0.0.2", "Signed in 12 Sep · expires 11 Dec"), trailing "Sign out" (this device: Veil confirm then back to login) or "Revoke" (danger, Undo not possible: Veil confirm "Sign out {device}?"); refresh button; states loading / error / "No other sessions".
- **Sign out everywhere**: danger section with hold-to-confirm "Hold to sign out everywhere" (1200 ms); downloads stay on this device (stated in the helper).

#### 4.25.6 Notifications and checks

Admin: a schedule strip of three tiles (Last check "12 min ago", Next check "in 48 min" or warning "Overdue by 12 min", Interval "60 min"); switches "Check for new chapters automatically", "Check when the server starts", "Notify about new chapters"; a slider "Check every" 5–120 min step 5 (live `mono.meta` value); primary "Save" (draft-then-save; "Saved" toast). Non-admins see the same strip read-only with "Only the server owner can change these."

#### 4.25.7 Members (admin)

A grouped list (phone) or table (desktop, columns Member, Status, Joined, Last seen, Sessions, Actions; horizontal scroll under 720 px): username + "Admin" / "You" chips, "Active" / "Deactivated" status chip, joined date, last seen, session count; actions "Deactivate" / "Reactivate" (secondary S; immediate with toast; deactivation signs them out everywhere) and "Delete" (danger → Veil confirm with a typed-username field: "Delete @{user}? Their profiles, library, progress, bookmarks and everything else are removed. This can't be undone."). Your own row's actions are disabled with the reason. Footer "{n} other accounts" + refresh.

#### 4.25.8 Backup and restore (admin)

- **Nightly backup** status tile: "Last nightly backup: today 03:10 · 84 MB" (success) or "Unknown" (warning; never shown as healthy).
- **Restore pending** banner (warning) when staged: "A restore is staged and applies when the server restarts." + "Cancel restore".
- **Export**: explainer ("A copy of the whole server database, every account included. Keep it private.") + primary "Export backup" (web: file download; mobile: opens the export URL in the system browser) + "Preparing" state + result "Saved {filename}".
- **Restore**: danger-toned card, "Choose backup file" (system picker, `.db`), the chosen file "{name} · {size}", validation errors ("That isn't a .db file", "That file is empty"), danger "Restore from this file" → Veil confirm with the typed phrase "RESTORE" (§3.11) listing what happens (replaces every account, sign-ins come from the backup, applies on restart, nothing current is kept) → uploading → staged confirmation alert "Restore staged. Restart the server to finish."

#### 4.25.9 Server (mobile)

Field "Server address" (current URL), primary "Save" (validates with the health check; toast "Connected to {host}" or field error; https enforced in release builds), secondary "Use default", and a status line with the server name and version from the health check.

#### 4.25.10 Keyboard (web)

The live shortcut registry grouped by scope (General, Navigation, Lists, Reader, Novel reader, Listen), rows with description + keycaps; the "Single-key shortcuts" switch; empty "No shortcuts here yet."

#### 4.25.11 Diagnostics

Mobile: Rendering (FPS, jank %, worst frame ms, average frame, build and raster times, samples; "Collecting frames: scroll something"), Display (Android: current refresh rate, supported modes, resolution; iOS: "Switchable display modes are Android-only"), Device (platform and OS, CPU cores, screen size and pixel ratio, app version, build mode), Image cache (live and cached images, memory), Glass engine (tier in use: liquid / frosted / solid, shader warm-up time). Web: Glass tier and why ("Chromium: liquid" / "Safari: frosted" / "Reduce transparency: solid"), service worker version, storage estimate, GPU renderer string where exposed.

#### 4.25.12 About

App card (MM mark, "ManhwaManiacs", "A reader for manga, manhwa, manhua and web novels", version and build), update card (Android APK: "Up to date · v{v}" / "Update available · v{a} → v{b}" + "Download update"; iOS SideStore: "Updates come from SideStore" + the source URL `mono.meta` + "Copy source URL" + "Builds are signed for 7 days"; web: service worker version + "Check for updates"), "What's new" row, "Open-source licences" row (a styled licence list plane: package name, version, licence, expandable text).

**Settings signature moment.** Settings **rows remember depth**: pushing a section keeps the section row visible as the strata edge, labelled by its colour-coded glyph, so a deep setting (Settings → Reading → Tap zones) shows three coloured edges above it.

**Settings keys (web).** `/` search, `↑/↓` sections, `Enter` open, `Esc` pop.

### 4.26 System status (admin)

**Layout.** Plane (desktop: 2-column grid of cards). `largeTitle` "System status" + `subhead` "Everything that can break quietly." Cluster: Refresh (orbit while refreshing).

1. **Summary banner**: the worst state's tint and glyph with a headline ("All systems healthy" / "2 problems need attention") and bullet list of problems.
2. **Server card**: state chip (Healthy / Warning / Down / Unknown with a dot), name, version (`mono.meta`), "Checked every 15 s".
3. **Update checker card**: last run (+ relative), next run estimate (+ relative), interval, failed runs (danger when > 0), server error block (`mono.meta` in a `slab.2` well), "Check now".
4. **Recent checks card**: up to 8 runs with status chips (completed / running / failed / other), trigger, counts, time, error block.
5. **Source health card**: per-source rows (state glyph, name, id `mono.meta`, "Demoted" warning chip, "Probed 4 min ago", message, expandable last error), sorted failing first; filter chips All · Failing · Demoted.
6. **Backup card**: nightly status (§4.25.8).

**Signature moment.** **Problems come forward**: healthy cards sit flat on the plane; any card in warning or down state lifts to L3 + 6 px with a 1 px rim in its semantic colour and a slow 3 s breathing glow, so trouble is literally in front.

**States.** Loading (card skeletons), partial errors per card, non-admin (floating object `ShieldCheck` "Administrators only" + "Back to Home"), offline.

**Keys.** `r` refresh, `c` check now.

### 4.27 Status screens

| Screen | Where | Layout and copy | Actions |
|---|---|---|---|
| **404** | any unknown path, inside the shell | floating object `Compass` "This place doesn't exist" / "It may have moved, or the series was removed from your library." + keycap hint "Press ⌘K to search everything" | "Go to Home" (primary), "Open library" |
| **Route error** | a plane that throws | floating object `WarningCircle` "Something broke here" / "Nothing was lost. Trying again usually fixes it." + a `mono.meta` chip "Ref {digest}"; unreachable variant `PlugsConnected` "Can't reach your server" / "It may be starting up, or the connection dropped. Your library is safe." | "Try again", "Go to Home" |
| **Root error** | the app shell fails | standalone document (no fonts, no providers): `#000`, the MM mark SVG inline, "ManhwaManiacs couldn't start" / "Reloading usually fixes it. If not, check the server or the running build." in `system-ui` | "Try again", "Reload the app" |
| **Offline fallback** | served by the service worker when navigation fails offline | standalone HTML with inline CSS using the Glass tokens (`#000`, Slate text, Glacier focus, a CSS-only frosted card with `backdrop-filter` over a static horizon gradient, `system-ui` fonts): the MM mark (72 px), a live status capsule "No connection" / "Back online" (warning / success dot, updated from `online`/`offline` events), title "This page needs the server", body "Chapters you downloaded are still on this device and open as usual.", note "Served from your device by the app." | "Try again", "Open downloads" |
| **Maintenance** | `503 db_busy` on a whole plane | floating object `Hourglass` "The server is busy" + a live countdown "Retrying in {n} s" | "Retry now" |
| **Reader landing** | `/read` | §4.14.10 | |

### 4.28 Global overlays and shared pieces

| Overlay | Level | Spec |
|---|---|---|
| Command palette | L6 | §3.28 |
| Shortcuts sheet (`?`) | L6 | A large sheet / 640 px panel: "Keyboard shortcuts", intro "Only what works here is listed. Shortcuts pause while you type.", groups with keycap rows, "Nothing here has shortcuts." empty state; `Esc` closes |
| New-chapters banner | L5 | A Float capsule above the dock (phone) / bottom-centre (desktop): `BellRinging` + "**4 new chapters** across 3 series" + plain "View" + `X`. Appears when unread notifications newer than the last dismissed one exist; hidden in Updates and rooms; dismissal is remembered for the session until a newer notification arrives |
| Service-worker update (web) | L5 | Float capsule "A new version is ready" + "Reload"; reload posts `skip-waiting` and reloads |
| Android update | L5 / sheet | The You-sheet banner and the About card; "Download update" opens the APK download, then a sheet "Install the update" with three numbered steps (Open the downloaded file · Allow installs from this source if asked · Tap Install) and "Got it" |
| What's new | L6 | Shown once after an update and from the You sheet: large sheet "What's new" + release cards (`slab.1`: version capsule in Iris tint, "Latest" chip on the first, date · build, bullet highlights); states loading / "Release notes aren't available right now" |
| First-run hint | L3 | Profiles with no follows and onboarding skipped: an inline card at the top of Home, Search idle and Updates: `Compass` "Nothing followed yet. Browse a source and follow a series to start your library." + "Browse sources" |
| Series context menu | L6 | §3.23 |
| Profile quick switch | L6 | §4.24 |
| Undo toasts | L8 | §3.12; used by unfollow, remove bookmark, remove download, remove from collection, bulk actions, remove saved audio, skin switch |
| "Further on another device" | L8 | Toast "You're further on another device: CH 145 p. 3" + "Jump" (from `advanced: false` progress responses) |
| Offline HUD | L8 | §3.24 |
| Skip link (web) | L8 | "Skip to content" capsule at top-left, visible on focus only, jumps to the plane's large title |
| Reader notices | L8 | Bookmark saved / failed, stale anchor, "Back to where you were" chip |
| Sync notice | L8 | After an offline period: "Synced 12 reads and 2 bookmarks" toast (from outbox flush results) |

### 4.29 Coverage map

Every screen in both inventories and where Strata specifies it.

**Web routes.**

| Inventory screen | Strata |
|---|---|
| R0 `/` redirect | Home is `/` (4.8) |
| R1 Login, R2 Register | 4.3, 4.4 |
| R3 Profile picker, profile form dialog, R4 Manage profiles | 4.5, 4.6 |
| R5 Library, R6 Browse all | 4.17 (one bay; browse is the filtered view) |
| R7 Followed series detail, R17 Source series detail | 4.12 (one series plane for both routes) |
| R8 Collections, R9 Collection detail | 4.18 |
| R10 History | 4.19 |
| R11 Bookmarks | 4.20 |
| R12 Find something to read | 5.1.3 (For you) |
| R13 Reading statistics | 5.2 |
| R14 Search | 4.9 |
| R15 Sources, R16 Source catalogue | 4.10, 4.11 |
| R17n Book page | 4.13 |
| R18 Reader landing | 4.14.10 |
| R19 Manga reader, R20 Read all | 4.14 |
| R21 Novel reader | 4.15, 4.16 |
| R22 Updates | 4.21 |
| R23 Downloads | 4.22 |
| R24 OCR search | 4.23 |
| R25 More | 4.24 (You) |
| R26 Settings (Design → Skin, Appearance → removed by decision, Reader, Notifications, Content, Security, Shortcuts, Backup, Members) | 4.25.1–4.25.10 |
| R27 System status | 4.26 |
| E1 404, E2 route error, E3 root error, E4 offline fallback | 4.27 |
| Command palette, shortcuts dialog, new-chapters banner, update prompt, first-run banner, bookmark notice, account menu (sign out, account header) | 3.28, 4.28, 4.24, 4.25.5 |
| Sidebar, topbar, profile chip, bottom tabs, content-mode switch, notification bell | 3.16, 3.14, 4.24, 3.15, 3.34, 3.15 (Updates bay badge) |

**Mobile screens.**

| Inventory screen | Strata |
|---|---|
| S01 Setup, S02 Splash | 4.1, 4.2 |
| S03 Login, S04 Register | 4.3, 4.4 |
| S05 Profile picker, S06/S07 Add/Edit profile | 4.5, 4.6 |
| S08 Library home | 4.8 (Home) and 4.17 (Library) |
| S09 Library browse, S10 Series detail (library) | 4.17, 4.12 |
| S11 Recommendations | 5.1.3 |
| S12 Statistics | 5.2 |
| S13 Reading history, S14 Bookmarks | 4.19, 4.20 |
| S15 Manga reader, S19 Source reader | 4.14 |
| S16 Sources, S17 Source browser, S18 Source series detail (manga and novel bodies) | 4.10, 4.11, 4.12, 4.13 |
| S20 Search | 4.9 |
| S21 Downloads (Chapters, Storage) | 4.22 |
| S22 More | 4.24 |
| S23 Updates | 4.21 |
| S24 Collections, S25 Collection detail | 4.18 |
| S26 Novel reader + N1 Type, N2 Contents, N3 Audiobook picker, N4 Voices | 4.15, 4.15.4, 4.15.5, 4.13, 4.16.3–4.16.4 |
| S27 Dialogue search | 4.23 |
| S28 Settings (General, Server, About, Debug; settings search) | 4.25 |
| S29 Password and security, S30 Members | 4.25.5, 4.25.7 |
| S31 Theme gallery | replaced by the Skin picker 4.25.1 (palettes removed by decision) |
| S32 Storage, S33 Backup, S34 Diagnostics | 4.22, 4.25.8, 4.25.11 |
| M1 Series actions sheet | 3.23 context menu |
| M2 Chapter selection bar | 4.12 download picker |
| M3 Reading mode sheet | 3.34 |
| M4 What's new, M5 Save to Files | 4.28, 4.22 |
| M6 Reader settings | 4.14.6 |
| M8 Collection dialogs, M9 confirmations | 4.18, 3.11 |
| G1 Bottom navigation, G2 Mood backdrop, G3 Profile switcher, G4 18+ gate, G5 Reading mode, G6 Auth, G7 Setup, G8 What's new, G9 App update, G10 lifecycle states, G11 system UI, G12 haptics | 3.15, 2.1.6 + 2.1.9, 4.24, 3.25, 3.34, 4.2–4.4, 4.1, 4.28, 4.28 + 4.25.12, 4.22 + 4.0.6, 4.14.12, 2.10 |

**New screens (§5):** Home AI rails, For you, More like this, Previously on (5.1); Stats, streak, Wrapped, share cards (5.2); Circle, friend plane, reactions, shared collections, recommend-to, inbox, sharing settings (5.3); auto-scroll, soundscapes, guided view, page-tinted chrome (5.4); onboarding (4.7); You (4.24).

---
## 5. The four new features

All four are designed server-first (stack-decision §2.6): the backend computes and gates, both clients render. Each feature lists its entry points, screens, states and the endpoints the screens are drawn against (existing ones by name; proposed ones marked **new**).

### 5.1 AI home, recommendations and "Previously on"

#### 5.1.1 What the AI touches, and what it never does

- The AI is an external API called by the server (owner decision). The clients never talk to it.
- It **ranks and explains** (rails, `why` lines), **answers prompts** (the For you ask box), and **summarises what you already read** (recaps). It never invents series: every card is a real series from AniList-verified data or the server's catalogue.
- Everything is per profile and 18+-gated server-side; a closed gate means mature items are simply absent.
- Every AI-produced line carries the `Sparkle` badge (§3.20). Non-AI algorithmic rails (world recommendations, recently updated) carry no badge.

Endpoints: `GET /library/world/recommendations`, `GET /library/suggest/availability`, `POST /library/world/suggest`, `POST /library/suggest`, `GET /library/recommendations` (genre affinity), `GET /library/continue-reading`, `GET /library/recently-updated`, plus **new** `GET /home` (ordered sections `{type, title, why?, items[], state}` with `state: ready | loading | empty | unavailable`), **new** `GET /series/similar?source=&series=` (items + `why`), **new** `POST /recommendations/feedback {anilist_id | source_id+series_key, signal: "not_interested" | "clear"}`, **new** `POST /recaps {scope: "series" | "chapter", source_id, series_key, chapter_key?}` → `{state: ready | generating | unavailable, reason?, sections: [{kind, title, text}], characters?: [{name, note}], covered_through: chapter_number, generated_at}`.

#### 5.1.2 AI rails on Home

Home (§4.8) composes rails from `GET /home`; when that endpoint is unreachable the client composes the same rails from the individual endpoints.

| Rail | Content | `why` subline | Card |
|---|---|---|---|
| **For you** | world recommendations ranked by the AI against the profile's history | "Picked from what you read this month" | world card (available / info) |
| **Because you read {title}** (up to 3) | seeded by recent favourites and completions | per card: one line ≤ 160 characters ("Same regression setup, slower romance") | world card |
| **Almost done** | continue items with ≤ 3 chapters left | "2 chapters left" per card | deck card |
| **New since you caught up** | followed series with new chapters after a caught-up state | "3 new since 12 Sep" | poster with "NEW" |
| **More like {current read}** | similar series to the most-read series this week | "Like *{title}*: {reason}" | world card |
| **Your genres** | chips from genre affinity | n/a | chips |

**"Not interested."** Long press a card → "Not interested", or on phones flick the card **upward** past 60 px: the card sinks into the abyss (scale 0.8, brightness → 0) instead of flying off, the rail closes the gap, and a toast reads "Fewer like this" + "Undo". Settings → Content and privacy → AI → "Clear 'Not interested'" resets it.

**Loading.** Rails load independently: a rail header with a small orbit next to its title and five skeleton cards with the depth shimmer. AI rails can take several seconds on a cold server; they never block the rest of Home.

#### 5.1.3 For you (the ask plane)

**Entry points.** You sheet → For you; sidebar "For you"; Home rail headers ("See all" on For you); command palette ("Ask for a recommendation"); the Home Stage `DotsThree` → "Something else like this". Route `/for-you`.

**Layout (phone).** Plane with a Glacier/Iris horizon. `largeTitle` "For you" + `subhead` by availability: "Describe what you feel like. Picks are weighed against what you've read." / "You've used today's AI asks. They reset at midnight UTC; the picks below still work." / "Picks from everything out there, based on what you read."

1. **The ask box**: a textarea (`slab.3`, radius 20, 3 lines, 600 characters) with placeholder "A revenge story with a competent lead, no harem" and three suggestion chips under it ("A murim regressor who comes back stronger", "Magic academy, but the lead is already strong", "Something slow and political, not a power fantasy"; tapping one fills and submits). Primary capsule "Suggest" (the plane's tint; enables at 3 characters). A quota line `caption1` `label.3`: "18 of 60 asks left today" (shown when ≤ 10 remain, in warning at ≤ 3).
2. **Answer area** (appears on submit): see the signature moment.
3. **For you** section (grid of world cards, 2 columns phone / 4–6 desktop).
4. **Because you read {title}** sections, one per seed.

**Signature moment: the answer rises from depth.** While thinking, the ask box stays and under it a **thinking orbit** appears: three dots orbiting on a tilted ellipse at different depths (the near dot bright and large, the far one dim), plus a status line that steps through honest phases as the server reports them (or on timers when it cannot): "Reading your library" (0 s) → "Asking for ideas" (1.5 s) → "Checking which of your sources have them" (4 s) → "Still working. This can take up to a minute." (15 s). When results arrive, the orbit dissolves and result cards rise one by one from behind the plane (scale 0.9 → 1, brightness 0.3 → 1, 80 ms apart) into a vertical list of **answer cards**: wide cards (poster 96 × 144 left; right: title, meta, the AI `why` in `callout` with the `Sparkle` badge, availability chip, actions Open / Search my sources / Read on {site}). A "Show as grid" plain button switches to posters.

**States.**

| State | UI |
|---|---|
| Available, idle | ask box + chips + sections |
| Thinking | orbit + phase line; the Suggest button shows "Thinking" and disables; the rest of the plane stays usable |
| Results | answer cards (up to 12) + "Ask again" (secondary) |
| No matches (`ai_no_matches`) | inline notice "Nothing matched that. Try describing it differently." |
| Empty shelf (`suggest_shelf_empty`) | "Follow or read a few series first. Picks start from what you read." + "Browse sources" |
| Budget exhausted | the ask box is replaced by a quiet notice "You've used today's asks. They reset at midnight UTC." with a live countdown; sections remain |
| Not configured | no ask box; notice "AI asks aren't set up on this server." (admins see "Add an AI API key on the server to enable asks."); sections remain |
| Rate limited | notice "Too many asks in a row. Try again in {n} s." with countdown |
| World catalogue unreachable (`unavailable_reason`) | notice "The worldwide catalogue isn't reachable, so these picks come from a saved copy." |
| Offline | floating object "For you needs a connection" |
| Error | inline "That didn't work. Try again." + Retry |
| Loading sections | skeleton grid of 6 |

**Desktop.** Front pane: the ask box across the top (max 720 px), answers in a two-column list, sections as grids.

**Keys.** `/` focus the ask box, `Enter` submit, `Shift Enter` newline, `Alt 1`–`Alt 3` fill an example, `j`/`k` through answers.

#### 5.1.4 More like this (series plane)

A rail at the end of every series and book plane (§4.12 item 10) and on the caught-up card (§4.14.5): up to 10 world cards from **new** `GET /series/similar`, each with a `why` line. Loading: rail skeleton. Empty or unavailable: the rail is omitted (no empty rail). AI unavailable: the rail falls back to genre matches from the same source without `why` lines and without the `Sparkle` badge.

#### 5.1.5 "Previously on" recaps

**When it appears.** The setting "Previously on recaps" (Off · **Ask** (default) · Always):

- **Series recap:** before continuing a series you haven't read for **7 days or more**. With Ask, Continue shows a one-line prompt on the series plane and on continue cards: "Previously on · 30-second recap" (the recap card, §4.12 item 5). With Always, pressing Continue opens the recap plane first.
- **Chapter recap:** when opening the next chapter after **3 days or more** away, the room shows a glass pill at the top-centre, "Previously · 20 s", for 6 s; tapping it opens the compact recap sheet.
- Long press any Continue button → "Recap first" (always available).

**The recap plane.** Rises between the series plane and the room (depth + 1, with the series plane in the deck and the room waiting behind the Continue button). Horizon from the series palette.

- Header: `caption1` +0.18 em `label.2` "PREVIOUSLY ON" and the series title in `title1` with the letter reveal.
- **The recap deck**: 3–5 cards stacked in depth (the front card 88 % width, radius 28, `slab.1`; the next two visible above it at deck geometry), each one section: **Where you left off** (chapter and page, 2–3 sentences), **What happened** (4–6 bullet sentences), **Who's who** (up to 6 characters with a one-line note; for novels drawn from the attribution cast, each with their speaker swatch), **Open threads** (2–3 questions the story has raised). Swipe up (or tap the right half) lifts the front card off the deck toward you and away (`spring.lift` reversed upward), revealing the next; swipe down brings it back. Progress: 3–5 small capsules at the top.
- Spoiler guard: the footer line `caption1` `label.3` "Covers up to chapter {n}. Nothing after where you stopped." (`covered_through`).
- Actions (sticky footer): primary "Continue reading · CH 142" (dives into the room from the deck), secondary "Skip", plain "Don't recap this series" (per series).

**Compact recap sheet** (chapter recap in the room): medium detent, one card "Last time" (3–4 sentences) + "Continue".

**Streaming.** The recap text streams from the server; words fade in (opacity 0 → 1 over 120 ms per word, no movement) as they arrive; the deck appears with skeleton lines that fill from the top. (The 50 ms typing reveal is reserved for headlines, §6.2.)

**States.**

| State | UI |
|---|---|
| Generating | deck with skeleton lines + the thinking orbit + "Writing your recap" |
| Ready (cached) | instant deck; `caption1` "Written {time} ago" |
| Needs dialogue (manga with too few scanned chapters) | floating object `recap` "Recaps need the dialogue text" / "Scan a few recent chapters on your phone (On this device → Scan text) and recaps become available." + "Continue anyway" |
| Not enough read | "Read a couple of chapters first; there's nothing to recap yet." + Continue |
| AI not configured / budget exhausted | notice with the reason + Continue (the recap is skipped) |
| Offline | cached recap if one exists, else "Recaps need a connection" + Continue |
| Error | "Couldn't write a recap." + Retry + Continue |

**Keys.** `Space`/`→` next card, `←` previous, `Enter` continue reading, `s` skip.

#### 5.1.6 The thinking orbit (AI loading, everywhere)

A 28 px (inline) or 64 px (plane) glyph: three dots (4 / 3 / 2 px at 64 px scale ×2) on a tilted ellipse (rx 24, ry 9, tilt 12°), 1400 ms per revolution, the near dot at 1.0 brightness and 1.2 scale, the far dot at 0.4 and 0.8; the ellipse itself is a 0.5 px `rgba(255,255,255,0.12)` stroke. Colour Iris. Reduced motion: the three dots pulse in sequence in place.

#### 5.1.7 AI unavailable copy (one voice everywhere)

| Reason | Short (rail notice, badge tooltip) | Long (For you, recap) |
|---|---|---|
| `not_configured` | "AI picks are off on this server" | "AI isn't set up on this server. Everything else works as usual." |
| `budget_exhausted` | "Today's AI asks are used up" | "You've used today's AI asks. They reset at midnight UTC." |
| `rate_limited` | "AI is busy, retrying in {n} s" | "Too many requests in a row. Trying again in {n} s." |
| offline | "AI picks need a connection" | "You're offline. AI picks come back when you reconnect." |
| upstream error | "AI picks didn't load" | "The AI service didn't answer. Try again in a moment." |

### 5.2 Reading stats, streaks and the Wrapped recap

Endpoints: `GET /library/statistics?days=&tz_offset_minutes=` (daily, by-hour, by-source, by-series, sessions, streak, totals; `days=365` for the year), `GET /library/recommendations` (genre weights for the radar), plus **new** `GET /stats/wrapped?year=` (server-computed yearly aggregates: totals, top series, top genres, busiest day, longest streak, night-owl share, first and last reads, per-month chapters) and **new** `PUT /profiles/{id}` field `daily_goal_minutes` (5 · 10 · 15 · 30 · 60, default 10).

#### 5.2.1 The Stats plane

**Entry points.** You sheet tile "Stats", the You orb's streak ring (tap the ring area on the You sheet), sidebar "Stats", `g t`, the Home greeting's streak line.

**Layout (phone).** Plane. `largeTitle` "Stats" + range segmented control **7 d · 30 d · 90 d · Year**. Scope note (when novels are enabled) `caption1` `label.3`: "Streak and totals count everything; the breakdowns show {Manga | Novels} only."

1. **Hero**: the streak flame (96 px, §5.2.3) left; right: "12-day streak" `title2`, "Best 31 days" `subhead`, today's goal ring (44 px) "8 of 10 min today".
2. **Totals** (2 × 2 stat tiles): Time read ("14 h 20 m"), Chapters ("212"), Pages ("6,840"), Series ("18"); each with the all-time line ("312 h all time") and a delta against the previous window.
3. **Chapters per day**: a bar chart (height 160) of the window; bars Iris with rounded tops (radius 3, width `min(16, available / n − 3)`), empty days as 2 px `fill.2` stubs, a dashed line for minutes read on a second axis (Glacier 1.5 px), axis labels `caption2` `label.3`. Tap a bar → the readout line above the chart: "Mon 21 Sep · 12 chapters · 48 min · 3 series" (selection haptic); tapping again clears.
4. **Year heatmap** (Year range, and as a collapsed card otherwise): a 53 × 7 grid of 10 px cells, 2 px gaps, 5 levels (`#15131F`, `#2A2550`, `#463C8F`, `#6A5BD6`, `#A99BFF`) by pages read; month labels `caption2`; today outlined 1 px Glacier; tap a cell → readout.
5. **Reading clock**: a 24-hour radial dial (200 px): 24 wedges from the centre whose length is the share of reading in that hour (Iris), midnight at the top, labels 0 / 6 / 12 / 18; centre text "Night owl" / "Early bird" / "Lunch reader" / "Evening reader" (the peak band) and "Most at 23:00".
6. **Genre radar**: 6–8 axes (top genres by weight), a filled polygon Iris at 24 % with a 1.5 px Iris outline and dots at the vertices; labels `caption1`. Tap a label → For you filtered by that genre.
7. **Top series**: ranked rows (cover 44 × 66, title, "42 chapters · 6 h 10 m", "Last read 2 d ago"), tap → series plane.
8. **Where you read**: source rows with share bars (Iris ramp by rank).
9. **Recent sessions**: rows "Chapter 12 · *{title}* · 40 pages · 12 min · 2 h ago", tap → reader at that chapter.
10. **Your library**: followed, favourites, chapters finished, and per-status rows with bars in status colours.
11. **Wrapped entry**: from 1 December (and "Your year so far" after 30 days of history): a tall `slab.1` card with the year set in `display` and a fanned preview of three Wrapped cards; tap → Wrapped (§5.2.4).
12. Footnote: "Days start at UTC+05:30 · Sessions count up to 30 min of idle · Recording since 27 Jul 2026".

Each chart has a "Show as table" plain button (accessible data table with the same numbers) and keyboard focus per bar/cell with arrow keys and a live readout.

**Layout (desktop).** Front pane, a 12-column grid: hero + totals across the top, chapters per day (8 columns) + reading clock (4), heatmap full width, radar (4) + top series (8), sources + sessions (6 + 6), library shape, Wrapped card.

**Signature moment.** **Numbers rise from depth**: switching ranges re-draws the bars rising from behind the plane (scale-y from 0 with brightness from 0.3, 12 ms per bar left to right), and the totals roll their numbers.

**States.** Loading (hero skeleton, 4 tile skeletons, chart skeleton 160 px, two panel skeletons), empty ("No reading recorded yet. Stats fill in as you read." + "Go to Home"), followed but never read ("Nothing read on this profile yet" + the library shape card), offline (the last cached stats, dimmed, "Last updated {time}"), error ("Couldn't load stats" + Retry).

**Keys.** `[` / `]` previous / next range, arrows through the focused chart, `t` toggle table view, `w` open Wrapped.

#### 5.2.2 Chart colour and type rules

Series colours come from the Iris ramp (`#463C8F`, `#6A5BD6`, `#A99BFF`, `#D4CCFF`) with Glacier as the only second-axis colour; semantic colours only for status breakdowns. Labels `caption2` `label.3`, values `mono.meta`. Tooltips are HUD capsules (L8). No gridlines except a baseline and quarter lines at `rgba(255,255,255,0.06)`.

#### 5.2.3 The streak flame

- **Glyph**: a flame drawn as three nested teardrop layers in depth (back `#FF6B4A` at 0.6 scale 1.0, middle `#FFB35C` scale 0.78, front core `#FFF1D6` scale 0.46), each a glass-like layer with its own parallax (0.10 / 0.20 / 0.30 with the gyro or pointer) and a flicker: each layer's top point sways ±4 % on independent sine loops (1.3 s, 1.7 s, 2.1 s).
- **States**: *alive, goal met today* (full colour, flicker on); *alive, not yet today* (colours at 0.55, no core, still flickering slowly); *at risk* (after 20:00 local with nothing read today: the flame shrinks to 0.8 and a `caption1` warning line "Read today to keep your 12-day streak"); *broken* (a grey `slate500` ember with a thin smoke line; "Start a new streak today"); *new record* (Bloom sparks, 6 particles rising 40 px over 900 ms, when current exceeds the longest).
- **Ignition** (goal met, or streak +1): the core grows from 0 on `spring.bouncy`, the three layers fan apart in depth and settle, 8 ember particles rise, AHAP `ignite`, sound `ignite`. It plays where you are when it happens (a HUD toast "12-day streak" carries a 32 px flame), and once on the You orb ring.
- **Where**: the You orb ring on every bay root (the ring fills with the flame gradient as the goal progresses), the You sheet, the Stats hero, the Home greeting line ("12-day streak").
- **Goal**: Stats `DotsThree` → "Daily goal" menu (5, 10, 15, 30, 60 min); stored on the profile.

#### 5.2.4 Wrapped

**Entry points.** Stats card (from 1 December, or "Your year so far" after 30 days of history), the You sheet row "Wrapped {year}", a one-time Home Stage spotlight in December ("Your {year} in pages"), `w` on Stats. Route `/stats/wrapped/:year`. Frame: Room (no dock).

**The deck.** Ten 9:16 cards shown in depth: the front card fills the screen minus 16 px margins (phone) or a 432 × 768 card centred (desktop), the next two visible behind it at deck geometry. Segmented progress capsules along the top (10 segments). Each card auto-advances after 6 s (hold to pause; the segment stops filling); tap right half or swipe up = next (the front card **lifts off toward you** and away); tap left half or swipe down = previous; `Esc`/close circle exits. Each card has its own horizon generated from its hero cover palette.

| # | Card | Content |
|---|---|---|
| 1 | Opener | "Your {year} in pages" typed at 50 ms per character (§6.2) in `display`, the profile orb, the year in `mono.figure` |
| 2 | Time | "You read for **312 hours**" (`mono.figure` rolling up), "That's 13 days straight." |
| 3 | Volume | chapters and pages as two big numbers; a mini bar of chapters per month |
| 4 | Top series | the #1 cover large (tilted 6° with parallax), #2–#5 fanned behind it in depth; "{title}: 212 chapters" |
| 5 | Genres | the genre radar drawn stroke by stroke, "Mostly **murim** and **regression**" |
| 6 | Clock | the reading clock; "You're a **night owl**: 58 % after 22:00" |
| 7 | Streak | the flame, "Longest streak: **31 days**", the dates |
| 8 | Busiest day | the date, "42 chapters in one day", the series of that day as small covers |
| 9 | Firsts and lasts | first series of the year, last one; "From *X* in January to *Y* now" |
| 10 | Summary | a composed poster: top 3 covers, totals, streak, genre words; the share card |

**Share.** Every card has a `Export` button (L5, bottom-right). Pressing it **flips the card** (rotateY 180° on `spring.smooth`, haptic rigid 0.5) to its share side: the same card composed for export (the MM mark and "ManhwaManiacs · {year}" at the foot, no UI chrome), with two size tabs **Story 1080 × 1920** and **Post 1080 × 1350**, and buttons "Share", "Save image" (mobile) / "Download" (web), "Copy image" (web, `navigator.clipboard.write` with a PNG). Flip back with the close glyph or by tapping the card.

**Privacy.** Share cards never show a mature (18+) series' cover or title; the next eligible series takes its place. The Circle never sees Wrapped unless shared by the reader.

**Keys (web).** `→` / `Space` next card, `←` previous, `k` pause or resume auto-advance, `e` export (flip), `1` / `2` story or post size on the share side, `Esc` flip back, then close.

**States.** Generating ("Putting your year together" with the thinking orbit over a skeleton card), not enough data ("Read a little more and your recap will be ready."), offline (the last generated Wrapped from cache, or "Wrapped needs a connection"), export in progress (the Share button shows an orbit), export failed ("Couldn't make the image. Try again."), shared/saved (toast "Saved to Photos" / "Image downloaded").

#### 5.2.5 Share-card rendering

- **Web:** each card's share side is drawn with Canvas 2D at 1080 × 1920 (or 1350): fonts loaded with `document.fonts.load('600 64px "Google Sans Flex"')`, covers from the same-origin API proxy (no taint), shapes drawn with `roundRect`, the horizon as two radial gradients; `canvas.toBlob('image/png')`; `navigator.share({ files: [file] })` when `navigator.canShare({ files })` is true, otherwise a download link (`URL.createObjectURL`). No library.
- **Flutter:** the share side is a widget rendered off-screen inside a `RepaintBoundary` at 360 × 640 logical px; `toImage(pixelRatio: 3)` gives 1080 × 1920 (post: 360 × 450 → 1080 × 1350); PNG bytes go to a small **`mm/share`** method channel (iOS: `UIActivityViewController` with the PNG file; Android: `Intent.ACTION_SEND` through the app's `FileProvider`), and "Save image" uses the same channel (iOS: `PHPhotoLibrary` add-only permission, `NSPhotoLibraryAddUsageDescription` "Save your reading recap images"; Android 10+: `MediaStore.Images` insert, no permission).

### 5.3 Social for 2–3 users: the Circle

#### 5.3.1 Model and privacy

- **The Circle** is everyone else on this server: the other accounts' profiles. Each profile is a separate person in it ("Aya · Night reads").
- **Opt-in per profile, off by default.** Settings → Content and privacy → Circle: "Share my activity" (off), "Share what I'm reading" (off; the Continue list), "Accept recommendations" (on), "Show me in presence" (off: "reading now" dots), "Share 18+ activity" (off; only offered when this profile's gate is open).
- **The 18+ rule.** A mature item from someone's activity, collection or recommendation is shown only when (a) the sharer allowed 18+ sharing, and (b) the viewing profile's gate is open. Otherwise the item is absent: no placeholder, no count, no "hidden" row.
- **Per-series hiding.** A series plane's `DotsThree` → "Hide from my Circle" excludes it from everything shared.
- Nothing is shared retroactively when a switch is turned on: sharing starts from that moment.

Endpoints (**new**): `GET /social/circle` (members `{account_id, profile_id, name, avatar_key, mood, presence: reading|active_today|away, reading_now?}`), `GET/PUT /social/sharing` (the switches above), `GET /social/activity?before=&limit=` (events `{id, actor, kind: started|read_chapters|finished|followed|reacted|added_to_collection|recommended, series, chapter_range?, reaction?, collection?, at}`), `GET /social/profiles/{account}/{profile}` (their shared reading, collections), `POST /social/reactions {source_id, series_key, chapter_key, kind}` / `DELETE /social/reactions/{id}` / `GET /social/reactions?source=&series=&chapter=`, `POST /social/recommendations {to: [{account_id, profile_id}], source_id, series_key, note?}`, `GET /social/recommendations?box=inbox|sent`, `PATCH /social/recommendations/{id} {state: seen|followed|dismissed}`, `PATCH /library/collections/{id} {shared, collaborative}`, `GET /social/collections`, `PUT /social/hidden-series`. All gated server-side by the rules above.

#### 5.3.2 The Circle plane

**Entry points.** You sheet tile "Circle", sidebar "Circle", `g c`, Home "From your circle" rail header, the Updates bay's Circle segment, friend orbs anywhere.

**Layout (phone).** Plane with a Bloom-tinted horizon. `largeTitle` "Circle". Top: **presence orbs**: each member's 56 px orb on a shallow arc, nearer (larger, brighter) when more recently active; ring: Glacier live dot + ring when reading now, Bloom ring when active today, none when away; name under it; "Reading *{title}*" under the name when shared. Segmented control: **Activity** · **For you** · **Collections**.

- **Activity**: activity cards (§3.7) grouped by day (sticky day headers). Consecutive chapter reads collapse into one card ("Aya read chapters 140–152 of *{title}*"). Each card: tap the series → series plane; tap the orb → friend plane; the reaction row lets you add your reaction to that chapter too.
- **For you**: recommendations sent to you (inbox): cards with the sender's orb, the note in `callout` quotes, the series (world or source card), actions "Follow" (primary S) / "Not now"; states seen/followed. A "Sent" filter chip shows what you recommended and whether it was followed.
- **Collections**: shared collections from others (stacks with owner chips) and yours that you share.

**Layout (desktop).** Front pane: presence arc across the top, Activity as the main column, For you and Collections as a right column (≥ 1280 px).

**Signature moment.** **Presence has depth**: orbs of people reading right now drift forward to the front of the arc and breathe with a Glacier ring; as their activity ages they drift back into the arc. Opening a friend makes their orb fly to the friend plane's header.

**States.** Nothing shared yet (the default: floating object `UsersThree` "Your Circle is quiet" / "When people on this server share their reading, it shows up here. Your sharing is off." + "Sharing settings"), only you on the server ("There's nobody else on this server yet."), loading (orb skeletons + 3 card skeletons), offline ("The Circle needs a connection"), error.

**Keys.** `[`/`]` tabs, `↑/↓` cards, `r` react to the focused card's chapter.

#### 5.3.3 Friend plane

Header: the friend's orb (112 px, their mood ring), name, account; "Reading now: *{title}* · CH 142" when shared. Sections: **Reading** (their continue list as posters with their progress lines in Bloom), **Collections** (their shared collections), **Recent** (their activity). Actions: "Recommend something" (opens the recommend sheet with them preselected), per poster "Follow" quick action. Empty: "{name} isn't sharing their reading." States as the Circle plane.

#### 5.3.4 Reactions

Six reactions, drawn with Phosphor Fill glyphs (no emoji, so they match the skin): **Hype** `Fire`, **Love** `Heart`, **Wrecked** `SmileyMelting`, **Tears** `Drop`, **Twist** `Lightning`, **Masterpiece** `HandsClapping`.

- **Reaction bar**: a `slab.2` capsule (48 px) with the six glyphs (24 px, `label.2`); your chosen reaction is Fill Bloom with a Bloom tint behind it; counts from the Circle as `caption2` under each glyph; an orb stack of up to 3 people who reacted to the right ("Aya and Kai"). One reaction per person per chapter; tapping yours again removes it.
- **Where**: the chapter end (manga seam end card, the caught-up card, the novel end matter), chapter rows (a summary glyph + count), activity cards, the long-press page menu "React to this chapter".
- **Animation**: the chosen glyph **rises out of the bar through depth**: it scales 1 → 1.6 while moving up 48 px and toward the viewer (L3 → L6), leaving a Bloom trail of 5 particles, then shrinks back into its slot on `spring.bouncy`; AHAP `pop`; sound `react`.
- Long press a glyph: a popover listing who reacted with it.
- States: sending (glyph at 0.6 with orbit ring), failed (glyph shakes, toast "Couldn't send your reaction"), sharing off (the bar still works for yourself; a helper line "Only you see this. Turn on Circle sharing to show others.").

#### 5.3.5 Shared collections

In the collection sheet: "Share with your Circle" switch → "Friends can add series" (collaborative) switch. Shared stacks carry a Bloom person chip ("Shared" / "From Aya"). In a collaborative collection, posters added by someone else carry a 20 px orb of who added them at the bottom-left; removing someone else's addition asks "Remove {title}? Aya added it." Leaving a shared collection (someone else's): `DotsThree` → "Remove from my Circle collections". Mature members follow the 18+ rule per viewer.

#### 5.3.6 Recommend to

**Entry points.** Series plane `DotsThree` → "Recommend to…", the context menu on any poster, the friend plane, the reader's page menu (series-level), Wrapped card 4 ("Recommend {top series}").

**Sheet (medium).** Title "Recommend *{title}*"; the Circle's orbs (multi-select, `select.ring` + check; a member whose profile would not be allowed to see this series (18+) is shown disabled with "Not available to {name}" and cannot be selected; a member with "Accept recommendations" off is disabled with "{name} isn't taking recommendations"); a note field (140 characters, "Why they'll like it"); primary "Send". On send, the selected orbs **fly out of the sheet** along a curve toward the top edge (the Circle's direction), AHAP `thread`, toast "Sent to Aya".

**Receiving.** The Circle For you tab, a Home rail "From your circle" (sender orb on each card), and the Updates bay's Circle segment. New recommendations add a Bloom dot to the You orb.

#### 5.3.7 Sharing settings

Settings → Content and privacy → Circle (§4.25.4): the five switches of §5.3.1 with plain explanations, a "Hidden from my Circle" list (series you hid, each with "Unhide"), and "Clear my activity" (Veil confirm: "Remove everything you've shared so far? Your reading stays; your Circle just won't see past activity.").

#### 5.3.8 States summary

Default is quiet: with sharing off everywhere, the Circle plane shows the "quiet" object, Home omits the Circle row, the Updates Circle segment shows "Nothing from your Circle yet", and reaction bars show only your own reaction.

### 5.4 Ambient reader extras

#### 5.4.1 Auto-scroll (strip)

- **Control.** When auto-scroll starts (settings row, `p`, or the page menu), the room's accessory slot holds the **auto-scroll capsule** (L5, 52 px): play/pause (40 px), the speed readout "1.5×" (tap opens the speed dial, §3.21), and a thin progress line showing the chapter position.
- **Speed.** Base 60 px/s at 1×; the dial ranges 0.5×–3.0× (30–180 px/s) in 0.05 steps; `<` / `>` step by 0.25× with selection haptics; speed is stored per series.
- **Motion.** Starts and speed changes ramp over 400 ms (never lurch); the scroll is frame-delta based and clamps long frames to 1/60 s.
- **Interaction.** Any touch pauses it; it resumes 800 ms after the finger lifts (a small ring in the capsule counts down the resume). Scrolling manually adjusts position without stopping it. Chrome stays hidden while it runs except the capsule, which minimizes to a 32 px pill after 3 s.
- **Boundaries.** It continues through seamless seams; with "Between chapters: Card" it stops at the card and waits; it stops at the series end.
- **States.** Running, paused (by user), waiting (resume countdown), stopped at end ("End of chapter" in the capsule), unavailable in paged layouts (the row explains "Auto-scroll works in Strip layout").
- Under Reduce Motion it never starts by itself; when the user starts it, it runs (user-requested motion).

#### 5.4.2 Ambient soundscape

- **Scenes** (eight, each three looping layers mixed live): **Rain on glass** (rain bed, drips on a pane, low room tone), **Night city** (distant traffic, occasional train, neon hum), **Forest dusk** (wind in leaves, crickets, a far stream), **Library hush** (room tone, page rustles, a clock), **Tide** (waves, shingle, gulls far off), **Café corner** (murmur, cups, espresso hiss), **Campfire** (crackle, embers, night wind), **Deep space** (a synthesized drone in E, slow shimmer, soft pulses).
- **Soundscape sheet** (from the reader settings "Soundscape" row, the room's `DotsThree`, or the listen stage tile): a 2 × 4 grid of scene orbs (72 px glass spheres, each tinted by its scene: Rain `#8FD8FF`, Night city `#A99BFF`, Forest `#8FE3B0`, Library `#E8D26B`, Tide `#6FE0C4`, Café `#FFB77A`, Campfire `#FF7A4D`, Deep space `#7A68F0`); the playing orb shows a live waveform ring (the layer levels). Under the grid: a **mixer** of three sliders (Bed, Detail, Tone; 0–100 %) and the master **fill slider**; switches "Lower under narration" (on; ducks to 30 %) and "Remember for this series"; a sleep row shared with narration (Off, 15, 30, 60 min, End of chapter).
- **Room accessory.** While a scene plays (and nothing more important holds the slot), the accessory shows the scene orb (28 px, gently pulsing), its name, and play/pause; tap opens the sheet.
- **Audio assets.** Each layer is a 90 s seamless loop, Opus 96 kb/s (web, Android) and AAC-LC 96 kb/s in `.m4a` (iOS), about 1.1 MB per layer (24 files, ≈ 26 MB total), served by the existing public media route as `/app/media/soundscapes/{scene}-{layer}.{ogg|m4a}` and downloaded on first play, then cached (web: the service worker's media cache; mobile: the app support directory). Recordings are CC0 field recordings or synthesized with sox (Deep space), so there is no licence to track.
- **Playback.** Web: one `AudioContext`, each layer an `AudioBufferSourceNode` with `loop = true` into its `GainNode`, cross-fades between scenes over 2 s. Flutter: `just_audio` (already a dependency), one `AudioPlayer` per layer with `LoopMode.one` and volume ramps; the audio session uses `playback` with `mixWithOthers` so the user's own music is not interrupted (and when the user's music is playing, the soundscape starts muted with a toast "Your music is playing. Tap to mix the soundscape in.").
- **Rules.** UI sounds never play while a soundscape plays. Narration always wins (the soundscape ducks). Soundscapes stop when leaving the room unless "Keep playing outside the reader" is on (a switch in the sheet).
- **States.** Loading a scene ("Fetching Rain on glass" with a progress ring on its orb), playing, paused, offline (only cached scenes are selectable; others show `CloudSlash`), error ("Couldn't play this scene").

#### 5.4.3 Panel-by-panel guided view

- **Data.** **New** `GET /reader/panels?source=&series=&chapter=` → `{pages: [{number, panels: [{x, y, w, h, order}]}], detector, generated_at}` with coordinates normalised to 0–1; computed server-side once per chapter by a panel detector and cached. Downloaded chapters store their panel data with the pages.
- **Entry points.** Reader settings "Start guided view", the page menu "Guided view from here", `x`. Works in any layout; exits back to the layout you came from at the same position.
- **The view.** The camera frames the current panel: the page is scaled so the panel fills the viewport width (max 2.5×, min 1×; tall panels fit height), centred; everything outside the panel is covered by `veil.focus` + `blur.focusVeil` (18 px), and the panel itself is lifted to L3 + 8 px with a soft rim (`rgba(255,255,255,0.10)` 0.5 px) so it floats in front of its own page. Moving to the next panel **dollies the camera** on `spring.smooth` (same page) or `spring.lift` (next page: the old page recedes one step as the new page comes forward). Haptic selection per panel.
- **Controls.** Tap the right 70 % / swipe left = next panel; tap the left 30 % / swipe right = previous; double tap = show the whole page for 2 s; pinch out = exit to the normal layout at this panel. Chrome: the three Float controls plus a **panel counter** capsule "Panel 3 of 7 · Page 12" in place of the scrubber, and a close circle. Auto-advance option (a switch in the settings sheet: 4 s per panel, pausing on touch).
- **States.** Loading panels (the page shows with a thin orbit in the counter capsule), no panel data for this chapter ("Guided view isn't ready for this chapter." + "Read normally"), partial (pages without panels are shown whole as a single "panel"), offline without cached data (same as no data), error ("Couldn't load panel data" + Retry).
- **Reduced motion.** Cuts between panels with a 120 ms fade.

#### 5.4.4 Page-tinted chrome

- **What is tinted.** Only Float glass in the room: the three top controls, the toolbar capsule, the minimized pill, the accessory. Never text, never pages, never the dock or other screens.
- **Which page.** The page under the reading line (38 % of the viewport height in strip; the current page in paged layouts).
- **How.** The page's tint (§2.1.9 glass clamp: L 0.62–0.74, C ≤ 0.10) is mixed at 18 % into the `glass.float` fill; the rim takes the tint at 0.50; the toolbar pill's inner glow takes it at 0.30. A change applies only when the new tint differs by ΔE (OKLab) > 0.04, and eases over `dur.paletteShift` (600 ms).
- **Legibility guard.** When the mixed glass luminance over the page exceeds 0.45, the legibility floor (§2.2.4) switches on, so labels keep ≥ 4.5:1.
- **Novel room.** The tint is the paper colour's text tone at 12 %. **Listen stage.** The voice's hue.
- **Switch.** Reader settings → Light → "Page-tinted controls" (default on).

---
## 6. The two required signature animations

Both are owner-mandated. In Strata they are placed so they never compete: the letter reveal marks **arriving at a place** (a plane's title, a section coming into view), and the typing reveal marks **being greeted** (one headline per session).

### 6.1 Heading reveal: "Surface"

Each letter fades in, slides up and un-blurs, staggered, as if surfacing from just behind the glass.

**Per letter (grapheme cluster):**

| Property | From | To | Driver |
|---|---|---|---|
| opacity | 0 | 1 | 320 ms `ease.out` |
| translateY | 0.42 em | 0 | `spring.letter` {450, 0.10}: stiffness 194.96, damping 25.13 |
| blur | 12 px | 0 | 320 ms `ease.out` |
| scale | 1.06 | 1.00 | `spring.letter` (the letter settles from slightly nearer, the depth signature) |

- **Stagger:** 22 ms per letter. Strings longer than 28 characters stagger by word (40 ms per word) and by letter within a word (12 ms). The whole reveal is capped at 700 ms: if a string would exceed it, the per-letter step shrinks to fit.
- **Type:** responsive sizes from the scale (`largeTitle` 34 → 52, `title2` 22 → 28, `display` 40 → 80 by breakpoint), tight tracking (−0.014 to −0.028 em per role), `ROND` per role.
- **Colour transition on state:** headings that are links (rail titles with "See all", Stage titles, collection names) go `label.1` → Iris on hover and focus over 180 ms `ease.standard`, while their letters rise 1 px in a 12 ms left-to-right wave and settle back; pressed returns to `label.1` at 0.8 opacity. Headings in a selected state (the current section in the desktop settings list header) sit in Iris.

**Where it plays (exactly):**

1. Every plane's `largeTitle` on **first arrival** (a push or a bay's first visit in the session). Not on pop (returning to a plane shows its title settled), not on tab switches back.
2. Section headers (`title2`, the H3 level): each rail and section title the first time it scrolls into view on a plane visit (IntersectionObserver threshold 0.6 / Flutter visibility fraction 0.6), once per visit.
3. The Home Stage title on every spotlight change.
4. Titles of: setup, login, register, the profile picker, onboarding steps 2–4, the recap plane's series title, every Wrapped card title (except the typed opener), empty/error floating-object titles are **excluded** (they stay calm).
5. The wordmark letters in the logo reveal (§7.4).

**Implementation.**

- **Web:** `skins/glass/primitives/LetterReveal.tsx`: splits the string with `Intl.Segmenter(undefined, { granularity: 'grapheme' })` into `inline-block` spans (`aria-hidden`), the container carries `aria-label` with the full text; Motion 13 variants with `staggerChildren: 0.022`, `filter: blur()` per span. When the reveal completes, the spans are replaced by the plain string so kerning and ligatures return (no visible change: the final frame is identical within 0.5 px).
- **Flutter:** `skins/glass/primitives/letter_reveal.dart`: lays the string out once with `TextPainter`, reads each grapheme's box with `getBoxesForSelection`, and paints the whole paragraph once per animating grapheme clipped to that grapheme's box (`canvas.clipRect`) inside a `saveLayer` carrying its opacity, offset, scale and `ImageFilter.blur`; graphemes that have finished merge into one final paint. This keeps kerning intact during the animation. One `AnimationController` drives all letters from a `SpringSimulation` per letter offset by its stagger.
- **Reduced motion:** the whole line fades in over 200 ms. **Screen readers:** the full string is announced once, immediately.

### 6.2 Typing reveal: one character every 50 ms

**The main headline**, typed as if the app is greeting you.

**Where it plays (exactly):**

1. **Home greeting** ("Good evening, Yash") on profile arrival and on the first Home visit of each app session. It is the main headline of the app.
2. **Onboarding welcome** ("Hi, {profile}."), once per new profile.
3. **Wrapped opener** ("Your {year} in pages"), each time Wrapped opens.

Nowhere else. (Recap text streams word by word, §5.1.5; it is not a typing reveal.)

**Spec.**

- **Cadence:** exactly one grapheme every 50 ms, computed from elapsed time (`visible = floor((now − start) / 50)`), never from a timer chain, so dropped frames never slow it down. Grapheme clusters (emoji, combined characters, Hangul syllables) count as one character (`Intl.Segmenter` on the web, the `characters` package in Flutter).
- **Each new character** fades from 0.3 to 1 opacity over 80 ms with no movement and no blur (typing is flat; the letter reveal is the one with depth).
- **Caret:** a 2 px Glacier bar, 0.82 em tall, baseline-aligned, following the last character on `spring.track`; after the last character it blinks three times (530 ms on / 530 ms off) and fades out over 200 ms.
- **Layout:** the full string is laid out invisibly first, so the line never reflows as characters appear and the caret never jumps lines.
- **Sound** (only when interface sounds are on): a `tap` at −34 dBFS on every second character. **Haptic:** none.
- **Skip:** a tap on the headline completes it instantly.
- **Accessibility:** the full text is in the accessibility label from the first frame. **Reduced motion:** the text fades in over 200 ms.
- **Timing check:** "Good evening, " is 14 characters; with a 30-character profile name the longest greeting takes 2.2 s, and the Stage below starts assembling at 400 ms, so nothing waits for the typing.

---

## 7. Brand

The name stays "ManhwaManiacs". Everything below is new and shared by the Glass skin's surfaces (splash, icon, sidebar, auth, share cards).

### 7.1 Wordmark: the Stack, in depth

- **Lockup:** "Manhwa" above "Maniacs", flush left, leading 0.84 so the lines nearly touch; lowercase in **Google Sans Flex** `wght 620`, `ROND 100`, `opsz` = size, tracking −0.02 em, ink Frost `#F2F4F8`.
- **The MM column:** the two capitals are one shape: the top M stands on a horizontal **gutter bar** and the bottom M hangs from it (geometry on a 1024 canvas: bounding box x 240–784, y 192–832; top M y 192–480; bar y 480–544, x 208–816; bottom M y 544–832; stroke 88 units, miter joins, flat caps).
- **Strata rendition:** the column is built as **three glass slabs at three depths**: the bottom M deepest (scale 0.96, brightness 0.80), the bar in the middle and lit (its rim in Glacier `#8FD8FF`, the gutter is where the light comes through), the top M nearest (a specular edge `rgba(255,255,255,0.55)` along its top-left). Each slab has a 0.5 px rim and refracts the horizon behind it. Offsets between slabs are 3 % of the column height, down and to the right, so the stack reads as layers.
- **Single-line fallback** (sidebar, share-card foot, tight headers): "ManhwaManiacs" in Google Sans Flex `wght 640`, `ROND 80`, the two capital M's in Iris.
- **Clear space:** half the M's width on every side. **Minimum sizes:** lockup 88 px wide; single line 120 px wide; the column alone 16 px tall (favicon).
- **Don'ts:** no outline strokes, no gradients on the lowercase, never on a light background (dark only), never tinted per profile.

### 7.2 App icon: "Strata MM"

- **Master (1024 × 1024):** black `#000000` background with a horizon of two soft blobs (Iris `#A99BFF` at 0.40 top-left, Glacier `#8FD8FF` at 0.30 bottom-right, blur 180); the MM column as the three glass slabs of §7.1, centred, occupying the brand geometry; each slab refracting the horizon (rendered once, not live).
- **iOS 26:** a layered icon exported from Icon Composer: background layer (the horizon), and three foreground layers (bottom M, bar, top M) so the system's Liquid Glass lighting, tinted and clear modes act on each slab; the monochrome variant is the column silhouette.
- **Android:** adaptive icon, 108 dp canvas: background = the horizon; foreground = the three slabs within the 72 dp safe zone (the column fits a 60 dp circle); monochrome layer = the column silhouette for themed icons.
- **Skin-bound icon:** switching to Glass sets the Glass icon; switching away sets the Cinematic one. iOS uses `setAlternateIconName("GlassIcon")` (the system confirmation alert is accepted as part of the restart moment); Android toggles `activity-alias` components (`.GlassIcon` enabled, `.CinematicIcon` disabled) with `PackageManager.DONT_KILL_APP`.
- **Web:** `favicon.svg` (the column silhouette in Frost, `prefers-color-scheme` agnostic because the site is dark), `favicon.ico` 32/16, `apple-touch-icon.png` 180 on black, PWA icons 192/512 and a maskable 512 with the column inside the 80 % safe circle.

### 7.3 Splash

- **Native layer (both platforms):** a neutral mark: the flat MM column in `#F3EEE6` on `#000000` (it cannot know the skin). `flutter_native_splash` 2.4.8: `color: "#000000"`, `image: brand/splash/mm-neutral.png` (1152 × 1152), `android_12: { image: brand/splash/mm-neutral-a12.png, color: "#000000" }`; on Android 12+ the mark fits the 192 dp visible circle.
- **Web:** the root layout server-renders the neutral mark as inline SVG centred on `#000`; the installed iOS PWA uses black startup images so there is no white flash.
- **Hand-off:** the first Flutter frame / hydrated React tree redraws the neutral mark at the identical size and position, then plays the Glass reveal.

### 7.4 Logo reveal: "Strata assembly"

Cold start 1,200 ms; warm start 400 ms; the skin-switch arrival always plays the cold version.

| t (ms) | Element | Motion |
|---|---|---|
| 0 | neutral mark | the hand-off frame, flat and cream |
| 0–220 | the column splits | the mark separates into its three parts along z: the top M moves toward you (scale 1.00 → 1.10), the bottom M away (1.00 → 0.90), the bar stays; the vertical gaps open by 24 px; on `spring.surface` |
| 60–310 | glass | each part materializes into glass (lensing 0 → 1 over 250 ms, the cream fading to the glass fill); the horizon blooms behind (Iris and Glacier blobs from 0 to 0.26 over 400 ms) |
| 220–640 | convergence | the three slabs tilt (`rotateX` 12° → 0) and move back into the stacked Strata offsets of §7.1 on `spring.surface`; at ~640 ms they **lock** (haptic `surfaceLock`; sound `logo` when sounds are on) |
| 520–1,000 | wordmark | "Manhwa" / "Maniacs" surface to the right of the column with the letter reveal (22 ms stagger) |
| 1,000–1,200 | hand-off | the column flies to its destination (the first picker orb, the login panel's mark, or the dock droplet on Home) on `spring.morph`; the wordmark dematerializes |

Warm start (400 ms): the slabs appear already stacked and lit (0–200 ms: horizon blooms, slab lensing 0 → 1) and hand off (200–400 ms); no wordmark. Tap anywhere skips to the hand-off. Reduced motion: a 200 ms cross-fade from the neutral mark to the destination, one light haptic.

Implementation: web draws the column as three absolutely positioned inline SVG slabs with the glass recipe (liquid tier on Chromium via one cached SVG filter per slab size); Flutter draws three `SkinGlass` rounded paths (quality `premium`, static) animated by one controller.

---

## 8. Signature moments

Seventeen moments where Strata's idea (navigation is depth) is felt, with where each is specified.

1. **The rise and the strata edges** (every push, §2.9.4, §2.2.2). A new plane rises from below while the one you left steps back and dims; its ambient-coloured top edge joins the lit edges above the screen, so the path you took is a stack of coloured strips you can tap.
2. **The stack overview** (§3.31). Long press Back and the whole bay fans into a tilted deck of live planes; tap any layer to jump there as everything above it falls away.
3. **The cover flight into depth** (§4.12). A poster lifts out of its rail, flies to the series header, and the blurred backdrop blooms out from it, so the series opens up around its cover.
4. **The dive** (§2.9.4, §4.14.12). Pressing Read on the Home Stage: the poster itself comes at you and becomes the first page while the entire app sinks into the dark behind it.
5. **Surfacing** (§2.9.4). Leaving a reader lets the app rise back up under your finger to the exact plane, scroll position and focus you left.
6. **The next chapter locks in** (§4.14.5). Overscroll the end of a chapter: the next chapter rises as a tilted card, and past the threshold it locks with a double tap of haptics and becomes the page.
7. **Guided view panels float** (§5.4.3). Each panel lifts in front of its own page while the rest sinks behind a veil, and the camera dollies from panel to panel.
8. **Page-tinted controls** (§5.4.4). The three glass controls and the toolbar quietly take on the colour of the page you are reading, shifting as the art changes.
9. **Profile arrival** (§4.5). The chosen orb comes forward out of the orbit, floods the space with its mood, and becomes the You orb as Home assembles around it.
10. **The listen stage** (§4.16.2). The page steps back, a voice orb comes forward and breathes with the narrator, and a character's colour flows into it when they speak.
11. **Previously on, as a deck** (§5.1.5). The recap is a stack of cards you lift off one by one before diving into the chapter.
12. **Wrapped, as a deck that flips** (§5.2.4). Each year-card lifts off toward you; Export flips a card over to its shareable side.
13. **The streak ignites** (§5.2.3). Meeting today's goal lights a three-layer flame in depth on the You orb, with embers rising and the `ignite` haptic.
14. **Reactions rise through depth** (§5.3.4). A reaction glyph rises out of the bar toward you and settles back, leaving a Bloom trail.
15. **Recede into the abyss** (§4.25.1). Switching skins pushes the entire space away into the dark until only the MM mark remains; the new skin is born from it.
16. **The lift page turn** (§4.15.2). A finished page rises toward you and slides away like a sheet of glass lifted from a stack.
17. **Unfollow sinks** (§4.17). Removed series drop into the abyss; Undo raises them back from the dark.

---

## 9. Implementation notes (stack from `stack-decision.md`)

### 9.1 Tokens

`design/tokens/glass.json` holds every value in §2 under these top-level keys: `color`, `label`, `fill`, `line`, `status`, `speaker`, `paper`, `mood`, `depth` (levels, phone/desk geometry, dims), `material`, `type` (families, roles per breakpoint, text-scale rules), `space`, `layout`, `radius`, `blur`, `rim`, `motion` (springs as `{ms, bounce}`, curves as `{ms, bezier}`, stagger rules), `haptics` (event → pattern name, plus the AHAP pattern bodies), `sounds` (event → file). `design/build.mjs` emits:

- `frontend/src/skins/glass/tokens.generated.css` (`[data-skin="glass"] { --mm-color-abyss: #000000; --mm-depth-phone-deck1-scale: 0.94; --mm-spring-lift: linear(…64 samples…); … }`),
- `frontend/src/skins/glass/tokens.generated.ts` (`spring.lift = { type: "spring", stiffness: 130.5, damping: 21.02, mass: 1 }` computed from `{ms, bounce}` with Apple's formulas; stiffness/damping rather than `visualDuration` so retargets keep velocity),
- `mobile/lib/skins/glass/tokens.g.dart` (`const glassTokens = SkinTokens(abyss: Color(0xFF000000), … lift: SpringToken(ms: 550, bounce: 0.08), …)`, letter spacing multiplied into absolute values per style),
- `mobile/assets/haptics/*.ahap.json` from `haptics.patterns`,
- and the `HapticEvent` / `SoundEvent` / `ScreenId` entries in the contract files.

`--check` mode also verifies the contrast table: every `label.*` token against `#000000`, `slab.1` and `slab.2`, every paper pair, every speaker hue, failing CI below 4.5:1 for text roles (3:1 for `label.4`, which is documented as disabled-only).

### 9.2 Web (Next.js 16.2.9, React 19.2, Tailwind 4, Motion 13.4.4)

**Folder:**

```
frontend/src/skins/glass/
  index.ts                 Skin export (tokens, fonts, Shell, Splash, screens: Record<ScreenId, Screen>, haptics, sounds)
  tokens.generated.{css,ts}
  fonts.ts                 next/font: Google_Sans_Flex({ axes: ['ROND','opsz'], variable: '--font-glass' }),
                           Google_Sans_Code, and Literata / Newsreader / Atkinson_Hyperlegible_Next with preload: false
  Shell.tsx                Horizon, Sidebar | Dock+Orb+Accessory, PlaneStack, overlays, MotionConfig reducedMotion="user"
  Splash.tsx               Strata assembly (plays once per session: sessionStorage['mm.skin.splash'])
  shell/  PlaneStack.tsx  Horizon.tsx  Dock.tsx  Sidebar.tsx  Accessory.tsx  YouOrb.tsx  StackOverview.tsx  OfflineHud.tsx
  primitives/  Glass.tsx  Button.tsx  IconButton.tsx  Field.tsx  Chip.tsx  Segmented.tsx  Sheet.tsx  Menu.tsx
               Toast.tsx  Poster.tsx  Rail.tsx  Skeleton.tsx  Orbit.tsx  Slider.tsx  Switch.tsx  Progress.tsx
               FloatingObject.tsx  LetterReveal.tsx  TypingReveal.tsx  DownloadControl.tsx  ReactionBar.tsx
  screens/     one folder per ScreenId (home, library, series, readerManga, readerNovel, listen, forYou, stats,
               wrapped, circle, friend, settings, …)
  motion.ts    springs from tokens + the depth transform maps
  haptics.ts   navigator.vibrate for the four Android-web events, no-ops elsewhere
  sounds.ts    Web Audio buffers, decoded on the first user gesture
  palette.worker.ts   16×16 OffscreenCanvas sampler + OKLCH selection (§2.1.9)
```

**The plane stack.** `PlaneStack` lives in the Glass `Shell`, which wraps the App Router `children`. On every navigation it keeps the previous route trees mounted instead of replacing them: state is an array of `{ key: pathname + search, node: ReactNode }`, capped at 4 per bay. A push appends the new `children`; a pop (in-app back, `Esc`, strata tap, browser back) removes the top entry. Direction comes from the app's own `navigate()` helper (which passes Next `Link`'s `transitionTypes={['nav-forward']}` / `['nav-back']`) and from `popstate` for browser buttons. Deck entries render `inert` and `aria-hidden`, with `transform: translateY(var(--top)) scale(var(--scale))` and `filter: brightness(var(--b)) blur(var(--blur))` driven by one Motion value `p` per navigation; levels 2 and 3 are clipped to their visible band (`clip-path: inset(0 0 calc(100% - 48px) 0)`) so they cost almost nothing to paint. Because the previous plane is still mounted, the cover flight is a plain Motion `layoutId` shared between the rail poster and the header poster (inside one `LayoutGroup`), with no View Transition snapshot. A hard load of a deep URL renders the plane at depth 1 over its bay root (the bay is derived from the path; a `from` query parameter set by in-app links overrides it). Each bay's stack path list is kept in `sessionStorage['mm.glass.bays']` so switching bays restores its stack (planes re-render from TanStack Query's cache).

**Rooms** are not in the plane stack: the reader routes render in a `Room` layout, and entering one animates the whole `PlaneStack` element (the dive) before the router swaps; the stack's scroll positions and focus are restored on surfacing from a snapshot kept in memory.

**Glass tiers.** `Glass.tsx` renders the frosted recipe for everyone (`backdrop-filter: blur(var(--mm-blur-float)) saturate(1.7)`, fill, the `::before` specular rim with a masked gradient and the `::after` pointer glow). On Chromium (detected by `navigator.userAgentData.brands` containing "Chromium"), it adds `data-liquid` and `backdrop-filter: url(#lg-{w}x{h}-r{r})`: an SVG `feDisplacementMap` filter generated from our own convex-squircle refraction map (n 1.5, bezel/thickness per material), cached per size and rebuilt on `ResizeObserver` with a 100 ms debounce; `colorInterpolationFilters="sRGB"` is mandatory; materialize animates the filter's `scale` from 0. `@media (prefers-reduced-transparency: reduce)`, `(prefers-contrast: more)` and the in-app Solid glass switch (`data-solid` on `<html>`) select the solid tokens. At most two glass layers overlap: the Shell tracks open Lift surfaces and sets `data-solid-under` on Float controls beneath them.

**Horizon.** A fixed `div` behind everything with two `radial-gradient`s whose colours are registered custom properties (`@property --mm-h-a { syntax: '<color>'; inherits: true; initial-value: transparent }`) transitioning over 600 ms; drift is a CSS keyframe transform (40 s), disabled under reduced motion; parallax offsets come from a pointer listener on the Shell (desktop) or `DeviceOrientationEvent` (mobile web, after `DeviceOrientationEvent.requestPermission()` on iOS Safari, requested from Settings → Feedback, never on load).

**Libraries (the list in stack-decision §3):** `motion` 13.4.4 (springs, layout, drag, gestures for planes and sheets), `@base-ui/react` 1.8.0 (`Drawer` for accessible sheets with snap points and nesting, `Menu`, `ContextMenu`, `Dialog`, `Switch`, `Slider` primitives styled with the Glass tokens; the morph-from-trigger is a Motion `layoutId` between the trigger's glass and the popup body), `sonner` 2.0.8 (`toast.custom()` rendering the HUD capsule; `visibleToasts={2}`; position `top-center` below 768 px, `bottom-center` above), `embla-carousel-react` 8.6.0 (the Home Stage only: loop, 9 s autoplay stopped on interaction), `@use-gesture/react` 10.3.1 (reader pinch). Rails use native `scroll-snap`; the voice orbit and the Wrapped deck are Motion drags; charts are hand-drawn SVG (bars, heatmap, clock, radar), no chart library. `lenis` is not used by Glass (the reader and planes keep native scrolling).

**Keyboard.** The existing `lib/keyboard` registry gains the Glass bindings (§4.0.5 and per screen); chords `g h`… use its chord parser; the "Single-key shortcuts" switch filters modifier-less bindings; the shortcuts sheet and the command palette read the registry.

**Offline and the skin switch.** The service worker handles `{ type: 'skin-changed' }` by deleting the pages cache and re-fetching every saved chapter document, so an offline cold launch never serves the other skin's HTML (stack-decision §2.5). The offline fallback page ships its own inline Glass CSS.

**Performance budget (desktop Chromium and flagship phones):** 120 fps on scroll with the dock and two Float controls in the liquid tier; plane push ≤ 1 dropped frame; filters regenerated only at rest; the horizon is a composited layer (`will-change: transform`); deck planes beyond 1 are clipped; images on rails use `next/image` with explicit `sizes`.

### 9.3 Flutter (3.44.6, Riverpod, go_router ≤ 17.5)

**Folder:**

```
mobile/lib/skins/glass/
  glass_skin.dart          Skin implementation (theme, buildRouter, splash, haptics, sounds)
  tokens.g.dart
  skin_glass.dart          the one wrapper around liquid_glass_widgets (quality policy, solid fallback)
  router.dart              StatefulShellRoute.indexedStack (4 bays) + root-navigator rooms + sheets
  shell/  strata_route.dart  strata_controller.dart  horizon.dart  dock.dart  accessory.dart  you_orb.dart
          stack_overview.dart  offline_hud.dart
  primitives/  …the same list as the web, in Dart
  screens/<screen_id>/…
  haptics.dart  sounds.dart  palette_isolate.dart
```

**Planes.** Each bay branch navigator builds pages with `StrataPage` (a `Page` whose route is `StrataRoute`, a `PageRoute` with `opaque: false`, `maintainState: true`, and `transitionDuration` long enough for the spring; the actual motion is driven by `controller.animateWith(SpringSimulation(glassTokens.lift, …))` from the route's own `AnimationController`, overriding `createAnimationController`). A `StrataController` (a Riverpod `Notifier` fed by a `NavigatorObserver` on each branch navigator) keeps, for every route, its depth from the top; each `StrataPlane` widget reads its depth with `ref.watch` and animates top, scale and brightness toward the §2.2.2 values. Brightness on black is a `ColoredBox(Colors.black.withValues(alpha: 1 − b))` overlay (equivalent to multiplying brightness on an AMOLED canvas, and much cheaper than a colour matrix); deck 2 and 3 add `ImageFiltered(ImageFilter.blur(…))` inside a `ClipRect` limited to their visible band plus 40 px; depth ≥ 4 is wrapped in `Visibility(visible: false, maintainState: true)` so it keeps state and costs no paint. The drag-to-drop and the iOS full-width swipe are one `GestureDetector` on the plane feeding `route.controller` directly (1:1), released with Apple's projection; `swipeable_page_route` 0.4.8 supplies the full-width back gesture on iOS; Android predictive back uses `PredictiveBackPageTransitionsBuilder` wrapped so its progress drives the same depth mapping. The cover flight uses `heroine` 0.7.2 (`Heroine(tag: 'cover-$id', motion: …smooth…)`), which works because the previous plane stays mounted.

**Rooms** are routes on the root navigator (`DiveRoute`), above the shell; the dive drives the shell's `Transform` + `ColoredBox` overlay from the room route's animation.

**Glass.** `liquid_glass_widgets` 1.7.2 pinned exactly, used only through `SkinGlass` (stack-decision condition). Quality: `GlassQuality.premium` for static Float and Lift surfaces (dock, orb, top controls, menus, sheets, alerts), `standard` for glass inside scrolling content (the floating-object disc, the scrub lens). `LiquidGlassWidgets.initialize()` precompiles shaders during the native splash. The dock is `GlassTabBar` (bar 62, minimized 50, the search variant for the orb, minimize thresholds 24 / 12); sheets are `GlassModalSheet.show(morphFrom: anchor, peekSize: 96, halfSize: 0.5, horizontalMargin: 8, bottomMargin: 8, fullTopBorderRadius: 28, barrierColor: Color(0x4D000000))`; lists inside sheets use the provided scroll controller for the drag hand-off. Content-layer blur (deck levels, the focus veil) uses `BackdropFilter.grouped` inside one `BackdropGroup` per screen. Reduce Transparency is read through the `mm/haptics` channel (`reduceTransparency`) and the Solid glass switch, and fed to `GlassAccessibilityScope`. If the stack-decision glass gate fails on the iPhone, `SkinGlass` switches to `BackdropFilter` + a painted rim with no other file changing.

**Springs.** `SpringDescription.withDurationAndBounce(duration: Duration(milliseconds: ms), bounce: b)` from the generated tokens; retargets use `SpringSimulation(spring, controller.value, target, controller.velocity)`.

**Other packages (stack-decision list plus Glass-only additions, all resolving on 3.44.6):** `flutter_animate` 4.5.2 (staggered assemblies), `gaimon` 1.5.0 (named impacts + AHAP, Android waveforms), `sensors_plus` 7.1.0 (gyro parallax, throttled to 60 Hz, off under Reduce Motion), `material_color_utilities` ^0.13.0 promoted to a direct dependency (page tints in `compute()`), `flutter_soloud` 5.1.4 (UI sounds), `audio_service` (system media controls for listen mode; pinned to the newest release that resolves on 3.44.6 when added), `flutter_native_splash` 2.4.8 (dev), plus the existing `just_audio`, `audio_session`, `wakelock_plus`, `cached_network_image`. New native code: the `mm/share` channel (§5.2.5) and the `mm/haptics` channel additions, both in one isolated commit with a CI iOS dry run.

**Fonts.** Bundled variable TTFs: `GoogleSansFlexMM` (the 510 KB instanced subset), `GoogleSansCodeMM`, Literata, Newsreader, Atkinson Hyperlegible Next; every `TextStyle` carries `fontVariations` for `wght`, `opsz` (= size) and `ROND`, generated per role.

**Text scale.** The Glass shell reads the OS factor from `MediaQuery.textScalerOf(context)` once, then sets `MediaQuery(textScaler: TextScaler.noScaling)` below it and builds every text style through a `GlassTextScaler` that applies §2.3.3 per role (linear for body roles, damped and capped for titles), so no style is scaled twice.

**Tests.** `test/skins/completeness_test.dart` and `import_boundary_test.dart` (stack-decision §2.3) cover Glass; per cluster, one smoke test and golden screenshots at depth 0, 1 and 3, plus reduced-motion and solid-glass goldens for the dock, a sheet and the series plane; a unit test for the depth mapping (`p` → deck values) and for the release projection.

### 9.4 Backend additions this concept draws against

| Addition | Used by |
|---|---|
| `reading_profiles.skin` (`'cinematic' \| 'glass'`, nullable) on `PATCH /profiles/{id}` | Skin switch and profile arrival (stack-decision §2.4) |
| `palette` on series payloads (`dominant, vibrant, muted, darkVibrant`), computed once per cover with Pillow | Horizon field, series header, stat and share cards |
| `GET /home` ordered sections | Home (§4.8, §5.1.2) |
| `GET /series/similar`, `POST /recommendations/feedback` | More like this, Not interested |
| `POST /recaps` (+ cached results) | Previously on |
| `GET /stats/wrapped?year=`, profile `daily_goal_minutes` | Wrapped, streak goal |
| `/social/*` endpoints and collection `shared`/`collaborative` fields (§5.3.1) | The Circle |
| `GET /reader/panels` | Guided view |
| Soundscape media files under `/app/media/soundscapes/` | Soundscapes |

Every addition applies the 18+ gate when serving, never when storing (shared caches rule).

### 9.5 Build order for the Glass skin

1. Tokens + `SkinGlass` + the glass gate on the owner's iPhone and the Android flagship (stack-decision condition).
2. Shell: horizon, dock/orb/accessory, sidebar, `PlaneStack` / `StrataRoute` with the depth mapping, stack overview, sheets, menus, toasts.
3. Primitives (§3) with goldens.
4. Home, Library, series and book planes, Sources and catalogue, Search.
5. Rooms: manga reader chrome on the extracted reader engine (`chromeBuilder`), novel reader, listen mode.
6. Updates, On this device, Collections, History, Bookmarks, Dialogue search, You, Settings (with the skin picker), System status, status screens.
7. The four new features in the order AI home and recaps → stats and Wrapped → ambient extras → Circle (the Circle needs the most backend).
8. Brand: icon sets, splash assets, the logo reveal, share-card templates.
