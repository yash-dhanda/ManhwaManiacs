"use client";

import { usePresence, type MotionValue } from "motion/react";
import {
  createContext, useCallback, useContext, useEffect, useId, useLayoutEffect, useRef, useState,
  useSyncExternalStore, type CSSProperties, type ElementType, type ReactNode, type Ref,
} from "react";
import { createPortal } from "react-dom";
import { isGlassReduced, play } from "../motion";
import { MOTION_LABELS } from "../motion.generated";
import { beginRecord, trackFrames } from "../motion-recorder";
import { recomputeStacking, registerGlass, useBudgetScope, useForcedSolid, type GlassLayer } from "./budget";
import { useGlassEnv } from "./env";
import { liquidMap, maskHref, type LiquidMap, type MapShape } from "./liquid-map";
import { dimFor, gradFor, rondFor, tierAt, tierFor, TIERS, type Tier } from "./material";

export type GlassFinish = "regular" | "clear" | "tinted";
export type GlassTwin = "content" | "onGlass" | "dense" | "cover";

/** Descendants of a live surface render as the onGlass twin: no backdrop-filter is ever nested in another (2.4.1). */
export const GlassHostContext = createContext(false);

/* ---- the single hidden <svg><defs> every surface portals its <filter> into ---- */
let lensHost: SVGDefsElement | null = null;
const lensSubs = new Set<() => void>();
const lensSubscribe = (cb: () => void) => (lensSubs.add(cb), () => void lensSubs.delete(cb));
const setLensHost = (el: SVGDefsElement | null) => { lensHost = el; lensSubs.forEach((l) => l()); };

/** Mount once near the root of the Glass tree. Without it surfaces draw blur and saturation only. */
export function LensDefs() {
  return (
    <svg aria-hidden focusable="false" width={0} height={0} style={{ position: "absolute", width: 0, height: 0, pointerEvents: "none" }}>
      <defs ref={setLensHost} />
    </svg>
  );
}

/* ---- specular sweep (2.4.4): one on screen at a time, requests within 300 ms of the last start dropped ---- */
let lastSweep = -Infinity;
let sweeping = false;

export function sweepGlass(host: HTMLElement): void {
  const now = performance.now();
  if (sweeping || now - lastSweep < 300 || isGlassReduced()) return;
  const root = document.documentElement.dataset;
  if (root.solid === "on" || host.hasAttribute("data-forced-solid") || matchMedia("(prefers-reduced-transparency: reduce)").matches) return;
  const w = host.offsetWidth, h = host.offsetHeight;
  if (!w || !h) return;
  lastSweep = now;
  sweeping = true;
  const finishRecord = trackFrames(beginRecord("specularSweep", MOTION_LABELS.specularSweep, 520));
  const deg = parseFloat(getComputedStyle(document.documentElement).getPropertyValue("--mm-light-angle")) || 135;
  const a = (deg * Math.PI) / 180;
  const d = { x: Math.sin(a), y: -Math.cos(a) }; // gradient direction; 135deg runs down and right
  const half = (Math.abs(w * d.x) + Math.abs(h * d.y)) / 2 + 20;
  const layer = document.createElement("span");
  layer.className = "glass__sweep";
  layer.setAttribute("aria-hidden", "true");
  const band = document.createElement("i");
  const bh = Math.ceil(Math.hypot(w, h)) * 2;
  band.style.height = `${bh}px`;
  band.style.marginTop = `${-bh / 2}px`;
  layer.appendChild(band);
  host.appendChild(layer);
  const at = (t: number) => {
    const k = -half + t * 2 * half;
    return `translate(${w / 2 + d.x * k - 20}px, ${h / 2 + d.y * k - h / 2}px) rotate(${Math.atan2(d.y, d.x)}rad)`;
  };
  const anim = band.animate([{ transform: at(0) }, { transform: at(1) }], { duration: 520, easing: "cubic-bezier(0.2, 0, 0, 1)", fill: "both" });
  const done = () => { sweeping = false; layer.remove(); finishRecord(); };
  anim.onfinish = done;
  anim.oncancel = done;
}

