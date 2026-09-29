import { durMs } from "../../tokens.generated";
import { logMotion } from "./motion-log";

/** §8.14.2 Column wipe: 12 / 8 / 4 blades by width, close top-down, hold on black, open bottom-down. */
export function bladeCount(width: number): number {
  return width >= 1024 ? 12 : width >= 768 ? 8 : 4;
}

const CLOSE = durMs.wipeClose; // 200
const OPEN = durMs.wipeOpen; // 280
const STAGGER = 16;
const HOLD = 40;
const SETTLE: [number, number, number, number] = [0.16, 1, 0.3, 1];

export function wipePlan(n: number) {
  const close = CLOSE + (n - 1) * STAGGER;
  const open = OPEN + (n - 1) * STAGGER;
  return { close, hold: HOLD, open, total: close + HOLD + open };
}

const frame = () => new Promise<void>((r) => requestAnimationFrame(() => r()));

/**
 * Runs the wipe around `go` (the navigation). Blades close, `go()` fires while
 * the screen is black, then once the route has committed (or 1.2 s) the hold
 * elapses and the blades open. Reduced motion: a 200 ms cross-fade through black.
 */
export async function columnWipe(go: () => void, committed: () => boolean) {
  const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  const n = reduce ? 1 : bladeCount(window.innerWidth);
  const plan = reduce ? { close: 100, hold: 0, open: 100, total: 200 } : wipePlan(n);
  const t0 = performance.now();
  const host = document.createElement("div");
  host.setAttribute("data-mm-wipe", String(n));
  host.style.cssText = "position:fixed;inset:0;z-index:2147483000;display:flex;pointer-events:auto";
  const blades = Array.from({ length: n }, () => {
    const b = document.createElement("div");
    b.style.cssText = "flex:1;background:#000;transform:scaleY(0);transform-origin:top;will-change:transform";
    host.append(b);
    return b;
  });
  document.body.append(host);
  const ease = `cubic-bezier(${SETTLE.join(",")})`;
  const run = (b: HTMLElement, from: string, to: string, origin: string, delay: number, ms: number) => {
    b.style.transformOrigin = origin;
    return b.animate([{ transform: from }, { transform: to }], { duration: ms, delay, easing: reduce ? "linear" : ease, fill: "forwards" }).finished;
  };
  await Promise.all(blades.map((b, i) => run(b, "scaleY(0)", "scaleY(1)", "top", reduce ? 0 : i * STAGGER, reduce ? 100 : CLOSE)));
  const tClosed = performance.now();
  go();
  const limit = performance.now() + 1200;
  while (!committed() && performance.now() < limit) await new Promise((r) => setTimeout(r, 16));
  await frame();
  await new Promise((r) => setTimeout(r, plan.hold));
  const tOpen = performance.now();
  await Promise.all(blades.map((b, i) => run(b, "scaleY(1)", "scaleY(0)", "bottom", reduce ? 0 : i * STAGGER, reduce ? 100 : OPEN)));
  host.remove();
  logMotion("columnWipe close", plan.close, tClosed - t0);
  logMotion("columnWipe open", plan.open, performance.now() - tOpen);
  logMotion("columnWipe", plan.total, tClosed - t0 + plan.hold + (performance.now() - tOpen));
}
