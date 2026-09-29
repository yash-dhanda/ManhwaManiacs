import { describe, expect, it } from "vitest";
import { armed, displayedPull, dropletRadius, glyphRotation, neckWidth, pullProgress } from "./pull-physics";

describe("pull physics", () => {
  it("the radius grows 0 to 16 over the first 60 raw px", () => {
    expect(dropletRadius(0)).toBe(0);
    expect(dropletRadius(30)).toBe(8);
    expect(dropletRadius(60)).toBe(16);
    expect(dropletRadius(90)).toBe(16);
  });
  it("the neck is 12 x (1 - progress) px", () => {
    expect(neckWidth(0)).toBe(12);
    expect(neckWidth(30)).toBeCloseTo(8.4, 5);
    expect(neckWidth(60)).toBeCloseTo(4.8, 5);
    expect(neckWidth(90)).toBeCloseTo(1.2, 5);
    expect(neckWidth(100)).toBe(0);
  });
  it("triggers at exactly 100 raw px", () => {
    expect(armed(99.9)).toBe(false);
    expect(armed(100)).toBe(true);
    expect(pullProgress(100)).toBe(1);
  });
  it("the glyph turns 360 degrees per 100 raw px", () => {
    expect(glyphRotation(50)).toBe(180);
    expect(glyphRotation(100)).toBe(360);
  });
  it("the displayed pull is a rubber band that never reaches the raw value", () => {
    expect(displayedPull(0, 800)).toBe(0);
    expect(displayedPull(100, 800)).toBeLessThan(100);
    expect(displayedPull(100, 800)).toBeGreaterThan(displayedPull(50, 800));
  });
});
