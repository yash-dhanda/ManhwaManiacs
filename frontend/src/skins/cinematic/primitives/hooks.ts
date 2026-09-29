"use client";
import { useEffect, useState } from "react";

/** Root font size as a multiple of 16 px (150 % stacks the folio button, 130 % gives titles two lines). Updates on resize and on style/class changes to <html>. */
export function useRootScale(): number {
  const [scale, setScale] = useState(1);
  useEffect(() => {
    const read = () => setScale(parseFloat(getComputedStyle(document.documentElement).fontSize) / 16 || 1);
    read();
    window.addEventListener("resize", read);
    const mo = new MutationObserver(read);
    mo.observe(document.documentElement, { attributes: true, attributeFilter: ["style", "class"] });
    return () => { window.removeEventListener("resize", read); mo.disconnect(); };
  }, []);
  return scale;
}

/** Holds `value` true for `ms` after it turns true (error colours, success ticks). */
export function useHold(value: unknown, ms: number): boolean {
  const [held, setHeld] = useState(false);
  useEffect(() => {
    if (!value) return;
    setHeld(true); // eslint-disable-line react-hooks/set-state-in-effect -- timed hold
    const t = setTimeout(() => setHeld(false), ms);
    return () => clearTimeout(t);
  }, [value, ms]);
  return held;
}

/** Long-press (450 ms, 8 px slop) or right-click. Spread the returned handlers on the element. */
export function useLongPress(onLongPress?: () => void, ms = 450, slop = 8) {
  const state = { t: 0 as unknown as ReturnType<typeof setTimeout>, x: 0, y: 0, fired: false };
  return {
    onPointerDown: (e: React.PointerEvent) => {
      if (!onLongPress || e.pointerType === "mouse") return;
      state.x = e.clientX; state.y = e.clientY; state.fired = false;
      state.t = setTimeout(() => { state.fired = true; onLongPress(); }, ms);
      const cancel = (ev: PointerEvent) => {
        if (ev.type === "pointermove" && Math.hypot(ev.clientX - state.x, ev.clientY - state.y) < slop) return;
        clearTimeout(state.t);
        window.removeEventListener("pointermove", cancel); window.removeEventListener("pointerup", cancel); window.removeEventListener("pointercancel", cancel);
      };
      window.addEventListener("pointermove", cancel); window.addEventListener("pointerup", cancel); window.addEventListener("pointercancel", cancel);
    },
    onContextMenu: (e: React.MouseEvent) => { if (!onLongPress) return; e.preventDefault(); onLongPress(); },
  };
}
