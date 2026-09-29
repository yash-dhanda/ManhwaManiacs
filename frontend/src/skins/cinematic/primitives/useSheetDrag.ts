"use client";
import { animate } from "motion/react";
import { useDrag } from "@use-gesture/react";
import { useEffect, useRef, type RefObject } from "react";
import { haptic } from "../haptics";
import { readReduced } from "../motion";
import { durMs } from "../tokens.generated";
import { nearestDetent, rubberBand, shouldDismiss } from "./sheet-physics";

/**
 * Sheet drag (§7.9, coarse pointers): follows the finger 1:1 on the grabber and header (`bind`) and from the body's
 * overscroll at its top; past the top detent it rubber-bands; release settles on the nearest detent with `spring.sheet`
 * (150 ms fade under reduced motion) or dismisses (30 % of the height or 800 px/s).
 */
export function useSheetDrag({ popupRef, bodyRef, detents, enabled, onDismiss }: {
  popupRef: RefObject<HTMLElement | null>;
  bodyRef: RefObject<HTMLElement | null>;
  detents: number[];
  enabled: boolean;
  onDismiss: () => void;
}) {
  const rest = useRef(0);       // current resting offset (px below the tallest detent)
  const cur = useRef(0);
  const anim = useRef<{ stop: () => void } | null>(null);
  const cb = useRef({ detents, onDismiss });
  useEffect(() => { cb.current = { detents, onDismiss }; });

  const set = (y: number) => {
    cur.current = y;
    const el = popupRef.current;
    if (!el) return;
    el.style.setProperty("--cine-drag-y", `${y}px`);
  };
  const dims = () => ({ h: popupRef.current?.offsetHeight ?? 600, vh: window.innerHeight });
  const restOf = (i: number) => {
    const d = cb.current.detents; const top = Math.max(...d);
    return (top - d[i]) * window.innerHeight;
  };
  const lowestRest = () => Math.max(...cb.current.detents.map((_, i) => restOf(i)));

  const move = (dy: number) => {
    anim.current?.stop();
    popupRef.current?.setAttribute("data-dragging", "");
    const total = rest.current + dy;
    const { h } = dims();
    set(total < 0 ? -rubberBand(-total, h) : total);
  };
  const release = (vyPxPerS: number) => {
    const el = popupRef.current; if (!el) return;
    el.removeAttribute("data-dragging");
    const { h, vh } = dims();
    const total = cur.current;
    const reduced = readReduced();
    if (shouldDismiss(total - lowestRest(), h, vyPxPerS)) {
      if (reduced) { el.style.transition = `opacity ${durMs.reduced}ms linear`; el.style.opacity = "0"; setTimeout(() => cb.current.onDismiss(), durMs.reduced); return; }
      anim.current = animate(total, h, { type: "spring", visualDuration: 0.48, bounce: 0, onUpdate: set, onComplete: () => cb.current.onDismiss() });
      haptic("sheet.dismiss");
      return;
    }
    const i = nearestDetent(total, cb.current.detents, vh);
    const target = restOf(i);
    if (target !== rest.current) haptic("sheet.detent");
    rest.current = target;
    if (reduced) { set(target); return; }
    anim.current = animate(total, target, { type: "spring", visualDuration: 0.48, bounce: 0, onUpdate: set });
  };

  // Grabber + header: use-gesture, touch only.
  const bind = useDrag(({ movement: [, my], velocity: [, vy], direction: [, dy], last }) => {
    if (!enabled) return;
    if (last) release(vy * 1000 * (dy >= 0 ? 1 : -1)); else move(my);
  }, { pointer: { touch: true }, filterTaps: true, axis: "y", enabled });

  // Body overscroll: touch events so the browser still scrolls until scrollTop hits 0.
  useEffect(() => {
    const body = bodyRef.current;
    if (!body || !enabled) return;
    let y0 = 0, t0 = 0, y1 = 0, tracking = false;
    const start = (e: TouchEvent) => { y0 = y1 = e.touches[0].clientY; t0 = e.timeStamp; tracking = body.scrollTop <= 0; };
    const mv = (e: TouchEvent) => {
      const y = e.touches[0].clientY;
      if (!tracking && body.scrollTop <= 0 && y > y0) { tracking = true; y0 = y; t0 = e.timeStamp; }
      if (!tracking) return;
      const dy = y - y0;
      if (dy <= 0 && cur.current <= rest.current) { if (dy < 0) tracking = false; return; }
      if (e.cancelable) e.preventDefault();
      y1 = y; move(dy);
    };
    const end = (e: TouchEvent) => {
      if (!tracking) return; tracking = false;
      if (cur.current === rest.current) return;
      const dt = Math.max(1, e.timeStamp - t0);
      release(((y1 - y0) / dt) * 1000);
    };
    body.addEventListener("touchstart", start, { passive: true });
    body.addEventListener("touchmove", mv, { passive: false });
    body.addEventListener("touchend", end); body.addEventListener("touchcancel", end);
    return () => { body.removeEventListener("touchstart", start); body.removeEventListener("touchmove", mv); body.removeEventListener("touchend", end); body.removeEventListener("touchcancel", end); };
    // eslint-disable-next-line react-hooks/exhaustive-deps -- handlers read refs
  }, [enabled, bodyRef]);

  /** Reset to the tallest detent for a fresh open. */
  const reset = () => { rest.current = 0; set(0); popupRef.current?.style.removeProperty("opacity"); popupRef.current?.style.removeProperty("transition"); };
  return { bind, reset };
}
