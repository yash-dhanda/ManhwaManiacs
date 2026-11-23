"use client";

import { useEffect, useRef, useState } from "react";
import { formatCountdown, formatCountdownWords } from "@/lib/chapter-lock";
import { startCountdown } from "@/lib/countdown";

interface ChapterCountdownProps {
  /** ISO-8601 UTC instant the chapter opens. */
  lockedUntil: string | null | undefined;
  /** Called once when the clock reaches zero. */
  onUnlocked?: () => void;
  /** Words before the time; the readout is `Opens in 3:27:14`. */
  prefix?: string;
  className?: string;
}

/**
 * A ticking `Opens in 3:27:14` for a chapter that is in early access.
 *
 * Renders nothing that depends on the clock until it has mounted: the server
 * (and the first client paint, which must match it) draws a fixed-width
 * placeholder, and the real remaining time starts in an effect. Without that,
 * the HTML rendered on the server would disagree with the browser's by however
 * long the page took to arrive.
 *
 * The visible digits are hidden from assistive tech and the label carries the
 * same time in words. `role="timer"` is deliberately not a live region, so the
 * once-a-second change is read when the user looks at it, not announced every
 * second over whatever they are listening to.
 */
export function ChapterCountdown({
  lockedUntil,
  onUnlocked,
  prefix = "Opens in",
  className,
}: ChapterCountdownProps) {
  const [remainingMs, setRemainingMs] = useState<number | null>(null);
  const onUnlockedRef = useRef(onUnlocked);
  useEffect(() => {
    onUnlockedRef.current = onUnlocked;
  }, [onUnlocked]);

  useEffect(() => {
    return startCountdown(lockedUntil, {
      onTick: setRemainingMs,
      onUnlocked: () => onUnlockedRef.current?.(),
    });
  }, [lockedUntil]);

  if (remainingMs === null) {
    return (
      <span className={className} data-countdown="pending">
        {prefix} <span aria-hidden>–:––</span>
      </span>
    );
  }

  return (
    <span
      className={className}
      role="timer"
      aria-label={`${prefix} ${formatCountdownWords(remainingMs)}`}
      data-countdown="running"
    >
      <span aria-hidden>
        {prefix} <span className="tabular-nums">{formatCountdown(remainingMs)}</span>
      </span>
    </span>
  );
}
