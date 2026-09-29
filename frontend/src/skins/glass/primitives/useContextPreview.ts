"use client";

import { useCallback, useEffect, useState, type RefObject } from "react";
import { registerGlass } from "../glass/budget";
import { haptic } from "../haptics";
import { isGlassReduced, play } from "../motion";

export type PreviewKind = "poster" | "row" | "image";
/** Poster 1.12, row 1.02, image 1.0 (glass 7.23). */
export const PREVIEW_SCALE: Record<PreviewKind, number> = { poster: 1.12, row: 1.02, image: 1 };

export interface ContextPreview {
  open: boolean;
  /** called by Poster's `onContextPreview` at 450 ms (`longpress.open`), or by `.` / Shift+F10 on a focused item */
  show: () => void;
  hide: () => void;
  element: HTMLElement | null;
}

/**
 * Lifts the pressed object over a `dimContext` scrim (registered in the glass budget as a scrim) so a menu can bloom from its
 * nearest edge. The object stays interactive: it is raised in place, never cloned, so a poster can still be dragged and thrown.
 */
export function useContextPreview(ref: RefObject<HTMLElement | null>, kind: PreviewKind): ContextPreview {
  const [open, setOpen] = useState(false);
  const show = useCallback(() => { haptic("longpress.open"); setOpen(true); }, []);
  const hide = useCallback(() => setOpen(false), []);
  const element = open ? ref.current : null;
  useEffect(() => {
    const el = ref.current;
    if (!open || !el) return;
    const off = registerGlass({ id: `dim-context-${Math.random().toString(36).slice(2)}`, kind: "scrim", layer: "overlays", label: "dimContext", el: null });
    const prev = { z: el.style.zIndex, pos: el.style.position, scale: el.style.scale };
    if (getComputedStyle(el).position === "static") el.style.position = "relative";
    el.style.zIndex = "80";
    el.setAttribute("data-lifted", "");
    const s = isGlassReduced() ? 1 : PREVIEW_SCALE[kind];
    const c = play("pressSwell", 0, 1, { onUpdate: (v) => { el.style.scale = String(1 + (s - 1) * v); } });
    return () => {
      c.stop();
      off();
      el.style.zIndex = prev.z; el.style.position = prev.pos; el.style.scale = prev.scale;
      el.removeAttribute("data-lifted");
    };
  }, [open, kind, ref]);
  return { open, show, hide, element };
}
