import { describe, expect, it } from "vitest";
import { dimFor, gradFor, lerpTier, rondFor, tierAt, tierFor, tierParams } from "./material";

describe("material maths", () => {
  it("snaps size to tier and never reaches T5", () => {
    expect([20, 35.9, 36, 56, 57, 96, 97, 240, 401, 5000].map(tierFor)).toEqual(
      ["t1", "t1", "t2", "t2", "t3", "t3", "t4", "t4", "t4", "t4"],
    );
  });
  it("dim follows Lb and clamps", () => {
    expect(dimFor(1)).toBe(0.64);
    expect(dimFor(0)).toBe(0.22);
    expect(dimFor(0.5)).toBeCloseTo(0.43);
    expect(dimFor(0, true)).toBe(0.4);
    expect(dimFor(1, true)).toBe(0.64);
    expect(dimFor(2, true)).toBeLessThanOrEqual(0.72);
  });
  it("GRAD and ROND", () => {
    expect(gradFor(1)).toBe(40);
    expect(gradFor(0.5)).toBe(20);
    expect(rondFor("t1")).toBe(20);
    expect(rondFor("t5")).toBe(100);
  });
  it("parses tier tokens and interpolates every parameter", () => {
    const t2 = tierParams("t2");
    expect(t2).toMatchObject({ blur: 8, fillA: 0.07, shadowY: 6, shadowBlur: 20, shadowA: 0.45, rond: 40 });
    const mid = lerpTier(tierParams("t2"), tierParams("t4"), 0.5);
    expect(mid.blur).toBe(15);
    expect(mid.rond).toBe(60);
    expect(tierAt(1)).toEqual(tierParams("t1"));
    expect(tierAt(5)).toEqual(tierParams("t5"));
    expect(tierAt(2.5).blur).toBeCloseTo(9);
  });
});
