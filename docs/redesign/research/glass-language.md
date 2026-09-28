# Glass + Depth: the visual language for the ManhwaManiacs "Glass" skin

Research date: 2026-09-29. Sources: Apple's HIG and WWDC23/WWDC25 sessions, the Flutter 3.44.6 SDK source, Motion 12.42.2 source, and four reference implementations cloned into `/srv/manhwamaniacs/dev/design-ref`. Every number carries one of three labels:

- **[Apple]**: read from Apple's HIG, an Apple API page, or a WWDC session transcript during this research.
- **[3P]**: measured or implemented by a third-party library or site (named at the point of use).
- **[MM]**: a ManhwaManiacs decision. These are starting values and calibration knobs, not Apple facts.

The format follows the `design-md` DESIGN.md convention (see `~/.claude/skills/design-md/design-md/apple/DESIGN.md` and `raycast/DESIGN.md`): a YAML token block (section 2), then the prose that explains how to use it.

**One conflict to be aware of.** `inventory/00-decisions.md` says "Flagship-only, maximum effects. Do not design degraded fallbacks for low-end devices." The task for this document asks for low-end Android fallbacks. Section 9 handles both. It defines one **capability floor**, which is not a low-end design tier. It switches on only when the renderer literally cannot draw refraction (Skia, or a non-Chromium browser) or when the user turned on Reduce Transparency or Increase Contrast. Those are accessibility settings, so they follow the same rule as reduced motion.

---

## 0. The rules in ten lines

1. Glass is for the **control layer only**: bars, floating buttons, menus, sheets, toasts. Content (covers, rows, pages) sits on black or on standard materials, never on Liquid Glass. [Apple]
2. **No glass on glass.** Anything placed on a glass surface uses fills, vibrancy and transparency. Glass siblings share one sampling container. [Apple]
3. Two variants that **never mix**: *regular* (the default, and adaptive) and *clear* (only over media, only with a dimming layer when the media is bright). [Apple]
4. **Size changes the material.** The bigger the glass, the thicker it reads: deeper shadow, stronger lensing, softer scatter. Small glass flips light/dark with the backdrop. Large glass never flips. [Apple]
5. Every control is a **capsule**. Every container is **concentric**: inner radius = outer radius − padding. [Apple]
6. **Springs only**, parameterised as duration + bounce. The default bounce is 0. Bounce above 0.4 is off-limits. A retarget keeps its velocity. [Apple]
7. Presses **grow and light up**: about +17 pt on the longest side, plus a glow that spreads from the finger. They do not dim. [Apple, 3P measurement]
8. **Tint is rare.** Only the one primary action per screen gets a tinted glass background. Symbols on glass stay monochrome. [Apple]
9. **Haptics follow Apple's documented meanings** and are always optional. [Apple]
10. **Accessibility settings reshape the glass.** Reduce Transparency makes it frostier. Increase Contrast makes it black and white with a border. Reduce Motion removes elasticity. [Apple]

---

## 1. Apple's language, from source

### 1.1 The material: Liquid Glass

WWDC25 session 219, *Meet Liquid Glass* [Apple]:

- **Lensing, not scattering.** "Where as previous materials scattered light, this new set of materials dynamically bends, shapes, and concentrates light in real time." Lensing is "the primary way Liquid Glass visually defines itself".
- **Materialize, don't fade.** Glass objects appear and disappear "by gradually modulating the light bending and lensing". Opacity fades are not how glass enters.
- **Highlights.** Light sources "shine on the material producing highlights that respond to geometry". On some interactions the lights move around the silhouette. "In some cases, the lighting responds to device motion."
- **Adaptive shadow.** The shadow's opacity goes **up** over text and **down** over a solid light background.
- **Size → thickness.** When glass grows (for example, a menu opening from a toolbar button), "its material characteristics change to simulate a thicker, more substantial material": it gets "deeper, richer shadows, … more pronounced lensing and refraction effects, and a softer scattering of light".
- **Light/dark adaptivity.** Small elements (nav bars, tab bars) "flip from light to dark based on the background". Large elements (menus, sidebars) adapt but "don't flip from light to dark", because that "would be distracting". The amount of tint and the dynamic range shift so labels stay legible.
- **Interaction.** "The material illuminates from within". The glow starts "right under your fingertips" and spreads through the element and onto nearby glass. The material "flexes" with a "gel-like flexibility", and elements "can even lift up into Liquid Glass temporarily".
- **Morphing.** Glass "dynamically morphs between the controls in each context". A menu is a bubble that "simply pops open" in place.

### 1.2 Variants: regular vs clear

From the HIG Materials page and WWDC25-219 [Apple]:

| | Regular | Clear |
|---|---|---|
| Behaviour | Blurs, adjusts luminosity, fully adaptive | "Permanently more transparent", **no adaptive behaviours** |
| Use for | Everything by default. Required for text-heavy glass (alerts, sidebars, popovers) | Components over photos and video |
| Legibility aid | Scroll edge effects | A **dimming layer**: dark, **35 % opacity**, when the media underneath is bright. None when the media is already dark |
| Conditions | None | Use only when all three hold: over media-rich content, the content won't be harmed by dimming, and the content on top is bold and bright |
| Mixing | **Never mix the two variants** | |

### 1.3 Layering and hierarchy

[Apple, HIG Materials and WWDC25-219/356]

- Liquid Glass is "a distinct functional layer for controls and navigation elements … that floats above the content layer". "Don't use Liquid Glass in the content layer."
- **Exception:** a transient content-layer control, such as a slider or toggle, "takes on a Liquid Glass appearance … when a person activates it". It is glass only while it is being dragged.
- "Always avoid glass on glass." For anything on top of glass, "use fills, transparency, and vibrancy".
- Glass cannot sample other glass. Siblings go into one `GlassEffectContainer` so they share a sampling region and can morph into each other (`glassEffectID`).
- "Use Liquid Glass effects sparingly … Limit these effects to the most important functional elements."
- Tinting: "Selecting a color generates a range of tones that are mapped to content brightness underneath". Tint only primary elements: "When every element is tinted, nothing stands out." To emphasise an action, "apply color to the background rather than to symbols or text". "Refrain from adding color to the background of multiple controls."
- A task that interrupts the user pairs glass with a **dimming layer**. Action sheets now **spring from the control that triggered them**.
- "When focus shifts, like dragging a sheet upward, Liquid Glass subtly recedes, becoming more opaque and gently growing in size."

### 1.4 Standard materials and vibrancy

[Apple, HIG Materials] These are the materials for content-layer structure that is not Liquid Glass.

- iOS thickness ladder: `ultraThin` (mostly translucent) → `thin` → `regular` (the default) → `thick` (more opaque than translucent). "Thicker materials … provide better contrast for text"; "thinner materials … help people retain their context".
- Vibrancy for labels: `label` → `secondaryLabel` → `tertiaryLabel` → `quaternaryLabel`. Never put quaternary on `thin` or `ultraThin`. Fills: `fill`, `secondaryFill`, `tertiaryFill`. Separators have a single vibrancy value.
- Pick a material by **meaning**, not by the colour it gives. System settings change how materials look.
- **visionOS:** windows use the system "glass" material, which is not modifiable. Inside a window, `thin` "brings attention to interactive elements", `regular` separates sections (sidebars, grouped tables), and `thick` makes "a dark element that remains visually distinct" on top of `regular`. "Prefer translucency to opaque colors in windows." visionOS vibrancy has three levels: label, secondaryLabel, tertiaryLabel (for inactive elements only).

### 1.5 Scroll edge effects

[Apple, WWDC25-356/323] These replace hard dividers under bars.

- The **soft** style is the iOS default: a gradual fade and blur for glass controls over scrolling content.
- The **hard** style is "a stronger, more opaque boundary", used for pinned headers and controls without backgrounds. SwiftUI: `scrollEdgeEffectStyle(.hard, for: .top)`.
- "Scroll edge effects are not decorative. They don't block or darken like overlays." Apply **one per view edge**.

### 1.6 Sheets, detents and stacking

[Apple, WWDC25-323 and the nilcoalescing write-up]

- Partial-height detents are **inset** by default with a Liquid Glass background. The bottom edges "pull in to nest in display corners", and the corners follow the device shape.
- At the full-height (`.large`) detent, the background "transitions to an opaque appearance, and it becomes attached to the sides and bottom of the screen".
- A sheet can **morph out of the button that opened it**: `matchedTransitionSource(id:in:)` on the button, and `.navigationTransition(.zoom(sourceID:in:))` on the sheet content.
- Remove `presentationBackground` so the system material shows through.
- The iOS 26 sheet corner radius is 40 pt when set through `preferredCornerRadius` [3P, search summary; re-measure before relying on it]. `UISheetPresentationController.backgroundEffect` arrived in iOS 26.1 [3P].
- Stacking reference: Flutter's `CupertinoSheetRoute`, measured from the iOS 18 simulator, uses an 8 % top gap. The covered sheet scales down by 0.0835 and moves up by 2 %, with `Curves.fastEaseInToSlowEaseOut` over 500 ms [3P, Flutter SDK `cupertino/sheet.dart`].
- Drag projection. When a finger lifts, iOS picks the destination detent from where the motion *would* end, not where the finger stopped: `projected = position + (velocity_pt_per_s / 1000) × r / (1 − r)`, with `r = 0.998` (`UIScrollView.DecelerationRate.normal`). That works out to about `position + 0.5 × velocity`. Source: WWDC18 *Designing Fluid Interfaces* [Apple, recalled rather than re-fetched in this research].

### 1.7 Concentricity

[Apple, WWDC25-356]

