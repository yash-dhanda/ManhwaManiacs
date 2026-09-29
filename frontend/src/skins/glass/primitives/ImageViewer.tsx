"use client";

import { Dialog } from "@base-ui/react/dialog";
import { useGesture } from "@use-gesture/react";
import { motion, useMotionValue } from "motion/react";
import { useCallback, useEffect, useRef, useState } from "react";
import { GlassSurface } from "../glass/GlassSurface";
import { useAmbient } from "../glass/AmbientField";
import { haptic } from "../haptics";
import { isGlassReduced, play } from "../motion";
import { project } from "../physics/project";
import { Button } from "./Button";
import { Icon } from "./Icon";
import { focusQuiet, springTo, useGlassHost, useIsDesktop } from "./overlay-utils";
import { sheetTrigger, useSheetParam } from "./useSheetParam";
import { clamp } from "./slider-math";
import { DOUBLE_TAP_ZOOM, dragDismiss, isDoubleTap, keepFocal, MAX_ZOOM, MIN_ZOOM, panLimit, pastDismissLine, shouldDismiss } from "./viewer-math";

export const IMAGE_SHEET = "image";

/** Open the viewer from a thumbnail: URL state `?sheet=image`; the image zooms out of the thumbnail's rect. */
export const openImage = (thumb: HTMLElement | null) => import("./useSheetParam").then((m) => m.openSheet(IMAGE_SHEET, undefined, thumb));

/**
 * The image viewer (glass 7.31): pinch 1x to 4x around the focal point with a 0.18 rubber band, double tap 1x to 2.5x on `camera`,
 * pan with momentum, a vertical drag at 1x dismisses back into the thumbnail. Chrome fades after 2 s idle. Base UI Dialog supplies
 * the focus trap and Esc; the accessible name is the image description.
 */
export function ImageViewer({ src, thumbSrc, alt, "data-testid": tid }: { src: string; thumbSrc?: string; alt: string; "data-testid"?: string }) {
  const { open, close } = useSheetParam(IMAGE_SHEET);
  const [mounted, setMounted] = useState(open);
  if (open && !mounted) setMounted(true);
  if (!mounted) return null;
  return <ViewerBody src={src} thumbSrc={thumbSrc ?? src} alt={alt} open={open} close={close} onExited={() => setMounted(false)} tid={tid} />;
}

