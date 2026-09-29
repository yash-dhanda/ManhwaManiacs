"use client";

import { Popover } from "@base-ui/react/popover";
import { motion, useMotionValue } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { GlassSurface } from "../glass/GlassSurface";
import { haptic } from "../haptics";
import { play } from "../motion";
import { Chip } from "./Chip";
import { springOrJump, useGlassHost } from "./overlay-utils";
import {
  DIAL_MAX, DIAL_MIN, DIAL_PRESETS, DIAL_PX_PER_STEP, DIAL_STEP, dialKey, dialMagnet, dialRawFromDrag, dialTicked, dialValueFromDrag, overshoot,
} from "./slider-math";

const MARKS = [0.5, 1, 1.5, 2, 2.5, 3] as const;
const TRACK_H = 240 - 56;
const yOfValue = (v: number) => ((DIAL_MAX - v) / (DIAL_MAX - DIAL_MIN)) * TRACK_H;
const fmt = (v: number) => `${(Math.round(v * 100) / 100).toString()}×`;

export interface SpeedDialProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  anchor: HTMLElement | null;
  value: number;
  /** commits on release (or a key, or a preset) */
  onChange: (v: number) => void;
  /** a live preview while dragging */
  onPreview?: (v: number) => void;
  /** the words-per-minute equivalent shown under the value */
  wpmAt: (speed: number) => number;
  "data-testid"?: string;
}

/**
 * A vertical glass capsule, 64 x 240, rising out of its anchor on `morph`. Dragging anywhere on it sets 0.5x to 3.0x in 0.05 steps
 * (6 px per step), `detent.tick` every 0.25x, a magnet at 1.0x (within 0.08), a 12 px rubber band past the ends. Touch-and-hold for
 * 600 ms without moving resets to 1.0x. An anchored picker: no URL state.
 */
