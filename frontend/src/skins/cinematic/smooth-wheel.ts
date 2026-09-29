"use client";
import Lenis from "lenis";
import { useEffect } from "react";

/**
 * Lenis smooth wheel (§8.0.5): only on the desktop frame (768 px and up) with a fine pointer, never under reduced motion.
 * Created on mount, destroyed on unmount or when a condition changes. Only Tonight (web/08) and The Annual (web/21) call it.
 */
export function useSmoothWheel(): void {
  useEffect(() => {
    const mqs = [window.matchMedia("(min-width: 768px)"), window.matchMedia("(pointer: fine)"), window.matchMedia("(prefers-reduced-motion: reduce)")];
    let lenis: Lenis | null = null;
    const apply = () => {
      const on = mqs[0].matches && mqs[1].matches && !mqs[2].matches && document.documentElement.dataset.motion !== "reduced";
      if (on && !lenis) lenis = new Lenis({ autoRaf: true });
      else if (!on && lenis) { lenis.destroy(); lenis = null; }
    };
    apply();
    mqs.forEach((m) => m.addEventListener("change", apply));
    return () => { mqs.forEach((m) => m.removeEventListener("change", apply)); lenis?.destroy(); lenis = null; };
  }, []);
}