const ric = (fn: () => void): (() => void) => {
  if (typeof requestIdleCallback === "function") {
    const id = requestIdleCallback(fn, { timeout: 200 });
    return () => cancelIdleCallback(id);
  }
  const id = setTimeout(fn, 0);
  return () => clearTimeout(id);
};

export interface GlassSurfaceProps {
  as?: ElementType;
  tier?: Tier | "auto";
  finish?: GlassFinish;
  twin?: GlassTwin;
  /** background luminance 0 to 1 under the surface; 1 (unknown) counts as white (2.1.7) */
  lb?: number;
  /** bar-group shapes in local px; the group is ONE live element with a masked backdrop and a multi-shape map */
  shapes?: MapShape[];
  /** growth: a continuous tier 1 to 5, interpolated every frame (2.4.2 rule 2) */
  tierValue?: MotionValue<number>;
  pressedGlow?: { x: number; y: number; on: boolean };
  overContent?: boolean;
  capsule?: boolean;
  radius?: number;
  layer?: GlassLayer;
  /** in flight: maps never rebuild while true */
  moving?: boolean;
  materialize?: boolean;
  /** cache-key variant for shape sets that differ only by design (the dock's tab positions) */
  mapVariant?: string;
  className?: string;
  style?: CSSProperties;
  children?: ReactNode;
  ref?: Ref<HTMLElement>;
  [prop: string]: unknown;
}

const setRef = <T,>(ref: Ref<T> | undefined, v: T | null) => {
  if (typeof ref === "function") ref(v);
  else if (ref) (ref as { current: T | null }).current = v;
};

