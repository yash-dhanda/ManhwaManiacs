"use client";
import { useId, useRef, useState } from "react";
import { Icon } from "../Icon";
import { useTyped } from "./TypedHeadline";

/**
 * §7.4. `index`: Bodoni Moda Italic (type.field); the empty, unfocused placeholder is typed at 50 ms per character as an
 * aria-hidden visual layer while the input's real placeholder holds the same full string. `compact`: type.ui, leading magnifier.
 */
export function SearchField({ label, placeholder, value, onChange, variant = "index", onSubmitNow, onArrowDown, "data-gallery": gallery }: {
  label: string; placeholder: string; value: string; onChange: (v: string) => void; variant?: "index" | "compact";
  onSubmitNow?: (v: string) => void; onArrowDown?: () => void; "data-gallery"?: string;
}) {
  const id = useId();
  const ref = useRef<HTMLInputElement>(null);
  const [focused, setFocused] = useState(false);
  const typed = useTyped(placeholder);
  const showTyped = variant === "index" && !value && !focused;
  const idx = variant === "index";
  return (
    <div className="group relative flex items-end gap-2 pb-2" style={{ minHeight: idx ? 56 : 44 }}>
      {!idx ? <span className="pb-1 text-ink-60"><Icon name="search" size={20} /></span> : null}
      <div className="relative min-w-0 flex-1">
        {showTyped ? (
          <span aria-hidden className={`pointer-events-none absolute inset-0 flex items-end text-ink-45 ${idx ? "type-field" : "type-ui"}`}>
            <span>{typed.shown}</span><span style={{ color: "transparent" }}>{typed.rest}</span>
          </span>
        ) : null}
        <input ref={ref} id={id} data-gallery={gallery} data-typed-placeholder={showTyped} type="search" role="searchbox" aria-label={label} value={value} placeholder={placeholder}
          onChange={(e) => onChange(e.target.value)} onFocus={() => setFocused(true)} onBlur={() => setFocused(false)}
          onKeyDown={(e) => {
            if (e.key === "Escape") { if (value) { onChange(""); e.stopPropagation(); } else ref.current?.blur(); }
            else if (e.key === "Enter") onSubmitNow?.(value);
            else if (e.key === "ArrowDown") { e.preventDefault(); onArrowDown?.(); }
          }}
          className={`w-full text-ink-100 outline-none ${idx ? (value ? "type-body" : "type-field") : "type-ui"}`}
          style={{ caretColor: "var(--mm-color-spot)", outline: "none", boxShadow: "none", ...(idx && value ? { fontFamily: "var(--font-display)", fontStyle: "normal", fontSize: "inherit" } : {}), ...(showTyped ? { color: "transparent" } : {}) }} />
      </div>
      {value ? <button type="button" onClick={() => { onChange(""); ref.current?.focus(); }} className="type-label min-h-(--mm-hit-min) px-1 text-ink-60 hover:text-ink-100 hover:underline hover:underline-offset-4">Clear</button> : null}
      <span aria-hidden className="absolute inset-x-0 bottom-0 h-px bg-rule-2" />
      <span aria-hidden className="absolute inset-x-0 bottom-0 h-0.5 origin-left bg-spot transition-transform duration-(--mm-dur-line) ease-settle" style={{ transform: `scaleX(${focused ? 1 : 0})` }} />
    </div>
  );
}
