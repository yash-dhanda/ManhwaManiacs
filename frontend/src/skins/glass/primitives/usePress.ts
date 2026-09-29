"use client";

import { motionValue } from "motion/react";
import { useCallback, useEffect, useMemo, useRef, useState, type KeyboardEvent, type MouseEvent, type PointerEvent, type RefObject } from "react";
import type { HapticEvent } from "../../contract.generated";
import { haptic } from "../haptics";
import { isGlassReduced, play, useGlassReduced } from "../motion";

export type PressState = "hover" | "pressed" | "focus" | "disabled" | "loading" | "selected" | "error";

/** Pure: glass growth in px on the longest side, then as a scale of (L + growth) / L (DESIGN 2.4.2 rule 3). */
export function swellScale(w: number, h: number, kind: "medium" | "feather"): number {
  const L = Math.max(w, h);
  if (!L) return 1;
  const growth = kind === "medium" ? 12 : Math.min(17, 0.35 * L);
  return (L + growth) / L;
}

/** Pure: stretch along the drag axis, the other axis conserving area (DESIGN 4.10 Stretch). */
export function stretchScales(dx: number, width: number): { sx: number; sy: number } {
  const s = 1 + 0.06 * Math.max(-1, Math.min(1, width ? dx / width : 0));
  return { sx: s, sy: 1 / Math.sqrt(s) };
}

/** Pure: a drag further than 1.5 x the hit area (44 px minimum) from the element's box cancels. */
export function isCancelled(x: number, y: number, r: { left: number; top: number; width: number; height: number }, hit = 44): boolean {
  const w = Math.max(r.width, hit) * 1.5, h = Math.max(r.height, hit) * 1.5;
  const cx = r.left + r.width / 2, cy = r.top + r.height / 2;
  return Math.abs(x - cx) > w / 2 || Math.abs(y - cy) > h / 2;
}

export interface UsePressOptions {
  /** glass swells and its content sinks; content only sinks */
  material: "glass" | "content";
  /** glass: Medium class +12 px, Feather/Light +17 px capped at 0.35 x side */
  growth?: "medium" | "feather";
  /** content sink scale: cards and posters 0.97, rows 0.99, chips 0.96, plain icons 0.92 */
  sink?: number;
  disabled?: boolean;
  loading?: boolean;
  selected?: boolean;
  error?: boolean;
  /** the gallery forces a state; sets the same attribute the real state sets */
  forceState?: PressState;
  /** default "tap.primary"; false = none */
  haptic?: HapticEvent | false;
  /** activation: release inside the target (or Enter/Space) */
  onPress?: (e: PointerEvent | MouseEvent | KeyboardEvent) => void;
  onPressStart?: (e: PointerEvent) => void;
  /** press ended without activating (drag away, pointercancel) */
  onCancel?: () => void;
  /** glass only: stretch toward a drag */
  stretch?: boolean;
  /** minimum hit box used for the cancel distance */
  hit?: number;
}

/**
 * Every pressable primitive uses this. It sets data-hover / data-pressed / data-focus-visible / data-disabled /
 * data-loading / data-selected / data-error on the element (so states are styled from CSS and the gallery can force
 * one), animates `--mm-swell` 0..1 on the `press` spring, and writes `scale` (glass growth x stretch, or content sink).
 * Spread `props` on the interactive element and hand `glow` to GlassSurface as `pressedGlow`.
 */
