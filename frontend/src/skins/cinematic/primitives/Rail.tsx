"use client";
import { useVirtualizer } from "@tanstack/react-virtual";
import { animate } from "motion/react";
import { useCallback, useEffect, useId, useLayoutEffect, useRef, useState, type KeyboardEvent, type ReactNode } from "react";
import { startMove } from "@/lib/motion-timings";
import { RuleDraw } from "../motion-components";
import { useCineReduced } from "../motion";
import { ease } from "../tokens.generated";
import { Badge } from "./Badge";
import { Button } from "./Button";
import { Glyph } from "./glyphs";
import { Poster } from "./Poster";
import { posterWidth, railBreakpoint, railGap, visiblePosters, pageBy } from "./rail-math";
import { RailSlate, type SlateItem } from "./RailSlate";
import { SetHeading } from "./SetHeading";
import { GalleyPlate } from "./Skeleton";
import { useRootScale } from "./hooks";

export type RailItem = SlateItem & { href?: string; folio?: string; badges?: ReactNode; progress?: number; matchCut?: { sourceId: string; seriesKey: string } };
export type RailState = "ready" | "loading" | "empty" | "error" | "ai-unavailable";

export type RailProps = {
  index?: string;
  title: string;
  items: RailItem[];
  state?: RailState;
  /** Core rails collapse to one italic line when empty; optional rails render nothing. */
  core?: boolean;
  emptyLine?: string;
  aiNote?: string;
  staleLabel?: string;
  pickedLabel?: string;
  onSeeAll?: () => void;
  onRetry?: () => void;
  onOpen?: (item: RailItem) => void;
  "data-gallery"?: string;
};

const VIRTUALISE_AFTER = 30;

/** Programmatic scroll: Paddle page 560 ms ease.turn; reduced motion jumps (§4.8). */
function scrollRail(el: HTMLElement, left: number, reduced: boolean, ms = 560, easing: readonly number[] = ease.turn) {
  if (reduced) { el.scrollLeft = left; return; }
  const rec = startMove("paddlePage", ms);
  animate(el.scrollLeft, left, { duration: ms / 1000, ease: easing as never, onUpdate: (v) => { el.scrollLeft = v; }, onComplete: () => rec.end() });
}

