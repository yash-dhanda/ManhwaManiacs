"use client";

import { motion, useMotionValue } from "motion/react";
import { useEffect, useRef, useState, type ReactNode } from "react";
import { GlassSurface } from "../glass/GlassSurface";
import { haptic } from "../haptics";
import { isGlassReduced, play } from "../motion";
import { springOrJump } from "./overlay-utils";
import { clamp, pageAt } from "./slider-math";

export interface ScrubRailProps {
  pages: number;
  page: number;
  /** release (or a key): jump to this page */
  onCommit: (page: number) => void;
  /** every page change while dragging */
  onScrub?: (page: number) => void;
  /** page counts per chapter: the read-all rail is segmented with 2 px gaps and `scrub.boundary` fires at the seams */
  segments?: number[];
  /** bookmarked pages: 4 px droplets on the track */
  bookmarks?: number[];
  /** the lens content: the thumbnail at w=240 and the page number in monoLarge */
  renderPreview?: (page: number) => ReactNode;
  height?: number;
  "data-testid"?: string;
}

/** Segment boundaries as fractions of the rail (0 to 1), one per seam. */
export function seamFractions(segments: readonly number[]): number[] {
  const total = segments.reduce((a, b) => a + b, 0);
  let run = 0;
  return segments.slice(0, -1).map((n) => (run += n) / total);
}

/**
 * The reader rail: a vertical 44 px hit strip, a 3 px track (6 px on touch) with a 12 px thumb. On touch a magnifier lens
 * (glassThick, 120 x 164, radius 20) grows out of the thumb on `lens` and follows it on `track`. The thumb snaps page by page.
 */
export function ScrubRail({ pages, page, onCommit, onScrub, segments, bookmarks = [], renderPreview, height = 320, "data-testid": tid }: ScrubRailProps) {
  const rail = useRef<HTMLDivElement | null>(null);
  const y = useMotionValue(0);
  const lens = useMotionValue(0);
  const [drag, setDrag] = useState(false);
  const [touch, setTouch] = useState(false);
  const [cur, setCur] = useState(page);
  const st = useRef({ id: -1, page });
  const h = Math.max(1, height);
  const posOf = (p: number) => (pages <= 1 ? 0 : ((p - 1) / (pages - 1)) * h);
  useEffect(() => { if (!drag) { setCur(page); springOrJump(y, posOf(page), "track"); } }, [page, drag, pages, h]); // eslint-disable-line react-hooks/exhaustive-deps
  if (pages <= 1) return null; // a one-page chapter renders no rail

  const seams = segments ? seamFractions(segments) : [];
  const seamPages = seams.map((f) => Math.round(f * pages));
  const scrubTo = (clientY: number) => {
    const r = rail.current!.getBoundingClientRect();
    const p = pageAt(clamp((clientY - r.top) / r.height, 0, 1), pages);
    if (p !== st.current.page) {
      const crossed = seamPages.some((s) => (st.current.page <= s) !== (p <= s));
      haptic(p === 1 || p === pages || crossed ? "scrub.boundary" : "scrub.tick");
      st.current.page = p;
      setCur(p);
      onScrub?.(p);
      springOrJump(y, posOf(p), "track");
    }
  };
  const down = (e: React.PointerEvent<HTMLDivElement>) => {
    st.current = { id: e.pointerId, page: cur };
    try { e.currentTarget.setPointerCapture(e.pointerId); } catch { /* synthetic */ }
    const isTouch = e.pointerType === "touch";
    setTouch(isTouch); setDrag(true);
    if (isTouch) { lens.set(isGlassReduced() ? 0 : 0); play("scrubLens", lens, 1); }
    scrubTo(e.clientY);
  };
  const end = (commit: boolean) => {
    if (!drag) return;
    setDrag(false);
    play("scrubLens", lens, 0);
    springOrJump(y, posOf(st.current.page), "track");
    if (commit) onCommit(st.current.page);
  };
  const onKey = (e: React.KeyboardEvent) => {
    const map: Record<string, number> = { ArrowDown: 1, ArrowRight: 1, ArrowUp: -1, ArrowLeft: -1, PageDown: 10, PageUp: -10 };
    let n: number | null = null;
    if (e.key in map) n = clamp(cur + map[e.key], 1, pages);
    else if (e.key === "Home") n = 1;
    else if (e.key === "End") n = pages;
    if (n === null) return;
    e.preventDefault();
    if (n !== cur) { haptic(n === 1 || n === pages ? "scrub.boundary" : "scrub.tick"); setCur(n); onCommit(n); }
  };

  const bars = segments
    ? (() => { const total = segments.reduce((a, b) => a + b, 0); let run = 0; return segments.map((n) => { const top = (run / total) * 100; run += n; return { top, h: (n / total) * 100 }; }); })()
    : [{ top: 0, h: 100 }];
  return (
    <div
      ref={rail}
      role="slider"
      tabIndex={0}
      aria-label="Page"
      aria-orientation="vertical"
      aria-valuemin={1}
      aria-valuemax={pages}
      aria-valuenow={cur}
      aria-valuetext={`Page ${cur} of ${pages}`}
      className="g-scrub"
      data-cursor="ns-resize"
      data-touch={touch ? "" : undefined}
      data-dragging={drag ? "" : undefined}
      data-testid={tid}
      style={{ height: h }}
      onPointerDown={down}
      onPointerMove={(e) => { if (drag && e.pointerId === st.current.id) scrubTo(e.clientY); }}
      onPointerUp={() => end(true)}
      onPointerCancel={() => end(false)}
      onKeyDown={onKey}
    >
      {bars.map((b, i) => (
        <span key={i} className="g-scrub__seg" style={{ top: `calc(${b.top}% + ${i ? 1 : 0}px)`, height: `calc(${b.h}% - ${segments ? 2 : 0}px)` }} />
      ))}
      <motion.span className="g-scrub__fill" style={{ height: y }} />
      {bookmarks.filter((b) => b >= 1 && b <= pages).map((b) => <span key={b} className="g-scrub__mark" style={{ top: posOf(b) - 2 }} aria-hidden="true" />)}
      <motion.span className="g-scrub__thumb" style={{ y }} aria-hidden="true" />
      {drag && touch ? (
        <motion.div className="g-scrub__lens" style={{ y, scale: lens, opacity: lens }} aria-hidden="true">
          <GlassSurface tier="t4" radius={20} layer="overlays" materialize={false} className="g-scrub__lensGlass">
            <div className="g-scrub__preview">{renderPreview?.(cur)}<span className="g-scrub__num">{cur}</span></div>
          </GlassSurface>
        </motion.div>
      ) : null}
    </div>
  );
}
