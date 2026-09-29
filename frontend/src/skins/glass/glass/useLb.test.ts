import { describe, expect, it } from "vitest";
import { dimFor } from "./material";
import { fieldTerm, lbOf } from "./useLb";

describe("Lb sources", () => {
  it("unknown counts as white", () => expect(lbOf({ kind: "unknown" })).toBe(1));
  it("field is l x opacity + 0.02", () => {
    expect(fieldTerm(0.5, 0.26)).toBeCloseTo(0.15);
    expect(lbOf({ kind: "field", l: 0.5, opacity: 0.26 })).toBeCloseTo(0.15);
  });
  it("cover reads the peak: a dark cover with one white patch still dims to the max", () => {
    expect(dimFor(lbOf({ kind: "cover", lMax: 1 }))).toBe(0.64);
    expect(dimFor(lbOf({ kind: "cover", lMax: 0.1 }))).toBeCloseTo(0.262);
  });
  it("page takes the max over the listed bands only", () => {
    const sample = { pTop: 0.9, pMid: 0.2, pBottom: 0.4 };
    expect(lbOf({ kind: "page", sample, bands: ["mid", "bottom"] })).toBe(0.4);
    expect(lbOf({ kind: "page", sample, bands: ["top", "mid"] })).toBe(0.9);
  });
  it("paper is its luminance", () => expect(lbOf({ kind: "paper", luminance: 0.8 })).toBe(0.8));
});
