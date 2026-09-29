import { describe, expect, it } from "vitest";
import { buildTrending } from "./trending";

const items = (p: string, n: number) => Array.from({ length: n }, (_, i) => ({ id: `${p}${i}`, title: `${p} ${i}` }));

describe("buildTrending", () => {
  it("takes two per source in pin order", () => {
    const out = buildTrending([{ sourceId: "a", items: items("a", 5) }, { sourceId: "b", items: items("b", 5) }]);
    expect(out.map((t) => t.seriesKey)).toEqual(["a0", "a1", "b0", "b1"]);
  });
  it("de-duplicates by case-folded title", () => {
    const out = buildTrending([
      { sourceId: "a", items: [{ id: "1", title: "Solo" }] },
      { sourceId: "b", items: [{ id: "2", title: "SOLO" }, { id: "3", title: "Other" }] },
    ]);
    expect(out.map((t) => t.seriesKey)).toEqual(["1", "3"]);
  });
  it("caps at ten and skips sources with no popular page", () => {
    const many = Array.from({ length: 8 }, (_, i) => ({ sourceId: `s${i}`, items: items(`s${i}`, 3) }));
    expect(buildTrending([{ sourceId: "x", items: null }, ...many])).toHaveLength(10);
  });
});
