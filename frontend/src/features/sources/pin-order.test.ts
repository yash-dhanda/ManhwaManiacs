import { describe, expect, it } from "vitest";
import { availablePosition, movePin, reorderAvailable } from "./pin-order";
import type { SourcePin } from "./types";

const pin = (id: string, available = true, i = 0): SourcePin => ({ source_id: id, sort_order: i, name: id, icon_url: null, mature: false, available });
const pins = [pin("a", true, 0), pin("x", false, 1), pin("b", true, 2), pin("c", true, 3)];

describe("pin order", () => {
  it("keeps unavailable pins in place when reordering", () => {
    expect(reorderAvailable(pins, ["c", "a", "b"]).map((p) => p.source_id)).toEqual(["c", "x", "a", "b"]);
  });
  it("keeps sort_order dense", () => {
    expect(reorderAvailable(pins, ["c", "b", "a"]).map((p) => p.sort_order)).toEqual([0, 1, 2, 3]);
  });
  it("moves up, down, top and bottom", () => {
    expect(movePin(pins, "b", "up")!.map((p) => p.source_id)).toEqual(["b", "x", "a", "c"]);
    expect(movePin(pins, "a", "down")!.map((p) => p.source_id)).toEqual(["b", "x", "a", "c"]);
    expect(movePin(pins, "c", "top")!.map((p) => p.source_id)).toEqual(["c", "x", "a", "b"]);
    expect(movePin(pins, "a", "bottom")!.map((p) => p.source_id)).toEqual(["b", "x", "c", "a"]);
  });
  it("refuses a move past either end", () => {
    expect(movePin(pins, "a", "up")).toBeNull();
    expect(movePin(pins, "c", "down")).toBeNull();
    expect(movePin(pins, "zzz", "up")).toBeNull();
  });
  it("reports the position among available pins", () => {
    expect(availablePosition(pins, "c")).toEqual({ position: 3, total: 3 });
    expect(availablePosition(pins, "x")).toBeNull();
  });
});
