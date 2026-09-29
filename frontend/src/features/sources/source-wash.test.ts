import { describe, expect, it } from "vitest";
import { fnv1a32 } from "./standins/fnv1a32";
import { sourceWashHue } from "./source-wash";

describe("sourceWashHue", () => {
  it("matches fnv1a32 for known ids", () => {
    expect(fnv1a32("a")).toBe(0xe40c292c);
    expect(sourceWashHue("a")).toBe(0xe40c292c % 360);
    expect(sourceWashHue("asura")).toBe(fnv1a32("asura") % 360);
    expect(sourceWashHue("asura")).toBeLessThan(360);
  });
});
