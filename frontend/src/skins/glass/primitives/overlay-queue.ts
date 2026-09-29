"use client";

import { useEffect, useSyncExternalStore } from "react";

/**
 * The overlay queue (glass 7.12, 7.30, 15.7): one small store that decides which transient items may show.
 * Blockers (menus, context menus, and on phones alerts) hold every item. On phones one top-band slot serves
 * toast > new-chapters capsule > app-update capsule; on desktop and tablet toasts and the new-chapters capsule
 * share a queue and the app-update capsule waits while a bottom bar shows (`html[data-bottom-bar]`).
 */
export type SlotKind = "toast" | "chapters" | "update";
export type BlockerKind = "menu" | "alert";

export interface QueueInput {
  wanted: Readonly<Record<SlotKind, boolean>>;
  /** open blockers by kind */
  blockers: Readonly<Record<BlockerKind, number>>;
  phone: boolean;
  bottomBar: boolean;
}

export type Allowed = Record<SlotKind, boolean>;

/** Pure: which of the wanted items may show right now. */
export function computeAllowed({ wanted, blockers, phone, bottomBar }: QueueInput): Allowed {
  const none: Allowed = { toast: false, chapters: false, update: false };
  if (blockers.menu > 0 || (phone && blockers.alert > 0)) return none;
  if (phone) {
    const first = (["toast", "chapters", "update"] as const).find((k) => wanted[k]);
    return first ? { ...none, [first]: true } : none;
  }
  return {
    chapters: wanted.chapters,
    toast: wanted.toast && !wanted.chapters,
    update: wanted.update && !bottomBar,
  };
}

/**
 * A timer that keeps its remaining time when paused (a toast leaving for a menu, hover, focus, touch).
 * The clock is injectable so the queue's tests need no real time.
 */
export class PausableTimer {
  private left: number;
  private started: number | null = null;
  private handle: ReturnType<typeof setTimeout> | undefined;
  constructor(ms: number, private readonly onDone: () => void, private readonly now: () => number = () => performance.now()) { this.left = ms; }
  get remaining(): number { return this.started === null ? this.left : Math.max(0, this.left - (this.now() - this.started)); }
  get running(): boolean { return this.started !== null; }
  start(): void {
    if (this.started !== null || this.left === Infinity) return;
    this.started = this.now();
    this.handle = setTimeout(() => { this.left = 0; this.started = null; this.onDone(); }, this.left);
  }
  pause(): void {
    if (this.started === null) return;
    this.left = this.remaining;
    this.started = null;
    clearTimeout(this.handle);
  }
  stop(): void { this.pause(); this.left = 0; }
}

const wanted: Record<SlotKind, number> = { toast: 0, chapters: 0, update: 0 };
const blockers: Record<BlockerKind, number> = { menu: 0, alert: 0 };
let phone = typeof window !== "undefined" && window.matchMedia?.("(max-width: 767px)").matches === true;
let bottomBar = false;
let allowed: Allowed = { toast: false, chapters: false, update: false };
const subs = new Set<() => void>();

const same = (a: Allowed, b: Allowed) => a.toast === b.toast && a.chapters === b.chapters && a.update === b.update;
function recompute() {
  const next = computeAllowed({
    wanted: { toast: wanted.toast > 0, chapters: wanted.chapters > 0, update: wanted.update > 0 },
    blockers, phone, bottomBar,
  });
  if (same(next, allowed)) return;
  allowed = next;
  subs.forEach((s) => s());
}
const subscribe = (cb: () => void) => (subs.add(cb), () => void subs.delete(cb));

/** Register an open menu, context menu or alert. Returns the release function. */
export function registerBlocker(kind: BlockerKind = "menu"): () => void {
  blockers[kind]++;
  recompute();
  let done = false;
  return () => { if (done) return; done = true; blockers[kind]--; recompute(); };
}

/** Say an item of this kind wants to show. Returns the release function. */
export function requestSlot(kind: SlotKind): () => void {
  wanted[kind]++;
  recompute();
  let done = false;
  return () => { if (done) return; done = true; wanted[kind]--; recompute(); };
}

export const setQueueFrame = (next: { phone?: boolean; bottomBar?: boolean }) => {
  if (next.phone !== undefined) phone = next.phone;
  if (next.bottomBar !== undefined) bottomBar = next.bottomBar;
  recompute();
};

/** Mount once (GlassToaster does): mirrors the viewport class and `html[data-bottom-bar]` into the store. */
export function useQueueFrame(): void {
  useEffect(() => {
    const mq = window.matchMedia("(max-width: 767px)");
    const sync = () => setQueueFrame({ phone: mq.matches, bottomBar: document.documentElement.hasAttribute("data-bottom-bar") });
    sync();
    mq.addEventListener("change", sync);
    const mo = new MutationObserver(sync);
    mo.observe(document.documentElement, { attributes: true, attributeFilter: ["data-bottom-bar"] });
    return () => { mq.removeEventListener("change", sync); mo.disconnect(); };
  }, []);
}

/** Declare that an item of `kind` wants to show while `want` is true; `allowed` says whether it may. */
export function useOverlaySlot(kind: SlotKind, want = true): { allowed: boolean } {
  useEffect(() => (want ? requestSlot(kind) : undefined), [kind, want]);
  const ok = useSyncExternalStore(subscribe, () => allowed[kind], () => false);
  return { allowed: want && ok };
}

/** Hook form of `registerBlocker`: blocks while `open`. */
export function useBlocker(open: boolean, kind: BlockerKind = "menu"): void {
  useEffect(() => (open ? registerBlocker(kind) : undefined), [open, kind]);
}

export const getAllowed = (): Allowed => allowed;

/** test hook */
export const _resetQueue = () => {
  wanted.toast = wanted.chapters = wanted.update = 0;
  blockers.menu = blockers.alert = 0;
  phone = false; bottomBar = false;
  allowed = { toast: false, chapters: false, update: false };
};
