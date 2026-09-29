import { describe, expect, it } from "vitest";
import { p3State, runP3 } from "./p3-limiter";

describe("runP3", () => {
  it("runs at most two at once and drains the rest", async () => {
    const releases: Array<() => void> = [];
    const gate = () => new Promise<void>((r) => releases.push(r));
    const done = [runP3(gate), runP3(gate), runP3(gate)];
    expect(p3State()).toEqual({ inFlight: 2, queued: 1 });
    releases[0]();
    await done[0];
    expect(p3State().inFlight).toBe(2);
    releases[1]();
    releases[2]();
    await Promise.all(done);
    expect(p3State()).toEqual({ inFlight: 0, queued: 0 });
  });
  it("swallows a failing task", async () => {
    await expect(runP3(() => Promise.reject(new Error("x")))).resolves.toBeUndefined();
  });
});
