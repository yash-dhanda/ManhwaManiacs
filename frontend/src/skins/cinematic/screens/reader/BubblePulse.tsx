"use client";

import { useEffect, useState } from "react";
import type { PageBox } from "@/features/ocr/still-crop";
import { prefersReducedMotion } from "../kit/motion";
import { toast } from "../kit/Kit";

/**
 * A 2 px `spot` frame around the matched bubble, pulsed twice for 480 ms each
 * (once, static, for 960 ms under reduced motion). Mount it INSIDE the page's
 * positioned element; `box` is in page fractions. Plays once, then removes itself.
 */
export function BubblePulse({ box, onDone }: { box: PageBox; onDone?: () => void }) {
  const [gone, setGone] = useState(false);
  const reduced = prefersReducedMotion();
  useEffect(() => {
    const t = setTimeout(() => {
      setGone(true);
      onDone?.();
    }, 960);
    return () => clearTimeout(t);
  }, [onDone]);
  if (gone) return null;
  return (
    <>
      <style>{`@keyframes mm-bubble-pulse{0%,100%{opacity:0}50%{opacity:1}}`}</style>
      <span
        aria-hidden
        style={{
          position: "absolute",
          left: `${box.x * 100}%`,
          top: `${box.y * 100}%`,
          width: `${box.w * 100}%`,
          height: `${box.h * 100}%`,
          border: "2px solid var(--mm-color-spot)",
          pointerEvents: "none",
          opacity: reduced ? 1 : 0,
          animation: reduced ? undefined : "mm-bubble-pulse 480ms var(--mm-ease-settle) 2",
        }}
      />
    </>
  );
}

/** The toast that follows a dialogue jump ("Found on page 12." / the chapter-start fallback). */
export function announceDialogueJump(page: number | null) {
  toast(page !== null ? `Found on page ${page}.` : "Opened at the chapter start. The line is in this chapter.");
}
