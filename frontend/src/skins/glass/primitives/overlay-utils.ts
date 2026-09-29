"use client";

import { animate, type AnimationPlaybackControls, type MotionValue } from "motion/react";
import { useEffect, useState, useSyncExternalStore } from "react";
import { isGlassReduced } from "../motion";
import { spring } from "../tokens.generated";

const noop = () => () => {};
/** The element that carries the Glass tokens; overlays portal inside it so the custom properties resolve. */
export const glassHost = () => document.querySelector<HTMLElement>('[data-skin="glass"]') ?? document.body;
export const useGlassHost = (): HTMLElement | null => useSyncExternalStore(noop, glassHost, () => null);

/** matchMedia as state; `false` on the server and before mount. */
export function useMedia(query: string): boolean {
  const [v, setV] = useState(false);
  useEffect(() => {
    const mq = window.matchMedia(query);
    const on = () => setV(mq.matches);
    on();
    mq.addEventListener("change", on);
    return () => mq.removeEventListener("change", on);
  }, [query]);
  return v;
}
/** Phones and mobile web below 768 px. */
export const useIsDesktop = () => useMedia("(min-width: 768px)");

let probe: HTMLElement | null = null;
/** `env(safe-area-inset-top)` in px (0 on desktop browsers). */
export function safeTop(): number {
  if (typeof document === "undefined") return 0;
  if (!probe || !probe.isConnected) {
    probe = document.createElement("div");
    probe.style.cssText = "position:fixed;top:0;left:0;width:0;height:0;padding-top:env(safe-area-inset-top,0px);visibility:hidden;pointer-events:none";
    document.body.appendChild(probe);
  }
  return parseFloat(getComputedStyle(probe).paddingTop) || 0;
}

export type SpringName = keyof typeof spring;

/**
 * A spring from the token table that has no named move of its own (the sheet's `dismiss`, an overlay's `tick`, `camera`).
 * Reduced motion: a 150 ms linear fade replaces it (the value simply gets there).
 */
export function springTo(mv: MotionValue<number>, to: number, name: SpringName, opts: { velocity?: number; onComplete?: () => void } = {}): AnimationPlaybackControls {
  if (isGlassReduced()) return animate(mv, to, { duration: 0.15, ease: "linear", onComplete: opts.onComplete });
  return animate(mv, to, { ...spring[name], velocity: opts.velocity, onComplete: opts.onComplete } as never);
}

export const clamp01 = (v: number) => Math.min(1, Math.max(0, v));

/** Focus an element without scrolling. */
export const focusQuiet = (el: HTMLElement | null | undefined) => el?.focus({ preventScroll: true });

/** Elements inside `root` that take keyboard focus, in DOM order. */
export const FOCUSABLE = 'a[href], button:not([disabled]), input:not([disabled]), textarea:not([disabled]), select:not([disabled]), [tabindex]:not([tabindex="-1"])';
