import { describe, expect, it } from "vitest";
import { pointerAngle, rollAngle } from "./useLightAngle";

describe("light angle", () => {
  it("stays within 135 deg +- 25 deg", () => {
    expect(pointerAngle(0, 1000)).toBe(110);
    expect(pointerAngle(500, 1000)).toBe(135);
    expect(pointerAngle(1000, 1000)).toBe(160);
    expect(rollAngle(0)).toBe(135);
    expect(rollAngle(30)).toBe(160);
    expect(rollAngle(-90)).toBe(110);
  });
});
