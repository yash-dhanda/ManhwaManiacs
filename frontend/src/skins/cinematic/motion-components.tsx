"use client";
import { useEffect, useRef, useState, type CSSProperties, type ReactNode } from "react";
import { useCineReduced } from "./motion";
import { play } from "./motion";

/** Pauses a CSS animation while the element is off screen (§15.6). */
export function useOffscreenPause<T extends HTMLElement>() {
  const ref = useRef<T>(null);
  useEffect(() => {
    const el = ref.current;
    if (!el || typeof IntersectionObserver === "undefined") return;
    const io = new IntersectionObserver(([e]) => { el.dataset.offscreen = e.isIntersecting ? "false" : "true"; });
    io.observe(el);
    return () => io.disconnect();
  }, []);
  return ref;
}

/** Applies animate-drift to its child wrapper and pauses it off screen. */
export function Drift({ children, className = "" }: { children: ReactNode; className?: string }) {
  const ref = useOffscreenPause<HTMLDivElement>();
  return <div ref={ref} className={`animate-drift ${className}`}>{children}</div>;
}

/** Applies animate-flicker with the reading-order phase (+60 ms per item). */
export function Flicker({ index = 0, children, className = "" }: { index?: number; children?: ReactNode; className?: string }) {
  return <div className={`animate-flicker ${className}`} style={{ animationDelay: `${index * 60}ms`, ["--i" as string]: index } as CSSProperties}>{children}</div>;
}

/** Rack focus / Develop wrapper CineImage uses: runs once on first decode, skipped when already decoded at mount. */
export function RackImage({ children, ready, alreadyDecoded = false, className = "" }: { children: ReactNode; ready: boolean; alreadyDecoded?: boolean; className?: string }) {
  const ref = useRef<HTMLDivElement>(null);
  const reduced = useCineReduced();
  const ran = useRef(false);
  useEffect(() => {
    if (!ready || ran.current || alreadyDecoded || !ref.current) return;
    ran.current = true;
    if (reduced) { play("dissolve", ref.current); return; }
    play("rackFocus", ref.current);
  }, [ready, alreadyDecoded, reduced]);
  return <div ref={ref} className={className} style={{ opacity: ready || alreadyDecoded ? undefined : 0 }}>{children}</div>;
}

/** A rule (hairline, heavy or Oxford) that draws with Rule draw on entrance (reduced motion: present at rest). */
export function RuleDraw({ kind = "hairline", delayMs = 0, className = "", spotLead = false }: { kind?: "hairline" | "heavy" | "oxford"; delayMs?: number; className?: string; spotLead?: boolean }) {
  const ref = useRef<HTMLDivElement>(null);
  const reduced = useCineReduced();
  const [drawn, setDrawn] = useState(false);
  useEffect(() => {
    const el = ref.current;
    if (!el || reduced || drawn) return;
    el.style.transformOrigin = "left";
    play("ruleDraw", el, { delayMs, onComplete: () => setDrawn(true) });
  }, [reduced, delayMs, drawn]);
  // The Press start lockup (§12.4): the first 12 % of the heavy line is spot.
  const lead = spotLead ? { background: "linear-gradient(to right, var(--mm-color-spot) 12%, var(--mm-color-ink-100) 12%)" } : undefined;
  const shape = kind === "hairline" ? "h-px bg-rule-1" : kind === "heavy" ? "h-[3px] bg-ink-100" : "flex flex-col gap-[2px]";
  return (
    <div ref={ref} aria-hidden className={`cine-rule ${shape} ${className}`} style={{ ...(kind === "heavy" ? lead : null), ...(reduced || drawn ? null : { transform: "scaleX(0)" }) }}>
      {kind === "oxford" && (<><span className="block h-[3px] bg-ink-100" style={lead} /><span className="block h-px bg-ink-100" /></>)}
    </div>
  );
}
