"use client";

import { animate, MotionConfig, type AnimationPlaybackControls } from "motion/react";
import { createElement, useSyncExternalStore, type ReactNode } from "react";
import { MOTION_LABELS, type MotionName } from "./motion.generated";
import { beginRecord, trackFrames } from "./motion-recorder";
import { curve, spring } from "./tokens.generated";

/** What a move does under Reduce Motion (DESIGN 4.10 last column, 4.11). */
export type ReducedSpec =
  | { kind: "fade"; ms: number }
  | { kind: "instant" }
  | { kind: "none" }
  | { kind: "frozen" }
  | { kind: "same" };

export type MoveTransition =
  | (typeof spring)[keyof typeof spring]
  | { duration: number; ease: "linear" | readonly [number, number, number, number] };

export interface MoveSpec {
  /** the row's planned settle time, what the motion-timings overlay compares against */
  ms: number;
  transition: MoveTransition;
  reduced: ReducedSpec;
}

type SpringKey = keyof typeof spring;
type CurveKey = { [K in keyof typeof curve]: (typeof curve)[K] extends { bezier: readonly number[] } | { curve: "linear" } ? K : never }[keyof typeof curve];

const mv = (ms: number, transition: MoveTransition, reduced: ReducedSpec): MoveSpec => ({ ms, transition, reduced });
const sp = (k: SpringKey): MoveTransition => spring[k];
const cv = (k: CurveKey, ms: number): MoveTransition => {
  const c = curve[k];
  return { duration: ms / 1000, ease: "bezier" in c ? c.bezier : "linear" };
};
const lin = (ms: number): MoveTransition => ({ duration: ms / 1000, ease: "linear" });
const NONE: MoveTransition = { duration: 0, ease: "linear" };
const fade = (ms: number): ReducedSpec => ({ kind: "fade", ms });
const INSTANT: ReducedSpec = { kind: "instant" };
const NONE_R: ReducedSpec = { kind: "none" };
const FROZEN: ReducedSpec = { kind: "frozen" };
const SAME: ReducedSpec = { kind: "same" };

