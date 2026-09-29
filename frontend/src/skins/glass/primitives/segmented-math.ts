import { project } from "../physics/project";

/** Equal widths, or content-fit widths when the labels differ by more than 40 % (longest vs shortest). */
export function segmentWidths(labelWidths: readonly number[], total: number): number[] {
  const max = Math.max(...labelWidths), min = Math.min(...labelWidths);
  const fit = max > 0 && (max - min) / max > 0.4;
  if (!fit) return labelWidths.map(() => total / labelWidths.length);
  const sum = labelWidths.reduce((a, b) => a + b, 0);
  return labelWidths.map((w) => (w / sum) * total);
}

export const segmentEdges = (widths: readonly number[]) => widths.reduce<number[]>((acc, w, i) => (acc.push((acc[i] ?? 0) + w), acc), [0]).slice(0, -1);
export const segmentCentres = (widths: readonly number[]) => segmentEdges(widths).map((e, i) => e + widths[i] / 2);

/** Index of the segment whose centre is nearest `x` (thumb centre, track coordinates). */
export function nearestSegment(x: number, widths: readonly number[]): number {
  const c = segmentCentres(widths);
  return c.reduce((best, v, i) => (Math.abs(v - x) < Math.abs(c[best] - x) ? i : best), 0);
}

/** Release: project the thumb centre by its velocity (px/s) and settle on the nearest segment. */
export const releaseSegment = (x: number, v: number, widths: readonly number[]) => nearestSegment(project(x, v), widths);

/** Boundaries crossed moving the thumb centre from `from` to `to`: each fires one `select` haptic. */
export function boundariesCrossed(from: number, to: number, widths: readonly number[]): number {
  return Math.abs(nearestSegment(to, widths) - nearestSegment(from, widths));
}

/** Droplet stretch by velocity: scaleX = 1 + min(|v| / 2000, 0.25), scaleY = 1 / sqrt(scaleX). */
export function dropletStretch(v: number): { sx: number; sy: number } {
  const sx = 1 + Math.min(Math.abs(v) / 2000, 0.25);
  return { sx, sy: 1 / Math.sqrt(sx) };
}

/** Roving keys: next index for an arrow, Home or End (wraps never). */
export function keyTarget(key: string, i: number, n: number, vertical = false): number | null {
  const next = vertical ? "ArrowDown" : "ArrowRight", prev = vertical ? "ArrowUp" : "ArrowLeft";
  if (key === next || (!vertical && key === "ArrowDown")) return Math.min(n - 1, i + 1);
  if (key === prev || (!vertical && key === "ArrowUp")) return Math.max(0, i - 1);
  if (key === "Home") return 0;
  if (key === "End") return n - 1;
  return null;
}
