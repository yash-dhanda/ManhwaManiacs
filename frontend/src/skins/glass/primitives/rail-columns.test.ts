import { describe, expect, it } from "vitest";
import { arrowStep, moveFocus } from "./rail-columns";

describe("rail keyboard model", () => {
  const counts = [10, 3, 0, 8];
  it("left and right stay in the rail and stop at its ends", () => {
    expect(moveFocus(counts, { rail: 0, col: 4 }, "ArrowRight")).toEqual({ rail: 0, col: 5 });
    expect(moveFocus(counts, { rail: 0, col: 0 }, "ArrowLeft")).toBeNull();
    expect(moveFocus(counts, { rail: 1, col: 2 }, "ArrowRight")).toBeNull();
  });
  it("up and down keep the column, clamped to the shorter rail", () => {
    expect(moveFocus(counts, { rail: 0, col: 7 }, "ArrowDown")).toEqual({ rail: 1, col: 2 });
    expect(moveFocus(counts, { rail: 1, col: 1 }, "ArrowUp")).toEqual({ rail: 0, col: 1 });
  });
  it("skips empty rails and stops at the group's ends", () => {
    expect(moveFocus(counts, { rail: 1, col: 2 }, "ArrowDown")).toEqual({ rail: 3, col: 2 });
    expect(moveFocus(counts, { rail: 3, col: 0 }, "ArrowDown")).toBeNull();
    expect(moveFocus(counts, { rail: 0, col: 0 }, "ArrowUp")).toBeNull();
  });
  it("Home and End", () => {
    expect(moveFocus(counts, { rail: 0, col: 4 }, "End")).toEqual({ rail: 0, col: 9 });
    expect(moveFocus(counts, { rail: 0, col: 4 }, "Home")).toEqual({ rail: 0, col: 0 });
  });
  it("arrows page by visible - 1", () => { expect(arrowStep(5)).toBe(4); expect(arrowStep(1)).toBe(1); });
});
