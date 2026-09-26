import { describe, expect, it } from "vitest";
import {
  canSubmitPrompt,
  MAX_PROMPT_LENGTH,
  MIN_PROMPT_LENGTH,
  suggestionsSubtitle,
} from "./suggestions";

describe("spending a request", () => {
  it("refuses a description too short to mean anything", () => {
    // Refused here rather than by a 422, so a stray keystroke costs nothing.
    expect(canSubmitPrompt("", false)).toBe(false);
    expect(canSubmitPrompt("a", false)).toBe(false);
    expect(canSubmitPrompt("   ", false)).toBe(false);
  });

  it("refuses whitespace padding that only looks long enough", () => {
    expect(canSubmitPrompt("  a  ", false)).toBe(false);
  });

  it("allows a real description", () => {
    expect(canSubmitPrompt("murim", false)).toBe(true);
    expect(canSubmitPrompt("a".repeat(MIN_PROMPT_LENGTH), false)).toBe(true);
  });

  it("refuses a second request while one is in flight", () => {
    // One submit is one paid call; double-tapping the button must not be two.
    expect(canSubmitPrompt("a revenge story", true)).toBe(false);
  });

  it("agrees with the server about the bounds", () => {
    expect(MIN_PROMPT_LENGTH).toBe(3);
    expect(MAX_PROMPT_LENGTH).toBe(600);
  });
});

describe("why the box is hidden", () => {
  it("describes the working state when the box can ask", () => {
    expect(suggestionsSubtitle(true, "ok")).toContain("Describe it");
  });

  it("tells a spent budget it comes back, not just that it's gone", () => {
    // The one distinction this whole helper exists for: two reasons that
    // both hide the identical box used to render the identical sentence.
    const copy = suggestionsSubtitle(false, "budget_exhausted");
    expect(copy).toContain("used today's AI suggestions");
    expect(copy).toContain("midnight UTC");
  });

  it("never points at the genre chips, which are gone", () => {
    for (const reason of ["budget_exhausted", "not_configured", undefined]) {
      expect(suggestionsSubtitle(false, reason)).not.toMatch(/genre/i);
    }
  });

  it("falls back to the picks pitch for a server with no key at all", () => {
    expect(suggestionsSubtitle(false, "not_configured")).toContain(
      "picked from what you already read",
    );
  });

  it("treats a missing reason the same as not_configured", () => {
    // availabilityQuery.data can be undefined before the first response
    // lands; that must read as "nothing to explain yet", not crash or claim
    // a budget was spent that was never checked.
    expect(suggestionsSubtitle(false, undefined)).toBe(
      suggestionsSubtitle(false, "not_configured"),
    );
  });
});
