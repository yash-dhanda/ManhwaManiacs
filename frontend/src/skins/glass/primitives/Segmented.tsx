"use client";

import { motionValue } from "motion/react";
import { useCallback, useEffect, useLayoutEffect, useMemo, useRef, useState, type KeyboardEvent, type PointerEvent } from "react";
import { GlassHostContext, GlassSurface } from "../glass/GlassSurface";
import { haptic } from "../haptics";
import { isGlassReduced, play } from "../motion";
import { createTracker } from "../physics/tracker";
import { Spinner } from "./Progress";
import { boundariesCrossed, dropletStretch, keyTarget, nearestSegment, releaseSegment, segmentEdges, segmentWidths } from "./segmented-math";
import { useContext } from "react";
import { useGlassReduced } from "../motion";

export interface SegmentOption { value: string; label: string; disabled?: boolean }
export interface SegmentedProps {
  options: readonly SegmentOption[];
  value: string;
  onChange: (value: string) => void;
  /** switches panels: tablist/tab instead of radiogroup/radio */
  as?: "radio" | "tabs";
  orientation?: "horizontal" | "vertical";
  /** 32 tall inside sheets */
  compact?: boolean;
  disabled?: boolean;
  /** the selected label is replaced by a spinner while its data loads */
  loading?: boolean;
  /** the thumb springs back to the previous segment on `tick`; the caller shows a toast */
  error?: boolean;
  label: string;
  /** gallery: draw the drag glass */
  forceDragging?: boolean;
  "data-testid"?: string;
}

/**
 * Track fill3 (wellOnGlass inside T4/T5 glass), 2 px padding, a surface3 thumb. Tapping moves the thumb on `tab`; dragging it
 * turns it into TRANSIENT glass (one live T1 clear surface, in the budget only while dragged), following on `track`,
 * stretching, a `select` haptic at every boundary; release projects to the nearest segment. Vertical: the clear droplet is a
 * content twin (never a second backdrop read).
 */
