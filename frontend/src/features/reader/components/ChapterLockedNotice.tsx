"use client";

import { useCallback, useEffect, useRef, useState, type ReactNode } from "react";
import Link from "next/link";
import { Clock } from "lucide-react";
import { ChapterCountdown } from "@/components/ui/chapter-countdown";
import { formatOpensAt, isLocked, type ChapterLock } from "@/lib/chapter-lock";

/**
 * How long to wait after the clock reaches zero before asking again. The
 * source flips the chapter on its own schedule, a few seconds either side of
 * the announced instant; asking at exactly zero would mostly be told "not yet".
 */
export const UNLOCK_GRACE_MS = 4000;

/**
 * Early access, as the reader shows it: a chapter the source lists but has not
 * opened to everyone yet.
 *
 * `lockedAtMount` is decided ONCE. After the countdown ends the reader retries
 * a single time; if the chapter is still closed the error comes back to a fresh
 * mount whose instant is already past, which lands on `fallback` (the server's
 * own sentence and a Try again) instead of starting another countdown that
 * would loop forever against a source that is late.
 */
function useLockedAtMount(lock: ChapterLock | null | undefined): boolean {
  const [locked] = useState(() => isLocked(lock?.lockedUntil, Date.now()));
  return locked;
}

/** One automatic retry, `UNLOCK_GRACE_MS` after the countdown reaches zero. */
function useRetryAfterUnlock(retry: () => void) {
  const retryRef = useRef(retry);
  useEffect(() => {
    retryRef.current = retry;
  }, [retry]);
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const [opening, setOpening] = useState(false);

  useEffect(
    () => () => {
      if (timer.current !== null) clearTimeout(timer.current);
    },
    [],
  );

  const onUnlocked = useCallback(() => {
    if (timer.current !== null) return;
    setOpening(true);
    timer.current = setTimeout(() => retryRef.current(), UNLOCK_GRACE_MS);
  }, []);

  return { opening, onUnlocked };
}

function OpensAtLine({ lockedUntil }: { lockedUntil: string | null }) {
  const [text] = useState(() => formatOpensAt(lockedUntil, Date.now()));
  return text ? <p className="text-sm text-muted">Opens to everyone at {text}.</p> : null;
}

/**
 * The whole-screen state for an entry chapter in early access. Renders
 * `fallback` (the ordinary error view) when the chapter is not locked as far as
 * the clock can tell — no instant, or one that has passed.
 */
export function ChapterLockedNotice({
  lock,
  retry,
  seriesHref,
  fallback,
}: {
  lock: ChapterLock | null | undefined;
  retry: () => void;
  seriesHref: string;
  fallback: ReactNode;
}) {
  const lockedAtMount = useLockedAtMount(lock);
  const { opening, onUnlocked } = useRetryAfterUnlock(retry);
  if (!lock || !lockedAtMount) return <>{fallback}</>;

  return (
    <div
      className="flex min-h-[60vh] flex-col items-center justify-center gap-3 bg-bg p-6 text-center"
      role="status"
    >
      <span className="inline-flex items-center gap-1.5 text-[11px] font-semibold uppercase tracking-widest text-muted">
        <Clock className="size-3.5" aria-hidden />
        Early access
      </span>
      <p className="text-2xl font-semibold text-fg">
        <ChapterCountdown lockedUntil={lock.lockedUntil} onUnlocked={onUnlocked} />
      </p>
      <OpensAtLine lockedUntil={lock.lockedUntil} />
      {opening ? <p className="text-sm text-muted">Opening it now…</p> : null}
      <Link
        href={seriesHref}
        className="inline-flex h-10 items-center justify-center rounded-lg border border-border/60 px-4 text-sm font-medium text-fg transition-colors hover:bg-white/5"
      >
        Go to series
      </Link>
    </div>
  );
}

/**
 * The end-of-strip message when the NEXT chapter is in early access. Renders
 * `fallback` (the ordinary failure card) when it is not locked as far as the
 * clock can tell.
 */
export function ChapterLockedTail({
  lock,
  label,
  retry,
  fallback,
}: {
  lock: ChapterLock | null | undefined;
  label: string | null;
  retry: () => void;
  fallback: ReactNode;
}) {
  const lockedAtMount = useLockedAtMount(lock);
  const { onUnlocked } = useRetryAfterUnlock(retry);
  if (!lock || !lockedAtMount) return <>{fallback}</>;

  return (
    <div className="mx-auto flex w-full max-w-3xl justify-center px-4 pb-10 pt-4">
      <div
        className="glass-card reader-end-card-enter flex w-full max-w-md flex-col items-center gap-2 rounded-2xl px-6 py-5 text-center shadow-glass"
        role="status"
      >
        <span className="text-[11px] font-semibold uppercase tracking-widest text-muted">
          {label ? `${label} · Early access` : "Early access"}
        </span>
        <span className="text-lg font-semibold text-fg">
          <ChapterCountdown lockedUntil={lock.lockedUntil} onUnlocked={onUnlocked} />
        </span>
        <OpensAtLine lockedUntil={lock.lockedUntil} />
      </div>
    </div>
  );
}
