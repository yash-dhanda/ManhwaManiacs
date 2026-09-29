import { describe, expect, it } from "vitest";
import { indicatorAt, nextTab } from "./tabs-math";

const boxes = [{ left: 0, width: 60 }, { left: 80, width: 100 }, { left: 200, width: 40 }];

describe("indicatorAt", () => {
  it("sits on the label at whole positions", () => {
    expect(indicatorAt(boxes, 0)).toEqual({ left: 0, width: 60 });
    expect(indicatorAt(boxes, 1)).toEqual({ left: 80, width: 100 });
  });
  it("lerps left and width between two labels while a finger drags the panel", () => {
    expect(indicatorAt(boxes, 0.5)).toEqual({ left: 40, width: 80 });
  });
  it("stretches by velocity, capped at 25 %, about its centre", () => {
    const r = indicatorAt(boxes, 0, 9);
    expect(r.width).toBe(75);
    expect(r.left).toBe(-7.5);
    expect(indicatorAt(boxes, 0, 0.1).width).toBeCloseTo(66, 5);
  });
});

describe("nextTab", () => {
  it("skips disabled tabs", () => {
    expect(nextTab([false, true, false], 0, 1)).toBe(2);
    expect(nextTab([false, true, false], 2, -1)).toBe(0);
  });
  it("stays put at the ends unless wrapping", () => {
    expect(nextTab([false, false], 1, 1)).toBe(1);
    expect(nextTab([false, false], 1, 1, true)).toBe(0);
  });
});
