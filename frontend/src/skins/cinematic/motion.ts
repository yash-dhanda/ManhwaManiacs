"use client";
import { animate, MotionConfig, type AnimationPlaybackControlsWithThen, type DOMKeyframesDefinition } from "motion/react";
import { createElement, useEffect, useState, type ReactNode } from "react";
import { usePathname } from "next/navigation";
import { startMove } from "@/lib/motion-timings";
import { durMs, ease, scalar } from "./tokens.generated";
import type { MotionName } from "./motion.generated";

/** The named-move union of §4.5 (written by shared/01). */
export type CineMotionName = MotionName;

// ---- pure stagger maths (§4.6) ----
export const gridDelay = (index: number, row: number): number =>
  Math.min(scalar.staggerGrid.cap, index * scalar.staggerGrid.item + row * scalar.staggerGrid.row);
export const listDelay = (i: number): number => Math.min(scalar.staggerList.cap, scalar.staggerList.item * i);
/** ms between letters; n = graphemes excluding spaces. */
export const letterStep = (n: number): number => Math.min(scalar.staggerLetter.item, scalar.staggerLetter.cap / Math.max(1, n - 1));
export const wordDelay = (i: number): number => scalar.staggerWord.item * i;
export const typedCount = (elapsedMs: number, length: number): number =>
  Math.min(length, Math.max(0, Math.floor(elapsedMs / durMs.type)));

// ---- rack cap (§4.5, §15.6): 12 rack at once per screen, the 13th develops ----
export const RACK_CAP = 12;
let racking = 0;
export const rackCount = () => racking;
export const resetRackCount = () => { racking = 0; };
/** Claim a rack slot: true while under the cap. Release with `releaseRack()` when the move ends. */
export function claimRack(): boolean {
  if (racking >= RACK_CAP) return false;
  racking++;
  return true;
}
export const releaseRack = () => { racking = Math.max(0, racking - 1); };

// ---- entrance decision (§4.6) ----
export type Entrance = "set" | "dissolve" | "none";
/** Pure decision table: `seen` = this pathname:listKey already ran in the session. */
export function decideEntrance(seen: boolean, hadSkeleton: boolean): Entrance {
  if (seen) return "none";
  return hadSkeleton ? "dissolve" : "set";
}
const seenLists = new Set<string>();
export const resetEntranceSeen = () => seenLists.clear();
/** "set" on the first data paint of a list this session; "dissolve" after a skeleton, refetch, append or pull; "none" when already run. */
export function useEntrance(listKey: string, { hadSkeleton = false, refetched = false }: { hadSkeleton?: boolean; refetched?: boolean } = {}): Entrance {
  const pathname = usePathname() ?? "";
  const key = `${pathname}:${listKey}`;
  // Frozen at first render; a later refetch, append or pull (flag flips on) upgrades the same mounted list to "dissolve".
  const flag = hadSkeleton || refetched;
  const [first] = useState(() => ({ flag, d: decideEntrance(seenLists.has(key), flag) }));
  const decision: Entrance = flag && !first.flag ? "dissolve" : first.d;
  useEffect(() => { seenLists.add(key); }, [key]);
  return decision;
}

// ---- reduced motion (§4.8, §14.1): OS setting OR html[data-motion="reduced"] ----
export function readReduced(): boolean {
  if (typeof document === "undefined") return false;
  return window.matchMedia("(prefers-reduced-motion: reduce)").matches || document.documentElement.dataset.motion === "reduced";
}
export function useCineReduced(): boolean {
  const [reduced, setReduced] = useState(false);
  useEffect(() => {
    const update = () => setReduced(readReduced());
    update();
    const mq = window.matchMedia("(prefers-reduced-motion: reduce)");
    mq.addEventListener("change", update);
    const mo = new MutationObserver(update);
    mo.observe(document.documentElement, { attributes: true, attributeFilter: ["data-motion"] });
    return () => { mq.removeEventListener("change", update); mo.disconnect(); };
  }, []);
  return reduced;
}
/** Mount once per shell (web/06) and in the gallery. */
export function MotionRoot({ children }: { children: ReactNode }) {
  const reduced = useCineReduced();
  return createElement(MotionConfig, { reducedMotion: reduced ? "always" : "user" }, children);
}

/** True after `ms` of waiting while `active` (skeleton 120 ms, leader dial 400 ms). */
export function useDelayedFlag(ms: number, active = true): boolean {
  const [on, setOn] = useState(false);
  useEffect(() => {
    if (!active) return;
    const t = setTimeout(() => setOn(true), ms);
    return () => { clearTimeout(t); setOn(false); };
  }, [ms, active]);
  return on && active;
}

// ---- play(): the single entry point for named moves ----
type Target = Element | null;
export type PlayOpts = {
  delayMs?: number; from?: DOMKeyframesDefinition; to?: DOMKeyframesDefinition; onComplete?: () => void;
  /** Override the table duration (Dip out is 160 ms and in 240 ms; blades take the stagger on top). */
  durationMs?: number; easeOverride?: readonly number[] | string;
  /** false: no recorder entry (a caller records one entry for a whole choreography). */
  record?: boolean;
};

