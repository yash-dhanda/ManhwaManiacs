import { describe, expect, it } from "vitest";
import { dialKey, dialMagnet, dialTicked, dialValueFromDrag, overshoot, pageAt, sliderKey, snapToStep, steppedThumb } from "./slider-math";

describe("stepped slider", () => {
  it("snaps to steps and reports the 30 % magnet", () => {
    expect(snapToStep(3.2, 0, 10, 1)).toMatchObject({ value: 3, magnet: true });
    expect(snapToStep(3.5, 0, 10, 1)).toMatchObject({ magnet: false });
    expect(snapToStep(11, 0, 10, 1).value).toBe(10);
  });
  it("pulls the thumb onto the step inside the magnet and follows the finger outside it", () => {
    expect(steppedThumb(3.25, 0, 10, 1).display).toBe(3);
    expect(steppedThumb(3.5, 0, 10, 1).display).toBe(3.5);
  });
  it("rubber-bands at most 12 px past the ends", () => {
    for (const o of [1, 20, 400, 4000]) expect(overshoot(o, 300)).toBeLessThanOrEqual(12);
    expect(overshoot(4000, 300)).toBeGreaterThan(11);
    expect(overshoot(0, 300)).toBe(0);
  });
  it("keys: arrows step, Page keys step x 10, Home and End the ends", () => {
    expect(sliderKey(5, "ArrowRight", 0, 100, 1)).toBe(6);
    expect(sliderKey(5, "PageUp", 0, 100, 1)).toBe(15);
    expect(sliderKey(95, "PageUp", 0, 100, 1)).toBe(100);
    expect(sliderKey(5, "Home", 0, 100, 1)).toBe(0);
    expect(sliderKey(5, "End", 0, 100, 1)).toBe(100);
    expect(sliderKey(5, "a", 0, 100, 1)).toBeNull();
  });
});

describe("speed dial", () => {
  it("maps 6 px of drag to 0.05, upward raising the speed", () => {
    expect(dialValueFromDrag(1, 0)).toBe(1);
    expect(dialValueFromDrag(1, -6)).toBe(1.05);
    expect(dialValueFromDrag(1, -60)).toBe(1.5);
    expect(dialValueFromDrag(1, 12)).toBe(0.9);
    expect(dialValueFromDrag(1, -9999)).toBe(3);
    expect(dialValueFromDrag(1, 9999)).toBe(0.5);
  });
  it("pulls values within 0.08 of 1.0x to 1.0", () => {
    expect(dialMagnet(1.08)).toEqual({ value: 1, magnet: true });
    expect(dialMagnet(0.92)).toEqual({ value: 1, magnet: true });
    expect(dialMagnet(1.1)).toEqual({ value: 1.1, magnet: false });
  });
  it("ticks every 0.25x", () => {
    expect(dialTicked(0.95, 1.0)).toBe(true);
    expect(dialTicked(1.05, 1.1)).toBe(false);
    expect(dialTicked(1.2, 1.3)).toBe(true);
  });
  it("keys: 0.05, 0.25, ends", () => {
    expect(dialKey(1, "ArrowUp")).toBe(1.05);
    expect(dialKey(1, "PageDown")).toBe(0.75);
    expect(dialKey(1, "Home")).toBe(0.5);
    expect(dialKey(1, "End")).toBe(3);
  });
});

describe("scrub rail", () => {
  it("snaps to the nearest page", () => {
    expect(pageAt(0, 40)).toBe(1);
    expect(pageAt(1, 40)).toBe(40);
    expect(pageAt(0.5, 41)).toBe(21);
  });
});
