"use client";
import { useEffect, useRef } from "react";
import { haptic } from "../haptics";
import { FolioFlip } from "./FolioFlip";
import { Glyph } from "./glyphs";

/** §7.21 stepper: - value + as two 36 px ruled icon buttons around a folio value; hold repeats every 120 ms after 400 ms. */
export function Stepper({ value, onChange, min, max, step = 1, label, unit = "", ...rest }: {
  value: number; onChange: (n: number) => void; min: number; max: number; step?: number; label: string; unit?: string; "data-gallery"?: string;
}) {
  const latest = useRef(value);
  useEffect(() => { latest.current = value; }, [value]);
  const timers = useRef<{ t?: ReturnType<typeof setTimeout>; i?: ReturnType<typeof setInterval> }>({});
  const stop = () => { clearTimeout(timers.current.t); clearInterval(timers.current.i); };
  useEffect(() => stop, []);
  const bump = (dir: 1 | -1) => {
    const next = Math.min(max, Math.max(min, latest.current + dir * step));
    if (next === latest.current) { stop(); return; }
    latest.current = next; haptic("select"); onChange(next);
  };
  const hold = (dir: 1 | -1) => ({
    onPointerDown: (e: React.PointerEvent) => { if (e.button !== 0) return; stop(); timers.current.t = setTimeout(() => { timers.current.i = setInterval(() => bump(dir), 120); }, 400); },
    onPointerUp: stop, onPointerLeave: stop, onPointerCancel: stop,
  });
  return (
    <div role="group" aria-label={label} data-gallery={rest["data-gallery"]} className="inline-flex items-center gap-2"
      onKeyDown={(e) => { if (e.key === "ArrowUp") { e.preventDefault(); bump(1); } else if (e.key === "ArrowDown") { e.preventDefault(); bump(-1); } }}>
      <StepButton label={`Decrease ${label}`} glyph="minus" disabled={value <= min} onClick={() => bump(-1)} {...hold(-1)} />
      <span role="status" className="inline-flex min-w-16 items-center justify-center text-ink-100">
        <FolioFlip value={value} label={`${label}, ${value}${unit}`} />{unit ? <span aria-hidden className="type-folio-lg">{unit}</span> : null}
      </span>
      <StepButton label={`Increase ${label}`} glyph="plus" disabled={value >= max} onClick={() => bump(1)} {...hold(1)} />
    </div>
  );
}

function StepButton({ label, glyph, disabled, onClick, ...rest }: { label: string; glyph: "minus" | "plus"; disabled: boolean; onClick: () => void } & React.HTMLAttributes<HTMLButtonElement>) {
  return (
    <button type="button" aria-label={label} aria-disabled={disabled || undefined} {...rest}
      onClick={() => { if (!disabled) onClick(); }}
      className="group inline-flex min-h-(--mm-hit-min) min-w-(--mm-hit-min) items-center justify-center">
      <span className={`inline-flex size-9 items-center justify-center border ${disabled ? "border-rule-1 text-ink-30" : "border-rule-2 text-ink-60 group-hover:border-ink-100 group-hover:text-ink-100"}`}><Glyph name={glyph} size={20} /></span>
    </button>
  );
}
