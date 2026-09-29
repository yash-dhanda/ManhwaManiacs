import type { OfflineState } from "@/features/offline/types";

/** Downloads badge: queued (paused for room) + downloading (saving) + failed (partial) from the local worker; zero until it answers. */
export function downloadsBadge(state: Pick<OfflineState, "entries">): number {
  let n = 0;
  for (const e of state.entries ?? []) if (e.status === "saving" || e.status === "partial" || e.status === "paused") n++;
  return n;
}
