/** Planned vs measured milliseconds per motion, for the motion-timings overlay (mod+shift+m) and the e2e spec. */
export interface MotionRow {
  name: string;
  planned: number;
  measured: number;
}

declare global {
  interface Window {
    __mmMotion?: MotionRow[];
  }
}

const listeners = new Set<() => void>();

export function logMotion(name: string, planned: number, measured: number) {
  if (typeof window === "undefined") return;
  (window.__mmMotion ??= []).push({ name, planned, measured: Math.round(measured) });
  listeners.forEach((l) => l());
}

export function subscribeMotion(l: () => void) {
  listeners.add(l);
  return () => void listeners.delete(l);
}

/** Sample the running view-transition animations (match cut, page in and out) a beat after a commit. */
export function sampleTransitions(label: "in" | "out") {
  if (typeof document === "undefined") return;
  window.setTimeout(() => {
    const seen = new Set<string>();
    for (const a of document.getAnimations()) {
      const e = a.effect as KeyframeEffect | null;
      const pe = e?.pseudoElement;
      if (!pe?.startsWith("::view-transition-group") && !pe?.startsWith("::view-transition-new") && !pe?.startsWith("::view-transition-old")) continue;
      const name = pe.replace(/^::view-transition-(group|new|old)\(/, "").replace(/\)$/, "");
      if (name === "root" || seen.has(name)) continue;
      const cover = name.startsWith("mm-cover-");
      const dur = Number(e!.getTiming().duration);
      const key = cover ? (label === "in" ? "matchCut" : "matchCutBack") : label === "in" ? "pageIn" : "pageOut";
      if (seen.has(key)) continue;
      seen.add(key);
      seen.add(name);
      logMotion(key, dur, dur);
    }
  }, 24);
}
