import { describe, expect, it } from "vitest";
import { barrierOpacity, clampZoom, containSize, coverFolio, pageFolio, panForZoom, shouldDismissLightbox, toggleZoom, zoomLabel } from "./lightbox-math";

describe("lightbox maths", () => {
  it("caps the resting size at 1.5x natural pixels", () => {
    expect(containSize(720, 1080, 4000, 4000)).toEqual({ w: 1080, h: 1620 });
    const s = containSize(720, 1080, 400, 600);
    expect(s.w).toBeCloseTo(400); expect(s.h).toBeCloseTo(600);
    expect(containSize(0, 10, 100, 100)).toEqual({ w: 0, h: 0 });
  });
  it("barrier fades with the drag", () => {
    expect(barrierOpacity(0)).toBe(0.96);
    expect(barrierOpacity(200)).toBeCloseTo(0.48);
    expect(barrierOpacity(400)).toBe(0);
    expect(barrierOpacity(-50)).toBe(0.96);
  });
  it("dismisses past 120 px or 800 px/s", () => {
    expect(shouldDismissLightbox(120, 0)).toBe(false);
    expect(shouldDismissLightbox(121, 0)).toBe(true);
    expect(shouldDismissLightbox(10, 800)).toBe(false);
    expect(shouldDismissLightbox(10, 801)).toBe(true);
  });
  it("clamps zoom to 1..4 and toggles 1 <-> 2.5", () => {
    expect(clampZoom(0.2)).toBe(1); expect(clampZoom(9)).toBe(4);
    expect(toggleZoom(1)).toBe(2.5); expect(toggleZoom(2.5)).toBe(1);
    expect(zoomLabel(2.5)).toBe("250%");
  });
  it("keeps the pointer point fixed and resets at 1x", () => {
    expect(panForZoom({ x: 100, y: 0 }, 1, 2, { x: 0, y: 0 })).toEqual({ x: -100, y: 0 });
    expect(panForZoom({ x: 100, y: 0 }, 2, 1, { x: -100, y: 0 })).toEqual({ x: 0, y: 0 });
  });
  it("folios", () => { expect(coverFolio(720, 1080)).toBe("COVER · 720 × 1080"); expect(pageFolio(18, 800, 12400)).toBe("PAGE 18 · 800 × 12400"); });
});
