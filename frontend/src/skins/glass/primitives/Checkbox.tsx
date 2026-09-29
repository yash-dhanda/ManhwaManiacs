"use client";

import { useEffect, useRef, useState } from "react";
import { haptic } from "../haptics";
import { isGlassReduced } from "../motion";
import type { ForcedControlState } from "./Switch";
import { pop } from "./shake";

export interface CheckboxProps {
  checked: boolean | "mixed";
  onChange: (next: boolean) => void;
  label: string;
  disabled?: boolean;
  forceState?: ForcedControlState;
  "data-testid"?: string;
}

/** A 24 px squircle (radius 7): off fill1 with a 1.5 px g600 border; on an iris600 fill and a white check that draws over 160 ms while the box pops 1 to 1.12 to 1. Hit 44. */
export function Checkbox({ checked, onChange, label, disabled, forceState, "data-testid": tid }: CheckboxProps) {
  const box = useRef<HTMLSpanElement | null>(null);
  const [prev, setPrev] = useState(checked);
  const [drawKey, setDrawKey] = useState(0);
  if (prev !== checked) { setPrev(checked); if (checked === true) setDrawKey((k) => k + 1); }
  useEffect(() => { if (checked === true && drawKey > 0) pop(box.current, 1.12); }, [checked, drawKey]);
  const off = disabled || forceState === "disabled";
  return (
    <button
      type="button"
      role="checkbox"
      aria-checked={checked === "mixed" ? "mixed" : checked}
      aria-label={label}
      disabled={off}
      className="g-check"
      data-checked={checked === true ? "" : undefined}
      data-mixed={checked === "mixed" ? "" : undefined}
      data-force={forceState}
      data-testid={tid}
      onClick={() => { haptic(checked === true ? "toggle.off" : "toggle.on"); onChange(checked !== true); }}
    >
      <span ref={box} className="g-check__box">
        {checked === "mixed" ? <span className="g-check__bar" /> : checked ? (
          <svg key={drawKey} viewBox="0 0 24 24" width="24" height="24" aria-hidden="true" data-reduced={isGlassReduced() ? "" : undefined}>
            <path d="M6.5 12.5l3.6 3.6 7.4-8" fill="none" stroke="#fff" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round" pathLength={1} className="g-check__path" />
          </svg>
        ) : null}
      </span>
    </button>
  );
}
