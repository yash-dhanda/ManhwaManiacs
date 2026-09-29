import { describe, expect, it } from "vitest";
import { rainAcceleration, rainStep, spawnDrop, type Drop } from "./rain";

const b = { w: 300, h: 80 };
const fixed = () => 0.5;

describe("rain", () => {
  it("a droplet crosses the height in 4 s under constant acceleration", () => {
    expect(rainAcceleration(80)).toBeCloseTo(10);
    let d: Drop = { x: 100, y: 0, vy: 0, r: 4, phase: 0, t: 0 };
    for (let i = 0; i < 400; i++) d = { ...rainStep(d, 0.01, { w: 300, h: 1e15 }, fixed) };
    expect(d.t).toBeCloseTo(4, 5);
    expect(d.y / (0.5 * rainAcceleration(1e15) * 16)).toBeCloseTo(1, 1);
  });
  it("wobbles laterally at 15 % of the fall speed", () => {
    const d: Drop = { x: 100, y: 10, vy: 100, r: 4, phase: Math.PI / 2, t: 0 };
    const n = rainStep(d, 0.01, { w: 300, h: 1e6 }, fixed);
    expect(Math.abs(n.x - 100)).toBeLessThanOrEqual(0.15 * n.vy * 0.01 + 1e-9);
    expect(n.x).not.toBe(100);
  });
  it("respawns above the top with radius 3 to 6", () => {
    const d: Drop = { x: 10, y: b.h + 10, vy: 50, r: 4, phase: 0, t: 3 };
    const n = rainStep(d, 0.016, b, fixed);
    expect(n.y).toBeLessThan(0);
    expect(n.vy).toBe(0);
    for (const r of [0, 0.5, 0.999]) {
      const s = spawnDrop(b, () => r);
      expect(s.r).toBeGreaterThanOrEqual(3);
      expect(s.r).toBeLessThanOrEqual(6);
    }
  });
});
