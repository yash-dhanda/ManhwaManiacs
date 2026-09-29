import { physics } from "../tokens.generated";

const RATE = physics.decelerationRate;

/** Where a fling ends (DESIGN 4.4): pos + (v / 1000) x rate / (1 - rate), i.e. pos + 0.499 x v. v in px/s. */
export const project = (pos: number, v: number) => pos + (v / 1000) * (RATE / (1 - RATE));

/** project(), capped at `cap` viewport lengths of travel (physics.projectionCap = 1). */
export function projectCapped(pos: number, v: number, cap: number, viewport = 1) {
  const travel = Math.max(-cap * viewport, Math.min(cap * viewport, project(pos, v) - pos));
  return pos + travel;
}

export const nearest = (points: readonly number[], x: number) =>
  points.reduce((best, p) => (Math.abs(p - x) < Math.abs(best - x) ? p : best), points[0]);

/** Rail snap: the projected landing, rounded to a multiple of the stride. */
export const railSnap = (offset: number, v: number, stride: number) => Math.round(project(offset, v) / stride) * stride;
