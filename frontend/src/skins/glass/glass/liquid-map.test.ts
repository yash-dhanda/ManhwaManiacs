import { describe, expect, it } from "vitest";
import { encode, mapKey, profileFor, renderMapData, SAMPLES, type MapShape } from "./liquid-map";
import { TIERS } from "./material";
import { glass } from "../tokens.generated";

describe("liquid map profile", () => {
  it("is 0 at the inner edge, monotonic toward the rim, and peaks at the tier's max displacement", () => {
    for (const t of TIERS) {
      const p = profileFor(t);
      expect(p).toHaveLength(SAMPLES);
      expect(p[SAMPLES - 1]).toBeCloseTo(0, 6);
      expect(p[0]).toBeCloseTo(glass[t].displacement, 6);
      for (let i = 1; i < p.length; i++) expect(p[i]).toBeLessThanOrEqual(p[i - 1] + 1e-9);
    }
  });
  it("encodes the maximum as R 255 (or 1) and zero as 128", () => {
    expect(encode(10, 10)).toBe(255);
    expect(encode(-10, 10)).toBe(1);
    expect(encode(0, 10)).toBe(128);
  });
});

describe("liquid map pixels", () => {
  const shape: MapShape = { x: 0, y: 0, w: 100, h: 100, r: 20, tier: "t2" };
  const at = (d: Uint8ClampedArray, x: number, y: number, w = 100) => [d[(y * w + x) * 4], d[(y * w + x) * 4 + 1]];
  it("is neutral at the centre and outside the band", () => {
    const { data } = renderMapData([shape], 100, 100);
    expect(at(data, 50, 50)).toEqual([128, 128]);
  });
  it("bends inward at a straight vertical edge (left R 255, right R 1)", () => {
    const { data } = renderMapData([shape], 100, 100);
    expect(at(data, 0, 50)).toEqual([255, 128]);
    expect(at(data, 99, 50)[0]).toBe(1);
    expect(at(data, 50, 0)).toEqual([128, 255]);
  });
  it("keys on rounded shapes, tiers and variant", () => {
    expect(mapKey([shape], 100.2, 100, "a")).toBe(mapKey([{ ...shape, x: 0.3 }], 100, 100, "a"));
    expect(mapKey([shape], 100, 100)).not.toBe(mapKey([{ ...shape, tier: "t3" }], 100, 100));
  });
});
