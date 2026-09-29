import { describe, expect, it } from "vitest";
import { stillCrop } from "./still-crop";

describe("stillCrop", () => {
  it("returns the top of the page for a null box", () => {
    expect(stillCrop(null, 0.7)).toEqual({ objectPosition: "50% 0%", scale: 1 });
  });
  it("scales so the box fills 60% of the width", () => {
    expect(stillCrop({ x: 0.4, y: 0.5, w: 0.2, h: 0.1 }, 0.7).scale).toBe(3);
  });
  it("centres a centred box", () => {
    const c = stillCrop({ x: 0.4, y: 0.45, w: 0.2, h: 0.1 }, 0.7);
    expect(c.objectPosition.startsWith("50%")).toBe(true);
  });
  it("clamps at the edges", () => {
    expect(stillCrop({ x: 0, y: 0, w: 0.2, h: 0.05 }, 0.7).objectPosition).toBe("0% 0%");
    expect(stillCrop({ x: 0.8, y: 0.95, w: 0.2, h: 0.05 }, 0.7).objectPosition).toBe("100% 100%");
  });
  it("never zooms out for a wide box", () => {
    expect(stillCrop({ x: 0, y: 0, w: 0.9, h: 0.1 }, 0.7).scale).toBe(1);
  });
});
