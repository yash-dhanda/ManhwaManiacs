"use client";

import { useCallback, useEffect, useId, useLayoutEffect, useRef, useState, type ReactNode } from "react";
import { GlassSurface } from "../glass/GlassSurface";
import { haptic } from "../haptics";
import { isGlassReduced, play } from "../motion";
import { Icon } from "./Icon";
import { Skeleton } from "./Skeleton";
import { indicatorAt, nextTab, type TabBox } from "./tabs-math";
import { Button } from "./Button";

export interface TabDef {
  id: string;
  label: string;
  disabled?: boolean;
  /** the panel's own states: loading shows its skeleton (the tab still works); error its error block */
  state?: "ready" | "loading" | "error";
  errorText?: string;
  onRetry?: () => void;
  panel: ReactNode;
}

export interface TabPagerProps {
  tabs: TabDef[];
  value: string;
  onChange: (id: string) => void;
  label: string;
  "data-testid"?: string;
}

/**
 * A scrollable row of tab labels over a clear-glass content-twin indicator (32 tall), and beneath it a CSS scroll-snap pager.
 * The indicator reads the pager's continuous position, so it slides and stretches between the labels while a finger drags a
 * panel; `select` fires when the scroll settles. Tapping a tab scrolls the pager with Motion on `settle`.
 */
