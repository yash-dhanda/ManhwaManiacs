import { describe, expect, it } from "vitest";
import type { ChapterManifest } from "@/features/reader/api";
import { pageAspect, stillPageUrl } from "./still-source";

const m = { pages: [{ number: 1, url: "https://x/a.jpg", width: 800, height: 1200 }, { number: 2, url: "https://x/b.jpg" }] } as unknown as ChapterManifest;

describe("still source", () => {
  it("finds a page by number and returns null when absent", () => {
    expect(stillPageUrl(m, 2)).toContain("b.jpg");
    expect(stillPageUrl(m, 9)).toBeNull();
    expect(stillPageUrl(m, null)).toBeNull();
    expect(stillPageUrl(undefined, 1)).toBeNull();
  });
  it("derives the aspect, defaulting to 0.7", () => {
    expect(pageAspect(m, 1)).toBeCloseTo(0.667, 2);
    expect(pageAspect(m, 2)).toBe(0.7);
  });
});
