import { describe, expect, it } from "vitest";
import { coverTransitionName, fnv1a32 } from "./cover-transition-name";

describe("fnv1a32", () => {
  it("matches the reference vectors", () => {
    expect(fnv1a32("")).toBe(0x811c9dc5);
    expect(fnv1a32("a")).toBe(0xe40c292c);
    expect(fnv1a32("foobar")).toBe(0xbf9cf968);
  });
});

describe("coverTransitionName", () => {
  it("matches the exact vectors", () => {
    expect(coverTransitionName("", "")).toBe("cover-050c5d1f");
    expect(coverTransitionName("asura", "solo-leveling")).toBe("cover-a07012e1");
    expect(coverTransitionName("mangadex", "a/b c%d")).toBe("cover-a34e56be");
    expect(coverTransitionName("src", "한국")).toBe("cover-7f4c64fd");
  });
  it("is always a valid view-transition-name", () => {
    for (const [s, k] of [["", ""], ["x", "y/z"], ["é", "\u0000"]]) {
      expect(coverTransitionName(s, k)).toMatch(/^cover-[0-9a-f]{8}$/);
    }
  });
});
