# Web Glass foundation: materials, ambient field, physics and motion

Track: web · Order 68 · Depends on: `docs/redesign/prompts/release/00-cinematic-flip-release.md`, `docs/redesign/prompts/shared/05-brand-glass-and-art-intake.md` · Runs in parallel with: `docs/redesign/prompts/mobile/25-glass-foundation-material-physics.md` · Proof folder: `docs/redesign/proof/web-25/`

## Goal

Cinematic is now the default skin and `legacy` is gone (`release/00`). This step lays the Glass skin's foundation on the web client, with no screens yet: the glass material itself (`GlassSurface` with the thickness scale T1 to T5, the regular, clear and tinted finishes, the content twins, and three rendering tiers: A "liquid" refraction through an SVG `feDisplacementMap` backdrop filter on Chromium, B "frosted" blur on Safari and Firefox, C "solid" for Reduce Transparency and Solid glass, with Increase Contrast as a modifier on A and B and forced colours mapped to system colours), the displacement-map builder, the adaptive legibility dim driven by `Lb`, the lit action's caustic and follow ring, the specular sweep, the pointer- and tilt-driven light angle, the ambient field behind content, rain on glass, the physics helpers (projection, rubber band, velocity tracker with catch, magnets) with a runnable check of every §15.8 value, the `play()` motion helper over the generated `MotionName` union, the Glass motion-timings overlay, the live glass-surface budget counter, the document defaults, and the `/dev/glass-calibration` checkerboard page. Glass stays reachable only through the debug row (CINEMATIC | GLASS); every Glass `ScreenId` stays in Glass's `PENDING` map. Cinematic must not change by a single pixel.

## Read first

Read these completely before planning. Where this file and `glass/DESIGN.md` disagree, `glass/DESIGN.md` wins; say so in the report.

1. `docs/redesign/inventory/00-decisions.md` (all of it: dark AMOLED `#000000`, flagship-only maximum effects, OS reduced motion honoured).
2. `docs/redesign/stack-decision.md` §2.1 (the token pipeline), §2.2 (web folder layout and the lint boundary), §3 (dependency list), §4 risks 3, 5 and 11.
3. `docs/redesign/glass/DESIGN.md`:
   - The "Conventions used everywhere below" block and §1 Manifesto.
   - §2.1.1 to §2.1.4 (the Graphite ramp, text and fill roles incl. `onGlass`, `fill1`–`fill4`, `wellOnGlass`, the backing disc, Iris, semantic roles), §2.1.6 (the seven moods), §2.1.7 (scrims, dims, the legibility floor and the full `Lb` source table), §2.1.8 (ambient field, extraction, clamping, Light follows the story), §2.1.9 (one light per meaning).
   - §2.2 (fixed layout lengths and scroll insets), §2.3 (squircle rule, `rCapsule`), §2.4.1 to §2.4.4 (layer stack, mass classes, the three glass rules, the six-surface budget, web bar groups, droplets and the neck, focus rings never masked, every variant, the material behaviours 1–8, the thickness scale, the web and Flutter mappings, calibration knobs, the light effects), §2.5 (blur and the two-stacked-layer budget), §2.6 (the two-tone focus ring on glass), §2.8.4 and §2.8.5 (every material, motion, physics and threshold key with its CSS name).
   - §3.5 (material-aware axes: `ROND` follows the tier, `GRAD` follows `Lb`, the registered twins `--glass-rond-t` and `--glass-grad-t`).
   - §4.1 to §4.11 (laws, springs with k and c, velocity hand-off, projection, rubber-banding, thresholds, timed values, stagger, interruptibility, the complete motion table, Reduce Motion, Reduce Transparency, Increase Contrast, forced colours).
   - §8.0.7 (the "Dark everywhere" bullet: `color-scheme` and the autofill override).
   - §12.7 and §12.6 only for where the demo art lives.
   - §15.1 (generator outputs for Glass), §15.2 (the web file map; this step builds the `glass/`, `physics/`, `motion.ts` and `motion-timings.tsx` parts and the document defaults), §15.7 (performance budget and the live-surface table), §15.8 (the physics check, the calibration page, the motion-timings overlay, the web gate), §15.9 step 1, §15.10 rows G1, G2 and G10, §15.11 (`motion`, `fast-average-color`).
4. `docs/redesign/inventory/web.md` §2 (global chrome) only to see which surfaces will later be glass; no inventory screen is delivered in this step.
5. `docs/redesign/00-baseline.md` (the green baseline you must keep).
6. `docs/redesign/prompts-plan.json`: the entry for `web/00` (its `TRACK RULE` binds this file) and the entry for this file.
7. Reference code, read only (never copy code from a repository without a licence):
   - `/srv/manhwamaniacs/dev/design-ref/kube.io/app/data/articles/2025_10_04_liquid_glass_css_svg/lib/displacementMap.ts`, `lib/surfaceEquations.ts` and `components/Filter.tsx`: the Snell refraction profile over a convex squircle bezel and the `feImage` + `feDisplacementMap` chain. This repository has **no licence**: read it for the maths, write our own code.
   - `/srv/manhwamaniacs/dev/design-ref/liquid-glass-react/src/` (MIT) for how a React component hosts its SVG filter.
8. Code you build on: `frontend/src/skins/glass/` (from earlier steps: `index.ts` with its `PENDING` map, `tokens.generated.css`, `tokens.generated.ts`, `motion.generated.ts`, `fonts.ts`, `icons/`, `haptics.ts`, `sounds.ts`), `frontend/src/skins/types.ts`, `frontend/src/skins/theme.generated.css`, `frontend/src/app/globals.css`, both root layouts (`frontend/src/app/(app)/layout.tsx` and `frontend/src/app/(preview)/layout.tsx`), the boot script (`grep -rl "appearance-boot-source" frontend/src`), the motion-timings recorder core from `web/02` (`grep -rln "SKIN RESTART" frontend/src`), `frontend/src/skins/cinematic/motion-timings.tsx` (the overlay to mirror, not to import), `frontend/public/skin-preview/covers/` (the 24 demo covers).

## Preconditions (check before writing the plan)

- `git log --oneline -20` shows `release/00`; `test ! -d frontend/src/skins/legacy` succeeds; the debug row at `/settings/diagnostics?debug=1` offers CINEMATIC | GLASS.
- `node design/build.mjs --check` passes, and these generated files exist: `frontend/src/skins/glass/tokens.generated.css`, `tokens.generated.ts` (physical springs `{ type: "spring", stiffness, damping, mass: 1 }`, §15.10 G1) and `motion.generated.ts`. Grep `tokens.generated.css` for `--mm-glass-t2-blur`, `--mm-glass-tinted-fill`, `--mm-dim-min`, `--mm-color-machine-wash`, `--mm-color-bloom-rim`, `--mm-spring-letter` and `--mm-physics-rubber-band-c`. If a key of §2.8.4 or §2.8.5 is missing, do not edit `design/`: note it in the report for the shared track and read the value from DESIGN.md inside a clearly named constant with a comment citing the section.
- `@base-ui/react` 1.8.0, `motion` 13.4.4 and `fast-average-color` 9.6.0 are installed (`npm ls motion fast-average-color @base-ui/react`).
- In `frontend/`: `free -m && npm run test` is green; record the vitest file and case counts (your floor). `npm run lint` and `npm run build` are green.

