"use client";

import { motionValue } from "motion/react";
import { useEffect, useMemo, useRef, useState, type CSSProperties, type KeyboardEvent, type PointerEvent } from "react";
import { GlassSurface } from "../glass/GlassSurface";
import { useLbItem } from "../glass/useLb";
import { haptic } from "../haptics";
import { isGlassReduced, play, useGlassReduced } from "../motion";
import { createTracker } from "../physics/tracker";
import { Badge, badgeLabel, type StatusKey } from "./Badge";
import { Cover } from "./Cover";
import { Icon } from "./Icon";
import { Skeleton } from "./Skeleton";
import { decideThrow, isTap, liftScale, LIFT, magnetTarget, throwIntensity, type ThrowTarget } from "./poster-throw";
import { usePress, type PressState } from "./usePress";

export interface PosterProps {
  title: string;
  src?: string;
  /** the cover's peak luminance (palette.lMax); bars above it thicken over pale covers */
  lMax?: number;
  /** width in px: phone 124, tablet 148, desktop 168, wide 184 (grids size by columns) */
  width?: number;
  status?: StatusKey;
  newCount?: number;
  downloaded?: boolean;
  mature?: boolean;
  gateLocked?: boolean;
  favourite?: boolean;
  following?: boolean;
  /** 0..1: a 3 px `iris500` bar inside a 5 px track along the bottom */
  progress?: number;
  selectMode?: boolean;
  selected?: boolean;
  loading?: boolean;
  /** the cover failed to load */
  error?: boolean;
  disabled?: boolean;
  disabledReason?: string;
  onOpen?: () => void;
  /** 450 ms of press, `.` or Shift+F10: the web/27 context menu attaches here */
  onContextPreview?: () => void;
  onThrowOpen?: (velocity: { x: number; y: number }) => void;
  onThrowAway?: () => void;
  allowAway?: boolean;
  targets?: readonly ThrowTarget[];
  onDropOnTarget?: (id: string) => void;
  onMagnet?: (id: string | null) => void;
  onFavourite?: () => void;
  onFollow?: () => void;
  /** the peek capsule text after 600 ms of rest: "Continue Ch 12" or "Open" */
  peek?: string;
  onMore?: () => void;
  forceState?: PressState | "peek";
  href?: string;
  "data-testid"?: string;
}

const PEEK_DELAY = 600;

