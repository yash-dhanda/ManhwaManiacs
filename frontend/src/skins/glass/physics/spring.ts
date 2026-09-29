import { physics } from "../tokens.generated";

/** Settle time and bounce to a physical spring (DESIGN 4.3): k = (2pi/d)^2, c = 4pi(1 - bounce)/d, mass 1; d in seconds. */
export function toPhysical(ms: number, bounce: number) {
  const d = ms / 1000;
  return { type: "spring" as const, stiffness: (2 * Math.PI / d) ** 2, damping: (4 * Math.PI * (1 - bounce)) / d, mass: 1 };
}

/** Haptic intensity by navigation depth: 0.30 + 0.08 x depth. */
export const depthIntensity = (depth: number) => physics.depthIntensityBase + physics.depthIntensityStep * depth;
