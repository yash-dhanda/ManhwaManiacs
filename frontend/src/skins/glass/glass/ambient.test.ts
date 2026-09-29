import { describe, expect, it } from "vitest";
import { ANCHORS, driftTargets, resolveAmbient } from "./AmbientField";
import { MOODS } from "./palette";

describe("ambient field", () => {
  it("drifts within +-6 % of every anchor", () => {
    for (const rand of [() => 0, () => 0.999999, () => 0.5]) {
      driftTargets(rand).forEach(([x, y], i) => {
        expect(Math.abs(x - ANCHORS[i][0])).toBeLessThanOrEqual(6);
        expect(Math.abs(y - ANCHORS[i][1])).toBeLessThanOrEqual(6);
      });
    }
  });
  it("falls back to the mood colour at its own opacity before data", () => {
    const r = resolveAmbient({ mood: "romantic" });
    expect(r.colours).toEqual([MOODS.romantic.colour, MOODS.romantic.colour, MOODS.romantic.colour]);
    expect(r.opacity).toBe(0.2);
    expect(resolveAmbient({}).colours).toEqual(["#4336A3", "#2B2370", "#4336A3"]);
    expect(resolveAmbient({}).opacity).toBe(0.3);
  });
  it("aurora at 20 %, and an explicit opacity wins", () => {
    expect(resolveAmbient({ aurora: true })).toMatchObject({ colours: ["#8FD8FF", "#A99BFF", "#FF9ED8"], opacity: 0.2 });
    expect(resolveAmbient({ mood: "horror", opacity: 0.18 }).opacity).toBe(0.18);
  });
  it("clamps a palette and marks a two-colour palette's third blob small", () => {
    const r = resolveAmbient({ palette: { a: ["#FF0000", "#00FF00"] }, mood: "default" });
    expect(r.smallThird).toBe(true);
    expect(r.colours[2]).toBe(r.colours[0]);
  });
});
