import { isGlassReduced, play } from "../motion";
import { haptic } from "../haptics";

/** x(t) = A * e^(-t / 90 ms) * sin(2 pi * 7 Hz * t), t in ms, 420 ms (DESIGN 4.10 Error shake). */
export const shakeX = (tMs: number, amp = 8) => amp * Math.exp(-tMs / 90) * Math.sin(2 * Math.PI * 7 * (tMs / 1000));

/** Fires the `error` haptic and shakes `el` (6 for fields, 8 otherwise). Nothing moves under reduced motion. */
export function shake(el: HTMLElement | null, amp = 8): void {
  haptic("error");
  if (!el || isGlassReduced()) return;
  play("errorShake", 0, 1, { onUpdate: (p) => { el.style.translate = `${shakeX(p * 420, amp).toFixed(2)}px 0`; }, onComplete: () => { el.style.translate = ""; } });
}
