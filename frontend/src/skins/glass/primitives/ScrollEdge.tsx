"use client";

import { useEffect, useId, useRef, type CSSProperties, type RefObject } from "react";
import { registerGlass } from "../glass/budget";
import { bottomEdgeOpacity, topEdgeOpacity } from "./scroll-edge-math";

/** `.glass-scroll` shows its thumb only while scrolling: `data-scrolling` is held for 800 ms after the last scroll event. */
export function useScrollingFlag(scroller: RefObject<HTMLElement | null>) {
  useEffect(() => {
    const s = scroller.current;
    if (!s) return;
    let t: ReturnType<typeof setTimeout> | undefined;
    const on = () => { s.setAttribute("data-scrolling", ""); clearTimeout(t); t = setTimeout(() => s.removeAttribute("data-scrolling"), 800); };
    s.addEventListener("scroll", on, { passive: true });
    return () => { s.removeEventListener("scroll", on); clearTimeout(t); s.removeAttribute("data-scrolling"); };
  }, [scroller]);
}

/**
 * `edgeSoft`: a plateau of rgba(0,0,0,0.72) from the screen edge to the far edge of its bar group, then a 24 px fade, with
 * backdrop blur 6 (a scrim in the glass budget). Its opacity follows how much content is under it. Solid glass makes it the hard edge.
 */
export function ScrollEdge({ edge, plateau, scroller, "data-testid": tid }: { edge: "top" | "bottom"; plateau: number; scroller: RefObject<HTMLElement | null>; "data-testid"?: string }) {
  const el = useRef<HTMLDivElement | null>(null);
  const id = useId();
  useScrollingFlag(scroller);
  useEffect(() => registerGlass({ id: `edge-${id}`, kind: "scrim", layer: "controls", label: `scrollEdge.${edge}`, el: el.current }), [id, edge]);
  useEffect(() => {
    const s = scroller.current;
    if (!s) return;
    const write = () => {
      const o = edge === "top" ? topEdgeOpacity(s.scrollTop) : bottomEdgeOpacity(s.scrollHeight, s.scrollTop, s.clientHeight);
      el.current?.style.setProperty("--edge-o", o.toFixed(3));
    };
    write();
    s.addEventListener("scroll", write, { passive: true });
    const ro = new ResizeObserver(write);
    ro.observe(s);
    return () => { s.removeEventListener("scroll", write); ro.disconnect(); };
  }, [edge, scroller]);
  return <div ref={el} className="g-edge" data-edge={edge} aria-hidden="true" data-testid={tid} style={{ "--plateau": `${plateau}px` } as CSSProperties} />;
}

/** `edgeHard`: rgba(0,0,0,0.92) with a 0.5 px separator, under pinned section headers. */
export function HardEdge({ edge = "top", height = 44 }: { edge?: "top" | "bottom"; height?: number }) {
  return <div className="g-edge-hard" data-edge={edge} aria-hidden="true" style={{ height }} />;
}
