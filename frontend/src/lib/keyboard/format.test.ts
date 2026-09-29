import { describe, expect, it } from "vitest";
import { formatKeyCombo, formatKeyToken } from "./format";

describe("formatKeyToken", () => {
  it("renders delete and backspace as the Mac glyph or Del", () => {
    expect(formatKeyToken("delete", true)).toBe("⌫");
    expect(formatKeyToken("backspace", true)).toBe("⌫");
    expect(formatKeyToken("delete", false)).toBe("Del");
    expect(formatKeyToken("backspace", false)).toBe("Del");
  });
  it("keeps the existing cases", () => {
    expect(formatKeyToken("space", false)).toBe("Space");
    expect(formatKeyToken("b", false)).toBe("B");
    expect(formatKeyToken("escape", false)).toBe("Escape");
  });
  it("formats a combo with a delete key", () => {
    expect(formatKeyCombo("delete").length).toBe(1);
  });
});
