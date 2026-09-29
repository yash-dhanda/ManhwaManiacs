"use client";
import { useRatingCard } from "./rating-card";

/** A slot at the top-left under the running head at `z.toast`. */
export function RatingCardHost() {
  const node = useRatingCard((s) => s.node);
  if (!node) return null;
  return <div data-rating-card-host className="fixed" style={{ top: "calc(var(--mm-running-head-h, 0px) + 16px)", left: "calc(var(--mm-sidebar-w, 0px) + max(var(--mm-grid-margin), 16px))", zIndex: "var(--mm-z-toast)" }}>{node}</div>;
}
