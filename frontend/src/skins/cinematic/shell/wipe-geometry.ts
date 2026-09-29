/** Column wipe geometry (§8.14.2). Pure. All numbers in CSS px / ms. */
export const WIPE = { closeMs: 200, openMs: 280, holdMs: 40, staggerMs: 16 } as const;

/** Blades follow the grid: 4 below 600, 8 at 600-1023, 12 from 1024. */
export const columnsFor = (vw: number) => (vw < 600 ? 4 : vw < 1024 ? 8 : 12);

export type Grid = { columns: number; margin: number; gutter: number; max: number };
export type Blade = { left: number; width: number };

/**
 * One blade per column, each from its column's left edge to the next column's left edge, so margins and gutters are covered and blade
 * edges land on column edges. The first blade starts at 0 and the last ends at the viewport's right edge.
 */
export function blades(vw: number, g: Grid): Blade[] {
  const box = Math.min(vw, g.max);
  const origin = (vw - box) / 2;
  const inner = box - 2 * g.margin;
  const colW = (inner - (g.columns - 1) * g.gutter) / g.columns;
  const lefts = Array.from({ length: g.columns }, (_, i) => origin + g.margin + i * (colW + g.gutter));
  return lefts.map((l, i) => {
    const left = i === 0 ? 0 : l;
    const right = i === g.columns - 1 ? vw : lefts[i + 1];
    return { left, width: right - left };
  });
}

export const closeTotalMs = (n: number) => WIPE.closeMs + WIPE.staggerMs * (n - 1);
export const openTotalMs = (n: number) => WIPE.openMs + WIPE.staggerMs * (n - 1);
/** Close + hold + open: 616 / 744 / 872 ms for 4 / 8 / 12 blades. */
export const wipeTotalMs = (n: number) => closeTotalMs(n) + WIPE.holdMs + openTotalMs(n);
