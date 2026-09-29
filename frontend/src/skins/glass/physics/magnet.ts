import { physics } from "../tokens.generated";

export interface MagnetStep {
  pos: number;
  /** the target now holding the position, or null */
  target: number | null;
  capture: boolean;
  release: boolean;
}

/** Pulls `pull` of the remaining distance per frame toward a target within `radius` px (DESIGN 4.6). Callers fire magnet.capture / magnet.drop. */
export function createMagnet(targets: readonly number[], radius: number = physics.magnetRadius, pull: number = physics.magnetPull) {
  let held: number | null = null;
  return {
    step(pos: number): MagnetStep {
      let best: number | null = null;
      for (const t of targets) if (Math.abs(t - pos) < radius && (best === null || Math.abs(t - pos) < Math.abs(best - pos))) best = t;
      const capture = best !== null && held === null;
      const release = best === null && held !== null;
      held = best;
      return { pos: best === null ? pos : pos + (best - pos) * pull, target: best, capture, release };
    },
  };
}
