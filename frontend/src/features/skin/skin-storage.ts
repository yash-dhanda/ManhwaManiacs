import { SKIN_MESSAGE } from "@/features/offline/protocol";
import { T0_KEY } from "@/lib/motion-timings";
import type { SkinId } from "@/skins/types";

// Every access is wrapped in try/catch: a locked-down browser throws.
export { T0_KEY };
export const RETURN_KEY = "mm.skin.return";
export const DEBUG_KEY = "mm.debug";
export const BOOT_RESTART_KEY = "mm.skin.boot-restart";
export const splashKey = (skin: SkinId) => `mm.skin.splash.${skin}`;

export type SkinCookie = "mm-skin" | "mm-skin-debug";

export function readCookie(name: string): string | null {
  try {
    for (const part of document.cookie.split("; ")) {
      const eq = part.indexOf("=");
      if (eq > 0 && part.slice(0, eq) === name) return decodeURIComponent(part.slice(eq + 1));
    }
  } catch {
    // no cookie access
  }
  return null;
}

export function writeSkinCookie(name: SkinCookie, skin: SkinId): void {
  try {
    document.cookie = `${name}=${skin}; Path=/; Max-Age=31536000; SameSite=Lax; Secure`;
  } catch {
    // ignore
  }
}

export function clearSkinCookie(name: SkinCookie): void {
  try {
    document.cookie = `${name}=; Path=/; Max-Age=0; SameSite=Lax; Secure`;
  } catch {
    // ignore
  }
}

export function postToWorker(message: { type: "skin" | "skin-changed"; skin: SkinId }): void {
  try {
    navigator.serviceWorker?.controller?.postMessage(message);
  } catch {
    // no worker
  }
}

/** The one restart path: cookie, return route, splash reset, worker notice, reload. */
export function restartInto(o: {
  cookie: SkinCookie;
  skin: SkinId;
  from: SkinId;
  returnPath: string;
}): void {
  writeSkinCookie(o.cookie, o.skin);
  try {
    sessionStorage.setItem(RETURN_KEY, o.returnPath);
    sessionStorage.removeItem(splashKey(o.from));
  } catch {
    // ignore
  }
  postToWorker({ type: SKIN_MESSAGE.changed, skin: o.skin });
  location.replace(o.returnPath);
}
