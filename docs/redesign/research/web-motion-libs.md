# Web motion and interaction building blocks — ManhwaManiacs redesign

Scope: open-source (or free) building blocks for the Next.js web client that implement the two personalities ("Cinematic" and "Glass"). Researched 2026-09-29. Star counts and push dates come from the GitHub API (authenticated `gh`), versions and licences from the npm registry the same day. All four reference clones live under `/srv/manhwamaniacs/dev/design-ref/web/`.

## 0. Baseline: what the app runs today and what is current

| Package | Installed in `frontend/` | Latest on npm (2026-09-29) | Note |
|---|---|---|---|
| next | 16.2.9 | 16.3.6 | `Link transitionTypes` landed in 16.2.0, so it is already available |
| react / react-dom | 19.2.4 | 19.3.0 (canary `19.3.0-canary-d083ec1d-20260922`) | App Router uses Next's bundled canary React, not this one |
| tailwindcss | ^4 | 4.3.3 | CSS-first `@theme` config is already used in `src/app/globals.css` |
| framer-motion | 12.42.2 | 13.4.4 | Move to the `motion` package (see §2.1) |
| @types/react | 19.2.17 | — | Ships `canary.d.ts`, which types `ViewTransition` |

Verified locally (read-only): `node_modules/next/dist/compiled/react/cjs/react.production.js` exports `ViewTransition` (not `unstable_ViewTransition`), so `import { ViewTransition } from 'react'` already works in App Router on 16.2.9. In 16.2.9, `experimental.viewTransition` appears only in the config schema and defaults (`viewTransition: false`). No other code reads it, so it looks like a no-op. The current guide (docs version 16.3.6) says "View transitions work in the App Router with no configuration". TypeScript needs `/// <reference types="react/canary" />` in a `.d.ts` so `ViewTransition` and `addTransitionType` type-check.

## 1. Verdict at a glance

| Library | Repo | Licence | Stars | Last push | Verdict |
|---|---|---|---|---|---|
| Motion (`motion`) | github.com/motiondivision/motion | MIT | 33.8k | 2026-09-28 | **Core engine.** Springs, gestures, layoutId, scroll |
| React `<ViewTransition>` | react.dev (built into React canary) | MIT | — | — | **Route-level page and shared-element transitions** |
| motion-primitives | github.com/ibelick/motion-primitives | MIT | 6.4k | 2026-09-28 | **Copy components** (TextEffect, Dock, Tilt, ProgressiveBlur, MorphingDialog, AnimatedBackground) |
| Magic UI | github.com/magicuidesign/magicui | MIT | 22.4k | 2026-09-20 | **Copy components** (TextAnimate, TypingAnimation, Marquee, BlurFade) |
| React Bits | github.com/DavidHDev/react-bits | MIT + Commons Clause | 48.2k | 2026-09-28 | **Reference and selective copy** (GlassSurface, BlurText, Stack, ScrollStack). Many components depend on GSAP, ogl or three |
| Base UI | github.com/mui/base-ui | MIT | 11.0k | 2026-09-28 | **Headless primitives, including a Drawer** (swipe to dismiss, snap points). Replaces vaul |
| shadcn/ui | github.com/shadcn-ui/ui | MIT | 124.8k | 2026-09-28 | **Distribution only** (the CLI and registry pull in Magic UI, React Bits and Base UI parts). Do not adopt its look |
| tw-animate-css | github.com/Wombosvideo/tw-animate-css | MIT | 807 | 2026-02-28 | **Yes**, for CSS enter/exit utilities (includes `blur-in`/`blur-out`) |
| embla-carousel | github.com/davidjerleke/embla-carousel | MIT | 8.4k | 2026-09-18 | **Yes** for the hero billboard and any carousel that needs loop or autoplay |
| Lenis | github.com/darkroomengineering/lenis | MIT | 16.1k | 2026-09-22 | **Optional.** Cinematic only, desktop wheel only, never in the reader |
| vaul | github.com/emilkowalski/vaul | MIT | 8.6k | 2025-10-03 | **No.** README says "This repo is unmaintained". Mine its constants only |
| @use-gesture | github.com/pmndrs/use-gesture | MIT | 9.6k | 2024-07-15 | **Only if** reader pinch-zoom needs it. Stale since 2024 |
| react-spring | github.com/pmndrs/react-spring | MIT | 29.2k | 2026-09-28 | **No.** Its springs duplicate Motion's |
| GSAP | github.com/greensock/GSAP | "Standard no-charge" (not OSI) | 28.7k | 2026-04-13 | **No** by default. Free, with all plugins including SplitText, but it would be a second engine |
| Aceternity UI | ui.aceternity.com (no public repo) | Site licence (Pro $199 one-time per third-party sources) | — | — | **Inspiration only.** Nothing to clone |
| Rive web | github.com/rive-app/rive-react | MIT runtime | 1.2k | 2026-09-24 | **Yes, narrowly**: the wordmark/splash and a few state-machine icons, shared with Flutter |
| Lottie (lottie-web / dotLottie) | github.com/airbnb/lottie-web, github.com/LottieFiles/dotlottie-web | MIT | 32.1k / 888 | 2025-09-01 / 2026-09-16 | **No.** Rive covers the same need with interactivity |
| colorthief v3 | github.com/lokesh/color-thief | MIT | 13.6k | 2026-08-03 | **Yes** (web fallback) when a palette with semantic swatches is needed |
| fast-average-color | github.com/fast-average-color/fast-average-color | MIT | 1.5k | 2026-09-11 | **Yes** (web fallback) for a single ambient colour plus `isDark` |
| node-vibrant | github.com/Vibrant-Colors/node-vibrant | MIT (npm) | 2.5k | 2026-01-27 | **No.** colorthief v3 now has Vibrant-style swatches in OKLCH |
| liquid-glass-react | github.com/rdev/liquid-glass-react | MIT | 6.3k | 2025-06-13 | **Reference** (already cloned at `design-ref/liquid-glass-react`) |
| shuding/liquid-glass | github.com/shuding/liquid-glass | MIT | 1.2k | 2026-03-26 | Reference demo |
| kube.io liquid glass article | kube.io/blog/liquid-glass-css-svg | — | — | — | **Best explanation of the physics** (clone at `design-ref/kube.io`) |
| next-view-transitions | github.com/shuding/next-view-transitions | MIT | 2.4k | 2026-03-06 | **No.** Superseded by native `<ViewTransition>` plus `Link transitionTypes` |
| react-fast-marquee | github.com/justin-chu/react-fast-marquee | MIT | 1.5k | 2024-07-01 | **No.** A CSS marquee is about 20 lines |
| react-parallax-tilt | github.com/mkosir/react-parallax-tilt | MIT | 1.1k | 2026-09-25 | **No.** The Motion tilt is about 30 lines |
| sonner | github.com/emilkowalski/sonner | MIT | 13.0k | 2026-08-10 | Worth it for toasts (outside this brief, but toasts are a "minor element") |

