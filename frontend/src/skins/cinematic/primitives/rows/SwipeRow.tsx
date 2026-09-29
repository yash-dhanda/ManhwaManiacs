"use client";
import { useDrag } from "@use-gesture/react";
import { animate } from "motion/react";
import { useRef, useState, type ReactNode } from "react";
import { haptic } from "../../haptics";
import { spring } from "../../tokens.generated";
import { useCoarsePointer } from "../overlay-hooks";

const SLAB = 72;
/** §7.16 swipe actions (coarse pointers only): a flat 72 px slab under the row; release past 50 % of the row commits on spring.release. */
export function SwipeRow({ children, action, label, onCommit, className = "" }: { children: ReactNode; action: "mark-read" | "remove"; label?: string; onCommit: () => void; className?: string }) {
  const coarse = useCoarsePointer();
  const ref = useRef<HTMLDivElement>(null);
  const [dim, setDim] = useState(false);
  const x = useRef(0);
  const move = (to: number, done?: () => void) => { const el = ref.current; if (!el) return; animate(x.current, to, { ...spring.release, onUpdate: (v) => { x.current = v; el.style.transform = `translateX(${v}px)`; }, onComplete: done }); };
  const bind = useDrag(({ movement: [mx], last, first, memo = 0 }) => {
    const el = ref.current; if (!el) return memo;
    const dx = Math.min(0, mx);
    if (!last) { x.current = dx; el.style.transform = `translateX(${dx}px)`; return memo; }
    if (first) return memo;
    if (-dx > el.offsetWidth / 2) {
      haptic(action === "remove" ? "delete.confirm" : "select");
      if (action === "remove") move(-el.offsetWidth, onCommit);
      else { onCommit(); setDim(true); move(0); }
    } else move(0);
    return memo;
  }, { axis: "x", filterTaps: true, pointer: { touch: true } });
  if (!coarse) return <div className={className}>{children}</div>;
  const slab = action === "remove" ? "bg-proof" : "bg-ink-100";
  return (
    <div className={`relative overflow-hidden ${className}`}>
      <div aria-hidden className={`absolute inset-y-0 right-0 flex items-center justify-center text-paper-0 ${slab}`} style={{ width: SLAB }}><span className="type-label">{label ?? (action === "remove" ? "Remove" : "Mark read")}</span></div>
      <div ref={ref} {...bind()} style={{ touchAction: "pan-y", opacity: dim ? 0.55 : 1 }} className="relative bg-paper-1">{children}</div>
    </div>
  );
}
