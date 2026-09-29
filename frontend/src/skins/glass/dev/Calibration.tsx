"use client";

import { AnimatePresence, motion, useMotionValue } from "motion/react";
import { useCallback, useEffect, useRef, useState, type CSSProperties, type ReactNode } from "react";
import { AmbientField, AmbientProvider, useAmbient } from "../glass/AmbientField";
import { CausticWrap, FollowRing } from "../glass/Caustic";
import { GlassSurface, LensDefs, sweepGlass } from "../glass/GlassSurface";
import { useGlassCount } from "../glass/budget";
import { useGlassEnv } from "../glass/env";
import type { MapShape } from "../glass/liquid-map";
import { dimFor } from "../glass/material";
import { MOODS, coverPalette, type Mood } from "../glass/palette";
import { createRain } from "../glass/rain";
import { useLb, useLbItem } from "../glass/useLb";
import { useLightAngle } from "../glass/useLightAngle";
import { GlassMotionConfig, play } from "../motion";
import { GlassMotionTimings } from "../motion-timings";
import { createMagnet } from "../physics/magnet";
import { nearest, project } from "../physics/project";
import { rubberband } from "../physics/rubberband";
import { catchMotion, createTracker } from "../physics/tracker";
import { glass } from "../tokens.generated";

const CHECKER = "repeating-conic-gradient(#000 0 25%, #fff 0 50%) 0 0 / 32px 32px";
const COVERS = Array.from({ length: 24 }, (_, i) => `/dev-covers/cover-${String(i + 1).padStart(2, "0")}.svg`);

const css = `
.cal { position: relative; z-index: 2; min-height: 100vh; padding: 16px; color: var(--mm-color-label1); font: 15px/22px var(--mm-font-sans, system-ui); }
.cal h1 { font-size: 22px; line-height: 28px; margin: 0 0 8px; }
.cal button { min-height: 44px; min-width: 44px; padding: 0 14px; border-radius: 12px; border: 1px solid var(--mm-color-separator, rgba(255,255,255,.2)); background: var(--mm-color-fill3, #222); color: inherit; font: inherit; cursor: pointer; }
.cal button[aria-pressed="true"], .cal button[aria-selected="true"] { background: var(--mm-color-iris700, #5B4AD1); border-color: transparent; }
.cal button:focus-visible { outline: 2px solid var(--mm-color-iris300, #BCB0FF); outline-offset: 2px; }
.cal .row { display: flex; flex-wrap: wrap; gap: 8px; align-items: center; margin: 8px 0; }
.cal .cell { padding: 24px; background: ${CHECKER}; display: inline-block; max-width: 100%; }
.cal .cap { font-size: 12px; line-height: 16px; color: var(--mm-color-label2); margin-top: 6px; max-width: 460px; }
.cal .readout { font: 12px/16px var(--mm-font-mono, ui-monospace, monospace); color: var(--mm-color-label2); }
.cal .stage { position: relative; }
.cal .col { height: 520px; overflow: auto; width: min(360px, 100%); background: #000; }
.cal .col img { display: block; width: 100%; }
.cal .menu-row { padding: 10px 14px; }
`;

const root = () => document.documentElement;

function applyRenderer(r: string | undefined) {
  if (r === "solid") root().dataset.solid = "on";
  else if (r === "liquid" || r === "frosted") { delete root().dataset.solid; root().dataset.glassRenderer = r; }
}
const toggleAttr = (name: "contrast" | "motion", on: boolean, value: string) => {
  if (on) root().dataset[name] = value; else delete root().dataset[name];
};

const captionFor = (t: "t1" | "t2" | "t3" | "t4" | "t5") => {
  const g = glass[t];
  return `${t.toUpperCase()} · n = 1.5 · bezel ${g.bezel} px · max displacement ${g.displacement} px · thickness ${g.thickness}${g.dispersion ? ` · dispersion ${g.dispersion} px` : ""}`;
};

function Cell({ caption, children }: { caption: string; children: ReactNode }) {
  return (
    <div>
      <div className="cell">{children}</div>
      <div className="cap">{caption}</div>
    </div>
  );
}

const dockShapes: MapShape[] = [
  { x: 0, y: 0, w: 290, h: 64, r: 32, tier: "t3" },
  { x: 298, y: 7, w: 50, h: 50, r: 25, tier: "t3" },
];

