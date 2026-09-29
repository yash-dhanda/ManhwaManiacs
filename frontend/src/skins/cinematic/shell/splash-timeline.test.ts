import { describe, expect, it } from "vitest";
import { CONNECTING_MS, handoffStart, LAST_LETTER_START, REVEAL_END, showConnecting, SPLASH_TIMELINE, stepFor } from "./splash-timeline";

describe("splash timeline (§12.4)", () => {
  it("the last letter starts at 540 and lands at 1180", () => {
    expect(LAST_LETTER_START).toBe(540);
    expect(REVEAL_END).toBe(1180);
    expect(stepFor("letters")).toMatchObject({ startMs: 252, endMs: 1180 });
  });
  it("matches the table rows", () => {
    expect(stepFor("intersection")).toMatchObject({ startMs: 100, endMs: 420 });
    expect(stepFor("monogramOut")).toMatchObject({ startMs: 252, endMs: 572 });
    expect(stepFor("rule")).toMatchObject({ startMs: 700, endMs: 1180 });
    expect(stepFor("impression").startMs).toBe(1180);
    expect(stepFor("handoff")).toMatchObject({ startMs: 1180, endMs: 1400 });
    expect(SPLASH_TIMELINE.every((s) => s.endMs > s.startMs)).toBe(true);
  });
  it("hand-off starts at max(probe, 1180) and waits while pending", () => {
    expect(handoffStart(300)).toBe(1180);
    expect(handoffStart(1180)).toBe(1180);
    expect(handoffStart(2000)).toBe(2000);
    expect(handoffStart(null)).toBeNull();
  });
  it("CONNECTING at 2400 ms while pending", () => {
    expect(showConnecting(2399, null)).toBe(false);
    expect(showConnecting(CONNECTING_MS, null)).toBe(true);
    expect(showConnecting(3000, 2500)).toBe(false);
  });
});
