import { describe, expect, it } from "vitest";
import { engineLabel } from "./engine-label";

describe("engineLabel", () => {
  it("names the two on-device engines", () => {
    for (const e of ["vision", "Apple_Vision", "apple-vision"]) expect(engineLabel(e)).toBe("VISION");
    for (const e of ["mlkit", "ML_KIT", "ml-kit"]) expect(engineLabel(e)).toBe("ML KIT");
  });
  it("upper-cases anything else", () => {
    expect(engineLabel("tesseract")).toBe("TESSERACT");
  });
});
