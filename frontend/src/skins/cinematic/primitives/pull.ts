import { rubberBand } from "./sheet-physics";

/** §7.29 pull to reprint: the 96 px trigger is measured on the finger's raw pull; the shown stretch is rubber-banded (c = 0.35) over 240 px. */
export const PULL_TRIGGER = 96;
export const PULL_MAX = 240;
export const pullDistance = (rawDy: number): number => rubberBand(rawDy, PULL_MAX);
export type PullPhase = "idle" | "pull" | "release";
export const pullPhase = (raw: number): PullPhase => (raw <= 0 ? "idle" : raw >= PULL_TRIGGER ? "release" : "pull");
/** Fraction of the rule grown from the centre outwards (0..1, reaches 1 at the trigger), from the raw pull. */
export const pullRule = (raw: number): number => Math.min(1, Math.max(0, raw / PULL_TRIGGER));
