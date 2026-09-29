import { describe, expect, it } from "vitest";
import { dragDismiss, isDoubleTap, keepFocal, panLimit, pastDismissLine, shouldDismiss } from "./viewer-math";

describe("image viewer maths", () => {
  it("follows the drag: scale, radius and backdrop", () => {
    expect(dragDismiss(0)).toEqual({ scale: 1, radius: 0, backdrop: 1 });
    expect(dragDismiss(120).scale).toBeCloseTo(0.9, 5);
    expect(dragDismiss(2000).scale).toBe(0.85);
    expect(dragDismiss(-320).backdrop).toBe(0);
    expect(dragDismiss(200).radius).toBe(28);
  });
  it("dismisses past 180 px projected or 800 px/s", () => {
    expect(shouldDismiss(100, 0)).toBe(false);
    expect(shouldDismiss(100, 300)).toBe(true);
    expect(shouldDismiss(10, 800)).toBe(true);
    expect(shouldDismiss(-200, 0)).toBe(true);
    expect(pastDismissLine(179, 0)).toBe(false);
  });
  it("double tap: 280 ms and 24 px", () => {
    const a = { t: 0, x: 10, y: 10 };
    expect(isDoubleTap(a, { t: 280, x: 30, y: 10 })).toBe(true);
    expect(isDoubleTap(a, { t: 281, x: 10, y: 10 })).toBe(false);
    expect(isDoubleTap(a, { t: 100, x: 40, y: 10 })).toBe(false);
    expect(isDoubleTap(null, a)).toBe(false);
  });
  it("keeps the focal point fixed", () => {
    expect(keepFocal(0, 100, 1, 2)).toBe(-100);
    expect(keepFocal(-100, 100, 2, 1)).toBe(0);
    expect(panLimit(400, 2.5)).toBe(300);
    expect(panLimit(400, 1)).toBe(0);
  });
});
