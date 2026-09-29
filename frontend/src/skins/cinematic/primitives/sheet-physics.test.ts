import { describe, expect, it } from "vitest";
import { nearestDetent, rubberBand, shouldDismiss } from "./sheet-physics";

describe("sheet physics", () => {
  it("rubber band is 0 at x = 0, grows, and stays under d", () => {
    expect(rubberBand(0, 600)).toBe(0);
    expect(rubberBand(100, 600)).toBeGreaterThan(0);
    expect(rubberBand(100, 600)).toBeLessThan(100);
    expect(rubberBand(1e6, 600)).toBeLessThan(600);
    expect(rubberBand(100, 600)).toBeCloseTo(600 * (1 - 1 / ((100 * 0.35) / 600 + 1)), 6);
  });
  it("picks the nearest detent", () => {
    const d = [0.5, 0.92];
    expect(nearestDetent(0, d, 800)).toBe(1);
    expect(nearestDetent(0.42 * 800, d, 800)).toBe(0);
    expect(nearestDetent(0.1 * 800, d, 800)).toBe(1);
    expect(nearestDetent(0.3 * 800, d, 800)).toBe(0);
  });
  it("dismisses past 30 % or 800 px/s", () => {
    expect(shouldDismiss(290, 1000, 0)).toBe(false);
    expect(shouldDismiss(310, 1000, 0)).toBe(true);
    expect(shouldDismiss(0, 1000, 799)).toBe(false);
    expect(shouldDismiss(0, 1000, 801)).toBe(true);
  });
});
