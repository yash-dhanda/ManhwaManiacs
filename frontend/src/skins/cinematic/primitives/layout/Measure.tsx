"use client";
import { useLayoutEffect, useRef, type ReactNode } from "react";

const CH = { deck: 62, synopsis: 62, recap: 58, notice: 48 } as const;

/** Caps a text block in `ch`; a display block's rendered height rounds up to the next 4 px multiple through a ResizeObserver (baseline grid). */
export function Measure({ kind = "deck", display = false, children, className = "" }: { kind?: keyof typeof CH; display?: boolean; children: ReactNode; className?: string }) {
  const ref = useRef<HTMLDivElement>(null);
  useLayoutEffect(() => {
    const el = ref.current;
    if (!el || !display) return;
    const snap = () => {
      el.style.marginBottom = "0px";
      const h = el.getBoundingClientRect().height;
      el.style.marginBottom = `${Math.ceil(h / 4) * 4 - h}px`;
    };
    snap();
    const ro = new ResizeObserver(snap);
    ro.observe(el);
    return () => ro.disconnect();
  }, [display]);
  return <div ref={ref} className={className} style={{ maxWidth: `${CH[kind]}ch` }}>{children}</div>;
}
