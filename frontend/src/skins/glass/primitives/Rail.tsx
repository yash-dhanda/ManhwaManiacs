"use client";

import { motionValue } from "motion/react";
import { Children, useCallback, useEffect, useMemo, useRef, useState, type KeyboardEvent, type ReactNode } from "react";
import { GlassSurface } from "../glass/GlassSurface";
import { play } from "../motion";
import { railSnap } from "../physics/project";
import { Button } from "./Button";
import { Icon } from "./Icon";
import { LetterReveal } from "./LetterReveal";
import { Skeleton } from "./Skeleton";
import { arrowStep } from "./rail-columns";
import { useRailGroup } from "./RailGroup";

export type RailState = "loaded" | "loading" | "empty" | "error" | "partial";
export interface RailProps {
  title: string;
  subtitle?: string;
  /** "{profileId}:{screenId}:{headingKey}" for the header's LetterReveal */
  revealKey?: string;
  onSeeAll?: () => void;
  state?: RailState;
  onRetry?: () => void;
  /** an AI rail renders this instead of nothing when empty (the AiNotice, web/28) */
  unavailable?: ReactNode;
  /** position inside a RailGroup */
  index?: number;
  /** screen margin: the leading and trailing inset */
  inset?: number;
  posterWidth?: number;
  children?: ReactNode;
}

/**
 * Header (title2 through LetterReveal, subtitle, See all), then a scroller with free native momentum. On `scrollend`,
 * railSnap() gives the target and Motion carries scrollLeft there on `settle`. No snapping while a pointer or finger is down.
 */
