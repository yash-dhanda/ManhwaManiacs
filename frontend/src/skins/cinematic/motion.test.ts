import { beforeEach, describe, expect, it } from "vitest";
import { RACK_CAP, claimRack, decideEntrance, gridDelay, letterStep, listDelay, rackCount, releaseRack, resetRackCount, typedCount, wordDelay } from "./motion";

describe("stagger maths", () => {
  it("grid: 32 ms per item, 64 per row, cap 480", () => {
    expect(gridDelay(0, 0)).toBe(0);
    expect(gridDelay(3, 0)).toBe(96);
    expect(gridDelay(2, 1)).toBe(128);
    expect(gridDelay(40, 10)).toBe(480);
  });
  it("list: 24 ms cap 360", () => {
    expect(listDelay(5)).toBe(120);
    expect(listDelay(100)).toBe(360);
  });
  it("letters: min(24, 560/(n-1))", () => {
    expect(letterStep(1)).toBe(24);
    expect(letterStep(7)).toBe(24);
    expect(letterStep(50)).toBeCloseTo(560 / 49);
  });
  it("words: 30 ms", () => expect(wordDelay(4)).toBe(120));
  it("typed clock: one grapheme per 50 ms", () => {
    expect(typedCount(0, 40)).toBe(0);
    expect(typedCount(499, 40)).toBe(9);
    expect(typedCount(500, 40)).toBe(10);
    expect(typedCount(99999, 40)).toBe(40);
    expect(typedCount(-10, 40)).toBe(0);
  });
});

describe("rack cap", () => {
  beforeEach(resetRackCount);
  it("the 13th rack downgrades", () => {
    for (let i = 0; i < RACK_CAP; i++) expect(claimRack()).toBe(true);
    expect(claimRack()).toBe(false);
    releaseRack();
    expect(claimRack()).toBe(true);
    expect(rackCount()).toBe(RACK_CAP);
  });
});

describe("entrance decision", () => {
  it("set on first paint, dissolve after skeleton or refetch, none when seen", () => {
    expect(decideEntrance(false, false)).toBe("set");
    expect(decideEntrance(false, true)).toBe("dissolve");
    expect(decideEntrance(true, false)).toBe("none");
    expect(decideEntrance(true, true)).toBe("none");
  });
});
