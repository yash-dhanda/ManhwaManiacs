import { describe, expect, it } from "vitest";
import { buildGenreIndex } from "./genre-index";

describe("buildGenreIndex", () => {
  it("is empty with nothing pinned", () => {
    expect(buildGenreIndex([], {}, [])).toEqual([]);
  });
  it("merges case-insensitively keeping the first spelling", () => {
    const out = buildGenreIndex(["a", "b"], { a: ["Action", "Romance"], b: ["action"] }, []);
    expect(out.find((g) => g.genre === "action")).toEqual({ genre: "action", label: "Action", sourceIds: ["a", "b"] });
  });
  it("orders by weight, then alphabetically", () => {
    const out = buildGenreIndex(["a"], { a: ["Zed", "Alpha", "Beta", "Gamma"] }, [
      { genre: "gamma", weight: 9 },
      { genre: "Beta", weight: 3 },
    ]);
    expect(out.map((g) => g.label)).toEqual(["Gamma", "Beta", "Alpha", "Zed"]);
  });
  it("ignores pinned sources with no genres", () => {
    expect(buildGenreIndex(["a"], {}, [])).toEqual([]);
  });
});
