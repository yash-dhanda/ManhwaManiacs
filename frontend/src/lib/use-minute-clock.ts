"use client";

import { useEffect, useState } from "react";

/**
 * The current time, refreshed twice a minute, or `null` until mounted.
 *
 * For text that is accurate to the minute (`Opens in 3 h 27 min` on a chapter
 * row) — a per-second ticker across hundreds of rows would re-render the whole
 * list for nothing. `null` on the server and first client paint keeps both
 * identical; the rows fill in from the effect.
 */
export function useMinuteClock(): number | null {
  const [now, setNow] = useState<number | null>(null);
  useEffect(() => {
    const update = () => setNow(Date.now());
    update();
    const timer = setInterval(update, 30_000);
    return () => clearInterval(timer);
  }, []);
  return now;
}