function Checkerboard() {
  const [extra, setExtra] = useState(0);
  const [stack, setStack] = useState(false);
  const [wide, setWide] = useState(false);
  return (
    <section aria-label="Checkerboard">
      <h2>1 · Checkerboard</h2>
      <div className="row">
        <button type="button" onClick={() => setExtra((n) => n + 1)}>Add glass surface ({extra})</button>
        <button type="button" onClick={() => setStack((s) => !s)} aria-pressed={stack}>Stack test</button>
        <button type="button" onClick={() => setWide((w) => !w)} aria-pressed={wide}>Resize T4</button>
      </div>
      <div className="row" style={{ alignItems: "flex-start", gap: 24 }}>
        <Cell caption={captionFor("t2")}>
          <GlassSurface as="button" tier="t2" capsule data-testid="t2-button" aria-label="T2 pane, 44 px" style={{ width: 44, height: 44, border: 0, padding: 0, color: "var(--mm-color-label1)" }}>
            <span aria-hidden>●</span>
          </GlassSurface>
        </Cell>
        <Cell caption={`${captionFor("t3")} · one masked element, two shapes`}>
          <GlassSurface tier="t3" shapes={dockShapes} data-testid="t3-dock" style={{ width: 348, height: 64 }} />
        </Cell>
        <Cell caption={captionFor("t4")}>
          <GlassSurface tier="t4" radius={26} data-testid="t4-menu" style={{ width: wide ? 320 : 240, height: 220 }}>
            <div style={{ padding: 8 }}>
              {["Share", "Add to collection", "Mark as read", "Remove"].map((l) => <div key={l} className="menu-row">{l}</div>)}
            </div>
          </GlassSurface>
        </Cell>
        <Cell caption={captionFor("t5")}>
          <GlassSurface tier="t5" radius={40} data-testid="t5-swatch" style={{ width: "min(420px, 100%)", aspectRatio: "1 / 1" }} />
        </Cell>
      </div>
      {Array.from({ length: extra }, (_, i) => (
        <GlassSurface key={i} tier="t1" capsule style={{ position: "fixed", right: 16, bottom: 16 + i * 40, width: 120, height: 32 }} aria-label={`Extra glass ${i + 1}`} />
      ))}
      {stack && (
        <div data-testid="stack" style={{ position: "fixed", right: 16, top: 120, width: 200, height: 200 }}>
          <GlassSurface tier="t2" layer="controls" data-testid="stack-low" style={{ position: "absolute", left: 0, top: 0, width: 120, height: 120 }} />
          <GlassSurface tier="t2" layer="overlays" style={{ position: "absolute", left: 30, top: 30, width: 120, height: 120 }} />
          <GlassSurface tier="t2" layer="interruptions" style={{ position: "absolute", left: 60, top: 60, width: 120, height: 120 }} />
        </div>
      )}
    </section>
  );
}

function CoverTile({ src }: { src: string }) {
  const ref = useRef<HTMLImageElement>(null);
  const [lMax, setLMax] = useState(1);
  useEffect(() => {
    let live = true;
    coverPalette({ coverUrl: src }).then((p) => { if (live) setLMax(p.lMax); }, () => {});
    return () => { live = false; };
  }, [src]);
  useLbItem(ref, lMax);
  // eslint-disable-next-line @next/next/no-img-element
  return <img ref={ref} src={src} alt="" width={200} height={300} data-lmax={lMax.toFixed(2)} />;
}

function Legibility({ rain }: { rain: boolean }) {
  const wrap = useRef<HTMLDivElement>(null);
  const bar = useRef<HTMLDivElement>(null);
  const env = useGlassEnv();
  const lb = useLb({ kind: "bar", ref: bar });
  const dim = dimFor(lb, env.hc);
  useEffect(() => {
    const host = bar.current;
    if (!host) return;
    const m = /#([^")]+)/.exec(host.style.getPropertyValue("--glass-lens"));
    const filter = m ? (document.getElementById(m[1]) as unknown as SVGFilterElement | null) : null;
    const r = createRain(host, { renderer: env.renderer, filter });
    r.setActive(rain);
    return () => r.destroy();
  }, [rain, env.renderer]);
  return (
    <section aria-label="Legibility over art">
      <h2>3 · Legibility over art</h2>
      <div className="readout" data-testid="lb-readout">Lb {lb.toFixed(2)} · dim {dim.toFixed(2)}</div>
      <div ref={wrap} className="stage" style={{ width: "min(360px, 100%)" }}>
        <div className="col" data-testid="cover-column">
          {COVERS.map((c) => <CoverTile key={c} src={c} />)}
        </div>
        <GlassSurface ref={bar as never} tier="t3" shapes={dockShapes} lb={lb} data-testid="lb-bar" style={{ position: "absolute", left: 6, top: 12, width: 348, height: 64 }}>
          <GlassSurface as="span" data-testid="lb-label" style={{ position: "absolute", left: 20, top: 16, padding: "4px 12px", borderRadius: 999, color: "var(--mm-color-on-glass, #F2F2F7)" }}>
            Legibility label
          </GlassSurface>
        </GlassSurface>
      </div>
    </section>
  );
}

