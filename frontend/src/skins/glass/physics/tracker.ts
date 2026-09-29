import type { MotionValue } from "motion/react";
import { threshold } from "../tokens.generated";

export interface PointerLike {
  clientX: number;
  clientY: number;
  timeStamp: number;
  pointerType?: string;
}

const WINDOW_MS = 100;

/** Least-squares slope of value over time, px/s; 0 with fewer than two samples. */
export function slope(samples: readonly { t: number; v: number }[]) {
  if (samples.length < 2) return 0;
  const n = samples.length;
  const t0 = samples[0].t;
  let st = 0, sv = 0, stt = 0, stv = 0;
  for (const s of samples) {
    const t = s.t - t0;
    st += t; sv += s.v; stt += t * t; stv += t * s.v;
  }
  const den = n * stt - st * st;
  return den === 0 ? 0 : ((n * stv - st * sv) / den) * 1000;
}

/** Drag tracker: offset from the start, velocity from a least-squares fit over the last 100 ms, per-pointer slop. */
export function createTracker(axis: "x" | "y" = "x") {
  let from = 0, origin = 0, slop = 0, active = false, slopped = false;
  let samples: { t: number; v: number }[] = [];
  const val = (e: PointerLike) => (axis === "x" ? e.clientX : e.clientY);
  const offsetOf = (v: number) => from + v - origin;
  return {
    start(e: PointerLike, fromOffset = 0) {
      active = true; slopped = false; from = fromOffset; origin = val(e);
      slop = e.pointerType === "touch" ? threshold.dragSlopTouch : threshold.dragSlopMouse;
      samples = [{ t: e.timeStamp, v: origin }];
    },
    /** Returns the offset once the slop is passed (null before). */
    move(e: PointerLike): number | null {
      if (!active) return null;
      const v = val(e);
      samples.push({ t: e.timeStamp, v });
      while (samples.length > 2 && e.timeStamp - samples[0].t > WINDOW_MS) samples.shift();
      if (!slopped && Math.abs(v - origin) < slop) return null;
      slopped = true;
      return offsetOf(v);
    },
    end() {
      active = false;
      const last = samples[samples.length - 1];
      const recent = last ? samples.filter((s) => last.t - s.t <= WINDOW_MS) : [];
      return { offset: last ? offsetOf(last.v) : from, velocity: slope(recent) };
    },
  };
}

/** Catch (DESIGN 4.3, 4.9): stop what runs, hand back the exact state. `onCatch` fires the motion.catch haptic when it was animating. */
export function catchMotion(value: MotionValue<number>, onCatch?: () => void) {
  const animating = value.isAnimating();
  const velocity = value.getVelocity();
  const from = value.get();
  value.stop();
  if (animating) onCatch?.();
  return { from, velocity };
}
