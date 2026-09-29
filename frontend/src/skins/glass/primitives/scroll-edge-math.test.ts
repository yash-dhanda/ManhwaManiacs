import { describe, expect, it } from "vitest";
import { bottomEdgeOpacity, indexAt, tickBetween, topEdgeOpacity } from "./scroll-edge-math";

describe("scroll edges", () => {
  it("fade in as content arrives under them", () => {
    expect(topEdgeOpacity(0)).toBe(0);
    expect(topEdgeOpacity(12)).toBe(0.5);
    expect(topEdgeOpacity(500)).toBe(1);
    expect(bottomEdgeOpacity(1000, 0, 800)).toBe(1);
    expect(bottomEdgeOpacity(1000, 190, 800)).toBeCloseTo(10 / 24, 5);
    expect(bottomEdgeOpacity(1000, 200, 800)).toBe(0);
  });
  it("fast scroll maps the strip to rows and ticks per 10", () => {
    expect(indexAt(0, 500)).toBe(0);
    expect(indexAt(1, 500)).toBe(499);
    expect(tickBetween(9, 10)).toBe(true);
    expect(tickBetween(11, 15)).toBe(false);
  });
});
