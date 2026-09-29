import { describe, expect, it } from "vitest";
import { blades, closeTotalMs, columnsFor, openTotalMs, wipeTotalMs } from "./wipe-geometry";

describe("wipe geometry", () => {
  it("picks 4 / 8 / 12 columns", () => {
    expect([390, 599, 600, 1023, 1024, 1440].map(columnsFor)).toEqual([4, 4, 8, 8, 12, 12]);
  });
  it("totals 616 / 744 / 872 ms", () => {
    expect([4, 8, 12].map(wipeTotalMs)).toEqual([616, 744, 872]);
    expect([closeTotalMs(12), openTotalMs(12)]).toEqual([376, 456]);
    expect([closeTotalMs(4), openTotalMs(4)]).toEqual([248, 328]);
  });
  it.each([[390, 4, 16, 8], [768, 8, 32, 16], [1440, 12, 48, 24], [2560, 12, 96, 24]])("covers the full width at %i px", (vw, columns, margin, gutter) => {
    const b = blades(vw, { columns, margin, gutter, max: 1760 });
    expect(b).toHaveLength(columns);
    expect(b[0].left).toBe(0);
    let x = 0;
    for (const bl of b) { expect(bl.left).toBeCloseTo(x, 5); x = bl.left + bl.width; }
    expect(x).toBeCloseTo(vw, 5);
  });
  it("lands blade edges on column edges within the 1760 cap", () => {
    const b = blades(2560, { columns: 12, margin: 96, gutter: 24, max: 1760 });
    const origin = (2560 - 1760) / 2 + 96;
    expect(b[1].left).toBeCloseTo(origin + (1760 - 192 - 11 * 24) / 12 + 24, 5);
  });
});
