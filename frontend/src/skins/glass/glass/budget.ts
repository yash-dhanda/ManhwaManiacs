"use client";

import { createContext, createElement, useContext, useSyncExternalStore, type ReactNode } from "react";

export type GlassLayer = "controls" | "overlays" | "interruptions" | "hud";
/** z layers 3 to 6 of DESIGN 2.4.1 */
export const LAYER_RANK: Record<GlassLayer, number> = { controls: 3, overlays: 4, interruptions: 5, hud: 6 };
/** DESIGN 15.7: live glass elements per web screen. */
export const GLASS_LIMIT = 6;

export interface Rect { left: number; top: number; right: number; bottom: number }
export interface BudgetEntry {
  id: string;
  /** scrims (scroll-edge and dimContext blur layers) are counted apart from glass */
  kind: "glass" | "scrim";
  layer: GlassLayer;
  label: string;
  el: HTMLElement | null;
  /** development galleries only: shown in the live count, never counted against GLASS_LIMIT */
  exempt?: boolean;
}

/** Development galleries show many live specimens at once; screens never use this. */
export const BudgetScopeContext = createContext<{ exempt: boolean; label?: string }>({ exempt: false });
export function GlassBudgetScope({ exempt = false, label, children }: { exempt?: boolean; label?: string; children: ReactNode }) {
  return createElement(BudgetScopeContext.Provider, { value: { exempt, label } }, children);
}
export const useBudgetScope = () => useContext(BudgetScopeContext);

const overlap = (a: Rect, b: Rect) => a.left < b.right && b.left < a.right && a.top < b.bottom && b.top < a.bottom;

/**
 * DESIGN 2.4.2 rule 7 / 2.5: at most two stacked live layers. A surface overlapped by two live surfaces of
 * higher layers that also overlap each other renders solid until the stack clears.
 */
export function forcedSolidIds(items: readonly { id: string; layer: GlassLayer; rect: Rect }[]): Set<string> {
  const out = new Set<string>();
  for (const a of items) {
    const above = items.filter((b) => b !== a && LAYER_RANK[b.layer] > LAYER_RANK[a.layer] && overlap(a.rect, b.rect));
    outer: for (let i = 0; i < above.length; i++)
      for (let j = i + 1; j < above.length; j++)
        if (overlap(above[i].rect, above[j].rect)) { out.add(a.id); break outer; }
  }
  return out;
}

const entries = new Map<string, BudgetEntry>();
let counts = { glass: 0, scrims: 0, exempt: 0 };
let solid: ReadonlySet<string> = new Set();
let warned = false;
const listeners = new Set<() => void>();

const emit = () => listeners.forEach((l) => l());
const subscribe = (l: () => void) => (listeners.add(l), () => void listeners.delete(l));

function checkLimit() {
  if (counts.glass <= GLASS_LIMIT) { warned = false; return; }
  if (warned) return;
  warned = true;
  console.warn(`[glass] ${counts.glass} live glass elements (limit ${GLASS_LIMIT}): ${[...entries.values()].filter((e) => e.kind === "glass" && !e.exempt).map((e) => e.label).join(", ")}`);
}

function recompute() {
  const list = [...entries.values()];
  const glass = list.filter((e) => e.kind === "glass");
  const exempt = glass.filter((e) => e.exempt).length;
  const next = { glass: glass.length - exempt, scrims: list.length - glass.length, exempt };
  if (next.glass !== counts.glass || next.scrims !== counts.scrims || next.exempt !== counts.exempt) counts = next;
  const rects = glass.flatMap((e) => (e.el ? [{ id: e.id, layer: e.layer, rect: e.el.getBoundingClientRect() }] : []));
  const f = forcedSolidIds(rects);
  if (f.size !== solid.size || [...f].some((id) => !solid.has(id))) solid = f;
  // Dev warning, one per crossing. Deferred a tick so StrictMode's mount/unmount/mount cycle does not warn twice.
  if (process.env.NODE_ENV !== "production") setTimeout(checkLimit, 0);
  emit();
}

export function registerGlass(e: BudgetEntry): () => void {
  entries.set(e.id, e);
  recompute();
  return () => { entries.delete(e.id); recompute(); };
}

let timer: ReturnType<typeof setTimeout> | undefined;
/** Re-check rects after a layout change (debounced by the caller's resize listener). */
export const recomputeStacking = () => { clearTimeout(timer); timer = setTimeout(recompute, 100); };

export const useGlassCount = () => useSyncExternalStore(subscribe, () => counts, () => counts);
export const useForcedSolid = (id: string) => useSyncExternalStore(subscribe, () => solid.has(id), () => false);

/** test hook */
export const _resetBudget = () => { entries.clear(); counts = { glass: 0, scrims: 0, exempt: 0 }; solid = new Set(); warned = false; };

/** dev/e2e hook: the live counts and the forced-solid ids */
if (typeof window !== "undefined" && process.env.NODE_ENV !== "production")
  (window as unknown as { __glassBudget?: () => unknown }).__glassBudget = () => ({ ...counts, solid: [...solid] });
