import { describe, expect, it } from "vitest";
import { hexToOklch } from "@/lib/color/oklch";
import { coverPalette, deriveAccents, fieldColours, luminanceStats, MOODS, rimTint } from "./palette";
import { dimFor } from "./material";

describe("palette", () => {
  it("dark cover with one white patch: mean 0.2-ish, lMax 1.0 drives the dim to 0.64", () => {
    const px = new Uint8ClampedArray(32 * 32 * 4);
    for (let i = 0; i < 1024; i++) { const v = i < 100 ? 255 : 90; px.set([v, v, v, 255], i * 4); }
    const { l, lMax } = luminanceStats(px);
    expect(l).toBeLessThan(0.25);
    expect(lMax).toBeCloseTo(1, 5);
    expect(dimFor(lMax)).toBe(0.64);
  });
  it("derives the two accents by rotating hue at the same L and C", () => {
    const [a0, a1, a2] = deriveAccents("#7563F2");
    const o = hexToOklch(a0), p = hexToOklch(a1), q = hexToOklch(a2);
    expect(p.l).toBeCloseTo(o.l, 1);
    expect(q.c).toBeCloseTo(o.c, 1);
    expect(((p.h - o.h + 360) % 360)).toBeCloseTo(30, -1);
    expect(((o.h - q.h + 360) % 360)).toBeCloseTo(30, -1);
  });
  it("clamps the field to L 0.55-0.78 and C 0.06-0.16, keeps the hue", () => {
    const { colours } = fieldColours({ a: ["#FFFFF0", "#101040", "#FF0000"] }, "romantic");
    expect(colours[0]).toBe(MOODS.romantic.colour); // near-grey: mood colour
    const dark = hexToOklch(colours[1]);
    expect(dark.l).toBeGreaterThanOrEqual(0.54);
    const red = hexToOklch(colours[2]);
    expect(red.c).toBeLessThanOrEqual(0.161);
    expect(red.l).toBeLessThanOrEqual(0.781);
    expect(red.h).toBeCloseTo(hexToOklch("#FF0000").h, -1);
  });
  it("reuses the first colour when fewer than three (third blob drawn small)", () => {
    const r = fieldColours({ a: ["#4433AA"] }, "default");
    expect(r.smallThird).toBe(true);
    expect(r.colours[1]).toBe(r.colours[0]);
    expect(r.colours[2]).toBe(r.colours[0]);
  });
  it("rim tint is light and low-chroma", () => {
    const o = hexToOklch(rimTint({ a: ["#FF0000"] }));
    expect(o.l).toBeCloseTo(0.86, 1);
    expect(o.c).toBeLessThanOrEqual(0.081);
  });
  it("uses the server palette when present", async () => {
    const p = { a: ["#111111", "#222222", "#333333"], l: 0.1, lMax: 0.5 };
    await expect(coverPalette({ palette: p })).resolves.toBe(p);
  });
});
