"use client";

import { useEffect, useRef, useState } from "react";
import { LeaderDial, kit as s } from "./Kit";
import { prefersReducedMotion } from "./motion";

const TRIGGER = 72;

/** Pull to reprint (phones): drag down from the top of the page past 72 px to refetch. */
export function usePullToReprint(onRefresh: () => Promise<unknown> | unknown) {
  const [pull, setPull] = useState(0);
  const [busy, setBusy] = useState(false);
  const cb = useRef(onRefresh);
  useEffect(() => { cb.current = onRefresh; });
  useEffect(() => {
    let y0: number | null = null;
    let cur = 0;
    const top = () => (document.scrollingElement?.scrollTop ?? 0) <= 0;
    const start = (e: TouchEvent) => { y0 = top() ? e.touches[0].clientY : null; cur = 0; };
    const move = (e: TouchEvent) => {
      if (y0 === null) return;
      cur = Math.max(0, Math.min(TRIGGER * 1.5, (e.touches[0].clientY - y0) * 0.5));
      setPull(cur);
    };
    const end = () => {
      if (y0 === null) return;
      const fire = cur >= TRIGGER;
      y0 = null; cur = 0; setPull(0);
      if (fire) { setBusy(true); Promise.resolve(cb.current()).finally(() => setBusy(false)); }
    };
    window.addEventListener("touchstart", start, { passive: true });
    window.addEventListener("touchmove", move, { passive: true });
    window.addEventListener("touchend", end);
    window.addEventListener("touchcancel", end);
    return () => {
      window.removeEventListener("touchstart", start);
      window.removeEventListener("touchmove", move);
      window.removeEventListener("touchend", end);
      window.removeEventListener("touchcancel", end);
    };
  }, []);
  return { pull, busy };
}

export function PullMark({ pull, busy }: { pull: number; busy: boolean }) {
  if (!busy && pull <= 0) return null;
  const ready = pull >= TRIGGER;
  return (
    <div className={s.pullMark} style={{ height: busy ? 40 : pull, transition: prefersReducedMotion() || !busy ? "none" : undefined }} role="status" aria-live="polite">
      {busy ? <><LeaderDial /> Reprinting…</> : ready ? "Release to reprint" : "Pull to reprint"}
    </div>
  );
}
