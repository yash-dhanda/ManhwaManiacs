"use client";

import { useEffect, useState, type RefObject } from "react";

/** TODO(reader): the reader's PageSample type lands with features/reader; this is its shape for the `page` source. */
export interface PageSample { pTop: number; pMid: number; pBottom: number }

export type LbSource =
  | { kind: "unknown" }
  | { kind: "field"; l: number; opacity: number }
  | { kind: "cover"; lMax: number }
  | { kind: "page"; sample: PageSample; bands: readonly ("top" | "mid" | "bottom")[] }
  | { kind: "paper"; luminance: number }
  | { kind: "bar"; ref: RefObject<HTMLElement | null>; field?: { l: number; opacity: number } };

const clamp01 = (v: number) => Math.min(1, Math.max(0, v));
/** The ambient field's contribution (2.1.7): l x opacity + 0.02. */
export const fieldTerm = (l: number, opacity: number) => l * opacity + 0.02;

/** Lb (0 to 1) for every source except `bar`, which needs the registered items (see useLb). */
export function lbOf(source: Exclude<LbSource, { kind: "bar" }>): number {
  switch (source.kind) {
    case "unknown": return 1;
    case "field": return clamp01(fieldTerm(source.l, source.opacity));
    case "cover": return clamp01(source.lMax);
    case "page": {
      const key = { top: "pTop", mid: "pMid", bottom: "pBottom" } as const;
      return clamp01(Math.max(0, ...source.bands.map((b) => source.sample[key[b]])));
    }
    case "paper": return clamp01(source.luminance);
  }
}

/* ---- registered items: posters and rows call useLbItem(ref, lMax) (web/26) ---- */
const items = new Map<RefObject<HTMLElement | null>, number>();
const subs = new Set<() => void>();

/** Register an item's peak luminance so a bar over it can read it. */
export function useLbItem(ref: RefObject<HTMLElement | null>, lMax: number) {
  useEffect(() => {
    items.set(ref, lMax);
    subs.forEach((s) => s());
    return () => { items.delete(ref); subs.forEach((s) => s()); };
  }, [ref, lMax]);
}

/** Largest lMax among registered items whose rects intersect `rect`. */
export function lItemsFor(rect: DOMRect): number {
  let m = 0;
  for (const [ref, lMax] of items) {
    const r = ref.current?.getBoundingClientRect();
    if (r && r.left < rect.right && rect.left < r.right && r.top < rect.bottom && rect.top < r.bottom) m = Math.max(m, lMax);
  }
  return m;
}

const SLOW = 3000; // px/s: above this the value is held
let scrollBound = false;
let lastTop = 0, lastT = 0, speed = 0, lastFire = 0;
let trail: ReturnType<typeof setTimeout> | undefined;
const scrollSubs = new Set<() => void>();

function onScroll(e: Event) {
  const now = performance.now();
  const top = (e.target instanceof Element ? e.target.scrollTop : window.scrollY) || 0;
  if (lastT) speed = (Math.abs(top - lastTop) / Math.max(1, now - lastT)) * 1000;
  lastTop = top; lastT = now;
  clearTimeout(trail);
  if (speed > SLOW || now - lastFire < 100) { // at most every 100 ms; held while flinging
    trail = setTimeout(() => { lastFire = performance.now(); speed = 0; scrollSubs.forEach((s) => s()); }, 120); // trailing update once scrolling settles
    return;
  }
  lastFire = now;
  scrollSubs.forEach((s) => s());
}

function bindScroll() {
  if (scrollBound) return () => {};
  scrollBound = true;
  document.addEventListener("scroll", onScroll, { capture: true, passive: true });
  return () => { scrollBound = false; clearTimeout(trail); document.removeEventListener("scroll", onScroll, { capture: true }); };
}

/** Lb for a surface (DESIGN 2.1.7 source table). The bar source is max(field term, lItems), recomputed on scroll. */
export function useLb(source: LbSource): number {
  const [bar, setBar] = useState(1);
  const isBar = source.kind === "bar";
  const ref = isBar ? source.ref : null;
  const field = isBar ? source.field : undefined;
  useEffect(() => {
    if (!ref) return;
    const update = () => {
      const el = ref.current;
      if (!el) return;
      const f = field ? fieldTerm(field.l, field.opacity) : 0;
      setBar(clamp01(Math.max(f, lItemsFor(el.getBoundingClientRect()))));
    };
    const unbind = bindScroll();
    scrollSubs.add(update);
    subs.add(update);
    const raf = requestAnimationFrame(update);
    return () => { cancelAnimationFrame(raf); scrollSubs.delete(update); subs.delete(update); if (!scrollSubs.size) unbind(); };
  }, [ref, field?.l, field?.opacity]); // eslint-disable-line react-hooks/exhaustive-deps
  return source.kind === "bar" ? bar : lbOf(source);
}
