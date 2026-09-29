/** Rail keyboard model (7.9): one tab stop per rail; left and right move within a rail; up and down move between the rails of a RailGroup keeping the column. */
export interface RailPos { rail: number; col: number }

/** `counts[r]` is the number of items in rail r. Returns the new position, or null when the move goes nowhere. */
export function moveFocus(counts: readonly number[], at: RailPos, key: "ArrowLeft" | "ArrowRight" | "ArrowUp" | "ArrowDown" | "Home" | "End"): RailPos | null {
  const n = counts[at.rail] ?? 0;
  if (key === "ArrowLeft") return at.col > 0 ? { rail: at.rail, col: at.col - 1 } : null;
  if (key === "ArrowRight") return at.col < n - 1 ? { rail: at.rail, col: at.col + 1 } : null;
  if (key === "Home") return at.col > 0 ? { rail: at.rail, col: 0 } : null;
  if (key === "End") return at.col < n - 1 ? { rail: at.rail, col: n - 1 } : null;
  const step = key === "ArrowUp" ? -1 : 1;
  for (let r = at.rail + step; r >= 0 && r < counts.length; r += step) if (counts[r] > 0) return { rail: r, col: Math.min(at.col, counts[r] - 1) };
  return null;
}

/** How many whole posters a desktop arrow scrolls: visible count - 1, at least 1. */
export const arrowStep = (visible: number) => Math.max(1, visible - 1);