export function TabPager({ tabs, value, onChange, label, "data-testid": tid }: TabPagerProps) {
  const uid = useId();
  const strip = useRef<HTMLDivElement | null>(null);
  const pager = useRef<HTMLDivElement | null>(null);
  const ind = useRef<HTMLSpanElement | null>(null);
  const tabEls = useRef<(HTMLButtonElement | null)[]>([]);
  const idx = Math.max(0, tabs.findIndex((t) => t.id === value));
  const animating = useRef(false);
  const last = useRef({ pos: idx, t: 0, speed: 0 });
  const settleT = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const disabled = tabs.map((t) => !!t.disabled);
  const [reducedKey, setReducedKey] = useState(0);

  const boxes = useCallback((): TabBox[] => tabEls.current.map((el) => (el ? { left: el.offsetLeft, width: el.offsetWidth } : { left: 0, width: 0 })), []);
  const place = useCallback((pos: number, speed = 0) => {
    const el = ind.current;
    if (!el) return;
    const b = isGlassReduced() ? boxes()[Math.round(pos)] ?? { left: 0, width: 0 } : indicatorAt(boxes(), pos, speed);
    el.style.left = `${b.left}px`;
    el.style.width = `${b.width}px`;
  }, [boxes]);

  useLayoutEffect(() => { place(idx); }, [idx, place, tabs.length]);
  useEffect(() => {
    const ro = new ResizeObserver(() => place(pager.current ? pager.current.scrollLeft / Math.max(1, pager.current.clientWidth) : idx));
    if (strip.current) ro.observe(strip.current);
    return () => ro.disconnect();
  }, [idx, place]);

  // keep the selected tab label in view
  useEffect(() => { tabEls.current[idx]?.scrollIntoView({ inline: "center", block: "nearest", behavior: isGlassReduced() ? "auto" : "smooth" }); }, [idx]);

  const goTo = useCallback((i: number, viaScroll = false) => {
    const p = pager.current;
    if (!p) return;
    const target = i * p.clientWidth;
    if (isGlassReduced()) { p.style.scrollSnapType = "none"; p.scrollLeft = target; requestAnimationFrame(() => { p.style.scrollSnapType = ""; }); if (!viaScroll) setReducedKey((k) => k + 1); return; }
    animating.current = true;
    p.style.scrollSnapType = "none";
    play("followScroll", p.scrollLeft, target, {
      onUpdate: (v) => { p.scrollLeft = v; },
    });
    // scrollLeft starts wherever the pager is: animate from there
  }, []);

  const select = useCallback((i: number, source: "tap" | "scroll" | "key") => {
    const t = tabs[i];
    if (!t || t.disabled) return;
    if (t.id !== value) { haptic("select"); onChange(t.id); }
    if (source !== "scroll") goTo(i);
  }, [goTo, onChange, tabs, value]);

  // programmatic scroll from a value change made elsewhere
  const prevIdx = useRef(idx);
  useEffect(() => {
    if (prevIdx.current === idx) return;
    prevIdx.current = idx;
    const p = pager.current;
    if (p && Math.abs(p.scrollLeft - idx * p.clientWidth) > 2 && !animating.current) goTo(idx, true);
  }, [idx, goTo]);

  // the pager scrolled: move the indicator with the continuous position; settle picks the panel
  const onScroll = () => {
    const p = pager.current;
    if (!p) return;
    const w = Math.max(1, p.clientWidth);
    const pos = p.scrollLeft / w;
    const now = performance.now();
    const dt = Math.max(1, now - last.current.t);
    const speed = Math.abs(pos - last.current.pos) / (dt / 1000) / 12; // panels per second, scaled so a firm swipe reaches the 25 % cap
    last.current = { pos, t: now, speed: last.current.speed * 0.6 + speed * 0.4 };
    place(pos, last.current.speed);
    clearTimeout(settleT.current);
    settleT.current = setTimeout(() => {
      const i = Math.round(p.scrollLeft / w);
      last.current.speed = 0;
      place(i);
      if (animating.current) { animating.current = false; p.style.scrollSnapType = ""; }
      if (tabs[i] && tabs[i].id !== value && !tabs[i].disabled) { haptic("select"); onChange(tabs[i].id); }
    }, 110);
  };
  useEffect(() => () => clearTimeout(settleT.current), []);

  // `[` and `]` go to the previous and next tab (not while typing)
  useEffect(() => {
    const on = (e: KeyboardEvent) => {
      if (e.metaKey || e.ctrlKey || e.altKey) return;
      const t = e.target as HTMLElement | null;
      if (t && (t.isContentEditable || /^(INPUT|TEXTAREA|SELECT)$/.test(t.tagName))) return;
      if (e.key !== "[" && e.key !== "]") return;
      const next = nextTab(disabled, idx, e.key === "]" ? 1 : -1);
      if (next !== idx) { e.preventDefault(); select(next, "key"); tabEls.current[next]?.focus({ preventScroll: true }); }
    };
    window.addEventListener("keydown", on);
    return () => window.removeEventListener("keydown", on);
  });

  const onKeyDown = (e: React.KeyboardEvent) => {
    const from = tabEls.current.findIndex((el) => el === document.activeElement);
    const cur = from < 0 ? idx : from;
    let next = cur;
    if (e.key === "ArrowRight") next = nextTab(disabled, cur, 1);
    else if (e.key === "ArrowLeft") next = nextTab(disabled, cur, -1);
    else if (e.key === "Home") next = nextTab(disabled, -1, 1);
    else if (e.key === "End") next = nextTab(disabled, tabs.length, -1);
    else return;
    e.preventDefault();
    tabEls.current[next]?.focus({ preventScroll: true });
    select(next, "key");
  };

  return (
    <div className="g-tabs" data-testid={tid}>
      <div className="g-tabs__strip" ref={strip}>
        <div role="tablist" aria-label={label} className="g-tabs__list" onKeyDown={onKeyDown}>
          <span ref={ind} key={reducedKey} className="g-tabs__ind" aria-hidden="true" data-reduced-fade={isGlassReduced() ? "" : undefined}>
            <GlassSurface tier="t1" finish="clear" twin="content" capsule layer="controls" materialize={false} className="g-tabs__glass" />
          </span>
          {tabs.map((t, i) => (
            <button
              key={t.id}
              ref={(el) => { tabEls.current[i] = el; }}
              type="button"
              role="tab"
              id={`${uid}-tab-${t.id}`}
              aria-selected={i === idx}
              aria-controls={`${uid}-panel-${t.id}`}
              aria-disabled={t.disabled || undefined}
              disabled={t.disabled}
              tabIndex={i === idx ? 0 : -1}
              className="g-tabs__tab"
              data-selected={i === idx ? "" : undefined}
              data-loading={t.state === "loading" ? "" : undefined}
              onClick={() => select(i, "tap")}
            >
              <span className="g-tabs__label">{t.label}</span>
            </button>
          ))}
        </div>
      </div>
      <div className="g-tabs__pager" ref={pager} onScroll={onScroll}>
        {tabs.map((t, i) => (
          <div
            key={t.id}
            role="tabpanel"
            id={`${uid}-panel-${t.id}`}
            aria-labelledby={`${uid}-tab-${t.id}`}
            aria-busy={t.state === "loading" || undefined}
            className="g-tabs__panel"
            data-active={i === idx ? "" : undefined}
            inert={i === idx ? undefined : true}
            tabIndex={i === idx ? 0 : -1}
          >
            {t.state === "loading" ? (
              <div className="g-tabs__skeleton" aria-hidden="true">{[0, 1, 2].map((r) => <Skeleton key={r} shape="line" height={44} radius={20} row={r} />)}</div>
            ) : t.state === "error" ? (
              <div className="g-tabs__error" role="alert">
                <span className="g-disc"><Icon name="warning-circle" size={22} color="var(--mm-color-danger)" /></span>
                <p>{t.errorText ?? "Couldn't load this tab."}</p>
                {t.onRetry ? <Button variant="secondary" size="M" label="Retry" onPress={t.onRetry} /> : null}
              </div>
            ) : t.panel}
          </div>
        ))}
      </div>
    </div>
  );
}
