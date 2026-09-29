import { describe, expect, it } from "vitest";
import { coverTransitionName } from "./cover-name";
import { bladeCount, wipePlan } from "./wipe";

describe("Column wipe plan (§8.14.2)", () => {
  it("12 blades on desktop take 376 + 40 + 456 = 872 ms", () => {
    expect(bladeCount(1440)).toBe(12);
    expect(wipePlan(12)).toEqual({ close: 376, hold: 40, open: 456, total: 872 });
  });
  it("8 blades at 768-1023 px take 744 ms, 4 on phones take 616 ms", () => {
    expect(bladeCount(900)).toBe(8);
    expect(wipePlan(8).total).toBe(744);
    expect(bladeCount(390)).toBe(4);
    expect(wipePlan(4).total).toBe(616);
  });
});

describe("coverTransitionName", () => {
  it("is a valid, stable, per-series CSS identifier", () => {
    const a = coverTransitionName("mangapill", "9748/dustland");
    expect(a).toMatch(/^mm-cover-[a-zA-Z0-9_-]+$/);
    expect(coverTransitionName("mangapill", "9748/dustland")).toBe(a);
    expect(coverTransitionName("mangapill", "9748/other")).not.toBe(a);
  });
});
