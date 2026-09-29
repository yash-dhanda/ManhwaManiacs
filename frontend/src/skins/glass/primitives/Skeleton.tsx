"use client";

import type { CSSProperties, ReactNode } from "react";

export type SkeletonShape = "poster" | "line" | "circle" | "card" | "block";

/**
 * Wet glass: aria-hidden, `surface2` with a 40 % wide sheen band sweeping every 1,400 ms (2,800 ms for AI skeletons), phase offset
 * 60 ms per `row` so the sheen travels down a list; appears only after 180 ms (a fast load never flashes one). Reduced motion: static.
 * Shapes and radii match the content they stand for.
 */
export function Skeleton({ shape = "block", width, height, radius, row = 0, ai, className, style }: { shape?: SkeletonShape; width?: number | string; height?: number | string; radius?: number | string; row?: number; ai?: boolean; className?: string; style?: CSSProperties }) {
  const base: CSSProperties = shape === "poster" ? { aspectRatio: "2 / 3", borderRadius: 14, width: width ?? "100%" } : shape === "circle" ? { borderRadius: 9999, width, height: height ?? width } : shape === "line" ? { height: height ?? 14, borderRadius: 7, width: width ?? "100%" } : shape === "card" ? { borderRadius: 26, width: width ?? "100%", height: height ?? 132 } : { width, height, borderRadius: 14 };
  return <span aria-hidden="true" className={`g-skel${className ? ` ${className}` : ""}`} data-ai={ai ? "" : undefined} data-shape={shape} style={{ ...base, ...(radius !== undefined ? { borderRadius: radius } : {}), "--sk-row": row, ...style } as CSSProperties} />;
}

/** The region a skeleton fills carries aria-busy. */
export function SkeletonRegion({ busy = true, children, className, label }: { busy?: boolean; children: ReactNode; className?: string; label?: string }) {
  return <div className={className} aria-busy={busy || undefined} aria-label={label}>{children}</div>;
}
