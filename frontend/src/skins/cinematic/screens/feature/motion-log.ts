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

/**
 * Sample the running view-transition animations a beat after a commit and log
 * the match cut (480 in, 336 back), Page in (320) and Page out (224).
 */
export function sampleTransitions(label: "in" | "out") {
  if (typeof document === "undefined") return;
  const back = document.documentElement.dataset.mmNav === "back";
  window.setTimeout(() => {
    const logged = new Set<string>();
    for (const a of document.getAnimations()) {
      const e = a.effect as KeyframeEffect | null;
      const pe = e?.pseudoElement ?? "";
      const m = /^::view-transition-(group|new|old)\((.+)\)$/.exec(pe);
      if (!m || m[2] === "root") continue;
      const cover = m[2].startsWith("mm-cover-");
      if (cover && m[1] !== "group") continue;
      const dur = Number(e!.getTiming().duration);
      let key: string | null;
      if (cover) key = label === "in" ? "matchCut" : back ? "matchCutBack" : null;
      else key = label === "in" ? (m[2] === "mm-page-in" ? "pageIn" : null) : m[2] === "mm-page-out" ? "pageOut" : null;
      if (!key || logged.has(key)) continue;
      logged.add(key);
      logMotion(key, key === "matchCutBack" ? 336 : key === "matchCut" ? 480 : key === "pageIn" ? 320 : 224, dur);
    }
  }, 24);
}
