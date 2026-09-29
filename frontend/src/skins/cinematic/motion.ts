"use client";
import { animate, MotionConfig, type AnimationPlaybackControlsWithThen, type DOMKeyframesDefinition } from "motion/react";
import { createElement, useEffect, useRef, useState, type ReactNode } from "react";
import { usePathname } from "next/navigation";
import { startMove } from "@/lib/motion-timings";
import { dur, durMs, ease, scalar } from "./tokens.generated";
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
  const [decision] = useState<Entrance>(() => {
    const d = decideEntrance(seenLists.has(key), hadSkeleton || refetched);
    return d;
  });
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
    if (!active) { setOn(false); return; }
    const t = setTimeout(() => setOn(true), ms);
    return () => clearTimeout(t);
  }, [ms, active]);
  return on;
}

// ---- play(): the single entry point for named moves ----
type Target = Element | null;
export type PlayOpts = { delayMs?: number; from?: DOMKeyframesDefinition; to?: DOMKeyframesDefinition; onComplete?: () => void };

type Def = { ms: number; ease: readonly number[] | string; from: DOMKeyframesDefinition; to: DOMKeyframesDefinition; repeat?: boolean };
const settle = ease.settle;
const DEFS: Partial<Record<CineMotionName, Def>> = {
  set: { ms: 320, ease: settle, from: { opacity: 0, y: 8 }, to: { opacity: 1, y: 0 } },
  ruleDraw: { ms: 480, ease: settle, from: { scaleX: 0 }, to: { scaleX: 1 } },
  rackFocus: { ms: 520, ease: settle, from: { opacity: 0, filter: "blur(14px) brightness(0.6)", scale: 1.03 }, to: { opacity: 1, filter: "blur(0px) brightness(1)", scale: 1 } },
  develop: { ms: 520, ease: settle, from: { opacity: 0, filter: "brightness(0.6)", scale: 1.03 }, to: { opacity: 1, filter: "brightness(1)", scale: 1 } },
  dissolve: { ms: 160, ease: settle, from: { opacity: 0 }, to: { opacity: 1 } },
  paddlePage: { ms: 560, ease: ease.turn, from: {}, to: {} },
  ruleSlide: { ms: 320, ease: settle, from: {}, to: {} },
  slate: { ms: 320, ease: settle, from: {}, to: {} },
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
  const rec = startMove(move, def.ms + (opts.delayMs ?? 0));
  const done = () => { if (racked) releaseRack(); rec.end(); opts.onComplete?.(); };
  // Per-property keyframes [from, to]; a property without a `from` animates from its current value (§4.7).
  const frames: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(to)) frames[k] = k in from ? [(from as Record<string, unknown>)[k], v] : v;
  const controls = animate(target as Element, frames as never, { duration: def.ms / 1000, delay: (opts.delayMs ?? 0) / 1000, ease: def.ease as never });
  controls.then(done, done);
  return controls;
}
