"use client";
// STUB (interface frozen; the progress agent replaces the body).
import type { CSSProperties } from "react";

export type LiquidTone = "iris" | "success" | "warning" | "danger";

/**
 * A liquid level that fills its nearest positioned ancestor (position:absolute; inset:0; inherits the capsule's radius;
 * overflow hidden; pointer-events none; aria-hidden). `value` 0..1, left to right, on `lens` with a 3 px meniscus.
 * Reduced motion: the level jumps. Standalone (labelled, role="progressbar") use is `Progress kind="liquid"`.
 */
export function LiquidProgress({ value, tone = "iris", className, style }: { value: number; tone?: LiquidTone; className?: string; style?: CSSProperties }) {
  return <span className={`g-liquid${className ? ` ${className}` : ""}`} data-tone={tone} aria-hidden="true" style={{ "--v": value, ...style } as CSSProperties} />;
}
