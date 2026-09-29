"use client";

import { useEffect, useSyncExternalStore } from "react";

/**
 * One lit object per screen (DESIGN 2.4.2 rule 8). Every mounted `tinted` object registers here. In development,
 * two visible lit objects outside an overlay log one console.warn. suppressLit() (sheets and alerts, web/27)
 * drops the screen's lit object to glassThin and fades its caustic over 180 ms until released.
 */
interface Entry { el: () => HTMLElement | null; overlay: boolean }
const entries = new Set<Entry>();
const subs = new Set<() => void>();
let suppressors = 0;
let warned = false;
const emit = () => subs.forEach((s) => s());

const visible = (e: Entry) => {
  const el = e.el();
  return !!el && el.getClientRects().length > 0 && getComputedStyle(el).visibility !== "hidden";
};

/** Visible lit objects outside overlays (exported for tests and the gallery). */
export const litCount = () => [...entries].filter((e) => !e.overlay && visible(e)).length;

function check() {
  if (process.env.NODE_ENV === "production") return;
  if (litCount() > 1) {
    if (!warned) console.warn("[glass] more than one visible lit (tinted) object outside an overlay: one lit object per screen (2.4.2 rule 8)");
    warned = true;
  } else warned = false;
}

/** Registers a lit object; returns the unregister function. The check runs after layout and past StrictMode's mount/unmount/mount. */
export function registerLit(el: () => HTMLElement | null, overlay = false): () => void {
  const e: Entry = { el, overlay };
  entries.add(e);
  emit();
  const t = setTimeout(check, 0);
  return () => { clearTimeout(t); entries.delete(e); emit(); };
}

export function useLit(el: () => HTMLElement | null, overlay = false, active = true): { suppressed: boolean } {
  useEffect(() => (active ? registerLit(el, overlay) : undefined), [el, overlay, active]);
  const suppressed = useSyncExternalStore((cb) => (subs.add(cb), () => void subs.delete(cb)), () => suppressors > 0, () => false);
  return { suppressed: suppressed && !overlay };
}

/** test hook */
export const isSuppressed = () => suppressors > 0;

/** Called by sheets and alerts; returns the release function. */
export function suppressLit(): () => void {
  suppressors++;
  emit();
  let done = false;
  return () => { if (done) return; done = true; suppressors--; emit(); };
}

/** test hook */
export const _resetLit = () => { entries.clear(); suppressors = 0; warned = false; };
