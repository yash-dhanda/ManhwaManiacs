import { describe, expect, it } from "vitest";
import { decideThrow, isTap, liftScale, magnetTarget, pressPhase, throwIntensity } from "./poster-throw";

const vp = { w: 400, h: 800 };
describe("poster lift", () => {
  it("phases and scale", () => {
    expect(pressPhase(100)).toBe("press");
    expect(pressPhase(150)).toBe("lift");
    expect(pressPhase(450)).toBe("menu");
    expect(liftScale(150)).toBe(1);
    expect(liftScale(300)).toBeCloseTo(1.03, 5);
    expect(liftScale(450)).toBeCloseTo(1.06, 5);
    expect(liftScale(900)).toBeCloseTo(1.06, 5);
  });
  it("a tap is a release before 450 ms inside the slop", () => {
    expect(isTap(449, false)).toBe(true);
    expect(isTap(450, false)).toBe(false);
    expect(isTap(200, true)).toBe(false);
  });
  it("throw intensity is clamped 0.3 to 1", () => {
    expect(throwIntensity(0)).toBe(0.3);
    expect(throwIntensity(2000)).toBeCloseTo(0.8);
    expect(throwIntensity(9000)).toBe(1);
  });
});
describe("decideThrow", () => {
  it("open above the top 20 % or on a hard upward throw", () => {
    expect(decideThrow({ centre: { x: 200, y: 100 }, velocity: { x: 0, y: 0 }, viewport: vp }).kind).toBe("open");
    const d = decideThrow({ centre: { x: 200, y: 600 }, velocity: { x: 0, y: -1300 }, viewport: vp });
    expect(d.kind).toBe("open");
    expect(d.kind === "open" && d.velocity.y).toBe(-1300);
  });
  it("away needs allowAway, and a side edge or 1,200 px/s sideways", () => {
    const base = { centre: { x: 200, y: 500 }, viewport: vp };
    expect(decideThrow({ ...base, velocity: { x: 1300, y: 0 } }).kind).toBe("drop");
    expect(decideThrow({ ...base, velocity: { x: 1300, y: 0 }, allowAway: true })).toEqual({ kind: "away", side: "right" });
    expect(decideThrow({ ...base, velocity: { x: -1300, y: 0 }, allowAway: true })).toEqual({ kind: "away", side: "left" });
    expect(decideThrow({ centre: { x: 390, y: 500 }, velocity: { x: 500, y: 0 }, viewport: vp, allowAway: true }).kind).toBe("away");
  });
  it("target within 64 px of a friend orb", () => {
    const targets = [{ id: "a", x: 100, y: 500 }, { id: "b", x: 300, y: 500 }];
    expect(decideThrow({ centre: { x: 130, y: 520 }, velocity: { x: 0, y: 0 }, viewport: vp, targets })).toEqual({ kind: "target", id: "a" });
    expect(decideThrow({ centre: { x: 200, y: 520 }, velocity: { x: 0, y: 0 }, viewport: vp, targets }).kind).toBe("drop");
    expect(magnetTarget({ x: 250, y: 500 }, targets)).toBe("b");
  });
  it("open wins over the others", () => {
    expect(decideThrow({ centre: { x: 100, y: 500 }, velocity: { x: 0, y: -2000 }, viewport: vp, allowAway: true, targets: [{ id: "a", x: 100, y: 500 }] }).kind).toBe("open");
  });
});
