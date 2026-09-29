import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { haptic } from "./haptics";

let vibrate: ReturnType<typeof vi.fn>;
let coarse = true;
let store: Record<string, string>;
let clock = 1000;

beforeEach(() => {
  vibrate = vi.fn();
  coarse = true;
  store = {};
  clock += 10_000;
  vi.stubGlobal("navigator", { vibrate });
  vi.stubGlobal("matchMedia", () => ({ matches: coarse }));
  vi.stubGlobal("localStorage", {
    getItem: (k: string) => store[k] ?? null,
    setItem: (k: string, v: string) => void (store[k] = v),
  });
  vi.stubGlobal("performance", { now: () => clock });
});
afterEach(() => vi.unstubAllGlobals());

describe("glass haptics", () => {
  it("vibrates the seven web events with their exact patterns", () => {
    const want: [string, number[]][] = [
      ["stack.open", [18]],
      ["toggle.on", [10]],
      ["longpress.open", [18]],
      ["follow.add", [12, 60, 12]],
      ["download.fail", [24, 50, 24]],
      ["streak.milestone", [12]],
      ["error", [24, 50, 24, 50, 24]],
    ];
    for (const [event, pattern] of want) {
      clock += 1000;
      vibrate.mockClear();
      haptic(event as never);
      expect(vibrate).toHaveBeenCalledWith(pattern);
    }
  });

  it("is a no-op for other events, off, and fine pointers", () => {
    haptic("tap.primary");
    expect(vibrate).not.toHaveBeenCalled();
    store["mm.haptics"] = "off";
    haptic("error");
    store["mm.haptics"] = "on";
    coarse = false;
    haptic("error");
    expect(vibrate).not.toHaveBeenCalled();
  });

  it("drops a weaker call inside 120 ms but lets a stronger one replace it", () => {
    haptic("error"); // 148
    clock += 50;
    haptic("toggle.on"); // 10, weaker: dropped
    expect(vibrate).toHaveBeenCalledTimes(1);
    clock += 200;
    haptic("toggle.on");
    clock += 50;
    haptic("error"); // stronger: replaces
    expect(vibrate).toHaveBeenCalledTimes(3);
    expect(vibrate).toHaveBeenLastCalledWith([24, 50, 24, 50, 24]);
  });
});
