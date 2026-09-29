"use client";

import { createContext, useContext, useEffect, useRef, useState, type ReactNode } from "react";
import { isGlassReduced } from "../motion";
import { AURORA, fieldColours, MOODS, rimTint, type CoverPalette, type Mood } from "./palette";

export interface AmbientSource {
  /** the story's cover palette; wins over the mood */
  palette?: Pick<CoverPalette, "a"> | null;
  /** the profile mood, used before data arrives and when no palette is given */
  mood?: Mood;
  /** the brand aurora (auth, onboarding) */
  aurora?: boolean;
  /** field opacity 0 to 1; defaults to the mood's own */
  opacity?: number;
}

/** Blob anchors in percent of the viewport (DESIGN 2.1.8). */
export const ANCHORS = [[18, 8], [78, 14], [46, 36]] as const;
export const DRIFT_MS = 14000;
const DRIFT_RANGE = 6;

/** New drift targets: each anchor moved by up to +-6 % (rand in [0, 1)). */
export function driftTargets(rand: () => number = Math.random): [number, number][] {
  return ANCHORS.map(([x, y]) => [x + (rand() * 2 - 1) * DRIFT_RANGE, y + (rand() * 2 - 1) * DRIFT_RANGE]);
}

/** The three field colours, the rim tint and the opacity for a source. */
export function resolveAmbient(s: AmbientSource) {
  const mood = MOODS[s.mood ?? "default"];
  let colours: [string, string, string];
  let smallThird = false;
  if (s.aurora) colours = [...AURORA];
  else if (s.palette?.a.length) ({ colours, smallThird } = fieldColours(s.palette, s.mood ?? "default"));
  else colours = [mood.colour, mood.colour2 ?? mood.colour, mood.colour];
  const rim = s.palette?.a.length ? rimTint(s.palette) : mood.colour;
  return { colours, smallThird, rim, opacity: s.opacity ?? (s.aurora ? 0.2 : mood.opacity) };
}

function createStore() {
  let source: AmbientSource = {};
  const subs = new Set<() => void>();
  return {
    get: () => source,
    set(next: AmbientSource) { source = next; subs.forEach((s) => s()); },
    subscribe: (cb: () => void) => (subs.add(cb), () => void subs.delete(cb)),
  };
}

const Ctx = createContext<ReturnType<typeof createStore> | null>(null);

/** Wraps the Glass tree; screens declare their field source with useAmbient, AmbientField draws it. */
export function AmbientProvider({ children }: { children: ReactNode }) {
  const [store] = useState(createStore);
  return <Ctx.Provider value={store}>{children}</Ctx.Provider>;
}

/** Declare this screen's field source (a palette, a mood, or the brand aurora). */
export function useAmbient(source: AmbientSource) {
  const store = useContext(Ctx);
  const key = JSON.stringify([source.palette?.a, source.mood, source.aurora, source.opacity]);
  useEffect(() => {
    store?.set(source);
    // the key stands for the source by value
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [store, key]);
}

/**
 * The field: ONE fixed element behind content with three radial gradients and no filter. Light follows the
 * story: the colours are registered properties on <html> that transition over tintShift (200 ms linear under
 * reduced motion, see glass.css); every glass rim reads --amb-rim from the same place.
 */
export function AmbientField() {
  const store = useContext(Ctx);
  const el = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!store) return;
    const root = document.documentElement;
    const apply = () => {
      const { colours, smallThird, rim, opacity } = resolveAmbient(store.get());
      colours.forEach((c, i) => root.style.setProperty(`--amb-a${i + 1}`, c));
      root.style.setProperty("--amb-rim", rim);
      el.current?.style.setProperty("--amb-op", String(opacity));
      el.current?.style.setProperty("--amb-s3", smallThird ? "0.6" : "1");
    };
    apply();
    const off = store.subscribe(apply);
    return () => {
      off();
      for (const p of ["--amb-a1", "--amb-a2", "--amb-a3", "--amb-rim"]) root.style.removeProperty(p);
    };
  }, [store]);

  // drift: every 14 s a new target per blob, paused while hidden, frozen under reduced motion
  useEffect(() => {
    const node = el.current;
    if (!node) return;
    let timer: ReturnType<typeof setInterval> | undefined;
    const tick = () => {
      if (isGlassReduced() || document.hidden) return;
      driftTargets().forEach(([x, y], i) => {
        node.style.setProperty(`--amb-x${i + 1}`, `${x}%`);
        node.style.setProperty(`--amb-y${i + 1}`, `${y}%`);
      });
    };
    const start = () => { clearInterval(timer); if (!document.hidden) timer = setInterval(tick, DRIFT_MS); };
    start();
    document.addEventListener("visibilitychange", start);
    return () => { clearInterval(timer); document.removeEventListener("visibilitychange", start); };
  }, []);

  return <div ref={el} className="ambient-field" aria-hidden="true" data-ambient-field="" />;
}
