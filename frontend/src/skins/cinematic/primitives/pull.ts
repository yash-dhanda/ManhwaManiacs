import { rubberBand } from "./sheet-physics";

/** §7.29 pull to reprint: the 96 px trigger and a rubber band (c = 0.35) over a 240 px stretch. */
export const PULL_TRIGGER = 96;
export const PULL_MAX = 240;
export const pullDistance = (rawDy: number): number => rubberBand(rawDy, PULL_MAX);
export type PullPhase = "idle" | "pull" | "release";
export const pullPhase = (shown: number): PullPhase => (shown <= 0 ? "idle" : shown >= PULL_TRIGGER ? "release" : "pull");
/** Fraction of the rule that has grown from the centre outwards (0..1, reaches 1 at the trigger). */
export const pullRule = (shown: number): number => Math.min(1, Math.max(0, shown / PULL_TRIGGER));
