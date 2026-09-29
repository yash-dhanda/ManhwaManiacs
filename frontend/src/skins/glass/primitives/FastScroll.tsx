"use client";

import { useRef, useState, type RefObject } from "react";
import { GlassSurface } from "../glass/GlassSurface";
import { haptic } from "../haptics";
import { FAST_SCROLL_MIN_ROWS, indexAt, tickBetween } from "./scroll-edge-math";

/** Lists over 200 rows: a 44 px drag strip on the trailing edge; the bubble shows the chapter number or first letter from `labelAt`, a `select` tick per 10 rows. */
export function FastScroll({ count, scroller, labelAt, controls, "data-testid": tid }: { count: number; scroller: RefObject<HTMLElement | null>; labelAt: (index: number) => string; controls: string; "data-testid"?: string }) {
  const strip = useRef<HTMLDivElement | null>(null);
  const [idx, setIdx] = useState(0);
  const [drag, setDrag] = useState(false);
  const [frac, setFrac] = useState(0);
  const id = useRef(-1);
  if (count <= FAST_SCROLL_MIN_ROWS) return null;
  const go = (clientY: number) => {
    const r = strip.current!.getBoundingClientRect();
    const f = Math.min(1, Math.max(0, (clientY - r.top) / r.height));
    const i = indexAt(f, count);
    if (tickBetween(idx, i)) haptic("select");
    setFrac(f); setIdx(i);
    const s = scroller.current;
    if (s) s.scrollTop = f * (s.scrollHeight - s.clientHeight);
  };
  return (
    <div
      ref={strip}
      role="scrollbar"
      aria-controls={controls}
      aria-orientation="vertical"
      aria-valuemin={0}
      aria-valuemax={count - 1}
      aria-valuenow={idx}
      tabIndex={0}
      className="g-fastscroll"
      data-dragging={drag ? "" : undefined}
      data-testid={tid}
      onPointerDown={(e) => { id.current = e.pointerId; try { e.currentTarget.setPointerCapture(e.pointerId); } catch { /* synthetic */ } setDrag(true); go(e.clientY); }}
      onPointerMove={(e) => { if (drag && e.pointerId === id.current) go(e.clientY); }}
      onPointerUp={() => setDrag(false)}
      onPointerCancel={() => setDrag(false)}
      onKeyDown={(e) => {
        const s = scroller.current;
        if (!s) return;
        if (e.key === "ArrowDown") s.scrollTop += 80; else if (e.key === "ArrowUp") s.scrollTop -= 80;
        else if (e.key === "Home") s.scrollTop = 0; else if (e.key === "End") s.scrollTop = s.scrollHeight;
        else return;
        e.preventDefault();
      }}
    >
      <span className="g-fastscroll__thumb" style={{ top: `${frac * 100}%` }} />
      {drag ? (
        <span className="g-fastscroll__bubble" style={{ top: `${frac * 100}%` }}>
          <GlassSurface tier="t2" capsule layer="hud" materialize={false} className="g-fastscroll__glass"><span className="g-fastscroll__label">{labelAt(idx)}</span></GlassSurface>
        </span>
      ) : null}
    </div>
  );
}