export function Rail({ title, subtitle, revealKey, onSeeAll, state = "loaded", onRetry, unavailable, index = 0, inset = 16, posterWidth = 124, children }: RailProps) {
  const group = useRailGroup();
  const scroller = useRef<HTMLDivElement>(null);
  const root = useRef<HTMLElement | null>(null);
  const [ends, setEnds] = useState({ start: true, end: false });
  const [hover, setHover] = useState(false);
  const leave = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const sl = useMemo(() => motionValue(0), []);
  const down = useRef(false);
  const anim = useRef<{ stop: () => void } | null>(null);
  const cur = useRef(0);
  const count = Children.count(children);

  const stride = () => {
    const kids = scroller.current?.querySelectorAll<HTMLElement>(":scope > *:not(.g-rail__pad)");
    if (!kids || kids.length < 2) return posterWidth + 12;
    return kids[1].offsetLeft - kids[0].offsetLeft;
  };
  const measure = useCallback(() => {
    const el = scroller.current;
    if (!el) return;
    setEnds({ start: el.scrollLeft <= 1, end: el.scrollLeft + el.clientWidth >= el.scrollWidth - 1 });
  }, []);
  const scrollTo = useCallback((x: number, name: "surface" | "pageSlide" = "surface") => {
    const el = scroller.current;
    if (!el) return;
    anim.current?.stop();
    sl.set(el.scrollLeft);
    anim.current = play(name, sl, Math.max(0, Math.min(el.scrollWidth - el.clientWidth, x)), { onUpdate: (v) => { el.scrollLeft = v; } });
  }, [sl]);
  useEffect(() => {
    const el = scroller.current;
    if (!el) return;
    let t: ReturnType<typeof setTimeout>;
    const settle = () => {
      if (down.current) return;
      const s = stride();
      const first = el.querySelector<HTMLElement>(":scope > *:not(.g-rail__pad)");
      const base = first ? first.offsetLeft - inset : 0; // the first poster rests at scrollLeft = base
      const target = railSnap(el.scrollLeft - base, 0, s) + base;
      if (Math.abs(target - el.scrollLeft) > 0.5) scrollTo(target);
    };
    const onScroll = () => { measure(); clearTimeout(t); t = setTimeout(settle, 140); }; // fallback where scrollend is missing
    const onEnd = () => { clearTimeout(t); settle(); };
    const stop = () => { anim.current?.stop(); down.current = true; };
    const up = () => { down.current = false; clearTimeout(t); t = setTimeout(settle, 140); };
    el.addEventListener("scroll", onScroll, { passive: true });
    el.addEventListener("scrollend", onEnd);
    el.addEventListener("pointerdown", stop);
    el.addEventListener("wheel", () => anim.current?.stop(), { passive: true });
    window.addEventListener("pointerup", up);
    window.addEventListener("pointercancel", up);
    measure();
    return () => { clearTimeout(t); el.removeEventListener("scroll", onScroll); el.removeEventListener("scrollend", onEnd); el.removeEventListener("pointerdown", stop); window.removeEventListener("pointerup", up); window.removeEventListener("pointercancel", up); };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [measure, scrollTo, inset, count]);

  // one tab stop per rail: only the current poster keeps tabindex 0; star, bell and peek are reached through the context menu
  useEffect(() => {
    const el = scroller.current;
    if (!el) return;
    const apply = () => {
      const mains = Array.from(el.querySelectorAll<HTMLElement>(".g-poster__main"));
      mains.forEach((m, i) => m.tabIndex = i === Math.min(cur.current, mains.length - 1) ? 0 : -1);
      el.querySelectorAll<HTMLElement>(".g-poster__act").forEach((b) => (b.tabIndex = -1));
    };
    apply();
    const mo = new MutationObserver(apply);
    mo.observe(el, { childList: true, subtree: true });
    return () => mo.disconnect();
  }, [count, state]);
  useEffect(() => { group?.register(root.current, index); return () => group?.register(null, index); }, [group, index]);

  const onKey = (e: KeyboardEvent<HTMLElement>) => {
    const el = scroller.current;
    const mains = Array.from(el?.querySelectorAll<HTMLElement>(".g-poster__main") ?? []);
    const i = mains.indexOf(document.activeElement as HTMLElement);
    if (i < 0) return;
    if (e.key === "ArrowLeft" || e.key === "ArrowRight" || e.key === "Home" || e.key === "End") {
      const to = e.key === "ArrowLeft" ? i - 1 : e.key === "ArrowRight" ? i + 1 : e.key === "Home" ? 0 : mains.length - 1;
      if (to < 0 || to > mains.length - 1) return;
      e.preventDefault();
      cur.current = to;
      mains.forEach((m, k) => (m.tabIndex = k === to ? 0 : -1));
      mains[to].focus({ preventScroll: true });
      mains[to].scrollIntoView({ block: "nearest", inline: "nearest" });
    } else if ((e.key === "ArrowUp" || e.key === "ArrowDown") && group) {
      if (group.move({ rail: index, col: i }, e.key)) e.preventDefault();
    }
  };
  const onFocus = () => {
    const mains = Array.from(scroller.current?.querySelectorAll<HTMLElement>(".g-poster__main") ?? []);
    const i = mains.indexOf(document.activeElement as HTMLElement);
    if (i >= 0) cur.current = i;
  };
  const page = (dir: 1 | -1) => {
    const el = scroller.current;
    if (!el) return;
    const s = stride();
    const visible = Math.max(1, Math.floor(el.clientWidth / s));
    scrollTo(el.scrollLeft + dir * arrowStep(visible) * s, "pageSlide");
  };

  if (state === "empty") return unavailable ? <section className="g-rail" ref={(el) => { root.current = el; }}>{unavailable}</section> : null;
  const skeletons = Array.from({ length: 6 }, (_, i) => <Skeleton key={i} shape="poster" width={posterWidth} row={i} />);
  return (
    <section
      ref={(el) => { root.current = el; }} className="g-rail" aria-label={title} aria-busy={state === "loading" || undefined} data-state={state}
      onPointerEnter={(e) => { if (e.pointerType === "mouse") { clearTimeout(leave.current); setHover(true); } }}
      onPointerLeave={() => { clearTimeout(leave.current); leave.current = setTimeout(() => setHover(false), 300); }}
      onKeyDown={onKey} onFocus={onFocus}
      style={{ "--rail-inset": `${inset}px` } as React.CSSProperties}
    >
      <header className="g-rail__head">
        <div className="g-rail__titles">
          <LetterReveal text={title} revealKey={revealKey} as="h3" typeClass="type-title2" />
          {subtitle ? <p className="g-rail__sub type-footnote">{subtitle}</p> : null}
        </div>
        {onSeeAll ? <Button variant="plain" size="M" label="See all" onPress={onSeeAll} /> : null}
      </header>
      {state === "error" ? (
        <div className="g-rail__error" role="alert"><span className="type-body">Couldn&rsquo;t load this row</span><Button variant="plain" label="Retry" onPress={() => onRetry?.()} /></div>
      ) : (
        <div className="g-rail__wrap">
          <div ref={scroller} className="g-rail__scroll" role="list" tabIndex={-1}>
            <span className="g-rail__pad" aria-hidden="true" />
            {state === "loading" ? skeletons : (
              <>
                {Children.map(children, (c, i) => <div role="listitem" className="g-rail__item" data-wave-item key={i}>{c}</div>)}
                {state === "partial" ? <Skeleton shape="poster" width={posterWidth} row={0} /> : null}
              </>
            )}
            <span className="g-rail__pad" aria-hidden="true" />
          </div>
          {(["prev", "next"] as const).map((k) => {
            const hidden = k === "prev" ? ends.start : ends.end;
            return (
              <GlassSurface key={k} as="button" twin="content" tier="t2" capsule finish="regular" type="button" className="g-rail__arrow" data-dir={k} data-show={hover && !hidden ? "" : undefined} aria-label={k === "prev" ? "Scroll back" : "Scroll forward"} tabIndex={-1} onClick={() => page(k === "prev" ? -1 : 1)}>
                <Icon name={k === "prev" ? "caret-left" : "caret-right"} size={20} />
              </GlassSurface>
            );
          })}
        </div>
      )}
    </section>
  );
}
