import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { HAPTIC_EVENTS } from "../contract.generated";
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

describe("cinematic haptics", () => {
  it("vibrates the five web events with their exact patterns", () => {
    const want: [string, number[]][] = [
      ["longpress.open", [12]],
      ["follow.add", [12]],
      ["streak.milestone", [12]],
      ["download.fail", [20, 40, 20]],
      ["error", [20, 40, 20]],
    ];
    for (const [event, pattern] of want) {
      vibrate.mockClear();
      haptic(event as never);
      expect(vibrate).toHaveBeenCalledWith(pattern);
    }
  });

  it("is a no-op for every other event", () => {
    const five = new Set(["longpress.open", "follow.add", "streak.milestone", "download.fail", "error"]);
    for (const event of HAPTIC_EVENTS) if (!five.has(event)) haptic(event);
    expect(vibrate).not.toHaveBeenCalled();
  });

  it("respects mm.haptics = off", () => {
    store["mm.haptics"] = "off";
    haptic("error");
    expect(vibrate).not.toHaveBeenCalled();
  });

  it("does nothing on a fine pointer", () => {
    coarse = false;
    haptic("error");
    expect(vibrate).not.toHaveBeenCalled();
  });
});