export function Poster(props: PosterProps) {
  const { title, src, lMax = 0.5, width, status, newCount, downloaded, mature, gateLocked, favourite, following, progress, selectMode, selected, loading, error, disabled, disabledReason, onOpen, onContextPreview, onThrowOpen, onThrowAway, allowAway, targets, onDropOnTarget, onMagnet, onFavourite, onFollow, peek, onMore, forceState, "data-testid": tid } = props;
  const reduced = useGlassReduced();
  const host = useRef<HTMLDivElement>(null);
  useLbItem(host, lMax);
  const [loaded, setLoaded] = useState(false);
  const [peekOpen, setPeekOpen] = useState(false);
  const [lifted, setLifted] = useState(false);
  const peekT = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const dismissed = useRef(false);
  const lastType = useRef("mouse");
  const tx = useMemo(() => motionValue(0), []);
  const ty = useMemo(() => motionValue(0), []);
  const t = useRef({ active: false, t0: 0, x0: 0, y0: 0, slop: false, menu: false, raf: 0, id: -1, magnet: null as string | null, tracker: null as ReturnType<typeof createTracker> | null, trackerY: null as ReturnType<typeof createTracker> | null });

  const p = usePress<HTMLButtonElement>({ material: "content", sink: 0.97, disabled: disabled || loading, selected, error, forceState: forceState === "peek" ? undefined : forceState, haptic: "tap.primary", onPress: () => onOpen?.() });
  const label = [title, newCount ? badgeLabel({ kind: "new", count: newCount }) : null, downloaded ? "downloaded" : null, status ? badgeLabel({ kind: "status", status }) : null, mature ? "18+" : null, favourite ? "favourite" : null, selectMode ? (selected ? "selected" : "not selected") : null].filter(Boolean).join(", ");

  useEffect(() => {
    const write = () => { const el = host.current; if (el) el.style.translate = `${tx.get()}px ${ty.get()}px`; };
    const a = tx.on("change", write), b = ty.on("change", write);
    return () => { a(); b(); };
  }, [tx, ty]);
  useEffect(() => () => { cancelAnimationFrame(t.current.raf); clearTimeout(peekT.current); }, []);
  useEffect(() => {
    if (!peekOpen) return;
    const onKey = (e: globalThis.KeyboardEvent) => { if (e.key === "Escape") { dismissed.current = true; setPeekOpen(false); } };
    document.addEventListener("keydown", onKey);
    return () => document.removeEventListener("keydown", onKey);
  }, [peekOpen]);

  const isTouch = (e: PointerEvent) => e.pointerType === "touch" || e.pointerType === "pen";
  const frame = useRef<() => void>(() => {});
  useEffect(() => {
    frame.current = () => {
    const s = t.current;
    if (!s.active) return;
    const el = host.current;
    const elapsed = performance.now() - s.t0;
    if (el && !s.slop && !reduced) {
      const sc = liftScale(elapsed);
      el.style.scale = String(sc);
      el.style.setProperty("--lift", String((sc - 1) / (LIFT.peak - 1)));
    }
    if (elapsed >= LIFT.start && !lifted) { setLifted(true); haptic("press.lift"); }
    if (elapsed >= LIFT.menu && !s.menu && !s.slop) { s.menu = true; haptic("longpress.open"); onContextPreview?.(); }
    s.raf = requestAnimationFrame(frame.current);
    };
  });
  const onTouchDown = (e: PointerEvent<HTMLButtonElement>) => {
    const s = t.current;
    s.active = true; s.slop = false; s.menu = false; s.t0 = performance.now(); s.x0 = e.clientX; s.y0 = e.clientY; s.id = e.pointerId; s.magnet = null;
    tx.stop(); ty.stop();
    s.tracker = createTracker("x"); s.trackerY = createTracker("y");
    s.tracker.start(e, tx.get()); s.trackerY.start(e, ty.get());
    s.raf = requestAnimationFrame(frame.current);
  };
  const reset = (drop: boolean) => {
    const el = host.current;
    cancelAnimationFrame(t.current.raf);
    setLifted(false);
    if (el) { el.style.removeProperty("--lift"); if (drop) { play("zoom", tx, 0); play("zoom", ty, 0); } }
    if (el) el.style.scale = "";
  };
  const onTouchMove = (e: PointerEvent<HTMLButtonElement>) => {
    const s = t.current;
    if (!s.active || e.pointerId !== s.id) return;
    const ox = s.tracker?.move(e) ?? null, oy = s.trackerY?.move(e) ?? null;
    if (ox === null && oy === null) return;
    if (!s.slop) {
      // moving before the lift begins is a scroll, not a lift; once lifted the poster follows the finger 1:1
      if (performance.now() - s.t0 < LIFT.start) { s.active = false; cancelAnimationFrame(s.raf); reset(false); return; }
      s.slop = true;
      e.currentTarget.setPointerCapture(e.pointerId);
    }
    tx.set(ox ?? tx.get()); ty.set(oy ?? ty.get());
    if (targets?.length && host.current) {
      const r = host.current.getBoundingClientRect();
      const m = magnetTarget({ x: r.left + r.width / 2, y: r.top + r.height / 2 }, targets);
      if (m !== s.magnet) { haptic(m ? "magnet.capture" : "magnet.drop"); s.magnet = m; onMagnet?.(m); }
    }
  };
  const onTouchUp = (e: PointerEvent<HTMLButtonElement>) => {
    const s = t.current;
    if (!s.active || e.pointerId !== s.id) return;
    s.active = false;
    const elapsed = performance.now() - s.t0;
    if (isTap(elapsed, s.slop)) { reset(false); haptic("tap.primary"); onOpen?.(); return; }
    if (!s.slop) { reset(false); return; } // held to the menu without dragging: the menu owns it now
    const vx = s.tracker?.end().velocity ?? 0, vy = s.trackerY?.end().velocity ?? 0;
    const r = host.current!.getBoundingClientRect();
    const d = decideThrow({ centre: { x: r.left + r.width / 2, y: r.top + r.height / 2 }, velocity: { x: vx, y: vy }, viewport: { w: innerWidth, h: innerHeight }, targets, allowAway });
    if (s.magnet) { s.magnet = null; onMagnet?.(null); }
    if (d.kind === "drop") { reset(true); return; }
    haptic("throw.commit");
    void throwIntensity;
    const to = d.kind === "open" ? { x: tx.get() + vx * 0.3, y: -innerHeight } : d.kind === "away" ? { x: d.side === "left" ? -innerWidth : innerWidth, y: ty.get() } : { x: tx.get(), y: ty.get() };
    const done = () => { reset(true); if (d.kind === "open") onThrowOpen?.(d.velocity); else if (d.kind === "away") onThrowAway?.(); else if (d.kind === "target") { haptic("magnet.drop"); onDropOnTarget?.(d.id); } };
    if (d.kind === "target" || isGlassReduced()) { done(); return; }
    play("throw", tx, to.x, { velocity: vx }); play("throw", ty, to.y, { velocity: vy, onComplete: done });
  };

  // hover: tilt up to 6 deg, specular follows, lift -2 px; a peek after 600 ms of rest
  const onMouseMove = (e: PointerEvent<HTMLButtonElement>) => {
    if (e.pointerType !== "mouse" || disabled) return;
    const el = host.current;
    if (!el) return;
    const r = el.getBoundingClientRect();
    const fx = (e.clientX - r.left) / r.width, fy = (e.clientY - r.top) / r.height;
    if (!reduced) { el.style.setProperty("--ry", `${((fx - 0.5) * 12).toFixed(2)}deg`); el.style.setProperty("--rx", `${((0.5 - fy) * 12).toFixed(2)}deg`); }
    el.style.setProperty("--sx", `${fx * 100}%`); el.style.setProperty("--sy", `${fy * 100}%`);
    if (peek && !dismissed.current && !peekOpen) { clearTimeout(peekT.current); peekT.current = setTimeout(() => setPeekOpen(true), PEEK_DELAY); }
  };
  const onLeave = () => { clearTimeout(peekT.current); dismissed.current = false; setPeekOpen(false); const el = host.current; if (el) { el.style.setProperty("--rx", "0deg"); el.style.setProperty("--ry", "0deg"); } };
  const onKey = (e: KeyboardEvent<HTMLButtonElement>) => {
    if (e.key === "." || (e.shiftKey && e.key === "F10")) { e.preventDefault(); onContextPreview?.(); }
  };

  const showPeek = (peek && peekOpen) || forceState === "peek";
  const w = width ? { width } : undefined;
  if (loading) return <div className="g-poster" style={w} data-state="loading" data-testid={tid}><Skeleton shape="poster" /></div>;
  return (
    <div ref={host} className="g-poster" style={w as CSSProperties} data-selected-mode={selectMode ? "" : undefined} data-selected={selected ? "" : undefined} data-lifted={lifted ? "" : undefined} data-disabled={disabled ? "" : undefined} data-cursor={lifted ? "grab" : undefined} data-dragging={lifted ? "" : undefined} data-mature={mature ? "" : undefined} data-testid={tid} onPointerLeave={onLeave}>
      <button
        {...p.props} type="button" className="g-poster__main" aria-label={label} aria-disabled={disabled ? true : undefined}
        onPointerDown={(e) => { lastType.current = e.pointerType; if (isTouch(e)) { if (!disabled) onTouchDown(e); } else p.props.onPointerDown(e); }}
        onPointerMove={(e) => { if (isTouch(e)) onTouchMove(e); else { p.props.onPointerMove(e); onMouseMove(e); } }}
        onPointerUp={(e) => { if (isTouch(e)) onTouchUp(e); else p.props.onPointerUp(e); }}
        onPointerCancel={(e) => { if (isTouch(e)) { t.current.active = false; reset(true); } else p.props.onPointerCancel(); }}
        onContextMenu={(e) => { if (lastType.current !== "mouse") e.preventDefault(); }}
        onKeyDown={onKey}
      >
        <span className="g-poster__media" data-loaded={loaded ? "" : undefined} data-error={error ? "" : undefined}>
          {error ? <Icon name="image-broken" size={24} color="var(--mm-color-g600)" /> : src ? <Cover src={src} onLoad={() => setLoaded(true)} onError={() => setLoaded(true)} /> : null}
        </span>
        <span className="g-poster__spec" aria-hidden="true" />
        {progress !== undefined ? <span className="g-poster__progress" aria-hidden="true"><i style={{ width: `${Math.min(1, Math.max(0, progress)) * 100}%` }} /></span> : null}
        <span className="g-poster__ov g-poster__tl" aria-hidden="true">{status ? <Badge kind="status" status={status} onCover /> : null}{mature && !gateLocked ? <Badge kind="mature" onCover /> : null}</span>
        <span className="g-poster__ov g-poster__tr" aria-hidden="true">{newCount ? <Badge kind="new" count={newCount} /> : null}</span>
        <span className="g-poster__ov g-poster__bl" aria-hidden="true">{downloaded ? <Badge kind="downloaded" onCover /> : null}{gateLocked ? <span className="g-poster__disc"><Icon name="age-gate" size={14} color="var(--mm-color-mature)" /></span> : null}{favourite ? <span className="g-poster__disc"><Icon name="star" size={14} weight="fill" color="var(--mm-color-streak-core)" /></span> : null}</span>
        {mature && !gateLocked ? <span className="g-poster__ov g-poster__br" aria-hidden="true"><Badge kind="mature" onCover /></span> : null}
        {selectMode ? <span className="g-poster__check" aria-hidden="true" data-on={selected ? "" : undefined}>{selected ? <Icon name="check" size={16} weight="fill" /> : null}</span> : null}
      </button>
      {!selectMode && !disabled ? (
        <>
          <button type="button" className="g-poster__act g-poster__act--tl" aria-label="Favourite" aria-pressed={!!favourite} onClick={onFavourite}><span className="g-poster__disc32"><Icon name="star" size={16} weight={favourite ? "fill" : "regular"} color={favourite ? "var(--mm-color-streak-core)" : undefined} /></span></button>
          <button type="button" className="g-poster__act g-poster__act--tr" aria-label="Follow" aria-pressed={!!following} onClick={onFollow}><span className="g-poster__disc32"><Icon name="bell-ringing" size={16} weight={following ? "fill" : "regular"} color={following ? "var(--mm-color-iris400)" : undefined} /></span></button>
        </>
      ) : null}
      {showPeek ? (
        <GlassSurface as="div" twin="content" tier="t2" capsule finish="regular" className="g-poster__peek" role="group" aria-label={`${title} quick actions`}>
          <button type="button" className="g-poster__peekbtn" onClick={onOpen}><span className="g-label type-footnote">{peek ?? "Open"}</span></button>
          <button type="button" className="g-poster__peekmore" aria-label={`More for ${title}`} onClick={onMore}><Icon name="dots-three" size={20} /></button>
        </GlassSurface>
      ) : null}
      {disabled && disabledReason ? <p className="g-poster__reason type-caption1">{disabledReason}</p> : null}
    </div>
  );
}
