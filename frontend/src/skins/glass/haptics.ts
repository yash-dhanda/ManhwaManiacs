import { readHapticsEnabled, webHapticsAvailable } from "@/features/preferences/feedback";
import type { HapticEvent } from "../contract.generated";
import { hapticsWeb } from "./tokens.generated";

const WINDOW_MS = 120;
let lastAt = -Infinity;
let lastTotal = 0;

const total = (p: readonly number[]) => p.reduce((a, b) => a + b, 0);

/**
 * Web vibration for Glass's seven events (glass §5.2). A call within 120 ms of
 * the previous vibration is dropped unless its pattern is longer, in which case
 * it replaces it, so a burst keeps the strongest.
 */
export function haptic(event: HapticEvent): void {
  // Development only: browser checks count events whether or not they map to navigator.vibrate.
  if (process.env.NODE_ENV !== "production" && typeof window !== "undefined") window.dispatchEvent(new CustomEvent("mm:haptic", { detail: event }));
  const pattern = (hapticsWeb as Partial<Record<HapticEvent, readonly number[]>>)[event];
  if (!pattern || !webHapticsAvailable() || !readHapticsEnabled()) return;
  const now = performance.now();
  const t = total(pattern);
  if (now - lastAt < WINDOW_MS && t <= lastTotal) return;
  lastAt = now;
  lastTotal = t;
  navigator.vibrate([...pattern]);
}
