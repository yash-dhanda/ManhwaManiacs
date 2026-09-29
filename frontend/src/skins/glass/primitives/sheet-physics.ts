import { project } from "../physics/project";
import { rubberband } from "../physics/rubberband";

/** Sheet detents on phones (glass 7.10, 8.0.3). Tops are px from the viewport top. */
export type DetentName = "peek" | "medium" | "large";
export interface Detent { name: DetentName; top: number }

export const PEEK_HEIGHT = 96;
export const MEDIUM_RATIO = 0.52;
export const LARGE_GAP = 10;
export const RUBBER_CAP = 60;
export const RUBBER_C = 0.55;
export const DISMISS_VELOCITY = 1500;
export const DISMISS_FRACTION = 0.5;

/** `peek` 96 px tall, `medium` 52 % of the viewport, `large` viewport - safe-top - 10. Sorted highest first. */
export function detentTops(vh: number, safeTop: number, names: readonly DetentName[]): Detent[] {
  const top: Record<DetentName, number> = { peek: vh - PEEK_HEIGHT, medium: vh - vh * MEDIUM_RATIO, large: safeTop + LARGE_GAP };
  return [...new Set(names)].map((name) => ({ name, top: top[name] })).sort((a, b) => a.top - b.top);
}

export type Pick = { kind: "detent"; name: DetentName; top: number } | { kind: "dismiss" };

/** The projected top edge of a release (DESIGN 4.4), velocity in px/s, positive down. */
export const projectedTop = (top: number, velocity: number) => project(top, velocity);

/** The line below which a release dismisses: the lowest detent's top plus half the sheet's height there. */
export const dismissLine = (lowestTop: number, sheetHeight: number) => lowestTop + DISMISS_FRACTION * sheetHeight;

/**
 * On release: the detent nearest the projected top, or `dismiss` when the projection is below the lowest detent by more
 * than half the sheet's height at that detent, or when the sheet sits at the lowest detent and leaves at 1,500 px/s or more.
 */
export function pickDetent({ top, velocity, detents, sheetHeight }: { top: number; velocity: number; detents: readonly Detent[]; sheetHeight: number }): Pick {
  const sorted = [...detents].sort((a, b) => a.top - b.top);
  const lowest = sorted[sorted.length - 1];
  const p = projectedTop(top, velocity);
  if (p > dismissLine(lowest.top, sheetHeight)) return { kind: "dismiss" };
  if (top >= lowest.top - 1 && velocity >= DISMISS_VELOCITY) return { kind: "dismiss" };
  const best = sorted.reduce((b, d) => (Math.abs(d.top - p) < Math.abs(b.top - p) ? d : b), sorted[0]);
  return { kind: "detent", name: best.name, top: best.top };
}

/** Above the top detent the displacement follows rubberband(x, viewport, 0.55), capped at 60 px. `x` is px above (positive). */
export const stretchAbove = (x: number, vh: number) => Math.min(RUBBER_CAP, rubberband(Math.max(0, x), vh, RUBBER_C));

/** Rendered offset for a raw offset: `raw` is the sheet's translate relative to the top detent (negative = above it). */
export const applyRubberBand = (raw: number, vh: number) => (raw >= 0 ? raw : -stretchAbove(-raw, vh));

/** 0 at `medium` or lower, 1 at `large`, following the sheet's top edge (never time). */
export function largeProgress(top: number, mediumTop: number, largeTop: number): number {
  const span = mediumTop - largeTop;
  if (span <= 0) return 0;
  return Math.min(1, Math.max(0, (mediumTop - top) / span));
}

/** Inset 8 px at partial detents, lerping to 0 over the last 20 % of travel toward `large`. */
export const insetAt = (p: number) => 8 * (1 - Math.min(1, Math.max(0, (p - 0.8) / 0.2)));

/** Bottom corner radius: 36 at partial detents, 0 once attached. Top corners stay 36. */
export const bottomRadiusAt = (p: number) => 36 * (1 - Math.min(1, Math.max(0, (p - 0.8) / 0.2)));

/** The material cross-fade: T4 glass to opaque solid as the sheet goes tall (0 = glass, 1 = solid). */
export const solidnessAt = (p: number) => Math.min(1, Math.max(0, (p - 0.5) / 0.5));

/** Page recession at `large`: scale 1 - 0.06 p, radius 12 p, blur 8 p, brightness 1 - 0.4 p (reduced: dim only). */
export const recession = (p: number) => ({ scale: 1 - 0.06 * p, radius: 12 * p, blur: 8 * p, brightness: 1 - 0.4 * p });

/** Lower sheet of a stack: at `large` scales to 0.9165 and moves up 2 %; a lower partial sheet drops to 70 % brightness. */
export const lowerSheet = (atLarge: boolean) => (atLarge ? { scale: 0.9165, lift: 0.02, brightness: 1 } : { scale: 1, lift: 0, brightness: 0.7 });

/** Detents crossed between two top positions (each one fires `sheet.pass` during a drag). */
export function detentsPassed(a: number, b: number, detents: readonly Detent[]): number {
  const lo = Math.min(a, b), hi = Math.max(a, b);
  return detents.filter((d) => d.top > lo && d.top <= hi).length;
}
