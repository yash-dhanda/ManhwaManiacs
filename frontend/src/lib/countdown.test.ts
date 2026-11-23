import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { startCountdown } from "./countdown";

const START = Date.parse("2026-11-23T10:48:00Z");

beforeEach(() => {
  vi.useFakeTimers();
  vi.setSystemTime(START);
});
afterEach(() => {
  vi.useRealTimers();
});

describe("startCountdown", () => {
  it("ticks once a second with the remaining time", () => {
    const ticks: number[] = [];
    startCountdown("2026-11-23T10:48:03Z", {
      onTick: (ms) => ticks.push(ms),
      onUnlocked: () => {},
    });
    expect(ticks).toEqual([3000]);
    vi.advanceTimersByTime(1000);
    expect(ticks).toEqual([3000, 2000]);
  });

  it("stops at zero and fires onUnlocked exactly once", () => {
    const onUnlocked = vi.fn();
    const ticks: number[] = [];
    startCountdown("2026-11-23T10:48:02Z", { onTick: (ms) => ticks.push(ms), onUnlocked });
    vi.advanceTimersByTime(10_000);
    expect(onUnlocked).toHaveBeenCalledTimes(1);
    expect(ticks.at(-1)).toBe(0);
    expect(vi.getTimerCount()).toBe(0);
  });

  it("fires immediately for an instant already past", () => {
    const onUnlocked = vi.fn();
    startCountdown("2026-11-23T09:00:00Z", { onTick: () => {}, onUnlocked });
    expect(onUnlocked).toHaveBeenCalledTimes(1);
    expect(vi.getTimerCount()).toBe(0);
  });

  it("does nothing for a missing or malformed instant", () => {
    const onTick = vi.fn();
    const onUnlocked = vi.fn();
    startCountdown(null, { onTick, onUnlocked });
    startCountdown("later", { onTick, onUnlocked });
    expect(onTick).not.toHaveBeenCalled();
    expect(onUnlocked).not.toHaveBeenCalled();
    expect(vi.getTimerCount()).toBe(0);
  });

  it("clears its interval when disposed and never fires afterwards", () => {
    const onUnlocked = vi.fn();
    const stop = startCountdown("2026-11-23T10:48:05Z", { onTick: () => {}, onUnlocked });
    expect(vi.getTimerCount()).toBe(1);
    stop();
    stop();
    expect(vi.getTimerCount()).toBe(0);
    vi.advanceTimersByTime(10_000);
    expect(onUnlocked).not.toHaveBeenCalled();
  });

  it("follows the wall clock when timers are throttled", () => {
    const ticks: number[] = [];
    startCountdown("2026-11-23T10:48:30Z", { onTick: (ms) => ticks.push(ms), onUnlocked: () => {} });
    vi.setSystemTime(START + 20_000);
    vi.advanceTimersByTime(1000);
    expect(ticks.at(-1)).toBe(9000);
  });
});
