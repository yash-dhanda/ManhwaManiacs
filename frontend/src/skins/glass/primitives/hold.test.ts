import { describe, expect, it } from "vitest";
import { fillLevel, holdStep, initialHold, rampIntensity, type HoldEvent, type HoldState } from "./hold";

const run = (evs: HoldEvent[], reduced = false) => {
  let s: HoldState = initialHold;
  const fx: string[] = [];
  for (const e of evs) { const r = holdStep(s, e, reduced); s = r.state; fx.push(...r.effects.map((x) => (x.type === "ramp" ? `ramp${x.intensity.toFixed(2)}` : x.type))); }
  return { s, fx };
};

describe("hold to confirm", () => {
  it("a release before 200 ms with under 8 px is a click", () => {
    const { s, fx } = run([{ type: "down", t: 0 }, { type: "up", t: 150, dist: 3 }]);
    expect(s.phase).toBe("clicked");
    expect(fx).toEqual(["click"]);
  });
  it("8 px of movement before 200 ms cancels; the release does nothing", () => {
    const { s, fx } = run([{ type: "down", t: 0 }, { type: "move", t: 100, dist: 10 }, { type: "up", t: 150, dist: 10 }]);
    expect(s.phase).toBe("cancelled");
    expect(fx).toEqual(["cancel"]);
  });
  it("pointercancel cancels", () => expect(run([{ type: "down", t: 0 }, { type: "cancel" }]).s.phase).toBe("cancelled"));
  it("nothing fills for 200 ms; the fill starts at 200 ms and the ramp fires at its start", () => {
    const a = run([{ type: "down", t: 0 }, { type: "tick", t: 199 }]);
    expect(a.s.level).toBe(0);
    expect(a.fx).toEqual([]);
    const b = run([{ type: "down", t: 0 }, { type: "tick", t: 200 }]);
    expect(b.fx).toEqual(["ramp0.20"]);
    expect(b.s.phase).toBe("filling");
  });
  it("ramps every 150 ms rising 0.2 to 0.8, and 1,200 ms confirms", () => {
    const ticks: HoldEvent[] = [{ type: "down", t: 0 }];
    for (let t = 0; t <= 1200; t += 10) ticks.push({ type: "tick", t });
    const { s, fx } = run(ticks);
    const ramps = fx.filter((f) => f.startsWith("ramp"));
    expect(ramps.length).toBe(7); // elapsed 0,150,...,900 (a 1,000 ms fill)
    expect(ramps[0]).toBe("ramp0.20");
    expect(parseFloat(ramps[6].slice(4))).toBeCloseTo(0.2 + 0.6 * 0.9, 1);
    expect(s.phase).toBe("done");
    expect(fx.filter((f) => f === "done")).toHaveLength(1);
  });
  it("a release after 200 ms and before completion aborts", () => {
    const { s, fx } = run([{ type: "down", t: 0 }, { type: "tick", t: 300 }, { type: "tick", t: 600 }, { type: "up", t: 620 }]);
    expect(s.phase).toBe("aborted");
    expect(fx.at(-1)).toBe("abort");
  });
  it("reduced motion steps the level in four 25 % increments 250 ms apart", () => {
    expect([100, 250, 499, 500, 750, 999, 1000].map((e) => fillLevel(e, true))).toEqual([0, 0.25, 0.25, 0.5, 0.75, 0.75, 1]);
  });
  it("ramp intensity is clamped", () => { expect(rampIntensity(-1)).toBe(0.2); expect(rampIntensity(2)).toBeCloseTo(0.8); });
});
