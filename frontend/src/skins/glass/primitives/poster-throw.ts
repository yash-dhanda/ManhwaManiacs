import { project } from "../physics/project";
import { threshold } from "../tokens.generated";

/** Press-and-lift timing (DESIGN 4.6): a tap is a release before 450 ms within the slop; the growth from 150 ms is only a preview. */
export const LIFT = { start: threshold.liftStart, menu: threshold.liftMenu, peak: 1.06, throwV: threshold.throwVelocity, magnet: 64, topFraction: 0.2 } as const;

export type PressPhase = "press" | "lift" | "menu";
export const pressPhase = (elapsedMs: number): PressPhase => (elapsedMs < LIFT.start ? "press" : elapsedMs < LIFT.menu ? "lift" : "menu");
/** 1 until 150 ms, then linearly to 1.06 at 450 ms. */
export const liftScale = (elapsedMs: number) => 1 + (LIFT.peak - 1) * Math.min(1, Math.max(0, (elapsedMs - LIFT.start) / (LIFT.menu - LIFT.start)));
/** A release before 450 ms that never passed the slop is a tap. */
export const isTap = (elapsedMs: number, passedSlop: boolean) => elapsedMs < LIFT.menu && !passedSlop;
/** throw.commit intensity: clamp(0.3 + |v| / 4000, 0.3, 1.0), v in px/s. */
export const throwIntensity = (speed: number) => Math.min(1, Math.max(0.3, 0.3 + Math.abs(speed) / 4000));

export interface Pt { x: number; y: number }
export interface ThrowTarget extends Pt { id: string }
export interface ThrowInput {
  /** the poster's centre at release, viewport coordinates */
  centre: Pt;
  /** release velocity, px/s */
  velocity: Pt;
  viewport: { w: number; h: number };
  targets?: readonly ThrowTarget[];
  /** AI cards: a sideways throw is "Not interested" */
  allowAway?: boolean;
}
export type ThrowDecision =
  | { kind: "open"; velocity: Pt }
  | { kind: "away"; side: "left" | "right" }
  | { kind: "target"; id: string }
  | { kind: "drop" };

/**
 * `open` when the projected centre is above the top 20 % of the screen or vy <= -1,200 px/s; `away` when allowed and the projected
 * centre passes a side edge or |vx| >= 1,200 px/s; `target` when within 64 px of a registered friend-orb target; otherwise `drop`.
 */
export function decideThrow({ centre, velocity, viewport, targets = [], allowAway = false }: ThrowInput): ThrowDecision {
  const px = project(centre.x, velocity.x), py = project(centre.y, velocity.y);
  if (py < viewport.h * LIFT.topFraction || velocity.y <= -LIFT.throwV) return { kind: "open", velocity };
  if (allowAway && (px < 0 || px > viewport.w || Math.abs(velocity.x) >= LIFT.throwV)) return { kind: "away", side: px < viewport.w / 2 ? "left" : "right" };
  let best: ThrowTarget | null = null, bd = Infinity;
  for (const t of targets) { const d = Math.hypot(t.x - centre.x, t.y - centre.y); if (d <= LIFT.magnet && d < bd) { best = t; bd = d; } }
  if (best) return { kind: "target", id: best.id };
  return { kind: "drop" };
}

/** The friend-orb target within magnet range of `centre`, or null (drives magnet.capture / magnet.drop while dragging). */
export function magnetTarget(centre: Pt, targets: readonly ThrowTarget[]): string | null {
  let best: string | null = null, bd = Infinity;
  for (const t of targets) { const d = Math.hypot(t.x - centre.x, t.y - centre.y); if (d <= LIFT.magnet && d < bd) { best = t.id; bd = d; } }
  return best;
}
