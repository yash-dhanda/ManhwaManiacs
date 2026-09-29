import { describe, expect, it } from "vitest";
import { PULL_MAX, PULL_TRIGGER, pullDistance, pullPhase, pullRule } from "./pull";

describe("pull to reprint", () => {
  it("rubber-bands from zero and never reaches the max", () => {
    expect(pullDistance(0)).toBe(0);
    expect(pullDistance(-5)).toBe(0);
    expect(pullDistance(100)).toBeLessThan(100);
    expect(pullDistance(5000)).toBeLessThan(PULL_MAX);
  });
  it("arms at 96 px of shown pull", () => {
    expect(pullPhase(0)).toBe("idle");
    expect(pullPhase(PULL_TRIGGER - 0.1)).toBe("pull");
    expect(pullPhase(PULL_TRIGGER)).toBe("release");
    expect(pullPhase(200)).toBe("release");
  });
  it("rule grows to full at the trigger", () => {
    expect(pullRule(48)).toBe(0.5);
    expect(pullRule(500)).toBe(1);
  });
});
