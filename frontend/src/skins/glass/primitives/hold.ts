import { threshold } from "../tokens.generated";

/**
 * The hold-to-confirm state machine (DESIGN 4.6, 7.1, 14.8), pure and clock-driven: feed it `down`, `move`, `tick`, `up`
 * and `cancel` with timestamps in ms. Nothing starts for 200 ms; a release before that with under 8 px of movement is a
 * click; 8 px or more before 200 ms (or a pointercancel) cancels; from 200 ms the fill rises over 1,000 ms (1,200 ms in all)
 * with a `hold.ramp` transient every 150 ms rising 0.2 to 0.8; a release after 200 ms and before completion aborts.
 */
export const HOLD = { start: threshold.holdStart, slop: threshold.holdClickSlop, total: threshold.holdConfirm, ramp: 150, reducedStep: 250 } as const;
export const FILL_MS = HOLD.total - HOLD.start;

export type HoldPhase = "idle" | "pending" | "filling" | "cancelled" | "aborted" | "done" | "clicked";
export interface HoldState { phase: HoldPhase; start: number; level: number; ramps: number }
export type HoldEvent =
  | { type: "down"; t: number }
  | { type: "move"; t: number; dist: number }
  | { type: "tick"; t: number }
  | { type: "up"; t: number; dist?: number }
  | { type: "cancel" };
export type HoldEffect = { type: "click" } | { type: "ramp"; intensity: number } | { type: "done" } | { type: "abort" } | { type: "cancel" };

export const initialHold: HoldState = { phase: "idle", start: 0, level: 0, ramps: 0 };

/** The fill level 0..1 at elapsed ms since the fill began; reduced motion steps it in four 25 % increments 250 ms apart. */
export const fillLevel = (elapsed: number, reduced = false) => {
  const l = Math.min(1, Math.max(0, elapsed / FILL_MS));
  return reduced ? (l >= 1 ? 1 : Math.floor(elapsed / HOLD.reducedStep) * 0.25) : l;
};
export const rampIntensity = (level: number) => 0.2 + 0.6 * Math.min(1, Math.max(0, level));

export function holdStep(s: HoldState, e: HoldEvent, reduced = false): { state: HoldState; effects: HoldEffect[] } {
  const none = { state: s, effects: [] as HoldEffect[] };
  switch (e.type) {
    case "down": return { state: { phase: "pending", start: e.t, level: 0, ramps: 0 }, effects: [] };
    case "cancel":
      return s.phase === "pending" || s.phase === "filling" ? { state: { ...initialHold, phase: "cancelled" }, effects: [{ type: "cancel" }] } : none;
    case "move":
      if (s.phase === "pending" && e.dist >= HOLD.slop && e.t - s.start < HOLD.start) return { state: { ...initialHold, phase: "cancelled" }, effects: [{ type: "cancel" }] };
      return none;
    case "tick": {
      if (s.phase !== "pending" && s.phase !== "filling") return none;
      const elapsed = e.t - s.start - HOLD.start;
      if (elapsed < 0) return none;
      const level = fillLevel(elapsed, reduced);
      const due = Math.floor(elapsed / HOLD.ramp) + 1; // one at the fill's start, then every 150 ms
      const effects: HoldEffect[] = [];
      let ramps = s.ramps;
      while (ramps < due && elapsed < FILL_MS) { effects.push({ type: "ramp", intensity: rampIntensity(elapsed / FILL_MS) }); ramps++; }
      if (elapsed >= FILL_MS) { effects.push({ type: "done" }); return { state: { ...s, phase: "done", level: 1, ramps }, effects }; }
      return { state: { ...s, phase: "filling", level, ramps }, effects };
    }
    case "up": {
      if (s.phase === "pending") {
        if (e.t - s.start >= HOLD.start) return { state: { ...s, phase: "aborted" }, effects: [{ type: "abort" }] };
        if ((e.dist ?? 0) < HOLD.slop) return { state: { ...s, phase: "clicked" }, effects: [{ type: "click" }] };
        return { state: { ...initialHold, phase: "cancelled" }, effects: [{ type: "cancel" }] };
      }
      if (s.phase === "filling") return { state: { ...s, phase: "aborted" }, effects: [{ type: "abort" }] };
      return none;
    }
  }
}