/** One entry per row of DESIGN 4.10, in table order. A name missing here is a type error. */
export const MOTION_TABLE = {
  materialise: mv(250, cv("materialize", 250), fade(150)),
  dematerialise: mv(350, cv("dematerialize", 350), fade(120)),
  pressSwell: mv(253, sp("press"), SAME),
  contentSink: mv(253, sp("press"), SAME),
  stretch: mv(149, sp("track"), NONE_R),
  bloom: mv(434, sp("morph"), fade(150)),
  push: mv(615, sp("page"), fade(200)),
  pop: mv(615, sp("page"), fade(200)),
  stackFan: mv(436, sp("smooth"), fade(200)),
  zoom: mv(558, sp("zoom"), fade(200)),
  dive: mv(558, sp("zoom"), fade(200)),
  bookOpen: mv(615, sp("page"), fade(200)),
  surface: mv(414, sp("settle"), fade(150)),
  tabDroplet: mv(518, sp("tab"), fade(150)),
  tabSwitch: mv(120, cv("fadeIn", 120), fade(120)),
  minimise: mv(473, sp("minimize"), INSTANT),
  sheetPresent: mv(447, sp("sheet"), fade(150)),
  sheetSnap: mv(342, sp("sheetSnap"), fade(150)),
  recede: mv(0, NONE, SAME),
  toastFall: mv(431, sp("snappy"), fade(150)),
  wave: mv(431, sp("snappy"), fade(150)),
  surfaceFromDepth: mv(431, sp("snappy"), fade(150)),
  deal: mv(431, sp("snappy"), fade(150)),
  letterReveal: mv(345, sp("letter"), INSTANT),
  typingReveal: mv(50, sp("tick"), INSTANT),
  wordStream: mv(120, cv("fadeIn", 120), INSTANT),
  lightFollowsTheStory: mv(900, cv("tintShift", 900), fade(200)),
  dimShift: mv(400, cv("dimShift", 400), INSTANT),
  stepIntoTheLight: mv(1100, sp("celebrate"), fade(200)),
  throw: mv(558, sp("zoom"), fade(150)),
  catch: mv(0, NONE, SAME),
  rubberBand: mv(414, sp("settle"), INSTANT),
  meniscusRefresh: mv(467, sp("lens"), FROZEN),
  scrubLens: mv(467, sp("lens"), fade(150)),
  chapterCardRise: mv(558, sp("zoom"), fade(200)),
  novelNext: mv(615, sp("page"), fade(200)),
  seamChip: mv(250, cv("materialize", 250), fade(150)),
  cruiseRamp: mv(400, lin(400), INSTANT),
  panelCamera: mv(392, sp("camera"), fade(120)),
  hitLens: mv(392, sp("camera"), fade(120)),
  pageSlide: mv(615, sp("page"), fade(160)),
  pageLift: mv(615, sp("page"), fade(160)),
  paperRipple: mv(615, sp("page"), fade(200)),
  liquidFill: mv(467, sp("lens"), INSTANT),
  holdFill: mv(1200, sp("dismiss"), SAME),
  skinMelt: mv(615, cv("dematerialize", 615), fade(200)),
  dropletReveal: mv(1200, sp("lens"), fade(200)),
  cardFlip: mv(436, sp("smooth"), fade(200)),
  deckLiftOff: mv(436, sp("smooth"), fade(150)),
  storyStack: mv(615, sp("page"), fade(200)),
  thinkingOrbit: mv(1400, lin(1400), FROZEN),
  causticPress: mv(150, cv("glowIn", 150), NONE_R),
  followRing: mv(700, cv("followRing", 700), NONE_R),
  specularSweep: mv(520, cv("sweep", 520), NONE_R),
  streakFlare: mv(643, sp("celebrate"), INSTANT),
  recordSparks: mv(900, cv("fadeOut", 900), NONE_R),
  goalRingClose: mv(431, sp("snappy"), INSTANT),
  reactionBloomAndArc: mv(467, sp("lens"), fade(150)),
  presenceDrift: mv(1064, sp("drift"), INSTANT),
  liveRingBreathe: mv(2400, lin(2400), FROZEN),
  rainOnGlass: mv(0, lin(0), NONE_R),
  beadFlicker: mv(120, lin(120), INSTANT),
  beadPulse: mv(289, sp("tick"), NONE_R),
  genreField: mv(0, NONE, FROZEN),
  densityReflow: mv(431, sp("snappy"), INSTANT),
  pinFly: mv(558, sp("zoom"), INSTANT),
  fanOpen: mv(643, sp("celebrate"), NONE_R),
  drain: mv(467, sp("lens"), INSTANT),
  ambientDrift: mv(1064, sp("drift"), FROZEN),
  lightFollow: mv(149, sp("track"), NONE_R),
  heroTilt: mv(149, sp("track"), NONE_R),
  orbIdleDrift: mv(0, lin(0), FROZEN),
  lensBob: mv(0, lin(0), FROZEN),
  errorShake: mv(420, lin(420), NONE_R),
  skeletonShimmer: mv(1400, lin(1400), FROZEN),
  titleCapsule: mv(431, cv("materialize", 431), fade(150)),
  dockMerge: mv(149, sp("track"), NONE_R),
  addressDrain: mv(558, sp("zoom"), fade(200)),
  slabCondense: mv(558, cv("fadeOut", 558), fade(200)),
  lensSplit: mv(643, sp("celebrate"), fade(150)),
  fieldRipple: mv(600, cv("fadeIn", 600), NONE_R),
  orbitingCovers: mv(1064, sp("drift"), FROZEN),
  orbLift: mv(558, sp("zoom"), fade(200)),
  dotsMerge: mv(431, sp("snappy"), fade(200)),
  coverArc: mv(289, sp("tick"), fade(150)),
  avatarArc: mv(280, sp("tick"), fade(150)),
  orbsFlyOut: mv(558, sp("zoom"), fade(150)),
  tagFlight: mv(558, sp("zoom"), fade(200)),
  plusOne: mv(643, sp("celebrate"), fade(150)),
  rowPulse: mv(900, cv("fadeOut", 900), INSTANT),
  skinPreview: mv(0, NONE, SAME),
  flameFlicker: mv(1064, sp("drift"), FROZEN),
  countUp: mv(1064, sp("drift"), INSTANT),
  pagePile: mv(0, NONE, FROZEN),
  podiumDrop: mv(120, NONE, fade(150)),
  liquidSpinner: mv(900, lin(900), FROZEN),
  buttonDots: mv(289, sp("tick"), FROZEN),
  countPop: mv(289, sp("tick"), fade(150)),
  queuedRing: mv(4000, lin(4000), FROZEN),
  orbBreathe: mv(2000, lin(2000), FROZEN),
  spotlightDrop: mv(467, sp("lens"), fade(200)),
  lensPop: mv(467, sp("lens"), fade(150)),
  chartRise: mv(431, sp("snappy"), fade(150)),
  spoilerUnseal: mv(160, lin(160), INSTANT),
  tapLight: mv(300, lin(300), SAME),
  sceneGlyphLoops: mv(0, NONE, FROZEN),
  quickType: mv(12, lin(12), INSTANT),
  speakingOrbPulse: mv(0, NONE, FROZEN),
  previewOrbPulse: mv(0, NONE, FROZEN),
  levelBars: mv(0, NONE, FROZEN),
  cruiseDiscSpin: mv(0, lin(0), FROZEN),
  highlightBand: mv(431, sp("snappy"), fade(120)),
  lozengeMorph: mv(431, sp("snappy"), fade(120)),
  followScroll: mv(414, sp("settle"), INSTANT),
  lensHop: mv(643, sp("celebrate"), fade(150)),
  cardDrop: mv(643, sp("celebrate"), fade(150)),
} as const satisfies Record<MotionName, MoveSpec>;

