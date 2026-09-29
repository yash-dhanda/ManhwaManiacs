import { scalar } from "../tokens.generated";

/** Overdrag past the top detent: d · (1 − 1 / (x · c / d + 1)), c = scalar.rubber (0.35). */
export function rubberBand(x: number, d: number, c: number = scalar.rubber): number {
  if (x <= 0 || d <= 0) return 0;
  return d * (1 - 1 / ((x * c) / d + 1));
}

/**
 * Nearest detent to the sheet's current offset. `offset` is how far the sheet has been dragged DOWN from its tallest
 * detent (px, negative = past the top); `detents` are visible fractions of `height` (tallest first or any order).
 * Returns the index into `detents` of the closest resting position.
 */
export function nearestDetent(offset: number, detents: number[], height: number): number {
  const top = Math.max(...detents);
  let best = 0, bestD = Infinity;
  detents.forEach((f, i) => {
    const rest = (top - f) * height;
    const d = Math.abs(offset - rest);
    if (d < bestD) { bestD = d; best = i; }
  });
  return best;
}

/** Dismiss when more than 30 % of the sheet is below rest, or flung down faster than 800 px/s. */
export function shouldDismiss(offset: number, height: number, velocityPxPerS: number): boolean {
  return offset > height * 0.3 || velocityPxPerS > 800;
}
