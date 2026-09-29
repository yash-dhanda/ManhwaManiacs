import { describe, expect, it } from "vitest";
import { sortGenreWeights } from "./genre-weights";

describe("sortGenreWeights", () => {
  it("sorts highest first, ties alphabetical", () => {
    const out = sortGenreWeights([{ genre: "b", weight: 1 }, { genre: "a", weight: 1 }, { genre: "c", weight: 5 }]);
    expect(out.map((g) => g.genre)).toEqual(["c", "a", "b"]);
  });
  it("returns [] for an empty or missing answer", () => {
    expect(sortGenreWeights(undefined)).toEqual([]);
    expect(sortGenreWeights([])).toEqual([]);
  });
});
