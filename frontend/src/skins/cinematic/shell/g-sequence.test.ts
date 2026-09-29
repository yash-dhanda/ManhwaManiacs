import { describe, expect, it } from "vitest";
import { gChip, gKey, gTarget, gTick, IDLE, type GState } from "./g-sequence";

const run = (keys: [string, number][]) => {
  let s: GState = IDLE;
  const out: { consumed: boolean; jump?: number }[] = [];
  for (const [k, t] of keys) { const r = gKey(s, k, t); s = r.state; out.push({ consumed: r.consumed, jump: r.jump }); }
  return { s, out };
};

describe("g sequence", () => {
  it("g then 2..9 and 0 jump at once and consume both keys", () => {
    const { out, s } = run([["g", 0], ["2", 100]]);
    expect(out).toEqual([{ consumed: true, jump: undefined }, { consumed: true, jump: 2 }]);
    expect(s).toBe(IDLE);
    expect(run([["g", 0], ["0", 10]]).out[1].jump).toBe(0);
  });
  it("g 1 then 1 or 0 or 2 is 11 / 10 / 12", () => {
    expect(run([["g", 0], ["1", 10], ["1", 200]]).out[2].jump).toBe(11);
    expect(run([["g", 0], ["1", 10], ["0", 200]]).out[2].jump).toBe(10);
    expect(run([["g", 0], ["1", 10], ["2", 200]]).out[2].jump).toBe(12);
  });
  it("g 1 alone jumps to 01 after 600 ms", () => {
    const r = gKey(gKey(IDLE, "g", 0).state, "1", 100);
    expect(gTick(r.state, 600).jump).toBeUndefined();
    expect(gTick(r.state, 700)).toMatchObject({ jump: 1, state: IDLE });
  });
  it("Enter jumps to 01", () => expect(run([["g", 0], ["Enter", 50]]).out[1]).toEqual({ consumed: true, jump: 1 }));
  it("arms for 1500 ms, then cancels", () => {
    const s = gKey(IDLE, "g", 0).state;
    expect(gTick(s, 1499).state).toBe(s);
    expect(gTick(s, 1500).state).toBe(IDLE);
    expect(gKey(s, "2", 1600)).toMatchObject({ consumed: false, state: IDLE });
  });
  it("any other key or a modifier cancels without consuming", () => {
    expect(run([["g", 0], ["x", 5]]).out[1]).toEqual({ consumed: false, jump: undefined });
    expect(gKey(gKey(IDLE, "g", 0).state, "2", 5, true)).toMatchObject({ consumed: false, state: IDLE });
    expect(gKey(gKey(IDLE, "g", 0).state, "Escape", 5)).toMatchObject({ consumed: false, state: IDLE });
  });
  it("shift alone does not cancel", () => {
    const s = gKey(IDLE, "g", 0).state;
    expect(gKey(s, "Shift", 5).state).toBe(s);
  });
  it("other keys do not arm", () => expect(gKey(IDLE, "j", 0).consumed).toBe(false));
  it("chip text", () => {
    expect(gChip(IDLE)).toBeNull();
    expect(gChip({ phase: "armed", at: 0 })).toBe("G _");
    expect(gChip({ phase: "one", at: 0 })).toBe("G 1_");
  });
  it("novels mode cancels g 9", () => {
    expect(gTarget(9, true)).toBeNull();
    expect(gTarget(9, false)).toBe("/ocr");
    expect(gTarget(0, false)).toBe("/settings");
    expect(gTarget(12, false)).toBe("/library/recommendations");
  });
});
