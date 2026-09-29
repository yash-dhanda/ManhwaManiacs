import { describe, expect, it } from "vitest";
import { hexToOklch, oklchToHex } from "./oklch";

describe("oklch", () => {
  it("round-trips hex colours", () => {
    for (const hex of ["#FF7AA8", "#4336A3", "#9FD98A", "#000000", "#FFFFFF", "#7563F2"]) expect(oklchToHex(hexToOklch(hex))).toBe(hex);
  });
  it("knows white and black", () => {
    expect(hexToOklch("#FFFFFF").l).toBeCloseTo(1, 3);
    expect(hexToOklch("#000000").l).toBeCloseTo(0, 5);
    expect(hexToOklch("#FF0000").h).toBeCloseTo(29.2, 0);
  });
});
