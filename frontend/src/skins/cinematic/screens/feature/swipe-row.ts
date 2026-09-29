"use client";

import { useRef, useState } from "react";

const SLAB = 72;

/**
 * Phone row gestures (§8.17 D3): a left swipe pulls a 72 px slab; releasing
 * past half of it commits; the row springs back on `spring.release`
 * (reduced motion: a 150 ms fade). Holding 450 ms without moving opens the menu.
 */
export function useSwipeRow({ onCommit, onLongPress, enabled }: { onCommit: () => void; onLongPress: () => void; enabled: boolean }) {
  const [dx, setDx] = useState(0);
  const [releasing, setReleasing] = useState(false);
  const start = useRef<{ x: number; y: number } | null>(null);
  const long = useRef<ReturnType<typeof setTimeout> | null>(null);
  const moved = useRef(false);
  const clear = () => {
    if (long.current) clearTimeout(long.current);
    long.current = null;
  };
  const reduce = () => typeof window !== "undefined" && window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  const handlers = {
    onTouchStart: (e: React.TouchEvent) => {
      start.current = { x: e.touches[0].clientX, y: e.touches[0].clientY };
      moved.current = false;
      setReleasing(false);
      long.current = setTimeout(() => {
        if (!moved.current) onLongPress();
      }, 450);
    },
    onTouchMove: (e: React.TouchEvent) => {
      if (!start.current) return;
      const mx = e.touches[0].clientX - start.current.x;
      const my = e.touches[0].clientY - start.current.y;
      if (Math.abs(mx) > 8 || Math.abs(my) > 8) {
        moved.current = true;
        clear();
      }
      if (enabled && Math.abs(mx) > Math.abs(my) && mx < 0) setDx(Math.max(mx, -SLAB));
    },
    onTouchEnd: () => {
      clear();
      if (dx <= -SLAB / 2 && enabled) onCommit();
      setReleasing(true);
      setDx(0);
      start.current = null;
    },
    onTouchCancel: () => {
      clear();
      setReleasing(true);
      setDx(0);
    },
  };
  const style: React.CSSProperties = {
    transform: dx ? `translateX(${dx}px)` : undefined,
    transition: releasing
      ? reduce()
        ? "transform 150ms linear"
        : "transform var(--mm-spring-release-ms) var(--mm-spring-release)"
      : "none",
  };
  return { dx, handlers, style, swiping: dx < 0, slab: SLAB };
}
