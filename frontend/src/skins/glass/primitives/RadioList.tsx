"use client";

import { useRef } from "react";
import { haptic } from "../haptics";
import { Icon } from "./Icon";

export interface RadioOption<T extends string = string> { value: T; label: string; description?: string; disabled?: boolean }

/** The 24 px Radio visual: off a 1.5 px g600 ring; on a 10 px white dot inside an iris600 disc, the dot growing on `tick`. For the gallery and select-mode lists. */
export function Radio({ checked }: { checked: boolean }) {
  return <span className="g-radio" data-checked={checked ? "" : undefined} aria-hidden="true"><span className="g-radio__dot" /></span>;
}

/** Radios appear only in lists: grouped rows with a trailing check glyph on the selected row. Arrows move the selection. */
export function RadioList<T extends string>({ options, value, onChange, label, "data-testid": tid }: { options: RadioOption<T>[]; value: T; onChange: (v: T) => void; label: string; "data-testid"?: string }) {
  const refs = useRef<(HTMLButtonElement | null)[]>([]);
  const enabled = options.map((o, i) => (o.disabled ? -1 : i)).filter((i) => i >= 0);
  const move = (from: number, dir: 1 | -1) => {
    const pos = enabled.indexOf(from);
    const next = enabled[(pos + dir + enabled.length) % enabled.length];
    haptic("select");
    onChange(options[next].value);
    refs.current[next]?.focus();
  };
  const tabbable = Math.max(0, options.findIndex((o) => o.value === value));
  return (
    <div role="radiogroup" aria-label={label} className="g-radiolist" data-testid={tid}>
      {options.map((o, i) => {
        const on = o.value === value;
        return (
          <button
            key={o.value}
            ref={(el) => { refs.current[i] = el; }}
            type="button"
            role="radio"
            aria-checked={on}
            disabled={o.disabled}
            tabIndex={i === tabbable ? 0 : -1}
            className="g-radiolist__row"
            data-checked={on ? "" : undefined}
            onClick={() => { if (!on) { haptic("select"); onChange(o.value); } }}
            onKeyDown={(e) => {
              if (e.key === "ArrowDown" || e.key === "ArrowRight") { e.preventDefault(); move(i, 1); }
              else if (e.key === "ArrowUp" || e.key === "ArrowLeft") { e.preventDefault(); move(i, -1); }
            }}
          >
            <span className="g-radiolist__label"><span>{o.label}</span>{o.description ? <small>{o.description}</small> : null}</span>
            {on ? <span className="g-disc g-radiolist__check" data-small=""><Icon name="check" size={16} color="var(--mm-color-iris400)" /></span> : null}
          </button>
        );
      })}
    </div>
  );
}
