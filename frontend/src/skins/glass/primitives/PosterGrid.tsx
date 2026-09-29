"use client";

import type { CSSProperties, ReactNode } from "react";

/**
 * The one rule for every poster grid on tablet and desktop: repeat(auto-fill, minmax(var(--grid-min), 1fr)), gap 20 px
 * (12 px on phones). `--grid-min` 148 px on tablet, 152 px on desktop and wide at Comfortable, 112 px at Compact.
 * Content width W = min(viewport - sidebarOffset, 1440) - 2 x margin (sidebarOffset 304 expanded or 100 collapsed; margin 32
 * desktop, 40 wide) is exposed as `--grid-content-w` for screens.
 */
export function PosterGrid({ children, density = "comfortable", className, label }: { children: ReactNode; density?: "comfortable" | "compact"; className?: string; label?: string }) {
  return <div role="list" aria-label={label} className={`g-postergrid${className ? ` ${className}` : ""}`} data-density={density} style={{} as CSSProperties}>{children}</div>;
}

/** Pure: content width for a viewport (used by tests and screens that need columns). */
export function gridContentWidth(viewport: number, sidebar: "expanded" | "collapsed" = "collapsed"): number {
  const margin = viewport >= 1920 ? 40 : 32;
  return Math.min(viewport - (sidebar === "expanded" ? 304 : 100), 1440) - 2 * margin;
}
/** Pure: columns at Comfortable (152) or Compact (112) for a viewport. */
export function gridColumns(viewport: number, density: "comfortable" | "compact" = "comfortable", sidebar: "expanded" | "collapsed" = "collapsed"): number {
  const min = density === "compact" ? 112 : viewport < 1024 ? 148 : 152, gap = 20;
  return Math.max(1, Math.floor((gridContentWidth(viewport, sidebar) + gap) / (min + gap)));
}
