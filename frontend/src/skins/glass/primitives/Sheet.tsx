"use client";

import { Dialog } from "@base-ui/react/dialog";
import { animate, motion, useDragControls, useMotionValue, useMotionValueEvent, useTransform, type MotionStyle, type MotionValue } from "motion/react";
import {
  createContext, useCallback, useContext, useEffect, useLayoutEffect, useMemo, useRef, useState,
  type CSSProperties, type ReactNode, type RefObject,
} from "react";
import { GlassSurface } from "../glass/GlassSurface";
import { useLb } from "../glass/useLb";
import { haptic } from "../haptics";
import { isGlassReduced, play } from "../motion";
import { beginRecord, trackFrames } from "../motion-recorder";
import { MOTION_LABELS } from "../motion.generated";
import { createTracker, catchMotion, slope } from "../physics/tracker";
import { Button } from "./Button";
import { Icon } from "./Icon";
import { suppressLit } from "./lit";
import { clamp01, focusQuiet, safeTop, springTo, trapTab, useGlassHost, useIsDesktop } from "./overlay-utils";
import { Skeleton } from "./Skeleton";
import {
  detentsPassed, detentTops, dismissLine, largeProgress, MEDIUM_RATIO, pickDetent, projectedTop, applyRubberBand,
  type Detent, type DetentName,
} from "./sheet-physics";
import { sheetTrigger, useSheetParam } from "./useSheetParam";

export type SheetDesktop = "panel" | "window" | "detailWindow" | "popover";
export type SheetState = "ready" | "loading" | "error" | "empty";

export interface SheetProps {
  /** kebab-case id: the URL is `?sheet={id}` */
  id: string;
  title: string;
  children?: ReactNode;
  /** the detents this sheet uses on phones; default medium and large */
  detents?: readonly DetentName[];
  initialDetent?: DetentName;
  /** the form at 768 px and wider; default `panel` */
  desktop?: SheetDesktop;
  /** `monolith` is the listen full player: T5 glass at medium, solid2 at large */
  material?: "glass" | "monolith";
  /** centre the title (pickers) */
  centerTitle?: boolean;
  /** an optional leading header action */
  headerLeading?: ReactNode;
  /** the element that recedes behind a tall sheet (the page wrapper); the sheet writes --sheet-progress on it */
  recedeTarget?: RefObject<HTMLElement | null>;
  state?: SheetState;
  errorText?: string;
  onRetry?: () => void;
  emptyCopy?: string;
  /** the element a bloom grows out of; defaults to the element focused when the sheet opened */
  triggerRef?: RefObject<HTMLElement | null>;
  "data-testid"?: string;
}

const SheetCtx = createContext<{ scroller: RefObject<HTMLDivElement | null> } | null>(null);
export const useSheetScroller = () => useContext(SheetCtx)?.scroller ?? null;

/** Base UI Dialog owns focus, roles and dismissal; Motion owns every movement. */
export function Sheet(props: SheetProps) {
  const { open } = useSheetParam(props.id);
  const desktop = useIsDesktop();
  const [mounted, setMounted] = useState(open);
  if (open && !mounted) setMounted(true); // derive during render: the exit animation keeps it mounted after `open` goes false
  if (!mounted) return null;
  const done = () => setMounted(false);
  return desktop ? <DesktopSheet {...props} onExited={done} /> : <PhoneSheet {...props} onExited={done} />;
}

/* ---------------------------------------------------------------- shared chrome */