export function Segmented({ options, value, onChange, as = "radio", orientation = "horizontal", compact, disabled, loading, error, label, forceDragging, "data-testid": tid }: SegmentedProps) {
  if (process.env.NODE_ENV !== "production" && (options.length < 2 || options.length > 5)) throw new Error("Segmented holds 2 to 5 segments; more must be a menu");
  const vertical = orientation === "vertical";
  const onGlass = useContext(GlassHostContext);
  const reduced = useGlassReduced();
  const track = useRef<HTMLDivElement>(null);
  const thumb = useRef<HTMLDivElement>(null);
  const [widths, setWidths] = useState<number[]>(() => options.map(() => 100));
  const [dragging, setDragging] = useState(false);
  const idx = Math.max(0, options.findIndex((o) => o.value === value));
  const pos = useMemo(() => motionValue(0), []);
  const size = useMemo(() => motionValue(0), []);
  const tracker = useRef(createTracker(vertical ? "y" : "x"));
  const drag = useRef({ active: false, from: 0, last: 0 });
  const moved = useRef(false);

  const edges = useMemo(() => segmentEdges(widths), [widths]);
  const measure = useCallback(() => {
    const t = track.current;
    if (!t) return;
    const inner = (vertical ? t.clientHeight : t.clientWidth) - 4;
    const buttons = Array.from(t.querySelectorAll<HTMLElement>("[data-seg]"));
    const w = vertical ? options.map(() => inner / options.length) : segmentWidths(buttons.map((b) => b.querySelector("span")?.scrollWidth ?? 60), inner);
    setWidths((old) => (old.length === w.length && old.every((v, i) => Math.abs(v - w[i]) < 0.5) ? old : w));
  }, [options, vertical]);
  useLayoutEffect(measure, [measure]);
  useEffect(() => { const t = track.current; if (!t) return; const ro = new ResizeObserver(measure); ro.observe(t); return () => ro.disconnect(); }, [measure]);

  const write = useCallback(() => {
    const el = thumb.current;
    if (!el) return;
    const v = pos.getVelocity();
    const { sx, sy } = dropletStretch(v);
    const s = isGlassReduced() ? { sx: 1, sy: 1 } : vertical ? { sx: sy, sy: sx } : { sx, sy };
    el.style.transform = vertical ? `translateY(${pos.get()}px) scale(${s.sx}, ${s.sy})` : `translateX(${pos.get()}px) scale(${s.sx}, ${s.sy})`;
  }, [pos, vertical]);
  useEffect(() => pos.on("change", write), [pos, write]);
  useEffect(() => size.on("change", () => { const el = thumb.current; if (el) el.style[vertical ? "height" : "width"] = `${size.get()}px`; }), [size, vertical]);

  // move the thumb when the selection (or measured widths) change
  const placed = useRef(false);
  useLayoutEffect(() => {
    if (drag.current.active) return;
    const target = edges[idx] ?? 0;
    const w = widths[idx] ?? 0;
    if (!placed.current) { pos.set(target); size.set(w); placed.current = true; write(); return; }
    const a = play("tabDroplet", pos, target);
    const b = play("tabDroplet", size, w);
    return () => { a.stop(); b.stop(); };
  }, [idx, edges, widths, pos, size, write]);

  // error: the thumb springs back to the segment it left, on `tick`
  const prev = useRef({ cur: idx, before: idx });
  useLayoutEffect(() => { if (prev.current.cur !== idx) prev.current = { cur: idx, before: prev.current.cur }; }, [idx]);
  useEffect(() => {
    if (!error || prev.current.before === prev.current.cur) return;
    const a = play("countPop", pos, edges[prev.current.before] ?? 0);
    const b = play("countPop", size, widths[prev.current.before] ?? 0);
    return () => { a.stop(); b.stop(); };
  }, [error, edges, widths, pos, size]);

  const select = (i: number) => { if (i !== idx && !options[i].disabled) { haptic("select"); onChange(options[i].value); } };
  const onDown = (e: PointerEvent<HTMLDivElement>) => {
    if (disabled || loading) return;
    const t = thumb.current;
    if (!t) return;
    const r = t.getBoundingClientRect();
    if (e.clientX < r.left || e.clientX > r.right || e.clientY < r.top || e.clientY > r.bottom) return;
    pos.stop();
    tracker.current = createTracker(vertical ? "y" : "x");
    tracker.current.start(e, pos.get());
    drag.current = { active: true, from: pos.get(), last: pos.get() };
  };
  const onMove = (e: PointerEvent<HTMLDivElement>) => {
    if (!drag.current.active) return;
    const off = tracker.current.move(e);
    if (off === null) return;
    if (!dragging) { setDragging(true); moved.current = true; e.currentTarget.setPointerCapture(e.pointerId); }
    const max = (edges[edges.length - 1] ?? 0) + (widths[widths.length - 1] ?? 0) - (widths[idx] ?? 0);
    const x = Math.max(0, Math.min(max, off));
    const c0 = drag.current.last + (widths[idx] ?? 0) / 2, c1 = x + (widths[idx] ?? 0) / 2;
    for (let n = boundariesCrossed(c0, c1, widths); n > 0; n--) haptic("select");
    drag.current.last = x;
    play("stretch", pos, x);
  };
  const onUp = () => {
    if (!drag.current.active) return;
    drag.current.active = false;
    setTimeout(() => { const m = moved.current; moved.current = false; return m; }, 0);
    if (!moved.current) { tracker.current.end(); return; }
    const { offset, velocity } = tracker.current.end();
    setDragging(false);
    const c = offset + (widths[idx] ?? 0) / 2;
    const to = releaseSegment(c, velocity, widths);
    if (to !== idx && !options[to].disabled) { haptic("select"); onChange(options[to].value); }
    else play("tabDroplet", pos, edges[idx] ?? 0, { velocity });
  };
  const roving = useRef<(HTMLButtonElement | null)[]>([]);
  const onKey = (e: KeyboardEvent<HTMLDivElement>) => {
    const t = keyTarget(e.key, idx, options.length, vertical);
    if (t === null) return;
    e.preventDefault();
    roving.current[t]?.focus();
    select(t);
  };
  void nearestSegment;
  const glassOn = dragging || forceDragging;
  return (
    <div
      ref={track} className="g-seg" data-orientation={orientation} data-compact={compact ? "" : undefined} data-disabled={disabled ? "" : undefined} data-well={onGlass ? "glass" : undefined} data-error={error ? "" : undefined} data-testid={tid}
      role={as === "tabs" || vertical ? "tablist" : "radiogroup"} aria-label={label} aria-orientation={vertical ? "vertical" : undefined} aria-disabled={disabled ? true : undefined}
      onPointerDown={onDown} onPointerMove={onMove} onPointerUp={onUp} onPointerCancel={onUp} onKeyDown={onKey}
    >
      <div ref={thumb} className="g-seg__thumb" data-cursor="grab" data-dragging={glassOn ? "" : undefined} data-clear={vertical ? "" : undefined} aria-hidden="true">
        {glassOn && !vertical ? <GlassSurface tier="t1" finish="clear" capsule materialize={false} layer="controls" className="g-seg__glass" aria-label="segment drag glass" /> : null}
        {vertical ? <GlassSurface twin="content" tier="t1" finish="clear" capsule materialize={false} className="g-seg__glass" /> : null}
      </div>
      {options.map((o, i) => {
        const selected = i === idx;
        const tabs = as === "tabs" || vertical;
        return (
          <button
            key={o.value} ref={(el) => { roving.current[i] = el; }} type="button" data-seg="" data-selected={selected ? "" : undefined} data-press="content" style={{ [vertical ? "height" : "width"]: widths[i] }}
            role={tabs ? "tab" : "radio"} aria-selected={tabs ? selected : undefined} aria-checked={tabs ? undefined : selected} tabIndex={selected ? 0 : -1} disabled={disabled || o.disabled}
            onClick={() => { if (moved.current) { moved.current = false; return; } select(i); }}
          >
            <span className="g-label">{loading && selected ? <Spinner size={16} /> : o.label}</span>
          </button>
        );
      })}
    </div>
  );
  void reduced;
}
