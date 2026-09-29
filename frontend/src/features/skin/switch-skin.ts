import { markSkinRestartStart } from "@/lib/motion-timings";
import { profilesApi } from "@/features/profiles/api";
import type { SkinId } from "@/skins/types";
import { restartInto, T0_KEY } from "./skin-storage";

const PATCH_GRACE_MS = 1000;

export interface SwitchDeps {
  patch(profileId: number, skin: "cinematic" | "glass", signal: AbortSignal): Promise<unknown>;
  markStart(): void;
  clearStart(): void;
  restartInto: typeof restartInto;
  isOnline(): boolean;
  path(): string;
}

export const browserDeps: SwitchDeps = {
  patch: (id, skin, signal) => profilesApi.update(id, { skin }, signal),
  markStart: markSkinRestartStart,
  clearStart: () => {
    try {
      sessionStorage.removeItem(T0_KEY);
    } catch {
      // ignore
    }
  },
  restartInto,
  isOnline: () => navigator.onLine,
  path: () => location.pathname + location.search,
};

/**
 * Awaits the server, then restarts into the other skin (stack §2.5). The PATCH
 * starts at t0 alongside the leaving skin's exit; it gets 1,000 ms more after
 * the exit ends. Mirror and return route are written only on success.
 */
export async function switchSkin(
  opts: {
    profileId: number;
    to: "cinematic" | "glass";
    from: SkinId;
    outgoing: () => Promise<void>;
    reverse: () => Promise<void>;
  },
  deps: SwitchDeps = browserDeps,
): Promise<"restarting" | "failed"> {
  if (!deps.isOnline()) return "failed";
  deps.markStart();
  const controller = new AbortController();
  const patch = deps
    .patch(opts.profileId, opts.to, controller.signal)
    .then(() => true as const, () => false as const);
  await opts.outgoing();
  let timer: ReturnType<typeof setTimeout> | undefined;
  const timeout = new Promise<false>((resolve) => {
    timer = setTimeout(() => resolve(false), PATCH_GRACE_MS);
  });
  const ok = await Promise.race([patch, timeout]);
  clearTimeout(timer);
  if (ok) {
    deps.restartInto({ cookie: "mm-skin", skin: opts.to, from: opts.from, returnPath: deps.path() });
    return "restarting";
  }
  controller.abort();
  deps.clearStart();
  await opts.reverse();
  return "failed";
}
