import { describe, expect, it } from "vitest";
import { comboAllowed, isSingleKeyCombo, singleKeyShortcutsEnabled } from "./single-key";

describe("single-key shortcuts", () => {
  it("defaults to on and reads off", () => {
    expect(singleKeyShortcutsEnabled(() => null)).toBe(true);
    expect(singleKeyShortcutsEnabled(() => "on")).toBe(true);
    expect(singleKeyShortcutsEnabled(() => "off")).toBe(false);
  });
  it("classifies combos", () => {
    expect(isSingleKeyCombo("j")).toBe(true);
    expect(isSingleKeyCombo("g l")).toBe(true);
    expect(isSingleKeyCombo("shift+j")).toBe(true);
    expect(isSingleKeyCombo("mod+k")).toBe(false);
    expect(isSingleKeyCombo("alt+t")).toBe(false);
    expect(isSingleKeyCombo("escape")).toBe(false);
    expect(isSingleKeyCombo("shift+?")).toBe(false);
  });
  it("gates only when off", () => {
    expect(comboAllowed("j", true)).toBe(true);
    expect(comboAllowed("j", false)).toBe(false);
    expect(comboAllowed(["j", "mod+j"], false)).toBe(true);
  });
});
