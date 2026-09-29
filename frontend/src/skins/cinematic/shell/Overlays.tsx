"use client";
import { useEffect, useRef, useState, type CSSProperties, type ReactNode } from "react";
import { useRouter } from "next/navigation";
import { startMove } from "@/lib/motion-timings";
import { haptic } from "../haptics";
import { logMotion } from "../screens/feature/motion-log";
import { play, readReduced } from "../motion";
import { playSound } from "../sounds";
import { durMs, ease } from "../tokens.generated";
import { transitionTypesFor, type NavKind } from "./use-cine-router";
import { useShellState } from "./shell-state";
import { blades as computeBlades, columnsFor, WIPE, wipeTotalMs, type Blade } from "./wipe-geometry";

const sleep = (ms: number) => new Promise<void>((r) => setTimeout(r, ms));
type Ctl = { speed: number; stop?: () => void };

type Host = {
  dip: (then: () => void | Promise<void>) => Promise<void>;
  wipe: (then: () => void | Promise<void>) => Promise<void>;
  push: (href: string, nav?: NavKind) => void;
};
let host: Host | null = null;

/** Dip (§4.5): `#000` fades in 160 ms, `then()` runs in the 40 ms hold, fades out 240 ms. 150 ms fades under reduced motion. Falls back to `then()` with no host. */
export async function dip(then: () => void | Promise<void>): Promise<void> {
  if (!host) { await then(); return; }
  return host.dip(then);
}
/** Column wipe around `then()` (the navigation). */
export async function columnWipe(then: () => void | Promise<void>): Promise<void> {
  if (!host) { await then(); return; }
  return host.wipe(then);
}
/** Push through the shell's router (used by `enterReader`). */
export function shellPush(href: string, nav: NavKind = "forward"): void {
  if (host) host.push(href, nav);
  else if (typeof window !== "undefined") window.location.assign(href);
}

/** Pure look at a blade at time t from the wipe start (gallery `freezeAt` and tests). */
export function bladeScaleAt(i: number, n: number, tMs: number): number {
  const closeEnd = WIPE.closeMs + WIPE.staggerMs * (n - 1);
  const openStart = closeEnd + WIPE.holdMs;
  const out = (p: number) => 1 - Math.pow(1 - Math.min(1, Math.max(0, p)), 3);
  if (tMs < openStart) return out((tMs - i * WIPE.staggerMs) / WIPE.closeMs);
  return 1 - out((tMs - openStart - i * WIPE.staggerMs) / WIPE.openMs);
}

/** The blades themselves: `#000` columns from column edge to column edge. `scaleAt` freezes them for the gallery. */
export function ColumnWipe({ blades, bladeRef, scaleAt, className = "" }: { blades: Blade[]; bladeRef?: (i: number, el: HTMLDivElement | null) => void; scaleAt?: (i: number) => number; className?: string }) {
  return (
    <div aria-hidden className={`pointer-events-none absolute inset-0 ${className}`} data-column-wipe={blades.length} data-mm-wipe={blades.length}>
      {blades.map((b, i) => (
        <div key={i} ref={(el) => bladeRef?.(i, el)} data-blade
          style={{ position: "absolute", top: 0, bottom: 0, left: b.left, width: b.width, background: "#000", transformOrigin: "top", transform: `scaleY(${scaleAt ? scaleAt(i) : 0})`, willChange: "transform" } as CSSProperties} />
      ))}
    </div>
  );
}

/** Iris (§8.5): a `clip-path` circle on a takeover, frozen at `radius` for the gallery. Children are the takeover. */
export function Iris({ x, y, radius, children, className = "" }: { x: number; y: number; radius: number; children: ReactNode; className?: string }) {
  return <div data-iris className={className} style={{ clipPath: `circle(${radius}px at ${x}px ${y}px)` }}>{children}</div>;
}

const diag = () => Math.hypot(window.innerWidth, window.innerHeight);