- There are three shape kinds. **Fixed** has a constant radius. A **capsule** has radius = height ÷ 2. A **concentric** shape's radius is the parent radius minus the padding: `r_inner = r_outer − padding`.
- "By aligning radii and margins around a shared center, shapes can comfortably nest." If a nested shape "feels off", it probably needs to be concentric.
- On iPhone, controls near the screen edge are **capsules with extra margin**. On iPad and Mac, use shapes concentric with the window.
- APIs: SwiftUI `.rect(corner: .containerConcentric)` and `ConcentricRectangle`. The system takes the corner from the container and the device.
- Apple's corners are continuous (superellipse), not circular arcs. The web and Flutter equivalents are in sections 5.5 and 6.2.

### 1.8 Springs

WWDC23 *Animate with springs* and the SwiftUI API pages [Apple]:

- Parameters: **duration** (the perceptual duration) and **bounce** (−1 to 1). Bounce 0 is a smooth spring and the default. About 0.15 is "brisk". About 0.3 is "noticeable bounciness". Be "cautious about using values higher than around 0.4".
- Conversion, with mass = 1: `stiffness = (2π / duration)²`, and `damping = 4π(1 − bounce) / duration` when bounce ≥ 0 or `4π / (duration × (1 + bounce))` when bounce < 0. Flutter's `SpringDescription.withDurationAndBounce` in SDK 3.44.6 implements exactly this, as `dampingRatio = 1 − bounce` or `1 / (1 + bounce)` [verified in source].
- Presets: `.smooth` = 0.5 s / bounce 0. `.snappy` = 0.5 s / bounce **0.15** (the "base bounce of 0.15" per Apple's docs). `.bouncy` = 0.5 s / 0.3. `spring(response: 0.5, dampingFraction: 0.825)`. `interactiveSpring(response: 0.15, dampingFraction: 0.86, blendDuration: 0.25)`. The `motor` package reproduces the same presets [3P].
- Velocity: gestures hand their velocity to the spring, and an interrupted spring "uses the velocity it had when it was retargeted".

The presets converted to physics values (computed here, mass 1):

| Preset | duration / bounce | stiffness | damping | ζ | settles to 0.5 % | overshoot |
|---|---|---|---|---|---|---|
| smooth | 0.50 / 0 | 157.9 | 25.13 | 1.00 | 592 ms | 0 % |
| snappy | 0.50 / 0.15 | 157.9 | 21.36 | 0.85 | 537 ms | 0.6 % |
| bouncy | 0.50 / 0.30 | 157.9 | 17.59 | 0.70 | 556 ms | 4.6 % |
| spring() default | resp 0.5 / ζ 0.825 | 157.9 | 20.73 | 0.825 | 565 ms | 1.0 % |
| interactiveSpring | resp 0.15 / ζ 0.86 | 1754.6 | 72.05 | 0.86 | 115 ms | 0.5 % |

### 1.9 Type: SF Pro and Dynamic Type

HIG Typography, iOS/iPadOS [Apple]. Values are size / leading in pt.

| Style | Weight | xSmall | **Large (default)** | AX5 (max) |
|---|---|---|---|---|
| Large Title | Regular | 31/38 | **34/41** | 60/70 |
| Title 1 | Regular | 25/31 | **28/34** | 58/68 |
| Title 2 | Regular | 19/24 | **22/28** | 56/66 |
| Title 3 | Regular | 17/22 | **20/25** | 55/65 |
| Headline | Semibold | 14/19 | **17/22** | 53/62 |
| Body | Regular | 14/19 | **17/22** | 53/62 |
| Callout | Regular | 13/18 | **16/21** | 51/60 |
| Subhead | Regular | 12/16 | **15/20** | 49/58 |
| Footnote | Regular | 12/16 | **13/18** | 44/52 |
| Caption 1 | Regular | 11/13 | **12/16** | 43/51 |
| Caption 2 | Regular | 11/13 | **11/13** | 40/48 |

- Minimum sizes: iOS 11 pt (default 17), visionOS 12 pt (default 17) [Apple].
- iOS 26 typography is "bolder and left-aligned" in key moments such as alerts and onboarding [Apple, WWDC25-356]. Navigation large titles are 34 pt **bold** and inline titles are 17 pt semibold [3P, learnui].
- Optical sizes: SF Text is used below 20 pt and SF Display at 20 pt and above. The switch is automatic through the `opsz` axis [3P].
- Tracking in pt at the default size. Values marked ✓ were cross-checked in this research. The rest come from Apple's iOS UI kit and should be re-read from the iOS 26 Figma kit before shipping:
  11 → +0.06 · 12 → 0 · 13 → −0.08 · 15 → **−0.23 ✓** (Flutter `cupertino/text_theme.dart`) · 16 → −0.31 · 17 → **−0.43 ✓** (iOS 26 kit, reported by two sources; Flutter's iOS 14-era value is −0.41) · 20 → −0.45 · 22 → −0.26 · 28 → +0.38 · 34 → **+0.38 to +0.40 ✓** (Flutter uses +0.38 for the 34 pt bold nav large title).
- **Licensing:** SF Pro can be used on Apple platforms through the system font. It must **not** be bundled into the Android build or served as a web font. Use it only where the OS provides it.

### 1.10 Haptics

HIG *Playing haptics* and UIKit [Apple]:

| Family | Pattern | Documented meaning |
|---|---|---|
| Notification (`UINotificationFeedbackGenerator`) | success / warning / error | A task completed / produced a warning / failed |
| Impact (`UIImpactFeedbackGenerator`) | light / medium / heavy | Collision between small / medium / large UI objects |
| | rigid / soft | Collision between hard / soft, flexible objects. Added in iOS 13, along with `impactOccurred(intensity:)` taking 0–1 |
| Selection (`UISelectionFeedbackGenerator`) | selection | "A UI element's values are changing" |

The rules, quoted [Apple]: "Use system-provided haptic patterns according to their documented meanings." "Use haptics consistently." "Prefer using haptics to complement other feedback." "Avoid overusing haptics." "Prefer playing short haptics that complement discrete events." "Make haptics optional." Haptics can also disturb the camera, gyroscope and microphone.

### 1.11 Motion durations (non-spring reference)

Apple doesn't publish UIKit durations. These are Flutter's constants, tuned against iOS [3P, Flutter SDK 3.44.6]:

| What | Value |
|---|---|
| Push/pop page transition (`CupertinoPageRoute`) | 500 ms |
| Page swipe dropped mid-gesture | 350 ms |
| Modal popup / action sheet | 335 ms |
| Sheet (`CupertinoSheetRoute`) | 500 ms, `fastEaseInToSlowEaseOut` |
| Sheet dropped after drag | 300 ms |
| Button press fade out / in | 120 ms / 180 ms (pressed opacity 0.4, the pre-glass iOS look) |
| Sliding segmented thumb | spring over 412 ms; highlight 200 ms |
| Switch position / reaction | 200 ms / 300 ms |
| Nav bar title fade / search expand | 150 ms / 300 ms |

Glass-specific values measured by `liquid_glass_widgets` [3P]: materialize 250 ms, dematerialize 350 ms, touch glow ("ambient lift") 150 ms in / 60 ms out, button→sheet morph 375 ms ("iOS 26 native-parity"), and a glass switch toggle of 380 ms.

### 1.12 Hover and press states

- **iOS 26 press** [Apple + 3P]: glass controls grow, brighten from inside, and stretch toward the drag. `.glassEffect(.regular.interactive())` gives the "scale, bounce, shimmer on interaction". Measured growth is about **+17 pt on the longest side whatever the control's size**, so a 56 pt circle reaches about 1.30× and a 132 pt pill about 1.13× (measured at 120 fps by `liquid_glass_widgets`) [3P].
- **visionOS hover** [Apple, HIG Eyes]: interactive elements highlight when looked at. There are three custom hover-effect delays: none (subtle invitations), short (tab-bar expansion) and long (tooltips and extra info). Rounded shapes are easier to target. Multi-part controls need one bounding region. "Keep at least one primary view unchanged" between hover states. SwiftUI's `HoverEffect` has `.highlight` and `.lift`.
- **visionOS spacing** [Apple]: centres at least **60 pt** apart, with **16 pt** or more between items. On touch, the iOS minimum stays **44 × 44 pt** (Flutter `kMinInteractiveDimensionCupertino = 44`).

### 1.13 Tab bar morphing

[Apple, WWDC25-323/356; metrics 3P]

- The tab bar is a **floating glass capsule**, inset **21 pt** from the left, right and bottom [3P, learnui]. It holds 2 to 5 tabs, with labels at 11 pt [3P]. `liquid_glass_widgets` uses a bar height of 64 pt, a minimized height of 50 pt and a 50 pt search circle [3P].
- `tabBarMinimizeBehavior(.onScrollDown)` collapses the bar into a small capsule on downward scroll and re-expands it on upward scroll. `liquid_glass_widgets` triggers after 20 pt of downward scroll and expands after 12 pt of upward scroll [3P].
- `tabViewBottomAccessory { … }` puts a control above the bar, such as the Music mini-player. When the bar minimizes, the accessory moves **inline** beside it. It reads `tabViewBottomAccessoryPlacement` (`.inline` / `.expanded`).
- `Tab(role: .search)` gives Search its own circle, separated at the trailing end. Tapping it expands into a search field at the bottom of the screen.
- The selection indicator is a glass droplet. Pressing it lifts it into clear, lensing glass. Dragging stretches it along the direction of travel. Releasing lets it settle into the new tab on a spring. Siblings in one glass container blend like metaballs while they move.

### 1.14 visionOS depth, carried over to a flat screen

[Apple, HIG Spatial layout]

- "Use depth to communicate hierarchy." It works well for "making a tab bar or toolbar stand out from a window".
- "Avoid adding depth to text", because floating text is hard to read. Depth "may not work as well on small objects" such as a symbol inside a button.
- Each depth step costs refocusing effort, so use few steps. Don't let controls overlap other interactive elements.

### 1.15 Accessibility

[Apple, WWDC25-219 and HIG]

| Setting | What happens to glass |
|---|---|
| Reduce Transparency | "Makes Liquid Glass frostier and obscures more of the content behind it" |
| Increase Contrast | "Makes elements predominantly black or white and highlights them with a contrasting border" |
| Reduce Motion | "Decreases the intensity of some effects and disables any elastic properties" |
| iOS 26.1 *Liquid Glass: Clear / Tinted* | "Tinted" raises opacity and contrast. It can only be changed while Reduce Transparency is off [3P, Engadget/TechCrunch] |

---

## 2. ManhwaManiacs Glass tokens

These are all [MM] unless an Apple label says otherwise. The blocks are YAML so a code generator can read them.

```yaml
---
version: alpha
name: ManhwaManiacs-Glass
description: >
  Dark-only Liquid Glass + visionOS-depth skin on an AMOLED #000 canvas. Glass is the control
  layer only (bars, floating buttons, menus, sheets, toasts). Content sits on black and on standard
  materials. Capsule controls, concentric containers, Apple springs, SF Pro where the OS provides it
  and Inter everywhere else. One indigo tint, used once per screen.

colors:
  canvas: "#000000"                        # AMOLED base (owner decision)
  surface-1: "#1C1C1E"                     # Apple dark secondarySystemBackground
  surface-2: "#2C2C2E"                     # Apple dark tertiarySystemBackground
  surface-3: "#3A3A3C"                     # Apple dark systemGray4
  label: "#FFFFFF"
  label-2: "rgba(235,235,245,0.60)"        # Apple dark secondaryLabel (UIKit tables; re-sample on iOS 26)
  label-3: "rgba(235,235,245,0.30)"        # tertiaryLabel
  label-4: "rgba(235,235,245,0.18)"        # quaternaryLabel: never on thin/ultraThin
  fill-1: "rgba(120,120,128,0.36)"         # systemFill (dark)
  fill-2: "rgba(120,120,128,0.32)"
  fill-3: "rgba(118,118,128,0.24)"
  fill-4: "rgba(118,118,128,0.18)"
  separator: "rgba(84,84,88,0.60)"
  separator-opaque: "#38383A"
  tint: "#6D7CFF"                          # Apple iOS 26 dark Indigo, used as the MM brand tint
  tint-hc: "#A7AAFF"                       # Indigo, increased contrast
  on-tint: "#FFFFFF"
  blue: "#0091FF"                          # iOS 26 dark system colors (HIG Color)
  green: "#30D158"
  orange: "#FF9230"
  red: "#FF4245"
  yellow: "#FFD600"
  pink: "#FF375F"                          # 18+ marker
  purple: "#DB34F2"
  teal: "#00D2E0"
  dim-clear: "rgba(0,0,0,0.35)"            # Apple: dimming under clear glass over bright media
  dim-modal: "rgba(0,0,0,0.40)"            # alerts / interrupting tasks
  dim-sheet: "rgba(0,0,0,0.25)"            # partial-detent sheets

materials:                                  # glass = control layer; material-* = content layer
  glass-regular:        # bars, tab bar, floating buttons, toasts
    fill: "rgba(255,255,255,0.06)"
    blur: 8px            # CSS blur radius == Flutter sigma (both are the Gaussian std-dev)
    saturate: 1.8
    rim: "rgba(255,255,255,0.22)"          # 0.5px hairline
    specular: "rgba(255,255,255,0.40)"     # top-left rim light
    shadow: "0 6px 20px rgba(0,0,0,0.45)"
    bezel: 12px          # refraction band width
    thickness: 24px      # virtual slab height for the Snell calculation
    refraction-n: 1.5
  glass-regular-large:  # menus, popovers, partial sheets: "thicker" per Apple
    fill: "rgba(30,30,32,0.50)"
    blur: 20px
    saturate: 1.8
    rim: "rgba(255,255,255,0.18)"
    specular: "rgba(255,255,255,0.30)"
    shadow: "0 24px 64px rgba(0,0,0,0.60)"
    bezel: 18px
    thickness: 40px
  glass-clear:          # reader and hero-media controls only
    fill: "rgba(255,255,255,0.02)"
    blur: 1px
    saturate: 1.4
    rim: "rgba(255,255,255,0.28)"
    dim: "{colors.dim-clear}"
    bezel: 12px
    thickness: 24px
  glass-tinted:         # the ONE primary action per screen (Read / Continue)
    fill: "color-mix(in oklab, #6D7CFF 78%, transparent)"
    blur: 8px
    saturate: 1.6
    rim: "rgba(255,255,255,0.30)"
  frosted:              # capability floor, no refraction (section 9)
    fill: "rgba(28,28,30,0.62)"
    blur: 24px
    saturate: 1.8
  solid:                # Reduce Transparency / Increase Contrast
    fill: "#1C1C1E"
    fill-large: "#2C2C2E"
    border: "rgba(255,255,255,0.10)"
    border-hc: "rgba(255,255,255,0.55)"
  material-ultrathin: { fill: "rgba(28,28,30,0.40)", blur: 12px }
  material-thin:      { fill: "rgba(28,28,30,0.58)", blur: 20px }
  material-regular:   { fill: "rgba(28,28,30,0.72)", blur: 30px }
  material-thick:     { fill: "rgba(28,28,30,0.86)", blur: 40px }
  light-angle: 135deg   # highlight comes from the top-left; gyro/pointer may move it ±25deg

typography:
  family-apple: "system-ui (SF Pro Text/Display via opsz)"   # iOS app, Safari/macOS web
  family-other: "Inter Variable 4.x (opsz 14-32, OFL-1.1)"   # Android app, non-Apple web
  web-stack: '-apple-system, BlinkMacSystemFont, "Inter Variable", Inter, sans-serif'
  large-title: { size: 34, line: 41, weight: 700, tracking-sf: 0.38 }
  title-1:     { size: 28, line: 34, weight: 700, tracking-sf: 0.38 }
  title-2:     { size: 22, line: 28, weight: 700, tracking-sf: -0.26 }
  title-3:     { size: 20, line: 25, weight: 600, tracking-sf: -0.45 }
  headline:    { size: 17, line: 22, weight: 600, tracking-sf: -0.43 }
  body:        { size: 17, line: 22, weight: 400, tracking-sf: -0.43 }
  callout:     { size: 16, line: 21, weight: 400, tracking-sf: -0.31 }
  subhead:     { size: 15, line: 20, weight: 400, tracking-sf: -0.23 }
  footnote:    { size: 13, line: 18, weight: 400, tracking-sf: -0.08 }
  caption-1:   { size: 12, line: 16, weight: 400, tracking-sf: 0 }
  caption-2:   { size: 11, line: 13, weight: 500, tracking-sf: 0.06 }
  tab-label:   { size: 11, line: 13, weight: 600 }
  ax5-cap: { large-title: 60, title-1: 58, title-2: 56, title-3: 55, body: 53, caption-2: 40 }  # Apple AX5 row
  # Titles here are bolder than Apple's Dynamic Type "Regular", following iOS 26's "bolder" direction.

rounded:          # every nested pair obeys r_inner = r_outer - padding
  capsule: 9999px # all controls: buttons, chips, segmented, search, tab bar, toasts
  xs: 8px         # OCR hit box, tiny badges
  sm: 14px        # cover art inside a 26/12 card; menu rows inside a 26/6 menu (=20) -> use md
  md: 20px        # grouped list inset inside a 36/16 sheet
  lg: 26px        # cards, menus, popovers
  xl: 36px        # sheets when the device radius is unknown (3P stupid_simple_sheet default)
  sheet-rule: "device_radius - sheet_inset (8)"   # when the device radius is known
  corner-shape: squircle   # superellipse(2) on web (Chromium); RoundedSuperellipseBorder in Flutter

spacing:          # pt == px at 1x
  hairline: 0.5
  xxs: 4
  xs: 6
  sm: 8
  md: 12
  lg: 16
  xl: 20
  xxl: 24
  screen-margin: 16          # 20 on large phones and tablets
  tab-bar-inset: 21          # Apple 3P-measured
  sheet-inset: 8             # partial detents
  touch-min: 44
  control-gap-min: 8         # 16 on desktop pointer (visionOS spacing rule, scaled)

motion:            # Apple duration/bounce -> physics (mass 1). Use stiffness/damping on web.
  interactive: { duration: 0.15, dampingFraction: 0.86, stiffness: 1754.6, damping: 72.05 }  # Apple interactiveSpring
  press:       { duration: 0.25, bounce: 0.15, stiffness: 631.7, damping: 42.73 }
  snappy:      { duration: 0.50, bounce: 0.15, stiffness: 157.9, damping: 21.36 }           # Apple .snappy
  smooth:      { duration: 0.50, bounce: 0.00, stiffness: 157.9, damping: 25.13 }           # Apple .smooth (default)
  bouncy:      { duration: 0.50, bounce: 0.30, stiffness: 157.9, damping: 17.59 }           # Apple .bouncy (celebrations only)
  morph:       { duration: 0.375, bounce: 0.27, stiffness: 280.7, damping: 24.46 }          # button->menu/sheet bloom
  tab:         { duration: 0.45, bounce: 0.20, stiffness: 195.0, damping: 22.34 }           # tab droplet travel
  sheet:       { duration: 0.35, bounce: 0.00, stiffness: 322.3, damping: 35.90 }           # present/dismiss
  sheet-snap:  { duration: 0.40, bounce: 0.10, stiffness: 246.7, damping: 28.27 }           # detent after fling
  minimize:    { duration: 0.40, bounce: 0.00, stiffness: 246.7, damping: 31.42 }           # tab bar minimize
  fade-in: 180ms
  fade-out: 120ms
  glow-in: 150ms
  glow-out: 60ms
  materialize: 250ms
  dematerialize: 350ms
  reduced-crossfade: 200ms
  easing-fade: "cubic-bezier(0.2, 0, 0, 1)"     # for opacity-only fades
  press-growth: "min(17pt, 0.35 * longest_side)" # Apple-measured 17pt, capped for tiny icons
  tooltip-delay: { none: 0ms, short: 150ms, long: 600ms }   # visionOS's three levels; ms are MM
  tab-minimize-threshold: { down: 20pt, up: 12pt }         # 3P
  fling-projection: "pos + 0.5 * velocity_pt_s"            # Apple, r = 0.998

components:
  tab-bar:        { material: glass-regular, rounded: capsule, height: 64, minimized: 50, search-circle: 50, inset: 21, indicator: glass-clear-droplet }
  bottom-accessory: { material: glass-regular, rounded: capsule, height: 48, sits: "8 above tab bar; inline when minimized" }   # TTS mini-player, Continue pill
  nav-button:     { material: glass-regular, size: 44, icon: 22, rounded: capsule, group-gap: 8 }
  primary-button: { material: glass-tinted, height: 50, padding: "0 24", rounded: capsule, type: headline }
  secondary-button: { material: glass-regular, height: 44, padding: "0 18", rounded: capsule, type: headline }
  chip:           { content-layer: "fill-3 + label", height: 32, rounded: capsule, type: subhead, selected: "glass-regular + label" }
  segmented:      { track: fill-3, thumb: "glass-regular while dragging, surface-3 at rest", height: 36, rounded: capsule }
  toggle:         { track-on: tint, thumb: "glass-clear while dragging (Apple exception), #FFF at rest", size: "51x31" }
  slider:         { track: fill-2, fill: tint, thumb: "glass-clear 28 while dragging" }
  search-field:   { material: glass-regular, height: 50, rounded: capsule, placement: "bottom on phone" }
  menu:           { material: glass-regular-large, rounded: lg, padding: 6, row-radius: 20, row-height: 44, presents: "morph from trigger" }
  sheet-partial:  { material: glass-regular-large, inset: 8, radius: "device-8 | 36", barrier: dim-sheet }
  sheet-full:     { material: "solid surface-1", radius-top: 36, attached: "sides+bottom", barrier: dim-modal }
  alert:          { material: glass-regular-large, width: 300, radius: 26, barrier: dim-modal, type: "title-3 bold, left-aligned" }
  toast:          { material: glass-regular, rounded: capsule, height: 44, top: "safe-top + 8" }
  card:           { surface: canvas, media-radius: 14, card-radius: 26, padding: 12 }   # content layer: no glass
  list-row:       { surface: surface-1, grouped-radius: 20, row-height: 52, separator: separator }
  scroll-edge:    { style: soft, height: 72, blur: 6px, fade: "black 72% -> 0" }
  scroll-edge-hard: { fill: "rgba(0,0,0,0.92)", separator: separator }
---
```

---

## 3. Glass on an AMOLED black canvas

This is the one real problem, and it is ours [MM]. Liquid Glass shows what is behind it. Over pure `#000000` there is nothing to bend, so a glass bar looks like a grey smudge with a rim. Apple's own dark screens avoid this because they always have content under the chrome. Three rules make glass work on black:

1. **Chrome floats over content, never over empty black.** Every scroll view runs edge to edge under the bars, with content insets instead of padding. Covers, banners and manhwa pages are colourful, and that is what the glass bends. Empty states put their illustration where the bar would sit.
2. **Ambient field layer (z0.5).** Each screen paints two or three very soft colour blobs, taken from the focused series' cover (the dominant colours), at 18–28 % opacity with a blur of about 120 px. They sit in the top 45 % of the screen and fade to `#000` by 60 % of its height. The bottom stays true black for AMOLED. This lines up with the owner's "reader chrome tinted by dynamic color from the current page". The glass tint is derived from the same colours, as Apple maps a tint to the brightness of what's behind it. The field drifts slowly (40 s loop) and freezes under Reduce Motion.
3. **Rim and inner light carry the shape when the backdrop is dark.** The 0.5 px rim, the top-left specular gradient, and the touch glow from the finger are what make glass read as glass over black. Refraction is at its most visible over the ambient field and cover art.

The shadow follows Apple's adaptive-shadow idea in reverse. On black a shadow is invisible, so glass gets separation from its **rim**. The 45–60 % black shadow is there for when the glass floats over bright pages.

---

## 4. Layer model and screen mapping

| z | Layer | Treatment |
|---|---|---|
| 0 | Canvas | `#000000` |
| 0.5 | Ambient field | Cover-derived colour blobs (section 3) |
| 1 | Content | Covers, rails, rows, reader pages. Surfaces `surface-1/2`, `material-*`. **No Liquid Glass** |
| 2 | Scroll edge | Soft effect under the top bar and above the tab bar. Hard under pinned headers |
| 3 | Controls | `glass-regular` bars, nav buttons, floating buttons, bottom accessory. One glass container per bar group |
| 4 | Overlays | Menus/popovers (`glass-regular-large`, morphing out of the trigger), partial sheets (glass), full sheets (solid) |
| 5 | Interruptions | Alerts and action sheets with `dim-modal`. Action sheets spring from their source |
| 6 | HUD | Toasts and download progress (`glass-regular` capsule) |

How each screen uses the layers [MM]:

- **Home** (Netflix-style browse). The hero spotlight is media, so its title controls use `glass-clear` plus a gradient dim (`dim-clear` at the bottom 40 % of the hero). Rails sit in the content layer. The top bar is `glass-regular` nav buttons with no bar background, and the scroll edge is soft.
- **Library / Updates / Downloads.** Grids and rows sit in the content layer. The filter row is **chips in the content layer** (fills). A chip only becomes glass while it is being dragged, which is Apple's transient-control exception. The sort control is a nav button that opens a `menu` by morphing.
- **Series detail.** The cover zooms in from the tapped card (see 5.8 and 6.5). The **Read / Continue** button is the screen's single `glass-tinted` action. The chapter list sits in the content layer. The 18+ badge uses `pink` fill, never glass.
- **Manhwa reader** (Webtoon-style). Chrome auto-hides. Pages are often bright white and are the thing being read, and dimming them would hurt, so Apple's third condition fails: the reader uses **`glass-regular`, not clear**. The next-chapter card is content (`surface-1`, radius 26).
- **Novel reader + TTS.** Apple Books style. Page themes belong to the content layer. The TTS player is the **tab-bar bottom accessory** (like the Music mini-player): it goes inline when the bar minimizes and expands into a `sheet-partial` with the 31-voice picker (menu rows at 44 pt).
- **Search / OCR.** Search is the `Tab(role: .search)` circle. It expands into a bottom `search-field`. OCR hit boxes on pages are content (`tint` 2 px outline, radius 8). Moving to the next hit plays a selection haptic.
- **Settings / Profiles / 18+ gate.** Grouped `list-row`s on `surface-1`. The profile switcher is a `sheet-partial` at the medium detent. The PIN pad is content-layer fills, not glass: keys are 72 pt circles in `fill-2`.
- **Desktop web.** An inset glass **sidebar** (Apple: "Sidebars are now inset and built with Liquid Glass"), with content extending under it. The wide reader's side panels are `material-thick` in the content layer. Only the floating toolbars are glass.

---

## 5. Web implementation (Next.js 16, React 19, Tailwind 4, Motion 12.42.2)

The installed versions are `framer-motion` 12.42.2 and `motion-dom` 12.42.2 (checked in `frontend/node_modules`). **No new dependencies are needed.** Everything below uses CSS, SVG and the existing Motion.

### 5.1 Skin tokens (Tailwind 4 `@theme inline` + `data-skin`)

The skin is picked in Settings and the app restarts, so the root layout sets `data-skin` on `<html>` from a cookie, and each skin fills the same CSS variables.

```css
/* app/globals.css */
@import "tailwindcss";

@theme inline {
  --color-canvas: var(--mm-canvas);
  --color-surface-1: var(--mm-surface-1);
  --color-label: var(--mm-label);
  --color-label-2: var(--mm-label-2);
  --color-tint: var(--mm-tint);
  --radius-card: var(--mm-radius-card);
  --font-sans: var(--mm-font);
}

[data-skin="glass"] {
  --mm-canvas: #000;
  --mm-surface-1: #1c1c1e;
  --mm-label: #fff;
  --mm-label-2: rgb(235 235 245 / .6);
  --mm-tint: #6d7cff;
  --mm-radius-card: 26px;
  --mm-font: -apple-system, BlinkMacSystemFont, "Inter Variable", Inter, sans-serif;
  --glass-fill: rgb(255 255 255 / .06);
  --glass-blur: 8px;
  --glass-sat: 1.8;
  --glass-rim: rgb(255 255 255 / .22);
  --glass-spec: rgb(255 255 255 / .40);
  --light-angle: 135deg;
}
```

Type: `html { font-size: 100% }` and all sizes in `rem` (17 px = 1.0625rem), so browser text zoom works. It is the web's version of Dynamic Type. `font-optical-sizing: auto` lets both SF (on Apple devices) and Inter 4 pick their optical size. For Inter, tighten tracking with size: Inter's published dynamic-metrics formula is `tracking_em = −0.0223 + 0.185·e^(−0.1745·px)`, which gives about −0.013 em at 17 px and −0.022 em at 34 px (constants from rsms.me/inter/dynmetrics; re-check them). Do **not** reuse SF's positive Display tracking on Inter.

Desktop sizes [MM]: body 15, callout 14, subhead 13, footnote 12, headline 15/600, title-3 20, title-2 24, title-1 32, large-title 40. macOS's 13 pt body is too small for a reading app.

### 5.2 The glass recipe in three tiers

```css
.glass {                                   /* tier B, "frosted": every browser */
  position: relative; isolation: isolate;
  background: var(--glass-fill);
  -webkit-backdrop-filter: blur(8px) saturate(1.8);   /* Safari <18: hard-coded, no var() */
  backdrop-filter: blur(var(--glass-blur)) saturate(var(--glass-sat));
  box-shadow:
    inset 0 0 0 .5px var(--glass-rim),
    0 6px 20px rgb(0 0 0 / .45);
  corner-shape: squircle;                  /* Chromium 139+; ignored elsewhere */
}
.glass[data-liquid] {                      /* tier A, "liquid": Chromium only, set by JS */
  backdrop-filter: url(#lg-44x44-r22);     /* per-size filter, see 5.3 */
}
@media (prefers-reduced-transparency: reduce), (prefers-contrast: more) {
  .glass, .glass[data-liquid] {            /* tier C, "solid" */
    backdrop-filter: none; -webkit-backdrop-filter: none;
    background: #1c1c1e;
    box-shadow: inset 0 0 0 1px rgb(255 255 255 / .10);
  }
}
@media (prefers-contrast: more) {
  .glass { box-shadow: inset 0 0 0 1px rgb(255 255 255 / .55); }
}
```

Why the liquid tier needs JavaScript detection: only Chromium renders SVG filters inside `backdrop-filter`. **Firefox parses `url()` as valid, passes `@supports`, and then renders nothing.** WebKit has an open bug (#245510). Detect Chromium by the one API only Chromium ships:

```ts
export const liquidCapable = () =>
  !!(navigator as any).userAgentData?.brands?.some((b: { brand: string }) => b.brand === "Chromium");
```

### 5.3 Refraction: generating the SVG displacement map

The method follows kube.io's *Liquid Glass in the Browser* (2025-10-04): a convex-squircle bezel profile `y = ⁴√(1 − (1 − x)⁴)`, Snell refraction at n = 1.5, 128 samples along one radius, rotated around the shape, and encoded as R = x and G = y, with 128 meaning no displacement. The code below is our own. **kube.io's repository has no license file, so read it for the technique and do not copy its code.**

```ts
// lib/glass/liquid-map.ts
const surface = (x: number) => Math.pow(1 - Math.pow(1 - x, 4), 0.25); // 0 at rim -> 1 at flat top

export function liquidMap(w: number, h: number, radius: number, bezel: number, thickness: number, n = 1.5) {
  const N = 128, mag = new Float32Array(N);
  for (let i = 0; i < N; i++) {               // displacement (px) vs distance from the rim
    const x = (i + 0.5) / N, e = 0.5 / N;
    const slope = ((surface(Math.min(1, x + e)) - surface(Math.max(0, x - e))) / (2 * e)) * (thickness / bezel);
    const t1 = Math.atan(slope), t2 = Math.asin(Math.sin(t1) / n);
    mag[i] = surface(x) * thickness * Math.tan(t1 - t2);
  }
  const max = Math.max(...mag) || 1;
  const img = new ImageData(w, h), hx = w / 2, hy = h / 2, r = Math.min(radius, hx, hy);
  for (let py = 0; py < h; py++) for (let px = 0; px < w; px++) {
    const x = px + 0.5 - hx, y = py + 0.5 - hy;
    const qx = Math.abs(x) - (hx - r), qy = Math.abs(y) - (hy - r);
    let d: number, nx = 0, ny = 0;            // d = distance in from the rim; n = outward normal (abs)
    if (qx > 0 && qy > 0) { const l = Math.hypot(qx, qy); d = r - l; nx = qx / l; ny = qy / l; }
    else if (qx > qy) { d = r - qx; nx = 1; } else { d = r - qy; ny = 1; }
    const k = d > 0 && d < bezel ? mag[Math.min(N - 1, ((d / bezel) * N) | 0)] / max : 0;
    const o = (py * w + px) * 4;
    img.data[o] = 128 - Math.sign(x) * nx * k * 127;       // sample inward (convex lens)
    img.data[o + 1] = 128 - Math.sign(y) * ny * k * 127;
    img.data[o + 2] = 128; img.data[o + 3] = 255;
  }
  return { img, scale: 2 * max }; // feDisplacementMap moves by scale × (C/255 − 0.5)
}
```

```tsx
// One <filter> per (w, h, radius) combination, cached. Rebuild on ResizeObserver with a 100 ms debounce.
<svg width="0" height="0" aria-hidden style={{ position: "absolute" }}>
  <filter id={id} x="0" y="0" width={w} height={h} filterUnits="userSpaceOnUse"
          colorInterpolationFilters="sRGB">                      {/* required, or 128 stops being neutral */}
    <feGaussianBlur in="SourceGraphic" stdDeviation={blur} result="b" />
    <feImage href={mapDataUrl} x="0" y="0" width={w} height={h} result="m" />
    <feDisplacementMap in="b" in2="m" scale={scale * lensing} xChannelSelector="R" yChannelSelector="G" result="d" />
    <feColorMatrix in="d" type="saturate" values="1.8" />
  </filter>
</svg>
```

Three details matter:

- `colorInterpolationFilters="sRGB"` is mandatory. The default, linearRGB, shifts the map's values.
- Per the SVG spec, the pixel shift is `scale × (C/255 − 0.5)`. To shift by `max` px you need `scale = 2·max`. kube.io's text maps 255 to the full `scale`, so check this on screen.
- Animate `scale` rather than regenerating the map: `lensing` 0 → 1 is how glass **materializes** (Apple: "modulating the light bending"). A larger glass uses a bigger `bezel`/`thickness` (the `glass-regular-large` tokens), which gives Apple's "more pronounced lensing" for free.

Bezel and thickness per component [MM]: nav button 44 → bezel 10 / thickness 20; tab bar 64 → 12 / 24; menu and sheet → 18 / 40.

Performance: the map is rebuilt only when a size changes. Tab-bar minimize animates width, so that transition uses the frosted tier and switches back to liquid when it settles. Pay the rebuild cost only at rest (kube.io notes that anything except animating `scale` forces a rebuild).

### 5.4 Specular rim and touch glow

```css
.glass::before {                            /* directional rim light */
  content: ""; position: absolute; inset: 0; border-radius: inherit; padding: 1px; pointer-events: none;
  background: linear-gradient(var(--light-angle),
      var(--glass-spec), rgb(255 255 255 / .06) 35%, rgb(255 255 255 / .02) 65%, rgb(255 255 255 / .22));
  mask: linear-gradient(#000 0 0) content-box, linear-gradient(#000 0 0);
  mask-composite: exclude;
}
.glass::after {                             /* "illuminates from within", starting under the finger */
  content: ""; position: absolute; inset: 0; border-radius: inherit; pointer-events: none;
  background: radial-gradient(140px circle at var(--mx, 50%) var(--my, 50%), rgb(255 255 255 / .16), transparent 60%);
  opacity: 0; transition: opacity 60ms linear;               /* glow-out */
}
.glass[data-pressed]::after { opacity: 1; transition-duration: 150ms; } /* glow-in */
```

`--mx`/`--my` are set on `pointerdown` and `pointermove`, and only while the pointer is pressed or hovering over the element (no global listeners). On desktop, `:hover` uses the same layer at 0.08 opacity with no delay. That is the visionOS "highlight" hover. `--light-angle` can follow the pointer across the viewport (±25°) for the "lights move" effect. It stays static under reduced motion.

### 5.5 Shapes and concentricity

```css
.card  { --r: 26px; --p: 12px; border-radius: var(--r); padding: var(--p); corner-shape: squircle; }
.card > .media { border-radius: max(calc(var(--r) - var(--p)), 4px); corner-shape: squircle; }  /* = 14px */
```

`corner-shape: squircle` means `superellipse(2)` and is supported in Chromium 139+ only. Safari and Firefox fall back to a circular radius, which is acceptable. Don't add a clip-path polyfill (YAGNI). Controls use `border-radius: 9999px`, a capsule, and never `corner-shape`, because a capsule's end is already a semicircle.

### 5.6 Springs in Motion

```ts
// lib/glass/motion.ts
import type { Transition } from "framer-motion";
const s = (stiffness: number, damping: number): Transition => ({ type: "spring", stiffness, damping, mass: 1 });

export const glassSpring = {
  interactive: s(1754.6, 72.05), press: s(631.7, 42.73), snappy: s(157.9, 21.36),
  smooth: s(157.9, 25.13), bouncy: s(157.9, 17.59), morph: s(280.7, 24.46),
  tab: s(195.0, 22.34), sheet: s(322.3, 35.9), sheetSnap: s(246.7, 28.27), minimize: s(246.7, 31.42),
} as const;
```

Use **stiffness/damping, not `duration`/`bounce`/`visualDuration`**, for two reasons found in `motion-dom` 12.42.2's `spring.mjs`:

1. Duration-defined springs **zero the inherited velocity** ("Time-defined springs should ignore inherited velocity"). Physics springs keep it. That matches Apple's rule that a retargeted spring keeps its velocity.
2. `visualDuration` sets `ω = 2π / (visualDuration × 1.2)`, so an Apple duration `d` would need `visualDuration = d / 1.2`. Motion's `bounce` also clamps the damping ratio to [0.05, 1], so Apple's negative (flattened) bounces can't be expressed that way.

Wrap the app in `<MotionConfig reducedMotion="user" transition={glassSpring.smooth}>`. Under the OS setting, Motion then drops transform and layout animations and keeps opacity and colour, which is Apple's "disables elastic properties" (see section 8).

### 5.7 Press, hover, focus

- **Press:** on `pointerdown`, `scale = 1 + min(17, 0.35·max(w, h)) / max(w, h)`, driven by `glassSpring.press`. It springs back with the same spring. Add brightness through the glow layer. **Do not lower opacity.** While pressed, pointer movement stretches the control up to 6 % along the drag axis (`scaleX = 1 + 0.06·clamp(dx/w)`), with the other axis at `1/√scaleX` so the volume looks preserved. It follows with `glassSpring.interactive`.
- **Hover** (pointer devices only, `@media (hover: hover)`): the highlight layer at 0.08, no delay. Cards lift (visionOS `.lift`): `translateY(-2px)`, shadow `0 12px 32px rgb(0 0 0/.5)`, `glassSpring.snappy`. Text never gets depth (Apple). Tooltip delays follow the three visionOS levels: 0 / 150 / 600 ms.
- **Focus** (keyboard first on desktop): `outline: 2px solid var(--color-tint); outline-offset: 2px`. Browsers draw outlines along `border-radius`, so the ring stays concentric with the element.

### 5.8 Tab bar (mobile web) and sidebar (desktop)

- A capsule `glass` bar, fixed at `bottom: calc(env(safe-area-inset-bottom) + 21px)`, `inset-inline: 21px`, 64 px tall. The Search circle (50 px) sits separately at the trailing end.
- **Selection droplet:** a `motion.div layoutId="tab-droplet"` using `glassSpring.tab`. While the user drags across the bar, it follows with `glassSpring.interactive` and stretches `scaleX = 1 + clamp(|velocityX| / 2000, 0, 0.25)` using `useVelocity`. It switches to `glass-clear` while lifted. Each tab it crosses plays a selection haptic (where the platform has one).
- **Minimize:** after 20 px of downward scroll, animate to a 50 px capsule showing only the selected icon (`glassSpring.minimize`). After 12 px of upward scroll, expand again. The TTS / Continue **bottom accessory** moves inline between the capsule and the search circle.
- **Cover → detail zoom**, the equivalent of `.navigationTransition(.zoom)`: shared `layoutId={"cover-" + id}` on the card image and the detail hero, using `glassSpring.smooth`. The rest of the detail page fades in over 180 ms.
- **Desktop:** an inset glass sidebar 280 px wide, `inset: 12px`, radius 26, with content scrolling underneath. Keyboard: `g h/l/u/s` jumps to the main sections, and `⌘K`/`Ctrl K` opens search as a centred glass-regular-large panel that morphs out of the sidebar search field.

### 5.9 Sheets and menus

- **Phone-width sheets:** a `motion.div` with `drag="y"`, snapping to three detents: `peek 96 px`, `medium 50vh`, `large calc(100dvh − safe-top − 10px)`. On drag end, `target = nearestDetent(y + 0.5·velocity.y)`, animated with `glassSpring.sheetSnap`. Over the last 20 % of the travel to `large`, the inset lerps 8 → 0 and the material crossfades glass → solid (Apple: opaque and attached at full height). The edges rubber-band with `dragElastic: 0.15`. `vaul` would do this too, but Motion is already installed, so it isn't worth a dependency.
- **Desktop sheets** become centred form panels (560 px, radius 36) that morph out of their trigger.
- **Menus and popovers:** they bloom out of the trigger. Use a shared `layoutId` on the trigger's glass and the menu body with `glassSpring.morph`. The content fades in over the last 40 % (`materialize` 250 ms). Closing reverses the path in `dematerialize` 350 ms.
- **Stacking:** at most two sheets. A lower sheet at `large` scales to `0.9165` (1 − 0.0835) and moves up 2 %. A lower partial sheet drops to 70 % brightness. Only the bottom-most sheet blurs the backdrop.

### 5.10 Scroll edge effect

```css
.edge-top {                                         /* soft, one per edge */
  position: sticky; top: 0; z-index: 2; pointer-events: none;
  height: calc(env(safe-area-inset-top) + 72px); margin-bottom: calc(-1 * (env(safe-area-inset-top) + 72px));
  backdrop-filter: blur(6px);
  mask-image: linear-gradient(to bottom, #000 40%, transparent);
  background: linear-gradient(to bottom, rgb(0 0 0 / .72), transparent);
}
.edge-top[data-hard] { backdrop-filter: none; mask-image: none; background: rgb(0 0 0 / .92);
  box-shadow: 0 .5px 0 rgb(84 84 88 / .6); }
```

A mirrored `.edge-bottom` sits behind the tab bar. For a smoother progressive blur, stack three layers (blur 2 / 6 / 14 px, masked 0–100 %, 0–66 %, 0–33 %) and only add them if the single layer bands visibly.

### 5.11 Haptics on the web

- Android Chrome: `navigator.vibrate`, used for only four events: toggle `10`, success `[12, 60, 12]`, error `[24, 50, 24, 50, 24]`, long-press menu `18`. Nothing on scroll or navigation.
- iOS Safari has no Vibration API. The `<input type="checkbox" switch>` trick (npm `ios-haptics`) only works from a real tap and was patched for programmatic use in iOS 26.5, so **skip it**. iPhone users get haptics from the Flutter app.
- Desktop: none.

### 5.12 Accessibility on the web

`prefers-reduced-motion` → `MotionConfig reducedMotion="user"`, plus the rules in section 8. `prefers-reduced-transparency` (Chromium 118+; progressive only) → tier C. `prefers-contrast: more` → tier C plus a 1 px border at 55 % and `tint-hc`. An in-app **Solid glass** toggle in Settings forces tier C, because Safari and Firefox don't all expose reduced transparency.

---

## 6. Flutter implementation (Flutter 3.44.6, Impeller, Riverpod, go_router)

CI pins Flutter **3.44.6** (checked in the repo's CI config). `pubspec.yaml` still says `flutter: '>=3.22.0'`. Raise that to `>=3.41.0`, which the packages below require.

### 6.1 Packages

| Package | Version | License | Needs | Use |
|---|---|---|---|---|
| `liquid_glass_widgets` (github.com/sdegenaar/liquid_glass_widgets) | 1.7.2 | MIT | Flutter ≥3.41, zero deps | **The glass engine.** Tab bar with minimize, modal sheet with detents and morph-from-trigger, buttons with native press growth, menus, switch/slider/segmented, quality tiers, accessibility scope, gyro lighting |
| `liquid_glass_renderer` (github.com/whynotmake-it/flutter_liquid_glass) | 0.2.0-dev.4 | MIT | Flutter ≥3.32.4, **Impeller only** | Raw renderer for custom glass shapes and blend groups (max 16 shapes). Only if (1) can't draw a shape we need |
| `motor` (whynotmake-it/rivership) | 1.1.0 | MIT | Flutter ≥3.32 | Optional: `CupertinoMotion` presets and multi-dimensional springs. `SpringDescription.withDurationAndBounce` in the SDK covers most needs |
| `heroine` (whynotmake-it/rivership) | 0.7.2 | MIT | Flutter ≥3.27 | Spring-driven hero for the cover → detail zoom (Apple's zoom transition) |
| `stupid_simple_sheet` (whynotmake-it/rivership) | 1.0.0-dev.4 | MIT | Flutter ≥3.10 | Fallback only if GlassModalSheet's scroll→drag handoff misbehaves in long chapter lists. Its glass route uses smooth 350 ms, a 36 px superellipse top, a 15 % black barrier, and `SheetSnappingConfig([0.5, 1.0])` |
| `sensors_plus` | latest | BSD-3-Clause | | Gyro stream for specular lighting (optional) |

Deliberately **not** used: Flutter's `CupertinoSheetRoute`. It is the iOS 18 full-height card stack (8 % top gap, 0.0835 scale-down, 500 ms `fastEaseInToSlowEaseOut`), with no detents and no glass. `smooth_sheets` 1.2.0 (MIT) is not needed once the glass sheet exists.

### 6.2 Materials and shapes

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();          // precompiles shaders (avoids first-frame jank)
  runApp(LiquidGlassWidgets.wrap(child: const App()));
}
```

- **Quality:** `GlassQuality.premium` (full refraction: two-pass shader, `refract()`, specular, chromatic aberration) for **static** chrome: tab bar, nav buttons, menus, sheets. `standard` (the lightweight shader) for anything inside a scroll view, because premium's texture capture doesn't follow the scroll position [3P docs]. That is the whole quality policy. The owner's decision rules out adaptive downgrading, so leave `adaptiveQuality` off.
- **Token mapping** (liquid_glass_widgets / renderer settings) [MM]: `glass-regular` → thickness 24, blur 3, refractiveIndex 1.15, lightIntensity 0.5, saturation 1.5, glassColor `0x0FFFFFFF`. `glass-regular-large` → thickness 40, blur 12, glassColor `0x801E1E20`. `glass-clear` → thickness 24, blur 0, glassColor `0x05FFFFFF`, with a `Container(color: Color(0x59000000))` dim layer under media only. The library defaults are thickness 30, blur 3, refractiveIndex 1.15, light angle 0.75π. The renderer defaults are thickness 20, blur 5, refractiveIndex 1.2, saturation 1.5, chromatic aberration 0.01. Treat all of these as calibration knobs.
- **Content-layer materials:** `BackdropFilter.grouped(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), child: ColoredBox(color: Color(0x941C1C1E)))` inside one `BackdropGroup` per screen. The group shares a single backdrop read across all the grouped filters, which is the Impeller optimisation in Flutter ≥3.29. A Flutter `sigma` equals a CSS `blur()` radius, so the token values carry over unchanged.
- **Shapes:** `RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(26))` and `ClipRSuperellipse` (both in the SDK). Concentric helper: `double concentric(double outer, double pad) => math.max(outer - pad, 4);`
- **Device corner radius** for sheet insets: `liquid_glass_widgets` resolves it adaptively (for example, 53 pt on iPhone 15 Pro Max). Otherwise use 36.

### 6.3 Springs

```dart
abstract final class GlassSprings {
  static const interactive = SpringDescription(mass: 1, stiffness: 1754.6, damping: 72.05);
  static final press     = SpringDescription.withDurationAndBounce(duration: const Duration(milliseconds: 250), bounce: .15);
  static final snappy    = SpringDescription.withDurationAndBounce(bounce: .15);   // 500 ms default
  static final smooth    = SpringDescription.withDurationAndBounce();              // 500 ms, 0
  static final bouncy    = SpringDescription.withDurationAndBounce(bounce: .3);
  static final morph     = SpringDescription.withDurationAndBounce(duration: const Duration(milliseconds: 375), bounce: .27);
  static final tab       = SpringDescription.withDurationAndBounce(duration: const Duration(milliseconds: 450), bounce: .2);
  static final sheet     = SpringDescription.withDurationAndBounce(duration: const Duration(milliseconds: 350));
  static final sheetSnap = SpringDescription.withDurationAndBounce(duration: const Duration(milliseconds: 400), bounce: .1);
}

// Retarget without losing momentum (Apple's velocity rule):
controller.animateWith(SpringSimulation(GlassSprings.snappy, controller.value, target, controller.velocity));

// Detent choice after a fling (Apple projection, r = 0.998):
double project(double pos, double velocityPxPerS) => pos + velocityPxPerS / 1000 * .998 / (1 - .998);
```

The factory is exact Apple math. The SDK source uses `stiffness = 4π²m/d²` and `dampingRatio = 1 − bounce`, or `1 / (1 + bounce)` for negative bounce.

### 6.4 Sheets

`GlassModalSheet.show(context:, morphFrom: anchor, builder: …)` [3P API]. Settings [MM]: `peekSize: 96`, `halfSize: 0.5`, `fullSize: null` (the library default is `(h − 90)/h`), `horizontalMargin: 8`, `bottomMargin: 8` (it lerps to 0 over the last 20 % toward full), `fullTopBorderRadius: 36`, `morphSpeed: MorphSpeed.normal` (375 ms), `barrierColor: Color(0x40000000)`, `suppressInteractionOnChildren: true` for forms and the voice picker. Any list inside the sheet uses the provided `ScrollControllerProvider.of(context)` controller and physics so scrolling hands off to the sheet drag.

### 6.5 Tab bar and navigation

- `GlassTabBar` with `barHeight: 64` and `minimizedBarHeight: 50`, the search variant (`searchBarHeight: 50`), and the minimize controller (20 / 12 pt thresholds). Wire it to go_router's `StatefulShellRoute.indexedStack`, so each tab keeps its own stack.
- The bottom accessory (TTS mini-player / Continue pill) is our own 48 pt `GlassContainer` capsule. It moves inline by reading the minimize controller's value.
- Cover → detail zoom: `heroine`'s `Heroine(tag:, motion: …)` with `GlassSprings.smooth`, the equivalent of Apple's `.zoom`.

### 6.6 Haptics

Flutter 3.44.6's `HapticFeedback` has `lightImpact`, `mediumImpact`, `heavyImpact`, `selectionClick`, `vibrate`, `successNotification`, `warningNotification` and `errorNotification`. From the engine source:

| Flutter call | iOS | Android |
|---|---|---|
| `lightImpact` | Impact `.light` | `VIRTUAL_KEY` |
| `mediumImpact` | Impact `.medium` | `KEYBOARD_TAP` |
| `heavyImpact` | Impact `.heavy` | `CONTEXT_CLICK` |
| `selectionClick` | `UISelectionFeedbackGenerator` | `CLOCK_TICK` |
| `successNotification` | Notification `.success` | `CONFIRM` (API 30+, **no-op below**) |
| `warningNotification` | Notification `.warning` | `KEYBOARD_TAP` (API 30+) |
| `errorNotification` | Notification `.error` | `REJECT` (API 30+) |

The core API has **no `soft`, no `rigid` and no intensity**, and it can't use Android 14's better constants. One small method channel (`mm/haptics`) fills those gaps instead of adding a dependency:

```swift
// ios/Runner/AppDelegate.swift (inside didFinishLaunching)
let ch = FlutterMethodChannel(name: "mm/haptics", binaryMessenger: controller.binaryMessenger)
let styles: [String: UIImpactFeedbackGenerator.FeedbackStyle] = ["light": .light, "medium": .medium, "heavy": .heavy, "soft": .soft, "rigid": .rigid]
ch.setMethodCallHandler { call, result in
  let a = call.arguments as? [String: Any] ?? [:]
  switch call.method {
  case "impact":
    UIImpactFeedbackGenerator(style: styles[a["style"] as? String ?? ""] ?? .light)
      .impactOccurred(intensity: CGFloat(a["intensity"] as? Double ?? 1))
    result(nil)
  case "reduceTransparency": result(UIAccessibility.isReduceTransparencyEnabled)
  default: result(FlutterMethodNotImplemented)
  }
}
```

On Android, the same channel maps `impact:soft` → `VIRTUAL_KEY`, `impact:rigid` → `CONTEXT_CLICK`, `segment` → `SEGMENT_TICK` (API 34, else `CLOCK_TICK`), `toggle` → `TOGGLE_ON`/`TOGGLE_OFF` (API 34, else `VIRTUAL_KEY`), and `threshold` → `GESTURE_THRESHOLD_ACTIVATE` (API 34, else `CONTEXT_CLICK`), all through `view.performHapticFeedback(...)`. The minSdk is 24, so every API-30/34 constant needs its version guard. The full event table is in section 7.

### 6.7 Typography

- **iOS:** font families `CupertinoSystemText` below 20 pt and `CupertinoSystemDisplay` at 20 pt and above. These are the SDK's aliases for SF Pro Text/Display, so no font is bundled. Use the tracking values from section 1.9.
- **Android:** bundle **Inter Variable 4.x** (OFL-1.1, rsms/inter) and pass `fontVariations: [FontVariation('opsz', size.clamp(14, 32)), FontVariation('wght', weight)]`.
- **Dynamic Type:** Flutter's iOS engine turns the content size into **one linear factor based on Body** (xS 14/17 … AX5 53/17 ≈ 3.12×, checked in `FlutterViewController.mm`). Apple scales large styles far less, so an unclamped Large Title would reach 106 pt at AX5 where Apple uses 60 pt. Rule: `size = min(base × scaler, ax5Cap[style])`, using the `ax5-cap` tokens. Body styles scale linearly. Titles are capped.

### 6.8 Accessibility flags

| Need | Flutter source |
|---|---|
| Reduce Motion | `MediaQuery.disableAnimationsOf(context)` (iOS and Android "Remove animations"), plus `PlatformDispatcher.instance.accessibilityFeatures.reduceMotion` (iOS only) |
| Increase Contrast | `MediaQuery.highContrastOf(context)` (iOS only) |
| Reduce Transparency | **Not exposed by Flutter.** Read it through `mm/haptics.reduceTransparency` (iOS) and feed `GlassAccessibilityScope(reduceTransparency: …)`. Android has no system flag, so use the in-app **Solid glass** toggle |
| Bold Text | `MediaQuery.boldTextOf(context)` (iOS, Android 31+) → +100 on every weight |

`liquid_glass_widgets` already snaps springs under Reduce Motion and swaps to a frosted panel under High Contrast. It only approximates Reduce Transparency using High Contrast, which is why the channel above exists.

### 6.9 Lighting that follows the device

`GlassMotionScope(stream: gyroscopeEventStream().map((e) => e.y * .5), child: …)` moves the specular angle (Apple: "the lighting responds to device motion"). Clamp it to ±25° and turn it off under Reduce Motion.

---

## 7. Haptic vocabulary for the Glass skin

These are [MM] choices that stay inside Apple's documented meanings. Everything goes through one `GlassHaptics` class, which honours the in-app **Haptics** toggle (Apple: make them optional) and rate-limits to one call per 50 ms. Haptics stay on under Reduce Motion, because they aren't motion.

| Event | iOS | Flutter | Android (API 34 / older) | Android web |
|---|---|---|---|---|
| Tab tapped (selection changes) | selection | `selectionClick` | `CLOCK_TICK` | none |
| Tab droplet dragged across a tab | selection | `selectionClick` | `SEGMENT_TICK` / `CLOCK_TICK` | none |
| Segmented control, page-mode stepper, TTS speed, voice picker scroll | selection | `selectionClick` | `SEGMENT_TICK` / `CLOCK_TICK` | none |
| Toggle flips (including the 18+ content toggle) | impact light | `lightImpact` | `TOGGLE_ON`/`OFF` / `VIRTUAL_KEY` | `vibrate(10)` |
| Primary tinted action pressed (Read, Continue, Download) | impact soft, 0.7 | channel `soft` | `VIRTUAL_KEY` | none |
| Long-press → context menu blooms | impact medium | `mediumImpact` | `LONG_PRESS` | `vibrate(18)` |
| Drag-reorder: lift / drop (collections, queue) | impact medium / light | `mediumImpact` / `lightImpact` | `DRAG_START` / `VIRTUAL_KEY` | none |
| Sheet snaps to a detent after a fling | impact soft, 0.5 | channel `soft` | `GESTURE_END` (API 30) / none | none |
| Sheet or reader dragged past the dismiss threshold | impact rigid, 0.6 | channel `rigid` | `GESTURE_THRESHOLD_ACTIVATE` / `CONTEXT_CLICK` | none |
| Pull-to-refresh armed | impact medium | `mediumImpact` | `GESTURE_THRESHOLD_ACTIVATE` / `KEYBOARD_TAP` | none |
| Reader reaches the chapter end; next-chapter card locks in | impact rigid, 0.8 | channel `rigid` | `CONTEXT_CLICK` | none |
| Auto-scroll speed step, OCR next/previous hit | selection | `selectionClick` | `SEGMENT_TICK` / `CLOCK_TICK` | none |
| Added to library, download finished, bookmark saved, streak milestone | success | `successNotification` | `CONFIRM` (API 30) | `vibrate([12,60,12])` |
| Offline, storage nearly full, source rate-limited | warning | `warningNotification` | `KEYBOARD_TAP` (API 30) | none |
| Wrong 18+ PIN, source error, download failed | error | `errorNotification` | `REJECT` (API 30) | `vibrate([24,50,24,50,24])` |
| Profile switched | impact medium | `mediumImpact` | `CONFIRM` | none |

These events **never** trigger a haptic: plain navigation taps, scrolling, page turns (except at the chapter end), hover, focus, and toasts appearing.

---

## 8. Reduced-motion rules

Apple's intent is to lower intensity and remove elasticity. User-initiated direct manipulation still follows the finger.

| Behaviour | Default | Reduce Motion |
|---|---|---|
| Press | +17 pt growth, `press` spring, stretch | No scale, no stretch. The glow alone gives feedback (150 ms / 60 ms) |
| Glass flex / jelly / droplet stretch | On | **Off** |
| Menu / sheet morph out of the trigger | `morph` spring along a path | `reduced-crossfade` 200 ms in place, no path |
| Sheet present / dismiss | `sheet` spring slide | 200 ms fade at the target detent. Dragging still follows the finger. Release uses `smooth` (bounce 0) |
| Push navigation, cover → detail zoom | Shared-element zoom, `smooth` | 200 ms crossfade |
| Tab droplet travel | `tab` spring | Jumps to the new tab. The droplet crossfades in over 150 ms |
| Tab bar minimize | `minimize` spring | Swaps with a 150 ms fade |
| Materialize (lensing 0 → 1) | 250 ms | Instant lensing, opacity fade 200 ms |
| Specular following gyro / pointer, ambient field drift | On | Static light at 135°, field frozen |
| Hover lift (desktop) | −2 px + deeper shadow | Highlight only, no movement |
| Heading letter reveal, 50 ms/char typing reveal (owner signatures) | On | Whole line fades in over 200 ms; text shown immediately |
| Novel page-turn animation | Slide/curl | Crossfade 200 ms |
| Reader auto-scroll, drag-to-scroll | User feature | Kept (the user asked for this motion) |
| Scroll edge effect, haptics | On | Kept |

---

## 9. Capability floor (not a low-end design tier)

This matches the owner's decision: there is no designed "lite" look, no benchmarking, and no adaptive downgrade. Glass drops a tier **only** when the effect can't be drawn, or when the user asked for less transparency.

| Trigger | Web | Flutter | Result |
|---|---|---|---|
| Renderer can't refract: Firefox, Safari (no `url()` in `backdrop-filter`), Skia (`ui.ImageFilter.isShaderFilterSupported == false`) | tier B `frosted` | `GlassQuality.minimal`/`standard` (the library caps premium automatically) | Blur + saturate + rim + glow. Same shapes, motion and layout |
| Reduce Transparency (OS on iOS/macOS; the in-app **Solid glass** toggle everywhere) | tier C `solid` | `GlassAccessibilityScope(reduceTransparency: true)` | `#1C1C1E` / `#2C2C2E` fills, 10 % rim, hard scroll edges |
| Increase Contrast | tier C + 1 px border at 55 % + `tint-hc` | `highContrast` → frosted panel + border | Black/white, contrasting border (Apple) |
| Blur disabled entirely (`backdrop-filter` unsupported, which is effectively no current browser) | tier C | n/a | Same as solid |

A device with no blur at all therefore gets **tier C**. That is the "no-blur low-end Android" case the task asked about. It is the same solid skin that accessibility uses, so it costs no extra design work.

---

## 10. Verify before shipping

1. Re-measure on an iOS 26 device and update the [3P] values: sheet corner radius (40?), tab-bar height (64?), and the 21 pt inset. Re-read SF tracking for 11/12/13/16/20/22/28 pt from the iOS 26 Figma kit. Re-sample `label-2`–`label-4` and the fill alphas on iOS 26.
2. Check the `feDisplacementMap` scale factor (`2·max` per the SVG spec) against kube.io's `max` with a checkerboard backdrop.
3. `liquid_glass_widgets` 1.7.2 is recent (2026-09-25). Pin the exact version and read its CHANGELOG before any upgrade.
4. Confirm Inter's dynamic-metrics constants at rsms.me/inter/dynmetrics.
5. The drag-projection formula comes from WWDC18 *Designing Fluid Interfaces* and was not re-fetched in this research.

---

## 11. Sources

Apple:
- HIG Materials: https://developer.apple.com/design/human-interface-guidelines/materials
- HIG Typography: https://developer.apple.com/design/human-interface-guidelines/typography
- HIG Playing haptics: https://developer.apple.com/design/human-interface-guidelines/playing-haptics
- HIG Color (iOS 26 system colors, Liquid Glass color rules): https://developer.apple.com/design/human-interface-guidelines/color
- HIG Eyes (visionOS): https://developer.apple.com/design/human-interface-guidelines/eyes
- HIG Spatial layout (visionOS): https://developer.apple.com/design/human-interface-guidelines/spatial-layout
- WWDC25-219 *Meet Liquid Glass*: https://developer.apple.com/videos/play/wwdc2025/219/
- WWDC25-356 *Get to know the new design system*: https://developer.apple.com/videos/play/wwdc2025/356/
- WWDC25-323 *Build a SwiftUI app with the new design*: https://developer.apple.com/videos/play/wwdc2025/323/
- WWDC23-10158 *Animate with springs*: https://developer.apple.com/videos/play/wwdc2023/10158/
- SwiftUI `snappy(duration:extraBounce:)`, `spring(response:dampingFraction:blendDuration:)`, `interactiveSpring(...)`; UIKit `UIImpactFeedbackGenerator.FeedbackStyle` (developer.apple.com/documentation)

Code (cloned in `/srv/manhwamaniacs/dev/design-ref`, read-only reference):
- liquid_glass_widgets 1.7.2, MIT: https://github.com/sdegenaar/liquid_glass_widgets
- flutter_liquid_glass (liquid_glass_renderer 0.2.0-dev.4, apple_liquid_glass), MIT: https://github.com/whynotmake-it/flutter_liquid_glass
- rivership (motor 1.1.0, heroine 0.7.2, stupid_simple_sheet 1.0.0-dev.4), MIT: https://github.com/whynotmake-it/rivership
- smooth_sheets 1.2.0, MIT: https://github.com/fujidaiti/smooth_sheets
- liquid-glass-react 1.1.1, MIT (props reference; Safari/Firefox show no displacement): https://github.com/rdev/liquid-glass-react
- kube.io *Liquid Glass in the Browser: Refraction with CSS and SVG*, **no license, technique only**: https://github.com/kube/kube.io (article `2025_10_04_liquid_glass_css_svg`)
- Flutter SDK 3.44.6 (`/srv/manhwamaniacs/dev/flutter`): `physics/spring_simulation.dart`, `cupertino/sheet.dart`, `cupertino/route.dart`, `cupertino/button.dart`, `cupertino/text_theme.dart`, `services/haptic_feedback.dart`, `widgets/basic.dart` (BackdropGroup), engine `PlatformPlugin.java`, `FlutterPlatformPlugin.mm` and `FlutterViewController.mm`
- Motion 12.42.2 (`frontend/node_modules/motion-dom/dist/es/animation/generators/spring.mjs`)

Web platform and third-party measurements:
- MDN `backdrop-filter`; mdn/browser-compat-data#24110 (SVG filters Chromium-only); WebKit bug 245510
- Chrome Platform Status: `corner-shape` (Chromium 139+): https://chromestatus.com/feature/5357329815699456
- Chrome blog, `prefers-reduced-transparency` (Chrome 118): https://developer.chrome.com/blog/css-prefers-reduced-transparency
- learnui.design iOS 26 guidelines (tab bar 21 pt inset, 11 pt labels): https://www.learnui.design/blog/ios-design-guidelines-templates.html
- nilcoalescing, *Presenting Liquid Glass sheets in SwiftUI*: https://nilcoalescing.com/blog/PresentingLiquidGlassSheetsInSwiftUI/
- Engadget / TechCrunch on the iOS 26.1 Clear/Tinted setting: https://techcrunch.com/2025/11/04/ios-26-1-lets-you-turn-down-liquid-glass-transparency/
- ios-haptics (the Safari switch trick, patched for programmatic use in iOS 26.5): https://github.com/tijnjh/ios-haptics
