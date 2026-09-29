import { describe, expect, it } from "vitest";
import { armIdle, armStart, canCommit, isArmed, phraseMatches } from "./arm";

describe("arm", () => {
  it("is disabled until 1000 ms and a press at 999 ms is ignored", () => {
    const s = armStart(0);
    expect(isArmed(s, 0)).toBe(false);
    expect(canCommit(s, 999)).toBe(false);
    expect(canCommit(s, 1000)).toBe(true);
  });
  it("idle never arms", () => expect(isArmed(armIdle(), 5000)).toBe(false));
  it("heavy confirms need the arm AND the condition", () => {
    const s = armStart(0);
    expect(canCommit(s, 1500, false)).toBe(false);
    expect(canCommit(s, 500, true)).toBe(false);
    expect(canCommit(s, 1500, true)).toBe(true);
  });
  it("phrase is case-insensitive", () => {
    expect(phraseMatches(" restore ", "RESTORE")).toBe(true);
    expect(phraseMatches("restor", "RESTORE")).toBe(false);
  });
});
