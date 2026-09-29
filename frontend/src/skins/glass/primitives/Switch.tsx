"use client";

import { motion, useMotionValue, useTransform } from "motion/react";
import { useRef, useState, type CSSProperties } from "react";
import { GlassSurface } from "../glass/GlassSurface";
import { haptic } from "../haptics";
import { isGlassReduced } from "../motion";
import { project } from "../physics/project";
import { announce } from "./announce";
import { springOrJump } from "./overlay-utils";
import { Spinner } from "./Progress";
import { shake } from "./shake";

export type ForcedControlState = "hover" | "pressed" | "focus" | "disabled" | "loading" | "error";

const TRACK_W = 51, KNOB = 27, INSET = 2, TRAVEL = TRACK_W - KNOB - INSET * 2;

export interface SwitchProps {
  checked: boolean;
  /** may return a promise: while it runs the knob shows a spinner; if it rejects the knob springs back with the shake */
  onChange: (next: boolean) => void | Promise<void>;
  label: string;
  disabled?: boolean;
  loading?: boolean;
  forceState?: ForcedControlState;
  "data-testid"?: string;
}

/**
 * 51 x 31 track (off fill1, on iris600) in a 44 px hit, a 27 px white knob. A tap moves the knob on `tick`; dragging turns it into
 * transient glassFilm clear glass stretched to 34 x 27 that follows the finger and projects to on or off on release.
 */
export function Switch({ checked, onChange, label, disabled, loading, forceState, "data-testid": tid }: SwitchProps) {
  const off = disabled || forceState === "disabled";
  const busy = loading || forceState === "loading";
  const kx = useMotionValue(checked ? TRAVEL : 0);
  const [held, setHeld] = useState(false);
  const [dragging, setDragging] = useState(false);
  const [error, setError] = useState(false);
  const [pending, setPending] = useState(false);
  const [prev, setPrev] = useState(checked);
  const root = useRef<HTMLButtonElement | null>(null);
  const s = useRef({ x0: 0, k0: 0, moved: false, id: -1, samples: [] as { t: number; x: number }[] });

  // controlled: move the knob when `checked` changes from outside
  if (prev !== checked) { setPrev(checked); springOrJump(kx, checked ? TRAVEL : 0, "tick"); }

  const commit = async (next: boolean) => {
    if (next === checked) { springOrJump(kx, checked ? TRAVEL : 0, "tick"); return; }
    haptic(next ? "toggle.on" : "toggle.off");
    springOrJump(kx, next ? TRAVEL : 0, "tick");
    try {
      setPending(true);
      await onChange(next);
    } catch {
      springOrJump(kx, checked ? TRAVEL : 0, "tick");
      shake(root.current, 6);
      announce(`Couldn't change ${label}`);
      setError(true);
      setTimeout(() => setError(false), 2000);
    } finally { setPending(false); }
  };

  const down = (e: React.PointerEvent<HTMLButtonElement>) => {
    if (off || busy || pending || (e.pointerType === "mouse" && e.button !== 0)) return;
    const st = s.current;
    st.id = e.pointerId; st.x0 = e.clientX; st.k0 = kx.get(); st.moved = false; st.samples = [{ t: e.timeStamp, x: e.clientX }];
    try { e.currentTarget.setPointerCapture(e.pointerId); } catch { /* synthetic */ }
    setHeld(true);
  };
  const move = (e: React.PointerEvent<HTMLButtonElement>) => {
    const st = s.current;
    if (!held || e.pointerId !== st.id) return;
    st.samples.push({ t: e.timeStamp, x: e.clientX });
    while (st.samples.length > 2 && e.timeStamp - st.samples[0].t > 100) st.samples.shift();
    if (!st.moved && Math.abs(e.clientX - st.x0) < 4) return;
    st.moved = true;
    setDragging(true);
    kx.set(Math.min(TRAVEL, Math.max(0, st.k0 + e.clientX - st.x0)));
  };
  const up = (e: React.PointerEvent<HTMLButtonElement>) => {
    const st = s.current;
    if (!held || e.pointerId !== st.id) return;
    setHeld(false);
    setDragging(false);
    if (!st.moved) { void commit(!checked); return; }
    const a = st.samples[0], b = st.samples[st.samples.length - 1];
    const v = b && a && b.t > a.t ? ((b.x - a.x) / (b.t - a.t)) * 1000 : 0;
    void commit(project(kx.get(), v) > TRAVEL / 2);
  };
  const cancel = () => { setHeld(false); setDragging(false); springOrJump(kx, checked ? TRAVEL : 0, "tick"); };

  const stretch = held && !isGlassReduced();
  const width = useTransform(kx, () => (stretch ? 34 : KNOB));
  const x = useTransform(kx, (v) => INSET + v - (stretch && v > TRAVEL / 2 ? 34 - KNOB : 0));
  const st = forceState;
  return (
    <button
      ref={root}
      type="button"
      role="switch"
      aria-checked={checked}
      aria-label={label}
      aria-busy={busy || undefined}
      disabled={off}
      className="g-switch"
      data-checked={checked ? "" : undefined}
      data-held={held ? "" : undefined}
      data-force={st}
      data-error={error || st === "error" ? "" : undefined}
      data-loading={busy ? "" : undefined}
      data-cursor="grab"
      data-dragging={dragging ? "" : undefined}
      data-testid={tid}
      onPointerDown={down}
      onPointerMove={move}
      onPointerUp={up}
      onPointerCancel={cancel}
      onKeyDown={(e) => { if (e.key === " " || e.key === "Enter") { e.preventDefault(); if (!off && !busy && !pending) void commit(!checked); } }}
      style={{ "--sw-w": `${TRACK_W}px` } as CSSProperties}
    >
      <span className="g-switch__track" />
      {dragging ? (
        <motion.span className="g-switch__knob g-switch__knob--glass" style={{ x, width: 34 }}>
          <GlassSurface tier="t1" finish="clear" capsule layer="controls" className="g-switch__glass" materialize={false} />
        </motion.span>
      ) : (
        <motion.span className="g-switch__knob" style={{ x, width }}>{busy ? <Spinner size={12} /> : null}</motion.span>
      )}
    </button>
  );
}