function Light() {
  const [pressed, setPressed] = useState<{ x: number; y: number; on: boolean }>({ x: 0, y: 0, on: false });
  const [origin, setOrigin] = useState<{ x: number; y: number } | null>(null);
  const sweepTarget = useRef<HTMLDivElement>(null);
  return (
    <section aria-label="Light">
      <h2>4 · Light</h2>
      <div className="stage" style={{ width: 360, maxWidth: "100%", height: 200, background: "url(/dev-covers/cover-06.svg) center / cover" }}>
        <div style={{ position: "absolute", left: 40, top: 60 }}>
          <CausticWrap pressed={pressed.on}>
            <GlassSurface
              as="button" tier="t2" finish="tinted" radius={25} pressedGlow={pressed} data-testid="tinted-button" aria-label="Lit action"
              onPointerDown={(e: React.PointerEvent<HTMLElement>) => {
                const r = e.currentTarget.getBoundingClientRect();
                setPressed({ x: e.clientX - r.left, y: e.clientY - r.top, on: true });
              }}
              onPointerUp={() => setPressed((p) => ({ ...p, on: false }))}
              onPointerLeave={() => setPressed((p) => ({ ...p, on: false }))}
              style={{ width: 180, height: 50, border: 0, color: "#fff", font: "inherit" }}
            >
              Add to library
            </GlassSurface>
          </CausticWrap>
        </div>
      </div>
      <div className="row">
        <button type="button" onClick={() => { const h = sweepTarget.current?.querySelector<HTMLElement>("[data-testid=tinted-button]") ?? document.querySelector<HTMLElement>("[data-testid=tinted-button]"); if (h) sweepGlass(h); }}>Sweep</button>
        <button type="button" onClick={() => setOrigin({ x: 60 + Math.random() * 120, y: 100 })}>Follow ring</button>
      </div>
      <div style={{ width: 360, maxWidth: "100%", height: 200, background: "#0b0b12" }} ref={sweepTarget}>
        <FollowRing origin={origin} />
      </div>
    </section>
  );
}

const PALETTES = [
  ["#E86A6A", "#F0A860", "#B85CD9"],
  ["#4FA8E8", "#5CD9C4", "#6A7AE8"],
  ["#D9C84F", "#8FD95C", "#E8843C"],
];
const MOOD_LIST = Object.keys(MOODS) as Mood[];

function Ambient() {
  const [i, setI] = useState(-1);
  const [m, setM] = useState<Mood>("default");
  useAmbient(i >= 0 ? { palette: { a: PALETTES[i % 3] }, mood: m } : { mood: m });
  return (
    <section aria-label="Ambient">
      <h2>5 · Ambient</h2>
      <div className="row">
        <button type="button" onClick={() => { setI((n) => n + 1); play("lightFollowsTheStory", 0, 1); }}>Next cover palette</button>
        {MOOD_LIST.map((k) => (
          <button key={k} type="button" aria-pressed={i < 0 && m === k} onClick={() => { setI(-1); setM(k); }}>{k}</button>
        ))}
      </div>
    </section>
  );
}

function PhysicsDemo() {
  const x = useMotionValue(0);
  const y = useMotionValue(0);
  const [tx] = useState(() => createTracker("x"));
  const [ty] = useState(() => createTracker("y"));
  const [magnet] = useState(() => createMagnet([0, 240, 480]));
  const [moving, setMoving] = useState(false);
  const [show, setShow] = useState(true);
  const [lb, setLb] = useState(1);
  const sweepRef = useRef<HTMLElement | null>(null);
  const W = 600, H = 300, S = 120, MAX_X = W - S, MAX_Y = H - S;
  const detents = [0, MAX_X / 2, MAX_X];
  const rb = (off: number, max: number, d: number) => (off < 0 ? -rubberband(-off, d) : off > max ? max + rubberband(off - max, d) : off);
  const finish = useCallback(() => setMoving(false), []);
  return (
    <section aria-label="Physics and motion">
      <h2>6 · Physics and motion</h2>
      <div style={{ width: `min(${W}px, 100%)`, height: H, position: "relative", background: "rgba(255,255,255,0.06)", overflow: "hidden", touchAction: "none" }} data-testid="track">
        <motion.div
          style={{ x, y, width: S, height: S, position: "absolute", left: 0, top: 0, touchAction: "none" }}
          onPointerDown={(e) => {
            e.currentTarget.setPointerCapture(e.pointerId);
            const cx = catchMotion(x), cy = catchMotion(y);
            tx.start(e.nativeEvent, cx.from);
            ty.start(e.nativeEvent, cy.from);
            setMoving(true);
          }}
          onPointerMove={(e) => {
            const ox = tx.move(e.nativeEvent), oy = ty.move(e.nativeEvent);
            if (ox !== null) { const m = magnet.step(rb(ox, MAX_X, W)); x.set(m.target === null ? rb(ox, MAX_X, W) : m.pos); }
            if (oy !== null) y.set(rb(oy, MAX_Y, H));
          }}
          onPointerUp={() => {
            const rx = tx.end(), ry = ty.end();
            const tX = nearest(detents, Math.max(0, Math.min(MAX_X, project(x.get(), rx.velocity))));
            const tY = Math.max(0, Math.min(MAX_Y, project(y.get(), ry.velocity)));
            play("rubberBand", x, tX, { velocity: rx.velocity, onComplete: finish });
            play("rubberBand", y, tY, { velocity: ry.velocity });
          }}
        >
          <GlassSurface tier="t3" radius={28} moving={moving} data-testid="tile" aria-label="Draggable glass tile" style={{ width: S, height: S }} />
        </motion.div>
      </div>
      <div className="row">
        <button type="button" onClick={() => setShow(true)}>Materialise</button>
        <button type="button" onClick={() => setShow(false)}>Dematerialise</button>
        <button type="button" onClick={() => { if (sweepRef.current) sweepGlass(sweepRef.current); }}>Specular sweep</button>
        <button type="button" onClick={() => { setLb((v) => (v > 0.5 ? 0.1 : 1)); play("dimShift", 0, 1); }}>Dim shift</button>
      </div>
      <div style={{ height: 80, position: "relative", background: CHECKER, width: 220 }}>
        <AnimatePresence>
          {show && <GlassSurface key="demo" ref={sweepRef} tier="t2" radius={20} lb={lb} data-testid="demo-surface" style={{ position: "absolute", inset: 12 }} />}
        </AnimatePresence>
      </div>
    </section>
  );
}

