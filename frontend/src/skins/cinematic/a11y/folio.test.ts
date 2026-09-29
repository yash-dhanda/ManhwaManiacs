import { describe, expect, it } from "vitest";
import { folioLabel, folioLabelJoin } from "./folio";

describe("folioLabel", () => {
  const cases: [string, string][] = [
    ["CH 142 · 63%", "Chapter 142, 63 percent read"],
    ["2 H", "2 hours ago"],
    ["PAUSED 21 D", "Paused 21 days"],
    ["p. 12", "page 12"],
    ["12 MIN", "12 minutes"],
    ["18+", "Mature, 18 plus"],
    ["CH 12 OF 40", "Chapter 12 of 40"],
    ["NEXT · CH 143", "Next, chapter 143"],
    ["3 NEW", "3 new chapters"],
    ["1 NEW", "1 new chapter"],
    ["Filters ⁽2⁾", "Filters, 2"],
    ["Filters (2)", "Filters, 2"],
    ["READING¹²", "Reading, 12"],
  ];
  it.each(cases)("%s -> %s", (v, s) => expect(folioLabel(v)).toBe(s));
  it("label plus count", () => expect(folioLabel("READING", 12)).toBe("Reading, 12"));
  it("joins a split button", () => expect(folioLabelJoin("Continue", "CH 143 · p.12")).toBe("Continue, chapter 143, page 12"));
});
