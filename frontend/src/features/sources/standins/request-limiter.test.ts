import { describe, expect, it } from "vitest";
import { createLimiter } from "./request-limiter";

describe("stand-in limiter", () => {
  it("runs a task and returns its value", async () => {
    const l = createLimiter();
    expect(await l.run("P1", async () => 7)).toBe(7);
  });
  it("holds P3 below the token floor but lets P1 through", async () => {
    let t = 0;
    const l = createLimiter({ capacity: 10, refillPerSecond: 0, now: () => t, p3Floor: 20 });
    let p3 = false;
    void l.run("P3", async () => (p3 = true));
    expect(await l.run("P1", async () => 1)).toBe(1);
    expect(p3).toBe(false);
  });
});