## 2. Library notes

### 2.1 Motion (formerly framer-motion): the one engine

- npm `motion@13.4.4` (MIT, peer `react ^18 || ^19`). `motion` depends on `framer-motion ^13.4.4` and re-exports it, so installing `motion` and removing `framer-motion` does not duplicate code. Import from `motion/react`.
- Breaking change from 12 to 13, per the upgrade guide: `@emotion/is-prop-valid` is no longer an optional dependency. That only matters with styled-components or Emotion, and the app uses neither, so the migration is a find-and-replace of the import path in the four files that use it.
- RSC: `motion/react-client` (in framer-motion, `./client`) is a `'use client'` re-export. It lets a server component render `<motion.div>` without authoring its own client file: `import * as motion from "motion/react-client"`. Hooks such as `useScroll`, `useSpring` and `useMotionValue` still need a `'use client'` leaf.
- Free: `layout`/`layoutId`, `AnimatePresence`, drag/pan/tap/hover gestures, `useScroll`, `useSpring`, `useTransform`, `MotionConfig`, and the `spring()` generator.
- Paid (Motion+, £299 one-time personal): Ticker, Carousel, Typewriter, ScrambleText, AnimateNumber, Cursor, Curtains, AnimateActivity. None of these is needed, because the free equivalents are listed below.
- Springs use a time-based model: `{ type: "spring", visualDuration, bounce }`. This is the same (duration, bounce) mental model as SwiftUI, which keeps the Glass tokens portable to the Flutter side. Physics options (`stiffness`, `damping`, `mass`) override time-based ones. Defaults: `bounce 0.25`, `restSpeed 0.1`, `restDelta 0.01`.
- CSS springs: `spring(visualDuration, bounce)` stringifies to a duration plus a `linear(...)` easing (`el.style.transition = "all " + spring(0.5)`). Generate each Glass spring once at build time and paste the resulting `linear()` into Tailwind `@theme` as `--ease-*`. CSS-only components (skeletons, hover states, server components) then get real spring curves with no JS.
- Set `<MotionConfig reducedMotion="user">` at the root.

### 2.2 React `<ViewTransition>` plus Next `Link transitionTypes`

- Import: `import { ViewTransition, addTransitionType } from 'react'`. Props: `enter`, `exit`, `update`, `share`, `default` (each `"auto" | "none" | className | {[type]: className}`), and `name` for shared elements. Events: `onEnter`, `onExit`, `onUpdate` and `onShare`, which receive `(instance, types)` and must return a cleanup function.
- It fires only inside transitions: `startTransition`, `useTransition`, `Suspense` reveals and `useDeferredValue`. A plain `setState` does not fire it. Next navigations are transitions, so route changes animate automatically.
- `next/link` `transitionTypes={['nav-forward']}` (since v16.2.0) and `router.push(href, { transitionTypes })` feed `addTransitionType`. Browser back and the swipe-back gesture carry no type, so directional slides do not play on them. Shared-name morphs still play.
- Recipes from the official guide (nextjs.org/docs/app/guides/view-transitions), worth adopting as the baseline:
  - **Shared morph**: `name={\`cover-${id}\`} share="morph" default="none"` on both sides. `::view-transition-group(.morph){animation-duration:400ms}` plus a mid-flight `filter: blur(3px)` keyframe at 30%. The pair only forms when the destination renders in the same commit (prefetched). If it suspends into a fallback, the content gets its enter animation instead.
  - **Suspense handoff**: exit 150ms `ease-out` (fade and slide down 10px), then enter fade 210ms `ease-in` delayed 150ms, with the slide running 400ms.
  - **Directional nav**: old page 150ms fade plus 400ms `ease-in-out` slide by ±60px. New page 210ms fade delayed 150ms plus 400ms slide.
  - **Anchored chrome**: give the header or tab bar `viewTransitionName`, then set `animation:none` on its group, `display:none` on its old snapshot, and `z-index:100`.
  - Add `::view-transition{pointer-events:none}` so clicks during the animation are not swallowed.
  - Put the wrapper in each `page.tsx`, never in the layout, because layouts persist and never fire enter or exit.
