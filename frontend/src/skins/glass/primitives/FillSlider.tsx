"use client";

import { motion, useMotionValue, useTransform } from "motion/react";
import { useEffect, useRef, useState } from "react";
import { GlassSurface } from "../glass/GlassSurface";
import { haptic } from "../haptics";
import { Icon } from "./Icon";
import { springOrJump } from "./overlay-utils";
import { clamp, sliderKey } from "./slider-math";

/**
 * Control Centre style: a 72 x 160 capsule that fills from the bottom with `onGlass` at 90 %, a glyph at the bottom. Drag anywhere;
 * the fill follows on `track`. Always on a glass host, so it draws as the fill2 twin.
 */
export function FillSlider({ value, onChange, label, icon = "sun", "data-testid": tid }: { value: number; onChange: (v: number) => void; label: string; icon?: "sun" | "speaker-high"; "data-testid"?: string }) {
  const box = useRef<HTMLDivElement | null>(null);
  const fill = useMotionValue(value);
  const [live, setLive] = useState(value);
  const [drag, setDrag] = useState(false);
  const id = useRef(-1);
  // eslint-disable-next-line react-hooks/set-state-in-effect -- the controlled value re-syncs the fill when not dragging
  useEffect(() => { if (!drag) { setLive(value); springOrJump(fill, value, "track"); } }, [value, drag, fill]);
  const set = (clientY: number) => {
    const r = box.current!.getBoundingClientRect();
    const v = clamp(1 - (clientY - r.top) / r.height, 0, 1);
    setLive(v); onChange(v); springOrJump(fill, v, "track");
    if (v === 0 || v === 1) haptic("detent.limit");
  };
  const h = useTransform(fill, (v) => `${(clamp(v, 0, 1) * 100).toFixed(2)}%`);
  return (
    <GlassSurface twin="onGlass" radius={36} layer="controls" materialize={false} className="g-fillslider" data-testid={tid}>
      <div
        ref={box}
        role="slider"
        tabIndex={0}
        aria-label={label}
        aria-orientation="vertical"
        aria-valuemin={0}
        aria-valuemax={100}
        aria-valuenow={Math.round(live * 100)}
        aria-valuetext={`${Math.round(live * 100)} percent`}
        className="g-fillslider__box"
        data-cursor="grab"
        data-dragging={drag ? "" : undefined}
        onPointerDown={(e) => { id.current = e.pointerId; try { e.currentTarget.setPointerCapture(e.pointerId); } catch { /* synthetic */ } setDrag(true); set(e.clientY); }}
        onPointerMove={(e) => { if (drag && e.pointerId === id.current) set(e.clientY); }}
        onPointerUp={() => setDrag(false)}
        onPointerCancel={() => setDrag(false)}
        onKeyDown={(e) => { const n = sliderKey(Math.round(live * 100), e.key, 0, 100, 5); if (n !== null) { e.preventDefault(); const v = n / 100; setLive(v); onChange(v); springOrJump(fill, v, "track"); haptic("detent.tick"); } }}
      >
        <motion.span className="g-fillslider__fill" style={{ height: h }} />
        <span className="g-fillslider__glyph"><Icon name={icon} size={24} weight="fill" /></span>
      </div>
    </GlassSurface>
  );
}