function SheetBody({ state = "ready", errorText, onRetry, emptyCopy, children, scrollerRef, style, onFocusCapture }: Pick<SheetProps, "state" | "errorText" | "onRetry" | "emptyCopy" | "children"> & { scrollerRef: RefObject<HTMLDivElement | null>; style?: MotionStyle; onFocusCapture?: (e: React.FocusEvent) => void }) {
  return (
    <motion.div ref={scrollerRef} className="g-sheet__body" style={style} onFocusCapture={onFocusCapture} data-state={state} aria-busy={state === "loading" || undefined}>
      {state === "loading" ? (
        <div className="g-sheet__skeleton" aria-hidden="true">{[0, 1, 2, 3].map((i) => <Skeleton key={i} shape="line" height={44} radius={20} row={i} />)}</div>
      ) : state === "error" ? (
        <div className="g-sheet__error" role="alert">
          <span className="g-disc"><Icon name="warning-circle" size={22} color="var(--mm-color-danger)" /></span>
          <p className="type-callout">{errorText ?? "Couldn't load this."}</p>
          {onRetry ? <Button variant="secondary" size="M" label="Retry" twin="onGlass" onPress={onRetry} /> : null}
        </div>
      ) : state === "empty" ? (
        <p className="g-sheet__empty type-callout">{emptyCopy ?? "Nothing here yet."}</p>
      ) : children}
    </motion.div>
  );
}

function Header({ title, titleRef, centerTitle, headerLeading, onClose, dragHandlers }: { title: string; titleRef: RefObject<HTMLHeadingElement | null>; centerTitle?: boolean; headerLeading?: ReactNode; onClose: () => void; dragHandlers?: { onPointerDown: (e: React.PointerEvent) => void } }) {
  return (
    <header className="g-sheet__header" data-center={centerTitle ? "" : undefined} {...dragHandlers}>
      <div className="g-sheet__lead">{headerLeading}</div>
      <Dialog.Title ref={titleRef} tabIndex={-1} className="g-sheet__title type-title2">{title}</Dialog.Title>
      <button type="button" className="g-sheet__close" aria-label="Close" onClick={onClose} onPointerDown={(e) => e.stopPropagation()} data-cursor="pointer">
        <span className="g-sheet__closeDisc"><Icon name="x" size={16} weight="regular" /></span>
      </button>
    </header>
  );
}

/** Where focus goes when the sheet closes: the trigger it opened from, if it is still on the page. */
function useFinalFocus(id: string, triggerRef?: RefObject<HTMLElement | null>) {
  return () => {
    const el = triggerRef?.current ?? sheetTrigger(id);
    return el && el.isConnected ? el : true;
  };
}

/** The origin of a bloom: the centre of the trigger, in viewport px. */
function originOf(id: string, triggerRef?: RefObject<HTMLElement | null>) {
  const el = triggerRef?.current ?? sheetTrigger(id);
  if (!el || !el.isConnected) return null;
  const r = el.getBoundingClientRect();
  if (!r.width && !r.height) return null;
  return { x: r.left + r.width / 2, y: r.top + r.height / 2, rect: r };
}

function useRecede(target: RefObject<HTMLElement | null> | undefined, write: boolean, cls: "glass-recede" | "glass-recede-window") {
  const set = (p: number) => {
    const el = target?.current;
    if (!el || !write) return;
    el.classList.add(cls);
    el.style.setProperty("--sheet-progress", p.toFixed(4));
  };
  useEffect(() => () => {
    const el = target?.current;
    if (!el || !write) return;
    el.style.removeProperty("--sheet-progress");
    el.classList.remove(cls);
  }, [target, write, cls]);
  return set;
}

/* ---------------------------------------------------------------- phone: the physics sheet */

