import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import {
  clearEntries,
  entries,
  formatEntry,
  isLate,
  logSkinRestart,
  markSkinRestartStart,
  setRecording,
  startMove,
} from "./motion-timings";

let now = 0;
let cbs: FrameRequestCallback[] = [];
const store = new Map<string, string>();

function step(ms: number) {
  now += ms;
  const run = cbs;
  cbs = [];
  run.forEach((cb) => cb(now));
}

beforeEach(() => {
  now = 1000;
  cbs = [];
  store.clear();
  vi.stubGlobal("requestAnimationFrame", (cb: FrameRequestCallback) => cbs.push(cb));
  vi.stubGlobal("cancelAnimationFrame", () => {});
  vi.stubGlobal("performance", { now: () => now });
  vi.stubGlobal("sessionStorage", {
    getItem: (k: string) => store.get(k) ?? null,
    setItem: (k: string, v: string) => void store.set(k, v),
    removeItem: (k: string) => void store.delete(k),
  });
  vi.spyOn(Date, "now").mockImplementation(() => now);
  vi.spyOn(console, "table").mockImplementation(() => {});
  vi.spyOn(console, "info").mockImplementation(() => {});
  clearEntries();
  setRecording(false);
});
afterEach(() => {
  setRecording(false);
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

describe("motion-timings", () => {
  it("keeps the last 200 entries", () => {
    setRecording(true);
    for (let i = 0; i < 205; i++) startMove(`m${i}`, 100).end();
    expect(entries()).toHaveLength(200);
    expect(entries()[0].name).toBe("m5");
  });

  it("counts a 50 ms gap at 60 Hz as 2 dropped frames", () => {
    setRecording(true);
    const h = startMove("column wipe", 200);
    for (let i = 0; i < 5; i++) step(1000 / 60);
    step(50);
    for (let i = 0; i < 3; i++) step(1000 / 60);
    h.end();
    expect(entries()[0].dropped).toBe(2);
    expect(entries()[0].frames).toBe(9);
    expect(isLate(entries()[0])).toBe(true);
  });

  it("does nothing while recording is off", () => {
    startMove("x", 100).end();
    expect(cbs).toHaveLength(0);
    expect(entries()).toHaveLength(0);
  });

  it("logs a restart while off, clears t0 and warns over 1500 ms", () => {
    const warn = vi.spyOn(console, "warn").mockImplementation(() => {});
    markSkinRestartStart();
    expect(store.get("mm.skin.t0")).toBe("1000");
    now += 1600;
    const e = logSkinRestart("glass");
    expect(e?.kind).toBe("restart");
    expect(entries()).toHaveLength(1);
    expect(store.has("mm.skin.t0")).toBe(false);
    expect(warn).toHaveBeenCalledWith("SKIN RESTART 1600 ms > 1500 ms");
    expect(isLate(entries()[0])).toBe(true);
  });

  it("returns null without t0", () => {
    expect(logSkinRestart("glass")).toBeNull();
    expect(entries()).toHaveLength(0);
  });

  it("formats entries", () => {
    const base = { kind: "move" as const, startFrame: 0, endFrame: 53, frames: 53, plannedFrames: 53, dropped: 0, startMs: 0 };
    expect(formatEntry({ ...base, name: "column wipe", plannedMs: 872, endMs: 880 })).toBe(
      "COLUMN WIPE   872 → 880 MS   53/53 F   0 DROP",
    );
    expect(
      formatEntry({ ...base, kind: "restart", name: "SKIN RESTART", plannedMs: 0, endMs: 1212 }),
    ).toBe("SKIN RESTART  confirm → first splash frame  1,212 MS");
  });
});