/** §7.8 rail: section rule, header (folio + linked heading + See all), snapping poster scroller, paddles, slate, roving keyboard. */
export function Rail(p: RailProps) {
  const { items, state = "ready" } = p;
  const reduced = useCineReduced();
  const scale = useRootScale();
  const uid = useId();
  const scroller = useRef<HTMLDivElement>(null);
  const [content, setContent] = useState(1200);
  const [vw, setVw] = useState(1440);
  const [focusIx, setFocusIx] = useState(0);
  const [slate, setSlate] = useState<{ item: RailItem; rect: DOMRect; keyboard: boolean; ix: number } | null>(null);
  const [atStart, setAtStart] = useState(true);
  const [atEnd, setAtEnd] = useState(false);
  const els = useRef<(HTMLElement | null)[]>([]);

  useLayoutEffect(() => {
    const el = scroller.current;
    if (!el) return;
    const measure = () => { setContent(el.clientWidth); setVw(window.innerWidth); setAtStart(el.scrollLeft <= 1); setAtEnd(el.scrollLeft + el.clientWidth >= el.scrollWidth - 1); };
    measure();
    const ro = new ResizeObserver(measure);
    ro.observe(el);
    el.addEventListener("scroll", measure, { passive: true });
    return () => { ro.disconnect(); el.removeEventListener("scroll", measure); };
  }, [items.length, state]);

  const bp = railBreakpoint(vw);
  const gap = railGap(bp);
  const w = posterWidth(content, bp, scale);
  const visible = visiblePosters(bp, scale);
  const virtual = items.length > VIRTUALISE_AFTER;
  // eslint-disable-next-line react-hooks/incompatible-library -- TanStack Virtual is used as documented
  const virt = useVirtualizer({ count: items.length, horizontal: true, getScrollElement: () => scroller.current, estimateSize: () => w + gap, overscan: 4, enabled: virtual });

  const focusItem = useCallback((i: number) => {
    const n = Math.max(0, Math.min(items.length - 1, i));
    setFocusIx(n);
    const sc = scroller.current;
    if (sc) {
      const step = w + gap;
      const first = Math.ceil(sc.scrollLeft / step - 0.02), last = Math.floor((sc.scrollLeft + sc.clientWidth) / step - 1 + 0.02);
      if (n < first) scrollRail(sc, n * step, reduced, 320, ease.settle);
      else if (n > last) scrollRail(sc, (n - Math.floor(visible) + 1) * step, reduced, 320, ease.settle);
    }
    if (virtual) virt.scrollToIndex(n);
    requestAnimationFrame(() => els.current[n]?.focus({ preventScroll: true }));
  }, [items.length, w, gap, reduced, visible, virtual, virt]);

  const page = (dir: 1 | -1) => { const sc = scroller.current; if (sc) scrollRail(sc, sc.scrollLeft + dir * pageBy(visible) * (w + gap), reduced); };

  const neighbour = (dir: 1 | -1) => {
    const rails = Array.from(document.querySelectorAll<HTMLElement>("[data-rail]"));
    const me = rails.indexOf(scroller.current!.closest("[data-rail]") as HTMLElement);
    const next = rails[me + dir];
    const target = next?.querySelector<HTMLElement>('[data-rail-item][tabindex="0"]');
    if (!target) return;
    target.focus({ preventScroll: true });
    window.scrollTo({ top: target.getBoundingClientRect().top + window.scrollY - window.innerHeight * 0.3, behavior: reduced ? "auto" : "smooth" });
  };

  const openSlate = (i: number, keyboard: boolean, rect?: DOMRect) => {
    const el = els.current[i]; const item = items[i];
    if (!el || !item) return;
    setSlate({ item, rect: rect ?? el.getBoundingClientRect(), keyboard, ix: i });
  };

  const onKey = (e: KeyboardEvent, i: number) => {
    switch (e.key) {
      case "ArrowRight": e.preventDefault(); focusItem(i + 1); break;
      case "ArrowLeft": e.preventDefault(); focusItem(i - 1); break;
      case "ArrowDown": e.preventDefault(); neighbour(1); break;
      case "ArrowUp": e.preventDefault(); neighbour(-1); break;
      case "Home": e.preventDefault(); focusItem(0); break;
      case "End": e.preventDefault(); focusItem(items.length - 1); break;
      case " ": e.preventDefault(); if (slate) setSlate(null); else openSlate(i, true); break;
    }
  };

  useEffect(() => { if (focusIx >= items.length) setFocusIx(0); }, [items.length, focusIx]);

  if (state === "empty" && !p.core) return null;
  const bounds = { left: 0, right: typeof window === "undefined" ? 1440 : window.innerWidth };
  const slateId = `${uid}-slate`;
  const header = (
    <div className="set-heading-link flex items-baseline gap-3 py-3">
      {p.index ? <span className="type-folio text-ink-45">{p.index}</span> : null}
      <SetHeading as="h2" trigger="inView" id={`rail-${p.title}`} text={p.title} className="type-section min-w-0 text-ink-100 group-focus-within/rail:text-ink-100" />
      {p.staleLabel ? <Badge variant="stale">{p.staleLabel}</Badge> : null}
      {p.pickedLabel ? <Badge variant="pickedAgo">{p.pickedLabel}</Badge> : null}
      {p.onSeeAll ? <span className="ml-auto"><Button variant="quiet" size="sm" onClick={p.onSeeAll}>See all <Glyph name="arrow-right" size={16} /></Button></span> : null}
    </div>
  );

  return (
    <section data-rail data-gallery={p["data-gallery"]} aria-label={p.title} className="group/rail relative w-full">
      <RuleDraw kind="hairline" />
      {header}
      {state === "empty" ? <p className="type-body-italic py-3 text-ink-45">{p.emptyLine ?? "Nothing here yet."}</p> : null}
      {state === "error" ? <p className="type-caption flex items-center gap-2 py-3 text-proof">This row didn&apos;t load.<Button variant="quiet" size="sm" onClick={p.onRetry}>Retry</Button></p> : null}
      {state === "ai-unavailable" ? <p className="type-kicker py-2 text-spot"><span className="text-ink-60">NOTE </span>{p.aiNote ?? "Riya is resting."} Here is your shelf instead.</p> : null}
      {state === "ready" || state === "loading" || state === "ai-unavailable" ? (
        <div className="relative">
          <div ref={scroller} data-poster-group role="list" aria-busy={state === "loading" || undefined} className="flex overflow-x-auto py-2 [scrollbar-width:none]"
            style={{ gap, scrollSnapType: "x proximity", overscrollBehaviorX: "contain", height: virtual ? w * 1.5 + 96 : undefined, position: "relative" }}>
            {state === "loading"
              ? Array.from({ length: Math.ceil(visible) + 1 }).map((_, i) => <div key={i} role="listitem" style={{ width: w, flex: "none", aspectRatio: "2 / 3" }}><GalleyPlate index={i} title={items[i]?.title} /></div>)
              : virtual
                ? <div style={{ width: virt.getTotalSize(), position: "relative", flex: "none" }}>{virt.getVirtualItems().map((v) => rail(v.index, { position: "absolute", left: v.start, width: w }))}</div>
                : items.map((_, i) => rail(i, { width: w, flex: "none" }))}
          </div>
          <div className="pointer-events-none absolute inset-y-0 hidden w-full frame:block">
            {!atStart ? <Paddle side="left" onClick={() => page(-1)} /> : null}
            {!atEnd && items.length > visible ? <Paddle side="right" onClick={() => page(1)} /> : null}
          </div>
        </div>
      ) : null}
      {slate ? (
        <RailSlate item={slate.item} anchor={slate.rect} bounds={bounds} keyboard={slate.keyboard} id={slateId}
          onClose={(restore) => { const ix = slate.ix; setSlate(null); if (restore) requestAnimationFrame(() => els.current[ix]?.focus()); }}
          onRead={() => p.onOpen?.(slate.item)} />
      ) : null}
    </section>
  );

  function rail(i: number, style: React.CSSProperties) {
    const it = items[i];
    return (
      <div key={it.id} role="listitem" style={{ ...style, scrollSnapAlign: "start" }}>
        <Poster title={it.title} src={it.src} href={it.href} folio={it.folio} badges={it.badges} progress={it.progress} matchCut={it.matchCut} ambientDuo={it.duo}
          tabIndex={i === focusIx ? 0 : -1} aria-expanded={slate?.ix === i} aria-controls={slate?.ix === i ? slateId : undefined}
          posterRef={(el) => { els.current[i] = el; if (el) { el.setAttribute("data-rail-item", ""); el.onkeydown = (e) => onKey(e as unknown as KeyboardEvent, i); el.onfocus = () => setFocusIx(i); } }}
          onOpen={() => p.onOpen?.(it)} onDwell={(rect) => openSlate(i, false, rect)} />
      </div>
    );
  }
}

function Paddle({ side, onClick }: { side: "left" | "right"; onClick: () => void }) {
  return (
    <button type="button" aria-label={side === "left" ? "Previous posters" : "Next posters"} onClick={onClick} tabIndex={-1}
      className={`scrim-rail-end pointer-events-auto absolute inset-y-2 flex w-12 items-center justify-center text-ink-100 opacity-0 transition-opacity duration-(--mm-dur-beat) group-hover/rail:opacity-100 ${side === "left" ? "left-0 scale-x-[-1]" : "right-0"}`}>
      <Glyph name="arrow-right" size={24} />
    </button>
  );
}