export function SpeedDial({ open, onOpenChange, anchor, value, onChange, onPreview, wpmAt, "data-testid": tid }: SpeedDialProps) {
  const host = useGlassHost();
  const [live, setLive] = useState(value);
  const [drag, setDrag] = useState(false);
  const scale = useMotionValue(0.8);
  const rise = useMotionValue(0);
  const thumb = useMotionValue(yOfValue(value));
  const st = useRef({ id: -1, y0: 0, v0: value, held: false, moved: false, last: value, magnet: false, timer: undefined as ReturnType<typeof setTimeout> | undefined });

  // eslint-disable-next-line react-hooks/set-state-in-effect -- the controlled value re-syncs the thumb when not dragging
  useEffect(() => { if (!drag) { setLive(value); thumb.set(yOfValue(value)); } }, [value, drag, thumb]);
  useEffect(() => {
    if (!open) return;
    scale.set(0.85); rise.set(0);
    const a = play("bloom", scale, 1);
    return () => a.stop();
  }, [open, scale, rise]);

  const preview = (v: number, ticked: boolean, magnet: boolean) => {
    setLive(v); onPreview?.(v);
    if (magnet && !st.current.magnet) haptic("detent.magnet");
    st.current.magnet = magnet;
    if (ticked && !magnet) haptic("detent.tick");
    thumb.set(yOfValue(v));
  };
  const down = (e: React.PointerEvent<HTMLDivElement>) => {
    const s = st.current;
    s.id = e.pointerId; s.y0 = e.clientY; s.v0 = live; s.moved = false; s.last = live; s.magnet = false;
    try { e.currentTarget.setPointerCapture(e.pointerId); } catch { /* synthetic */ }
    setDrag(true);
    clearTimeout(s.timer);
    s.timer = setTimeout(() => { if (!s.moved) { haptic("detent.magnet"); preview(1, false, true); s.last = 1; onChange(1); setDrag(false); } }, 600);
  };
  const move = (e: React.PointerEvent<HTMLDivElement>) => {
    const s = st.current;
    if (!drag || e.pointerId !== s.id) return;
    const dy = e.clientY - s.y0;
    if (!s.moved && Math.abs(dy) < 4) return;
    s.moved = true;
    clearTimeout(s.timer);
    const raw = dialRawFromDrag(s.v0, dy);
    let v = dialValueFromDrag(s.v0, dy);
    const m = dialMagnet(v);
    v = m.value;
    const past = raw > DIAL_MAX ? ((raw - DIAL_MAX) / DIAL_STEP) * DIAL_PX_PER_STEP : raw < DIAL_MIN ? ((DIAL_MIN - raw) / DIAL_STEP) * DIAL_PX_PER_STEP : 0;
    if (past > 0 && s.last !== v) haptic("detent.limit");
    const ticked = dialTicked(s.last, v);
    if (v !== s.last || m.magnet !== s.magnet) preview(v, ticked, m.magnet);
    s.last = v;
    if (past > 0) thumb.set(yOfValue(v) + (raw > DIAL_MAX ? -1 : 1) * overshoot(past, TRACK_H));
  };
  const up = (e: React.PointerEvent<HTMLDivElement>) => {
    const s = st.current;
    if (!drag || e.pointerId !== s.id) return;
    clearTimeout(s.timer);
    setDrag(false);
    springOrJump(thumb, yOfValue(s.last), "track");
    if (s.moved) onChange(s.last);
  };
  const key = (e: React.KeyboardEvent) => {
    const n = dialKey(live, e.key);
    if (n === null) return;
    e.preventDefault();
    if (dialTicked(live, n)) haptic("detent.tick");
    setLive(n); thumb.set(yOfValue(n)); onChange(n);
  };

  if (!host) return null;
  const wpm = Math.round(wpmAt(live));
  return (
    <Popover.Root open={open} onOpenChange={onOpenChange} modal="trap-focus">
      <Popover.Portal container={host}>
        <Popover.Positioner anchor={anchor} side="top" sideOffset={12} className="g-dial-pos">
          <Popover.Popup
            className="g-dial"
            initialFocus={false}
            render={(p) => <motion.div {...(p as object)} style={{ scale, transformOrigin: "50% 100%" }} data-testid={tid ?? "speed-dial"} />}
          >
            <GlassSurface tier="t3" radius={32} layer="overlays" materialize={false} className="g-dial__glass">
              <div className="g-dial__inner">
                <div
                  role="slider"
                  tabIndex={0}
                  aria-label="Playback speed"
                  aria-orientation="vertical"
                  aria-valuemin={DIAL_MIN}
                  aria-valuemax={DIAL_MAX}
                  aria-valuenow={live}
                  aria-valuetext={`${live} times, about ${wpm} words a minute`}
                  className="g-dial__cap"
                  data-cursor="grab"
                  data-dragging={drag ? "" : undefined}
                  onPointerDown={down}
                  onPointerMove={move}
                  onPointerUp={up}
                  onPointerCancel={() => { clearTimeout(st.current.timer); setDrag(false); }}
                  onKeyDown={key}
                >
                  <span className="g-dial__value">{fmt(live)}</span>
                  <span className="g-dial__track">
                    {MARKS.map((m) => <span key={m} className="g-dial__mark" style={{ top: yOfValue(m) }}><i />{m}</span>)}
                    <motion.span className="g-dial__thumb" style={{ y: thumb }} />
                  </span>
                </div>
                <p className="g-dial__wpm">≈ {wpm} wpm</p>
                <div className="g-dial__presets" role="group" aria-label="Speed presets">
                  {DIAL_PRESETS.map((v) => <Chip key={v} kind="choice" label={`${v}`} selected={Math.abs(live - v) < 0.001} onPress={() => { setLive(v); thumb.set(yOfValue(v)); onChange(v); }} />)}
                </div>
              </div>
            </GlassSurface>
          </Popover.Popup>
        </Popover.Positioner>
      </Popover.Portal>
    </Popover.Root>
  );
}
