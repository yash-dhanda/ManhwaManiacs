import { describe, expect, it } from "vitest";
import { gridColumns } from "./PosterGrid";

describe("poster grid columns (7.8)", () => {
  it("5 columns at 1024 (collapsed sidebar), 6 at 1440 and 8 at 1920 (expanded)", () => {
    expect(gridColumns(1024)).toBe(5);
    expect(gridColumns(1440, "comfortable", "expanded")).toBe(6);
    expect(gridColumns(1920, "comfortable", "expanded")).toBe(8);
  });
});
