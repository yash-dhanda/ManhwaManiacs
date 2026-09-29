"use client";
import { animate, cubicBezier } from "motion/react";
import { useEffect, useLayoutEffect, useRef, useState } from "react";
import { splashKey } from "@/features/skin/skin-storage";
import { logSkinRestart, startMove } from "@/lib/motion-timings";
import { Monogram } from "./brand/Monogram";
import { haptic } from "./haptics";
import { readReduced } from "./motion";
import { LeaderDial } from "./primitives/Progress";
import { OxfordRule } from "./primitives/OxfordRule";
import { SetHeading } from "./primitives/SetHeading";
import { playSound } from "./sounds";
import { useShellState } from "./shell/shell-state";
import { HANDOFF_MS, IMPRESSION_MS, REVEAL_END, showConnecting, stepFor } from "./shell/splash-timeline";
import { durMs, ease } from "./tokens.generated";

const settle = cubicBezier(...ease.settle);
const lift = cubicBezier(...ease.lift);
const prog = (t: number, s: { startMs: number; endMs: number }, e: (n: number) => number = settle) => e(Math.min(1, Math.max(0, (t - s.startMs) / (s.endMs - s.startMs))));

/** Pure: the look of the splash at time t (ms). Used by the live splash and by the gallery's frozen frames. */
export function splashLook(t: number) {
  const inter = prog(t, stepFor("intersection"));
  const out = prog(t, stepFor("monogramOut"), lift);
  const imp = t < REVEAL_END ? 0 : Math.sin(Math.min(1, (t - REVEAL_END) / IMPRESSION_MS) * Math.PI);
  return {
    intersection: inter, bloom: 0.35 * inter, monogramOpacity: 1 - out, monogramScale: 1 - 0.04 * out,
    ruleOn: t >= stepFor("rule").startMs, lettersOn: t >= stepFor("letters").startMs, impressionPx: imp,
  };
}
const mix = (a: number, spot: string) => (a <= 0 ? "#000000" : `color-mix(in srgb, ${spot} ${Math.round(a * 100)}%, #000000)`);

/** Frozen letter opacity for the gallery (real splash uses SetHeading). */
function FrozenLine({ text, italic, offset, t }: { text: string; italic: boolean; offset: number; t: number }) {
  return (
    <span aria-hidden className="type-masthead block whitespace-nowrap" style={{ fontFamily: "var(--mm-font-display)", fontStyle: italic ? "italic" : "normal", fontVariationSettings: '"opsz" 96, "wght" 800', letterSpacing: "-0.035em", lineHeight: 0.86 }}>
      {[...text].map((c, i) => { const s = stepFor("letters").startMs + (offset + i) * 24; const p = prog(t, { startMs: s, endMs: s + durMs.letter }); return <span key={i} style={{ opacity: p, filter: `blur(${8 * (1 - Math.min(1, p * 640 / 440))}px)`, display: "inline-block", transform: `translateY(${0.42 * (1 - p)}em)` }}>{c}</span>; })}
    </span>
  );
}

/** The splash layer at time t. `frozen` renders static letters (gallery); live mode mounts SetHeading. */
export function SplashView({ t, frozen = false, connecting = false, lockupRef, layerRef, ready = true }: { t: number; frozen?: boolean; connecting?: boolean; lockupRef?: React.Ref<HTMLDivElement>; layerRef?: React.Ref<HTMLDivElement>; ready?: boolean }) {
  const l = splashLook(t);
  void ready;
  return (
    <div ref={layerRef} data-splash aria-hidden={undefined} style={{ position: "fixed", inset: 0, zIndex: "var(--mm-z-shutter)", background: "#000000" }} className="grid place-items-center">
      <span role="status" className="sr-only">Loading ManhwaManiacs</span>
      <div aria-hidden style={{ gridArea: "1 / 1", opacity: l.monogramOpacity, transform: `scale(${l.monogramScale})` }} data-splash-monogram>
        <Monogram className="w-28 frame:w-40 h-auto" size={160} intersection={mix(l.intersection, "var(--mm-color-spot)")} bloom={l.bloom} />
      </div>
      <div aria-hidden ref={lockupRef} style={{ gridArea: "1 / 1", transform: `translateY(${l.impressionPx}px)` }} data-splash-lockup className="flex flex-col items-start text-ink-100">
        {l.lettersOn || frozen ? (frozen ? <><FrozenLine text="Manhwa" italic={false} offset={0} t={t} /><FrozenLine text="Maniacs" italic offset={6} t={t} /></> : (
          <>
            <SetHeading as="p" trigger="signal" play startDelay={0} text="Manhwa" id="splash-a" className="type-masthead" />
            <span style={{ fontStyle: "italic", display: "block" }}><SetHeading as="p" trigger="signal" play startDelay={144} text="Maniacs" id="splash-b" className="type-masthead italic" /></span>
          </>)) : <span className="type-masthead invisible block" style={{ lineHeight: 0.86 }}>Manhwa<br />Maniacs</span>}
        <div className="mt-3 w-full">{l.ruleOn ? <OxfordRule spotLead /> : <span className="block h-[5px]" />}</div>
        {connecting ? <div className="mt-3 flex items-center gap-2"><LeaderDial size={24} immediate /><span className="type-kicker text-ink-60">CONNECTING</span></div> : null}
      </div>
    </div>
  );
}

