"use client";

import { useEffect, useRef, useState, type CSSProperties, type ElementType } from "react";

const seg = typeof Intl !== "undefined" && "Segmenter" in Intl ? new Intl.Segmenter(undefined, { granularity: "grapheme" }) : null;
const graphemes = (s: string): string[] => (seg ? Array.from(seg.segment(s), (x) => x.segment) : Array.from(s));
export const CAP = 48;
export const TYPED_KEY = "mm.glass.typed";
export const STEP_MS = 50;
const reduced = () => matchMedia("(prefers-reduced-motion: reduce)").matches || document.documentElement.dataset.motion === "reduced";
const readSeen = (): string[] => { try { return JSON.parse(sessionStorage.getItem(TYPED_KEY) ?? "[]"); } catch { return []; } };
const record = (k: string) => { try { sessionStorage.setItem(TYPED_KEY, JSON.stringify([...new Set([...readSeen(), k])])); } catch { /* private mode */ } };

/**
 * One grapheme every 50 ms, the caret of light on `track` (10.2). The full string is laid out from frame 0 (untyped tail transparent).
 * Skips on a pointerdown on the headline or a key press while focus is on the headline or document.body; focus ARRIVING on it never skips.
 * `typedKey` is "{profileId}:{placement}"; recorded when typing starts.
 */
export function TypedHeadline({ text, typedKey, as: Tag = "h1", className, "data-testid": tid }: { text: string; typedKey: string; as?: ElementType; className?: string; "data-testid"?: string }) {
  const all = graphemes(text);
  const g = all.slice(0, CAP), tail = all.slice(CAP).join("");
  const [done, setDone] = useState(false);
  const ref = useRef<HTMLElement>(null);
  const caretRef = useRef<HTMLSpanElement>(null);
  const startedFor = useRef<string | null>(null); // survives StrictMode's replayed effect, so dev does not mistake its own record for a previous visit
  useEffect(() => {
    const el = ref.current, caret = caretRef.current;
    if (!el || !caret) return;
    const id0 = `${typedKey}\n${text}`;
    if (reduced() || (startedFor.current !== id0 && readSeen().includes(typedKey))) { setDone(true); return; }
    startedFor.current = id0;
    record(typedKey);
    const spans = Array.from(el.querySelectorAll<HTMLSpanElement>("[data-g]"));
    const place = (i: number) => {
      const s = spans[Math.min(i, spans.length - 1)];
      if (s) caret.style.translate = `${s.offsetLeft + s.offsetWidth}px ${s.offsetTop}px`;
    };
    let i = 0;
    place(0);
    el.dataset.typing = "run"; // letters, tail and caret start in the tick that starts the interval
    const id = window.setInterval(() => { i += 1; if (i >= spans.length) window.clearInterval(id); else place(i); }, STEP_MS);
    const cleanup = () => { window.removeEventListener("keydown", onKey); el.removeEventListener("pointerdown", skip); };
    const skip = () => { window.clearInterval(id); place(spans.length - 1); setDone(true); cleanup(); };
    const onKey = () => { const a = document.activeElement; if (a === document.body || a === el) skip(); };
    window.addEventListener("keydown", onKey);
    el.addEventListener("pointerdown", skip, { once: true });
    return () => { window.clearInterval(id); cleanup(); delete el.dataset.typing; };
  }, [text, typedKey]);
  return (
    <Tag ref={ref} tabIndex={-1} aria-label={text} data-testid={tid} className={`typed${done ? " is-done" : ""}${className ? ` ${className}` : ""}`}>
      {g.map((c, i) => <span key={i} data-g aria-hidden style={{ "--i": i } as CSSProperties}>{c}</span>)}
      {tail && <span className="tail" aria-hidden style={{ "--n": g.length } as CSSProperties}>{tail}</span>}
      <span ref={caretRef} className="caret" aria-hidden style={{ "--n": g.length } as CSSProperties} />
    </Tag>
  );
}
