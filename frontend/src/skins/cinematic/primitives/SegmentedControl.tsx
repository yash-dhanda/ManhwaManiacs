"use client";
import { useRef, type KeyboardEvent } from "react";
import { cn } from "@/lib/cn";
import { haptic } from "../haptics";
import { useCineReduced } from "../motion";
import { useSlideRule, type SlugItem } from "./SlugLines";
import { Tooltip } from "./Tooltip";

/** §7.5 `STRIP | SINGLE | DOUBLE`: labels divided by 1 px rules inside a 1 px rule.2 frame, 40 tall, the active segment's spot underline slides. */
export function SegmentedControl({ items, value, onChange, label }: { items: SlugItem[]; value: string; onChange: (id: string) => void; label: string }) {
  const reduced = useCineReduced();
  const { root, box } = useSlideRule(value);
  const btns = useRef<Record<string, HTMLButtonElement | null>>({});
  const key = (e: KeyboardEvent, i: number) => {
    if (e.key !== "ArrowRight" && e.key !== "ArrowLeft") return;
    e.preventDefault();
    const dir = e.key === "ArrowRight" ? 1 : -1;
    for (let k = 1; k <= items.length; k++) {
      const n = items[(i + dir * k + items.length * k) % items.length];
      if (!n.disabled) { onChange(n.id); btns.current[n.id]?.focus(); return; }
    }
  };
  return (
    <div ref={root} role="radiogroup" aria-label={label} className="relative inline-flex min-h-10 items-stretch border border-rule-2">
      {items.map((it, i) => {
        const on = it.id === value;
        const b = (
          <button ref={(el) => { btns.current[it.id] = el; }} type="button" data-slug-id={it.id} role="radio" aria-checked={on} aria-disabled={it.disabled || undefined}
            tabIndex={on ? 0 : -1} onKeyDown={(e) => key(e, i)} onClick={() => { if (it.disabled) return; haptic("select"); onChange(it.id); }}
            className={cn("type-nav relative min-h-(--mm-hit-min) min-w-(--mm-hit-min) px-4 transition-colors duration-(--mm-dur-beat) active:translate-y-px", i > 0 && "border-l border-rule-2", it.disabled ? "text-ink-30" : on ? "text-ink-100" : "text-ink-45 hover:text-ink-100")}>
            <span data-slug-label>{it.label}</span>
          </button>
        );
        return it.disabled && it.disabledReason ? <Tooltip key={it.id} label={it.disabledReason}>{b}</Tooltip> : <span key={it.id} className="contents">{b}</span>;
      })}
      {box ? <span aria-hidden className="pointer-events-none absolute bottom-1 left-0 h-0.5 bg-spot" style={{ width: box.w, transform: `translateX(${box.x}px)`, transition: reduced ? "none" : "transform 320ms var(--mm-ease-settle), width 320ms var(--mm-ease-settle)" }} /> : null}
    </div>
  );
}
