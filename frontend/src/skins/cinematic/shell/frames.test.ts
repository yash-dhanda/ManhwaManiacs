import { describe, expect, it } from "vitest";
import { frameFor } from "./frames";

describe("frameFor", () => {
  it.each([
    ["/login", "bare"], ["/register", "bare"],
    ["/profiles", "takeover"], ["/profiles?switch=1", "takeover"], ["/welcome", "takeover"], ["/recap/a/b", "takeover"], ["/library/statistics/annual/2026", "takeover"],
    ["/reader/a/b/c", "reader"], ["/read-all/a/b", "reader"],
    ["/novels/a/b/c", "page"],
    ["/", "app"], ["/library", "app"], ["/profiles/manage", "app"], ["/profiles/new", "app"], ["/profiles/3/edit", "app"], ["/reader", "app"], ["/does-not-exist", "app"], ["/library/statistics", "app"],
  ])("%s -> %s", (p, f) => expect(frameFor(p)).toBe(f));
});
