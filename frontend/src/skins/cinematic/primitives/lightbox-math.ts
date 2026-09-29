/** Lightbox maths (§7.30), pure. */
export const REST_CAP = 1.5;
export const ZOOM_MIN = 1;
export const ZOOM_MAX = 4;
export const ZOOM_DOUBLE = 2.5;
export const BARRIER_MAX = 0.96;
export const DISMISS_PX = 120;
export const DISMISS_VELOCITY = 800;
export const DRAG_FADE_PX = 400;

/** Size at rest: object-fit contain in the viewport, never larger than 1.5 x the image's natural pixels. */
export function containSize(natW: number, natH: number, vw: number, vh: number, cap = REST_CAP): { w: number; h: number } {
  if (natW <= 0 || natH <= 0) return { w: 0, h: 0 };
  const fit = Math.min(vw / natW, vh / natH);
  const k = Math.min(fit, cap);
  return { w: natW * k, h: natH * k };
}
/** Barrier opacity while dragging down: 0.96 x (1 - dy / 400), clamped to 0..0.96. */
export const barrierOpacity = (dy: number): number => Math.min(BARRIER_MAX, Math.max(0, BARRIER_MAX * (1 - Math.max(0, dy) / DRAG_FADE_PX)));
/** Release past 120 px or faster than 800 px/s dismisses (downwards only). */
export const shouldDismissLightbox = (dy: number, velocityPxPerS: number): boolean => dy > DISMISS_PX || velocityPxPerS > DISMISS_VELOCITY;
export const clampZoom = (z: number): number => Math.min(ZOOM_MAX, Math.max(ZOOM_MIN, z));
/** Double tap / double click: 1x <-> 2.5x. */
export const toggleZoom = (z: number): number => (z > 1.01 ? 1 : ZOOM_DOUBLE);
export const zoomLabel = (z: number): string => `${Math.round(z * 100)}%`;
/** Translate that keeps the point under the pointer fixed when zooming from z0 to z1 (offsets from the image centre). */
export function panForZoom(pointer: { x: number; y: number }, z0: number, z1: number, pan: { x: number; y: number }): { x: number; y: number } {
  const k = z1 / z0;
  return z1 <= 1 ? { x: 0, y: 0 } : { x: pointer.x - (pointer.x - pan.x) * k, y: pointer.y - (pointer.y - pan.y) * k };
}
export const coverFolio = (w: number, h: number) => `COVER · ${w} × ${h}`;
export const pageFolio = (n: number, w: number, h: number) => `PAGE ${n} · ${w} × ${h}`;
