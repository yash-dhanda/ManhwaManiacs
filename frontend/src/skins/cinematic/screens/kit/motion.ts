"use client";

import { useEffect, useState } from "react";

/** Reduced motion: the media query or html[data-motion="reduced"]. */
export function prefersReducedMotion(): boolean {
  if (typeof window === "undefined") return false;
  return (
    window.matchMedia("(prefers-reduced-motion: reduce)").matches ||
    document.documentElement.dataset.motion === "reduced"
  );
}

export function useReducedMotion(): boolean {
  const [reduced, setReduced] = useState(false);
  useEffect(() => {
    const update = () => setReduced(prefersReducedMotion());
    update();
    const mq = window.matchMedia("(prefers-reduced-motion: reduce)");
    mq.addEventListener("change", update);
    return () => mq.removeEventListener("change", update);
  }, []);
  return reduced;
}

/** One grapheme per 50 ms; the full string at once under reduced motion or when `active` is false. */
export function useTyped(text: string, active: boolean, stepMs = 50): string {
  const reduced = useReducedMotion();
  const [state, setState] = useState({ text, count: 0 });
  useEffect(() => {
    if (!active || reduced) return;
    const graphemes = Array.from(text).length;
    let n = 0;
    const timer = setInterval(() => {
      n += 1;
      setState({ text, count: n });
      if (n >= graphemes) clearInterval(timer);
    }, stepMs);
    return () => clearInterval(timer);
  }, [text, active, reduced, stepMs]);
  if (!active || reduced) return text;
  const count = state.text === text ? state.count : 0;
  return Array.from(text).slice(0, count).join("");
}

/** Re-renders every `ms`; returns Date.now(). */
export function useNow(ms: number): number {
  const [now, setNow] = useState(() => Date.now());
  useEffect(() => {
    const t = setInterval(() => setNow(Date.now()), ms);
    return () => clearInterval(t);
  }, [ms]);
  return now;
}

/** `Retry-After` countdown in whole seconds; 0 when idle. */
export function useCountdown(seconds: number | null): number {
  const [state, setState] = useState({ seconds, left: seconds ?? 0 });
  useEffect(() => {
    if (!seconds) return;
    let left = seconds;
    const t = setInterval(() => {
      left = Math.max(0, left - 1);
      setState({ seconds, left });
      if (left === 0) clearInterval(t);
    }, 1000);
    return () => clearInterval(t);
  }, [seconds]);
  return state.seconds === seconds ? state.left : (seconds ?? 0);
}