## Skills to invoke

1. `superpowers:writing-plans` before any code: write the plan to `docs/redesign/proof/web-25/plan.md` (commit it with the proof).
2. `superpowers:test-driven-development` for everything pure (physics, material maths, palette clamping, the budget registry, the map builder's profile): write the vitest first.
3. `superpowers:subagent-driven-development` to run the plan (or `superpowers:executing-plans` inline). At most 6 implementer subagents; start each subagent prompt with a scope lock, pass `model: "opus"` explicitly, run builds, tests and browsers one at a time, and verify each subagent's work against `git status` and `git diff`, never against its report alone.
4. `frontend-design:frontend-design`, `impeccable:impeccable` and `taste-skill:taste-skill` while building and reviewing the material on the calibration page (the glass must read as thick, lit, refracting water over true black, never as a grey frosted card).
5. `superpowers:verification-before-completion` before you claim anything is done.

## Scope: deliver every item below

Use the generated custom properties and TypeScript tokens (`--mm-…`, `tokens.generated.ts`), never literals, except where a value below is marked as a formula constant. Sections cited are `glass/DESIGN.md`.

### A. Document defaults (§8.0.7, §15.2)

1. Both root layouts export `viewport: Viewport = { width: "device-width", initialScale: 1, viewportFit: "cover", interactiveWidget: "resizes-content", colorScheme: "dark", themeColor: "#000000" }` (Next emits `<meta name="color-scheme" content="dark">` and the viewport meta with `viewport-fit=cover, interactive-widget=resizes-content`). Keep whatever Cinematic already set if it is identical; the result must hold for both skins.
2. `frontend/src/skins/glass/glass.css` (a global stylesheet, imported by `app/globals.css` right after `skins/glass/tokens.generated.css`; never a CSS module, because Turbopack rejects impure selectors in modules and `tsc`/`eslint` do not catch it) starts with `html[data-skin="glass"] { color-scheme: dark; }` and the autofill override `[data-skin="glass"] input:-webkit-autofill { -webkit-text-fill-color: var(--mm-color-label1); box-shadow: 0 0 0 50px var(--mm-color-fill3) inset; caret-color: var(--mm-color-iris400); }`.
3. `@property` registrations the generator did not already emit (grep `@property --` across `frontend/src` first and register each name once only): `--glass-dim` (`<number>`, inherits true, initial 0.64: an unknown backdrop counts as white, §2.1.7), `--glass-grad-t` and `--glass-rond-t` (`<number>`, inherits false, initial 0; §3.5), `--mm-light-angle` (`<angle>`, inherits true, initial `135deg`), `--amb-a1`, `--amb-a2`, `--amb-a3`, `--amb-rim` (`<color>`, inherits true, initial `#4336A3`, the Default mood), `--amb-x1` … `--amb-y3` (`<percentage>`, inherits false), `--sheet-progress` (`<number>`, inherits true, initial 0), `--caustic-a` (`<number>`, inherits false, initial 0.14). `--glass-rond` and `--glass-grad` stay **unregistered** (§3.5).

### B. Rendering tier detection (§2.4.2 `frosted` row, §15.2)

In the boot script (`appearance-boot-source.ts`), before paint and for both skins, stamp `html[data-glass-renderer]`: `"liquid"` when `navigator.userAgentData?.brands?.some(b => b.brand === "Chromium")` is true, otherwise `"frosted"`. It is a renderer-capability rule (Safari and Firefox cannot run SVG displacement inside `backdrop-filter`), never a device tier. The calibration page (item O) can override it with `?renderer=liquid|frosted|solid` for testing only. Solid comes from the existing `data-solid="on"` (Solid glass, stamped by `web/02`) or `@media (prefers-reduced-transparency: reduce)`.

### C. Material maths (`skins/glass/glass/material.ts`, pure)

- `tierFor(shorterSide)`: `< 36 → "t1"`, `36–56 → "t2"`, `57–96 → "t3"`, `≥ 97 → "t4"` (`glass.snap` [36, 57, 97], §2.4.3, §2.8.4). **T5 is never reached by size**: it is declared only by the Massive objects of §2.4.1 (the listen full player, the Wrapped frame, the image viewer frame, the splash lens), so `tier="auto"` never returns `"t5"`; a `GlassSurface` gets T5 only through an explicit `tier="t5"`.
- `dimFor(lb, highContrast = false)`: `clamp(0.22 + 0.42 × lb, 0.22, 0.64)`; with Increase Contrast `clamp(…, 0.40, 0.72)` (§2.1.7, §4.11).
- `gradFor(lb)`: `round(40 × lb)` (§3.5; the web has no Bold Text signal).
- `rondFor(tier)`: `20 × n` for `tN` (T1 20 … T5 100, §3.5).
- `lerpTier(a, b, t)`: linear interpolation of every numeric tier parameter (thickness, bezel, displacement, blur, saturate, fill alpha, specular, shadow offset, blur and alpha, dispersion, `ROND`) for growing glass (§2.4.2 rule 2).

### D. `GlassSurface.tsx` (§2.4, §2.5, §2.6, §3.5, §4.11, §15.2)

A client component, the only way glass is drawn in the skin. Props: `as` (element type, default `div`), `tier` (`"t1"`…`"t5"` or `"auto"`, which measures the shorter side with a `ResizeObserver` and applies `tierFor`), `finish` (`"regular" | "clear" | "tinted"`), `twin` (`"content" | "onGlass" | "dense" | "cover"`, optional), `lb` (number 0–1, default 1.0), `shapes` (optional bar-group shape list for item E), `tierValue` (optional `MotionValue<number>` 1–5 for growth), `pressedGlow` (optional `{ x, y, on }` in local px), `overContent` (boolean, default true), `capsule` (boolean), `radius` (px), `layer` (`"controls" | "overlays" | "interruptions" | "hud"`, the z layers 3–6 of §2.4.1), `moving` (boolean: the object is in flight; maps never rebuild while true), `materialize` (boolean, default true), `className`, `children`, plus forwarded DOM props and ref.

Structure (focus rings are never masked, §2.4.1): the host element holds the children and the focus ring; three `aria-hidden` spans sit beneath the children: `.glass__bg` (the `backdrop-filter`, the optional `mask-image`, then its background layers: the tier fill on top of the `dimLegibility` layer `rgb(0 0 0 / var(--glass-dim))`), `.glass__rim` (the 0.5 px specular rim: `linear-gradient(var(--mm-light-angle), rgb(255 255 255 / S) 0%, rgb(255 255 255 / 0.06) 35%, rgb(255 255 255 / 0.02) 65%, rgb(255 255 255 / S × 0.55) 100%)` drawn through a 0.5 px padding ring with `mask-composite: exclude`, the first stop mixed with `var(--amb-rim)` at 18 % via `color-mix(in oklab, …)`), and `.glass__glow` (the press glow). Inner light (T2 and up): `inset 1px 1px 0 rgb(255 255 255 / S × 0.35), inset -1px -1px 0 rgb(0 0 0 / 0.35)`, exposed as `--glass-inner-light`; the drop shadow is exposed as `--glass-shadow` (§2.6 appends the focus ring to both).

1. **Tiers** (from the generated `--mm-glass-tN-*` properties, §2.8.4), mapped in `glass.css` by `data-tier`:

   | Tier | Blur | Saturate | Fill | Specular S | Shadow | Max displacement | Bezel | Dispersion | ROND |
   |---|---|---|---|---|---|---|---|---|---|
   | T1 Film | 2 | 1.4 | `rgba(255,255,255,0.03)` | 0.55 | `0 2px 8px rgba(0,0,0,0.35)` | 6 | 6 | none | 20 |
   | T2 Pane | 8 | 1.8 | `rgba(255,255,255,0.07)` | 0.42 | `0 6px 20px rgba(0,0,0,0.45)` | 10 | 10 | none | 40 |
   | T3 Slab | 10 | 1.8 | `rgba(255,255,255,0.06)` | 0.40 | `0 8px 24px rgba(0,0,0,0.50)` | 12 | 12 | none | 60 |
   | T4 Block | 22 | 1.8 | `rgba(28,28,34,0.52)` | 0.30 | `0 24px 64px rgba(0,0,0,0.60)` | 18 | 18 | 0.6 px | 80 |
   | T5 Monolith | 32 | 1.7 | `rgba(22,22,28,0.60)` | 0.26 | `0 40px 96px rgba(0,0,0,0.66)` | 22 | 24 | 1.2 px | 100 |

2. **Finishes** (§2.4.2): `clear` = fill `rgba(255,255,255,0.02)`, blur 1, saturate 1.4, specular 0.50, no shadow, the dim still inside; `tinted` = fill `rgba(117,99,242,0.86)` (`iris600` at 86 %), pressed `rgba(91,74,209,0.86)`, blur 8, saturate 1.6, rim `rgba(255,255,255,0.30)`, specular colour `rgba(228,223,255,0.60)` (`iris100` at 60 %), shadow `0 8px 24px rgba(117,99,242,0.35)`, and the caustic (item H). Variants never mix inside one container.
3. **Rendering tier A "liquid"** (`html[data-glass-renderer="liquid"]`): `.glass__bg { backdrop-filter: var(--glass-lens,) blur(var(--glass-blur)) saturate(var(--glass-saturate)); }`, where `--glass-lens` is `url(#lens-<instanceId>)` once the map from item E is ready; until then the surface draws without displacement (never a blank frame).
4. **Tier B "frosted"**: `backdrop-filter` and `-webkit-backdrop-filter` `blur(calc(var(--glass-blur) + 6px)) saturate(1.8)`; fill, dim, rim, inner light, caustic and glow unchanged; no displacement, no dispersion.
5. **Tier C "solid"** (`data-solid="on"`, `prefers-reduced-transparency: reduce`): no `backdrop-filter`; T1–T3 fill `#1C1C22` (`solid1`), T4–T5 `#26262E` (`solid2`); a 1 px `rgba(255,255,255,0.10)` rim; inner light at `S × 0.5`; no dim, no caustic, no dispersion, no specular sweep, no rain; `tinted` becomes solid `iris700` `#5B4AD1` (white 6.28:1), pressed `#4A3CB0` (§4.11).
6. **Increase Contrast** (`data-contrast="more"`, `prefers-contrast: more`), a modifier on A and B (the plan entry lists it under tier C; `glass/DESIGN.md` §15.2 makes it a modifier, and the contract wins): `hcBorder` 1 px `rgba(255,255,255,0.55)` on every surface, the dim clamp 0.40–0.72, and 3 px focus rings; the label remaps (`label2` → `label1`, `label3` → `label2`, `iris300` accent text) are exposed as the custom properties `--glass-label2` and `--glass-label3` so primitives read them.
7. **Forced colours** (`@media (forced-colors: active)`): the surface is `Canvas` with a 1 px `CanvasText` border; `tinted` is `ButtonText` on `ButtonFace` with a 2 px `Highlight` border; the dim, rim, glow, caustic and every decorative layer are removed.
8. **Content twins** (§2.4.1 rule 1, §2.4.2 rule 7): when `twin` is set there is no backdrop read, no displacement and no dim, and the surface does not register in the budget: `content` = fill `rgba(19,19,23,0.62)`, `onGlass` = fill `fill2` `rgba(120,120,128,0.30)` with rim `rgba(255,255,255,0.22)`, `dense` = `rgba(19,19,23,0.82)`, `cover` = `rgba(0,0,0,0.86)` with rim `rgba(255,255,255,0.22)`; all keep the 0.5 px rim of the tier they replace and the inner light. `finish="tinted"` with a twin is the tinted twin: fill `iris600` at 86 %, rim 0.30, specular `iris100` at 60 %, no caustic.
9. **No glass on glass** (§2.4.2 rule 7): a `GlassHostContext` marks descendants of a live surface; a `GlassSurface` rendered inside a live surface without an explicit `twin` renders as the `onGlass` twin automatically, so no `backdrop-filter` element is ever nested inside another (§2.4.1).
10. **Legibility dim and axes**: the host sets `--glass-dim: dimFor(lb, hc)`, `--glass-grad-t: gradFor(lb)`, `--glass-rond-t: rondFor(tier)`, and `--glass-grad: var(--glass-grad-t); --glass-rond: var(--glass-rond-t)` on itself; `--glass-dim` and `--glass-grad-t` transition over `dimShift` (400 ms `cubic-bezier(0.2, 0, 0, 1)`); under reduced motion they change at once (§4.11 "the dim changes instantly").
11. **Materialise and dematerialise** (§2.4.2 rule 1, §4.10): on mount the displacement scale ramps 0 → full over `materialize` (250 ms `cubic-bezier(0.2, 0, 0, 1)`) while opacity goes 0 → 1 over the first 120 ms; on exit (callers wrap in `AnimatePresence`) the reverse over `dematerialize` (350 ms). Reduced motion: a 150 ms opacity fade in (120 ms out) with full refraction from frame 0.
12. **Press glow** (§2.4.2 rule 3): `.glass__glow` is a radial gradient of radius 140 px at `(--glow-x, --glow-y)`, `rgba(255,255,255,0.16)` (tinted: `rgba(188,176,255,0.22)`), in over `glowIn` 150 ms linear, out over `glowOut` 60 ms linear. Glass never dims on press. Primitives (`web/26`) drive it through `pressedGlow`.
13. **Growth** (§2.4.2 rule 2): when `tierValue` is given, the host writes the interpolated blur, fill alpha, specular, shadow and `--glass-rond-t` each frame from `lerpTier`; the displacement filter keeps the lower tier's map with its `scale` interpolated (maps never rebuild mid-motion).
14. **Squircles** (§2.3): `@supports (corner-shape: squircle)` applies `corner-shape: squircle` to non-capsule surfaces; capsules never get it.
15. **Specular sweep** (§2.4.4): `sweepGlass(host)` runs a 40 px band of `rgba(255,255,255,0.18)` along the light angle from the lit corner to the far corner in 520 ms `cubic-bezier(0.2, 0, 0, 1)`, clipped to the shape. A module-level coordinator allows one sweep on screen at a time and drops requests within 300 ms of the last start. It plays when a surface materialises and when a lit action becomes enabled. Reduced motion and solid: none.

### E. `liquid-map.ts` (§2.4.1 web bar groups, §2.4.3 web mapping, §15.2)

- `liquidMap(shapes: { x, y, w, h, r, tier }[], groupW, groupH)` returns `{ key, href, scale, dispersion }`: one displacement map per surface or bar group. `key` is the shape list rounded to whole px plus the tiers; `href` is a PNG data URL drawn on a canvas at CSS-pixel resolution.
- **Profile.** For each shape: the bezel band is the tier's bezel width; inside it, `x = depthIntoBezel / bezel` (0 at the rim, 1 at the inner edge of the band); the glass surface height is the convex squircle `y(x) = (1 − (1 − x)^4)^(1/4)`; a vertical ray refracts at that surface with Snell's law, `n = 1.5` (`eta = 1 / 1.5`); the lateral travel to the bottom of the glass (virtual thickness from the tier table of §2.4.3: T1 12, T2 20, T3 24, T4 40, T5 56) is the raw displacement. Precompute 128 samples per (tier) and normalise so the largest sample equals the tier's max displacement `D`. Outside the band and outside the shape the map is neutral.
- **Direction** is the inward normal of the rounded rectangle (the gradient of its signed distance field), so the rim bends the backdrop toward the shape's centre, as the Flutter side does; check it on the checkerboard (item O).
- **Encoding:** `R = round(128 + 127 × dx / D)`, `G = round(128 + 127 × dy / D)`, `B = 128`, `A = 255`, and `feDisplacementMap scale = 2 × D` with `xChannelSelector="R" yChannelSelector="G"`, so a full-strength pixel moves `D` px.
- **Filter** (in `LensDefs`, a single hidden `<svg><defs>` host that `GlassSurface` portals into): `<filter id="lens-<instanceId>" x="0" y="0" width={W} height={H} filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB">`, `feImage` with the cached `href`, then `feDisplacementMap`. T4 and T5 add **dispersion** (§2.4.3): three displacement passes at `scale × 1.000 / 1.033 / 1.067` (T4) or `× 1.000 / 1.055 / 1.109` (T5), each isolated to one channel with `feColorMatrix`, recombined with two `feBlend mode="screen"`. The map data URL is cached per `key` (an LRU of 32 entries); each instance owns its own `<filter>` element (so materialise can animate its `scale` alone) that points at the cached image.
- **Groups:** the bar group's `mask-image` (an SVG data URL of the same rounded rectangles) comes from the same shape list; the group is **one** live element (§2.4.1). Droplets and the metaball neck are `web/29`'s; this module only needs to accept extra shapes and a `variant` string in the cache key so the dock can cache one map per tab position plus a base map.
- **Rebuild policy:** a `ResizeObserver` on the host, debounced 100 ms after the last resize; never while `moving` is true (it rebuilds 100 ms after `moving` turns false); the build runs in `requestIdleCallback` with a 200 ms timeout. Until a map exists the surface draws tier B's look without displacement.
- The map builder's profile and encoding are pure functions with a vitest (`liquid-map.test.ts`): the profile is 0 at the inner edge of the band, monotonic toward the rim, and its maximum encodes to `R` 255 or 1 at a straight vertical edge; a pixel at the centre of a shape encodes neutral 128/128.

### F. Budget and stacking (`skins/glass/glass/budget.ts`, §2.4.1, §2.5, §15.7)

- A registry every live surface (renderer A or B, not a twin, not solid) joins on mount and leaves on unmount, with `kind: "glass" | "scrim"` (scroll-edge and `dimContext` blur layers are scrims, not glass; they are counted separately so the §15.7 limit of **six** live glass elements per web screen stays exact) and its `layer`.
- `useGlassCount()` (through `useSyncExternalStore`) returns `{ glass, scrims }`. In development, a seventh live glass element logs one `console.warn` naming the registered elements. The Diagnostics row "Glass layers on screen" is built later (`web/40`); it reads this hook.
- **Two stacked layers at most** (§2.4.2 rule 7, §2.5): on every register, unregister and debounced window resize, compute each live surface's rect; when a surface is overlapped by two live surfaces of higher layers that also overlap each other, it renders as solid (`data-forced-solid`, the `solid1` recipe) until the stack clears.

### G. `useLightAngle.ts` (§2.4.2 rule 5)

- One `pointermove` listener on `window` for fine pointers: `angle = 135° + 25° × (pointerX / viewportWidth − 0.5) × 2`, written to `--mm-light-angle` on `document.documentElement` at most once per animation frame.
- Coarse pointers: `deviceorientation` where it needs no permission (Android Chrome): the roll `gamma` relative to the pose captured at the first event after mount, low-passed with α = 0.15, sampled at most every 33 ms (30 Hz), `angle = 135° + 25° × clamp(roll / 30°, −1, 1)`; listeners run only while the document is visible. iOS Safari needs `DeviceOrientationEvent.requestPermission()` from a user gesture: export `requestDeviceTilt()` for the Settings switch "Light follows the device" (`web/39`); without it the angle stays 135°.
- Pinned at 135° under reduced motion (OS or `data-motion="reduced"`) and when called with `{ follow: false }`.

### H. `Caustic.tsx` (§2.4.4)

- `CausticWrap` wraps the one lit (`tinted`) object: its `::before`, placed below the glass, is an ellipse 120 % × 70 % of the object's size, offset 8 px along the light direction (`translate: calc(sin(var(--mm-light-angle)) * 8px) calc(cos(var(--mm-light-angle)) * -8px)`, which is down and right at 135°), filled with `radial-gradient(closest-side, rgb(143 126 255 / var(--caustic-a)), transparent)` (`iris500` `#8F7EFF`), `filter: blur(18px)`, `mix-blend-mode: screen`. `--caustic-a` is 0.14 at rest and 0.22 while pressed (in 150 ms linear, out 60 ms linear). It renders only when `overContent` is true. The wrapper must not create a stacking context (no `isolation`, `opacity < 1`, `transform` or `filter` on it), or the blend has nothing to blend with. Solid and Reduce Transparency: none; reduced motion: no press brightening.
- `FollowRing` (plays with `follow.add`, §2.4.4): a ring centred on the origin element inside a clipping band, radius 0 → the distance to the band's far corner, border 2 px → 24 px, colour `iris300` `#BCB0FF` at 30 % → 0, `filter: blur(6px)`, `mix-blend-mode: screen`, over 700 ms `cubic-bezier(0.2, 0, 0, 1)` through the Web Animations API. Reduced motion: none.

### I. `palette.ts` (§2.1.8)

- `coverPalette(item)`: returns the server `palette: { a: [hex, hex, hex], l, lMax }` when present. Otherwise (the offline fallback) it decodes a 32 × 32 copy with `fast-average-color` 9.6.0 (`algorithm: "dominant"`) for `a[0]`, derives `a[1]` and `a[2]` by rotating the hue ±30° at the same OKLCH L and C, and computes `l` (mean relative luminance) and `lMax` (95th percentile) from the same 32 × 32 canvas via `getImageData`. Results are cached per image URL for the session.
- `fieldColours(palette, mood)`: OKLCH clamping for the field (L 0.55–0.78, C 0.06–0.16, hue kept); a colour with C < 0.03 before clamping is replaced by the mood colour; with fewer than three colours the first is reused (the renderer draws that third blob at 60 % size). `rimTint(palette)`: `a[0]` at OKLCH L 0.86 with C capped at 0.08.
- OKLCH conversion: if one exists outside `src/skins/` (`grep -rn "oklch\|oklab" -i frontend/src --include=*.ts`), import it; if the only copy is inside `skins/cinematic/`, move it to `frontend/src/lib/color/oklch.ts` in its own no-behaviour-change commit and import it from both skins; otherwise write `lib/color/oklch.ts` (sRGB ↔ OKLab ↔ OKLCH) with a vitest round-trip case.

### J. `useLb.ts` (§2.1.7 `Lb` sources)

`useLb(source)` returns `Lb` (0–1). Sources: `{ kind: "unknown" }` → 1.0; `{ kind: "field", l, opacity }` → `l × opacity + 0.02`; `{ kind: "cover", lMax }`; `{ kind: "page", sample, bands }` → the maximum of the sample's `pTop`, `pMid`, `pBottom` over the listed bands (the reader's `PageSample` type from `features/reader`); `{ kind: "paper", luminance }`; `{ kind: "bar", ref, field }` → `max(field term, lItems)`, where `lItems` is the largest `lMax` among registered items whose rects intersect the bar's rect, recomputed on scroll at most every 100 ms and held while the scroll speed exceeds 3000 px/s. Items register with `useLbItem(ref, lMax)` (posters and rows call it in `web/26`); scroll is observed with one capturing passive `scroll` listener on `document`.

