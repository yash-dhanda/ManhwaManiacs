"use client";
import { Tabs } from "@base-ui/react/tabs";
import { animate } from "motion/react";
import { useCallback, useEffect, useLayoutEffect, useRef, useState, type ReactNode } from "react";
import { useShortcut } from "@/lib/keyboard";
import { folioLabel } from "../a11y/folio";
import { haptic } from "../haptics";
import { readReduced, useCineReduced } from "../motion";
import { durMs, ease } from "../tokens.generated";
import { Tooltip } from "./Tooltip";
import { useDesktopFrame } from "./overlay-hooks";

const RAISED = "⁰¹²³⁴⁵⁶⁷⁸⁹";
const raise = (n: number) => String(n).split("").map((d) => RAISED[Number(d)]).join("");

export type ContentsTab = {
  id: string; folio: string; label: string;
  /** A number, "loading" (shows -) or "error" (shows ! in proof). */
  count?: number | "loading" | "error";
  disabled?: boolean; disabledReason?: string;
  panel?: ReactNode;
};

/**
 * §7.12 contents tabs. Phone frame: a CSS scroll-snap pager whose scroll position drives a sliding 2 px spot indicator;
 * desktop: click and `[` / `]`. `pager={false}` makes nested tabs tap-only.
 */
export function ContentsTabs({ tabs, value, onValueChange, sticky = false, pager = true, shortcutGroup = "Tabs", label = "Sections", ...rest }: {
  tabs: ContentsTab[]; value: string; onValueChange: (id: string) => void; sticky?: boolean; pager?: boolean; shortcutGroup?: string; label?: string; "data-gallery"?: string;
}) {
  const desktop = useDesktopFrame();
  const paged = pager && !desktop;
  const reduced = useCineReduced();
  const listRef = useRef<HTMLDivElement>(null);
  const scroller = useRef<HTMLDivElement>(null);
  const tabEls = useRef<Record<string, HTMLElement | null>>({});
  const ind = useRef<HTMLSpanElement>(null);
  const fromScroll = useRef(false);
  const [ready, setReady] = useState(false);
  const enabled = tabs.filter((t) => !t.disabled);
  const step = useCallback((d: 1 | -1) => {
    const i = enabled.findIndex((t) => t.id === value);
    const next = enabled[i + d];
    if (next) { haptic("select"); onValueChange(next.id); }
  }, [enabled, value, onValueChange]);
  useShortcut({ id: `${shortcutGroup}.tab-next`, keys: "]", description: "Next tab", group: shortcutGroup, handler: () => step(1) });
  useShortcut({ id: `${shortcutGroup}.tab-prev`, keys: "[", description: "Previous tab", group: shortcutGroup, handler: () => step(-1) });

  const place = useCallback((x: number, w: number) => { const el = ind.current; if (el) { el.style.transform = `translateX(${x}px)`; el.style.width = `${w}px`; } }, []);
  const rectOf = (id: string) => { const el = tabEls.current[id], l = listRef.current; if (!el || !l) return null; return { x: el.offsetLeft, w: el.offsetWidth }; };
  // Tap: Rule slide 320 ms ease.settle (reduced: instant, the row fades via CSS).
  const prev = useRef<{ x: number; w: number } | null>(null);
  useLayoutEffect(() => {
    if (fromScroll.current) { fromScroll.current = false; return; }
    const r = rectOf(value); if (!r) return;
    const from = prev.current;
    prev.current = r;
    if (!from || readReduced() || !ready) { place(r.x, r.w); setReady(true); return; }
    animate(0, 1, { duration: durMs.column / 1000, ease: ease.settle as unknown as [number, number, number, number], onUpdate: (p) => place(from.x + (r.x - from.x) * p, from.w + (r.w - from.w) * p) });
  }, [value, tabs, place, ready]);
  useEffect(() => { if (!paged) return; const i = tabs.findIndex((t) => t.id === value); const el = scroller.current; if (el && !fromScroll.current) el.scrollTo({ left: i * el.clientWidth, behavior: readReduced() ? "auto" : "smooth" }); }, [value, paged, tabs]);

  const onScroll = () => {
    const el = scroller.current; if (!el || !paged) return;
    const p = el.scrollLeft / Math.max(1, el.clientWidth);
    const i = Math.max(0, Math.min(tabs.length - 1, Math.floor(p))), j = Math.min(tabs.length - 1, i + 1), t = p - i;
    const a = rectOf(tabs[i].id), b = rectOf(tabs[j].id);
    if (a && b) place(a.x + (b.x - a.x) * t, a.w + (b.w - a.w) * t);
    const idx = Math.round(p);
    if (Math.abs(p - idx) < 0.02 && tabs[idx] && tabs[idx].id !== value && !tabs[idx].disabled) { fromScroll.current = true; prev.current = rectOf(tabs[idx].id); haptic("select"); onValueChange(tabs[idx].id); }
  };

  return (
    <Tabs.Root value={value} onValueChange={(v) => { haptic("select"); onValueChange(String(v)); }} data-gallery={rest["data-gallery"]}>
      <Tabs.List ref={listRef} aria-label={label} className={`relative flex min-h-12 overflow-x-auto border-b border-rule-1 bg-paper-1 ${sticky ? "sticky z-(--mm-z-sticky) " : ""}`} style={sticky ? { top: "var(--mm-running-head-h, 56px)" } : undefined}>
        {tabs.map((t) => {
          const count = t.count;
          const spoken = typeof count === "number" ? folioLabel(t.label, count) : t.label;
          const btn = (
            <Tabs.Tab key={t.id} value={t.id} disabled={t.disabled && !t.disabledReason} aria-disabled={t.disabled || undefined} aria-label={spoken}
              ref={(el: HTMLElement | null) => { tabEls.current[t.id] = el; }}
              onClick={(e: React.MouseEvent) => { if (t.disabled) e.preventDefault(); }}
              className={`type-nav group relative inline-flex min-h-12 shrink-0 items-center gap-2 px-4 whitespace-nowrap transition-colors duration-(--mm-dur-tick) active:translate-y-px ${
                t.disabled ? "text-ink-30" : "text-ink-45 hover:text-ink-100 data-[active]:text-ink-100"}`}>
              <span aria-hidden className="type-folio text-ink-45">{t.folio}</span>
              <span aria-hidden>{t.label.toUpperCase()}</span>
              {count !== undefined ? (
                <span aria-hidden className={`type-folio ${count === "error" ? "text-proof" : ""} -translate-y-1`}>{typeof count === "number" ? raise(count) : count === "error" ? "!" : "–"}</span>
              ) : null}
            </Tabs.Tab>
          );
          return t.disabled && t.disabledReason ? <Tooltip key={t.id} label={t.disabledReason}>{btn}</Tooltip> : btn;
        })}
        <span key={reduced ? value : "i"} ref={ind} aria-hidden className="cine-tab-indicator pointer-events-none absolute bottom-0 left-0 h-0.5 bg-spot" style={{ width: 0 }} />
      </Tabs.List>
      {paged ? (
        <div ref={scroller} onScroll={onScroll} className="cine-pager flex overflow-x-auto" style={{ scrollSnapType: "x mandatory", scrollbarWidth: "none" }}>
          {tabs.map((t) => <Tabs.Panel key={t.id} value={t.id} keepMounted className="min-w-full shrink-0 basis-full" style={{ scrollSnapAlign: "start", touchAction: "pan-y pinch-zoom" }}>{t.panel}</Tabs.Panel>)}
        </div>
      ) : tabs.map((t) => <Tabs.Panel key={t.id} value={t.id}>{t.panel}</Tabs.Panel>)}
    </Tabs.Root>
  );
}