- `<ViewTransition>` works inside async server components (the guide's own examples are RSC), so route transitions need zero client JS of your own.
- Browser support: Chromium 125+ for types and `view-transition-class`, plus recent Safari and Firefox. Unsupported browsers swap content instantly without breaking.

### 2.3 motion-primitives (ibelick): copy these files

- Install one at a time: `npx motion-primitives@latest add text-effect`. Built on `motion/react` and Tailwind 4. The repo pins `motion ^11.12` and React 18 for its site, but the component code runs unchanged on Motion 13 and React 19.
- Components: Accordion, AnimatedBackground (sliding active pill via `layoutId`), AnimatedGroup, AnimatedNumber, BorderTrail, Carousel, Cursor, Dialog, Disclosure, Dock, GlowEffect, ImageComparison, InfiniteSlider, InView, Magnetic, MorphingDialog, MorphingPopover, ProgressiveBlur, ScrollProgress, SlidingNumber, SpinningText, Spotlight, TextEffect, TextLoop, TextMorph, TextRoll, TextScramble, TextShimmer, TextShimmerWave, Tilt, ToolbarDynamic, ToolbarExpandable, TransitionPanel.
- **TextEffect** (`components/core/text-effect.tsx`): `per: 'char' | 'word' | 'line'`, `preset: 'blur' | 'fade-in-blur' | 'scale' | 'fade' | 'slide'`, `delay` (applied as seconds; the docs table says ms), `speedReveal`, `speedSegment`, `trigger`, `variants`, `containerTransition`, `segmentTransition`. Default stagger is char 0.03s, word 0.05s, line 0.1s. The `fade-in-blur` preset goes from `{opacity 0, y 20, blur 12px}` to `{opacity 1, y 0, blur 0}`, with a symmetric exit via `AnimatePresence`. Two defects to fix when copying: it splits with `segment.split('')`, which breaks surrogate pairs and emoji (use `Intl.Segmenter`), and it has no screen-reader handling (add an `sr-only` copy and `aria-hidden` on the segments).
- **Dock**: magnification 80px, distance 150px, panel height 64px, spring `{ mass: 0.1, stiffness: 150, damping: 12 }`. Hover magnification needs a pointer, so it is desktop only.
- **Tilt**: `rotationFactor` 15°, springs on x and y. **ProgressiveBlur**: 8 stacked layers, each `backdrop-filter: blur(index × 0.25px)` masked by a gradient band. This is the look of Apple's edge-fading bars.

### 2.4 Magic UI: copy these files

- Install: `pnpm dlx shadcn@latest add @magicui/text-animate` (shadcn namespace registry). Uses `motion/react`.
- **TextAnimate**: `by: text | word | character | line`, `animation: fadeIn | blurIn | blurInUp | slideUp | slideLeft | scaleUp | …`, `duration 0.3`, `startOnView true`, `once`, `accessible true`. Stagger is character 0.03s, word 0.05s, line 0.06s. `blurInUp` goes from `{opacity 0, blur 10px, y 20}` to rest, with y 0.3s, opacity 0.4s and filter 0.3s. It is the only one of the three text libraries that gets accessibility right: `aria-label` plus an `sr-only` copy. It still splits characters with `split("")`.
- **TypingAnimation**: `duration 100` ms per character, `deleteSpeed = typeSpeed / 2`, `pauseDelay 1000`, `loop`, `words[]`, `cursorStyle line | block | underscore`, `blinkCursor`. Splits with `Array.from`, which is code-point safe (better than `split('')`) but not full-grapheme safe.
- **Marquee**: pure CSS. `[--duration:40s] [--gap:1rem]`, `repeat 4`, `pauseOnHover`, `vertical`, with keyframes `translateX(calc(-100% - var(--gap)))`. Copy the 70 lines instead of adding a dependency.
- Others worth a look: BlurFade, Dock, ProgressiveBlur, Lens, NumberTicker, AnimatedList, BorderBeam, ShineBorder, NoiseTexture, LightRays, TextReveal (scroll-linked).

### 2.5 React Bits (DavidHDev): reference and selective copy

- Licence: **MIT + Commons Clause**. Use in an app is fine, including commercial use. Selling or redistributing the components themselves as a library is not allowed. For a private app that is fine.
- Four variants per component: JS-CSS, JS-TW, TS-CSS and TS-TW. Install with `npx shadcn@latest add @react-bits/BlurText-TS-TW` (jsrepo also works). Take TS-TW.
- Dependency map (from the clone, `src/ts-tailwind`): Motion is used by BlurText, ShinyText, RotatingText, DecryptedText, TextCursor, TrueFocus, Dock, Stack, TiltedCard, Carousel, ElasticSlider and Counter. **GSAP** is used by SplitText, TextType, ScrollReveal, ScrollFloat, Shuffle, ScrambledText, Masonry, CardSwap, BounceCards, AnimatedContent and FadeContent. **ogl** is used by CircularGallery, FlexCarousel and WarpText. **three / r3f** is used by FluidGlass and ASCIIText. **lenis** is used by ScrollStack. Take only Motion-based or dependency-free ones, or port the GSAP ones to Motion.
- **BlurText** (Motion, per letter or word): delay 200ms per segment, `stepDuration 0.35s`, three keyframes: `{blur 10px, opacity 0, y ∓50}`, then `{blur 5px, opacity .5, y ±5}`, then `{blur 0, opacity 1, y 0}`. Triggered by IntersectionObserver. No accessibility handling.
- **GlassSurface** (dependency-free): a real SVG liquid-glass implementation. It uses per-channel `feDisplacementMap` (`distortionScale -180`, R/G/B offsets 0/10/20 for chromatic aberration, `xChannel R`), an inline SVG displacement image with a blurred inner rect (`blur 11`, `brightness 50`, `opacity 0.93`) and `mix-blend-mode: difference`. It detects Safari and Firefox by UA sniffing and falls back to a plain `backdrop-filter: blur()`. This is the most practical starting point for Glass tier B (§3.3).
- **Stack** (swipe-away card stack, spring `stiffness 260, damping 20`) and **ScrollStack** (sticky stacking cards: `itemDistance 100`, `itemScale 0.03`, `itemStackDistance 30`, `stackPosition '20%'`, `baseScale 0.85`) are good references for "continue reading" stacks.

### 2.6 Aceternity UI

- Around 116+ free components plus a paid Pro tier. No public source repo (`aceternity/ui` returns 404), so there is nothing to clone. The licence page covers purchased items. Copy-paste use in a private app is the normal usage.
- Worth studying for ideas only: Text Generate Effect, Typewriter Effect, 3D Card, Floating Dock, Sticky Scroll Reveal, Parallax Scroll, Apple Cards Carousel, Glare Card, Spotlight, Aurora and Lamp. The motion-primitives or Magic UI equivalents cover all of them.

### 2.7 shadcn/ui, Base UI and tw-animate-css

- shadcn/ui is the **delivery mechanism** (CLI plus namespaced registries `@magicui`, `@react-bits`), not a visual base. Since July 2026 Base UI is its default primitive layer. Tailwind v4 support dates from Feb 2025 and React 19 from Oct 2024. In September 2026 `cn` moved into a dedicated package.
- **Base UI** `@base-ui/react@1.8.0` (MIT, 11k stars, published 2026-09-04) ships `drawer`, `dialog`, `tabs`, `toast`, `menu`, `popover`, `slider`, `switch` and others (verified in the package file list). `Drawer.Root` supports `swipeDirection` (`up | down | left | right`, default down), `snapPoints` (fractions, px or rem), `snapPoint` with `onSnapPointChange`, `modal`, and nested drawers exposed as the CSS variable `--nested-drawers`. It is headless, so each personality styles it fully.
- **tw-animate-css** `1.4.0`: add `@import "tw-animate-css";` after `@import "tailwindcss";`. Utilities: `animate-in`/`animate-out`, `fade-*`, `zoom-*`, `spin-*`, `slide-in-from-*`/`slide-out-to-*`, `blur-in`/`blur-out`, plus `duration-*`, `delay-*`, `ease-*`, `repeat-*`, `fill-mode-*`, `accordion-*`, `collapsible-*` and `caret-blink`. It is the Tailwind 4 replacement for the v3 plugin `tailwindcss-animate`, and it pairs naturally with Base UI's `data-[starting-style]`/`data-[ending-style]`.

### 2.8 vaul (use its numbers, not the package)

- `vaul@1.1.2`, last publish 2024-12-14. The README says unmaintained. Its only dependency is `@radix-ui/react-dialog ^1.1.1`.
- Its feel is tuned well and worth copying into Base UI Drawer styling. From `src/constants.ts`: `TRANSITIONS.DURATION 0.5s`, `EASE cubic-bezier(0.32, 0.72, 0, 1)`, `VELOCITY_THRESHOLD 0.4` (fling closes), `CLOSE_THRESHOLD 0.25` (drag past 25% closes), `NESTED_DISPLACEMENT 16px`, `WINDOW_TOP_OFFSET 26px`, background scale-down with an 8px radius.

### 2.9 Embla Carousel

- `embla-carousel-react@8.6.0` (MIT), with `9.0.0-rc03` on the `next` tag. Stay on 8 until 9 is final. Plugins: Autoplay, Auto Scroll, Auto Height, Class Names, Fade, Accessibility, plus the third-party `embla-carousel-wheel-gestures@8.1.0` for trackpad swipes.
- Key options: `align` (`center`), `axis` (`x`), `loop`, `dragFree`, `duration` (25; a friction unit roughly in the 20–60 range, not ms), `skipSnaps`, `containScroll` (`trimSnaps`), `watchDrag`, `startIndex`, `dragThreshold`.
- Use it for the Cinematic hero billboard (Fade plugin plus Autoplay 6–8s) and cover rails that need snapping and momentum on desktop. It is client-only; wrap it in a leaf `'use client'` component and pass slides from the server as children.

### 2.10 Lenis

- `lenis@1.3.26` (MIT, published 2026-09-18). React: `import { ReactLenis, useLenis } from 'lenis/react'` and `import 'lenis/dist/lenis.css'`, inside a `'use client'` provider.
- Drive it from Motion's frame loop so there is one rAF: `<ReactLenis root options={{ autoRaf: false, lerp: 0.1, smoothWheel: true, syncTouch: false }} ref={lenisRef} />` plus `frame.update(({ timestamp }) => lenisRef.current?.lenis?.raf(timestamp), true)`.
- Constraints for this app: never enable it on the reader route (webtoon strips must scroll 1:1 with the wheel and trackpad, and the virtualised list owns scroll). Leave touch native (`syncTouch: false`). Disable it under `prefers-reduced-motion`. Add `data-lenis-prevent` on inner scrollers such as sheets and chapter lists. It belongs to Cinematic only; Glass should feel native.

### 2.11 Gestures: @use-gesture, react-spring, GSAP

- `@use-gesture/react@10.3.1`: last npm publish 2024-03-21, repo quiet since 2024-07. Motion already covers drag, pan, tap and hover, with `dragElastic`, `dragMomentum` and `dragConstraints`. The one thing Motion lacks is **pinch**. If the reader needs web pinch-zoom beyond the browser's own, `usePinch` with `rubberband` is the least code. Otherwise skip it.
- `@react-spring/web@10.1.2` works (React 19 peer) but is a second spring engine. Skip.
- `gsap@3.15.0` and `@gsap/react@2.1.2` (`useGSAP`): the Standard licence is free for commercial use and **all plugins are now free** (SplitText, ScrollTrigger, MorphSVG, Draggable, Inertia). The one prohibition is using it in no-code visual animation builders that compete with Webflow. It is not an OSI licence. Technically it is excellent (SplitText has line masks and `autoSplit` on resize), but adding it means two animation engines and two rAF loops. Keep it out unless a scroll-pinned cinematic sequence proves impossible with Motion `useScroll` or CSS scroll timelines.

### 2.12 Rive and Lottie

- Rive: `@rive-app/react-canvas-lite@4.35.0` (MIT runtime). The WASM is 882,456 bytes for canvas-lite and 1,955,136 bytes for full canvas (text and layout). It loads asynchronously and is cacheable. The main advantage is that **the same `.riv` file runs in Flutter** (the `rive` package), so the new wordmark and splash reveal, plus a few state-machine icons (download progress to done, TTS voice speaking), are authored once for web, Android and iOS. The editor is a hosted product with its own pricing, so check the plan before committing assets.
- Lottie: `lottie-web@5.13.0` (slow-moving, last push 2025-09) or `@lottiefiles/dotlottie-react@0.19.16` (ThorVG WASM, 1,238,072 bytes). Both are playback-only. Rive does everything Lottie does plus inputs and state machines, so do not add both.

### 2.13 Ambient colour extraction

- **Do it once on the server first.** The backend already pins `pillow==12.3.0`. A 64px thumbnail plus `Image.quantize(colors=5, method=Image.Quantize.MEDIANCUT)` gives a palette that can be stored with the series row and sent to **both** clients. Flutter then needs no second extractor, and nothing flickers while a canvas samples on the client.
- Web fallback (sources not yet processed, or local downloads):
  - `fast-average-color@9.6.0`: `new FastAverageColor().getColorAsync(img, { algorithm: 'dominant', mode: 'speed', width: 32, height: 32 })` returns `{ hex, rgba, value, isDark, isLight }`. `isDark` drives foreground contrast on tinted surfaces. Smallest and cheapest option.
  - `colorthief@3.5.0`: zero runtime deps. `sharp` is only a peer for Node, and browsers use the native `index.browser.js` export. It quantises in **OKLCH** and `getSwatches()` returns Vibrant, Muted, DarkVibrant, DarkMuted, LightVibrant and LightMuted. Colour objects have `.hex() .rgb() .hsl() .oklch() .css()`. Sync and async variants exist, and it can run in a Worker via `ImageBitmap`. Use it when a personality needs two or three coordinated tones, for example a Cinematic gradient from DarkVibrant to black.
- CORS: covers are served same-origin through the `/api` rewrite, so canvas reads are not tainted. Only absolute third-party URLs would need `crossOrigin="anonymous"`.

## 3. Capability recipes

### 3.1 Per-letter text reveal (fade + slide-up + blur-out)

Default to **CSS in a server component**, and hydrate Motion only when the text must exit, interrupt or re-trigger:

```tsx
// SplitReveal.tsx — RSC, zero client JS
const seg = new Intl.Segmenter(undefined, { granularity: "grapheme" });
export function SplitReveal({ text }: { text: string }) {
  const g = Array.from(seg.segment(text), (s) => s.segment);
  return (
    <span className="split-reveal">
      <span className="sr-only">{text}</span>
      <span aria-hidden>
        {g.map((c, i) => (
          <span key={i} style={{ "--i": i } as React.CSSProperties}>{c === " " ? " " : c}</span>
        ))}
      </span>
    </span>
  );
}
```
```css
.split-reveal [aria-hidden] > span {
  display: inline-block;
  animation: letter-in var(--reveal-dur, 600ms) var(--ease-reveal, cubic-bezier(0.16, 1, 0.3, 1)) both;
  animation-delay: calc(var(--i) * var(--reveal-step, 24ms));
}
@keyframes letter-in { from { opacity: 0; translate: 0 0.35em; filter: blur(8px); } }
@media (prefers-reduced-motion: reduce) { .split-reveal [aria-hidden] > span { animation: none; } }
```
Filter animation on many spans is expensive. Keep per-letter reveals to headings (roughly 60 graphemes or fewer) and switch to per-word for anything longer. For the Motion version (exit or re-trigger), copy motion-primitives `TextEffect` and apply the two fixes in §2.3, or use Magic UI `TextAnimate`, which already handles accessibility.

### 3.2 Typing reveal with per-character delay

- For one-shot typing, use the same span technique with `animation: type-in 1ms steps(1) both; animation-delay: calc(var(--i) * 28ms)` (from `opacity 0` to `1`) and a caret element using `caret-blink` from tw-animate-css. This is RSC-friendly with no JS. Use 18–35ms per character: fast enough not to block reading, slow enough to read as typing.
- For loop, delete or multiple words (for example rotating search placeholders or OCR dialogue hits), copy Magic UI `TypingAnimation` (100ms per character default; lower it to 40–60ms).

### 3.3 Glass materials

Implement it in tiers:
1. **Tier A (all browsers, including iOS Safari)**: `background: rgb(255 255 255 / 0.06); backdrop-filter: blur(24px) saturate(180%); -webkit-backdrop-filter: …; border: 1px solid rgb(255 255 255 / 0.12); box-shadow: inset 0 1px 0 rgb(255 255 255 / 0.18), 0 8px 32px rgb(0 0 0 / 0.5)`, plus a 2–4% noise overlay (Magic UI NoiseTexture) to stop banding.
2. **Tier B (Chromium only)**: add an SVG filter via `backdrop-filter: url(#lg) blur(…)` for refraction. Only Chromium applies SVG filters in `backdrop-filter`. Safari and Firefox ignore the displacement; both liquid-glass-react's README and kube.io say so. Start from React Bits `GlassSurface` (per-channel `feDisplacementMap`, `scale -180`, R/G/B offsets 0/10/20). For physically based edges, follow kube.io: a convex-squircle surface profile, Snell's law with refractive index 1.5, a displacement map precomputed along one radius (127 samples) and encoded as R = x and G = y around a neutral 128, loaded through `<feImage>`, with a specular rim blended on top. Animate only the filter's `scale`. Changing size or shape rebuilds the map, which is expensive.
3. **Tier C (edges)**: motion-primitives `ProgressiveBlur` (8 masked layers, 0.25px steps) under top and bottom bars.

On an AMOLED `#000` base, glass has nothing to refract and reads as flat grey. The Glass personality needs an ambient layer behind the content: large blurred cover art or extracted-colour gradient blobs (§2.13). Budget: keep live `backdrop-filter` surfaces to the chrome (tab bar, top bar, open sheet, one hero card), never on every cover in a 60-item grid. That is a performance rule of thumb; profile on the target Android device.

### 3.4 Page and shared-element transitions

- **Between routes**: React `<ViewTransition>` with `Link transitionTypes` (`nav-forward` and `nav-back`), plus a shared `name={\`cover-${seriesId}\`}` on the grid cover and the series hero (§2.2). CSS per personality:
  - Cinematic: the old page scales to 0.96, blurs 6px and fades over 250ms. The new page rises 24px with a 450ms fade, easing `cubic-bezier(0.16, 1, 0.3, 1)`.
  - Glass: an iOS-style push where the new page enters from +30% x and the old page moves to −25% x and dims, using the Glass spring as a CSS `linear()` curve from §2.1.
- **Modal over a grid** (series quick-look, chapter list): Next **intercepting plus parallel routes** (`@modal/(.)series/[id]`) keep the grid mounted, so either a ViewTransition name pair or a Motion `layoutId` morph works. motion-primitives `MorphingDialog` is the reference.
- **Within a page**: Motion `layoutId` for the sliding tab or segment pill (motion-primitives `AnimatedBackground`), filter-chip reorders (`layout`), and card-to-expanded-card. `AnimatePresence` handles in-page mount and unmount.
- **Avoid** wrapping `{children}` in `AnimatePresence` inside a layout for route exit animations. In App Router that needs the "FrozenRouter" hack on Next's internal `LayoutRouterContext`, which breaks across Next upgrades. Route transitions are ViewTransition's job.

### 3.5 Smooth scroll

Lenis, Cinematic only, per §2.10. Glass keeps native scrolling, which feels more "Apple".

### 3.6 Swipe gestures on web

- **Drag-to-dismiss sheets**: Base UI `Drawer` with vaul's tuning (§2.8). Glass uses nested drawers with the background scaled to about 0.94 and a 12–16px top radius. Cinematic uses a full-height dark panel that slides with a shorter 0.35s and no scale.
- **Swipe between tabs**: native first. `display:flex; overflow-x:auto; scroll-snap-type:x mandatory; overscroll-behavior-x:contain` on the track, and `scroll-snap-align:start; scroll-snap-stop:always` on each panel. The active index comes from an IntersectionObserver at threshold 0.6, which drives the `layoutId` pill. This gives native momentum on Android and iOS with zero dependencies. Use Embla only if tab swipes need loop or programmatic physics.
- **Swipe-away card stacks** (e.g. "up next"): Motion `drag="x"` with `onDragEnd` checking `|offset.x| > 120 || |velocity.x| > 500`. React Bits `Stack` is the reference.

### 3.7 Spring tokens (proposal)

| Token | Cinematic | Glass |
|---|---|---|
| press | `scale 0.97`, 120ms `cubic-bezier(0.2, 0, 0, 1)` | `scale 0.96`, spring `visualDuration 0.2, bounce 0.35` |
| default move | 320ms `cubic-bezier(0.16, 1, 0.3, 1)` (expo-out) | spring `visualDuration 0.35, bounce 0.15` |
| sheet | 350ms `cubic-bezier(0.32, 0.72, 0, 1)` | spring `visualDuration 0.5, bounce 0.1` |
| hero / page | 450–600ms expo-out, exits 150–250ms `cubic-bezier(0.7, 0, 0.84, 0)` | spring `visualDuration 0.45, bounce 0.12` |
| ambient | Ken Burns `scale 1 → 1.08` over 20s linear | blob drift 30–40s `ease-in-out` alternate |

Cinematic uses eased curves and never bounces. Glass uses springs everywhere, with CSS `linear()` exports for CSS-only elements.

### 3.8 Skeletons

Skeletons need no library. Put `@theme { --animate-shimmer: shimmer 1.6s linear infinite; }` in Tailwind 4 with `@keyframes shimmer { from { background-position: -200% 0 } to { background-position: 200% 0 } }`.
- Cinematic: a gradient sweep `#0a0a0a → #1a1a1a → #0a0a0a` at `background-size: 200% 100%`.
- Glass: a translucent `rgb(255 255 255 / 0.05–0.09)` opacity pulse over 1.2s `ease-in-out` alternate.

Hand off to content with the Suspense plus ViewTransition pattern in §2.2 (exit 150ms, enter 210ms delayed 150ms).

### 3.9 Marquee

Copy Magic UI `Marquee` (CSS keyframes, `--duration 40s`, `--gap 1rem`, 4 repeats). Add `mask-image: linear-gradient(90deg, transparent, #000 10%, #000 90%, transparent)` for faded edges. Pause on hover and under reduced motion.

### 3.10 Sticky stacks and parallax

- **Sticky stacks**: `position: sticky; top: calc(var(--stack-top) + var(--i) * 12px)` per card. Scale earlier cards with Motion `useScroll({ target, offset: ["start start", "end start"] })` and `useTransform` from 1 to `1 - (n - i) * 0.03` (the React Bits ScrollStack scale step).
- **Parallax**: CSS scroll-driven animations where supported, `@supports (animation-timeline: view()) { .para { animation: para linear both; animation-timeline: view(); } }`. Support: Chrome/Edge 115+, Safari 26+, and Firefox 152 still behind `layout.css.scroll-driven-animations.enabled` (June 2026). The fallback is static, or Motion `useScroll` plus `useTransform(scrollYProgress, [0, 1], ["-12%", "12%"])` in a client leaf when the effect matters. Keep it decorative.

### 3.11 3D tilt

Copy motion-primitives `Tilt` (15° factor, springs). Gate it behind `@media (hover: hover) and (pointer: fine)`, because touch devices get no tilt. For Cinematic, add a glare layer: a radial gradient that follows the pointer at `mix-blend-mode: overlay` with 0.15 alpha. For Glass, add a moving specular highlight instead.

### 3.12 Dock and tab bars

- Mobile-width web uses a bottom tab bar with a `layoutId` pill (motion-primitives `AnimatedBackground`; it takes the transition from the caller, and `{ type: "spring", bounce: 0.2, duration: 0.3 }` is a good start), anchored across route transitions with `viewTransitionName` (§2.2).
- Desktop Glass uses a floating glass dock (motion-primitives `Dock`: 80px magnification, 150px distance, spring `mass 0.1, stiffness 150, damping 12`).
- Desktop Cinematic uses a top bar that goes from transparent to `#000` with a 24px blur once scrolled past the hero. That is a Motion `useScroll` threshold or `animation-timeline: scroll()`.

### 3.13 Carousels

Embla (§2.9) for the billboard and rails. For plain horizontal rails of covers, native `overflow-x` with `scroll-snap-type: x proximity` plus arrow buttons calling `scrollBy({ left: el.clientWidth * 0.9, behavior: 'smooth' })` is enough and costs nothing.

## 4. Tailwind 4, React 19 and RSC integration notes

- Personality switch: set `data-personality="cinematic|glass"` on `<html>` from the server (cookie), so the first paint is correct and nothing flashes. Declare `@custom-variant cinematic (&:where([data-personality=cinematic], [data-personality=cinematic] *));` and the same for `glass`. Tokens live in two `[data-personality=…]` blocks feeding `@theme inline` variables. Because the brief says the app restarts on switch, the server can also pick different component implementations per personality: a server-side `switch`, not client toggling.
- Client leaves: Motion hooks, Embla, Lenis, Base UI Drawer, colour extraction and anything with pointer handlers. Server-safe: `<ViewTransition>`, CSS reveals, marquee, skeletons, `motion/react-client` elements with declarative props, and the SVG glass filter definitions (render `<svg><filter id="lg">…</filter></svg>` once in the root layout).
- Replace `framer-motion` with `motion@13` before copying any registry component. All three component libraries import `motion/react`.
- Registries install into your tree as source (the `components/ui` pattern). That is the point: every file gets restyled per personality, and the registry is never a runtime dependency.
- Reduced motion: `MotionConfig reducedMotion="user"`, the `prefers-reduced-motion` block for `::view-transition-*` from the Next guide, Lenis disabled, and the marquee paused.

## 5. Reference clones

| Path | Source | Commit | Size | Why |
|---|---|---|---|---|
| `/srv/manhwamaniacs/dev/design-ref/web/motion-primitives` | github.com/ibelick/motion-primitives | `120f64f` (2026-09-28) | 3.7 MB | TextEffect, Dock, Tilt, ProgressiveBlur, MorphingDialog, AnimatedBackground (`components/core/`) |
| `/srv/manhwamaniacs/dev/design-ref/web/magicui` | github.com/magicuidesign/magicui | `d7207e5` (2026-09-20) | 28 MB | TextAnimate, TypingAnimation, Marquee, BlurFade (`apps/www/registry/magicui/`), keyframes in `apps/www/styles/globals.css` |
| `/srv/manhwamaniacs/dev/design-ref/web/react-bits` | github.com/DavidHDev/react-bits | `9d0270d` (2026-09-28) | 276 MB | GlassSurface, BlurText, Stack, ScrollStack (`src/ts-tailwind/`) |
| `/srv/manhwamaniacs/dev/design-ref/web/vaul` | github.com/emilkowalski/vaul | `3e97aac` (2025-10-03) | 752 KB | Drawer physics constants and drag math (`src/constants.ts`, `src/use-snap-points.ts`) |

Already present from other research: `/srv/manhwamaniacs/dev/design-ref/liquid-glass-react` and `/srv/manhwamaniacs/dev/design-ref/kube.io`.

## 6. Sources

- https://react.dev/reference/react/ViewTransition
- https://nextjs.org/docs/app/guides/view-transitions (docs version 16.3.6, updated 2026-08-25)
- https://nextjs.org/docs/app/api-reference/components/link (transitionTypes, v16.2.0)
- https://motion.dev/docs/react-upgrade-guide , https://motion.dev/docs/spring , https://motion.dev/plus
- https://motion-primitives.com/docs/text-effect , https://magicui.design/docs/components/text-animate
- https://github.com/DavidHDev/react-bits/blob/main/LICENSE.md
- https://gsap.com/standard-license
- https://base-ui.com/react/components/drawer , https://ui.shadcn.com/docs/changelog
- https://github.com/Wombosvideo/tw-animate-css , https://github.com/emilkowalski/vaul
- https://github.com/darkroomengineering/lenis/blob/main/packages/react/README.md
- https://embla-carousel.com/api/options/
- https://github.com/lokesh/color-thief , https://github.com/fast-average-color/fast-average-color
- https://kube.io/blog/liquid-glass-css-svg/
- https://ui.aceternity.com/licence
- https://caniuse.com/mdn-css_properties_animation-timeline_scroll

## Recommended stack

| Need | Pick | Package @ version | Licence | How |
|---|---|---|---|---|
| Animation engine, springs, gestures, layoutId | Motion | `motion@13.4.4` (replaces `framer-motion@12.42.2`) | MIT | `motion/react` in client leaves, `motion/react-client` in RSC; `MotionConfig reducedMotion="user"` |
| Route and shared-element transitions | React `<ViewTransition>` + Next `Link transitionTypes` | built into Next 16.2+ (bundled canary React) | MIT | Per-page wrappers, `name` pairs for cover morphs, CSS per personality; `react/canary` types |
| Per-letter reveal | Own `SplitReveal` (CSS, RSC) + motion-primitives `TextEffect` (fixed) | copy from clone | MIT | `Intl.Segmenter`, sr-only copy, 24ms step, 600ms expo-out, blur 8px |
| Typing reveal | CSS `steps(1)` spans; Magic UI `TypingAnimation` for loop/delete | copy via `@magicui` registry | MIT | 18–35ms per character |
| Enter/exit utility classes | tw-animate-css | `tw-animate-css@1.4.0` | MIT | `@import "tw-animate-css";` |
| Glass material | Own CSS tier A + React Bits `GlassSurface` tier B (Chromium) + motion-primitives `ProgressiveBlur` | copy from clones | MIT / MIT+Commons Clause | Ambient layer behind glass on AMOLED; chrome-only budget |
| Sheets, drawers, dialogs, tabs primitives | Base UI | `@base-ui/react@1.8.0` | MIT | `Drawer` with `swipeDirection`, `snapPoints`; vaul's 0.5s `cubic-bezier(0.32,0.72,0,1)` tuning |
| Swipe between tabs | Native CSS scroll-snap + IntersectionObserver | none | — | `scroll-snap-stop: always`; Embla only if loop is needed |
| Carousel / billboard | Embla | `embla-carousel-react@8.6.0` + `embla-carousel-autoplay`, `embla-carousel-fade` | MIT | Client leaf; stay on v8 until v9 is final |
| Smooth scroll | Lenis (Cinematic only) | `lenis@1.3.26` | MIT | `autoRaf:false` driven by Motion `frame.update`; off in reader and under reduced motion |
| Marquee | Magic UI `Marquee` (CSS) | copy | MIT | `--duration 40s`, `--gap 1rem`, mask edges |
| Sticky stacks, parallax | CSS sticky + scroll-driven animations; Motion `useScroll` fallback | none | — | `@supports (animation-timeline: view())` |
| 3D tilt | motion-primitives `Tilt` | copy | MIT | 15°, fine-pointer only |
| Dock / tab bar | motion-primitives `Dock` + `AnimatedBackground` | copy | MIT | `layoutId` pill; `viewTransitionName` to anchor across routes |
| Skeletons | Tailwind 4 `@theme` keyframes | none | — | Shimmer (Cinematic), pulse (Glass); Suspense + ViewTransition handoff |
| Ambient colour | Backend Pillow palette → API; web fallback fast-average-color / colorthief | `fast-average-color@9.6.0`, `colorthief@3.5.0` | MIT | Same-origin covers, no canvas taint; OKLCH swatches |
| Wordmark / splash / stateful icons | Rive | `@rive-app/react-canvas-lite@4.35.0` (882 KB WASM) | MIT runtime | One `.riv` shared with Flutter `rive` |
| Toasts | sonner | `sonner@2.0.8` | MIT | Restyle per personality |
| Distribution | shadcn CLI registries | `shadcn@latest` | MIT | `@magicui/*`, `@react-bits/*-TS-TW`; source lands in-tree |
| **Not adopted** | GSAP, react-spring, @use-gesture (unless pinch), vaul, Lottie, node-vibrant, react-fast-marquee, react-parallax-tilt, next-view-transitions, Aceternity (ideas only) | — | — | Duplicate engines, unmaintained, or a few lines of CSS or Motion |