### K. `AmbientField.tsx` (§2.1.8)

- `AmbientProvider` + `useAmbient({ palette | mood | aurora, opacity })` so a screen declares its field source; `AmbientField` draws it: one `position: fixed; inset: 0` element at z 0.5 (behind content), `pointer-events: none`, `aria-hidden`, whose background is three radial gradients (no filter): blob diameter 70 % of the viewport width at centres (18 %, 8 %), (78 %, 14 %), (46 %, 36 %) held in `--amb-x1…--amb-y3`; each blob's stops are `colour @ 0`, `colour @ calc(35vw − var(--amb-blur) × 0.5)`, `colour at 45 % of its alpha @ 35vw`, `transparent @ calc(35vw + var(--amb-blur))`, with `--amb-blur` 120 px below 1024 px and 180 px at 1024 px and wider; each blob's alpha is the source opacity (Home 26 %, library-type lists 18 %, Settings the mood's own, auth and onboarding the brand aurora `#8FD8FF`, `#A99BFF`, `#FF9ED8` at 20 %, the full table in §2.1.8). A mask keeps the upper screen lit and the lower screen true black: opaque to 40 % of the viewport height, 50 % at 55 %, transparent at 60 %, with a bottom layer `linear-gradient(to bottom, transparent 55%, #060608 60%, #000000 70%)` (`g25` then black).
- **Light follows the story:** colours are the registered `--amb-a1..3` transitioning over `tintShift` (900 ms `cubic-bezier(0.2, 0, 0, 1)`), and `--amb-rim` (from `rimTint`) with them. Reduced motion: a 200 ms linear cross-fade.
- **Drift:** every 14 s each blob anchor takes a new random target within ±6 % of its anchor; `--amb-x*` and `--amb-y*` transition with the pre-sampled `drift` spring (`var(--mm-spring-drift-ms)` `var(--mm-spring-drift)`, 900 ms bounce 0). Paused while the document is hidden; frozen under reduced motion.
- **Mood fallback** before data: the profile mood colour at its own opacity (§2.1.6: Romantic `#FF7AA8` 20 %, Action `#FF6B4A` 20 %, Comedy `#FFC94D` 16 %, Horror `#C0506F` 26 %, Slice of Life `#9FD98A` 16 %, Fantasy `#9B8CFF` 22 %, Default `#4336A3` + `#2B2370` 30 %).
- Solid glass and Reduce Transparency: the field stays behind content at half opacity. Only art already on screen may feed the field (a mature series owns it only when the gate is open because it is only on screen then).

### L. `rain.ts` (§2.4.4, §4.10 "Rain on glass")

`createRain(host, { renderer })` for a glass group, active only while told (the Rain soundscape playing, `web/44`) and while the host is visible: 6 to 10 droplets of radius 3–6 px, each running top to bottom in 4 s under constant acceleration (`a = 2 × H / (4 s)²`) with a lateral wobble `dx/dt = 0.15 × dy/dt × sin(2π t / 1.2 s + φ)`, a random phase per droplet, respawning at the top. The step function `rainStep(state, dt, bounds)` is pure and tested. Tier A: each droplet is a 16 × 16 hemisphere displacement tile placed by a `feImage` `x`/`y` in a second pass after the group's displacement, updated at 30 fps. Tier B: absolutely positioned spans with `radial-gradient(circle at 35% 35%, rgb(255 255 255 / 0.35), rgb(255 255 255 / 0.06) 60%, transparent 70%)` and a 0.5 px rim, moved by `transform`. Off under reduced motion and solid. It adds no `backdrop-filter` element.

### M. `physics/` (§4.3–§4.6, §15.2, §15.8)

- `physics/project.ts`: `project(pos, vPxPerS) = pos + (v / 1000) × 0.998 / (1 − 0.998)` (= `pos + 0.499 × v`); `projectCapped(pos, v, cap)` capped at one viewport length (`physics.projectionCap` 1.0); `nearest(points, x)`; `railSnap(offset, v, stride) = round(project(offset, v) / stride) × stride`.
- `physics/rubberband.ts`: `rubberband(x, d, c = 0.55) = d × (1 − 1 / (x × c / d + 1))`; the reader's chapter-end pull uses `c = 0.35` (`physics.rubberBandChapterC`).
- `physics/tracker.ts`: `createTracker()` with `start(event, from)`, `move(event)`, `end()` returning `{ offset, velocity }` in px/s from a least-squares fit over the samples of the last 100 ms (0 with fewer than two); it knows the slop per pointer type (touch 10 px, mouse and pen 3 px); `catchMotion(value: MotionValue<number>)` stops a running animation, returns `{ from, velocity }` from `value.get()` and `value.getVelocity()` so the gesture continues from the exact state, and fires the `motion.catch` haptic event when the value was animating (§4.3 Catch, §4.9).
- `physics/magnet.ts`: `createMagnet(targets, radius = 64, pull = 0.35)`: `step(pos)` pulls 0.35 of the remaining distance per frame toward a target within 64 px, and reports `capture` and `release` transitions (callers fire `magnet.capture` and `magnet.drop`).
- `physics/spring.ts`: `toPhysical(ms, bounce) = { stiffness: (2π / d)², damping: 4π(1 − bounce) / d, mass: 1 }` with `d` in seconds; `depthIntensity(depth) = 0.30 + 0.08 × depth`.
- `physics/physics.test.ts` (vitest) asserts every §15.8 value: `project(0, 1000) ≈ 499`; `rubberband(100, 800, 0.55) ≈ 51.5`; `toPhysical(520, 0)` → k 146.0, c 24.17; `toPhysical(150, 0.14)` → k 1754.6, c 72.05 (and that the generated `tokens.generated.ts` springs `page` and `track` carry the same stiffness and damping to 0.1); `railSnap(310, 900, 136) == 816`; `tierFor(44) == "t2"`, `tierFor(240) == "t4"`, `tierFor(401) == "t4"` (T5 is never reached by size, §15.8); `dimFor(1.0) == 0.64`, `dimFor(0) == 0.22`, and a dark cover with one white patch (mean `l` 0.2, `lMax` 1.0) read through the `cover` source gives `dimFor(1.0) == 0.64`; `depthIntensity(3) == 0.54`; plus the tracker's velocity on a synthetic 1000 px/s drag and a magnet capture at 63 px and none at 65 px.

### N. `motion.ts` and `motion-timings.tsx` (§4.10, §4.11, §15.2, §15.8)

- `MOTION_TABLE` typed `satisfies Record<MotionName, MoveSpec>` (the union from `motion.generated.ts`; use its member spelling exactly), one entry per row of the §4.10 table, all of them: `{ ms, transition, reduced }`, where `ms` is the row's planned settle time for the overlay (for example Press swell 253, Sheet present 447, Push 615, Tab droplet 518, Letter reveal 345 per letter), `transition` is the row's spring from `tokens.generated.ts` (physical `{ type: "spring", stiffness, damping, mass: 1 }`, §4.3) or its curve (`{ duration: ms / 1000, ease: [x1, y1, x2, y2] }` from the curve token, for example `tintShift` → `{ duration: 0.9, ease: [0.2, 0, 0, 1] }`, `fadeOut` → `{ duration: 0.12, ease: [0.4, 0, 1, 1] }`, the linear curves → `ease: "linear"`), and `reduced` is the row's last column encoded as one of `{ kind: "fade", ms: 120 | 150 | 200 }`, `{ kind: "instant" }`, `{ kind: "none" }` (the end state with no movement), `{ kind: "frozen" }` (loops), `{ kind: "same" }` (catching, glow only, 1:1 tracking).
- `play(name, target, keyframes, { velocity, onComplete })` wraps Motion's `animate`, passes the release `velocity` into physical springs (law 4), swaps in the reduced replacement when reduced motion is on (the OS query or `html[data-motion="reduced"]`), returns Motion's playback controls (so a caller can `stop()` them: the catch), and records every call in the shared motion-timings recorder from `web/02`: name, planned `ms`, start, end, frames rendered, and dropped frames (`requestAnimationFrame` deltas over 1.5 × the display's frame interval, measured with `performance.now()`). In development, a name missing from `MOTION_TABLE` throws.
- `GlassMotionConfig`: `<MotionConfig reducedMotion="user">` for the Glass tree; `useGlassReduced()` returns true for the OS query or `data-motion="reduced"`, so components honour the in-app switch that Motion's own `useReducedMotion` cannot see.
- `skins/glass/motion-timings.tsx`: the development overlay (tree-shaken from production builds): `mod+shift+m` toggles a 320 px panel bottom-left listing the last 20 moves from the recorder as rows in `mono` 11/16 (`PRESS SWELL   253 → 251 MS   15/15 F   0 DROP`), a row in `danger` `#FF5C5C` when a move dropped frames or overran its settle time by more than one frame; `Clear` and `Copy log` in its header; each entry mirrored once to `console.table`. It mirrors Cinematic's overlay in behaviour; it does not import it (the lint boundary bans that).

### O. The calibration page `/dev/glass-calibration` (§2.4.3 calibration knobs, §15.8)

`frontend/src/app/(preview)/dev/glass-calibration/page.tsx` (a server component that calls `notFound()` when `process.env.NODE_ENV === "production"`) renders a client component from `frontend/src/skins/glass/dev/Calibration.tsx` inside `<div data-skin="glass">` with `LensDefs`, `GlassMotionConfig`, `AmbientProvider`, the light-angle hook and the Glass motion-timings overlay. It must render without a signed-in session; if the app's auth guard redirects it, exempt `/dev/` paths in development only. Sections:

1. **Checkerboard** (the §15.8 page): a 16 px black-and-white checkerboard (`repeating-conic-gradient(#000 0 25%, #fff 0 50%) 0 0 / 32px 32px`) under a T2 44 px circular glass button, a T3 dock bar group (a 64 px-tall capsule 290 px wide plus a 50 px orb 8 px to its right, one masked element with a two-shape map), a T4 240 × 220 menu (radius 26) and a T5 420 × 420 swatch (dispersion 1.2 px). A caption under each states the tier, `n = 1.5`, bezel, max displacement and thickness in use, so the owner can count bent squares against the Flutter page (`mobile/25`).
2. **Controls** (content layer, plain elements with the tokens, each ≥ 44 × 44 px, keyboard operable, never glass): renderer Liquid | Frosted | Solid (sets `data-glass-renderer`, or `data-solid="on"`), Increase contrast on/off (`data-contrast`), Reduce motion on/off (`data-motion`), and the live readouts: light angle, "Glass layers on screen: N / 6 (+ S scrims)", and the `Lb` and dim of the bar in section 3.
3. **Legibility over art:** a scrolling column of the 24 demo covers (`frontend/public/skin-preview/covers/`, each registered with `useLbItem` from its computed `lMax`) under a floating T3 bar group with an `onGlass` label, whose `Lb` uses the `bar` source; the dim readout moves between 0.22 and 0.64 as pale covers pass.
4. **Light:** a `tinted` T2 button (L 50 px tall) over a cover with `CausticWrap`, a pressable demo that drives `pressedGlow` and the caustic's 0.22 press, a `FollowRing` trigger over a 360 × 200 band, and a "Sweep" button that calls `sweepGlass`.
5. **Ambient:** buttons that cycle the field through three demo-cover palettes (Light follows the story) and the seven moods.
6. **Physics and motion:** a 120 × 120 draggable glass tile inside a 600 × 300 track that rubber-bands past the edges with `rubberband` and settles through `play()` with the `MotionName` member of the Rubber band row carrying the release velocity, snaps to the projected nearest of three detents, and can be caught mid-flight; buttons that play Materialise, Dematerialise, Specular sweep, Light follows the story and Dim shift through `play()`.
7. **Rain:** a toggle that runs `createRain` on the section-3 bar.

### P. Checks in the browser

`frontend/e2e/glass-foundation.spec.ts` (Playwright, against `next dev`, no sign-in needed), one browser context per test:

1. Chromium: `.glass__bg` of the T2 button has a computed `backdrop-filter` containing `url(#lens-`; with `?renderer=frosted` it has no `url(` and its blur is the tier blur + 6 px; with `data-solid="on"` it has `none` and the T2 fill is `rgb(28, 28, 34)` and the T4 fill `rgb(38, 38, 46)`; the tinted button is `rgb(91, 74, 209)` under solid.
2. Increase contrast adds the 1 px `rgba(255, 255, 255, 0.55)` border and raises the dim floor to 0.40.
3. Reduced motion (`emulateMedia({ reducedMotion: "reduce" })`): `--mm-light-angle` stays `135deg` after pointer moves; the ambient anchors do not change over 15 s; a materialising surface's filter `scale` is already at full on its first frame.
4. The focus ring on the T2 button is fully visible (keyboard `Tab`, then a screenshot crop that shows the 2 px `iris300` ring and the 6 px glow outside the circle, unclipped by any mask).
5. Adding a seventh live glass surface logs one warning; the three-layer overlap renders the lowest as solid.
6. A resize of the T4 menu rebuilds its map once, at least 100 ms after the last resize step.

## Out of scope here (owned by later steps; do not build)

- Every primitive (`web/26`–`web/28`), the shell, dock, sidebar, sheet host, droplets and the metaball neck (`web/29`), every screen (`web/30` onward), the Diagnostics rows (`web/40`), the "Light follows the device" setting UI (`web/39`), rain being started by the soundscape (`web/44`).
- Any change to `design/` (report missing keys instead), `mobile/`, `backend/` or the Cinematic skin.

## File layout

```
frontend/src/app/globals.css                               imports skins/glass/glass.css after the Glass tokens
frontend/src/app/(app)/layout.tsx, (preview)/layout.tsx    viewport export (A1)
frontend/src/features/preferences/appearance-boot-source.ts (or wherever it lives)   data-glass-renderer (B)
frontend/src/lib/color/oklch.ts (+ oklch.test.ts)          only if no shared copy exists (I)
frontend/src/skins/glass/
├── glass.css                                              A2, A3, D (tiers, finishes, renderers, solid, contrast, forced colours, twins, focus ring), K, H
├── motion.ts                                              N (MOTION_TABLE, play, GlassMotionConfig, useGlassReduced)
├── motion-timings.tsx                                     N (development overlay)
├── glass/
│   ├── GlassSurface.tsx                                   D (+ LensDefs, GlassHostContext, sweepGlass)
│   ├── material.ts (+ material.test.ts)                   C
│   ├── liquid-map.ts (+ liquid-map.test.ts)               E
│   ├── budget.ts (+ budget.test.ts)                       F
│   ├── useLightAngle.ts                                   G
│   ├── Caustic.tsx                                        H (CausticWrap, FollowRing)
│   ├── palette.ts (+ palette.test.ts)                     I
│   ├── useLb.ts                                           J
│   ├── AmbientField.tsx                                   K (AmbientProvider, useAmbient, AmbientField)
│   └── rain.ts (+ rain.test.ts)                           L
├── physics/
│   ├── project.ts, rubberband.ts, tracker.ts, magnet.ts, spring.ts
│   └── physics.test.ts                                    M
└── dev/Calibration.tsx                                    O
frontend/src/app/(preview)/dev/glass-calibration/page.tsx  O
frontend/e2e/glass-foundation.spec.ts                      P
docs/redesign/proof/web-25/                                plan.md, screenshots, report.md
```

Skin files import only `@/features/**` (never `@/features/*/components/**`), `@/lib/**`, `@/services/**`, `@/stores/**`, `@/types/**` and their own `skins/glass/**`; the lint rule bans `@/skins/cinematic/**`.

## Acceptance criteria

- [ ] `physics/physics.test.ts` passes and asserts every value listed in item M, including `project(0, 1000) ≈ 499`, `rubberband(100, 800, 0.55) ≈ 51.5`, the rail snap to 816, `tierFor` (with `tierFor(401) == "t4"`: no size reaches T5), `dimFor` and depth 0.54; `material`, `liquid-map`, `palette`, `budget` and `rain` tests pass.
- [ ] Tier A in Chromium: every live surface on the calibration page refracts the checkerboard at its rim toward its centre; T4 and T5 show a thin red and blue fringe; tier B shows blur only (+6 px), no displacement; tier C is opaque `#1C1C22` / `#26262E` with a 1 px `rgba(255,255,255,0.10)` rim, and the tinted button is `#5B4AD1`.
- [ ] The legibility dim follows `Lb`: the section-3 bar's dim readout moves within 0.22–0.64 as covers pass, eases over 400 ms, is instant under reduced motion, and its `onGlass` label stays readable over the whitest cover (screenshot).
- [ ] Increase contrast adds `hcBorder` to every surface and clamps the dim to 0.40–0.72; forced colours show `Canvas`/`CanvasText` surfaces with no decorative layers (screenshot with `emulateMedia({ forcedColors: "active" })`).
- [ ] Focus rings on glass are the two-tone ring (2 px black inner, 2 px `iris300` at 2 px offset, 6 px `rgba(188,176,255,0.28)` glow; 3 px under Increase Contrast), appended to the surface's own shadow list, and never clipped by a mask.
- [ ] No `backdrop-filter` element is nested inside another; a `GlassSurface` inside a live surface renders as the `onGlass` twin.
- [ ] Budget: the counter shows the live glass count and scrims separately; a seventh live glass element warns in development; a three-layer overlap forces the lowest layer solid.
- [ ] Maps rebuild only at rest: never while `moving` is true, and once, at least 100 ms after the last resize.
- [ ] The light angle follows the pointer within ±25° around 135° on desktop, and is pinned at 135° under reduced motion; the caustic sits 8 px down-right of the lit button at 135°, brightens to 22 % while pressed, and is absent over empty black and under solid.
- [ ] The ambient field is one fixed element with three radial gradients and no `filter`; the lower 40 % of the viewport is true black; palettes cross-fade over 900 ms (200 ms under reduced motion); anchors drift every 14 s and freeze under reduced motion and while hidden.
- [ ] `play()` covers every name in `MotionName` (a type error otherwise), throws on an unknown name in development, uses physical springs with the release velocity, swaps in the reduced replacement for both the OS query and the in-app switch, and every call appears in the Glass motion-timings overlay (`mod+shift+m`, development only) with no dropped frames for the calibration moves at 1440 × 900 (or a trace showing the cost is software raster only, listed for the owner's hardware check).
- [ ] Document defaults: `<meta name="color-scheme" content="dark">`, the viewport meta with `viewport-fit=cover, interactive-widget=resizes-content`, `color-scheme: dark` on the Glass root, and the autofill override on wells.
- [ ] Keyboard and targets: every calibration control is reachable by `Tab`, operable with `Enter`/`Space`, and at least 44 × 44 px.
- [ ] Per-skin difference: nothing under `frontend/src/skins/cinematic/` changed (`git diff --stat` for this step's commits shows none there, except an OKLCH move into `lib/color/` if item I required it, with Cinematic's tests green); with the default skin, `/` and `/library` render as before (screenshots before and after).
- [ ] Glass `PENDING` is unchanged (this step adds no screen); the completeness test passes.
- [ ] `npm run typecheck`, `npm run lint` (0 errors, 0 warnings), `npm run test` (file and case counts at or above the floor plus the new tests), `npm run build` (0 errors, 0 warnings) and `node design/build.mjs --check` are green.

## Verification

**RAM guard (production shares this box).** Before every heavy command (a build, the vitest suite, `next dev`, a Playwright run) run `free -m` and read the `available` column of the `Mem:` row. If it is under 1024 MB, stop and report instead of running it. Never run two builds at once, and never run `next build` while `next dev` or a Playwright browser is running.

From `frontend/`:

```bash
free -m && npm run typecheck
free -m && npm run lint
free -m && npm run test
free -m && npm run build
cd .. && node design/build.mjs --check && cd frontend
```

Browser checks and proof (from `frontend/`):

```bash
free -m && NEXT_PUBLIC_API_URL=/api BACKEND_INTERNAL_URL=http://127.0.0.1:8010 npm run dev -- -p 3010
# second shell
free -m && E2E_BASE_URL=http://127.0.0.1:3010 npx playwright test e2e/glass-foundation.spec.ts --workers=1
```

Capture with `frontend/scripts/proof.mjs` (run `node scripts/proof.mjs --help` first; add a flag only if one below is missing) in the named session `web-25`, headless Chromium, at 1440 × 900 and 390 × 844 (touch emulation on the phone size), into `docs/redesign/proof/web-25/`: `calibration-{liquid,frosted,solid}-{desktop,phone}.png`, `calibration-contrast-desktop.png`, `calibration-forced-colors-desktop.png`, `calibration-reduced-desktop.png`, `legibility-{dark,pale}-desktop.png` (the section-3 bar over the darkest and the palest cover), `caustic-{rest,pressed}-desktop.png`, `focus-ring-t2-desktop.png`, `ambient-{mood,palette}-phone.png`, and `default-skin-{before,after}-{desktop,phone}.png` for `/library`. If you use `playwright-cli`, pass `-s=web-25`. Write `docs/redesign/proof/web-25/report.md` mapping each screenshot to the acceptance item it proves. Stop `next dev` when done.

`00-baseline.md` records lint and build at 0 errors and 0 warnings; keep them there. This step changes nothing in `mobile/` or `backend/`: check each of your commits with `git show --stat --format= <hash>` (the parallel `mobile/NN` session and the backend and shared sessions commit `mobile/` and `backend/` on the same branch, so never judge by the branch diff). If one of your commits touched them, revert that part and prove the baseline with `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter analyze` (No issues found), `cd mobile && /srv/manhwamaniacs/dev/flutter/bin/flutter test` (all 2012 tests pass, or the current higher count) and `cd backend && .venv/bin/python -m pytest -q --no-header`, one at a time after the RAM guard.

## Git

- Branch `feat/vps-slim-source-native`. Commit small and often: document defaults and the renderer stamp; the material maths with its test; the physics with its test; `GlassSurface` and `glass.css`; the map builder; the budget; light angle and caustic; palette and `useLb`; the ambient field; rain; `motion.ts` and the overlay; the calibration page; the browser spec; the proof. Stage your paths explicitly (`git add frontend/src/skins/glass/physics …`), never `git add -A` or `git add .`, because the mobile, backend and shared sessions commit in the same checkout.
- Conventional messages (`feat(web-glass): liquid displacement maps per bar group`). No Claude or AI attribution anywhere: no `Co-Authored-By` line, no "Generated with" line, no AI author. Never commit secrets or `.claude/`.
- Run `npm run build` (after `free -m`, with `next dev` stopped) before every push, then `git push origin feat/vps-slim-source-native:master` after each working step.
- Never edit `backend/connectors/`. Never touch production containers or `/srv/manhwamaniacs/{app,data}`. Do not deploy anything: Glass stays behind the debug row until `release/01`.

## Report back

Reply with:

1. Done items by letter (A to P), and anything not done with the reason.
2. Missing token keys found in the generated files (for the shared track), if any.
3. The screenshot folder `docs/redesign/proof/web-25/` and its file list.
4. Test counts: vitest files and cases before and after; the Playwright spec result; lint, build and `build.mjs --check` results; the `free -m` available figure before each build.
5. The calibration readout: for the T2 44 px button and the T4 240 px menu, how many 16 px squares the rim bends on the web (for the side-by-side with `mobile/25`), and any refraction knob you would change in `design/tokens/glass.json` (the shared track edits it, not you).
6. The motion-timings figures for the calibration moves, and any raster-only move for the owner's hardware check.
7. Open issues, each with its `glass/DESIGN.md` section.

Next prompt file: `docs/redesign/prompts/web/26-glass-primitives-controls-and-reveals.md` (`docs/redesign/prompts/mobile/25-glass-foundation-material-physics.md` runs in parallel).