const SECTIONS = ["1", "3", "4", "5", "6"] as const;

function Controls({ tab, setTab, rain, setRain }: { tab: string; setTab: (t: string) => void; rain: boolean; setRain: (r: boolean) => void }) {
  const env = useGlassEnv();
  const count = useGlassCount();
  const [angle, setAngle] = useState("");
  useEffect(() => {
    const t = setInterval(() => setAngle(getComputedStyle(root()).getPropertyValue("--mm-light-angle").trim()), 200);
    return () => clearInterval(t);
  }, []);
  const mode = env.solid ? "solid" : env.renderer;
  return (
    <div role="group" aria-label="Calibration controls">
      <h1>Glass calibration</h1>
      <div className="row" role="group" aria-label="Renderer">
        {(["liquid", "frosted", "solid"] as const).map((r) => (
          <button key={r} type="button" aria-pressed={mode === r} onClick={() => applyRenderer(r)}>{r[0].toUpperCase() + r.slice(1)}</button>
        ))}
        <button type="button" aria-pressed={env.hc} onClick={() => toggleAttr("contrast", !env.hc, "more")}>Increase contrast</button>
        <button type="button" aria-pressed={env.reduced} onClick={() => toggleAttr("motion", !env.reduced, "reduced")}>Reduce motion</button>
        <button type="button" aria-pressed={rain} onClick={() => setRain(!rain)}>Rain</button>
      </div>
      <div className="readout" data-testid="readouts">
        <span data-testid="angle">light angle {angle}</span> · <span data-testid="count">Glass layers on screen: {count.glass} / 6 (+ {count.scrims} scrims)</span> · renderer {mode}
      </div>
      <div className="row" role="tablist" aria-label="Sections">
        {SECTIONS.map((s) => (
          <button key={s} role="tab" type="button" aria-selected={tab === s} onClick={() => setTab(s)}>{s}</button>
        ))}
      </div>
    </div>
  );
}

function Body({ renderer, section }: { renderer?: string; section?: string }) {
  const [tab, setTab] = useState(SECTIONS.includes(section as never) ? (section as string) : "1");
  const [rain, setRain] = useState(false);
  useLightAngle();
  useEffect(() => { applyRenderer(renderer); }, [renderer]);
  return (
    <main className="cal" style={{ ["--x" as string]: 0 } as CSSProperties}>
      <style>{css}</style>
      <Controls tab={tab} setTab={setTab} rain={rain} setRain={setRain} />
      {tab === "1" && <Checkerboard />}
      {tab === "3" && <Legibility rain={rain} />}
      {tab === "4" && <Light />}
      {tab === "5" && <Ambient />}
      {tab === "6" && <PhysicsDemo />}
    </main>
  );
}

/** The /dev/glass-calibration page body (renders without a signed-in session). */
export function Calibration({ renderer, section }: { renderer?: string; section?: string }) {
  return (
    <GlassMotionConfig>
      <AmbientProvider>
        <LensDefs />
        <AmbientField />
        <Body renderer={renderer} section={section} />
        <GlassMotionTimings />
      </AmbientProvider>
    </GlassMotionConfig>
  );
}