/**
 * The Press start splash (§8.2, §12.4). Server-rendered first frame is the black layer with the monogram; from hydration one
 * `performance.now()` origin drives the timeline. The choreography always runs 0-1180 ms; the hand-off starts at
 * max(probeDone, 1180). Tap, Enter, Space or Esc skip to the hand-off (or to the hold while the probe is pending).
 */
export function Splash({ probeSettled }: { probeSettled: boolean }) {
  const [t, setT] = useState(0);
  const [mode, setMode] = useState<"full" | "warm" | "reduced">("full");
  const [done, setDone] = useState(false);
  const [connecting, setConnecting] = useState(false);
  const origin = useRef(0);
  const probeAt = useRef<number | null>(null);
  const handed = useRef(false);
  const layer = useRef<HTMLDivElement | null>(null);
  const lockup = useRef<HTMLDivElement | null>(null);
  const setHandoff = useShellState((s) => s.setHandoff);

  const [ready, setReady] = useState(false);
  useEffect(() => { if (ready && probeSettled && probeAt.current === null) probeAt.current = performance.now() - origin.current; }, [ready, probeSettled]);

  useLayoutEffect(() => {
    let warm = false;
    try { warm = sessionStorage.getItem(splashKey("cinematic")) !== null; } catch { /* storage blocked */ }
    // eslint-disable-next-line react-hooks/set-state-in-effect -- storage and media reads need the client
    setMode(readReduced() ? "reduced" : warm ? "warm" : "full");
    origin.current = performance.now();
    logSkinRestart("cinematic");
    setReady(true);
  }, []);

  // The choreography and the hand-off.
  useEffect(() => {
    if (done || !ready) return;
    const rec = startMove("press start", mode === "full" ? REVEAL_END + HANDOFF_MS : durMs.clip * 2);
    if (mode === "full") { playSound("splash.reveal"); }
    let raf = 0, impressed = false;
    const finish = () => {
      if (handed.current) return;
      handed.current = true;
      setHandoff(true);
      const el = layer.current, lk = lockup.current;
      const end = () => { rec.end(); if (mode === "full") { try { sessionStorage.setItem(splashKey("cinematic"), "1"); } catch { /* storage blocked */ } } setDone(true); };
      if (!el) { end(); return; }
      const target = document.querySelector("[data-sidebar-wordmark]")?.getBoundingClientRect();
      if (mode === "full" && lk && target && window.matchMedia("(min-width: 768px)").matches) {
        const a = lk.getBoundingClientRect();
        const sc = Math.max(0.05, target.width / Math.max(1, a.width));
        animate(lk, { x: target.left - a.left - (a.width * (1 - sc)) / 2, y: target.top - a.top - (a.height * (1 - sc)) / 2, scale: sc }, { duration: HANDOFF_MS / 1000, ease: ease.turn as never });
      }
      animate(el, { opacity: 0 }, { duration: (mode === "full" ? HANDOFF_MS : durMs.clip) / 1000, ease: ease.turn as never }).then(end, end);
    };
    (window as unknown as { __splashFinish?: () => void }).__splashFinish = finish;
    if (mode !== "full") {
      // Warm start and reduced motion: the lockup fades in, holds until ready, fades out (200 ms clip fades; 300 ms fade-in when reduced).
      const inMs = mode === "warm" ? durMs.clip : durMs.tapscroll;
      const lk = lockup.current;
      if (lk) animate(lk, { opacity: [0, 1] }, { duration: inMs / 1000, ease: "linear" });
      const wait = () => { if (probeAt.current !== null) setTimeout(finish, inMs); else raf = requestAnimationFrame(wait); };
      wait();
      return () => cancelAnimationFrame(raf);
    }
    const tick = () => {
      const now = performance.now() - origin.current;
      setT(now);
      if (!impressed && now >= REVEAL_END) { impressed = true; haptic("splash.impress"); }
      if (showConnecting(now, probeAt.current)) setConnecting(true);
      if (probeAt.current !== null && now >= Math.max(probeAt.current, REVEAL_END)) { finish(); return; }
      raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [mode, done, ready, setHandoff]);

  // Skip: tap, Enter, Space, Esc jump to the end of the reveal (the hand-off waits for the probe).
  useEffect(() => {
    if (done) return;
    const skip = () => { origin.current = Math.min(origin.current, performance.now() - REVEAL_END); };
    const key = (e: KeyboardEvent) => { if (e.key === "Enter" || e.key === " " || e.key === "Escape") skip(); };
    window.addEventListener("pointerdown", skip, { once: true });
    window.addEventListener("keydown", key);
    return () => { window.removeEventListener("pointerdown", skip); window.removeEventListener("keydown", key); };
  }, [done]);

  if (done) return null;
  return <SplashView t={mode === "full" ? t : REVEAL_END} frozen={mode !== "full"} connecting={connecting} lockupRef={lockup} layerRef={layer} />;
}
