import { describe, expect, it } from "vitest";
import { pageBy, posterWidth, railBreakpoint, railGap, visiblePosters } from "./rail-math";

describe("rail math", () => {
  it("visible counts per breakpoint", () => {
    expect(visiblePosters("phone")).toBe(3.2);
    expect(visiblePosters("tablet")).toBe(5.2);
    expect(visiblePosters("desktop")).toBe(6.25);
    expect(visiblePosters("wide")).toBe(7.25);
    expect(visiblePosters("cinema")).toBe(8.25);
    expect(visiblePosters("phone", 1.3)).toBe(2.3);
    expect(visiblePosters("desktop", 1.5)).toBe(6.25);
  });
  it("gaps", () => {
    expect([railGap("phone"), railGap("tablet"), railGap("desktop"), railGap("wide"), railGap("cinema")]).toEqual([8, 12, 12, 12, 16]);
  });
  it("breakpoint from viewport", () => {
    expect(railBreakpoint(390)).toBe("phone");
    expect(railBreakpoint(800)).toBe("tablet");
    expect(railBreakpoint(1440)).toBe("wide");
    expect(railBreakpoint(2560)).toBe("cinema");
  });
  it("poster width = (content - floor(visible) x gap) / visible", () => {
    expect(posterWidth(1312, "desktop")).toBeCloseTo((1312 - 6 * 12) / 6.25);
    expect(posterWidth(358, "phone")).toBeCloseTo((358 - 3 * 8) / 3.2);
  });
  it("pages by visible - 1", () => {
    expect(pageBy(6.25)).toBe(5);
    expect(pageBy(2.3)).toBe(1);
  });
});
