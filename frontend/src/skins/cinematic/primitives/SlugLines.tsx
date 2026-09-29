"use client";
import { useLayoutEffect, useRef, useState, type KeyboardEvent } from "react";
import { cn } from "@/lib/cn";
import { haptic } from "../haptics";
import { useCineReduced } from "../motion";
import { Glyph } from "./glyphs";

export type SlugItem = { id: string; label: string; count?: number | null; disabled?: boolean; disabledReason?: string };

/** Measures the selected item so one underline can slide to it (Rule slide, 320 ms settle). */
export function useSlideRule(selectedId: string | undefined) {
  const root = useRef<HTMLDivElement>(null);
  const [box, setBox] = useState<{ x: number; w: number } | null>(null);
  useLayoutEffect(() => {
    const measure = () => {
      const el = selectedId ? root.current?.querySelector<HTMLElement>(`[data-slug-id="${CSS.escape(selectedId)}"] [data-slug-label]`) : null;
      const host = root.current;
      if (!el || !host) { setBox(null); return; }
      const a = el.getBoundingClientRect(), b = host.getBoundingClientRect();
      setBox({ x: a.left - b.left + host.scrollLeft, w: a.width });
    };
    measure();
    const ro = new ResizeObserver(measure);
    if (root.current) ro.observe(root.current);
    return () => ro.disconnect();
  }, [selectedId]);
  return { root, box };
}

/** §7.5 typographic toggles separated by middle dots. Single-select is a radiogroup with a sliding underline; multi-select uses aria-pressed and draws. */
export function SlugLines({ items, value, onChange, mode = "single", label, loading = false }: {
  items: SlugItem[]; value: string | string[]; onChange: (next: string) => void; mode?: "single" | "multi"; label: string; loading?: boolean;
}) {
  const reduced = useCineReduced();
  const selected = new Set(Array.isArray(value) ? value : [value]);
  const single = mode === "single";
  const { root, box } = useSlideRule(single ? [...selected][0] : undefined);
  const move = (e: KeyboardEvent, i: number) => {
    if (!single || (e.key !== "ArrowRight" && e.key !== "ArrowLeft")) return;
    e.preventDefault();
    const dir = e.key === "ArrowRight" ? 1 : -1;
    for (let k = 1; k <= items.length; k++) {
      const n = items[(i + dir * k + items.length * k) % items.length];
      if (!n.disabled) { onChange(n.id); (root.current?.querySelector<HTMLElement>(`[data-slug-id="${CSS.escape(n.id)}"]`))?.focus(); return; }
    }
  };
  return (
    <div ref={root} role={single ? "radiogroup" : "group"} aria-label={label} className="relative flex items-center overflow-x-auto whitespace-nowrap [mask-image:linear-gradient(to_right,#000_calc(100%-24px),transparent)] frame:flex-wrap frame:overflow-visible frame:[mask-image:none]">
      {items.map((it, i) => {
        const on = selected.has(it.id);
        const spoken = it.count != null ? `${it.label}, ${it.count}` : it.label;
        return (
          <span key={it.id} className="flex items-center">
            {i > 0 ? <span aria-hidden className="type-nav mx-3 text-ink-30">·</span> : null}
            <button type="button" data-slug-id={it.id} role={single ? "radio" : undefined} aria-checked={single ? on : undefined} aria-pressed={single ? undefined : on}
              aria-disabled={it.disabled || undefined} aria-label={spoken} title={it.disabled ? it.disabledReason : undefined}
              onKeyDown={(e) => move(e, i)} tabIndex={!single || on || selected.size === 0 ? 0 : -1}
              onClick={() => { if (it.disabled) return; haptic("select"); onChange(it.id); }}
              className={cn("type-nav relative inline-flex min-h-(--mm-hit-min) min-w-(--mm-hit-min) items-center justify-center px-3 transition-colors duration-(--mm-dur-beat) active:translate-y-px", it.disabled ? "text-ink-30" : on ? "text-ink-100" : "text-ink-45 hover:text-ink-100")}>
              <span data-slug-label className="relative inline-flex items-baseline gap-0.5">
                {it.label}
                {it.count !== undefined ? <span aria-hidden className="type-folio text-ink-45" style={{ fontSize: "0.72em", verticalAlign: "0.5em" }}>{loading || it.count === null ? "–" : it.count}</span> : null}
                {!single && on ? <span aria-hidden className="absolute inset-x-0 h-0.5 origin-left bg-spot" style={{ bottom: -4, animation: reduced ? undefined : "slug-draw 240ms var(--mm-ease-settle) both" }} /> : null}
              </span>
            </button>
          </span>
        );
      })}
      {single && box ? <span aria-hidden className="pointer-events-none absolute bottom-[calc(50%-14px)] left-0 h-0.5 bg-spot" style={{ width: box.w, transform: `translateX(${box.x}px)`, transition: reduced ? "none" : "transform 320ms var(--mm-ease-settle), width 320ms var(--mm-ease-settle)" }} /> : null}
    </div>
  );
}

/** Removable token: label + x inside a 1 px rule.2 square box, 28 tall. */
export function SlugToken({ label, onRemove }: { label: string; onRemove: () => void }) {
  return (
    <span className="type-nav inline-flex min-h-7 items-center gap-1 border border-rule-2 pl-2 text-ink-100">
      {label}
      <button type="button" aria-label={`Remove ${label}`} onClick={onRemove} className="inline-flex min-h-(--mm-hit-min) min-w-(--mm-hit-min) items-center justify-center text-ink-60 hover:text-ink-100"><Glyph name="x" size={12 as never} /></button>
    </span>
  );
}
