"use client";
import { useEffect, useLayoutEffect, useRef } from "react";
import { createPortal } from "react-dom";
import { animate } from "motion/react";
import { startMove } from "@/lib/motion-timings";
import { play, useCineReduced } from "../motion";
import { ease, z } from "../tokens.generated";
import { useDuotone } from "../duotone";
import { Button } from "./Button";
import { CineImage } from "./CineImage";
import { SetHeading } from "./SetHeading";

export type SlateItem = { id: string; title: string; src?: string | null; kicker: string; deck?: string; why?: string; duo?: string };

/** Slate geometry: 2.1 x poster width, centred on the poster then clamped 24 px inside the bounds; at the rail's ends it grows inward. */
export function slateRect(poster: DOMRect, bounds: { left: number; right: number }, viewportH: number) {
  const width = poster.width * 2.1;
  const height = poster.height * 1.6;
  let left = poster.left + poster.width / 2 - width / 2;
  left = Math.max(bounds.left + 24, Math.min(left, bounds.right - 24 - width));
  const top = Math.max(24, Math.min(poster.top + poster.height / 2 - height / 2, viewportH - 24 - height));
  return { left, top, width, height };
}

/** §7.8 preview slate: portal overlay at z.panel. Pointer-dwell slates never take focus; keyboard-opened slates are a non-modal dialog. */
export function RailSlate({ item, anchor, bounds, keyboard, id, onClose, onRead, onLibrary, onDetails }: {
  item: SlateItem; anchor: DOMRect; bounds: { left: number; right: number }; keyboard: boolean; id: string; onClose: (restoreFocus: boolean) => void;
  onRead?: () => void; onLibrary?: () => void; onDetails?: () => void;
}) {
  const ref = useRef<HTMLDivElement>(null);
  const reduced = useCineReduced();
  const grace = useRef<ReturnType<typeof setTimeout>>(undefined);
  const r = slateRect(anchor, bounds, typeof window === "undefined" ? 900 : window.innerHeight);
  const filter = useDuotone(item.duo ?? "#B8B2A4");

  useLayoutEffect(() => {
    const el = ref.current;
    if (!el) return;
    if (reduced) { animate(el, { opacity: [0, 1] }, { duration: 0.15 }); return; }
    const sx = anchor.width / r.width, sy = anchor.height / r.height;
    const dx = anchor.left + anchor.width / 2 - (r.left + r.width / 2), dy = anchor.top + anchor.height / 2 - (r.top + r.height / 2);
    play("slate", el, { from: { transform: `translate(${dx}px, ${dy}px) scale(${sx}, ${sy})` }, to: { transform: "none" } });
  }, [anchor, r.left, r.top, r.width, r.height, reduced]);
  useEffect(() => { if (keyboard) ref.current?.querySelector<HTMLElement>("button")?.focus(); }, [keyboard]);
  useEffect(() => () => clearTimeout(grace.current), []);

  const close = (restore: boolean) => {
    const el = ref.current;
    if (!el || reduced) { onClose(restore); return; }
    const rec = startMove("slate", 200);
    animate(el, { opacity: 0, transform: "scale(0.96)" }, { duration: 0.2, ease: ease.lift as never }).then(() => { rec.end(); onClose(restore); });
  };
  const onKey = (e: React.KeyboardEvent) => {
    if (e.key === "Escape" || e.key === " ") { e.preventDefault(); e.stopPropagation(); close(true); return; }
    if (e.key === "Tab") {
      const bs = Array.from(ref.current?.querySelectorAll<HTMLElement>("button") ?? []);
      const i = bs.indexOf(document.activeElement as HTMLElement);
      const n = (i + (e.shiftKey ? -1 : 1) + bs.length) % bs.length;
      e.preventDefault(); bs[n]?.focus();
    }
  };
  return createPortal(
    <div ref={ref} id={id} role={keyboard ? "dialog" : undefined} aria-modal={keyboard ? false : undefined} aria-labelledby={keyboard ? `${id}-title` : undefined} aria-label={keyboard ? undefined : item.title} data-slate
      onKeyDown={keyboard ? onKey : undefined}
      onPointerLeave={() => { grace.current = setTimeout(() => close(false), 120); }} onPointerEnter={() => clearTimeout(grace.current)}
      className="fixed flex flex-col overflow-hidden bg-paper-2" data-stock="raised"
      style={{ left: r.left, top: r.top, width: r.width, height: r.height, zIndex: z.panel, boxShadow: "inset 0 0 0 1px var(--mm-color-hairline-art)" }}>
      <div className="relative h-1/2 overflow-hidden">
        <div className="blur-card absolute -inset-4" style={{ filter }}><CineImage src={item.src} alt="" title={item.title} priority /></div>
        <div aria-hidden className="scrim-foot pointer-events-none absolute inset-0" style={{ ["--scrim-solid-at" as string]: "48px" }} />
        <div id={`${id}-title`} className="absolute inset-x-3 bottom-2"><SetHeading as="h3" trigger="signal" play id={`slate-${item.id}`} text={item.title} className="type-subhead text-ink-100" /></div>
      </div>
      <div className="flex h-1/2 flex-col gap-1 p-3">
        <p className="type-kicker text-ink-45">{item.kicker}</p>
        {item.deck ? <p className="type-body line-clamp-2 text-ink-80">{item.deck}</p> : null}
        {item.why ? <p className="type-body-italic text-ink-60">{item.why}</p> : null}
        <div className="mt-auto flex flex-wrap items-center gap-1">
          <Button size="sm" onClick={onRead}>Read</Button>
          <Button size="sm" variant="secondary" onClick={onLibrary}>+ Library</Button>
          <Button size="sm" variant="quiet" onClick={onDetails}>Details</Button>
        </div>
      </div>
    </div>,
    document.body,
  );
}