function PhoneSheet({ id, title, children, detents: names = ["medium", "large"], initialDetent, material = "glass", centerTitle, headerLeading, recedeTarget, state, errorText, onRetry, emptyCopy, triggerRef, onExited, "data-testid": tid }: SheetProps & { onExited: () => void }) {
  const { open, covered, stacked, close } = useSheetParam(id);
  const host = useGlassHost();
  const titleRef = useRef<HTMLHeadingElement | null>(null);
  const scroller = useRef<HTMLDivElement | null>(null);
  const layer = useRef<HTMLDivElement | null>(null);
  const surface = useRef<HTMLElement | null>(null);
  const popup = useRef<HTMLElement | null>(null);
  const controls = useDragControls();
  const finalFocus = useFinalFocus(id, triggerRef);

  const namesKey = names.join(",");
  const geo = useMemo(() => {
    const vh = typeof window === "undefined" ? 844 : window.innerHeight;
    const st = safeTop();
    const list = detentTops(vh, st, namesKey.split(",") as DetentName[]);
    const largeTop = st + 10;
    const mediumTop = vh - vh * MEDIUM_RATIO;
    const yOf = (top: number) => top - largeTop;
    return { vh, list, largeTop, mediumTop, H: vh - largeTop, yOf, yTopDet: yOf(list[0].top), lowest: list[list.length - 1] };
  }, [namesKey]);
  const { vh, list, largeTop, mediumTop, H, yOf, yTopDet, lowest } = geo;
  const initial: Detent = list.find((d) => d.name === (initialDetent ?? (names.includes("medium") ? "medium" : lowest.name))) ?? lowest;

  const rawY = useMotionValue(H);
  const fade = useMotionValue(1);
  const y = useTransform(rawY, (r) => yTopDet + applyRubberBand(r - yTopDet, vh));
  const scale = useMotionValue(1);
  const cover = useMotionValue(0);
  const kb = useMotionValue(0);
  const closing = useRef(false);
  const exited = useRef(false);
  const lastTop = useRef(largeTop + H);
  const overLine = useRef(false);
  const dragging = useRef(false);
  const draggedFlag = useRef(false);
  const [detentName, setDetentName] = useState<DetentName>(initial.name);

  // only the lowest sheet blurs the page: a lone sheet, or the covered one of a stack
  const writeRecede = useRecede(recedeTarget, !stacked || covered, "glass-recede");
  const writeVars = useCallback((yy: number) => {
    const top = largeTop + yy;
    const p = names.length === 1 && names[0] === "large" ? clamp01((vh - top) / (vh - largeTop)) : largeProgress(top, mediumTop, largeTop);
    const closed = clamp01((H - yy) / Math.max(1, H - yOf(lowest.top)));
    const el = layer.current;
    if (el) {
      el.style.setProperty("--sheet-p", p.toFixed(4));
      el.style.setProperty("--sheet-dim", (closed * (recedeTarget ? 1 - p : 1) * fade.get()).toFixed(4));
    }
    writeRecede(p * closed * fade.get());
    popup.current?.toggleAttribute("data-large", p >= 0.999);
  }, [H, fade, largeTop, lowest.top, mediumTop, names, recedeTarget, vh, writeRecede, yOf]);
  useMotionValueEvent(y, "change", writeVars);
  useMotionValueEvent(fade, "change", () => writeVars(y.get()));
  useLayoutEffect(() => { writeVars(y.get()); }, [writeVars, y]);

  useEffect(() => suppressLit(), []);

  /* ---- present ---- */
  useEffect(() => {
    const target = yOf(initial.top);
    const finish = trackFrames(beginRecord("recede", MOTION_LABELS.recede, 0));
    const origin = originOf(id, triggerRef);
    let c: { stop: () => void } | undefined;
    if (isGlassReduced()) {
      rawY.set(target + 16);
      fade.set(0);
      c = animate(fade, 1, { duration: 0.15, ease: "linear" });
      animate(rawY, target, { duration: 0.15, ease: "linear" });
    } else {
      rawY.set(H);
      if (origin && origin.y > vh * 0.75 && popup.current) {
        popup.current.style.transformOrigin = `${origin.x}px ${origin.y - largeTop}px`;
        scale.set(0.92);
        play("bloom", scale, 1);
      }
      c = play("sheetPresent", rawY, target, { onComplete: () => { haptic("sheet.detent"); } });
    }
    const t = setTimeout(finish, 700);
    return () => { clearTimeout(t); finish(); c?.stop(); };
    // mount only
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);
  useEffect(() => { const t = setTimeout(() => focusQuiet(titleRef.current), 30); return () => clearTimeout(t); }, []);

  /* ---- dismiss ---- */
  const dismiss = useCallback((velocity = 0) => {
    if (closing.current) return;
    closing.current = true;
    haptic("sheet.dismiss");
    scroller.current?.blur();
    const done = () => { if (!exited.current) { exited.current = true; onExited(); } };
    if (isGlassReduced()) {
      animate(fade, 0, { duration: 0.15, ease: "linear", onComplete: done });
      animate(rawY, rawY.get() + 16, { duration: 0.15, ease: "linear" });
    } else springTo(rawY, H, "dismiss", { velocity, onComplete: done });
  }, [H, fade, onExited, rawY]);
  const releaseVelocity = useRef(0);
  useEffect(() => { if (!open) dismiss(releaseVelocity.current); }, [open, dismiss]);
  const requestClose = useCallback((velocity = 0) => { releaseVelocity.current = velocity; close(); }, [close]);

  /* ---- drag frame: sheet.pass, threshold.cross / back ---- */
  const samples = useRef<{ t: number; v: number }[]>([]);
  const dragFrame = useCallback(() => {
    const top = largeTop + rawY.get();
    const now = performance.now();
    samples.current.push({ t: now, v: top });
    while (samples.current.length > 2 && now - samples.current[0].t > 100) samples.current.shift();
    if (detentsPassed(lastTop.current, top, list) > 0) haptic("sheet.pass");
    lastTop.current = top;
    if (samples.current.length < 3) return; // too few frames for a stable velocity
    const over = projectedTop(top, slope(samples.current)) > dismissLine(lowest.top, vh - lowest.top);
    if (over !== overLine.current) { overLine.current = over; haptic(over ? "threshold.cross" : "threshold.back"); }
  }, [largeTop, list, lowest.top, rawY, vh]);

  const settleTo = useCallback((d: Detent, velocity: number) => {
    setDetentName(d.name);
    play("sheetSnap", rawY, yOf(d.top), { velocity, onComplete: () => haptic("sheet.detent") });
  }, [rawY, yOf]);

  const release = useCallback((velocity: number) => {
    dragging.current = false;
    samples.current = [];
    const top = largeTop + Math.max(rawY.get(), yTopDet);
    const pick = pickDetent({ top: largeTop + rawY.get() < list[0].top ? list[0].top : top, velocity, detents: list, sheetHeight: vh - lowest.top });
    overLine.current = false;
    if (pick.kind === "dismiss") requestClose(velocity);
    else settleTo(pick, velocity);
  }, [largeTop, list, lowest.top, rawY, requestClose, settleTo, vh, yTopDet]);

  const goTo = useCallback((name: DetentName) => {
    const d = list.find((x) => x.name === name);
    if (d) settleTo(d, 0);
  }, [list, settleTo]);
  const cycle = useCallback((dir: 1 | -1 | 0) => {
    const idx = Math.max(0, list.findIndex((d) => d.name === detentName));
    const next = dir === 0 ? (idx + 1) % list.length : Math.min(list.length - 1, Math.max(0, idx + (dir === 1 ? -1 : 1)));
    goTo(list[next].name);
  }, [detentName, goTo, list]);

  /* ---- catch a flying sheet: a touch stops it exactly where it is ---- */
  const onPointerDownCapture = (e: React.PointerEvent) => {
    if (!rawY.isAnimating()) return;
    catchMotion(rawY, () => haptic("motion.catch"));
    if (closing.current) { closing.current = false; exited.current = false; if (!open) import("./useSheetParam").then((m) => m.openSheet(id, undefined, sheetTrigger(id))); }
    if ((e.target as HTMLElement).closest(".g-sheet__body")) return; // the body's own touch handler takes it
    controls.start(e.nativeEvent);
  };

  /* ---- body hand-off: our own gesture, because touch-action: pan-y hands pointer events to the browser ---- */
  useEffect(() => {
    const body = scroller.current;
    if (!body) return;
    const s = { mode: "idle" as "idle" | "drag" | "scroll", y0: 0, raw0: 0, tracker: createTracker("y"), wasCaught: false };
    const at = (t: Touch, e: TouchEvent) => ({ clientX: t.clientX, clientY: t.clientY, timeStamp: e.timeStamp, pointerType: "touch" });
    const start = (e: TouchEvent) => {
      const t = e.touches[0];
      s.y0 = t.clientY;
      s.mode = "idle";
      s.tracker.start(at(t, e));
      if (rawY.isAnimating()) {
        catchMotion(rawY, () => haptic("motion.catch"));
        s.mode = "drag"; s.raw0 = rawY.get(); s.wasCaught = true;
        lastTop.current = largeTop + s.raw0;
      }
    };
    const move = (e: TouchEvent) => {
      const t = e.touches[0];
      const dy = t.clientY - s.y0;
      if (s.mode === "scroll") return;
      if (s.mode === "idle") {
        if (Math.abs(dy) < 4) return;
        const partial = rawY.get() > yTopDet + 1;
        if ((dy > 0 && body.scrollTop <= 0) || (dy < 0 && partial)) {
          s.mode = "drag"; s.raw0 = rawY.get(); s.y0 = t.clientY; dragging.current = true; s.tracker.start(at(t, e), 0);
          lastTop.current = largeTop + s.raw0;
        } else { s.mode = "scroll"; return; }
      }
      if (e.cancelable) e.preventDefault();
      s.tracker.move(at(t, e));
      rawY.set(s.raw0 + (t.clientY - s.y0));
      dragFrame();
    };
    const end = (e: TouchEvent) => {
      if (s.mode === "drag") {
        const last = e.changedTouches[0];
        s.tracker.move(at(last, e));
        release(s.tracker.end().velocity);
      }
      s.mode = "idle";
    };
    body.addEventListener("touchstart", start, { passive: true });
    body.addEventListener("touchmove", move, { passive: false });
    body.addEventListener("touchend", end);
    body.addEventListener("touchcancel", end);
    return () => { body.removeEventListener("touchstart", start); body.removeEventListener("touchmove", move); body.removeEventListener("touchend", end); body.removeEventListener("touchcancel", end); };
  }, [dragFrame, largeTop, rawY, release, yTopDet]);

  /* ---- on-screen keyboard (phones) ---- */
  const onFocusCapture = (e: React.FocusEvent) => {
    const el = e.target as HTMLElement;
    if (!el.matches("input, textarea, select, [contenteditable='true']")) return;
    if (detentName !== "large" && list.some((d) => d.name === "large")) goTo("large");
    setTimeout(() => {
      const vv = window.visualViewport;
      const visible = vv ? vv.height : window.innerHeight;
      const body = scroller.current;
      if (!body) return;
      const r = el.getBoundingClientRect();
      const br = body.getBoundingClientRect();
      body.scrollBy({ top: r.top - br.top - visible * 0.3, behavior: isGlassReduced() ? "auto" : "smooth" });
    }, 250);
  };
  useEffect(() => {
    const vv = window.visualViewport;
    if (!vv) return;
    const on = () => {
      const h = Math.max(0, Math.round(window.innerHeight - vv.height));
      if (Math.abs(kb.get() - h) > 1) play("sheetSnap", kb, h);
    };
    vv.addEventListener("resize", on);
    return () => vv.removeEventListener("resize", on);
  }, [kb]);

  /* ---- stacking (a second sheet above) ---- */
  useEffect(() => { play("stackFan", cover, covered ? 1 : 0); }, [covered, cover]);

  const lb = useLb({ kind: "bar", ref: surface });
  const monolith = material === "monolith";

  if (!host) return null;
  return (
    <Dialog.Root open modal onOpenChange={(o) => { if (!o) requestClose(0); }} disablePointerDismissal={false}>
      <Dialog.Portal container={host}>
        <div ref={layer} className="g-sheet-layer" data-covered={covered ? "" : undefined} data-detent={detentName} style={{ "--sheet-dim": 0, "--sheet-p": 0 } as CSSProperties}>
          <Dialog.Backdrop className="g-sheet__dim" render={<motion.div onClick={() => requestClose(0)} />} />
          <Dialog.Popup
            className="g-sheet"
            onKeyDown={trapTab}
            initialFocus={titleRef}
            finalFocus={finalFocus}
            render={(props) => (
              <motion.div
                {...(props as object)}
                ref={(el: HTMLDivElement | null) => { popup.current = el; const r = (props as { ref?: React.Ref<HTMLDivElement> }).ref; if (typeof r === "function") r(el); else if (r) (r as { current: HTMLDivElement | null }).current = el; }}
                drag="y"
                dragListener={false}
                dragControls={controls}
                dragMomentum={false}
                dragElastic={0}
                _dragY={rawY}
                onDragStart={() => { dragging.current = true; draggedFlag.current = true; samples.current = []; overLine.current = false; lastTop.current = largeTop + rawY.get(); }}
                onDrag={dragFrame}
                onDragEnd={(_, info) => release(info.velocity.y)}
                onPointerDownCapture={onPointerDownCapture}
                style={{ y, opacity: fade, scale, top: largeTop, "--cover": cover, "--kb": kb } as never}
                data-testid={tid ?? `sheet-${id}`}
                data-detent={detentName}
                data-covered={covered ? "" : undefined}
                data-material={material}
              />
            )}
          >
            <GlassSurface ref={surface} tier={monolith ? "t5" : "t4"} radius={36} layer="overlays" lb={lb} className="g-sheet__glass" materialize={false}>
              <span className="g-sheet__solid" data-material={material} aria-hidden="true" />
              <div className="g-sheet__inner">
                <div className="g-sheet__grabber" onPointerDown={(e) => controls.start(e.nativeEvent)}>
                  <button
                    type="button"
                    className="g-sheet__grab"
                    aria-label="Sheet size"
                    data-cursor="grab"
                    onClick={() => { if (draggedFlag.current) { draggedFlag.current = false; return; } cycle(0); }}
                    onKeyDown={(e) => { if (e.key === "ArrowUp") { e.preventDefault(); cycle(1); } else if (e.key === "ArrowDown") { e.preventDefault(); cycle(-1); } }}
                  ><span className="g-sheet__pill" /></button>
                </div>
                <Header title={title} titleRef={titleRef} centerTitle={centerTitle} headerLeading={headerLeading} onClose={() => requestClose(0)} dragHandlers={{ onPointerDown: (e) => controls.start(e.nativeEvent) }} />
                <SheetCtx.Provider value={{ scroller }}>
                  <SheetBody scrollerRef={scroller} state={state} errorText={errorText} onRetry={onRetry} emptyCopy={emptyCopy} onFocusCapture={onFocusCapture} style={{ paddingBottom: kb }}>{children}</SheetBody>
                </SheetCtx.Provider>
              </div>
            </GlassSurface>
          </Dialog.Popup>
        </div>
      </Dialog.Portal>
    </Dialog.Root>
  );
}

/* ---------------------------------------------------------------- desktop: panel, window, detail window, popover */

function useMv(): MotionValue<number> { return useMotionValue(0); }

function DesktopSheet({ id, title, children, desktop = "panel", material = "glass", centerTitle, headerLeading, recedeTarget, state, errorText, onRetry, emptyCopy, triggerRef, onExited, "data-testid": tid }: SheetProps & { onExited: () => void }) {
  const { open, covered, close } = useSheetParam(id);
  const host = useGlassHost();
  const titleRef = useRef<HTMLHeadingElement | null>(null);
  const scroller = useRef<HTMLDivElement | null>(null);
  const layer = useRef<HTMLDivElement | null>(null);
  const finalFocus = useFinalFocus(id, triggerRef);
  const pres = useMv();
  const cover = useMv();
  const closing = useRef(false);
  const exited = useRef(false);
  const origin = useMemo(() => originOf(id, triggerRef), [id, triggerRef]);
  const reduced = isGlassReduced();
  const detail = desktop === "detailWindow";

  const writeRecede = useRecede(recedeTarget, detail, "glass-recede-window");
  useMotionValueEvent(pres, "change", (p) => {
    const el = layer.current;
    if (el) el.style.setProperty("--sheet-dim", detail ? "0" : clamp01(p).toFixed(4));
    writeRecede(clamp01(p));
  });
  useEffect(() => suppressLit(), []);

  useEffect(() => {
    pres.set(0);
    const c = desktop === "window" || desktop === "popover" ? play("bloom", pres, 1) : play("sheetPresent", pres, 1);
    return () => c.stop();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);
  useEffect(() => { const t = setTimeout(() => focusQuiet(titleRef.current), 30); return () => clearTimeout(t); }, []);
  useEffect(() => { play("stackFan", cover, covered ? 1 : 0); }, [covered, cover]);

  const dismiss = useCallback(() => {
    if (closing.current) return;
    closing.current = true;
    haptic("sheet.dismiss");
    const done = () => { if (!exited.current) { exited.current = true; onExited(); } };
    springTo(pres, 0, "dismiss", { onComplete: done });
  }, [onExited, pres]);
  useEffect(() => { if (!open) dismiss(); }, [open, dismiss]);

  const surfaceRef = useRef<HTMLElement | null>(null);
  const lb = useLb({ kind: "bar", ref: surfaceRef });
  const opacity = useTransform(pres, (p) => clamp01(reduced ? p : desktop === "panel" ? 1 : p * 1.8));
  const x = useTransform(pres, (p) => (reduced || desktop !== "panel" ? 0 : (1 - p) * (440 + 24)));
  const sc = useTransform(pres, (p) => (reduced || desktop === "panel" || detail ? 1 : 0.9 + 0.1 * p));
  const yy = useTransform(pres, (p) => (reduced || !detail ? 0 : (1 - p) * 24));
  const coverScale = useTransform(cover, (c) => 1 - 0.0835 * c);

  const style: MotionStyle & Record<string, unknown> = { x, y: yy, scale: sc, opacity };
  if (desktop === "window" || desktop === "popover") {
    style.transformOrigin = origin ? `${origin.x}px ${origin.y}px` : "50% 30%";
  }
  if (desktop === "popover" && origin) {
    style.top = Math.min(window.innerHeight - 24, origin.rect.bottom + 8);
    style.left = Math.max(12, Math.min(window.innerWidth - 420 - 12, origin.rect.right - 420));
  }
  const monolith = material === "monolith";

  if (!host) return null;
  const chrome = (
    <>
      {detail ? null : <Header title={title} titleRef={titleRef} centerTitle={centerTitle} headerLeading={headerLeading} onClose={() => close()} />}
      {detail ? (
        <div className="g-sheet__detailbar">
          <Dialog.Title ref={titleRef} tabIndex={-1} className="sr-only">{title}</Dialog.Title>
          <button type="button" className="g-sheet__close" aria-label="Close" onClick={() => close()}><span className="g-sheet__closeDisc"><Icon name="x" size={16} weight="regular" /></span></button>
        </div>
      ) : null}
      <SheetCtx.Provider value={{ scroller }}>
        <SheetBody scrollerRef={scroller} state={state} errorText={errorText} onRetry={onRetry} emptyCopy={emptyCopy}>{children}</SheetBody>
      </SheetCtx.Provider>
    </>
  );

  return (
    <Dialog.Root open modal onOpenChange={(o) => { if (!o) close(); }}>
      <Dialog.Portal container={host}>
        <div ref={layer} className="g-sheet-layer" data-desktop={desktop} data-covered={covered ? "" : undefined} style={{ "--sheet-dim": 0 } as CSSProperties}>
          <Dialog.Backdrop className="g-sheet__dim" render={<motion.div onClick={() => close()} />} />
          <Dialog.Popup
            className={`g-sheet-d g-sheet-d--${desktop}`}
            onKeyDown={trapTab}
            initialFocus={titleRef}
            finalFocus={finalFocus}
            render={(props) => <motion.div {...(props as object)} style={{ ...style, ...(covered ? { scale: coverScale as unknown as number } : {}) } as never} data-testid={tid ?? `sheet-${id}`} data-desktop={desktop} data-covered={covered ? "" : undefined} />}
          >
            {detail ? (
              <div className="g-sheet-d__slab" ref={(el) => { surfaceRef.current = el; }}>{chrome}</div>
            ) : (
              <GlassSurface ref={surfaceRef} tier={monolith && desktop === "window" ? "t5" : "t4"} radius={desktop === "panel" || desktop === "popover" ? 26 : 32} layer="overlays" lb={lb} className="g-sheet-d__glass" materialize={false}>
                <div className="g-sheet__inner">{chrome}</div>
              </GlassSurface>
            )}
          </Dialog.Popup>
        </div>
      </Dialog.Portal>
    </Dialog.Root>
  );
}
