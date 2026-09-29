import type { SourcePin } from "./types";

export type PinMove = "up" | "down" | "top" | "bottom";

const dense = (pins: SourcePin[]) => pins.map((p, i) => (p.sort_order === i ? p : { ...p, sort_order: i }));

/**
 * The full next pin array after the *available* pins are reordered. Unavailable
 * pins keep their own slots, so they come back when their source does.
 */
export function reorderAvailable(pins: SourcePin[], nextAvailableIds: string[]): SourcePin[] {
  const byId = new Map(pins.filter((p) => p.available).map((p) => [p.source_id, p]));
  const queue = nextAvailableIds.map((id) => byId.get(id)).filter((p): p is SourcePin => Boolean(p));
  return dense(pins.map((p) => (p.available ? queue.shift() ?? p : p)));
}

/** Position of `id` among available pins (1-based) and how many there are; null when not pinned. */
export function availablePosition(pins: SourcePin[], id: string): { position: number; total: number } | null {
  const ids = pins.filter((p) => p.available).map((p) => p.source_id);
  const i = ids.indexOf(id);
  return i < 0 ? null : { position: i + 1, total: ids.length };
}

/** Move one available pin; returns null when the move is a no-op (already at that end). */
export function movePin(pins: SourcePin[], id: string, move: PinMove): SourcePin[] | null {
  const ids = pins.filter((p) => p.available).map((p) => p.source_id);
  const i = ids.indexOf(id);
  if (i < 0) return null;
  const target = move === "up" ? i - 1 : move === "down" ? i + 1 : move === "top" ? 0 : ids.length - 1;
  if (target < 0 || target >= ids.length || target === i) return null;
  const next = [...ids];
  next.splice(i, 1);
  next.splice(target, 0, id);
  return reorderAvailable(pins, next);
}
