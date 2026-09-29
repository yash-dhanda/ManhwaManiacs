import { describe, expect, it } from "vitest";
import { spring } from "../tokens.generated";
import { dimFor, tierFor } from "../glass/material";
import { createMagnet } from "./magnet";
import { nearest, project, projectCapped, railSnap } from "./project";
import { rubberband } from "./rubberband";
import { depthIntensity, toPhysical } from "./spring";
import { createTracker } from "./tracker";

describe("DESIGN 15.8 physics values", () => {
  it("projection", () => {
    expect(project(0, 1000)).toBeCloseTo(499, 5);
    expect(railSnap(310, 900, 136)).toBe(816);
    expect(projectCapped(0, 100000, 1, 800)).toBe(800);
    expect(nearest([0, 100, 300], 180)).toBe(100);
  });
  it("rubber band", () => {
    expect(rubberband(100, 800, 0.55)).toBeCloseTo(51.5, 1);
    expect(rubberband(100, 800)).toBeCloseTo(51.5, 1);
    expect(rubberband(100, 800, 0.35)).toBeLessThan(rubberband(100, 800, 0.55));
  });
  it("springs", () => {
    const page = toPhysical(520, 0);
    expect(page.stiffness).toBeCloseTo(146.0, 0);
    expect(page.damping).toBeCloseTo(24.17, 2);
    const track = toPhysical(150, 0.14);
    expect(track.stiffness).toBeCloseTo(1754.6, 0);
    expect(track.damping).toBeCloseTo(72.05, 2);
    // the generated token springs carry the same numbers
    expect(spring.page.stiffness).toBeCloseTo(page.stiffness, 0);
    expect(Math.abs(spring.page.stiffness - 146)).toBeLessThan(0.1);
    expect(Math.abs(spring.page.damping - 24.17)).toBeLessThan(0.1);
    expect(Math.abs(spring.track.stiffness - 1754.6)).toBeLessThan(0.1);
    expect(Math.abs(spring.track.damping - 72.05)).toBeLessThan(0.1);
  });
  it("tier, dim, depth", () => {
    expect(tierFor(44)).toBe("t2");
    expect(tierFor(240)).toBe("t4");
    expect(tierFor(401)).toBe("t4");
    expect(dimFor(1.0)).toBe(0.64);
    expect(dimFor(0)).toBe(0.22);
    // dark cover, one white patch: mean l 0.2, lMax 1.0: the cover source reads lMax
    const cover = { l: 0.2, lMax: 1.0 };
    expect(dimFor(cover.lMax)).toBe(0.64);
    expect(depthIntensity(3)).toBeCloseTo(0.54, 10);
  });
  it("tracker velocity on a 1000 px/s drag", () => {
    const t = createTracker("x");
    t.start({ clientX: 0, clientY: 0, timeStamp: 0, pointerType: "mouse" });
    for (let i = 1; i <= 12; i++) t.move({ clientX: i * 16, clientY: 0, timeStamp: i * 16 });
    const { offset, velocity } = t.end();
    expect(velocity).toBeCloseTo(1000, -1);
    expect(offset).toBe(192);
    const single = createTracker();
    single.start({ clientX: 5, clientY: 0, timeStamp: 0 });
    expect(single.end().velocity).toBe(0);
  });
  it("tracker slop per pointer type", () => {
    const touch = createTracker();
    touch.start({ clientX: 0, clientY: 0, timeStamp: 0, pointerType: "touch" });
    expect(touch.move({ clientX: 9, clientY: 0, timeStamp: 10 })).toBeNull();
    expect(touch.move({ clientX: 11, clientY: 0, timeStamp: 20 })).toBe(11);
    const mouse = createTracker();
    mouse.start({ clientX: 0, clientY: 0, timeStamp: 0, pointerType: "mouse" });
    expect(mouse.move({ clientX: 4, clientY: 0, timeStamp: 10 })).toBe(4);
  });
  it("magnet captures at 63 px and not at 65 px", () => {
    const m = createMagnet([0]);
    const hit = m.step(63);
    expect(hit.capture).toBe(true);
    expect(hit.pos).toBeCloseTo(63 * 0.65, 5);
    expect(createMagnet([0]).step(65)).toMatchObject({ capture: false, target: null, pos: 65 });
    const both = createMagnet([0]);
    both.step(30);
    expect(both.step(100).release).toBe(true);
  });
});
