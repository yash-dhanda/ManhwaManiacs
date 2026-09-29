import { afterEach, describe, expect, it, vi } from "vitest";
import { _resetBudget, forcedSolidIds, registerGlass, type Rect } from "./budget";

const r = (l: number, t: number, w: number, h: number): Rect => ({ left: l, top: t, right: l + w, bottom: t + h });

describe("stacking", () => {
  it("forces the lowest layer solid under two overlapping higher layers", () => {
    const s = forcedSolidIds([
      { id: "a", layer: "controls", rect: r(0, 0, 100, 100) },
      { id: "b", layer: "overlays", rect: r(10, 10, 100, 100) },
      { id: "c", layer: "interruptions", rect: r(20, 20, 100, 100) },
    ]);
    expect([...s]).toEqual(["a"]);
  });
  it("two stacked layers are fine, and disjoint upper layers do not count", () => {
    expect(forcedSolidIds([
      { id: "a", layer: "controls", rect: r(0, 0, 100, 100) },
      { id: "b", layer: "overlays", rect: r(10, 10, 100, 100) },
    ]).size).toBe(0);
    expect(forcedSolidIds([
      { id: "a", layer: "controls", rect: r(0, 0, 100, 100) },
      { id: "b", layer: "overlays", rect: r(0, 0, 40, 40) },
      { id: "c", layer: "hud", rect: r(60, 60, 40, 40) },
    ]).size).toBe(0);
  });
});

describe("registry", () => {
  afterEach(_resetBudget);
  it("warns once at the seventh live glass element, and scrims do not count", async () => {
    vi.useFakeTimers();
    const warn = vi.spyOn(console, "warn").mockImplementation(() => {});
    const off = Array.from({ length: 7 }, (_, i) => registerGlass({ id: `g${i}`, kind: "glass", layer: "controls", label: `g${i}`, el: null }));
    registerGlass({ id: "s", kind: "scrim", layer: "controls", label: "s", el: null });
    await vi.advanceTimersByTimeAsync(0);
    expect(warn).toHaveBeenCalledTimes(1);
    off[0]();
    await vi.advanceTimersByTimeAsync(0);
    expect(warn).toHaveBeenCalledTimes(1);
    registerGlass({ id: "g0", kind: "glass", layer: "controls", label: "g0", el: null }); // crosses the limit again
    await vi.advanceTimersByTimeAsync(0);
    expect(warn).toHaveBeenCalledTimes(2);
    vi.useRealTimers();
    warn.mockRestore();
  });
});
