"use client";
// STUB (interface frozen by the lane lead; the progress agent replaces the bodies, never the exported signatures).
import type { CSSProperties } from "react";

export function Spinner({ size = 16, className }: { size?: 10 | 12 | 16 | 24; className?: string }) {
  return <span className={`g-spinner${className ? ` ${className}` : ""}`} data-size={size} style={{ width: size, height: size } as CSSProperties} aria-hidden="true" />;
}

/** three 5 px `onGlass` dots 6 px apart, each bobbing 3 px on `tick` 80 ms apart (button loading) */
export function Dots({ className }: { className?: string }) {
  return <span className={`g-dots${className ? ` ${className}` : ""}`} aria-hidden="true"><i /><i /><i /></span>;
}