type Def = { ms: number; ease: readonly number[] | string; from: DOMKeyframesDefinition; to: DOMKeyframesDefinition; repeat?: boolean };
const settle = ease.settle;
const DEFS: Partial<Record<CineMotionName, Def>> = {
  set: { ms: durMs.column, ease: settle, from: { opacity: 0, y: 8 }, to: { opacity: 1, y: 0 } },
  ruleDraw: { ms: durMs.spread, ease: settle, from: { scaleX: 0 }, to: { scaleX: 1 } },
  rackFocus: { ms: durMs.rack, ease: settle, from: { opacity: 0, filter: "blur(14px) brightness(0.6)", scale: 1.03 }, to: { opacity: 1, filter: "blur(0px) brightness(1)", scale: 1 } },
  develop: { ms: durMs.rack, ease: settle, from: { opacity: 0, filter: "brightness(0.6)", scale: 1.03 }, to: { opacity: 1, filter: "brightness(1)", scale: 1 } },
  dissolve: { ms: durMs.beat, ease: settle, from: { opacity: 0 }, to: { opacity: 1 } },
  paddlePage: { ms: durMs.irisOut, ease: ease.turn, from: {}, to: {} },
  ruleSlide: { ms: durMs.column, ease: settle, from: {}, to: {} },
  slate: { ms: durMs.column, ease: settle, from: {}, to: {} },
  // web/05 overlay moves (CSS classes in motion.css carry the visuals; play() is for JS-driven callers and the recorder)
  insert: { ms: durMs.column, ease: settle, from: { clipPath: "inset(0 0 100% 0)" }, to: { clipPath: "inset(0 0 0% 0)" } },
  rise: { ms: durMs.rise, ease: settle, from: { opacity: 0, y: 24 }, to: { opacity: 1, y: 0 } },
  panel: { ms: durMs.column, ease: settle, from: { x: "100%" }, to: { x: "0%" } },
  arm: { ms: durMs.arm, ease: ease.linear, from: { scaleX: 0 }, to: { scaleX: 1 } },
  lightbox: { ms: durMs.spread, ease: ease.turn, from: {}, to: {} },
  dip: { ms: durMs.beat, ease: ease.lift, from: { opacity: 0 }, to: { opacity: 1 } },
  columnWipe: { ms: durMs.wipeClose, ease: settle, from: { scaleY: 0 }, to: { scaleY: 1 } },
  iris: { ms: durMs.spread, ease: ease.turn, from: {}, to: {} },
  folioFlip: { ms: durMs.tick, ease: ease.set, from: { y: "100%", opacity: 0 }, to: { y: "0%", opacity: 1 } },
};

/**
 * Play a named move on `target` (Motion `animate()`), reporting it to the web/02 recorder under the same
 * name. Returns the controls so callers can retarget (§4.7). Rack focus beyond the cap of 12 downgrades to Develop.
 * Moves with a caller-supplied `from`/`to` (paddlePage, ruleSlide, slate) take their keyframes from `opts`.
 */
export function play(name: CineMotionName, target: Target, opts: PlayOpts = {}): AnimationPlaybackControlsWithThen | null {
  if (!target) return null;
  let move = name;
  let racked = false;
  if (name === "rackFocus") { racked = claimRack(); if (!racked) move = "develop"; }
  const def = DEFS[move];
  if (!def) throw new Error(`play(): move "${name}" arrives with the step that first uses it`);
  const to = opts.to ?? def.to;
  const from = opts.from ?? def.from;
  const ms = opts.durationMs ?? def.ms;
  const rec = opts.record === false ? { end: () => {} } : startMove(move, ms + (opts.delayMs ?? 0));
  const done = () => { if (racked) releaseRack(); rec.end(); opts.onComplete?.(); };
  // Per-property keyframes [from, to]; a property without a `from` animates from its current value (§4.7).
  const frames: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(to)) frames[k] = k in from ? [(from as Record<string, unknown>)[k], v] : v;
  const controls = animate(target as Element, frames as never, { duration: ms / 1000, delay: (opts.delayMs ?? 0) / 1000, ease: (opts.easeOverride ?? def.ease) as never });
  controls.then(done, done);
  return controls;
}

// Later steps import the reveal components from here (§15.2).
export { SetHeading, useTitleSignal } from "./primitives/SetHeading";
export { TypedHeadline, useTyped } from "./primitives/TypedHeadline";
export { RackImage, Drift, Flicker, RuleDraw } from "./motion-components";

// Shell motion (web/06): one import place for every screen.
export { ColumnWipe, Iris, dip, columnWipe, irisClose } from "./shell/Overlays";
export { enterReader, useReaderPrefetch } from "./shell/reader-entry";
