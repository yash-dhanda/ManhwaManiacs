"use client";
import { Slider as BaseSlider } from "@base-ui/react/slider";
import { useRef, useState, type ReactNode } from "react";
import { haptic } from "../haptics";

export type SliderProps = {
  value: number; onValueChange: (v: number) => void; min: number; max: number; step?: number;
  label: string;
  /** Text on the flag above the thumb while dragging ("1.25×", "19 px", "−40"). */
  format?: (v: number) => string;
  /** aria-valuetext ("Page 18 of 40"). */
  valueText?: (v: number) => string;
  minCaption?: ReactNode; maxCaption?: ReactNode;
  disabled?: boolean; className?: string;
  onTick?: (v: number) => void; onCommit?: (v: number) => void;
  "data-gallery"?: string;
};

/** §7.20: 2 px rule.2 track, ink.100 fill, 1 x 6 px step ticks (<= 20 steps), 2 x 20 thumb with a 44 px hit area and a folio flag while dragging. */
export function Slider({ value, onValueChange, min, max, step = 1, label, format = String, valueText, minCaption, maxCaption, disabled = false, className = "", onTick, onCommit, ...rest }: SliderProps) {
  const [drag, setDrag] = useState(false);
  const last = useRef(value);
  const ticks = (max - min) / step <= 20 ? Math.round((max - min) / step) + 1 : 0;
  return (
    <div className={className}>
      <BaseSlider.Root
        value={value} min={min} max={max} step={step} largeStep={step * 10} disabled={disabled} thumbAlignment="edge" data-gallery={rest["data-gallery"]}
        onValueChange={(v) => { const n = v as number; if (n !== last.current) { last.current = n; haptic("select"); onTick?.(n); } onValueChange(n); }}
        onValueCommitted={(v) => { setDrag(false); onCommit?.(v as number); }}
      >
        <BaseSlider.Control onPointerDown={() => setDrag(true)} className="relative flex min-h-(--mm-hit-min) w-full touch-none items-center select-none">
          <BaseSlider.Track className={`relative h-0.5 w-full ${disabled ? "bg-rule-1" : "bg-rule-2"}`}>
            <BaseSlider.Indicator className={disabled ? "bg-ink-30" : "bg-ink-100"} />
            {ticks > 1 ? (
              <span aria-hidden className="pointer-events-none absolute inset-x-0 top-1 flex justify-between">
                {Array.from({ length: ticks }, (_, i) => <span key={i} className="h-1.5 w-px bg-ink-30" />)}
              </span>
            ) : null}
            <BaseSlider.Thumb
              aria-label={label} getAriaValueText={valueText ? (_f, v) => valueText(v) : undefined}
              data-dragging={drag || undefined}
              className={`cine-thumb group relative flex size-(--mm-hit-min) items-center justify-center outline-none`}
            >
              <span aria-hidden className={`cine-thumb-bar block ${disabled ? "bg-ink-30" : "bg-ink-100"}`} />
              {drag && !disabled ? (
                <span aria-hidden className="type-folio absolute bottom-full mb-1 -translate-y-0 border border-ink-100 bg-paper-0 px-2 py-1 whitespace-nowrap text-ink-100">{format(value)}</span>
              ) : null}
            </BaseSlider.Thumb>
          </BaseSlider.Track>
        </BaseSlider.Control>
      </BaseSlider.Root>
      {minCaption || maxCaption ? <div className="type-caption flex justify-between text-ink-45"><span>{minCaption}</span><span>{maxCaption}</span></div> : null}
    </div>
  );
}
