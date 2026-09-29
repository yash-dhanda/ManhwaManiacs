import { describe, expect, it } from "vitest";
import { isCancelled, stretchScales, swellScale } from "./usePress";
import { shakeX } from "./shake";

describe("press math", () => {
  it("medium glass grows 12 px on the longest side", () => expect(swellScale(200, 50, "medium")).toBeCloseTo(212 / 200, 6));
  it("feather glass grows 17 px capped at 0.35 x the side", () => {
    expect(swellScale(100, 100, "feather")).toBeCloseTo(1.17, 6);
    expect(swellScale(44, 44, "feather")).toBeCloseTo(1.35, 6);
  });
  it("stretch conserves area", () => {
    const { sx, sy } = stretchScales(50, 100);
    expect(sx).toBeCloseTo(1.03, 6);
    expect(sx * sy * sy).toBeCloseTo(1, 6);
    expect(stretchScales(900, 100).sx).toBeCloseTo(1.06, 6);
  });
  it("cancels beyond 1.5 x the hit area", () => {
    const r = { left: 0, top: 0, width: 100, height: 50 };
    expect(isCancelled(50, 25, r)).toBe(false);
    expect(isCancelled(120, 25, r)).toBe(false); // inside 150 wide box centred on 50 (-25..125)
    expect(isCancelled(130, 25, r)).toBe(true);
  });
  it("error shake decays", () => {
    expect(Math.abs(shakeX(0))).toBe(0);
    expect(Math.abs(shakeX(420))).toBeLessThan(0.1);
  });
});
