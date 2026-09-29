"use client";

import { motion, useMotionValue } from "motion/react";
import { useContext, useRef } from "react";
import { GlassHostContext } from "../glass/GlassSurface";
import { haptic } from "../haptics";
import { isGlassReduced } from "../motion";
import { Icon } from "./Icon";
import { springTo } from "./overlay-utils";

/** Two 36 px fill2 circles (wellOnGlass inside T4/T5 glass) with - and +, the value in mono 15 between them, hit 44 each. Past a limit the value stretches 4 px toward the pressed side and springs back with `detent.limit`. */
export function Stepper({ value, onChange, min = 0, max = 99, step = 1, label, format, "data-testid": tid }: { value: number; onChange: (v: number) => void; min?: number; max?: number; step?: number; label: string; format?: (v: number) => string; "data-testid"?: string }) {
  const onGlass = useContext(GlassHostContext);
  const nudge = useMotionValue(0);
  const el = useRef<HTMLDivElement | null>(null);
  const go = (dir: 1 | -1) => {
    const next = value + dir * step;
    if (next < min || next > max) {
      haptic("detent.limit");
      if (!isGlassReduced()) { nudge.set(4 * dir); springTo(nudge, 0, "tick"); }
      return;
    }
    haptic("select");
    onChange(next);
  };
  return (
    <div
      ref={el}
      role="spinbutton"
      aria-label={label}
      aria-valuenow={value}
      aria-valuemin={min}
      aria-valuemax={max}
      aria-valuetext={format?.(value)}
      tabIndex={0}
      className="g-stepper"
      data-well={onGlass ? "glass" : undefined}
      data-testid={tid}
      onKeyDown={(e) => {
        if (e.key === "ArrowUp") { e.preventDefault(); go(1); }
        else if (e.key === "ArrowDown") { e.preventDefault(); go(-1); }
        else if (e.key === "Home") { e.preventDefault(); onChange(min); }
        else if (e.key === "End") { e.preventDefault(); onChange(max); }
      }}
    >
      <button type="button" tabIndex={-1} className="g-stepper__btn" aria-label={`Decrease ${label}`} onClick={() => go(-1)}><span><Icon name="minus" size={16} /></span></button>
      <motion.span className="g-stepper__value" style={{ x: nudge }} aria-hidden="true">{format ? format(value) : value}</motion.span>
      <button type="button" tabIndex={-1} className="g-stepper__btn" aria-label={`Increase ${label}`} onClick={() => go(1)}><span><Icon name="plus" size={16} /></span></button>
    </div>
  );
}
