"use client";
import { Dialog } from "@base-ui/react/dialog";
import { useDrag, usePinch } from "@use-gesture/react";
import { animate } from "motion/react";
import { useCallback, useEffect, useRef, useState } from "react";
import { haptic } from "../haptics";
import { readReduced } from "../motion";
import { durMs, ease, spring } from "../tokens.generated";
import { Glyph } from "./glyphs";
import { IconButton } from "./IconButton";
import { useDesktopFrame } from "./overlay-hooks";
import { BARRIER_MAX, barrierOpacity, clampZoom, containSize, coverFolio, pageFolio, panForZoom, shouldDismissLightbox, toggleZoom, zoomLabel } from "./lightbox-math";

const TURN = ease.turn as unknown as [number, number, number, number];
const SETTLE = ease.settle as unknown as [number, number, number, number];
const FLAG = "border border-ink-100 bg-paper-0 px-2 py-1";

export type LightboxProps = {
  open: boolean; onOpenChange: (o: boolean) => void;
  /** Full-size image. */
  src: string;
  /** The cached crop shown at once while the full image loads (and kept if it fails). */
  thumbSrc?: string;
  title: string; kind?: "cover" | "page"; page?: number;
  naturalW: number; naturalH: number;
  /** The art's frame on the page, for the match cut. */
  from?: DOMRect | null;
  offline?: boolean;
  "data-gallery"?: string;
};

/**
 * §7.30 Lightbox: color.lightbox over everything, no bloom/grain/drift; contain at <= 1.5x natural; pinch 1-4x, double tap 2.5x,
 * keys = - 0, Ctrl/Cmd+wheel; drag down at 1x dismisses (120 px or 800 px/s); ?view=cover history entry; chrome hides after 3000 ms.
 */
