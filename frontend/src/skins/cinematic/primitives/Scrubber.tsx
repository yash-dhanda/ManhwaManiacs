"use client";
import { useRef } from "react";
import { haptic } from "../haptics";
import { playSound } from "../sounds";
import { Slider, type SliderProps } from "./Slider";

/**
 * §7.20 scrubber base: a Slider whose steps are pages. `onTick(page)` fires haptic `scrub.tick`; `onBoundary(chapter)`
 * fires `scrub.boundary` when the value crosses into a new chapter (`chapterOf` maps page -> chapter). The reader ruler
 * (web/12) and speed ruler (web/15) extend it.
 */
export function Scrubber({ chapterOf, onTick, onBoundary, ...p }: Omit<SliderProps, "format"> & {
  chapterOf?: (page: number) => number; onBoundary?: (chapter: number) => void; format?: (v: number) => string;
}) {
  const lastChapter = useRef(chapterOf?.(p.value));
  return (
    <Slider {...p} onTick={(v) => {
      haptic("scrub.tick"); playSound("scrub.tick"); onTick?.(v);
      const c = chapterOf?.(v);
      if (c !== undefined && c !== lastChapter.current) { lastChapter.current = c; haptic("scrub.boundary"); playSound("scrub.boundary"); onBoundary?.(c); }
    }} />
  );
}
