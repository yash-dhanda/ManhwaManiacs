"use client";
import { useEffect, useRef, useState } from "react";
import { startMove } from "@/lib/motion-timings";
import { durMs } from "../tokens.generated";

/** §4.5 Folio flip: the number rolls digit by digit (80 ms each, 40 ms apart). Visual layer aria-hidden; one accessible value. */
export function FolioFlip({ value, label, className = "" }: { value: number | string; label?: string; className?: string }) {
  const text = String(value);
  const prev = useRef(text);
  const [old, setOld] = useState<string | null>(null);
  useEffect(() => {
    if (prev.current === text) return;
    const from = prev.current;
    prev.current = text;
    const rec = startMove("folioFlip", durMs.tick + 40 * text.length);
    setOld(from); // eslint-disable-line react-hooks/set-state-in-effect -- roll trigger
    const t = setTimeout(() => { setOld(null); rec.end(); }, durMs.tick + 40 * text.length);
    return () => clearTimeout(t);
  }, [text]);
  const pad = old ? Math.max(text.length, old.length) : text.length;
  const cur = text.padStart(pad, " ");
  const was = old?.padStart(pad, " ");
  return (
    <span className={`type-folio-lg inline-flex tabular-nums ${className}`}>
      <span className="sr-only">{label ?? text}</span>
      <span aria-hidden aria-live="off" className="inline-flex">
        {cur.split("").map((ch, i) => {
          const changed = was !== undefined && was[i] !== ch;
          return (
            <span key={`${i}-${changed ? ch : "s"}`} className="relative inline-block overflow-hidden" style={{ ["--i" as string]: i }}>
              {changed ? <span className="cine-flip-out absolute inset-0">{was![i] === " " ? " " : was![i]}</span> : null}
              <span className={changed ? "cine-flip-in inline-block" : "inline-block"}>{ch === " " ? " " : ch}</span>
            </span>
          );
        })}
      </span>
    </span>
  );
}