const reducedQuery = () => typeof window !== "undefined" && window.matchMedia("(prefers-reduced-motion: reduce)").matches;
const inAppReduced = () => typeof document !== "undefined" && document.documentElement.dataset.motion === "reduced";

/** True for the OS query or the in-app switch (`html[data-motion="reduced"]`), which Motion's own hook cannot see. */
export const isGlassReduced = () => reducedQuery() || inAppReduced();

function subscribeReduced(cb: () => void) {
  const mq = window.matchMedia("(prefers-reduced-motion: reduce)");
  mq.addEventListener("change", cb);
  const mo = new MutationObserver(cb);
  mo.observe(document.documentElement, { attributes: true, attributeFilter: ["data-motion"] });
  return () => { mq.removeEventListener("change", cb); mo.disconnect(); };
}

export const useGlassReduced = () => useSyncExternalStore(subscribeReduced, isGlassReduced, () => false);

/** The Glass tree's motion config: Motion follows the OS query itself. */
export function GlassMotionConfig({ children }: { children: ReactNode }) {
  return createElement(MotionConfig, { reducedMotion: "user" }, children);
}

const TRANSFORM_KEYS = /^(x|y|z|scale[XY]?|rotate[XYZ]?|skew[XY]?|translate.*|perspective|transformPerspective|originX|originY)$/;

type AnimateFn = (target: unknown, keyframes: unknown, options?: unknown) => AnimationPlaybackControls;

export interface PlayOptions {
  /** release velocity handed to physical springs (law 4), in the units of the animated value per second */
  velocity?: number;
  onComplete?: () => void;
  delay?: number;
}

/**
 * Start a named move. `target` is anything Motion's `animate` takes (an element, a MotionValue, a number
 * with onUpdate). Under Reduce Motion the row's replacement is swapped in. Returns Motion's controls, so a
 * caller can `stop()` them: the catch. Every call is recorded for the motion-timings overlay.
 */
export function play(name: MotionName, target: unknown, keyframes: unknown, opts: PlayOptions = {}): AnimationPlaybackControls {
  const spec: MoveSpec | undefined = (MOTION_TABLE as Record<string, MoveSpec>)[name];
  if (!spec) {
    if (process.env.NODE_ENV !== "production") throw new Error(`play(): unknown motion "${name}"`);
    return animate(target as never, keyframes as never, { duration: 0 } as never);
  }
  const reduced = isGlassReduced();
  let transition: Record<string, unknown> = { ...spec.transition };
  let kf = keyframes;
  if (reduced) {
    const r = spec.reduced;
    if (r.kind === "fade") {
      transition = { duration: r.ms / 1000, ease: "linear" };
      if (kf && typeof kf === "object" && !Array.isArray(kf) && !("get" in (target as object))) {
        const kept = Object.fromEntries(Object.entries(kf).filter(([k]) => !TRANSFORM_KEYS.test(k)));
        kf = Object.keys(kept).length ? kept : kf; // a move with nothing but movement still ends in its end state
        if (kf === keyframes && Object.keys(kf as object).every((k) => TRANSFORM_KEYS.test(k))) transition = { duration: 0 };
      }
    } else if (r.kind !== "same") transition = { duration: 0 };
  }
  if (transition.type === "spring" && opts.velocity !== undefined) transition.velocity = opts.velocity;
  if (opts.delay) transition.delay = opts.delay;
  const rec = beginRecord(name, MOTION_LABELS[name], spec.ms);
  const finish = trackFrames(rec);
  const controls = (animate as unknown as AnimateFn)(target, kf, {
    ...transition,
    onComplete: () => { finish(); opts.onComplete?.(); },
  });
  for (const k of ["stop", "cancel", "complete"] as const) {
    const orig = controls[k]?.bind(controls);
    if (orig) controls[k] = () => { orig(); finish(); };
  }
  return controls;
}

/** What a caller should do with a loop or a purely decorative move under Reduce Motion. */
export const reducedKind = (name: MotionName): ReducedSpec["kind"] => MOTION_TABLE[name].reduced.kind;