/**
 * `irisClose(element, { x, y, radius })` animates `clip-path: circle(R at x y)` on the takeover from the viewport diagonal down to the
 * avatar radius over 480 ms `ease.turn`, and resolves when it lands. A tap during the close skips in 120 ms. Reduced motion: 200 ms cross-fade.
 */
export function irisClose(element: HTMLElement, { x, y, radius }: { x: number; y: number; radius: number }): Promise<void> {
  const R = diag();
  const reduced = readReduced();
  const c = reduced
    ? play("iris", element, { from: { opacity: 1 }, to: { opacity: 0 }, durationMs: durMs.clip, easeOverride: ease.linear })
    : play("iris", element, { from: { clipPath: `circle(${R}px at ${x}px ${y}px)` }, to: { clipPath: `circle(${radius}px at ${x}px ${y}px)` }, durationMs: 480 });
  if (!c) return Promise.resolve();
  const skipTap = () => { c.speed = Math.max(1, 480 / durMs.snap); };
  window.addEventListener("pointerdown", skipTap, { once: true });
  return Promise.resolve(c).then(() => window.removeEventListener("pointerdown", skipTap));
}

/** The point the next route opens from: the shell's content wrapper reads it. */
export const requestIrisOut = (p: { x: number; y: number }) => useShellState.getState().requestIrisOut(p);

/** Content wrapper hook: on mount with a pending Iris point, opens `circle(0)` -> `circle(diagonal)` over 560 ms `ease.settle`. */
export function useIrisReveal(ref: React.RefObject<HTMLElement | null>, key: string) {
  const irisOut = useShellState((s) => s.irisOut);
  useEffect(() => {
    const el = ref.current;
    if (!irisOut || !el) return;
    useShellState.getState().requestIrisOut(null);
    const { x, y } = irisOut;
    const c = readReduced()
      ? play("iris", el, { from: { opacity: 0 }, to: { opacity: 1 }, durationMs: durMs.clip, easeOverride: ease.linear })
      : play("iris", el, { from: { clipPath: `circle(0px at ${x}px ${y}px)` }, to: { clipPath: `circle(${diag()}px at ${x}px ${y}px)` }, durationMs: durMs.irisOut, easeOverride: ease.settle });
    const skip = () => { if (c) c.speed = Math.max(1, durMs.irisOut / durMs.snap); };
    window.addEventListener("pointerdown", skip, { once: true });
    return () => { window.removeEventListener("pointerdown", skip); c?.complete?.(); el.style.clipPath = ""; el.style.opacity = ""; };
  }, [irisOut, ref, key]);
}

