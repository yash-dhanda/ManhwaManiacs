import { project } from "../physics/project";

/** Image viewer maths (glass 7.31). */
export const DISMISS_PX = 180;
export const DISMISS_VELOCITY = 800;
export const MIN_ZOOM = 1;
export const MAX_ZOOM = 4;
export const DOUBLE_TAP_ZOOM = 2.5;

/** At 1x a vertical drag of `dy` px: scale 1 - min(|dy|/1200, 0.15), radius 0 to 28, backdrop opacity 1 - min(|dy|/320, 1). */
export function dragDismiss(dy: number) {
  const a = Math.abs(dy);
  return { scale: 1 - Math.min(a / 1200, 0.15), radius: 28 * Math.min(1, a / 200), backdrop: 1 - Math.min(a / 320, 1) };
}

/** A release dismisses when the projection passes 180 px either way or the speed is 800 px/s or more. */
export const shouldDismiss = (dy: number, vy: number) => Math.abs(project(dy, vy) - 0) > DISMISS_PX || Math.abs(vy) >= DISMISS_VELOCITY;

/** The dismiss line is crossed when the projected drag passes 180 px. */
export const pastDismissLine = (dy: number, vy: number) => Math.abs(project(dy, vy)) > DISMISS_PX;

/** Two taps within 280 ms and 24 px are a double tap. */
export const isDoubleTap = (a: { t: number; x: number; y: number } | null, b: { t: number; x: number; y: number }) => !!a && b.t - a.t <= 280 && Math.hypot(b.x - a.x, b.y - a.y) <= 24;

/** Pan that keeps the point `p` (relative to the image centre) fixed while scale goes from `s0` to `s1`. */
export const keepFocal = (pan: number, p: number, s0: number, s1: number) => p - (p - pan) * (s1 / s0);

/** Pan limit at a scale: half the overflow. */
export const panLimit = (size: number, scale: number) => Math.max(0, ((scale - 1) * size) / 2);
