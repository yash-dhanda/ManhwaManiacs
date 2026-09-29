"use client";

import { motion, useMotionValue } from "motion/react";
import { useCallback, useEffect, useRef, useState } from "react";
import { GlassSurface } from "../glass/GlassSurface";
import { haptic } from "../haptics";
import { announce } from "./announce";
import { springOrJump } from "./overlay-utils";
import { Spinner } from "./Progress";
import { clamp, overshoot, pxToValue, sliderKey, snapToStep, valueToPx } from "./slider-math";
import { shake } from "./shake";
import type { ForcedControlState } from "./Switch";

export interface SliderProps {
  value: number;
  min?: number;
  max?: number;
  step?: number;
  /** fires on every change while dragging (a live preview) */
  onChange?: (v: number) => void;
  /** fires on release or a key press: the value to save. May return a promise; if it rejects the thumb springs back to the last saved value */
  onCommit?: (v: number) => void | Promise<void>;
  label: string;
  format?: (v: number) => string;
  disabled?: boolean;
  loading?: boolean;
  forceState?: ForcedControlState;
  "data-testid"?: string;
}

/**
 * Track 6 px `fill1`, fill `iris500`, a 28 px white thumb in a 44 px hit. While dragged the thumb becomes transient glass, grows
 * to 34 px on `press` and the track thickens to 8 px. Stepped sliders tick per step and magnetise within 30 % of the spacing;
 * past the ends the thumb rubber-bands at most 12 px.
 */
export function Slider({ value, min = 0, max = 100, step = 1, onChange, onCommit, label, format, disabled, loading, forceState, "data-testid": tid }: SliderProps) {
  const off = disabled || forceState === "disabled";
  const busy = loading || forceState === "loading";
  const rail = useRef<HTMLDivElement | null>(null);
  const len = useRef(1);
  const tx = useMotionValue(0);
  const [drag, setDrag] = useState(false);
  const [live, setLive] = useState(value);
  const [error, setError] = useState(false);
  const saved = useRef(value);
  const st = useRef({ id: -1, index: -999, limit: false, x0: 0 });

  const measure = useCallback(() => { len.current = Math.max(1, (rail.current?.clientWidth ?? 1) - 28); }, []);
  useEffect(() => {
    measure();
    const ro = new ResizeObserver(() => { measure(); if (!drag) tx.set(valueToPx(value, min, max, len.current)); });
    if (rail.current) ro.observe(rail.current);
    return () => ro.disconnect();
  }, [drag, max, measure, min, tx, value]);
  useEffect(() => { if (!drag) { saved.current = value; setLive(value); springOrJump(tx, valueToPx(value, min, max, len.current), "track"); } }, [value, drag, min, max, tx]);

  const commit = async (v: number) => {
    const prev = saved.current;
    try { await onCommit?.(v); saved.current = v; }
    catch {
      springOrJump(tx, valueToPx(prev, min, max, len.current), "tick");
      setLive(prev); onChange?.(prev);
      shake(rail.current, 6); announce(`Couldn't save ${label}`);
      setError(true); setTimeout(() => setError(false), 2000);
    }
  };

  const at = (clientX: number) => {
    const r = rail.current!.getBoundingClientRect();
    const px = clientX - r.left - 14;
    const raw = pxToValue(px, min, max, len.current);
    return { px, raw };
  };
  const apply = (clientX: number) => {
    const { px, raw } = at(clientX);
    const s = snapToStep(raw, min, max, step);
    const before = st.current.index;
    if (s.index !== before) { if (before !== -999) haptic("detent.tick"); st.current.index = s.index; }
    const past = px < 0 ? -px : px > len.current ? px - len.current : 0;
    if (past > 0 && !st.current.limit) { st.current.limit = true; haptic("detent.limit"); }
    if (past === 0) st.current.limit = false;
    const disp = s.magnet ? s.value : clamp(raw, min, max);
    const extra = past > 0 ? overshoot(past, len.current) * (px < 0 ? -1 : 1) : 0;
    tx.set(valueToPx(disp, min, max, len.current) + extra);
    setLive(s.value);
    onChange?.(s.value);
  };

  const down = (e: React.PointerEvent<HTMLDivElement>) => {
    if (off || busy || (e.pointerType === "mouse" && e.button !== 0)) return;
    st.current = { id: e.pointerId, index: snapToStep(value, min, max, step).index, limit: false, x0: e.clientX };
    try { e.currentTarget.setPointerCapture(e.pointerId); } catch { /* synthetic */ }
    setDrag(true);
    apply(e.clientX);
  };
  const move = (e: React.PointerEvent<HTMLDivElement>) => { if (drag && e.pointerId === st.current.id) apply(e.clientX); };
  const up = (e: React.PointerEvent<HTMLDivElement>) => {
    if (!drag || e.pointerId !== st.current.id) return;
    setDrag(false);
    const { raw } = at(e.clientX);
    const v = snapToStep(raw, min, max, step).value;
    springOrJump(tx, valueToPx(v, min, max, len.current), "track");
    setLive(v);
    void commit(v);
  };
  const cancel = () => { setDrag(false); springOrJump(tx, valueToPx(saved.current, min, max, len.current), "track"); setLive(saved.current); };

  const onKey = (e: React.KeyboardEvent) => {
    if (off || busy) return;
    const n = sliderKey(live, e.key, min, max, step);
    if (n === null) return;
    e.preventDefault();
    if (n !== live) haptic("detent.tick");
    setLive(n); onChange?.(n); void commit(n);
  };

  const text = format ? format(live) : String(live);
  const shown = drag || forceState === "pressed";
  return (
    <div className="g-slider" data-drag={shown ? "" : undefined} data-force={forceState} data-error={error || forceState === "error" ? "" : undefined} data-disabled={off ? "" : undefined} data-testid={tid}>
      <div ref={rail} className="g-slider__rail" data-cursor="grab" data-dragging={shown ? "" : undefined} onPointerDown={down} onPointerMove={move} onPointerUp={up} onPointerCancel={cancel}>
        <span className="g-slider__track"><motion.span className="g-slider__fill" style={{ width: tx }} /></span>
        <motion.div
          role="slider"
          tabIndex={off ? -1 : 0}
          aria-label={label}
          aria-valuemin={min}
          aria-valuemax={max}
          aria-valuenow={live}
          aria-valuetext={text}
          aria-disabled={off || undefined}
          aria-busy={busy || undefined}
          className="g-slider__thumb"
          style={{ x: tx }}
          onKeyDown={onKey}
        >
          {shown ? (
            <span className="g-slider__glassThumb"><GlassSurface tier="t1" finish="clear" capsule layer="controls" materialize={false} className="g-slider__glass" /></span>
          ) : <span className="g-slider__knob" />}
          {shown ? <span className="g-slider__bubble"><GlassSurface tier="t2" capsule layer="hud" materialize={false} className="g-slider__bubbleGlass"><span className="g-slider__bubbleText">{text}</span></GlassSurface></span> : null}
        </motion.div>
      </div>
      <span className="g-slider__value" aria-hidden="true">{busy ? <Spinner size={12} /> : text}</span>
    </div>
  );
}