function ViewerBody({ src, thumbSrc, alt, open, close, onExited, tid }: { src: string; thumbSrc: string; alt: string; open: boolean; close: () => void; onExited: () => void; tid?: string }) {
  const host = useGlassHost();
  const desktop = useIsDesktop();
  const stage = useRef<HTMLDivElement | null>(null);
  const img = useRef<HTMLImageElement | null>(null);
  const sc = useMotionValue(1);
  const px = useMotionValue(0);
  const py = useMotionValue(0);
  const radius = useMotionValue(0);
  const bg = useMotionValue(0);
  const full = useMotionValue(0);
  const [status, setStatus] = useState<"loading" | "ready" | "error">("loading");
  const [tries, setTries] = useState(0);
  const [chrome, setChrome] = useState(true);
  const [zoomed, setZoomed] = useState(false);
  const idle = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const g = useRef({ s0: 1, pan0: [0, 0], over: false, lastTap: null as { t: number; x: number; y: number } | null, limitFired: false });
  const closing = useRef(false);
  useAmbient({ mood: "default", opacity: 0.4 });

  const poke = useCallback(() => {
    setChrome(true);
    clearTimeout(idle.current);
    idle.current = setTimeout(() => setChrome(false), 2000);
  }, []);
  useEffect(() => { poke(); return () => clearTimeout(idle.current); }, [poke]);

  const thumbRect = () => sheetTrigger(IMAGE_SHEET)?.getBoundingClientRect() ?? null;
  const toThumb = () => {
    const t = thumbRect(), el = img.current;
    if (!t || !el) return null;
    const r = el.getBoundingClientRect();
    const k = t.width / r.width;
    return { scale: k, x: t.left + t.width / 2 - (r.left + r.width / 2), y: t.top + t.height / 2 - (r.top + r.height / 2) };
  };

  // open: zoom out of the thumbnail on `zoom`; reduced: a 200 ms cross-fade
  useEffect(() => {
    const from = toThumb();
    const cs = [play("materialise", bg, 1)];
    if (from && !isGlassReduced()) {
      sc.set(from.scale); px.set(from.x); py.set(from.y);
      cs.push(play("zoom", sc, 1), play("zoom", px, 0), play("zoom", py, 0));
    }
    return () => cs.forEach((c) => c.stop());
    // mount only
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);
  useEffect(() => { setTimeout(() => focusQuiet(stage.current), 30); }, []);

  const exit = useCallback((vx = 0, vy = 0) => {
    if (closing.current) return;
    closing.current = true;
    const done = () => onExited();
    if (isGlassReduced()) { play("dematerialise", bg, 0, { onComplete: done }); return; }
    const to = toThumb();
    haptic("sheet.dismiss");
    play("dematerialise", bg, 0);
    if (to) {
      play("zoom", sc, to.scale, { velocity: 0 });
      play("zoom", px, to.x + px.get() * 0, { velocity: vx });
      play("zoom", py, to.y, { velocity: vy, onComplete: done });
    } else play("dematerialise", full, 0, { onComplete: done });
  }, [bg, full, onExited, px, py, sc]);
  useEffect(() => { if (!open) exit(); }, [open, exit]);

  const limitsOf = () => {
    const el = stage.current!;
    return { lx: panLimit(el.clientWidth, sc.get()), ly: panLimit(el.clientHeight, sc.get()) };
  };
  const setZoom = (target: number, focal?: { x: number; y: number }) => {
    const s0 = sc.get();
    const t = clamp(target, MIN_ZOOM, MAX_ZOOM);
    const f = focal ?? { x: 0, y: 0 };
    play("panelCamera", sc, t);
    if (t === 1) { play("panelCamera", px, 0); play("panelCamera", py, 0); }
    else { play("panelCamera", px, keepFocal(px.get(), f.x, s0, t)); play("panelCamera", py, keepFocal(py.get(), f.y, s0, t)); }
    setZoomed(t > 1);
    haptic("zoom.snap");
  };
  const rel = (cx: number, cy: number) => {
    const r = stage.current!.getBoundingClientRect();
    return { x: cx - (r.left + r.width / 2), y: cy - (r.top + r.height / 2) };
  };

  useGesture(
    {
      onPinchStart: () => { g.current.s0 = sc.get(); g.current.pan0 = [px.get(), py.get()]; g.current.limitFired = false; },
      onPinch: ({ offset: [s], origin: [ox, oy] }) => {
        const f = rel(ox, oy);
        sc.set(s);
        if ((s < MIN_ZOOM || s > MAX_ZOOM) && !g.current.limitFired) { g.current.limitFired = true; haptic("zoom.limit"); }
        px.set(keepFocal(g.current.pan0[0], f.x, g.current.s0, s));
        py.set(keepFocal(g.current.pan0[1], f.y, g.current.s0, s));
        setZoomed(s > 1.01);
      },
      onPinchEnd: () => {
        const s = clamp(sc.get(), MIN_ZOOM, MAX_ZOOM);
        play("rubberBand", sc, s);
        if (s === 1) { play("rubberBand", px, 0); play("rubberBand", py, 0); setZoomed(false); }
        else { const { lx, ly } = limitsOf(); play("rubberBand", px, clamp(px.get(), -lx, lx)); play("rubberBand", py, clamp(py.get(), -ly, ly)); }
      },
      onDragStart: () => { g.current.pan0 = [px.get(), py.get()]; g.current.over = false; poke(); },
      onDrag: ({ movement: [mx, my], velocity: [vx, vy], direction: [dx, dy], last, tap, pinching, event, xy }) => {
        if (pinching) return;
        if (tap && last) {
          const now = { t: performance.now(), x: xy[0], y: xy[1] };
          if (isDoubleTap(g.current.lastTap, now)) { g.current.lastTap = null; const f = rel(xy[0], xy[1]); setZoom(sc.get() > 1.05 ? 1 : DOUBLE_TAP_ZOOM, f); }
          else { g.current.lastTap = now; poke(); }
          return;
        }
        void event;
        if (sc.get() > 1.01) {
          const { lx, ly } = limitsOf();
          const raw = { x: g.current.pan0[0] + mx, y: g.current.pan0[1] + my };
          const soft = (v: number, l: number) => (Math.abs(v) <= l ? v : Math.sign(v) * (l + Math.min(40, (Math.abs(v) - l) * 0.3)));
          if (!last) { px.set(soft(raw.x, lx)); py.set(soft(raw.y, ly)); return; }
          const tx = clamp(project(px.get(), vx * dx * 1000), -lx, lx), ty = clamp(project(py.get(), vy * dy * 1000), -ly, ly);
          springTo(px, tx, "settle"); springTo(py, ty, "settle");
          return;
        }
        // 1x: a vertical drag dismisses
        const d = dragDismiss(my);
        if (!last) {
          px.set(mx * 0.6); py.set(my); sc.set(d.scale); radius.set(d.radius); bg.set(d.backdrop);
          const over = pastDismissLine(my, vy * dy * 1000);
          if (over !== g.current.over) { g.current.over = over; haptic(over ? "threshold.cross" : "threshold.back"); }
          return;
        }
        const vyPx = vy * dy * 1000;
        if (shouldDismiss(my, vyPx)) { close(); }
        else { springTo(py, 0, "settle"); springTo(px, 0, "settle"); springTo(sc, 1, "settle"); springTo(radius, 0, "settle"); springTo(bg, 1, "settle"); }
      },
    },
    { target: stage, eventOptions: { passive: false }, drag: { filterTaps: true, pointer: { touch: true }, from: () => [0, 0] }, pinch: { scaleBounds: { min: MIN_ZOOM, max: MAX_ZOOM }, rubberband: 0.18, from: () => [sc.get(), 0] } },
  );
  // a dismiss that started from the release velocity: `close()` flips the URL, `exit()` then flies back into the thumbnail

  const onKey = (e: React.KeyboardEvent) => {
    poke();
    if (e.key === "+" || e.key === "=") { e.preventDefault(); setZoom(sc.get() * 1.25); }
    else if (e.key === "-") { e.preventDefault(); setZoom(sc.get() / 1.25); }
    else if (e.key === "0") { e.preventDefault(); setZoom(1); }
    else if (sc.get() > 1.01 && e.key.startsWith("Arrow")) {
      e.preventDefault();
      const { lx, ly } = limitsOf();
      const step = 48;
      if (e.key === "ArrowLeft") px.set(clamp(px.get() + step, -lx, lx));
      if (e.key === "ArrowRight") px.set(clamp(px.get() - step, -lx, lx));
      if (e.key === "ArrowUp") py.set(clamp(py.get() + step, -ly, ly));
      if (e.key === "ArrowDown") py.set(clamp(py.get() - step, -ly, ly));
    }
  };

  const share = async () => {
    try {
      const blob = await (await fetch(src)).blob();
      const file = new File([blob], "image", { type: blob.type });
      if (navigator.canShare?.({ files: [file] })) await navigator.share({ files: [file], title: alt });
      else if (navigator.share) await navigator.share({ url: src, title: alt });
      else await navigator.clipboard?.writeText(src);
    } catch { /* cancelled */ }
  };

  if (!host) return null;
  return (
    <Dialog.Root open modal onOpenChange={(o) => { if (!o) close(); }}>
      <Dialog.Portal container={host}>
        <Dialog.Popup className="g-viewer" initialFocus={false} aria-label={alt} onKeyDown={onKey} onPointerMove={poke} data-testid={tid ?? "image-viewer"} data-zoomed={zoomed ? "" : undefined} data-chrome={chrome ? "" : "hidden"}
          render={(p) => <div {...(p as object)} />}>
          <Dialog.Title className="sr-only">{alt}</Dialog.Title>
          <motion.div className="g-viewer__bg" style={{ opacity: bg }} />
          <div ref={stage} className="g-viewer__stage" tabIndex={0} data-cursor={zoomed ? "zoom-out" : "zoom-in"}>
            <motion.div className="g-viewer__frame" style={{ x: px, y: py, scale: sc, borderRadius: radius }}>
              <img ref={img} key={`t${tries}`} className="g-viewer__thumb" src={thumbSrc} alt="" data-loading={status !== "ready" ? "" : undefined} draggable={false} />
              <motion.img key={`f${tries}`} className="g-viewer__img" src={src} alt={alt} draggable={false} style={{ opacity: full }}
                onLoad={() => { setStatus("ready"); play("materialise", full, 1); }} onError={() => setStatus("error")} />
            </motion.div>
            {status === "error" ? (
              <div className="g-viewer__error" role="alert">
                <GlassSurface tier="t3" radius={26} layer="overlays" materialize={false} className="g-viewer__errglass">
                  <div className="g-viewer__errinner"><p>Couldn&apos;t load this image</p><Button variant="secondary" size="M" label="Retry" twin="onGlass" onPress={() => { setStatus("loading"); setTries((n) => n + 1); }} /></div>
                </GlassSurface>
              </div>
            ) : null}
          </div>
          <div className="g-viewer__chrome">
            <GlassSurface tier="t1" finish="clear" capsule layer="hud" materialize={false} className="g-viewer__btn g-viewer__btn--close">
              <button type="button" aria-label="Close" onClick={() => close()}><Icon name="x" size={20} /></button>
            </GlassSurface>
            <div className="g-viewer__right">
              <GlassSurface tier="t1" finish="clear" capsule layer="hud" materialize={false} className="g-viewer__btn"><button type="button" aria-label="Share" onClick={() => void share()}><Icon name="share" size={20} /></button></GlassSurface>
              {desktop ? <GlassSurface tier="t1" finish="clear" capsule layer="hud" materialize={false} className="g-viewer__btn"><a aria-label="Save" href={src} download><Icon name="download-simple" size={20} /></a></GlassSurface> : null}
            </div>
          </div>
        </Dialog.Popup>
      </Dialog.Portal>
    </Dialog.Root>
  );
}
