"use client";
import { useRef, useState, type ReactNode } from "react";
import { haptic } from "../haptics";
import { playSound } from "../sounds";
import { IndeterminateRule } from "./Progress";
import { pullDistance, pullPhase, pullRule } from "./pull";

/**
 * §7.29 touch pull past the top of a refreshable list: a 2 px spot rule grows from the centre with the pull, caption
 * PULL TO REPRINT -> RELEASE TO REPRINT at 96 px; on release the rule becomes indeterminate until `onRefresh` settles.
 * Desktop and Downloads: don't use it (register `r` and an overflow Refresh item instead).
 */
export function PullToReprint({ onRefresh, children, className = "" }: { onRefresh: () => Promise<unknown>; children: ReactNode; className?: string }) {
  const [shown, setShown] = useState(0);
  const [busy, setBusy] = useState(false);
  const start = useRef<{ y: number; x: number } | null>(null);
  const armed = useRef(false);
  const phase = pullPhase(shown);
  const atTop = (el: HTMLElement) => (el.closest("[data-pull-scroll]") as HTMLElement | null ?? document.scrollingElement as HTMLElement).scrollTop <= 0;
  const end = () => {
    const fire = armed.current; start.current = null; armed.current = false; setShown(0);
    if (!fire || busy) return;
    haptic("refresh.fire"); setBusy(true);
    onRefresh().finally(() => setBusy(false));
  };
  return (
    <div className={className}
      onPointerDown={(e) => { if (e.pointerType === "mouse" || busy || !atTop(e.currentTarget)) return; start.current = { y: e.clientY, x: e.clientX }; }}
      onPointerMove={(e) => {
        const s = start.current; if (!s) return;
        const dy = e.clientY - s.y;
        if (dy <= 0 || Math.abs(e.clientX - s.x) > dy) { if (dy <= 0) setShown(0); return; }
        const d = pullDistance(dy);
        setShown(d);
        const a = pullPhase(d) === "release";
        if (a && !armed.current) { haptic("refresh.arm"); playSound("refresh.arm"); }
        armed.current = a;
      }}
      onPointerUp={end} onPointerCancel={end}>
      <div aria-live="polite" className="flex flex-col items-center overflow-hidden" style={{ height: busy ? 24 : shown, transition: shown ? "none" : "height var(--mm-dur-line) var(--mm-ease-set)" }}>
        {busy ? <IndeterminateRule label="Reprinting" className="mt-3" /> : shown > 0 ? (
          <>
            <div aria-hidden className="mt-3 h-0.5 bg-spot" style={{ width: `${pullRule(shown) * 100}%` }} />
            <p className="type-kicker mt-2 text-ink-45">{phase === "release" ? "RELEASE TO REPRINT" : "PULL TO REPRINT"}</p>
          </>
        ) : null}
      </div>
      {children}
    </div>
  );
}
