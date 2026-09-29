import { describe, expect, it } from "vitest";
import { boundariesCrossed, dropletStretch, keyTarget, nearestSegment, releaseSegment, segmentCentres, segmentWidths } from "./segmented-math";

describe("segmented math", () => {
  it("equal widths unless labels differ by more than 40 %", () => {
    expect(segmentWidths([60, 70, 65], 300)).toEqual([100, 100, 100]);
    const w = segmentWidths([30, 100], 260);
    expect(w[0] + w[1]).toBeCloseTo(260);
    expect(w[1]).toBeGreaterThan(w[0]);
  });
  it("nearest segment by centre", () => {
    const w = [100, 100, 100];
    expect(segmentCentres(w)).toEqual([50, 150, 250]);
    expect(nearestSegment(99, w)).toBe(0);
    expect(nearestSegment(101, w)).toBe(1);
  });
  it("release projects by velocity", () => {
    const w = [100, 100, 100];
    expect(releaseSegment(60, 0, w)).toBe(0);
    expect(releaseSegment(60, 800, w)).toBe(1); // 60 + 0.499 x 800 = 459
  });
  it("counts boundaries crossed", () => expect(boundariesCrossed(40, 260, [100, 100, 100])).toBe(2));
  it("stretch caps at 25 % and conserves area", () => {
    expect(dropletStretch(10_000).sx).toBe(1.25);
    const { sx, sy } = dropletStretch(1000);
    expect(sx * sy * sy).toBeCloseTo(1);
  });
  it("keys", () => {
    expect(keyTarget("ArrowRight", 0, 3)).toBe(1);
    expect(keyTarget("ArrowLeft", 0, 3)).toBe(0);
    expect(keyTarget("End", 0, 3)).toBe(2);
    expect(keyTarget("Home", 2, 3)).toBe(0);
    expect(keyTarget("ArrowDown", 0, 3, true)).toBe(1);
    expect(keyTarget("x", 0, 3)).toBeNull();
  });
});
