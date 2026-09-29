"use client";
import grain from "./assets/grain.png";
import { useOffscreenPause } from "./motion-components";

/** Film grain over art only (§2.1, §15.2): overlay blend at 6 % (5 % where §8 says so), 12 fps, static under reduced motion, paused off screen. */
export function Grain({ strength = 0.06, className = "" }: { strength?: 0.05 | 0.06; className?: string }) {
  const ref = useOffscreenPause<HTMLDivElement>();
  return (
    <div ref={ref} aria-hidden className={`cine-grain animate-grain pointer-events-none absolute inset-0 ${className}`}
      style={{ background: `url(${grain.src}) repeat`, mixBlendMode: "overlay", opacity: strength }} />
  );
}
