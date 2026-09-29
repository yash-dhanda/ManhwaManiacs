import { describe, expect, it } from "vitest";
import { applyRubberBand, detentsPassed, detentTops, dismissLine, insetAt, largeProgress, lowerSheet, pickDetent, recession, stretchAbove } from "./sheet-physics";

const VH = 844, SAFE = 47;
const detents = detentTops(VH, SAFE, ["medium", "large"]);
const medium = detents[1], large = detents[0];
const sheetHeight = VH - medium.top; // height at the lowest detent

describe("detentTops", () => {
  it("places peek, medium (52 %) and large (viewport - safe-top - 10)", () => {
    const d = detentTops(VH, SAFE, ["peek", "medium", "large"]);
    expect(d.map((x) => x.name)).toEqual(["large", "medium", "peek"]);
    expect(d[0].top).toBe(SAFE + 10);
    expect(d[1].top).toBeCloseTo(VH * 0.48, 5);
    expect(d[2].top).toBe(VH - 96);
  });
});

describe("pickDetent", () => {
  it("a slow release picks the nearest detent to the top edge", () => {
    expect(pickDetent({ top: large.top + 40, velocity: 0, detents, sheetHeight })).toMatchObject({ kind: "detent", name: "large" });
    expect(pickDetent({ top: medium.top - 20, velocity: 0, detents, sheetHeight })).toMatchObject({ kind: "detent", name: "medium" });
  });
  it("a flick up from medium projects to large", () => {
    expect(pickDetent({ top: medium.top, velocity: -900, detents, sheetHeight })).toMatchObject({ kind: "detent", name: "large" });
  });
  it("a modest flick down from large lands on medium, a fast one dismisses", () => {
    expect(pickDetent({ top: large.top, velocity: 700, detents, sheetHeight })).toMatchObject({ kind: "detent", name: "medium" });
    expect(pickDetent({ top: large.top, velocity: 2600, detents, sheetHeight }).kind).toBe("dismiss");
  });
  it("dismisses by position when the projection is more than half the sheet height below the lowest detent", () => {
    const line = dismissLine(medium.top, sheetHeight);
    expect(pickDetent({ top: line + 5, velocity: 0, detents, sheetHeight }).kind).toBe("dismiss");
    expect(pickDetent({ top: line - 5, velocity: 0, detents, sheetHeight }).kind).toBe("detent");
  });
  it("dismisses by velocity at the lowest detent from 1,500 px/s", () => {
    // a tall sheet keeps the position rule out of the way, so only the velocity rule can dismiss
    expect(pickDetent({ top: medium.top, velocity: 1500, detents, sheetHeight: 6000 }).kind).toBe("dismiss");
    expect(pickDetent({ top: medium.top, velocity: 1499, detents, sheetHeight: 6000 }).kind).toBe("detent");
  });
});

describe("rubber band", () => {
  it("never exceeds 60 px, however far the finger goes", () => {
    for (const x of [1, 10, 100, 500, 5000]) expect(stretchAbove(x, VH)).toBeLessThanOrEqual(60);
    expect(stretchAbove(5000, VH)).toBe(60);
  });
  it("follows the finger below the top detent and stretches above it", () => {
    expect(applyRubberBand(120, VH)).toBe(120);
    expect(applyRubberBand(0, VH)).toBe(0);
    expect(applyRubberBand(-40, VH)).toBeLessThan(0);
    expect(applyRubberBand(-40, VH)).toBeGreaterThan(-40);
  });
});

describe("geometry", () => {
  it("progress is 0 at medium, 1 at large, and drives inset and recession", () => {
    expect(largeProgress(medium.top, medium.top, large.top)).toBe(0);
    expect(largeProgress(large.top, medium.top, large.top)).toBe(1);
    expect(largeProgress(large.top - 30, medium.top, large.top)).toBe(1);
    expect(insetAt(0)).toBe(8);
    expect(insetAt(0.8)).toBe(8);
    expect(insetAt(1)).toBeCloseTo(0, 9);
    expect(recession(1)).toEqual({ scale: 0.94, radius: 12, blur: 8, brightness: 0.6 });
  });
  it("stacked sheets follow the 0.9165 / 2 % / 70 % rules", () => {
    expect(lowerSheet(true)).toMatchObject({ scale: 0.9165, lift: 0.02 });
    expect(lowerSheet(false).brightness).toBe(0.7);
  });
  it("counts detents passed during a drag", () => {
    const three = detentTops(VH, SAFE, ["peek", "medium", "large"]);
    expect(detentsPassed(three[2].top, three[0].top, three)).toBe(2);
    expect(detentsPassed(three[0].top + 5, three[0].top + 10, three)).toBe(0);
  });
});