export function usePress<T extends HTMLElement = HTMLElement>(o: UsePressOptions) {
  const ref = useRef<T | null>(null);
  const reduced = useGlassReduced();
  const [hover, setHover] = useState(false);
  const [pressed, setPressed] = useState(false);
  const [focusVisible, setFocusVisible] = useState(false);
  const [glow, setGlow] = useState<{ x: number; y: number; on: boolean }>({ x: 0, y: 0, on: false });
  const swell = useMemo(() => motionValue(0), []);
  const st = useRef({ id: -1, active: false, cancelled: false, dx: 0, x0: 0, base: 1, w: 1, ctl: null as { stop: () => void } | null });
  const blocked = !!(o.disabled || o.loading);
  const oRef = useRef(o);
  useEffect(() => { oRef.current = o; });

  const write = useCallback(() => {
    const el = ref.current;
    if (!el) return;
    const v = swell.get();
    el.style.setProperty("--mm-swell", v.toFixed(4));
    if (isGlassReduced()) { el.style.scale = ""; return; }
    const cur = oRef.current;
    if (cur.material === "content") { el.style.scale = v ? String(1 - (1 - (cur.sink ?? 0.97)) * v) : ""; return; }
    const g = 1 + (st.current.base - 1) * v;
    const { sx, sy } = cur.stretch === false || !st.current.active ? { sx: 1, sy: 1 } : stretchScales(st.current.dx, st.current.w);
    el.style.scale = v || st.current.active ? `${(g * sx).toFixed(4)} ${(g * sy).toFixed(4)}` : "";
  }, [swell]);
  useEffect(() => swell.on("change", write), [swell, write]);

  const settle = useCallback((to: 0 | 1) => {
    st.current.ctl?.stop();
    st.current.ctl = play(to ? "pressSwell" : "contentSink", swell, to);
  }, [swell]);

  const end = useCallback((activated: boolean, e?: PointerEvent) => {
    const s = st.current;
    if (!s.active) return;
    s.active = false;
    s.dx = 0;
    setPressed(false);
    setGlow((g) => ({ ...g, on: false }));
    settle(0);
    const cur = oRef.current;
    if (activated && e) {
      if (cur.haptic !== false) haptic(cur.haptic ?? "tap.primary");
      cur.onPress?.(e);
    } else cur.onCancel?.();
  }, [settle]);

  const onPointerDown = (e: PointerEvent<T>) => {
    if (blocked || (e.pointerType === "mouse" && e.button !== 0)) return;
    const el = e.currentTarget;
    const r = el.getBoundingClientRect();
    const s = st.current;
    s.id = e.pointerId; s.active = true; s.cancelled = false; s.dx = 0; s.x0 = e.clientX; s.w = r.width;
    s.base = oRef.current.material === "glass" ? swellScale(r.width, r.height, oRef.current.growth ?? "medium") : 1;
    try { el.setPointerCapture(e.pointerId); } catch { /* synthetic events */ }
    setPressed(true);
    setGlow({ x: e.clientX - r.left, y: e.clientY - r.top, on: true });
    settle(1);
    oRef.current.onPressStart?.(e);
  };
  const onPointerMove = (e: PointerEvent<T>) => {
    const el = e.currentTarget;
    const s = st.current;
    if (e.pointerType === "mouse" && !s.active && !blocked) {
      const r = el.getBoundingClientRect();
      el.style.setProperty("--glow-x", `${e.clientX - r.left}px`);
      el.style.setProperty("--glow-y", `${e.clientY - r.top}px`);
    }
    if (!s.active || e.pointerId !== s.id) return;
    const r = el.getBoundingClientRect();
    if (!s.cancelled && isCancelled(e.clientX, e.clientY, r, oRef.current.hit)) {
      s.cancelled = true;
      end(false);
      return;
    }
    if (!s.cancelled) { s.dx = e.clientX - s.x0; write(); }
  };
  const onPointerUp = (e: PointerEvent<T>) => {
    const s = st.current;
    if (!s.active || e.pointerId !== s.id) return;
    const r = e.currentTarget.getBoundingClientRect();
    end(!s.cancelled && !isCancelled(e.clientX, e.clientY, r, oRef.current.hit), e);
  };
  const onPointerCancel = () => end(false);

  const onClick = (e: MouseEvent<T>) => {
    // pointer clicks were activated on release; a click with no pointer (detail 0) is the keyboard or assistive tech
    if (e.detail !== 0 || blocked) return;
    const cur = oRef.current;
    if (cur.haptic !== false) haptic(cur.haptic ?? "tap.primary");
    cur.onPress?.(e);
  };
  /** for non-native elements (role="button" on a div): Enter and Space are always a click */
  const onKeyDown = (e: KeyboardEvent<T>) => {
    if (blocked || e.currentTarget !== e.target) return;
    if (e.key === "Enter" || e.key === " ") {
      e.preventDefault();
      const cur = oRef.current;
      if (cur.haptic !== false) haptic(cur.haptic ?? "tap.primary");
      cur.onPress?.(e);
    }
  };

  const f = o.forceState;
  useEffect(() => {
    const el = ref.current;
    if (f !== "pressed" || !el) return;
    const r = el.getBoundingClientRect();
    st.current.base = o.material === "glass" ? swellScale(r.width, r.height, o.growth ?? "medium") : 1;
    swell.set(1);
    return () => swell.set(0);
  }, [f, o.material, o.growth, swell]);
  const on = (name: PressState, real: boolean | undefined) => (real || f === name ? "" : undefined);
  const props = {
    onPointerDown, onPointerMove, onPointerUp, onPointerCancel, onClick,
    onPointerEnter: (e: PointerEvent<T>) => { if (e.pointerType === "mouse") setHover(true); },
    onPointerLeave: () => setHover(false),
    onFocus: (e: { currentTarget: T; target: EventTarget }) => { try { setFocusVisible(e.target === e.currentTarget && e.currentTarget.matches(":focus-visible")); } catch { setFocusVisible(true); } },
    onBlur: () => setFocusVisible(false),
    "data-press": o.material,
    "data-reduced": reduced ? "" : undefined,
    "data-hover": on("hover", hover),
    "data-pressed": on("pressed", pressed),
    "data-focus-visible": on("focus", focusVisible),
    "data-disabled": on("disabled", o.disabled),
    "data-loading": on("loading", o.loading),
    "data-selected": on("selected", o.selected),
    "data-error": on("error", o.error),
    "aria-disabled": o.disabled ? true : undefined,
    "aria-busy": o.loading ? true : undefined,
  } as const;

  const glowOut = f === "pressed" && !glow.on ? { x: (ref.current?.offsetWidth ?? 0) / 2, y: (ref.current?.offsetHeight ?? 0) / 2, on: true } : glow;
  return { ref: ref as RefObject<T | null>, props, glow: glowOut, pressed, onKeyDown, swell };
}
