import { lockedUntilMs } from "@/lib/chapter-lock";

/**
 * The clock behind a ticking countdown, kept out of React so the timing rules
 * (one tick a second, stop at zero, fire once, nothing left running) can be
 * tested with fake timers and no DOM.
 *
 * Reads `Date.now()` on every tick rather than counting ticks: a background
 * tab throttles timers, and a count would drift minutes behind the real
 * instant. Returns a disposer that is safe to call any number of times.
 */
export interface CountdownHandlers {
  /** Remaining milliseconds, called now and then once a second until zero. */
  onTick: (remainingMs: number) => void;
  /** The instant has passed. Called exactly once, after the final `onTick(0)`. */
  onUnlocked: () => void;
}

export function startCountdown(
  lockedUntil: string | null | undefined,
  { onTick, onUnlocked }: CountdownHandlers,
): () => void {
  const target = lockedUntilMs(lockedUntil);
  // No readable instant: nothing to count down to, and nothing to announce.
  if (target === null) return () => {};

  let timer: ReturnType<typeof setInterval> | null = null;
  let finished = false;

  const stop = () => {
    if (timer !== null) {
      clearInterval(timer);
      timer = null;
    }
  };

  const tick = () => {
    if (finished) return;
    const remaining = target - Date.now();
    if (remaining > 0) {
      onTick(remaining);
      return;
    }
    finished = true;
    stop();
    onTick(0);
    onUnlocked();
  };

  tick();
  if (!finished) timer = setInterval(tick, 1000);

  return () => {
    finished = true;
    stop();
  };
}
