import { describe, expect, it } from "vitest";
import { announceMove, moveDisabled, moveItem, moveItems } from "./reorder";

describe("reorder", () => {
  it("announces one-based positions", () => expect(announceMove("Solo Leveling", 2, 12)).toBe("Solo Leveling moved to position 3 of 12"));
  it("moves and clamps", () => {
    expect(moveItem([1, 2, 3, 4], 0, 2)).toEqual([2, 3, 1, 4]);
    expect(moveItem([1, 2, 3], 2, 0)).toEqual([3, 1, 2]);
    expect(moveItem([1, 2, 3], 1, 9)).toEqual([1, 3, 2]);
  });
  it("disables the ends", () => {
    expect(moveDisabled(0, 5)).toEqual({ up: true, top: true, down: false, bottom: false });
    expect(moveDisabled(4, 5)).toEqual({ up: false, top: false, down: true, bottom: true });
    expect(moveDisabled(0, 1)).toEqual({ up: true, top: true, down: true, bottom: true });
  });
  it("menu items call onMove with from and to", () => {
    const calls: [number, number][] = [];
    const items = moveItems(2, 5, (a, b) => calls.push([a, b]));
    items.forEach((i) => i.onSelect?.());
    expect(calls).toEqual([[2, 1], [2, 3], [2, 0], [2, 4]]);
    expect(items.map((i) => i.disabled)).toEqual([false, false, false, false]);
  });
});