/** The overlays host at `z.shutter` (aria-hidden; pointer events only for the skip tap). Mount once in the Shell. */
export function Overlays() {
  const router = useRouter();
  const dipRef = useRef<HTMLDivElement>(null);
  const fadeRef = useRef<HTMLDivElement>(null);
  const els = useRef<(HTMLDivElement | null)[]>([]);
  const [bl, setBl] = useState<Blade[] | null>(null);
  const [active, setActive] = useState(false);
  const live = useRef<Set<Ctl>>(new Set());
  const skipping = useRef(false);

  useEffect(() => {
    const track = (c: unknown): Ctl | null => { if (!c) return null; live.current.add(c as Ctl); return c as Ctl; };
    const h: Host = {
      push: (href, nav = "forward") => router.push(href, { transitionTypes: transitionTypesFor(nav) }),
      async dip(then) {
        const el = dipRef.current;
        if (!el) { await then(); return; }
        const reduced = readReduced();
        setActive(true);
        await play("dip", el, { durationMs: reduced ? durMs.reduced : durMs.beat, easeOverride: reduced ? ease.linear : ease.lift });
        await Promise.all([Promise.resolve(then()), sleep(reduced ? 0 : durMs.holdDip)]);
        await play("dip", el, { from: { opacity: 1 }, to: { opacity: 0 }, durationMs: reduced ? durMs.reduced : durMs.line, easeOverride: reduced ? ease.linear : ease.settle });
        setActive(false);
      },
      async wipe(then) {
        const reduced = readReduced();
        skipping.current = false;
        setActive(true);
        if (reduced) {
          // A 200 ms cross-fade through black (100 in, 100 out); no blades.
          const f = fadeRef.current;
          const t0 = performance.now();
          f?.setAttribute("data-mm-wipe", "1");
          await play("columnWipe", f, { from: { opacity: 0 }, to: { opacity: 1 }, durationMs: durMs.clip / 2, easeOverride: ease.linear, record: false });
          haptic("reader.enter"); playSound("reader.enter");
          await then();
          await play("columnWipe", f, { from: { opacity: 1 }, to: { opacity: 0 }, durationMs: durMs.clip / 2, easeOverride: ease.linear, record: false });
          f?.removeAttribute("data-mm-wipe");
          logMotion("columnWipe", durMs.clip, performance.now() - t0);
          setActive(false);
          return;
        }
        const cs = getComputedStyle(document.documentElement);
        const num = (v: string, d: number) => { const n = parseFloat(cs.getPropertyValue(v)); return Number.isFinite(n) ? n : d; };
        const vw = window.innerWidth;
        const cols = num("--mm-grid-columns", columnsFor(vw));
        const list = computeBlades(vw, { columns: cols, margin: num("--mm-grid-margin", 16), gutter: num("--mm-grid-gutter", 12), max: num("--mm-grid-max", 1760) || 1760 });
        const rec = startMove("column wipe", wipeTotalMs(list.length));
        const t0 = performance.now();
        setBl(list);
        await new Promise<void>((r) => requestAnimationFrame(() => requestAnimationFrame(() => r())));
        const run = async (dir: "close" | "open") => {
          const ms = skipping.current ? durMs.snap : dir === "close" ? WIPE.closeMs : WIPE.openMs;
          const cts = els.current.slice(0, list.length).map((el, i) => {
            if (!el) return null;
            el.style.transformOrigin = dir === "close" ? "top" : "bottom";
            return track(play("columnWipe", el, { from: { scaleY: dir === "close" ? 0 : 1 }, to: { scaleY: dir === "close" ? 1 : 0 }, durationMs: ms, delayMs: skipping.current ? 0 : i * WIPE.staggerMs, easeOverride: ease.settle, record: false }));
          });
          await Promise.all(cts.map((c) => (c ? Promise.resolve(c as unknown as PromiseLike<unknown>) : null)));
          cts.forEach((c) => c && live.current.delete(c));
        };
        await run("close");
        haptic("reader.enter"); playSound("reader.enter");
        await Promise.all([Promise.resolve(then()), sleep(skipping.current ? 0 : WIPE.holdMs)]);
        await run("open");
        rec.end();
        logMotion("columnWipe", wipeTotalMs(list.length), performance.now() - t0);
        setBl(null);
        setActive(false);
      },
    };
    host = h;
    return () => { if (host === h) host = null; };
  }, [router]);

  // A tap during the wipe jumps to the open state in 120 ms.
  const skip = () => { skipping.current = true; live.current.forEach((c) => { c.speed = Math.max(c.speed, 6); }); };

  return (
    <div aria-hidden data-overlays style={{ position: "fixed", inset: 0, zIndex: "var(--mm-z-shutter)", pointerEvents: active ? "auto" : "none" }} onPointerDown={skip}>
      <div ref={dipRef} style={{ position: "absolute", inset: 0, background: "#000", opacity: 0, pointerEvents: "none" }} />
      <div ref={fadeRef} style={{ position: "absolute", inset: 0, background: "#000", opacity: 0, pointerEvents: "none" }} />
      {bl ? <ColumnWipe blades={bl} bladeRef={(i, el) => { els.current[i] = el; }} /> : null}
    </div>
  );
}
