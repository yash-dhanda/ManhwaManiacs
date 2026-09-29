import { rubberband } from "../physics/rubberband";

/** Pull to refresh (glass 7.33). Raw px is the finger's travel; the displayed pull is rubber-banded. */
export const TRIGGER_PX = 100;
export const REST_LINE = 60;
export const RADIUS_FULL_AT = 60;
export const RADIUS_MAX = 16;
export const NECK_MAX = 12;

/** The displayed pull for a raw pull: rubberband(raw, viewportHeight, 0.55). */
export const displayedPull = (raw: number, vh: number) => rubberband(Math.max(0, raw), vh, 0.55);

/** The droplet radius grows 0 to 16 px over the first 60 raw px. */
export const dropletRadius = (raw: number) => RADIUS_MAX * Math.min(1, Math.max(0, raw) / RADIUS_FULL_AT);

/** Progress toward the trigger, 0 to 1. */
export const pullProgress = (raw: number) => Math.min(1, Math.max(0, raw) / TRIGGER_PX);

/** The neck width, 12 x (1 - progress) px, thinning as the pull continues. */
export const neckWidth = (raw: number) => NECK_MAX * (1 - pullProgress(raw));

/** The droplet glyph turns 360 degrees per 100 raw px. */
export const glyphRotation = (raw: number) => (Math.max(0, raw) / TRIGGER_PX) * 360;

/** The neck snaps at exactly 100 raw px. */
export const armed = (raw: number) => raw >= TRIGGER_PX;
