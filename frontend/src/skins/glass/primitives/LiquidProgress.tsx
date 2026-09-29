"use client";

import { motionValue } from "motion/react";
import { useEffect, useMemo, useRef, type CSSProperties } from "react";
import { play } from "../motion";
import type { MotionName } from "../motion.generated";

export type LiquidTone = "iris" | "success" | "warning" | "danger";

const clamp = (v: number, lo: number, hi: number) => Math.min(hi, Math.max(lo, v));
/** The meniscus bulge: 3 px + clamp(velocity / 400, -3, 3) px, velocity in px/s along the track. */
export const meniscus = (velocityPx: number) => 3 + clamp(velocityPx / 400, -3, 3);

/**
 * A liquid level that fills its nearest positioned ancestor (position:absolute; inset:0; inherits the capsule's radius;
 * overflow hidden; pointer-events none; aria-hidden). `value` 0..1, left to right, on `lens` (k 223.8, c 20.94) so a jump
 * sloshes once; the leading edge curves 3 px and wobbles with velocity. `paused` freezes the meniscus. Reduced motion: jumps.
 */
export function LiquidProgress({ value, tone = "iris", paused = false, direct = false, move = "liquidFill", className, style }: { value: number; tone?: LiquidTone; paused?: boolean; /** follow `value` every frame with no spring (the hold fill is driven by a clock) */ direct?: boolean; /** the named move that carries a change (default liquidFill on `lens`; the hold drain uses holdFill on `dismiss`) */ move?: MotionName; className?: string; style?: CSSProperties }) {
  const host = useRef<HTMLSpanElement>(null);
  const lvl = useMemo(() => motionValue(clamp(value, 0, 1)), []); // eslint-disable-line react-hooks/exhaustive-deps
  const first = useRef(true);
  useEffect(() => {
    const el = host.current;
    if (!el) return;
    const write = () => {
      const w = el.offsetWidth || 1;
      el.style.setProperty("--lv", String(clamp(lvl.get(), 0, 1)));
      el.style.setProperty("--men", `${paused ? 3 : meniscus(lvl.getVelocity() * w)}px`);
    };
    write();
    const off = lvl.on("change", write);
    return off;
  }, [lvl, paused]);
  useEffect(() => {
    if (first.current) { first.current = false; return; }
    if (direct) { lvl.stop(); lvl.set(clamp(value, 0, 1)); return; }
    const c = play(move, lvl, clamp(value, 0, 1));
    return () => c.stop();
  }, [value, lvl, direct, move]);
  return <span ref={host} className={`g-liquid${className ? ` ${className}` : ""}`} data-tone={tone} data-paused={paused ? "" : undefined} aria-hidden="true" style={{ "--lv": clamp(value, 0, 1), ...style } as CSSProperties}><i /></span>;
}
