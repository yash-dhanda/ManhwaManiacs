/** §7.8 rail geometry, pure. Breakpoints match the theme: tablet 600, frame 768, desktop 1024, wide 1440, cinema 1920 (px). */
export type RailBreakpoint = "phone" | "tablet" | "desktop" | "wide" | "cinema";

export function railBreakpoint(viewportPx: number): RailBreakpoint {
  if (viewportPx >= 1920) return "cinema";
  if (viewportPx >= 1440) return "wide";
  if (viewportPx >= 1024) return "desktop";
  if (viewportPx >= 600) return "tablet";
  return "phone";
}

const VISIBLE: Record<RailBreakpoint, number> = { phone: 3.2, tablet: 5.2, desktop: 6.25, wide: 7.25, cinema: 8.25 };
const GAP: Record<RailBreakpoint, number> = { phone: 8, tablet: 12, desktop: 12, wide: 12, cinema: 16 };

/** Visible posters; the phone frame at root font size >= 130 % shows 2.3. */
export function visiblePosters(bp: RailBreakpoint, rootScale = 1): number {
  return bp === "phone" && rootScale >= 1.3 ? 2.3 : VISIBLE[bp];
}
export const railGap = (bp: RailBreakpoint) => GAP[bp];

/** (content width - floor(visible) x gap) / visible. */
export function posterWidth(contentWidth: number, bp: RailBreakpoint, rootScale = 1): number {
  const v = visiblePosters(bp, rootScale);
  return (contentWidth - Math.floor(v) * railGap(bp)) / v;
}

/** Paddles page by `visible - 1` posters. */
export const pageBy = (visible: number) => Math.max(1, Math.floor(visible) - 1);
