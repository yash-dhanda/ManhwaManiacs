"use client";

import { useEffect } from "react";
import { useGlassReduced } from "../motion";
import { light } from "../tokens.generated";

const clamp = (v: number, lo: number, hi: number) => Math.min(hi, Math.max(lo, v));

/** 135 deg + 25 deg x (x / width - 0.5) x 2 (DESIGN 2.4.2 rule 5). */
export const pointerAngle = (x: number, width: number) => light.angle + light.range * (x / width - 0.5) * 2;
/** 135 deg + 25 deg x clamp(roll / 30 deg, -1, 1). */
export const rollAngle = (roll: number) => light.angle + light.range * clamp(roll / 30, -1, 1);

const write = (deg: number) => document.documentElement.style.setProperty("--mm-light-angle", `${deg}deg`);

type TiltEvent = typeof DeviceOrientationEvent & { requestPermission?: () => Promise<"granted" | "denied"> };
let tiltGranted = false;
const tiltListeners = new Set<() => void>();

/** iOS Safari: call from a user gesture (the Settings switch "Light follows the device", web/39). Resolves true when tilt is on. */
export async function requestDeviceTilt(): Promise<boolean> {
  const DOE = (typeof DeviceOrientationEvent === "undefined" ? undefined : DeviceOrientationEvent) as TiltEvent | undefined;
  if (!DOE) return false;
  if (typeof DOE.requestPermission === "function") {
    try { tiltGranted = (await DOE.requestPermission()) === "granted"; } catch { tiltGranted = false; }
  } else tiltGranted = true;
  tiltListeners.forEach((l) => l());
  return tiltGranted;
}

/**
 * One light for the whole page: the specular angle follows the pointer (fine pointers) or the device roll
 * (coarse pointers, no permission needed on Android Chrome), written to --mm-light-angle on <html> at most
 * once per frame. Pinned at 135 deg under reduced motion and with `{ follow: false }`.
 */
export function useLightAngle({ follow = true }: { follow?: boolean } = {}) {
  const reduced = useGlassReduced();
  useEffect(() => {
    write(light.angle);
    if (!follow || reduced) return;
    const cleanups: (() => void)[] = [];
    const attach = () => {
      cleanups.splice(0).forEach((c) => c());
      if (document.hidden) return;
      if (matchMedia("(pointer: fine)").matches) {
        let raf = 0, x = 0;
        const move = (e: PointerEvent) => {
          x = e.clientX;
          if (!raf) raf = requestAnimationFrame(() => { raf = 0; write(pointerAngle(x, window.innerWidth)); });
        };
        window.addEventListener("pointermove", move, { passive: true });
        cleanups.push(() => { window.removeEventListener("pointermove", move); cancelAnimationFrame(raf); });
      } else if (typeof DeviceOrientationEvent !== "undefined") {
        const needsPermission = typeof (DeviceOrientationEvent as TiltEvent).requestPermission === "function";
        if (needsPermission && !tiltGranted) return;
        let base: number | null = null, smooth = 0, last = 0;
        const orient = (e: DeviceOrientationEvent) => {
          const now = performance.now();
          if (now - last < 33 || e.gamma === null) return;
          last = now;
          base ??= e.gamma;
          smooth += 0.15 * (e.gamma - base - smooth);
          write(rollAngle(smooth));
        };
        window.addEventListener("deviceorientation", orient);
        cleanups.push(() => window.removeEventListener("deviceorientation", orient));
      }
    };
    attach();
    document.addEventListener("visibilitychange", attach);
    tiltListeners.add(attach);
    return () => {
      document.removeEventListener("visibilitychange", attach);
      tiltListeners.delete(attach);
      cleanups.forEach((c) => c());
      write(light.angle);
    };
  }, [follow, reduced]);
}
