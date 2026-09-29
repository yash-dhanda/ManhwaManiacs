"use client";

import { useEffect, type RefObject } from "react";
import { isGlassReduced, play } from "../motion";

export const WAVE_SPEED = 1.6; // px per ms
export const WAVE_CAP = 240; // ms

/** delay_i = min(distance_i / 1.6 px/ms, 240 ms) from the cause point (DESIGN 4.8). */
export function waveDelays(points: readonly { x: number; y: number }[], cause: { x: number; y: number }): number[] {
  return points.map((p) => Math.min(Math.hypot(p.x - cause.x, p.y - cause.y) / WAVE_SPEED, WAVE_CAP));
}

export type WaveCause = { x: number; y: number } | "top-left" | "centre";

/**
 * Runs each `[data-wave-item]` inside `ref` (only those inside the viewport) through the Wave move: opacity 0 to 1 over `fadeIn`,
 * a 12 px translate toward rest from the cause's direction plus scale 0.98 to 1 on `snappy`. Exits never stagger.
 * Reduced motion: everything fades together over 150 ms. `trigger` re-runs it (a new data arrival, a route arrival).
 */
export function useWave(ref: RefObject<HTMLElement | null>, cause: WaveCause, trigger: unknown = 0): void {
  useEffect(() => {
    const root = ref.current;
    if (!root) return;
    const vw = window.innerWidth, vh = window.innerHeight;
    const items = Array.from(root.querySelectorAll<HTMLElement>("[data-wave-item]")).filter((el) => { const r = el.getBoundingClientRect(); return r.bottom > 0 && r.top < vh && r.right > 0 && r.left < vw; });
    if (!items.length) return;
    const rects = items.map((el) => el.getBoundingClientRect());
    const rr = root.getBoundingClientRect();
    const c = cause === "top-left" ? { x: rr.left, y: rr.top } : cause === "centre" ? { x: rr.left + rr.width / 2, y: rr.top + rr.height / 2 } : cause;
    const centres = rects.map((r) => ({ x: r.left + r.width / 2, y: r.top + r.height / 2 }));
    const delays = waveDelays(centres, c);
    const reduced = isGlassReduced();
    const ctl = items.map((el, i) => {
      const dx = centres[i].x - c.x, dy = centres[i].y - c.y, d = Math.hypot(dx, dy) || 1;
      el.style.opacity = "0";
      return play("wave", el, reduced ? { opacity: 1 } : { opacity: 1, x: [(dx / d) * 12, 0], y: [(dy / d) * 12, 0], scale: [0.98, 1] }, { delay: reduced ? 0 : delays[i] / 1000, onComplete: () => { el.style.opacity = ""; } });
    });
    return () => ctl.forEach((k) => k.stop());
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [ref, trigger]);
}
