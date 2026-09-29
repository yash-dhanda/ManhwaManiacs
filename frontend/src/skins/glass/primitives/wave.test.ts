import { describe, expect, it } from "vitest";
import { WAVE_CAP, waveDelays } from "./wave";

describe("entrance wave", () => {
  it("delay grows with distance at 1.6 px/ms", () => {
    const d = waveDelays([{ x: 0, y: 0 }, { x: 160, y: 0 }, { x: 0, y: 320 }], { x: 0, y: 0 });
    expect(d[0]).toBe(0);
    expect(d[1]).toBeCloseTo(100);
    expect(d[2]).toBeCloseTo(200);
  });
  it("caps at 240 ms", () => {
    expect(waveDelays([{ x: 5000, y: 0 }], { x: 0, y: 0 })[0]).toBe(WAVE_CAP);
    expect(WAVE_CAP).toBe(240);
  });
});
