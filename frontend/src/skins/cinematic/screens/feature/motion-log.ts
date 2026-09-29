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
  const logged = new Set<string>();
  const t0 = performance.now();
  const id = window.setInterval(() => {
    for (const a of document.getAnimations()) {
      const e = a.effect as KeyframeEffect | null;
      const pe = e?.pseudoElement ?? "";
      const m = /^::view-transition-(group|new|old)\((.+)\)$/.exec(pe);
      if (!m || m[2] === "root") continue;
      const cover = m[2].startsWith("mm-cover-");
      const dur = Number(e!.getTiming().duration);
      let key: string | null;
      if (cover) key = label === "in" ? "matchCut" : back ? "matchCutBack" : null;
      else {
        // an unnamed page transition gets an auto name; the CSS animation's own name says which one it is
        const an = (a as CSSAnimation).animationName;
        key = an === "mm-page-in" ? "pageIn" : an === "mm-page-out" ? "pageOut" : null;
      }
      if (!key || logged.has(key)) continue;
      logged.add(key);
      logMotion(key, key === "matchCutBack" ? 336 : key === "matchCut" ? 480 : key === "pageIn" ? 320 : 224, dur);
    }
    if (logged.size > 0 || performance.now() - t0 > 700) window.clearInterval(id);
  }, 16);
}