export function Lightbox({ open, onOpenChange, src, thumbSrc, title, kind = "cover", page, naturalW, naturalH, from, offline = false, ...rest }: LightboxProps) {
  const desktop = useDesktopFrame();
  const flip = useRef<HTMLDivElement>(null);
  const barrier = useRef<HTMLDivElement>(null);
  const [view, setView] = useState({ z: 1, x: 0, y: 0 });
  const viewRef = useRef(view);
  const [smooth, setSmooth] = useState(false);
  const [chrome, setChrome] = useState(true);
  const [chip, setChip] = useState(false);
  const [loaded, setLoaded] = useState<"loading" | "ok" | "failed">("loading");
  const [size, setSize] = useState({ w: 0, h: 0 });
  const idle = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const chipT = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const chromeEl = useRef<HTMLDivElement>(null);
  const closing = useRef(false);
  const pushed = useRef(false);

  const set = useCallback((v: { z: number; x: number; y: number }, glide = false) => { viewRef.current = v; setSmooth(glide); setView(v); }, []);
  const showChip = () => { setChip(true); clearTimeout(chipT.current); chipT.current = setTimeout(() => setChip(false), durMs.holdChip); };
  const wake = useCallback(() => {
    setChrome(true); clearTimeout(idle.current);
    idle.current = setTimeout(() => { if (!chromeEl.current?.contains(document.activeElement)) setChrome(false); }, 3000);
  }, []);

  // Size at rest and reset per open.
  useEffect(() => {
    if (!open) return;
    const fit = () => setSize(containSize(naturalW, naturalH, window.innerWidth, window.innerHeight));
    fit(); window.addEventListener("resize", fit);
    set({ z: 1, x: 0, y: 0 }); setLoaded("loading"); closing.current = false; wake(); // eslint-disable-line react-hooks/set-state-in-effect -- reset per open
    return () => { window.removeEventListener("resize", fit); clearTimeout(idle.current); clearTimeout(chipT.current); };
  }, [open, naturalW, naturalH, set, wake]);

  // Browser back: ?view=cover pushed on open; closing another way pops it once.
  useEffect(() => {
    if (!open) return;
    const url = new URL(window.location.href); url.searchParams.set("view", "cover");
    window.history.pushState({ view: "cover" }, "", url); pushed.current = true;
    const onPop = () => { pushed.current = false; onOpenChange(false); };
    window.addEventListener("popstate", onPop);
    return () => { window.removeEventListener("popstate", onPop); if (pushed.current) { pushed.current = false; window.history.back(); } };
    // eslint-disable-next-line react-hooks/exhaustive-deps -- once per open
  }, [open]);

  // Open: match cut from the source frame (480 ms ease.turn); barrier 0 -> 0.96 in 240 ms. Reduced: 150 ms fades.
  useEffect(() => {
    if (!open) return;
    haptic("longpress.open");
    const el = flip.current, bar = barrier.current; if (!el || !bar) return;
    const reduced = readReduced();
    animate(bar, { opacity: [0, BARRIER_MAX] }, { duration: (reduced ? durMs.reduced : durMs.line) / 1000, ease: "linear" });
    if (reduced || !from) { animate(el, { opacity: [0, 1] }, { duration: durMs.reduced / 1000 }); return; }
    const to = el.getBoundingClientRect();
    if (!to.width) return;
    animate(el, { x: [from.left + from.width / 2 - (to.left + to.width / 2), 0], y: [from.top + from.height / 2 - (to.top + to.height / 2), 0], scaleX: [from.width / to.width, 1], scaleY: [from.height / to.height, 1] }, { duration: durMs.spread / 1000, ease: TURN });
  }, [open, from]);

  const leave = useCallback((mode: "button" | "flick") => {
    if (closing.current) return; closing.current = true;
    const el = flip.current, bar = barrier.current;
    const reduced = readReduced();
    const done = () => onOpenChange(false);
    if (!el || !bar) { done(); return; }
    if (reduced || !from) {
      animate(bar, { opacity: 0 }, { duration: durMs.reduced / 1000 }); animate(el, { opacity: 0 }, { duration: durMs.reduced / 1000 }).then(done); return;
    }
    animate(bar, { opacity: 0 }, { duration: durMs.line / 1000 });
    const target = { x: from.left + from.width / 2 - window.innerWidth / 2, y: from.top + from.height / 2 - window.innerHeight / 2, scaleX: from.width / Math.max(1, size.w), scaleY: from.height / Math.max(1, size.h) };
    const o = mode === "button" ? { duration: durMs.column / 1000, ease: TURN } : spring.release;
    animate(el, target, o).then(done);
  }, [from, onOpenChange, size]);

  const zoomTo = useCallback((z: number, pointer = { x: 0, y: 0 }, glide = true) => {
    const cur = viewRef.current, nz = clampZoom(z);
    const p = panForZoom(pointer, cur.z, nz, { x: cur.x, y: cur.y });
    set({ z: nz, x: p.x, y: p.y }, glide); showChip();
    if (glide) haptic("zoom.snap");
  }, [set]);

  const bindDrag = useDrag(({ movement: [, my], velocity: [, vy], direction: [, dy], last, tap }) => {
    wake();
    if (tap || viewRef.current.z > 1.01) return;
    const el = flip.current, bar = barrier.current; if (!el || !bar) return;
    if (!last) { const d = Math.max(0, my); el.style.transform = `translateY(${d}px)`; bar.style.opacity = String(barrierOpacity(d)); return; }
    const d = Math.max(0, my);
    if (shouldDismissLightbox(d, dy > 0 ? vy * 1000 : 0)) leave("flick");
    else { animate(el, { y: 0 }, spring.release); animate(bar, { opacity: BARRIER_MAX }, spring.release); }
  }, { filterTaps: true, pointer: { touch: true }, enabled: open });

  // Pan when zoomed (kept separate so it can use offset accumulation).
  const panStart = useRef({ x: 0, y: 0 });
  const bindPan = useDrag(({ movement: [mx, my], first }) => {
    const cur = viewRef.current; if (cur.z <= 1.01) return;
    if (first) panStart.current = { x: cur.x, y: cur.y };
    const lim = { x: (size.w * cur.z) / 2, y: (size.h * cur.z) / 2 };
    set({ z: cur.z, x: Math.max(-lim.x, Math.min(lim.x, panStart.current.x + mx)), y: Math.max(-lim.y, Math.min(lim.y, panStart.current.y + my)) }, false);
  }, { filterTaps: true, enabled: open });

  usePinch(({ offset: [scale], origin: [ox, oy], first }) => {
    if (first) wake();
    const rect = flip.current?.getBoundingClientRect();
    const c = rect ? { x: ox - (rect.left + rect.width / 2), y: oy - (rect.top + rect.height / 2) } : { x: 0, y: 0 };
    zoomTo(scale, c, false);
  }, { scaleBounds: { min: 1, max: 4 }, from: () => [viewRef.current.z, 0], target: flip, eventOptions: { passive: false }, enabled: open });

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "=" || e.key === "+") { e.preventDefault(); zoomTo(viewRef.current.z * 1.25); }
      else if (e.key === "-") { e.preventDefault(); zoomTo(viewRef.current.z / 1.25); }
      else if (e.key === "0") { e.preventDefault(); zoomTo(1); }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [open, zoomTo]);

  const onWheel = (e: React.WheelEvent) => {
    if (!(e.ctrlKey || e.metaKey)) return;
    e.preventDefault();
    const rect = flip.current?.getBoundingClientRect();
    const c = rect ? { x: e.clientX - (rect.left + rect.width / 2), y: e.clientY - (rect.top + rect.height / 2) } : { x: 0, y: 0 };
    zoomTo(viewRef.current.z * Math.exp(-e.deltaY / 300), c, false);
  };
  const onDouble = (e: React.MouseEvent) => {
    const rect = flip.current?.getBoundingClientRect();
    const c = rect ? { x: e.clientX - (rect.left + rect.width / 2), y: e.clientY - (rect.top + rect.height / 2) } : { x: 0, y: 0 };
    zoomTo(toggleZoom(viewRef.current.z), c);
  };

  const folio = kind === "page" && page ? pageFolio(page, naturalW, naturalH) : coverFolio(naturalW, naturalH);
  const zoomed = view.z > 1.01;
  return (
    <Dialog.Root open={open} onOpenChange={(o) => { if (!o) leave("button"); }}>
      <Dialog.Portal>
        <Dialog.Popup aria-label={`Cover of ${title}`} aria-modal="true" data-gallery={rest["data-gallery"]} initialFocus={() => chromeEl.current?.querySelector("button")}
          onPointerMove={wake} onPointerDown={wake} onWheel={onWheel}
          className="group fixed inset-0 flex items-center justify-center overflow-hidden outline-none" style={{ zIndex: "var(--mm-z-lightbox)" }}>
          <div ref={barrier} aria-hidden className="absolute inset-0 bg-lightbox" style={{ opacity: BARRIER_MAX }} />
          <div ref={flip} {...bindDrag()} style={{ width: size.w, height: size.h, touchAction: zoomed ? "none" : "pan-x", transformOrigin: "50% 50%" }} className="relative">
            <div {...bindPan()} onDoubleClick={onDouble}
              style={{ width: "100%", height: "100%", transform: `translate(${view.x}px, ${view.y}px) scale(${view.z})`, transition: smooth ? `transform ${durMs.line}ms cubic-bezier(${SETTLE.join(",")})` : "none", cursor: zoomed ? "grab" : "default", touchAction: "none" }}>
              {/* eslint-disable-next-line @next/next/no-img-element -- the cached crop must show at once, before the full image */}
              {thumbSrc ? <img src={thumbSrc} alt="" draggable={false} className="absolute inset-0 size-full object-contain" /> : null}
              {!offline && loaded !== "failed" ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img src={src} alt={`Cover of ${title}`} draggable={false} onLoad={() => setLoaded("ok")} onError={() => setLoaded("failed")}
                  className="absolute inset-0 size-full object-contain transition-opacity duration-(--mm-dur-line)" style={{ opacity: loaded === "ok" ? 1 : 0 }} />
              ) : null}
            </div>
          </div>
          <div ref={chromeEl} className={`transition-opacity duration-(--mm-dur-line) ${chrome ? "opacity-100" : "opacity-0 focus-within:opacity-100"}`}>
            <div className="absolute top-3 right-3"><Dialog.Close render={<IconButton label="Close" icon="close" variant="on-art" />} /></div>
            <div className="absolute bottom-3 left-3 flex flex-col items-start gap-1">
              {loaded === "failed" || offline ? <p role="status" className={`type-caption ${FLAG} ${loaded === "failed" ? "text-proof" : "text-ink-60"}`}>{loaded === "failed" ? "Couldn't load the full cover." : "Offline: showing the saved copy."}</p> : null}
              <p className={`type-caption text-ink-60 ${FLAG}`}>{title}</p>
              <p className={`type-folio text-ink-100 ${FLAG}`}>{folio}</p>
            </div>
            <div className={`absolute right-3 bottom-3 items-center gap-2 ${desktop ? "flex" : "hidden group-focus-within:flex"}`}>
              <ZoomBtn label="Zoom in" onClick={() => zoomTo(view.z * 1.25)}><Glyph name="plus" size={20} /></ZoomBtn>
              <ZoomBtn label="Zoom out" onClick={() => zoomTo(view.z / 1.25)}><Glyph name="minus" size={20} /></ZoomBtn>
              <ZoomBtn label="Fit" onClick={() => zoomTo(1)}><span className="type-label">Fit</span></ZoomBtn>
            </div>
          </div>
          {chip ? <p role="status" className={`type-folio absolute top-3 left-1/2 -translate-x-1/2 text-ink-100 ${FLAG}`}>{zoomLabel(view.z)}</p> : null}
        </Dialog.Popup>
      </Dialog.Portal>
    </Dialog.Root>
  );
}

function ZoomBtn({ label, onClick, children }: { label: string; onClick: () => void; children: React.ReactNode }) {
  return <button type="button" aria-label={label} onClick={onClick} className="inline-flex min-h-(--mm-hit-min) min-w-(--mm-hit-min) items-center justify-center bg-onart text-ink-100">{children}</button>;
}
