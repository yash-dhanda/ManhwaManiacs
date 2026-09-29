import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { switchSkin, type SwitchDeps } from "./switch-skin";

const log: string[] = [];
let deps: SwitchDeps;
let patchImpl: (signal: AbortSignal) => Promise<unknown>;
let signalSeen: AbortSignal | null;

const opts = (outgoing: () => Promise<void> = async () => void log.push("outgoing")) => ({
  profileId: 7,
  to: "glass" as const,
  from: "cinematic" as const,
  outgoing,
  reverse: async () => void log.push("reverse"),
});

beforeEach(() => {
  vi.useFakeTimers();
  log.length = 0;
  signalSeen = null;
  patchImpl = async () => ({});
  deps = {
    patch: (_id, _skin, signal) => {
      log.push("patch");
      signalSeen = signal;
      return patchImpl(signal);
    },
    markStart: () => void log.push("t0"),
    clearStart: () => void log.push("clear-t0"),
    restartInto: vi.fn(() => void log.push("restart")),
    isOnline: () => true,
    path: () => "/library?x=1",
  };
});
afterEach(() => vi.useRealTimers());

describe("switchSkin", () => {
  it("writes t0 first and starts the PATCH before outgoing resolves", async () => {
    await switchSkin(opts(), deps);
    expect(log.slice(0, 3)).toEqual(["t0", "patch", "outgoing"]);
  });

  it("restarts on a 2xx with the mirror cookie and the current path", async () => {
    expect(await switchSkin(opts(), deps)).toBe("restarting");
    expect(deps.restartInto).toHaveBeenCalledWith({
      cookie: "mm-skin",
      skin: "glass",
      from: "cinematic",
      returnPath: "/library?x=1",
    });
  });

  it("reverses on a rejection, removes t0 and writes no cookie", async () => {
    patchImpl = () => Promise.reject(new Error("500"));
    expect(await switchSkin(opts(), deps)).toBe("failed");
    expect(log).toContain("reverse");
    expect(log).toContain("clear-t0");
    expect(deps.restartInto).not.toHaveBeenCalled();
  });

  it("aborts a PATCH that lands 1,001 ms after outgoing ends", async () => {
    patchImpl = () => new Promise((resolve) => setTimeout(resolve, 1500));
    const p = switchSkin(opts(), deps);
    await vi.advanceTimersByTimeAsync(1001);
    expect(await p).toBe("failed");
    expect(signalSeen?.aborted).toBe(true);
    expect(deps.restartInto).not.toHaveBeenCalled();
  });

  it("waits the full second from the end of outgoing", async () => {
    patchImpl = () => new Promise((resolve) => setTimeout(resolve, 1400));
    const outgoing = () => new Promise<void>((r) => setTimeout(r, 500));
    const p = switchSkin(opts(outgoing), deps);
    await vi.advanceTimersByTimeAsync(1500);
    expect(await p).toBe("restarting");
  });

  it("fails offline without calling outgoing or the server", async () => {
    deps.isOnline = () => false;
    expect(await switchSkin(opts(), deps)).toBe("failed");
    expect(log).toEqual([]);
  });
});
