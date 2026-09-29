"use client";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { startMove } from "@/lib/motion-timings";
import { graphemes } from "../text";
import { typedCount, useCineReduced } from "../motion";

/** §10.2.3: one grapheme per 50 ms on a timestamp clock. Headlines only (<= 60 graphemes). */
export function useTyped(text: string, ms = 50) {
  const chars = useMemo(() => graphemes(text), [text]);
  const reduce = useCineReduced();
  const [n, setN] = useState(0);
  const raf = useRef(0);
  const skipped = useRef(false);
  const rec = useRef<{ end: () => void } | null>(null);
  useEffect(() => {
    if (process.env.NODE_ENV !== "production" && chars.length > 60) console.warn(`TypedHeadline: ${chars.length} graphemes; headlines only, stream longer prose by word`);
  }, [chars]);
  useEffect(() => {
    skipped.current = false;
    if (reduce) return;
    // eslint-disable-next-line react-hooks/set-state-in-effect -- restart the clock when the text changes (§10.2.3)
    setN(0);
    rec.current = startMove("type", ms * chars.length);
    const t0 = performance.now();
    const tick = (t: number) => {
      if (skipped.current) return;
      const k = typedCount(t - t0, chars.length);
      setN(k);
      if (k < chars.length) raf.current = requestAnimationFrame(tick);
      else { rec.current?.end(); rec.current = null; }
    };
    raf.current = requestAnimationFrame(tick);
    return () => { cancelAnimationFrame(raf.current); rec.current?.end(); rec.current = null; };
  }, [chars, ms, reduce]);
  const skip = useCallback(() => {
    skipped.current = true;
    cancelAnimationFrame(raf.current);
    setN(chars.length);
    rec.current?.end(); rec.current = null;
  }, [chars]);
  const count = reduce ? chars.length : n;
  return { shown: chars.slice(0, count).join(""), rest: chars.slice(count).join(""), done: count === chars.length, skip, reduced: reduce };
}

export function TypedHeadline({ text, className, skipRef, as: Tag = "p" }: {
  text: string; className?: string; skipRef?: React.MutableRefObject<(() => void) | null>; as?: "h1" | "h2" | "h3" | "p" | "span";
}) {
  const { shown, rest, done, skip, reduced } = useTyped(text);
  useEffect(() => { if (skipRef) skipRef.current = done ? null : skip; }, [done, skip, skipRef]);
  return (
    <Tag className={className} onClick={skip} tabIndex={done ? -1 : 0}
      onKeyDown={(e) => { if (!done && (e.key === "Enter" || e.key === " ")) { e.preventDefault(); skip(); } }}>
      <span className="sr-only">{text}</span>
      <span aria-hidden data-typed="shown">{shown}</span>
      {!reduced && (
        <span aria-hidden className="relative inline-block w-0 align-baseline">
          <span className={`absolute bottom-[0.06em] left-[0.04em] h-[0.86em] w-[0.12em] bg-spot ${done ? "animate-caret-out" : ""}`} />
        </span>
      )}
      <span aria-hidden style={{ color: "transparent" }}>{rest}</span>
    </Tag>
  );
}