export function GlassSurface({
  as: Tag = "div", tier = "t2", finish = "regular", twin, lb = 1, shapes, tierValue, pressedGlow, overContent = true,
  capsule, radius, layer = "controls", moving = false, materialize = true, mapVariant = "", className, style, children, ref, ...rest
}: GlassSurfaceProps) {
  const env = useGlassEnv();
  const parentLive = useContext(GlassHostContext);
  const id = useId().replace(/[^a-zA-Z0-9]/g, "");
  const hostRef = useRef<HTMLElement | null>(null);
  const filterRef = useRef<SVGFilterElement | null>(null);
  const lens = useSyncExternalStore(lensSubscribe, () => lensHost, () => null);
  const [size, setSize] = useState({ w: 0, h: 0 });
  const [map, setMap] = useState<LiquidMap | null>(null);
  const [isPresent, safeToRemove] = usePresence();
  const forcedSolid = useForcedSolid(id);
  const scope = useBudgetScope();

  const twinEff: GlassTwin | undefined = twin ?? (parentLive ? "onGlass" : undefined);
  const [entering, setEntering] = useState(materialize && !twinEff);
  const live = !twinEff && !env.solid;
  const wantLens = live && env.renderer === "liquid" && !forcedSolid && !!lens;

  const tierBase: Tier = tierValue ? TIERS[Math.min(4, Math.max(0, Math.floor(tierValue.get()) - 1))] : tier === "auto" ? (size.w ? tierFor(Math.min(size.w, size.h)) : "t2") : tier;
  const r = capsule ? Math.min(size.w, size.h) / 2 : Math.min(radius ?? 20, Math.min(size.w, size.h) / 2 || 1e4);
  const shapeKey = shapes ? JSON.stringify(shapes) : "";

  // ---- size: measured now, then debounced 100 ms after the last resize, and never while moving ----
  const movingRef = useRef(moving);
  useEffect(() => { movingRef.current = moving; }, [moving]);
  const readSize = useCallback(() => {
    const el = hostRef.current;
    if (el) setSize((s) => (s.w === el.offsetWidth && s.h === el.offsetHeight ? s : { w: el.offsetWidth, h: el.offsetHeight }));
  }, []);
  useLayoutEffect(readSize, [readSize]);
  useEffect(() => {
    const el = hostRef.current;
    if (!el) return;
    let t: ReturnType<typeof setTimeout>;
    const ro = new ResizeObserver(() => {
      clearTimeout(t);
      t = setTimeout(() => { if (!movingRef.current) readSize(); }, 100);
    });
    ro.observe(el);
    return () => { clearTimeout(t); ro.disconnect(); };
  }, [readSize]);
  useEffect(() => {
    if (moving) return;
    const t = setTimeout(readSize, 100);
    return () => clearTimeout(t);
  }, [moving, readSize]);

  // ---- displacement map: built at rest, in idle time ----
  const builds = useRef(0);
  useEffect(() => {
    if (!wantLens || !size.w || !size.h) return;
    return ric(() => {
      const shp: MapShape[] = shapes ?? [{ x: 0, y: 0, w: size.w, h: size.h, r, tier: tierBase }];
      setMap(liquidMap(shp, size.w, size.h, mapVariant));
      builds.current++;
      hostRef.current?.setAttribute("data-map-builds", String(builds.current));
    });
    // shapes are compared by value through shapeKey
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [wantLens, size.w, size.h, tierBase, r, shapeKey, mapVariant]);

  // ---- filter scale: materialise ramp x growth ----
  const k = useRef(materialize && !twinEff ? 0 : 1);
  const growthScale = useRef<number | null>(null);
  const apply = useCallback(() => {
    const f = filterRef.current;
    if (!f || !map) return;
    const base = growthScale.current ?? map.scale;
    const mults = map.dispersion ?? [1];
    // only the lens passes (rain adds its own displacement pass after them)
    Array.from(f.querySelectorAll("feDisplacementMap")).slice(0, mults.length).forEach((n, i) => n.setAttribute("scale", String(base * k.current * mults[i])));
  }, [map]);
  useLayoutEffect(apply, [apply]);

  // ---- growth (2.4.2 rule 2): every frame from lerpTier; the lower tier's map stays, its scale interpolates ----
  useEffect(() => {
    const el = hostRef.current;
    if (!tierValue || !el) return;
    const write = (v: number) => {
      const p = tierAt(v);
      const s = el.style;
      s.setProperty("--g-blur", `${p.blur}px`);
      s.setProperty("--g-fill", `rgb(${p.fillR} ${p.fillG} ${p.fillB} / ${p.fillA})`);
      s.setProperty("--g-spec-t", String(p.specular));
      s.setProperty("--glass-shadow", `0 ${p.shadowY}px ${p.shadowBlur}px rgb(0 0 0 / ${p.shadowA})`);
      s.setProperty("--glass-rond-t", String(p.rond));
      growthScale.current = 2 * p.displacement;
      apply();
    };
    write(tierValue.get());
    return tierValue.on("change", write);
  }, [tierValue, apply]);

  // ---- materialise on mount, dematerialise on exit (callers wrap in AnimatePresence) ----
  useEffect(() => {
    const el = hostRef.current;
    if (!materialize || twinEff || !el) { k.current = 1; apply(); return; }
    let c: { stop: () => void } | undefined;
    if (env.reduced || !wantLens) { k.current = 1; apply(); }
    else c = play("materialise", 0, 1, { onUpdate: (v: number) => { k.current = v; apply(); } });
    sweepGlass(el);
    const t = setTimeout(() => setEntering(false), 420);
    return () => { clearTimeout(t); c?.stop(); };
    // mount only: later env changes must not replay the entrance
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);
  useEffect(() => {
    if (isPresent || !safeToRemove) return;
    if (env.reduced || !wantLens) { const t = setTimeout(safeToRemove, env.reduced ? 120 : 350); return () => clearTimeout(t); }
    const c = play("dematerialise", 1, 0, { onUpdate: (v: number) => { k.current = v; apply(); }, onComplete: safeToRemove });
    return () => c.stop();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isPresent]);

  // ---- budget ----
  const label = typeof rest["aria-label"] === "string" ? (rest["aria-label"] as string) : `${Tag as string}.${className ?? tierBase}`;
  useEffect(() => {
    if (!live) return;
    const off = registerGlass({ id, kind: "glass", layer, label, el: hostRef.current, exempt: scope.exempt });
    window.addEventListener("resize", recomputeStacking);
    return () => { off(); window.removeEventListener("resize", recomputeStacking); };
  }, [live, id, layer, label, scope.exempt]);

  const setHost = useCallback((el: HTMLElement | null) => { hostRef.current = el; setRef(ref, el); }, [ref]);
  const glow = pressedGlow;
  const css = {
    "--glass-dim": dimFor(lb, env.hc),
    "--glass-grad-t": gradFor(lb),
    "--glass-rond-t": rondFor(tierBase),
    "--glass-grad": "var(--glass-grad-t)",
    "--glass-rond": "var(--glass-rond-t)",
    ...(capsule || radius === undefined ? {} : { "--glass-radius": `${radius}px` }),
    ...(wantLens && map ? { "--glass-lens": `url(#lens-${id})` } : {}),
    ...(shapes && size.w ? { "--glass-mask": maskHref(shapes, size.w, size.h) } : {}),
    ...(glow ? { "--glow-x": `${glow.x}px`, "--glow-y": `${glow.y}px` } : {}),
    ...style,
  } as CSSProperties;

  const dispersion = map?.dispersion;
  const filter =
    lens && wantLens && map
      ? createPortal(
          <filter ref={filterRef} id={`lens-${id}`} x={0} y={0} width={size.w} height={size.h} filterUnits="userSpaceOnUse" colorInterpolationFilters="sRGB">
            <feImage href={map.href} x={0} y={0} width={size.w} height={size.h} preserveAspectRatio="none" result="map" />
            {dispersion ? (
              <>
                <feDisplacementMap in="SourceGraphic" in2="map" xChannelSelector="R" yChannelSelector="G" result="dr" />
                <feColorMatrix in="dr" type="matrix" values="1 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 1 0" result="r" />
                <feDisplacementMap in="SourceGraphic" in2="map" xChannelSelector="R" yChannelSelector="G" result="dg" />
                <feColorMatrix in="dg" type="matrix" values="0 0 0 0 0  0 1 0 0 0  0 0 0 0 0  0 0 0 1 0" result="g" />
                <feDisplacementMap in="SourceGraphic" in2="map" xChannelSelector="R" yChannelSelector="G" result="db" />
                <feColorMatrix in="db" type="matrix" values="0 0 0 0 0  0 0 0 0 0  0 0 1 0 0  0 0 0 1 0" result="b" />
                <feBlend in="r" in2="g" mode="screen" result="rg" />
                <feBlend in="rg" in2="b" mode="screen" />
              </>
            ) : (
              <feDisplacementMap in="SourceGraphic" in2="map" xChannelSelector="R" yChannelSelector="G" />
            )}
          </filter>,
          lens,
        )
      : null;

  return (
    <GlassHostContext.Provider value={!twinEff}>
      <Tag
        {...rest}
        ref={setHost}
        className={`glass${className ? ` ${className}` : ""}`}
        style={css}
        data-tier={tierBase}
        data-finish={finish}
        data-twin={twinEff}
        data-capsule={capsule ? "" : undefined}
        data-forced-solid={forcedSolid ? "" : undefined}
        data-materialize={!isPresent ? "out" : entering ? "in" : undefined}
        data-glow={glow?.on ? "on" : undefined}
        data-pressed={glow?.on ? "on" : undefined}
        data-over-content={overContent ? undefined : "false"}
      >
        <span className="glass__bg" aria-hidden="true" />
        <span className="glass__rim" aria-hidden="true" />
        <span className="glass__glow" aria-hidden="true" />
        {children}
        {filter}
      </Tag>
    </GlassHostContext.Provider>
  );
}
