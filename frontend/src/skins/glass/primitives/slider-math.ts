import { rubberband } from "../physics/rubberband";

/** Slider, scrub rail and speed dial maths (glass 7.21, 8.14.2, 8.16.3). */
export const MAGNET_FRACTION = 0.3;
export const RUBBER_PX = 12;

export const clamp = (v: number, lo: number, hi: number) => Math.min(hi, Math.max(lo, v));

/** Snap to the step grid; returns the snapped value and whether the magnet (within 30 % of the step spacing, in value units) caught it. */
export function snapToStep(value: number, min: number, max: number, step: number): { value: number; magnet: boolean; index: number } {
  const v = clamp(value, min, max);
  const idx = Math.round((v - min) / step);
  const snapped = clamp(min + idx * step, min, max);
  return { value: snapped, magnet: Math.abs(v - snapped) <= MAGNET_FRACTION * step, index: idx };
}

/**
 * Stepped drag: within 30 % of the step spacing the thumb is pulled fully to the step; between steps it follows the finger.
 * Returns the display value (for the thumb position) and the committed step value.
 */
export function steppedThumb(value: number, min: number, max: number, step: number): { display: number; value: number; step: number } {
  const s = snapToStep(value, min, max, step);
  return { display: s.magnet ? s.value : clamp(value, min, max), value: s.value, step: s.index };
}

/** Past min or max the thumb rubber-bands at most 12 px, with `d` the track length. `over` is the raw px past the end. */
export const overshoot = (over: number, trackLength: number) => Math.min(RUBBER_PX, rubberband(Math.max(0, over), trackLength, 0.55));

/** Pixel offset along the track for a value. */
export const valueToPx = (v: number, min: number, max: number, length: number) => (max === min ? 0 : ((v - min) / (max - min)) * length);
export const pxToValue = (px: number, min: number, max: number, length: number) => (length <= 0 ? min : min + (px / length) * (max - min));

/* ---- speed dial ---- */
export const DIAL_MIN = 0.5;
export const DIAL_MAX = 3;
export const DIAL_STEP = 0.05;
export const DIAL_PX_PER_STEP = 6;
export const DIAL_MAGNET = 0.08;
export const DIAL_TICK_EVERY = 0.25;
export const DIAL_PRESETS = [0.8, 1, 1.25, 1.5, 2] as const;

const round2 = (v: number) => Math.round(v * 100) / 100;

/** Dragging up raises the speed: 6 px per 0.05, from the value at touch-down. `dy` is positive downward. */
export function dialValueFromDrag(start: number, dy: number): number {
  const raw = start - (dy / DIAL_PX_PER_STEP) * DIAL_STEP;
  return round2(clamp(Math.round(raw / DIAL_STEP) * DIAL_STEP, DIAL_MIN, DIAL_MAX));
}

/** Raw (unclamped) value for the rubber band past the ends. */
export const dialRawFromDrag = (start: number, dy: number) => start - (dy / DIAL_PX_PER_STEP) * DIAL_STEP;

/** Values within +-0.08 of 1.0x are pulled to 1.0. */
export const dialMagnet = (v: number): { value: number; magnet: boolean } => (Math.abs(v - 1) <= DIAL_MAGNET + 1e-9 ? { value: 1, magnet: true } : { value: v, magnet: false });

/** A `detent.tick` every 0.25x: true when moving from `a` to `b` crossed a multiple of 0.25. */
export const dialTicked = (a: number, b: number) => Math.floor(round2(a) / DIAL_TICK_EVERY + 1e-9) !== Math.floor(round2(b) / DIAL_TICK_EVERY + 1e-9);

/** Keyboard: arrows 0.05, Page Up/Down 0.25, Home/End the ends. */
export function dialKey(v: number, key: string): number | null {
  switch (key) {
    case "ArrowUp": case "ArrowRight": return round2(clamp(v + DIAL_STEP, DIAL_MIN, DIAL_MAX));
    case "ArrowDown": case "ArrowLeft": return round2(clamp(v - DIAL_STEP, DIAL_MIN, DIAL_MAX));
    case "PageUp": return round2(clamp(v + 0.25, DIAL_MIN, DIAL_MAX));
    case "PageDown": return round2(clamp(v - 0.25, DIAL_MIN, DIAL_MAX));
    case "Home": return DIAL_MIN;
    case "End": return DIAL_MAX;
    default: return null;
  }
}

/** Slider keyboard: arrows one step, Page Up/Down ten steps, Home/End the ends. */
export function sliderKey(v: number, key: string, min: number, max: number, step: number): number | null {
  const at = (n: number) => clamp(Math.round((v + n * step - min) / step) * step + min, min, max);
  switch (key) {
    case "ArrowUp": case "ArrowRight": return at(1);
    case "ArrowDown": case "ArrowLeft": return at(-1);
    case "PageUp": return at(10);
    case "PageDown": return at(-10);
    case "Home": return min;
    case "End": return max;
    default: return null;
  }
}

/** Scrub rail: project to the nearest page. `frac` 0 to 1 along the rail. */
export const pageAt = (frac: number, pages: number) => (pages <= 1 ? 1 : clamp(Math.round(frac * (pages - 1)) + 1, 1, pages));
